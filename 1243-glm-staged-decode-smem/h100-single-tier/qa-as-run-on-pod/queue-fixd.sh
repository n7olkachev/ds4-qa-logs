#!/bin/bash
until grep -q "BASE NOMTP DONE" /workspace/evidence/run-base-nomtp.log 2>/dev/null && grep -q "FIXTURES base DONE" /workspace/evidence/run-fixtures-base.log 2>/dev/null; do sleep 20; done
until [ -x /data/fixD/gguf-tools/quality-testing/score_official ] && ! pgrep -f "nvc[c]|cic[c]|ptxa[s]" >/dev/null; do sleep 15; done
export DS4_GLM_MEMORY_GUARD=0 DS4_GPU_FLAGS=" "
/workspace/qa/01-model-free.sh /data/base base > /dev/null 2>&1
/workspace/qa/01-model-free.sh /data/fixD fixD > /dev/null 2>&1
/workspace/qa/run-fixtures-tree.sh fixD
echo "$(date -u +%FT%TZ) ALL H100 DONE" >> /workspace/evidence/run-fixtures-fixD.log
