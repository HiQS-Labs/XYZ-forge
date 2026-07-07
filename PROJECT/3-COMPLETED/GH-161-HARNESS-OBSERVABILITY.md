---
gh_issue: 161
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/161
title: "Audit and add more observability into the harness and individual files"
status: SHIPPED (3-COMPLETED) — Phase 1 built on branch claude/gh-161-harness-observability
created: 2026-07-07
updated: 2026-07-07
owner: noel
doc_type: feature
complexity: 3
risk: 1
effort: 3
phases: 1
ratings_provisional: true
non_goals:
  - Not changing containment, allowlist, or commit behavior — logging only, no control-flow changes
  - Not a new external telemetry service — scope is in-repo, inspectable output
related:
  - relay-automation/relay-turn-lib.sh
  - relay-automation/codex-turn.sh
  - relay-automation/agy-turn.sh
  - relay-automation/marathon-drive.sh
  - utils/swarm-preflight.sh
goal: >
  Audit the harness for observability gaps and add structured instrumentation at key decision
  points, written into the turn's own transcript (CODEX_LOG/AGY_LOG) rather than a separate log,
  so root-causing a future containment/allowlist/worktree bug doesn't require manually sourcing
  relay-turn-lib.sh and hand-constructing an empirical repro from scratch.
roadmap_exempt: false
---

## Key concepts

- Root-causing GH-160 required manually sourcing `relay-turn-lib.sh` and hand-building a repro to
  see what `RTL_ROOT` actually resolved to — there was no direct way to observe that state live.
- Scope: `relay-automation/` shims (`codex-turn.sh`, `agy-turn.sh`, `relay-turn-lib.sh`,
  `marathon-drive.sh`) and `utils/swarm-preflight.sh`.
- Candidate instrumentation points: root resolution, allowlist matching, worktree seed/copy-back,
  containment verdicts.
- Destination decided: inject into the existing per-turn transcript (`CODEX_LOG`/`AGY_LOG`), not a
  new/separate log file — a transcript is already the artifact someone opens to debug a turn, so a
  second file just adds a place to forget to look. Format/verbosity still open.

> **Note for plan writers:** apply the `/ponytail` lens to whatever you propose here — favor the
> laziest instrumentation that actually works (existing log streams, plain `printf`, one line per
> decision point) over new logging infrastructure, config surface, or a bespoke format.

# GH-161 · Audit and add more observability into the harness and individual files

## Status

| What was just completed | What's next |
|---|---|
| **Phase 1 SHIPPED (2026-07-07):** built the "Proposed Phase 1 shape" from Phase 0 findings below verbatim — `rtl_trace`/`rtl_log_always`/`rtl_default_log` in `relay-turn-lib.sh`, wired via `RTL_LOG` in `codex-turn.sh`/`agy-turn.sh` before `rtl_init` runs. See "## Phase 1 build (shipped)" for the full change set, the two real bugs the build's own tests caught (a `set -e`-under-containment footgun and a truncating-redirect data loss), and verification. | Open for operator review/merge. No further work planned unless review surfaces a gap. |

## Idea

Audit the harness (`relay-automation/`, `utils/`, and individual shim scripts like `codex-turn.sh`,
`agy-turn.sh`, `relay-turn-lib.sh`, `marathon-drive.sh`, `swarm-preflight.sh`) for observability
gaps, and add more structured instrumentation.

## Why

Root-causing GH-160 required manually sourcing `relay-turn-lib.sh` and hand-constructing empirical
repros to see what `RTL_ROOT` actually resolved to — there was no direct way to observe that state
from a live run. A harness this size, driving multiple headless agents across many repos, would
benefit from built-in tracing/logging at key decision points (root resolution, allowlist matching,
worktree seed/copy-back, containment verdicts) rather than requiring source-level reconstruction
every time something goes wrong.

