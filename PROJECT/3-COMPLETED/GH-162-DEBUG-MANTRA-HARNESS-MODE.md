---
gh_issue: 162
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/162
title: "Add a 'code debugging mantra' harness file/mode that builds the mantra into the harness itself"
status: SHIPPED (3-COMPLETED) — Phase 1 built on branch claude/gh-161-harness-observability
created: 2026-07-07
updated: 2026-07-07
owner: noel
doc_type: feature
complexity: 2
risk: 1
effort: 2
phases: 1
ratings_provisional: true
non_goals:
  - Not replacing the ~/.claude/skills/debug-mantra Claude Code skill — this is about builder/reviewer turns, a different surface
  - Not a general prompt-engineering rewrite of turn prompts beyond the debugging-discipline slice
related:
  - relay-automation/relay-turn-lib.sh
  - relay-automation/marathon-drive.sh
  - utils/swarm-preflight.sh
goal: >
  Decide how to bake the debug-mantra discipline (reproduce reliably -> know the fail path ->
  question the hypothesis -> treat every run as a breadcrumb) into the harness itself, so headless
  builder/reviewer turns hitting a failing gate or flaky test have the same structured discipline
  a Claude Code session gets from the externally-invoked skill.
roadmap_exempt: false
---

## Key concepts

- The debug-mantra skill's four-step discipline (reproduce → know the fail path → question the
  hypothesis → treat every run as a breadcrumb) is what found GH-160's root cause, after an earlier
  investigation stalled on an unverified assumption.
- Today it lives only as an externally-invoked Claude Code skill — headless builder/reviewer turns
  (codex, agy) get no equivalent discipline when they hit a failing gate or flaky test.
- **Locked-in trigger:** the agent turns the mode on itself, automatically, after its own first
  failed bug-fix attempt — not a flag a human or caller has to set in advance.
- Candidate integration points for the mode's content: a static reference file, injected into the
  next turn's prompt once the trigger fires, or a new `--debug-mantra` mode surfaced by
  `swarm-preflight`/`marathon-drive`.

> **Note for plan writers:** apply the `/ponytail` lens here — favor the laziest integration seam
> that actually works (a static reference file a turn is told to read beats a new relay-drive mode)
> over new harness machinery, and question whether a seam needs to exist at all before adding one.

# GH-162 · Add a "code debugging mantra" harness file/mode

## Status

| What was just completed | What's next |
|---|---|
| **Phase 1 SHIPPED (2026-07-07):** built the debug-mantra auto-trigger in `marathon-drive.sh` — a read-only peek at GH-45's own `.tick/attempts/<lane>` counter detects a prior non-Approved attempt, and a note (citing the last `ESCALATION.md` reason) is baked into the re-rendered relay file, pointing the builder at a new static `relay-automation/DEBUG-MANTRA.md`. See "## Phase 1 build (shipped)" for the one refinement versus the original proposal (no separate `relay-turn-lib.sh` helper — the injection point turned out to be the relay-file render, not a shim-side prompt prepend), the change set, and verification. | Open for operator review/merge (same PR as GH-161, per operator direction — one PR for both). `relay-drive.sh`'s own standalone-mode mirror (when driven without `marathon-drive.sh`) is a noted, unbuilt follow-up. |

## Idea

Add a "code debugging mantra" harness file or mode that builds the debug-mantra discipline into
the harness itself, rather than it living only as an externally-invoked Claude Code skill
(`~/.claude/skills/debug-mantra`) — and have it turn itself on automatically, without a human or
caller flag, once the agent has already failed to fix the bug on its own once.

## Why

