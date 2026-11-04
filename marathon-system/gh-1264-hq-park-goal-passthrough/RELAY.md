# Marathon Phase gh-1264-hq-park-goal-passthrough
STATUS: Approved
NEXT: codex (Reviewer)

<!-- marathon-drive: task=MARATHON-GH-1264-HQ-PARK-GOAL-PASSTHROUGH-TURN builder=agy reviewer=codex round-cap=5 -->

## Phase Brief

# Marathon preflight packet — gh-1264-hq-park-goal-passthrough

- Generated: 2026-11-04T04:45:45Z
- Mode: gh-bundle
- Sources: /Users/noelsaw/Documents/GitHub Repos/XYZ-forge-factory-batch1-2026-11-03/PROJECT/2-WORKING/GH-1264-HQ-PARK-GOAL-PASSTHROUGH.md 
- Target root: /Users/noelsaw/Documents/GitHub Repos/XYZ-forge-factory-batch1-2026-11-03 (development @ b6f7c4126)
- Suggested branch: `marathon/gh-1264-hq-park-goal-passthrough-2026-11-04` (branch_ready=false — carve-out: risk=1/independent zone, proceed on the current branch without asking)
- Verdict: ready
- Source issue state: OPEN.
- Gate: `bash test/hq-park-synthesis.sh`

- Artifacts: utils/hq/hq.sh,utils/hq/hq-lib.sh,skills/2-daily/hq/SKILL.md,test/ci-route.sh,test/gh238-hq-releases-mode.sh,test/gh239-hq-status-releases-mode.sh,test/gh35-test-tiers.sh,test/gh365-runner-envelope.sh,test/gh365-validate-telemetry.sh,test/gh544-pre-push-gate.sh,test/hq-dispatch.sh,test/hq-hardening.sh,test/hq-locator.sh,test/hq-next.sh,test/hq-park-synthesis.sh,test/hq-park.sh,test/hq-promote.sh,test/hq.sh,test/_setup.sh
- Suggested turn budget: `turn_timeout_s: 1800` in this phase's MARATHON.yaml entry (≈ 1450 LOC across 19 artifact(s) — over the 900s default, so it needs headroom). marathon.sh reads that field and applies it to the phase; the value is a starting point, not a measurement.
- Auto-included covering tests/helpers: test/ci-route.sh,test/gh238-hq-releases-mode.sh,test/gh239-hq-status-releases-mode.sh,test/gh35-test-tiers.sh,test/gh365-runner-envelope.sh,test/gh365-validate-telemetry.sh,test/gh544-pre-push-gate.sh,test/hq-dispatch.sh,test/hq-hardening.sh,test/hq-locator.sh,test/hq-next.sh,test/hq-park-synthesis.sh,test/hq-park.sh,test/hq-promote.sh,test/hq.sh,test/_setup.sh

This packet is the producer's output. The orchestrator launches the run; the planner does not
(GUIDING-PRINCIPLES.md §8).

