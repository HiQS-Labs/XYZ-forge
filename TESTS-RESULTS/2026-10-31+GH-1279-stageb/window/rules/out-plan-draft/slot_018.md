# Plan draft: #1267 hq park --gh-issue: register an already-filed issue (capture + ledger row) without creating a new one

> draft; preflight and independent plan QA outstanding

- Request: `gh-1267-d0a97acdebba` (tick `slot_018`)
- Draft status: **ready**
- Planner state: ready; flags: none
- Rating: 70/50/50/75
- Capture doc: PROJECT/1-INBOX/GH-1267-HQ-PARK-GH-ISSUE.md (sha256 9de7f46a02388aadcca0f9fd3737a3ad1d6d58ba904d6e71c784128274072000)
- Issue sha256: d0a97acdebbae1329813f97a01e87a475c655a04003f97f66b3d62739b2bf9b9 (updated 2026-10-30T16:51:39Z)
- Dependencies: none

## Scope

_Source: PROJECT/1-INBOX/GH-1267-HQ-PARK-GH-ISSUE.md:L136 (Phase 0 — Explore & scope)_

### Checklist

- [ ] TODO: scope-specific checklist items for this idea's Phase 0 pass.

### QA checklist — Phase 0

- [ ] TODO: acceptance criteria for the Phase 0 pass above.

_Source: PROJECT/1-INBOX/GH-1267-HQ-PARK-GH-ISSUE.md:L25 (frontmatter goal)_

TODO: one-paragraph statement of what "done" looks like for this idea.

## Acceptance criteria

_Source: issue#1267:L38 (Acceptance)_

- [ ] `bash utils/hq/hq.sh park --gh-issue <N> XYZ-forge` (preview) on an open issue with no capture prints the existing issue URL and title and the capture that would be written, whose `## Idea` contains a known non-empty substring of that issue's body, and writes nothing. Red control: on the base the same command exits 1 with `hq park: '--gh-issue' is UNRESOLVED` (the flag is swallowed as the project name; recorded).
- [ ] `bash utils/hq/hq.sh park --create --gh-issue <N> XYZ-forge` on that issue writes `PROJECT/1-INBOX/GH-<N>-*.md` whose `gh_issue:` is `<N>` and whose `## Idea` is non-empty, and exactly one ledger row with `issue_url` equal to the existing issue; and creates no GitHub issue: `gh issue list --state all --limit 1 --json number --jq '.[0].number'` is the same non-empty integer before and after (a plain `gh issue list` count is capped at 30 and proves nothing; recorded).
- [ ] The same command on an issue that already has a capture (#1263, `PROJECT/1-INBOX/GH-1263-HQ-PARK-RATING-GRAMMAR.md`; or #1258 once its PR merges) exits 1 naming the existing doc and writes nothing (recorded); the preview witness above must use a different, unregistered issue.
- [ ] `bash utils/hq/hq.sh park --title "x" XYZ-forge "fresh request"` (no `--gh-issue`) previews byte-identically to the base (both exit 0, non-empty, `diff` empty; recorded). `bash test/hq-park.sh` passes on the final commit.

_Source: PROJECT/1-INBOX/GH-1267-HQ-PARK-GH-ISSUE.md:L86 (Acceptance)_

- [ ] `bash utils/hq/hq.sh park --gh-issue <N> XYZ-forge` (preview) on an open issue with no capture prints the existing issue URL and title and the capture that would be written, whose `## Idea` contains a known non-empty substring of that issue's body, and writes nothing. Red control: on the base the same command exits 1 with `hq park: '--gh-issue' is UNRESOLVED` (the flag is swallowed as the project name; recorded).
- [ ] `bash utils/hq/hq.sh park --create --gh-issue <N> XYZ-forge` on that issue writes `PROJECT/1-INBOX/GH-<N>-*.md` whose `gh_issue:` is `<N>` and whose `## Idea` is non-empty, and exactly one ledger row with `issue_url` equal to the existing issue; and creates no GitHub issue: `gh issue list --state all --limit 1 --json number --jq '.[0].number'` is the same non-empty integer before and after (a plain `gh issue list` count is capped at 30 and proves nothing; recorded).
- [ ] The same command on an issue that already has a capture (#1263, `PROJECT/1-INBOX/GH-1263-HQ-PARK-RATING-GRAMMAR.md`; or #1258 once its PR merges) exits 1 naming the existing doc and writes nothing (recorded); the preview witness above must use a different, unregistered issue.
- [ ] `bash utils/hq/hq.sh park --title "x" XYZ-forge "fresh request"` (no `--gh-issue`) previews byte-identically to the base (both exit 0, non-empty, `diff` empty; recorded). `bash test/hq-park.sh` passes on the final commit.

## Open questions

_missing_

## Write set

- `utils/hq/hq.sh` (PROJECT/1-INBOX/GH-1267-HQ-PARK-GH-ISSUE.md:preflight-contract)
- `skills/2-daily/hq/SKILL.md` (PROJECT/1-INBOX/GH-1267-HQ-PARK-GH-ISSUE.md:preflight-contract)

## Unresolved file names

- none

## Contract probes

- grep_absent `utils/hq/hq.sh`: unfixed

## Existing preflight contract

```json
{
  "artifacts": [
    "utils/hq/hq.sh",
    "skills/2-daily/hq/SKILL.md"
  ],
  "fix_probes": [
    {
      "note": "pre-fix: cmd_park never calls gh issue view (0 matches at development); landed when the adopt branch does",
      "path": "utils/hq/hq.sh",
      "pattern": "issue view",
      "type": "grep_absent"
    }
  ],
  "gate": "bash test/hq-park.sh",
  "remediation": {
    "criteria": "park accepts --gh-issue N; with it, cmd_park refuses an already-registered issue, fetches url/title/body with gh issue view, skips dup guard and gh issue create, and reuses the unchanged capture + roadmap add path. No bulk mode, no rating, no new test (GH-831).",
    "source": "issue#<this>"
  },
  "target": {
    "ref": "development",
    "repo": "."
  }
}
```
