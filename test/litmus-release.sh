#!/usr/bin/env bash
# gate-evidence: {"form":"deliberate-mutation","observed":true,"result":"--mutate-evidence strips an accepted form and a registration from a fixture copy; the audit went from 6/6 satisfied to 2 structural failures, and the unmutated fixture is re-checked green in the same run"}
# Litmus (release 0.2.0) — the executable goalpost for a FROZEN manifest of decision gates.
#
# Why this file exists. Until now Litmus's definition of done was its issue list, and an issue list
# is a backlog: it grows while you work on it. #457, #460 and #461 were all filed ON 2026-08-08 while
# executing Litmus. A release whose scope is "the open issues in its milestone" cannot close, because
# working on it generates more of it. Both advisors in the 2026-08-08 codex+agy consult independently
# reached the same remedy: freeze a named manifest and make the exit criterion one committed command.
#
# WHAT THIS PROVES, and what it deliberately does not.
#
#   PROVES  (1) each manifest gate is REGISTERED in validate.sh's TESTS array, so the suite actually
#               runs it. This is the #461 defect: test/gh401-dry-run-no-mutation.sh shipped in #456,
#               sat in the tree unregistered, and was therefore never executed by CI. A gate absent
#               from TESTS is indistinguishable from a gate that passes.
#           (2) each carries a PARSEABLE `# gate-evidence:` declaration naming one of the accepted
#               forms with observed=true, or is explicitly marked advisory in the manifest.
#           (3) no manifest entry claims completion it cannot support — a CLOSED issue whose gate is
#               missing, unregistered, or undeclared is a false completion claim and fails HARD.
#
#   DOES NOT PROVE that the negative control was truly observed. utils/py/gate_inventory.py reads a
#           declaration authored by the same person who wrote the gate ("This tool never treats a
#           filename, a successful invocation, or a prose mention as negative-control evidence" — but
#           `observed: true` is still a string a human typed). That limit is inherent to metadata and
#           is stated here rather than papered over, because claiming otherwise would make this audit
#           the exact self-certifying shape Litmus exists to forbid (#419 principle 13). Closing the
#           gap needs recorded execution of each control, which is deliberately out of scope for the
#           release goalpost and is tracked separately.
#
# THREE MODES, because the audit has three different jobs:
#
#   (default)          Suite mode, registered in validate.sh. GREEN while Litmus is in progress.
#                      Fails ONLY on a false completion claim (3 above). Remaining work is reported
#                      as INFO, so an unfinished release does not paint the whole suite red — an
#                      always-red suite trains people to ignore it, which is #460's failure mode.
#
#   --release-gate     THE GOALPOST. Exits non-zero until every manifest entry is complete. This is
#                      the command RELEASES.md cites. It is red today, on purpose, and turning it
#                      green is what "Litmus is done" means.
#
#   --mutate-evidence  This audit's own negative control, per #419. Copies the tree, strips one
#                      declaration and one registration, and asserts the audit goes RED. If the audit
#                      stayed green under a corrupted manifest it would not be evidence of anything.
#
# THE FREEZE. Adding an entry below is a re-scope, not a bugfix. Per the consult, a newly discovered
# defect joins Litmus only if it (a) makes this command fail or falsifies a named invariant, (b) has
# a reproducer demonstrating that, and (c) the operator explicitly swaps out an existing entry or
# accepts a target-date slip. Otherwise it belongs to the next release. Discovery is not admission.
set -euo pipefail

source "$(dirname "$0")/_setup.sh" litmus-release
ROOT="$(cd "$(dirname "$0")/.." && pwd)"

MODE="suite"
case "${1:-}" in
  --release-gate)    MODE="release-gate" ;;
  --mutate-evidence) MODE="mutate" ;;
  "")                ;;
  *) echo "usage: $0 [--release-gate|--mutate-evidence]" >&2; exit 2 ;;
esac

