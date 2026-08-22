#!/usr/bin/env bash
# GH-284 Phase 4 — release-driven marathon selection: milestone seed + landed-on-trunk rollup.
#
# The substance under test is the LANDED matcher. "Did this issue land?" is the kind of question
# whose wrong answer looks exactly like its right one, so every matcher case below is driven with a
# real commit subject taken from this repo's own history, including the two that broke the naive
# versions:
#
#   fix(RELEASES): correct the GH-308 release codename spelling   <- mentions 308, implements nothing
#   fix(GH-322): port GH-284 Phase 2 into the lane that actually run  <- scope is 322, mentions 284
#
# Hermetic: a throwaway git repo (crafted subjects), a stubbed gh, and a crafted RELEASES.md. The
# script is COPIED into the throwaway repo because it derives its own ROOT from BASH_SOURCE.
source "$(dirname "$0")/_setup.sh" gh284-p4-release-lanes

SRC="$(cd "$(dirname "$0")/.." && pwd)/utils/release-lanes.sh"
[ -f "$SRC" ] || fail "utils/release-lanes.sh not found"

T="$WORK/repo"
mkdir -p "$T/utils"
cp "$SRC" "$T/utils/release-lanes.sh"
LANES="$T/utils/release-lanes.sh"

git -C "$T" init -q 2>/dev/null || { git init -q "$T"; }
git -C "$T" config user.email p4@example.invalid
git -C "$T" config user.name p4-test

# ── crafted trunk history ───────────────────────────────────────────────────────────────────────
# Each subject is a case. Order matters only in that all land on one branch.
commit() { # <subject> [body]
  printf '%s\n' "$1" > "$T/marker.txt"
  git -C "$T" add marker.txt
  if [ -n "${2:-}" ]; then
    git -C "$T" commit -q -m "$1" -m "$2"
  else
    git -C "$T" commit -q -m "$1"
  fi
}
commit "chore: baseline"
commit "fix(GH-101): conventional scope claims 101"
commit "GH-102: leading bare scope claims 102"
commit "feat(GH-103 P3): scope with a phase suffix claims 103"
commit "fix(RELEASES): correct the GH-104 release codename spelling"   # mentions 104 only
commit "fix(GH-101): port GH-105 Phase 2 into the lane that runs"      # scope 101, mentions 105
commit "Marathon: gate-and-fleet-integrity (#106)"  "Fixes described in GH-106 body only."
commit "docs: unrelated change (#107)"                                  # bare #107 = a PR number
# 108 is referenced nowhere at all.
# GH-332: claimed by a commit but the issue is still OPEN. Verbatim the shape of the real case —
# #308's only claiming commit was `GH-308: re-scope Phase 0/1 after #278 was fixed dual-lane`, i.e.
# planning on a multi-phase epic, which the first cut counted as a full landing (`Quicksilver: 1/1`).
commit "GH-109: re-scope Phase 0/1 after #278 was fixed dual-lane"

git -C "$T" branch -M main
TRUNK=main

# ── stubbed gh ──────────────────────────────────────────────────────────────────────────────────
STUB="$WORK/bin"; mkdir -p "$STUB"
OPEN_JSON="$WORK/open.jsonl"
ALL_JSON="$WORK/all.json"
GH_AUTH_RC="$WORK/gh-auth-rc"; printf '0\n' > "$GH_AUTH_RC"
export OPEN_JSON ALL_JSON GH_AUTH_RC
cat > "$STUB/gh" <<'GHSTUB'
#!/usr/bin/env bash
case "$1" in
  auth) exit "$(cat "$GH_AUTH_RC")" ;;
  issue)
    # Unknown milestones are not an error to gh — it returns an empty list, same as an empty one.
    case "$*" in
      *"--milestone Empty"*) [[ "$*" == *"--state all"* ]] && printf '[]\n' || printf ''; exit 0 ;;
    esac
    if [[ "$*" == *"--state all"* ]]; then cat "$ALL_JSON"; else cat "$OPEN_JSON"; fi
    exit 0 ;;
esac
exit 0
GHSTUB
chmod +x "$STUB/gh"

