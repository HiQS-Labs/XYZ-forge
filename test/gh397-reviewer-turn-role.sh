#!/usr/bin/env bash
# test/gh397-reviewer-turn-role.sh — GH-397 regression.
# gate-evidence: {"form":"pre-fix-replay","observed":true,"result":"reproducer: bash test/gh397-reviewer-turn-role.sh; pre-fix revision: relay-turn-lib.sh before d4999cd, where rtl_is_reviewer_turn read only the agent-maintained NEXT: prose; pre-fix result: case 3 FAILED — a builder that never flipped NEXT: left the reviewer running with the builder's write scope; post-fix result: 11/0, role derived from the marathon-drive directive with the NEXT: line kept only as the fallback"}
#
# `NEXT:` is the relay's state variable, and two drivers wrote two incompatible VALUE DOMAINS into
# it. relay-drive writes a ROLE (Producer|Reviewer); marathon-drive writes an AGENT ID
# (claude|codex|agy). rtl_is_reviewer_turn — the shared reader, used by BOTH lanes — tested for the
# literal word "Reviewer", so in a marathon it always returned false.
#
# The consequence was not cosmetic. rtl_init uses that answer to SCOPE THE ALLOWLIST: on a reviewer
# turn it drops ALLOW_PATHS so the reviewer can only append to the relay file. Returning false meant
# every marathon reviewer turn kept write authority over the artifact it was reviewing AND received
# the builder's "Edit ONLY <relay> and: <artifact>" prompt — the exact boundary an over-eager agy
# reviewer crossed on 2026-06-20 when it edited validate.sh.
#
# The fix does NOT ask the acting model to rewrite NEXT: itself. test/agy-turn.sh (S2) already locks
# in that agents skip that flip and nothing catches it; a containment boundary hung on that honor
# system fails OPEN. Instead the role is DERIVED from two things no agent authors: the machine-
# readable role directive marathon-drive renders into the relay file, and RELAY_AGENT, which
# relay-drive exports from the tick token. Case 3 below is the whole point of the design.
source "$(dirname "$0")/_setup.sh" gh397-reviewer-turn-role
LIB="$(cd "$(dirname "$0")/.." && pwd)/relay-automation/relay-turn-lib.sh"
# shellcheck source=relay-automation/relay-turn-lib.sh
source "$LIB"

mk_marathon_relay() {  # <path> <next-line>
  printf '# Marathon Phase p1\nSTATUS: Open\nNEXT: %s\n\n<!-- marathon-drive: task=MARATHON-p1 builder=codex reviewer=agy round-cap=6 -->\n\nbody\n' \
    "$2" > "$1"
}

M="$WORK/marathon-relay.md"

# --- Case 1: the reported bug. Marathon relay, reviewer acting. -------------------------------
mk_marathon_relay "$M" "agy (Reviewer)"
rtl_is_reviewer_turn "$M" agy \
  && pass "marathon reviewer turn is recognized as a REVIEWER turn" \
  || fail "marathon reviewer turn still reads as a builder turn — GH-397 is back"

# --- Case 2: the builder must NOT be scoped as a reviewer (it legitimately builds) ------------
mk_marathon_relay "$M" "codex (Builder)"
rtl_is_reviewer_turn "$M" codex \
  && fail "marathon BUILDER turn was scoped as a reviewer — its artifact edits would be reverted" \
  || pass "marathon builder turn is not a reviewer turn"

# --- Case 3: THE POINT. The builder forgot to flip NEXT; the reviewer is still scoped. --------
# NEXT: still names the BUILDER — the exact drift test/agy-turn.sh S2 proves is uncaught. Under a
# prompt-instruction fix this returns false and the reviewer silently regains artifact write
# authority. Deriving the role from the directive + tick-token agent makes the stale pointer
# irrelevant: the boundary no longer depends on anything a model remembered to do.
mk_marathon_relay "$M" "codex (Builder)"
rtl_is_reviewer_turn "$M" agy \
  && pass "reviewer stays scoped even when the builder never flipped NEXT (fails CLOSED)" \
  || fail "a forgotten NEXT: flip silently unscoped the reviewer — the boundary is back on the honor system"

# --- Case 4/5: plain /relay threads carry no directive and must behave exactly as before ------
P="$WORK/plain-relay.md"
printf 'STATUS: Open\nNEXT: Reviewer\n\nbody\n' > "$P"
rtl_is_reviewer_turn "$P" agy \
  && pass "plain relay thread with NEXT: Reviewer is still a reviewer turn" \
  || fail "regressed the plain /relay Producer|Reviewer path"

printf 'STATUS: Open\nNEXT: Producer\n\nbody\n' > "$P"
rtl_is_reviewer_turn "$P" agy \
  && fail "plain relay thread with NEXT: Producer read as a reviewer turn" \
  || pass "plain relay thread with NEXT: Producer is not a reviewer turn"

# --- Case 6: no agent known (a hand-run turn) falls back to the NEXT: header ------------------
mk_marathon_relay "$M" "agy (Reviewer)"
rtl_is_reviewer_turn "$M" "" \
  && pass "with no acting agent, the NEXT: header still decides (hand-run turns keep working)" \
  || fail "an agentless call stopped honoring the NEXT: header"

# --- Case 7: a self-review lane (builder == reviewer) carries no role signal — fall through ---
printf '# Marathon Phase p1\nSTATUS: Open\nNEXT: agy (Reviewer)\n\n<!-- marathon-drive: task=MARATHON-p1 builder=agy reviewer=agy round-cap=6 -->\n\nbody\n' > "$M"
rtl_is_reviewer_turn "$M" agy \
  && pass "builder==reviewer lane falls back to the NEXT: header rather than guessing" \
  || fail "builder==reviewer lane resolved a role it cannot know"

# --- Case 8: the user-visible symptom — the reviewer's PROMPT and allowlist -------------------
# Case 1 proves the predicate. This proves the two things that predicate actually controls, which is
# what the issue reported: contradictory scope statements in one context window.
mkdir -p "$A/phases/p1"
MP="$A/phases/p1/RELAY.md"
mk_marathon_relay "$MP" "codex (Builder)"    # stale pointer again — worst case, on purpose

prompt="$(rtl_turn_prompt agy "$MP" MARATHON-p1 "src/thing.py" codex)"
printf '%s' "$prompt" | grep -Fq "You are the REVIEWER this turn" \
  && pass "reviewer prompt carries the REVIEWER scope note" \
  || fail "reviewer prompt has no REVIEWER note — the safety text is still never delivered"
printf '%s' "$prompt" | grep -Fq "src/thing.py" \
  && fail "reviewer prompt still lists the artifact as editable — the contradiction GH-397 reported" \
  || pass "reviewer prompt drops the artifact from the editable set"

RELAY_AGENT=agy rtl_init "$A" "$MP" "src/thing.py"
[ "${RTL_WAS_REVIEWER_TURN:-0}" = "1" ] \
  && pass "rtl_init records the reviewer turn (allowlist scoped to the relay file only)" \
  || fail "rtl_init did not scope the reviewer turn — artifact edits would not be reverted"
[ "${#RTL_ALLOW[@]}" -eq 1 ] \
  && pass "reviewer allowlist holds the relay file and nothing else" \
  || fail "reviewer allowlist still carries ${#RTL_ALLOW[@]} entries: ${RTL_ALLOW[*]}"

exit 0
