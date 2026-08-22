source "$(dirname "$0")/_setup.sh" gh165-governance-canonical-paths-guard
XYZ_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

PASS=0
FAIL=0

pass() {
  echo "  ✅ PASS: $1"
  PASS=$((PASS + 1))
}

fail() {
  echo "  ❌ FAIL: $1 (got: $2, expected: $3)"
  FAIL=$((FAIL + 1))
}

echo "=== Running gh165-governance-canonical-paths-guard.sh ==="

# Invariant 1: wave_reconcile.py is the ONLY script that actually executes file moves into 3-COMPLETED
# (Excluding wave_reconcile.py, test suites, and documentation)
illegal_doc_movers=$(grep -rn "3-COMPLETED" "$XYZ_ROOT/utils" "$XYZ_ROOT/relay-automation" "$XYZ_ROOT/skills" \
  --exclude="wave_reconcile.py" \
  --exclude="*.md" \
  --exclude="*.txt" \
  --exclude="*.json" \
  --exclude="*.jsonl" \
  --exclude="*.html" \
  --exclude="*.bak" \
  --exclude="*.pyc" \
  2>/dev/null | grep -vE "(#|//|\"|'|recommend:)" | grep -E "(mv |rename|os\.replace|shutil\.move)" | grep -v "test" || true)

if [ -z "$illegal_doc_movers" ]; then
  pass "No unauthorized scripts move active docs into 3-COMPLETED"
else
  fail "No unauthorized scripts move active docs into 3-COMPLETED" "$illegal_doc_movers" "empty"
fi

# Invariant 2: pdda.sh and pdda-lib.sh maintain strict read-only purity (zero write operations to ROADMAP.md or releases.db)
illegal_pdda_writes=$(grep -En "(^\s*(git mv|mv|rm|cp)\s+.*ROADMAP\.md|^\s*(git mv|mv|rm|cp)\s+.*releases\.(db|sql))" \
  "$XYZ_ROOT/utils/pdda/pdda.sh" "$XYZ_ROOT/utils/pdda/pdda-lib.sh" 2>/dev/null || true)

if [ -z "$illegal_pdda_writes" ]; then
  pass "pdda.sh and pdda-lib.sh maintain strict read-only purity"
else
  fail "pdda.sh and pdda-lib.sh maintain strict read-only purity" "$illegal_pdda_writes" "empty"
fi

# Invariant 3: standup triage.py never mutates ROADMAP.md, releases.db, or PROJECT active docs
illegal_triage_writes=$(grep -En "open\(.*(ROADMAP\.md|releases\.db|releases\.sql|PROJECT/3-COMPLETED)" \
  "$XYZ_ROOT/skills/standup/triage.py" 2>/dev/null || true)

if [ -z "$illegal_triage_writes" ]; then
  pass "skills/standup/triage.py maintains strict read-only purity on governance ledgers"
else
  fail "skills/standup/triage.py maintains strict read-only purity on governance ledgers" "$illegal_triage_writes" "empty"
fi

# Invariant 4: No new .sh executable introduced under utils/ or relay-automation/ (GH-551)
if [ -f "$XYZ_ROOT/utils/wave-reconcile.sh" ]; then
  fail "No new .sh wrapper in utils/ (GH-551)" "found utils/wave-reconcile.sh" "must be Python only"
else
  pass "No new .sh wrapper in utils/ (GH-551 invariant preserved)"
fi

echo "=== gh165-governance-canonical-paths-guard.sh Results: $PASS passed, $FAIL failed ==="
if [ "$FAIL" -gt 0 ]; then
  exit 1
fi
exit 0