cat > "$ALL_JSON" <<'EOF'
[{"number":101,"title":"claimed by conventional scope","state":"CLOSED","url":"u/101"},
 {"number":102,"title":"claimed by leading scope","state":"CLOSED","url":"u/102"},
 {"number":103,"title":"claimed by scope with phase suffix","state":"CLOSED","url":"u/103"},
 {"number":104,"title":"only mentioned in another commit subject","state":"OPEN","url":"u/104"},
 {"number":105,"title":"mentioned inside another issue's scoped commit","state":"OPEN","url":"u/105"},
 {"number":106,"title":"fixed inside a marathon commit, claimed by nobody","state":"OPEN","url":"u/106"},
 {"number":107,"title":"shares a number with a squash-merge PR","state":"OPEN","url":"u/107"},
 {"number":108,"title":"no trunk reference at all","state":"OPEN","url":"u/108"},
 {"number":109,"title":"claimed by a commit but still OPEN (an epic mid-flight)","state":"OPEN","url":"u/109"}]
EOF
cat > "$OPEN_JSON" <<'EOF'
{"number":104,"title":"only mentioned","createdAt":"2026-07-01T00:00:00Z","updatedAt":"2026-07-02T00:00:00Z","url":"u/104","labels":[]}
{"number":108,"title":"no reference","createdAt":"2026-07-01T00:00:00Z","updatedAt":"2026-07-02T00:00:00Z","url":"u/108","labels":[]}
EOF

REL="$WORK/RELEASES.md"
cat > "$REL" <<'EOF'
Release: 0.1.0
Status: Draft
Codename: n/a
Description: no join key on purpose
Milestone:

Release: 1.0.0
Status: Draft
Target Date: 2026-08-01
Codename: Quicksilver
Description: the live one
Milestone: Quicksilver

Release: 0.9.0
Status: Shipped
Codename: Older
Description: history — must be excluded from auto-resolve
Milestone: Older
EOF

lanes() { PATH="$STUB:$PATH" RELEASES_FILE="$REL" bash "$LANES" "$@"; }

# ── milestone resolution ────────────────────────────────────────────────────────────────────────
out="$(lanes rollup --milestone Quicksilver --trunk "$TRUNK" 2>&1)"; rc=$?
[ "$rc" -eq 0 ] && pass "rollup runs with an explicit --milestone" \
  || fail "explicit --milestone failed (rc=$rc): $out"

out="$(lanes rollup --release Quicksilver --trunk "$TRUNK" 2>&1)"; rc=$?
grep -q 'milestone: Quicksilver' <<<"$(printf '%s' "$out")" && [ "$rc" -eq 0 ] \
  && pass "--release resolves via Codename:" || fail "--release by codename failed (rc=$rc): $out"

out="$(lanes rollup --release 1.0.0 --trunk "$TRUNK" 2>&1)"; rc=$?
grep -q 'milestone: Quicksilver' <<<"$(printf '%s' "$out")" && [ "$rc" -eq 0 ] \
  && pass "--release resolves via Release:" || fail "--release by version failed (rc=$rc): $out"

# Auto-resolve must pick the ONE in-progress block with a join key. The Shipped block also has a
# Milestone:, so if history were not excluded this would be ambiguous and fail.
out="$(lanes rollup --trunk "$TRUNK" 2>&1)"; rc=$?
grep -q 'milestone: Quicksilver' <<<"$(printf '%s' "$out")" && [ "$rc" -eq 0 ] \
  && pass "auto-resolve picks the single in-progress release, excluding Shipped history" \
  || fail "auto-resolve failed (rc=$rc): $out"

# A release with a blank Milestone: must fail loudly. An empty seed list would be indistinguishable
# from a milestone that simply has no open issues — the whole point of Phase 3's join key.
out="$(lanes seed --release 0.1.0 2>&1)"; rc=$?
grep -q 'cannot resolve to an issue set' <<<"$([ "$rc" -eq 3 ] && printf '%s' "$out")" \
  && pass "a release with no Milestone: fails loudly rather than seeding nothing" \
  || fail "blank Milestone: should exit 3 with a named reason (rc=$rc): $out"

