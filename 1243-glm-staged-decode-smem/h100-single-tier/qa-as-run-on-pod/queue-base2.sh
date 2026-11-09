#!/bin/bash
export DS4_GLM_MEMORY_GUARD=0 DS4_GPU_FLAGS=" "
/workspace/qa/run-fixtures-tree.sh base
/workspace/qa/03-mtp-scenario.sh /data/base base /data/base/gguf/GLM-5.3-Flash-Q2.gguf nomtp > /workspace/evidence/run-base-nomtp.log 2>&1
echo "$(date -u +%FT%TZ) BASE NOMTP DONE" >> /workspace/evidence/run-base-nomtp.log
