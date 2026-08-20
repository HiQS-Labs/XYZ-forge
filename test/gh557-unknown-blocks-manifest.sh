#!/usr/bin/env bash
# test/gh557-unknown-blocks-manifest.sh — GH-557.
#
# THE DEFECT. `check_acceptance_fidelity` returned one of match/diverged/unknown, and only
# `diverged` blocked. `unknown` fell through to `ready (exit 0)`. But `unknown` was returned for
# materially different situations that the packet printed identically:
#
#   * transient — `gh` missing, unauthenticated, or offline. Retryable, nobody's fault.
#   * structural — the ISSUE ITSELF states no `## Acceptance` section, so the capture doc's criteria
#     came from somewhere else and no retry will ever verify them.
#
# Observed live on 2026-08-15 against Meter manifest member #382, with `gh` authenticated and the
# network healthy:
#
#     inlined-acc : 6 criterion(a) from the acceptance-section
#     acceptance  : unknown — issue #382 has no '## Acceptance' section — nothing to copy from
#     verdict     : ready (exit 0)
#
# Six criteria, no source, lane declared ready. That is GH-400's failure arriving through GH-400's
# own pass-through case. It also hid a diagnosis: during the 2026-08-14 DNS outage every Meter packet
# read `unknown`, which was attributed to DNS; when DNS was restored the same entries still read
# `unknown` for the second reason entirely, and no output distinguished them.
#
# THE FIX IS DELIBERATELY NARROW, and cases 2-4 are what keep it honest. A gate that blocks the
# structural case everywhere would be a hard stop on ordinary exploratory work, and a gate that
# blocks on an outage would have halted this whole repo on 2026-08-14. Only a FROZEN MANIFEST member
# blocks, and only on the structural cause. This repo has documented instances of an assertion that
# could not tell the bug from the fix (#348, #342, #351, #362B, #369); the over-block controls exist
# so this is not another.
#
# Hermetic: `gh` is stubbed on PATH, fixtures are throwaway git repos. No network, no auth.

set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"
SP="$ROOT/utils/swarm-preflight.sh"
PY="$ROOT/utils/py/swarm_preflight.py"

WORK="$(mktemp -d "${TMPDIR:-/tmp}/gh557-unknown-manifest.XXXXXX")"
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/fixture-guard.sh"   # GH-10: shared fixture containment
fixture_guard_init "$WORK"   # GH-10: pin the sandbox root
trap 'rm -rf "$WORK"' EXIT

PASS=0; FAIL=0
pass() { echo "  PASS: $*"; PASS=$((PASS+1)); }
fail() { echo "  FAIL: $*" >&2; FAIL=$((FAIL+1)); }

echo "== test: gh557-unknown-blocks-manifest =="
echo "  workdir: $WORK"

[ -f "$PY" ] || { fail "missing $PY"; echo "  gh557-unknown-blocks-manifest: $PASS pass, $FAIL fail"; exit 1; }

# ── gh stub — serves $GH_STUB_DIR/<n>.md as the issue body ────────────────────────────────────────
mkdir -p "$WORK/bin" "$WORK/issues"
cat >"$WORK/bin/gh" <<'STUB'
#!/usr/bin/env bash
[ "${GH_STUB_BROKEN:-0}" = "1" ] && { echo "gh: could not authenticate" >&2; exit 1; }
n=""
for a in "$@"; do case "$a" in ''|*[!0-9]*) ;; *) n="$a"; break ;; esac; done
[ -n "$n" ] && [ -f "$GH_STUB_DIR/$n.md" ] || { echo "gh: no such issue" >&2; exit 1; }
cat "$GH_STUB_DIR/$n.md"
STUB
chmod +x "$WORK/bin/gh"
export GH_STUB_DIR="$WORK/issues"
export SP_PY_DIR="$ROOT/utils/py"
# Case 6 reads THIS repo's real goalposts. Derived, not passed in, so `bash test/<file>` and
# validate.sh behave identically.
export GH557_REPO_ROOT="$ROOT"
# The fixture goalpost's filename. See make_repo for why this is a variable.
REL_BASENAME="fixture-release.sh"

# An issue that states NO acceptance section — the structural case.
cat >"$WORK/issues/700.md" <<'EOF'
## Summary
A phase boundary records no memory telemetry.

