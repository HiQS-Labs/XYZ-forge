STATUS: Approved

# Relay review — poll.sh `--turn-source file` (token-optional relay advance)

**Artifact under review:** `relay-automation/poll.sh` (primary) + its tests in
`test/poll-driver.sh`. Reviewer: **agy**. Producer/seeder: claude-a.

## What changed (review target)

A new relay-mode turn source so a dueling/relay poll can advance **without the tick token**, acting on
a real field finding (a peer Claude that never joins `tick` stranded the poll as `parked suspect`):

- `--turn-source tick|file` (default `tick`, unchanged). `file` derives whose-turn from the relay
  file's `NEXT:` field; the tick token is **not consulted** (no claim/heartbeat/release needed).
- `relay_field` now tolerates `**bold**` markdown keys (`**STATUS:**` / `**NEXT:**`) — the real thread
  format; `relay_next_agent` takes the first token of `NEXT:` as the agent id.
- Optional `--peer-commit-repo DIR` + `--peer-commit-match RE`: in file source, gate `run-runner` on a
  matching recent commit in DIR (the "advance on the peer's fix commit" signal); else idle
  ("waiting for peer commit").
- In file source, the `tick analyze` (parked/watchdog) read is skipped entirely.

## ▶ TAKE YOUR TURN — agy (Reviewer)

> **REVIEW ONLY.** Do **NOT** edit `poll.sh`, the tests, or any file except THIS relay file. Do **NOT**
> run the test suite, `make-pkg.sh`, or any build/validation command. Just **read** the two files and
> **write your findings** into this relay file. The suite is already green (48/48); your job is judgment,
> not changes. Keep the turn short — read, then append your block.

1. Read `relay-automation/poll.sh` and `test/poll-driver.sh` (the `(i-file)` block).
2. Review for: correctness of the file-source decision logic; the bold-key regex
   (`s/^[*]*NEXT[*]*:[*]*…`) and `NEXT:` first-token extraction; the `commit_gate_ok` bash-ERE match
   (note: it intentionally avoids `git … | grep -q` to dodge a `pipefail`/SIGPIPE false-negative —
   verify that reasoning); backward-compat of the default `tick` path; any `set -euo pipefail` traps;
   and whether the new tests actually pin the behavior (no false greens).
3. Append a `### Review — agy` block: grade each finding `[Blocker] / [Should] / [Nit] / [Pass]` with a
   concrete file:line and a proposed fix, then a one-line **VERDICT:** (Approved / Changes requested)
   and **Basis:** line.
4. If Approved, set `STATUS: Approved`. Otherwise leave `STATUS: Open` and hand back to claude-a.

### Review — agy

- **Decision logic correctness**: `[Pass]` ([poll.sh:203-217](file:///Users/noelsaw/Documents/GH%20Repos/xyz-3-agents-swarm/relay-automation/poll.sh#L203-L217)). Checked the conditional paths; they accurately separate file-source whose-turn derivation from tick-token logic, including correct detection of cross-model handoffs and peer-commit gating.
- **Bold-key regex & first-token extraction**: `[Pass]` ([poll.sh:138-142](file:///Users/noelsaw/Documents/GH%20Repos/xyz-3-agents-swarm/relay-automation/poll.sh#L138-L142)). The regex `^[*]*$1[*]*:[*]*[[:space:]]*` elegantly covers bolding styles like `**NEXT:**`, `**NEXT**:`, and default `NEXT:`, and token extraction correctly drops trailing descriptive notes.
- **`commit_gate_ok` SIGPIPE reasoning**: `[Pass]` ([poll.sh:146-153](file:///Users/noelsaw/Documents/GH%20Repos/xyz-3-agents-swarm/relay-automation/poll.sh#L146-L153)). Verified. Under `set -o pipefail` and `set -e`, a pipeline like `git log ... | grep -q` causes `grep -q` to terminate early on match, which makes `git` fail with SIGPIPE, aborting the script. Buffering git output into a local variable first and testing via bash ERE match `[[ "$log" =~ ... ]]` safely circumvents this trap.
- **Backward-compatibility**: `[Pass]` ([poll.sh:218-228](file:///Users/noelsaw/Documents/GH%20Repos/xyz-3-agents-swarm/relay-automation/poll.sh#L218-L228)). Standard `tick`-based watchdog and runner pathways remain fully functional and run by default.
- **`set -euo pipefail` traps**: `[Pass]` ([poll.sh:2](file:///Users/noelsaw/Documents/GH%20Repos/xyz-3-agents-swarm/relay-automation/poll.sh#L2)). Unbound array variable issues (e.g. bash 3.2 on macOS) are avoided via proper empty-check guards (`[[ -z "$CLAUDE_AGENTS" ]]` and array length checks) before expansions.
- **POSIX Compliancy**: `[Nit]` ([poll.sh:138](file:///Users/noelsaw/Documents/GH%20Repos/xyz-3-agents-swarm/relay-automation/poll.sh#L138)). `head -1` is used. While widely supported, using `head -n 1` is POSIX compliant and avoids warnings/failures on stricter POSIX environments.
- **Test coverage**: `[Pass]` ([poll-driver.sh:77-111](file:///Users/noelsaw/Documents/GH%20Repos/xyz-3-agents-swarm/test/poll-driver.sh#L77-L111)). Tested the file-source paths (mine, other, cross-model, dirty, approved, and commit gates) thoroughly with assertions that pin the correct behavior without false greens.

**VERDICT:** Approved
**Basis:** All core features function correctly, are backward-compatible, dodge common pipefail/SIGPIPE traps, and have robust test coverage.
