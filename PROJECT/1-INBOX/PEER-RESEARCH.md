# XYZ Multi-Agent Coordination — Competitive Analysis Dashboard

> Beta snapshot · July 2026  
> Benchmarked against: **MiMo Code v0.1.0** · **Traycer v2.9.x** · **Omnigent alpha (Databricks)**

---

## 1. Competitive Landscape Map

### 1.1 Tier Classification

| Tool | Tier | Problem domain | Approach summary |
|---|---|---|---|
| **XYZ** | Direct | Multi-agent repo coordination | Kernel-level collision-free work-claiming (`tick` + O_EXCL lock) + turn-based relay across Claude Code / Codex / agy |
| **MiMo Code** | Direct | Long-horizon single-agent + subagent orchestration | Cross-session SQLite memory + parallel checkpoint-writer subagent; fork of OpenCode |
| **Traycer** | Direct | Outer-loop planning / verification layer over coding agents | Multi-model ensemble (Sonnet-4.5 for planning, GPT-5.1 for verification); phase-gated tasks; YOLO autonomous loop |
| **Omnigent** | Direct | Meta-harness: governance + composition across agent runtimes | YAML-configured orchestration above Claude Code, Codex, Pi; policy enforcement + live session sharing; built-in Polly multi-agent coordinator |

### 1.2 Positioning Map

```
                    REPO COORDINATION ←————————→ SESSION MANAGEMENT
                           │                              │
      Governance/           │                              │
      Control-first:        │           Omnigent           │
                            │      (policy enforcement     │
                            │       + team collab)         │
                            │                              │
      Kernel/               │                              │
      Concurrency-first:    │    XYZ (tick kernel)         │
                            │    collision-free claims     │
                            │    file-scoped locking       │
                            │                              │
      Outer-loop            │                              │
      Planning-first:       │          Traycer             │
                            │    (plan/verify ensemble)    │
                            │                              │
      Memory/               │                              │
      Continuity-first:     │                   MiMo Code  │
                            │                   (SQLite FTS5│
                            │                   4-layer mem)│
```

**Axes summary:**
- **XYZ** owns the local-kernel / zero-dependency coordination quadrant — no server, no remote API, O_EXCL locking for true write-safety.
- **Omnigent** owns enterprise governance + team collaboration (OIDC, policy engine, spend caps, shared sessions).
- **Traycer** owns the outer-loop orchestration + human-in-the-loop phase management (Kanban board, phase-gated verification).
- **MiMo Code** owns long-horizon single-process continuity through the strongest published memory architecture.

---

## 2. Feature Comparison Matrix

> Ratings: **Strong** / **Adequate** / **Weak** / **Absent**

### 2.1 Agent Coordination Architecture

| Criterion | XYZ | MiMo Code | Traycer | Omnigent |
|---|---|---|---|---|
| **Simultaneous multi-agent on same repo** | **Strong** — O_EXCL path-scoped claims prevent concurrent writes; agents queue by claim | Adequate — parallel subagents share session context but no file-locking primitive | Adequate — multiple agents via phases, not concurrent file writers | Weak — worktree-per-agent via Polly but no kernel-level collision prevention |
| **Agent provider flexibility** | Strong — Claude Code, Codex, agy (Antigravity); custom relay per provider | Strong — any OpenAI-compatible API; Claude, DeepSeek, Kimi, GLM, Ollama | Strong — Claude Code, Codex, Cursor, OpenCode, Cline, Copilot | Strong — Claude Code, Codex, Pi, custom agents; swap with one-line YAML change |
| **Zero-dependency local operation** | **Strong** — no server, no API keys for coordination kernel (`./validate.sh` runs clean) | Adequate — local SQLite; model API key still required | Weak — cloud-backed planning and verification ensemble; requires Traycer subscription | Weak — server mode is primary path; standalone runner available but limited |
| **Turn-based build→review relay** | **Strong** — explicit relay loop: builder agent → reviewer agent; Marathon chains phases | Adequate — Compose mode chains planning/exec/review but single primary agent | Strong — phase-gated pipeline with handoff and re-queue on failure | Adequate — Polly does cross-vendor review but YAML-configured, not file-relay |
| **Event log / auditability** | Strong — `.tick/events/` append-only log; `STATE.md` projection | Adequate — SQLite history trace; per-task progress logs | Adequate — Kanban task board; phase verification logs | Strong — full trajectory audit; OIDC event log; policy evaluation records |

