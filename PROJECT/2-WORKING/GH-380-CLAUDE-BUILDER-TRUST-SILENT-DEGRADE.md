---
gh_issue: 380
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/380
title: "A claude builder silently ignores the target repo's permissions unless the directory was trusted interactively — never checked, never reported"
status: "2-WORKING — captured 2026-08-10 for release 0.3.0 Nightwatch. The issue has no `## Acceptance` section (verified live via `gh issue view 380`); acceptance criteria authored below, scoped down from the issue's four suggested fixes after verifying one of them is already shipped. Awaiting preflight."
created: 2026-08-10
updated: 2026-08-10
owner: noel
doc_type: project
release: "0.6.0 Meter"
complexity: 2
risk: 2
effort: 2
phases: 1
ratings_provisional: true
roadmap_exempt: false
related:
  - "#379 — the issue's 'Related' section says the same temp turn log holds #379's error JSON and both diagnoses are 'discarded the same way'. VERIFIED PARTIALLY STALE: as of commit 7812710 (2026-07-31, already in this tree), the claude-turn log is no longer a reaped temp file on the default execution path — see 'The defect' and the deviations section."
  - "GH-382 (commit 7812710) — 'failed-phase evidence survives — persistent claude-turn logs, escalation archives the relay transcript'. This is the fix that makes one of GH-380's own suggested remedies moot; load-bearing for the deviations section below."
  - "GH-117 (`_probe_claude_bin`/`_probe_agent_bin` in marathon_drive.py) — the separate, already-fixed 'claude builder missing from PATH headless' failure mode the operator asked me to check for interaction. Verified orthogonal: it probes binary discoverability only, never workspace trust."
  - "GH-308 — the Bash/Python frozen-twin contract that governs where this fix may land (relay-automation/claude-turn.sh is frozen; utils/py/claude-turn.py is authoritative)."
non_goals:
  - "Hard-stopping the turn when the target directory is untrusted. The issue is explicit: 'a warning, not a hard stop, since the turn does still run.' A fix that refuses to launch fails review."
  - "Auto-setting `hasTrustDialogAccepted` / silently trusting the directory on the operator's behalf. The issue's suggested fix is detect-and-report only; auto-trust changes the security posture without consent and was never asked for."
  - "Fixing #379 itself (the `budget_exhausted` phase-1 failure). The issue explicitly disclaims this: 'Trust was not what stopped that turn.'"
  - "Editing the turn kernel (`relay-automation/relay-turn-lib.sh` / `utils/py/rtl.py`) or the driver (`relay-automation/marathon.sh` / `utils/py/marathon_drive.py`). The detection belongs entirely in the claude builder shim (+ optionally the preflight twin); nothing about it requires touching the kernel or driver."
  - "Reproducing the exact `Hypercart-Dev-Tools/rebalance-OS` incident (108 permissions.allow entries). That repo is outside this tree and unverifiable from here; the fix must work generically, not just for that one observed case."
goal: >
  A `--builder claude` turn today runs with the target repo's `permissions.allow` silently and
  entirely ignored unless that directory was trusted interactively in Claude Code beforehand — a
  state a headless `claude -p` can neither set nor be warned about by the CLI in any way the
  harness surfaces. Verified against the current tree: neither claude-turn twin, neither
  swarm-preflight twin, nor marathon_drive.py's escalation path contains any check for this state.
  Add a warn-only detect-and-report so the operator sees it before or during a turn, instead of
  discovering it by chance the way this issue's incident was discovered.
---

# GH-380 · claude builder runs with target-repo permissions silently dropped, never checked or reported

## Status

