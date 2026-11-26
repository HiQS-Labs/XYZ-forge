#!/usr/bin/env bash
# GH-1637 manual check, Marathon level (recorded evidence, NOT a suite; GH-831).
# Drives the REAL utils/py/marathon_drive.py -> REAL relay_drive.py -> REAL consult.sh with stub turn-takers
# and stub advisors, to see: the new default cap, --consult-at-cap being passed, the adjudicated terminal being
# accepted through Marathon's attestation + pre-advance gate, the result receipt / PR text naming it, and the
# existing acceptance recheck still stopping an unfixed candidate before success.
# Run from a disposable full clone:  bash TESTS-RESULTS/2026-11-26+GH-1637/manual_check_marathon.sh
set -u
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$ROOT/test/_setup.sh" gh1637-marathon >/dev/null
unset XYZ_ARCHIVE_ROOT   # transcripts and consult answers land in <clone>/relay-system (this is a disposable clone)
export TICK_BIN="$TICK" CONSULT_TIMEOUT=60 XYZ_HARNESS_CONTEXT=marathon MARATHON_ROOT="$A"
unset MARATHON_REVIEWER_GATE_CMD
printf '.tick/\nbin/\n.order\n.n\n.consults\nagy\ncodex\n' >"$A/.gitignore"
echo RED >"$A/marker.txt"; git -C "$A" add .gitignore marker.txt && git -C "$A" commit -q -m seed && git -C "$A" push -q origin HEAD:main
PASSN=0; FAILN=0
ok()  { echo "  PASS: $*"; PASSN=$((PASSN+1)); }
bad() { echo "  FAIL: $*"; FAILN=$((FAILN+1)); }

# builder = agy, reviewer = codex (marathon's default pair); the builder commits a deliverable on its first turn
cat >"$WORK/agent" <<'EOF'
#!/usr/bin/env bash
R="$RELAY_TARGET_ROOT"; [ -n "$R" ] || R="$MARATHON_ROOT"
echo "$RELAY_AGENT" >> "$R/.order"
"$TICK_BIN" claim "$RELAY_TASK" --agent "$RELAY_AGENT" --paths "$RELAY_FILE" >/dev/null 2>&1
if [ "$RELAY_AGENT" = agy ]; then
  if [ "$(grep -c '^agy$' "$R/.order")" = 1 ]; then
    echo built > "$R/deliverable.txt"; git -C "$R" add deliverable.txt; git -C "$R" commit -q -m "builder deliverable"
  fi
  printf '\n### Round 1 · Builder · rebuttal\n\nDisposition: declined, findings are not blocking.\n' >> "$RELAY_FILE"
  "$TICK_BIN" release "$RELAY_TASK" --agent agy --to codex >/dev/null 2>&1
else
  printf '\n### Reviewer · Round 2\n\nVERDICT: FAIL\nBasis: open finding.\n\n- [Should] something is still open\n' >> "$RELAY_FILE"
  "$TICK_BIN" release "$RELAY_TASK" --agent codex --to agy >/dev/null 2>&1
fi
EOF
chmod +x "$WORK/agent"
cat >"$WORK/codex" <<'EOF'
#!/usr/bin/env bash
out=""; prev=""; for a in "$@"; do [ "$prev" = "--output-last-message" ] && out="$a"; prev="$a"; done
printf "analysis\nADJUDICATION: NON-BLOCKING\n" > "$out"; printf "model: stub\n\nanalysis\nADJUDICATION: NON-BLOCKING\n"
EOF
cat >"$WORK/agy" <<'EOF'
#!/usr/bin/env bash
case "$1" in whoami|models) echo agystub; exit 0 ;; esac
printf "analysis\nADJUDICATION: NON-BLOCKING\n"
EOF
chmod +x "$WORK/codex" "$WORK/agy"
export CODEX_BIN="$WORK/codex" AGY_BIN="$WORK/agy" MARATHON_AGENT_CMD="$WORK/agent" RELAY_TARGET_ROOT="$A"
# marathon probes the client binaries named by --builder/--reviewer on PATH; the stubs above answer for consult only
mkdir -p "$WORK/bin"; for c in agy codex; do printf '#!/usr/bin/env bash\nexit 99\n' >"$WORK/bin/$c"; chmod +x "$WORK/bin/$c"; done
export PATH="$WORK/bin:$PATH"

