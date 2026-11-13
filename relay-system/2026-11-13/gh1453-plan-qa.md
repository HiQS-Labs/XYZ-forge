# RELAY · GH-1453 plan QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-11-13.
-->

NEXT: Reviewer
STATUS: Open
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
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
   Reviewer headings may be `### Reviewer · Round N`, `### Round N · Reviewer · <agent>`, `### Reviewer (<agent>)` (optionally followed by `— rN`), or `### Reviewer — Round N` (optionally followed by `(<agent>)`); follow the heading with a non-empty review body.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(gh1453-plan-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: `PROJECT/2-WORKING/GH-1453-JOG-LOCAL-RECONCILE.md` (sections `## Recon`, `## Preflight bet`, `## Plan`, `## Acceptance`, `## Verification`, `## Risks`). This is a **plan review**: no production code has been written yet.
- Reviewer: codex   ·   Producer: claude
- Started: 2026-11-13
- Operational envelope: a local developer CLI (`releases_app.py jog run --checkpoint-root`), one operator per primary clone, one code file changed (`utils/py/jog_run.py`) plus skill text. Other sessions push to the same `development` branch; that is the case this plan exists for. Grade against the issue's acceptance and commensurate complexity. Do not grade against enterprise or multi-tenant threat models. The repo forbids new tests, suites, registry entries or gate machinery (AGENTS.md *No new tests*, GH-831); verification is existing suites plus manual checks recorded under `TESTS-RESULTS/`.
- Out of scope: per-transition publication (GH-1108 delivery 2), the per-task preflight fetch, merge-cleanup and `ledger_merge.py`, moving the ledger out of the repo (GH-1224).
- Definition of Done: the plan is grounded in the cited paths, extends the existing `JogCheckpoint` and the canonical ledger writers, and its acceptance checks would each fail on the unchanged tree.

### Step A: paraphrase first (GH-1414). Do this BEFORE reading anything else.
Read ONLY the plan doc's `## Status`, `## Recon`, `## Preflight bet`, `## Plan`, `## Acceptance`,
`## Verification`, `## Risks` and its frontmatter `non_goals`. Do not open source files or the issue
yet. Then, at the top of your review block, write:
- **What this proposes** (2–5 sentences)
- **How the existing system works, per this document** (2–5 sentences)
- **What it's not** (short; ground exclusions in the doc's sections and label any inference)
- **Input boundary:** list which sections you had read when you wrote the paraphrase.

### Step B: source-backed technical validation
Now read the requirements and source:
- Issue: https://github.com/HiQS-Labs/XYZ-forge/issues/1453 (its body proposed touching `ledger_merge.classify`; the plan doc supersedes that and does not).
- `utils/py/jog_run.py`: `_git` (1116-1121), `promote_contract_to_working` (1677-1810), `JogCheckpoint` (2106-2203), `jog_run_main` (2250-2547).
- `utils/py/releases_app.py`: `perform_write` (1662-1790), `_require_jog_primary` (4717), `jog_acquire_lease` / `jog_set_status` (5072-5135), `jog_reconcile_orphan_leases` (5138-5200), the `op_receipts` schema (601-612).
- `utils/releases-merge-resolve.sh` (whole file, 250 lines), `.gitattributes`.
- `skills/2-daily/merge-cleanup/scripts/ledger_merge.py:145-260` (`classify`, for the rejected alternative only).
- `skills/2-daily/jog/SKILL.md:140-170`; `AGENTS.md` (Danger list, *No new tests*, GH-527 rail).

Label this assessment **source-backed**. Answer each question with `file:line` evidence:

1. Are the Recon claims true at the cited lines? In particular: is it true that, with a separate execution clone, the only writes a checkpoint wake makes to the primary ledger are `jog-lease`, `jog-<status>` and `jog-reconcile`? Name any other writer the wake can reach in the primary.
2. Plan step 1 removes the start fetch and equality check and adds "no commit on HEAD absent from the local `origin/development` ref". Does anything else in the run depend on the primary equalling the remote at start? Is the local-ref check sufficient to keep unrelated unpublished commits from being published by the wake?
3. Plan step 3 runs `git merge --no-commit --no-ff origin/development` in the primary, takes the remote side of the two ledger files with `git checkout --theirs`, rebuilds, replays, runs the resolver and commits. Is each command legal under AGENTS.md for a valued checkout, given the tree is clean and the wake's ledger is committed? Is `git merge --abort` a complete restore on every failure path listed in step 5, including after `check --rebuild` has replaced `releases.db` and left `releases.db.bak`?
4. Replay correctness: does replaying the wake's `op_receipts` in order through `jog_acquire_lease` / `jog_set_status` / `jog_reconcile_orphan_leases` reproduce the wake's final `status`, `attempt_count`, `failure_reason` and queue positions on the remote ledger, given the overlap check passed? Name a concrete sequence of writes where it would not, and say whether the plan's final-state verification catches it.
5. Generation floor: `utils/releases-merge-resolve.sh` refuses a dump whose generation is below either merge parent. Does "one replayed write per original write" guarantee the floor? Name a case where it falls short and what the plan does then.
6. Identifying the wake's writes by "`op_receipts` rows after the recorded `txn_id`": is that reliable given how `op_receipts` ids and `check --rebuild` behave? Is there a simpler reliable marker already available?
7. What prevents an unchanged, unfixed tree from passing each acceptance item A1–A6, and is the stated red control the right observation? Distinguish checks that prove the reconcile happened from checks that only prove nothing crashed.
8. The repeat in step 3.8 (remote moved again during the push): is the second merge sound when the first merge commit is already the primary's HEAD and the publication clone has already fast-forwarded to it?
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

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
