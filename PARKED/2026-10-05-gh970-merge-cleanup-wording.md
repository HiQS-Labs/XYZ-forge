# Parked — 2026-10-05 (found during GH-970 final QA)

- **merge-cleanup SKILL.md still says `/start-task` creates clones in the listed safe roots.**
  `skills/2-daily/merge-cleanup/SKILL.md` Phase 1 (~line 106) attributes `~/agent-workspaces` / `~/marathon-clones`
  placement to `/start-task`; after GH-970, start-task clones are siblings of the primary. Codex GH-970 review nit.
  Outside GH-970 because that file is a full-gate surface (`utils/ci-route.sh:336`). Next: fold a one-line wording fix
  ("legacy and marathon clones; pass `--root "$(dirname <primary>)"` for start-task siblings") into the next
  merge-cleanup change (e.g. the GH-789 port).