The debug-mantra skill's four-step discipline (reproduce reliably -> know the fail path -> question
the hypothesis -> treat every run as a breadcrumb) is what actually found GH-160's root cause this
session, after an earlier investigation stalled on an unverified assumption. Builder/reviewer turns
driven by this harness (codex, agy, etc.) hit debugging tasks constantly (failing gates, flaky
tests, containment escalations) but have no equivalent structured discipline available to them —
they're just prompted to "read the acceptance criteria and your diff." Baking an equivalent mode or
reference file into the harness (e.g. injected into a turn's prompt when a gate fails, or a
`--debug-mantra` mode for `swarm-preflight`/`marathon-drive`) could make headless debugging turns
more reliable and less prone to the same "confident but wrong" failure mode.

A first attempt failing is exactly the signal a human would use to decide "stop guessing, get
disciplined" — the same escalation point where the debug-mantra Claude Code skill earns its keep.
Requiring an explicit flag in advance would mean nobody sets it until after the second or third
failure, by which point the harness has already burned a round on unstructured guessing. Turning it
on automatically after the first failure removes that judgment call from the loop entirely.

## Phase 0 — Explore & scope

Purpose: this is a review/spike — the trigger condition (auto-on after 1 failed self-attempted fix)
is locked in; decide how to detect that condition and which content-integration seam to use.

### Checklist

- [x] Define "1 failed bug-fix attempt" concretely per turn type: is it a `--pre-advance-cmd` gate
      failing after a builder turn's edit, a round-cap retry, a failed test the agent's own diff was
      supposed to fix, or something `relay-drive.sh`/`marathon-drive.sh` already tracks (e.g. round
      number, prior-round gate result)? Find the existing signal rather than inventing a new counter.
- [x] Decide where the trigger check lives: inside the turn-taker shim (`codex-turn.sh`/
      `agy-turn.sh`) before dispatch, or in the driver (`relay-drive.sh`/`marathon-drive.sh`) when it
      detects the retry.
- [x] Compare the three candidate content seams (static reference file a turn can be told to read;
      prompt injection triggered on the detected failure; a new `--debug-mantra` mode on
      `swarm-preflight`/`marathon-drive`) and note the cost/benefit of each, given the trigger already
      fires automatically.
- [x] Check whether builder/reviewer turn prompts already carry any debugging guidance today (grep
      `relay-automation/` for existing prompt text) to avoid duplicating or conflicting instructions.
- [x] Sketch one concrete worked example end to end: a turn whose gate fails once, the harness
      detects it, and what the mantra-equivalent guidance looks like injected into the *next* turn's
      context.
- [x] Decide whether this needs to reference the ledger/breadcrumb step (step 4) at all for a
      single-turn, stateless builder — or whether that step only makes sense for a human/skill
      session with persistent context across a debug session.
- [x] Propose the concrete change set as this doc's next phase — do not implement in this phase.
      Apply the `/ponytail` lens: prefer the seam that adds the least new harness surface (a
      reference file over a new mode/flag) unless the worked example proves the simpler seam
      doesn't actually work.

### QA checklist — Phase 0

- [x] The proposal names the exact existing signal used to detect "1 failed attempt" — not a new,
      separately-tracked counter, unless nothing existing covers it.
- [x] The proposal names one specific content-integration seam, not "somewhere in the harness."
- [x] The worked example is concrete (a real turn type, a real gate) and shows the failure→trigger→
      next-turn sequence, not hypothetical in the abstract.
- [x] The proposal addresses whether/how the breadcrumb-ledger step applies to a stateless turn.

## Phase 0 findings

### 1. The existing signal for "1 failed attempt"

GH-45's own per-lane attempt cap already tracks exactly this: `.tick/attempts/<lane>` (one line
appended per fire) in `relay-automation/marathon-drive.sh`'s `lane_attempt_gate()`, keyed on `PHASE_ID`.
Critically, `lane_attempt_reset()` clears that file the moment a phase reaches `STATUS: Approved` and
its pre-advance gate passes — so the counter's line count **is already "consecutive non-Approved
attempts,"** with zero new tracking needed. No new counter invented.

### 2. Trigger-check location

