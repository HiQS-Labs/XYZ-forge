---
gh_issue: 453
source: https://github.com/HiQS-Labs/XYZ-forge/issues/453
title: Governance document identity audit
status: Stage 1 report — Stage 2 awaiting maintainer approval
updated: 2026-09-05
owner: Codex
goal: Establish document ownership and propose corrections without changing governance authority.
created: 2026-09-05
doc_type: feedback
effort: 3
complexity: 3
risk: 2
phases: 2
---

# GH-453 — Governance document identity audit

## Status

| What was just completed | What's next |
|---|---|
| Stage 1 report independently approved; documentation and ledger checks passed with warnings recorded. | Maintainer decision on proposed dispositions; Stage 2 remains unapproved. |

## Quad Concepts

- Mixed document authority → separate subject, maintenance and XYZ applicability.
- Stale factual claims → check each principle against bounded evidence.
- Sync overwrites → trace provenance before proposing a durable disposition.
- Policy changes → stop after the report for maintainer approval.

## Scope

Execute Stage 1 of [the revised audit prompt](../1-INBOX/CODEX-GOVERNANCE-DOC-AUDIT-PROMPT.md).
Produce one report with the ownership/applicability inventory, exact proposed corrections,
strategy trade-offs, confirmed/refuted nearby drift, evidence limits and non-goals.
Stage 2 governance edits require explicit approval of that report.

## Table of contents