printf 'Phase brief: build deliverable.txt\n' >"$A/brief.md"

echo "== M1 default cap: no --round-cap and no brief round-cap -> 9 (4 review rounds), dry run"
out="$(python3 "$ROOT/utils/py/marathon_drive.py" --phase-brief "$A/brief.md" --reviewer codex --builder agy --dry-run 2>&1)"
grep -q "round-cap=9" <<<"$out" && ok "M1 default round-cap=9" || bad "M1 $out"
echo "== M1b marathon.sh default: a phase with no max_review_rounds gets cap 2*4+1 = 9 (dry run)"
cat >"$A/plan.yaml" <<'EOF'
name: gh1637
phases:
  - id: p1
    reviewer: codex
    brief: brief.md
EOF
mout="$(cd "$A" && MARATHON_HOME="$ROOT" MARATHON_ROOT="$A" MARATHON_ALLOW_PLAN_OUTSIDE_WORKING=1 bash "$ROOT/relay-automation/marathon.sh" --plan "$A/plan.yaml" --dry-run 2>&1)"
grep -q "round-cap=9" <<<"$mout" && ok "M1b marathon.sh phase default round-cap=9" || bad "M1b $mout"

echo "== M2 full path: marathon -> relay-drive consult-at-cap -> Consult-Adjudicated -> pre-advance gate -> success"
git -C "$A" push -q origin HEAD:main 2>/dev/null
RES="$WORK/result.json"
out="$(python3 "$ROOT/utils/py/marathon_drive.py" --phase-brief "$A/brief.md" --reviewer codex --builder agy --phase-id p1 --relay-task TASKM \
      --phases-dir "$A/phases" --round-cap 3 --force --pre-advance-cmd true --result-file "$RES" 2>&1)"; rc=$?
[ "$rc" = 0 ] && ok "M2 marathon exit 0" || bad "M2 exit $rc: $(tail -25 <<<"$out")"
grep -q "consult-adjudicated, not a reviewer approval" <<<"$out" && ok "M2 success text names the adjudication" || bad "M2 success text"
python3 - "$RES" <<'EOF' && ok "M2 result receipt: outcome approved, relay_status Consult-Adjudicated" || bad "M2 receipt"
import json, sys
r = json.load(open(sys.argv[1]))
assert r["relay_status"] == "Consult-Adjudicated" and r["outcome"] == "approved", (r["relay_status"], r["outcome"])
assert r["gate"]["result"] in ("pass", "passed", "PASS") or r["gate"]["exit"] == 0, r["gate"]
print("   receipt:", r["outcome"], r["relay_status"], "gate", r["gate"]["result"], "attest", bool(r["attest_path"]))
EOF
python3 - "$ROOT" <<'EOF' && ok "M2b lane_pr_notes names consult-adjudicated, advisors and not-a-reviewer-approval" || bad "M2b lane_pr_notes"
import ast, sys, pathlib
tree = ast.parse(pathlib.Path(sys.argv[1], "utils/py/marathon_drive.py").read_text())
fn = next(n for n in tree.body if isinstance(n, ast.FunctionDef) and n.name == "lane_pr_notes")
ns = {}; exec(compile(ast.Module(body=[fn], type_ignores=[]), "<n>", "exec"), ns)
adj = {"advisors": {"codex": "NON-BLOCKING", "agy": "NON-BLOCKING"}, "candidate": "a" * 40, "excerpts": {"codex": "reasoning one\nADJUDICATION: NON-BLOCKING", "agy": "reasoning two\nADJUDICATION: NON-BLOCKING"}}
txt = ns["lane_pr_notes"]("p1", "1637", False, adj)
assert "consult-adjudicated" in txt and "not a reviewer approval" in txt and "codex=NON-BLOCKING" in txt and "reasoning one" in txt and "reasoning two" in txt and "operator's call" in txt, txt
plain = ns["lane_pr_notes"]("p1", "1637", False)
assert "consult-adjudicated" not in plain
print("   PR notes:", txt.replace("\n", " | ")[:200])
EOF

