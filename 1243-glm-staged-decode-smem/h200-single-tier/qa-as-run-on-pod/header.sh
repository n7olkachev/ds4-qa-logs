#!/bin/bash
# Evidence header for every log: who/what/where, so each file stands alone.
evidence_header() {   # $1 = tree dir, rest = description
  local tree="$1"; shift
  echo "# ==== ds4 QA evidence ===="
  echo "# date_utc: $(date -u +%FT%TZ)"
  echo "# host: $(hostname)  runpod_pod: ${RUNPOD_POD_ID:-?}  dc: ${RUNPOD_DC_ID:-?}  gpu_count: ${RUNPOD_GPU_COUNT:-?}"
  echo "# gpu: $(nvidia-smi --query-gpu=name,driver_version,memory.total,compute_cap --format=csv,noheader)"
  echo "# nvcc: $(/usr/local/cuda/bin/nvcc --version | tail -1)"
  echo "# os: $(uname -srm)  $(. /etc/os-release && echo $PRETTY_NAME)"
  echo "# tree: $tree"
  echo "# commit: $(git -C "$tree" rev-parse HEAD)  ($(git -C "$tree" log -1 --format=%s))"
  echo "# dirty_files: $(git -C "$tree" status --porcelain --untracked-files=no | wc -l | tr -d ' ')"
  echo "# origin: $(git -C "$tree" remote get-url origin)"
  echo "# description: $*"
  echo "# ========================="
}
