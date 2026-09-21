# RELAY · GH-724 marathon-triage drive-loop plan QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-09-20.
-->

NEXT: Producer
STATUS: Approved
ROUND: 2 / 3

## ▶ TAKE YOUR TURN — read this first (works for ANY agent: Claude, Codex, agy)
1. **Read this whole file** (header, Setup, Ground rules, every block in the Log).
2. **Check it's your turn:** `NEXT` (top) names the role to act. Confirm you are bound to it and the
   last Log block isn't already yours. If not → STOP and reply "wrong window — nudge the <other> window."
3. **Do your role's work** on the artifact named in Setup:
   - **Reviewer:** review vs the Definition of Done → graded findings
     (`[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`), each with a concrete fix → set a **VERDICT**
     (exactly PASS, FAIL, or PARKED) and a **Basis** (explanation). **Review the whole file, not just the diff** (GH-268):
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
     **A finding that asks for a behaviour change is a generalization unless you can paste the concrete
     input — a row, a value, a `file:line` — that fails under the current code** (GH-681: the gh673
     final QA relay generalized one late-error observation into "or a later invalid identity", the
     Producer implemented it, the same seat `[Pass]`ed it next round, and one historical NULL-URL
     ledger row then blanked every issue). Every `[Blocker]` or `[Should]` requesting a behaviour
     change MUST carry three lines: `Observed input:` (the failing input you saw), `Affected scope:`
     (the input predicate the change would govern), `Falsifier:` (the fixture or data that would show
     the change unnecessary or wrong, and its expected result).
     A `[Blocker]` must cite an observed failure. This is a protocol rule, not a mechanical check —
     the Producer may disposition a request lacking these as `Declined — unproven generalization`.
   - **Producer:** log a disposition for every open finding (Implemented / Modified / Declined + why,
     including `Declined — unproven generalization` for a behaviour-change request that carries no
     `Observed input:` / `Affected scope:` / `Falsifier:`), make the change, then add new work.
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(gh724-plan-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: `PROJECT/2-WORKING/GH-724-MARATHON-TRIAGE-DRIVE-LOOP.md` (the plan). Read alongside: `skills/marathon-triage/SKILL.md` (current, to be rewritten), `skills/merge-cleanup/SKILL.md` (the loop shape to mirror: `## Recite this`, `## Drive loop`, `**Done rule**`), `relay-automation/hooks/relay-xyz-guard.sh`, `utils/py/marathon_plan.py`, `utils/hq/hq-lib.sh` (`hq_render_capture`, `hq_roadmap_line`), `utils/hq/hq.sh` (`park`), `PROJECT/PDDA.md` → "GitHub issue intake".
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-09-20
- Definition of Done: the plan's recon claims are grounded in the cited file:line evidence; the ordered Phase 1 list is sufficient to make `/marathon-triage` run unattended (inventory → reconcile → capture missing intake → planner dry run + per-candidate preflight → report) without inventing new tooling; the read-only/confirmation boundary is drawn correctly (read-only tools inside the default, irreversible actions behind confirmation); the capture recipe reuses the existing writers only; acceptance checks are falsifiable with a red control; non-goals keep #443's code work out; ratings are grounded.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Producer R1 — plan QA packet

VERDICT: PARKED
Basis: awaiting independent plan review.

**Operational envelope.** A markdown skill document (`skills/marathon-triage/SKILL.md`) that instructs a coding agent; local single-repo developer tooling. No runtime code, no tests added, no new writer. Grade against the stated requirements and commensurate complexity: do not ask for a triage runtime, a state machine, a new CLI verb, or enterprise fail-safes. The measurable defect is behavioural: agents invoking the skill stop and ask the operator before writing capture docs, running `swarm-preflight.sh --dry-run`, and running the planner dry run.

**Read first, in full:** the plan doc named in Setup, then the files listed beside it. Measure, read-only: you may run `python3 utils/py/marathon_plan.py --help`, `grep -n` over the cited files, and `bash relay-automation/hooks/relay-xyz-guard.sh` reading (do not execute the harness entrypoints themselves).

**Questions — answer each with a grade and a file:line citation:**

1. Recon grounding: do `marathon_plan.py:49/:52/:58` say what the plan claims (`--dry-run` writes nothing; `--deep` delegates to `swarm-preflight.sh --dry-run`; the exit code set)? Does `relay-xyz-guard.sh:98-100` really treat any Bash command containing `find-harness.sh` as proof-of-load, and are `marathon-plan`/`swarm-preflight` (Bash and Python twins) on the derived block list?
2. Is the diagnosis complete? Beyond the five traced causes, is there anything else in the current `SKILL.md` that would make an agent stop or ask before the end-to-end computation? Quote the line.
3. Is the read-only/confirmation boundary right? The plan puts `marathon_plan.py --dry-run --deep` and `swarm-preflight.sh --dry-run` inside the read-only default and reserves confirmation for promote / close / fire / cut a branch / write the plan file. Is writing a `1-INBOX` capture doc + `releases roadmap add` row (a reversible, repo-local, ledger-through-the-writer action) correctly treated as *in* the default with commit left to the operator — or should it sit behind confirmation? Give the concrete consequence either way.
4. Capture recipe: does `hq_render_capture` (`hq-lib.sh:401-416`) + `hq_roadmap_line` (`:548`) + `releases_app.py roadmap add` produce the same artifacts `hq park --create` produces for a new issue (`hq.sh:254-345`)? Any field the recipe would miss (e.g. `owner`, `goal`) that a PDDA gate then flags?
5. Drive loop / exit ladder: are the per-code actions for the planner (0/2/3/4/5/6) and preflight (0/2/3/4/5/6/7) consistent with the classification table already in the skill? Is `6 → re-run without --require-gh and mark UNKNOWN` correct given `marathon_plan.py`'s documented degrade behaviour?
6. Done rule: is it falsifiable? Can you construct a report the rule would wrongly accept (an agent that "asked whether to preflight" and stopped)?
7. Acceptance: the grep-count check (`^## Recite this|^## Drive loop|^\*\*Done rule` = 3) and the red control — adequate for a doc-only change, or is something load-bearing unchecked (e.g. the Step 0 proof-of-load sentence, the `ROADMAP.md` = 0 count in the deployed copy)?
8. Scope: is anything in Phase 1 more than a doc rewrite plus a Pulse re-publish? Anything that should be pushed to #443 or a follow-up instead?
9. Ratings `65/45/50/85`: grounded in the recon and the recurrence evidence (#443 + this report)? Appeal is neutral by policy.

Output: graded findings (`[Blocker]/[Should]/[Nit]/[Pass]`), each with the fix and a citation; `swept file: yes|no`; a VERDICT with Basis. Do not edit the plan or any artifact — findings only, in this thread.

### Reviewer R1 — codex

VERDICT: FAIL
Basis: the doc-only approach and existing writers fit the task, but the retained umbrella prerequisite prevents discovery-first triage, the read-only claim is inaccurate, and the completion/acceptance contract needs explicit blocked outcomes. These are plan corrections, not requests for runtime tooling.
swept file: yes

Read the whole plan and current marathon-triage skill, including the pre-existing prerequisites and report tail. Pre-existing defects relevant to this rewrite are included below. No artifact/source edits, git commands, harness execution, or test suites were run.

- [Should] **Q2/Q8 — scope the retained umbrella/clone prerequisites to execution.** Plan `PROJECT/2-WORKING/GH-724-MARATHON-TRIAGE-DRIVE-LOOP.md:68` explicitly preserves 0b/0c. Current `skills/marathon-triage/SKILL.md:66-83` says “Procedure, before any triage work”, requires opening/registering an umbrella and linking members, and says “If you cannot name the umbrella issue, you are not ready to triage”. That is an additional stop cause beyond the diagnosis and asks for the wave sketch before inventory computes it. Fix: retain umbrella/full-clone rules for launching a selected marathon; make inventory, capture and dry-run reporting possible without selecting/creating an umbrella. Report umbrella creation/linking as a downstream decision when not already authorized.
  Observed input: the existing skill's discovery trigger “choose work to swarm next” (`:7`) meets its unconditional “before any triage work” umbrella prerequisite (`:66`).
  Affected scope: triage invocations without an already selected marathon umbrella; execution prerequisites remain intact.
  Falsifier: walk the revised instructions with no umbrella and two unrelated candidate issues; inventory and a recommendation must complete without opening an umbrella or asking which arc to select first. An explicitly authorized marathon launch must still require its umbrella and full clone.

- [Should] **Q1/Q3 — replace “writes nothing/read-only” with the actual dry-run boundary.** Plan `:42` says preflight “writes nothing”; `:71/:86` repeats a read-only default. But `utils/py/swarm_preflight.py:1298` runs `git fetch --prune`, `:1355-1361` creates a detached worktree, and `:1378` removes it; its `args.dry_run` exit is only at `:1705-1711`. Planner `--deep` invokes that same path (`utils/py/_marathon_plan.py:1022-1030`). Fix the recon and guardrail to authorize ordinary readiness computation without repeated confirmation while accurately stating its Git-metadata/temporary-worktree effects, no packet/plan publication, and no execution. Explicitly call captures + ledger rows reversible default intake writes, and honor an explicit user request for a strictly read-only audit by reporting proposed captures instead. No code change or new approval gate is needed.
  Observed input: the planned `marathon_plan.py --dry-run --deep`/preflight `--dry-run` calls reach metadata mutations before the dry-run branch cited above.
  Affected scope: descriptions of dry-run side effects and default intake authorization, not runtime behavior.
  Falsifier: in a disposable clone, observe preflight on a valid contract with an outdated remote-tracking ref: ref refresh and transient worktree registration are allowed, while no packet/plan file is published. If dry-run bypasses those calls, this finding is wrong. [Unverified — needs clone run] for runtime side-effect measurement; source path observed directly.

- [Should] **Q5/Q6 — distinguish a completed report from a blocked report.** Plan `:73` says planner 3 must “report ... and stop”, but `:74` prohibits any report without quoted waves/held/drift and full coverage. A releases DB without `roadmap_items` raises `EngineExit(3)` before report rendering (`utils/py/_marathon_plan.py:773`); unavailable GitHub likewise cannot establish the complete open-issue universe. Fix: forbid claiming completion, not reporting, when requirements fail. Allow an explicit incomplete/blocked report naming command, exit, missing evidence and next action; bound invocation repair/retry and handle unexpected exits as unknown rather than success. Keep the complete-report conditions for healthy runs.
  Observed input: plan `:73` exit-3 stop and `:74` unconditional “no report unless” are contradictory for the concrete missing-table branch at `_marathon_plan.py:773`.
  Affected scope: failure and offline terminal outcomes; successful triage still needs full coverage and per-candidate evidence.
  Falsifier: a missing-table scenario must yield one blocked report without fabricated waves or an endless retry; a healthy scenario that merely asks whether to preflight must fail the completion rule.

- [Should] **Q7 — give behavioral acceptance a red control, not only the heading count.** Plan `:76/:78/:90` tests three headings and deletes one as its negative control. A document with all three headings but the unchanged “before any triage work” prerequisite still passes that test. Fix: retain the cheap structural check, and add a small reviewer walkthrough covering no umbrella, missing intake, invalid contract, and unavailable evidence, checking actions/report against the done rule. Use the current stop-before-preflight behavior as the failing control and record decisive evidence in the final relay block/PR acceptance map. No new test suite is requested. Step 0 and deployed-copy checks already exist at `:85/:88`; run and cite them rather than treating the heading count as proof of unattended behavior.
  Observed input: the proposed heading regex checks only `Recite this`, `Drive loop`, and `Done rule`, not their contents (`plan:76`).
  Affected scope: acceptance evidence for this skill rewrite only.
  Falsifier: retain all three headings while restoring the old ask-before-planner sentence (`skills/marathon-triage/SKILL.md:170-171`); the behavioral review must reject that mutant even though the heading check passes.

- [Pass] **Q1 — CLI and guard grounding otherwise holds.** `utils/py/marathon_plan.py:49-57` documents no plan doc in dry-run, deep delegation, degrading without `--require-gh`, and the stated exits (the exit line is 57, not 58). `relay-automation/hooks/relay-xyz-guard.sh:98-100` accepts any Bash command text containing `find-harness.sh`; `:123-139` derives Bash/Python twins. Narrow static probe: `python3 - <<'PY'` using `Path.read_text()`, the guard's `re.search(r'Tier-A[\s\S]*?entry points\s*\(([^)]+)\)', a)` and `re.findall(r'`([^`]+)`', m.group(1))`, then checking both files, exited **0**: `marathon-plan in_guard_inventory= True bash_exists= True python_exists= True`; `swarm-preflight in_guard_inventory= True bash_exists= True python_exists= True`. Same read-only probe counted `current_shape_headings= 0`, `literal_ROADMAP.md= 0`. Qualify “every call exit 2” in plan `:70` to sessions with this hook enabled and no prior marker; the hook is fail-open and session-scoped (`guard:24/:33-34`).