| What was just completed | What's next |
|---|---|
| Captured 2026-08-10 for release 0.3.0 Nightwatch. Verified against the current tree that the harness has genuinely zero code path checking or reporting Claude Code workspace trust — confirmed by reading both `claude-turn` twins' exact CLI invocation and by a whole-tree grep for the two literal strings the CLI itself emits. Also found and scoped out one of the issue's four suggested fixes ("preserve the turn log") as already shipped by an unrelated, already-merged commit. Acceptance criteria authored — the issue has no `## Acceptance` section. | Preflight, then fire as a single-phase lane. Confined to the builder shim (+ optionally swarm-preflight's advisory line); does not touch the driver or kernel, so no phase-ordering constraint with other Nightwatch lanes is implied by this doc. |

**Issue:** https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/380

## The defect

**Confirmed: neither `claude-turn` twin passes any trust-related flag, nor reads `~/.claude.json`, before launching `claude -p`.**

- `relay-automation/claude-turn.sh:222-229` (Bash, FROZEN per the header at `relay-automation/claude-turn.sh:2`) invokes:
  ```
  "$CLAUDE_BIN" -p "$prompt" --model "$model" --allowedTools "Bash,Read,Edit,Write" \
    --permission-mode acceptEdits --output-format json --max-turns "$max_turns" --max-budget-usd "$max_budget"
  ```
  No flag or environment read relates to workspace trust.
- `utils/py/claude-turn.py:118-126` (Python, authoritative per GH-308, and the twin that actually runs by
  default — `relay-automation/claude-turn.sh:9` defaults `XYZ_PYTHON` to `1`, which `exec`s into this
  file) builds the identical `cmd` list, same absence.
- **Whole-tree verification of the issue's own grep claim:** re-ran it precisely.
  `/usr/bin/grep -rl 'hasTrustDialogAccepted' .` → zero matches. `/usr/bin/grep -rl 'has not been
  trusted' .` → zero matches. The harness has no code, anywhere, that recognizes this state — this
  is stronger confirmation than the issue's own (slightly different) grep pattern, which OR'd the two
  strings together and would have hit either.
- `utils/swarm-preflight.sh:780` builds `GH39_LANE_NOTE="codex=... agy=..."` (no `claude` term at
  all) and emits it at `utils/swarm-preflight.sh:846`. `utils/py/swarm_preflight.py:1347-1349`
  builds the identical `codex=/agy=` string and emits it at `utils/py/swarm_preflight.py:1436`. The
  issue's claim that `lane-cli` "does not report `claude` at all" is confirmed exactly as stated.
- `utils/py/marathon_drive.py`'s `escalate()` (`utils/py/marathon_drive.py:1169-1195`) writes
  `ESCALATION.md` with only `phase/task/relay-drive-exit/reason/gate/relay-file` fields — no stderr
  content from the builder turn is captured there. The issue's "ESCALATION.md: nothing" claim holds.

**One evidentiary claim in the issue is stale as of this tree — see the deviations section below**
(the turn-log location). It does not change the core defect: detection and reporting are still
entirely absent.

## Acceptance

*The live issue (fetched 2026-08-10 via `gh issue view 380`) has no `## Acceptance` heading — its
sections are `## TL;DR`, `## Why this is not an edge case`, `## Impact`, `## Not the cause of the
current failure`, `## Suggested fixes`, and `## Related`. Per the drafting brief, nothing is copied
into this section since there is nothing to copy verbatim. Authored criteria are in the section
below, never here.*

## Acceptance — authored (issue had none)

Derived from the issue's own "Suggested fixes" section, with one of the four scoped out as already
shipped (see deviations below) and the "warning, not a hard stop" constraint carried through
explicitly as a negative criterion:

- [ ] `utils/py/claude-turn.py` (the authoritative twin) reads `~/.claude.json` and checks
      `projects[<target-root>]["hasTrustDialogAccepted"]` before invoking the `claude` CLI. If the
      key is `false`, or the target-root path is absent from `projects` entirely, the shim prints a
      warning to stderr naming the same remedy the CLI itself gives (run interactively once and
      accept the dialog, or set the key directly in `~/.claude.json`) — and the turn **still runs**.
      A missing or unreadable `~/.claude.json` degrades to the same warning, not a crash.
- [ ] The frozen Bash twin (`relay-automation/claude-turn.sh`) is left untouched by this criterion
      unless the same check is added there too — in which case a `Frozen-twin-exception:` trailer is
      required on that commit (see Reversibility & blast radius). The Python twin alone satisfies
      this criterion for the default execution path.
- [ ] `swarm-preflight`'s `lane-cli` advisory line gains a `claude=` term reporting CLI presence and,
      when present, the workspace-trust state of the preflight's own `--target-root` (e.g.
      `claude=present/trusted` vs `claude=present/untrusted`) — in both twins
      (`utils/swarm-preflight.sh:780,846` and `utils/py/swarm_preflight.py:1347-1349,1436`), or with
      a `Frozen-twin-exception:` trailer if only one is touched.
