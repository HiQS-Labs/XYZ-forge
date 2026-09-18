# RELAY · GH-684/GH-686 final QA — implementation, tests and evidence (agy)
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-09-17.
-->

NEXT: Reviewer
STATUS: Open
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
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(gh684-final-qa-agy): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: the committed implementation on this branch — `git diff ba1f58e8..HEAD` (32 files; the ledger/receipt/relay files are paperwork; the code is `utils/py/wave_reconcile.py`, `utils/py/hosted_lane_report.py`, `.github/workflows/wave-reconcile.yml`, `test/gh421-auto-wave-reconcile.sh`, `test/gh684-hosted-lane-report.sh`, `test/gh53-releases-merge-resolve.sh`, `utils/releases-merge-resolve.sh`, `validate.sh`) — against the plan Codex approved in round 2 (Codex is out of budget for this final pass; agy reviews the implementation) of `relay-system/2026-09-18/gh684-plan-qa.md` (attested at `21de1d9d`): `PROJECT/2-WORKING/GH-684-HOSTED-RECONCILE-LANE.md` (S1–S4, Requirements → plan mapping, Acceptance checks now ticked with the evidence) and `PROJECT/2-WORKING/GH-686-GH53-FIXTURE-FLAKE.md`.
- Evidence: `TESTS-RESULTS/2026-09-18+GH-684/` — `README.md`, `provenance.jsonl` (15 rows with log sha256), positives, four single-site red controls, the base flake witness (`gh53-base-40x.log`, 33/7), and `validate-full.log` (389/394; the five reds are the environment's baseline set, identical on unmodified `development` per `TESTS-RESULTS/2026-09-17+GH-681/validate-full.log`).
- Reviewer: agy   ·   Producer: claude-a
- Started: 2026-09-18
- Definition of Done: each issue's requirements are satisfied by the code as written (not as described); the codepaths match the approved plan; no duplicate subsystem or second writer slipped in; the tests substantiate the claims and their red controls are causal; the persisted ratings (`rated 80/75/50/60` for #684, `70/70/50/85` for #686) still match the evidence. Approve when every question below is "yes" or the remaining findings are `[Nit]`.

### Operational envelope (grade against this)
Single-repo GitHub Actions job on `macos-latest` plus a local Python reconciler and a Bash fixture; one operator. Commensurate complexity: no notification service, no queue, no second ledger, no retry layer. The full-suite qualification (`--qualify --gate`) is deliberately untouched (#591). Behaviour-change requests carry `Observed input:` / `Affected scope:` / `Falsifier:`. You may run narrow read-only probes under `.relay-scratch/`; suites belong to the disposable-clone receipts you are reviewing.

### Questions (cite file:line)
1. **S2 as written.** `utils/py/wave_reconcile.py`: is the skip inside the merged/closing-doc branch, after the open-issue/umbrella preservation branch and before `ship_manifest_items`? Do explicit landings still reach `validate_and_update_doc`'s `die(code=5)` unchanged? Does `reconciled_issues.discard(issue_num)` plus `skipped_issues` give the ownership behaviour the plan specified? Is the `--dry-run` path unaffected? Does the end-of-run summary line avoid the `SKIP_MARKER` prefix (so the report tool cannot double-count it)?
2. **S1 as written.** `.github/workflows/wave-reconcile.yml` and `utils/py/hosted_lane_report.py`: `2>&1 | tee "$RUNNER_TEMP/reconcile.log"` under `set -euo pipefail` — does the reconciler's exit code still fail the step? Does the final step use `job.status`, `if: always()`, and `issues: write`? In the tool: is the create/comment/close matrix exactly the plan's (attention on `status != success` or any skip; close only on success with no skips and an open issue; no mutating call otherwise)? Is `gh issue list --label X` before the label exists safe (the Producer measured `[]`, rc 0 on the real repo)? Any way the tool's own failure could mask the job's status?
3. **S3 as written.** `test/gh53-releases-merge-resolve.sh` `gen_rows`/`union_dump` and the `mk_diverged` sleep: is the kept row the higher generation then the later `updated_at`, is the header made equal to it, is the distinct-timestamp assertion before the union, and is the B2 two-header negative control still exercising what it did? `utils/releases-merge-resolve.sh:75–77`: comment only?
4. **Tests substantiate the claims.** `test/gh421-auto-wave-reconcile.sh`: do the four new cases and the bounded extraction test what the plan says (mixed batch, repeat-then-repair with the receipt present, explicit fail-closed, planner ownership + its fatal red control, workflow pins)? Is the planner stub's injected finding real-shaped and does it reach the ownership classifier? `test/gh684-hosted-lane-report.sh`: does the recording stub actually enforce the run-URL invariant on every mutating call, and is the skip line built from `wave_reconcile.SKIP_MARKER`? Is anything asserted that would stay green on the unfixed code?
5. **Red controls are causal.** Read `TESTS-RESULTS/2026-09-18+GH-684/summary.txt` and the four `red*.log`s: does each mutation explain exactly the red it produced (and the greens that stayed green)? Is the 33/7 base witness credible as the pre-fix flake?
6. **No duplicate subsystem.** Does `hosted_lane_report.py` duplicate an existing issue-writing helper in `utils/py/` or `skills/`? Is `SKIP_MARKER` the only coupling between the reconciler and the tool?
7. **Scope and ratings.** Anything in the diff outside S1–S4 (scope creep), or anything from #684/#686 missing? Do `80/75/50/60` and `70/70/50/85` still match the evidence (the flake measured at 17.5 %, not "one in two")?
8. **Paperwork.** Do the capture docs, CHANGELOG entry, and receipts README describe what the code does, not what was planned? Anything false or overclaimed?

Output: graded bullets `[Blocker]` / `[Should]` / `[Nit]` / `[Pass]` per question with `file:line`, then a verdict. Set `STATUS: Approved` only if no `[Blocker]` or `[Should]` remains.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
