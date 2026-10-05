# RELAY · GH-970 final QA: deterministic task-clone names
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-05.
-->

NEXT: Producer
STATUS: Approved
ROUND: 3 / 3

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
   Reviewer headings may be `### Reviewer · Round N`, `### Round N · Reviewer · <agent>`, `### Reviewer (<agent>)` (optionally followed by `— rN`), or `### Reviewer — Round N` (optionally followed by `(<agent>)`); follow the heading with a non-empty review body.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(gh-970-final-qa-deterministic-task-clone-names): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: `skills/1-hourly/start-task/SKILL.md` (step 3), plus the rest of this branch's diff against the development base:
  `SOP.md` (fresh-clone example), `AGENTS.md` (branch carve-out line), `CHANGELOG.md` (GH-970 entry),
  `PROJECT/1-INBOX/GH-970-CLONE-NAMING.md`. Requirements: https://github.com/HiQS-Labs/XYZ-forge/issues/970.
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-10-05
- Definition of Done: the formula (folder `<repo-name>-gh<issue>-<very-short-desc>-<yyyy-mm-dd>` as a sibling of the
  primary; branch `<type>/<folder>`, type feat/fix/chore/docs) and its edge cases are stated unambiguously in
  start-task step 3; SOP and AGENTS agree with it and do not contradict other docs; text-only, no new tests or
  enforcement machinery (GH-831). Plan QA skipped as a simple text change; this is the final QA.

**Operational envelope.** Instruction text for agents. Grade clarity, consistency and conflicts with other repo docs.

**Questions.**
1. Is the rule unambiguous enough that two different agents would produce the same folder and branch for the same
   task? Name any gap (case of `<repo-name>`, date timezone, desc length, multi-issue, helper clones, resume).
2. Does anything else in the repo still describe task-clone naming/placement differently (grep `XYZ-forge-<topic>`,
   `agent-workspaces`, `marathon-clones`, `feat/<topic>`, other skills such as merge-cleanup-deep, jog, 10days,
   express)? Flag contradictions only; marathon lane branches `marathon/gh-<n>-*` are a stated non-goal.
3. Does `merge-cleanup`'s scanner (`--prefix`, `SAFE_ROOTS`, sibling `--root`) find clones placed this way?
4. Anything over- or under-specified? Cite `file:line`.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer · Round 1 · codex

VERDICT: FAIL
Basis: The requested naming shape is present, but the explicitly requested edge-case review found two ambiguities. Resolve them with text, without new machinery.
swept file: yes

Sweep: Read the complete primary artifact (start-task SKILL.md), SOP, AGENTS and GH-970 capture; checked the GH-970 CHANGELOG entry and searched naming references in other docs/skills. Historical CHANGELOG entries were searched for naming conflicts, not individually revalidated. No additional pre-existing defect found in the primary artifact beyond the issue-number ordering note below. No git commands, suites, executable fixtures, source edits or artifact edits were performed.

- [Should] **R1 — Define how variable name components are chosen.** skills/1-hourly/start-task/SKILL.md:86 permits any 2–4 lowercase kebab words; :87 says only “the day the clone is provisioned.” The same GH-970 task admits both XYZ-forge-gh970-clone-naming-2026-10-05 and XYZ-forge-gh970-task-clone-names-2026-10-05. Provisioning at 2026-10-06T00:30:00+00:00 yields Oct 5 locally or Oct 6 in UTC. The packet explicitly asks whether two agents produce the same name. **Fix:** identify one recorded task slug to reuse (or explicitly state description choice is discretionary), and specify the date timezone. Keep this a short instruction; no slug generator needed.
  Observed input: GH-970 title “start-task + SOP: deterministic task-clone folder and branch names” and the two valid descriptions above; :86–87 supply no selection or timezone rule.
  Affected scope: First provisioning of ordinary task clones; existing names stay unchanged on resume.
  Falsifier: The same recorded GH-970 slug and provisioning instant produce an identical folder/date for two agents; an existing older folder retains its original date.
  Probe command: Python stdin using datetime.fromisoformat("2026-10-06T00:30:00+00:00").astimezone(ZoneInfo(zone)).date() for UTC and America/Los_Angeles. Exit 0; decisive output: “UTC: 2026-10-06”, “America/Los_Angeles: 2026-10-05”. This measures an instruction ambiguity, not a runtime failure.

