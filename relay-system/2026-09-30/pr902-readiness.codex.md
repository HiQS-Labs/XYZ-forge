# RELAY · PR 902 readiness QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-09-30.
-->

NEXT: Producer
STATUS: Open
ROUND: 1 / 4

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
6. **Commit only the relay file** (`relay(pr-902-readiness-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **pr902-qa-scope.md** (embedded below — read it here).
- Reviewer: codex   ·   Producer: producer
- Started: 2026-09-30

### Artifact — pr902-qa-scope.md
```
PR 902 readiness review. Local desktop task-sync, one shared core/CLI and thin adapters; native Codex planner has no app-store writer. Read all scripts under skills/3-weekly/task-sync/scripts/, SKILL.md, PROJECT/2-WORKING/GH-901-CODEX-TASK-SYNC.md, and review-controls.txt plus provenance under TESTS-RESULTS/2026-09-30+GH-901. Graph XYZ-forge generation 2026-09-01T15:54:30Z misses all five source paths; exact source fallback required.
Questions: 1. Are missing/unreadable transcript previews preserved without disabling successful updates? 2. Does a second-workspace SQLite failure roll back the first title update? 3. Are naive timestamps consistently local? 4. Did merging reviewed PR900 preserve Codex core/CLI changes, safety and receipt isolation? 5. Are all eight threads disposed: heading count, Status table (PR900), preview, schema/pin authority before writes (PR900), multi-row transaction, timestamp, Codex-only doctor receipt docs, portable parity inputs (PR900)? 6. Is anything else materially broken in touched files? Keep changes commensurate. Do not demand new test suites, scheduler, cross-store transaction framework. Read-only synthetic probes under .relay-scratch only; no heavy gates/live stores. Graded findings with file:line, swept file: yes, concrete failing inputs for changes. Producer owns separate full-clone gate and merge/cleanup. No code edits; only relay report.
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

### Reviewer · Round 1
VERDICT: FAIL
Basis: The three PR902 fixes are supported by source and retained red/green evidence, but two review threads remain unresolved. No gate or executable fixture was run here; final clone verification remains Producer-owned.
swept file: yes

- [Should] Empty authoritative pins bypass schema validation before annotation mutation. `skills/3-weekly/task-sync/scripts/adapters/antigravity.py:367` returns before opening/checking the summaries DB; `:268` checks schema only when title/preview writes exist; `:278` still reaches the annotation writer. This contradicts SKILL.md's “Schema-validate before any write; abort … on drift.” Fix within the existing apply preflight: validate the summaries schema even when candidates/writes are empty, before annotation mutations.
  Observed input: apply=True, app stopped, authoritative `pinned_conversations_order=[]`, unavailable summaries DB. A non-mutating mock probe reaches the annotation writer with no connection attempt and returns error=None.
  Affected scope: Antigravity apply sweeps with empty candidate/title-write sets, including a missing or drifted summaries DB.
  Falsifier: empty authoritative pins plus a healthy summaries schema must still permit stripping stale annotation pins; empty pins plus missing/drifted schema must raise AdapterError before any annotation write. Preserve valid empty-list authority.
  Command (exit 0; imports only, all write entry points mocked):
  ```python
  import sys
  from unittest.mock import patch
  sys.path.insert(0, 'skills/3-weekly/task-sync/scripts')
  from adapters.antigravity import AntigravityAdapter
  a = AntigravityAdapter(agy_root='/nonexistent/synthetic', apply=True, app_running_fn=lambda: False)
  events = []
  with patch.object(a, '_read_pinned_ids', return_value=[]), patch.object(a, '_connect', side_effect=AssertionError('schema validation attempted')), patch.object(a, '_mirror_annotations', side_effect=lambda ids, rep: events.append('annotation writer reached')):
      r = a.sweep()
  print(events, r['error'])
  ```
  Decisive output: `['annotation writer reached'] None`. Executed with `PYTHONDONTWRITEBYTECODE=1` and `TMPDIR="$PWD/.relay-scratch/tmp"`.

- [Should] PR900 Status row remains outside the table: `PROJECT/2-WORKING/GH-896-UNIFIED-TASK-SYNC.md:36` is blank, followed by the headerless readiness row at `:37`. Remove that intervening blank line so the row belongs to the existing two-column table. This is a concrete document-format repair, not a runtime behavior expansion.

- [Pass] Missing/unreadable preview preservation is narrowly implemented at `adapters/antigravity.py:241`–243; successful previews still enter the existing update branch at `:250`. `TESTS-RESULTS/2026-09-30+GH-901/review-controls.txt` records both failure inputs false on baseline / true after fix. Multi-workspace title updates share `with conn:` at `adapters/zcode.py:168`, and the same receipt records injected second-row ABORT rollback false/true. These are retained controls, not firsthand fixture runs this turn.

- [Pass] Local naive timestamps: `core.py:51` and `:64` both use `astimezone()`. Firsthand pure parser probe, `TZ=America/Los_Angeles python3 -`, normal parser and mocked fromisoformat ValueError fallback on `2026-09-30 01:00:00`, exit 0: both emitted `2026-09-30T01:00:00-07:00`. No new suite required.

- [Pass] Integration preserves the measured core/CLI/Codex implementation: inline `python3 -` SHA256 comparison against the last GH901 provenance row, exit 0, returned True for core.py, task_sync.py, adapters/antigravity.py, adapters/zcode.py and adapters/codex.py. `task_sync.py:210`–218 refuses unsupported Codex mixed writes before dispatch; `:75` and `:113` isolate native-only doctor from CLI receipts; `codex.py:90`–110 preserves exclusions/manual pins and uses actual activity. Historical merge ancestry was not independently queried (no git authorized).

- [Unverified — no citation] Eight-thread disposition: preview, transaction and timestamp have the cited fixes/controls; Codex-only receipt documentation is explicit in SKILL.md (“A Codex-only native heartbeat does not refresh that receipt”); portable parity inputs use TASK_SYNC_ZCODE_ORIGINAL/SEED and TASK_SYNC_AGY_ORIGINAL in the retained GH896 batteries. Heading/count evidence is truthful: GH901 SUMMARY says “28 recorded manual probes”, GH896 provenance says “count corrected … to 24”. Status-table and schema-before-write threads remain open above.

- [Unverified — needs clone run] No current final-state gate attestation was generated here. GH901 provenance records the historical Small run against 61065117364152bbbf5a63a8db7cd8b0945fcd4b; it cannot attest subsequent source fixes. Producer must retain the appropriate final full-clone gate receipt. Full-file sweep found the pre-existing schema bypass and Status-table defect above; no other material defect identified in the bounded reviewed files.

Graph evidence: XYZ-forge generation 2026-09-01T15:54:30Z; coverage reports missing freshness for all five source paths. Full exact-source fallback covered all six script files, SKILL.md, GH901 working doc, review-controls and provenance; GH896 Status/parity inputs were read for the inherited threads.

Handing off to Producer — fix/disposition the two Shoulds and retain final clone verification, then request the next review turn.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
