# skills/ — grouped by frequency of use

Every skill lives in exactly one tier folder, `skills/<tier>/<name>/SKILL.md` (GH-744). The
folders are numbered so a plain directory listing reads as a usage map:

| Folder | Cadence | What lives here |
|---|---|---|
| `1-hourly/` | every hour | the in-task loop: intake, recon, planning discipline, review relays, the ledger |
| `2-daily/` | a few times a day | landing, queueing and driving work; multi-session and multi-repo coordination |
| `3-weekly/` | weekly | cadence reviews, cleanup sweeps, collection and publishing maintenance |
| `4-occasional/` | least frequently | setup, audits, one-off tooling and specialist lenses |

The per-skill index with a one-line purpose for each is `ARCHITECTURE.md` → "Skills Index".

## The contract

- **Depth, not tier, is load-bearing.** Scanners glob `skills/*/*/SKILL.md`; the locators that ship
  inside skills (`find-harness.sh`, `find-hq.sh`, `find-xyz.sh`, `find-pdda.sh`, …) resolve the repo
  root as three levels up from their own directory. Publish manifests and some scripts still contain explicit tier paths.
- **Look a skill up by name:** `ls -d skills/*/<name>`.
- **Re-tier a skill:** `git mv skills/<old>/<name> skills/<new>/<name>`, then repoint its row in the
  Skills Index and any `skills/<old>/<name>` literal (`grep -rn "skills/<old>/<name>"`). This includes paths in code and tests.
- **Add a skill:** create it under the tier you expect it to be used at; `4-occasional/` is the
  default when unsure. The Skills Index row is part of the change.
- **Refresh only your installed skills and configured app targets after a move.**
  Skills Army HQ app links point at its flat collection and remain valid; refresh each moved
  skill's source receipt with `intake.py --apply update <name> --source <forge>/skills/<tier>/<name>`.
  A direct `install.sh` link points at the source folder and becomes dangling when it moves:
  re-run that skill's installer from its new location, using the same target options as before.
  There is no need to install missing skills or configure IDEs you do not use.
- Cross-skill and repo-document links use canonical repository URLs where needed so they also
  work in the flat deployed collection.
- **Vendored copies mirror the layout.** `relay-automation/xyz-vendor.sh` copies `skills/` verbatim,
  so a target repo's `.xyz/skills/` is tiered too. XYZ-mini is the exception: its publisher
  (`utils/py/xyz_mini_sync.py`) flattens the curated subset into the mini's own one-level `skills/`.