out="$(lanes seed --release NoSuchRelease 2>&1)"; rc=$?
[ "$rc" -eq 3 ] && pass "an unknown --release exits 3" || fail "unknown --release gave rc=$rc: $out"

# Two live blocks with join keys is ambiguous — it must say so, not silently pick one.
REL2="$WORK/RELEASES-ambiguous.md"
{ cat "$REL"; printf '\nRelease: 2.0.0\nStatus: Draft\nCodename: Second\nMilestone: Second\n'; } > "$REL2"
out="$(PATH="$STUB:$PATH" RELEASES_FILE="$REL2" bash "$LANES" rollup --trunk "$TRUNK" 2>&1)"; rc=$?
[ "$rc" -eq 3 ] && printf '%s' "$out" | grep -q 'Quicksilver' && printf '%s' "$out" | grep -q 'Second' \
  && pass "two in-progress releases with join keys is an error that names both" \
  || fail "ambiguous auto-resolve should exit 3 naming both (rc=$rc): $out"

# ── the landed matcher ──────────────────────────────────────────────────────────────────────────
ROLL="$(lanes rollup --milestone Quicksilver --trunk "$TRUNK" 2>&1)"
# Capture the whole label, not the first whitespace-delimited word: GH-332 added the two-word
# "IN FLIGHT", which an awk '{print $1}' would silently truncate to "IN" — and the grep that fed it
# would not have matched the line at all.
state_of() { printf '%s\n' "$ROLL" | sed -n "s/^  \([A-Z][A-Z ]*[A-Z]\) *#$1 .*/\1/p" | head -1; }

[ "$(state_of 101)" = "LANDED" ] \
  && pass "a conventional scope fix(GH-101) counts as landed" \
  || fail "101 should be LANDED, got '$(state_of 101)'"
[ "$(state_of 102)" = "LANDED" ] \
  && pass "a leading bare GH-102 scope counts as landed" \
  || fail "102 should be LANDED, got '$(state_of 102)'"
[ "$(state_of 103)" = "LANDED" ] \
  && pass "a scope with a phase suffix feat(GH-103 P3) counts as landed" \
  || fail "103 should be LANDED, got '$(state_of 103)'"

# The two real false positives that broke the naive matchers.
[ "$(state_of 104)" = "MENTIONED" ] \
  && pass "a subject that only MENTIONS GH-104 is not landed (fix(RELEASES): … GH-104 …)" \
  || fail "104 should be MENTIONED, got '$(state_of 104)' — a subject-mention is being read as a claim"
[ "$(state_of 105)" = "MENTIONED" ] \
  && pass "GH-105 inside another issue's scoped commit is not landed (fix(GH-101): … GH-105 …)" \
  || fail "105 should be MENTIONED, got '$(state_of 105)' — another issue's scope is landing this one"

[ "$(state_of 106)" = "MENTIONED" ] \
  && pass "a fix inside a marathon commit that claims no issue reads as MENTIONED, not landed" \
  || fail "106 should be MENTIONED, got '$(state_of 106)'"

# The PR-number namespace collision: `(#107)` is a squash-merge PR, not evidence about issue 107.
[ "$(state_of 107)" = "ABSENT" ] \
  && pass "a bare #107 in a subject is a PR number and never lands issue 107" \
  || fail "107 should be ABSENT, got '$(state_of 107)' — bare #N is being accepted as evidence"

[ "$(state_of 108)" = "ABSENT" ] \
  && pass "an issue with no trunk reference is ABSENT" \
  || fail "108 should be ABSENT, got '$(state_of 108)'"

# GH-332: the case that made Quicksilver report 1/1 when it had barely started. A commit claiming an
# issue answers "has anyone worked on this?", not "is this finished?" — the issue's own CLOSED state
# is the human signal, and the script was already fetching it and discarding it.
[ "$(state_of 109)" = "IN FLIGHT" ] \
  && pass "a commit claiming an OPEN issue is IN FLIGHT, not landed (#308's real shape)" \
  || fail "109 should be IN FLIGHT, got '$(state_of 109)' — an open epic is being counted as landed"
