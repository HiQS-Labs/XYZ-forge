# RELAY · GH1022 Phase8 canonical preservation final QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-12.
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
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns.
   Reviewer headings may be `### Reviewer · Round N`, `### Round N · Reviewer · <agent>`, `### Reviewer (<agent>)` (optionally followed by `— rN`), or `### Reviewer — Round N` (optionally followed by `(<agent>)`); follow the heading with a non-empty review body.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(gh1022-phase8-final): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: _<fill in the repo-relative path(s) the turn reviews>_
- Reviewer: codex   ·   Producer: Author
- Started: 2026-10-12
- Definition of Done: _<fill in the acceptance criteria the Reviewer grades against>_

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

Artifact scope: exact candidate16e4a046; whole utils/py/releases_app.py, both changed weekly/releases skill documents and main GH1022 plan. Inspect relevant existing owner fixture sources in full (gh32 owner/artifacts, gh360 scoped-chain/multiline, gh646 status-label, gh549 history). Read current implementation plus unchanged surrounding owner behavior, not only changed diff. Manual source-qualified evidence is committed under TESTS-RESULTS/2026-10-11+GH-1022/phase8-*.json with provenance. This is the bounded new canonical owner API prerequisite, not weekly coordination, proposal/freeze or shared firing/landing.

## Log

### Producer · Round 1

VERDICT: PARKED
Basis: Implemented approved Phase8 plan; new-scope final source QA pending.

Candidate16e4a046 factors existing check receipt arithmetic and existing rebuild staged constructor. Adds pure conservative local-parent row selection and opt-in check preview/apply; new-kind journal binds parent/selection/runtime/root/before-after state, stage exactness and same transaction receipt. Ordinary check owns exact new-mode recovery ahead of legacy cleanup. Existing check/rebuild/defaults, immutable triggers, backup and connector policy retained. Unknown/delete/conflict/owner drift holds; exact repeat no-op. No second store, merger outside owner, runner, gate, migration or event.

27 actual ephemeral manual controls are source-qualified atd7efd6d5: preview/apply/no-op3; backup/refusals/crash/recovery18; source/conflict/deletion/NULL-gh/override/start/history6. Fixtures write local Git/DB/dump/staging/journal/audit with connectors0, no external writes. Existing suites run only in separate disposable full clone. Do not claim every concurrency/drift boundary demonstrated merely because source guard exists; inspect proof and report limits. No new permanent test/case/parameter/registration approved or added.

No source edits, extra agents, executable suites/fixture programs, network/connectors/live actions, or Git commands/writes except this relay; harmless in-memory source probes permitted. Read owners and surrounding code completely in paged chunks (no truncated whole-file approval). Every behavior-change finding needs observed input/scope/falsifier. Preserve R6FAIL6/6/Medium1028, #1027unapproved, closed Phase6/7 and Phase8 planApprovedR1/3. This is genuinely new API finalQA cap3 under existing authority, not a reset or extra corrective allowance. Whole1022 and remainingW7–11 remainactive. Handing off to Reviewer(codex)—take Phase8 final Round1.

### Reviewer · Round 1

VERDICT: FAIL
Basis: The new selector accepts complete deletion of an ancestor history table when that table is absent from both parents. This contradicts the approved preservation/deletion-hold contract. Fix B1 before Phase8 approval. The retained quiet/crash controls do not falsify this input.
swept file: yes

- [Blocker] **B1 — visit ancestor-only tables before selecting rows.** `utils/py/releases_app.py:6563` iterates only `target` and `ours`, so when both omit the last row of a base table, its deletion/append-only checks at `:6582`, `:6601` and `:6614` never execute. The actual seeded dump contains 713 work events. Removing the entire `work_events` entry from both parsed parent inputs passes `_merge_source` and `select_ledger_merge`, returning zero events. Work events are excluded from business digests (`:1304`), so the source receipt check cannot catch this loss. Exact roundtrip also succeeds because the empty table emits no records. Cheapest fix: include base-only table names in the existing iteration, retaining current target/ours ordering, so the existing guards handle the missing rows; do not add an importer or change trigger/history policy.
  Observed input: `base_text = Path('releases.sql').read_text(); tables, gen, _ = _merge_source(base_text); deleted = deepcopy(tables); del deleted['work_events']; deleted_text = _merge_dump_text(deleted, gen); select_ledger_merge(base_text, deleted_text, deleted_text)`. Both modified inputs remain current-schema, FK-valid, receipt-valid and exact-roundtrip sources. Candidate owner SHA256 is `d7efd6d5e620c9518adf91ff78929c79bab2df9cb9d4f9a645dae3d5faf56694`.
  Affected scope: a nonempty ancestor logical table absent from both parent dumps. The witnessed case is complete work-event deletion; the same loop must still visit ancestor-only roadmap/other tables and apply their already defined rules. This does not request acceptance of unsupported deletes.
  Falsifier: the exact both-deleted input must hold with the existing append-only refusal; unchanged parents must retain all 713 events, and a one-parent deletion must keep holding. A legitimate table empty in all three sources must remain supported.
  Probe command (in-memory owner functions only; no Git, disk DB, fixture executable or artifact write):
  ```bash
  export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"
  python3 - <<'PY'
  import importlib.util, pathlib, copy
  p=pathlib.Path('utils/py/releases_app.py')
  s=importlib.util.spec_from_file_location('review_owner',p)
  a=importlib.util.module_from_spec(s); s.loader.exec_module(a)
  text=pathlib.Path('releases.sql').read_text()
  tables,g,d=a._merge_source(text)
  print('base_work_events='+str(len(tables['work_events'])))
  removed=copy.deepcopy(tables); del removed['work_events']
  removed_text=a._merge_dump_text(removed,g)
  a._merge_source(removed_text); print('deleted_source_admitted=True')
  selected=a.select_ledger_merge(text,removed_text,removed_text)
  print('both_deleted_selection_accepted=True selected_work_events='+str(len(selected['tables'].get('work_events',[]))))
  try: a.select_ledger_merge(text,text,removed_text)
  except ValueError as e: print('one_deleted_control_held='+str(e))
  selected=a.select_ledger_merge(text,text,text)
  print('unchanged_control_work_events='+str(len(selected['tables']['work_events'])))
  PY
  ```
  Exit status: **0**. Decisive output: `base_work_events=713`; `deleted_source_admitted=True`; `both_deleted_selection_accepted=True selected_work_events=0`; `one_deleted_control_held=historical source is not append-only: work_events`; `unchanged_control_work_events=713`. This witnesses the selector failure, not a disk publication/data-loss run.

