# Logs for the ds4 PR "Copy model tensors into device memory on a discrete CUDA GPU when they fit"

Branch: https://github.com/n7olkachev/ds4/tree/cuda-resident-model (commit 136e766, base antirez/ds4 main @ b3f5018).

One machine for everything: RunPod pod `3s050mzbu75h8t`, NVIDIA H200 SXM 141 GB (sm_90), driver 595.91.07, nvcc 12.8.93, Ubuntu 24.04, 2026-11-09 19:30–21:50 UTC. `base/*` directories are main at b3f5018, `fix/*` the branch at 136e766. Every log starts with a header: date, host, GPU, driver, nvcc, git commit of the tree, dirty-file count, and the command that produced it. `00-COMPARISON.txt` is the side-by-side; `MANIFEST.sha256` lists every file.

| directory | what |
|---|---|
| `base/`, `fix/` | GLM 5.3 Flash Q2. `01-cli-smoke.*`: the same greedy 64-token prompt (stdout, stderr, log). `02-score-100.log` + `glm53-q2-100.tsv`, `02-score-long.log` + `glm53-q2-long.tsv`: QA section 3 fixtures. `03-bench.*`: `ds4-bench` 2048→8192, GPU otherwise idle. `fix/05-cuda-regression.log`, `fix/06-test-model-copy.log` (new test + four Compute Sanitizer tools), `fix/07-server-smoke.log` (+ `07a-*`: the same request when the card had no room), `fix/08-verbose-spans.err` (the 132 device allocations). |
| `fix-nocopy/` | The branch with `DS4_CUDA_NO_MODEL_COPY=1`: main's path and main's speed. |
| `fix-no-room/` | The branch with 110 GiB of the card held by another process: the "stays host-mapped" decision, same output. |
| `base-flash/`, `fix-flash/`, `base-flash-cli-idle/` | DeepSeek V4 Flash 0731 Q2: CLI smoke, `ds4_test --logprob-vectors`, the 100-case `data/flash` scorer, `ds4-bench`. The first base CLI smoke ran while two other scorers were on the card; `base-flash-cli-idle` repeats it alone. |
| `base-dspark/`, `fix-dspark/` | V4 Flash with the DSpark support model (`--dspark --mtp-model`). |
| `harness/` | The scripts that produced the logs. |

Models: `GLM-5.3-Flash-Q2.gguf` 96,505,816,384 bytes, sha256 `e81fd6241c6e55a64e1e14e47a3eab61a173fa8d7e4b5c1d1848827119705b32`; `DeepSeek-V4-Flash-IQ2XXS-w2Q2K-AProjQ8-SExpQ8-OutQ8-chat-v2-imatrix-0731.gguf` 86,720,111,488 bytes (Hugging Face ETag `ca22ae2f…61c0`); `DeepSeek-V4-Flash-DSpark-support-0731.gguf` 5,989,114,272 bytes.

The fixture TSVs, the long-case TSVs, the Flash scorer TSVs and every CLI stdout are byte-identical between `base` and `fix`.
