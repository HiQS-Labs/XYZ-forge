#!/usr/bin/env bash
# gate-evidence: {"form":"pre-fix-replay","observed":true,"result":"a temporary copy with the GH-425 slug guard removed accepted a foreign repository's same-numbered issue; the real lane refuses it while accepting source=tracking plus related=origin"}
# GH-425 — source: identifies the tracking issue; related: retains a foreign origin.
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"
PY="$ROOT/utils/py/swarm_preflight.py"
WORK="$(mktemp -d "${TMPDIR:-/tmp}/gh425-source-url-slug.XXXXXX")"
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/fixture-guard.sh"   # GH-10: shared fixture containment
fixture_guard_init "$WORK"   # GH-10: pin the sandbox root
trap 'rm -rf "$WORK"' EXIT

PASS=0; FAIL=0
pass() { echo "  PASS: $*"; PASS=$((PASS + 1)); }
fail() { echo "  FAIL: $*" >&2; FAIL=$((FAIL + 1)); }

echo "== test: gh425-source-url-slug =="
echo "  workdir: $WORK"
[ -f "$PY" ] || { fail "missing $PY"; exit 1; }

# Preflight requires a successful `git fetch`, but this gate needs the literal GitHub origin URL
# that `repo_slug_for()` reads. Stub only fetch; every other git operation reaches the real binary.
REAL_GIT="$(command -v git)"
mkdir -p "$WORK/bin"
cat >"$WORK/bin/git" <<EOF
#!/usr/bin/env bash
for arg in "\$@"; do
  [ "\$arg" = fetch ] && exit 0
done
exec "$REAL_GIT" "\$@"
EOF
chmod +x "$WORK/bin/git"

TRACKING_SLUG="Acme-Org/tracking-repo"
TRACKING_URL="https://github.com/$TRACKING_SLUG/issues/94"
ORIGIN_URL="https://github.com/Upstream/origin-repo/issues/2"
SAME_NUMBER_FOREIGN="https://github.com/SomeoneElse/unrelated-repo/issues/94"
CONTRACT='{
  "target": { "repo": ".", "ref": "main" },
  "gate": "true",
  "fix_probes": [ { "type": "path_absent", "path": "NEW_FILE.txt" } ],
  "artifacts": [ "src/a.py" ],
  "remediation": { "source": "issue#94", "criteria": "x" }
}'

init_repo() { # <repo>
  git -C "$1" init -q -b main 2>/dev/null || { git -C "$1" init -q; git -C "$1" symbolic-ref HEAD refs/heads/main; }
  git -C "$1" remote add origin "https://github.com/$TRACKING_SLUG.git"
  git -C "$1" -c user.email=t@t -c user.name=t add -A >/dev/null 2>&1
  git -C "$1" -c user.email=t@t -c user.name=t commit -qm fixture >/dev/null 2>&1
}

capture() { # <repo> <source> [related-line]
  mkdir -p "$1/PROJECT/2-WORKING" "$1/src"; : >"$1/src/a.py"
  printf -- '---\ntitle: GH-425 fixture\ngh_issue: 94\nsource: %s\n%s---\n\n## Acceptance\n\n- [ ] a criterion.\n\n## Swarm Preflight Contract\n```json\n%s\n```\n' \
    "$2" "${3-}" "$CONTRACT" >"$1/PROJECT/2-WORKING/GH-94-fixture.md"
}

run_preflight() { # <python> <repo>
  PATH="$WORK/bin:$PATH" SWARM_PREFLIGHT_ROOT="$2" SWARM_PREFLIGHT_NOW="2026-08-08T00:00:00Z" \
    SWARM_PREFLIGHT_TODAY="2026-08-08" python3 "$1" --target-root "$2" \
    --project-doc "$2/PROJECT/2-WORKING/GH-94-fixture.md" --out "$2/packet" 2>&1
}

