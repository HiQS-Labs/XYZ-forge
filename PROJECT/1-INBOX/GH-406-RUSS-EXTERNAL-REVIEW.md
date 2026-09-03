---
title: External review (Russ K.) — eight findings on guards narrower than their documented guarantee
status: Proposed (1-INBOX — not yet active)
created: 2026-09-03
owner: noelsaw1
gh_issue: 406
source: https://github.com/HiQS-Labs/XYZ-forge/issues/406
doc_type: audit
complexity: 3
risk: 3
effort: 4
phases: 3
ratings_provisional: true
non_goals:
  - Re-litigating the architectural comparison (turn-as-unit vs card-as-unit) — a difference of bet, not a defect.
  - Building a semantic comment-vs-code drift detector; R5 resolves path references only.
  - Making `.tick/` git-tracked. Coordination provenance not surviving the run is a deliberate trade.
related:
  - GH-396 (harness root resolution — sequence R2 after it lands)
  - GH-21 (validate-relay-block Phase 1 — R1 completes its driven-path wiring)
  - GH-12 (foreign-cwd foot-gun — R2 is the same shape on an exempt verb)
goal: >
  Close the class of defect where a document states a guarantee and the mechanism covers a
  narrower path than the sentence implies. Five of the eight external findings are that same
  §13 anti-pattern — a check that cannot falsify its claim because it never runs on the path
  it is supposed to govern. Land R1-R6 each with a witnessed red control.
---

# GH-406: External review (Russ K.) — guards narrower than their documented guarantee

> **1-INBOX capture**, not an active-work doc — no `## Status` table yet. On promotion to
> `PROJECT/2-WORKING/`, create the status table and outline execution phases.

## Provenance

External technical review by **Russ K.**, received 2026-09-02, read against branch `development`
@ `0f62aa4a`. Agent-generated under his direction: two parallel readers under a Claude (Fable 5)
evaluator, then an adversarial Codex (gpt-5.6-terra) pass that returned REVISE and corrected four
items. Evidence grades E1 (ran it) / E2 (read the code) — nothing E3.

Verbatim text is preserved in the issue body and in `PROJECT/1-INBOX/RUSS-TRIAGE.md`.

## Verification

Re-checked against HEAD `e58f339f` on 2026-09-03 before ranking. **All eight findings still
reproduce. None fixed by any merged PR or commit since.** Full evidence table in the triage
comment on the issue.

**GH-408 exists and shipped.** An earlier draft of this doc claimed it did not; that claim was
wrong and is retracted. It is [upstream #408](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/408),
closed COMPLETED 2026-08-12 under 0.3.0 Nightwatch, and its fix is at HEAD
(`marathon_drive.py:479`, `bin/tick:182`, `test/gh408-tick-failure-visibility.sh` 22/0,
`test/baselines/GH-408-negative-control.md` 12 red pre-fix). The false negative came from a
`grep --include=…` invocation that this toolchain routes to ripgrep, which rejects the flag and
prints `0 matches` — a search that never ran, rendered as a clean result. Use
`git grep -nE 'GH-40[789]'`. Recorded rather than quietly fixed because it is this issue's own
defect: an absence asserted from a tool that could not have reported a presence.

**R3 survives with a sharper cause.** GH-408 did not overlook the transient case — it deliberately
*unified* the lost-claim exits, correctly, for three causes that are all durable. `src/lock.js`'s
`EEXIST` (a transient O_EXCL collision) was never in that set, yet `bin/tick:463-465` maps it to 1
alongside them. So 3.1 is a follow-up to shipped work, not a gap in unallocated work.

## The organising finding

Five of eight are one defect wearing five hats: a guarantee is written in prose, a mechanism is
built covering a narrower path, and nothing compares the two. That is this repo's own §13
anti-pattern. The highest-value work is closing the class, not fixing eight bugs.

## Ranked remediation

| R | Finding | Impact | Effort | Core fix |
|---|---|---|---|---|
| R1 | 1.2 — `validate-relay-block` off the headless path | highest | low | Pass `--relay-file` from `rtl_enforce`; escalate on exit 8 |
| R2 | 1.3 — `tick log` outside the foreign-cwd guard | high | very low | Guard on verb **+ event-type prefix**: `task.*` guarded, `cost.*` best-effort |
| R3 | 3.1 — transient lock == durable loss | high | low | Typed `EEXIST` → exit `75`/`EX_TEMPFAIL`; `rtl.py` retries; `--json` result line per verb |
| R4 | 1.1 — marker authorises destructive rebuild | irreversible | minutes | Delete `.xyz-launch-artifact`; refuse >1-commit destination without `--discard-history` |
| R5 | *new* — nothing checks inline comment references | compounding | low | PDDA check: extract path-shaped refs from comments, assert targets exist, run on **both** trees; then add both ADRs to `KEEP_FILES` |
| R6 | 1.4 — guard hook covers 6 of 11+ entrypoints | medium | very low | Glob `relay-automation/*-turn.sh` + the three Python drivers; enumerate-entrypoints test |
| R7 | 1.6 / 3.2 / dead `GH-<n>` refs | low | trivial | One batched docs PR — **the `GH-<n>` half is DONE**, see below |

### R7 partial — upstream numbering resolved (2026-09-03)

Russ K.'s 3.1 second half ("a read-only archive, or a one-line note in the ROUTER saying where
those numbers live") is closed:

- [`docs/ROADMAP-UPSTREAM-ARCHIVE.md`](../../docs/ROADMAP-UPSTREAM-ARCHIVE.md) already existed as
  that archive but was referenced from nothing — a cold reader never found it. `ROUTER.md` →
  "Canonical rules" now carries the pointer and states the two-repo numbering rule.
- Upstream numbers cited from *shipped code* are now mirrored as closed `[upstream archive]`
  issues so the citation resolves locally without editing the comment:
  [#407](https://github.com/HiQS-Labs/XYZ-forge/issues/407) and
  [#408](https://github.com/HiQS-Labs/XYZ-forge/issues/408), deliberately number-aligned with
  upstream. Zero code edits were needed as a result.
- The archive doc records the mirror list and the rule for extending it.

Still open under R7: §7 vs `package.json` (1.6), `PROJECT/4-MISC/` `.gitkeep`s (1.6), and
`CODEX_FLAGS` (3.2).

R1, R2, R3 and R6 ship **with a witnessed red control** or they do not ship — four of the eight
findings exist precisely because a check was written and never proven capable of failing.

## Sequencing note

R2 sequences **after GH-396** so it is written against the final root resolver. GH-396 covers
*where* the root resolves; R2 covers *which verbs may act on an inferred one*. Adjacent, not
duplicate.

## Kept as-is (not work items)

Kernel behaviour verified at E1 by the reviewer (11/11 unit tests, overlap rejection,
reap-then-reclaim epoch raise, zombie verb refusal, stale-event fencing with an audit row, O_EXCL
claim serialisation), projection as a pure function of the event set, the containment layering in
`relay-turn-lib.sh`, the outcome taxonomy, the uncited-`[Pass]` downgrade, and `DO-NOT-BUILD.md`.
