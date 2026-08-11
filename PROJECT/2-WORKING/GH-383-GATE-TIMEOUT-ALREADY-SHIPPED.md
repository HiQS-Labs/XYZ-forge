---
gh_issue: 383
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/383
title: "The pre-advance gate has no timeout, so a hanging gate stalls an unattended marathon indefinitely"
status: "2-WORKING — captured 2026-08-10 for release 0.3.0 Nightwatch, batch 2. VERIFIED STALE: the timeout the issue asks for already shipped in GH-390 (commit 94cafc9) and was hardened in GH-457 (commit 1fcef22). The issue's own code snippet matches the pre-GH-390 shape, not the tree as it stands. Only a documentation gap and one intentional escape hatch remain; see deviations. Awaiting operator decision on whether to close #383 outright or fire the doc-only residual as a lane."
created: 2026-08-10
updated: 2026-08-10
owner: noel
doc_type: project
release: "0.3.0 Nightwatch"
complexity: 1
risk: 1
effort: 1
phases: 1
ratings_provisional: true
roadmap_exempt: false
related:
  - "#390 — shipped the exact mechanism this issue asks for: wall-clock, CPU, and RSS caps on the gate subprocess, with a distinct `gate-killed` exit (commit 94cafc9, PR #393). This is the primary reason #383 is stale."
  - "#457 — hardened the wall-clock cap into fast/full tiers so a legitimately long green gate is not falsely killed (commit 1fcef22/41f7472, PR #468). Directly relevant: it is a second, later commit still tuning the exact mechanism #383 claims does not exist."
  - "#407 — added the `gate: not-run|green|red` attribution and the reason-string split (`gate-killed` vs `pre-advance-failed`) that #383's suggested fix #1 also asks for (\"a TimeoutExpired should be reported distinctly from a non-zero exit\"). Already implemented."
  - "#379 — the issue's own related link (exit-code overloading in the escalation path); not independently reverified here, carried over as-is."
  - "#382 — the issue's own related link; also the crash that motivated GH-390's gate guard in the first place, so #382 and #383 trace to the same incident."
non_goals:
  - "Re-implementing a gate timeout. It already exists, is tiered, is tested (test/gh390-gate-guard.sh, test/gh457-gate-tiers.sh, test/gh407-gate-ran-attribution.sh), and has been observed firing live. Any lane here must not duplicate it."
  - "Changing MARATHON_GATE_GUARD=0's behaviour. That escape hatch deliberately restores the exact pre-GH-390, untimed call for emergency use (marathon_drive.py:1325-1327's own comment: \"a guard that false-positives would otherwise block every marathon\"). Removing that intent is a different, much bigger discussion than this issue and is out of scope."
  - "Adding stdout/stderr capture to the gate subprocess. Real and separate — see 'The defect' — but it is a telemetry/escalation-completeness gap, not a timeout gap, and belongs to its own issue if pursued."
goal: >
  Correct the record on #383 before it can misdirect a builder: the harness already bounds the
  pre-advance gate by wall clock (300s fast tier / 1800s full tier, tiered specifically so a green
  gate near the old flat cap stops false-killing), by CPU, and by RSS, kills the whole process group
  on overrun, and reports the kill as a reason distinct from a genuine gate failure. What remains
  undocumented for an operator is the tier/env-var surface itself and the one place a hang can still
  happen on purpose (MARATHON_GATE_GUARD=0). Publish that, or close #383 as already fixed.
---

# GH-383 · the "no timeout" claim is stale — the gate guard already bounds it

## Status

| What was just completed | What's next |
|---|---|
| Verified against the tree at `development` (branch confirmed clean vs. HEAD, no diff on `utils/py/marathon_drive.py`) on 2026-08-10: the pre-advance gate is already wrapped in a wall-clock + CPU + RSS guard that kills a hanging gate and reports it distinctly. The issue's quoted code (`subprocess.run(...)`, no `timeout=`) matches the **pre-GH-390** shape, which now only survives as the `MARATHON_GATE_GUARD=0` escape hatch. | Operator call: close #383 as already-shipped, or fire a documentation-only lane (env vars + escape-hatch caveat) as scoped in the authored criteria below. Either way, no code change is warranted. |

**Issue:** https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/383

## The defect

**What the issue claims** (quoting its own snippet, attributed to `utils/py/marathon_drive.py:1012-1015`):

```python
def run_pre_advance_gate():
    cwd = args.target_root if args.target_root else None
    rc = subprocess.run(pre_advance_cmd, shell=True, executable="/bin/bash",
                        cwd=cwd, env=_gate_env()).returncode
```

and that `grep -rn 'GATE_TIMEOUT|gate_timeout'` returns nothing across the harness.

