---
Goal: Final QA of the GH-807 fix (signal-triage quiet-grep false failure)
Date: 2026-09-24
Producer: claude-a
Reviewer: codex
NEXT: codex
STATUS: Open
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

