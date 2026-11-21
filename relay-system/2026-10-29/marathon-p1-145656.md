# Marathon Phase p1
STATUS: Approved
NEXT: codex (Reviewer)

<!-- marathon-drive: task=MARATHON-P1-TURN builder=agy reviewer=codex round-cap=5 -->

## Phase Brief

---
gh_issue: 1233
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1233
title: "jog recovery after a driver crash: guidance for leftovers before retry-build"
status: Active
created: 2026-10-27
updated: 2026-10-29
owner: noelsaw1
doc_type: bugfix
complexity: 1
risk: 1
effort: 1
phases: 1
goal: "An operator recovering a crashed Jog item knows which leftovers exist, how to confirm each is safe to clear, and that retry-build goes into a fresh clone."
non_goals:
  - Code changes to jog resume, retry-build or _execution_root (doc-first; code only if the doc proves insufficient, per the issue).
related:
  - "Marathon umbrella #1250 (lane L1)"
  - "GH-1175 Phase 0 evidence: TESTS-RESULTS/2026-10-25+GH-1175-phase0/step3-*"
---

# GH-1233: jog crash recovery — guidance for leftovers before `retry-build`

## Status

| What was just completed | What's next |
|---|---|
| Promoted for marathon #1250 (lane L1) with plan, acceptance and contract | Codex plan QA, then build |

## Observed (GH-1175 Phase 0, 2026-10-26)

After a SIGKILL of the jog/marathon tree and a correct cold-start park, the target clone still held:
- a local `marathon/gh-416-…` branch with a render commit;
- the `rtl-wt.*` isolation worktree;
- the tick token `MARATHON-…-TURN`, still `claimed` by agy;
- `.git/relay-driver.lock`, holding the dead pid.

`jog resume` says "use jog retry-gate / retry-build / land", but neither it nor `skills/2-daily/jog/SKILL.md` (Recovery Verbs, lines 178-189 at 93f41cb8) says whether retry-build may reuse that clone or how to clear the leftovers. The Phase 0 run recovered by hand: `git worktree remove --force`, then a fresh clone for retry-build (`step3-recovery-prep.log`, `step3-leftovers-after-kill.log`).

## Plan (one phase)
Edit `skills/2-daily/jog/SKILL.md` "Recovery Verbs" only. Add a "Crash leftovers" block after the three verbs:
1. **Name the four leftovers.** For each, separate "no process owns it" from "no unique work remains". Preserve on any uncertainty.
   - **Isolation worktree:** `git worktree list`, plus no live process holding the path (`lsof`). A worktree with no owner can still hold unpublished edits, so check `git -C <wt> status` before removing it.
   - **Claimed tick token:** `tick info <token>` names an agent, not a pid. Establish the owning execution from the driver lock and the Jog row's lease pid (`kill -0`). The token only clears once that execution is confirmed dead.
   - **Driver lock:** the pid in it is not alive (`kill -0`). The driver reclaims a stale lock itself on the next run.
   - **Unpushed local marathon branch:** this is evidence to **preserve**, never proof that removal is safe.
2. **Point to merge-cleanup's existing checks** before anything is cleared: dirty files, unpublished refs, dependent worktrees, live handles. Do not repeat them by hand.
3. **State the rule.** After a cold-start park, `retry-build` targets a **fresh disposable full clone**, never the crashed one. The crashed clone is retired through `/merge-cleanup`, which preserves an unpushed branch until the operator says it is disposable.
4. **Keep the order:** `resume` first (no token), then `retry-gate` (approved build, failed gate), then `retry-build` (real rebuild).

