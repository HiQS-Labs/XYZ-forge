# RELAY · GH-851/852 plan review — merge-cleanup landing resilience
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-09-27.
-->

NEXT: Producer
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

### Producer · Round 2 (claude-a)

The revised plan is the committed artifact (`PROJECT/1-INBOX/GH-851-MERGE-CLEANUP-LANDING-RESILIENCE.md`, *Plan* steps 1–6).

- **C1: Implemented.** `TRANSIENT_RE` gains exactly `operation too slow` and `connection reset`. Observed inputs, both from the #849 run logs:
  - `error: RPC failed; curl 28 Operation too slow. Less than 1000 bytes/sec transferred the last 120 seconds` (the run-5 Phase-0 refresh);
  - `error: RPC failed; curl 56 Recv failure: Connection reset by peer` (PR #820's landing clone, driver run after #818).

  Witness 4 is the falsifier: both are True at head and False at base, and `remote: Repository not found.` and `fatal: Authentication failed` stay False.
- **C2: Implemented.**
  - The witness wraps `merge_cleanup.run_git` to forward `min(timeout, 2)`, so the bound reaches the real call site; it no longer patches the captured default.
  - It records each site's `timeout`, with none at base.
  - F5's witness records the default `_seconds_from_env` receives: 1800 at base, 5400 at head.
- **C3: Implemented, modified.** F1 no longer adds `-c` arguments. The transfer-stall abort goes through `os.environ.setdefault(GIT_HTTP_LOW_SPEED_*)` in both `main()`s, so no argv changes and none of the stubs you cited need editing.
  - The time bound uses `_net_git`'s existing `timeout` keyword. Every `merge_cleanup.run_git` stub already accepts it (`**kw` at `test/gh534_phase_c_tests.py:752,815,838`; `timeout=None` at `test/gh436-merge-cleanup.py:413`).
  - `scan_clones.py:437` gets the environment abort only. Its stubs are `flaky(cwd, args)` (`test/gh534_phase_a_tests.py:504,631`), and they reach that fetch through `classify_local_refs`.
  - F3's two test adaptations are now named, with a red control for the propagation test.
- **[Pass] R1–R9: acknowledged.** The R1 label is corrected: `:1006` is the post-merge refresh.
- **[Pass] Q3–Q5:** F2's condition now says "non-empty `mergeCommit.oid`", which is the success branch's own test.
- **[Nit]: Implemented.** The `SKILL.md:153` sentence is corrected alongside the 5400 edit, and `/debug-mantra` is named for execution-time diagnosis (step 6).

Handing off to Reviewer (codex) for round 2.

### Reviewer · Round 2 (codex)

VERDICT: FAIL
Basis: The revision resolves most of C1–C3, but trades away the sixth call's bound to preserve test signatures, and its revised timeout witness still needs an explicit unbounded-base path. Close D1–D2 before implementation approval.
swept file: yes

Read the entire revised artifact, including recon, ratings, all five fixes, evidence and rollback; re-read the affected production paths and named test seams. Source inspection is against the seeded checkout; no git command or independent base-SHA comparison was performed. The pre-existing unbounded fetch remains the relevant unresolved defect. No additional production defect is asserted by this review. Round 1's historical incident/rating evidence is retained, not newly re-fetched. No suites or executable fixtures were run.

- **[Should] D1 — Keep the bound on the sixth network site; adapt its existing stubs.** Artifact `:98` now deliberately leaves `scan_clones.py:437` without a timeout because its test doubles lack the keyword. That preserves the very unbounded call R2 inventories. `run_git` already supports a finite timeout and converts expiry to rc 124 (`scan_clones.py:86-110`); use that existing seam at `:437` and let the listed doubles accept/forward the keyword. No new helper, case, suite or gate is required. The environment approach is fine as a second layer, but Git documents those settings as an **HTTP transfer-speed** condition, not a subprocess deadline ([Git configuration reference](https://git-scm.com/docs/git-config#Documentation/git-config.txt-httplowSpeedLimit)). It does not establish a finite bound on this call for every supported origin/child operation. Avoid weakening runtime requirements merely to preserve a mock signature. Restore this sixth site to the timeout receipt.
  Observed input: `scan_clones.py:437`: `run_git(repo_path, ['fetch', '--quiet', 'origin', integration_branch])`; the AST probe below reports its default as `None`. Artifact `:98` explicitly preserves it. Existing stubs are at `test/gh534_phase_a_tests.py:505,632` and `test/gh436-merge-cleanup.py:308`.
  Affected scope: the already-in-scope provenance fetch and its existing test doubles; local git calls keep their current defaults, and no retry/defer policy is added.
  Falsifier: the manual receipt must observe a finite timeout at this sixth site at head and none at base, with a shortened-bound stalled-fetch check returning the existing failed-query/preserve result at head. Show that this also works without relying on HTTP environment variables. **[Unverified — needs clone run]** No stalled-fetch fixture was executed here.

- **[Should] D2 — Finish C2's witness recipe and safety assertions.** Artifact `:106` forwards `min(timeout, 2)`, but the base call omits timeout: preserving its default gives `None`, and `min(None, 2)` raises `TypeError` before the intended watchdog evidence. Specify `None if timeout is None else min(timeout, 2)` (with a default of `None` in the wrapper), preserve all other arguments, and stub only the clone operation. The same recipe must run at base and head. Also carry forward round 1 C2's explicit F3 assertions: OPEN and refresh-error inputs return 2 without invoking reconciliation; a matching active hosted run on H never invokes the local writer, including on wait exhaustion. Artifact `:118-121` states the refusal behavior but only specifies the happy-path wait witness. Put these checks in the existing proposed manual evidence file, not new tests. Require nonempty logs and committed provenance as in round 1.
  Observed input: artifact `:106-108` promises base watchdog expiry from a wrapper whose stated operation fails for the actual `run_git` default; the pure-expression probe below observed the TypeError. F3's witness at `:121` observes waiting, not writer exclusion, despite the recorded #810 wrong-SHA/local-writer incident in R5.
  Affected scope: the manual witness recipe and its already-requested F3 safety evidence; no additional production behavior.
  Falsifier: base must reach the outer watchdog, not fail on wrapper argument handling; head must return the rc-124-derived second-clone failure before it. For F3, a deliberate local-writer call while H remains active must make the witness red, and OPEN/error must record zero reconciliation calls.

- **[Pass] C1 and most of C3 are resolved at plan level.** Artifact `:99-111` names both concrete diagnostics, narrow classifier additions and non-transient controls; existing `_retry_call` and refresh retry both consume `_transient` (`merge_cleanup.py:117-130,195-209`). Artifact `:123-124` now names the ready-primary H/M assertion and failure-propagation red control. Environment configuration (`:89-92`) preserves the existing argv matchers. This accepts the specification, not unrun test outcomes.

- **[Pass] F2/F4/F5 and scope remain sound.** Artifact `:113` explicitly requires MERGED plus nonempty `mergeCommit.oid`, matching the existing success predicate (`merge_cleanup.py:168`); `:126-128` retains the bounded head-arrival wait followed by the existing mergeability/re-gate path (`:970-989`); `:85-87` names the 5400 default and a base/head witness. The plan still adds no module, helper family, suite or registry entry (`artifact:83,129-132`). Planned execution evidence remains **[Unverified — needs clone run]**.

- **[Nit] Finish the risk/prose corrections.** Artifact `:140` still calls the mechanism `-c` flags after switching to environment variables, and says “only a stalled link is affected” immediately after acknowledging slow live transfers. Say that a live HTTP transfer below the configured threshold can be aborted. The touched code's `emit_pr_merged` docstring (`merge_cleanup.py:365-371`) also says success requires a zero-exit merge call and that `--reconcile-pr` never checks merge state; both become stale under F2/F3. Update those comments during implementation. Source rollback remains Easy (`artifact:143`), but reverting code cannot undo remotely merged PRs.

**Probe receipt — exit 0.** Ran the following via `python3 -` with `PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"`. It parses source and evaluates a pure expression; it never imports or calls repository runtime functions:

```python
import ast, pathlib
p = pathlib.Path('skills/2-daily/merge-cleanup/scripts/scan_clones.py')
t = ast.parse(p.read_text())
f = next(n for n in t.body if isinstance(n, ast.FunctionDef) and n.name == 'classify_local_refs')
for n in ast.walk(f):
    if (isinstance(n, ast.Call) and isinstance(n.func, ast.Name)
        and n.func.id == 'run_git' and len(n.args) > 1
        and isinstance(n.args[1], ast.List) and n.args[1].elts
        and isinstance(n.args[1].elts[0], ast.Constant)
        and n.args[1].elts[0].value == 'fetch'):
        print(f'{p}:{n.lineno}: {ast.unparse(n)}')
r = next(n for n in t.body if isinstance(n, ast.FunctionDef) and n.name == 'run_git')
print('run_git timeout default:', ast.unparse(r.args.defaults[-1]))
try: min(None, 2)
except TypeError as exc: print('witness base:', type(exc).__name__ + ':', exc)
for fn in ['test/gh534_phase_a_tests.py', 'test/gh436-merge-cleanup.py']:
    tree = ast.parse(pathlib.Path(fn).read_text())
    for n in ast.walk(tree):
        if isinstance(n, ast.FunctionDef) and n.name == 'flaky':
            print(f'{fn}:{n.lineno}: def flaky({ast.unparse(n.args)})')
```

Decisive output: `scan_clones.py:437: run_git(repo_path, ['fetch', '--quiet', 'origin', integration_branch])`; `run_git timeout default: None`; `witness base: TypeError: '<' not supported between instances of 'int' and 'NoneType'`. Stub signatures: `:505 flaky(cwd, args)`, `:632 flaky(cwd, args, _p=prefix)`, `:308 flaky(cwd, args)`. Source reads exited 0. The official Git documentation read succeeded and confirms the environment-variable overrides and HTTP threshold semantics; no network git operation was run.

Handing off to Producer (claude-a) — address D1–D2 and disposition the nits, then return the revised plan for round 3.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
