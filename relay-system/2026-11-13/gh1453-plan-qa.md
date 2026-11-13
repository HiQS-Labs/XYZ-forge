# RELAY · GH-1453 plan QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-11-13.
-->

NEXT: Producer
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

### Reviewer · Round 1

**What this proposes:** Start a checkpoint wake using only the primary's local state, then publish once at completion. If development moved, merge its changes and replay this wake's ledger receipts through the existing Jog writers, checking overlap and final row state before publishing.

**How the existing system works, per this document:** The checkpoint currently fetches at startup and requires HEAD to equal the published branch. Lease/status writes remain local until finish commits the ledger and pushes through a publication clone; a moved remote rejects that push and leaves the journal committed for retry.

**What it's not:** Per-transition publication, changes to execution-clone preflight, B1/merge-cleanup, or moving the ledger outside the repository (frontmatter non_goals and Preflight bet).

**Input boundary:** Frontmatter non_goals, Status, Recon, Preflight bet, Plan, Acceptance, Verification, Risks only; no source or issue read before this paraphrase.

**Assessment: source-backed.**
swept file: yes

Reviewed the complete plan, including its pre-existing Recon and Risks; pre-existing defects in the touched checkpoint are called out below. No source, fixture, test or Git command was executed. Only the relay was edited. Runtime merge/abort and full acceptance rehearsals are **[Unverified — needs clone run]**.

Evidence scope: graph discovery used project `XYZ-forge` (nearest indexed root is the main checkout, not this relay worktree), generation `2026-09-01T15:54:30Z`. Both project-list pages were inspected. Coverage reported changed metadata for the two Python files and resolver, and untracked metadata for B1; graph results lack the current checkpoint. Accordingly all material conclusions below use current source reads, not stale graph completeness.

- **[Should] F1 — Specify a recoverable state after a committed reconcile, including retry exhaustion and crashes.** Plan 3.7 commits the merge and replaces the journal commit; step 5 promises that `merge --abort` restores the original checkpoint. Once committed there is no merge to abort. After a second attempted merge, abort restores the *first merge*, not the original checkpoint. Existing recovery only recognizes one parent equal to base plus the original publication message (`utils/py/jog_run.py:2164-2171`), so a crash between reconcile commit and journal save is also rejected. Keep the original replay source separately from the current publication head, define the durable journal transitions and resume recognition, and preserve the latest valid merge on publication failure rather than promising an impossible abort. Check cleanup of unstaged rebuilt DB/views separately; abort is not a substitute for a demonstrated restore.
  Observed input: plan 3.7 → push rejected three times → step 5; also crash just after the merge commit and before `save()`. The document explicitly sends both into recovery designed for the original single-parent commit.
  Affected scope: moved-again retries, post-commit failures and resume of a reconcile checkpoint.
  Falsifier: disposable-clone rehearsal of these exact boundaries leaves a clean, journal-consistent primary and publication clone and resumes without task dispatch; assert which committed head is retained. Include a failure after rebuild but before staging to prove DB/view restoration and backup cleanup.

- **[Should] F2 — Do not replay global orphan detection against the remote queue without bounding its effects.** `jog_reconcile_orphan_leases` scans every running row and probes local PIDs (`utils/py/releases_app.py:5145-5164`); the SQL dump deliberately serializes every lease PID as NULL (`:1273-1278`). Rebuilding the remote ledger therefore makes remote running rows appear orphaned. The proposed verification of only wake-changed rows misses collateral changes to other rows. Record/replay the original reconcile's row effects through suitable existing status operations, or establish and verify an equivalent bounded procedure; do not blindly rerun the global detector.
  Observed input: source predicate `WHERE status = 'running'` plus dumped `NULL AS lease_pid`. Concrete sequence: base has orphan A; wake reconciles A, leases A and parks A; remote independently introduces running B. Rebuild gives B a NULL PID; replaying the first reconcile resets B to pending although B was not changed by the wake. A can still match the wake's final triple.
  Affected scope: a wake containing a jog-reconcile receipt and a disjoint remote running row.
  Falsifier: rehearse that sequence and require B's remote status/attempt/reason/position to survive unchanged while A reaches its expected result; no orphan replay should mutate B.

