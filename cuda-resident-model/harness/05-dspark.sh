#!/bin/bash
# DeepSeek V4 Flash 0731 Q2 with the DSpark support model, greedy CLI smoke. Usage: 05-dspark.sh TREE LABEL MODEL DRAFTER
set -u -o pipefail
. "$(dirname "$0")/header.sh"
TREE=$1; LABEL=$2; MODEL=$3; DRAFTER=$4; OUT=/workspace/evidence/$LABEL; mkdir -p "$OUT"
export DS4_LOCK_FILE=/tmp/ds4-$LABEL.lock
cd "$TREE"
PROMPT="Explain in three sentences why Redis uses a single-threaded event loop."
{
  evidence_header "$TREE" "DeepSeek V4 Flash 0731 Q2 + DSpark support model: greedy, 64 tokens, ctx 4096, GPU otherwise idle"
  echo; echo "\$ ./ds4 -m $MODEL --dspark --mtp-model $DRAFTER --cuda -c 4096 --temp 0 -n 64 -p \"$PROMPT\"   (stdout -> 05-dspark-cli.out)"
  ( time ./ds4 -m "$MODEL" --dspark --mtp-model "$DRAFTER" --cuda -c 4096 --temp 0 -n 64 -p "$PROMPT" 2>"$OUT/05-dspark-cli.err" >"$OUT/05-dspark-cli.out" ) 2>&1; echo "exit=$?"
  echo; echo "--- stderr:"; cat "$OUT/05-dspark-cli.err"; echo; echo "--- stdout sha256: $(sha256sum "$OUT/05-dspark-cli.out" | cut -c1-16)  bytes: $(wc -c < "$OUT/05-dspark-cli.out")"
} > "$OUT/05-dspark-cli.log" 2>&1
grep -E "registered|copying|stays|covered|loading model tensors|arena|t/s|accept|draft|^exit|sha256|^real" "$OUT/05-dspark-cli.log" | head -20
