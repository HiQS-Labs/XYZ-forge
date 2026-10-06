# Final QA relay — GH-976 implementation
STATUS: Open
NEXT: codex (Reviewer)

## Your role

You are the **reviewer**. Review-only turn: `ALLOW_PATHS` is empty; write only this relay file.
Do not edit source, plan, or evidence. No `validate.sh`, `test/*.sh`, or executable fixtures in the
worktree (read-only probes under `.relay-scratch/` are fine).

## What to review

The committed implementation of the plan you approved in `relay-system/2026-10-05/gh976-plan-qa-codex.md`:

- `utils/py/relay_drive.py` — the new `commits_touch_non_receipt()` helper and the oracle call site
  (`git log -1 --stat`, `git show HEAD -- utils/py/relay_drive.py`).
- `PROJECT/2-WORKING/GH-976-RELAY-RECEIPT-ONLY-PROGRESS.md` — the approved plan, status updated.
- `TESTS-RESULTS/2026-10-05+GH-976/` — `SUMMARY.md`, `provenance.jsonl` (ten control runs plus the
  existing suite run), and the control script `gh976-controls.sh`.
- `CHANGELOG.md` top entry.

Operational envelope: a local CLI relay supervisor for one developer's headless agent loops. This repo
forbids new test suites and `validate.sh` registry entries (GH-831); the diff must contain neither.

## Definition of Done

1. **Does the code match the approved plan?** Receipt directories with trailing slashes; relay file
   excluded only when it resolves inside `target_repo()`; `git diff --name-only before..after` in that
   repo; False on empty SHA or git error; resolved-items arm and hard ceiling untouched; the frozen
   Bash twin untouched. Cite file:line for any deviation.
2. **Is any real repair wrongly classified as a receipt?** Consider a builder whose only change is
   under one of the excluded prefixes, and a relay file path that collides with a target file name.
3. **Does the evidence substantiate the claims?** Read `provenance.jsonl`: are the base runs for A/B
   genuine failures of the candidate expectation, do C/D prove the HEAD arm still extends, does E
   cover the no-SHA branch, is the suite run present and green, and are the expected exits honest?
   Note the fixture retry around `index.lock` recorded in `SUMMARY.md`; say whether it masks anything.
4. **Scope hygiene.** Any new suite, registry entry, gate machinery, unrelated refactor, or accidental
   file in the diff?
5. **Issue mapping.** Does the change satisfy the current acceptance list on issue #976 (receipt-only
   → `cap-stalled` at the original cap, no `Extension · System`; real-file still extends; gh115 suite
   green)? Is the persisted rating `80/75/50/85` still consistent with the evidence?

Rate findings `[Blocker]`, `[Must]`, `[Should]`, `[Note]`; behaviour-change requests carry
`Observed input:`, `Affected scope:`, `Falsifier:`. Set `STATUS: Approved` only if the implementation
is correct and the evidence supports it; otherwise `STATUS: Changes requested`.

## Round log

<!-- ▽ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK ▽ -->
▶ TAKE YOUR TURN (codex)
<!-- △ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK △ -->
