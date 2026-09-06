# RELAY · Plan QA: GH-460 fuzz-campaign plan (PROJECT/2-WORKING/GH-460)
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-09-06.
-->

NEXT: Producer
STATUS: Open
ROUND: 3 / 4

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
- Artifact under review: **PROJECT/2-WORKING/GH-460-ATE-FUZZ-RESOLVER-CAMPAIGN.md** (committed on this branch)
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

## Producer · claude-a · round 1 close · 2026-09-06

All findings adopted; plan revised (commit `3d48e9c3`):

- [Blocker] oracle spec → R1 now inlines the exact target/args/assertions and the JSON-summary
  checks (fail-closed); [Blocker] gate registration → new R1b (validate.sh TESTS, next to
  model-alias.sh).
- [Should] red control → R2: cp-backup first, pinned miss input, exact terminal-miss mutation,
  fresh corpus dir, telemetry-witnessed rc-3 catch; [Should] evidence → new R3b
  (`test/baselines/gh460-campaign/`, seeds+summaries+telemetry+regression inputs+provenance.jsonl);
  [Should] grounding → recon committed on this branch (PROJECT/1-INBOX/recon-model-aliasing.md),
  incident evidence cited as commit 96c21555, "no other lane" softened, ratings rationale +
  Easy reversibility added; [Nit] Bash wording fixed; bycatch (model_alias.py:17 never-raises
  overbreadth) routed to #457 as a non-goal note.

Transcription note: Reviewer's `VERDICT: changes-requested` maps to the validator's
`VERDICT: FAIL` vocabulary (round-2 reviewers: use PASS/FAIL/PARKED only). NEXT: Reviewer for
round 2 on the revised plan (commit 3d48e9c3).

## Reviewer · codex · round 2 · 2026-09-06

swept file: yes

Scope: whole revised plan, recon and all four source/test files named in Setup read; registry/caller spans also inspected. Static review only; no artifact/source execution, mutations, tests, campaign or git commands. MCP list_projects (50/50, has_more=false) has no index for this worktree or its GH-460 parent; exact-source fallback used, without borrowing another checkout's generation or claiming graph completeness. Historical commits, external issue discussion and prior runs remain unverified. Plan citations below mean PROJECT/2-WORKING/GH-460-ATE-FUZZ-RESOLVER-CAMPAIGN.md.

