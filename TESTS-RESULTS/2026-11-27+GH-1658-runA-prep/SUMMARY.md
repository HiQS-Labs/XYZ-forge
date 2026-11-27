# Flywheel Run A queue preparation (ledger #1658): Conveyor receipts

**Preparation evidence, pending publication.** Prepared 2026-11-27 by Conveyor (preparation only:
no implementation, no `jog add`, no queue admission, no readiness label). Readiness still needs this
PR's review, merge to `development`, and the exact-ref preflight recheck at the integration ref
(Conveyor step 6). Every command, head and exit below is in `provenance.jsonl`, with the arm's construction (`build`), working directory (`$P` prep clone, `$PROOF`, `$SCRATCH`) and full command, so each arm can be replayed from the retained patches.

- **Prepared commit (`origin/development`):** `6142128d9c433d6b12972c6cd9a6f864f0ed9da2`
- **Preparation clone:** fresh full clone of `origin/development`. **Proof clone** for the READY check: a separate fresh full clone at the same commit. **Scratch clone** for the probe matrix and consumer arms: a third disposable clone, reset to the prepared commit between arms.

## Ready items (3)

| Issue | Capture | Gate | round_cap | Preflight `--dry-run` (base) | PRS |
|---|---|---|---|---|---|
| [#1666](https://github.com/HiQS-Labs/XYZ-forge/issues/1666) | `PROJECT/1-INBOX/GH-1666-ACCEPTANCE-MARKDOWN-LINE-MODEL.md` (new) | `bash test/gh400-acceptance-fidelity.sh` | 9 | exit 0, READY, fidelity `match`, probes unfixed/unfixed | 45/35/50/80 |
| [#1423](https://github.com/HiQS-Labs/XYZ-forge/issues/1423) | `PROJECT/1-INBOX/GH-1423-RELAY-ATTEST-GITIGNORED.md` (existing capture from PR #1424, reused and completed) | `bash test/gh505-relay-attest.sh` | 9 | exit 0, READY, fidelity `match`, probes unfixed/unfixed | 40/35/50/75 (issue's proposal) |
| [#1638](https://github.com/HiQS-Labs/XYZ-forge/issues/1638) | `PROJECT/1-INBOX/GH-1638-RELAY-SEED-DIR-NESTING.md` (new) | `bash test/worktree-isolation.sh` | 9 | exit 0, READY, fidelity advisory (no issue Acceptance heading; three `[added]`), probes unfixed/unfixed | 55/50/50/80 |

Preflight command (each item; `preflight-<N>.json/.err/.rc`):

```bash
PYTHONDONTWRITEBYTECODE=1 bash utils/swarm-preflight.sh --project-doc PROJECT/1-INBOX/<capture>.md \
  --target-root <proof clone at 6142128d9c43> --dry-run --format json
```

### Scope: declared vs effective (`consumer-validation.txt`)

Declared write sets are disjoint: `utils/py/swarm_preflight.py` + `test/gh400-acceptance-fidelity.sh`;
`utils/py/relay_drive.py`; `relay-automation/relay-turn-lib.sh` +
`skills/1-hourly/relay-automation/relay-pkg.tar.gz`; each plus its own
`TESTS-RESULTS/2026-11-27+GH-N/delivery.md`. None cites `utils/py/jog_run.py`,
`utils/py/gate_receipt.py` or `githooks/`, and no open PR touches any declared path.

Preflight also infers covering tests/helpers into each **effective** lane
(`lane_plan.effective_artifacts`). Those inferred paths overlap: `test/_setup.sh` (all three),
`test/gh505-relay-attest.sh`, `test/gh371-interrupt-snapshot.sh`, `test/gh372-escalation-log-tail.sh`
(#1423 and #1638), `test/gh642-consumer-fruit.sh` (#1666 and #1638). **They are reserved: none of
these three tasks may edit an inferred path.** The only suite edit any packet intends is #1666's
case in `test/gh400-acceptance-fidelity.sh`, which is in no other packet's effective lane.

### Probe proof (`matrix.txt`, `preflight-arms.txt`)

The fix probes are inline commands so they evaluate at the prepared commit itself. Readable copies:
`probe-gh1666.py`, `probe-gh1423.py`, `probe-gh1638.sh`; the exact JSON strings:
`probe-gh*.cmd.json` (`consumer-validation.txt` confirms each capture's probe equals its proved copy).

Standalone probe exits (0 = fixed; `matrix.txt`):

| Arm | #1666 | #1423 | #1638 |
|---|---|---|---|
| base (`6142128d9c43`) | 1 | 1 | 1 |
| simulated fix (`sim-gh<N>.patch`) | 0 | 0 | 1: source only, package not regenerated |
| simulated fix + `make-pkg.sh` (`sim-gh1638-with-pkg.patch`) | — | — | 0 |
| fake fix (`fake-gh<N>.patch`) | 1 (issue side only) | 1 (`return True` before committing) | 1 (skip directory entries) |
| second fake | 1 (`fake2-…-two-reader`: deviations reader left on `splitlines()`) | — | 1 (`fake2-…-overlay`: contents-only `cp -R src/.`, keeps a host-deleted child) |
| third fake | 1 (`fake3-…-mask-three`: masks only U+0085/U+2028/U+2029) | — | — |
| #1423 with hostile inherited `GIT_DIR=/nonexistent` | — | base 1, simulated 0 | — |

#1666's probe covers every non-CR/LF separator Python `splitlines()` breaks on (U+000B, U+000C,
U+001C-U+001E, U+0085, U+2028, U+2029). #1638's probe also requires a host-deleted child to be
absent, an ordinary file entry to seed, a failed directory copy to fail the begin, and the
packaged `relay-pkg.tar.gz` member to equal the live library. `pkg-freshness-arms.txt`: on the
source-only arm `bash test/relay-pkg-freshness.sh` exits 1 (drift: `relay-turn-lib.sh`); after
`make-pkg.sh` it exits 0.

Consumer arms (real Preflight, `--dry-run`, simulated fix committed on the scratch clone's
`development`):

| Arm | #1666 | #1423 | #1638 |
|---|---|---|---|
| fixed + delivery receipt | exit 4, landed/landed | exit 4, landed/landed | exit 4, landed/landed |
| fixed, receipt absent | exit 7, landed/unfixed | exit 7, landed/unfixed | exit 7, landed/unfixed |

So a behavior fix without its delivery receipt reads AMBIGUOUS (7), and only the complete delivery
reads STALE/landed (4). The patches are proof inputs only, not the implementation.

### Admission checks (`admission-checks.txt`)

`jog_run.hold_refusal` and `jog_run.stale_evidence_refusal`: `None` for all three ready items
(cited paths unchanged between `prepared_commit` and `development`).

## Held item (1)

| Issue | Capture | Prerequisite | Admission check |
|---|---|---|---|
| [#1480](https://github.com/HiQS-Labs/XYZ-forge/issues/1480) | `PROJECT/1-INBOX/GH-1480-MERGE-CLEANUP-DECOMPOSE.md` (new, held, no build contract) | #1475, OPEN (Phase 2B/3 still in scope on the same `merge_cleanup.py` lines). Recorded in #1480's own body: "Blocked on …/issues/1475 and its implementation PR." | `hold_refusal` → `hold: capture body HELD: marker` |

PRS 70/65/50/40 is the issue's own proposal.

## Dropped from the ready set: #1590

#1590 was prepared in round 0 of this batch and then withdrawn after independent review round 1.
It already carries a Conveyor hold: its marker comment (2026-11-24) records an unmerged
preparation on `docs/XYZ-forge-gh1583-conveyor-prep-2026-11-24` at `6047be0fe`, three review
rounds ending Escalated at the cap with one open [Should], and "Next owner: operator". Conveyor
preserves holds, so #1590 stays held for the operator and this PR adds no capture or PRS row for
it. #1638 replaces it.

## Existing backlog packets naturally stale under the #1664 gate

None on the integration backlog. `git grep '"prepared_commit"' -- PROJECT/` at `6142128d9c43`
finds no contract that records it: the only mentions are prose in
`PROJECT/2-WORKING/GH-1476-RAW-TASK-PREPARATION.md` and
`PROJECT/2-WORKING/GH-1664-STALE-EVIDENCE-ADMISSION.md`. The gate skips every legacy packet, so
none can be naturally stale. (Unmerged preparation branches such as #1590's are outside this
claim.) Run A's stale witness therefore uses the #1664 suite's disposable replay, labelled as
such, unless one of the three packets above becomes naturally stale before launch because a cited
file changes on `development`.

## PRS read-back (`prs-readback.txt`)

Written with `releases_app.py roadmap pickup … --rated P/S/A/E` (dry run inspected first);
`releases_app.py check`: clean (0 failures).
