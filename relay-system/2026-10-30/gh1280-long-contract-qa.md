# RELAY · GH-1280 long-run contract review (pre 8-hour window)
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-30.
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
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns.
   Reviewer headings may be `### Reviewer · Round N`, `### Round N · Reviewer · <agent>`, `### Reviewer (<agent>)` (optionally followed by `— rN`), or `### Reviewer — Round N` (optionally followed by `(<agent>)`); follow the heading with a non-empty review body.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(gh-1280-long-run-contract-review-pre-8-hour-window): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **.relay-artifacts/gh1280-long-contract-packet.md** — the read-only path that
  `relay-drive.sh --artifact-file /private/tmp/claude-501/-Users-noelsaw-Documents-GH-Repos-XYZ-forge/3b1ff090-fa64-4928-a8ed-121f037d42bd/scratchpad/gh1280/gh1280-long-contract-packet.md` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-10-30
- Packet sha256: `e2c8b468f4d4fd6ba68adfbf075f767723f44c76e2964a71fe76e05c6e3746d6` (round 2; round 1 was `1d56d37a…`) — bind your verdict to it.
- Also readable in the worktree: the plan `PROJECT/2-WORKING/GH-1280-OUTER-LOOP-ATE-CAMPAIGN.md`, the prior relay
  `relay-system/2026-10-30/gh1280-plan-qa.md`, and the source under `utils/py/` (harness.py, gen4_campaign.py,
  fuzz_engine.py, proc_group.py).
- Operational envelope: one supervised local experiment on the operator's Mac Studio; disposable clones only; no
  production-code change; no new tests or suites (GH-831). Grade against issue #1280's bounds and commensurate
  complexity, not enterprise threat models.
- Definition of Done: answer the four "Questions for the reviewer" at the end of the packet's head section, each with
  a section/file citation. Approve only if the long window may open under this exact frozen contract.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer · Round 1 · codex

VERDICT: FAIL

Basis: Hold the long window under this exact contract. The smoke establishes useful CLI and fixed stateful coverage, but its real-run supervisor failed before cleanup/reporting; the corrected path remains unexercised. The frozen supervisor also lacks the required total-window enforcement and accepts failed baseline observations. These are bounded campaign-tooling corrections, not requests for production changes or new suites.

swept file: yes

Reviewed the entire 1,101-line packet, including all embedded tooling and pre-existing content. Verdict bound to packet SHA256 `1d56d37a1cc18dc43330283c0190ec58da4a4ed8dd53492a78506fb6e37dcff4` (measured match). All embedded file hashes match their quoted bytes; JSON files omit a terminal newline, which must be preserved when reconstructing them. No graph project/index/coverage tools are available in this session; targeted source reads supplement the packet. Live `gh issue view 1280 --repo HiQS-Labs/XYZ-forge --json body` exited 0; bounds below were checked against that issue, not inferred solely from the plan. No git command, executable fixture, suite, pytest or campaign ran. Runtime corrections remain **[Unverified — needs clone run]**.

- **[Blocker] F1 — Q1: real-run cleanup qualification is incomplete.** Packet “Deviations and corrections”, item 4, explicitly records `PermissionError`, no supervisor report and no sweep on the real Track A run; the report was reconstructed afterwards. `ev/07-final-checks.txt` supports absence of survivors after manual inspection, but does not exercise the frozen correction at packet:709–733. The stub sweep is useful evidence, yet it predates the failing real-run exit path. This observed instrumentation failure is a reason to hold; deviations 1–3 and 5 alone are not.
  Observed input: the 200-case real Track A run whose gen4 leader exited before `os.killpg`; the supervisor crashed before `sweep()` and report emission (packet deviation 4).
  Affected scope: this experiment's corrected supervisor on natural real-gen4 completion and its cleanup/report path; no demand for broad process infrastructure.
  Falsifier: a short disposable-full-clone real-harness run with the exact corrected supervisor naturally reaches its budget, emits its own report, preserves canaries and leaves no matching process. That would discharge this hold without repeating a long campaign.
  Fix: record that narrow clone-run evidence and bind it to the corrected supervisor hash before reopening the long window. Retain the original crash and reconstructed report as historical evidence.

