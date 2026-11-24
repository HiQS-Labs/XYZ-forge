# Conveyor preparation receipts — GH-1590 and GH-1583 (Kickstart run 3, #1592)

- Base: origin/development 305ebc303d7cee1553570200963b5aac39fd4195.
- Research: one read-only Explore agent (1 attempt, 30 min cap) returned file:line receipts for both issues; its conclusions are the "Recon map" and "Plan" sections of each capture doc. It wrote nothing.
- Validation (disposable verify clone, identity bracket unchanged): `extract_contract` and `contract_probes_from_doc` return nonempty probes with no reason for both docs; `swarm-preflight --dry-run` exits 0 (READY) on the doc commit, every unfixed probe reads `unfixed`. A first run exited 5 because directory artifacts did not exist at the ref; they were replaced by `artifacts_new` files with `path_absent` probes.
- Advisory gaps left as is (GH-557): neither issue body has an `## Acceptance` section; the capture docs carry the criteria and the issue bodies are not rewritten.
- Frozen twins `utils/marathon-plan.sh` and `utils/swarm-preflight.sh` stay out of scope of #1583 (GH-308, no fallback safety defect).
