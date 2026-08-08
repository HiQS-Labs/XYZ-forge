#!/usr/bin/env bash
# test/gh438-acceptance-recheck.sh — GH-438 Phase 2.
#
# THE DEFECT. swarm-preflight REQUIRES every fix_probe to read `unfixed` before a run — that is the
# readiness check — and nothing re-read them afterwards. So a phase could report
# `STATUS: Approved, gate passed` and exit 0 while its own contract still said the fix had not
# landed. On the reported lane the detector was `git ls-files --error-unmatch .mcp.json`: it read
# `unfixed` before the run and STILL read `unfixed` after, while the phase reported success and the
# file was still tracked. Observed 2/2 on the same lane. The harness had the exact signal and never
# looked at it.
#
# That is the worst failure shape an autonomous runner has — reporting success while having changed
# nothing — because the operator's own exit code says everything is fine.
#
# Case 1 uses the reported lane verbatim as its fixture: a tracked file, a brief whose whole
# deliverable is untracking it, and a builder that does what the real one did — edits .gitignore,
# which has no effect on an already-tracked file.
source "$(dirname "$0")/_setup.sh" gh438-acceptance-recheck
DRIVER="$(cd "$(dirname "$0")/.." && pwd)/utils/py/marathon_drive.py"
export TICK_BIN="$TICK"
tick_a init >/dev/null

printf '.tick/\n' > "$A/.gitignore"
printf '{"mcpServers":{}}\n' > "$A/.mcp.json"
git -C "$A" add -A >/dev/null 2>&1
git -C "$A" commit -q -m "seed: .mcp.json is tracked"

STUB_CLAUDE="$WORK/stub-claude"; printf '#!/usr/bin/env bash\nexit 0\n' > "$STUB_CLAUDE"; chmod +x "$STUB_CLAUDE"
STUB_AGY="$WORK/stub-agy"; printf '#!/usr/bin/env bash\nexit 0\n' > "$STUB_AGY"; chmod +x "$STUB_AGY"