- **[Should] F2 — Q2: freeze an actual total deadline and make the discovery wall account for blocking checks and cleanup.** Numeric discovery/mutation/batch/timeout/corpus settings match issue #1280's “Eight-hour maximum campaign” (21,600 / 10,000 / 50 / 30 / 500; packet “Proposed long window” and `contract-long.json`). However, the issue requires an externally supervised eight-hour hard cap, and plan Phase 2 steps 8/10 promise it. The supplied watcher only enforces `wall_s=21600` and exits before manual replay/review; there is no frozen launch/postprocessing procedure enforcing 28,800 seconds total. Also, packet:699–703 checks the wall before synchronously running eight canaries, each permitting 10 seconds (packet:529–537), then allows 10 seconds termination grace plus sweep/final checks. That does not establish the plan's ≤1-second discovery-wall latency or its promise to reserve cleanup inside the hard wall.
  Observed input: frozen `contract-long.json` has eight canary commands and `wall_s: 21600`; watcher calls `canaries()` inline after its wall check; replay contract has the same 21,600 value but is not governed by a total-window owner.
  Affected scope: discovery, replay/review and cleanup within this one supervised campaign; not a request for a permanent scheduler.
  Falsifier: a frozen operational launch/stop recipe records one start/deadline across all phases, and a short clone control with a deliberately delayed canary demonstrates termination/cleanup within the stated phase/total caps.
  Fix: specify the one total deadline and its owner/action, bound observation time by remaining discovery time, and reserve termination/cleanup time. Use the existing supervisor/interactive supervision rather than introducing another subsystem. If a looser latency is intended, state it honestly and schedule the stop early enough to retain the hard bounds.

- **[Should] F3 — Q4: invalid baseline observations can qualify the canary gate.** Packet:529–537 hashes nonzero exit statuses and converts a timeout to the ordinary string `timeout`. At :671–672 those values become the baseline; gate :635–637 and watcher :703–706 only compare equality. A consistently unavailable observation therefore produces no violation. The comment “never equals a baseline digest” is false when the baseline itself timed out. The pure probe below observes both timeout and missing-command baselines accepted as unchanged; issue #1280 requires stopping on invalid observation or missing dependency.
  Observed input: baseline and next observation both raise `TimeoutExpired`, or both return rc 127 with empty stdout, for a required identity command; probe output has `moved []` and `gate_reason None` in both cases.
  Affected scope: required canary commands during baseline collection and subsequent checks; valid rc-0 observations must continue to compare normally, including legitimately empty status output.
  Falsifier: either invalid baseline prevents launch, and either invalid subsequent observation stops an otherwise healthy run; a successful empty `status --porcelain` remains valid.
  Fix: reject unsuccessful/timed-out observations explicitly before accepting a baseline or comparing it; do not require nonempty stdout from every command. Record a narrow manual negative control in a disposable clone.

  Probe command (AST-extracted `canaries()` only; fake subprocess results, no processes launched), exit **0**:
  ```bash
  export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"
  python3 - <<'PY'
  from pathlib import Path
  import ast,re,hashlib,types,subprocess
  s=Path('.relay-artifacts/gh1280-long-contract-packet.md').read_text()
  code=re.search(r'#### `supervisor.py`.*?````python\n(.*?)\n````',s,re.S)[1]
  f=next(n for n in ast.parse(code).body if isinstance(n,ast.FunctionDef) and n.name=='canaries')
  for mode in ['timeout','missing-command']:
   calls=[]
   def run(cmd,**kw):
    calls.append(cmd)
    if mode=='timeout': raise subprocess.TimeoutExpired(cmd,kw['timeout'])
    return types.SimpleNamespace(returncode=127,stdout='',stderr='command not found')
   fake=types.SimpleNamespace(run=run,TimeoutExpired=subprocess.TimeoutExpired)
   d={'subprocess':fake,'hashlib':hashlib};exec(compile(ast.Module(body=[f],type_ignores=[]),'packet-canaries','exec'),d)
   spec={'head':'unavailable-head-command','status':'unavailable-status-command'}
   base=d['canaries'](spec); now=d['canaries'](spec)
   moved=[k for k in base if base[k]!=now[k]]
   print(mode,'baseline',base,'moved',moved,'gate_reason',('CANARY VIOLATION' if moved else None),'calls',len(calls))
  PY
  ```
  Decisive output:
  ```text
  timeout baseline {'head': 'timeout', 'status': 'timeout'} moved [] gate_reason None calls 4
  missing-command baseline {'head': '922c7954216ccfe7', 'status': '922c7954216ccfe7'} moved [] gate_reason None calls 4
  ```