- [Pass] **Q3/Q4 — automatic reversible capture is appropriate; the existing writers cover the fields.** `utils/hq/hq-lib.sh:448-467` emits identity, title, status, created, `owner: unassigned`, provisional ratings and `goal`; `:548-550` supplies the pointer line. `utils/hq/hq.sh:324-339` uses exactly this render → roadmap-add sequence. PDDA's inbox minimum is `PROJECT/PDDA.md:263-269`; no additional owner/goal writer is needed. Preserve actionable issue substance in the renderer's request argument. Default capture authorization removes the reported operator stop; moving it behind a new confirmation would preserve that defect. The recipe should also say that a failed ledger add leaves intake incomplete (existing handling `hq.sh:342-345`), not silently claim success. Source-equivalence review only; PDDA gates were not run here.

- [Pass] **Q5 — documented code classifications and exit-6 degradation are consistent.** Current skill `:142-149/:164-165` maps invalid contract 3 to NEEDS-CONTRACT, stale 4 to CONTRACT-STALE, and 5/6/7 to BLOCKED. `marathon_plan.py:54` and `_marathon_plan.py:1196-1205` support retrying once without `--require-gh` and marking live state UNKNOWN. Record individual preflight evidence independently: deep delegation discards stdout/stderr and explicitly handles only 4/5/6/7 (`_marathon_plan.py:1028-1049`), so planner success alone is not each candidate's exit/verdict.

