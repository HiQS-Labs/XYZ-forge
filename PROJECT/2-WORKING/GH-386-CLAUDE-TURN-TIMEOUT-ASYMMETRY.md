---
gh_issue: 386
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/386
title: "claude-turn caps at 600s while every other builder defaults to 900s, and the packet's computed RELAY_TURN_TIMEOUT_S is never exported — a phase sized for 900 ran at 600"
status: "2-WORKING — captured 2026-08-10 for release 0.3.0 Nightwatch. Both halves independently re-verified against source on 2026-08-10; both still reproduce. No acceptance criteria existed on the issue — authored onto this doc in a separate labelled section. Awaiting preflight."
created: 2026-08-10
updated: 2026-08-10
owner: noel
doc_type: project
release: "0.3.0 Nightwatch"
complexity: 2
risk: 2
effort: 2
phases: 1
ratings_provisional: true
roadmap_exempt: false
related:
  - "#382 — the run this issue's own evidence (`p5-gh139`) was observed on; issue #386 cites it as provenance for the killed-at-600 incident."
  - "#320 — the twin-drift fix whose Python-aligned-to-Bash resolution is the *documented lineage* of claude-turn's 600 value (confirmed via the issue's own 2026-07-31 comment, see below). This lane does not reopen #320 — twin parity is holding and is out of scope here."
  - "#387 — adjacent, NOT this doc. #387 is about what happens AFTER a turn is killed at its cap (a partial, mid-edit commit is gated and treated as if the phase completed). #386 is about WHY the kill happens at the wrong threshold in the first place: an asymmetric default (600 vs 900) and a computed suggestion that never reaches the run. Fixing #386 makes the kill less likely to fire on an undersized cap, but does nothing about what the harness does once a kill *does* fire — that is #387's defect, not this one's."
non_goals:
  - "Changing agy/codex/aider/pi's 900s default. All four are unchanged and out of scope — only claude-turn's asymmetry is in question."
  - "Reopening or re-verifying GH-320's twin-parity fix. Confirmed still holding (Bash/Python agree for all five builders) and not touched here."
  - "Inventing new host-aware or LOC-aware timeout sizing logic. `swarm-preflight` already computes a number; this lane is about making that number reach the run, not about improving the heuristic."
  - "Fixing #387's post-kill commit/gate behavior. Explicitly out of scope, see related."
goal: >
  claude-turn's timeout default (600s) is one of two fixed inputs to a wall-clock kill that has
  already destroyed a phase's headroom in production (#382). The second input — swarm-preflight's
  own computed per-phase budget — never reaches the run at all, so an operator reading "900" in the
  packet cannot rely on 900 actually being the cap. Fix both halves so the number an operator reads
  in a preflight packet is the number that governs the phase, and so claude's outlier default either
  disappears or is explained where the next reader will see it.
---

# GH-386 · claude-turn's 600s cap is an unexplained outlier, and swarm-preflight's suggested budget never reaches the run

## Status

