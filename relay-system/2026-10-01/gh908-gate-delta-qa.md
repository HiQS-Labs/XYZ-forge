# RELAY · GH-908 gate delta QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-01.
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
6. **Commit only the relay file** (`relay(gh908-gate-delta-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **delta-brief.md** (embedded below — read it here).
- Reviewer: agy   ·   Producer: claude-a
- Started: 2026-10-01

### Artifact — delta-brief.md
```
Review commit 24432389 as a focused delta to the already approved GH-908 review in relay-system/2026-10-01/gh908-final-qa.md. Do not modify code or run test/*.sh or validate.sh. Read the full touched functions and their callers. The first ci-local on f7024999 failed GH-777's direct-SQLite inventory due to the extra query in pdda.sh; the corrected pdda.sh now uses the existing doc_path query's exit status. The new releases_app.py projections_enabled function now uses canonical connect(db). Determine whether these changes preserve empty-vs-corrupt DB behavior, projection-off semantics, and the DB gateway contract. Identify concrete counterexamples. Existing focused controls after the fix: gh777 ratchet clean; pdda-roadmap-coverage 11/11. Qualifying full suite is pending. Grade with file:line citations; approval must be independent of tests.
```
- Definition of Done: _<fill in the acceptance criteria the Reviewer grades against>_

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log


### Reviewer · Round 1 · codex

swept file: yes

**VERDICT: PASS**
**Basis:** The embedded delta brief was reviewed in full. Current source preserves queryable-empty versus unreadable-ledger behavior, explicit projection-off and legacy defaults, and the canonical connection contract. Reviewed the complete touched functions and their immediate callers, including pre-existing branches; no concrete counterexample or pre-existing defect found in that bounded scope. This approves the delta review, not merge readiness; the qualifying full gate remains pending.

- [Pass] Empty is ready, unreadable is not: `utils/pdda/pdda.sh:350-355` assigns the existing doc-path query inside `if`, sets readiness on success even with no rows, and clears it if the raw-text query fails. `utils/pdda/pdda.sh:364-408` still reports unreadable ledgers, scans both working and inbox docs, and reports uncovered pointers. `utils/pdda/pdda.sh:358` excludes stale Markdown authority in releases mode. Read-only SQLite controls: command `sqlite3 :memory: "CREATE TABLE roadmap_items(doc_path TEXT, raw_text TEXT); SELECT doc_path FROM roadmap_items WHERE doc_path IS NOT NULL;"` exited 0 with zero output bytes; `sqlite3 :memory: "SELECT doc_path FROM roadmap_items WHERE doc_path IS NOT NULL"` exited 1, `no such table: roadmap_items`; `sqlite3 "file:README.md?mode=ro" "SELECT doc_path FROM roadmap_items WHERE doc_path IS NOT NULL"` exited 26, `file is not a database (26)`. These contrasting statuses exercise the readiness distinction without executing the dispatcher or a test fixture. No change requested.
- [Pass] Canonical gateway retained: `utils/py/releases_app.py:1350` calls `connect(db)`; its full implementation at `utils/py/releases_app.py:432-444` retains explicit transaction mode, named rows, foreign-key enablement and refusal if enablement fails. Connection closure remains in `finally` at `utils/py/releases_app.py:1353-1354`. Command `PYTHONDONTWRITEBYTECODE=1 python3 utils/pdda/check_inventory_ratchet.py --check` exited 0: `inventory_ratchet: clean (matches baseline, 0 new scripts/connects)`. A narrow read-only call to canonical `connect` on the seeded DB reported `gateway foreign_keys=1 isolation_level=None` (inline Python probe, exit 0). No change requested.
- [Pass] Projection semantics preserved by inspection of `utils/py/releases_app.py:1344-1357`: missing DB, absent setting and SQLite read errors retain the default; only the explicit value `off` suppresses refresh. The gate precedes all writer refresh work at `utils/py/releases_app.py:1370-1402` and both reconcile view selections at `utils/py/wave_reconcile.py:1809-1823`. Complete immediate callers read: `perform_write` (`utils/py/releases_app.py:1670-1784`), `perform_migration` (`utils/py/releases_app.py:1787-1899`), and `run_subprocesses` (`utils/py/wave_reconcile.py:1767-1870`). Both writer paths invoke refresh after durability. Narrow evaluation of the unchanged function AST with in-memory settings returned `None -> True; auto -> True; on -> True; off -> False` (inline Python probe, exit 0); this isolates predicate behavior and does not claim end-to-end exporter execution. No change requested.
- [Unverified — needs clone run] The reported 11/11 focused suite and qualifying full suite were not run this turn. No `validate.sh`, `test/*.sh`, pytest, executable fixture, Git command, exporter or reconciler was executed. Harness must supply the qualifying gate for the final committed state.

Evidence scope: graph lookup used nearest available project `XYZ-forge`, generation `2026-09-01T15:54:30Z`; it belongs to a different checkout and coverage marked all three source paths `metadata_changed`. Therefore structural claims above use current local source, not graph completeness or commit identity (Git is prohibited this turn). The sweep covers the entire embedded artifact and the named function/caller scope, not an exhaustive audit of unrelated functions in the large source files. Scratch environment: `PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"`.

Relay closed (Approved), no further review turn needed. NEXT is Producer (claude-a) for harness closeout and the pending qualifying gate.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
