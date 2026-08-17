---
title: "Ballast 0.7.0 — Wave 1 phase brief (#14 atomic event append · #4 gate travels with clones)"
status: active
created: 2026-08-16
updated: 2026-08-16
owner: orchestrator (Claude Code)
doc_type: project
goal: >
  Drive Ballast wave 1 — the two disjoint lowest-ease lanes (#14, #4) — as one marathon phase:
  build (agy), review (codex), adjudicate (orchestrator), merge on operator clearance.
roadmap_exempt: true
---

# Ballast 0.7.0 — Wave 1 phase brief (#14 atomic event append · #4 gate travels with clones)

Subordinate planning artifact for the Ballast release (RELEASES.md 0.7.0 block owns scope; the
five member lanes each have their own capture doc and ROADMAP pointer — this brief is exempt from
a ledger line of its own for that reason).

## Status

| What was just completed | What's next |
|---|---|
| Wave assignment fixed by the orchestrator's overlap check (#15/#10 serialized over validate.sh); dry-run render 2026-08-16 | Operator decides whether to fire; on go, drive this brief with marathon-drive (builder agy, reviewer codex, round-cap 5, require-clean) |

Release: Ballast (0.7.0), frozen manifest #14 #15 #4 #10 #3. This wave: **#14 and #4** — the two
lowest-ease lanes with fully disjoint artifacts (`src/events.js` + `test/unit/` vs `README.md` +
`githooks/install.sh`). Lanes #15 and #10 are deliberately NOT in this wave: both edit
`validate.sh` and are serialized into waves 2 and 3 respectively. Lane #3 is NOT FIRED — its
preflight verdict is STALE (the defect appears already landed on main; operator decision pending).

Standing rules for every Ballast lane (from the release brief):

- Builder: **agy**. Reviewer: **codex**. The orchestrator adjudicates and merges; the operator
  decides whether to fire at all.
- The gate is `bash validate.sh`, run in a **disposable full clone at a durable location** — never
  in the primary clone, and never under `/tmp` (a clone under /tmp fails
  `gh388-run-log-durability`'s own-root durability classification; observed 2026-08-16).
- **Every fix ships a recorded negative control under `test/baselines/`** showing the check
  failing when the fix is reverted. A check never observed failing is not evidence.
- Acceptance criteria are the GitHub issue's, verbatim; deviations must be declared in the
  capture doc's `## Acceptance — deviations from the issue` section. Preflight re-fetches the
  issue and hard-fails on unexplained divergence.
- Before committing: `bash test/gh308-frozen-twin-guard.sh --check --staged`. No frozen-twin
  edits without an exception trailer; no new `.sh` under `utils/` or `relay-automation/`.
- A waiver names the failed criterion, the owner, the reason, and the follow-up issue. Silence
  is not a waiver.

## Lane #14 — atomic event append

Issue: https://github.com/HiQS-Suite/XYZ-forge/issues/14 · Capture:
`PROJECT/2-WORKING/GH-14-ATOMIC-EVENT-APPEND.md` (contract inside, probes bug-polarity).

Fix shape (from the issue): `appendEvent` writes to a temp name the reader cannot select
(`.tmp` does not match `readAllEvents`'s `.endsWith('.jsonl')` filter), then `renameSync` into
place — same directory, same filesystem, atomic. After this, a `.jsonl` that exists is always
complete. `#5`'s quarantine, if retained, layers on top ONLY after atomic writes, with its own
test distinguishing a genuinely corrupt file from a young one. The two `test/unit/events.test.js`
cases deferred from PR #7 (corrupt-file quarantine, empty-file skip) are re-authored here against
atomic writes. Healthy-path event bytes unchanged.

Artifacts: `src/events.js`, `test/unit/events.test.js`,
`test/baselines/GH-14-negative-control.md` (new). Do not touch `validate.sh` (waves 2-3 own it).

## Lane #4 — the gate travels with the repo, not just with the clone

Issue: https://github.com/HiQS-Suite/XYZ-forge/issues/4 · Capture:
`PROJECT/2-WORKING/GH-4-GATE-TRAVELS-WITH-CLONES.md`.

Fix shape: surface an ungated clone in-band — a committed marker or first-run check that warns
when the hook wiring is absent, naming `bash githooks/install.sh` as the one-command fix — and
make the README quickstart state the install step is a correctness requirement, not optional
setup. The fix is LOCAL: hosted CI re-arm is #16, an explicit non-goal. A push cannot be locally
refused with no hook installed (git reads hooks from `.git/hooks`, which does not travel with a
clone) — the deliverable is that the ungated state stops being invisible; state the limit, don't
paper over it. If the design genuinely needs `validate.sh` or `ci-local.sh`, STOP and report:
those paths belong to lanes #15/#10 and would force re-serialization.

Artifacts: `README.md`, `githooks/install.sh`, `test/baselines/GH-4-negative-control.md` (new).

## Exit criteria for this wave (per lane)

- #14: issue acceptance verbatim (5 criteria) + negative control recorded.
- #4: issue acceptance verbatim (4 criteria + 1 declared addition) + negative control recorded.
- Both: `bash validate.sh` green in the disposable clone; capture-doc Status tables updated;
  ROADMAP pointer lines updated to reflect progress (pointer-only).