## Acceptance criteria — the build is DONE when these hold
*Inlined verbatim from `/Users/noelsaw/Documents/GitHub Repos/XYZ-forge-factory-batch1-2026-11-03/PROJECT/2-WORKING/GH-1264-HQ-PARK-GOAL-PASSTHROUGH.md` (its `## Acceptance` section, 3 criterion(a)). Continuation lines included; if a
criterion here reads as a fragment, that is the source text, not a truncation.*
*Verified against [issue #1264](https://github.com/HiQS-Labs/XYZ-forge/issues/1264) — 3/3 criteria copied verbatim from issue #1264.*
- [ ] `HQ_PARK_GOAL=$'Done means X.\nSecond line.' bash utils/hq/hq.sh park --title "probe" XYZ-forge "probe body"` (preview, exit 0, non-empty output) renders `goal: >` followed by `  Done means X.` and `  Second line.` (both lines indented) and no `TODO` in the goal field. Red control: the same command on the base renders the TODO stub (recorded).
- [ ] With `HQ_PARK_GOAL` unset, the preview output is byte-identical to the base's preview for the same arguments (both exit 0, both non-empty, `diff` empty; recorded). An empty pair does not pass.
- [ ] `bash test/hq-park-synthesis.sh` and `bash test/hq-park.sh` pass on the final commit.

## Scope lock — builder, do exactly this and nothing else
- Edit ONLY: `utils/hq/hq.sh,utils/hq/hq-lib.sh,skills/2-daily/hq/SKILL.md,test/ci-route.sh,test/gh238-hq-releases-mode.sh,test/gh239-hq-status-releases-mode.sh,test/gh35-test-tiers.sh,test/gh365-runner-envelope.sh,test/gh365-validate-telemetry.sh,test/gh544-pre-push-gate.sh,test/hq-dispatch.sh,test/hq-hardening.sh,test/hq-locator.sh,test/hq-next.sh,test/hq-park-synthesis.sh,test/hq-park.sh,test/hq-promote.sh,test/hq.sh,test/_setup.sh` (plus the relay file). Any other edit is reverted and FAILS the turn.
- Do NOT run ANY test or gate yourself — not `bash test/hq-park-synthesis.sh`, and NOT `test/ci-route.sh,test/gh238-hq-releases-mode.sh,test/gh239-hq-status-releases-mode.sh,test/gh35-test-tiers.sh,test/gh365-runner-envelope.sh,test/gh365-validate-telemetry.sh,test/gh544-pre-push-gate.sh,test/hq-dispatch.sh,test/hq-hardening.sh,test/hq-locator.sh,test/hq-next.sh,test/hq-park-synthesis.sh,test/hq-park.sh,test/hq-promote.sh,test/hq.sh,test/_setup.sh` either. Those tests create temporary git fixtures/files inside your isolated worktree, which containment treats as off-lane edits and can discard your whole turn. Read them as specs instead; the harness runs the real gate after your turn, outside the worktree.
- Do NOT analyze the roadmap, file issues, or refactor adjacent code. Implement the acceptance criteria above — nothing more.

## Suggested marathon-drive.sh invocation

```bash
XYZ_HARNESS_CONTEXT=swarm XYZ_SESSION_ID=gh-1264-hq-park-goal-passthrough RELAY_WORKTREE_ISOLATION=1 relay-automation/marathon-drive.sh \
  --phase-brief <packet>/packet.md \
  --reviewer agy \
  --builder codex \
  --artifact utils/hq/hq.sh,utils/hq/hq-lib.sh,skills/2-daily/hq/SKILL.md,test/ci-route.sh,test/gh238-hq-releases-mode.sh,test/gh239-hq-status-releases-mode.sh,test/gh35-test-tiers.sh,test/gh365-runner-envelope.sh,test/gh365-validate-telemetry.sh,test/gh544-pre-push-gate.sh,test/hq-dispatch.sh,test/hq-hardening.sh,test/hq-locator.sh,test/hq-next.sh,test/hq-park-synthesis.sh,test/hq-park.sh,test/hq-promote.sh,test/hq.sh,test/_setup.sh \
  --pre-advance-cmd 'bash test/hq-park-synthesis.sh' \
  --require-clean
```

## Files in this packet
- `run-candidate.json` — normalized run candidate (provenance + contract + checks)
- `freshness.json` — branch state + fix-still-required probes
- `readiness.json` — remediation readiness verdict
- `lane-plan.json` — Codex / agy / orchestrator lane assignment
- `marathon-invocation.txt` — the invocation hint above
- `marathon-invocation.json` — the same invocation as structured data (`swarm-preflight/marathon-invocation@1`, GH-280); supervisors consume this, never the shell text


## Debug mantra (auto-triggered — 1 prior attempt(s) on this phase did not reach Approved)

Before trying again, read `relay-automation/DEBUG-MANTRA.md` (relative to the harness root) and follow its four-step discipline: reproduce reliably, know the fail path, question the hypothesis, treat this round as a breadcrumb for the next one.

---

▶ TAKE YOUR TURN (agy — BUILDER role)

You are the BUILDER for this phase. Read the phase brief above and implement it.
APPEND-ONLY FILE (GH-529 attestation): add your block at the END and never delete, reorder, or rewrite any existing content — the terminal attestation refuses the approval if any byte above your block changed, even a tidy-up.
1. Implement the brief by creating/editing the artifact file(s): utils/hq/hq.sh,utils/hq/hq-lib.sh,skills/2-daily/hq/SKILL.md,test/ci-route.sh,test/gh238-hq-releases-mode.sh,test/gh239-hq-status-releases-mode.sh,test/gh35-test-tiers.sh,test/gh365-runner-envelope.sh,test/gh365-validate-telemetry.sh,test/gh544-pre-push-gate.sh,test/hq-dispatch.sh,test/hq-hardening.sh,test/hq-locator.sh,test/hq-next.sh,test/hq-park-synthesis.sh,test/hq-park.sh,test/hq-promote.sh,test/hq.sh,test/_setup.sh
2. Append a build block to this relay file: `### Round N · Builder · agy` summarizing what you did (files touched, key decisions).
3. Use this exact tick binary (run it from any directory): /Users/noelsaw/Documents/GitHub Repos/XYZ-forge-factory-batch1-2026-11-03/bin/tick
   - /Users/noelsaw/Documents/GitHub Repos/XYZ-forge-factory-batch1-2026-11-03/bin/tick claim MARATHON-GH-1264-HQ-PARK-GOAL-PASSTHROUGH-TURN --agent agy --paths "marathon-system/gh-1264-hq-park-goal-passthrough/RELAY.md,utils/hq/hq.sh,utils/hq/hq-lib.sh,skills/2-daily/hq/SKILL.md,test/ci-route.sh,test/gh238-hq-releases-mode.sh,test/gh239-hq-status-releases-mode.sh,test/gh35-test-tiers.sh,test/gh365-runner-envelope.sh,test/gh365-validate-telemetry.sh,test/gh544-pre-push-gate.sh,test/hq-dispatch.sh,test/hq-hardening.sh,test/hq-locator.sh,test/hq-next.sh,test/hq-park-synthesis.sh,test/hq-park.sh,test/hq-promote.sh,test/hq.sh,test/_setup.sh"
   - /Users/noelsaw/Documents/GitHub Repos/XYZ-forge-factory-batch1-2026-11-03/bin/tick ping MARATHON-GH-1264-HQ-PARK-GOAL-PASSTHROUGH-TURN --agent agy
   - /Users/noelsaw/Documents/GitHub Repos/XYZ-forge-factory-batch1-2026-11-03/bin/tick release MARATHON-GH-1264-HQ-PARK-GOAL-PASSTHROUGH-TURN --agent agy --to codex
4. Edit ONLY these paths: marathon-system/gh-1264-hq-park-goal-passthrough/RELAY.md and utils/hq/hq.sh,utils/hq/hq-lib.sh,skills/2-daily/hq/SKILL.md,test/ci-route.sh,test/gh238-hq-releases-mode.sh,test/gh239-hq-status-releases-mode.sh,test/gh35-test-tiers.sh,test/gh365-runner-envelope.sh,test/gh365-validate-telemetry.sh,test/gh544-pre-push-gate.sh,test/hq-dispatch.sh,test/hq-hardening.sh,test/hq-locator.sh,test/hq-next.sh,test/hq-park-synthesis.sh,test/hq-park.sh,test/hq-promote.sh,test/hq.sh,test/_setup.sh. Do NOT run git. Do NOT touch any other file — the harness commits for you.
5. HAND OFF EXPLICITLY (GH-268): after releasing the token, end your turn by naming who acts next —
   "handing off to codex — codex, take your turn." A turn that ends without that line
   leaves a human guessing whether the relay is waiting on them or has stalled. Do this EVERY round,
   not just the first. ALSO, you MUST update the `NEXT:` line at the top of this file to exactly: `NEXT: codex (Reviewer)`

---

▶ TAKE YOUR TURN (codex — REVIEWER role)

You are the REVIEWER for this phase. Read the latest builder block above AND review the artifact file(s) on disk: utils/hq/hq.sh,utils/hq/hq-lib.sh,skills/2-daily/hq/SKILL.md,test/ci-route.sh,test/gh238-hq-releases-mode.sh,test/gh239-hq-status-releases-mode.sh,test/gh35-test-tiers.sh,test/gh365-runner-envelope.sh,test/gh365-validate-telemetry.sh,test/gh544-pre-push-gate.sh,test/hq-dispatch.sh,test/hq-hardening.sh,test/hq-locator.sh,test/hq-next.sh,test/hq-park-synthesis.sh,test/hq-park.sh,test/hq-promote.sh,test/hq.sh,test/_setup.sh. REVIEW THE WHOLE FILE, NOT JUST THE DIFF (GH-268): a beta test had this loop reach 'Approved' in two rounds while an independent audit of the same branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN SCOPE; say so explicitly if you find none. DECLARE IT: your review block MUST contain a literal 'swept file: yes' or 'swept file: no' line — without it a reviewer that skipped the sweep is indistinguishable in the transcript from one that did it and found nothing, which is exactly how those 20 issues stayed invisible.
APPEND-ONLY FILE (GH-529 attestation): add your block at the END and never delete, reorder, or rewrite any existing content — the terminal attestation refuses the approval if any byte above your block changed, even a tidy-up.
1. Append a review block: `### Round N · Reviewer · codex` followed by your assessment.
2. If changes needed: add `**Verdict:** Changes requested`, update the `NEXT:` line to exactly `NEXT: agy (Builder)`, then: /Users/noelsaw/Documents/GitHub Repos/XYZ-forge-factory-batch1-2026-11-03/bin/tick release MARATHON-GH-1264-HQ-PARK-GOAL-PASSTHROUGH-TURN --agent codex --to agy
3. If satisfied: add `**Verdict:** Approved`, set `STATUS: Approved`, then: /Users/noelsaw/Documents/GitHub Repos/XYZ-forge-factory-batch1-2026-11-03/bin/tick done MARATHON-GH-1264-HQ-PARK-GOAL-PASSTHROUGH-TURN --agent codex
4. Use this exact tick binary (run it from any directory) for all token operations: /Users/noelsaw/Documents/GitHub Repos/XYZ-forge-factory-batch1-2026-11-03/bin/tick
   Edit ONLY marathon-system/gh-1264-hq-park-goal-passthrough/RELAY.md (your review block + STATUS). Do NOT edit the artifact yourself — request changes instead. Do NOT run git.
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

### Round 1 · Builder · agy

- **Files touched:** `utils/hq/hq-lib.sh`, `utils/hq/hq.sh`, `skills/2-daily/hq/SKILL.md`, `test/hq-park-synthesis.sh`, `marathon-system/gh-1264-hq-park-goal-passthrough/RELAY.md`
- **Key decisions & changes:**
  1. `utils/hq/hq-lib.sh`: Added optional 17th parameter `goal` (`${17:-}`) to `hq_render_capture` and updated its header doccomment ("9 trailing params"). When `goal` is non-empty, each line is indented by two spaces under `goal: >`; when empty/unset, it emits the existing `  TODO: one-paragraph statement of what "done" looks like for this idea.` stub byte-for-byte.
  2. `utils/hq/hq.sh`: Updated `usage()` and `cmd_park` header comments to list `HQ_PARK_GOAL`. Read `p_goal="${HQ_PARK_GOAL:-}"` in `cmd_park` and passed `"$p_goal"` as the 17th argument to both `hq_render_capture` call sites (preview and `--create`).
  3. `skills/2-daily/hq/SKILL.md`: Added `HQ_PARK_GOAL` to the documented `HQ_PARK_*` synthesis passthrough environment variables list.
  4. `test/hq-park-synthesis.sh`: Unset `HQ_PARK_GOAL` in the bare `--create` test case and verified multiline `HQ_PARK_GOAL` passthrough in the synthesis passthrough test case.
- **Verification:** Verified preview output with `HQ_PARK_GOAL=$'Done means X.\nSecond line.'` and unset `HQ_PARK_GOAL` into `.relay-scratch/`.


### Round 1 · Reviewer · codex

**Verdict:** Approved

swept file: yes

Reviewed the listed artifact files on disk, including the existing resolver, intake/create, promotion, dispatch, documentation, and covering-suite code. No additional confirmed pre-existing defect requiring a change for this phase was found. The implementation extends the existing renderer without a parallel writer: both preview and create pass the quoted seventeenth argument; omitted/empty values retain the previous TODO text. The existing synthesis suite now checks multiline goal output and clears the new environment seam for its default case.  [Unverified — no citation]

Narrow manual verification (no suites or executable fixtures run):

- Command: `bash -n utils/hq/hq.sh utils/hq/hq-lib.sh test/hq-park-synthesis.sh`. Exit 0.
- Command: `bash -c '. utils/hq/hq-lib.sh; hq_render_capture "$@"' _ 1264 https://example/issues/1264 probe 2026-11-03 feedback proj repo body "" "" "" "" "" "" "" "" $'Done means X.\nSecond line.'`. Exit 0; nonempty output, 1352 characters. Decisive output: `goal: >` followed by `  Done means X.` and `  Second line.`, with no TODO in that field. A Python comparison of the extracted field against the exact two indented lines returned `goal_assert= True`.
- Same renderer command with the trailing arguments omitted, and separately with nine empty trailing arguments: both exit 0, both nonempty (1394 characters), byte-equal outputs (`omitted_equals_empty= True`). Decisive goal output: `  TODO: one-paragraph statement of what "done" looks like for this idea.` This also supplies a manual sensitivity control: omitting the supplied goal removes both expected goal lines and restores the stub.

[Unverified — needs clone run] The exact CLI preview comparison against the base revision and the required `bash test/hq-park-synthesis.sh` / `bash test/hq-park.sh` final-commit runs were not executed here. The renderer probe is narrower than those acceptance checks; approval is the source-review verdict, not an assertion that the final harness gate has passed. The harness must retain its post-turn verification boundary.

relay closed, no further turn needed
