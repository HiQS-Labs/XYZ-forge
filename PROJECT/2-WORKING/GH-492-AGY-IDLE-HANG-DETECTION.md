---
gh_issue: 492
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/492
title: "GH-492 — agy hangs headless with no CPU and no progress, and its only pre-flight warning fires on every turn"
status: "2-WORKING — captured 2026-08-10 for release 0.3.0 Nightwatch. Claims verified against relay-automation/agy-turn.sh, utils/py/agy-turn.py, utils/py/turn_diagnostics.py, utils/py/rtl.py, and utils/py/consult.py. Awaiting preflight; see the self-modification finding below before firing as a marathon lane."
created: 2026-08-10
updated: 2026-08-10
owner: noel
doc_type: project
release: "0.3.0 Nightwatch"
complexity: 4
risk: 4
effort: 4
phases: 1
ratings_provisional: true
roadmap_exempt: false
related:
  - "#375 (CLOSED) — established the three-state `unverifiable` verdict for `agy whoami`'s TTY error. This issue is explicit that it does not reopen #375; it asks for the replacement signal #375 didn't provide. Verified: rtl.py:39-96 is exactly the #375 code."
  - "#390 — the timeout-attribution sampler (TurnDiagnostics) that correctly diagnosed the 2026-08-10 hang as `timeout-idle-no-progress`. Verified working as designed; this issue is about everything BEFORE the 900s cap expires, not the attribution itself."
  - "#414 — cited by the issue as narrowing the fallback-reviewer option (`--builder pi` rejected). Not independently reverified for this doc; carried through as context only."
non_goals:
  - "Fixing agy itself. It is a third-party CLI; both 2026-08-10 failures were transient/auth-shaped and resolved by an interactive `agy login`, not by a code change here."
  - "Swapping the default reviewer away from agy. The marathon design deliberately keeps builder and reviewer on different models; this lane does not touch that policy."
  - "Reopening #375. Its three-state verdict (pass / unverifiable / failed) is correct and is reused, not replaced."
  - "Depending on a GNU `timeout`/`gtimeout` binary. Verified absent on this host (see The defect) — any implementation must stay inside Python's own process control, as the current code already does."
goal: >
  Give the harness a way to end a hung agy turn well before its wall-clock cap, and stop training
  operators to ignore agy's only pre-flight signal. Verified 2026-08-10: utils/py/agy-turn.py's
  TurnDiagnostics sampler (GH-390) already proves a hang is `cpu=0.02s/s, worktree-progress=no` from
  its very first samples, but nothing acts on that until subprocess.run's own 900s timeout fires
  (utils/py/agy-turn.py:242-254). Separately, utils/py/rtl.py's TTY-based auth verdict (GH-375) prints
  an identical "could not run headless" WARNING on every single headless agy invocation — verified
  unconditional, because a headless run never has a TTY — so the warning carries zero information
  about any specific run, healthy or hung. Both failures recurred on 2026-08-10 (a ~900s idle hang
  mid-marathon, then an auth-preflight timeout that killed a consult outright); both were resolved by
  an interactive `agy login`, evidence the underlying cause was an expired/absent auth session that no
  headless probe could name as such.
---

# GH-492 · agy can hang headless for its full wall-clock cap with zero early signal, and its one warning is on every run

## Status

| What was just completed | What's next |
|---|---|
| Captured 2026-08-10. Every claim in the issue checked against source: confirmed the 900s cap is wall-clock-only with no early idle kill, confirmed the TTY auth warning is unconditional in headless mode, and additionally confirmed (not requested by the issue text, but by the drafting brief) that `utils/py/consult.py` — the OTHER place agy runs headless, and the surface where the issue's second 2026-08-10 failure actually occurred — has **none** of GH-390's diagnostics at all. | Preflight, but see the self-modification finding under Reversibility & blast radius first: the fix as scoped by criterion 3 necessarily edits `utils/py/rtl.py`, which this repo's own guiding principles name as the turn kernel. This cannot be a marathon lane; it ships as a direct PR. |

**Issue:** https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/492

## The defect

