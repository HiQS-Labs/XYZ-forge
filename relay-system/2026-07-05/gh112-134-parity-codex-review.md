# RELAY · GH-112 #134 Python parity — independent Codex review
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-07-05.
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
     (`[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`), each with a concrete fix → set a **Verdict**
     (Approved | Changes requested | Blocked). Do **not** edit the artifact; only append findings here.
   - **Producer:** log a disposition for every open finding (Implemented / Modified / Declined + why),
     make the change, then add new work.
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(gh112-134-parity-codex-review): <role> r<N>`); no push. **Stop** and report one line.

## Setup
- Artifact under review: `utils/py/marathon_drive.py` and `utils/py/swarm_preflight.py` — both already
  present, tracked, and merged to `main` (commit `cd4c215`, 2026-07-05 08:04, "feat(gh-112): port #134
  reliability fixes into the opt-in Python layer"). Read them directly from the repo tree; nothing is
  seeded separately.
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-07-05

### Why this review exists
This commit was **built by a marathon-drive lane with codex as the builder**, then verified by that
same lane's embedded agy-reviewer step before landing. That is a real gate, but it is not an
independent second opinion — same session, same lane. Per GUIDING-PRINCIPLES.md §12 ("Independent
Verification — the agent that produces a turn must not be the sole grader of its own quality") and the
repo's broader posture that changes near the containment core are "usually broader than they look"
(§AGENTS.md "Repo-specific rails"), this commit gets one now: a fresh, separately-invoked `/relay-xyz`
pass, with **codex now in the REVIEWER seat** (not the builder seat it held originally) — the opposite
role, for a genuinely independent read.

### What changed (context for the reviewer)
`cd4c215` ported three Bash reliability fixes (GH-106, GH-117, GH-108) into the opt-in `utils/py/`
Python layer so it doesn't drift from Bash (`XYZ_PYTHON=1` still defaults off — this is a parity port,
not a promotion):
- `marathon_drive.py`: added a builder+reviewer binary probe that must run **before any tick mutation**
  (GH-117 — the point of the original bug: a missing binary used to fail *after* the tick task was
  already seeded and spent, with no recovery except a fresh relay-task id).
- `swarm_preflight.py`: added `is_fs_touching` / `is_genuine_ref`-style gate-scoping helpers mirroring
  `swarm-preflight.sh` (GH-108/126/127 markers) — these decide what counts as a filesystem-touching test
  needing the "do not run in-turn" guidance, and what counts as a genuine covering-test reference vs. a
  path that merely appears in file text.
- Claims (from the commit body, unverified by this relay — confirm or refute): GH-107's containment
  exemption is "already inherited via rtl.py" (i.e. this port didn't need to touch it) and
  `relay-turn-lib.sh` (the Bash containment core) is untouched.

### Definition of Done
Grade against GUIDING-PRINCIPLES.md + AGENTS.md, prioritizing containment > coordination correctness >
signal quality > implementation speed, specifically:
1. **Containment held**: no path in the new/changed Python code writes outside an allowlist, self-commits
   mid-turn, or could orphan a peer's concurrent commit. If GH-107's exemption logic really is untouched
   (inherited via `rtl.py`, not reimplemented here), say so explicitly with a file:line pointer proving it.
2. **Parity is real, not cosmetic**: the `is_fs_touching` / `is_genuine_ref` helpers in
   `swarm_preflight.py` actually mirror `swarm-preflight.sh`'s GH-108/126/127 logic (same gate-scoping
   decisions on the same inputs), not just similarly-named functions with different behavior.
3. **The binary-probe fix lands before the failure mode it fixes**: `marathon_drive.py`'s builder/reviewer
   probe genuinely runs before the first tick-mutating call on both `--dry-run` and a live run — re-check
   this the way GH-117's original Bash fix was verified, not just that a probe function exists somewhere.
4. **No regression against `relay-turn-lib.sh`**: confirm (don't just trust the commit message) that the
   Bash containment core is byte-identical / untouched by this commit.
5. **Least code that clears the bar** (GUIDING-PRINCIPLES §7): flag any part of the ~166-line diff that
   looks like more machinery than the three ported fixes actually require.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Round 1 · Reviewer · codex
- [Blocker] `utils/py/swarm_preflight.py:304-326` does not mirror the shell's inferred-path containment boundary. The Bash source sanitizes every inferred test/helper through `sanitizeInferredPath` before widening `ALLOW_PATHS` (`utils/swarm-preflight.sh:346-378`), rejecting `test/..` escapes and generated entries like `__pycache__/x.pyc`; the Python port adds raw `rel_path`/`helper` values as soon as `is_genuine_ref` passes. In `XYZ_PYTHON=1` mode that means the same contract can widen beyond repo-local real test files, which breaks DoD #1 and #2 on containment/parity. Fix: port the shell sanitizer into Python and gate both inferred tests and inferred helpers through it; add the Python-layer regression equivalent of `test/swarm-preflight.sh:780-832` (GH-137/T35b).
- [Pass] `utils/py/marathon_drive.py:243-245` probes the builder and reviewer binaries before the dirty-workspace scan (`:261-276`), before relay rendering (`:278-333`), and before the first tick-mutating calls (`:377-379`). The same ordering also holds on `--dry-run` because the dry-run exit is later at `:335-338`. No change needed.
- [Pass] GH-107's containment exemption is still inherited, not reimplemented: the Python bridge sources `relay-automation/relay-turn-lib.sh` and routes enforcement through it (`utils/py/rtl.py:26-58`), while the exemption logic itself remains solely in `relay-automation/relay-turn-lib.sh:241-269` and is consumed in the off-lane scan at `:409`. No change needed.
- [Should] I could confirm the current Python path still delegates to `relay-turn-lib.sh`, but under this turn's no-`git` constraint I could not independently produce a commit-scoped receipt that `cd4c215` left `relay-turn-lib.sh` byte-identical/untouched. Fix: when you answer this finding, attach a deterministic receipt for that commit (for example the commit's name-only diff or equivalent CI artifact) so DoD #4 is explicitly closed instead of inferred from the working tree.

**Verdict:** Changes requested

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
