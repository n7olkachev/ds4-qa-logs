#!/bin/bash
# Pod bring-up: trees, builds, model download — all in parallel, logs in /workspace/evidence.
set -u
export PATH=/usr/local/cuda/bin:$PATH
E=/workspace/evidence; mkdir -p $E /data/gguf /workspace/qa
apt-get install -y -qq bc jq >/dev/null 2>&1 &
# 1. model download (background)
nohup bash /workspace/qa/ranged-download.sh > $E/download.log 2>&1 &
# 2. trees
cd /data
[ -d base ] || git clone -q https://github.com/antirez/ds4.git base
[ -d fix ]  || git clone -q https://github.com/n7olkachev/ds4.git fix
git -C base checkout -q b3f5018
git -C fix checkout -q cuda-resident-model
echo "base: $(git -C base rev-parse --short HEAD)  fix: $(git -C fix rev-parse --short HEAD)"
# 3. builds (background, parallel)
for t in base fix; do
  ( cd /data/$t && nohup make cuda-generic -j16 > $E/build-$t.log 2>&1; echo "build $t exit=$?" >> $E/build-$t.log ) &
done
echo "setup launched $(date -u +%T)"