echo "== M3 default-off through Marathon is unchanged where no reviewer turn completed (cap 1) -> cap-stalled"
printf '#!/usr/bin/env bash\n"$TICK_BIN" claim "$RELAY_TASK" --agent "$RELAY_AGENT" --paths "$RELAY_FILE" >/dev/null 2>&1\nif [ "$RELAY_AGENT" = agy ]; then n=codex; else n=agy; fi\n"$TICK_BIN" release "$RELAY_TASK" --agent "$RELAY_AGENT" --to "$n" >/dev/null 2>&1\n' >"$WORK/agent2"; chmod +x "$WORK/agent2"
tick_a log task.created TASKN --agent dispatcher >/dev/null
out="$(MARATHON_AGENT_CMD="$WORK/agent2" python3 "$ROOT/utils/py/marathon_drive.py" --phase-brief "$A/brief.md" --reviewer codex --builder agy --phase-id pN --relay-task TASKN --phases-dir "$A/phases" --round-cap 1 --force --pre-advance-cmd true 2>&1)"; rc=$?
[ "$rc" = 4 ] && grep -q "reason: cap-stalled" "$A/phases/pN/ESCALATION.md" 2>/dev/null && ok "M3 cap 1 still ends cap-stalled (no reviewer turn, no consult)" || bad "M3 rc=$rc: $(tail -5 <<<"$out")"