- [Pass] **Q6/Q8/Q9 — retain the proposed healthy-run done criteria, scope and ratings.** Plan `:74` rejects the “asked whether to preflight” terminal state and requires classifications, candidate evidence and capture gids; apply the blocked-report distinction above. Plan `:58/:62/:77-80` confines implementation to skill/governance docs plus deployment and explicitly excludes #443 runtime work. Ratings `:54` are reasonable ordinal judgments for the stated operator-time defect and small rewrite, with appeal neutral. Recurrence at `:50` is producer/operator-reported evidence, not independently re-observed here; no stronger recurrence claim is approved. Hooks/PDDA runtime checks remain [Unverified — needs clone run] where required by the turn boundary.

Handing off to Producer (claude-a) — revise the plan for the four Should findings, disposition each, and open R2.

### Producer R2 — dispositions and revised plan

VERDICT: PARKED
Basis: all four `[Should]` findings verified against source by the Producer and implemented in the plan (commit noted below); requesting R2 review of the revised `PROJECT/2-WORKING/GH-724-MARATHON-TRIAGE-DRIVE-LOOP.md`.

Dispositions (Producer verified each cited line before accepting):

- Q2/Q8 umbrella prerequisite — **Implemented.** Recon cause 6 added; Phase 1 step 1 now rescopes 0b/0c to *launching a selected marathon* ("before firing", after the report); triage runs with no umbrella and umbrella creation/linking becomes a decisions-list item. QA checklist gained the no-umbrella walkthrough scenario.
- Q1/Q3 dry-run side effects — **Implemented.** Verified `swarm_preflight.py:1297` (`git fetch --prune`), `:1355-1361` (detached worktree add), `:1378-1380` (remove/prune), `:1705-1711` (dry-run exit after), and `_marathon_plan.py:1022-1030`. Recon cause 2 and the guardrail bullet now say "ordinary readiness computation: refreshes remote-tracking refs, uses a transient worktree, publishes no packet/plan/doc" — inside the default; captures + ledger rows named as reversible default intake writes; an explicit strictly-read-only audit request is honoured by reporting proposed captures. Exit line corrected to `:57`. Guard claim qualified (hook wired, no prior marker, fail-open, session-scoped).
- Q5/Q6 complete vs blocked report — **Implemented.** Drive loop now defines two terminal shapes; planner exit 3 / `gh` unavailable / writer refusal yield a **blocked report** naming command, exit, missing evidence and next action; one bounded retry for 2 and 6; unexpected codes are unknown, never success; the Done rule governs *completion* claims only. Per-candidate verdicts must come from direct preflight calls (recon cause 7: deep delegation discards output, handles only 4/5/6/7).
- Q7 acceptance red control — **Implemented.** Kept the structural heading grep; added a stop-sentence grep (`request confirmation before generating|before any triage work|not ready to triage` must be 0) whose mutant is exactly the falsifier you named (all three headings present + the old planner sentence restored → grep 1 → rejected); added the four-scenario reviewer walkthrough (no umbrella + two candidates; missing capture; invalid contract exit 3; `gh` unavailable) to final QA, with the current stop-before-preflight behaviour as the failing control. The half-complete ledger add (`hq.sh:342-345`) is now reported as such, never as success.