- [Pass] Source ownership is correctly reused: ordinary check delegates scoped-chain arithmetic to `_receipt_chain_details` (`utils/py/releases_app.py:6009`, `:6489`); both new apply and legacy rebuild call `_build_rebuilt_db` (`:6837`, `:6988`). New-kind recovery branches before legacy SQLite/staging cleanup (`:1917`). Append-only triggers remain in the schema (`:616`, `:944`), and new apply does not use the legacy fixed-backup copy (`:6990`). These are source-qualified observations, not runtime qualification.
- [Pass] Preview returns before WriterLock/apply effects (`utils/py/releases_app.py:6787`); local commit evidence explicitly states `target_freshness='not verified; supplied local commit only'` (`:6780`). Apply requires connectors0 and holds existing intent/sidecars, device cursors and leases (`:6791`, `:6797`, `:6803`). Weekly still declares coordination/adoption/rollover unimplemented (`skills/3-weekly/weekly/SKILL.md:193`), and the plan retains W7–W11 plus R6FAIL/Medium1028 and unapproved #1027 (`PROJECT/2-WORKING/GH-1022-WEEKLY-INTAKE.md:21`, `:1080`). No readiness, dispatch or full-issue approval follows.
- [Unverified — needs clone run] **Recovery drift and waiting-writer boundaries remain unqualified.** `_recover_ledger_merge` checks live/staged dump file type, but does not compare their bytes before overwriting the dump and deleting staging/intent (`utils/py/releases_app.py:6718`, `:6728`, `:6733`). A permitted in-memory decision probe, with filesystem/Git/selection/DB identity boundaries stubbed, returned `('completed', 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa')`, `dump_content_or_hash_checked=False` and actions `write releases.sql; unlink releases.sql.tmp-<txn>; unlink intent` for existing regular dump/stage files. Probe exit **0**; zero real writes. Its first setup attempt exited **3** (`dump-parse` on the probe's stub `exact-after-dump`) because the stub also affected selection; the corrected decision probe supplied a precomputed selection. This is not observed end-to-end owner loss and is not an additional behavior-change demand. A disposable-clone run should distinguish legitimate pre/post-swap dumps from a separately edited dump/stage and record preservation or the concrete failure. Also measure a sanctioned writer that opens its connection before waiting for the merge's WriterLock: existing callers open before lock (`:2450`, `:1698`), while the merge swaps the DB file (`:6860`). No race-free claim follows from the lock alone.
- [Unverified — needs clone run] Retained evidence has 3 quiet/preview/no-op, 18 refusal/crash/recovery and 6 shape controls (`TESTS-RESULTS/2026-10-11+GH-1022/phase8-manual-results.json`, `phase8-negative-results.json`, `phase8-shape-results.json`), attributed to the matching owner hash in `provenance.jsonl:218`. Those records are producer evidence; no suite, pytest, executable fixture, Git command, connector, network or live operation ran here. Existing owner/artifact/status/history checks and final harness gate remain required after repair; no new permanent test/case/parameter/registry is requested or authorized.

Sweep/evidence limits: read the whole 7,527-line owner, both complete skill documents, whole 1,122-line main plan and complete gh32 owner/artifact, gh360 scoped-chain/multiline, gh646 wrapper/Python and gh549 history fixture sources in paged chunks, rereading truncated spans. No additional demonstrated pre-existing actionable defect found; the recovery/concurrency suspicions above remain explicitly unverified. Graph listing fully paginated: this relay root has no index; nearest XYZ-forge generation `2026-09-01T15:54:30Z` is a different root. Graph search/coverage reported changed/missing/not-tracked metadata and gh32 partial line237; direct current full-source reads supersede stale graph evidence. No artifact/source edits, new agents or Git writes. Phase8 plan approval and closed Phase6/7/R6 histories remain unchanged; this final Round1 fails within its existing cap3.

Handing off to Author — address B1, retain the failed round and concrete controls, then return the repaired candidate for the next authorized review turn. No approval or publication permission granted.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
