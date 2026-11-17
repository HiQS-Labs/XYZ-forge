# Manual instruction walk — GH-1476

Base: `9331cec67`. Candidate source hashes are in provenance.jsonl.

Author-performed paper walk, not a model behavior experiment, runtime test or independent QA. No fake tasks dispatched and no live probes run. Each source anchor was checked nonempty. Red means the old text expressly prescribed the contrary outcome; policy gaps have no old instruction and are not called reproduced runtime failures. Regression controls retain existing behavior.

| Scenario | Control | Revised source | Observed instruction path |
|---|---|---|---|
| RAW without contract | policy gap | `skills/1-hourly/conveyor/SKILL.md:21` | Parent accepts issue, commits selection and budget; read-only medium child precedes capture and pickup. Existing intake remains accepted. |
| Daily goals: twelve links and one ambiguous goal | policy gap | `skills/1-hourly/conveyor/SKILL.md:25` | Links are candidates, not twelve authorizations. Existing five-item default applies to authorized batch; ambiguity held for decomposition. |
| Fresh prepared item | regression | `skills/1-hourly/conveyor/SKILL.md:36` | Reuse the full applicable medium receipt, recheck issue/source/dependencies and parser/preflight; contract alone insufficient. |
| Completed-folder open issue | red | `skills/3-weekly/10days/SKILL.md:220` | Old line excludes immediately. New line routes to Step 3 reconciliation; folder alone cannot exclude. |
| Low-risk legitimate issue | red | `skills/3-weekly/10days/SKILL.md:244` | Old sanity filter excluded low-risk noise. New rule requires affirmative exclusion evidence; low risk remains eligible. |
| Unknown reproduction/access | red | `skills/3-weekly/10days/SKILL.md:281` | Old EXCLUDE list includes unreproducible. New rule holds uncertainty, preserving reason and next owner. |
| Contract artifacts untrustworthy | red | `skills/3-weekly/10days/SKILL.md:387` | Old sniff rule excluded it. New rule HELD/needs_contract removes it from Step 5 and fire list, retains it for repair. |
| Wrong-polarity exit 4 | red | `skills/3-weekly/10days/SKILL.md:437` | Old Step 6 drops and proposes closing every exit4. New flow holds and investigates; delivery requires affirmative evidence. |
| High-risk state/authority boundary | policy gap | `skills/1-hourly/conveyor/SKILL.md:45` | Deeper bounded research, decision or spike; preserve cumulative budget. Expensive effort is low cheapness, not high. |
| Explicit risk deferral | red | `skills/1-hourly/conveyor/SKILL.md:49` | Default no implicit deferral; operator requested batch mode defers visibly, not an approval bypass. |
| Operator rating and malformed override | red | `skills/3-weekly/10days/SKILL.md:232` | Old rule clears override and children force-rate. New rule preserves malformed value and holds; neutral appeal50 otherwise. |
| First rating / existing rated row | regression | `skills/3-weekly/10days/SKILL.md:398` | Existing rated row retained; unrated row first-rated without force with override; frontmatter refreshed only after readback. |
| Shortlist / no existing capture | red | `skills/3-weekly/10days/SKILL.md:389` | Old duplicate pickup directions include no doc-path. New order selection note -> research -> actual capture -> one pickup real path -> Step5. |
| Step3 hold or research hold | red | `skills/3-weekly/10days/SKILL.md:296` | No Step3 write; research hold stays note without invented capture or dangling row. Parent is sole writer. |
| Conveyor absent capture | regression | `skills/1-hourly/conveyor/SKILL.md:58` | Existing Step2->3->4 preserved. Read-only research returns receipt; parent capture precedes pickup. |
| No packet yet / budget exhausted | policy gap | `skills/1-hourly/conveyor/SKILL.md:41` | Numeric deadline and remaining attempts/time recorded before packet exists. Exhausted budget forbids launch, no automatic reset. |
| Raw goal without issue identity | regression | `skills/1-hourly/conveyor/SKILL.md:19` | Clarify identity/scope, no issue invention. Existing idea route only separately requested. |
| Held task versus independent selected task | red | `skills/3-weekly/10days/SKILL.md:415` | Only selected, prepared, not-held set reaches planner fire intersection; independent eligible work continues. Wave gate policy unchanged. |
| Research depth versus --deep | policy gap | `skills/3-weekly/10days/SKILL.md:407` | --deep still refreshes preflight; research policy owns investigation depth, no new runtime option. |

Main path: selected no-doc issue walks Conveyor intake -> medium receipt -> parent capture -> pickup real path -> readback -> parser/preflight -> independent preparation review/publication. Adjacent path: full fresh prior receipt reuses research, revalidates freshness, then follows the same preparation boundary. Neither path admits execution.

The unchanged Step6.5 overlap and Step7 execution prerequisites were read after the altered selection sections; no change to their commands, ownership, acceptance-copying requirement or wave-red-gate policy.

OL-09 remains unchecked until a real bounded run. OL-10 runtime admission remains separate. Final independent review and classified gate pending.
