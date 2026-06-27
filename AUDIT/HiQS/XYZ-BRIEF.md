# XYZ (Forge) Multi-Agent Toolkit — Capabilities Brief
### For Business Analysis & Marketing Planning
*Date: 2026-06-17 · Refreshed: 2026-06-24 · Status: Working Beta · Audience: Business Analysts, Marketing Directors*

> **How this brief was produced (accuracy assurance).** Every capability and limitation below was read directly from the product's source code and automated test suite on 2026-06-17 — not from memory, prior marketing, or the team's own description. The draft was then independently reviewed by two separate AI models (OpenAI Codex and Google Gemini) running in parallel against the live repository, and the nine factual corrections they surfaced were each re-verified against the source before being applied. As a result, every statement here is traceable to a specific file or test (see *Appendix: Substantiation*), and the marketing claims have been pre-screened so nothing external-facing outruns what the technical record can support.

> **2026-06-24 refresh (what changed since the original).** Re-checked against `ROADMAP.md` and `CHANGELOG.md`. Three corrections were material: (1) **Google Gemini was retired as a coordinated model on 2026-06-19** — the permanent cross-model lane is now **agy (Antigravity CLI)**; every forward-looking "the product uses Gemini" claim was changed to agy (the line above is historical — Gemini *did* review the 06-17 draft, so it stays). (2) The automated test suite grew from **23/23 to 44/44**. (3) **Cross-model relay is no longer manual** — headless cross-model loops (`relay-drive.sh` + `agy-turn.sh`/`codex-turn.sh`) now run to "Approved" on their own, demonstrated live on 06-23 and 06-24. Two capabilities that shipped after the original (worktree-isolation containment, cross-repo targeting, and the cost-observed Marathon harness) are folded in below.

---

## 1. Executive summary

XYZ (Forge) is a developer toolkit that makes three AI coding assistants — Claude, OpenAI Codex, and agy (Antigravity) — work **together** on one codebase instead of as three disconnected chat windows a person has to referee. It offers three core modes of collaboration — **building in parallel**, **reviewing each other's work in a loop** (including a turnkey **"Dueling Claudes"** two-window recipe where one Claude reports and another fixes), and **giving a reconciled second opinion** before a decision is made — plus an emerging fourth mode, **autonomous multi-phase builds** (the cost-observed "Marathon" harness).

**Bottom line for planning:** the foundation is mature and well-tested (44/44 automated tests). All three core collaboration modes now run hands-free — including **cross-model** loops, which since the original draft graduated from "needs a manual nudge" to fully driven. The active frontier has moved up the stack to **autonomous, multi-phase, cost-budgeted builds** and **same-device cross-repo swarms**. This is a credible **beta** with an unusually honest engineering culture — which, as Section 4 argues, is itself a marketable asset. It is not yet a turnkey, install-anywhere product.

---

## 2. The three capabilities (Business-Analyst view)

