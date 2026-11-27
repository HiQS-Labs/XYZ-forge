# GH-1423 relay attestation delivery

## Observed before the fix

The rebalanceOS review returned exit 4 with `attest-publish-failed`, although attestation commit `a278102` landed. During Forge preparation on 2026-11-27, Git 2.50.1 reproduced the publication failure in a scratch repository. Its `.gitignore` contained `relay-system/`, and `relay-system/t.md` was force-added and committed when seeding the fixture. After editing the tracked file, `git ls-files --error-unmatch` returned 0, `git add -- <file>` returned 1, and `git commit -q -m m -- <file>` returned 0. The [preparation record](../../PROJECT/2-WORKING/GH-1423-RELAY-ATTEST-GITIGNORED.md#reproduction) captured these excerpts from staging stderr.

```text
The following paths are ignored by one of your .gitignore files: relay-system
hint: Use -f if you really want to add them.
```

The [recorded helper probe](../2026-11-27+GH-1658-runA-prep/probe-gh1423.py) returned 1 at baseline `6142128d9c43` because the commit landed but the helper reported failure. It returned 0 for the simulated fix, which also exercised a plain tracked path and a rejecting pre-commit hook. The fake fix that returned success without committing failed the probe. See the [matrix](../2026-11-27+GH-1658-runA-prep/matrix.txt) and [provenance](../2026-11-27+GH-1658-runA-prep/provenance.jsonl).

## Independent review of the delivered helper

In [round 1](../../marathon-system/gh-1423-relay-attest-gitignored/RELAY.md#round-1--reviewer--agy), agy ran the preparation probe against the delivered `utils/py/relay_drive.py` with `PYTHONDONTWRITEBYTECODE=1` and `TMPDIR="$PWD/.relay-scratch/tmp"`. The probe exited 0. The helper committed the tracked relay file under the ignored directory, committed it with the ignore rule removed, and returned false when a pre-commit hook rejected the commit. The reviewer also observed that an unrelated staged file stayed staged and a read-only Git directory yielded `Unable to create '.../.git/index.lock': Permission denied`.

## Terminal publication probe with stubbed Git responses

On 2026-11-27, the builder ran `PYTHONDONTWRITEBYTECODE=1 python3 .relay-scratch/probe-gh1423-terminal.py` from the turn worktree. It exited 0 after compiling the live driver (SHA-256 `ec6c0af36ed3985402bf20893429b34c16255c6d3059c310cb0ec689abb06065`). The scratch probe extracted the live helper, terminal judge, and review-once exit branches by AST. It restored the preparation patch's pre-fix staging call and combined return-code check in memory for the baseline arm. Each arm used a fresh scratch transcript, stubbed the token as done, and supplied the Git responses at the subprocess boundary. The driver wrote the actual trailer and JSON. The probe captured the requested commit subject and transcript bytes at the commit boundary and checked the resulting exit and record.

| Arm | Observed driver exit and diagnostic | Stubbed commit and actual JSON checks |
| --- | --- | --- |
| Baseline, ignored | 4, `attest-publish-failed`. `The following paths are ignored by one of your .gitignore files: relay-system` | One commit request succeeded and included the trailer. No record. |
| Fixed, ignored | 0, `reviewer approved/closed (STATUS: Approved, attested) after 1 turn` | One commit request succeeded and included the trailer. `load` validated the JSON and `candidate_ok` accepted it with stubbed ancestry and diff responses. |
| Fixed, no ignore rule | 0, same approval message | Same commit and record checks passed. |
| Fixed, commit rejected | 4, `attest-publish-failed`. `fixture: pre-commit rejected the attestation` | No successful commit and no record. |

Each successful stubbed commit had subject `relay-drive: attest <arm> approved by agy (reviewed aaaaaaaaaaaa)` and contained `### Attestation · relay-drive`. The scratch probe exercised the terminal decision and record writer. Real Git behavior for the delivered helper comes from the independent review above. The full-driver replay with actual Git commits and candidate ancestry remains outstanding under the turn's Git and suite restrictions.

## Full-driver replay procedure

Use a disposable full clone and the scratch repositories from case B of [the existing attestation suite](../../test/gh505-relay-attest.sh). Keep a fresh fixture for each arm. In a scratch copy of that fixture, use `relay-system/relay.md` consistently in the seed, reviewer stub, token path and driver invocation. For the ignored arms, add `relay-system/` to the fixture's `.gitignore` and force-add only the relay file during fixture seeding. Save combined driver output and the exit code. Check the last commit's subject and its relay-file contents, and check the task JSON under the target repository's Git directory at `relay-attest/<task>.json`.

| Arm | Expected result |
| --- | --- |
| Baseline driver, ignored directory | Exit 4 and `attest-publish-failed` with the staging diagnostic. The attestation commit lands and contains the trailer. The record is absent. |
| Fixed driver, ignored directory | Exit 0. The attestation commit contains the trailer and the task record exists and validates. |
| Fixed driver, no ignore rule | Exit 0 with the same commit and record checks. |
| Fixed driver, ignored directory, commit rejected | Exit 4 and `attest-publish-failed` with the hook diagnostic. Neither the attestation commit nor its record is published. |

For the rejection arm, give the target fixture its own pre-commit hook. Have it reject only when the working relay file contains the `### Attestation · relay-drive` heading, emitting a distinctive message to stderr before exiting 1. This lets the review turn commit first and exercises failure of the driver's attestation commit.

The relay designates `bash test/gh505-relay-attest.sh` as the harness gate.