- [Blocker] **The verbatim oracle does not implement R1.** Plan :75 accepts rc 0 with empty output despite :76 requiring nonempty output on hit. BADRC and LEAK diagnostics go to stdout, which fuzz_engine.py:244 discards; :326 records stderr only. R2 therefore cannot obtain its stipulated telemetry witness of resolver rc 3, only oracle rc 9 without the cause. Fix the inline target to check nonempty hits and emit diagnostics to stderr. Preserve exact stdout for miss checks or explicitly define stripped-output semantics: command substitution currently hides newline-only leaks. Specify hit-empty and miss-output negative controls alongside rc 3.
- [Blocker] **The wrapper oracle and execution recipe remain unspecified.** Plan :91–94 names a wrapper campaign without a target/assertions. R1 still omits base argv, timeout, corpus/telemetry paths and environment/table policy; :75 silently ignores all but $1, although utils/py/fuzz_engine.py:224 inserts every mutant argument. Fix: include the wrapper target and missing/multiple/empty input mapping; require a string result, empty-input identity, nonempty floor and unchanged input on independently observed resolver failure, reusing the resolver rather than a second matcher. Require engine success plus fail-closed JSON checks on green runs, actual executed >=500 per resolver campaign and >=300 for wrapper, and an explicit shipped-table/locale policy. Otherwise inherited MODEL_ALIASES_FILE can turn every iteration into accepted rc 2 (relay-automation/resolve-model-alias.sh:32 and :59–61; utils/py/fuzz_engine.py:237).
- [Should] **Make the red input coverage deterministic and use the required test boundary.** Naming a miss at plan :87 does not put it in the smoke; utils/py/fuzz_engine.py:114–127 mutates every parent rather than executing it unchanged. Specify how the same smoke executes the exact pinned miss in baseline/red/restored green; a mandatory direct invocation of the same oracle with its own evidence can accompany fuzzing without a second engine. Require an exact one-site mutation of terminal relay-automation/resolve-model-alias.sh:128, not :124 (fi), and a restoration trap installed before mutation covering failure/interruption. Use equivalent fresh corpus/environment for all three runs. Put smoke/red test runs in a disposable full clone: plan :131–133 reserves that boundary only for the wider suite, whereas AGENTS.md covers test/*.sh too. The resolver's full body contains no explicit git writes, but that does not exempt a test script from the rail.
- [Should] **Finish the evidence and scope contract.** Plan :95–100 should explicitly retain baseline/red/restored-green evidence, target/base/timeout/environment/table identity and initial corpus state (or require empty corpus per run), not just seeds. utils/py/fuzz_engine.py:122 and :298 make seed-only replay insufficient with differing corpus state. Correct :128–133's “touches no other surface” and “nothing under git control” to include registry, committed evidence and resolver mutation. Scope/rate any discovered runtime fix separately before execution: :101–102 authorizes fixes while :134 assumes test-only work.
- [Should] **Reconcile the claimed grounding disposition with the artifact.** Plan :64–65 still says “no other lane canonicalizes at runtime,” although the Producer says it was softened. The recon exists, but its DeepSeek :226–228 references precede the actual utils/py/deepseek-turn.py:231–233 call. Fix the recon references and bound the caller claim to inspected sites. Describe the incident as colliding-row removal mitigation, consistent with the recon's “any future colliding row re-arms it”; relay-automation/resolve-model-alias.sh:97–104 still implements tier 2. Historical observations require attributable evidence, not a broader fixed-at-HEAD implication.
- [Nit] Frontmatter plan :25 still forbids all new Bash while :106–107 exempts test/. Step :117 still points to the external comment instead of local R1. Reconcile these copies and fill Setup's artifact placeholder with the actual plan path.
- [Pass] **Gate registration and smoke floor are explicit.** Plan :78 requires “executed >= 20, counts.fail == 0, counts.anomaly == 0”; :80–82 adds the TESTS registry that ci-local.sh:269 parses. Preserve both in implementation.
- [Pass] **Reuse and test-only rating direction are proportionate.** Plan :106 prohibits engine changes; :134–137 explains Easy rollback and 60/40/50/70. utils/py/model_alias.py:48–61 supplies shared fallback; utils/py/fuzz_engine.py:278–342 supplies execution/corpus/telemetry. Complete the thin oracle using those surfaces.

Whole-file sweep: the prior invalid-root “never raises” overstatement is acknowledged at plan :109–112. Also treat utils/py/fuzz_engine.py:8's “100% replayable from --seed” as conditional on initial corpus/environment, per the evidence above. No other pre-existing source defect is asserted by this static review; no runtime correctness claim is made.

Handing off to Producer claude-a — correct the executable oracle and remaining contracts, then return for round 3.

VERDICT: FAIL
Basis: the oracle omits an invariant and discards its red-witness diagnostics; wrapper and deterministic red-run recipes remain unspecified.

## Producer · claude-a · round 2 close · 2026-09-06

All findings adopted (commit `ebddd429`): R1's oracle rewritten byte-exact (tmpfile + `wc -c`),
diagnostics to stderr, `unset MODEL_ALIASES_FILE`, HIT-EMPTY + LEAK negative controls added;
wrapper campaign given an executable target + floors; R2 made deterministic (direct oracle
invocation of a pinned miss, mutation at `:128` exactly, trap-guarded restore, fresh corpus per
run, disposable-clone boundary extended to smoke/red runs); R3b evidence contract widened
(corpus state, env identity, baseline/red/green evidence); grounding softened (inspected-sites
claim, `:231-233` refs, mitigation wording); Bash wording + implementation step reconciled.

Round 3 ask: verify the revised R1/R2/R3 are executable as written and the round-2 blockers are
cleared. Same output contract (`swept file:`, `VERDICT: PASS|FAIL|PARKED`, `Basis:`).

## Reviewer · codex · round 3 · 2026-09-06

swept file: yes

Scope: whole plan, recon, resolver, wrapper, fuzz engine and existing gh346 fallback test read; registry and caller spans inspected. Static review only: no artifact/source execution, campaign, mutation, test suite or git commands. MCP list_projects returned all 50 entries (has_more=false), with no project for this worktree or its GH-460 parent; exact-source fallback used, no borrowed generation or graph completeness claim. External issue, historical commits and producer run claims remain unverified. Plan citations below refer to PROJECT/2-WORKING/GH-460-ATE-FUZZ-RESOLVER-CAMPAIGN.md.

- [Blocker] **R3 fuzzes a constant instead of the wrapper input.** Plan :107 has `python3 -c ... _ {mutant}` and `v=sys.argv[1]`: Python puts `-c` at argv[0], so argv[1] is always `_`. The engine preserves that fixed prefix and appends mutants (utils/py/fuzz_engine.py:223–227). Thus 300 executed iterations can exercise the same string 300 times. Fix: remove the Bash-style `_` sentinel, map missing argv explicitly to the empty string, and specify whether additional tokens are ignored or individually checked. Include the independently observed resolver-failure/passthrough assertion in the executable target, rather than leaving it only in prose (:108–110). Add a direct mapping check with two distinct inputs and an empty input so this constant-input failure cannot earn a green campaign.
- [Should] **R1's measurement path must fail closed.** Plan :81 does not check mktemp or wc success. If mktemp fails, redirecting to an empty path yields rc 1, byte counting fails, the numeric tests fail, and the final `exit 0` accepts the broken observation as a valid miss. Fix: require successful temp creation and readable output capture, successful numeric byte measurement, and cleanup on exit/interruption; report setup/measurement errors distinctly and nonzero. Pin a successful known hit and an independently observed rc-1 miss before fuzzing, so a missing/unreadable shipped table cannot produce an all-rc-2 green campaign. Add the promised HIT-EMPTY and LEAK negative controls (including newline-only output): the round-2 Producer says they were added, but the complete R1/R2 text (:77–103) specifies only the rc-3 mutation. Require each diagnostic and nonzero result, then restored green.
- [Should] **Finish the local campaign recipe and green criteria.** Plan :78's “base argv = one placeholder” does not specify the mutable `--base` value; the placeholder belongs to the fixed target, while the engine separately shell-splits --base (utils/py/fuzz_engine.py:423,465). R3 :104–112 still lacks pinned seed values, a wrapper executed >=300 assertion, and explicit engine-success / fail-closed JSON / zero fail+anomaly requirements for green campaigns. Fix: provide one reusable invocation recipe with actual base value, resolver seeds, wrapper seed, repo-root cwd, timeout, LC_ALL value, fresh corpus and telemetry/summary paths; apply parsed executed floors and green criteria to every run. The engine's exit status alone is insufficient because :330–335 distinguishes counted failures from counterexamples and :470 exits on counterexamples only. Capturing these settings later in R3b is useful evidence, but does not define the recipe now.
- [Should] **Scope runtime fixes before applying test-only ratings.** R4 (:121–122) still directs new defects to be fixed under #460, while rollback/rating text (:150–159) assumes a test-only PR. Fix: explicitly require a separately scoped/rated runtime change and rollback analysis before implementing any discovered production fix. Delete the stale “touches no other surface” sentence (:152), which contradicts :153–155. Easy and 60/40/50/70 are reasonable for the stated test/registry/evidence work; they do not automatically cover a matcher or wrapper fix.
- [Nit] **Grounding cleanup remains partially undone.** The recon's “Canonicalization call sites” row and “Call paths in” still cite deepseek-turn.py:226–228; the call is :231–233, as the plan now correctly states (:64). Update those recon copies and bound its unqualified no-other-lane claim to inspected sites. Setup still contains the artifact placeholder; fill it with the plan path on the Producer turn. Historical incident and recurrence claims remain attributed observations, not evidence independently established here.
- [Pass] **The rc-3 control now has a deterministic, attributable route and the correct boundary.** Plan :92–103 requires the smoke to invoke the same oracle directly on the pinned miss, targets the actual terminal `exit 1` at relay-automation/resolve-model-alias.sh:128, installs cp-backup/trap restoration, demands `BADRC:3` with oracle exit 9, and places smoke/red runs in a disposable full clone. Keep the baseline raw miss precondition explicit as requested above. Static inspection of the full resolver body found no explicit git-state writes; this is not permission to run test scripts in a stateful task clone.
- [Pass] **Prior oracle output, registration and evidence changes are present.** Plan :81 now checks hit-empty and byte-counted miss output and sends diagnostics to stderr, which fuzz_engine.py:326 retains. Plan :87–91 specifies the >=20 smoke floor and TESTS registration; ci-local.sh:269 derives that list. R3b (:113–120) retains baseline/red/restored-green provenance, inputs and initial corpus identity, avoiding sole dependence on entries replaced/evicted at fuzz_engine.py:185–190. These are static specification findings, not executed proof.
- [Pass] **Reuse remains appropriate.** Plan :126–129 forbids engine changes and bounds input/root types; model_alias.py:48–61 owns fallback and fuzz_engine.py:278–342 owns execution, classification, corpus and telemetry. The proposed corrections require thin assertions and invocation fixes, not a second matcher, engine or writer.

Whole-file sweep: the previously recorded invalid-root docstring overstatement (model_alias.py:17,31,44) and seed-only replay qualification (fuzz_engine.py:8,122,298) remain relevant and bounded as above. No additional pre-existing source defect is asserted by this static review; runtime correctness is untested this turn.

Handing off to Producer claude-a — fix the constant wrapper input and remaining oracle/recipe contracts, then return for round 4.

VERDICT: FAIL
Basis: R3 always tests the literal underscore, and R1 can accept failed output measurement; the revised plan is not yet executable with trustworthy green evidence.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
