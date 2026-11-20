# Final QA Delta Relay — GH-1548 (KS-05: Post-`origin/development` Merge)

STATUS: Approved

- **Issue:** #1548 (parent arc #1541, milestone KS-05)
- **Candidate Head (post-merge):** `cd5beb0f6485234fe75ac02a09c1eadaf2fafb4b`
- **Base Head (`origin/development`):** `6062aa2ea77a01a9d395f0cee971a0bdcf62c3e0`
- **Prior Approved Final QA:** `relay-system/2026-11-20/gh1548-final-qa.md` (Turn 8 `STATUS: Approved`)
- **Prior Approved Code SHA:** `b280e6709ce93b7e89676d0ac61c859bce119968`
- **Route:** `full`

## Turn 1 — Producer (Antigravity)

Candidate HEAD `cd5beb0f6485234fe75ac02a09c1eadaf2fafb4b` merges current `origin/development` (`6062aa2ea7`, including landed KS-02 and KS-04) into the Codex Final QA R4 Approved KS-05 branch (`relay-system/2026-11-20/gh1548-final-qa.md`, Turn 8 `STATUS: Approved`).

Delta summary:
- **0-byte code/skill delta** on `utils/py/harness.py`, `utils/py/relay_drive.py`, and `skills/1-hourly/relay-xyz/SKILL.md` vs R4-approved SHA `b280e6709ce93b7e89676d0ac61c859bce119968` (confirmed via `git diff`).
- Resolved `releases.db` / `releases.sql` by taking `origin/development` and re-registering GH-1548 via `releases_app.py roadmap pickup` (`roadmap_id: rmi-01M7W9MRP1BTEE1QAC6P0A7BGP`), synced into `PROJECT/2-WORKING/GH-1548-KS05-STOP-REASONS.md`.
- Kept both `CHANGELOG.md` entries cleanly; preserved all landed KS-02 (`build_queue.py`) and KS-04 (`kickstart_status.py`) code.
- Re-ran `TESTS-RESULTS/2026-11-20+GH-1548/outputs/controls-r3-probe.py . . TESTS-RESULTS/2026-11-20+GH-1548/outputs/controls-r3.txt`, `./utils/pdda/pdda.sh run` (saved to `outputs/pdda-run.log`), refreshed `outputs/code-and-docs.patch` against `origin/development..HEAD`, and regenerated `TESTS-RESULTS/2026-11-20+GH-1548/provenance.jsonl`.
- Prior disposable full gate (`outputs/disposable-full-gate.log`) remains retained and matched in `provenance.jsonl`.

Please verify that the merge preserved KS-02/KS-04 cleanly, that KS-05's current-base `outputs/code-and-docs.patch` contains only KS-05's approved changes, and that `provenance.jsonl` matches, then emit your Final QA Delta verdict.

**NEXT: Reviewer (Codex)**


## Turn 2 — Reviewer (Codex)

VERDICT: Approved — the merge preserves the approved KS-05 changes and the landed KS-02/KS-04 files.
STATUS: Approved

Reviewed candidate `cd5beb0f6485234fe75ac02a09c1eadaf2fafb4b` against declared base `6062aa2ea77a01a9d395f0cee971a0bdcf62c3e0` and prior approved code `b280e6709ce93b7e89676d0ac61c859bce119968`.

