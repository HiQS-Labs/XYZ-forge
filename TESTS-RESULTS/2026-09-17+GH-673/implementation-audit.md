# GH673 bounded implementation audit

Codex CLI one-shot advisory, 2026-09-17, input candidate 97bfaaa5.
1 answered, 0 failed; mechanically stamped NO FIRSTHAND VERIFICATION CITED.
Not a driven relay turn, final approval, qualifying gate or promotion evidence.
Both Should findings below were independently reproduced and repaired in 1331d96b;
39 focused checks pass and deletion controls fail. Remaining final gates stay open.
Raw full transcript remains local ignored scratch; only the final answer follows.

ANSWER: The core repairs hold on inspection, but two concrete [Should] gaps remain. This is advisory, not final approval.

- **[Should] Equal-time native duplicates omit identity from conflict detection.** `src/flightdeck/connectors.py:342` compares only state, labels and closure reason; `:353` keeps the first duplicate. An otherwise identical foreign-URL row can therefore make identity validity depend on row ordering. My in-memory reproduction returned `(identity_valid=True, conflict=False)` versus `(False, False)` when reversed. **Minimal fix:** include `native_item_identity(row)` in the duplicate signature; test both orderings.

- **[Should] Root errors overwrite per-row errors.** `src/flightdeck/connectors.py:112` replaces `unqualified-ledger-row` with a root error. A mocked 2001-row report reproduced only `issue-cap` in the retained evidence. Confirmation remains conservative, but the identity diagnostic is lost. **Minimal fix:** preserve the row error separately from the root error; assert both survive.

- **[Pass] Unqualified helper rows cannot establish or close work.** Helper-owned identity remains available while invalid rows receive no lifecycle evidence (`utils/py/releases_app.py:5345`, `:5356`). The connector clears label/start/lifecycle and records an issue-scoped gap (`src/flightdeck/connectors.py:90`). Unresolvable rows are counted (`:79`); unrelated qualified peers remain usable.

- **[Pass] Canonical duplicates and error-only quiet cards remain conservative.** Evidence accumulates instead of overwriting (`src/flightdeck/aggregate.py:121`). Errors withhold confirmation, conflicting signatures remain conflicts, and error-only cards are selected (`web/flightdeck/issue-context.mjs:33`, `:35`, `:64`). Fresh, qualified native closure retains precedence and distinguishes cancellation (`:19`, `:24`).

- **[Pass] Drawer preservation uses current targets and shared derivation.** `web/flightdeck/app.js:207` resolves current native/inferred cards and compares complete handoff text, drawer title and read health. Missing targets close the drawer. Opening and revalidation share `detailContent` (`:273`, `:289`).

- **[Pass] Read-path containment is explicit.** The subprocess calls the helper directly, with isolated execution, streamed output/deadline limits and group cleanup (`utils/py/releases_cycle.py:51`, `:64`, `:72`, `:95`). Native SQLite reads use read-only mode, query-only enforcement and bounded waits/progress interruption (`src/flightdeck/connectors.py:263`). The ledger helper probes schema without migration (`utils/py/releases_app.py:5286`, `:5293`, `:5327`).

Read: the GH673 working document; all requested functions, direct helper dependencies/callers; retention/configuration callers; both populated Python test files, selector tests and browser regression source.

Tested: `node test/flightdeck/work-status-checks.mjs` passed; two synthetic, in-memory Python reproductions produced the findings above. No live data, edits, commits, pushes or harness tests.

Unverified: Python fixture-suite execution, real-browser behavior, WAL/source-preservation execution, cleanup under real subprocess load, final-tip broad gate, and comparison with the landed #646 producer.

RECOMMENDATION: Fix the two scoped gaps, then complete independent final review and the required disposable-clone gates.
