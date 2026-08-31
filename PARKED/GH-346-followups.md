
## GH-346 — parked after QA approval (2026-08-31)

Non-blocking residuals from the GLM 5.3 review of Phases 0-2 (relay:
`relay-system/2026-08-31/gh346-phase0-2-qa.md`). All four are "derive it instead of curating it" —
the same lesson the issue itself is about — so they belong with the ROI checkpoint, not before it.

1. `test/gh346-telemetry-row-written.sh`'s `cases` list curates the shims' dispatched defaults.
   A shim changing its default fails no test. Derive from the shims' source the way LANES is.
2. `test/gh346-gateway-allowlists.sh`'s #8/#9/#10 loops still name commandcode/deepseek explicitly
   rather than iterating `$LANES`. A ninth lane is caught loudly by #2/#3/#4/#5 but would be
   silently unchecked for gate_env / the `*_AGENT` reset / `GATE_SCRUBBED_ENV`.
3. `harness_turn_logger.py`'s new rc-visibility branch is pinned by no test — a revert to silence
   passes everything.
4. `relay-automation/README.md`'s Components table has no rows for claude/commandcode/deepseek/
   smallcode. Pre-existing, additive-only; reviewer agreed parking is right.

Reviewer's standing condition, carried forward: the ROI checkpoint item "Confirm harnesses.db
telemetry matches dispatch for all 8 gateways" MUST NOT be ticked while agy/codex still record a
DECLARED (not dispatched) default. That item is where Phase 3 either closes the caveat or the
sentinel question re-opens.
