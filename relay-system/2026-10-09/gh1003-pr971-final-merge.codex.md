# RELAY · GH1003 PR 971 final refreshed merge QA
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
6. **Commit only the relay file** (`relay(gh1003-pr-971-final-refreshed-merge-qa): <role> r<N>`); no push. **Stop** and report one line.
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

Candidate before scaffold: 092b92e601540a07af781a13f745d0b256cc3caa. Integration parent: 643aa0d0510c0ce0f52d649f749e6a88d3eb09d6. Earlier complete review: relay-system/2026-10-08/gh1003-pr971-merge.codex.md; renewed approved correction: relay-system/2026-10-09/gh1003-pr971-merge-r2.codex.md. Reuse those complete reviews for unchanged feature/runtime and old history. Incoming #953 runtime and integration receipts already have final Approved QA at relay-system/2026-10-09/gh1003-pr953-final-merge.codex.md and hosted qualification. Incoming #966 feature/docs/receipts also have Approved final QA at relay-system/2026-10-09/gh1003-pr966-final-merge.codex.md once present in integration. Reuse that receipt for identical incoming artifacts. Do not repeat already approved feature recon; review the final integration/preservation delta and whole artifacts involved.

Read TESTS-RESULTS/2026-10-08+GH-1003/pr-971/final-refresh-proof.json, provenance, gate-result.json, gate-neutral-result.json and raw logs. Independently compare complete parent changelogs as ordered subsequences; complete roadmap business fields and remaining business tables; canonical SQL/DB/digest/receipt-chain consistency; current status labels and exact raw_text. Writer-owned IDs, positions and admission timestamps may change but never backdate admission. Integration completed rows use NULL status_label. Confirm no duplicate issue identity and no business field loss. LEADERBOARD must match exact integration bytes. All incoming runtime differences against tested own candidate 9ce8e5b28ac4ba150548c97db8ab9c093f879f4c must match integration blobs exactly. No manually authored runtime/test/registry edits are expected. Account separately for newly added evidence and relay scaffolds.

Qualification truth: the identical small gate first failed with inherited XYZ_HARNESS pointing at primary, identity intact. With XYZ_HARNESS absent it passed validate.sh --sequential --subsystem small, identity intact. Both results and raw logs are committed; this is an environment-neutral successful control, not claiming the original run green. Final exact-head second-full-clone release check and hosted smoke remain outstanding. Keep #964 operator checks / #971 deployed refresh pending; do not execute them.

Graph context: Verify tier current canonical project Users-noelsaw-Documents-GH-Repos-XYZ-forge, root /Users/noelsaw/Documents/GH Repos/XYZ-forge, generation 2026-10-09T08:04:52Z. check_index_coverage reported metadata_match/no_recorded_issue for utils/py/releases_app.py and canonical merge_cleanup.py/ledger_merge.py; current deployed helpers hash match canonical. Coverage is best effort. A seeded review checkout is not this indexed root; use exact local artifacts/object reads for current preservation claims and state any gaps. Relevant source: replay_ops label loss is known and corrected in candidates using existing writer, broader repair PARKED.

Safety: pure read review only. No suite, pytest, fixtures or mutating DB verbs in this linked review worktree. Only edit this relay. In-memory parsing/comparison and red controls are fine. Return Approved or an observed blocker/Should with concrete input, citations and falsifier. Witness at least one preservation/digest red control; retain truthful limits. No promotion or production verification claim.

## Log

### Reviewer · Round 1 · codex

VERDICT: PASS
Basis: Approved for bounded final integration/preservation QA at `092b92e601540a07af781a13f745d0b256cc3caa`, seeded at `81cfc97facca2dea99a882941ab185feb2eb909b`. Both complete parent changelogs, the full expected business union, integration runtime/view bytes and current ledger consistency pass. Final exact-head second-full-clone release check and hosted smoke remain outstanding; approval does not attest promotion, deployed refresh or operator checks.
swept file: yes

Scope: complete candidate/parent object trees and changelog blobs; every row of all 16 SQLite tables; complete canonical SQL, receipt chain, view and committed PR971 merge/gate evidence. Prior approved feature/runtime/history reviews were reused as instructed. No additional pre-existing defect affecting this bounded preservation sweep was found; the older nine ledger advisories remain recorded in `TESTS-RESULTS/2026-10-08+GH-1003/pr-971/ledger-readback.txt:5` onward. No git command, suite, pytest, executable fixture or artifact writer was run.