The instrumentation should land **inside the transcript files each turn already produces**
(`CODEX_LOG`/`AGY_LOG`), not a separate diagnostic log — a transcript is already the file someone
opens to debug a turn (see GH-165, where the missing piece of evidence was simply that `CODEX_LOG`
wasn't pinned to a persistent path), so a second log location is one more place to forget to check.

## Phase 0 — Explore & scope

Purpose: this is a review/spike, not yet a build — decide what "more observability" concretely means
before writing any instrumentation.

### Checklist

- [x] Survey the listed files for existing logging (grep for `echo`/`printf` to stderr, `CODEX_LOG`/
      `AGY_LOG` conventions already in place) so new instrumentation doesn't duplicate what's there.
- [x] List the specific decision points worth instrumenting (root resolution, allowlist match/reject,
      worktree seed/copy-back, containment verdict, tick token transitions) and what each needs to
      emit to have mattered for GH-160/GH-165-style investigations.
- [x] Confirm the destination: instrumentation writes into the turn's own transcript
      (`CODEX_LOG`/`AGY_LOG`), not a new file. Decide format within that constraint: structured
      (JSON lines) vs. plain text prefixed lines (e.g. `[trace] <point>: <state>`).
- [x] As part of this, decide whether `CODEX_LOG`/`AGY_LOG` need to default to a persistent path
      instead of today's PID-keyed `${TMPDIR:-/tmp}/codex-turn-$$.log` (ephemeral, gone once the
      process exits) — the transcript-injection approach only pays off if the transcript itself
      survives past the run.
- [x] Decide default posture: opt-in via an env var (e.g. `RTL_TRACE=1`) vs. always-on at a low
      verbosity level.
- [x] Propose the concrete change set (files touched, new env vars, output shape) as this doc's next
      phase — do not implement in this phase. Apply the `/ponytail` lens here: the lazy version is
      a handful of `printf` lines into the already-open log file descriptor, not a new logging
      library or format.

### QA checklist — Phase 0

- [x] The proposal names concrete decision points, not just "more logging."
- [x] The proposal writes into the existing transcript stream, not a new/separate log file.
- [x] The proposal states whether it's opt-in or always-on, with a stated reason.
- [x] The proposal doesn't touch containment/allowlist/commit control flow — logging only.

## Phase 0 findings

### 1. Existing logging survey

`relay-turn-lib.sh` already had diagnostic `printf … >&2` at a dozen call sites, but every one of them
was **failure/handoff-path only** — nothing traced the routine, successful path:

- `rtl_init` — one conditional printf, only when a REVIEWER turn drops `ALLOW_PATHS`. The `RTL_ROOT`
  resolution itself (the GH-51 same-repo collapse and the GH-160 vendored-`.xyz/` collapse) emitted
  **nothing** — exactly the state GH-160 needed and had to reconstruct by hand (see "Why" above).
- `rtl_check` — printed only on an off-allowlist revert; a *match* (the common case) was silent.
- `rtl_enforce` — printed on the commit-bypass branch, the violation summary, the file-scoped commit
  result, the archive-commit result, and the token-handoff branch taken. All informative, but **none
  of them landed in `CODEX_LOG`/`AGY_LOG`** — see finding 3.
- `rtl_worktree_begin`/`rtl_worktree_end` — no printfs at all; the seed list, the seedsig-skip
  decision, and the off-lane path were silent.

Conclusion: no duplication risk — the survey found a **failure-narration** layer, not a
**decision-trace** layer.

### 2. Decision points worth instrumenting

| Decision point | Function | What must be captured |
|---|---|---|
| Root resolution | `rtl_init` | The resolved `RTL_ROOT`, whether the GH-51 same-repo collapse fired, whether the GH-160 vendored-`.xyz/` collapse fired, `RTL_IGNORECASE`. |
| Allowlist match/reject | `rtl_check`/`rtl_in_allow` | For each changed path: the allow/reject verdict — today only the reject case printed. |
| Worktree seed/copy-back | `rtl_worktree_begin`/`rtl_worktree_end` | Which entries were seeded vs. skipped, the `RTL_WT_OFFLANE` verdict + offending path, per-entry copy-back decision. |
| Containment verdict | `rtl_enforce` | Whether HEAD moved and which branch fired, the final `RTL_VIOLATION` count, the commit outcome, the archive-commit outcome. |
| Tick token transitions | `rtl_enforce` step 4 | Which of the four handoff branches fired. |

### 3. Destination + format

