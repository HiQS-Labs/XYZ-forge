# Parked — 2026-10-04 (found during GH-964)

- **`daily-planner` is missing from the ARCHITECTURE.md Skills Index.** `skills/2-daily/daily-planner/`
  exists on `development` (`8853cd6a`) but no row in `ARCHITECTURE.md` → "Skills Index" links
  `skills/2-daily/daily-planner/SKILL.md`, and the `2-daily` heading count read 16 against 17 folders.
  GH-964 added only its own `xyz-mod` row (count now 17 rows / 18 folders). Outside GH-964's scope.
  Next check: add the row and recount the heading, or confirm the omission is deliberate.
