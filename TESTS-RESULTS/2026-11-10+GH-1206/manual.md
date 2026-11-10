# GH-1206 packaging probes

The npm manifest now describes a repository development manifest and source snapshot. It does not declare an npm CLI or library entry point. Use the repository for the full harness. The allowlist is `src/*.js` and the commercial license; npm also includes package metadata, README and LICENSE automatically.

## Procedure and observed results

1. Before edits, run `npm pack --dry-run --json --ignore-scripts --cache .relay-scratch/npm-cache`, redirecting stdout/stderr under `.relay-scratch/`. Exit 0: predecessor identity, version 1.0.1, 10,447 files, 47,378,176 compressed bytes / 186,258,993 unpacked bytes.
2. Correct package and lock root identity to `xyz-forge`, remove nonexistent `main` and obsolete directory hints, set both Node engines to `>=18` (README: Node 18+), and add the explicit source allowlist. Dependencies and version remain unchanged.
3. Repeat the same dry-run. Exit 0: `xyz-forge@1.0.1`, 17 files, 51,022 compressed bytes / 152,679 unpacked bytes.
4. Parse both nonempty JSON manifests. Assert final paths equal `{package.json, README.md, LICENSE, LICENSE-COMMERCIAL.md}` plus the current `src/*.js` files, with no extra or missing files. Assert matching package/lock names, unchanged versions, matching engines, README baseline, absence of predecessor identity, and absence of `main`/`bin`. All assertions passed. The full final path list and metadata hashes are retained in `provenance.jsonl`.

Red control: the baseline fails the corrected identity and bounded-contents predicates. It includes 7,250 evidence/transcript/ledger entries, including `TESTS-RESULTS/2026-08-20+GH-94/error_log.jsonl`; none can pass the final exact allowlist predicate. This demonstrates the probes distinguish the observed pre-fix artifact from the final one.

Environment: Node v24.21.0, npm 11.19.0. Outputs and npm cache stayed under `.relay-scratch/`. These are archive/metadata probes, not runtime compatibility evidence for Node 18.

No install, publish, version bump, release-tag change, or git command was performed. No CLI installation support was declared. No test suites were changed or run: the embedded relay scope lock defers them to the harness. The acceptance requirement for 14 kernel unit tests remains pending harness verification; the full gate is also pending.
