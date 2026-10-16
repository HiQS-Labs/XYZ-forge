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

## CI qualification policy

This section owns the normative explanation of selection, qualifying evidence and batch authority.
`utils/ci-route.sh` is the single executable owner of path→area→suite and hosted-gate decisions;
its registry is not copied here. AGENTS and SOP point here. Execution, resource width, receipt
validation and publication stay in their existing consumers; no second policy map or framework.

### Current boundaries

| Boundary | Selection and evidence |
|---|---|
| Local push / `validate.sh --auto` | Router tier1 uses the docs gate; tier2 uses its registered areas; unknown/empty/unverifiable ranges, unclaimed test edits, kernel/gate/containment/safety inputs use full. Local runs are self-checks. |
| Hosted development landing | Router `hosted_gate=small` uses the existing sequential Small list plus PDDA, Python and identity stages. Medium defaults to full; the configured, strictly proved skills-army-content@2 profile uses existing Small then area commands. Large remains full. |
| Main promotion | Full sequential hosted macOS for the **actual exact main commit**, regardless of range classification. A local PASS, ancestor receipt or equal tree does not qualify main. |
| PR feedback | Existing vendored-smoke, reconciliation-wiring, frozen-twin and vendored checks remain required by repository policy. A workflow declaration is not an actual run. |
| Ubuntu canary | Advisory portability signal on development push/manual dispatch; its job conclusion and skipped steps must be disclosed. Its inner PR Fast Gate predicate is unreachable under the current enclosing job predicate; do not count it as active PR selective coverage. |

