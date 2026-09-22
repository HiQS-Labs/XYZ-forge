# Shakedown — improvements & status

Working notes for finishing the `shakedown` skill. Source: an independent relay review on
2026-06-21 (Codex reviewer + agy as a second model, run through the xyz relay harness) plus the
follow-up build session that acted on it. This file lives with the skill; fold it into the README
or delete it once shipped.

## Status at a glance

| Piece | State |
| --- | --- |
| `SKILL.md` path-discovery snippet | **Done** — prefers install roots, anchors the project root to the repo top (not CWD), fails loud instead of collapsing to `.`. Independently confirmed `[Pass]`. |
| `SKILL.md` "When NOT to shake down" counter-example | **Done** — added; confirmed `[Pass]`. |
| `SKILL.md` read-only contract | **Done** — now names both the dated report *and* `SHAKEDOWN/INDEX.md` as repo writes. |
| `SKILL.md` report markers | **Done** — emoji to ASCII (`[path bug reproduced]` / `[warnings only]` / `[clean]`). |
| `SKILL.md` frontmatter description | **Done** — compressed to the trigger cases. |
| `scripts/lib.sh` | **Done** — `sev_emoji` to `sev_label` (ASCII), matching the report markers. |
| `scripts/audit.sh` | **Done** — static audit; sources lib.sh; bash-3.2 safe; dogfood passes. |
| `scripts/harness.sh` | **Done** — live scenario matrix; sources lib.sh; bash-3.2 safe; dogfood passes. |
| README / CHANGELOG / install symlink | **Done** — shipped as v1.0 (README layout + utils table, CHANGELOG entry, symlinked into `~/.claude/skills/`). |

## What `lib.sh` already provides (reuse, never reinvent)

`scripts/lib.sh` is the shared static-analysis core; the two entrypoints are thin consumers of it.

- `SHK_PATH_RE` — the `.sh` path-token regex.
- `grade_path <token>` -> `CLASS|severity|note`; severity is pass / warn / block. Classes: SELF (pass), ABSOLUTE (warn), HOME / CWD / BARE (block).
- `sev_label <severity>` -> `[ok]` / `[warn]` / `[block]` (renamed from `sev_emoji`).
- `find_script_calls <file>` -> one line per `.sh` token: `lineno <TAB> token <TAB> rawline`.
- `invoked_with_sh <rawline>` -> true when the line runs the script through `sh`, not `bash`.
- `trim <string>` -> collapse to a single trimmed line for table cells.

## The two entrypoints (written this session)

### `scripts/audit.sh --target <skill-dir>` — static audit
- Self-locates and sources lib.sh (the exact idiom the skill recommends). Prints a header block (target, git HEAD, env).
- Part 1: `find_script_calls` over the target `SKILL.md` -> `grade_path` each token, `invoked_with_sh` flag, rendered with `sev_label`.
- Part 2: per bundled `.sh` — shebang / exec-bit / self-location-idiom checks.
- Verdict anchored to the worst finding. Exit `0` clean / `1` warn / `2` block / `3` usage.
- **Known limit:** it greps *every* `.sh` token, including illustrative bad-path examples written in prose — so a meta-skill that documents bad paths on purpose shows blocks for its own examples. The output prints a note to read findings in context. (See Remaining work #1.)

### `scripts/harness.sh --target <dir> --as-documented '<cmd>' [--proposed '<cmd with {SKILL}>'] [--keep]` — live harness
- Stages a fresh copy of the target per scenario under `mktemp`, deleted on exit (`--keep` retains it).
- Matrix: control (CWD=skill), foreign CWD, nested CWD, spaces-in-path, project install, user install (fake `HOME`), stripped exec bit.
- Run A runs the as-documented command; Run B substitutes `{SKILL}` -> install dir and runs the proposed command. Splits NOT-FOUND (exit 127 / "no such file") from found-but-errored.
- Exit `0` no discovery bug / `1` bug reproduced / `3` usage.

### Dogfood (2026-06-21)
Against a fixture whose `SKILL.md` documents `bash scripts/foo.sh` (CWD-relative):
- `audit.sh` -> `[block]` on the token; verdict `[path bug reproduced]`; exit 2. (verified)
- `harness.sh` Run A -> control found, but foreign / nested / spaces / project / user all NOT-FOUND (127); Run B (`bash "{SKILL}/scripts/foo.sh"`) found in every scenario including spaces. Verdict `[path bug reproduced]`; exit 1. (verified)
- Both run under macOS system bash 3.2.57 (an earlier `mapfile` in audit.sh was replaced with a portable read loop — shakedown is a distributed skill and must run anywhere).

## Remaining work

- [ ] 1. Decide the audit-on-meta-skill noise: accept the documented "examples are flagged" caveat, or teach `find_script_calls` to skip tokens inside fenced example blocks. Low priority — the caveat is printed.
- [x] 2. README: added `utils/shakedown` to the layout tree and the utils table. (shipped v1.0, commit `0b44a71`)
- [x] 3. CHANGELOG: added the shakedown v1.0 entry (repo extra). (shipped)
- [x] 4. Install: symlinked into `~/.claude/skills/shakedown`. (shipped)
- [ ] 5. Optional: a `test/` fixture plus a one-line self-test so a regression in lib.sh or the scripts is caught before shipping.

## Appendix — relay review findings (2026-06-21)

Codex (reviewer) and agy (second model), against the staged copy:

- `[Blocker]` `audit.sh` / `harness.sh` did not exist -> **written**.
- `[Should]` read-only contract contradicted the `INDEX.md` write -> **fixed**.
- `[Should]` emoji markers vs. the repo's plain-ASCII presentation -> **fixed** (SKILL.md + lib.sh).
- `[Nit]` frontmatter description too verbose for a trigger surface -> **compressed**.
- `[Pass]` hardened path-discovery loop (avoids the `.` collapse, exits clean).
- `[Pass]` "When NOT to shake down" counter-example.

Rejected: Codex also mass-replaced every em-dash with a hyphen on the staged copy. Not lifted — this repo's authoring conventions explicitly allow em-dashes; only the emoji needed to go.
