# GH-1299 acceptance — ceremony audit folded into sanity-check Plan mode

Same procedure and inputs as GH-1286 (`TESTS-RESULTS/2026-10-31+GH-1286/`): fresh Claude Code
general-purpose subagents (Claude Opus 5.5), each told to read only the skill snapshot and one input
([`inputs/`](inputs/), identical to GH-1286's), no git/gh/web. One change: the agent gets the whole
`sanity-check` skill and the operator request "Audit this plan for ceremony.", so it must find Plan
mode itself. Acceptance rules unchanged (GH-1286 plan steps 3–4).

| Run | sanity-check commit | Plan mode text | #1279 worked example | #1186 counter-example |
|---|---|---|---|---|
| f1 | `f86b1933` | compressed to ~35 lines | 2–3 of 6 ([raw](raw/f1-1279.md)) | **fail**: cut the red control ([raw](raw/f1-1186.md)) |
| f2 | `93920fe4` | tested GH-1286 wording, near verbatim | 4 of 6 ([raw](raw/f2-1279.md)) | **fail**: cut the red control ([raw](raw/f2-1186.md)) |
| ref | GH-1286 standalone `f09f8105` | — | 4 of 6 | pass |

## Reading

- **Compression lost behaviour.** The 35-line version (f1) kept the planned crash, the in-window
  canaries and the timed window, which the tested wording cuts. The shipped text is therefore the
  tested wording, not the compressed one.
- **#1279 with the tested wording matches the standalone skill (4 of 6):** it cuts the crash/miss
  faults, the slot accounting and the 8-hour spacing, and keeps the planted-flaw review. Still unmet,
  as before: cutting the adapter / driver derivative, and proposing one real marathon lane.
- **The #1186 counter-example fails in both fold runs, on one call:** both agents cut the optional red
  branch, arguing #1176 already showed the ratchet catches a new loose script and only the YAML wiring
  is new. The standalone skill kept it in its two later runs. The procedure wording is the same but
  its surrounding skill changed, and there is one sample per cell, so the cause is unresolved and
  parity with the standalone skill is unproven. Recorded as fail; no further rounds run, by the
  producer's judgment, to avoid tuning toward a known answer.
