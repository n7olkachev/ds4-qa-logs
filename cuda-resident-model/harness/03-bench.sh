#!/bin/bash
# ds4-bench sweep on one tree. Usage: 03-bench.sh TREE LABEL MODEL [extra args...]
set -u -o pipefail
. "$(dirname "$0")/header.sh"
TREE=$1; LABEL=$2; MODEL=$3; shift 3; OUT=/workspace/evidence/$LABEL; mkdir -p "$OUT"
export DS4_LOCK_FILE=/tmp/ds4-$LABEL.lock   # one instance lock per label so trees can run side by side
cd "$TREE"
ARGS="-m $MODEL --cuda --prompt-file speed-bench/promessi_sposi.txt --ctx-start 2048 --ctx-max 8192 --step-incr 2048 --gen-tokens 64 $*"
{
  evidence_header "$TREE" "ds4-bench linear sweep 2048..8192 step 2048, 64 greedy tokens per frontier, GPU otherwise idle, extra args [$*]"
  echo; echo "\$ nvidia-smi --query-gpu=utilization.gpu,memory.used --format=csv,noheader"; nvidia-smi --query-gpu=utilization.gpu,memory.used --format=csv,noheader
  echo "\$ ./ds4-bench $ARGS --csv $OUT/03-bench.csv"
  ( time ./ds4-bench $ARGS --csv "$OUT/03-bench.csv" 2>&1 | grep -v "swiglu one failed\|quantize launch failed" ) 2>&1
  echo "exit=${PIPESTATUS[0]}"; echo; echo "--- csv:"; cat "$OUT/03-bench.csv"
} > "$OUT/03-bench.log" 2>&1
echo "== $LABEL"; cat "$OUT/03-bench.csv"
