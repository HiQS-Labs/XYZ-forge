# GH-1100 verification

Runtime revision: d6c7e9b0. Probe source is `probe-command.txt`: copy into ignored `temp/root-probe.py` at the task root and run the commands in `provenance.jsonl`. Base and target-only controls each fail for the intended reason; the complete candidate passes. The probe intercepts subprocess/state writes, so it proves dispatch arguments/environment without launching builders or touching primary state. The supplemental adapter checks cover root, .xyz, existing target and packets without optional harness_home, with immutable inputs.

The real Marathon parser/render dry-run places phase output inside the disposable gate clone (`driver-dry-run.txt`). It proves root consumption without live builder work; it is not a live-shift acceptance claim.

The existing real-chain adapter suite passed **223 checks, 0 failures**. Full output: `gh280.log.gz`. It covers root and vendored installs, builds and gate retries with deterministic agents. Before/after repository identities match. No test suites or registry entries were added or changed.

Initial full PDDA run failed solely on the new recon document's missing frontmatter, status table and coverage exemption. Those were fixed; each failed subcheck reran green. PRS check was clean; frozen-twin staged guard passed. Full publication gate is required and remains pending final review/publication.

Independent plan review Approved: `relay-system/2026-10-16/gh1100-plan.codex.md`, structured attestation here. Final review and publication receipts follow.
