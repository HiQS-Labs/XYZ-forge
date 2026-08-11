---
gh_issue: 379
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/379
title: "GH-379 — a budget-exhausted claude builder is escalated as 'pre-advance-failed', and its own error text is discarded"
status: "2-WORKING — captured 2026-08-10 for release 0.3.0 Nightwatch. Verified against `development` (fast-forward ancestor of the working tree checked). The issue's own title-level complaint (exit 5 → 'pre-advance-failed' misattribution) is ALREADY FIXED by #407 (a163efc/ccfb314, merged 2026-08-08, three days after this issue was last updated). The temp-file survival risk for the builder's own JSON is ALSO already fixed on the authoritative Python side (commit 7812710, 2026-07-31). What remains open is narrower than the issue as filed. Acceptance criteria are authored here — the issue has none. Awaiting preflight."
created: 2026-08-10
updated: 2026-08-10
owner: noel
doc_type: project
release: "0.3.0 Nightwatch"
complexity: 3
risk: 3
effort: 3
phases: 1
ratings_provisional: true
roadmap_exempt: false
related:
  - "#407 — SHIPPED 2026-08-08 (a163efc/ccfb314, PR #469). This is the SAME underlying defect as this issue's Problem #1 (exit 5 misattributed as 'pre-advance-failed' when the gate never ran), fixed by distinguishing `reason: relay-failed-before-gate` from `reason: pre-advance-failed` using a `gate:` state the driver already tracks (`utils/py/marathon_drive.py:2034-2063`). #379 does not cite #407 by number, but re-running its own reproduction against the fixed code no longer produces the escalation it complains about."
  - "#408/#409 (folded into PROJECT/2-WORKING/GH-409-408-TOKEN-FAILURE-VISIBILITY.md) — a DIFFERENT defect in the same neighborhood, not the same class. #408 is an ACTIVE suppression: `rtl.claim_task_or_exit` and `_run_tick_loud` redirect a subprocess's stdout/stderr to `DEVNULL` before the caller ever sees it. This issue's remaining gap (surfacing `subtype`/`terminal_reason`) is a MISSING PROPAGATION step, not a suppression — the data is already captured to a persistent file (`utils/py/claude-turn.py:72`) and nothing discards it; nothing simply copies it into `ESCALATION.md`. The GH-409/408 doc's own text names the piece this issue still needs — 'a reason channel out of relay-drive that does not exist' — as an acknowledged open gap, so the two issues point at the same missing architecture from different sides without being the same bug."
  - "#382 — the 2026-07-30 rebalance-OS panic run whose forensics produced commit 7812710 (2026-07-31), which made `claude-turn.py`'s transcript persistent instead of tempdir-only. That fix landed the day AFTER this issue was filed and already resolves the 'temp file not reaped yet' survival risk this issue describes, on the Python (authoritative) side only."
  - "#390 — shipped the `GATE_GUARD_KILL_EXIT` precedent (`utils/py/marathon_drive.py:273`, used at `:1562`) for exactly this shape of problem: two different causes reaching the same exit code, resolved by widening the reason string rather than the exit code. This lane's acceptance criterion 1 follows that same precedent (additive `ESCALATION.md` field), not a new exit code, which is also why 'give the builder-failure case its own exit code' from the issue's suggested fixes is treated as superseded, not adopted."
non_goals:
  - "Re-fixing the exit-5 → 'pre-advance-failed' misattribution. #407 already shipped this (verified below); redoing it would duplicate merged work and risks re-diverging from `test/gh407-gate-ran-attribution.sh`, which already pins the fixed behavior."
  - "Fixing the Bash frozen twin's temp-file behavior (`relay-automation/claude-turn.sh:159`, `CLAUDE_LOG=\"${CLAUDE_LOG:-${TMPDIR:-/tmp}/claude-turn-$$.json}\"`). It is a FROZEN twin (`test/gh308-frozen-twin-guard.sh:15`); Python is authoritative and already fixed (see #382 above). Touching the Bash file needs a `Frozen-twin-exception:` trailer and is not part of this lane's scope."
  - "Changing the numeric default of `CLAUDE_MAX_BUDGET` ($0.50) or `CLAUDE_MAX_TURNS` (12) in code. This lane documents the existing defaults accurately; raising them is a separate cost decision with its own blast radius."
  - "Building the exact side-channel design (event, file, or exit-code range) that carries `subtype`/`terminal_reason` from the builder shim to the driver. This doc states the requirement and the constraint (must not require a new marathon-only exit code, must not touch the Bash twins); the mechanism is an implementation decision for the fix itself."
