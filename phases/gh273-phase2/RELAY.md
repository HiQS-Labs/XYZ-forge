# Marathon Phase gh273-phase2
STATUS: Open
NEXT: codex

<!-- marathon-drive: task=MARATHON-GH273-PHASE2-TURN builder=codex reviewer=agy round-cap=5 -->

## Phase Brief

# Marathon preflight packet — gh-273-marathon-closeout-automation

- Generated: 2026-07-22T03:16:49Z
- Mode: gh-bundle
- Sources: /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/PROJECT/2-WORKING/GH-273-MARATHON-CLOSEOUT-AUTOMATION.md 
- Target root: /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm (development @ 680e18ac2)
- Suggested branch: `marathon/gh-273-marathon-closeout-automation-2026-07-22` (branch_ready=false — not cut yet; ask the operator before proceeding, per GUIDING-PRINCIPLES.md §8)
- Verdict: ready
- Gate: `bash validate.sh`

- Artifacts: .claude/loose-ends-sequence.md
- Suggested turn budget: `RELAY_TURN_TIMEOUT_S=300` (sized to ≈ 0 LOC across 1 artifact(s); a build that also edits tests needs headroom over the 300s default)


This packet is the producer's output. The orchestrator launches the run; the planner does not
(GUIDING-PRINCIPLES.md §8).

## Acceptance criteria — the build is DONE when these hold (inlined from the capture doc)
(no '- [ ]' checklist found in /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/PROJECT/2-WORKING/GH-273-MARATHON-CLOSEOUT-AUTOMATION.md — add an Acceptance criteria list)

## Scope lock — builder, do exactly this and nothing else
- Edit ONLY: `.claude/loose-ends-sequence.md` (plus the relay file). Any other edit is reverted and FAILS the turn.
- Do NOT run the full gate (`bash validate.sh`) yourself — it can create files that trip containment and discard your turn. Verify with ONLY the specific test for the file(s) you changed; the harness runs the gate after your turn.
- Do NOT analyze the roadmap, file issues, or refactor adjacent code. Implement the acceptance criteria above — nothing more.

## Suggested marathon-drive.sh invocation

```bash
XYZ_HARNESS_CONTEXT=swarm XYZ_SESSION_ID=gh-273-marathon-closeout-automation relay-automation/marathon-drive.sh \
  --phase-brief <packet>/packet.md \
  --reviewer agy \
  --builder codex \
  --artifact .claude/loose-ends-sequence.md \
  --pre-advance-cmd 'bash validate.sh' \
  --require-clean
```

## Files in this packet
- `run-candidate.json` — normalized run candidate (provenance + contract + checks)
- `freshness.json` — branch state + fix-still-required probes
- `readiness.json` — remediation readiness verdict
- `lane-plan.json` — Codex / agy / orchestrator lane assignment
- `marathon-invocation.txt` — the invocation hint above


---

▶ TAKE YOUR TURN (codex — BUILDER role)

You are the BUILDER for this phase. Read the phase brief above and implement it.
1. Implement the brief by creating/editing the artifact file(s): .claude/loose-ends-sequence.md
2. Append a build block to this relay file: `### Round N · Builder · codex` summarizing what you did (files touched, key decisions).
3. Use this exact tick binary (run it from any directory): /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick
   - /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick claim MARATHON-GH273-PHASE2-TURN --agent codex --paths "phases/gh273-phase2/RELAY.md,.claude/loose-ends-sequence.md"
   - /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick ping MARATHON-GH273-PHASE2-TURN --agent codex
   - /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick release MARATHON-GH273-PHASE2-TURN --agent codex --to agy
4. Edit ONLY these paths: phases/gh273-phase2/RELAY.md and .claude/loose-ends-sequence.md. Do NOT run git. Do NOT touch any other file — the harness commits for you.

### Round 1 · Builder · codex

- Created `.claude/loose-ends-sequence.md` with the required project-local `### *` matcher and
  direct bullets for the PDDA sweep, conditional ROADMAP dashboard regeneration, and
  VERIFIED-COMPLETE-only project-document archival.
- Key decision: used `../` for repository-relative utility and project paths because the
  `loose-ends` contract resolves relative paths from the manifest's `.claude/` directory.
- File-specific verification passed: the manifest has one matcher plus exactly three bullets, both
  resolved utility scripts are executable, and both resolved project lifecycle directories exist.
  Per the scope lock, the full project gate was not run.

---

▶ TAKE YOUR TURN (agy — REVIEWER role)

You are the REVIEWER for this phase. Read the latest builder block above AND review the artifact file(s) on disk: .claude/loose-ends-sequence.md.
1. Append a review block: `### Round N · Reviewer · agy` followed by your assessment.
2. If changes needed: add `**Verdict:** Changes requested` then: /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick release MARATHON-GH273-PHASE2-TURN --agent agy --to codex
3. If satisfied: add `**Verdict:** Approved`, set `STATUS: Approved`, then: /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick done MARATHON-GH273-PHASE2-TURN --agent agy
4. Use this exact tick binary (run it from any directory) for all token operations: /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick
   Edit ONLY phases/gh273-phase2/RELAY.md (your review block + STATUS). Do NOT edit the artifact yourself — request changes instead. Do NOT run git.

### Round 1 · Reviewer · agy

**Verdict:** Changes requested

The artifact `.claude/loose-ends-sequence.md` contains prose in the command bullets, which violates the explicit acceptance criteria: "no prose the parser would misread as a command". 

The lines:
`- If ROADMAP.md changed, run ../utils/roadmap-dashboard.sh to regenerate ROADMAP-DASHBOARD.md.`
`- Move documents from ../PROJECT/2-WORKING to ../PROJECT/3-COMPLETED only when marathon-cleanup classifies them VERIFIED-COMPLETE; never archive from a bare status-word change.`
are prose, not literal shell commands. This will break the `loose-ends` command runner. 

Please replace these with valid bash commands (e.g. using `echo` for the reminders, or actual scripts).

### Round 2 · Builder · codex

- Replaced both prose bullets in `.claude/loose-ends-sequence.md` with literal shell commands: the
  idempotent ROADMAP dashboard renderer and an `echo` command carrying the archive-safety reminder.
- Key decision: run the dashboard renderer unconditionally; this is safe and ensures the generated
  artifact is refreshed whenever `ROADMAP.md` changed without embedding fragile change detection in
  the manifest.
- File-specific verification passed: the manifest retains one `### *` matcher and exactly three
  bullets, every bullet parses as Bash, and both referenced repository scripts are executable. Per
  the scope lock, the full project gate was not run.