### 2.2 Long-Horizon Task Performance

| Criterion | XYZ | MiMo Code | Traycer | Omnigent |
|---|---|---|---|---|
| **200+ step task completion** | Strong — Marathon chains unlimited phases via `depends_on`; relay loop designed for indefinite iteration | **Strong** — core design goal; >65% win rate vs Claude Code past 200 steps (Xiaomi internal, n=576) | Adequate — Phases Mode + YOLO loop; practical limit tied to agent context window | Adequate — relies on underlying agent context management; no custom memory layer |
| **Context window management** | Adequate — relay handoff via files sidesteps context limits; no explicit compaction | **Strong** — 4-layer SQLite memory; checkpoint-writer subagent at 20%/45%/70% window budget; context rebuild < 65K tokens | Adequate — outer-loop summaries; depends on model ensemble for compression | Weak — no published memory management layer; relies on agent-native context handling |
| **Cross-session memory** | Weak — no persistent memory layer; `.tick/STATE.md` tracks coordination state only | **Strong** — MEMORY.md (project), checkpoint.md (session), tasks/ (per-task), SQLite FTS5 history | Adequate — task history persists in workspace; no project-level knowledge graph | Weak — policy state persists; agent memory is per-session unless model supports it |
| **Task tree / dependency tracking** | Strong — `MARATHON.yaml` with `depends_on` ordering; swarm-preflight planner | Strong — tree-shaped task system (T1, T1.1, T1.2…); checkpoint-integrated | Strong — Kanban phases with dependencies and blocked states | Adequate — YAML task decomposition; no explicit dependency graph primitive |

### 2.3 Error Recovery

| Criterion | XYZ | MiMo Code | Traycer | Omnigent |
|---|---|---|---|---|
| **Stale-claim / lock recovery** | **Strong** — O_EXCL ensures no orphaned locks; event log survives crashes | Adequate — checkpoint.md written pre-crash; session resume from last checkpoint | Adequate — phase re-queue on verification failure; no crash-safe lock primitive | Adequate — sandboxed execution; policy violations halt (not crash) agent |
| **Automated retry loops** | Strong — relay-automation watchdog; auto-handback on review failure | Strong — `/goal` command with independent judge model prevents premature stop | **Strong** — YOLO mode: autonomous plan→code→verify→fix loop without manual clicks | Adequate — policy violations trigger configurable callbacks, not auto-retry |
| **Error memory / anti-recurrence** | Weak — no error knowledge base; agents may repeat mistakes | **Strong** — error memory layer in SQLite; errors + fixes persisted; `/dream` deduplicates | Adequate — verification failure is logged per phase; no cross-session error learning | Weak — no error memory layer; policy violations logged but not fed back to agent |
| **Agent crash / timeout handling** | Strong — watchdog in relay-automation; claim TTL prevents indefinite locks | Adequate — checkpoint state survives crash; resume requires manual re-invocation | Adequate — phase watchdog; stuck phases can be manually re-queued | Adequate — cloud sandbox isolation; dead agents are terminated, not auto-resumed |

### 2.4 Interoperability & Ecosystem

| Criterion | XYZ | MiMo Code | Traycer | Omnigent |
|---|---|---|---|---|
| **MCP server support** | Absent (not documented) | Strong — inherited from OpenCode; full MCP protocol | Adequate — via connected agent (Claude Code + MCP) | Adequate — via wrapped agent runtimes |
| **Install portability** | **Strong** — `install.sh` drops tick into any repo; `~/.config/xyz/registry.tsv` tracks installs | Strong — npm global install; `mimocode.json` per project | Weak — VS Code extension primary; workspace scoping helps | Adequate — `npm install -g omnigent`; project-level YAML config |
| **Team / multiplayer** | Weak — single-machine, single git worktree model | Weak — local-first; no shared session support | **Strong** — multiplayer workspaces; teammates comment on artifacts; shared context | **Strong** — live session sharing via URL; OIDC multi-user; team spend controls |
| **HQ / multi-repo management** | Strong — HQ command center (`hq.sh`); fuzzy project resolution; Rebalance integration | Absent | Absent | Absent |
| **License** | (private/beta) | MIT | Proprietary SaaS | Apache 2.0 |

---

## 3. Strategic Positioning Analysis

