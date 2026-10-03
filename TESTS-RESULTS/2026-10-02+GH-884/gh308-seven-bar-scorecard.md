# GH-884 admission rubric — gh308 worked example, seven-bar scorecard

Worked example for the GH-884 re-earn transform. Suite: `test/gh308-frozen-twin-guard.sh`.
Witnessed against committed `12acffbd` in a disposable full clone (re-witnesses in this directory
and `../2026-10-02+GH-928/`; the initial run predates the relay, against the 88cb6090-era tree). Full narrative: GH-884 PoC comment, 2026-10-02.

| # | Bar | Verdict | Evidence |
|---|---|---|---|
| 1 | Red control witnessed | ✅ | Internal: 38 self-assertions incl. throwaway-repo red matrix (`gh308-full-selftest.log`). External: staged twin edit blocked by name, rc=1, restore byte-identical (GH-884 PoC comment, 2026-10-02) |
| 2 | Containment | ✅ | `lib/fixture-guard.sh` (GH-10) + mktemp sandboxes; invoking-clone fingerprint (full local config + HEAD) identical before/after (PoC comment) |
| 3 | Invocation-shape coverage (GH-195 lesson) | ✅ | staged / `--base REV` / `GH308_FROZEN_TWIN_BASE` / strict mode; one shared implementation, no inline re-implementation (GH-379 lesson) |
| 4 | Expected set derived from source | ✅ (hybrid, documented) | FROZEN set read from banners in the tree; two explicit historical-regression pins (GH-362 marathon-plan retirement; relay-turn-lib non-freeze) |
| 5 | Determinism / flake history | ✅ (partial) | two consecutive runs identical, 6.7s; formal N/window would come from the Oct 8 audit's 4-source failure history |
| 6 | Provenance | ✅ | this directory + `../2026-10-02+GH-928/` (relay rounds) + GH-884 PoC comment |
| 7 | Cost | 57 ms CI mode · 6.7 s full self-test · ≈15 min agent re-earn dry run | measured |

Scope note (per relay-r2/r3): ONE worked example — no measured throughput or rebuild-success rate
for the long tail follows from it.