- [Stage 1 — report](#stage-1--report)
- [Stage 2 — approved corrections only](#stage-2--approved-corrections-only)

## Initial recon and rating

Base: `9a8eb8a59ea2ce9617a77149e198505bb2263f04`, fresh clone from canonical remote,
branch `fix/gh453-governance-audit`, origin/development base. Git hooks installed and checked.
The original issue body remains unchanged; the revised prompt incorporates its review comment.

Instruction path: ROUTER → AGENTS → PROJECT/PDDA; ROUTER calls the constitution policy of record.
Import path: upstream pdda-sync manifest → runtime tree plus PROJECT/PDDA.md; startup docs are
separate opt-in installer copies. XYZ's build-launch-artifact PROJECT_SCAFFOLD retains all five
PROJECT governance files. Local sync policy protects registered local behavior even in imports.
No file removal or rename is proposed; deletion inventory is empty for this report-only phase.

Rating rationale (2026-09-05): RELEASES read-back `70/65/50/55` (priority/severity/appeal/cheapness),
rank 240, no operator override. Misread policy can misdirect agents and sync review, but no new
loss-of-work incident is established. Medium research effort: small document set, mixed history.
Appeal is neutral. Related evidence: issue #406's review and #414's comment-reference audit concern
misstated contracts; they do not prove another instance of this ownership confusion. Searched issue
metadata for governance/PDDA over 2026-08-23..2026-09-05 versus 2026-08-09..2026-08-22 (the query
included 2026-08-08 as a boundary buffer). Results mix features, duplicates and defects; distinct
incident counts and trend are unknown, with no recurrence multiplier. The supplied reviewer
misreading is one reported example, not a measured rising rate.

## Stage 1 — report

1. Record audit/base and upstream SHAs, graph freshness and coverage limits; enumerate the required
   eight documents from disk → expect non-empty inventory with one row per path.
2. Inspect registration, callers/test references, introduction history, upstream manifest and
   provenance for each row → expect subject, maintenance, local authority and protected behavior
   separated; unknown classifications remain ambiguous.
3. Inspect every numbered principle and relevant conventions against bounded source evidence →
   expect confirmed/contradicted/unresolved rows and exact proposed text for falsified claims.
4. Refresh nearby findings, compare at least the path-preserving, banner, relocation and charter
   options, and write disposition/non-goals/approval questions here → expect complete report with
   no governance policy edits and no assertions of sync persistence without evidence.
5. Run relevant report/intake checks and independent Codex report QA → expect attributable results
   or explicit failures; submit the concrete report and stop for maintainer approval.

### QA checklist

- [x] Every requested file and numbered principle has a row; evidence boundaries are explicit.
- [x] Missing upstream provenance or local-authority ambiguity is not silently resolved.
- [x] Revised prompt retains the original requirements, except expressly corrected statements.
- [x] Only prompt, intake/report, ledger projections, review evidence and a new CHANGELOG
  end-of-iteration entry changed; no historical changelog rewrite.
- [x] Review and hygiene results are recorded honestly; no Stage 2 completion claim.

The final reviewer gets an omission-diff question comparing the issue-body requirements, revised
prompt and report. A report can fail on a missing row, unsupported authority decision or absent
required replacement text. There is no new runtime gate in Stage 1, so mutation testing a new
implementation is inapplicable. Stage 2's link checker must reject empty input, missing file and
missing heading; eventual evidence goes under test/baselines/gh453-governance/ with provenance.

### Verdict and evidence boundary

Keep the existing paths and distinguish **subject**, **maintenance**, and **authority in XYZ**.
Do not label every PDDA-related document “not XYZ Forge policy.” In particular, that would negate
XYZ's own sync-review policy. Extend the existing GUIDING-PRINCIPLES Purpose section for XYZ's
charter, with README pointing to it; do not create a parallel scope document.

This is a proposal, not an adoption decision. Inspection is pinned to XYZ base
`9a8eb8a59ea2ce9617a77149e198505bb2263f04`. The working branch changes the prompt, intake/report,
ledger projections and evidence only. References below use base file:line unless stated otherwise.
The knowledge graph used was `Users-noelsaw-Documents-GH-Repos-XYZ-forge`, generation
`2026-09-06T02:27:59Z` (UTC; September 5 locally), Verify tier. Coverage reported
`metadata_match` / `no_recorded_issue` for candidate governance documents, kernel files and launch
retention paths. That is not completeness proof. The fresh clone is not indexed: material claims
were checked in its source; documentation, literals, history and missing paths used direct reads.
The claim trace covered inbound and outbound depth 1; it does not establish every harness path.

Upstream references are pinned independently:

- [PDDA manifest](https://github.com/Hypercart-Dev-Tools/pdda/blob/2a762f28432da074794e5adfa845108cfe037601/utils/pdda/pdda-sync-manifest.conf#L16): runtime directory plus PROJECT/PDDA.md, excluding the sync machinery itself.
- [Predecessor tree](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/tree/67dd324487c1fc470b2c539f1cebe2a9c3fb3651): all four non-PDDA.md PROJECT governance files are byte-identical to this reference.
- XYZ import metadata: `utils/pdda/PDDA-SOURCE.md:9`; local sync-review contract:
  `PROJECT/PDDA-SYNC-POLICY.md:11–14,35–58`.

The current PDDA manifest does not establish every historical installation's saved manifest.
Some bundled installation documentation is newer than that remote snapshot. No sync replay was
performed. No recommendation below is a claim that arbitrary `--force` installation preserves edits.

### Ownership, registration and disposition inventory

“Repo-owned” below means protected local maintenance/disposition under the sync-review policy,
not original authorship. Import origin and protected local behavior can coexist. Registration in
ROUTER or a release consumer is positive local evidence; lack of a dedicated test is not permission
to delete. Coverage here records consumers, not an assertion that tests prove policy semantics.

| Path | Subject | Classification and settling evidence | XYZ applicability and proposed disposition |
|---|---|---|---|
| `PROJECT/CONSTITUTION.md` | PDDA scope and governance | **Repo-owned inherited policy; broader authority ambiguous.** ROUTER:18 registers policy of record; launch scaffold:138–144 retains it. Predecessor `1019503` introduced it in an aider-studio sync; `2ad905e` adopted the GH-144 synthesis/mode work. Absent from inspected PDDA manifest. | Keep path; identify predecessor origin and PDDA subject. ROUTER adoption and Constitution:21–23 are positive local authority signals. Clarify the PDDA-only advisory-review rule before any claim that it governs all XYZ reviews. No replacement/removal. |
| `PROJECT/DO-NOT-BUILD.md` | PDDA anti-scope, with broad governance-layer parenthetical | **Repo-owned inherited policy; extent of adoption ambiguous.** ROUTER:19 and launch scaffold:143; predecessor introduction `1019503`, GH-144 provenance. Absent from inspected PDDA manifest. | Keep path; explain PDDA product boundary separately from XYZ's own scope. Maintainer must settle applicable entries below. No replacement/removal. |
| `PROJECT/PDDA-MODE-GUIDE.md` | PDDA mode selection | **Repo-owned inherited guidance.** Constitution:54–55 links it; launch scaffold:140 retains it; predecessor `2ad905e` introduced it for GH-144. Absent from inspected PDDA manifest. | Keep; banner says local guidance for using PDDA in XYZ. Correct dead heading references after approval without changing PDDA mechanics. No replacement/removal. |
| `PROJECT/PDDA-SYNC-POLICY.md` | XYZ review of PDDA updates | **Repo-owned explicitly.** Its line 11 says so; AGENTS requires it before sync approval; launch scaffold:141. Predecessor #416 commits `d55e53b` / `5bfb1a5`, correction `a7b7367`, protect behavior lost at `cfd56b0`. | Binding XYZ policy. First line should say exactly that. Never prepend “not XYZ Forge policy.” No replacement/removal. |
| `PROJECT/PDDA.md` | PDDA document contract as used by XYZ | **Sync input with repo-owned protected adaptations; treat disposition as repo-owned guardrail candidate.** Upstream manifest:17, local sync policy:11–14; ROUTER:17,27 and launch scaffold:139 register local use. Current file differs from upstream. | Keep current canonical path. State upstream origin plus local adoption and sync-review protection. A local-only banner here could be overwritten; use durable repo-owned routing/README clarification and pursue an upstream origin marker only through a separately approved upstream change. No replacement/removal. |
| `GUIDING-PRINCIPLES.md` | XYZ product/runtime priorities | **Repo-owned.** AGENTS names it canonical; ROUTER role/startup routing; predecessor introduction `80d95d5`. PDDA installer startup-doc path is separate create-only opt-in, not the sync manifest. | Keep; fix factual drift and extend existing Purpose for charter. No parallel scope document. No replacement/removal. |
| `AGENTS.md` | XYZ agent behavior | **Repo-owned.** ROUTER startup registration and explicit “What this file owns”; predecessor introduction `35c2653`; optional upstream startup template does not make this local policy disposable. | Keep; retain existing policy ownership split and link to approved charter wording. No policy weakening. No replacement/removal. |
| `ROUTER.md` | XYZ routing and canonical authority | **Repo-owned.** AGENTS directs startup here; predecessor introduction `f8811c3`; optional installer template is not ordinary dependency sync. | Keep; refine role table, fix stale hosted-CI paragraph, resolve every startup path after approved changes. No replacement/removal. |

XYZ public history introduces these inherited files together at `1f0a5bf1` (initial public release),
so public introduction alone cannot settle earlier intent. The predecessor history supplies that
missing context. No dedicated semantic-policy test was established for Constitution, anti-scope
or mode guide; their positive routing and launch registration already prevent treating them as
unattached upstream debris. The checked test/reference scope was `test/pdda*`, the local PDDA
checks seam and launch builder, not an exhaustive proof about every repository test.

**Deletion inventory: empty.** Neither Stage 1 nor the recommended path-preserving disposition
removes, moves or renames a file. Relocation is evaluated as an alternative, not approved for
execution. If selected later, inventory all source paths and apply all five classification tests
again to the actual diff, including replacement equivalence and explicit local sign-off.

### Missing provenance: recovered source, not invented upstream attribution

The four cited sources are absent from XYZ. They are present in the predecessor, not in the
inspected PDDA tree. Proposed Stage 2 replacements are pinned links to:

- [GH-144 synthesis, now archived under 4-MISC](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/blob/67dd324487c1fc470b2c539f1cebe2a9c3fb3651/PROJECT/4-MISC/GH-144-PDDA-FEEDBACK-SYNTHESIS.md).
- [Perplexity feedback](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/blob/67dd324487c1fc470b2c539f1cebe2a9c3fb3651/PROJECT/1-INBOX/PDDA/FEEDBACK-PERPLEXITY.md).
- [ChatGPT feedback](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/blob/67dd324487c1fc470b2c539f1cebe2a9c3fb3651/PROJECT/1-INBOX/PDDA/FEEDBACK-CHATGPT.md).
- [Gemini feedback](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/blob/67dd324487c1fc470b2c539f1cebe2a9c3fb3651/PROJECT/1-INBOX/PDDA/FEEDBACK-GEMINI.md).

The synthesis archive move is visible at predecessor `0a18a78`. Constitution:9 also names a relay
transcript; its provenance was not independently verified in this bounded audit. Do not claim the
entire evidence chain is complete or replace that reference speculatively.

### Strategy and trade-offs

| Option | Benefit | Cost / durability | Recommendation |
|---|---|---|---|
| Move under `PROJECT/vendor/pdda/` | Ownership is visible in the path. | Mislabels locally owned files; breaks routing, relative links and launch scaffold; moving PDDA.md conflicts with upstream manifest and may be undone. Requires deletion classification and actual importer review. | Reject for this change. |
| Keep paths and use one blanket “not XYZ policy” banner | Small diff and fast visual cue. | False for sync policy and adopted contract; erases existing local authority. A banner in sync input can disappear. | Reject blanket wording. |
| Keep paths, use per-file provenance/authority wording and correct repo-owned routing | Reuses current consumers, reversible, preserves local guardrails and upstream distinction. | Reader must see nuanced authority wording; PDDA.md first-line marker needs upstream cooperation or an explicit approved preservation mechanism. | Recommended, with the sync durability condition below. |
| Add a new XYZ charter file | Clearly separate product scope. | Duplicates existing GUIDING Purpose and README scope; creates another canonical text to maintain. | Prefer extending GUIDING Purpose and pointing README to it. |

Suggested first-line pattern for the four inherited local PROJECT files:
“**Subject: … · Maintained by XYZ Forge (inherited from [predecessor]) · Authority in XYZ: …**”.
For sync policy, authority is “binding review policy for PDDA dependency updates.” For mode guide,
“guidance for selecting PDDA's mode.” Constitution/anti-scope wording must reflect the maintainer's
specific adoption decision, not silently make one. The upstream PDDA repository can be linked as
technology origin without claiming it owns those four files.

For PDDA.md, recommend an upstream-owned portable subject marker plus the durable XYZ-owned
routing clarification. Until that marker or an explicitly approved preservation mechanism is in
place, the original “every PROJECT file clear within one line after future sync” acceptance target
is **not fully satisfied**. Do not claim a local banner alone solves it; do not add a new sync hook
or behavior change in this issue. A maintainer may instead accept the narrower local-document and
routing fix while tracking the upstream marker separately.

### Does the anti-scope parenthetical bind XYZ?

The parenthetical is evidence of intended governance-layer reach, not authority to ban XYZ's
existing execution system. ROUTER registers it as PDDA anti-scope, while Constitution explicitly
extends verified-success to all agents. These are different adoption signals.

| Entry (DO-NOT-BUILD line) | Assessment for XYZ |
|---|---|
| Generic spec framework / PRD-to-tasks product (16–17) | Consistent with current README:174–177, but capability overlap does not prove an adopted prohibition on every planning feature. Propose retaining that product boundary in XYZ's charter. |
| Generic multi-agent platform / marketplace (18) | Marketplace exclusion matches README. A blanket orchestration ban conflicts with XYZ's stated coordination/relay purpose. Do not apply that ban to its core product. |
| Full Kanban before stable CLI/MCP (19) | Conditional sequencing advice, not evidence that all dashboards are forbidden. Adoption unresolved. |
| Replacing commodity Markdown linting (20) | Consistent with the canonical reuse principle. Apply as a preference to extend/reuse existing checks, not permission to remove local contract checks. |
| New Bash or policy complexity (21) | XYZ independently has stronger Python/frozen-twin rails in AGENTS. Those already govern; do not weaken them to this older measured-gap wording. |
| Replacement for agent instruction formats (26–28) | Consistent with existing ROUTER/AGENTS role split. Preserve it without creating another policy system. |
| Large AI agile methodology (29–31) | Reasonable proposed product boundary, but final adoption belongs to the maintainer. Does not prohibit the existing capture → rate → plan → preflight → execute → gate → land → record workflow. |

Constitution:34–35's “LLM … may never block” applies to PDDA advisory checking. Extending it to all
XYZ quality review would conflict with this repository's required relay approvals. Clarify the
boundary in local routing; do not rewrite PDDA's actual policy in this task.

### Every numbered principle checked

“Supported” means a bounded implementation supports the statement, not universal correctness.
Normative goals cannot be certified by a code scan. Existing base-suite results are separate from
proof of each policy claim.

| Principle / line | Inspection and verdict | Proposed action |
|---|---|---|
| 1 Local coordination / 51 | **Supported for tick kernel.** `src/claim.js:33–35` folds local events; `src/events.js:117` appends locally; `src/identity.js:5` records removal of Git transport. `bin/tick:21` discovers local Git root, not per-event remote transport. | Retain, explicitly read as coordination kernel, not every harness integration. |
| 2 Canonical events / 53 | **Overbroad/partly false.** `src/project.js:341–355` writes `.tick/STATE.md`; claim reads/folds events directly at `src/claim.js:34–35`. RELEASES is a separate canonical ledger. | Replace text below; scope canonical-event claim to tick and remove “reads go through projection.” |
| 3 Containment / 55 | **Normative; mechanisms present, absolute guarantee unproven.** `utils/py/rtl.py:727–749` delegates before/enforce/worktree operations. AGENTS documents shared Git-state limitations. | Retain requirement, do not describe worktree isolation as machine-wide safety. Fix Purpose's absolute guarantee. |
| 4 Skill guard / 57 | **Conditional mechanism.** `relay-automation/hooks/relay-xyz-guard.sh` handles configured hook events; it is not enforcement for every possible CLI runtime. | Qualify the guard sentence below. Skill-first remains policy. |
| 5 Adversarial proof / 59 | **Normative.** Concurrency/containment suites exist; this audit did not map all feature claims to red controls. | Retain requirement; historical universal coverage unresolved. |
| 6 Durable changes / 61 | **Normative, consistent** with North Star:7–22. Code cannot prove every change removes its root cause. | Retain. |
| 7 Minimal code / 63 | **Contradicted** by tracked package.json/lockfile and `src/acorn-extract.js:4–5`. Bounded import scan from bin/tick and its local modules found built-ins/local imports, not Acorn. | Exact replacement below; kernel-only dependency statement. |
| 8 Operator decides / 65 | **Normative with bounded mechanisms.** Relay driver caps turns; observed exits include 5 and 8 in this task as well as listed examples. No all-path no-loop proof. | Retain operator authority; treat menu as examples, avoid claiming exhaustive validation. |
| 9 Resumable docs / 67 | **Contradicted/overbroad.** ROUTER:34–38 names RELEASES DB; `.tick/events` and runtime receipts hold execution state outside PROJECT. ROADMAP.md is retired here. | Exact replacement below and appendix repoints. |
| 10 Verified done / 69 | **Normative, measurable.** validate and PDDA entry points exist; independent relay required. This report is Stage 1, not completion of Stage 2. | Retain; run suites only in disposable full clones per current safety rails. |
| 11 Issue-first / 71 | **Supported workflow contract** by ROUTER:38 and CLI intake; #453 is parked/rated. Cannot prove universal historical compliance. | Retain. |
| 12 Independent grading / 73 | **Wired but conditional.** `utils/py/codex-turn.py:135` → rtl.enforce → `relay-turn-lib.sh:1352–1389` validates reviewer blocks when its prerequisites hold. `bin/tick:266–281` supports release validation with optional relay-file flag. | Retain as required policy. Do not claim every release path is structurally gated; broader enforcement audit is separate. |
| 13 Red controls / 75 | **Normative.** No new decision gate is built here; historical completeness not established. | Retain; future link resolver must reject empty input, dead file and dead heading controls. |

### Exact proposed corrections

These are **proposed text**, not edits to the governing documents.

Replace line 3:

> North star for **XYZ Forge**, the multi-agent coordination harness behind the `tick` event-log kernel and `relay-automation/` relay stack. When a choice is unclear, the option that keeps agents synchronized, contained, and verifiable — without leaking or destroying work — wins. AGENTS.md is the behavioral playbook; ROUTER.md is the entry-point map; this is the *why*.

Replace principle 7:

> 7. **Least code that clears the bar.** The `tick` coordination kernel uses Node's standard library. The repository also ships `package.json` and `package-lock.json` for Acorn-based source analysis. Prefer reusing or extending what exists; the smallest change that stays correct, contained, and durable wins. Net-new code is a cost to justify. Deleting code counts as progress.

Replace principle 2:

> 2. **One canonical event log for tick coordination.** `.tick/events/` records coordination events; `.tick/STATE.md` is a derived view. Coordination verbs read and fold the events and append changes through the event API. Other subsystems retain their own documented sources of truth, including the RELEASES roadmap ledger. Do not create competing copies of canonical state.

Replace principle 9:

> 9. **Docs support resumable work (PDDA).** ROUTER points to the governing contracts; the RELEASES DB owns this repository's roadmap ledger, and ROADMAP-DASHBOARD.md is its generated view. Linked PROJECT documents hold plans, decisions and handoff detail; CHANGELOG records dated outcomes. Resume execution using those documents together with the relevant runtime state and evidence. If current documentation contradicts the implementation, correct it or explicitly record the unresolved discrepancy.

Replace principle 4's guard sentence only:

> In sessions that install and invoke the `PreToolUse` hook, `relay-automation/hooks/relay-xyz-guard.sh` checks supported driver invocations for the skill's setup evidence; this is not a guarantee that every runtime invokes that hook.

Replace Purpose:36, subject to maintainer approval of the charter:

> XYZ Forge is a local-first operations system for humans directing agents across their repositories: capture → rate → plan → preflight → execute → gate → land → record. Its `tick` kernel coordinates local claims through an event log and exclusive locks; its relay and Marathon tooling drive bounded build and review work. Containment controls reduce accidental writes but do not guarantee safety outside their enforced boundaries; linked worktrees share Git state. The product prioritizes coordination, recoverability and verifiable outcomes. It does not aim to be a general spec or PRD generator, an agent marketplace, or enterprise application lifecycle management. The operator remains the decision authority.

Replace the strict-mode convention body at lines 87–100:

> Python is the default implementation for the twelve frozen Tier-A entry points. Existing Bash bodies are compatibility fallbacks selected with `XYZ_PYTHON=0`; their strict-mode choices remain subsystem-specific. Consult each existing script's header and error handling before changing it. New executables under `utils/` or `relay-automation/` follow AGENTS.md's Python and exception rules. This section does not authorize edits to frozen Bash twins.

Evidence: early Python dispatch in `utils/marathon-plan.sh` and `utils/swarm-preflight.sh`, and
AGENTS runtime-default / frozen-twin / no-new-Bash rails. The old universal claim that every exempt
script has a header was not exhaustively verified and should not survive as an unchecked assertion.

Replace the builder-default bullet at 135–141:

> **Builder default is `codex`.** Marathon's current implementation defaults to Codex; agy is another supported builder. Choosing Claude remains an explicit, cost-acknowledged operator decision under AGENTS.md. Actual billing depends on the selected tool's authentication and account configuration; a default executable name does not establish a billing guarantee. The Python implementation is the default, with the existing Bash fallback available through `XYZ_PYTHON=0`.

Evidence: `utils/py/marathon_drive.py:963` and marathon.sh builder default. Billing promises cannot
be verified from repository code; this proposal removes the unconditional promise rather than
claiming a current vendor price. Plan-location enforcement at `relay-automation/marathon.sh:145–176`
supports the documented working-directory rule and MARATHON_HOME/environment exceptions. Retain it.

In appendix item 5 replace “no execution detail in ROADMAP.md” with “no execution detail in the
roadmap ledger or its generated dashboard”; in its final rejection bullet replace “ROADMAP.md”
with “the roadmap ledger”. The tool-install convention is normative/operator-controlled; this audit
did not verify historical workstation paths or claims that two lanes have “never” had the incident.
Those historical assertions remain **unverified**, not newly certified.

### Refreshed nearby findings and proposed issue boundaries

| Original item | Finding at pinned base | Recommendation |
|---|---|---|
| 9 Modes | **Confirmed stale comment:** `.pdda-mode:4` says light moves docs; `PROJECT/PDDA.md:876` says no mutation, `utils/pdda/pdda-lib.sh:46–55` flags and gates only full. **Qualify equivalence:** dispatcher:1484–1486 prints different mode labels; observe/light share the inspected exit gate, not literally all behavior. | Correct the local comment in Stage 2. No checker behavior change. Broader mode redesign is separate. |
| 10 Missing heading | **Confirmed:** `PROJECT/PDDA-MODE-GUIDE.md:61,69` cite absent “Check severity contract.” Dispatcher:919,949,1117 explicitly ignores heading anchors. The predecessor GH-144 commit added a table that the present import lacks. | Repair local guide references to existing authoritative content after checking semantic equivalence; if the missing table's details have no current authority, say unresolved rather than inventing a heading. Checker enhancement belongs separately. |
| 11 Hosted CI | **Partly stale finding:** README:37 now states local plus hosted gates; ROUTER:66 still says hosted CI fires on nothing while private. Workflow ci.yml:98–103 triggers push/PR main/development; GitHub repository metadata reports public. A trigger is not evidence of a run for a particular SHA. | Correct ROUTER in Stage 2; no README private-claim fix remains. Do not claim hosted attestation without an actual run. |
| 12 Skills | **Original count/list outdated:** direct `skills/*/SKILL.md` enumeration is 49; ARCHITECTURE index has 44 distinct linked skill paths, including start-task:73. Missing browserbase, converge, dry, merge-cleanup, workhorse. | Separate small index-maintenance issue/work item; no need to broaden ownership changes. No claim about nested/global skills. |
| 5 XYZ scope | **Refuted now:** README:162–177 has explicit XYZ scope and anti-scope. GUIDING Purpose exists but lacks the full workflow/product boundary. | Consolidate canonical charter in existing GUIDING Purpose and point README to it; do not assert the project has no scope statement. |
| 8 Operator reference | **No longer present:** current README has no `§8` citation; it links GUIDING at 198–199,283. GUIDING does have numbered principle 8, but not numbered section headings. | No stale-reference patch needed at this base. Use heading plus named principle for any future citation. |
| New README attribution | **Contradicted:** README:196–198 labels all five sync inputs and disclaims XYZ policy. Manifest plus explicit sync-policy ownership refute it. | Correct in this ownership change, naming PDDA.md as imported contract and the other documents' local maintenance/adoption separately. |
| Package name | **Confirmed:** root package name still predecessor identity. | Record only; separate decision as requested. Do not change package name or lockfile. |

### Stage 2 acceptance and remaining decisions

Approve the path-preserving strategy, the exact proposed XYZ principles corrections, and the
specific adoption boundary for Constitution/anti-scope before execution. Also decide whether the
PDDA.md first-line marker is a prerequisite or a separate upstream follow-up; without that decision
this report does not promise a durable all-five first-line outcome.

After approval, sweep current references in ROUTER, ARCHITECTURE, README, HOW-TO-USE, SOP, AGENTS,
skills and PDDA consumers; retain historical CHANGELOG entries. A bounded resolver should cover
changed governance docs and their current top-level inbound references, report unrelated baseline
defects separately, and test both missing files and headings with non-empty input controls. The
four provenance links should point to the verified predecessor snapshot. Required Stage 2 gates
remain PDDA run, tier 1, full validate for changes outside PROJECT, and targeted governance. Run
mutation-heavy suites in a separate disposable full clone and compare Git identity before/after.
Finally inspect all ROUTER startup targets and every PROJECT document's first line. These checks
have **not** been claimed as completed for unimplemented Stage 2 edits.

## Lessons Learned (For Future Agents)

- A file can discuss another project and still be a locally adopted rule. Track subject, maintenance
  and applicability separately; a reassuring blanket banner can silently withdraw a guardrail.
- Public-release history can flatten provenance. Consult the predecessor and the actual current
  import manifest before inventing an upstream owner or declaring a file disposable.
- Refresh “verified” observations at a pinned base. README scope and skill counts had already changed.
- Review output must satisfy the actual structural validator. A prose approval label and a successful
  model response are not substitutes for a machine-valid verdict or a successful driver result.

## Stage 2 — approved corrections only

Not authorized. Its exact scope and executable sequence will be set from the maintainer-approved
report, then reviewed before edits. It must preserve the user's upstream-policy, checker-behavior,
frozen-twin, package-name and historical-CHANGELOG exclusions. No deployment or merge authorized.

## Risks and rollback

Stage 1 is Easy: a separate branch contains report-only work; no governance behavior changes.
The later authority decision is Costly until the maintainer settles adoption and sync ownership.
Rollback for approved future edits is a scoped revert of this task's commits, followed by sync
and link verification; do not overwrite shared working files from Git or clean up valued clones.
No competing writer or system is introduced: existing RELEASES CLI owns all ledger changes.

## Evidence and execution log

- Initial source checks: upstream manifest names runtime + PDDA.md; launch scaffold names all five.
- Preflight full suite exited 0 on the unchanged base; Git identity stayed intact. Five pooled
  failures passed automatic single-suite retries. This is not proof of reliable parallel execution.
  Evidence: TESTS-RESULTS/2026-09-05+GH-453/provenance.jsonl and validate.log.
- Report/intake PDDA aggregate exited 0 (24 warnings, no errors); frontmatter and status-table
  checks exited 0. Changelog reminder addressed by a new dated entry, without rewriting history.
- Upstream PDDA reference: `2a762f28432da074794e5adfa845108cfe037601`; its manifest
  (`utils/pdda/pdda-sync-manifest.conf:16–23`) distributes only runtime + PROJECT/PDDA.md.
- Predecessor reference: `67dd324487c1fc470b2c539f1cebe2a9c3fb3651`; all four non-PDDA.md
  PROJECT governance docs are byte-identical to that predecessor. Constitution/anti-scope were
  introduced at `1019503`, mode guide at `2ad905e` for predecessor #144, sync policy via #416.
  The four missing provenance sources exist in the predecessor: synthesis moved to PROJECT/4-MISC;
  three feedback docs remain in PROJECT/1-INBOX/PDDA. They are not in the current PDDA repo.
- The current README's “all ... sync inputs / not XYZ Forge policy” paragraph contradicts that
  narrower manifest and the locally owned sync policy; include this refreshed drift in the report.
- Independent plan review passed: relay driver exit 0, STATUS Approved and VERDICT PASS.
  Thread: relay-system/2026-09-05/gh453-plan-qa.md. The first model attempt was unsupported;
  the first substantive review requested the CHANGELOG allowance and had an invalid verdict shape.
  Both were corrected; no guard was weakened.

### Final Stage 1 verification

- Independent report review: `relay-system/2026-09-05/gh453-report-qa.md`, driver exit 0,
  STATUS Approved, VERDICT PASS. Its non-blocking suggestion is retained for Stage 2: preserve
  the normative/implementation/history/external distinction when drafting final principles.
- `./validate.sh --tier 1`: exit 0 on candidate `3eadeb7f` in the disposable full clone.
  Warnings include unavailable issue-state lookups and pre-existing completed-document drift;
  they are not silently reported as checked or fixed.
- `GH_REPO=HiQS-Labs/XYZ-forge bash utils/pdda/pdda.sh run`: exit 0, 23 warnings, no errors.
  The explicit slug lets the local-origin test clone query the intended GitHub project.
- `GH_REPO=HiQS-Labs/XYZ-forge bash utils/pdda/pdda.sh governance`: exit 0, 8 warnings.
  Existing reference/discoverability findings remain outside this report-only change.
- `python3 utils/py/releases_app.py check`: exit 0, 0 failures, 8 migration-debt warnings.
  An earlier attempted `roadmap check` was rejected as an unsupported verb (exit 2); the supported
  top-level check above was then used. No ledger was hand-edited.
- Pre/post Git identity for the candidate checks matched. Logs and hashes are retained under
  TESTS-RESULTS/2026-09-05+GH-453/final-stage1 and provenance.jsonl.
- Full `./validate.sh` was run on the unchanged base only (exit 0 after five serial retry
  recoveries). It was not rerun on the report candidate; Stage 1 requires relevant report/intake
  hygiene, while the full candidate suite remains a Stage 2 requirement for the proposed edits.
- Changes following report approval are status/check receipts and the required Lessons Learned
  heading level only; no ownership conclusion, proposed policy or runtime implementation changed.

## Non-goals

No policy adoption/rejection, governance moves/deletions, upstream publications, code changes,
package rename, new sync mechanism, historical-log repairs, merge or clone teardown.
