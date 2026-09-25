---
Goal: Final QA of the GH-807 fix (signal-triage quiet-grep false failure)
Date: 2026-09-24
Producer: claude-a
Reviewer: codex
NEXT: claude-a
STATUS: Approved
---

# Context

Review a committed, tested fix. Operational envelope: this is a ten-line test-harness repair in one
file plus a one-row ratchet baseline change. Grade against the issue's stated scope and
commensurate complexity — do not ask for frameworks, fuzzers, or abstractions.

Read:
- `PROJECT/2-WORKING/GH-807-SIGNAL-TRIAGE-QUIET-GREP.md` — plan, root cause, acceptance, rating.
- `git show HEAD -- test/signal-triage.sh test/baselines/GH-139-pipe-grep-baseline.txt` — the diff.
- `TESTS-RESULTS/2026-09-24+GH-807/` — red-control logs (unfixed, 8-wide parallel), green logs
  (fixed, serial + 8-wide), `provenance.jsonl`.
- Issue #807 scope list (quoted in the plan's Observed section).

# Questions

1. Does the diff replace **every** producer-into-grep pipeline in `test/signal-triage.sh` with the
   established capture/here-string pattern, preserving each assertion's semantics and messages?
   Cite any site changed in meaning, or any missed.
2. Is the red control genuine evidence? It shows 2/8 parallel runs at `0ae3452a` failing with
   `Broken pipe`. Is that the same failure shape as the issue's witnessed log, or a different one?
3. Is the GH-139 ratchet correctly moved forward (row removed, not relaxed), and does
   `test/gh139-pipe-grep-guard.sh` still enforce it for this file (a reintroduced pipe would fail)?
4. Does the persisted rating `55/45/50/92` match the evidence (sev/pri reasoning in the doc)?
5. Anything out of scope that slipped in, or any issue scope item not addressed?

Write your verdict as `### Round 1 · Reviewer · codex`, cite `file:line`, set `STATUS: Approved`
if it may ship as-is, else list required changes and leave `STATUS: Open`.

<!-- ▽ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK ▽ -->
▶ TAKE YOUR TURN (codex)
<!-- △ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK △ -->

# Log

### Round 1 · Reviewer · codex

**Verdict: Approved for the bounded GH-807 repair; no required code changes.** Reversibility: Easy, limited to assertion input plumbing and a stricter inventory baseline. The harness-owned final gate remains outstanding; this approval does not claim that gate passed.

1. **All ten sites addressed.** `test/signal-triage.sh:70`, `:76`, `:102`, `:114`, `:154`, `:159`, `:182`, `:190`, `:208`, and `:254` use here-strings. Complete source inspection and a nonempty-input static probe found ten here-strings and zero producer-into-grep pipelines. Patterns, assertion branches, and messages match the unfixed copy in `/Users/noelsaw/Documents/GH Repos/XYZ-forge/test/signal-triage.sh`; a filesystem diff shows exactly ten one-line replacements. No changed assertion meaning found for these JSON inputs. The remaining grep-to-tr pipelines at lines 207–208 consume their complete input and are not the quiet-grep producer hazard. Existing capture/error/empty-output handling at lines 59–67 is preserved.
2. **Red control is the same failure class, at a different assertion.** `TESTS-RESULTS/2026-09-24+GH-807/red-control-unfixed-0ae3452a-run1.log:20` and `red-control-unfixed-0ae3452a-run2.log:24` show echo's Broken pipe at line 76, followed by evidence-prefix failures even though the printed JSON contains the expected prefix (run 1 line 26; run 2 line 30). The witnessed issue failure was category matching at line 70 (`PROJECT/2-WORKING/GH-807-SIGNAL-TRIAGE-QUIET-GREP.md:39`). Both are early grep exit plus pipefail; this is not an exact reproduction of the same assertion, but it genuinely reproduces the mechanism. Independently counted all eight red logs: two fail, six pass; all nine green logs end 44 pass, 0 fail with no Broken pipe (e.g. `green-fixed-serial.log:48`). `provenance.jsonl:1` identifies the red base and host. Nine green runs support the repair; they are not a statistical proof of zero flakiness.
3. **Ratchet advances.** Filesystem comparison with the unfixed baseline shows only removal of `9 test/signal-triage.sh`, between the neighboring entries at `test/baselines/GH-139-pipe-grep-baseline.txt:31`. `test/gh139-pipe-grep-guard.sh:38` includes this file; lines 42 and 50–54 count the literal quiet-grep shape, default a missing row to zero, and fail growth. An in-memory probe using that detector/comparison returned 0 for the current nonempty file and 1 after adding one `echo "$json" | grep -q category` line. This is a focused comparison probe, not a rerun of the whole guard. The guard covers the established literal quiet-grep spelling, not every conceivable pipeline spelling or non-quiet grep.
4. **Rating is supported and persisted.** `releases.sql:736` stores priority/severity/appeal/effort as 55/45/50/92, consistent with `PROJECT/2-WORKING/GH-807-SIGNAL-TRIAGE-QUIET-GREP.md:73`: moderate gate reliability harm without data loss, recurrence raising priority, neutral appeal, and a small established repair. The tuple is priority first, severity second. The recurrence search's stated coverage limit is appropriate; I did not independently repeat that historical search.
5. **Scope and limits.** The inspected two-file repair has no extra behavior or framework. The documented focused acceptance is supported by the supplied logs and source; the full gate remains unchecked at `PROJECT/2-WORKING/GH-807-SIGNAL-TRIAGE-QUIET-GREP.md:69` and belongs to the harness under this turn's instructions. No Git commands or test suites were run. Consequently, the filesystem comparison is not authenticated against HEAD/base, and I make no exhaustive claim about other committed files. The relay says the issue scope list is quoted in Observed, but that section contains the witnessed failure rather than an explicit scope list; assessment here uses the plan's stated acceptance and non-goals.

Nonblocking documentation follow-up: the roadmap row at `releases.sql:736` still points to `PROJECT/1-INBOX/...` while the reviewed plan lives in `PROJECT/2-WORKING/...`; reconcile through the existing ledger CLI during normal closeout. The plan also cites pipefail as line 2 at line 48; the actual setting is `test/signal-triage.sh:26`. Neither affects this repair's behavior.

Review method: direct source/log inspection for shell and text artifacts; no graph completeness claim. Only this relay file was edited. NEXT is claude-a for handoff.
