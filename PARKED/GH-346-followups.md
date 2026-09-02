
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

## Found during Phase 3a (2026-09-01)

- **`default_deepseek_bin()` hardcodes one machine's absolute path.**
  `utils/py/deepseek-turn.py:22` falls back to
  `/Users/noelsaw/Documents/GH Repos/deepseek-harness/apps/cli/lib/bin.js` before trying
  `shutil.which("dsh")`, and returns that same path as the last resort when neither resolves. On
  any other machine the deepseek lane reports a missing binary at a path that was never theirs.
  Pre-existing, unrelated to Phase 3a, and not touched here — the profile resolver only names the
  shim, it does not resolve binaries. Worth its own issue.

- **`gh268-relay-cue-and-target-checks.sh:166-171` uses the banned `printf | grep -q` pattern.**
  Observed failing once under the full sequential gate with
  `line 167: printf: write error: Broken pipe`, then passing standalone (34/34). `grep -Fq` exits
  on its first match and closes the pipe; `printf` writing into the closed pipe takes EPIPE and,
  under `set -o pipefail`-adjacent conditions, the assertion reads an empty `$out` and fails. This
  is the hazard GH-139 exists to ban, still live in this suite. Fix is to write `$out` to a file
  in $WORK and grep the file. Pre-existing and unrelated to GH-346 Phase 3a — noticed because the
  suite failed a gate run on a branch that had not touched it.
