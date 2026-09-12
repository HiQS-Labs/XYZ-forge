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
a manifest of DIALED-IN work and a testable exit criterion, both recorded in the blocks below. "The
open issues are done" is not an exit criterion, because working on a release generates more of them.

**Membership is dialed in, not frozen (2026-08-20, GH-111).** A task — and by extension a marathon —
is dialed into exactly one release at a time, recorded as a state in `releases.db` rather than as a
sentence someone remembered to write. Dialing a task in requires a reason, exactly as cutting one
does: deliberateness comes from every commitment stating its case, not from a ceremony that makes
*changing* the commitment expensive. What a freeze used to buy — a fixed denominator, so "N of M" was
an honest figure — is now bought by the release's BASELINE: the count of what it was committed to at
kickoff. Progress is measured against the live manifest, and growth against that baseline, so scope
creep is a measured fact instead of something forbidden and then worked around.

**Releases that shipped before 2026-08-20 used the freeze model, and their blocks still say so.**
Those `Manifest: FROZEN …` lines are the historical record of how those releases were actually run;
rewriting them would be a silent history edit. (Unrelated: "frozen Bash twins" elsewhere in this repo
means GH-308's Python-authoritative rule and has nothing to do with manifests.)

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
Status: Shipped
Shipped: 2026-08-14 — RC 2026-08-09 on `development` @ `263816c`, soak window 5 days, re-verified at ship on `86ba3bd5`: `bash test/litmus-release.sh --release-gate` → exit 0, 6/6 complete, 0 false completion claims. **The ship test was the release's own exit command, not an issue-state audit.** Convention settled 2026-08-14: an exit criterion that is MET *is* the definition of done; a release is not held open by issues it never named. Falsification check on the soak window found nothing — every issue filed 08-09 → 08-14 (#485, #491, #499, #503, #504, #509, #510, #514, #518, #520, #521, #522, #523, #525, #527, #528, #533, #534, #536, #539, #540, #542, #544) either shipped inside it or left the exit command green, and the command was re-run on a `development` containing all of those fixes.
Target Date: 2026-09-05
RC evidence: `bash test/litmus-release.sh --release-gate` → `GOALPOST MET — all 6 manifest entries complete` (6/6, 0 remaining, 0 false completion claims). Its own negative control, `--mutate-evidence`, was re-run on the same commit and reports `negative control OBSERVED in both directions (6 pass, 0 fail)` — it detects a stripped declaration, an unregistered gate (the #461 defect), and an invariant violated in either direction. Four of the six issues are CLOSED with per-criterion evidence (#407, #417, #457, #461). **Residual scope, resolved at ship (2026-08-14).** Both entries' gates are registered, green and control-observed — which is what this release's exit criterion measures — but each carried acceptance criteria that did not ship, and an unshipped criterion is not a reason to hold a met goalpost open. **#375 is CLOSED** (this block previously said it remained open; that was stale). **#390's residual is now [#546](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/546), milestoned Meter** — Layer 4's host free-memory floor and packet-driven per-phase overrides, deferred by the source itself at `utils/py/marathon_drive.py:1509` (verbatim: `# Layer 4 (host free-memory floor) and packet-driven per-phase overrides are Phase 2.`). Meter is the right home rather than a parking space: a host floor is a precondition checked before spending, #382 is already a Meter member and its capture doc documents this exact deferral, and #392 is the static counterpart to this runtime one. #546 is **milestone backlog, NOT admitted to Meter's frozen manifest** — it does not make Meter's exit command fail, so "discovery is not admission" applies. #375's shipped three-state `unverifiable` verdict still deliberately contradicts its criteria 1 and 5, because implementing them literally took `relay-self-sufficiency.sh` from 4/0 to 0/4 on a working machine; that is recorded on the issue and is a deliberate deviation, not an omission.
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
Status: Shipped
Shipped: 2026-08-14 — RC 2026-08-11 on `development`, soak window 3 days, re-verified at ship on `86ba3bd5`: `bash test/nightwatch-release.sh --release-gate` → exit 0, **manifest 8/8 complete, lifecycle 5 passing / 0 failing / 0 NOT COVERED**. Half B *executes* the lifecycle cases rather than auditing them, so this is a run that killed real children and watched them recover — not a checklist. Falsification check on the soak window found nothing: the exit command was re-run on a `development` that already contains every fix landed 08-11 → 08-14, including GH-314 (the marathon transcript write-set), which is adjacent to this release's subject and was the one worth checking. The hostile-target write-set lifecycle case still passes via `gh514-write-set-trackable.sh`. Open non-manifest issues (#514, #467, #402, #392, #391, #386) do **not** hold this release open — the exit criterion never named them, and a milestone is a backlog, not a goalpost.
Target Date: 2026-10-10
RC evidence: `bash test/nightwatch-release.sh --release-gate` → `GOALPOST MET — all 8 manifest entries complete and every lifecycle case executes green` (manifest 8/8, lifecycle 5 passing / 0 failing / 0 NOT COVERED). Its own negative control, `--mutate-evidence`, reports 34/0 and `negative control OBSERVED in both directions`. Every manifest entry carries a recorded pre-fix control under `test/baselines/`, not an assertion that one happened. **Two entries are honest about their limits and are worth reading before signing off:** #358's Phase 2 is a *disposition* that needs a real CI failure carrying the new instrumentation, and its capture doc forbids pre-committing one — so Phase 1 shipped and Phase 2 is blocked on an observation, not on work; and #354's membership is Phase 1 only, which was delivered by #376/#448 rather than by this release, recorded as such rather than rebuilt. **#426's outcome inverted its own diagnosis:** a factorial control showed the leak survives with worktree isolation OFF, so teardown was exonerated and the real cause was the GH-375 auth pre-flight running with the caller's CWD, outside containment. **Twelve open Nightwatch-milestone issues remain and gate nothing**, per this block's own "a release is not its milestone" rule. **CI-VERIFIED 2026-08-12, and it was not before:** the goalpost was first met on macOS only, and two of the five lifecycle cases (#388, #514) were failing on every ubuntu CI run at the time the RC was recorded — their fixtures stubbed the builder but not the reviewer binary, so `marathon_drive.py`'s probe fail-fasted and the cases never executed the code they assert on. Fixed, and the gate now reports `GOALPOST MET` with `codex` absent from `PATH`, which is the CI condition reproduced locally rather than inferred. Recorded here because it is exactly the class of thing this release exists to catch: a green result that was green about the wrong environment. The general defect is #520; the control is `test/baselines/GH-520-negative-control.md`.
Post RC update: **#358 Phase 1 is in Nightwatch. Phase 2 is deferred to the Lantern build.** Operator decision, 2026-08-11, recorded here rather than left implicit in an issue thread. Phase 1 — the lock instrumentation — shipped and is counted in the RC evidence above; the manifest below is unchanged and this release does not wait on Phase 2. Phase 2 is the *disposition*, which needs a real CI failure carrying that instrumentation, and it belongs to Lantern because what it produces is a failure that states its own reason — Lantern's whole subject — not a lifecycle invariant. **#358 keeps its Nightwatch milestone**, because it is a frozen manifest entry counted in this block's evidence and re-milestoning it to tidy a join key would falsify a frozen boundary. Only the scope moved.
Codename: Nightwatch
Description: An unattended marathon against a real target repo survives, records, and recovers. Before dispatching work, it proves the target can accept the harness write-set and preserves the local-state contract, so hostile ignore rules or linked worktrees fail clearly rather than silently splitting, leaking, or losing the run. GH-354 Phase 1 is an early Nightwatch containment prerequisite: restore clone-wide driver exclusion for linked worktrees and prove all driver pairs fail closed. A run interrupted, killed at its cap, or panicking the host leaves a durable record and recovery path instead of a clean tree full of ungated commits. Depends on Litmus. The same durability work is what makes a reflection corpus trustworthy (#431): a run with no record is invisible to any later pass over it, and the loop's own evidence has never survived a reboot (#430).
Exit criterion: `bash test/nightwatch-release.sh --release-gate` exits 0. **BUILT 2026-08-11 and red by design**, exactly as Litmus's was; turning it green is what "done" means. It has two halves because a metadata audit cannot answer this release's question. Half A audits the frozen manifest — each entry's gate EXISTS, is REGISTERED in `validate.sh` (a gate absent from TESTS is indistinguishable from one that passes — the #461 defect), and has a RECORDED control under `test/baselines/`; it also cross-checks that this list and the `Manifest:` line below agree, since a boundary that disagrees with itself is not frozen. Half B **executes** the lifecycle cases rather than auditing them, delegating to the suites that already drive real children and kill them rather than growing a second driver fixture here. Status on 2026-08-11: **manifest 8/8 complete; lifecycle 5 passing, 0 NOT COVERED — GOALPOST MET.** The last gap was the hostile-target write-set case, closed by #514, which was filed while executing this release and deliberately NOT admitted to the manifest (discovery is not admission); it belongs to the lifecycle list because the exit criterion always named that case — what was missing was a suite driving it. That lane also corrected its own premise: the pre-fix tree does not dispatch a turn first, it dies at the render's `git add` with an unhandled `CalledProcessError` traceback, so the discriminating assertion is the absence of that traceback rather than the absence of a dispatch. Its own negative control is `--mutate-evidence` (34/0), which unregisters a gate and deletes a recorded control in a fixture copy, requires both to be detected, and re-checks the unmutated inputs green in the same run so an always-red detector cannot pass for one. Honest limit, inherited from Litmus: Half A reads a declaration and a filename and cannot know a recorded control was honestly recorded; Half B is what narrows that, and is why this criterion is a command that kills children rather than a checklist.
Manifest: FROZEN 2026-08-11 — #408, #409, #426, #388, #387, #384, #358, plus #354 Phase 1. Eight named entries, a fixed denominator rather than a percentage. The first six were moved out of Litmus on 2026-08-08 after a codex+agy consult; #387 and #384 are added at freeze time because the exit criterion above already names their cases — it requires a cap-killed child and a restarted recovery, and nothing else in the milestone supplies either. **The milestone is not the manifest.** Nightwatch's milestone holds 18 open issues; the twelve not listed here (#376, #378, #379, #380, #382, #386, #391, #392, #402, #467, #491, and anything filed during execution) are backlog worked inside the 0.3.0-0.3.4 band, and none of them gates the release. **AMENDED 2026-08-11:** five of those — #378, #379, #380, #382, #491 — were re-milestoned to Meter (0.6.0) at the operator's instruction, so they are no longer Nightwatch backlog at all. The manifest above is untouched and the RC evidence stands; what changed is only the non-gating remainder. #358 stays milestoned here because it is a frozen manifest entry whose Phase 1 shipped and is counted in the RC evidence above — only its *Phase 2* moved, and it moved to **Lantern**, not Meter (see the Post RC update line above). Adding an entry is a RE-SCOPE, not a bugfix, under the same admission rule Litmus used: a mid-release discovery joins only if it makes the exit command fail or falsifies a named invariant, has a reproducer demonstrating that, and the operator explicitly swaps out an existing entry or accepts a date slip. Discovery is not admission.
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
Exit criterion: `bash test/lantern-release.sh --release-gate` exits 0. **NOT BUILT.** Writing it precedes fixing any member, which is the Litmus and Nightwatch ordering and the reason both releases could tell a finished entry from a claimed one. Two halves, the established shape: Half A audits the frozen manifest — each entry's gate EXISTS, is REGISTERED in `validate.sh`, has a RECORDED control under `test/baselines/`, and the list agrees with the `Manifest:` line below. Half B **executes** #499's four phases rather than auditing them, since every one of them is a message an operator either receives or does not: a `relay-drive` launch preflight that refuses before spending, a gate refusal that states its real reason, a launcher exit code that survives its wrapper, and a change-impact report. **#358 Phase 2 is the one member with no executable half, and the criterion is written around that rather than pretending otherwise:** it is satisfied by a RECORDED transcript of a real CI failure under `test/baselines/`, and it must NOT be satisfiable by a disposition written in advance — that issue's own capture doc forbids pre-committing one, and an exit criterion that accepted a pre-written verdict would launder exactly the thing #419 exists to prevent. Its own negative control is `--mutate-evidence`, which must unregister a gate, delete a recorded control, and substitute a pre-dated disposition for a real transcript — detecting all three, and re-checking the unmutated inputs green in the same run so an always-red detector cannot pass for one.
Manifest: DIALED IN at one issue on creation — #499, which supersedes and closes #494, #495, #496 and #498. Four phases, each shippable alone: relay-drive launch preflight; a gate refusal that states its real reason; a launcher whose exit code survives plus a gate-readiness check; and a change-impact reporter. Freezing at one is the whole point — these were filed as four and unified precisely to stop a single coherent change spreading across four PRs. **RE-FROZEN AT TWO on 2026-08-11 by explicit operator decision — #499, plus #358 Phase 2.** Recorded as a re-scope rather than an edit, because the admission rule below is worthless if a manifest can grow quietly: the operator named the entry and the release, which is the documented way past the rule, and this line says so with a date instead of just showing two items where there was one. It is a genuine fit, not a parking space — Phase 2 is a *disposition* that turns a lost concurrent-append record into a failure naming its own terminal lock state, which is Lantern's subject exactly, whereas the run lifecycle it sits inside was already handled correctly (that is the Nightwatch boundary, and it is why Phase 1 belonged there and Phase 2 does not). It was briefly a Meter member the same day and moved here before either release started; Meter's block records the move from its side. **#358 keeps its Nightwatch milestone** — it is a frozen entry counted in Nightwatch's RC evidence, so only its scope moved, and this is the second Lantern member not enumerable by `gh issue list --milestone Lantern`. Adding a further member is a RE-SCOPE, not a bugfix, per the Litmus rule above.
GH_URL: [GH 499](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/499)
Milestone: not created yet. The original reason — "#499 is unmilestoned by design while Nightwatch is the active goalpost" — expired when Nightwatch reached RC on 2026-08-11, and is kept here only so a reader does not act on it as if current. Creating it is a live decision, not a formality: **neither member would be enumerable by it as things stand** (#499 is unmilestoned, and #358 keeps its Nightwatch milestone deliberately), so the milestone would join nothing until #499 is assigned. The `Manifest:` line below is this release's authoritative scope either way.
Front-door reviewed: No
Shakedown reviewed: No
License file: Yes

Release: 0.6.0
Iterations: 0.6.0-0.6.4
Status: Draft
Target Date: 2026-09-26
Codename: Meter
Description: **XYZ can be handed to a stranger.** An unauthenticated clone reaches a documented entry path and exercises a supported happy path with no private context, from a tree that has been sanitized and secret-scanned. **RE-SCOPED 2026-08-15 by explicit operator decision** — Meter was originally the metering release ("a run accounts for what it spends and checks what it requires before spending it"; members #378 #379 #380 #382 #491, found by a real unattended marathon against rebalance-OS); that work moved intact to Sundown (0.8.0) and publication took the slot, because it is the next thing that happens to this repository and the operator named it. Recorded as a dated re-scope — a codename that quietly changes its subject is the same defect as a manifest that quietly grows. (This block was COMPACTED 2026-08-20 by operator request; the full prose of every paragraph below is in this file's git history.)
Publication target: **the deliverable is a sanitized clone, not this repository** — fresh history, single initial commit, pushed to **https://github.com/HiQS-Labs/XYZ-forge** (new org, named by the operator 2026-08-15, XYZ's permanent home). `CHANGELOG.md` carried forward verbatim as the public record; carrying the 2,147-commit history was rejected 2026-08-15 because a full-history secret scan would have to scan everything ever deleted — fresh history makes sanitization complete by construction. `.tick/` (161 MB) and `relay-system/` (32 MB) do not ship; `PROJECT/` ships as an empty PDDA scaffold plus the Meter build docs retained as a worked example — the method travels, the backlog does not.
Scope boundary — Meter vs Lantern: **Lantern owns how a failure is described; Meter owns what a run consumed and what it required.** Route by whether the issue names a *resource or precondition* (dollars, turns, memory, a trusted directory, a green suite) or *the wording of a verdict whose handling was already correct*. #379 splits across both by that rule (overloaded exit 5 → Lantern; the budget itself → Meter). #491 sits here deliberately: the violated invariant is re-spending paid turns already held, and its evidence is a cost measurement.
Exit criterion: `bash test/meter-release.sh --release-gate` exits 0. **NOT BUILT — writing it is Meter's first task, before any sanitization** (the Litmus/Nightwatch ordering). Two halves, re-pointed at launch with the 2026-08-15 re-scope (command and shape unchanged). **Half A AUDITS the launch artifact:** sanitized clone at the declared path with exactly one commit; `CHANGELOG.md` byte-identical to this repository's; `.tick/`, `relay-system/`, `temp/` absent; `PROJECT/` = PDDA scaffold + retained Meter example only; both LICENSE files present and consistent; secret-scan result names its tool version and exact commit. **Half B EXECUTES the stranger's path:** a credential-less clone of the published commit reaches the documented entry point and completes one supported happy path with nothing that exists only on the author's machine. Negative control `--mutate-evidence` (fixture copy): plant a private path in a tracked file, remove `CHANGELOG.md`, leave a `relay-system/` behind — detect all three, re-check unmutated inputs green in the same run. RED on arrival.
Manifest: **DIALED IN at TWO — #555 and #563.** #555 is the release's own exit criterion (ships first, arrives RED). #563 is the launch checklist authored by an external reviewer (Codex Sol High): release boundary, public onboarding and behavior, secret/privacy review, legal/CI/publication sequence — frozen whole per the Plumbline precedent (one coherent cutover, not split across issues). **Scope CLOSED to further admission by explicit operator instruction 2026-08-15** — the standing admission rule is superseded for this release only; anything discovered during execution is filed to Sundown or left unmilestoned and **waived in writing per #563's rule (a waiver names the failed criterion, owner, reason and follow-up — silence is not a waiver).** Known open items under that rule, each needing a fix or waiver before the gate is called green: **#564** (31 unaudited suites can reach the caller's clone through an empty fixture path) and **#544's re-arm debt** (hosted CI fires on nothing while private; going public is the documented trigger). **Re-scope ledger, dated** (full prose for each in this file's git history): 2026-08-11 frozen at five on creation (#378 #379 #380 #382 #491); same day #358-P2 briefly a member, moved to Lantern before any work began; 2026-08-12 #509 admitted; 2026-08-14 #509 retired complete (its two unchecked criteria made permanently unwitnessable by GH-544's CI retirement, which owns the debt and the re-arm trigger); 2026-08-14 #551 admitted (shared refuse-don't-default root cause under nine issues) and the target pulled in 2027-01-16 → 2026-09-26 (Nightwatch, the only blocker, had shipped); 2026-08-15 #555 admitted; 2026-08-15 the subject replaced (fifth re-scope) — the seven engineering entries dissolved: #380 CLOSED and shipped under the original scope (stays milestoned Meter as delivered work); #378 #379 #382 #491 #551 moved intact to Sundown (0.8.0) with their capture docs, acceptance criteria and evidence; #546 followed as Sundown backlog (was never a manifest entry).
Manifest-Members: 555 563
GH_URL: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/563
Milestone: Meter
Front-door reviewed: Yes
Shakedown reviewed: Yes
License file: Yes

Release: 0.7.0
Iterations: 0.7.0-0.7.4
Status: Shipped
Shipped: 2026-08-18 — `XYZ_BALLAST_STRANGER_RUNS=10 test/ballast-release.sh --release-gate` → exit 0, manifest 4/4 complete, stranger's path 4/4 passing (B1 10/10 consecutive parallel runs zero failures, B2a in-band ungated warning, B2b forced-red push refusal, B3 atomic event append).
Target Date: 2026-09-12
Codename: Ballast
Description: Post-launch hardening: **the launched repository holds up under a stranger's first run and an outside contributor's first push.** Every member was found the same way — by pointing the launch machinery at its own published output: the first fresh-clone runs of the public repository produced a different failing set each time (#15), a push gate that does not travel with clones got worse the moment the repo went public (#4), and the kernel's own event log can drop events on the concurrent path the kernel exists to coordinate (#14). Ballast exists because publication moved the failure surface from "our machines" to "everyone else's", and nothing in the shipped tree tests that surface. Builds on Meter's publication; depends on nothing unshipped.
Exit criterion: `bash test/ballast-release.sh --release-gate` exits 0. **NOT BUILT — writing it is Ballast's first task, before any member is fixed** (the Litmus/Nightwatch/Meter ordering; a release whose exit criterion is authored after its members cannot tell a finished entry from a claimed one). Two halves, the established shape. **Half A audits the frozen manifest:** each entry's gate EXISTS, is REGISTERED in `validate.sh` (a gate absent from TESTS is indistinguishable from one that passes — the #461 defect), has a RECORDED control under `test/baselines/`, and the list agrees with the `Manifest-Members:` line below in both directions. **Half B EXECUTES the stranger's path rather than auditing it:** (1) a fresh unauthenticated clone from the published commit runs the documented entry path ten consecutive times in parallel with zero failing runs — a contention warning is allowed only where it names the contended suite per #15's contract; (2) a fresh clone with no gate installed is surfaced as ungated, in-band, on the documented first-run path, naming the one-command install (#4) — and with the gate installed, a would-be-red push is refused (a push cannot be locally refused with no hook at all; that mechanical limit is stated here rather than papered over, and #4's fix makes the ungated state loud instead of invisible); (3) a writer killed mid-`appendEvent` loses no event, and no reader ever observes a partial `.jsonl` (#14). RED on arrival by design. Its own negative control is `--mutate-evidence`: in a fixture copy it must unregister a gate, delete a recorded control, and forge a passing stranger-run record; detect all three; and re-check the unmutated inputs green in the same run so an always-red detector cannot pass for one. **SHIPPED 2026-08-18.** `XYZ_BALLAST_STRANGER_RUNS=10 test/ballast-release.sh --release-gate` executed for real against a fresh disposable clone (`~/xyz-disposable/xyz-stranger-clone`): exit 0. Half A: 4 of 4 manifest members complete (#14, #15, #4, #3 — gate/registration/control/CLOSED-issue all confirmed). Half B: 4 of 4 passing (B1: 10/10 consecutive parallel runs with zero failures; B2a: ungated clone warning in-band; B2b: forced-red push refusal; B3: atomic-append cross-process stress case clean) — **GOALPOST MET**.
Manifest: FROZEN 2026-08-16 on creation — #14, #15, #4, #10, #3. Five entries, a fixed denominator rather than a percentage. Same admission rule Litmus and Nightwatch used: a mid-release discovery joins only if it makes the exit command fail or falsifies a named invariant, has a reproducer demonstrating that, and the operator explicitly swaps out an existing entry or accepts a date slip. Discovery is not admission. **#14 and #15 SHIPPED 2026-08-17** (PR #21, PR #20; each closed with evidence — atomic-write negative control, 10/10 consecutive parallel fresh-clone runs). **#3 SHIPPED 2026-08-17**: the durable-default and path-printing halves were already landed pre-freeze (GH-430); the sole remaining gap, a recorded negative control, closed the same day (`test/baselines/GH-3-state-dir-negative-control.md`) — closed as landed, not re-scoped or swapped. **#10 CUT 2026-08-17, invoking its own pre-declared contingency**: a driven marathon attempt (builder agy, reviewer codex, round-cap 5) escalated after 5 rounds without landing — the suite count the fix would need to touch grew from the estimated ~31 to 73 with zero mechanically adopted, and the builder self-issued a scope waiver rather than flagging the blocker back to the orchestrator. This is exactly the scope-slip the freeze anticipated ("#10 is the designated cut if scope slips... #1's clone-identity bracket already covers the same ground *detectably* in the meantime"); cut per that pre-authorized contingency rather than re-fired. Issue #10 stays open, un-closed by this cut — the underlying containment gap remains real, just descoped from Ballast. Manifest reduced from 5 to 4 entries; this is a recorded re-scope, not a silent drop.
Manifest-Members: 14 15 4 3
Explicit non-goals, stated so they are not silently absorbed: #16 (hosted CI re-arm — tracked separately, explicitly NOT in scope, the local pre-push gate stays the only gate), #9 (tooling floor: eslint/prettier, src/ coverage, decompositions), #11 (Sundown twin retirement), #12 (tree diet), #13 (fold scaling — its body was corrected 2026-08-16: it claimed event append is already atomic temp+rename, which was never true; #14 owns making it so).
GH_URL:
Milestone: Ballast
Front-door reviewed: No
Shakedown reviewed: No
License file: Yes

Release: 0.8.0
Iterations: 0.8.0-0.8.4
Status: Draft
Target Date: 2026-10-17
Codename: Sundown
Description: Retire the twelve frozen Bash twins. Three steps, in order: (1) sweep for real `XYZ_PYTHON=0` usage — if nothing sets it, the fallback is already dead in practice; (2) re-vendor every fleet `.xyz/` copy onto the Python lane (`xyz-sync.sh list` is the worklist); (3) delete the twins and retire the GH-308 edit-guard, keeping only its no-new-Bash half (GH-551). Not before steps 1-2: the vendored fleet still runs the Bash path, and `XYZ_PYTHON=0` is the documented rollback. Depends on nothing in Meter.
**WIDENED 2026-08-15 by explicit operator decision — Sundown receives Meter's five engineering entries.** The release's sentence becomes: **the harness accounts for what it spends, checks what it requires before spending it, and stops carrying the retired Bash lane.** Said plainly rather than argued into one theme: the twin retirement and the metering work are two subjects sharing one release, and they are here together because Meter was re-pointed at publication on 2026-08-15 and these five needed a home that was not a parking space. They arrive intact — same capture docs under `PROJECT/2-WORKING/`, same verbatim acceptance criteria, same evidence — and the honest reading of the widening is that Sundown's date is now less trustworthy than it was, because it absorbed five entries without absorbing any schedule.
**RENUMBERED 0.7.0 → 0.8.0 on 2026-08-16 by explicit operator decision, to open 0.7.0 for Ballast.** Nothing about this release changed except its version: same codename, same target date, same manifest, same milestone. The band moves with it (`0.7.0-0.7.4` → `0.8.0-0.8.4`) because a release's iteration band is part of its identity here, not a separate fact. Recorded as a dated line rather than shown as a block that was always 0.8.0, on the same principle the manifest re-scopes above follow: a version that changes without a trace is indistinguishable from one that was misread. The `(0.7.0)` parentheticals in Meter's re-scope paragraphs were swept to `(0.8.0)` in the same edit — they identify *which release received the transfer*, so leaving them stale would have pointed a reader at a version that no longer exists. `CHANGELOG.md`'s existing entry is **not** swept: it is the append-only record of what was decided on 2026-08-15, when Sundown was 0.7.0, and the renumber is recorded there as its own dated entry instead.
Manifest: **#378, #379, #382, #491, #551, #28**, received from Meter 2026-08-15, plus the twin-retirement work described above, which remains unnumbered until its issues are filed. **#28** is the RELEASES.md ledger-discipline fix (parser continuation-folding + advisory bloat checks; see its capture doc for detail), added 2026-08-18 as a post-Ballast follow-up. **#546 is milestone backlog, not a manifest entry** — it followed the metering subject here and does not gate this release, under the standing rule that discovery is not admission. **Not yet frozen.** Freezing requires the twin-retirement issues to exist so the manifest is a fixed denominator rather than a list plus a promise; until then this line is a receipt for the transfer, not a contract. #380 did not move: it is CLOSED and shipped under Meter's original scope, and stays milestoned there.
Exit criterion: **NOT WRITTEN.** Required before this release starts, per the ordering Litmus and Nightwatch both used and Meter is repeating — the gate is built first and arrives RED, because a release whose exit criterion is authored after its members cannot tell a finished entry from a claimed one.
GH_URL: pending — api.github.com DNS outage 2026-08-14; file on recovery
Milestone: Sundown
Front-door reviewed: No
Shakedown reviewed: No
License file: Yes

Release: 0.9.0
Iterations: 0.9.0-0.9.4
Status: Draft
Target Date: 2026-09-19
Codename: Cargo
Description: The harness travels with its ledger. The RELEASES DB system (releases_app.py CLI + merge resolver + FAQs) and the GH-103 HTML timeline generator (utils/timeline/) ship inside every vendored `.xyz/` payload as an optional, never-wired-by-default add-on — a "when you're ready" module a target repo enables by running `releases init` itself, matching this file's own OPTIONAL philosophy (GH-381). Sequenced before Meter (0.6.0, 2026-09-26) by explicit operator decision 2026-08-20; version 0.9.0 because every 0.1–0.8 band is reserved — target date, not version number, carries the ordering. Cut through the CLI and mirrored here by hand in the same commit (the GH-32 Phase-0 dual path; no automatic dual writer exists yet).
Exit criterion: A repo vendored with `xyz-vendor.sh` can, with zero extra downloads, run `releases init`/`add` and `export_timeline.py --preview` from `.xyz/` against its own root, and `xyz-sync.sh update` preserves the target's ledger state (GH-312 preserve list). Nothing runs until the user invokes it. NOT BUILT — the gate is authored before any member is fixed, per the Litmus/Nightwatch ordering.
Manifest: DIALED IN 2026-08-20 on creation — #105 (vendor the RELEASES DB + timeline generator into the .xyz payload). RE-SCOPED 2026-08-20 by explicit operator instruction: + #107 (connect /10days, /radar, and PARKED to the RELEASES DB — read-only consumption seams; no new writers). Two entries; no swap; target date held — #107 is additive tooling scoped as quick wins. The standing admission rule remains for anything further: a mid-release discovery joins only if it makes the exit command fail or falsifies a named invariant, has a reproducer demonstrating that, and the operator explicitly swaps out an existing entry or accepts a date slip. Discovery is not admission.
GH_URL: https://github.com/HiQS-Labs/XYZ-forge/issues/105
Milestone: Cargo
Front-door reviewed: No
Shakedown reviewed: No
License file: Yes
