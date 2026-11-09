#!/bin/bash
# Unattended: wait for the GGUF, record its identity, then run every model-dependent gate on base and fixD.
set -u
MODEL=/data/base/gguf/GLM-5.3-Flash-Q2.gguf; E=/workspace/evidence; Q=/workspace/qa; export DS4_GPU_FLAGS=${DS4_GPU_FLAGS:---gpu-devices 0 --gpu-vram auto}
log() { echo "$(date -u +%FT%TZ) $*" | tee -a "$E/run-all.log"; }
until [ -f "$MODEL" ] && [ "$(stat -c %s "$MODEL")" -eq 96505816384 ] && ! ls /data/base/gguf/part.* >/dev/null 2>&1; do sleep 10; done
log "gpu flags: $DS4_GPU_FLAGS"; log "model complete: $(stat -c %s "$MODEL") bytes"
[ -s "$E/model-identity.txt" ] || { echo "file: $MODEL"; echo "bytes: $(stat -c %s "$MODEL")"; echo "hf_api_xet_hash: 3717238bd6bb945cc065012f119519b8ce3ad04645dc2a1011bac077b415ffda"; echo "hf_resolve_x_linked_etag: e81fd6241c6e55a64e1e14e47a3eab61a173fa8d7e4b5c1d1848827119705b32"; echo "sha256: $(sha256sum "$MODEL" | cut -d' ' -f1)"; } > "$E/model-identity.txt"
log "identity: $(cat "$E/model-identity.txt" | tr '\n' ' ')"
for t in base fixD; do log "fixtures $t"; "$Q/02-fixtures.sh" /data/$t $t "$MODEL" >> "$E/run-all.log" 2>&1; grep -hE "^summary|^api_summary|exit=" "$E/$t/03-score-100.log" "$E/$t/04-score-long.log" | tee -a "$E/run-all.log"; done
for run in "base mtp" "fixD mtp" "fixD nomtp"; do set -- $run; log "mtp scenario $1 $2"; "$Q/03-mtp-scenario.sh" /data/$1 $1 "$MODEL" $2 >> "$E/run-all.log" 2>&1; done
log "bundle"; "$Q/06-bundle.sh" fixD >> "$E/run-all.log" 2>&1
log "ALL DONE"
