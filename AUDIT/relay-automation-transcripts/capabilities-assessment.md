# XYZ 3-Agent Swarm — Capabilities Assessment

*Two points of view on the same system: an honest engineer's read, and a marketing read.*
*Scope: three features — **Automated Relay**, **Concurrent Swarm**, and the new **Consult** (cross-model second opinion).*
*Date: 2026-06-17.*

---

## Part 1 — Honest technical assessment

### What this actually is

A small toolkit that lets three AI coding agents — Claude Code, Codex, and Gemini — work against **one shared repo** in three different shapes of collaboration. The shared backbone is `tick`, a tiny command-line tool backed by an append-only event log under `.tick/events/` (one event = one file, so concurrent writes never collide and never need merging). Everything else is built on top of that log.

There are three distinct collaboration patterns, and they are genuinely different — not three names for the same thing.

### Feature 1 — Concurrent Swarm (`xyz` / `tick`)

**What it does:** lets 2+ agents work the *same codebase at the same time* on non-overlapping, path-scoped lanes. Each agent "claims" a task and declares which file globs it will touch. A per-repo lock (`O_EXCL`) serialises claims into a real mutex, so when two agents grab the same task simultaneously, exactly one wins — no tie-breaker guessing. Agents send heartbeats (`tick ping`) so the system can tell a live claim from a stalled one, and `tick analyze` reports an honest **concurrency metric** (how much time agents actually overlapped) plus per-agent activity counts.

**Maturity:** the most mature of the three. 12 acceptance tests pass (`./validate.sh`), and it has been hand-tested with real agents (results in `REAL-AGENT-OBSERVATIONS.md`).

**Honest limits:**
- **Best for parallel work, not constant handoff.** It shines when work splits into clean lanes that *don't* touch shared files. Work that needs agents constantly editing the same files or handing off every few minutes is the wrong fit.
- **Coarse commit attribution in the shared-tree setup.** A single working tree has one git identity at a time, and that identity was seen flipping between agents during testing. The `--agent` field in the event log is the reliable record of who did what; git-author-level attribution is acknowledged as a soft spot and future work.
- **Coordination is local, not networked.** All agents must point at the same local `.tick/` directory. This is deliberate (it removes the per-event git push/pull friction of earlier versions) but means it's not built for agents on separate machines or async sessions.

### Feature 2 — Automated Relay (`relay` + `relay-automation`)

**What it does:** runs a turn-based **Producer ↔ Reviewer** loop in a shared file. One agent builds, the other critiques and proposes fixes, and the loop repeats until the reviewer says "Approved" — so a human stops copy-pasting output back and forth between two AI windows. The portable `/relay` skill is dependency-free (just files); the `relay-automation` sibling adds the hands-free machinery on top of `tick`:
- a **poll driver** that advances turns automatically,
- a **watchdog** that detects and recovers from stalls,
- a **verdict-gated runner** (turns must emit `PASS` / `FAIL` / `PARKED`),
- and a **headless cross-model turn-taker** so Codex can take its turn non-interactively (`codex exec`), enabling a Claude↔Codex relay with no human in the middle.

**Maturity:** solid and tested — its own test suite (`poll-driver`, `poll-relay`, `watchdog-relay`, `codex-turn`) rides in `validate.sh`. The headless Codex turn is wired and working; the full cross-model auto-relay is the active build frontier.

**Honest limits:**
- **`relay-automation` is not portable.** It depends on a `tick` runtime with a specific capability (handoff-exclusive claims). It even ships a capability *gate* that refuses to run on a `tick` that's too old — which is the honest move, but it means setup matters. The plain `/relay` skill *is* portable; the automation layer is not.
- **Convergence isn't guaranteed.** A relay loops until "Approved." There are round-caps and no-progress escalation to stop runaway loops, but a poorly framed task can still churn.

### Feature 3 — Consult (new — cross-model second opinion)

**What it does:** asks the *same question* to Codex and Gemini **in parallel**, then has Claude reconcile the two answers into one — surfacing where the models **agree**, where they **disagree**, and giving a single reconciled call. It's the fast "ask the other brains before I commit" move for a decision, a design, or a doc. It runs **exactly once** (not a loop) and **writes nothing** to your code — it's advisory only.

**The safety design is the strongest part.** Advisors don't run against your real files. The tool checks out a **throwaway git worktree** from your current working state (including uncommitted and brand-new files), and the advisors run *there*. Anything they write is destroyed with the worktree. So even if an advisor ignores the "don't touch anything" instruction, your real repo is never the surface — there's nothing to revert. (This replaced an earlier, weaker "revert afterward" approach that the skill's own first dogfood flagged as unsafe — a good sign the project tests its own claims.)

**Maturity:** newest of the three, but already test-covered (`test/consult.sh`: WIP preservation, no advisor leak, graceful degrade, non-git refusal) and self-dogfooded twice.

