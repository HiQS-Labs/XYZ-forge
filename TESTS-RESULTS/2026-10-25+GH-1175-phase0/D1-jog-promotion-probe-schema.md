TITLE: jog run: fire-time 1-INBOX promotion lints YAML frontmatter fix_probes, not the Preflight Contract probes; every unattended 1-INBOX run parks

## Observed (GH-1175 Phase 0, 2026-10-26)
`releases jog run --target-root … --builder agy --reviewer codex --max-tasks 1` on #416 (capture in `PROJECT/1-INBOX/`, JSON Preflight Contract that `swarm-preflight --dry-run` reported **ready, exit 0**) parked in under 1 s:
`jog: contract promotion failed: unreviewed-probe-contract (no valid probes in unattended mode)`.

## Cause
`utils/py/jog_run.py` `extract_probes_from_doc` (≈L1336) reads only a frontmatter `fix_probes:` YAML list and treats each entry as a shell command (`lint_probe`). The Preflight Contract's JSON `fix_probes` (grep_present / grep_absent / path_absent / command) — the probes preflight actually evaluates — are ignored. With no tty (`interactive=sys.stdin.isatty()`), zero frontmatter probes → park. Two probe schemas for one gate.

Any scheduled/reconciler-driven run (#1175 Phase 1+) therefore parks every 1-INBOX issue. GH-1087 passed only because its doc was already in 2-WORKING.

## Proposed remedy (for review)
Have the promotion lint reuse the contract's JSON `fix_probes` (the same parser preflight uses) and accept them when preflight's probe evaluation returns `unfixed` for each; keep frontmatter probes as an additional, not exclusive, source. One probe schema.

## Acceptance
- An unattended `jog run` on a 1-INBOX doc whose JSON contract passes `swarm-preflight --dry-run` promotes and reaches preflight.
- A doc with no probes in either place still parks `unreviewed-probe-contract`.
- Manual red/green receipts under TESTS-RESULTS/ (no new suites, GH-831).

Related: #1175, #522, GH-1098 A2.