- **[Pass] Approved code preserved.** Read-only Python decoding of local loose/packed repository objects confirmed identical blob IDs for `utils/py/harness.py`, `utils/py/relay_drive.py`, and `skills/1-hourly/relay-xyz/SKILL.md` between candidate and prior approved code. Seeded files match those blobs byte for byte.
- **[Pass] KS-02/KS-04 preserved.** Candidate and base blobs are identical for `skills/1-hourly/kickstart/scripts/build_queue.py` (`0b7020217334b37d56cf3b3d732049b6f932b688`) and `skills/1-hourly/kickstart/scripts/kickstart_status.py` (`3a5f45449fb729531edf4b426ba4c4241aa77afc`); seeded files match. Complete tree-path comparison found no other runtime code delta against base beyond the two approved KS-05 Python files. Remaining changes are KS-05 docs, receipts, relay records, skill text and ledger files.
- **[Pass] Current-base patch exact.** `outputs/code-and-docs.patch` contains precisely the three approved code/skill paths. Its old/new object IDs match base/candidate. Independently applied every unified hunk in memory to base blob contents, asserting removed/context lines, and obtained exactly the candidate blob bytes for all three paths. The patch is code/skill-only despite its broader filename; it does not purport to contain the ledger or evidence delta.
- **[Pass] Delivered provenance matches.** All eight current manifest entries are nonempty and their SHA-256 hashes and byte lengths match. The retained gate log and done JSON still identify the prior approved code SHA, `validate_rc=0`, `elapsed_s=996`; the gate log retains matching PRE/POST identity snapshots. The refreshed PDDA log ends with no errors and 36 warnings. Prior Turn 8's nine-entry count describes that earlier manifest, not the current eight-entry manifest.

Read-only probes, with `export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"` and `mkdir -p "$TMPDIR"`:

1. `python3 -u "$TMPDIR/object_probe.py" > "$TMPDIR/object-results.txt"` — exit **0**. Scratch-only probe decoded commit/tree/blob objects and pack deltas directly using Python standard-library `pathlib`, `struct` and `zlib`; it invoked no Git executable, repository module or fixture. It compared complete base/candidate path maps, the five named files, patch object IDs and exact in-memory hunk application. Decisive output:
   ```text
   PRIOR_APPROVED_IDENTICAL utils/py/harness.py 3b9bfcbd25260fc300a36aa2beab20ef6b4575bc
   PRIOR_APPROVED_IDENTICAL utils/py/relay_drive.py 660bbb6b75ec4296a30bff42646ceeb0cb40d832
   PRIOR_APPROVED_IDENTICAL skills/1-hourly/relay-xyz/SKILL.md 5bec932c597ebcd6f9955b835d9ec5b2a19b4a7b
   BASE_IDENTICAL skills/1-hourly/kickstart/scripts/build_queue.py 0b7020217334b37d56cf3b3d732049b6f932b688
   BASE_IDENTICAL skills/1-hourly/kickstart/scripts/kickstart_status.py 3a5f45449fb729531edf4b426ba4c4241aa77afc
   PATCH_APPLIES_EXACTLY skills/1-hourly/relay-xyz/SKILL.md
   PATCH_APPLIES_EXACTLY utils/py/harness.py
   PATCH_APPLIES_EXACTLY utils/py/relay_drive.py
   ```
   An earlier probe used the incorrect assumed path `utils/py/build_queue.py` and exited 1 with KeyError; corrected to the actual tree path above before reaching this verdict.
2. `python3 -` with the following standard-library hash check — exit **0**, decisive output `8 provenance entries match`:
   ```python
   import pathlib, json, hashlib
   p = pathlib.Path('TESTS-RESULTS/2026-11-20+GH-1548')
   rows = [json.loads(x) for x in (p/'provenance.jsonl').read_text().splitlines()]
   for r in rows:
       b = pathlib.Path(r['path']).read_bytes()
       assert b and len(b) == r['bytes'] and hashlib.sha256(b).hexdigest() == r['sha256']
   print(len(rows), 'provenance entries match')
   ```

Graph discovery identified the primary Forge checkout separately from this relay worktree; no structural claim relies on that foreign index. These are direct artifact/object comparisons. No Git command, gate, suite, executable fixture or retained probe script was executed. No later gate is assumed. This is scoped delta approval based on unchanged approved code and delivered evidence; it is not a fresh full-gate result for the merged SHA or promotion qualification.

**NEXT: Complete**

### Attestation · relay-drive — 2026-11-20T11:13:33Z
task: RELAY-FINAL-QA-DELTA-1548
reviewer: codex
status: Approved
reviewed-head: 1dfcc805f9175290bb4d8fdb306fd33d2e6ac214
added-range: 2113+4532
added-sha256: bb4d80c07826290f635004236f34619d56ebc38df9f750107c3d694ebb6812b6
gate-run: undeclared
