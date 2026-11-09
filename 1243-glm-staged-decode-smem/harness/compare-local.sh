#!/bin/bash
# Local comparison of pulled evidence: base (b3f5018) vs fixD (5ebf36c). Run on the Mac.
# Usage: compare-local.sh EVIDENCE_DIR   (containing base/ and fixD/ subdirs as pulled from the pods)
set -u
E=${1:?evidence dir}; REPO=~/ai/ds4-contrib/ds4; cd "$E" || exit 1
Q=$REPO/gguf-tools/quality-testing
{
  echo "# ==== comparison base (b3f5018) vs fixD (5ebf36c) — generated $(date -u +%FT%TZ) ===="
  echo "## reference (QA_BEFORE_RELEASES.md, Metal): Q2 avg NLL 0.458030488, first-token 89/100, greedy prefix 7.37"
  echo; echo "## 100-case fixture summary lines"
  for t in base fixD; do echo "--- $t"; grep -hE "^summary|^api_summary" $t/03-score-100.log; grep -h "exit=" $t/03-score-100.log; done
  echo; echo "## 100-case: compare_scores.py base → fixD"; python3 $Q/compare_scores.py base/glm53-q2-100.tsv fixD/glm53-q2-100.tsv 2>&1 | tail -25
  echo; echo "## 100-case TSV byte comparison"; cmp base/glm53-q2-100.tsv fixD/glm53-q2-100.tsv && echo "IDENTICAL" || { echo "differ — columns that differ:"; diff <(cut -f1-12 base/glm53-q2-100.tsv) <(cut -f1-12 fixD/glm53-q2-100.tsv) | head -10; }
  echo; echo "## long cases summary lines"
  for t in base fixD; do echo "--- $t"; grep -hE "^summary|^api_summary" $t/04-score-long.log; grep -h "exit=" $t/04-score-long.log; done
  echo; echo "## long: compare_scores.py base → fixD"; python3 $Q/compare_scores.py base/glm53-q2-long.tsv fixD/glm53-q2-long.tsv 2>&1 | tail -15
  echo; echo "## MTP scenario (single-tier H200): failures and cycles"
  for r in base/05-server-mtp fixD/05-server-mtp fixD/05-server-nomtp base/05-server-nomtp; do [ -f $r.log ] && echo "$r: staged-launch-failed=$(grep -vE '^#' $r.log | grep -c 'staged decode weights launch failed') step-failed=$(grep -vE '^#' $r.log | grep -c 'glm mtp step failed') ACCEPT=$(grep -c 'cycle: .* ACCEPT' $r.log) reject=$(grep -c 'cycle: .* reject' $r.log)"; done
  echo; echo "## generated text per request from --trace (thinking included, trace metadata stripped)"
  for r in base/05-trace-mtp fixD/05-trace-mtp fixD/05-trace-nomtp base/05-trace-nomtp; do [ -f $r.txt ] && { awk '/^--- generated text ---$/{f=1;next} /^--- parsed message ---$/{f=0} f' $r.txt | grep -vE "^--- trace:|^\s*$" > $r.text.txt; echo "$(shasum -a 256 $r.text.txt | cut -c1-16)  $(wc -c < $r.text.txt | tr -d ' ') bytes  $r"; }; done
  for pair in "fixD/05-trace-mtp fixD/05-trace-nomtp" "base/05-trace-nomtp fixD/05-trace-nomtp" "base/05-trace-mtp base/05-trace-nomtp"; do set -- $pair; [ -f $1.text.txt ] && [ -f $2.text.txt ] && { printf "%s vs %s: " "$1" "$2"; cmp -s $1.text.txt $2.text.txt && echo IDENTICAL || echo "DIFFER ($(cmp $1.text.txt $2.text.txt | head -1))"; }; done
  echo; echo "## model-free: hashes bitwise where base launches (H200)"
  diff <(grep -E "^heads" base/02-hash-timing.log | sed 's/ median=.*//') <(grep -E "^heads" fixD/02-hash-timing.log | sed 's/ median=.*//' | grep -Ff <(grep -E "^heads" base/02-hash-timing.log | cut -d: -f1)) && echo "BITWISE IDENTICAL"
  echo; echo "## model identity"; cat model-identity.txt 2>/dev/null
} > 00-COMPARISON.txt 2>&1
find . -type f ! -name MANIFEST.sha256 -exec shasum -a 256 {} + | sort -k2 > MANIFEST.sha256
cat 00-COMPARISON.txt
