# XYZ — Multi-Agent Coordination Beta

**XYZ lets several AI coding agents — Claude Code, Codex, and agy (Google's Antigravity CLI) — work
on the same repo at the same time without overwriting each other's work.**

## What XYZ is

It's built in two layers:

- **`tick`** — the kernel: a tiny local event-log CLI that hands out collision-free, path-scoped
  work claims, so two agents never edit the same thing at once. No server, no API keys, no remote.
- **`relay-automation/`** — the product on top of `tick`: it runs agents in **turns** (one builds,
  another reviews) headlessly, so you can hand a task to Codex or agy and let them iterate toward
  done without babysitting the handoff.

It's a working beta, not a polished product — but the kernel is test-covered and the relay stack
is the main active surface.

## Quickstart — prove it works (no accounts needed)

Requires **Node 18+** and **git** (the `tick` kernel runs on Node). No accounts or API keys.

```bash
npm install
npm run test:unit          # ~1 second — fast proof the kernel logic itself is sound
bash githooks/install.sh   # contributors: wires the pre-push gate (correctness requirement)
./validate.sh              # the full suite — see timing note below before you run this
```

(`npm install` pulls the two parser dependencies the test suite needs — skip it and the
suite stops at `Cannot find module 'acorn'`.)

**If you are going to push to this repo, run `bash githooks/install.sh` once per clone. It is a
correctness requirement, not optional setup.** The local gate catches failures before a push; hosted
CI independently checks public-repo changes afterward. The hook lives in `.git/hooks/`, which does
not travel with a clone, so skipping this step removes the early boundary even though hosted CI may
still run later. One run covers every branch and linked worktree of that clone (GH-549).
`./validate.sh` itself warns, in-band, if this clone is ungated — check
directly any time with `bash githooks/install.sh --check`. (Just evaluating the project and never
pushing? The warning is informational only — `validate.sh` still runs and exits exactly as it
would gated.)

That runs the full kernel + coordination test suite, with **no accounts or API keys required** —
the fastest proof the coordination kernel actually works. It's the whole suite, not a smoke test,
so **budget 5–10 minutes** on a first run — that figure assumes parallel mode. `validate.sh` forces
sequential below 4 cores, where a full run measured ~13 minutes; run `./validate.sh --print-mode` to
see which mode your machine picks and why. The suite prints its own pass count at the end; if it's
green, you're good.

> **⚠️ Run this un-sandboxed.** Under Claude Code's default Bash sandbox — or any sandboxed agent
> harness — this command prints **nothing for several minutes** before failing, because the suite's
> `mktemp -d` scratch directories are blocked. It looks like a hang, not a permissions error, and
> it is this repo's single most common false alarm. Turn the sandbox off for this command
> (`/sandbox` in Claude Code, or run it yourself in a normal terminal) before concluding anything
> is broken.

## Then pick your path

- **New here for the beta test?** → start at [Beta Tester Onboarding](#beta-tester-onboarding) below.
- **Run a live relay** — hand a real task to Codex/agy and let them build→review it →
  start at **[relay-automation/README.md](relay-automation/README.md)**. Live turns need each CLI
  installed and authenticated first: see
  **[Set up Codex, agy, and Pi](relay-automation/README.md#set-up-codex-agy-and-pi-headless-bring-up)**.
  For phase/status context, the project hub is
  [PROJECT/4-MISC/AUTOMATED-RELAY.md](PROJECT/4-MISC/AUTOMATED-RELAY.md).
- **Connect live agent sessions by a short ID** — start a serialized discussion with two or more
  Claude, Codex, or other skill-aware sessions → see [AgentChorus](#agentchorus--live-sessions-by-compact-id).
- **Here for the kernel** — how the `tick` coordination primitive works →
  read [What `tick` is](#what-tick-is), then the source in [bin/tick](bin/tick), [src/](src), [test/](test).
- **Install `tick` into another repo** → see [Install into another repo](#install-into-another-repo).

> **Editing this repo as an agent?** Read [ROUTER.md](ROUTER.md) for the startup order and canonical
> entry points. It's the map for *working on* the repo, not for *using* it — a human landing here
> should start with the Quickstart above.

---

> **⏳ Beta-testing period:** the onboarding guide below runs for the duration of the beta. Once the
> beta wraps, this section moves out and the README continues straight from
> [What XYZ is](#what-xyz-is) above. Historical design discussion: legacy source issue #123.

## Beta Tester Onboarding

**TL;DR:** You can get immediate value from **Relay** and **Consult** with just this XYZ repo — no
PDDA required. PDDA installation is only needed if you want the full eventual automation path
(**Swarm** and especially **Marathon**). Start with the fast path, graduate to PDDA later if you
like what you see.

Background links (not required for this test):

- GiantBrains Claude Skills — https://github.com/Claude-AI-Tools-Ventura-County/giant-brains-claude-skills
- PDDA (the doc-governance half of the system) — https://github.com/Hypercart-Dev-Tools/pdda

### The four modes of operation

XYZ has four modes. They stack — each one builds on the trust you develop with the previous:

1. **Consult** — a one-shot, parallel second opinion. The same question fans out to Codex and agy
   at the same time, each answers independently in an isolated copy of the repo, and the answers
   are reconciled into one. Nothing is modified; it's purely advisory. Lowest risk, fastest payoff.
2. **Relay** — an iterative, turn-based loop between two agents on one shared file: a **Producer**
   builds an artifact, a **Reviewer** critiques and proposes fixes, and they hand off back and
   forth until the artifact converges. This replaces you copy-pasting output between two agent
   windows. Changes are confined to the relay thread file and the artifact under review.
3. **Swarm** — two or more agents working **concurrently** on the same repo, each claiming a
   non-overlapping, path-scoped lane (via the `tick` kernel) so they never collide. Good for
   parallel builds or parallel codebase recon. This is where PDDA's doc structure starts to matter,
   because lanes are carved from well-defined task docs.
4. **Marathon** — the full automation payoff: a queue of pre-flighted tasks (built up during the
   day) fired as one long autonomous run, typically end-of-day or overnight. Marathon **requires**
   PDDA, because the preflight scripts rely on PDDA's opinionated docs/roadmap structure to verify
   every queued task is well-specified before anything runs unattended.

How they fit together: **Consult** answers "what do the other models think?", **Relay** answers
"build this and have it reviewed until it's right", **Swarm** answers "do several independent
things at once", and **Marathon** answers "do all of today's queued work while I sleep." Consult
and Relay need only this XYZ repo. Swarm and Marathon are where PDDA earns its setup cost.

### AgentChorus — live sessions by compact ID

**Agent2Agent is the general-discussion face of Relay:** it drops Producer/Reviewer vocabulary,
allows a declared roster of two or more live sessions, and keeps exactly one active writer through
the relay file's existing `NEXT:` field. It is local and serialized, not a chat server: every
participant must be able to see the same XYZ clone, and parallel writes/broadcasts are deliberately
out of scope.

Install the repo-backed skill for both Claude Code and Codex (idempotent):

```bash
bash skills/agent-chorus/install.sh
```

Then ask the first session to start a discussion, for example: *"Start XYZ AgentChorus with four
agents to discuss: subject line here."* It seeds turn 1 as `agent1`, creates a collision-checked
six-digit ID under `relay-system/<date>/`, and prints one copy/paste invitation for every other seat:

```text
Join XYZ AgentChorus #123456 as agent number two to discuss: "subject line here"
Join XYZ AgentChorus #123456 as agent number three to discuss: "subject line here"
Join XYZ AgentChorus #123456 as agent number four to discuss: "subject line here"
```

Paste each line into its target session once. Agent 2 owns the opening `NEXT:`; agents 3 and 4 join
read-only, report `DECISION: wait`, and can arm their doorbells immediately. The same skill validates
the ID and subject, reads the durable discussion, and responds only if that participant owns `NEXT:`.
An operator can inspect the full roster, current turn, and advisory doorbell state at any time with
`agent2agent.py status --id 123456`; the command creates no lock or sidecar. Each successful turn prints
the next compact invitation, which can route to `agent1`, `agent3`, `agent4`, or any other member of
the original roster. Two operating levels are available: read-only `watch` polls every 150 seconds
by default, while `drive` is an explicit, bounded opt-in that invokes an approved turn command only
when that participant owns `NEXT:`. See [the AgentChorus skill](skills/agent-chorus/SKILL.md) for the
deterministic `start`/`status`/`join`/`watch`/`drive`/`send`/`close` contract.

### Before you start — safety and reversibility

Everything below is designed to be reversible, but please help it along:

- **Create a fresh branch (or git worktree) in *both* repos you touch** — one in your clone of
  XYZ, and one in each target project where you'll run relays or install PDDA. E.g.
  `git checkout -b xyz-beta-test`. If anything goes sideways, recovery is just
  `git checkout main` and deleting the branch. If you use `git worktree` directly, read
  [WORKTREE-SAFETY.md](WORKTREE-SAFETY.md) first — a couple of its operations (force-removing a
  worktree directory, moving/relinking one) leave stale git metadata if done by hand instead of
  through `git worktree remove`/`repair`.
- **What each step actually touches** (so you know how to undo it):
  - *Skill install* — symlinks skill folders into the selected agent's user-level skill directory
    (`~/.claude/skills/` and, where supported, `~/.codex/skills/`). A `git pull` in your XYZ clone
    updates the installed skill through that symlink. Undo: delete the symlink. Your project repos
    are untouched.
  - *Relay runs* — write a dated thread file under `relay-system/<date>/` plus the artifact being
    reviewed, on your branch. Undo: discard the branch.
  - *Consult runs* — advisory only; agents work in isolated copies. Nothing to undo. **Known
    limitation:** the `agy` CLI has been observed grounding its answers against the real repo
    instead of confining itself to its isolated copy, undermining the "isolated" guarantee for that
    one advisor specifically. A detect-and-fail check now catches this case and hard-fails the turn
    rather than silently returning a contaminated answer, though it isn't a complete fix yet — see
    legacy source issues #178 and #183.
  - *PDDA install* — adds scripts and an opinionated `PROJECT/` docs structure to the target repo.
    Undo: it's all ordinary tracked files on your branch, so discarding the branch fully reverts it.
- Clone this XYZ repo locally. Clone PDDA **only** if you're going for the full automation path.

### Prerequisites — install and authenticate these before the fast path

The fast path below shells out to the Codex and agy CLIs. **Install and sign in to both before you
start** — a relay or consult fails mid-run, not at startup, if either isn't logged in.

| Prerequisite | Install | Notes |
|---|---|---|
| **Codex CLI** (OpenAI) | <https://openai.com/index/introducing-the-codex-app/> | Authenticate with your ChatGPT account. |
| **agy CLI** (Google Antigravity — the **CLI**, not just the desktop app) | <https://antigravity.google/product/antigravity-cli> | Authenticate through the Antigravity desktop app. You can hand this URL to Claude Code and ask it to install for you. |
| **Node 18+ and git** | your usual package manager | Needed by the `tick` kernel and the Quickstart above. |
| **Python 3.8+** | usually already present | See the runtime note below. |

#### Hardware sizing for Marathon

**Recommended minimum: 16 GB RAM for the serial `marathon.sh --plan` route.** That minimum covers
one builder and its gate running serially, with normal host reserve; it does **not** support the
`/10days` per-lane parallel dispatch. The two routes are intentionally different: the serial command
works one lane at a time, while `/10days` may start one agent for each lane in a wave.

“Supported” below means a recommended planning envelope that leaves host reserve and is not expected
to swap because of XYZ itself. It is not a guarantee that a target repository's test suite will
finish: that suite's memory use is unbounded and must be supplied by the operator when sizing a wave.

| Host RAM | Supported execution path | Planning guidance |
|---|---|---|
| 16 GB | Serial `marathon.sh --plan` only | Do not use `/10days` per-lane parallel dispatch. |
| 24 GB | Serial route; small `/10days` parallel wave after manual budgeting | Reserve memory for macOS and the target suite before choosing the lane count. |
| 32 GB | Serial route; `/10days` per-lane parallel dispatch after manual budgeting | A practical baseline for a normal parallel wave, subject to the target suite's memory cost. |
| 64 GB | Serial route; wider `/10days` per-lane parallel dispatch after manual budgeting | More headroom for lanes and repository tests; it is still not an automatic wave-width limit. |

For a serial marathon, XYZ measured about **2.2 GB steady**. For `/10days`, budget
**1.5–2 GB per concurrent lane**, then add the target repository's own test suite memory (an
unbounded, operator-supplied term) and the host reserve. In other words, choose a width that fits:
`available RAM − host reserve − target-suite memory`, divided by 1.5–2 GB per lane. Do not infer a
safe width from the table alone for a repository whose tests are memory-heavy.

Measurement provenance: on a **32 GB M1 Max**, 138 samples taken at **10-second intervals** while a
builder, an agy reviewer, and three pytest gates were active measured a serial marathon at **2.19 GB
average steady-state**, with a **2.26 GB peak**. Re-measure when the agent mix, gate command, or host
meaningfully changes.

`kernel ≤ 1 per wave` is a **coordination/zone cap, not a memory cap**. It is configured through
`maxPerWave` in `utils/marathon-plan-zones.default.json` and applies independently of write-set
collisions: it constrains which lanes may share a wave, never how much RAM they consume.

XYZ does have per-gate resource containment: the GH-390 gate guard enforces **wall-clock, CPU and
RSS** caps and kills an over-budget gate. It does **not** currently inspect host RAM, clamp a wave
width, or refuse a wave that is too large for the machine. Host-aware wave sizing remains the
operator's responsibility.

The caps come from a **tier**, so there is one place to look rather than a rule per gate:

| Tier | Wall | CPU | Use |
|---|---|---|---|
| `full` (default) | 1800s | 1200s | a whole-suite gate; sized ~1.9× the worst observed run |
| `fast` | 300s | 240s | a targeted gate, where minutes already means runaway |

RSS is not tiered: it defaults to 8192 MB. A gate the guard kills exits **108**, and the phase
escalates as `gate-killed` — deliberately distinct from `pre-advance-failed`, so a gate that ran out
of time is never triaged as a gate that found a defect.

| Variable | Effect |
|---|---|
| `MARATHON_GATE_TIER` | pick `full` or `fast` |
| `MARATHON_GATE_WALL_S` | override the tier's wall cap |
| `MARATHON_GATE_CPU_S` | override the tier's CPU cap |
| `MARATHON_GATE_RSS_MB` | override the RSS cap (default 8192) |
| `MARATHON_GATE_POLL_S` | sampling interval (default 1s) |
| `MARATHON_GATE_GUARD=0` | **disable the guard entirely** |

Per-variable overrides win over the tier, so a phase can retune one cap without leaving its tier.

> **`MARATHON_GATE_GUARD=0` removes ALL timeout and memory protection from the gate**, not just the
> cap you were trying to get around. An unattended run with the guard off can hang indefinitely on a
> gate that never returns — the failure recorded in legacy source issue #383
> was filed for, and the guard is what closed it. Raise the specific cap instead.

**Gate Environment and Execution Contract:** The gate program is resolved from the command's first token. The gate environment is scrubbed (GH-441); configuration reaches a gate through files, not variables. A gate command may not begin with an environment assignment.

Full per-CLI verification steps, environment variables, and troubleshooting live in
**[Set up Codex, agy, and Pi](relay-automation/README.md#set-up-codex-agy-and-pi-headless-bring-up)**.

- **Runtime — Python by default.** The harness entry points run their **Python** implementation by
  default. Every shim keeps its original Bash body inline as the escape hatch, so you can force the
  legacy Bash path at any granularity: one command with `XYZ_PYTHON=0 <command>`, a whole session or
  CI job with `export XYZ_PYTHON=0`, or permanently with `git revert <flip-sha>` (the flip is one
  isolated commit). Python 3.8+ is required; if `python3` is missing or too old a shim prints a warning
  and falls back to Bash on its own.
- **Supply-chain note (agy):** The `agy` CLI performs background self-updates. This interacts oddly with the pin-to-audited-commit discipline used for most headless tools, as your underlying agent model may update mid-project.
- **Agent users: run un-sandboxed.** If you're driving this from Claude Code (or another sandboxed
  agent harness), relay and consult runs need real keychain access and outbound network egress to
  reach Codex/agy — a sandboxed shell will fail with "Operation not permitted" or a blocked-host
  error that looks like a bug but is really the sandbox. Disable the sandbox for these commands
  before concluding something is broken.

### Fast path: immediate value, no PDDA

1. Create a working branch in your XYZ clone.
2. In the XYZ repo, ask Claude Code to: *"install the /relay-xyz, /consult, and /agent2agent skills for me
   system-wide."*
3. In any target project (on its own fresh branch), you can now:
   - Run a **Consult** for a cross-model second opinion on a design, doc, or decision.
   - Run a **Relay** to have a Producer/Reviewer pair converge a real artifact.
   - Start an **Agent2Agent** discussion when two or more live sessions should exchange general
     reasoning through a compact ID instead of artifact-review roles.

No PDDA compliance is enforced on the target project for either of these. This is the recommended
starting point for all beta testers.

### Full automation path: PDDA + Swarm/Marathon

Only take this path once the fast path works for you and you want unattended, queued execution:

1. In the target project repo, **create a new branch first**, then run PDDA's `install.sh`.
2. Ask Claude Code to help make the project's docs folder structure PDDA-compliant so XYZ can
   operate on it cleanly. (PDDA ships auto-triage scripts that do most of this restructuring for
   you.)
3. Ask Claude Code to create a **Marathon Plan** file, and add tasks to it throughout the day as
   they come up.
4. Near end of day, ask Claude Code to run the **preflight scripts** — these check your docs and
   GitHub issues for Marathon/Swarm viability so nothing under-specified runs unattended.
5. When preflight is green, ask Claude Code to **fire the Marathon**.

### Recover after an interrupted Marathon

After a crash, kill, reboot, or other suspected interruption, run the read-only recovery report
against the affected repo:

```bash
bash /path/to/xyz/relay-automation/marathon-recover.sh /path/to/target-repo
```

It reads every `marathon-system/*/RELAY.md` (and the legacy `phases/` location), the local tick
event log, and commits reachable from the target's current branch tip. A reported **UNGATED COMMIT**
means a phase remains open or escalated, has no `marathon.phase.approved` event, and already has a
landed commit: treat it as unverified. Re-run that phase's gate or revert the commit before trusting
it. The report also shows the driver-lock state. A stale lock self-heals on the next marathon run;
a lock reported LIVE only means its PID still answers the liveness probe, so check a seemingly-dead
holder rather than assuming it is stale.

### Important note on PDDA's structure

PDDA's folder structure is deliberately opinionated. That setup cost is the trade for what
Marathon gives you: because every task lives in a predictable doc structure, the system can
preflight, queue, and execute a full day's work without you babysitting it. If that trade doesn't
appeal yet, stay on the fast path — Relay and Consult deliver value on day one with zero
restructuring.

---

## Glossary — the four terms you'll hit first

(For how the operating modes — Consult, Relay, Swarm, Marathon — relate to each other, see
[The four modes of operation](#the-four-modes-of-operation) in the beta section above.)

- **`tick`** — the coordination kernel: a shared local event log (`.tick/events/`) that agents
  claim work through, serialized by an `O_EXCL` lock.
- **relay** — a turn-based loop where one agent builds and another reviews, handing off through
  files instead of a human copy-pasting between windows.
- **Marathon** (`relay-automation/marathon.sh`) — chains several relay build→review phases from a
  `MARATHON.yaml`, in `depends_on` order. The multi-agent coordinator built on the relay loop.
  Headless builders default to subscription-billed `codex`/`agy`; `--builder claude` is available as
  an explicit per-call API opt-in (`CLAUDE_MAX_BUDGET` defaults to $0.50 and `CLAUDE_MAX_TURNS` to 12).
- **agy** — the Antigravity CLI (Google), one of the agents XYZ coordinates alongside Claude Code
  and Codex.

## FAQ

### Is XYZ a "graph" — does it do graph engineering?

Partly, and the parts it leaves out are deliberate. If you arrive with the standard agent-graph
vocabulary (a DAG of nodes and edges, parallel stages, routing decisions), the Glossary entry above
will read as more than it says. The precise answer:

**What matches.** Phases are real nodes — each gets `marathon-system/<id>/RELAY.md`, a tick token, a
reviewer, a brief, and an artifact allowlist, with an LLM turn as the body. Inside a phase there is
a genuine LLM-selected edge: the reviewer writes `STATUS:`, and `utils/py/relay_drive.py` treats
`Approved`/`Closed` as terminal and anything else as another round, bounded by a round cap. Every phase boundary runs a verification gate, which must be able to *start* before turn 1 — a missing
gate fails fast rather than being skipped. Target repositories with known pre-existing test failures
can specify `--pre-advance-baseline <rc>` (or `MARATHON_GATE_BASELINE=<rc>`) to permit existing failure exit codes
while halting if regressions worsen the code. And the whole run is an inspectable state machine
(`.tick/events/`, `RELAY.md`, `ESCALATION.md` with typed reason codes) rather than a model's
self-report.

**What doesn't.** There is no DAG. `depends_on` is scalar-only — one dependency per phase — so a
join is inexpressible: "p4 after p2 *and* p3" cannot be written. There is no parallel execution;
`relay-automation/MARATHON.example.yaml` states that phases run strictly one at a time and that a
disjoint write-set does not buy you parallelism. `depends_on` **validates** the order you authored
rather than **deriving** one, which inverts the usual graph model. And a failure halts the chain —
there is no conditional edge to a remediation node.

So: a sequential chain of agent-driven build→review loops, with hard gates at every boundary. The
scheduling a graph engine exists to automate is handed to the operator on purpose — see
`GUIDING-PRINCIPLES.md` §8, and `utils/swarm-preflight.sh`, which is the *producer* of a run packet
and never its executor.

Parallelism does exist, but as **swarms**: separate agents in separate worktrees or clones on
disjoint write-sets, coordinated by `tick` locks. That is arranged by the operator, not scheduled
from a dependency graph.

### Do phases run in parallel? What does `depends_on` actually do?

**Inside a single marathon plan: No.** Phases run **strictly one at a time**, in the order they appear in the plan.
A phase *without* `depends_on` is not "unordered" or "parallel-safe" — it simply runs when its turn
comes. `depends_on` constrains and validates that order; it does not create a concurrent execution graph.

It also takes exactly one phase id, unquoted (`depends_on: p3`). The list form `depends_on: [p3]`
parses as the literal string and aborts the plan with an unknown-phase error that points at your
phase ids rather than at the field's shape. Chain them (`p3 → p4 → p5`) to express a longer order.

Analysing your phases for a disjoint write-set is still worth doing — it is how you learn which
phases genuinely need `depends_on` — but it will not make them concurrent within the same working tree.

**Where concurrency DOES exist is across separate runners (Lanes and Swarms):**
- **Automated Runner Concurrency (Separate Full Clones):** Because linked worktrees share the parent repository's `.git/relay-driver.lock` (GH-42, GH-564), automated runners (`marathon.sh` / `relay-drive.sh`) running simultaneously must be dispatched in **separate standalone full clones**.
- **Interactive Multi-Agent Coordination (Shared Workspace):** Multiple live agent sessions operating in the same repository or worktree coordinate their task claims via the shared local `.tick/events/` log.
- **Triage Fan-Out:** Skills like `/10days` fan out parallel read-only subagents to *triage and inspect* backlog issues simultaneously, while the actual build/review execution for any given lane remains strictly sequential within its runner.

Always `--dry-run` a new plan first. It parses every field and prints the real execution order at
zero cost, which is the cheapest way to catch both a mis-shaped field and a wrong mental model.

## Glossary & Execution Model

To avoid ambiguity across planning, kernel locks, and multi-agent workflows, terminology in this repository adheres to the following hierarchy:

$$\text{Wave} \longrightarrow \text{Lane} \longrightarrow \text{Execution Plan (\texttt{MARATHON.yaml})} \longrightarrow \text{Phase} \longrightarrow \text{Relay} \longrightarrow \text{Turn}$$

| Term | Scope | Definition | Execution & Concurrency Model |
|:---|:---:|:---|:---:|
| **Turn** | Agent | A single bounded headless invocation of an AI builder (e.g. Codex, Qwen) or reviewer (Claude). | Single turn step |
| **Relay** | Product | An automated, iterative handoff loop between builder and reviewer until a verified gate pass or halt condition. | Sequential turn loop |
| **Phase (Plan)** | Marathon | A single discrete step/milestone within a `MARATHON.yaml` execution file (e.g. `p1`, `p2`). | **Strictly Sequential** (1-at-a-time per runner) |
| **Phase (Doc)** | PDDA | A numbered stage of implementation defined in a `PROJECT/2-WORKING/` design specification (Phase 0, Phase 1). | Documentation / roadmap staging |
| **Lane** | Workflow | An autonomous execution pipeline dedicated to solving a single GitHub issue or task. | Single track |
| **Execution Plan** | Runner | An authored `MARATHON.yaml` file defining a concrete sequence of phases, gates, and git commit targets. | Serial execution spec |
| **Wave Plan** | Planner | A generated roadmap document (`MARATHON-PLAN-*.md` via `marathon-plan.sh`) grouping backlog items into collision-safe waves. | Planning overlay (operator-dispatched) |
| **Wave** | Planner | A batch of independent lanes with disjoint write-sets, satisfied prerequisites, and respected zone caps. | Batch recommendation |
| **Marathon** | Automation | The multi-phase orchestrator (`marathon.sh`) and phase loop driver (`marathon-drive.sh`) executing a plan on a branch. | Serial orchestrator |
| **Swarm** | Architecture | Multiple independent agents or runners working concurrently across **separate full clones** (automated) or worktrees (interactive). | **Distributed / Parallel** |
| **`depends_on`** | Config | An authoring validation assertion in `MARATHON.yaml` verifying prerequisite phase completion before starting the next. | Assertion gate (not parallel DAG) |
| **`tick` Kernel** | Kernel | The local, serverless database managing collision-free task claims and path-scoped locks under `.tick/events/`. | Append-only event log with `O_EXCL` locks |

## Repo map

- `relay-automation/` — scripts and operator docs for poll-driven relays, watchdogs, headless turn-takers, and consult.
- `skills/` — packaged skill surfaces, including `agent2agent`, `relay-xyz`, `relay-automation`, `xyz`, consult helpers, and
  [`ponytail`](skills/ponytail/SKILL.md) (the `/ponytail` lens definition cited throughout
  `PROJECT/` docs and PDDA's `/idea` Phase 0 — see legacy source issue #180).
  Claude Code only scans `~/.claude/skills/`, so a fresh clone won't see these until you symlink them in —
  run `bash skills/relay-xyz/install.sh` once per clone/machine to make the `/relay-xyz` skill discoverable
  (see [skills/relay-xyz/SKILL.md](skills/relay-xyz/SKILL.md#first-time-setup-on-a-new-clone-or-machine-make-the-skill-discoverable)).
- `skills/marathon-triage/`, `skills/marathon-cleanup/`, `skills/10days/` — the marathon operator
  skills: triage PDDA intake + active work into a ranked, preflight-checked, collision-safe queue
  ([`marathon-triage`](skills/marathon-triage/SKILL.md)); archive only lanes with verified completion
  evidence after a run ([`marathon-cleanup`](skills/marathon-cleanup/SKILL.md)); and — the one deliberate,
  operator-authorized auto-fire exception to the "ask before firing" rule — sweep recent GitHub issues into
  a marathon and execute it unattended ([`10days`](skills/10days/SKILL.md)). See legacy source issue #240.
- `skills/file-xyz-bug/` — file a harness bug from **any other repo** into this repo's `PROJECT/1-INBOX/`
  (GH issue + capture doc + ROADMAP park), without touching the repo you're standing in.
- `skills/agent-chorus/` — compact six-digit rendezvous (AgentChorus, formerly agent2agent) for serialized discussions among two or more
  live sessions; reuses dated relay files and supports Claude Code plus Codex skill installation.
- `relay-system/` — relay transcripts, reviews, and dogfood runs.
- `PROJECT/2-WORKING/` — active project docs and working plans.
- `bin/tick`, `src/`, `test/` — the `tick` coordination kernel and its test suite.
- `releases.db` + `releases.sql` — TWO subsystems in one ledger: the GH-32 RELEASES ledger and the GH-69 ROADMAP shadow (`releases roadmap sync` mirrors `ROADMAP.md`'s ledger in, one-way). Read [RELEASES-DB-FAQS.md](RELEASES-DB-FAQS.md) before merging either file, since the SQLite file is derived and the SQL dump is what git actually merges.
- `utils/swarm-preflight.sh` — marathon intake planner: turns a project doc or a GH-issue bundle into a marathon-ready run packet (freshness + fix-still-required checks, readiness gate, Codex/agy lane plan). Run `utils/swarm-preflight.sh --help`; see [GH-25-SWARM-PREFLIGHT-PLANNER.md](PROJECT/3-COMPLETED/GH-25-SWARM-PREFLIGHT-PLANNER.md).
- `utils/marathon-plan.sh` — the marathon planner/ranker: scores the whole ROADMAP ledger into waves of disjoint, collision-safe write-sets, and with `--deep` delegates to `swarm-preflight.sh --dry-run` per item for an authoritative freshness verdict. Writes `PROJECT/2-WORKING/MARATHON-PLAN-<date>.md` — the "marathon file" the operator skills act on.
- `utils/swe-diagram/` — dependency-free architecture/Git-history diagram generator; `layout: "git-lanes"` renders stacked branch lanes with commits left-to-right, driven by a local ref-reading generator that emits an auditable JSON spec plus self-contained HTML. See legacy source issue #201.
- `utils/git-bundle-snapshot.sh` + `relay-automation/hooks/gh177-sandbox-test-guard.sh` — the wipe-prevention layer: rotated `git bundle --all` backups on a daily cron, plus a PreToolUse hook that blocks running the test suite under a *sandboxed* Claude Code Bash call (the ignition for the GH-177 repo wipes). See legacy source issue #233.
- `install.sh` — materializes the `tick` runtime (`bin/tick` + `src/*.js`) into an external repo and records the install in a per-user, machine-local registry (`~/.config/xyz/registry.tsv`). See "Install into another repo" below.
- `utils/hq/` — **HQ**, the multi-repo command center (`hq.sh` + `hq-lib.sh`); driven by the user-level `/hq` skill in `skills/hq/`. See [HQ — multi-repo command center](#hq--multi-repo-command-center) below.

## What `tick` is

`tick` coordinates agents through a shared local event log under `.tick/events/`.
Claims are serialized by an `O_EXCL` lock, and projection folds events into
`.tick/STATE.md`. Coordination is local-transport only: no per-event push/fetch,
no remote dependency, one shared `.tick/` directory per active run.

If you are here for the kernel rather than the relay layer, the implementation
lives in [bin/tick](bin/tick), [src/](src), and [test/](test). Run the full suite with
`./validate.sh`.

## Install into another repo

`install.sh` copies the `tick` runtime into any target directory and records the install:

```bash
./install.sh [target-dir] [--repo <coordinated-repo-path>]
# Example:
./install.sh ../sleuth-app/xyz-tick --repo ../sleuth-app
```

This creates `<target-dir>/bin/tick` and `<target-dir>/src/*.js`, then appends a row to the per-user,
machine-local registry at `~/.config/xyz/registry.tsv` (override with `XYZ_REGISTRY`). The registry
tracks where each copy lives and which source commit it was built from — so a future `tick` version can
be pushed to copies that are behind.

The registry is **never committed** (machine-local only). If [git-pulse](https://github.com/anthropics/git-pulse)
is configured, a path-normalized projection (no absolute paths) is published to its sync repo so install
status rolls up across devices automatically.

Options:
- `--repo <path>` — record the coordinated repo (where `.tick/` lives) in the registry entry.
- `--no-register` — skip the registry write entirely (also skips git-pulse projection).

## HQ — multi-repo command center

Where `tick` and the relay coordinate agents **inside one repo**, **HQ** is the operator front door
**across every repo on this device**. It turns a single utterance — *"for project Acme, do X"* — into
governance-aware action: resolve a fuzzy project name to a real repo, report its state, and land the
request on that repo's own PDDA rails. It ships as `utils/hq/hq.sh` and the user-level `/hq` skill.

**Read paths are safe; every write path previews by default and acts only with `--create`.** HQ never
drives a marathon itself — `fire` stops at a gated hand-off you run.

### Install once, then it works from any repo

Claude Code only scans `~/.claude/skills/`, so symlink the skill in once per clone (idempotent):

```bash
bash skills/hq/install.sh      # symlinks this clone's skills/hq into ~/.claude/skills/
bash skills/hq/find-hq.sh --check   # one-glance readiness: hq root, sqlite3, rebalance registry
```

After that, `/hq …` works from a session opened in **any** repo. Standing in this harness clone you
can also call `bash utils/hq/hq.sh …` directly (the forms below use that short form).

### Command surface

| Command | What it does |
|---|---|
| `hq.sh status <project>` | **Project card** — resolved repo + path, capability tier (A/B/C), Rebalance priority, PDDA mode + startup docs, active-doc count, open marathon plan, XYZ install/drift stamps. |
| `hq.sh resolve <project>` | Machine-readable `KEY=value` resolution (`RESOLVED_VIA=exact\|fuzzy`; an ambiguous name returns rc=2 with `CANDIDATES`). |
| `hq.sh registries` | Introspection — what each registry knows and its coverage. |
| `hq.sh next [--limit N]` | **Priority board** — projects ranked by Rebalance `priority_tier` with each one's HQ capability tier. Read-only. |
| `hq.sh park [--create] [--title T] <project> <req…>` | **Issue-first intake** in the target repo: GH issue → `PROJECT/1-INBOX/` capture → ROADMAP parking. Previews unless `--create`. |
| `hq.sh promote [--create] --gh-issue N <project>` | **PDDA `1-INBOX → 2-WORKING`** (GH-138): `git mv GH-N-*.md` + scaffold the moved doc so it satisfies the enforced 2-WORKING contract (leaves ratings/QA gates as operator TODOs). Previews unless `--create`. |
| `hq.sh queue [--create] [--gh-issue N] <project> <req…>` | Append an **HQ-queued lane** to the target's newest `MARATHON-*.md` plan (non-destructive). Previews unless `--create`. |
| `hq.sh fire --gh-issue N [--risk 1-5] <project>` | **Gated prepare-and-hand-off** — resolves, gates (Tier A, `risk < 3`), and emits the `swarm-preflight` command for the operator to run. Never drives the harness (GUIDING-PRINCIPLES §8). |

The intake-to-dispatch pipeline is **`park → promote → queue → fire`** — capture on the rails, promote
into active work, queue a marathon lane, then hand off. Each step previews first.

### How a name becomes a repo (resolution ladder)

1. **Rebalance `project_registry`** (`rebalance-OS/rebalance.db`) — semantic catalog: NAME → repos + priority. No path.
2. **XYZ install registry** (`~/.config/xyz/registry.tsv`) — repo → absolute path + drift stamps (the path resolver).
3. **Git Pulse PDDA registry** (`~/git-pulse-sync/pdda/registry-<device>.tsv`) — repo → PDDA mode + startup docs, cross-device.
4. **Filesystem `find`** — fallback when no registry knows the path.

**Capability tiers:** **A** = PDDA + XYZ install → dispatch-eligible · **B** = PDDA only → intake only ·
**C** = bare repo → plain issue only (offer a PDDA install). Test/non-default overrides:
`HQ_PDDA_REGISTRY_DIR`, `HQ_XYZ_REGISTRY`, `HQ_REBALANCE_DB`, `HQ_SEARCH_ROOTS` (see `utils/hq/hq-lib.sh`).

Full agent-facing detail — invocation flow, guardrails, and the locator contract — lives in the skill:
[skills/hq/SKILL.md](skills/hq/SKILL.md). Historical implementation record: legacy source issue #128.

---

For retained testing artifacts, benchmark receipts, and telemetry logs, see [TESTS-RESULTS/README.md](TESTS-RESULTS/README.md).

For observed real-agent behavior and decision history, see
[REAL-AGENT-OBSERVATIONS.md](PROJECT/4-MISC/REAL-AGENT-OBSERVATIONS.md) and
[CHANGELOG.md](CHANGELOG.md) — the running end-of-iteration log. (`RECAP.md` is retired in `PROJECT/4-MISC/`.)
