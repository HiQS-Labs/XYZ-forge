#!/usr/bin/env bash
# test/preflight-docs.sh — GH-78: offline coverage for utils/telemetry/preflight-docs.sh.
# Uses a STUB PDDA_LLM_BIN (no real model) to exercise every branch: no-LLM warn, clean pass, a safe
# contract-enforcing edit that is APPLIED, an unsafe edit that is REJECTED+reverted, a model-declined
# warn, and inbox-capture (ROADMAP-queued) targeting.
source "$(dirname "$0")/_setup.sh" preflight-docs
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SCRIPT="$ROOT/utils/telemetry/preflight-docs.sh"

REPO="$WORK/repo"
mkdir -p "$REPO/PROJECT/2-WORKING" "$REPO/PROJECT/1-INBOX"

# ── fixture docs ─────────────────────────────────────────────────────────────
# A fully contract-clean working doc.
cat >"$REPO/PROJECT/2-WORKING/CLEAN.md" <<'EOF'
---
title: Clean doc
status: Active
created: 2026-06-24
updated: 2026-06-24
owner: test
goal: stay clean
---

## Status

| What was just completed | What's next |
|---|---|
| seeded | verify |
EOF

# The broken working doc: missing the required `goal` key (exactly 1 deterministic error).
ORIG="$WORK/broken-orig.md"
cat >"$ORIG" <<'EOF'
---
title: Broken doc
status: Active
created: 2026-06-24
updated: 2026-06-24
owner: test
---

## Status

| What was just completed | What's next |
|---|---|
| seeded | verify |
EOF

# The contract-clean corrected version the stub returns for the "fix" case (adds `goal`).
FIXED="$WORK/broken-fixed.md"
cat >"$FIXED" <<'EOF'
---
title: Broken doc
status: Active
created: 2026-06-24
updated: 2026-06-24
owner: test
goal: added by preflight
---

## Status

| What was just completed | What's next |
|---|---|
| seeded | verify |
EOF

# A broken inbox capture parked in ROADMAP (missing required `doc_type`).
cat >"$REPO/PROJECT/1-INBOX/GH-9001-TEST.md" <<'EOF'
---
gh_issue: 9001
source: https://example.com/issues/9001
title: Test intake
status: Proposed (1-INBOX — not yet active)
created: 2026-06-24
---

Short capture.
EOF

cat >"$REPO/ROADMAP.md" <<'EOF'
# Roadmap

## Queue / parked intake

- Test intake → [GH-9001-TEST.md](PROJECT/1-INBOX/GH-9001-TEST.md)
EOF

BROKEN="$REPO/PROJECT/2-WORKING/BROKEN.md"
seed_broken() { cp "$ORIG" "$BROKEN"; }

# ── stub model CLI ───────────────────────────────────────────────────────────
STUB="$WORK/stub-llm.sh"
cat >"$STUB" <<'EOF'
#!/usr/bin/env bash
cat >/dev/null   # consume the prompt on stdin
case "${STUB_MODE:-}" in
  fix)    printf 'ACTION: edit\nREASON: added missing goal key\n---BEGIN-DOC---\n'; cat "$STUB_FIXED_DOC"; printf '%s\n' '---END-DOC---' ;;
  unsafe) printf 'ACTION: edit\nREASON: pretend fix\n---BEGIN-DOC---\n';           cat "$STUB_ORIG_DOC";  printf '%s\n' '---END-DOC---' ;;
  warn)   printf 'ACTION: warn\nREASON: needs human judgment\n' ;;
  *)      printf 'ACTION: clean\nREASON: n/a\n' ;;
esac
EOF
chmod +x "$STUB"

