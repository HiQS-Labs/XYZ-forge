# XYZ Forge

**A local-first engineering operations system for running AI coding agents as a workforce.**

XYZ Forge coordinates several AI coding agents — Claude Code, Codex, `agy` (Google's Antigravity
CLI), and others — working on the same repositories, and it carries the surrounding machinery an
unattended agent run actually needs: specified work, collision-free lanes, verification gates, and a
receipted record of what happened.

It started as a coordination kernel. It has become the loop around it:

```
capture → rate → plan → preflight → execute → gate → land → record
```

Every stage is a CLI verb or a skill, every artifact is on your disk, and no stage requires a
server, an account, or an API key for the coordination layer itself.

> **Safety and warranty:** XYZ Forge is provided **"AS IS," without warranty**, under the applicable
> license. Coding-agent automation is inherently risky: models may choose commands through their own
> runtimes and safety controls, outside the intended harness workflow. XYZ Forge cannot guarantee
> model behavior or data integrity; maintain tested, independent backups and follow industry-standard
> backup and recovery practices.

---

## Status: alpha, single-operator, moving fast

Be clear-eyed about what you are adopting.

| | |
|---|---|
| Age | Current history rooted 2026-08-15 after a 2026-09-02 reset; the project predates it (archival tag `bash-final-2026-07-28`) |
| Release tags | No release tags — two archival tags only; versions are tracked in an internal ledger, not published ([#452](https://github.com/HiQS-Labs/XYZ-forge/issues/452) tracks adopting them) |
| Primary operator | One, with a small collaborator set; most commits are agent-authored |
| Test suite | ~350 registered suites (count drifts weekly); `npm run test:unit` is a 14-case, sub-second kernel check |
| Gates | Local pre-push gate plus hosted CI on `main` and `development` |
| Runtime | Python by default since the `XYZ_PYTHON` flip; frozen Bash twins remain as a fallback |
| Known-weakest area | The frozen Bash fallback paths, and Python static analysis (there is none) |

This is software that has been used hard by its author against real repositories and has the scar
tissue to show it — several guards in this repo exist because an earlier version destroyed work.
That is a point in its favor and a warning at once. **Run it on a branch. Keep independent backups.**

---

## Prove the kernel works — 60 seconds, no accounts

Tested on **Node 18+**; requires **git**.

```bash
npm install                # two parser deps used by the test tooling
npm run test:unit          # ~1s — 14 kernel unit tests
```

Then, if you intend to contribute:

```bash
bash githooks/install.sh   # ONCE PER CLONE — wires the pre-push gate
./validate.sh              # the full suite (see the timing note)
```

`./validate.sh` runs the whole registered suite, no accounts or API keys required. **Budget 5–10
minutes** in parallel mode; below 4 cores it forces sequential and takes considerably longer. Run
`./validate.sh --print-mode` to see which mode your machine picks and why.

> **⚠️ Run `validate.sh` un-sandboxed.** Under Claude Code's default Bash sandbox — or any sandboxed
> agent harness — the suite prints **nothing for several minutes** and then fails, because its
> `mktemp -d` scratch directories are blocked. It looks like a hang, not a permissions error, and it
> is this repo's single most common false alarm. Turn the sandbox off for this command (`/sandbox` in
> Claude Code) before concluding anything is broken.

**The pre-push hook is a correctness requirement, not optional setup.** It lives in `.git/hooks/`,
which does not travel with a clone, so a fresh clone is ungated until you install it. One install
covers every branch and linked worktree of that clone. Check any time with
`bash githooks/install.sh --check`.

---

## What you actually get

### 1. The kernel — `tick`

A dependency-free Node CLI over an append-only event log at `.tick/events/`. Agents take
**path-scoped claims** serialized by an `O_EXCL` lock, so two agents editing overlapping paths
serialize instead of racing. Projection folds events into `.tick/STATE.md`. No server, no remote, no
per-event network traffic.

Source: [`bin/tick`](bin/tick), [`src/`](src). Tests: [`test/`](test).

*Known limit:* there is no stale-lock detection yet. A hard kill mid-claim leaves a lock that must be
removed by hand — see the note at the top of [`src/lock.js`](src/lock.js).

### 2. The execution layer — relay, swarm, marathon

Headless turns driven through each agent's own CLI, one turn at a time, with containment enforced by
a shared core ([`relay-automation/relay-turn-lib.sh`](relay-automation/relay-turn-lib.sh)):

- a **path allowlist** per turn, tightened further for reviewer turns
- **worktree isolation** by default under the driver — the agent writes to a throwaway worktree and
  only allowlisted files are copied back
- a **commit-bypass guard** that resets the repo if an agent commits mid-turn
- a **wall-clock watchdog**, and **typed exit codes** so a timeout is never mistaken for a defect
- **no pushes, ever**, from a turn shim

Four execution modes, in increasing order of autonomy:

| Mode | What it does | Needs |
|---|---|---|
| **Consult** | One question fans out to two models in parallel, isolated copies, answers reconciled. Advisory; nothing is modified. | This repo |
| **Relay** | Producer builds, Reviewer critiques, they hand off until the artifact converges. | This repo |
| **Swarm** | Multiple agents work concurrently on disjoint, path-scoped lanes. | Separate clones per automated runner |
| **Marathon** | A queue of preflighted work runs unattended, gated at every phase boundary. | The governance layer below |

Start at [`relay-automation/README.md`](relay-automation/README.md). Live turns need each agent CLI
installed and authenticated first.

### 3. The operations layer — the part that made this a lifecycle system

This is the half that grew, and the half worth explaining plainly.

Unattended agents fail for boring reasons: the work was under-specified, two lanes collided, a gate
never ran, or nobody can tell afterward what actually landed. Each of those failures produced a
durable surface here:

| Surface | Answers |
|---|---|
| **Issue-first intake** — GH issue → capture doc → parked ledger row | "Is this work written down anywhere?" |
| **Scored backlog** — `pri` / `sev` / `appeal` / `effort` ratings | "What should run next, and why that?" |
| **Wave planner** — exact write-set intersection, zone caps, dependency gating | "Can these lanes run together without colliding?" |
| **Preflight** — freshness probes, already-landed detection, readiness verdict | "Is this specified well enough to run while I sleep?" |
| **Verification gates** — a gate must be able to *start* before turn 1, with CPU/wall/RSS caps | "Did anything actually prove this works?" |
| **Release ledger** — SQLite + a git-mergeable SQL dump, receipted writes | "What did we promise, and what shipped with evidence?" |
| **Doc governance (PDDA)** — frontmatter, status tables, ledger coverage | "Can an agent resume this work tomorrow from the docs alone?" |
| **HQ** — multi-repo resolution, capability tiers, previewed writes | "Do that, for project Acme, from wherever I am" |
| **~50 skills** | Reusable procedures for all of the above |

Two design commitments hold this together:

- **Machine-readable boundaries.** State crossing a subsystem boundary travels as a schema-stamped
  JSON artifact with explicit nulls — never parsed out of logs or prose. See
  [`MACHINE-CONTRACTS.md`](MACHINE-CONTRACTS.md).
- **Deterministic before advisory.** Anything expressible as a regex, schema, or file check is
  checked deterministically and may block. LLM review may warn, rank, or propose — it may never
  block.

### 4. Docs as runtime state

The doc governance is not project-management paperwork. Agent work has to be **stoppable, resumable,
and handed off from `PROJECT/**` alone** — so the doc tree is serialized machine state, and drift
between docs and code is a defect rather than untidiness. That is why the checks have teeth and why
"done" means the suite is green *and* the doc contract holds.

---

## Scope — what this is and is not

**It is:** a local-first operations system for a small number of humans directing a larger number of
agents across their own repositories. The operator is the sole decision authority; every write path
of consequence previews first or requires an explicit gate.

**It is not application lifecycle management.** There is no multi-user identity, no role-based access
control, no SSO, no cross-team capacity planning, no compliance certification, and no traceability
matrix for regulatory submission. Those require multi-user, server-backed, permissioned state, and
**local-first is a deliberate constraint here, not a missing feature.** If you need Polarion or Azure
DevOps, you need Polarion or Azure DevOps.

**It is not a spec-driven-development framework or an agent marketplace.** It does not generate specs
or PRDs from prompts, and it does not host third-party agents. Adjacent tools cover those well —
GitHub Spec Kit for spec-driven flows, Task Master for PRD-to-task breakdown, LangGraph and similar
for orchestration primitives, GitHub Agent HQ for enterprise multi-vendor agent management.

---

## Two products, honestly described

XYZ Forge ships alongside **PDDA**, a separate repo-governance project
([Hypercart-Dev-Tools/pdda](https://github.com/Hypercart-Dev-Tools/pdda)) whose checkers are vendored
into `utils/pdda/`.

The relationship is not symmetrical, and earlier versions of this README stated it less directly:

- **Consult and Relay need only this repo.** No governance structure is required; preflight against a
  plain document degrades every doc-shaped check to advisory and still reaches a verdict.
- **Swarm and Marathon effectively require PDDA.** `hq fire` refuses any repo that is not Tier A
  (PDDA **and** a vendored XYZ install), and the wave planner cannot rank a backlog it cannot read.
  PDDA is a prerequisite for the unattended path, not an optional enhancement.

The dependency runs one way only: the harness reads governance structure; PDDA never calls the
harness. `PROJECT/CONSTITUTION.md`, `PROJECT/DO-NOT-BUILD.md`, and `PROJECT/PDDA*.md` are **PDDA's own
governance documents, vendored here as sync inputs** — they describe PDDA's scope, not this project's.
Do not read them as XYZ Forge policy. This project's principles live in
[`GUIDING-PRINCIPLES.md`](GUIDING-PRINCIPLES.md); its behavioral rules for agents live in
[`AGENTS.md`](AGENTS.md).

---

## Install

### Into another repo — the kernel only

```bash
./install.sh ../my-app/xyz-tick --repo ../my-app
```

Copies the `tick` runtime and records the install in a machine-local registry at
`~/.config/xyz/registry.tsv` (never committed).

### Into another repo — the full harness

```bash
bash relay-automation/xyz-vendor.sh /path/to/target
```

Vendors the harness under `.xyz/` in the target repo. **Note:** the harness alone leaves that repo at
HQ Tier C, which cannot be dispatched to. For the unattended path you also need PDDA installed at the
target's root — see [`skills/vendor-stack/SKILL.md`](skills/vendor-stack/SKILL.md) for the two-step
flow.

### Skills

Claude Code only scans `~/.claude/skills/`, so skills must be symlinked in once per machine:

```bash
bash skills/relay-xyz/install.sh     # the relay driver — start here
bash skills/hq/install.sh            # multi-repo command center
bash skills/agent-chorus/install.sh  # multi-session discussions
```

---

## Hardware sizing for unattended runs

**Recommended minimum: 16 GB RAM** for the serial `marathon.sh --plan` route. That covers one builder
and its gate running serially with normal host reserve; it does **not** support per-lane parallel
dispatch.

| Host RAM | Supported path |
|---|---|
| 16 GB | Serial only |
| 24 GB | Serial; small parallel wave after manual budgeting |
| 32 GB | Serial; per-lane parallel dispatch after manual budgeting |
| 64 GB | Wider parallel dispatch, still not an automatic width limit |

Measured: on a **32 GB M1 Max**, 138 samples at 10-second intervals with a builder, a reviewer, and
three pytest gates active showed a serial marathon at **2.19 GB average, 2.26 GB peak**. Budget
**1.5–2 GB per concurrent lane**, then add your target repository's own test-suite memory — an
unbounded term you must supply — plus host reserve.

Per-gate containment (wall clock, CPU, RSS) is enforced and kills an over-budget gate; a killed gate
exits **108** and escalates distinctly, so a runaway is never triaged as a defect. **Host-aware wave
sizing remains the operator's responsibility** — the guard does not inspect host RAM or clamp wave
width.

---

## Recovering from an interrupted run

```bash
bash relay-automation/marathon-recover.sh /path/to/target-repo
```

A read-only report over phase records, the tick log, and reachable commits. An **UNGATED COMMIT**
means a phase landed a commit without an approval event: treat it as unverified, and re-run the gate
or revert before trusting it.

---

## Where to go next

| You want to | Read |
|---|---|
| Understand the architecture | [`ARCHITECTURE.md`](ARCHITECTURE.md) |
| Work *on* this repo as an agent | [`ROUTER.md`](ROUTER.md), then [`AGENTS.md`](AGENTS.md) |
| Know why it's built this way | [`GUIDING-PRINCIPLES.md`](GUIDING-PRINCIPLES.md) |
| Run a relay or marathon | [`relay-automation/README.md`](relay-automation/README.md) |
| Operate it day to day, glossary, FAQ | [`HOW-TO-USE.md`](HOW-TO-USE.md) |
| Understand cross-subsystem contracts | [`MACHINE-CONTRACTS.md`](MACHINE-CONTRACTS.md) |
| Merge the release ledger safely | [`RELEASES-DB-FAQS.md`](RELEASES-DB-FAQS.md) |
| Use git worktrees with this | [`WORKTREE-SAFETY.md`](WORKTREE-SAFETY.md) |
| Pick a skill for a job | [`ARCHITECTURE.md`](ARCHITECTURE.md) → Skills Index |
| See supported models and harnesses | [`HARNESS-MODELS-REGISTRY.md`](HARNESS-MODELS-REGISTRY.md) |

Project site: <https://hiqs-labs.github.io/XYZ-forge/>

## License

AGPL-3.0-only. A commercial license is available — see
[`LICENSE-COMMERCIAL.md`](LICENSE-COMMERCIAL.md).
