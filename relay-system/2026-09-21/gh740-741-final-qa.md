# RELAY · GH-740/741 final QA — hosted lane publish + report attribution (diff at 071f6c42)
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-09-21.
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
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(gh740-741-final-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: utils/py/hosted_lane_publish.py, utils/py/hosted_lane_report.py, utils/py/wave_reconcile.py (the `--only-receipted` flag: argparse block + the partition replacing `qualify_landings` in `main`), .github/workflows/wave-reconcile.yml, test/gh740-hosted-lane-publish.sh, test/gh684-hosted-lane-report.sh, test/gh421-auto-wave-reconcile.sh (WorkflowTests + the `only_receipted` cases), validate.sh (one TESTS row), CHANGELOG.md (top entry), PROJECT/2-WORKING/GH-740-HOSTED-LANE-PUSH-RACE.md (the approved plan). Diff: `git diff b6bb8aab..071f6c42 -- <those paths>`.
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-09-21
- Definition of Done: the implementation satisfies the **approved plan** (relay `gh740-741-plan-qa-delta2`, Approved) and each issue's acceptance, at commensurate complexity — no second subsystem, no merge queue, no widening of the bot's commit surface. Grade against the plan's Requirements table, not against speculative failure modes. Questions, each graded: (1) #740 — does `hosted_lane_publish.py` do exactly the fast path the inline step did when the push succeeds (allowlist first, explicit `git add`, bot identity, one commit, one push), and on rejection: discard (`reset --hard`), lift **only** receipt files from the discarded commit, publish them (≤3), recompute **once** with `RECONCILE_ARGS` + coalesced `--pr/--commit` + `--only-receipted --skip-pull`, never rebase, never force? (2) `wave_reconcile.py --only-receipted`: is the partition using the same matcher as the qualifier, are explicit unreceipted targets fail-closed, is `issue_owners` untouched, and does the flag refuse without `--catch-up --qualify`? (3) #741 — does `terminal_error()` never blame a green reconcile step's log, keep the red reconcile step's last error, and do skips from both logs still demand attention? Is the workflow passing the right values (`steps.reconcile.outcome`, `steps.publish.outcome`, publish log tee'd)? (4) Do the tests substantiate the claims: gh740's fixture drives a real bare remote and racer; the **production** `qualification_receipt_matches` accepts the published receipt and refuses a corrupted one; the stale clone's plain push is the red control; the second-race, no-receipts, undeclared, and F6a parser cases; gh421's four `--only-receipted` cases incl. the F6 open-reference retention; gh684's replay of run 35623940059 with the old `summarize()` as red control? Name any claim a test does **not** actually pin. (5) Are the gh421 pin moves the minimum (YAML extraction removed because no inline Python remains) and is anything that was pinned before no longer pinned? (6) Ratings `85/75/50/55` and `70/55/50/80` still match the delivered scope? (7) Anything in the diff outside the two issues' scope? Focused evidence: gh684 10/10, gh421 36/36, gh740 7/7, ci-workflow 0 failed; the full gate in a disposable clone is running in parallel and its receipt will be attached before the PR. Grade [Must]/[Should]/[Nit]; **Approved** when no [Must] remains.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

## Reviewer — codex — Round 1

VERDICT: PASS
Basis: No [Must]/[Blocker] found in the seeded implementation against the approved Requirements. Approval is code-review approval; clone-run evidence and final-commit gate remain required before merge readiness. Nonblocking evidence gaps below should be corrected when attaching that evidence.
swept file: yes

Sweep: complete publisher, reporter, workflow and gh740/gh684 suites; the explicitly scoped wave_reconcile argparse/partition and gh421 WorkflowTests/only_receipted sections, validate registration, CHANGELOG top entry and approved plan. No additional pre-existing functional defect found in these reviewed surfaces. Historical base comparison was not performed: this reviewer is expressly prohibited from running git, so “verbatim move” and absence of unrelated changes across the entire commit range are not independently attested.