Nits from the `[Pass]` items folded in: exit-code line `:57`; qualified "every call exit 2"; per-candidate evidence independent of planner success; provisional ratings note kept.

Questions for R2 (grade with citations):
1. Do the revisions resolve each `[Should]` as you intended, or does any leave a residual stop cause?
2. Is the two-shape terminal contract (complete / blocked) now consistent with the exit ladder — any code left without a mapped shape?
3. Is the rescoped 0b/0c placement (after the report, "before firing") the right boundary, or does any triage step still depend on an umbrella?
4. Anything in the revised Phase 1 that exceeds a doc rewrite + Pulse re-publish?

Handing off to Reviewer (codex) — take your turn.

### Reviewer R2 — codex

VERDICT: PASS
Basis: all four R1 Should findings are resolved in the executable plan. The rewrite can proceed using existing writers and readiness tools, with bounded failure reporting and falsifiable final acceptance. Two residual wording nits do not change the explicit Phase 1 contract. This approves the plan, not an implementation or deployment.
swept file: yes

Read the entire 100-line plan and entire 207-line current marathon-triage skill, including retained prerequisites, classification/ranking rules and report tail; cross-checked the cited guard, planner/deep-preflight paths, capture writers, PDDA intake minimum and merge-cleanup loop. No additional blocking pre-existing defect found in the artifact under review. No git commands, runtime entrypoints, test suites, source edits or artifact edits were run.

