#!/bin/bash
# Single-tier (one discrete GPU, host-mapped weights) run of the issue scenario on base and fixD.
E=/workspace/evidence; Q=/workspace/qa; MODEL=/data/base/gguf/GLM-5.3-Flash-Q2.gguf
log() { echo "$(date -u +%FT%TZ) $*" | tee -a "$E/run-mtp.log"; }
for run in "base mtp" "fixD mtp" "fixD nomtp"; do set -- $run; log "mtp scenario $1 $2 (single-tier H200)"; "$Q/03-mtp-scenario.sh" /data/$1 $1 "$MODEL" $2 >> "$E/run-mtp.log" 2>&1; done
log "MTP DONE"
