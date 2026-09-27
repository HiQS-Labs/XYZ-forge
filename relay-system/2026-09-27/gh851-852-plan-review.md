# RELAY · GH-851/852 plan review — merge-cleanup landing resilience
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-09-27.
-->

NEXT: Producer
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
   Reviewer headings may be `### Reviewer · Round N`, `### Round N · Reviewer · <agent>`, `### Reviewer (<agent>)` (optionally followed by `— rN`), or `### Reviewer — Round N` (optionally followed by `(<agent>)`); follow the heading with a non-empty review body.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(gh851-852-plan-review): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **.relay-artifacts/GH-851-MERGE-CLEANUP-LANDING-RESILIENCE.md** — the read-only path that
  `relay-drive.sh --artifact-file PROJECT/1-INBOX/GH-851-MERGE-CLEANUP-LANDING-RESILIENCE.md` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-09-27
- Definition of Done: **Approved** when all of these hold:
  - (a) every recon claim R1–R9 matches the cited file and line at the branch base `030ab5ba`. That includes the R2 list of unbounded network git calls; say if any network call site is missing;
  - (b) each finding F1–F5 has a change that fixes the observed incident, not a generalization of it. Each has a falsifiable red/green witness that is red at the base and green at the head;
  - (c) the plan extends the existing GH-623 `_net_git` / `_retry_call` and GH-736 `_await_mergeable` machinery. It adds no new module, helper family, suite, registry entry or gate machinery (AGENTS.md *No new tests*);
  - (d) the risks are real and the rollback is sound. F2 cannot report a merge that GitHub does not show as `MERGED` with a merge commit. F3 fails closed;
  - (e) the ratings (#851 `55/35/50/85`, #852 `60/45/50/65`) are grounded in the cited #849 evidence, and appeal is neutral.

## Review packet

**What this is.** One PR for #851 and #852. It is the first direct-path item of #854, the operator-approved
stabilization plan (revision 3), and it carries #854's decision D5 (the 5400 s hosted-wait default). Every finding
was hit in the #849 merge batch on 2026-09-27. The plan is the committed capture doc
`PROJECT/1-INBOX/GH-851-MERGE-CLEANUP-LANDING-RESILIENCE.md`, seeded as the artifact above.

**Read these sources yourself.**
- `skills/2-daily/merge-cleanup/scripts/merge_cleanup.py`:
  - `_gh` `:70`, `_net_git` `:106`, `_retry_call` `:117`, `execute_pr_merge` `:148-174`;
  - `prepare_landing_clone` `:278-308`, `validate_head_in_second_clone` `:311-333`, `push_resolved_head` `:336-346`;
  - `wait_for_hosted_reconcile` `:422-501`, `run_post_merge_reconcile` `:523-570`, `commit_and_push_phase5_writes` `:584-620`;
  - `_await_mergeable` `:790-805`, the post-B1 re-gate `:961-974`, `--reconcile-pr` in `main` `:1109-1115`.
- `skills/2-daily/merge-cleanup/scripts/scan_clones.py`: `run_git` `:86-110`, the fetch at `:437`.
- `skills/2-daily/merge-cleanup/SKILL.md:153`.
- Tests: `test/gh534_phase_c_tests.py` (`TestGh623Resilience`, `TestParityGuard`) and `test/gh674-merge-cleanup-hosted-lookup.sh`.
- Incident evidence: #849 comments 5852638878 and 5857312850; #851; #852 and its two comments.

**Specific questions.**
1. Is R3 right? Does `subprocess.run(timeout=…)` on macOS stop counting while the machine sleeps, so that no in-script bound can cap wall time? If so, is adding git's `http.lowSpeedLimit` / `http.lowSpeedTime` still worth it on top of `timeout`?
2. F1: is 3600 s right for the post-merge `push` at `:601`? That push runs the repo's pre-push hook, which can run a gate.
3. F2: is "re-query once after a non-zero `gh pr merge`" enough? Should it reuse the zero-exit path's six-poll loop (`:167-173`) instead of a single read?
4. F3: is refusing a not-yet-merged PR in `--reconcile-pr` the right fail-closed behaviour? Can any existing caller or suite depend on the old behaviour?
5. F4: can waiting for `headRefOid == pushed commit` be defeated? For example, a third party pushing to the branch in the window. Today `push_resolved_head` refuses when the remote head moved before the push.
6. Witnesses: are the stub-based red/green witnesses under `TESTS-RESULTS/` falsifiable enough? Or must a behaviour one of them shows be pinned by editing an existing test, because an existing test pins the old behaviour?

**Operating envelope.** This is a single-operator developer tool run from one laptop against one GitHub repo.
Grade against the stated requirements and commensurate complexity: a few surgical changes in an existing script.
Do not grade against multi-tenant or adversarial threat models, or ask for new infrastructure.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer · Round 1

VERDICT: FAIL
Basis: The surgical scope and incident diagnosis are sound, but F1's retry claim and witness recipe do not match the code, and the plan misses existing tests that must change to remain truthful. Resolve C1–C3 before implementation approval.
swept file: yes

Read the entire seeded artifact, including recon, ratings, witnesses and rollback; traced its named code paths and existing callers/tests. The pre-existing issues found in the reviewed surfaces are identified below (transient classification, captured timeout default, stale skill prose). No artifact or source edits, git commands, suites or executable fixtures were run. Base attribution is to the supplied seeded checkout; no independent git comparison to `030ab5ba` was performed.

- **[Should] C1 — F1's new low-speed abort does not enter the existing transient path.** Artifact lines 69 and 126 call these failures retryable, but `merge_cleanup.py:94-103` does not match `curl 28 … Operation too slow`. The narrow source probe below returned `curl28 transient: False`. `_retry_call` therefore returns immediately at `:126-127`; the landing-clone caller hard-stops rather than deferring at `:882-890`. Cheapest fix: explicitly include this observed low-speed diagnostic in the existing classifier, with a manual witness for three attempts at an existing retry site and a non-transient control. Preserve the plan's decision not to add retries to the newly bounded sites; distinguish that decision from classification at existing retry sites. Correct the risk statement: a live transfer below the threshold can also be aborted.
  Observed input: #852's prescribed low-speed abort and artifact R3's `curl 28 … Operation too slow`; concrete probe input was `error: RPC failed; curl 28 Operation too slow. Less than 1000 bytes/sec transferred the last 120 seconds`.
  Affected scope: this specific curl low-speed diagnostic at existing GH-623 retry/defer sites; no new retry policy or helper family.
  Falsifier: the same diagnostic must classify transient and get three attempts; an authentication/repository-not-found diagnostic must still get one. If a captured incident diagnostic already contains an existing matched token, show that exact text and revise the claim rather than broadening indiscriminately.

- **[Should] C2 — Repair and complete the planned evidence, without changing runtime solely for a probe.** Artifact `:99` says patching `NET_TIMEOUT_S` shortens the witness, but `_net_git(..., timeout=NET_TIMEOUT_S)` captures 180 at definition time (`merge_cleanup.py:106`); the probe below returned `patched constant: 0.01 effective default: 180`. Patch the witness's call seam to forward an explicit short timeout to the real helper (or its captured default), and have the stub recognize the leading `-c` arguments. State that F1's witness records bounds/config for all six R2 sites, including 3600 on the hook-running push; one clone alone cannot establish the six-site criterion. For F5, replace the unspecified `grep`/parity claim (`:87`) with an explicit base-red/head-green assertion of the effective default with `HOSTED_WAIT_ENV` unset, plus the skill text value. For F3, include the already-specified OPEN/error refusal cases and assert that no local writer runs while H's hosted run is active. Keep these manual checks in the already-proposed evidence file, with nonempty logs and committed provenance.
  Observed input: artifact `:97-100` and the live function definition at `merge_cleanup.py:106`; changing the module constant after definition leaves the call's timeout at 180.
  Affected scope: the proposed manual witness recipe and acceptance evidence, not an expansion of production behaviour.
  Falsifier: show the shortened bound reaching the actual `run_git` call, base timing out only at the outer watchdog, and head returning rc-124-derived failure inside it; an unchanged 180-second default must fail that witness. F5 must fail at base 1800 and pass at head 5400.

- **[Should] C3 — Name the necessary existing-test adaptations.** R8/step 6 currently only say run the suites. Adding `-c` prefixes bypasses command-match stubs in `test/gh534_phase_c_tests.py:756,816,839` and `test/gh436-merge-cleanup.py:413-421`. F3 also introduces a real PR query into `TestMergeCleanupOrchestration._run_main` (`test/gh436-merge-cleanup.py:352-363`), whose ready-primary test at `:374-379` previously needed no PR response. The existing reconcile-failure test (`test/gh534_phase_b_tests.py:522-525`) can now pass on the new refresh refusal without ever testing reconciliation. Plan surgical edits to those existing seams: recognize the git options while preserving failure injection; supply a MERGED PR response with H/M for ready/reconcile-failure paths; assert the intended reconcile call was reached. No new test method, suite or gate is needed.
  Observed input: literal stub predicates `args[:1] == ["clone"]`, `args == ["fetch", "origin", "development"]`, and `args[0] == "fetch"`; `_run_main` mocks reconciliation but not PR refresh; the failure-propagation case supplies PR 7 without establishing a merged PR.
  Affected scope: existing tests whose injected command shape or reconciliation preconditions change under F1/F3.
  Falsifier: in a disposable full clone, retain the injected-failure counts (three attempts), demonstrate the ready-primary test invokes reconciliation with H/M, and make the failure-propagation assertion go red when reconciliation's failure is ignored. **[Unverified — needs clone run]** These suite outcomes were not executed in this reviewer worktree.

- **[Pass] Recon and scope, with small qualifications.** R1/R2 match the read source: `_gh` bounds at `:70,161,444`; five unbounded network calls in `merge_cleanup.py:316,343,550,601,605`, plus `scan_clones.py:437`. An AST inventory found no additional direct network git call in those two files; `:320` is the local-path fetch. `:1006` is post-merge, not Phase 0 as R1 labels it. R4–R6 match `:161-173`, `:538-543`, `:790-805`, `:970-974`, `:1112-1115`. R7's default and explicit test overrides match `:431` and `test/gh674-merge-cleanup-hosted-lookup.sh:45,73,121`. R8 names the relevant suites, subject to C3. R9 agrees with `utils/ci-route.sh:67,336-337,348`. The plan at `:83-118` reuses current helpers and adds no module, suite or registry entry.

- **[Pass] Q1/Q2 — the host rule and a separate push bound are justified.** Local `time.get_clock_info('monotonic')` reported `mach_absolute_time()`; `subprocess._time.__name__` reported `monotonic`, and `Popen._remaining_time` subtracts it from the deadline. Apple documents that this clock excludes system sleep: https://developer.apple.com/documentation/driverkit/mach_absolute_time . This supports the awake-time limitation, not a proof that sleep alone explains every historical hang. Keep the host rule; HTTP low-speed settings add useful transport-level termination. They do not bound SSH transfers or establish child-process cleanup. Q2: 3600 seconds is defensible against #849's measured awake full gates of 862/874 seconds (comment 5857312850); hosted 52.8–65.9-minute durations are a different budget. The #852 body also explicitly records surviving git children after the parent was killed: do not describe `subprocess.run(timeout=...)` as process-tree cleanup. No descendant probe was run.

- **[Pass] Q3/Q4/Q5 — proposed incident fixes are appropriately narrow.** F2's MERGED-plus-commit condition (`artifact:102`, existing `merge_cleanup.py:168`) avoids false merge success; one read fixes the observed #810 case. Reusing the existing six-poll confirmation loop is a reasonable simplification, but delayed MERGED visibility after a failed call was not established here, so it is not a new requirement. Make “merge commit” explicitly mean a nonempty `mergeCommit.oid`, as the current success branch does. F3's refusal on OPEN/error (`artifact:106-109`) is the right fail-closed change, with existing callers accounted for by C3. F4's exact-head wait (`artifact:112-114`) handles the documented stale old-head response. A different head that never equals the pushed commit leads to a bounded refusal; a head changing during `_await_mergeable` is then used to prepare a new landing clone and re-gated (`merge_cleanup.py:976-989`). Do not claim the equality observation locks a branch. Name the budget as poll attempts/sleeps, not a strict 90-second wall limit: individual refreshes themselves have timeout/retry budgets.

- **[Pass] Ratings, D5 and rollback.** The #849 comments 5852638878/5857312850 and #851/#852 bodies corroborate resume cost, a hung verification clone, merged-but-reported-failed #810, and the wrong SHA stopped by the second guard. The stated `55/35/50/85` and revised `60/45/50/65` are defensible prioritization judgments, with appeal explicitly neutral (`artifact:44-51`), rather than measured numerical facts. #854 revision 3 D5 explicitly authorizes 5400 globally. Source rollback is Easy: revert the code/doc change (`artifact:129`); that does not undo PRs already merged, and observed-remote-state checks remain the safety condition. Exact “every repair” counts beyond the cited incidents and raw sleep logs were not independently reproduced.

- **[Nit] Existing prose drift on a line already scheduled for editing.** `SKILL.md:153` still advertises `gh run list --branch ... --commit ...`, although `merge_cleanup.py:436-439` deliberately omits both filters and matches H/M. Correct that sentence while changing 1800 to 5400. Also name debug-mantra as the execution-time diagnosis protocol; the plan is currently silent on it.

**Probe receipt (non-mutating source extraction; exit 0).** Ran `python3 -` with the following program under `PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"`; no git or repository function with filesystem effects was invoked:

```python
import ast, pathlib, re, subprocess
p = pathlib.Path("skills/2-daily/merge-cleanup/scripts/merge_cleanup.py")
t = ast.parse(p.read_text())
names = {"NET_TIMEOUT_S", "TRANSIENT_RE"}
nodes = [n for n in t.body if
    (isinstance(n, ast.Assign) and any(isinstance(x, ast.Name) and x.id in names for x in n.targets))
    or (isinstance(n, ast.FunctionDef) and n.name in {"_net_git", "_transient"})]
ns = {"re": re, "Path": pathlib.Path, "List": list, "subprocess": subprocess,
      "run_git": lambda cwd, args, timeout: timeout}
exec(compile(ast.Module(body=nodes, type_ignores=[]), str(p), "exec"), ns)
ns["NET_TIMEOUT_S"] = 0.01
print("patched constant:", ns["NET_TIMEOUT_S"], "effective default:",
      ns["_net_git"](pathlib.Path("."), ["clone"]))
s = "error: RPC failed; curl 28 Operation too slow. Less than 1000 bytes/sec transferred the last 120 seconds"
print("curl28 transient:", ns["_transient"](s))
```

Decisive output: `patched constant: 0.01 effective default: 180`; `curl28 transient: False`. Source reads/AST inventory exited 0. Read-only `gh api repos/HiQS-Labs/XYZ-forge/issues/comments/{5852638878,5857312850}` and issue 851/852/854 queries succeeded (exit 0); an intervening `gh issue view` batch failed with `error connecting to api.github.com` (exit 1), then API reads recovered. These are source/incident checks, not executed red/green implementation evidence.

Handing off to Producer (claude-a) — address C1–C3, disposition the nits, then return the revised plan for review.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