- [Pass] **R2 Q1/Q3 — discovery no longer depends on an umbrella.** `PROJECT/2-WORKING/GH-724-MARATHON-TRIAGE-DRIVE-LOOP.md:74` explicitly moves umbrella registration and clone naming after reporting, as prerequisites for launching a selected marathon. This overrides the retained current skill's “before any triage work” (`skills/marathon-triage/SKILL.md:66`) and removes the circular need to choose a wave before inventory. The no-umbrella/two-candidate walkthrough is required at plan `:81/:94`. R1 umbrella finding resolved; preserve this placement in the rewrite.

- [Pass] **R2 Q1 — readiness effects and intake boundary are explicit.** Plan `:42/:73` describes ref refresh and transient worktrees, matching `utils/py/swarm_preflight.py:1298/:1355-1380`, with the no-packet dry-run branch at `:1705-1711`. Plan `:75` reuses the renderer, pointer formatter and ledger CLI, reads the row back and reports half-complete intake on failure; this matches `utils/hq/hq.sh:324-345`. Renderer fields at `utils/hq/hq-lib.sh:448-467` cover the PDDA minimum (`PROJECT/PDDA.md:263-269`). Capturing missing intake is authorized by the revised default; contract authoring/promotion remains a recommendation. R1 side-effect and capture observations resolved in the operative instructions.

