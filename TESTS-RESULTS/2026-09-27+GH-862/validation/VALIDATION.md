# GH-862 validation plan — measured (2026-09-27)

**Method.** Registry at `54bd4ae6` (411 registered + 13 EXEMPT). D1 runtime: medians over the 8 newest committed
full-registry qualification receipts (`measured.json` → `d1_receipts`); median gate **2,989 s**, in line with #862's
"about 2988 s". D2 failures: 93 failed hosted `wave-reconcile` runs since 2026-09-12, with their `validate.sh`
summaries parsed (`d2-hosted-failed-runs.jsonl`, 16 had no summary and are unattributed), plus every committed green
receipt. D3/D4/D5: suite source, read by hand where the computed counter (`measure.py`) could not see the assertion
style. **No script branches on a suite name.**
- Scripts: `collect_d2.py`, `measure.py`, `d3_siblings.py`.
- Outputs: `measured.json`, `d3-nightly-siblings.txt`.

| # | Check (#862 *Validation plan*) | Measured result | Match |
|---|---|---|---|
| 1 | Heavy top 3 = gh436, gh549, marathon-drive | #1 `gh436` 183.1 s (6.13%), #2 `gh549` 153.0 s, #3 `marathon-drive` 115.7 s | yes |
| 2 | gh436 KEEP, `regression-caught` (#812), not NIGHTLY | red 7 of 109, all with `gh674` in the 2026-09-24 cluster; fixed by `0ae3452a` (#794), which changes product code | yes |
| 3 | #853 suites | `gh649`: 0/81, fixed at HEAD by `af4fef27` → `fixed-flake`, KEEP ✔. `gh496`: 2/107, race #813 fixed in product code by `d469343d` (#818) → `regression-caught`, KEEP ✔. `agent-chorus-bridge`: 21/107, #760 open → KEEP-FIX #853 ✔. **`gh492`: 0/107, fixed in the window by `9b39223f` (#793) → `fixed-flake`, KEEP.** **`gh620`: 0/72, fixed by `04b66e00` (#830) → `fixed-flake`, KEEP.** | 3 of 5 as expected; gh492/gh620 **differ because their fixes landed in this window** (D8) |
| 4 | gh798 prose (~13 of 21 grep docs); 8a/8b vacuous | 16 of 21 assertions grep repo docs (0.76, computed); 8a/8b edit a copy and grep the copy → vacuous (read) | yes (ratio higher than the estimate) |
| 5 | gh132, gh678, gh620 not prose; releases-skill, gh378 mixed | gh132 0 doc greps, gh678 0, gh620 behavioural → not prose ✔. gh378 2 of 7 (0.29) → SPLIT ✔. **releases-skill 29 of 39 (0.74)**, but 7 assertions run the installer → SPLIT, not TURN-OFF | verdicts match; releases-skill's ratio is above the "mixed" band |
| 6 | synthetic-pi-model-unset covered by pi-turn | `relay-automation/pi-turn.sh` execs `utils/py/pi-turn.py`; `pi-turn.sh` case 3 asserts exit 5 + no commit + no relay edit + binary never invoked ⊇ the synthetic's exit 5 | yes |
| 7 | NIGHTLY exercised (ranks 4–10, 0 failures) | gh280, gh365-tier-fail-closed, pdda-install-startup-docs, gh251, marathon-root-audit, gh365-pdda-gov-scan: all 0 failures. Siblings sharing an invoked target exist for gh280/marathon-root-audit, but none is shown to be a **superset** → no NIGHTLY proposed. Three suites' invocations weren't parsed → sibling UNKNOWN. `agy-turn` (#10) is excluded: 10/107 red | exercised; no NIGHTLY verdict (not forced) |
| 8 | TURN-OFF exercised | synthetic-pi → TURN-OFF, pinned by `test/gh141-synthetic-registry.sh:83` (restore: re-add the entry and the gh141 pin). The 8 #831 suites scored as if registered: gh578 (0.96), gh779, gh781, gh615, gh616, gh617 are pin/contract greps of SKILL text with only copy-mutation "execution" → prose → TURN-OFF; gh778/gh798 are prose plus installer checks covered by `gh678`'s all-installer matrix (D4) → TURN-OFF. **8 of 8** | yes |
| 9 | No behaviour guard proposed for TURN-OFF; nothing modified | the only TURN-OFFs are synthetic-pi (covered) and the 8 already-exempt prose suites; the scripts write only into this folder | yes |
| 10–12, 14 | Report issue dedupe, oversized report, per-turn comments, redaction | exercised for real in `../practice/` (dedupe fixed and passing on run 4, #876) | yes |
| 13 | Reminders fire | radar: `gh436` + `gh674` red together in 7 runs → fires. whack-a-mole: the #853 members in the sample (agent-chorus-bridge 21 red) → points to #853, no new umbrella | yes |

**New findings the known answers didn't contain:**
- `agy-turn` was red in 10 of 107 runs, all on 2026-09-15/16, and green in every run since. The cause is not traced (`unattributed`).
- `gh777-inventory-ratchet` was red in 7 runs on 2026-09-24, and `pdda-repo-contract` in 5 runs on 2026-09-17/24. Both are candidates for the `coupling` class at the Oct 8 audit.
