# RELAY · GH-1000 plan QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-11-10.
-->

NEXT: Producer
STATUS: Approved
ROUND: 2 / 4

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
6. **Commit only the relay file** (`relay(gh1000-plan): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: `PROJECT/2-WORKING/GH-1000-EVIDENCE-LINKED-CONSOLIDATION.md` (the plan; Phases 1–4 are intentionally still "Pending plan QA")
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-11-10
- Definition of Done: see "Plan QA brief" below.

### Plan QA brief

**Goal.** Pre-implementation QA of the plan for umbrella issue #1000 (https://github.com/HiQS-Labs/XYZ-forge/issues/1000; read it with `gh issue view 1000 --repo HiQS-Labs/XYZ-forge` if network is available, otherwise the "Asks" are restated in the plan's Scope and Acceptance map). The issue follows #996 checklist item 6: connect execution ID, invocation ID, token, transcript, gate receipt, result receipt and attestation so one failed or resumed phase can be reconstructed from a single starting record, without a second task-state store or event writer.

**Operational envelope.** A documentation-only PR in a single-operator local developer toolkit. Grade against the issue's stated requirements and commensurate complexity. Do not ask for new tests, suites, gates or scripts (AGENTS.md "No new tests", GH-831), and do not ask for enterprise or multi-tenant machinery. The issue itself withholds authorization for migration, deletion, deployment and merging of prototypes.

**Read.** The plan in full; `AGENTS.md` (No new tests, Verified beats plausible); and spot-check the plan's Phase 0 claims against the source: `utils/py/releases_app.py` (`load_work_evidence`, `work_events`, `_record_work_event`, `cmd_work_status`), `utils/py/jog_run.py` (execution id creation, `publish_jog_receipt`), `utils/py/marathon_drive.py` (`write_terminal_result`, `save_transcript`), `MACHINE-CONTRACTS.md`, `utils/py/board_sync.py`, `utils/py/work_connectors/`, `src/flightdeck/`, `addons/paperclip-dashboard/`, and the GH-1254 records under `TESTS-RESULTS/2026-11-08+GH-1254/`, `TESTS-RESULTS/2026-11-08+GH-1358-rehearsal/` and `relay-system/2026-11-08/marathon-gh-1254-*.md`.

**Questions.**
1. Are the Phase 0 recon claims true in the actual paths? In particular: (a) one shared reader `load_work_evidence` consumed by board policy, labels connector, Flightdeck and Paperclip; (b) the execution ID is absent from committed `work_events` payloads; (c) `marathon-drive/result@1` carries no transcript path and the only join is `head_sha` = transcript commit; (d) only approved results are copied into `TESTS-RESULTS/`. Cite file:line for anything wrong.
2. Is any requirement of issue #1000 missing from the Acceptance map, or mapped to the wrong phase? Is deferring the checklist section 4 interface demonstration and the "add only missing references" work to follow-on issues a defensible reading of "Scope now", or does the issue require them in this PR?
3. Does the plan extend the existing subsystems (PDDA plan doc, RELEASES CLI writer, `TESTS-RESULTS/` manual check) without adding a second reader, writer, store or scheduler?
4. Are the proposed dispositions in the Plan table supported by the recon, and is any of them a decision the plan should not pre-empt (for example retiring GH-402 Phase 2, or freezing Paperclip)? They are recommendations for the operator, not actions.
5. Is the verification falsifiable? Step 2's walk must be able to report MISSING, and step 3's red control (GH-1064, no execution records) must fail a walk that reports success on empty input. Is GH-1254 a sound worked example, and is the stated caveat about its unusually complete records sufficient?
6. Is the rating `45/35/50/55` grounded (appeal neutral 50 with no operator value; severity not inflated; recurrence correctly stated as not applicable)?
7. Blast radius, ordering and rollback: anything understated for a docs + one-roadmap-row change?

Flag anything wrong, missing, incorrectly scoped, or over/under-engineered, with file:line. Set STATUS to Approved if the plan can proceed.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer · Round 1

VERDICT: FAIL
Basis: The docs-only approach is proportionate, but the reconstruction acceptance omits part of the requested chain and one recon statement overstates a runtime invariant. These need small plan edits before execution.
swept file: yes

- [Should] **R1 — Require the complete evidence chain in the walk.** `PROJECT/2-WORKING/GH-1000-EVIDENCE-LINKED-CONSOLIDATION.md:147–158` currently permits an attempt to pass with only result, transcript and review trailer. A review trailer is not the separate machine attestation; neither invocation identity nor gate binding is required by that pass condition. Add a per-attempt checklist/table for execution ID, invocation identity/path (explicitly say if no independent invocation ID exists), token, transcript, gate receipt, result and attestation, each resolved or MISSING/UNKNOWN with its join and reason. Bind gate/review evidence to the relevant candidate; a green label alone is insufficient. Keep this a manual check, with no new machinery.
  Observed input: Reading `TESTS-RESULTS/2026-11-08+GH-1254/jog/gh1254-exec2-gateretry2/marathon-result.json` yields execution `gh1254-exec2-gateretry2`, token `MARATHON-GH-1254-OUTER-LOOP-BORROW-DECL-TURN-2`, head `fc7896aae3349e89d0e929aa1ca299f2fa678f2d`, green gate and a machine-local `.git/relay-attest/...json` path. Its published directory contains `gate-receipt.json`, `landing.json`, `marathon-result.json`, `provenance.jsonl`, `receipt.json`; no attestation file. Probe: `python3` standard-library `json.loads(Path(path).read_text())`, print those fields and sorted parent filenames; exit 0, decisive output as quoted above. The current walk could omit this attestation gap entirely.
  Affected scope: Phase 2's manual reconstruction and its Phase 4 missing-reference conclusions, for every discovered attempt including gate retries.
  Falsifier: Walk that same published bundle without access to the original runner: it must report an unresolved attestation unless an independently located committed copy is actually linked and its binding checked; it must not call the full chain complete merely because the transcript has an approval trailer. GH-1064 must still return UNKNOWN on zero attempts.

- [Should] **R2 — Qualify the transcript-commit join.** At plan lines 124–125, replace the unconditional “`head_sha` equals the commit that saved the transcript” with a candidate join to investigate per attempt. `utils/py/marathon_drive.py:216–222` reads receipt-time HEAD from `target_repo_path` or root; `:2322–2344` writes/commits the transcript in root (or its configured archive); `:2859–2867` can run a post-approval command before terminal receipt generation. `MACHINE-CONTRACTS.md:105–109` explicitly calls head_sha observational receipt-time HEAD. Absence of a transcript field is supported, but equality is not a general contract. Document how the walk falls back to transcript content/token and provenance when that equality is absent or ambiguous, and report unresolved joins honestly.
  Observed input: The actual writer uses `repo = _RESULT.get("target_repo_path") or _RESULT.get("root")` followed by `rev-parse HEAD`, whereas `save_transcript` commits with `git -C root`; these are distinct supported roots. Source inspection, not an executed failure claim.
  Affected scope: The Phase 0 statement and Phase 2 reconstruction procedure; no runtime change requested.
  Falsifier: A same-root, unchanged-HEAD attempt may establish the equality for that record. A target-root/archive-root or post-approval-commit case must not inherit that equality without evidence; missing/ambiguous association must remain MISSING/UNKNOWN.

- [Pass] **Reuse and publication recon:** `utils/py/releases_app.py:1508–1512` emits Jog status and global ID without execution identity; `:5746` owns the shared reader; `utils/py/board_sync.py:1191–1192`, `utils/py/work_connectors/__init__.py:145–147`, `utils/py/releases_cycle.py:55` and `src/flightdeck/connectors.py:13` establish the consumer chain. Paperclip fetches `/flightdeck.json` at `addons/paperclip-dashboard/app.js:106`. `utils/py/jog_run.py:1083–1084` refuses publication except approved green results. The proposed reuse and failed-result gap are grounded.
- [Pass] **Proportionate work and negative control:** plan lines 140–141, 153–155 and 163–169 reuse existing owners, reject empty-input success, and add no suite/store/scheduler. The scope paragraph explicitly leaves dispositions as operator recommendations; retirement/freeze proposals therefore do not themselves authorize action. The rating section states neutral appeal and no incident recurrence claim. GH-1254 is a useful worked example with the explicitly stated hand-preservation caveat; no broader representativeness claim should be inferred.
- [Unverified — needs source access] `gh issue view 1000 --repo HiQS-Labs/XYZ-forge --json body` returned “error connecting to api.github.com”. The issue's live authorization wording and sibling-repo state were unavailable. On the supplied restatement, deferring implementation is a defensible bounded PR, provided the umbrella stays open and the interface demonstration remains explicitly owed, as the acceptance map states. Do not describe the scope ambiguity as an operator decision already obtained.
- [Unverified — needs clone run] No validate/test/pytest or executable fixtures were run. The planned PDDA/RELEASES checks and final gate remain implementation-stage obligations. Full plan swept; no additional pre-existing plan defects found beyond R1–R2 above. Runtime files were spot-checked only, not exhaustively audited.

Handing off to Producer (claude-a) — disposition R1–R2, update the plan, then request the next reviewer turn.

### Producer · Round 2

- **R1 — Implemented.** Plan step 2 now requires a seven-cell row per attempt (execution ID, invocation, token, transcript, gate receipt, result receipt, attestation), each `RESOLVED` with its join or `MISSING` / `UNKNOWN` with a reason. A trailer never fills the attestation cell; gate and review cells count only when bound by SHA to the attempt's candidate. Step 3 gains a second control: the published `gh1254-exec2-gateretry2` bundle must show attestation `MISSING`. Still a manual check; no machinery added.
- **R2 — Implemented.** Phase 0 missing-reference 2 now calls the `head_sha` match a candidate join, cites `marathon_drive.py:216`, `:2322`, `:2859` and `MACHINE-CONTRACTS.md:105` for why it is not a contract, and step 2 states the fallback (token in header and commit message) and that an ambiguous match is `UNKNOWN`.
- **Unverified note on scope — Implemented.** The scope paragraph now says the plan proposes the narrow reading, the operator has not ruled on it, and the interface demonstration stays owed.

Handing off to Reviewer (codex) — re-review the plan at the new HEAD.

### Reviewer · Round 2

VERDICT: PASS
Basis: R1–R2 are resolved. The full plan is adequate to proceed as the bounded documentation slice proposed, with umbrella completion and interface implementation still owed. Approval is plan QA, not acceptance of the proposed dispositions or a claim that the implementation-stage checks passed.
swept file: yes

- [Pass] **R1 resolved; reconstruction can expose gaps.** `PROJECT/2-WORKING/GH-1000-EVIDENCE-LINKED-CONSOLIDATION.md:155–170` requires all seven cells, explicit unresolved reasons, candidate-bound gate/review evidence, and both empty-input and missing-attestation controls. Probe: standard-library Python `json.loads(Path("TESTS-RESULTS/2026-11-08+GH-1254/jog/gh1254-exec2-gateretry2/marathon-result.json").read_text())` plus `sorted(x.name for x in p.parent.iterdir())`; exit 0. Decisive output: execution `gh1254-exec2-gateretry2`, candidate `fc7896aae3349e89d0e929aa1ca299f2fa678f2d`, machine-local `.git/relay-attest/...json` path; bundle files `['gate-receipt.json', 'landing.json', 'marathon-result.json', 'provenance.jsonl', 'receipt.json']`. The planned MISSING result is grounded; a trailer cannot fill it.
- [Pass] **R2 resolved; fallback is bounded.** The plan's “It is not a contract” qualification and per-attempt fallback (`:124–130`, `:161–163`) agree with `utils/py/marathon_drive.py:217–221` (target receipt HEAD), `:2333–2344` (transcript archive and root commit), `:2859–2867` (post-approval command), and `MACHINE-CONTRACTS.md:104–109` (observational head versus reviewed candidate). Ambiguous transcript associations remain UNKNOWN.
- [Pass] **Scope and reuse remain proportionate.** The scope explicitly says “the operator has not ruled on it” and “interface demonstration stays explicitly owed”; the acceptance map ends “The umbrella stays open after this PR.” Plan steps 1, 5 and 6 require evidence-backed inventory, interface comparison, and drafts awaiting agreement. The proposed dispositions remain recommendations. Shared-reader consumers remain visible at `utils/py/board_sync.py:1191–1192`, `utils/py/work_connectors/__init__.py:145–147`, `utils/py/releases_cycle.py:55`, and `addons/paperclip-dashboard/app.js:106`; approved-only publication is enforced at `utils/py/jog_run.py:1083–1084`. No additional pre-existing plan defects found in the full sweep; runtime sources were spot-checked rather than exhaustively audited.
- [Unverified — needs source access] `gh issue view 1000 --repo HiQS-Labs/XYZ-forge --json body` exited 1: “error connecting to api.github.com”. Live issue wording and sibling-repo claims were not independently refreshed. Approval relies on the supplied issue restatement and the plan's explicit unresolved scope boundary; it does not establish an operator decision.
- [Unverified — needs clone run] No validate/test/pytest or executable fixtures run. Plan step 7 and final artifact QA remain obligations after the planned documentation and manual receipt exist.

Relay closed (Approved), no further turn needed. Producer may proceed with the planned documentation work and preserve the stated scope caveats.


### Attestation · relay-drive — 2026-11-11T06:06:06Z
task: RELAY-gh1000-plan
reviewer: codex
status: Approved
reviewed-head: 712ee432d57a5f4ba5f4de894beb933b64179d9e
added-range: 16168+3164
added-sha256: 36085d4f0ec6bb2bac117bae97872cc5d26cc3a6342a1301cb16a683cea296b2
<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
