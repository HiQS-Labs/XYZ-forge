---
gh_issue: 1263
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1263
title: "hq park: rating grammar in the title pre-rates the ledger row or leaves intake half-complete"
status: Proposed (1-INBOX — not yet active)
created: 2026-10-30
owner: unassigned
doc_type: feedback
complexity: 1
risk: 1
effort: 1
phases: 1
ratings_provisional: true
non_goals:
  - no change to parse_rating or its grammar
  - no title rewriting
  - no new flag/script/test
related:
  - #1258
  - #1177
  - GH-249
goal: >
  TODO: one-paragraph statement of what "done" looks like for this idea.
---

## Key concepts

- cmd_park title guard at hq.sh:253 ahead of Tier C, preview and create
- parse_rating token-presence rule (releases_app.py:3299,3317)
- hq_roadmap_line interpolates the title
- half-complete intake branch hq.sh:339

> **Note for plan writers:** apply the `/ponytail` lens — favor the laziest approach that actually
> works over new infrastructure, and question whether new surface needs to exist at all.

# hq park: rating grammar in the title pre-rates the ledger row or leaves intake half-complete

## Status

| What was just completed | What's next |
|---|---|
| Captured via HQ (`/hq park`) for project **XYZ-forge** → repo `XYZ-forge`. The GitHub issue is the signal stream; this doc is the in-repo capture and back-reference. | Fill in Why/Key Concepts, correct the provisional ratings above, and run a Phase 0 explore pass before promoting to `2-WORKING`. |

## Idea

## Observed (2026-10-30, `development@e305cbf3`)

| Claim | Command | Observed |
|---|---|---|
| A neutral title leaves the parked row unrated | `source utils/hq/hq-lib.sh; hq_roadmap_line 99999 "Add idea intake skill" …` piped to `parse_rating` (`utils/py/releases_app.py:3325`) | all five rating columns `None` |
| A title that quotes the rating grammar pre-rates the row | same, title `Handle rated 80/55/50/65 placeholders` | `rating_pri=80, sev=55, appeal=50, effort=65` stored by `roadmap add`; the later `releases roadmap rate --issue-num N` then refuses `already-rated` (`releases_app.py:3738-3741`) |
| A title with a malformed token breaks intake **after** the issue exists | same, title `Fix rated 5/5 placeholder` | `parse_rating` refuses `rating-shape` (exit 3). In `hq park --create` that refusal happens at `roadmap add` (`utils/hq/hq.sh:339`), after `gh issue create` (`:314`) and the capture doc (`:323-325`) succeeded: HQ prints "intake is half-complete (issue + capture doc exist, no queue pointer)" |
| No `--title` has the same exposure | `hq_issue_title` (`utils/hq/hq-lib.sh:402-406`) | the title is the first 72 chars of the request, so a request that opens with a score example is interpolated the same way |

Receipts: read-only probe, no DB writer ran; the `--create` half-complete branch is source-traced (`hq.sh:339-344`), not executed; reproduced independently by the Codex plan-QA probe on #1258 (`relay-system/2026-10-30/gh1258-plan-qa.md`, Probe A).

## Root cause

`hq_roadmap_line` interpolates the free-text title into the ledger line (`utils/hq/hq-lib.sh:555-558`) and `parse_rating` scans the whole line by design (GH-249: one grammar, one parser; `releases_app.py:3325-3328`, the `title` argument is only the error label). Nothing between `hq park` and `roadmap add` strips or refuses rating grammar in the title. One instance: `cmd_park` is the only caller that composes a ledger line from an operator-typed title. Fix site: `cmd_park`, where `$title` is computed (`hq.sh:253`), before the dup guard (`:306`) and before any write (`:314`).

## Plan

1. `utils/hq/hq.sh` `cmd_park`: right after `$title` is computed (`:253`), refuse when the title matches the token-presence rule `parse_rating` triggers on, `\b(rated|ovr)\s+\d` (`_RATED_TOKEN_RE`/`_OVR_TOKEN_RE`, `releases_app.py:3299,3317`; in bash `grep -Eq '(^|[^[:alnum:]_])(rated|ovr)[[:space:]]+[0-9]'`), so malformed and truncated scores (`rated 5/5`, `rated 70`, orphan `ovr 200`) are caught too: print `hq park: title carries rating grammar ("rated N/N/N/N" / "ovr N"); roadmap add would read it as the row's score. Move the example into the body and rate with: releases roadmap rate --issue-num N --rated P/S/A/E` to stderr and `return 2`. The guard runs on the computed `$title` (`:253`), so the no-`--title` path is covered, and it sits before the Tier C branch (`:259`), the preview return (`:279-300`) and the dup guard (`:306`), so preview, Tier C plain issues and `--create` all refuse the same way (a blanket policy, by intent). One `grep -Eq`, about six lines. No change to `parse_rating`, `hq_roadmap_line` or `roadmap add`.
2. Record the four acceptance witnesses as a manual check under `TESTS-RESULTS/<date>+GH-<this>/` with `provenance.jsonl`; `bash test/hq-park.sh` (existing, `validate.sh:587`) stays green on the final commit. No new test (GH-831).

## Blast radius

