# GH-796 integration review of PR #765

Reviewed source: `0e9c4b8859bc034bb6a15bdc635e97b8185b6d06`, integrated with development
`0ae3452a5774c6e72b633dd61648137e80516e6b`. Final #795 integration, relay QA and full gate remain pending.

## Bounded independent source review

The read-only governance reviewer (`/root/governance_review`) found no remaining concrete F1–F6
blocker at this head. It verified selected-wave readiness versus all-wave structure/final closeout,
invalid/missing selector rejection, honest pending #777 checklists, one exact inventory addition,
consumer-root binding, Markdown receipt paths, and first terminal STATUS semantics. It also
verified that the architecture conflict retains both new skill entries and that the ledger decision
retains completed #764 while replaying only distinct #762/#763. This source review is not a full gate
or driver-attested final relay QA. No broad new tests or framework were recommended.

## PDDA distribution review

No file under `utils/pdda/` is deleted. The existing dispatcher forwards the selector; its new
marathon check remains registered. `utils/pdda-local-checks.sh`, its tests, existing checks and
registrations remain intact. The recursive distribution manifest includes the checker; it does
not ship Forge's `relay_attest.py`, so the checker uses the same small first-STATUS contract without
introducing a runtime dependency or expanding the distribution.

The guardrail change in `PROJECT/PDDA.md`, `skills/2-daily/start-marathon/SKILL.md` and
`utils/pdda/check_marathon_qa.py` is the operator-authorized GH-796 F1 remediation: selected-wave
admission instead of requiring unfinished future waves to complete before the first PR. Mandatory
structure remains all-wave, checked receipts remain validated, and final/Completed plans still
require every wave. The changed enforcement boundary is explicit, not an accidental deletion.
Selected-ready/future-pending and final-closeout controls verify the distinction.

Deletion/rename inventory outside the PDDA core:
- The source `skills/2-daily/marathon-triage/` skill and installer move to `start-marathon`; the
  installer retains the old invocation as a compatibility alias. Existing routing/installer tests
  exercise that contract. The old agent metadata is replaced by the new skill's metadata.
- The stale GH-764 inbox capture would duplicate development's completed record. Its exact bytes
  are retained as `GH-764-original-intake.md` here; the PARKED pointer now names the completed doc.
  Development's canonical ledger row/history is preserved; no second active #764 row is replayed.

Receipt checks establish recorded terminal status only. They do not prove authorship or the exact
reviewed SHA; the independent-review and head-verification requirements remain separate.