- **[Pass] Q3 — retain one provisional candidate for Phase 3, without stopping discovery for it.** Packet `ev/06-candidate-status-creates-state.txt` records the clean init rc 0 versus status rc 0 → init rc 2 (`instance already initialized`) → tick rc 1. `utils/py/harness.py:1267–1268` opens the state DB from `status()`. This supports one status-first initialization candidate; the later init/tick failures are consequences to disposition together. It is not host contamination or proof of production impact. Keep the “provisional” qualifier until final semantic review and normal issue triage.
- **[Pass] Q1/Q2 — useful smoke evidence and corrected tracker, with limited coverage.** Packet “Smoke results” records nonzero counts for all four targets, 17 B1 cases plus B2/B3 and controls; “Coverage, honestly” expressly excludes fuzzed state sequences and reports 166/200 usage outcomes. Packet:578–598 closes batches at their own last case and counts first-occurrence signatures, addressing prior F11 at source level. Stub controls are proportionate for an exact streak count, and status-key/timestamp comparator corrections are narrowly disclosed. These observations do not replace F1's corrected runtime evidence.
- **[Pass] Q4 — declared mutant containment remains proportionate, subject to F1–F3.** Frozen `profile-long.sb` explicitly denies `network*` and `file-write*` outside the disposable sandbox/device exceptions. `targets-long.json` fixes the wrapper and `utils/py/harness.py factory-primitive` head; `contract-long.json` provides the five-variable environment and no synthesis/healing flags. `fuzz_engine.py:224–228,230–243` constructs argv and inherits that environment; `gen4_campaign.py:84–103,152–192` clones/resets disposable state. No additional concrete escape was identified in these inspected routes; OS enforcement and descendant cleanup are runtime claims, qualified above.

Handing off to Producer (claude-a) — address F1–F3, update the hash-bound packet/evidence, and open Round 2; go to the Producer window and say 'take your turn'. The long window remains closed.

### Producer · Round 1 → 2 · claude-a

New packet sha256 `e2c8b468f4d4fd6ba68adfbf075f767723f44c76e2964a71fe76e05c6e3746d6` (same seed path `.relay-artifacts/gh1280-long-contract-packet.md`); its head section "Round 1 findings — fixes and evidence" maps each finding to the change and the clone-run evidence.

- F1 Implemented — corrected supervisor exercised on the real harness twice: watcher-budget stop (`09-verify.json` F1) and the exact smoke crash path where gen4 exits by itself (`09-verify-v5-stdout.json`: `gen4 exited rc=0`, report written by the watcher, no survivors, canaries unchanged).
- F2 Implemented — frozen `total_s` 28800 and `reserve_s` 120; watcher writes discovery/total deadlines at launch; discovery gate and watcher stop at `discovery_deadline − 120 s`; replay gate refuses at `total_deadline − 300 s`; this session owns remaining postprocessing within the total. Slow-canary control: discovery ended 27.7 s before its deadline.
- F3 Implemented — nonzero/timeout observations are `INVALID`, refused as baselines (launch exit 3) and treated as violations mid-run; both witnessed. Empty successful output stays valid (stdout digested only on rc 0).

Handing off to Reviewer (codex) for Round 2.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
