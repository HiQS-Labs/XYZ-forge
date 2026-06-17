# RELAY · AGENTS.md — BigQuery usage governance QA
<!--
  Single source of truth for this two-agent relay.
  Read this ENTIRE file before doing anything. Act only on your turn.
-->

NEXT: Reviewer (optional confirm pass — operator closed in-thread)
STATUS: Closed — operator-directed (5 Should fixes applied; 2 Nits declined)
ROUND: 2 / 2

## ▶ TAKE YOUR TURN — read this first (works for ANY agent: Claude, Codex, Gemini)
The operator just said "take your turn on this file." Everything you need is **in this file** — don't wait for pasted instructions.
1. **Read this whole file** (header, Setup, Ground rules, every turn in the Log).
2. **Check it's your turn:** `NEXT` (top) names the role to act. Confirm you are the agent bound to it (see Setup) **and** the last Log block isn't already yours. If not → STOP and reply "wrong window — nudge the <other> window."
3. **Do your role's work** on the artifact named in Setup (read the real files / the latest `git show <last commit>` diff; cite `file:line`):
   - **Reviewer:** review vs the Definition of Done → graded findings (`[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`), each with a concrete proposed fix → set a **Verdict** (Approved | Changes requested | Blocked). Do **not** edit the artifact; you only append findings here.
   - **Producer:** for every open finding log a disposition (Implemented / Modified / Declined + why), make the change, then add new work.
4. **Append ONE block** at the very bottom, directly **above** the marker line (`<!-- ↓↓↓ NEXT TURN ... -->`). Never edit earlier turns. Header it `### Round N · <Role> · <your-label> · <date time>`; a Reviewer block carries `**Verdict:**` + `**Findings & proposals:**` (graded bullets) + `**Commit:**`; a Producer block carries `**Decisions on proposals:**` + `**Did:**` + `**Re-review this:**` + `**Commit:**`. (Need the exact shape? Mirror the most recent block of the other role above.)
5. **Update the header:** flip `NEXT` to the other role; set `STATUS` (`Approved` closes the relay — Reviewer only; else leave `Open`); the Producer bumps `ROUND` when opening a new cycle.
6. **Commit only the files you touched** (artifact + this log): `git commit -m "relay(<slug>): <your-label> r<N>"`, then put the short hash in your block's `Commit:` line and `git commit --amend --no-edit`. Push if the team shares a remote.
7. **Stop.** Tell the operator your one-line result (e.g. "Changes requested, 1 Blocker — Producer's turn").

## Setup
- Artifact under review: `AGENTS.md` — **BigQuery usage governance only**, four blocks:
  - §31–50 — "BigQuery imports & syncs — follow the gold-standard SOP first (⭐ MANDATORY)"
  - §52–64 — "BigQuery query & cost governance (⭐ MANDATORY)" (the 10 numbered cost/perf rules)
  - §419–484 — "Compute venue pre-flight" + "Rejected reasoning" + "Plan doc inheritance"
  - §486–560 — "Heavy batch / one-time computations" Rules 1–3 (compute-locally, restart-safe, progress-visible)
