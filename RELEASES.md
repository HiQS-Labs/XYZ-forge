# Major Releases

Forward-looking planning ledger for major releases — one block per release, minimal fields, blank
line between blocks. Marathon plans and other forward planning cross-reference this doc for
target release names/dates; it is not a history of what shipped (that's CHANGELOG.md — lessons
learned belong there at ship time, not duplicated here). Contract lives in PROJECT/PDDA.md ->
"RELEASES.md — release ledger". Add new fields only when a real need shows up.

## This file is OPTIONAL (GH-381)

**Read this before proposing an edit to it.**

`RELEASES.md` is an *optional planning aid*. It is not a required artifact, it is not a checklist,
and it is **not something to keep topped up**. An empty file, a stale file, or no file at all are
all perfectly valid states. The tooling agrees: `pdda.sh releases` is warn-only, never blocks, and
skips entirely when the file is absent — *"RELEASES.md not found — nothing to check."*

**Do not offer to fill this in, populate it, bring it up to date, or add the release you just
shipped.** Do not treat a sparse file as an incomplete one. If nobody is actively planning a release
arc right now, the correct amount of content here is whatever is already present — including
nothing.

Edit it only when an operator explicitly asks for release *planning*. That is the whole trigger.

## Scope boundary — Litmus (0.2.0) vs Nightwatch (0.3.0)

Added 2026-08-08 after a cross-model consult (codex + agy) found the two descriptions **not
decidable**: a competent agent could not route a new issue between them from the prose alone, because
Litmus says checks must "report red" correctly while Nightwatch says hostile states must "fail
clearly." Both advisors independently flagged this as blocking, and the overlap is worst exactly where
orchestration failures emit gate-looking verdicts.

> **Litmus owns faulty decision semantics.** A named acceptance, preflight, reviewer, or pre-advance
> check returns pass, fail, or a *reason* inconsistent with a controlled input's observable outcome —
> or lacks a recorded negative control.
>
> **Nightwatch owns run lifecycle.** Dispatch, target and worktree containment, claims, durable
> logging, interruption, and resume — **even when lifecycle code emits a misleading message.**
>
> **Classify by the violated invariant, not by the wording of the message.** Split an issue that
> violates both.

That last clause is the load-bearing one. The intuitive rule — "a lying message is Litmus" — gives the
wrong answer: #426 exits 6 claiming containment worked while a file leaked, but the invariant it
violates is run containment, so it is Nightwatch, with the assertion of its lie written as a
Litmus-style test. Conversely #407 reports `pre-advance-failed` when no gate ran, and that *is* a
Litmus defect, because the violated invariant is the verdict itself.

**A release is not its milestone.** A milestone is a backlog and grows while you work; a release needs
a frozen manifest and a testable exit criterion, both recorded in the blocks below. "The open issues
are done" is not an exit criterion, because working on a release generates more of them.

## What belongs here, on the occasions it is used

**Major and meaningful releases only. Not every release number.**

A block earns its place by being worth *planning toward* — a named arc with a theme, a target date,
and a milestone. If the only thing you can write in `Description:` is a restatement of what changed,
it belongs in CHANGELOG.md and nowhere else.

`Iterations:` reserves a band of patch numbers for a release. **Reserved, deliberately not
enumerated** — versions inside a band ship freely and are recorded in CHANGELOG.md only. They never
get a block here. The band is what makes "where does 0.2.3 go?" a question with a written answer
instead of one resolved by adding a row.

**A version inside an existing band is already accounted for, so a new block for it is a
duplicate.** That is the admission rule, and it is the only one.

Why this is written down rather than assumed: the failure mode is not a wrong entry, it is a file
that stays correct at every single step while turning into the wrong thing. Add `0.2.1` because it
shipped, add `0.2.2` for symmetry, and this becomes a **de-facto pre-CHANGELOG** — a second,
hand-maintained history that is guaranteed to disagree with the real one the first time someone
updates one and not the other. Two sources of truth for the same fact is the defect; the row count
is only the symptom.