**1. The 900s cap is wall-clock-only; there is no idle-kill.** `utils/py/agy-turn.py:205` reads
`turn_timeout = int(os.environ.get("RELAY_TURN_TIMEOUT_S", 900))`, and the child is run at
`utils/py/agy-turn.py:246` via `subprocess.run(cmd, ..., timeout=turn_timeout, ...)`. That single
`timeout=` argument is the entire enforcement mechanism — Python's `subprocess.run` does not return
control until either the child exits or `turn_timeout` seconds elapse. `TurnDiagnostics` (imported at
`utils/py/agy-turn.py:10`, wrapping the call at `utils/py/agy-turn.py:242-254`) runs a background
sampler thread alongside the child, but its own class (`utils/py/turn_diagnostics.py`) has no method
that terminates the child — only `start()`, `stop()`, and `classify()` (`utils/py/turn_diagnostics.py:248-329`).
`classify()` is called at `utils/py/agy-turn.py:301`, strictly **after** the `except
subprocess.TimeoutExpired` branch has already fired at `utils/py/agy-turn.py:247-248`. So the sampler
that can tell "idle" from "working" from sample one only gets to speak once the full 900s (or whatever
`RELAY_TURN_TIMEOUT_S` is set to) has already elapsed. This matches the issue's claim exactly: the
2026-08-10 hang's own transcript shows `samples=90` at a 10s interval (`DEFAULT_INTERVAL_S = 10.0`,
`utils/py/turn_diagnostics.py:48`) — 900s of sampling, all of it unanimous from the start, none of it
actionable until the end.

