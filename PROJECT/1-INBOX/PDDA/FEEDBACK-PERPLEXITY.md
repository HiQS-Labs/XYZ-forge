# Linear Improvement Steps for rebalance + PDDA

Date: 2026-06-23

## Working thesis

Do not turn this into another generic Spec-Driven Development framework. GitHub Spec Kit already owns the broad “Spec → Plan → Tasks → Implement” workflow, with Markdown artifacts, templates, quality checklists, cross-artifact analysis, integrations, presets, extensions, and governance primitives ([GitHub Spec Kit docs](https://github.github.com/spec-kit/), [github/spec-kit](https://github.com/github/spec-kit)).

The useful improvement path is to make **rebalance** the local evidence layer and **PDDA / relay** the repo-governance and execution layer. Spec Kit should be treated as the reference model for artifact flow, command naming, gates, and customization, not as something to clone wholesale.

## Linear improvement path

### Step 1: Define the shared constitution

Create one project-level governance file that both rebalance and PDDA obey. Spec Kit uses `.specify/memory/constitution.md` for foundational project principles and development guidelines; mirror that pattern with a repo-local file such as `PROJECT/CONSTITUTION.md` or `.rebalance/constitution.md` ([github/spec-kit](https://github.com/github/spec-kit)).

The constitution should define non-negotiables: local-first privacy, deterministic checks before LLM judgment, explicit reversibility for destructive actions, evidence-backed claims, no hidden cloud sync for private notes, and validation-before-success reporting. The first deliverable is not code; it is the policy layer all later scripts and agents can point at.

Verification: add a deterministic check that confirms the constitution file exists, has required headings, and is linked from `ROUTER.md`, `AGENTS.md`, and the rebalance README.

### Step 2: Freeze the artifact taxonomy

Map the current documents into a small set of canonical artifact types. Spec Kit gets leverage from predictable artifacts such as `spec.md`, `plan.md`, `tasks.md`, `research.md`, `quickstart.md`, and `contracts/` ([github/spec-kit](https://github.com/github/spec-kit)).

For your system, use a taxonomy like:

- `PROJECT/**`: execution truth for repo work.
- `ROADMAP.md`: pointer ledger only.
- `CHANGELOG.md`: append-only iteration provenance.
- `PROJECT/PDDA.md`: document governance contract.
- `rebalance.db`: local evidence corpus.
- `PROJECT/CONSTITUTION.md`: shared governance principles.
- `PROJECT/<feature>/SPEC.md`: expected behavior.
- `PROJECT/<feature>/PLAN.md`: implementation plan.
- `PROJECT/<feature>/TASKS.md`: dependency-ordered task list.
- `PROJECT/<feature>/EVIDENCE.md`: linked rebalance/PDDA facts, queries, commits, issues, notes, calendar context.

Verification: add a doc-index check that fails in `full` mode if an active project lacks its required artifact set.

### Step 3: Split “project state” from “workday state”

Keep PDDA responsible for what the repo thinks is active, complete, blocked, or stale. Keep rebalance responsible for what your actual attention signals show: commits, PRs, notes, calendar, Gmail snippets, reminders, and eventually Slack.

This avoids a common failure mode: project docs say one thing, but your week says another. The bridge should be an explicit “evidence projection” step, not implicit AI intuition.

Verification: create a command or MCP tool that emits a `PROJECT/EVIDENCE-SNAPSHOT.md` with top projects by recent activity, stale-but-active docs, over-invested projects, and under-invested active roadmap items.

### Step 4: Add a Spec Kit-style clarify gate

Spec Kit recommends `/speckit.clarify` before planning to reduce rework and avoid treating the first spec as final ([github/spec-kit](https://github.com/github/spec-kit)). Add a PDDA equivalent before any multi-phase project enters `PROJECT/2-WORKING`.

The gate should ask only the questions that would change implementation: success condition, owner, target repo, privacy level, destructive operations, required evidence, stop condition, and rollback path.

Verification: `utils/pdda-check-clarified.sh` confirms active multi-phase docs have a `## Clarifications` section or an explicit `clarification_exempt: true`.

### Step 5: Convert active projects into feature folders

PDDA currently tracks active Markdown docs directly under `PROJECT/2-WORKING`. Keep that for small fixes, but graduate larger efforts into feature folders inspired by Spec Kit’s `specs/<feature-name>/` structure ([github/spec-kit](https://github.com/github/spec-kit)).

Recommended shape:

```text
PROJECT/2-WORKING/<slug>/
  SPEC.md
  PLAN.md
  TASKS.md
  EVIDENCE.md
  CHECKLIST.md
  DECISIONS.md
```

Keep backwards compatibility by allowing a single-file active doc for small work. The improvement is not “more files everywhere”; it is “folders for work that is already large enough to rot.”

Verification: add a size/complexity heuristic that warns when a single active doc should be promoted to a folder.

### Step 6: Make tasks dependency-ordered and parallel-aware

Spec Kit’s `tasks.md` includes dependency ordering, parallel markers, file paths, TDD structure, and checkpoint validation ([github/spec-kit](https://github.com/github/spec-kit)). Bring that discipline into PDDA’s active project docs.

Each task should carry:

- ID.
- Dependency IDs.
- Write scope.
- Verification command.
- Expected evidence artifact.
- Parallel-safe flag.
- Agent lane recommendation.

Verification: `utils/pdda-check-tasks.sh` validates task IDs, dependency references, duplicate IDs, missing verification commands, and unsafe parallel claims.

### Step 7: Add cross-artifact analysis before implementation

Spec Kit has `/speckit.analyze` for cross-artifact consistency and coverage analysis after tasks and before implementation ([github/spec-kit](https://github.com/github/spec-kit)). Add a PDDA analyzer that compares `SPEC.md`, `PLAN.md`, `TASKS.md`, `ROADMAP.md`, and rebalance evidence.

It should catch contradictions like:

- Roadmap says active, but no active task exists.
- Plan names a repo not present in rebalance’s project registry.
- Tasks require calendar/email signals that are not ingested.
- SPEC success criteria are not represented in TASKS.
- PLAN proposes destructive actions without a rollback path.

Verification: analyzer emits JSONL findings and is warn-only until the false-positive rate is acceptable.

### Step 8: Add checklist generation for English requirements

Spec Kit’s `/speckit.checklist` generates quality checklists that validate requirements completeness, clarity, and consistency ([github/spec-kit](https://github.com/github/spec-kit)). Add a local `pdda-checklist` command that creates a `CHECKLIST.md` for each active feature folder.

The checklist should include: privacy, data-source readiness, MCP host readiness, local/offline behavior, test coverage, docs update, rollback path, evidence snapshot, and changelog entry.

Verification: `utils/pdda-check-checklist.sh` confirms every non-exempt active feature has a checklist and that required categories are present.

### Step 9: Add a converge step

Spec Kit’s `/speckit.converge` assesses the codebase against spec, plan, and tasks, then appends remaining work as new tasks ([github/spec-kit](https://github.com/github/spec-kit)). This is especially useful for your setup because rebalance can supply evidence of what actually happened.

Build `pdda-converge` as a read-first command:

1. Read active project artifacts.
2. Read validation results.
3. Query rebalance for recent commits, PRs, issues, notes, calendar context, and stale docs.
4. Append missing work to `TASKS.md` or produce a proposed patch.
5. Never silently rewrite past claims.

Verification: first version runs in dry-run mode only and writes `PROJECT/PDDA-CONVERGE-PROPOSAL.md`.

### Step 10: Bridge task lists to GitHub issues

Spec Kit includes `/speckit.taskstoissues` to convert generated task lists into GitHub issues ([github/spec-kit](https://github.com/github/spec-kit)). Your relay-to-issue skill is already pointing in this direction. Make it the official bridge from PDDA tasks to GitHub issues.

The bridge should stamp issues with a stable source pointer, task ID, repo target, verification command, and dedup marker. It should also round-trip issue URLs back into the project artifact.

Verification: run one live issue creation on a low-risk repo, then verify the PDDA doc, roadmap pointer, and GitHub issue all reference each other.

### Step 11: Make rebalance the evidence oracle for prioritization

The rebalance README already positions the system as a local-first work OS that ingests Obsidian, GitHub activity/artifacts, git pulse history, calendar, Gmail, reminders, and planned Slack into SQLite plus semantic search. Use that as the prioritization oracle for PDDA.

Add a weekly command:

```text
rebalance pdda-priorities
```

It should answer:

- Which active PDDA items received real attention this week?
- Which roadmap items are stale despite being active?
- Which repos are over-consuming attention?
- Which client/project has meetings but no code movement?
- Which completed items lack changelog provenance?

Verification: output is a Markdown report plus machine-readable JSON, with every recommendation tied to local evidence rows or file paths.

### Step 12: Separate deterministic checks from LLM judgment everywhere

PDDA already has the right instinct: deterministic scripts enforce what should never require judgment, while LLM review flags planning-quality gaps. Preserve that split across rebalance and relay.

Rules:

- Regex/schema/file-existence checks may block.
- LLM checks may warn, propose, or rank, but not block.
- Destructive repair actions require explicit operator authorization.
- Self-repair may choose only from a bounded menu.

Verification: every checker declares `deterministic: true|false`, `blocking_allowed: true|false`, and `mutation_allowed: false` unless explicitly approved.

### Step 13: Add a customization stack

Spec Kit’s customization model uses project-local overrides, presets, extensions, and core defaults, with a priority order ([github/spec-kit](https://github.com/github/spec-kit)). Adopt the same idea without copying the whole system.

Recommended order:

1. Repo-local overrides: `PROJECT/.pdda/overrides/`
2. User defaults: `~/.config/pdda/presets/`
3. Built-in PDDA templates: `PROJECT/PDDA.md` plus `utils/`

Use this for templates, checklists, thresholds, and classification rules. Keep it simple until more than one repo needs it.

Verification: add `pdda config explain` to print where each active rule came from.

### Step 14: Add integration profiles instead of hardcoding Claude

Spec Kit supports many AI coding agents and can initialize different command/context files per integration ([GitHub Spec Kit docs](https://github.github.com/spec-kit/)). Your system already mentions Claude, Codex, agy, ChatGPT, Gemini, Copilot, Cursor, Continue, and MCP hosts. Make those explicit profiles.

Profiles should define:

- Agent command.
- Capabilities.
- Sandbox requirements.
- Cost visibility.
- Can self-commit?
- Can access MCP?
- Can run browser?
- Can handle multi-repo context?
- Required startup docs.

Verification: `relay doctor agents` prints each lane’s status and known limitations.

### Step 15: Promote relay containment to a first-class safety contract

The roadmap already identifies containment hardening: peer commit protection, self-commit prevention, epoch fencing, chaos suite, cross-repo E2E, and worktree isolation. Make this a named safety layer rather than scattered relay implementation detail.

Recommended artifact:

```text
PROJECT/SAFETY-CONTRACT.md
```

It should define worktree isolation, commit ownership, epoch fencing, stale-writer prevention, self-commit policy, peer-commit policy, allowed recovery actions, and rollback expectations.

Verification: the chaos suite must include concurrent peer commit, stale writer, self-commit attempt, failed repair, interrupted agent, and cross-repo target tests.

### Step 16: Turn scheduler policy into an observable contract

rebalance already has scheduled collectors governed by `SCHEDULER.md`. Make scheduler health visible to PDDA and the morning/weekly brief.

Each job should expose:

- Last run.
- Last success.
- Last repair attempt.
- Last unrecoverable failure.
- Data freshness impact.
- Whether stale data should suppress recommendations.

Verification: `rebalance index_status` or a new `scheduler_status` tool returns both human-readable and JSON output.

### Step 17: Add “evidence freshness” to every AI answer

rebalance’s value depends on local evidence. Every high-level answer should say whether the underlying sources are fresh enough.

Add a compact freshness block:

```text
Evidence freshness:
- GitHub artifacts: fresh, synced 42m ago
- Calendar: stale, last synced 3d ago
- Gmail: disabled
- Vault: fresh, indexed 11m ago
- Git pulse: repaired after push conflict, fresh
```

Verification: MCP `ask`, `semantic_query`, weekly reports, and PDDA evidence snapshots all include source freshness.

### Step 18: Create one “morning command” that joins both halves

The product moment is not “run PDDA” or “query rebalance.” It is:

```text
What should I work on today?
```

That answer should combine:

- Calendar constraints.
- Recent commits and PRs.
- Active PDDA roadmap items.
- Stale working docs.
- Open GitHub issues tied to active docs.
- Client/project balance.
- Data freshness.
- Suggested next action.

Verification: run the command for a real workday and require that every recommendation links back to one active artifact or one evidence source.

### Step 19: Package the minimum viable workflow

Do not ship the whole internal system. Package a narrow workflow:

1. Install.
2. Ingest local evidence.
3. Initialize constitution.
4. Create one feature folder.
5. Generate tasks.
6. Run checks.
7. Produce morning brief.
8. Converge after work.
9. Update changelog.

This is the “hello world” for the combined system.

Verification: a clean clone can complete the workflow with one sample repo and one sample vault fixture.

### Step 20: Decide what to delete or defer

After the above, remove anything that is only duplicating Spec Kit, Backlog.md, or Task Master. Keep only the things those systems do not give you: local evidence, privacy-preserving work context, deterministic doc governance, safety/containment, and cross-source prioritization.

Likely keep:

- rebalance local evidence layer.
- MCP tools.
- PDDA deterministic checks.
- roadmap pointer coverage.
- changelog provenance.
- relay containment and cost-observed loops.
- GitHub issue bridge.

Likely avoid building:

- a generic SDD framework.
- a full Kanban product.
- another PRD-to-task generator.
- a generic AI coding agent marketplace.
- a visual project management UI before the CLI/MCP contract is stable.

Verification: maintain a `PROJECT/DO-NOT-BUILD.md` file so scope control is explicit.

## Recommended first three implementation PRs

### PR 1: Constitution + artifact taxonomy

Add the shared constitution, update router docs, define active feature-folder shape, and add lightweight checks for required links.

Success signal: a new agent can understand the operating contract without reading the whole repo.

### PR 2: Evidence snapshot bridge

Add `rebalance pdda-evidence` or an MCP equivalent that emits a Markdown + JSON snapshot from local sources.

Success signal: PDDA can see real attention signals instead of relying only on docs.

### PR 3: Cross-artifact analyzer

Add a warn-only analyzer that compares SPEC, PLAN, TASKS, ROADMAP, CHANGELOG, and rebalance evidence.

Success signal: the analyzer catches at least one real stale/contradictory project state without blocking the workflow.

## Final positioning

Spec Kit answers: “How do I turn intent into structured implementation artifacts for AI coding agents?” ([GitHub Spec Kit docs](https://github.github.com/spec-kit/)).

rebalance + PDDA should answer: “Given my real local work evidence, which repo/project should the agents work on, under what safety contract, and how do we prove the work did not drift?”

That is the differentiated lane.