# The contrast that proves the gate is issue STATE and not something else: 101 is claimed by the same
# kind of commit and IS counted, because it is closed.
[ "$(state_of 101)" = "LANDED" ] && [ "$(state_of 109)" != "LANDED" ] \
  && pass "closed+claimed lands, open+claimed does not — the discriminator is the issue state" \
  || fail "state gating is not working: 101='$(state_of 101)' 109='$(state_of 109)'"

# Prefix safety: GH-10 must not be satisfied by GH-101/102/103.
cat > "$WORK/all-prefix.json" <<'EOF'
[{"number":10,"title":"must not match GH-101 by prefix","state":"OPEN","url":"u/10"}]
EOF
out="$(ALL_JSON="$WORK/all-prefix.json" lanes rollup --milestone Quicksilver --trunk "$TRUNK" 2>&1)"
grep -qE '^ +ABSENT +#10 ' <<<"$(printf '%s' "$out")" \
  && pass "GH-10 is not matched by GH-101 (no prefix bleed)" \
  || fail "prefix bleed: issue 10 matched a GH-10x commit: $out"

# ── the headline and the mentioned bucket ───────────────────────────────────────────────────────
grep -q "Quicksilver: 3/9 landed on $TRUNK" <<<"$(printf '%s' "$ROLL")" \
  && pass "headline reports the correct landed/total against the named trunk" \
  || fail "expected '3/9 landed on $TRUNK': $ROLL"
# The in-flight count must be named, not folded into the denominator silently. #332 shipped as a
# confident "1/1 landed" precisely because nothing distinguished this bucket.
grep -q 'claimed by a commit but still OPEN' <<<"$(printf '%s' "$ROLL")" \
  && pass "the IN FLIGHT bucket is surfaced explicitly in the summary" \
  || fail "in-flight count was not surfaced: $ROLL"
grep -q 'mentioned on trunk but claimed by no commit' <<<"$(printf '%s' "$ROLL")" \
  && pass "the MENTIONED bucket is surfaced explicitly, not folded into a not-landed tally" \
  || fail "mentioned count was not surfaced: $ROLL"
grep -q 'trunk (derived)' <<<"$(printf '%s' "$ROLL")" \
  && pass "the rollup states which trunk it measured against" \
  || fail "rollup did not name its trunk: $ROLL"
grep -q '└─ .*fix(GH-101)' <<<"$(printf '%s' "$ROLL")" \
  && pass "each landed row cites the commit that claimed it" \
  || fail "no evidence line for a landed issue: $ROLL"

# --json must carry the same verdicts a machine can consume.
J="$(lanes rollup --milestone Quicksilver --trunk "$TRUNK" --json 2>/dev/null)"
got="$(J="$J" python3 -c 'import json,os
d=json.loads(os.environ["J"])
c=d["counts"]
print(c["landed"], c["claimed-but-open"], c["mentioned"], c["absent"], d["trunk"], d["total"])')"
[ "$got" = "3 1 3 2 $TRUNK 9" ] \
  && pass "--json carries the same counts, trunk and total as the text report" \
  || fail "--json disagreed with the text report: '$got'"