goal: >
  Issue #379's own reproduction (`--builder claude`, budget-exhausted mid-turn, escalated as
  `reason: pre-advance-failed`) no longer reproduces on `development`: #407 already separates
  'the gate ran and failed' from 'the relay failed before the gate ran'. What #407 does NOT do, and
  what remains genuinely open, is name WHY the relay failed before the gate — a budget-exhausted
  builder, a crashed shim, and a containment violation all still collapse into the same generic
  `reason: relay-failed-before-gate` string, and the builder's own diagnosis (`subtype`,
  `terminal_reason`, `total_cost_usd`) — already captured to a persistent file — is never copied into
  `ESCALATION.md` or echoed to the operator. Separately, `CLAUDE_MAX_BUDGET`/`CLAUDE_MAX_TURNS` remain
  undocumented outside the two builder shims themselves. Close both gaps.
---

# GH-379 · the builder's own failure reason exists on disk and never reaches the operator

## Status

| What was just completed | What's next |
|---|---|
| Captured 2026-08-10 as a lane of release 0.3.0 Nightwatch. Every factual claim in the issue was re-checked against the tree rather than trusted — the issue's headline complaint (exit 5 escalated as `pre-advance-failed`) turned out to already be fixed by a same-neighborhood issue (#407) that shipped three days after this one was last touched. Acceptance criteria are authored fresh, scoped to what is actually still missing. | Preflight, then fire. The write-set touches the driver (`utils/py/marathon_drive.py`) with a real behavior change (not a comment), so per the self-modification constraint this must ship as a direct PR or a supervised `/relay`, not an automated marathon phase — see Reversibility & blast radius. |

**Issue:** https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/379

## The defect

The issue names three problems. Verified against `development` (ancestor of the checked-out tree,
confirmed via `git merge-base --is-ancestor`), each stands differently than as filed:

**Problem 1 — "exit 5 is overloaded, escalation misattributes the cause" — ALREADY FIXED.**
`utils/py/marathon_drive.py:2034-2063` is exactly this fix, landed as #407 (`a163efc`/`ccfb314`,
merged 2026-08-08 — three days after this issue's last update, 2026-08-05). The relevant code:

```python
gate_ran = run_gate_result[0] != "not-run"
if timeout_reason[0] != "turn-timeout-or-hang":
    reason, emit = timeout_reason[0], timeout_emit[0]
elif gate_ran:
    reason = "pre-advance-failed"
    ...
else:
    reason = "relay-failed-before-gate"
    ...
```

`run_gate_result[0]` (`utils/py/marathon_drive.py:760`) defaults to `"not-run"` and is set ONLY
inside `run_pre_advance_gate()` (`:1332`, `:1406`), which the relay_exit==5 branch never calls
directly — it only reads a flag set (if at all) by an earlier stall/timeout probe. In the issue's
exact scenario — a builder turn fails on round 1, before any reviewer handoff, before any gate
invocation — `run_gate_result` stays `"not-run"`, so `gate_ran` is `False` and the escalation now
reads `reason: relay-failed-before-gate`, not `reason: pre-advance-failed`. `escalate()`
(`:1169-1211`) writes `gate: {run_gate_result[0]}` into every `ESCALATION.md` unconditionally
(`:1193`), so `gate: not-run` is present alongside it. A test exists and is green for this:
`test/gh407-gate-ran-attribution.sh`. The issue's own reproduction, re-run today, would not produce
its "Observed" log block.

