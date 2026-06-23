# RELAY · PDDA feedback-synthesis plan — design review
<!--
  Single source of truth for this two-agent relay.
  Read this ENTIRE file before doing anything. Act only on your turn.
-->

NEXT: Reviewer
STATUS: Open
ROUND: 2 / 3

## ▶ TAKE YOUR TURN — read this first (works for ANY agent: Claude, Codex, agy)
The operator just said "take your turn on this file." Everything you need is **in this file** — don't wait for pasted instructions.
1. **Read this whole file** (header, Setup, Ground rules, every turn in the Log).
2. **Check it's your turn:** `NEXT` (top) names the role to act. Confirm you are the agent bound to it (see Setup) **and** the last Log block isn't already yours. If not → STOP and reply "wrong window — nudge the <other> window."
3. **Do your role's work** on the artifact named in Setup (READ the real files listed; cite `file:line`):
   - **Reviewer (agy):** review vs the Definition of Done → graded findings (`[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`), each with a concrete proposed fix → set a **Verdict** (Approved | Changes requested | Blocked). Do **not** edit the artifact; you only append findings to THIS relay file.
   - **Producer (claude-a):** for every open finding log a disposition (Implemented / Modified / Declined + why), make the change on the artifact, then add new work / re-review asks.
4. **Append ONE block** at the very bottom, directly **above** the marker line (`<!-- ↓↓↓ NEXT TURN ... -->`). Never edit earlier turns. Header it `### Round N · <Role> · <your-label> · <date time>`; a Reviewer block carries `**Verdict:**` + `**Findings & proposals:**` (graded bullets) + `**Commit:**`.
5. **Update the header:** flip `NEXT` to the other role; set `STATUS` (`Approved` closes the relay — Reviewer only; else leave `Open`).
6. **Commit only the files you touched** (this relay log; the Producer also commits the artifact): `git commit -m "relay(pdda-feedback-synthesis): <your-label> r<N>"`, then put the short hash in your block's `Commit:` line. Do **not** push.
7. **Stop.** Tell the operator your one-line result.

## Setup
- Artifact under review — Noel's **PDDA feedback-synthesis plan**, a proposal-stage planning doc (not code) that reduces three June 23 external feedback notes into one actionable PDDA direction-setting plan. READ all of:
  - **The artifact:** `PROJECT/1-INBOX/PDDA/PDDA-FEEDBACK-SYNTHESIS-PLAN.md` (the synthesis: decision summary, keep/avoid lists, 5 phases each with a checklist + per-phase QA checklist, recommended first three PRs, open questions before promotion to `2-WORKING`).
  - **The three source notes the synthesis claims to represent** — cite these to verify faithfulness:
    - `PROJECT/1-INBOX/PDDA/FEEDBACK-PERPLEXITY.md`
    - `PROJECT/1-INBOX/PDDA/FEEDBACK-CHATGPT.md`
    - `PROJECT/1-INBOX/PDDA/FEEDBACK-GEMINI.md`
  - **The contract it must obey + advocates:** `PROJECT/PDDA.md` (lifecycle folders, required frontmatter, the exact two-column `## Status` table, QA-gate-per-phase, hardcoded-path ban, the `ROADMAP.md` pointer-only contract) and `ROUTER.md` (the startup path the doc proposes linking new files from).
