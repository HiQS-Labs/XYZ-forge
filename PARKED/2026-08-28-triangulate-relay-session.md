# Parked — triangulate skill relay session, 2026-08-28

Dropped from the `triangulate` skill build (two relay QA rounds). None blocked the deliverable.

## 1. `relay-drive.sh` mis-parses a Setup artifact path wrapped in both `**` and backticks

`relay_extract_markdown_paths()` (relay-automation/relay-drive.sh:365-369) alternates
`` `[^`]+` `` with `\*\*[^*]+\*\*`, then strips with sed in the order backtick-lead,
backtick-trail, asterisk-lead, asterisk-trail.

For a Setup line written as ``- Artifact under review: **`path/to/file.md`** — ...`` the
leftmost-longest match is the `**...**` span, so the captured candidate is
`` **`path/to/file.md`** ``. The two backtick-stripping seds run *before* the asterisk ones and
therefore no-op, leaving `` `path/to/file.md` `` with literal backticks. `preflight_setup_artifact_paths`
then dies with `artifact path not found in worktree` for a path that exists.

**Repro:** scaffold any relay, wrap the Setup artifact path in `**` + backticks, run `relay-drive.sh`.
**Workaround used:** backticks only, no bold.
**Fix:** strip asterisks before backticks (reorder the sed chain), or strip both repeatedly until stable.

Cost this session: two wasted drive attempts, which then tripped the lane attempt cap
(`--force` needed to re-fire). The failure message names the path but not the invisible backticks,
so it reads as "your file is missing" rather than "your markup confused the parser."

## 2. Lane attempt cap counts preflight failures as attempts

The two failures above consumed the 2-attempt cap before a single agent turn had run. A preflight
`die()` is arguably not an "attempt" — nothing was dispatched. Worth deciding whether the counter
should increment only after the turn-taker is invoked.

## 3. `~/.claude/skills/ponytail/` vs `04-build/ponytail-refined/`

The local directory is a real (older, shorter) copy: 5966 bytes vs 7616. The operator flagged it for
removal; it is **not** deleted. A copy is preserved at
`giant-brains-claude-skills/PARKED/ponytail-local-superseded-20260828.md`.
Decision needed: delete and symlink `/ponytail` -> `ponytail-refined`, or keep both.
