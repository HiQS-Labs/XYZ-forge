# GH-254 manual verification

Actual rows.sort AST executed against draft-first input with missing, equal and conflicting target dates. All produce cut/shipped history by date, then active, then draft; nullable versions remain valid. Baseline kept draft before active on missing dates (witnessed failure). No test suite added. Full qualification pending parent host slot.

Existing gh103-timeline-exporter suite passed (exit0, 2.022s) in disposable full clone at a8ef441b9dce8a9b3e9db5bdddef88836d4bc859; HEAD/origin/bare/local identity unchanged. Normal hooks installed.
