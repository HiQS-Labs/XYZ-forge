# RELAY · GH-1625 plan QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-11-25.
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
     change MUST carry `Observed input:`, `Affected scope:` (the input predicate the change would govern),
     and `Falsifier:` (the fixture or data that would show the change unnecessary or wrong, and its expected
     result). `Observed input:` accepts two strict, non-speculative forms:
     (1) **Form 1 (observed failure or artifact contradiction):** a failing probe/gate output, or a concrete
     `fileA:line` vs `fileB:line` contradiction (e.g. IAM SA mismatch, inverted test, sibling guard omission);
     (2) **Form 2 (unrunnable runtime hazard trace):** permitted ONLY when reproduction requires an external
     service, multi-process concurrency, or a browser/container runtime forbidden in the relay worktree —
     must supply a hop-by-hop `file:line` trace plus an exact `Clone probe:` command/script for the Producer's
     disposable full clone. Default severity for an unexecuted Form 2 hazard is `[Should]`.
     A `[Blocker]` must cite an observed failure (Form 1); an unexecuted Form 2 hazard stays `[Should]`
     until a probe reproduces it, and remains pending probe verification until the Producer runs
     `Clone probe:` in a disposable full clone.
     A finding from an earlier round stays open, and the verdict stays failing, until new evidence closes it.
     This includes earlier [Nit] findings; only a newly raised [Nit] with VERDICT: PASS on STATUS: Approved remains optional.
     This is a protocol rule, not a mechanical check —
     the Producer may disposition a request lacking Form 1 evidence and lacking a complete Form 2 trace + `Clone probe:` as `Declined — unproven generalization`.
   - **Producer:** log a disposition for every open finding (Implemented / Modified / Declined + why,
     including `Declined — unproven generalization` for a behaviour-change request lacking Form 1 evidence and
     lacking a complete Form 2 trace + `Observed input:` / `Affected scope:` / `Falsifier:` / `Clone probe:`).
     For every Form 2 `Clone probe:` finding, read the probe before running it — refuse any probe that reaches
     the network, credentials, or paths outside the disposable clone and record the refusal as
     `[Unverified — clone probe failed/unavailable]` — then execute safe probes in a disposable full clone and
     record one of three outcomes: (a) Reproduced → fix and paste failing-before / passing-after probe output;
     (b) Falsified → `Declined — falsified by clone probe: <cmd → exit + output>`; (c) Errored, refused, or
     environment unavailable → keep the finding OPEN (`[Unverified — clone probe failed/unavailable]`, blocking
     `STATUS: Approved` until re-run cleanly or escalated/parked). Make approved changes, then add new work.
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
   Reviewer headings may be `### Reviewer · Round N`, `### Round N · Reviewer · <agent>`, `### Reviewer (<agent>)` (optionally followed by `— rN`), or `### Reviewer — Round N` (optionally followed by `(<agent>)`); follow the heading with a non-empty review body.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Manual relay: commit only the relay file** (`relay(gh-1625-plan-qa): <role> r<N>`); no push.
   **Driven turn (relay-drive, marathon): do not run git — the harness commits the turn.** **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. (The window wording is
   for a manual relay; in a driven turn, name the next role.) The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: `PROJECT/2-WORKING/GH-1625-SUITE-TEMP-ISOLATION.md` (the plan; no code yet)
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-11-25
- Definition of Done: the plan, as written, would make the merge-cleanup unit suite (gate entry
  `test/gh436-merge-cleanup.sh` → `test/gh436-merge-cleanup.py`, which imports
  `gh534_phase_a/b/c_tests`) stop creating `merge-cleanup-*`/`merge-check-*` folders in the inherited
  system temp directory and stop running `prune_retained_scratch` against it, with falsifiable
  acceptance checks and no new tests (AGENTS.md *No new tests*, GH-831).
- Operational envelope: local developer test suite in a single repo. Commensurate complexity: this is
  a ~10-line change to one existing test module. Do not ask for new suites, shared fixture libraries,
  or changes to production `merge_cleanup.py` behaviour (explicit non-goals in the plan).

### Step 1 — paraphrase first (GH-1414)
Before reading anything except the plan doc, write 2–5 sentences each under **What this proposes** and
**How the existing system works, per this document**, plus a short **What it's not**. Label inference.