**What is actually at those coordinates today.** `run_pre_advance_gate()` is no longer at 1012-1015
— that range is now an unrelated exit-handler comment (`utils/py/marathon_drive.py:1012-1015`, part
of `_marathon_drive_on_exit`/GH-238 gate-probe commentary). The gate function itself is at
`utils/py/marathon_drive.py:1321-1407`.

**The literal grep is true but the conclusion it's used for is false.** `/usr/bin/grep -rn
"GATE_TIMEOUT|gate_timeout" .` does return nothing — because the harness's variables are named
`MARATHON_GATE_WALL_S`, `MARATHON_GATE_CPU_S`, `MARATHON_GATE_RSS_MB`, and `MARATHON_GATE_TIER`
(`utils/py/marathon_drive.py:342-345`), not `GATE_TIMEOUT`. Grepping for a string that was never the
chosen name and reading the empty result as "no timeout exists" is the stale part of this issue.

**The default path (`MARATHON_GATE_GUARD` unset or `"1"`, i.e. the default — `marathon_drive.py:1328`)
does bound the gate**, verified by reading `run_pre_advance_gate()` end to end:

- `GATE_TIERS = {"fast": {"wall_s": 300, "cpu_s": 240}, "full": {"wall_s": 1800, "cpu_s": 1200}}`,
  `GATE_DEFAULT_TIER = "full"` — `utils/py/marathon_drive.py:302-309`. A gate with no configured tier
  gets a **1800-second (30-minute) wall-clock cap** by default, not "generous but finite" as a wish —
  it is shipped as exactly that.
- The gate runs via `subprocess.Popen(..., start_new_session=True)` so it is its own process-group
  leader (`marathon_drive.py:1352-1353`), then a poll loop checks elapsed wall time and group RSS on
  every tick (`marathon_drive.py:1357-1373`). On overrun it calls `_gate_kill_group(proc, reason)` and
  sets `rc = GATE_GUARD_KILL_EXIT` (`= 108`, `marathon_drive.py:273`) — `marathon_drive.py:1370-1371`.
- The kill is **reported distinctly from a real gate failure**, which is exactly suggested-fix #1 in
  the issue ("a TimeoutExpired should be reported distinctly from a non-zero exit"). At
  `marathon_drive.py:1559-1568`, `escalate()` branches on `gate_exit == GATE_GUARD_KILL_EXIT`: a
  guard kill logs `"pre-advance gate KILLED by the resource guard"` and escalates as `gate-killed`;
  anything else escalates as `pre-advance-failed`. This split is the subject of its own test,
  `test/gh407-gate-ran-attribution.sh`, and the tier sizing (so a legitimately long green gate is not
  mistaken for a runaway) is the subject of `test/gh457-gate-tiers.sh`.
- A CPU cap (soft/hard split, `marathon_drive.py:1337-1348`) and an RSS cap
  (`GATE_RSS_MB_DEFAULT = 8192`, `marathon_drive.py:311`, checked at `marathon_drive.py:1367-1368`)
  are enforced alongside the wall clock.

**Git history confirms this is not new-but-unmerged work**: `94cafc9 feat(GH-390): resource-guard the
pre-advance gate (Phase 1 — layers 1-3 + gate-killed)` introduced `wall_s` and the guard together;
`1fcef22`/`41f7472 fix(GH-457): the gate's caps come from a declared tier, and the default tier is
bigger than the gate` (PR #468) retuned it afterward. Both are on `development`, which is HEAD for
this checkout (`git diff development...HEAD -- utils/py/marathon_drive.py` is empty).

**One real, narrower gap survives.** `MARATHON_GATE_GUARD=0` intentionally disables the entire guard
and restores the untimed call the issue quotes — `marathon_drive.py:1328-1333`. Its own comment says
why: *"a guard that false-positives would otherwise block every marathon until someone can land a
revert."* An operator who sets this flag gets back exactly the failure mode #383 describes. That
env var is not documented in any `.md` file in the tree (`/usr/bin/grep -rln "MARATHON_GATE_GUARD"
--include="*.md" .` returns only session transcripts under `relay-system/`, not README/AGENTS.md), so
an operator has no way to know the trade-off exists short of reading the source.

**Second real, narrower gap: the tier/cap env vars themselves are undocumented for operators.**
`README.md:174-176` documents the RSS cap ("the GH-390 gate guard enforces an RSS cap and kills an
over-budget gate") as part of the GH-392 hardware-sizing section, but does not mention
`MARATHON_GATE_WALL_S`, `MARATHON_GATE_CPU_S`, or `MARATHON_GATE_TIER` anywhere — confirmed by
`/usr/bin/grep -rln "MARATHON_GATE_WALL_S" --include="*.md" .` returning no hits outside this doc.

**Third, out-of-scope-for-#383 finding requested for the record.** `run_pre_advance_gate()`'s guarded
path calls `subprocess.Popen(cmd, shell=True, executable="/bin/bash", cwd=cwd, env=env,
start_new_session=True)` at `marathon_drive.py:1352-1353` with **no `stdout=` or `stderr=` kwarg** —
confirmed by reading the call and grepping the surrounding function (`marathon_drive.py:1321-1407`)
for `stdout`/`stderr`, which finds none. This is still true today. The gate's output is not captured
by the driver at all; the subprocess inherits the driver's own stdout/stderr file descriptors, so the
text goes wherever the operator redirected the whole marathon process (or the terminal, if
unredirected) — but the Python driver itself has no programmatic handle on it, so it cannot attach
gate output to an escalation record. **This does not bear on #383**: it is orthogonal to whether the
gate times out, and would apply identically to a green, red, or killed gate. It is a real gap but
belongs to a different issue about escalation-record completeness, not this one.

## Acceptance

The issue as filed has **no `## Acceptance` heading and no checklist of acceptance criteria** — it
is a narrative bug report (TL;DR, "How this was reached", "Workaround available today", "Suggested
fix" as three numbered prose paragraphs, "Related"). There is nothing to copy verbatim. Per the
drafting brief, criteria are authored separately below rather than invented inside this section.

## Acceptance — deviations from the issue

1. **The headline claim is stale.** "The pre-advance gate has no timeout" was true of the code the
   issue quotes, but that code is the pre-GH-390 shape. On `development` today the default path has a
   1800s (full tier) / 300s (fast tier) wall-clock cap, a CPU cap, and an RSS cap, all enforced by a
   process-group kill with distinct `gate-killed` attribution. See "The defect" above for every
   file:line.
2. **Suggested fix #1** ("give the gate a default timeout... reported distinctly... so the escalation
   says what happened") **is already shipped**, not a suggestion still pending. `GATE_GUARD_KILL_EXIT`
   and the `escalate()` branch at `marathon_drive.py:1559-1568` do exactly this.
3. **Suggested fix #2** ("document it alongside `--pre-advance-cmd`... a gate is operator-supplied and
   may hang") is **partially done**: the RSS cap is documented in `README.md:174-176`, but the
   wall-clock/CPU tier env vars and the `MARATHON_GATE_GUARD=0` escape hatch are not documented
   anywhere. This is the one piece of the issue that is still actionable, and it is scoped as the
   authored criteria below.
4. **Suggested fix #3** ("document the wrapper form... until (1) lands") is now moot — (1) landed, so
   the `perl -e 'alarm'` wrapper the issue proposes as a workaround is no longer the load-bearing
   protection; the harness's own default is.
5. **The grep the issue cites as evidence** (`grep -rn 'GATE_TIMEOUT|gate_timeout'` returns nothing)
   is true as literally stated but does not support "no timeout exists" — the shipped variables are
   named `MARATHON_GATE_WALL_S` / `MARATHON_GATE_CPU_S` / `MARATHON_GATE_TIER`, a different name for
   the same concept, not an absence of the concept.
6. **A note found in an adjacent capture doc contradicts my own reading and is flagged rather than
   silently resolved.** `PROJECT/2-WORKING/GH-390-GATE-GUARD-COVERAGE.md:19` (captured 2026-08-08)
   lists `"#383 — owns the wall-clock bound; out of scope here."` as a related-issue note on GH-390's
   *remainder* phase. Read literally that suggests the wall-clock bound was deliberately left for
   #383 to add later. But the wall-clock cap (`wall_s`) was introduced in the *same* commit as the
   rest of the guard — `94cafc9 feat(GH-390): resource-guard the pre-advance gate (Phase 1 — layers
   1-3 + gate-killed)` — not in a later commit tied to #383. The most likely reading is that the
   GH-390 doc's note was itself stale or referred to something narrower (e.g., #383 documenting the
   bound, not implementing it) that never got split out before #383 was filed as its own "no timeout"
   report. Either way, the code is unambiguous: the wall-clock cap exists today and is not waiting on
   this issue.

