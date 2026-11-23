# Plan draft: #1265 consult: add the installed kimi and cmd seats so a degraded pair can be re-fired without API keys

> draft; preflight and independent plan QA outstanding

- Request: `gh-1265-89200a349cde` (tick `slot_035`)
- Draft status: **ready**
- Planner state: ready; flags: none
- Rating: 50/40/50/70
- Capture doc: PROJECT/1-INBOX/GH-1265-CONSULT-INSTALLED-KIMI-CMD.md (sha256 28dd6c39bf628bb29ce90eb210c9a8d9b341da6540aad86cd662f2191e434a73)
- Issue sha256: 89200a349cde9cf4d949676405da391177d9749a55fc46985232924b9e3aea87 (updated 2026-10-30T16:49:58Z)
- Dependencies: none

## Scope

_Source: PROJECT/1-INBOX/GH-1265-CONSULT-INSTALLED-KIMI-CMD.md:L132 (Phase 0 — Explore & scope)_

### Checklist

- [ ] TODO: scope-specific checklist items for this idea's Phase 0 pass.

### QA checklist — Phase 0

- [ ] TODO: acceptance criteria for the Phase 0 pass above.

_Source: PROJECT/1-INBOX/GH-1265-CONSULT-INSTALLED-KIMI-CMD.md:L23 (frontmatter goal)_

TODO: one-paragraph statement of what "done" looks like for this idea.

## Acceptance criteria

_Source: issue#1265:L35 (Acceptance)_

- [ ] `relay-automation/consult.sh --prompt "Reply with the single word OK." --models kimi --label probe` exits 0 with one non-empty `answer-*.md` whose payload contains `OK` (recorded). Red control: on the base the same command prints `unknown model 'kimi' — skipping` and exits 2 (no valid model reaches `die`, `consult.py:185,862`; recorded).
- [ ] The same for `--models cmd` (recorded; if `cmd` is not authenticated on the box, the run must fail as a stated advisor failure, not a silent 0, and the receipt says so).
- [ ] Neutralizer witness: a prompt that makes the seat name its vendor ("state your vendor") yields a neutral payload with no `kimi`, `moonshot`, `cmd` or `commandcode` token (recorded). Red control: on the base, an in-memory `_neutralize_answer_text` replay of "I am kimi from Moonshot" keeps `Moonshot` (recorded).
- [ ] `--models codex,agy` output layout is unchanged: both runs exit 0 and both produce `answer-A.md`, `answer-B.md` and `key.json` (asserted present and non-empty before comparing), and the sorted file-name sets are equal (an empty pair does not pass; recorded).
- [ ] `bash test/consult.sh` passes on the final commit.

_Source: PROJECT/1-INBOX/GH-1265-CONSULT-INSTALLED-KIMI-CMD.md:L81 (Acceptance)_

- [ ] `relay-automation/consult.sh --prompt "Reply with the single word OK." --models kimi --label probe` exits 0 with one non-empty `answer-*.md` whose payload contains `OK` (recorded). Red control: on the base the same command prints `unknown model 'kimi' — skipping` and exits 2 (no valid model reaches `die`, `consult.py:185,862`; recorded).
- [ ] The same for `--models cmd` (recorded; if `cmd` is not authenticated on the box, the run must fail as a stated advisor failure, not a silent 0, and the receipt says so).
- [ ] Neutralizer witness: a prompt that makes the seat name its vendor ("state your vendor") yields a neutral payload with no `kimi`, `moonshot`, `cmd` or `commandcode` token (recorded). Red control: on the base, an in-memory `_neutralize_answer_text` replay of "I am kimi from Moonshot" keeps `Moonshot` (recorded).
- [ ] `--models codex,agy` output layout is unchanged: both runs exit 0 and both produce `answer-A.md`, `answer-B.md` and `key.json` (asserted present and non-empty before comparing), and the sorted file-name sets are equal (an empty pair does not pass; recorded).
- [ ] `bash test/consult.sh` passes on the final commit.

## Open questions

_missing_

## Write set

- `utils/py/consult.py` (PROJECT/1-INBOX/GH-1265-CONSULT-INSTALLED-KIMI-CMD.md:preflight-contract)
- `skills/1-hourly/consult/SKILL.md` (PROJECT/1-INBOX/GH-1265-CONSULT-INSTALLED-KIMI-CMD.md:preflight-contract)

## Unresolved file names

- none

## Contract probes

- grep_absent `utils/py/consult.py`: unfixed

## Existing preflight contract

```json
{
  "artifacts": [
    "utils/py/consult.py",
    "skills/1-hourly/consult/SKILL.md"
  ],
  "fix_probes": [
    {
      "note": "pre-fix: no kimi branch in the dispatch; landed when present",
      "path": "utils/py/consult.py",
      "pattern": "m == \"kimi\"",
      "type": "grep_absent"
    }
  ],
  "gate": "bash test/consult.sh",
  "remediation": {
    "criteria": "kimi and cmd dispatch branches mirroring agy with each shim's own invocation (KIMI_BIN / COMMANDCODE_BIN --print), vendor words added to the neutralizer, Python --help and skill text; the frozen Bash twin is untouched; no automatic fallback, no new test (GH-831).",
    "source": "issue#<this>"
  },
  "target": {
    "ref": "development",
    "repo": "."
  }
}
```
