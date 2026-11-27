#!/usr/bin/env bash
# GH-1637 manual check (recorded evidence, NOT a suite or test: GH-831 forbids new ones).
# Drives the REAL utils/py/relay_drive.py and the REAL relay-automation/consult.sh (consult.py) with stub
# builder/reviewer turn-takers and stub codex/agy advisor binaries, in throwaway repos. No network.
# Run from a disposable full clone:  bash TESTS-RESULTS/2026-11-26+GH-1637/manual_check.sh
set -u
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$ROOT/test/_setup.sh" gh1637-manual >/dev/null   # throwaway $A (clone of a bare remote), $WORK, tick_a, pass/fail
export TICK_BIN="$TICK" RELAY_TARGET_ROOT="$A" XYZ_ARCHIVE_ROOT="$WORK/archive" CONSULT_TIMEOUT=60
unset MARATHON_REVIEWER_GATE_CMD
RD="$ROOT/utils/py/relay_drive.py"
printf '.tick/\nbin/\n.order\n.n\n.consults\n' >"$A/.gitignore"
echo RED >"$A/marker.txt"
git -C "$A" add .gitignore marker.txt && git -C "$A" commit -q -m seed && git -C "$A" push -q origin HEAD:main
SEED="$(git -C "$A" rev-parse HEAD)"
PASSN=0; FAILN=0
ok()  { echo "  PASS: $*"; PASSN=$((PASSN+1)); }
bad() { echo "  FAIL: $*"; FAILN=$((FAILN+1)); }

# ---- stub turn-taker: bld = builder, rev = reviewer ----------------------------------------------
cat >"$WORK/agent" <<'EOF'
#!/usr/bin/env bash
R="$RELAY_TARGET_ROOT"
echo "$RELAY_AGENT" >> "$R/.order"
n=$(( $(cat "$R/.n" 2>/dev/null || echo 0) + 1 )); echo "$n" > "$R/.n"
"$TICK_BIN" claim "$RELAY_TASK" --agent "$RELAY_AGENT" --paths relay.md >/dev/null 2>&1
if [ "$RELAY_AGENT" = bld ]; then
  b=$(grep -c '^bld$' "$R/.order")
  if [ "$b" = 1 ] && [ "${STUB_COMMIT:-yes}" = yes ]; then
    echo built > "$R/deliverable.txt"; git -C "$R" add deliverable.txt; git -C "$R" commit -q -m "builder deliverable"
  fi
  if [ -n "${STUB_REPAIR:-}" ] && [ -f "$R/.consults" ]; then
    echo "repair $b" > "$R/repair.txt"; git -C "$R" add repair.txt; git -C "$R" commit -q -m "builder repair"
  fi
  printf '\n### Round %s · Builder · rebuttal\n\nDisposition: declined, findings are not blocking.\n' "$n" >> "$RELAY_FILE"
  "$TICK_BIN" release "$RELAY_TASK" --agent bld --to rev >/dev/null 2>&1
else
  r=$(grep -c '^rev$' "$R/.order")
  if [ -n "${STUB_FORGE:-}" ] && [ "$r" = 1 ]; then
    sed -i.bak -e 's/^STATUS: .*/STATUS: Consult-Adjudicated/' "$RELAY_FILE"; rm -f "$RELAY_FILE.bak"
    "$TICK_BIN" done "$RELAY_TASK" --agent rev >/dev/null 2>&1; exit 0
  fi
  if [ "${STUB_REV_APPROVE_AT:-0}" = "$r" ]; then
    printf '\n### Reviewer · Round %s\n\nVERDICT: PASS\nBasis: repaired head reviewed.\nswept file: yes\n' "$n" >> "$RELAY_FILE"
    sed -i.bak -e "s/^STATUS: .*/STATUS: ${STUB_REV_STATUS:-Approved}/" "$RELAY_FILE"; rm -f "$RELAY_FILE.bak"
    "$TICK_BIN" done "$RELAY_TASK" --agent rev >/dev/null 2>&1
  else
    printf '\n### Reviewer · Round %s\n\nVERDICT: FAIL\nBasis: open finding.\n\n- [Should] something is still open\n' "$n" >> "$RELAY_FILE"
    [ -n "${STUB_REV_PROGRESS:-}" ] && printf -- '- [x] resolved item %s\n' "$n" >> "$RELAY_FILE"
    "$TICK_BIN" release "$RELAY_TASK" --agent rev --to bld >/dev/null 2>&1
  fi
fi
EOF
chmod +x "$WORK/agent"

