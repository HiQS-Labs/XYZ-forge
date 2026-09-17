# RELAY · GH-646 writer focused replacement QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-09-17.
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
   - **Producer:** log a disposition for every open finding (Implemented / Modified / Declined + why),
     make the change, then add new work.
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(gh646-writer-focused-replacement-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: `utils/py/releases_app.py`, `utils/py/express.py`, `utils/py/wave_reconcile.py`, `utils/py/work_connectors/__init__.py`, `utils/py/work_connectors/github_labels.py`, `utils/ci-route.sh`, `validate.sh`, `releases.sql`, `RELEASES-DB-FAQS.md`, `PROJECT/2-WORKING/GH-646-STATUS-LABEL.md`, and their changed focused tests/receipts in this branch.
- Reviewer: codex-gh646-review2   ·   Producer: terra-gh646-writer
- Started: 2026-09-17
- Definition of Done: The operator authorized a focused changed-function-and-callers review of the 23-file GH-646 candidate rather than an unrelated whole-repository sweep. Review every changed runtime function and its direct callers relevant to: schema/dump compatibility; qualified accepted start; only-literal-label local/opt-in remote projection; exact repository/native issue-versus-PR identity; direct confirmed closure; Express and wave exact-row routing; connector failure/replay; and CI routing. Treat a concrete reachable in-scope defect as a finding. Do not require reader/Flight Deck/Daily changes, a generic label system, service, scheduler, new database, live migration, connector enablement, live GitHub label write, or deployment. The prior capped relay is historical evidence only; this is its replacement. Approval is valid only when this exact reviewer turn is attested by the Python driver; final qualification remains a separate gate.  [Unverified — no citation]

### Focused-review waiver and evidence boundary

The operator explicitly authorized this focused review on 2026-09-17 after the prior automated reviewer failed before producing a Round 3 verdict. This limits the review to the candidate's changed runtime seams, relevant direct callers, schema/dump and test/receipt boundaries. It does **not** waive source review, approval attestation, the final disposable-clone qualification gate, or normal PR review. A reviewer must state `swept file: yes` only for the listed scope files it actually reads; it must list any unreviewed changed file as an unknown.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer · codex-gh646-review2 · Round 1 · 2026-09-17

VERDICT: FAIL
Basis: The focused writer review found a reachable terminal-authority defect in the changed wave closeout function's direct caller. Exact-row selection does not establish that its issue ended.
swept file: no

- [Blocker] **Wave closeout can clear an open issue's accepted label based on a declined PR, or clear an issue with unknown state.** `utils/py/wave_reconcile.py:2028` reads issue state, but the OPEN guard at `:2040` requires `is_merged`. For an unmerged/declined landing with a linked issue and active doc, `issue_state == "OPEN"` still falls into `elif doc_path` at `:2046`, calls `update_roadmap_entry` at `:2052`, and its exact owned-row update at `:1279` sets Deferred/⛔. `_sync_status_labels` (`utils/py/releases_app.py:1634`) then clears the accepted label; the emitted deferred event authorizes remote removal even while the native issue remains open (`utils/py/work_connectors/github_labels.py:54–58`). Separately, `fetch_issue_state` (`utils/py/wave_reconcile.py:270`) returns None for an offline manifest without issue evidence and accepts arbitrary live state strings; ordinary non-umbrella callers at `:2036` treat these as not open and allow terminal mutation. These are pre-existing caller defects made consequential for this new label, within the authorized changed-function/callers scope. **Fix:** without explicit operator force, require positively confirmed CLOSED issue evidence before terminalizing an owned row for either merged or declined landings; preserve OPEN and missing/invalid state. Keep any legacy doc policy separate if necessary. Add focused caller-level regressions for declined PR + OPEN active issue, offline missing state, and invalid live state, asserting row/label/event preservation and no remote removal; include a red control restoring the permissive caller.
- [Pass] Accepted admission is separately qualified, native-open checked, and rechecked under the writer transaction; ordinary active appearance does not establish the label (`utils/py/releases_app.py:3928–3940`, `:3981–3993`, `:1634–1647`). The native guard rejects PRs and mismatched URL/number (`:5410–5423`); direct reconcile-state now invokes it before accepting the closure reason (`:4072–4116`). No additional defect found in those inspected seams. No change requested there.
- [Pass] Schema009 adds only the constrained nullable literal, new dump emission includes it, and restoration defaults absent old-dump fields to NULL (`utils/py/releases_app.py:1016–1020`, `:1260–1262`, `:6183–6201`; focused roundtrip assertions at `test/gh646_status_label.py:392–423`). The checked-in dump still records schema008 (`releases.sql:12`), consistent with deliberate migration rather than a live migration claim. No change requested there.
- [Pass] The complete labels adapter checks qualified current identity and opt-in repository membership, mutates only the literal label, and verifies unrelated-label preservation (`utils/py/work_connectors/github_labels.py:98–118`, `:62–90`). Parent failure persistence retains the cursor (`utils/py/work_connectors/__init__.py:304–338`); raw board events remain separate and label-repair events are filtered (`:132–141`, `:460–476`). Exact Express and wave row selectors use owned identity/global ID (`utils/py/express.py:635–661`, `:730`; `utils/py/wave_reconcile.py:1250–1282`). No change requested to those selection/projection seams.
- [Pass] The focused wrapper is registered in the main inventory and releases subsystem (`validate.sh:249`, `utils/ci-route.sh:26`), and both Python test and wrapper paths are assigned to releases (`utils/ci-route.sh:38`). The suite declares targeted appearance and closure-identity negative controls (`test/gh646_status_label.py:1015–1060`). These are source observations, not claims that I executed or independently attested their results.
- [Should] **Review/evidence limits:** fully read the relay, task doc, focused wrapper, and labels adapter; inspected the relevant shared-writer, migration/dump/restore, admission, direct cleanup, lifecycle/identity, connector batching/dispatch, Express admission/resume/manifest, wave closeout/caller, and routing sections. This is the authorized focused sweep, not an entire-file sweep of the large runtime files; hence `swept file: no`. Some large combined reads were output-truncated. No complete 23-file changed-path inventory or GH-646 receipt set was available from the relay's Setup, and I did not invoke git to obtain one; unlisted changed tests/receipts and uninspected portions remain unknown. Producer should list the exact candidate paths and receipt paths in its disposition so the final review can close those boundaries. No artifact/source execution, test execution, gate execution, git command, or edit outside this relay file occurred. Driver attestation and final disposable-clone qualification remain outstanding.

Handing off to terra-gh646-writer — disposition the blocker, repair the focused wave terminal-authority seam and add caller regressions, provide the candidate/evidence path inventory, then reopen Reviewer Round 2. Go to the Producer window and say 'take your turn'.

### Producer · terra-gh646-writer · Round 1 disposition · 2026-09-17

VERDICT: PASS
Basis: The Round 1 fail path reproduced in a new caller-level focused test before repair. The minimal repair preserves the existing explicit `--force-promote` override but otherwise requires a positively confirmed CLOSED issue state before wave closeout can invoke the terminal document/roadmap writer.

- [Blocker] Implemented in `utils/py/wave_reconcile.py`. `_may_terminalize_issue(issue_state, force_promote)` is the one shared terminal-authority predicate. The active-doc and no-doc closeout branches now preserve an OPEN, absent, or invalid issue state rather than calling `validate_and_update_doc`/`update_roadmap_entry`; the pre-existing merged-open merge-evidence path remains unchanged. Explicit `--force-promote` remains the documented override.
- Added `test_wave_requires_confirmed_closed_issue_before_terminalizing_label` in `test/gh646_status_label.py`. A declined PR with its owned issue `OPEN`, absent from the offline evidence, or `UNKNOWN` leaves the accepted row, event count, and label unchanged and never calls either terminal writer. Before the repair, all three cases entered `validate_and_update_doc`, reproducing the reviewer’s fail path. Red control witnessed: `python3 test/gh646_status_label.py --mutant wave_terminal` restores permissive terminal admission and fails all three `assert_not_called` protections. Corrected suite: 41 tests pass.
- Candidate path inventory: runtime `utils/py/releases_app.py`, `utils/py/express.py`, `utils/py/wave_reconcile.py`, `utils/py/work_connectors/__init__.py`, `utils/py/work_connectors/github_labels.py`, `utils/ci-route.sh`, `validate.sh`; schema/ledger `releases.sql`, `releases.db`; focused tests `test/gh646_status_label.py`, `test/gh646-status-label.sh`, `test/gh267-express-skill.sh`, `test/gh32-releases-app.sh`, `test/gh424-roadmap-status-marker.sh`, `test/gh492-roadmap-state-sweep.sh`, `test/gh527-issue-url-repair.sh`, `test/gh69-roadmap-shadow.sh`; scope/receipts `PROJECT/2-WORKING/GH-646-STATUS-LABEL.md`, `RELEASES-DB-FAQS.md`, three skill docs, this relay, and the preserved capped relay. Historical full-gate receipt 393 is provenance only; it is not qualification for this candidate.
- Focused evidence this round: corrected 41-case Python suite passes; `wave_terminal` red control fails as expected. The appearance and direct-closure mutants remain retained prior evidence and will be re-run with the focused wrapper before any qualification. No final gate, live migration, connector enablement, label write, deployment, push, or PR occurred.

Handing off to codex-gh646-review2 — review the wave terminal-authority repair and the now-complete focused scope inventory; if no concrete in-scope defect remains, issue an attested approval or explicitly escalate at this two-round cap. Go to the Reviewer window and say 'take your turn'.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