## Notes
No acceptance criteria were ever authored onto this issue.
EOF
cp "$WORK/issues/700.md" "$WORK/issues/900.md"

# An issue that DOES state criteria, matching the doc verbatim — the no-false-block control.
cat >"$WORK/issues/800.md" <<'EOF'
## Summary
A phase boundary records no memory telemetry.

## Acceptance

- [ ] A phase boundary records peak RSS and swap for the run.
EOF

# make_repo <name> <issue> <manifest-issue-or-'none'> <doc-acceptance:yes|no>
#   Builds a throwaway repo carrying its own test/<name>-release.sh goalpost, so frozen-manifest
#   membership is read from the FIXTURE and never from this repo's real manifests.
make_repo() {
  local name="$1" issue="$2" manifest="$3" doc_acc="$4"
  local repo="$WORK/$name"
  mkdir -p "$repo/PROJECT/2-WORKING" "$repo/test" "$repo/src"
  : >"$repo/src/target.txt"

  if [ "$manifest" != "none" ]; then
    # Built from parts on purpose: written as one literal, `test/`+`fixture-release.sh` reads to
    # test/path-integrity.sh as a reference to a repo path that does not exist. It is a file this
    # fixture CREATES inside a throwaway repo, not a path in this one.
    cat >"$repo/test/${REL_BASENAME}" <<RELEASE
#!/usr/bin/env bash
# Fixture goalpost. Same documented row format as the real ones:
#   <issue>|<gate test file, or '-'>|<note>
MANIFEST=(
  "$manifest|test/gh$manifest-something.sh|the fixture's frozen manifest entry"
)
RELEASE
  fi

  {
    printf -- '---\n'
    printf 'gh_issue: %s\n' "$issue"
    printf 'source: https://github.com/fixture/repo/issues/%s\n' "$issue"
    printf 'title: "GH-%s — fixture"\n' "$issue"
    printf -- '---\n\n# GH-%s\n\n' "$issue"
    if [ "$doc_acc" = "yes" ]; then
      printf '## Acceptance\n\n- [ ] A phase boundary records peak RSS and swap for the run.\n\n'
    fi
    printf '## Swarm Preflight Contract\n\n```json\n'
    printf '{\n  "target": { "repo": ".", "ref": "main" },\n  "gate": "true",\n'
    printf '  "fix_probes": [ { "type": "path_absent", "path": "NEW.txt" } ],\n'
    printf '  "artifacts": [ "src/target.txt" ],\n'
    printf '  "remediation": { "source": "issue#%s", "criteria": "fixture lane" }\n}\n' "$issue"
    printf '```\n'
  } >"$repo/PROJECT/2-WORKING/GH-$issue-fixture.md"

  git -C "$repo" init -q -b main 2>/dev/null || { git -C "$repo" init -q; git -C "$repo" symbolic-ref HEAD refs/heads/main; }
  git -C "$repo" -c user.email=t@t -c user.name=t add -A >/dev/null
  git -C "$repo" -c user.email=t@t -c user.name=t commit -qm init >/dev/null
  # A LOCAL bare origin, deliberately: preflight sets candidate_state=blocked whenever `git fetch`
  # fails (swarm_preflight.py:1250), so a github.com-shaped remote would make every case here exit 6
  # for a network reason and assert nothing about acceptance. A local origin also keeps the run
  # hermetic. repo_slug_for() returns None for a path remote, and check_source_url treats an
  # unknown tracking slug as "cannot contradict" — so `source:` still reads ok.
  git init -q --bare "$repo.origin"
  git -C "$repo" remote add origin "$repo.origin"
  git -C "$repo" push -q origin main
  git -C "$repo" branch -q --set-upstream-to=origin/main main
  printf '%s' "$repo"
}

run() {  # run <repo> <doc-relative-path>
  PATH="$WORK/bin:$PATH" SWARM_PREFLIGHT_ROOT="$1" \
  SWARM_PREFLIGHT_NOW="2026-08-15T00:00:00Z" SWARM_PREFLIGHT_TODAY="2026-08-15" \
  bash "$SP" --target-root "$1" --project-doc "$2" --dry-run 2>&1
}