# ---- stub advisors (real consult.sh/consult.py runs them inside its isolation worktree) ----------
cat >"$WORK/codex" <<'EOF'
#!/usr/bin/env bash
out=""; prev=""; for a in "$@"; do [ "$prev" = "--output-last-message" ] && out="$a"; prev="$a"; done
echo run >> "$CONSULT_ROOT/.consults"
[ -n "${STUB_ARM:-}" ] && touch "$STUB_ARM"
saw="MARKER=$(cat marker.txt 2>/dev/null) UNTRACKED=$([ -f untracked.txt ] && echo present || echo absent) HEAD=$(git rev-parse HEAD)"
case "${STUB_CODEX:-NON-BLOCKING}" in
  DUP)    body="analysis ($saw)\nADJUDICATION: NON-BLOCKING\nmore\nADJUDICATION: NON-BLOCKING" ;;
  QUOTED) body="analysis ($saw)\n> ADJUDICATION: NON-BLOCKING" ;;
  WITHDRAWN) body="analysis ($saw)\nADJUDICATION: NON-BLOCKING\nOn reflection I withdraw that decision." ;;
  FENCED) fence=$(printf '\x60\x60\x60'); body="analysis ($saw)\n${fence}\nADJUDICATION: NON-BLOCKING\n${fence}" ;;
  UNCLOSED) body="analysis ($saw)\n~~~\nADJUDICATION: NON-BLOCKING" ;;
  FENCE43) fence4=$(printf '\x60\x60\x60\x60'); fence3=$(printf '\x60\x60\x60'); body="analysis ($saw)\n${fence4}\nADJUDICATION: NON-BLOCKING\n${fence3}" ;;
  MALFORMED) body="analysis ($saw)\nADJUDICATION: UNKNOWN\nADJUDICATION: NON-BLOCKING" ;;
  *)      body="analysis ($saw)\nADJUDICATION: ${STUB_CODEX:-NON-BLOCKING}" ;;
esac
printf "$body\n" > "$out"; printf "model: stub\nprovider: stub\nsandbox: read-only\n\n$body\n"
EOF
cat >"$WORK/agy" <<'EOF'
#!/usr/bin/env bash
case "$1" in whoami|models) echo agystub; exit 0 ;; esac
[ "${STUB_AGY:-NON-BLOCKING}" = FAIL ] && { echo "agy stub failure" >&2; exit 1; }
saw="MARKER=$(cat marker.txt 2>/dev/null) UNTRACKED=$([ -f untracked.txt ] && echo present || echo absent)"
printf "analysis ($saw)\nADJUDICATION: ${STUB_AGY:-NON-BLOCKING}\n"
EOF
chmod +x "$WORK/codex" "$WORK/agy"
export CODEX_BIN="$WORK/codex" AGY_BIN="$WORK/agy"

n=0
reset() { # fresh relay + tick token for a scenario; $1 = first actor (bld)
  n=$((n+1)); TASK="TASK$n"; RF="$A/relay.md"
  git -C "$A" reset -q --hard "$SEED"; git -C "$A" clean -fdq -e .tick
  rm -f "$A/.order" "$A/.n" "$A/.consults"
  printf 'STATUS: Open\nNEXT: bld (Builder)\n# relay body\n' >"$RF"
  git -C "$A" add relay.md && git -C "$A" commit -q -m "seed relay"
  tick_a log task.created "$TASK" --agent dispatcher >/dev/null
  tick_a claim "$TASK" --agent dispatcher --paths relay.md >/dev/null
  tick_a release "$TASK" --agent dispatcher --to bld >/dev/null
}
drive() { # drive <round-cap> [extra relay_drive args...]; sets OUT, RC
  local cap="$1"; shift
  OUT="$(RELAY_DIFF_BASE=origin/main python3 "$RD" --relay-file "$RF" --agent-cmd "$WORK/agent" --relay-task "$TASK" \
         --round-cap "$cap" --reviewer rev --builder bld "$@" 2>&1)"; RC=$?
}
status() { sed -n 's/^STATUS: *//p' "$RF" | head -1; }
consults() { [ -f "$A/.consults" ] && wc -l <"$A/.consults" | tr -d ' ' || echo 0; }
order() { tr '\n' ' ' <"$A/.order" 2>/dev/null | sed 's/ $//'; }
token() { tick_a info "$TASK" 2>/dev/null | sed -n 's/^status: *//p' | head -1; }
attest() { ls "$A/.git/relay-attest/$TASK.json" 2>/dev/null; }
export STUB_CODEX=NON-BLOCKING STUB_AGY=NON-BLOCKING

