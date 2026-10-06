**NO FIRSTHAND VERIFICATION CITED** — treat conclusions as conditional (codex's answer carries an unsupported [Pass]/verified/confirmed-style claim with no quoted span or file:line citation nearby, despite the consult PREAMBLE asking advisors to cite evidence.)

> **ATTESTATION**
> Model: gpt-6.1-sol
> Provider: openai
> Sandbox: read-only

Reading additional input from stdin...
2026-09-30T18:26:40.143356Z  WARN codex_skills::interface: ignoring interface.icon_small: icon path with '..' must resolve under plugin assets/
2026-09-30T18:26:40.143750Z  WARN codex_skills::interface: ignoring interface.icon_large: icon path with '..' must resolve under plugin assets/
2026-09-30T18:26:40.171054Z  WARN codex_core::agents_md: project doc exceeds remaining budget; truncating path=file:///private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-42794-90iuouwj/AGENTS.md remaining_bytes=32768
OpenAI Codex v0.159.1
--------
workdir: /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-42794-90iuouwj
model: gpt-6.1-sol
provider: openai
approval: never
sandbox: read-only
reasoning effort: low
reasoning summaries: none
session id: 01a0f391-93db-7670-8d87-08d981820c52
--------
user
You are an INDEPENDENT advisor in a one-shot cross-model consult. Another model is answering the SAME question separately and a coordinator will reconcile both answers, so give your own honest, specific read — do not hedge toward a consensus you cannot see. Read any repo files the question references (cite file:line). Respond with: (1) a short direct ANSWER; (2) graded FINDINGS — [Blocker]/[Should]/[Nit]/[Pass] — where applicable; (3) a one-line RECOMMENDATION. You are ADVISORY ONLY: output your analysis as text; do not rely on writing files (you are running in a throwaway copy).

=== CONSULT QUESTION ===
Review a small extension to GH-896's centralized task-sync, requested by the user for Codex desktop session titles/pins every 15 minutes. Read skills/3-weekly/task-sync/scripts/{core.py,task_sync.py} and SKILL.md. Operational envelope: local desktop, no direct app-store writes, no added tests/gates or daemon. Proposed implementation: new thin adapters/codex.py, exposed with --ide codex --codex-snapshot PATH --exclude-thread ID. Snapshot is fresh native list_threads response plus captured_at seconds and activity_at mapping from native read_thread most recent turn's completedAt or startedAt. Timestamp mapping must cover local eligible recent chats; actual activity, not title mutation updatedAt, drives stamps. Native hostId local and kind codex only; skip custom sidebar sections to preserve grouping, excluded heartbeat ID required. Reuse core clean_base/local_stamp/new_ide_report. Adapter is planning only, --apply rejected clearly (native agent applies rename/pin via supported tools). --unpin-days/--group not supported; preserve existing pins and sorting; reject unsafe snapshots and missing activity. CLI no default adapter change. Skill gives exact native flow: inventory (limit 200), read recent turns, export snapshot, planner, re-read before changes, native set_thread_title and move_thread_to_sidebar_section(sectionId pinned), verify native state. Preserve base titles by default; no agent summary inference needed. Single heartbeat uses this same skill and planner, native automation tool, quiet unchanged, tool unavailability fail closed; extend existing scheduler if present. No broad database reverse engineering.
Questions: 1 Is this minimal DRY reuse? 2 Are safety/idempotence/activity handling correct? 3 What concrete blockers must be fixed? Include file citations and scoped falsifiers; don't demand enterprise machinery or new suites. Reversibility Easy: native title and pin changes can be undone; no deletions. PR #900 remains open, so this is a dependent branch and must disclose dependency. Advise only, don't edit, commit, or run mutation-heavy tests.

hook: SessionStart
hook: SessionStart Completed
codex
I’ll inspect the shared planner, CLI, and skill instructions, then assess the proposed Codex adapter against the stated safety envelope.
exec
/bin/zsh -lc 'cat ROUTER.md
cat skills/3-weekly/task-sync/scripts/core.py
cat skills/3-weekly/task-sync/scripts/task_sync.py
cat skills/3-weekly/task-sync/SKILL.md' in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-42794-90iuouwj
 succeeded in 0ms:
# ROUTER.md

This file is the first entry point for an AI agent working in this repo: it tells you what to read, what to run, and which files are canonical.

XYZ Forge is three parts: **XYZ Forge**, the harness (this router and `AGENTS.md`); **PDDA**, project-doc governance (`PROJECT/PDDA.md`); and **PRS**, the Product Release System, which is the RELEASES ledger (`RELEASES-DB-FAQS.md`). Definition: [HOW-TO-USE.md → Glossary](HOW-TO-USE.md#glossary--the-five-terms-youll-hit-first).

## Role split

- `ROUTER.md` = startup order and canonical entry points
- `GUIDING-PRINCIPLES.md` = XYZ Forge’s product purpose, scope and *why*, and the canonical North Star: durable, reversible, DRY — extend what exists rather than forking a parallel system
- `AGENTS.md` = behavioral rules, decision quality, reversibility, blast radius, proof
- `README.md` = human-facing repo/product overview
- `ROADMAP.md` = LEGACY pointer ledger, frozen since the `ROADMAP_SOURCE=releases` flip — the RELEASES DB (`releases.db` via `releases.sql`) is the source of truth; write via `releases roadmap add`, never by editing this file
- `CHANGELOG.md` = the end-of-iteration running log (first-class PDDA artifact; governed by `PROJECT/PDDA.md`)
- `RELEASES DB` = the single runtime and release-planning ledger (`releases.db` via `releases.sql`; operated through `releases_app.py`); `RELEASES.md` is retired (GH-568)
- `HARNESS-MODELS-REGISTRY.md` = evaluated agent harnesses, supported model grades (A/B/C), and CLI flags
- `MACHINE-CONTRACTS.md` = the Jog ↔ Preflight ↔ Marathon machine-contract reference (`marathon-invocation@1`, `marathon-drive/result@1`) and their version/deprecation policy
- `PROJECT/**` docs = canonical execution detail for a specific effort
- `PARKED/` = root holding area for incidental agent findings outside the current task; triage may promote an item into issue-first PDDA intake
- `PROJECT/PDDA.md` = shared PDDA document contract maintained in Forge (incl. CHANGELOG); repo-specific adoption policy stays in this router
- `PROJECT/CONSTITUTION.md` = locally maintained PDDA-layer policy of record, with verified-success, reversibility and local-first safeguards adopted by XYZ; advisory-only LLM checking is PDDA-specific and does not replace XYZ relay approval
- `PROJECT/DO-NOT-BUILD.md` = locally maintained PDDA anti-scope; XYZ product scope remains in GUIDING-PRINCIPLES, not a blanket prohibition on coordination or execution
- `PROJECT/PDDA-MODE-GUIDE.md` = XYZ-maintained guidance for selecting PDDA’s enforcement mode
- `PROJECT/PDDA-SYNC-POLICY.md` = binding XYZ-owned review policy for PDDA distribution updates

## Startup sequence

1. Read `ROUTER.md` to understand the repo's operating order and canonical files. -> expect one clear next file, not a repo-wide scavenger hunt.
2. Read `AGENTS.md` before making recommendations or edits. -> expect explicit assumptions, a reversibility read on consequential changes, and verified claims only.
3. Run `python3 utils/py/releases_app.py roadmap list` to find the active effort or parked intake. -> expect links outward to the canonical `PROJECT/**` docs; the roadmap is a pointer ledger, not a plan body. (`ROADMAP.md` is the frozen legacy file — do not read it for current state or edit it.)
4. Read the linked `PROJECT/**` document that owns the work you are touching. -> expect the near-top `## Status` table to tell you what was just completed and what is next.
5. If the task touches project docs, read `PROJECT/PDDA.md` and follow the PDDA contract. -> expect `PROJECT/2-WORKING` docs to have frontmatter, the exact status table, and QA gates when phased.
6. Before reporting success on code or runtime work, check that the same `python3` used by the gate imports `requests`, `yaml` (PyYAML), and `pytest`, then run `./validate.sh`. -> expect the suite to stay green; do not claim completion if it fails or was skipped.
7. Before reporting success on doc-hygiene or roadmap work, run `utils/pdda/pdda.sh run` (or the relevant `utils/pdda/pdda.sh <check>` subcommand). -> expect deterministic findings first, then any LLM review.

## Canonical rules

- Do not put phase checklists, build steps, or deep execution notes in the roadmap ledger.
- Every active doc in `PROJECT/2-WORKING/` must be reflected by a pointer row in the roadmap ledger (the RELEASES DB) that links it. A working doc that should not appear opts out with `roadmap_exempt: true` in its frontmatter. Governance lives in `PROJECT/PDDA.md` → "ROADMAP contract".
- Promoting a capture from `1-INBOX` to `2-WORKING` is a DB-verb procedure (`roadmap repoint` + `roadmap update` / `roadmap move`), never a markdown edit — the exact steps and their two known gate traps (`updated:` frontmatter key, bullet-format `raw_text`) live in `SOP.md` → "Step 1b: Promoting a capture from 1-INBOX to 2-WORKING (releases-mode)".
- Every captured GitHub issue doc in `PROJECT/1-INBOX/GH-*.md` must also be parked as a queue row immediately at intake — `python3 utils/py/releases_app.py roadmap add --issue-num N --issue-url U --title T --created YYYY-MM-DD --doc-path P` (or `hq park`, which routes there automatically in this repo) — then promoted or removed later. Governance lives in `PROJECT/PDDA.md` → "GitHub issue intake" + "ROADMAP contract".
- Incidental findings outside the active task go first to root `PARKED/` under its README contract.
  They need no issue or roadmap row until triage promotes them. “Queue / parked intake” in RELEASES
  names the later, formal issue queue; it is not a replacement for the root folder. Required work
  in the current task remains in its active plan rather than being parked.
- Do not create a second competing plan when a canonical `PROJECT/**` doc already exists.
- Issue-first: any change beyond a **2–3 line** fix opens a GitHub issue first, then a pointer doc **named after the issue** (`GH-<number>-VERY-SHORT-DESC.md`, e.g. `GH-1234-SHOWME-COMMAND.md`), and that capture is **parked in the roadmap ledger immediately** (`releases roadmap add`) before execution begins. The issue is the signal stream; the pointer doc is the execution surface of record. Genuinely trivial edits (≤2–3 line fixes, typos, path repoints, doc-only one-liners) are exempt. Governed by `PROJECT/PDDA.md` → "GitHub issue intake".
- Issue-first applies when a parked observation is promoted into work, not when an agent first
  records an out-of-scope observation in `PARKED/`.
- Runtime triage labels: since the `XYZ_PYTHON` flip the harness is dual-runtime, so any harness-bug issue gets a `runtime:` label — `runtime:python` (default path), `runtime:bash` (`XYZ_PYTHON=0` opt-out), or `runtime:parity` (the twins diverge). `/file-xyz-bug` harvests and applies it; for in-repo intake (`/triage`, hand-filed `gh issue create`) apply it by hand. Omit rather than guess — a wrong runtime tag misroutes triage.
- **`GH-<n>` numbering spans two repos.** This repo succeeded [`Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm`](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm) and the migration did **not** renumber references, so a `GH-<n>` in a source comment, test name, or CHANGELOG entry may belong to either repo. Upstream ledger entries are preserved verbatim in [`docs/ROADMAP-UPSTREAM-ARCHIVE.md`](docs/ROADMAP-UPSTREAM-ARCHIVE.md), which states its own numbering caveat and is not parsed by anything. Where an upstream number is cited from code that ships here, mirror it as a closed `[upstream archive]` issue so the citation resolves locally (#407, #408 are the pattern) rather than editing the comment. Raised externally as GH-406 §3.1.
- Do not override deterministic PDDA findings with prose.
- Do not report a win you did not verify with the relevant script or test.
- Update `CHANGELOG.md` at the end of each iteration; its governance lives in `PROJECT/PDDA.md` — do not re-specify CHANGELOG rules in `AGENTS.md` or elsewhere.

## PDDA distribution

Forge is canonical for PDDA. `utils/pdda/pdda-install.sh` installs governance into targets;
`utils/pdda/pdda-sync.sh` updates registered targets from the shared manifest.
Read [PDDA migration](docs/PDDA-MIGRATION.md) before switching an existing distributor.
Targets own their startup documents; generic templates live under `utils/pdda/templates/`.

## Command rails

For repo correctness:

```bash
bash githooks/install.sh        # ONCE PER CLONE — wires the pre-push gate (GH-544)
bash githooks/install.sh --check # is this clone gated? exit 1 if not
./validate.sh              # the gate — PARALLEL by default (GH-544), auto-sized to the host (GH-35)
./validate.sh --print-mode # which mode would this host pick, and why — runs nothing
./validate.sh --sequential # force the sequential run (see the hook’s measured GREEN in Ns line)
./validate.sh --tier 2 --subsystem hq   # GH-35: one subsystem's focused suites (pre-push speed, NOT evidence)
./validate.sh --sequential --subsystem small  # GH-831: the Small list — locally a self-check; hosted, the reconcile's qualifying run for docs/ledger/skill landings
./validate.sh --auto       # GH-35: classify the git diff, run the minimal safe tier (fails closed to 3)
./validate.sh --throttle   # GH-35: 2 workers under nice — quiet-machine mode (--burst restores full width)
bash ci-local.sh           # the QUALIFYING run — sequential + writes the gate record (GH-509/GH-536)
```

**Both gate entry points refuse to run from a linked git worktree (GH-45)** — a worktree shares
the parent clone's `.git`, and an observed suite escape corrupted the parent (core.bare, origin,
remote refs, development). Run the gate from a separate disposable full clone; `XYZ_ALLOW_WORKTREE_GATE=1` is the
announced override for disposable runs.

**Local push checks and hosted CI both apply.** This repository is public; the workflow covers
pushes and pull requests to `main` and `development`. Hosted macOS promotion evidence requires an
actual passing run for the exact commit; the Ubuntu canary remains advisory. Install the local
hook with `githooks/install.sh` for each clone — `.git/hooks/` does not travel with a clone. One
installation covers that clone’s branches and linked worktrees. Run mutation-heavy gates and
pushes that invoke them from a separate disposable full clone, as required by AGENTS.md.
Bypasses (`git push --no-verify`, `XYZ_SKIP_PREPUSH=1`) announce that the local gate was skipped.
**Draft-review publication is distinct from merge readiness (GH-487):** an operator-requested WIP
draft may use a bypass only with (a) current focused evidence for the changed area — e.g. the
mapped subsystem's suites run green — (b) the hook's skipped-gate disclosure echoed into the PR
description, and (c) merge readiness still outstanding. A bypassed push never authorises merge,
promotion, or teardown, and a published draft is never approval.

**Parallel became the default on 2026-08-14 (GH-544)** when the local gate was the only gate during
the private phase, and a slow gate risks being skipped; use the hook’s measured `GREEN in Ns` line for current cost. **GH-35 (2026-08-18) rebalanced the width to `cores/2` (floor 2, cap 4) and put every
worker under `nice -n 10`** — the original `cores − 2` (up to 8) saturated developer machines badly
enough to wedge the editor; `--burst` buys the old full-core width back for unattended runs, and
`--throttle`/`--quiet-cpu` pins 2 workers. Ambient levers: `XYZ_VALIDATE_THROTTLE=1`,
`XYZ_VALIDATE_MAX_JOBS=N`, `XYZ_VALIDATE_PARALLEL` (flags > MAX_JOBS > THROTTLE > PARALLEL > host
detection; malformed values exit 2 naming the variable). Below 4 cores, or where `xargs -P` is
unsupported, the run **falls back to sequential and says so** — every run prints the mode it chose
and the reason, so a fallback is never silent.

**GH-35 also added TIERED SELECTION on top, as a separate axis from width.** `utils/ci-route.sh`
owns one fail-closed subsystem registry (hq, releases, telemetry, ate, swe-diagram, pdda,
agent-chorus, standup, skills-army-hq, plus `small`, a gate-only list that claims no paths); a push the classifier rates `tier=2` runs only those focused
suites at the boundary, `--tier 1` runs the docs gate, and everything else — unknown paths, unclaimed
test edits, kernel surfaces — runs the full suite. `--auto` classifies a local diff the same way.
Tiers 1 and 2 are pre-push speed and are labelled NOT promotion evidence; only `ci-local.sh`'s
sequential full run qualifies (GH-509).

**GH-831 (2026-09-25) made these three tiers for what qualifies a landing.** The push hook is unchanged.
After a merge, the hosted reconcile (`wave-reconcile.yml`) qualifies each landing with **one** run,
picked by classifying the landing's changes at the tested commit:

- **Small** — docs, the ledger dumps (`releases.*`, `harnesses.*`) and non-core skill files (tier 1):
  `validate.sh --sequential --subsystem small`, the PDDA, PRS and canary suites plus the PDDA gate
  and the Python layer. The receipt records the list it ran.
- **Medium** — mapped non-core code (tier 2): the full registry at the reconcile, the area's suites at push.
- **Large** — core harness, unmapped code, gate surfaces (tier 3): the full registry.

Promotion always runs the full registry. Eight skill-text suites are off, recorded in
`test/gh306-registry-bidirectional.sh`'s EXEMPT list, and no new suites are added (AGENTS.md). The code of
core skills (`relay`, `relay-xyz`, `relay-automation`, `merge-cleanup`, `express`, `jog`) never routes as
docs. Skill markdown keeps its existing docs routing, except that `relay-xyz` and `relay-automation` stay
full-gate surfaces for every file. merge-cleanup's `SKILL.md` and `WORKTREE-SAFETY.md` are full-gate files too:
they are what `gh436-merge-cleanup` reads, and GH-836 D1 moved that suite from Small to Large.
Plan: [GH-831](PROJECT/2-WORKING/GH-831-THREE-TIER-GATE.md).

`--burst` / `XYZ_VALIDATE_MAX_JOBS` are honoured for tier 2: 2 is the default width, not a pin.
Run one gate at a time on a host: a concurrent relay turn, second gate or pollers lengthen the run
(`nice` protects the editor, not the wall-clock).

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
utils/pdda/pdda.sh releases         # legacy releases check (skips when RELEASES.md is retired)
utils/pdda/pdda.sh releases-current # read-only roll-up: queries releases.db (GH-568)
utils/pdda/pdda.sh quad-concepts    # opt-in: requires a "## Quad Concepts" section of 1-4 bullets (lever: .pdda-quad / PDDA_QUAD)
utils/pdda/pdda.sh glance           # read-only roll-up: title + Quad Concepts for each PROJECT/2-WORKING doc
utils/pdda/pdda.sh governance       # repo-root governance-doc cross-reference + doc/code drift
utils/pdda/pdda.sh marathon-qa      # mechanical marathon Wave QA receipt & checklist gate (GH-784)
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

**Subsystem 1 — releases** (GH-32 / GH-568): the release ledger. App-managed writes
only; `releases.db` and the `releases` CLI (`releases list`, `releases show`) are the sole source of truth (`RELEASES.md` is retired per GH-568).
**Subsystem 2 — the roadmap ledger** (GH-69 shadow → GH-238/GH-243 canonical → GH-269 retired ROADMAP.md → GH-567 retired ROADMAP-DASHBOARD.md): since the
`ROADMAP_SOURCE=releases` flip, `roadmap_items` IS the ledger — write rows with
`releases roadmap add` (or `hq park`), read with `roadmap list`.
The legacy markdown roadmap files (ROADMAP and ROADMAP-DASHBOARD) have been retired. `roadmap sync` exists for legacy-mode repos only and
no-ops here by design (it would delete `add`-parked rows). Pinned by `test/gh69-roadmap-shadow.sh`,
`test/gh238-hq-releases-mode.sh`, `test/gh269-roadmap-retired.sh`, and `test/gh567-roadmap-dashboard-retired.sh`.

## Routing hints

- If the task is about current priorities or active work, start with `releases roadmap list`, then follow the linked `PROJECT/**` doc.
- If the task changes the roadmap ledger, write through the CLI (`releases roadmap add` for intake; `hq park` routes there automatically).
- If the task touches `releases.db`, `releases.sql`, or a merge conflict on either, start in [RELEASES-DB-FAQS.md](RELEASES-DB-FAQS.md); writes go through the CLI, never a hand-edit.
- If the task is about fresh GitHub intake or duplicate-prevention, start in the roadmap queue (via `releases roadmap list`), then follow the linked `PROJECT/1-INBOX/GH-*.md` capture doc.
- If the task is about document quality, active-doc lifecycle, roadmap sprawl, or automation policy, start in `PROJECT/PDDA.md`.
- If the task is about the CHANGELOG, provenance, or end-of-iteration logging, the governance is in `PROJECT/PDDA.md` (the "CHANGELOG.md — end-of-iteration record" contract).
- If the task is about release planning, ledger health, cleanup, authoring, or publishing, invoke `/releases`. It operates against `releases.db` via `releases_app.py`; `RELEASES.md` has been retired (GH-568). It conditionally points strategic drift to `/radar` and a frozen path-to-ship to `/finish-line` without duplicating either workflow.
- If the task is about the `tick` runtime, event projection, or multi-agent coordination kernel, start in `README.md`, then `bin/`, `src/`, `test/`, and the active project doc.
- If the task is about the **Aider ↔ OpenRouter** turn-taker lane (`relay-automation/aider-turn.sh` — an OpenAI-standard build lane discrete from Codex; `AIDER_MODEL`/`OPENROUTER_API_KEY`, `--builder aider`), start in `PROJECT/3-COMPLETED/GH-77-AIDER-OPENROUTER-LANE.md`. The shim owns the tick token ops (Aider can't run shell mid-turn), asserts token ownership before launching Aider, and runs Aider `--no-auto-commits` (the harness commits).
- If the task is about running, driving, or reviewing via the relay (`relay-automation/` — `relay-drive.sh`, `poll.sh`, the turn shims, `marathon*.sh`), **invoke the `relay-xyz` skill first — do not improvise the handoff or hand-roll a harness from `ls relay-automation/`.** The skill owns the locator, sandbox rules, exit codes, and the safety boundary; a `PreToolUse` guard (`relay-automation/hooks/relay-xyz-guard.sh`) blocks driving a harness driver before the skill is loaded. For the two live-Claude-windows, same-machine duel recipe (Reporter↔Maintainer with a human go-gate), the copy-paste form is [relay-automation/DUELING-CLAUDES.md](relay-automation/DUELING-CLAUDES.md).
- If the task is about the ATE (Automated Testing Environment) skill — unattended variation-test fuzzing whose implementation lives under `utils/ate/` — start at its canonical interface in `skills/4-occasional/ate/SKILL.md`.
- If the task is about relay session telemetry, the `focus5float` health feed, or extraction scripts under `utils/telemetry/`, start in `PROJECT/1-INBOX/GH-24-RELAY-TELEMETRY-EXTRACTOR.md`.
- If the task is about live per-session completion telemetry — the `XYZ.json` log every relay/marathon/swarm session appends to at the harness repo root (schema: `harness`/`sessionId`/`health`/`title`/`description`/`updatedAt`), the shared writer `utils/telemetry/append-xyz-completion.sh`, or the shared health mapping `utils/telemetry/health-lib.sh` — start in `PROJECT/1-INBOX/GH-75-XYZ-JSON-COMPLETION-TELEMETRY.md`. `XYZ.json` is local + gitignored (machine-specific).
- If the task is about cross-repo HQ tooling (`utils/hq/` — `hq.sh` single-repo actions, `rollup.sh` the Obsidian daily ROADMAP rollup, `marathon-scan.sh` the cross-repo marathon-preflight aggregator, `hq-lib.sh` the shared repo registry), start in `PROJECT/3-COMPLETED/GH-27-ROADMAP-DASHBOARD.md` and `PROJECT/3-COMPLETED/GH-158-HQ-MARATHON-SCAN.md`. The two rollups are deliberately separate today (`rollup.sh` → Obsidian, generic; `marathon-scan.sh` → hub repo, preflight-aware) and are not yet bridged — tracked in `PROJECT/1-INBOX/GH-192-HQ-MARATHON-OBSIDIAN-ROLLUP.md`.
- If the task is about a proposed roadmap-steward agent, start here, then read `PROJECT/PDDA.md` and its `Proposed roadmap steward extension` section.
- If the task is about finding or picking a skill for a job, see `ARCHITECTURE.md` → "Skills Index" for a one-line inventory of every skill in `skills/`.
- If the task is about **managing skills for the system** — adding a skill to the machine-wide collection, deploying/refreshing/removing it across the configured app targets (`targets.json`, machine-local), or asking what is deployed — the mechanism is the `skills-army-hq` skill (`skills/3-weekly/skills-army-hq/SKILL.md`). `skills/` in this repo is the authoring source; the durable collection lives wherever `XYZ_SKILLS_ROOT` points (machine-local, never committed; falls back to `~/git-pulse-sync/Deployed Skills`), and only `intake.py` / `sync.py` mutate it or the app symlinks. Never hand-copy a skill folder into an app's skills directory.
- Issue-first SOP: any change beyond a 2–3 line fix (and every project plan) opens a GitHub issue *first*, then gets a pointer doc named after the issue at `PROJECT/1-INBOX/GH-<number>-VERY-SHORT-DESC.md` — e.g. `GH-1234-SHOWME-COMMAND.md` — and that capture is parked in the roadmap ledger queue immediately via `releases roadmap add` (format + lifecycle owned by `PROJECT/PDDA.md` → "GitHub issue intake"), following the normal `1-INBOX` → `2-WORKING` flow. Genuinely trivial edits (≤2–3 line fixes, typos, path repoints, doc-only one-liners) are exempt and commit directly.
"""task-sync core — shared semantics and the adapter safety contract.

Owns the stamp logic, the report schema, and the adapter error contract.
Adapters own only their app's store I/O; they must raise AdapterError
(with a clear, named message) instead of proceeding on a failed or empty
authoritative read — a failed read never triggers a destructive write.

Stamp semantics (operator-locked, GH-896): the MM-DD prefix is the task's
own last-activity date, never wall-clock at sweep time. Adapters convert
their store's native timestamp to a local datetime and call stamp_of().
"""

from __future__ import annotations

import re
from datetime import datetime, timezone

# A leading U.S. mm-dd (or legacy mm/dd) stamp followed by a description.
STAMP_RE = re.compile(r"^(\d{2}-\d{2})\s+(\S.*)$", re.DOTALL)
# Legacy slash form seen in Antigravity titles, stripped before re-stamping.
SLASH_STAMP_RE = re.compile(r"^\d{2}/\d{2}(?=\s|$)\s*")
# A bare date is not a description ("09-29" alone must not restack to "09-29 09-29").
BARE_DATE_RE = re.compile(r"^\d{2}[-/]\d{2}$")
MAX_BASE = 72  # keep the descriptive part readable in a task list


class AdapterError(Exception):
    """An adapter refused to proceed — the store failed a safety check."""


def local_stamp(dt: datetime) -> str:
    """The mm-dd stamp for an aware-or-naive local datetime."""
    return dt.strftime("%m-%d")


def utc_text_to_local_dt(text: str) -> datetime | None:
    """Parse an app's UTC timestamp text into local time.

    Handles the formats actually seen in Antigravity's
    ``conversation_summaries.last_modified_time`` — ISO-8601 with
    fractional seconds and an explicit offset
    (``2026-06-19 01:31:58.720731+00:00``). The fallback chain also
    accepts offset-naive ``%Y-%m-%d %H:%M:%S`` text and — deliberately,
    matching the superseded original — treats NAIVE text as already
    local. Returns None for absent, non-string, or unparseable input —
    callers decide whether that skips the row or aborts."""
    if not text or not isinstance(text, str):
        return None
    cleaned = text.strip()
    try:
        return datetime.fromisoformat(cleaned).astimezone()
    except ValueError:
        pass
    for fmt in (
        "%Y-%m-%d %H:%M:%S.%f%z",
        "%Y-%m-%d %H:%M:%S%z",
        "%Y-%m-%d %H:%M:%S.%f",
        "%Y-%m-%d %H:%M:%S",
    ):
        try:
            parsed = datetime.strptime(cleaned, fmt)
        except ValueError:
            continue
        if parsed.tzinfo is None:
            parsed = parsed.replace(tzinfo=timezone.utc)
        return parsed.astimezone()
    return None


def ms_to_local_dt(ms: int) -> datetime:
    return datetime.fromtimestamp(ms / 1000)


def clean_base(raw: str, *, slash_stamps: bool = False) -> str:
    """Strip any existing stamp and collapse whitespace so re-stamping
    never stacks prefixes; cap length so long prompt-derived titles stay
    scannable. A bare date is not a description.

    slash_stamps=True also strips the legacy mm/dd form (Antigravity)."""
    base = raw.strip()
    if slash_stamps:
        base = SLASH_STAMP_RE.sub("", base)
    match = STAMP_RE.match(base)
    base = match.group(2) if match else base
    base = re.sub(r"\s+", " ", base).strip()
    if BARE_DATE_RE.fullmatch(base):
        return ""
    if len(base) > MAX_BASE:
        base = base[: MAX_BASE - 1].rstrip() + "…"
    return base


def new_ide_report() -> dict:
    """The per-IDE report shape every adapter returns."""
    return {
        "swept": 0,
        "renamed": [],
        "pinned": [],
        "unpinned": [],
        "needs_summary": [],
        "skipped": 0,
        "error": None,
    }


def merge_report(mode: str, ide_reports: dict) -> dict:
    """The merged stdout contract: mode + one section per IDE. The
    heartbeat and installer consume this JSON; per-IDE lists stay
    machine-addressable."""
    return {"mode": mode, "ides": ide_reports}


def receipt_path() -> str:
    import os

    return os.path.expanduser("~/.cache/task-sync/last-run.json")


def write_receipt(mode: str, ide_reports: dict) -> str:
    """Heartbeat receipt — written on apply runs only. Doctor reads it;
    a missing receipt is a distinct non-red 'pending' state."""
    import json
    import os

    path = receipt_path()
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w", encoding="utf-8") as f:
        json.dump(
            {
                "at": datetime.now().isoformat(timespec="seconds"),
                "mode": mode,
                "ides": {
                    name: {
                        "swept": rep.get("swept", 0),
                        "renamed": len(rep.get("renamed", [])),
                        "error": rep.get("error"),
                    }
                    for name, rep in ide_reports.items()
                },
            },
            f,
            indent=2,
        )
        f.write("\n")
    return path
#!/usr/bin/env python3
"""task_sync — unified IDE task-list grooming (GH-896).

One CLI over per-IDE adapters (zcode, agy). Default is dry-run; pass
``--apply`` to commit. Emits one merged JSON report; per-IDE sections
stay machine-addressable (the heartbeat consumes ``needs_summary``).

    task_sync.py --doctor
    task_sync.py                       # dry-run, both IDEs
    task_sync.py --apply               # the heartbeat invocation
    task_sync.py --set-title <id> "Short description of last action"
    task_sync.py --zcode-db /tmp/copy.sqlite --agy-root /tmp/agy-fixture ...

Safety contract (core-enforced, GH-896): schema-validate before write
with a clear abort; dry-run by default; write only on change; a failed
or empty-authoritative read never triggers a destructive write;
Antigravity writes are gated on the app being closed; the Electron store
is backed up and replaced atomically. One IDE's store failure never
blocks the other — each section reports its own error.
"""

from __future__ import annotations

import argparse
import importlib
import json
import os
import sys
from datetime import datetime, timedelta

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import core  # noqa: E402

ADAPTERS = ("zcode", "agy")

SWEEP_KNOBS = ("hours", "all", "pin_hours", "no_pin", "unpin_days", "include_cron", "group")


def _build_adapter(name: str, args, apply: bool):
    module_name = "antigravity" if name == "agy" else name
    module = importlib.import_module(f"adapters.{module_name}")
    if name == "zcode":
        return module.ZcodeAdapter(db_path=args.zcode_db, apply=apply)
    if name == "agy":
        return module.AntigravityAdapter(
            agy_root=args.agy_root,
            apply=apply,
        )
    raise SystemExit(f"task-sync: unknown adapter {name!r}")


def _sweep_kwargs(args) -> dict:
    return {
        "hours": args.hours,
        "include_all": args.all,
        "pin": args.pin,
        "pin_hours": args.pin_hours,
        "unpin_days": args.unpin_days,
        "include_cron": args.include_cron,
        "group": args.group,
    }


def run_doctor(args) -> tuple[dict, int]:
    ides = {}
    red = 0
    receipt = core.receipt_path()
    receipt_state = "absent"
    receipt_red = None
    if os.path.exists(receipt):
        try:
            with open(receipt, "r", encoding="utf-8") as f:
                at = json.load(f).get("at", "unreadable")
            receipt_state = at
            if at == "unreadable":
                receipt_red = f"heartbeat receipt unreadable at {receipt}"
            else:
                age = datetime.now() - datetime.fromisoformat(at)
                if age > timedelta(hours=2):
                    receipt_red = (
                        f"heartbeat receipt stale: last apply {at} "
                        f"({age.total_seconds() / 3600:.1f}h ago) — heartbeat may be dead"
                    )
        except (OSError, ValueError):
            receipt_state = "unreadable"
            receipt_red = f"heartbeat receipt unreadable at {receipt}"
    for name in args.ide:
        adapter = _build_adapter(name, args, apply=False)
        try:
            ides[name] = adapter.doctor()
        except core.AdapterError as exc:
            ides[name] = {"ok": False, "reds": [str(exc)]}
        if not ides[name].get("ok"):
            red = 1
    report = {
        "mode": "doctor",
        "heartbeat": {
            "receipt": receipt,
            "state": receipt_state,
            "note": "pending — no receipt yet" if receipt_state == "absent" else receipt_state,
        },
        "ides": ides,
    }
    if receipt_red:
        report["heartbeat"]["red"] = receipt_red
        red = 1
    return report, red


def run_sweep(args, apply: bool) -> tuple[dict, int]:
    ides = {}
    red = 0
    for name in args.ide:
        adapter = _build_adapter(name, args, apply=apply)
        try:
            ides[name] = adapter.sweep(**_sweep_kwargs(args))
        except core.AdapterError as exc:
            ides[name] = core.new_ide_report()
            ides[name]["error"] = str(exc)
            red = 1
    report = core.merge_report("apply" if apply else "dry-run", ides)
    if apply and red == 0:
        report["receipt"] = core.write_receipt(report["mode"], ides)
    return report, red


def run_set_title(args) -> tuple[dict, int]:
    task_id, description = args.set_title
    ides = {}
    red = 0
    apply = args.apply
    for name in args.ide:
        adapter = _build_adapter(name, args, apply=apply)
        try:
            if name == "agy":
                ides[name] = adapter.set_title(task_id, description, auto_pin=args.auto_pin)
            else:
                ides[name] = adapter.set_title(task_id, description)
        except core.AdapterError as exc:
            ides[name] = {"task_id": task_id, "found": False, "renamed": [], "error": str(exc)}
            red = 1
    report = core.merge_report("apply" if apply else "dry-run", ides)
    return report, red


def main(argv=None) -> int:
    parser = argparse.ArgumentParser(
        description="Unified IDE task-list grooming (zcode, agy). Dry-run by default."
    )
    parser.add_argument("--ide", default="zcode,agy",
                        help="comma-separated adapters to run (default: zcode,agy)")
    parser.add_argument("--apply", action="store_true",
                        help="commit writes (default is dry-run)")
    parser.add_argument("--doctor", action="store_true",
                        help="health check: store reachability, schema, app gate, heartbeat receipt")
    parser.add_argument("--set-title", nargs=2, metavar=("TASK_ID", "TITLE"),
                        help="set one task's title per selected IDE; stamps it with the "
                             "task's own last-activity mm-dd date (a supplied stamp is normalized)")
    parser.add_argument("--zcode-db", metavar="PATH", default=None,
                        help="override the ZCode task index DB (probes use copies)")
    parser.add_argument("--agy-root", metavar="PATH", default=None,
                        help="override the Antigravity root dir; its electron store is "
                             "<root>/app_storage.json (probes use fixture roots)")
    parser.add_argument("--hours", type=float, default=24.0,
                        help="sweep window in hours of last activity (default 24)")
    parser.add_argument("--all", action="store_true",
                        help="sweep everything recent rather than the default candidate set")
    parser.add_argument("--pin", dest="pin", action="store_true", default=True,
                        help="ZCode: pin tasks active within --pin-hours (default)")
    parser.add_argument("--no-pin", dest="pin", action="store_false",
                        help="skip pin writes (does not disable --unpin-days)")
    parser.add_argument("--pin-hours", type=float, default=24.0,
                        help="ZCode pin window in hours of last activity (default 24)")
    parser.add_argument("--unpin-days", type=float, default=None, metavar="N",
                        help="ZCode: also unpin tasks inactive for N days (default: never)")
    parser.add_argument("--include-cron", action="store_true",
                        help="ZCode: also touch automation-owned tasks (default: skip)")
    parser.add_argument("--group", metavar="NAME", default=None,
                        help="ZCode: add pinned-window tasks to this named task group")
    parser.add_argument("--auto-pin", action="store_true",
                        help="Agy: opt into derived pin writes including app_storage.json "
                             "for --set-title targets (gated, backed up, atomic)")
    args = parser.parse_args(argv)

    args.ide = [s.strip() for s in args.ide.split(",") if s.strip()]
    unknown = [s for s in args.ide if s not in ADAPTERS]
    if unknown:
        parser.error(f"unknown --ide value(s): {unknown} (choose from {list(ADAPTERS)})")
    if not args.ide:
        parser.error("--ide resolved to an empty list")
    if args.group and args.set_title:
        parser.error("--group applies to sweeps only; not valid with --set-title")

    if args.doctor:
        report, red = run_doctor(args)
    elif args.set_title:
        report, red = run_set_title(args)
    else:
        report, red = run_sweep(args, apply=args.apply)

    json.dump(report, sys.stdout, ensure_ascii=False, indent=2)
    print()
    return 3 if red else 0


if __name__ == "__main__":
    sys.exit(main())
---
name: task-sync
description: >-
  Unified IDE task-list grooming for XYZ Forge: one central core with per-IDE adapters
  (ZCode, Antigravity) that date-stamp task titles with the task's own last-activity
  mm-dd, write last-action descriptions, and manage pins under one safety contract.
  Use when asked to groom/sync IDE task lists, set up the 15-minute heartbeat, install
  task-sync via Skills Army HQ, or run the health doctor.
when_to_use: The operator wants ZCode and/or Antigravity task titles date-stamped or
  re-summarized, tasks pinned, the heartbeat installed or repointed, or the doctor run.
license: Same as this repository.
metadata:
  repo: XYZ-forge
  tier: 3-weekly
---

# task-sync — unified IDE task-list grooming (GH-896)

One core, thin per-IDE adapters, one CLI, one heartbeat. Canonical home:
`skills/3-weekly/task-sync/` (Skills Army HQ-deployable). Ports the relay-proven
behavior of `utils/zcode/task-stamp` (PR #893) and `utils/skills/agy-task-sync`
(PR #894); both originals are superseded after soak, not modified.

## Semantics (operator-locked)

- **Stamp = the task's own last-activity date** (mm-dd, local). A task worked on
  09-29 and swept on 09-30 keeps `09-29` until it is touched again; continuing a
  conversation moves the stamp on the next heartbeat. Never wall-clock, never the
  original start date.
- **Pins are adapter-declared.** ZCode derives pins from the activity window
  (`--pin-hours`, default 24) and writes them. Antigravity is mirror-app-owned:
  `pinned_conversations_order` in `app_storage.json` is ground truth, mirrored to
  `annotations/*.pbtxt`; `--auto-pin` opts into derived pin writes (gated, backed
  up, atomic).
- **Descriptions.** ZCode raw prompt titles become agent-written ≤8-word last-action
  summaries (via `needs_summary`). Antigravity previews are extracted directly from
  session transcripts (`[Tool]`/`[Response]`/`[User]`).

## Safety contract (core-enforced)

- Dry-run by default; `--apply` commits.
- Schema-validate before any write; abort with a named, clear message on drift.
- Write only on change — re-runs are no-ops.
- **A failed or empty-authoritative read never triggers a destructive write.**
  An unreadable `app_storage.json` aborts the whole Antigravity sweep (the
  superseded original stripped every annotation pin on this path — witnessed;
  the red control lives in the GH-896 TESTS-RESULTS receipt).
- Antigravity writes are gated while the app is running (fail closed: an
  undetectable app state counts as running). The Electron store is backed up
  (`.bak-<ts>`) and replaced via temp-file rename.
- One IDE's store failure never blocks the other; each IDE section carries its
  own error, and any adapter error exits nonzero (3).

## Commands

```bash
S=skills/3-weekly/task-sync/scripts/task_sync.py

python3 $S --doctor              # health: stores, schema, app gate, heartbeat receipt
python3 $S                       # dry-run both IDEs (merged JSON report)
python3 $S --apply               # the heartbeat invocation
python3 $S --ide zcode --apply   # one IDE only
python3 $S --set-title <id> "Reviewed LTVera PR 648, flagged changelog"  # per-IDE; not found is reported per IDE
python3 $S --set-title <agy-conv-id> "Ran validate.sh checks" --ide agy --apply --auto-pin
```

Probe/CI-safe store overrides (never point these at live stores from probes):
`--zcode-db PATH` (ZCode task index copy), `--agy-root PATH` (Antigravity fixture
root; its electron store is `<root>/app_storage.json`).

Doctor exit codes: `0` all green · `3` any red (missing store, schema drift,
app running → Agy writes gated). `heartbeat: pending — no receipt yet` is a
non-red state (nothing has applied on this machine yet); the receipt lives at
`~/.cache/task-sync/last-run.json` (machine-local, written on `--apply`).

## The heartbeat (single scheduler)

One 15-minute ZCode automation runs `task_sync.py --apply --ide zcode,agy` in this
workspace; the daemon/launchd/in-session `/schedule` options of the superseded
originals are dropped. The installer SOP below creates or repoints it. The
automation's own task is automation-owned and skipped by the ZCode adapter — no
self-restamping loop.

## Install SOP (this skill is the installer)

1. **Doctor first:** `python3 $S --doctor` — all stores must be green or
   pending-receipt before installing.
2. **Vendor via Skills Army HQ** (canonical source = this repo's skills tree):
   `intake.py add task-sync --source <forge>/skills/3-weekly/task-sync` (preview,
   then `--apply`) into the Deployed Skills collection, then `sync.py` to this
   device's app targets (ZCode `~/.zcode/skills/task-sync`, Antigravity
   `~/.gemini/antigravity/skills/task-sync`, `~/.gemini/antigravity-cli/skills/`
   when present). Verify each symlink resolves into the collection and the app's
   skill list picks it up.
3. **Heartbeat:** create or repoint the 15-minute ZCode automation (CronCreate,
   `intervalUnit: minute`, `interval: 15`) with the prompt: run
   `python3 <collection>/task-sync/scripts/task_sync.py --apply --ide zcode,agy`,
   then for each `needs_summary` entry in the ZCode section read the task's
   `searchable_text`, craft a ≤8-word last-action summary, apply
   `--set-title <task_id> "<summary>"`, touch nothing else, and report one line
   (`task-sync: renamed=N pinned=M summarized=K`).
4. **Doctor again:** green (or Agy red only because the app is open — that gate
   clears on the next tick after the app closes).
5. **Retirement (post-soak):** after a soak period, retire
   `utils/zcode/task-stamp/` and `utils/skills/agy-task-sync/` via a follow-up PR,
   and close PRs #893/#894 as superseded by this skill.

## Caveats

- **App-overwrites-active-titles:** a running IDE can rewrite its own active
  session's title; the next heartbeat re-applies the stamp. Completed tasks stick.
- **UI refresh:** stores are the source of truth; an app may not re-render its
  task list until it refetches (switch workspace or restart).
- **Agy write gating:** while Antigravity runs, its adapter refuses writes
  (heartbeat reports the error and continues with ZCode); the gate clears once
  the app closes.
- **Discovery:** the skill is HQ-deployed by symlink; if it stops appearing,
  check the collection link (`ls -l ~/.zcode/skills/task-sync`).

## Verification note (GH-831)

No new `test/` suites — this skill is verified by the functional probe battery,
doctor fault injection, the A3 red control against the superseded original, one
full `validate.sh` on the final commit, and the TESTS-RESULTS receipt with
provenance (see `TESTS-RESULTS/2026-09-30+GH-896/`).

exec
/bin/zsh -lc 'nl -ba skills/3-weekly/task-sync/scripts/core.py
nl -ba skills/3-weekly/task-sync/scripts/task_sync.py
nl -ba skills/3-weekly/task-sync/SKILL.md
cat GUIDING-PRINCIPLES.md' in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-42794-90iuouwj
 succeeded in 0ms:
     1	"""task-sync core — shared semantics and the adapter safety contract.
     2	
     3	Owns the stamp logic, the report schema, and the adapter error contract.
     4	Adapters own only their app's store I/O; they must raise AdapterError
     5	(with a clear, named message) instead of proceeding on a failed or empty
     6	authoritative read — a failed read never triggers a destructive write.
     7	
     8	Stamp semantics (operator-locked, GH-896): the MM-DD prefix is the task's
     9	own last-activity date, never wall-clock at sweep time. Adapters convert
    10	their store's native timestamp to a local datetime and call stamp_of().
    11	"""
    12	
    13	from __future__ import annotations
    14	
    15	import re
    16	from datetime import datetime, timezone
    17	
    18	# A leading U.S. mm-dd (or legacy mm/dd) stamp followed by a description.
    19	STAMP_RE = re.compile(r"^(\d{2}-\d{2})\s+(\S.*)$", re.DOTALL)
    20	# Legacy slash form seen in Antigravity titles, stripped before re-stamping.
    21	SLASH_STAMP_RE = re.compile(r"^\d{2}/\d{2}(?=\s|$)\s*")
    22	# A bare date is not a description ("09-29" alone must not restack to "09-29 09-29").
    23	BARE_DATE_RE = re.compile(r"^\d{2}[-/]\d{2}$")
    24	MAX_BASE = 72  # keep the descriptive part readable in a task list
    25	
    26	
    27	class AdapterError(Exception):
    28	    """An adapter refused to proceed — the store failed a safety check."""
    29	
    30	
    31	def local_stamp(dt: datetime) -> str:
    32	    """The mm-dd stamp for an aware-or-naive local datetime."""
    33	    return dt.strftime("%m-%d")
    34	
    35	
    36	def utc_text_to_local_dt(text: str) -> datetime | None:
    37	    """Parse an app's UTC timestamp text into local time.
    38	
    39	    Handles the formats actually seen in Antigravity's
    40	    ``conversation_summaries.last_modified_time`` — ISO-8601 with
    41	    fractional seconds and an explicit offset
    42	    (``2026-06-19 01:31:58.720731+00:00``). The fallback chain also
    43	    accepts offset-naive ``%Y-%m-%d %H:%M:%S`` text and — deliberately,
    44	    matching the superseded original — treats NAIVE text as already
    45	    local. Returns None for absent, non-string, or unparseable input —
    46	    callers decide whether that skips the row or aborts."""
    47	    if not text or not isinstance(text, str):
    48	        return None
    49	    cleaned = text.strip()
    50	    try:
    51	        return datetime.fromisoformat(cleaned).astimezone()
    52	    except ValueError:
    53	        pass
    54	    for fmt in (
    55	        "%Y-%m-%d %H:%M:%S.%f%z",
    56	        "%Y-%m-%d %H:%M:%S%z",
    57	        "%Y-%m-%d %H:%M:%S.%f",
    58	        "%Y-%m-%d %H:%M:%S",
    59	    ):
    60	        try:
    61	            parsed = datetime.strptime(cleaned, fmt)
    62	        except ValueError:
    63	            continue
    64	        if parsed.tzinfo is None:
    65	            parsed = parsed.replace(tzinfo=timezone.utc)
    66	        return parsed.astimezone()
    67	    return None
    68	
    69	
    70	def ms_to_local_dt(ms: int) -> datetime:
    71	    return datetime.fromtimestamp(ms / 1000)
    72	
    73	
    74	def clean_base(raw: str, *, slash_stamps: bool = False) -> str:
    75	    """Strip any existing stamp and collapse whitespace so re-stamping
    76	    never stacks prefixes; cap length so long prompt-derived titles stay
    77	    scannable. A bare date is not a description.
    78	
    79	    slash_stamps=True also strips the legacy mm/dd form (Antigravity)."""
    80	    base = raw.strip()
    81	    if slash_stamps:
    82	        base = SLASH_STAMP_RE.sub("", base)
    83	    match = STAMP_RE.match(base)
    84	    base = match.group(2) if match else base
    85	    base = re.sub(r"\s+", " ", base).strip()
    86	    if BARE_DATE_RE.fullmatch(base):
    87	        return ""
    88	    if len(base) > MAX_BASE:
    89	        base = base[: MAX_BASE - 1].rstrip() + "…"
    90	    return base
    91	
    92	
    93	def new_ide_report() -> dict:
    94	    """The per-IDE report shape every adapter returns."""
    95	    return {
    96	        "swept": 0,
    97	        "renamed": [],
    98	        "pinned": [],
    99	        "unpinned": [],
   100	        "needs_summary": [],
   101	        "skipped": 0,
   102	        "error": None,
   103	    }
   104	
   105	
   106	def merge_report(mode: str, ide_reports: dict) -> dict:
   107	    """The merged stdout contract: mode + one section per IDE. The
   108	    heartbeat and installer consume this JSON; per-IDE lists stay
   109	    machine-addressable."""
   110	    return {"mode": mode, "ides": ide_reports}
   111	
   112	
   113	def receipt_path() -> str:
   114	    import os
   115	
   116	    return os.path.expanduser("~/.cache/task-sync/last-run.json")
   117	
   118	
   119	def write_receipt(mode: str, ide_reports: dict) -> str:
   120	    """Heartbeat receipt — written on apply runs only. Doctor reads it;
   121	    a missing receipt is a distinct non-red 'pending' state."""
   122	    import json
   123	    import os
   124	
   125	    path = receipt_path()
   126	    os.makedirs(os.path.dirname(path), exist_ok=True)
   127	    with open(path, "w", encoding="utf-8") as f:
   128	        json.dump(
   129	            {
   130	                "at": datetime.now().isoformat(timespec="seconds"),
   131	                "mode": mode,
   132	                "ides": {
   133	                    name: {
   134	                        "swept": rep.get("swept", 0),
   135	                        "renamed": len(rep.get("renamed", [])),
   136	                        "error": rep.get("error"),
   137	                    }
   138	                    for name, rep in ide_reports.items()
   139	                },
   140	            },
   141	            f,
   142	            indent=2,
   143	        )
   144	        f.write("\n")
   145	    return path
     1	#!/usr/bin/env python3
     2	"""task_sync — unified IDE task-list grooming (GH-896).
     3	
     4	One CLI over per-IDE adapters (zcode, agy). Default is dry-run; pass
     5	``--apply`` to commit. Emits one merged JSON report; per-IDE sections
     6	stay machine-addressable (the heartbeat consumes ``needs_summary``).
     7	
     8	    task_sync.py --doctor
     9	    task_sync.py                       # dry-run, both IDEs
    10	    task_sync.py --apply               # the heartbeat invocation
    11	    task_sync.py --set-title <id> "Short description of last action"
    12	    task_sync.py --zcode-db /tmp/copy.sqlite --agy-root /tmp/agy-fixture ...
    13	
    14	Safety contract (core-enforced, GH-896): schema-validate before write
    15	with a clear abort; dry-run by default; write only on change; a failed
    16	or empty-authoritative read never triggers a destructive write;
    17	Antigravity writes are gated on the app being closed; the Electron store
    18	is backed up and replaced atomically. One IDE's store failure never
    19	blocks the other — each section reports its own error.
    20	"""
    21	
    22	from __future__ import annotations
    23	
    24	import argparse
    25	import importlib
    26	import json
    27	import os
    28	import sys
    29	from datetime import datetime, timedelta
    30	
    31	sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
    32	
    33	import core  # noqa: E402
    34	
    35	ADAPTERS = ("zcode", "agy")
    36	
    37	SWEEP_KNOBS = ("hours", "all", "pin_hours", "no_pin", "unpin_days", "include_cron", "group")
    38	
    39	
    40	def _build_adapter(name: str, args, apply: bool):
    41	    module_name = "antigravity" if name == "agy" else name
    42	    module = importlib.import_module(f"adapters.{module_name}")
    43	    if name == "zcode":
    44	        return module.ZcodeAdapter(db_path=args.zcode_db, apply=apply)
    45	    if name == "agy":
    46	        return module.AntigravityAdapter(
    47	            agy_root=args.agy_root,
    48	            apply=apply,
    49	        )
    50	    raise SystemExit(f"task-sync: unknown adapter {name!r}")
    51	
    52	
    53	def _sweep_kwargs(args) -> dict:
    54	    return {
    55	        "hours": args.hours,
    56	        "include_all": args.all,
    57	        "pin": args.pin,
    58	        "pin_hours": args.pin_hours,
    59	        "unpin_days": args.unpin_days,
    60	        "include_cron": args.include_cron,
    61	        "group": args.group,
    62	    }
    63	
    64	
    65	def run_doctor(args) -> tuple[dict, int]:
    66	    ides = {}
    67	    red = 0
    68	    receipt = core.receipt_path()
    69	    receipt_state = "absent"
    70	    receipt_red = None
    71	    if os.path.exists(receipt):
    72	        try:
    73	            with open(receipt, "r", encoding="utf-8") as f:
    74	                at = json.load(f).get("at", "unreadable")
    75	            receipt_state = at
    76	            if at == "unreadable":
    77	                receipt_red = f"heartbeat receipt unreadable at {receipt}"
    78	            else:
    79	                age = datetime.now() - datetime.fromisoformat(at)
    80	                if age > timedelta(hours=2):
    81	                    receipt_red = (
    82	                        f"heartbeat receipt stale: last apply {at} "
    83	                        f"({age.total_seconds() / 3600:.1f}h ago) — heartbeat may be dead"
    84	                    )
    85	        except (OSError, ValueError):
    86	            receipt_state = "unreadable"
    87	            receipt_red = f"heartbeat receipt unreadable at {receipt}"
    88	    for name in args.ide:
    89	        adapter = _build_adapter(name, args, apply=False)
    90	        try:
    91	            ides[name] = adapter.doctor()
    92	        except core.AdapterError as exc:
    93	            ides[name] = {"ok": False, "reds": [str(exc)]}
    94	        if not ides[name].get("ok"):
    95	            red = 1
    96	    report = {
    97	        "mode": "doctor",
    98	        "heartbeat": {
    99	            "receipt": receipt,
   100	            "state": receipt_state,
   101	            "note": "pending — no receipt yet" if receipt_state == "absent" else receipt_state,
   102	        },
   103	        "ides": ides,
   104	    }
   105	    if receipt_red:
   106	        report["heartbeat"]["red"] = receipt_red
   107	        red = 1
   108	    return report, red
   109	
   110	
   111	def run_sweep(args, apply: bool) -> tuple[dict, int]:
   112	    ides = {}
   113	    red = 0
   114	    for name in args.ide:
   115	        adapter = _build_adapter(name, args, apply=apply)
   116	        try:
   117	            ides[name] = adapter.sweep(**_sweep_kwargs(args))
   118	        except core.AdapterError as exc:
   119	            ides[name] = core.new_ide_report()
   120	            ides[name]["error"] = str(exc)
   121	            red = 1
   122	    report = core.merge_report("apply" if apply else "dry-run", ides)
   123	    if apply and red == 0:
   124	        report["receipt"] = core.write_receipt(report["mode"], ides)
   125	    return report, red
   126	
   127	
   128	def run_set_title(args) -> tuple[dict, int]:
   129	    task_id, description = args.set_title
   130	    ides = {}
   131	    red = 0
   132	    apply = args.apply
   133	    for name in args.ide:
   134	        adapter = _build_adapter(name, args, apply=apply)
   135	        try:
   136	            if name == "agy":
   137	                ides[name] = adapter.set_title(task_id, description, auto_pin=args.auto_pin)
   138	            else:
   139	                ides[name] = adapter.set_title(task_id, description)
   140	        except core.AdapterError as exc:
   141	            ides[name] = {"task_id": task_id, "found": False, "renamed": [], "error": str(exc)}
   142	            red = 1
   143	    report = core.merge_report("apply" if apply else "dry-run", ides)
   144	    return report, red
   145	
   146	
   147	def main(argv=None) -> int:
   148	    parser = argparse.ArgumentParser(
   149	        description="Unified IDE task-list grooming (zcode, agy). Dry-run by default."
   150	    )
   151	    parser.add_argument("--ide", default="zcode,agy",
   152	                        help="comma-separated adapters to run (default: zcode,agy)")
   153	    parser.add_argument("--apply", action="store_true",
   154	                        help="commit writes (default is dry-run)")
   155	    parser.add_argument("--doctor", action="store_true",
   156	                        help="health check: store reachability, schema, app gate, heartbeat receipt")
   157	    parser.add_argument("--set-title", nargs=2, metavar=("TASK_ID", "TITLE"),
   158	                        help="set one task's title per selected IDE; stamps it with the "
   159	                             "task's own last-activity mm-dd date (a supplied stamp is normalized)")
   160	    parser.add_argument("--zcode-db", metavar="PATH", default=None,
   161	                        help="override the ZCode task index DB (probes use copies)")
   162	    parser.add_argument("--agy-root", metavar="PATH", default=None,
   163	                        help="override the Antigravity root dir; its electron store is "
   164	                             "<root>/app_storage.json (probes use fixture roots)")
   165	    parser.add_argument("--hours", type=float, default=24.0,
   166	                        help="sweep window in hours of last activity (default 24)")
   167	    parser.add_argument("--all", action="store_true",
   168	                        help="sweep everything recent rather than the default candidate set")
   169	    parser.add_argument("--pin", dest="pin", action="store_true", default=True,
   170	                        help="ZCode: pin tasks active within --pin-hours (default)")
   171	    parser.add_argument("--no-pin", dest="pin", action="store_false",
   172	                        help="skip pin writes (does not disable --unpin-days)")
   173	    parser.add_argument("--pin-hours", type=float, default=24.0,
   174	                        help="ZCode pin window in hours of last activity (default 24)")
   175	    parser.add_argument("--unpin-days", type=float, default=None, metavar="N",
   176	                        help="ZCode: also unpin tasks inactive for N days (default: never)")
   177	    parser.add_argument("--include-cron", action="store_true",
   178	                        help="ZCode: also touch automation-owned tasks (default: skip)")
   179	    parser.add_argument("--group", metavar="NAME", default=None,
   180	                        help="ZCode: add pinned-window tasks to this named task group")
   181	    parser.add_argument("--auto-pin", action="store_true",
   182	                        help="Agy: opt into derived pin writes including app_storage.json "
   183	                             "for --set-title targets (gated, backed up, atomic)")
   184	    args = parser.parse_args(argv)
   185	
   186	    args.ide = [s.strip() for s in args.ide.split(",") if s.strip()]
   187	    unknown = [s for s in args.ide if s not in ADAPTERS]
   188	    if unknown:
   189	        parser.error(f"unknown --ide value(s): {unknown} (choose from {list(ADAPTERS)})")
   190	    if not args.ide:
   191	        parser.error("--ide resolved to an empty list")
   192	    if args.group and args.set_title:
   193	        parser.error("--group applies to sweeps only; not valid with --set-title")
   194	
   195	    if args.doctor:
   196	        report, red = run_doctor(args)
   197	    elif args.set_title:
   198	        report, red = run_set_title(args)
   199	    else:
   200	        report, red = run_sweep(args, apply=args.apply)
   201	
   202	    json.dump(report, sys.stdout, ensure_ascii=False, indent=2)
   203	    print()
   204	    return 3 if red else 0
   205	
   206	
   207	if __name__ == "__main__":
   208	    sys.exit(main())
     1	---
     2	name: task-sync
     3	description: >-
     4	  Unified IDE task-list grooming for XYZ Forge: one central core with per-IDE adapters
     5	  (ZCode, Antigravity) that date-stamp task titles with the task's own last-activity
     6	  mm-dd, write last-action descriptions, and manage pins under one safety contract.
     7	  Use when asked to groom/sync IDE task lists, set up the 15-minute heartbeat, install
     8	  task-sync via Skills Army HQ, or run the health doctor.
     9	when_to_use: The operator wants ZCode and/or Antigravity task titles date-stamped or
    10	  re-summarized, tasks pinned, the heartbeat installed or repointed, or the doctor run.
    11	license: Same as this repository.
    12	metadata:
    13	  repo: XYZ-forge
    14	  tier: 3-weekly
    15	---
    16	
    17	# task-sync — unified IDE task-list grooming (GH-896)
    18	
    19	One core, thin per-IDE adapters, one CLI, one heartbeat. Canonical home:
    20	`skills/3-weekly/task-sync/` (Skills Army HQ-deployable). Ports the relay-proven
    21	behavior of `utils/zcode/task-stamp` (PR #893) and `utils/skills/agy-task-sync`
    22	(PR #894); both originals are superseded after soak, not modified.
    23	
    24	## Semantics (operator-locked)
    25	
    26	- **Stamp = the task's own last-activity date** (mm-dd, local). A task worked on
    27	  09-29 and swept on 09-30 keeps `09-29` until it is touched again; continuing a
    28	  conversation moves the stamp on the next heartbeat. Never wall-clock, never the
    29	  original start date.
    30	- **Pins are adapter-declared.** ZCode derives pins from the activity window
    31	  (`--pin-hours`, default 24) and writes them. Antigravity is mirror-app-owned:
    32	  `pinned_conversations_order` in `app_storage.json` is ground truth, mirrored to
    33	  `annotations/*.pbtxt`; `--auto-pin` opts into derived pin writes (gated, backed
    34	  up, atomic).
    35	- **Descriptions.** ZCode raw prompt titles become agent-written ≤8-word last-action
    36	  summaries (via `needs_summary`). Antigravity previews are extracted directly from
    37	  session transcripts (`[Tool]`/`[Response]`/`[User]`).
    38	
    39	## Safety contract (core-enforced)
    40	
    41	- Dry-run by default; `--apply` commits.
    42	- Schema-validate before any write; abort with a named, clear message on drift.
    43	- Write only on change — re-runs are no-ops.
    44	- **A failed or empty-authoritative read never triggers a destructive write.**
    45	  An unreadable `app_storage.json` aborts the whole Antigravity sweep (the
    46	  superseded original stripped every annotation pin on this path — witnessed;
    47	  the red control lives in the GH-896 TESTS-RESULTS receipt).
    48	- Antigravity writes are gated while the app is running (fail closed: an
    49	  undetectable app state counts as running). The Electron store is backed up
    50	  (`.bak-<ts>`) and replaced via temp-file rename.
    51	- One IDE's store failure never blocks the other; each IDE section carries its
    52	  own error, and any adapter error exits nonzero (3).
    53	
    54	## Commands
    55	
    56	```bash
    57	S=skills/3-weekly/task-sync/scripts/task_sync.py
    58	
    59	python3 $S --doctor              # health: stores, schema, app gate, heartbeat receipt
    60	python3 $S                       # dry-run both IDEs (merged JSON report)
    61	python3 $S --apply               # the heartbeat invocation
    62	python3 $S --ide zcode --apply   # one IDE only
    63	python3 $S --set-title <id> "Reviewed LTVera PR 648, flagged changelog"  # per-IDE; not found is reported per IDE
    64	python3 $S --set-title <agy-conv-id> "Ran validate.sh checks" --ide agy --apply --auto-pin
    65	```
    66	
    67	Probe/CI-safe store overrides (never point these at live stores from probes):
    68	`--zcode-db PATH` (ZCode task index copy), `--agy-root PATH` (Antigravity fixture
    69	root; its electron store is `<root>/app_storage.json`).
    70	
    71	Doctor exit codes: `0` all green · `3` any red (missing store, schema drift,
    72	app running → Agy writes gated). `heartbeat: pending — no receipt yet` is a
    73	non-red state (nothing has applied on this machine yet); the receipt lives at
    74	`~/.cache/task-sync/last-run.json` (machine-local, written on `--apply`).
    75	
    76	## The heartbeat (single scheduler)
    77	
    78	One 15-minute ZCode automation runs `task_sync.py --apply --ide zcode,agy` in this
    79	workspace; the daemon/launchd/in-session `/schedule` options of the superseded
    80	originals are dropped. The installer SOP below creates or repoints it. The
    81	automation's own task is automation-owned and skipped by the ZCode adapter — no
    82	self-restamping loop.
    83	
    84	## Install SOP (this skill is the installer)
    85	
    86	1. **Doctor first:** `python3 $S --doctor` — all stores must be green or
    87	   pending-receipt before installing.
    88	2. **Vendor via Skills Army HQ** (canonical source = this repo's skills tree):
    89	   `intake.py add task-sync --source <forge>/skills/3-weekly/task-sync` (preview,
    90	   then `--apply`) into the Deployed Skills collection, then `sync.py` to this
    91	   device's app targets (ZCode `~/.zcode/skills/task-sync`, Antigravity
    92	   `~/.gemini/antigravity/skills/task-sync`, `~/.gemini/antigravity-cli/skills/`
    93	   when present). Verify each symlink resolves into the collection and the app's
    94	   skill list picks it up.
    95	3. **Heartbeat:** create or repoint the 15-minute ZCode automation (CronCreate,
    96	   `intervalUnit: minute`, `interval: 15`) with the prompt: run
    97	   `python3 <collection>/task-sync/scripts/task_sync.py --apply --ide zcode,agy`,
    98	   then for each `needs_summary` entry in the ZCode section read the task's
    99	   `searchable_text`, craft a ≤8-word last-action summary, apply
   100	   `--set-title <task_id> "<summary>"`, touch nothing else, and report one line
   101	   (`task-sync: renamed=N pinned=M summarized=K`).
   102	4. **Doctor again:** green (or Agy red only because the app is open — that gate
   103	   clears on the next tick after the app closes).
   104	5. **Retirement (post-soak):** after a soak period, retire
   105	   `utils/zcode/task-stamp/` and `utils/skills/agy-task-sync/` via a follow-up PR,
   106	   and close PRs #893/#894 as superseded by this skill.
   107	
   108	## Caveats
   109	
   110	- **App-overwrites-active-titles:** a running IDE can rewrite its own active
   111	  session's title; the next heartbeat re-applies the stamp. Completed tasks stick.
   112	- **UI refresh:** stores are the source of truth; an app may not re-render its
   113	  task list until it refetches (switch workspace or restart).
   114	- **Agy write gating:** while Antigravity runs, its adapter refuses writes
   115	  (heartbeat reports the error and continues with ZCode); the gate clears once
   116	  the app closes.
   117	- **Discovery:** the skill is HQ-deployed by symlink; if it stops appearing,
   118	  check the collection link (`ls -l ~/.zcode/skills/task-sync`).
   119	
   120	## Verification note (GH-831)
   121	
   122	No new `test/` suites — this skill is verified by the functional probe battery,
   123	doctor fault injection, the A3 red control against the superseded original, one
   124	full `validate.sh` on the final commit, and the TESTS-RESULTS receipt with
   125	provenance (see `TESTS-RESULTS/2026-09-30+GH-896/`).
# Guiding Principles

North star for **XYZ Forge**, the multi-agent coordination harness behind the `tick` event-log kernel and `relay-automation/` relay stack. When a choice is unclear, the option that keeps agents synchronized, contained, and verifiable — without leaking or destroying work — wins. AGENTS.md is the behavioral playbook; ROUTER.md is the entry-point map; this is the *why*.

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

XYZ Forge is a local-first operations system for humans directing agents across their repositories:
capture → rate → plan → preflight → execute → gate → land → record. Its `tick` kernel coordinates
local claims through an event log and exclusive locks; its relay and Marathon tooling drive bounded
build and review work. Containment controls reduce accidental writes but do not guarantee safety
outside their enforced boundaries; linked worktrees share Git state. The product prioritizes
coordination, recoverability and verifiable outcomes. The operator remains the decision authority.

XYZ is not enterprise application lifecycle management or an agent marketplace. It currently
assumes specified work rather than providing a structured spec/PRD-generation pipeline of its own;
that capability gap is not a permanent prohibition on future product work. PDDA’s governance-layer
anti-scope does not prohibit XYZ’s coordination and execution features.

## The quality bar

Every agent turn is a signal. A turn is high-quality only when it is all four:

- **Attested** — carries its receipts: source, evidence, confidence. Never a bare verdict. A relay review names which claim is wrong and why; a build turn names the seam it touched.
- **Relevant** — ranked, not dumped. Volume is not value. One real bug beats five nits and a phantom.
- **Fresh** — current, not stale. A turn that reads a stale `STATE.md` or misses an epoch fence is wrong by construction.
- **Structured** — one shape, clean for the operator to read and for downstream agents to feed on.

Fail a pillar, and the turn, feature, or relay review isn't done.

## How it's built

1. **Coordination is local-transport only.** `.tick/events/` is the shared bus; claims resolve from there, not from a remote. No per-event push/fetch; no remote dependency at runtime. A coordination primitive that reaches out is a coordination primitive that can fail or leak.

2. **One canonical event log for tick coordination.** `.tick/events/` records coordination events; `.tick/STATE.md` is a derived view. Coordination verbs read and fold the events and append changes through the event API. Other subsystems retain their own documented sources of truth, including the RELEASES roadmap ledger. Do not create competing copies of canonical state.

3. **Containment is non-negotiable.** A headless turn must not: self-commit mid-turn, orphan a peer's concurrent commit, or write outside its allowlist. The allowlist, worktree isolation, and commit-bypass guard exist because a driven agent will do all three if unconstrained — not hypothetically, but as documented live incidents (GH-13, GH-14, GH-17). New relay paths must clear the containment bar before they ship.

4. **Skill-first; never improvise the harness.** The `relay-xyz` skill owns the locator, sandbox rules, exit codes, and the safety boundary. A session that improvises those from `ls relay-automation/` silently skips the skill's safety layer. In sessions that install and invoke the `PreToolUse` hook, `relay-automation/hooks/relay-xyz-guard.sh` checks supported driver invocations for the skill’s setup evidence; this is not a guarantee that every runtime invokes that hook. Add capabilities to the skill; do not work around it.

5. **Adversarially proven before commercially viable.** The harness exists to run against real codebases. Features in the adversarial-hardening track (epoch fencing, chaos suite, cross-repo E2E) must be verified to survive deliberate abuse — stale writers, zombie claims, macOS case-sensitivity, concurrent peer commits — not just the happy path. A feature that clears the happy path and skips chaos is half-done.

6. **Build durable, not band-aid.** Durable means it removes the root cause and the next planned change builds on it — not a patch torn out when the obvious next feature lands. A band-aid is wasted work unless a demo strictly needs one, and a demo band-aid is tagged for removal so it isn't silently inherited.

7. **Least code that clears the bar.** The `tick` coordination kernel uses Node's standard library. The repository also ships `package.json` and `package-lock.json` for Acorn-based source analysis. Prefer reusing or extending what exists; the smallest change that stays correct, contained, and durable wins. Net-new code is a cost to justify. Deleting code counts as progress.

8. **Honest; the operator decides.** Surface what failed and why — never mask a stall as success or an escalation as a stall. A headless turn self-repairs within a bounded exit-code menu (`exit 3` stall, `exit 4` escalated-by-design, `exit 6` containment revert), then stops; it never loops forever or silently swallows an error. Destructive actions require explicit authorization.

9. **Docs support resumable work (PDDA).** ROUTER points to the governing contracts; the RELEASES DB owns this repository's roadmap ledger (queried via `python3 utils/py/releases_app.py roadmap list`). Linked PROJECT documents hold plans, decisions and handoff detail; CHANGELOG records dated outcomes. Resume execution using those documents together with the relevant runtime state and evidence. If current documentation contradicts the implementation, correct it or explicitly record the unresolved discrepancy.

10. **Done means verified.** "Done" is `validate.sh` green, the relevant PDDA checks passing, and any relay review returning `Approved` — not work that looks finished. An unverified success claim is itself a low-quality signal.

11. **Issue-first; every non-trivial change has a signal stream.** Any change beyond a 2–3 line fix opens a GitHub issue first, then gets a `GH-<number>` in-repo pointer doc, then lands. The issue is the machine-queryable signal stream; the `PROJECT/**` doc is the execution surface of record. Genuinely trivial edits (≤2–3 line fixes, typos, path repoints, doc-only one-liners) are exempt.

12. **Independent Verification (Separated Grading)** — The agent that produces a turn must not be the sole grader of its own quality. Verification must be performed by an independent deterministic check or a separate reviewing agent before the lock releases. Applies to: the relay's structural block validator (`bin/validate-relay-block` — Phase 1 of GH-21), consult-verify diversity (Phase 3), and any other post-generation quality gate.

13. **A green gate without a witnessed red control is not evidence.** Every new or materially changed decision gate needs a recorded demonstration that it fails for the right reason: a pre-fix replay, deliberate mutation, or controlled bad input. Witness it on an existing suite, or record it as a manual check under `TESTS-RESULTS/`. Never add a new test suite to do it (GH-831: no new tests). Do not mistake a check that validates the artifact it just generated (#351) or a parity check that compares a lane to itself (#348) for evidence; both shapes are structurally unable to falsify their claim.

## Applying this

Adding a feature or weighing a tradeoff, ask: *does this keep agents coordinated without collision, contained within their scope, and verifiable to an outside observer? And is "done" provable by running `validate.sh`?* If any answer is no, reconsider.

---

## Conventions

### Strict-mode policy (bash `set -e`)

Python is the default implementation for the twelve frozen Tier-A entry points. Existing Bash
bodies are compatibility fallbacks selected with `XYZ_PYTHON=0`; their strict-mode choices remain
subsystem-specific. Consult each existing script’s header and error handling before changing it.
New executables under `utils/` or `relay-automation/` follow AGENTS.md’s Python and exception rules.
This section does not authorize edits to frozen Bash twins.

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

- **Builder default is `codex`.** Marathon’s current implementation defaults to Codex; agy is
  another supported builder. Choosing Claude remains an explicit, cost-acknowledged operator
  decision under AGENTS.md. Actual billing depends on the selected tool’s authentication and
  account configuration; a default executable name does not establish a billing guarantee. The
  Python implementation is the default, with the existing Bash fallback available through
  `XYZ_PYTHON=0`.
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
3. **Coordination through the event log?** Tick coordination state uses `tick` verbs; other subsystems use their documented canonical writers. Competing state copies need explicit justification.
4. **Done verifiable?** Names runnable gates (`validate.sh`, specific tests, `utils/pdda/pdda.sh run`). None = low-quality signal.
5. **Drift reduced, not created?** No duplicated docs, no execution detail in the roadmap ledger or its generated dashboard, no reinventing a path the event-log contract already documents.
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
- The roadmap ledger would need execution detail to make the plan legible.

codex
(1) ANSWER

Yes: a thin, read-only Codex planner is minimal DRY reuse. Native tools own mutations; the adapter owns snapshot validation and proposals. Activity-based stamps and additive pinning are sound, but the proposal needs several precise contracts before implementation is ready.

This is a design review, not implementation approval. The inspected files contain the existing ZCode/Agy implementation. Graph tools were unavailable; I read the requested source directly. No files were changed or mutation-heavy tests run.

(2) FINDINGS

- **[Pass] Reuse the existing seam.** Adapter construction, sweep arguments, and merged reports already provide the required extension points (`skills/3-weekly/task-sync/scripts/task_sync.py:40`, `:53`, `:111`). Reuse `local_stamp` and `new_ide_report`; keep the default `zcode,agy` selection unchanged (`core.py:31`, `:93`; `task_sync.py:151`). No second scheduler, database reader, or generic adapter framework is needed.

- **[Blocker] Resolve “preserve base titles” versus `clean_base`.** That helper collapses whitespace and truncates descriptions beyond 72 characters (`core.py:74–90`). Calling it unconditionally violates literal base-title preservation and loses information that a later native rename cannot recover without the original title. Make truncation optional, preserving existing adapter defaults, or explicitly obtain agreement to normalization/truncation. Empty or date-only bases should be skipped without summary inference. **Falsifier:** a 100-character native title must retain its entire descriptive base after stamping.

- **[Blocker] Define snapshot eligibility and completeness without trusting `updatedAt` as activity.** Specify the exact native response shape, recognized sidebar states, timestamp units, freshness bound, and required activity coverage. Reject malformed/duplicate IDs, ambiguous section state, nonfinite timestamps, and implausible future values. Missing activity must never fall back to `updatedAt`, capture time, or thread creation time. A 200-row inventory is bounded: document that scope and handle pagination/truncation explicitly rather than claiming complete coverage. The activity contract requires the task’s own last activity (`SKILL.md:26–29`; `core.py:8–10`). **Falsifiers:** remove one eligible activity entry; supply milliseconds as seconds; provide a truncated inventory; mutate only `updatedAt`. None may produce unsafe or newly dated proposals.

- **[Blocker] Make re-reading conditional, not ceremonial.** Each proposal should include the observed title, section/pin state, and activity. Before each native mutation, recheck exclusion, local host, Codex kind, grouping, and the relevant observed values; skip or replan on change. Never move an already pinned thread merely to reaffirm its pin. This implements the existing “write only on change” contract (`SKILL.md:43`). **Falsifier:** between planning and application, manually rename, regroup, or advance a conversation; the old plan must not overwrite that new state. Replanning verified results must emit no changes.

- **[Should] Reject unsupported modes before any selected adapter writes.** Validate Codex `--apply`, missing snapshot/exclusion, `--unpin-days`, and `--group` at CLI preflight. Otherwise a mixed `--ide zcode,codex --apply` can write ZCode before reaching Codex (`task_sync.py:111–124`). Also explicitly implement or reject Codex `--set-title`; its current dispatch assumes every non-Agy adapter supports it (`:128–139`). Constructors currently sit outside the `AdapterError` handlers (`:115–118`), so snapshot validation there would escape the structured error contract. **Falsifier:** an invalid mixed invocation performs zero writes and returns a clear error without a traceback.

- **[Should] Separate Codex planning health from existing apply receipts.** The current doctor measures a receipt written only by CLI apply runs (`core.py:119`; `task_sync.py:65–107`). A successful native Codex heartbeat therefore cannot establish health through that receipt. Document snapshot/tool readiness separately; do not label planned changes as applied or borrow another adapter’s receipt as Codex success.

- **[Pass] The heartbeat scope is appropriate.** Extend the existing scheduler where its execution context has the required native tools; otherwise fail closed. Require its actual thread ID, preserve custom sections and existing pins, stay quiet on unchanged runs, and verify mutations through native state. Update the current ZCode-specific installation instructions accordingly (`SKILL.md:76–101`). Native title/pin changes are **Easy** to reverse when previous titles are retained.

- **[Should] Disclose PR #900 dependency.** Identify the dependent base and prerequisite in the PR description; distinguish inherited GH-896 changes from this extension. Merge readiness remains conditional on the prerequisite landing.

(3) RECOMMENDATION

Proceed with the thin adapter after resolving title preservation, bounded snapshot coverage, and conditional native application; verify with scoped manual falsifiers and existing checks, without adding suites, gates, or a daemon.
tokens used
45,824
(1) ANSWER

Yes: a thin, read-only Codex planner is minimal DRY reuse. Native tools own mutations; the adapter owns snapshot validation and proposals. Activity-based stamps and additive pinning are sound, but the proposal needs several precise contracts before implementation is ready.

This is a design review, not implementation approval. The inspected files contain the existing ZCode/Agy implementation. Graph tools were unavailable; I read the requested source directly. No files were changed or mutation-heavy tests run.

(2) FINDINGS

- **[Pass] Reuse the existing seam.** Adapter construction, sweep arguments, and merged reports already provide the required extension points (`skills/3-weekly/task-sync/scripts/task_sync.py:40`, `:53`, `:111`). Reuse `local_stamp` and `new_ide_report`; keep the default `zcode,agy` selection unchanged (`core.py:31`, `:93`; `task_sync.py:151`). No second scheduler, database reader, or generic adapter framework is needed.

- **[Blocker] Resolve “preserve base titles” versus `clean_base`.** That helper collapses whitespace and truncates descriptions beyond 72 characters (`core.py:74–90`). Calling it unconditionally violates literal base-title preservation and loses information that a later native rename cannot recover without the original title. Make truncation optional, preserving existing adapter defaults, or explicitly obtain agreement to normalization/truncation. Empty or date-only bases should be skipped without summary inference. **Falsifier:** a 100-character native title must retain its entire descriptive base after stamping.

- **[Blocker] Define snapshot eligibility and completeness without trusting `updatedAt` as activity.** Specify the exact native response shape, recognized sidebar states, timestamp units, freshness bound, and required activity coverage. Reject malformed/duplicate IDs, ambiguous section state, nonfinite timestamps, and implausible future values. Missing activity must never fall back to `updatedAt`, capture time, or thread creation time. A 200-row inventory is bounded: document that scope and handle pagination/truncation explicitly rather than claiming complete coverage. The activity contract requires the task’s own last activity (`SKILL.md:26–29`; `core.py:8–10`). **Falsifiers:** remove one eligible activity entry; supply milliseconds as seconds; provide a truncated inventory; mutate only `updatedAt`. None may produce unsafe or newly dated proposals.

- **[Blocker] Make re-reading conditional, not ceremonial.** Each proposal should include the observed title, section/pin state, and activity. Before each native mutation, recheck exclusion, local host, Codex kind, grouping, and the relevant observed values; skip or replan on change. Never move an already pinned thread merely to reaffirm its pin. This implements the existing “write only on change” contract (`SKILL.md:43`). **Falsifier:** between planning and application, manually rename, regroup, or advance a conversation; the old plan must not overwrite that new state. Replanning verified results must emit no changes.

- **[Should] Reject unsupported modes before any selected adapter writes.** Validate Codex `--apply`, missing snapshot/exclusion, `--unpin-days`, and `--group` at CLI preflight. Otherwise a mixed `--ide zcode,codex --apply` can write ZCode before reaching Codex (`task_sync.py:111–124`). Also explicitly implement or reject Codex `--set-title`; its current dispatch assumes every non-Agy adapter supports it (`:128–139`). Constructors currently sit outside the `AdapterError` handlers (`:115–118`), so snapshot validation there would escape the structured error contract. **Falsifier:** an invalid mixed invocation performs zero writes and returns a clear error without a traceback.

- **[Should] Separate Codex planning health from existing apply receipts.** The current doctor measures a receipt written only by CLI apply runs (`core.py:119`; `task_sync.py:65–107`). A successful native Codex heartbeat therefore cannot establish health through that receipt. Document snapshot/tool readiness separately; do not label planned changes as applied or borrow another adapter’s receipt as Codex success.

- **[Pass] The heartbeat scope is appropriate.** Extend the existing scheduler where its execution context has the required native tools; otherwise fail closed. Require its actual thread ID, preserve custom sections and existing pins, stay quiet on unchanged runs, and verify mutations through native state. Update the current ZCode-specific installation instructions accordingly (`SKILL.md:76–101`). Native title/pin changes are **Easy** to reverse when previous titles are retained.

- **[Should] Disclose PR #900 dependency.** Identify the dependent base and prerequisite in the PR description; distinguish inherited GH-896 changes from this extension. Merge readiness remains conditional on the prerequisite landing.

(3) RECOMMENDATION

Proceed with the thin adapter after resolving title preservation, bounded snapshot coverage, and conditional native application; verify with scoped manual falsifiers and existing checks, without adding suites, gates, or a daemon.