- Definition of Done: **The BigQuery governance is technically correct (no false cost/perf claims about BigQuery's on-demand model), internally consistent (no rule contradicts another or the data-architecture section), and complete enough to act as authoritative guardrails — an agent following it would neither incur a surprise cost nor be blocked from a legitimately cheap query. Flag any claim that is outdated, oversimplified to the point of being wrong, or that an engineer could weaponize into a bad decision.**
- Producer: Claude (Opus 4.8) — owner of AGENTS.md   ·   Reviewer: Gemini (headless via `gemini-cli`)
- Handoff: manual nudge (Reviewer turn driven headless via `npx @google/gemini-cli`, operator-relayed)
- Scope: operator wants a SINGLE return-trip QA pass — **Reviewer QA → Producer disposition** (max ROUND 2). High-signal findings only; this is a doc, so verdicts are `textual only` / `N/A — non-executable artifact`.
- Started: 2026-06-16

## Ground rules
1. This file is the single source of truth. If it isn't written here, assume the other agent doesn't know it. The two agents may be different tools (e.g. Claude and Gemini) and never share memory.
2. Read the whole file. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Then update `NEXT`, `STATUS`, `ROUND` at the top. (Only exception: right after committing, fill the hash into your own just-written turn's `Commit:` line.)
4. Stay tight. Requests and findings are bullets, not essays.
5. **The Reviewer never edits the artifact.** It proposes graded findings, each with a concrete suggested fix where possible. The Producer (the original author), with the operator, decides each proposal and implements the approved ones — logging a disposition (Implemented / Modified / Declined + reason) for every one.
6. Grade every finding:  `[Blocker]` must fix to ship · `[Should]` strong recommendation · `[Nit]` optional · `[Pass]` checked and sound (records what was verified, not assumed). Answer the Producer's "Re-review this" questions in an `Answers:` block.
7. The Reviewer posts a Verdict every turn. The relay ends on **Approved** — so to get proposals actioned in-thread the Reviewer sets `Changes requested`, not `Approved`; a `[Nit]` left on an `Approved` verdict is the author's discretion, handled out-of-band. If the max `ROUND` ends without `Approved`, set `STATUS: Escalated` and hand back to the human.
8. End your turn by committing it: `relay(agents-md-bq-governance): <role> r<N>`, then fill the hash into your `Commit:` line. If your turn touched no tracked files (comments-only), write `Commit: none (comments only)`.
9. **One window at a time, clean tree at every handoff.** Both agents share one working tree; the `NEXT` pointer is honor-system. Never start a turn while the other window may still be editing, and never flip `NEXT` with uncommitted changes left in the tree — commit or stash first.
10. **Evidence contract — state your proof every turn.** The Producer logs a one-line `Verification:`; the Reviewer logs a verdict `Basis:` — `behaviorally proven` (ran/observed) or `textual only` (read, not run). For this doc, BigQuery cost/perf claims can only be checked `textual only` against known BigQuery semantics — say so honestly.

## Roles
- **Producer** — the only writer of the artifact: builds it, requests review, decides and implements proposals (with the operator), updates.
- **Reviewer** — reviews against the DoD, proposes graded findings with suggested fixes, sets a verdict. Never edits the artifact.

## Context for the Reviewer (read before reviewing)

You are QA-ing the **BigQuery governance** of `AGENTS.md` — the guardrails that tell AI agents how to use Google BigQuery safely and cheaply for this multi-tenant Shopify-LTV SaaS. Background you need:

- BigQuery here is **read-only at app runtime** (one thin wrapper around the Binoid reference model) but is also **the default compute venue for ad-hoc heavy historical analytics** over data already mirrored there. Postgres on a single GCE VM is the primary OLTP/app-serving store.
- The cost rules exist because a 2026-05-27 incident ("Open CDP Phase 4") had agents reach for a multi-GB `pg_restore` + local Postgres path for an analytical cross-join that BigQuery would have run in minutes — the venue pre-flight (§419) is the fix.
- BigQuery bills **on-demand by bytes scanned** (columnar; partition/cluster pruning reduces scan; `LIMIT` does not).

**Scrutiny points (Producer's asks):**
1. **Technical correctness of the 10 cost rules (§52–64).** Is any claim wrong or misleading on today's BigQuery? Specifically: Rule 5 ("largest table first in JOINs") — is that still accurate guidance given BigQuery's cost-based optimizer, or is it stale folklore? Rule 2 (`LIMIT` doesn't save money) — correct, but does it need the "unless clustered / preview / metadata" nuances? Rule 6 (`APPROX_COUNT_DISTINCT`) — "exponentially faster" accurate or overstated?
2. **Gaps.** What governance is *missing* that would cause a surprise bill? (e.g. no mention of partition/cluster as the primary scan-reduction lever beyond Rule 2's aside; no `maximum_bytes_billed` / dry-run guidance; no mention of clustering, materialized views, BI Engine, query result caching, or per-project cost controls/quotas.)
3. **Internal consistency.** Does the cost governance (§52) contradict the data-architecture "Postgres is primary" framing or the venue pre-flight (§419)? Does Rule 10 ("check the validator / note scan estimate") have a concrete mechanism, or is it aspirational with no `--dry-run` instruction?
4. **Actionability.** Could an agent follow these and still get blocked from a cheap query, or be pushed toward an expensive one? Is anything so simplified it's wrong (e.g. "never SELECT *" with no carve-out for already-pruned small tables)?

Cite `AGENTS.md:<line>` for every finding. This is a non-executable doc — your Basis will be `textual only` against known BigQuery semantics; flag anything you can't verify as such.

---
## Log

### Round 1 · Producer · Claude (Opus 4.8) · 2026-06-16
**Did:** Scaffolded this relay to QA the BigQuery usage governance in `AGENTS.md`. Scoped the review to the four BQ governance blocks (import SOP §31, the 10 cost rules §52, the venue pre-flight §419, and the heavy-batch Rules 1–3 §486) and wrote the Definition of Done + scrutiny points above. No edits made to `AGENTS.md` yet — this round only frames the review.
**Review this:** The four scrutiny points in the Context block — above all (1) whether any of the 10 cost rules (§52–64) is technically wrong on today's BigQuery, and (2) what cost-control governance is *missing* (partition/cluster as primary lever, `maximum_bytes_billed`, dry-run, result caching, project quotas).
**Verification:** N/A — non-executable artifact (Markdown governance doc). All findings are `textual only` against known BigQuery semantics.
**Open questions:** Is Rule 5 ("largest table first in JOINs") sound modern guidance or stale folklore that should be softened/removed? Is the §52 block missing a hard `maximum_bytes_billed` guardrail that would make the "never a surprise bill" promise real?
**Commit:** 6c90552

### Round 1 · Reviewer · Gemini (headless) · 2026-06-16
**Verdict:** Changes requested
**Basis:** textual only (read AGENTS.md against known BigQuery on-demand semantics; nothing executed)
**Findings & proposals:**
- [Should] AGENTS.md:63 — Rule 5 ("Join order matters") is stale folklore. Modern BigQuery uses a Cost-Based Optimizer (CBO) and dynamic execution planning (Dremel engine) that automatically reorders joins and designates broadcast sides based on table statistics, regardless of syntactic query order. Proposed fix: Replace Rule 5 with: `5. **Join order is auto-optimized**: BigQuery's modern Cost-Based Optimizer dynamically plans broadcast and hash joins. Do not worry about syntactic table order (largest first); instead, focus on pre-filtering join keys, avoiding CROSS JOINs, and matching partition/cluster filters in join conditions.`
- [Should] AGENTS.md:65 — Rule 6 states `APPROX_COUNT_DISTINCT()` is "cheaper". While it is cheaper in terms of slot-seconds/CPU footprint, under on-demand billing, BigQuery bills strictly by bytes scanned. Since both functions scan the exact same columnar bytes, the on-demand cost is identical. Calling it "exponentially cheaper" is technically wrong and misleading for cost tracking. Proposed fix: Replace Rule 6 with: `6. **Prefer approximate aggregations for performance**: Use APPROX_COUNT_DISTINCT() instead of COUNT(DISTINCT) on large datasets. While both scan the same column data and cost the same under on-demand billing, approximate functions utilize fewer slot-seconds and prevent 'Resources exceeded' errors on massive tables.`
- [Should] AGENTS.md:70 — Rule 10 ("Check the validator") is purely aspirational for programmatic agents. An automated script or CLI agent cannot visually inspect the console's query validator. It needs a programmatic mechanism to prevent runaway scans. Proposed fix: Expand Rule 10 to mandate programmatic dry-runs: `10. **Validate scan volume programmatically**: For interactive queries, check the console's query validator estimate. For automated scripts or AI agents, always execute a dry-run first (e.g., setting dry_run=True in the Python SDK's QueryJobConfig or using --dry-run in the bq CLI) to inspect total_bytes_processed. Abort execution if the estimate exceeds safe thresholds.`
- [Should] AGENTS.md:52 — Missing partition/cluster pruning as the primary cost reduction mechanism. The 10 rules mention partitions only as an aside in Rule 2, but do not establish partition/cluster key filtering in the `WHERE` clause as the absolute primary lever for reducing billed bytes. Proposed fix: Add a new Rule 2b: `2b. **Mandate Partition & Cluster Filters**: When querying large partitioned or clustered tables, you must include the partition/cluster key in your WHERE clause (e.g., WHERE event_date >= CURRENT_DATE() - 7). This is the primary mechanism to prune blocks and reduce billed bytes scanned.`
- [Should] AGENTS.md:52 — Missing a hard maximum bytes billed guardrail. There is no directive to use BQ's `maximum_bytes_billed` config. If an agent executes a poorly optimized query, there is no system guardrail preventing an expensive bill. Proposed fix: Add a new Rule 11: `11. **Set maximum bytes billed safety limits**: When executing queries programmatically, always set the maximum_bytes_billed parameter (e.g., via QueryJobConfig.maximum_bytes_billed or the CLI flag --max_bytes_billed) to a safe threshold (e.g., 10 GB) to automatically abort run-away scans before they incur costs.`
- [Nit] AGENTS.md:56 — Rule 1's "Never use `SELECT *`" is too rigid. For small tables (<10 MB, e.g. reference data or tenant configs), `SELECT *` has negligible cost and is cleaner to write. Proposed fix: Add a carve-out: `1. **Never use SELECT * on large tables**: Always explicitly select only the columns you need. SELECT * scans the entire table across all columns, maximizing cost. (Exception: tiny metadata, lookup, or reference tables under 10 MB are acceptable if needed).`
- [Nit] AGENTS.md:52 — Missing query result cache preservation rules. BigQuery caches results for 24 hours at zero cost, but using non-deterministic SQL functions (e.g. `CURRENT_TIMESTAMP()`, `RAND()`) invalidates it. Proposed fix: Add a rule: `12. **Preserve query cache**: BigQuery caches duplicate queries for 24 hours at zero cost. Avoid using non-deterministic SQL functions directly in your queries if you can compute them externally and pass them as literals to preserve cache hits.`
- [Pass] AGENTS.md:31-50 — Checked the mandatory import and sync gold-standard SOP. The workflow is robustly designed to introduce deliberate friction (requiring a checklist based on `utils/wp-bq/IMPORT-TEMPLATE.md` at `temp/<site>/imports/<SITE>-IMPORT-YYYY-MM-DD.md`) before any irreversible production write, protecting MySQL-to-BQ migration flows.
- [Pass] AGENTS.md:419-484 — Evaluated the "Compute venue pre-flight" and "Rejected reasoning" sections. They are highly actionable, completely consistent with the Postgres primary/BQ analytical division, and directly address the structural pitfalls from the Open CDP Phase 4 incident.
- [Pass] AGENTS.md:486-560 — Verified the Heavy Batch / One-time Computations Rules 1-3. The guidelines are operationally sound, and the chunked/rate-reported Python template in Rule 3 provides an outstanding reference implementation for progress visibility.

**Answers:**
- Rule 5 largest-table-first: sound modern guidance or stale folklore? → Stale folklore. Modern BigQuery uses a Cost-Based Optimizer (CBO) and dynamic execution planning (Dremel engine) that automatically designates build and probe inputs for broadcast and hash joins based on actual statistics, regardless of syntactic join order. Forcing agents or engineers to strictly place the largest table first is unnecessary and technically outdated.
- Is the cost block missing a hard maximum_bytes_billed guardrail? → Yes. Under BigQuery's on-demand model, bytes scanned translates directly to dollars. An un-optimized or buggy query can run up a massive bill instantly. Setting a hard `maximum_bytes_billed` (or programmatic `max_bytes_billed` in SDK / `--max_bytes_billed` in CLI) is the only true physical guardrail to prevent a runaway query from billing the company, and is currently completely omitted from §52-64.

**Commit:** none (comments only)

### Round 2 · Producer · Claude (Opus 4.8) · 2026-06-16
Verified every Gemini finding against BigQuery's on-demand semantics before disposing of it; its line cites were a few lines low (it flagged the right *rules* by content). Operator directed: apply the 5 `[Should]`, decline the 2 `[Nit]`.
**Decisions on proposals:**
- [Should] Rule 5 join-order folklore (@ AGENTS.md:60, Gemini cited :63) — **Implemented** → rewrote as Rule 6 "Join order is auto-optimized — don't hand-order tables"; removed the "largest table first" advice, redirected to pre-filtering join keys / no `CROSS JOIN` / partition filters in join conditions. · Proof: textual only (correct — BQ's cost-based optimizer reorders joins; syntactic order is not a cost lever).
- [Should] Rule 6 `APPROX_COUNT_DISTINCT` false cost claim (@ AGENTS.md:61, Gemini cited :65) — **Implemented** → rewrote as Rule 7 "Approximate aggregations save slots, not on-demand dollars"; states both forms scan identical bytes → identical on-demand cost, and to not cite it as a cost saving. · Proof: textual only (correct and the highest-value correctness fix — it was a false claim inside a cost doc).
- [Should] Rule 10 validator aspirational for agents (@ AGENTS.md:65, Gemini cited :70) — **Implemented** → expanded as Rule 11 "Validate scan volume programmatically before running"; mandates `dry_run=True` (Python SDK) / `bq query --dry-run` and reading `total_bytes_processed` for non-interactive callers. · Proof: textual only.
- [Should] Partition/cluster not established as primary lever (@ AGENTS.md:52) — **Implemented** → added as new Rule 3 "Filter on partition & cluster keys — this is the primary lever," stating it reduces billed bytes more than any other rule. · Proof: textual only (correct — block pruning is the dominant scan-reduction mechanism).
- [Should] No `maximum_bytes_billed` guardrail (@ AGENTS.md:52) — **Modified** → added as new Rule 12; kept Gemini's intent but **corrected the `bq` CLI flag** from its proposed `--max_bytes_billed` to the real flag `--maximum_bytes_billed`, and dropped the hardcoded "10 GB" example (threshold is workload-specific). · Proof: textual only.
- [Nit] Rule 1 `SELECT *` carve-out for <10 MB tables — **Declined** → a blanket "never `SELECT *`" is a stronger, harder-to-misread guardrail in an agent-facing doc; the marginal savings on tiny tables don't justify softening the rule into a judgment call agents will over-apply.
- [Nit] Query-cache-preservation rule — **Declined** → real but low-frequency for this app's batch-analytics usage; would add a 13th rule for a niche case. Deferred (noted here for the record).
**Did:** Rewrote the §52 cost-governance numbered list from 10 → 12 rules incorporating the 5 accepted fixes; renumbered cleanly. No other AGENTS.md section touched (import SOP, venue pre-flight, heavy-batch Rules 1–3 were all `[Pass]`).
**Verification:** N/A — non-executable artifact (Markdown). All dispositions are `textual only` against known BigQuery semantics. `git diff AGENTS.md` shows the single §52 hunk (the section was an uncommitted working-tree addition being QA'd pre-landing).
**Re-review this:** (optional confirm pass) new Rules 3, 6, 7, 11, 12 in §52–66. Whether Rule 7's slots-vs-dollars distinction and Rule 12's flag (`--maximum_bytes_billed`) read correctly.
**Commit:** 9ba7f21

<!-- ↓↓↓  NEXT TURN GOES ABOVE THIS LINE — keep this marker last  ↓↓↓ -->
