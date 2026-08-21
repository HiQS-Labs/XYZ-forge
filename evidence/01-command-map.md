# Phase 2 — Command map

Every verb and flag below was extracted from the repo, not guessed. Each row cites the
file and line it came from. Line numbers are against `linux-bringup` @ `cd0f5bd`.

Read for this map: `ROUTER.md`, `README.md`, `ARCHITECTURE.md`, `AGENTS.md`,
`relay-automation/marathon.sh`, `relay-automation/marathon-drive.sh`,
`relay-automation/relay-turn-lib.sh`, `skills/relay-xyz/SKILL.md`,
`skills/marathon-triage/SKILL.md`, `.claude/commands/pre-marathon.md`,
`utils/marathon-plan.sh --help`, `utils/swarm-preflight.sh --help`.

---

## Summary — the brief's five, resolved

| Brief's phase | Repo's actual verb | Status |
|---|---|---|
| Compute | *(no such verb)* — nearest is `utils/marathon-plan.sh` | **DOC finding F-002** — "compute" is not repo vocabulary |
| Preflight | `utils/swarm-preflight.sh --project-doc DOC` | documented |
| Dry run | `relay-automation/marathon.sh --plan P --dry-run` | documented |
| Full run | `relay-automation/marathon.sh --plan P [--builder A]` | documented |
| Transcript location | `<root>/relay-system/<date>/marathon-<phase>-<HHMMSS>.md` | documented in source, **not in README** |

---

## 1. Compute — NO SUCH VERB (DOC finding)

There is no marathon "compute" step anywhere in the repo. `grep -rn -i '\bcompute\b'` over
`utils/`, `relay-automation/*.md`, `skills/`, and `README.md` returns nine hits, none of
which is a marathon lifecycle verb — the closest is an internal implementation comment:

> `utils/marathon-plan.sh:170` — `# One embedded Node program does the compute (parse ledger → resolve items → signals → score →`

The **functional** equivalent — the step that turns a backlog into a ranked, collision-safe
set of waves — is the marathon planner/ranker:

```bash
utils/marathon-plan.sh [--dry-run | --check] [--policy quick-wins|derisk-first]
                       [--deep] [--require-gh] [--format text|json]
```

- Cited: `README.md:440` — "the marathon planner/ranker: scores the whole ROADMAP ledger into
  waves of disjoint, collision-safe write-sets … Writes `PROJECT/2-WORKING/MARATHON-PLAN-<date>.md`"
- Usage text captured live in `evidence/02-marathon-plan-help.log` (exit 0).
- Exit codes (from its own `--help`): `0` clean · `2` usage · `3` ROADMAP unparseable ·
  `4` drift present · `5` items held · `6` gh required-but-absent.

**Note the shim/impl split:** `utils/marathon-plan.sh --help` prints its usage line as
`Usage: utils/py/marathon_plan.py …` — the Python implementation's path, not the Bash shim the
operator actually invokes. This is the `XYZ_PYTHON` dual-runtime shim pattern
(`README.md:271-277`) leaking its inner name into user-facing help. Cosmetic; logged as F-003.

The canonical lifecycle the repo *does* define, from `.claude/commands/pre-marathon.md:6-22`,
is **triage → preflight → dry-run → confirm → fire**, with step 1 delegating ranking and wave
formation to the `marathon-triage` skill (`skills/marathon-triage/SKILL.md`), not to a
"compute" command.

## 2. Preflight

```bash
utils/swarm-preflight.sh (--project-doc DOC | --gh-issue N [--gh-issue N ...]) \
                         [--target-root REPO] [--out DIR] [--format text|json] [--dry-run]
```

- Cited: `utils/swarm-preflight.sh:94-103` (its `usage()` heredoc).
- Cited: `README.md:439` — "marathon intake planner: turns a project doc or a GH-issue bundle
  into a marathon-ready run packet (freshness + fix-still-required checks, readiness gate …)".
- Exit codes, `utils/swarm-preflight.sh:105-106`:
  `0` ready · `2` usage · `3` contract missing/invalid · `4` stale/already-landed ·
  `5` not marathon-ready · `6` blocked/missing-target · `7` ambiguous.
