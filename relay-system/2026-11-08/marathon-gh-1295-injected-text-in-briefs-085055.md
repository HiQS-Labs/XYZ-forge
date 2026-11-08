# Marathon Phase gh-1295-injected-text-in-briefs
STATUS: Open
NEXT: agy (Builder)

<!-- marathon-drive: task=MARATHON-GH-1295-INJECTED-TEXT-IN-BRIEFS-TURN builder=agy reviewer=codex round-cap=5 -->

## Phase Brief

# Marathon preflight packet — gh-1295-injected-text-in-briefs

- Generated: 2026-11-08T08:35:35Z
- Mode: gh-bundle
- Sources: /private/var/folders/55/4ncr895946v1jymn1561yy340000gn/T/gh1358-live-deployment-dr61f_tg/runner/PROJECT/2-WORKING/GH-1295-INJECTED-TEXT-IN-BRIEFS.md 
- Target root: /private/var/folders/55/4ncr895946v1jymn1561yy340000gn/T/gh1358-live-deployment-dr61f_tg/runner (development @ 153163bd0)
- Suggested branch: `marathon/gh-1295-injected-text-in-briefs-2026-11-08` (branch_ready=false — carve-out: risk=1/independent zone, proceed on the current branch without asking)
- Verdict: ready
- Source issue state: OPEN.
- Gate: `python3 -m pytest test/test_python_layer.py && bash test/synthetic/gh94-containment-invariants.sh`

- Artifacts: utils/py/harness.py,test/gh174-harness-registry.sh
- Suggested turn budget: `turn_timeout_s: 1800` in this phase's MARATHON.yaml entry (≈ 1902 LOC across 2 artifact(s) — over the 900s default, so it needs headroom). marathon.sh reads that field and applies it to the phase; the value is a starting point, not a measurement.
- Auto-included covering tests/helpers: test/gh174-harness-registry.sh

This packet is the producer's output. The orchestrator launches the run; the planner does not
(GUIDING-PRINCIPLES.md §8).

## Acceptance criteria — the build is DONE when these hold
*Inlined verbatim from `/private/var/folders/55/4ncr895946v1jymn1561yy340000gn/T/gh1358-live-deployment-dr61f_tg/runner/PROJECT/2-WORKING/GH-1295-INJECTED-TEXT-IN-BRIEFS.md` (6 checkbox(es) found across the WHOLE document — the doc has no `## Acceptance` section, so this list may include phase checklists). Continuation lines included; if a
criterion here reads as a fragment, that is the source text, not a truncation.*
*NOT verified, and NOT verifiable as things stand — issue #1295 has no '## Acceptance' section — nothing to copy from. This list exists only in the capture doc; reading the issue will not confirm it, because the issue states no criteria. Establish the criteria on the issue before treating anything below as the definition of done.*
- [ ] Inspect `_sections` and `render_brief` in `utils/py/harness.py`.
- [ ] Evaluate fencing options: wrap sourced scope in explicit Markdown code fence or quote block with untrusted data disclaimer.
- [ ] Evaluate pattern filter for common override strings (`IGNORE ALL PREVIOUS INSTRUCTIONS`, `SYSTEM OVERRIDE`).
- [ ] Sourced issue body instructions cannot be read as instructions by builder prompts in generated briefs.
- [ ] Normal issue bodies render unchanged without regression.
- [ ] No new test files (GH-831).
  "target": { "repo": ".", "ref": "development" },
  "gate": "python3 -m pytest test/test_python_layer.py && bash test/synthetic/gh94-containment-invariants.sh",
  "fix_probes": [
    { "type": "grep_absent", "path": "utils/py/harness.py", "pattern": "untrusted_issue_text|sanitize_brief_scope",
      "note": "pre-fix: harness.py does not fence untrusted scope text in briefs" }
  ],
  "artifacts": [ "utils/py/harness.py" ],
  "remediation": {
    "source": "issue#1295",
    "criteria": "Render sourced issue scope inside explicit untrusted fences or hold brief when instruction patterns match; no new tests (GH-831)."
  }

