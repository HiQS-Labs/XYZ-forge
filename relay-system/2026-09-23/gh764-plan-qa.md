# RELAY · GH-764 plan QA: baseline gate repair
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-09-23.
-->

NEXT: Reviewer
STATUS: Open
ROUND: 2 / 4

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
6. **Commit only the relay file** (`relay(gh764-plan-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: PROJECT/2-WORKING/GH-764-BASELINE-GATE-FAILURES.md
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-09-23
- Operational envelope: macOS local gate repair across three existing focused suites. This is one issue, with a small connector handoff change, a WAL test-fixture repair, and an ATE dependency/preflight repair. Keep machinery and test footprint commensurate; do not demand new subsystems or speculative policy.
- Definition of Done: review the plan against the actual source in `test/gh142-ate-exit-contract.sh`, `utils/ate/scripts/run_variations.py`, `utils/ate/install.sh`, `test/test_gh605_work_state.py`, `utils/py/releases_app.py`, `utils/py/work_connectors/__init__.py`, and `test/gh549-work-events.sh`. Answer specifically:
  1. Does the GH-142 evidence prove missing `requests` is the cause, and does the plan prevent the false-positive exit-code assertion without changing production ATE behavior?
  2. Does GH-605's proposed fixture setup create WAL-header/no-sidecar input without weakening the reader's refusal?
  3. Is clearing the closed `Popen.stdin` handle after payload write the smallest safe way to preserve concurrent connector launch and shared deadline on Python 3.9? Identify a concrete counterexample if not.
  4. Are the accepted scope, rating, rollback, red controls and gate evidence sufficient? Does the plan miss a caller or failure class?
  Give graded findings with file:line citations, `VERDICT: PASS` or `FAIL`, and `Basis:`. Approve only if implementation is ready to start.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer · Round 1

swept file: yes

- [Pass] The GH-142 exit-code assertion can pass on an import error, but the following child-failure assertion catches it (`test/gh142-ate-exit-contract.sh:107-114`). `run_variations.py` imports both modules before `main()` or filing (`utils/ate/scripts/run_variations.py:44-45`, `utils/ate/scripts/run_variations.py:563-573`). A same-interpreter dependency preflight in the test is a bounded fix; production ATE behavior need not change (`PROJECT/2-WORKING/GH-764-BASELINE-GATE-FAILURES.md:78`).
- [Should] Make the ATE preflight and negative control cover **both** imports, and state the cause as missing ATE dependencies rather than `requests` alone. The current Python 3.9 interpreter lacks both; installing only `requests` would expose the next import failure. `validate.sh` announces missing `yaml` but does not preflight `requests` (`validate.sh:1033-1037`). Fix Phase 1's “with and without requests” criterion to test missing `yaml` independently, then the complete pinned environment (`PROJECT/2-WORKING/GH-764-BASELINE-GATE-FAILURES.md:58-59`, `PROJECT/2-WORKING/GH-764-BASELINE-GATE-FAILURES.md:78`).
  Observed input: `python3 -c 'import importlib.util; print("requests",bool(importlib.util.find_spec("requests"))); print("yaml",bool(importlib.util.find_spec("yaml"))); print("pytest",bool(importlib.util.find_spec("pytest")))'` exited 0 with `requests False`, `yaml False`, `pytest False`; imports are at `utils/ate/scripts/run_variations.py:44-45`.
  Affected scope: GH-142 runs whose interpreter lacks either `requests` or `yaml`; each must report a named prerequisite failure before the filing exit assertion.
  Falsifier: run with `requests` installed and `yaml` absent; if the existing suite already reports `yaml` as a prerequisite rather than a filing failure, the added YAML control is unnecessary.
- [Pass] The proposed WAL fixture edit targets the precondition after the connection is closed and checkpointed (`test/test_gh605_work_state.py:216-233`). The reader checks the WAL header before any SQLite open and refuses it (`utils/py/releases_app.py:5215-5223`, `utils/py/releases_app.py:5266-5287`); the existing test then asserts refusal, unchanged DB bytes, and absent sidecars (`test/test_gh605_work_state.py:233-238`). No reader relaxation is needed.
- [Pass] Clearing the closed `Popen.stdin` handle after a successful payload write is the smallest fix for the observed `communicate()` error (`utils/py/work_connectors/__init__.py:195-227`). On Python 3.9, `python3 -c 'import subprocess,sys; p=subprocess.Popen([sys.executable,"-c","import sys; print(len(sys.stdin.read()))"],stdin=subprocess.PIPE,stdout=subprocess.PIPE,stderr=subprocess.PIPE,text=True); p.stdin.write("abc"); p.stdin.close(); p.stdin=None; out,err=p.communicate(timeout=2); print(p.returncode,repr(out),repr(err))'` exited 0 with `0 '3\\n' ''`. The GH-549 suite has separate concurrent-launch, one-window, and cursor red controls (`test/gh549-work-events.sh:358-384`, `test/gh549-work-events.sh:400-422`, `test/gh549-work-events.sh:559-585`).
- [Should] Account for a separate, observed connector deadline failure class before claiming the shared window is preserved without qualification. `_launch` synchronously writes the whole JSON payload before the next connector launches (`utils/py/work_connectors/__init__.py:181-207`, `utils/py/work_connectors/__init__.py:440-442`); the deadline starts only after all launches. The event reader allows 500 rows with no byte cap (`utils/py/work_connectors/__init__.py:127-138`). Bound that write within the connector window, or explicitly document this existing limit and its follow-up while keeping GH-764's code change narrow.
  Observed input: `python3 -c 'import subprocess,sys,time; p=subprocess.Popen([sys.executable,"-c","import sys,time; time.sleep(2); sys.stdin.read()"],stdin=subprocess.PIPE,stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL,text=True); t=time.monotonic(); p.stdin.write("x"*1048576); p.stdin.close(); print("write_elapsed",round(time.monotonic()-t,1)); p.wait()'` exited 0 with `write_elapsed 2.0`.
  Affected scope: a configured child that delays or never reads stdin when its serialized event batch exceeds pipe capacity; the host waits before the shared deadline begins and later connectors launch.
  Falsifier: an actual `dispatch(window_s=1)` with a 1 MiB batch and a child that waits 2 seconds before reading still launches the next connector and returns within the one-second window; an immediate-reading child must continue to advance.
- [Should] Reconcile the plan's `risk: 2` with its own **Costly** connector classification (`PROJECT/2-WORKING/GH-764-BASELINE-GATE-FAILURES.md:11`, `PROJECT/2-WORKING/GH-764-BASELINE-GATE-FAILURES.md:69`); PDDA maps Costly to risk 3 (`PROJECT/PDDA.md:131-132`). The two-phase doc also needs a phase table of contents and an explicit Phase 0 QA gate (`PROJECT/PDDA.md:63-65`). The rollback path and final disposable-clone gate are otherwise concrete (`PROJECT/2-WORKING/GH-764-BASELINE-GATE-FAILURES.md:69`, `PROJECT/2-WORKING/GH-764-BASELINE-GATE-FAILURES.md:76-81`). Full suite and red-control outcomes remain [Unverified — needs clone run] after implementation.

VERDICT: FAIL
Basis: The three baseline diagnoses support bounded fixes, but the plan needs a two-dependency ATE control, an honest disposition of the measured pre-deadline stdin stall, and a consistent risk/phase contract before implementation starts.

Handing off to Producer — go to the Producer window and say “take your turn”.

### Producer · Round 1 disposition

- **Implemented — ATE dependencies:** Phase 1 now requires separate negative controls for missing `requests` and missing `yaml`, plus the fully provisioned run. The Phase 0 ledger names both imports.
- **Modified — connector deadline:** The measured pre-deadline write stall is real but is a separate failure class from #764's closed-handle error. The plan states its limit explicitly and records a sourced root `PARKED/` note for triage, without claiming that the narrow fix repairs it.
- **Implemented — PDDA metadata:** risk is 3 for a Costly shared connector path; the two-phase plan now has a table of contents and an explicit Phase 0 QA gate.

The implementation remains unchanged pending this second plan review. Please recheck the corrected plan and either approve or cite a remaining concrete blocker. Handing off to Reviewer — take your turn.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