- Default packet output: `relay-system/preflight/<date>/<slug>` (`utils/swarm-preflight.sh:100`).
- `--dry-run` runs all checks and prints the verdict but writes no packet directory
  (`utils/swarm-preflight.sh:102`).

**Prerequisite the flag list does not state:** a candidate is only `READY` when its capture doc
carries valid JSON under a heading matching `Preflight Contract`
(`skills/marathon-triage/SKILL.md:78-80`). Preflight validates a contract; it does not author one.

## 3. Dry run

```bash
relay-automation/marathon.sh --plan MARATHON.yaml --dry-run
```

- Cited: `relay-automation/marathon.sh:103` — "`--dry-run   Render each phase's relay file and
  print the tick seed; exit without running.`"
- Same flag exists one level down at `relay-automation/marathon-drive.sh:53` — "render relay
  file and print tick seed cmd, then exit".
- Mandated by `.claude/commands/pre-marathon.md:14-16`: "For every plan classified `READY`, run
  its supported marathon invocation with `--dry-run` … A failed or ambiguous dry-run makes that
  plan non-fireable."

## 4. Full run

```bash
relay-automation/marathon.sh --plan MARATHON.yaml [--builder codex] [--phases-dir DIR] \
                             [--pre-advance-cmd CMD] [--target-root DIR] [--force] \
                             [--retry PHASE-ID] [--closeout-pr]
