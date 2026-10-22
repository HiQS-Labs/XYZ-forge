# RELAY · GH-1178 plan QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-22.
-->

NEXT: Producer
STATUS: Approved
ROUND: 1 / 3

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
6. **Commit only the relay file** (`relay(gh1178-plan-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: `PROJECT/2-WORKING/GH-1178-WAVE-RECONCILE-SHARED-DOC-REPOINT.md` (the plan —
  no code has changed yet). Requirements: https://github.com/HiQS-Labs/XYZ-forge/issues/1178.
- Source to read: `utils/py/wave_reconcile.py` (`find_active_doc_for_issue` :1070,
  `update_roadmap_entry` :1515-1560, `ledger_write` :1275, the landing loop :2309-2440),
  `utils/py/releases_app.py` `cmd_roadmap_repoint` :3770, fixture harness
  `test/gh421-auto-wave-reconcile.sh` (setUp / `apply` / `test_lifecycle_and_second_apply`).
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-10-22
- Operational envelope: a local post-merge reconciler CLI run by one operator or one CI job per
  repo. Grade against the issue's acceptance list and commensurate complexity — no multi-tenant or
  concurrency threat models. This repo forbids new test suites (`AGENTS.md` *No new tests*, GH-831):
  verification is a manual fixture check recorded under `TESTS-RESULTS/` plus existing suites.
- Definition of Done (plan): answers to these questions are all yes, or findings say what to change.
  1. Is the recon grounded — do the cited lines show the owning row repointed and the sharing row not,
     and is the claim "order-independent, so the fix must run after the landing loop" correct?
  2. Does the plan cover every acceptance item in #1178 (both rows repointed; red control; unmoved
     rows untouched; no new writer)?
  3. Does it extend the existing writer (`ledger_write` → `roadmap repoint`) and the existing owned-row
     check, with no parallel write path or second subsystem?
  4. Is anything wrong with repointing rows by exact `doc_path` match after the loop — e.g. dry-run
     (repoint refuses a missing destination), journal rollback, the `raw_text` path, rerun idempotency,
     a row in another repo, or an OPEN issue's row sharing the doc?
  5. Is it the smallest correct change? Flag any over- or under-building.
  Cite `file:line` for every claim.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer · Round 1

VERDICT: PASS
Basis: Ship the plan. The exact-source-path post-loop pass addresses the observed failure through the existing writer and ownership contract. Approval is for the plan, not runtime qualification.
swept file: yes

- [Pass] Swept the entire 104-line plan, including recon, implementation, acceptance, rating and lessons. No pre-existing defect requiring a plan revision found. The filename correction is accurate: `utils/py/wave_reconcile.py:1080` matches `GH-<number>-`/`<number>-`, not frontmatter. The owner supplies `doc_path` at `:2395`; the sharing branch at `:2406-2415` does not. Root cause: per-issue filename discovery cannot give a sharing row the moved destination; fix site: post-loop row repoint; why here: all moves are known and no earlier lifecycle update can overwrite the repaired embedded path.
- [Pass] Acceptance coverage is complete for #1178: plan A1–A5 (`PROJECT/2-WORKING/GH-1178-WAVE-RECONCILE-SHARED-DOC-REPOINT.md:82-93`) specify both row paths and raw text, both orders, the base red control, unmoved rows, rerun and canonical writer. Read-only requirements query `gh issue view 1178 --repo HiQS-Labs/XYZ-forge --json title,body` exited 0; decisive issue acceptance: “A row whose doc was not moved in this run is not repointed” and “the fix goes through `roadmap repoint`.” The proposed exact-match filter and writer satisfy those contracts.
- [Pass] Existing mechanics fit: `ledger_write` emits intent and returns before CLI execution on dry-run (`utils/py/wave_reconcile.py:1278-1283`), avoiding the destination-existence refusal (`utils/py/releases_app.py:3796-3798`). Real writes snapshot ledger artifacts (`wave_reconcile.py:1281`, `:1755-1775`); failures roll back (`:2484-2491`). `roadmap repoint` rewrites both path fields (`releases_app.py:3799-3811`). Reusing `identity_valid` AND exact repo equality (`wave_reconcile.py:1533-1536`, `releases_app.py:5440-5455`) excludes foreign/invalid rows. Repointing an owned OPEN sibling changes its file pointer only; the proposed helper contains no lifecycle update (plan `:61-64`, `:77-78`).
- [Nit] Plan `:65-66` describes real apply correctly, but dry-run leaves the owner row at its old path, so the final pass may print a second owner repoint intent. Clarify that “gets no second write” is an apply guarantee; duplicate preview intent does not justify simulated ledger state or extra machinery. Also `:43` means “after all relevant moves/updates” for this design; an all-row repair immediately after each owner update would also be order-independent, but the proposed final pass is clear and small.
- [Unverified — needs clone run] No executable fixtures, suites or runtime mutation probes were run in this reviewer worktree. The gh421 fixture supports the proposed manual exercise: `test/gh421-auto-wave-reconcile.sh:30` accepts `GH421_WAVE`, `:129-143` drives offline apply, and `:161-183` checks lifecycle plus second-apply mutation absence. Implementation qualification should retain nonempty row assertions and committed `provenance.jsonl` in the plan's evidence directory. A focused manual dry-run/foreign-row/OPEN-sibling/late-failure check can validate the stated boundaries without adding a suite.

Evidence scope: Verify tier; graph project `XYZ-forge` is the primary checkout, generation `2026-09-01T15:54:30Z`, not this relay worktree. Graph lookup was stale (e.g. old function line ranges); coverage reported changed source metadata and absent fixture/plan. Therefore the findings above rely on direct current-worktree source reads, not graph freshness. No artifact/source edits, git commands, or test execution performed.

Relay closed (Approved), no further turn needed. Producer may proceed with implementation and disposable-clone verification.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