**Problem 2 — "the builder's own error is discarded" — PARTIALLY FIXED, discoverability gap remains.**
The issue's exact quoted path, `$TMPDIR/claude-turn-<pid>.json`, is the literal current path of the
FROZEN Bash twin: `relay-automation/claude-turn.sh:159` —
`CLAUDE_LOG="${CLAUDE_LOG:-${TMPDIR:-/tmp}/claude-turn-$$.json}"`. It is unchanged and still at risk
of exactly the loss the issue describes. But the AUTHORITATIVE Python twin no longer has this
problem: `utils/py/claude-turn.py:72` —
`claude_log = os.environ.get("CLAUDE_LOG") or rtl_default_log(root, "claude-turn", t)` — resolves to
a persistent path under `<transcript-root>/logs/<date>/claude-turn-<task-slug>-<pid>.log`, fixed by
commit `7812710` (2026-07-31, the day AFTER this issue was filed, in direct forensic response to a
2026-07-30 panic run — the same class of loss this issue reports). `marathon_drive.py`'s `escalate()`
also now archives the relay transcript on every escalation, not only on success (`:1200-1209`, same
commit). Given `XYZ_PYTHON` defaults to `1` (`relay-automation/marathon-drive.sh:9`), a fresh run
today uses the Python path by default — the issue's own incident, dated 2026-07-30, predates this fix
by one day, which is consistent with its exact `$TMPDIR/.../*.json` path (that was still the Python
default at the time).

What is genuinely still missing: the persisted file's PATH is never printed to the marathon log or
`ESCALATION.md`, and its CONTENT (`is_error`, `subtype`, `terminal_reason`, `total_cost_usd`) is never
copied or echoed anywhere. `ESCALATION.md`'s template (`utils/py/marathon_drive.py:1187-1195`) writes
`phase`/`task`/`relay-drive-exit`/`reason`/`gate`/`relay-file` — no builder-diagnostic field exists.
An operator who does not already know `rtl_default_log`'s path convention still cannot find the
builder's own explanation without a manual search.

**Problem 3 — "the default is undocumented and low for real work" — CONFIRMED, still true.**
Verified 2026-08-10: `/usr/bin/grep -rn "CLAUDE_MAX_BUDGET\|CLAUDE_MAX_TURNS" README.md` → 0 matches.
Same for `relay-automation/MARATHON.example.yaml` → 0 matches (only a mention of `--builder claude`
being available, no budget/turn guidance). The only place either variable is named is inside the two
builder shims themselves: `relay-automation/claude-turn.sh:45-46,175-176` and
`utils/py/claude-turn.py:74-75`, both defaulting `CLAUDE_MAX_BUDGET` to `0.50` and `CLAUDE_MAX_TURNS`
to `12`. Note: `claude-turn.sh:46`'s own header COMMENT says "default: 2.00", which does not match its
own code default of `0.50` two lines later (`:176`) — the shim's internal doc comment is itself
stale, a small compounding data point for "this value is undocumented and not kept in sync."

`marathon.sh:18-20`'s description of `--builder claude` as "a SEPARATE, PER-CALL API-BILLED
turn-taker" was checked and is accurate as general documentation; the issue's point that
`total_cost_usd` is notional (not an API charge) under OAuth/subscription auth is a real nuance the
comment does not carry, but it is a minor addition to an already-accurate sentence, not a defect.

## Acceptance

Issue #379 has **no `## Acceptance` block** — it is written as an incident report ("TL;DR" /
"Observed" / "Three separate problems" / "Suggested fixes" / a closing cost-model note), not as a
checklist. Per the drafting contract, criteria are authored below in a separately labelled section
rather than fabricated here.

## Acceptance — authored (issue has none)

1. When a `--builder claude` turn fails for a reason other than a wall-clock timeout (exit 7) or a
   containment violation (exit 6) — i.e. the generic `bounded_rc != 0` path at
   `utils/py/claude-turn.py:179-182` — the builder's own `is_error`/`subtype`/`terminal_reason` fields
   from its persisted `claude_log` JSON (`utils/py/claude-turn.py:72`) reach the phase's
   `ESCALATION.md` as an additive field, alongside the existing `reason:`/`gate:` lines
   (`utils/py/marathon_drive.py:1187-1195`) — not replacing them, not requiring a new exit code (see
   the `#390` precedent in `related` above for why widening the reason string, not the exit code, is
   the established pattern here).
2. `CLAUDE_MAX_BUDGET` and `CLAUDE_MAX_TURNS` are documented wherever `--builder claude` is described
   (README.md and/or `relay-automation/MARATHON.example.yaml`), stating the actual current defaults
   ($0.50 / 12 turns — verified above) and that a floor cost (cache-creation dominated) is paid per
   turn, so an operator can judge headroom before a run rather than after a budget-exhausted halt.
