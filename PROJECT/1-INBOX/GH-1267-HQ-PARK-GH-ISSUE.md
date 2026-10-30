---
gh_issue: 1267
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1267
title: "hq park --gh-issue: register an already-filed issue (capture + ledger row) without creating a new one"
status: Proposed (1-INBOX — not yet active)
created: 2026-10-30
owner: unassigned
doc_type: feedback
complexity: 2
risk: 1
effort: 2
phases: 1
ratings_provisional: true
non_goals:
  - no bulk mode
  - no body/title rewriting
  - no rating
  - no queue/promote change
  - no fix for #1263
related:
  - #1258
  - #1175
  - #1263
  - #1264
goal: >
  TODO: one-paragraph statement of what "done" looks like for this idea.
---

## Key concepts

- park --gh-issue mirrored from queue
- adopt branch after resolution, before title/slug/preview
- gh issue view via HQ_GH_BIN
- unchanged capture + roadmap add path

> **Note for plan writers:** apply the `/ponytail` lens — favor the laziest approach that actually
> works over new infrastructure, and question whether new surface needs to exist at all.

# hq park --gh-issue: register an already-filed issue (capture + ledger row) without creating a new one

## Status

| What was just completed | What's next |
|---|---|
| Captured via HQ (`/hq park`) for project **XYZ-forge** → repo `XYZ-forge`. The GitHub issue is the signal stream; this doc is the in-repo capture and back-reference. | Fill in Why/Key Concepts, correct the provisional ratings above, and run a Phase 0 explore pass before promoting to `2-WORKING`. |

## Idea

## Observed (2026-10-30, `development@e305cbf3`)

| Claim | Command | Observed |
|---|---|---|
| `hq park` can only create a new issue | `sed -n 543,556p utils/hq/hq.sh` | the `park` parser accepts `--create` and `--title` only; `queue` already parses `--gh-issue N` (`:559-567`) |
| The create path always files | `sed -n 302,345p utils/hq/hq.sh` | dup guard (`:306-312`) then `gh issue create` (`:314`); the capture (`:323-325`) and `roadmap add` (`:339`) are reached only through that creation |
| An existing issue cannot be registered by CLI | #1258, filed with `gh issue create` on 2026-10-29 | no capture doc and no ledger row until a hand sequence ran on 2026-10-30: `hq_render_capture` called directly, `releases roadmap add`, `releases roadmap rate` (intake commit on `feat/XYZ-forge-gh1258-idea-skill-2026-10-30`) |
| Re-parking by title is refused | `hq.sh:306-312` | the dup guard matches the existing open issue by title and aborts, so `hq park --create` is not a workaround |
| The backlog is mostly this case | `TESTS-RESULTS/2026-10-25+GH-1175-phase0/SUMMARY.md:15`; `step6/survey.log:1` (`miss:row 204`) | 204 of 281 open issues (73%) have no ledger row (missing registration; not proof that each was hand-filed) |

## Diagnosis / existing gap

`cmd_park` conflates two steps, "create the GitHub issue" and "register its intake" (capture doc + ledger row). The second step has no entry point for an issue that already exists, so the 204 hand-filed issues can only be registered by reproducing the create path by hand, which is where the title-rating hazard of #1263 lives. One instance; the registration half of `cmd_park` is already the code to reuse.

## Plan