- **[Should] F3 — Complete the merge algorithm for cleanly merged paths and remote code-only movement.** Plan 3.4 takes `--theirs` only on conflicted files, but requires the entire remote ledger as replay input. A cleanly merged dump has no unmerged stage 3 to take. Conversely step 3.3 commits before the resolver, then 3.7 rebuilds and asks for another merge commit; the resolver always rebuilds, stages and deliberately does not commit (`utils/releases-merge-resolve.sh:139-151,226-246`). Select the remote dump deterministically whether or not the textual merge conflicted, keep the merge open through validation/resolution, and commit exactly once.
  Observed input: plan 3.3 says “commit the merge and go to 3.7”; 3.7 then runs the resolver and “commit the merge.” Also a remote change of releases.sql is not itself proof that releases.sql has an unmerged stage.
  Affected scope: remote code-only commits and any clean textual ledger merge.
  Falsifier: two manual variants, remote code-only and cleanly merged dump, each publish a clean, consistent merge containing the intended rows with no unresolved stages or second accidental checkpoint commit.

- **[Should] F4 — Address the pre-existing adopted-view ownership failure.** The checkpoint owns only two files and refuses every other dirty path (`utils/py/jog_run.py:2113,2135-2138,2163`), but every canonical write calls refresh_preview (`utils/py/releases_app.py:1767`), which can rewrite adopted RELEASES-PREVIEW.html and LEADERBOARD.html (`:1364-1393`). An ordinary wake can therefore fail at finish before either old publication or new reconciliation. Treat legitimate generated outputs consistently through checkpoint ownership/commit/restore, or use an existing supported projection setting with an explicit contract. Include an adopted-view fixture rather than proving only the no-view case.
  Observed input: existing `RELEASES-PREVIEW.html` or `LEADERBOARD.html` with projections enabled, followed by jog-lease/status changing its rendered content; finish classifies that path as foreign.
  Affected scope: checkpoint primaries that adopt these generated views.
  Falsifier: a wake with adopted views finishes cleanly and preserves unrelated dirt refusal; repeat with moved development and check the generated views agree with the final ledger.

- **[Should] F5 — Route canonical writer refusals through the promised stop/cleanup path.** Step 4 catches ContractError, but canonical writer refusal calls `sys.exit(code)` (`utils/py/releases_app.py:209-211`); e.g. lease/status refuse a missing or ambiguous queue identity (`:5084-5093,5118-5124`). Specify conversion/handling at the replay boundary so a refused replay reaches rollback and the checkpoint-held message. Include constructor errors in the protected call scope as well (`utils/py/jog_run.py:2119-2122,2358`).
  Observed input: replay target GH-N has no row, or matches two repositories; writer raises SystemExit, not ContractError.
  Affected scope: refused canonical replay and checkpoint construction.
  Falsifier: controlled writer refusal during an open merge exits 2 with checkpoint-held, no traceback, no open merge, clean retained committed state and retryable journal.

- **[Should] F6 — Tighten the manual acceptance contract and its claim of red-on-base.** A4 explicitly expects unchanged behavior, so the unchanged tree *must* pass it; this contradicts the Setup DoD that every acceptance check fails on base. Label A4 a preservation check. A2 proves start admission but does not require publication from a genuinely stale local tracking ref; A1 should assert actual merged remote/wake row values and lineage, not just phase/check clean. Add moved-again and failure-boundary variants to the existing manual checks to cover F1/F3/F5; no new suite. Normalize timestamp/receipt/PID differences for A4 rather than promising byte-identical live DB trees across independent runs.
  Observed input: A4 “With no remote movement ... match base”; A2 stops at “The wake starts”; A1 includes no repeat-push case.
  Affected scope: the plan's manual verification and stated DoD.
  Falsifier: preservation checks pass base; change checks fail base for the stated reason; candidate rehearsals inspect final data, committed ancestry, cleanliness and recovery, with nonempty receipts retained in the specified TESTS-RESULTS directory.

**Answers to Step B (1–9):**