# The four buckets must account for every issue — a state that silently vanishes from the tally is
# how an over-count hides.
[ "$(J="$J" python3 -c 'import json,os
d=json.loads(os.environ["J"])
print(sum(d["counts"].values()) == d["total"])')" = "True" ] \
  && pass "the buckets sum to the total (no issue is dropped from the tally)" \
  || fail "counts do not sum to total: $J"

# ── seed ────────────────────────────────────────────────────────────────────────────────────────
S="$(lanes seed --milestone Quicksilver 2>/dev/null)"
keys="$(printf '%s\n' "$S" | head -1 | python3 -c 'import json,sys; print(",".join(sorted(json.loads(sys.stdin.read()))))')"
[ "$keys" = "createdAt,labels,number,title,updatedAt,url" ] \
  && pass "seed emits the same keys as skills/10days/scan-issues.sh" \
  || fail "seed shape drifted from the /10days seed contract: $keys"
[ "$(printf '%s\n' "$S" | wc -l | tr -d ' ')" = "2" ] \
  && pass "seed emits one JSON object per open issue" \
  || fail "seed line count wrong: $S"

# ── failure modes that must not read as success ─────────────────────────────────────────────────
out="$(lanes seed --milestone Empty 2>&1)"; rc=$?
[ "$rc" -eq 4 ] && pass "an empty milestone seeds exit 4, never 0" \
  || fail "empty seed returned rc=$rc (must be non-zero): $out"

out="$(lanes rollup --milestone Empty --trunk "$TRUNK" 2>&1)"; rc=$?
[ "$rc" -eq 4 ] && pass "an empty milestone rollup exits 4, never 0" \
  || fail "empty rollup returned rc=$rc: $out"
# It must bail BEFORE rendering: the first cut printed "Empty: 0/0 landed on main" and only then
# exited 4, which is a report that reads like a fact about a milestone that may not exist.
grep -q '0/0 landed' <<<"$(printf '%s' "$out")" \
  && fail "empty rollup printed a 0/0 report before failing: $out" \
  || pass "an empty rollup prints no report at all before exiting"

printf '1\n' > "$GH_AUTH_RC"
out="$(lanes seed --milestone Quicksilver 2>&1)"; rc=$?
grep -q 'not authenticated' <<<"$([ "$rc" -eq 3 ] && printf '%s' "$out")" \
  && pass "an unauthenticated gh exits 3 with a named reason" \
  || fail "unauthenticated gh gave rc=$rc: $out"
grep -q '^{' <<<"$(printf '%s' "$out")" \
  && fail "unauthenticated run emitted issue JSON anyway: $out" \
  || pass "an unauthenticated run emits no partial list that could look complete"
printf '0\n' > "$GH_AUTH_RC"

# `gh` must be genuinely ABSENT here, which a trimmed PATH does not guarantee: ubuntu CI ships gh at
# /usr/bin/gh, so PATH=/usr/bin:/bin still found it and this case silently exercised the
# unauthenticated path instead (right exit code, wrong message — green on macOS, red on CI).
# Build a PATH containing only the externals the script actually needs.
NOGH="$WORK/nogh"; mkdir -p "$NOGH"
for tool in bash git python3 tr sed; do
  p="$(command -v "$tool" 2>/dev/null)" && [ -n "$p" ] && ln -sf "$p" "$NOGH/$tool"
done
if PATH="$NOGH" command -v gh >/dev/null 2>&1; then
  fail "the gh-absent fixture still resolves a gh on its PATH — the next assertion would be vacuous"
else
  pass "the gh-absent fixture really resolves no gh (the case is not vacuous)"
fi
out="$(PATH="$NOGH" RELEASES_FILE="$REL" bash "$LANES" seed --milestone Quicksilver 2>&1)"; rc=$?
grep -q 'gh CLI not found' <<<"$([ "$rc" -eq 3 ] && printf '%s' "$out")" \
  && pass "a missing gh exits 3 with a named reason" \
  || fail "missing gh gave rc=$rc: $out"

# ── usage ───────────────────────────────────────────────────────────────────────────────────────
lanes bogus-verb >/dev/null 2>&1; rc=$?
[ "$rc" -eq 2 ] && pass "an unknown verb exits 2" || fail "unknown verb gave rc=$rc"
lanes seed --not-a-flag >/dev/null 2>&1; rc=$?
[ "$rc" -eq 2 ] && pass "an unknown flag exits 2" || fail "unknown flag gave rc=$rc"
lanes seed --milestone A --release B >/dev/null 2>&1; rc=$?
[ "$rc" -eq 2 ] && pass "--milestone and --release together exit 2" || fail "mutual exclusion gave rc=$rc"
lanes --help >/dev/null 2>&1; rc=$?
[ "$rc" -eq 0 ] && pass "--help exits 0" || fail "--help gave rc=$rc"

echo "  gh284-p4-release-lanes: $PASS pass, $FAIL fail"
[ "$FAIL" = 0 ]