Selection and worker width are separate axes. Local parallel defaults/resource controls remain in
[command rails](#command-rails); `ci-local.sh` stays sequential and writes local evidence. Hosted
qualification and promotion stay sequential, with one gate per local host and one reconciliation
writer. GH528's multi-width stress evidence remains outstanding; an increased width is not a
qualifying-coverage decision. Operator-retired suites remain off; their retained files/exemptions
are in gh306. No test retirement or new suite/case is authorized here.

### Router decision and consumer compatibility

The push/PR key/value output identifies `policy_version=ci-route@1` and the supported
`hosted_gate=small|full|skills-army-content@2` decision. The profile is a path candidate only;
its resolved setting and complete raw Git scope must also pass the wave consumer. The version
identifies the contract; the tested commit identifies its exact content. Local readers continue
using their existing route/tier fields. Unsupported/missing/duplicate/malformed metadata selects
full, including a new consumer paired with an older router. Commands are fixed arrays; classifier
text is never evaluated as shell. Main's explicit full command is unchanged. The bounded profile's
configuration and versioned two-phase receipt contract are specified below.

Machine-consumed text must follow its consumers, not its suffix. GH988/GH989 added/renamed a
skills-army package Markdown payload; the existing gh620 publisher pin failed in hosted run37723297290
([issue995](https://github.com/HiQS-Labs/XYZ-forge/issues/995)). The router now retains the existing
skills-army area for its text inputs before generic docs precedence, retaining the existing PDDA
documentation gate alongside area coverage. No suite is added. Existing
safety text/full rules remain. The bounded reverse audit additionally follows package sync into the canonical drift checker and
scans all registered suite sources for package-wide consumers. The existing area now includes the
already registered gh660 drift, path-integrity Markdown-link and gh788 interpreter-pattern suites;
its eight existing shell suites add coverage locally. Small and the full registry are unchanged;
Medium remains full unless the bounded configured qualification below is proved. This is a bounded consumer closure, not a claim that arbitrary shared-publisher,
all-device sync or probabilistic app behavior is fully mapped. Changes to publisher manifests and new consumers must
be audited before any narrower route is accepted; unknown/shared/global/safety scope keeps full.

### Evidence identity, invalidation and recovery

Existing wave receipts bind actual tested SHA, each landing SHA/PR, typed passing result, gate,
telemetry digest and list/count/identity evidence. Small's list is read at the **tested historical
commit**, not current HEAD. Preserve the literal historical Small-list reader and `wave-qualification@1`
semantics. An integrated snapshot may qualify older included landings with per-PR provenance; it does
not mean each historical tree ran or every descendant is qualified. Old valid receipts remain valid
for their recorded historical landing. Receipt publication commits are not new tested source heads.

No generic candidate/environment PASS cache exists. A frozen candidate must name exact base, ordered
member heads, interaction/dependency scope, candidate/tested/actual landed SHA, routing/suite revision,
lockfiles, OS/runtime/toolchain/dependency environment, review evidence and rollback boundary. Changes
to those inputs require fresh affected verification; tree equality alone cannot transfer history-
sensitive or exact-main qualification. Current receipts do not persist all those freeze/environment
fields and must not be presented as implementing such equivalence. The smallest future pilot should
avoid cross-candidate/cross-environment transfer entirely.

Failed, canceled, skipped, partial and advisory observations never become PASS. Preserve first
failures, retries and qualified outcomes. Existing strict replay checks complete top-level envelopes;
it does not inspect every nested `skip_lines` value, so disclose internal omissions separately.
Legacy provenance attribution is distinct from strict wave/premerge passing qualification.

Hosted reconciliation remains serialized with cancellation disabled. On a publication FF race,
existing GH740 recovery retains receipts first with bounded attempts, then recomputes transitions
once using only applicable retained evidence. No stale SQLite/generated-transition rebase, force
push, second writer or duplicate expensive replay. Unknown newcomers wait for their own qualification.
Reconciliation mutation rollback is not rollback of already merged code.

### Batch authority and rollout

Prepare dependencies/conflicts and combined review before freezing a candidate. Same-seam work may
be proposed as one bounded landing; a shared CHANGELOG/ledger alone is not semantic coupling.
Ordinary separate PRs keep per-PR checks, holds, drafts, review caps and the current ordered merge/
reconcile durability barrier. A batch issue or plaintext verdict is an audit record, not a checked
qualification receipt or permission to merge ahead of that barrier.

An actual fold needs explicit authority, compatible workflow/protection behavior, ordered member
provenance, fixed evidence and an atomic-group/dependency-suffix rollback plan. Required failure or
identity drift stops landing. The GH854 staging-only exception expired October7; PR880/PR936/PR939
are historical approved-fold precedents, not standing scheduling authority. No automatic retargeting,
exception revival, canceled required run, gate bypass or cap reset follows from grouping.

GH1072/GH1073 identify stale verdict-write and repaired-scope defects in unmerged PR1069, not this
base's wave receipts. Until resolved and independently verified, that proposed batch state cannot
be evidence authority. Its active owner must not be duplicated. A single-landing selection study can
proceed without depending on that unsafe state; broader automated batching cannot be called ready.

Medium defaults to full. Noel approved the bounded configurable profile below; any further
coverage reduction requires an audited non-core scope, deduplicated existing
Small+area+known-consumer coverage plus mandatory non-shell stages, reconstructible expected selection
at tested policy, retained attributed historical full failures, receipt-version coexistence and
separately reviewed policy/workflow/protection compatibility. A relevant missed failure, unknown
edge, incompatible identity, unexplained skip, blocking review or exhausted cap retains/restores full.
Existing fixtures/manual evidence come first; **every individual new CI assertion/parameter case
requires Noel's approval**, even inside an existing file. No second runner/registry or speculative
framework is needed. No new test is approved by this policy.

Measure queue delay, execution/wall time, runner-minutes, setup/suite/reconcile costs, failures,
retries and relevant failure catch rate separately. Match command, coverage, machine/configuration,
width and load for before/after comparisons; disclose differences and single-sample limits. A Small
PR smoke job is not a full macOS benchmark. Use naturally occurring comparable hosted jobs; no
manual trigger/rerun, claimed causal speedup or measured savings follows merely from consolidation.

## Document hygiene commands

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
- If the task is blocked by a failing test, unexpected error, or disputed requirement, invoke the `sanity-check` skill (`skills/1-hourly/sanity-check/SKILL.md`) to establish whether the obstacle must block the goal before spending hours debugging or repairing it.
- If the task is about **managing skills for the system** — adding a skill to the machine-wide collection, deploying/refreshing/removing it across the configured app targets (`targets.json`, machine-local), or asking what is deployed — the mechanism is the `skills-army-hq` skill (`skills/3-weekly/skills-army-hq/SKILL.md`). Forge authors its own skills in `skills/`, Skills Army HQ included; XYZ-skills-army-mini and the other standalone repos are published children (`push-downstream`, GH-955). Intake accepts any local folder. The durable collection lives wherever `XYZ_SKILLS_ROOT` points (machine-local, never committed; falls back to `~/git-pulse-sync/Deployed Skills`), and only `intake.py` / `sync.py` mutate it or the app symlinks. Never hand-copy a skill folder into an app's skills directory.
- Issue-first SOP: any change beyond a 2–3 line fix (and every project plan) opens a GitHub issue *first*, then gets a pointer doc named after the issue at `PROJECT/1-INBOX/GH-<number>-VERY-SHORT-DESC.md` — e.g. `GH-1234-SHOWME-COMMAND.md` — and that capture is parked in the roadmap ledger queue immediately via `releases roadmap add` (format + lifecycle owned by `PROJECT/PDDA.md` → "GitHub issue intake"), following the normal `1-INBOX` → `2-WORKING` flow. Genuinely trivial edits (≤2–3 line fixes, typos, path repoints, doc-only one-liners) are exempt and commit directly.


### Configurable bounded Medium qualification (GH1076)

The existing device configuration owner reads `ci.optimized` from `~/.xyz/device_config.json`, or
the existing `XYZ_DEVICE_CONFIG_PATH` override. `XYZ_CI_OPTIMIZED=0|1|false|true` has precedence over
the file; the library default is false. Invalid JSON/block/key/type/override fails to full, even if
another tier would mask the error. Inspect with `python3 utils/py/device_config.py --ci`.

The switch controls wave qualification, including local `wave_reconcile --qualify`; explicit full
commands, `ci-local.sh`, existing local pre-push tiers and exact-main macOS/full are unchanged.
The only optimized Medium profile is `skills-army-content@2`: exactly one merged development PR
whose actual tested snapshot is its landing, with verified source/base and only modified regular
tracked top-level package `.md`/`.txt` data. Agent manifests, requirements, adds/deletes/renames, mode
changes, symlinks, shared/code/mixed/unknown/high-risk inputs retain full. Name-only classification
is only a candidate; the wave verifies the complete raw Git diff.

The profile may also carry one verified local Small evidence pair. The actual PR head must be a
single-parent evidence-only commit after its frozen source. The complete source-to-carrier diff
must be exactly two new regular100644 sibling files, provenance.jsonl and validation.jsonl, in one
flat TESTS-RESULTS campaign. The canonical premerge reader's opt-in strict mode checks its supported
schema1.0 local record, exact PR/source/tree, original sequential Small/v1 telemetry, digest and
immutable carrier/landing blob equality. Extra records/fields/files, parallel proof, symlinks,
mode/rename/functional changes or unknown proof stay full. The legacy premerge reader is unchanged.
Only that verified pair is removed from classifier input; the complete remaining raw functional
scope keeps its original constraints. Selection, writing and replay use the same descriptor.

This is classification-only evidence under the existing operator-trusted local boundary. Recorded
producer/schema/source metadata and hashes do not authenticate a producer or a completely fabricated
consistent local story. The local record cannot supply postmerge PASS or suppress fresh landing
Small/area execution. Unsupported experimental content@1 receipts fall back to full; historical
wave-qualification@1 semantics remain unchanged. Expanded content@2 receipts bind the companion
descriptor, including the explicit no-companion state, through the existing profile/policy contract.

Two fixed existing sequential commands run separately: Small (including PDDA/Python/envelope), then
skills-army area (including its own envelope). Their original streams, IDs, hashes, lists and counts
remain separate in a two-row container at the existing `validation.jsonl` path. Typed @2 provenance
uses a nested outcome; no synthetic combined run or count is created. Strict validation rejects
failed stages, omissions, retries, extra stages, wrong identities or policy/environment mismatch.
Incomplete proof after otherwise successful commands gets one full fallback on the unchanged clone;
a real test failure or clone drift stops qualification. The original rejected proof is retained.
Historical @1 semantics remain. Off/error/incompatible @2 cannot suppress required full qualification.

Hosted runners do not read the Mac file. The wave workflow explicitly maps repository variable
`XYZ_CI_OPTIMIZED` into the existing environment tier, defaulting to `1` when unset. Set that variable
to `0` to restore Medium full for future hosted jobs; removing it returns the workflow's explicit
on default. Local off is `ci.optimized: false` (or environment `XYZ_CI_OPTIMIZED=0`). Changing the Mac
file alone cannot switch hosted jobs. This workflow contract becomes live only after this PR lands;
a PR smoke pass is not an actual optimized qualification. Primary-checkout activation is coordinated
with the merge owner; isolated verification must not alter the shared Mac file.
