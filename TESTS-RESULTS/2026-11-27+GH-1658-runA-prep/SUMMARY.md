# Flywheel Run A queue preparation (ledger #1658) — Conveyor receipts

Prepared 2026-11-27 by Conveyor (preparation only: no implementation, no `jog add`, no queue
admission). Preparation clone: fresh full clone of `origin/development`. Proof clone for
preflight: a separate fresh full clone at the same commit.

- **Prepared commit (`origin/development`):** `6142128d9c433d6b12972c6cd9a6f864f0ed9da2`
- **Preflight evaluated ref:** `development` at `6142128d9c43` (every `preflight-*.json` → `freshness.evaluated_ref_commit`).

## Ready items (3)

| Issue | Capture | Gate | round_cap | Preflight `--dry-run` | Probes | PRS |
|---|---|---|---|---|---|---|
| [#1590](https://github.com/HiQS-Labs/XYZ-forge/issues/1590) | `PROJECT/1-INBOX/GH-1590-DAILY-GOALS-BACKTICKED-FOREIGN-LEAD.md` (new) | `bash test/gh280-jog-marathon-adapter.sh` | 9 | exit 0, READY (`preflight-1590.*`) | command unfixed, path_absent unfixed | 55/45/50/90 |
| [#1666](https://github.com/HiQS-Labs/XYZ-forge/issues/1666) | `PROJECT/1-INBOX/GH-1666-ACCEPTANCE-MARKDOWN-LINE-MODEL.md` (new) | `bash test/gh400-acceptance-fidelity.sh` | 9 | exit 0, READY, fidelity `match` (`preflight-1666.*`) | command unfixed, path_absent unfixed | 45/35/50/80 |
| [#1423](https://github.com/HiQS-Labs/XYZ-forge/issues/1423) | `PROJECT/1-INBOX/GH-1423-RELAY-ATTEST-GITIGNORED.md` (existing capture from PR #1424, reused and completed) | `bash test/gh505-relay-attest.sh` | 9 | exit 0, READY, fidelity `match` (`preflight-1423.*`) | command unfixed, path_absent unfixed | 40/35/50/75 (issue's proposal) |

Write sets are disjoint: `skills/1-hourly/kickstart/scripts/build_queue.py`;
`utils/py/swarm_preflight.py` + `test/gh400-acceptance-fidelity.sh`; `utils/py/relay_drive.py`
(each plus its own `TESTS-RESULTS/2026-11-27+GH-N/delivery.md`). None cites `utils/py/jog_run.py`,
`utils/py/gate_receipt.py` or `githooks/`. No open PR touches any of these paths (open-PR file lists
read 2026-11-27).

Preflight command (each item):

```bash
PYTHONDONTWRITEBYTECODE=1 bash utils/swarm-preflight.sh --project-doc PROJECT/1-INBOX/<capture>.md \
  --target-root <proof clone at 6142128d9c43> --dry-run --format json
```

### Probe proof (`matrix.txt`)

The fix probes are inline commands so they evaluate at the prepared commit itself (no file this PR
adds is needed). Readable copies: `probe-gh*.py`; the exact JSON strings: `probe-gh*.cmd.json`
(`consumer-validation.txt` confirms each capture's probe equals its proved copy).

| Arm | #1590 | #1666 | #1423 |
|---|---|---|---|
| base (`6142128d9c43`) | 1 (unfixed) | 1 (unfixed) | 1 (unfixed) |
| simulated fix (`simulated-fix.patch`) | 0 (fixed) | 0 (fixed) | 0 (fixed) |
| fake fix (`fake-fix.patch`) | 1 | 1 | 1 |

Fake fixes: #1590 `return []` (controls catch it); #1666 issue-side-only line model (sides diverge);
#1423 `return True` before committing (the commit-landed check catches it). The patches are proof
inputs only, not the implementation.

### Consumer checks (`consumer-validation.txt`, `admission-checks.txt`)

- `swarm_preflight.extract_contract` + `jog_run.contract_probes_from_doc`: nonempty contract, 2 labels, no reason, for each capture.
- `jog_run.hold_refusal`: `None` for all three; `jog_run.stale_evidence_refusal`: `None` for all three (cited paths unchanged between `prepared_commit` and `development`).

## Held item (1)

| Issue | Capture | Prerequisite | Admission check |
|---|---|---|---|
| [#1480](https://github.com/HiQS-Labs/XYZ-forge/issues/1480) | `PROJECT/1-INBOX/GH-1480-MERGE-CLEANUP-DECOMPOSE.md` (new, held, no build contract) | #1475, OPEN (Phase 2B/3 still in scope on the same `merge_cleanup.py` lines). Recorded in #1480's own body: "Blocked on …/issues/1475 and its implementation PR." | `hold_refusal` → `hold: capture body HELD: marker` (`admission-checks.txt`) |

PRS 70/65/50/40 is the issue's own proposal.

## Existing backlog packets naturally stale under the #1664 gate

None. `git grep '"prepared_commit"' -- PROJECT/` at `6142128d9c43` finds no contract that records
it: the only mentions are prose in `PROJECT/2-WORKING/GH-1476-RAW-TASK-PREPARATION.md` and
`PROJECT/2-WORKING/GH-1664-STALE-EVIDENCE-ADMISSION.md`. The gate skips every legacy packet, so
no existing packet can be naturally stale. Run A's stale witness therefore uses the #1664 suite's
disposable replay (labelled as such), unless one of the three packets above becomes naturally
stale before launch because a cited file changes on `development`.

## PRS read-back (`prs-readback.txt`)

Written with `releases_app.py roadmap pickup … --rated P/S/A/E` (dry run inspected first);
`releases_app.py check`: clean (0 failures).
