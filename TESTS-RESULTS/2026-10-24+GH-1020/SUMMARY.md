# GH-1020 — manual check receipt (GH-1088 / GH-831: no new suite)

Change under test: `relay-automation/relay-turn-lib.sh` (reviewer handoff sentence names `tick done` on approval;
commits `7f6f0995`, `7cbbeb5e`) and `src/scope.js` (`release --to done|Approved|Closed` refused; `7f6f0995`).
Every run below happened in the disposable full clone `XYZ-forge-gh1020-reviewer-close-mismatch-2026-10-24-verify`
(a clone of `origin/development` @ `c5ef7a2e`, then `fix-under-test` = the task commit named per row), from a plain
unsandboxed shell, with Codex `gpt-6.1-sol` (codex-cli 0.159.1) as the real reviewer where a model ran. Provenance per
artifact: `provenance.jsonl`.

| Check | Where | Result |
|---|---|---|
| **Before fix (red control for 2)** — real Codex `--review-once` approval, `RELAY_PEER` unset | `before-fix-*` | model ran `tick release … --agent codex --to done` (`before-fix-codex-tick-commands.txt:3`); shim `WARN could not tick done … (not current owner?)`; driver **exit 4 close-mismatch**; `tick info` after: `status: open`, `handoff-to: done` |
| **1 — Guard, forced replay** (`check1-forced-replay/check1.sh`, 25 PASS / 0 FAIL) | `check1-forced-replay/` | `release --to done`, `--to Approved`, `--to Closed` each exit 1 with `"<word>" is a terminal status, not an agent — to close the token run \`tick done <task> --agent codex\``; `.tick/events` count unchanged; token still `claimed` by codex. Controls: `--to claude-a` and bare `release` succeed, one `task.released` each. After the refused misfire, `tick done` by codex succeeds (what rtl_enforce step 4 runs). **Red control** (guard hunk replaced by `origin/development:src/scope.js`): `release --to done` succeeds (`released:`), `tick done` then fails, `tick info` shows `handoff-to: done` — the before-fix state. |
| **2 — Prompt, real model approval** (`RELAY_PEER` unset, same trivial artifact as the before run) | `check2-after-fix/` | model ran `claim` then **`done RELAY-gh1020-check2-080134 --agent codex`** (no `release --to done`); driver `attested Approved by codex`, **exit 0**; `tick info` after: `status: done` |
| **3 — Adjacent path, real model non-approval** (`RELAY_PEER` unset, artifact returns `a - b`) | `check3-after-fix/` | model wrote `[Blocker]` + `VERDICT: FAIL`, kept `STATUS: Open`, ran `release … --to claude-a`; driver **exit 5** (review completed without approval); `tick info` after: `open`, `handoff-to: claude-a` |
| Focused suites on `7cbbeb5e` | `focused-suites-7cbbeb5e.txt` | relay-turn-handoff 2/2 · agy-turn 65/65 · gh432-failed-turn-persist 12/12 · relay-review-once 9/9 · gh505-relay-attest all (case G caught the first cut's builder-prompt copy, fixed in `7cbbeb5e`) · gh681-reviewer-probe-rules all · gh554-tick-unknown-flags 76/76 |

Check 2 alone does not discharge check 1 (a model that reads the fixed prompt simply runs `tick done`); check 1 is
the falsifiable test of the guard, with its own red control.
