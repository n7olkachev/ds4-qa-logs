#!/bin/bash
# Parallel ranged download of the GLM-5.3-Flash Q2 GGUF from Hugging Face, for pods where the
# hf/Xet client crashes. N independent byte ranges, at most PAR in flight (anonymous requests
# get rate-limited above that), each verified by length and re-fetched on failure, then
# concatenated. Complete parts survive a restart of this script.
set -u
URL="https://huggingface.co/antirez/glm-5.3-flash-gguf/resolve/main/GLM-5.3-Flash-Q2.gguf"
DIR=/workspace/base/gguf; OUT=$DIR/GLM-5.3-Flash-Q2.gguf
SIZE=96505816384; N=12; PAR=${PAR:-6}
E=/workspace/evidence; : > "$E/download-http.log"; : > "$E/download-errors.log"
CH=$(( (SIZE + N - 1) / N )); mkdir -p "$DIR"; cd "$DIR" || exit 1; rm -f "$OUT"
for i in $(seq 0 $((N-1))); do
  while [ "$(pgrep -c '^curl')" -ge "$PAR" ]; do sleep 2; done
  s=$((i*CH)); e=$(( (i+1)*CH - 1 )); [ $e -ge $SIZE ] && e=$((SIZE-1)); want=$((e-s+1)); p=$(printf "part.%02d" "$i")
  (
    tries=0
    until [ -f "$p" ] && [ "$(stat -c %s "$p")" -eq "$want" ]; do
      tries=$((tries+1)); rm -f "$p"
      curl -L -f -sS --connect-timeout 30 --speed-limit 1000000 --speed-time 60 \
           -r "$s-$e" -o "$p" -w "%{http_code} part=$i got=%{size_download} time=%{time_total}s\n" "$URL" \
           >> "$E/download-http.log" 2>> "$E/download-errors.log"
      [ $tries -ge 30 ] && { echo "part $i failed 30 times" >&2; exit 1; }
      sleep 2
    done
    echo "$(date -u +%T) part $i ok ($tries tries)"
  ) &
  sleep 1
done
wait
echo "$(date -u +%T) concatenating"
cat $(ls part.* | sort) > "$OUT" && rm -f part.* && echo "$(date -u +%T) done: $(stat -c %s "$OUT") bytes"
