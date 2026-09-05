# RELAY · QA: Model-catalog plan (PROJECT.md) — canonical catalog for XYZ-forge + AEGIS-Sleuth resolvers
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-09-05.
-->

NEXT: Producer
STATUS: Open
ROUND: 1 / 4

## ▶ TAKE YOUR TURN — read this first (works for ANY agent: Claude, Codex, agy)
1. **Read this whole file** (header, Setup, Ground rules, every block in the Log).
2. **Check it's your turn:** `NEXT` (top) names the role to act. Confirm you are bound to it and the
   last Log block isn't already yours. If not → STOP and reply "wrong window — nudge the <other> window."
3. **Do your role's work** on the artifact named in Setup:
   - **Reviewer:** review vs the Definition of Done → graded findings
     (`[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`), each with a concrete fix → set a **Verdict**
     (Approved | Changes requested | Blocked). **Review the whole file, not just the diff** (GH-268):
     a beta test had this loop reach `Approved` in two rounds while an independent audit of the same
     branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the
     change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN
     SCOPE; if you find none, say so explicitly rather than leaving it unstated.
     **Declare it: every review block must contain a literal `swept file: yes` or `swept file: no`
     line.** Without it a reviewer that skipped the sweep is indistinguishable in the transcript from
     one that did it and found nothing — which is how the original 20 issues stayed invisible.
     Any `[Pass]` or "verified"/"confirmed" finding MUST
     carry a quoted span or a `file:line` citation — an uncited one is mechanically downgraded to
     `[Unverified — no citation]` (GH-173 B3). Do **not** edit the artifact; only append findings here.
   - **Producer:** log a disposition for every open finding (Implemented / Modified / Declined + why),
     make the change, then add new work.
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(model-catalog-plan-qa-agy): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **.relay-artifacts/PROJECT.md** — the read-only path that
  `relay-drive.sh --artifact-file /Users/noelsaw/Documents/GH Repos/Model-catalog/PROJECT.md` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: agy   ·   Producer: claude-a
- Started: 2026-09-05
- Definition of Done: the plan is executable as written by an agent in each consumer repo with no
  further design decisions; every risky claim carries its source; the data model supports both
  consumers' matching semantics; no secrets-surface exists in the design.

Adjudicate the plan in **.relay-artifacts/PROJECT.md** (Model-catalog repo, issue #1). Context: it
merges XYZ-forge's 7-row OpenRouter alias table (`relay-automation/openrouter-model-aliases.yml`,
GH-120/GH-346) and AEGIS-Sleuth's 53-row `ModelAliases` pins (`data/static/ai/command-normalization.json`,
GH-168) into one versioned data-only repo. Deliberately NOT a service/gateway.

Questions (answer each, cite the plan section):

1. Schema: does the `target` field (`native` | `openrouter`) cleanly separate the two consumers, or
   will a colloquial name that exists in both ID spaces (e.g. `deepseek v4 pro`) force a v2 schema
   change? Is the `(match, target)` uniqueness rule sufficient given XYZ folds punctuation but
   Sleuth does not?
2. Consumer contract: any gap that would let a consumer reintroduce substring substitution, a
   default-on-miss, or a runtime network call? Is "exact IDs always win" actually guaranteed by the
   data (no exact ID declared as a key) — check Sleuth's 53 rows for a key that IS an exact ID.
3. Provenance: backfilling Sleuth's `verified_on` from the GH-168 Rev 4 date (2026-09-04) while
   XYZ's rows stay `null` — honest, or false precision? What would you change?
4. Phases 1–2: is the XYZ seam real (caller-supplied-table support, commit `c5831ff3`)? Name any
   step in Phase 1 or Phase 2 that would break the frozen-twin/GH-551 rules, the vendored `.xyz/`
   lifecycle, or the refusal contract's negative control.
5. Risks the plan misses: public-repo hazards beyond secrets (license? import cost? row contribution
   flow?), governance (who arbitrates a pin both repos disagree on), and failure modes when the two
   source tables disagree on the same colloquial name.
6. Anything over- or under-engineered for a data-only repo's first commit?

Output: graded findings (`[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`) with concrete fixes, then a
Verdict. Do not edit the artifact.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

## Reviewer (agy) — 2026-09-05

swept file: yes

### Findings vs Questions

*   **[Blocker] Schema (Q1):** The `(match, target)` uniqueness rule is insufficient because XYZ folds punctuation. Two distinct JSON rows (e.g., `deepseek v4` and `deepseek-v4`) will collide at consumer time in XYZ.
    *   *Fix:* Add a CI validation rule asserting `(normalize(match), target)` is unique, not just the raw string.
*   **[Blocker] Consumer contract (Q2):** The rule "Exact IDs always win" contradicts the "Refusal on unknown" contract. Since Sleuth's 53 rows do not declare exact IDs (like `gpt-4o`) as keys, an exact ID input yields "no row hit" and will be refused by the resolver, not passed through.
    *   *Fix:* Add exact IDs as identity rows (`match: "gpt-4o", replace: "gpt-4o"`) or amend the contract so consumers bypass the lookup for exact IDs.
*   **[Nit] Provenance (Q3):** Claiming `2026-09-04` for the `gemini pro` row is false precision because it is known to be stale.
    *   *Fix:* Set `verified_on: null` for any row with the `unverified-generation` flag.
*   **[Pass] Phases 1-2 Seam (Q4):** The caller-supplied table seam in XYZ-forge is real and verified; commit `c5831ff3` correctly exposes `MODEL_ALIASES_FILE` for overriding the lookup table (cited: `Phase 1 — XYZ-forge consumes` step 2).
*   **[Blocker] Phases 1-2 GH-551 (Q4):** Phase 1 Step 2 says to repoint `resolve-model-alias.sh` at `data/catalog.json`. This script is a frozen Bash twin expecting `alias: slug` format. Parsing JSON in Bash violates the GH-551 "no-new-Bash" rule.
    *   *Fix:* Phase 1 must compile `catalog.json` into the legacy `.yml` format at vendoring time, leaving the Bash script untouched.
*   **[Should] Missed risks (Q5):** The plan misses governance (who wins if a name like `chatgpt` is disputed?) and the 2-PR friction of adding a row.
    *   *Fix:* Add a governance tie-breaker rule and acknowledge the cross-repo contribution cost.
*   **[Nit] Over-engineering (Q6):** Phase 1 Step 3 generates test assertions dynamically from the catalog. This makes the test a tautology and requires parsing JSON in `test/model-alias.sh`.
    *   *Fix:* Keep `test/model-alias.sh` with explicit hardcoded assertions.

### Verdict
**Verdict:** Changes requested.

handing off to Producer — go to the claude-a window and say 'take your turn'

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
