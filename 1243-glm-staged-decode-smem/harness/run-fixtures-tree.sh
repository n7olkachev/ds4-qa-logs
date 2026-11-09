#!/bin/bash
# Fixture gates (100-case + eight long) for one tree, single-tier CUDA. Usage: run-fixtures-tree.sh base|fixD
set -u
T=$1; E=/workspace/evidence; Q=/workspace/qa; MODEL=/data/base/gguf/GLM-5.3-Flash-Q2.gguf
export DS4_GPU_FLAGS=" "
log() { echo "$(date -u +%FT%TZ) $*" | tee -a "$E/run-fixtures-$T.log"; }
while pgrep -f "score[_]official|ds4[-]server" >/dev/null; do sleep 15; done
log "fixtures $T (single-tier, host-mapped weights)"
"$Q/02-fixtures.sh" /data/$T $T "$MODEL" >> "$E/run-fixtures-$T.log" 2>&1
grep -hE "^summary|^api_summary|exit=" "$E/$T/03-score-100.log" "$E/$T/04-score-long.log" | tee -a "$E/run-fixtures-$T.log"
log "FIXTURES $T DONE"
