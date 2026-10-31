# Plan draft: #1263 hq park: rating grammar in the title pre-rates the ledger row or leaves intake half-complete

> draft; preflight and independent plan QA outstanding

- Request: `gh-1263-cc3112346a3d` (tick `slot_020`)
- Draft status: **ready**
- Planner state: ready; flags: none
- Rating: 55/45/50/90
- Capture doc: PROJECT/1-INBOX/GH-1263-HQ-PARK-RATING-GRAMMAR.md (sha256 869909c5f070da86c88b18792550d6bf250dc22175b46fb5bb19c631b16c632d)
- Issue sha256: cc3112346a3d6196b494d70feaa4f6da89d24b9bd3d1a2222176abb1f549a8ef (updated 2026-10-30T16:28:08Z)
- Dependencies: none

## Scope

_Source: PROJECT/1-INBOX/GH-1263-HQ-PARK-RATING-GRAMMAR.md:L131 (Phase 0 — Explore & scope)_

### Checklist

- [ ] TODO: scope-specific checklist items for this idea's Phase 0 pass.

### QA checklist — Phase 0

- [ ] TODO: acceptance criteria for the Phase 0 pass above.

_Source: PROJECT/1-INBOX/GH-1263-HQ-PARK-RATING-GRAMMAR.md:L22 (frontmatter goal)_

TODO: one-paragraph statement of what "done" looks like for this idea.

_Source: codex-authored (codex-authored)_

Verify the issue remains open and reproduce the title parsing behavior against the current code.

_Source: codex-authored (codex-authored)_

Plan an early guard on the computed park title for rating-token presence across preview, Tier C, and create paths, before any writes.

_Source: codex-authored (codex-authored)_

Record the requested manual verification and run the existing focused hq park suite.

## Acceptance criteria

_Source: issue#1263:L36 (Acceptance)_

- [ ] `bash utils/hq/hq.sh park --title "Handle rated 80/55/50/65 placeholders" XYZ-forge "probe"` (preview, no `--create`) exits 2 and names `releases roadmap rate`; nothing is created. Red control: the same command on `development@e305cbf3` previews normally (exit 0); both recorded under `TESTS-RESULTS/<date>+GH-<this>/`.
- [ ] `… --title "Fix rated 5/5 placeholder" …` and `… --title "Rank ovr 200 example" …` exit 2 the same way, before any write. Red control: on the base, preview exits 0 and renders the token (preview never calls `parse_rating`, `hq.sh:279-300`); the separate pure-parser witness (`hq_roadmap_line` piped to `parse_rating`) refuses `rating-shape` with exit 3; both recorded.
- [ ] `bash utils/hq/hq.sh park XYZ-forge "rated 80/55/50/65 should not leak from a request opening"` (no `--title`) exits 2 the same way; the guard runs on the computed title. Red control: base previews normally (recorded).
- [ ] `… --title "Add idea intake skill" …` previews exactly as on the base: both commands exit 0, both outputs are non-empty and contain the title and the rendered capture, and the two outputs are byte-identical (recorded; an empty pair does not pass). `bash test/hq-park.sh` passes on the final commit.

_Source: PROJECT/1-INBOX/GH-1263-HQ-PARK-RATING-GRAMMAR.md:L81 (Acceptance)_

- [ ] `bash utils/hq/hq.sh park --title "Handle rated 80/55/50/65 placeholders" XYZ-forge "probe"` (preview, no `--create`) exits 2 and names `releases roadmap rate`; nothing is created. Red control: the same command on `development@e305cbf3` previews normally (exit 0); both recorded under `TESTS-RESULTS/<date>+GH-<this>/`.
- [ ] `… --title "Fix rated 5/5 placeholder" …` and `… --title "Rank ovr 200 example" …` exit 2 the same way, before any write. Red control: on the base, preview exits 0 and renders the token (preview never calls `parse_rating`, `hq.sh:279-300`); the separate pure-parser witness (`hq_roadmap_line` piped to `parse_rating`) refuses `rating-shape` with exit 3; both recorded.
- [ ] `bash utils/hq/hq.sh park XYZ-forge "rated 80/55/50/65 should not leak from a request opening"` (no `--title`) exits 2 the same way; the guard runs on the computed title. Red control: base previews normally (recorded).
- [ ] `… --title "Add idea intake skill" …` previews exactly as on the base: both commands exit 0, both outputs are non-empty and contain the title and the rendered capture, and the two outputs are byte-identical (recorded; an empty pair does not pass). `bash test/hq-park.sh` passes on the final commit.

_Source: codex-authored (codex-authored)_

Titles containing rating grammar are refused with exit 2 and guidance to use releases roadmap rate before any issue, capture, or queue write.

_Source: codex-authored (codex-authored)_

The guard also covers titles derived from request text and malformed or truncated rating tokens.

_Source: codex-authored (codex-authored)_

Neutral titles continue through the existing flow, and the existing hq park suite passes.

_Source: codex-authored (codex-authored)_

The rating parser and ledger-line construction remain unchanged, with no title rewriting or new test suite.

## Open questions

_Source: codex-authored (codex-authored)_

What are the remaining acceptance witnesses beyond the truncated issue body, and have related changes already landed?

_Source: codex-authored (codex-authored)_

Does the proposed shell token check match the current parser's token-presence behavior for all relevant title inputs?

## Write set

- `utils/hq/hq.sh` (PROJECT/1-INBOX/GH-1263-HQ-PARK-RATING-GRAMMAR.md:preflight-contract)

## Unresolved file names

- none

## Contract probes

- grep_absent `utils/hq/hq.sh`: unfixed

## Existing preflight contract

```json
{
  "artifacts": [
    "utils/hq/hq.sh"
  ],
  "fix_probes": [
    {
      "note": "pre-fix: no refusal message in cmd_park; landed when the guard's message is present",
      "path": "utils/hq/hq.sh",
      "pattern": "title carries rating grammar",
      "type": "grep_absent"
    }
  ],
  "gate": "bash test/hq-park.sh",
  "remediation": {
    "criteria": "One refusal in cmd_park at the computed title (hq.sh:253) on the token-presence rule \\b(rated|ovr)\\s+\\d, ahead of Tier C, preview and create; message names releases roadmap rate. No change to parse_rating, hq_roadmap_line or roadmap add; no new test (GH-831).",
    "source": "issue#<this>"
  },
  "target": {
    "ref": "development",
    "repo": "."
  }
}
```