# A brief carrying the lane's real acceptance detector.
#
# POLARITY, because it reads backwards and cost a debugging round here: eval_probes marks a `command`
# probe `landed` when the command's exit status is NON-zero (the default, expect_nonzero omitted/false).
# Probes describe the BUG, not the fix. `git ls-files --error-unmatch .mcp.json` exits 0 while the
# path is still tracked — that is the bug present, so `unfixed` — and exits non-zero once it has been
# untracked, which is the fix landed. Setting expect_nonzero:true would invert it and mark the
# UNFIXED state as landed, which is exactly the false pass this whole phase exists to prevent.
write_brief() {  # <path>
  cat > "$1" <<BRIEF
# Untrack .mcp.json

## Preflight Contract

\`\`\`json
{
  "target": { "repo": "fixture", "ref": "HEAD" },
  "gate": "true",
  "artifacts": [".gitignore"],
  "fix_probes": [
    { "type": "command", "cmd": "git ls-files --error-unmatch .mcp.json" }
  ]
}
\`\`\`

## What this lane does
Untrack .mcp.json with \`git rm --cached .mcp.json\`.
BRIEF
}

BRIEF="$WORK/brief-mcp.md"; write_brief "$BRIEF"
BRIEF_NONE="$WORK/brief-plain.md"; printf '## brief\nno contract here\n' > "$BRIEF_NONE"

mk_stub() {  # <builder-action>
  cat > "$WORK/rd.sh" <<STUB
#!/usr/bin/env bash
set -eu
relay=""; task=""
while ((\$#)); do
  case "\$1" in
    --relay-file) relay="\$2"; shift 2 ;;
    --relay-task) task="\$2"; shift 2 ;;
    *) shift ;;
  esac
done
$1
sed -i.bak 's/^STATUS:[[:space:]]*.*/STATUS: Approved/' "\$relay"; rm -f "\$relay.bak"
printf '\n### Round 1 · Reviewer · agy\n**Verdict:** Approved\n' >> "\$relay"
TICK_REPO_ROOT="$A" "$TICK" claim "\$task" --agent agy --paths "phases/p1/RELAY.md" >/dev/null 2>&1 || true
TICK_REPO_ROOT="$A" "$TICK" done "\$task" --agent agy >/dev/null 2>&1 || true
exit 0
STUB
  chmod +x "$WORK/rd.sh"
}

run_driver() {  # <brief> [extra-args...]
  local b="$1"; shift
  rm -rf "$A/phases" "$A/.tick"; tick_a init >/dev/null 2>&1 || true
  MARATHON_ROOT="$A" MARATHON_RELAY_DRIVE="$WORK/rd.sh" TICK_REPO_ROOT="$A" TICK_BIN="$TICK" \
  CLAUDE_BIN="$STUB_CLAUDE" AGY_BIN="$STUB_AGY" \
  python3 "$DRIVER" --phases-dir "$A/phases" --phase-brief "$b" --reviewer agy --builder claude \
    --pre-advance-cmd "true" "$@" 2>&1
}

# --- (1) THE REPORTED LANE: reviewer approves, but the fix did not land --------------------------
# The builder does exactly what the real one did — edits .gitignore, which does nothing to an
# already-tracked file. Reviewer approves. Repo gate passes (it knows nothing about this lane).
# Before Phase 2 this exited 0 reporting "Approved, gate passed".
mk_stub 'printf "\n.mcp.json\n" >> "'"$A"'/.gitignore"'
out="$(run_driver "$BRIEF")"; rc=$?
[ "$rc" -ne 0 ] \
  && pass "a lane whose acceptance probe still reports unfixed does NOT exit 0 (rc=$rc)" \
  || fail "GH-438 is back: reported success while the fix had not landed: $out"
printf '%s' "$out" | grep -q "acceptance re-check FAILED" \
  && pass "the failure is reported in the lane's own terms, not as a gate failure" \
  || fail "no acceptance re-check diagnostic: $out"
printf '%s' "$out" | grep -q "acceptance probe still unfixed" \
  && pass "the failing probe is named" || fail "the failing probe was not named: $out"
grep -q 'reason: acceptance-probes-unmet' "$A/phases/p1/ESCALATION.md" 2>/dev/null \
  && pass "ESCALATION.md records acceptance-probes-unmet" \
  || fail "escalation record missing or wrong reason: $(cat "$A/phases/p1/ESCALATION.md" 2>/dev/null)"
git -C "$A" ls-files --error-unmatch .mcp.json >/dev/null 2>&1 \
  && pass "and the file really is still tracked — the lane genuinely did not do its job" \
  || fail "fixture wrong: .mcp.json is not tracked"

# --- (2) THE FIX ACTUALLY LANDS: the same lane must complete -------------------------------------
# Without this the check would be satisfied by failing everything, which is a worse bug.
git -C "$A" reset -q --hard HEAD >/dev/null 2>&1
mk_stub 'git -C "'"$A"'" rm --cached -q .mcp.json'
out="$(run_driver "$BRIEF")"; rc=$?
[ "$rc" -eq 0 ] \
  && pass "the same lane completes once the fix really lands (rc=0)" \
  || fail "a lane that DID do its job was blocked — the check now always fails: $out"
printf '%s' "$out" | grep -q "acceptance re-check passed" \
  && pass "the passing re-check is stated, not silent" || fail "no pass diagnostic: $out"
git -C "$A" reset -q --hard HEAD >/dev/null 2>&1

# --- (3) NO CONTRACT → byte-identical to before ---------------------------------------------------
# Most lanes carry no probes. Failing them closed would break every one of them, so this is the
# regression that matters most.
mk_stub 'true'
out="$(run_driver "$BRIEF_NONE")"; rc=$?
[ "$rc" -eq 0 ] && pass "a brief with no preflight contract is unaffected (rc=0)" \
  || fail "a contract-less lane was blocked by the acceptance re-check: $out"
printf '%s' "$out" | grep -q "acceptance re-check" \
  && fail "a contract-less lane emitted acceptance-recheck output — not byte-identical to before" \
  || pass "a contract-less lane emits no acceptance-recheck output at all"

# --- (4) --dry-run runs no probes -----------------------------------------------------------------
out="$(run_driver "$BRIEF" --dry-run)"; rc=$?
[ "$rc" -eq 0 ] && pass "--dry-run exits 0" || fail "--dry-run exit=$rc"
printf '%s' "$out" | grep -q "acceptance re-check" \
  && fail "--dry-run evaluated acceptance probes (GH-401: a dry run does no work)" \
  || pass "--dry-run evaluates no probes"

# --- (5) the builder cannot rewrite the criteria it is judged by -----------------------------------
# The brief is an input to the phase. Read from the working tree, a builder could soften its own
# acceptance instead of meeting it — marking its own homework. The contract is read from
# pre_phase_head, so an edit made during the phase is ignored.
git -C "$A" reset -q --hard HEAD >/dev/null 2>&1
# Re-establish this case's OWN precondition rather than inheriting it. Case 2's `git rm --cached`
# reached a commit, so .mcp.json was already untracked here — the probe read `landed` and the case
# passed for a reason that had nothing to do with what it claims to test. A fixture that depends on
# a previous case's residue is the same class of defect as a test that cannot fail.
printf '{"mcpServers":{}}\n' > "$A/.mcp.json"
cp "$BRIEF" "$A/brief-tracked.md"
git -C "$A" add .mcp.json brief-tracked.md >/dev/null 2>&1
git -C "$A" commit -q -m "track the brief and re-track .mcp.json"
git -C "$A" ls-files --error-unmatch .mcp.json >/dev/null 2>&1 \
  && pass "case-5 precondition: .mcp.json is tracked, so the original contract reads unfixed" \
  || fail "case-5 precondition failed — .mcp.json is not tracked, the case would pass vacuously"
# The rewritten contract is one that WOULD PASS (`false` exits non-zero → landed). So if the driver
# read the working-tree brief, this phase succeeds; it must fail, proving the original was used.
mk_stub 'printf "# Untrack .mcp.json\n\n## Preflight Contract\n\n```json\n{\"target\":{\"repo\":\"f\",\"ref\":\"HEAD\"},\"gate\":\"true\",\"fix_probes\":[{\"type\":\"command\",\"cmd\":\"false\"}]}\n```\n" > "'"$A"'/brief-tracked.md"'
out="$(run_driver "$A/brief-tracked.md")"; rc=$?
[ "$rc" -ne 0 ] \
  && pass "a builder that rewrote the brief into a PASSING contract is still judged by the original" \
  || fail "the builder softened its own acceptance criteria and the phase passed: $out"
git -C "$A" reset -q --hard HEAD >/dev/null 2>&1

# --- (6) the evaluator is REUSED, not reimplemented -------------------------------------------------
grep -q 'from swarm_preflight import' "$DRIVER" \
  && pass "marathon_drive calls swarm_preflight's probe evaluator rather than a second copy" \
  || fail "a duplicate probe evaluator has appeared — GH-191's 'no second engine' rule"

exit 0
