#!/bin/bash
# 05: the issue's scenario against ds4-server. Usage: 03-mtp-scenario.sh TREE LABEL MODEL mtp|nomtp
set -u
. "$(dirname "$0")/header.sh"
GPUFLAGS=${DS4_GPU_FLAGS:---gpu-devices 0 --gpu-vram auto}
TREE=$1; LABEL=$2; MODEL=$3; MODE=$4; OUT=/workspace/evidence/$LABEL; mkdir -p "$OUT"
PORT=8011
cd "$TREE"
MTPARGS=""; [ "$MODE" = mtp ] && MTPARGS="--mtp --mtp-timing"
{
  evidence_header "$TREE" "DS4_CUDA_COPY_MODEL=${DS4_CUDA_COPY_MODEL:-unset} ds4-server --cuda $GPUFLAGS $MTPARGS, three-turn greedy session whose MTP window crosses 12,033 positions (issue #1243 scenario)"
  echo; echo "\$ ./ds4-server --cuda $GPUFLAGS -m $MODEL --ctx 32768 --port $PORT --trace $OUT/05-trace-$MODE.txt $MTPARGS"
} > "$OUT/05-server-$MODE.log" 2>&1
./ds4-server --cuda $GPUFLAGS -m "$MODEL" --ctx 32768 --port $PORT --trace "$OUT/05-trace-$MODE.txt" $MTPARGS >> "$OUT/05-server-$MODE.log" 2>&1 &
SRV=$!
for i in $(seq 1 120); do curl -s -o /dev/null "http://127.0.0.1:$PORT/v1/models" && break; sleep 5; done
python3 /workspace/qa/client.py "$PORT" "$OUT/05-client-$MODE.log" "$OUT/05-text-$MODE.txt"
sleep 2; kill -TERM $SRV; wait $SRV 2>/dev/null
{
  echo; echo "# ==== summary ($LABEL, $MODE) ===="
  echo "# 'staged decode weights launch failed' lines: $(grep -c "staged decode weights launch failed" "$OUT/05-server-$MODE.log")"
  echo "# 'glm mtp step failed' lines: $(grep -c "glm mtp step failed" "$OUT/05-server-$MODE.log")"
  echo "# mtp cycles ACCEPT: $(grep -c "glm mtp cycle: .* ACCEPT" "$OUT/05-server-$MODE.log")  reject: $(grep -c "glm mtp cycle: .* reject" "$OUT/05-server-$MODE.log")"
  echo "# sha256 of greedy texts: $(sha256sum "$OUT/05-text-$MODE.txt" | cut -c1-16)"
} >> "$OUT/05-server-$MODE.log"
tail -5 "$OUT/05-server-$MODE.log"
