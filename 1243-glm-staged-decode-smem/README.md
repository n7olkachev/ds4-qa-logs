# Logs for the ds4 CUDA fix of antirez/ds4#1243

Branch: https://github.com/n7olkachev/ds4/tree/glm-staged-decode-smem (commit 0a50118, base antirez/ds4 main @ b3f5018).

Every log starts with a header: date, host, GPU, driver, nvcc version, git commit of the tree, and the command that produced it. `MANIFEST.sha256` in each run directory lists every file.

| directory | what |
|---|---|
| `h100-single-tier/` | H100 SXM, one GPU, weights host-mapped. `base/` = main, `fixD/` = the branch. `03-score-100.log` + `glm53-q2-100.tsv`: 100-case GLM 5.3 Z.AI fixture. `04-score-long.log` + `glm53-q2-long.tsv`: eight long cases, ctx 8192. `05-*`: ds4-server scenario from the issue (server log, `--trace`, client log, generated text). `00-COMPARISON.txt`: base vs branch. |
| `h200-single-tier/` | H200, same layout. `fixD/03`, `fixD/04`: fixture runs on this machine (not comparable with the H100 numbers, every case differs between the two GPUs). `base/05-*`, `fixD/05-*`: the server scenario on this machine. `01-model-free.log`, `02-hash-timing.log` per tree: kernel tests and the hash/timing program. `fix/` is the rejected all-global variant. |
| `a40-and-kernel-logs/` | A40 session: baseline, model-free reproduction at 12,033 rows, hashes and timings of the old kernel and of each variant, and the H200 kernel-level timing rounds (`12-`, `13-`, `15-`). |
| `mac-metal/` | M1: `make tests/test_glm_attention` with CLT 16.4, the Metal run showing wrong values at 16,384 rows, the bisection 7,424-32,768, and the final run with the Apple skip. |
| `2xh100-multitier-placement-bug/` | Two H100s, `--gpu-devices 0,1 --gpu-vram auto`: main fails at prefill with `selective-cache miss ... GLM-5.3 BF16 matrix` (not related to the fix; separate problem). |
| `harness/` | The scripts that produced the logs: `01-model-free.sh`, `02-fixtures.sh`, `03-mtp-scenario.sh` + `client.py`, `06-bundle.sh`, `compare-local.sh`, `ranged-download.sh`; `glm_window_hash.c` is the hashing and timing program. |
| `variants/` | The two kernel variants that were measured and not used, as patches against b3f5018. |

Model: `GLM-5.3-Flash-Q2.gguf`, 96,505,816,384 bytes, sha256 `e81fd6241c6e55a64e1e14e47a3eab61a173fa8d7e4b5c1d1848827119705b32` (equal to the Hugging Face ETag). Host-mapped single-tier CUDA: ~1.3-2 min per fixture case, 52 tok/s prefill, 1.67 tok/s decode; that is the configuration, not a measurement of the fix.
