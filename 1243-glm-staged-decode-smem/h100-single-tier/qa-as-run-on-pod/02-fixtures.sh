#!/bin/bash
# 03/04: his GLM 5.3 quality gates. Usage: 02-fixtures.sh TREE LABEL MODEL
set -u
. "$(dirname "$0")/header.sh"
GPUFLAGS=${DS4_GPU_FLAGS:---gpu-devices 0 --gpu-vram auto}; GUARDNOTE="DS4_GLM_MEMORY_GUARD=${DS4_GLM_MEMORY_GUARD:-unset}"
TREE=$1; LABEL=$2; MODEL=$3; OUT=/workspace/evidence/$LABEL; mkdir -p "$OUT"
cd "$TREE"
Q=gguf-tools/quality-testing
{
  evidence_header "$TREE" "DS4_CUDA_COPY_MODEL=${DS4_CUDA_COPY_MODEL:-unset} GPUFLAGS=[$GPUFLAGS] QA_BEFORE_RELEASES.md section 3: 100-case GLM 5.3 Flash Q2 fixture at ctx 4096 (reference: avg NLL 0.458030488, first-token 89/100, greedy prefix 7.37 on Metal)"
  echo; echo "\$ model identity"; cat /workspace/evidence/model-identity.txt 2>/dev/null || echo "(sha256 pending)"
  echo; echo "\$ $Q/score_official $MODEL $Q/data/glm53-flash-openrouter-zai-fp8-100/manifest.tsv $OUT/glm53-q2-100.tsv 4096 $GPUFLAGS"
  $Q/score_official "$MODEL" $Q/data/glm53-flash-openrouter-zai-fp8-100/manifest.tsv "$OUT/glm53-q2-100.tsv" 4096 $GPUFLAGS 2>&1; echo "exit=${PIPESTATUS[0]}"
} > "$OUT/03-score-100.log" 2>&1
{
  evidence_header "$TREE" "DS4_CUDA_COPY_MODEL=${DS4_CUDA_COPY_MODEL:-unset} GPUFLAGS=[$GPUFLAGS] QA_BEFORE_RELEASES.md section 3: eight long Z.AI FP8 cases, rendered prompts, ctx 8192 (every prompt crosses the 2,051-token boundary)"
  echo; echo "\$ python3 $Q/render_glm_references.py $Q/data/glm53-flash-openrouter-zai-fp8-long"
  python3 $Q/render_glm_references.py $Q/data/glm53-flash-openrouter-zai-fp8-long 2>&1
  echo; echo "\$ $Q/score_official $MODEL $Q/data/glm53-flash-openrouter-zai-fp8-long/manifest-rendered.tsv $OUT/glm53-q2-long.tsv 8192 --rendered-prompt $GPUFLAGS"
  $Q/score_official "$MODEL" $Q/data/glm53-flash-openrouter-zai-fp8-long/manifest-rendered.tsv "$OUT/glm53-q2-long.tsv" 8192 --rendered-prompt $GPUFLAGS 2>&1; echo "exit=${PIPESTATUS[0]}"
} > "$OUT/04-score-long.log" 2>&1
echo "done: $OUT/03-score-100.log $OUT/04-score-long.log"
