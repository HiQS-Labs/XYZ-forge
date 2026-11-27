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

## Independent full-driver replay

On 2026-11-27, agy ran four isolated scratch repositories through the Python driver, the real `codex-turn.sh` shim, and `bin/tick`, with a scripted reviewer. The fixed driver SHA-256 was `ec6c0af36ed3985402bf20893429b34c16255c6d3059c310cb0ec689abb06065`. The baseline arm restored the pre-fix staging call and return-code check in a scratch copy. Agy also reran the preparation helper probe against the fixed driver and observed exit 0. [Round 2 reviewer replay](../../marathon-system/gh-1423-relay-attest-gitignored/RELAY.md#round-2--reviewer--agy)

| Arm | Observed exit and diagnostic | Commit and attestation record |
| --- | --- | --- |
| `T-1-base-ignored` | Exit 4, `attest-publish-failed`. Staging stderr began `The following paths are ignored by one of your .gitignore files:`. | Attestation commit `3800d45` landed with the trailer. The record was absent. |
| `T-2-fixed-ignored` | Exit 0. Driver reported `STATUS: Approved, token done, attested by rev`. | Attestation commit `10566e2` landed with the trailer. `relay_attest.load` succeeded and `candidate_ok` returned `(True, None)`. |
| `T-3-fixed-plain` | Exit 0. Driver reported approval attested by `rev`. | Attestation commit `67d6bc3` landed with the trailer. `relay_attest.load` succeeded and `candidate_ok` returned `(True, None)`. |
| Fixed driver with rejecting hook | Exit 4, `attest-publish-failed`. Commit stderr was `fixture: pre-commit rejected the attestation`. | HEAD stayed at the reviewer turn `88da43b`. The attestation commit, committed trailer, and record were absent. |

The baseline commit subject was `relay-drive: attest T-1-base-ignored approved by rev (reviewed e5d4c4c0a5b6)`. For each landed attestation commit, the reviewer verified `### Attestation · relay-drive` in `HEAD:relay-system/relay.md`. The fixed success arms validated their respective task records under `.git/relay-attest/` against the resulting candidate HEAD.

## Replay procedure

Use a disposable full clone and the reviewer-approval fixture from case B of the [existing attestation suite](../../test/gh505-relay-attest.sh). Create a fresh scratch repository per arm and use the nested relay path consistently in the seed, reviewer stub, token path, and driver invocation. In the ignored arms, add `relay-system/` to `.gitignore` and force-add only the relay file during fixture seeding. For the rejection arm, install a fixture-local pre-commit hook that emits the rejection diagnostic and returns 1 only when the working relay file contains the attestation heading. This lets the reviewer turn commit before the publication attempt.

Run the driver with worktree isolation enabled and save its output and exit code. Inspect the last commit's subject and committed relay file, then check for `.git/relay-attest/<task>.json`. For the success arms, load the task record with `relay_attest.load` and check the resulting candidate HEAD with `relay_attest.candidate_ok`.

The relay designates `bash test/gh505-relay-attest.sh` as the harness gate.
