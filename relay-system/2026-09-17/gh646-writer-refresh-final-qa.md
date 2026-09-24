# RELAY · GH-646 refreshed writer final QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-09-17.
-->

NEXT: Human
STATUS: Escalated
ROUND: 3 / 3

## ▶ TAKE YOUR TURN — read this first (works for ANY agent: Claude, Codex, agy)
1. **Read this whole file** (header, Setup, Ground rules, every block in the Log).
2. **Check it's your turn:** `NEXT` (top) names the role to act. Confirm you are bound to it and the
   last Log block isn't already yours. If not → STOP and reply "wrong window — nudge the <other> window."
3. **Do your role's work** on the artifact named in Setup:
   - **Reviewer:** review vs the Definition of Done → graded findings
     (`[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`), each with a concrete fix → set a **Verdict**
     (Approved | Changes requested | Blocked). **Review the whole file, not just the diff** (GH-268):
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
6. **Commit only the relay file** (`relay(gh-646-refreshed-writer-final-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: `PROJECT/2-WORKING/GH-646-STATUS-LABEL.md`, `utils/py/releases_app.py`, `utils/py/express.py`, `utils/py/wave_reconcile.py`, `utils/py/work_connectors/__init__.py`, `utils/py/work_connectors/github_labels.py`, and the GH-646-focused tests.
- Reviewer: codex-gh646-review   ·   Producer: terra-gh646-writer
- Started: 2026-09-17
- Definition of Done: Review only the refreshed GH-646 producer. Confirm that explicit accepted starts set one exact owned `in-progress` value through the existing writer; remote projection is opt-in and exact-identity-bound; confirmed closure clears only that label; old schema/dump paths remain compatible; Express and reconciliation cannot borrow a same-number foreign issue. The review must reject an added writer, service, scheduler, generic label layer, inferred start, Flight Deck/Daily change, live migration, connector enablement, or deployment. Focused evidence is 38 `test/gh646_status_label.py` cases plus existing related suites; final qualification is still pending and cannot be called green by this review.

## Questions for this bounded final review

1. Does every status mutation reuse the existing locked roadmap writer and durable receipt boundary, including accepted starts and terminal cleanup?
2. Can a same-number foreign repository, malformed URL, or pull request ever supply identity or closure authority to an owned issue? Cite the relevant guard and test.
3. Does the GitHub connector preserve local durability across remote failures, write only the literal label, and avoid treating metadata, stale activity, merged PRs, or reopen as authority?
4. Are schema migration, old/new dump, existing marker/event compatibility, and reader behavior correctly bounded? Reader SQLite sidecar policy is already approved separately and is not a request to change reader code here.
5. Is the diff surgical relative to the plan, with no unrelated dashboard, Daily, generated-view, or harness changes? Flag a real omission or safety issue with file:line evidence; do not demand speculative infrastructure.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer · codex-gh646-review · Round 1 · 2026-09-17

swept file: no

Verdict: Changes requested

- [Blocker] Ordinary roadmap updates bypass accepted-start admission. `utils/py/releases_app.py:1642–1645` sets `status_label = "in-progress"` when a target transitions into `in_flight`, even with `accepted_start=False`. The ownership/native-issue/open-state checks at `utils/py/releases_app.py:3929–3941` run only under `if accepted:`. Consequently a queued row with a foreign/malformed URL, a native PR, or a closed issue can receive the authoritative local label through `roadmap update --gid <gid> --section "In progress"` (or a 🚧 marker) without admission. This is a static fail-path finding, not an executed reproduction. Fix: restrict establishment of this new label to the qualified accepted-start path; retain legacy marker/section and event compatibility without letting those alone establish the label. If legacy explicit transitions must establish it, route them through the same qualification and stale-row checks instead. Add focused negative cases for each identity/native-state defect through ordinary update and move, with a valid accepted-start positive control and a mutant that restores the bypass.
- [Pass] The dedicated accepted-start path checks owned identity, native issue state, and stale row identity inside its mutation (`utils/py/releases_app.py:3932–3941`, `utils/py/releases_app.py:3982–4000`); the shared writer places label maintenance inside its transaction before the receipt and commit (`utils/py/releases_app.py:1688–1699`, quoted seam: `_sync_status_labels(conn, before_rows, op, target_gid, accepted_start)`). These protections do not cover the ordinary-update bypass above.
- [Pass] Remote writes name only the literal owned label: `utils/py/work_connectors/github_labels.py`, quoted calls `"--add-label", LABEL` and `"--remove-label", LABEL`, with `LABEL = "in-progress"`; readback checks unrelated labels via `after - {LABEL} != before - {LABEL}`. Native REST identity rejects `"pull_request" in issue` and mismatching `html_url`/number (`utils/py/releases_app.py:5399–5414`). Focused test coverage is present in `test/gh646_status_label.py:test_owned_identity_and_pr_refusal` and `test_failed_removal_reopen_replay_and_cursor_retention`; these were read, not run this turn.
- [Should] Final QA remains open. This turn inspected the complete plan and label connector plus relevant writer, connector-parent, Express, reconciliation, and focused-test paths; it did not complete the mandated whole-file sweep of the large artifacts. Remaining schema/dump compatibility, unrelated/pre-existing defects, and surgical diff scope receive no approval from this turn. Finish that sweep after the blocker is resolved. No tests, gates, git commands, source edits, live migration, enablement, or deployment were performed; the producer's reported 38-case run is not independently re-attested here, and final qualification remains pending.

Handing off to terra-gh646-writer — address the admission bypass, record the disposition, and reopen Reviewer QA; go to the Producer window and say 'take your turn'.

### Producer · terra-gh646-writer · Round 1 disposition · 2026-09-17

- [Blocker] Implemented. `_sync_status_labels` now establishes `in-progress` only when the existing `roadmap-update` call carries `accepted_start=True`. Existing active rows retain a previously established label; inactive/terminal rows still clear it. Legacy appearance transitions retain their existing lifecycle event compatibility but cannot create this new authority.
- Added `test_ordinary_active_appearance_never_establishes_label`: foreign repository identity, native closed state, and native pull-request state each make ordinary `In progress` / `🚧` appearance without a label; a valid explicit accepted start remains the positive control.
- Red control witnessed: `python3 test/gh646_status_label.py --mutant appearance` fails the new assertion after deliberately restoring the old appearance-based label mutation. The corrected suite passes 39 tests; the wrapper also passes. This is focused evidence only, not final qualification.

Handing off to codex-gh646-review — review the narrow repair and decide whether the remaining bounded sweep can approve; go to the Reviewer window and say 'take your turn'.

### Reviewer · codex-gh646-review · Round 2 · 2026-09-17

swept file: no

Verdict: Changes requested

- [Pass] The Round 1 establishment bypass is repaired: `utils/py/releases_app.py:1634–1647` retains an existing label while active, clears it while inactive, and establishes it only for the targeted `roadmap-update` with `accepted_start`. Admission still checks owned identity and open native issue state (`utils/py/releases_app.py:3928–3941`) and rechecks the row under the writer transaction (`utils/py/releases_app.py:3981–4000`). The new negative/positive control is `test/gh646_status_label.py:185–211`; its deliberately restored bypass is at `test/gh646_status_label.py:985–1003`. These are source-inspection findings; neither the 39-case run nor its red control was executed this turn.
- [Should] Terminal cleanup lacks the native identity proof required elsewhere by this implementation. `cmd_roadmap_reconcile_state` qualifies the local URL (`utils/py/releases_app.py:4058–4066`) but requests only `state,stateReason` and validates only those fields before queuing terminal mutation (`utils/py/releases_app.py:4068–4091`). `wave_reconcile.fetch_issue_state` likewise requests only `state` (`utils/py/wave_reconcile.py:270–301`), then its callers can update the qualified local row (`utils/py/wave_reconcile.py:2028–2086`). Neither path checks the returned repository URL/number or rejects a native `pull_request` object, unlike `read_native_issue` (`utils/py/releases_app.py:5398–5412`). Thus the requested native issue-versus-PR/exact-identity guarantee is not established for closure. This is a static qualification gap, not a claim that the real CLI was observed returning a PR. Fix: reuse the existing native issue guard for live closure reads and validate the closure reason alongside it; preserve documented offline behavior. Add closure-path refusal fixtures for native PR and mismatched returned identity, plus genuine closed-issue positives and a red control removing the guard. Existing direct-close fixtures return only state/reason (`test/gh646_status_label.py:576–614`), so they cannot prove this property.
- [Pass] Exact-row routing is present in Express and wave ledger updates: `utils/py/express.py:635–657` selects a uniquely qualified repository match; `utils/py/express.py:724–733` admits by global ID; `utils/py/wave_reconcile.py:1252–1289` qualifies ownership and writes by global ID. Tests inspect both row orders and foreign-only behavior (`test/gh646_status_label.py:806–864`). Schema 009 leaves historical labels NULL and constrains the literal value (`utils/py/releases_app.py:1016–1020`); dump emission and restore handle absent/present fields (`utils/py/releases_app.py:1260–1262`, `utils/py/releases_app.py:6172–6189`; coverage at `test/gh646_status_label.py:392–423`). These passes concern the cited seams only.
- [Should] The earlier whole-file-sweep requirement remains open. This turn read the complete plan and complete label connector, then expanded inspection of shared writer, migration/dump/restore, admission, direct cleanup, Express, wave closure callers, connector payload/dispatch, and focused tests. It did not read every line of the large artifacts or establish the complete branch diff without git, which the operator forbids. No claim of no pre-existing defects or surgical branch scope is made. Complete the required sweep before approval. No source/artifact execution, tests, gates, git commands, live migration, connector enablement, or deployment occurred; final qualification remains pending.

Handing off to terra-gh646-writer — address the closure qualification gap, record its disposition and focused evidence, then reopen the final whole-file review; go to the Producer window and say 'take your turn'.

### Producer · terra-gh646-writer · Round 2 disposition · 2026-09-17

- [Should] Implemented narrowly in `cmd_roadmap_reconcile_state`. After the existing local roadmap identity check, direct terminal cleanup now calls the existing `read_native_issue(repo, number, url)` guard before it accepts the existing CLI closure state/reason. That guard rejects a returned pull request, mismatched number or HTML URL, malformed labels, and nonterminal native state. The closure state from `gh issue view` must also agree with native state before the writer queues the exact-row terminal mutation; closure reason validation remains unchanged.
- Added `test_direct_close_refuses_mismatched_native_identity` for native pull-request, wrong-number, and wrong-URL payloads. Each is refused without changing the admitted row's `In progress` section or `in-progress` label. The existing genuine closed/cancelled close fixture is the positive control. `test/gh492-roadmap-state-sweep.sh` now supplies a valid native REST fixture and still proves its terminal-event rollback and second-sweep behavior.
- Red control witnessed: `python3 test/gh646_status_label.py --mutant closure_identity` fails all three new refusal assertions after deliberately replacing the native guard with a valid closed identity. The corrected focused suite passes 40 tests; `test/gh492-roadmap-state-sweep.sh` and `test/gh646-status-label.sh` pass. The earlier appearance mutant still fails as intended. These are focused implementation checks only, not final qualification.
- [Should] Declined to broaden `wave_reconcile.fetch_issue_state` in this repair. It already accepts a locally exact qualified row and writes by its global ID; the separate label connector rechecks exact native identity before any remote label operation. Altering the generic wave state API would expand the evidence surface without changing this direct writer closure authority. Please reject this disposition if the complete sweep finds a path that lets wave reconciliation make a status-label mutation without the connector guard.

Handing off to codex-gh646-review — review the direct terminal repair and complete the required whole-file/surgical-scope sweep; go to the Reviewer window and say 'take your turn'.

### Relay driver · bounded review execution · Round 3 · 2026-09-17

The required actual reviewer invocation was attempted once with `relay-automation/relay-drive.sh`, `codex-gh646-review`, disposable worktree isolation, and `--review-once`. The harness reported `codex exec failed (exit 5)` after creating its throwaway worktree; it appended no reviewer block and the requested transcript log was empty. The driver handed the token back without a review verdict. No source, live system, migration, connector, deployment, or final qualification gate ran in that invocation.

This is a capped-review escalation, not an approval or a claim that the source is ready to publish. A human must authorize a new bounded independent review or resolve the review-runner failure before final qualification, push, or PR publication.

Handing off to a human — choose whether to repair/retry the review runner in a new bounded review or use an independent reviewer; no further turn runs under this capped thread.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
