# GH605 implementation evidence — not yet approved

The controlling expanded plan incorporates GLM5.3 and recovered Qwen feedback. Codex plan
review Approved8cfad6bb with exit0. Sol High produced1e918e83 and correction7e24f54a.
See provenance.jsonl for exact heads, commands, outcomes and retained-log hashes.

First full validate:376/377 checks, exit1; test registry assertion372 .sh entries versus374
listed entries. Existing event/sweep/board suites pass. Correction tests:40/41 Python tests;
one Git-less odd-path fixture errors. Expanded sweep rollback/idempotence passes. No final
qualifying push gate or final QA approval, and no live mutations.

## Independently witnessed integration blockers

1. Real policy-preview exits1: simultaneous user(login:) and organization(login:) query causes
   GitHub to reject the nonexistent organization for a valid user-owned board. Direct user-only
   query succeeds. A single repositoryOwner(login:) query with User/Organization fragments
   succeeds and returns all five configured status columns; it is the minimal proposed repair.
2. Captured fetch_board_items query contains one extra closing brace (balance=-1). The mock
   accepts this invalid query. Both query shapes need regressions, including live read-only proof.
3. Cleanly closed WAL-mode schema7 fixture starts without sidecars. load_work_evidence's first
   read creates and leaves -wal/-shm despite mode=ro. Existing-sidecar refusal is insufficient.
   Refuse WAL format before SQLite open; do not use immutable=1 to guess live consistency.
4. Existing shell registry census rejects new .py entry points. Preserve the established runner
   and shell registry contract with thin test entry points invoking the Python fixtures instead
   of widening unrelated telemetry/routing machinery. Correct the Git-less URI fixture too.
5. A real tagged recent start followed by a backfill in_flight snapshot changes activity from
   recent to unknown. A snapshot is informational, not a superseding live transition. Keep its
   latest-event visibility while resolving genuine lifecycle separately.

Other planner probes (invalid identity, malformed closure, draft/non-draft order, missing
ledger completion) drove the correction pass; final tests, not the build claim, establish fixes.

## Live-read/source coverage

GitHub collector read607 issue/PR nodes:375 issues and232 PRs, with7 open PRs. Explicit
closing links:604->603,598->593,597->592,596->595. Draft607 had no closing references.
Current board remains untouched. Rebalance's cached CLIO and ranking snapshots trail live
CLIO/rendered prompts by hours; CLIO and rendered prompts are two views of the same source,
not independent corroboration. Exact605 review and608 express requests are intent only.
No raw private prompts or device config are committed. The current policy target remains
operator-configured, automatic connector disabled, no deletions authorized.

Raw test logs remain in the separate verification clones' temp/gh605-validation directories.
Their hashes above preserve the evidence chain; failed checks have not been relabeled green.