echo "== S1 both NON-BLOCKING -> Consult-Adjudicated (cap 3, reviewer finding open, builder rebuttal last)"
reset; drive 3 --consult-at-cap
[ "$RC" = 0 ] && ok "S1 exit 0" || bad "S1 exit $RC: $OUT"
[ "$(status)" = "Consult-Adjudicated" ] && ok "S1 STATUS is Consult-Adjudicated (not Approved)" || bad "S1 status '$(status)'"
[ "$(token)" = done ] && ok "S1 token closed" || bad "S1 token '$(token)'"
python3 - "$ROOT" "$A" "$TASK" "$RF" <<'EOF' && ok "S1 attestation record loads with adjudication provenance" || bad "S1 attestation record"
import sys, os
root, repo, task, rf = sys.argv[1:5]
sys.path.insert(0, os.path.join(root, "utils", "py"))
import relay_attest
rec, why = relay_attest.load(task, expected_reviewer="rev", relay_file=rf, target_repo=repo)
assert rec is not None, why
assert rec["status"] == "Consult-Adjudicated" and rec["adjudication"]["advisors"] == {"codex": "NON-BLOCKING", "agy": "NON-BLOCKING"}, rec
print("   record:", rec["status"], rec["adjudication"]["advisors"], "candidate", rec["adjudication"]["candidate"][:12])
EOF
python3 - "$ROOT" "$A" "$TASK" "$RF" <<'EOF' && ok "S1 jog merge boundary refuses the record before any merge call" || bad "S1 merge boundary"
import sys, os
root, repo, task, rf = sys.argv[1:5]
sys.path.insert(0, os.path.join(root, "utils", "py"))
import relay_attest, jog_run
rec, why = relay_attest.load(task, expected_reviewer="rev", relay_file=rf, target_repo=repo)
merged, reason = jog_run._merge_reviewed_pr(repo, 1, rec)
assert merged is False and "consult-adjudicated" in reason, (merged, reason)
print("   refusal:", reason)
EOF
python3 - "$ROOT" "$A" "$TASK" "$RF" <<'PYEOF' && ok "S1 Approved/Closed records still reach the candidate checks (no consult-adjudicated refusal); adjudicated returns first" || bad "S1 merge triple"
import sys, os
root, repo, task, rf = sys.argv[1:5]
sys.path.insert(0, os.path.join(root, "utils", "py"))
import relay_attest, jog_run
rec, why = relay_attest.load(task, expected_reviewer="rev", relay_file=rf, target_repo=repo)
out = {}
for status in ("Approved", "Closed", "Consult-Adjudicated"):
    merged, reason = jog_run._merge_reviewed_pr(repo, 1, dict(rec, status=status))
    out[status] = (merged, reason)
    print("   ", status, "->", reason)
assert "consult-adjudicated" in out["Consult-Adjudicated"][1]
for s in ("Approved", "Closed"):
    assert out[s][0] is False and "consult-adjudicated" not in out[s][1] and "could not read PR" in out[s][1], out[s]
PYEOF
grep -q "Round-cap tie-break" "$RF" && grep -q "codex=NON-BLOCKING, agy=NON-BLOCKING" "$RF" && ok "S1 consult block with both verdicts is in the committed transcript" || bad "S1 consult block"
[ "$(consults)" = 1 ] && ok "S1 exactly one consult" || bad "S1 consults=$(consults)"

