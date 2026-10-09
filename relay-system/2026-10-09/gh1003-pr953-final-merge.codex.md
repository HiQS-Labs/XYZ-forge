# RELAY · GH1003 PR 953 final refreshed merge QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-09.
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
6. **Commit only the relay file** (`relay(gh1003-pr-953-final-refreshed-merge-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: committed candidate ledger, CHANGELOG, routine view and merge qualification evidence
- Reviewer: codex   ·   Producer: Producer
- Started: 2026-10-09
- Definition of Done: independently confirm the final merge preserves both parents and earlier approved runtime, with truthful qualification evidence and no new blocker

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Final refreshed merge review

Candidate before scaffold: bd89143964056a056fe03139bd77e26f229c12ae. Integration parent: f7ee6610160ce05e2b09a6cbca7b7dc4bf75fe4c. Earlier approved complete merge review: relay-system/2026-10-08/gh1003-pr953-merge.codex.md; approved view correction: relay-system/2026-10-09/gh1003-pr953-merge-r2.codex.md. Reuse those reviews for unchanged runtime and prior history; do not repeat their already completed runtime recon. This final delta adds already-landed #979/#999 integration docs, replays only disjoint roadmap row GH998 through existing writer, preserves exact GH998 raw_text using roadmap update after rating normalization, and preserves the integration LEADERBOARD blob. No source/test/registry change.

Read `TESTS-RESULTS/2026-10-08+GH-1003/pr-953/final-refresh-proof.json`, its provenance, original merge and label readbacks, gate results and raw logs. Verify independently against complete git object parents and SQLite tables that both changelogs survive; all earlier candidate/integration business fields survive; roadmap status labels and text match readback; receipt chain/digest and DB/dump are consistent. Writer-owned IDs/positions/admission timestamps can change; no historical admission is backdated. GH998 is Completed/✅ with status_label NULL per canonical lifecycle; GH949/GH912 remain in-progress.

Compare complete candidate tree against tested runtime commit a57884ad3208d2923d59d4e9914ad06939ec8990: only integration docs, authoritative ledger, view, receipts and PARKED finding should differ. The source runtime bytes must stay identical. Check that PARKED/2026-10-09-merge-cleanup-replay-label.md describes the known helper label loss and keeps general repair out of batch.

Qualification truth: isolated full macOS registry exercised all 407 suites with one caller-env failure in gh544-parallel-default (MAX_JOBS=2); the unchanged existing suite passed 29/29 with MAX_JOBS and HARNESS absent. Identity intact in both. Original feature full gate is retained; this is aggregate registry-plus-neutral-control evidence, not claiming the first full run was green. The final pushed head must also pass hosted smoke and the final release check in a second full clone. Judge the bounded merge/evidence now; do not claim hosted final-head qualification already happened.

Safety: pure read review only. Do not run suite, pytest, fixtures, databases with mutating verbs, or change artifacts in this linked review worktree. Only edit this relay. In-memory parsing/comparison is fine. Return Approved or an observed blocker/Should with citations and falsifier.

## Log

### Reviewer · Round 1 · codex

VERDICT: PASS
Basis: Approved for the bounded refreshed merge at `bd89143964056a056fe03139bd77e26f229c12ae`. Both parent changelogs and ledger business fields survive; runtime bytes retain the previously reviewed and exercised resolution. Qualification claims distinguish the failed aggregate run, neutral control and original feature gate. Final-head hosted smoke and the second-full-clone release check remain outstanding.
swept file: yes

Scope: complete stored trees and parent changelog blobs, all 16 SQLite tables, complete canonical dump, receipt chain, view, PARKED observation, and retained merge/gate evidence. Object reads verified SHA-1 without invoking git; SQLite blobs were deserialized in memory with query-only enabled. Prior runtime/history reviews were reused as instructed. No additional pre-existing defect was found within these bounded preservation/consistency checks. Graph registry pagination found no project for this seeded checkout; the canonical project's generation is `2026-09-01T15:54:30Z`, with changed/missing/excluded coverage for relevant paths, so exact local source and stored objects supplied the evidence. No suite, pytest, fixture, artifact writer or git command was run.

- [Pass] The actual refreshed merge `81f82b84adc1611b1ee5f40d7382885293c6c255` has parents `22c08cdfda437f809278f890a9577bf6d52f6203` and `f7ee6610160ce05e2b09a6cbca7b7dc4bf75fe4c`; the candidate descends through `b459de5ce5e1db50b7d60410fe82f8846d106744`. Both complete changelogs survive as ordered byte-line subsequences: earlier 3673 and integration 3647 lines become 3681, with no replacement/deletion operations. `CHANGELOG.md:3` retains the integration GH998 entry; `TESTS-RESULTS/2026-10-08+GH-1003/pr-953/final-refresh-proof.json:2` identifies integration and line 4 identifies the earlier parent. Probe: `PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp" python3 .relay-scratch/tmp/review_probe.py`, exit **0**; decisive output: `changelog earlier lines 3673 3681 noninsert []`, `changelog integration lines 3647 3681 noninsert []`.
- [Pass] All 336 earlier and 335 integration roadmap rows retain their business fields in the 337-row candidate, including exact raw_text, ratings, complexity/risk/effort and status labels; no duplicate non-NULL issue identities exist. `releases.sql:827` and `releases.sql:828` retain GH949/GH912 `in-progress`; `releases.sql:829` retains GH998 `Completed`, `✅`, NULL label and exact integration text `**SHIPPED 2026-10-09 (PR #999)**`. All twelve tables outside settings/roadmap/receipts/work_events are fully identical to both parents, including manifest_state_events and connector_cursors. Same probe, exit **0**: `roadmap earlier count 336 missing [] business changes {}`, `roadmap integration count 335 missing [] business changes {}`, `roadmap candidate count 337 duplicate identities []`. Supplemental command `PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp" python3 .relay-scratch/tmp/supplemental_probe.py`, exit **0**: `all 12 remaining complete tables identical` for both parents and `additional business complexity/risk/effort fields preserved`.
- [Pass] Current DB/dump and receipt state agree: generation **1497**, canonical serialization equals the complete SQL bytes, integrity `ok`, no foreign-key violations, **1684** chain receipts (1688 total), **171** breaks scoped by **171** reanchors, latest after-digest equals current business digest. Citations: `releases.sql:3`, `releases.sql:16`, `releases.sql:2536` (`reanchor:171`), and canonical serializer/digest at `utils/py/releases_app.py:1094` and `utils/py/releases_app.py:1303`. Same probe, exit **0**: `canonical dump exact 1497`, `integrity ok foreign violations []`, `receipt chain 1684 breaks 171 tolerated 171 latest digest True`. Earlier-candidate receipts/events all survive, with six/four additions. Integration GH998 was replayed: its eight receipts and six events are not copied into the current chain; original history remains in integration parent objects. This finding establishes business preservation and current-chain consistency, not identical provenance tables across both parents.
- [Pass] Replay admissions are current-time records, not reconstructed historical starts. GH949/GH912 accepted-start events remain at `2026-10-09T06:51:58Z`/`06:51:59Z` (`releases.sql:3178`, `releases.sql:3179`); GH998 has current first_seen `2026-10-09T07:44:34Z` and no invented in_flight event (`releases.sql:829`, `releases.sql:3180`–3183). The same supplemental command, exit **0**, prints those timestamps and `admission 998 ... in_flight []`. `PARKED/2026-10-09-merge-cleanup-replay-label.md:3` accurately names the earlier label loss and accepted-start repair; line 5 explicitly keeps general helper repair outside this batch. Concrete follow-on: retain that parked observation for later triage; no expansion is needed here.
- [Pass] Complete candidate-versus-tested-runtime tree comparison contains **41** paths, all within the stated docs/ledger/view/evidence/PARKED scope; no source, test, registry or runner delta. The proof's pre-proof path list matches after accounting for the proof file itself. Thirty incoming docs/view/receipts match integration exactly. The view shares integration blob `258e7bd1513b7b5ee2d0a49ae0682981ecbd6400`; all 310 lines/293 ranked rows were parsed. `LEADERBOARD.md:1` deliberately retains integration generation 1488 pending reconciliation. Seed `ae094cc57eda469d65be6f9fa6bd731a552835b7` adds only this relay scaffold. Citations: `TESTS-RESULTS/2026-10-08+GH-1003/pr-953/final-refresh-proof.json` span `"tested_runtime_commit": "a57884ad3208d2923d59d4e9914ad06939ec8990", "runtime_differences": []`; prior review `relay-system/2026-10-09/gh1003-pr953-merge-r2.codex.md:90`. Commands: the review probe above and `PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp" python3 .relay-scratch/tmp/evidence_probe.py`, both exit **0**; decisive output `working all changed blobs match committed candidate 41`, `integration changed docs/views/receipts exact 30`, `whole view 310 ranked rows 293 first/last ['1'] ['293']`.
- [Pass] Qualification reporting is truthful at the recorded revisions. Every one of the **407** static registry entries has exactly one raw parallel result; only gh544-parallel-default fails. `gate.log:448` says `22 pass, 7 fail`; `gate.log:498` records 407 registered and `gate.log:512` says `409 / 410`. The full-run before/after identity snapshots in `gate-result.json:13`–24 are equal. The neutral raw log ends `29 pass, 0 fail`, with rc 0 at `mode-neutral-result.json:3`; MAX_JOBS outranks PARALLEL in unchanged `validate.sh:948`–968, explaining the observed failures in `test/gh544-parallel-default.sh:63`–111. Same evidence probe, exit **0**: `registry 407 parallel result rows 407 unique 407`, `registry missing set() extra set()`, `registry failures [('gh544-parallel-default.sh', '1')]`, `neutral PASS assertions 29`. The neutral receipt records `identity_intact: true` but supplies no separate raw before/after snapshots; that assertion is retained as reported, not independently re-established here.
- [Pass] Original feature qualification remains intact: all seven files under `TESTS-RESULTS/2026-10-04+GH-949/full-gate/` match the tested runtime tree; the six retained artifact SHA-256 values match their files, and original before/after snapshots are identical. `full-gate/provenance.jsonl:1` records source `9e7eaddc63e58d16cdceddb7477f3e4a421ac786`, macOS and rc 0; `push.log` contains `pre-push: full gate GREEN in 808s — pushing.` The same supplemental command, exit **0**: `original feature retained hashes all match 6 identity identical True`; the original continuity receipt's six feature runtime hashes also match the final candidate. This preserves earlier feature evidence without relabeling it as final-head qualification.
- [Unverified — needs clone run] No final pushed-head hosted smoke or second-full-clone release check is established by this review. The final-review instruction above explicitly leaves those steps to the Producer/harness. Approval covers this bounded merge/evidence; merge qualification, promotion and cleanup must wait for their required exact-head results.

Manual red controls changed only in-memory comparison inputs. Each command below used `PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"` and exited **1**, with the quoted decisive output:

```text
python3 .relay-scratch/tmp/red_probe.py changelog
AssertionError: red: deleted integration heading fails full-parent preservation
python3 .relay-scratch/tmp/red_probe.py view
AssertionError: red: old view fails current integration identity
python3 .relay-scratch/tmp/red_probe.py row
AssertionError: red: fabricated GH998 start fails parent business equality
python3 .relay-scratch/tmp/red_probe.py dump
AssertionError: red: altered SQL fails canonical DB/dump equality
python3 .relay-scratch/tmp/red_probe.py digest
AssertionError: red: altered receipt digest fails current business digest
```

Relay closed (Approved), no further review turn needed. Handing completion to Producer for final-head hosted smoke and the release check in a second disposable full clone; the harness owns the one-file commit.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