# ── the frozen manifest ────────────────────────────────────────────────────────────────────────────
# issue | gate hint | optional INVARIANT (shell predicate run in the tree; must exit 0)
#
# The hint is a prefix for unbuilt lanes because the filename is not knowable before the build; #461's
# gate already exists under #401's name, which is why it carries an exact path instead.
#
# WHY THE INVARIANT COLUMN EXISTS — this audit shipped with the exact defect it was built to catch.
# Registration plus a declaration proves the gate RUNS and CLAIMS a control. It does not prove the
# issue's acceptance criteria are met. #461 is "GH-401 closed with criteria 4 and 5 unmet"; criterion 5
# is about the control (which registration+declaration does cover) but criterion 4 is about a TRACKED
# FILE, which no amount of gate metadata can see. The first run after #458 merged duly reported #461
# `complete` while `phases/p1/RELAY.md` was still tracked with 9 machine-specific absolute paths — a
# false completion claim, from the tool whose one hard failure mode is false completion claims.
# So: where an entry's acceptance includes a checkable state invariant, name it here.
MANIFEST=(
  "375|test/gh375-|"
  "390|test/gh390-gate-guard.sh|"
  "407|test/gh407-|"
  "417|test/gh417-|"
  # GH-401 criterion 4: a tracked copy is retained only if a named consumer is identified AND it holds
  # no machine-specific absolute paths. No consumer was ever identified, so the invariant is: untracked.
  "457|test/gh457-|"
  "461|test/gh401-dry-run-no-mutation.sh|! git ls-files --error-unmatch phases/p1/RELAY.md >/dev/null 2>&1"
)
ACCEPTED_FORMS="pre-fix-replay deliberate-mutation controlled-bad-fixture"

# ── audit one manifest entry against a tree ────────────────────────────────────────────────────────
# Echoes one line: "<issue> <state> <detail>" where state is complete|incomplete|BROKEN.
# BROKEN is reserved for a false completion claim, which is the only thing suite mode fails on.
audit_entry() {
  local tree="$1" issue="$2" hint="$3" gate="" inv="$4" invariant="${5:-}"
  if [ -f "$tree/$hint" ]; then
    gate="$hint"
  else
    # glob the prefix; a lane not yet built resolves to nothing
    local m; m="$(cd "$tree" && ls ${hint}*.sh 2>/dev/null | head -1 || true)"
    [ -n "$m" ] && gate="$m"
  fi

  if [ -z "$gate" ]; then
    printf '%s incomplete no-gate-yet\n' "$issue"; return 0
  fi

  # (1) registration — the inventory is generated FROM validate.sh's TESTS array, so presence in it
  # is proof the suite runs the gate. Absence is the #461 defect.
  if ! printf '%s' "$inv" | /usr/bin/grep -Fq "\"$gate\""; then
    printf '%s incomplete not-registered-in-validate.sh:%s\n' "$issue" "$gate"; return 0
  fi

  # (2) a parseable declaration naming an accepted form, with observed=true
  local form observed
  form="$(printf '%s' "$inv" | python3 -c "
import json,sys
d=json.load(sys.stdin); gates=d['gates'] if isinstance(d,dict) and 'gates' in d else d
for g in gates:
    if g.get('gate')=='$gate': print(g.get('negative_control',{}).get('form','none')); break
else: print('none')
" 2>/dev/null || echo none)"
  observed="$(printf '%s' "$inv" | python3 -c "
import json,sys
d=json.load(sys.stdin); gates=d['gates'] if isinstance(d,dict) and 'gates' in d else d
for g in gates:
    if g.get('gate')=='$gate': print('yes' if g.get('negative_control',{}).get('observed') else 'no'); break
else: print('no')
" 2>/dev/null || echo no)"

  case " $ACCEPTED_FORMS " in
    *" $form "*) ;;
    *) printf '%s incomplete unaccepted-or-absent-form(%s):%s\n' "$issue" "$form" "$gate"; return 0 ;;
  esac
  [ "$observed" = "yes" ] || { printf '%s incomplete not-observed:%s\n' "$issue" "$gate"; return 0; }

  # (3) the entry's own state invariant, where its acceptance defines one. Gate metadata cannot see
  # repository state; this is the difference between "the gate runs" and "the issue is fixed".
  if [ -n "$invariant" ]; then
    if ! ( cd "$tree" && eval "$invariant" ) >/dev/null 2>&1; then
      printf '%s incomplete invariant-unmet:%s\n' "$issue" "$gate"; return 0
    fi
  fi

  printf '%s complete %s(%s)\n' "$issue" "$gate" "$form"
}

