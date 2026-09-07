**NO FIRSTHAND VERIFICATION CITED** — treat conclusions as conditional (codex's answer carries an unsupported [Pass]/verified/confirmed-style claim with no quoted span or file:line citation nearby, despite the consult PREAMBLE asking advisors to cite evidence.)

> **ATTESTATION**
> Model: gpt-6-astra
> Provider: openai
> Sandbox: read-only

Reading additional input from stdin...
OpenAI Codex v0.153.4
--------
workdir: /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-86231-968w76hh
model: gpt-6-astra
provider: openai
approval: never
sandbox: read-only
reasoning effort: low
reasoning summaries: none
session id: 01a0788d-ea2f-7c12-84d8-3e663a5ee716
--------
user
You are an INDEPENDENT advisor in a one-shot cross-model consult. Another model is answering the SAME question separately and a coordinator will reconcile both answers, so give your own honest, specific read — do not hedge toward a consensus you cannot see. Read any repo files the question references (cite file:line). Respond with: (1) a short direct ANSWER; (2) graded FINDINGS — [Blocker]/[Should]/[Nit]/[Pass] — where applicable; (3) a one-line RECOMMENDATION. You are ADVISORY ONLY: output your analysis as text; do not rely on writing files (you are running in a throwaway copy).

=== CONSULT QUESTION ===
# Consult Question: Needle Oracle Tool Extraction Simplification

Context: We are building a "what to do next" Oracle using the 45M Needle model to run on the M1 Max ANE (Orion runtime) for RebalanceOS. The goal is to train it on historical XYZ-CLIO markdown logs.

The original issue (#467) proposed extracting full JSON tool calls (name + arguments) to form the training dataset.

I proposed a "ponytail" simplification:
Instead of building a robust parser to extract and validate full JSON tool schemas and arguments, we just use a simple regex to extract the **tool name only** (e.g., `run_tests`, `create_pr`, `read_file`) from the markdown. We then train Needle to predict ONLY the tool name string.

Question:
Does stripping the tool arguments from the training data fundamentally break the usefulness of this Oracle for its intended role in RebalanceOS, or is predicting just the tool name sufficient for a "real-time recommendations" sentinel? What are the concrete risks of skipping JSON argument extraction?

codex
I’ll check the repository context, then assess whether tool-name prediction preserves the Oracle’s intended decision.

exec
/bin/zsh -lc "pwd; rg --files -g '*467*' -g '*NEEDLE*' -g '*ORACLE*' -g 'ROUTER.md' -g 'GUIDING-PRINCIPLES.md' -g '*Needle*' -g '*needle*' -g '*Oracle*'" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-86231-968w76hh
 succeeded in 0ms:
/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-86231-968w76hh
GUIDING-PRINCIPLES.md
test/gh467-index-only-lane-blocked.sh
relay-system/2026-09-06/needle-oracle-140920/needle-oracle.PROMPT.txt
evidence/marathons/run-1/artefacts/events/2026-08-20T13-24-22.467Z-codex-claimed-MARATHON-R1P2-TURN.jsonl
ROUTER.md

exec
/bin/zsh -lc "cat ROUTER.md; cat GUIDING-PRINCIPLES.md; rg -n -i 'needle|oracle|orion|tool.name|tool.calls' PROJECT relay-system/2026-09-06/needle-oracle-140920 README.md | head -100" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-86231-968w76hh
 succeeded in 0ms:
# ROUTER.md

This file is the first entry point for an AI agent working in this repo: it tells you what to read, what to run, and which files are canonical.

## Role split

- `ROUTER.md` = startup order and canonical entry points
- `GUIDING-PRINCIPLES.md` = the *why*, and the canonical North Star: durable, reversible, DRY — extend what exists rather than forking a parallel system
- `AGENTS.md` = behavioral rules, decision quality, reversibility, blast radius, proof
- `README.md` = human-facing repo/product overview
- `ROADMAP-DASHBOARD.md` = the generated, human-readable view of the roadmap ledger (read this; regenerate with `utils/roadmap-dashboard.sh`); the RELEASES DB (`releases.db` via `releases.sql`) is the source of truth (`ROADMAP.md` retired per GH-269)
- `CHANGELOG.md` = the end-of-iteration running log (first-class PDDA artifact; governed by `PROJECT/PDDA.md`)
- `RELEASES.md` = forward-looking release-planning ledger (first-class PDDA artifact; governed by `PROJECT/PDDA.md`)
- `HARNESS-MODELS-REGISTRY.md` = evaluated agent harnesses, supported model grades (A/B/C), and CLI flags
- `MACHINE-CONTRACTS.md` = the Jog ↔ Preflight ↔ Marathon machine-contract reference (`marathon-invocation@1`, `marathon-drive/result@1`) and their version/deprecation policy
- `PROJECT/**` docs = canonical execution detail for a specific effort
- `PROJECT/PDDA.md` = document contract and automation rules (incl. the CHANGELOG contract)
- `PROJECT/CONSTITUTION.md` = the policy of record: PDDA's lane and its non-negotiables (deterministic-before-LLM, verified-success-only, reversibility, local-first)
- `PROJECT/DO-NOT-BUILD.md` = the anti-scope list — product directions PDDA must not become (companion to `CONSTITUTION.md`)

## Startup sequence

1. Read `ROUTER.md` to understand the repo's operating order and canonical files. -> expect one clear next file, not a repo-wide scavenger hunt.
2. Read `AGENTS.md` before making recommendations or edits. -> expect explicit assumptions, a reversibility read on consequential changes, and verified claims only.
3. Read `ROADMAP-DASHBOARD.md` (or `python3 utils/py/releases_app.py roadmap list`) to find the active effort or parked intake. -> expect links outward to the canonical `PROJECT/**` docs; the roadmap is a pointer ledger, not a plan body. (`ROADMAP.md` is retired — the RELEASES DB is the single source of truth.)
4. Read the linked `PROJECT/**` document that owns the work you are touching. -> expect the near-top `## Status` table to tell you what was just completed and what is next.
5. If the task touches project docs, read `PROJECT/PDDA.md` and follow the PDDA contract. -> expect `PROJECT/2-WORKING` docs to have frontmatter, the exact status table, and QA gates when phased.
6. Before reporting success on code or runtime work, run `./validate.sh`. -> expect the suite to stay green; do not claim completion if it fails or was skipped.
7. Before reporting success on doc-hygiene or roadmap work, run `utils/pdda/pdda.sh run` (or the relevant `utils/pdda/pdda.sh <check>` subcommand). -> expect deterministic findings first, then any LLM review.

## Canonical rules

- Do not put phase checklists, build steps, or deep execution notes in the roadmap ledger.
- Every active doc in `PROJECT/2-WORKING/` must be reflected by a pointer row in the roadmap ledger (the RELEASES DB) that links it. A working doc that should not appear opts out with `roadmap_exempt: true` in its frontmatter. Governance lives in `PROJECT/PDDA.md` → "ROADMAP contract".
- Promoting a capture from `1-INBOX` to `2-WORKING` is a DB-verb procedure (`roadmap repoint` + `roadmap update` / `roadmap move`), never a markdown edit — the exact steps and their two known gate traps (`updated:` frontmatter key, bullet-format `raw_text`) live in `SOP.md` → "Step 1b: Promoting a capture from 1-INBOX to 2-WORKING (releases-mode)".
- Every captured GitHub issue doc in `PROJECT/1-INBOX/GH-*.md` must also be parked as a queue row immediately at intake — `python3 utils/py/releases_app.py roadmap add --issue-num N --issue-url U --title T --created YYYY-MM-DD --doc-path P` (or `hq park`, which routes there automatically in this repo) — then promoted or removed later. Governance lives in `PROJECT/PDDA.md` → "GitHub issue intake" + "ROADMAP contract".
- Do not create a second competing plan when a canonical `PROJECT/**` doc already exists.
- Issue-first: any change beyond a **2–3 line** fix opens a GitHub issue first, then a pointer doc **named after the issue** (`GH-<number>-VERY-SHORT-DESC.md`, e.g. `GH-1234-SHOWME-COMMAND.md`), and that capture is **parked in the roadmap ledger immediately** (`releases roadmap add`) before execution begins. The issue is the signal stream; the pointer doc is the execution surface of record. Genuinely trivial edits (≤2–3 line fixes, typos, path repoints, doc-only one-liners) are exempt. Governed by `PROJECT/PDDA.md` → "GitHub issue intake".
- Runtime triage labels: since the `XYZ_PYTHON` flip the harness is dual-runtime, so any harness-bug issue gets a `runtime:` label — `runtime:python` (default path), `runtime:bash` (`XYZ_PYTHON=0` opt-out), or `runtime:parity` (the twins diverge). `/file-xyz-bug` harvests and applies it; for in-repo intake (`/triage`, hand-filed `gh issue create`) apply it by hand. Omit rather than guess — a wrong runtime tag misroutes triage.
- **`GH-<n>` numbering spans two repos.** This repo succeeded [`Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm`](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm) and the migration did **not** renumber references, so a `GH-<n>` in a source comment, test name, or CHANGELOG entry may belong to either repo. Upstream ledger entries are preserved verbatim in [`docs/ROADMAP-UPSTREAM-ARCHIVE.md`](docs/ROADMAP-UPSTREAM-ARCHIVE.md), which states its own numbering caveat and is not parsed by anything. Where an upstream number is cited from code that ships here, mirror it as a closed `[upstream archive]` issue so the citation resolves locally (#407, #408 are the pattern) rather than editing the comment. Raised externally as GH-406 §3.1.
- Do not override deterministic PDDA findings with prose.
- Do not report a win you did not verify with the relevant script or test.
- Update `CHANGELOG.md` at the end of each iteration; its governance lives in `PROJECT/PDDA.md` — do not re-specify CHANGELOG rules in `AGENTS.md` or elsewhere.

## Command rails

For repo correctness:

```bash
bash githooks/install.sh        # ONCE PER CLONE — wires the pre-push gate (GH-544)
bash githooks/install.sh --check # is this clone gated? exit 1 if not
./validate.sh              # the gate — PARALLEL by default (GH-544), auto-sized to the host (GH-35)
./validate.sh --print-mode # which mode would this host pick, and why — runs nothing
./validate.sh --sequential # force the sequential run (~16 min)
./validate.sh --tier 2 --subsystem hq   # GH-35: one subsystem's focused suites (pre-push speed, NOT evidence)
./validate.sh --auto       # GH-35: classify the git diff, run the minimal safe tier (fails closed to 3)
./validate.sh --throttle   # GH-35: 2 workers under nice — quiet-machine mode (--burst restores full width)
bash ci-local.sh           # the QUALIFYING run — sequential + writes the gate record (GH-509/GH-536)
```

**Both gate entry points refuse to run from a linked git worktree (GH-45)** — a worktree shares
the parent clone's `.git`, and an observed suite escape corrupted the parent (core.bare, origin,
remote refs, development). Run the gate from a normal clone; `XYZ_ALLOW_WORKTREE_GATE=1` is the
announced override for disposable runs.

**Hosted CI fires on nothing while this repo is private (GH-544).** The gate runs locally at the push
boundary instead, so `githooks/install.sh` is part of setting up a clone — the hook lives in
`.git/hooks/`, which does not travel with a clone, and an uninstalled one pushes unverified. One
install covers every branch and every linked worktree of that clone (GH-549). Bypass with
`git push --no-verify` or `XYZ_SKIP_PREPUSH=1`; both announce themselves. Re-arm CI when the repo
goes public (free there).

**Parallel became the default on 2026-08-14 (GH-544)** because the local gate is the only gate during
the private phase, and a 16-minute gate does not get run — it gets skipped, which is worse than a
3-minute one. **GH-35 (2026-08-18) rebalanced the width to `cores/2` (floor 2, cap 4) and put every
worker under `nice -n 10`** — the original `cores − 2` (up to 8) saturated developer machines badly
enough to wedge the editor; `--burst` buys the old full-core width back for unattended runs, and
`--throttle`/`--quiet-cpu` pins 2 workers. Ambient levers: `XYZ_VALIDATE_THROTTLE=1`,
`XYZ_VALIDATE_MAX_JOBS=N`, `XYZ_VALIDATE_PARALLEL` (flags > MAX_JOBS > THROTTLE > PARALLEL > host
detection; malformed values exit 2 naming the variable). Below 4 cores, or where `xargs -P` is
unsupported, the run **falls back to sequential and says so** — every run prints the mode it chose
and the reason, so a fallback is never silent.

**GH-35 also added TIERED SELECTION on top, as a separate axis from width.** `utils/ci-route.sh`
owns one fail-closed subsystem registry (hq, releases, telemetry, ate, swe-diagram, pdda,
agent-chorus); a push the classifier rates `tier=2` runs only those focused suites at the boundary,
`--tier 1` runs the docs gate, and everything else — unknown paths, test edits, kernel surfaces —
runs the full suite. `--auto` classifies a local diff the same way. Tiers 1 and 2 are pre-push
speed and are labelled NOT promotion evidence; only `ci-local.sh`'s sequential full run qualifies
(GH-509).

**What still qualifies a claim is unchanged.** `./validate.sh` in either mode is a self-check;
`ci-local.sh` is the run that writes the evidence record, it does **not** call `validate.sh`, and it
stays sequential. The macOS promotion boundary in `ci.yml` pins `--sequential` explicitly for the same
reason. GH-528 Phase 2 (multi-width stress evidence) is still **owed** — the flip was an operator
decision taken with that evidence outstanding, mitigated by the announced fallback rather than
discharged. See `PROJECT/2-WORKING/GH-528-TEST-SUITE-RECALIBRATION.md`, #509 and #544.

For document hygiene:

```bash
utils/pdda/pdda.sh run
```

For targeted PDDA debugging (subcommands of the single dispatcher):

```bash
utils/pdda/pdda.sh frontmatter
utils/pdda/pdda.sh status-table
utils/pdda/pdda.sh hardcoded-paths
utils/pdda/pdda.sh roadmap
utils/pdda/pdda.sh roadmap-coverage
utils/pdda/pdda.sh changelog
utils/pdda/pdda.sh stale
utils/pdda/pdda.sh issue-doc-sync   # warn-only: flags 2-WORKING/GH-*.md docs drifted from their GitHub issue state
utils/pdda/pdda.sh releases         # validate RELEASES.md, the OPTIONAL release-planning ledger (warn-only; skips a missing file)
utils/pdda/pdda.sh releases-current # read-only roll-up: RELEASES.md entries whose Status isn't "Shipped"
utils/pdda/pdda.sh quad-concepts    # opt-in: requires a "## Quad Concepts" section of 1-4 bullets (lever: .pdda-quad / PDDA_QUAD)
utils/pdda/pdda.sh glance           # read-only roll-up: title + Quad Concepts for each PROJECT/2-WORKING doc
utils/pdda/pdda.sh gh-refresh       # refresh the cached GitHub issue-state file issue-doc-sync reads offline (needs gh)
utils/pdda/pdda.sh catchup          # LLM repo triage + ROUTER.md recommendations (delegates to pdda-catchup.sh)
utils/pdda/pdda.sh doc-ready        # LLM readiness review — set PDDA_LLM_BIN (codex/claude/agy) for recommendations, else it self-skips
```

## The RELEASES DB — two subsystems, one ledger (GH-32 / GH-69)

`releases.db` + `releases.sql` hold TWO mirrored subsystems, both operated through ONE CLI,
`utils/py/releases_app.py` (alias: the `/releases` skill). Read
[RELEASES-DB-FAQS.md](RELEASES-DB-FAQS.md) before merging either file — the SQLite binary is
derived; the SQL dump is what git actually merges, and a conflicted merge has a one-command
resolver (`utils/releases-merge-resolve.sh`).

```bash
python3 utils/py/releases_app.py check          # trio consistency, receipt chain, crash recovery
python3 utils/py/releases_app.py next           # the next unshipped release, by target date
python3 utils/py/releases_app.py add|ship ...   # RELEASE writes — never hand-edit releases.sql
python3 utils/py/releases_app.py roadmap add ... # GH-238: park one issue as a roadmap row (the intake write path)
                                                #   GH-249: put `rated N/N/N/N [ovr N]` in --raw-text to score it
python3 utils/py/releases_app.py roadmap rate ...# GH-253: score a row that is ALREADY parked (--force to re-score)
python3 utils/py/releases_app.py roadmap list   # read the roadmap rows (--json for machine consumers)
python3 utils/py/releases_app.py roadmap sync   # LEGACY-mode only (mirrors ROADMAP.md); a guarded no-op in this repo
```

**Subsystem 1 — releases** (GH-32, Phase 0 side-by-side): the release ledger. App-managed writes
only; `RELEASES.md` is still the human file during the shadow phase.
**Subsystem 2 — the roadmap ledger** (GH-69 shadow → GH-238/GH-243 canonical → GH-269 retired ROADMAP.md): since the
`ROADMAP_SOURCE=releases` flip, `roadmap_items` IS the ledger — write rows with
`releases roadmap add` (or `hq park`), read with `roadmap list` / `ROADMAP-DASHBOARD.md`.
`ROADMAP.md` has been retired and removed. `roadmap sync` exists for legacy-mode repos only and
no-ops here by design (it would delete `add`-parked rows). Pinned by `test/gh69-roadmap-shadow.sh`,
`test/gh238-hq-releases-mode.sh`, and `test/gh269-roadmap-retired.sh`.

## Routing hints

- If the task is about current priorities or active work, start in `ROADMAP-DASHBOARD.md` (or `releases roadmap list`), then follow the linked `PROJECT/**` doc.
- If the task changes the roadmap ledger, write through the CLI (`releases roadmap add` for intake; `hq park` routes there automatically) and finish by regenerating `ROADMAP-DASHBOARD.md` (`utils/roadmap-dashboard.sh`) — the push gate refuses a ledger write with a stale dashboard (GH-243).
- If the task touches `releases.db`, `releases.sql`, or a merge conflict on either, start in [RELEASES-DB-FAQS.md](RELEASES-DB-FAQS.md); writes go through the CLI, never a hand-edit.
- If the task is about fresh GitHub intake or duplicate-prevention, start in the dashboard's queue section (or `releases roadmap list`), then follow the linked `PROJECT/1-INBOX/GH-*.md` capture doc.
- If the task is about document quality, active-doc lifecycle, roadmap sprawl, or automation policy, start in `PROJECT/PDDA.md`.
- If the task is about the CHANGELOG, provenance, or end-of-iteration logging, the governance is in `PROJECT/PDDA.md` (the "CHANGELOG.md — end-of-iteration record" contract).
- If the task is about release planning, ledger health, cleanup, authoring, or publishing, invoke `/releases`. It reads and synthesizes `RELEASES.md` first, then routes explicit requests into confirmation-gated cleanup, planning, or publication; governance is in `PROJECT/PDDA.md` (the "RELEASES.md — release ledger" contract). It conditionally points strategic drift to `/radar` and a frozen path-to-ship to `/finish-line` without duplicating either workflow.
- If the task is about the `tick` runtime, event projection, or multi-agent coordination kernel, start in `README.md`, then `bin/`, `src/`, `test/`, and the active project doc.
- If the task is about the **Aider ↔ OpenRouter** turn-taker lane (`relay-automation/aider-turn.sh` — an OpenAI-standard build lane discrete from Codex; `AIDER_MODEL`/`OPENROUTER_API_KEY`, `--builder aider`), start in `PROJECT/3-COMPLETED/GH-77-AIDER-OPENROUTER-LANE.md`. The shim owns the tick token ops (Aider can't run shell mid-turn), asserts token ownership before launching Aider, and runs Aider `--no-auto-commits` (the harness commits).
- If the task is about running, driving, or reviewing via the relay (`relay-automation/` — `relay-drive.sh`, `poll.sh`, the turn shims, `marathon*.sh`), **invoke the `relay-xyz` skill first — do not improvise the handoff or hand-roll a harness from `ls relay-automation/`.** The skill owns the locator, sandbox rules, exit codes, and the safety boundary; a `PreToolUse` guard (`relay-automation/hooks/relay-xyz-guard.sh`) blocks driving a harness driver before the skill is loaded. For the two live-Claude-windows, same-machine duel recipe (Reporter↔Maintainer with a human go-gate), the copy-paste form is [relay-automation/DUELING-CLAUDES.md](relay-automation/DUELING-CLAUDES.md).
- If the task is about the ATE (Automated Testing Environment) skill — unattended variation-test fuzzing whose implementation lives under `utils/ate/` — start at its canonical interface in `skills/ate/SKILL.md`.
- If the task is about relay session telemetry, the `focus5float` health feed, or extraction scripts under `utils/telemetry/`, start in `PROJECT/1-INBOX/GH-24-RELAY-TELEMETRY-EXTRACTOR.md`.
- If the task is about live per-session completion telemetry — the `XYZ.json` log every relay/marathon/swarm session appends to at the harness repo root (schema: `harness`/`sessionId`/`health`/`title`/`description`/`updatedAt`), the shared writer `utils/telemetry/append-xyz-completion.sh`, or the shared health mapping `utils/telemetry/health-lib.sh` — start in `PROJECT/1-INBOX/GH-75-XYZ-JSON-COMPLETION-TELEMETRY.md`. `XYZ.json` is local + gitignored (machine-specific).
- If the task is about cross-repo HQ tooling (`utils/hq/` — `hq.sh` single-repo actions, `rollup.sh` the Obsidian daily ROADMAP rollup, `marathon-scan.sh` the cross-repo marathon-preflight aggregator, `hq-lib.sh` the shared repo registry), start in `PROJECT/3-COMPLETED/GH-27-ROADMAP-DASHBOARD.md` and `PROJECT/3-COMPLETED/GH-158-HQ-MARATHON-SCAN.md`. The two rollups are deliberately separate today (`rollup.sh` → Obsidian, generic; `marathon-scan.sh` → hub repo, preflight-aware) and are not yet bridged — tracked in `PROJECT/1-INBOX/GH-192-HQ-MARATHON-OBSIDIAN-ROLLUP.md`.
- If the task is about a proposed roadmap-steward agent, start here, then read `PROJECT/PDDA.md` and its `Proposed roadmap steward extension` section.
- If the task is about finding or picking a skill for a job, see `ARCHITECTURE.md` → "Skills Index" for a one-line inventory of every skill in `skills/`.
- Issue-first SOP: any change beyond a 2–3 line fix (and every project plan) opens a GitHub issue *first*, then gets a pointer doc named after the issue at `PROJECT/1-INBOX/GH-<number>-VERY-SHORT-DESC.md` — e.g. `GH-1234-SHOWME-COMMAND.md` — and that capture is parked in the roadmap ledger queue immediately via `releases roadmap add` (format + lifecycle owned by `PROJECT/PDDA.md` → "GitHub issue intake"), following the normal `1-INBOX` → `2-WORKING` flow. Genuinely trivial edits (≤2–3 line fixes, typos, path repoints, doc-only one-liners) are exempt and commit directly.
# Guiding Principles

North star for **xyz-3-agents-swarm**, the multi-agent coordination harness behind the `tick` event-log kernel and `relay-automation/` relay stack. When a choice is unclear, the option that keeps agents synchronized, contained, and verifiable — without leaking or destroying work — wins. AGENTS.md is the behavioral playbook; ROUTER.md is the entry-point map; this is the *why*.

## The North Star

There is no perfect architecture and no finished codebase. The bar is not perfection — it is that
every change leaves the harness **more durable, more reversible, and less duplicated** than it found
it, and that the three stay in balance:

- **Durable** — it removes the root cause and the next planned change builds on it, rather than being
  torn out when the obvious next feature lands.
- **Reversible** — the cost of being wrong is known and bounded before the change lands. A change
  nobody can undo is a bet, not a fix, and gets treated as one.
- **DRY** — nothing canonical lives in two places where it can drift. One source of truth, and every
  other surface is a pointer or a projection of it.

**Do not build a new layer, module, or sub-system when an existing piece of code can be extended
easily, logically, and safely.** Extending an existing abstraction beats standing up a parallel,
siloed system, even when the parallel path is faster to write today — the parallel path is what
later has to be kept in sync, and what silently drifts when it isn't. If the existing abstraction
genuinely cannot carry the new case, say so in one line, with the reason, before forking.

These three pull against each other, and that tension is the decision, not a problem to average
away: the most durable fix is often the least reversible, and collapsing two near-duplicates is a
DRY win that can widen the blast radius. Name the trade and pick; do not split the difference by
building both.

This section is canonical. `AGENTS.md` owns how it is applied to a given change — the reversibility
scale (§3) and blast-radius sizing (§4) — and principles 6, 7, and 10 below are the build-time and
done-time expressions of it. Where another doc restates this, that doc is the copy and this is the
original.

## Purpose

`tick` coordinates Claude Code, Codex, and agy (Antigravity CLI) on the same branch without collision: a shared local event log under `.tick/events/`, claims serialized by `O_EXCL` locks, and a `Marathon` harness that chains multi-phase build→review cycles from a `MARATHON.yaml`. The relay layer (`relay-automation/`) drives headless turns, isolates agent writes to worktrees, and enforces an allowlist so no headless agent destroys work it didn't intend to touch. The goal: a multi-agent swarm safe enough to run against a real external codebase and correct enough that its output is worth shipping.

## The quality bar

Every agent turn is a signal. A turn is high-quality only when it is all four:

- **Attested** — carries its receipts: source, evidence, confidence. Never a bare verdict. A relay review names which claim is wrong and why; a build turn names the seam it touched.
- **Relevant** — ranked, not dumped. Volume is not value. One real bug beats five nits and a phantom.
- **Fresh** — current, not stale. A turn that reads a stale `STATE.md` or misses an epoch fence is wrong by construction.
- **Structured** — one shape, clean for the operator to read and for downstream agents to feed on.

Fail a pillar, and the turn, feature, or relay review isn't done.

## How it's built

1. **Coordination is local-transport only.** `.tick/events/` is the shared bus; claims resolve from there, not from a remote. No per-event push/fetch; no remote dependency at runtime. A coordination primitive that reaches out is a coordination primitive that can fail or leak.

2. **One canonical event log; every surface is a projection.** `tick` accretes events; `STATE.md` is the current projection. Reads go through the projection; writes go through a `claim/take/scope/done` verb. Nothing canonical lives in two places where it can drift. An agent that hard-codes state outside `.tick/` is creating drift.

3. **Containment is non-negotiable.** A headless turn must not: self-commit mid-turn, orphan a peer's concurrent commit, or write outside its allowlist. The allowlist, worktree isolation, and commit-bypass guard exist because a driven agent will do all three if unconstrained — not hypothetically, but as documented live incidents (GH-13, GH-14, GH-17). New relay paths must clear the containment bar before they ship.

4. **Skill-first; never improvise the harness.** The `relay-xyz` skill owns the locator, sandbox rules, exit codes, and the safety boundary. A session that improvises those from `ls relay-automation/` silently skips the skill's safety layer. The `PreToolUse` guard (`relay-automation/hooks/relay-xyz-guard.sh`) enforces this by blocking driver calls before the skill loads. Add capabilities to the skill; do not work around it.

5. **Adversarially proven before commercially viable.** The harness exists to run against real codebases. Features in the adversarial-hardening track (epoch fencing, chaos suite, cross-repo E2E) must be verified to survive deliberate abuse — stale writers, zombie claims, macOS case-sensitivity, concurrent peer commits — not just the happy path. A feature that clears the happy path and skips chaos is half-done.

6. **Build durable, not band-aid.** Durable means it removes the root cause and the next planned change builds on it — not a patch torn out when the obvious next feature lands. A band-aid is wasted work unless a demo strictly needs one, and a demo band-aid is tagged for removal so it isn't silently inherited.

7. **Least code that clears the bar.** Node standard library only — no deps, no lockfile; the repo ships no root manifest. Prefer reusing or extending what exists; the smallest change that stays correct, contained, and durable wins. Net-new code is a cost to justify. Deleting code counts as progress.

8. **Honest; the operator decides.** Surface what failed and why — never mask a stall as success or an escalation as a stall. A headless turn self-repairs within a bounded exit-code menu (`exit 3` stall, `exit 4` escalated-by-design, `exit 6` containment revert), then stops; it never loops forever or silently swallows an error. Destructive actions require explicit authorization.

9. **Docs are resumable runtime state (PDDA).** Agent work is stoppable, resumable, and handed off from `PROJECT/**` alone — ROUTER points, project docs hold detail, CHANGELOG logs dated outcomes. ROADMAP.md is a pointer/ledger only; execution detail lives in the linked `PROJECT/**` doc. If reality and the docs disagree, the docs are the bug.

10. **Done means verified.** "Done" is `validate.sh` green, the relevant PDDA checks passing, and any relay review returning `Approved` — not work that looks finished. An unverified success claim is itself a low-quality signal.

11. **Issue-first; every non-trivial change has a signal stream.** Any change beyond a 2–3 line fix opens a GitHub issue first, then gets a `GH-<number>` in-repo pointer doc, then lands. The issue is the machine-queryable signal stream; the `PROJECT/**` doc is the execution surface of record. Genuinely trivial edits (≤2–3 line fixes, typos, path repoints, doc-only one-liners) are exempt.

12. **Independent Verification (Separated Grading)** — The agent that produces a turn must not be the sole grader of its own quality. Verification must be performed by an independent deterministic check or a separate reviewing agent before the lock releases. Applies to: the relay's structural block validator (`bin/validate-relay-block` — Phase 1 of GH-21), consult-verify diversity (Phase 3), and any other post-generation quality gate.

13. **A green gate without a witnessed red control is not evidence.** Every new or materially changed decision gate ships a recorded demonstration that it fails for the right reason: a pre-fix replay, deliberate mutation, or controlled bad fixture. Do not mistake a check that validates the artifact it just generated (#351) or a parity check that compares a lane to itself (#348) for evidence; both shapes are structurally unable to falsify their claim.

## Applying this

Adding a feature or weighing a tradeoff, ask: *does this keep agents coordinated without collision, contained within their scope, and verifiable to an outside observer? And is "done" provable by running `validate.sh`?* If any answer is no, reconsider.

---

## Conventions

### Strict-mode policy (bash `set -e`)

Strict mode is **per-subsystem, not repo-wide** (GH-110 P3b). The split is deliberate:

- **`relay-automation/` drivers and turn shims run `set -euo pipefail`.** They orchestrate risky,
  multi-step, containment-sensitive turns where a silently-ignored failure can commit off-lane or
  orphan a peer. Abort-on-error (`-e`) is the correct default there.
- **`utils/` analysis tools (`pdda/*`, `marathon-plan.sh`, `swarm-preflight.sh`) run `set -uo pipefail`
  or `set -u`, deliberately *without* `-e`.** These are long single-pass scripts whose normal control
  flow includes many expected-nonzero probes (`git rev-parse`, `gh` lookups, `grep` misses). Under
  `-e` a benign "no match" would abort the whole run, so they set `-u` (catch unset vars) + explicit
  per-call error handling instead. This is an exemption, not an oversight.

Every currently `-e`-exempt script carries a one-line `# strict-mode: -e exempt — …` header next to
its `set -` line so the exemption is self-documenting. New scripts default to `set -euo pipefail`
unless they fit the analysis-tool profile above, in which case they add the exemption header.

### Tool install paths — never inside another app's folder (GH-347)

**This harness's tool binaries never live inside another application's private directory.** Not the
worker CLIs (`codex`, `agy`, `pi`, `aider`), not `tick`, not anything the harness shells out to.

The failure mode is specific and quiet: a foreign app owns its own directory, so its next update or
reinstall deletes our dependency with it — on that app's schedule, with no signal we control. Worse, the
readiness check cannot tell the two apart. `find-harness.sh --check` tests only whether a worker is *on
PATH*, so "the neighbouring app just wiped our tool" and "never installed" produce the byte-identical
line. That is the same disease as GH-315/GH-319: a broken observation layer where failure is invisible
and every available signal agrees.

**The `npm install -g` trap — this is how GH-347 actually happened.** npm derives its global prefix from
whichever `npm` is on PATH, so a bare `npm install -g <pkg>` inherits a foreign app's runtime silently
and exits 0. On the machine that filed GH-347, another agent app had symlinked its bundled Node onto PATH
(`~/.local/bin/npm -> ~/.hermes/node/bin/npm`) with no `~/.npmrc` involved at all, so `pi` installed into
that app's folder and — because only `node`/`npm` were symlinked out, not `pi` — was invisible to every
shell while being perfectly functional. **Run `npm config get prefix` before any global install and
confirm it is a path this repo's tooling owns.** Never assume.

The positive pattern is already on disk in the two lanes that have never had this problem: a tool's own
app directory with a symlink onto PATH (`~/.local/bin/codex -> ~/.codex/packages/…/bin/codex`), or a real
binary in a shared user-local `bin`. Either is fine. Someone else's runtime is not.

**Scope note:** where a *working* binary lives stays the operator's call. This is a convention and a
warning, deliberately **not** a gate — a false positive that blocks a relay is worse than the papercut it
prevents.

### Marathon builder default & plan location (GH-212)

Two vendored-harness defaults, made explicit so an agent given only the vendored bundle picks the
right behavior without pattern-matching a downstream repo's prior drift:

- **Builder default is `codex`, not a billed CLI.** `marathon.sh`/`marathon-drive.sh` (and the
  `XYZ_PYTHON=1` port) default `--builder` to `codex` — build turns bill via the Codex/ChatGPT
  subscription, not the Anthropic API (agy is the other cost-blind option). `--builder claude`
  spawns a headless Claude Code CLI subprocess instead: a separate, per-call API-billed turn-taker.
  Use it only as an explicit, cost-acknowledged choice — never assume it's free because an
  interactive session is already running. `swarm-preflight.sh`'s suggested invocation and
  `marathon.sh`'s own default now agree; don't let them drift apart again.
- **A marathon's plan lives under `PROJECT/2-WORKING/`.** The `MARATHON.yaml` + its phase briefs
  belong under `PROJECT/2-WORKING/<capture-doc>/` — never a standalone top-level folder (e.g.
  `marathon-plans/<slug>/`). `marathon.sh --plan` enforces this: it refuses (exit 2) a plan that
  resolves outside `PROJECT/2-WORKING/`, exempting only paths under the harness's own home
  (`MARATHON_HOME` — shipped reference examples like `MARATHON.example.yaml`) or an explicit
  `MARATHON_ALLOW_PLAN_OUTSIDE_WORKING=1` override for a genuinely non-default location.

---

## Appendix: AI Doc Review Heuristics

When reviewing any repo doc (roadmap entries, plans, architecture notes, audits, task writeups), apply these. Priority: containment > coordination correctness > signal quality > implementation speed and operator friction.

**Heuristics**

1. **Containment preserved?** Any headless path that could self-commit, touch off-allowlist files, or orphan a peer commit without an explicit containment argument → reject or escalate.
2. **Skill-first respected?** Any plan that bypasses `relay-xyz` or improvises the harness from scratch without the skill layer → reject. Add to the skill instead.
3. **Coordination through the event log?** Reads/writes to shared state route through `tick` verbs; hard-coded state outside `.tick/` needs explicit justification.
4. **Done verifiable?** Names runnable gates (`validate.sh`, specific tests, `utils/pdda/pdda.sh run`). None = low-quality signal.
5. **Drift reduced, not created?** No duplicated docs, no execution detail in ROADMAP.md, no reinventing a path the event-log contract already documents.
6. **Next action singular?** One explicit next step, not buried in prose; status cells non-empty.
7. **Operator control explicit?** No silent retry, no auto-repair outside the bounded exit-code menu, no masked failure; destructive ops surface before executing.
8. **Four pillars pass?** Each turn/output is Attested, Relevant, Fresh, Structured. Fail one → not done.

**Tie-breakers**

- **Containment vs speed:** choose containment; flag friction as a design question, not a shortcut.
- **New relay path vs reuse:** extend the existing skill and harness over forking a parallel path; if the harness can't accommodate it, surface the gap.
- **Ambitious vs resumable:** a shorter plan an agent can resume cold beats a comprehensive one that buries state in prose.

**Reject or escalate when**

- A headless path has no allowlist, no worktree isolation, and no commit-bypass guard — and the doc doesn't justify why.
- "Done" has no runnable verification step.
- Adding a new relay lane requires editing the event-log kernel or the `tick` verb schema without a decision record under `decisions/`.
- Hardcoded absolute paths, silent destructive operations, or opaque epoch-fence assumptions.
- ROADMAP.md would need execution detail to make the plan legible.
relay-system/2026-09-06/needle-oracle-140920/needle-oracle.PROMPT.txt:1:# Consult Question: Needle Oracle Tool Extraction Simplification
relay-system/2026-09-06/needle-oracle-140920/needle-oracle.PROMPT.txt:3:Context: We are building a "what to do next" Oracle using the 45M Needle model to run on the M1 Max ANE (Orion runtime) for RebalanceOS. The goal is to train it on historical XYZ-CLIO markdown logs.
relay-system/2026-09-06/needle-oracle-140920/needle-oracle.PROMPT.txt:5:The original issue (#467) proposed extracting full JSON tool calls (name + arguments) to form the training dataset.
relay-system/2026-09-06/needle-oracle-140920/needle-oracle.PROMPT.txt:8:Instead of building a robust parser to extract and validate full JSON tool schemas and arguments, we just use a simple regex to extract the **tool name only** (e.g., `run_tests`, `create_pr`, `read_file`) from the markdown. We then train Needle to predict ONLY the tool name string.
relay-system/2026-09-06/needle-oracle-140920/needle-oracle.PROMPT.txt:11:Does stripping the tool arguments from the training data fundamentally break the usefulness of this Oracle for its intended role in RebalanceOS, or is predicting just the tool name sufficient for a "real-time recommendations" sentinel? What are the concrete risks of skipping JSON argument extraction?
PROJECT/3-COMPLETED/GH-183-EXPLORER-ENV-SOUNDNESS.md:40:   env (inherit `differential_oracle.py`'s discipline: PATH/HOME/TMPDIR/XYZ_ROOT only) + declared
PROJECT/3-COMPLETED/GH-184-TRACKED-SCRATCH-ARTIFACT.md:32:invisible to the Phase 1 zero-mutation oracle (`--help` scope) and the Phase 5 anomaly oracle
PROJECT/3-COMPLETED/GH-184-TRACKED-SCRATCH-ARTIFACT.md:47:3. The durable hardening (per-probe zero-mutation oracle so fuzzer-driven real turns can never
PROJECT/3-COMPLETED/GH-15-PARALLEL-FRESH-CLONE-RELIABILITY.md:32:(gh492, gh388, oracle-guard, improve-loop-qa, releases-skill, gh430, improve-loop-dogfood,
PROJECT/PDDA.md:816:  is clamped to `warn` in `pdda-doc-ready.sh`), so a non-deterministic oracle can never fail a build —
PROJECT/3-COMPLETED/GH-155-3RD-GEN-ATE-METAMORPHIC-INVARIANTS.md:4:title: "3rd Gen ATE & Fuzzing: Metamorphic Invariants, Differential Oracles, Hermetic Reproducers, Self-Healing & Active Explorers"
PROJECT/3-COMPLETED/GH-155-3RD-GEN-ATE-METAMORPHIC-INVARIANTS.md:26:  invariant assertion oracles (Phase 1), differential multi-harness cross-testing oracles (Phase 2),
PROJECT/3-COMPLETED/GH-155-3RD-GEN-ATE-METAMORPHIC-INVARIANTS.md:36:| **All 5 Phases Built & Landed (2026-08-22)**: (1) `utils/py/metamorphic_oracle.py` & `test/gh155-phase1-metamorphic-invariants.sh` (8/8 pass). (2) `utils/py/differential_oracle.py` & `test/gh155-phase2-differential-oracle.sh` (5/5 pass). (3) `utils/py/repro_builder.py` & `test/gh155-phase3-repro-builder.sh` (7/7 pass). (4) `utils/py/self_healer.py` & `test/gh155-phase4-self-healer.sh` (5/5 pass). (5) `utils/py/active_explorer.py` & `test/gh155-phase5-active-explorer.sh` (4/4 pass) providing end-to-end integration from discovery to patch synthesis. Pre-push test gate 100% green. | **Production Deployment & Campaign Execution**: Continuous 3rd Gen ATE runs with local Gemma-4 31B triage and DeepSeek Harness (`dsh`) autonomous healing. |
PROJECT/3-COMPLETED/GH-155-3RD-GEN-ATE-METAMORPHIC-INVARIANTS.md:40:1. **Deterministic Ground First ($0 LLM Overhead):** Consolidate scattered guards into reusable, deterministic per-entry-point assertion oracles before connecting paid or local LLM mutation loops.
PROJECT/3-COMPLETED/GH-155-3RD-GEN-ATE-METAMORPHIC-INVARIANTS.md:41:2. **Full-Clone Isolation (GH-564):** All fuzzing, healing, and oracle runs execute in separate standalone full clones, never in linked worktrees sharing `.git/config`.
PROJECT/3-COMPLETED/GH-155-3RD-GEN-ATE-METAMORPHIC-INVARIANTS.md:43:4. **No-New-Bash Rail (GH-551):** All oracle and self-healing logic is implemented in authoritative Python in `utils/py/`.
PROJECT/3-COMPLETED/GH-155-3RD-GEN-ATE-METAMORPHIC-INVARIANTS.md:49:- **Phase 2 (Completed)**: Differential Multi-Harness Cross-Testing Oracle (`agy`, `codex`, `claude`, `aider`, `pi`, `commandcode`, `deepseek`).
PROJECT/3-COMPLETED/GH-155-3RD-GEN-ATE-METAMORPHIC-INVARIANTS.md:56:1. **Deterministic Oracles Ground Everything ($0 Cost):** Building deterministic metamorphic invariant oracles and differential multi-runner oracles upfront creates an un-gameable acceptance floor before invoking LLMs.
PROJECT/2-WORKING/GH-201-GEN35-FOLLOWUPS.md:26:| spun out of #174 2026-08-24 (collision-free tracker); tasks 1+9 already shipped via PR #185 | Task 3 (deterministic fixes) → Task 4 (data path) → Task 6 (explorer+oracle) gate Task 7 (Phase 4 autonomy); Task 8 calibration hour; Task 8b Gemma sensor rides alongside |
PROJECT/2-WORKING/GH-299-GEN4-FUZZING-ATE.md:2:title: "GH-299: Gen 4 ATE & True Evolutionary Fuzzing — High-ROI Phasing: Semantic Invariant Oracles, Constraint-Aware Pairwise ATE, and Feedback-Guided Fuzzing"
PROJECT/2-WORKING/GH-299-GEN4-FUZZING-ATE.md:42:| 1 | `bash test/gh-gen4-phase1-domain-oracles.sh` green; each oracle has a positive and a negative control | 17/17 on 2026-09-04 |
PROJECT/2-WORKING/GH-299-GEN4-FUZZING-ATE.md:44:| 3 | `bash test/gh-gen4-phase3-fuzz-engine.sh`: seed replay deterministic, corpus grows, novelty eviction holds the 500 cap | 20/20 on 2026-09-04 — byte-identical plan replay, 150 mutants/0 misclassified, cap held at 6 under eviction pressure, parity oracle +/- controls, real twin run contained |
PROJECT/2-WORKING/GH-299-GEN4-FUZZING-ATE.md:50:**Gen 3 (`GH-155`) and Gen 3.5 (`GH-201`) established deterministic test oracles and sandbox safety, but execution remained bounded variation testing and static script enumeration rather than true generative fuzzing.**
PROJECT/2-WORKING/GH-299-GEN4-FUZZING-ATE.md:54:2. **Immediate Risk Mitigation (Phase 1 — Highest ROI)**: Consolidates the **4 Core Semantic Domain Oracles** (Zero-State tree hashing, Host Containment `GH-564`/`GH-567`, Idempotence, and Crash/Stale-Lock Recovery) to permanently protect developer machines and CI from catastrophic state corruption ($0 LLM overhead).
PROJECT/2-WORKING/GH-299-GEN4-FUZZING-ATE.md:56:4. **True Generative Fuzzing & Differential Parity (Phase 3)**: Deploys a **seeded, multi-strategy mutational fuzzer** using an `(exit_code, signal, stderr_digest, duration_bucket)` feedback loop, a **novelty-weighted 500-cap corpus**, and the Differential Cross-Twin Parity Oracle.
PROJECT/2-WORKING/GH-299-GEN4-FUZZING-ATE.md:73:    "Phase 1: 4 Core Semantic Oracles": [0.22, 0.94]
PROJECT/2-WORKING/GH-299-GEN4-FUZZING-ATE.md:97:To ensure seamless interoperability across Oracles, Pairwise ATE, Mutator, and Repro Builder without downstream retrofits:
PROJECT/2-WORKING/GH-299-GEN4-FUZZING-ATE.md:106:    phase: str = "oracle"            # "oracle" | "pairwise" | "fuzz" | "repro"
PROJECT/2-WORKING/GH-299-GEN4-FUZZING-ATE.md:113:    oracle_results: Dict[str, bool] = field(default_factory=dict)  # oracle_name -> pass/fail
PROJECT/2-WORKING/GH-299-GEN4-FUZZING-ATE.md:128:### Pillar 2: Semantic Domain Invariant Oracles (`utils/py/domain_oracles.py`)
PROJECT/2-WORKING/GH-299-GEN4-FUZZING-ATE.md:129:- **Zero-State Mutation Oracle**: Full SHA-256 tree digest check (excluding `__pycache__`/`.DS_Store`) + `lsof` verification of zero leaked file descriptors or `.tick/lock` handles.
PROJECT/2-WORKING/GH-299-GEN4-FUZZING-ATE.md:130:- **Idempotence & Monotonicity Oracle**: Identical state and zero duplicate receipts on repeated execution.
PROJECT/2-WORKING/GH-299-GEN4-FUZZING-ATE.md:131:- **Host Containment Oracle (GH-564 / GH-567)**: Proves `.git/config`, `core.bare`, and remotes are never modified; all operations stay within physical `$WORK`.
PROJECT/2-WORKING/GH-299-GEN4-FUZZING-ATE.md:132:- **Crash & Stale-Lock Recovery Oracle**: Proves subsequent `tick acquire` succeeds after `SIGKILL` and verifies line-level JSONL validity.
PROJECT/2-WORKING/GH-299-GEN4-FUZZING-ATE.md:133:- *(Note: Differential Cross-Twin Parity Oracle is deployed in Phase 3 alongside mutational discovery).*
PROJECT/2-WORKING/GH-299-GEN4-FUZZING-ATE.md:157:1. Phase 1 (Immediate High ROI): 4 Core Semantic Domain Oracles (`utils/py/domain_oracles.py`)
PROJECT/2-WORKING/GH-299-GEN4-FUZZING-ATE.md:160:   -> Verification: test/gh-gen4-phase1-domain-oracles.sh (4 positive controls + 4 negative falsification controls)
PROJECT/2-WORKING/GH-299-GEN4-FUZZING-ATE.md:169:   -> Deploy Differential Cross-Twin Parity Oracle (Python authoritative vs Bash twin)
PROJECT/2-WORKING/GH-299-GEN4-FUZZING-ATE.md:234:# 3. Smoke Test: Zero-State & Containment Oracle against Host (Pillar 2)
PROJECT/2-WORKING/GH-299-GEN4-FUZZING-ATE.md:238:pass "Pillar 2: Zero-state mutation oracle verified 100% byte-identical host state"
PROJECT/2-WORKING/MARATHON-PLAN-2026-09-03.md:138:- #299 GH-299 · feat(ate): Gen 4 ATE & True Evolutionary Fuzzing — Feedback-guided mutational engine, semantic domain oracles, and adaptive pairwise matrix — `needs-contract`
PROJECT/2-WORKING/MARATHON-PLAN-2026-09-04.md:141:- #299 GH-299 · feat(ate): Gen 4 ATE & True Evolutionary Fuzzing — Feedback-guided mutational engine, semantic domain oracles, and adaptive pairwise matrix — `needs-contract`
PROJECT/2-WORKING/GH-259-JOG-SERIAL-QUEUE.md:202:- The `whatsnext-xyz` catchall router (Phase 2 — will query jog state as an oracle).
PROJECT/2-WORKING/GH-396-HARNESS-ROOT-RESOLVER.md:140:- [x] The other ~10 live scripts with inline vendored predicates (`relay-automation/{finding-new,oracle-guard,smallcode-turn,target-checks,marathon,marathon-agent,improve-loop}.sh`, `utils/marathon-plan.sh`, `utils/swarm-preflight.sh`, `utils/roadmap-dashboard.sh`) get a **one-line comment** pointing at the library. Nothing else. Their predicates are simple and stable; the Python lane is authoritative.
PROJECT/2-WORKING/GH-396-HARNESS-ROOT-RESOLVER.md:210:and the oracle's own existing→1 / missing→0 check.
PROJECT/2-WORKING/GH-396-HARNESS-ROOT-RESOLVER.md:230:5. **The #395 oracle is "override agrees with auto-discovery on the same fixture," not a hardcoded
PROJECT/2-WORKING/GH-396-HARNESS-ROOT-RESOLVER.md:262:- [x] `test/gh396-find-harness-roots.sh` — five #395 topologies with the agree-with-auto oracle; #394 warn-under-override + remedy-runnable; `--quiet` accepted / silences only the announcement / exports identical.
PROJECT/2-WORKING/GH-396-HARNESS-ROOT-RESOLVER.md:263:- [x] `test/gh393-deepseek-readiness.sh` — parity pin with ast-extracted oracle, two negative controls, oracle self-check.
PROJECT/2-WORKING/GH-396-HARNESS-ROOT-RESOLVER.md:272:- `RELAY_HAS_DEEPSEEK` needs a shared binary rule. The cheapest honest form: `deepseek-turn.py --print-bin` (prints `default_deepseek_bin()` and exits 0/1 on existence), called from `find-harness.sh:204-206`. Then the suite's ast oracle and the runtime cannot drift.
PROJECT/2-WORKING/GH-141-FUZZ-ATE-UTILITY.md:35:| **BUILT 2026-08-22 on branch `gh141-fuzz-ate-utility`** — all in-scope phases landed: **#142** exit contract (0/3/1 + propagation; SKILL.md documents it, incl. the launch-failure/hang hardening from the a2a #818589 review) with `gh142-ate-exit-contract.sh` **30/0** (which also carries Phase 4's three outcomes + dedup, replacing the original live-run phase); **Phase 1** single selector (`validate.sh --list`, 14/14 synthetic suites registry-reachable, fuzz-loop consumes the registry) with `gh141-synthetic-registry.sh` **6/0**; **Phase 2** de-aliased telemetry (nested `classification.status` removed; severity grades exit classes; cause classifies output; both consumer shapes coexist) pinned by the extended `gh102` suite over a five-outcome corpus; **Phase 5** Aider decoupling (neutral labels end-to-end with preset opt-back-in, `expects_edits` oracle key — the #146 fix, `variations.turn-shims.yaml`, SKILL.md generalized). | Full gate re-run on the EXACT final commit SHA (a gate cited to any other SHA is not evidence — a2a #818589 turn 3 caught the first PR citing the pre-amend SHA) → push → merge is the operator's call; #141's remaining scope moves with #143's comparison. |
PROJECT/2-WORKING/GH-141-FUZZ-ATE-UTILITY.md:52:   oracle (17 false HIGH `no_edit` failures on non-Aider probes) — so this branch implements the
PROJECT/2-WORKING/GH-141-FUZZ-ATE-UTILITY.md:151:no GitHub issues as a test oracle; no ATE deletion; no schema expansion (Phase 2 only removes);
PROJECT/1-INBOX/GH-445-TURN-SHIM-HELP-PARITY.md:25:During the GH-299 Gen 4 ATE 3-hour soak (14,825 mutations), the differential cross-twin parity oracle
PROJECT/1-INBOX/GH-446-MARATHON-PLAN-WRITE-GUARD.md:31:Zero-State Oracle), and causes `wave_reconcile` runs to leave an untracked plan file in clean clones.
PROJECT/1-INBOX/GH-460-ATE-FUZZ-RESOLVER-CAMPAIGN.md:20:demonstrated (seed 7, 30 iterations, structural-contract oracle, 30/30 clean). Issue #460 owns
PROJECT/1-INBOX/GH-460-ATE-FUZZ-RESOLVER-CAMPAIGN.md:23:the oracle narrowed.** Accept requires zero untriaged counterexamples.
PROJECT/1-INBOX/GH-460-ATE-FUZZ-RESOLVER-CAMPAIGN.md:41:posted + oracle narrowed. Null campaigns are valid and reported as nulls; the committed smoke

exec
/bin/zsh -lc "rg -n -i 'needle|rebalanceos|XYZ.CLIO|orion' ROADMAP-DASHBOARD.md PROJECT/1-INBOX releases.sql | head -55; nl -ba GUIDING-PRINCIPLES.md | head -65; rg --files | rg -i 'clio|467|needle'" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-86231-968w76hh
 succeeded in 0ms:
PROJECT/1-INBOX/GH-419-MARATHON-RULE-ENFORCEMENT.md:72:target is a real product repo (`rebalanceOS-gh144`) that will never be named `marathon-gh-…`, so
PROJECT/1-INBOX/GH-419-MARATHON-RULE-ENFORCEMENT.md:178:`-longtail`, `rebalanceOS-gh144` (number at the **end**), and — the exemplar —
PROJECT/1-INBOX/GH-454-RECONCILE-GATE-DEFECTS.md:14:reported_from: rebalanceOS
PROJECT/1-INBOX/GH-454-RECONCILE-GATE-DEFECTS.md:44:- **Observed from:** `rebalanceOS` (vendored `.xyz/`, `tier=2`, vendored 2026-09-02T21:20:08Z)
PROJECT/1-INBOX/GH-454-RECONCILE-GATE-DEFECTS.md:61:   (rebalanceOS has 23), confirm `bash utils/pdda/pdda.sh run` exits **0**.
releases.sql:463:INSERT INTO roadmap_items(global_id, repo_gid, gh_number, title, section, position, status_marker, complexity, risk, effort, doc_path, issue_url, raw_text, first_seen, updated_at, rating_pri, rating_sev, rating_appeal, rating_effort, rating_ovr) VALUES('rmi-01M0ZA4000FSYV0MJ8AEYX6NT0', 'repo-01M0BTBRJ0PZF51EK6PCRJ20FS', '255', 'marathon-drive blocked-before-dispatch refusal omits XYZ_ARCHIVE_ROOT', 'Queue / parked intake', '16', '🆕', NULL, NULL, NULL, 'PROJECT/1-INBOX/GH-255-ARCHIVE-ROOT-REMEDY.md', 'https://github.com/HiQS-Labs/XYZ-forge/issues/255', '- **GH-255 — marathon-drive blocked-before-dispatch refusal omits XYZ_ARCHIVE_ROOT** (2026-08-26) - the refusal named --target-root and un-ignore but never XYZ_ARCHIVE_ROOT, the knob GH-30 built for exactly the repo it fires on; cost three dead-end launch attempts on a consuming repo. Reported from rebalanceOS. Issue [#255](https://github.com/HiQS-Labs/XYZ-forge/issues/255). -> [PROJECT/1-INBOX/GH-255-ARCHIVE-ROOT-REMEDY.md](PROJECT/1-INBOX/GH-255-ARCHIVE-ROOT-REMEDY.md) rated 1/1/1/1', '2026-08-26T15:13:19Z', '2026-08-26T15:13:19Z', '1', '1', '1', '1', NULL);
releases.sql:464:INSERT INTO roadmap_items(global_id, repo_gid, gh_number, title, section, position, status_marker, complexity, risk, effort, doc_path, issue_url, raw_text, first_seen, updated_at, rating_pri, rating_sev, rating_appeal, rating_effort, rating_ovr) VALUES('rmi-01M0ZA408NRF4EAD9SP0VX6C2F', 'repo-01M0BTBRJ0PZF51EK6PCRJ20FS', '256', 'No preflight checks the builder can reach a phase artifact paths', 'Queue / parked intake', '17', '🆕', NULL, NULL, NULL, 'PROJECT/1-INBOX/GH-256-ARTIFACT-REACHABILITY-PREFLIGHT.md', 'https://github.com/HiQS-Labs/XYZ-forge/issues/256', '- **GH-256 — no preflight checks the builder can reach a phase''s artifact paths** (2026-08-26) - under --target-root the shim guarded the harness while the worktree was the target, so four builder turns wrote nothing and the phase burned its round cap in silence. Reported from rebalanceOS. Issue [#256](https://github.com/HiQS-Labs/XYZ-forge/issues/256). -> [PROJECT/1-INBOX/GH-256-ARTIFACT-REACHABILITY-PREFLIGHT.md](PROJECT/1-INBOX/GH-256-ARTIFACT-REACHABILITY-PREFLIGHT.md) rated 3/2/2/1', '2026-08-26T15:13:19Z', '2026-08-26T15:13:19Z', '3', '2', '2', '1', NULL);
releases.sql:513:INSERT INTO roadmap_items(global_id, repo_gid, gh_number, title, section, position, status_marker, complexity, risk, effort, doc_path, issue_url, raw_text, first_seen, updated_at, rating_pri, rating_sev, rating_appeal, rating_effort, rating_ovr) VALUES('rmi-01M1T8H5J5P8TZ9Y5M194E91JN', 'repo-01M0BTBRJ0PZF51EK6PCRJ20FS', '454', 'wave_reconcile dies on an unnamed release, and enforces PDDA full-mode on an observe-mode repo', 'Queue / parked intake', '54', '🆕', NULL, NULL, NULL, 'PROJECT/1-INBOX/GH-454-RECONCILE-GATE-DEFECTS.md', 'https://github.com/HiQS-Labs/XYZ-forge/issues/454', '- **GH-454 · wave_reconcile dies on an unnamed release, and enforces PDDA full-mode on an observe-mode repo** 🆕 **captured 2026-09-05 via /file-xyz-bug from `rebalanceOS`** — two defects, one run, each rolling the whole wave back: `export_timeline.py:278` does `(codename or version).lower()` and raises on a release row with both NULL; `run_validation_gate()` fails on any stdout line containing `ERROR`, ignoring `pdda.sh`''s mode-aware exit code and so enforcing `full` on a repo that declares `observe`. Both have workarounds the caller must already know. With GH-215''s surviving half, this is what blocks GH-421 unattended operation. rated 72/78/80/78 — [GH-454-RECONCILE-GATE-DEFECTS.md](PROJECT/1-INBOX/GH-454-RECONCILE-GATE-DEFECTS.md)', '2026-09-06T02:25:03Z', '2026-09-06T02:25:03Z', '72', '78', '80', '78', NULL);
PROJECT/1-INBOX/GH-256-ARTIFACT-REACHABILITY-PREFLIGHT.md:14:reported_from: rebalanceOS
PROJECT/1-INBOX/GH-255-ARCHIVE-ROOT-REMEDY.md:14:reported_from: rebalanceOS
PROJECT/1-INBOX/recon-harness-root-resolution.md:132:Every shell that `eval`s `find-harness.sh --env` (operators, all relay/consult/hq/file-xyz-bug/marathon-triage/10days skill sessions, 8 script callers), the 5 Python turn shims via `rtl.resolve_turn_root`, `wave_reconcile`/`jog_run`/`marathon_plan`/`swarm_preflight`/`marathon_drive` via four ad-hoc `harness_home` derivations, `bin/tick`'s event-log location, and the three consumer repos (`rebalanceOS` ×5, `LTVera-Pandas` ×4, `aegis-sleuth-slack-bot` ×3) that run all of the above from a `.xyz/` copy stamped by `xyz-vendor.sh` and audited by two disagreeing staleness checks.
PROJECT/1-INBOX/RADAR-REPORT-2026-09-01.md:190:| **S5 `reported_from:`** | **available** | **10 capture docs** (was 7), **4 distinct external consumer repos**: `LTVera-Pandas` ×4 (#215, #216, #222, +1), `aegis-sleuth-slack-bot` ×3 (#221, #254, +1), `rebalanceOS` ×2 (#255, #256), `ltvera` ×1. **Grew by 3 docs and 1 repo in 4 days.** |
PROJECT/1-INBOX/RADAR-REPORT-2026-09-02.md:117:| **S5 `reported_from:`** | available | **14 capture docs** (run 1: 7, run 2: 10). `rebalanceOS` **5** (was 2), `LTVera-Pandas` 4, `aegis-sleuth-slack-bot` 3, `ltvera` 2. **Grew by 4 docs in one day.** |
PROJECT/1-INBOX/RADAR-REPORT-2026-09-02.md:162:three runs, and `rebalanceOS` alone went from 2 to 5.
PROJECT/1-INBOX/RADAR-REPORT-2026-08-28.md:133:| **S5 `reported_from:`** | **available** | 7 capture docs, **3 distinct external consumer repos**: `LTVera-Pandas` (#215, #216, #222), `rebalanceOS` (#255, #256), `aegis-sleuth-slack-bot` (#221, #254). All in `PROJECT/1-INBOX/`; 6 still open. |
PROJECT/1-INBOX/RADAR-REPORT-2026-08-28.md:172:Members: **#215, #216, #222** (`LTVera-Pandas`), **#255, #256** (`rebalanceOS`), **#221, #254** (`aegis-sleuth-slack-bot`). Docs: `PROJECT/1-INBOX/GH-{215,216,222,255,256,221,254}-*.md`.
PROJECT/1-INBOX/GH-32-RELEASES-APP-SQLITE.md:32:| Ad-hoc field invention (`Deadline:` vs `Target Date:`, `Exit:` vs `Exit criterion:`, `Issues:` vs `Manifest:`, `Issues frozen:`, `Deploys:`, `Not in scope:`) | aegis, rebalanceOS | The "minimal fields" contract forks per repo with no mechanism to converge |
PROJECT/1-INBOX/GH-32-RELEASES-APP-SQLITE.md:36:| Bare `#nnn` refs resolving to nothing (rebalanceOS's own header admits its issue numbers point at a retired tracker) | rebalanceOS | Manifests need full URLs, not repo-relative issue numbers |
PROJECT/1-INBOX/GH-32-RELEASES-APP-SQLITE.md:372:  rebalanceOS case, where the numbers point at a retired tracker, is precisely why they cannot be
     1	# Guiding Principles
     2	
     3	North star for **xyz-3-agents-swarm**, the multi-agent coordination harness behind the `tick` event-log kernel and `relay-automation/` relay stack. When a choice is unclear, the option that keeps agents synchronized, contained, and verifiable — without leaking or destroying work — wins. AGENTS.md is the behavioral playbook; ROUTER.md is the entry-point map; this is the *why*.
     4	
     5	## The North Star
     6	
     7	There is no perfect architecture and no finished codebase. The bar is not perfection — it is that
     8	every change leaves the harness **more durable, more reversible, and less duplicated** than it found
     9	it, and that the three stay in balance:
    10	
    11	- **Durable** — it removes the root cause and the next planned change builds on it, rather than being
    12	  torn out when the obvious next feature lands.
    13	- **Reversible** — the cost of being wrong is known and bounded before the change lands. A change
    14	  nobody can undo is a bet, not a fix, and gets treated as one.
    15	- **DRY** — nothing canonical lives in two places where it can drift. One source of truth, and every
    16	  other surface is a pointer or a projection of it.
    17	
    18	**Do not build a new layer, module, or sub-system when an existing piece of code can be extended
    19	easily, logically, and safely.** Extending an existing abstraction beats standing up a parallel,
    20	siloed system, even when the parallel path is faster to write today — the parallel path is what
    21	later has to be kept in sync, and what silently drifts when it isn't. If the existing abstraction
    22	genuinely cannot carry the new case, say so in one line, with the reason, before forking.
    23	
    24	These three pull against each other, and that tension is the decision, not a problem to average
    25	away: the most durable fix is often the least reversible, and collapsing two near-duplicates is a
    26	DRY win that can widen the blast radius. Name the trade and pick; do not split the difference by
    27	building both.
    28	
    29	This section is canonical. `AGENTS.md` owns how it is applied to a given change — the reversibility
    30	scale (§3) and blast-radius sizing (§4) — and principles 6, 7, and 10 below are the build-time and
    31	done-time expressions of it. Where another doc restates this, that doc is the copy and this is the
    32	original.
    33	
    34	## Purpose
    35	
    36	`tick` coordinates Claude Code, Codex, and agy (Antigravity CLI) on the same branch without collision: a shared local event log under `.tick/events/`, claims serialized by `O_EXCL` locks, and a `Marathon` harness that chains multi-phase build→review cycles from a `MARATHON.yaml`. The relay layer (`relay-automation/`) drives headless turns, isolates agent writes to worktrees, and enforces an allowlist so no headless agent destroys work it didn't intend to touch. The goal: a multi-agent swarm safe enough to run against a real external codebase and correct enough that its output is worth shipping.
    37	
    38	## The quality bar
    39	
    40	Every agent turn is a signal. A turn is high-quality only when it is all four:
    41	
    42	- **Attested** — carries its receipts: source, evidence, confidence. Never a bare verdict. A relay review names which claim is wrong and why; a build turn names the seam it touched.
    43	- **Relevant** — ranked, not dumped. Volume is not value. One real bug beats five nits and a phantom.
    44	- **Fresh** — current, not stale. A turn that reads a stale `STATE.md` or misses an epoch fence is wrong by construction.
    45	- **Structured** — one shape, clean for the operator to read and for downstream agents to feed on.
    46	
    47	Fail a pillar, and the turn, feature, or relay review isn't done.
    48	
    49	## How it's built
    50	
    51	1. **Coordination is local-transport only.** `.tick/events/` is the shared bus; claims resolve from there, not from a remote. No per-event push/fetch; no remote dependency at runtime. A coordination primitive that reaches out is a coordination primitive that can fail or leak.
    52	
    53	2. **One canonical event log; every surface is a projection.** `tick` accretes events; `STATE.md` is the current projection. Reads go through the projection; writes go through a `claim/take/scope/done` verb. Nothing canonical lives in two places where it can drift. An agent that hard-codes state outside `.tick/` is creating drift.
    54	
    55	3. **Containment is non-negotiable.** A headless turn must not: self-commit mid-turn, orphan a peer's concurrent commit, or write outside its allowlist. The allowlist, worktree isolation, and commit-bypass guard exist because a driven agent will do all three if unconstrained — not hypothetically, but as documented live incidents (GH-13, GH-14, GH-17). New relay paths must clear the containment bar before they ship.
    56	
    57	4. **Skill-first; never improvise the harness.** The `relay-xyz` skill owns the locator, sandbox rules, exit codes, and the safety boundary. A session that improvises those from `ls relay-automation/` silently skips the skill's safety layer. The `PreToolUse` guard (`relay-automation/hooks/relay-xyz-guard.sh`) enforces this by blocking driver calls before the skill loads. Add capabilities to the skill; do not work around it.
    58	
    59	5. **Adversarially proven before commercially viable.** The harness exists to run against real codebases. Features in the adversarial-hardening track (epoch fencing, chaos suite, cross-repo E2E) must be verified to survive deliberate abuse — stale writers, zombie claims, macOS case-sensitivity, concurrent peer commits — not just the happy path. A feature that clears the happy path and skips chaos is half-done.
    60	
    61	6. **Build durable, not band-aid.** Durable means it removes the root cause and the next planned change builds on it — not a patch torn out when the obvious next feature lands. A band-aid is wasted work unless a demo strictly needs one, and a demo band-aid is tagged for removal so it isn't silently inherited.
    62	
    63	7. **Least code that clears the bar.** Node standard library only — no deps, no lockfile; the repo ships no root manifest. Prefer reusing or extending what exists; the smallest change that stays correct, contained, and durable wins. Net-new code is a cost to justify. Deleting code counts as progress.
    64	
    65	8. **Honest; the operator decides.** Surface what failed and why — never mask a stall as success or an escalation as a stall. A headless turn self-repairs within a bounded exit-code menu (`exit 3` stall, `exit 4` escalated-by-design, `exit 6` containment revert), then stops; it never loops forever or silently swallows an error. Destructive actions require explicit authorization.
marathon-system/nightwatch-wave-3-2026-08-11--gh467-index-only-lane/RELAY.md
test/gh467-index-only-lane-blocked.sh
relay-system/2026-09-06/needle-oracle-140920/needle-oracle.PROMPT.txt
evidence/marathons/run-1/artefacts/events/2026-08-20T13-24-22.467Z-codex-claimed-MARATHON-R1P2-TURN.jsonl

codex
**ANSWER:** Predicting only the tool name can be useful for a coarse recommendation sentinel. It does **not** establish which concrete task to do next. I would approve name-only **prediction targets**, while preserving the original records and relevant context. Stripping arguments from the entire dataset is a different, more damaging simplification.

The key assumption is that RebalanceOS or a human already knows the relevant project and target, and only needs a suggestion such as “run tests.” If the Oracle must choose *which* tests, file, issue, or project deserves attention, tool names alone cannot express its answer.

**FINDINGS**

- **[Pass] Full argument generation is unnecessary for an advisory classifier.** A context → action-category model can provide useful suggestions without emitting executable JSON. That is consistent with “least code that clears the bar,” which explicitly retains correctness as a requirement (`GUIDING-PRINCIPLES.md:63`). Neither full schema validation nor arbitrary argument generation must be part of this first experiment.

- **[Blocker] Actual tool names may identify transport, not intent.** Your examples—`run_tests`, `create_pr`, `read_file`—are meaningful action categories. Actual logs might instead record all three as `Bash` or `exec_command`, with the distinction entirely inside the command argument. A name-only extractor would collapse different decisions into one label. Inspect representative logs before accepting this simplification; if this pattern dominates, extract a small semantic action vocabulary from selected arguments.

- **[Should] Separate output simplification from input impoverishment.** Predicting `run_tests` needs no output arguments. But deciding whether to recommend it may require knowing which project was edited, which tests already ran, and whether they passed. Keep relevant prior context and results as inputs. Never include the target call or subsequent results in that example’s input.

- **[Should] Target ambiguity limits usefulness even when the label is correct.** `read_file` does not select a file; `create_pr` does not select a branch or base. Another component must resolve these details and check prerequisites. Tool-name accuracy therefore measures only part of recommendation quality. The repository itself defines useful signals as relevant, fresh, and structured (`GUIDING-PRINCIPLES.md:40`).

- **[Should] Regex extraction still needs evidence that it finds real calls.** Markdown can contain quoted examples, proposed calls, repeated transcripts, and ordinary prose mentioning tools. Restrict extraction to observed call boundaries, retain source offsets, reject unknown forms, and manually audit a sample for precision and missed calls. Skipping JSON validation does not justify skipping label-quality checks.

- **[Should] Historical next actions are not automatically desirable next actions.** Logs include retries, mistakes, and unnecessary reads. Training only on call events also omits opportunities to stay silent. Evaluate on held-out sessions or later dates against a frequent-tool baseline; measure useful recommendations and nuisance prompts, with an abstention option.

- **[Should] Preserve the source so the shortcut stays reversible.** Keep immutable logs or source references alongside derived labels. You can defer argument parsing without permanently losing targets, intent, and the ability to repair labels.

**Evidence limit:** The local Needle document repeats this question (`relay-system/2026-09-06/needle-oracle-140920/needle-oracle.PROMPT.txt:3`). I did not locate the referenced Needle issue or historical CLIO corpus here, so actual tool granularity and extraction reliability remain unverified; no model or ANE performance claim follows from this review.

**RECOMMENDATION:** Start with context → semantic action-name prediction, preserve raw records, and extract only the argument fields needed to distinguish actions; expand to structured outputs only when measured recommendation failures require them.
tokens used
28,258
**ANSWER:** Predicting only the tool name can be useful for a coarse recommendation sentinel. It does **not** establish which concrete task to do next. I would approve name-only **prediction targets**, while preserving the original records and relevant context. Stripping arguments from the entire dataset is a different, more damaging simplification.

The key assumption is that RebalanceOS or a human already knows the relevant project and target, and only needs a suggestion such as “run tests.” If the Oracle must choose *which* tests, file, issue, or project deserves attention, tool names alone cannot express its answer.

**FINDINGS**

- **[Pass] Full argument generation is unnecessary for an advisory classifier.** A context → action-category model can provide useful suggestions without emitting executable JSON. That is consistent with “least code that clears the bar,” which explicitly retains correctness as a requirement (`GUIDING-PRINCIPLES.md:63`). Neither full schema validation nor arbitrary argument generation must be part of this first experiment.

- **[Blocker] Actual tool names may identify transport, not intent.** Your examples—`run_tests`, `create_pr`, `read_file`—are meaningful action categories. Actual logs might instead record all three as `Bash` or `exec_command`, with the distinction entirely inside the command argument. A name-only extractor would collapse different decisions into one label. Inspect representative logs before accepting this simplification; if this pattern dominates, extract a small semantic action vocabulary from selected arguments.

- **[Should] Separate output simplification from input impoverishment.** Predicting `run_tests` needs no output arguments. But deciding whether to recommend it may require knowing which project was edited, which tests already ran, and whether they passed. Keep relevant prior context and results as inputs. Never include the target call or subsequent results in that example’s input.

- **[Should] Target ambiguity limits usefulness even when the label is correct.** `read_file` does not select a file; `create_pr` does not select a branch or base. Another component must resolve these details and check prerequisites. Tool-name accuracy therefore measures only part of recommendation quality. The repository itself defines useful signals as relevant, fresh, and structured (`GUIDING-PRINCIPLES.md:40`).

- **[Should] Regex extraction still needs evidence that it finds real calls.** Markdown can contain quoted examples, proposed calls, repeated transcripts, and ordinary prose mentioning tools. Restrict extraction to observed call boundaries, retain source offsets, reject unknown forms, and manually audit a sample for precision and missed calls. Skipping JSON validation does not justify skipping label-quality checks.

- **[Should] Historical next actions are not automatically desirable next actions.** Logs include retries, mistakes, and unnecessary reads. Training only on call events also omits opportunities to stay silent. Evaluate on held-out sessions or later dates against a frequent-tool baseline; measure useful recommendations and nuisance prompts, with an abstention option.

- **[Should] Preserve the source so the shortcut stays reversible.** Keep immutable logs or source references alongside derived labels. You can defer argument parsing without permanently losing targets, intent, and the ability to repair labels.

**Evidence limit:** The local Needle document repeats this question (`relay-system/2026-09-06/needle-oracle-140920/needle-oracle.PROMPT.txt:3`). I did not locate the referenced Needle issue or historical CLIO corpus here, so actual tool granularity and extraction reliability remain unverified; no model or ANE performance claim follows from this review.

**RECOMMENDATION:** Start with context → semantic action-name prediction, preserve raw records, and extract only the argument fields needed to distinguish actions; expand to structured outputs only when measured recommendation failures require them.
