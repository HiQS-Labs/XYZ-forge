# GH-1100 verification

Runtime revision: d6c7e9b0. Probe source is `probe-command.txt`: copy into ignored `temp/root-probe.py` at the task root and run the commands in `provenance.jsonl`. Base and target-only controls each fail for the intended reason; the complete candidate passes. The probe intercepts subprocess/state writes, so it proves dispatch arguments/environment without launching builders or touching primary state. The supplemental adapter checks cover root, .xyz, existing target and packets without optional harness_home, with immutable inputs.

The real Marathon parser/render dry-run places phase output inside the disposable gate clone (`driver-dry-run.txt`). It proves root consumption without live builder work; it is not a live-shift acceptance claim.

The existing real-chain adapter suite passed **223 checks, 0 failures**. Full output: `gh280.log.gz`. It covers root and vendored installs, builds and gate retries with deterministic agents. Before/after repository identities match. No test suites or registry entries were added or changed.

Initial full PDDA run failed solely on the new recon document's missing frontmatter, status table and coverage exemption. Those were fixed; each failed subcheck reran green. PRS check was clean; frozen-twin staged guard passed. Full publication gate passed 409/409 at 8a5041fd (see below).

Independent plan review Approved: `relay-system/2026-10-16/gh1100-plan.codex.md`, structured attestation here. Final review and publication receipts follow.

Final Codex review Approved at reviewed head b92d66c8 (`final-attestation.json`). Integration base advanced to 746b1148; existing ledger_merge disjoint replay kept upstream queue/roadmap state, replayed only GH-1100 via writer and resolver, and reminted the row as rmi-01M53Y2G9AG6656690Q53F8ZPW. Its status_label was NULL after replay, so it was explicitly re-admitted with accepted-start. Original pre-implementation admission remains in commit d6c7e9b0 history; no runtime code changed during integration. Routine generated leaderboard view is excluded from the task diff.

## Publication gate

Normal pre-push full gate at **8a5041fd**: **409/409 passed**, 869 seconds, no bypass. Raw output: `publication-gate.log.gz`; before/after identities match. `gh648-l4-285-revalidate.sh` initially raised process-group PermissionError under pooled load and passed the gate's built-in serial retry. Initial output retained in `gh648-pooled-failure.txt`; same signature was previously reported in [GH-1063](https://github.com/HiQS-Labs/XYZ-forge/issues/1063). The OS-level cause is unproven; this is a qualified green, not a claim that the initial failure was harmless. No suite was disabled or altered. Final evidence-only additions follow this tested commit; runtime bytes are unchanged. This local validation is not promotion evidence or a live GH-1098 shift run.
