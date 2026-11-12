# GH1447 bounded replay and instruction verification

## Results

Two requested wording improvements applied to existing start-task preparation review and Flywheel handoff. Manual previous-text absence/current-text uniqueness controls PASS. Consumer main path: green regressions without artifact/outcome correspondence do not establish acceptance. Adjacent path: separate defect-sensitive acceptance may establish outcome even while regressions stay green. Flywheel review of a later amendment requires evidence or unresolved disposition; one completed child cannot establish integration. These are text interpretations, not observed agent effectiveness.

One offline replay ran: two exact original command probes from f98ad1d9, two repaired command forms and historical script files from811d5823, plus empty/trivial/missing controls. Current lint_probe classified all7 as expected: original inline commands refused at -c; repaired file commands accepted; invalid controls refused. No inherited command executed. The script reconstructs only required historical files in a temporary fixture. Inputs and hashes are nonempty and recorded.

## Recommendation and limits

Existing jog_run.lint_probe takes tokens[1] as the script path; swarm_preflight.eval_probes instead runs a shell command and maps return status. A surgical follow-up should reconcile supported command forms or explicitly refuse unsupported forms consistently at preparation, with preserved malformed/trivial/missing rejection. Do not simply exempt all option-looking tokens or claim that lint acceptance establishes semantics. No runtime fix implemented here; separate idea spike owns that decision and heuristic false-positive study. No unlazy runtime imported, no new suite/registry/gate/hook.

Prior-art search found related glossary1407, admission522, preparation1439/1296 and outer-loop1386/1400; none is the requested narrow instruction + retained-input replay or explicit gate-lint exploration. Historical/14-day recurrence trend remains unknown. Lessons: NO_ENTRY; one replay supports a known compatibility observation, not an effectiveness claim.

## Publication

Plan and final Codex relay reviews are driver-attested Approved. Normal publication gate passed on 92b7df05d359749c4f1fe4cc51cf39bdc507e2a0 in 73.429s; clone identity unchanged. Raw log and JSON retained. Final documentation-tail publication follows. No merge/deployment.

## Authorized landing and deployment

PR1449 merged as 4cf70d70d82a7af630b7a7d9c08919e0107f4fc6. Canonical wave reconciliation, ledger check and issue/doc sync passed; primary publication verified clean/equal. Both skills deployed through Skills Army only from clean merged source; full folder and receipt parity, six owned links per skill verified. Pulse remote d5596580d8bbf3c3c159e136ebd6968b5a3b8b7d contains matching payloads. Initial stale/diverged Pulse finding cleared by the existing Pulse writer, not history mutation here. App picker discovery remains unverified; Grok Mac is staging only. No checkouts removed.
