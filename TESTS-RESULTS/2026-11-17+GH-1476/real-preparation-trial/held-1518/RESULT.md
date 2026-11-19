# Case HELD — #1518 operator decision

Disposition: **held — operator decision**. No research child, no capture, no contract, no ledger row, no label.

Authority: issue body section "Decision needed (operator)": whether a green sequential non-`--fast` `ci-local.sh` receipt for the exact pushed SHA should count as a full-gate receipt in `utils/py/gate_receipt.py` `is_full_gate_receipt`, or whether the double run is intended.

Hold still live (read-only checks, 2026-11-17T19:09Z):
- `gh issue view 1518 --json comments,labels,state` → `{"c":0,"l":[],"s":"OPEN","u":"2026-11-17T18:08:54Z"}` — no operator answer.
- Live `utils/py/gate_receipt.py` at `6000f3de`: `def is_full_gate_receipt` line 67, requires `gate == "validate.sh"` line 71, refusal text line 89 — the behavior in question is unchanged.
- `gh pr list --state all --search "1518 in:body"` → no PR.
- Branch ledger read (`roadmap list --json` at `2e22cce0`): no row for 1518. None created.

Next owner: operator answers the decision on #1518. Only then is it RAW-selectable for medium research. Other items continued while held.