| What was just completed | What's next |
|---|---|
| Captured 2026-08-10. Both halves of the issue re-verified independently against current source (not the issue's own line citations, several of which have drifted — see "The defect"). Neither half is fixed; both reproduce today. Issue has no `## Acceptance` section — criteria authored onto this doc in a separately labelled section, informed by the verification below and a 2026-07-31 collaborator comment on the issue that supplies real provenance for the 600 value. | Preflight, then fire. Part (b)'s fix must not touch `relay-automation/marathon.sh` / `utils/py/marathon_drive.py` (the running driver) — see Reversibility & blast radius. |

**Issue:** https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/386

## The defect

Both halves were re-verified against the current tree on 2026-08-10 (branch `feature/agent-devtools-fuzzing`, confirmed identical to `development` for every file cited below via `git diff development -- <files>` → no output). **Both still reproduce.**

### Half (a) — claude-turn's cap is still 600s while every other builder is 900s

Confirmed current defaults, all five builders, both twins:

| builder | Bash default | Python default |
|---|---|---|
| `claude` | `relay-automation/claude-turn.sh:200` → `${RELAY_TURN_TIMEOUT_S:-600}` | `utils/py/claude-turn.py:97` → `600` |
| `agy` | `relay-automation/agy-turn.sh:208` → `900` | `utils/py/agy-turn.py:205` → `900` |
| `codex` | `relay-automation/codex-turn.sh:145` → `900` | `utils/py/codex-turn.py:73` → `900` |
| `aider` | `relay-automation/aider-turn.sh:242` → `900` | `utils/py/aider-turn.py:135` → `900` |
| `pi` | `relay-automation/pi-turn.sh:164` → `900` | `utils/py/pi-turn.py:105` → `900` |

`claude` is still the sole outlier. The Bash/Python twins agree at 600 (GH-320's twin-parity fix is
holding — `test/gh320-twin-timeout-parity.sh` checks each twin pair against its own header, not
against the other builders, so it cannot and does not catch this asymmetry).

**Stale line citations in the issue** (values are correct, several line numbers have drifted since
the issue was filed, presumably from intervening commits):
- `utils/py/claude-turn.py:90` (issue) → now `:97`.
- `utils/py/agy-turn.py:161` (issue) → now `:205` (44-line drift — the largest of the five).
- `utils/py/codex-turn.py:72` (issue) → now `:73`.
- `utils/py/aider-turn.py:135` (issue) → unchanged, exact match.
- `utils/py/pi-turn.py:99` (issue) → now `:105`.
- `relay-automation/claude-turn.sh:200` (issue) → unchanged, exact match.

The header comments at `relay-automation/claude-turn.sh:69-70` and `utils/py/claude-turn.py:93-96`
still only explain the GH-320 twin-parity requirement ("this default MUST match the Bash twin's...").
Neither says why `claude` is 600 while the other four are 900 — confirmed by reading both files in
full; no rationale text exists at either site today.

**New evidence not in the issue body:** a 2026-07-31 comment on the live issue (from `mrtwebdesign`,
fetched 2026-08-10 via `gh issue view 386 --json comments`) establishes that 600 is **not** an
accident. GH-320 found the *Python* turn-takers had all drifted to a 300s default while their Bash
twins/headers said 900/900/600 (agy, codex, claude respectively); the fix aligned Python to Bash,
which for `claude-turn` means today's 600 was inherited from the **pre-existing Bash header value**,
not introduced by GH-320. That makes 600 deliberate *at the file level* — but, per the same comment,
GH-320's scope was twin agreement, not cross-shim consistency, so it "neither introduced nor examined
the difference — it preserved it." The open question the issue asks is therefore unchanged: no file
states **why** claude should be lower than the other four.

### Half (b) — the packet's computed RELAY_TURN_TIMEOUT_S is still never exported

Confirmed: `swarm-preflight` computes a per-phase suggestion and writes it into `packet.md` as text
only —

- `utils/py/swarm_preflight.py:1502-1516` computes `gh39_timeout` (300/600/900 by LOC/artifact-count
  thresholds) and line `:1535` renders `Suggested turn budget: RELAY_TURN_TIMEOUT_S={gh39_timeout}...`
  into the packet body.
- `utils/swarm-preflight.sh:884-896` computes the Bash-twin equivalent (`GH39_TIMEOUT`) and line
  `:942` renders the same string into `packet.md`.
- (Issue cited `utils/py/swarm_preflight.py:883` — now `:1535`, a 652-line drift, the file has grown
  substantially since the issue was filed. `utils/swarm-preflight.sh:942` is unchanged, exact match.)

**Nothing reads that computed number back out of the packet.** Confirmed by searching every
`.sh`/`.py` file in the repo for `turn_timeout_s` / `RELAY_TURN_TIMEOUT_S`: `utils/marathon-plan.sh`
and its Python engine (`utils/py/marathon_plan.py`, `utils/py/_marathon_plan.py`) — the tools that
actually build a `MARATHON.yaml` from a preflight packet — contain **zero** references to either
name. The packet's suggested number has no path into the plan.

**One nuance the issue's phrasing slightly overstates:** `relay-automation/marathon.sh` does have an
export mechanism (`:193` reads a `turn_timeout_s` field per phase out of `MARATHON.yaml`; `:236-238`
exports it as `RELAY_TURN_TIMEOUT_S` when invoking `marathon-drive.sh`, but **only if that YAML field
is non-empty**). Real plans do use it — e.g.
`PROJECT/2-WORKING/MARATHON-2026-08-10-NIGHTWATCH-WAVE-2/MARATHON.yaml:113,121` both set
`turn_timeout_s: 900` by hand. So "marathon.sh does not read the packet's suggestion" is true in the
sense that matters (nothing carries the *preflight-computed* number into that field automatically),
but it is not accurate to say marathon.sh has no export path at all — it has one, gated on a plan
author manually transcribing the packet's number into YAML. `utils/py/marathon_drive.py` confirmed to
have **zero** `RELAY_TURN_TIMEOUT_S` references — it only inherits whatever `marathon.sh` exported
into its environment, exactly as the issue says.

**"the 300s default" is still stale.** Confirmed present verbatim today at both sites:
`utils/py/swarm_preflight.py:1535` and `utils/swarm-preflight.sh:942` both still read "...a build that
also edits tests needs headroom over the 300s default". No turn script defaults to 300 anywhere in
the current tree (claude=600, all others=900) — confirmed by the table in half (a).

**Observed-impact claim (`p5-gh139`, phase artifacts `scripts/health_issue_reporter.py` +
`tests/test_health_issue_reporter.py`):** could not be independently verified — no
`MARATHON.yaml`/plan doc referencing `p5-gh139` or those two artifacts exists anywhere in the current
tree (`git grep` for both turned up nothing). This is consistent with the packet/plan for that run
having been ephemeral or living outside this checkout, not with the claim being false; noted as
**unverified**, not disproven. The mechanism that would produce exactly this symptom (a phase with an
unset `turn_timeout_s` YAML field, run with `--builder claude`) is independently confirmed to exist
and behave as described.

## Acceptance

*Issue #386 (fetched fresh via `gh issue view 386 --json body,comments` on 2026-08-10, not just the
locally cached copy — both match byte-for-byte) has **no `## Acceptance` section**. Its body is TL;DR
/ The asymmetry / The suggestion that goes nowhere / Observed impact / Suggested fix / Related — a
"Suggested fix" bullet list, not a checklist of acceptance criteria. Per this repo's drafting
convention, nothing is invented inside this heading; criteria are authored in the separate section
below instead.*

