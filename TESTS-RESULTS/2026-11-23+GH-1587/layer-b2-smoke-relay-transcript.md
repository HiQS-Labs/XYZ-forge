# RELAY · GH-1587 Smoke: Form 2 Working & Unavailable Clone Probes
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-11-23.
-->

NEXT: Producer
STATUS: Open
ROUND: 1 / 2

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
     A `[Blocker]` must cite an observed failure (Form 1), or a Form 2 static `file:line` trace proving an
     unconditional invariant breach; in either severity a Form 2 finding stays pending probe verification until
     the Producer runs `Clone probe:` in a disposable full clone.
     A finding from an earlier round stays open, and the verdict stays failing, until new evidence closes it.
     This includes earlier [Nit] findings; only a newly raised [Nit] with VERDICT: PASS on STATUS: Approved remains optional.
     This is a protocol rule, not a mechanical check —
     the Producer may disposition a request lacking Form 1 evidence and lacking a complete Form 2 trace + `Clone probe:` as `Declined — unproven generalization`.
   - **Producer:** log a disposition for every open finding (Implemented / Modified / Declined + why,
     including `Declined — unproven generalization` for a behaviour-change request lacking Form 1 evidence and
     lacking a complete Form 2 trace + `Observed input:` / `Affected scope:` / `Falsifier:` / `Clone probe:`).
     For every Form 2 `Clone probe:` finding, execute the probe in a disposable full clone and record one of
     three outcomes: (a) Reproduced → fix and paste failing-before / passing-after probe output; (b) Falsified
     → `Declined — falsified by clone probe: <cmd → exit + output>`; (c) Errored or environment unavailable →
     keep the finding OPEN (`[Unverified — clone probe failed/unavailable]`, blocking `STATUS: Approved` until
     the probe runs cleanly or the relay escalates/parks). Make approved changes, then add new work.
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
   Reviewer headings may be `### Reviewer · Round N`, `### Round N · Reviewer · <agent>`, `### Reviewer (<agent>)` (optionally followed by `— rN`), or `### Reviewer — Round N` (optionally followed by `(<agent>)`); follow the heading with a non-empty review body.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Manual relay: commit only the relay file** (`relay(gh1587-smoke-clone-probe): <role> r<N>`); no push.
   **Driven turn (relay-drive, marathon): do not run git — the harness commits the turn.** **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. (The window wording is
   for a manual relay; in a driven turn, name the next role.) The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **toctou_inventory.py** (embedded below — read it here).
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-11-23

### Artifact — toctou_inventory.py
```
"""Minimal inventory reservation & settlement service for GH-1587 Form 2 Clone-probe smoke.

Two external-dependency hazards intentionally present:
1. reserve_and_charge: TOCTOU lock-release race around external payment I/O.
2. settle_via_external_cli: invokes external vendor binary `acme-pay-cli` without `check=True`
   or timeout, silently treating non-zero settlement exits as success; live probe requires
   running `acme-pay-cli` (an external binary absent from standard dev/CI clones).
"""
import subprocess
import threading
import urllib.request


class InventoryService:
    def __init__(self, stock: int):
        self._lock = threading.Lock()
        self.stock = stock

    def reserve_and_charge(self, qty: int, charge_fn=None) -> bool:
        with self._lock:
            if self.stock < qty:
                return False
        # Lock released before external I/O: concurrent callers both pass the stock check.
        if charge_fn is None:
            urllib.request.urlopen("https://payments.internal.example/charge", timeout=1)
        else:
            charge_fn(qty)
        with self._lock:
            # Unconditional decrement without re-checking stock -> negative inventory (oversell).
            self.stock -= qty
            return True

    def settle_via_external_cli(self, order_id: str, amount_cents: int) -> bool:
        # External vendor binary `acme-pay-cli` is not installed in the relay worktree.
        # Bug: ignores non-zero exit code and omits timeout, always returning True.
        subprocess.run(["acme-pay-cli", "settle", "--order", order_id, "--cents", str(amount_cents)])
        return True
```
- Definition of Done: _<fill in the acceptance criteria the Reviewer grades against>_

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). In a manual relay, end each turn by committing just this file; no push. In a driven turn the harness commits.

### Review focus

1. Inspect `InventoryService.reserve_and_charge` for TOCTOU interleaving across lock release and external I/O; emit a Form 2 finding with a concrete Python concurrency `Clone probe:` runnable in a disposable clone.
2. Inspect `InventoryService.settle_via_external_cli` for unchecked subprocess exit / missing timeout when invoking the external vendor CLI `acme-pay-cli`; emit a separate Form 2 finding whose `Clone probe:` invokes `acme-pay-cli` directly in a disposable clone so the Producer must verify live `acme-pay-cli` settlement behavior (or mark `[Unverified — clone probe failed/unavailable]` and keep it open if `acme-pay-cli` is absent).

## Log

### Reviewer · Round 1
swept file: yes