echo "== S2 REAL at cap 3, reviewer next: builder is dispatched before any reviewer can approve"
reset; STUB_REPAIR=1 STUB_CODEX=REAL STUB_REV_APPROVE_AT=2 drive 3 --consult-at-cap
[ "$RC" = 0 ] && [ "$(status)" = Approved ] && ok "S2 repaired head then approved (exit 0, Approved)" || bad "S2 rc=$RC status=$(status): $OUT"
repair_attested() { # the approval's reviewed_head is a descendant of, and differs from, the head the consult judged
  python3 - "$A" "$TASK" "$RF" <<'PYEOF'
import json, re, subprocess, sys
repo, task, rf = sys.argv[1:4]
cand = re.search(r"candidate ([0-9a-f]{40})", open(rf).read()).group(1)
rec = json.load(open(f"{repo}/.git/relay-attest/{task}.json"))
assert rec["status"] == "Approved" and rec["reviewed_head"] != cand, (rec["status"], rec["reviewed_head"], cand)
assert subprocess.run(["git", "-C", repo, "merge-base", "--is-ancestor", cand, rec["reviewed_head"]]).returncode == 0
print("   consult judged", cand[:12], "-> reviewer attested repaired", rec["reviewed_head"][:12])
PYEOF
}
repair_attested && ok "S2 the approval attests a CHANGED repair head, not the head the consult judged" || bad "S2 repair head"
[ "$(order)" = "bld rev bld bld rev" ] && ok "S2 order bld rev bld | consult | bld rev" || bad "S2 order '$(order)'"
[ "$(consults)" = 1 ] && ok "S2 no second consult" || bad "S2 consults=$(consults)"
echo "== S2b REAL at cap 2 (reviewer just finished; builder next)"
reset; STUB_REPAIR=1 STUB_CODEX=REAL STUB_REV_APPROVE_AT=2 drive 2 --consult-at-cap
[ "$RC" = 0 ] && [ "$(order)" = "bld rev bld rev" ] && ok "S2b order bld rev | consult | bld rev, approved on the repaired head" || bad "S2b rc=$RC order '$(order)' status $(status)"
echo "== S2e REAL, builder hands back WITHOUT repairing, reviewer tries to approve: refused (repair-missing), no Approved attestation"
reset; STUB_CODEX=REAL STUB_REV_APPROVE_AT=2 drive 2 --consult-at-cap
[ "$RC" = 4 ] && grep -q "repair-missing" <<<"$OUT" && [ -z "$(attest)" ] && ok "S2e unchanged candidate cannot be approved after a REAL verdict" || bad "S2e rc=$RC attest=$(attest): $OUT"
echo "== S2c REAL then the repaired lane still fails: second cap escalates, no second consult"
reset; STUB_CODEX=REAL STUB_REV_PROGRESS=1 drive 3 --consult-at-cap
[ "$RC" = 4 ] && [ "$(consults)" = 1 ] && [ "$(order)" = "bld rev bld bld rev" ] && ok "S2c repair reviewer records progress yet the lane ends after exactly the two repair turns (order '$(order)', one consult)" || bad "S2c rc=$RC consults=$(consults) order='$(order)': $OUT"
echo "== S2d REAL at the new default cap 9 (builder-first alternation, reviewer next at the cap)"
reset; STUB_REPAIR=1 STUB_CODEX=REAL STUB_REV_APPROVE_AT=5 drive 9 --consult-at-cap
repair_attested && ok "S2d the approval attests a CHANGED repair head" || bad "S2d repair head"
[ "$RC" = 0 ] && [ "$(status)" = Approved ] && [ "$(order)" = "bld rev bld rev bld rev bld rev bld bld rev" ] && ok "S2d cap 9: 9 turns, consult, builder repair, reviewer approves the repaired SHA" || bad "S2d rc=$RC status=$(status) order='$(order)'"

echo "== S2f REAL, no repair, reviewer writes CLOSED instead of Approved: refused too (repair-missing)"
reset; STUB_CODEX=REAL STUB_REV_APPROVE_AT=2 STUB_REV_STATUS=Closed drive 2 --consult-at-cap
[ "$RC" = 4 ] && grep -q "repair-missing" <<<"$OUT" && [ -z "$(attest)" ] && ok "S2f an unchanged candidate cannot be Closed after a REAL verdict" || bad "S2f rc=$RC attest=$(attest): $OUT"
echo "== S3 SAFETY -> hold"
reset; STUB_AGY=SAFETY drive 3 --consult-at-cap
[ "$RC" = 4 ] && grep -q "consult-hold" <<<"$OUT" && [ "$(status)" = Open ] && ok "S3 consult-hold, STATUS still Open" || bad "S3 rc=$RC status=$(status): $OUT"
echo "== S3b a valid SAFETY veto stands when the peer advisor fails -> consult-hold (not inconclusive)"
reset; STUB_CODEX=SAFETY STUB_AGY=FAIL drive 3 --consult-at-cap
[ "$RC" = 4 ] && grep -q "consult-hold" <<<"$OUT" && [ "$(status)" = Open ] && ok "S3b SAFETY + failed peer = consult-hold" || bad "S3b rc=$RC status=$(status): $OUT"
echo "== S4 one advisor fails -> consult-inconclusive (a lone NON-BLOCKING never adjudicates)"
reset; STUB_AGY=FAIL drive 3 --consult-at-cap
[ "$RC" = 4 ] && grep -q "consult-inconclusive" <<<"$OUT" && [ "$(status)" = Open ] && ok "S4 hold" || bad "S4 rc=$RC status=$(status): $OUT"
echo "== S5 duplicate final verdict / token only in quoted text -> consult-inconclusive"
reset; STUB_CODEX=DUP drive 3 --consult-at-cap
[ "$RC" = 4 ] && grep -q "consult-inconclusive" <<<"$OUT" && ok "S5 duplicate verdict holds" || bad "S5 dup rc=$RC: $OUT"
reset; STUB_CODEX=QUOTED drive 3 --consult-at-cap
[ "$RC" = 4 ] && grep -q "consult-inconclusive" <<<"$OUT" && ok "S5 quoted-only token holds" || bad "S5 quoted rc=$RC: $OUT"