- [ ] Wherever `--builder claude` is documented (README, ARCHITECTURE, or the header comment block in
      `relay-automation/claude-turn.sh`/`utils/py/claude-turn.py` themselves), a short note states
      that trust is per-directory, is set only by accepting the dialog in an interactive session, and
      a fresh Claude Code install starts with zero trusted directories.
- [ ] The new check adds no new hard-failure exit code and does not change `claude-turn`'s existing
      exit contract (`0` acted/deferred · `3` claude not found · `5` claude failed · `6` off-allowlist
      · `7` timeout). A fix that turns "untrusted" into a new failing exit code fails this criterion.

## Acceptance — deviations from the issue

1. **The issue has no `## Acceptance` section at all** (confirmed against the live issue, not just
   the local capture — `gh issue view 380` returns the identical body). This is a structural gap, not
   a wrong claim; criteria are authored above rather than declared "already satisfied."

2. **STALE: "the CLI's own warning goes into a temp file the operator never sees ... never copied
   into the phase directory."** True of the frozen Bash twin's fallback default
   (`relay-automation/claude-turn.sh:159`: `CLAUDE_LOG="${CLAUDE_LOG:-${TMPDIR:-/tmp}/claude-turn-$$.json}"`)
   but **not true of the path that actually runs by default.** `utils/py/claude-turn.py:72` defaults
   `CLAUDE_LOG` via `rtl_default_log()` (`utils/py/rtl.py:307-324`), which resolves to
   `<target-root>/relay-system/logs/<date>/claude-turn-<task>-<pid>.log` — inside the repo, not a
   reaped temp file — falling back to `$TMPDIR` only if that path can't be created. This landed in
   commit `7812710` ("fix(GH-382 follow-up): failed-phase evidence survives — persistent claude-turn
   logs, escalation archives the relay transcript", 2026-07-31) which is **already an ancestor of
   this tree's HEAD** (confirmed via `git merge-base --is-ancestor`). Practically: the issue's own
   suggested fix #4, "Preserve the turn log," is **already shipped** for the default execution path
   and is deliberately excluded from the authored acceptance criteria above. This does NOT touch the
   core defect — nothing extracts the trust-warning *line* from that persisted log into any
   operator-facing surface (stdout, `ESCALATION.md`, preflight); the log merely survives on disk
   where it previously might not have. Only one of the issue's four remedies is moot; the other three
   are unaffected and still required.

3. **Unverifiable: the exact incident details.** The 108-permissions figure and the literal CLI
   warning text are taken as given from the issue; I have no access to
   `Hypercart-Dev-Tools/rebalance-OS` or its `~/.claude.json` state to reproduce them, and did not
   attempt to (read-only task). The harness-side absence of any check — the actual defect this lane
   fixes — was verified directly and does not depend on that external repro.

4. **Interaction with the separate "claude doesn't work headless" issue, checked as requested.**
   Verified this tree already has fail-fast PATH discovery for the claude builder, independent of
   trust: `utils/py/marathon_drive.py:238-260` (`_probe_claude_bin`/`_probe_agent_bin`, GH-117) dies
   with a clear message *before any tick mutation* if `claude` isn't resolvable via `CLAUDE_BIN`,
   plain `PATH`, or `~/.claude/local/claude`. The shim layer carries an equivalent fallback + exit-3
   fail-fast (`relay-automation/claude-turn.sh:105-122`, `utils/py/claude-turn.py:36-48`). So
   `--builder claude` is not categorically broken headless in this tree today — it is wired, with a
   fail-fast binary-presence check. That check, however, tests only binary *discoverability*, never
   authentication or workspace trust, so it cannot detect or mask this issue's defect. The two failure
   modes are orthogonal (binary absent vs. binary present-but-untrusted-directory); this lane's fix
   does not depend on, or interact with, that PATH probe.

## Litmus tests

- Point `--target-root` at a directory that is absent from `~/.claude.json`'s `projects` map (or has
  `hasTrustDialogAccepted: false`) and run a `--builder claude` turn: stderr must carry the trust
  warning; the turn must still complete on its own merits (no new exit code, no hard stop). A fix
  that makes the turn exit non-zero solely because of untrusted state fails this test.
