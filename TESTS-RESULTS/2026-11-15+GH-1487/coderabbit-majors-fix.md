# GH-1487 — CodeRabbit Major fixes after merging development (2026-11-19)

Manual check (no new suite, GH-831). Candidate: merge commit `dd9538bbd` on top of PR head `ad5e70297`.
Runs in a disposable full clone of the candidate.

| Finding | Fix | Witness (fixed `dd9538bbd`) | Pre-fix (`ad5e70297`) |
|---|---|---|---|
| Catch-up ignored offline manifests' camelCase fields | `changelog_catchup_candidates` reads `merged_at` or `mergedAt`, `base.ref` or `baseRefName` | `changelog_catchup_candidates(..., offline_manifest={"prs":[{number:4242, mergedAt, baseRefName:"development", mergeCommit}]})` → `candidates: [4242]` | `candidates: []` |
| Plain `--pr N` landing never reached the changelog writer | landing loop stores fetched metadata (`metadata.setdefault`) | `CHANGELOG_WRITES=landing CHANGELOG_CUTOVER=2026-01-01T00:00:00Z python3 utils/py/wave_reconcile.py --root . --pr 4242 --offline probe-manifest.json --dry-run` → `Dry-run: would prepend 1 entry/entries to CHANGELOG.md` | `Changelog: no new entries to write (up to date)` |
| express SKILL.md claimed conditional CHANGELOG writes the driver lacks | reverted the skill text to development's (driver unchanged); driver change filed as #1530 | text and `utils/py/express.py:914-942` agree | — |

Focused suites on the candidate: `bash test/wave-reconcile.sh` 23 passed, 0 failed; `bash test/pdda-changelog.sh`
18 passed, 0 failed; `python3 TESTS-RESULTS/2026-11-15+GH-1487/run_controls.py` controls 1–9 PASS.
