# Gen 3.5 soak receipts (2026-08-22 campaign, committed 2026-08-23)

Evidence for #174 (Part G) and #177 (§2-§4), and the pre-fix behavior recorded in
`test/baselines/GH-18*-negative-control.md`. Campaign run per SOP.md in a
standalone full clone at development `d8e8c5b0`: validate.sh gate (257/257),
four targeted probes, then a 3600s time-budgeted loop over the five Gen-3
engines (276 iterations, 1,656/1,656 expected-verdict, 0 flakes, 0 drift).

- `soak_summary.json` / `soak_telemetry.jsonl` — campaign summary + per-run records
- `gh174-soak-driver.py` — the campaign driver (control.json abort, PGID containment)
- `probes/` — targeted probe artifacts (B2a emitted reproducer, A10 null record,
  real-turn log, sample GH-141 record)
- `gh174-validate-baseline.log` — full qualifying-gate output
- per-iteration logs (1,656 files) were deliberately not committed; the JSONL
  carries every record's verdict, rc, and duration.

Findings became #180-#184 (auto-filed per SOP §1). Completion PR: see #174.
