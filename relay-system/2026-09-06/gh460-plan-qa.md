# RELAY · Plan QA: GH-460 fuzz-campaign plan (PROJECT/2-WORKING/GH-460)
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-09-06.
-->

NEXT: Reviewer
STATUS: Open
ROUND: 1 / 4

## ▶ TAKE YOUR TURN — read this first (works for ANY agent: Claude, Codex, agy)
1. **Read this whole file** (header, Setup, Ground rules, every block in the Log).
2. **Check it's your turn:** `NEXT` (top) names the role to act. Confirm you are bound to it and the
   last Log block isn't already yours. If not → STOP and reply "wrong window — nudge the <other> window."
3. **Do your role's work** on the artifact named in Setup:
   - **Reviewer:** review vs the Definition of Done → graded findings
     (`[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`), each with a concrete fix → set a **Verdict**
     (Approved | Changes requested | Blocked). **Review the whole file, not just the diff** (GH-268):
     a beta test had this loop reach `Approved` in two rounds while an independent audit of the same
     branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the
     change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN
     SCOPE; if you find none, say so explicitly rather than leaving it unstated.
     **Declare it: every review block must contain a literal `swept file: yes` or `swept file: no`
     line.** Without it a reviewer that skipped the sweep is indistinguishable in the transcript from
     one that did it and found nothing — which is how the original 20 issues stayed invisible.
     Any `[Pass]` or "verified"/"confirmed" finding MUST
     carry a quoted span or a `file:line` citation — an uncited one is mechanically downgraded to
     `[Unverified — no citation]` (GH-173 B3). Do **not** edit the artifact; only append findings here.
   - **Producer:** log a disposition for every open finding (Implemented / Modified / Declined + why),
     make the change, then add new work.
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(gh460-plan-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: _<fill in the repo-relative path(s) the turn reviews>_
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-09-06
- Definition of Done: QA the GH-460 plan before implementation. Read the plan doc, the issue
  spec it implements (git log/msg + `gh` not available offline — the plan restates requirements),
  and the code it touches: `relay-automation/resolve-model-alias.sh`,
  `utils/py/model_alias.py`, `utils/py/fuzz_engine.py` (--mode fuzz/replay CLI), and
  `test/gh346-resolver-fallback.sh` for the existing contract tests. Answer with citations:

  1. Grounded: do the plan's file:line claims match this worktree?
  2. Missing requirements: is any work item under-specified to execute or review (esp. the
     invariant oracle in the --target string, the executed>=20 floor, and the red-control
     procedure — cp-backup edit, not git checkout)?
  3. Extends-not-forks: does anything in the plan grow a second matcher/engine/writer?
  4. Red controls: is item 2's mutation procedure sufficient to prove the smoke can fail?
     Is a mutated-resolver run safe in a task clone (no git-state writes)?
  5. Blast radius / rollback / ratings (60/40/50/70): grounded and proportionate?

  Graded findings ([Blocker]/[Should]/[Nit]/[Pass]) with citations; `swept file:` line. End the
  block with EXACTLY these two lines (the file validator enforces them literally):
  `VERDICT: PASS` or `VERDICT: FAIL` or `VERDICT: PARKED` (uppercase, line-start — these are the
  only accepted values), then `Basis: <one line on the decisive evidence>`. Do NOT edit the plan
  or any source file.


## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

## Reviewer · codex · round 1 · 2026-09-06

swept file: yes

Scope: read the entire GH-460 plan and all four source/test files named in Setup. Static review only; no resolver, campaign, mutation, test suite, or git command executed. MCP list_projects returned no index for this worktree or its GH-460 parent clone; exact local source reads are the fallback, with no graph-generation/completeness claim. The issue/comment and referenced primary-clone recon are not available here, so historical run/commit claims remain unverified.

- [Blocker] **Specify the actual oracle and command locally.** Plan `PROJECT/2-WORKING/GH-460-ATE-FUZZ-RESOLVER-CAMPAIGN.md:90` delegates the load-bearing target to “the #457 comment”; neither its code nor wrapper argument mapping is present. `utils/py/fuzz_engine.py:223` shell-splits the fixed command and inserts mutant argv, while `:244` discards target stdout. Fix: include the exact inline target, base argv, cwd, timeout, environment/table policy, corpus and telemetry paths, and JSON assertions. The oracle must capture resolver rc/stdout itself, map valid rc 0/1/2 outcomes to oracle success, enforce empty stdout on miss and nonempty output on success, and emit a diagnostic/nonzero result for violations. Define missing/multiple argv handling and wrapper empty-input policy; check passthrough against an independently observed miss, not a second matcher. Assert engine success AND a nonempty valid summary with `executed >= 20`, `counts.fail == 0`, `counts.anomaly == 0` (`fuzz_engine.py:339`, `:470`).
- [Blocker] **Register the standing smoke in the existing gate.** Plan `:90` adds a test file but `:103` assumes it is the only touched surface. `validate.sh:104` explicitly registers the existing resolver test; `ci-local.sh:246` and `:269` derive the qualifying suite from that TESTS list. Fix: add the new smoke to that registry and include registration in scope/rollback; otherwise a manually runnable test does not continuously guard R1. Run implementation-time gates only in a separate disposable full clone, per AGENTS.md.
- [Should] **Make the red control attributable and restoration unconditional.** Plan `:93`–`:95` says sed-inject on miss and expect any nonzero exit, but does not guarantee a seeded mutant reaches `resolve-model-alias.sh:128`; usage exits earlier at `:52`, and substring matches exit at `:121`. Fix: pin a witnessed miss in the same smoke input set, assert the replacement changes exactly the terminal miss exit, install cp-backup restoration before mutation (including failure/interruption), and require telemetry showing the oracle caught rc 3 for that input. A syntax error, timeout, or missing JSON must not qualify as the red witness. Fresh equivalent corpus/environment for baseline, red, and restored green is required: existing corpus seeds affect generation (`fuzz_engine.py:298`, `:122`). Resolver execution has no explicit git writes in its full 128-line body, but a `test/*.sh` run still belongs in a disposable full clone; the plan's task-clone blanket safety claim is insufficient.
- [Should] **Preserve replayable evidence before corpus eviction.** Plan `:75`–`:79`, `:96`–`:106` promises PR notes/temporary summaries but no committed evidence destination or exact campaign recipe. `fuzz_engine.py:185` replaces same-signature entries, `:190` evicts them, and `:187` can return no corpus id; replay `:454`–`:463` requires a surviving entry and reports reproduction, not a fixed regression. Fix: pin all three seeds and wrapper seed/base/300 executed floor; preserve exact argv, target, environment/table identity, summaries, telemetry, regression input, and replay commands in a committed evidence directory, including required provenance.jsonl for cited runs. Record red and restored-green evidence there. Do not depend on an ephemeral corpus id alone. Define regression success after the fix separately from replaying the recorded failure.
- [Should] **Correct unavailable/stale grounding and qualify scope.** Plan `:17`/`:56` points to a recon file absent in this worktree, and `:64` claims the tier-2 rewrite is fixed at HEAD without accessible evidence; the present resolver still executes squashed matching (`resolve-model-alias.sh:97`–`:104`). Fix: supply the recon in the reviewable artifact set or inline its essential evidence, identify the exact caller-level fix and evidence behind the historical claim, and avoid implying the matcher changed. The cited DeepSeek call is grounded at `utils/py/deepseek-turn.py:231`–`:233`; the review caller is at `utils/py/review_xyz.py:629`, but “no other lane” is not established by these two citations. Ratings 60/40/50/70 lack rationale; add a short explanation and an explicit Easy reversibility read for test-only work, with any discovered runtime fix separately scoped/rated before execution.
- [Nit] **Reconcile the Bash wording.** Plan `:85` says “no new Bash files” while `:90` creates one under test/. Fix: say no new production Bash/oracle executable; AGENTS.md's GH-551 rule exempts test/.
- [Pass] **The proposed reuse direction is sound.** `model_alias.py:48`–`:61` already centralizes subprocess fallback, and `fuzz_engine.py:278`–`:342` already supplies execution, classification, corpus and telemetry. Keep the oracle limited to contract assertions over those existing paths; no second normalizer, fuzz engine, or writer is needed. The executed floor in plan `:72`–`:73` is appropriate once parsed fail-closed as above.

Whole-file sweep also found a pre-existing limitation relevant to the oracle: the absolute “never raises” wording in `model_alias.py:17` exceeds its implementation for invalid root types, since `resolver_path(xyz_root)` is outside the try at `:44` (and `resolver_path` calls os.path.join at `:31`). Bound this campaign to string model inputs and a valid fixed harness root, or explicitly route a broader contract finding rather than silently fuzzing unrelated argument types. No other pre-existing defect is asserted by this static review; it is not runtime proof.

VERDICT: changes-requested
Basis: oracle specification, continuous gate registration, attributable red control, and durable campaign evidence are missing execution contracts.

Handing off to Producer claude-a — address each finding in the plan and return for round 2.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