### Step 2 — source-backed validation
Then read the sources: `skills/2-daily/merge-cleanup/scripts/merge_cleanup.py` (`prune_retained_scratch`
near lines 354-430, `_land_prs_loop` near 2013-2025 and its `finally` near 2531-2545, `land_prs` call site
near 3093-3097, `run_isolated_check`), `test/gh436-merge-cleanup.py` (top-of-file imports near 1-50 and
the phase-module imports near 1382-1384), `test/gh534_phase_a_tests.py`, `test/gh534_phase_b_tests.py`,
`test/gh534_phase_c_tests.py` (their own `tempfile`/`gettempdir`/SAFE_ROOTS usage), and
`test/gh436-merge-cleanup.sh`.

Questions:
1. Is the root-cause claim grounded: does any of the four modules already isolate `TMPDIR` or
   `tempfile.tempdir`, and is gh436 the only gate entry that runs them (check `validate.sh` TESTS and
   `test/ci-route.sh`)?
2. Will setting `os.environ["TMPDIR"]` + `tempfile.tempdir = None` at the top of
   `gh436-merge-cleanup.py`, before `import merge_cleanup` and the phase-module imports, actually reach
   every path: in-process `mkdtemp`, `gettempdir()` inside `prune_retained_scratch`, child processes the
   phase modules spawn (`subprocess.run([sys.executable, …], env=…)` — check whether any of them build
   `env` from scratch and so drop `TMPDIR`), and module-level constants computed at import time from
   `gettempdir()` (e.g. SAFE_ROOTS widening in phase A)?
3. Is the `atexit` removal guard safe (removes only the exact created path) and is there any case where
   a test deliberately leaves something it needs after exit?
4. What prevents an unchanged, unfixed suite from being reported as fixed — is acceptance check A1's red
   control (before) and its "after" condition sufficient, and is the 227-test count a good vacuity guard?
5. Is anything missing, over-built, or mis-scoped? Is the PRS rating `45/45/50/85` and its rationale
   grounded?

Cite `file:line` for every claim. Write your verdict and set STATUS to Approved if it passes.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). In a manual relay, end each turn by committing just this file; no push. In a driven turn the harness commits.

## Log

### Reviewer · Round 1

**What this proposes**

Give the gh436 Python entry point a fresh temporary directory before it imports the production module or the three phase modules. Set `TMPDIR`, reset Python's cached temp directory, and remove the exact created directory at normal process exit. The planned proof compares an unpatched and patched run inside a sealed parent directory, then checks the existing gate wrapper.

**How the existing system works, per this document**

The gh436 shell wrapper launches the Python suite, which collects the three phase modules. Fixture landings and checks use the inherited Python temp root, and landing cleanup enumerates that root through production pruning. The plan reports 227 passing tests alongside 41 leaked merge scratch folders and one real pruning pass in the sealed replay (plan lines 27–52).

**What it's not**

The plan leaves production pruning and standalone phase-module entry points outside its scope (plan lines 78–80).

swept file: yes

VERDICT: FAIL  
Basis: The one-file isolation design is sound at plan level. A1 currently cannot pass as written, and its log predicate cannot establish where pruning enumerated. The findings below cover the existing plan as a whole.

