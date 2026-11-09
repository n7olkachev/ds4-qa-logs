#!/bin/bash
# DeepSeek V4 Flash 0731 Q2 gates on one tree: CLI smoke, ds4_test --logprob-vectors, section-3 100-case scorer.
# Usage: 04-flash.sh TREE LABEL MODEL
set -u -o pipefail
. "$(dirname "$0")/header.sh"
TREE=$1; LABEL=$2; MODEL=$3; OUT=/workspace/evidence/$LABEL; mkdir -p "$OUT"
export DS4_LOCK_FILE=/tmp/ds4-$LABEL.lock
cd "$TREE"; Q=gguf-tools/quality-testing
[ -x $Q/score_official ] || make -C gguf-tools quality-score >/dev/null 2>&1
ln -sfn "$MODEL" ds4flash.gguf
PROMPT="Explain in three sentences why Redis uses a single-threaded event loop."
{
  evidence_header "$TREE" "DeepSeek V4 Flash 0731 Q2: CLI smoke, greedy, 64 tokens, ctx 4096; DS4_CUDA_NO_MODEL_COPY=${DS4_CUDA_NO_MODEL_COPY:-unset}"
  echo; echo "\$ ./ds4 -m $MODEL --cuda -c 4096 --temp 0 -n 64 -p \"$PROMPT\"   (stdout -> 04-flash-cli.out)"
  ( time ./ds4 -m "$MODEL" --cuda -c 4096 --temp 0 -n 64 -p "$PROMPT" 2>"$OUT/04-flash-cli.err" >"$OUT/04-flash-cli.out" ) 2>&1; echo "exit=$?"
  echo; cat "$OUT/04-flash-cli.err"; echo; echo "--- stdout sha256: $(sha256sum "$OUT/04-flash-cli.out" | cut -c1-16)  bytes: $(wc -c < "$OUT/04-flash-cli.out")"
} > "$OUT/04-flash-cli.log" 2>&1
{
  evidence_header "$TREE" "DeepSeek V4 Flash 0731 Q2: ds4_test --logprob-vectors (tests/test-vectors/flash-0731/official.vec); DS4_CUDA_NO_MODEL_COPY=${DS4_CUDA_NO_MODEL_COPY:-unset}"
  echo; echo "\$ DS4_TEST_MODEL=$MODEL ./ds4_test --logprob-vectors"
  ( time DS4_TEST_MODEL="$MODEL" ./ds4_test --logprob-vectors 2>&1 ) 2>&1; echo "exit=$?"
} > "$OUT/04-flash-logprob-vectors.log" 2>&1
{
  evidence_header "$TREE" "section 3: DeepSeek V4 Flash 0731 smoke vectors, 100 cases, ctx 4096; DS4_CUDA_NO_MODEL_COPY=${DS4_CUDA_NO_MODEL_COPY:-unset}"
  echo; echo "\$ $Q/score_official $MODEL $Q/data/flash/manifest.tsv $OUT/flash-q2-100.tsv 4096"
  ( time $Q/score_official "$MODEL" $Q/data/flash/manifest.tsv "$OUT/flash-q2-100.tsv" 4096 2>&1 ) 2>&1; echo "exit=$?"
} > "$OUT/04-flash-score-100.log" 2>&1
echo "done $LABEL: $(grep -hE 'exit=|^real|^summary|PASS|FAIL' "$OUT"/04-flash-*.log | tr '\n' ' ' | cut -c1-400)"