(none — the issue supplies no acceptance criteria)

## Acceptance — authored (issue has no criteria)

*Authored 2026-08-10 from the verified defect above and the issue's own "Suggested fix" section,
sharpened by the 2026-07-31 collaborator comment on the live issue.*

- [ ] **Half (a) resolved one of two ways, decided explicitly rather than left ambiguous:** either
  `claude-turn`'s default is raised to 900 to match `agy`/`codex`/`aider`/`pi` (both twin sites,
  `relay-automation/claude-turn.sh:200` and `utils/py/claude-turn.py:97`), **or** it stays at 600 and
  a rationale comment is added at both twin header sites (`relay-automation/claude-turn.sh:69-70`,
  `utils/py/claude-turn.py:93-96`) stating why `claude` is intentionally lower than the other four —
  not merely restating the existing GH-320 twin-parity requirement, which explains twin agreement but
  not the cross-shim difference.
- [ ] If the Bash header (`relay-automation/claude-turn.sh`) is the one edited, the change carries a
  `Frozen-twin-exception:` trailer per `test/gh308-frozen-twin-guard.sh`'s `TWINS` list (`claude-turn`
  is twin #3 of 12); the Python file is the default edit target and needs no exception.
- [ ] `test/gh320-twin-timeout-parity.sh` still passes unchanged — it asserts twin-vs-twin agreement,
  which this fix must not break regardless of which resolution is chosen for half (a).