### XYZ — Where It Wins
**Unclaimed position:** XYZ is the only tool with a kernel-level, file-system-native, zero-server coordination primitive. Every other tool layers coordination on top of existing agent context or YAML configuration. XYZ's `O_EXCL`-based work-claiming is a genuinely different mechanism — it's closer to a filesystem mutex than an orchestration framework.

**Differentiators:**
- No API dependency for coordination (competitors require at minimum a model call to coordinate)
- HQ multi-repo command center — no competitor has a project-spanning operator surface
- `swarm-preflight` intake pipeline (freshness gates, readiness checks, marathon planning)
- Headless relay with explicit build→review handoff produces a traceable review transcript

**Vulnerable positions:**
- Cross-session memory is entirely absent — MiMo Code has a substantial lead here
- No published benchmark scores — makes external validation conversations difficult
- Single-machine scope limits enterprise / team use cases vs. Omnigent and Traycer multiplayer

### MiMo Code — Threat Level: HIGH (for long-horizon workloads)
Open-source (MIT), free model included, 4.1K GitHub stars in one day. The memory architecture is the best-published solution to context-window collapse on 200+ step tasks. Xiaomi's benchmark claims (SWE-bench Verified 82% vs 79%, SWE-bench Pro 62% vs 55%, Terminal Bench 2 73% vs 69%) are self-reported but directionally credible given the architectural specificity.  
**Key risk:** If XYZ users are doing long single-agent tasks, MiMo Code is a straight drop-in substitute with better continuity.

### Traycer — Threat Level: MEDIUM (for teams wanting managed outer-loop)
Traycer v2.8+ now wraps Claude Code / Codex / Cline with a planning ensemble — it is becoming an outer-loop that could absorb XYZ's relay function for teams that want a GUI. YOLO Mode directly competes with Marathon's headless relay. Traycer's multi-model ensemble (Sonnet for planning, GPT-5.1 for verification) is a differentiated architectural bet; Traycer charges for the coordination layer, not inference.

### Omnigent — Threat Level: MEDIUM-HIGH (for enterprise / governance)
Databricks' provenance means enterprise buy-in, SOC2 pathway, and existing Databricks customer relationships. Polly's git-worktree-per-agent pattern overlaps directly with XYZ's concurrent-agents goal. Apache 2.0 license removes lock-in concern. Primary gap vs. XYZ: no kernel-level collision prevention, no file-locking primitive, and no multi-repo HQ layer.

---

## 4. Evaluation Rubric — Clean-Room Review

### 4.1 Principles

1. **No shared state between tool runs** — fresh git clone or worktree for each test case.
2. **Deterministic tasks** — use public repos with known, verifiable pass/fail criteria (test suite green = pass).
3. **Record tool-call traces** — capture agent event logs, `.tick/events/`, or equivalent per tool.
4. **Blind scoring where possible** — score outputs before identifying which tool produced them.
5. **Replicate three times** — use ClawEval's Pass³ principle: a task only counts as solved if it passes all three independent runs.

### 4.2 Scoring Dimensions

Each test case is scored across six dimensions (0–5 scale):

| Dimension | What it measures | Scoring anchor |
|---|---|---|
| **Task Completion Rate (TCR)** | Did the agent complete the stated acceptance criteria? | 5 = all criteria green; 0 = regression or incomplete |
| **Tool-Call Stability (TCS)** | Were tool calls deterministic, non-redundant, and non-looping? | 5 = no spurious calls; 0 = infinite loop or crash |
| **Context Continuity (CC)** | Did the agent correctly recall prior state mid-task? | 5 = flawless recall; 0 = lost context, restarted from scratch |
| **Error Recovery Quality (ERQ)** | On deliberate fault injection, did the agent diagnose and fix? | 5 = root-cause identified and fixed; 0 = gave up or hallucinated fix |
| **Collision Safety (CS)** | Did multiple agents produce a coherent, non-conflicting diff? | 5 = clean merge; 0 = conflict, data loss, or silent overwrite |
| **Latency / Step Efficiency (LSE)** | Step count and wall-clock time to task completion | 5 = within 20% of human baseline; 0 = >5x human baseline |

**Composite score:** `(TCR × 2 + TCS + CC + ERQ + CS × 2 + LSE) / 9` (TCR and CS double-weighted as primary safety properties)

---

## 5. Clean-Room Test Suite