echo "== M4 the existing acceptance recheck still judges an ADJUDICATED candidate (red control, then green)"
mkbrief() { # $1 = file, $2 = probe command; the probe exits 0 only when the fix has landed
cat >"$1" <<EOB
Phase brief: build deliverable.txt

## Swarm Preflight Contract

\`\`\`json
{"target": {"repo": ".", "ref": "main"}, "gate": "true", "artifacts": ["deliverable.txt"],
 "fix_probes": [{"type": "command", "cmd": "$2", "expect_nonzero": true}],
 "remediation": {"source": "issue#1637", "criteria": "deliverable.txt exists"}}
\`\`\`
EOB
}
mkbrief "$A/brief-unfixed.md" "test -f never-built.txt"; mkbrief "$A/brief-fixed.md" "test -f deliverable.txt"
git -C "$A" add brief-unfixed.md brief-fixed.md && git -C "$A" commit -q -m "briefs"
for which in unfixed fixed; do
  git -C "$A" reset -q --hard HEAD; git -C "$A" clean -fdq -e .tick -e phases; rm -f "$A/.order"
  git -C "$A" rm -q -f --ignore-unmatch deliverable.txt >/dev/null 2>&1
  tick_a log task.created "TASK-$which" --agent dispatcher >/dev/null
  out="$(python3 "$ROOT/utils/py/marathon_drive.py" --phase-brief "$A/brief-$which.md" --reviewer codex --builder agy --phase-id "p-$which" \
        --relay-task "TASK-$which" --phases-dir "$A/phases" --round-cap 3 --force --pre-advance-cmd true --result-file "$WORK/r-$which.json" 2>&1)"; rc=$?
  if [ "$which" = unfixed ]; then
    [ "$rc" = 5 ] && grep -q "acceptance-probes-unmet" <<<"$out" && ok "M4 unfixed candidate: adjudicated terminal, then acceptance-probes-unmet (exit 5), no success" || bad "M4 unfixed rc=$rc: $(tail -12 <<<"$out")"
  else
    [ "$rc" = 0 ] && grep -q "Consult-Adjudicated" "$WORK/r-fixed.json" && ok "M4 fixed candidate: adjudicated terminal advances (exit 0)" || bad "M4 fixed rc=$rc: $(tail -12 <<<"$out")"
  fi
done

echo "== M5 red pre-advance gate after an adjudicated terminal (default path: no focused gate, so the real gate is Marathon's pre-advance)"
git -C "$A" reset -q --hard HEAD; git -C "$A" clean -fdq -e .tick -e phases; rm -f "$A/.order"
tick_a log task.created TASK-M5 --agent dispatcher >/dev/null
out="$(python3 "$ROOT/utils/py/marathon_drive.py" --phase-brief "$A/brief-fixed.md" --reviewer codex --builder agy --phase-id p-m5 \
      --relay-task TASK-M5 --phases-dir "$A/phases" --round-cap 3 --force --pre-advance-cmd false --result-file "$WORK/r-m5.json" 2>&1)"; rc=$?
python3 - "$WORK/r-m5.json" "$rc" <<'PYEOF' && ok "M5 red pre-advance gate: exit 5, no approved outcome, no ready PR (relay_status Consult-Adjudicated kept in the receipt)" || bad "M5 rc=$rc: $(tail -8 <<<"$out")"
import json, sys
r = json.load(open(sys.argv[1])); rc = int(sys.argv[2])
assert rc == 5 and r["outcome"] != "approved" and r["pr"]["number"] is None, (rc, r["outcome"], r["pr"])
print("   receipt:", r["outcome"], r["reason"], "| relay_status", r["relay_status"], "| gate", r["gate"]["result"])
PYEOF

echo "== M6 mixed Approved/adjudicated multi-phase closeout summary keeps the count and labels the adjudicated phase"
mkdir -p "$A/briefs" "$A/PROJECT/2-WORKING"; printf 'brief\n' >"$A/briefs/p1.md"; printf 'brief\n' >"$A/briefs/p2.md"
cat >"$A/PROJECT/2-WORKING/mix.yaml" <<'EOP'
name: mix
phases:
  - id: p1
    reviewer: codex
    brief: briefs/p1.md
  - id: p2
    reviewer: codex
    depends_on: p1
    brief: briefs/p2.md
EOP
cat >"$WORK/drive-stub.sh" <<'EOP'
#!/usr/bin/env bash
pid=""; while (($#)); do case "$1" in --phase-id) pid="$2"; shift 2;; *) shift;; esac; done
[ "$pid" = p2 ] && echo "p2 (agy=NON-BLOCKING, codex=NON-BLOCKING)" >> "$MARATHON_ADJUDICATED_FILE"
exit 0
EOP
cat >"$WORK/closeout-stub.sh" <<'EOP'
#!/usr/bin/env bash
while (($#)); do case "$1" in --notes) printf '%s\n' "$2" > "$CLOSEOUT_NOTES_OUT"; shift 2;; *) shift;; esac; done
exit 0
EOP
chmod +x "$WORK/drive-stub.sh" "$WORK/closeout-stub.sh"
CLOSEOUT_NOTES_OUT="$WORK/closeout-notes.txt" RELAY_TURN_TIMEOUT_S= MARATHON_ROOT="$A" MARATHON_DRIVE="$WORK/drive-stub.sh" MARATHON_CLOSEOUT_BIN="$WORK/closeout-stub.sh" \
  MARATHON_YAML_BIN="$ROOT/bin/marathon-yaml" TICK_BIN="$TICK" bash "$ROOT/relay-automation/marathon.sh" --plan "$A/PROJECT/2-WORKING/mix.yaml" --closeout-pr >/dev/null 2>&1
grep -q "Phases approved: 2/2 (consult-adjudicated, not reviewer-approved: p2 (agy=NON-BLOCKING, codex=NON-BLOCKING))" "$WORK/closeout-notes.txt" 2>/dev/null \
  && ok "M6 closeout summary: count kept (2/2) and p2 labelled consult-adjudicated with its verdicts" || bad "M6 notes: $(cat "$WORK/closeout-notes.txt" 2>/dev/null)"

echo
echo "RESULT: $PASSN passed, $FAILN failed"
[ "$FAILN" = 0 ]
