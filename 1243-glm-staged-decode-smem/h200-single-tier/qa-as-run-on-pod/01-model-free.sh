#!/bin/bash
# 01: model-free checks on one tree. Usage: 01-model-free.sh TREE LABEL
set -u
. "$(dirname "$0")/header.sh"
TREE=$1; LABEL=$2; OUT=/workspace/evidence/$LABEL; mkdir -p "$OUT"
cd "$TREE"
{
  evidence_header "$TREE" "model-free: make test-glm-attention (CUDA), test_glm53_kda, glm_window_hash (64 heads)"
  echo; echo "\$ make CUDA_ARCH=native tests/test_glm_attention tests/test_glm53_kda"
  make CUDA_ARCH=native tests/test_glm_attention tests/test_glm53_kda 2>&1 | tail -2
  echo; echo "\$ ./tests/test_glm_attention"; ./tests/test_glm_attention 2>&1; echo "exit=${PIPESTATUS[0]}"
  echo; echo "\$ ./tests/test_glm53_kda"; ./tests/test_glm53_kda 2>&1 | tail -15; echo "exit=${PIPESTATUS[0]}"
} > "$OUT/01-model-free.log" 2>&1
# scratch hash/timing program (source published with the evidence)
cp /workspace/qa/glm_window_hash.c tests/
CFLAGS="-O3 -g -march=native -Wall -Wextra -std=c99 -D_GNU_SOURCE -fno-finite-math-only"
NVCCFLAGS="-O3 -g -lineinfo --use_fast_math -arch=native -Xcompiler -march=native -Xcompiler -pthread"
LIBS="ds4_image.o cuda/mmq/ds4_ggml_stubs.o cuda/mmq/ds4_mmq.o cuda/mmq/ds4_mmq_d2r.o cuda/mmq/quantize.o cuda/mmq/mmid.o cuda/mmq/mmvq.o cuda/mmq/ds4_repack.o -lm -Xcompiler -pthread -L/usr/local/cuda/lib64 -lcudart -lcublas"
gcc $CFLAGS -I. -c -o tests/glm_window_hash.o tests/glm_window_hash.c && \
/usr/local/cuda/bin/nvcc $NVCCFLAGS -o tests/glm_window_hash tests/glm_window_hash.o ds4_cuda.o $LIBS
{
  evidence_header "$TREE" "glm_window_hash: FNV-1a of the heads output + median latency of the whole indexed decode entry, HEADS=64 RUNS=51"
  echo; echo "\$ sha256sum tests/glm_window_hash.c"; sha256sum tests/glm_window_hash.c
  echo; echo "\$ HEADS=64 RUNS=51 ./tests/glm_window_hash 511 512 600 2048 2051 4096 8192 12000 12032 12033 16384 32768 65536"
  HEADS=64 RUNS=51 ./tests/glm_window_hash 511 512 600 2048 2051 4096 8192 12000 12032 12033 16384 32768 65536 2>&1
} > "$OUT/02-hash-timing.log" 2>&1
echo "done: $OUT/01-model-free.log $OUT/02-hash-timing.log"
