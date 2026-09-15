# GH-592 — express provenance receipt: witnessed controls

Tested implementation: commit `acff869ce90ff62619c95cb2fd793b7d22405818` on `fix/gh592-express-receipt`, 2026-09-13, disposable clone, working tree clean
(the receipts' `commit` field names exactly this commit; PR #597).

## Red controls (the gate can fail)
- `test/gh425-gate-provenance-pr.sh::test_cli_commit_landing_gate_express_receipt`
  - (a) empty `TESTS-RESULTS/`, `wave_reconcile.py --commit A --gate --offline … --dry-run` → **exit 6**, `No provenance.jsonl or error_log.jsonl entry matches`
  - (b) receipt written by `express.write_receipt(A)` → the real `check_provenance_receipts` passes
  - (c) same receipt vs declared commit B → **exit 6** (B is declared in the offline manifest, so the matcher — not exit 4 — decides)
  - predicate rejects rc=1 / wrong suite / wrong issue / wrong commit / string rc / explicit `pr` field; bare and `test/` suite spellings are one expectation; unterminated prior line separated before appending; a valid record lacking its final newline is preserved intact; the ONLY record for a third sha behind a symlink in a first-sorted directory is not found by `find_receipt` (removing the guard flips this); the writer refuses to append through a symlink and the target is untouched
- `test/gh267-express-skill.sh` controls: (i) unrelated `TESTS-RESULTS/unrelated/provenance.jsonl` injected after the clean-development check → closeout refuses by name, remote == post-fix-push sha; (ii) `write_receipt` mutated to return the path without writing → `express-reconcile-failed` with the missing-receipt message; (iii) resume with no receipt → refused before issue close, recipe pointer printed; (iv) rc=1 / wrong-suite / wrong-issue / malformed records → refused; (v) valid committed receipt, reconcile never ran → resume passes `--gate`, second resume appends nothing; (vi) valid receipt in an ignored (uncommitted) path → refused (evidence is read from HEAD); (vii) committed record carrying an explicit `pr` field → refused; (viii) committed symlinked `provenance.jsonl` → refused (HEAD reader skips mode 120000); `docs` without `--suite` → refused with nothing written.

## Driver production (green)
- Normal fixture landing creates `TESTS-RESULTS/<date>+GH-999-express/provenance.jsonl` with exactly one record for the landing sha: `command == "bash test/gh999-demo.sh"`, `rc == 0`, `gate == "express-suite"`, `issue == 999`; the ship commit lists exactly that file; the gated reconcile outcome is printed in the landing output.

## Not exercised by a test (stated limit)
- The recovery recipe in `skills/express/SKILL.md` (identity snapshot around a rerun at the landing commit) is documentation executed by an operator; there is no recovery CLI to drive from a test (plan-QA R11 ruled one out). Its shell fails closed by construction (`set -euo pipefail`, git exit codes, `snap()` abort chain).

## Totals
- gh267-express-skill: pass=95 fail=0 · gh425-gate-provenance-pr: Ran 14 tests in 0.032s, OK