# C1: the false-negative half — same issue number from another repository is not provenance.
R_BAD="$WORK/foreign-same-number"; capture "$R_BAD" "$SAME_NUMBER_FOREIGN"; init_repo "$R_BAD"
out_bad="$(run_preflight "$PY" "$R_BAD")"; rc_bad=$?
[ "$rc_bad" -eq 5 ] && grep -q 'source URL wrong-repository' <<<"$out_bad" \
  && pass "C1 same-number foreign repository is NOT-READY" \
  || fail "C1 expected wrong-repository exit 5, got $rc_bad: $out_bad"
grep -q 'move the foreign issue URL into `related:`' <<<"$out_bad" \
  && pass "C1b wrong-repository remediation preserves the foreign origin" \
  || fail "C1b remediation did not name related:: $out_bad"
[ ! -f "$R_BAD/packet/packet.md" ] && pass "C1c refusal writes no packet" \
  || fail "C1c foreign provenance emitted a packet"

# Negative control: remove only the new slug branch in a disposable copy.  It must reproduce the
# pre-GH-425 false green; a control that stays red cannot demonstrate this check's discrimination.
PREFIX="$WORK/swarm_preflight.pre-gh425.py"
cp "$PY" "$PREFIX"
cp "$(dirname "$PY")/harness_paths.py" "$WORK/"
python3 - "$PREFIX" <<'PYEOF'
from pathlib import Path
import sys

path = Path(sys.argv[1])
source = path.read_text(encoding="utf-8")
new = '''    if not slug_matches:
        res["status"] = "wrong-repository"
        number_note = "the same issue number" if number_matches else f"issue #{u.group(2)}"
        res["detail"] = (
            f"source: points at repository {res['slug']} ({number_note}), but tracking issue "
            f"#{issue_number} belongs to {tracking_slug} — `source:` must cite the tracking "
            "repository; preserve any cross-repo origin under `related:`")
        return res

'''
if new not in source:
    raise SystemExit("could not construct exact pre-GH-425 control")
path.write_text(source.replace(new, ""), encoding="utf-8")
PYEOF
R_CONTROL="$WORK/pre-fix-control"; capture "$R_CONTROL" "$SAME_NUMBER_FOREIGN"; init_repo "$R_CONTROL"
out_control="$(run_preflight "$PREFIX" "$R_CONTROL")"; rc_control=$?
[ "$rc_control" -eq 0 ] && [ -f "$R_CONTROL/packet/packet.md" ] \
  && pass "C2 pre-GH-425 control reproduces the false READY verdict" \
  || fail "C2 expected pre-fix false green, got $rc_control: $out_control"

# C3: option 1's cross-repo shape is accepted: source stays local, related retains the origin.
R_OK="$WORK/tracking-plus-related"; capture "$R_OK" "$TRACKING_URL" $'related:\n  - "'"$ORIGIN_URL"$' — originating issue"\n'; init_repo "$R_OK"
out_ok="$(run_preflight "$PY" "$R_OK")"; rc_ok=$?
[ "$rc_ok" -eq 0 ] && [ -f "$R_OK/packet/packet.md" ] \
  && pass "C3 tracking source plus foreign related origin is READY" \
  || fail "C3 documented cross-repo shape was refused (rc=$rc_ok): $out_ok"

# C4: a local repository with the wrong number is a distinct operator correction.
R_NUMBER="$WORK/local-wrong-number"; capture "$R_NUMBER" "https://github.com/$TRACKING_SLUG/issues/2"; init_repo "$R_NUMBER"
out_number="$(run_preflight "$PY" "$R_NUMBER")"; rc_number=$?
[ "$rc_number" -eq 5 ] && grep -q 'tracking repository is right, but the tracking issue number is wrong' <<<"$out_number" \
  && pass "C4 local wrong issue number is distinguished from wrong repository" \
  || fail "C4 wrong-number diagnostic was not distinct (rc=$rc_number): $out_number"

echo "  gh425-source-url-slug: $PASS pass, $FAIL fail"
[ "$FAIL" -eq 0 ]
