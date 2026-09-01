#!/usr/bin/env bash
# GH-362 — the marathon planner must read link-style `- [Title](path)` ledger bullets.
#
# GH-349 made them first class in releases_app.py (`_is_ledger_bullet`), and that file's
# parse_roadmap_ledger docstring promises "the same block boundaries as the planner". Both planner
# engines tested `- **` only, so a ROADMAP written entirely in link bullets parsed as ZERO items
# and the run died `exit 3` with "no ledger items parsed (is '## Ledger' present?)" — naming the
# one thing that was not wrong. wave_reconcile runs the planner as a mandatory step, so the
# post-merge closeout was unrunnable in such a repo (LTVera-Pandas, 2026-09-01).
#
# Both engines are asserted: XYZ_PYTHON=1 (the default, utils/py/_marathon_plan.py) and
# XYZ_PYTHON=0 (the Bash/node fallback). _marathon_plan.py says the two are mirrored, so a fix
# that lands in only one of them is a latent regression the day the default flips.
#
# Usage: bash test/gh362-marathon-plan-link-bullets.sh
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$HERE/.." && pwd)"
# shellcheck source=/dev/null
source "$HERE/_setup.sh" gh362-marathon-plan-link-bullets

command -v python3 >/dev/null 2>&1 || { echo "python3 required" >&2; exit 1; }
command -v node >/dev/null 2>&1 || { echo "node required" >&2; exit 1; }

R="$WORK/repo"
case "$R" in "$WORK"/*) ;; *) echo "REFUSING: $R outside WORK" >&2; exit 2 ;; esac
mkdir -p "$R/utils" "$R/PROJECT/1-INBOX"
cp -R "$ROOT_DIR/utils/." "$R/utils/"
git -C "$R" init -q
git -C "$R" -c user.email=t@t -c user.name=t commit -q --allow-empty -m base
touch "$R/PROJECT/1-INBOX/GH-777-LINK-BULLET.md"

# A ledger written the way GH-349 sanctions: every entry a link bullet. The body deliberately
# mentions a DIFFERENT issue in prose, so a title taken from the whole block would mis-key the row.
cat > "$R/ROADMAP.md" <<'MD'
# Roadmap

## Ledger

### Queue / parked intake
- [GH-777 — the link-bullet entry](PROJECT/1-INBOX/GH-777-LINK-BULLET.md) — captured 2026-09-01.
  Follows on from GH-888, which is only referenced here and must not become this row's key.
- [ ] a task-list item that is not a ledger entry at all
- [x] a completed task-list item, likewise

### In progress

### Completed

### Deferred · vision
MD

# marathon-plan resolves its root from its OWN location, so drive the fixture's copy.
PLAN="$R/utils/marathon-plan.sh"

run_engine() { # <XYZ_PYTHON value> <label>
  local mode="$1" label="$2" out="$WORK/out.$1" rc=0
  XYZ_PYTHON="$mode" QUEUE_PLAN_OFFLINE=1 bash "$PLAN" --format json --dry-run \
    > "$out" 2> "$WORK/err.$1" || rc=$?

  [ "$rc" != "3" ] \
    && pass "$label: ledger of link bullets parsed (no exit 3)" \
    || { sed 's/^/    /' "$WORK/err.$1" >&2; fail "$label: exited 3 — link bullets still unparsed"; }
  grep -q "no ledger items parsed" "$WORK/err.$1" \
    && fail "$label: still reports 'no ledger items parsed' on a populated ledger" \
    || pass "$label: no 'no ledger items parsed' complaint"

  # The GH key must come from the link LABEL (777), never from prose (888).
  python3 - "$out" "$label" <<'PY'
import json, sys
out, label = sys.argv[1], sys.argv[2]
rows = []
for line in open(out):
    line = line.strip()
    if line.startswith("{"):
        try: rows.append(json.loads(line))
        except ValueError: pass
blob = json.dumps(rows)
sys.exit(0 if ("GH-777" in blob or "777" in blob) and "888" not in blob else 1)
PY
  [ $? = 0 ] \
    && pass "$label: the row is keyed to 777 from the link label, not to 888 from prose" \
    || { sed 's/^/    /' "$out" >&2; fail "$label: wrong GH key — the title took the whole block"; }

  # Task-list items must not have become entries.
  grep -q "task-list item" "$out" \
    && { sed 's/^/    /' "$out" >&2; fail "$label: a '- [ ]' task-list item parsed as a ledger entry"; } \
    || pass "$label: '- [ ]' / '- [x]' task-list items are still not ledger entries"
}

run_engine 1 "python engine (default)"
run_engine 0 "bash/node engine"

# ── negative control: a bold-bullet ledger must still parse, unchanged ──────────────────────────
cat > "$R/ROADMAP.md" <<'MD'
# Roadmap

## Ledger

### Queue / parked intake
- **GH-777 — the bold entry** (2026-09-01) - [doc](PROJECT/1-INBOX/GH-777-LINK-BULLET.md)

### In progress

### Completed

### Deferred · vision
MD
rc=0
XYZ_PYTHON=1 QUEUE_PLAN_OFFLINE=1 bash "$PLAN" --format json --dry-run > "$WORK/out.bold" 2>"$WORK/err.bold" || rc=$?
[ "$rc" != "3" ] \
  && pass "bold bullets still parse — the fix widened the grammar, it did not swap it" \
  || { sed 's/^/    /' "$WORK/err.bold" >&2; fail "REGRESSION: a bold-bullet ledger now fails to parse"; }

echo "  $TEST_NAME: $PASS pass, $FAIL fail"
[ "$FAIL" = "0" ] || exit 1
exit 0
