# RELAY · GH1003 PR 966 final refreshed merge QA
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
6. **Commit only the relay file** (`relay(gh1003-pr-966-final-refreshed-merge-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: _<fill in the repo-relative path(s) the turn reviews>_
- Reviewer: codex   ·   Producer: merge-cleanup
- Started: 2026-10-09
- Definition of Done: _<fill in the acceptance criteria the Reviewer grades against>_

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.


## Final refreshed merge review

Candidate before scaffold: e2e3f8a88ec646f57d607672e8d3b369b52b7c2e. Integration parent: 1e83bfb9d792d9c2dd4650d2956d9ac182566c12. Earlier complete review: relay-system/2026-10-08/gh1003-pr966-merge.codex.md; renewed approved correction: relay-system/2026-10-09/gh1003-pr966-merge-r2.codex.md. Reuse those complete reviews for unchanged feature/runtime and old history. Incoming #953 runtime and integration receipts already have final Approved QA at relay-system/2026-10-09/gh1003-pr953-final-merge.codex.md and hosted qualification. Do not repeat already approved feature recon; review the final integration/preservation delta and whole artifacts involved.

Read TESTS-RESULTS/2026-10-08+GH-1003/pr-966/final-refresh-proof.json, provenance, gate-result.json, gate-neutral-result.json and raw logs. Independently compare complete parent changelogs as ordered subsequences; complete roadmap business fields and remaining business tables; canonical SQL/DB/digest/receipt-chain consistency; current status labels and exact raw_text. Writer-owned IDs, positions and admission timestamps may change but never backdate admission. Integration completed rows use NULL status_label. Confirm no duplicate issue identity and no business field loss. LEADERBOARD must match exact integration bytes. All incoming runtime differences against tested own candidate 4a965bff58c50b9bada89ad78c6230dec5112058 must match integration blobs exactly. No manually authored runtime/test/registry edits are expected. Account separately for newly added evidence and relay scaffolds.

Qualification truth: the identical small gate first failed with inherited XYZ_HARNESS pointing at primary, identity intact. With XYZ_HARNESS absent it passed validate.sh --sequential --subsystem small, identity intact. Both results and raw logs are committed; this is an environment-neutral successful control, not claiming the original run green. Final exact-head second-full-clone release check and hosted smoke remain outstanding. Keep #964 operator checks / #971 deployed refresh pending; do not execute them.

Graph context: Verify tier current canonical project Users-noelsaw-Documents-GH-Repos-XYZ-forge, root /Users/noelsaw/Documents/GH Repos/XYZ-forge, generation 2026-10-09T08:04:52Z. check_index_coverage reported metadata_match/no_recorded_issue for utils/py/releases_app.py and canonical merge_cleanup.py/ledger_merge.py; current deployed helpers hash match canonical. Coverage is best effort. A seeded review checkout is not this indexed root; use exact local artifacts/object reads for current preservation claims and state any gaps. Relevant source: replay_ops label loss is known and corrected in candidates using existing writer, broader repair PARKED.

Safety: pure read review only. No suite, pytest, fixtures or mutating DB verbs in this linked review worktree. Only edit this relay. In-memory parsing/comparison and red controls are fine. Return Approved or an observed blocker/Should with concrete input, citations and falsifier. Witness at least one preservation/digest red control; retain truthful limits. No promotion or production verification claim.

## Log

### Reviewer · Round 1 · codex

VERDICT: PASS
Basis: Approved for bounded final integration/preservation QA at `e2e3f8a88ec646f57d607672e8d3b369b52b7c2e`. Complete parent changelogs, the expected ledger business union, current receipt chain and integration runtime/view bytes survive. One nonblocking evidence-count clarification is recorded below. Final exact-head second-full-clone release check and hosted smoke remain outstanding; this is not promotion or deployed verification.
swept file: yes

Scope: complete candidate/parent object trees and changelog blobs; all 16 SQLite tables; complete canonical dump, receipt chain, view and committed PR966 merge/gate evidence. Prior approved feature/runtime/history reviews were reused as instructed. No additional pre-existing preservation/runtime defect was found in this bounded sweep. Graph tools are unavailable in this session; the supplied canonical graph context covers a different root and cannot establish this checkout's freshness. SHA-1-checked loose/packed objects, exact local files and query-only in-memory SQLite supplied current evidence. No git command, suite, pytest, executable fixture or artifact writer was run.

Probe commands below used `PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"`; scripts and output remained under that scratch directory. Initial scratch probes used an incorrect `issue_num` column and then an incorrect view column layout/naive pipe split; corrected probes use `gh_number`, the actual eleven-column header and escaped-pipe-aware parsing. These were probe errors, not artifact failures.

- [Pass] **Both complete parent changelogs survive in order.** Actual merge `14cfab284dbf93b210f58f36c5e6d068a4286d2f` has parents `1f663b5345793389e83e5b64a4663d563bfedba9` and `1e83bfb9d792d9c2dd4650d2956d9ac182566c12`; candidate descends through `bc27798036265090255f6d796f476d1e41ece933` and `133bd1f07ca7a2d5f191b6ffd3d8f5a0082b57e4`. `final-refresh-proof.json:3`–5 in `TESTS-RESULTS/2026-10-08+GH-1003/pr-966/` names the parents/base. Command `python3 "$TMPDIR/review_probe.py"`, exit **0**, decisive output: `CHANGELOG earlier 3697 3697 whole ordered subsequence true`, `CHANGELOG integration 3681 3697 whole ordered subsequence true`. No fix needed.
- [Pass] **All 339 expected roadmap business rows survive, including exact raw_text.** The candidate preserves all 337 integration rows and its two own additions. The only business differences from the earlier 339-row candidate are GH949/GH912's integration-owned completion fields; both now retain Completed/✅, completed doc paths and NULL labels (`releases.sql:827`, `:828`). GH964 retains `in-progress` and the explicit pending D4/D5/operator decision (`releases.sql:830`); GH967 retains its original queue text/ratings (`:831`). All twelve remaining complete tables and nongeneration settings match both relevant parents; no qualified duplicate issue numbers exist. Command `python3 "$TMPDIR/supplemental_probe.py"`, exit **0**: `expected union all 339 business rows exact with integration precedence`, `integration admissions and nongeneration settings exact`. Main probe, exit **0**: `ROADMAP integration 337 candidate 339 business differences {}`, `qualified issue duplicates []`. No business correction needed.
- [Pass] **Canonical DB/dump and receipt digest agree; admissions are not backdated.** `releases.sql:3` and `:16` record generation **1515**; `:2551` scopes the latest rebuild to `reanchor:173`. Main probe, exit **0**: `CANONICAL dump exact generation 1515 integrity ok foreign key violations zero`, `CHAIN 1697 total 1701 breaks 173 tolerated 173 digest 8a7126b00e9d5c0c824ed16e1eaac1f195d4587b4f5edfd74e00113f49d2b4e5`. Pure serializer/digest functions are at `utils/py/releases_app.py:1094` and `:1303`; chain rules at `:5740`–5788. All integration receipts/events survive with nine/seven additions. Earlier own replay receipts/events are replaced (nine/seven removed), rather than copied into the integration chain; earlier parent objects retain that history. GH964/GH967 first_seen is current `2026-10-09T09:16:47Z`; GH964's qualified accepted-start is `09:16:51Z` (`releases.sql:3207`), matching `provenance.jsonl:6`. Supplemental probe, exit **0**: `replayed admissions current time, no backdate`. This establishes writer-shaped consistency, not independent observation of the producer's command history. No fix needed.
- [Pass] **Runtime and view retain integration bytes; new evidence is accounted for.** All five runtime paths listed in `final-refresh-proof.json:35`–40 exactly match integration modes/blobs. Complete tested-to-candidate comparison has **238** paths; every difference other than the authoritative union and own evidence/review receipts is an integration blob, including incoming skill/runtime material. The 12-path final refresh against the earlier parent consists only of ledger/view, integration doc moves/receipts and the refreshed proof/provenance. Seed `5c5b4ce6cef99b6a50d8c9a902aeef18261dc06e` adds only this relay scaffold; all other working files match committed candidate bytes. `LEADERBOARD.md:1` deliberately retains integration generation **1501**, blob `8909deb856d01e5c53569ac1d6fe360c63eea7d6`; all **312** lines/**295** ranked rows have valid ordinals, axes, sums, overrides and order (`:12` declares the columns). Supplemental probe, exit **0**: `238 tested-to-candidate paths all integration blobs except authoritative union and own evidence`, `refresh doc/receipt moves exact integration`, `whole view 312 lines 295 rows; ordinals axes calc overrides sort sound`. No manually authored runtime/test/registry resolution or view correction is needed.
- [Pass] **Gate reporting preserves the failed run and successful neutral control separately.** Both commands tested `4a965bff58c50b9bada89ad78c6230dec5112058`, not the refreshed head (`gate-result.json:3`, `gate-neutral-result.json:3`). Raw `gate.log:2798` reports **72 / 75**; `:2872`–2874 lists gh448-driver-lock-resolver, gh429-wave-reconcile-vendored-observe and gh358-wave-reconcile-vendored-paths. `gate.log:350` explicitly resolves the inherited override to the primary harness. `provenance.jsonl:3`–4 records the environment change; `gate-neutral.log:2700` reports **75 / 75** with rc **0** (`gate-neutral-result.json:12`). Complete before/after identity snapshots are equal in both JSON results. Both logs contain all **72** selected shell-suite headings and label the run **NOT promotion evidence** (`gate.log:2783`, `gate-neutral.log:2685`). Supplemental probe, exit **0**: `GATE gate rc 1 identity exact`, `GATE gate-neutral rc 0 identity exact failures []`, `RUNNING count 72` for each. No claim that the first run or refreshed head was green is warranted.
- [Nit] **Clarify the proof's row-count scope on its next evidence update.** `final-refresh-proof.json:34` says `"business_row_count": 337`; the independent complete-table comparison measures **337 integration rows and 339 candidate rows**, including GH964/GH967 (`releases.sql:830`, `:831`). Supplemental probe, exit **0**: `proof business_row_count 337 integration 337 candidate 339`. Label 337 explicitly as the integration count and record 339 as the candidate count. This ambiguity does not block preservation approval because the reviewer compared every expected row and field independently.
- [Unverified — needs clone run] **Final-head qualification remains pending.** `final-refresh-proof.json:43` and `provenance.jsonl:6` expressly leave exact-head second-full-clone release check and hosted smoke outstanding. Producer/harness must obtain them before claiming their completion. Keep GH964 operator D4/D5 and GH971 deployed refresh pending; neither was executed here. Approval closes this bounded review only.

Manual red controls changed only in-memory comparison inputs. Both commands used the env prefix above and exited **1**, with decisive output:

```text
python3 "$TMPDIR/review_probe.py" red-row
AssertionError: red: dropped GH964 admission fails preservation
python3 "$TMPDIR/review_probe.py" red-digest
AssertionError: red: altered receipt after-digest fails business digest
```

Relay closed (Approved), no further review turn needed. Handing completion to Producer (merge-cleanup) for final exact-head second-full-clone release check and hosted smoke. The harness owns the one-file commit.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