Destination fixed by the issue: `CODEX_LOG`/`AGY_LOG`, not a new file. Format: **plain text prefixed
lines**, e.g. `[trace] rtl_init: RTL_ROOT=<path> …`, not JSON — the transcript is already unstructured
CLI output, and this repo already has a separate, purpose-built JSON-lines stream (`.tick/events/*.jsonl`)
that shouldn't be blurred with the human-readable transcript.

Key nuance the survey surfaced: the log redirect (`codex-turn.sh`'s `... > "$CODEX_LOG" 2>&1`;
`agy-turn.sh` likewise) wraps **only the bounded agent-binary invocation**, not the whole shim — it
closes before `rtl_worktree_end`/`rtl_enforce` run, so today's containment diagnostics physically
cannot reach `CODEX_LOG` no matter how loud they are. This is the real gap, not verbosity.

### 4. Persistent path vs. PID-keyed tmp

Current default: `${TMPDIR:-/tmp}/codex-turn-$$.log` (PID-keyed, gone once the process exits). Decision:
**yes, default `CODEX_LOG`/`AGY_LOG` to a persistent path**, reusing the already-existing
`rtl_transcript_root` resolver so no new path-resolution logic is introduced, falling back to today's
tmp path on any resolver failure — logging must never be able to fail a build.

### 5. Default posture — opt-in vs. always-on

Decision: **opt-in, `RTL_TRACE=1`, default off**, for the *new* fine-grained decision-point tracing —
this repo already has an established convention of opt-in advanced-behavior env flags for exactly this
class of extra work (`RELAY_WORKTREE_ISOLATION=1`, `XYZ_PYTHON=1`, `CODEX_ALLOW_API_KEY=1`). The new
trace points fire on the routine, successful path, so always-on would add noise to every transcript
forever for a benefit that only matters when reconstructing an incident. The *existing* unconditional
diagnostics stay unconditional — Phase 1 only adds routing them into the log file too.

## Proposed Phase 1 shape

Add `rtl_trace()` (opt-in, gated on `RTL_TRACE=1` + `RTL_LOG`) and `rtl_log_always()` (mirrors an
existing unconditional diagnostic into `RTL_LOG`, no new gating) to `relay-turn-lib.sh`; call them at
the decision points in finding 2. Wire `RTL_LOG` in `codex-turn.sh`/`agy-turn.sh` before `rtl_init`
runs. Separately (optional/independent): re-point `CODEX_LOG`/`AGY_LOG`'s default at a persistent path
via `rtl_transcript_root`, falling back to the historical tmp path on any resolver failure.

Non-goals preserved: no change to `rtl_enforce`'s exit codes, the allowlist/containment logic, or the
commit/no-push contract — this is destination + presence of `printf` lines only.

## Phase 1 build (shipped 2026-07-07, branch `claude/gh-161-harness-observability`)

Built the Proposed Phase 1 shape above, verbatim, plus the "separate/optional" persistent-log-path
change (worth doing together — GH-165's actual root cause was exactly this: `CODEX_LOG` never pinned
to a durable path).

### Change set

- **`relay-automation/relay-turn-lib.sh`**
  - `rtl_trace(msg...)` — opt-in (`RTL_TRACE=1` + `RTL_LOG` set) fine-grained decision-point line.
  - `rtl_log_always(msg...)` — mirrors an existing unconditional diagnostic into `RTL_LOG`; gated only
    on `RTL_LOG` being set, no new flag.
  - `rtl_default_log(root, tool, task)` — persistent transcript path under
    `rtl_transcript_root(root)/logs/<date>/<tool>-<task>-<pid>.log`, falling back to the historical
    `${TMPDIR:-/tmp}/<tool>-$$.log` on any resolver/mkdir failure.
  - Instrumented `rtl_init` (root resolution + both collapse flags), `rtl_check` (allow + reject),
    `rtl_worktree_begin`/`rtl_worktree_end` (seed/skip/offlane/copy-back), `rtl_enforce` (HEAD-moved
    branch, violation count, commit/archive-commit outcome, all four token-handoff branches).
- **`relay-automation/codex-turn.sh`** / **`relay-automation/agy-turn.sh`** — `CODEX_LOG`/`AGY_LOG`
  now default to `rtl_default_log(...)`, exported as `RTL_LOG` **before** `rtl_init` runs (moved up
  from their old post-`rtl_init` position) so the trace call inside `rtl_init` itself lands in the
  transcript. The agent-binary redirect switched from truncating (`>`) to appending (`>>`) — see bug
  (2) below.
