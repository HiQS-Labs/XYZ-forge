---
title: A pre-existing phases/ or relay-system/ ignore rule HALTs a marathon, and --dry-run cannot see it
status: Proposed (1-INBOX — not yet active)
created: 2026-08-07
owner: noel
gh_issue: 314
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/314
doc_type: bugfix
complexity: 2
risk: 3
effort: 2
phases: 1
ratings_provisional: true
reported_from: LTVera-Pandas (2026-07-28), aegis-sleuth-slack-bot (2026-08-07)
harness_commit: bed9a9f
non_goals:
  - forcing commits past a target repo's gitignore (`git add -f`) — that would silently publish
    transcripts on a public repo with nobody deciding to
  - relocating where marathon output lives, or building a centralized transcript archive (GH-30)
  - solving "a build marathon's relay thread must live inside the target repo" (GH-245/GH-289);
    that constraint is deliberate and stays
related:
  - GH-117 — precedent: --dry-run must probe preconditions before mutating state
  - GH-401 — --dry-run's relationship to phases/ is independently already wrong
  - GH-245 / GH-289 — why --target-root is not an escape hatch for BUILD turns
  - GH-440 — sibling: ensure_gitignore also misses /.tick/
  - GH-30 — optional centralized transcript archive (redirect relay-system/ out of foreign repos)
goal: >
  A marathon fired against a repo whose .gitignore covers phases/ or relay-system/ fails in
  seconds with a message naming every unaddable path, instead of after a full phase — and
  --dry-run reports the same thing. An escalation still records why a phase halted even when
  its own ESCALATION.md cannot be committed.
---

# GH-314 — A pre-existing ignore rule HALTs a marathon, and `--dry-run` cannot see it

> **1-INBOX capture**, not the active-work doc — no `## Status` table yet. On promotion to
> `PROJECT/2-WORKING/`, add the status table + per-phase QA gates and carry `gh_issue` forward
> (`PROJECT/PDDA.md` → GitHub issue intake).

## Symptom

`marathon_drive.py` unconditionally `git add`s three files into the target repo. If the target
ignores any of them, the phase dies with an unhandled `CalledProcessError` and the chain HALTs.
`--dry-run` passes clean beforehand, because it exits before the first `git add`.

## Why this doc exists

The issue was filed 2026-07-28 and sat with no capture doc and no ROADMAP entry, so it never became
work. It then cost a second operator a full afternoon on 2026-08-07. Parking it is the point.

## The write-set

| Call site | Path | Notes |
|---|---|---|
| `utils/py/marathon_drive.py:1233` | `phases/<lane>/RELAY.md` | in the original report |
| `utils/py/marathon_drive.py:956` | `phases/<lane>/ESCALATION.md` | **found 2026-08-07** — fires inside `escalate()` |
| `utils/py/marathon_drive.py:986` | `relay-system/<date>/marathon-<phase>-<time>.md` | in the original report |

Line numbers are `bed9a9f`; the original report cites `681`/`455` at `5dfef3b`.

## Environment

- **Observed from:** `LTVera-Pandas` (2026-07-28, `5dfef3b`) and `aegis-sleuth-slack-bot`
  (2026-08-07, vendored `source_commit=faf50e06131c`) — both vendored `.xyz/` installs
- **Runtime:** Python (`XYZ_PYTHON` unset → default)
- **Worker/CLI:** `codex` builder + `agy` reviewer, `tick` 0.2.0
- **Sandbox:** off

## Reproduction — deterministic

1. Vendor `.xyz/` into a repo whose `.gitignore` already covers `phases/` or `relay-system/`
2. `.xyz/relay-automation/marathon.sh --plan <plan> --pre-advance-cmd "<gate>" --dry-run` → **passes**
3. Same command without `--dry-run`

**Expected:** preflight verifies all three paths are addable and dies naming them, before any worker
is dispatched. `--dry-run` reports the same.
**Observed:** exit 1 mid-phase; later phases never start.
**Frequency:** every time — it is a `.gitignore` rule, not a race. Two repos, three call sites.

## Three findings beyond the original report

### 1. `escalate()` crashing destroys the halt record

`ESCALATION.md` is added at `marathon_drive.py:956`, inside the escalation handler. On 2026-08-07 the
run reached a *correct* escalation — codex built for 1h32m, the pre-advance gate caught a real bug —
and the handler then crashed on its own unaddable file. The operator got a stack trace instead of the
reason the phase halted. This path runs when something has already gone wrong, so it should be the
most failure-tolerant code in the file, not the least.

### 2. Serial discovery costs one phase per landmine

Un-ignoring only `RELAY.md` bought exactly one more run before crashing on `ESCALATION.md`, with the
`relay-system/` transcript still queued behind it. Three fixes, three runs, ~1.5h each.

### 3. Public targets have no supported configuration

The intuitive workaround — relay in a private harness, code in the target via `--target-root` — is
rejected by design for BUILD turns (GH-245/GH-289: a build turn needs a writable relay file for its
findings). Combined with this bug, a repo that deliberately does not track harness output cannot run
a build marathon at all. `aegis-sleuth-slack-bot` ignored `phases/` as *"internal PDDA/agent phase
mechanics"* and `relay-system/` as *"raw AI reviewer transcripts, high leak surface"*; running a
marathon there required reversing both documented decisions and publishing the transcripts.

## Impact

Not blocking — the workaround is to narrow the target's ignore rules to those three filenames
(verified working: the next run reached escalation and committed `ESCALATION.md`). The cost is
disclosure on public targets, plus roughly a phase of wall-clock per landmine discovered.

## Phase 0 — Diagnose & scope

> Discovery phase: its findings are written **back into this doc** before its QA gate can pass
> (`PROJECT/PDDA.md` → Discovery & spike phases).

### Checklist

- [ ] Reproduce in a fixture repo that ignores `phases/` (not just from a consumer report)
- [ ] Decide the owner: `xyz-vendor.sh ensure_gitignore` (install-time), a marathon preflight
      (run-time), or both — a repo can grow an ignore rule *after* vendoring, which argues for
      run-time as the authority
- [ ] Enumerate the write-set from the code rather than from reports, so a fourth call site cannot
      hide; assert the list is complete with a test that fails when a new `git add` is introduced
- [ ] Make `escalate()` degrade instead of raising when its own file cannot be committed
- [ ] Wire the same check into `--dry-run` (cf. GH-117)
- [ ] Decide whether to document "public targets must publish transcripts" or offer a real
      alternative (cf. GH-30)

### QA checklist — Phase 0

- [ ] A fixture repo ignoring all three paths fails in seconds, naming all three at once
- [ ] `--dry-run` on that fixture reports the same failure the real run would hit
- [ ] An escalation whose `ESCALATION.md` cannot be committed still records the halt reason
- [ ] No path force-adds past a target's gitignore
- [ ] The fix composes with the existing preflight rather than adding a parallel one (`/ponytail`)