The driver (`marathon-drive.sh`), not the turn-taker shims — `codex-turn.sh`/`agy-turn.sh` never
receive `PHASE_ID` or see `.tick/attempts/`, so detecting the retry there would mean re-deriving or
threading a new identifier through the shim layer, duplicating logic GH-45 already centralized in the
driver. The driver also owns the one place that can inject into the artifact the builder actually
reads before doing anything else: the relay-file render.

### 3. Content-seam comparison

| Seam | Cost | Verdict |
|---|---|---|
| Static reference file (`DEBUG-MANTRA.md`) a turn is told to read | One new file; zero new flags/modes | **Chosen** |
| Prompt injection on detected failure | Needs a live injection point in the turn's CLI prompt string (owned by `rtl_turn_prompt` in the shim, not the driver) | Rejected as primary — the driver cannot reach into the shim's prompt construction without new plumbing; see finding 5 for how the reference file gets surfaced instead |
| New `--debug-mantra` mode on `swarm-preflight`/`marathon-drive` | A new flag + new code path a caller must remember/wire, for something that is supposed to trigger itself | Rejected — the trigger is already automatic; a mode flag would be redundant surface for zero added capability |

### 4. Existing prompt-text survey

`relay-automation/`'s builder/reviewer templates (`marathon-drive.sh`'s relay-file heredoc,
`relay-turn-lib.sh`'s `rtl_turn_prompt`) carry scope/procedure instructions (what to edit, tick
commands, "do not run the full gate suite") but **no debugging-discipline guidance at all** — no
overlap or conflict to reconcile.

### 5. Worked example

Builder=codex, reviewer=agy, `--pre-advance-cmd "bash validate.sh"`. First fire: `marathon-drive.sh`
renders `phases/p1/RELAY.md` with STATUS: Open, the phase brief, builder/reviewer turn blocks — no
`.tick/attempts/p1` exists yet, so no debug-mantra text. The relay closes Approved but `validate.sh`
fails: `escalate("pre-advance-failed", 0)` writes `phases/p1/ESCALATION.md` (`reason:
pre-advance-failed`) and exits 5; `.tick/attempts/p1` now holds one line. On the next `marathon-drive.sh
--phase-id p1 ...` fire (a re-fire, e.g. `marathon.sh --retry` or a manual re-run), the render reads
`.tick/attempts/p1`'s line count (1) BEFORE `lane_attempt_gate` appends this fire's own line, and bakes
a `## Debug mantra` section into the SAME "Phase Brief" area of the relay file, citing "1 prior
attempt(s)" and the `pre-advance-failed` reason from `ESCALATION.md` — the builder sees it as part of
the very first thing it reads.

### 6. Breadcrumb-ledger step (mantra step 4) for a stateless turn

Applies, but is satisfied by artifacts the harness already persists — no new ledger file. Because
`marathon-drive.sh` **fully re-renders** the relay file on every fire (a `cat >` truncating heredoc,
not an append), a re-fired phase's relay file starts with NO round history of its own; the durable
breadcrumb trail for a stateless single-turn builder is `ESCALATION.md` (reason + relay-drive exit
code, one per phase dir) plus, within a single marathon-drive invocation, the relay file's own
`### Round N` blocks as the builder/reviewer go back and forth. Phase 1 only needs to point the builder
at `ESCALATION.md` — it does not need a new persistent ledger.

## Proposed Phase 1 shape

Add `debug_mantra_prior_attempts()` (read-only peek at `.tick/attempts/<lane>`'s line count, reusing
GH-45's own `_lane_key` helper) and `debug_mantra_note()` (renders the note, citing the last
`ESCALATION.md` reason, empty string when prior=0) to `marathon-drive.sh`. Wire the peek + note
BEFORE Step 1's relay-file render, injecting into the "Phase Brief" section. Add a new static
`relay-automation/DEBUG-MANTRA.md` with the four-step discipline, written for a headless builder.
`relay-drive.sh`'s standalone (non-marathon) mode is a smaller, separate follow-up since it drives an
EXISTING relay file rather than rendering one — no natural "first thing read" injection point without
further design.