| Seam | Where | What changes |
|---|---|---|
| `cmd_park` title computation and guards | `utils/hq/hq.sh:251-256`, `:259` (Tier C), `:279-300` (preview), `:306-312`, `:314`, `:339` | one new refusal at `:253`, ahead of every branch |
| `hq_issue_title` / `hq_roadmap_line` | `utils/hq/hq-lib.sh:402-406`, `:555-558` | unchanged (read) |
| `parse_rating` / `roadmap add` | `utils/py/releases_app.py:3325`, `:3639` | unchanged (read) |
| Consumers of `hq park` | `skills/2-daily/hq/SKILL.md`, `skills/2-daily/file-xyz-bug/SKILL.md` Step 4–5, `skills/1-hourly/idea/SKILL.md` Step 7 | a refused title is reported as the stop it is; idea already forbids such titles |

Recon `e305cbf3`; integration base `development@e305cbf3`. Effective write-set: `utils/hq/hq.sh` (guard), `TESTS-RESULTS/<date>+GH-<this>/` (receipt + `provenance.jsonl`). Route: `utils/ci-route.sh` classifies `utils/hq/hq.sh` as subsystem `hq` (route fast, tier 2); focused suite `test/hq-park.sh`; the push hook applies whatever qualification the final changed set requires. Builder: Codex or agy headless; reviewer: Codex relay.

## Dependencies

None. Related: #1258 (the idea skill documents the title rule at its Step 7), #1177 (placeholder-rating defect class), GH-249 (rating grammar in `roadmap add --raw-text`).

## Acceptance

- [ ] `bash utils/hq/hq.sh park --title "Handle rated 80/55/50/65 placeholders" XYZ-forge "probe"` (preview, no `--create`) exits 2 and names `releases roadmap rate`; nothing is created. Red control: the same command on `development@e305cbf3` previews normally (exit 0); both recorded under `TESTS-RESULTS/<date>+GH-<this>/`.
- [ ] `… --title "Fix rated 5/5 placeholder" …` and `… --title "Rank ovr 200 example" …` exit 2 the same way, before any write. Red control: on the base, preview exits 0 and renders the token (preview never calls `parse_rating`, `hq.sh:279-300`); the separate pure-parser witness (`hq_roadmap_line` piped to `parse_rating`) refuses `rating-shape` with exit 3; both recorded.
- [ ] `bash utils/hq/hq.sh park XYZ-forge "rated 80/55/50/65 should not leak from a request opening"` (no `--title`) exits 2 the same way; the guard runs on the computed title. Red control: base previews normally (recorded).
- [ ] `… --title "Add idea intake skill" …` previews exactly as on the base: both commands exit 0, both outputs are non-empty and contain the title and the rendered capture, and the two outputs are byte-identical (recorded; an empty pair does not pass). `bash test/hq-park.sh` passes on the final commit.

## Verification

Existing suite `test/hq-park.sh` on the final commit (full route). The four acceptance witnesses are manual checks recorded under `TESTS-RESULTS/<date>+GH-<this>/` with `provenance.jsonl` committed in the same PR. No new suite, no `validate.sh` entry.

## Non-goals

No change to `parse_rating`, its grammar, `hq_roadmap_line` or `roadmap add`. No stripping or rewriting of titles (a refusal is explicit; a silent rewrite would hide the operator's intent). No new flag, no new script, no new test.

## Risk and rollback

Risk: a title that legitimately quotes a score (for example an issue about the rating grammar itself) is refused; that is the intent, and the message says where the example belongs. Rollback: revert the guard commit. A row already pre-rated by this path is corrected with `releases roadmap rate --force` and a recorded reason; a half-complete intake is finished with `releases roadmap add` by hand.

## PRS proposal

- pri 55: it bites exactly the issues that talk about ratings (#1177 class), which are the ones being filed now that #1258 puts PRS proposals in every body.
- sev 45: a wrong rating is stored silently, or intake stops half-complete (issue without ledger row); both recoverable by hand, no data lost.
- appeal 50: operator did not set a preference.
- effort 90: one guard of about six lines beside an existing guard, covered by an existing suite.

## Preflight Contract

```json
{
  "target": { "repo": ".", "ref": "development" },
  "gate": "bash test/hq-park.sh",
  "fix_probes": [
    { "type": "grep_absent", "path": "utils/hq/hq.sh", "pattern": "title carries rating grammar",
      "note": "pre-fix: no refusal message in cmd_park; landed when the guard's message is present" }
  ],
  "artifacts": [ "utils/hq/hq.sh" ],
  "remediation": {
    "source": "issue#<this>",
    "criteria": "One refusal in cmd_park at the computed title (hq.sh:253) on the token-presence rule \\b(rated|ovr)\\s+\\d, ahead of Tier C, preview and create; message names releases roadmap rate. No change to parse_rating, hq_roadmap_line or roadmap add; no new test (GH-831)."
  }
}
```

Recon: e305cbf3 · base: development@e305cbf3 · tier: standard · review: consult relay-system/2026-10-30/gh-idea-A-draft-112341 models=codex,agy hash 4fa3dc539317f5780d2db97ca762113e1ac1c593a065d5bb238e6ba6be8e7ec7

## Why

hq park composes the ledger line from the operator's title; parse_rating reads the whole line, so a title that quotes rating grammar pre-rates the row or, if malformed, aborts roadmap add after the issue already exists. Now that #1258 puts a PRS proposal in every body, titles about ratings are common.

## Phase 0 — Explore & scope

### Checklist

- [ ] TODO: scope-specific checklist items for this idea's Phase 0 pass.

### QA checklist — Phase 0

- [ ] TODO: acceptance criteria for the Phase 0 pass above.
