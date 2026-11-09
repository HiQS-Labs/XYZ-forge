# GH-254 manual verification

Actual rows.sort AST executed against draft-first input with missing, equal and conflicting target dates. All produce cut/shipped history by date, then active, then draft; nullable versions remain valid. Baseline kept draft before active on missing dates (witnessed failure). No test suite added. Full qualification pending parent host slot.
