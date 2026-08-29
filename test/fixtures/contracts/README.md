# Contract goldens (`@1`)

Recorded canonical shapes for the two GH-280 machine contracts, pinned by
`test/gh291-contract-goldens.sh` (registered in `validate.sh`):

- `invocation-at1-root.json` / `invocation-at1-vendored.json` — real output of
  `swarm_preflight.build_marathon_invocation_artifact` in the root and vendored (`.xyz`)
  layouts.
- `result-at1-approved.json` / `result-at1-refused.json` — real output of the
  `marathon_drive` result writer (`write_terminal_result`) for the two outcome families.

Path-bearing strings are committed **tokenized** (`<FIX>`, `<WORK>`): the comparator in the
suite normalizes both sides with the same mapping, so the goldens stay machine-portable.
Volatile values (run timestamps, the receipt's live `head_sha` probe) are normalized away at
compare time; everything else — key sets, nesting, types, constant values — is pinned.

**Changing these files is a contract event.** A producer change that alters the `@1` shape
shows up as a drift here and must land as a deliberate golden update in the same PR,
following the widen → flip → narrow ladder in `MACHINE-CONTRACTS.md`. Re-record deliberately:

```bash
GH291_RECORD=1 bash test/gh291-contract-goldens.sh
```
