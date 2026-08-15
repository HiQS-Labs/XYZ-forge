---
schema: finish-line/parked/v2
created_local: 2026-08-14T22:25
repo: xyz-3-agents-swarm
---

# Parked — 2026-08-14 22:25 — xyz-3-agents-swarm

## Runs

### R-001 — 2026-08-14T22:25
- frozen_items: 4
- parked_items: 3

#### P-001 — Standalone clones under /tmp fail a suite
- claimed_severity: operational trap
- exclusion_rule: X2
- evidence: test/gh388-run-log-durability.sh:55
- summary: A clone made under /tmp or /var/folders fails gh388 identically on unmodified development, because those roots are registered non-durable; the failure reads as a code defect.
- remediation: Clone to a durable path, or note the exemption in the standalone-clone rail.
- issue: none
- revisit_when: a second session loses time to this false failure

#### P-002 — Turn-prompt claim contract may be re-litigated
- claimed_severity: unresolved disagreement
- exclusion_rule: X4
- evidence: utils/py/marathon_drive.py:1985
- summary: PR 529 removed the tick claim instruction globally to work around one model's tool loop; reverted on merge, and the original author has not responded to the reasoning.
- remediation: If SmallCode needs a claim-free prompt, scope it per-shim rather than globally.
- issue: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/522
- revisit_when: the author disputes the revert or a second lane needs the same relaxation

#### P-003 — agy advisor unusable until re-login
- claimed_severity: degraded tooling
- exclusion_rule: X2
- evidence: relay-automation/consult.sh:1
- summary: Every agy consult this session failed its auth pre-flight, so cross-model checks ran single-model and unreconciled, which is weaker evidence than the skill's contract assumes.
- remediation: Run agy login in a normal terminal.
- issue: none
- revisit_when: the next consult needs two independent opinions
