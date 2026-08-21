# Daybreak · Wave 4 — End-to-end Wiring, All-Degraded Fixture & Subsystem Registration

Release **0.7.2 "Daybreak"** · marathon `mar-01M0EC2ZXJCCJ88KASQPDBTBJ9` · tracking
[#77](https://github.com/HiQS-Suite/XYZ-forge/issues/77) ([#87](https://github.com/HiQS-Suite/XYZ-forge/issues/87)).

Complete the final integration of the `/standup` toolchain:
1. End-to-end `skills/standup/collect.sh` execution combining all 8 lenses (1 through 8).
2. Hermetic `skills/standup/fixtures/all-degraded/` fixture triggering all degradation paths simultaneously.
3. Verify `skills/standup/install.sh --check` contract.
4. Register `standup` subsystem or mapping in `utils/ci-route.sh`.
5. Comprehensive test coverage in `test/gh77-standup-triage.sh` proving all 8 lenses run together cleanly and all exit criteria for Release 0.7.2 Daybreak are satisfied.

## Work units

| Issue | Unit | Deliverables |
|---|---|---|
| [#87](https://github.com/HiQS-Suite/XYZ-forge/issues/87) | 4 · Wiring & Integration | `collect.sh` end-to-end with all 8 lenses, `fixtures/all-degraded/`, `install.sh --check`, `ci-route.sh` registration, and full `test/gh77-standup-triage.sh` suite |

## Contract

`collect.sh --fixture <dir>` emits one unified JSON document containing lenses 1–8:

```json
{
  "repo": {"branch": "<name>"},
  "lenses": {
    "1": {"status": "ok|degraded", "degraded_id": "D<n>|null", "candidates": [ ... ]},
    "2": {"status": "ok|degraded", "degraded_id": "D<n>|null", "candidates": [ ... ]},
    "3": {"status": "ok|degraded", "degraded_id": "D<n>|null", "candidates": [ ... ]},
    "4": {"status": "ok|degraded", "degraded_id": "D<n>|null", "candidates": [ ... ]},
    "5": {"status": "ok|degraded", "degraded_id": "D<n>|null", "candidates": [ ... ]},
    "6": {"status": "ok|degraded", "degraded_id": "D<n>|null", "candidates": [ ... ]},
    "7": {"status": "ok|degraded", "degraded_id": "D<n>|null", "candidates": [ ... ]},
    "8": {"status": "ok|degraded", "degraded_id": "D<n>|null", "candidates": [ ... ]}
  }
}
```

## Pass condition — machine-checkable, per unit

```bash
skills/standup/collect.sh --fixture skills/standup/fixtures/all-degraded
python3 skills/standup/triage.py --lenses <that output> --dry-run
bash test/gh77-standup-triage.sh
bash validate.sh --subsystem releases
```

## Definition of done for this phase

1. All 8 lenses run together in `skills/standup/collect.sh`.
2. `skills/standup/fixtures/all-degraded/` cleanly triggers all degradation modes and `triage.py` handles the collapsed output within the 15-line display cap exiting 3.
3. `skills/standup/install.sh --check` exits 0 when installed (or 1 when not) without errors.
4. `ci-route.sh` maps `skills/standup/*` changes to `test/gh77-standup-triage.sh`.
5. `test/gh77-standup-triage.sh` passes 100% clean.
6. `bash validate.sh --subsystem releases` is green.

## Working rules for the BUILDER

- **`skills/standup/fixtures/` is a DIRECTORY lane** — files inside are yours to create/update.
- **Do not leave scratch files in the tree.** Keep temp probes under `$TMPDIR`.
- **`triage.py` is NOT modified** — report any finding in the relay file rather than editing `triage.py`.