1. **[Pass]** The primary's canonical ledger-op claim holds for this operational envelope: promotion returns before primary roadmap repoint (`jog_run.py:1764-1767`); real auto-merge is refused before the loop (`:2261-2265`); the loop uses lease/status and startup reconciliation (`:2362-2369,2414,2449`). Cold recovery also calls jog_set_status (`:474,480`), not another op family. Additional reachable writes are generated HTML views and local connector dispatch/cursors through perform_write (`releases_app.py:1767-1784`), plus the documented local execution cache. “Only ledger writes” must not be read as “only filesystem writes.”
2. **[Pass]** No other start-equality dependency was found in the cited run path: task work validates and runs in the separate execution clone (`jog_run.py:2329,2396-2408,2444-2448`). Testing that HEAD is an ancestor of the local tracking ref excludes commits absent from that ref; the finish head/message check still protects against mid-wake primary commits (`:2164-2171`). This is sufficient under the stated ordinary shared-branch envelope, not proof against remote history rewriting. Missing tracking ref should produce a named stop.
3. **[Pass]** The proposed bounded conflict checkout is not the forbidden tree-restoring checkout: AGENTS.md:7 names `git checkout -- <path>`; the canonical resolver itself uses conflict-stage checkout (`utils/releases-merge-resolve.sh:133,187`). Merge/rebuild/resolver/commit are not prohibited under the stated clean, committed ownership premise. The blanket restoration claim is false after commit (F1); restoration after unstaged rebuild/view writes remains **[Unverified — needs clone run]**. Rebuild replaces the DB and writes .bak (`releases_app.py:6654-6660`), which Git abort does not remove.
4. **[Should]** Ordinary lease/status replay can recover the requested final triple: lease increments attempts and status sets reason (`releases_app.py:5095-5101,5125-5135`). Status also shifts *other active rows' positions* (`:5128-5131`); final triple verification alone does not establish all queue ordering or remote preservation. A wake-reconciled row whose old PID is now live can fail final-state verification (safe stop), whereas the remote-B sequence in F2 can pass that verification with collateral mutation. Include queue identity/order and untouched remote rows in replay reasoning and manual observations.
5. **[Should]** The “one replayed write per original write” explanation assumes each replay actually writes. An orphan reconcile may return without a receipt if no orphan exists (`releases_app.py:5163-5164`), so that count is not guaranteed. More fundamentally rebuild already chooses `max(dump_gen, old_gen)+1` (`:6568-6570`); the resolver checks the floor *before* its rebuild (`utils/releases-merge-resolve.sh:110-120`). For repeated merges the HEAD parent is the prior reconcile, not the original checkpoint. A remote rebuilt DB with fewer replayed writes can fall below that prior parent's generation, especially when earlier original reconcile calls become no-ops on replay; the resolver then stops, as planned. State the actual generation argument for the chosen algorithm, including this retry case, instead of the unconditional write-count guarantee. Do not pad with unrelated writer calls.
6. **[Should]** txn_id is a UUID4 (`releases_app.py:188-189`), not sortable time. The plan can reliably use it as an *anchor*, resolve its id in the original checkpoint DB and enumerate ORDER BY id after that anchor. It must not compare txn_id lexically or carry a numeric id across rebuilt databases; load_dump recreates ids (`:6530-6535`). Simpler in this fixed original-DB scope: record newest receipt id with the base (and handle an empty log); txn_id identity remains useful if rebuilds can intervene. Specify which convention. Read-only probe, exit 0: `python3` with `sqlite3.connect('file:releases.db?mode=ro', uri=True)`; queries `SELECT count(*) FROM op_receipts WHERE id>(SELECT id FROM op_receipts WHERE txn_id=?)` and `SELECT count(*) FROM op_receipts WHERE txn_id>?` using marker `7f7e78624ed143beb4227a425e1a9670`. Decisive output: `after marker by id: 1` versus `after marker lexically: 1478`. Probe created no data files.
7. **[Pass]** A1 distinguishes base's rejected push (`jog_run.py:2193-2195`), A2 its startup equality refusal (`:2153-2157`), A3 the new named overlap/restore behavior, A5 actual resumed reconciliation, A6 the new skill section versus its current open-ended stop wording (`skills/2-daily/jog/SKILL.md:158-164`). A4 is regression preservation, not a red-on-base case (F6). A3 needs its candidate restore assertion plus the disjoint positive control; absence of traceback alone proves neither reconciliation nor safe restore.
8. **[Should]** A second merge can preserve publication fast-forward ancestry if it extends the first merge, since the publication clone is already at that first head (`jog_run.py:2185-2188`). But it is not “the same procedure”: HEAD, merge base, generation floor, crash recognition and retained journal commit differ. Reverting primary to the original checkpoint would also break the existing publication-clone ff-only path. Resolve these through F1/F3 and the generation explanation in answer 5.
9. **[Pass]** Reusing JogCheckpoint and canonical writers is proportionate for this local CLI; rejecting B1 changes fits its roadmap-only replay contract (`ledger_merge.py:228-234`). No additional runner, registry, suite or framework is warranted. The required missing work is the bounded recovery/retry and replay contract above, not enterprise coordination machinery. Restrict skill wording to checkpoint publication: per-task execution preflight still contacts origin (plan non_goals; `jog_run.py:637-640`).

**VERDICT: FAIL**
**Basis:** The plan addresses the reported publication seam, but its written retry/rollback contract is internally inconsistent and global orphan replay can alter disjoint remote rows. F1–F6 and the receipt-marker/generation clarifications remain open; none needs a new test suite. Root cause: a moved development has only a plain-push path; Fix site: JogCheckpoint publication and its stop boundary; Why not upstream/downstream: execution/preflight and B1 do not own primary checkpoint publication.

Handing off to Producer — go to the Producer window and say 'take your turn'.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