- [Should] **R2 — Distinguish task clones from helper matches during resume.** skills/1-hourly/start-task/SKILL.md:94 names helpers ending in -gate / -verify; :96–98 then says any matching sibling means resume. Both helpers match the wildcard. A task clone plus its gate clone supplies multiple matches with no selection rule; a helper alone is also described as a task resume. **Fix:** distinguish disposable helpers, locate the actual task clone by remote/branch/PR identity, and say to inspect/reconcile helper-only or ambiguous listings rather than arbitrarily choosing a folder or overwriting it.
  Observed input: XYZ-forge-gh970-clone-naming-2026-10-05 and the documented helper names XYZ-forge-gh970-clone-naming-2026-10-05-gate and XYZ-forge-gh970-clone-naming-2026-10-05-verify, all matched by XYZ-forge-gh970-*.
  Affected scope: Resume discovery with helper clones or multiple task candidates for the same issue.
  Falsifier: Task-plus-gate resolves to the task; gate-only does not resume implementation in the helper; two task candidates are reconciled rather than arbitrarily selected.
  Probe command: Python stdin with fnmatchcase(name, "XYZ-forge-gh970-*") for those three names. Exit 0; decisive output: all three report “resume-pattern=True”. No directories or executable fixtures were created for this probe.

- [Nit] **R3 — Resolve the issue before constructing the name.** Step 3 provisions/names the clone at skills/1-hourly/start-task/SKILL.md:78–98, but “Create any missing issue first” appears at :104; :110 preserves trivial intake exemption. **Fix:** clarify before provisioning that the issue number must already be known, and define the naming fallback for an issue-exempt task or state that this rule requires a tracking issue. This is an instruction-order clarification, not a request for mandatory new intake machinery.

- [Pass] **Requested format and ordinary scope agree.** skills/1-hourly/start-task/SKILL.md:84–95 states exact-case repo name, sibling placement, full folder branch suffix, four types, lowest issue number and helper suffixes. SOP.md:216–230 mirrors the formula and points to step 3; AGENTS.md:63 authorizes the same four types. CHANGELOG.md:8–12 and PROJECT/1-INBOX/GH-970-CLONE-NAMING.md (“folder `<repo-name>-gh<issue>-<very-short-desc>-<yyyy-mm-dd>`”) agree. Propagate accepted clarifications where needed.

- [Pass] **Scanner supports sibling names when the parent is scanned.** skills/2-daily/merge-cleanup/scripts/scan_clones.py:1053–1065 walks immediate children and filters case-insensitively by substring, so these repo-prefixed names qualify. Its :1299 / :1308 accepts an explicit root; skills/3-weekly/merge-cleanup-deep/SKILL.md:75–79 already supplies `--root "$(dirname "$PRIMARY")"`. Default roots are only the four locations at scanner :26–31; arbitrary primary parents need an explicit root. This is source inspection, not an end-to-end scanner run. No scanner code change requested.

- [Nit] **Cleanup documentation still describes old placement.** skills/2-daily/merge-cleanup/SKILL.md:106 attributes creation in the listed safe roots to /start-task; this now depends on the primary location. **Fix:** replace that attribution with legacy/marathon discovery wording and mention the explicit sibling-root option already used by merge-cleanup-deep. SOP.md:87 is explicitly a campaign clone at :92–95; 10days/start-marathon locations are excluded by GH-970’s marathon non-goal, so those are not task-clone contradictions.

- [Unverified — needs clone run] Docs gate and final changed-path scope are not attested by this turn. The user prohibits git commands and gate/suite execution here; the harness/Producer must supply the final docs-gate receipt and confirm text-only scope. Requirement query `gh api repos/HiQS-Labs/XYZ-forge/issues/970 --jq '{title: .title, body: .body}'` exited 0 and returned the operator formula, edge cases and marathon/enforcement non-goals.

Evidence boundary: list_projects has no index for this review worktree. The nearest XYZ-forge index targets the primary and reports generation 2026-09-01T15:54:30Z; scanner lookup returned zero nodes. Coverage marked relevant paths missing/not-tracked/metadata-changed or excluded, so material claims use current worktree source rather than stale graph evidence.

Handing off to Producer (claude-a) — disposition the findings, make accepted text clarifications, and open the next review round.

### Producer · Round 1 · claude-a

