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
  root as three levels up from their own directory. Nothing reads the tier name.
- **Look a skill up by name:** `ls -d skills/*/<name>`.
- **Re-tier a skill:** `git mv skills/<old>/<name> skills/<new>/<name>`, then repoint its row in the
  Skills Index and any `skills/<old>/<name>` literal (`grep -rn "skills/<old>/<name>"`). No code change.
- **Add a skill:** create it under the tier you expect it to be used at; `4-occasional/` is the
  default when unsure. The Skills Index row is part of the change.
- **Discovery is unchanged.** Apps still scan `~/.claude/skills/<name>` (and the Codex / agy / ZCode
  equivalents). Those entries point at the Skills Army HQ collection or at a skill's own `install.sh`
  symlink — never at a tier folder — so re-tiering never breaks an installed skill. The one
  machine-local follow-up after a re-tier is the collection's provenance:
  `intake.py --apply update <name> --source <forge>/skills/<tier>/<name>`.
- **Vendored copies mirror the layout.** `relay-automation/xyz-vendor.sh` copies `skills/` verbatim,
  so a target repo's `.xyz/skills/` is tiered too. XYZ-mini is the exception: its publisher
  (`utils/py/xyz_mini_sync.py`) flattens the curated subset into the mini's own one-level `skills/`.