1. `utils/hq/hq.sh` parser for `park`: accept `--gh-issue N` / `--gh-issue=N` exactly as `queue` does (`:559-567`); request becomes optional when it is set (`[ "${#pargs[@]}" -ge 1 ]`).
2. `cmd_park`: when an issue number is given, the adopt branch runs **right after target resolution (`:250`) and before `title`/`slug` (`:253-254`), Tier C (`:259`) and the preview return (`:279-300`)**: (a) refuse a non-numeric number; refuse if `PROJECT/1-INBOX/GH-N-*.md` or `PROJECT/2-WORKING/GH-N-*.md` already exists in the target, naming the path (already registered); refuse on Tier C (no PDDA lifecycle to register into; never fall through to `:267`'s `gh issue create`); (b) `"$HQ_GH_BIN" issue view N --json url,title,body` run in `"$path"` (the test seam, `hq.sh:21`, `test/hq-park.sh:37`): `url` is the source, `title` is the title unless `--title` was given, the request is the given text or else the issue body; a fetch or JSON failure stops before any write; an empty body is allowed (the TODO stubs keep the doc valid); (c) `slug` derives from the resolved **title** (`hq_slug "${ptitle:-$title}"`), never from a fetched body; (d) preview uses the fetched `num`/`src` instead of the `<N>` placeholders at `:280`; (e) `--create` skips the dup guard and `gh issue create` and continues into the unchanged capture + `roadmap add` path (`:320-345`), whose writer already refuses a duplicate issue URL or number (`releases_app.py:3651-3658`). `created` stays the intake date (today), as it is for a fresh park.
3. `skills/2-daily/hq/SKILL.md:60-66`: one usage line, `hq park [--create] --gh-issue N <project> [request…]`, "adopt an existing issue".

About twenty lines, all inside `cmd_park` and the parser; no new function, no new writer.

## Blast radius

| Seam | Where | What changes |
|---|---|---|
| `park` parser | `utils/hq/hq.sh:543-556` | one flag, mirrored from `queue` |
| `cmd_park` adopt branch | `utils/hq/hq.sh:250-300` (after resolution, before title/slug, Tier C and preview) and `:302-345` (dup guard and create skipped) | one branch; registration half reused as is |
| hq skill usage | `skills/2-daily/hq/SKILL.md:60-66` | one line |
| Consumers | `skills/1-hourly/idea/SKILL.md` (Phase 3 retrofit, #1258), `start-task` Step 3 intake, `start-marathon` NEEDS-CAPTURE (`skills/2-daily/start-marathon/SKILL.md:182,193`) | gain a CLI path; no behaviour change until they call it |

Recon `e305cbf3`; base `development@e305cbf3`. Write-set: `utils/hq/hq.sh`, `skills/2-daily/hq/SKILL.md`, `TESTS-RESULTS/<date>+GH-<this>/`. Route: subsystem `hq`, focused suite `test/hq-park.sh`. Builder: Codex or agy headless; reviewer: Codex relay.

## Dependencies

None hard. Write-set collision: #1263 (`cmd_park` guard) and #1264 (`cmd_park` env + `skills/2-daily/hq/SKILL.md`) touch the same files; sequence or group the three, never parallel lanes. Related: #1258 (Phase 3 retrofit needs this), #1175 (204 unregistered issues), #1263 (the title hazard the hand path exposes; this issue does not fix it, the writer still parses the rendered line).

## Acceptance

- [ ] `bash utils/hq/hq.sh park --gh-issue <N> XYZ-forge` (preview) on an open issue with no capture prints the existing issue URL and title and the capture that would be written, whose `## Idea` contains a known non-empty substring of that issue's body, and writes nothing. Red control: on the base the same command exits 1 with `hq park: '--gh-issue' is UNRESOLVED` (the flag is swallowed as the project name; recorded).
- [ ] `bash utils/hq/hq.sh park --create --gh-issue <N> XYZ-forge` on that issue writes `PROJECT/1-INBOX/GH-<N>-*.md` whose `gh_issue:` is `<N>` and whose `## Idea` is non-empty, and exactly one ledger row with `issue_url` equal to the existing issue; and creates no GitHub issue: `gh issue list --state all --limit 1 --json number --jq '.[0].number'` is the same non-empty integer before and after (a plain `gh issue list` count is capped at 30 and proves nothing; recorded).
- [ ] The same command on an issue that already has a capture (#1263, `PROJECT/1-INBOX/GH-1263-HQ-PARK-RATING-GRAMMAR.md`; or #1258 once its PR merges) exits 1 naming the existing doc and writes nothing (recorded); the preview witness above must use a different, unregistered issue.
- [ ] `bash utils/hq/hq.sh park --title "x" XYZ-forge "fresh request"` (no `--gh-issue`) previews byte-identically to the base (both exit 0, non-empty, `diff` empty; recorded). `bash test/hq-park.sh` passes on the final commit.

## Verification

Existing suite `test/hq-park.sh` (GH-831: no new tests); the four witnesses are manual checks recorded under `TESTS-RESULTS/<date>+GH-<this>/` with `provenance.jsonl` in the same PR. The one real registration in item 2 is an intake the repo wants anyway; its capture and row are reported, not committed, by the witness.

## Non-goals

No bulk mode (one issue per call; a loop is the caller's); no rewriting of the existing issue body or title; no rating (that stays `releases roadmap rate`); no change to `queue` or `promote`; no fix for #1263's title hazard. The `--create` witness leaves a real capture and ledger row in the primary; they are reported as intake for the operator to commit, and reverted in the task clone before the PR commit so the diff stays inside the artifacts.

## Risk and rollback

Risk: adopting an issue whose body is empty renders a capture with an empty `## Idea`; the existing TODO stubs still make the doc valid, and the operator sees it in preview. Rollback: revert the commit; captures and rows already written keep their value.

## PRS proposal

- pri 70: it is the missing CLI step for the 204 unregistered issues and the prerequisite of #1258 Phase 3; the hand path is error-prone (#1263).
- sev 50: today each hand registration risks a wrong title, a missed row or a pre-rated row; recoverable, no data lost.
- appeal 50: operator did not set a preference.
- effort 75: about twenty lines reusing the registration half of `cmd_park`, parser mirrored from `queue`, existing suite covers the file.

## Preflight Contract

```json
{
  "target": { "repo": ".", "ref": "development" },
  "gate": "bash test/hq-park.sh",
  "fix_probes": [
    { "type": "grep_absent", "path": "utils/hq/hq.sh", "pattern": "issue view",
      "note": "pre-fix: cmd_park never calls gh issue view (0 matches at development); landed when the adopt branch does" }
  ],
  "artifacts": [ "utils/hq/hq.sh", "skills/2-daily/hq/SKILL.md" ],
  "remediation": {
    "source": "issue#<this>",
    "criteria": "park accepts --gh-issue N; with it, cmd_park refuses an already-registered issue, fetches url/title/body with gh issue view, skips dup guard and gh issue create, and reuses the unchanged capture + roadmap add path. No bulk mode, no rating, no new test (GH-831)."
  }
}
```

Recon: e305cbf3 · base: development@e305cbf3 · tier: standard · review: consult relay-system/2026-10-30/gh-idea-C-draft-113616 models=codex,agy hash 8c80eac8078a90918c372fdbd2fd1d3a8d625160d71b3645f25c3cb4387fa884

## Why

cmd_park conflates creating the issue with registering its intake; 204 of 281 open issues have no row and the only path is a hand sequence (the one that exposed #1263).

## Phase 0 — Explore & scope

### Checklist

- [ ] TODO: scope-specific checklist items for this idea's Phase 0 pass.

### QA checklist — Phase 0

- [ ] TODO: acceptance criteria for the Phase 0 pass above.
