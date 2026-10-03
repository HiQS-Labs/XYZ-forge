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
- ownership is **per adapted entry**. An entry the child has never been published (a fresh child,
  or a newly added or re-added entry) is seeded once from forge bytes. After that, the tool never
  replaces, adds to, or prunes anything under the entry from the forge side. A file the forge adds
  later is not shipped, and a file the forge removes is not deleted from the child;
- whatever the child tracks under an established entry is carried forward and recorded in
  `MANIFEST.txt`, including child-only files such as a mini `install.sh`. A file the child deletes
  is recorded as gone and never re-created from forge bytes;
- dropping the **whole entry** from the manifest deletes every path the child's `MANIFEST.txt`
  records under it. A child file added since the last publication is not recorded yet, so the drop
  leaves it in place;
- **every adapted entry needs an exact row in `mini/ORIGIN.md`** (shipped to the child as
  `ORIGIN.md`). The first column must name the entry's destination and the Kind column must say
  `adapted`. A path mentioned in a Notes column, or a parent directory, documents nothing. The tool
  reads the file as committed at the published source SHA. It refuses (exit 2) when the row is
  missing, when a row still says `adapted` for an entry the manifest no longer publishes as
  adapted, or when `--allow-dirty` would ship uncommitted edits to the file.

`MANIFEST.txt` in the child lists every tool-owned path (managed and adapted) without marking the
kind; `ORIGIN.md` is the kind registry. Adaptations carry upstream debt: park it (`PARKED/`) or
file it, and either re-upstream the change or maintain the fork consciously. Keep the ORIGIN.md
table in sync when adding or dropping adapted entries — dropping an adapted entry deletes the
child files on the next publication.