## Phase 1 build (shipped 2026-07-07, branch `claude/gh-161-harness-observability`)

Built the Proposed Phase 1 shape above, with one refinement the build surfaced: the original
Phase 0 sketch (and the earlier explore-lane pass) considered mirroring `relay-turn-lib.sh`'s
`rtl_drift_brief` pattern (a shim-side prompt-prepend). Building it concretely showed that pattern
does not fit here — `rtl_drift_brief` prepends to the CLI *prompt string* the shim hands the agent
binary, but `marathon-drive.sh` builder/reviewer turns are driven through the *relay file itself*
(the artifact the builder reads first), which the driver already owns and fully re-renders each fire.
Injecting there is simpler and needs no new plumbing between the driver and the shim.

### Change set

- **`relay-automation/marathon-drive.sh`**
  - `debug_mantra_prior_attempts(root, lane_key_raw)` — read-only peek at `.tick/attempts/<lane>`'s
    line count via the existing `_lane_key` helper. Placed AFTER `lane_attempt_reset()`'s closing
    brace, deliberately OUTSIDE the `_lane_key`..`lane_attempt_reset` block `test/lane-attempt-cap.sh`
    asserts is byte-identical between `marathon-drive.sh` and `relay-drive.sh` — this GH-162 addition
    does not extend that mirror contract.
  - `debug_mantra_note(prior_count, phase_dir, mantra_file)` — empty output when `prior=0` (mirrors
    `rtl_drift_brief`'s "say nothing when there is nothing to say" convention, so a phase's first-ever
    fire renders byte-identical to before this feature existed); otherwise a short note citing the
    prior-attempt count and, if present, the last `ESCALATION.md` `reason:`.
  - Computed once, read-only, right after `RELAY_FILE`/`REL_RELAY` are set and BEFORE the Step 1
    render — well before `lane_attempt_gate`'s own Step 3 call, so the peek can never race the write.
    Injected as `${DEBUG_MANTRA_TEXT}` into the relay-file heredoc, right after the phase brief.
- **`relay-automation/DEBUG-MANTRA.md`** (new) — the four-step discipline (reproduce reliably → know
  the fail path → question the hypothesis → treat this round as a breadcrumb), written to point a
  headless builder at the harness's own `ESCALATION.md` + `### Round N` history as its breadcrumb
  trail, rather than asking for a new ledger.
- **`test/debug-mantra.sh`** (new, 14 cases) — asserts: no note on a phase's first-ever fire (and the
  brief still renders normally); the note appears and cites the correct count + `DEBUG-MANTRA.md` path
  once `.tick/attempts/<lane>` has a prior line; the note cites a real `ESCALATION.md` reason when
  present; the peek is genuinely read-only (never mutates the attempts file); and the GH-45
  byte-identical mirror block stays untouched by the new functions. Added to `validate.sh`.

### Verification

- `test/debug-mantra.sh`: 14/14 pass (new).
- `test/marathon-drive.sh` (55/55), `test/lane-attempt-cap.sh` (26/26), `test/marathon.sh` (17/17),
  `test/marathon-yaml.sh`, `test/swarm-preflight.sh` (87/87), `test/marathon-plan.sh` (58/58): all
  still green, no regressions. (`lane-attempt-cap.sh`'s one stderr syntax-error line from its
  `extract()` helper sourcing `relay-drive.sh`'s block is pre-existing — reproduced identically
  against a clean `origin/main` baseline via `git stash`, unrelated to this change.)
- `marathon-drive.sh` is not part of `skills/relay-automation/relay-pkg.tar.gz`'s manifest — no
  repackaging needed for this change.
- Full `./validate.sh`: same 4 pre-existing failures as GH-161's build (`archive-writers.sh`,
  `xyz-harness-hooks.sh`, `security-scan.sh`, `python:test_python_layer.py`), independently confirmed
  against a clean `origin/main` baseline — none touch this change's files.
