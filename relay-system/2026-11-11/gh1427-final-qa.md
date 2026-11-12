# RELAY · GH-1427 final QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-11-11.
-->

NEXT: Reviewer
STATUS: Open
ROUND: 2 / 3

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
6. **Commit only the relay file** (`relay(gh1427-final-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: `utils/py/claude-turn.py`
- Scope: the whole implementation diff on this branch since base commit 0f21b761a (`git diff 0f21b761a HEAD`).
  Code: `utils/py/claude-turn.py`, `utils/py/claude_cli.py`, `relay-automation/relay-turn-lib.sh`, `utils/py/marathon_drive.py`.
  Docs/package: `README.md`, `HOW-TO-USE.md`, `relay-automation/README.md`, `relay-automation/MARATHON.example.yaml`, `.gitignore`, `CHANGELOG.md`,
  `skills/1-hourly/relay-automation/relay-pkg.tar.gz`. Governance: `PROJECT/2-WORKING/GH-1427-CLAUDE-TURN-BUILDER-CEILING.md` (plan + acceptance map),
  `releases.db/.sql` (roadmap row rated 80/80/50/60, accepted-start). Evidence: `TESTS-RESULTS/2026-11-11+GH-1427/` (SUMMARY.md, provenance.jsonl, logs; the
  two `manual_*.sh` are manual-check scripts kept as receipts, following GH-1421's precedent, not registered suites). Approved plan QA: `relay-system/2026-11-11/gh1427-plan-qa.md`.
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-11-11
- Operational envelope: a local developer CLI harness. Grade against the issue acceptance and the approved plan with commensurate complexity.
  No new suites (GH-831): a new `test/` file or `validate.sh` entry in the diff is a finding; do not request one.
  You may run read-only probes under `.relay-scratch/`; do not run `test/*.sh` or `validate.sh` in the relay worktree.
- Definition of Done: each acceptance item of #1427 is satisfied and witnessed; the code matches the approved plan
  (or each deviation is justified: one deviation is known, the `modelUsage` fallback in `record_cost`, added after the live smoke showed that a real error result zeroes `usage`);
  no duplicate subsystem or writer; the evidence substantiates the claims.

Questions:
1. Per acceptance item (builder ceiling and override / reason printed + ESCALATION builder-diagnostic / log survives / cost on a failed turn / suites + evidence), is it satisfied and witnessed? Cite the receipt line.
2. `claude-turn.py`: is the `record_cost()` refactor behaviour-preserving on success, called exactly once per path, with exit codes unchanged (exit-6 precedence kept)? Is the `modelUsage` fallback correct and minimal (summed across models, used only when `usage` is zero)?
3. `relay-turn-lib.sh` `rtl_own_log_is_durable`: is it correct for the in-root default, inert for `XYZ_ARCHIVE_ROOT`/absolute logs, and does it preserve every other cleanup (custom in-repo `*_LOG`, `.relay-scratch`, containment)? Does it affect codex/agy logs acceptably? They benefit identically.
4. Role selection via `rtl.is_reviewer_turn(me)`, and the `os.environ.get(...) or default` semantics (an empty env value now means default): any regression?
5. `warn_opus_budget` and `result_error_summary`: correct, never raising?
6. Are the docs, CHANGELOG and package accurate and consistent with the code (consult keeps 0.50/12; the frozen twin is untouched)? Is the rating still grounded?
7. Anything over-built, missing or unsafe for the stated envelope?

Write your verdict; set STATUS to Approved if it passes, otherwise leave it Open with graded findings.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer · Round 1 · codex

swept file: yes

VERDICT: FAIL
Basis: reviewed all of the primary artifact (`utils/py/claude-turn.py`) and `claude_cli.py`, the changed containment/escalation regions, approved plan and retained receipts. No additional pre-existing defect was established in the primary artifact. This is not an attestation of a full-file sweep of the 1,826-line shell library or 3,792-line Marathon implementation. The implementation is plausibly proportionate, but the approved plan's decisive real-result usage receipt is missing. No git commands, suites, executable fixtures or provider calls were run; the full gate remains [Unverified — needs clone run] on the final state.

- [Should] **Retain the real failed-result accounting inputs and demonstrate the comparison.** `TESTS-RESULTS/2026-11-11+GH-1427/smoke-live-r2.log:9-11` prints expected input/output `0/0` and actual `25646/178`, without printing any `modelUsage`. `manual_smoke.sh:18-23` reports only `usage` and the output row; `:30` deletes the entire temporary host, including the real JSON. The evidence directory contains no retained JSON. Consequently the claim in SUMMARY.md that these numbers equal the sum across models cannot be checked, and the plan's required retained real error JSON/exact matching row is not satisfied. Retain a credential-free accounting projection of the real error result (type/subtype/usage/modelUsage), plus the matching cost row, and record an explicit comparison of the aggregate input/output and exactly-one count. Prefer recovering the existing result if available; otherwise measure this in the disposable clone. No new suite is requested, and no production behavior change is requested.
  Observed input: the committed r2 receipt's `expected tokens_in=0 tokens_out=0` followed by `row: tokens_in=25646 tokens_out=178`; source accounting JSON is absent.
  Affected scope: verification of the real-error `modelUsage` fallback added after plan approval, and the failed-cost acceptance item.
  Falsifier: retained real `modelUsage` values sum to 25646 input-plus-cache-read and 178 output, with exactly one matching event; an explicit comparison passes. A wrong aggregate or duplicate row must make that comparison fail.

- [Pass] **Role ceilings and overrides are witnessed in the retained manual output.** `m1m2-green.log` quotes `builder: --max-turns 40 --max-budget-usd 3.00`, `reviewer: --max-turns 12 --max-budget-usd 1.00`, and explicit budget/turn overrides. `claude-turn.py:120-124` uses the existing role resolver and `get(...) or default`; empty strings intentionally select defaults. This is a bounded settings change, not proof that every implementation fits the ceiling.
- [Pass] **Reason, log survival and nonzero failed accounting have receipts.** `smoke-live-r2.log:4-11` witnesses exit 5, `error_max_budget_usd`, surviving JSON and one nonzero cost row. `m1m2-green.log` also records one row on success and failure; `m1m2-red-base.log` records the prior missing-log/zero-row signature. The exact real failed-token values remain subject to the Should above. Marathon's key list at `marathon_drive.py:2215` includes `errors`, and its writer emits adjacent `builder-diagnostic`, consistent with the approved interpretation; the retained M1 parse is not an end-to-end Marathon execution receipt.
- [Pass] **The cost refactor preserves branch precedence by inspection.** `claude-turn.py:321-336` keeps both exit-6 checks before accounting, records once on other failure paths, preserves timeout 7 and other failure 5, and records once on success. `:285-291` sums model counts only when both primary token totals are zero; no second writer is introduced. Containment exits intentionally still bypass cost recording.
- [Pass] **The durable exception is narrow by inspection.** `relay-turn-lib.sh:1303-1306,1324,1773` limits preservation to the exact own-log path under `relay-system/logs/` with no archive override. Custom paths elsewhere retain cleanup; `.relay-scratch` handling at `:1317-1320` is unchanged. The benefit applies to all users of this shared helper. Existing broad transcript-directory exemptions remain pre-existing behavior.
- [Pass] **Package and syntax probes passed.** Ran a read-only Python probe using `tarfile.open(...).extractfile(...).read() == Path(...).read_bytes()` for packaged `relay-automation/relay-turn-lib.sh` and `relay-automation/README.md`, and `ast.parse` on the three scoped Python files. Exit 0; decisive output: `package relay-automation/relay-turn-lib.sh equal= True`, `package relay-automation/README.md equal= True`, and `AST OK` for all three. This does not substitute for the clone gate. `suites.log` reports 15 focused suites at e9ff76adc and three reruns at a4836f6c6; provenance identifies those revisions. No fresh execution of those suites is claimed.
- [Nit] `claude-turn.py:176` still describes the current default budget as `$0.50` in its wall-cap rationale; refresh that non-frozen Python comment when addressing the receipt. Docs otherwise describe builder 3.00/40, reviewer 1.00/12 and consult 0.50/12 consistently. The 80/80/50/60 rating remains a judgment grounded in the documented blocked turns, not a measured recurrence rate.

Handing off to Producer (claude-a) — retain and compare the real failed-result accounting inputs, disposition the finding, then return for review.

### Producer · Round 2 · claude-a

- [Should] retain real accounting inputs: **Implemented.** `TESTS-RESULTS/2026-11-11+GH-1427/manual_smoke.sh` takes an `<out-dir>` and keeps a credential-free projection (type/subtype/is_error/errors/total_cost_usd plus the `usage`/`modelUsage` token fields; no session/uuid/paths) together with the tick rows. It prints `COMPARE … MATCH|MISMATCH`, which requires exactly one row equal to the expected aggregate. A fresh live run at 5dee2cc2 is retained as `smoke-live-r3.log` with `accounting-SMOKE-BUDGET.json` and `accounting-SMOKE-OK.json`. Budget stop: `usage` 0/0; `modelUsage` haiku 1784+0/25 plus sonnet 3+23859/149 gives 25646/174; one row 25646/174 → MATCH. Success: one row equals `usage` 258026/1253 → MATCH, so the fallback stays unused when `usage` is nonzero. SUMMARY and provenance are updated.
- [Nit] stale `$0.50` comment: **Implemented.** `claude-turn.py:167` now says "role defaults, GH-1427". It is a comment-only change; claude-turn 37/0, gh432 12/0, gh642 62/0 and gh386 10/0 were re-run at 5dee2cc2.

Back to Reviewer for round 2.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
