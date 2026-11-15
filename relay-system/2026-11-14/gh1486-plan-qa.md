# RELAY · GH-1486 plan QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-11-14.
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
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
   Reviewer headings may be `### Reviewer · Round N`, `### Round N · Reviewer · <agent>`, `### Reviewer (<agent>)` (optionally followed by `— rN`), or `### Reviewer — Round N` (optionally followed by `(<agent>)`); follow the heading with a non-empty review body.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(gh1486-plan-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: `PROJECT/2-WORKING/GH-1486-RE-VENDOR-XYZ-SKILL.md` (frontmatter `non_goals`, `## Recon`, `## Preflight bet`, `## Plan`, `## Acceptance`, `## Verification`, `## Risks`). This is a **plan review**: the skill file has not been written yet.
- Reviewer: codex   ·   Producer: claude
- Started: 2026-11-14
- Operational envelope: an instruction-only skill (one `SKILL.md`) that an agent follows on one developer's machine to refresh one repository's git-ignored `.xyz/` copy, by sequencing commands that already exist (`relay-automation/xyz-sync.sh`, `xyz-vendor.sh`, Skills Army HQ `sync.py`/`intake.py`). No script, flag or suite is added (XYZ-forge `AGENTS.md` *No new tests*, GH-831). Grade against that envelope; do not ask for locks, journals, daemons, a helper script or a fleet mode.
- Operator decision already made: a **separate skill**, not a `## Refresh` section in `vendor-stack`. Two consult advisors recommended the section under `skills/README.md:25-28`; the operator chose the separate skill for a memorable name (issue #1486, first comment). Do not reopen this; you may flag a concrete harm it causes.
- Definition of Done: the plan is grounded in the cited paths, sequences the existing writers without duplicating any, each listed stop is checkable with the commands the plan names, and each acceptance item would fail on base `5967bde25`.

### Step A: paraphrase first (GH-1414). Do this BEFORE reading anything else.
Read ONLY the plan doc's frontmatter `non_goals`, `## Status`, `## Recon`, `## Preflight bet`, `## Plan`, `## Acceptance`, `## Verification` and `## Risks`. Do not open source files or the issue yet. Then, at the top of your review block, write:
- **What this proposes** (2–5 sentences)
- **How the existing system works, per this document** (2–5 sentences)
- **What it's not** (short; ground exclusions in the doc's sections and label any inference)
- **Input boundary:** list which sections you had read when you wrote the paraphrase.

### Step B: source-backed technical validation
Now read the requirements and source:
- Issue: https://github.com/HiQS-Labs/XYZ-forge/issues/1486 and its first comment (consult dispositions).
- `relay-automation/xyz-sync.sh` (whole file: `select_vendored_rows`, `update_rows` 268-298, `require_safe_update_source` 300-330, `check_rows` 406-465).
- `relay-automation/xyz-vendor.sh:36-75` (args, tier auto-detect), `:230-240` (`XYZ_RUNTIME_PATHS`), `:420-516` (`materialize_vendor`, `register_vendor`).
- `relay-automation/driver-lock-lib.sh:1-40`.
- `skills/3-weekly/skills-army-hq/SKILL.md:20-90,190-250`.
- `skills/4-occasional/vendor-stack/SKILL.md` (whole file), `skills/README.md:15-40`, `ARCHITECTURE.md:130-155`, `README.md:245-265`.
- `utils/ci-route.sh:54-70` (gate route).

Label this assessment **source-backed**. Answer each question with `file:line` evidence:

1. Are the Recon claims true at the cited lines? Name any that are wrong.
2. Plan step 1.2: does `fetch` + `merge --ff-only origin/<branch>` + `HEAD == origin/<branch>` reliably reject a Forge checkout carrying unpublished commits, without mutating anything the operator would not expect? Is the merge step needed at all, or should a behind checkout simply stop?
3. Plan step 1.3/1.6: `xyz-sync.sh` matches `<target>` or `<target>/.xyz` and `check` prints the install dir. Is passing `$T/.xyz` everywhere and matching the line `ok    $T/.xyz` exact and robust (paths with spaces, a registry with several rows for nested repos)?
4. Plan step 1.4: is "relay lock path absent and no process command line contains `$T/.xyz/`" a sound check for a live relay, marathon or Jog run in that repository? Name a live-run shape it misses, and say whether missing it matters within the envelope.
5. Plan step 1.5: is the tier rule right? When `releases.db` exists, does `xyz-vendor.sh` already keep tier 2, and is there any tier-1 copy the rule would wrongly stop?
6. Plan step 1.6's three-part current test: is it the right definition of "current"? Does `check` read the registry rather than the copy (so a registry row and `VERSION` could disagree), and does the third condition close that?
7. Plan step 1.9: is the Skills Army handoff correct (read-only status with `--canonical`, then the `skills-army-hq` skill's own preview/apply), and does it avoid writing the collection on its own authority?
8. What prevents an unchanged base from passing each acceptance item A1–A7, and is each red control or contrast the right observation? Distinguish checks that prove the skill's stops fire from checks that only prove nothing crashed.
9. Is anything here more machinery than the problem needs, or is a required case missing? Flag over- and under-engineering concretely. Do not ask for new suites.

Write graded findings, then a VERDICT. Set STATUS to Approved only if no `[Blocker]` or `[Should]` remains.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer · Round 1

**What this proposes.** Add a separate `/re-vendor-xyz` instruction-only skill to refresh one registered repository's `.xyz/` using existing writers. It checks published source, inactivity and tier retention, backs up the copy, verifies three currentness conditions, then hands deployed-skill drift to Skills Army HQ. Three existing documents gain pointers.

**How the existing system works, per this document.** `xyz-sync.sh` selects registry rows and delegates replacement to `xyz-vendor.sh`, which preserves selected runtime state and writes VERSION and registry metadata. Bare single-target updates lack the source guard, while `check` compares registry metadata to local Forge HEAD and can report both `ok` and a missing safety guard. Skills Army owns collection updates through preview/apply.

**What it's not.** Per `non_goals` and Preflight bet, this is not first installation, fleet refresh, script changes, collection deployment, or detection of hand edits inside `.xyz/`.

**Input boundary:** Before writing this paraphrase I read the relay instructions and the plan's `non_goals`, Status, Recon, Preflight bet, Plan, Acceptance, Verification and Risks. The read command also displayed the title, remaining frontmatter and Rating rationale; no source or issue had been opened.

**Assessment: source-backed — Block pending two plan corrections.**
swept file: yes

Graph tools (`list_projects`, `index_status`, search and coverage) are unavailable in this session's tool inventory; validation used exact source reads and targeted text searches. Read the complete plan and `xyz-sync.sh`, the requested source ranges and pointer documents, and issue #1486 plus its first comment through read-only `gh api` (exit 0). No suites, executable fixtures, or git commands were run. Runtime fixture claims remain **[Unverified — needs clone run]**. No additional pre-existing defect was found in the plan beyond the findings below; this is not an exhaustive audit of the underlying harness.

- **[Should] S1 — Resolve the vendored relay lock against the harness root, not only the consumer repository.** Recon/step 1.4 currently describe `$T/.git/relay-driver.lock` (`PROJECT/2-WORKING/GH-1486-RE-VENDOR-XYZ-SKILL.md:52,71`). The relay actually derives `root_dir` from its own file (`utils/py/relay_drive.py:115-118`) and locks `driver_lock_path(root_dir)` (`:522`); the resolver's no-git fallback is `<root>/.relay-driver.lock` (`utils/py/rtl.py:983-1005`). Thus a vendored relay locks `$T/.xyz/.relay-driver.lock`. The Bash twin likewise uses its harness ROOT_DIR (`relay-automation/relay-drive.sh:157`). Call the existing resolver for `$T/.xyz` as well as `$T` (the latter covers consumer-root drivers), correct Recon, and exercise the vendored lock case in A4. This is one extra existing-resolver call, not a new detector.
  Observed input: the source's `driver_lock_path(root_dir)` with `root_dir = $T/.xyz`; a direct relative invocation from that directory, `python3 utils/py/relay_drive.py --relay-file relay-system/live.md --agent-cmd '<configured turn command>'`, has no absolute `$T/.xyz/` in its argv. During an idle/waiting turn the driver lock can be the only durable signal.
  Affected scope: a relay using the installed `.xyz` harness and relative argv, while the consumer-root lock is absent. An absolute-path subprocess may mask the gap temporarily but does not correct the lock lookup.
  Falsifier: in the disposable clone, hold only `$T/.xyz/.relay-driver.lock`, with no absolute-path process match. The skill must stop before backup/update and name that lock. If the actual vendored driver instead locks `$T/.git/relay-driver.lock`, this source-based finding is disproven. No live driver was launched in this review.

- **[Should] S2 — Include failed source fetch explicitly in the closed stop contract.** Step 1.2 fetches but the closed list includes only `cannot fast-forward` and `HEAD not equal to origin` for this part (`PROJECT/2-WORKING/GH-1486-RE-VENDOR-XYZ-SKILL.md:69,78`), followed by “Anything else continues.” A failed fetch can leave the old remote-tracking ref equal to HEAD; a subsequent merge/equality test does not establish fresh published state. State that any nonzero fetch stops, and retain its output; add that input to the existing manual verification, without adding a suite.
  Observed input: the plan's `git fetch origin <branch>` returning nonzero while the previously stored `origin/<branch>` equals HEAD. Neither subsequent condition in the stated closed list rejects that input.
  Affected scope: failure to fetch the selected source branch (network/authentication/missing ref), not ordinary target drift or optional collection absence.
  Falsifier: make the disposable source's origin unreachable while HEAD equals its cached remote-tracking ref. Expect `re-vendor-xyz: stopped: ...` before backup/update. If the extracted skill commands already terminate and report fetch failure explicitly, no further runtime mechanism is needed; make that rule explicit in the plan. This scenario was not executed here.

**Answers to the requested technical questions**

1. **[Pass] Recon's writer and drift claims are grounded.** Selection uses normalized exact equality (`xyz-sync.sh:193-197`); update delegates without flags (`:291-296`), and only `--all` invokes source safety (`:284-289`). VERSION is staged before the swap and runtime preservation precedes replacement (`xyz-vendor.sh:474-503`). The live-lock claim is wrong as detailed in S1. “Tier 2 kept only if releases.db” is accurate specifically for sync's no-flag invocation; direct vendor also accepts `--with-releases` (`xyz-vendor.sh:42-44,66-72`). Machine-local canonical configuration and the historical unchanged-since-base claim were not independently established.
2. **[Pass] Successful fetch plus merge and final equality rejects ahead and diverged histories as designed** (plan step 1.2: “`HEAD` equals `origin/<branch>`”). An ahead merge may succeed with “already up to date,” so equality is essential. Fast-forwarding a behind checkout intentionally changes its tracked files; this is explicit in the plan and issue. **[Nit]** Merge is not needed to prove publication: fetching and stopping unless equal is smaller, but requiring the operator to update separately adds friction. Either policy is reasonable; do not require a redesign. S2 concerns failure handling, not the successful sequence.
3. **[Pass] `$T/.xyz` is the right selector for ordinary registered nested repositories and spaces.** Selection compares normalized whole strings (`xyz-sync.sh:175,193-197`); `check` emits the raw install directory via `printf 'ok    %s\n'` (`:442-443`). Match that entire literal line, not whitespace fields, a regex, or a substring. Normalize `$T` physically to agree with vendor's `cd ... && pwd` (`xyz-vendor.sh:64`); registry aliases can otherwise produce a safe false stop. The missing-guard line includes a parenthesized suffix (`xyz-sync.sh:449-450`), so match the target followed by ` (` rather than requiring the bare prefix to be the whole line.
4. **[Should] S1 answers the missed live-run shape.** Relative argv defeats the absolute substring test, and checking the wrong lock matters directly to the #1011 protection. The process check is supplementary, not a proof of inactivity. A separate lock/journal/fleet service is unnecessary within this envelope.
5. **[Pass] The tier rule prevents the demonstrated downgrade.** `xyz-vendor.sh:66-72` automatically includes tier 2 when the root DB exists; a VERSION tier of 1 does not trigger the proposed stop (plan step 1.5). A tier-1 copy with a root DB becomes tier 2 by existing vendor policy; the skill should describe that accurately rather than promise immutable tiers.
6. **[Pass] Three-part currentness closes the registry/VERSION disagreement.** `check` reads selected registry fields (`xyz-sync.sh:427-431`), inspects the installed safety marker (`:434-439`), and can emit both messages (`:442-451`). Comparing installed VERSION source_commit with source HEAD (plan step 1.6) adds the missing copy-side provenance check. This is not whole-tree integrity; hand-edit detection is explicitly excluded in Preflight bet.
7. **[Pass] Step 1.9 delegates to the correct owner.** Explicit canonical selection avoids stale fallback (`skills-army-hq/SKILL.md:30-40,229-244`); that owner's preview/apply and verification procedure governs writes (`:160-173`). Treat its warnings and partial results as reportable, not “deployed skills current” merely because status exits zero (`:24-29,46-58`). The new skill's handoff does not itself authorize collection expansion or installing this new skill.
8. **[Pass] Acceptance has a meaningful skill-presence boundary, with distinct runtime limits.** A1 checks new file/name/triggers; A2 checks its stop/currentness instructions; A7 checks the three new pointers (plan Acceptance A1/A2/A7). Their claimed base red controls still need the clone run. A3's before-DRIFT/after-three-conditions is functional success, not a stop control. A4 must assert the named stop and no writer invocation as well as unchanged VERSION; bare exit 0 is only the contrast, not safety proof. A5 must observe rejection of “already current” before repair; eventual successful repair is allowed. A6 must observe no backup/update invocation; unchanged second-resolution vendored_utc alone cannot prove that. A3–A6 fail base only when the driver requires and extracts the new skill, as Verification promises (`PROJECT/2-WORKING/GH-1486-RE-VENDOR-XYZ-SKILL.md:99`); the underlying writer can already satisfy their happy-path state predicates.
9. **[Pass] The instruction-only scope is proportionate.** Existing sync/vendor writers and HQ collection ownership remain intact (plan Preflight bet and steps 1.8–1.9); pointers match `vendor-stack/SKILL.md:146-156`, `README.md:254-263`, and `ARCHITECTURE.md:145-147`. Markdown/docs routing matches `utils/ci-route.sh:63-68`. Required missing cases are S1/S2, not new automation. **[Nit]** The rollback sentence overstates the `.xyz` zip: it does not contain the registry or `.git/info/exclude` (plan step 1.7 vs Preflight bet Rollback). Describe it as recovery of the replaced copy; registry/exclude reconciliation belongs to their existing owners.

**VERDICT: FAIL**
**Basis:** Two bounded plan corrections remain: checking the lock that vendored relays actually hold, and explicitly refusing an unsuccessful source fetch. Runtime verification is deferred to the authorized disposable-clone stage; no runtime pass is claimed here.

Handing off to Producer (claude) — revise the plan for S1/S2, disposition every finding, then open Round 2; go to the Producer window and say 'take your turn'.

### Producer · Round 2 (claude)

Dispositions (plan doc `PROJECT/2-WORKING/GH-1486-RE-VENDOR-XYZ-SKILL.md` revised):

- **S1 vendored relay lock — Implemented.** Verified: `utils/py/relay_drive.py:115-118` sets `root_dir` to the harness the driver runs from and `:522` locks `driver_lock_path(root_dir)`; `utils/py/rtl.py` resolver returns `<root>/.relay-driver.lock` with no `.git`. Recon now states both lock shapes; step 1.4 checks `$T/.xyz/.relay-driver.lock` and the consumer-root lock (`driver_lock_path_for_repo "$T"`); the process match is described as a supplement. A crashed driver's stale lock also stops and is reported, never removed. A4 adds "vendored lock held, no matching process" and "consumer-root lock held".
- **S2 failed fetch — Implemented.** Step 1.2 stops on any nonzero `git fetch`; "fetch failed" added to the closed list; A4 adds the unreachable-origin case with `HEAD` equal to the cached ref.
- **Q2 Nit (merge not needed) — Declined.** Keeping `merge --ff-only`: a behind Forge checkout is the common case for a refresh, and making the operator update separately is the friction this skill removes. Equality after the merge still rejects ahead/diverged.
- **Q3 matching — Implemented.** Step 1.6 normalizes `$T` with `pwd -P`, matches the whole literal `ok    $T/.xyz` line by fixed string, and matches the guard line as a prefix `SAFETY GUARD MISSING $T/.xyz (`.
- **Q5 tier wording — Implemented.** Step 1.5 says a tier-1 copy with `releases.db` becomes tier 2 by the vendor's rule.
- **Q7 warnings — Implemented by reference.** Step 1.9 already hands writes to the `skills-army-hq` skill, whose status warnings the report repeats; no extra claim of "current" from an exit code.
- **Q8 observations — Implemented.** A4 asserts the named stop, no backup and no `update` invocation (driver logs writer calls) plus unchanged `VERSION`; A5 observes the "not already current" decision; A6 observes no backup and no `update` call instead of `vendored_utc`.
- **Q9 Nit rollback overstated — Implemented.** Rollback and step 1.7 now say the zip recovers the replaced copy only; registry and ignore lines stay with their owners.

Round 2 opened. Handing off to Reviewer (codex) — take your turn.

### Reviewer · Round 2 (codex)

**What this proposes.** Add one `/re-vendor-xyz` instruction-only skill for refreshing one registered repository's `.xyz/` copy through the existing sync/vendor writers. It checks published source, both driver-lock locations, processes and tier retention, backs up before replacement, and checks currentness before and after. It delegates deployed-skill updates to Skills Army HQ and adds three discovery pointers.

**How the existing system works, per this document.** Sync selects registry rows and calls vendor without tier flags; vendor stages source, preserves named runtime state, replaces the copy and records provenance. Sync's `check` uses registry metadata and separately inspects a safety marker, so `ok` alone is insufficient. A vendored driver locks under `.xyz/`, while consumer-root drivers use the shared resolver; collection updates have their own owner and preview/apply procedure.

**What it's not.** Per `non_goals` and Preflight bet: no first install, fleet refresh, script/helper changes, hand-edit detection, or deployment of this new skill into a collection or another person's machine. Refreshing already-installed Forge skills is the bounded Step 9 handoff, not collection expansion.

**Input boundary:** This paraphrase was formed after reading the relay and the plan's non_goals, Status, Recon, Preflight bet, Plan, Acceptance, Verification and Risks, before opening source or the issue. The whole-file display also included the title, other frontmatter and Rating rationale.

**Assessment: source-backed — Ship the plan.**
swept file: yes

Reviewed the entire plan, not only the Round 2 changes, and reread the required source and pointer surfaces plus issue #1486 and its first comment (`gh api`, exit 0). Applied the `swe` review rubric. Graph discovery was available this turn: `list_projects` had 86 entries with no exact task-worktree project; nearest canonical project `XYZ-forge` was ready, but coverage generation was `2026-09-01T15:54:30Z`. Symbol search returned an older `driver_lock_path` range; coverage reported changed/missing/untracked metadata and vendor's partial range 272. Therefore graph results were only provisional, and material claims below use this worktree's direct source, including that range. No index mutation was requested. No additional pre-existing defect was found in the plan during this sweep. This is a plan approval, not runtime qualification: all fixture/base-red claims remain **[Unverified — needs clone run]**. No git commands, suites, pytest, executable fixtures or phase gates were run.

- **[Pass] S1 closed: the two lock checks now correspond to the drivers.** Plan `PROJECT/2-WORKING/GH-1486-RE-VENDOR-XYZ-SKILL.md:71` names both the vendored lock and `driver_lock_path_for_repo "$T"`; Recon at `:52` explains them. `utils/py/relay_drive.py:115-118,522` derives and locks the harness root; `utils/py/rtl.py:983-1005` and `relay-automation/driver-lock-lib.sh:20-34` establish the vendored and consumer/worktree resolutions. A4 (`plan:92`) now includes a vendored lock with no process match and a consumer-root lock. Stale locks stop without deletion. No extra detector or lock service is required.
- **[Pass] S2 closed: unsuccessful fetch is explicitly a stop.** Plan `:69` says “stop on any nonzero exit”; the closed list `:78` includes “fetch failed”; A4 `:92` includes unreachable origin with equality to the cached ref. These clauses close the stale-ref failure without changing the writers.

**Answers to the requested technical questions** (plan citations below refer to `PROJECT/2-WORKING/GH-1486-RE-VENDOR-XYZ-SKILL.md`):

1. **[Pass] Recon's relevant contracts are grounded.** Exact selection is `relay-automation/xyz-sync.sh:193-197`; no-selection and missing-target exit-0 paths are `:241-246,282,292-295`; only fleet updates invoke source safety (`:284-289`). Vendor runtime carry-forward and VERSION staging are `relay-automation/xyz-vendor.sh:474-503`. The corrected lock claim is supported above. “Tier 2 kept only if releases.db” describes sync's no-flag call; direct vendor additionally supports `--with-releases` (`:44,66-72`). Historical unchanged-since-base and this machine's canonical key are assertions still requiring their implementation-stage receipts, not newly verified facts.
2. **[Pass] The published-source policy is sufficient for the stated ordinary origin/branch setup.** Plan `:69` requires successful fetch, ff-only merge and final equality. Ahead history cannot satisfy equality, and diverged history cannot fast-forward. Bringing a behind source current intentionally changes that checkout, explicitly documented at `:69`; merge is unnecessary for a reject-if-behind policy, but the Producer's keep-and-update choice is reasonable within the operator's refresh request. No requirement to stop merely for being behind.
3. **[Pass] Install-directory selection and literal output matching fit spaces and ordinary nested registered targets.** Sync normalizes the selector and compares whole paths (`:175,193-197`), then prints the raw install directory (`:443`). Plan `:73` requires fixed-string whole-line `ok` and the precise guard prefix including ` (`; this avoids substring/nested-row confusion. Physical normalization is explicit. A pre-existing registry alias spelling can still cause a conservative mismatch rather than a false success; no registry rewrite is required here.
4. **[Pass] The demonstrated relative-driver hole is addressed within this envelope.** Relative argv such as `python3 utils/py/relay_drive.py ...` lacks `$T/.xyz/`, but its vendored lock is now checked (driver/resolver citations in S1). The process scan remains supplementary (`plan:52,71`), not exhaustive process identity or atomic exclusion against a new run starting after the check. An instruction-only single-machine refresh cannot promise those stronger properties; adding locks, journals or fleet coordination would exceed this plan's envelope.
5. **[Pass] Tier handling matches the no-flag writer.** Vendor `:66-72` enables tier 2 from a root DB; Plan `:72` refuses the tier-2/no-DB downgrade and accurately allows tier-1/DB promotion. A tier-1 copy is not wrongly stopped by that predicate.
6. **[Pass] Three-part currentness is the correct bounded contract.** Sync reads registry provenance (`:427-431`) and installed guard text (`:434-450`), while Plan `:73` separately requires installed VERSION source_commit to equal source HEAD. Thus a current registry cannot mask an older VERSION. This does not establish whole-tree integrity, explicitly excluded at `plan:61`.
7. **[Pass] Skills Army remains the mutation owner.** Plan `:76` hands off after explicit-canonical read-only status. `skills/3-weekly/skills-army-hq/SKILL.md:30-40,160-173,229-244` owns source verification, preview/apply and warnings; `:24-29,46-58` forbids treating exit 0 or SKILL.md parity as full deployment readiness. The handoff inherits those requirements and authorizes no new collection membership or app targets.
8. **[Pass] Acceptance now distinguishes stops, successful refresh and no-op behavior.** A1/A2/A7 (`plan:89-90,95`) depend on the new skill/text/pointers; their existing regression suites alone would pass base. A3 (`:91`) demonstrates refresh with before-DRIFT contrast, not a stop. A4 (`:92`) now requires the named stop, no backup/update invocation and unchanged VERSION; its bare exit-0 contrasts are explicitly not safety proof. A5 (`:93`) observes rejection of “already current” before repair; A6 (`:94`) observes the skip decision and no writer invocation rather than a timestamp. A3–A6 depend on extracting the new skill's actual commands (`:99`), so base cannot pass through a separately implemented fixture algorithm. The promised base reds and fixture outputs must still be retained with provenance; none were executed this turn.
9. **[Pass] No additional machinery or required plan correction identified.** The one-file skill reuses the existing copy writer (`xyz-sync.sh:296`) and collection owner, with pointers into the existing surfaces (`ARCHITECTURE.md:145-147`, `README.md:254-263`, `vendor-stack/SKILL.md:146-156`). Markdown routing is supported by `utils/ci-route.sh:63-68`. The rollback wording now limits the zip to the replaced copy (`plan:63,74`). The accepted separate-skill decision is recorded in the issue's first comment and does not need reopening.

**VERDICT: PASS**
**Basis:** S1 and S2 are explicitly resolved, the remaining Round 1 observations were dispositioned, and no Blocker or Should remains against this instruction-only plan. Proceed to implementation and the already-planned disposable-full-clone verification; approval here does not claim that the unwritten skill or runtime fixtures pass.

Relay closed (Approved), no further turn needed.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
