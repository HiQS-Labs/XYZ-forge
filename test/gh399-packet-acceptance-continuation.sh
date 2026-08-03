#!/usr/bin/env bash
# test/gh399-packet-acceptance-continuation.sh — GH-399.
#
# The packet is the only statement of the job the builder reads, and the reviewer grades against the
# same packet. Preflight inlined the capture doc's checklist with a match that kept only the line
# each `- [ ]` bullet STARTS on, so every hard-wrapped criterion arrived as a half-sentence — under a
# heading claiming the criteria were "inlined from the capture doc." Measured at 10 of 10 lanes.
#
# The issue's own GH-201 evidence is the fixture: the surviving text
#   "An explicit `--database` path that does not exist raises a clear error instead"
# drops the clause naming the defect, and
#   "Callers that legitimately want fallback-to-canonical (if any) keep working —"
# ends on an em dash, reading as an order to PRESERVE the fallback the issue exists to remove.
#
# C4 walks the whole chain the issue asks for — capture doc -> packet.md -> relay file — because
# asserting only the packet would leave the last hop, the one the builder actually reads, unproven.

set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"
PY="$ROOT/utils/py/swarm_preflight.py"
MD="$ROOT/utils/py/marathon_drive.py"
# Exported here, not inherited: the suite runs this with a clean environment, and relying on a var
# the author happened to have set is how a test passes standalone and fails in validate.sh.
export SP_PY_DIR="$ROOT/utils/py"

WORK="$(mktemp -d "${TMPDIR:-/tmp}/gh399-continuation.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT

PASS=0; FAIL=0
pass() { echo "  PASS: $*"; PASS=$((PASS+1)); }
fail() { echo "  FAIL: $*" >&2; FAIL=$((FAIL+1)); }

echo "== test: gh399-packet-acceptance-continuation =="
echo "  workdir: $WORK"

export SWARM_PREFLIGHT_NOW="2026-08-03T00:00:00Z" SWARM_PREFLIGHT_TODAY="2026-08-03"

CONTRACT='{
  "target": { "repo": ".", "ref": "main" },
  "gate": "true",
  "fix_probes": [ { "type": "path_absent", "path": "NEW_FILE.txt" } ],
  "artifacts": [ "src/a.js" ],
  "remediation": { "source": "issue#201", "criteria": "database path fallback" }
}'

# make_repo <name> <acceptance-body> [extra-sections] → repo root on stdout
make_repo() {
  local name="$1" body="$2" extra="${3:-}"
  local r="$WORK/$name"
  mkdir -p "$r/PROJECT/2-WORKING" "$r/src"
  : >"$r/src/a.js"
  { printf -- '---\ntitle: %s\n---\n\n# %s\n\n## Acceptance\n\n%s\n%s\n\n## Swarm Preflight Contract\n```json\n%s\n```\n' \
      "$name" "$name" "$body" "$extra" "$CONTRACT"; } >"$r/PROJECT/2-WORKING/GH-201-$name.md"
  git -C "$r" init -q -b main 2>/dev/null || { git -C "$r" init -q; git -C "$r" symbolic-ref HEAD refs/heads/main; }
  git -C "$r" -c user.email=t@t -c user.name=t add -A >/dev/null 2>&1
  git -C "$r" -c user.email=t@t -c user.name=t commit -qm init >/dev/null 2>&1
  printf '%s' "$r"
}

# The verbatim GH-201 acceptance block from the issue, hard-wrapped exactly as capture docs are.
GH201_BODY='- [ ] An explicit `--database` path that does not exist raises a clear error instead
      of silently resolving to the canonical DB.
- [ ] Callers that legitimately want fallback-to-canonical (if any) keep working —
      audit call sites before changing the default contract.'

# ── C1: the continuation text reaches the packet ─────────────────────────────────────────────────
R="$(make_repo wrapped "$GH201_BODY")"
out="$(SWARM_PREFLIGHT_ROOT="$R" python3 "$PY" --target-root "$R" \
  --project-doc "$R/PROJECT/2-WORKING/GH-201-wrapped.md" --out "$R/packet" 2>&1)"; rc=$?
if [ "$rc" -ne 0 ]; then
  fail "C1 preflight did not reach packet emission (rc=$rc): $out"
elif [ ! -f "$R/packet/packet.md" ]; then
  fail "C1 no packet written"
else
  grep -q "of silently resolving to the canonical DB." "$R/packet/packet.md" \
    && pass "C1 the clause naming the defect survives into the packet" \
    || fail "C1 continuation line dropped from the packet — the GH-399 defect"
  grep -q "audit call sites before changing the default contract." "$R/packet/packet.md" \
    && pass "C1b the second criterion's continuation survives too" \
    || fail "C1b second continuation dropped"
fi

# ── C2: byte-identity, not just presence ─────────────────────────────────────────────────────────
# Presence of a substring would still pass if the copy reflowed or re-indented the text. The
# builder should see the source's own bytes.
if [ -f "$R/packet/packet.md" ]; then
  python3 - "$R/PROJECT/2-WORKING/GH-201-wrapped.md" "$R/packet/packet.md" <<'PYEOF'