run_preflight() {  # run_preflight <logdir> [PDDA_LLM_BIN]
  local logdir="$1" bin="${2:-}"
  PDDA_REPO_ROOT="$REPO" \
  PDDA_WORKING_DIR="$REPO/PROJECT/2-WORKING" \
  PDDA_INBOX_DIR="$REPO/PROJECT/1-INBOX" \
  PDDA_ROADMAP="$REPO/ROADMAP.md" \
  PREFLIGHT_LOG_DIR="$logdir" \
  PDDA_LLM_BIN="$bin" \
  STUB_MODE="${STUB_MODE:-}" STUB_FIXED_DOC="$FIXED" STUB_ORIG_DOC="$ORIG" \
  bash "$SCRIPT" >/dev/null 2>&1
}

logline() { grep "\"doc\": \"[^\"]*$1\"" "$2/$(date +%Y-%m-%d).jsonl" 2>/dev/null; }
has() { logline "$1" "$3" | grep -q "\"action\": \"$2\""; }

# ── Case 1: no LLM — review+warn only, no edits ──────────────────────────────
seed_broken
L1="$WORK/log1"; run_preflight "$L1" ""
rc=$?
[ "$rc" -eq 0 ] && pass "exits 0 with no PDDA_LLM_BIN (never blocks)" || fail "non-zero exit ($rc) with no LLM"
has BROKEN.md warn "$L1"   && pass "no-LLM: broken working doc logged as warn" || fail "no-LLM: broken doc not warned"
has CLEAN.md clean "$L1"   && pass "no-LLM: clean working doc logged as clean" || fail "no-LLM: clean doc not marked clean"
has GH-9001-TEST.md warn "$L1" && pass "no-LLM: ROADMAP-queued inbox capture is targeted + warned" || fail "inbox capture not targeted"
grep -q '"goal"' "$BROKEN" && fail "no-LLM run edited the doc (must not)" || pass "no-LLM: doc left unedited"

# ── Case 2: model declines (ACTION: warn) — no edit ──────────────────────────
seed_broken
L2="$WORK/log2"; STUB_MODE=warn run_preflight "$L2" "$STUB"
has BROKEN.md warn "$L2" && pass "model-declines: logged as warn" || fail "model-declines: not warned"
grep -q '"goal"' "$BROKEN" && fail "model-declines run edited the doc" || pass "model-declines: doc left unedited"

# ── Case 3: unsafe edit (no improvement) — reverted + warn ───────────────────
seed_broken
L3="$WORK/log3"; STUB_MODE=unsafe run_preflight "$L3" "$STUB"
has BROKEN.md warn "$L3" && pass "unsafe-edit: rejected and logged as warn" || fail "unsafe-edit: not warned"
grep -q 'unsafe edit reverted' <<<"$(logline BROKEN.md "$L3")" && pass "unsafe-edit: summary records the revert" || fail "unsafe-edit: revert not recorded"
grep -q '"goal"' "$BROKEN" && fail "unsafe-edit was NOT reverted (doc changed)" || pass "unsafe-edit: doc reverted to original"

# ── Case 4: safe edit — applied + logged ─────────────────────────────────────
seed_broken
L4="$WORK/log4"; STUB_MODE=fix run_preflight "$L4" "$STUB"
has BROKEN.md edit "$L4" && pass "safe-edit: logged as edit" || fail "safe-edit: not logged as edit"
grep -q '"safe": true' <<<"$(logline BROKEN.md "$L4")" && pass "safe-edit: marked safe" || fail "safe-edit: not marked safe"
grep -q '^goal: added by preflight' "$BROKEN" && pass "safe-edit: contract fix applied to the doc" || fail "safe-edit: fix not written"

# ── every telemetry line is valid JSON ───────────────────────────────────────
python3 -c "import json,glob,sys
for f in glob.glob('$WORK/log*/*.jsonl'):
    for ln in open(f):
        json.loads(ln)
print('ok')" >/dev/null 2>&1 && pass "all telemetry lines are valid JSON" || fail "telemetry produced invalid JSON"

echo "  $TEST_NAME: $PASS pass, $FAIL fail"
exit 0
