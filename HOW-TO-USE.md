# How to Use This System

An operator's guide to running XYZ day to day, organized by time horizon. Adapted from the
operating-rhythm writeup in [#259](https://github.com/HiQS-Labs/XYZ-forge/issues/259); that issue's
comment thread also tracks the skills roadmap that mechanizes these rituals.

One framing point before the rituals: the two core systems own different truths. The **releases DB
is the commitment ledger** — what's promised, to which release, with what evidence. The **marathon
system is the execution engine** — sequencing, concurrency lanes, readiness. The leverage is in
never duplicating either's state by hand, and letting each oracle catch the other's rot.

## Hour to hour — let the ledger answer "what now"

- **Start sessions with `releases next` + `releases show` on the active release.** The queue is
  already scored (`rating_pri/sev/appeal/effort/ovr`) — resist re-deriving priorities in your head
  or in chat. If the ranking is wrong, re-rate the row so the correction is durable.
- **Run the item's preflight before building it.** The `already-landed` check (`fix_probes`)
  exists because work sometimes already shipped — GH-197's history (closed on work that never
  landed, reopened, re-closed against verified code) is exactly that failure class. Two minutes of
  probing beats building something twice.
- **Record evidence at the moment of action.** `manifest ship --evidence` while the PR/test
  receipt is in front of you. GH-205 sat `dialed_in` for days while its issue was closed because
  shipping evidence was deferred — the op_receipts audit trail is only as good as its timeliness.
- **Never hand-edit `ROADMAP.md` ledger rows, `releases.sql`, or the DB.** Every hand edit breaks
  the DB↔dump↔generated triangle that `releases check` guards. Verbs only.
- **At merge time**, the rhythm is mechanized (`wave_reconcile.py --pr N`) — remember the two
  gates: capture docs need their Lessons Learned section *before* merge, and PR bodies citing a
  foreign tracker need an offline `issues[]` manifest.
- **For the immediate "run today" queue**, use jog once landed (GH-259 Phase 1): `jog GH-<n>`
  queues without wave-planning ceremony; full contracts are owed at fire time, not capture time.

## Day to day — a morning drift sweep and a generated plan

- **One command block each morning**: `releases check` + `marathon-plan.sh --dry-run` +
  `pdda.sh issue-doc-sync`. Deterministic output means any diff is real signal. The three drift
  classes it catches — `already-closed` (ledger stale vs GitHub), `already-landed`,
  `undocumented-partial` — are precisely the rot that accumulates silently. Five minutes daily
  keeps that list at zero-attributable. End the sweep by confirming the tree is clean
  (`git status --porcelain`) so the sweep itself can't become the day's first undetected drift.
- **Generate the day's `MARATHON-PLAN-<date>.md`, never author it** — it's collision-lane aware
  (`agy_safe` vs `orchestrator_only`), which is what keeps concurrent harness turns from stomping
  each other. Then link outcomes back: `releases manifest marathon` rolls marathon results up
  into the release manifest.
- **Same-day dial-in decisions on new intake.** When something lands in `1-INBOX`, either
  `manifest dial-in` it with a `dial_reason` or `cut --reason` it. Undispositioned intake is how
  backlogs of warnings form — the reason columns are your future self's context.
- **Close the loop before bed**: `releases gen` and treat a non-empty
  `RELEASES.generated.md.drift` as unfinished business.

## Day to week — release boundaries and disposition sessions

- **Weekly `releases list` review of the target-date ladder.** Drafts carrying `MIG-` placeholder
  tracking refs age into `mig-ref-stale` warnings (>7 days). A weekly disposition session
  (convert to real tracking issues or cut) keeps the strict flip reachable.
- **Per-release boundary ritual** — at a multi-day shipping cadence, "weekly" is really
  "per-release": `releases baseline` at kickoff (write-once — it's your mid-release scope-change
  detector), then at close require *zero* `dialed_in` stragglers, `releases check` clean,
  dashboards regenerated, then ship.
- **Weekly held-item disposition.** The planner never auto-places held items in waves — held is
  where work goes to be forgotten unless someone explicitly re-rates, parks, or cuts. A weekly
  pass over held buckets plus a `gh-refresh` of the issue-state cache closes that hole.
- **Feed what the drift oracles find back into core.** When the same manual workaround recurs
  across sessions, it's either a core fix or a skill — file it. The oracles detecting their own
  blind spots is the system working as designed; leaving the finding undispositioned is not.

## Glossary — the four terms you'll hit first

(For how the operating modes — Consult, Relay, Swarm, Marathon — relate to each other, see the
execution-modes table in [README.md](README.md).)
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
`GUIDING-PRINCIPLES.md` (item 8, "Honest; the operator decides", under "How it's built"), and `utils/swarm-preflight.sh`, which is the *producer* of a run packet
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


## Where the deeper docs live

- [ROUTER.md](ROUTER.md) — canonical entry points and command rails (start here each session).
- [AGENTS.md](AGENTS.md) — repo behavior, decision quality, and proof rules.
- [PROJECT/PDDA.md](PROJECT/PDDA.md) — the doc lifecycle contract (1-INBOX → 2-WORKING → 3-COMPLETED).
- [RELEASES-DB-FAQS.md](RELEASES-DB-FAQS.md) — the app-managed ledger contract and merge procedure.
- [skills/relay-xyz/SKILL.md](skills/relay-xyz/SKILL.md) — driving automated relays and marathons.