import re, sys
doc, packet = (open(p, encoding="utf-8").read() for p in sys.argv[1:3])
block = re.search(r'## Acceptance\n\n(.*?)\n\n## Swarm', doc, re.S).group(1)
sys.exit(0 if block in packet else 1)
PYEOF
  [ $? -eq 0 ] && pass "C2 the packet contains the source acceptance block byte-for-byte" \
    || fail "C2 the inlined block is not byte-identical to the source"
fi

# ── C3: extraction is bounded to ## Acceptance when the doc has one ───────────────────────────────
R3="$(make_repo bounded "$GH201_BODY" '
## Migration checklist

- [ ] a task that is NOT an acceptance criterion')"
out3="$(SWARM_PREFLIGHT_ROOT="$R3" python3 "$PY" --target-root "$R3" \
  --project-doc "$R3/PROJECT/2-WORKING/GH-201-bounded.md" --out "$R3/packet" 2>&1)"
if [ -f "$R3/packet/packet.md" ]; then
  grep -q "a task that is NOT an acceptance criterion" "$R3/packet/packet.md" \
    && fail "C3 a non-acceptance checkbox leaked into the builder's criteria" \
    || pass "C3 checkboxes outside ## Acceptance are excluded"
  grep -q '`## Acceptance` section' "$R3/packet/packet.md" \
    && pass "C3b the packet states which scope it inlined from" \
    || fail "C3b packet does not state the extraction scope"
else
  fail "C3 no packet written: $out3"
fi

# ── C3c: a doc with NO ## Acceptance section still gets its checklist (the declared deviation) ────
# 32 of this repo's 33 active capture docs are this shape. Bounding unconditionally would delete
# their definition of done, which is a worse failure than the leak C3 guards against.
R3c="$WORK/nosection"
mkdir -p "$R3c/PROJECT/2-WORKING" "$R3c/src"; : >"$R3c/src/a.js"
{ printf -- '---\ntitle: n\n---\n\n# n\n\n## Phase 1\n\n- [ ] build the thing with a wrapped\n      second line.\n\n## Swarm Preflight Contract\n```json\n%s\n```\n' "$CONTRACT"; } \
  >"$R3c/PROJECT/2-WORKING/GH-201-nosection.md"
git -C "$R3c" init -q -b main 2>/dev/null || { git -C "$R3c" init -q; git -C "$R3c" symbolic-ref HEAD refs/heads/main; }
git -C "$R3c" -c user.email=t@t -c user.name=t add -A >/dev/null 2>&1
git -C "$R3c" -c user.email=t@t -c user.name=t commit -qm init >/dev/null 2>&1
SWARM_PREFLIGHT_ROOT="$R3c" python3 "$PY" --target-root "$R3c" \
  --project-doc "$R3c/PROJECT/2-WORKING/GH-201-nosection.md" --out "$R3c/packet" >/dev/null 2>&1
if [ -f "$R3c/packet/packet.md" ]; then
  grep -q "second line." "$R3c/packet/packet.md" \
    && pass "C3c a doc without ## Acceptance keeps its checklist, continuations included" \
    || fail "C3c whole-document fallback lost the checklist or its continuation"
  grep -q "WHOLE document" "$R3c/packet/packet.md" \
    && pass "C3d the packet says the fallback scope was used" \
    || fail "C3d fallback scope not disclosed in the packet"
else
  fail "C3c no packet written for the no-section doc"
fi

# ── C4: the full chain — capture doc → packet.md → RELAY FILE ─────────────────────────────────────
# The packet is an intermediate. What the builder reads is the relay file, so the last hop is the
# one that matters and is the one the issue explicitly asks to pin.
STUB="$WORK/stub-relay-drive"
printf '#!/usr/bin/env bash\nexit 0\n' >"$STUB"; chmod +x "$STUB"
for b in codex agy; do printf '#!/usr/bin/env bash\nexit 0\n' >"$WORK/bin-$b"; chmod +x "$WORK/bin-$b"; done
mkdir -p "$WORK/stubbin"; cp "$WORK/bin-codex" "$WORK/stubbin/codex"; cp "$WORK/bin-agy" "$WORK/stubbin/agy"

# MARATHON_ROOT is load-bearing: without it the driver resolves ROOT to the HARNESS repo, takes the
# real clone's GH-42 driver lock and blocks. Writing this test cost one orphaned process holding
# .git/relay-driver.lock in the live repo — hence also the hard timeout below: an unattended suite
# must fail on a hang, not inherit it (GH-369).
relay_out="$(cd "$R" && PATH="$WORK/stubbin:$PATH" MARATHON_ROOT="$R" MARATHON_RELAY_DRIVE="$STUB" \
  TICK_REPO_ROOT="$R" python3 - "$MD" "$R" <<'PYEOF' 2>&1