- [Pass] Q1: `utils/py/hosted_lane_publish.py:70`, `:91`, `:182` preserve the changed-path allowlist before explicit staging, bot identity, one initial commit/push. Recovery at `:207` resets to the fetched remote, checks out only receipts, bounds their publication to `RECEIPT_ATTEMPTS = 3`, then recomputes once (`:218`) and fails on a second transition-push rejection. No executable rebase or force-push. `retry_argv` (`:137`) coalesces original and receipt targets; `recompute` (`:167`) clears the planner fingerprint. No second subsystem or wider allowlist needed.
- [Pass] Q2: `utils/py/wave_reconcile.py:1937` rejects the flag without catch-up/qualification. The partition at `:2022` calls the same `committed_qualifications`/`qualification_receipt_matches` pair used in `qualify_landings` (`:535`), refuses explicit missing receipts, logs recovered deferrals, and retains full metadata for `issue_owners`. The qualifying-suite call exists only in the opposite branch. gh421 `:514–555` covers older-deferred/newer-owned, both-receipted, explicit refusal, argument constraints and the OPEN reference's merge evidence.
- [Pass] Q3: `utils/py/hosted_lane_report.py:69` selects the failing step's log; `:129` collects skips from both logs. Workflow uses both step outcomes, `job.status`, publish tee and pipefail. Narrow read-only probe, command: `PYTHONDONTWRITEBYTECODE=1 python3` importing the reporter and calling `terminal_error('success', ['wave-reconcile: ERROR — invalid merged_at timestamp'], 'failure', ['hosted-lane-publish: ERROR — push rejected'])`, then the same reconcile log with outcomes `failure`/`skipped`; exit 0, decisive output: `('publish', 'push rejected')` and `('reconcile', 'invalid merged_at timestamp')`. gh684's `test_green_reconcile_red_publish_names_the_publish_step_not_a_test_line` retains the old summarize result as the contrasting control.
- [Pass] Q4, static fixture assessment: gh740 `:147` uses a real bare remote and racer, observes a rejected stale plain push, checks racer → receipts → transitions history and surviving racer ledger bytes, and invokes the production receipt consumer before/after telemetry corruption (`:177`). Second race, absent receipts and undeclared paths are present. Parser declarations are extracted from production, not copied, and repeated PR options provide the negative control (`:208`). These are substantive assertions; their execution was not repeated here.
- [Should] Q4/Q5, evidence coverage: gh421 `:637` mocks `commit()` itself, so its path-list assertions no longer pin actual `git add -A -- <paths>` staging or bot identity. Add a narrow assertion of the real helper's git argv in the disposable-clone suite. Also missing are receipt-publication retry exhaustion (three rejected receipt pushes), an existing `--commit` target coalesced with another receipt target, and an assertion that the second-race diagnostic contains the actual racing SHA (gh740 `:185` only matches the prefix). None demonstrates a current production failure; these are test-coverage requests, not runtime behavior changes. The newer-unreceipted/older-receipted ownership case is also not pinned by gh421's current variants.
- [Nit] Evidence count: the seed says gh740 “7/7”, but AST inspection finds six `test_*` methods. Command: `PYTHONDONTWRITEBYTECODE=1 python3` extracting the shell heredoc with `split("<<'PY'\n",1)[1].rsplit('\nPY',1)[0]`, parsing with `ast.parse`, and counting `FunctionDef` names starting `test_`; exit 0, output `gh740 test count: 6`. Reconcile the prose with the actual final clone-run output.
- [Nit] The publisher's module/plan promise “Every failure” has the canonical prefix is broader than implementation: `declared_paths` (`:78`) exits with `Refusing undeclared reconciliation artifacts`, and `git` (`:66`) can raise an uncaught subprocess exception. Narrow that promise to handled recovery failures, or normalize those errors in a future change. Reporter fallback still attributes these to publish; this does not recreate #741.
- [Pass] Q5/Q6/Q7, current scope: gh421 retains allowlist refusal cases (`:700`), trigger/permission/queue checks (`:603`) and step ordering (`:674`); inline-Python extraction is obsolete for the now-external module. Ratings `85/75/50/55` and `70/55/50/80` remain consistent with the plan's stated impact/effort and delivered one-lane change. `validate.sh:573` registers the fixture and the top CHANGELOG entry describes this same scope. No unrelated addition identified in the seeded review surfaces; historical pin equivalence remains unverified as noted above.
- [Unverified — needs clone run] Claimed focused pass counts, full qualifying gate, mutation controls and final-SHA provenance must be attached from the disposable full clone. No validate.sh, test/*.sh, pytest, executable fixture or git command was run in this turn. Approval does not attest a hosted run or authorize merging.

Relay closed (Approved), no further turn needed. Producer claude-a owns the remaining evidence attachment and nonblocking dispositions; harness owns the file-scoped commit.


### Attestation · relay-drive — 2026-09-21T22:21:02Z
task: gh740-741-final-qa
reviewer: codex
status: Approved
reviewed-head: c28ac293992e88a917036e11820dfd170bfdf476
added-range: 7799+6004
added-sha256: 638dcc64acf19c518c3357f266f81556611c73938f4fc34982b1460f84b97361
## Producer — claude-a — post-approval dispositions

- **[Should] evidence coverage — Accepted (tests only, no production change).** gh740: the second-race diagnostic is now asserted to contain the actual racing SHA (`origin/development` after the race); the fast-path case pins the remote commit's author/email (`github-actions[bot] <41898282+…>`) and its exact staged path set via `git show --name-only`, so the real `commit()` helper's `git add -A -- <paths>` and identity are pinned in the clone suite; the F6a parser case adds an existing `--commit` target coalesced with a receipt's commit + a receipt PR. gh421: receipts-loop exhaustion — four rejected pushes → exit 1, commits = T + 3 receipt attempts, zero recompute.
- **[Nit] count — Accepted.** gh740 is 6 test methods; the plan's status now says 6/6.
- **[Nit] "every failure" promise — Accepted.** Docstring narrowed to *handled recovery failures*; the allowlist refusal keeps its historical text; unexpected git errors surface as tracebacks and the report falls back to the last log line.
- The newer-unreceipted / older-receipted ownership case: covered by `test_only_receipted_defers_the_unreceipted_older_closer_and_keeps_newest_owner`'s inverse? No — that case has the *older* unreceipted. `test_only_receipted_with_both_receipted…` has both receipted. The newer-unreceipted/older-receipted variant is exercised by the same `issue_owners` code path (ownership is computed over full `metadata` before the partition) — recorded here as **not separately pinned**; `Disposition: Rejected (Out of Scope / Ponytail)` for a fifth ownership permutation on a 15-line flag whose ownership code is unchanged.

Focused suites after these edits: gh740 **6/6** — the earlier "Ran 7" was a fixture helper named `tested()` that unittest collected as a vacuous test (prefix `test`); renamed away, so the count now matches your AST count. gh421 36/36. Full gate runs once on the final commit in a disposable clone; receipt attached to the PR.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