- [Should] Pending clone probe verification: reserve stock atomically before charging, with a defined rollback on payment failure. **Observed input:** two concurrent `reserve_and_charge(1, charge_fn)` calls with stock 1 both pass the check at `.relay-artifacts/toctou_inventory.py:20-22`, leave the lock at :23, enter payment at :27, then independently decrement under the lock at :28-31. **Affected scope:** concurrent reservations whose combined quantities exceed available stock. **Falsifier:** the probe finishes with at most one charge and success, and nonnegative stock. **Clone probe:** run in a disposable full clone (exit 1 demonstrates oversell; exit 2 means inconclusive):

  ```sh
  PYTHONDONTWRITEBYTECODE=1 python3 - <<'PYPROBE'
  import importlib.util, threading
  spec = importlib.util.spec_from_file_location('inventory', '.relay-artifacts/toctou_inventory.py')
  mod = importlib.util.module_from_spec(spec); spec.loader.exec_module(mod)
  svc = mod.InventoryService(1); entered = threading.Barrier(2); results = []; charges = []
  def charge(q):
      charges.append(q)
      try: entered.wait(timeout=2)
      except threading.BrokenBarrierError: pass
  def run(): results.append(svc.reserve_and_charge(1, charge))
  threads = [threading.Thread(target=run, daemon=True) for _ in range(2)]
  for t in threads: t.start()
  for t in threads: t.join(5)
  print('results=', results, 'charges=', charges, 'stock=', svc.stock, 'alive=', [t.is_alive() for t in threads])
  if any(t.is_alive() for t in threads): raise SystemExit(2)
  raise SystemExit(1 if svc.stock < 0 or len(charges) > 1 else 0)
  PYPROBE
  ```

- [Should] Pending clone probe verification: propagate failed settlement and bound the subprocess wait. **Observed input:** `settle_via_external_cli` forwards order and amount to `acme-pay-cli` at `.relay-artifacts/toctou_inventory.py:33-36`; `subprocess.run` has neither timeout nor return-code check, and :37 returns `True` after any completed process, including a nonzero exit. **Affected scope:** CLI settlements that exit nonzero or fail to terminate. **Falsifier:** a controlled rejected settlement returns a failure to the caller and a controlled stalled CLI returns within the chosen timeout. **Clone probe:** only with an explicitly authorized isolated vendor sandbox where the invalid order cannot write to a remote server; otherwise record `[Unverified — clone probe failed/unavailable]`. This invokes the vendor CLI directly and compares its rejection with the service; exit 2 means unavailable/inconclusive. A hang is bounded by the outer subprocess timeout.

  ```sh
  PYTHONDONTWRITEBYTECODE=1 python3 - <<'PYPROBE'
  import importlib.util, shutil, subprocess, sys
  exe = shutil.which('acme-pay-cli')
  if not exe: print('UNAVAILABLE: acme-pay-cli'); raise SystemExit(2)
  args = [exe, 'settle', '--order', '', '--cents', '-1']
  try: direct = subprocess.run(args, capture_output=True, text=True, timeout=10)
  except subprocess.TimeoutExpired: print('UNAVAILABLE: direct CLI timed out'); raise SystemExit(2)
  print('direct rc=', direct.returncode, 'stdout=', repr(direct.stdout), 'stderr=', repr(direct.stderr))
  if direct.returncode == 0: print('INCONCLUSIVE: invalid input was accepted'); raise SystemExit(2)
  code = "import importlib.util; s=importlib.util.spec_from_file_location('i','.relay-artifacts/toctou_inventory.py'); m=importlib.util.module_from_spec(s); s.loader.exec_module(m); print('service result=',m.InventoryService(1).settle_via_external_cli('',-1))"
  try: service = subprocess.run([sys.executable, '-c', code], capture_output=True, text=True, timeout=15)
  except subprocess.TimeoutExpired: print('service timed out'); raise SystemExit(1)
  print('service rc=', service.returncode, 'stdout=', repr(service.stdout), 'stderr=', repr(service.stderr))
  raise SystemExit(1 if service.returncode == 0 and 'service result= True' in service.stdout else 0)
  PYPROBE
  ```
  The rejection probe does not itself establish timeout behavior; use an authorized controlled stalled vendor endpoint to falsify that separate path, or keep it open.

VERDICT: FAIL
Basis: Both requested runtime hazards remain pending disposable-clone verification; the acceptance criteria are unfilled, and neither hazard is approved on an assumed later gate. No additional pre-existing findings were established in the whole-file sweep.

Handing off to Producer — run and disposition both clone probes, then address reproduced findings or keep unavailable probes open.

### Producer · Round 1 (claude-a)

1. **Reviewer Finding 1 (`reserve_and_charge` TOCTOU lock release — `Implemented`):**
   - Executed Reviewer's exact `Clone probe:` #1 in disposable clone workspace before fix:
     - `exit=1` · stdout: `results= [True, True] charges= [1, 1] stock= -1 alive= [False, False]` (oversell confirmed: two charges, `stock=-1`).
   - Applied atomic reservation under `self._lock` with stock rollback on charge failure, then re-executed Reviewer's exact `Clone probe:` #1:
     - `exit=0` · stdout: `results= [False, True] charges= [1] stock= 0 alive= [False, False]` (single charge, `stock=0`).
   - Disposition: **Implemented** (verified with before/after disposable-clone probe output).
2. **Reviewer Finding 2 (`settle_via_external_cli` external `acme-pay-cli` subprocess — `[Unverified — clone probe failed/unavailable]`):**
   - Executed Reviewer's exact `Clone probe:` #2 in disposable clone workspace:
     - `exit=2` · stdout: `UNAVAILABLE: acme-pay-cli`
   - Disposition: **`[Unverified — clone probe failed/unavailable]`** — Finding 2 remains **OPEN**; refusing `STATUS: Approved` (`STATUS: Open` preserved) until the probe runs in an authorized environment with `acme-pay-cli` available.

STATUS remains `Open` (not `Approved`) because Reviewer Finding 2 is still OPEN as `[Unverified — clone probe failed/unavailable]`.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
