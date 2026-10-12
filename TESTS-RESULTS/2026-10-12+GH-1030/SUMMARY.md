# GH-1030 post-merge review — 2026-10-12

Development baseline: `d09b8f9dedd436be3e5f883f68deff985719fe1b`.

The full macOS `bash validate.sh` gate passed **409/409**, exit 0, in 1,432 seconds. HEAD, origin, core.bare and local user identity remained unchanged. Two pool failures (`relay-turn-timeout.sh`, `jog-queue.sh`) passed the registered isolated retries. These observations are retained separately; the retry does not prove a harmless flake or identify a contended resource. The timeout's whole-shim `<5s` assertion observed 5s despite the expected timeout exit 7; the same symptom predates this batch (#224, #854). No new product regression is established.

Required focused checks passed: gh113 (27/27), gh396 (42/42), gh777, gh609 including existing negative controls, gh306, and the canonical Marathon launcher, driver (162/162), planner (70 passed, 2 skipped), YAML, monitor, and closeout (23/23) suites. The initial direct gh396 run failed one locator assertion because the caller inherited an explicit XYZ_HARNESS pointing at the primary checkout. Removing only that variable returned the same suite to green. The registered full gate already clears it through gate-env.sh; no source was changed. Both invocations are retained.

Manual probes passed for nested/hyphen scratch containment, vendored-root order, observer symlink identity/foreign receipts, all 17 slug/init/onboarding cases, and Paperclip handler boundaries. Pre-fix scratch/root-order, observer and slug controls failed as expected. The real Marathon dry-run rendered one phase without changing files or HEAD; an already-capped live fire refused at exit 8 without a relay commit or attempt append. No provider was dispatched by either Marathon probe. Paperclip checks invoked handlers directly without opening a socket.

The actual Codex relay-drive review turn passed with an attested source-only approval. Its seeded-artifact scope is explicit; it is not a merge-candidate approval. A separate actual-tree review on refreshed PR #1019 is Approved and passes candidate_ok. The runtime candidate hash remains c9c246250f735e29144c9a0712ccee57d068c2540c84e5771a6107e7d173e334. The parent read current source and merged first-parent diffs; stale graph metadata and the peer's historical-fetch limitation are disclosed in the receipts.

PR #1019 preparation used a normal merge refresh, preserving both original PR head 74b871f4 and development d09b8f9d. The canonical resolver proved disjoint ledger changes, replayed one GH1010 item through supported writers, preserved additive changelog sections, and passed releases check. Human merge approval remains required.

PR #1024 remains blocked: draft; #1027 open without approval or owner deferral; current diff adds 58,491 raw .log/.txt lines under TESTS-RESULTS and no .gitignore change. Keep compact provenance/validation/error summaries and hashes; strip raw gate dumps before merge. No history rewrite, inline regression repair, GitHub PR merge, hook bypass, or action on #930/#954 occurred.

Only small JSONL receipts and review prose are committed. Raw logs are local under ignored temp directories. Later merges require a fresh gate/focused replay and hosted evidence on each new tip; this baseline does not qualify them.
