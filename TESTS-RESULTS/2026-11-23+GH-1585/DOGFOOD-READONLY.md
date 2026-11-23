# GH-1585 laser-focus: read-only dogfood on the motivating client repo (redacted)

The target is a **private** client repo, and this repository is public, so identifiers, quotes and
version numbers are replaced with placeholders. The verbatim receipt stays with the operator, not in
the repo. The run followed `skills/2-daily/laser-focus/SKILL.md` Steps 0–1b, plus a paper run of Steps
2–3. Steps 2–3 normally run only after the operator answers frame lock and the gate passes; that
answer is pending, so the paper run assumes the frame "T = vX.Y, strict freeze".

## Step 0 — repo identity
- `--repo` = the current checkout's origin (match), so local ledger readers were allowed.
- `gh auth status` succeeded.

## Step 1 — frame lock (the skill's first output)

| Source | State | Finding |
|---|---|---|
| Repo policy (`ROUTER.md`) | found | `releases.db` is the sole source of truth; `ROADMAP.md` is retired |
| Ledger `next` (the `cmd_next` SQL, run `sqlite3 -readonly`) | stale | 7 `active` rows, all undated. Sorted first is a row with an **empty version**, then six older versions. No row for the team's working target |
| Ledger rows matching the working target | absent | 0 |
| Open milestones | conflicting | 1, unrelated to the target |
| Tags for the target | absent | none |
| Branches | found | 2 remote branches named for `vX.Y` and `vX.Y.1` |
| Open issues | found / conflicting | 5 issues titled with `vX.Y`. One feature issue titles its journey "the `vX.Y.1` handoff" while sibling issues say "`vX.Y` item N" |

Questions emitted, after which the run **stopped** (no triage, no writes):
- **Q1:** "Is `vX.Y` the overall goal, or `vX.Y.1`? Canonical ledger spelling (`X.Y.0`)? Any hard deadline or launch gate?"
- **Q2:** "Swaps allowed, or strict freeze except blockers and clarifications?"
- **Scope source:** "Where is `vX.Y`'s scope defined? No ledger manifest exists; candidates are the 5 `vX.Y` issues."

## Step 1b — ledger gate (evaluated for the hypothetical frame "T = X.Y.0")
- **Alignment gap:** `X.Y.0` is absent. The route is `/releases plan X.Y.0`, with the operator's tracker as the tracking issue.
- **Rows ahead in `next`:** 7 `active` rows. They are listed but not yet flagged; flagging needs per-row evidence (a CHANGELOG ship entry, or an operator statement), gathered after Q1.
- **Data-quality note:** the empty-version `active` row sorts first in `next`, so a naive read reports a target with no name.
- **Gate result: NOT MET.** The run stops before triage, as designed.
- `releases.db` sha256 was identical before and after (see `provenance.jsonl`).

## Steps 2–3 — paper classification (hypothetical frame; not run against a passed gate)

| id (redacted) | Statement (paraphrase) | Decision state | Code → bucket | claimed_severity | Note |
|---|---|---|---|---|---|
| prA-ic1-s1 | PO: keep PR-A to the sidebar change only, for launch | decided | `A4` → 1 | none | Implementation: PR open and ready for review, not merged, so it is not "done" |
| prA-ic1-s2 | PO: use the newer Overview from PR-G | decided | `A4` → 1 | none | PR-G is open, not merged |
| prA-ic1-s3 | PO: describes the View idea → Create campaign → prefilled Content journey | decided | `R0` | none | Restates issue-H's recorded scope. Issue-H calls it the `vX.Y.1` handoff, which feeds Q1 |
| prB-ic2-s1 | PO: send variant A for all three emails as they stand | decided | `A4` → 1 | none | The pick is preserved |
| prB-ic2-s2 | PO: prefers B's design for one email; wants the sale name, an offer sentence, discount %, coupon code and a button above the fold | decided | `D1` → 2 (strict) / `C3` → 4 (swaps) | none | Matches the operator's expected placement: new layout recipe → next point release |
| prB-ic3 | Teammate (not the product decider), non-blind: prefers B for a different email than the PO picked | n/a: a dissent, not a decision | no row matches → `C1` → 4 | none | The table's fallback surfaces it to the decider as a question. Nothing changes. Flagged non-blind |
| prB-ic0 | Teammate, earlier: one email "not ready, recipe being reworked" | superseded | `R0` | not ready | A later authorized decision ("send as they stand") wins |

Worked examples (from the skill text, run on paper): `A4` / `D1`·`C3`·`P1` / `C1` / `C4`. All match the skill.

**Findings from this dogfood:**
1. The frame lock surfaced a real target ambiguity (`vX.Y` vs. `vX.Y.1`) that no single source resolves. This is the case the mandatory first question exists for.
2. A non-decider's dissent from a recorded decision has no explicit row. It reaches `C1` through the "nothing falls through" rule, which gives the right outcome (ask the decider; change nothing), but naming the case in `C1` would make it explicit.
3. `releases next` would name an empty-version row. This supports "scheduling evidence only".
