# GH-1427 verification

Plan QA: Codex relay `relay-system/2026-11-11/gh1427-plan-qa.md`, Approved in round 3. Base `0f21b761a`.

- **Suites:** 15 existing focused suites green in a disposable full clone (`suites.log`). The frozen-twin guard is clean. No new suite (GH-831).
- **M1/M2 (manual, fake CLI, host that does not ignore `relay-system/logs/`):** the console prints
  `failed (exit 1): error_max_budget_usd: Reached maximum budget ($0.50)`. The JSON transcript survives. Exactly one `tick cost` row is written on both the failure and the success turn. Builder turns get `3.00/40`, reviewer turns `1.00/12`, and env overrides both (`m1m2-green.log`).
- **Red control on base:** the same script shows a bare `failed (exit 1)`, the JSON log **MISSING** while `.stderr` is PRESENT, 0 cost rows, and `0.50/12` for both roles (`m1m2-red-base.log`). That is the LTVera-Pandas incident signature. It also shows that on a non-ignoring host, base never recorded Claude cost even for *successful* turns, because the log was deleted before the cost block read it.
- **Live smoke (claude 2.1.322, bounded):** r1 found that a real `error_max_budget_usd` result reports `usage` all-zero (`total_cost_usd` 0.078), so no row was written (`smoke-live-r1.log`). Fixed by falling back to `modelUsage` (a4836f6c6). r2 main path: exit 5, the reason printed, the log kept, 1 row (25646 in / 178 out, summed across models including the CLI's auxiliary Haiku call). r2 adjacent path (rerun on the default builder ceiling): exit 0, 1 row, ~$0.15 (`smoke-live-r2.log`).
- **r3 (final-QA r1 [Should]):** the smoke now keeps a credential-free accounting projection of each real result
  (`accounting-SMOKE-BUDGET.json`, `accounting-SMOKE-OK.json`) and prints an explicit comparison (`smoke-live-r3.log`, at 5dee2cc2).
  For the budget stop, `usage` is 0/0, and `modelUsage` sums to 25646 in (haiku 1784+0, sonnet 3+23859) and 174 out (25+149). The single row reads 25646/174, so **MATCH**.
  For the success turn, the single row equals `usage` (258026/1253), so **MATCH**, and the `modelUsage` fallback stays unused when `usage` is nonzero.
- **Final QA:** Codex relay `relay-system/2026-11-11/gh1427-final-qa.md`, Approved in round 2 at `426bae21`. Only this paragraph's repair followed it.
- **ESCALATION:** the M1 log parsed through the GH-379 key list yields `subtype=error_max_budget_usd, errors=[...]`. Live total spend for the smoke was about $0.33 of list-price usage.
- **Not covered:** a full Marathon/Jog end-to-end Claude-builder run (left for the operator's next real run); the full gate runs in the pre-push hook on the final approved commit.