### Authored acceptance criteria (the issue has none; this scopes only the residual gap)

- [ ] `README.md` (or the operator-facing env-var reference nearest `--pre-advance-cmd`) documents
      `MARATHON_GATE_WALL_S`, `MARATHON_GATE_CPU_S`, and `MARATHON_GATE_TIER`, including the shipped
      defaults (fast: 300s wall / 240s CPU; full: 1800s wall / 1200s CPU) and that an unknown tier
      name falls back loudly to `full`.
- [ ] The same location documents `MARATHON_GATE_GUARD=0` as an escape hatch that **removes all
      timeout/CPU/RSS protection and restores the untimed pre-GH-390 gate call**, so an operator who
      sets it understands they have reintroduced the exact failure mode #383 describes.
- [ ] The documentation does not claim the guard is disableable-without-cost, and does not re-litigate
      or duplicate the RSS-cap sentence already at `README.md:174-176`.
- [ ] No change to `utils/py/marathon_drive.py`, `relay-automation/marathon-drive.sh`, or any other
      driver/kernel file. This is documentation-only; see Reversibility & blast radius.

## Litmus tests

- **A reviewer can falsify "still no timeout" in one read**: open `utils/py/marathon_drive.py`, jump
  to `run_pre_advance_gate()` (currently 1321-1407), and check for a wall-clock comparison inside the
  poll loop. If a future edit removed the wall-clock branch, that would be a real regression of #383's
  concern and this doc's claim would need updating — but as of this capture it is present.
