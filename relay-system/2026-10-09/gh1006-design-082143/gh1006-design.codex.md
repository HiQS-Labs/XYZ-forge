**NO FIRSTHAND VERIFICATION CITED** — treat conclusions as conditional (codex's answer carries an unsupported [Pass]/verified/confirmed-style claim with no quoted span or file:line citation nearby, despite the consult PREAMBLE asking advisors to cite evidence.)

> **ATTESTATION**
> Model: gpt-6-astra
> Provider: openai
> Sandbox: read-only

Reading additional input from stdin...
2026-10-09T15:21:50.274315Z ERROR codex_models_manager::manager: failed to refresh available models: request timed out
2026-10-09T15:21:50.322943Z  WARN codex_skills::interface: ignoring interface.icon_small: icon path with '..' must resolve under plugin assets/
2026-10-09T15:21:50.322971Z  WARN codex_skills::interface: ignoring interface.icon_large: icon path with '..' must resolve under plugin assets/
2026-10-09T15:21:50.335561Z  WARN codex_core::agents_md: project doc exceeds remaining budget; truncating path=file:///private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-13569-zsltpsy2/AGENTS.md remaining_bytes=32768
OpenAI Codex v0.159.1
--------
workdir: /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-13569-zsltpsy2
model: gpt-6-astra
provider: openai
approval: never
sandbox: read-only
reasoning effort: high
reasoning summaries: none
session id: 01a12141-8834-7f81-be05-20e916b30fe4
--------
user
You are an INDEPENDENT advisor in a one-shot cross-model consult. Another model is answering the SAME question separately and a coordinator will reconcile both answers, so give your own honest, specific read — do not hedge toward a consensus you cannot see. Read any repo files the question references (cite file:line). Respond with: (1) a short direct ANSWER; (2) graded FINDINGS — [Blocker]/[Should]/[Nit]/[Pass] — where applicable; (3) a one-line RECOMMENDATION. You are ADVISORY ONLY: output your analysis as text; do not rely on writing files (you are running in a throwaway copy).

=== CONSULT QUESTION ===
# GH-1006: bounded unattended marathon progress and safe minor repairs

Advisory only; do not edit, run tests, dispatch builders, or change git state. Read current source in this isolated checkout. Operational envelope: local macOS developer harness, one authorized marathon, existing driver locks/attempt caps/containment, no daemon or parallel executor, no new test suites/gate machinery (GH-831). Grade commensurate complexity.

The operator asks to refine https://github.com/HiQS-Labs/XYZ-forge/issues/1006 and then implement via start-task. Original issue: opt-in 600-second interval x6 read-only observation checks; snapshot identity, phase/role, heartbeat age, qualifying progress, phase counts, gate/review, pointers; immediate terminal report/cancellation; explicit window end; no restart or cap bypass. New intent: meaningful progress during hours away; minor harness correction -> reviewed PR -> continue marathon from that PR. Suggests three-agent consult vote before repairing/refiring. Completion cannot be guaranteed.

Current source: relay-automation/marathon.sh owns the ordered chain, blocks on each child and halts on failure. utils/py/marathon_drive.py owns bounded single-phase execution, driver heartbeat, receipts, some existing timeout/already-satisfied recovery. utils/py/consult.py supports codex,agy,claude advisory seats. utils/py/jog_run.py owns explicit receipt reconciliation and retry verbs. Read relevant portions plus AGENTS.md and GUIDING-PRINCIPLES.md. Knowledge graph generation 2026-09-01 is stale for Python driver/consult/rtl: direct source is authoritative. This is a bounded task-directed Verify trace, not an exhaustive audit.

External dependency: open PR #1004 fixes GH-1001/GH-1002 in harness_paths.py, marathon_drive.py, relay-turn-lib.sh; head 51ec2ba59b13a10ac3d8c370b19aae2fa51225f0 targets development. Do not duplicate or assume it merged. Consumer recovery cannot ignore its existing defects.

Proposed policy to challenge: preserve observation as default; explicit bounded recovery opt-in with launch-time budget and deadline. Product progress = accepted deliverable + relevant verification, not heartbeat/log/token traffic. Preparation progress = reviewed repair PR or reproducible blocker handoff, separately reported. A consult advises whether diagnosed local repair is worth trying; deterministic constraints veto regardless of vote. At most one repair episode per run by default, no reset by fresh execution/token. Stop original child, establish exclusive ownership, repair canonical Forge in separate full clone, independently QA and verify exact commit, publish PR against development. Resume only on explicit launch-time permission for unmerged dependency; pin immutable repair SHA in isolated per-run harness, preserve old receipts/attempt identity, no hot-patching active installed harness; no automatic merge. Otherwise park after PR. Exclude locks/containment/gate semantics, schemas, deletion, auth/network bridges or scope expansion from 'minor'. Genuine review cap is a product/escalation outcome, not automatically a machinery defect. Use existing progress/run-log and start-task/relay machinery rather than implement a generic autonomous repair controller.

Questions (answer every one):
1. Is the safe minimum monitoring plus a skill-driven bounded recovery procedure, or is a runtime recovery controller justified now? Where precisely should monitoring live to avoid a second executor and preserve chain-wide x6 timing?
2. Can PR-based continuation be supported safely within current contracts? Which missing primitive blocks it? Distinguish already-supported actions from desired additions.
3. Is 'three-agent vote' useful? Specify evidence, disagreement/abstention treatment and why votes cannot override safety predicates. Recommend unanimity or majority with reasons.
4. Propose concrete repair eligibility, shared budgets/deadline, stop cases and definition of meaningful progress. Identify requirement conflicts (one-hour observation vs several-hour recovery; immediate halt reporting vs explicit recovery).
5. Give a surgical ordered implementation boundary, precise existing paths, falsifiable checks/red controls (existing suites/manual receipts only), risks/rollback. Name any unsupported guarantee or unresolved decision.

Return reconciled-design input with Agree / Disagree / Blocking / Optional / Skip items and file:line citations. Keep it under 1500 words. Do not give an approval without grounding it. Each model is one independent advisory seat; no build authorization comes from your vote.

hook: SessionStart
hook: SessionStart Completed
codex
I’ll ground this advisory in the current chain, driver, consult, and retry contracts, then separate the safe minimum from the primitives PR-based continuation still needs.

exec
/bin/zsh -lc "pwd; rg --files -g 'ROUTER.md' -g 'AGENTS.md' -g 'GUIDING-PRINCIPLES.md' -g 'WORKTREE-SAFETY.md'; cat ROUTER.md" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-13569-zsltpsy2
 succeeded in 0ms:
/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-13569-zsltpsy2
WORKTREE-SAFETY.md
GUIDING-PRINCIPLES.md
AGENTS.md
ROUTER.md
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
- If the task is blocked by a failing test, unexpected error, or disputed requirement, invoke the `sanity-check` skill (`skills/1-hourly/sanity-check/SKILL.md`) to establish whether the obstacle must block the goal before spending hours debugging or repairing it.
- If the task is about **managing skills for the system** — adding a skill to the machine-wide collection, deploying/refreshing/removing it across the configured app targets (`targets.json`, machine-local), or asking what is deployed — the mechanism is the `skills-army-hq` skill (`skills/3-weekly/skills-army-hq/SKILL.md`). Forge authors its own skills in `skills/`, Skills Army HQ included; XYZ-skills-army-mini and the other standalone repos are published children (`push-downstream`, GH-955). Intake accepts any local folder. The durable collection lives wherever `XYZ_SKILLS_ROOT` points (machine-local, never committed; falls back to `~/git-pulse-sync/Deployed Skills`), and only `intake.py` / `sync.py` mutate it or the app symlinks. Never hand-copy a skill folder into an app's skills directory.
- Issue-first SOP: any change beyond a 2–3 line fix (and every project plan) opens a GitHub issue *first*, then gets a pointer doc named after the issue at `PROJECT/1-INBOX/GH-<number>-VERY-SHORT-DESC.md` — e.g. `GH-1234-SHOWME-COMMAND.md` — and that capture is parked in the roadmap ledger queue immediately via `releases roadmap add` (format + lifecycle owned by `PROJECT/PDDA.md` → "GitHub issue intake"), following the normal `1-INBOX` → `2-WORKING` flow. Genuinely trivial edits (≤2–3 line fixes, typos, path repoints, doc-only one-liners) are exempt and commit directly.

exec
/bin/zsh -lc 'cat /Users/noelsaw/.codex/skills/swe/SKILL.md; cat /Users/noelsaw/.codex/skills/recon/SKILL.md' in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-13569-zsltpsy2
 succeeded in 0ms:
---
name: swe
description: Apply software-engineering standards when authoring or reviewing project plans, build/spec/PRD documents, architecture RFCs, or agent governance. Use for "write a plan", "review this build doc", "apply our SWE standards", or "is this plan ready to build"; also apply before drafting a project plan. Grades grounded recon, minimal scope, diagnosis, blast radius, and verifiable acceptance. This is a planning rubric, not a debugging or execution pipeline.
---

# SWE

Vibe the build; engineer the plan. This lens is the discipline that lets a fast v1.x ship without becoming a liability.

A governance overlay for **build/spec documents** — the "build v1.x" doc, the implementation spec, the architecture RFC. It does not debug code or pick a tradeoff in the moment; it reads the *plan* and asks whether the plan already embodies the engineering standards before a single line is written. Run it two ways: as an **authoring gate** (write the doc against it) or as a **review rubric** (read a doc, emit findings + a verdict). The whole bet: most plans fail not on the feature but on the five things below, smuggled past in prose — starting with Pillar 0, where the plan is grounded (or not) in the system as it actually exists.

## Pillar 0: Recon — is the plan grounded in a system anyone actually read?

The four pillars grade what the document *says*. Pillar 0 grades its **provenance**: was it written against the system as it exists, or from the prompt plus three grepped files? This pillar is about evidence, not consequences — what breaks when a *step* runs is Blast's job, below.

- [ ] The current system was traced before the first plan heading: entry points and call paths in, every read *and write* site of the state involved, the contracts crossed, the failure and rollback paths today.
- [ ] Claims about what the change touches cite code somebody read — `file:line`, not "various downstream."
- [ ] What could not be verified is listed as an explicit unknown with the command or file that would settle it, never smoothed into the findings.

**Applicability first.** Pillar 0 does not apply to greenfield work, a non-code plan, or a change contained to files the doc already quotes — mark it N/A and say why. Where it does apply, grade the *evidence*, not the artifact: a [recon](../recon/SKILL.md) Recon Map is the standard form, but a trace embedded in the doc or supplied by the author counts. **Block** only when the doc makes claims about an existing system that nothing behind it verifies; a thin trace on a genuinely small change is a **Fix**, not a Block.

**Pillar 0 feeds Blast; it does not satisfy it.** The trace establishes the *current-state* radius — who depends today on what the plan touches. Blast then asks what each proposed step *adds*: new systems, new data, new people, the shield, the tripwire, the undo class. Copying the map's radius into the Blast section unchanged understates the plan's own impact and fails Blast on its own terms.

## The four pillars

Each pillar is a lens on the document. A v1.x doc that satisfies a pillar contains the thing explicitly; a doc that "implies" it fails the pillar — implied is unbuilt.

### 1. Minimal (Ponytail) — does the plan earn each part it adds?

The plan's default answer to "add a thing" is *no*. Scope, dependencies, and abstractions are all liabilities until justified in the doc.

- [ ] Every new component answers "does this need to exist?" (YAGNI) — speculative scope is cut or deferred, not built.
- [ ] Sourcing ladder is honored to minimize mechanism, not requirements: stdlib → native platform feature → already-installed dep → one line of our own. A new dep names what it buys that the rung above does not. (Security and observability requirements are never simplified away, only implemented via the laziest viable mechanism).
- [ ] No premature abstraction — the plugin layer / framework / generic engine is justified by ≥2 concrete present uses, not one hypothetical future one.
- [ ] Bias is stated: delete > add, boring > clever, shortest diff that works. A complexity cap is named (e.g. stdlib-only, ~600-line ceiling) where it applies.

*Planning translation:* this is the editor pass on scope. Most v1.x bloat is decided here, in the doc, long before code.

### 2. Diagnosable (Mantra) — does the plan say how it will fail and be found?

A build doc that provisions zero observability is a debugging session deferred to production. Bake the diagnosis path into v1.x, not v1.next.

- [ ] Instrumentation is right-sized but explicit: a single actionable error log is better than an unread ELK stack, but silent failures are blocked. The plan names the exact log, metric, or alert that fires when it breaks.
- [ ] Every iterate/retry loop has a **stop condition** (e.g. 5-failure hard stop, 10-total cap). An unbounded "retry until it works" is a defect in the plan.
- [ ] Failures are made reproducible: the plan names how a failure is repro'd, and treats intermittent failure as a *signal* (concurrency / ordering / env / TOCTOU), not noise to retry away.
- [ ] State changes are auditable — append-only event log over in-place mutation where the history matters.
- [ ] **The plan names debug-mantra as its execution-time debugging protocol** — "we'll figure it out when it breaks" is a Diagnosable failure.

*Planning translation:* the runtime debugging ritual, pulled forward. If the doc can't say how you'll see it break, you'll see it break in prod.

### 3. Blast — does the plan price its irreversible moves before committing?

For every wide-impact or hard-to-undo step, the doc must already carry the cost. Don't dress a one-way door as a tweak.

- [ ] Each risky step names its **undo class**: easy / costly / one-way door. One-way doors are flagged, never silent.
- [ ] **Blast radius** is named — the exact systems, data, and people that break if this step goes wrong (not "various downstream").
- [ ] A **shield** is specified — flag, adapter, pilot/canary, dual-write, or an explicit "none."
- [ ] A **tripwire** exists for anything costly or one-way: *how* you'll know to pull it and *by when* (the point of no return). A shield with no tripwire is a brake with no warning light.

For the full per-decision accounting, defer to the **blast-radius** skill — this pillar only enforces that the v1.x doc *contains* that accounting for its irreversible steps.

### 4. Proof (Done) — can the plan prove it's finished, separately from claiming it?

Editor and grader are different roles. The plan must define "done" in terms something other than the author can check.

- [ ] Every task has a **measurable done-criterion** — a checkable output or metric, not "works" / "improved" / "robust."
- [ ] Tests are specified *and the plan requires they actually run* — "tests pass" means an execution artifact, not an assertion.
- [ ] **No orphan tasks**: every step maps to a success criterion, and every success criterion is covered by a step.
- [ ] **Closed loop**: For medium/large efforts, backend/data work must explicitly connect to a user-facing UI plane or final consumer. Fetching data without surfacing it to the user is an incomplete loop.
- [ ] **Observed vs. predicted is kept separate** — the doc never launders a projection ("this will reduce load 40%") as evidence. Predictions are labeled as such.

*Planning translation:* PlanProof's editor/grader separation at document scale. The grader reads only what's written, not what the author meant.

## House invariants

Non-negotiable conventions a v1.x doc must satisfy regardless of pillar. These are cheap to check and expensive to skip.

- [ ] **FSM threshold** — model an explicit state machine only past ~4 states; below that a flag or enum is leaner. Past it, an ad-hoc tangle of booleans is the defect.
- [ ] **Single write path** — one writer per piece of state. Multiple write paths to the same table/file are a race waiting to happen; name the single path.
- [ ] **Append-only event log** only when audit or history is an explicit business requirement (JSONL or equivalent); otherwise, simple in-place updates are the default.
- [ ] **UTC-only** time handling end to end; local time only at the display edge. "Nightly," "daily," "expires in 24h" all imply a timezone — pin it.
- [ ] **Crash-safe / idempotent jobs** — cron and background work are resumable and safe to run twice. A job that corrupts state on a mid-run crash is unshipped.
- [ ] **Checklist standard** — actionable items use the `- [ ]` hyphen prefix in GitHub-flavored Markdown, never bare `[ ]` in tables or lists.
- [ ] **Agent contract current** — for agent-built work, AGENTS.md / CLAUDE.md exists and matches the plan (conventions, loop caps, honesty constraints). The project's AGENTS.md must name SOLID compliance as a coding standard; if it doesn't, the plan has no enforceable code-design contract.

## Zero-Downtime Expand-Contract Schema & State Migration Rubric

When planning online schema changes, state re-encodings, or persistent data migrations across rolling deployments or mixed-version clients, the plan must budget lock/backfill rates, define stop/rollback tripwires, and enforce the 6-stage lifecycle:

1. **Stage 1 — Expand:** Add the new column, field, or data store as nullable or optional, with concurrent write synchronization in place so new writes populate both shapes without breaking existing readers.
2. **Stage 2 — Backfill & Continuous Sync:** Execute an idempotent, rate-limited background backfill. Any concurrent updates occurring during the backfill and mixed-version window MUST reach the new representation with an explicit conflict/ordering strategy.
3. **Stage 3 — Convergence Gate:** Run an automated parity/reconciliation assertion verifying data convergence across old and new representations before cutting over read traffic.
4. **Stage 4 — Switch Reads:** Redirect query and read paths to the new representation, retaining graceful fallback to the legacy shape if read errors occur.
5. **Stage 5 — Dual-Write & Mixed-Version Support:** Continue bidirectional synchronization / updating both representations for every representation still read by active versions, offline clients, or needed by application rollback throughout the entire mixed-version window.
6. **Stage 6 — Contract & Retire:** Ending legacy updates and dropping legacy fields/columns is strictly gated on:
   - (a) Full retirement and migration of all legacy writers.
   - (b) Full retirement of all legacy readers.
   - (c) Full retirement of delayed, queued, or asynchronous consumers.
   - (d) Closure of the application rollback window (or verified reverse synchronization if rollback occurs).

---

## How this differs from the sibling skills

- **swe** — "Does this *plan* embody our engineering standards before we build?" The standard/rubric, applied to a whole document.
- **recon** — "What is actually there?" The read-only trace of the current system that Pillar 0 grades the doc against. It supplies the current-state radius; Blast extends that radius per proposed step. Run recon first in author mode when the plan changes an existing system.
- **phase-0-spike** (an external workflow at `~/.claude/workflows/phase-0-spike.js`, not a skill in this repo) — the deep seam map, contract owners, and rollout invariants for a refactor that is already committed to. `recon` is the cheap universal pass before any plan; phase-0-spike is the expensive one after the refactor is approved. A v1.x doc for a subsystem refactor cites one or the other, never neither.
- **plan-adversarial-serial** — the *pipeline* (generate → review → revise → review → judge). It is the machinery; `swe` is one of the standards the machinery can enforce. Compose them: run the adversarial pipeline with `swe` as the lens content.
- **blast-radius** — "How big is *this one decision* and what breaks?" `swe`'s Blast pillar defers per-decision accounting to it.
- **iron-triangle** — "Which of speed/cost/quality is *this choice* trading?" When a plan forces fast/cheap/good tension, hand that node to it.
- **debug-mantra** — the four-step runtime debugging discipline (reproduce → fail path → falsify → breadcrumb). Diagnosable enforces the plan names it; debug-mantra governs live execution — composing across the doc/session boundary.
- **take-a-step-back** — "Is this the right problem/frame at all?" Runs *before* there is a plan to govern.
- **bottom-line** / **linear** — compress or sequence output. `swe` evaluates a plan's substance; those reshape its presentation.

Reach for `swe` the moment there is a build/spec document to hold to a standard — authoring one or judging one.

## How to apply

**Author mode** — you are writing the v1.x doc. Clear Pillar 0 first (run recon, or state why it was skipped), then use the four pillars and house invariants as the doc's skeleton: each feature passes Minimal before it earns a section; each risky step ships with its Blast block; each task ships with its Proof criterion. The lens is the gate, not a later edit.

**Review mode** — you are handed a v1.x doc. Walk Pillar 0, then the four pillars, then the invariants. For each gap, emit one finding keyed to the doc location (`§section`, or `file:line` for code-adjacent specs), tagged by severity, with the *cheapest* fix first. Close with a verdict. Do not rewrite the doc unless asked — surface the checkable gaps and let the author act.

## Project plan scaffold (Author mode)

When the ask is "write a project plan" / "write a plan" (authoring, not reviewing), clear Pillar 0 first, build the doc against the four pillars **and** lay it out in the fixed structure below. The structure is load-bearing, not decoration: the status table forces an honest "where are we" at a glance, the Table of contents keeps a long plan navigable, observable checklist items *are* the Proof done-criteria, and the per-phase QA checklist is the grader pass made mechanical. Implied is unbuilt — so every field below is written down, not assumed.

Required order, top to bottom: **frontmatter → status table → table of contents → phases (each with observable todos) → per-phase QA checklist**.

````markdown
---
title: <Project> — Build Plan
status: Not started | In progress | Blocked | Shipped
owner: <name>
created: <YYYY-MM-DD>   # UTC
updated: <YYYY-MM-DD>   # UTC — bump every time the plan changes
reversibility: Easy | Costly | One-way door — <one line of why>
---

# <Project> — Build Plan

| Most recently completed phase | What's next |
| --- | --- |
| — (not started) | Phase 1: <name> |

## Table of contents
- [Phase 1: <name>](#phase-1-name)
- [Phase 2: <name>](#phase-2-name)
- [Phase 3: <name>](#phase-3-name)

## Phase 1: <name>
**Goal:** <one observable outcome this phase delivers — not "work on X">

- [ ] <observable todo: names a checkable output or artifact>
- [ ] <observable todo>
- [ ] <observable todo>

### Phase 1 — QA checklist
- [ ] Every todo above produced its checkable output (no orphan tasks)
- [ ] Tests **run**: existing suites, plus new ones only where the repo allows them. Where it does not (XYZ-forge: `AGENTS.md` *No new tests*, GH-831) and no existing suite covers the change, a manual check recorded under `TESTS-RESULTS/` counts. Point to the execution artifact, not an assertion
- [ ] Diagnosable: logs + correlation id present; every loop has a stop condition
- [ ] Blast: each risky step names undo-class + shield + tripwire (or explicit "none")
- [ ] Status table and `updated:` date refreshed before this phase is marked done

## Phase 2: <name>
...
````

Filling it:

- **Frontmatter** — the at-a-glance contract. Keep `status`, `updated`, and `reversibility` honest; a stale `updated` date is the first sign the plan drifted from reality.
- **Status table** — exactly two columns, one row. It is the single source of truth for "where are we"; update it as the *last* step of finishing a phase, never before. Don't expand it into a multi-row log — that's what phases are for.
- **Phases** — split by observable milestone, not by calendar. Apply the Minimal pillar to phase count too: only as many phases as the work earns. Each phase has one `**Goal:**` line stating the outcome it delivers.
- **Observable todos** — every `- [ ]` names a checkable output, not an activity. "Add retry cap of 5 to the reconciler loop" passes; "improve reliability" fails. Use the `- [ ]` hyphen prefix (house Checklist standard), never bare `[ ]`.
- **Per-phase QA checklist** — closes each phase against the four pillars. It is Proof's editor/grader separation per phase: the boxes are checked by running things, not by the author asserting done. A phase isn't complete until its QA checklist is.

## Output format (Review mode)

Lead with the verdict in one line. Then findings, ordered by severity, then quick wins first within a severity. Keep it tight — clean plans get a short list, not a manufactured one.

**Verdict:** **Ship** · **Ship with conditions** · **Block** — [one sentence: the load-bearing reason].

**Findings:**

| Loc | Pillar | Severity | What breaks | Cheapest fix |
| --- | --- | --- | --- | --- |
| §x.y | Blast | Block | One-way migration with no rollback named | Add a dual-write window + a row-count tripwire before cutover |
| §x.z | Proof | Fix | "Improves sync" has no done-criterion | State the measurable signal (e.g. drift count → 0 over 3 runs) |

Severity: **Block** (cannot build safely as written — unguarded one-way door, no done-criteria, unbounded loop) · **Fix** (change before v1.x ships) · **Note** (improvement, optional).

**Quick wins:** [the 1–3 findings fixable in a line of doc, listed as `- [ ]` so the author can tick them off.]

## Principles

**Implied is unbuilt.** A plan gets credit only for what it states. "Obviously we'll log it" is a Diagnosable failure; write it down or it won't exist.

**Editor and grader are different roles.** The strongest constraint in the whole lens is Proof's separation: done is defined by something the author can't fudge. Keep them apart.

**Price the one-way doors loudest.** Reversible mistakes are cheap; irreversible ones are the only ones worth slowing down for. A tweak that can't be undone is not a tweak.

**Cut scope before breaking a corner.** When the plan is overloaded, the Minimal pillar and scope-reduction beat heroics. Defer to `iron-triangle` when the tension is explicitly fast/cheap/good.

**Stop conditions are not optional.** Any loop in the plan — retry, fix-iterate, agent relay — names its cap. Unbounded means undefined.

**Separate what you saw from what you expect.** Observed evidence and predicted behavior are different epistemic objects; a plan that blends them is lying to its future reader.

**Don't manufacture findings.** A genuinely clean v1.x doc gets "Ship" and a short list. The lens enforces a standard, not a quota of objections.

## Example — reviewing a v1.x build doc excerpt

Input (abridged):

> **§3 Nightly order reconciler.** A cron job runs each night to reconcile order state against the upstream system. For each order it pulls upstream status and updates `wp_orders` to match. On mismatch it retries until the write succeeds. This makes order state reliable.

Output:

> **Verdict:** **Block** — a nightly DELETE/UPDATE against the orders table with an unbounded retry, no tripwire, and no measurable "reliable" can corrupt order state with no way to know or stop it.
>
> **Findings:**
>
> | Loc | Pillar | Severity | What breaks | Cheapest fix |
> | --- | --- | --- | --- | --- |
> | §3 | Diagnosable | Block | "retries until the write succeeds" is an unbounded loop | Add a 5-failure hard stop / 10-total cap, then dead-letter the order |
> | §3 | Blast | Block | Bulk overwrite of `wp_orders` is costly-to-one-way with no shield/tripwire | Run in observe mode first; add a row-count + mismatch-rate tripwire before any write mode |
> | §3 | Proof | Fix | "makes order state reliable" has no done-criterion | Define it: drift count → 0 across 3 consecutive runs, logged |
> | §3 | House (UTC) | Fix | "each night" has no timezone | Pin the schedule to UTC; document the local display offset separately |
> | §3 | House (write path) | Note | Reconciler is a second writer to `wp_orders` | Name the single write path, or gate the reconciler behind the same one |
>
> **Quick wins:**
> - [ ] Add the loop cap (§3) — one clause.
> - [ ] Pin "each night" to UTC (§3) — one word.
> - [ ] Replace "reliable" with the drift-count criterion (§3) — one sentence.

## What success looks like

The author sees, before any code exists, exactly where the plan is a wish rather than a build: the loop with no cap, the migration with no rollback, the task that can't prove it's done. The best outcome is a v1.x doc that ships fast *because* its risky parts were priced up front — not one that ships fast and pays later.
---
name: recon
description: >-
  Trace an existing system end to end — entry points, call paths, every read and
  write of the state involved, the contracts crossed, the failure and rollback
  paths — and write it down as a Recon Map before a plan for changing it is
  drafted. Fires when the user asks to plan, spec, design, refactor, migrate, or
  size a change to code that already exists: "write a plan", "plan this out",
  "how should we build X into this", "refactor X", "migrate X", "what would it
  take to change X", "will this break anything". Also self-trigger before you
  write any plan step whose blast radius names code you have not read. Uses the
  codebase-memory knowledge graph when installed, falls back to grep, and fans
  wide traces out across parallel read-only subagents. Produces a Recon Map file
  and hands off. Skip greenfield work with
  no existing system to trace, on a change confined to a file already read in
  full, on a typo or copy edit, on a non-code plan, or when a current Recon Map
  for the same subsystem already exists.
---

# Recon

Read the system before you plan a change to it. A plan written from the prompt plus three grepped files is fiction with headings — its steps reference call paths nobody traced, state nobody inventoried, and contracts nobody knew were there, and its blast radius section is invented. Recon makes the trace a deliverable with named artifacts, produced before the first plan heading.

**The one rule:** no plan step may name a blast radius that includes code nobody read. If a step touches a caller, the caller is in the map at `file:line`. If it cannot be found, it is in the Unknowns list — never silently assumed absent.

## When to run it

**Run recon when** the ask is to plan, design, spec, refactor, migrate, or size a change to a system that already exists, and the change plausibly reaches beyond a file you have already read in full.

**Skip recon when** — the calibration counter-example, and it matters as much as the trigger:

- **Greenfield** — there is no existing system to trace. Recon has nothing to read; go plan.
- The change is confined to a file you have **already read in full** — and one lookup says so. Spend the single call (`search_graph`, or one grep for the symbol name) before claiming this skip; any external reference it returns and the skip does not apply. Asserting the negative without the lookup is the easiest dishonest exit in this list.
- A typo, copy edit, comment, or formatting change.
- The plan is not about code (a process, a doc, a rollout schedule).
- A Recon Map for this subsystem exists and no relevant commit has landed since. Re-read it; do not re-run.
- You traced this exact subsystem earlier in this session, nothing has landed since, and the edges are still in your context. Write the map from what you hold rather than re-running the fan-out.
- The user hands you the edges. Skip the fan-out, not the map: fold their edges into the map, cite them to the user, and mark them `supplied` — unverified until read.

Say "recon skipped — [one-line reason]" and go. A recon on a contained rename whose references are already enumerated is ceremony, and ceremony is how a gate gets ignored when it counts. A rename whose callers are *not* yet enumerated is exactly what recon is for.

## Step 1 — Scope the trace

Name the **subject** in one line: the function, module, table, endpoint, or feature the change lands on. Name the **change class**: local edit, cross-module change, contract change, state/authority change, or replacement. If the class is state/authority, run [spike-360](https://github.com/HiQS-Labs/XYZ-forge/blob/development/skills/4-occasional/spike-360/SKILL.md) first — it decides whether a new source of truth should exist at all; recon maps the system either way once that is settled.

Ask at most one clarifying question. If the subject is ambiguous, pick the likeliest reading, state it, and trace that — **unless the two readings sit on opposite sides of a boundary** (application versus infrastructure, this service versus another). There, guessing wrong spends the whole fan-out on the wrong system, so name both readings and ask.

## Step 2 — Seed from the knowledge graph if it is installed

If the `codebase-memory` MCP server is available, use it first — it answers "who touches this" in one call instead of twenty greps:

- `index_status` / `list_projects` — indexed, and **indexed at what revision?** Compare it to current HEAD and the dirty worktree; an index older than the last relevant commit is a stale lead, and every edge from it is unconfirmed until read. If unindexed and the repo is large, offer `index_repository` once with its cost; if declined, fall through to grep and record the degraded mode in the map.
- `get_architecture` — the shape of the system before the details.
- `search_graph(name_pattern | label | qn_pattern)` — locate the subject's symbols.
- `trace_path(function_name, mode=calls | data_flow | cross_service)` — the edges. This is the tool that earns the skill its name.
- `get_code_snippet(qualified_name)` / `search_code(pattern)` — exact source, and graph-augmented grep for the rest.

**The graph is a lead, not a citation.** Every edge a plan step will depend on gets confirmed by reading the file; an edge that exists only in the graph is marked `graph-only`. Depending on the indexer, it **may miss** config, SQL strings, templates, shell and CI scripts, cron, IaC and deploy manifests, generated code and its generator, database triggers/views/procedures, macros, runtime registries, reflection and dynamic dispatch, and consumers in other repositories. Anything in that list you did not verify by hand is an Unknown — in graph mode and grep mode alike.

No graph installed? Say so in one line and trace with grep, glob, and reads. The output contract does not change.

## Step 3 — Fan out, sized to the radius

Recon is wide, shallow, and parallel — the ideal sub-agent shape. Launch the lanes **in one message so they run concurrently**, each read-only, each returning the Step 4 envelope. Use sub-agents available to the current model through its own runtime and model provider; inherit the current model where supported, without requiring a named model, model lab, or vendor-specific agent type.

Scale the lane count to the radius, and say which you ran: a two-file change with one caller is one lane in your own context; a subsystem with external consumers is all four.

| Lane | Question it answers | Owns |
| --- | --- | --- |
| **A. Entry & call paths** | How does control reach this code? | Callers and entry points — routes, CLI, cron, hooks, event handlers, tests — plus runtime registration, plugin dispatch, reflection, and anything invoked by name from config |
| **B. State & data** | What reads and writes the state involved? | Read sites and *write* sites, active readers and writers, schema, migrations, caches, serialized formats, database triggers/views/procedures, and whether there is a single write path |
| **C. Contracts & boundaries** | What crosses a line if this changes? | Public APIs, exported symbols with external consumers, events/queues, background worker queues, delayed/asynchronous consumers, config keys, env vars, feature flags, cross-service and cross-repository consumers |
| **D. Build, failure & operations** | How is this built, how does it fail, who notices? | Build/CI config and package metadata, generated code and its generator, IaC and deploy manifests, error paths, retries, timeouts, operational tripwires, lock budgets, existing tests covering the subject, logs/metrics/traces, and the reverse-sync rollback path |

Budget each lane: **read-only, no edits, roughly 8 minutes, report what you found and what the budget cut off.** The budget is a prompt instruction, not a timeout — which is exactly why the report-what-you-cut rule is the part that has to hold. An empty lane is a finding, not a failure. Give every lane the same honesty instruction: *`file:line` for everything claimed; anything inferred, unverified, or graph-only is listed as an unknown, never smoothed into the findings.*

No sub-agent capability? Run the lanes serially in the main context, same budget, same schema — and name in the map which lanes you curtailed and where you stopped. Serial is not licence to go shallow; it is licence to record what you skipped.

## Step 4 — What each lane returns

A common envelope plus that lane's own fields from the table above:

```
LANE: <A|B|C|D>
FINDINGS:
  - <file:line> — <what it is> — <why it matters to the change> — [confirmed | graph-only | supplied]
    confirmed = you read the file · graph-only = the index says so, nobody read it · supplied = the user gave it
UNKNOWNS: <what could not be verified, and the one command or file that would settle it>
CUT OFF AT: <where the budget stopped the lane, or "nothing">
```

## Step 5 — Reconcile into the Recon Map

Merge the lanes yourself; do not paste them. Dedupe by `file:line`, resolve contradictions by reading the file, and write the map to `recon-<subject-slug>.md` beside where the plan will live. Long output belongs in the file, never in chat.

```markdown
# Recon Map — <subject>
Commit: <sha> · Mode: <graph+read | grep-only> · Lanes: <which ran>

## Subject and change class
## The seams — where a change here escapes this file
| Seam | Location | Crosses | Breaks if |
## Call paths in
<entry point -> ... -> subject, with file:line>
## State
<read sites / write sites; the single write path, or the fact that there is not one>
## Contracts
<name — consumer — breaking-if — where it is declared>
## Build, failure and rollback today
## Unknowns
| Unknown | Why it matters | What would settle it |
## Current-state radius, one line
<the systems, data, and people that today depend on what this change touches — named, not "various downstream">
```

The Unknowns table is load-bearing. Zero unknowns is an honest result on a small, fully verified subject and a warning sign on a large one — say which case you are in rather than manufacturing a gap to look thorough.

## Step 6 — Hand off

Recon stops at the map. In chat: the verdict line (`Recon complete — N seams, M unknowns, current-state radius: <one line>.`), the file path, the one or two unknowns that would change the plan if they resolve the other way, and the next step.

If the user asked for a plan in the same breath, write it next — recon does not withhold the plan, it grounds it. The plan is a separate artifact from the map, drafted against [swe](../swe/SKILL.md), and its Blast section *starts* from the map's current-state radius and then adds what the plan itself introduces. Copying the radius across unchanged is a Blast failure, not a shortcut.

## Escalation and neighbors

- **recon** — "What is actually there?" Read-only reconnaissance of the current system, before a plan exists.
- **[spike-360](https://github.com/HiQS-Labs/XYZ-forge/blob/development/skills/4-occasional/spike-360/SKILL.md)** — "Should this authority exist?" Classify first when state is moving; recon then maps what the approved shape has to live with.
- **[swe](../swe/SKILL.md)** — "Does the plan embody our standards?" Its Pillar 0 is satisfied by recon's map; its Blast pillar extends that map per decision.
- **`phase-0-spike`** (`~/.claude/workflows/phase-0-spike.js`) — the deep seam map with contract owners and rollout invariants, for a refactor already committed to. Recon is the cheap universal pass; that is the expensive committed one.
- **`blast-radius` (not shipped here)** — prices a one-way door the map exposes.
- **[debug-mantra](../debug-mantra/SKILL.md)** — traces a fail path for a bug happening now; recon traces edges for a change that has not happened yet.

exec
/bin/zsh -lc "nl -ba AGENTS.md | sed -n '1,190p'; nl -ba GUIDING-PRINCIPLES.md | sed -n '1,230p'" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-13569-zsltpsy2
 succeeded in 0ms:
     1	# AGENTS.md
     2	
     3	## Danger: commands agents must not run
     4	
     5	- Never run `git reset --hard`, `git checkout -- <path>`, or a tree-wide `git stash` in a checkout
     6	  whose state matters; they overwrite tracked work or hide shared worktree-family state.
     7	- Never run `rm -rf`, `find ... -delete`, or equivalent recursive cleanup through an empty,
     8	  unresolved, relative, root, home, workspace, or otherwise unproven target path.
     9	- Never remove or move a linked worktree with `rm -rf` or `mv`, and never hand-delete
    10	  `.git/worktrees/*`; use `git worktree remove` / `move` / `prune` / `repair`.
    11	- Never run sandboxed `git switch --track` or `git branch -D` directly; wrap the complete command
    12	  with `utils/git-sandbox-guard.sh --repo <root> -- <git command>`.
    13	- Never delete or move a full-clone folder until its working tree, stashes, local refs, and registered
    14	  worktrees prove that it contains no unique or depended-on state.
    15	- Never run `validate.sh` or `test/*.sh` from a linked worktree or a full clone whose state matters;
    16	  run mutation-heavy gates only in a separate disposable full clone.
    17	
    18	Read [`WORKTREE-SAFETY.md`](WORKTREE-SAFETY.md) for the rationale, recovery paths, and safe patterns.
    19	
    20	> **Safety and warranty:** XYZ Forge is provided **“AS IS,” without warranty**, under the applicable
    21	> license. Coding models may choose commands through their own runtimes and safety controls, outside
    22	> the intended harness workflow. XYZ Forge cannot guarantee model behavior or data integrity; maintain
    23	> tested, independent backups and follow industry-standard backup and recovery practices.
    24	
    25	Read `ROUTER.md` first for startup order and canonical files.
    26	
    27	Read `GUIDING-PRINCIPLES.md` for the product north stars — its "The North Star" section (durable,
    28	reversible, DRY; extend what exists rather than forking a parallel system) is canonical and governs
    29	everything below.
    30	
    31	Read `PROJECT/PDDA.md` when the task touches project docs or `CHANGELOG.md`.
    32	Its document contract is adopted here; [ROUTER’s role split](ROUTER.md#role-split) distinguishes
    33	XYZ-owned policy from PDDA-layer scope.
    34	
    35	Read `HARNESS-MODELS-REGISTRY.md` for evaluated agent harnesses, model compatibility grades, and CLI flags.
    36	
    37	Read `TESTS-RESULTS/README.md` for committed test artifacts, telemetry receipts, and benchmark logs.
    38	Read `SOP.md` → "Arc planning" before starting a large refactor — scheduling the follow-up arcs (review/dogfood/conformance lanes) at plan time is what keeps the arc linear.
    39	
    40	## Runtime default
    41	
    42	Entry-point shims run their **Python** implementation by default (`XYZ_PYTHON` unset → Python). To
    43	force the legacy Bash path for a single run, prefix it with `XYZ_PYTHON=0`; for a whole session,
    44	`export XYZ_PYTHON=0`. The Bash body stays inline in every shim, so the opt-out is always available.
    45	
    46	## What this file owns
    47	
    48	This file is the behavioral playbook for work in this repo: decision quality, reversibility, blast
    49	radius, planning shape, and proof.
    50	
    51	Do not restate routing, roadmap, changelog, or active-doc contracts here. Those live in
    52	`ROUTER.md` and `PROJECT/PDDA.md`.
    53	
    54	After a PR merges into `development`, the hosted reconciliation workflow (`wave-reconcile.yml`)
    55	automatically reconciles docs, ledger, and views (`LEADERBOARD.md`). Task
    56	branches do not commit routine views. Local reconciliation via `python3 utils/py/wave_reconcile.py --pr <N>`
    57	serves as an emergency fallback (failing closed if a hosted reconciler is in-flight; pass `--force-local-reconcile`
    58	to override); `pdda.sh issue-doc-sync` is the deterministic drift detector when in doubt.
    59	
    60	Maintainer-only workflow defaults (branch discipline, express-to-development, fresh-clone-per-task)
    61	live in `SOP.md` → "Opinionated SOPs" — optional for downstream users, binding for us. That section
    62	is a standing carve-out from the "do not create new git branches automatically" rail: it
    63	pre-authorizes one `feat/`/`fix/`/`chore/`/`docs/` branch per fresh task clone, nothing more.
    64	
    65	## Operating principles
    66	
    67	### 1. Lead with the line that survives skimming
    68	
    69	Your first sentence gives the verdict, current state, or call. No setup first.
    70	
    71	### 2. Make the bet explicit before acting
    72	
    73	State the assumption, tradeoff, and failure mode that matter before you commit to a path. If a future
    74	reader could not say "that assumption was wrong," you have not made the real bet legible yet.
    75	
    76	### 3. Use one reversibility scale
    77	
    78	Consequential changes get a read on the shared scale: **Easy / Costly / One-way door**, with one line
    79	of why. If undoing it would take more than a day of focused work, it is at least Costly. Costly
    80	changes need a rollback path. One-way doors need explicit confirmation before proceeding.
    81	
    82	This scale is how `GUIDING-PRINCIPLES.md` → "The North Star" gets applied per change; that section
    83	owns the *why*, this one owns the read.
    84	
    85	### 4. Size the blast radius before changing shared surfaces
    86	
    87	Before a refactor, schema change, dependency bump, coordination-kernel change, or relay-containment
    88	change, say what ripples, what might break, and who notices. A change you cannot size is not ready.
    89	
    90	### 5. One plan, one ordered list
    91	
    92	When you give executable steps, put them in one numbered list in execution order. Keep verification
    93	inline (`-> expect ...`). Do not scatter action items across prose.
    94	
    95	### 6. Verified beats plausible
    96	
    97	Do not claim success without the relevant test, script, or observable proof. If verification was
    98	skipped or failed, say that plainly and include the result.
    99	
   100	An uncommitted `provenance.jsonl` is not proof (GH-430). Any run cited as evidence in an issue, PR,
   101	ROADMAP entry, or decision record must have its `provenance.jsonl` committed in the same PR — a path
   102	you merely ran and can no longer show counts as no claim at all.
   103	
   104	**A check that cannot fail is not a check.** A passing assertion is evidence only once you have seen
   105	it fail: mutate the thing it guards — break the code, transpose the fix, delete the value — and watch
   106	it go red. If you cannot make it fail, it is decorative, and it is worse than nothing because it
   107	reports confidence it never earned. Witness the failure on an existing suite or record it as a manual check.
   108	Never add a suite to do it; see the *No new tests* rail. This is the precise way this principle fails while looking
   109	satisfied: you *did* verify, and the verification was hollow. Three examples from GH-377/GH-379, all
   110	of which passed cleanly before they were mutated — an `awk` range that terminated on its own first
   111	line, `not matches -- "$pat"` where the helper already supplied `--` so the check searched for the
   112	literal string `--`, and a telemetry `rc` assertion that no *passing* run could ever exercise.
   113	
   114	**A flaky suite is fixed in place if it is in a tier, and turned off if it is not.** Tier membership comes from
   115	`utils/ci-route.sh` (`SUBSYSTEM_TESTS_small`). Turning off means removing it from `validate.sh` `TESTS` and adding it to the
   116	gh306 `EXEMPT` list, keeping the file (#802 operator decision, comment 5841529958; #853).
   117	
   118	**An empty input passes every check.** Before asserting anything about extracted data, assert that
   119	you extracted some: a failed command substitution yields an empty string, a shell redirect creates
   120	the file regardless, and a scanner then reports CLEAN against zero bytes. Size-check the artifact,
   121	or guard the extraction with its own assertion, before trusting a verdict computed from it.
   122	
   123	**Never expose the operator's machine to the network without asking.** A tunnel, port forward, or
   124	remote bridge needs explicit permission each time — running the tests is not permission, and neither
   125	is working on the feature that provides it. `SOP.md` §3b has the incident and the teardown rule that
   126	goes with it.
   127	
   128	**Establish blocker necessity before investing in repair.** An in-flight failing test or unexpected error is not automatically an urgent blocker. When an obstacle's necessity or user consequence is unclear, or after two investigation attempts yield no new evidence, run `sanity-check` (`skills/1-hourly/sanity-check/SKILL.md`) to evaluate whether to fix now, simplify, defer via PRS, or dismiss, before sinking hours into tracing the fail path.
   129	
   130	### 7. Record only consequential bets
   131	
   132	If a change is Costly, One-way door, or assumption-heavy, record the bet in `CHANGELOG.md` per
   133	`PROJECT/PDDA.md`. Below that threshold, skip the ritual.
   134	
   135	### 8. Stay quiet on trivial work
   136	
   137	Most edits are small and reversible. Do not manufacture ceremony for a rename, typo fix, or other
   138	local change.
   139	
   140	## Repo-specific rails
   141	
   142	- **No new tests (GH-831, operator decision 2026-09-25).** This covers three things:
   143	  - Do not add a new `test/` suite or a new entry in `validate.sh`'s `TESTS` registry.
   144	  - Do not add new gate machinery: guards, lanes, runners or telemetry stages.
   145	  - Do not add a test to enforce this rule.
   146	
   147	  Verify a change with the existing suite that covers it, or with a manual check recorded under
   148	  `TESTS-RESULTS/<date>+GH-<n>/` with its `provenance.jsonl`. Edit an existing suite only to keep it truthful
   149	  when the behaviour it pins changes. A red control (see *Verified beats plausible*) is witnessed on an
   150	  existing suite or recorded as a manual check. Reviewers treat a new test file as a finding.
   151	
   152	  The gate is being cut to Small/Medium/Large tiers under [#831](https://github.com/HiQS-Labs/XYZ-forge/issues/831).
   153	  #815, #816, #817 and #819 are superseded; do not implement them.
   154	
   155	- **This repo's purpose is to keep a long-horizon marathon under load — and that is a work-selection
   156	  filter, not a slogan.** The harness is only proven by work long enough, parallel enough, and
   157	  failure-prone enough to tax the whole system: worktree isolation, path claims, the driver lock,
   158	  multi-round handoff, escalation, and resume. Short, single-shot tasks land fine but prove nothing.
   159	  Four rules follow, and they are load-bearing:
   160	
   161	  1. **Exactly one long-horizon marathon is in flight at a time.** When one lands, choosing the next
   162	     is a real decision, not a default. It is named in the roadmap ledger's **Immediate next-up**
   163	     (query via `python3 utils/py/releases_app.py roadmap list`; the RELEASES DB is the source of truth since the
   164	     `ROADMAP_SOURCE=releases` flip) as the marathon, so an agent arriving cold can tell which item
   165	     is the load and which items are riding alongside it.
   166	  2. **Prefer the marathon-shaped candidate.** *Marathon-shaped* means: decomposable into many items
   167	     with an identical transform, a per-item pass condition a machine can check, and a plausible way
   168	     to break the harness. GH-10 (73 unaudited suites, one mechanical adoption each) is the
   169	     archetype. Picking a non-marathon-shaped item over a marathon-shaped one of comparable value
   170	     needs a stated reason — write it in the ledger entry, not in a commit message.
   171	  3. **Only real work.** Never manufacture a marathon to keep the system busy, and never build a
   172	     synthetic workload that cannot damage anything — a run with no blast radius does not surface
   173	     the failures that matter. If nothing genuinely needed is marathon-shaped right now, **the
   174	     correct state is idle**. Say so plainly and do the smaller work; an idle gap is honest signal,
   175	     a fabricated marathon is noise that costs real tokens.
   176	  4. **The point is the failures.** A marathon that completes cleanly and teaches nothing is a
   177	     weaker result than one that escalates and names a defect. Report what broke; do not smooth it.
   178	
   179	- **The RELEASES DB is two subsystems behind one CLI** (`utils/py/releases_app.py`; it is the
   180	  Product Release System, [PRS](HOW-TO-USE.md#glossary--the-five-terms-youll-hit-first)): the GH-32
   181	  release ledger and the roadmap ledger (`roadmap_items`). Since the `ROADMAP_SOURCE=releases`
   182	  flip (GH-169/GH-238/GH-243) and ROADMAP.md retirement (GH-269), the DB is the roadmap's source of truth in THIS repo: park intake
   183	  with `releases roadmap add` (or `hq park`), and read with `releases roadmap list` (or `python3 utils/py/releases_app.py roadmap list`).
   184	  `roadmap sync` is for legacy-mode repos only and no-ops here — it mirrors markdown and would delete
   185	  `add`-parked rows. Never hand-edit `releases.sql` or `releases.db`. Merge conflicts on the dump have
   186	  a one-command resolver (`utils/releases-merge-resolve.sh`). The whole contract, including what a real
   187	  merge conflict looks like: [RELEASES-DB-FAQS.md](RELEASES-DB-FAQS.md).
   188	
   189	- **The local gate runs at the push boundary; hosted CI independently attests public-repo changes
   190	  (GH-544, XYZ-forge #16).** The private-phase bridge ended when this repository became public on
     1	# Guiding Principles
     2	
     3	North star for **XYZ Forge**, the multi-agent coordination harness behind the `tick` event-log kernel and `relay-automation/` relay stack. When a choice is unclear, the option that keeps agents synchronized, contained, and verifiable — without leaking or destroying work — wins. AGENTS.md is the behavioral playbook; ROUTER.md is the entry-point map; this is the *why*.
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
    36	XYZ Forge is a local-first operations system for humans directing agents across their repositories:
    37	capture → rate → plan → preflight → execute → gate → land → record. Its `tick` kernel coordinates
    38	local claims through an event log and exclusive locks; its relay and Marathon tooling drive bounded
    39	build and review work. Containment controls reduce accidental writes but do not guarantee safety
    40	outside their enforced boundaries; linked worktrees share Git state. The product prioritizes
    41	coordination, recoverability and verifiable outcomes. The operator remains the decision authority.
    42	
    43	XYZ is not enterprise application lifecycle management or an agent marketplace. It currently
    44	assumes specified work rather than providing a structured spec/PRD-generation pipeline of its own;
    45	that capability gap is not a permanent prohibition on future product work. PDDA’s governance-layer
    46	anti-scope does not prohibit XYZ’s coordination and execution features.
    47	
    48	## The quality bar
    49	
    50	Every agent turn is a signal. A turn is high-quality only when it is all four:
    51	
    52	- **Attested** — carries its receipts: source, evidence, confidence. Never a bare verdict. A relay review names which claim is wrong and why; a build turn names the seam it touched.
    53	- **Relevant** — ranked, not dumped. Volume is not value. One real bug beats five nits and a phantom.
    54	- **Fresh** — current, not stale. A turn that reads a stale `STATE.md` or misses an epoch fence is wrong by construction.
    55	- **Structured** — one shape, clean for the operator to read and for downstream agents to feed on.
    56	
    57	Fail a pillar, and the turn, feature, or relay review isn't done.
    58	
    59	## How it's built
    60	
    61	1. **Coordination is local-transport only.** `.tick/events/` is the shared bus; claims resolve from there, not from a remote. No per-event push/fetch; no remote dependency at runtime. A coordination primitive that reaches out is a coordination primitive that can fail or leak.
    62	
    63	2. **One canonical event log for tick coordination.** `.tick/events/` records coordination events; `.tick/STATE.md` is a derived view. Coordination verbs read and fold the events and append changes through the event API. Other subsystems retain their own documented sources of truth, including the RELEASES roadmap ledger. Do not create competing copies of canonical state.
    64	
    65	3. **Containment is non-negotiable.** A headless turn must not: self-commit mid-turn, orphan a peer's concurrent commit, or write outside its allowlist. The allowlist, worktree isolation, and commit-bypass guard exist because a driven agent will do all three if unconstrained — not hypothetically, but as documented live incidents (GH-13, GH-14, GH-17). New relay paths must clear the containment bar before they ship.
    66	
    67	4. **Skill-first; never improvise the harness.** The `relay-xyz` skill owns the locator, sandbox rules, exit codes, and the safety boundary. A session that improvises those from `ls relay-automation/` silently skips the skill's safety layer. In sessions that install and invoke the `PreToolUse` hook, `relay-automation/hooks/relay-xyz-guard.sh` checks supported driver invocations for the skill’s setup evidence; this is not a guarantee that every runtime invokes that hook. Add capabilities to the skill; do not work around it.
    68	
    69	5. **Adversarially proven before commercially viable.** The harness exists to run against real codebases. Features in the adversarial-hardening track (epoch fencing, chaos suite, cross-repo E2E) must be verified to survive deliberate abuse — stale writers, zombie claims, macOS case-sensitivity, concurrent peer commits — not just the happy path. A feature that clears the happy path and skips chaos is half-done.
    70	
    71	6. **Build durable, not band-aid.** Durable means it removes the root cause and the next planned change builds on it — not a patch torn out when the obvious next feature lands. A band-aid is wasted work unless a demo strictly needs one, and a demo band-aid is tagged for removal so it isn't silently inherited.
    72	
    73	7. **Least code that clears the bar.** The `tick` coordination kernel uses Node's standard library. The repository also ships `package.json` and `package-lock.json` for Acorn-based source analysis. Prefer reusing or extending what exists; the smallest change that stays correct, contained, and durable wins. Net-new code is a cost to justify. Deleting code counts as progress.
    74	
    75	8. **Honest; the operator decides.** Surface what failed and why — never mask a stall as success or an escalation as a stall. A headless turn self-repairs within a bounded exit-code menu (`exit 3` stall, `exit 4` escalated-by-design, `exit 6` containment revert), then stops; it never loops forever or silently swallows an error. Destructive actions require explicit authorization.
    76	
    77	9. **Docs support resumable work (PDDA).** ROUTER points to the governing contracts; the RELEASES DB owns this repository's roadmap ledger (queried via `python3 utils/py/releases_app.py roadmap list`). Linked PROJECT documents hold plans, decisions and handoff detail; CHANGELOG records dated outcomes. Resume execution using those documents together with the relevant runtime state and evidence. If current documentation contradicts the implementation, correct it or explicitly record the unresolved discrepancy.
    78	
    79	10. **Done means verified.** "Done" is `validate.sh` green, the relevant PDDA checks passing, and any relay review returning `Approved` — not work that looks finished. An unverified success claim is itself a low-quality signal.
    80	
    81	11. **Issue-first; every non-trivial change has a signal stream.** Any change beyond a 2–3 line fix opens a GitHub issue first, then gets a `GH-<number>` in-repo pointer doc, then lands. The issue is the machine-queryable signal stream; the `PROJECT/**` doc is the execution surface of record. Genuinely trivial edits (≤2–3 line fixes, typos, path repoints, doc-only one-liners) are exempt.
    82	
    83	12. **Independent Verification (Separated Grading)** — The agent that produces a turn must not be the sole grader of its own quality. Verification must be performed by an independent deterministic check or a separate reviewing agent before the lock releases. Applies to: the relay's structural block validator (`bin/validate-relay-block` — Phase 1 of GH-21), consult-verify diversity (Phase 3), and any other post-generation quality gate.
    84	
    85	13. **A green gate without a witnessed red control is not evidence.** Every new or materially changed decision gate needs a recorded demonstration that it fails for the right reason: a pre-fix replay, deliberate mutation, or controlled bad input. Witness it on an existing suite, or record it as a manual check under `TESTS-RESULTS/`. Never add a new test suite to do it (GH-831: no new tests). Do not mistake a check that validates the artifact it just generated (#351) or a parity check that compares a lane to itself (#348) for evidence; both shapes are structurally unable to falsify their claim.
    86	
    87	## Applying this
    88	
    89	Adding a feature or weighing a tradeoff, ask: *does this keep agents coordinated without collision, contained within their scope, and verifiable to an outside observer? And is "done" provable by running `validate.sh`?* If any answer is no, reconsider.
    90	
    91	---
    92	
    93	## Conventions
    94	
    95	### Strict-mode policy (bash `set -e`)
    96	
    97	Python is the default implementation for the twelve frozen Tier-A entry points. Existing Bash
    98	bodies are compatibility fallbacks selected with `XYZ_PYTHON=0`; their strict-mode choices remain
    99	subsystem-specific. Consult each existing script’s header and error handling before changing it.
   100	New executables under `utils/` or `relay-automation/` follow AGENTS.md’s Python and exception rules.
   101	This section does not authorize edits to frozen Bash twins.
   102	
   103	### Tool install paths — never inside another app's folder (GH-347)
   104	
   105	**This harness's tool binaries never live inside another application's private directory.** Not the
   106	worker CLIs (`codex`, `agy`, `pi`, `aider`), not `tick`, not anything the harness shells out to.
   107	
   108	The failure mode is specific and quiet: a foreign app owns its own directory, so its next update or
   109	reinstall deletes our dependency with it — on that app's schedule, with no signal we control. Worse, the
   110	readiness check cannot tell the two apart. `find-harness.sh --check` tests only whether a worker is *on
   111	PATH*, so "the neighbouring app just wiped our tool" and "never installed" produce the byte-identical
   112	line. That is the same disease as GH-315/GH-319: a broken observation layer where failure is invisible
   113	and every available signal agrees.
   114	
   115	**The `npm install -g` trap — this is how GH-347 actually happened.** npm derives its global prefix from
   116	whichever `npm` is on PATH, so a bare `npm install -g <pkg>` inherits a foreign app's runtime silently
   117	and exits 0. On the machine that filed GH-347, another agent app had symlinked its bundled Node onto PATH
   118	(`~/.local/bin/npm -> ~/.hermes/node/bin/npm`) with no `~/.npmrc` involved at all, so `pi` installed into
   119	that app's folder and — because only `node`/`npm` were symlinked out, not `pi` — was invisible to every
   120	shell while being perfectly functional. **Run `npm config get prefix` before any global install and
   121	confirm it is a path this repo's tooling owns.** Never assume.
   122	
   123	The positive pattern is already on disk in the two lanes that have never had this problem: a tool's own
   124	app directory with a symlink onto PATH (`~/.local/bin/codex -> ~/.codex/packages/…/bin/codex`), or a real
   125	binary in a shared user-local `bin`. Either is fine. Someone else's runtime is not.
   126	
   127	**Scope note:** where a *working* binary lives stays the operator's call. This is a convention and a
   128	warning, deliberately **not** a gate — a false positive that blocks a relay is worse than the papercut it
   129	prevents.
   130	
   131	### Marathon builder default & plan location (GH-212)
   132	
   133	Two vendored-harness defaults, made explicit so an agent given only the vendored bundle picks the
   134	right behavior without pattern-matching a downstream repo's prior drift:
   135	
   136	- **Builder default is `codex`.** Marathon’s current implementation defaults to Codex; agy is
   137	  another supported builder. Choosing Claude remains an explicit, cost-acknowledged operator
   138	  decision under AGENTS.md. Actual billing depends on the selected tool’s authentication and
   139	  account configuration; a default executable name does not establish a billing guarantee. The
   140	  Python implementation is the default, with the existing Bash fallback available through
   141	  `XYZ_PYTHON=0`.
   142	- **A marathon's plan lives under `PROJECT/2-WORKING/`.** The `MARATHON.yaml` + its phase briefs
   143	  belong under `PROJECT/2-WORKING/<capture-doc>/` — never a standalone top-level folder (e.g.
   144	  `marathon-plans/<slug>/`). `marathon.sh --plan` enforces this: it refuses (exit 2) a plan that
   145	  resolves outside `PROJECT/2-WORKING/`, exempting only paths under the harness's own home
   146	  (`MARATHON_HOME` — shipped reference examples like `MARATHON.example.yaml`) or an explicit
   147	  `MARATHON_ALLOW_PLAN_OUTSIDE_WORKING=1` override for a genuinely non-default location.
   148	
   149	---
   150	
   151	## Appendix: AI Doc Review Heuristics
   152	
   153	When reviewing any repo doc (roadmap entries, plans, architecture notes, audits, task writeups), apply these. Priority: containment > coordination correctness > signal quality > implementation speed and operator friction.
   154	
   155	**Heuristics**
   156	
   157	1. **Containment preserved?** Any headless path that could self-commit, touch off-allowlist files, or orphan a peer commit without an explicit containment argument → reject or escalate.
   158	2. **Skill-first respected?** Any plan that bypasses `relay-xyz` or improvises the harness from scratch without the skill layer → reject. Add to the skill instead.
   159	3. **Coordination through the event log?** Tick coordination state uses `tick` verbs; other subsystems use their documented canonical writers. Competing state copies need explicit justification.
   160	4. **Done verifiable?** Names runnable gates (`validate.sh`, specific tests, `utils/pdda/pdda.sh run`). None = low-quality signal.
   161	5. **Drift reduced, not created?** No duplicated docs, no execution detail in the roadmap ledger or its generated dashboard, no reinventing a path the event-log contract already documents.
   162	6. **Next action singular?** One explicit next step, not buried in prose; status cells non-empty.
   163	7. **Operator control explicit?** No silent retry, no auto-repair outside the bounded exit-code menu, no masked failure; destructive ops surface before executing.
   164	8. **Four pillars pass?** Each turn/output is Attested, Relevant, Fresh, Structured. Fail one → not done.
   165	
   166	**Tie-breakers**
   167	
   168	- **Containment vs speed:** choose containment; flag friction as a design question, not a shortcut.
   169	- **New relay path vs reuse:** extend the existing skill and harness over forking a parallel path; if the harness can't accommodate it, surface the gap.
   170	- **Ambitious vs resumable:** a shorter plan an agent can resume cold beats a comprehensive one that buries state in prose.
   171	
   172	**Reject or escalate when**
   173	
   174	- A headless path has no allowlist, no worktree isolation, and no commit-bypass guard — and the doc doesn't justify why.
   175	- "Done" has no runnable verification step.
   176	- Adding a new relay lane requires editing the event-log kernel or the `tick` verb schema without a decision record under `decisions/`.
   177	- Hardcoded absolute paths, silent destructive operations, or opaque epoch-fence assumptions.
   178	- The roadmap ledger would need execution detail to make the plan legible.

exec
/bin/zsh -lc "wc -l relay-automation/marathon.sh utils/py/marathon_drive.py utils/py/consult.py utils/py/jog_run.py; rg -n 'wait|drive|progress|trap|CHAIN|resume|exit|run.log' relay-automation/marathon.sh; rg -n '"'^(def |class )|heartbeat|attempt|timeout|already.satisfied|retry|resume|harness|receipt|progress'"' utils/py/marathon_drive.py" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-13569-zsltpsy2
 succeeded in 0ms:
     362 relay-automation/marathon.sh
    3613 utils/py/marathon_drive.py
     938 utils/py/consult.py
    1780 utils/py/jog_run.py
    6693 total
5:# order, and runs each phase through marathon-drive.sh (the unmodified single-phase loop). Advances
6:# on phase approval; HALTS on the first phase failure (relay no-progress / cap / gate / containment),
7:# leaving that phase's ESCALATION.md (written by marathon-drive) and NOT starting later phases.
32:# its task name exactly as before. marathon-drive.sh already supports --relay-task natively; this is
33:# purely a marathon.sh-side task-name override, no change to marathon-drive.sh itself.
35:# The MARATHON.yaml phase fields drive each marathon-drive call: id→--phase-id, reviewer→--reviewer,
43:#   MARATHON_DRIVE      — marathon-drive.sh path (default: <harness-home>/relay-automation/marathon-drive.sh)
50:# Exit: 0 all phases approved · N the failing phase's marathon-drive exit code · 2 usage/parse error.
62:DRIVE_BIN="${MARATHON_DRIVE:-"$MARATHON_HOME/relay-automation/marathon-drive.sh"}"
66:die() { printf 'marathon: %s\n' "$*" >&2; exit 2; }
72:# marathon-drive runs with XYZ_HARNESS_CONTEXT=marathon-phase (its own hook silent), so this is the
75:# emitting nothing — worse than a bare marathon-drive halt, which does emit red). Best-effort.
95:  --target-root DIR       Foreign git repo the BUILD lands in; forwarded to marathon-drive.sh (GH-11).
99:                          and relay-system/ on purpose): without it, marathon-drive's `git add` of
109:  --dry-run               Render each phase's relay file and print the tick seed; exit without running.
116:                          plainly instead: the driver detects the satisfied lane and re-runs only the
120:                          and does not change the successful marathon exit code.
137:    --help)            usage; exit 0 ;;
182:# ── GH-388: the chain run log ────────────────────────────────────────────────────────────────────
201:  # harness-home-exempt case. A missing lib costs the durability CHECK, not the run log.
212:  # second copy of that rule is how the run log and the per-phase transcripts would end up in
214:  # `|| _run_log_base=""` is load-bearing: under `set -e` an assignment whose command substitution
215:  # exits non-zero terminates the script, so a fake/partial MARATHON_HOME turned "the resolver is
216:  # unavailable" into a bare exit 127 with no message — the shape of failure this whole issue is
218:  _run_log_base="$(set +e; source "$MARATHON_HOME/relay-automation/relay-turn-lib.sh" >/dev/null 2>&1; rtl_transcript_root "$ROOT" 2>/dev/null)" || _run_log_base=""
219:  if [[ -z "$_run_log_base" ]]; then
224:      _run_log_base="$ROOT/relay-system"
230:  # Scoped to RELOCATION, matching rtl_default_log: a run log inside the repo being driven shares
233:  _run_log_reason="$(xyz_non_durable_reason "$_run_log_base")"
234:  if [[ -n "$_run_log_reason" ]] && [[ "$(_xyz_realish_path "$_run_log_base")" != "$(_xyz_realish_path "$ROOT")"/* ]]; then
235:    die "the resolved run-log root $_run_log_base is under $_run_log_reason, which this harness records as non-durable storage ($(xyz_non_durable_conf)), and it is OUTSIDE the repo being driven ($ROOT). A marathon's own record must survive a reboot — that is the whole of GH-388. Point XYZ_ARCHIVE_ROOT at a committed archive, or unset it."
238:  _run_log_dir="$_run_log_base/run-logs/$(date +%Y-%m-%d 2>/dev/null || echo unknown-date)"
239:  mkdir -p "$_run_log_dir" || die "could not create the run-log directory $_run_log_dir"
241:  MARATHON_RUN_LOG="$_run_log_dir/marathon-${_plan_slug}-$(date +%H%M%S 2>/dev/null || echo unknown)-$$.log"
251:  log "run log: $MARATHON_RUN_LOG"
254:# Parse + validate + resolve order. A malformed/cyclic plan halts the whole run here (exit 2).
283:  drive_args=( --phase-id "$id" --reviewer "$reviewer" --builder "$BUILDER"
285:  [[ -n "$PHASES_DIR" ]] && drive_args+=( --phases-dir "$PHASES_DIR" )
286:  [[ -n "$artifact" ]] && drive_args+=( --artifact "$artifact" )
287:  [[ -n "$TARGET_ROOT" ]] && drive_args+=( --target-root "$TARGET_ROOT" )
288:  [[ -n "$PRE_ADVANCE_CMD" ]] && drive_args+=( --pre-advance-cmd "$PRE_ADVANCE_CMD" )
289:  ((FORCE)) && drive_args+=( --force )   # GH-45: bypass the per-lane attempt cap for this run
291:  # marathon-drive.sh derive its default MARATHON-<ID>-TURN name, unaffected.
296:    # (tick info exits 0 once a task has any recorded state — spent or not, it's not reusable).
302:    drive_args+=( --relay-task "$retry_task" )
304:  if ((DRY_RUN)); then drive_args+=( --dry-run ); fi
306:  phase_exit=0
307:  # GH-75: mark each per-phase marathon-drive call so its (and its nested relay-drive's) XYZ.json hook
313:      bash "$DRIVE_BIN" "${drive_args[@]}" || phase_exit=$?
316:      bash "$DRIVE_BIN" "${drive_args[@]}" || phase_exit=$?
318:  if [[ "$phase_exit" -ne 0 ]]; then
319:    log "HALT: phase $id failed (marathon-drive exit $phase_exit) — chain stops; later phases NOT started"
320:    case "$phase_exit" in
321:      3) _halt_reason="relay no-progress" ;;
326:      *) _halt_reason="marathon-drive exit $phase_exit" ;;
329:    exit "$phase_exit"
335:  exit 0
362:exit 0
20:from harness_paths import harness_home, repo_root, resolve_tool, is_vendored  # noqa: E402
36:# `die()` and the lane-attempt cap all exit BEFORE the run log arms (drive_started).
41:    3: "no-progress escalation",
45:    7: "turn timeout / hang",
46:    8: "lane parked at the attempt cap",
52:def _exit_meaning(code):
65:# ── GH-280: opt-in durable terminal result receipt (marathon-drive/result@1) ──────────────────
67:# record: outcome, identity (issue/phase/lane/token/attempt), repo/branch/SHA, gate + acceptance
88:    "root": None,              # harness root (MARATHON_ROOT-resolved)
99:    "attempt_max": None,
100:    "pr_note": None,           # non-None when PR publication was attempted and failed
107:def _result_outcome(code):
108:    """Map a driver exit code onto the receipt's outcome vocabulary."""
128:def _derive_issue_number(lane, task, brief_name):
137:def _result_cmd_out(cmd, cwd=None):
138:    """Best-effort stdout capture for the receipt's git/gh probes; failure yields None."""
140:        res = subprocess.run(cmd, cwd=cwd, capture_output=True, text=True, timeout=30)
149:def write_terminal_result(code):
151:    the process's real exit code — the receipt is a record, not a verdict override."""
157:        eprint(f"marathon-drive: result receipt could not be written "
161:def _write_terminal_result_inner(code):
189:    attempt_count = _RESULT.get("attempt_count")
190:    if attempt_count is None and lane and _RESULT.get("root"):
191:        attempts_file = os.path.join(_RESULT["root"], ".tick", "attempts",
193:        if os.path.isfile(attempts_file):
195:                with open(attempts_file, "r") as f:
196:                    attempt_count = sum(1 for _ in f)
200:    gate_receipt_path = None
202:        candidate = os.path.join(_RESULT["root"], ".xyz", "receipts", f"{head_sha}.json")
204:            gate_receipt_path = candidate
235:    receipt = {
247:        "attempt": {"count": attempt_count, "max": _RESULT.get("attempt_max")},
254:        "head_sha": head_sha,   # observational: HEAD at receipt-write time
266:            "receipt_path": gate_receipt_path,
281:            json.dump(receipt, f, indent=2)
290:    log(f"result receipt written: {target} (outcome: {outcome}, exit {code})")
293:def _result_arm(args, root, target_root):
305:            f"marathon-drive will not guess a location for the receipt")
326:        "attempt_max": int(os.environ.get("LANE_MAX_ATTEMPTS", "2") or 2),
332:def runlog_find_comment_id(payload_text, marker):
343:    run log POSTed a duplicate every single time. test/gh284-runlog-heartbeat.sh missed that for a
377:def _json_esc(value):
388:def xyz_debug_log_enabled():
393:def xyz_debug_log_file(root):
398:def _xyz_debug_log_write(root, line):
407:def xyz_debug_log_append(root, severity, check, message,
419:    scope = f"target:{target_root}" if target_root else "harness"
431:def xyz_debug_log_stale_lock(root):
443:        '{"timestamp":"%s","severity":"info","check":"marathon.stale-lock","scope":"harness"'
448:def xyz_harvest_findings(harvest_bin, relay_file, root, target_root, debug_log):
470:def _utc_now_z():
474:def eprint(*args, **kwargs):
477:def get_env(key, default=None):
480:def die(msg):
484:def log(msg):
487:def resolve_force_relay_task(base_task, tick_bin, force, explicit):
535:def run_tick_loud(cmd_args):
562:        # exit-1 lock-contention meaning — record the real reason for the result receipt.
566:def preflight_write_set_trackable(repo_root, paths, transcript_paths=None):
644:        eprint("    2. Or run with --target-root <code-repo>, which moves ALL harness output here")
652:        eprint("       <harness-root>/marathon-system regardless (see phases_dir below), so the")
657:    eprint("       to track harness output.")
658:    eprint("  Not doing it for you: a repo that ignores harness output usually means it, and")
662:def _repo_rel_prefix(path, root):
683:def phase_commit_root(root, phase_dir, target_root):
722:def _probe_bin(bin_name, role_label, agent_id):
737:DEEPSEEK_DEFAULT_BIN = "/Users/noelsaw/Documents/GH Repos/deepseek-harness/apps/cli/lib/bin.js"
739:def _probe_bin_or_file(candidates, role_label, agent_id, override_env):
757:def _probe_claude_bin(role_label):
771:def _probe_agent_bin(agent_id, role_label):
866:def _gate_tier():
876:def _gate_guard_config():
903:def _gate_group_rss_mb(pgid):
913:                             timeout=10)
935:def _gate_rss_summary(peak_mb, readable, unreadable):
946:def _gate_kill_group(proc, reason):
962:def gate_guard_cpu_attribution(returncode, cpu_s):
980:def _phase_memory_sample(tag="", root=None, tick_bin=None, relay_task=None):
986:            out = subprocess.run(["sysctl", "-n", "vm.swapusage"], capture_output=True, text=True, timeout=5).stdout
999:            out = subprocess.run(["vm_stat"], capture_output=True, text=True, timeout=5).stdout
1042:def main():
1059:    # GH-402: deliberately NOT folded into --force. --force bypasses the per-lane attempt cap, which
1061:    # One flag for both would mean an operator retrying a flaky lane silently acquires permission to
1067:    # GH-280: opt-in durable terminal-result receipt for supervisors. No behavior change when unset.
1069:                        help="write a marathon-drive/result@1 JSON receipt at this path on every "
1072:                        help="caller-assigned execution ID recorded in the result receipt "
1085:        print("  --result-file PATH      GH-280 opt-in terminal result receipt (marathon-drive/result@1), written")
1087:        print("  --execution-id ID       GH-280 caller-assigned execution ID recorded in the result receipt.")
1121:    xyz_harness = harness_home()
1125:    tick_bin = get_env("TICK_BIN", os.path.join(xyz_harness, "bin", "tick"))
1126:    relay_drive_bin = get_env("MARATHON_RELAY_DRIVE", os.path.join(xyz_harness, "relay-automation", "relay-drive.sh"))
1127:    agent_cmd = get_env("MARATHON_AGENT_CMD", os.path.join(xyz_harness, "relay-automation", "marathon-agent.sh"))
1130:    # os.access(X_OK) at spawn time, so a harness missing the script simply harvests nothing.
1131:    harvest_findings_bin = os.path.join(xyz_harness, "relay-automation", "harvest-findings.sh")
1133:    # GH-280: arm the terminal-result receipt BEFORE anything below can die, so every refusal,
1134:    # escalation, and success path from here on produces exactly one receipt when requested.
1136:    # started a run, and a supervisor treats "exit non-zero, no receipt" as "driver never armed".
1143:    def lane_attempt_gate(root_dir, raw, force):
1146:        max_attempts = get_env("LANE_MAX_ATTEMPTS", "2")
1147:        try: max_attempts = int(max_attempts)
1148:        except ValueError: max_attempts = 2
1151:        attempts_dir = os.path.join(root_dir, ".tick", "attempts")
1152:        os.makedirs(attempts_dir, exist_ok=True)
1153:        attempts_file = os.path.join(attempts_dir, key)
1156:        if os.path.isfile(attempts_file):
1158:                with open(attempts_file, "r") as f:
1164:            eprint(f"lane-attempt-cap: --force override — lane {key} at {count} attempt(s) (cap {max_attempts}), proceeding.")
1165:        elif count >= max_attempts:
1166:            eprint(f"lane-attempt-cap: lane {key} PARKED after {count} attempt(s) (cap {max_attempts}) — no relay token seeded.")
1167:            eprint(f"  Re-anchor to the committed QUEUE lanes (AGENTS.md) or re-fire with --force. Attempts log: {attempts_file}")
1168:            # GH-280: the receipt reports the count that PARKED the lane; the attempts file
1169:            # still holds it here, but record it explicitly so the receipt survives any later
1171:            _RESULT["attempt_count"] = count
1178:                f"lane {raw} parked at attempt cap",
1190:        with open(attempts_file, "a") as f:
1192:        # GH-280: record the attempt this fire represents — complete_phase_success RESETS the
1193:        # attempts file, so a receipt that re-reads it after a green phase would report null
1195:        _RESULT["attempt_count"] = count + 1
1198:    def lane_attempt_reset(root_dir, raw):
1201:        attempts_file = os.path.join(root_dir, ".tick", "attempts", _lane_key(raw))
1202:        if os.path.exists(attempts_file):
1203:            try: os.remove(attempts_file)
1206:    def debug_mantra_prior_attempts(root_dir, raw):
1207:        # GH-162: READ-ONLY peek at the .tick/attempts/<lane> file GH-45 maintains — how many prior
1209:        f = os.path.join(root_dir, ".tick", "attempts", _lane_key(raw))
1219:        # GH-162: the note injected into the relay when a prior attempt exists; empty on a first fire
1235:        # full absolute path per line. This preamble renders ONLY on a retry, so the old form handed
1236:        # every re-attempt extra copies of the repo root — a recovery path that raised the very
1237:        # hazard it was retrying against, back when the containment scan failed turns on prose.
1257:        harness_root = harness_home()
1258:        mantra_rel = _rel(mantra_file, harness_root)          # relay-automation/DEBUG-MANTRA.md
1260:        out = (f"\n## Debug mantra (auto-triggered — {prior} prior attempt(s) on this phase did not reach Approved)\n\n"
1261:               f"Before trying again, read `{mantra_rel}` (relative to the harness root) and follow its "
1275:        # ls.sh, marathon-live.sh, find-harness.sh) must agree with it, so it lives in rtl.py's shared
1323:    xyz_append_bin = get_env("XYZ_APPEND_BIN", os.path.join(xyz_harness, "utils", "telemetry", "append-xyz-completion.sh"))
1330:        harness = "swarm" if ctx == "swarm" else "marathon"
1335:        subprocess.run([xyz_append_bin, harness, sid, health, title, desc], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
1337:    # GH-75/GH-249 lifecycle heartbeat: write operational liveness before driving the relay and clear
1340:    # xyz_marathon_heartbeat_write/clear (relay-automation/marathon-drive.sh).
1341:    xyz_heartbeat_bin = get_env("XYZ_HEARTBEAT_BIN", os.path.join(xyz_harness, "utils", "telemetry", "write-xyz-heartbeat.sh"))
1343:    def _heartbeat(clear):
1344:        if not os.access(xyz_heartbeat_bin, os.X_OK):
1347:        harness = "swarm" if ctx == "swarm" else "marathon"
1353:            subprocess.run([xyz_heartbeat_bin, harness, sid], env=env,
1358:    def xyz_marathon_heartbeat_write():
1359:        _heartbeat(clear=False)
1361:    def xyz_marathon_heartbeat_clear():
1362:        _heartbeat(clear=True)
1407:        # reads green. Strict only here, where the harness CHOSE this gate: an operator who passes
1417:    # resolve_force_relay_task). Resolved HERE — before render, the receipt
1418:    # (_RESULT["token"]), heartbeat, and seed — so every downstream consumer sees exactly one
1419:    # token identity. The lane-attempt key stays lane/phase-keyed.
1423:    # GH-207: a marathon lane namespaces its phase paths + attempt state so two lanes sharing a bare
1429:    # BOTH halves of Phase 2 — the driver heartbeat AND the --log-github run log — existed only in
1432:    # neither one ever executed. #322 scoped this as "the run-log half only, the heartbeat is already
1433:    # in the Python twin (12 references)"; those 12 matches are xyz_marathon_heartbeat_* — the GH-75
1434:    # XYZ.heartbeat.json session record, a different file and a different feature. Before this change
1435:    # `grep -c driver_heartbeat utils/py/marathon_drive.py` was 0, so the observability Phase 2 was
1469:    # question only a READER of the heartbeat file asks, and this lane is the writer; the reader
1470:    # (rtl_driver_heartbeat_status, relay-turn-lib.sh) still honors the variable. The one consumer
1473:    def driver_heartbeat_path():
1476:        return get_env("RTL_DRIVER_HEARTBEAT_FILE") or os.path.join(root, ".tick", "driver-heartbeat.json")
1480:    def driver_heartbeat_write():
1481:        # Same record and the same atomic mkstemp+os.replace as rtl_driver_heartbeat_write, so a
1482:        # heartbeat written by either twin is byte-compatible with readers of the other.
1483:        path = driver_heartbeat_path()
1495:            fd, tmp = tempfile.mkstemp(dir=directory, prefix=".driver-heartbeat.", suffix=".tmp")
1511:    def driver_heartbeat_clear():
1513:            os.remove(driver_heartbeat_path())
1517:    # GH-333: there is deliberately NO driver_heartbeat_status() here. Its only caller was the run
1519:    # asked before clearing the heartbeat, and the PID it tested belonged to the process asking. The
1522:    # The heartbeat FILE is the real deliverable and is unchanged: this lane still writes and clears
1524:    # (`rtl_driver_heartbeat_status`), which is a shared runtime dependency, not a frozen twin.
1527:    def driver_heartbeat_start():
1531:        if not driver_heartbeat_write():
1532:            log("driver heartbeat unavailable — continuing without liveness record")
1542:                driver_heartbeat_write()
1546:    def driver_heartbeat_stop():
1550:            driver_heartbeat_clear()
1590:                timeout=5,
1618:            marker = f"<!-- xyz-qa-receipt: issue={issue} phase={args.phase_id} sha={head_sha} -->"
1641:            log(f"posted QA attestation receipt to {repo}#{issue}")
1763:        # heartbeat), then stop the heartbeat, then the cost summary. Each part is independently
1770:            driver_heartbeat_stop()
1819:                with open(os.path.join(xyz_harness, ".relay-scratch", "last-turn-incident.json"),
1833:                        capture_output=True, text=True, timeout=5,
2044:    # fitness is a quality claim, and HARNESS-MODELS-REGISTRY.md grades it per harness separately
2134:            ts_base = subprocess.check_output(f"source \"{os.path.join(xyz_harness, 'relay-automation', 'relay-turn-lib.sh')}\" && rtl_transcript_root \"{root}\"", shell=True, executable="/bin/bash").decode('utf-8').strip()
2163:            with open(os.path.join(xyz_harness, ".relay-scratch", "last-turn-incident.json"),
2228:            ts_base = subprocess.check_output(f"source \"{os.path.join(xyz_harness, 'relay-automation', 'relay-turn-lib.sh')}\" && rtl_transcript_root \"{root}\"", shell=True, executable="/bin/bash").decode('utf-8').strip()
2254:    # (test/xyz-harness-hooks.sh reads XYZ_HARNESS_CONTEXT / XYZ_SESSION_ID;
2317:    # builder wrote — yet it ran with no timeout, no resource bounds, and in the marathon's own
2519:        # builder turn made progress.
2522:        # deliverable is REMOVING a path could never register progress — the artifact is gone, which
2623:    # also called from the GH-274 already-satisfied path at a point where the guard has not run yet —
2624:    # a NameError there would turn a healthy already-satisfied phase into a crash. On that path the
2640:        closeout = os.path.join(xyz_harness, "relay-automation", "marathon-closeout.sh")
2699:        if success_mode == "already-satisfied":
2700:            success_text = f"phase {args.phase_id} complete — lane_already_satisfied, reviewer approved, gate passed"
2701:            _RESULT["reason"] = "already-satisfied"
2705:        # GH-505/GH-509: no success is published — no approved event, no green, no receipt — unless
2707:        # relay file was rendered for (a --retry derivative on an already-satisfied lane).
2708:        attested_task = completed_relay_task() if success_mode == "already-satisfied" else relay_task
2720:        lane_attempt_reset(get_env("TICK_REPO_ROOT", root), lane_state_key)
2729:            # the hook may move HEAD — the receipt names ONE validated candidate, taken after it
2742:                receipt_py = os.path.join(xyz_harness, "utils", "py", "gate_receipt.py")
2743:                if os.path.isfile(receipt_py):
2745:                        ["python3", receipt_py, "write", "--repo", root, "--sha", head_sha,
2758:    # (re)build or (re)review — the only reason to re-invoke marathon-drive for it is to retry a
2762:    # Checked before the render (below); extends GH-207's already-satisfied detection
2763:    # (recover_already_satisfied_lane, triggered mid-relay on a no-progress reroute) to this
2764:    # separate post-terminal-gate-retry trigger. DRY_RUN is exempted: its whole point is to
2786:        # this run computed. A phase that once failed and was re-run with --retry completes on a
2787:        # suffixed token (GH-116 allocates -2, -3, ...), while the base name keeps the dead attempt's
2788:        # state forever. A later run without --retry then reads the base token, sees "not done", and
2793:        # directive, and that render is redone on every fire including the retry — so the file is an
2796:        # ever reach done", which would wrongly satisfy a lane whose retry belonged to another run.
2805:        # was anchored to the harness-computed name, which the builder cannot influence. Two limits
2809:        #      the file at all. This is what --retry passes, and a retry must never be satisfied by
2810:        #      the attempt it was invoked to retry.
2812:        #      derived base itself, or one of GH-116's `-<n>` retry derivatives of it. Anything else
2824:        log(f"relay directive names task '{recorded}', which is not {relay_task} or a retry derivative of it "
2858:        complete_phase_success("already-satisfied")
2860:    # GH-491: --retry (which arrives here as an explicit --relay-task) deliberately bypasses the
2862:    # the file, because "a retry must never be satisfied by the attempt it was invoked to retry". That
2869:    # `done` afterwards — every one of those turns was avoidable by re-firing without --retry.
2871:    # Advisory ONLY. --retry still rebuilds, because deliberately rebuilding an approved phase is
2879:                log(f"phase {args.phase_id}: --retry given, so this run REBUILDS. But the relay is already "
2881:                    f"WITHOUT --retry would have re-run only the pre-advance gate and dispatched no "
2913:    # in whatever repo it resolved to — the harness itself when no MARATHON_ROOT/--phases-dir was
2914:    # given. Both the reads below (phase brief, prior-attempt peek) work fine against a phase dir that
2928:    # GH-162: peek at prior attempts BEFORE rendering so a re-fired phase carries the debug-mantra note.
2929:    debug_mantra_prior = debug_mantra_prior_attempts(get_env("TICK_REPO_ROOT", root), lane_state_key)
2931:        debug_mantra_prior, phase_dir, os.path.join(xyz_harness, "relay-automation", "DEBUG-MANTRA.md"))
2938:        builder_scope_line = f"Edit ONLY these paths: {rel_relay} and {args.artifact_paths}. Do NOT run git. Do NOT touch any other file — the harness commits for you."
2953:        builder_scope_line = f"Edit ONLY {rel_relay}. Do NOT run git. Do NOT touch any other file — the harness commits for you."
3020:        # touching .tick/attempts/<lane>, which is the state that test hand-seeds. That need is real;
3033:    # checked it. So a repo that deliberately ignores harness output (a public one, or a vendored
3062:                os.path.join(xyz_harness, "relay-automation", "relay-turn-lib.sh"), root),
3098:        log(f"preflight: phase write-set commits to {commit_root}, not the harness root — "
3113:    # to", and against THAT repo's trunk rather than the harness's: under --target-root they are
3114:    # different repos with different defaults, and checking the harness's would be the plausible
3191:        # on the branch its earlier attempt already built, or each attempt strands its commits on a
3192:        # branch of its own and the PR shows one attempt's worth of work.
3216:            eprint("  Deliberately NOT covered by --force: that bypasses the per-lane attempt cap, and")
3217:            eprint("  retrying a flaky lane must not silently grant permission to land on a shared")
3272:    # The outer marathon-drive invocation owns this lane's attempt count. A parent relay-drive
3277:    lane_attempt_gate(get_env("TICK_REPO_ROOT", root), lane_state_key, args.force)
3291:    # heartbeat. Same placement as MARATHON_DRIVE_STARTED=1 + marathon_driver_heartbeat_start in the
3295:    driver_heartbeat_start()
3299:        reason_file = os.path.join(xyz_harness, ".relay-scratch", "escalation-reason")
3305:        incident_file = os.path.join(xyz_harness, ".relay-scratch", "last-turn-incident.json")
3333:        # utils/py/codex-turn.py:26), which nothing set — so the shim guarded the harness while the
3349:        # deepseek turn was resolving containment against the harness clone, not the target.
3357:    xyz_marathon_heartbeat_write()
3359:    _atexit.register(xyz_marathon_heartbeat_clear)
3378:    def recover_already_satisfied_lane():
3380:        # ONE routed reviewer pass instead of a false no-progress escalation. Returns 0 to route to
3381:        # complete_phase_success(already-satisfied); 3 to fall through to the ordinary no-progress halt.
3386:            log("already-satisfied probe: pre-advance gate FAILED — treating it as real no-progress")
3391:            if attested_terminal(where="already-satisfied probe") is None:
3393:            log(f"already-satisfied probe: relay already reached terminal agreement (STATUS: {s}, token done, attested)")
3401:            log(f"already-satisfied probe: artifact + gate are green, but current actor is {actor or 'none'} (token {tstatus or 'missing'}) — cannot auto-route to review")
3403:        log(f"already-satisfied probe: routed the stalled builder turn to reviewer {args.reviewer} for one approval pass")
3408:            log("already-satisfied probe: reviewer declined approval — lane remains unsatisfied")
3412:    timeout_reason = ["turn-timeout-or-hang"]
3413:    timeout_emit = [f"halted at phase {args.phase_id} — turn timeout / hang"]
3415:    def recover_timeout_exit():
3416:        # GH-205: a relay timeout (exit 7) whose declared artifact already landed AND left a live
3417:        # reviewer handoff is resumed with one more relay-drive pass instead of a false hang.
3432:        #   actor moved to the reviewer    -> resume         (token)
3438:        # What IS given up is the `timeout-gate-failed` early exit: a timed-out turn whose artifact was
3439:        # already red used to halt here, and now resumes to the reviewer, who rejects it. That costs
3452:        # still sets TIMEOUT_ESCALATION_REASON="timeout-gate-failed"
3460:            timeout_reason[0] = "timeout-no-artifact"
3461:            timeout_emit[0] = f"halted at phase {args.phase_id} — timed-out builder produced no declared artifact"
3469:            if attested_terminal(where="timeout probe") is None:
3471:            log(f"timeout probe: relay already reached terminal agreement (STATUS: {s}, token done, attested) — continuing")
3474:            timeout_reason[0] = "timeout-no-live-actor"
3475:            timeout_emit[0] = f"halted at phase {args.phase_id} — timed-out builder left no live reviewer handoff"
3476:            log(f"timeout probe: artifact landed, but {relay_task} has no live actor (STATUS: {s}) — cannot continue")
3479:            timeout_reason[0] = "timeout-builder-still-owned-turn"
3480:            timeout_emit[0] = f"halted at phase {args.phase_id} — timed-out builder never handed the relay to review"
3481:            log(f"timeout probe: builder still owns {relay_task} (STATUS: {s}) — treating this as a real hang")
3483:        log(f"timeout probe: artifact landed and {relay_task} moved to {actor} — resuming relay-drive from the post-timeout state")
3486:            timeout_reason[0] = "timeout-during-review-recovery"
3487:            timeout_emit[0] = f"halted at phase {args.phase_id} — relay timed out again during review recovery"
3491:        _r = recover_timeout_exit()
3497:        if recover_already_satisfied_lane() == 0:
3498:            complete_phase_success("already-satisfied")
3499:        log("relay escalated: no-progress (relay-drive exit 3)")
3500:        escalate("no-progress", 3)
3501:        xyz_marathon_emit("red", f"halted at phase {args.phase_id} — relay no-progress")
3505:        reason_file = os.path.join(xyz_harness, ".relay-scratch", "escalation-reason")
3531:        if timeout_reason[0] != "turn-timeout-or-hang":
3532:            reason, emit = timeout_reason[0], timeout_emit[0]
3549:        log("relay escalated: timeout / hang (relay-drive exit 7)")
3550:        escalate(timeout_reason[0], 7)
3551:        xyz_marathon_emit("red", timeout_emit[0])
3558:    # GH-284 P2 / GH-322: the Bash twin runs its run log + heartbeat stop from an EXIT trap that
3561:    # first, hooks run in a `finally` (so an exception path still clears the heartbeat), and the
3604:            # in the result receipt — the two demand opposite responses from a supervisor.

codex
I’m applying the recon and SWE skills to the design review, keeping the trace in this response as requested. Graph tools are unavailable in this session, so current source is the evidence base.

exec
/bin/zsh -lc "wc -l relay-automation/marathon.sh utils/py/marathon_drive.py utils/py/consult.py utils/py/jog_run.py; rg -n 'wait|drive|progress|trap|resume|run.log|for .*phase' relay-automation/marathon.sh; rg -n '"'^(def |class )'"' utils/py/marathon_drive.py utils/py/consult.py utils/py/jog_run.py" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-13569-zsltpsy2
 succeeded in 0ms:
     362 relay-automation/marathon.sh
    3613 utils/py/marathon_drive.py
     938 utils/py/consult.py
    1780 utils/py/jog_run.py
    6693 total
5:# order, and runs each phase through marathon-drive.sh (the unmodified single-phase loop). Advances
6:# on phase approval; HALTS on the first phase failure (relay no-progress / cap / gate / containment),
7:# leaving that phase's ESCALATION.md (written by marathon-drive) and NOT starting later phases.
32:# its task name exactly as before. marathon-drive.sh already supports --relay-task natively; this is
33:# purely a marathon.sh-side task-name override, no change to marathon-drive.sh itself.
35:# The MARATHON.yaml phase fields drive each marathon-drive call: id→--phase-id, reviewer→--reviewer,
43:#   MARATHON_DRIVE      — marathon-drive.sh path (default: <harness-home>/relay-automation/marathon-drive.sh)
50:# Exit: 0 all phases approved · N the failing phase's marathon-drive exit code · 2 usage/parse error.
62:DRIVE_BIN="${MARATHON_DRIVE:-"$MARATHON_HOME/relay-automation/marathon-drive.sh"}"
71:# GH-75: the ONE whole-run completion record for a marathon.sh-orchestrated run. Each per-phase
72:# marathon-drive runs with XYZ_HARNESS_CONTEXT=marathon-phase (its own hook silent), so this is the
75:# emitting nothing — worse than a bare marathon-drive halt, which does emit red). Best-effort.
95:  --target-root DIR       Foreign git repo the BUILD lands in; forwarded to marathon-drive.sh (GH-11).
99:                          and relay-system/ on purpose): without it, marathon-drive's `git add` of
116:                          plainly instead: the driver detects the satisfied lane and re-runs only the
182:# ── GH-388: the chain run log ────────────────────────────────────────────────────────────────────
201:  # harness-home-exempt case. A missing lib costs the durability CHECK, not the run log.
212:  # second copy of that rule is how the run log and the per-phase transcripts would end up in
214:  # `|| _run_log_base=""` is load-bearing: under `set -e` an assignment whose command substitution
218:  _run_log_base="$(set +e; source "$MARATHON_HOME/relay-automation/relay-turn-lib.sh" >/dev/null 2>&1; rtl_transcript_root "$ROOT" 2>/dev/null)" || _run_log_base=""
219:  if [[ -z "$_run_log_base" ]]; then
224:      _run_log_base="$ROOT/relay-system"
230:  # Scoped to RELOCATION, matching rtl_default_log: a run log inside the repo being driven shares
233:  _run_log_reason="$(xyz_non_durable_reason "$_run_log_base")"
234:  if [[ -n "$_run_log_reason" ]] && [[ "$(_xyz_realish_path "$_run_log_base")" != "$(_xyz_realish_path "$ROOT")"/* ]]; then
235:    die "the resolved run-log root $_run_log_base is under $_run_log_reason, which this harness records as non-durable storage ($(xyz_non_durable_conf)), and it is OUTSIDE the repo being driven ($ROOT). A marathon's own record must survive a reboot — that is the whole of GH-388. Point XYZ_ARCHIVE_ROOT at a committed archive, or unset it."
238:  _run_log_dir="$_run_log_base/run-logs/$(date +%Y-%m-%d 2>/dev/null || echo unknown-date)"
239:  mkdir -p "$_run_log_dir" || die "could not create the run-log directory $_run_log_dir"
241:  MARATHON_RUN_LOG="$_run_log_dir/marathon-${_plan_slug}-$(date +%H%M%S 2>/dev/null || echo unknown)-$$.log"
251:  log "run log: $MARATHON_RUN_LOG"
283:  drive_args=( --phase-id "$id" --reviewer "$reviewer" --builder "$BUILDER"
285:  [[ -n "$PHASES_DIR" ]] && drive_args+=( --phases-dir "$PHASES_DIR" )
286:  [[ -n "$artifact" ]] && drive_args+=( --artifact "$artifact" )
287:  [[ -n "$TARGET_ROOT" ]] && drive_args+=( --target-root "$TARGET_ROOT" )
288:  [[ -n "$PRE_ADVANCE_CMD" ]] && drive_args+=( --pre-advance-cmd "$PRE_ADVANCE_CMD" )
289:  ((FORCE)) && drive_args+=( --force )   # GH-45: bypass the per-lane attempt cap for this run
291:  # marathon-drive.sh derive its default MARATHON-<ID>-TURN name, unaffected.
302:    drive_args+=( --relay-task "$retry_task" )
304:  if ((DRY_RUN)); then drive_args+=( --dry-run ); fi
307:  # GH-75: mark each per-phase marathon-drive call so its (and its nested relay-drive's) XYZ.json hook
313:      bash "$DRIVE_BIN" "${drive_args[@]}" || phase_exit=$?
316:      bash "$DRIVE_BIN" "${drive_args[@]}" || phase_exit=$?
319:    log "HALT: phase $id failed (marathon-drive exit $phase_exit) — chain stops; later phases NOT started"
321:      3) _halt_reason="relay no-progress" ;;
326:      *) _halt_reason="marathon-drive exit $phase_exit" ;;
utils/py/consult.py:14:def xyz_write_ops_log_append(pattern, cmd):
utils/py/consult.py:79:def _citation_window():
utils/py/consult.py:88:def rtl_has_uncited_claim(path, window=None):
utils/py/consult.py:119:def _rtl_norm(s):
utils/py/consult.py:123:def rtl_classify_cited_claims(transcript_path, prompt_path, window=None):
utils/py/consult.py:171:def die(msg):
utils/py/consult.py:175:def warn(msg):
utils/py/consult.py:178:def aider_answer_ok(out_path):
utils/py/consult.py:195:def advisor_answer_ok(out_path, model):
utils/py/consult.py:224:def consult_codex_attestation(out_path):
utils/py/consult.py:251:def consult_agy_isolation_breach(out_path, root):
utils/py/consult.py:269:def guarded_with_timeout(cmd, cwd, log_file, timeout_s, env=None, *, own_group=False):
utils/py/consult.py:280:def wait_with_idle_bound(proc, out_path, remaining_s):
utils/py/consult.py:330:def _kill_advisor_group(proc):
utils/py/consult.py:362:def surface_partial(out_path, model, marker):
utils/py/consult.py:379:def agy_auth_preflight(agy_bin, log_file):
utils/py/consult.py:457:def main():
utils/py/marathon_drive.py:52:def _exit_meaning(code):
utils/py/marathon_drive.py:107:def _result_outcome(code):
utils/py/marathon_drive.py:128:def _derive_issue_number(lane, task, brief_name):
utils/py/marathon_drive.py:137:def _result_cmd_out(cmd, cwd=None):
utils/py/marathon_drive.py:149:def write_terminal_result(code):
utils/py/marathon_drive.py:161:def _write_terminal_result_inner(code):
utils/py/marathon_drive.py:293:def _result_arm(args, root, target_root):
utils/py/marathon_drive.py:332:def runlog_find_comment_id(payload_text, marker):
utils/py/marathon_drive.py:377:def _json_esc(value):
utils/py/marathon_drive.py:388:def xyz_debug_log_enabled():
utils/py/marathon_drive.py:393:def xyz_debug_log_file(root):
utils/py/marathon_drive.py:398:def _xyz_debug_log_write(root, line):
utils/py/marathon_drive.py:407:def xyz_debug_log_append(root, severity, check, message,
utils/py/marathon_drive.py:431:def xyz_debug_log_stale_lock(root):
utils/py/marathon_drive.py:448:def xyz_harvest_findings(harvest_bin, relay_file, root, target_root, debug_log):
utils/py/marathon_drive.py:470:def _utc_now_z():
utils/py/marathon_drive.py:474:def eprint(*args, **kwargs):
utils/py/marathon_drive.py:477:def get_env(key, default=None):
utils/py/marathon_drive.py:480:def die(msg):
utils/py/marathon_drive.py:484:def log(msg):
utils/py/marathon_drive.py:487:def resolve_force_relay_task(base_task, tick_bin, force, explicit):
utils/py/marathon_drive.py:535:def run_tick_loud(cmd_args):
utils/py/marathon_drive.py:566:def preflight_write_set_trackable(repo_root, paths, transcript_paths=None):
utils/py/marathon_drive.py:662:def _repo_rel_prefix(path, root):
utils/py/marathon_drive.py:683:def phase_commit_root(root, phase_dir, target_root):
utils/py/marathon_drive.py:722:def _probe_bin(bin_name, role_label, agent_id):
utils/py/marathon_drive.py:739:def _probe_bin_or_file(candidates, role_label, agent_id, override_env):
utils/py/marathon_drive.py:757:def _probe_claude_bin(role_label):
utils/py/marathon_drive.py:771:def _probe_agent_bin(agent_id, role_label):
utils/py/marathon_drive.py:866:def _gate_tier():
utils/py/marathon_drive.py:876:def _gate_guard_config():
utils/py/marathon_drive.py:903:def _gate_group_rss_mb(pgid):
utils/py/marathon_drive.py:935:def _gate_rss_summary(peak_mb, readable, unreadable):
utils/py/marathon_drive.py:946:def _gate_kill_group(proc, reason):
utils/py/marathon_drive.py:962:def gate_guard_cpu_attribution(returncode, cpu_s):
utils/py/marathon_drive.py:980:def _phase_memory_sample(tag="", root=None, tick_bin=None, relay_task=None):
utils/py/marathon_drive.py:1042:def main():
utils/py/jog_run.py:64:class ContractError(Exception):
utils/py/jog_run.py:68:def _load_contract_json(path, expected_schema, what):
utils/py/jog_run.py:86:def load_marathon_invocation(path):
utils/py/jog_run.py:128:def load_marathon_result(path):
utils/py/jog_run.py:188:def validate_marathon_executor(args):
utils/py/jog_run.py:212:def _jog_state_paths(root, gid):
utils/py/jog_run.py:217:def _ledger_abs_path(root, gid, path):
utils/py/jog_run.py:229:def _ledger_rel_path(root, gid, path):
utils/py/jog_run.py:244:def jog_commit_supervisor_state(root, gh_num, exec_id):
utils/py/jog_run.py:287:def jog_resolve_ledger_gid(root, gh_num):
utils/py/jog_run.py:319:def jog_load_state(root, gid):
utils/py/jog_run.py:334:def jog_save_state(root, gid, state):
utils/py/jog_run.py:344:def jog_current_gid(root, gh_num):
utils/py/jog_run.py:356:def jog_verify_pr_before_merge(root, receipt, pr_number):
utils/py/jog_run.py:387:def jog_project_marathon_outcome(root, gh_num, receipt, auto_merge=False,
utils/py/jog_run.py:441:def jog_reconcile_cold_start(root, gh_nums):
utils/py/jog_run.py:491:def _marathon_argv_from_invocation(invocation, builder, reviewer):
utils/py/jog_run.py:514:def run_marathon_phase(root, gh_num, gid, builder, reviewer, auto_merge=False, mode="run"):
utils/py/jog_run.py:620:def _jog_latest_receipt(root, gid, outcomes=None):
utils/py/jog_run.py:645:def _jog_exec_dir(root, gid, record):
utils/py/jog_run.py:651:def jog_resume(root, gh_num, args=None):
utils/py/jog_run.py:707:def jog_retry_gate(root, gh_num, args):
utils/py/jog_run.py:729:def _jog_retry_gate_locked(root, gh_num, args):
utils/py/jog_run.py:813:def jog_retry_build(root, gh_num, args):
utils/py/jog_run.py:832:def _jog_retry_build_locked(root, gh_num, args):
utils/py/jog_run.py:858:def _gh_pr_view(root, pr_number):
utils/py/jog_run.py:871:def jog_land(root, gh_num, pr_arg=None):
utils/py/jog_run.py:1048:class JogSupervisorLock:
utils/py/jog_run.py:1116:def lint_probe(root, probe_cmd):
utils/py/jog_run.py:1138:def find_issue_doc(root, gh_num):
utils/py/jog_run.py:1152:def extract_probes_from_doc(doc_path):
utils/py/jog_run.py:1177:def promote_contract_to_working(root, gh_num, doc_path, interactive=True):
utils/py/jog_run.py:1265:def run_single_phase_drive(root, gh_num, builder="agy", reviewer=None, simulate=False):
utils/py/jog_run.py:1387:def _verify_legacy_pr_before_merge(root, pr_num):
utils/py/jog_run.py:1404:def _tick_bin(root):
utils/py/jog_run.py:1412:def _token_done(root, task):
utils/py/jog_run.py:1430:def _merge_reviewed_pr(root, pr_num, record, expected_candidate=None):
utils/py/jog_run.py:1468:def _legacy_attestation(root, gh_num, reviewer):
utils/py/jog_run.py:1481:def handle_landing_boundary(root, gh_num, auto_merge=False, reviewer=None, simulate=False):
utils/py/jog_run.py:1559:def jog_run_main(args=None):

exec
/bin/zsh -lc "nl -ba relay-automation/marathon.sh | sed -n '52,185p;239,362p'; rg -n 'heartbeat|attempt|already.satisfied|harness_home|HARNESS|timeout|Popen|wait\\(|result_json|receipt|retry|progress' utils/py/marathon_drive.py" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-13569-zsltpsy2
 succeeded in 0ms:
    52	HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    53	MARATHON_HOME="${MARATHON_HOME:-"$(cd "$HERE/.." && pwd)"}"
    54	if [[ -n "${MARATHON_ROOT:-}" ]]; then
    55	  ROOT="$MARATHON_ROOT"
    56	elif ROOT="$(git -C "${PWD:-.}" rev-parse --show-toplevel 2>/dev/null)"; then
    57	  :
    58	else
    59	  ROOT="$MARATHON_HOME"
    60	fi
    61	TICK_BIN="${TICK_BIN:-"$MARATHON_HOME/bin/tick"}"
    62	DRIVE_BIN="${MARATHON_DRIVE:-"$MARATHON_HOME/relay-automation/marathon-drive.sh"}"
    63	YAML_BIN="${MARATHON_YAML_BIN:-"$MARATHON_HOME/bin/marathon-yaml"}"
    64	CLOSEOUT_BIN="${MARATHON_CLOSEOUT_BIN:-"$MARATHON_HOME/relay-automation/marathon-closeout.sh"}"
    65	
    66	die() { printf 'marathon: %s\n' "$*" >&2; exit 2; }
    67	log() { printf 'marathon: %s\n' "$*"; }
    68	
    69	XYZ_APPEND_BIN="${XYZ_APPEND_BIN:-"$MARATHON_HOME/utils/telemetry/append-xyz-completion.sh"}"
    70	
    71	# GH-75: the ONE whole-run completion record for a marathon.sh-orchestrated run. Each per-phase
    72	# marathon-drive runs with XYZ_HARNESS_CONTEXT=marathon-phase (its own hook silent), so this is the
    73	# only place a marathon.sh run is recorded — on BOTH the success tail AND the halt path, so a failed
    74	# run isn't silently absent from XYZ.json (GH-75 review: an early halt used to skip the tail entirely,
    75	# emitting nothing — worse than a bare marathon-drive halt, which does emit red). Best-effort.
    76	xyz_marathon_run_emit() {  # <health> <description>
    77	  [[ -x "$XYZ_APPEND_BIN" ]] || return 0
    78	  local plan; plan="$(basename "$PLAN")"; plan="${plan%.*}"; [[ -n "$plan" ]] || plan="marathon"
    79	  "$XYZ_APPEND_BIN" marathon "$plan" "$1" "$plan" "$2" >/dev/null 2>&1 || true
    80	}
    81	
    82	usage() {
    83	  cat <<'EOF'
    84	Usage: marathon.sh --plan MARATHON.yaml [--builder A] [--phases-dir D] [--pre-advance-cmd C]
    85	                    [--dry-run] [--force] [--retry PHASE-ID] [--closeout-pr]
    86	
    87	  --plan PATH            MARATHON.yaml to run (required). Must resolve under PROJECT/2-WORKING/ in
    88	                          the target repo (GH-212) — exempt: paths under this harness's own home
    89	                          (shipped examples), or MARATHON_ALLOW_PLAN_OUTSIDE_WORKING=1.
    90	  --builder AGENT         Builder agent id (default: codex — no per-call API charge; bills via the
    91	                          Codex/ChatGPT subscription). --builder claude spawns a headless Claude
    92	                          Code CLI subprocess instead: a SEPARATE, PER-CALL API-BILLED turn-taker —
    93	                          an explicit, cost-acknowledged choice, not the default.
    94	  --phases-dir DIR        Where to create <dir>/<id>/ (default: <repo-root>/marathon-system).
    95	  --target-root DIR       Foreign git repo the BUILD lands in; forwarded to marathon-drive.sh (GH-11).
    96	                          The relay thread, tick token, marathon-system/ and relay-system/ transcripts all stay
    97	                          in THIS harness repo — only code changes land in DIR. Use this when the target
    98	                          repo cannot track harness output (e.g. a public repo that gitignores marathon-system/
    99	                          and relay-system/ on purpose): without it, marathon-drive's `git add` of
   100	                          RELAY.md / ESCALATION.md / the transcript fails and the phase HALTs.
   101	                          Plan and brief paths resolve against DIR when set.
   102	                          GH-255 — pick the right knob for what is actually ignored: if the target
   103	                          ignores ONLY relay-system/, prefer XYZ_ARCHIVE_ROOT (GH-30), which
   104	                          redirects just the transcripts and leaves the code artifact and the
   105	                          .tick token anchored to the target. --target-root is the answer when
   106	                          marathon-system/ is ignored too, because XYZ_ARCHIVE_ROOT does not
   107	                          redirect RELAY.md / ESCALATION.md and will leave that run blocked.
   108	  --pre-advance-cmd CMD   Gate before phase.approved (default: bash validate.sh, per phase).
   109	  --dry-run               Render each phase's relay file and print the tick seed; exit without running.
   110	  --force                 GH-45: bypass the per-lane attempt cap for this run.
   111	  --retry PHASE-ID        GH-116: retry one phase with a fresh relay-task suffix. This REBUILDS the
   112	                          phase — a full builder + reviewer cycle — because a retry must never be
   113	                          satisfied by the attempt it was invoked to retry.
   114	                          GH-491: if the phase's relay is already terminal (STATUS: Approved) and its
   115	                          token is done, and only the GATE went red, do NOT use this. Re-fire the plan
   116	                          plainly instead: the driver detects the satisfied lane and re-runs only the
   117	                          pre-advance gate, dispatching no turns. Use --retry when the ARTIFACT is what
   118	                          needs to change.
   119	  --closeout-pr           Open (but never merge) a PR after a successful marathon. Closeout failure is logged
   120	                          and does not change the successful marathon exit code.
   121	EOF
   122	}
   123	
   124	PLAN=""; BUILDER="codex"; PHASES_DIR=""; PRE_ADVANCE_CMD=""; DRY_RUN=0; FORCE=0; RETRY_PHASE=""; CLOSEOUT_PR=0
   125	TARGET_ROOT=""   # GH-11 passthrough: foreign repo the BUILD lands in; relay/transcripts stay in ROOT
   126	while (($# > 0)); do
   127	  case "$1" in
   128	    --plan)            PLAN="${2:-}"; shift 2 ;;
   129	    --builder)         BUILDER="${2:-}"; shift 2 ;;
   130	    --phases-dir)      PHASES_DIR="${2:-}"; shift 2 ;;
   131	    --target-root)     TARGET_ROOT="${2:-}"; shift 2 ;;
   132	    --pre-advance-cmd) PRE_ADVANCE_CMD="${2:-}"; shift 2 ;;
   133	    --dry-run)         DRY_RUN=1; shift ;;
   134	    --force)           FORCE=1; shift ;;   # GH-45: forward to each phase so a parked lane can be re-fired
   135	    --retry)           RETRY_PHASE="${2:-}"; shift 2 ;;   # GH-116: retry one phase with a fresh relay-task suffix
   136	    --closeout-pr)     CLOSEOUT_PR=1; shift ;;
   137	    --help)            usage; exit 0 ;;
   138	    *)                 die "unknown argument: $1" ;;
   139	  esac
   140	done
   141	[[ -n "$PLAN" ]] || { die "--plan MARATHON.yaml required"; }
   142	[[ -f "$PLAN" ]] || die "plan not found: $PLAN"
   143	
   144	# GH-212: plan-location guard. A marathon's plan artifacts (this YAML + its phase briefs) belong
   145	# under PROJECT/2-WORKING/<capture-doc>/, not a standalone top-level folder (e.g. marathon-plans/)
   146	# an agent might pattern-match from a prior repo. Exempt: paths under this harness's own home
   147	# (MARATHON_HOME) — shipped reference examples (e.g. MARATHON.example.yaml), not an agent-authored
   148	# plan for a target repo. Override for a legitimate non-default location:
   149	# MARATHON_ALLOW_PLAN_OUTSIDE_WORKING=1.
   150	_plan_abs="$(cd "$(dirname "$PLAN")" && pwd -P)/$(basename "$PLAN")"
   151	# Canonicalize with `pwd -P` unconditionally (relative AND already-absolute input): ROOT can come
   152	# from `git rev-parse --show-toplevel` (symlink-resolved) or a raw MARATHON_ROOT env override
   153	# (whatever form the caller passed), so either side of this comparison can be a logical (non -P)
   154	# path — canonicalize both or a macOS /var -> /private/var checkout falsely flags every plan.
   155	# symlinks (e.g. macOS /var -> /private/var), so a logical (non -P) comparison here would falsely
   156	# flag every plan as "outside" on such a checkout (same pitfall swarm-preflight.sh works around).
   157	# On a --target-root run the plan lives in the TARGET repo's PROJECT/2-WORKING/, not the harness's,
   158	# so this guard must measure against that repo — otherwise every cross-repo plan falsely "resolves
   159	# outside PROJECT/2-WORKING/" and dies. GH-212's intent is unchanged: the plan must sit under
   160	# PROJECT/2-WORKING/ of whichever repo owns it.
   161	_plan_base="${TARGET_ROOT:-$ROOT}"
   162	_root_canon="$(cd "$_plan_base" 2>/dev/null && pwd -P || printf '%s' "$_plan_base")"
   163	_home_canon="$(cd "$MARATHON_HOME" 2>/dev/null && pwd -P || printf '%s' "$MARATHON_HOME")"
   164	_plan_rel_root="${_plan_abs#"$_root_canon"/}"
   165	case "$_plan_rel_root" in
   166	  PROJECT/2-WORKING/*) ;;   # in the expected home — proceed
   167	  *)
   168	    case "$_plan_abs" in
   169	      "$_home_canon"/*) ;;   # harness-owned reference material — exempt
   170	      *)
   171	        if [[ "${MARATHON_ALLOW_PLAN_OUTSIDE_WORKING:-0}" != "1" ]]; then
   172	          die "plan '$PLAN' resolves outside PROJECT/2-WORKING/ (got: $_plan_rel_root). Marathon plans (MARATHON.yaml + phase briefs) belong under PROJECT/2-WORKING/<capture-doc>/, not a standalone folder — see GUIDING-PRINCIPLES.md Conventions. Override: MARATHON_ALLOW_PLAN_OUTSIDE_WORKING=1."
   173	        fi
   174	        log "MARATHON_ALLOW_PLAN_OUTSIDE_WORKING=1 — proceeding with a plan outside PROJECT/2-WORKING/ ($_plan_rel_root)"
   175	        ;;
   176	    esac
   177	    ;;
   178	esac
   179	
   180	export TICK_REPO_ROOT="$ROOT"
   181	
   182	# ── GH-388: the chain run log ────────────────────────────────────────────────────────────────────
   183	# This file persisted NOTHING of its own — no tee, no `exec >`, no log-file variable. What was
   184	# durable got written per phase, ON COMPLETION, so the phase that DIES is the one phase with no
   185	# record, and the chain-level narrative existed only on the operator's terminal. Whether any of it
   239	  mkdir -p "$_run_log_dir" || die "could not create the run-log directory $_run_log_dir"
   240	  _plan_slug="$(basename "${PLAN%.*}" | tr -c 'A-Za-z0-9._-' '_')"
   241	  MARATHON_RUN_LOG="$_run_log_dir/marathon-${_plan_slug}-$(date +%H%M%S 2>/dev/null || echo unknown)-$$.log"
   242	  export MARATHON_RUN_LOG
   243	
   244	  # `tee -a` via process substitution, so output is captured AS IT IS PRODUCED rather than buffered
   245	  # to the end — the whole point is that the record survives a run that never reaches its end.
   246	  # stderr is folded in: an escalation reason arriving on stderr and a phase heading on stdout,
   247	  # interleaved in one file, is the narrative an operator actually needs to read afterwards.
   248	  exec > >(tee -a "$MARATHON_RUN_LOG") 2>&1
   249	  # Printed at chain start, per acceptance: an operator has to know where to look afterwards, and
   250	  # afterwards is exactly when the terminal is gone.
   251	  log "run log: $MARATHON_RUN_LOG"
   252	fi
   253	
   254	# Parse + validate + resolve order. A malformed/cyclic plan halts the whole run here (exit 2).
   255	PLAN_TSV="$("$YAML_BIN" "$PLAN")" || die "plan parse failed (see above)"
   256	[[ -n "$PLAN_TSV" ]] || die "plan has no phases"
   257	PLAN_NAME="$(sed -n 's/^name:[[:space:]]*//p' "$PLAN" | head -n1 | sed 's/[[:space:]]*$//')"
   258	phase_count="$(printf '%s\n' "$PLAN_TSV" | grep -c .)"
   259	log "plan: $PLAN — $phase_count phase(s) in execution order"
   260	
   261	idx=0
   262	# Read TSV with a NON-whitespace field separator (US / \037): `IFS=$'\t' read` coalesces consecutive
   263	# tabs (tab is whitespace-class), which would collapse empty columns and shift every field. Translate
   264	# tabs → \037 so empty fields (no rounds / no depends_on / no artifact / no turn_timeout_s) are
   265	# preserved positionally.
   266	while IFS=$'\037' read -r id reviewer rounds depends_on brief artifact turn_timeout_s name; do
   267	  [[ -n "$id" ]] || continue
   268	  idx=$((idx + 1))
   269	  rounds="${rounds:-2}"
   270	  cap=$((2 * rounds + 1))
   271	  lane_ns=""
   272	  [[ -n "$PLAN_NAME" ]] && lane_ns="${PLAN_NAME}--${id}"
   273	  [[ -n "$brief" ]] || die "phase $id: no 'brief:' in the plan — a phase needs a task to run"
   274	  # Briefs live beside the plan, so they resolve against the repo the plan came from. On a
   275	  # --target-root run that is the TARGET repo, not this harness — resolving against $ROOT would
   276	  # look for the target's briefs inside the harness clone and die "brief file not found".
   277	  brief_base="${TARGET_ROOT:-$ROOT}"
   278	  case "$brief" in /*) brief_path="$brief" ;; *) brief_path="$brief_base/$brief" ;; esac
   279	  [[ -f "$brief_path" ]] || die "phase $id: brief file not found: $brief_path"
   280	
   281	  log "── phase $idx/$phase_count: $id (reviewer=$reviewer, round-cap=$cap${artifact:+, artifact=$artifact}${turn_timeout_s:+, turn-timeout=${turn_timeout_s}s}) ──"
   282	
   283	  drive_args=( --phase-id "$id" --reviewer "$reviewer" --builder "$BUILDER"
   284	               --phase-brief "$brief_path" --round-cap "$cap" )
   285	  [[ -n "$PHASES_DIR" ]] && drive_args+=( --phases-dir "$PHASES_DIR" )
   286	  [[ -n "$artifact" ]] && drive_args+=( --artifact "$artifact" )
   287	  [[ -n "$TARGET_ROOT" ]] && drive_args+=( --target-root "$TARGET_ROOT" )
   288	  [[ -n "$PRE_ADVANCE_CMD" ]] && drive_args+=( --pre-advance-cmd "$PRE_ADVANCE_CMD" )
   289	  ((FORCE)) && drive_args+=( --force )   # GH-45: bypass the per-lane attempt cap for this run
   290	  # GH-116: only the phase named by --retry gets a task-name override — every other phase still lets
   291	  # marathon-drive.sh derive its default MARATHON-<ID>-TURN name, unaffected.
   292	  if [[ -n "$RETRY_PHASE" && "$id" == "$RETRY_PHASE" ]]; then
   293	    id_upper="$(printf '%s' "$id" | tr '[:lower:]' '[:upper:]')"
   294	    retry_n=2
   295	    # First unused suffix, not a hardcoded -2: keep bumping while that task name already exists
   296	    # (tick info exits 0 once a task has any recorded state — spent or not, it's not reusable).
   297	    while "$TICK_BIN" info "MARATHON-${id_upper}-TURN-${retry_n}" >/dev/null 2>&1; do
   298	      retry_n=$((retry_n + 1))
   299	    done
   300	    retry_task="MARATHON-${id_upper}-TURN-${retry_n}"
   301	    log "phase $id: --retry requested — overriding relay task to $retry_task (first unused suffix)"
   302	    drive_args+=( --relay-task "$retry_task" )
   303	  fi
   304	  if ((DRY_RUN)); then drive_args+=( --dry-run ); fi
   305	
   306	  phase_exit=0
   307	  # GH-75: mark each per-phase marathon-drive call so its (and its nested relay-drive's) XYZ.json hook
   308	  # stays silent — this orchestrator emits a SINGLE harness:"marathon" whole-run record below, never
   309	  # one per phase.
   310	  if [[ -n "$turn_timeout_s" ]]; then
   311	    MARATHON_ROOT="$ROOT" MARATHON_LANE_NS="$lane_ns" TICK_BIN="$TICK_BIN" XYZ_HARNESS_CONTEXT=marathon-phase \
   312	      RELAY_TURN_TIMEOUT_S="$turn_timeout_s" \
   313	      bash "$DRIVE_BIN" "${drive_args[@]}" || phase_exit=$?
   314	  else
   315	    MARATHON_ROOT="$ROOT" MARATHON_LANE_NS="$lane_ns" TICK_BIN="$TICK_BIN" XYZ_HARNESS_CONTEXT=marathon-phase \
   316	      bash "$DRIVE_BIN" "${drive_args[@]}" || phase_exit=$?
   317	  fi
   318	  if [[ "$phase_exit" -ne 0 ]]; then
   319	    log "HALT: phase $id failed (marathon-drive exit $phase_exit) — chain stops; later phases NOT started"
   320	    case "$phase_exit" in
   321	      3) _halt_reason="relay no-progress" ;;
   322	      4) _halt_reason="relay cap/close-mismatch" ;;
   323	      5) _halt_reason="pre-advance gate failed" ;;
   324	      6) _halt_reason="containment violation" ;;
   325	      7) _halt_reason="turn timeout / hang" ;;
   326	      *) _halt_reason="marathon-drive exit $phase_exit" ;;
   327	    esac
   328	    xyz_marathon_run_emit red "halted at phase $idx of $phase_count ($id) — $_halt_reason"
   329	    exit "$phase_exit"
   330	  fi
   331	done < <(printf '%s\n' "$PLAN_TSV" | tr '\t' '\037')
   332	
   333	if ((DRY_RUN)); then
   334	  log "dry-run complete: $phase_count phase(s) would run in order"
   335	  exit 0
   336	fi
   337	
   338	if ((CLOSEOUT_PR)); then
   339	  closeout_plan="${PLAN_NAME:-$(basename "${PLAN%.*}")}"
   340	  closeout_event_dir="$ROOT/.tick/events"
   341	  closeout_event_count=0
   342	  closeout_event_types=""
   343	  if [[ -d "$closeout_event_dir" ]]; then
   344	    closeout_event_count="$(find "$closeout_event_dir" -type f -name '*.jsonl' -print | wc -l | tr -d '[:space:]')"
   345	    closeout_event_types="$(find "$closeout_event_dir" -type f -name '*.jsonl' -print | LC_ALL=C sort | while IFS= read -r event_file; do
   346	      sed -n 's/.*"type":"\([^"]*\)".*/\1/p' "$event_file"
   347	    done | LC_ALL=C sort -u | paste -sd, -)"
   348	  fi
   349	  closeout_notes="Marathon plan: $closeout_plan
   350	Phases approved: $phase_count/$phase_count
   351	Tick events: $closeout_event_count${closeout_event_types:+ ($closeout_event_types)}"
   352	  if ! bash "$CLOSEOUT_BIN" --repo "$ROOT" --auto-pr --title "Marathon: $closeout_plan" --notes "$closeout_notes"; then
   353	    log "closeout PR failed after successful marathon; leaving marathon successful"
   354	  fi
   355	fi
   356	"$TICK_BIN" log marathon.complete "MARATHON-RUN" --agent marathon > /dev/null 2>&1 || true
   357	
   358	# GH-75: the whole-run success record (title/sessionId = plan name, "N of M phase(s) approved").
   359	xyz_marathon_run_emit green "$phase_count of $phase_count phase(s) approved"
   360	
   361	log "marathon complete — all $phase_count phase(s) approved"
   362	exit 0
20:from harness_paths import harness_home, repo_root, resolve_tool, is_vendored  # noqa: E402
36:# `die()` and the lane-attempt cap all exit BEFORE the run log arms (drive_started).
41:    3: "no-progress escalation",
45:    7: "turn timeout / hang",
46:    8: "lane parked at the attempt cap",
65:# ── GH-280: opt-in durable terminal result receipt (marathon-drive/result@1) ──────────────────
67:# record: outcome, identity (issue/phase/lane/token/attempt), repo/branch/SHA, gate + acceptance
99:    "attempt_max": None,
100:    "pr_note": None,           # non-None when PR publication was attempted and failed
108:    """Map a driver exit code onto the receipt's outcome vocabulary."""
138:    """Best-effort stdout capture for the receipt's git/gh probes; failure yields None."""
140:        res = subprocess.run(cmd, cwd=cwd, capture_output=True, text=True, timeout=30)
151:    the process's real exit code — the receipt is a record, not a verdict override."""
157:        eprint(f"marathon-drive: result receipt could not be written "
189:    attempt_count = _RESULT.get("attempt_count")
190:    if attempt_count is None and lane and _RESULT.get("root"):
191:        attempts_file = os.path.join(_RESULT["root"], ".tick", "attempts",
193:        if os.path.isfile(attempts_file):
195:                with open(attempts_file, "r") as f:
196:                    attempt_count = sum(1 for _ in f)
200:    gate_receipt_path = None
202:        candidate = os.path.join(_RESULT["root"], ".xyz", "receipts", f"{head_sha}.json")
204:            gate_receipt_path = candidate
235:    receipt = {
247:        "attempt": {"count": attempt_count, "max": _RESULT.get("attempt_max")},
254:        "head_sha": head_sha,   # observational: HEAD at receipt-write time
266:            "receipt_path": gate_receipt_path,
281:            json.dump(receipt, f, indent=2)
290:    log(f"result receipt written: {target} (outcome: {outcome}, exit {code})")
305:            f"marathon-drive will not guess a location for the receipt")
326:        "attempt_max": int(os.environ.get("LANE_MAX_ATTEMPTS", "2") or 2),
343:    run log POSTed a duplicate every single time. test/gh284-runlog-heartbeat.sh missed that for a
562:        # exit-1 lock-contention meaning — record the real reason for the result receipt.
913:                             timeout=10)
959:    proc.wait()
986:            out = subprocess.run(["sysctl", "-n", "vm.swapusage"], capture_output=True, text=True, timeout=5).stdout
999:            out = subprocess.run(["vm_stat"], capture_output=True, text=True, timeout=5).stdout
1059:    # GH-402: deliberately NOT folded into --force. --force bypasses the per-lane attempt cap, which
1061:    # One flag for both would mean an operator retrying a flaky lane silently acquires permission to
1067:    # GH-280: opt-in durable terminal-result receipt for supervisors. No behavior change when unset.
1069:                        help="write a marathon-drive/result@1 JSON receipt at this path on every "
1072:                        help="caller-assigned execution ID recorded in the result receipt "
1085:        print("  --result-file PATH      GH-280 opt-in terminal result receipt (marathon-drive/result@1), written")
1087:        print("  --execution-id ID       GH-280 caller-assigned execution ID recorded in the result receipt.")
1121:    xyz_harness = harness_home()
1133:    # GH-280: arm the terminal-result receipt BEFORE anything below can die, so every refusal,
1134:    # escalation, and success path from here on produces exactly one receipt when requested.
1136:    # started a run, and a supervisor treats "exit non-zero, no receipt" as "driver never armed".
1143:    def lane_attempt_gate(root_dir, raw, force):
1146:        max_attempts = get_env("LANE_MAX_ATTEMPTS", "2")
1147:        try: max_attempts = int(max_attempts)
1148:        except ValueError: max_attempts = 2
1151:        attempts_dir = os.path.join(root_dir, ".tick", "attempts")
1152:        os.makedirs(attempts_dir, exist_ok=True)
1153:        attempts_file = os.path.join(attempts_dir, key)
1156:        if os.path.isfile(attempts_file):
1158:                with open(attempts_file, "r") as f:
1164:            eprint(f"lane-attempt-cap: --force override — lane {key} at {count} attempt(s) (cap {max_attempts}), proceeding.")
1165:        elif count >= max_attempts:
1166:            eprint(f"lane-attempt-cap: lane {key} PARKED after {count} attempt(s) (cap {max_attempts}) — no relay token seeded.")
1167:            eprint(f"  Re-anchor to the committed QUEUE lanes (AGENTS.md) or re-fire with --force. Attempts log: {attempts_file}")
1168:            # GH-280: the receipt reports the count that PARKED the lane; the attempts file
1169:            # still holds it here, but record it explicitly so the receipt survives any later
1171:            _RESULT["attempt_count"] = count
1178:                f"lane {raw} parked at attempt cap",
1190:        with open(attempts_file, "a") as f:
1192:        # GH-280: record the attempt this fire represents — complete_phase_success RESETS the
1193:        # attempts file, so a receipt that re-reads it after a green phase would report null
1195:        _RESULT["attempt_count"] = count + 1
1198:    def lane_attempt_reset(root_dir, raw):
1201:        attempts_file = os.path.join(root_dir, ".tick", "attempts", _lane_key(raw))
1202:        if os.path.exists(attempts_file):
1203:            try: os.remove(attempts_file)
1206:    def debug_mantra_prior_attempts(root_dir, raw):
1207:        # GH-162: READ-ONLY peek at the .tick/attempts/<lane> file GH-45 maintains — how many prior
1209:        f = os.path.join(root_dir, ".tick", "attempts", _lane_key(raw))
1219:        # GH-162: the note injected into the relay when a prior attempt exists; empty on a first fire
1235:        # full absolute path per line. This preamble renders ONLY on a retry, so the old form handed
1236:        # every re-attempt extra copies of the repo root — a recovery path that raised the very
1237:        # hazard it was retrying against, back when the containment scan failed turns on prose.
1257:        harness_root = harness_home()
1260:        out = (f"\n## Debug mantra (auto-triggered — {prior} prior attempt(s) on this phase did not reach Approved)\n\n"
1326:        ctx = get_env("XYZ_HARNESS_CONTEXT", "")
1337:    # GH-75/GH-249 lifecycle heartbeat: write operational liveness before driving the relay and clear
1340:    # xyz_marathon_heartbeat_write/clear (relay-automation/marathon-drive.sh).
1341:    xyz_heartbeat_bin = get_env("XYZ_HEARTBEAT_BIN", os.path.join(xyz_harness, "utils", "telemetry", "write-xyz-heartbeat.sh"))
1343:    def _heartbeat(clear):
1344:        if not os.access(xyz_heartbeat_bin, os.X_OK):
1346:        ctx = get_env("XYZ_HARNESS_CONTEXT", "")
1353:            subprocess.run([xyz_heartbeat_bin, harness, sid], env=env,
1358:    def xyz_marathon_heartbeat_write():
1359:        _heartbeat(clear=False)
1361:    def xyz_marathon_heartbeat_clear():
1362:        _heartbeat(clear=True)
1388:    # branch and ran the HARNESS's validate.sh against a foreign repo. Both branches below now use
1417:    # resolve_force_relay_task). Resolved HERE — before render, the receipt
1418:    # (_RESULT["token"]), heartbeat, and seed — so every downstream consumer sees exactly one
1419:    # token identity. The lane-attempt key stays lane/phase-keyed.
1423:    # GH-207: a marathon lane namespaces its phase paths + attempt state so two lanes sharing a bare
1429:    # BOTH halves of Phase 2 — the driver heartbeat AND the --log-github run log — existed only in
1432:    # neither one ever executed. #322 scoped this as "the run-log half only, the heartbeat is already
1433:    # in the Python twin (12 references)"; those 12 matches are xyz_marathon_heartbeat_* — the GH-75
1434:    # XYZ.heartbeat.json session record, a different file and a different feature. Before this change
1435:    # `grep -c driver_heartbeat utils/py/marathon_drive.py` was 0, so the observability Phase 2 was
1469:    # question only a READER of the heartbeat file asks, and this lane is the writer; the reader
1470:    # (rtl_driver_heartbeat_status, relay-turn-lib.sh) still honors the variable. The one consumer
1473:    def driver_heartbeat_path():
1476:        return get_env("RTL_DRIVER_HEARTBEAT_FILE") or os.path.join(root, ".tick", "driver-heartbeat.json")
1480:    def driver_heartbeat_write():
1481:        # Same record and the same atomic mkstemp+os.replace as rtl_driver_heartbeat_write, so a
1482:        # heartbeat written by either twin is byte-compatible with readers of the other.
1483:        path = driver_heartbeat_path()
1495:            fd, tmp = tempfile.mkstemp(dir=directory, prefix=".driver-heartbeat.", suffix=".tmp")
1511:    def driver_heartbeat_clear():
1513:            os.remove(driver_heartbeat_path())
1517:    # GH-333: there is deliberately NO driver_heartbeat_status() here. Its only caller was the run
1519:    # asked before clearing the heartbeat, and the PID it tested belonged to the process asking. The
1522:    # The heartbeat FILE is the real deliverable and is unchanged: this lane still writes and clears
1524:    # (`rtl_driver_heartbeat_status`), which is a shared runtime dependency, not a frozen twin.
1527:    def driver_heartbeat_start():
1531:        if not driver_heartbeat_write():
1532:            log("driver heartbeat unavailable — continuing without liveness record")
1541:            while not stop.wait(hb_interval):
1542:                driver_heartbeat_write()
1546:    def driver_heartbeat_stop():
1550:            driver_heartbeat_clear()
1590:                timeout=5,
1618:            marker = f"<!-- xyz-qa-receipt: issue={issue} phase={args.phase_id} sha={head_sha} -->"
1641:            log(f"posted QA attestation receipt to {repo}#{issue}")
1763:        # heartbeat), then stop the heartbeat, then the cost summary. Each part is independently
1770:            driver_heartbeat_stop()
1833:                        capture_output=True, text=True, timeout=5,
2044:    # fitness is a quality claim, and HARNESS-MODELS-REGISTRY.md grades it per harness separately
2048:    # assume. See PROJECT/1-INBOX/GH-346-HARNESS-GATEWAY-MODEL-RESOLUTION.md.
2254:    # (test/xyz-harness-hooks.sh reads XYZ_HARNESS_CONTEXT / XYZ_SESSION_ID;
2303:        "XYZ_HARNESS_CONTEXT", "XYZ_SESSION_ID",
2317:    # builder wrote — yet it ran with no timeout, no resource bounds, and in the marathon's own
2378:        proc = subprocess.Popen(cmd, shell=True, executable="/bin/bash", cwd=cwd, env=env,
2423:        #                       IS the process we wait on and Popen reports the signal negated.
2519:        # builder turn made progress.
2522:        # deliverable is REMOVING a path could never register progress — the artifact is gone, which
2623:    # also called from the GH-274 already-satisfied path at a point where the guard has not run yet —
2624:    # a NameError there would turn a healthy already-satisfied phase into a crash. On that path the
2699:        if success_mode == "already-satisfied":
2700:            success_text = f"phase {args.phase_id} complete — lane_already_satisfied, reviewer approved, gate passed"
2701:            _RESULT["reason"] = "already-satisfied"
2705:        # GH-505/GH-509: no success is published — no approved event, no green, no receipt — unless
2707:        # relay file was rendered for (a --retry derivative on an already-satisfied lane).
2708:        attested_task = completed_relay_task() if success_mode == "already-satisfied" else relay_task
2720:        lane_attempt_reset(get_env("TICK_REPO_ROOT", root), lane_state_key)
2729:            # the hook may move HEAD — the receipt names ONE validated candidate, taken after it
2742:                receipt_py = os.path.join(xyz_harness, "utils", "py", "gate_receipt.py")
2743:                if os.path.isfile(receipt_py):
2745:                        ["python3", receipt_py, "write", "--repo", root, "--sha", head_sha,
2758:    # (re)build or (re)review — the only reason to re-invoke marathon-drive for it is to retry a
2762:    # Checked before the render (below); extends GH-207's already-satisfied detection
2763:    # (recover_already_satisfied_lane, triggered mid-relay on a no-progress reroute) to this
2764:    # separate post-terminal-gate-retry trigger. DRY_RUN is exempted: its whole point is to
2786:        # this run computed. A phase that once failed and was re-run with --retry completes on a
2787:        # suffixed token (GH-116 allocates -2, -3, ...), while the base name keeps the dead attempt's
2788:        # state forever. A later run without --retry then reads the base token, sees "not done", and
2793:        # directive, and that render is redone on every fire including the retry — so the file is an
2796:        # ever reach done", which would wrongly satisfy a lane whose retry belonged to another run.
2809:        #      the file at all. This is what --retry passes, and a retry must never be satisfied by
2810:        #      the attempt it was invoked to retry.
2812:        #      derived base itself, or one of GH-116's `-<n>` retry derivatives of it. Anything else
2824:        log(f"relay directive names task '{recorded}', which is not {relay_task} or a retry derivative of it "
2858:        complete_phase_success("already-satisfied")
2860:    # GH-491: --retry (which arrives here as an explicit --relay-task) deliberately bypasses the
2862:    # the file, because "a retry must never be satisfied by the attempt it was invoked to retry". That
2869:    # `done` afterwards — every one of those turns was avoidable by re-firing without --retry.
2871:    # Advisory ONLY. --retry still rebuilds, because deliberately rebuilding an approved phase is
2879:                log(f"phase {args.phase_id}: --retry given, so this run REBUILDS. But the relay is already "
2881:                    f"WITHOUT --retry would have re-run only the pre-advance gate and dispatched no "
2914:    # given. Both the reads below (phase brief, prior-attempt peek) work fine against a phase dir that
2928:    # GH-162: peek at prior attempts BEFORE rendering so a re-fired phase carries the debug-mantra note.
2929:    debug_mantra_prior = debug_mantra_prior_attempts(get_env("TICK_REPO_ROOT", root), lane_state_key)
3020:        # touching .tick/attempts/<lane>, which is the state that test hand-seeds. That need is real;
3191:        # on the branch its earlier attempt already built, or each attempt strands its commits on a
3192:        # branch of its own and the PR shows one attempt's worth of work.
3216:            eprint("  Deliberately NOT covered by --force: that bypasses the per-lane attempt cap, and")
3217:            eprint("  retrying a flaky lane must not silently grant permission to land on a shared")
3272:    # The outer marathon-drive invocation owns this lane's attempt count. A parent relay-drive
3277:    lane_attempt_gate(get_env("TICK_REPO_ROOT", root), lane_state_key, args.force)
3291:    # heartbeat. Same placement as MARATHON_DRIVE_STARTED=1 + marathon_driver_heartbeat_start in the
3295:    driver_heartbeat_start()
3325:        env2["XYZ_HARNESS_CONTEXT"] = "marathon-phase"
3357:    xyz_marathon_heartbeat_write()
3359:    _atexit.register(xyz_marathon_heartbeat_clear)
3378:    def recover_already_satisfied_lane():
3380:        # ONE routed reviewer pass instead of a false no-progress escalation. Returns 0 to route to
3381:        # complete_phase_success(already-satisfied); 3 to fall through to the ordinary no-progress halt.
3386:            log("already-satisfied probe: pre-advance gate FAILED — treating it as real no-progress")
3391:            if attested_terminal(where="already-satisfied probe") is None:
3393:            log(f"already-satisfied probe: relay already reached terminal agreement (STATUS: {s}, token done, attested)")
3401:            log(f"already-satisfied probe: artifact + gate are green, but current actor is {actor or 'none'} (token {tstatus or 'missing'}) — cannot auto-route to review")
3403:        log(f"already-satisfied probe: routed the stalled builder turn to reviewer {args.reviewer} for one approval pass")
3408:            log("already-satisfied probe: reviewer declined approval — lane remains unsatisfied")
3412:    timeout_reason = ["turn-timeout-or-hang"]
3413:    timeout_emit = [f"halted at phase {args.phase_id} — turn timeout / hang"]
3415:    def recover_timeout_exit():
3416:        # GH-205: a relay timeout (exit 7) whose declared artifact already landed AND left a live
3438:        # What IS given up is the `timeout-gate-failed` early exit: a timed-out turn whose artifact was
3452:        # still sets TIMEOUT_ESCALATION_REASON="timeout-gate-failed"
3460:            timeout_reason[0] = "timeout-no-artifact"
3461:            timeout_emit[0] = f"halted at phase {args.phase_id} — timed-out builder produced no declared artifact"
3469:            if attested_terminal(where="timeout probe") is None:
3471:            log(f"timeout probe: relay already reached terminal agreement (STATUS: {s}, token done, attested) — continuing")
3474:            timeout_reason[0] = "timeout-no-live-actor"
3475:            timeout_emit[0] = f"halted at phase {args.phase_id} — timed-out builder left no live reviewer handoff"
3476:            log(f"timeout probe: artifact landed, but {relay_task} has no live actor (STATUS: {s}) — cannot continue")
3479:            timeout_reason[0] = "timeout-builder-still-owned-turn"
3480:            timeout_emit[0] = f"halted at phase {args.phase_id} — timed-out builder never handed the relay to review"
3481:            log(f"timeout probe: builder still owns {relay_task} (STATUS: {s}) — treating this as a real hang")
3483:        log(f"timeout probe: artifact landed and {relay_task} moved to {actor} — resuming relay-drive from the post-timeout state")
3486:            timeout_reason[0] = "timeout-during-review-recovery"
3487:            timeout_emit[0] = f"halted at phase {args.phase_id} — relay timed out again during review recovery"
3491:        _r = recover_timeout_exit()
3497:        if recover_already_satisfied_lane() == 0:
3498:            complete_phase_success("already-satisfied")
3499:        log("relay escalated: no-progress (relay-drive exit 3)")
3500:        escalate("no-progress", 3)
3501:        xyz_marathon_emit("red", f"halted at phase {args.phase_id} — relay no-progress")
3531:        if timeout_reason[0] != "turn-timeout-or-hang":
3532:            reason, emit = timeout_reason[0], timeout_emit[0]
3549:        log("relay escalated: timeout / hang (relay-drive exit 7)")
3550:        escalate(timeout_reason[0], 7)
3551:        xyz_marathon_emit("red", timeout_emit[0])
3558:    # GH-284 P2 / GH-322: the Bash twin runs its run log + heartbeat stop from an EXIT trap that
3561:    # first, hooks run in a `finally` (so an exception path still clears the heartbeat), and the
3604:            # in the result receipt — the two demand opposite responses from a supervisor.

exec
/bin/zsh -lc "nl -ba utils/py/jog_run.py | sed -n '491,619p;651,855p'; nl -ba utils/py/harness_paths.py | sed -n '1,230p'" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-13569-zsltpsy2
 succeeded in 0ms:
   491	def _marathon_argv_from_invocation(invocation, builder, reviewer):
   492	    """The packet's argv with Jog's supervisor policy applied.
   493	
   494	    Policy overrides, in one place so every dispatch path (run / retry-gate / retry-build)
   495	    stays identical: the operator's reviewer/builder replace the packet's suggestions, the
   496	    packet's --require-clean is dropped (a supervisor's own queue writes make the tree
   497	    legitimately non-pristine between lease and dispatch), and the packet's suggested
   498	    per-issue phase id is adopted so Marathon's lane namespace (and its attempt cap) stays
   499	    per-issue instead of collapsing onto marathon's bare 'p1' default.
   500	    """
   501	    argv = list(invocation["argv"])
   502	    for flag, value in (("--reviewer", reviewer), ("--builder", builder)):
   503	        if flag in argv:
   504	            argv[argv.index(flag) + 1] = value
   505	        else:
   506	            argv += [flag, value]
   507	    if "--require-clean" in argv:
   508	        argv.remove("--require-clean")
   509	    if "--phase-id" not in argv and invocation.get("phase"):
   510	        argv += ["--phase-id", invocation["phase"]]
   511	    return argv
   512	
   513	
   514	def run_marathon_phase(root, gh_num, gid, builder, reviewer, auto_merge=False, mode="run"):
   515	    """Execute one leased queue item through Preflight → Marathon's one-phase driver.
   516	
   517	    Returns (queue_status, failure_reason): one of ("completed", reason) / ("parked", reason) /
   518	    ("failed", reason) for jog_set_status. All durable state lands in the execution ledger
   519	    under .tick/jog/<gid>/ so a restart can reconcile without a second dispatch.
   520	    """
   521	    home = harness_home()
   522	    preflight_py = os.path.join(home, "utils", "py", "swarm_preflight.py")
   523	    if not os.path.isfile(preflight_py):
   524	        return "parked", f"marathon executor: swarm_preflight not found at {preflight_py} " \
   525	                        f"(vendored installs resolve .xyz via the harness home — GH-279 #2)"
   526	
   527	    state = jog_load_state(root, gid)
   528	    exec_id = f"gh{gh_num}-exec{len(state['executions']) + 1}"
   529	    exec_dir = os.path.join(_jog_state_paths(root, gid)[0], exec_id)
   530	    packet_dir = os.path.join(exec_dir, "preflight")
   531	    record = {
   532	        "execution_id": exec_id,
   533	        "mode": mode,
   534	        "started_at": _dt.datetime.now(_dt.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
   535	        "status": "dispatched",
   536	        # GH-292 F2: ledger-internal paths are stored RELATIVE to the ledger base so the
   537	        # history survives a queue-row re-add (fresh gid) without re-key surgery.
   538	        "packet_dir": _ledger_rel_path(root, gid, packet_dir),
   539	        "result_path": None,
   540	    }
   541	    state["executions"].append(record)
   542	    state["gh_number"] = gh_num
   543	    jog_save_state(root, gid, state)
   544	    print(f"jog: marathon execution {exec_id} for GH-{gh_num} (packet: {packet_dir})")
   545	
   546	    pf = subprocess.run(
   547	        [sys.executable, preflight_py, "--gh-issue", str(gh_num), "--out", packet_dir],
   548	        cwd=root, capture_output=True, text=True)
   549	    if pf.returncode == 4:
   550	        record["status"] = "completed-preflight-stale"
   551	        jog_save_state(root, gid, state)
   552	        return "completed", "preflight: already-landed"
   553	    if pf.returncode != 0:
   554	        record["status"] = "preflight-refused"
   555	        jog_save_state(root, gid, state)
   556	        tail = (pf.stderr or pf.stdout or "").strip().splitlines()
   557	        detail = tail[-1][:200] if tail else ""
   558	        return "parked", f"preflight-refused (exit {pf.returncode}){': ' + detail if detail else ''}"
   559	
   560	    invocation_path = os.path.join(packet_dir, "marathon-invocation.json")
   561	    try:
   562	        invocation = load_marathon_invocation(invocation_path)
   563	    except ContractError as exc:
   564	        record["status"] = "invalid-invocation"
   565	        jog_save_state(root, gid, state)
   566	        return "parked", f"invalid marathon invocation artifact: {exc}"
   567	
   568	    argv = _marathon_argv_from_invocation(invocation, builder, reviewer)
   569	    if mode == "retry-build":
   570	        # A rebuild must not be satisfied by the attempt it retries (GH-491): dispatch on a
   571	        # FRESH suffixed token in the same family. The spent token's history stays untouched —
   572	        # Tick events are append-only and prior execution records are never deleted.
   573	        prior_record, prior_receipt = _jog_latest_receipt(root, gid)
   574	        prior_token = (prior_receipt or {}).get("token")
   575	        if prior_token:
   576	            argv += ["--relay-task", f"{prior_token}-{len(state['executions'])}"]
   577	    argv += ["--execution-id", exec_id]
   578	    record["result_path"] = _ledger_rel_path(root, gid, invocation["result_path"])
   579	    # PR #281 review B4: persist the result path BEFORE dispatch — a crash mid-drive otherwise
   580	    # orphans a receipt that was actually written (the ledger's newest record still says null).
   581	    jog_save_state(root, gid, state)
   582	
   583	    env = dict(os.environ)
   584	    env.update(invocation["env"])
   585	    # Jog already holds the outer driver lock; exporting it keeps marathon-drive from
   586	    # contending with its own supervisor on the same lock directory.
   587	    env["RELAY_DRIVER_LOCKED"] = "1"
   588	
   589	    # GH-292 F1: supervisor-owned writes are committed BEFORE any turn dispatches, so the
   590	    # supervisor's to revert.
   591	    jog_commit_supervisor_state(root, gh_num, exec_id)
   592	
   593	    print(f"jog: dispatching marathon-drive ({invocation['drive_command']})")
   594	    proc = subprocess.run(argv, cwd=invocation["target_root"], env=env)
   595	    record["drive_exit"] = proc.returncode
   596	
   597	    try:
   598	        receipt = load_marathon_result(invocation["result_path"])
   599	    except ContractError as exc:
   600	        record["status"] = "no-valid-result"
   601	        jog_save_state(root, gid, state)
   602	        return "failed", (f"marathon-drive exited {proc.returncode} without a valid result "
   603	                          f"receipt: {exc}")
   604	    record["status"] = "terminal"
   605	    record["outcome"] = receipt["outcome"]
   606	    record["reason"] = receipt["reason"]
   607	    jog_save_state(root, gid, state)
   608	
   609	    action, reason = jog_project_marathon_outcome(
   610	        root, gh_num, receipt, auto_merge=auto_merge,
   611	        execution_id=exec_id, result_path=invocation["result_path"])
   612	    record["status"] = f"projected-{action}"
   613	    record["projected_reason"] = reason
   614	    jog_save_state(root, gid, state)
   615	    return action, reason
   616	
   617	
   618	# ── GH-280 Phase 3: explicit resume / gate-only retry / rebuild / landing semantics ────────────
   619	
   651	def jog_resume(root, gh_num, args=None):
   652	    """`jog resume <GH>` — reconcile existing durable state, spend nothing.
   653	
   654	    Reconciliation only: a valid terminal receipt is re-projected idempotently (no dispatch,
   655	    no token); a dispatched execution without a receipt parks the row (the operator chooses
   656	    retry-build); anything else is reported. Resume never fires Marathon on its own — a new
   657	    fire is always the explicit retry-build decision."""
   658	    gid = jog_resolve_ledger_gid(root, gh_num)
   659	    if not gid:
   660	        print(f"jog: GH-{gh_num} is not in the jog queue")
   661	        sys.exit(2)
   662	    state = jog_load_state(root, gid)
   663	    executions = state.get("executions") or []
   664	    if not executions:
   665	        print(f"jog: GH-{gh_num} has no marathon execution state — run `releases jog run "
   666	              f"--reviewer <agent>` (marathon is the default executor) or `jog retry-build` "
   667	              f"to dispatch")
   668	        return 0
   669	
   670	    latest = executions[-1]
   671	    record, receipt = _jog_latest_receipt(root, gid)
   672	    if record is not None and record.get("execution_id") == latest.get("execution_id"):
   673	        action, reason = jog_project_marathon_outcome(
   674	            root, gh_num, receipt,
   675	            execution_id=latest.get("execution_id"), result_path=latest.get("result_path"))
   676	        latest["status"] = f"projected-{action}"
   677	        latest["projected_reason"] = reason
   678	        jog_save_state(root, gid, state)
   679	        jog_set_status(root, gh_num, action, failure_reason=reason)
   680	        print(f"jog: resume GH-{gh_num}: terminal Marathon result re-projected ({action}) — {reason}")
   681	        return 0
   682	    if latest.get("status") == "dispatched":
   683	        # GH-291 Scope 2: distinguish a future-schema/invalid receipt from a missing one —
   684	        # version skew must park with its cause named, not read as "no result".
   685	        load_error = None
   686	        _p = _ledger_abs_path(root, gid, latest.get("result_path"))
   687	        if _p and os.path.isfile(_p):
   688	            try:
   689	                load_marathon_result(_p)
   690	            except ContractError as exc:
   691	                load_error = str(exc)
   692	        latest["status"] = "cold-start-paused"
   693	        jog_save_state(root, gid, state)
   694	        jog_set_status(root, gh_num, "parked",
   695	                       failure_reason="resume: dispatched Marathon execution has no valid result "
   696	                                      "receipt"
   697	                                      + (f" (load error: {load_error})" if load_error else "")
   698	                                      + " — inspect, then `jog retry-build` if a rebuild is wanted")
   699	        print(f"jog: resume GH-{gh_num}: execution {latest.get('execution_id')} dispatched with no "
   700	              f"valid result{f' ({load_error})' if load_error else ''} — parked; no token spent")
   701	        return 1
   702	    print(f"jog: resume GH-{gh_num}: latest execution {latest.get('execution_id')} is "
   703	          f"'{latest.get('status')}' — nothing to reconcile; use jog retry-gate / retry-build / land")
   704	    return 0
   705	
   706	
   707	def jog_retry_gate(root, gh_num, args):
   708	    """`jog retry-gate <GH>` — re-run ONLY the gate against the same head SHA.
   709	
   710	    Marathon's native satisfied-lane path (GH-274) is the mechanism: with the phase's relay
   711	    terminal and its tick token done, re-invoking marathon-drive skips render/reseed/dispatch
   712	    and re-runs the pre-advance gate alone. Jog refuses if the head SHA moves during the
   713	    retry — that state needs retry-build, not a gate check."""
   714	    error = validate_marathon_executor(args)
   715	    if error:
   716	        print(f"jog: {error}", file=sys.stderr)
   717	        sys.exit(2)
   718	    # GH-300 (B2): retry verbs dispatch marathon-drive exactly like the run executor, so
   719	    # they hold the same supervisor lock — a retry fired beside a live drive is precisely
   720	    # the concurrency the lock exists to prevent (GH-42 / GH-354).
   721	    supervisor_lock = JogSupervisorLock(root)
   722	    supervisor_lock.acquire()
   723	    try:
   724	        return _jog_retry_gate_locked(root, gh_num, args)
   725	    finally:
   726	        supervisor_lock.release()
   727	
   728	
   729	def _jog_retry_gate_locked(root, gh_num, args):
   730	    gid = jog_resolve_ledger_gid(root, gh_num)
   731	    if not gid:
   732	        # Same refusal retry-build already had: a None gid here would otherwise surface
   733	        # as a TypeError traceback from jog_load_state instead of a clean exit.
   734	        print(f"jog: GH-{gh_num} has no jog queue row and no execution ledger", file=sys.stderr)
   735	        sys.exit(2)
   736	    record, receipt = _jog_latest_receipt(root, gid, outcomes=("approved",))
   737	    if record is None:
   738	        # A red gate escalates with outcome 'escalated'; the relay behind it is terminal and
   739	        # its receipt still names the head — retry-gate applies there too.
   740	        record, receipt = _jog_latest_receipt(root, gid, outcomes=("escalated",))
   741	    if record is None:
   742	        print(f"jog: GH-{gh_num} has no terminal Marathon execution to gate-retry", file=sys.stderr)
   743	        sys.exit(2)
   744	
   745	    prior_head = receipt.get("head_sha")
   746	    invocation_path = os.path.join(
   747	        _ledger_abs_path(root, gid, record.get("packet_dir")), "marathon-invocation.json")
   748	    try:
   749	        invocation = load_marathon_invocation(invocation_path)
   750	    except ContractError as exc:
   751	        print(f"jog: cannot gate-retry — {exc}", file=sys.stderr)
   752	        sys.exit(2)
   753	
   754	    # The head-moved guard runs BEFORE dispatch: marathon's own runs commit transcripts (the
   755	    # receipt head legitimately advances by those), so the meaningful invariant is that the
   756	    # head is UNCHANGED between the execution and this retry — checked against the live repo
   757	    # pre-dispatch, not against the post-run receipt (which would false-trip on the retry's
   758	    # own transcript commit and burn a gate run to report it).
   759	    pre_head = subprocess.run(["git", "rev-parse", "HEAD"], cwd=invocation["target_root"],
   760	                              capture_output=True, text=True)
   761	    if pre_head.returncode == 0 and pre_head.stdout.strip() != prior_head:
   762	        print(f"jog: refusing gate retry for GH-{gh_num} — head is {pre_head.stdout.strip()[:8]} "
   763	              f"but the execution ran on {str(prior_head or '')[:8]}; the head moved between "
   764	              f"runs (use jog retry-build)", file=sys.stderr)
   765	        sys.exit(2)
   766	
   767	    state = jog_load_state(root, gid)
   768	    entry = next((e for e in state.get("executions") or []
   769	                  if e.get("execution_id") == record["execution_id"]), None)
   770	    if entry is None:
   771	        print(f"jog: ledger lost execution {record['execution_id']} — refusing to gate-retry",
   772	              file=sys.stderr)
   773	        sys.exit(2)
   774	    gate_retries = entry.setdefault("gate_retries", [])
   775	    attempt_no = len(gate_retries) + 1
   776	    retry_dir = os.path.join(_jog_exec_dir(root, gid, record), f"gate-retry-{attempt_no}")
   777	    os.makedirs(retry_dir, exist_ok=True)
   778	    argv = _marathon_argv_from_invocation(invocation, args.builder, args.reviewer)
   779	    argv += ["--execution-id", f"{record['execution_id']}-gateretry{attempt_no}",
   780	             "--result-file", os.path.join(retry_dir, "marathon-result.json")]
   781	
   782	    env = dict(os.environ)
   783	    env.update(invocation["env"])
   784	    env["RELAY_DRIVER_LOCKED"] = "1"
   785	    print(f"jog: gate-only retry for GH-{gh_num} against head {prior_head} "
   786	          f"(no builder turn; satisfied-lane path)")
   787	    proc = subprocess.run(argv, cwd=invocation["target_root"], env=env)
   788	    result_path = os.path.join(retry_dir, "marathon-result.json")
   789	    try:
   790	        new_receipt = load_marathon_result(result_path)
   791	    except ContractError as exc:
   792	        gate_retries.append({"execution_id": record["execution_id"], "attempt": attempt_no,
   793	                             "status": "no-valid-result", "drive_exit": proc.returncode})
   794	        jog_save_state(root, gid, state)
   795	        print(f"jog: gate retry exited {proc.returncode} without a valid receipt: {exc}",
   796	              file=sys.stderr)
   797	        sys.exit(2)
   798	    gate_retries.append({"execution_id": record["execution_id"], "attempt": attempt_no,
   799	                         "status": new_receipt.get("outcome"),
   800	                         "result_path": result_path})
   801	    jog_save_state(root, gid, state)
   802	
   803	    action, reason = jog_project_marathon_outcome(
   804	        root, gh_num, new_receipt,
   805	        auto_merge=getattr(args, "auto_merge", False),
   806	        execution_id=f"{record['execution_id']}-gateretry{attempt_no}",
   807	        result_path=_ledger_rel_path(root, gid, result_path))
   808	    jog_set_status(root, gh_num, action, failure_reason=reason)
   809	    print(f"jog: gate retry result: {new_receipt.get('outcome')} → queue {action} — {reason}")
   810	    return 0 if new_receipt.get("outcome") == "approved" else 1
   811	
   812	
   813	def jog_retry_build(root, gh_num, args):
   814	    """`jog retry-build <GH>` — a fresh Marathon attempt on a fresh execution id.
   815	
   816	    Marathon's namespaced attempt record is the sole retry cap: the lane key is unchanged, so
   817	    attempts accumulate and the cap parks the lane exactly as an ordinary marathon caller
   818	    would experience. All prior Tick history and execution records are preserved."""
   819	    error = validate_marathon_executor(args)
   820	    if error:
   821	        print(f"jog: {error}", file=sys.stderr)
   822	        sys.exit(2)
   823	    # GH-300 (B2): same supervisor lock as the run executor — see jog_retry_gate.
   824	    supervisor_lock = JogSupervisorLock(root)
   825	    supervisor_lock.acquire()
   826	    try:
   827	        return _jog_retry_build_locked(root, gh_num, args)
   828	    finally:
   829	        supervisor_lock.release()
   830	
   831	
   832	def _jog_retry_build_locked(root, gh_num, args):
   833	    gid = jog_resolve_ledger_gid(root, gh_num) or jog_current_gid(root, gh_num)
   834	    if not gid:
   835	        print(f"jog: GH-{gh_num} is not in the jog queue", file=sys.stderr)
   836	        sys.exit(2)
   837	    conn = sqlite3.connect(os.path.join(root, "releases.db"))
   838	    conn.row_factory = sqlite3.Row
   839	    try:
   840	        row = conn.execute("SELECT status FROM jog_queue WHERE global_id = ?", (gid,)).fetchone()
   841	        if row and row["status"] == "running":
   842	            print(f"jog: GH-{gh_num} has a live lease — resume or wait; retry-build refused",
   843	                  file=sys.stderr)
   844	            sys.exit(2)
   845	    finally:
   846	        conn.close()
   847	
   848	    jog_acquire_lease(root, gh_num, os.getpid())
   849	    action, reason = run_marathon_phase(
   850	        root, gh_num, gid,
   851	        builder=getattr(args, "builder", "agy"), reviewer=args.reviewer,
   852	        auto_merge=getattr(args, "auto_merge", False), mode="retry-build")
   853	    jog_set_status(root, gh_num, action, failure_reason=reason)
   854	    print(f"jog: retry-build GH-{gh_num} → {action} — {reason}")
   855	    return 0 if action in ("completed", "parked") else 1
     1	#!/usr/bin/env python3
     2	"""harness_paths.py (GH-396 Phase 2) — single resolver for harness_home, repo_root, is_vendored, and harness_tool.
     3	
     4	Provides:
     5	- harness_home(path=None, anchor_file=None): directory containing relay-automation/ + utils/ (repo root, or <repo>/.xyz)
     6	- is_vendored(path=None): boolean check for vendored (.xyz) layout
     7	- repo_root(path=None, anchor_file=None): consumer repo root (dirname of .xyz if vendored, else harness_home)
     8	- resolve_tool(repo_root, rel_path, prefer_repo=True): resolves tool file with repo-first mock shadow preference
     9	
    10	Two resolution questions live here and they are deliberately separate:
    11	1. Install / layout resolution (harness_home, repo_root, is_vendored) determines whether
    12	   the execution is standing in a canonical checkout or a vendored leaf, preserving symlinks.
    13	2. Tool resolution (resolve_tool(repo_root, rel, prefer_repo=True)) selects which copy of a tool
    14	   file inside that install — repo-first so a canonical checkout and test mocks shadow the harness
    15	   copy (test/gh358-…:128-131), harness-home fallback. Their orderings differ by design and are never
    16	   merged into one ladder.
    17	
    18	Shadow risk is exposed, not hidden: resolve_tool(rel, prefer_repo=True) is the existing
    19	contract for the five harness tools wave_reconcile runs. A consumer repo carrying its own
    20	same-named utils/… file would win silently under repo-first. New consumers pass
    21	prefer_repo=False; the docstring names the risk and the flag.
    22	"""
    23	
    24	import os
    25	import re
    26	import subprocess
    27	import sys
    28	
    29	
    30	def harness_home(path=None, anchor_file=None):
    31	    """Dir containing relay-automation/ + utils/: repo root, or <repo>/.xyz when vendored.
    32	
    33	    Derived from THIS file's location (or anchor_file if provided), or XYZ_HARNESS environment variable.
    34	    Never uses os.path.realpath so symlinked .xyz directories preserve their .xyz identity.
    35	    """
    36	    if path is not None:
    37	        if os.path.isfile(path):
    38	            return os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(path)), "..", ".."))
    39	        return os.path.abspath(path)
    40	    if anchor_file is not None:
    41	        if os.path.isfile(anchor_file):
    42	            return os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(anchor_file)), "..", ".."))
    43	        return os.path.abspath(anchor_file)
    44	    if os.environ.get("XYZ_HARNESS") and os.path.isdir(os.environ["XYZ_HARNESS"]):
    45	        return os.path.abspath(os.environ["XYZ_HARNESS"])
    46	    # If the main running script is under .xyz/, use its location to preserve symlinked .xyz
    47	    main_mod = sys.modules.get("__main__")
    48	    main_file = getattr(main_mod, "__file__", None)
    49	    if main_file and os.path.isfile(main_file):
    50	        main_abs = os.path.abspath(main_file)
    51	        if "/.xyz/" in main_abs or main_abs.endswith("/.xyz"):
    52	            parts = main_abs.split(os.sep)
    53	            if ".xyz" in parts:
    54	                idx = parts.index(".xyz")
    55	                return os.sep.join(parts[:idx + 1])
    56	    return os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", ".."))
    57	
    58	
    59	def is_vendored(path=None):
    60	    """Check if the harness is installed in a vendored (.xyz) layout."""
    61	    if path is None:
    62	        if os.environ.get("XYZ_VENDORED") in ("1", "true", "True"):
    63	            return True
    64	        if os.environ.get("XYZ_VENDORED") in ("0", "false", "False"):
    65	            return False
    66	        if os.environ.get("XYZ_HARNESS"):
    67	            p = os.path.abspath(os.environ["XYZ_HARNESS"])
    68	            if os.path.basename(p.rstrip("/\\")) == ".xyz":
    69	                return True
    70	    p = harness_home() if path is None else (
    71	        os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(path)), "..", ".."))
    72	        if os.path.isfile(path) else os.path.abspath(path)
    73	    )
    74	    return os.path.basename(p.rstrip("/\\")) == ".xyz"
    75	
    76	
    77	def repo_root(path=None, anchor_file=None):
    78	    """Return the consumer repo root (dirname(harness_home) if vendored, else harness_home). Raises on failure."""
    79	    h = harness_home(path, anchor_file=anchor_file)
    80	    if is_vendored(h):
    81	        if path is None and anchor_file is None:
    82	            caller = os.environ.get("XYZ_CALLER_ROOT")
    83	            if caller and os.path.isdir(caller):
    84	                return os.path.abspath(caller)
    85	        return os.path.dirname(h.rstrip("/\\"))
    86	    return h
    87	
    88	
    89	def resolve_tool(repo_root, rel_path, prefer_repo=True):
    90	    """Resolve a HARNESS tool (releases_app, the dashboard/plan/timeline scripts) for a run
    91	    whose cwd is `repo_root`.
    92	
    93	    The target repo wins when it carries the tool itself (`prefer_repo=True`, the existing
    94	    contract: every wave-reconcile test suite installs its mocks at `$REPO/utils/...` and
    95	    relies on them shadowing the real thing, and a canonical checkout is its own harness home,
    96	    so repo-first is a no-op there).
    97	
    98	    Only when the target repo does NOT carry the tool do we fall back to the harness home —
    99	    the vendored (Tier 2) case, where these files exist solely under `<repo>/.xyz/`.
   100	
   101	    When `prefer_repo=False`, the harness-home copy wins if present, avoiding shadow risk.
   102	
   103	    Returns a path relative to `repo_root` when the repo owns the tool, else an absolute path
   104	    into the harness home. Both are correct as argv[1] for a subprocess run with cwd=repo_root.
   105	    """
   106	    if not rel_path:
   107	        raise ValueError("rel_path is required")
   108	    if prefer_repo:
   109	        if os.path.exists(os.path.join(repo_root, rel_path)):
   110	            return rel_path
   111	        vendored = os.path.join(harness_home(), rel_path)
   112	        if os.path.exists(vendored):
   113	            return vendored
   114	        # Neither location has it: return the repo-relative path so the failure names the tool the
   115	        # caller asked for, exactly as it did before this helper existed.
   116	        return rel_path
   117	    else:
   118	        h = os.path.join(harness_home(), rel_path)
   119	        if os.path.exists(h):
   120	            return h
   121	        if os.path.exists(os.path.join(repo_root, rel_path)):
   122	            return rel_path
   123	        return rel_path
   124	
   125	
   126	# Backward compatibility alias for wave_reconcile
   127	harness_tool = resolve_tool
   128	
   129	
   130	def github_slug_from_origin(root):
   131	    """Best-effort '<org>/<repo>' from a github.com origin remote; None when unresolved.
   132	
   133	    GH-429: extracted here (the module every harness tool already imports) so wave_reconcile can
   134	    recognise `Closes https://github.com/<org>/<repo>/issues/N` for THIS repo only; the Tier 2
   135	    twin `releases_app._github_slug_from_origin` keeps its own copy — releases_app is not vendored
   136	    on a Tier 1 install, so it cannot be the import.
   137	    """
   138	    try:
   139	        out = subprocess.check_output(["git", "-C", root, "remote", "get-url", "origin"],
   140	                                      stderr=subprocess.DEVNULL).decode().strip()
   141	    except Exception:
   142	        return None
   143	    m = re.search(r"github\.com[/:]([\w.\-]+/[\w.\-]+?)(?:\.git)?$", out)
   144	    return m.group(1) if m else None
   145	

web search: 
web search: https://github.com/HiQS-Labs/XYZ-forge/issues/1006
exec
/bin/zsh -lc "nl -ba utils/py/marathon_drive.py | sed -n '235,277p;1103,1143p;1420,1509p;2678,2730p;2830,2861p;2980,3055p;3240,3285p;3300,3357p;3415,3497p'; rg -n 'model|codex|agy|claude|vote|quorum|reconcil|failure|ThreadPool|returncode' utils/py/consult.py" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-13569-zsltpsy2
 succeeded in 0ms:
   235	    receipt = {
   236	        "schema": RESULT_SCHEMA,
   237	        "execution_id": _RESULT.get("execution_id"),
   238	        "generated_at": _utc_now_z(),
   239	        "outcome": outcome,
   240	        "reason": reason,
   241	        "exit_code": code,
   242	        "approval_preserved": outcome == "post-approve-failed",
   243	        "issue": issue,
   244	        "phase": _RESULT.get("phase"),
   245	        "lane": lane,
   246	        "token": _RESULT.get("token"),
   247	        "attempt": {"count": attempt_count, "max": _RESULT.get("attempt_max")},
   248	        "builder": _RESULT.get("builder"),
   249	        "reviewer": _RESULT.get("reviewer"),
   250	        "target_repo": {"path": _RESULT.get("target_repo_path") or _RESULT.get("root"),
   251	                        "origin_url": origin_url},
   252	        "base_branch": _RESULT.get("base_branch"),
   253	        "head_branch": head_branch,
   254	        "head_sha": head_sha,   # observational: HEAD at receipt-write time
   255	        # GH-505/GH-509: the candidate that was VALIDATED against the reviewer's attestation, the
   256	        # revision the reviewer read, and the record — None on any outcome that was not attested.
   257	        "reviewed_candidate": _RESULT.get("reviewed_candidate"),
   258	        "reviewed_head": _RESULT.get("reviewed_head"),
   259	        "added_sha256": _RESULT.get("added_sha256"),
   260	        "attest_path": _RESULT.get("attest_path"),
   261	        "branch_redirect": bool(_RESULT.get("branch_redirect")),
   262	        "gate": {
   263	            "cmd": _RESULT.get("gate_cmd"),
   264	            "result": _RESULT.get("gate_result") or "not-run",
   265	            "exit": _RESULT.get("gate_exit"),
   266	            "receipt_path": gate_receipt_path,
   267	        },
   268	        "acceptance": _RESULT.get("acceptance"),
   269	        "pr": {"number": pr_number, "url": pr_url, "state": pr_state},
   270	        "pr_note": _RESULT.get("pr_note"),
   271	        "relay_status": relay_status,
   272	        "timestamps": {"started_at": _RESULT.get("started_at"),
   273	                       "finished_at": _utc_now_z()},
   274	    }
   275	
   276	    target = _RESULT["path"]
   277	    directory = os.path.dirname(target) or "."
  1103	        die("--phase-brief FILE required")
  1104	    if not os.path.isfile(args.phase_brief_file):
  1105	        die(f"phase brief not found: {args.phase_brief_file}")
  1106	    if not args.reviewer:
  1107	        eprint("Usage: relay-automation/marathon-drive.sh --phase-brief FILE --reviewer AGENT [options]")
  1108	        die("--reviewer AGENT required")
  1109	    if not args.builder:
  1110	        die("--builder cannot be empty")
  1111	    if not args.phase_id:
  1112	        die("--phase-id cannot be empty")
  1113	
  1114	    if args.target_root:
  1115	        try:
  1116	            subprocess.run(["git", "-C", args.target_root, "rev-parse", "--show-toplevel"], 
  1117	                           stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, check=True)
  1118	        except subprocess.CalledProcessError:
  1119	            die(f"invalid --target-root (not a git repo): {args.target_root}")
  1120	
  1121	    xyz_harness = harness_home()
  1122	    default_root = repo_root()
  1123	    
  1124	    root = get_env("MARATHON_ROOT", default_root)
  1125	    tick_bin = get_env("TICK_BIN", os.path.join(xyz_harness, "bin", "tick"))
  1126	    relay_drive_bin = get_env("MARATHON_RELAY_DRIVE", os.path.join(xyz_harness, "relay-automation", "relay-drive.sh"))
  1127	    agent_cmd = get_env("MARATHON_AGENT_CMD", os.path.join(xyz_harness, "relay-automation", "marathon-agent.sh"))
  1128	    # GH-342: `$HERE/harvest-findings.sh` in the Bash twin — HERE is relay-automation/, which for the
  1129	    # Python lane is a sibling of utils/py's grandparent. Resolved once; both call sites re-check
  1130	    # os.access(X_OK) at spawn time, so a harness missing the script simply harvests nothing.
  1131	    harvest_findings_bin = os.path.join(xyz_harness, "relay-automation", "harvest-findings.sh")
  1132	
  1133	    # GH-280: arm the terminal-result receipt BEFORE anything below can die, so every refusal,
  1134	    # escalation, and success path from here on produces exactly one receipt when requested.
  1135	    # --help / unknown-arg / missing-required-arg exits above are pre-arm on purpose: they never
  1136	    # started a run, and a supervisor treats "exit non-zero, no receipt" as "driver never armed".
  1137	    if args.result_file:
  1138	        _result_arm(args, root, args.target_root)
  1139	
  1140	    def _lane_key(raw):
  1141	        return re.sub(r'[^A-Za-z0-9._-]', '_', raw)
  1142	
  1143	    def lane_attempt_gate(root_dir, raw, force):
  1420	    relay_task = resolve_force_relay_task(
  1421	        relay_task, tick_bin, force=bool(args.force), explicit=bool(args.relay_task))
  1422	    _RESULT["token"] = relay_task
  1423	    # GH-207: a marathon lane namespaces its phase paths + attempt state so two lanes sharing a bare
  1424	    # phase id (p1) don't collide. Defaults to the phase id when no lane namespace is set.
  1425	    lane_state_key = get_env("MARATHON_LANE_NS") or args.phase_id
  1426	    _RESULT["lane"] = lane_state_key
  1427	
  1428	    # ── GH-284 Phase 2, ported (GH-322) ────────────────────────────────────────────────────────
  1429	    # BOTH halves of Phase 2 — the driver heartbeat AND the --log-github run log — existed only in
  1430	    # relay-automation/marathon-drive.sh. That twin `exec`s this file at its own line 18, long before
  1431	    # it installs the EXIT trap that runs them, so on the default lane (XYZ_PYTHON unset, GH-264)
  1432	    # neither one ever executed. #322 scoped this as "the run-log half only, the heartbeat is already
  1433	    # in the Python twin (12 references)"; those 12 matches are xyz_marathon_heartbeat_* — the GH-75
  1434	    # XYZ.heartbeat.json session record, a different file and a different feature. Before this change
  1435	    # `grep -c driver_heartbeat utils/py/marathon_drive.py` was 0, so the observability Phase 2 was
  1436	    # built to provide was absent from the lane that actually runs. Both halves are ported here.
  1437	    run_gate_result = ["not-run"]
  1438	    drive_started = [False]
  1439	    # GH-388: set once this phase has reached a DECIDED outcome and written a durable record for it
  1440	    # (escalate() writes ESCALATION.md + archives the transcript; complete_phase_success archives it).
  1441	    # Read only by _write_interrupted_phase_record, whose whole job is the case where neither ran —
  1442	    # a phase killed before the driver decided anything. A second flag rather than inferring from
  1443	    # run_gate_result, because "the gate did not run" and "this phase never reached an outcome" are
  1444	    # different facts and #407 exists because they were once conflated.
  1445	    phase_outcome_recorded = [False]
  1446	
  1447	    def _cmd_out(cmd, cwd=None):
  1448	        # Best-effort stdout capture: a missing binary, a non-zero exit, or a crash all yield "".
  1449	        # Every probe in the run log is advisory, and none of them may raise into the exit path.
  1450	        try:
  1451	            res = subprocess.run(cmd, cwd=cwd, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL)
  1452	        except Exception:
  1453	            return ""
  1454	        if res.returncode != 0:
  1455	            return ""
  1456	        return res.stdout.decode("utf-8", "replace").strip()
  1457	
  1458	    def _utc_now():
  1459	        return _dt.datetime.now(_dt.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
  1460	
  1461	    hb_interval = get_env("MARATHON_DRIVER_HEARTBEAT_INTERVAL", "30")
  1462	    try:
  1463	        hb_interval = int(hb_interval)
  1464	    except (TypeError, ValueError):
  1465	        hb_interval = 30
  1466	    if hb_interval <= 0:
  1467	        hb_interval = 30
  1468	    # MARATHON_DRIVER_HEARTBEAT_STALE_AFTER is deliberately not read here (GH-333). Staleness is a
  1469	    # question only a READER of the heartbeat file asks, and this lane is the writer; the reader
  1470	    # (rtl_driver_heartbeat_status, relay-turn-lib.sh) still honors the variable. The one consumer
  1471	    # this file had was the dropped constant field.
  1472	
  1473	    def driver_heartbeat_path():
  1474	        # RTL_DRIVER_HEARTBEAT_FILE is the same override relay-turn-lib.sh honors, so an observer (or
  1475	        # a test) can point both twins at one file and get one answer.
  1476	        return get_env("RTL_DRIVER_HEARTBEAT_FILE") or os.path.join(root, ".tick", "driver-heartbeat.json")
  1477	
  1478	    hb_state = {"started": "", "plan": "", "stop": None, "live": False}
  1479	
  1480	    def driver_heartbeat_write():
  1481	        # Same record and the same atomic mkstemp+os.replace as rtl_driver_heartbeat_write, so a
  1482	        # heartbeat written by either twin is byte-compatible with readers of the other.
  1483	        path = driver_heartbeat_path()
  1484	        record = {
  1485	            "pid": os.getpid(),
  1486	            "started_utc": hb_state["started"],
  1487	            "updated_utc": _utc_now(),
  1488	            "plan": hb_state["plan"],
  1489	            "phase_id": args.phase_id,
  1490	            "relay_task": relay_task,
  1491	        }
  1492	        directory = os.path.dirname(path) or "."
  1493	        try:
  1494	            os.makedirs(directory, exist_ok=True)
  1495	            fd, tmp = tempfile.mkstemp(dir=directory, prefix=".driver-heartbeat.", suffix=".tmp")
  1496	            try:
  1497	                with os.fdopen(fd, "w") as f:
  1498	                    json.dump(record, f, sort_keys=True)
  1499	                    f.write("\n")
  1500	                os.replace(tmp, path)
  1501	            except Exception:
  1502	                try:
  1503	                    os.unlink(tmp)
  1504	                except OSError:
  1505	                    pass
  1506	                raise
  1507	        except Exception:
  1508	            return False
  1509	        return True
  2678	            log("acceptance re-check passed — every fix_probe reports the fix landed")
  2679	        log(f"relay approved — running pre-advance gate: {pre_advance_cmd}")
  2680	        gate_exit = run_pre_advance_gate()
  2681	        if gate_exit != 0:
  2682	            # GH-390 layer 5: a gate the guard killed is a different event from a gate that ran and
  2683	            # found a defect, and triaging the two together is what made the crashes hard to read.
  2684	            # Both halt the phase; only the reason string differs.
  2685	            if gate_exit == GATE_GUARD_KILL_EXIT:
  2686	                log(f"pre-advance gate KILLED by the resource guard (exit {gate_exit}) — escalating")
  2687	                escalate("gate-killed", 0)
  2688	                xyz_marathon_emit("red", f"halted at phase {args.phase_id} — pre-advance gate killed by the resource guard")
  2689	            else:
  2690	                log(f"pre-advance gate FAILED (exit {gate_exit}) — escalating")
  2691	                escalate("pre-advance-failed", 0)
  2692	                xyz_marathon_emit("red", f"halted at phase {args.phase_id} — pre-advance gate failed")
  2693	            sys.exit(5)
  2694	        if args.requires_test and not requires_test_delta(args.requires_test):
  2695	            log(f"requires-test FAILED — no new/updated test detected at: {args.requires_test}")
  2696	            escalate("requires-test-missing", 0)
  2697	            xyz_marathon_emit("red", f"halted at phase {args.phase_id} — required test not added/updated: {args.requires_test}")
  2698	            sys.exit(5)
  2699	        if success_mode == "already-satisfied":
  2700	            success_text = f"phase {args.phase_id} complete — lane_already_satisfied, reviewer approved, gate passed"
  2701	            _RESULT["reason"] = "already-satisfied"
  2702	        else:
  2703	            success_text = f"phase {args.phase_id} complete — STATUS: Approved, gate passed"
  2704	        save_transcript()
  2705	        # GH-505/GH-509: no success is published — no approved event, no green, no receipt — unless
  2706	        # relay-drive's attestation covers the candidate. The token that completed is the one the
  2707	        # relay file was rendered for (a --retry derivative on an already-satisfied lane).
  2708	        attested_task = completed_relay_task() if success_mode == "already-satisfied" else relay_task
  2709	        def bind_candidate(where):
  2710	            cand = _cmd_out(["git", "-C", args.target_root or root, "rev-parse", "HEAD"])
  2711	            rec = attested_terminal(attested_task, candidate=cand, where=where)
  2712	            if rec is None:
  2713	                log(f"phase {args.phase_id}: relay exited 0 but its approval is not attested for candidate {cand[:12] if cand else '?'} — refusing to publish success")
  2714	                escalate("candidate-drifted-from-reviewed-head", 0)
  2715	                xyz_marathon_emit("red", f"halted at phase {args.phase_id} — approval not bound to the merge candidate")
  2716	                sys.exit(4)
  2717	            return cand, rec
  2718	        candidate, record = bind_candidate(f"phase {args.phase_id} success")
  2719	        subprocess.run([tick_bin, "log", "marathon.phase.approved", relay_task, "--agent", "marathon"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
  2720	        lane_attempt_reset(get_env("TICK_REPO_ROOT", root), lane_state_key)
  2721	        refresh_remote_tracking_ref()
  2722	        if args.post_approve_cmd:
  2723	            log(f"phase approved — running post-approve command: {args.post_approve_cmd}")
  2724	            post_approve_exit = run_post_approve_cmd()
  2725	            if post_approve_exit != 0:
  2726	                log(f"post-approve command FAILED (exit {post_approve_exit}) — phase remains approved; escalating closeout")
  2727	                escalate("post-approve-failed", 0)
  2728	                sys.exit(9)
  2729	            # the hook may move HEAD — the receipt names ONE validated candidate, taken after it
  2730	            candidate, record = bind_candidate(f"phase {args.phase_id} post-approve")
  2830	            return False
  2831	        s = file_status()
  2832	        if not terminal_status(s):
  2833	            return False
  2834	        task = completed_relay_task()
  2835	        tstatus, _actor = token_state(task)
  2836	        if tstatus != "done":
  2837	            # GH-385 asked for this line by name: "Log the disagreement ... that single line would
  2838	            # have made this diagnosable immediately." A terminal relay whose token is not done is a
  2839	            # contradiction, and the rebuild that follows is otherwise indistinguishable in the log
  2840	            # from an ordinary first fire.
  2841	            log(f"phase {args.phase_id}: relay is terminal (STATUS: {s}) but token '{task}' reads "
  2842	                f"'{tstatus or 'unknown'}', not done — rebuilding; if this phase really did complete, "
  2843	                f"its record is on a token this run cannot see (see GH-385)")
  2844	            return False
  2845	        # GH-505/GH-509: the word `Approved` is builder-writable; only relay-drive's attestation says
  2846	        # a reviewer approved THIS file at a revision this HEAD still honours. Without it, a spent token
  2847	        # cannot be reopened (GH-274), so the run refuses loudly instead of re-dispatching.
  2848	        if attested_terminal(task, where=f"phase {args.phase_id} startup") is None:
  2849	            log(f"phase {args.phase_id}: terminal relay is NOT attested — refusing to treat it as satisfied; "
  2850	                f"its token '{task}' is done and cannot be reopened, so this run halts (see GH-505)")
  2851	            escalate("unattested-terminal", 0)
  2852	            xyz_marathon_emit("red", f"halted at phase {args.phase_id} — terminal relay without a reviewer attestation")
  2853	            sys.exit(4)
  2854	        return True
  2855	
  2856	    if not args.dry_run and satisfied_lane_terminal():
  2857	        log(f"phase {args.phase_id} already reached a terminal relay (STATUS: {file_status()}, token done) — skipping render/reseed, re-running only the pre-advance gate")
  2858	        complete_phase_success("already-satisfied")
  2859	
  2860	    # GH-491: --retry (which arrives here as an explicit --relay-task) deliberately bypasses the
  2861	    # short-circuit above — completed_relay_task() returns the operator-named token without consulting
  2980	5. HAND OFF EXPLICITLY (GH-268): after releasing the token, end your turn by naming who acts next —
  2981	   "handing off to {args.reviewer} — {args.reviewer}, take your turn." A turn that ends without that line
  2982	   leaves a human guessing whether the relay is waiting on them or has stalled. Do this EVERY round,
  2983	   not just the first. ALSO, you MUST update the `NEXT:` line at the top of this file to exactly: `NEXT: {args.reviewer} (Reviewer)`
  2984	
  2985	---
  2986	
  2987	▶ TAKE YOUR TURN ({args.reviewer} — REVIEWER role)
  2988	
  2989	You are the REVIEWER for this phase. {reviewer_read_line}
  2990	APPEND-ONLY FILE (GH-529 attestation): add your block at the END and never delete, reorder, or rewrite any existing content — the terminal attestation refuses the approval if any byte above your block changed, even a tidy-up.
  2991	1. Append a review block: `### Round N · Reviewer · {args.reviewer}` followed by your assessment.
  2992	2. If changes needed: add `**Verdict:** Changes requested`, update the `NEXT:` line to exactly `NEXT: {args.builder} (Builder)`, then: {tick_cli} release {relay_task} --agent {args.reviewer} --to {args.builder}
  2993	3. If satisfied: add `**Verdict:** Approved`, set `STATUS: Approved`, then: {tick_cli} done {relay_task} --agent {args.reviewer}
  2994	4. Use this exact tick binary (run it from any directory) for all token operations: {tick_cli}
  2995	   {reviewer_scope_line}
  2996	4b. TO VERIFY A FINDING, WRITE PROBE FILES OUTSIDE THE REPO — under $TMPDIR, never inside the
  2997	   working tree. Creating even one scratch file in the repo is an off-lane write: containment
  2998	   reverts it and FAILS YOUR WHOLE TURN, discarding the review you just did (GH-441). Observed
  2999	   2026-08-08: a reviewer found a real latent crash, wrote two probe files in-tree to demonstrate
  3000	   it, and lost the turn for doing so — the finding survived only because RELAY.md happens to be
  3001	   on your allowlist. `cp` what you need to "$TMPDIR/probe.$$/" and work there instead. Verifying
  3002	   is wanted; verifying in-tree is what costs you the turn.
  3003	4c. A finding that asks for a behaviour change is a generalization unless you can paste the concrete
  3004	   input — a row, a value, a `file:line` — that fails under the current code (GH-681). Every
  3005	   `[Blocker]` or `[Should]` requesting a behaviour change MUST carry `Observed input:`,
  3006	   `Affected scope:` and `Falsifier:` lines; a `[Blocker]` must cite an observed failure. The Builder
  3007	   may disposition a request lacking these as `Declined — unproven generalization`.
  3008	5. HAND OFF EXPLICITLY (GH-268): end your turn by naming who acts next — "handing off to {args.builder} —
  3009	   {args.builder}, take your turn" when requesting changes, or "relay closed, no further turn needed" when
  3010	   approving. The beta report singled this out: the Reviewer turn did not tell the user to go back to the
  3011	   Producer, so the relay looked stalled when it was simply waiting. Do this EVERY round.
  3012	"""
  3013	
  3014	    if args.dry_run:
  3015	        log(f"dry-run: relay file would be rendered at {relay_file}")
  3016	        # GH-401: a dry run must not write, but it must still SHOW its work — otherwise the flag
  3017	        # becomes "do nothing and tell you nothing", and the render (the expensive, interesting part)
  3018	        # is unobservable. Emitting it here is not a test affordance: test/debug-mantra.sh has always
  3019	        # relied on --dry-run to produce a rendered relay it can inspect WITHOUT driving a phase or
  3020	        # touching .tick/attempts/<lane>, which is the state that test hand-seeds. That need is real;
  3021	        # the file write it used to ride on is what was wrong. Fenced so a caller can extract the
  3022	        # render exactly, and so a grep for template text can't be confused with a driver log line.
  3023	        print("--- BEGIN RENDERED RELAY ---")
  3024	        print(relay_content, end="")
  3025	        print("--- END RENDERED RELAY ---")
  3026	        print(f"tick seed: log task.created {relay_task} + claim --agent marathon + release --to {args.builder}")
  3027	        sys.exit(0)
  3028	
  3029	    # GH-514: prove the repo can TRACK this run's write-set before anything is dispatched.
  3030	    #
  3031	    # `marathon.sh --help` has always stated this failure — "without --target-root, marathon-drive's
  3032	    # `git add` of RELAY.md / ESCALATION.md / the transcript fails and the phase HALTs" — and nothing
  3033	    # checked it. So a repo that deliberately ignores harness output (a public one, or a vendored
  3034	    # install where ensure_gitignore added `.xyz/` and never un-ignored the output dirs, #314) was
  3035	    # discovered as a halt AFTER a builder turn had been spent. Worse on the escalation path: the
  3036	    # record explaining why the run stopped is itself one of the files that cannot be committed, so
  3037	    # the run loses its own account of the failure.
  3038	    #
  3039	    # Checked against the repo each file is actually committed to (#131): `commit_root` for the
  3040	    # phase write-set — `root` in every in-repo shape, the TARGET repo under --target-root with a
  3041	    # target --phases-dir, where `root` would probe a repo that never receives these files and an
  3042	    # ignored target marathon-system/ would still halt the phase mid-run. The transcript still
  3043	    # lands under `root` (save_transcript resolves rtl_transcript_root against it), so the probe
  3044	    # path is checked there. One call when the two repos are the same, byte-identical to the
  3045	    # pre-#131 check; two only when they genuinely differ.
  3046	    # GH-314: the write set is THREE paths, not two. `save_transcript()` also does a
  3047	    # `git add --` with check=True on a file under the transcript root, so an ignored
  3048	    # `relay-system/` HALTs the chain after the turn is already spent — the same defect this
  3049	    # preflight exists to stop, on the one path it was not checking. That third call site is
  3050	    # exactly the one #314's second reporter found the hard way, an afternoon at a time.
  3051	    #
  3052	    # The root is resolved the same way `save_transcript()` resolves it (rtl_transcript_root via
  3053	    # relay-turn-lib.sh) rather than assuming the literal `relay-system/`, because a vendored or
  3054	    # relocated install can move it and a hardcoded guess would check a path the run never writes.
  3055	    # If it cannot be resolved, the path is simply not added: this guard must not invent a new way
  3240	    # a "nothing to commit" git error; treat it as unchanged and continue.
  3241	    if subprocess.run(["git", "-C", commit_root, "diff", "--cached", "--quiet", "--", relay_file]).returncode == 0:
  3242	        log(f"relay file unchanged: {relay_file}")
  3243	    else:
  3244	        subprocess.run(["git", "-C", commit_root, "commit", "-q", "-m", f"marathon: render phase {args.phase_id} relay ({relay_task})"], check=True)
  3245	        log(f"relay file committed: {relay_file}")
  3246	
  3247	    os.environ["TICK_REPO_ROOT"] = root
  3248	
  3249	    def reconcile_relay_task():
  3250	        try:
  3251	            info = subprocess.check_output([tick_bin, "info", relay_task], stderr=subprocess.DEVNULL).decode('utf-8').splitlines()
  3252	        except:
  3253	            return
  3254	        
  3255	        status, claimer, handoff = "", "", ""
  3256	        for line in info:
  3257	            if line.startswith("status:"): status = line.split(":", 1)[1].strip()
  3258	            elif line.startswith("claimer:"): claimer = line.split(":", 1)[1].strip()
  3259	            elif line.startswith("handoff-to:"): handoff = line.split(":", 1)[1].strip()
  3260	            
  3261	        if status == "claimed":
  3262	            die(f"relay task {relay_task} already has a live claim by {claimer or 'unknown'}; refusing to reap a live claim")
  3263	        elif status == "open":
  3264	            if not handoff: return
  3265	            if handoff in [args.builder, args.reviewer]:
  3266	                _run_tick_loud([tick_bin, "claim", relay_task, "--agent", handoff, "--paths", rel_relay])
  3267	                _run_tick_loud([tick_bin, "release", relay_task, "--agent", handoff])
  3268	                log(f"reconciled leaked open handoff: {relay_task} (cleared stale reservation for {handoff})")
  3269	            else:
  3270	                die(f"relay task {relay_task} is open but reserved for unexpected agent '{handoff}'")
  3271	
  3272	    # The outer marathon-drive invocation owns this lane's attempt count. A parent relay-drive
  3273	    # process may have set this flag to suppress its nested accounting; do not let that inherited
  3274	    # value skip this invocation's own gate. The child relay-drive environment sets it explicitly
  3275	    # below to avoid double-counting, matching the Bash implementation.
  3276	    os.environ.pop("LANE_ATTEMPT_COUNTED", None)
  3277	    lane_attempt_gate(get_env("TICK_REPO_ROOT", root), lane_state_key, args.force)
  3278	    _run_tick_loud = run_tick_loud   # GH-408: module-level now, so it is directly testable
  3279	
  3280	    reconcile_relay_task()
  3281	
  3282	    _run_tick_loud([tick_bin, "log", "task.created", relay_task, "--agent", "marathon"])
  3283	    _run_tick_loud([tick_bin, "claim", relay_task, "--agent", "marathon", "--paths", rel_relay])
  3284	    _run_tick_loud([tick_bin, "release", relay_task, "--agent", "marathon", "--to", args.builder])
  3285	    log(f"tick token seeded: {relay_task} → {args.builder}")
  3300	        if os.path.isfile(reason_file):
  3301	            try:
  3302	                os.remove(reason_file)
  3303	            except OSError:
  3304	                pass
  3305	        incident_file = os.path.join(xyz_harness, ".relay-scratch", "last-turn-incident.json")
  3306	        if os.path.isfile(incident_file):
  3307	            try:
  3308	                os.remove(incident_file)
  3309	            except OSError:
  3310	                pass
  3311	        cmd2 = [relay_drive_bin, "--relay-file", relay_file, "--relay-task", relay_task,
  3312	                "--agent-cmd", agent_cmd,
  3313	                # GH-505/GH-509: the driver learns the roles from ITS invocation, never from the
  3314	                # relay file or the token, and attests only the reviewer's approval.
  3315	                "--reviewer", args.reviewer, "--builder", args.builder]
  3316	        if review_once:
  3317	            cmd2.append("--review-once")   # GH-207: one approval pass, no round-cap
  3318	        else:
  3319	            cmd2.extend(["--round-cap", str(args.round_cap)])
  3320	        if args.target_root:
  3321	            cmd2.extend(["--target-root", args.target_root])
  3322	        env2 = os.environ.copy()
  3323	        env2["RELAY_FILE"] = relay_file
  3324	        env2["LANE_ATTEMPT_COUNTED"] = "1"
  3325	        env2["XYZ_HARNESS_CONTEXT"] = "marathon-phase"
  3326	        env2["RELAY_COST_SUMMARY"] = "0"
  3327	        env2["TICK_REPO_ROOT"] = get_env("TICK_REPO_ROOT", root)
  3328	        # GH-256: under --target-root the turn shim must GUARD the repo the worktree is cut FROM.
  3329	        #
  3330	        # relay-drive exports RELAY_TARGET_ROOT and relay-turn-lib.sh:251 reads
  3331	        # RTL_ROOT="${RELAY_TARGET_ROOT:-$1}", so the WORKTREE is correct. But each shim resolves
  3332	        # its own containment root from <AGENT>_TURN_ROOT (utils/py/agy-turn.py:321,
  3333	        # utils/py/codex-turn.py:26), which nothing set — so the shim guarded the harness while the
  3334	        # worktree was the target, the per-artifact seed check resolved every path against the
  3335	        # wrong root and found nothing, and the agent got a worktree without its own files.
  3336	        # relay-turn-lib.sh:283 already stated the gap: "marathon-drive/relay-drive don't export
  3337	        # CODEX_TURN_ROOT/AGY_TURN_ROOT — they never do".
  3338	        #
  3339	        # Measured: four builder turns wrote nothing, appended no builder block, and the phase
  3340	        # escalated cap-stalled after 29 minutes with zero lines of code. No error anywhere.
  3341	        #
  3342	        # Set on env2 (the relay-drive child) rather than os.environ, so the guard root is scoped
  3343	        # to the drive that actually has a foreign target and cannot leak into anything else in
  3344	        # this process. The name set matches route_agent's accepted prefixes above — claude, codex,
  3345	        # agy, aider, pi, smallcode, commandcode, deepseek. Keeping the two lists together is
  3346	        # deliberate: a new builder route added above without a guard root here silently
  3347	        # reintroduces this bug. GH-346 Phase 2 added DEEPSEEK, which was the one accepted route
  3348	        # with no guard root — deepseek-turn.py:93 reads DEEPSEEK_TURN_ROOT, so a --target-root
  3349	        # deepseek turn was resolving containment against the harness clone, not the target.
  3350	        if args.target_root:
  3351	            for _shim in ("CLAUDE", "CODEX", "AGY", "AIDER", "PI", "SMALLCODE", "COMMANDCODE", "DEEPSEEK"):
  3352	                env2[f"{_shim}_TURN_ROOT"] = args.target_root
  3353	        return subprocess.run(cmd2, env=env2, cwd=root).returncode
  3354	
  3355	    # GH-75: write liveness before the drive; clear it on ANY terminal path via atexit (registered only
  3356	    # here, so early exits before a live phase never register a spurious clear).
  3357	    xyz_marathon_heartbeat_write()
  3415	    def recover_timeout_exit():
  3416	        # GH-205: a relay timeout (exit 7) whose declared artifact already landed AND left a live
  3417	        # reviewer handoff is resumed with one more relay-drive pass instead of a false hang.
  3418	        #
  3419	        # GH-387: this used to PROBE THE PRE-ADVANCE GATE here, before any token inspection, and that
  3420	        # probe made the gate the first thing ever to execute work no human or reviewer had seen. A
  3421	        # turn killed at its wall-clock cap is still committed by rtl_enforce — deliberately, that is
  3422	        # GH-432's shipped fix against orphaned tokens and lost work — so the artifact on disk may be
  3423	        # a partial write from an agent that was killed mid-edit.
  3424	        #
  3425	        # The probe is gone, and NOTHING ELSE CHANGES, because the probe decided nothing. Every branch
  3426	        # below is resolved by artifacts_exist(), file_status() and token_state():
  3427	        #
  3428	        #   no artifact                    -> real hang, 7   (checked BEFORE the gate ever was)
  3429	        #   terminal status, no live actor -> continue,  0   (token)
  3430	        #   no live actor                  -> halt,      7   (token)
  3431	        #   actor is still the builder     -> real hang, 7   (token)
  3432	        #   actor moved to the reviewer    -> resume         (token)
  3433	        #
  3434	        # The tick token records the handoff DIRECTLY. The gate was only ever a proxy for the question
  3435	        # "did the builder finish and hand off?", which the token already answers — so GH-205's
  3436	        # hands-free recovery of a false hang is preserved intact, not traded away.
  3437	        #
  3438	        # What IS given up is the `timeout-gate-failed` early exit: a timed-out turn whose artifact was
  3439	        # already red used to halt here, and now resumes to the reviewer, who rejects it. That costs
  3440	        # one reviewer turn on work that was going to fail anyway. It was a fail-fast optimisation, not
  3441	        # a guarantee — and paying it buys "the gate is never the first executor of un-inspected code".
  3442	        #
  3443	        # The reviewer is now the first inspector, which is the correct order: a reviewer READS the
  3444	        # artifact, the gate EXECUTES it.
  3445	        #
  3446	        # STILL OPEN, deliberately not fixed here (see the capture doc): refusing this gate does not
  3447	        # stop a LATER invocation from executing a leftover partial, because path_has_nonempty_phase_delta
  3448	        # accepts an untracked file as evidence of work. Closing that needs a durable
  3449	        # `unreviewed-partial` marker — new persistent state, independent of this change.
  3450	        #
  3451	        # BASH/PYTHON DIVERGENCE, deliberate and pinned. The frozen twin still probes the gate here and
  3452	        # still sets TIMEOUT_ESCALATION_REASON="timeout-gate-failed"
  3453	        # (relay-automation/marathon-drive.sh:1208). It is frozen under GH-308 and is NOT to be taught
  3454	        # this fix as a drive-by change — that needs a `Frozen-twin-exception:` trailer and belongs to
  3455	        # retiring the twins. The Bash path is only reachable via XYZ_PYTHON=0 or a host with no
  3456	        # python3 >= 3.8; marathon-drive.sh:9 execs this file otherwise, which is the default. Same
  3457	        # shape as the GH-414 divergence note in route_agent above, and the same reason: the frozen
  3458	        # halves are the dead halves, and #379/#380 show they actively generate false bug reports.
  3459	        if not artifacts_exist():
  3460	            timeout_reason[0] = "timeout-no-artifact"
  3461	            timeout_emit[0] = f"halted at phase {args.phase_id} — timed-out builder produced no declared artifact"
  3462	            log("relay timed out (exit 7) before any declared artifact landed — treating it as a real hang")
  3463	            return 7
  3464	        log("relay timed out (exit 7) after declared artifact(s) appeared — reading the relay + token state "
  3465	            "(GH-387: the pre-advance gate is NOT run here; the reviewer inspects the artifact first)")
  3466	        s = file_status()
  3467	        tstatus, actor = token_state()
  3468	        if terminal_status(s) and not actor:
  3469	            if attested_terminal(where="timeout probe") is None:
  3470	                return 7
  3471	            log(f"timeout probe: relay already reached terminal agreement (STATUS: {s}, token done, attested) — continuing")
  3472	            return 0
  3473	        if not actor:
  3474	            timeout_reason[0] = "timeout-no-live-actor"
  3475	            timeout_emit[0] = f"halted at phase {args.phase_id} — timed-out builder left no live reviewer handoff"
  3476	            log(f"timeout probe: artifact landed, but {relay_task} has no live actor (STATUS: {s}) — cannot continue")
  3477	            return 7
  3478	        if actor == args.builder:
  3479	            timeout_reason[0] = "timeout-builder-still-owned-turn"
  3480	            timeout_emit[0] = f"halted at phase {args.phase_id} — timed-out builder never handed the relay to review"
  3481	            log(f"timeout probe: builder still owns {relay_task} (STATUS: {s}) — treating this as a real hang")
  3482	            return 7
  3483	        log(f"timeout probe: artifact landed and {relay_task} moved to {actor} — resuming relay-drive from the post-timeout state")
  3484	        r = _run_relay_drive()
  3485	        if r == 7:
  3486	            timeout_reason[0] = "timeout-during-review-recovery"
  3487	            timeout_emit[0] = f"halted at phase {args.phase_id} — relay timed out again during review recovery"
  3488	        return r
  3489	
  3490	    if relay_exit == 7:
  3491	        _r = recover_timeout_exit()
  3492	        relay_exit = 0 if _r == 0 else _r
  3493	
  3494	    if relay_exit == 0:
  3495	        complete_phase_success()
  3496	    elif relay_exit == 3:
  3497	        if recover_already_satisfied_lane() == 0:
41:from rtl import (RelayTurnLib, resolve_tick_bin, resolve_tick_repo_root, agy_auth_output_verdict,
42:                 agy_auth_timeout_verdict, AGY_AUTH_TIMEOUT_DEFAULT_S)
44:from claude_cli import resolve_binary as resolve_claude, preflight as claude_preflight, read_result as claude_result, effort_flags
50:# fanning out is that one model's failure is not the run's failure. CONSULT_IDLE_S=0 disables it.
63:    r"|Unable to list models|No API key was provided|NotFoundError|Traceback \(most recent call last\)"
179:    """False if the Aider transcript shows an auth/config failure or has no visible answer."""
187:            f.write("\nconsult: Aider returned no visible content (empty answer — likely reasoning-only or a silent failure).\n")
191:            f.write("\nconsult: Aider transcript shows an auth/config failure — counted as FAILED (was exit 0).\n")
195:def advisor_answer_ok(out_path, model):
206:    # codex's raw provenance lines (model:/provider:/sandbox:) are metadata, not an answer
207:    body = "\n".join(l for l in body.splitlines() if not re.match(r"^(model|provider|sandbox):", l))
218:                f.write(f"\nconsult: {model} returned no visible content (exit 0, empty answer) — counted as FAILED.\n")
220:            warn(f"{model} returned no visible content (exit 0, empty JSON response) — counted as FAILED")
224:def consult_codex_attestation(out_path):
225:    # GH-308 port (consult.sh run_codex): prepend an ATTESTATION provenance header (which
226:    # model/provider/sandbox actually answered), parsed from the codex output. This lived only in the
227:    # Bash twin, so every codex transcript on the default lane silently lost the provenance stamp.
230:    model = provider = sandbox = "unknown"
234:                if model == "unknown" and line.startswith("model:"):
235:                    model = line[len("model:"):].strip() or "unknown"
242:    header = f"> **ATTESTATION**\n> Model: {model}\n> Provider: {provider}\n> Sandbox: {sandbox}\n\n"
251:def consult_agy_isolation_breach(out_path, root):
252:    # GH-308 port (GH-178 B1, consult.sh run_agy): True if the agy transcript cited the real repo root
254:    # (tick-command narration, markdown file:// citations). Missing on the Python lane, so a real agy
255:    # grounding-escape was counted as a clean cross-model answer instead of failing the advisor.
289:    worktree, so a directory mtime cannot attribute progress to a model. Its own pid is the CPU
362:def surface_partial(out_path, model, marker):
376:    print(f"consult: {model} -> {partial_path}\n{text}", flush=True)
379:def agy_auth_preflight(agy_bin, log_file):
384:            # GH-221 (2026-08-24): probe `models`, not `whoami` — agy >=1.1.19 removed `whoami`
385:            # entirely, while `models` runs headless and requires live auth on every agy
387:            subprocess.run([agy_bin, "models"], stdout=f, stderr=subprocess.STDOUT, timeout=secs, check=True)
388:        # GH-375: `agy whoami` exits 0 while failing to run at all without a TTY, so exit status
389:        # cannot decide this — see agy_auth_output_verdict in rtl.py. Same hole as agy-turn.py, so
391:        severity, detail = agy_auth_output_verdict(tmp)
393:            # Not a failure. `agy whoami` needs a TTY and consult runs headless, so this branch is
394:            # the NORMAL path here, not an edge case — failing it closed would disable the agy seat
395:            # on every consult. Recorded in the log so a later credential failure is diagnosable.
399:                f.write(f"\nconsult: WARNING — {detail}. Proceeding; if agy fails on credentials, "
400:                        f"run `agy login` in a normal terminal.\n")
407:                f.write(f"\nconsult: agy auth pre-flight exited 0 but {detail}. Run `agy login` in a normal terminal, then retry.\n")
413:        # GH-375 follow-up: the branch that actually lost the agy seat. A timeout whose captured output
414:        # already carries the TTY diagnostic is the same failure as the fast TTY exit, only slower, and
415:        # blocking on it disables the agy advisor on every consult run under load — observed 2026-08-09
416:        # on a machine where `agy -p` answered correctly in the same minute. Silence or any other
418:        t_severity, t_detail = agy_auth_timeout_verdict(tmp)
423:                f.write(f"\nconsult: WARNING — {t_detail}. Proceeding; if agy fails on credentials, "
424:                        f"run `agy login` in a normal terminal.\n")
430:            f.write(f"\nconsult: agy auth pre-flight timed out after {secs}s; {t_detail}. Run `agy login` in a normal terminal, then retry.\n")
432:        # #135: a non-zero probe exit was a credentials failure by definition — but agy 1.1.18
434:        # killed the consult's agy seat while auth was never in question and prescribed the
436:        # same verdict as the exit-0 path above (the #130 fix in agy-turn.py, same shape). A
439:        severity, detail = agy_auth_output_verdict(tmp)
442:                f.write(f"\nconsult: NOTE — agy auth is unverifiable headless (expected, probe exited "
443:                        f"{e.returncode} on a usage error); proceeding. {detail}\n")
449:            f.write(f"\nconsult: agy auth pre-flight failed (exit {e.returncode}); {detail or 'no recognizable diagnostic'}. Run `agy login` in a normal terminal, then retry.\n")
452:            f.write(f"\nconsult: agy auth pre-flight could not run: {type(e).__name__}: {e}\n")
479:    codex_bin = os.environ.get("CODEX_BIN", "codex")
480:    agy_bin = os.environ.get("AGY_BIN", os.environ.get("GEMINI_BIN", "agy"))
481:    gemini_bin = os.environ.get("GEMINI_BIN", agy_bin)
490:    models_str = "codex,agy"
507:        elif arg == "--models" and i + 1 < len(args):
508:            models_str = args[i+1]
517:            print("Usage: consult.sh --prompt \"question\" [--out DIR] [--models codex,agy] [--label SLUG] [--tool-mode standard|programmatic]")
529:            die("Containment failure (fail-closed): OS sandbox backend (sandbox-exec or bwrap) unavailable for --tool-mode programmatic")
550:        if res.returncode != 0:
560:            "You are an INDEPENDENT advisor in a one-shot cross-model consult. Another model is answering the SAME question "
561:            "separately and a coordinator will reconcile both answers, so give your own honest, specific read — do not hedge "
568:        preamble = "You are an INDEPENDENT advisor in a one-shot cross-model consult. Another model is answering the SAME question separately and a coordinator will reconcile both answers, so give your own honest, specific read — do not hedge toward a consensus you cannot see. Read any repo files the question references (cite file:line). Respond with: (1) a short direct ANSWER; (2) graded FINDINGS — [Blocker]/[Should]/[Nit]/[Pass] — where applicable; (3) a one-line RECOMMENDATION. You are ADVISORY ONLY: output your analysis as text; do not rely on writing files (you are running in a throwaway copy)."
585:    if res.returncode != 0:
616:        models = [m.strip() for m in models_str.split(",") if m.strip()]
620:        for m in models:
621:            if m == "claude":
622:                f_out = os.path.join(run_dir, f"{label}.claude.md")
624:                claude_bin = resolve_claude(cenv)
626:                claude_settings = ["--restricted", "--strict-mcp-config"]
628:                    if not claude_bin:
629:                        raise ValueError("claude CLI not found; set CLAUDE_BIN")
631:                    claude_preflight(claude_bin, cenv, wt, cli_flags=claude_settings)
637:                claude_prompt = full_prompt
639:                    claude_prompt += "\nClaude advisory seat: only Read/Grep/Glob are available; inspect source without executing probe scripts."
640:                cmd = [claude_bin, "-p", claude_prompt, "--output-format", "json",
641:                       "--model", cenv.get("CLAUDE_MODEL", "claude-sonnet-4-6"),
644:                       "--max-budget-usd", cenv.get("CLAUDE_MAX_BUDGET", "0.50")] + claude_settings + native_effort
647:            elif m == "codex":
648:                f_out = os.path.join(run_dir, f"{label}.codex.md")
653:                cmd = [codex_bin, "exec"] + cflags + [full_prompt]
655:                procs.append((proc, "codex", f_out, time.time(), cmd))
656:            elif m == "agy":
657:                f_out = os.path.join(run_dir, f"{label}.agy.md")
658:                if not agy_auth_preflight(agy_bin, f_out):
659:                    procs.append((None, "agy", f_out, time.time(), None))
661:                cmd = [agy_bin, "--dangerously-skip-permissions", "--print-timeout", f"{timeout_s}s", "-p", full_prompt]
663:                procs.append((proc, "agy", f_out, time.time(), cmd))
681:                    aider_model = os.environ.get("AIDER_MODEL", "openai/agents-a1")
689:                    aider_model = os.environ.get("AIDER_MODEL", "openrouter/anthropic/claude-sonnet-5")
690:                cmd = [aider_bin, "--model", aider_model] + auth_args + ["--message", full_prompt, "--yes-always", "--no-auto-commits", "--no-gitignore", "--no-check-update", "--no-analytics", "--no-show-model-warnings", "--no-stream", "--map-tokens", "0"]
702:                muse_model = os.environ.get("MUSE_MODEL", "muse-spark-1.3")
708:                       "--model", muse_model,
714:                warn(f"unknown model '{m}' — skipping")
717:            die(f"no valid models to consult (got: {models_str})")
722:        survivor_model = ""
724:        results = []  # (model, out_path, ok) — used by the GH-223 citation-stamp pass below
736:                # where the 2026-08-10 auth-preflight failure killed a consult outright, and it had
738:                # sampler — same reason agy-turn.py's blocking call was replaced.
743:                # the shared worktree would let a fast codex answer mask a hung agy.
748:                # GH-308 port (consult.sh run_codex): stamp the codex transcript with its provenance
750:                if m == "codex":
751:                    consult_codex_attestation(out)
753:                # GH-308 port (GH-178 B1, consult.sh run_agy): a successful agy run whose transcript cited
757:                if m == "claude" and proc.returncode == 0:
759:                        answer = claude_result(out)
767:                if m == "agy" and proc.returncode == 0 and os.path.isfile(out) and os.path.getsize(out) > 0:
768:                    if consult_agy_isolation_breach(out, root):
770:                            f.write(f"\nconsult: [FAIL] agy transcript cited the real repo root ({root}) instead of the isolation worktree. This is a known agy isolation breach (grounding escaped $WT). Failing the turn to prevent a silent breach.\n")
777:                elif proc.returncode == 0 and (aider_answer_ok(out) if m == "aider" else advisor_answer_ok(out, m)):
780:                    survivor_model = m
783:                elif proc.returncode == 0:
784:                    # exit 0 but the aider transcript proved an auth/config failure or empty answer
792:                        f.write(f"\nconsult: advisor failed with exit {proc.returncode}\n")
793:                        if m == "claude":
812:        citeless_models = []
813:        provenance_warnings = []  # (model, echoed_count) — GH-235 A4 v0 prompt-trace warnings
819:                citeless_models.append(m)
861:        # but ended with exactly one survivor is not a reconciled cross-model result — no second read
862:        # happened, so treating its verdict as reconciled is exactly the failure mode this consult
865:        # in this run's stdout. Deliberately does NOT fire when only one model was ever requested: that
866:        # is an intentional single-model query, not a degrade. Mirrors relay-automation/consult.sh
872:                f"**SINGLE-MODEL — NOT RECONCILED** (only {survivor_model} answered; {failed} of "
873:                f"{len(procs)} requested advisor(s) failed — this is one model's read, not a "
874:                f"cross-model consult. Do not treat any claim below as cross-verified.)"
919:        if removed is not None and removed.returncode == 0:
928:    if citeless_models:
929:        warn(f"NO FIRSTHAND VERIFICATION CITED for: {' '.join(citeless_models)} (stamped into transcript(s) + sidecar(s) in {run_dir})")
930:    for pw_model, pw_count in provenance_warnings:
931:        warn(f"prompt-trace classifier: {pw_model} echoed {pw_count} cited claim(s) from {label}.PROMPT.txt (see {os.path.join(run_dir, f'{label}.{pw_model}.PROVENANCE.txt')})")

codex
The existing retry verbs preserve important boundaries: Jog’s `resume` only reconciles receipts, while gate retry and rebuild are explicit actions. The gap is a verified handoff to a repaired harness SHA while retaining the original run’s identity and budgets; a published PR alone does not establish that handoff.

exec
/bin/zsh -lc "nl -ba utils/py/marathon_drive.py | sed -n '2998,3065p;3230,3355p'; rg -n 'GH-1001|GH-1002|1004|progress' utils/py/rtl.py relay-automation/relay-turn-lib.sh utils/py/marathon_drive.py; rg --files test | rg 'marathon|gh280|gh274|gh491|gh284|gh388|gh100[12]|gh279|gh396|consult'; nl -ba GUIDING-PRINCIPLES.md | sed -n '60,95p'; nl -ba AGENTS.md | sed -n '326,352p'" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-13569-zsltpsy2
 succeeded in 0ms:
  2998	   reverts it and FAILS YOUR WHOLE TURN, discarding the review you just did (GH-441). Observed
  2999	   2026-08-08: a reviewer found a real latent crash, wrote two probe files in-tree to demonstrate
  3000	   it, and lost the turn for doing so — the finding survived only because RELAY.md happens to be
  3001	   on your allowlist. `cp` what you need to "$TMPDIR/probe.$$/" and work there instead. Verifying
  3002	   is wanted; verifying in-tree is what costs you the turn.
  3003	4c. A finding that asks for a behaviour change is a generalization unless you can paste the concrete
  3004	   input — a row, a value, a `file:line` — that fails under the current code (GH-681). Every
  3005	   `[Blocker]` or `[Should]` requesting a behaviour change MUST carry `Observed input:`,
  3006	   `Affected scope:` and `Falsifier:` lines; a `[Blocker]` must cite an observed failure. The Builder
  3007	   may disposition a request lacking these as `Declined — unproven generalization`.
  3008	5. HAND OFF EXPLICITLY (GH-268): end your turn by naming who acts next — "handing off to {args.builder} —
  3009	   {args.builder}, take your turn" when requesting changes, or "relay closed, no further turn needed" when
  3010	   approving. The beta report singled this out: the Reviewer turn did not tell the user to go back to the
  3011	   Producer, so the relay looked stalled when it was simply waiting. Do this EVERY round.
  3012	"""
  3013	
  3014	    if args.dry_run:
  3015	        log(f"dry-run: relay file would be rendered at {relay_file}")
  3016	        # GH-401: a dry run must not write, but it must still SHOW its work — otherwise the flag
  3017	        # becomes "do nothing and tell you nothing", and the render (the expensive, interesting part)
  3018	        # is unobservable. Emitting it here is not a test affordance: test/debug-mantra.sh has always
  3019	        # relied on --dry-run to produce a rendered relay it can inspect WITHOUT driving a phase or
  3020	        # touching .tick/attempts/<lane>, which is the state that test hand-seeds. That need is real;
  3021	        # the file write it used to ride on is what was wrong. Fenced so a caller can extract the
  3022	        # render exactly, and so a grep for template text can't be confused with a driver log line.
  3023	        print("--- BEGIN RENDERED RELAY ---")
  3024	        print(relay_content, end="")
  3025	        print("--- END RENDERED RELAY ---")
  3026	        print(f"tick seed: log task.created {relay_task} + claim --agent marathon + release --to {args.builder}")
  3027	        sys.exit(0)
  3028	
  3029	    # GH-514: prove the repo can TRACK this run's write-set before anything is dispatched.
  3030	    #
  3031	    # `marathon.sh --help` has always stated this failure — "without --target-root, marathon-drive's
  3032	    # `git add` of RELAY.md / ESCALATION.md / the transcript fails and the phase HALTs" — and nothing
  3033	    # checked it. So a repo that deliberately ignores harness output (a public one, or a vendored
  3034	    # install where ensure_gitignore added `.xyz/` and never un-ignored the output dirs, #314) was
  3035	    # discovered as a halt AFTER a builder turn had been spent. Worse on the escalation path: the
  3036	    # record explaining why the run stopped is itself one of the files that cannot be committed, so
  3037	    # the run loses its own account of the failure.
  3038	    #
  3039	    # Checked against the repo each file is actually committed to (#131): `commit_root` for the
  3040	    # phase write-set — `root` in every in-repo shape, the TARGET repo under --target-root with a
  3041	    # target --phases-dir, where `root` would probe a repo that never receives these files and an
  3042	    # ignored target marathon-system/ would still halt the phase mid-run. The transcript still
  3043	    # lands under `root` (save_transcript resolves rtl_transcript_root against it), so the probe
  3044	    # path is checked there. One call when the two repos are the same, byte-identical to the
  3045	    # pre-#131 check; two only when they genuinely differ.
  3046	    # GH-314: the write set is THREE paths, not two. `save_transcript()` also does a
  3047	    # `git add --` with check=True on a file under the transcript root, so an ignored
  3048	    # `relay-system/` HALTs the chain after the turn is already spent — the same defect this
  3049	    # preflight exists to stop, on the one path it was not checking. That third call site is
  3050	    # exactly the one #314's second reporter found the hard way, an afternoon at a time.
  3051	    #
  3052	    # The root is resolved the same way `save_transcript()` resolves it (rtl_transcript_root via
  3053	    # relay-turn-lib.sh) rather than assuming the literal `relay-system/`, because a vendored or
  3054	    # relocated install can move it and a hardcoded guess would check a path the run never writes.
  3055	    # If it cannot be resolved, the path is simply not added: this guard must not invent a new way
  3056	    # for a healthy run to fail, which is the same fail-open contract the docstring above sets.
  3057	    _phase_write_set = [relay_file, os.path.join(phase_dir, "ESCALATION.md")]
  3058	    _transcript_write_set = []
  3059	    try:
  3060	        _ts_base = subprocess.check_output(
  3061	            "source \"%s\" && rtl_transcript_root \"%s\"" % (
  3062	                os.path.join(xyz_harness, "relay-automation", "relay-turn-lib.sh"), root),
  3063	            shell=True, executable="/bin/bash", stderr=subprocess.DEVNULL).decode("utf-8").strip()
  3064	        if _ts_base:
  3065	            # The probe path must MIMIC THE REAL SHAPE, not merely live under the same root.
  3230	
  3231	    os.makedirs(phase_dir, exist_ok=True)
  3232	    with open(relay_file, 'w') as f:
  3233	        f.write(relay_content)
  3234	
  3235	    # #131: commit_root, not root — with --target-root and a target --phases-dir the relay file
  3236	    # lives in the TARGET repo and `git -C root add` failed "outside repository" (exit 128). In
  3237	    # every in-repo shape commit_root IS root, so these commands are byte-identical to before.
  3238	    subprocess.run(["git", "-C", commit_root, "add", "--", relay_file], check=True)
  3239	    # GH-207: only commit when the render actually changed — a byte-identical re-render must not HALT on
  3240	    # a "nothing to commit" git error; treat it as unchanged and continue.
  3241	    if subprocess.run(["git", "-C", commit_root, "diff", "--cached", "--quiet", "--", relay_file]).returncode == 0:
  3242	        log(f"relay file unchanged: {relay_file}")
  3243	    else:
  3244	        subprocess.run(["git", "-C", commit_root, "commit", "-q", "-m", f"marathon: render phase {args.phase_id} relay ({relay_task})"], check=True)
  3245	        log(f"relay file committed: {relay_file}")
  3246	
  3247	    os.environ["TICK_REPO_ROOT"] = root
  3248	
  3249	    def reconcile_relay_task():
  3250	        try:
  3251	            info = subprocess.check_output([tick_bin, "info", relay_task], stderr=subprocess.DEVNULL).decode('utf-8').splitlines()
  3252	        except:
  3253	            return
  3254	        
  3255	        status, claimer, handoff = "", "", ""
  3256	        for line in info:
  3257	            if line.startswith("status:"): status = line.split(":", 1)[1].strip()
  3258	            elif line.startswith("claimer:"): claimer = line.split(":", 1)[1].strip()
  3259	            elif line.startswith("handoff-to:"): handoff = line.split(":", 1)[1].strip()
  3260	            
  3261	        if status == "claimed":
  3262	            die(f"relay task {relay_task} already has a live claim by {claimer or 'unknown'}; refusing to reap a live claim")
  3263	        elif status == "open":
  3264	            if not handoff: return
  3265	            if handoff in [args.builder, args.reviewer]:
  3266	                _run_tick_loud([tick_bin, "claim", relay_task, "--agent", handoff, "--paths", rel_relay])
  3267	                _run_tick_loud([tick_bin, "release", relay_task, "--agent", handoff])
  3268	                log(f"reconciled leaked open handoff: {relay_task} (cleared stale reservation for {handoff})")
  3269	            else:
  3270	                die(f"relay task {relay_task} is open but reserved for unexpected agent '{handoff}'")
  3271	
  3272	    # The outer marathon-drive invocation owns this lane's attempt count. A parent relay-drive
  3273	    # process may have set this flag to suppress its nested accounting; do not let that inherited
  3274	    # value skip this invocation's own gate. The child relay-drive environment sets it explicitly
  3275	    # below to avoid double-counting, matching the Bash implementation.
  3276	    os.environ.pop("LANE_ATTEMPT_COUNTED", None)
  3277	    lane_attempt_gate(get_env("TICK_REPO_ROOT", root), lane_state_key, args.force)
  3278	    _run_tick_loud = run_tick_loud   # GH-408: module-level now, so it is directly testable
  3279	
  3280	    reconcile_relay_task()
  3281	
  3282	    _run_tick_loud([tick_bin, "log", "task.created", relay_task, "--agent", "marathon"])
  3283	    _run_tick_loud([tick_bin, "claim", relay_task, "--agent", "marathon", "--paths", rel_relay])
  3284	    _run_tick_loud([tick_bin, "release", relay_task, "--agent", "marathon", "--to", args.builder])
  3285	    log(f"tick token seeded: {relay_task} → {args.builder}")
  3286	
  3287	    _run_tick_loud([tick_bin, "log", "marathon.phase.start", relay_task, "--agent", "marathon"])
  3288	    _phase_memory_sample(f"{args.phase_id}-start", root=root, tick_bin=tick_bin, relay_task=relay_task)
  3289	    log(f"phase start: running relay-drive --round-cap {args.round_cap}")
  3290	    # Past this point a phase is really being driven — arm the run log and start the driver
  3291	    # heartbeat. Same placement as MARATHON_DRIVE_STARTED=1 + marathon_driver_heartbeat_start in the
  3292	    # Bash twin, so --help / usage / lock contention / a parked lane / --dry-run never post a run log
  3293	    # or leave a liveness record behind.
  3294	    drive_started[0] = True
  3295	    driver_heartbeat_start()
  3296	    refresh_remote_tracking_ref()
  3297	
  3298	    def _run_relay_drive(review_once=False):
  3299	        reason_file = os.path.join(xyz_harness, ".relay-scratch", "escalation-reason")
  3300	        if os.path.isfile(reason_file):
  3301	            try:
  3302	                os.remove(reason_file)
  3303	            except OSError:
  3304	                pass
  3305	        incident_file = os.path.join(xyz_harness, ".relay-scratch", "last-turn-incident.json")
  3306	        if os.path.isfile(incident_file):
  3307	            try:
  3308	                os.remove(incident_file)
  3309	            except OSError:
  3310	                pass
  3311	        cmd2 = [relay_drive_bin, "--relay-file", relay_file, "--relay-task", relay_task,
  3312	                "--agent-cmd", agent_cmd,
  3313	                # GH-505/GH-509: the driver learns the roles from ITS invocation, never from the
  3314	                # relay file or the token, and attests only the reviewer's approval.
  3315	                "--reviewer", args.reviewer, "--builder", args.builder]
  3316	        if review_once:
  3317	            cmd2.append("--review-once")   # GH-207: one approval pass, no round-cap
  3318	        else:
  3319	            cmd2.extend(["--round-cap", str(args.round_cap)])
  3320	        if args.target_root:
  3321	            cmd2.extend(["--target-root", args.target_root])
  3322	        env2 = os.environ.copy()
  3323	        env2["RELAY_FILE"] = relay_file
  3324	        env2["LANE_ATTEMPT_COUNTED"] = "1"
  3325	        env2["XYZ_HARNESS_CONTEXT"] = "marathon-phase"
  3326	        env2["RELAY_COST_SUMMARY"] = "0"
  3327	        env2["TICK_REPO_ROOT"] = get_env("TICK_REPO_ROOT", root)
  3328	        # GH-256: under --target-root the turn shim must GUARD the repo the worktree is cut FROM.
  3329	        #
  3330	        # relay-drive exports RELAY_TARGET_ROOT and relay-turn-lib.sh:251 reads
  3331	        # RTL_ROOT="${RELAY_TARGET_ROOT:-$1}", so the WORKTREE is correct. But each shim resolves
  3332	        # its own containment root from <AGENT>_TURN_ROOT (utils/py/agy-turn.py:321,
  3333	        # utils/py/codex-turn.py:26), which nothing set — so the shim guarded the harness while the
  3334	        # worktree was the target, the per-artifact seed check resolved every path against the
  3335	        # wrong root and found nothing, and the agent got a worktree without its own files.
  3336	        # relay-turn-lib.sh:283 already stated the gap: "marathon-drive/relay-drive don't export
  3337	        # CODEX_TURN_ROOT/AGY_TURN_ROOT — they never do".
  3338	        #
  3339	        # Measured: four builder turns wrote nothing, appended no builder block, and the phase
  3340	        # escalated cap-stalled after 29 minutes with zero lines of code. No error anywhere.
  3341	        #
  3342	        # Set on env2 (the relay-drive child) rather than os.environ, so the guard root is scoped
  3343	        # to the drive that actually has a foreign target and cannot leak into anything else in
  3344	        # this process. The name set matches route_agent's accepted prefixes above — claude, codex,
  3345	        # agy, aider, pi, smallcode, commandcode, deepseek. Keeping the two lists together is
  3346	        # deliberate: a new builder route added above without a guard root here silently
  3347	        # reintroduces this bug. GH-346 Phase 2 added DEEPSEEK, which was the one accepted route
  3348	        # with no guard root — deepseek-turn.py:93 reads DEEPSEEK_TURN_ROOT, so a --target-root
  3349	        # deepseek turn was resolving containment against the harness clone, not the target.
  3350	        if args.target_root:
  3351	            for _shim in ("CLAUDE", "CODEX", "AGY", "AIDER", "PI", "SMALLCODE", "COMMANDCODE", "DEEPSEEK"):
  3352	                env2[f"{_shim}_TURN_ROOT"] = args.target_root
  3353	        return subprocess.run(cmd2, env=env2, cwd=root).returncode
  3354	
  3355	    # GH-75: write liveness before the drive; clear it on ANY terminal path via atexit (registered only
utils/py/marathon_drive.py:41:    3: "no-progress escalation",
utils/py/marathon_drive.py:2519:        # builder turn made progress.
utils/py/marathon_drive.py:2522:        # deliverable is REMOVING a path could never register progress — the artifact is gone, which
utils/py/marathon_drive.py:2763:    # (recover_already_satisfied_lane, triggered mid-relay on a no-progress reroute) to this
utils/py/marathon_drive.py:3380:        # ONE routed reviewer pass instead of a false no-progress escalation. Returns 0 to route to
utils/py/marathon_drive.py:3381:        # complete_phase_success(already-satisfied); 3 to fall through to the ordinary no-progress halt.
utils/py/marathon_drive.py:3386:            log("already-satisfied probe: pre-advance gate FAILED — treating it as real no-progress")
utils/py/marathon_drive.py:3499:        log("relay escalated: no-progress (relay-drive exit 3)")
utils/py/marathon_drive.py:3500:        escalate("no-progress", 3)
utils/py/marathon_drive.py:3501:        xyz_marathon_emit("red", f"halted at phase {args.phase_id} — relay no-progress")
relay-automation/relay-turn-lib.sh:1462:  # the turn started (e.g. an operator's own in-progress `git add`), it silently rides along into the
test/hq-marathon-live.sh
test/hq-marathon-scan.sh
test/gh491-roadmap-section-validation.sh
test/gh382-marathon-memory-telemetry.sh
test/gh308-consult-guards.sh
test/gh280-jog-marathon-adapter.sh
test/consult.sh
test/marathon-yaml.sh
test/gh284-p3-release-milestone.sh
test/marathon-closeout.sh
test/gh589-consult-no-tick.sh
test/gh396-find-harness-roots.sh
test/gh284-runlog-heartbeat.sh
test/gh388-run-log-durability.sh
test/gh784-marathon-qa-gate.sh
test/gh491-gate-only-refire.sh
test/gh284-p4-release-lanes.sh
test/marathon-plan.sh
test/gh648-l3-consult-cap.sh
test/gh391-emit-marathon-yaml.sh
test/marathon.sh
test/marathon-root-audit.sh
test/gh362-marathon-plan-link-bullets.sh
test/gh273-marathon-root-audit-python-shape.sh
test/marathon-monitor.sh
test/marathon-drive.sh
test/synthetic/synthetic-marathon-env-leak.sh
test/synthetic/gh101-consult-programmatic.sh
test/synthetic/gh131-marathon-target-root.sh
test/synthetic/synthetic-marathon-worktree-guard.sh
test/gh131-marathon-target-root.sh
    60	
    61	1. **Coordination is local-transport only.** `.tick/events/` is the shared bus; claims resolve from there, not from a remote. No per-event push/fetch; no remote dependency at runtime. A coordination primitive that reaches out is a coordination primitive that can fail or leak.
    62	
    63	2. **One canonical event log for tick coordination.** `.tick/events/` records coordination events; `.tick/STATE.md` is a derived view. Coordination verbs read and fold the events and append changes through the event API. Other subsystems retain their own documented sources of truth, including the RELEASES roadmap ledger. Do not create competing copies of canonical state.
    64	
    65	3. **Containment is non-negotiable.** A headless turn must not: self-commit mid-turn, orphan a peer's concurrent commit, or write outside its allowlist. The allowlist, worktree isolation, and commit-bypass guard exist because a driven agent will do all three if unconstrained — not hypothetically, but as documented live incidents (GH-13, GH-14, GH-17). New relay paths must clear the containment bar before they ship.
    66	
    67	4. **Skill-first; never improvise the harness.** The `relay-xyz` skill owns the locator, sandbox rules, exit codes, and the safety boundary. A session that improvises those from `ls relay-automation/` silently skips the skill's safety layer. In sessions that install and invoke the `PreToolUse` hook, `relay-automation/hooks/relay-xyz-guard.sh` checks supported driver invocations for the skill’s setup evidence; this is not a guarantee that every runtime invokes that hook. Add capabilities to the skill; do not work around it.
    68	
    69	5. **Adversarially proven before commercially viable.** The harness exists to run against real codebases. Features in the adversarial-hardening track (epoch fencing, chaos suite, cross-repo E2E) must be verified to survive deliberate abuse — stale writers, zombie claims, macOS case-sensitivity, concurrent peer commits — not just the happy path. A feature that clears the happy path and skips chaos is half-done.
    70	
    71	6. **Build durable, not band-aid.** Durable means it removes the root cause and the next planned change builds on it — not a patch torn out when the obvious next feature lands. A band-aid is wasted work unless a demo strictly needs one, and a demo band-aid is tagged for removal so it isn't silently inherited.
    72	
    73	7. **Least code that clears the bar.** The `tick` coordination kernel uses Node's standard library. The repository also ships `package.json` and `package-lock.json` for Acorn-based source analysis. Prefer reusing or extending what exists; the smallest change that stays correct, contained, and durable wins. Net-new code is a cost to justify. Deleting code counts as progress.
    74	
    75	8. **Honest; the operator decides.** Surface what failed and why — never mask a stall as success or an escalation as a stall. A headless turn self-repairs within a bounded exit-code menu (`exit 3` stall, `exit 4` escalated-by-design, `exit 6` containment revert), then stops; it never loops forever or silently swallows an error. Destructive actions require explicit authorization.
    76	
    77	9. **Docs support resumable work (PDDA).** ROUTER points to the governing contracts; the RELEASES DB owns this repository's roadmap ledger (queried via `python3 utils/py/releases_app.py roadmap list`). Linked PROJECT documents hold plans, decisions and handoff detail; CHANGELOG records dated outcomes. Resume execution using those documents together with the relevant runtime state and evidence. If current documentation contradicts the implementation, correct it or explicitly record the unresolved discrepancy.
    78	
    79	10. **Done means verified.** "Done" is `validate.sh` green, the relevant PDDA checks passing, and any relay review returning `Approved` — not work that looks finished. An unverified success claim is itself a low-quality signal.
    80	
    81	11. **Issue-first; every non-trivial change has a signal stream.** Any change beyond a 2–3 line fix opens a GitHub issue first, then gets a `GH-<number>` in-repo pointer doc, then lands. The issue is the machine-queryable signal stream; the `PROJECT/**` doc is the execution surface of record. Genuinely trivial edits (≤2–3 line fixes, typos, path repoints, doc-only one-liners) are exempt.
    82	
    83	12. **Independent Verification (Separated Grading)** — The agent that produces a turn must not be the sole grader of its own quality. Verification must be performed by an independent deterministic check or a separate reviewing agent before the lock releases. Applies to: the relay's structural block validator (`bin/validate-relay-block` — Phase 1 of GH-21), consult-verify diversity (Phase 3), and any other post-generation quality gate.
    84	
    85	13. **A green gate without a witnessed red control is not evidence.** Every new or materially changed decision gate needs a recorded demonstration that it fails for the right reason: a pre-fix replay, deliberate mutation, or controlled bad input. Witness it on an existing suite, or record it as a manual check under `TESTS-RESULTS/`. Never add a new test suite to do it (GH-831: no new tests). Do not mistake a check that validates the artifact it just generated (#351) or a parity check that compares a lane to itself (#348) for evidence; both shapes are structurally unable to falsify their claim.
    86	
    87	## Applying this
    88	
    89	Adding a feature or weighing a tradeoff, ask: *does this keep agents coordinated without collision, contained within their scope, and verifiable to an outside observer? And is "done" provable by running `validate.sh`?* If any answer is no, reconsider.
    90	
    91	---
    92	
    93	## Conventions
    94	
    95	### Strict-mode policy (bash `set -e`)
   326	  **Orchestrator vs. Review Protocol Separation (GH-784):** The Orchestrator (the dispatch/tool driver) cannot self-satisfy the review contract or attest review solely by observing passing test suites. It must mechanically invoke an independent peer/Codex QA turn (`relay-xyz` / `/start-task` Step 8 parity) with recorded receipts under `relay-system/<YYYY-MM-DD>/<label>.codex.md` before approving or signing off on PR creation or promotion. Self-review or test-only observation does not satisfy the Wave QA receipt gate.
   327	- **HQ (multi-repo command center)** — for cross-repo tasking (resolve a project → land intake on its
   328	  own PDDA rails → prepare dispatch), drive `utils/hq/hq.sh` via the `/hq` skill rather than hand-editing
   329	  another repo's docs. Full command surface (`status`/`resolve`/`next`/`park`/`promote`/`queue`/`fire`),
   330	  install, and the resolution ladder and agent-facing invocation flow + guardrails are in [skills/2-daily/hq/SKILL.md](skills/2-daily/hq/SKILL.md). Write paths preview by default; `fire` never drives the harness.
   331	- Changes to `.tick/events/`, `src/project.js`, relay containment, or event/verb shape are usually
   332	  broader than they look. Treat them as at least Costly until proven otherwise.
   333	- **Contain tree-touching subagents with `isolation: "worktree"` (GH-177/GH-233).** A Claude Code
   334	  session spawning Agent/Workflow subagents that will *modify files* in this repo should pass
   335	  `isolation: "worktree"` so a runaway destructive command shreds a disposable checkout, not the main
   336	  tree (this repo has been wiped twice — see
   337	  `PROJECT/3-COMPLETED/GH-177-MKTEMP-TRAP-REPO-WIPE.md`). Know what it does NOT protect: worktrees
   338	  share `.git` objects/refs, so destructive *git* operations (`update-ref`, `branch -D`, resets,
   339	  force-push) still hit the real repo — a worktree-isolated agent once reset ROOT HEAD via
   340	  `rtl_enforce`'s commit-bypass guard. Harness-driven codex/agy lanes are covered by
   341	  `rtl_worktree_begin` instead and don't need the flag. Known frictions: `--require-clean` self-trips
   342	  on the driver's own lock dir inside a linked worktree, and untracked artifacts are invisible to a
   343	  worktree checkout — commit review inputs first. Read-only subagents (Explore, audits) don't need
   344	  isolation. Related guards: never execute `validate.sh`/`test/*.sh` under a sandboxed Bash call
   345	  (enforced by `relay-automation/hooks/gh177-sandbox-test-guard.sh` — re-run it un-sandboxed; do NOT
   346	  push it to CI to be exercised, see the CI rail below), and `test/mktemp-trap-guard.sh` statically
   347	  outlaws the wipe idiom repo-wide. **The "what it does NOT protect" list above is narrower than
   348	  reality — see the next rail (GH-564): a worktree isolates the working tree only, and everything
   349	  under `.git` is shared, which is why running the suite in one contaminated the parent clone twice.**
   350	- **Run the suite in a SEPARATE FULL CLONE, never in a clone whose state you care about — and a
   351	  linked worktree is NOT a way around it (GH-564).** `validate.sh` and `test/*.sh` can write to the
   352	  git config, remotes, and refs of the repository they are invoked from. On 2026-08-15 the primary

exec
/bin/zsh -lc "rg --files | rg 'marathon.monitor|progress|GH-100[126]|GH-1004'; nl -ba test/marathon-monitor.sh | sed -n '1,155p'; nl -ba utils/py/consult.py | sed -n '616,665p;775,805p;855,882p;920,940p'; rg -n 'rtl_driver_lock|DriverLock|driver_lock|signal.signal|SIGTERM' utils/py/marathon_drive.py" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-13569-zsltpsy2
 succeeded in 0ms:
TESTS-RESULTS/2026-10-02+GH-938/base-5212dae4/base-gh123-lock-progress-bound.log
test/gh370-progress-telemetry.sh
test/marathon-monitor.sh
test/gh123-lock-progress-bound.sh
test/gh438-removal-is-progress.sh
TESTS-RESULTS/2026-09-27+GH-793/head-teeth-progress.log
TESTS-RESULTS/2026-10-01+GH-909/focused/gh123-lock-progress-bound.log
     1	#!/usr/bin/env bash
     2	# test/marathon-monitor.sh — dependency-free tests for marathon-ls.sh.
     3	#
     4	# Covers:
     5	#   (a) Both lock-path cases:
     6	#       - Normal clone: .git/relay-driver.lock/pid
     7	#       - Vendored install: .relay-driver.lock/pid  (no .git/)
     8	#   (b) All four states:
     9	#       - LIVE  (pid = live process — $$)
    10	#       - STALE (pid = dead pid, 999999)
    11	#       - IDLE  (no lock + marathon.complete event)
    12	#       - GONE  (registry row pointing to a deleted path)
    13	#
    14	# Uses a fake registry.tsv via $XYZ_REGISTRY.
    15	# Final line: "marathon-monitor: N pass, M fail"
    16	set -uo pipefail
    17	
    18	HERE="$(cd "$(dirname "$0")" && pwd)"
    19	LS="$HERE/../relay-automation/marathon-ls.sh"
    20	
    21	PASS=0; FAIL=0
    22	pass() { printf '  PASS: %s\n' "$*"; PASS=$((PASS+1)); }
    23	fail() { printf '  FAIL: %s\n' "$*" >&2; FAIL=$((FAIL+1)); }
    24	
    25	echo "== test: marathon-monitor =="
    26	
    27	# ---------------------------------------------------------------------------
    28	# Temp fixture dir
    29	# ---------------------------------------------------------------------------
    30	_tmp="${TMPDIR:-/tmp}"; D="${_tmp%/}/marathon-monitor-test.$$"   # strip trailing slash so paths never contain '//'
    31	rm -rf "$D"
    32	mkdir -p "$D"
    33	trap 'rm -rf "$D"' EXIT
    34	
    35	# ---------------------------------------------------------------------------
    36	# Fixture helpers
    37	# ---------------------------------------------------------------------------
    38	
    39	make_clone_repo() {
    40	  # make_clone_repo <path> — create a fake "normal clone" (has .git/)
    41	  # GH-484: the phase dir is marathon-system/, what a current driver actually writes.
    42	  local repo="$1"
    43	  mkdir -p "$repo/.git" "$repo/.tick/events" "$repo/marathon-system/p1"
    44	}
    45	
    46	make_vendored_repo() {
    47	  # make_vendored_repo <path> — create a fake "vendored" repo (no .git/)
    48	  local repo="$1"
    49	  mkdir -p "$repo/.tick/events" "$repo/marathon-system/p1"
    50	}
    51	
    52	write_marathon_event() {
    53	  # write_marathon_event <repo> <type> [<ts>]
    54	  local repo="$1" type="$2" ts="${3:-2026-07-02T00:00:00.000Z}"
    55	  local events_dir="$repo/.tick/events"
    56	  mkdir -p "$events_dir"
    57	  # Use a fixed filename that matches *marathon*.jsonl.
    58	  local f="$events_dir/marathon-DRIVE.jsonl"
    59	  printf '{"type":"%s","ts":"%s"}\n' "$type" "$ts" >> "$f"
    60	}
    61	
    62	# ---------------------------------------------------------------------------
    63	# Build fake registry.tsv
    64	# ---------------------------------------------------------------------------
    65	REGISTRY="$D/registry.tsv"
    66	# Columns: install_dir  last_install_utc  tick_version  source_commit  coordinated_repo
    67	# Header line.
    68	printf 'install_dir\tlast_install_utc\ttick_version\tsource_commit\tcoordinated_repo\n' > "$REGISTRY"
    69	
    70	# We will add rows after creating fixtures below.
    71	
    72	# ---------------------------------------------------------------------------
    73	# Fixture 1: LIVE — normal clone (.git/) + live PID
    74	# ---------------------------------------------------------------------------
    75	REPO_LIVE="$D/repo-live"
    76	make_clone_repo "$REPO_LIVE"
    77	write_marathon_event "$REPO_LIVE" "marathon.start"
    78	# Create .git/relay-driver.lock/pid with our own PID (definitely alive).
    79	mkdir -p "$REPO_LIVE/.git/relay-driver.lock"
    80	printf '%s\n' "$$" > "$REPO_LIVE/.git/relay-driver.lock/pid"
    81	printf '%s\t2026-07-02\tv1\tabc\t%s\n' "$REPO_LIVE/.xyz" "$REPO_LIVE" >> "$REGISTRY"
    82	
    83	# ---------------------------------------------------------------------------
    84	# Fixture 2: STALE — vendored (.relay-driver.lock/) + dead PID
    85	# ---------------------------------------------------------------------------
    86	REPO_STALE="$D/repo-stale"
    87	make_vendored_repo "$REPO_STALE"
    88	write_marathon_event "$REPO_STALE" "marathon.start"
    89	# Create .relay-driver.lock/pid with a dead PID.
    90	mkdir -p "$REPO_STALE/.relay-driver.lock"
    91	printf '%s\n' "999999" > "$REPO_STALE/.relay-driver.lock/pid"
    92	printf '%s\t2026-07-02\tv1\tabc\t%s\n' "$REPO_STALE/.xyz" "$REPO_STALE" >> "$REGISTRY"
    93	
    94	# ---------------------------------------------------------------------------
    95	# Fixture 3: IDLE — clone, no lock, marathon.complete event
    96	# ---------------------------------------------------------------------------
    97	REPO_IDLE="$D/repo-idle"
    98	make_clone_repo "$REPO_IDLE"
    99	write_marathon_event "$REPO_IDLE" "marathon.complete" "2026-07-02T12:00:00.000Z"
   100	# No lock directory.
   101	printf '%s\t2026-07-02\tv1\tabc\t%s\n' "$REPO_IDLE/.xyz" "$REPO_IDLE" >> "$REGISTRY"
   102	
   103	# ---------------------------------------------------------------------------
   104	# Fixture 4: GONE — path that we will delete before running the check
   105	# ---------------------------------------------------------------------------
   106	REPO_GONE="$D/repo-gone"
   107	make_clone_repo "$REPO_GONE"
   108	printf '%s\t2026-07-02\tv1\tabc\t%s\n' "$REPO_GONE/.xyz" "$REPO_GONE" >> "$REGISTRY"
   109	# Delete the path now so marathon-ls.sh sees it as GONE.
   110	rm -rf "$REPO_GONE"
   111	
   112	# ---------------------------------------------------------------------------
   113	# Fixture 5 (GH-484): NEW-DEFAULT only — a run written by a current driver
   114	# ---------------------------------------------------------------------------
   115	REPO_NEW="$D/repo-new-default"
   116	make_clone_repo "$REPO_NEW"
   117	write_marathon_event "$REPO_NEW" "marathon.complete" "2026-08-09T12:00:00.000Z"
   118	printf 'STATUS: Open\n' > "$REPO_NEW/marathon-system/p1/RELAY.md"
   119	printf '%s\t2026-08-09\tv1\tabc\t%s\n' "$REPO_NEW/.xyz" "$REPO_NEW" >> "$REGISTRY"
   120	
   121	# ---------------------------------------------------------------------------
   122	# Fixture 6 (GH-484): LEGACY only — a pre-flip run, or a fleet repo whose
   123	# vendored .xyz/ has not re-synced and is therefore still writing to phases/.
   124	# ---------------------------------------------------------------------------
   125	REPO_LEGACY="$D/repo-legacy"
   126	make_clone_repo "$REPO_LEGACY"
   127	rm -rf "$REPO_LEGACY/marathon-system"
   128	mkdir -p "$REPO_LEGACY/phases/p1"
   129	write_marathon_event "$REPO_LEGACY" "marathon.complete" "2026-08-09T12:00:00.000Z"
   130	printf 'STATUS: Open\n' > "$REPO_LEGACY/phases/p1/RELAY.md"
   131	printf '%s\t2026-08-09\tv1\tabc\t%s\n' "$REPO_LEGACY/.xyz" "$REPO_LEGACY" >> "$REGISTRY"
   132	
   133	# ---------------------------------------------------------------------------
   134	# Fixture 7 (GH-484): BOTH populations present, and the LEGACY file is NEWER.
   135	# This is the falsifiable case: a naive "look in marathon-system/, return if
   136	# found" implementation passes fixtures 5 and 6 and fails only this one.
   137	# ---------------------------------------------------------------------------
   138	REPO_MIXED="$D/repo-mixed"
   139	make_clone_repo "$REPO_MIXED"
   140	mkdir -p "$REPO_MIXED/phases/p1"
   141	write_marathon_event "$REPO_MIXED" "marathon.complete" "2026-08-09T12:00:00.000Z"
   142	printf 'STATUS: Approved\n' > "$REPO_MIXED/marathon-system/p1/RELAY.md"
   143	sleep 1   # mtime granularity: `test -nt` is second-resolution on some filesystems
   144	printf 'STATUS: Open\n' > "$REPO_MIXED/phases/p1/RELAY.md"
   145	printf '%s\t2026-08-09\tv1\tabc\t%s\n' "$REPO_MIXED/.xyz" "$REPO_MIXED" >> "$REGISTRY"
   146	
   147	# ---------------------------------------------------------------------------
   148	# Run marathon-ls.sh with our fake registry
   149	# ---------------------------------------------------------------------------
   150	OUTPUT="$(XYZ_REGISTRY="$REGISTRY" bash "$LS" 2>/dev/null || true)"
   151	
   152	# Helper: get the STATE column (col 2) for a given repo path.
   153	state_for() {
   154	  local repo="$1"
   155	  printf '%s' "$OUTPUT" | awk -F'\t' -v r="$repo" '$1 == r { print $2 }'
   616	        models = [m.strip() for m in models_str.split(",") if m.strip()]
   617	        
   618	        procs = []
   619	        
   620	        for m in models:
   621	            if m == "claude":
   622	                f_out = os.path.join(run_dir, f"{label}.claude.md")
   623	                cenv = dict(base_env)
   624	                claude_bin = resolve_claude(cenv)
   625	                # Resolve identical settings/account routes for the probe and request.
   626	                claude_settings = ["--restricted", "--strict-mcp-config"]
   627	                try:
   628	                    if not claude_bin:
   629	                        raise ValueError("claude CLI not found; set CLAUDE_BIN")
   630	                    native_effort = effort_flags(cenv)
   631	                    claude_preflight(claude_bin, cenv, wt, cli_flags=claude_settings)
   632	                except ValueError as error:
   633	                    with open(f_out, "w") as stream:
   634	                        stream.write(f"consult: {error}\n")
   635	                    procs.append((None, m, f_out, time.time(), None))
   636	                    continue
   637	                claude_prompt = full_prompt
   638	                if tool_mode == "programmatic":
   639	                    claude_prompt += "\nClaude advisory seat: only Read/Grep/Glob are available; inspect source without executing probe scripts."
   640	                cmd = [claude_bin, "-p", claude_prompt, "--output-format", "json",
   641	                       "--model", cenv.get("CLAUDE_MODEL", "claude-sonnet-4-6"),
   642	                       "--tools", "Read,Grep,Glob", "--allowedTools", "Read,Grep,Glob",
   643	                       "--max-turns", cenv.get("CLAUDE_MAX_TURNS", "12"),
   644	                       "--max-budget-usd", cenv.get("CLAUDE_MAX_BUDGET", "0.50")] + claude_settings + native_effort
   645	                proc = guarded_with_timeout(cmd, wt, f_out, timeout_s, cenv, own_group=True)
   646	                procs.append((proc, m, f_out, time.time(), cmd))
   647	            elif m == "codex":
   648	                f_out = os.path.join(run_dir, f"{label}.codex.md")
   649	                cflags = os.environ.get("CODEX_FLAGS", "-s read-only").split()
   650	                cenv = dict(base_env)
   651	                if os.environ.get("CODEX_ALLOW_API_KEY", "0") != "1":
   652	                    cenv.pop("OPENAI_API_KEY", None)
   653	                cmd = [codex_bin, "exec"] + cflags + [full_prompt]
   654	                proc = guarded_with_timeout(cmd, wt, f_out, timeout_s, cenv)
   655	                procs.append((proc, "codex", f_out, time.time(), cmd))
   656	            elif m == "agy":
   657	                f_out = os.path.join(run_dir, f"{label}.agy.md")
   658	                if not agy_auth_preflight(agy_bin, f_out):
   659	                    procs.append((None, "agy", f_out, time.time(), None))
   660	                    continue
   661	                cmd = [agy_bin, "--dangerously-skip-permissions", "--print-timeout", f"{timeout_s}s", "-p", full_prompt]
   662	                proc = guarded_with_timeout(cmd, wt, f_out, timeout_s, dict(base_env))
   663	                procs.append((proc, "agy", f_out, time.time(), cmd))
   664	            elif m == "gemini":
   665	                ext = "json" if os.environ.get("CONSULT_GEMINI_JSON", "0") == "1" else "md"
   775	                    summary += f"\n  [FAIL] {m} -> {out} (see transcript for error)"
   776	                    results.append((m, out, False))
   777	                elif proc.returncode == 0 and (aider_answer_ok(out) if m == "aider" else advisor_answer_ok(out, m)):
   778	                    answered += 1
   779	                    summary += f"\n  [ok]   {m} -> {out}"
   780	                    survivor_model = m
   781	                    survivor_out = out
   782	                    results.append((m, out, True))
   783	                elif proc.returncode == 0:
   784	                    # exit 0 but the aider transcript proved an auth/config failure or empty answer
   785	                    failed += 1
   786	                    summary += f"\n  [FAIL] {m} -> {out} (see transcript for error)"
   787	                    results.append((m, out, False))
   788	                else:
   789	                    failed += 1
   790	                    summary += f"\n  [FAIL] {m} -> {out} (see transcript for error)"
   791	                    with open(out, "a") as f:
   792	                        f.write(f"\nconsult: advisor failed with exit {proc.returncode}\n")
   793	                        if m == "claude":
   794	                            f.write(f"consult: CLI diagnostics: {out}.stderr\n")
   795	                    results.append((m, out, False))
   796	            except subprocess.TimeoutExpired:
   797	                idle_reason = getattr(proc, "xyz_idle_reason", None)
   798	                if not idle_reason:  # The idle path already killed and reaped the advisor.
   799	                    _kill_advisor_group(proc)
   800	                failed += 1
   801	                marker = (f"PARTIAL — killed at idle threshold [{idle_reason}], no verdict"
   802	                          if idle_reason else f"PARTIAL — hit the {timeout_s}s cap, no verdict")
   803	                partial_path = surface_partial(out, m, marker)
   804	                summary += f"\n  [FAIL] {m} -> {partial_path} ({marker})"
   805	                results.append((m, out, False))
   855	                    for token in echoed_tokens:
   856	                        f.write(f"ECHOED {token}\n")
   857	                if not uncited and echoed_count > 0:
   858	                    provenance_warnings.append((m, echoed_count))
   859	
   860	        # GH-178 A2 / GH-215 (Python port): a panel that started with MORE THAN ONE requested advisor
   861	        # but ended with exactly one survivor is not a reconciled cross-model result — no second read
   862	        # happened, so treating its verdict as reconciled is exactly the failure mode this consult
   863	        # exists to avoid. Stamp it MECHANICALLY — into the surviving transcript itself, plus a
   864	        # format-agnostic sidecar marker — so the caveat travels with the data instead of living only
   865	        # in this run's stdout. Deliberately does NOT fire when only one model was ever requested: that
   866	        # is an intentional single-model query, not a degrade. Mirrors relay-automation/consult.sh
   867	        # (see the "GH-178 A2" comment there) — do not redesign, just port.
   868	        degraded = False
   869	        if len(procs) > 1 and answered == 1:
   870	            degraded = True
   871	            stamp = (
   872	                f"**SINGLE-MODEL — NOT RECONCILED** (only {survivor_model} answered; {failed} of "
   873	                f"{len(procs)} requested advisor(s) failed — this is one model's read, not a "
   874	                f"cross-model consult. Do not treat any claim below as cross-verified.)"
   875	            )
   876	            if not survivor_out.endswith(".json"):
   877	                try:
   878	                    with open(survivor_out, "r", errors="replace") as f:
   879	                        existing = f.read()
   880	                    with open(survivor_out, "w") as f:
   881	                        f.write(stamp + "\n\n" + existing)
   882	                except OSError:
   920	            xyz_write_ops_log_append("git worktree remove", f"git -C {root} worktree remove --force {wt}")
   921	        else:
   922	            warn(f"could not remove consult worktree; preserved at {wt}. Recover with git -C {shlex.quote(root)} worktree remove --force {shlex.quote(wt)}")
   923	            sys.exit(5)
   924	
   925	    print(f"consult: {answered} answered, {failed} failed -> {run_dir}{summary}")
   926	    if degraded:
   927	        warn(f"SINGLE-MODEL — NOT RECONCILED (stamped into {survivor_out} and {os.path.join(run_dir, 'DEGRADED-SINGLE-MODEL.txt')})")
   928	    if citeless_models:
   929	        warn(f"NO FIRSTHAND VERIFICATION CITED for: {' '.join(citeless_models)} (stamped into transcript(s) + sidecar(s) in {run_dir})")
   930	    for pw_model, pw_count in provenance_warnings:
   931	        warn(f"prompt-trace classifier: {pw_model} echoed {pw_count} cited claim(s) from {label}.PROMPT.txt (see {os.path.join(run_dir, f'{label}.{pw_model}.PROVENANCE.txt')})")
   932	    if answered == 0:
   933	        warn("all advisors failed")
   934	        sys.exit(5)
   935	    sys.exit(0)
   936	
   937	if __name__ == "__main__":
   938	    main()
21:from rtl import driver_lock_path  # noqa: E402
949:    for sig in (signal.SIGTERM, signal.SIGKILL):
1276:        # driver_lock_path (with a byte-for-byte Bash twin in relay-automation/driver-lock-lib.sh)
1278:        lock_dir, lock_label = driver_lock_path(root)
1783:        supervisor SIGTERM, the host going down under it) reaches neither, which is precisely the
3567:    # sat in a 8KB buffer that a SIGTERM discards, while the subprocesses wrote straight to the same
3577:    # SIGTERM — from an operator, a supervisor, a wall-clock kill, a host shutting down under the run
3579:    # KeyboardInterrupt and so already reached them; SIGTERM did not, and SIGTERM is what an
3589:    for _sig in (signal.SIGTERM, signal.SIGINT, signal.SIGHUP):
3591:            signal.signal(_sig, _terminate)

exec
/bin/zsh -lc "rg -n 'progress|watch|heartbeat' relay-automation/marathon-ls.sh; rg --files skills | rg '/(start-task|relay-xyz)/SKILL.md"'$'"'; nl -ba utils/py/marathon_drive.py | sed -n '1270,1326p;3570,3613p'; nl -ba relay-automation/marathon-ls.sh | sed -n '1,70p;90,185p'; nl -ba test/marathon.sh | sed -n '1,40p'; nl -ba test/gh280-jog-marathon-adapter.sh | sed -n '1,28p'" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-13569-zsltpsy2
 succeeded in 0ms:
skills/1-hourly/relay-xyz/SKILL.md
skills/1-hourly/start-task/SKILL.md
  1270	        # GH-49b/GH-207: the lock lives in .git/ (never committed) for a normal clone. In a linked
  1271	        # worktree .git is a FILE pointing at the shared gitdir, so resolve the real common dir and put
  1272	        # the lock there — otherwise --require-clean sees the driver's own lock as untracked dirt inside
  1273	        # the worktree. A vendored .xyz/ copy (no .git) falls back to a hidden lock beside the scripts.
  1274	        # GH-448: this resolution is the canonical write-side one — every read-only consumer (marathon-
  1275	        # ls.sh, marathon-live.sh, find-harness.sh) must agree with it, so it lives in rtl.py's shared
  1276	        # driver_lock_path (with a byte-for-byte Bash twin in relay-automation/driver-lock-lib.sh)
  1277	        # rather than being reimplemented here.
  1278	        lock_dir, lock_label = driver_lock_path(root)
  1279	
  1280	        try:
  1281	            os.mkdir(lock_dir)
  1282	        except OSError:
  1283	            holder = ""
  1284	            pid_file = os.path.join(lock_dir, "pid")
  1285	            if os.path.isfile(pid_file):
  1286	                try:
  1287	                    with open(pid_file, 'r') as f: holder = f.read().strip()
  1288	                except: pass
  1289	            
  1290	            is_running = False
  1291	            if holder:
  1292	                try:
  1293	                    os.kill(int(holder), 0)
  1294	                    is_running = True
  1295	                except: pass
  1296	            
  1297	            if is_running:
  1298	                eprint(f"marathon-drive: another driver is active in this repo (pid {holder}, lock: {lock_label}).")
  1299	                eprint("marathon-drive: Concurrent runs in the same clone are unsafe (GH-42 ROOT HEAD hazard).")
  1300	                sys.exit(1)
  1301	            
  1302	            eprint(f"marathon-drive: reclaiming stale relay-driver.lock (holder pid {holder or 'none'} not running).")
  1303	            # Sentinel Tier 1 (GH-281/GH-342): record the auto-heal. Emitted BEFORE the reclaim, so
  1304	            # the finding survives even if the rmtree/mkdir below fails and the run exits 1.
  1305	            xyz_debug_log_stale_lock(root)
  1306	            try:
  1307	                shutil.rmtree(lock_dir)
  1308	                os.mkdir(lock_dir)
  1309	            except:
  1310	                eprint("marathon-drive: could not acquire relay-driver.lock after reclaiming a stale one.")
  1311	                sys.exit(1)
  1312	        
  1313	        with open(os.path.join(lock_dir, "pid"), 'w') as f:
  1314	            f.write(str(os.getpid()) + "\n")
  1315	        
  1316	        os.environ["RELAY_DRIVER_LOCKED"] = "1"
  1317	        def cleanup_lock():
  1318	            try: shutil.rmtree(lock_dir)
  1319	            except: pass
  1320	        import atexit
  1321	        atexit.register(cleanup_lock)
  1322	
  1323	    xyz_append_bin = get_env("XYZ_APPEND_BIN", os.path.join(xyz_harness, "utils", "telemetry", "append-xyz-completion.sh"))
  1324	
  1325	    def xyz_marathon_emit(health, desc):
  1326	        ctx = get_env("XYZ_HARNESS_CONTEXT", "")
  3570	    for _stream in (sys.stdout, sys.stderr):
  3571	        try:
  3572	            _stream.reconfigure(line_buffering=True)
  3573	        except Exception:
  3574	            pass    # Python < 3.7 or a stream that cannot be reconfigured — best effort
  3575	
  3576	    # GH-388: without this the `finally` below is unreachable for the case the issue is ABOUT. A
  3577	    # SIGTERM — from an operator, a supervisor, a wall-clock kill, a host shutting down under the run
  3578	    # — terminates CPython immediately: no `finally`, no exit hooks, no record. SIGINT already raised
  3579	    # KeyboardInterrupt and so already reached them; SIGTERM did not, and SIGTERM is what an
  3580	    # unattended run actually receives. Converting it to SystemExit puts both on the same path.
  3581	    #
  3582	    # The exit code stays 128+signal, the shell convention the driver's own `_exit_meaning` and
  3583	    # marathon.sh's halt-reason table already read, so nothing downstream has to learn a new number.
  3584	    # SIGKILL and a host panic remain unreachable by design — no handler runs for those, which is why
  3585	    # the record this enables is a floor and not a guarantee, and why #384's recovery path is a
  3586	    # separate lane rather than something this one quietly claims to cover.
  3587	    def _terminate(signum, _frame):
  3588	        raise SystemExit(128 + signum)
  3589	    for _sig in (signal.SIGTERM, signal.SIGINT, signal.SIGHUP):
  3590	        try:
  3591	            signal.signal(_sig, _terminate)
  3592	        except (ValueError, OSError, AttributeError):
  3593	            pass    # not the main thread, or the platform has no such signal — best effort
  3594	
  3595	    _exit_code = 0
  3596	    try:
  3597	        try:
  3598	            main()
  3599	        except SystemExit as _e:
  3600	            _exit_code = _e.code if isinstance(_e.code, int) else (0 if _e.code is None else 1)
  3601	        except BaseException:
  3602	            _exit_code = 1
  3603	            # GH-280: an unhandled driver crash must not read as "lock contention" (also exit 1)
  3604	            # in the result receipt — the two demand opposite responses from a supervisor.
  3605	            _RESULT["crashed"] = True
  3606	            raise
  3607	    finally:
  3608	        for _hook in _ON_EXIT:
  3609	            try:
  3610	                _hook(_exit_code)
  3611	            except Exception:
  3612	                pass
  3613	    sys.exit(_exit_code)
     1	#!/usr/bin/env bash
     2	# marathon-ls.sh — cross-repo marathon monitor engine (read-only).
     3	#
     4	# Enumerates every repo known to the xyz registry (hub + col-5 coordinated_repo),
     5	# resolves its relay-driver lock path, derives LIVE/STALE/IDLE/GONE state, finds
     6	# the newest *marathon*.jsonl tick event, and prints one TSV row per repo.
     7	#
     8	# Output columns (tab-separated, header row first):
     9	#   REPO  STATE  PHASE  LAST-TICK  PID  RELAY-FILE
    10	#
    11	# STATE derivation:
    12	#   LIVE  — lock dir present + pid file alive (kill -0 succeeds)
    13	#   STALE — lock dir present + pid dead or missing
    14	#   IDLE  — no lock + newest marathon tick event is phase.approved or marathon.complete
    15	#   GONE  — repo path does not exist on disk
    16	#
    17	# Registry: $XYZ_REGISTRY (default: ${XDG_CONFIG_HOME:-$HOME/.config}/xyz/registry.tsv)
    18	# Registry format: install_dir<TAB>last_install_utc<TAB>tick_version<TAB>source_commit<TAB>coordinated_repo
    19	#
    20	# This script writes NO state to any monitored repo.
    21	set -euo pipefail
    22	
    23	XYZ_REGISTRY="${XYZ_REGISTRY:-${XDG_CONFIG_HOME:-$HOME/.config}/xyz/registry.tsv}"
    24	
    25	# Resolve this script's real directory (bash 3.2 / macOS safe — no readlink -f).
    26	_src="${BASH_SOURCE[0]}"
    27	while [ -h "$_src" ]; do
    28	  _dir="$(cd -P "$(dirname "$_src")" >/dev/null 2>&1 && pwd)"
    29	  _src="$(readlink "$_src")"
    30	  case "$_src" in /*) ;; *) _src="$_dir/$_src" ;; esac
    31	done
    32	SELF_DIR="$(cd -P "$(dirname "$_src")" >/dev/null 2>&1 && pwd)"
    33	HUB_REPO="$(cd "$SELF_DIR/.." && pwd)"
    34	
    35	# shellcheck source=relay-automation/driver-lock-lib.sh
    36	. "$SELF_DIR/driver-lock-lib.sh"
    37	
    38	# ---------------------------------------------------------------------------
    39	# helpers
    40	# ---------------------------------------------------------------------------
    41	
    42	trim_cr() { printf '%s' "${1%$'\r'}"; }
    43	
    44	# Resolve the relay-driver lock path for a given repo root — delegates to the shared resolver
    45	# (GH-448: this used to guess 2 branches inline and missed the linked-worktree case, where .git is a
    46	# FILE and the driver's real lock lives at the git common dir, not <repo>/.git/relay-driver.lock).
    47	lock_path_for_repo() {
    48	  driver_lock_path_for_repo "$1"
    49	}
    50	
    51	# Find the newest *marathon*.jsonl file under <repo>/.tick/events/.
    52	newest_marathon_jsonl() {
    53	  local repo="$1"
    54	  local events_dir="$repo/.tick/events"
    55	  [ -d "$events_dir" ] || return 0
    56	  # Use ls -t (newest first) rather than `find -newer` for bash 3.2 compat.
    57	  # Glob for files matching *marathon*.jsonl; pick the first (newest by mtime).
    58	  local f
    59	  # shellcheck disable=SC2012
    60	  f="$(ls -t "$events_dir"/*marathon*.jsonl 2>/dev/null | head -1 || true)"
    61	  printf '%s' "$f"
    62	}
    63	
    64	# Extract the last event line from a jsonl file and return phase type + timestamp.
    65	# Outputs: TYPE<TAB>TIMESTAMP  (or empty strings when not parseable).
    66	last_event_fields() {
    67	  local jsonl="$1"
    68	  [ -f "$jsonl" ] || { printf '\t'; return 0; }
    69	  local last_line type ts
    70	  last_line="$(tail -1 "$jsonl" 2>/dev/null || true)"
    90	    local pid=""
    91	    [ -f "$pid_file" ] && pid="$(cat "$pid_file" 2>/dev/null || true)"
    92	    pid="$(trim_cr "${pid:-}")"
    93	    if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
    94	      _STATE="LIVE"
    95	      _PID="$pid"
    96	    else
    97	      _STATE="STALE"
    98	      _PID="${pid:--}"
    99	    fi
   100	    return 0
   101	  fi
   102	
   103	  # No lock — state is IDLE (no lock present).
   104	  _STATE="IDLE"
   105	  _PID="-"
   106	}
   107	
   108	# Find the newest <phase-dir>/*/RELAY.md path for a repo (used in RELAY-FILE column).
   109	#
   110	# GH-484: reads BOTH the current default (marathon-system/) and the historical one (phases/), and
   111	# picks whichever holds the newer file — not a straight swap. Two populations need to stay visible
   112	# at once: this repo's ~72 committed pre-flip runs (deliberately not migrated), and fleet repos
   113	# whose vendored .xyz/ has not re-synced yet and so is still writing to phases/. Checking only the
   114	# new name would make the monitor silently report nothing for either.
   115	newest_relay_file() {
   116	  local repo="$1" d f newest=""
   117	  for d in "$repo/marathon-system" "$repo/phases"; do
   118	    [ -d "$d" ] || continue
   119	    # shellcheck disable=SC2012
   120	    f="$(ls -t "$d"/*/RELAY.md 2>/dev/null | head -1 || true)"
   121	    [ -n "$f" ] || continue
   122	    if [ -z "$newest" ] || [ "$f" -nt "$newest" ]; then newest="$f"; fi
   123	  done
   124	  printf '%s' "${newest:--}"
   125	}
   126	
   127	# ---------------------------------------------------------------------------
   128	# print one row per repo
   129	# ---------------------------------------------------------------------------
   130	
   131	print_row() {
   132	  local repo="$1"
   133	  local repo_abs
   134	
   135	  # Canonicalize path (no readlink -f on macOS bash 3.2).
   136	  if [ -d "$repo" ]; then
   137	    repo_abs="$(cd "$repo" && pwd)"
   138	  else
   139	    repo_abs="$repo"
   140	  fi
   141	
   142	  # GONE: repo does not exist on disk.
   143	  if [ ! -d "$repo_abs" ]; then
   144	    printf '%s\tGONE\t-\t-\t-\t-\n' "$repo_abs"
   145	    return 0
   146	  fi
   147	
   148	  local lock
   149	  lock="$(lock_path_for_repo "$repo_abs")"
   150	
   151	  resolve_state "$lock"
   152	  local state="$_STATE" pid="$_PID"
   153	
   154	  local marathon_jsonl phase ts relay_file
   155	  marathon_jsonl="$(newest_marathon_jsonl "$repo_abs")"
   156	  if [ -n "$marathon_jsonl" ]; then
   157	    local fields
   158	    fields="$(last_event_fields "$marathon_jsonl")"
   159	    phase="$(printf '%s' "$fields" | cut -f1)"
   160	    ts="$(printf '%s' "$fields" | cut -f2)"
   161	  else
   162	    phase="-"
   163	    ts="-"
   164	  fi
   165	  [ -n "$phase" ] || phase="-"
   166	  [ -n "$ts" ]    || ts="-"
   167	
   168	  relay_file="$(newest_relay_file "$repo_abs")"
   169	
   170	  printf '%s\t%s\t%s\t%s\t%s\t%s\n' \
   171	    "$repo_abs" "$state" "$phase" "$ts" "$pid" "$relay_file"
   172	}
   173	
   174	# ---------------------------------------------------------------------------
   175	# collect repos: hub + registry col-5
   176	# ---------------------------------------------------------------------------
   177	
   178	printf 'REPO\tSTATE\tPHASE\tLAST-TICK\tPID\tRELAY-FILE\n'
   179	
   180	# Hub repo always first.
   181	print_row "$HUB_REPO"
   182	
   183	# Registry — col 5 (coordinated_repo), skip header + comment lines.
   184	if [ -f "$XYZ_REGISTRY" ]; then
   185	  while IFS=$'\t' read -r install_dir _last_utc _tick_ver _source_commit coordinated_repo _extra; do
     1	#!/usr/bin/env bash
     2	# marathon.sh test: the multi-phase orchestrator parses MARATHON.yaml, runs phases in depends_on
     3	# order via marathon-drive (STUBBED), HALTS on the first failure (later phases NOT started), and
     4	# emits marathon.complete only when every phase is approved. (Phase 4 / M5)
     5	source "$(dirname "$0")/_setup.sh" marathon
     6	unset MARATHON_LANE_NS
     7	# GH-217: this suite's own GH-212 assertions (tests 12-14) must decide the plan-location policy
     8	# themselves. An ambient MARATHON_ALLOW_PLAN_OUTSIDE_WORKING=1 inherited from an outer marathon run
     9	# (legitimate there, via marathon.sh's documented override) flips test 12's expected exit-2 refusal
    10	# to exit 0 — the gate_env scrub is the primary fix; this unset is defensive hygiene so the suite
    11	# stays honest even under a hand-rolled --pre-advance-cmd that skips the helper. Test 13 sets the
    12	# override explicitly per-invocation, which is unaffected by an unset here.
    13	unset MARATHON_ALLOW_PLAN_OUTSIDE_WORKING
    14	REPO="$(cd "$(dirname "$0")/.." && pwd)"
    15	MSH="$REPO/relay-automation/marathon.sh"
    16	YBIN="$REPO/bin/marathon-yaml"
    17	
    18	mkdir -p "$A/briefs" "$A/PROJECT/2-WORKING"
    19	for p in p1 p2 p3 a b; do printf 'brief for %s\n' "$p" > "$A/briefs/$p.md"; done
    20	
    21	# Stub marathon-drive: record "id|cap|reviewer|artifact|relay-task|turn-timeout|lane-ns" per phase;
    22	# exit 4 if id == STUB_FAIL_PHASE. (GH-116: relay-task column captures marathon.sh's --relay-task
    23	# override, if any. GH-207: lane-ns captures the marathon-scoped lane key passed from plan name.)
    24	STUB="$WORK/drive.sh"
    25	cat > "$STUB" <<'STUB'
    26	#!/usr/bin/env bash
    27	set -u
    28	pid=""; cap=""; rev=""; art=""; rtask=""; timeout="${RELAY_TURN_TIMEOUT_S:-}"; lane_ns="${MARATHON_LANE_NS:-}"; pdir=""
    29	while (($#)); do case "$1" in
    30	  --phase-id) pid="$2"; shift 2;;
    31	  --round-cap) cap="$2"; shift 2;;
    32	  --reviewer) rev="$2"; shift 2;;
    33	  --artifact) art="$2"; shift 2;;
    34	  --relay-task) rtask="$2"; shift 2;;
    35	  --phases-dir) pdir="$2"; shift 2;;
    36	  *) shift;;
    37	esac; done
    38	printf '%s|%s|%s|%s|%s|%s|%s|%s\n' "$pid" "$cap" "$rev" "$art" "$rtask" "$timeout" "$lane_ns" "$pdir" >> "$WORK/phases-ran"
    39	[ "$pid" = "${STUB_FAIL_PHASE:-__none__}" ] && exit 4
    40	exit 0
     1	#!/usr/bin/env bash
     2	# gh280-jog-marathon-adapter.sh — GH-280 Phase 1: Jog ↔ Marathon machine contracts.
     3	#
     4	# Exercises, with REAL Preflight → Marathon → Relay chains and deterministic agent/GitHub
     5	# shims (never --simulate):
     6	#   - swarm-preflight emits the additive swarm-preflight/marathon-invocation@1 artifact
     7	#   - marathon-drive --result-file emits exactly one marathon-drive/result@1 receipt per
     8	#     terminal exit: success, pre-dispatch refusal, builder failure, reviewer cap,
     9	#     gate failure, timeout, lane park, protected-branch redirect, PR-publication failure
    10	#   - jog_run's contract loaders reject unsupported schema versions and malformed artifacts
    11	#   - both installation shapes: harness at repo ROOT and vendored under .xyz/
    12	source "$(dirname "$0")/_setup.sh" gh280-jog-marathon-adapter
    13	unset MARATHON_LANE_NS MARATHON_ROOT MARATHON_RELAY_DRIVE MARATHON_AGENT_CMD TICK_BIN
    14	REPO="$(cd "$(dirname "$0")/.." && pwd)"
    15	
    16	# ── deterministic GitHub shim: logs every call, canned PR answers ─────────────────────────────
    17	# Anything not understood exits 1 — the same shape as an unauthenticated/offline gh, so
    18	# preflight's issue-state probe degrades to `unknown` instead of touching the network.
    19	STUB_BIN="$WORK/stub-bin"
    20	mkdir -p "$STUB_BIN"
    21	GH_STUB_LOG="$WORK/gh-stub-calls.log"
    22	export GH_STUB_LOG
    23	GH_STUB_PR_JSON="${GH_STUB_PR_JSON:-}"   # optional: path to a canned `gh pr list --json` array
    24	export GH_STUB_PR_JSON
    25	cat > "$STUB_BIN/gh" <<'GH_EOF'
    26	#!/usr/bin/env bash
    27	set -u
    28	printf '%s\n' "$*" >> "${GH_STUB_LOG:?}"

exec
/bin/zsh -lc 'gh pr view 1004 --repo HiQS-Labs/XYZ-forge --json state,baseRefName,headRefOid,body; gh issue view 1006 --repo HiQS-Labs/XYZ-forge --json title,body' in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-13569-zsltpsy2
 succeeded in 746ms:
{"baseRefName":"development","body":"Fixes #1001 and #1002, the two harness bugs that sank the GH-1 Phase 0 marathon in HiQS-Labs/XYZ-layout-engine. One branch because both touch `utils/py/marathon_drive.py`.\n\n## #1001 — vendored run resolves the wrong repo\n- **Cause:** `e53f5d06` (GH-396 review fixups, PR #403, 2026-09-02) put the `XYZ_HARNESS` check ahead of the running script's own `.xyz/` copy in `harness_home()`. On a Mac that exports `XYZ_HARNESS` (the relay-xyz-documented setup), a vendored `marathon-drive` resolved its root to the global harness clone and parked the lane on that repo's issue #1.\n- **Fix:** the running `.xyz/` copy now wins; `XYZ_HARNESS` is the fallback. Explicit path/anchor arguments, `XYZ_VENDORED` and `XYZ_CALLER_ROOT` keep their semantics.\n- The issue-closed preflight now queries the lane's target repo (`_gate_root`) for both the origin lookup and the `gh repo view` fallback. Its park message now names the repo it queried.\n\n## #1002 — builder scratch fails the turn and burns the attempt cap\n- The GH-113 relocation already existed, but it only accepted root-level `test_`-style names. agy's `test-satori.mjs` (hyphen) and `tools/spike/test_satori.mjs` (nested) both failed the turn with exit 6.\n- **Scratch names:** `rtl_scratch_relocate` now accepts `(test|fix|repro|probe)[-_]` prefixes.\n- **Nested scratch, worktree turns only:** inside `rtl_worktree_end`, nested untracked scratch files are relocated, and so is a wholly new directory if every file in it is scratch.\n  - Mixed directories, nested non-scratch files and the in-ROOT `rtl_check` path still fail, as before.\n  - Worktree copy-back stays allowlist-only.\n- **Cap order:** an at-cap lane now parks before any render, branch or relay commit. This uses a read-only pre-check; the single append is unchanged.\n- **Dry-run:** prints attempts against the cap, and is aware of `--force`.\n- **Unchanged:** containment failures still count toward the cap (GH-45).\n- **Builder prompt:** the agy preamble now states the real rule, including the worktree-only qualifier.\n\n## Verification\n- **Plan QA:** Codex, Approved in round 3 and attested (`relay-system/2026-10-08/gh1001-1002-plan-qa.md`).\n- **Final QA:** Codex, Approved in round 1 and attested (`relay-system/2026-10-08/gh1001-1002-final-qa.md`).\n- **Existing suites edited to stay truthful (no new suite, GH-831):**\n  - `gh396` is 42/42. Its new assertion is red on base.\n  - `gh113` is 27/27. It is 21/27 on base, with all six GH-1002 positives red. An accept-mixed mutation turns the mixed-directory control red (25/27).\n- **Manual checks, red on base:**\n  - `TESTS-RESULTS/2026-10-08+GH-1001/issue_closed_repo_probe.py` passes 4/4 and fails 4/4 on base.\n  - `TESTS-RESULTS/2026-10-08+GH-1002/cap_order_check.sh` passes 9/9. On base, a parked fire adds a commit (2 → 3) and dry-run prints no attempts line.\n- **Focused suites in a disposable full clone:**\n\n  | Suite | Result |\n  |---|---|\n  | lane-attempt-cap | 26/26 |\n  | debug-mantra | 17/17 |\n  | gh342 | 29/29 |\n  | gh280 | 223/223 |\n  | marathon-drive | 162/162 |\n  | agy-turn | 65/65 |\n\n- **Full gate:** `ci-local.sh` on `4b2aa888` in a disposable full clone exited 0 with all steps passed. It is self-reported, not hosted promotion evidence (GH-509). Commits after it are docs, evidence and relay files only.\n- **Pre-push gate:** the first push was red only because the shell inherited the operator's `XYZ_HARNESS` (the open #912 class). A re-push with it cleared passed the full gate.\n\n## Limits and follow-ups\n- #912 (ci-local/validate inheriting `XYZ_HARNESS`) is still open and out of scope.\n- The frozen Bash `marathon-drive.sh` (GH-308) is unchanged, so `XYZ_PYTHON=0` keeps the old cap ordering.\n- Consumers pick up the fix on their next `.xyz/` re-vendor.\n\nRatings: #1001 80/75/50/70 and #1002 65/65/50/55; rationale in `PROJECT/2-WORKING/GH-1001-VENDORED-HARNESS-ROOT.md`. Reversibility: Easy.\n\n🤖 Generated with [Claude Code](https://claude.com/claude-code)\n\n\n<!-- This is an auto-generated comment: release notes by coderabbit.ai -->\n\n## Summary by CodeRabbit\n\n* **Bug Fixes**\n  * Vendored harnesses are now selected ahead of the `XYZ_HARNESS` fallback when running from a project’s `.xyz` directory.\n  * Closed-issue checks now use the configured target repository and identify it in park messages.\n  * In isolated worktree turns, eligible untracked scratch files—and new directories containing only eligible scratch files—are moved to scratch storage. Mixed-content directories and other off-lane changes remain blocked.\n  * Lanes at their attempt limit now park before relay commits; dry-run output shows attempts versus the limit and whether the lane would proceed with `--force`.\n\n<!-- end of auto-generated comment: release notes by coderabbit.ai -->","headRefOid":"51ec2ba59b13a10ac3d8c370b19aae2fa51225f0","state":"OPEN"}
{"body":"The GH-5 XYZ Layout Engine marathon halted in its first phase after the bounded review cap. The launcher had no scheduled operator progress checks; status was inspected only when requested. Add opt-in bounded progress monitoring to the existing marathon supervisor, without a second executor or new daemon.\n\nExisting capabilities (vendored XYZ Forge source commit `062ae45f01faf73bf78bcc10fcba86cd7d5c2ad7`): `marathon_drive.py` writes a driver heartbeat at a default 30-second interval, bounds turns/gates, and emits escalation/terminal receipts. `marathon-ls.sh`, `marathon-detail.sh` and `marathon-tui.sh` offer read-only views. These do not constitute six scheduled progress checks with operator-visible reports. Graph generation 2026-09-01 is stale/partial for relevant paths; the claims above use current source inspection. Related: #186 telemetry improvements, #189 parked-claim recovery, #291 supervisor ownership.\n\nRequested default for this workflow: **600 seconds × 6 checks**, a one-hour observation window. A liveness heartbeat alone must never be reported as accepted progress.\n\n## Acceptance\n\n- [ ] Add opt-in interval and check-count controls to the existing supervisor/launcher, with validated positive bounds and clear effective settings in dry-run output.\n- [ ] At each due check record run/clone identity, active phase/role, heartbeat age, last qualifying progress, completed/total phases, current gate/review state, and relevant receipt/log pointers.\n- [ ] Surface each report through the existing run log and supported caller notification channel; document when an unattended caller cannot deliver conversational updates.\n- [ ] Emit completion/escalation/halt immediately, then cancel outstanding checks; distinguish a live but stalled process from a successful milestone.\n- [ ] After the sixth check, emit an explicit monitoring-window-ended state and the next observation action. Do not imply completion, kill an authorized run, or leave an unbounded timer behind.\n- [ ] Monitoring is read-only: it must not claim/reap tokens, dispatch builders, restart parked lanes, bypass gates or raise attempt/review caps. Reuse existing lock/state readers and supervisor ownership.\n- [ ] Preserve existing Bash/Python behavior and document supported parity; avoid a parallel monitor state machine or scheduling service.\n- [ ] Verify due times, terminal cancellation and six-check bounds using existing suites/manual clock-controlled receipts, under GH-831 test-admission rules; do not add a suite merely for timer plumbing.\n\n## Scope and tradeoff\n\nThis issue adds observation, not automatic recovery or guaranteed completion. Native timeouts/escalation remain authoritative. The Layout Engine recovery run will use a temporary session-local bounded observer until this feature is shipped; no installed harness edits in that consumer repo.\n\nReversibility: Easy. PRS estimates (provisional): priority 80, severity 55, appeal 80 (explicit operator request), effort cheapness 65. Implementation belongs in canonical XYZ Forge; adoption through the existing vendor/sync rail.\n","title":"Marathon: bounded progress monitoring at 10-minute intervals × 6"}

exec
/bin/zsh -lc "nl -ba relay-automation/marathon-detail.sh | sed -n '1,80p'; rg -n 'heartbeat|progress|approved|gate|RELAY|tick|source' relay-automation/marathon-detail.sh; nl -ba utils/py/marathon_drive.py | sed -n '3078,3137p'; rg -n 'Step 8|QA|receipt|permission|draft|clone|relay' skills/1-hourly/start-task/SKILL.md | head -35; rg -n 'progress|monitor|resume|retry' skills/1-hourly/relay-xyz/SKILL.md | head -30; rg -n 'rtl_scratch_relocate|test_\\|fix_|test\\|fix\\|repro|nested' relay-automation/relay-turn-lib.sh | head -20; nl -ba /Users/noelsaw/.codex/skills/swe/SKILL.md | sed -n '1,80p'" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-13569-zsltpsy2
 succeeded in 0ms:
     1	#!/usr/bin/env bash
     2	# marathon-detail.sh <repo> — preview for ONE repo path (read-only).
     3	#
     4	# Prints:
     5	#   - STATUS: / NEXT: lines from the newest marathon-system/*/RELAY.md (falling back to phases/) (if any)
     6	#   - Last ~10 lines/events from the newest .tick/events/*marathon*.jsonl
     7	#
     8	# Writes NO state to any monitored repo.
     9	set -euo pipefail
    10	
    11	usage() {
    12	  printf 'Usage: marathon-detail.sh <repo-path>\n' >&2
    13	  exit 2
    14	}
    15	
    16	[ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ] && { usage; }
    17	[ $# -ge 1 ] || usage
    18	
    19	REPO="$1"
    20	
    21	# ---------------------------------------------------------------------------
    22	# helpers
    23	# ---------------------------------------------------------------------------
    24	
    25	section() { printf '\n--- %s ---\n' "$*"; }
    26	
    27	# ---------------------------------------------------------------------------
    28	# RELAY.md preview
    29	# ---------------------------------------------------------------------------
    30	
    31	if [ ! -d "$REPO" ]; then
    32	  printf 'REPO: %s\n' "$REPO"
    33	  printf 'STATE: GONE (path does not exist on disk)\n'
    34	  exit 0
    35	fi
    36	
    37	printf 'REPO: %s\n' "$REPO"
    38	
    39	# Newest <phase-dir>/*/RELAY.md. GH-484: reads BOTH the current default (marathon-system/) and the
    40	# historical one (phases/) and keeps the newer — see the same fallback in marathon-ls.sh for why
    41	# both populations have to stay visible (un-migrated pre-flip runs, and not-yet-re-synced fleet
    42	# repos still writing to phases/).
    43	RELAY_FILE=""
    44	for PHASES_DIR in "$REPO/marathon-system" "$REPO/phases"; do
    45	  [ -d "$PHASES_DIR" ] || continue
    46	  # shellcheck disable=SC2012
    47	  CANDIDATE="$(ls -t "$PHASES_DIR"/*/RELAY.md 2>/dev/null | head -1 || true)"
    48	  [ -n "$CANDIDATE" ] || continue
    49	  if [ -z "$RELAY_FILE" ] || [ "$CANDIDATE" -nt "$RELAY_FILE" ]; then RELAY_FILE="$CANDIDATE"; fi
    50	done
    51	
    52	if [ -n "$RELAY_FILE" ] && [ -f "$RELAY_FILE" ]; then
    53	  section "RELAY.md: $(basename "$(dirname "$RELAY_FILE")")/RELAY.md"
    54	  # Extract STATUS: and NEXT: lines (case-sensitive as used in relay templates).
    55	  grep -E '^(STATUS|NEXT):' "$RELAY_FILE" 2>/dev/null || printf '(no STATUS:/NEXT: lines found)\n'
    56	else
    57	  section "RELAY.md"
    58	  printf '(no marathon-system/*/RELAY.md or phases/*/RELAY.md found)\n'
    59	fi
    60	
    61	# ---------------------------------------------------------------------------
    62	# Recent tick events
    63	# ---------------------------------------------------------------------------
    64	
    65	EVENTS_DIR="$REPO/.tick/events"
    66	MARATHON_JSONL=""
    67	if [ -d "$EVENTS_DIR" ]; then
    68	  # shellcheck disable=SC2012
    69	  MARATHON_JSONL="$(ls -t "$EVENTS_DIR"/*marathon*.jsonl 2>/dev/null | head -1 || true)"
    70	fi
    71	
    72	section "Recent tick events"
    73	if [ -n "$MARATHON_JSONL" ] && [ -f "$MARATHON_JSONL" ]; then
    74	  printf 'File: %s\n' "$MARATHON_JSONL"
    75	  tail -10 "$MARATHON_JSONL"
    76	else
    77	  printf '(no *marathon*.jsonl events found in %s)\n' "$EVENTS_DIR"
    78	fi
5:#   - STATUS: / NEXT: lines from the newest marathon-system/*/RELAY.md (falling back to phases/) (if any)
6:#   - Last ~10 lines/events from the newest .tick/events/*marathon*.jsonl
28:# RELAY.md preview
39:# Newest <phase-dir>/*/RELAY.md. GH-484: reads BOTH the current default (marathon-system/) and the
43:RELAY_FILE=""
47:  CANDIDATE="$(ls -t "$PHASES_DIR"/*/RELAY.md 2>/dev/null | head -1 || true)"
49:  if [ -z "$RELAY_FILE" ] || [ "$CANDIDATE" -nt "$RELAY_FILE" ]; then RELAY_FILE="$CANDIDATE"; fi
52:if [ -n "$RELAY_FILE" ] && [ -f "$RELAY_FILE" ]; then
53:  section "RELAY.md: $(basename "$(dirname "$RELAY_FILE")")/RELAY.md"
55:  grep -E '^(STATUS|NEXT):' "$RELAY_FILE" 2>/dev/null || printf '(no STATUS:/NEXT: lines found)\n'
57:  section "RELAY.md"
58:  printf '(no marathon-system/*/RELAY.md or phases/*/RELAY.md found)\n'
62:# Recent tick events
65:EVENTS_DIR="$REPO/.tick/events"
72:section "Recent tick events"
  3078	    except Exception as _exc:
  3079	        # Deliberately NOT fail-closed, and this is the one place worth arguing about.
  3080	        #
  3081	        # An agy review called the silent narrowing a blocker: if the root cannot be resolved the
  3082	        # transcript goes unchecked, supposedly risking the same expensive halt. That premise does
  3083	        # not hold here — `save_transcript()` resolves the root the SAME way and returns False on
  3084	        # failure (see its own try/except), so it never reaches its `git add`. A resolution failure
  3085	        # therefore produces no transcript and no halt, and refusing the run would invent a new way
  3086	        # for a healthy one to fail — precisely what preflight_write_set_trackable's docstring
  3087	        # forbids.
  3088	        #
  3089	        # The legitimate half of that review is that it was SILENT. It is not any more: a narrower
  3090	        # guard now says so, so nobody reads a green preflight as covering three paths when it
  3091	        # covered two.
  3092	        log("preflight: transcript root unresolved (%s) — write-set check covers RELAY.md and "
  3093	            "ESCALATION.md only, not the transcript" % _exc.__class__.__name__)
  3094	    if os.path.realpath(commit_root) == os.path.realpath(root):
  3095	        preflight_write_set_trackable(root, _phase_write_set + _transcript_write_set,
  3096	                                      transcript_paths=_transcript_write_set)
  3097	    else:
  3098	        log(f"preflight: phase write-set commits to {commit_root}, not the harness root — "
  3099	            f"probing each repo separately (#131)")
  3100	        preflight_write_set_trackable(commit_root, _phase_write_set)
  3101	        if _transcript_write_set:
  3102	            preflight_write_set_trackable(root, _transcript_write_set,
  3103	                                          transcript_paths=_transcript_write_set)
  3104	
  3105	    # GH-402: refuse to make the first commit if the RECEIVING repo is sitting on its trunk.
  3106	    #
  3107	    # `marathon/<slug>-<date>` is advisory text in a preflight packet and nothing enforces it, so a
  3108	    # marathon commits to whatever branch the target happens to have checked out. The driver is the
  3109	    # last common point on every commit path — relay turns, escalations, transcripts all funnel
  3110	    # through here — which is why the fix belongs at this one site rather than in each writer.
  3111	    #
  3112	    # Measured against `args.target_root or root`, the existing idiom for "the repo this run writes
  3113	    # to", and against THAT repo's trunk rather than the harness's: under --target-root they are
  3114	    # different repos with different defaults, and checking the harness's would be the plausible
  3115	    # wrong answer that passes every test written against a same-repo fixture.
  3116	    def refuse_trunk_commit():
  3117	        commit_root = args.target_root or root
  3118	        # The carve-out preflight already computes: risk==1 in an independent zone is allowed to
  3119	        # proceed on the current branch without asking (SP_SKIP_BRANCH_PROMPT). Honoured from the
  3120	        # environment rather than by parsing the packet — the driver does not read packets, and
  3121	        # GH-386 is what happens when something pretends it does.
  3122	        if os.environ.get("SP_SKIP_BRANCH_PROMPT") == "1":
  3123	            log("branch guard: skipped — preflight recorded the risk=1/independent-zone carve-out (GH-402)")
  3124	            return
  3125	        if args.allow_trunk_commit or os.environ.get("MARATHON_ALLOW_TRUNK_COMMIT") == "1":
  3126	            log("branch guard: overridden by --allow-trunk-commit / MARATHON_ALLOW_TRUNK_COMMIT (GH-402)")
  3127	            return
  3128	
  3129	        current = _cmd_out(["git", "-C", commit_root, "symbolic-ref", "--quiet", "--short", "HEAD"])
  3130	        if not current:
  3131	            return          # detached HEAD: not trunk, and not this guard's business
  3132	
  3133	        # Fires only on a SHARED trunk — one `origin/HEAD` actually resolves to. This is a narrowing
  3134	        # of trunk_ref()'s more permissive fallback, and it is deliberate on both counts.
  3135	        #
  3136	        # The harm this guard exists to prevent is stated in its own message: a marathon's turns
  3137	        # commit continuously, so a run that lands on trunk cannot be un-landed by stopping it, only
4:  Start one task or a batch of GitHub issues and carry it through fresh full clones,
5:  repo-governed intake, grounded recon, surgical DRY planning, Codex relay plan QA,
6:  execution, verification, final relay QA, and ready PRs. Use for /start-task,
7:  "start these issues", or requests to clone, register, execute, QA, and make a PR.
9:  and retiring clones use merge-cleanup.
15:repository's existing execution, governance, and relay tools. Keep the canonical
25:issue creation, task branches, commits, pushes, Codex QA, and opening PRs. Preserve
26:explicit limits such as "plan only", "hold after QA", or a different reviewer.
29:do not repeat permission questions already answered. Merge, deployment, and clone
37:> 1. **Resolve intake & isolate in a fresh clone (Steps 1–3).** Verify the canonical remote/issue, provision a fresh full clone with a task branch off `origin/development`, register the PDDA capture doc in `1-INBOX`, and record 4-axis RELEASES task ratings.
38:> 2. **Ground in recon & draft a surgical plan (Steps 4–5).** Trace live entry points, state writes, and blast radius before proposing changes; design the leanest DRY plan that extends existing subsystems with falsifiable acceptance checks.
39:> 3. **Pre-implementation plan QA (Step 6).** Run a Codex relay review on the plan, adjudicate findings against ground-truth evidence, and iterate until approved before writing production code.
41:> 5. **Final relay QA & open ready PR (Steps 8–9).** Run final Codex relay QA on the completed diff and test evidence; upon approval, push through the pre-push gate, open the PR against `development`, and retain the task clone for merge handoff.
43:> **Overall Goal:** Issue implemented to spec, validated through double-relay QA (plan + final), and submitted as a verified, conflict-free PR ready for merge.
58:   RELEASES infrastructure is not permission to install it or invent a substitute.
62:   canonical plan: issue URL, scope, dependencies, clone/branch, plan location,
65:   related issues that change the same seam into one clone/branch/PR; separate
79:   a fresh **full clone from the canonical remote**, verify origin and base SHA,
81:   off `origin/development`, with the per-clone git hooks installed and checked.
91:     the clone is first provisioned, and it never changes on resume.
95:     the primary clone (`$(dirname <primary>)/<folder>`). Never `/tmp`, a
100:     gate or verification clone for the task is `<folder>-gate` / `<folder>-verify`,
104:     one task clone → this is a resume (below). Two or more task clones, or only
109:   existing task clone, branch, remote branch, remote PR status (`gh pr list --head <branch>`),
110:   and live HEAD commit rather than duplicating clones, creating redundant branches, or
121:   recon, persist/read back each tracked task's score before plan QA or execution,
175:6. **QA the plan before implementation.** For every non-simple change, load
176:   `relay-xyz` and use its locator, prerequisite checks, thread protocol and
188:   relay thread. Adjudicate findings against evidence, stated requirements, and
193:   disposition, revise, and re-review until Approved within the relay's configured
198:   a brief reason; final QA still applies.
202:   Approved plan QA and before the first implementation write: resolve the exact
205:   Registration/rating/QA are not starts. Refuse uncertain identity/native state;
216:   plan QA if new evidence materially changes scope, architecture, or risk.
218:   relay review loops, run ONLY the focused target test suite (`bash test/<target-test>.sh`
172:> Anything else that describes the lock — driver headers, monitor docs — links here rather than
275:`relay-drive.sh` is the **supervisor** (round cap, no-progress escalation, reads the file's `STATUS:`
569:- **`relay-drive.sh`**: `0` closed Approved/Closed · `3` no-progress (token actor didn't move) ·
545:# non-matching path keep today's off-lane behavior byte-for-byte; a nested cache (e.g.
921:    rtl_scratch_relocate "$path" "$wt" "$RTL_ROOT" && continue
1134:#     tree root; a nested off-lane path is a lane mistake, not scratch, and still violates.
1142:rtl_scratch_relocate() {  # <path> <src-root> [dest-root] — 0 = relocated, 1 = not scratch-shaped
1146:  [[ "$p" =~ ^(tmp|temp|scratch|debug|test_|fix_|repro_|probe_) ]] \
1157:  rtl_log_always "rtl_scratch_relocate: path=$p src=$src_root dest=$dest (GH-113)"
1192:  rtl_scratch_relocate "$p" "$RTL_ROOT" && return 0
     1	---
     2	name: swe
     3	description: Apply software-engineering standards when authoring or reviewing project plans, build/spec/PRD documents, architecture RFCs, or agent governance. Use for "write a plan", "review this build doc", "apply our SWE standards", or "is this plan ready to build"; also apply before drafting a project plan. Grades grounded recon, minimal scope, diagnosis, blast radius, and verifiable acceptance. This is a planning rubric, not a debugging or execution pipeline.
     4	---
     5	
     6	# SWE
     7	
     8	Vibe the build; engineer the plan. This lens is the discipline that lets a fast v1.x ship without becoming a liability.
     9	
    10	A governance overlay for **build/spec documents** — the "build v1.x" doc, the implementation spec, the architecture RFC. It does not debug code or pick a tradeoff in the moment; it reads the *plan* and asks whether the plan already embodies the engineering standards before a single line is written. Run it two ways: as an **authoring gate** (write the doc against it) or as a **review rubric** (read a doc, emit findings + a verdict). The whole bet: most plans fail not on the feature but on the five things below, smuggled past in prose — starting with Pillar 0, where the plan is grounded (or not) in the system as it actually exists.
    11	
    12	## Pillar 0: Recon — is the plan grounded in a system anyone actually read?
    13	
    14	The four pillars grade what the document *says*. Pillar 0 grades its **provenance**: was it written against the system as it exists, or from the prompt plus three grepped files? This pillar is about evidence, not consequences — what breaks when a *step* runs is Blast's job, below.
    15	
    16	- [ ] The current system was traced before the first plan heading: entry points and call paths in, every read *and write* site of the state involved, the contracts crossed, the failure and rollback paths today.
    17	- [ ] Claims about what the change touches cite code somebody read — `file:line`, not "various downstream."
    18	- [ ] What could not be verified is listed as an explicit unknown with the command or file that would settle it, never smoothed into the findings.
    19	
    20	**Applicability first.** Pillar 0 does not apply to greenfield work, a non-code plan, or a change contained to files the doc already quotes — mark it N/A and say why. Where it does apply, grade the *evidence*, not the artifact: a [recon](../recon/SKILL.md) Recon Map is the standard form, but a trace embedded in the doc or supplied by the author counts. **Block** only when the doc makes claims about an existing system that nothing behind it verifies; a thin trace on a genuinely small change is a **Fix**, not a Block.
    21	
    22	**Pillar 0 feeds Blast; it does not satisfy it.** The trace establishes the *current-state* radius — who depends today on what the plan touches. Blast then asks what each proposed step *adds*: new systems, new data, new people, the shield, the tripwire, the undo class. Copying the map's radius into the Blast section unchanged understates the plan's own impact and fails Blast on its own terms.
    23	
    24	## The four pillars
    25	
    26	Each pillar is a lens on the document. A v1.x doc that satisfies a pillar contains the thing explicitly; a doc that "implies" it fails the pillar — implied is unbuilt.
    27	
    28	### 1. Minimal (Ponytail) — does the plan earn each part it adds?
    29	
    30	The plan's default answer to "add a thing" is *no*. Scope, dependencies, and abstractions are all liabilities until justified in the doc.
    31	
    32	- [ ] Every new component answers "does this need to exist?" (YAGNI) — speculative scope is cut or deferred, not built.
    33	- [ ] Sourcing ladder is honored to minimize mechanism, not requirements: stdlib → native platform feature → already-installed dep → one line of our own. A new dep names what it buys that the rung above does not. (Security and observability requirements are never simplified away, only implemented via the laziest viable mechanism).
    34	- [ ] No premature abstraction — the plugin layer / framework / generic engine is justified by ≥2 concrete present uses, not one hypothetical future one.
    35	- [ ] Bias is stated: delete > add, boring > clever, shortest diff that works. A complexity cap is named (e.g. stdlib-only, ~600-line ceiling) where it applies.
    36	
    37	*Planning translation:* this is the editor pass on scope. Most v1.x bloat is decided here, in the doc, long before code.
    38	
    39	### 2. Diagnosable (Mantra) — does the plan say how it will fail and be found?
    40	
    41	A build doc that provisions zero observability is a debugging session deferred to production. Bake the diagnosis path into v1.x, not v1.next.
    42	
    43	- [ ] Instrumentation is right-sized but explicit: a single actionable error log is better than an unread ELK stack, but silent failures are blocked. The plan names the exact log, metric, or alert that fires when it breaks.
    44	- [ ] Every iterate/retry loop has a **stop condition** (e.g. 5-failure hard stop, 10-total cap). An unbounded "retry until it works" is a defect in the plan.
    45	- [ ] Failures are made reproducible: the plan names how a failure is repro'd, and treats intermittent failure as a *signal* (concurrency / ordering / env / TOCTOU), not noise to retry away.
    46	- [ ] State changes are auditable — append-only event log over in-place mutation where the history matters.
    47	- [ ] **The plan names debug-mantra as its execution-time debugging protocol** — "we'll figure it out when it breaks" is a Diagnosable failure.
    48	
    49	*Planning translation:* the runtime debugging ritual, pulled forward. If the doc can't say how you'll see it break, you'll see it break in prod.
    50	
    51	### 3. Blast — does the plan price its irreversible moves before committing?
    52	
    53	For every wide-impact or hard-to-undo step, the doc must already carry the cost. Don't dress a one-way door as a tweak.
    54	
    55	- [ ] Each risky step names its **undo class**: easy / costly / one-way door. One-way doors are flagged, never silent.
    56	- [ ] **Blast radius** is named — the exact systems, data, and people that break if this step goes wrong (not "various downstream").
    57	- [ ] A **shield** is specified — flag, adapter, pilot/canary, dual-write, or an explicit "none."
    58	- [ ] A **tripwire** exists for anything costly or one-way: *how* you'll know to pull it and *by when* (the point of no return). A shield with no tripwire is a brake with no warning light.
    59	
    60	For the full per-decision accounting, defer to the **blast-radius** skill — this pillar only enforces that the v1.x doc *contains* that accounting for its irreversible steps.
    61	
    62	### 4. Proof (Done) — can the plan prove it's finished, separately from claiming it?
    63	
    64	Editor and grader are different roles. The plan must define "done" in terms something other than the author can check.
    65	
    66	- [ ] Every task has a **measurable done-criterion** — a checkable output or metric, not "works" / "improved" / "robust."
    67	- [ ] Tests are specified *and the plan requires they actually run* — "tests pass" means an execution artifact, not an assertion.
    68	- [ ] **No orphan tasks**: every step maps to a success criterion, and every success criterion is covered by a step.
    69	- [ ] **Closed loop**: For medium/large efforts, backend/data work must explicitly connect to a user-facing UI plane or final consumer. Fetching data without surfacing it to the user is an incomplete loop.
    70	- [ ] **Observed vs. predicted is kept separate** — the doc never launders a projection ("this will reduce load 40%") as evidence. Predictions are labeled as such.
    71	
    72	*Planning translation:* PlanProof's editor/grader separation at document scale. The grader reads only what's written, not what the author meant.
    73	
    74	## House invariants
    75	
    76	Non-negotiable conventions a v1.x doc must satisfy regardless of pillar. These are cheap to check and expensive to skip.
    77	
    78	- [ ] **FSM threshold** — model an explicit state machine only past ~4 states; below that a flag or enum is leaner. Past it, an ad-hoc tangle of booleans is the defect.
    79	- [ ] **Single write path** — one writer per piece of state. Multiple write paths to the same table/file are a race waiting to happen; name the single path.
    80	- [ ] **Append-only event log** only when audit or history is an explicit business requirement (JSONL or equivalent); otherwise, simple in-place updates are the default.

codex
PR #1004 is still open at the supplied SHA. Its fixes matter here: this checkout resolves `XYZ_HARNESS` before a running vendored copy, and checks the attempt cap after committing the relay render. Consumer continuation must account for those defects, rather than assume pinning a PR SHA makes it safe.

exec
/bin/zsh -lc "rg -n 'Step 8|QA|receipt|fresh|clone|relay' skills/1-hourly/start-task/SKILL.md | head -25; rg -n 'progress|monitor|resume|retry' skills/1-hourly/relay-xyz/SKILL.md | head -18; nl -ba relay-automation/relay-turn-lib.sh | sed -n '4240,4260p'; rg -n 'rtl_scratch_relocate|test_\\*|fix_\\*' relay-automation/relay-turn-lib.sh" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-13569-zsltpsy2
 succeeded in 0ms:
4:  Start one task or a batch of GitHub issues and carry it through fresh full clones,
5:  repo-governed intake, grounded recon, surgical DRY planning, Codex relay plan QA,
6:  execution, verification, final relay QA, and ready PRs. Use for /start-task,
7:  "start these issues", or requests to clone, register, execute, QA, and make a PR.
9:  and retiring clones use merge-cleanup.
15:repository's existing execution, governance, and relay tools. Keep the canonical
25:issue creation, task branches, commits, pushes, Codex QA, and opening PRs. Preserve
26:explicit limits such as "plan only", "hold after QA", or a different reviewer.
29:do not repeat permission questions already answered. Merge, deployment, and clone
37:> 1. **Resolve intake & isolate in a fresh clone (Steps 1–3).** Verify the canonical remote/issue, provision a fresh full clone with a task branch off `origin/development`, register the PDDA capture doc in `1-INBOX`, and record 4-axis RELEASES task ratings.
39:> 3. **Pre-implementation plan QA (Step 6).** Run a Codex relay review on the plan, adjudicate findings against ground-truth evidence, and iterate until approved before writing production code.
41:> 5. **Final relay QA & open ready PR (Steps 8–9).** Run final Codex relay QA on the completed diff and test evidence; upon approval, push through the pre-push gate, open the PR against `development`, and retain the task clone for merge handoff.
43:> **Overall Goal:** Issue implemented to spec, validated through double-relay QA (plan + final), and submitted as a verified, conflict-free PR ready for merge.
62:   canonical plan: issue URL, scope, dependencies, clone/branch, plan location,
65:   related issues that change the same seam into one clone/branch/PR; separate
79:   a fresh **full clone from the canonical remote**, verify origin and base SHA,
81:   off `origin/development`, with the per-clone git hooks installed and checked.
91:     the clone is first provisioned, and it never changes on resume.
95:     the primary clone (`$(dirname <primary>)/<folder>`). Never `/tmp`, a
100:     gate or verification clone for the task is `<folder>-gate` / `<folder>-verify`,
104:     one task clone → this is a resume (below). Two or more task clones, or only
109:   existing task clone, branch, remote branch, remote PR status (`gh pr list --head <branch>`),
110:   and live HEAD commit rather than duplicating clones, creating redundant branches, or
121:   recon, persist/read back each tracked task's score before plan QA or execution,
175:6. **QA the plan before implementation.** For every non-simple change, load
172:> Anything else that describes the lock — driver headers, monitor docs — links here rather than
275:`relay-drive.sh` is the **supervisor** (round cap, no-progress escalation, reads the file's `STATUS:`
569:- **`relay-drive.sh`**: `0` closed Approved/Closed · `3` no-progress (token actor didn't move) ·
921:    rtl_scratch_relocate "$path" "$wt" "$RTL_ROOT" && continue
1137:#   - NAME must look like transient scratch (tmp*/temp*/scratch*/debug*/test_*/fix_*/repro_*/probe_*
1142:rtl_scratch_relocate() {  # <path> <src-root> [dest-root] — 0 = relocated, 1 = not scratch-shaped
1157:  rtl_log_always "rtl_scratch_relocate: path=$p src=$src_root dest=$dest (GH-113)"
1192:  rtl_scratch_relocate "$p" "$RTL_ROOT" && return 0

codex
**ANSWER:** Agree with monitoring plus a skill-driven, bounded repair procedure. A general runtime recovery controller is not justified. PR-based continuation is feasible, but the current contracts do **not yet establish a safe, budget-preserving handoff to a repaired harness revision**.

This is a task-directed source review, not an exhaustive audit. Graph tools were unavailable. No files, tests, builders, or git state were changed.

**[Pass] Agree — put observation at the chain owner.**

`marathon.sh` owns phase ordering, blocks on each driver invocation, and exits on the first failure (`relay-automation/marathon.sh:266`, `:310`, `:318`). The phase driver’s heartbeat belongs to a single phase (`utils/py/marathon_drive.py:1484`). Starting six checks inside every phase would silently multiply and restart the window.

Start one read-only observer from `marathon.sh`, before the phase loop, and terminate it through the chain’s lifecycle. It may be a child process, but must never dispatch work. Use six absolute deadlines from chain launch: +600 through +3600 seconds; phase transitions and retries do not reset them. Bound each snapshot read so reporting cannot indefinitely delay shutdown. On sleep/resume, report missed deadlines without inventing historical snapshots.

Reuse the chain log (`relay-automation/marathon.sh:241`) and existing readers. However, `marathon-ls.sh` selects the newest event/relay by mtime (`:51`, `:115`): that is useful fleet visibility, insufficient run attribution. Bind observations to the launched plan, clone, phase and token.

**[Blocker] Blocking — PR publication is not a continuation primitive.**

Supported today:

- Explicit harness/tool paths (`relay-automation/marathon.sh:53`; `utils/py/marathon_drive.py:1121`).
- Terminal receipts with execution, lane, token, attempts, review and gate evidence (`utils/py/marathon_drive.py:235`).
- Already-approved gate-only re-entry (`utils/py/marathon_drive.py:2856`).
- Narrow timeout recovery after an actual reviewer handoff (`utils/py/marathon_drive.py:3459`).
- Jog receipt reconciliation without dispatch, explicit gate retry, and explicit rebuild preserving lane attempts (`utils/py/jog_run.py:651`, `:707`, `:813`).

Missing is an **explicit continuation handoff binding the original authorization/state root to the exact replacement harness SHA**, after proving the former child and descendants are stopped and exclusive ownership is established. It must preserve plan/lane identity, receipts, consumed attempts, repair allowance and deadline while recording any new execution/token as a successor. Current result receipts identify the product candidate, not a verified replacement harness revision.

Do not equate driver exit or lock disappearance with descendant termination: the driver invokes relay synchronously, while its signal handler raises `SystemExit` (`utils/py/marathon_drive.py:3353`, `:3587`). That handoff needs demonstrated evidence.

**[Blocker] Blocking — respect #1004 as an external dependency.**

Read-only GitHub inspection confirmed [PR #1004](https://github.com/HiQS-Labs/XYZ-forge/pull/1004) remains **OPEN**, targeting `development`, at `51ec2ba59b13a10ac3d8c370b19aae2fa51225f0`.

Current source prioritizes `XYZ_HARNESS` over the running vendored copy (`utils/py/harness_paths.py:44`), and commits the relay render before checking the attempt cap (`utils/py/marathon_drive.py:3238`, `:3277`). These directly undermine naïve consumer restart/adoption.

Do not duplicate those fixes or call them merged. Either await adoption of the merged dependency, or explicitly authorize and verify an immutable dependency composition containing it. Its containment changes also fall outside the proposed “minor repair” category.

**[Should] Agree — constrain repairs by semantics, not diff size.**

Eligibility requires a reproduced local harness defect, a traced cause, a narrow allowlisted correction, a falsifier, and independent review plus relevant verification. Examples could include correcting a diagnostic formatting error or a demonstrably wrong non-authoritative argument.

Exclude lock/ownership logic, containment, gate/review semantics, schemas, deletion, credentials, bridges, dependency expansion and product-scope changes. A small diff touching those remains consequential. Unknown causes, partial artifacts awaiting review, genuine review-cap exhaustion and ordinary product failures are not automatic repair candidates.

The current driver explicitly documents a later-invocation risk involving unreviewed partial artifacts (`utils/py/marathon_drive.py:3446`). Re-entry must not interpret artifact existence as acceptance.

**[Should] Optional — three advisors can improve diagnosis; votes cannot authorize execution.**

The three seats already exist (`utils/py/consult.py:621`, `:647`, `:656`). What does not exist is a safety quorum: the consult can exit zero with partial panel success (`utils/py/consult.py:925`).

Provide every seat the same reproduction, exact source/environment revisions, failure receipt, causal trace, proposed scope, exclusions, remaining budget and falsifier. Require firsthand citations and explicit recommendation or abstention.

Recommend **majority for “worth attempting repair”**: at least two independent affirmative seats. Timeouts, empty answers and abstentions are not affirmative votes; never lower the threshold. Preserve dissent. A concrete safety objection must be resolved by evidence or the procedure parks, regardless of majority. Unanimity adds availability vetoes without proving safety. The panel is optional advisory overhead, never a substitute for post-change independent QA (`AGENTS.md:326`).

**[Should] Agree — separate observation, recovery and outcomes.**

Suggested launch contract:

- Observation remains opt-in **600 × 6**.
- Recovery requires separate explicit authorization, a required absolute deadline, **one repair episode and at most one continuation dispatch**.
- Diagnosis, consult, repair, QA, verification and publication consume that shared allowance. No nested repair of the repair; no fresh execution/token resets.
- Existing attempt/review caps remain ceilings. No `--force`, cap increases or gate substitutions.
- At the recovery deadline, stop recovery-owned work through the existing termination mechanism; failed termination means park and report uncertain ownership. Do not begin continuation without sufficient remaining time.

Meaningful **product progress** is a newly accepted deliverable with relevant verification bound to its candidate, deduplicated across repeated reports. The driver already binds approval before publishing phase success (`utils/py/marathon_drive.py:2705`). Heartbeats, tokens and log growth are activity.

**Preparation progress** is a reviewed repair PR or reproducible blocker handoff, reported separately. A gate rerun of the same accepted deliverable is verification activity, not another delivered milestone.

Resolve the requirement conflicts explicitly: the one-hour observation window does not authorize several-hour recovery. Window expiry stops observations, not an otherwise authorized marathon. A child halt is reported immediately and cancels its outstanding checks; authorized recovery then gets a separate, explicit status without rewriting that halt as success.

**[Should] Ordered implementation boundary and proof.**

1. Refine GH-1006 into observation acceptance plus a bounded recovery procedure in `skills/1-hourly/relay-xyz/SKILL.md`, reusing `start-task`’s full-clone, plan-QA and final-QA workflow (`skills/1-hourly/start-task/SKILL.md:37`). Default recovery outcome: publish and park.
2. Add chain-owned observation lifecycle in `relay-automation/marathon.sh`; use a small Python reader for timing/snapshots if needed. Preserve child exit codes. Reuse driver receipts and heartbeat; do not add recovery decisions to `marathon_drive.py`.
3. Verify with existing `test/marathon.sh`, `test/marathon-monitor.sh`, relevant receipt suites, and manual clock-controlled receipts. Red controls: phase transition resets the clock; seventh check; terminal exit leaves observer alive; heartbeat-only activity falsely counts as progress; stale receipt from another run; missing data falsely reports success.
4. Only then implement the narrow continuation handoff if still required. Manually falsify mismatched harness SHA, surviving descendant, changed state root, exhausted budget, missing QA and fresh-token budget reset. Reuse Jog semantics without routing marathon chains through a new Jog executor.
5. Verify in disposable full clones; commit manual provenance. No new suite or gate machinery (`AGENTS.md:142`). Observation rollback is disabling its flag. Continuation is **Costly** until proven: rollback means stop, retain evidence and park; selecting the prior harness never rolls back product commits automatically.

**[Nit] Skip — unsupported guarantees.** No guaranteed completion, immediate notification during host failure, persistent skill execution after caller termination, or guaranteed chat delivery. SIGKILL/host failure already exceed the driver’s reporting guarantee (`utils/py/marathon_drive.py:3584`). Choose and document the supported notification channel.

**RECOMMENDATION:** Ship bounded observation and repair-to-PR procedure first; enable unmerged-PR continuation only after the exact-SHA, ownership and shared-budget handoff is independently demonstrated.
tokens used
108,656
**ANSWER:** Agree with monitoring plus a skill-driven, bounded repair procedure. A general runtime recovery controller is not justified. PR-based continuation is feasible, but the current contracts do **not yet establish a safe, budget-preserving handoff to a repaired harness revision**.

This is a task-directed source review, not an exhaustive audit. Graph tools were unavailable. No files, tests, builders, or git state were changed.

**[Pass] Agree — put observation at the chain owner.**

`marathon.sh` owns phase ordering, blocks on each driver invocation, and exits on the first failure (`relay-automation/marathon.sh:266`, `:310`, `:318`). The phase driver’s heartbeat belongs to a single phase (`utils/py/marathon_drive.py:1484`). Starting six checks inside every phase would silently multiply and restart the window.

Start one read-only observer from `marathon.sh`, before the phase loop, and terminate it through the chain’s lifecycle. It may be a child process, but must never dispatch work. Use six absolute deadlines from chain launch: +600 through +3600 seconds; phase transitions and retries do not reset them. Bound each snapshot read so reporting cannot indefinitely delay shutdown. On sleep/resume, report missed deadlines without inventing historical snapshots.

Reuse the chain log (`relay-automation/marathon.sh:241`) and existing readers. However, `marathon-ls.sh` selects the newest event/relay by mtime (`:51`, `:115`): that is useful fleet visibility, insufficient run attribution. Bind observations to the launched plan, clone, phase and token.

**[Blocker] Blocking — PR publication is not a continuation primitive.**

Supported today:

- Explicit harness/tool paths (`relay-automation/marathon.sh:53`; `utils/py/marathon_drive.py:1121`).
- Terminal receipts with execution, lane, token, attempts, review and gate evidence (`utils/py/marathon_drive.py:235`).
- Already-approved gate-only re-entry (`utils/py/marathon_drive.py:2856`).
- Narrow timeout recovery after an actual reviewer handoff (`utils/py/marathon_drive.py:3459`).
- Jog receipt reconciliation without dispatch, explicit gate retry, and explicit rebuild preserving lane attempts (`utils/py/jog_run.py:651`, `:707`, `:813`).

Missing is an **explicit continuation handoff binding the original authorization/state root to the exact replacement harness SHA**, after proving the former child and descendants are stopped and exclusive ownership is established. It must preserve plan/lane identity, receipts, consumed attempts, repair allowance and deadline while recording any new execution/token as a successor. Current result receipts identify the product candidate, not a verified replacement harness revision.

Do not equate driver exit or lock disappearance with descendant termination: the driver invokes relay synchronously, while its signal handler raises `SystemExit` (`utils/py/marathon_drive.py:3353`, `:3587`). That handoff needs demonstrated evidence.

**[Blocker] Blocking — respect #1004 as an external dependency.**

Read-only GitHub inspection confirmed [PR #1004](https://github.com/HiQS-Labs/XYZ-forge/pull/1004) remains **OPEN**, targeting `development`, at `51ec2ba59b13a10ac3d8c370b19aae2fa51225f0`.

Current source prioritizes `XYZ_HARNESS` over the running vendored copy (`utils/py/harness_paths.py:44`), and commits the relay render before checking the attempt cap (`utils/py/marathon_drive.py:3238`, `:3277`). These directly undermine naïve consumer restart/adoption.

Do not duplicate those fixes or call them merged. Either await adoption of the merged dependency, or explicitly authorize and verify an immutable dependency composition containing it. Its containment changes also fall outside the proposed “minor repair” category.

**[Should] Agree — constrain repairs by semantics, not diff size.**

Eligibility requires a reproduced local harness defect, a traced cause, a narrow allowlisted correction, a falsifier, and independent review plus relevant verification. Examples could include correcting a diagnostic formatting error or a demonstrably wrong non-authoritative argument.

Exclude lock/ownership logic, containment, gate/review semantics, schemas, deletion, credentials, bridges, dependency expansion and product-scope changes. A small diff touching those remains consequential. Unknown causes, partial artifacts awaiting review, genuine review-cap exhaustion and ordinary product failures are not automatic repair candidates.

The current driver explicitly documents a later-invocation risk involving unreviewed partial artifacts (`utils/py/marathon_drive.py:3446`). Re-entry must not interpret artifact existence as acceptance.

**[Should] Optional — three advisors can improve diagnosis; votes cannot authorize execution.**

The three seats already exist (`utils/py/consult.py:621`, `:647`, `:656`). What does not exist is a safety quorum: the consult can exit zero with partial panel success (`utils/py/consult.py:925`).

Provide every seat the same reproduction, exact source/environment revisions, failure receipt, causal trace, proposed scope, exclusions, remaining budget and falsifier. Require firsthand citations and explicit recommendation or abstention.

Recommend **majority for “worth attempting repair”**: at least two independent affirmative seats. Timeouts, empty answers and abstentions are not affirmative votes; never lower the threshold. Preserve dissent. A concrete safety objection must be resolved by evidence or the procedure parks, regardless of majority. Unanimity adds availability vetoes without proving safety. The panel is optional advisory overhead, never a substitute for post-change independent QA (`AGENTS.md:326`).

**[Should] Agree — separate observation, recovery and outcomes.**

Suggested launch contract:

- Observation remains opt-in **600 × 6**.
- Recovery requires separate explicit authorization, a required absolute deadline, **one repair episode and at most one continuation dispatch**.
- Diagnosis, consult, repair, QA, verification and publication consume that shared allowance. No nested repair of the repair; no fresh execution/token resets.
- Existing attempt/review caps remain ceilings. No `--force`, cap increases or gate substitutions.
- At the recovery deadline, stop recovery-owned work through the existing termination mechanism; failed termination means park and report uncertain ownership. Do not begin continuation without sufficient remaining time.

Meaningful **product progress** is a newly accepted deliverable with relevant verification bound to its candidate, deduplicated across repeated reports. The driver already binds approval before publishing phase success (`utils/py/marathon_drive.py:2705`). Heartbeats, tokens and log growth are activity.

**Preparation progress** is a reviewed repair PR or reproducible blocker handoff, reported separately. A gate rerun of the same accepted deliverable is verification activity, not another delivered milestone.

Resolve the requirement conflicts explicitly: the one-hour observation window does not authorize several-hour recovery. Window expiry stops observations, not an otherwise authorized marathon. A child halt is reported immediately and cancels its outstanding checks; authorized recovery then gets a separate, explicit status without rewriting that halt as success.

**[Should] Ordered implementation boundary and proof.**

1. Refine GH-1006 into observation acceptance plus a bounded recovery procedure in `skills/1-hourly/relay-xyz/SKILL.md`, reusing `start-task`’s full-clone, plan-QA and final-QA workflow (`skills/1-hourly/start-task/SKILL.md:37`). Default recovery outcome: publish and park.
2. Add chain-owned observation lifecycle in `relay-automation/marathon.sh`; use a small Python reader for timing/snapshots if needed. Preserve child exit codes. Reuse driver receipts and heartbeat; do not add recovery decisions to `marathon_drive.py`.
3. Verify with existing `test/marathon.sh`, `test/marathon-monitor.sh`, relevant receipt suites, and manual clock-controlled receipts. Red controls: phase transition resets the clock; seventh check; terminal exit leaves observer alive; heartbeat-only activity falsely counts as progress; stale receipt from another run; missing data falsely reports success.
4. Only then implement the narrow continuation handoff if still required. Manually falsify mismatched harness SHA, surviving descendant, changed state root, exhausted budget, missing QA and fresh-token budget reset. Reuse Jog semantics without routing marathon chains through a new Jog executor.
5. Verify in disposable full clones; commit manual provenance. No new suite or gate machinery (`AGENTS.md:142`). Observation rollback is disabling its flag. Continuation is **Costly** until proven: rollback means stop, retain evidence and park; selecting the prior harness never rolls back product commits automatically.

**[Nit] Skip — unsupported guarantees.** No guaranteed completion, immediate notification during host failure, persistent skill execution after caller termination, or guaranteed chat delivery. SIGKILL/host failure already exceed the driver’s reporting guarantee (`utils/py/marathon_drive.py:3584`). Choose and document the supported notification channel.

**RECOMMENDATION:** Ship bounded observation and repair-to-PR procedure first; enable unmerged-PR continuation only after the exact-SHA, ownership and shared-budget handoff is independently demonstrated.