- [Blocker] A1 counts its own sentinels as leaks. **Observed input:** The inputs named in `PROJECT/2-WORKING/GH-1625-SUITE-TEMP-ISOLATION.md:48` match the zero-count pattern at line 91 and must still exist at line 92. Read-only probe, exit 1: `python3 -c 'from pathlib import Path; names = [f"merge-cleanup-plant{i:03}" for i in range(1, 6)]; hits = [n for n in names if Path(n).match("merge-cleanup-*")]; assert len(hits) == 0, f"expected 0 matches with plants preserved, got {len(hits)}" '` → `AssertionError: expected 0 matches with plants preserved, got 5`. **Affected scope:** Sealed A1 parents seeded with those five directories. **Falsifier:** With only the five unchanged planted trees, the leak check should pass. Adding one extra `merge-cleanup-*` or `merge-check-*` directory, deleting or changing a planted tree, or leaving the run directory behind should fail. Snapshot the planted names and contents before each run, count newly created matching siblings, and check the planted trees and suite-root removal independently.
- [Should] Observe the directory enumerated by pruning in A1. **Observed input:** Plan lines 88–93 use a log naming the parent as the distinguishing predicate. `skills/2-daily/merge-cleanup/scripts/merge_cleanup.py:391-411` calculates the keep limit, may skip on the process probe, and lists the resolved temp root at line 406. It only emits the normal root-bearing message at lines 427–429 when `pruned or kept` is truthy. With five plants and `MERGE_CLEANUP_KEEP_WORKDIRS=5`, a pass can enumerate the parent and leave all plants intact with no root-bearing log. The plan itself reports 66 skipped calls at line 43. **Affected scope:** A1 red runs on an ambient machine and after-runs in which allocations move but pruning still enumerates the inherited parent. **Falsifier:** An observed enumeration of the exact resolved parent must make the after check fail even when no pruning line appears, and an empty trace must fail verification. In the disposable clone, make at least one prune pass deterministic for A1 and record the actual enumeration root with a temporary manual probe. Expect the parent before and the isolated suite child after, and retain the ordinary direct-run checks and 227-test outcome as independent evidence. Keep the probe out of the shipped suite.
- [Should] Tie the red control to one identified baseline. **Observed input:** The status row cites `086b657ea` (plan line 23), the observed problem heading cites `7f2f1cce5` (line 25), and the acceptance section calls the baseline “the unpatched base” (line 89). **Affected scope:** Anyone reproducing or comparing the reported 227 tests, 41 leaks, and pruning output. **Falsifier:** A receipt tying the cited command, exit status, and decisive output to one exact revision, or distinct labeled receipts if both were run. Resolve the two references and identify which evidence belongs to each.
- [Nit] Tighten two factual statements while revising A1. Plan line 50 attributes retention to the plants having no removable clone. `merge_cleanup.py:310-330,339-347` in the production path allows removal of a tool-shaped directory with no Git metadata when the handle check returns verified idle. Report the observed reason if the transcript has it, or report only that the five survived. Plan line 100 says the suite “never touches” the inherited temp directory, while lines 68–70 deliberately create the suite directory there. State the requirement in terms of no leaked fixture siblings and no pruning of the inherited parent.
- [Pass] The registered gate is `validate.sh:96` → `test/gh436-merge-cleanup.sh:8-11` → `test/gh436-merge-cleanup.py:1382-1384`. `test/ci-route.sh:239-245` pins its exclusion from Small. The Python direct run also reaches `unittest.main()` at `test/gh436-merge-cleanup.py:1592-1593`. I found no earlier temp-root override in the four modules. Representative allocations are at `test/gh436-merge-cleanup.py:125`, `test/gh534_phase_a_tests.py:97-111`, `test/gh534_phase_b_tests.py:175-203`, and `test/gh534_phase_c_tests.py:95-105`.
- [Pass] Set the new root before the first local import at `test/gh436-merge-cleanup.py:24`, which also precedes the production import at line 39 and phase collection at lines 1382–1384. `skills/2-daily/merge-cleanup/scripts/merge_cleanup.py:3097,1961-1972,2025,2545,400-406,432-445` ties both allocation prefixes and pruning to Python's default temp lookup. Phase A's `DEFAULT_SAFE_ROOTS` is a static list (`skills/2-daily/merge-cleanup/scripts/scan_clones.py:22-31`), widened at fixture setup with the actual fixture root (`test/gh534_phase_a_tests.py:97-106,532-546`). Phase A's tick and open-handle calls preserve the environment (`test/gh534_phase_a_tests.py:303-306`, `skills/2-daily/merge-cleanup/scripts/scan_clones.py:325-329,444-449`). The child Python paths inherit or copy it, including the Phase B temp-allocating stub and Phase C's explicitly supplied envs (`test/gh534_phase_b_tests.py:40-42,142-159,397`; `test/gh534_phase_c_tests.py:43-47,69-85,95-99,190-193,405-406,884-887,950`). I found no explicit child env that discards `TMPDIR` on these paths.
- [Pass] The plan's exact-path/prefix/parent guard at lines 72–74 is proportionate for normal exit. Capture the absolute created path and original parent at setup, and apply the guard to that target at cleanup. The in-suite retained clone checks consume their outputs before exit (`test/gh436-merge-cleanup.py:1101-1112`; `test/gh534_phase_b_tests.py:392-401`), and the GH-1140 helper dirs reported at plan line 43 are test-owned (`test/gh436-merge-cleanup.py:1474-1498`). I found no post-exit consumer in the reviewed suite paths. The 227 count is a useful collection floor when tied to a green suite result and matching baseline (plan lines 43, 93; `test/gh436-merge-cleanup.py:1379-1384,1592-1593`). The 45/45/50/85 rating matches `releases.sql:1062`; the scope and rating rationale at plan lines 65–84 and 108–114 are proportionate to the reported clutter, possible pruning, and small implementation surface.

[Unverified — needs clone run] The reported base runs and the proposed after-run were not replayed in this worktree. The nearest graph index covers a separate checkout, so citations use the relay worktree's source lines.

Handing off to Producer (claude-a) to correct A1 and reconcile the baseline evidence.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