for mode in WITHDRAWN FENCED UNCLOSED FENCE43 MALFORMED; do
  reset; STUB_CODEX=$mode drive 3 --consult-at-cap
  [ "$RC" = 4 ] && grep -q "consult-inconclusive" <<<"$OUT" && [ "$(status)" = Open ] && ok "S5 $mode verdict does not adjudicate" || bad "S5 $mode rc=$RC status=$(status): $OUT"
done
echo "== S6 red focused driver gate after two NON-BLOCKING: STATUS restored, token still open, no attestation"
reset; MARATHON_REVIEWER_GATE_CMD=false drive 3 --consult-at-cap
[ "$RC" = 4 ] && [ "$(status)" = Open ] && [ "$(token)" = open ] && [ -z "$(attest)" ] && ok "S6 refused: Open, token open, no attestation" || bad "S6 rc=$RC status=$(status) token=$(token) attest=$(attest): $OUT"
echo "== S7 refused token close (tick done fails): STATUS restored, token handed back, no attestation"
printf '#!/usr/bin/env bash\n[ "$1" = done ] && exit 1\nexec "%s" "$@"\n' "$TICK" >"$WORK/tick-nodone"; chmod +x "$WORK/tick-nodone"
reset; TICK_BIN="$WORK/tick-nodone" drive 3 --consult-at-cap
[ "$RC" = 4 ] && [ "$(status)" = Open ] && [ "$(token)" = open ] && [ -z "$(attest)" ] && ok "S7 token-close-failed: Open, token open, no attestation" || bad "S7 rc=$RC status=$(status) token=$(token): $OUT"
grep -q "token-close-failed" <<<"$OUT" && ok "S7 reason named" || bad "S7 reason missing"
echo "== S7b a refused handoff release after the driver claimed the token: token handed back, STATUS Open"
cat >"$WORK/tick-norelease" <<EOT
#!/usr/bin/env bash
if [ "\$1" = release ] && [ -f "$WORK/fail-release" ] && [[ " \$* " == *" --to bld "* ]]; then rm -f "$WORK/fail-release"; exit 1; fi
exec "$TICK" "\$@"
EOT
chmod +x "$WORK/tick-norelease"
reset; rm -f "$WORK/fail-release"; STUB_ARM="$WORK/fail-release" STUB_CODEX=REAL TICK_BIN="$WORK/tick-norelease" drive 3 --consult-at-cap
info="$(tick_a info "$TASK" 2>/dev/null)"
[ "$RC" = 4 ] && grep -q "consult-inconclusive" <<<"$OUT" && [ "$(token)" = open ] && grep -q "handoff-to: rev" <<<"$info" && [ "$(status)" = Open ] && ok "S7b claim rolled back: token open, handoff-to rev, STATUS Open" || bad "S7b rc=$RC token=$(token) status=$(status) info=$(tr '\n' ' ' <<<"$info")"
echo "== S7c a refused REVIEWER claim after the builder-to-reviewer transfer (cap 2: builder holds the handoff): original handoff restored"
cat >"$WORK/tick-noclaim" <<EOT
#!/usr/bin/env bash
if [ "\$1" = claim ] && [ -f "$WORK/fail-claim" ] && [[ " \$* " == *" --agent rev "* ]]; then rm -f "$WORK/fail-claim"; exit 1; fi
exec "$TICK" "\$@"
EOT
chmod +x "$WORK/tick-noclaim"
reset; rm -f "$WORK/fail-claim"; STUB_ARM="$WORK/fail-claim" TICK_BIN="$WORK/tick-noclaim" drive 2 --consult-at-cap
info="$(tick_a info "$TASK" 2>/dev/null)"
[ "$RC" = 4 ] && grep -q "token-close-failed" <<<"$OUT" && [ "$(token)" = open ] && grep -q "handoff-to: bld" <<<"$info" && [ "$(status)" = Open ] && [ -z "$(attest)" ] && ok "S7c refused reviewer claim: token open, handoff-to bld (restored), STATUS Open, no attestation" || bad "S7c rc=$RC token=$(token) status=$(status) info=$(tr '\n' ' ' <<<"$info")"
echo "== S8 receipt-write failure AFTER done: no attestation, token spent (existing spent-token case; marathon.sh --retry mints a fresh token)"
reset; mkdir -p "$A/.git/relay-attest/$TASK.json"
drive 3 --consult-at-cap
[ "$RC" = 4 ] && [ "$(token)" = done ] && grep -q "attest-publish-failed" <<<"$OUT" && ok "S8 attest-publish-failed, token done, no ready terminal" || bad "S8 rc=$RC token=$(token): $OUT"

