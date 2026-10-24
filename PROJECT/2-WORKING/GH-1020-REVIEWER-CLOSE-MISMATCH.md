---
gh_issue: 1020
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1020
title: "Relay reviewer close: STATUS header and token disagree (close-mismatch)"
status: active
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

## Status

| What was just completed | What's next |
|---|---|
| Final Codex QA **PASS** (`relay-system/2026-10-24/gh1020-final-qa.md`, attested on `1fd5d8b6`; one text nit on the rating windows, applied here). Code: `7f6f0995` + `7cbbeb5e`. Receipts: `TESTS-RESULTS/2026-10-24+GH-1020/`. | Tier-3 `ci-local.sh` once in the disposable `-gate` clone on this commit, then push through the pre-push gate and open the ready PR against development (do not merge). |

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

## Smallest fix (two edits, no new state, no new writer)

Why the shim cannot repair it after the fact: once the model has run `release --to done`, the token is
`open` with `handoff_to = "done"`. `src/claim.js` refuses a claim on an open token whose `handoff_to`
names a different agent (`reserved for another agent`; `--force` only bypasses path overlap), and
`src/scope.js` `done()`/`release()` require a live claim by the caller. The configured reviewer (or
any other real agent) cannot reclaim it; only an identity literally named `done` could, and no such
agent exists. The supported recovery is a fresh token id — exactly the manual recovery in #1020. So
the fix must stop the bad write, not clean up after it.

1. **Prompt (`rtl_turn_prompt`, `relay-turn-lib.sh:999-1000`):** the `handoff` text names the
   terminal verb: *if you set `STATUS: Approved` or `Closed`, close the token with `done <task> --agent
   <me>`; otherwise `release --to <peer>` (or the agent named by `NEXT`). `done` is a verb, never a
   `--to` target.* The GH-681 `role_note` sentence stays byte-identical (pinned by
   `test/gh681-reviewer-probe-rules.sh`). Covers the observed trigger.
2. **Tick guard (`src/scope.js` `release()`):** refuse `--to done` (and the other terminal words
   `Approved`/`Closed`) with a one-line error naming the right verb. The model's misfire then fails
   *before* ownership changes hands, the agent still owns the token, and the shim's existing
   deterministic `tick done` (`rtl_enforce` step 4) closes it. This is what makes the acceptance line
   *"whether or not the model also runs `tick` itself"* true, in the same style as #554 (tick refuses a
   misuse instead of silently recording it). `rtl_enforce` itself is unchanged.

Row 4 of the issue (header left `Open`, token `done`) was not reproduced here and is out of this fix's
scope; it stays tracked in #1020 as proposal 2. Proposal 3 (marathon `--retry` replay) is a non-goal.

Alternatives rejected: (a) prompt-only — leaves the acceptance line untrue for a model that ignores the
prompt (two were observed on 2026-10-10); (b) shim reclaim-and-done — refused by `claim` for the
reviewer, see above, and a repair path that re-owns a released token would be a second writer; (c)
loosening `close-mismatch` in `relay_drive.py` — the agreement rule is the safety property (non-goal).
Rollback: revert the two hunks; no state or schema involved.

## Verification (GH-831: no new tests)

- Focused suites during iteration: `test/relay-turn-handoff.sh` (the rtl_enforce step-4 suite),
  `test/agy-turn.sh`, `test/gh432-failed-turn-persist.sh`, `test/relay-review-once.sh`,
  `test/gh505-relay-attest.sh`, `test/gh681-reviewer-probe-rules.sh` (pins the role_note sentence),
  `test/gh554-tick-unknown-flags.sh`.
- Final gate: `utils/ci-route.sh` classifies `relay-automation/relay-turn-lib.sh` and `src/scope.js` as
  kernel/gate surface → `route=full`, `tier=3`; run `bash ci-local.sh` exactly once on the final approved
  commit in a disposable full clone (`<folder>-gate`), identity checked before and after.
- Manual checks, all recorded under `TESTS-RESULTS/2026-10-24+GH-1020/` with commands, non-empty
  outputs, revision and provenance (GH-831: no suite, registry entry or gate added):
  1. **Guard, forced (edit 2 — falsifiable on its own):** in the disposable clone, with the reviewer
     owning a token, replay the retained command verbatim (`before-fix-codex-tick-commands.txt:3`):
     `tick release <task> --agent codex --to done`. Required: non-zero exit, a diagnostic naming `done`
     and the right verb, the `.tick/events` count unchanged, `tick info` still `claimed` by codex. Same
     for `--to Approved` and `--to Closed`. Controls: `--to claude-a` (peer) and a bare `release` with no
     `--to` still succeed and emit one `task.released` each. Then the shim's own closure path:
     `rtl_enforce` step 4 on a header `STATUS: Approved` runs `tick done` and the driver attests / exits 0.
     **Red control:** the same forced replay with the guard hunk reverted succeeds, prints `released:`,
     ownership is lost, and the shim's `tick done` fails — the before-fix state.
  2. **Prompt (edit 1), real model:** the same real Codex `--review-once` approval on the same trivial
     artifact as the before run (exit 4, `handoff-to: done` — the retained red control), now expected
     exit 0, token `done`, attested; the transcript must show no `release --to done`.
  3. **Adjacent path:** a non-approval review (`STATUS: Open`, `NEXT: Producer`) still hands off to the
     peer and exits 5.
  A passing run of check 2 alone does not discharge check 1: once the prompt is fixed the model may
  simply run `tick done`, which says nothing about the guard.

## Rating (2026-10-24)

`rated 85/82/50/80` — sev 82: an approving review is refused and the automated relay/marathon halts
until an operator repairs the token by hand; no data lost, recovery bounded (matches #763's 82).
pri 85: factory run 4 (#1081 successor) is blocked on it. Recurrence of *this* mode (approved review,
token released to `done`, close-mismatch): 5 in the last 14 days (2026-10-10..24)
(#1020 rows 1–3, Agy, 2026-10-10; #1020 second comment, Codex, 2026-10-10; #1081 Prerequisites,
2026-10-14) — #1020 row 4 (header left Open) and row 5 (retry fallout) are a different mode and are not
counted; 3 earlier incidents across 2026-09-23..28 (#763; 2026-09-24 `relay-system/2026-09-24/gh796-plan-qa.md:99`;
2026-09-28 `relay-system/2026-09-28/gh879-n5-final-qa-r2.md:63`, all Agy, each recovered with a fresh
token); plus one on-demand reproduction today with Codex. Same class on both observed reviewer seats
(Agy, Codex), rising.
appeal 50 neutral. effort 80: two small edits (one prompt string, one guard), no schema, no new state;
the cost is the tier-3 full gate the kernel surface requires.
