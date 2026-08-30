# Daybreak · Wave 1 — the three offline lenses

Release **0.7.2 "Daybreak"** · marathon `mar-01M0EC2ZXJCCJ88KASQPDBTBJ9` · tracking
[#77](https://github.com/HiQS-Labs/XYZ-forge/issues/77).

Build lenses **2, 3, 7** in `skills/standup/collect.sh`. These three are deliberately first: they are
pure-local reads with no network and no `gh`, so they are the cheapest possible proof that the
harness holds before the two `gh` lenses arrive in wave 3.

## Work units

| Issue | Lens | Bounded read |
|---|---|---|
| [#79](https://github.com/HiQS-Labs/XYZ-forge/issues/79) | 2 · working tree | `git status --porcelain`, excluding **untracked** paths under `PARKED/` |
| [#80](https://github.com/HiQS-Labs/XYZ-forge/issues/80) | 3 · branch | `git rev-list --left-right --count @{upstream}...HEAD`, trunk fallback on exit 128 |
| [#81](https://github.com/HiQS-Labs/XYZ-forge/issues/81) | 7 · ROADMAP ledger | `python3 utils/py/releases_app.py roadmap sync --dry-run` |

## The transform — identical for all three

1. Implement the bounded read in `skills/standup/collect.sh`, honouring `--fixture <dir>`.
2. Emit candidates carrying all six required fields — `key`, `what`, `evidence_type`,
   `evidence_payload`, `staleness`, `close` (plus `close_kind`, and `check` when parkable).
   **A lens that cannot supply all six does not emit the candidate** — it sets
   `status: degraded` with its `D` id. Silence is the one unacceptable outcome.
3. Add `skills/standup/fixtures/lens-<n>/`.
4. Add two assertions to `test/gh77-standup-triage.sh`: the candidate classifies to its expected
   tier, and the lens degrades loudly with its `D` id when the read is unavailable.

## Output contract `collect.sh` must satisfy

```json
{"repo": {"branch": "<name>"},
 "lenses": {"2": {"status": "ok|degraded", "degraded_id": "D<n>|null", "candidates": [ … ]}}}
```

`triage.py --lenses <file> --dry-run` is the consumer. Read it — it is the authority on field names
and on what each lens's `live_state` payload must contain, because suppression hashes that payload.

## Pass condition — machine-checkable, per unit

```
skills/standup/collect.sh --fixture skills/standup/fixtures/lens-<n>   # valid JSON
python3 skills/standup/triage.py --lenses <that output> --dry-run      # no D5, exit 0
bash test/gh77-standup-triage.sh                                       # green
```

## Three things that are already settled — do not relitigate them

- **Lens 2 excludes only *untracked* paths under `PARKED/`.** A blanket exclusion was tried and
  rejected in review: it hid an operator's uncommitted edit to a tracked park file forever. The
  self-feed only needs the untracked half, because a modified tracked file closes with
  `git add` + commit and cannot loop.
- **Lens 3 never claims "unpushed" without an upstream.** Divergence from the trunk does not
  establish push state. With no upstream, carry `upstream-state: no-upstream`, take **unknown**
  staleness, and make the close an `inspect:` action — never a bare `git push` at an unresolved
  remote.
- **`close` is never executed.** Only a park record's read-only `check` probe runs during collection.

## Definition of done for this phase

All three lenses implemented, three fixture directories, six new assertions, and
`bash validate.sh --subsystem releases` green. `triage.py` is **not** modified by this phase — if a
lens seems to need a change there, that is a finding to report, not an edit to make.

## Working rules for the BUILDER

The first fire of this phase (2026-08-20) escalated at exit 6 before any review ran, and two of the
three causes were things nobody told the builder:

- **`skills/standup/fixtures/` is a DIRECTORY lane** — spelled with the trailing slash, so the whole
  tree beneath it is yours this turn. The first fire spelled it without one, which was unmatchable by
  construction and reverted the fixtures as off-lane (GH-90, fixed in `a350b2d`).
- **Do not leave scratch files in the tree.** Probe files, scratch scripts, and one-off outputs are
  off-lane no matter how harmless, and a single stray path at the repo root fails the whole turn. Use
  `$TMPDIR`. The reviewer has always been told this; the builder had not been, and the first fire
  littered the repo root as a result.

## What this phase is actually testing

Three lanes editing **one shared `collect.sh` and one shared suite**. That collision surface is why
this is a marathon rather than a task. A lane clobbering another's edit, a stale worktree, an
unexpected driver-lock interaction — those are the deliverable, per `AGENTS.md` → Repo-specific
rails, rule 4. **Report what broke; do not smooth it.** A clean run that teaches nothing is the
weaker result.
