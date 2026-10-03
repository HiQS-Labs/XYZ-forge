# GH947 final verification and handoff

Runtime implementation: `1dc04f05460a2bc8b05949483d63a5d6bc46ad0a`.
HiQS demonstrated immutable consumer source: `452f6e48d7fc76b4b21c00a6b325ea015aa7a372`.
Final reviewed source: `a9c7335d9d549e354ffc45ce2d197b9a55ec4faf`.
Valid final Agy attestation: `fc0c19ae2bf824eed118de2f114c30a2d7805eb2`, driver exit0.
Round2's textual PASS was rejected for removed spacing (driver exit4); it is not an
approval. Round3 preserved the bytes and received valid attestation within the cap3.

Existing profile suite 51 pass; Claude subscription Python cases and four turn controls
pass; process-group suite 43 pass. Manual synthetic controls include unknown policy
constraint refusal, single resolver admission, actual native advisory argv, receipt reuse,
provider/build/config refusals, expiry during auth preflight, modelUsage mismatch and
unsupported actor zero token claims. Both expiry and policy mutations fail as expected,
then pass when restored. The exact manual command and provenance are retained alongside
logs; no new suite, registry entry, or production clock override was added.

## Full local gate

`ci-local.sh --base origin/development` exited 0 on attested commit `fc0c19ae`.
All 10 steps passed. The native record has 409 verdict entries: 408 pass and one
duplicate acorn-extract skip (already executed by the npm stage), zero failures.
Origin/HEAD/tree are unchanged before and after; see `full-gate-identity.json`.
The full outer log and native record are retained as `ci-local.log` and
`full-gate-record.txt`. The native record hashes the temporary suite transcript, which
the runner removes on normal exit (ci-local.sh:152); the retained outer log has its own
SHA256 in provenance. These are distinct logs and digests.
The obsolete candidate also exited0 with unchanged identity; its separate JSON
records why that result is not current runtime qualification.
Run in a fresh full clone from canonical remote, never a linked worktree or valued task
clone. Origin, HEAD and tree identity checked before and after. ShellCheck v0.11.0 was
installed only in `/tmp`, from the official Darwin-aarch64 release; archive SHA256
`339b930feb1ea764467013cc1f72d09cd6b869ebf1013296ba9055ab2ffbd26f` was checked against
release metadata. Python suite dependencies were isolated in a `/tmp` virtualenv.
The earlier gate on `29a9d369` is obsolete for current runtime qualification after the
policy-equality fix. Its outcome is retained separately and is not reused as current proof.

## Limits and lifecycle

[XYZ draft PR954](https://github.com/HiQS-Labs/XYZ-forge/pull/954) depends on
[HiQS draft PR6](https://github.com/NeochromeTeam/hiqs-ai-resolve/pull/6), itself stacked
on [PR29](https://github.com/NeochromeTeam/hiqs-ai-resolve/pull/29). Both issues remain
open/in progress. PR29 publication/security defects, a maintained real published recipe,
and a separately authorized live advisory pilot still block the foundation-ready
milestone. Synthetic native binary controls are not real Claude/Fable execution evidence.
No provider spend, deployment, primary checkout refresh, merge or clone teardown occurred.

The documented `XYZ_SKIP_PREPUSH=1` draft/previously-gated automation route was used for
publication to avoid mutation-heavy gates in the retained task clone; the push hook is
skipped, not passed. Hosted smoke checks are recorded separately; workflow-skipped macOS
and Ubuntu jobs do not qualify this change. Local evidence is self-reported, not promotion
qualification. Changes after the tested source are reporting/docs/ledger metadata only.
Retain the task clone until verified landing; `/merge-cleanup` can then retire it.
