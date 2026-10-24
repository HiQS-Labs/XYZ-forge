---
gh_issue: 1020
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1020
title: "Relay reviewer close: STATUS header and token disagree (close-mismatch)"
status: Proposed (1-INBOX — not yet active)
created: 2026-10-10
owner: claude-fable-5-1 (start-task, 2026-10-24)
doc_type: bugfix
complexity: 2
risk: 2
effort: 2
phases: 1
ratings_provisional: false
rating: 85/82/50/80
non_goals:
  - Marathon recovery / `--retry <phase>` replay (issue proposal 3) — separate, larger change.
  - Loosening `close-mismatch` in `relay_drive.py`; the agreement rule is correct.
  - Letting a builder or the orchestrator self-attest (GH-505/509 unchanged).
  - New tests, suites or registry entries (GH-831).
related:
  - https://github.com/HiQS-Labs/XYZ-forge/issues/763 (same mode, rows 1–3; duplicate — closed by the same PR)
  - https://github.com/HiQS-Labs/XYZ-forge/issues/554 (reviewer `done` flag misuse, closed)
  - https://github.com/HiQS-Labs/XYZ-forge/issues/1081 (factory run 1 hit this; run 4 is blocked on it)
  - relay-automation/relay-turn-lib.sh (`rtl_turn_prompt`, `rtl_enforce` step 4)
goal: >
  An approving reviewer turn ends with header `STATUS: Approved`, token `done`, and
  `relay-drive.sh --review-once` exit 0 — whether or not the model also runs `tick` itself.
---

# Relay reviewer close-mismatch (GH-1020, closes GH-763)

## Observed (ground truth, not the issue's guess)

Reproduced on `development` @ `c5ef7a2e` (2026-10-24, Codex `gpt-6.1-sol`, `RELAY_PEER` unset): one
real `relay-drive.sh --review-once` approval on a trivial artifact → shim
`WARN could not tick done … as codex (not current owner?)`, driver exit 4 `close-mismatch`,
`tick info` = `status: open`, `handoff-to: done`. Receipt: `TESTS-RESULTS/2026-10-24+GH-1020/`.

The turn prompt built by `rtl_turn_prompt` (`relay-automation/relay-turn-lib.sh:999-1000`) tells the
model: *"(3) when finished, release --to the other agent (the role named by NEXT in the file)"* when
`RELAY_PEER` is unset — which is the default for `relay-drive.sh --review-once`; the driver never sets
`RELAY_PEER` (only `codex-turn.sh:100` reads it from the environment). On approval the thread's own
protocol sets `NEXT: done`, so the model runs `tick release <task> --agent codex --to done`
(observed verbatim in the Codex transcript). `release` succeeds: the token is now `open` with
`handoff-to: done`, and no agent owns it.

The shim's deterministic close (`rtl_enforce` step 4, `relay-turn-lib.sh:1566-1602`) then reads
header `STATUS: Approved` and runs `tick done <task> --agent codex`. `assertOwnership`
(`src/scope.js`) throws `task … is open (never claimed)`, so the shim prints the WARN and leaves the
token. `relay_drive.py:732/781` sees a terminal header with a live token and exits 4 `close-mismatch`.

Two writers, one token, and the prompt itself names the wrong verb for the terminal case. The
`role_note` sentence *"When approving, hand the token off with done"* is in the same prompt, so the
model receives both instructions and merges them into `release --to done`.

## Smallest fix (one file, no new state)

1. **Prompt (`rtl_turn_prompt`):** the `handoff` text names the terminal verb explicitly:
   if `STATUS` is `Approved`/`Closed`, run `done <task> --agent <me>`; otherwise `release --to <peer>`
   (or the agent named by `NEXT`); **never `release --to done`** — `done` is a verb, not an agent.
   Keeps the GH-681 `role_note` sentence byte-identical (pinned by `test/gh681-reviewer-probe-rules.sh`).
2. **Shim (`rtl_enforce` step 4):** when the header is terminal and the token is `open` (the model
   released it — to `done`, to the peer, or to nobody), re-`claim` it as this agent (claim is legal:
   `src/claim.js` refuses an open token only when `handoff_to` names a *different* agent; `done` and the
   peer are handled by passing `--force` only if needed — see plan) and then `tick done`. The existing
   WARN stays for a token another agent actually holds. This makes the acceptance line *"whether or not
   the model also runs tick itself"* true.

Row 4 of the issue (header left `Open`, token `done`) is not reproduced here and is out of this fix's
scope; it is tracked in the issue as proposal 2.

## Verification (GH-831: no new tests)

- Existing suites: `test/agy-turn.sh`, `test/gh432-failed-turn-persist.sh`, `test/relay-review-once.sh`,
  `test/gh505-relay-attest.sh`, `test/gh681-reviewer-probe-rules.sh` (pins the role_note sentence),
  `test/gh554-tick-unknown-flags.sh`. Run in a disposable full clone.
- Manual check (recorded under `TESTS-RESULTS/2026-10-24+GH-1020/`): the same real Codex
  `--review-once` approval on the same trivial artifact, before (exit 4, `handoff-to: done`) and after
  the fix (exit 0, token `done`, attested). Red control = the before run above.
- Adjacent path: a non-approval review (`STATUS: Open`, `NEXT: Producer`) still hands off to the peer
  and exits 5.

## Rating (2026-10-24)

`rated 85/82/50/80` — sev 82: an approving review is refused and the automated relay/marathon halts
until an operator repairs the token by hand; no data lost, recovery bounded (matches #763's 82).
pri 85: factory run 4 (#1081 successor) is blocked on it; 6 incidents in the last 14 days window
(2026-10-10 ×5 across Agy and Codex, 2026-10-14 in #1081) vs 1 in the preceding 14 (none; #763 is
2026-09-23) — rising, same class, reproduced today on demand. appeal 50 neutral. effort 80: two
edits in one file, no schema, no new state.
