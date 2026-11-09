#!/bin/bash
# 06: compare before/after and bundle everything with a sha256 manifest. Usage: 06-bundle.sh [FIXLABEL]
set -u
E=/workspace/evidence; F=${1:-fixD}; cd "$E"
{
  echo "# ==== comparison base (b3f5018) vs $F (5ebf36c) ===="
  echo "## 100-case fixture: python3 compare_scores.py"
  python3 /data/fixD/gguf-tools/quality-testing/compare_scores.py base/glm53-q2-100.tsv $F/glm53-q2-100.tsv 2>&1 | tail -20
  echo; echo "## long cases: compare_scores.py"
  python3 /data/fixD/gguf-tools/quality-testing/compare_scores.py base/glm53-q2-long.tsv $F/glm53-q2-long.tsv 2>&1 | tail -20
  echo; echo "## summary lines"; grep -hE "^summary|^api_summary" base/03-score-100.log $F/03-score-100.log base/04-score-long.log $F/04-score-long.log
  echo; echo "## generated text per request, from --trace (thinking included): base-mtp / $F-mtp / $F-nomtp"
  for r in base/05-trace-mtp $F/05-trace-mtp $F/05-trace-nomtp; do awk '/^--- generated text ---$/{f=1;next} /^--- parsed message ---$/{f=0} f' "$r.txt" > "$r.generated.txt"; echo "$(sha256sum "$r.generated.txt" | cut -c1-16)  $(wc -c < "$r.generated.txt") bytes  $r.generated.txt"; done
  echo "diff base-mtp vs $F-mtp generated:"; diff base/05-trace-mtp.generated.txt $F/05-trace-mtp.generated.txt && echo IDENTICAL
  echo "diff $F-mtp vs $F-nomtp generated:"; diff $F/05-trace-mtp.generated.txt $F/05-trace-nomtp.generated.txt && echo IDENTICAL
  echo; echo "## visible texts (sha256): base-mtp $F-mtp $F-nomtp"; sha256sum base/05-text-mtp.txt $F/05-text-mtp.txt $F/05-text-nomtp.txt
  echo; echo "## diff base-mtp vs fix-mtp"; diff base/05-text-mtp.txt $F/05-text-mtp.txt && echo IDENTICAL
  echo; echo "## diff fix-mtp vs fix-nomtp"; diff $F/05-text-mtp.txt $F/05-text-nomtp.txt && echo IDENTICAL
  echo; echo "## server summaries"; grep -hE "^# (\x27|mtp|sha256|====)" base/05-server-mtp.log $F/05-server-mtp.log $F/05-server-nomtp.log
  echo; echo "## hash lines base vs fix (counts both could launch must match)"; diff <(grep -E "^heads" base/02-hash-timing.log | sed 's/ median=.*//') <(grep -E "^heads" $F/02-hash-timing.log | sed 's/ median=.*//' | grep -Ff <(grep -E "^heads" base/02-hash-timing.log | cut -d: -f1)) && echo "BITWISE IDENTICAL where base launches"
} > "$E/00-COMPARISON.txt" 2>&1
find . -type f ! -name MANIFEST.sha256 -exec sha256sum {} + | sort -k2 > MANIFEST.sha256
cat 00-COMPARISON.txt