- **`.gitignore`** — added `relay-system/logs/`. **Load-bearing, not cosmetic**: `rtl_check` already
  deletes any file that lands in the tracked tree matching the shim's own transcript path ("not an
  agent edit"); an un-ignored persistent log would be wiped at the end of every single turn.
- **`test/relay-turn-trace.sh`** (new, 20 cases) — direct unit coverage of all three helpers plus a
  real end-to-end run through `codex-turn.sh` (stub `codex`) proving: the persistent transcript is
  created and never appears in `git status`; `RTL_TRACE=1` yields fine-grained lines the default
  posture doesn't; the unconditional lines appear either way; an explicitly in-tree `CODEX_LOG` is
  still swept exactly as before. Added to `validate.sh`.

### Two real bugs the build's own tests caught (worth recording — both are exactly the kind of subtle
### containment-adjacent regression this repo's `AGENTS.md` flags relay-turn-lib.sh changes as Costly for)

1. **`set -e` under a `test && action` idiom.** A final cleanup step (added to sweep our own
   instrumentation writes out of an in-tree `RTL_LOG`) ended with `[[ cond ]] && rm -f ...` as the
   *last statement* of `rtl_enforce`. When `cond` is false (nothing to sweep — the common case), that
   expression's own exit status is 1, and since every turn-taker shim runs under `set -euo pipefail`,
   an otherwise-successful turn was silently killed. A second, related instance: passing `RTL_LOG_REL`
   straight to `git status --porcelain -- <path>` as a pathspec is fatal (exit 128, "outside
   repository") whenever `CODEX_LOG` is `/dev/null` or any other path outside `RTL_ROOT` — which is
   the overwhelming majority of this repo's own test suite's convention, so the very first full
   `validate.sh` run surfaced it across a dozen previously-green tests immediately. Fixed by (a) using
   an explicit `if`/`fi` instead of `&&` as the function's final statement, and (b) skipping the sweep
   entirely unless `RTL_LOG_REL` is a genuine repo-relative path.
2. **Truncating redirect wiping earlier writes.** `codex-turn.sh`/`agy-turn.sh` redirect the
   agent-binary invocation with `> "$CODEX_LOG" 2>&1` — a TRUNCATING redirect. Once `rtl_init` could
   write a trace line into that same path *before* the agent even runs, the truncation silently wiped
   it. Fixed by switching to `>>` (append); still effectively a fresh file per turn since the default
   filename embeds `$$`.

Both were caught by the new end-to-end test in `test/relay-turn-trace.sh`, not by inspection — worth
noting for GH-162 (debug-mantra harness mode): "run the actual thing, don't just read the diff" applied
to the instrumentation build itself.

### Verification

- `test/relay-turn-trace.sh`: 20/20 pass (new).
- Full existing regression set covering `relay-turn-lib.sh` (`codex-turn.sh`, `agy-turn.sh`,
  `worktree-isolation.sh`, `shim-worktree.sh`, `relay-turn-handoff.sh`, `relay-turn-timeout.sh`,
  `claude-turn.sh`, `aider-turn.sh`, `archive-commit.sh`, `relay-artifact-file.sh`,
  `relay-dep-drift.sh`): all still green, no regressions.
- `skills/relay-automation/relay-pkg.tar.gz` regenerated (`make-pkg.sh`) since packaged sources
  changed; `path-integrity.sh` / `relay-pkg-freshness.sh` confirmed green against the refreshed tarball.
- Full `./validate.sh`: only 4 failures, and all 4 were independently reproduced against a clean
  `origin/main` baseline (via `git stash`) with the identical failure — `archive-writers.sh`
  ("consult (unset) exited non-zero"), `xyz-harness-hooks.sh` ("marathon.sh exit=2"),
  `security-scan.sh` (a root-can-read-"unreadable"-file environment quirk, 2/33), and
  `python:test_python_layer.py` (pytest not installed in this container). None touch
  `relay-automation/` or this change's files — pre-existing, unrelated to this build.