echo "== S9 a reviewer TURN that writes Consult-Adjudicated itself is reverted as forged"
reset; STUB_FORGE=1 drive 3 --consult-at-cap
[ "$RC" = 4 ] && [ "$(status)" != Consult-Adjudicated ] && grep -q "only relay-drive's consult-at-cap may record" <<<"$OUT" && ok "S9 forged terminal reverted (exit 4)" || bad "S9 rc=$RC status=$(status): $OUT"

echo "== S10 transcript-only candidate (builder commits no deliverable): hold before any consult"
reset; STUB_COMMIT=no drive 3 --consult-at-cap
[ "$RC" = 4 ] && [ "$(consults)" = 0 ] && grep -q "no deliverable change" <<<"$OUT" && ok "S10 holds, consult never ran" || bad "S10 rc=$RC consults=$(consults): $OUT"

echo "== S10b the candidate patch cannot be captured (git diff fails after the name-only check passed): hold before any advisor is dispatched"
REAL_GIT="$(command -v git)"; mkdir -p "$WORK/shim"
printf '#!/usr/bin/env bash\ncase " $* " in *" diff "*) case " $* " in *" --name-only "*) ;; *) exit 128 ;; esac ;; esac\nexec "%s" "$@"\n' "$REAL_GIT" >"$WORK/shim/git"; chmod +x "$WORK/shim/git"
reset; PATH="$WORK/shim:$PATH" drive 3 --consult-at-cap
[ "$RC" = 4 ] && [ "$(consults)" = 0 ] && grep -q "could not capture the candidate patch" <<<"$OUT" && [ "$(status)" = Open ] && [ -z "$(attest)" ] && ok "S10b patch capture failure holds: no advisor dispatched, STATUS Open, no attestation" || bad "S10b rc=$RC consults=$(consults) status=$(status): $OUT"
echo "== S11 default-off: same lane without --consult-at-cap keeps cap-stalled, no consult"
reset; drive 3
[ "$RC" = 4 ] && grep -q "cap-stalled" <<<"$OUT" && [ "$(consults)" = 0 ] && ok "S11 cap-stalled, zero consults" || bad "S11 rc=$RC consults=$(consults): $OUT"

echo "== S12 dirty target: advisors read the pinned candidate, not the working tree"
reset; echo GREEN >"$A/marker.txt"; echo x >"$A/untracked.txt"; rm -rf "$WORK/archive"   # only this run's answers below
drive 3 --consult-at-cap
ans="$(find "$WORK/archive" -name '*.codex.md' | head -1)"
[ -n "$ans" ] && grep -q "MARKER=RED UNTRACKED=absent" "$ans" && grep -q "MARKER=RED UNTRACKED=absent" "$(find "$WORK/archive" -name '*.agy.md' | head -1)" \
  && ok "S12 both advisors saw MARKER=RED UNTRACKED=absent (working tree has GREEN + untracked.txt)" || bad "S12 advisors saw: $(grep -h MARKER "$WORK"/archive/*/*/*.md 2>/dev/null | head -2)"
cand="$(python3 -c "import json,sys;print(json.load(open('$A/.git/relay-attest/$TASK.json'))['adjudication']['candidate'])" 2>/dev/null)"
grep -q "HEAD=$cand" "$ans" && ok "S12 advisor HEAD equals the attested candidate ${cand:0:12}" || bad "S12 candidate/advisor HEAD mismatch (rc=$RC status=$(status) cand='$cand' advisor=$(grep -o 'HEAD=[0-9a-f]*' "$ans" | head -1))"

echo
echo "RESULT: $PASSN passed, $FAILN failed"
[ "$FAILN" = 0 ]