- Definition of Done — judge the synthesis on:
  - **(a) Faithfulness to the three sources:** does the "What the feedback agrees on" section and the keep/avoid/build framing accurately represent Perplexity, ChatGPT, and Gemini, or does it editorialize, misattribute, or invent agreement that isn't in the notes? Cite `FEEDBACK-*.md:line` for any drift.
  - **(b) Internal consistency + scope discipline:** does the doc honor its own `non_goals` and "What to avoid building" list, or does a later phase (esp. Phase 4 evidence bridge, Phase 5 integrations) smuggle back the platform sprawl it forbids? Does anything contradict the "thin repo-governance and safety layer" thesis?
  - **(c) Consistency with the PDDA contract it advocates:** does the doc obey `PROJECT/PDDA.md` (minimum frontmatter; the proposal correctly flags the `Most recently completed phase` header vs the active-doc `What was just completed | What's next` contract; repo-relative paths only; no second roadmap)? Is the header-note caveat correct and sufficient, or does it still violate the contract while sitting in `1-INBOX`?
  - **(d) Actionability / observability:** is every checklist item genuinely observable (each has a concrete *Observable:* line that a script or human could check)? Are the per-phase QA checklists real gates, not restatements? Is the "Recommended first three PRs" order dependency-correct (does PR 2 or 3 depend on PR 1's outputs)?
  - **(e) Right-sizing / YAGNI:** is a 5-phase plan proportionate for a `1-INBOX` proposal, or is it premature scaffolding? Should Phases 4–5 be deferred to a sibling track (one of the open questions raises exactly this) rather than specified now?
  - **(f) Open-questions quality:** are the 4 open questions the genuinely blocking ones before promotion to `2-WORKING`, or are any non-blocking / missing a load-bearing one (e.g. where `CONSTITUTION.md` should live, or whether the evidence bridge should be its own track)?
- Producer: Noel (owner) — represented here by the orchestrator (claude-a)   ·   Reviewer: **agy**
- Handoff: cli-driven (agy)   <!-- driven by relay-automation/relay-drive.sh + agy-turn.sh -->
- Started: 2026-06-23

## Ground rules
1. This file is the single source of truth. The agents are different tools (Claude and agy) and never share memory.
2. Read the whole file. Take a turn only if `NEXT` names your role.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Then update `NEXT`/`STATUS` at the top.
4. Stay tight. Findings are graded bullets, not essays.
5. **The Reviewer (agy) never edits the artifact.** It proposes graded findings with concrete suggested fixes; it appends them to THIS file only.
6. Grade every finding: `[Blocker]` must fix · `[Should]` strong rec · `[Nit]` optional · `[Pass]` checked + sound.
7. The Reviewer posts a Verdict. Relay ends on **Approved**; else the orchestrator carries the findings back to the Producer.
8. End your turn by committing it: `relay(pdda-feedback-synthesis): <role> r<N>`. No push.
9. **One actor at a time.** The `RELAY-PDDA-SYNTH` tick token is the lock.
10. **Evidence:** this is a *planning* doc — prefer `textual` evidence with `file:line` citations into the artifact, the three `FEEDBACK-*.md` notes, and `PROJECT/PDDA.md`. Where the synthesis claims the feedback "agrees," verify it against the actual notes.

## Roles
- **Producer** — Noel (owner), applied here by the orchestrator (claude-a). Applies the Reviewer's findings to the artifact between rounds.
- **Reviewer** — agy. Reviews against the DoD, proposes graded findings, sets a verdict. Never edits the artifact.

---
## Log

### Round 1 · Producer · claude-a (on Noel's behalf) · 2026-06-23
**Did:** Scaffolded this relay for a design review of `PROJECT/1-INBOX/PDDA/PDDA-FEEDBACK-SYNTHESIS-PLAN.md` — a proposal-stage synthesis that takes the three June 23 feedback notes (Perplexity / ChatGPT / Gemini) and reduces them to one actionable PDDA direction: keep PDDA a *thin repo-governance and safety layer*, with a 5-phase plan (lock positioning → harden contract/modes → artifact ergonomics → evidence bridge to rebalance → outward integrations), each phase carrying a checklist + a QA checklist, plus a "first three PRs" sequence and 4 open questions before promotion to `2-WORKING`. No edits to the artifact yet — this is the review request.
**Review this:** Apply the DoD in Setup. I'm most interested in: (a) is the synthesis **faithful** to the three source notes, or does it claim agreement the notes don't support? (b) does any later phase (esp. Phase 4 evidence bridge / Phase 5 integrations) **smuggle back** the platform sprawl the doc's own "What to avoid building" list forbids? (c) does the doc obey the **PDDA contract** it advocates (the `Most recently completed phase` header note, no second roadmap, repo-relative paths)? (d) are the checklist *Observable:* lines genuinely checkable and is the "first three PRs" order dependency-correct? (e) is a 5-phase plan **right-sized** for a `1-INBOX` proposal, or should Phases 4–5 defer to a sibling track?
**Verification:** N/A from the producer side — this is a review request. By inspection the artifact carries frontmatter, a `## Status` table, per-phase QA checklists, and repo-relative paths; confirm or refute that it actually meets the PDDA contract it advocates.
**Open questions:** The 4 at the bottom of the artifact (CONSTITUTION.md path; feature-folder promotion timing; which single evidence output ships first; combined vs sibling PDDA+rebalance track) — flag which actually block promotion to `2-WORKING` and whether any load-bearing one is missing.
**Commit:** (this relay scaffold; the artifact is reviewed on disk in `1-INBOX`)

### Round 1 · Reviewer · agy · 2026-06-23
**Verdict:** Changes requested

**Findings & proposals:**
- `[Blocker]` **Premature scaffolding and scope creep in Phases 3-5 contradict YAGNI and the "thin layer" goal.**
  - *Detail:* The plan defines a heavy 5-phase roadmap. Phase 3 (artifact taxonomy, custom analyzers, clarifying gates) and Phase 4 (weekly prioritization command, morning briefs tracking calendar and Gmail) represent a significant expansion of features. This directly contradicts the non-goal of "not turning PDDA into a general spec-driven-development platform" ([PDDA-FEEDBACK-SYNTHESIS-PLAN.md#L21](file:///var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/rtl-wt.CNDaYc/PROJECT/1-INBOX/PDDA/PDDA-FEEDBACK-SYNTHESIS-PLAN.md#L21)), ChatGPT's warning to "not keep refining it as a broad platform" ([FEEDBACK-CHATGPT.md#L20](file:///var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/rtl-wt.CNDaYc/PROJECT/1-INBOX/PDDA/FEEDBACK-CHATGPT.md#L20)), and Gemini's strong recommendation to "freeze the Bash" and let it be "good enough" ([FEEDBACK-GEMINI.md#L3](file:///var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/rtl-wt.CNDaYc/PROJECT/1-INBOX/PDDA/FEEDBACK-GEMINI.md#L3)).
  - *Proposal:* Truncate the active roadmap to Phase 1 (positioning/constitution) and Phase 2 (hardening modes), and explicitly defer or move Phases 3-5 to a separate track or the rebalance backlog to keep PDDA focused as a thin, low-maintenance governance layer.
- `[Should]` **Dependency mismatch in the "Recommended first three PRs" sequence.**
  - *Detail:* The first three PRs sequence places the "Evidence snapshot bridge" as PR 3 ([PDDA-FEEDBACK-SYNTHESIS-PLAN.md#L255](file:///var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/rtl-wt.CNDaYc/PROJECT/1-INBOX/PDDA/PDDA-FEEDBACK-SYNTHESIS-PLAN.md#L255)). However, this bridge (a Phase 4 feature) depends on the artifact ergonomics and taxonomy changes defined in Phase 3 ([PDDA-FEEDBACK-SYNTHESIS-PLAN.md#L165-L181](file:///var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/rtl-wt.CNDaYc/PROJECT/1-INBOX/PDDA/PDDA-FEEDBACK-SYNTHESIS-PLAN.md#L165-L181)) to know what metadata and folder structure to query. Implementing PR 3 before Phase 3 is completed will result in throwaway code or circular dependencies.
  - *Proposal:* Re-order the recommended PRs, clarify that PR 3 will operate only on single-file active docs, or swap the sequence so that artifact structure is locked before the bridge is built.
- `[Should]` **Missing open question/task on replacing custom scripts with off-the-shelf linting.**
  - *Detail:* Both Gemini ([FEEDBACK-GEMINI.md#L5](file:///var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/rtl-wt.CNDaYc/PROJECT/1-INBOX/PDDA/FEEDBACK-GEMINI.md#L5)) and ChatGPT ([FEEDBACK-CHATGPT.md#L66](file:///var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/rtl-wt.CNDaYc/PROJECT/1-INBOX/PDDA/FEEDBACK-CHATGPT.md#L66)) recommend replacing custom Bash scripts with standard tools like `markdownlint` to reduce maintenance overhead. The current open questions ([PDDA-FEEDBACK-SYNTHESIS-PLAN.md#L260-L268](file:///var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/rtl-wt.CNDaYc/PROJECT/1-INBOX/PDDA/PDDA-FEEDBACK-SYNTHESIS-PLAN.md#L260-L268)) do not address this, nor does the roadmap plan for this transition.
  - *Proposal:* Add a 5th open question: "Should we replace custom deterministic Bash scripts with a standard `.markdownlint.json` configuration to minimize maintenance overhead as suggested by Gemini and ChatGPT?"
- `[Should]` **Over-generalized claim of convergence regarding the evidence bridge/rebalance.**
  - *Detail:* The decision summary states that the three feedback docs "converge on... the bridge between repo truth and local work evidence (rebalance)" ([PDDA-FEEDBACK-SYNTHESIS-PLAN.md#L65-L66](file:///var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/rtl-wt.CNDaYc/PROJECT/1-INBOX/PDDA/PDDA-FEEDBACK-SYNTHESIS-PLAN.md#L65-L66)). However, only Perplexity's feedback mentions `rebalance` or the evidence bridge. ChatGPT's and Gemini's feedback focus exclusively on scope containment, freezing the custom Bash scripts, and using standard tools (like `markdownlint`).
  - *Proposal:* Reword [PDDA-FEEDBACK-SYNTHESIS-PLAN.md#L65-L66](file:///var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/rtl-wt.CNDaYc/PROJECT/1-INBOX/PDDA/PDDA-FEEDBACK-SYNTHESIS-PLAN.md#L65-L66) to clarify that the evidence bridge is a Perplexity-specific proposal to bridge the repo and local workspace, rather than a point of agreement across all three sources.
- `[Pass]` **Header-note caveat and paths.**
  - *Detail:* The file uses repo-relative paths correctly. The header-note caveat on lines 37-39 correctly explains why it uses the alternative `Most recently completed phase` status header in `1-INBOX`. Since it is not yet in `2-WORKING`, this does not violate the active-doc contract of `PROJECT/PDDA.md`.

**Commit:** <pending handoff>

### Round 2 · Producer · claude-a (on Noel's behalf) · 2026-06-23
**Decisions on proposals:** (all applied to `PROJECT/1-INBOX/PDDA/PDDA-FEEDBACK-SYNTHESIS-PLAN.md` on disk — re-review the committed file)
- `[Blocker]` Premature scaffolding / scope creep in Phases 3–5 — **Implemented (defer-in-place).** Rather than delete the forward design, I scoped the **near-term proposal to Phases 1–2 only** and marked **Phases 3, 4, 5 as `Deferred (future track)`** with a blockquote under each header (Phase 4/5 also decision-gated behind the evidence-bridge open question). Added a "Proposed near-term scope" note to the Decision summary and updated the `## Status` row to say the same. This keeps PDDA a thin governance/safety layer and honors Gemini/ChatGPT's freeze-and-contain signal without throwing away the design thinking. (Decision summary; `## Status`; Phase 3/4/5 headers.)
- `[Should]` Dependency mismatch — PR 3 (evidence bridge, a Phase 4 item) ahead of Phase 3 — **Implemented.** Renamed the section to **"Recommended first PRs"** (TOC anchor updated), marked PRs 1–2 as the near-term pair and **PR 3 as deferred/decision-gated**, and added an explicit **Dependency guard**: the first evidence-snapshot version must operate only on existing single-file active docs + git/notes signals and must NOT depend on the Phase 3 taxonomy (else they deadlock).
- `[Should]` Missing open question on off-the-shelf linting — **Implemented.** Added a **5th open question**: whether to offload the deterministic Bash checks to a standard `.markdownlint.json` (+ Vale/lychee) and keep only the repo-specific contract checks custom — citing Gemini (`FEEDBACK-GEMINI.md`) and ChatGPT (`FEEDBACK-CHATGPT.md`), and naming which checks are hard to translate (exact `## Status` header, hardcoded-path ban, pointer-only `ROADMAP.md`).
- `[Should]` Over-generalized "all three converge on the evidence bridge" claim — **Implemented.** Verified independently: `rebalance`/evidence-bridge appears **only** in `FEEDBACK-PERPLEXITY.md` (26 hits; 0 in ChatGPT, 0 in Gemini). Reworded the Decision summary so the first two bullets are marked the genuine three-way agreement and the evidence bridge is labeled **Perplexity's proposal only**, with ChatGPT/Gemini converging on scope containment instead. Phase 4 Intent reattributed to Perplexity.
- `[Pass]` Header-note caveat + paths — no change needed; thanks for the independent confirmation it's correct for a `1-INBOX` doc.
**Did:** All 4 actioned findings applied to the artifact (committed). No change to the `[Pass]` item.
**Verification:** textual — `rebalance` mention counts confirmed by grep across the three notes (P:26 / C:0 / G:0); markdownlint recommendation confirmed at `FEEDBACK-CHATGPT.md:66` and `FEEDBACK-GEMINI.md:5`. Doc re-read; frontmatter, the `## Status` table, per-phase QA checklists, and repo-relative paths all intact; TOC anchor for the renamed PR section updated to match.
**Re-review this:** (1) Is the Phase 1–2 near-term / Phase 3–5 deferred boundary now unambiguous and consistent across Status, Decision summary, the phase headers, and the PR list? (2) Is the evidence-bridge attribution now faithful to the sources? (3) Does the PR 3 dependency guard resolve the circular-dependency risk? If satisfied this is round 2/3 — **Approve**; else name any real Blocker.
**Commit:** <pending handoff>

<!-- ↓↓↓  NEXT TURN GOES ABOVE THIS LINE — keep this marker last  ↓↓↓ -->
