---
gh_issue: 1543
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1543
title: "kickstart(KS-15): versioned run-record contract, atomic appends, redacted snapshot and checkpoint helper"
status: In Progress
created: 2026-11-20
updated: 2026-11-20
owner: operator
goal: "Define the kickstart v1 run-record grammar, atomic append primitive, redacted snapshot, and branch checkpoint helper in run_record.py and kickstart/SKILL.md so KS-04, KS-06, KS-08, KS-09, KS-13, and KS-20 share one canonical parser and writer."
doc_type: feat
complexity: 2
risk: 1
effort: 2
phases: 1
---

## Status

| What was just completed | What's next |
|---|---|
| Intake registered and grounded surgical plan drafted. | Run independent Codex plan QA (`relay-system/2026-11-20/gh1543-plan-qa.md`). |

## Problem

Arc #1541 (adjudication U1, U10, U12, U16) requires the kickstart run-record contract to exist before KS-04 (`kickstart_status.py`), KS-06 (amendment application), KS-08 (killed-landing recovery), KS-09 (pinned `LANDING_CLONE`), KS-13 (final-QA invalidation), and KS-20 (interruption recovery). Today, run records are free-form Markdown with no versioned line grammar, no atomic append lock (risking torn writes on crash or parent/child contention), no standard redaction pass (run-1 publication #1542 hit stray `</content>`/`</invoke>` tags and local paths), and no checkpoint push helper for run-record branches.

## Requirements (from #1543 / #1541 KS-15, U1, U10, U12, U16)