Write-set: `skills/2-daily/jog/SKILL.md`. Docs route (`utils/ci-route.sh` classifies `skills/*/SKILL.md` as docs, except merge-cleanup's).

## Acceptance

- [ ] `skills/2-daily/jog/SKILL.md` "Recovery Verbs" names each crash leftover (isolation worktree, claimed tick token, clone driver lock, unpushed local marathon branch) and how to confirm it is safe to clear.
- [ ] It states that after a cold-start park, `retry-build` targets a fresh disposable full clone and the crashed clone is retired through `/merge-cleanup`, never reused.
- [ ] `utils/pdda/pdda.sh run` is clean; no new tests (GH-831).

## Verification

Read the changed section from its consumer's entry point (the jog skill), and check it against the Phase 0 step-3 logs. Run `utils/pdda/pdda.sh run`. Rollback: revert the doc commit.

## Swarm Preflight Contract

```json
{
  "target": {"repo": ".", "ref": "development"},
  "gate": "bash utils/pdda/pdda.sh run",
  "fix_probes": [
    {"type": "grep_absent", "path": "skills/2-daily/jog/SKILL.md", "pattern": "Crash leftovers"}
  ],
  "artifacts": ["skills/2-daily/jog/SKILL.md"],
  "remediation": {"source": "issue#1233", "criteria": "Recovery Verbs gains a Crash leftovers block: four leftovers with safe-to-clear checks, and the fresh-clone rule for retry-build."},
  "lanes": {"agy_safe": ["skills/2-daily/jog/SKILL.md"], "orchestrator_only": []}
}
```


---

▶ TAKE YOUR TURN (agy — BUILDER role)

You are the BUILDER for this phase. Read the phase brief above and implement it.
APPEND-ONLY FILE (GH-529 attestation): add your block at the END and never delete, reorder, or rewrite any existing content — the terminal attestation refuses the approval if any byte above your block changed, even a tidy-up.
1. Implement the brief by creating/editing the artifact file(s): skills/2-daily/jog/SKILL.md
2. Append a build block to this relay file: `### Round N · Builder · agy` summarizing what you did (files touched, key decisions).
3. Use this exact tick binary (run it from any directory): /Users/noelsaw/marathon-clones/marathon-gh-1250-phase0-followups/bin/tick
   - /Users/noelsaw/marathon-clones/marathon-gh-1250-phase0-followups/bin/tick claim MARATHON-P1-TURN --agent agy --paths "marathon-system/gh1250-phase0-followups--p1/RELAY.md,skills/2-daily/jog/SKILL.md"
   - /Users/noelsaw/marathon-clones/marathon-gh-1250-phase0-followups/bin/tick ping MARATHON-P1-TURN --agent agy
   - /Users/noelsaw/marathon-clones/marathon-gh-1250-phase0-followups/bin/tick release MARATHON-P1-TURN --agent agy --to codex
4. Edit ONLY these paths: marathon-system/gh1250-phase0-followups--p1/RELAY.md and skills/2-daily/jog/SKILL.md. Do NOT run git. Do NOT touch any other file — the harness commits for you.
5. HAND OFF EXPLICITLY (GH-268): after releasing the token, end your turn by naming who acts next —
   "handing off to codex — codex, take your turn." A turn that ends without that line
   leaves a human guessing whether the relay is waiting on them or has stalled. Do this EVERY round,
   not just the first. ALSO, you MUST update the `NEXT:` line at the top of this file to exactly: `NEXT: codex (Reviewer)`

---

▶ TAKE YOUR TURN (codex — REVIEWER role)

You are the REVIEWER for this phase. Read the latest builder block above AND review the artifact file(s) on disk: skills/2-daily/jog/SKILL.md. REVIEW THE WHOLE FILE, NOT JUST THE DIFF (GH-268): a beta test had this loop reach 'Approved' in two rounds while an independent audit of the same branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN SCOPE; say so explicitly if you find none. DECLARE IT: your review block MUST contain a literal 'swept file: yes' or 'swept file: no' line — without it a reviewer that skipped the sweep is indistinguishable in the transcript from one that did it and found nothing, which is exactly how those 20 issues stayed invisible.
APPEND-ONLY FILE (GH-529 attestation): add your block at the END and never delete, reorder, or rewrite any existing content — the terminal attestation refuses the approval if any byte above your block changed, even a tidy-up.
1. Append a review block: `### Round N · Reviewer · codex` followed by your assessment.
2. If changes needed: add `**Verdict:** Changes requested`, update the `NEXT:` line to exactly `NEXT: agy (Builder)`, then: /Users/noelsaw/marathon-clones/marathon-gh-1250-phase0-followups/bin/tick release MARATHON-P1-TURN --agent codex --to agy
3. If satisfied: add `**Verdict:** Approved`, set `STATUS: Approved`, then: /Users/noelsaw/marathon-clones/marathon-gh-1250-phase0-followups/bin/tick done MARATHON-P1-TURN --agent codex
4. Use this exact tick binary (run it from any directory) for all token operations: /Users/noelsaw/marathon-clones/marathon-gh-1250-phase0-followups/bin/tick
   Edit ONLY marathon-system/gh1250-phase0-followups--p1/RELAY.md (your review block + STATUS). Do NOT edit the artifact yourself — request changes instead. Do NOT run git.
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

---

### Round 1 · Builder · agy

- **Files touched:** `skills/2-daily/jog/SKILL.md`, `marathon-system/gh1250-phase0-followups--p1/RELAY.md`
- **Key decisions & changes:**
  - Added the `### Crash leftovers` subsection under `## Recovery Verbs` in `skills/2-daily/jog/SKILL.md` (immediately after the three recovery verbs `jog resume`, `jog retry-gate`, and `jog retry-build`).
  - Reinforced the recovery verb order (`resume` first without spending a token, then `retry-gate` for approved builds with a failed gate, then `retry-build` for real rebuilds).
  - Named all four crash leftovers observed in GH-1175 Phase 0 (`TESTS-RESULTS/2026-10-25+GH-1175-phase0/step3-*`) and separated "no process owns it" from "no unique work remains" (preserving on any uncertainty):
    1. **Isolation worktree (`rtl-wt.*`):** `git worktree list`, no live process holding the path (`lsof`), and `git -C <wt> status` check before `git worktree remove`.
    2. **Claimed tick token (`MARATHON-…-TURN`):** `tick info <token>` names an agent, not a pid; confirm owning execution is dead via the driver lock and the Jog row's `lease_pid` (`kill -0`) before clearing.
    3. **Clone driver lock (`.git/relay-driver.lock`):** confirm the pid in it is not alive (`kill -0`); the driver reclaims a stale lock itself on the next run.
    4. **Unpushed local marathon branch (`marathon/gh-…`):** work evidence to preserve, never proof that removal is safe.
  - Directed operators to rely on `/merge-cleanup`'s existing safety checks (dirty files, unpublished refs, dependent worktrees, live handles) rather than repeating them by hand.
  - Stated the fresh-clone rule for `retry-build`: after a cold-start park, `jog retry-build --target-root <clone>` targets a fresh disposable full clone, never the crashed one, while the crashed clone is retired through `/merge-cleanup` (preserving any unpushed branch until the operator confirms it is disposable).
- **Verification:** Confirmed against `TESTS-RESULTS/2026-10-25+GH-1175-phase0/step3-leftovers-after-kill.log` and `step3-recovery-prep.log`, verified the `grep_absent` fix probe (`Crash leftovers` now present in `skills/2-daily/jog/SKILL.md`), and ran PDDA doc-hygiene checks.


### Round 1 · Reviewer · codex

**Verdict:** Approved

swept file: yes

Ship the documentation change. Read all of `skills/2-daily/jog/SKILL.md`, including its existing primary-writer, execution, publication and recovery instructions. No actionable pre-existing defect found in this review. The new section names all four observed leftovers, distinguishes process ownership from recoverable work, preserves uncertainty and unpublished branches, delegates disposal checks to `/merge-cleanup`, and explicitly requires a fresh disposable full clone after a cold-start park. This is a small, reversible documentation change; no runtime change or new test is needed.

Evidence inspected (read-only):
- Command: `cat TESTS-RESULTS/2026-10-25+GH-1175-phase0/step3-leftovers-after-kill.log TESTS-RESULTS/2026-10-25+GH-1175-phase0/step3-recovery-prep.log`. Both files were read successfully; decisive output names clone lock pid `32725`, branch `marathon/gh-416-doc-trues-up-batch-2026-10-25`, detached worktree `rtl-wt.6YDYAC`, token `status: claimed` / `claimer: agy`, and the replacement clone ending `phase0-r2`. The combined shell call subsequently exited 2 because a separate search named nonexistent `utils/py/relay_turn_lib.py`; no log read failed. Follow-up searches used the actual `utils/py/rtl.py` and exited 0.
- Command: `rg -n "unpublished|unpushed|live handles|lsof|worktree|PRESERVE" skills/2-daily/merge-cleanup/SKILL.md` (exit 0). Lines 207–227 explicitly cover pinned Tick claims, live handles, detached HEAD/local refs, dependent worktrees and failed safety queries. This supports the new block's delegation to existing checks rather than treating a clean status alone as disposal proof.
- Command: `sed -n '905,950p' utils/py/jog_run.py; sed -n '1245,1325p' utils/py/jog_run.py` (exit 0). Retry-build accepts the supplied target root, validates it and creates a new attempt; the supervisor reads `relay-driver.lock/pid`, probes liveness and reclaims a stale lock. The fresh-clone requirement is operator guidance, not a claim that runtime enforces clone novelty.

[Unverified — needs clone run] The required `utils/pdda/pdda.sh run` gate was not independently executed here. The builder reports running doc-hygiene checks but supplies no decisive output in its block. Gate verification remains with the post-turn harness; this approval attests the document review, not a passing gate. No git commands, suites or executable fixtures were run, and no artifact/source files were edited.

relay closed, no further turn needed

### Attestation · relay-drive — 2026-10-29T14:40:31Z
task: MARATHON-P1-TURN
reviewer: codex
status: Approved
reviewed-head: e45096a1b4bc6eb16ad018de76d6257612427cfa
added-range: 12161+2543
added-sha256: 852d2e896263a5853b202a502fe0fdd5d3010b4ebf5dc325271623c0f55d0c90
config-sha256: 75171e73d8bd6dcf8119f88528857922148b245a1e17f65c2f4cbd38486a03cf
