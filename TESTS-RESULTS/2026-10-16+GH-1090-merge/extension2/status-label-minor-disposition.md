Canonical B1 replay for PR1091 preserves incoming development rows and selected GH1090 fields, but changes the accepted-start task status_label from in-progress to NULL and regenerates its GID/timestamps. Native final review3/3 classified this as Minor, with no Radar behavior impact or required product finding. Original receipt's selected-field comparison omitted status_label, so its business-fields preservation label must not be read as whole-row preservation.

Evidence: old head3f544cc7da13983d03dc175d55972f321a78bce2; canonical merge11b15e44d6bb44cf674dec5ceda21a694136e5a5; reviewed head8e4c17e8488984f37fc8b0470c522d3996730ba8. Canonical roadmap update restores status_label only for accepted_start; replay used section/marker restoration. Product blob169c8c435197a52783425fcc581289673afe6c00 is unchanged.

PRS: priority25, severity20, appeal35, effort cheapness75; no override.

- [ ] Determine canonical accepted-start replay preservation contract and affected readers.
- [ ] Align replay metadata or explicitly document intentional regeneration.
- [ ] Make preservation receipts enumerate compared and excluded fields.

Deferred under Noel's standing noncritical finding direction. Original repair2/2 and approved extensions2/2 remain exhausted. This issue authorizes no implementation, new test/assertion, cap reset, installation, live run or main promotion.
