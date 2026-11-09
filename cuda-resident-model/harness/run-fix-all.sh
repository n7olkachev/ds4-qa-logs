#!/bin/bash
# Everything for the fix tree from the final commit, sequentially on an idle GPU.
set -u
export PATH=/usr/local/cuda/bin:$PATH
E=/workspace/evidence; Q=/workspace/qa; G=/data/gguf/GLM-5.3-Flash-Q2.gguf; F=/data/gguf/ds4flash-0731-q2.gguf; D=/data/gguf/DeepSeek-V4-Flash-DSpark-support-0731.gguf
. $Q/header.sh
log() { echo "$(date -u +%FT%TZ) $*" | tee -a $E/run-fix-all.log; }
mkdir -p $E/final-stash && mv $E/fix $E/fix-flash $E/fix-nocopy $E/fix-no-room $E/fix-dspark $E/final-stash/ 2>/dev/null
mkdir -p $E/fix $E/fix-flash
log "model-free test + sanitizers"
cd /data/fix && { evidence_header /data/fix "make test-cuda-model-copy, then the same binary under the four Compute Sanitizer tools (GPU idle)"; echo; echo "\$ make test-cuda-model-copy"; make test-cuda-model-copy 2>&1 | grep -v "^nvcc warning"; echo "exit=${PIPESTATUS[0]}"; for tool in memcheck initcheck racecheck synccheck; do echo; echo "\$ compute-sanitizer --tool $tool --error-exitcode 1 ./tests/test_cuda_model_copy"; compute-sanitizer --tool $tool --error-exitcode 1 ./tests/test_cuda_model_copy 2>&1 | grep -E "PASS|SUMMARY|ERROR|error"; echo "exit=${PIPESTATUS[0]}"; done; } > $E/fix/06-test-model-copy.log 2>&1
log "cuda-regression"; cd /data/fix && { echo "# make cuda-regression on fix ($(git rev-parse --short HEAD)), $(date -u +%FT%TZ)"; make cuda-regression 2>&1; echo "exit=$?"; } > $E/fix/05-cuda-regression.log 2>&1
log "GLM CLI smokes"; bash $Q/01-cli-smoke.sh /data/fix fix $G > /dev/null; DS4_CUDA_NO_MODEL_COPY=1 bash $Q/01-cli-smoke.sh /data/fix fix-nocopy $G > /dev/null
log "GLM bench"; bash $Q/03-bench.sh /data/fix fix $G > /dev/null
log "Flash gates"; bash $Q/04-flash.sh /data/fix fix-flash $F > /dev/null
log "Flash bench"; bash $Q/03-bench.sh /data/fix fix-flash $F > /dev/null
log "DSpark smoke"; bash $Q/05-dspark.sh /data/fix fix-dspark $F $D > /dev/null
log "GLM fixtures"; bash $Q/02-fixtures.sh /data/fix fix $G > /dev/null
log "verbose span count"; cd /data/fix && DS4_LOCK_FILE=/tmp/ds4-v.lock DS4_CUDA_WEIGHT_CACHE_VERBOSE=1 ./ds4 -m $G --cuda -c 4096 --temp 0 -n 4 -p hi 2> $E/fix/08-verbose-spans.err >/dev/null
log "ALL DONE"
