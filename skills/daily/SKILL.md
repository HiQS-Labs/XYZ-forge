---
name: daily
description: >
  15-minute multi-source daily work synthesizer. Monitors the operator's multi-agent
  prompt log (`0. Claude Prompts.md` / CLIO) and fuses it with Rebalance's live work signal
  (ranked next actions, calendar events, Sleuth reminders, Apple Reminders, GitHub activity)
  and device-wide git state (`collect.sh`). Appends 15-minute syntheses into deterministic daily logs at
  `temp/daily-log/YYYY-MM-DD.log`, evaluating trajectory, velocity, and adaptive coaching over the rolling
  2-hour window. Trigger on "/daily", "daily", "what am I working on", "synthesize activity",
  "daily log", "monitor prompts".
---

# Daily — Live Prompts Log + Work Signal + Git Telemetry

Continuously answers: **"What is the operator actually working on right now across all agents, repos, and systems, what is the trajectory/velocity of their work, and what actionable coaching maintains forward momentum?"**

---

## Recite this — verbatim, as the first thing in your first response

> **Daily Discipline:**
> 1. **Extract multi-agent intent signal (Step 1).** Read recent operator prompts from `0. Claude Prompts.md` / `clio_prompts` over the rolling 2-hour window across Claude, Agy, Codex, and ZCode to anchor active human directives.
> 2. **Collect live operational work signals (Step 2).** Query `get_next_actions()`, `calendar_events`, `sleuth_reminders`, and read-only Apple Reminders snapshots from the local database without external side effects.
> 3. **Scan device-wide git state & CPU health (Step 3).** Run unclosed loop and runaway CPU scanners read-only; synchronize `temp/close-the-loop.md` with in-flight worktrees, unmerged branches, open PRs, and process health.
> 4. **Evaluate 2-hour trajectory & trigger-grounded coaching (Step 4).** Assess velocity, momentum, and time-gated horizons (exactly-once Morning Retro / Monday Horizon); emit falsifiable coaching nudges strictly citing their telemetry triggers (`[Trigger: ...]`).
> 5. **Format deterministic schema & append log (Steps 5–6).** Render the standard Markdown synthesis block (Focus, Trajectory, Velocity, Horizon, Unclosed Loops, CPU Health, Coaching Nudge) and append atomically to `temp/daily-log/YYYY-MM-DD.log`.
>
> **Overall Goal:** 15-minute multi-agent work synthesis delivered with zero external mutations — fusing prompt intent, operational state, device git activity, and temporal trajectory into deterministic daily logs and trigger-cited adaptive coaching.

Then begin work.

---

## Guardrails & Principles

- **Reuse Existing Subsystems**: Do not create parallel pipelines or bespoke ad-hoc trackers. Query the resolved SQLite database (`src/rebalance/paths.py:resolve_db()`), `get_next_actions()`, `clio_prompts`, `calendar_events`, `sleuth_reminders`, Apple Reminders snapshots, and `.claude/skills/rebalance/collect.sh`.
- **Read-Only Against Repositories & External Stores**: Synthesis inspects files and SQLite tables; it never mutates git state, resets branches, alters worktrees, or writes to external stores. Apple Reminders access uses the read-only Core Data snapshot extractor with graceful degradation.
- **Deterministic Daily Logging**: Output records append to `temp/daily-log/YYYY-MM-DD.log` (gitignored under `temp/`) matching the fixed log-entry schema.
- **Debug Mantra Ground-Truth Calibration**: Never report unclosed loops, open PRs, or stalled branches from unverified memory, stale logs, or un-refreshed ledgers. Always verify against live GitHub/git state (`state == 'OPEN'`). A merged or closed PR is not an open loop. Inspect the fresh output of `scan_unclosed_loops.py` before citing telemetry.

---

## Procedure (Every 15 Minutes)

### Step 1 — Read Recent Multi-Agent Prompts (Intent Signal)
Inspect the top of `/Users/noelsaw/Documents/Noel Saw/0. Claude Prompts.md` (or query `clio_prompts` table in `rebalance.db`).
- Extract prompts within the current 2-hour window.
- Identify active repositories, tools/agents (Claude, Agy, Codex, ZCode), and explicit directives (e.g. PR reviews, feature builds, hotfixes, refactors).