```

- Cited: `relay-automation/marathon.sh:15-16` (header usage) and `:84-115` (`usage()` heredoc).
- Default builder is `codex` — `relay-automation/marathon.sh:90-93`, and `:18-21`:
  "`--builder claude` spawns a headless Claude Code CLI subprocess instead: a SEPARATE,
  PER-CALL API-BILLED turn-taker … Use it only as an explicit, cost-acknowledged choice."
  Budget defaults, `README.md:334-335`: `CLAUDE_MAX_BUDGET` = $0.50, `CLAUDE_MAX_TURNS` = 12.
- **Plan-location constraint (GH-212), `relay-automation/marathon.sh:23-26`:** the `--plan` YAML
  and its phase briefs must resolve under `PROJECT/2-WORKING/` in the target repo. Paths under
  the harness's own home are exempt (that is what makes the shipped
  `relay-automation/MARATHON.example.yaml` runnable). Override:
  `MARATHON_ALLOW_PLAN_OUTSIDE_WORKING=1`.
- Phases run **strictly one at a time** in `depends_on` order, and the run **HALTS on the first
  phase failure**, leaving that phase's `ESCALATION.md` and not starting later phases
  (`relay-automation/marathon.sh:4-8`). `marathon.complete` is emitted only when every phase is
  approved.
- Per-phase round cap = `2 * max_review_rounds + 1` (`relay-automation/marathon.sh:10`).
- Default gate before `phase.approved` is `bash validate.sh`, per phase
  (`relay-automation/marathon.sh:102`).

### Exit codes

`marathon.sh` (`:50`): `0` all phases approved · `N` the failing phase's marathon-drive exit
code · `2` usage/parse error.

`marathon-drive.sh` (`:61-66`) — the codes that actually classify a failure:

| Code | Meaning |
|---|---|
| `0` | phase approved + gate passed |
| `2` | usage |
| `3` | relay no-progress |
| `4` | relay cap / mismatch |
| `5` | pre-advance gate failed (or failed `--requires-test`) |
| `6` | **containment violation** — turn-taker reverted an off-lane edit |
| `7` | **turn timeout / hang** |
| `8` | **lane parked** — GH-45 attempt cap, no token seeded; re-fire with `--force` |
| `9` | post-approve command failed (phase remains approved) |
| `108` | **gate killed** by the GH-390 resource guard; phase escalates as `gate-killed` (`README.md:243-245`) |

> **Correction to the brief.** The brief lists exit `8` as "relay block invalid". In this
> revision exit `8` is **lane parked (GH-45 attempt cap)** — `marathon-drive.sh:65-66`. There is
> a separate `bin/validate-relay-block` binary, but its failures do not surface as marathon
> exit 8. Logged as F-004.

### Gate resource guard (GH-390) — env levers, `README.md:236-248`

| Variable | Effect |
|---|---|
| `MARATHON_GATE_TIER` | `full` (1800s wall / 1200s CPU, default) or `fast` (300s / 240s) |
| `MARATHON_GATE_WALL_S` / `_CPU_S` / `_RSS_MB` | per-cap override (RSS default 8192 MB) |
| `MARATHON_GATE_POLL_S` | sampling interval (default 1s) |
| `MARATHON_GATE_GUARD=0` | **disables ALL timeout and memory protection** — README explicitly warns against it |

## 5. Transcript output location

Three distinct artefact families, all inside the **harness** repo (not `--target-root`):

**a) The saved transcript** — `relay-automation/marathon-drive.sh:877-881`:

```
<transcript-root>/<YYYY-MM-DD>/marathon-<PHASE_ID>-<HHMMSS>.md
```

`<transcript-root>` comes from `rtl_transcript_root()`,
`relay-automation/relay-turn-lib.sh:120-137`: it is `<target_root>/relay-system` unless
`XYZ_ARCHIVE_ROOT` is set, in which case that must be an **absolute path to an existing
directory** or the resolver hard-errors (`:130-137`). The transcript is `git add`ed and
committed with message `marathon: phase <ID> transcript saved (<TASK>)`
(`marathon-drive.sh:889-894`).

**b) Live per-phase state** — `relay-automation/marathon-drive.sh:679-682`, `:837`, `:857`:

```
<root>/marathon-system/<phase-id>/RELAY.md         # the live relay thread
<root>/marathon-system/<phase-id>/ESCALATION.md    # written on failure, carries `reason:`
```

Default `--phases-dir` is `<repo-root>/marathon-system` (`marathon-drive.sh:682`, GH-484 moved
it there from the legacy `phases/`). `marathon.sh:94` repeats the same default.

**c) The event log** — `.tick/events/`, carrying `phase.start` / `phase.approved` /
`phase.escalated` / `marathon.complete` (`relay-automation/marathon.sh:11-12`). `.tick/` is
gitignored and per-device (`skills/relay-xyz/SKILL.md:482-483`).

**d) Whole-run completion telemetry** — `XYZ.json` at the harness repo root, appended by
`utils/telemetry/append-xyz-completion.sh` on both the success tail and the halt path
(`relay-automation/marathon.sh:69-80`). Local + gitignored.

---

## 6. Prerequisites the map depends on

- **The relay-xyz guard.** `relay-automation/hooks/relay-xyz-guard.sh` is a `PreToolUse` hook
  that blocks any Bash call executing `marathon.sh`, `marathon-drive.sh`, `relay-drive.sh`,
  `poll.sh`, `codex-turn.sh` or `agy-turn.sh` until the session proves it loaded the
  `relay-xyz` skill (`:105-128`). Proof is either a `Skill` call naming `relay-xyz` (`:84-87`)
  or a Bash command running `find-harness.sh` (`:93-95`). This fired on this machine — see F-001.
- **A builder on PATH.** `skills/relay-xyz/SKILL.md:213-220` — agy and Codex are the builders;
  Claude CLI is not a default builder. `find-harness.sh --check` reports which are present.
  On this host: **neither** (`evidence/02-deps-probe.log`). See F-005.
- **PDDA.** `README.md:107-108` — "Marathon **requires** PDDA, because the preflight scripts rely
  on PDDA's opinionated docs/roadmap structure". Source: `utils/pdda/PDDA-SOURCE.md`,
  installer notes in `utils/pdda/PDDA-INSTALL.md`. Upstream repo per `README.md:88`:
  `https://github.com/Hypercart-Dev-Tools/pdda`.
- **The gate must run from a normal clone**, not a linked worktree (`ROUTER.md`, "Command rails"):
  both gate entry points refuse from a linked worktree (GH-45); `XYZ_ALLOW_WORKTREE_GATE=1` is
  the announced override.
