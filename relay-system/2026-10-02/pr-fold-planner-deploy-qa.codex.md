# RELAY · 2026-10-02 planner deployment ownership QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-02.
-->

NEXT: Producer
STATUS: Approved
ROUND: 1 / 1

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
6. **Commit only the relay file** (`relay(pr-fold-planner-deploy-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: committed fold branch at SHA bebdde27, especially the planner skill folders and skills/README.md. Compare with parent commit f72e1834 and the Skills Army HQ deployment contract. Read the earlier fold QA receipts for context.
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-10-02
- Definition of Done: independent read-only review of the operator's decision that app deployment goes through Skills Army HQ and Git Pulse Sync, with no new planner-specific installer. Check that the two newly added planner installers are absent, their skill instructions have no stale installer direction, the existing GH-678 installer safety suite still covers the remaining 24 legacy installers, and the new planner skills remain usable through the managed collection's intake/sync path. Distinguish this narrow PR #890 correction from the separate 24-installer migration. No new tests or gate machinery; do not run test suites in the relay worktree. An existing GH-678 focused run passed in a disposable full clone after the removal. Return PASS/FAIL/PARKED with citations, explicit `swept file: yes/no`, and any concrete remaining blocker.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer · Round 1 · codex

VERDICT: PASS

Basis: the narrow PR #890 deployment correction follows the existing Skills Army HQ / Git Pulse Sync ownership contract, removes both new installers, and preserves the legacy installer matrix and shared planner payload. No concrete blocker remains for this correction. This approves source/package compatibility, not a live deployment or the consolidated branch's runtime qualification.

swept file: yes

Scope: complete reads of both planner SKILL.md files, skills/README.md, the GH-678 suite, and planner_core.py; targeted reads of the existing intake/sync implementation and its deployment contract; both earlier fold QA receipts. Whole retained files changed by this correction were reviewed, including pre-existing text. No additional deployment blocker was established in them. The unchanged engine's planning algorithms are not being certified by this deployment review. Graph tools were unavailable; direct source and SHA-1-validated commit/tree/blob reads supplied evidence without invoking Git. Only this relay file and scratch probes were written; no suites, executable fixtures, application writers, commits or deployment ran.

- **[Pass] Exactly the requested removal and documentation correction.** Candidate `bebdde273e532975b19f10c849388524ad89feb7` names `f72e183488268b29b76e90104f2cfb13a7742db5` as its parent. Object comparison reports exactly four changed paths: deletion of `skills/2-daily/daily-planner/install.sh` and `skills/3-weekly/weekly-planner/install.sh`, removal of the install.sh layout entry from `skills/3-weekly/weekly-planner/SKILL.md:47`, and replacement of the direct-installer guidance at `skills/README.md:30`. Both complete planner instructions contain zero `install.sh` references. Probe: `PYTHONDONTWRITEBYTECODE=1 python3 .relay-scratch/ownership_probe.py`, exit **0**, decisive output `INSTALLERS_REMOVED ['skills/2-daily/daily-planner/install.sh', 'skills/3-weekly/weekly-planner/install.sh']`, `PLANNER_STALE_INSTALLER_REFERENCES 0`, `WORKTREE_REVIEWED_PATHS_MATCH True`, `ALL_STATIC_CHECKS_PASS`. Negative control: `PYTHONDONTWRITEBYTECODE=1 python3 -` loaded the same object reader and applied `assert not present` to these exact two paths in the parent tree; exit **1**, output `NEGATIVE_CONTROL parent_planner_installers_present` followed by both paths and `AssertionError: parent violates planner-installer absence predicate`. Initial loose-object-only probe attempts could not read packed trees; the completed probe handles packs and validates reconstructed object hashes. No fix requested.

- **[Pass] Deployment ownership is consistent with the existing manager.** `skills/README.md:30` says app links are owned by Skills Army HQ in the Git Pulse Sync collection and directs source-receipt refresh plus sync preview/apply. This matches `skills/3-weekly/skills-army-hq/SKILL.md:42` (“Canonical owning repo → Git Pulse Sync `Deployed Skills/` → app directory symlinks”), its add/update procedure at `:49`, and its prohibition on running copied installers at `:136`. This change introduces no installer, test, gate, dependency or parallel deployment mechanism. No fix requested.

- **[Pass] GH-678 still selects all 24 remaining legacy installers.** `test/gh678-installer-live-links.sh:12` loops over `skills/*/*/install.sh`, with foreign-live-link refusal assertions at `:24`, dangling-link replacement at `:33`, legacy-alias cases at `:42`, and a nonempty-discovery assertion at `:64`. The object comparison above reports `INSTALLER_COUNTS 26 24` and `LEGACY_24_SUITE_ENGINE_UNCHANGED True`; the current filesystem contains 24 matching installers, and each retained installer and the suite has the same blob as the parent. The comment at `:17` still says “22 installers”; that pre-existing count is not the discovery mechanism. This is coverage-selection/source evidence, not a new suite run. The separate 24-installer migration remains separate; no migration or safety-guard weakening is hidden in this correction. No fix requested.

- **[Pass] Managed intake retains the payload needed by both skills.** The read-only `skill_info` and `snapshot` functions (`skills/3-weekly/skills-army-hq/scripts/intake.py:98`, `:147`) accept both actual folders. The probe above prints `MANAGED_PAYLOAD daily-planner ['', 'SKILL.md']` and `MANAGED_PAYLOAD weekly-planner ['', 'SKILL.md', 'scripts', 'scripts/planner_core.py']`. Whole-folder staging uses `copytree` at `:572`; sync constructs each app link to `root / name` (`scripts/sync.py:98`, `:105`, `:126`). Thus deploying both folders preserves the weekly-owned engine used by daily (`skills/2-daily/daily-planner/SKILL.md:14`). The engine accepts an explicit target `--repo-root` independently of its own location (`skills/3-weekly/weekly-planner/scripts/planner_core.py:772`). No custom installer is needed. No fix requested.

- **[Nit] Existing invocation examples are environment-specific.** Daily's example at `skills/2-daily/daily-planner/SKILL.md:30` defaults to Claude's skills directory; weekly's examples at `skills/3-weekly/weekly-planner/SKILL.md:74` and `:101` use repository-relative paths. A device deploying only to another app must resolve the weekly engine from its managed collection and pass the intended repository root. Optional follow-up: document that physical-folder invocation and the requirement to intake both skills; do not restore a planner installer to solve it. This limitation predates the removal and does not prevent managed payload intake/sync. App discovery and runtime prerequisites remain separate checks under `skills/3-weekly/skills-army-hq/SKILL.md:65` and `:172`.

- **[Unverified — needs clone run] Runtime qualification.** Setup reports a passing GH-678 run after removal, but this turn did not independently inspect a corresponding committed run receipt or execute the suite. The harness must retain the disposable-full-clone qualification evidence; this source approval does not attest live app discovery, authenticated GitHub ingestion, or planner output correctness.

Relay closed (Approved), no further review turn needed. Producer / claude-a resumes the separate qualification/publication work; the harness owns the one-file commit. Reviewer closes the token with `done` as instructed for approval.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
