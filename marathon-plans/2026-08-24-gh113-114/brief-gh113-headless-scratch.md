# Lane brief — GH-113: sanctioned scratch lane for headless builder turns

Execution surface of record: `PROJECT/2-WORKING/GH-113-HEADLESS-SCRATCH-CONTAINMENT.md`
(issue: https://github.com/HiQS-Labs/XYZ-forge/issues/113)

## Task

Headless builder prompts rely on prose ("no root scratch files") that the model ignores while
debugging. There is no sanctioned writable scratch lane in the turn's ALLOW_PATHS, so any temp
file is an off-allowlist change and the guard's only move is revert-and-fail (exit 6).

1. `utils/py/agy-turn.py` (authoritative Python lane; the Bash twin is FROZEN per GH-308):
   provision a per-turn scratch dir (`.relay-scratch/<turn>/`, already gitignored per GH-91),
   export it as TMPDIR/scratch guidance in the builder prompt, and add it to the turn's
   allowlist.
2. `utils/py/marathon_drive.py`: same provisioning for marathon-generated turns.
3. Soft-landing in `rtl_check()`: a ROOT-level scratch-shaped file (small extension allowlist)
   is MOVED into the turn scratch dir with a warning instead of failing the turn; genuinely
   off-lane edits to tracked files still exit 6, unchanged.
4. `test/gh113-headless-scratch.sh` (new): a synthetic turn that writes `tmp.json` at root
   completes with the file relocated and turn exit 0; an off-lane tracked-file edit still
   exits 6. Register in validate.sh TESTS.

## Definition of done

- Daybreak-wave-2 repro shape (root `tmp.json` during a builder turn) no longer fails the
  turn — the file relocates to the sanctioned scratch lane.
- Containment still refuses an off-lane edit to a tracked file (exit 6 unchanged).
- `test/gh113-headless-scratch.sh` green and registered in validate.sh.
- `bash validate.sh` green.
