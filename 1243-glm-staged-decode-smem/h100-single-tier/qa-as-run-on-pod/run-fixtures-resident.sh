#!/bin/bash
# Single-tier, VRAM-resident (DS4_CUDA_COPY_MODEL=1) fixture gates on base and fixD; waits for the MTP runner.
E=/workspace/evidence; Q=/workspace/qa; MODEL=/data/base/gguf/GLM-5.3-Flash-Q2.gguf
export DS4_CUDA_COPY_MODEL=1; export DS4_GPU_FLAGS=" "
log() { echo "$(date -u +%FT%TZ) $*" | tee -a "$E/run-fixtures.log"; }
until grep -q "MTP DONE" "$E/run-mtp.log" 2>/dev/null; do sleep 15; done
for t in base fixD; do log "fixtures $t (single-tier resident)"; "$Q/02-fixtures.sh" /data/$t $t "$MODEL" >> "$E/run-fixtures.log" 2>&1; grep -hE "^summary|^api_summary|exit=" "$E/$t/03-score-100.log" "$E/$t/04-score-long.log" | tee -a "$E/run-fixtures.log"; done
log "bundle"; "$Q/06-bundle.sh" fixD >> "$E/run-fixtures.log" 2>&1; log "FIXTURES DONE"
