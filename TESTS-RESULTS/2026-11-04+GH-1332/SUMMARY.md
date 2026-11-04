# GH-1332 item 1: a doc Jog promotes on an execution branch passes roadmap coverage

**Cause.** `jog_run.promote_contract_to_working` moves a `1-INBOX` doc to `2-WORKING` on the execution branch and, by design, writes no ledger there (one writer; `_execution_root` refuses lane ledger changes; `wave_reconcile` repoints after landing). `pdda-check-roadmap-coverage` required the exact `2-WORKING` path in the ledger, so every gate run on such a branch failed: Marathon's `pdda.sh` pre-advance gate, and `pdda-repo-contract` / `gh269-roadmap-retired` in the full suite. In the #1298 batch this hit all five promoted items, and the workaround (repointing on the lane branch) broke `jog resume` / `jog land` by adding lane ledger changes.

**Change.** `utils/pdda/pdda.sh`, working-doc coverage loop only: a `PROJECT/2-WORKING/<name>` doc with no pointer is covered (INFO, not ERROR) when the ledger points at `PROJECT/1-INBOX/<name>` **and** that `1-INBOX` file no longer exists (a move, not a copy).

**Landing side (read, not changed).** `wave_reconcile.update_roadmap_entry` selects the row by `gh_number` and repoints it to the doc's destination when `doc_path` differs, so a row still naming `1-INBOX` is corrected when the PR lands.

**Manual check (no new test, GH-831)** in a disposable clone of `origin/development` `7af4ee3d`, output in `coverage-check-output.txt`:

| Case | Red (unpatched) | Green (patched) |
|---|---|---|
| A: `git mv` GH-1295 `1-INBOX` -> `2-WORKING`, ledger untouched (Jog's in-flight state) | ERROR | INFO "promoted in flight" |
| B: copy GH-1296 to `2-WORKING` (`1-INBOX` still present) | ERROR | ERROR |
| C: new `2-WORKING` doc with no ledger row at all | ERROR | ERROR |

**Not changed:** the `1-INBOX` coverage loop; item 2 of #1332 (`jog retry-gate` refusing a relay-receipt-only tail) stays open.
