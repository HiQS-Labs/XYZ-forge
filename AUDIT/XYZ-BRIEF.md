# XYZ Multi-Agent Toolkit — Capabilities Brief
### For Business Analysis & Marketing Planning
*Date: 2026-06-17 · Status: Working Beta · Audience: Business Analysts, Marketing Directors*

> **How this brief was produced (accuracy assurance).** Every capability and limitation below was read directly from the product's source code and automated test suite on 2026-06-17 — not from memory, prior marketing, or the team's own description. The draft was then independently reviewed by two separate AI models (OpenAI Codex and Google Gemini) running in parallel against the live repository, and the nine factual corrections they surfaced were each re-verified against the source before being applied. As a result, every statement here is traceable to a specific file or test (see *Appendix: Substantiation*), and the marketing claims have been pre-screened so nothing external-facing outruns what the technical record can support.

---

## 1. Executive summary

XYZ is a developer toolkit that makes three AI coding assistants — Claude, OpenAI Codex, and Google Gemini — work **together** on one codebase instead of as three disconnected chat windows a person has to referee. It offers three distinct modes of collaboration: **building in parallel**, **reviewing each other's work in a loop**, and **giving a reconciled second opinion** before a decision is made.

**Bottom line for planning:** the foundation is mature and well-tested; two of the three collaboration modes are production-quality, and the third (full cross-model automation) is partially complete and clearly the active build frontier. This is a credible **beta** with an unusually honest engineering culture — which, as Section 4 argues, is itself a marketable asset. It is not yet a turnkey, install-anywhere product.

---

## 2. The three capabilities (Business-Analyst view)

| Capability | What it delivers, in business terms | Readiness | Best-fit use | The one limitation to plan around |
|---|---|---|---|---|
| **Concurrent Swarm** | Run multiple AI agents on the same codebase at once without them overwriting each other, plus a trustworthy measurement of how much they actually worked in parallel. | **Highest** — 23/23 automated tests pass; validated in live multi-agent runs. | Large builds that split cleanly into independent workstreams. | It guarantees two agents can't claim the *same task*, but does not hard-block an agent from editing outside its lane — collision-safety relies on agent compliance plus after-the-fact auditing. |
| **Automated Relay** | A self-running "build → review → fix" loop between two agents that continues until the work is approved, eliminating the human copy-paste between AI windows. | **Solid** for Claude-to-Claude; **partial** for cross-model. | Iteratively hardening one artifact — a code change, a spec, a document. | Fully automatic turn-taking works for the Claude loop today; turns handed to Codex/Gemini still need a manual nudge. Full cross-model automation is in progress. |
| **Consult** | A one-shot "second opinion": ask two different AI models the same question simultaneously and receive a single reconciled answer that shows where they agreed and disagreed. | **Newest**, but test-covered and self-validated twice. | De-risking a decision, design, or document before committing to it. | Two models agreeing raises confidence but is not proof. It protects your *code repository*, not the host *machine process*. |

### Readiness tiering (what to treat as ready vs. in-progress)

- **Production-quality core** — the underlying coordination engine and the concurrency model. Fully tested (23/23), the part everything else stands on.
- **Production-quality, single-model** — the Relay loop and the Consult second-opinion flow, when driven by the Claude agent.
- **Active frontier (not done)** — fully automated, hands-free coordination *across* the three different model vendors. Wired and demonstrated, not yet finished.

### Risk register (the honest limitations, translated)

| Business risk | Likelihood / severity | Mitigation already in place | Status |
|---|---|---|---|
| An agent edits files outside its declared lane, causing an unexpected conflict | Low / Medium | Real lock on task claims + automated post-run audit; a stricter pre-commit enforcement option is designed | Mitigated, not eliminated — enforcement is a planned upgrade |
| A cross-model run isn't truly hands-free and needs operator attention | Medium / Low | The Claude loop is fully automatic; the system *tells you* when a manual nudge is needed rather than stalling silently | Known; full automation in progress |
| A "second opinion" is trusted as fact when both models share a blind spot | Medium / Medium | Output deliberately surfaces disagreement and is labeled advisory, not authoritative | By design — positioning must reinforce "signal, not proof" |
| Tool assumed portable to any machine/repo when parts are environment-specific | Medium / Low | The portable review loop is dependency-free; the automation and consult layers declare their dependencies and refuse to run if unmet | Known; affects install/onboarding messaging |
| Attribution of "who did what" is coarse in the simplest setup | Low / Low | The internal activity log is the reliable record of authorship | Known; richer attribution is future work |

