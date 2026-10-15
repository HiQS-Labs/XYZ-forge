# RELAY · PR1061 operator-authorized QA extension
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-15.
-->

NEXT: Reviewer
STATUS: Open
ROUND: 2 / 2

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
6. **Commit only the relay file** (`relay(pr1061-authorized-extension): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: TESTS-RESULTS/2026-10-15+GH-1059-review-corrections/, original gh1059-final.codex.md and canonical GH1059 acceptance; existing runtime/policy unchanged from original final sweep.
- Reviewer: codex   ·   Producer: codex-producer
- Started: 2026-10-15
- Definition of Done: _<fill in the acceptance criteria the Reviewer grades against>_

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log


### Attestation · relay-drive — 2026-10-15T03:04:19Z
task: RELAY-PR1061-EXTENSION-20261015
reviewer: codex
status: Approved
reviewed-head: b55594b7a1570c454dd37f59c1a1e889bd0bd8e7
added-range: 9139+6393
added-sha256: 045660b853cca6b08f23473e51585c6a12b7a64c982e5bec2d0908fa81d42df5
<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->


### Producer · Extension Round 1 (cumulative final QA round 4)

Authorization: Noel explicitly answered “Authorize one evidence-only review” and then extended tonight's batch: “I authorize you and the agent to do more 2 rounds of QA per PR than base/default. Please get as many PRs merged tonight as possible. And then do the full clone folder clean up.” Main conversation 2026-10-14 19:55 PDT, Sentinel_4231123aedc48191a8cec54c1d6544e0, parent delegation. This is extension1/2 beyond original3/3, not a reset; original relay-system/2026-10-14/gh1059-final.codex.md stays Escalated3/3 byte-identical to880d1452. This thread has the single two-round extension budget, never multiplied across restarts. No new CI test/case approval. PR1062 remains excluded.

Evidence-only first extension: original Round3 found no material runtime defect after sweeping both Python owners and four policy files; it failed solely because newer manual47/cleanup180 atfb6b7f28 and manual48 at359f7766 had provenance.json rather than required JSONL. Those three truthful records were appended ate4a8af1e, original retained. Inspect correction root provenance.jsonl and all-native raw logs/identity/provenance.json. Retained normal full publication ate4a8af1e passed409/409,1223s, two initial suites (gh360-scoped-receipt-chain-rebuild.sh and jog-queue.sh) passed built-in sequential retry. It is local full evidence at its named revision, not hosted full or first-attempt perfection. Publication result/log/telemetry under publication/; original source-only full record was followed by explicit commit/pr/result alias at1c4bc868 for same actual run (no rerun). Existing receipt-reader result at1c/880 is retained there. Doc-only followups atbee96e20 (110s) and880d1452 (73s) published normally, not full409 reruns. No new fixture or tests requested.

Current-base integration: canonical B1 initially handed off CHANGELOG because independently inserted sections weren't prefix-additive. Exact section-by-section comparison proves common preamble/sections identical and all additions retained. Canonical B1 then resolved disjoint ledger by keeping higher-generation ours and replaying GH1052 through writer. current-base/ preserves refusal, resolution and exact business-content comparison: all incoming business content retained, GH1052 only gid/first_seen/updated_at reminted by canonical replay, only new issue1059; incoming LEADERBOARD bytes preserved. Six runtime/policy files are byte-identical to880, original finalQA file also unchanged; current-base/preservation.json includes SHA256 for file-only verification. Ledger check zero failures/nine existing warnings. No code/policy changed during current integration.

Read the relevant artifacts in full, verify missing-JSONL falsifier and evidence attribution/limits, current-base preservation and original-history integrity. No new runtime review is necessary solely for this metadata correction; report any concrete in-scope defect if seen. Do not call earlier full gate a current-head gate: new normal publication after this integration, exact-head hosted checks/reviews, premerge receipts and destination macOS qualification remain Producer obligations. No actual cleanup occurred.

Read-only peer: only this new relay file writable, no Git command, network, test/validate/pytest or executable fixture. Narrow file/JSON/hash probes with bytecode disabled allowed. Append at absolute EOF exact heading `### Reviewer (codex) · Round 1`, `VERDICT: PASS` or FAIL, nonempty Basis and `swept file: yes` or no. On PASS header Approved/NEXT —, tick done RELAY-PR1061-EXTENSION-20261015. On FAIL leave truthful findings and hand off; only one extension round remains. Never edit original relay or counters. Handing off to Reviewer.

### Reviewer (codex) · Round 1

VERDICT: PASS
Basis: The original Round3 receipt-format finding is closed. The evidence-only correction meets the relevant canonical GH1059 acceptance while retaining original history and verification limits. No outstanding Blocker/Should or additional material pre-existing defect was found in this bounded evidence sweep. Current-head publication, hosted checks and destination qualification remain Producer obligations.
swept file: yes

Evidence paths below are relative to `TESTS-RESULTS/2026-10-15+GH-1059-review-corrections/` unless fully qualified.

- [Pass] The exact missing-JSONL falsifier is satisfied. `provenance.jsonl:1` retains source1fb2d9f4; `:2` and `:3` attribute manual47/cleanup180 to fb6b7f28; `:4` attributes manual48 to359f7766 and expressly excludes full180/publication qualification at that source. `all-native/shared-guard-results.json` retains matching before/after identity and rc0 for both earlier checks. `all-native/shared-guard-cleanup180.log:1921` reports “Ran 180 tests in 286.110s”, followed by “OK” at1923; `all-native/final-manual48.log:293` reports “Manual cases: 48”. Recorded inputs retain ordinary/published guard-removal red controls and the exit0 warning case; `all-native/git-warning-proof.json` retains the concrete warning. These are producer executions, not reviewer reruns. No new suite/case, runtime change or rerun is requested.
  Reviewer receipt probe, with `PYTHONDONTWRITEBYTECODE=1` and `TMPDIR="$PWD/.relay-scratch/tmp"`:
  ```sh
  python3 -c 'import json; from pathlib import Path; p=Path("TESTS-RESULTS/2026-10-15+GH-1059-review-corrections/provenance.jsonl"); r=[json.loads(s) for s in p.read_text().splitlines() if s.strip()]; want={("fb6b7f28",47),("fb6b7f28",180),("359f7766",48)}; have=lambda rows:{(x.get("source","")[:8],x.get("passed")) for x in rows if x.get("rc")==0}; assert r and want<=have(r) and not want<=have(r[:1]); print("records:",len(r),"; newer receipts: 3/3; historical-only control: fails")'
  ```
  Exit **0**; output: `records: 4 ; newer receipts: 3/3; historical-only control: fails`. The in-memory historical-only control fails the receipt predicate without altering an artifact.
- [Pass] Earlier full publication is accurately bounded. `publication/provenance.jsonl:1` attributes409/409 to e4a8af1e as local macOS parallel publication, explicitly not hosted landing/main promotion; `:2` adds commit/PR/result identity for the same run. `publication/attribution-correction.md:3` retains the earlier reader refusal and `:5` explains the alias without a rerun. The raw log records both initial failures and passing sequential retries (`publication/normal-full-publication.log:419`,425,431),409/409 at505 and1223s at915. `publication/result.json` retains identical before/after identity. The existing reader receipt at `publication/provenance.jsonl:3` belongs to1c4bc868. None is a current integrated-head full-gate result.
- [Pass] Integration history is explicit. `current-base/pr1061-second-current-base-resolution.json` retains the CHANGELOG refusal; `pr1061-second-changelog-preservation.json` records byte-identical common sections and retention of both sides' additions. `pr1061-second-ledger-resolution.json` records higher-generation ours plus writer replay of GH1052. `current-base/preservation.json:5` records incoming business-content preservation, with only GH1052 identity/timestamps reminted and issue1059 added; `:75` records incoming view preservation. `current-base/ledger-check.log` ends “check: clean (0 failures, 9 warning(s))”. These are retained producer comparisons/checks, not independently rerun Git merge-base or ledger-writer results.
- [Pass] Current runtime/policy and original relay bytes match all seven retained digests (`current-base/preservation.json:66`,74). The original `relay-system/2026-10-14/gh1059-final.codex.md:7` retains Producer/Escalated3/3 and the failed review. `current-base/qa-extension.json:4` preserves that budget and identifies cumulative round4 within two authorized extension rounds. No original counter or earlier turn was edited.
  Reviewer hash probe under the same environment:
  ```sh
  python3 -c 'import hashlib,json; from pathlib import Path; p=json.loads(Path("TESTS-RESULTS/2026-10-15+GH-1059-review-corrections/current-base/preservation.json").read_text()); checks=dict(p["runtimePolicySha256UnchangedFromPrior"]); checks["relay-system/2026-10-14/gh1059-final.codex.md"]=p["originalEscalated3of3FileSha256"]; assert len(checks)==7 and all(hashlib.sha256(Path(f).read_bytes()).hexdigest()==h for f,h in checks.items()); print("retained SHA256 matches: 7/7")'
  ```
  Exit **0**; output: `retained SHA256 matches: 7/7`. This checks seeded bytes against retained digests, not an independently fetched prior revision.
- [Unverified — needs clone run] Normal publication after current integration, exact-head hosted checks/reviews, premerge receipts and destination macOS qualification remain Producer obligations. Earlier runs attest their named revisions. No actual cleanup is established here.

Coverage and limits: reviewed the original relay, canonical acceptance, correction summary, receipt/identity/result metadata, recorded native manual inputs/results, raw-log summaries and current-base records; parsed retained manual output and full publication telemetry. No additional material defect was found in these evidence files. No new runtime sweep was required for this metadata-only extension; the original Round3 owns the prior full runtime/policy sweep. Verify-tier graph project `Users-noelsaw-Documents-GH-Repos-XYZ-forge`, generation2026-10-13T06:40:42Z, describes the maintained primary rather than this worktree. Coverage has missing metadata for the new plan/relay and no indexed correction scope; direct seeded files supplied authority. No Git command, network request, suite, pytest, executable fixture, repository import or gate ran. An initial file-only parser exited1 because it assumed unittest's OK was the last line; OK is at1923 before buffered stdout, and the corrected parser exited0. This was a reviewer parser assumption, not a product failure.

Relay closed (Approved), no further review turn needed. Handing completion to Producer (codex-producer) for current-head gates, hosted/premerge evidence and destination qualification before authorized merge or cleanup.



### Producer · Extension Round 2 (cumulative final QA round 5, final allowance)

After your first PASS and before publication, my raw diff review found an error in my current-base changelog handoff: I keyed sections by heading, but six historical date headings repeat. The dict comparison collapsed earlier occurrences and dropped238-line-diff historical entries. This was my preservation error, not a runtime defect or missing test. Original false comparison evidence is retained and explicitly superseded; extension1 PASS/history remains. No new allowance or reset; this is final extension2/2, cumulative5.

Corrected CHANGELOG is built from the COMPLETE incoming0215 bytes, inserting only the exact two contiguous GH1059 sections from880 before the common PR1054 heading. Removing that exact single addition must equal the complete incoming bytes; the same check on the pre-correction blob is a witnessed negative control (false). `current-base/changelog-duplicate-heading-correction.json` retains hashes/counts/failure attribution; `changelog-incoming.md` and `changelog-own-additions.md` preserve exact comparison inputs, including repeated historical headings. Incoming196 headings plus2 own gives198, all retained. Previous section-key proof is explicitly invalidated. No other current-base/runtime/policy/originalQA byte changed except truthful status metadata.

Review the actual entire CHANGELOG and exact byte equation against retained input, not a map keyed by heading. Recheck the required JSONL receipt correction, unchanged six runtime/policy+originalQA hashes, and current-base ledger content proof. Acceptance is the explicit canonical GH1059/evidence contract in this packet; the scaffold's unfilled Setup placeholder does not introduce new requirements. Current-head normal publication, exact-head hosted checks and destination qualification remain pending and Producer-owned. No tests or CI cases added.

Read-only, only this thread writable, no Git/network/test/pytest/executable fixture. File/JSON/hash probes with bytecode disabled allowed. Append `### Reviewer (codex) · Round 2`, VERDICT PASS/FAIL, Basis and swept file yes/no. PASS header Approved/NEXT —, tick done RELAY-PR1061-EXTENSION-R2-20261015. FAIL Escalated2/2 and hand off; no further round remains. Handing off to Reviewer.