### Category A — Single-Agent Agentic Autonomy (baseline)
*Tests each tool's single-agent loop before adding coordination complexity. Used to isolate coordination overhead.*

#### A-1: Isolated Bug Fix (SWE-bench–style)
- **Repo:** `pallets/flask` (pinned release tag)
- **Input:** GH issue description only (no patch hints)
- **Pass criteria:** Existing test suite green; no regressions
- **Relevant benchmark:** SWE-bench Pro public set (for calibration)
- **Coordination pressure:** Low — single agent, no concurrency
- **What to observe:** TCR, TCS, LSE

#### A-2: Multi-File Feature Addition (RoadmapBench–style)
- **Repo:** Any mature OSS project with a tagged minor release
- **Input:** Release notes for the next minor version; agent must implement described behavior
- **Pass criteria:** Target version test suite green; median change ~3,700 lines across 21 files
- **Relevant benchmark:** [RoadmapBench](https://arxiv.org/html/2605.15846v1) (median oracle: 3,700 lines, 51 files)
- **Coordination pressure:** Medium — single agent, long horizon
- **What to observe:** TCR, CC, LSE; especially context-window collapse behavior

#### A-3: 200+ Step Autonomous Task
- **Repo:** Private test repo (prevents benchmark contamination)
- **Input:** Migration spec: "Refactor the auth module from session-based to JWT; update all callers; maintain test coverage above 90%"
- **Pass criteria:** Test suite green; no pre-existing test deleted; coverage gate met
- **Coordination pressure:** High — single-agent, long horizon
- **What to observe:** CC (context continuity under pressure), TCS (tool call loops), ERQ

---

### Category B — Multi-Agent Coordination Stress Tests

#### B-1: Parallel Non-Overlapping Workstreams
- **Setup:** Two agents assigned to non-overlapping modules (e.g., `src/auth/` vs `src/billing/`)
- **Task:** Both implement independent feature specs concurrently; merge at end
- **Pass criteria:** Clean merge; all tests green; no cross-module interference
- **Fault injection:** After 50 steps, introduce a shared dependency update in `package.json`
- **What to observe:** CS (collision safety) — does the coordination layer prevent or detect the conflict?

#### B-2: Deliberate Overlap Attack
- **Setup:** Two agents assigned the *same* file path
- **Task:** Both try to edit `src/utils/date.ts` simultaneously
- **Pass criteria:** Tool should serialize access; only one agent edits at a time; no silent data loss
- **Expected XYZ behavior:** `tick` O_EXCL claim blocks second agent until first releases
- **Expected failure mode for others:** Silent overwrite or merge conflict in working tree
- **What to observe:** CS, TCS

#### B-3: Build→Review Relay Under Fault Injection
- **Setup:** Standard relay: Agent A builds, Agent B reviews
- **Fault injection:** Introduce a deliberate security vulnerability (hardcoded credential) in Agent A's output
- **Pass criteria:** Agent B's review detects and flags the vulnerability; relay halts or triggers fix loop
- **What to observe:** ERQ, TCR

#### B-4: Marathon / Long Phase Chain
- **Setup:** 5-phase Marathon (or equivalent): spec → scaffold → implement → test → review
- **Task:** Build a small CRUD REST API from a spec document
- **Fault injection at phase 3:** Introduce a breaking schema change to the spec mid-run
- **Pass criteria:** System detects dependency invalidation; re-plans or halts cleanly rather than silently continuing with stale spec
- **What to observe:** ERQ, CC, TCS

---

### Category C — Error Recovery Loops

#### C-1: Test-Failure Loop (TDD Stress)
- **Setup:** Provide agent with a failing test suite (red state intentional)
- **Task:** Make all tests green without deleting tests
- **Loop injection:** After each "fix," re-run suite; if agent passes by deleting tests, penalize ERQ to 0
- **Target:** Agent should converge in ≤ 10 iterations without human intervention
- **What to observe:** ERQ, TCS (tool-call stability in loop), TCR

#### C-2: Crash / Timeout Recovery
- **Setup:** Kill the agent process mid-task (after ~30 tool calls)
- **Task:** Resume and continue to completion without repeating completed work
- **Pass criteria:** Final output is correct; ≤ 5 duplicate tool calls after resume
- **What to observe:** CC (state recovery), TCS

#### C-3: Hallucinated Tool Output Injection
- **Setup:** Intercept one tool call response and replace it with plausible-but-wrong output (e.g., wrong file contents)
- **Task:** Agent must complete the original task correctly despite one corrupt tool response
- **Pass criteria:** Agent either detects inconsistency and re-reads, or final output is still correct
- **What to observe:** ERQ, TCS

---

### Category D — API-Provider Flexibility

#### D-1: Provider Swap, Same Task
- **Task:** Run test case A-1 three times: once with Claude, once with GPT-5.x, once with DeepSeek
- **Pass criteria:** Tool's coordination/memory layer produces consistent task completion regardless of underlying model
- **What to observe:** TCR variance across providers; does the harness abstract provider differences?

#### D-2: Model Downgrade Stability
- **Task:** Run B-4 with a weaker model (e.g., Sonnet-4.5-mini class) vs. flagship
- **Pass criteria:** Coordination layer compensates (more checkpoints, tighter task decomposition); total TCR drops < 20%
- **What to observe:** How much of task completion is in the harness vs. the model?

---

## 6. Benchmark Mapping

### 6.1 Which Benchmarks to Report Against

| Benchmark | Coverage | Why relevant to XYZ | Notes |
|---|---|---|---|
| **[SWE-bench Pro](https://openreview.net/forum?id=9R2iUHhVfr)** | 1,865 tasks; 107-line avg patch; 41 repos | Closest public proxy for real engineering tasks; MiMo Code and Traycer report against it | SWE-bench Verified is saturated (80%+ scores reflect benchmark contamination, not capability) |
| **[SWE-EVO](https://arxiv.org/html/2512.18470v6)** | 48 release-sized tasks; avg 21 files | Best existing long-horizon benchmark; tests exactly the 200+ step scenario XYZ targets | Best current model scores only 25%; high signal at scale |
| **[RoadmapBench](https://arxiv.org/html/2605.15846v1)** | 115 tasks; median 3,700-line oracle; 51 files | Tests full-release implementation from spec — directly matches Marathon use case | Even Claude Opus 4.7 scores only 39.1% |
| **[Claw-Eval](https://arxiv.org/abs/2604.06132)** | 300 tasks; 2,159 rubrics; Pass³ scoring | Full-trajectory auditing with embedded safety constraints; closest to XYZ's coordination safety claim | Published April 2026; MIT license; 3 evidence channels (traces, audit logs, env snapshots) |
| **[AgencyBench](https://arxiv.org/pdf/2601.11044)** | 138 tasks; avg 90 tool calls; 1M token context | Tests long-horizon agentic capability with real tool access; tool-call stability dimension | Best proxy for TCS metric |
| **[WildClawBench](https://arxiv.org/html/2605.10912)** | 60 tasks; avg 20+ tool calls; Docker containers | Native-runtime evaluation — harness choice shifts scores by up to 18 points | Directly measures harness contribution vs. model contribution |

### 6.2 Benchmark Selection Rationale for XYZ

XYZ's primary claim is **coordination safety** (no silent overwrites) + **long-horizon relay completion**. The most honest benchmarks to run are:

1. **WildClawBench** — because it isolates harness contribution from model contribution (the 18-point harness swing is directly relevant to XYZ's value proposition)
2. **SWE-bench Pro (commercial set)** — because the private enterprise tasks have internal conventions that stress cross-session memory, which is XYZ's current gap
3. **Custom Collision Safety metric (B-2 above)** — no existing benchmark tests concurrent-write collision prevention; this is XYZ's unique claim and should be a custom benchmark

### 6.3 Benchmark Anti-patterns to Avoid

- **SWE-bench Verified** — saturated; top models >80%; no differentiation signal
- **Self-reported surveys** (as MiMo Code used) — useful for directional framing; not credible for external claims without replication
- **Single-run scores** — use Pass³ (run 3×; count only tasks solved all 3 times) per Claw-Eval methodology to eliminate lucky-run inflation

---

## 7. XYZ Roadmap Gaps (Prioritized by Competitive Risk)

| Gap | Competitive exposure | Recommended fix |
|---|---|---|
| **Cross-session memory** | MiMo Code has a 4-layer SQLite architecture; XYZ has none | Add a `STATE.md` promotion layer: checkpoint-writer subagent that persists relay decisions, reviewed code summaries, and error patterns across marathon runs |
| **Benchmark scores** | Can't cite external validation in external conversations | Run SWE-bench Pro (public set) and WildClawBench against XYZ + Claude Code / Codex relay; publish scores with methodology |
| **Team / multiplayer** | Omnigent and Traycer both have shared session URLs; XYZ is single-machine | HQ already tracks multi-repo; add a read-only relay session broadcast (audit log over SSH or webhook) as a near-term multiplayer primitive |
| **MCP support** | MiMo Code inherits full MCP from OpenCode; XYZ is silent on MCP | Evaluate tick as an MCP server: expose `claim`, `release`, `status` as MCP tools so any MCP-compatible agent can participate in coordination |
| **Error memory** | MiMo Code persists errors + fixes; XYZ agents may repeat mistakes across marathon phases | Add an `ERRORS.md` parallel to `STATE.md`; relay reviewer writes error observations; subsequent build phases receive it as context |

---

## 8. Quick-Reference Summary Card

```
┌──────────────────────────────────────────────────────────────────────┐
│  XYZ vs. THE FIELD — JULY 2026                                       │
├─────────────────────┬────────┬──────────┬─────────┬──────────────────┤
│ Criterion           │  XYZ   │ MiMo Code│ Traycer │    Omnigent      │
├─────────────────────┼────────┼──────────┼─────────┼──────────────────┤
│ Concurrent agents   │ ●●●●●  │  ●●●     │  ●●●    │  ●●●             │
│ 200+ step tasks     │ ●●●●   │  ●●●●●   │  ●●●    │  ●●              │
│ Cross-session memory│ ●      │  ●●●●●   │  ●●     │  ●               │
│ Error recovery      │ ●●●●   │  ●●●●●   │  ●●●●   │  ●●              │
│ Provider flexibility│ ●●●●   │  ●●●●●   │  ●●●●   │  ●●●●●           │
│ Zero-dependency ops │ ●●●●●  │  ●●●     │  ●      │  ●●              │
│ Team/multiplayer    │ ●      │  ●       │  ●●●●●  │  ●●●●●           │
│ Multi-repo HQ       │ ●●●●●  │  ●       │  ●      │  ●               │
│ Governance/policy   │ ●●     │  ●●      │  ●●●    │  ●●●●●           │
│ Open source         │ (beta) │  MIT     │  No     │  Apache 2.0      │
└─────────────────────┴────────┴──────────┴─────────┴──────────────────┘
● = Absent  ●● = Weak  ●●● = Adequate  ●●●● = Strong  ●●●●● = Leading
```

---

## 9. Sources

- [MiMo Code GitHub — XiaomiMiMo/MiMo-Code](https://github.com/XiaomiMiMo/MiMo-Code) (MIT, June 2026)
- [Xiaomi MiMo Code long-horizon technical blog](https://mimo.xiaomi.com/blog/mimo-code-long-horizon) — official architecture writeup
- [Omnigent GitHub — omnigent-ai/omnigent](https://ithub.global.ssl.fastly.net/omnigent-ai/omnigent) (Apache 2.0, June 2026)
- [Omnigent built-in agents docs](https://omnigent.ai/docs/use/builtin-agents) — Polly and Debby spec
- [Traycer multi-model architecture blog](https://traycer.ai/blog/multi-model-architecture) (Feb 2026)
- [Traycer changelog](https://traycer.ai/changelog) — v2.6–v2.9 feature history
- [Claw-Eval paper — arXiv:2604.06132](https://arxiv.org/abs/2604.06132) (April 2026)
- [SWE-EVO — arXiv:2512.18470v6](https://arxiv.org/html/2512.18470v6) (May 2026)
- [RoadmapBench — arXiv:2605.15846v1](https://arxiv.org/html/2605.15846v1)
- [SWE-bench Pro — OpenReview ICLR 2026](https://openreview.net/forum?id=9R2iUHhVfr)
- [AgencyBench — arXiv:2601.11044](https://arxiv.org/pdf/2601.11044)
- [WildClawBench — arXiv:2605.10912](https://arxiv.org/html/2605.10912)
- [Long-Horizon Gap analysis — agentmarketcap.ai](https://agentmarketcap.ai/blog/2026/04/11/long-horizon-codebase-agents-full-repo-autonomy-2026) (April 2026)
- [SWE-bench saturation analysis — tianpan.co](https://tianpan.co/blog/2026-04-09-agentic-coding-production-swebench-gap) (April 2026)
