/* Scratch (not for the PR): hash + time the GLM indexed decode attention over
 * large selected windows, so an old and a new ds4_cuda.o can be compared
 * bit-for-bit and for speed. Same fixture as large_decode_window_cases() in
 * tests/test_glm_attention.c. Build like tests/test_glm_attention:
 *   nvcc $(NVCCFLAGS) -o glm_window_hash glm_window_hash.o ds4_cuda.o ds4_image.o $(MMQ_OBJS) $(CUDA_LDLIBS)
 * Usage: ./glm_window_hash [count ...]    (default list below; counts the old
 * kernel cannot launch are reported as FAIL instead of aborting) */
#include <math.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#include <time.h>

#include "ds4.h"
#include "ds4_gpu.h"

bool ds4_log_is_tty(FILE *fp) { (void)fp; return false; }

static void check(int ok, const char *what) {
    if (!ok) { fprintf(stderr, "%s failed\n", what); exit(1); }
}

static double seconds(void) {
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    return ts.tv_sec + ts.tv_nsec * 1e-9;
}

static uint64_t fnv1a(const void *p, size_t n) {
    const unsigned char *b = p;
    uint64_t h = 1469598103934665603ull;
    for (size_t i = 0; i < n; i++) { h ^= b[i]; h *= 1099511628211ull; }
    return h;
}

static ds4_gpu_tensor *upload(const void *data, size_t bytes) {
    ds4_gpu_tensor *t = ds4_gpu_tensor_alloc(bytes);
    check(t && ds4_gpu_tensor_write(t, 0, data, bytes), "tensor upload");
    return t;
}

static ds4_gpu_tensor *upload_cache(const float *data, size_t count, bool f16) {
    if (!f16) return upload(data, count * sizeof(float));
    _Float16 *half = malloc(count * sizeof(*half));
    check(half != NULL, "half cache allocation");
    for (size_t i = 0; i < count; i++) half[i] = data[i];
    ds4_gpu_tensor *t = upload(half, count * sizeof(*half));
    free(half);
    return t;
}