## Scope lock — builder, do exactly this and nothing else
- Edit ONLY: `utils/py/harness.py,test/gh174-harness-registry.sh` (plus the relay file). Any other edit is reverted and FAILS the turn.
- Do NOT run ANY test or gate yourself — not `python3 -m pytest test/test_python_layer.py && bash test/synthetic/gh94-containment-invariants.sh`, and NOT `test/gh174-harness-registry.sh` either. Those tests create temporary git fixtures/files inside your isolated worktree, which containment treats as off-lane edits and can discard your whole turn. Read them as specs instead; the harness runs the real gate after your turn, outside the worktree.
- Do NOT analyze the roadmap, file issues, or refactor adjacent code. Implement the acceptance criteria above — nothing more.

## Suggested marathon-drive.sh invocation

```bash
XYZ_HARNESS_CONTEXT=swarm XYZ_SESSION_ID=gh-1295-injected-text-in-briefs RELAY_WORKTREE_ISOLATION=1 relay-automation/marathon-drive.sh \
  --phase-brief <packet>/packet.md \
  --reviewer agy \
  --builder codex \
  --artifact utils/py/harness.py,test/gh174-harness-registry.sh \
  --pre-advance-cmd 'python3 -m pytest test/test_python_layer.py && bash test/synthetic/gh94-containment-invariants.sh' \
  --require-clean
```

## Files in this packet
- `run-candidate.json` — normalized run candidate (provenance + contract + checks)
- `freshness.json` — branch state + fix-still-required probes
- `readiness.json` — remediation readiness verdict
- `lane-plan.json` — Codex / agy / orchestrator lane assignment
- `marathon-invocation.txt` — the invocation hint above
- `marathon-invocation.json` — the same invocation as structured data (`swarm-preflight/marathon-invocation@1`, GH-280); supervisors consume this, never the shell text


---

▶ TAKE YOUR TURN (agy — BUILDER role)

You are the BUILDER for this phase. Read the phase brief above and implement it.
APPEND-ONLY FILE (GH-529 attestation): add your block at the END and never delete, reorder, or rewrite any existing content — the terminal attestation refuses the approval if any byte above your block changed, even a tidy-up.
1. Implement the brief by creating/editing the artifact file(s): utils/py/harness.py,test/gh174-harness-registry.sh
2. Append a build block to this relay file: `### Round N · Builder · agy` summarizing what you did (files touched, key decisions).
3. Use this exact tick binary (run it from any directory): /private/var/folders/55/4ncr895946v1jymn1561yy340000gn/T/gh1358-live-deployment-dr61f_tg/runner/bin/tick
   - /private/var/folders/55/4ncr895946v1jymn1561yy340000gn/T/gh1358-live-deployment-dr61f_tg/runner/bin/tick claim MARATHON-GH-1295-INJECTED-TEXT-IN-BRIEFS-TURN --agent agy --paths "marathon-system/gh-1295-injected-text-in-briefs/RELAY.md,utils/py/harness.py,test/gh174-harness-registry.sh"
   - /private/var/folders/55/4ncr895946v1jymn1561yy340000gn/T/gh1358-live-deployment-dr61f_tg/runner/bin/tick ping MARATHON-GH-1295-INJECTED-TEXT-IN-BRIEFS-TURN --agent agy
   - /private/var/folders/55/4ncr895946v1jymn1561yy340000gn/T/gh1358-live-deployment-dr61f_tg/runner/bin/tick release MARATHON-GH-1295-INJECTED-TEXT-IN-BRIEFS-TURN --agent agy --to codex