### Step 2 — Read Rebalance Live Work Signal (Operational Signal)
- Call `get_next_actions()` / load ranked next actions from `rebalance.db`.
- Query upcoming calendar events for today from `calendar_events` (or trigger `rebalance calendar-sync` if needed).
- Query active Sleuth reminders (`sleuth_reminders`).
- **macOS Apple Reminders Snapshot**:
  - Invoke the read-only snapshot extractor (`src/rebalance/ingest/apple_reminders.py:extract_apple_reminders`).
  - Filter to incomplete items (`is_completed == False`).
  - Graceful degradation: If running on non-macOS or if TCC/permissions are unavailable, log a warning and proceed without failing the cycle.

### Step 3 — Scan Device-Wide Git Activity, Unclosed Loops & Machine CPU Health (Code Signal)
- Execute `python3 .agents/skills/daily/scripts/scan_unclosed_loops.py` (or `bash .claude/skills/rebalance/collect.sh`).
- Automatically updates and synchronizes `temp/close-the-loop.md` with active in-flight worktrees, un-PRed branches, and open pull requests.
- Identifies repos with `ACTIVE` or `WARM` worktrees, recent commit timestamps, unmerged branches, and dirty working trees.
- **Machine CPU Health (Runaway Scanner)**:
  - Execute `python3 .agents/skills/daily/scripts/scan_runaway_cpu.py` (sibling scanner, GH-194).
  - Flags processes pinning a core across cycles: `%CPU > 50`, duty cycle (CPU time ÷ elapsed) `> 0.5`, elapsed `> 2h`, and (same `(pid, lstart)` persisted from the previous cycle with growing CPU time **or** elapsed `> 24h`); known long-lived services (`mcp_server`, `pulse_server`, IDE helpers, system daemons) are exempt.
  - Maintains the rolling comparison state at `temp/daily-log/cpu-watch.json`. Strictly report-only — it never signals or kills a process; the flagged line carries the ready `kill` command for the operator to run (or decline).

### Step 4 — Evaluate 2-Hour Trajectory, Velocity & Cadenced Horizons

1. **2-Hour Rolling Window Analysis**:
   - Read `temp/daily-log/YYYY-MM-DD.log`.
   - **Trajectory**: Direction of focus across repos, projects, and domains.
   - **Velocity**: Rate of task completions, commit cadence, multi-agent handoff speed, resolution of blockers.
   - **Momentum**: Accelerating vs decelerating workstreams, impending context switches (calendar events, deadlines).