- [ ] **Half (b): the value swarm-preflight computes and prints as `RELAY_TURN_TIMEOUT_S={gh39_timeout}`**
  (`utils/py/swarm_preflight.py:1502-1516,1535`; Bash twin `utils/swarm-preflight.sh:884-896,942`) is
  wired through to the value that actually governs the phase's turn, without requiring a human to
  hand-copy the packet's number into `MARATHON.yaml`. The natural seam is
  `utils/marathon-plan.sh` / `utils/py/marathon_plan.py` / `utils/py/_marathon_plan.py` (the tools that
  already build a phase's `MARATHON.yaml` from a preflight packet and currently contain zero
  references to `turn_timeout_s`) auto-populating each phase's `turn_timeout_s:` field using the same
  LOC/artifact-count heuristic swarm-preflight already computes — reusing the number, not
  reimplementing the heuristic a third time.
- [ ] **The fix does not touch `relay-automation/marathon.sh` or `utils/py/marathon_drive.py`.** Both
  are the running driver (see Reversibility & blast radius); a fix that requires editing either must
  ship as a direct PR, not a marathon lane, and this doc's preferred seam (`marathon-plan.sh`) avoids
  the problem entirely by populating the YAML field marathon.sh already knows how to read
  (`relay-automation/marathon.sh:193,236-238`) rather than changing how marathon.sh reads it.
- [ ] Failing the above (i.e., if wiring the value through is judged out of scope for this lane), the
  "Suggested turn budget" line is dropped entirely from both packet templates
  (`utils/py/swarm_preflight.py:1535`, `utils/swarm-preflight.sh:942`) rather than left in place — a
  suggestion the harness ignores is worse than no suggestion, per the issue's own suggested fix.
- [ ] The stale "...needs headroom over the 300s default" phrase is corrected at both sites
  (`utils/py/swarm_preflight.py:1535`, `utils/swarm-preflight.sh:942`) to name a default that exists
  in the current tree, or reworded to not assert a single universal default (claude is 600, the other
  four are 900).
- [ ] `test/swarm-preflight.sh`'s existing `RELAY_TURN_TIMEOUT_S=` assertions (T1b/T1d/T16, lines
  90-113) continue to pass unchanged — this lane wires the number through, it does not change
  swarm-preflight's sizing heuristic or its packet output format.

## Litmus tests

- **A fix that only changes the number without leaving a trace of the decision is indistinguishable
  from drift** — the whole point of half (a) is that the 600-vs-900 choice must be legible to the
  next reader, whichever way it's resolved. `git log -p` on the touched lines should show either the
  new value or a comment, not a bare numeric edit.
- **A fix that makes `marathon-plan.sh` populate `turn_timeout_s` but never actually causes
  `marathon.sh` to export `RELAY_TURN_TIMEOUT_S` for a real phase is incomplete.** Check a freshly
  generated `MARATHON.yaml` phase for a non-empty `turn_timeout_s:` field, then check that
  `relay-automation/marathon.sh:236` fires for that phase (`turn-timeout=Ns` appears in its log line,
  `:208`).
- **`test/gh320-twin-timeout-parity.sh` and `test/swarm-preflight.sh` T1b/T1d/T16 are the regression
  floor**, not the target — passing them proves nothing new shipped, only that nothing old broke.
- **A fix that touches `marathon.sh`/`marathon_drive.py` at all should be treated as a signal the
  wrong seam was chosen**, not as something to isolate via phase boundaries — per this repo's
  self-modification rule, phase isolation contains a driver change but the constraint here is
  categorical, not risk-graded.

## Reversibility & blast radius

**Small for half (a), small-to-medium for half (b), contingent on which seam is chosen.**

- Half (a) touches only `relay-automation/claude-turn.sh` (frozen twin, needs a
  `Frozen-twin-exception:` trailer if edited) and/or `utils/py/claude-turn.py` (its authoritative
  Python twin). Neither is the driver or the kernel. Fully revertible by reverting the commit; no
  behavioral surface beyond claude-turn's own timeout.
- Half (b), **if fixed at the recommended seam** (`utils/marathon-plan.sh` /
  `utils/py/marathon_plan.py` / `utils/py/_marathon_plan.py`), is also small and revertible —
  `utils/marathon-plan.sh:utils/py/marathon_plan.py` is a frozen-twin pair (twin #12 of 12 in
  `test/gh308-frozen-twin-guard.sh`); the same `Frozen-twin-exception:` rule applies if the Bash side
  is touched.
