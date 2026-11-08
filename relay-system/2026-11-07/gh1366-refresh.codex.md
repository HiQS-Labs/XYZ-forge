# RELAY · GH-1366 integration refresh QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-11-07.
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
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
   Reviewer headings may be `### Reviewer · Round N`, `### Round N · Reviewer · <agent>`, `### Reviewer (<agent>)` (optionally followed by `— rN`), or `### Reviewer — Round N` (optionally followed by `(<agent>)`); follow the heading with a non-empty review body.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(gh-1366-integration-refresh-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: `PROJECT/2-WORKING/GH-1366-PROPORTIONATE-REVIEW.md`, `TESTS-RESULTS/2026-11-07+GH-1366/`, `AGENTS.md`, `GUIDING-PRINCIPLES.md`
- Reviewer: codex   ·   Producer: producer
- Started: 2026-11-07
- Definition of Done: Previously approved policy wording unchanged; ledger refresh preserves integration Jog state and own task rating/status through supported writers.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Review request
Review the integration refresh section and ledger-merge.json, plus earlier final QA.
This is a narrow recheck after ledger-only merge; policy wording remains the approved version.
Questions: are evidence limitations, reminted row/admission disclosure and scope truthful?
Does any concrete source defect require correction before PR publication? No runtime changes.
Verify current ledger row and Jog comparison if useful via read-only SQLite; no Git or test suites.

## Log

### Reviewer · Round 1

Ship — approved for the narrow integration refresh.

VERDICT: PASS
Basis: Current policy meets the earlier approved textual contract; the integration disclosure distinguishes preserved task fields from replayed identity/time. No observed source defect requires correction before PR publication. This is source/evidence QA, not final-head gate qualification.
swept file: yes

- [Pass] Policy still matches the earlier final review's quoted requirements: AGENTS.md says "For every new or materially changed decision gate" and "Rerunning unchanged coverage does not require a fresh mutation"; GUIDING-PRINCIPLES.md appendix says the ordering "does not exempt a control" from North Star proportionality and "Preserve containment". GH-831's no-new-tests rail remains. No correction needed.
- [Pass] Integration disclosure is candid: PROJECT/2-WORKING/GH-1366-PROPORTIONATE-REVIEW.md, Integration refresh, states the new row replaces the branch-local row and "its admission time is replay time, not the original start." It names supported writers rather than implying identity/history preservation in the current row. No correction needed.
- [Pass] Current task fields agree with ledger-merge.json's task tuple. Read-only probe: `python3` with `sqlite3.connect('file:releases.db?mode=ro',uri=True)`, query `select * from roadmap_items where gh_number=1366`; exit 0, decisive output: global_id=rmi-01M6WRA7H35N01X2B3EA0V9W6J, rating_pri/sev/appeal/effort=65/35/50/90, rating_ovr=null, section="In progress", status_label="in-progress", doc_path="PROJECT/2-WORKING/GH-1366-PROPORTIONATE-REVIEW.md", first_seen="2026-11-08T04:57:51Z". Initial query used nonexistent issue_number and exited 1; corrected query above supplies the evidence.
- [Pass] Evidence boundaries remain explicit: SUMMARY.md says "manual textual verdicts, not measured reductions in friction or runtime tests"; provenance.jsonl labels ledger work "merge working state; committed with merge; not runtime qualification". Earlier PDDA exit 0 is tied to revision 6ea98fb2400a918fbeb512316c839cb21e74c039, not represented as a new integration-head execution; pdda.log ends "no errors, 97 warning(s)". No correction needed.
- [Nit] ledger-merge.json records "jog_rows_preserved": 31 and a complete/nonempty comparison method, but retains no comparison command or row digest. My read-only `select count(*) from jog_queue` returned 31 (exit 0); count alone cannot independently establish full equality against integration cf5bfe6881ef3bd66bc062727e49ef99969311b3. Optional improvement: retain the exact comparison command and paired digests in a later evidence refresh. This review accepts the producer's recorded comparison as reported evidence, not an independently repeated comparison or proof of writer execution.

Whole-file sweep: read the policy files, complete active plan, evidence records and earlier final QA. The earlier QA's already parked reconciliation-ownership contradiction remains; no additional pre-existing source defect identified. No Git, suites, pytest or executable fixtures ran. Historical policy byte identity and original branch history were not independently compared under the no-Git boundary. Required publication/harness checks remain separate.

Relay closed (Approved), no further turn needed.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