- Run `swarm-preflight` against a trusted vs. an untrusted target-root: the `lane-cli` advisory line
  must differ between the two runs, and the preflight's own exit code must stay unaffected — this
  stays advisory, matching the issue's "a warning, not a hard stop."
- A reviewer should NOT require editing the frozen `relay-automation/claude-turn.sh` twin unless the
  fix commit carries a `Frozen-twin-exception:` trailer — `utils/py/claude-turn.py` alone is
  sufficient for the default (`XYZ_PYTHON` unset) execution path per GH-308.
- A fix that silently sets `hasTrustDialogAccepted: true` (auto-trusting the directory) rather than
  printing a warning fails review outright — that is explicitly out of scope (see non-goals).

## Reversibility & blast radius

**Small.** The change is purely additive: a read of `~/.claude.json`, a conditional stderr print, and
(optionally) one new advisory-string term in preflight output. It does not alter the `claude` CLI
invocation's argv, does not change `claude-turn`'s exit contract, and does not touch
`rtl_enforce`/containment logic at all.

**Frozen-twin exposure:** the natural write-set is `utils/py/claude-turn.py` (and optionally
`utils/py/swarm_preflight.py`) — both are the *authoritative* side of a frozen-twin pair per
`test/gh308-frozen-twin-guard.sh:13-31` (`relay-automation/claude-turn.sh:utils/py/claude-turn.py` at
line 16; `utils/swarm-preflight.sh:utils/py/swarm_preflight.py` at line 24). Editing only the Python
side needs no `Frozen-twin-exception:` trailer. If the Bash side is also touched (e.g. to keep the
python3-absent fallback path in parity), that commit needs the trailer, since
`relay-automation/claude-turn.sh:1-2` states "FROZEN (GH-308): Python is authoritative — do not make
behavior changes here."

**Driver/kernel:** does not touch `relay-automation/marathon.sh` / `utils/py/marathon_drive.py` (the
driver) or `relay-automation/relay-turn-lib.sh` / `utils/py/rtl.py` (the turn kernel). Safe to run as
a normal single-phase marathon lane; no self-modification concern applies.

Fully revertible by reverting the commit(s). Worst-case failure mode of the new check itself is a
wrong or missing warning line — fail-open by construction, matching the issue's explicit ask that
this stay a warning rather than a gate.

## Swarm Preflight Contract

```json
{
  "target":        { "repo": ".", "ref": "development" },
  "gate":          "bash validate.sh",
  "fix_probes":    [
    { "type": "grep_absent", "path": "utils/py/claude-turn.py", "pattern": "hasTrustDialogAccepted" }
  ],
  "artifacts":     ["utils/py/claude-turn.py"],
  "artifacts_new": [],
  "remediation":   { "source": "issue #380", "criteria": "detect + report Claude Code workspace-trust state before a headless claude builder turn, warn-only, never a hard stop — ranking summary only, NOT the definition of done (that is the authored ## Acceptance block above)" },
  "lanes": { "agy_safe": [], "orchestrator_only": ["utils/py/claude-turn.py", "utils/swarm-preflight.sh", "utils/py/swarm_preflight.py"] }
}
```

**Probe polarity** (probes detect the **bug**, not the fix): `grep_absent` reports the fix as still
required while the marker string `hasTrustDialogAccepted` — which the fix introduces by reading that
exact key out of `~/.claude.json` — is still missing from `utils/py/claude-turn.py`. Confirmed absent
today (the whole-tree grep above returned zero hits, including in this file). Once the detection code
lands, the string appears in the file, the probe stops firing, and the lane is no longer fireable —
the intended behaviour.

`orchestrator_only` rather than `agy_safe`: the write-set is turn-shim and preflight infrastructure
code (part of the harness's own automation control surface), not a docs-only or leaf-application
change like the GH-392 exemplar's README edit — kept conservative pending an explicit call.

## Provenance

Filed as a precondition-verification issue, not a failure report — explicitly distinguished from
#379 in the issue's own "Not the cause of the current failure" section. Captured into `2-WORKING`
2026-08-10 for release 0.3.0 Nightwatch. Verification for this doc was done read-only against the
current tree (branch at capture time: `feature/agent-devtools-fuzzing`, HEAD `c2218d3`); no
`validate.sh` or `test/*.sh` was run.