1. **Versioned v1 grammar** (`RUN-RECORD-VERSION: 1`, `LANDING_CLONE: <path>`):
   - `OPERATOR_AMENDMENT: <ID> <ISO-UTC-TS> <text citing operator turn>`
   - `PARENT_NOTE: <ID> <ISO-UTC-TS> <text>`
   - `INTERVENTION: <ID> <ISO-UTC-TS> <text>`
   - `APPLIED: <ID> → <disposition: applied|superseded|escalated> <action/artifact> [<ISO-UTC-TS>]` (also accepts `->` and compact `APPLIED: <ID> → <action>` defaulting disposition to `applied`; `superseded` names the superseding amendment ID)
   - `GATE: <target> [head <sha>] <route> [<Ns>|(duration not recorded)] <green|red>` (and `GATE: final-QA <sha> <route> <verdict> ...`, matching the run-1 baseline lines in #1542)
   - `BASELINE: <key=value ...>` (optional summary line)
   - Leading `- ` markdown list markers are tolerated on event lines so bulleted Progress logs parse cleanly.
2. **One canonical stdlib module & CLI**: `skills/1-hourly/kickstart/scripts/run_record.py`:
   - `validate <record> [--json]`: parses headers and event lines, computes `unresolved_amendments` (any `OPERATOR_AMENDMENT` or `PARENT_NOTE` lacking a valid `APPLIED` disposition), checks for missing/unsupported version, duplicate IDs, `OPERATOR_AMENDMENT` missing operator-turn citation, unknown `APPLIED` target IDs, and malformed `GATE` lines. Exits 0 if valid, 1 with diagnostics otherwise.
   - `append <record> --kind <operator-amendment|parent-note|intervention|applied|gate> ...`: formats and validates the new line against the v1 grammar (and against the existing record for duplicate IDs / unknown `APPLIED` targets) BEFORE writing, then performs an `fcntl.flock`-locked atomic read + temp-file + `fsync` + `os.replace` append.
   - `snapshot <record> [--out PATH]`: refuses empty input, replaces `/Users/<user>` and `/home/<user>` with `~`, redacts token/secret patterns (`ghp_`, `gho_`, `github_pat_`, `sk-`, `Bearer `, `Authorization:`), strips stray tool tags (`</?content>`, `</?invoke...>`, `</?parameter...>`), and writes atomically.
   - `checkpoint --record <path> --clone <dir> --branch <branch> --dest <relpath> [--message <msg>] [--push]`: refuses `development` and `main` (never mutates integration branches or the primary checkout), refuses a dirty unrelated working tree in `<clone>`, writes a redacted snapshot into `<clone>/<dest>`, commits on `<branch>` if changed, and pushes only when `--push` is set.
3. **Runbook update**: add a concise v1 Run Record Contract subsection to `skills/1-hourly/kickstart/SKILL.md` naming `run_record.py` as the single parser/writer.
4. **Verification**: paired pre-change (red) vs changed (green) manual checks recorded under `TESTS-RESULTS/2026-11-20+GH-1543/` with `provenance.jsonl`. No new test suite (GH-831).

## Recon (base `6270a2b5d`)

- `skills/1-hourly/kickstart/scripts/` currently contains only `build_queue.py` (256 lines). `prior_art_recon.py --query run_record` found 0 matching modules, PRs, or issues.
- `utils/ci-route.sh:46-52` routes `skills/1-hourly/kickstart/**` as `docs` (tier 1 -> `utils/pdda/pdda.sh run`).
- Existing live run record (`temp/kickstart-2026-11-20-ks1541.md`) uses `RUN-RECORD-VERSION: 1`, `LANDING_CLONE: ...`, and expects `APPLIED: <id> → <action>` and `INTERVENTION:` lines. Run-1 published baseline (#1542, commit `423a48dce`) uses `OPERATOR_AMENDMENT: OA-1 ... (operator turn)`, `INTERVENTION: I-1 ...`, `GATE: #1501 head 2e9bb2bdd full 856s green`, `GATE: final-QA 0a87e686d tier1+full green (duration not recorded)`, and `BASELINE: ...`.

## Preflight Bet Check

- **Outcome sought:** Every downstream kickstart script (KS-04, KS-06, KS-08, KS-09, KS-13, KS-20) parses and updates the run record through one tested v1 contract without torn writes, secret/path leaks, or grammar drift.
- **Smallest viable bet:** One stdlib-only Python module/CLI `skills/1-hourly/kickstart/scripts/run_record.py` (~220 lines) plus a concise contract section in `skills/1-hourly/kickstart/SKILL.md`.
- **Non-goals:** No database, no daemon, no `kickstart_status.py` (KS-04), no `build_queue.py` template edits (KS-03), no live run-2 checkpoint publication (KS-15 acceptance stays uncredited until run 2), no new test suite (GH-831).
- **Alternatives rejected:** Putting regexes directly inside `kickstart_status.py` (KS-04) and `build_queue.py` (KS-03) would duplicate grammar parsing and omit atomic append + redaction. Adding a JSON sidecar alongside the Markdown run record would create a dual source of truth.
- **Reversibility & blast radius:** **Easy** — additive new script + docs section under `skills/1-hourly/kickstart/`. Reverting the PR cleanly removes it with zero effect on existing skills or gates.

## PRS Rating Rationale

- **Rated:** `85/65/50/80` (`pri/sev/appeal/effort`, total `280`).
- **Priority (85):** First milestone in the operator-authorized #1541 v5 build order; blocks KS-04, KS-06, KS-08, KS-09, KS-13.
- **Severity (65):** Missing contract caused U16 tag leaks, unparseable parent lines, and torn-write/split-brain risks in run 1.
- **Appeal (50):** Neutral default (no explicit operator appeal score).
- **Effort (80):** Small, bounded stdlib script and docs update.
- **Recurrence:** Run 1 (2026-11-19 → 11-20) hit 4 unapplied parent/amendment lines and 1 publication tag leak (#1542 U16); single prior run (baseline window).

## Implementation Plan & Inline Verification

1. Create `skills/1-hourly/kickstart/scripts/run_record.py` implementing v1 grammar parsing/validation (`parse_record`, `validate_record`), `fcntl.flock` atomic temp+fsync+rename `atomic_append`, `redact_text`/`write_snapshot`, `checkpoint_record`, and CLI subcommands (`validate`, `append`, `snapshot`, `checkpoint`). -> expect `python3 -m py_compile skills/1-hourly/kickstart/scripts/run_record.py` exit 0.
2. Document the v1 Run Record Contract in `skills/1-hourly/kickstart/SKILL.md` referencing `run_record.py`. -> expect `utils/pdda/pdda.sh run` exit 0.
3. Run paired red/green manual checks and main/adjacent smoke checks, recording commands, outputs, and `provenance.jsonl` under `TESTS-RESULTS/2026-11-20+GH-1543/`:
   - **Red controls:** (a) malformed records (missing version, `OPERATOR_AMENDMENT` without operator-turn citation, duplicate ID, `APPLIED` for unknown ID) exit 1 and `append` refuses without writing; (b) empty file refused by `snapshot` (exit 1); (c) pre-redaction fixture contains `/Users/example`, `ghp_...` token, and `</content></invoke>` tags (grep matches); (d) `checkpoint` targeting `development` or `main` exits 1 with zero commits.
   - **Green & smoke controls:** (a) `validate --json` parses run-1 baseline lines (#1542 shape) and active run-2 header with 0 errors and accurate `unresolved_amendments`; (b) `append` appends valid lines atomically across two concurrent subprocesses with 0 lost/torn lines; (c) `snapshot` strips tags, normalizes home paths to `~`, redacts tokens, and passes `validate`; (d) `checkpoint --push` in a disposable branch clone pushes redacted snapshot cleanly to a local bare remote, and a second unchanged run is a clean idempotent no-op.
4. Update `CHANGELOG.md` and assess `LESSONS-LEARNED.md` (or record `NO_ENTRY`). -> expect `utils/ci-route.sh pull_request` classifies `docs` and `utils/pdda/pdda.sh run` passes.

## Acceptance Criteria Mapping

- R1 (Capability): Kickstart gains a single versioned v1 record parser, atomic locked appender, redacted snapshotter, and safe branch checkpoint helper.
- R2 (Discriminating check): All 4 red controls fail pre-change / reject bad inputs; all 4 green controls pass on real CLI entry points with `provenance.jsonl`.
- R3 (Proportionate cost): ~220-line stdlib module with zero new dependencies, schemas, daemons, or test suites.

## Lessons Learned

NO_ENTRY (new capability contract; live multi-run evidence awaits run 2).
