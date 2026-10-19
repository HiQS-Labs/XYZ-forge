# RELAY · GH-1108 plan QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-17.
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
6. **Commit only the relay file** (`relay(gh1108-plan): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: `PROJECT/1-INBOX/GH-1108-JOG-LAND-RECEIPTS.md`; read current cited code and issue #1108 requirements.
- Reviewer: codex   ·   Producer: codex-producer
- Started: 2026-10-17
- Definition of Done: Review bounded plan before production edits. Verify ground truth, six-path exception, source/destination root identity, replay and failure boundaries, PRS ratings and test scope. Grade commensurate complexity in this local operator tool; no unrequested enterprise threat models. The historic PR1102 includes paths beyond the explicit allowlist and deliberately requires reapproval. Reviewer may write only this relay; do not execute mutation-heavy suites in reviewer worktree.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer · Round 1

Ship the bounded plan.

swept file: yes
VERDICT: PASS
Basis: Read the complete 63-line artifact and traced the current landing, receipt lookup, CLI aliases, canonical queue writer and reconciliation entry. No blocking or mandatory-change defect found in the plan, including its pre-existing sections. Approval is for implementation of this plan, not live landing or merge readiness.

- [Pass] Ground truth matches the issue and current seam: exact head equality and root identity at `utils/py/jog_run.py:961–969`, local-base reachability at `:988–994`, landing-marker-before-queue ordering at `:1014–1017`, and replay's reconciled shortcut at `:1024–1026`. `gh issue view 1108 --repo HiQS-Labs/XYZ-forge --json title,body,comments` exited 0; decisive issue input: “The receipt's approved head is 6f521bc5” and the comment requires landing writes in the primary. The plan addresses both requirements (artifact lines 36–40).
- [Pass] The six-path exception is bounded and intentionally does not promise to land historic #1102 (artifact lines 28, 36, 42). Read-only probe `gh api repos/HiQS-Labs/XYZ-forge/compare/6f521bc5...974d98db --jq '{status,ahead_by,total_commits,paths:[.files[].filename]}'` exited 0: `status="ahead", ahead_by=12`; paths included `PROJECT/2-WORKING/GH-1087-GH1051-RECORD-SPACING.md`, `TESTS-RESULTS/2026-10-17+GH-591/wave-746b114843afe67ea0d3b8143e06550e0924e530/provenance.jsonl`, and `marathon-system/gh-1087-gh1051-record-spacing/RELAY.md`. Thus the historical example exceeds the explicit allowlist; renewed approval is an honest limitation.
- [Pass] Root ownership and replay requirements are sufficient at plan granularity: source evidence/state, destination GitHub/Git/PRS/lifecycle, origin and source-path validation, unique destination queue identity, destination-qualified key, reconciliation reset and queue completion before the shortcut (artifact lines 38–40, 55–58). Existing `jog_set_status` always calls `perform_write` (`utils/py/releases_app.py:4853–4890`), so checking completion before calling it is necessary to meet the stated no-duplicate-receipt criterion. Preserve that requirement during implementation.
- [Nit] Clarify “Relative evidence resolves against the source execution directory” (artifact line 38) to distinguish gate evidence from state-record paths. `_ledger_abs_path` explicitly resolves relative `result_path`/`packet_dir` from `<source>/.tick/jog/<source-gid>/` (`utils/py/jog_run.py:217–229`); `_jog_latest_receipt` and `_jog_exec_dir` depend on that convention (`:647–676`). Preserve this existing convention while resolving gate evidence at its specified source location. This is wording clarification, not a request to broaden the feature.
- [Pass] Ratings are recorded without an unsupported recurrence boost (artifact line 63). Read-only SQLite probe `sqlite3.connect('file:releases.db?mode=ro', uri=True)` with `SELECT * FROM roadmap_items WHERE gh_number=1108` exited 0 and returned one row, `rmi-01M54B6DYYH7J2VXKTVPF01BZA`, ratings `85/80/50/60`, `rating_ovr=None`, and the artifact's doc path. The stated Costly boundary and rollback are proportionate (artifact line 44).
- [Unverified — no citation] Verification scope uses existing coverage and manual red controls in a disposable full clone, retains provenance, checks nonempty extraction and Git identity, and requires final independent QA (artifact lines 49–51, 59). No new suite/gate is proposed.
- [Unverified — needs clone run] Candidate behavior, red controls, duplicate-receipt counts and interrupted recovery are future implementation evidence. No suite, executable fixture, gate, or live landing was run here. Graph tools were unavailable in this reviewer tool inventory; source fallback was used, and the artifact's old graph generation was not treated as current proof.

Done. Relay closed (Approved), no further review turn needed. Producer acts next to implement the approved plan and carry the path-convention clarification into the work.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
