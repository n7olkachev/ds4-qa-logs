#!/bin/bash
# QA_BEFORE_RELEASES.md section 3 GLM 5.3 gates on one tree. Usage: 02-fixtures.sh TREE LABEL MODEL
set -u -o pipefail
. "$(dirname "$0")/header.sh"
TREE=$1; LABEL=$2; MODEL=$3; OUT=/workspace/evidence/$LABEL; mkdir -p "$OUT"
export DS4_LOCK_FILE=/tmp/ds4-$LABEL.lock   # one instance lock per label so trees can run side by side
cd "$TREE"; Q=gguf-tools/quality-testing
[ -x $Q/score_official ] || make -C gguf-tools quality-score >/dev/null 2>&1
{
  evidence_header "$TREE" "section 3: eight long Z.AI FP8 cases, rendered prompts, ctx 8192 (every prompt crosses the 2,051-token boundary); DS4_CUDA_NO_MODEL_COPY=${DS4_CUDA_NO_MODEL_COPY:-unset}"
  echo; echo "\$ python3 $Q/render_glm_references.py $Q/data/glm53-flash-openrouter-zai-fp8-long"
  python3 $Q/render_glm_references.py $Q/data/glm53-flash-openrouter-zai-fp8-long 2>&1
  echo; echo "\$ $Q/score_official $MODEL $Q/data/glm53-flash-openrouter-zai-fp8-long/manifest-rendered.tsv $OUT/glm53-q2-long.tsv 8192 --rendered-prompt"
  ( time $Q/score_official "$MODEL" $Q/data/glm53-flash-openrouter-zai-fp8-long/manifest-rendered.tsv "$OUT/glm53-q2-long.tsv" 8192 --rendered-prompt 2>&1 | grep -v "swiglu one failed\|quantize launch failed" ) 2>&1; echo "exit=${PIPESTATUS[0]}"
} > "$OUT/02-score-long.log" 2>&1
echo "done $LABEL: $(grep -hE '^summary|exit=|^real' "$OUT/02-score-100.log" "$OUT/02-score-long.log" | tr '\n' ' ')"