3. `relay-automation/claude-turn.sh:46`'s stale header comment ("default: 2.00") is corrected to match
   its own code default (`0.50`, `:176`) — small, but it is documentation actively contradicting the
   code it describes, discovered in the course of this lane.
4. `test/gh407-gate-ran-attribution.sh` remains green after this lane's change — proof the new
   diagnostic field is additive and does not re-touch #407's reason/gate distinction.

## Acceptance — deviations from the issue

Not applicable in the usual sense (there is no verbatim issue text to deviate from — see above), but
the issue's own "Suggested fixes" section is NOT carried forward unchanged, and the differences matter
enough to record explicitly:

- **"Give the builder-failure case its own exit code, distinct from gate failure"** — NOT adopted.
  #407 already solved the distinguishability problem this bullet asks for, using the existing
  `reason:`/`gate:` fields rather than a new exit code. Introducing a new exit code now would add a
  second, competing signal for the same fact the `gate:` field already states unambiguously.
- **"Detect budget exhaustion explicitly and print the remedy"** — narrowed to criterion 1 above
  (surface the fields that already say this) rather than building separate detection logic. The
  `claude` CLI's own `subtype: "error_max_budget_usd"` already IS the detection; the gap is only that
  nothing reads or shows it, not that nothing recognizes it.
- **"Preserve the turn log. Copy claude-turn-<pid>.json into the phase directory on failure, or write
  it there directly"** — already satisfied on the Python side by a prior, unrelated fix (#382-driven,
  commit `7812710`); not re-specified as new work here.

## Litmus tests

- **Reproduce against the CURRENT tree first, not the issue's log excerpt.** Stub `claude` to exit 1
  immediately (no real API call needed) under `--builder claude` with `RELAY_WORKTREE_ISOLATION=1` and
  confirm today's `ESCALATION.md` reads `reason: relay-failed-before-gate` / `gate: not-run` — NOT
  `pre-advance-failed`. If a reviewer sees `pre-advance-failed` for a pre-gate builder failure on
  `development`, something regressed #407; that is a #407 bug report, not evidence for this lane.
- **The new field must appear on the SAME repro that currently produces `gate: not-run`.** A fix that
  only adds the diagnostic field when the gate DID run (`pre-advance-failed`) misses the case that
  actually motivated this issue — a builder that never reached the gate at all.
- **`test/gh407-gate-ran-attribution.sh` must still pass unmodified.** This is the sharpest regression
  check available: it already pins the exact `reason:`/`gate:` behavior this lane must not disturb.
- **A green `validate.sh` proves nothing about criteria 2 or 3** (documentation). A reviewer must
  check by reading, the same shape GH-392, GH-358, and GH-414 all used for their non-mechanically-
  gatable criteria.