| Capability | What it delivers, in business terms | Readiness | Best-fit use | The one limitation to plan around |
|---|---|---|---|---|
| **Concurrent Swarm** | Run multiple AI agents on the same codebase at once without them overwriting each other, plus a trustworthy measurement of how much they actually worked in parallel. | **Highest** — 44/44 automated tests pass; validated in live multi-agent runs. | Large builds that split cleanly into independent workstreams. | The lock guarantees two agents can't claim the *same task*. Edit-lane separation is now **enforced via per-agent git worktrees** (default-ON for driven runs); in the simplest shared-checkout setup it still relies on agent compliance plus after-the-fact auditing. |
| **Automated Relay** | A self-running "build → review → fix" loop between two agents that continues until the work is approved, eliminating the human copy-paste between AI windows. | **Solid** — now hands-free for both same-model and **cross-model** loops. | Iteratively hardening one artifact — a code change, a spec, a document. | Cross-model relay (Claude ↔ Codex ↔ agy) now runs to "Approved" without a manual nudge. Setup is environment-specific: an agent CLI must be present and reachable (e.g. a missing `claude` binary fails loudly, not silently). |
| **Dueling Claudes** | Two live Claude Code windows — a *Reporter* that finds and cites a problem and a *Maintainer* that fixes it — talk to each other through one shared file on disk, with no human copy-paste between them. One human gate: the fixer shows its diff and waits for your "go" before it commits. | **Solid** — a zero-new-code recipe over the shipped Relay engine; two recorded live runs. | A reviewer-window + fixer-window loop on one machine (e.g. report a bug in repo A, fix it here) where you want a human approving each commit. | Same machine only (both windows share one filesystem). Two Claude windows share one model, so they share blind spots — for independent review, put Codex/agy in the second window. The turn contract lives in copy-pasted command strings, so paste them exactly. |
| **Consult** | A one-shot "second opinion": ask two different AI models the same question simultaneously and receive a single reconciled answer that shows where they agreed and disagreed. | **Solid** — test-covered and self-validated twice. | De-risking a decision, design, or document before committing to it. | Two models agreeing raises confidence but is not proof. It protects your *code repository* (disposable copy), not the host *machine process*. |
| **Marathon** *(emerging)* | An autonomous, multi-phase build that chains "build → review → advance" across phases on its own, with a real budget and a deterministic read on tokens, wall-clock, and human-minutes spent. | **Active frontier** — harness shipped and E2E-validated; graduation dogfood (real external repo) in progress. | Long, self-contained builds you want run unattended against a budget. | Cost capture is blind on the agy lane (no token output). Cross-repo, same-device swarms are the live hardening target — not yet turnkey. |

### Readiness tiering (what to treat as ready vs. in-progress)

- **Production-quality core** — the underlying coordination engine and the concurrency model. Fully tested (44/44), the part everything else stands on.
- **Production-quality** — the Relay loop, the **Dueling Claudes** two-window recipe built on it, and the Consult second-opinion flow, now driven hands-free both within one model and **across model vendors** (Claude ↔ Codex ↔ agy).
- **Active frontier (not done)** — autonomous, multi-phase, **cost-budgeted** builds (the Marathon harness) and **same-device cross-repo swarms**. Wired and demonstrated; the graduation dogfood against a real external repo is in progress.

### Risk register (the honest limitations, translated)

| Business risk | Likelihood / severity | Mitigation already in place | Status |
|---|---|---|---|
| An agent edits files outside its declared lane, causing an unexpected conflict | Low / Medium | Real lock on task claims + automated post-run audit; **per-agent git-worktree isolation now enforces edit-lane separation** (default-ON for driven runs) | Strongly mitigated — worktree isolation shipped; the shared-checkout fallback still relies on compliance + audit |
| A cross-model run isn't truly hands-free and needs operator attention | Low / Low | Cross-model loops now run headless to "Approved" via the driver; the system fails loudly (e.g. missing agent CLI) rather than stalling silently | Resolved for driven relays; remaining caveat is environment setup, not turn-taking |
| A "second opinion" is trusted as fact when both models share a blind spot | Medium / Medium | Output deliberately surfaces disagreement and is labeled advisory, not authoritative | By design — positioning must reinforce "signal, not proof" |
| Tool assumed portable to any machine/repo when parts are environment-specific | Medium / Low | The portable review loop is dependency-free; the automation and consult layers declare their dependencies and refuse to run if unmet | Known; affects install/onboarding messaging |
| Attribution of "who did what" is coarse in the simplest setup | Low / Low | The internal activity log is the reliable record of authorship | Known; richer attribution is future work |

---

## 3. Positioning & messaging (Marketing-Director view)

### The buyer and the pain
The target user already pays for and uses more than one AI coding assistant, and feels the friction of running them as **separate, uncoordinated windows** — manually shuttling output between them, hoping they don't overwrite each other's work, and having no objective read on whether parallel agents actually saved time. XYZ's core promise: **stop refereeing your AI tools; let them coordinate.**