- **R1 — Implemented.** `<very-short-desc>` is now the issue's capture-doc slug lowercased (the repo already names that doc `GH-<n>-<SLUG>.md`), with a recorded once-only choice where no capture doc exists; the date is the machine's local date at first provisioning and never changes on resume.
- **R2 — Implemented.** Resume lists `<repo-name>-gh<issue>-*` ignoring `-gate`/`-verify` helpers; exactly one task clone resumes; two or more, or helpers only, are inspected and reconciled, asking the operator if still ambiguous; never resume implementation in a helper.
- **R3 — Implemented.** Step 3 now says to resolve the tracking issue before naming, and gives the issue-exempt form `<repo-name>-<very-short-desc>-<yyyy-mm-dd>`.
- **Nit (merge-cleanup SKILL.md:106) — Declined (scope).** That file is a full-gate surface (`utils/ci-route.sh:336`); a one-line attribution edit would move this text-only change to the full gate. Its wording is still true for legacy and marathon clones; parked in `PARKED/2026-10-05-gh970-merge-cleanup-wording.md` for a later merge-cleanup change.
- CHANGELOG and capture doc updated to match.

Round 2: please re-review.

### Reviewer · Round 2 · codex

VERDICT: FAIL
Basis: The GH-970 naming changes satisfy the requested clarification. One pre-existing instruction conflict in the primary artifact needs a short text correction; no new machinery or tests.
swept file: yes

Sweep: Read the complete start-task SKILL.md, reviewed the SOP/AGENTS naming surfaces, capture and CHANGELOG entry, and searched the other skills for naming/placement contradictions. Rechecked scanner discovery source. No additional pre-existing finding beyond R4 below was identified in the primary artifact. Historical CHANGELOG entries were searched for naming references, not revalidated as individual changes.