- **A plausible-but-wrong "fix" for the authored criteria** would document only the RSS cap again
  (already covered) or only mention "there's a guard" without naming the env vars or their defaults —
  an operator sizing a custom gate command still could not answer "what's my timeout budget" from that
  prose. The criteria above require the actual variable names and shipped numbers, not a gesture at
  their existence.
- **A green `validate.sh` proves nothing about this lane** — it is documentation; nothing in the
  suite reads README prose. The reviewer has to actually read the added text against the criteria.

## Reversibility & blast radius

**Small.** The only change in scope is documentation (`README.md` or an adjacent doc). It does not
touch `utils/py/marathon_drive.py`, `relay-automation/marathon-drive.sh`,
`relay-automation/relay-turn-lib.sh`, or `utils/py/rtl.py` — so the self-modification constraint does
not apply and this can run as a normal marathon lane. Fully revertible by reverting one commit.

`relay-automation/marathon-drive.sh:utils/py/marathon_drive.py` **is** one of the twelve frozen-twin
pairs in `test/gh308-frozen-twin-guard.sh` (`TWINS` array, line 23), with the Python side
authoritative. This lane's write-set does not include either half of that pair, so no
`Frozen-twin-exception:` trailer is needed. Flagged for the record only: **if** a future lane instead
pursued a code change here (e.g., documenting via inline comments only, or the stdout/stderr capture
gap noted above), it would touch `utils/py/marathon_drive.py`, which is explicitly the running driver
— that would make it unfireable as a marathon lane per the self-modification constraint and would need
to ship as a direct PR instead.

## Swarm Preflight Contract

```json
{
  "target":        { "repo": ".", "ref": "development" },
  "gate":          "bash validate.sh",
  "fix_probes":    [
    { "type": "grep_absent", "path": "README.md", "pattern": "MARATHON_GATE_WALL_S" }
  ],
  "artifacts":     ["README.md"],
  "artifacts_new": [],
  "remediation":   { "source": "issue #383", "criteria": "document the gate guard's wall-clock/CPU tier env vars (MARATHON_GATE_WALL_S, MARATHON_GATE_CPU_S, MARATHON_GATE_TIER) and the MARATHON_GATE_GUARD=0 escape hatch's trade-off — ranking summary only, NOT the definition of done (that is the authored acceptance criteria above; the issue itself has no ## Acceptance block)" },
  "lanes": { "agy_safe": ["README.md"], "orchestrator_only": [] }
}
```

**Probe polarity** (probes detect the **bug**, not the fix): `grep_absent` reports the fix as still
required while `MARATHON_GATE_WALL_S` — the marker string the fix introduces — is missing from
`README.md`. Today that string is absent from `README.md` (confirmed above), so the probe correctly
fires as "not yet documented." Once the tier env vars are published there, the probe stops reporting
and the lane is no longer fireable, which is the intended behaviour.

## Provenance

Drafted 2026-08-10 as part of Nightwatch batch 2, from the issue text captured via
`gh issue view 383` into a session-local scratch file (path deliberately not recorded here — it is
machine-specific and `pdda-check-hardcoded-paths` rejects it). Verified read-only against the checked-out
tree (branch `feature/agent-devtools-fuzzing`, confirmed identical to `development` for
`utils/py/marathon_drive.py` via `git diff development...HEAD`, no output). No `validate.sh` or
`test/*.sh` was executed; all evidence is from reading source and `git log`. `gh issue view` was
attempted for live issue/comment state on #383, #390, #407 and failed in this sandbox (TLS
certificate error reaching `api.github.com`) — issue live-state (open/closed, comments) is therefore
**unverified**; everything above is sourced from the provided issue-text file and the repository
tree, not from a live fetch.