### Messaging pillars (one per capability)
1. **Parallel without chaos.** "Put three AI agents on one codebase at once — with a real lock that stops them claiming the same work, worktree isolation so they can't overwrite each other, and an honest read on how parallel they actually were." *(Value: speed without merge pain.)*
2. **Review that runs itself.** "A build-and-review loop that runs to 'approved' on its own — across models, no more copy-pasting between windows." *(Value: quality, hands-off.)*
3. **A second opinion before you commit.** "Ask two models the same question at once and get one reconciled answer that shows where they agree and disagree — with your real code sealed off in a disposable copy they can never touch." *(Value: de-risk decisions; trust through transparency.)*
4. **Set the budget, walk away.** *(Emerging.)* "Hand off a multi-phase build that chains itself from phase to phase against a token budget — and gives you a deterministic read on what it cost in tokens, wall-clock, and human-minutes." *(Value: unattended throughput, measured.)*

### Differentiators
- **Coordination, not just multi-model.** Many tools *let* you use several models; this one makes them *work as a team*.
- **An honesty-first product.** Failures are surfaced, not hidden; the system states when it degrades. This is rare and is a trust differentiator (see Section 4).
- **Measured, not vibes.** A real concurrency metric replaces "it felt faster."

### ⚠️ Claims substantiation table (use this before any copy ships)
This is the bridge between marketing and the technical record. Left column = the instinctive claim; right columns = what's actually defensible.

