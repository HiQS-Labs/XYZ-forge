---
Goal: QA Roadmap Ledger Fixes (GH-257)
Date: 2026-08-26
NEXT: Producer
STATUS: Open
---

# Context

Adjudicate the implementation of GH-257 (Roadmap ledger: malformed row validation, dropped row warnings, roadmap update subcommand, and staleness guard diagnosis).

Read the issue description and the modified files:
- utils/py/releases_app.py
- utils/roadmap-dashboard.sh
- githooks/dashboard-staleness-guard.sh
- test/gh257-roadmap-ledger-fixes.sh

Questions:

1. Does `validate_raw_text()` properly enforce markdown bold bullet shape (`- **<title>**`) and refuse malformed shapes (like `- [ ] #255 ...`) at write time for both `roadmap add` and `roadmap update`?
2. Does `utils/roadmap-dashboard.sh` accurately detect and report dropped unparseable rows to stderr with clear IDs without breaking the rendered output?
3. Does `releases roadmap update` safely and idempotently update a parked row's `raw_text` (and derived rating scores if present) with an auditable `roadmap-update` receipt?
4. Does `githooks/dashboard-staleness-guard.sh` distinguish between actionable drift vs the no-diff scenario when ledger changed but dashboard diff is empty, providing achievable remediation steps?
5. Does `test/gh257-roadmap-ledger-fixes.sh` comprehensively test all 4 tasks and prevent regressions?

Flag anything wrong, missing, incorrectly scoped, or over/under-engineered. Be concrete and cite file:line where you disagree with a specific claim.

Write your verdict below and change the STATUS to Approved/Closed if it passes.

<!-- ▽ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK ▽ -->
▶ TAKE YOUR TURN (codex)
<!-- △ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK △ -->

## Codex review — 2026-08-26

**Grade:** D

**Verdict:** Changes requested

### Blocking findings

1. **[Blocker] The write-time validator does not enforce the renderer's actual prefix.**
   `validate_raw_text()` strips the value and accepts `^-\s+\*\*` at
   `utils/py/releases_app.py:2784-2786`, while the renderer accepts only an exact `- **` prefix at
   `utils/roadmap-dashboard.sh:189`. Because Python `\s+` includes tabs, repeated spaces, and
   newlines, inputs such as `-   **GH-255 · title**` and `-\n**GH-255 · title**` pass both
   `roadmap add` and `roadmap update` but are subsequently dropped. Require the exact renderer
   grammar (including a non-empty, closed bold title) from one shared contract, and add negative
   controls for repeated whitespace, a tab, a newline, and an empty title.

2. **[Blocker] `roadmap update` can make `raw_text` disagree with its derived rating columns.**
   The mutation updates rating columns only when the new line contains a rating
   (`utils/py/releases_app.py:3029-3033`). If a rated row is updated to an unrated line, the else
   branch at `:3034-3037` changes only `raw_text` and leaves the old scores behind. Conversely, if
   rating columns are absent, a newly rated line is accepted and its derived scores are silently
   discarded; unlike `roadmap add` at `:2852-2860`, update has no `schema-behind` refusal. Always
   synchronize all five rating columns with `parse_rating()` (including clearing them to NULL), and
   refuse a rated update when the schema cannot store the scores.

### Additional findings

3. **[Should] The renderer's drop detector validates only the opening token, not the shape it
   parses.** `utils/roadmap-dashboard.sh:189` treats every line beginning `- **` as parseable, but
   `parseBullet()` requires a closing `**` at `:113-116`. An unterminated row such as
   `- **GH-255 malformed` therefore produces no dropped-row warning and is rendered through the
   fallback title path. Use the same complete predicate for admission and parsing so every rejected
   shape is named on stderr.

4. **[Should] The guard classifies commit-range drift using mutable working-tree state.** The range
   is computed from `remote_sha`/`local_sha` at `githooks/dashboard-staleness-guard.sh:31-43`, but
   the decisive `roadmap-dashboard.sh --check` at `:48-54` reads the current checkout rather than
   `local_sha`. Uncommitted DB/dashboard edits can therefore select the wrong remedy for the push.
   Run the diagnosis against a commit-pinned temporary projection (or explicitly prove and enforce
   a clean checkout before relying on this classification).

5. **[Should] The regression test is not comprehensive enough to catch the blockers above.**
   `test/gh257-roadmap-ledger-fixes.sh:27-72` covers only the checkbox shape and a normal valid
   line, so the validator/renderer whitespace mismatch and unterminated-bold case pass unnoticed.
   The update checks at `:75-99` do not prove dry-run non-mutation, idempotency/no second receipt,
   rating derivation, rating removal, or schema-behind refusal. The no-diff guard case at `:133-149`
   appends an unrelated SQL comment rather than constructing the historical malformed-row state,
   so it verifies message wording but not the original end-to-end diagnosis.

### Passing portions

6. **[Pass] The original checkbox failure is refused on both exposed write paths.** Add calls
   `validate_raw_text()` at `utils/py/releases_app.py:2807-2809`, update calls it at `:3010`, and
   the malformed `- [ ] #255 ...` cases are asserted at
   `test/gh257-roadmap-ledger-fixes.sh:27-38` and `:63-72`.

7. **[Pass] Dropped checkbox-style rows are reported without corrupting rendered stdout.** The
   renderer accumulates IDs at `utils/roadmap-dashboard.sh:189-204`, writes the summary only to
   stderr at `:207-210`, and continues building normal output at `:212-238`.

8. **[Pass] The update command has the right transactional and idempotent skeleton.** An unchanged
   value returns before writing at `utils/py/releases_app.py:3011-3014`; a real mutation goes
   through `perform_write(..., "roadmap-update", ...)` at `:3039`, providing the requested receipt.
   The rating consistency blocker above must be fixed before this is safe to approve.

9. **[Pass] The staleness guard now distinguishes drift from no-diff and keeps the intended
   refusal.** The two messages branch at `githooks/dashboard-staleness-guard.sh:45-84`; the no-diff
   path no longer repeats the impossible instruction to commit an unchanged dashboard and instead
   points to renderer warnings plus `roadmap update`. Finding 4 concerns the state used to choose
   the branch, not the remedy text itself.

**Verification:** Read-only review of the GH-257 issue and the four named implementation/test
surfaces. Per reviewer containment instructions, no Git command, source/artifact execution, or
project gate was run; the harness owns execution verification.
