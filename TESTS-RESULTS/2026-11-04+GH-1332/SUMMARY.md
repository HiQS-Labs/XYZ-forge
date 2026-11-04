# GH-1332 item 1: a doc Jog promotes on an execution branch passes roadmap coverage

**Cause.** `jog_run.promote_contract_to_working` moves a `1-INBOX` doc to `2-WORKING` on the execution branch and, by design, writes no ledger there (one writer; `_execution_root` refuses lane ledger changes; `wave_reconcile` repoints after landing). `pdda-check-roadmap-coverage` required the exact `2-WORKING` path in the ledger, so every gate run on such a branch failed: Marathon's `pdda.sh` pre-advance gate, and `pdda-repo-contract` / `gh269-roadmap-retired` in the full suite. In the #1298 batch this hit all five promoted items, and the workaround (repointing on the lane branch) broke `jog resume` / `jog land` by adding lane ledger changes.

**Change.** `utils/pdda/pdda.sh`, working-doc coverage loop only: a `PROJECT/2-WORKING/<name>` doc with no pointer is covered (INFO, not ERROR) when the ledger points at `PROJECT/1-INBOX/<name>` **and** that `1-INBOX` file no longer exists (a move, not a copy).

**Landing side (read, not changed).** When the issue is reconciled closed, `wave_reconcile.update_roadmap_entry` selects the row by `gh_number` and repoints it to the doc's destination (`wave_reconcile.py` ~1575-1588). A merge that leaves the issue **open** (a partial landing) only records merge evidence (~2392-2397), so the row keeps naming `1-INBOX` until the issue closes; this fallback keeps covering it meanwhile. That is the intended behaviour, not a guarantee of repointing on every merge (Codex final QA round 1, Should).

**Limit.** The fallback reuses the existing fixed-string match over `doc_path` and `raw_text`, so it shows a move happened, not that Jog made it: a hand `git mv` of a parked doc also passes until reconciled, and a substring such as `X.md.bak` would match `X.md` (Codex round 1, Nit; accepted for a single-operator coverage gate).

**Manual check (no new test, GH-831)**; command per case: `bash utils/pdda/pdda.sh run`, filtered to `pdda-check-roadmap-coverage` lines for the three docs, first on the unpatched clone, then after `git apply` of this change, in a disposable clone of `origin/development` `7af4ee3d`, output in `coverage-check-output.txt`:

| Case | Red (unpatched) | Green (patched) |
|---|---|---|
| A: `git mv` GH-1295 `1-INBOX` -> `2-WORKING`, ledger untouched (Jog's in-flight state) | ERROR | INFO "promoted in flight" |
| B: copy GH-1296 to `2-WORKING` (`1-INBOX` still present) | ERROR | ERROR |
| C: new `2-WORKING` doc with no ledger row at all | ERROR | ERROR |

**Whole-command status, case A alone** (B and C removed; the doc's `updated:` key added as Jog's promotion does): patched `pdda.sh run` exits **0**, unpatched exits **1**. With all three cases present both exit 1, as intended, since B and C must keep failing.

**Not changed:** the `1-INBOX` coverage loop; item 2 of #1332 (`jog retry-gate` refusing a relay-receipt-only tail) stays open.