4. Edit ONLY these paths: marathon-system/gh-1295-injected-text-in-briefs/RELAY.md and utils/py/harness.py,test/gh174-harness-registry.sh. Do NOT run git. Do NOT touch any other file — the harness commits for you.
5. HAND OFF EXPLICITLY (GH-268): after releasing the token, end your turn by naming who acts next —
   "handing off to codex — codex, take your turn." A turn that ends without that line
   leaves a human guessing whether the relay is waiting on them or has stalled. Do this EVERY round,
   not just the first. ALSO, you MUST update the `NEXT:` line at the top of this file to exactly: `NEXT: codex (Reviewer)`

---

▶ TAKE YOUR TURN (codex — REVIEWER role)

You are the REVIEWER for this phase. Read the latest builder block above AND review the artifact file(s) on disk: utils/py/harness.py,test/gh174-harness-registry.sh. REVIEW THE WHOLE FILE, NOT JUST THE DIFF (GH-268): a beta test had this loop reach 'Approved' in two rounds while an independent audit of the same branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN SCOPE; say so explicitly if you find none. DECLARE IT: your review block MUST contain a literal 'swept file: yes' or 'swept file: no' line — without it a reviewer that skipped the sweep is indistinguishable in the transcript from one that did it and found nothing, which is exactly how those 20 issues stayed invisible.
APPEND-ONLY FILE (GH-529 attestation): add your block at the END and never delete, reorder, or rewrite any existing content — the terminal attestation refuses the approval if any byte above your block changed, even a tidy-up.
1. Append a review block: `### Round N · Reviewer · codex` followed by your assessment.
2. If changes needed: add `**Verdict:** Changes requested`, update the `NEXT:` line to exactly `NEXT: agy (Builder)`, then: /private/var/folders/55/4ncr895946v1jymn1561yy340000gn/T/gh1358-live-deployment-dr61f_tg/runner/bin/tick release MARATHON-GH-1295-INJECTED-TEXT-IN-BRIEFS-TURN --agent codex --to agy
3. If satisfied: add `**Verdict:** Approved`, set `STATUS: Approved`, then: /private/var/folders/55/4ncr895946v1jymn1561yy340000gn/T/gh1358-live-deployment-dr61f_tg/runner/bin/tick done MARATHON-GH-1295-INJECTED-TEXT-IN-BRIEFS-TURN --agent codex
4. Use this exact tick binary (run it from any directory) for all token operations: /private/var/folders/55/4ncr895946v1jymn1561yy340000gn/T/gh1358-live-deployment-dr61f_tg/runner/bin/tick
   Edit ONLY marathon-system/gh-1295-injected-text-in-briefs/RELAY.md (your review block + STATUS). Do NOT edit the artifact yourself — request changes instead. Do NOT run git.
4b. TO VERIFY A FINDING, WRITE PROBE FILES OUTSIDE THE REPO — under $TMPDIR, never inside the
   working tree. Creating even one scratch file in the repo is an off-lane write: containment
   reverts it and FAILS YOUR WHOLE TURN, discarding the review you just did (GH-441). Observed
   2026-08-08: a reviewer found a real latent crash, wrote two probe files in-tree to demonstrate
   it, and lost the turn for doing so — the finding survived only because RELAY.md happens to be
   on your allowlist. `cp` what you need to "$TMPDIR/probe.$$/" and work there instead. Verifying
   is wanted; verifying in-tree is what costs you the turn.
4c. A finding that asks for a behaviour change is a generalization unless you can paste the concrete
   input — a row, a value, a `file:line` — that fails under the current code (GH-681). Every
   `[Blocker]` or `[Should]` requesting a behaviour change MUST carry `Observed input:`,
   `Affected scope:` and `Falsifier:` lines; a `[Blocker]` must cite an observed failure. The Builder
   may disposition a request lacking these as `Declined — unproven generalization`.
5. HAND OFF EXPLICITLY (GH-268): end your turn by naming who acts next — "handing off to agy —
   agy, take your turn" when requesting changes, or "relay closed, no further turn needed" when
   approving. The beta report singled this out: the Reviewer turn did not tell the user to go back to the
   Producer, so the relay looked stalled when it was simply waiting. Do this EVERY round.