# ══ Case 1 — THE PIN: a frozen manifest member whose issue states no criteria must BLOCK ══════════
R1="$(make_repo member-nosection 700 700 yes)"
out="$(run "$R1" "PROJECT/2-WORKING/GH-700-fixture.md")"; rc=$?
[ "$rc" -eq 5 ] \
  && pass "manifest member + issue with no '## Acceptance' is NOT-READY (exit 5)" \
  || fail "manifest member expected exit 5, got $rc: $out"
grep -Fq 'FROZEN MANIFEST member' <<<"$out" \
  && pass "the refusal says the issue is a frozen manifest member" \
  || fail "refusal does not name frozen-manifest membership: $out"
grep -Fq 'fixture-release.sh' <<<"$out" \
  && pass "the refusal names WHICH release manifest claims the issue" \
  || fail "refusal does not name the release goalpost: $out"
grep -Fq "Author the '## Acceptance' section onto the GitHub issue" <<<"$out" \
  && pass "the refusal states the remedy, not just the fault" \
  || fail "refusal states no remedy: $out"
grep -Fq 'cause: no-issue-section' <<<"$out" \
  && pass "the packet line reports the CAUSE, not a bare 'unknown'" \
  || fail "acceptance line does not carry the cause: $out"

# ══ Case 2 — OVER-BLOCK CONTROL: the same issue, NOT on any manifest, still reaches ready ═════════
# Without this, a gate that simply blocks every acceptance-less issue would pass Case 1 while
# halting ordinary exploratory work — the failure mode that gets a check switched off.
R2="$(make_repo nonmember-nosection 900 none yes)"
out2="$(run "$R2" "PROJECT/2-WORKING/GH-900-fixture.md")"; rc2=$?
[ "$rc2" -eq 0 ] \
  && pass "OVER-BLOCK CONTROL: non-member with no issue section still reaches ready (exit 0)" \
  || fail "non-member expected exit 0, got $rc2: $out2"
grep -Fq 'is not a frozen manifest member' <<<"$out2" \
  && pass "the non-blocking case SAYS why it did not block" \
  || fail "non-member run does not state its membership finding: $out2"

# ══ Case 3 — OUTAGE CONTROL: a manifest member with an unreachable gh must NOT block ══════════════
# On 2026-08-14 api.github.com stopped resolving. If an outage blocked manifest lanes, every lane in
# this repo would have halted. `fetch-failed` stays advisory on every path, by design.
out3="$(GH_STUB_BROKEN=1 run "$R1" "PROJECT/2-WORKING/GH-700-fixture.md")"; rc3=$?
[ "$rc3" -eq 0 ] \
  && pass "OUTAGE CONTROL: manifest member + unreachable gh stays ready (exit 0)" \
  || fail "unreachable gh on a manifest member expected exit 0, got $rc3: $out3"
grep -Fq 'cause: fetch-failed' <<<"$out3" \
  && pass "the outage is reported as fetch-failed, distinct from no-issue-section" \
  || fail "outage not distinguished from the structural cause: $out3"

# ══ Case 4 — NO-FALSE-BLOCK: a manifest member whose issue DOES state matching criteria ═══════════
R4="$(make_repo member-withsection 800 800 yes)"
out4="$(run "$R4" "PROJECT/2-WORKING/GH-800-fixture.md")"; rc4=$?
[ "$rc4" -eq 0 ] \
  && pass "manifest member with verbatim-matching criteria reaches ready (exit 0)" \
  || fail "matching manifest member expected exit 0, got $rc4: $out4"
grep -Fq 'acceptance  : match' <<<"$out4" \
  && pass "the matching case still reports match, uncomplicated by this change" \
  || fail "matching case no longer reports match: $out4"

# ══ Case 5 — the cause field itself, at the unit ══════════════════════════════════════════════════
cause_of() {  # cause_of <doc> <issue> [broken]
  GH_STUB_BROKEN="${3:-0}" PATH="$WORK/bin:$PATH" python3 - "$1" "$2" <<'PYEOF'
import sys, os
sys.path.insert(0, os.environ["SP_PY_DIR"])
from swarm_preflight import check_acceptance_fidelity
r = check_acceptance_fidelity(sys.argv[1], sys.argv[2], ".")
print(f"{r['status']}|{r.get('cause')}")
PYEOF
}
[ "$(cause_of "$R1/PROJECT/2-WORKING/GH-700-fixture.md" 700)" = "unknown|no-issue-section" ] \
  && pass "structural cause is 'no-issue-section'" \
  || fail "structural cause wrong: $(cause_of "$R1/PROJECT/2-WORKING/GH-700-fixture.md" 700)"
