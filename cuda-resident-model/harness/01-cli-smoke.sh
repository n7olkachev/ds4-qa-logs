#!/bin/bash
# Same short greedy prompt on one tree. Usage: 01-cli-smoke.sh TREE LABEL MODEL [extra ds4 args...]
set -u -o pipefail
. "$(dirname "$0")/header.sh"
TREE=$1; LABEL=$2; MODEL=$3; shift 3; OUT=/workspace/evidence/$LABEL; mkdir -p "$OUT"
export DS4_LOCK_FILE=/tmp/ds4-$LABEL.lock   # one instance lock per label so trees can run side by side
cd "$TREE"
PROMPT="Explain in three sentences why Redis uses a single-threaded event loop."
{
  evidence_header "$TREE" "CLI smoke: greedy, 64 tokens, ctx 4096, extra args [$*]"
  echo; echo "\$ ./ds4 -m $MODEL --cuda -c 4096 --temp 0 -n 64 $* -p \"$PROMPT\"   (stdout -> 01-cli-smoke.out)"
  ( time ./ds4 -m "$MODEL" --cuda -c 4096 --temp 0 -n 64 "$@" -p "$PROMPT" 2>"$OUT/01-cli-smoke.err" >"$OUT/01-cli-smoke.out" ) 2>&1
  echo "exit=$?"; echo; echo "--- stderr without the pre-existing graph-capture lines:"
  grep -v "swiglu one failed\|quantize launch failed" "$OUT/01-cli-smoke.err"
  echo "graph-capture lines (pre-existing on main, see side note): $(grep -c 'swiglu one failed\|quantize launch failed' "$OUT/01-cli-smoke.err")"
  echo; echo "--- stdout sha256: $(sha256sum "$OUT/01-cli-smoke.out" | cut -c1-16)  bytes: $(wc -c < "$OUT/01-cli-smoke.out")"
} > "$OUT/01-cli-smoke.log" 2>&1
grep -E "GLM prefill|generation|real|exit=|copying|stays host-mapped|registered|sha256" "$OUT/01-cli-smoke.log"
