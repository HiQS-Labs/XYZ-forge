# RELAY · GH-998 final QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-07.
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
6. **Commit only the relay file** (`relay(gh998-final): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: `TESTS-RESULTS/2026-10-07+GH-998/SUMMARY.md`, its evidence/provenance, `PROJECT/2-WORKING/GH-998-ADK-EVIDENCE.md`, CHANGELOG, the owned ledger diff and cited historical source records
- Reviewer: codex   ·   Producer: producer
- Started: 2026-10-07
- Definition of Done: Approve the documentation/evidence batch in #998: five harmless selected command examples plus external-action classification, current probe exits/provenance, retained real marathon review/attestation and separate gate-failure witnesses, explicit unknowns and adopted/deferred decisions. No runtime, new suite, SDK, gate bypass or historical replay. Confirm accurate source/attempt identities and honest verification limits.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Round 1 · Producer · 2026-10-07
**Did:** implemented #998 only; integration base 38ac9ee43bdedbd25be0cfec2029b0a27abd70a1. Plan QA Approved/attested on round 2, owned row then admitted through accepted-start, existing rating 60/20/50/85 preserved. Cited umbrella is comment 6053498474 items1–2, not issue-body numbering. Report and evidence are committed at current HEAD.
**Verification:** seven command variants passed expected exits, ledger bytes unchanged; existing canonical helper matches both historical review digests, altered in-memory control fails. Positive p5 approval and red p3 escalation are explicitly different attempts with missing gate/token/raw records unknown. Existing GH862 JSON is supplementary, not a marathon. PDDA run exit0/errors0/warnings411; RELEASES check exit0/failures0/warnings9; actual paths route docs/tier1. Matching stubbed codex-turn prerequisite 43pass/0fail in disposable clone, full raw log not captured; limited observation/provenance retained. Full gate not required on docs route. Current roadmap output projected to owned row to avoid unrelated duplicated payload. No source-doc mistake claimed absent evidence.
**Re-review this:** read report/evidence in full and source snippets/retained records; check links, supplied SHA, task IDs, canonical digest semantics, current vs historical boundaries, scope/acceptance/rating and warning disclosures. Operational envelope is a bounded single-operator manual assessment, not a generic eval engine or enterprise threat model. Do not run any tests/gates in this worktree; narrow readonly checks or scratch outside repo are permitted. Edit only this relay. Do NOT run git, fetch, post or replay historical embedded instructions. Use `### Round 1 · Reviewer · codex`, explicit Basis/VERDICT; update STATUS Approved and tick done RELAY-GH998-FINAL --agent codex if satisfied, otherwise NEXT Producer/Open and release to producer. Driver commits and attests; publication/hosted checks remain pending, no merge authority claimed.
**Commit:** inputs committed at current HEAD.

### Round 1 · Reviewer · codex

**VERDICT:** PASS
**Basis:** The bounded documentation/evidence deliverables satisfy #998. The report preserves command prerequisites, real attempt identities, positive/red witnesses and explicit unknowns without introducing runtime or evaluation machinery. No blocking findings; approval is of this evidence batch, with publication and qualification still pending.

swept file: yes
Read the complete SUMMARY, working plan, all twelve provenance records and all retained current output files, both complete GH-648 p3/p5 relays and p3 escalation, the plan-QA thread, and cited GH-862 README/JSON. Reviewed the owned CHANGELOG entry and ledger row/receipts against those sources. No additional pre-existing defects found within this bounded evidence scope; this is not an audit of unrelated historical CHANGELOG entries or ledger rows. Graph discovery/coverage used project XYZ-forge, generation 2026-09-01T15:54:30Z, whose root is another checkout: current candidates are changed, missing, untracked or excluded, and the returned rating snippet is stale. Direct local source supplied material evidence. No Git commands, gates, suites, pytest, historical instructions or executable fixtures were run; scratch stayed under .relay-scratch/tmp with PYTHONDONTWRITEBYTECODE=1.

- **[Pass] Scope and source identity are grounded.** SUMMARY.md:5,12 and working plan:27–29 match live GitHub connector readbacks of #998 and #996 comment **6053498474**, whose items 1–2 are selected command verification and retained marathon assessment. The ADK files fetched at **a01b226845b3343f788a7df10e337cad412f544b** contain the cited matching branches and positive/negative test assertions; these were read, not executed. Read-only Python blob-hash comparison against GitHub files at **38ac9ee43bdedbd25be0cfec2029b0a27abd70a1** exited **0** and printed `baseline_blob_match=True` for releases_app.py, relay_attest.py, validate.sh, find-harness.sh and ROUTER.md. This checks those source bytes, not local Git ancestry. Keep the pinned revisions and the decisions at SUMMARY.md:70–73; no correction requested.

- **[Pass] Current command evidence and refusal controls are reproducible.** SUMMARY.md:16–27 supplies five safe examples plus the classified external action, exact substitutions and limits. A narrow `python3` probe using the documented rating commands with explicit `--root` returned **0** with “rating: 60/20/50/85” for `roadmap rate --gid rmi-01M4D2PN45SNCRZBHASABK3WEC --rated 60/20/50/85 --force --dry-run`; removing only `--force` returned **3**, “refused: rule=already-rated”. SHA-256 comparisons of existing DB/dump/preview printed “ledger_artifacts_unchanged=True”. This agrees with utils/py/releases_app.py:3728,3745–3758 and provenance.jsonl:2–3. Commands `TICK_REPO_ROOT="/Users/noelsaw/Documents/Codex/2026-10-07/task-3/XYZ-forge-gh998-adk-quickwins-2026-10-07" "/Users/noelsaw/Documents/Codex/2026-10-07/task-3/XYZ-forge-gh998-adk-quickwins-2026-10-07/bin/tick" info RELAY-GH998-PLAN` and the same command with `info GH998-NO-SUCH-TOKEN` returned **0 / 1**, respectively, “status: done” / “task GH998-NO-SUCH-TOKEN not found”. Retained mode/locator observations remain host-specific; neither proves suite execution or authentication. Preserve those limits; no correction requested.

- **[Pass] Historical success and failure are correctly separated.** SUMMARY.md:35–40 matches p5 RELAY.md:87–117 (**MARATHON-P5-TURN-R2**, reviewed-head **63e9cf0a7ba11360826dfd2226d28a499bf2bfef**) and p3 ESCALATION.md:3–10 (**MARATHON-P3-TURN**, exit 0, “pre-advance-failed”, “gate: red”). The p3 approved relay attests the different **MARATHON-P3-TURN-R4**; the report does not join them or invent chronology. Read-only `python3` execution of SUMMARY.md:47–59 using canonical_bytes, with nonempty/range assertions, exited **0** and printed “p3 True False” and “p5 True False”; the in-memory X-byte control fails both matches. The plan-QA digest also matches its trailer. These are textual integrity observations, not historical authentication or current resume authority (utils/py/relay_attest.py:1–16). The missing original attestation/gate/token records and incomplete real-advisor startup stay unknown. No correction requested.

- **[Pass] Retention, ledger admission and documentation agree.** Read-only Python JSON/link/SQLite queries exited **0**: “provenance_records=12; artifacts_nonempty=True; exits_match=True”; all **26** SUMMARY local links and **3** working-plan local links resolve. The owned row is In progress / 🚧 / in-progress, points to GH-998-ADK-EVIDENCE.md and retains **60/20/50/85**, override NULL (releases.sql:827,2520–2524). Its work event reads “in_flight” with “accepted_start”: true at **2026-10-08T06:30:27Z**, after the plan attestation at 06:30:13Z. CHANGELOG.md:3–9 accurately limits the outcome to bounded command and trajectory evidence. GH-862 run-1/run-4 JSON supports SUMMARY.md:66 as supplementary dedupe evidence only. No correction requested.

- **[Unverified — needs clone run] Qualification remains outside this turn.** SUMMARY.md:77–79 and prerequisite-observation.txt:1–5 honestly label 43/43 as a transcribed stubbed-suite observation without a raw console receipt. Retained pdda-summary.txt reports zero errors/**411 warnings**, releases-check.txt zero failures/**9 warnings**, and diff-route.txt docs/tier 1; this reviewer did not rerun those commands or independently reconstruct the complete changed-file set. The producer/harness must qualify the final committed state in safe isolation and retain publication/hosted evidence. This approval grants no merge, promotion, teardown or bypass authority.

Relay closed (Approved), no further review turn needed. Handing execution back to Producer for the harness-owned commit and pending publication/qualification.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