# Issue state is advisory only. `gh` is absent in CI, and #400 established the posture that an
# unknown issue state never blocks — a gate that fails when the network is down is not measuring the
# repo. It is still reported, because a manifest entry whose issue is still OPEN is the honest signal
# that the release is not done.
issue_state() {
  local n="$1"
  command -v gh >/dev/null 2>&1 || { echo unknown; return 0; }
  gh issue view "$n" --json state -q .state 2>/dev/null || echo unknown
}

run_audit() {  # <tree> ; sets AUDIT_OUT, returns 0 always
  local tree="$1" inv
  inv="$(cd "$tree" && python3 utils/py/gate_inventory.py 2>/dev/null || echo '[]')"
  AUDIT_OUT=""
  local entry issue hint invariant rest line
  for entry in "${MANIFEST[@]}"; do
    issue="${entry%%|*}"; rest="${entry#*|}"
    hint="${rest%%|*}"; invariant="${rest#*|}"
    [ "$invariant" = "$rest" ] && invariant=""   # no third field
    line="$(audit_entry "$tree" "$issue" "$hint" "$inv" "$invariant")"
    AUDIT_OUT+="$line"$'\n'
  done
}

# ── mode: --mutate-evidence (this audit's own negative control) ─────────────────────────────────────
if [ "$MODE" = "mutate" ]; then
  FIX="$WORK/tree"
  mkdir -p "$FIX"
  # A fixture where ALL SIX entries are satisfied, so the mutation is the only variable. Built from
  # stubs rather than the real tree because 4 of 6 lanes are genuinely unbuilt today — mutating a
  # tree that is already red would prove nothing.
  mkdir -p "$FIX/test" "$FIX/utils/py"
  cp "$ROOT/utils/py/gate_inventory.py" "$FIX/utils/py/"
  {
    echo 'TESTS=('
    for stub in gh375-agy-auth-preflight gh390-gate-guard gh407-gate-never-ran \
                gh417-turn-root-resolution gh457-gate-cap gh401-dry-run-no-mutation; do
      echo "  \"$stub.sh\""
    done
    echo ')'
  } > "$FIX/validate.sh"
  for stub in gh375-agy-auth-preflight gh390-gate-guard gh407-gate-never-ran \
              gh417-turn-root-resolution gh457-gate-cap gh401-dry-run-no-mutation; do
    printf '#!/usr/bin/env bash\n# gate-evidence: {"form":"pre-fix-replay","observed":true,"result":"fixture"}\n' \
      > "$FIX/test/$stub.sh"
    chmod +x "$FIX/test/$stub.sh"
  done

  run_audit "$FIX"
  before_complete="$(printf '%s' "$AUDIT_OUT" | /usr/bin/grep -c ' complete ' || true)"
  [ "$before_complete" -eq 6 ] \
    && pass "control: an unmutated fixture satisfies all 6 manifest entries ($before_complete/6)" \
    || fail "control: the unmutated fixture should satisfy 6, got $before_complete — the mutation below would prove nothing"

  # Mutation A: strip a declaration (the #419 defect — a gate with no recorded control).
  printf '#!/usr/bin/env bash\n# no declaration here\n' > "$FIX/test/gh390-gate-guard.sh"
  # Mutation B: unregister a gate (the #461 defect — present in the tree, never run by the suite).
  /usr/bin/grep -v 'gh401-dry-run-no-mutation.sh' "$FIX/validate.sh" > "$FIX/validate.sh.new"
  mv "$FIX/validate.sh.new" "$FIX/validate.sh"

  run_audit "$FIX"
  after_complete="$(printf '%s' "$AUDIT_OUT" | /usr/bin/grep -c ' complete ' || true)"
  [ "$after_complete" -eq 4 ] \
    && pass "mutation flips exactly the two mutated entries (6 -> $after_complete complete)" \
    || fail "expected 4 complete after two mutations, got $after_complete"

  printf '%s' "$AUDIT_OUT" | /usr/bin/grep -q '^390 incomplete unaccepted-or-absent-form' \
    && pass "a stripped declaration is detected as an absent form, not silently accepted" \
    || fail "stripping gh390's declaration did not surface as an absent form"

  printf '%s' "$AUDIT_OUT" | /usr/bin/grep -q '^461 incomplete not-registered-in-validate.sh' \
    && pass "an unregistered gate is detected (the #461 defect), not treated as passing" \
    || fail "unregistering gh401 did not surface as not-registered"

  # Mutation C: the invariant column itself. This audit shipped reporting #461 complete while
  # phases/p1/RELAY.md was still tracked, so the column that fixes that must be proven to bite.
  FIX2="$WORK/tree2"
  mkdir -p "$FIX2/test" "$FIX2/utils/py"
  cp "$ROOT/utils/py/gate_inventory.py" "$FIX2/utils/py/"
  printf 'TESTS=(\n  "gh401-dry-run-no-mutation.sh"\n)\n' > "$FIX2/validate.sh"
  printf '#!/usr/bin/env bash\n# gate-evidence: {"form":"pre-fix-replay","observed":true,"result":"fixture"}\n' \
    > "$FIX2/test/gh401-dry-run-no-mutation.sh"
  inv2="$(cd "$FIX2" && python3 utils/py/gate_inventory.py 2>/dev/null || echo '[]')"

  satisfied="$(audit_entry "$FIX2" 461 "test/gh401-dry-run-no-mutation.sh" "$inv2" "true")"
  violated="$(audit_entry  "$FIX2" 461 "test/gh401-dry-run-no-mutation.sh" "$inv2" "false")"

  printf '%s' "$satisfied" | /usr/bin/grep -q ' complete ' \
    && pass "invariant control: a satisfied invariant leaves the entry complete" \
    || fail "a satisfied invariant should not block completion (got: $satisfied)"

  printf '%s' "$violated" | /usr/bin/grep -q 'invariant-unmet' \
    && pass "invariant control: a violated invariant blocks completion even with gate+declaration valid" \
    || fail "a violated invariant was NOT detected — this is the false completion claim this audit shipped with (got: $violated)"

  echo "litmus-release: negative control OBSERVED in both directions ($PASS pass, $FAIL fail)"
  exit 0
