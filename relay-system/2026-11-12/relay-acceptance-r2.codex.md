# Relay acceptance wording final QA round 2
STATUS: Approved
NEXT: orchestrator

Review skills/1-hourly/relay-xyz/SKILL.md lines734–736 and TESTS-RESULTS/2026-11-12+relay-acceptance/SUMMARY.md. Three added content lines in the existing QA-template section; user approved exact wording and scoped manual documentation exception, normal hooks required. Round1 approved content but driver rejected placement before an existing placeholder; retained receipt is not attested. Wording unchanged. No separate plan QA for this simple change.

Questions: Does the wording distinguish intended versus observed rejection and admission versus final acceptance without requiring every regression fail? Is it proportionate with no new stage/authority? Are summary/hash/evidence limitations honest? No speculative new machinery/tests. Read only; no suites/pytest/validate. Only edit this relay file. APPEND your verdict AT THE VERY END OF THIS FILE, preserving ALL existing body text and blank lines; only STATUS/NEXT may change. There is no placeholder to replace. Findings need concrete input, scope, falsifier.

<!-- ▽ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK ▽ -->
▶ TAKE YOUR TURN (codex)
<!-- △ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK △ -->

## Codex reviewer verdict — Approved

[Pass] skills/1-hourly/relay-xyz/SKILL.md:734–736 distinguishes intended rejection at plan review from observed evidence (or explicit unverified status) at final review. Admission and final acceptance are expressly distinct. “Green regression coverage alone” permits a separate defect-sensitive acceptance check; it does not require every regression to fail. These lines extend the existing QA template without adding a stage, authority, suite or executable gate. Easy reversal: remove the three lines.

[Pass] TESTS-RESULTS/2026-11-12+relay-acceptance/SUMMARY.md limits its read-through to instruction interpretation, disclaims future model compliance, and does not pre-claim independent QA or publication success. provenance.jsonl records round 1 as exit 4 / not attested. Command `cat TESTS-RESULTS/2026-11-12+relay-acceptance/review-round1.log` (exit 0) confirms “terminal STATUS Approved by reviewer codex REFUSED — review-body-rewritten”. Retained content approval is not presented as accepted harness evidence.

Read-only probe: after exporting PYTHONDONTWRITEBYTECODE=1 and TMPDIR="$PWD/.relay-scratch/tmp", command `python3 -` with this stdin exited 0:
```python
import hashlib,json
from pathlib import Path
p=Path('skills/1-hourly/relay-xyz/SKILL.md')
s=p.read_text()
q='For bug-fix or delivery-readiness reviews, ask: “What prevents each unchanged, unfixed task from being reported as delivered—and where is the observed rejection?”'
h=hashlib.sha256(p.read_bytes()).hexdigest()
r=json.loads(Path('TESTS-RESULTS/2026-11-12+relay-acceptance/provenance.jsonl').read_text().splitlines()[0])
assert s.count(q)==1
assert s.index('## QA / Consult Template Formatting') < s.index(q) < s.index('**Example format:**',s.index('## QA / Consult Template Formatting'))
assert h==r['sha256']
print('question_count=1; location=existing QA template before example; sha256='+h+'; receipt_hash_match=true')
```
Decisive output: `question_count=1; location=existing QA template before example; sha256=d51ef7f5d2093e00ee3542f7009d35a310f5dd22742c2524e86ca55c203f0ec7; receipt_hash_match=true`.

Scope: documentation wording and retained evidence only. Falsifier: wording equating admission with delivery, demanding all regressions fail, or evidence claiming accepted round-1 QA would overturn this verdict; none occurs in the reviewed inputs. No blocking findings. Runtime compliance, normal publication hooks and post-turn harness acceptance remain unverified here; no suites, pytest, validate or executable fixtures were run.

### Attestation · relay-drive — 2026-11-12T20:47:30Z
task: RELAY-ACCEPTANCE-R2-20261112
reviewer: codex
status: Approved
reviewed-head: 8f599d40259f1b85ce45ecb5cf974b1c8e11fc83
added-range: 1227+2578
added-sha256: be9972b774679ce1624f2c161fc05b766ec00d4cd8166ed6eaff231048424aa7
gate-run: undeclared