int main(int argc, char **argv) {
    enum { D = 512, V = 4, R = 64, NOPE = 32, CAP = 65536, MODEL_BYTES = 1 << 20 };
    const int H = getenv("HEADS") ? atoi(getenv("HEADS")) : 8;   /* GLM 5.3 Flash: 64 */
    static const uint32_t defaults[] = {511, 512, 600, 2051, 4096, 8192, 12000, 12032,
                                        12033, 16384, 32768, 65536};
    const uint32_t *counts = defaults;
    size_t n_counts = sizeof(defaults) / sizeof(defaults[0]);
    uint32_t *custom = NULL;
    if (argc > 1) {
        custom = malloc((size_t)(argc - 1) * sizeof(*custom));
        for (int i = 1; i < argc; i++) custom[i - 1] = (uint32_t)strtoul(argv[i], NULL, 10);
        counts = custom; n_counts = (size_t)(argc - 1);
    }
    const int runs = getenv("RUNS") ? atoi(getenv("RUNS")) : 21;
    check(ds4_gpu_init(), "GPU initialization");
    unsigned char *model = mmap(NULL, MODEL_BYTES, PROT_READ | PROT_WRITE,
                                MAP_PRIVATE | MAP_ANON, -1, 0);
    check(model != MAP_FAILED, "model allocation");
    for (int i = 0; i < H * V * (D / 32); i++) {
        unsigned char *block = model + 4096 + i * 34;
        _Float16 scale = 1;
        memcpy(block, &scale, sizeof(scale));
        memset(block + 2, 1, 32);
    }
    check(ds4_gpu_set_model_map(model, MODEL_BYTES), "model registration");
    float *kv = malloc((size_t)CAP * D * sizeof(float));
    float *rope = calloc((size_t)CAP * R, sizeof(float));
    float *low = malloc((size_t)H * D * sizeof(float));
    float *q = calloc((size_t)H * (NOPE + R), sizeof(float));
    int32_t *ids = malloc((size_t)CAP * sizeof(int32_t));
    float *out = malloc((size_t)H * V * sizeof(float));
    check(kv && rope && low && q && ids && out, "host allocation");
    for (size_t i = 0; i < (size_t)CAP * D; i++)
        kv[i] = ((int)((i % D) * 13 + (i / D) * 7) % 61 - 30) * 0.00390625f;
    for (int i = 0; i < H * D; i++)
        low[i] = ((i % D) * 3 + (i / D) * 5) % 17 * 0.015625f - 0.125f;
    ds4_gpu_tensor *qg = upload(q, (size_t)H * (NOPE + R) * sizeof(float));
    ds4_gpu_tensor *lg = upload(low, (size_t)H * D * sizeof(float));
    ds4_gpu_tensor *rg = upload_cache(rope, (size_t)CAP * R, true);
    ds4_gpu_tensor *ig = ds4_gpu_tensor_alloc((size_t)CAP * sizeof(int32_t));
    ds4_gpu_tensor *og = ds4_gpu_tensor_alloc((size_t)H * V * sizeof(float));
    check(ig && og, "tensor allocation");
    for (int f16 = 0; f16 < 2; f16++) {
        ds4_gpu_tensor *cache = upload_cache(kv, (size_t)CAP * D, f16);
        for (size_t c = 0; c < n_counts; c++) {
            const uint32_t count = counts[c];
            for (uint32_t i = 0; i < count; i++)
                ids[i] = (int32_t)((i * 2654435761u) % CAP);
            ids[count / 3] = (int32_t)CAP;
            ids[count / 2] = -1;
            check(ds4_gpu_tensor_write(ig, 0, ids, count * sizeof(int32_t)), "ids");
            double *t = malloc((size_t)runs * sizeof(double));
            uint64_t hash = 0;
            bool ok = true;
            for (int run = 0; run < runs && ok; run++) {
                check(ds4_gpu_synchronize(), "pre-sync");
                const double start = seconds();
                ok = ds4_gpu_glm_attention_indexed_decode_typed_tensor(
                      og, qg, lg, cache, rg, model, MODEL_BYTES, 4096, 8,
                      ig, count, CAP, f16, H, D, NOPE, 0, V, 4096,
                      10000, 1, 0, 1, 32, 1) && ds4_gpu_synchronize();
                t[run] = seconds() - start;
                if (!ok) break;
                check(ds4_gpu_tensor_read(og, 0, out, (size_t)H * V * sizeof(float)), "read");
                const uint64_t h = fnv1a(out, (size_t)H * V * sizeof(float));
                if (run == 0) hash = h;
                else if (h != hash) { fprintf(stderr, "count=%u f16=%d: nondeterministic\n", count, f16); exit(1); }
            }
            if (!ok) {
                printf("count=%6u f16=%d: FAIL (launch)\n", count, f16);
            } else {
                /* median of runs 1..N-1 (run 0 warms up) */
                for (int i = 2; i < runs; i++) {           /* insertion sort t[1..] */
                    double v = t[i]; int j = i - 1;
                    while (j >= 1 && t[j] > v) { t[j + 1] = t[j]; j--; }
                    t[j + 1] = v;
                }
                const double med = runs > 2 ? t[1 + (runs - 1) / 2] : t[0];
                printf("heads=%d count=%6u f16=%d: hash=%016llx out0=%a median=%.1f us\n",
                       H, count, f16, (unsigned long long)hash, out[0], med * 1e6);
            }
            free(t);
        }
        ds4_gpu_tensor_free(cache);
    }
    ds4_gpu_tensor_free(og); ds4_gpu_tensor_free(ig); ds4_gpu_tensor_free(rg);
    ds4_gpu_tensor_free(lg); ds4_gpu_tensor_free(qg);
    ds4_gpu_cleanup();
    munmap(model, MODEL_BYTES);
    free(out); free(custom); free(ids); free(q); free(low); free(rope); free(kv);
    return 0;
}
