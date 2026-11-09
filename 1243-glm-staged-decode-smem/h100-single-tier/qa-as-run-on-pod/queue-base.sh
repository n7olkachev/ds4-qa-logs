#!/bin/bash
until [ -f /data/base/gguf/GLM-5.3-Flash-Q2.gguf ] && [ "$(stat -c %s /data/base/gguf/GLM-5.3-Flash-Q2.gguf)" -eq 96505816384 ] && [ -x /data/base/gguf-tools/quality-testing/score_official ] && ! pgrep -f "nvc[c]|cic[c]|ptxa[s]" >/dev/null; do sleep 15; done
sha256sum /data/base/gguf/GLM-5.3-Flash-Q2.gguf > /workspace/evidence/model-sha256.txt
/workspace/qa/run-fixtures-tree.sh base