- **If half (b) is instead fixed by editing `relay-automation/marathon.sh` or
  `utils/py/marathon_drive.py`, it cannot ship as a marathon lane at all.** Both are explicitly the
  running driver — a lane whose write-set includes the code gating its own run "would edit the code
  gating its own run" and must ship as a direct PR, per this repo's self-modification constraint.
  `marathon.sh` has no Python twin (confirmed absent from `test/gh308-frozen-twin-guard.sh`'s `TWINS`
  array) and is not itself frozen, but the driver restriction is independent of twin status.
- Dropping the "Suggested turn budget" line entirely (the fallback acceptance criterion) is the
  lowest-blast-radius option of all — a one-line deletion at two sites, fully revertible, no
  behavioral change anywhere.

## Swarm Preflight Contract

```json
{
  "target":        { "repo": ".", "ref": "development" },
  "gate":          "bash validate.sh",
  "fix_probes":    [
    { "type": "grep_absent", "path": "relay-automation/claude-turn.sh", "pattern": "GH-386" },
    { "type": "grep_absent", "path": "utils/py/claude-turn.py", "pattern": "GH-386" },
    { "type": "grep_present", "path": "utils/py/swarm_preflight.py", "pattern": "the 300s default" },
    { "type": "grep_present", "path": "utils/swarm-preflight.sh", "pattern": "the 300s default" }
  ],
  "artifacts":     [
    "relay-automation/claude-turn.sh",
    "utils/py/claude-turn.py",
    "utils/marathon-plan.sh",
    "utils/py/marathon_plan.py",
    "utils/py/_marathon_plan.py",
    "utils/py/swarm_preflight.py",
    "utils/swarm-preflight.sh"
  ],
  "artifacts_new": [],
  "remediation":   { "source": "issue #386", "criteria": "resolve the claude-turn 600-vs-900 asymmetry explicitly (value change or documented rationale) and wire swarm-preflight's computed RELAY_TURN_TIMEOUT_S through to the run without editing relay-automation/marathon.sh or utils/py/marathon_drive.py — ranking summary only, NOT the definition of done (that is the authored ## Acceptance block above)" },
  "lanes": { "agy_safe": ["utils/py/claude-turn.py", "utils/py/marathon_plan.py", "utils/py/swarm_preflight.py"], "orchestrator_only": ["relay-automation/claude-turn.sh", "utils/marathon-plan.sh", "utils/swarm-preflight.sh"] }
}
```

**Probe polarity** (probes detect the **bug**, not the fix): the two `grep_absent` probes report
half (a) as still required while no comment mentioning `GH-386` exists at either `claude-turn` twin
site — this repo's convention is to tag a resolved cross-file question with the issue number in a
comment (as GH-320's own comments do), so a marker's absence means the decision (raise-to-900 vs
documented-600) has not yet been made and recorded. The two `grep_present` probes report half (b)'s
stale-default sub-defect as still required while the literal string "the 300s default" remains in
either packet template — once corrected or removed, the probes stop reporting and that portion of the
lane is no longer fireable, which is intended, not a defect. Note these four probes cover the
easiest-to-verify sub-parts of each half; the harder-to-probe portion of half (b) (whether the
computed number actually reaches `marathon.sh`'s export) is caught by the litmus tests, not by a
grep, because it depends on which seam the fix chooses.

## Provenance

Filed from a direct code read (both halves demonstrated by file:line quotes in the issue body) and
the `p5-gh139` incident on the run tracked by #382. Strengthened by a 2026-07-31 collaborator comment
on the live issue that traces the 600 value's lineage to GH-320's twin-alignment fix, establishing
that the value is deliberate at the file level even though its cross-shim rationale remains
unrecorded. Captured to `2-WORKING` 2026-08-10 for release 0.3.0 Nightwatch. Both halves independently
re-verified against the current tree the same day; neither is fixed.
