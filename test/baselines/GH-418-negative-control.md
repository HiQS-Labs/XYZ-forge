# GH-418 — planner ledger source negative control

Witnessed 2026-09-08 during builder round 1. These are focused regression results;
full-suite and final-commit verification belong to the outer relay harness.

The starting implementation already had a partial DB reader. Its literal substring
mode check missed `ROADMAP_SOURCE = releases # canonical`, although the repository's
existing `router_audit.parse_pdda_mode` recognizes it. It also silently fell back to
markdown for an empty or failed DB read. The original issue's claim that no DB path
existed is stale for this checkout.

## Reproduction

The regression creates an isolated fixture, initializes it through the Releases
application, and parks #418 with the real `cmd_roadmap_add` verb. Its rated project
doc has a ready preflight contract. The DB contains #418; `ROADMAP.md` contains only
#999. No git or network command runs; unexpected subprocesses fail immediately.
All in-turn fixtures, saved source copies, and logs were under `.relay-scratch/`.

Run the focused test with `GH418_SCRATCH` pointing at the scratch directory:

```bash
bash test/gh418-planner-ledger-source.sh
```

For the pre-fix replay, the same test also received `GH418_ENGINE_PATH` and
`GH418_CLI_PATH` pointing to byte-for-byte copies of the two starting Python files.
The shared zones configuration was pinned explicitly, so moving those copies did
not change config discovery. An initial probe omitted that pin and failed at zones
loading; that setup failure is not the red control.

| Observation | Saved pre-fix source | Fixed source |
|---|---|---|
| Test exit | 1 | 0 |
| Planner exit for DB-only case | 5 | 0 |
| Nonempty rendered plan | 3236 characters | 3244 characters |
| DB-only #418 in wave 1 | absent | present |
| Stale-only #999 in rendered plan | present, held `needs-doc` | absent |
| Report | `items=1 active=0 waves=0` | `items=1 active=1 waves=1` |
| Source field | `../../ROADMAP.md` | `releases.db (roadmap_items)` |

The pre-fix failure was:

```text
AssertionError: DB-only #418 absent from active plan
```

The fixed plan contains:

```text
| [#418] GH-418 · DB-only item | 2 | 2 | 2 | independent | — | 10 | 1 |
**Wave 1:** #418
```

## Stale-read canary and further cases

The test guards the shipped Python planner's file-open boundary in releases-mode.
Injecting a `ROADMAP.md` read into the DB loader raises exactly
`releases-mode read of frozen ROADMAP.md`; removing that injection restores green.
This is a runtime planner canary, not a claim that all unrelated shipped tools or
the frozen `XYZ_PYTHON=0` implementation have been audited.

The focused run also passed: compact/spaced mode settings; absent markdown; empty
DB without stale fallback; missing, corrupt, and unmigrated DB errors (exit 3);
legacy markdown selection even with a shadow DB and commented releases setting;
explicit fixture override and its source label; missing override errors; and
byte-identical DB/dump before and after planning.

## Source receipts

SHA-256 values identify the exact files used by the witnessed runs:

| File | Pre-fix | Fixed |
|---|---|---|
| `_marathon_plan.py` | `aff1dcf1ad557601dc97a770e9f4ecda059a44b20f1c92beeb51fac317968175` | `38b3a3009eeecab4fc33f54cc224a264e1f80afe97953f0caed7e18ddb2be26d` |
| `marathon_plan.py` | `998ee9314e754a4aec9ed8473613474c3762d7fda7430bc3354d94b87d8eb705` | `46c754b9a6477aadd717d14f73ca0d2e447f999c7730a8d0f72a083d928022a6` |

Test SHA-256: `45a9de943fd000e502f2596efb0b3586fb87195c36b6103c7c4510c00634651b`.
The turn allowlist permits this baseline, not an additional committed
`provenance.jsonl`; these inline receipts are focused observations, not a qualifying
gate receipt or merge-readiness claim.
