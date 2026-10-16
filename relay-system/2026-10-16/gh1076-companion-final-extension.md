# RELAY · GH1076 companion correction final extension
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-15.
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
6. **Commit only the relay file** (`relay(gh1076-companion-final-extension): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **.relay-artifacts/gh1076-companion-final-packet.md** — the read-only path that
  `relay-drive.sh --artifact-file relay-system/2026-10-16/gh1076-companion-final-packet.md` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: codex   ·   Producer: codex-producer
- Started: 2026-10-16 UTC
- Definition of Done: The seven explicit questions in gh1076-companion-final-packet.md, complete applicable source sweep, actual controlled verification and honest trust/counter/publication limits. One independently reviewed final extension1/1. FAIL ends the extension without automatic repeat; no activation or merge authority.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer · Round 1

VERDICT: PASS
Basis: The bounded correction at d8a6f875 implements the approved companion contract within the explicitly accepted operator-trusted local boundary. No concrete Blocker/Should defect was found, including in the pre-existing portions of the two production files. This approves this separate final extension1/1 only; historical FAILs/counters remain. Publication verification is still owed; this is no merge, deployment or activation approval.

swept file: yes

Sweep: Read the entire seeded packet, canonical 647-line plan, 550-line ci-route.sh and 2775-line wave_reconcile.py, ROUTER qualification policy, AUTHORIZATION.md and EVIDENCE.md. Followed strict-reader callers, selector/writer/replay, committed receipt discovery, premerge entry point and publisher receipt/target/retry interfaces; inspected device configuration resolution and workflow environment wiring. Read retained positive/resume/manual drivers, results, fault logs, historical summary and interruption records; checked raw positive streams/container. This is a complete sweep of the requested production files, not an exhaustive repository or all historical evidence audit. Graph project XYZ-forge is the different primary checkout, generation2026-09-01T15:54:30Z; graph lookup returned no wave symbols and coverage marked changed/not-tracked inputs. Current exact source reads and literal caller searches supplied the evidence; no freshness/completeness claim rests on that graph.

- [Pass] Q1–2: Complete raw B→M scope is partitioned by the original functional predicate, with every other path sent to the strict canonical reader. The pair must be two flat siblings, one supported typed schema1.0 record, unique JSON keys, source-bound sequential v1 Small telemetry and digest, C's sole parent S, exactly two new100644 S→C additions and identical B→M addition/blob tuples. A third nonfunctional change cannot disappear through the projection. Filtering follows verification; failure retains original input. Citations: utils/py/wave_reconcile.py:496, :512, :789, :1073–1156. The legacy reader body is unchanged in the immutable revision comparison; strict mode is opt-in. No fix requested.
- [Pass] Q3: Selection, writer and replay all call content_source_identity; writer stores companions, including None, and replay requires that key and exact descriptor equality. Both owners use skills-army-content@2. Discovery accepts only wave schemas, not local schema1.0, and @2 outcomes are nested; default premerge excludes unsupported qualification namespaces. Fresh landing phases remain required. Citations: utils/ci-route.sh:18; utils/py/wave_reconcile.py:710, :758, :889, :961, :1209. No fix requested.
- [Pass] Q4: Retained native-command evidence supports source527760b83-17477 Small75/75, fresh landingc3fe69e0f-57271 Small75/75 and c3fe69e0f-3407 area9/9. Separate container streams match original bytes/digests; true launch IDs are recorded. The positive/resume drivers intercept only npm-ci setup and delegate every validating command to original run_bounded. Controlled PR9001076 metadata and copied existing dependencies are explicitly disclosed. Citations: companion-correction/positive.json (under TESTS-RESULTS/2026-10-16+GH-1076), gh1076-companion-resume-qualification.py.txt, qualification-record.json and the three *-validation.jsonl streams; EVIDENCE.md:3–21. No live GitHub qualification is inferred. No fix requested.
- [Pass] Q5: The manual driver and fault logs distinguish24 unsupported-shape/full observations from six deliberately injected fatal/fallback controls, wrong-tree replay refusal and generic premerge refusal. failure/config/process/environment controls stop with code6/no receipt; missing-profile attempts exactly one full fallback, deliberately failed; missing-full proof is fatal. These are negative-path evidence, not passing software runs. Four retained unchanged focused logs report81/0,23 tests OK,6 tests OK and23/0, with unchanged identity in focused.json. Historical-summary.json reports221/221 old/current equality with explicit metadata/compatibility limits; this reviewer did not independently rerun the historical reader or any suite. Citations: companion-correction/gh1076-companion-manual-controls.py.txt, manual-controls.json, fault-*.log, focused.json and historical-summary.json. No fix requested.
- [Pass] Q6: SHA-verified loose-object tree comparison12fa1656→d8a6f875 finds exactly two production changes, utils/ci-route.sh and utils/py/wave_reconcile.py, with no test/ or validate.sh change. Current production bytes equal d8a6f875 blobs. The diff extends existing owners, preserves the functional predicate and legacy reader, and introduces no broad TESTS exemption, runner or registry. Citations: utils/ci-route.sh:18; utils/py/wave_reconcile.py:496, :1073 and reviewer probe below. No fix requested.
- [Pass] Q7: The first attempt remains incomplete, last gh589 rc120/no summary; its later diagnostic does not establish the cause. PUBLICATION.md explicitly says the normal exact-source gate remains owed. Authorization, trust limits, prior FAIL/counters, no primary/hosted activation and no stable-main/savings claim are preserved. Citations: companion-correction/attempt1-interrupted/INTERRUPTION.json, OUTAGE-CONFIRMATION.json, EVIDENCE.md:23–29, PUBLICATION.md:3; PROJECT/2-WORKING/GH-1076-CI-POLICY.md:619. No fix requested.

Reviewer read-only probe: `PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp" python3 .relay-scratch/review_evidence.py` → exit0. It imports only the production telemetry parser, reads retained bytes, hashes evidence and reads SHA-verified loose commit/tree/blob objects directly; no git command, gate or executable fixture was run. Decisive output: `source-small 527760b83-17477 75/75`; `landing-small c3fe69e0f-57271 75/75`; `landing-skills-army-hq c3fe69e0f-3407 9/9`; `container: two original byte-identical streams; digest bound`; `provenance evidence digests: 7 matched`; `interrupted area: no summary; last suite ('gh589-xyz-mini-sync.sh', 120)`; `SHA-verified production delta: ['utils/ci-route.sh', 'utils/py/wave_reconcile.py'] ; no test/ or validate.sh change`. An in-memory width2 mutation of each stream was rejected with `profile phase contains extra stages, retries, omissions or drift`. Earlier probe revisions exited1: first attempted to read an unchanged packed subtree as loose; second incorrectly asserted the entire delta contained only production files although authorized docs/evidence also changed. Restricting traversal to changed subtrees and the assertion to production scope resolved those reviewer-probe errors; neither was a product failure.

Remaining verification: [Unverified — needs clone run] normal exact-source full publication gate and natural exact-head hosted results. These follow approval under the approved sequence; no future run is counted here. The original interrupted qualification is not upgraded to PASS. Fully fabricated consistent local evidence remains outside the accepted guarantee; no cryptographic producer authentication was requested or claimed.

Relay closed (Approved), no further turn needed. Producer/parent may proceed only with the already authorized publication verification and reporting.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
