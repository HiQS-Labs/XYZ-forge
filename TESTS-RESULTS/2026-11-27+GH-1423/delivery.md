# GH-1423 relay attestation delivery

## Observed before the fix

The rebalanceOS review returned exit 4 with `attest-publish-failed`, although attestation commit `a278102` landed. During Forge preparation on 2026-11-27, Git 2.50.1 reproduced the publication failure in a scratch repository. Its `.gitignore` contained `relay-system/`, and `relay-system/t.md` was force-added and committed when seeding the fixture. After editing the tracked file, `git ls-files --error-unmatch` returned 0, `git add -- <file>` returned 1, and `git commit -q -m m -- <file>` returned 0. The [preparation record](../../PROJECT/2-WORKING/GH-1423-RELAY-ATTEST-GITIGNORED.md#reproduction) captured these excerpts from staging stderr.

```text
The following paths are ignored by one of your .gitignore files: relay-system
hint: Use -f if you really want to add them.
```

The [recorded helper probe](../2026-11-27+GH-1658-runA-prep/probe-gh1423.py) returned 1 at baseline `6142128d9c43` because the commit landed but the helper reported failure. It returned 0 for the simulated fix, which also exercised a plain tracked path and a rejecting pre-commit hook. The fake fix that returned success without committing failed the probe. See the [matrix](../2026-11-27+GH-1658-runA-prep/matrix.txt) and [provenance](../2026-11-27+GH-1658-runA-prep/provenance.jsonl).

## Full-driver replay

Use a disposable full clone and the scratch repositories from case B of [the existing attestation suite](../../test/gh505-relay-attest.sh). Keep a fresh fixture for each arm. In a scratch copy of that fixture, use `relay-system/relay.md` consistently in the seed, reviewer stub, token path and driver invocation. For the ignored arms, add `relay-system/` to the fixture's `.gitignore` and force-add only the relay file during fixture seeding. Save combined driver output and the exit code. Check the last commit's subject and its relay-file contents, and check the task JSON under the target repository's Git directory at `relay-attest/<task>.json`.

| Arm | Expected result |
| --- | --- |
| Baseline driver, ignored directory | Exit 4 and `attest-publish-failed` with the staging diagnostic. The attestation commit lands and contains the trailer. The record is absent. |
| Fixed driver, ignored directory | Exit 0. The attestation commit contains the trailer and the task record exists and validates. |
| Fixed driver, no ignore rule | Exit 0 with the same commit and record checks. |
| Fixed driver, ignored directory, commit rejected | Exit 4 and `attest-publish-failed` with the hook diagnostic. Neither the attestation commit nor its record is published. |

For the rejection arm, give the target fixture its own pre-commit hook. Have it reject only when the working relay file contains the `### Attestation · relay-drive` heading, emitting a distinctive message to stderr before exiting 1. This lets the review turn commit first and exercises failure of the driver's attestation commit.

The builder checked Python syntax and read the publication path. The relay restrictions reserved Git operations and the attestation suite for the harness or an authorized disposable-clone replay. The table gives expected outcomes for that replay.
