# GH-592 — express provenance receipt: witnessed controls

Head under test: `9dc6715acaf293c93d7241d54a33dc5c58245bea` (branch `fix/gh592-express-receipt`), 2026-09-13, disposable clone.

## Red controls (the gate can fail)
- `test/gh425-gate-provenance-pr.sh::test_cli_commit_landing_gate_express_receipt`
  - (a) empty `TESTS-RESULTS/`, `wave_reconcile.py --commit A --gate --offline … --dry-run` → **exit 6**, `No provenance.jsonl or error_log.jsonl entry matches`
  - (b) receipt written by `express.write_receipt(A)` → gate passes, `Provenance receipt matched for PR #<A[:12]>`
  - (c) same receipt vs declared commit B → **exit 6** (B is declared in the offline manifest, so the matcher — not exit 4 — decides)
- `test/gh267-express-skill.sh` controls: (i) unrelated `TESTS-RESULTS/unrelated/provenance.jsonl` injected after the clean-development check → closeout refuses by name, remote == post-fix-push sha; (ii) `write_receipt` mutated to return the path without writing → `express-reconcile-failed` with the missing-receipt message; (iii) resume with no receipt → refused before issue close, recipe printed; (iv) rc=1 / wrong-suite / wrong-issue / malformed records → refused; (v) valid committed receipt, reconcile never ran → resume passes `--gate`, second resume appends nothing.

## Driver production (green)
- Normal fixture landing creates `TESTS-RESULTS/<date>+GH-999-express/provenance.jsonl` with exactly one record for the landing sha: `command == "bash test/gh999-demo.sh"`, `rc == 0`, `gate == "express-suite"`, `issue == 999`; the ship commit lists it; the gated reconcile outcome is printed.

## Totals
- gh267-express-skill: pass=89 fail=0 · gh425-gate-provenance-pr: Ran 14 tests, OK