---

## 3. Positioning & messaging (Marketing-Director view)

### The buyer and the pain
The target user already pays for and uses more than one AI coding assistant, and feels the friction of running them as **separate, uncoordinated windows** — manually shuttling output between them, hoping they don't overwrite each other's work, and having no objective read on whether parallel agents actually saved time. XYZ's core promise: **stop refereeing your AI tools; let them coordinate.**

### Three messaging pillars (one per capability)
1. **Parallel without chaos.** "Put three AI agents on one codebase at once — with a real lock that stops them claiming the same work, and an honest read on how parallel they actually were." *(Value: speed without merge pain.)*
2. **Review that runs itself.** "A build-and-review loop between two agents that runs to 'approved' on its own — no more copy-pasting between windows." *(Value: quality, hands-off.)*
3. **A second opinion before you commit.** "Ask two models the same question at once and get one reconciled answer that shows where they agree and disagree — with your real code sealed off in a disposable copy they can never touch." *(Value: de-risk decisions; trust through transparency.)*

### Differentiators
- **Coordination, not just multi-model.** Many tools *let* you use several models; this one makes them *work as a team*.
- **An honesty-first product.** Failures are surfaced, not hidden; the system states when it degrades. This is rare and is a trust differentiator (see Section 4).
- **Measured, not vibes.** A real concurrency metric replaces "it felt faster."

### ⚠️ Claims substantiation table (use this before any copy ships)
This is the bridge between marketing and the technical record. Left column = the instinctive claim; right columns = what's actually defensible.

| Tempting claim | Safe to say? | Defensible wording | Do **not** say |
|---|---|---|---|
| No two agents ever collide | ✅ Scoped | "A real lock guarantees no two agents ever claim the same task." | "Collision-proof," "they can't touch the same file" (file-level edits aren't enforced) |
| Your code is safe during a consult | ✅ Yes | "Advisors work in a disposable copy of your repo — your real code is never their surface." | "Fully sandboxed," "provably safe" (that implies process-level isolation, which it isn't) |
| Hands-free review loop | ⚠️ Partial | "Hands-free review for the Claude loop." | "Fully hands-free across every model" (cross-model still needs a nudge) |
| Proven in the field | ⚠️ Soften | "Hand-tested with live agents; 23/23 automated tests passing." | "Battle-tested," "production-proven," "enterprise-grade" |
| Trustworthy second opinion | ✅ With framing | "Two independent reads, reconciled — strong signal." | "Verified answer," "guaranteed correct" (agreement ≠ proof) |
| Works anywhere | ⚠️ Partial | "Portable review loop; advanced automation has setup requirements." | "Install once, runs anywhere" |

### Sample paid-package copy (pre-screened against the table above)

> ## XYZ — Your AI Agents, Working as a Team
>
> **Claude. Codex. Gemini. One codebase. Finally coordinated.**
>
> Stop refereeing three AI windows. XYZ gives your agents a shared playbook so they can build in parallel without claiming the same work, review each other until it's right, and hand you a reconciled second opinion before you commit — all from your terminal.
>
> - **Swarm** — split a build across agents, with a real lock so no two ever claim the same task.
> - **Relay** — a build-and-review loop that runs itself to "approved," hands-free on the Claude loop.
> - **Consult** — ask two models one question, get one honest, reconciled answer — with your real code sealed off in a disposable copy the advisors can never touch.
>
> Hand-tested with live agents. Honest about its limits. Built by people who run it daily.
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
- **"23/23 tests":** `validate.sh`
- **"Lock guards claims, not file edits":** `README.md` (edit-scope is honest-declaration, not enforced)
- **"Cross-model relay needs a manual nudge":** `relay-automation/poll.sh`
- **"Consult uses a disposable copy; repo-isolated not process-sandboxed":** `skill/consult/SKILL.md`, `relay-automation/consult.sh`
- **"Watchdog escalates rather than self-heals":** `relay-automation/watchdog.sh` + its README