fi

# ── modes: suite (default) and --release-gate ───────────────────────────────────────────────────────
run_audit "$ROOT"
complete=0; incomplete=0; broken=0

while IFS= read -r line; do
  [ -n "$line" ] || continue
  issue="${line%% *}"; rest="${line#* }"; state="${rest%% *}"; detail="${rest#* }"
  st="$(issue_state "$issue")"

  if [ "$state" = "complete" ]; then
    complete=$((complete+1))
    echo "  OK   #$issue complete — $detail (issue: $st)"
  else
    # A CLOSED issue that is not complete is a FALSE COMPLETION CLAIM: someone closed it while its
    # gate is missing, unregistered, or undeclared. That is #461 exactly, and it is the one thing
    # this audit fails on in suite mode — a wrong claim is worse than unfinished work.
    if [ "$st" = "CLOSED" ]; then
      broken=$((broken+1))
      fail "#$issue is CLOSED but its gate is not complete — $detail"
    else
      incomplete=$((incomplete+1))
      echo "  INFO #$issue remaining — $detail (issue: $st)"
    fi
  fi
done <<< "$AUDIT_OUT"

[ "$broken" -eq 0 ] \
  && pass "no manifest entry claims completion it cannot support (0 false completion claims)" \
  || true   # fail() already recorded each one

echo "  manifest: $complete/${#MANIFEST[@]} complete, $incomplete remaining, $broken false claim(s)"

if [ "$MODE" = "release-gate" ]; then
  if [ "$complete" -eq "${#MANIFEST[@]}" ] && [ "$broken" -eq 0 ]; then
    echo "litmus-release: GOALPOST MET — all ${#MANIFEST[@]} manifest entries complete"
    exit 0
  fi
  echo "litmus-release: GOALPOST NOT MET — $complete/${#MANIFEST[@]} complete, $broken false claim(s)" >&2
  exit 1
fi

echo "litmus-release: $PASS pass, $FAIL fail"
