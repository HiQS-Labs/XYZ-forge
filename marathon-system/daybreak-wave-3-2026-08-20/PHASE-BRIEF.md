# Daybreak · Wave 3 — Open PRs & Issue state (lenses 4, 5 — the gh lenses)

Release **0.7.2 "Daybreak"** · marathon `mar-01M0EC2ZXJCCJ88KASQPDBTBJ9` · tracking
[#77](https://github.com/HiQS-Labs/XYZ-forge/issues/77).

Build lenses **4, 5** in `skills/standup/collect.sh`. Waves 1 (lenses 2, 3, 7) and 2 (lenses 1, 6, 8)
are landed and green — `test/gh77-standup-triage.sh` runs 112/0 on `development`. These two complete the
full 8-lens set by adding the GitHub metadata reads.

## Work units

| Issue | Lens | Bounded read |
|---|---|---|
| [#85](https://github.com/HiQS-Labs/XYZ-forge/issues/85) | 4 · Open PRs | `gh pr list --limit 51 --json number,title,updatedAt,isDraft,mergeStateStatus` — 51 probes one past the bound so truncation is detectable |
| [#86](https://github.com/HiQS-Labs/XYZ-forge/issues/86) | 5 · Issue state | `gh issue view <n> --json number,state,title,updatedAt` over the bounded set (session mentions + Queue/In-progress ledger cites + non-shipped manifests) |

## Contract (unchanged from waves 1 & 2)

`collect.sh --fixture <dir>` must emit one JSON document:

```json
{"repo": {"branch": "<name>"},
 "lenses": {"4": {"status": "ok|degraded", "degraded_id": "D<n>|null", "candidates": [ … ]},
            "5": {"status": "ok|degraded", "degraded_id": "D<n>|null", "candidates": [ … ]}}}
```

`triage.py --lenses <file> --dry-run` is the consumer. Read it — it is the authority on field names
and on what each lens's `live_state` payload must contain, because suppression hashes that payload.

## Pass condition — machine-checkable, per unit

```
skills/standup/collect.sh --fixture skills/standup/fixtures/lens-<n>   # valid JSON
python3 skills/standup/triage.py --lenses <that output> --dry-run      # no D5, exit 0
bash test/gh77-standup-triage.sh                                       # green
```

## Things that are already settled — do not relitigate them

- **Lens 4 limit is 51** — when exactly 51 rows return, the lens degrades with `D2` (PR list truncated at 50) while still emitting the first 50 candidates.
- **Both lenses degrade loudly with `D1` when `gh` is unavailable** (e.g. `which gh` fails or `gh` returns auth/network error).
- **Lens 5 bounded set is strictly:**
  1. numbers mentioned in this session transcript (`session.json`);
  2. numbers cited by `ROADMAP.md` ledger entries under `Queue / parked intake` or `In progress` only;
  3. manifest items of non-shipped releases.
  Never perform an unconstrained issue list sweep.
- **`triage.py` is NOT modified by this phase** — if a lens seems to need a change there, that is a
  finding to report, not an edit to make.

## Definition of done for this phase

Both lenses implemented, fixture directories under `skills/standup/fixtures/lens-4/` and `skills/standup/fixtures/lens-5/`
(plus degradation fixtures matching the pattern: `D1` when `gh` unavailable, `D2` when PR list truncated at 51),
each lens degrades loudly with its `D<n>` id when its read is unavailable, new assertions in `test/gh77-standup-triage.sh`, and
`bash validate.sh --subsystem releases` green.

## Working rules for the BUILDER — lessons from waves 1 & 2

- **`skills/standup/fixtures/` is a DIRECTORY lane** — spelled with the trailing slash, so the whole
  tree beneath it is yours this turn.
- **Do not leave scratch files in the tree.** Probe files, scratch scripts, and one-off outputs are
  off-lane no matter how harmless, and a single stray path at the repo root fails the whole turn.
  Use `$TMPDIR`.
- **Off-lane edits are reverted by the harness.** A `### Side Finding` block in the relay file is
  the only channel that survives — path / symptom / suspected_cause / probe.

## What this phase is actually testing

Two lanes editing **one shared `collect.sh` and one shared suite**. That collision surface is why
this is a marathon rather than a task. A lane clobbering another's edit, a stale worktree, an
unexpected driver-lock interaction — those are the deliverable, per `AGENTS.md` → Repo-specific
rails, rule 4. **Report what broke; do not smooth it.** A clean run that teaches nothing is the
weaker result.
