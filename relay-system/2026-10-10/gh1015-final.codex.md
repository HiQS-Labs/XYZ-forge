# RELAY · GH-1015 independent final QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-10.
-->

NEXT: Producer
STATUS: Approved
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
6. **Commit only the relay file** (`relay(gh-1015-independent-final-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **gh1015-final-packet.md** (embedded below — read it here).
- Reviewer: codex   ·   Producer: codex-author
- Started: 2026-10-10

### Artifact — gh1015-final-packet.md
```
# Independent Codex final QA — GH-1015

Read the entire parent plan and recon map under PROJECT/2-WORKING/GH-1015-OBSERVER-PATH*, the full two changed production files relay-automation/marathon.sh and validate.sh, driver receipt path producer/writer in utils/py/marathon_drive.py, existing GH609 checker, CHANGELOG top entry, current owned ledger row, and all retained evidence/provenance under TESTS-RESULTS/2026-10-10+GH-1015. Compare against integration base 9a923f3cc131f432f2682e7a11f57d03597fb5df.

Operational envelope: local opted-in developer CLI observer; three changed production lines plus governed intake/review and retained manual artifacts. No new suite, registry entry, gate, controller, paid/live provider invocation, auto-continuation or merge. Manual-replay.py is a one-off evidence replay in TESTS-RESULTS, not a new registered test/gate. Grade actual requirements with commensurate complexity; no speculative enterprise layers. Reviewer writes only this relay, never production/evidence. Do not run suites or executable manual fixtures from the reviewer worktree; bounded read-only data/source inspection is allowed.

1. Does exact observer init abspath align with driver receipts for ordinary default and explicit physical/absolute/relative symlink targets, without changing strict attribution or qualification semantics?
2. Are missed-check sorting and GH609 comment correct, and is package exclusion evidenced?
3. Do retained nonempty candidate results support three valid and eight rejecting cases, all finite JSON sorted keys, and base/old-init/old-sort witnessed red controls? Are hashes/source revisions/identity brackets truthful?
4. Does all code/docs/ledger scope fit the approved plan and persisted 60/35/50/90 rating, neutral appeal and unknown recurrence? No unrelated machinery/new suite?
5. Is the implementation suitable for the pending classified full macOS pre-push gate, with PR readiness explicitly contingent on that gate (not falsely reported already passed)?

Append concrete findings and citations, swept file: yes/no, VERDICT PASS/FAIL/PARKED and Basis. Required behavior-change findings require Observed input/Affected scope/Falsifier. Approve if no required correction remains; acknowledge pending qualifying gate, do not equate this QA to passing tests. Follow the scaffolded status/tick/turn protocol; hand off to codex-author if needed.
```
- Definition of Done: All five questions satisfied with no unresolved required finding; qualifying full macOS gate remains mandatory before a ready PR.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer · Round 1 · codex

VERDICT: PASS
Basis: All five final-QA questions are satisfied within the stated local observer envelope. No required correction remains. Approval covers source review and retained evidence; PR readiness remains contingent on the full macOS publication gate.
swept file: yes

- [Pass] Read the complete packet, parent plan/recon, entire `relay-automation/marathon.sh` and `validate.sh`, driver receipt producer/writer, existing GH-609 checker, CHANGELOG entry and retained evidence. No additional required pre-existing defect found in the two-file sweep. Direct comparison to integration base `9a923f3cc131f432f2682e7a11f57d03597fb5df` found exactly two observer-line changes and one registry-comment change; driver source is identical. Scope matches `PROJECT/2-WORKING/GH-1015-OBSERVER-PATH.md:39`. Nearest graph project is the primary checkout, generation `2026-10-10T08:23:22Z`, not this worktree; direct local source governs. Reported coverage gaps at marathon.sh:416 and :694 were read.
- [Pass] Init now uses `os.path.abspath(args.product_root)` (`relay-automation/marathon.sh:267`), matching explicit-target storage at `utils/py/marathon_drive.py:325` and receipt serialization at :250. Ordinary default root is forwarded through MARATHON_ROOT (`relay-automation/marathon.sh:642–646`); explicit physical/absolute/relative targets receive the same argument at :565 and :604. Exact schema/execution/phase/lane/target/token predicates (:135–144) and qualification (:148–157,294) are unchanged against base. No reader-side realpath tolerance or driver/schema change was introduced.
- [Pass] Missed-check output sorts keys (`relay-automation/marathon.sh:240–241`) like normal output (:208). The GH-609 comment (`validate.sh:144`) reflects existing workload-scoped online-migration safeguards and offline exemption (`test/gh609-sdlc-agent-gaps.sh:113–119`). Archive inspection found 18 members, excludes marathon.sh, and every member matches live source, consistent with `skills/1-hourly/relay-automation/make-pkg.sh:12–30` and retained `TESTS-RESULTS/2026-10-10+GH-1015/package.log` (“3 pass, 0 fail”). No archive regeneration is needed.
- [Pass] Nonempty retained results support three valid and eight rejecting cases (`TESTS-RESULTS/2026-10-10+GH-1015/SUMMARY.md:9–17`, `provenance.jsonl:3–5`). Candidate counts are `[1,1,1,0,0,0,0,0,0,0,0]`, with three finite sorted JSON emissions. Base/old-init counts are `[1,0,0,0,0,0,0,0,0,0,0]`; old-sort retains valid counts but ordering `[false,true,true]`. Provenance records candidate exit 0 and sensitivity exits `[1,1,1]`. All 13 artifact hashes match; baseline provenance hash, candidate source revision `4ddc2ab4`, and base/isolated-mutation source hashes match. Identity brackets are byte-identical before/after at their respective revisions. Focused logs retain codex-turn 43/0 on base, GH-609 33/0 and package 3/0 on candidate, correctly distinguished in `SUMMARY.md:17`. These are retained synthetic observations, not a fresh runtime reproduction or live provider qualification.
- [Pass] Scope fits the approved plan and persisted rating (`PROJECT/2-WORKING/GH-1015-OBSERVER-PATH.md:45–55`, `releases.sql:842`, `CHANGELOG.md:3–11`). Base/current DB comparison changes only roadmap row 347 (GH-1015); release rows are unchanged. Rating remains 60/35/50/90, override NULL, neutral appeal and unknown recurrence. Changed paths comprise the three production lines, owned intake/ledger, review records and manual evidence. No new registered suite/member, gate/controller, continuation or unrelated production edit. The retained replay is explicitly a one-off manual artifact (`SUMMARY.md:5`).
- [Pass] Read-only probe command: `export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"; python3 .relay-scratch/audit.py`, exit 0. The scratch-only stdlib script compared stored object data/source, JSON/hashes, identity and archive members; decisive output: `artifact_hashes_match 13`, `base_candidate_mutation_source_hashes_match True`, `identity_brackets_equal True`, `package 18 marathon_excluded; all members match`, and ledger rating 60/35/50/90 with NULL override. Follow-up `python3 -` queried read-only SQLite and an in-memory base DB and compared candidate object data, exit 0: `ledger_changed roadmap_items [347]`, `ledger_changed releases []`, `candidate_commit_sources_match True`, `baseline_provenance_hash_match True`. A bounded `python3 -` hash-location query, exit 0, found `match byte delta 24`: the retained plan-review content matches `plan-attestation.json` SHA 24 bytes after its historical added-start offset; that offset is not a current-file locator. Preliminary summary probes exited 1 on my list-shape/schema assumptions; corrected queries supplied the cited evidence. No git executable or executable fixture was invoked. Evidence citations: `SUMMARY.md:3,15–17`, `provenance.jsonl:1–5`, and `relay-system/2026-10-10/gh1015-plan.codex.md` (“STATUS: Approved”).
- [Unverified — needs clone run] Full classified macOS pre-push gate remains pending, explicitly required at `PROJECT/2-WORKING/GH-1015-OBSERVER-PATH.md:49,59` and `SUMMARY.md:3`. Source is suitable to proceed to that gate; QA approval does not attest a passing gate or ready PR. Run the publication gate in a disposable full clone against final committed state, retain provenance/identity evidence, then inspect emitted PR base/head/checks. No suite, pytest, provider or publication command ran here.

Relay closed (Approved), no further turn needed. Producer codex-author proceeds with the pending clone gate and publication checks.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