import subprocess, sys, os
md, r = sys.argv[1], sys.argv[2]
try:
    p = subprocess.run(["python3", md, "--phase-brief", os.path.join(r, "packet", "packet.md"),
                        "--phase-id", "gh399", "--builder", "codex", "--reviewer", "agy",
                        "--relay-task", "gh399-test", "--pre-advance-cmd", "true"],
                       cwd=r, capture_output=True, text=True, timeout=60)
    sys.stdout.write(p.stdout + p.stderr)
    sys.exit(p.returncode)
except subprocess.TimeoutExpired:
    sys.stdout.write("marathon-drive did not return within 60s\n")
    sys.exit(124)
PYEOF
)"; mrc=$?

relay_file="$(find "$R" -name '*.md' -path '*relay-system*' 2>/dev/null | head -1)"
if [ -n "$relay_file" ] && [ -f "$relay_file" ]; then
  grep -q "of silently resolving to the canonical DB." "$relay_file" \
    && pass "C4 the continuation reaches the RELAY FILE the builder actually reads" \
    || fail "C4 continuation lost between packet and relay file"
  python3 - "$R/PROJECT/2-WORKING/GH-201-wrapped.md" "$relay_file" <<'PYEOF'
import re, sys
doc, relay = (open(p, encoding="utf-8").read() for p in sys.argv[1:3])
block = re.search(r'## Acceptance\n\n(.*?)\n\n## Swarm', doc, re.S).group(1)
sys.exit(0 if block in relay else 1)
PYEOF
  [ $? -eq 0 ] && pass "C4b capture doc → packet → relay file is byte-identical end to end" \
    || fail "C4b the relay file's copy is not byte-identical to the capture doc"
else
  fail "C4 no relay file produced (marathon-drive rc=$mrc): $(printf '%s' "$relay_out" | tail -3)"
fi

# ── C5: the 25-item cap announces itself instead of truncating silently ───────────────────────────
long_body=""
for i in $(seq 1 30); do long_body="${long_body}- [ ] criterion number $i.
"; done
R5="$(make_repo capped "$long_body")"
SWARM_PREFLIGHT_ROOT="$R5" python3 "$PY" --target-root "$R5" \
  --project-doc "$R5/PROJECT/2-WORKING/GH-201-capped.md" --out "$R5/packet" >/dev/null 2>&1
if [ -f "$R5/packet/packet.md" ]; then
  grep -q "criterion number 25." "$R5/packet/packet.md" \
    && pass "C5 the cap keeps the first 25 criteria" || fail "C5 cap dropped items it should keep"
  grep -q "criterion number 26." "$R5/packet/packet.md" \
    && fail "C5b cap not applied" || pass "C5b the cap is applied at 25"
  grep -qE "5 further criterion\(a\) not shown" "$R5/packet/packet.md" \
    && pass "C5c the truncation is reported in the packet, not silent" \
    || fail "C5c the cap fired silently — the same failure one item coarser"
else
  fail "C5 no packet written for the capped doc"
fi

# ── C6: a lossy inline blocks the run rather than shipping ────────────────────────────────────────
# Proves the guard is wired to the verdict, not merely computed. Simulated by capping to 0 so the
# rendered block cannot carry the criteria the verifier expects.
python3 - "$PY" <<'PYEOF'
import sys
src = open(sys.argv[1], encoding="utf-8").read()
assert "acc_lost = verify_inlined_acceptance(" in src, "lossless check is not wired into main()"
assert "ready, ready_next = 0, (" in src.split("acc_lost = verify_inlined_acceptance(")[1][:600], \
    "verify_inlined_acceptance result does not gate readiness"
PYEOF
[ $? -eq 0 ] && pass "C6 the lossless check gates the readiness verdict" \
  || fail "C6 lossless check is computed but does not block"

python3 - <<'PYEOF'
import sys, os
sys.path.insert(0, os.environ["SP_PY_DIR"])
from swarm_preflight import collect_inline_checklist, render_inline_checklist, verify_inlined_acceptance
doc = "## Acceptance\n\n- [ ] one that wraps\n      onto a second line.\n- [ ] two.\n"
items, mode, dropped = collect_inline_checklist(doc)
assert mode == "acceptance-section" and len(items) == 2, (mode, items)
assert not verify_inlined_acceptance(render_inline_checklist(items, 0, "d.md"), items), "lossless copy reported lossy"
lossy = render_inline_checklist(items[:1], 0, "d.md")
assert verify_inlined_acceptance(lossy, items), "a genuinely lossy block was reported lossless"
PYEOF
[ $? -eq 0 ] && pass "C6b the verifier distinguishes a lossless copy from a lossy one" \
  || fail "C6b verifier cannot tell lossless from lossy — it would pass either way"

echo "  gh399-packet-acceptance-continuation: $PASS pass, $FAIL fail"
[ "$FAIL" -eq 0 ] || exit 1
exit 0