- **Grep, don't trust.** `/usr/bin/grep -c "CLAUDE_MAX_BUDGET" README.md
  relay-automation/MARATHON.example.yaml` reads `0` today for both files; it must read ≥1 for at least
  one after the fix.

## Reversibility & blast radius

**Medium, and the write-set is the load-bearing fact here.**

- **`utils/py/marathon_drive.py` is BOTH a frozen-twin-paired file (`test/gh308-frozen-twin-guard.sh:23`,
  `TWINS` array pairs it with `relay-automation/marathon-drive.sh`) AND, separately and more
  restrictively, the running driver itself.** Per the self-modification constraint: a lane whose
  write-set includes `utils/py/marathon_drive.py` cannot be fired as an automated marathon lane — the
  phase that edits it would be gated by the very code it is changing, and a single phase is not
  isolation against this, because the reviewer turn re-sources the same driver process the builder
  turn just modified. **This lane must ship as a direct PR, or a human-supervised `/relay`, never as a
  `marathon.sh` phase.** This is a real behavior change to `escalate()`'s written content, not a
  comment (contrast GH-414's precedent, where the driver-touching remainder was comment-only and was
  still marathon-fireable under `orchestrator_only`) — the bar for "must be a direct PR" is clearly
  met here, not a borderline case.
- **`utils/py/claude-turn.py` is also a frozen-twin-paired file**
  (`relay-automation/claude-turn.sh:utils/py/claude-turn.py`, `test/gh308-frozen-twin-guard.sh:15`).
  Whatever mechanism carries `subtype`/`terminal_reason` from the builder shim to the driver touches
  this file too. If this fix is itself built under `--builder claude`, the builder would be editing
  the very shim executing its own current turn — a narrower, additional self-referential risk beyond
  the driver one above. Build it under `--builder codex` or `--builder agy` instead.
- **The Bash twins (`relay-automation/marathon-drive.sh`, `relay-automation/claude-turn.sh`) are
  explicitly OUT of scope** (see non_goals) and are not touched by this lane as drafted. If a future
  author extends this fix to the Bash side, that edit needs a `Frozen-twin-exception:` trailer
  (GH-321 format) and does not get one implicitly from this doc.
- **The documentation criteria (2, 3) are low-risk, marathon-fireable on their own** — README.md and
  `relay-automation/MARATHON.example.yaml` are not driver/kernel files. If the two halves are split
  into separate phases, the docs half could run as a normal lane while the driver half goes out as a
  direct PR.
- **Revert path:** a single commit revert. `ESCALATION.md` is a generated, git-committed artifact
  written fresh by `escalate()` on each escalation, not a persisted store other tooling depends on for
  its CURRENT shape — the one existing reader, `debug_mantra_note()` (`utils/py/marathon_drive.py:556-
  563`), scrapes only the line starting `reason:` and ignores everything else, so an ADDITIVE new line
  cannot break it (verified by reading that function in full).

## Swarm Preflight Contract

```json
{
  "target":        { "repo": ".", "ref": "development" },
  "gate":          "bash validate.sh",
  "fix_probes":    [
    { "type": "grep_absent", "path": "utils/py/marathon_drive.py", "pattern": "terminal_reason" },
    { "type": "grep_absent", "path": "README.md", "pattern": "CLAUDE_MAX_BUDGET" }
  ],
  "artifacts":     ["utils/py/marathon_drive.py", "utils/py/claude-turn.py", "README.md", "relay-automation/MARATHON.example.yaml", "relay-automation/claude-turn.sh"],
  "artifacts_new": [],
  "remediation":   { "source": "issue #379, narrowed after verification — #407 already fixed the exit-5 misattribution", "criteria": "surface the builder's own subtype/terminal_reason into ESCALATION.md on a pre-gate builder failure, and document CLAUDE_MAX_BUDGET/CLAUDE_MAX_TURNS — ranking summary only, NOT the definition of done (that is the authored ## Acceptance block above)" },
  "lanes": { "agy_safe": ["README.md", "relay-automation/MARATHON.example.yaml"], "orchestrator_only": ["utils/py/marathon_drive.py", "utils/py/claude-turn.py"] }
}
```

**This contract is provided for preflight/relay tooling and reviewer use — it does NOT mean this
lane is safe to fire as an automated `marathon.sh` phase.** See Reversibility & blast radius: the
`utils/py/marathon_drive.py` edit is a real behavior change to the running driver and must go out as
a direct PR or a supervised `/relay`.

**Probe polarity** (probes detect the **bug**, not the fix): both probes are `grep_absent`, meaning
each currently reports "the fix's marker string is still missing, so the fix is still required."
`terminal_reason` does not appear anywhere in `utils/py/marathon_drive.py` today (verified by direct
grep) — once the fix adds it to the `ESCALATION.md` template or its surrounding code, the probe
stops firing. Same logic for `CLAUDE_MAX_BUDGET` in `README.md`: zero matches today, and the probe is
satisfied the moment documentation names it. Neither probe can be satisfied by an unrelated edit that
happens to contain the string coincidentally — both patterns are specific enough (a full env-var name,
a specific field name) that a false-positive landing is unlikely.

## Provenance

Filed 2026-07-30 from a real `--builder claude` run against `Hypercart-Dev-Tools/rebalance-OS`.
Captured into `2-WORKING` 2026-08-10 for release 0.3.0 Nightwatch. Verification found the issue's
headline complaint already resolved by the independently-filed and independently-shipped #407
(2026-08-08) and its temp-file survival risk already resolved by the #382-driven commit `7812710`
(2026-07-31) — both landed after this issue but before this capture, and neither references this
issue number. This doc is the reconciliation: what #379 asked for that is already done, what is not,
and why the remainder cannot go out as an ordinary marathon lane.