| Tempting claim | Safe to say? | Defensible wording | Do **not** say |
|---|---|---|---|
| No two agents ever collide | ✅ Scoped | "A real lock guarantees no two agents ever claim the same task; driven runs isolate each agent in its own git worktree." | "Collision-proof" (the shared-checkout fallback still trusts agent compliance) |
| Your code is safe during a consult | ✅ Yes | "Advisors work in a disposable copy of your repo — your real code is never their surface." | "Fully sandboxed," "provably safe" (that implies process-level isolation, which it isn't) |
| Hands-free review loop | ✅ Yes | "Hands-free review — same-model and cross-model (Claude, Codex, agy)." | "Zero-setup" (cross-model needs the agent CLIs installed and reachable) |
| Proven in the field | ⚠️ Soften | "Hand-tested with live agents; 44/44 automated tests passing." | "Battle-tested," "production-proven," "enterprise-grade" |
| Trustworthy second opinion | ✅ With framing | "Two independent reads, reconciled — strong signal." | "Verified answer," "guaranteed correct" (agreement ≠ proof) |
| Works anywhere | ⚠️ Partial | "Portable review loop; advanced automation has setup requirements." | "Install once, runs anywhere" |

### Sample paid-package copy (pre-screened against the table above)

> ## XYZ — Your AI Agents, Working as a Team
>
> **Claude. Codex. agy. One codebase. Finally coordinated.**
>
> Stop refereeing three AI windows. XYZ gives your agents a shared playbook so they can build in parallel without claiming the same work, review each other until it's right, and hand you a reconciled second opinion before you commit — all from your terminal.
>
> - **Swarm** — split a build across agents, with a real lock so no two ever claim the same task, and worktree isolation so they can't step on each other's edits.
> - **Relay** — a build-and-review loop that runs itself to "approved," hands-free across models.
> - **Consult** — ask two models one question, get one honest, reconciled answer — with your real code sealed off in a disposable copy the advisors can never touch.
>
> Hand-tested with live agents. 44/44 automated tests. Honest about its limits. Built by people who run it daily.
>
> **Get the XYZ toolkit → coordinate your agents today.**

---

## 4. The honesty advantage (why this is a marketing asset, not just a caveat)

The most unusual thing about this product is the **small gap between what's technically true and what's marketed**. The engineering process behind it surfaces its own failures, states its limits in plain language, and revises its own claims when testing proves them wrong — this very brief exists because two independent AI reviewers were invited to attack the assessment and nine of their corrections were adopted.

For a market saturated with overclaiming AI tools, "**honest about its limits**" is a genuine differentiator and a trust accelerator with technical buyers. The recommendation is to **lead with the honesty**, keep every external claim inside the substantiation table above, and let the credibility do work that hype can't.

---

## Appendix: Substantiation (traceability for analysts)

Claims in this brief map to the source-level assessment and the underlying code/tests:

- **Source assessment (full engineering detail):** `relay-system/2026-06-17/capabilities-assessment.md`
- **Cross-model review record (the two AI reviewers + reconciliation):** `relay-system/2026-06-17/capabilities-review-143340/SYNTHESIS.md`
- **"44/44 tests":** `validate.sh` (was 23/23 at the 06-17 draft)
- **"Lock guards claims; worktree isolation enforces edit lanes":** `README.md` (claim lock) + `relay-turn-lib.sh` / `RELAY_WORKTREE_ISOLATION` (worktree isolation, default-ON for driven runs)
- **"Cross-model relay now runs headless to Approved":** `relay-automation/relay-drive.sh` + `relay-automation/agy-turn.sh` / `relay-automation/codex-turn.sh` (live runs: `relay-system/2026-06-23/pdda-feedback-synthesis.md`, `relay-system/2026-06-24/gh18-agy-review.md`). *(Superseded: the original `relay-automation/poll.sh` manual-nudge path.)*
- **"Gemini retired 2026-06-19; agy is the permanent cross-model lane":** `ROADMAP.md` (operational note) + `PROJECT/3-COMPLETED/MARATHON-HARNESS.md`
- **"Marathon: cost-observed multi-phase chaining":** `relay-automation/marathon-drive.sh`, `tick analyze`, `PROJECT/3-COMPLETED/MARATHON-HARNESS.md`
- **"Cross-repo targeting (`--target-root`)":** `relay-automation/relay-drive.sh`, `relay-turn-lib.sh`, `test/relay-target-root.sh`
- **"Dueling Claudes: two Claude windows, one shared file, zero new code, human-gated commit":** `relay-automation/DUELING-CLAUDES.md` (recipe over `poll.sh` + `/loop` + `tick`); recorded runs `relay-system/2026-06-22/dueling-claudes.md`, `relay-system/2026-06-23/codex-relay-review.md`
- **"Consult uses a disposable copy; repo-isolated not process-sandboxed":** `skill/consult/SKILL.md`, `relay-automation/consult.sh`
- **"Watchdog escalates rather than self-heals":** `relay-automation/watchdog.sh` + its README

---

## Appendix B: Landing-page sketch (marketing draft)

*Aspirational tone, but every headline below maps to something in the substantiation table (§3) — the "spin" is in the framing, not in new claims. Defensibility notes are in italics; strip them before publishing.*

### Hero

> # Your AI coding agents, finally on the same team.
>
> ### Claude, Codex, and agy — building, reviewing, and second-guessing each other on one codebase, while you watch instead of referee.
>
> **[ Start coordinating → ]**  ·  *[ See how it works ]*
>
> *Defensible: "coordinated multi-agent" is the literal product. Avoids "autonomous AI engineer" overclaim.*

**Trust strip (under the fold of the hero):**
`44/44 automated tests passing` · `Runs from your terminal` · `Your code never leaves a disposable copy` · `Honest about what's beta`

---

### The problem (one screen, empathetic)

> **You're paying for three AI assistants. You're using them like three browser tabs.**
>
> Copy out of one, paste into another. Hope the second one doesn't undo the first. Squint at two answers and guess which to trust. No idea if running them "in parallel" actually saved you a minute.
>
> That's not a team. That's three contractors who've never met.

---

### What XYZ does (feature blocks — the 3 + 1)

> **🔀 Swarm — parallel without the pileup**
> Point multiple agents at one repo and let them work at once. A real lock means no two ever grab the same task; per-agent git worktrees mean they can't overwrite each other's edits. And you get an honest number for how parallel they actually were — not a vibe.
> *Defensible ✅ — claim lock + worktree isolation + concurrency metric all shipped. Do not say "collision-proof."*

> **🔁 Relay — review that runs itself**
> A build-and-review loop that runs to "approved" on its own. Two agents trade turns — one builds, one critiques and proposes fixes — until the work passes. Now hands-free across models, not just one. You stop being the clipboard.
> *Defensible ✅ — cross-model headless relay demonstrated live (06-23, 06-24). Say "needs the agent CLIs installed," not "zero setup."*

> **🥊 Dueling Claudes — two windows, one conversation**
> Open two Claude Code windows — one finds and cites the problem, the other fixes it — and let them talk to each other through a single file on disk. No copy-paste, no shuttling output between tabs. You stay in the loop for the one decision that matters: the fixer shows its diff and waits for your "go" before anything commits.
> *Defensible ✅ — a zero-new-code recipe over the shipped Relay engine, with two recorded runs. Say "same machine," not "anywhere"; note two Claude windows share a model's blind spots — drop Codex/agy into a window for independent review.*

> **🧭 Consult — a second opinion before you commit**
> Ask two different models the same question at once and get one reconciled answer that shows exactly where they agree and where they don't. They work in a disposable copy of your repo — your real code is never on the table.
> *Defensible ✅ — repo-isolated. Say "your code is sealed off," not "fully sandboxed" (no process isolation).*

> **⏱️ Marathon — set a budget, walk away** *(beta)*
> Hand off a multi-phase build that chains itself from phase to phase against a token budget — and hands you back a deterministic ledger of what it cost in tokens, wall-clock, and human-minutes. The honest frontier of the product.
> *Defensible ⚠️ — label it beta. Harness shipped + validated; the real-repo graduation run is in progress. Cost is blind on the agy lane.*

---

### Why XYZ (differentiators)

> **Coordination, not just multi-model.** Plenty of tools let you *pick* a model. XYZ makes them *work as a team*.
>
> **Measured, not vibes.** A real concurrency and cost metric replaces "it felt faster."
>
> **Honest by construction.** When something degrades, it tells you — loudly. This very page was fact-checked against the source code, and the claims that didn't hold up were cut.

---

### The honesty pledge (the section that converts technical buyers)

> **We'll tell you what's beta before you find out the hard way.**
>
> Most AI tools market the demo. We publish the limits: what's production-quality, what still needs setup, and what's an active frontier. Our claims are checked against our own test suite and source — by rival AI models we invite to attack them. If a sentence on this page can't be traced to code, it doesn't ship.
>
> *Defensible ✅ — this is literally how the brief was produced; it's the product's strongest, truest differentiator.*

---

### How it works (3 steps)

> 1. **Install the toolkit** and point it at your repo.
> 2. **Pick a mode** — Swarm, Relay, Consult, or Marathon — from your terminal.
> 3. **Watch the agents coordinate** — claims, reviews, costs, and conflicts, all on the record.

---

### Final CTA

> ## Stop refereeing. Start shipping.
> Give your agents a shared playbook today.
>
> **[ Get XYZ → ]**   *Built by people who run it daily.*

---

### Honest-footer microcopy (recommended, not optional)

> *XYZ is a working beta. Swarm, Relay, and Consult are production-quality; Marathon and cross-repo swarms are active frontiers. Setup is environment-specific — see the docs for prerequisites.*

**Pre-publish gate:** run every headline above through the §3 substantiation table. Anything in the "Do not say" column that slips in (e.g. "collision-proof," "fully sandboxed," "battle-tested," "install once, runs anywhere") must be cut or reworded before the page goes live.
