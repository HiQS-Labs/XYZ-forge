**NO FIRSTHAND VERIFICATION CITED** — treat conclusions as conditional (codex's answer carries an unsupported [Pass]/verified/confirmed-style claim with no quoted span or file:line citation nearby, despite the consult PREAMBLE asking advisors to cite evidence.)

> **ATTESTATION**
> Model: gpt-6-astra
> Provider: openai
> Sandbox: read-only

Reading additional input from stdin...
OpenAI Codex v0.153.4
--------
workdir: /private/var/folders/z0/92pfvhnn06z2_7hnpdb4kkbw0000gn/T/consult-wt-72136-672l0ujm
model: gpt-6-astra
provider: openai
approval: never
sandbox: read-only
reasoning effort: low
reasoning summaries: none
session id: 01a0c4c6-87e4-7da2-9dfc-4e24c275f79a
--------
user
You are an INDEPENDENT advisor in a one-shot cross-model consult. Another model is answering the SAME question separately and a coordinator will reconcile both answers, so give your own honest, specific read — do not hedge toward a consensus you cannot see. Read any repo files the question references (cite file:line). Respond with: (1) a short direct ANSWER; (2) graded FINDINGS — [Blocker]/[Should]/[Nit]/[Pass] — where applicable; (3) a one-line RECOMMENDATION. You are ADVISORY ONLY: output your analysis as text; do not rely on writing files (you are running in a throwaway copy).

=== CONSULT QUESTION ===
# Independent code review — GH-656 / GH-657 closeout evidence guards

Review the working tree's diff against `origin/development` (`git diff origin/development -- utils/py/jog_run.py utils/py/wave_reconcile.py test/gh280-jog-marathon-adapter.sh test/gh496-phase2-reconciliation-views.sh`). Read the issues' intent from `PROJECT/2-WORKING/GH-656-CLOSEOUT-EVIDENCE.md` and `PROJECT/2-WORKING/GH-657-RECEIPT-OUTCOMES.md`.

Question: does this diff correctly and **minimally** fix

1. **GH-656** — `utils/py/jog_run.py:jog_land` must carry the already-verified `merged_sha` as `mergeCommit: {oid: …}` into the offline reconciliation manifest it hands to `wave_reconcile.py`, so a nonempty owned release member ships instead of the reconciler refusing after Jog has persisted its landing; and
2. **GH-657** — `utils/py/wave_reconcile.py:validate_pre_merge_receipts` must reject any *supplied* outcome that is not a valid success: `result=pass, rc=1`; `result=fail, rc=0`; `result=pass, status=fail`; boolean `rc` (True/False) with or without `pass`; null / empty-string / wrong-type `result`/`status`/`rc`; and a receipt with **no** outcome fields at all — while still accepting the supported legacy positive shapes: result-only (`pass`/`passed`/`PASS`), status-only, integer-zero-`rc`-only, and consistent combined success.

Constraints to check:
- The separate post-merge attribution guard `check_provenance_receipts` (GH-425) must NOT be tightened; confirm the diff does not touch it and that the pre-merge change cannot leak into it.
- Trace every producer of pre-merge receipts on `development` (grep for writers of `TESTS-RESULTS/**/provenance.jsonl` / `validation.jsonl` entries with `result`/`status`/`rc`: `utils/py/express.py`, `utils/ci-route.sh`, `utils/py/wave_reconcile.py` qualification receipts, `githooks/pre-push`, tests' fixtures). Would any *legitimate* current producer emit a receipt the new `outcome_ok` predicate now refuses (e.g. `status: "PASS"` with `rc: "0"` as a string, `result: "passed"` with `status: "ok"`, `rc: 0` with `result: null`)?
- Is the new predicate's handling of `rc` present-but-None (`"rc": null`) the intended refusal, and is `type(rc) is int` correct given `bool` is a subclass of `int`?

Answer with: (a) verdict — correct & minimal / correct but not minimal / incorrect; (b) any concrete case the predicate gets wrong, with the exact receipt shape; (c) any regression risk for an existing receipt producer, naming the file and line; (d) anything blocking a PR into `development`; (e) anything optional. Advisory only — do not modify the repository.

codex
I’ll read the diff, issue intent, and receipt producers to check correctness, compatibility, and scope.

exec
/bin/zsh -lc 'cat ROUTER.md GUIDING-PRINCIPLES.md; git diff origin/development -- utils/py/jog_run.py utils/py/wave_reconcile.py test/gh280-jog-marathon-adapter.sh test/gh496-phase2-reconciliation-views.sh' in /private/var/folders/z0/92pfvhnn06z2_7hnpdb4kkbw0000gn/T/consult-wt-72136-672l0ujm
 succeeded in 0ms:
# ROUTER.md

This file is the first entry point for an AI agent working in this repo: it tells you what to read, what to run, and which files are canonical.

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
./validate.sh --sequential # force the sequential run (~16 min)
./validate.sh --tier 2 --subsystem hq   # GH-35: one subsystem's focused suites (pre-push speed, NOT evidence)
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
agent-chorus, standup, skills-army-hq); a push the classifier rates `tier=2` runs only those focused
suites at the boundary, `--tier 1` runs the docs gate, and everything else — unknown paths, unclaimed
test edits, kernel surfaces — runs the full suite. `--auto` classifies a local diff the same way.
Tiers 1 and 2 are pre-push speed and are labelled NOT promotion evidence; only `ci-local.sh`'s
sequential full run qualifies (GH-509).

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
- If the task is about the ATE (Automated Testing Environment) skill — unattended variation-test fuzzing whose implementation lives under `utils/ate/` — start at its canonical interface in `skills/ate/SKILL.md`.
- If the task is about relay session telemetry, the `focus5float` health feed, or extraction scripts under `utils/telemetry/`, start in `PROJECT/1-INBOX/GH-24-RELAY-TELEMETRY-EXTRACTOR.md`.
- If the task is about live per-session completion telemetry — the `XYZ.json` log every relay/marathon/swarm session appends to at the harness repo root (schema: `harness`/`sessionId`/`health`/`title`/`description`/`updatedAt`), the shared writer `utils/telemetry/append-xyz-completion.sh`, or the shared health mapping `utils/telemetry/health-lib.sh` — start in `PROJECT/1-INBOX/GH-75-XYZ-JSON-COMPLETION-TELEMETRY.md`. `XYZ.json` is local + gitignored (machine-specific).
- If the task is about cross-repo HQ tooling (`utils/hq/` — `hq.sh` single-repo actions, `rollup.sh` the Obsidian daily ROADMAP rollup, `marathon-scan.sh` the cross-repo marathon-preflight aggregator, `hq-lib.sh` the shared repo registry), start in `PROJECT/3-COMPLETED/GH-27-ROADMAP-DASHBOARD.md` and `PROJECT/3-COMPLETED/GH-158-HQ-MARATHON-SCAN.md`. The two rollups are deliberately separate today (`rollup.sh` → Obsidian, generic; `marathon-scan.sh` → hub repo, preflight-aware) and are not yet bridged — tracked in `PROJECT/1-INBOX/GH-192-HQ-MARATHON-OBSIDIAN-ROLLUP.md`.
- If the task is about a proposed roadmap-steward agent, start here, then read `PROJECT/PDDA.md` and its `Proposed roadmap steward extension` section.
- If the task is about finding or picking a skill for a job, see `ARCHITECTURE.md` → "Skills Index" for a one-line inventory of every skill in `skills/`.
- If the task is about **managing skills for the system** — adding a skill to the machine-wide collection, deploying/refreshing/removing it across the configured app targets (`targets.json`, machine-local), or asking what is deployed — the mechanism is the `skills-army-hq` skill (`skills/skills-army-hq/SKILL.md`). `skills/` in this repo is the authoring source; the durable collection lives wherever `XYZ_SKILLS_ROOT` points (machine-local, never committed; falls back to `~/git-pulse-sync/Deployed Skills`), and only `intake.py` / `sync.py` mutate it or the app symlinks. Never hand-copy a skill folder into an app's skills directory.
- Issue-first SOP: any change beyond a 2–3 line fix (and every project plan) opens a GitHub issue *first*, then gets a pointer doc named after the issue at `PROJECT/1-INBOX/GH-<number>-VERY-SHORT-DESC.md` — e.g. `GH-1234-SHOWME-COMMAND.md` — and that capture is parked in the roadmap ledger queue immediately via `releases roadmap add` (format + lifecycle owned by `PROJECT/PDDA.md` → "GitHub issue intake"), following the normal `1-INBOX` → `2-WORKING` flow. Genuinely trivial edits (≤2–3 line fixes, typos, path repoints, doc-only one-liners) are exempt and commit directly.
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

13. **A green gate without a witnessed red control is not evidence.** Every new or materially changed decision gate ships a recorded demonstration that it fails for the right reason: a pre-fix replay, deliberate mutation, or controlled bad fixture. Do not mistake a check that validates the artifact it just generated (#351) or a parity check that compares a lane to itself (#348) for evidence; both shapes are structurally unable to falsify their claim.

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
git: warning: confstr() failed with code 5: couldn't get path of DARWIN_USER_TEMP_DIR; using /tmp instead
git: error: couldn't create cache file '/tmp/xcrun_db-JDkkWPr3' (errno=Operation not permitted)
git: warning: confstr() failed with code 5: couldn't get path of DARWIN_USER_TEMP_DIR; using /tmp instead
git: error: couldn't create cache file '/tmp/xcrun_db-wtPVuYl9' (errno=Operation not permitted)
diff --git a/test/gh280-jog-marathon-adapter.sh b/test/gh280-jog-marathon-adapter.sh
index d692a04b..c62213d6 100644
--- a/test/gh280-jog-marathon-adapter.sh
+++ b/test/gh280-jog-marathon-adapter.sh
@@ -927,6 +927,15 @@ has "$(queue_status "$FR")" "parked|" \
   && pass "L1-L4 left the row un-landed (fail closed)" || fail "row mutated by a refused land: $(queue_status "$FR")"
 
 # L5: the good landing — verifies, completes the row, delegates lifecycle to wave_reconcile
+# GH-656: a nonempty release manifest exercises the real evidence consumer.
+LAND_ORIGIN="$(git -C "$FR" remote get-url origin)"
+git -C "$FR" remote set-url origin https://github.com/example/example.git
+REL_OUT="$(python3 "$FR/utils/py/releases_app.py" --root "$FR" add --status draft --version 0.0.656 --description 'GH-656 landing fixture' --tracking-issue https://github.com/example/example/issues/901 2>&1)"
+REL_GID="$(sqlite3 "$FR/releases.db" "SELECT global_id FROM releases WHERE version='0.0.656';")"
+[ -n "$REL_GID" ] && pass "L5 release member fixture is nonempty" || fail "L5 release creation failed: $REL_OUT"
+python3 "$FR/utils/py/releases_app.py" --root "$FR" manifest dial-in --gid "$REL_GID" https://github.com/example/example/issues/901 >/dev/null 2>&1
+MEMBER_BEFORE="$(sqlite3 "$FR/releases.db" "SELECT state FROM manifest_items WHERE release_id=(SELECT id FROM releases WHERE global_id='$REL_GID');")"
+[ "$MEMBER_BEFORE" = dialed_in ] && pass "L5 exact owned member starts dialed_in" || fail "L5 member fixture not live: $MEMBER_BEFORE"
 pr_view_json MERGED development "$LANE_TIP" "$MERGE_SHA" > "$VIEW"
 L5_OUT="$(GH_STUB_PR_VIEW_JSON="$VIEW" jog_verb land 901 --pr 42 2>&1)"; rc=$?
 [ "$rc" -eq 0 ] && pass "L5 jog land completes cleanly" || fail "L5 rc=$rc: $L5_OUT"
@@ -938,11 +947,22 @@ has "$(queue_status "$FR")" "completed|landed via PR #42" \
 grep -q "SHIPPED.*PR #42" "$FR/ROADMAP.md" \
   && pass "L5 ROADMAP entry archived with the shipping badge" || fail "L5 ROADMAP not archived"
 jassert "$FR/.tick/jog/$GID/state.json" 'any(e.get("landing",{}).get("reconciled") for e in d["executions"])' "L5 landing reconciliation evidence recorded"
+SHIP_STATE="$(sqlite3 "$FR/releases.db" "SELECT state FROM manifest_items WHERE release_id=(SELECT id FROM releases WHERE global_id='$REL_GID');")"
+[ "$SHIP_STATE" = shipped ] && pass "L5 real reconciler ships owned dialed-in member" || fail "L5 manifest state: $SHIP_STATE"
+SHIP_EVIDENCE="$(sqlite3 "$FR/releases.db" "SELECT e.reason FROM manifest_state_events e JOIN manifest_items m ON m.id=e.item_id JOIN releases r ON r.id=m.release_id WHERE r.global_id='$REL_GID' AND e.to_state='shipped';")"
+[ "$SHIP_EVIDENCE" = "$MERGE_SHA" ] && pass "L5 shipped evidence equals verified full merge SHA" || fail "L5 shipping evidence: $SHIP_EVIDENCE"
+landing_counts() {
+  sqlite3 "$FR/releases.db" "SELECT (SELECT count(*) FROM manifest_items WHERE release_id=(SELECT id FROM releases WHERE global_id='$REL_GID')) || '|' || (SELECT count(*) FROM manifest_state_events) || '|' || (SELECT count(*) FROM op_receipts);"
+}
+LANDED_COUNTS="$(landing_counts)"
 
 # L6: replay is idempotent — verifies again, projects nothing new, reconciles nothing new
 L6_OUT="$(GH_STUB_PR_VIEW_JSON="$VIEW" jog_verb land 901 --pr 42 2>&1)"; rc=$?
 [ "$rc" -eq 0 ] && has "$L6_OUT" "already reconciled" \
   && pass "L6 land replay is idempotent" || fail "L6 rc=$rc: $L6_OUT"
+SHIP_COUNT="$(sqlite3 "$FR/releases.db" "SELECT count(*) FROM manifest_items WHERE release_id=(SELECT id FROM releases WHERE global_id='$REL_GID') AND state='shipped';")"
+[ "$SHIP_COUNT" = 1 ] && pass "L6 replay retains exactly one shipped member" || fail "L6 shipped count: $SHIP_COUNT"
+[ "$(landing_counts)" = "$LANDED_COUNTS" ] && pass "L6 replay emits no duplicate manifest evidence or receipts" || fail "L6 replay counts changed"
 
 # L7: crash-boundary resume — landing recorded, reconciliation evidence missing → only step 3 re-runs
 python3 - "$FR/.tick/jog/$GID/state.json" <<'PY'
@@ -958,6 +978,8 @@ L7_OUT="$(GH_STUB_PR_VIEW_JSON="$VIEW" jog_verb reconcile 901 --pr 42 2>&1)"; rc
 [ "$rc" -eq 0 ] && has "$L7_OUT" "replaying missing steps only" \
   && pass "L7 reconcile resumes at the missing durable step" || fail "L7 rc=$rc: $L7_OUT"
 jassert "$FR/.tick/jog/$GID/state.json" 'any(e.get("landing",{}).get("reconciled") for e in d["executions"])' "L7 reconciliation evidence restored"
+[ "$(landing_counts)" = "$LANDED_COUNTS" ] && pass "L7 missing-step replay emits no duplicate shipping evidence" || fail "L7 replay counts changed"
+git -C "$FR" remote set-url origin "$LAND_ORIGIN"
 
 # L8/L9: more fail-closed shapes on a fabricated ledger — missing gate evidence, wrong repo
 cleanup_root_fixture
@@ -1035,7 +1057,7 @@ M_OUT="$(GH_STUB_PR_JSON="$CANNED_PR" \
 # of tracked ledger files cannot destroy the queue row anymore
 grep -q "jog-state:" <<<"$(git -C "$FR" log --oneline --grep="^jog-state:" -1)" \
   && pass "M3 supervisor-state commit landed before dispatch (F1)" \
-  || fail "M3 no jog-state commit found"
+  || fail "M3 no jog-state commit found: $M_OUT"
 grep -q "releases.db" <<<"$(git -C "$FR" show --name-only --format= "$(git -C "$FR" log --format=%H --grep="^jog-state:" -1)")" \
   && pass "M3 the supervisor commit carries releases.db" || fail "M3 supervisor commit lacks releases.db"
 git -C "$FR" checkout -q -- releases.db releases.sql
diff --git a/test/gh496-phase2-reconciliation-views.sh b/test/gh496-phase2-reconciliation-views.sh
index df0f5aa7..285b7b59 100755
--- a/test/gh496-phase2-reconciliation-views.sh
+++ b/test/gh496-phase2-reconciliation-views.sh
@@ -416,6 +416,45 @@ else
 fi
 
 # Case G: Red Control 6 - Pre-merge fails closed when PR metadata cannot be fetched -> exit 2
+# GH-657: real committed receipts, with identity and staleness held valid.
+python3 - "$ROOT" "$WORK/outcome-receipts" <<'PY' || fail "GH-657 committed receipt outcomes"
+import importlib.util, json, os, subprocess, sys
+root, repo = sys.argv[1:]
+sys.path.insert(0, os.path.join(root, 'utils/py'))
+spec = importlib.util.spec_from_file_location('wave', os.path.join(root, 'utils/py/wave_reconcile.py'))
+wave = importlib.util.module_from_spec(spec)
+spec.loader.exec_module(wave)
+os.makedirs(repo)
+def git(*args):
+    return subprocess.check_output(['git', '-C', repo, *args], text=True).strip()
+git('init', '-q')
+git('config', 'user.name', 'receipt-test')
+git('config', 'user.email', 'receipt@test.invalid')
+git('commit', '-q', '--allow-empty', '-m', 'fixture baseline')
+receipt_dir = os.path.join(repo, 'TESTS-RESULTS', 'outcomes')
+os.makedirs(receipt_dir)
+positive = [{key:token} for key in ('result','status') for token in ('pass','passed','PASS')] + [{'rc':0},
+            {'result':'pass','status':'passed','rc':0}]
+negative = [{'result':'pass','rc':1}, {'result':'fail','rc':0},
+            {'result':'pass','status':'fail','rc':0}, {'rc':False}, {'rc':True},
+            {'result':'fail','status':'pass'}, {'result':'pass','status':'fail'},
+            {'result':'pass','rc':False}, {'result':'pass','rc':True},
+            {'rc':'0'}, {'rc':0.0}, {'rc':None}, {'result':None,'rc':0},
+            {'result':[],'rc':0}, {'status':{},'rc':0}, {'result':'unknown','rc':0},
+            {'result':'','rc':0}, {'status':None,'rc':0}, {'status':'','rc':0},
+            {'rc':-1}, {}]
+for should_pass, cases in [(True,positive), (False,negative)]:
+    for outcome in cases:
+        tested = git('rev-parse','HEAD')
+        with open(os.path.join(receipt_dir,'provenance.jsonl'),'w') as f:
+            f.write(json.dumps({'commit':tested, **outcome})+'\n')
+        git('add','TESTS-RESULTS')
+        git('commit','-q','--allow-empty','-m','committed outcome')
+        error = wave.validate_pre_merge_receipts(repo, git('rev-parse','HEAD'))
+        assert (error is None) == should_pass, (outcome, error)
+        print('PASS committed outcome', outcome, flush=True)
+PY
+
 echo "error" > "$MOCK_GH_STATE"
 rc=0; out="$(python3 "$RECONCILE_PY" --root "$REPO" --pre-merge --pr 999 2>&1)" || rc=$?
 assert_eq "Pre-merge fails closed when PR metadata cannot be fetched (exit 2)" "$rc" "2"
diff --git a/utils/py/jog_run.py b/utils/py/jog_run.py
index eaf5191d..c3fd8a03 100755
--- a/utils/py/jog_run.py
+++ b/utils/py/jog_run.py
@@ -1004,6 +1004,7 @@ def jog_land(root, gh_num, pr_arg=None):
             "title": pr.get("title") or f"GH-{gh_num}",
             "state": "MERGED",
             "mergedAt": pr.get("mergedAt"),
+            "mergeCommit": {"oid": merged_sha},
             "baseRefName": pr.get("baseRefName"),
             "headRefName": pr.get("headRefName"),
             "body": pr.get("body") or f"Closes #{gh_num}",
diff --git a/utils/py/wave_reconcile.py b/utils/py/wave_reconcile.py
index c6828dc2..d793f518 100755
--- a/utils/py/wave_reconcile.py
+++ b/utils/py/wave_reconcile.py
@@ -801,9 +801,15 @@ def validate_pre_merge_receipts(repo_root, head_sha, pr_num=None):
                                 pass
 
                 if commit_match or pr_match:
-                    res = entry.get("result") or entry.get("status")
+                    outcomes = [entry[key] for key in ("result", "status") if key in entry]
                     rc = entry.get("rc")
-                    if res in ("pass", "passed", "PASS") or rc == 0:
+                    outcome_ok = bool(outcomes) or "rc" in entry
+                    outcome_ok = outcome_ok and all(
+                        isinstance(value, str) and value in ("pass", "passed", "PASS")
+                        for value in outcomes)
+                    if "rc" in entry:
+                        outcome_ok = outcome_ok and type(rc) is int and rc == 0
+                    if outcome_ok:
                         # GH-496 / Codex QA: verify receipt is not stale.
                         # If matched_sha is not HEAD, verify that no code or docs outside
                         # TESTS-RESULTS/ changed between the tested commit and HEAD.

exec
/bin/zsh -lc "rg -n 'provenance.jsonl|validation.jsonl' utils githooks ci-local.sh test" in /private/var/folders/z0/92pfvhnn06z2_7hnpdb4kkbw0000gn/T/consult-wt-72136-672l0ujm
 succeeded in 0ms:
utils/ci-route.sh:287:  # GH-487: TESTS-RESULTS receipts join the evidence side — a provenance.jsonl follow-up used
test/gh267-express-skill.sh:150:# identity check — some TESTS-RESULTS/**/provenance.jsonl line must carry the commit.
test/gh267-express-skill.sh:157:    if "provenance.jsonl" in fs:
test/gh267-express-skill.sh:158:        fp = os.path.join(d, "provenance.jsonl")
test/gh267-express-skill.sh:170:    print("--gate failure: No provenance.jsonl or error_log.jsonl entry matches PR #%s" % sha[:12], file=sys.stderr); sys.exit(6)
test/gh267-express-skill.sh:385:[ -n "$RECEIPT_DIR" ] && [ -f "$RECEIPT_DIR/provenance.jsonl" ] && ok "receipt file exists at TESTS-RESULTS/<date>+GH-999-express/provenance.jsonl" || bad "receipt file missing"
test/gh267-express-skill.sh:391:    if "provenance.jsonl" in fs:
test/gh267-express-skill.sh:392:        for line in open(os.path.join(d, "provenance.jsonl"), encoding="utf-8"):
test/gh267-express-skill.sh:406:grep -q 'GH-999-express/provenance.jsonl' <<<"$SHIP_STAT" && ok "ship transaction commits exactly the receipt" || bad "receipt not in ship commit"
test/gh267-express-skill.sh:413:STUB_INJECT_PATH="$FX/TESTS-RESULTS/unrelated/provenance.jsonl" python3 "$DRIVER" --root "$FX" run --issue 999 --suite test/gh999-demo.sh --summary demo >/dev/null 2>"$ERR" \
test/gh267-express-skill.sh:415:  || { grep -q "unexpected dirty path" "$ERR" && grep -q "TESTS-RESULTS/unrelated/provenance.jsonl" "$ERR" && ok "control (i): unrelated TESTS-RESULTS file refused by name; exact-path grant did not widen" || bad "control (i) wrong failure: $(tail -2 "$ERR")"; }
test/gh267-express-skill.sh:423:python3 - "$DRIVER" "$FX" <<'PY' >/dev/null 2>"$ERR" && bad "no-write mutation must fail closed" || { grep -q "express-reconcile-failed" "$ERR" && grep -q "No provenance.jsonl" "$ERR" && ok "control (ii): driver without a real receipt write fails the gate (missing-receipt oracle reached)" || bad "control (ii) wrong failure: $(tail -2 "$ERR")"; }
test/gh267-express-skill.sh:426:express.write_receipt = lambda root, sha, issue, suite, rc: "TESTS-RESULTS/mutant+GH-999-express/provenance.jsonl"
test/gh267-express-skill.sh:545:python3 - "$BADDIR/provenance.jsonl" "$LAND_SHA" <<'PY'
test/gh267-express-skill.sh:565:open(os.path.join(sys.argv[2], "TESTS-RESULTS/.relay-scratch/provenance.jsonl"), "w").write(json.dumps(rec) + "\n")
test/gh267-express-skill.sh:573:p = glob.glob(sys.argv[1] + "/TESTS-RESULTS/*+GH-999-express/provenance.jsonl")[0]
test/gh267-express-skill.sh:579:# --- GH-592 control (viii): a COMMITTED symlink named provenance.jsonl is not evidence (HEAD reader skips mode 120000) ---
test/gh267-express-skill.sh:587:os.symlink("../../outside-evidence.jsonl", os.path.join(root, "TESTS-RESULTS/0-linked/provenance.jsonl"))
test/gh267-express-skill.sh:590:! python3 "$DRIVER" --root "$FX" resume --issue 999 --suite test/gh999-demo.sh 2>"$ERR" && grep -q "no COMMITTED valid express receipt" "$ERR" && ok "control (viii): a committed symlinked provenance.jsonl is not evidence for resume" || bad "resume accepted a committed symlink receipt: $(tail -1 "$ERR")"
test/gh267-express-skill.sh:618:RECEIPT_LINES_BEFORE="$(cat "$FX"/TESTS-RESULTS/*+GH-999-express/provenance.jsonl | wc -l | tr -d ' ')"
test/gh267-express-skill.sh:621:[ "$(cat "$FX"/TESTS-RESULTS/*+GH-999-express/provenance.jsonl | wc -l | tr -d ' ')" = "$RECEIPT_LINES_BEFORE" ] && ok "control (v): second resume wrote no new receipt record" || bad "second resume appended a record"
utils/py/wave_reconcile.py:604:    telemetry_path, receipt_path = folder / "validation.jsonl", folder / "provenance.jsonl"
utils/py/wave_reconcile.py:672:            if name not in ("error_log.jsonl", "provenance.jsonl"):
utils/py/wave_reconcile.py:716:    die(f"--gate failure: No provenance.jsonl or error_log.jsonl entry matches PR #{pr_num} "
utils/py/wave_reconcile.py:734:        if f.endswith("provenance.jsonl") or f.endswith("error_log.jsonl")
utils/py/wave_reconcile.py:737:        return f"No committed provenance.jsonl or error_log.jsonl receipts found under TESTS-RESULTS/ at HEAD {head_sha[:10]}."
test/improve-loop.sh:24:[ "$(/usr/bin/grep -c . "$A/state/provenance.jsonl")" = 6 ] && pass "provenance: baseline + 5 judgements = 6 records" || fail "provenance lines=$(/usr/bin/grep -c . "$A/state/provenance.jsonl")"
utils/py/express.py:234:    valid_express_receipt, scanning every TESTS-RESULTS/**/provenance.jsonl by
utils/py/express.py:243:        if "provenance.jsonl" not in files:
utils/py/express.py:245:        path = os.path.join(dirpath, "provenance.jsonl")
utils/py/express.py:263:    for rel in sorted(p for p in ls.split("\0") if p.endswith("/provenance.jsonl")):
utils/py/express.py:284:    rel = os.path.join(rel_dir, "provenance.jsonl")
test/gh496-phase2-reconciliation-views.sh:214:cat << RECEIPT_EOF > "$REPO/TESTS-RESULTS/2026-09-10+GH-999/provenance.jsonl"
test/gh496-phase2-reconciliation-views.sh:217:git -C "$REPO" add "$REPO/TESTS-RESULTS/2026-09-10+GH-999/provenance.jsonl"
test/gh496-phase2-reconciliation-views.sh:222:cat << RECEIPT_EOF2 > "$REPO/TESTS-RESULTS/2026-09-10+GH-999/provenance.jsonl"
test/gh496-phase2-reconciliation-views.sh:225:git -C "$REPO" add "$REPO/TESTS-RESULTS/2026-09-10+GH-999/provenance.jsonl"
test/gh496-phase2-reconciliation-views.sh:287:cat << EOF_REC > "$REPO/TESTS-RESULTS/2026-09-10+GH-999/provenance.jsonl"
test/gh496-phase2-reconciliation-views.sh:290:git -C "$REPO" add "$REPO/TESTS-RESULTS/2026-09-10+GH-999/provenance.jsonl"
test/gh496-phase2-reconciliation-views.sh:382:git -C "$REPO" rm -q "$REPO/TESTS-RESULTS/2026-09-10+GH-999/provenance.jsonl"
test/gh496-phase2-reconciliation-views.sh:387:if grep -q "No committed provenance.jsonl or error_log.jsonl receipts found" <<< "$out"; then
test/gh496-phase2-reconciliation-views.sh:395:echo '{"commit": "xyz", "rc": 0, "result": "pass"}' > "$REPO/TESTS-RESULTS/2026-09-10+GH-999/provenance.jsonl"
test/gh496-phase2-reconciliation-views.sh:404:printf '{"commit": "%s", "rc": 0, "result": "pass"}\n' "$head_commit" > "$REPO/TESTS-RESULTS/2026-09-10+GH-999/provenance.jsonl"
test/gh496-phase2-reconciliation-views.sh:405:git -C "$REPO" add "$REPO/TESTS-RESULTS/2026-09-10+GH-999/provenance.jsonl"
test/gh496-phase2-reconciliation-views.sh:449:        with open(os.path.join(receipt_dir,'provenance.jsonl'),'w') as f:
test/gh430-state-dir-tracked-default.sh:4:# improve-loop.sh's only audit trail is $STATE_DIR/provenance.jsonl. The old default rooted it at
test/gh430-state-dir-tracked-default.sh:9:# This asserts that running the loop WITHOUT --state-dir puts provenance.jsonl at a path inside this
test/gh430-state-dir-tracked-default.sh:61:[ -n "$SD" ] && [ -s "$SD/provenance.jsonl" ] && pass "provenance.jsonl exists and is non-empty at the default path" \
test/gh430-state-dir-tracked-default.sh:62:  || fail "no provenance.jsonl at default path $SD"
test/gh430-state-dir-tracked-default.sh:71:[ -s "$EXPLICIT/provenance.jsonl" ] && pass "explicit --state-dir still wins over the default" \
test/gh430-state-dir-tracked-default.sh:72:  || fail "explicit --state-dir was not honored: $EXPLICIT/provenance.jsonl missing"
test/gh591-prepush-commit-boundary.sh:34:    hook.write_text('#!/bin/sh\nprintf "hook receipt\\n" > provenance.jsonl\n')
test/gh591-prepush-commit-boundary.sh:37:    assert (source/'provenance.jsonl').read_text() == 'hook receipt\n'
test/gh591-prepush-commit-boundary.sh:42:    git('add', 'provenance.jsonl', cwd=source)
test/gh591-prepush-commit-boundary.sh:45:    assert git('--git-dir', str(remote), 'show', 'main:provenance.jsonl') == 'hook receipt'
test/gh232-wave-reconcile-multiphase.sh:73:echo '{"status": "PASS"}' > "$REPO/TESTS-RESULTS/$TODAY/provenance.jsonl"
test/gh358-wave-reconcile-vendored-paths.sh:95:echo '{"status": "PASS"}' > "$REPO/TESTS-RESULTS/$TODAY/provenance.jsonl"
test/gh693-lessons-learned-advisory.sh:30:  echo '{"pr": 1001, "status": "PASS", "trials": 1}' > "$d/TESTS-RESULTS/2026-09-18/provenance.jsonl"
test/gh693-lessons-learned-advisory.sh:77:printf '{"commit": "%s", "status": "PASS"}\n' "$sha" >> "$C/TESTS-RESULTS/2026-09-18/provenance.jsonl"
test/improve-loop-dogfood.sh:53:PROV="$W/state/provenance.jsonl"
test/improve-loop-qa.sh:38:ds1="$(/usr/bin/grep -o '"decision":"[a-z]*"' "$W/d1/state/provenance.jsonl" | tr '\n' ',')"
test/improve-loop-qa.sh:39:ds2="$(/usr/bin/grep -o '"decision":"[a-z]*"' "$W/d2/state/provenance.jsonl" | tr '\n' ',')"
test/improve-loop-qa.sh:60:{ [ "$(/usr/bin/grep -c '"decision"' "$W/d1/state/provenance.jsonl")" -ge 1 ] \
test/improve-loop-qa.sh:61:  && [ "$(/usr/bin/grep -c '"challenger_metric"' "$W/d1/state/provenance.jsonl")" -ge 1 ]; } \
test/gh421-auto-wave-reconcile.sh:55:        (self.root / 'TESTS-RESULTS/provenance.jsonl').write_text('{"pr":42}\n')
test/gh421-auto-wave-reconcile.sh:149:        (self.root / 'TESTS-RESULTS/provenance.jsonl').write_text(json.dumps({'commit': sha}) + '\n{"pr":42}\n')
test/gh421-auto-wave-reconcile.sh:251:        (self.root / 'TESTS-RESULTS/provenance.jsonl').write_text(''.join(json.dumps({'pr':n})+'\n' for n in (42,43,44)))
test/gh421-auto-wave-reconcile.sh:300:        with open(self.root / 'TESTS-RESULTS/provenance.jsonl', 'a') as f:
test/gh421-auto-wave-reconcile.sh:612:        paths += ['TESTS-RESULTS/2026-09-13+GH-591/wave-' + 'a'*40 + '/provenance.jsonl',
test/gh421-auto-wave-reconcile.sh:613:                  'TESTS-RESULTS/2026-09-13+GH-591/wave-' + 'a'*40 + '/validation.jsonl']
test/gh421-auto-wave-reconcile.sh:620:            self.publish(paths + ['TESTS-RESULTS/arbitrary/provenance.jsonl'])
test/gh421-auto-wave-reconcile.sh:625:                self.publish(paths + ['TESTS-RESULTS/2026-09-13+GH-591/wave-'+sha+'/provenance.jsonl'])
test/champion.sh:36:[ "$(/usr/bin/grep -c . "$D/provenance.jsonl")" = 4 ] && pass "provenance.jsonl has baseline + 3 records" || fail "provenance line count wrong"
test/gh280-jog-marathon-adapter.sh:886:printf '{"status": "PASS"}\n' > "$FR/TESTS-RESULTS/2026-08-28/provenance.jsonl"
test/wave-reconcile.sh:114:} > "$REPO/TESTS-RESULTS/2026-08-22/provenance.jsonl"
test/gh425-gate-provenance-pr.sh:37:    def receipt(self, content, name="run/provenance.jsonl"):
test/gh425-gate-provenance-pr.sh:66:                    self.assertIn("TESTS-RESULTS/run/provenance.jsonl:1", output)
test/gh425-gate-provenance-pr.sh:131:        self.receipt('{"issue":425}\n', "PR-425/provenance.jsonl")
test/gh425-gate-provenance-pr.sh:134:        (self.results / "provenance.jsonl").symlink_to(other)
test/gh425-gate-provenance-pr.sh:222:        self.assertIn("No provenance.jsonl or error_log.jsonl entry matches", out)
test/gh425-gate-provenance-pr.sh:235:        self.assertIn("No provenance.jsonl or error_log.jsonl entry matches", out)
test/gh425-gate-provenance-pr.sh:263:        # a symlinked provenance.jsonl is not evidence for express either — falsifiable: the
test/gh425-gate-provenance-pr.sh:267:        outside = self.repo / "outside-provenance.jsonl"
test/gh425-gate-provenance-pr.sh:270:        (self.repo / "TESTS-RESULTS" / "0-link" / "provenance.jsonl").symlink_to(outside)
test/gh425-gate-provenance-pr.sh:277:        (linked_dir / "provenance.jsonl").symlink_to(outside)
test/gh425-gate-provenance-pr.sh:348:        files = list((self.root/'TESTS-RESULTS').rglob('provenance.jsonl'))
test/gh425-gate-provenance-pr.sh:365:            self.assertFalse(list(self.root.rglob('provenance.jsonl')))
test/gh425-gate-provenance-pr.sh:372:        self.assertFalse(list(self.root.rglob('provenance.jsonl')))
test/gh425-gate-provenance-pr.sh:390:                path=next((self.root/'TESTS-RESULTS').rglob('provenance.jsonl'))
test/gh425-gate-provenance-pr.sh:415:        self.assertFalse(list(self.root.rglob('provenance.jsonl')))
test/gh425-gate-provenance-pr.sh:420:        self.assertFalse(list(self.root.rglob('provenance.jsonl')))
test/gh425-gate-provenance-pr.sh:421:        self.assertFalse(list(self.root.rglob('validation.jsonl')))
test/gh425-gate-provenance-pr.sh:425:        path=next((self.root/'TESTS-RESULTS').rglob('provenance.jsonl'))
test/gh202-wave-reconcile-issue-state.sh:72:echo '{"status": "PASS"}' > "$REPO/TESTS-RESULTS/$TODAY/provenance.jsonl"
test/gh429-wave-reconcile-vendored-observe.sh:66:  echo '{"status": "PASS"}' > "$REPO/TESTS-RESULTS/$TODAY/provenance.jsonl"
test/baselines/GH-418-negative-control.md:80:`provenance.jsonl`; these inline receipts are focused observations, not a qualifying
test/baselines/GH-3-state-dir-negative-control.md:8:audit trail (`provenance.jsonl`) evaporates on the next tmp purge. The fix (landed as GH-430,
test/baselines/GH-3-state-dir-negative-control.md:27:  PASS: provenance.jsonl exists and is non-empty at the default path
test/baselines/GH-3-state-dir-negative-control.md:47:  PASS: provenance.jsonl exists and is non-empty at the default path
test/baselines/GH-3-state-dir-negative-control.md:57:`provenance: $STATE_DIR/provenance.jsonl` and the default path is git-tracked-eligible (confirmed

exec
/bin/zsh -lc "nl -ba utils/py/wave_reconcile.py | sed -n '590,845p'; nl -ba utils/py/jog_run.py | sed -n '910,1040p'; rg -n 'receipt|result|status|rc' githooks/pre-push utils/ci-route.sh | tail -65" in /private/var/folders/z0/92pfvhnn06z2_7hnpdb4kkbw0000gn/T/consult-wt-72136-672l0ujm
 succeeded in 0ms:
   590	            if len(files) != 1:
   591	                die("Qualification requires exactly one retained validation run", code=6)
   592	            raw = files[0].read_bytes()
   593	            summary = qualification_summary(raw, tested)
   594	            if summary['run'] != f"{tested[:9]}-{validation.pgid}":
   595	                die("Qualification telemetry does not identify the launched validation process", code=6)
   596	        except (subprocess.SubprocessError, OSError, ValueError) as exc:
   597	            die(f"Full-suite qualification failed; no receipt produced: {exc}", code=6)
   598	    if subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=repo_root, text=True).strip() != tested:
   599	        die("Publishing HEAD changed during qualification; rerun from fresh development", code=6)
   600	    check_porcelain_cleanliness(repo_root)
   601	    now = datetime.now(timezone.utc)
   602	    folder = Path(repo_root) / "TESTS-RESULTS" / f"{now:%Y-%m-%d}+GH-591" / f"wave-{tested}"
   603	    folder.mkdir(parents=True, exist_ok=True)
   604	    telemetry_path, receipt_path = folder / "validation.jsonl", folder / "provenance.jsonl"
   605	    for path in (telemetry_path, receipt_path):
   606	        if path.exists():
   607	            die(f"Refusing to overwrite qualification evidence: {path.name}", code=6)
   608	        journal.track_created(path)
   609	    telemetry_path.write_bytes(raw)
   610	    entries = []
   611	    for meta in pending:
   612	        entry = dict(schema_version=QUALIFICATION_SCHEMA, artifact_kind=meta.get("artifactKind", "pr"),
   613	                     tested_commit=tested, landing_commit=meta["mergeCommit"]["oid"], result="pass", rc=0,
   614	                     gate="validate.sh --sequential", timestamp=now.isoformat(),
   615	                     telemetry=str(telemetry_path.relative_to(repo_root)),
   616	                     telemetry_sha256=hashlib.sha256(raw).hexdigest(), passed=summary["passed"],
   617	                     total=summary["total"])
   618	        if meta.get("artifactKind") != "commit":
   619	            entry["pr"] = meta["number"]
   620	        if os.environ.get("GITHUB_ACTIONS") == "true":
   621	            entry["run_url"] = (f"https://github.com/{os.environ.get('GITHUB_REPOSITORY', '')}/actions/runs/"
   622	                                f"{os.environ.get('GITHUB_RUN_ID', '')}")
   623	        entries.append(json.dumps(entry, sort_keys=True))
   624	    receipt_path.write_text("\n".join(entries) + "\n", encoding="utf-8")
   625	    log(f"Full-suite qualification passed; retained {receipt_path.relative_to(repo_root)}")
   626	
   627	
   628	def check_provenance_receipts(repo_root, pr_meta):
   629	    """Require a JSONL receipt attributable to this PR (GH-425).
   630	
   631	    Accept top-level pr/pr_number (positive integer or decimal string), or an
   632	    exact full commit matching GitHub's mergeCommit. Explicit PR fields must all
   633	    match; a conflicting PR cannot be rescued by a commit match. Filenames and
   634	    issue numbers are not PR identity. This checks attribution, not test success
   635	    or whether the receipt was committed; report only the identity actually read.
   636	    """
   637	    pr_num = pr_meta.get("number")
   638	    results_dir = os.path.join(repo_root, "TESTS-RESULTS")
   639	    if not os.path.isdir(results_dir):
   640	        die(f"--gate failure: TESTS-RESULTS directory missing; cannot verify provenance for PR #{pr_num}", code=6)
   641	
   642	    def pr_number(value):
   643	        if type(value) is int and value > 0:
   644	            return str(value)
   645	        if isinstance(value, str) and re.fullmatch(r"[1-9][0-9]*", value):
   646	            return value
   647	        return None
   648	
   649	    expected_pr = pr_number(pr_num)
   650	
   651	    candidate_shas = set()
   652	    merge_commit = pr_meta.get("mergeCommit") or {}
   653	    merge_sha = merge_commit.get("oid") if isinstance(merge_commit, dict) else None
   654	    if isinstance(merge_sha, str) and re.fullmatch(r"[0-9a-fA-F]{40}", merge_sha):
   655	        candidate_shas.add(merge_sha.lower())
   656	
   657	    head_oid = pr_meta.get("headRefOid")
   658	    if isinstance(head_oid, str) and re.fullmatch(r"[0-9a-fA-F]{40}", head_oid):
   659	        candidate_shas.add(head_oid.lower())
   660	
   661	    commits_list = pr_meta.get("commits") or []
   662	    if isinstance(commits_list, list):
   663	        for c in commits_list:
   664	            if isinstance(c, dict):
   665	                c_oid = c.get("oid")
   666	                if isinstance(c_oid, str) and re.fullmatch(r"[0-9a-fA-F]{40}", c_oid):
   667	                    candidate_shas.add(c_oid.lower())
   668	
   669	    for root, dirs, files in os.walk(results_dir):
   670	        dirs.sort()
   671	        for name in sorted(files):
   672	            if name not in ("error_log.jsonl", "provenance.jsonl"):
   673	                continue
   674	            path = os.path.join(root, name)
   675	            if os.path.islink(path) or not os.path.isfile(path):
   676	                continue
   677	            try:
   678	                with open(path, encoding="utf-8") as receipt:
   679	                    for line_num, line in enumerate(receipt, 1):
   680	                        try:
   681	                            entry = json.loads(line)
   682	                        except ValueError:
   683	                            continue
   684	                        if not isinstance(entry, dict):
   685	                            continue
   686	                        if str(entry.get("schema_version", "")).startswith("wave-qualification"):
   687	                            if qualification_receipt_matches(repo_root, entry, pr_meta):
   688	                                log(f"  Full-suite integration receipt matched for {landing_label(pr_meta)}: "
   689	                                    f"{os.path.relpath(path, repo_root)}:{line_num}")
   690	                                return
   691	                            continue  # A malformed qualification cannot fall through to legacy PR identity.
   692	                        pr_fields = [key for key in ("pr", "pr_number") if key in entry]
   693	                        matched = None
   694	                        if pr_fields:
   695	                            if expected_pr and all(pr_number(entry[key]) == expected_pr for key in pr_fields):
   696	                                matched = f"{pr_fields[0]}={expected_pr}"
   697	                        elif candidate_shas:
   698	                            entry_commits = []
   699	                            for key in ("commit", "identity_before", "identity_after"):
   700	                                val = entry.get(key)
   701	                                if isinstance(val, str):
   702	                                    val = val.strip()
   703	                                    if len(val) >= 7 and re.fullmatch(r"[0-9a-fA-F]{7,40}", val):
   704	                                        entry_commits.append((key, val))
   705	                            for key, c_val in entry_commits:
   706	                                c_lower = c_val.lower()
   707	                                if any(cand.startswith(c_lower) or c_lower.startswith(cand) for cand in candidate_shas):
   708	                                    matched = f"{key}={c_val}"
   709	                                    break
   710	                        if matched:
   711	                            relpath = os.path.relpath(path, repo_root)
   712	                            log(f"  Provenance receipt matched for PR #{pr_num}: {relpath}:{line_num} ({matched})")
   713	                            return
   714	            except (OSError, UnicodeError):
   715	                continue  # An unreadable receipt cannot establish attribution.
   716	    die(f"--gate failure: No provenance.jsonl or error_log.jsonl entry matches PR #{pr_num} "
   717	        "by pr/pr_number or exact merge commit in TESTS-RESULTS/", code=6)
   718	
   719	
   720	def validate_pre_merge_receipts(repo_root, head_sha, pr_num=None):
   721	    """Ensure a passing test receipt matching HEAD SHA or PR number is COMMITTED in Git tree (GH-496)."""
   722	    try:
   723	        tree_files = subprocess.check_output(
   724	            ["git", "ls-tree", "-r", "--name-only", "HEAD", "TESTS-RESULTS/"],
   725	            cwd=repo_root,
   726	            text=True,
   727	            stderr=subprocess.DEVNULL,
   728	        ).splitlines()
   729	    except Exception:
   730	        tree_files = []
   731	
   732	    matching_receipts = [
   733	        f for f in tree_files
   734	        if f.endswith("provenance.jsonl") or f.endswith("error_log.jsonl")
   735	    ]
   736	    if not matching_receipts:
   737	        return f"No committed provenance.jsonl or error_log.jsonl receipts found under TESTS-RESULTS/ at HEAD {head_sha[:10]}."
   738	
   739	    try:
   740	        recent_shas = subprocess.check_output(
   741	            ["git", "log", "-n", "10", "--format=%H", "HEAD"],
   742	            cwd=repo_root,
   743	            text=True,
   744	            stderr=subprocess.DEVNULL,
   745	        ).splitlines()
   746	    except Exception:
   747	        recent_shas = [head_sha]
   748	    recent_shas_lower = set(s.lower() for s in recent_shas)
   749	
   750	    found_match = False
   751	    expected_pr = str(pr_num) if pr_num else None
   752	    for receipt_rel in matching_receipts:
   753	        try:
   754	            content = subprocess.check_output(
   755	                ["git", "show", f"HEAD:{receipt_rel}"],
   756	                cwd=repo_root,
   757	                text=True,
   758	                stderr=subprocess.DEVNULL,
   759	            )
   760	            for line in content.splitlines():
   761	                if not line.strip():
   762	                    continue
   763	                try:
   764	                    entry = json.loads(line)
   765	                except ValueError:
   766	                    continue
   767	                if not isinstance(entry, dict):
   768	                    continue
   769	                c_val = str(entry.get("commit") or "").lower()
   770	                c_len = len(c_val)
   771	                matched_sha = None
   772	                commit_match = False
   773	                if c_val and c_len >= 7:
   774	                    try:
   775	                        resolved = subprocess.check_output(
   776	                            ["git", "rev-parse", "--verify", f"{c_val}^{{commit}}"],
   777	                            cwd=repo_root,
   778	                            text=True,
   779	                            stderr=subprocess.DEVNULL,
   780	                        ).strip().lower()
   781	                        if resolved == head_sha.lower() or resolved in recent_shas_lower:
   782	                            commit_match = True
   783	                            matched_sha = resolved
   784	                    except Exception:
   785	                        pass
   786	
   787	                pr_match = False
   788	                if expected_pr:
   789	                    pr_val = str(entry.get("pr") or entry.get("pr_number") or "")
   790	                    if pr_val == expected_pr:
   791	                        pr_match = True
   792	                        if not matched_sha and c_val and c_len >= 7:
   793	                            try:
   794	                                matched_sha = subprocess.check_output(
   795	                                    ["git", "rev-parse", "--verify", f"{c_val}^{{commit}}"],
   796	                                    cwd=repo_root,
   797	                                    text=True,
   798	                                    stderr=subprocess.DEVNULL,
   799	                                ).strip().lower()
   800	                            except Exception:
   801	                                pass
   802	
   803	                if commit_match or pr_match:
   804	                    outcomes = [entry[key] for key in ("result", "status") if key in entry]
   805	                    rc = entry.get("rc")
   806	                    outcome_ok = bool(outcomes) or "rc" in entry
   807	                    outcome_ok = outcome_ok and all(
   808	                        isinstance(value, str) and value in ("pass", "passed", "PASS")
   809	                        for value in outcomes)
   810	                    if "rc" in entry:
   811	                        outcome_ok = outcome_ok and type(rc) is int and rc == 0
   812	                    if outcome_ok:
   813	                        # GH-496 / Codex QA: verify receipt is not stale.
   814	                        # If matched_sha is not HEAD, verify that no code or docs outside
   815	                        # TESTS-RESULTS/ changed between the tested commit and HEAD.
   816	                        if matched_sha and matched_sha != head_sha.lower():
   817	                            try:
   818	                                diff_out = subprocess.check_output(
   819	                                    ["git", "diff", "--name-only", f"{matched_sha}..{head_sha}"],
   820	                                    cwd=repo_root,
   821	                                    text=True,
   822	                                    stderr=subprocess.DEVNULL,
   823	                                ).splitlines()
   824	                                code_modifications = [
   825	                                    f for f in diff_out
   826	                                    if not f.startswith("TESTS-RESULTS/")
   827	                                ]
   828	                                if code_modifications:
   829	                                    # Stale receipt: code changed after this qualification run!
   830	                                    continue
   831	                            except Exception:
   832	                                continue
   833	                        found_match = True
   834	                        break
   835	            if found_match:
   836	                break
   837	        except Exception:
   838	            continue
   839	
   840	    if not found_match:
   841	        target = f"PR #{pr_num}" if pr_num else f"commit {head_sha[:10]}"
   842	        return f"No committed passing test receipt at HEAD matches {target} in TESTS-RESULTS/ (AGENTS.md: uncommitted provenance is not proof)."
   843	    return None
   844	
   845	
   910	                        receipt[field] = _other[field]
   911	            if receipt.get("base_branch") and receipt.get("head_branch"):
   912	                break
   913	
   914	    # ── PR identity: explicit --pr wins, but only after matching it against the receipt.
   915	    pr_number = None
   916	    if pr_arg:
   917	        m = re.search(r"/pull/(\d+)|^#?(\d+)$", str(pr_arg).strip())
   918	        pr_number = (m.group(1) or m.group(2)) if m else None
   919	        if not pr_number:
   920	            print(f"jog: --pr expects a PR number or URL, got {pr_arg!r}", file=sys.stderr)
   921	            sys.exit(2)
   922	    else:
   923	        pr_number = (receipt.get("pr") or {}).get("number")
   924	        if not pr_number:
   925	            print(f"jog: receipt for {record['execution_id']} has no PR identity — pass "
   926	                  f"`--pr <N|URL>` after opening one from its branches "
   927	                  f"(head={receipt.get('head_branch')}, base={receipt.get('base_branch')})",
   928	                  file=sys.stderr)
   929	            sys.exit(2)
   930	
   931	    # ── Step 1: verify GitHub truth against the execution receipt.
   932	    pr, err = _gh_pr_view(root, pr_number)
   933	    if pr is None:
   934	        print(f"jog: could not verify PR #{pr_number}: {err}", file=sys.stderr)
   935	        sys.exit(2)
   936	    checks = [
   937	        ("state MERGED", pr.get("state") == "MERGED"),
   938	        (f"base {receipt.get('base_branch')}", pr.get("baseRefName") == receipt.get("base_branch")),
   939	        (f"head {receipt.get('head_branch')}", pr.get("headRefName") == receipt.get("head_branch")),
   940	        (f"head SHA {str(receipt.get('head_sha') or '')[:8]}",
   941	         pr.get("headRefOid") == receipt.get("head_sha")),
   942	        ("receipt repo is this repo",
   943	         not receipt.get("target_repo", {}).get("path")
   944	         or os.path.realpath(receipt["target_repo"]["path"]) == os.path.realpath(root)),
   945	    ]
   946	    gate = receipt.get("gate") or {}
   947	    checks.append(("gate green on the landed head",
   948	                   gate.get("result") == "green"
   949	                   and (not gate.get("receipt_path") or os.path.isfile(gate["receipt_path"]))))
   950	    merged_sha = ((pr.get("mergeCommit") or {}).get("oid")) or None
   951	    checks.append(("merge commit present", bool(merged_sha)))
   952	    failed = [name for name, ok in checks if not ok]
   953	    if failed:
   954	        print(f"jog: refusing to land GH-{gh_num} via PR #{pr_number} — failed verification: "
   955	              f"{', '.join(failed)}", file=sys.stderr)
   956	        sys.exit(2)
   957	    base_ref = pr.get("baseRefName")
   958	    reach = subprocess.run(["git", "merge-base", "--is-ancestor", merged_sha, base_ref],
   959	                           cwd=root, capture_output=True)
   960	    if reach.returncode != 0:
   961	        print(f"jog: merge commit {merged_sha[:8]} is not reachable from '{base_ref}' — refusing "
   962	              f"to land GH-{gh_num}", file=sys.stderr)
   963	        sys.exit(2)
   964	
   965	    # ── Step 2: persist the landing projection (idempotent by key).
   966	    state = jog_load_state(root, gid)
   967	    entry = next((e for e in state.get("executions") or []
   968	                  if e.get("execution_id") == record["execution_id"]), None)
   969	    if entry is None:
   970	        print(f"jog: ledger lost execution {record['execution_id']} — refusing to land",
   971	              file=sys.stderr)
   972	        sys.exit(2)
   973	    landing = entry.setdefault("landing", {})
   974	    key = {
   975	        "repo": (receipt.get("target_repo") or {}).get("origin_url") or root,
   976	        "gid": gid,
   977	        "execution_id": record["execution_id"],
   978	        "merged_sha": merged_sha,
   979	    }
   980	    if landing.get("key") != key:
   981	        landing.update({
   982	            "key": key,
   983	            "pr_number": int(pr_number),
   984	            "pr_url": pr.get("url"),
   985	            "merged_at": pr.get("mergedAt"),
   986	            "landed_via": "jog land",
   987	            "landed_at": _dt.datetime.now(_dt.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
   988	        })
   989	        jog_save_state(root, gid, state)
   990	        jog_set_status(root, gh_num, "completed",
   991	                       failure_reason=f"landed via PR #{pr_number} (merged {merged_sha[:8]})")
   992	        print(f"jog: GH-{gh_num} landed — PR #{pr_number} merged into {base_ref} at {merged_sha[:8]}")
   993	    else:
   994	        print(f"jog: landing projection already recorded for PR #{pr_number} — replaying "
   995	              f"missing steps only")
   996	
   997	    # ── Step 3: delegate lifecycle closeout to wave_reconcile.py (idempotent).
   998	    if landing.get("reconciled"):
   999	        print(f"jog: GH-{gh_num} already reconciled at {landing.get('reconciled_at')} — nothing to do")
  1000	        return 0
  1001	    manifest = {
  1002	        "prs": [{
  1003	            "number": int(pr_number),
  1004	            "title": pr.get("title") or f"GH-{gh_num}",
  1005	            "state": "MERGED",
  1006	            "mergedAt": pr.get("mergedAt"),
  1007	            "mergeCommit": {"oid": merged_sha},
  1008	            "baseRefName": pr.get("baseRefName"),
  1009	            "headRefName": pr.get("headRefName"),
  1010	            "body": pr.get("body") or f"Closes #{gh_num}",
  1011	        }],
  1012	        "source": "jog land (verified gh pr view)",
  1013	    }
  1014	    exec_dir = _jog_exec_dir(root, gid, record)
  1015	    os.makedirs(exec_dir, exist_ok=True)
  1016	    manifest_path = os.path.join(exec_dir, "wave-manifest.json")
  1017	    with open(manifest_path, "w", encoding="utf-8") as f:
  1018	        json.dump(manifest, f, indent=2)
  1019	        f.write("\n")
  1020	    # The tree is never pristine here (jog's own tracked releases.db/sql writes), and the pull/
  1021	    # branch checks belong to an operator's working context, not this supervised closeout; the
  1022	    # offline manifest carries the PR truth verified seconds ago, so no second network fetch.
  1023	    reconcile_py = os.path.join(harness_home(), "utils", "py", "wave_reconcile.py")
  1024	    proc = subprocess.run(
  1025	        [sys.executable, reconcile_py, "--root", root, "--pr", str(pr_number),
  1026	         "--offline", manifest_path, "--skip-pull", "--skip-branch-check", "--allow-dirty"],
  1027	        cwd=root)
  1028	    if proc.returncode != 0:
  1029	        print(f"jog: wave_reconcile exited {proc.returncode} — landing is recorded; re-run "
  1030	              f"`jog land GH-{gh_num}` to resume reconciliation at this step", file=sys.stderr)
  1031	        sys.exit(6)
  1032	
  1033	    # ── Step 4: persist reconciliation evidence.
  1034	    state = jog_load_state(root, gid)
  1035	    for entry in state.get("executions") or []:
  1036	        if entry.get("execution_id") == record["execution_id"]:
  1037	            entry.setdefault("landing", {}).update({
  1038	                "key": key,
  1039	                "reconciled": True,
  1040	                "reconciled_at": _dt.datetime.now(_dt.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
githooks/pre-push:90:# These routes are intentionally narrow: a force push, an unavailable remote base, a URL push,
githooks/pre-push:104:# local tracking ref: a backward force-push of the integration branch leaves the tracking ref
githooks/pre-push:142:    # partial output is indistinguishable from a complete answer unless the status says so.
githooks/pre-push:239:  # worker-nice pin on EVERY push. Resource policy belongs to validate.sh (GH-35's own rule).
githooks/pre-push:265:    _rc=$?
githooks/pre-push:283:      _rc=$?
githooks/pre-push:299:    _rc=$?
githooks/pre-push:304:pre-push: $_gate_name RED (exit $_rc) after $((SECONDS - _start))s — push REFUSED.
utils/ci-route.sh:10:# deterministic policy owned by this registry; resource policy (worker count, nice) is
utils/ci-route.sh:22:# be registered in validate.sh's TESTS array — test/gh35-test-tiers.sh enforces both, because
utils/ci-route.sh:25:SUBSYSTEM_TESTS_hq="hq.sh hq-park.sh hq-park-synthesis.sh hq-dispatch.sh hq-next.sh hq-locator.sh hq-hardening.sh hq-promote.sh hq-marathon-scan.sh hq-rollup.sh hq-marathon-live.sh gh238-hq-releases-mode.sh gh239-hq-status-releases-mode.sh"
utils/ci-route.sh:27:SUBSYSTEM_TESTS_telemetry="xyz-completion.sh gh358-lock-instrumentation.sh archive-telemetry.sh gh496-telemetry-isolation.sh"
utils/ci-route.sh:30:SUBSYSTEM_TESTS_pdda="gh649-pdda-migration.sh pdda-changelog.sh pdda-install-startup-docs.sh pdda-roadmap-coverage.sh pdda-repo-contract.sh pdda-local-checks.sh gh400-acceptance-fidelity.sh gh400-source-url.sh gh422-backfill-source-url.sh gh425-source-url-slug.sh wave-reconcile.sh gh202-wave-reconcile-issue-state.sh gh232-wave-reconcile-multiphase.sh gh358-wave-reconcile-vendored-paths.sh gh496-phase2-reconciliation-views.sh"
utils/ci-route.sh:103:  # fail-closed path is already tested, so a force-push or a new branch does not need its own.
utils/ci-route.sh:136:    local diff_rc=0
utils/ci-route.sh:137:    git diff --no-renames --quiet HEAD -- validate.sh 2>/dev/null || diff_rc=$?
utils/ci-route.sh:138:    if [ "$diff_rc" -eq 0 ]; then
utils/ci-route.sh:146:    elif [ "$diff_rc" -eq 1 ]; then
utils/ci-route.sh:287:  # GH-487: TESTS-RESULTS receipts join the evidence side — a provenance.jsonl follow-up used
utils/ci-route.sh:313:    bin/tick|bin/validate-relay-block|src/*)
utils/ci-route.sh:403:        # A deleted/renamed regression cannot be exercised as a changed-area test.
utils/ci-route.sh:418:# GH-487 co-touch resolution: a claimed dedicated test forces tier 3 when this push touches no

codex
The predicate matches the requested outcome rules, and the Jog change carries the verified SHA directly into the manifest. I’m finishing the producer check; the post-merge attribution guard is unchanged and does not call the modified validator.

exec
/bin/zsh -lc "nl -ba utils/py/express.py | sed -n '275,305p'; nl -ba githooks/pre-push | sed -n '240,302p'; rg -n 'json|receipt|telemetry|result|rc' ci-local.sh utils/ci-route.sh | tail -45; rg -n 'def ship_manifest_items|merge_sha|mergeCommit' utils/py/wave_reconcile.py; nl -ba test/gh496-phase2-reconciliation-views.sh | sed -n '208,230p;280,295p'; rg -n 'provenance.jsonl|validation.jsonl' --glob '"'!TESTS-RESULTS/**'"' --glob '"'!PROJECT/**'"' --glob '"'!test/**'"' --glob '"'!*.md'"' ." in /private/var/folders/z0/92pfvhnn06z2_7hnpdb4kkbw0000gn/T/consult-wt-72136-672l0ujm
 succeeded in 70ms:
./evidence/02-validate-sequential.log:2823:  PASS: provenance.jsonl has baseline + 3 records
./evidence/02-validate-sequential.log:2907:    | improve-loop: provenance: /tmp/il-dogfood.28019/state/provenance.jsonl
./evidence/02-validate-sequential.log:2927:  PASS: provenance.jsonl exists and is non-empty at the default path
./relay-system/2026-09-21/gh656-code-review-092219/gh656-code-review.PROMPT.txt:12:- Trace every producer of pre-merge receipts on `development` (grep for writers of `TESTS-RESULTS/**/provenance.jsonl` / `validation.jsonl` entries with `result`/`status`/`rc`: `utils/py/express.py`, `utils/ci-route.sh`, `utils/py/wave_reconcile.py` qualification receipts, `githooks/pre-push`, tests' fixtures). Would any *legitimate* current producer emit a receipt the new `outcome_ok` predicate now refuses (e.g. `status: "PASS"` with `rc: "0"` as a string, `result: "passed"` with `status: "ok"`, `rc: 0` with `result: null`)?

exec
/bin/zsh -lc "python3 -B -c 'import ast,itertools,pathlib
p='\\''utils/py/wave_reconcile.py'\\''
t=ast.parse(pathlib.Path(p).read_text())
f=next(n for n in t.body if isinstance(n,ast.FunctionDef) and n.name=='\\''validate_pre_merge_receipts'\\'')
b=next(n for n in ast.walk(f) if isinstance(n,ast.If) and ast.unparse(n.test)=='\\''commit_match or pr_match'\\'')
code=compile(ast.Module(body=b.body[:5],type_ignores=[]),p,'\\''exec'\\'')
missing=object(); vals=[missing,None,'\\'''\\'','\\''pass'\\'','\\''passed'\\'','\\''PASS'\\'','\\''fail'\\'','\\''ok'\\'',0,1,False,True,0.0,'\\''0'\\'',[],{}]
n=0
for v in itertools.product(vals,repeat=3):
 e={k:x for k,x in zip(('\\''result'\\'','\\''status'\\'','\\''rc'\\''),v) if x is not missing}
 expected=bool(e) and all((type(x) is int and x==0) if k=='\\''rc'\\'' else (type(x) is str and x in ('\\''pass'\\'','\\''passed'\\'','\\''PASS'\\'')) for k,x in e.items())
 ns={'\\''entry'\\'':e};exec(code,ns)
 assert ns['\\''outcome_ok'\\'']==expected,e
 n+=1
print(str(n)+'\\'' outcome combinations passed'\\'')'" in /private/var/folders/z0/92pfvhnn06z2_7hnpdb4kkbw0000gn/T/consult-wt-72136-672l0ujm
 succeeded in 0ms:
4096 outcome combinations passed

codex
**ANSWER: Correct & minimal.** No concrete receipt shape is mishandled under the specified contract, and I found no existing legitimate producer whose successful outcome becomes invalid.

- **[Pass] GH-656:** `merged_sha` is obtained and reachability-checked at `utils/py/jog_run.py:950`; the single added field at `:1007` carries it into the existing offline manifest. This supplies the evidence consumed by `ship_manifest_items` at `utils/py/wave_reconcile.py:1159`. The expanded fixture checks nonempty membership, exact shipping SHA, and both replay paths (`test/gh280-jog-marathon-adapter.sh:930`).

- **[Pass] GH-657:** `utils/py/wave_reconcile.py:804` requires at least one outcome field and validates **every supplied field**. Present-but-null `rc` correctly refuses. `type(rc) is int` correctly excludes both booleans and floats; `isinstance(rc, int)` would incorrectly admit `False`. All supported positive shapes remain accepted. I executed the actual predicate extracted through AST against 4,096 outcome combinations; all matched the requested contract.

- **[Pass] Producer compatibility:** Express writes integer process return codes with corresponding `pass`/`fail` (`utils/py/express.py:285`). Qualification receipts write `result="pass", rc=0` (`utils/py/wave_reconcile.py:612`). Existing positive fixtures use compatible combined outcomes (`test/gh496-phase2-reconciliation-views.sh:288`) or status-only `PASS` (`test/gh693-lessons-learned-advisory.sh:30`). `utils/ci-route.sh:287` classifies evidence paths; it does not produce these receipts. `githooks/pre-push:258` dispatches gates rather than serializing provenance outcomes. Raw `validation.jsonl` telemetry is not selected by the pre-merge reader (`utils/py/wave_reconcile.py:732`).

  Consequently, `{"status":"PASS","rc":"0"}`, `{"result":"passed","status":"ok"}`, and `{"rc":0,"result":null}` correctly refuse; I found no legitimate successful producer emitting them.

- **[Pass] GH-425 isolation:** `check_provenance_receipts` is untouched (`utils/py/wave_reconcile.py:628`). The predicate is local to `validate_pre_merge_receipts`; the attribution guard does not call it. Existing attribution-only fixtures remain outside the tightened contract.

- **[Should] Delivery evidence:** No code blocker identified. I did not run mutation-heavy shell suites in this read-only consult. Required full qualification and push-gate evidence remain delivery prerequisites under `PROJECT/2-WORKING/GH-656-CLOSEOUT-EVIDENCE.md:80`.

- **[Nit] Optional coverage:** Add `{"result":"pass","rc":null}` and `{"result":"pass","rc":""}` to the committed-receipt matrix (`test/gh496-phase2-reconciliation-views.sh:438`). The implementation already rejects both; these would explicitly pin present-but-invalid `rc` against future refactors.

**RECOMMENDATION:** Approve the code review and proceed with the required gates and PR into `development`; no runtime changes needed.
tokens used
52,907
**ANSWER: Correct & minimal.** No concrete receipt shape is mishandled under the specified contract, and I found no existing legitimate producer whose successful outcome becomes invalid.

- **[Pass] GH-656:** `merged_sha` is obtained and reachability-checked at `utils/py/jog_run.py:950`; the single added field at `:1007` carries it into the existing offline manifest. This supplies the evidence consumed by `ship_manifest_items` at `utils/py/wave_reconcile.py:1159`. The expanded fixture checks nonempty membership, exact shipping SHA, and both replay paths (`test/gh280-jog-marathon-adapter.sh:930`).

- **[Pass] GH-657:** `utils/py/wave_reconcile.py:804` requires at least one outcome field and validates **every supplied field**. Present-but-null `rc` correctly refuses. `type(rc) is int` correctly excludes both booleans and floats; `isinstance(rc, int)` would incorrectly admit `False`. All supported positive shapes remain accepted. I executed the actual predicate extracted through AST against 4,096 outcome combinations; all matched the requested contract.

- **[Pass] Producer compatibility:** Express writes integer process return codes with corresponding `pass`/`fail` (`utils/py/express.py:285`). Qualification receipts write `result="pass", rc=0` (`utils/py/wave_reconcile.py:612`). Existing positive fixtures use compatible combined outcomes (`test/gh496-phase2-reconciliation-views.sh:288`) or status-only `PASS` (`test/gh693-lessons-learned-advisory.sh:30`). `utils/ci-route.sh:287` classifies evidence paths; it does not produce these receipts. `githooks/pre-push:258` dispatches gates rather than serializing provenance outcomes. Raw `validation.jsonl` telemetry is not selected by the pre-merge reader (`utils/py/wave_reconcile.py:732`).

  Consequently, `{"status":"PASS","rc":"0"}`, `{"result":"passed","status":"ok"}`, and `{"rc":0,"result":null}` correctly refuse; I found no legitimate successful producer emitting them.

- **[Pass] GH-425 isolation:** `check_provenance_receipts` is untouched (`utils/py/wave_reconcile.py:628`). The predicate is local to `validate_pre_merge_receipts`; the attribution guard does not call it. Existing attribution-only fixtures remain outside the tightened contract.

- **[Should] Delivery evidence:** No code blocker identified. I did not run mutation-heavy shell suites in this read-only consult. Required full qualification and push-gate evidence remain delivery prerequisites under `PROJECT/2-WORKING/GH-656-CLOSEOUT-EVIDENCE.md:80`.

- **[Nit] Optional coverage:** Add `{"result":"pass","rc":null}` and `{"result":"pass","rc":""}` to the committed-receipt matrix (`test/gh496-phase2-reconciliation-views.sh:438`). The implementation already rejects both; these would explicitly pin present-but-invalid `rc` against future refactors.

**RECOMMENDATION:** Approve the code review and proceed with the required gates and PR into `development`; no runtime changes needed.
