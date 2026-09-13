# RELAY · GH605 Sol High implementation
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-09-13.
-->

NEXT: Producer
STATUS: Open
ROUND: 1 / 2

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
   - **Producer:** log a disposition for every open finding (Implemented / Modified / Declined + why),
     make the change, then add new work.
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(gh605-sol-high-implementation): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: PROJECT/2-WORKING/GH-605-WORK-STATE-PROJECTION.md — controlling expanded specification
- Reviewer: codex-author   ·   Producer: sol-builder
- Started: 2026-09-13
- Definition of Done: implement ordered steps1–6 and tests/docs from7, then hand back for main-agent execution of tests, independent QA and live apply.

## Producer implementation instructions (override generic review-only scaffold)

You are Sol High, the implementation builder, not the reviewer. The operator explicitly
requested Sol High for implementation. Plan QA was Approved with driver exit0 and attestation
for8cfad6bb; relay-system/2026-09-13/gh605-expanded-plan.md contains findings and dispositions.
Parent merged currentdevelopment561123d0, preserved bothledgerhistories via canonical resolver;
planned production seams did not change in that merge. Do not touch unrelated GH608 harness fix.

You own edits to utils/py/releases_app.py, utils/py/board_sync.py,
utils/py/work_connectors/github_board.py, utils/py/work_connectors/__init__.py if necessary,
test/test_gh605_work_state.py, test/test_gh605_board_policy.py, existing relevant test fixtures,
validate.sh registration, RELEASES-DB-FAQS.md, CHANGELOG.md and this relay thread.
You are not alone in the codebase; preserve all others' changes, no resets/stash/cleanup.
Use apply_patch for edits. Read plan controlling revision carefully, source before editing.
Don't create a second module/writer; reuse named seams. No schema change/newdependency.

Implement both ledger event/diagnostic fixes AND board policy/safe apply/restore, with tests.
Useful concrete details: current savedpolicy uses singular `repo`, not `repos`; accept that
existing field as a validated single-repo alias, plus explicit repos list for portability.
Saved policy has implementation_status pending: explicit policy commands must consume it
without requiring a config edit, and raw replay must refuse when it matches that board.
No personal defaults. Status columnconfig can use explicit defaults names but targetneverdefaults.
No autoscheduler/connectorenable. Currentrepos.slug may be basename XYZ-forge, not owner/name;
identity must be demonstrated by exact roadmap issue_url and matching repo row/root origin,
not assumed by number or arbitrary first connector. Payload source+transition tags distinguish
newstart events from legacymetadata noise. Count latest superseding lifecycle, not any start.

Board remote reads use existing _gql or gh seam, complete bounded pagination. Prefer GraphQL
closingIssuesReferences for explicit PR links and current GH stateReason. Keep public board
snapshot interfaces compatible. Duplicate/opaque/foreign cards preserve, report; no dedupe/delete.
Use existing _ConnectorLock for same-ledger coordination; document cross-device GH compare/read
cannot be atomic CAS. Policy guard prevents raw replay anyway. Keep as_of fixed for preflight
comparison; re-read GH before apply; compare full resulting decisions/changes and source hashes,
not merely trust serialized changes. Audit per individual remote request and stop indeterminate.
Restoration needs target/policy validation and conditional current-status checks too.

Runtime testing will be run by parent in a SEPARATE FULL CLONE. Do NOT run validate.sh or
test/*.sh, or mutation-heavy Python suites from this linked worktree. You may syntax-check
without bytecode writes (ast.parse) and inspect fixtures. Write robust nonempty isolated Python
unittest fixtures with no real network/device config. Register via validate.sh's existing pattern.
Do not call gh mutations, change localdeviceconfig, writeledgerdata, create clones, or deploy.
Do not gitadd/commit/push; driver owns file-scoped commit, notwithstanding generic scaffold.

On completion append concise producedfiles/remaininglimits/testing-not-run block, set NEXT
Reviewer, STATUS Open (never Approved), release runtime task to codex-author. Parent will run
tests and final QA. Prioritize full coherent implementation over commentary; cap your turn20min.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