**2. No GNU `timeout`/`gtimeout` on this host — verified, and relevant to any fix.** `which timeout
gtimeout` returns "not found" for both on this machine. The current code already avoids this
dependency (it uses Python's own `subprocess.run(timeout=)`), which is the right shape to extend —
any fix sketch that shells out to `timeout(1)` will not run here.

**3. The TTY auth warning fires on every headless run, not selectively.** `utils/py/rtl.py:39-96`
(`agy_auth_output_verdict`) special-cases agy's TTY failure signature
(`AGY_AUTH_TTY_MARKERS = ("could not open tty", "error opening tty")`, `rtl.py:36`) and returns
`("unverifiable", ...)` for it. `utils/py/agy-turn.py:38-48` then prints the WARNING for that verdict.
Verified: `agy whoami` needs an interactive TTY to succeed at all (that is the entire finding of #375),
and a headless automated turn never has one — `stdin=subprocess.DEVNULL` is hardcoded at
`agy-turn.py:22`. So this branch is not occasionally hit, it is the **only** branch a headless run can
take on `agy whoami`, on every invocation, healthy or not. `utils/py/consult.py` carries an identical
copy of the same warning (`consult.py:222-224` and `consult.py:246-249`), so the same is true there.

**4. `utils/py/consult.py` — where the issue's SECOND 2026-08-10 failure happened — has none of GH-390's
attribution at all.** `consult.py` never imports or calls `TurnDiagnostics`; the agy advisor is launched
via `guarded_with_timeout()` (`consult.py:196-204`), a bare `subprocess.Popen` whose only timeout
handling is `proc.wait(timeout=rem)` at `consult.py:448`, caught at `consult.py:486-493` with no
classification — just `"advisor failed or exceeded the {timeout_s}s cap"`. `consult.py`'s own cap is a
**different** default from the relay-turn cap: `timeout_s = int(os.environ.get("CONSULT_TIMEOUT",
300))` at `consult.py:374`. The issue's second dated failure — "an auth pre-flight timeout that killed
a consult outright" — happened in `agy_auth_preflight()` (`consult.py:206`), whose own comment block
(`consult.py:19-25`, dated 2026-08-09, one day before the issue) already documents this exact failure
mode: a timeout whose captured output doesn't carry the TTY marker (because the probe was killed
before it could flush) stays fatal and kills the whole agy seat. `AGY_AUTH_TIMEOUT_DEFAULT_S` was
already raised from 5s to 20s on 2026-08-09 to buy headroom (`rtl.py:19-32`) — and the issue reports
the failure recurring the very next day. **If a fix is implemented only in `agy-turn.py`, the exact
surface where the 2026-08-10 consult failure occurred is untouched.**

**5. Additional, unreported gap found while checking consult's empty-output handling (per the drafting
brief, not the issue text):** `agy-turn.py` explicitly fails a clean-exit-but-empty-output turn
(`agy-turn.py:307-313`, the documented "silent failure under sandbox" gotcha). `consult.py`'s success
path for the agy advisor does **not** carry the same guard: `consult.py:459` only runs the
isolation-breach check when `os.path.getsize(out) > 0`, and the general "was this a good answer" branch
at `consult.py:469` is `elif proc.returncode == 0 and (m != "aider" or aider_answer_ok(out))` — for
`m == "agy"` this reduces to just `proc.returncode == 0`, with no size check at all. An agy consult
lane that exits 0 with an empty transcript (the exact gotcha `agy-turn.sh`'s own header names) is
recorded as `[ok]` today. This is not one of the issue's acceptance criteria and is reported here as
verified context only, not as something the acceptance block covers.

**6. Frozen twins — no Bash-side work needed.** `test/gh308-frozen-twin-guard.sh:14` and `:22` list
`relay-automation/agy-turn.sh:utils/py/agy-turn.py` and `relay-automation/consult.sh:utils/py/consult.py`
as two of the twelve frozen twins. Per GH-308, Python is authoritative and Bash is a frozen historical
fallback (`relay-automation/agy-turn.sh:2-3`, `relay-automation/consult.sh:2-3` both say so explicitly).
Since `XYZ_PYTHON` defaults to `1` (`agy-turn.sh:9`, `consult.sh:9`), the Python files are what actually
executes today. **A correct fix touches only the `.py` sides and does not need a `Frozen-twin-exception:`
trailer**, as long as the `.sh` files are left untouched (they may drift in their comments — e.g.
`agy-turn.sh:52-53` still documents `AGY_AUTH_TIMEOUT_S` default `5`, while the executing Python default
is `20` per `rtl.py:32` — but per GH-308 this is not a defect to fix here).

**7. The kernel-touch finding.** Criterion 3 (the warning fix) can only be satisfied by editing
`utils/py/rtl.py:39-96` and/or `utils/py/rtl.py:99+` (`agy_auth_output_verdict` /
`agy_auth_timeout_verdict`) — that is where the warning text and its trigger condition live, and both
`agy-turn.py` and `consult.py` import it from there (`agy-turn.py:8`, `consult.py:11-12`). This repo's
own drafting convention names `utils/py/rtl.py` as one of the two turn-kernel files whose edits cannot
be contained inside a single marathon phase (the reviewer turn re-sources the kernel the builder just
changed). See Reversibility & blast radius.

## Acceptance

*Copied verbatim from [issue #492](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/492) (`## Acceptance`), fetched 2026-08-10. Deviations, if any, are recorded in the separate block below.*

- [ ] A turn that is idle by the existing criteria — no CPU and no worktree progress — is killed on a **short idle threshold** rather than only at the full wall cap, and the threshold is separately configurable from the wall cap. The 90 samples that reported `cpu=0.02s/s, worktree-progress=no` were unanimous from the start; nothing was learned by waiting for sample 90.
- [ ] The idle kill keeps GH-390's existing attribution text and evidence (`cpu`, `samples`, `worktree-progress`), and remains distinguishable in the transcript from a wall-cap kill and from a runaway kill. Three causes, three verdicts, as today.
- [ ] The unconditional `could not run headless / auth was not verified` warning is **either** replaced by a probe that can actually distinguish healthy from unhealthy, **or** demoted so it is not printed at the same level on every successful turn. A warning that fires on 100% of runs is not evidence about any run, and today it fires identically on three good turns and one hang.
- [ ] If no reliable pre-flight probe for agy exists, that is recorded as the finding rather than papered over with a weaker probe. #375 already established that the obvious probe cannot work; a second unreliable one would be worse than none.
- [ ] A test drives a deliberately idle turn and asserts it is killed at the idle threshold rather than the wall cap, **with a negative control observed**: a turn that is slow but genuinely progressing must **not** be killed. Without that control the change is indistinguishable from making the harness trigger-happy.
- [ ] Whatever ships states plainly that agy hanging is an **external** condition the harness detects and contains, not one it prevents. The observed hang recovered on its own within a minute; nothing here claims to fix agy.

## Acceptance — deviations from the issue

1. **Criterion 1 does not name which entry point it covers, and this matters.** Verified there are two
   independent headless call sites for agy — `utils/py/agy-turn.py` (relay/marathon turns) and
   `utils/py/consult.py` (one-shot consults) — and only the first has any of GH-390's idle-attribution
   machinery today (`consult.py` has zero `TurnDiagnostics` usage, verified by absence of any import).
   The issue's own SECOND 2026-08-10 failure ("an auth pre-flight timeout that killed a consult
   outright") happened on the surface with no attribution at all. If criterion 1 is implemented only
   in `agy-turn.py`, the consult path — where one of the two dated failures actually occurred —
   remains exactly as blind as it is today. Not a contradiction in the issue, but a gap the acceptance
   text leaves open; recommend the builder scope both `agy-turn.py` and `consult.py` explicitly rather
   than treating `agy-turn.py` alone as satisfying criterion 1.
2. **Criterion 3 is unbuildable without touching `utils/py/rtl.py`.** The warning and its trigger
   condition (the TTY-marker match) live in `rtl.py:39-96`/`:99+`, which this repo's drafting
   convention names as one of two turn-kernel files (`relay-turn-lib.sh` is the other). That does not
   make the criterion wrong, but it does mean this lane cannot be executed as a marathon phase — see
   Reversibility & blast radius. Recorded here rather than silently accepted, per the brief's
   instruction to flag self-modification exposure "every time."
3. **No GNU `timeout`/`gtimeout` binary exists on the host this doc was drafted on** (verified: `which
   timeout gtimeout` → not found, both). The current implementation does not depend on either — it
   uses `subprocess.run(timeout=...)` and a Python thread sampler — and the issue's acceptance criteria
   do not reference an external timeout binary either. Recorded as an environment fact a builder must
   not violate: any fix sketch that shells out to `timeout(1)`/`gtimeout(1)` will not run here.

## Litmus tests

- **Idle-kill is live, not just attributed.** Grep for where the agy child process is launched in
  `utils/py/agy-turn.py` (and, if criterion 1 is scoped to cover it, `utils/py/consult.py`) — a real
  fix replaces or wraps the blocking `subprocess.run(..., timeout=turn_timeout)` call
  (`agy-turn.py:246`) with something that can act on `TurnDiagnostics`'s live signal *before*
  `turn_timeout` elapses, not merely call `classify()` after the fact (`agy-turn.py:299-303` is that
  after-the-fact call today — a plausible-but-fake fix leaves this line structurally unchanged).
- **The negative control is a real, separate assertion**, not a comment. `turn_diagnostics.py` already
  has the signal to build it on: `REASON_SLOW_PROGRESS` (`turn_diagnostics.py:75`, `:319-324`) fires
  when CPU is idle but the worktree mtime advanced. A reviewer should find a test that drives that
  exact shape — idle CPU, advancing mtime — and asserts the turn is **not** killed early, alongside a
  companion idle-with-no-mtime-advance test that asserts it **is**.
- **The warning fix is checkable by counting, not reading.** Run two consecutive healthy headless
  turns; before the fix, `grep -c "could not run headless"` on their combined stderr is 2 (identical,
  fires every time). After the fix, either the string is gone (replaced by a real probe) or it no
  longer appears at the same log severity on a clean run — a reviewer can tell the difference from the
  transcript alone.
- **Consult coverage is checkable by absence today, presence after.** `grep -n "TurnDiagnostics"
  utils/py/consult.py` returns nothing right now (verified 2026-08-10). If criterion 1 is scoped to
  cover consult per deviation 1 above, this becomes non-empty after the fix.
- **A green `validate.sh` proves nothing about the idle threshold's correctness on its own** — the
  suite only runs tests that are added to its explicit array (`validate.sh` lines ~95-130 name every
  test file individually; a new `test/gh492-*.sh` must be added to that list or it never runs).
  Confirm the new test is both present in the tree AND named inside `validate.sh`.

## Reversibility & blast radius

**Medium-to-Major — this is not a self-contained lane.**

- **Kernel touch, confirmed.** `utils/py/rtl.py` is one of the two files this repo's drafting
  convention names as the turn kernel (the other is `relay-automation/relay-turn-lib.sh`). Criterion 3
  cannot be satisfied without editing `rtl.py:39-96`/`:99+`, and **both** `agy-turn.py` and
  `consult.py` import those functions directly — a change here is live for every agy-driven turn and
  every consult, not scoped to the hang path alone. Per the self-modification constraint: a phase is
  not one turn, because the reviewer turn re-sources the kernel the builder just changed, so
  single-phase marathon isolation contains a driver change but not a kernel change. **This must ship
  as a direct PR, not a marathon lane.**
- **A second, narrower self-modification hazard specific to this issue.** `utils/py/agy-turn.py` is
  literally the script that executes an agy reviewer turn — the issue's own title calls agy "the
  reviewer half of the cross-model QA pipeline." If this fix ran as a marathon phase whose reviewer is
  agy, the reviewer turn reviewing the change would be executing under the just-edited version of its
  own turn-shim. `agy-turn.py` is not one of the two files literally named by the drafting convention's
  self-modification list, but the hazard shape is identical. Combined with the kernel-touch point
  above, direct-PR delivery is the only clean option; a non-agy reviewer for this specific change would
  be a workaround, not a fix, and the issue's own non-goals rule out swapping the default reviewer.
- **Regression risk the issue itself names.** An over-eager idle threshold is the actual danger here —
  criterion 5's negative control exists because a wrongly-tuned threshold could kill a genuinely slow
  agy turn, which would be a worse outcome for a legitimate long-running lane than today's blunt 900s
  cap. Threshold choice should default conservative and stay operator-configurable, as criterion 1
  requires.
- **Frozen twins, no Bash edits required.** Both `agy-turn.sh:agy-turn.py` and
  `consult.sh:consult.py` are frozen twins (`test/gh308-frozen-twin-guard.sh:14,22`); since Python is
  authoritative and this fix stays on the `.py` side, no `Frozen-twin-exception:` trailer is needed.
- **Fully revertible.** One commit revert restores today's wall-clock-only cap and always-on warning
  if a shipped idle threshold proves too aggressive in the field — nothing here is a one-way door.

## Swarm Preflight Contract

**Not marathon-fireable as scoped — see Reversibility & blast radius (`utils/py/rtl.py` kernel touch).**
The contract below is retained as a local pre-PR readiness/gate definition, not a marathon dispatch
target. `gate` stays the repo's real gate so a human or a direct-PR CI run can still use it; the probes
are best-effort suggestions for a builder's likely marker names, not a guarantee — verified against the
tree 2026-08-10, not against a fix that doesn't exist yet.

```json
{
  "target":        { "repo": ".", "ref": "development" },
  "gate":          "bash validate.sh",
  "fix_probes":    [
    { "type": "path_absent", "path": "test/gh492-agy-idle-kill.sh" },
    { "type": "grep_absent", "path": "utils/py/consult.py", "pattern": "TurnDiagnostics" }
  ],
  "artifacts":     ["utils/py/agy-turn.py", "utils/py/turn_diagnostics.py", "utils/py/rtl.py", "utils/py/consult.py"],
  "artifacts_new": ["test/gh492-agy-idle-kill.sh"],
  "remediation":   { "source": "issue #492", "criteria": "kill an idle agy turn on a short, separately-configurable threshold with GH-390 attribution preserved and a negative control; replace or demote the unconditional TTY auth warning — ranking summary only, NOT the definition of done (that is the verbatim ## Acceptance block above)" },
  "lanes": { "agy_safe": [], "orchestrator_only": ["utils/py/rtl.py", "utils/py/agy-turn.py", "utils/py/consult.py", "utils/py/turn_diagnostics.py"] }
}
```

**Probe polarity** (probes detect the **bug**, not the fix): `path_absent` on
`test/gh492-agy-idle-kill.sh` reports the fix as still required while that test file (a name suggested
by this doc, not mandated by the issue) does not yet exist; once a builder adds a test with that
behavior under any name, the reviewer must confirm manually rather than rely on the exact filename
matching. `grep_absent` on `TurnDiagnostics` inside `consult.py` reports deviation-1's gap as still
open while consult has no idle-attribution wiring; once consult imports and drives `TurnDiagnostics`
the same way `agy-turn.py` does, the probe stops reporting. Both probes are **necessary-but-not-
sufficient** signals for a feature this shaped — unlike GH-392's docs lane, a passing `validate.sh` run
including the new test is the actual proof; these probes only tell preflight bookkeeping that work was
attempted. `lanes.orchestrator_only` lists every file this fix plausibly touches because none of them
are agy-safe to hand to an agy builder given the kernel/self-reference hazards above.

## Provenance

Filed from two dated 2026-08-10 Nightwatch-wave operational failures: a ~900s no-CPU idle hang
mid-marathon (GH-390's own attribution correctly diagnosed it as `timeout-idle-no-progress` — the
detection worked; this issue is about the 900s spent getting there), and a separate auth pre-flight
timeout that killed a consult outright. Both were resolved by an interactive `agy login`, which is
itself evidence that the underlying cause was an expired or absent auth session that headless mode had
no way to report as such — the specific gap #375 left standing. Captured 2026-08-10 for release 0.3.0
Nightwatch; not yet assigned to a wave (kernel touch requires direct-PR delivery, not a marathon slot).