- [Pass] **R2 Q2 — terminal shapes cover missing evidence without pretending success.** Plan `:76-77` distinguishes complete from blocked reporting, bounds retries, classifies known nonzero exits and refuses to treat unknown exits as success. Thus missing `roadmap_items` (`utils/py/_marathon_plan.py:773`) yields a blocked report; unavailable GitHub remains UNKNOWN even if the planner degrades successfully (`utils/py/marathon_plan.py:54`); invalid contract maps to NEEDS-CONTRACT through the retained classification at `skills/marathon-triage/SKILL.md:146/:164-165`. Any unavailable per-candidate verdict falls under the missing-evidence blocked rule. Direct preflight evidence at plan `:76/:96` addresses deep delegation's discarded output (`utils/py/_marathon_plan.py:1028-1030`). R1 terminal-contract finding resolved.

- [Pass] **R2 Q1 — acceptance now checks the stop behavior as well as headings.** Plan `:79/:81/:93-96` requires structural and stop-sentence red controls, four reviewer scenarios, complete/blocked outcomes and direct preflight evidence; `:82` places acceptance evidence in the PR. Static baseline probe: `python3 - <<'PY'` with `Path.read_text()` on the plan and skill, `assert p and s`, `len(re.findall(r'^## Recite this|^## Drive loop|^\*\*Done rule', s, re.M))`, `sum(bool(re.search(r'request confirmation before generating|before any triage work|not ready to triage', l)) for l in s.splitlines())`, and `s.count('ROADMAP.md')` exited **0**. Decisive output: `plan_lines= 100`, `current_skill_lines= 207`, `current_shape_headings= 0`, `current_stop_sentence_lines= 2`, `current_literal_ROADMAP.md= 0`. The present skill supplies the specified failing control; actual revised-copy mutants and walkthroughs remain final-QA work, not evidence claimed here. R1 acceptance finding resolved at plan level.

- [Pass] **R2 Q4 — scope remains commensurate.** Plan `:60/:64/:80-83` confines implementation to skill/governance markdown, existing gates and skills-army-hq deployment, explicitly excluding #443 runtime work and a new capture verb. Easy reversibility at `:62` is appropriate. Ratings at `:56` remain reasonable ordinal judgments for the stated task; recurrence at `:52` is operator-reported, not independently reproduced in this turn.

- [Nit] **Finish propagating the corrected terminology.** Plan `:31/:89` still calls the tools/default “read-only”, whereas `:42/:73` correctly names metadata effects and intake writes. Rename those summary/checklist phrases to “ordinary readiness computation and reversible intake”. In the final skill, make the explicit strictly-read-only override cover the documented metadata effects too: report that readiness evidence unavailable or obtain it from an authorized disposable context, rather than treating skipped capture writes as sufficient. This is clarification of the existing explicit-request override, not a new default approval gate.

- [Nit] **Carry the guard qualification into the quoted instruction.** Plan recon `:43` correctly limits the block to hook-enabled sessions without a marker, but the proposed Step 0 sentence at `:72` still says “Skipping it makes every ... call exit 2”. Use “With the guard enabled and no prior proof-of-load, these calls are blocked with exit 2”. The source is explicitly fail-open and session-scoped (`relay-automation/hooks/relay-xyz-guard.sh:24/:33-34/:98-100`). The locator-first instruction itself is sound.

- [Unverified — needs clone run] Hooks suite, runtime side-effect observation, final rewritten-skill behavioral walkthrough and deployment parity have not been run in this reviewer turn. They remain the implementation gates specified at plan `:81-83/:91-96`; plan approval does not discharge them.

Relay closed (Approved), no further turn needed. Producer (claude-a) may proceed to the planned rewrite and final QA; the harness owns the relay-file commit.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
