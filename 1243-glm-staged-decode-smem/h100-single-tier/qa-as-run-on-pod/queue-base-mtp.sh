#!/bin/bash
until grep -q "ALL H100 DONE" /workspace/evidence/run-fixtures-fixD.log 2>/dev/null; do sleep 30; done
export DS4_GLM_MEMORY_GUARD=0 DS4_GPU_FLAGS=" "
/workspace/qa/03-mtp-scenario.sh /data/base base /data/base/gguf/GLM-5.3-Flash-Q2.gguf mtp > /workspace/evidence/run-base-mtp.log 2>&1
/workspace/qa/03-mtp-scenario.sh /data/fixD fixD /data/base/gguf/GLM-5.3-Flash-Q2.gguf mtp > /workspace/evidence/run-fixD-mtp.log 2>&1
echo "$(date -u +%FT%TZ) H100 MTP DONE" >> /workspace/evidence/run-fixD-mtp.log
