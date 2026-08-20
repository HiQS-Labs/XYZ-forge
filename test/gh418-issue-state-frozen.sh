#!/usr/bin/env bash
# test/gh418-issue-state-frozen.sh — GH-418.
# gate-evidence: {"form":"controlled-bad-fixture","observed":true,"result":"closed issue stayed advisory while the real GH-308 FROZEN artifact was refused"}
#
# The two measured cases are deliberately real shapes: a closed issue must still write an honest
# packet, while relay-automation/consult.sh's on-disk banner must stop a proposed write before any
# packet is emitted. `gh` is a hermetic JSON fixture, so neither assertion needs network/auth.

set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"
PY="$ROOT/utils/py/swarm_preflight.py"
WORK="$(mktemp -d "${TMPDIR:-/tmp}/gh418-preflight.XXXXXX")"
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/fixture-guard.sh"   # GH-10: shared fixture containment
fixture_guard_init "$WORK"   # GH-10: pin the sandbox root
trap 'rm -rf "$WORK"' EXIT

PASS=0; FAIL=0
pass() { echo "  PASS: $*"; PASS=$((PASS + 1)); }
fail() { echo "  FAIL: $*" >&2; FAIL=$((FAIL + 1)); }

echo "== test: gh418-issue-state-frozen =="
echo "  workdir: $WORK"

[ -f "$PY" ] || { fail "missing $PY"; exit 1; }

mkdir -p "$WORK/bin" "$WORK/issues"
cat >"$WORK/bin/gh" <<'STUB'
#!/usr/bin/env bash
n=""
json=""
while [ "$#" -gt 0 ]; do
  case "$1" in
    --json) shift; json="${1-}" ;;
    ''|*[!0-9]*) ;;
    *) n="$1" ;;
  esac
  shift
done
[ "$json" = "body,state,closedAt" ] || exit 2
[ -n "$n" ] && [ -f "$GH_STUB_DIR/$n.json" ] || exit 1
cat "$GH_STUB_DIR/$n.json"
STUB
chmod +x "$WORK/bin/gh"
export GH_STUB_DIR="$WORK/issues"

BODY='## Acceptance

- [ ] Change the implementation.
'
printf '{"body":%s,"state":"CLOSED","closedAt":"2026-08-06T15:46:01Z"}\n' \
  "$(python3 -c 'import json,sys; print(json.dumps(sys.argv[1]))' "$BODY")" >"$WORK/issues/418.json"
printf '{"body":%s,"state":"OPEN","closedAt":null}\n' \
  "$(python3 -c 'import json,sys; print(json.dumps(sys.argv[1]))' "$BODY")" >"$WORK/issues/419.json"

contract() {
  printf '{\n  "target": { "repo": ".", "ref": "main" },\n  "gate": "true",\n  "fix_probes": [ { "type": "path_absent", "path": "NEW_FILE.txt" } ],\n  "artifacts": [ "%s" ],\n  "remediation": { "source": "issue", "criteria": "test" }\n}' "$1"
}

capture() { # <repo> <issue> <artifact>
  local repo="$1" issue="$2" artifact="$3"
  mkdir -p "$repo/PROJECT/2-WORKING"
  {
    printf -- '---\ngh_issue: %s\nsource: https://github.com/example/repo/issues/%s\n---\n\n' "$issue" "$issue"
    printf '%s\n\n' "$BODY"
    printf '## Swarm Preflight Contract\n```json\n%s\n```\n' "$(contract "$artifact")"
  } >"$repo/PROJECT/2-WORKING/GH-$issue-case.md"
}

init_repo() {
  local repo="$1"
  git -C "$repo" init -q -b main 2>/dev/null || { git -C "$repo" init -q; git -C "$repo" symbolic-ref HEAD refs/heads/main; }
  git -C "$repo" -c user.email=t@t -c user.name=t add -A >/dev/null 2>&1
  git -C "$repo" -c user.email=t@t -c user.name=t commit -qm init >/dev/null 2>&1
}

# C1: CLOSED is conspicuous but advisory.  The emitted JSON and packet must carry its close time;
# pre-fix this case emitted a fully-green packet without either fact.
R1="$WORK/closed"; mkdir -p "$R1/src"; : >"$R1/src/a.py"
capture "$R1" 418 "src/a.py"
init_repo "$R1"
out="$(PATH="$WORK/bin:$PATH" SWARM_PREFLIGHT_ROOT="$R1" python3 "$PY" --target-root "$R1" \
  --project-doc "$R1/PROJECT/2-WORKING/GH-418-case.md" --out "$R1/packet" 2>&1)"; rc=$?
[ "$rc" -eq 0 ] && grep -q 'issue-state : CLOSED' <<<"$out" \
  && pass "C1 CLOSED issue is reported but remains fireable" \
  || fail "C1 expected advisory CLOSED output and exit 0 (rc=$rc): $out"