Graph: Verify tier, canonical project `Users-noelsaw-Documents-GH-Repos-XYZ-forge`, different root `/Users/noelsaw/Documents/GH Repos/XYZ-forge`; current coverage generation is `2026-10-09T09:49:52Z`. Coverage reports serializer/SQL/changelog/view metadata_match, DB excluded and this relay/evidence directory missing. The graph trace call was unavailable under the approval policy; exact local serializer/chain source and SHA-1-checked loose/packed objects supplied current evidence instead. SQLite blobs were deserialized in memory with query_only enabled. An extra attempt to compare against historical PR966 candidate `e2e3f8a88ec646f57d607672e8d3b369b52b7c2e` failed object lookup (exit 1, `KeyError` naming that SHA); the successful incoming-artifact comparison below is against the actual integration parent. Historical feature QA is reused from its supplied Approved receipt, not claimed freshly repeated.

All probe commands below used `export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"`; scripts/output stayed under that directory. Scratch is discarded, so decisive outputs are retained here.

- [Pass] **Both entire parent changelogs survive in byte-line order.** Actual merge `23a32305834a320b7c6288dd9ce3d55ecf3c3b6b` has parents `c42aa067b4be7a2d7f222e43fa34fdb029c82124` and `643aa0d0510c0ce0f52d649f749e6a88d3eb09d6`; candidate descends through `79393b0535e2722d057aa9181c51c329a58395b1`. `CHANGELOG.md:71` retains incoming GH964 and `:87` retains own GH970. Command `python3 "$TMPDIR/review_probe.py"`, exit **0**: `CHANGELOG earlier 3693 3709 complete ordered byte-lines PASS`, `CHANGELOG integration 3697 3709 complete ordered byte-lines PASS`. No correction needed.
- [Pass] **Complete expected roadmap business union survives, including exact raw_text and labels.** Same command, exit **0**: `ROADMAP all expected business fields exact 340 earlier 338 integration 339 qualified 338`, `qualified issue duplicates []`, `all integration admissions and writer metadata exact`. Comparison includes title, section/marker, doc, issue URL, all rating/complexity/risk/effort fields and status_label, excluding only writer-owned ID/GID/position/timestamps for replayed rows. Both unqualified rows also survive. Integration wins only its actual completion changes: GH949/GH912 retain Completed/✅/NULL label (`releases.sql:827`, `:828`); GH964 retains `in-progress` and pending operator D4/D5 text (`:830`); GH967 remains queued (`:831`); own GH970 retains NULL label and exact 55/40/50/85 text (`:832`). All twelve remaining complete tables and nongeneration settings equal both parents. No business correction needed.
- [Pass] **DB/dump/digest/receipt chain agree, without backdated admission.** `releases.sql:3` records generation **1520**; `:2558` carries `reanchor:174` and current after-digest. Same command, exit **0**: `CANONICAL exact dump generation 1520 integrity ok foreign violations zero`, `CHAIN counted 1702 all 1706 breaks 174 tolerated 174 digest c0457b9417d98225b8a19196cf35d1ac9885329d040367f0fa33337eafa81e29`. Pure canonical serialization/digest helpers are at `utils/py/releases_app.py:1094` and `:1303`; chain rules at `:5740` onward. Every integration receipt/event survives, with five/three additions. Earlier own replay history is replaced: five receipts/three events removed, fourteen/ten added relative to that earlier candidate; original history remains in its parent objects. GH970 first_seen/updated_at are current `2026-10-09T09:50:05Z`/`09:50:06Z` (`releases.sql:832`), consistent with final-refresh provenance line **7**, not the historical capture date. This proves writer-shaped consistency, not independent observation of the producer's exact writer argv. No correction needed.
- [Pass] **Runtime, incoming artifacts and routine view retain integration bytes.** Same main command, exit **0**: `all 5998 candidate working paths match; seed only relay scaffold 81cfc97facca2dea99a882941ab185feb2eb909b`, `TESTED TO CANDIDATE 267 all other paths exact integration`. The exceptions are only authoritative changelog/ledger union and own committed evidence/PR971 review receipt. All five runtime paths listed in `final-refresh-proof.json:62` onward have exact integration mode/blob identities. The final refresh against the earlier parent comprises 36 paths: authoritative union, incoming #966 feature/docs/receipts, hosted qualification evidence, routine view, and own proof/provenance; no manually resolved runtime/test/registry bytes appear. `LEADERBOARD.md:1` deliberately retains integration generation **1515**, blob `c7837d3f65594278627c6178e2a4932096596393`, awaiting hosted refresh. Command `python3 "$TMPDIR/supplemental_probe.py"`, exit **0**: `whole view 314 lines 297 ranked rows: ordinals axes sums overrides order and identity uniqueness PASS`, plus exact integration matches for all fourteen inspected #966 feature/doc/original-receipt artifacts. Prior incoming approval: `relay-system/2026-10-09/gh1003-pr966-final-merge.codex.md`, quoted `VERDICT: PASS` and `STATUS: Approved`. No correction needed.
- [Pass] **Gate evidence retains the failed run and successful neutral control separately.** `gate-result.json:3` and `gate-neutral-result.json:3` both name earlier tested commit `9ce8e5b28ac4ba150548c97db8ab9c093f879f4c`, not refreshed head. Raw `gate.log:2804` says **71 / 75** and `:2877`–2880 names four failures: gh448-driver-lock-resolver, gh103-timeline-exporter, gh429-wave-reconcile-vendored-observe and gh358-wave-reconcile-vendored-paths. `gate.log:350` resolves `via=override` to the primary harness. `gate-neutral.log:2700` says **75 / 75**, matching rc **0** at `gate-neutral-result.json:12`; provenance lines **3**–4 distinguish ambient XYZ_HARNESS from its absence. Supplemental command above, exit **0**: `both runs selected exact same 72 suites`, `FAILED gate-neutral []`. Complete before/after identity snapshots match in both JSONs. Logs label the run NOT promotion evidence (`gate.log:2789`, `gate-neutral.log:2685`). Incoming PR966 hosted telemetry hash also matches its committed receipt, with 72 suite results/zero failures, explicitly scoped to `1864b5cd370013fbe431f949db2a31468cd21507` in `TESTS-RESULTS/2026-10-09+GH-591/wave-1864b5cd370013fbe431f949db2a31468cd21507/provenance.jsonl:1`. None of these receipts qualifies the refreshed PR971 head.
- [Unverified — needs clone run] **Final-head qualification remains pending.** `final-refresh-proof.json:69` and `provenance.jsonl:7` explicitly leave second-full-clone release check and hosted smoke outstanding. Producer/harness must obtain those final-head results before claiming their completion. GH964 operator D4/D5 and keep/extend/drop remain pending (`PROJECT/2-WORKING/GH-964-CLAUDE-CODE-MODS.md:20`); GH970's deployed Skills Army refresh remains post-merge acceptance (`PROJECT/1-INBOX/GH-970-CLONE-NAMING.md:26`). Neither was executed here.

Manual red controls changed only in-memory comparison inputs. Each command below exited **1** with the quoted decisive output:

```text
python3 "$TMPDIR/review_probe.py" red-row
AssertionError: red: dropped GH970 fails complete expected business union
python3 "$TMPDIR/review_probe.py" red-digest
AssertionError: red: altered latest receipt after-digest fails current business digest
python3 "$TMPDIR/review_probe.py" red-changelog
AssertionError: red: dropped integration heading fails whole-parent preservation
```

Required fixes: none. Relay closed (Approved), no further review turn needed. Handing completion to Producer (merge-cleanup) for final exact-head second-full-clone release check and hosted smoke; operator checks and deployed refresh remain pending. The Approved turn closes the token with `done`; the harness owns the one-file commit.



### Attestation · relay-drive — 2026-10-09T10:00:02Z
task: GH1003-PR971-FINAL-MERGE-QA
reviewer: codex
status: Approved
reviewed-head: 81cfc97facca2dea99a882941ab185feb2eb909b
added-range: 8627+8839
added-sha256: efddc9222fe8c29a03ca25599127aeacfe7e7c5689315e14950124e9b2c6b03e
<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