An assistant that keeps asking for this file to be filled produces exactly that outcome, one
helpful suggestion at a time. Hence the section above.

When a band is exhausted, widen it or promote the next release — do not start enumerating.

`Milestone:` is the release -> issue-set join key (GH-284 Phase 3): a GitHub MILESTONE TITLE, not a
URL and not a list of issues. `GH_URL:` can name only one thing, which cannot express a release's
scope. Ask GitHub what is in a release instead of maintaining a list here:

    gh issue list --milestone "Quicksilver" --state open --json number,title,labels

Release: 0.1.0
Iterations: 0.1.0-0.1.4
Status: Shipped
Target Date: 2026-08-01
Codename: Quicksilver
Description: Python-authoritative Tier-A twins. Licensed AGPL-3.0-only (`LICENSE`) with a commercial option (`LICENSE-COMMERCIAL.md`), adopted 2026-07-29 post-ship; the pre-existing conflicting `LICENSE.md` was removed 2026-07-30 (#372).
GH_URL: [GH 308](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/308)
Milestone: Quicksilver
Front-door reviewed: No
Shakedown reviewed: No
License file: Yes

Release: 0.2.0
Iterations: 0.2.0-0.2.4
Status: Release Candidate — exit criterion MET 2026-08-09 on `development` @ `263816c`
Target Date: 2026-09-05
RC evidence: `bash test/litmus-release.sh --release-gate` → `GOALPOST MET — all 6 manifest entries complete` (6/6, 0 remaining, 0 false completion claims). Its own negative control, `--mutate-evidence`, was re-run on the same commit and reports `negative control OBSERVED in both directions (6 pass, 0 fail)` — it detects a stripped declaration, an unregistered gate (the #461 defect), and an invariant violated in either direction. Four of the six issues are CLOSED with per-criterion evidence (#407, #417, #457, #461). **#375 and #390 remain OPEN on purpose:** their gates are registered, green and control-observed, which is what this release's exit criterion measures, but each has acceptance criteria that did not ship — #390 defers a host free-memory floor and packet-driven per-phase overrides to a Phase 2 its own code comment names (`marathon_drive.py:1253`), and #375's shipped three-state `unverifiable` verdict deliberately contradicts its criteria 1 and 5 because implementing them literally took `relay-self-sufficiency.sh` from 4/0 to 0/4 on a working machine. Both are audited per-criterion on the issues. Closing them silently would have repeated exactly the #401→#461 mistake this release exists to catch.
Codename: Litmus
Description: Make the checks capable of failing. Every gate in the Litmus manifest is shown to report red against a real defect, or is explicitly downgraded to advisory — a check never observed failing is not evidence (#419). Ordered first because it is the release that makes the next one measurable. It is also what the self-improvement chain (#431) is blocked on: a Reviewer is a gate, so #419 applies to it, and its qualification gate is currently un-runnable (#428) and has only ever been measured once (#429).
Exit criterion: `bash test/litmus-release.sh --release-gate` exits 0. Red today by design; turning it green is what "done" means. Its own negative control is `--mutate-evidence`, which must detect a stripped declaration and an unregistered gate. NOTE the honest limit, stated in that file: the audit proves registration, declaration shape and the absence of false completion claims. It does NOT prove a control was truly observed, because `gate_inventory.py` reads a declaration authored by the same person who wrote the gate. Recorded execution of each control is deliberately out of scope for this release.
Manifest: FROZEN 2026-08-08 — #375, #390, #407, #417, #457, #461. Six named decision gates, a fixed denominator rather than a percentage. "Every gate" was unshippable prose: `gate_inventory.py` reports 152 of 158 gates with no declared control, and retrofitting them is explicitly out of scope. Adding an entry is a RE-SCOPE, not a bugfix: a mid-release discovery joins only if it makes the exit command fail or falsifies a named invariant, has a reproducer demonstrating that, and the operator explicitly swaps out an existing entry or accepts a date slip. Discovery is not admission — #457, #460 and #461 were all filed while executing Litmus, which is what an unfrozen boundary looks like.
GH_URL:
Milestone: Litmus
Front-door reviewed: No
Shakedown reviewed: No
License file: Yes

Release: 0.3.0
Iterations: 0.3.0-0.3.4
Status: Release Candidate — exit criterion MET 2026-08-11 on `development`
Target Date: 2026-10-10
RC evidence: `bash test/nightwatch-release.sh --release-gate` → `GOALPOST MET — all 8 manifest entries complete and every lifecycle case executes green` (manifest 8/8, lifecycle 5 passing / 0 failing / 0 NOT COVERED). Its own negative control, `--mutate-evidence`, reports 34/0 and `negative control OBSERVED in both directions`. Every manifest entry carries a recorded pre-fix control under `test/baselines/`, not an assertion that one happened. **Two entries are honest about their limits and are worth reading before signing off:** #358's Phase 2 is a *disposition* that needs a real CI failure carrying the new instrumentation, and its capture doc forbids pre-committing one — so Phase 1 shipped and Phase 2 is blocked on an observation, not on work; and #354's membership is Phase 1 only, which was delivered by #376/#448 rather than by this release, recorded as such rather than rebuilt. **#426's outcome inverted its own diagnosis:** a factorial control showed the leak survives with worktree isolation OFF, so teardown was exonerated and the real cause was the GH-375 auth pre-flight running with the caller's CWD, outside containment. **Twelve open Nightwatch-milestone issues remain and gate nothing**, per this block's own "a release is not its milestone" rule.
Codename: Nightwatch
Description: An unattended marathon against a real target repo survives, records, and recovers. Before dispatching work, it proves the target can accept the harness write-set and preserves the local-state contract, so hostile ignore rules or linked worktrees fail clearly rather than silently splitting, leaking, or losing the run. GH-354 Phase 1 is an early Nightwatch containment prerequisite: restore clone-wide driver exclusion for linked worktrees and prove all driver pairs fail closed. A run interrupted, killed at its cap, or panicking the host leaves a durable record and recovery path instead of a clean tree full of ungated commits. Depends on Litmus. The same durability work is what makes a reflection corpus trustworthy (#431): a run with no record is invisible to any later pass over it, and the loop's own evidence has never survived a reboot (#430).
Exit criterion: `bash test/nightwatch-release.sh --release-gate` exits 0. **BUILT 2026-08-11 and red by design**, exactly as Litmus's was; turning it green is what "done" means. It has two halves because a metadata audit cannot answer this release's question. Half A audits the frozen manifest — each entry's gate EXISTS, is REGISTERED in `validate.sh` (a gate absent from TESTS is indistinguishable from one that passes — the #461 defect), and has a RECORDED control under `test/baselines/`; it also cross-checks that this list and the `Manifest:` line below agree, since a boundary that disagrees with itself is not frozen. Half B **executes** the lifecycle cases rather than auditing them, delegating to the suites that already drive real children and kill them rather than growing a second driver fixture here. Status on 2026-08-11: **manifest 8/8 complete; lifecycle 5 passing, 0 NOT COVERED — GOALPOST MET.** The last gap was the hostile-target write-set case, closed by #514, which was filed while executing this release and deliberately NOT admitted to the manifest (discovery is not admission); it belongs to the lifecycle list because the exit criterion always named that case — what was missing was a suite driving it. That lane also corrected its own premise: the pre-fix tree does not dispatch a turn first, it dies at the render's `git add` with an unhandled `CalledProcessError` traceback, so the discriminating assertion is the absence of that traceback rather than the absence of a dispatch. Its own negative control is `--mutate-evidence` (34/0), which unregisters a gate and deletes a recorded control in a fixture copy, requires both to be detected, and re-checks the unmutated inputs green in the same run so an always-red detector cannot pass for one. Honest limit, inherited from Litmus: Half A reads a declaration and a filename and cannot know a recorded control was honestly recorded; Half B is what narrows that, and is why this criterion is a command that kills children rather than a checklist.
Manifest: FROZEN 2026-08-11 — #408, #409, #426, #388, #387, #384, #358, plus #354 Phase 1. Eight named entries, a fixed denominator rather than a percentage. The first six were moved out of Litmus on 2026-08-08 after a codex+agy consult; #387 and #384 are added at freeze time because the exit criterion above already names their cases — it requires a cap-killed child and a restarted recovery, and nothing else in the milestone supplies either. **The milestone is not the manifest.** Nightwatch's milestone holds 18 open issues; the twelve not listed here (#376, #378, #379, #380, #382, #386, #391, #392, #402, #467, #491, and anything filed during execution) are backlog worked inside the 0.3.0-0.3.4 band, and none of them gates the release. **AMENDED 2026-08-11:** five of those — #378, #379, #380, #382, #491 — were re-milestoned to Meter (0.6.0) at the operator's instruction, so they are no longer Nightwatch backlog at all. The manifest above is untouched and the RC evidence stands; what changed is only the non-gating remainder. #358 stays milestoned here because it is a frozen manifest entry whose Phase 1 shipped and is counted in the RC evidence above — only its *Phase 2* moved, as scope. Adding an entry is a RE-SCOPE, not a bugfix, under the same admission rule Litmus used: a mid-release discovery joins only if it makes the exit command fail or falsifies a named invariant, has a reproducer demonstrating that, and the operator explicitly swaps out an existing entry or accepts a date slip. Discovery is not admission.
GH_URL:
Milestone: Nightwatch
Front-door reviewed: No
Shakedown reviewed: No
License file: Yes

Release: 0.4.0
Iterations: 0.4.0-0.4.4
Status: Draft
Target Date: 2026-11-14
Codename: Plumbline
Description: Assisted reflection and a bounded self-improvement loop, measured before either is trusted. The reflection pipeline turns durable Nightwatch records into proposals (`proposals-sink.sh` gains its first production caller) and is graded against external ground truth — the 49 human-filed findings from the two rebalance-OS marathons (#405/#406) — for recall and precision. Ships a committed benchmark and a recorded go/no-go; "not worth automating yet" is a passing result, per #431's own Phase 2 exit criterion. Operator sign-off stays manual. Depends on Nightwatch.
GH_URL: [GH 431](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/431)
Milestone: Plumbline
Front-door reviewed: No
Shakedown reviewed: No
License file: Yes

Release: 0.5.0
Iterations: 0.5.0-0.5.4
Status: Draft
Target Date: 2026-12-12
Codename: Lantern
Description: When the harness fails, the information needed to act already exists inside it — make it say so. Not "add checks": every case was already detected, and some were then described wrongly (a stack trace, a fabricated path, a success exit code, silence). Scope is one epic, deliberately narrow, and deliberately NOT Nightwatch: that milestone owns run lifecycle "even when lifecycle code emits a misleading message" (see the scope boundary above), and none of Lantern's cases violates a lifecycle invariant — they violate the legibility of a failure whose lifecycle handling was already correct. All four members were found in one afternoon during Nightwatch wave 3, which halted three times at zero paid-turn cost; each halt was avoidable from information the system already held. Depends on nothing; independent of Plumbline.
Manifest: FROZEN at one issue on creation — #499, which supersedes and closes #494, #495, #496 and #498. Four phases, each shippable alone: relay-drive launch preflight; a gate refusal that states its real reason; a launcher whose exit code survives plus a gate-readiness check; and a change-impact reporter. Freezing at one is the whole point — these were filed as four and unified precisely to stop a single coherent change spreading across four PRs. Adding a member is a RE-SCOPE, not a bugfix, per the Litmus rule above.
GH_URL: [GH 499](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/499)
Milestone: not created yet — #499 is unmilestoned by design while Nightwatch is the active goalpost
Front-door reviewed: No
Shakedown reviewed: No
License file: Yes

Release: 0.6.0
Iterations: 0.6.0-0.6.4
Status: Draft
Target Date: 2027-01-16
Codename: Meter
Description: A run accounts for what it spends and checks what it requires before spending it. Every member was found the same way — a real unattended marathon against `Hypercart-Dev-Tools/rebalance-OS` — and each one costs the operator something no gate ever reports: ten ready lanes blocked by two unrelated pre-existing test failures (#378); a builder killed by a $0.50 budget and escalated as a failed pre-advance gate, its `terminal_reason: budget_exhausted` left in an unreferenced temp file (#379); 108 of the target's own `permissions.allow` grants silently dropped because the directory was never trusted interactively, invisible in preflight, stdout and the escalation alike (#380); a host kernel-panicked under memory pressure while the run's telemetry reported tokens and wall-clock and nothing about memory (#382); and three codex builds plus three agy reviews spent re-running work the driver already had, because the cheap gate-only path exists but nothing points at it and `--retry` silently takes the expensive one (#491). Depends on Nightwatch — #382's numbers need a durable place to land, which is exactly what Nightwatch built. Independent of Plumbline and Lantern.
Scope boundary — Meter vs Lantern: **Lantern owns how a failure is described; Meter owns what a run consumed and what it required.** Route by asking whether the issue names a *resource or a precondition* — dollars, turns, memory, swap, a trusted directory, a green suite — or names *the wording of a verdict whose handling was already correct*. Written down because two members straddle it and the file already has one recorded case (Litmus vs Nightwatch, 2026-08-08) of two descriptions that a competent agent could not route between. **#379 is split by that rule and belongs to both:** the overloaded exit 5 is a Lantern-shaped naming defect, the budget itself is a Meter resource, and the scope boundary above says to split an issue that violates both rather than argue it into one. **#491 is the marginal call and is placed here deliberately** — the re-scoped defect is a help-text and discoverability gap, which reads Lantern, but the invariant it violates is that the harness re-spends paid turns whose results it already holds, and the issue's evidence is a cost measurement.
Exit criterion: `bash test/meter-release.sh --release-gate` exits 0. **NOT BUILT.** Writing it is Meter's first task, before any member is fixed — that ordering is the Litmus and Nightwatch precedent, and it is the whole reason both releases could tell a finished entry from a claimed one. Two halves, same shape as Nightwatch's: Half A audits the frozen manifest (each entry's gate EXISTS, is REGISTERED in `validate.sh`, has a RECORDED control under `test/baselines/`, and the list agrees with the `Manifest:` line below) and Half B EXECUTES the cases rather than auditing them — a run against a red-suite target proceeds under a recorded baseline and halts on a *new* failure; a budget-exhausted builder is escalated as budget-exhausted rather than pre-advance-failed; an untrusted target is reported before the first paid turn rather than after; a phase boundary records memory and swap; and a re-fire of an already-satisfied phase runs only the gate and says so. Its own negative control is `--mutate-evidence`, which must unregister a gate and delete a recorded control in a fixture copy, detect both, and re-check the unmutated inputs green in the same run.
Manifest: FROZEN 2026-08-11 on creation — #378, #379, #380, #382, #491, plus #358 Phase 2. Six entries, a fixed denominator. **#358 is the one member NOT milestoned Meter, and this is deliberate:** the issue is a frozen entry in Nightwatch's manifest whose Phase 1 shipped and is counted in that release's RC evidence, so re-milestoning it would falsify a frozen boundary to tidy a join key. Only its Phase 2 moved. That entry is also the only one blocked on an *observation* rather than on work — it needs a real CI failure carrying the Phase 1 instrumentation, and its capture doc forbids pre-committing a disposition, so the exit criterion must accept a recorded transcript and must not accept a disposition written in advance. Adding an entry is a RE-SCOPE, not a bugfix, under the same admission rule Litmus and Nightwatch used: a mid-release discovery joins only if it makes the exit command fail or falsifies a named invariant, has a reproducer demonstrating that, and the operator explicitly swaps out an existing entry or accepts a date slip. Discovery is not admission.
GH_URL:
Milestone: Meter
Front-door reviewed: No
Shakedown reviewed: No
License file: Yes
