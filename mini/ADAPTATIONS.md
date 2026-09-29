# XYZ-mini adaptation policy (the sync exception path)

`utils/py/xyz_mini_sync.py` publishes the managed files of HiQS-Labs/XYZ-mini. The default
contract is byte-identity: a `managed` destination is replaced with its forge source bytes on
every publication. Two documented exceptions follow; both live in the tool and are recorded here
so they ride the normal branch → primary-branch merge flow.

## 1. Publications from a non-primary forge branch

A publication is a function of (source revision, the tool's embedded MANIFEST) — the source
revision is whatever the forge checkout holds at run time, on **any branch**. Feature-branch
publications are legitimate: e.g. shipping a skill the branch introduced before its PR merges.
The tool records `source_repo`/`source_sha`/`source_branch` in the child's `.xyz-forge-revision`
and warns on stderr when the branch is not `development`. When the branch lands, re-publish from
`development` to re-baseline the pin.

Note: a checkout whose branch predates a manifest source refuses (exit 2) — run publications
from a branch that actually contains every manifest source.

## 2. Adapted destinations (mini-owned bytes)

Some child files deliberately diverge from their forge source (flat-layout paths, child-scoped
hardening). The `adapted` mode covers them:

- the forge source must exist and stay tracked — it is the upstream of record;
- the tool copies it to the child only when the destination is absent, never replaces an existing
  adapted destination, and deletes it only when dropped from the manifest;
- an adapted destination missing from the child is refused — the tool never fabricates one from
  forge bytes (that would silently un-adapt it);
- **every adapted path must be documented in `mini/ORIGIN.md`** (shipped to the child as
  `ORIGIN.md`); the tool refuses (exit 2) to publish an adapted path that file does not name.

`MANIFEST.txt` in the child lists every tool-owned path (managed and adapted) without marking the
kind; `ORIGIN.md` is the kind registry. Adaptations carry upstream debt: park it (`PARKED/`) or
file it, and either re-upstream the change or maintain the fork consciously. Keep the ORIGIN.md
table in sync when adding or dropping adapted entries — dropping an adapted entry deletes the
child files on the next publication.
