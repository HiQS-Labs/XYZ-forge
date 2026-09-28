# #862 validation plan: report-issue checks, exercised for real (operator-authorized, 2026-09-27)

`practice_posting.py` follows `SKILL.md` §"Report Issue & Per-turn Comments" literally with `gh`. Each run uses one practice marker, `<!-- ci-suite-audit:practice862*:2026-09-27 -->`, that no real audit can have. It touches no other issue, creates no label, and closes what it opens.

| Run | Dedupe method | Result | Issues |
|---|---|---|---|
| 1 | `gh issue list --search` (as Agy's SKILL.md said) | **FAIL**: the re-run 3 s later opened a duplicate, because the search index missed the new issue | #871, #872 (both closed) |
| 2 | direct listing, `gh issue list --label ci`, matched locally | **FAIL**: listing is eventually consistent too (`open_matches: []` at re-run, `[873]` moments later) | #873, #874 (both closed) |
| 3 | local record, then listing | **VOID**: a relay containment step in the same clone reverted the working folder mid-run | #875 (closed) |
| 4 | local record, then listing (the SKILL.md fix) | **PASS**: the re-run found #876 through the local record while the listing still returned `[]`; it updated the body and added one delta comment | #876 (closed) |

Run 4 (`practice-run-4-record.json`), every check:
- **Filed once, dedupe:** same issue, `updated`, 1 delta comment.
- **Oversized report:** the full report is 108,722 characters (over 65,536). The body is 857 characters: summary, non-KEEP rows, reminders. The table spans 2 numbered comments: **411 of 411 rows, byte-identical to the source**.
- **Per-turn comments:** a decision turn adds exactly 1 comment; a no-decision turn adds 0.
- **Redaction:** no local path or token shape in anything posted.
- **Labels:** `ci` and `stability`; `radar` never used. The issue is closed with an evidence pointer.

**Fix carried in this PR (`SKILL.md` "Dedupe First").** Look first at a local record (`report-issue.txt`, written on creation), then at a direct listing matched locally, and never `--search`. Runs 1 and 2 are the red controls for this fix; run 4 is green.