**Honest limits:**
- **Two models, not ground truth.** Cross-model agreement raises confidence; it does not prove correctness. Both models can share the same blind spot. A unanimous answer is *strong signal*, not proof — especially for anything that depends on actually running the code, which neither model does.
- **Repo-isolated, not process-sandboxed.** Your repository is safe. The host process is not fully sandboxed — Gemini in particular can still reach the network and the host outside the worktree. For a hard process boundary you'd run consult inside your own sandbox.
- **Repo-local, not portable.** Hard-depends on the `codex` and `gemini` CLIs being installed and authed, plus the `relay-automation` shims. Unlike the portable `/relay`, you can't lift consult out and drop it into an arbitrary repo.
- **Cost tracking is partial.** Token/cost capture is opt-in for Gemini and not yet wired for Codex.

### The honest one-paragraph summary

This is a **working beta**, not a finished product. The core (`tick` + the concurrency model) is well-tested and the design choices are unusually honest — failures degrade gracefully and are *stated*, safety boundaries are precise about what they do and don't protect, and the project visibly tests its own claims and revises them when a dogfood run proves them wrong. The main caveats are real and disclosed: commit-level attribution is coarse, the automation and consult layers are repo-local rather than portable, and "cross-model agreement" is signal, not proof. The three features are genuinely distinct tools — swarm for parallel building, relay for iterative review-to-convergence, consult for a one-shot second opinion — and knowing which to reach for is the actual skill.

---

## Part 2 — Marketing assessment (the positive read)

### The pitch

**Three AI coding agents. One repo. Zero collisions. You stay in the chair.**

Claude, Codex, and Gemini don't have to be three browser tabs you babysit. XYZ turns them into a **coordinated team** that works the way real teams do — sometimes splitting the work, sometimes reviewing each other, sometimes just giving you a second opinion before you commit.

### Three ways to put three minds to work

**🛠 Swarm — build in parallel, never collide.**
Point all three agents at the same repo and let them go. Each one claims its own lane, and a real lock guarantees no two agents ever stomp the same files. You get an honest read on how much they actually worked in parallel — not a vanity number. *Three engineers, one repo, no merge hell.*

**🔁 Relay — a build-and-review loop that runs itself.**
One agent builds, another reviews and hands back fixes — automatically, in a shared file, until the work is approved. No more copy-pasting between windows. A built-in watchdog notices if a turn stalls and gets things moving again. *Pair programming between AIs, hands-free.*

**🧭 Consult — a second opinion in one shot.**
About to commit to a design, a schema, or a tricky decision? Ask Codex and Gemini the same question at once and get back a single reconciled answer that **shows its work** — where the two models agreed, where they split, and which way to go. And it's **provably safe**: the advisors run in a sealed-off copy of your repo and can never touch your real code. *Two expert opinions, reconciled, before you bet on anything.*

### Why it's different

- **Collision-proof by design** — a real mutex, not "hope they don't overlap."
- **Honest by default** — when something degrades, it tells you. No silent failures, no laundered consensus.
- **Your code is never at risk in a consult** — advisors work in a disposable copy, full stop.
- **Pick the right shape of collaboration** — parallel building, iterative review, or a one-shot gut-check.

### A marketing message for a paid repo package

> ## XYZ — Your AI Agents, Working as a Team
>
> **Claude. Codex. Gemini. One codebase. Finally coordinated.**
>
> Stop refereeing three AI windows. XYZ gives your agents a shared playbook so they can build in parallel without colliding, review each other's work until it's right, and give you a reconciled second opinion before you commit — all from your terminal.
>
> - **Swarm** — split a build across all three agents on collision-proof lanes.
> - **Relay** — a hands-free build-and-review loop that converges on its own.
> - **Consult** — ask two models one question, get one honest, reconciled answer — with your real code sealed off and untouchable.
>
> Battle-tested with real agents. Honest about its limits. Built by someone who actually runs it.
>
> **Get the XYZ toolkit → coordinate your agents today.**

*(Marketing-honesty note for internal use: keep claims tied to what's tested. "Collision-proof" and "your code is sealed off in a consult" are defensible — they're enforced by a lock and a throwaway worktree. Soften or qualify "battle-tested" to "hand-tested with real agents" and avoid implying the relay/consult layers are portable or that cross-model agreement equals correctness — those are the honest caveats from Part 1.)*

---

## How to read these two parts together

Part 1 is what you'd tell a fellow engineer evaluating whether to adopt it. Part 2 is what you'd put on a landing page. The gap between them is small and that's the point — the marketing claims that survive Part 1's scrutiny ("collision-proof," "your code is sealed off," "honest about failures") are the ones worth leading with. The claims to *avoid* are the ones Part 1 flags: portability, full process sandboxing, and any suggestion that two agreeing models are necessarily *right*.
