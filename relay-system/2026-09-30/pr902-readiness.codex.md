# RELAY · PR 902 readiness QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-09-30.
-->

NEXT: Reviewer
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

### Producer · Round 1
Both Shoulds implemented: unconditional summaries-schema validation before annotation apply, and readiness row now belongs to Status table. Observed r1 red input replayed: missing DB refuses, old annotation bytes preserved; healthy schema + explicit [] removes stale pin. Original four controls remain green. Request complete r2 review.

### Reviewer (codex) — r2
VERDICT: FAIL
Basis: Both prior Shoulds are resolved, but the full-file sweep found one concrete unreadable-preview edge still violating question 1 and per-IDE error isolation. Final clone gate remains Producer-owned.
swept file: yes

- [Should] Invalid UTF-8 transcript bytes escape the preview-preservation path. `skills/3-weekly/task-sync/scripts/adapters/antigravity.py:387` reads UTF-8, but `:389` catches only OSError. UnicodeDecodeError therefore escapes before the preservation branch at `:242`; `task_sync.py:129` also does not catch it. Extend the existing transcript-read error handling to include UnicodeError and reuse the existing error sentinel/preservation branch; do not introduce a suite or broad catch.
  Observed input: conversation `a`, title `Old title`, preview `valuable preview`, last_modified_time `2026-09-30 01:00:00+00:00`; its transcript read raises `UnicodeDecodeError('utf-8', bytes([255]), 0, 1, 'invalid start byte')`. A mocked apply sweep with IDEs zcode,agy raises instead of returning merged JSON; the successful ZCode section never gets its receipt.
  Affected scope: Antigravity transcript decoding failures only; preserve the old preview while permitting valid title/other-row updates.
  Falsifier: this byte sequence must yield a preserved preview and successful title update, with the merged report/receipt retained for successful IDEs; a valid UTF-8 transcript must still update its preview. Existing missing-file and OSError controls must remain green.
  Command: `PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp" python3 -` (exit 0; imports and mocked I/O only). Probe called `task_sync.run_sweep(args, True)` with the row above from mocked `_pinned_rows`, mocked Path.exists=True, builtins.open raising the exact decoding error, mocked ZCode success, and mocked connection/receipt entry points. Decisive output: `UnicodeDecodeError zcode completed: True agy write connection: False receipt: False`. Direct helper probe also emitted `UnicodeDecodeError 'utf-8' codec can't decode byte 0xff in position 0: invalid start byte`.

- [Pass] Empty-pin schema-before-write issue resolved at `adapters/antigravity.py:268`–277: connection and schema checks are unconditional before mirroring. Firsthand non-mutating mock probe with explicit [] and missing DB raised AdapterError and emitted `missing: missing DB writers: []`; healthy mocked schema emitted `healthy: ['schema', ('mirror', [])]`. Command: `PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp" python3 -`, exit 0. This verifies ordering; actual synthetic-file preservation/stripping is retained Producer evidence in `TESTS-RESULTS/2026-09-30+GH-901/review-controls.txt` (“Fixed replay refuses and preserves bytes; healthy empty schema + [] still removes stale pin”).

- [Pass] Status-table issue resolved: `PROJECT/2-WORKING/GH-896-UNIFIED-TASK-SYNC.md:36` immediately follows the prior table row, with the blank now after it at :37.

- [Pass] Remaining source contracts survive the integration: missing-file/OSError sentinel preservation at `antigravity.py:241`–253; all-workspace transaction at `zcode.py:168`–183; both local naive parser branches at `core.py:51,64`; native write refusal before dispatch at `task_sync.py:210`–218; receipt isolation at `:75,113`; exclusions and actual activity at `codex.py:90`–110. SHA256 probe against the final GH901 provenance row returned True for all five named production files (same inline Python command, exit 0). These are source/retained-control findings, not firsthand executable-fixture runs.

- [Pass] Eight-thread bookkeeping is now source-cited: count wording is “28 recorded manual probes” in `TESTS-RESULTS/2026-09-30+GH-901/SUMMARY.md:3`; GH896 provenance row 2 explicitly corrects 23 to 24; the Status row and schema preflight are resolved above; preview/transaction/timestamp sites are cited above; Codex-only receipt caveat is explicit at `SKILL.md:86`–90; portable predecessor/seed inputs are mandatory at `TESTS-RESULTS/2026-09-30+GH-896/zcode_parity.py:6`–9 and `agy_battery.py:10`–12.

- [Unverified — needs clone run] No gate or executable fixture run here. GH901 provenance's Small receipt names historical SHA `61065117364152bbbf5a63a8db7cd8b0945fcd4b`; current fixes still need the final disposable-full-clone gate after review. No merge/cleanup authorization is implied by this report.

Graph: confirmed XYZ-forge project; coverage generation 2026-09-01T15:54:30Z reports missing freshness for all five source paths and no indexed task-sync scope files. Exact-source fallback swept all six script files, SKILL.md, the complete GH901 working doc, review-controls/provenance; inherited GH896 Status/parity/count evidence was read. Apart from the decoding failure above, no other material pre-existing defect identified in this bounded sweep. No source/artifact edits, git commands, live stores or heavy gates.

Handing off to Producer — fix/disposition the decoding Should, retain its narrow red/green evidence and final clone gate, then request the next review turn.

### Producer · Round 2
Implemented UnicodeError in existing transcript-read handler. Bytes ff red before (UnicodeDecodeError), green after (existing preserving sentinel). Narrow change; request final r3 whole-file sweep.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
