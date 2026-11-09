#!/bin/bash
until grep -q "FIXTURES base DONE" /workspace/evidence/run-fixtures-base.log 2>/dev/null; do sleep 20; done
export DS4_GPU_FLAGS=" "
/workspace/qa/03-mtp-scenario.sh /data/base base /data/base/gguf/GLM-5.3-Flash-Q2.gguf nomtp > /workspace/evidence/run-base-nomtp.log 2>&1
echo "$(date -u +%FT%TZ) BASE NOMTP DONE" >> /workspace/evidence/run-base-nomtp.log