2. **Time-Gated Horizons (Exactly-Once Semantics)**:
   - **Local Timezone**: Evaluate against the operator's configured local timezone (e.g. `America/Los_Angeles` / PDT/PST).
   - **🌅 Morning Retrospective (Yesterday's Arc & Shutdown Continuity)**:
     - *Predicate*: Generated on the **first synthesis cycle written to `temp/daily-log/YYYY-MM-DD.log` for the day** (check if `🌅 Yesterday's Arc` is already present in today's log; if absent, generate it).
     - *Action*: Inspect `temp/daily-log/shutdown/latest.md` (or the most recent shutdown handoff) if present, along with `temp/daily-log/YYYY-MM-[yesterday].log`. Summarize yesterday's landed commits, PRs, finished arcs, and any carried-over next-session nudges in 2–3 crisp sentences.
   - **📅 Monday Weekly Horizon**:
     - *Predicate*: Generated on the **first synthesis cycle written on Mondays** (`local_time.weekday() == 0`, check if `📅 Weekly Operational Horizon` is already present in today's log; if absent, generate it).
     - *Action*: Evaluate upcoming 5-day calendar (`calendar_events` Monday–Friday) and top-ranked next actions to outline key weekly milestones, meeting load distribution, and deep work runways.

3. **Adaptive Coaching & Focus Guidance (Falsifiable Predicates)**:
   Evaluate the rolling window against these trigger rules. Every emitted coaching nudge **must explicitly cite the trigger** (e.g., `[Trigger: ...]`) to remain falsifiable:
   - **Flow State & Momentum Reinforcement**:
     - *Trigger*: $\ge 2$ consecutive 15m cycles with prompts/commits concentrated on a single repository without context-switching.
     - *Nudge*: Reinforce flow state; advise protecting the deep-work block until the current unit of work/PR is landed.
     - *Citation*: `[Trigger: N cycles focused on <repo>]`
   - **Context-Switching & Fragmentation Alert**:
     - *Trigger*: $\ge 3$ distinct repositories touched within the last 45 minutes ($T-3$ cycles).
     - *Nudge*: Warn of attention fragmentation; recommend parking secondary tasks and landing active WIP on the primary repository first.
     - *Citation*: `[Trigger: 3 repos touched in 45m: <repo1>, <repo2>, <repo3>]`
   - **Pacing & Recovery Reminders**:
     - *Trigger*: $\ge 8$ consecutive active cycles ($\ge 120\text{m}$) without an idle cycle, OR an external calendar meeting is $T-15\text{m}$ away.
     - *Nudge*: Encourage a 5-minute hydration/movement break or transition buffer before the next calendar milestone.
     - *Citation*: `[Trigger: 120m continuous execution | Meeting T-15m: <event_title>]`
   - **Friction & Blocker Escape Hatch**:
     - *Trigger*: $\ge 2$ consecutive cycles reporting test failure, error traces, or unmerged blocked state on the same task.
     - *Nudge*: Recommend dropping down to Rung 1 (`/debug-mantra`) to re-verify ground truth or invoking a quick `/consult` before further churn.
     - *Citation*: `[Trigger: Stalled task <task_id> for N cycles]`
   - **Unclosed Loops & Stalled Work Alert**:
     - *Trigger*: $\ge 1$ un-PRed branch, dangling worktree commit, or unmerged PR sitting without movement for $\ge 4$ consecutive cycles ($\ge 60\text{m}$).
     - *Nudge*: Prompt operator to close the loop (cut the PR, squash-merge, or run `/merge-cleanup`) to prevent branch drift and abandoned work.
     - *Citation*: `[Trigger: Unclosed loop <repo:branch_or_pr> stalled for N cycles]`
   - **Runaway Compute Alert**:
     - *Trigger*: The CPU-health scanner flags the same PID as a runaway candidate for $\ge 2$ consecutive cycles, or any candidate with elapsed $\ge 24\text{h}$ on its first flag.
     - *Nudge*: Name the process, its duty cycle and persistence span, and surface the ready `kill <pid>` command so the operator can stop it; never signal or kill the process yourself.
     - *Citation*: `[Trigger: PID <n> runaway for N cycles, duty <d>%]`

---

### Step 5 — Synthesize and Report (Deterministic Schema)

Format the synthesis matching this exact Markdown template:

```markdown
## [YYYY-MM-DD HH:MM TZ] — Synthesis (Cycle N)
[If First Cycle of Day]
- **🌅 Yesterday's Arc**: <2-3 sentences summarizing yesterday's achievements from previous log>

[If First Cycle of Monday]
- **📅 Weekly Operational Horizon**: <5-day outlook: key milestones, meeting load, and deep work runway>

- **Focus**: <1-2 sentences on what is actively being built or orchestrated right now across agents>
- **Trajectory (2-Hour Window: HH:MM – HH:MM TZ)**:
  - <Bullet 1: momentum, completed arcs, and direction of focus across repos>
  - <Bullet 2: swarm state across tools/agents (Claude, Agy, Codex, ZCode)>
- **Velocity**: <Nominal / High / Very High — with brief quantitative basis (e.g. commits/PRs/phases completed)>
- **Operational Horizon**: <Reconciled next 1–2 hours: upcoming calendar commitments + ranked Sleuth & Apple Reminders priorities>
- **Unclosed Loops**: <N un-PRed branches, M open PRs, K unpushed commits> `[Details: temp/close-the-loop.md]`
- **Machine CPU Health**: <0 runaway candidates, or N candidates with PID / command / duty / cycles and the ready kill command> `[Details: temp/daily-log/cpu-watch.json]`
- **Coaching Nudge**: <1-2 sentences of actionable guidance> `[Trigger: <telemetry_metric>]`
- **Model Receipt**: <model/effort, input/cached/output tokens, latency, dated list-price estimate, confidence and evidence IDs when an LLM canary produced the entry>
```

---

### Step 6 — Append to Daily Log

Append the formatted synthesis entry into `temp/daily-log/YYYY-MM-DD.log` (create file with `# Daily Activity Log — YYYY-MM-DD` header if starting a new day).