- [Pass] **R1/R3 resolved.** skills/1-hourly/start-task/SKILL.md:83–93 defines the issue-before-naming rule, exact-case repo name, lowercase capture-doc slug (or a once-recorded 2–4-word choice), machine-local first-provisioning date, immutable resume date, and issue-exempt form. The recorded slug removes repeated discretionary naming; identical machine/date/task inputs produce the same folder. SOP.md:216–230 and AGENTS.md:63 agree with the folder/branch types. No further naming edit requested.
- [Pass] **R2 resolved.** start-task SKILL.md:102–112 explicitly excludes helpers, verifies clone/branch/remote/PR/HEAD, and reconciles multiple or helper-only matches rather than selecting arbitrarily. The quoted instruction “never resume implementation in a helper” addresses the failing helper-only input from Round 1. No further helper edit requested.
- [Pass] **Sibling discovery remains supported.** skills/2-daily/merge-cleanup/scripts/scan_clones.py:1053–1065 scans immediate children and filters case-insensitively by substring; :1299–1308 supports explicit roots. skills/3-weekly/merge-cleanup-deep/SKILL.md:75–79 supplies the primary's parent as a root. Arbitrary parents still require that explicit root. Source review only; no scanner execution.
- [Nit] **Accept the deferred cleanup wording disposition.** PARKED/2026-10-05-gh970-merge-cleanup-wording.md:3–8 records the old attribution and concrete sibling-root follow-up. This is nonblocking legacy discovery wording, not a request to expand GH-970 into scanner changes. No further action in this turn.
- [Should] **R4 — Make the docs-gate shortcut conditional on the classifier (pre-existing).** start-task SKILL.md:221–224 first says to select the actual route, then says every Markdown/text-only change, “including skill instructions,” uses the documentation gate instead of the full suite. That contradicts the concrete full-gate Markdown inputs at utils/ci-route.sh:333–343, and explains the Producer's otherwise correct gate-cost disposition above. Fix only :222–226: say the docs gate applies when the classifier routes the changed paths as docs; text extensions do not override classified full-gate surfaces. Keep the existing classifier authoritative, with no new gate or duplicated registry.
  Observed input: A diff changing only skills/2-daily/merge-cleanup/SKILL.md (the precise file considered in the Producer's nit disposition). It satisfies the blanket Markdown shortcut at start-task :222–224, while utils/ci-route.sh:336–337 sets full_required=true for that path. WORKTREE-SAFETY.md is another explicit counterexample.
  Affected scope: Verification instructions for Markdown/text changes that the existing classifier marks full-required; ordinary docs retain their current route.
  Falsifier: If the existing classifier did not mark those exact Markdown paths full-required, the exception would be unnecessary. Expected result after clarification: merge-cleanup SKILL.md follows the full route; ordinary start-task SKILL.md follows its docs route. This is an observed source-level instruction conflict, not an executed gate failure.
  Evidence command: "sed -n '318,346p' utils/ci-route.sh" and "nl -ba skills/1-hourly/start-task/SKILL.md | sed -n '78,235p'". Exit 0 for both reads; decisive output: "WORKTREE-SAFETY.md|skills/*/merge-cleanup/SKILL.md)" followed by "full_required=true", versus “a Markdown/text-only change ... uses the deterministic documentation gate ... not ... the full validate.sh suite.”
- [Unverified — needs clone run] The docs gate and final changed-path scope remain harness responsibilities. No git command, gate, suite, pytest or executable fixture was run; no artifact/source file was changed.

Evidence boundary: Verify tier; list_projects pagination completed (77 projects), with no index for this worktree. Nearest XYZ-forge graph targets the primary. Coverage reports metadata-changed, missing/not-tracked, or excluded for the reviewed paths; current worktree source is the evidence. No graph completeness claim.

Handing off to Producer (claude-a) — disposition R4, make the short classifier-first text clarification, and open Round 3.

### Producer · Round 2 · claude-a

- **R4 — Implemented.** `start-task` step 7 now says the docs gate applies when `utils/ci-route.sh` routes the changed paths as docs, that the classifier decides rather than the extension, and names `WORKTREE-SAFETY.md` and `skills/*/merge-cleanup/SKILL.md` as Markdown that follows the full route. No new gate, no duplicated registry.
- Nit (parked cleanup wording) — acknowledged; it rides with the GH-789 port, which already edits that full-gate file.

Round 3: please re-review R4 only; R1–R3 passed in round 2.

### Reviewer · Round 3 · codex

VERDICT: PASS
Basis: R4 is resolved by a classifier-first instruction consistent with the cited full-gate paths. R1–R3 remain resolved; the deferred cleanup wording remains nonblocking. Approval covers this textual QA, with deterministic gate evidence still required from the harness before landing.
swept file: yes

Sweep: Read all 351 lines of skills/1-hourly/start-task/SKILL.md, rechecked its naming instructions against the SOP/AGENTS surfaces and the GH-970 capture/CHANGELOG entry, and compared R4 with current classifier source. No additional pre-existing defect found in the primary artifact. Round 1/2 discovery and scanner findings stand; no fresh exhaustive repository or changed-path claim is made.

- [Pass] **R4 resolved.** skills/1-hourly/start-task/SKILL.md:222–227 now says “The classifier decides, not the file extension” and restricts the documentation shortcut to paths classified as docs. Its explicit WORKTREE-SAFETY.md and skills/*/merge-cleanup/SKILL.md exceptions agree with utils/ci-route.sh:336–337, which sets full_required=true for those inputs. Fix complete; no further change requested.
  Evidence commands: `nl -ba skills/1-hourly/start-task/SKILL.md` and `nl -ba utils/ci-route.sh | sed -n '328,343p'`. Exit 0 for both reads; decisive output: “when utils/ci-route.sh routes the changed paths as docs”, “The classifier decides, not the file extension”, and “WORKTREE-SAFETY.md|skills/*/merge-cleanup/SKILL.md)” followed by “full_required=true”. Source comparison only; no gate execution.
- [Pass] **Earlier accepted naming clarifications remain present.** start-task SKILL.md:83–112 retains issue-before-naming, exact-case repo name, recorded capture slug, machine-local first-provisioning date, issue-exempt form, sibling placement, four branch types, lowest grouped issue, helper exclusion and resume reconciliation. SOP.md:216–230 delegates the full rule to step 3; AGENTS.md:63 lists the same four types. No further naming change requested.
- [Unverified — needs clone run] Deterministic docs-gate success and the final branch's text-only changed-path scope are not attested here. The harness must verify them against the final revision. No git command, validate.sh, test/*.sh, pytest, executable fixture, or artifact/source mutation was performed.

Evidence boundary: Verify tier. list_projects returned all 77 projects (has_more=false), none for this worktree. Nearest XYZ-forge index targets the primary; coverage generation is 2026-09-01T15:54:30Z and reports not-tracked, metadata-changed, missing or excluded for the cited paths. Current worktree source supplies the evidence; no graph completeness claim.

Relay closed (Approved), no further review turn needed. Producer (claude-a)/harness owns the file-scoped commit and final gate verification.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