python3 - "$R1/packet/run-candidate.json" <<'PYEOF' && pass "C1b run-candidate records CLOSED state and close time" || fail "C1b issue state missing from run-candidate.json"
import json, sys
s = json.load(open(sys.argv[1]))["readiness"]["issue_state"]
raise SystemExit(0 if s == {"status": "CLOSED", "closed_at": "2026-08-06T15:46:01Z", "detail": "issue #418 is CLOSED since 2026-08-06T15:46:01Z"} else 1)
PYEOF
grep -q 'Source issue state: CLOSED' "$R1/packet/packet.md" \
  && grep -q '2026-08-06T15:46:01Z' "$R1/packet/packet.md" \
  && pass "C1c packet tells the builder the issue closed and when" \
  || fail "C1c packet reads fully green: $(cat "$R1/packet/packet.md" 2>/dev/null)"

# C1d: unavailable `gh` is not evidence of staleness.  The state must remain visible as unknown
# in both audit output and the emitted packet, while the lane stays fireable.
R1U="$WORK/unknown"; mkdir -p "$R1U/src"; : >"$R1U/src/a.py"
capture "$R1U" 420 "src/a.py"
init_repo "$R1U"
out1u="$(PATH="$WORK/bin:$PATH" SWARM_PREFLIGHT_ROOT="$R1U" python3 "$PY" --target-root "$R1U" \
  --project-doc "$R1U/PROJECT/2-WORKING/GH-420-case.md" --out "$R1U/packet" 2>&1)"; rc1u=$?
[ "$rc1u" -eq 0 ] && grep -q 'issue-state : unknown' <<<"$out1u" \
  && pass "C1d unknown issue state is reported but remains fireable" \
  || fail "C1d expected advisory unknown output and exit 0 (rc=$rc1u): $out1u"
python3 - "$R1U/packet/run-candidate.json" <<'PYEOF' && pass "C1e run-candidate records unknown state" || fail "C1e unknown issue state missing from run-candidate.json"
import json, sys
s = json.load(open(sys.argv[1]))["readiness"]["issue_state"]
raise SystemExit(0 if s["status"] == "unknown" and s["closed_at"] is None else 1)
PYEOF
grep -q 'Source issue state: unknown' "$R1U/packet/packet.md" \
  && pass "C1f packet makes unknown issue state explicit" \
  || fail "C1f packet hid unknown issue state: $(cat "$R1U/packet/packet.md" 2>/dev/null)"

# C2: this is Plan M's measured file, copied from the repository so the test proves the banner is
# read from disk rather than matched against an in-code list.  It must produce no packet at all.
R2="$WORK/frozen"; mkdir -p "$R2/relay-automation"
cp "$ROOT/relay-automation/consult.sh" "$R2/relay-automation/consult.sh"
capture "$R2" 419 "relay-automation/consult.sh"
init_repo "$R2"
out2="$(PATH="$WORK/bin:$PATH" SWARM_PREFLIGHT_ROOT="$R2" python3 "$PY" --target-root "$R2" \
  --project-doc "$R2/PROJECT/2-WORKING/GH-419-case.md" --out "$R2/packet" 2>&1)"; rc2=$?
[ "$rc2" -eq 5 ] && grep -q 'FROZEN.*relay-automation/consult.sh' <<<"$out2" \
  && grep -q 'utils/py/consult.py' <<<"$out2" \
  && pass "C2 real FROZEN write target is NOT-READY and names its Python twin" \
  || fail "C2 expected frozen refusal (rc=$rc2): $out2"
[ ! -e "$R2/packet" ] && pass "C2b FROZEN refusal writes no packet" \
  || fail "C2b FROZEN refusal emitted packet files: $(find "$R2/packet" -type f 2>/dev/null)"

# C3: inferred-test scanning must skip binary files. Before the sibling reader was hardened, this
# routine fixture shape raised UnicodeDecodeError before preflight could render any verdict.
R3="$WORK/binary-test"; mkdir -p "$R3/src" "$R3/test"; : >"$R3/src/a.py"
printf '\377\376\375' >"$R3/test/binary-fixture.bin"
capture "$R3" 419 "src/a.py"
init_repo "$R3"
out3="$(PATH="$WORK/bin:$PATH" SWARM_PREFLIGHT_ROOT="$R3" python3 "$PY" --target-root "$R3" \
  --project-doc "$R3/PROJECT/2-WORKING/GH-419-case.md" --out "$R3/packet" 2>&1)"; rc3=$?
[ "$rc3" -eq 0 ] && ! grep -q 'UnicodeDecodeError' <<<"$out3" \
  && pass "C3 binary inferred test is skipped without crashing preflight" \
  || fail "C3 expected binary inferred test to be skipped (rc=$rc3): $out3"

echo "  gh418-issue-state-frozen: $PASS pass, $FAIL fail"
[ "$FAIL" -eq 0 ] || exit 1
