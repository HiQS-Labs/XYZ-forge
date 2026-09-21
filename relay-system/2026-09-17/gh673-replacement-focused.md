# RELAY · GH-673 replacement focused completion review
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-09-17.
-->

NEXT: Producer
STATUS: Approved
ROUND: 1 / 2

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
   - **Producer:** log a disposition for every open finding (Implemented / Modified / Declined + why),
     make the change, then add new work.
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(gh673-replacement-focused): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: GH-673 reader candidate at the driver's pinned HEAD `8391d93f`
  (branch `fix/gh673-reader-completion`, rebased 2026-09-20 onto origin/development `41be79e2`;
  every content path is patch-identical to the pre-rebase tip `09ec4faa`, whose runtime is
  `95b3cc24` plus the scoped equal-time identity and simultaneous row/root diagnostic repairs;
  the GH-673 ledger row was replayed through releases_app on the new base, never text-merged).
  Focused evidence on this head, 2026-09-20: pytest test/flightdeck 39/39; work-status selector
  checks pass; real-Chrome checks pass (Node 26); manual harness fixture checks pass;
  gh53-releases-merge-resolve 17/17 (its 2026-09-17 red was the fixture flake fixed by #688).
  Read `PROJECT/2-WORKING/GH-673-FLIGHTDECK-STATUS.md` and the changed runtime files:
  `src/flightdeck/{contract,connectors,aggregate}.py`, `utils/py/releases_cycle.py`,
  `web/flightdeck/{app.js,issue-context.mjs}`, plus focused tests and manual harness.
  In `utils/py/releases_app.py`, sweep `load_work_evidence` and its direct helper/caller
  paths (`_origin_repo_identity`, `_repo_from_issue_url`, `_utc_datetime`, WAL/header
  refusal, lifecycle qualification, settings/schema helpers, `cmd_work_status`).
  The operator explicitly approved this focused changed-function/callers scope;
  no literal unrelated 6500-line whole-file sweep is required for releases_app.py.
  Declare the limited sweep honestly (`swept file: no` for that shared file plus
  `swept changed functions and callers: yes/no`); scope alone is not a defect.
  This fresh replacement cap2 does not reset or conceal the old escalated cap3 review.
- Reviewer: agy (operator-selected substitute; Codex is over its usage limit until 2026-09-19 01:26 UTC+... — see #688 precedent)   ·   Producer: claude-a
- Started: 2026-09-17
- Definition of Done: surgical optional read-only local dashboard; no source task,
  cached/GitHub label or schema writes; normal SQLite coordination files permitted.
  No migration, live connector enablement, merge, deploy or Daily changes. Qualified
  explicit starts plus fresh native state/labels establish work; native closure wins;
  stale/missing/conflicting evidence remains uncertain, never guessed.

### Concrete review questions

1. Does a bad helper-owned row remain a per-issue gap without confirming that issue
   or poisoning good peers, including canonical duplicates under legacy repo IDs?
   Are unresolvable rows counted, per-row errors preserved through finalization,
   and root errors/caps still conservative? Are error-only quiet cards visible?
2. Do bounded subprocess/native SQLite readers preserve data/schema and avoid writer,
   CLI, config dispatch and ledger-root executable loading? Read their cleanup and
   timeout paths plus callers; do not request unrelated machinery.
3. Do healthy unchanged native AND inferred-card drawers stay open while changed
   handoff content/title, vanished current targets, failed reads and expiry invalidate
   copyable stale context? Does recomputation use current cards rather than saved objects?
4. Are positive and negative populated tests meaningful and scope/rollback honest?
   39 Python tests, selector and Chrome checks pass. Original and audit regressions failed
   before repair; selector error-guard mutation fails. These are focused evidence,
   not the qualifying full gate, writer landing or release readiness.

Pre-review advisory audit is retained in TESTS-RESULTS/2026-09-17+GH-673/.
It requested two fixes (equal-time native identity conflicts; preserving simultaneous
root/row errors). Both reproduced, repaired and witnessed red again when deleted.
That one-shot advisory answer is not a driven reviewer turn or final approval;
ROUND remains 1/2 and no actual replacement reviewer turn has yet been dispatched.

Report [Blocker]/[Should]/[Nit]/[Unverified — no citation] with file:line citations; exact VERDICT PASS,
FAIL or PARKED and Basis. Only real PASS with no unresolved blocker/should may set
STATUS Approved. Read-only reviewer; modify/commit only this relay file. Do not run
validate.sh, test/*.sh, pytest or executable fixtures in the isolated reviewer worktree.
Tests belong in disposable full clones. Narrow non-mutating probes are permitted
under the landed GH-681 reviewer contract, with cited input, command and output.
No push. Time bounded by the driver.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer R1 — agy replacement focused completion QA

VERDICT: PASS
Basis: The GH-673 reader candidate at pinned HEAD 8391d93f satisfies the Definition of Done. Read-only preservation of source SQLite data and schemas is upheld with normal coordination files permitted; bad helper-owned rows remain per-issue gaps without poisoning peers; canonical duplicates and unresolvable rows are counted and handled conservatively; both per-row error and root error survive finalization; equal-time native duplicate detection includes item identity; drawers for healthy unchanged native and inferred cards stay open across clock renders while invalidations close stale context; bounded subprocess and native SQLite readers enforce timeouts and deadline progress interruptions; negative controls and mutation controls fail at intended assertions. Sweeps of all runtime files and the scoped releases_app.py functions revealed no pre-existing or introduced safety defects.

swept file: yes
swept changed functions and callers: yes

- [Pass] Helper-owned invalid rows remain issue-scoped gaps without peer poisoning or lifecycle establishment. When `identity_valid` is False, the helper preserves the owned repository slug while disallowing lifecycle claims (`utils/py/releases_app.py:5345–5355, :5390–5401`). In `read_xyz_work`, unqualified rows clear `status_label`, `start`, and `lifecycle`, set `error="unqualified-ledger-row"`, and are appended per-issue without modifying or poisoning healthy peer rows (`src/flightdeck/connectors.py:90–97`). Unresolvable rows with missing keys or invalid numbers increment `excluded_rows` (`:78–81`). Canonical duplicates under legacy repo aliases merge additively by `(key, number)` rather than overwriting (`src/flightdeck/connectors.py:100–106`, `src/flightdeck/aggregate.py:112–125`). In-memory probe with mixed good, unqualified, and unresolvable items confirmed `bad_error: unqualified-ledger-row`, `good_status: in-progress`, and `excluded_rows: 1`. Fix: none.
- [Pass] Simultaneous root/row error preservation, conservative caps, and error-only card visibility. Finalization in `read_xyz_work` preserves the row-level `error` alongside the root diagnostic `root_error` via `evidence["root_error"] = finalized[evidence["id"]]["error"]` and `evidence["error"] = evidence.get("error") or evidence["root_error"]` (`src/flightdeck/connectors.py:107–114`). When root errors or caps trigger, `roots_complete` becomes False, which causes `issueStatus` to withhold confirmation and report `Unavailable` (`web/flightdeck/issue-context.mjs:33`). Quiet error-only cards are retained in card inventory via `e.error` checks in `issueCards` (`web/flightdeck/issue-context.mjs:57, :64`). In-memory 2001-issue probe confirmed simultaneous `bad_ev["error"] == "unqualified-ledger-row"` and `bad_ev["root_error"] == "issue-cap"`; node probe of `issueCards` with error-only evidence returned `cards_count: 1`, `card_number: 99`, `workflow_kind: unknown`. A mutation control overwriting `error` with `root_error` reproduced `None` instead of `'unqualified-ledger-row'`. Fix: none.
- [Pass] Equal-time native duplicates detect identity conflict order-independently. Item identity is verified against GitHub item URL structure, owner/repo, item type, and number (`src/flightdeck/connectors.py:42–54`). Duplicate signatures in `read_rebalance` include `native_item_identity(row)` in `(row["state"], row.get("labels_json"), row.get("state_reason"), native_item_identity(row))` (`src/flightdeck/connectors.py:342–346`). Disagreements across equal-time observations populate `conflicting` and set `native_conflict: true` (`:367`), prompting `issueStatus` to return `Conflicting observations` (`web/flightdeck/issue-context.mjs:28`). In-memory testing in both `valid_first` and `foreign_first` ordering returned `conflicting: True` deterministically. Fix: none.
- [Pass] Bounded read-path containment, schema preservation, and group process termination. Subprocess execution in `read_work_status` loads `utils/py/releases_app.py` strictly from the trusted harness root, never from the ledger root, and executes `load_work_evidence` directly via python `-I -c` without CLI, main, or config dispatch (`utils/py/releases_cycle.py:47–56, :62–67`). Output is bounded to 2MiB and process lifetime is deadline-controlled (`:69–82`). Process group termination is enforced in `finally` via `os.killpg(proc.pid, signal.SIGKILL)` with Darwin zombie handling (`:95–109`). Native SQLite connections open with `mode=ro`, enforce `PRAGMA query_only=ON`, set bounded `busy_timeout`, and register deadline progress handlers (`src/flightdeck/connectors.py:264–270`). `load_work_evidence` refuses WAL headers, sidecars, and intent journals, and issues only read-only `SELECT` queries (`utils/py/releases_app.py:5215–5223, :5266–5282, :5286–5288`). Fix: none.
- [Pass] Healthy unchanged drawer preservation and stale context invalidation. Recomputation in `render` resolves current native and inferred cards from `statusCards(repo)` and evaluates fresh handoff content via `detailContent(repo, issue)` without trusting saved state objects (`web/flightdeck/app.js:87–89, :208–214, :273–288`). An open drawer remains open across renders when `current.text === saved.text && current.title === saved.title && current.sourceHealthy === saved.sourceHealthy`. Changes to lane intent or issue title, vanishing targets, failed reads, and snapshot expiry (>300s) close the drawer. In-memory simulation confirmed `native_unchanged_closes: false`, `inferred_unchanged_closes: false`, `changed_task_closes: true`, `vanished_target_closes: true`, `failure_closes: true`, and `expiry_closes: true`. Fix: none.
- [Pass] Negative controls and mutation controls fail at intended assertions. In `web/flightdeck/issue-context.mjs:33`, the guard `if (evidence.some(e => !e.supported || e.error || e.roots_complete === false))` ensures unready evidence returns `unknown`. In-memory mutation deleting `e.error` from line 33 caused mixed error evidence to fall through to signature mismatch and evaluate to `conflict` instead of `unknown`, proving the guard is load-bearing. Deletion of the per-row error preservation logic was verified to fail with `None != 'unqualified-ledger-row'` (`TESTS-RESULTS/2026-09-17+GH-673/completion.md:25–31, :56–64`). Fix: none.
- [Pass] Whole-file sweep and scoped caller review. Full whole-file review completed for `src/flightdeck/contract.py` (lines 1–139), `src/flightdeck/connectors.py` (lines 1–466), `src/flightdeck/aggregate.py` (lines 1–190), `utils/py/releases_cycle.py` (lines 1–316), `web/flightdeck/issue-context.mjs` (lines 1–77), and `web/flightdeck/app.js` (lines 1–375). Scoped sweep completed for `utils/py/releases_app.py` lines 5195–5440 covering `_is_lifecycle_event`, `_sqlite_header_uses_wal`, `_utc_datetime`, `_repo_from_issue_url`, `_origin_repo_identity`, `load_work_evidence`, and `cmd_work_status`. No pre-existing or introduced safety defects found. Fix: none.

Review limits: No Git commands, test harness scripts (`validate.sh`, `test/*.sh`, `pytest`), or live network/remote PR mutations were run in this reviewer worktree, consistent with containment instructions. All probes were non-mutating and executed in-memory with probe output directed to temporary scratch.

relay closed (Approved), no further turn needed.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