[ "$(cause_of "$R1/PROJECT/2-WORKING/GH-700-fixture.md" 700 1)" = "unknown|fetch-failed" ] \
  && pass "transient cause is 'fetch-failed'" \
  || fail "transient cause wrong: $(cause_of "$R1/PROJECT/2-WORKING/GH-700-fixture.md" 700 1)"
[ "$(cause_of "$R4/PROJECT/2-WORKING/GH-800-fixture.md" 800)" = "match|None" ] \
  && pass "a match carries no cause — the field qualifies 'unknown' only" \
  || fail "match should carry no cause: $(cause_of "$R4/PROJECT/2-WORKING/GH-800-fixture.md" 800)"

# ══ Case 6 — the manifest reader must not admit issues merely NAMED in RELEASES.md prose ══════════
# RELEASES.md's Manifest: lines cite retired entries (#509), moved ones (#358 Phase 2) and #551's
# nine root-cause siblings. A regex over that prose would read every one as a member and block
# unrelated lanes. Membership comes from the goalposts' MANIFEST arrays instead.
python3 - <<'PYEOF' && pass "membership comes from goalpost MANIFEST arrays, not RELEASES.md prose" \
  || fail "manifest reader admitted a non-member cited only in RELEASES.md prose"
import sys, os
sys.path.insert(0, os.environ["SP_PY_DIR"])
from swarm_preflight import frozen_manifest_members
root = os.environ["GH557_REPO_ROOT"]
members, note = frozen_manifest_members(root)
# #509 was RETIRED from Meter and #272/#310/#329/#365/#504/#548 are cited only as #551's siblings.
# UPDATED 2026-08-15: #378/#379/#382/#491/#551 were ALSO retired from Meter's manifest when the
# release was re-scoped to the public launch, so they join the list that must NOT be admitted from
# prose. They are cited throughout RELEASES.md's Meter block as transfer history, which is exactly
# the prose a regex would misread as membership.
bad = [n for n in (509, 272, 310, 329, 365, 504, 548, 378, 379, 382, 491, 551) if n in members]
# Sanity in the other direction: the real Meter entries MUST be present, or this asserts nothing.
# Meter's frozen manifest is #555 and #563 as of the 2026-08-15 re-scope.
#
# COVERAGE NOTE, recorded rather than left implicit: the five entries above now belong to Sundown,
# and Sundown has no goalpost of its own yet. Membership is read from the goalposts' MANIFEST
# arrays, so until that release gets its own release script those five sit in NO manifest array and
# GH-557's block does not cover them. That is a consequence of the re-scope, not a regression in
# this reader, and it is why Sundown's exit criterion is marked NOT WRITTEN in RELEASES.md.
missing = [n for n in (555, 563) if n not in members]
if bad or missing or "read from" not in note:
    print(f"  admitted non-members: {bad}; missing real members: {missing}; note={note}", file=sys.stderr)
    sys.exit(1)
sys.exit(0)
PYEOF

# ══ Case 7 — the packet's provenance line must not tell a reader to "read the issue" ══════════════
# The generic unverified wording is actively misleading in the structural case: there is nothing in
# the issue to read, which IS the problem.
prov() {
  PATH="$WORK/bin:$PATH" python3 - <<'PYEOF'
import sys, os
sys.path.insert(0, os.environ["SP_PY_DIR"])
import swarm_preflight as sp
src = open(os.path.join(os.environ["SP_PY_DIR"], "swarm_preflight.py"), encoding="utf-8").read()
print("OK" if "NOT verifiable as things stand" in src else "MISSING")
PYEOF
}
[ "$(prov)" = "OK" ] \
  && pass "the structural case has its own packet provenance wording" \
  || fail "structural provenance wording absent"

echo "  gh557-unknown-blocks-manifest: $PASS pass, $FAIL fail"
[ "$FAIL" -eq 0 ]
