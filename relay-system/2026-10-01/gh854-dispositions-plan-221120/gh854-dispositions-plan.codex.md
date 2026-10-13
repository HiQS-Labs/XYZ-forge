**NO FIRSTHAND VERIFICATION CITED** — treat conclusions as conditional (codex's answer carries an unsupported [Pass]/verified/confirmed-style claim with no quoted span or file:line citation nearby, despite the consult PREAMBLE asking advisors to cite evidence.)

> **ATTESTATION**
> Model: gpt-6.1-sol
> Provider: openai
> Sandbox: read-only

Reading additional input from stdin...
2026-10-02T05:11:22.318004Z  WARN codex_skills::interface: ignoring interface.icon_small: icon path with '..' must resolve under plugin assets/
2026-10-02T05:11:22.318030Z  WARN codex_skills::interface: ignoring interface.icon_large: icon path with '..' must resolve under plugin assets/
2026-10-02T05:11:22.334354Z  WARN codex_core::agents_md: project doc exceeds remaining budget; truncating path=file:///private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-16535-02sbwo67/AGENTS.md remaining_bytes=32768
OpenAI Codex v0.159.1
--------
workdir: /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-16535-02sbwo67
model: gpt-6.1-sol
provider: openai
approval: never
sandbox: read-only
reasoning effort: medium
reasoning summaries: none
session id: 01a0fb06-2ed5-7ef2-82cd-6b3e9defbaa7
--------
user
You are an INDEPENDENT advisor in a one-shot cross-model consult. Another model is answering the SAME question separately and a coordinator will reconcile both answers, so give your own honest, specific read — do not hedge toward a consensus you cannot see. Read any repo files the question references (cite file:line). Respond with: (1) a short direct ANSWER; (2) graded FINDINGS — [Blocker]/[Should]/[Nit]/[Pass] — where applicable; (3) a one-line RECOMMENDATION. You are ADVISORY ONLY: output your analysis as text; do not rely on writing files (you are running in a throwaway copy).

=== CONSULT QUESTION ===
Review this narrow operator-approved disposition for XYZ-forge #854. Advisory only: no mutations, tests, git writes, issue changes. Assess concrete implementation omissions; do not re-litigate the approved priority decision or propose new test machinery.
Current base development1b40d57c36c70eb045341ec95403de93ba056b92. Operator approved separate deferred issues and executing the dispositions after source-grounded triangulation. #916 live relay historical exit6, #917 install registry15/16, #918 domain oracle16pass1fail are now deferred with explicit real-blocker triggers. #909 completion writer actual record loss fixed by landed#910: preserve its regression suite.
Plan: remove only registry-lock-concurrency.sh and gh-gen4-phase1-domain-oracles.sh from validate.sh TESTS; add existing gh306 EXEMPT entries with issue references; retain both suite files and runtime modules byte-for-byte. Remove retired oracle from utils/ci-route.sh SUBSYSTEM_TESTS_ate so subsystem membership remains valid; targeted manual bash test/<suite> still available. Remove registry-lock-concurrency from ci.yml Ubuntu --skip because unregistered skip names are invalid. Update now-false ci-local.sh comments and test/ci-workflow.sh expectation that installer suite necessarily runs locally; remove obsolete assertion, not new guard. Check gh379 canary suite for stale assumptions. No new suite, runner, stage, helper, runtime fix, Small-list edits. Existing RELAY_SELF_SUFFICIENCY_SKIP=1 makes future local qualifying runs match #836 D2 wrappers; directvalidate defaults remain unchanged.
Evidence: two normal relay pools failed, unexplained; completion lost1/16 with exits0 repairedflock; registry diagnostic15/16 suppressed failure details; oracle hashes shared clone while other suites mutate and discards detail. Exact historical registry/relay/oracle causes remain unproven; this change neither resolves nor claims them harmless. Deferred issues remain open. #854 hosted3/3, local1/3 unchanged; #853 quiet interval not discharged.
Verification: existing gh306 red control by temporarily omitting new exemptions then restore saved backup; focused gh306, ci-workflow, gh379 and ci-route suite; manual exact registry delta410->408, retained files/runtime unchanged and Small unchanged. Run in disposable full clone, serial on host; committed provenance. Independent plan/final QA before one full task-branch push gate, no automatic retry loop. Runtime-fix previous merge authority covered#910 only; prepare readyPR, operator approval at landing. Then two fresh development4-wide zero-retry runs, stoponfailure/drift; taskbranch gate doesn'tcount. Full Oct8audit remainsmanualonly. Easy to reverse: restore entries, exemption changes, ATE list and canary skip coherently in one revert; no data deletion/migration. Inspect relevant current source if helpful. Return concrete blockers and optional/outofscope distinctly.

hook: SessionStart
hook: SessionStart Completed
codex
I’ll check the current source for omissions in the approved disposition, without running tests or changing files.
exec
/bin/zsh -lc 'pwd; cat ROUTER.md; cat GUIDING-PRINCIPLES.md' in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-16535-02sbwo67
 succeeded in 0ms:
/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-16535-02sbwo67
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

exec
/bin/zsh -lc "cat /Users/noelsaw/.codex/skills/swe/SKILL.md; rg -n 'registry-lock-concurrency|gh-gen4-phase1-domain-oracles|RELAY_SELF_SUFFICIENCY_SKIP|installer|gh379|EXEMPT' validate.sh ci-local.sh .github/workflows/ci.yml test/ci-workflow.sh test/gh306-registry-bidirectional.sh utils/ci-route.sh; rg --files test | rg 'gh379|ci-route'; git rev-parse HEAD" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-16535-02sbwo67
 succeeded in 3963ms:
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
test/gh306-registry-bidirectional.sh:47:EXEMPT=(
test/gh306-registry-bidirectional.sh:74:    for e in "${EXEMPT[@]}"; do [ "$e" = "$name" ] && ex=1; done
test/gh306-registry-bidirectional.sh:132:for e in "${EXEMPT[@]}"; do
test/gh306-registry-bidirectional.sh:142:for e in "${EXEMPT[@]}"; do
utils/ci-route.sh:28:SUBSYSTEM_TESTS_ate="ate-run-variations.sh gh298-ate-gen4-ci-smoke.sh gh-gen4-phase1-domain-oracles.sh gh-gen4-phase2-adaptive-ate.sh gh-gen4-phase3-fuzz-engine.sh gh-gen4-phase4-repro-synth.sh gh-gen4-phase5-campaign.sh gh478-runaway-guard.sh gh712-jev-triage.sh synthetic/gh102-telemetry-schema.sh gh142-ate-exit-contract.sh"
ci-local.sh:26:# `registry-lock-concurrency.sh` — the workflow's own comment says that suite "passes locally" and
ci-local.sh:261:  # It used to mirror CI's, including `registry-lock-concurrency.sh`. That suite's own skip comment
ci-local.sh:404:  RELAY_SELF_SUFFICIENCY_SKIP=1 step "validate.sh suite" validate_suite
test/ci-workflow.sh:414:  # the wrong invariant: `registry-lock-concurrency.sh` is skipped in CI for a contended-Linux-runner
test/ci-workflow.sh:429:  if grep -qF '"registry-lock-concurrency.sh"' "$CI_LOCAL"; then
test/ci-workflow.sh:430:    fail "GH-509: ci-local.sh skips registry-lock-concurrency.sh — that suite PASSES on macOS and is skipped in CI only for a contended-Linux flake; local must not imitate a platform we do not ship to"
test/ci-workflow.sh:432:    pass "ci-local.sh runs registry-lock-concurrency.sh (skipped in CI for a Linux-only flake)"
.github/workflows/ci.yml:194:          RELAY_SELF_SUFFICIENCY_SKIP: "1"
.github/workflows/ci.yml:408:          RELAY_SELF_SUFFICIENCY_SKIP: "1"
.github/workflows/ci.yml:452:      # bug in any of them. Only registry-lock-concurrency.sh (GH-72, a documented 16-concurrent-writer
.github/workflows/ci.yml:485:      # test/gh379-canary-uses-validate.sh asserts all of this, selector by selector.
.github/workflows/ci.yml:489:          RELAY_SELF_SUFFICIENCY_SKIP: "1"
.github/workflows/ci.yml:494:            --skip registry-lock-concurrency.sh \
validate.sh:140:  # the EXEMPT list in test/gh306-registry-bidirectional.sh. Do not re-register them here.
validate.sh:256:  "gh379-claude-builder-diagnosis.sh" # GH-379 (Claude builder failure diagnostics surface in ESCALATION.md)
validate.sh:295:  "gh379-canary-uses-validate.sh"      # GH-379 (the canary CALLS validate.sh; it must never re-implement the runner)
validate.sh:549:  "gh678-installer-live-links.sh" # GH-678 (no installer replaces a live symlink it does not own; dangling still cleaned; sandboxed HOME)
validate.sh:647:  "registry-lock-concurrency.sh"
validate.sh:658:  # Live-agent test — auto-skips when agy/codex not on PATH or RELAY_SELF_SUFFICIENCY_SKIP=1.
validate.sh:659:  # Set RELAY_SELF_SUFFICIENCY_SKIP=1 in CI / keyless environments to avoid the real API call.
validate.sh:680:  "gh-gen4-phase1-domain-oracles.sh" # GH-299 Phase 1 (Gen 4 semantic domain oracles: zero-state, containment, idempotence, crash-recovery; +/- controls)
validate.sh:771:      [ $# -ge 2 ] || _err2 "--skip requires a suite name (e.g. --skip registry-lock-concurrency.sh)"
test/gh379-canary-uses-validate.sh
test/gh379-claude-builder-diagnosis.sh
test/ci-route.sh
git: warning: confstr() failed with code 5: couldn't get path of DARWIN_USER_TEMP_DIR; using /tmp instead
git: error: couldn't create cache file '/tmp/xcrun_db-1W0QuJ8H' (errno=Operation not permitted)
2026-10-01 22:11:39.325 xcodebuild[29988:202194409]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-10-01 22:11:39.928 xcodebuild[29988:202194336] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.
git: warning: confstr() failed with code 5: couldn't get path of DARWIN_USER_TEMP_DIR; using /tmp instead
git: error: couldn't create cache file '/tmp/xcrun_db-bJNTTUOR' (errno=Operation not permitted)
2026-10-01 22:11:40.725 xcodebuild[31669:202197143]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-10-01 22:11:40.970 xcodebuild[31669:202197080] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.
1b40d57c36c70eb045341ec95403de93ba056b92

codex
I’m using the SWE plan-review rubric for scope and proof. Graph tools are unavailable here, so I’m reading the shell/config sources directly. The checkout matches the stated base SHA.
exec
/bin/zsh -lc "nl -ba test/gh379-canary-uses-validate.sh; nl -ba test/gh306-registry-bidirectional.sh | sed -n '1,175p'; nl -ba test/ci-workflow.sh | sed -n '370,460p'; nl -ba ci-local.sh | sed -n '1,45p;245,300p;385,415p'; nl -ba .github/workflows/ci.yml | sed -n '442,512p'" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-16535-02sbwo67
 succeeded in 0ms:
     1	#!/usr/bin/env bash
     2	# GH-379 — the Ubuntu canary must CALL validate.sh, never reimplement it.
     3	#
     4	# WHY THIS SUITE EXISTS
     5	#
     6	# The canary's slowest step used to scrape the TESTS array out of validate.sh with sed/grep and run
     7	# its own serial for-loop, so it could carry three skips. Nothing detected that, because everything
     8	# still "ran tests" and the job still went green half the time. Three separate losses hid inside a
     9	# step that looked fine:
    10	#
    11	#   1. PARALLELISM. GH-528 measured 946.0s -> 184.3s at --parallel 8 with BYTE-IDENTICAL pass/fail
    12	#      sets. The hand-rolled loop was serial: 13m 14s, 88% of the job's wall, 100% of the repo's
    13	#      sampled runner-minute bill.
    14	#   2. THE CONTENTION-RETRY. validate.sh re-runs a pooled failure alone before believing it — the
    15	#      mechanism that separates a real red from contention. A bare for-loop has no such filter, so
    16	#      every flake read as a defect and every defect read as a possible flake.
    17	#   3. THREE NON-SHELL LANES. python:test_python_layer.py, clone-identity-invariant and
    18	#      gamma-poison-staleness-probe are NOT members of the TESTS array. A '.sh'-only scrape cannot
    19	#      see them, so they had never executed on Linux at all. That is the serious half: a coverage
    20	#      hole wearing the costume of a speed optimization.
    21	#
    22	# A comment in ci.yml saying "call validate.sh" would not have prevented any of it — the previous
    23	# loop also carried a confident comment. Only an assertion does, so these are assertions.
    24	#
    25	# THE NEGATIVE CONTROL that pins this suite: restore the scrape in ci.yml
    26	# (`sed -n '/^TESTS=(/,/^)/p' validate.sh`) and assertions 2 and 3 must go red. If they do not, this
    27	# suite is decorative and should be deleted rather than trusted.
    28	#
    29	# TWO HOUSE RULES THIS FILE OBEYS ON PURPOSE — do not "simplify" them back:
    30	#   * NO `eval` in the check helper. The `check "label" "shell string"` idiom common elsewhere in
    31	#     test/ trips security-scan.sh's `eval-unsanitized` rule. Here `check` takes a COMMAND and its
    32	#     arguments and runs them directly, so there is no second parse and nothing to sanitize.
    33	#   * NO piping a command into a quiet grep. GH-139 bans that shape under test/ (and counts it by
    34	#     static text scan, so even a comment containing it fails the guard) because a quiet grep exits
    35	#     at its first match, the writer then dies of SIGPIPE, and the result is nondeterministically
    36	#     red under `set -o pipefail`. Match against a here-string instead — that is what `matches` does.
    37	set -euo pipefail
    38	
    39	HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    40	REPO="$(cd "$HERE/.." && pwd)"
    41	. "$HERE/lib/fixture-guard.sh"
    42	require_forge_root validate.sh .github/workflows   # GH-708: forge-root only — witnessed skip in a vendored .xyz/
    43	WF="$REPO/.github/workflows/ci.yml"
    44	V="$REPO/validate.sh"
    45	
    46	PASS=0; FAIL=0
    47	ok()  { echo "  PASS: $*"; PASS=$((PASS + 1)); }
    48	bad() { echo "  FAIL: $*" >&2; FAIL=$((FAIL + 1)); }
    49	
    50	# check <label> <command> [args...] — runs the command directly. No eval, no re-parse.
    51	check() { local label="$1"; shift; if "$@"; then ok "$label"; else bad "$label"; fi; }
    52	# not <command> [args...] — inverts a check without needing a shell string.
    53	not()   { ! "$@"; }
    54	# matches <extended-regex> <text> — here-string, never a pipe (GH-139).
    55	matches()  { grep -qE -- "$1" <<<"$2"; }
    56	# fmatches <literal> <text> — same, fixed-string. Use this for anything containing regex
    57	# metacharacters or leading dashes; hand-escaping a flag name into an ERE is how the 2026-09-02
    58	# draft of the tier-selector check ended up vacuous.
    59	fmatches() { grep -qF -- "$1" <<<"$2"; }
    60	
    61	echo "== test: gh379-canary-uses-validate =="
    62	
    63	[ -f "$WF" ] || { bad "workflow missing at .github/workflows/ci.yml"; echo "  failed: $FAIL"; exit 1; }
    64	
    65	# ── 1. the canary invokes validate.sh, with an EXPLICIT concurrency mode ─────────────────────────
    66	# Explicit, not inherited: boundary-macos pins --sequential for exactly this reason (GH-544), and a
    67	# canary that inherits a default cannot say what it ran.
    68	check "canary invokes ./validate.sh with an explicit --parallel N" \
    69	  grep -qE '\./validate\.sh --parallel [0-9]+' "$WF"
    70	
    71	# ── 2. it does NOT reimplement the runner ────────────────────────────────────────────────────────
    72	# The exact shape that regressed: scraping the registry out of validate.sh's source.
    73	check "no CI step scrapes the TESTS array out of validate.sh" \
    74	  not grep -q "sed -n '/^TESTS=(/" "$WF"
    75	
    76	# The FULL-suite step specifically must not loop. The Fast Gate step (route=fast) still iterates a
    77	# short, hand-curated list, which is a different and defensible shape — it is a selected subset, not
    78	# a re-derivation of the registry. The FAST_TESTS block below guards that list instead.
    79	# NB: a naive awk range `/start/,/^      - name: /` terminates on its OWN first line, because the
    80	# step-name line matches both patterns — it captures one line and every assertion built on it passes
    81	# vacuously. Skip the opening line before looking for the next step.
    82	full_step="$(awk '/- name: Run validate.sh suite/{f=1; next} f && /^      - name: /{exit} f' "$WF")"
    83	# Guard the extraction itself. An awk range that captures nothing makes the next assertion vacuous —
    84	# which is the exact failure mode this file has already shipped once.
    85	check "the full-suite step was actually extracted (not an empty awk range)" \
    86	  matches 'validate\.sh' "$full_step"
    87	check "the FULL-suite step does not iterate suites itself" \
    88	  not matches 'bash "test/' "$full_step"
    89	
    90	# The Fast Gate's curated list is a SECOND registry that gh306-registry-bidirectional.sh does not
    91	# cover. A name that no longer exists on disk would silently shrink that lane.
    92	fast_body="$(awk '/FAST_TESTS=\(/{f=1;next} f&&/^ *\)/{exit} f' "$WF")"
    93	fast_list="$(grep -oE '"[a-zA-Z0-9._-]+\.sh"' <<<"$fast_body" | tr -d '"' || true)"
    94	check "the Fast Gate list was actually extracted (not an empty awk range)" \
    95	  test -n "$fast_list"
    96	# An empty extraction is not the only silent failure. The regex above only recognises QUOTED names,
    97	# so a valid-but-unquoted array entry is dropped without a word and every downstream assertion then
    98	# vouches for a list that is missing it. Count what the array body contains and require the parse to
    99	# account for all of it. (Codex review round 2, 2026-09-02.)
   100	# Strip a terminal backslash before counting: a legitimate `"a.sh" \` continuation would otherwise
   101	# count as a third field and fail the parity check on correct input. (Codex review round 3.)
   102	body_tokens="$(awk '{sub(/#.*/,""); sub(/\\[[:space:]]*$/,""); n+=NF} END{print n+0}' <<<"$fast_body")"
   103	parsed_tokens="$(grep -c . <<<"$fast_list" || true)"
   104	check "every Fast Gate array entry was parsed ($parsed_tokens parsed of $body_tokens in the array body)" \
   105	  test "$parsed_tokens" -eq "$body_tokens"
   106	gone=""
   107	while IFS= read -r t; do
   108	  [ -n "$t" ] || continue
   109	  [ -f "$REPO/test/$t" ] || gone="$gone $t"
   110	done <<<"$fast_list"
   111	check "every Fast Gate suite name still exists on disk (missing:${gone:- none})" test -z "$gone"
   112	
   113	# ── 3. the three non-shell lanes are actually REACHED ────────────────────────────────────────────
   114	# These live outside TESTS=(...), which is why a '.sh'-only scrape missed them, and running them on
   115	# Linux is the headline claim of GH-379.
   116	#
   117	# THE ASSERTION BELOW WAS VACUOUS UNTIL 2026-09-02, and Codex found it. It used to check only that
   118	# validate.sh still MENTIONS the three lane labels — which proves nothing about the canary, because
   119	# ownership is a property of validate.sh, not of how the canary calls it. Negative control at the
   120	# time: rewriting the canary command as `./validate.sh --parallel 6 --tier 1` — a mode that exits
   121	# long before any of the three lanes runs — left this suite at 23 pass, 0 fail.
   122	#
   123	# The lanes are tier-3 lanes. So the property that has to hold is TWO-part: validate.sh still owns
   124	# them, AND the canary's own command selects nothing narrower than tier 3. Anything that shrinks the
   125	# run set below the full registry breaks the coverage claim, so every selector is rejected by name.
   126	for lane in "python:test_python_layer.py" "clone-identity-invariant" "gamma-poison-staleness-probe"; do
   127	  check "validate.sh still owns the non-shell lane '$lane'" \
   128	    grep -Fq "$lane" "$V"
   129	done
   130	# THE GUARANTEE IS AN ALLOWLIST GRAMMAR OVER THE RESOLVED RUN BODY.
   131	#
   132	# Two earlier shapes failed here, and the second failure is the instructive one:
   133	#
   134	#   * A BLOCKLIST of narrowing selectors. Codex round 2: it missed --print-mode and --list, both of
   135	#     which exit before a suite runs. A list of ways to break a claim is never finished.
   136	#   * An allowlist grammar over text joined on SHELL backslash continuations. Codex round 3: the
   137	#     joiner understood `\` but not YAML. Switch the step's scalar from `run: |` to `run: >` and
   138	#     write the invocation on two un-backslashed lines, and YAML folds them into
   139	#     `./validate.sh --parallel 6 --tier 1` while the joiner captures only the first — so the
   140	#     grammar passed on a fragment it had never seen executed, and the lanes went unreached.
   141	#
   142	# So the command is now taken from the RESOLVED run scalar, and the scalar style is pinned besides.
   143	
   144	# (a) Pin the scalar style. A literal block (`run: |`) is the only style under which one physical
   145	# line is one command; every folding style makes text-level reasoning about this step unsound. This
   146	# assertion is unconditional and needs no YAML parser, so it holds even where PyYAML is absent.
   147	check "the canary step uses a LITERAL block scalar (run: |), not a folding one" \
   148	  matches '^        run: \|[[:space:]]*$' "$full_step"
   149	
   150	# (b) Resolve the run body. With PyYAML this is what the runner will actually execute — immune to
   151	# folding, quoting and continuation style alike. Without it, fall back to the literal-block text,
   152	# which (a) has just established is equivalent. The fallback is announced, never silent.
   153	run_body=""
   154	if python3 -c 'import yaml' >/dev/null 2>&1; then
   155	  # Scoped to the canary job and required to be UNIQUE. An earlier version scanned every job and
   156	  # took the FIRST step whose name merely started with the prefix, so a future second job with a
   157	  # similarly-named step could become a decoy: the renamed or narrowed real canary would go
   158	  # unchecked while run_body stayed non-empty and every assertion below passed. (Codex round 4.)
   159	  run_body="$(python3 - "$WF" <<'PY'
   160	import sys, yaml
   161	doc = yaml.safe_load(open(sys.argv[1]))
   162	job = (doc.get("jobs") or {}).get("canary-ubuntu")
   163	if job is None:
   164	    sys.stderr.write("no canary-ubuntu job\n"); raise SystemExit(1)
   165	hits = [st for st in (job.get("steps") or [])
   166	        if str(st.get("name", "")).startswith("Run validate.sh suite")]
   167	if len(hits) != 1:
   168	    sys.stderr.write("expected exactly 1 'Run validate.sh suite' step, found %d\n" % len(hits))
   169	    raise SystemExit(1)
   170	sys.stdout.write(hits[0].get("run", ""))
   171	PY
   172	)" || run_body=""
   173	  check "the canary step's run body resolved through a real YAML parser" test -n "$run_body"
   174	else
   175	  echo "  NOTE: PyYAML absent — falling back to the literal-block text pinned by (a)"
   176	  run_body="$(awk '/^        run: \|/{f=1;next} f && /^      - name: /{exit} f' <<<"$full_step")"
   177	fi
   178	
   179	# (c) Collapse shell continuations, drop comments and blanks. What survives is one logical command
   180	# per line — the unit the grammar is stated over.
   181	logical="$(awk '
   182	  { sub(/#.*/, ""); }
   183	  { line = $0
   184	    cont = (line ~ /\\[[:space:]]*$/)
   185	    sub(/\\[[:space:]]*$/, "", line)
   186	    gsub(/^[[:space:]]+|[[:space:]]+$/, "", line)
   187	    if (line != "") buf = (buf == "" ? line : buf " " line)
   188	    if (!cont && buf != "") { print buf; buf = "" } }
   189	  END { if (buf != "") print buf }' <<<"$run_body")"
   190	
   191	# (d) The WHOLE body is asserted, not just the line that mentions validate.sh. Codex round 3 was
   192	# explicit that finding one acceptable fragment is not execution proof: a second command appended
   193	# below could re-narrow the run and a fragment-scoped check would never look at it.
   194	n_cmds="$(grep -c . <<<"$logical" || true)"
   195	check "the canary step runs exactly 2 commands — the shell pin and the gate (found $n_cmds)" \
   196	  test "$n_cmds" -eq 2
   197	check "  the first is the shell pin" matches '^set -euo pipefail$' "$(head -1 <<<"$logical")"
   198	canary_cmd="$(tail -1 <<<"$logical")"
   199	check "  the second invokes the gate" matches '\./validate\.sh' "$canary_cmd"
   200	
   201	# (e) The grammar itself:  ./validate.sh --parallel <N> [--skip <NAME>]...
   202	grammar_bad=""; n_parallel=0
   203	# Deliberate word-splitting: this IS the tokenizer. `set --` is safe here; the suite takes no args.
   204	# shellcheck disable=SC2086
   205	set -- $canary_cmd
   206	[ "${1:-}" = "./validate.sh" ] || grammar_bad="entry point is '${1:-<empty>}', not ./validate.sh"
   207	shift || true
   208	while [ "$#" -gt 0 ]; do
   209	  case "$1" in
   210	    --parallel)
   211	      n_parallel=$((n_parallel + 1))
   212	      case "${2:-}" in
   213	        ''|*[!0-9]*) grammar_bad="$grammar_bad; --parallel wants an integer, got '${2:-<missing>}'" ;;
   214	      esac
   215	      shift 2 || break ;;
   216	    --skip)
   217	      [ -n "${2:-}" ] || { grammar_bad="$grammar_bad; --skip with no value"; break; }
   218	      shift 2 || break ;;
   219	    *)
   220	      grammar_bad="$grammar_bad; unexpected token '$1' — only --parallel N and --skip NAME are allowed, because every other flag can narrow or short-circuit the run"
   221	      shift ;;
   222	  esac
   223	done
   224	# EXACTLY one --parallel. Zero would inherit validate.sh's default, which is the thing pinning it
   225	# exists to prevent; more than one is ambiguous. Codex round 3 flagged that the loop counted neither.
   226	[ "$n_parallel" -eq 1 ] || grammar_bad="$grammar_bad; expected exactly one --parallel, found $n_parallel"
   227	check "the canary's command matches './validate.sh --parallel N [--skip NAME]...' exactly (bad:${grammar_bad:- none})" \
   228	  test -z "$grammar_bad"
   229	
   230	# Redundant with the grammar above, kept ONLY because it names the offender in the failure message.
   231	# The grammar is what makes the guarantee; do not delete it and keep just this list.
   232	for sel in --tier --subsystem --auto --paths-file --print-mode --list; do
   233	  # NB: `fmatches`, and NO stray `--`. The helper supplies its own end-of-options marker, so an
   234	  # extra one is swallowed as the PATTERN — which is exactly how the first draft of this loop
   235	  # searched for the string "--" instead of the flag and passed against every negative control.
   236	  check "the canary's command does not narrow or short-circuit the run with '$sel'" \
   237	    not fmatches "$sel" "$canary_cmd"
   238	done
   239	
   240	# ── 4. --skip is a real, guarded mechanism, not a comment ────────────────────────────────────────
   241	# Each of these is a property the old hand-rolled skip list did NOT have.
   242	check "validate.sh accepts --skip" grep -q -- '--skip)' "$V"
   243	
   244	rc=0; out="$(bash "$V" --skip 2>&1)" || rc=$?
   245	check "--skip with no value is a usage error (exit 2)" test "$rc" -eq 2
   246	check "  and says what it wanted" matches 'requires a suite name' "$out"
   247	
   248	rc=0; out="$(bash "$V" --skip definitely-not-a-suite.sh --sequential 2>&1)" || rc=$?
   249	check "an UNREGISTERED --skip name is refused (exit 2), so a typo cannot silently skip nothing" \
   250	  test "$rc" -eq 2
   251	check "  and the refusal explains why a no-op skip is dangerous" \
   252	  matches 'not in the registry' "$out"
   253	# NB: the marker MUST be one validate.sh actually emits. It prints "Running <suite>" in sequential
   254	# mode and "[parallel] <suite> rc=N" in the pool. An earlier draft of this assertion grepped for
   255	# `=== <suite> ===` — the format of the CI for-loop this whole issue DELETED — so it could never
   256	# fail and proved nothing. Checked against a real run before trusting it.
   257	check "  and no suite ran before the refusal" \
   258	  not matches '^(Running |\[parallel\] )' "$out"
   259	
   260	# The zero-test refusal has to FIRE, not merely exist as a string. Under bash 3.2 + `set -u` it once
   261	# died on an empty-array expansion one line early, so the message never printed while the exit code
   262	# stayed 1 — meaning an exit-code-only assertion could not tell the two apart. Skipping every
   263	# registered suite is the only input that exercises it.
   264	all_skips=()
   265	while IFS= read -r t; do all_skips+=(--skip "${t#test/}"); done < <(bash "$V" --list 2>/dev/null)
   266	check "the registry listed at least one suite to skip" test "${#all_skips[@]}" -gt 0
   267	rc=0; out="$(bash "$V" ${all_skips[@]+"${all_skips[@]}"} --sequential 2>&1)" || rc=$?
   268	check "skipping EVERY suite refuses (exit 1) rather than reporting a zero-test green" test "$rc" -eq 1
   269	check "  and it says so, instead of dying on an unbound variable" \
   270	  matches 'refusing a zero-test green' "$out"
   271	
   272	# ── 5. every skip the canary asks for is a registered suite ──────────────────────────────────────
   273	# Belt and braces with section 4: that proves the guard exists, this proves the workflow currently
   274	# satisfies it, so a rename in TESTS breaks the gate here rather than in CI.
   275	registry="$(bash "$V" --list 2>/dev/null || true)"
   276	skips="$(grep -oE -- '--skip [a-zA-Z0-9._-]+\.sh' "$WF" | awk '{print $2}' | sort -u || true)"
   277	if [ -z "$skips" ]; then
   278	  ok "no --skip entries in the workflow (nothing to validate)"
   279	else
   280	  missing=""
   281	  while IFS= read -r s; do
   282	    [ -n "$s" ] || continue
   283	    grep -qxF "test/$s" <<<"$registry" || missing="$missing $s"
   284	  done <<<"$skips"
   285	  check "every --skip name in ci.yml is a registered suite (drift:${missing:- none})" \
   286	    test -z "$missing"
   287	fi
   288	
   289	# ── 6. a skip can never be silent ────────────────────────────────────────────────────────────────
   290	check "validate.sh announces quarantined suites in the header" \
   291	  grep -q 'QUARANTINE (GH-379)' "$V"
   292	check "validate.sh repeats them in the summary" \
   293	  grep -q 'QUARANTINED (GH-379)' "$V"
   294	check "a quarantined run disqualifies itself as promotion evidence" \
   295	  grep -q 'NOT promotion evidence: a run that omits suites cannot qualify one' "$V"
   296	
   297	# ── 7. boundary-macos keeps its own pin (do not 'consistency-fix' it) ────────────────────────────
   298	# The macOS job is the promotion boundary and stays sequential on purpose (GH-528 Phase 2 unmet).
   299	# Asserted here so a future tidy-up of this file does not drag it along.
   300	check "boundary-macos still pins --sequential (it is the promotion boundary, not the canary)" \
   301	  grep -qE 'run: \./validate\.sh --sequential' "$WF"
   302	
   303	echo
   304	echo "  gh379-canary-uses-validate: $PASS pass, $FAIL fail"
   305	[ "$FAIL" -eq 0 ] || exit 1
   306	exit 0
     1	#!/usr/bin/env bash
     2	set -uo pipefail
     3	#
     4	# gh306-registry-bidirectional.sh — GH-306: the exists→registered half of the test registry
     5	# contract (the B3 root cause).
     6	#
     7	# gh35-test-tiers.sh section (4) pins ONE direction: every subsystem-registry suite must exist on
     8	# disk and appear in validate.sh's TESTS, and a registry naming a missing suite fails the listing
     9	# loudly. Nothing pinned the REVERSE direction — a runnable test/*.sh that exists on disk but is
    10	# NOT in TESTS runs only when invoked by hand, and the gate is green either way. That is exactly
    11	# how test/gh280-jog-marathon-adapter.sh shipped unregistered through PR #281 (review finding
    12	# B3; registered reactively in #296 / 4d83fc40). This suite makes the gate fail instead, and at
    13	# filing time it found TEN more green suites in the same hole (registered alongside it).
    14	#
    15	# WHAT THIS GUARD DOES NOT MATCH (GH-195: an audit that recognizes only one invocation shape
    16	# stops covering the same operation reached a different way):
    17	#   * suites under test/ SUBDIRECTORIES (synthetic/, fixtures/, lib/, baselines/) — a new
    18	#     test/<subdir>/suite.sh is invisible here. gh141-synthetic-registry.sh pins the synthetic/
    19	#     subset against the subsystem registry; the other subdirectories have no exists→registered
    20	#     pin as of GH-306;
    21	#   * executable NON-.sh files directly under test/ (a .py or extensionless runner);
    22	#   * subsystem-registry membership itself (that is gh35 section (4)'s direction, not this one);
    23	#   * exemption entries match by EXACT basename — renaming an exempt helper puts it back in the
    24	#     drift set (deliberate: an exemption is a name plus a reason, not a pattern).
    25	#
    26	# NOTE on style: older suites assert through an eval-based ok() helper (baselined under GH-64).
    27	# This suite deliberately uses plain if-blocks instead — new code adds no new eval surface, so
    28	# there is nothing to baseline.
    29	
    30	HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    31	REPO="$(cd "$HERE/.." && pwd)"
    32	V="$REPO/validate.sh"
    33	
    34	pass=0; fail=0
    35	ok(){ echo "  PASS: $1"; pass=$((pass+1)); }
    36	no(){ echo "  FAIL: $1" >&2; fail=$((fail+1)); }
    37	
    38	echo "== test: gh306-registry-bidirectional =="
    39	
    40	# ── the exemption list — short by contract; every entry carries its reason ───────────────────────
    41	# A suite goes here only when it CANNOT run in the gate, or was turned off by operator decision
    42	# (GH-831, 2026-09-25: non-core skill-text suites stop gating merges), with the reason written down. A suite
    43	# that merely lacks a registration is DRIFT, not an exemption — gh280 through #281 is what a
    44	# silent gap looks like. An exempt name that no longer exists on disk is itself drift (stale
    45	# exemptions are how this list rots into covering nothing), so the list is pinned in BOTH
    46	# directions below, like the registry it carves holes into.
    47	EXEMPT=(
    48	  "gh268-relay-cue-and-target-checks.sh" # GH-853 / AGENTS: observed pipefail false-red outside Small; turned off, file retained
    49	  "_setup.sh"                    # sourced by ~150 suites (shared tick fixture setup) — never executed directly
    50	  "_scratch-repo.sh"             # sourced hardened scratch-repo helper (GH-44) — never executed directly
    51	  "test-agy-standalone-repo.sh"  # legacy manual mock from the initial public release; no assertions, prints git status only
    52	  "test-agy-isolation.sh"        # pre-existing RED at GH-306 filing: stale expectation vs gh308-consult-guards.sh's Python-lane coverage of the same detector; needs its own fix lane, not a silent skip
    53	  "gh460-oracle.sh"              # GH-460 fuzz ORACLE, not a suite: takes one model name as $1 and answers for THAT input (0=contract holds, 8=setup/measure failure, 9=violation). The Gen4 engine calls it once per mutant; running it bare in the gate would resolve the empty string once and assert nothing. Its contract is exercised by gh460-fuzz-resolver-smoke.sh, which IS registered.
    54	  "gh578-ci-optimize-skill.sh"             # turned off by operator decision (GH-831): ci-optimize skill text, not harness code
    55	  "gh778-review-code-skill.sh"             # turned off by operator decision (GH-831): review-code skill text, not harness code
    56	  "gh798-status-skill.sh"                  # turned off by operator decision (GH-831): status skill text, not harness code
    57	  "gh779-radar-ci-health.sh"               # turned off by operator decision (GH-831): radar skill text, not harness code
    58	  "gh781-wam-radar-seed.sh"                # turned off by operator decision (GH-831): whack-a-mole skill text, not harness code
    59	  "gh615-start-task-reinforce.sh"          # turned off by operator decision (GH-831): start-task skill text, not harness code
    60	  "gh616-start-task-commensurate-envelope.sh" # turned off by operator decision (GH-831): start-task skill text, not harness code
    61	  "gh617-relay-xyz-commensurate-review.sh" # turned off by operator decision (GH-831): relay-xyz review-brief text, not harness code
    62	)
    63	
    64	# drift_of <test_dir> <tests_blob> — prints one basename per top-level *.sh directly inside
    65	# <test_dir> that appears nowhere in <tests_blob> and is not exempt. Pure function: reads one
    66	# directory and one string, prints names, touches nothing.
    67	drift_of() {
    68	  local tdir="$1" blob="$2" f name e ex
    69	  for f in "$tdir"/*.sh; do
    70	    [ -f "$f" ] || continue
    71	    name="${f##*/}"
    72	    grep -qF "\"$name\"" <<<"$blob" && continue
    73	    ex=0
    74	    for e in "${EXEMPT[@]}"; do [ "$e" = "$name" ] && ex=1; done
    75	    [ "$ex" = "1" ] && continue
    76	    printf '%s\n' "$name"
    77	  done
    78	}
    79	
    80	WORK="$(mktemp -d "${TMPDIR:-/tmp}/gh306-registry.XXXXXX")"
    81	[ -n "$WORK" ] && [ -d "$WORK" ] || { echo "mktemp failed" >&2; exit 1; }
    82	cleanup(){ [ -n "${WORK:-}" ] && [ -d "${WORK:-}" ] && rm -rf "$WORK"; }
    83	trap cleanup EXIT
    84	
    85	# GH-177/GH-1: every fixture path this suite passes around is proven to live under $WORK.
    86	. "$HERE/lib/fixture-guard.sh"
    87	require_forge_root validate.sh   # GH-708: forge-root only — witnessed skip in a vendored .xyz/
    88	fixture_guard_init "$WORK"
    89	
    90	# ── (1) the real check: no top-level suite ships unregistered ────────────────────────────────────
    91	tests_blob="$(sed -n '/^TESTS=(/,/^)/p' "$V")"
    92	if [ -n "$tests_blob" ]; then
    93	  ok "the TESTS array was extracted from validate.sh (non-empty blob)"
    94	else
    95	  no "the TESTS array was extracted from validate.sh (non-empty blob)"
    96	fi
    97	
    98	_real_drift="$(drift_of "$REPO/test" "$tests_blob")"
    99	if [ -z "$_real_drift" ]; then
   100	  ok "every top-level test/*.sh is in validate.sh's TESTS or explicitly exempt (drift: none)"
   101	else
   102	  no "top-level suite(s) on disk but registered nowhere and not exempt (the B3 shape, GH-306):"
   103	  printf '        %s\n' $_real_drift
   104	fi
   105	
   106	# The self-demonstration: THIS suite is itself a top-level test/*.sh, so it cannot be shipped
   107	# unregistered without tripping its own check — the guard closes the hole it arrived through.
   108	if grep -qF '"gh306-registry-bidirectional.sh"' <<<"$tests_blob"; then
   109	  ok "this suite itself is registered in TESTS (self-demonstrating — an unregistered guard is the exact failure it exists to catch)"
   110	else
   111	  no "this suite itself is registered in TESTS (self-demonstrating — an unregistered guard is the exact failure it exists to catch)"
   112	fi
   113	
   114	# ── (2) the other half of bidirectional: a TESTS entry with no file behind it ────────────────────
   115	# validate.sh's pool would fail at run time on a missing suite, but that red lands mid-gate and
   116	# reads as a suite failure; this names it as a REGISTRY failure before anything runs. The sed is
   117	# anchored to the LEADING quoted token of each line so quoted words inside entry comments
   118	# ("flake", "no dispatch") are not mistaken for suite names (found on the first run).
   119	_missing=""
   120	while IFS= read -r t; do
   121	  [ -n "$t" ] || continue
   122	  [ -f "$HERE/$t" ] || _missing="$_missing $t"
   123	done < <(sed -n 's/^[[:space:]]*"\([^"]*\)".*/\1/p' <<<"$tests_blob")
   124	if [ -z "$_missing" ]; then
   125	  ok "every TESTS entry exists on disk (missing: none)"
   126	else
   127	  no "every TESTS entry exists on disk (missing:$_missing)"
   128	fi
   129	
   130	# ── (3) the exemption list is pinned in both directions too ──────────────────────────────────────
   131	_stale=""
   132	for e in "${EXEMPT[@]}"; do
   133	  [ -f "$HERE/$e" ] || _stale="$_stale $e"
   134	done
   135	if [ -z "$_stale" ]; then
   136	  ok "every exemption names a file that still exists on disk (stale: none)"
   137	else
   138	  no "exemption entries name files that no longer exist (stale:$_stale) — the list is rotting into covering nothing"
   139	fi
   140	
   141	_declared=""
   142	for e in "${EXEMPT[@]}"; do
   143	  grep -qF "\"$e\"" <<<"$tests_blob" && _declared="$_declared $e"
   144	done
   145	if [ -z "$_declared" ]; then
   146	  ok "no exemption is ALSO registered in TESTS (double-listed: none — exempt means not in the gate)"
   147	else
   148	  no "exemption entries are ALSO registered in TESTS (double-listed:$_declared) — pick one: register the suite or keep the exemption"
   149	fi
   150	
   151	# ── (4) THE NEGATIVE CONTROL: the guard must fire on a ghost, and only on the ghost ───────────────
   152	# Fixture 1 is the #281 B3 replay in miniature: a test/ dir holding one registered stub, one
   153	# legitimately-exempt helper, and one ghost that exists on disk but is registered nowhere. The
   154	# drift report must name the ghost and ONLY the ghost.
   155	F1="$WORK/f1-ghost"; mkdir -p "$F1"
   156	require_fixture "$F1" "ghost fixture dir"
   157	printf '#!/usr/bin/env bash\nexit 0\n' > "$F1/registered-stub.sh"
   158	printf '# stub sourced by fixture suites — the _setup.sh exemption shape\n' > "$F1/_setup.sh"
   159	printf '#!/usr/bin/env bash\nexit 0\n' > "$F1/ghost-suite.sh"
   160	f1_blob='TESTS=(
   161	  "registered-stub.sh"
   162	)'
   163	_d="$(drift_of "$F1" "$f1_blob")"
   164	if [ "$_d" = "ghost-suite.sh" ]; then
   165	  ok "a ghost suite (on disk, unregistered, unexempted) is flagged BY NAME — the #281 B3 shape goes red"
   166	else
   167	  no "a ghost suite (on disk, unregistered, unexempted) is flagged BY NAME — the #281 B3 shape goes red (got: '${_d:-<empty>}')"
   168	fi
   169	if grep -qF 'registered-stub.sh' <<<"$_d"; then
   170	  no "the registered stub in the same dir is NOT flagged (got it in the drift report)"
   171	else
   172	  ok "  and the registered stub in the same dir is NOT flagged"
   173	fi
   174	if grep -qF '_setup.sh' <<<"$_d"; then
   175	  no "the exempt helper in the same dir is NOT flagged (got it in the drift report)"
   370	fi
   371	
   372	# ── ci-local.sh must not drift from the workflow it mirrors ──────────────────────────────────────
   373	# `ci-local.sh` reproduces this job step-for-step so the signal survives a metered/blocked Actions
   374	# account. A mirror with nothing pinning it to its original is the exact failure this repo keeps
   375	# paying for — frozen Bash twins, and a packaged tarball that staled the moment its source changed.
   376	# So pin the two things that would silently diverge and change WHICH tests run.
   377	CI_LOCAL="$ROOT/ci-local.sh"
   378	
   379	if [ -f "$CI_LOCAL" ]; then
   380	  # (1) INVERTED on 2026-09-02 (GH-379), and the inversion is the point.
   381	  #
   382	  # This used to require ci.yml and ci-local.sh to parse validate.sh's TESTS array with the SAME
   383	  # expression, so "the two cannot drift". That pinned the wrong invariant: it enforced parity
   384	  # between two hand-rolled copies of the runner instead of forbidding the copies. Both stayed in
   385	  # agreement and both stayed wrong — the workflow's copy was serial (13m 14s where the real gate
   386	  # takes ~4 min parallel), had no contention-retry, and its '.sh'-only regex could not see
   387	  # validate.sh's three non-shell lanes, which therefore never ran on Linux at all.
   388	  #
   389	  # The workflow now CALLS validate.sh. So the assertion is that it does not parse TESTS.
   390	  if grep -Fq "sed -n '/^TESTS=(/,/^)/p' validate.sh" "$WORKFLOW"; then
   391	    fail "GH-379: ci.yml parses validate.sh's TESTS again — it must CALL validate.sh, not re-derive its registry"
   392	  else
   393	    pass "ci.yml does not re-derive validate.sh's registry (it calls validate.sh — GH-379)"
   394	  fi
   395	
   396	  # ci-local.sh is the REMAINING copy of that pattern (see its own note near the TESTS parse). It is
   397	  # not converted here because it is the local promotion-evidence runner with its own semantics, and
   398	  # a 20KB rewrite does not belong in the change that fixed the workflow. Named rather than silently
   399	  # tolerated, so it is a tracked follow-up on GH-379 instead of a rediscovery six weeks from now.
   400	  # Three outcomes, not two. An earlier draft called `pass` on both branches, which meant a THIRD
   401	  # state — ci-local.sh rewritten to re-derive the registry some *other* way — also passed, and the
   402	  # "tracked follow-up" was prose rather than an assertion. Codex flagged it, 2026-09-02.
   403	  if grep -Fq "sed -n '/^TESTS=(/,/^)/p' validate.sh" "$CI_LOCAL"; then
   404	    pass "ci-local.sh still re-derives the registry via the KNOWN expression — tracked on GH-379, not a new defect"
   405	  elif grep -qE "TESTS=\\(|/\\^TESTS=" "$CI_LOCAL"; then
   406	    fail "ci-local.sh re-derives validate.sh's registry by some OTHER expression — a new copy of the runner, not the tracked one; call validate.sh instead (GH-379)"
   407	  else
   408	    pass "ci-local.sh no longer re-derives the registry at all (GH-379 follow-up landed)"
   409	  fi
   410	
   411	  # (2) The skip lists must now DIFFER, and this assertion was inverted on 2026-08-12 (GH-509).
   412	  #
   413	  # It previously required the two files to skip the SAME tests. Under the macOS reframe that pinned
   414	  # the wrong invariant: `registry-lock-concurrency.sh` is skipped in CI for a contended-Linux-runner
   415	  # flake, and the workflow's own comment says it "passes locally". Requiring local to skip it too
   416	  # discarded real signal about the platform we ship to, in order to imitate one we do not.
   417	  #
   418	  # Local must run MORE than hosted ubuntu, not the same.
   419	  # GH-379: the workflow now expresses its skips as validate.sh's `--skip <name>` rather than a
   420	  # quoted array member, so match either idiom. What matters is that BOTH still skip it — the
   421	  # intent (it already ran in the npm step; duplicate work, not lost coverage) is unchanged.
   422	  if { grep -qF '"acorn-extract.sh"' "$WORKFLOW" || grep -qE -- '--skip[[:space:]]+acorn-extract\.sh' "$WORKFLOW"; } \
   423	     && grep -qF '"acorn-extract.sh"' "$CI_LOCAL"; then
   424	    pass "both skip acorn-extract.sh (it already ran in the npm step — duplicate work, not lost coverage)"
   425	  else
   426	    fail "acorn-extract.sh skip drift — it is duplicate work in both files and should be skipped in both"
   427	  fi
   428	
   429	  if grep -qF '"registry-lock-concurrency.sh"' "$CI_LOCAL"; then
   430	    fail "GH-509: ci-local.sh skips registry-lock-concurrency.sh — that suite PASSES on macOS and is skipped in CI only for a contended-Linux flake; local must not imitate a platform we do not ship to"
   431	  else
   432	    pass "ci-local.sh runs registry-lock-concurrency.sh (skipped in CI for a Linux-only flake)"
   433	  fi
   434	
   435	  # (3) The honesty notice, also inverted. The old caveat warned that a green local run is not a green
   436	  # ubuntu run — true, but the less useful direction now: local IS the shipping platform. The limit
   437	  # worth pinning is that a local run is SELF-REPORTED, which is what the hosted macOS boundary buys
   438	  # out. If that caveat is edited away, the script starts implying it can qualify a promotion.
   439	  if grep -q "self-reported" "$CI_LOCAL" && grep -q "hosted macOS run" "$CI_LOCAL"; then
   440	    pass "ci-local.sh states the real limit: a local pass is self-reported and does not qualify a promotion"
   441	  else
   442	    fail "GH-509: ci-local.sh dropped its self-reported caveat — it now implies a local run can qualify a promotion"
   443	  fi
   444	else
   445	  skip "ci-local.sh not present; mirror-drift checks skipped"
   446	fi
   447	
   448	echo
   449	echo "Summary"
   450	echo "  passed: $PASS"
   451	echo "  failed: $FAIL"
   452	echo "  skipped: $SKIP"
   453	
   454	if [ "$FAIL" -gt 0 ]; then
   455	  exit 1
   456	fi
   457	
   458	exit 0
     1	#!/usr/bin/env bash
     2	# ci-local.sh — run the tier1 CI job on this machine, step for step.
     3	#
     4	# WHY THIS EXISTS: GitHub Actions is metered. Every push burned budget to learn things a laptop can
     5	# tell you for free, and when the budget ran out `gh pr checks` started reporting `fail` in 2 seconds
     6	# on every commit — not a test failure, but "the job was not started because recent account payments
     7	# have failed". A red check that means nothing is worse than no check, because a real break looks
     8	# identical. This runs the same steps locally so the signal keeps existing.
     9	#
    10	# It follows .github/workflows/ci.yml's job in ORDER and CONTENT, but NOT in coverage — see the
    11	# section below. test/ci-workflow.sh pins the parts that must not drift.
    12	#
    13	# ─────────────────────────────────────────────────────────────────────────────────────────────────
    14	# THIS RUNS ON THE PLATFORM WE SHIP TO. THE HOSTED UBUNTU JOB DOES NOT. (GH-509)
    15	# ─────────────────────────────────────────────────────────────────────────────────────────────────
    16	# XYZ is a local developer toolkit for macOS developers. Linux and Windows support are on the roadmap
    17	# and are not here yet. So the direction of the old caveat here — "a green local run does not mean a
    18	# green ubuntu run" — was true but pointed at the less useful risk. Reversed and stated properly:
    19	#
    20	#   * A green run HERE is the best evidence we have about what users experience, because your machine
    21	#     is the shipping platform with the real toolchain.
    22	#   * A green run on hosted UBUNTU says little. That job is an advisory portability canary; its red
    23	#     means "would not work on a platform we do not support yet", not "broken".
    24	#
    25	# This script therefore runs MORE than the hosted job, on purpose. It does not skip
    26	# `registry-lock-concurrency.sh` — the workflow's own comment says that suite "passes locally" and
    27	# flakes only under contended Linux CI, so skipping it here discarded real macOS signal to imitate a
    28	# machine no user has.
    29	#
    30	# THE HONEST LIMIT IS NOW ELSEWHERE, and it is not about platform. This run is SELF-REPORTED: it
    31	# proves someone ran the suite, not that they ran it on the code they are shipping. That is what the
    32	# hosted macOS boundary job buys — a clean machine, and evidence not produced by the claimant.
    33	# ─────────────────────────────────────────────────────────────────────────────────────────────────
    34	#
    35	# Usage:
    36	#   ./ci-local.sh              # every step (~15-20 min; the suite dominates)
    37	#   ./ci-local.sh --fast       # everything EXCEPT the full validate.sh suite (~1 min)
    38	#   ./ci-local.sh --base REF   # also run the frozen-twin guard against REF (CI does this on PRs only)
    39	#   ./ci-local.sh --probe      # GH-509: the UNCONFIGURED-MAC probe (see below)
    40	#
    41	# ── --probe: what a new adopter's machine actually looks like (GH-509 / GH-520) ──────────────────
    42	# Runs with `codex`, `agy` and `aider` stripped from PATH, simulating a Mac where XYZ has just been
    43	# installed and none of the agent CLIs are set up yet. That is a real audience, not a hypothetical:
    44	# GH-380 describes someone installing Claude Code specifically to run the swarm, with nothing else on
    45	# the box.
   245	npm_and_acorn() {
   246	  npm ci || return 1
   247	  bash test/acorn-extract.sh
   248	}
   249	
   250	# ── 9. the suite ─────────────────────────────────────────────────────────────────────────────────
   251	# TESTS is parsed out of validate.sh exactly the way the workflow parses it, so the two cannot drift
   252	# on WHICH tests run — only on the environment they run in.
   253	#
   254	# NOTE: `git config --global` is what CI does before this step, to supply the user identity and
   255	# init.defaultBranch that fixture-driven tests assume. That is deliberately NOT done here: a dev
   256	# machine already has both, and silently rewriting an operator's global git config is not something
   257	# a test runner should do. If a fixture test fails on a bare machine, set them yourself.
   258	validate_suite() {
   259	  # GH-509: THIS SKIP LIST IS DELIBERATELY SHORTER THAN THE WORKFLOW'S, and that is the point.
   260	  #
   261	  # It used to mirror CI's, including `registry-lock-concurrency.sh`. That suite's own skip comment
   262	  # in the workflow reads "flaky under CI load … PASSES LOCALLY" — it fails on a contended shared
   263	  # Linux runner, a machine no XYZ user will ever have. Skipping it here threw away real signal about
   264	  # the platform we actually ship to, in order to stay faithful to a platform we do not.
   265	  #
   266	  # Only ONE skip survives, and it is not a platform concession: acorn-extract.sh already ran in the
   267	  # npm step above, so running it again would be duplicated work rather than dropped coverage.
   268	  local skip_tests=(
   269	    "acorn-extract.sh"                # already run above (needs npm ci first) — duplicate, not dropped
   270	  )
   271	  local all_tests=() line t s skip rc=0
   272	  while IFS= read -r line; do
   273	    [ -n "$line" ] && all_tests+=("$line")
   274	  done < <(sed -n '/^TESTS=(/,/^)/p' validate.sh | grep -oE '"[^"]+\.sh"' | tr -d '"')
   275	
   276	  [ "${#all_tests[@]}" -gt 0 ] || { echo "  could not parse TESTS from validate.sh" >&2; return 1; }
   277	  echo "  ${#all_tests[@]} suites declared in validate.sh"
   278	
   279	  # GH-536: capture the transcript and a per-suite verdict list so the evidence record can carry an
   280	  # output hash and individual verdicts instead of a bare `result: green`.
   281	  #
   282	  # `tee -a` keeps the operator's live output intact — a 15-minute run that goes silent to build a
   283	  # log would be a bad trade. `${PIPESTATUS[0]}` is load-bearing: with a pipe, `$?` is tee's status,
   284	  # so a failing suite would look green. `set -o pipefail` is already on, but reading PIPESTATUS
   285	  # directly says which element is being tested rather than relying on a shell option set 150 lines
   286	  # away.
   287	  : > "$GATE_SUITE_LOG"
   288	  : > "$GATE_VERDICTS"
   289	  _one="${TMPDIR:-/tmp}/ci-local-onesuite-$$.log"   # GH-365: per-suite capture for telemetry bytes/hash
   290	  for t in "${all_tests[@]}"; do
   291	    skip=0
   292	    for s in "${skip_tests[@]}"; do [ "$t" = "$s" ] && { skip=1; break; }; done
   293	    [ "$skip" -eq 1 ] && { echo "SKIP (already run above): $t"; printf '%s\tskip\n' "$t" >> "$GATE_VERDICTS"; rt_emit suite stage "$t" "$(rt_now_ms)" "$(rt_now_ms)" 0 "verdict=skip-duplicate"; continue; }
   294	    echo "=== $t ===" | tee -a "$GATE_SUITE_LOG"
   295	    _s="$(rt_now_ms)"
   296	    # Two tees: the first APPENDS the shared transcript, the second writes the per-suite capture
   297	    # (truncated fresh). BSD tee does NOT permute options — the earlier single
   298	    # `tee "$_one" -a "$GATE_SUITE_LOG"` treated -a as a FILENAME (empirically confirmed:
   299	    # `printf hi | tee ./one -a ./two` leaves a file named '-a' in CWD), creating that stray file
   300	    # in the repo root on every suite. The GH-365 envelope's tree bracket caught it and refused
   385	if [ -n "$BASE" ]; then
   386	  step "frozen twin guard"          frozen_twin_guard
   387	else
   388	  printf '\n\033[33mSKIP: frozen twin guard — CI runs it on pull_request only. Pass --base <ref> to run it.\033[0m\n'
   389	fi
   390	step "npm ci + acorn-extract"       npm_and_acorn
   391	# GH-10/GH-1 + GH-365 step 1: the qualifying run gets the SAME envelope validate.sh uses, from
   392	# the ONE shared helper — harness-registry scratch (XYZ_HARNESS_DB) AND the identity bracket AND
   393	# the tree/worktree/lock bracket. Before GH-365, this run executed the registered suites with no
   394	# scratch envelope at all: harness_app.py writes landed in the TRACKED harnesses.db, the tree
   395	# went dirty, and gate-record.sh then refused to retain the record for exactly the run that
   396	# needed it. Fail closed if the helper is missing — never a second inline envelope.
   397	if [ "$FAST" -eq 0 ]; then
   398	  if [ ! -f "$HERE/test/lib/runner-envelope.sh" ]; then
   399	    echo "ci-local: test/lib/runner-envelope.sh is missing — the shared GH-365 runner envelope cannot be set up; refusing." >&2
   400	    exit 1
   401	  fi
   402	  . "$HERE/test/lib/runner-envelope.sh"
   403	  runner_envelope_begin "$HERE" "ci-local.sh" || exit 1
   404	  RELAY_SELF_SUFFICIENCY_SKIP=1 step "validate.sh suite" validate_suite
   405	  step "clone-identity invariant (GH-1)" ci_local_envelope_assert
   406	  runner_envelope_scrub
   407	fi
   408	
   409	# ── report ───────────────────────────────────────────────────────────────────────────────────────
   410	printf '\n\033[1m─── ci-local summary ───\033[0m\n'
   411	for s in "${PASSED[@]}"; do printf '  \033[32m+\033[0m %s\n' "$s"; done
   412	if [ "${#FAILED[@]}" -gt 0 ]; then
   413	  for s in "${FAILED[@]}"; do printf '  \033[31m-\033[0m %s\n' "$s"; done
   414	  printf '\n\033[31mci-local: %d step(s) failed\033[0m\n' "${#FAILED[@]}"
   415	  printf 'This ran on macOS — the platform XYZ ships to — so a failure here is a real defect for\n'
   442	      # GH-232: PR #231 ran the full ./validate.sh suite on ubuntu-latest for the first time and
   443	      # found ~12 failures, assumed to be Ubuntu-environment-only and scoped out of CI. Re-diagnosed
   444	      # directly against a real ubuntu:latest container (not guessed at from macOS): almost all were
   445	      # masked by two things, now both fixed — (1) marathon.sh/marathon-drive.sh (and dependents
   446	      # debug-mantra.sh/driver-lock.sh) used a BSD-only `sed -i ''` invocation that mis-parses under
   447	      # GNU sed; (2) driver-lock.sh/xyz-harness-hooks.sh stubbed CLAUDE_BIN/AGY_BIN but not
   448	      # CODEX_BIN — the actual default builder — so they only "passed" locally because a real `codex`
   449	      # binary happened to be on the developer's own PATH, masking the gap; ubuntu CI has no such
   450	      # binary. path-integrity.sh/archive-writers.sh/relay-file-seeding-visibility.sh/xyz-vendor.sh/
   451	      # hq.sh/relay-pkg-freshness.sh all passed cleanly once re-tested for real — no ubuntu-specific
   452	      # bug in any of them. Only registry-lock-concurrency.sh (GH-72, a documented 16-concurrent-writer
   453	      # lock-contention flake under CI load, unrelated to this issue) stays skipped.
   454	      # GH-379: this step CALLS validate.sh. It must never go back to iterating suites itself.
   455	      #
   456	      # It used to scrape the TESTS array out of validate.sh with sed/grep and run a serial
   457	      # for-loop, in order to carry the three skips below. That cost three things at once:
   458	      #   * PARALLELISM — GH-528 measured 946.0s -> 184.3s at --parallel 8 with byte-identical
   459	      #     pass/fail sets. The serial loop threw all of it away; the step measured 13m 14s, 88%
   460	      #     of this job's wall and 100% of the repo's sampled runner-minute bill.
   461	      #   * THE CONTENTION-RETRY — validate.sh re-runs a pooled failure alone before believing it,
   462	      #     which is what separates a real red from contention. The loop had no such filter.
   463	      #   * THREE NON-SHELL LANES — python:test_python_layer.py, clone-identity-invariant and
   464	      #     gamma-poison-staleness-probe live OUTSIDE the TESTS array, so a '.sh'-only scrape
   465	      #     could not see them. They had never run on Linux.
   466	      #
   467	      # The skips are now validate.sh's own --skip, which refuses an unregistered name, announces
   468	      # every skip in the header and the summary, and marks the run as not-promotion-evidence.
   469	      # A quarantine that cannot be typo'd into a no-op is the whole point.
   470	      #
   471	      # --parallel is PINNED explicitly, for the same reason boundary-macos pins --sequential: a
   472	      # future change to validate.sh's default must not silently change what this job runs.
   473	      #
   474	      # On the width, stated honestly because the first version of this comment was not: 6 is the
   475	      # POOL width, and validate.sh runs the serialized driver-lock lane as a concurrent background
   476	      # subshell alongside the pool (GH-42/GH-528), so peak concurrency is 6 + 1 = 7 suite processes
   477	      # on an 8-core runner, not 6. That still fits, but it is one core of headroom rather than two.
   478	      # 6 is a REASONED GUESS, not a measurement: GH-528's 5.1x came from a 10-core Mac and nothing
   479	      # has been timed on this runner. Revisit with an A/B of 4 vs 6 once the step has run a few
   480	      # times — the numbers will be in the job log, which is the whole reason for pinning a value
   481	      # that can be compared across runs. (Codex review, 2026-09-02.)
   482	      #
   483	      # No tier or path selector may be added here: the three non-shell lanes are tier-3 lanes, so
   484	      # narrowing the run set would silently retract this issue's headline coverage claim.
   485	      # test/gh379-canary-uses-validate.sh asserts all of this, selector by selector.
   486	      - name: Run validate.sh suite (minus a documented flaky test)
   487	        if: steps.route.outputs.route == 'full'
   488	        env:
   489	          RELAY_SELF_SUFFICIENCY_SKIP: "1"
   490	        run: |
   491	          set -euo pipefail
   492	          ./validate.sh --parallel 6 \
   493	            --skip acorn-extract.sh \
   494	            --skip registry-lock-concurrency.sh \
   495	            --skip pdda-repo-contract.sh
   496	
   497	      # GH-509 Phase 2 — the canary's verdict, written where a human and a script can both find it.
   498	      #
   499	      # `if: always()` because the whole point is to report when an EARLIER step failed; without it
   500	      # this step is skipped in exactly the case it exists for. `job.status` is the aggregate of the
   501	      # steps above, so this reads the outcome rather than re-deriving it.
   502	      #
   503	      # The line is deliberately greppable and deliberately does NOT say "failed" or "error": on this
   504	      # platform those words are wrong. This job reports on an operating system we do not ship to yet.
   505	      - name: Portability canary verdict
   506	        if: always()
   507	        run: |
   508	          set -euo pipefail
   509	          if [ "${{ job.status }}" = "success" ]; then
   510	            verdict="PORTABILITY-CANARY: green"
   511	            detail="No Linux portability drift detected. This says nothing about macOS, which is what we ship."
   512	          else

exec
/bin/zsh -lc "nl -ba test/gh379-canary-uses-validate.sh | sed -n '240,340p'; nl -ba test/gh306-registry-bidirectional.sh | sed -n '20,165p'; nl -ba test/ci-workflow.sh | sed -n '395,445p'; nl -ba test/ci-route.sh | sed -n '1,200p'; rg -n 'registry-lock-concurrency|gh-gen4-phase1-domain-oracles' --glob '"'!releases.sql'"' --glob '"'!CHANGELOG.md'"' --glob '"'!harnesses.sql'"' .github githooks test utils ci-local.sh validate.sh ROUTER.md; nl -ba validate.sh | sed -n '635,690p;755,778p;890,924p'" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-16535-02sbwo67
 succeeded in 0ms:
   240	# ── 4. --skip is a real, guarded mechanism, not a comment ────────────────────────────────────────
   241	# Each of these is a property the old hand-rolled skip list did NOT have.
   242	check "validate.sh accepts --skip" grep -q -- '--skip)' "$V"
   243	
   244	rc=0; out="$(bash "$V" --skip 2>&1)" || rc=$?
   245	check "--skip with no value is a usage error (exit 2)" test "$rc" -eq 2
   246	check "  and says what it wanted" matches 'requires a suite name' "$out"
   247	
   248	rc=0; out="$(bash "$V" --skip definitely-not-a-suite.sh --sequential 2>&1)" || rc=$?
   249	check "an UNREGISTERED --skip name is refused (exit 2), so a typo cannot silently skip nothing" \
   250	  test "$rc" -eq 2
   251	check "  and the refusal explains why a no-op skip is dangerous" \
   252	  matches 'not in the registry' "$out"
   253	# NB: the marker MUST be one validate.sh actually emits. It prints "Running <suite>" in sequential
   254	# mode and "[parallel] <suite> rc=N" in the pool. An earlier draft of this assertion grepped for
   255	# `=== <suite> ===` — the format of the CI for-loop this whole issue DELETED — so it could never
   256	# fail and proved nothing. Checked against a real run before trusting it.
   257	check "  and no suite ran before the refusal" \
   258	  not matches '^(Running |\[parallel\] )' "$out"
   259	
   260	# The zero-test refusal has to FIRE, not merely exist as a string. Under bash 3.2 + `set -u` it once
   261	# died on an empty-array expansion one line early, so the message never printed while the exit code
   262	# stayed 1 — meaning an exit-code-only assertion could not tell the two apart. Skipping every
   263	# registered suite is the only input that exercises it.
   264	all_skips=()
   265	while IFS= read -r t; do all_skips+=(--skip "${t#test/}"); done < <(bash "$V" --list 2>/dev/null)
   266	check "the registry listed at least one suite to skip" test "${#all_skips[@]}" -gt 0
   267	rc=0; out="$(bash "$V" ${all_skips[@]+"${all_skips[@]}"} --sequential 2>&1)" || rc=$?
   268	check "skipping EVERY suite refuses (exit 1) rather than reporting a zero-test green" test "$rc" -eq 1
   269	check "  and it says so, instead of dying on an unbound variable" \
   270	  matches 'refusing a zero-test green' "$out"
   271	
   272	# ── 5. every skip the canary asks for is a registered suite ──────────────────────────────────────
   273	# Belt and braces with section 4: that proves the guard exists, this proves the workflow currently
   274	# satisfies it, so a rename in TESTS breaks the gate here rather than in CI.
   275	registry="$(bash "$V" --list 2>/dev/null || true)"
   276	skips="$(grep -oE -- '--skip [a-zA-Z0-9._-]+\.sh' "$WF" | awk '{print $2}' | sort -u || true)"
   277	if [ -z "$skips" ]; then
   278	  ok "no --skip entries in the workflow (nothing to validate)"
   279	else
   280	  missing=""
   281	  while IFS= read -r s; do
   282	    [ -n "$s" ] || continue
   283	    grep -qxF "test/$s" <<<"$registry" || missing="$missing $s"
   284	  done <<<"$skips"
   285	  check "every --skip name in ci.yml is a registered suite (drift:${missing:- none})" \
   286	    test -z "$missing"
   287	fi
   288	
   289	# ── 6. a skip can never be silent ────────────────────────────────────────────────────────────────
   290	check "validate.sh announces quarantined suites in the header" \
   291	  grep -q 'QUARANTINE (GH-379)' "$V"
   292	check "validate.sh repeats them in the summary" \
   293	  grep -q 'QUARANTINED (GH-379)' "$V"
   294	check "a quarantined run disqualifies itself as promotion evidence" \
   295	  grep -q 'NOT promotion evidence: a run that omits suites cannot qualify one' "$V"
   296	
   297	# ── 7. boundary-macos keeps its own pin (do not 'consistency-fix' it) ────────────────────────────
   298	# The macOS job is the promotion boundary and stays sequential on purpose (GH-528 Phase 2 unmet).
   299	# Asserted here so a future tidy-up of this file does not drag it along.
   300	check "boundary-macos still pins --sequential (it is the promotion boundary, not the canary)" \
   301	  grep -qE 'run: \./validate\.sh --sequential' "$WF"
   302	
   303	echo
   304	echo "  gh379-canary-uses-validate: $PASS pass, $FAIL fail"
   305	[ "$FAIL" -eq 0 ] || exit 1
   306	exit 0
    20	#     pin as of GH-306;
    21	#   * executable NON-.sh files directly under test/ (a .py or extensionless runner);
    22	#   * subsystem-registry membership itself (that is gh35 section (4)'s direction, not this one);
    23	#   * exemption entries match by EXACT basename — renaming an exempt helper puts it back in the
    24	#     drift set (deliberate: an exemption is a name plus a reason, not a pattern).
    25	#
    26	# NOTE on style: older suites assert through an eval-based ok() helper (baselined under GH-64).
    27	# This suite deliberately uses plain if-blocks instead — new code adds no new eval surface, so
    28	# there is nothing to baseline.
    29	
    30	HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    31	REPO="$(cd "$HERE/.." && pwd)"
    32	V="$REPO/validate.sh"
    33	
    34	pass=0; fail=0
    35	ok(){ echo "  PASS: $1"; pass=$((pass+1)); }
    36	no(){ echo "  FAIL: $1" >&2; fail=$((fail+1)); }
    37	
    38	echo "== test: gh306-registry-bidirectional =="
    39	
    40	# ── the exemption list — short by contract; every entry carries its reason ───────────────────────
    41	# A suite goes here only when it CANNOT run in the gate, or was turned off by operator decision
    42	# (GH-831, 2026-09-25: non-core skill-text suites stop gating merges), with the reason written down. A suite
    43	# that merely lacks a registration is DRIFT, not an exemption — gh280 through #281 is what a
    44	# silent gap looks like. An exempt name that no longer exists on disk is itself drift (stale
    45	# exemptions are how this list rots into covering nothing), so the list is pinned in BOTH
    46	# directions below, like the registry it carves holes into.
    47	EXEMPT=(
    48	  "gh268-relay-cue-and-target-checks.sh" # GH-853 / AGENTS: observed pipefail false-red outside Small; turned off, file retained
    49	  "_setup.sh"                    # sourced by ~150 suites (shared tick fixture setup) — never executed directly
    50	  "_scratch-repo.sh"             # sourced hardened scratch-repo helper (GH-44) — never executed directly
    51	  "test-agy-standalone-repo.sh"  # legacy manual mock from the initial public release; no assertions, prints git status only
    52	  "test-agy-isolation.sh"        # pre-existing RED at GH-306 filing: stale expectation vs gh308-consult-guards.sh's Python-lane coverage of the same detector; needs its own fix lane, not a silent skip
    53	  "gh460-oracle.sh"              # GH-460 fuzz ORACLE, not a suite: takes one model name as $1 and answers for THAT input (0=contract holds, 8=setup/measure failure, 9=violation). The Gen4 engine calls it once per mutant; running it bare in the gate would resolve the empty string once and assert nothing. Its contract is exercised by gh460-fuzz-resolver-smoke.sh, which IS registered.
    54	  "gh578-ci-optimize-skill.sh"             # turned off by operator decision (GH-831): ci-optimize skill text, not harness code
    55	  "gh778-review-code-skill.sh"             # turned off by operator decision (GH-831): review-code skill text, not harness code
    56	  "gh798-status-skill.sh"                  # turned off by operator decision (GH-831): status skill text, not harness code
    57	  "gh779-radar-ci-health.sh"               # turned off by operator decision (GH-831): radar skill text, not harness code
    58	  "gh781-wam-radar-seed.sh"                # turned off by operator decision (GH-831): whack-a-mole skill text, not harness code
    59	  "gh615-start-task-reinforce.sh"          # turned off by operator decision (GH-831): start-task skill text, not harness code
    60	  "gh616-start-task-commensurate-envelope.sh" # turned off by operator decision (GH-831): start-task skill text, not harness code
    61	  "gh617-relay-xyz-commensurate-review.sh" # turned off by operator decision (GH-831): relay-xyz review-brief text, not harness code
    62	)
    63	
    64	# drift_of <test_dir> <tests_blob> — prints one basename per top-level *.sh directly inside
    65	# <test_dir> that appears nowhere in <tests_blob> and is not exempt. Pure function: reads one
    66	# directory and one string, prints names, touches nothing.
    67	drift_of() {
    68	  local tdir="$1" blob="$2" f name e ex
    69	  for f in "$tdir"/*.sh; do
    70	    [ -f "$f" ] || continue
    71	    name="${f##*/}"
    72	    grep -qF "\"$name\"" <<<"$blob" && continue
    73	    ex=0
    74	    for e in "${EXEMPT[@]}"; do [ "$e" = "$name" ] && ex=1; done
    75	    [ "$ex" = "1" ] && continue
    76	    printf '%s\n' "$name"
    77	  done
    78	}
    79	
    80	WORK="$(mktemp -d "${TMPDIR:-/tmp}/gh306-registry.XXXXXX")"
    81	[ -n "$WORK" ] && [ -d "$WORK" ] || { echo "mktemp failed" >&2; exit 1; }
    82	cleanup(){ [ -n "${WORK:-}" ] && [ -d "${WORK:-}" ] && rm -rf "$WORK"; }
    83	trap cleanup EXIT
    84	
    85	# GH-177/GH-1: every fixture path this suite passes around is proven to live under $WORK.
    86	. "$HERE/lib/fixture-guard.sh"
    87	require_forge_root validate.sh   # GH-708: forge-root only — witnessed skip in a vendored .xyz/
    88	fixture_guard_init "$WORK"
    89	
    90	# ── (1) the real check: no top-level suite ships unregistered ────────────────────────────────────
    91	tests_blob="$(sed -n '/^TESTS=(/,/^)/p' "$V")"
    92	if [ -n "$tests_blob" ]; then
    93	  ok "the TESTS array was extracted from validate.sh (non-empty blob)"
    94	else
    95	  no "the TESTS array was extracted from validate.sh (non-empty blob)"
    96	fi
    97	
    98	_real_drift="$(drift_of "$REPO/test" "$tests_blob")"
    99	if [ -z "$_real_drift" ]; then
   100	  ok "every top-level test/*.sh is in validate.sh's TESTS or explicitly exempt (drift: none)"
   101	else
   102	  no "top-level suite(s) on disk but registered nowhere and not exempt (the B3 shape, GH-306):"
   103	  printf '        %s\n' $_real_drift
   104	fi
   105	
   106	# The self-demonstration: THIS suite is itself a top-level test/*.sh, so it cannot be shipped
   107	# unregistered without tripping its own check — the guard closes the hole it arrived through.
   108	if grep -qF '"gh306-registry-bidirectional.sh"' <<<"$tests_blob"; then
   109	  ok "this suite itself is registered in TESTS (self-demonstrating — an unregistered guard is the exact failure it exists to catch)"
   110	else
   111	  no "this suite itself is registered in TESTS (self-demonstrating — an unregistered guard is the exact failure it exists to catch)"
   112	fi
   113	
   114	# ── (2) the other half of bidirectional: a TESTS entry with no file behind it ────────────────────
   115	# validate.sh's pool would fail at run time on a missing suite, but that red lands mid-gate and
   116	# reads as a suite failure; this names it as a REGISTRY failure before anything runs. The sed is
   117	# anchored to the LEADING quoted token of each line so quoted words inside entry comments
   118	# ("flake", "no dispatch") are not mistaken for suite names (found on the first run).
   119	_missing=""
   120	while IFS= read -r t; do
   121	  [ -n "$t" ] || continue
   122	  [ -f "$HERE/$t" ] || _missing="$_missing $t"
   123	done < <(sed -n 's/^[[:space:]]*"\([^"]*\)".*/\1/p' <<<"$tests_blob")
   124	if [ -z "$_missing" ]; then
   125	  ok "every TESTS entry exists on disk (missing: none)"
   126	else
   127	  no "every TESTS entry exists on disk (missing:$_missing)"
   128	fi
   129	
   130	# ── (3) the exemption list is pinned in both directions too ──────────────────────────────────────
   131	_stale=""
   132	for e in "${EXEMPT[@]}"; do
   133	  [ -f "$HERE/$e" ] || _stale="$_stale $e"
   134	done
   135	if [ -z "$_stale" ]; then
   136	  ok "every exemption names a file that still exists on disk (stale: none)"
   137	else
   138	  no "exemption entries name files that no longer exist (stale:$_stale) — the list is rotting into covering nothing"
   139	fi
   140	
   141	_declared=""
   142	for e in "${EXEMPT[@]}"; do
   143	  grep -qF "\"$e\"" <<<"$tests_blob" && _declared="$_declared $e"
   144	done
   145	if [ -z "$_declared" ]; then
   146	  ok "no exemption is ALSO registered in TESTS (double-listed: none — exempt means not in the gate)"
   147	else
   148	  no "exemption entries are ALSO registered in TESTS (double-listed:$_declared) — pick one: register the suite or keep the exemption"
   149	fi
   150	
   151	# ── (4) THE NEGATIVE CONTROL: the guard must fire on a ghost, and only on the ghost ───────────────
   152	# Fixture 1 is the #281 B3 replay in miniature: a test/ dir holding one registered stub, one
   153	# legitimately-exempt helper, and one ghost that exists on disk but is registered nowhere. The
   154	# drift report must name the ghost and ONLY the ghost.
   155	F1="$WORK/f1-ghost"; mkdir -p "$F1"
   156	require_fixture "$F1" "ghost fixture dir"
   157	printf '#!/usr/bin/env bash\nexit 0\n' > "$F1/registered-stub.sh"
   158	printf '# stub sourced by fixture suites — the _setup.sh exemption shape\n' > "$F1/_setup.sh"
   159	printf '#!/usr/bin/env bash\nexit 0\n' > "$F1/ghost-suite.sh"
   160	f1_blob='TESTS=(
   161	  "registered-stub.sh"
   162	)'
   163	_d="$(drift_of "$F1" "$f1_blob")"
   164	if [ "$_d" = "ghost-suite.sh" ]; then
   165	  ok "a ghost suite (on disk, unregistered, unexempted) is flagged BY NAME — the #281 B3 shape goes red"
   395	
   396	  # ci-local.sh is the REMAINING copy of that pattern (see its own note near the TESTS parse). It is
   397	  # not converted here because it is the local promotion-evidence runner with its own semantics, and
   398	  # a 20KB rewrite does not belong in the change that fixed the workflow. Named rather than silently
   399	  # tolerated, so it is a tracked follow-up on GH-379 instead of a rediscovery six weeks from now.
   400	  # Three outcomes, not two. An earlier draft called `pass` on both branches, which meant a THIRD
   401	  # state — ci-local.sh rewritten to re-derive the registry some *other* way — also passed, and the
   402	  # "tracked follow-up" was prose rather than an assertion. Codex flagged it, 2026-09-02.
   403	  if grep -Fq "sed -n '/^TESTS=(/,/^)/p' validate.sh" "$CI_LOCAL"; then
   404	    pass "ci-local.sh still re-derives the registry via the KNOWN expression — tracked on GH-379, not a new defect"
   405	  elif grep -qE "TESTS=\\(|/\\^TESTS=" "$CI_LOCAL"; then
   406	    fail "ci-local.sh re-derives validate.sh's registry by some OTHER expression — a new copy of the runner, not the tracked one; call validate.sh instead (GH-379)"
   407	  else
   408	    pass "ci-local.sh no longer re-derives the registry at all (GH-379 follow-up landed)"
   409	  fi
   410	
   411	  # (2) The skip lists must now DIFFER, and this assertion was inverted on 2026-08-12 (GH-509).
   412	  #
   413	  # It previously required the two files to skip the SAME tests. Under the macOS reframe that pinned
   414	  # the wrong invariant: `registry-lock-concurrency.sh` is skipped in CI for a contended-Linux-runner
   415	  # flake, and the workflow's own comment says it "passes locally". Requiring local to skip it too
   416	  # discarded real signal about the platform we ship to, in order to imitate one we do not.
   417	  #
   418	  # Local must run MORE than hosted ubuntu, not the same.
   419	  # GH-379: the workflow now expresses its skips as validate.sh's `--skip <name>` rather than a
   420	  # quoted array member, so match either idiom. What matters is that BOTH still skip it — the
   421	  # intent (it already ran in the npm step; duplicate work, not lost coverage) is unchanged.
   422	  if { grep -qF '"acorn-extract.sh"' "$WORKFLOW" || grep -qE -- '--skip[[:space:]]+acorn-extract\.sh' "$WORKFLOW"; } \
   423	     && grep -qF '"acorn-extract.sh"' "$CI_LOCAL"; then
   424	    pass "both skip acorn-extract.sh (it already ran in the npm step — duplicate work, not lost coverage)"
   425	  else
   426	    fail "acorn-extract.sh skip drift — it is duplicate work in both files and should be skipped in both"
   427	  fi
   428	
   429	  if grep -qF '"registry-lock-concurrency.sh"' "$CI_LOCAL"; then
   430	    fail "GH-509: ci-local.sh skips registry-lock-concurrency.sh — that suite PASSES on macOS and is skipped in CI only for a contended-Linux flake; local must not imitate a platform we do not ship to"
   431	  else
   432	    pass "ci-local.sh runs registry-lock-concurrency.sh (skipped in CI for a Linux-only flake)"
   433	  fi
   434	
   435	  # (3) The honesty notice, also inverted. The old caveat warned that a green local run is not a green
   436	  # ubuntu run — true, but the less useful direction now: local IS the shipping platform. The limit
   437	  # worth pinning is that a local run is SELF-REPORTED, which is what the hosted macOS boundary buys
   438	  # out. If that caveat is edited away, the script starts implying it can qualify a promotion.
   439	  if grep -q "self-reported" "$CI_LOCAL" && grep -q "hosted macOS run" "$CI_LOCAL"; then
   440	    pass "ci-local.sh states the real limit: a local pass is self-reported and does not qualify a promotion"
   441	  else
   442	    fail "GH-509: ci-local.sh dropped its self-reported caveat — it now implies a local run can qualify a promotion"
   443	  fi
   444	else
   445	  skip "ci-local.sh not present; mirror-drift checks skipped"
     1	#!/usr/bin/env bash
     2	# GH-509: deterministic route selection for docs, fast PR, and full integration gates.
     3	source "$(dirname "$0")/_setup.sh" ci-route
     4	ROOT="$(cd "$(dirname "$0")/.." && pwd)"
     5	require_forge_root validate.sh ci-local.sh   # GH-708: forge-root only — witnessed skip in a vendored .xyz/
     6	ROUTER="$ROOT/utils/ci-route.sh"
     7	
     8	route() {
     9	  local event="$1"
    10	  shift
    11	  printf '%s\n' "$@" | bash "$ROUTER" "$event"
    12	}
    13	
    14	expect_route() {
    15	  local label="$1" event="$2" expected_route="$3" expected_pdda="$4"
    16	  shift 4
    17	  local out
    18	  out="$(route "$event" "$@")"
    19	  if grep -Fqx "route=$expected_route" <<<"$out" \
    20	    && grep -Fqx "pdda_needed=$expected_pdda" <<<"$out"; then
    21	    pass "$label"
    22	  else
    23	    fail "$label: $out"
    24	  fi
    25	}
    26	
    27	expect_route "markdown-only PR uses the docs gate" pull_request docs true README.md PROJECT/1-INBOX/NOTE.md
    28	expect_route "ordinary code-only PR uses the fast gate without PDDA" pull_request fast false utils/hq/hq.sh
    29	expect_route "mixed docs and ordinary code runs both fast tests and PDDA" pull_request fast true README.md utils/hq/hq.sh
    30	expect_route "Tick/event changes require the full pre-merge gate" pull_request full true src/events.js
    31	expect_route "relay containment changes require the full pre-merge gate" pull_request full true relay-automation/relay-turn-lib.sh
    32	expect_route "Python-authoritative twin changes require the full pre-merge gate" pull_request full true utils/py/relay_drive.py
    33	expect_route "worktree safety test changes require the full pre-merge gate" pull_request full true test/worktree-isolation.sh
    34	expect_route "CI workflow changes require the full pre-merge gate" pull_request full true .github/workflows/ci.yml
    35	# GH-35 moved PDDA tooling off the blanket-full list and into the Tier-2 subsystem registry
    36	# (issue #35, subsystem 6): the focused PDDA suites run instead of the whole pool. PDDA itself
    37	# still gates (pdda_needed=true). utils/pdda/** staying tier 3 was the pre-GH-35 posture.
    38	expect_route "PDDA implementation changes run the PDDA subsystem gate (GH-35)" pull_request fast true utils/pdda/pdda.sh
    39	expect_route "releases DB and dump files are docs surfaces (GH-831 D4; the releases gate before, GH-496)" pull_request docs true releases.sql releases.db
    40	expect_route "wave_reconcile changes run the PDDA subsystem gate (GH-496)" pull_request fast true utils/py/wave_reconcile.py
    41	shell_suffix=sh
    42	deleted_test="test/removed-regression.${shell_suffix}"
    43	expect_route "a deleted regression test fails closed into the full gate" pull_request full true "$deleted_test"
    44	# GH-509 Phase 3 relabelled this: a push is no longer unconditionally full. With NO paths it still
    45	# is, because zero paths is the fail-closed case — which is what this line actually exercises.
    46	expect_route "a push with no usable range fails closed into the full gate" push full true
    47	expect_route "scheduled runs remain the full fallback boundary" schedule full true
    48	
    49	out="$(route pull_request utils/hq/hq.sh)"
    50	grep -Fqx 'changed_tests=hq.sh' <<<"$out" \
    51	  && pass "fast routes include a directly matching changed-area test" \
    52	  || fail "fast route omitted its changed-area test: $out"
    53	
    54	out="$(printf '' | bash "$ROUTER" pull_request)"
    55	grep -Fqx 'route=full' <<<"$out" \
    56	  && pass "an empty PR diff fails closed into the full gate" \
    57	  || fail "empty PR diff did not fail closed: $out"
    58	
    59	set +e
    60	unknown_out="$(bash "$ROUTER" unsupported </dev/null 2>&1)"
    61	unknown_rc=$?
    62	set -e
    63	[[ "$unknown_rc" -eq 2 && "$unknown_out" == *"unsupported event"* ]] \
    64	  && pass "unknown events fail loudly" \
    65	  || fail "unknown event result: rc=$unknown_rc out=$unknown_out"
    66	
    67	# ── GH-509 Phase 3: pushes are classified, not blanket-full ──────────────────────────────────────
    68	# 72% of the billed minutes were pushes to `development`, every one on the full route. They now
    69	# classify from their pushed range exactly as a PR classifies from its diff.
    70	expect_route "docs-only push uses the docs gate (was blanket full)" push docs true README.md
    71	expect_route "text documentation uses the docs gate" push docs true docs/guide.txt
    72	expect_route "AgentChorus skill instructions use the docs gate" push docs true skills/2-daily/agent-chorus/SKILL.md
    73	# GH-28 follow-up: consult.sh always writes .txt sidecars (NO-CITATION.txt, PROVENANCE.txt,
    74	# DEGRADED-SINGLE-MODEL.txt) alongside each relay-system/ transcript. Before this, a lone sidecar
    75	# fell through to the catch-all `docs_only=false` branch, forcing a transcript-only push onto the
    76	# full 6-minute local gate instead of the ~2-minute docs gate — observed directly on 2026-08-18.
    77	expect_route "a relay-system .txt sidecar alone uses the docs gate" push docs true "relay-system/2026-08-18/run/NO-CITATION.txt"
    78	expect_route "a relay-system transcript plus its .txt sidecar both use the docs gate" push docs true "relay-system/2026-08-18/run/consult.codex.md" "relay-system/2026-08-18/run/PROVENANCE.txt"
    79	expect_route "ordinary code-only push uses the fast gate" push fast false utils/hq/hq.sh
    80	expect_route "a push touching the kernel still fails closed to full" push full true src/events.js
    81	expect_route "a push touching relay containment still fails closed to full" push full true relay-automation/relay-turn-lib.sh
    82	
    83	# The trigger that must NOT be routed. A manual dispatch is someone asking for the whole gate;
    84	# answering with a routed subset answers a different question than the one asked.
    85	out="$(printf '%s\n' README.md | bash "$ROUTER" workflow_dispatch)"
    86	grep -Fqx 'route=full' <<<"$out" \
    87	  && pass "workflow_dispatch stays unconditionally full even for a docs-only path list" \
    88	  || fail "workflow_dispatch was routed away from full: $out"
    89	
    90	# ── GH-509: a RENAMED regression test must select full ───────────────────────────────────────────
    91	# This drives a real `git mv` through the exact command the workflow runs, because the defect lives
    92	# in the FLAG, not in the classifier. With git's default rename detection, `--name-only` prints only
    93	# the DESTINATION path — which still exists — so a renamed test reads as an ordinary changed file and
    94	# ci-route.sh's fail-closed branch for a vanished test is never reached. That branch's comment says
    95	# "deleted/renamed"; before this flag it only ever saw deletions.
    96	#
    97	# Asserting on ci-route.sh alone could not catch it: the classifier behaves correctly for whatever
    98	# paths it is handed. The bug is in WHICH paths it is handed.
    99	RENAME_REPO="$WORK/rename-fixture"
   100	git init -q "$RENAME_REPO"
   101	git -C "$RENAME_REPO" config user.email t@t
   102	git -C "$RENAME_REPO" config user.name t
   103	mkdir -p "$RENAME_REPO/test"
   104	printf '#!/usr/bin/env bash\nexit 0\n' >"$RENAME_REPO/test/old-regression.sh"
   105	git -C "$RENAME_REPO" add -A >/dev/null 2>&1
   106	git -C "$RENAME_REPO" commit -q -m seed
   107	RENAME_BASE="$(git -C "$RENAME_REPO" rev-parse HEAD)"
   108	git -C "$RENAME_REPO" mv test/old-regression.sh test/new-regression.sh
   109	git -C "$RENAME_REPO" commit -q -m rename
   110	
   111	# The defect, demonstrated rather than described: default rename detection hides the source path.
   112	if [ "$(git -C "$RENAME_REPO" diff --name-only "$RENAME_BASE" HEAD | wc -l | tr -d ' ')" -eq 1 ]; then
   113	  pass "control: plain --name-only reports ONE path for a rename (the source is invisible)"
   114	else
   115	  fail "control failed: git no longer hides the rename source, so this guard's premise is stale"
   116	fi
   117	
   118	rename_paths="$(git -C "$RENAME_REPO" diff --no-renames --name-only "$RENAME_BASE" HEAD)"
   119	# CWD must be the FIXTURE: ci-route.sh resolves `[[ -f "$path" ]]` relative to the working
   120	# directory, which is the whole mechanism under test — a vanished source path is what trips the
   121	# fail-closed branch. Run it from the harness root and every fixture path looks vanished, which
   122	# would make this assertion pass for the wrong reason and the edit case below fail outright.
   123	out="$(cd "$RENAME_REPO" && printf '%s\n' "$rename_paths" | bash "$ROUTER" push)"
   124	grep -Fqx 'route=full' <<<"$out" \
   125	  && pass "a renamed regression test selects full (--no-renames surfaces the removal)" \
   126	  || fail "GH-509: a renamed test did not select full — test removal can escape the full gate: $out"
   127	
   128	# And the reverse, so this is not simply "renames always full for some other reason": the same
   129	# fixture with the file merely EDITED must not be forced to full.
   130	printf '#!/usr/bin/env bash\nexit 1\n' >"$RENAME_REPO/test/new-regression.sh"
   131	git -C "$RENAME_REPO" add -A >/dev/null 2>&1
   132	git -C "$RENAME_REPO" commit -q -m edit
   133	edit_paths="$(git -C "$RENAME_REPO" diff --no-renames --name-only HEAD~1 HEAD)"
   134	out="$(cd "$RENAME_REPO" && printf '%s\n' "$edit_paths" | bash "$ROUTER" push)"
   135	grep -Fqx 'route=full' <<<"$out" \
   136	  && fail "an ordinary test EDIT was forced to full — the rename rule is over-broad" \
   137	  || pass "an ordinary test edit is not forced to full (the rename rule is not a blanket)"
   138	
   139	# ── GH-35: the TIER answers are pinned separately from the route ────────────────────────────────
   140	# route is the CI job shape; tier is the local gate selection. They DELIBERATELY disagree on
   141	# two pinned cases: an unmapped code path routes fast (CI runs its containment list) but stays
   142	# tier 3 locally (the push hook runs the full gate), and an ordinary test edit routes fast but
   143	# is tier 3 — the routing contract's own evidence never weakens its own gate.
   144	expect_tier() {
   145	  local label="$1" event="$2" expected_tier="$3"
   146	  shift 3
   147	  local out
   148	  out="$(route "$event" "$@")"
   149	  if grep -Fqx "tier=$expected_tier" <<<"$out"; then
   150	    pass "$label"
   151	  else
   152	    fail "$label: $out"
   153	  fi
   154	}
   155	
   156	expect_tier "docs-only changes are tier 1" pull_request 1 README.md PROJECT/x.md decisions/d.md docs/guide.txt .pdda-mode
   157	expect_tier "text and markdown anywhere are docs (GH-35 widened)" pull_request 1 relay-system/2026-08-18/run/NOTE.txt
   158	expect_tier "HQ utility changes are tier 2" pull_request 2 utils/hq/hq.sh skills/2-daily/hq/find-hq.sh
   159	expect_tier "releases subsystem (incl. the one non-twin utils/py file) is tier 2" pull_request 2 utils/py/releases_app.py utils/release-lanes.sh
   160	expect_tier "releases DB and dump files are tier 1 (GH-831 D4; tier 2 before, GH-496)" pull_request 1 releases.sql releases.db
   161	# GH-831 D4 precedence: a ledger dump is docs, a non-core skill's code is docs, a core skill's code
   162	# and an area-claimed skill are not, and a ledger dump beside core still fails closed.
   163	expect_tier "the other data dumps are tier 1 too (GH-831 D4)" pull_request 1 harnesses.sql harnesses.db
   164	expect_tier "non-core skill code is tier 1 (GH-831 D4)" pull_request 1 skills/3-weekly/radar/install.sh skills/4-occasional/rpr/scan.py
   165	expect_tier "core skill code stays off the docs gate (GH-831 D4: merge-cleanup)" pull_request 3 skills/2-daily/merge-cleanup/scripts/merge_cleanup.py
   166	expect_tier "a ledger dump beside core fails closed to tier 3 (GH-831 D4)" pull_request 3 releases.db relay-automation/relay-drive.sh
   167	expect_tier "releases utilities are tier 2 (GH-496)" pull_request 2 utils/releases-merge-resolve.sh utils/leaderboard.sh
   168	expect_tier "wave_reconcile is tier 2 under PDDA (GH-496)" pull_request 2 utils/py/wave_reconcile.py
   169	expect_tier "telemetry is tier 2" pull_request 2 utils/telemetry/health-lib.sh
   170	expect_tier "ATE + fuzzing are tier 2" pull_request 2 utils/ate/install.sh utils/fuzzing/fuzz-loop.sh
   171	expect_tier "swe-diagram is tier 2" pull_request 2 utils/swe-diagram/assets/renderer.js
   172	expect_tier "agent-chorus skill code is tier 2 (GH-35 subsystem 7)" pull_request 2 skills/2-daily/agent-chorus/scripts/agent_chorus.py
   173	expect_tier "agent-chorus SKILL.md stays docs (explanatory markdown)" pull_request 1 skills/2-daily/agent-chorus/SKILL.md
   174	expect_tier "kernel changes are tier 3" pull_request 3 src/events.js
   175	expect_tier "authoritative Python twins are tier 3" pull_request 3 utils/py/relay_drive.py
   176	expect_tier "relay-xyz skill surface is tier 3" pull_request 3 skills/1-hourly/relay-xyz/SKILL.md
   177	expect_tier "an UNMAPPED code path is tier 3 even though route=fast" pull_request 3 relay-automation/relay-turn-lib.sh
   178	expect_tier "an ordinary test EDIT is tier 3 (the contract's own evidence)" pull_request 3 test/some-suite.sh
   179	expect_tier "a test-like path outside test/ and outside a subsystem dir is unmapped" pull_request 3 fixtures/mock-test.sh
   180	expect_tier "mixed docs + subsystem is tier 2 with PDDA still on" pull_request 2 README.md utils/hq/hq.sh
   181	expect_tier "mixed subsystem + kernel fails closed to tier 3" pull_request 3 utils/hq/hq.sh src/events.js
   182	expect_tier "scheduled runs stay tier 3" schedule 3
   183	
   184	# GH-487 registered-skill contract tests: a modified registered skill with code + dedicated test
   185	# is classified as tier 2 (the fast path), but an unregistered skill or a missing dedicated test
   186	# fails closed into tier 3.
   187	expect_tier "a registered skill + its code + its dedicated tests is tier 2 (GH-487)" pull_request 2 skills/3-weekly/skills-army-hq/scripts/intake.py test/skills-army-hq.sh
   188	expect_tier "a dedicated test edited ALONE stays tier 3 (co-touch requirement, GH-487)" pull_request 3 test/skills-army-hq.sh
   189	expect_tier "shared Python test integration still escalates beside skill code (GH-487)" pull_request 3 skills/3-weekly/skills-army-hq/scripts/intake.py test/test_python_layer.py
   190	expect_tier "a TESTS-RESULTS receipt alone uses the docs gate (GH-487)" pull_request 1 TESTS-RESULTS/2026-09-08+GH-487/evidence.jsonl
   191	expect_tier "a TESTS-RESULTS receipt alone is tier 1 (GH-487)" pull_request 1 TESTS-RESULTS/2026-09-08+GH-487/evidence.jsonl
   192	expect_tier "a receipt beside subsystem code keeps the subsystem gate (GH-487)" pull_request 2 TESTS-RESULTS/2026-09-08+GH-487/evidence.jsonl utils/hq/hq.sh
   193	
   194	# A DELETED dedicated suite fails closed into the full gate: move the real wrapper away so the
   195	# CWD-relative existence check sees the deletion — the rename fixture's mechanism, GH-487 form.
   196	SKILLS_SUITE="$ROOT/test/skills-army-hq.sh"
   197	if [ -f "$SKILLS_SUITE" ]; then
   198	  mv "$SKILLS_SUITE" "$WORK/skills-army-hq.sh.stash"
   199	  out="$(route push test/skills-army-hq.sh || true)"
   200	  mv "$WORK/skills-army-hq.sh.stash" "$SKILLS_SUITE"
validate.sh:647:  "registry-lock-concurrency.sh"
validate.sh:680:  "gh-gen4-phase1-domain-oracles.sh" # GH-299 Phase 1 (Gen 4 semantic domain oracles: zero-state, containment, idempotence, crash-recovery; +/- controls)
validate.sh:771:      [ $# -ge 2 ] || _err2 "--skip requires a suite name (e.g. --skip registry-lock-concurrency.sh)"
ci-local.sh:26:# `registry-lock-concurrency.sh` — the workflow's own comment says that suite "passes locally" and
ci-local.sh:261:  # It used to mirror CI's, including `registry-lock-concurrency.sh`. That suite's own skip comment
.github/workflows/ci.yml:452:      # bug in any of them. Only registry-lock-concurrency.sh (GH-72, a documented 16-concurrent-writer
.github/workflows/ci.yml:494:            --skip registry-lock-concurrency.sh \
utils/ci-route.sh:28:SUBSYSTEM_TESTS_ate="ate-run-variations.sh gh298-ate-gen4-ci-smoke.sh gh-gen4-phase1-domain-oracles.sh gh-gen4-phase2-adaptive-ate.sh gh-gen4-phase3-fuzz-engine.sh gh-gen4-phase4-repro-synth.sh gh-gen4-phase5-campaign.sh gh478-runaway-guard.sh gh712-jev-triage.sh synthetic/gh102-telemetry-schema.sh gh142-ate-exit-contract.sh"
test/gh-gen4-phase1-domain-oracles.sh:27:echo "== test: gh-gen4-phase1-domain-oracles =="
test/gh-gen4-phase1-domain-oracles.sh:159:echo "== gh-gen4-phase1-domain-oracles: $PASS passed, $FAIL failed =="
test/ci-workflow.sh:414:  # the wrong invariant: `registry-lock-concurrency.sh` is skipped in CI for a contended-Linux-runner
test/ci-workflow.sh:429:  if grep -qF '"registry-lock-concurrency.sh"' "$CI_LOCAL"; then
test/ci-workflow.sh:430:    fail "GH-509: ci-local.sh skips registry-lock-concurrency.sh — that suite PASSES on macOS and is skipped in CI only for a contended-Linux flake; local must not imitate a platform we do not ship to"
test/ci-workflow.sh:432:    pass "ci-local.sh runs registry-lock-concurrency.sh (skipped in CI for a Linux-only flake)"
test/registry-lock-concurrency.sh:4:# registry-lock-concurrency.sh — GH-72 regression. N concurrent install.sh writers hammering ONE
test/registry-lock-concurrency.sh:21:echo "registry-lock-concurrency (GH-72): $N concurrent writers -> 1 registry"
test/registry-lock-concurrency.sh:59:echo "  registry-lock-concurrency: $pass pass, $fail fail"
test/baselines/GH-509-phase4-negative-control.md:16:| `SKIP_TESTS=("registry-lock-concurrency.sh")` injected into the boundary run block | boundary must carry no skip list | 35 / **2** |
   635	  "gh204-sed-portability.sh"     # GH-204 (in-place edits portable AND content-asserted; exit code masks the loss)
   636	  "gh153-releases-sidebar-rollup.sh"   # GH-153 (dashboard sidebar spike: releases_cycle module contract,
   637	                                 #   exporter payload keys + baked chrome in both artifacts; the rollup
   638	                                 #   embed itself lives in hq-rollup.sh cases A/F/G)
   639	  "transcript-audit.sh"
   640	  "security-scan.sh"
   641	  "sentinel-tier1.sh"           # GH-281 (Tier-1 JSONL finding capture)
   642	  "sentinel-network-guard.sh"   # GH-281 (bundled scripts stay zero-network)
   643	  "sentinel-driver-hooks.sh"    # GH-281 (marathon-drive.sh Tier-1 hooks: default-off + on-mode append)
   644	  "sentinel-overlay.sh"         # GH-281 (Tier-2 overlay: static egress guard + inert-by-default proof)
   645	  "checkjs.sh"
   646	  "acorn-extract.sh"             # GH-169
   647	  "registry-lock-concurrency.sh"
   648	  "marathon-monitor.sh"          # GH-88 (cross-repo marathon monitor)
   649	  "signal-triage.sh"             # GH-63 (signal triage stage)
   650	  # GH-40 double-blind Reviewer canaries — each verify-fixture.sh drives the real kernel and exits
   651	  # 0/1, so it plugs straight in. ponytail: the Gamma canary (test/fixtures/gamma-poison/) is
   652	  # deliberately NOT here — it runs the whole validate.sh itself, so nesting it would recurse; it
   653	  # stays a manual check.
   654	  "fixtures/canary-token-reuse/verify-fixture.sh"
   655	  "fixtures/canary-peer-orphan/verify-fixture.sh"
   656	  "fixtures/canary-reviewer-overstep/verify-fixture.sh"
   657	  "phase3-signoff-guard.sh"
   658	  # Live-agent test — auto-skips when agy/codex not on PATH or RELAY_SELF_SUFFICIENCY_SKIP=1.
   659	  # Set RELAY_SELF_SUFFICIENCY_SKIP=1 in CI / keyless environments to avoid the real API call.
   660	  "relay-self-sufficiency.sh"
   661	  # GH-306: the bidirectional registry audit found these ten suites green on disk but in neither
   662	  # TESTS nor the subsystem registry — every one a B3-shaped coverage hole (the gh280 lesson:
   663	  # unregistered means the gate never runs it, green or not). Registered as one block so the
   664	  # block itself documents the audit; gh306-registry-bidirectional.sh keeps the reverse
   665	  # direction closed from here on.
   666	  "agy-tui-takeover-verdict.sh"     # GH-375 follow-up (agy 1.1.16 mute terminal-takeover verdict; pre-fix replay in-suite)
   667	  "gh105-vendor-releases-addon.sh"  # GH-105 (Tier-2 releases addon vendoring + sticky tier detection)
   668	  "gh107-timeline-json-seam.sh"     # GH-107 (export_timeline.py --json seam)
   669	  "gh132-review-xyz-skill.sh"       # GH-132 (/review-xyz skill + multi-model review harness)
   670	  "gh165-governance-canonical-paths-guard.sh" # GH-165 (canonical wave-reconciler paths + GH-551 anti-sprawl static guard)
   671	  "gh197-vendor-tier-split.sh"      # GH-197 (two-tier vendor: core default + opt-in RELEASES overlay)
   672	  "gh273-marathon-root-audit-python-shape.sh" # GH-273 (root audit matches python3-spelled driver calls — the GH-195 blind spot)
   673	  "gh312-vendor-preserves-state.sh" # GH-312 (vendor/sync must not destroy the target's runtime state)
   674	  "relay-uncited-findings.sh"       # GH-173 B3 (rtl_check_uncited_findings downgrades uncited review claims)
   675	  "wave-reconcile.sh"               # GH-165 (canonical post-merge reconciler behavior)
   676	  "gh496-phase2-reconciliation-views.sh" # GH-496 (hosted reconciler in-flight collision detection, pre-merge checks, marathon plan fingerprinting)
   677	  "gh693-lessons-learned-advisory.sh" # GH-693 (Lessons Learned is a WARN, never a promotion gate: explicit, --pre-merge, catch-up; frontmatter control)
   678	  "gh306-registry-bidirectional.sh" # GH-306 (exists→registered registry half; self-demonstrating — see the suite header)
   679	  "gh298-ate-gen4-ci-smoke.sh"      # GH-298 (ATE Gen 4 CI smoke — fuzz/oracle wiring against the real runner)
   680	  "gh-gen4-phase1-domain-oracles.sh" # GH-299 Phase 1 (Gen 4 semantic domain oracles: zero-state, containment, idempotence, crash-recovery; +/- controls)
   681	  "gh-gen4-phase2-adaptive-ate.sh"   # GH-299 Phase 2 (Gen 4 constraint-aware pairwise ATE + calibrated $0 Tier-1 triage; independent coverage walk)
   682	  "gh-gen4-phase3-fuzz-engine.sh"    # GH-299 Phase 3 (Gen 4 seeded mutational fuzz engine: replay, novelty-capped corpus, cross-twin parity)
   683	  "gh-gen4-phase4-repro-synth.sh"    # GH-299 Phase 4 (Gen 4 clustered reproducer synthesis: 1 suite per root cause, ddmin, falsification)
   684	  "gh-gen4-phase5-campaign.sh"       # GH-299 Phase 5 (Gen 4 sandboxed campaign: bounded soak in a disposable clone, 0 host contamination, poison control)
   685	  "gh712-jev-triage.sh"              # GH-712 (Jev ATE triage offline replays: green/red FN controls, empty input, hash/model contract; canned responses, no network)
   686	  "gh396-find-harness-roots.sh"     # GH-396 (find-harness two-roots contract: #395 ×5 topologies, #394 warn-under-override + runnable remedy, --quiet)
   687	  "gh393-deepseek-readiness.sh"     # GH-396 / #393 (RELAY_HAS_DEEPSEEK parity with deepseek-turn.py's own binary rule + API key)
   688	  "gh591-prepush-commit-boundary.sh" # GH-591 (hook-created files do not travel in the selected commit)
   689	  "gh589-xyz-mini-sync.sh"          # GH-589 (XYZ mini publisher: idempotent, inclusion-only, mirror, ownership guard, secret tripwire, push read-back)
   690	  "gh589-consult-no-tick.sh"        # GH-589 (consult runs in the exported mini package without bin/tick; explicit broken TICK_BIN stays fatal; empty answers fail)
   755	fi
   756	while [ $# -gt 0 ]; do
   757	  case "$1" in
   758	    --list)
   759	      # #141 Phase 1: expose the authoritative registry as a manifest. Prints test/<entry> for
   760	      # every TESTS member, one per line, before any gate machinery runs. Read-only.
   761	      #
   762	      # GH-379: this used to `exit 0` right here, INSIDE the argument loop — which put it ahead of
   763	      # the --skip name validation below, so `XYZ_VALIDATE_SKIP=typo.sh ./validate.sh --list`
   764	      # returned 0 without ever checking the name. Deferred to after the loop so every exit path
   765	      # that accepts quarantine input also validates it. (Codex review round 2, 2026-09-02.)
   766	      LIST_ONLY=1; shift ;;
   767	    --print-mode) PRINT_MODE_ONLY=1; shift ;;
   768	    --skip)
   769	      # GH-379: the canary hand-rolled its own runner partly to get a skip list. A skip is a real
   770	      # reduction in coverage, so it is spelled out loud rather than buried in a CI for-loop.
   771	      [ $# -ge 2 ] || _err2 "--skip requires a suite name (e.g. --skip registry-lock-concurrency.sh)"
   772	      SKIP_SUITES+=("$2")
   773	      shift 2 ;;
   774	    --parallel|--max-parallel)
   775	      [ $# -ge 2 ] || _err2 "$1 requires an integer >= 1"
   776	      case "$2" in ''|*[!0-9]*) _err2 "$1 requires an integer >= 1" ;; esac
   777	      [ "$2" -ge 1 ] || _err2 "$1 requires an integer >= 1"
   778	      MODE_FLAGS=$((MODE_FLAGS + 1)); [ "$MODE_FLAGS" -le 1 ] || _err2 "conflicting concurrency flags — pick one of --parallel/--max-parallel/--sequential/--throttle/--burst"
   890	    [ "$_auto_head" = "$AUTO_RANGE" ] && _auto_head=""
   891	  else
   892	    # Default range: everything this clone has over its upstream, INCLUDING uncommitted work
   893	    # (diff against the working tree, not HEAD). No upstream -> compare against HEAD's parent.
   894	    _auto_base="$(git rev-parse --abbrev-ref --symbolic-full-name '@{upstream}' 2>/dev/null || true)"
   895	    [ -n "$_auto_base" ] || _auto_base="HEAD^"
   896	    _auto_head=""
   897	  fi
   898	  _auto_paths() {
   899	    if [ -n "$_auto_head" ]; then git diff --no-renames --name-only "$_auto_base" "$_auto_head"
   900	    else git diff --no-renames --name-only "$_auto_base"; fi
   901	  }
   902	  if _cls="$(_auto_paths 2>/dev/null | classify_paths)"; then
   903	    apply_classification "$_cls"
   904	    T2_PATHS="$(_auto_paths 2>/dev/null)"
   905	    echo "validate.sh: --auto classified tier $TIER — ${TIER_REASON:-unspecified} (GH-35)"
   906	    case "$T2_PATHS" in *.py|*.py$'\n'*) T2_PYTEST=1 ;; esac
   907	  else
   908	    echo "validate.sh: --auto could not classify the diff — failing closed to tier 3 (GH-35)" >&2
   909	    TIER=3
   910	  fi
   911	fi
   912	
   913	if [ -n "$PATHS_FILE" ]; then
   914	  [ -s "$PATHS_FILE" ] || _err2 "--paths-file must name a non-empty file"
   915	  _cls="$(classify_paths < "$PATHS_FILE")" || _err2 "the classifier could not run — refusing to guess a tier"
   916	  apply_classification "$_cls"
   917	  if [ "$TIER" -ne 2 ]; then
   918	    # A caller hands over a path list precisely because it wants the narrow gate. If those
   919	    # paths classify as anything but tier 2, saying so and failing is the honest move — a
   920	    # quiet escalation to a 4-minute full gate from inside a hook looks like a hang.
   921	    echo "validate.sh: --paths-file classified tier $TIER — ${TIER_REASON:-unspecified}." >&2
   922	    echo "validate.sh: refusing the narrow gate; run the full ./validate.sh (or push, which will)." >&2
   923	    exit 2
   924	  fi

exec
/bin/zsh -lc "nl -ba test/ci-workflow.sh | sed -n '407,438p'; rg -n 'membership|registered|SUBSYSTEM_TESTS|TESTS=|small' test/ci-route.sh utils/ci-route.sh | head -65; rg -n '909|completion.*writ|completion.*lock' validate.sh test/gh* utils/py/marathon_drive.py | head -35; nl -ba githooks/pre-push | sed -n '1,100p'; rg -n 'RELAY_SELF_SUFFICIENCY_SKIP|MAX_JOBS|RETRY|retry' githooks/pre-push validate.sh .github/workflows/wave-reconcile.yml | head -65; python3 -B -c 'import re,pathlib; s=pathlib.Path(\"validate.sh\").read_text().split(\"TESTS=(\",1)[1].split(\"\\n)\",1)[0]; a=re.findall(r\""'^'"\\s*\\\"(["'^'"\\\"]+\\.sh)\\\"\",s,re.M); print(\"anchored registry entries:\",len(a)); print(\"targets:\",[x for x in a if x in (\"registry-lock-concurrency.sh\",\"gh-gen4-phase1-domain-oracles.sh\")])'" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-16535-02sbwo67
 succeeded in 0ms:
   407	  else
   408	    pass "ci-local.sh no longer re-derives the registry at all (GH-379 follow-up landed)"
   409	  fi
   410	
   411	  # (2) The skip lists must now DIFFER, and this assertion was inverted on 2026-08-12 (GH-509).
   412	  #
   413	  # It previously required the two files to skip the SAME tests. Under the macOS reframe that pinned
   414	  # the wrong invariant: `registry-lock-concurrency.sh` is skipped in CI for a contended-Linux-runner
   415	  # flake, and the workflow's own comment says it "passes locally". Requiring local to skip it too
   416	  # discarded real signal about the platform we ship to, in order to imitate one we do not.
   417	  #
   418	  # Local must run MORE than hosted ubuntu, not the same.
   419	  # GH-379: the workflow now expresses its skips as validate.sh's `--skip <name>` rather than a
   420	  # quoted array member, so match either idiom. What matters is that BOTH still skip it — the
   421	  # intent (it already ran in the npm step; duplicate work, not lost coverage) is unchanged.
   422	  if { grep -qF '"acorn-extract.sh"' "$WORKFLOW" || grep -qE -- '--skip[[:space:]]+acorn-extract\.sh' "$WORKFLOW"; } \
   423	     && grep -qF '"acorn-extract.sh"' "$CI_LOCAL"; then
   424	    pass "both skip acorn-extract.sh (it already ran in the npm step — duplicate work, not lost coverage)"
   425	  else
   426	    fail "acorn-extract.sh skip drift — it is duplicate work in both files and should be skipped in both"
   427	  fi
   428	
   429	  if grep -qF '"registry-lock-concurrency.sh"' "$CI_LOCAL"; then
   430	    fail "GH-509: ci-local.sh skips registry-lock-concurrency.sh — that suite PASSES on macOS and is skipped in CI only for a contended-Linux flake; local must not imitate a platform we do not ship to"
   431	  else
   432	    pass "ci-local.sh runs registry-lock-concurrency.sh (skipped in CI for a Linux-only flake)"
   433	  fi
   434	
   435	  # (3) The honesty notice, also inverted. The old caveat warned that a green local run is not a green
   436	  # ubuntu run — true, but the less useful direction now: local IS the shipping platform. The limit
   437	  # worth pinning is that a local run is SELF-REPORTED, which is what the hosted macOS boundary buys
   438	  # out. If that caveat is edited away, the script starts implying it can qualify a promotion.
test/ci-route.sh:184:# GH-487 registered-skill contract tests: a modified registered skill with code + dedicated test
test/ci-route.sh:185:# is classified as tier 2 (the fast path), but an unregistered skill or a missing dedicated test
test/ci-route.sh:187:expect_tier "a registered skill + its code + its dedicated tests is tier 2 (GH-487)" pull_request 2 skills/3-weekly/skills-army-hq/scripts/intake.py test/skills-army-hq.sh
test/ci-route.sh:241:out="$(bash "$ROUTER" subsystems small)"
test/ci-route.sh:244:  && pass "subsystems small lists its 72 suites, without gh436 (GH-831; GH-836 D1)" \
test/ci-route.sh:245:  || fail "subsystems small listed $(wc -w <<<"$out") suites: $out"
test/ci-route.sh:258:printf '#!/usr/bin/env bash\nTESTS=(\n  "existing-test.sh"\n)\n' >"$VALIDATE_REPO/validate.sh"
test/ci-route.sh:268:printf '#!/usr/bin/env bash\nTESTS=(\n  "existing-test.sh"\n  "new-test.sh" # GH-496 (new test)\n)\n' >"$VALIDATE_REPO/validate.sh"
test/ci-route.sh:286:printf '#!/usr/bin/env bash\nTESTS=(\n  "existing-test.sh"\n  "new-test.sh" # GH-496 (new test)\n  "skills-army-hq.sh"\n)\n' >"$VALIDATE_REPO/validate.sh"
test/ci-route.sh:298:printf '#!/usr/bin/env bash\nMAX_JOBS=4\nTESTS=(\n  "existing-test.sh"\n  "new-test.sh"\n)\n' >"$VALIDATE_REPO/validate.sh"
test/ci-route.sh:310:printf '#!/usr/bin/env bash\nTESTS=(\n  "new-test.sh"\n)\n' >"$VALIDATE_REPO/validate.sh"
test/ci-route.sh:322:printf '#!/usr/bin/env bash\nTESTS=(\n  "new-test.sh"\n' >"$VALIDATE_REPO/validate.sh"
test/ci-route.sh:334:printf '#!/usr/bin/env bash\nTESTS=(\n  "existing-test.sh"\n  "new-test.sh"\n)\n"payload.sh"\n' >"$VALIDATE_REPO/validate.sh"
test/ci-route.sh:351:printf '#!/usr/bin/env bash\nTESTS=(\n  "existing-test.sh"\n)\n' >"$MULTI_REPO/validate.sh"
test/ci-route.sh:359:printf '#!/usr/bin/env bash\nRUNNER_MODE=custom\nTESTS=(\n  "existing-test.sh"\n)\n' >"$MULTI_REPO/validate.sh"
test/ci-route.sh:364:printf '#!/usr/bin/env bash\nRUNNER_MODE=custom\nTESTS=(\n  "existing-test.sh"\n  "new-test.sh"\n)\n' >"$MULTI_REPO/validate.sh"
test/ci-route.sh:412:printf '#!/usr/bin/env bash\nTESTS=(\n  "new.sh"\n)\n' >"$NON_GIT_DIR/validate.sh"
test/ci-route.sh:426:printf '#!/usr/bin/env bash\nTESTS=(\n  # Section 1\n  "existing-test.sh"\n)\n' >"$COMMENT_REPO/validate.sh"
test/ci-route.sh:434:printf '#!/usr/bin/env bash\nTESTS=(\n  "existing-test.sh"\n  "new-test.sh"\n)\n' >"$COMMENT_REPO/validate.sh"
test/ci-route.sh:453:printf '#!/usr/bin/env bash\nTESTS=(\n  "existing-test.sh"\n)\n' >"$FORCED_DIFF_REPO/validate.sh"
test/ci-route.sh:460:printf '#!/usr/bin/env bash\nTESTS=(\n  "existing-test.sh"\n  "new-test.sh"\n)\n' >"$FORCED_DIFF_REPO/validate.sh"
utils/ci-route.sh:21:# and list its suites in SUBSYSTEM_TESTS_<name>. Every listed suite must exist in test/ AND
utils/ci-route.sh:22:# be registered in validate.sh's TESTS array — test/gh35-test-tiers.sh enforces both, because
utils/ci-route.sh:24:SUBSYSTEMS="hq releases telemetry ate swe-diagram pdda agent-chorus standup skills-army-hq small"
utils/ci-route.sh:25:SUBSYSTEM_TESTS_hq="hq.sh hq-park.sh hq-park-synthesis.sh hq-dispatch.sh hq-next.sh hq-locator.sh hq-hardening.sh hq-promote.sh hq-marathon-scan.sh hq-rollup.sh hq-marathon-live.sh gh238-hq-releases-mode.sh gh239-hq-status-releases-mode.sh"
utils/ci-route.sh:26:SUBSYSTEM_TESTS_releases="gh32-releases-app.sh gh103-timeline-exporter.sh gh32-releases-artifacts.sh gh53-releases-merge-resolve.sh gh54-merged-dump-refusals.sh gh57-live-merge-resolve.sh gh69-roadmap-shadow.sh gh32-release-target-advisory.sh gh39-releases-project-sync.sh gh153-releases-sidebar-rollup.sh releases-skill.sh gh284-p3-release-milestone.sh gh284-p4-release-lanes.sh litmus-release.sh nightwatch-release.sh meter-release.sh ballast-release.sh gh57-releases-fuzz.sh gh257-roadmap-ledger-fixes.sh gh269-roadmap-retired.sh gh549-work-events.sh gh567-roadmap-dashboard-retired.sh gh568-releases-md-retired.sh gh646-status-label.sh"
utils/ci-route.sh:27:SUBSYSTEM_TESTS_telemetry="xyz-completion.sh gh358-lock-instrumentation.sh archive-telemetry.sh gh496-telemetry-isolation.sh"
utils/ci-route.sh:28:SUBSYSTEM_TESTS_ate="ate-run-variations.sh gh298-ate-gen4-ci-smoke.sh gh-gen4-phase1-domain-oracles.sh gh-gen4-phase2-adaptive-ate.sh gh-gen4-phase3-fuzz-engine.sh gh-gen4-phase4-repro-synth.sh gh-gen4-phase5-campaign.sh gh478-runaway-guard.sh gh712-jev-triage.sh synthetic/gh102-telemetry-schema.sh gh142-ate-exit-contract.sh"
utils/ci-route.sh:29:SUBSYSTEM_TESTS_swe_diagram="swe-diagram.sh"
utils/ci-route.sh:30:SUBSYSTEM_TESTS_pdda="gh649-pdda-migration.sh pdda-changelog.sh pdda-install-startup-docs.sh pdda-roadmap-coverage.sh pdda-repo-contract.sh pdda-local-checks.sh gh400-acceptance-fidelity.sh gh400-source-url.sh gh422-backfill-source-url.sh gh425-source-url-slug.sh wave-reconcile.sh gh202-wave-reconcile-issue-state.sh gh232-wave-reconcile-multiphase.sh gh358-wave-reconcile-vendored-paths.sh gh496-phase2-reconciliation-views.sh"
utils/ci-route.sh:31:SUBSYSTEM_TESTS_agent_chorus="agent-chorus.sh agent-chorus-bridge.sh gh233-agent-chorus-concurrency.sh"
utils/ci-route.sh:32:SUBSYSTEM_TESTS_standup="gh77-standup-triage.sh"
utils/ci-route.sh:33:SUBSYSTEM_TESTS_skills_army_hq="skills-army-hq.sh gh620-skills-army-mini-sync.sh gh589-xyz-mini-sync.sh gh589-consult-no-tick.sh gh589-skill-viewer.sh"
utils/ci-route.sh:35:# reconcile qualifies a tier-1 landing with `validate.sh --sequential --subsystem small`, and
utils/ci-route.sh:37:# it one literal line. subsystem_of() claims no paths for small: it is a gate, not an area.
utils/ci-route.sh:38:SUBSYSTEM_TESTS_small="gh308-frozen-twin-guard.sh gh777-inventory-ratchet.sh gh400-acceptance-fidelity.sh gh400-source-url.sh litmus-release.sh gh422-backfill-source-url.sh gh425-source-url-slug.sh gh448-driver-lock-resolver.sh nightwatch-release.sh meter-release.sh ballast-release.sh gh549-work-events.sh gh646-status-label.sh gh1-fixture-guard.sh gh1-adoption-guard.sh gh139-pipe-grep-guard.sh gh168-wave-reconcile-scope.sh gh184-no-tracked-scratch.sh gh202-wave-reconcile-issue-state.sh gh232-wave-reconcile-multiphase.sh releases-skill.sh gh103-timeline-exporter.sh gh75-dashboard.sh gh32-releases-app.sh gh32-releases-artifacts.sh gh53-releases-merge-resolve.sh gh54-merged-dump-refusals.sh gh57-releases-fuzz.sh gh57-live-merge-resolve.sh gh69-roadmap-shadow.sh gh351-manifest-unship.sh gh360-scoped-receipt-chain-rebuild.sh gh349-releases-roadmap-vendored.sh gh429-wave-reconcile-vendored-observe.sh gh358-wave-reconcile-vendored-paths.sh gh32-release-target-advisory.sh gh39-releases-project-sync.sh relay-target-root.sh relay-target-root-paths.sh relay-target-root-relayfile.sh relay-target-root-newfile.sh gh649-pdda-migration.sh pdda-changelog.sh pdda-install-startup-docs.sh pdda-roadmap-coverage.sh pdda-repo-contract.sh pdda-local-checks.sh gh784-marathon-qa-gate.sh gh284-p3-release-milestone.sh gh284-p4-release-lanes.sh mktemp-trap-guard.sh gh567-roadmap-dashboard-retired.sh gh257-roadmap-ledger-fixes.sh gh269-roadmap-retired.sh gh568-releases-md-retired.sh gh454-reconciler-defects.sh gh424-roadmap-status-marker.sh gh421-auto-wave-reconcile.sh gh491-roadmap-section-validation.sh gh492-roadmap-state-sweep.sh gh605-work-state.sh gh605-board-policy.sh gh645-merge-cleanup-xyz-tools.sh gh674-merge-cleanup-hosted-lookup.sh gh527-issue-url-repair.sh gh153-releases-sidebar-rollup.sh security-scan.sh sentinel-network-guard.sh gh107-timeline-json-seam.sh wave-reconcile.sh gh496-phase2-reconciliation-views.sh gh306-registry-bidirectional.sh"
utils/ci-route.sh:77:  # re-deriving the mapping. A registered suite missing from disk fails LOUDLY here: a silent
utils/ci-route.sh:82:      _tests="SUBSYSTEM_TESTS_${s//-/_}"
utils/ci-route.sh:91:      _tests="SUBSYSTEM_TESTS_${s//-/_}"
utils/ci-route.sh:193:    start_re = re.compile(r"^\s*TESTS=\(\s*$")
utils/ci-route.sh:199:                skeleton.append("TESTS=(")
utils/ci-route.sh:380:  # Tier-2 membership: only explicitly registered subsystem paths qualify; every other
utils/ci-route.sh:486:    _tests="SUBSYSTEM_TESTS_${s//-/_}"
test/gh123-lock-progress-bound.sh:5:# CPU-throttled runner the 16 concurrent appenders in test/xyz-completion.sh queue on one lock,
test/gh123-lock-progress-bound.sh:97:  || fail "test/xyz-completion.sh no longer mirrors the writer's 30s default"
     1	#!/usr/bin/env bash
     2	# pre-push — run the gate before anything reaches the remote. (GH-544)
     3	#
     4	# WHY THIS EXISTS: the push boundary gives the author the earliest complete local signal. Hosted CI
     5	# is re-armed now that XYZ-forge is public (#16), but it is downstream and the Ubuntu PR lane is
     6	# advisory; local commits remain free and ungated on purpose, while a push is checked before it
     7	# leaves the machine.
     8	#
     9	# WHY IT RUNS THE FAST GATE: `validate.sh` is parallel by default rather than sequential;
    10	# use this hook's measured `GREEN in Ns` line for current cost. This is the single most
    11	# important choice in this file. A slow pre-push hook risks producing `--no-verify` as a reflex,
    12	# and a gate that is routinely bypassed is worth less than no gate, because it also produces
    13	# the belief that something was checked.
    14	#
    15	# GH-35 added a NARROWER route below the fast gate: a push whose changed paths all map to a
    16	# registered utility subsystem (utils/ci-route.sh's Tier-2 registry) runs only that subsystem's
    17	# suites (see the measured `GREEN in Ns` line) instead of the full pool, under nice. The classifier must explicitly say
    18	# tier=2 AND name runnable suites — route=fast alone is not enough, because an unmapped code
    19	# path also routes fast and belongs on the full gate. Every narrower route fails closed to the
    20	# one above it.
    21	#
    22	# WHAT THIS IS NOT: promotion evidence. `ci-local.sh` is the qualifying run — sequential, and it
    23	# writes the gate record. This hook is a guard against pushing something obviously broken, not an
    24	# attestation. Nothing here writes a record.
    25	#
    26	# INSTALL: bash githooks/install.sh   (idempotent)
    27	#
    28	# HOW IT IS REACHED: not directly. `install.sh` puts a dispatch stub in `.git/hooks/pre-push` and that
    29	# stub execs this file. The indirection is the point (GH-549) — git metadata is branch-independent, so
    30	# a branch that predates this file still gets gated (the stub falls back to running `validate.sh`),
    31	# instead of git silently skipping a hook path that does not resolve.
    32	#
    33	# BYPASS, both deliberately loud:
    34	#   git push --no-verify        # native git; cannot be removed, and should not be
    35	#   XYZ_SKIP_PREPUSH=1 git push # for automation that has already gated
    36	#
    37	# DRAFT-REVIEW PUBLICATION (GH-487) is a legitimate bypass use, and is NOT merge readiness: an
    38	# operator-requested WIP draft may push past this gate only with current focused evidence for the
    39	# changed area, the skipped-gate disclosure echoed into the PR description, and merge readiness
    40	# still outstanding. A bypassed push never authorises merge, promotion, or teardown.
    41	set -uo pipefail
    42	
    43	# FAIL CLOSED. An earlier draft exited 0 here on the theory that "not in a repo" means there is
    44	# nothing to gate — but a pre-push hook only ever runs inside a repo, so reaching this branch means
    45	# something is wrong, and "something is wrong" must not resolve to "push anyway". Refusing is
    46	# recoverable (--no-verify); a silently ungated push is not.
    47	if ! REPO="$(git rev-parse --show-toplevel 2>/dev/null)" || [ -z "$REPO" ]; then
    48	  echo "pre-push: cannot resolve the repository root — REFUSING the push rather than skipping the gate." >&2
    49	  echo "pre-push:   Override with 'git push --no-verify' if you know why this happened." >&2
    50	  exit 1
    51	fi
    52	if [ ! -x "$REPO/validate.sh" ]; then
    53	  echo "pre-push: $REPO/validate.sh is missing or not executable — REFUSING the push." >&2
    54	  echo "pre-push:   A gate that cannot run is not a gate that passed." >&2
    55	  exit 1
    56	fi
    57	
    58	# A delete-only push has nothing to test. `git push --delete branch` and a deleting refspec both
    59	# arrive here with an all-zero local sha; gating them would block cleanup for no benefit.
    60	#
    61	# stdin is "<local ref> <local sha> <remote ref> <remote sha>" per ref. If EVERY line is a delete,
    62	# skip. If stdin is empty (some callers), fall through and gate — failing open on an empty read would
    63	# make the hook trivially bypassable by anything that does not feed it.
    64	_all_deletes=1
    65	_saw_line=0
    66	_real_ref_pairs=()
    67	while read -r _lref _lsha _rref _rsha; do
    68	  [ -n "${_lsha:-}" ] || continue
    69	  _saw_line=1
    70	  case "$_lsha" in
    71	    *[!0]*)
    72	      _all_deletes=0
    73	      _real_ref_pairs+=("$_lsha|${_rsha:-}")
    74	      ;;
    75	  esac
    76	done
    77	if [ "$_saw_line" -eq 1 ] && [ "$_all_deletes" -eq 1 ]; then
    78	  echo "pre-push: delete-only push — no gate to run."
    79	  exit 0
    80	fi
    81	
    82	if [ "${XYZ_SKIP_PREPUSH:-0}" != "0" ]; then
    83	  # Announced, never silent: a skipped gate that says nothing is indistinguishable from a passing one.
    84	  echo "pre-push: SKIPPED by XYZ_SKIP_PREPUSH — nothing was verified before this push." >&2
    85	  exit 0
    86	fi
    87	
    88	# A docs-only commit is still checked, but by the deterministic documentation gate instead of the
    89	# full runtime suite. Reuse the CI classifier rather than growing a second definition of "docs".
    90	# These routes are intentionally narrow: a force push, an unavailable remote base, a URL push,
    91	# missing classifier, non-linear history, or anything other than an exact `route=docs` (tier 1) or
    92	# `route=fast`+`tier=2` (registered utility subsystems) falls back to the full gate. A bad range
    93	# must cost time, never coverage. GH-487: the FIRST push of a new branch (all-zero remote SHA) no
    94	# longer refuses classification outright — it classifies against the integration branch
    95	# (development, then main) of the remote being pushed to, and only when the base evidence is
    96	# FRESH: the local tracking ref must equal the tip the remote currently advertises (git
    97	# ls-remote), because a stale ref cannot tell "behind" from "the branch was rewritten under us",
    98	# and only the first direction is safe. Stale, ambiguous (multiple best common ancestors),
    99	# unverifiable, or empty-range evidence all fall back to the full gate with a named reason.
   100	
githooks/pre-push:191:          [ -n "$_base_note" ] || _base_note="pre-push: no fresh merge-base with $_push_remote's integration branch (tracking ref stale or absent — fetch and retry, or take the full gate)."
githooks/pre-push:297:  # backend hiccup refused the push. RELAY_SELF_SUFFICIENCY_SKIP=0 opts back in; relay-automation/README.md
githooks/pre-push:299:  if RELAY_SELF_SUFFICIENCY_SKIP="${RELAY_SELF_SUFFICIENCY_SKIP:-1}" "$REPO/validate.sh"; then
validate.sh:23:  environment   XYZ_VALIDATE_THROTTLE=1 · XYZ_VALIDATE_MAX_JOBS=N · XYZ_VALIDATE_PARALLEL=N|0
validate.sh:35:  --burst / XYZ_VALIDATE_MAX_JOBS are honoured for tier 2: 2 is the default width, not a pin.
validate.sh:252:  "gh385-retry-token-satisfied.sh" # GH-385 (a phase completed on a --retry suffixed token is satisfied) + GH-491 (--retry on an already-satisfied lane says a plain re-fire would have been gate-only) — 19/0; controls: un-completed recorded token must still rebuild; GH-491 advisory must NOT fire when the recorded token is not done, and must not change --retry's behaviour
validate.sh:259:  "gh491-gate-only-refire.sh"    # GH-491 (gate-only re-fire discoverability under --retry)
validate.sh:299:  "gh365-validate-telemetry.sh"        # GH-365 step 2 (retained JSONL telemetry, one lib for both runners) — unit schema, e2e pool/retry/sequential events with skip_lines + bytes/hash, live-denominator check, wiring pins
validate.sh:347:  "gh648-l2-token-aftermath.sh" # GH-648 L2 (timeout preserves same-role token retry)
validate.sh:578:  "gh528-parallel-contention-retry.sh" # GH-528 (--parallel re-runs a pooled failure alone before believing it, and names the contended suite; the driver-lock lane list cannot be validated by reading it)
validate.sh:631:                                     #   E2E in root + vendored installs with stubbed agents/GitHub, resume/retry/land
validate.sh:658:  # Live-agent test — auto-skips when agy/codex not on PATH or RELAY_SELF_SUFFICIENCY_SKIP=1.
validate.sh:659:  # Set RELAY_SELF_SUFFICIENCY_SKIP=1 in CI / keyless environments to avoid the real API call.
validate.sh:726:# Precedence, highest first: flags > XYZ_VALIDATE_MAX_JOBS > XYZ_VALIDATE_THROTTLE >
validate.sh:951:  case "${XYZ_VALIDATE_MAX_JOBS:-}" in
validate.sh:953:    *[!0-9]*|'0') echo "validate.sh: XYZ_VALIDATE_MAX_JOBS must be an integer >= 1" >&2; exit 2 ;;
validate.sh:954:    *) PARALLEL_JOBS="$XYZ_VALIDATE_MAX_JOBS"; PARALLEL_WHY="XYZ_VALIDATE_MAX_JOBS=$XYZ_VALIDATE_MAX_JOBS" ;;
validate.sh:1182:# parallelism, its contention-retry, and three non-shell lanes the scrape could not see. Giving the
validate.sh:1375:      rt_emit retry retry "$t" "$_s" "$(rt_now_ms)" "$rc_alone" "rc_first=$rc_first" "classified=contended"
validate.sh:1376:      rt_suite retry "$t" "$_s" "$(rt_now_ms)" "$rc_alone" "$log.serial"
validate.sh:1382:      rt_emit retry retry "$t" "$_s" "$(rt_now_ms)" "$rc_alone" "rc_first=$rc_first" "classified=real-failure"
validate.sh:1383:      rt_suite retry "$t" "$_s" "$(rt_now_ms)" "$rc_alone" "$log.serial"
validate.sh:1432:    # receipt cannot represent a failure). The retry path ten lines up has had the order right
validate.sh:1535:# suite-lane records (pool/driver-lock/sequential): retry legs add retry-lane records and the
validate.sh:1556:# Only suite events: each retry also emits event=retry, which must not double its cost.
validate.sh:1569:      if (lane == "retry") {
validate.sh:1570:        retry_ms += ms
validate.sh:1571:        if (!retried[name]++) retry_count++
validate.sh:1576:    END { print -1, retry_count + 0, retry_ms + 0 }
anchored registry entries: 410
targets: ['registry-lock-concurrency.sh', 'gh-gen4-phase1-domain-oracles.sh']

codex
The proposed removals cover the registry, ATE membership, and Ubuntu skip reference. I found two small omissions: the membership check lives in `gh35-test-tiers.sh`, which isn’t in the focused verification list, and the workflow commentary still describes the retired registry suite as a Linux-only flake.
exec
/bin/zsh -lc "rg -n 'SUBSYSTEM|registered|registry|completion.*append|gh909' test/gh35-test-tiers.sh validate.sh | tail -30; nl -ba utils/ci-route.sh | sed -n '18,35p'; nl -ba test/gh35-test-tiers.sh | sed -n '120,180p'; nl -ba validate.sh | sed -n '1335,1390p'; rg -n 'zero.retry|retry|Oct|4-wide|854' PROJECT/2-WORKING/GH-854*" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-16535-02sbwo67
 exited 1 in 0ms:
validate.sh:662:  # TESTS nor the subsystem registry — every one a B3-shaped coverage hole (the gh280 lesson:
validate.sh:663:  # unregistered means the gate never runs it, green or not). Registered as one block so the
validate.sh:664:  # block itself documents the audit; gh306-registry-bidirectional.sh keeps the reverse
validate.sh:678:  "gh306-registry-bidirectional.sh" # GH-306 (exists→registered registry half; self-demonstrating — see the suite header)
validate.sh:732:SUBSYSTEM=""
validate.sh:759:      # #141 Phase 1: expose the authoritative registry as a manifest. Prints test/<entry> for
validate.sh:771:      [ $# -ge 2 ] || _err2 "--skip requires a suite name (e.g. --skip registry-lock-concurrency.sh)"
validate.sh:799:      SUBSYSTEM="$2"; shift 2 ;;
validate.sh:820:    [ "$_known" -eq 1 ] || { echo "validate.sh: --skip names '$_sk', which is not in the registry — refusing, because a skip that matches nothing is indistinguishable from one that works (GH-379)." >&2; exit 2; }
validate.sh:842:# Tiers select a test SET from the one registry in utils/ci-route.sh; width/nice select a
validate.sh:875:if [ "$AUTO_REQUESTED" -eq 1 ] || [ -n "$PATHS_FILE" ] || [ -n "$SUBSYSTEM" ]; then
validate.sh:878:  if [ "$AUTO_REQUESTED" -eq 1 ] && { [ -n "$PATHS_FILE" ] || [ -n "$SUBSYSTEM" ]; }; then
validate.sh:881:  [ -n "$PATHS_FILE" ] && [ -n "$SUBSYSTEM" ] \
validate.sh:930:if [ -n "$SUBSYSTEM" ]; then
validate.sh:931:  T2_TESTS="$(bash "$HERE/utils/ci-route.sh" subsystems "$SUBSYSTEM" 2>/dev/null)" \
validate.sh:932:    || _err2 "unknown subsystem '$SUBSYSTEM' (utils/ci-route.sh subsystems lists them)"
validate.sh:933:  [ -n "$T2_TESTS" ] || _err2 "subsystem '$SUBSYSTEM' resolved to no suites — refusing a zero-test gate"
validate.sh:935:  case "$SUBSYSTEM" in releases|pdda) T2_PYTEST=1 ;; esac
validate.sh:938:  if [ "$SUBSYSTEM" = small ]; then T2_PYTEST=1; T2_PDDA=1; fi
validate.sh:939:  echo "validate.sh: tier 2 — subsystem $SUBSYSTEM (GH-35)"
validate.sh:1096:# same registry the push hook uses, so the two cannot disagree about what "hq" covers).
validate.sh:1186:#   1. an unregistered name is a HARD ERROR — a typo'd skip that matches nothing looks identical to
validate.sh:1204:  # to run first. Verified: with the two lines transposed, `--skip` every registered suite died at
validate.sh:1223:# harness_app.py, whose every artifact path (db, dump, registry md, blog docs) follows
validate.sh:1266:# test/gh365-driver-lane-registry.sh now audits this list bidirectionally: a shipped-driver
validate.sh:1468:# failure, unchanged). rc=2 is ENVELOPE drift — the tracked tree, a registered worktree, or the
validate.sh:1485:  [ "$_re_rc" -eq 2 ] && echo "  (envelope drift — the per-suite verdicts stand, but THIS run leaves no valid evidence record; audit the named drift for a harness-registry bypass)" >&2
validate.sh:1552:  "suite_events=$_suite_events" "run_set=${#RUN_TESTS[@]}" "registered=${#TESTS[@]}" \
validate.sh:1554:echo "telemetry: $RT_FILE ($_suite_events suite events, ${#TESTS[@]} registered)"
validate.sh:1598:if [ "${TIER:-3}" -eq 3 ] && [ -z "${SUBSYSTEM:-}" ] && [ -z "$(git status --porcelain 2>/dev/null)" ]; then
    18	# The ONE mapping from changed paths to the focused suites that cover them, consumed by
    19	# githooks/pre-push and validate.sh (--tier 2 / --subsystem). Extending it is a deliberate
    20	# three-part act: name the subsystem in SUBSYSTEMS, add its path patterns to subsystem_of(),
    21	# and list its suites in SUBSYSTEM_TESTS_<name>. Every listed suite must exist in test/ AND
    22	# be registered in validate.sh's TESTS array — test/gh35-test-tiers.sh enforces both, because
    23	# a registry naming a suite that never runs is a green lie (the releases-skill lesson).
    24	SUBSYSTEMS="hq releases telemetry ate swe-diagram pdda agent-chorus standup skills-army-hq small"
    25	SUBSYSTEM_TESTS_hq="hq.sh hq-park.sh hq-park-synthesis.sh hq-dispatch.sh hq-next.sh hq-locator.sh hq-hardening.sh hq-promote.sh hq-marathon-scan.sh hq-rollup.sh hq-marathon-live.sh gh238-hq-releases-mode.sh gh239-hq-status-releases-mode.sh"
    26	SUBSYSTEM_TESTS_releases="gh32-releases-app.sh gh103-timeline-exporter.sh gh32-releases-artifacts.sh gh53-releases-merge-resolve.sh gh54-merged-dump-refusals.sh gh57-live-merge-resolve.sh gh69-roadmap-shadow.sh gh32-release-target-advisory.sh gh39-releases-project-sync.sh gh153-releases-sidebar-rollup.sh releases-skill.sh gh284-p3-release-milestone.sh gh284-p4-release-lanes.sh litmus-release.sh nightwatch-release.sh meter-release.sh ballast-release.sh gh57-releases-fuzz.sh gh257-roadmap-ledger-fixes.sh gh269-roadmap-retired.sh gh549-work-events.sh gh567-roadmap-dashboard-retired.sh gh568-releases-md-retired.sh gh646-status-label.sh"
    27	SUBSYSTEM_TESTS_telemetry="xyz-completion.sh gh358-lock-instrumentation.sh archive-telemetry.sh gh496-telemetry-isolation.sh"
    28	SUBSYSTEM_TESTS_ate="ate-run-variations.sh gh298-ate-gen4-ci-smoke.sh gh-gen4-phase1-domain-oracles.sh gh-gen4-phase2-adaptive-ate.sh gh-gen4-phase3-fuzz-engine.sh gh-gen4-phase4-repro-synth.sh gh-gen4-phase5-campaign.sh gh478-runaway-guard.sh gh712-jev-triage.sh synthetic/gh102-telemetry-schema.sh gh142-ate-exit-contract.sh"
    29	SUBSYSTEM_TESTS_swe_diagram="swe-diagram.sh"
    30	SUBSYSTEM_TESTS_pdda="gh649-pdda-migration.sh pdda-changelog.sh pdda-install-startup-docs.sh pdda-roadmap-coverage.sh pdda-repo-contract.sh pdda-local-checks.sh gh400-acceptance-fidelity.sh gh400-source-url.sh gh422-backfill-source-url.sh gh425-source-url-slug.sh wave-reconcile.sh gh202-wave-reconcile-issue-state.sh gh232-wave-reconcile-multiphase.sh gh358-wave-reconcile-vendored-paths.sh gh496-phase2-reconciliation-views.sh"
    31	SUBSYSTEM_TESTS_agent_chorus="agent-chorus.sh agent-chorus-bridge.sh gh233-agent-chorus-concurrency.sh"
    32	SUBSYSTEM_TESTS_standup="gh77-standup-triage.sh"
    33	SUBSYSTEM_TESTS_skills_army_hq="skills-army-hq.sh gh620-skills-army-mini-sync.sh gh589-xyz-mini-sync.sh gh589-consult-no-tick.sh gh589-skill-viewer.sh"
    34	# GH-831 D2: Small — the PDDA and PRS (releases/reconcile) suites plus the canaries. The hosted
    35	# reconcile qualifies a tier-1 landing with `validate.sh --sequential --subsystem small`, and
   120	out="$(probe --tier 1)"
   121	ok "--tier 1 print-mode names tier 1 and disclaims promotion evidence" \
   122	   "printf '%s' \"\$out\" | grep 'tier 1' >/dev/null"
   123	
   124	out="$(probe --subsystem hq)"
   125	ok "--subsystem hq selects tier 2 and names the subsystem" \
   126	   "printf '%s' \"\$out\" | grep 'tier 2 — subsystem hq' >/dev/null"
   127	rc=0; out="$(bash "$V" --subsystem nope --print-mode 2>&1)" || rc=$?
   128	ok "an unknown subsystem is refused (exit 2)" "[ $rc -eq 2 ]"
   129	
   130	# PR #55 review, finding 1: --tier N alongside a selector is legal as CONFIRMATION (this is
   131	# the exact spelling ROUTER.md documents) and an error as a contradiction.
   132	out="$(probe --tier 2 --subsystem hq)"; rc=$?
   133	ok "--tier 2 --subsystem hq (the ROUTER.md example) works (rc=$rc)" \
   134	   "[ $rc -eq 0 ] && printf '%s' \"\$out\" | grep 'tier 2 — subsystem hq' >/dev/null"
   135	rc=0; out="$(bash "$V" --print-mode --tier 1 --subsystem hq 2>&1)" || rc=$?
   136	ok "a CONTRADICTING --tier 1 --subsystem hq is refused (exit 2)" "[ $rc -eq 2 ]"
   137	ok "  and the error says which tier the selector chose" \
   138	   "printf '%s' \"\$out\" | grep 'contradicts the selector' >/dev/null"
   139	
   140	# ── (4) the registry drift guard — the releases-skill lesson as a test ───────────────────────────
   141	# Every registered suite must (a) exist in test/ and (b) be registered in validate.sh's TESTS,
   142	# or `--tier 2` would "pass" by running nothing. ci-route.sh's own listing check covers (a);
   143	# THIS covers (b), which nothing else can see.
   144	tests_blob="$(sed -n '/^TESTS=(/,/^)/p' "$V")"
   145	reg_lines="$(bash "$ROUTER" subsystems | cut -f2 | tr ' ' '\n')"
   146	[ -n "$reg_lines" ] || { echo "  FAIL: registry listing came back empty"; fail=$((fail+1)); }
   147	_drift=""
   148	while read -r t; do
   149	  [ -n "$t" ] || continue
   150	  grep -q "\"$t\"" <<<"$tests_blob" || _drift="$_drift $t"
   151	done <<<"$reg_lines"
   152	ok "every registered suite is in validate.sh's TESTS array (drift: '${_drift:-none}')" \
   153	   "[ -z \"\$_drift\" ]"
   154	
   155	# The loud half: a registry naming a suite missing from disk must refuse to list, not skip.
   156	# Layout mirrors a real checkout (ci-route.sh resolves ROOT/test relative to its own location),
   157	# and every REAL suite is present so the only missing one — the one the error must name — is
   158	# the ghost.
   159	DRIFT_ROOT="$WORK/drift"; DRIFT_DIR="$DRIFT_ROOT/utils"
   160	mkdir -p "$DRIFT_DIR" "$DRIFT_ROOT/test"
   161	require_fixture "$DRIFT_ROOT" "drift registry root"
   162	bash "$ROUTER" subsystems | cut -f2 | tr ' ' '\n' | while IFS= read -r _t; do
   163	  # GH-831: a registered suite may live in a subdirectory (synthetic/gh102-telemetry-schema.sh).
   164	  [ -n "$_t" ] && mkdir -p "$(dirname "$DRIFT_ROOT/test/$_t")" && : > "$DRIFT_ROOT/test/$_t"
   165	done
   166	cp "$ROUTER" "$DRIFT_DIR/ci-route.sh"
   167	sed 's/^SUBSYSTEM_TESTS_ate="\(.*\)"$/SUBSYSTEM_TESTS_ate="\1 ghost-suite.sh"/' \
   168	  "$DRIFT_DIR/ci-route.sh" > "$DRIFT_DIR/ci-route.sh.new" && mv "$DRIFT_DIR/ci-route.sh.new" "$DRIFT_DIR/ci-route.sh"
   169	chmod +x "$DRIFT_DIR/ci-route.sh"
   170	rc=0; out="$(bash "$DRIFT_DIR/ci-route.sh" subsystems 2>&1)" || rc=$?
   171	ok "a registered suite missing from test/ fails the listing loudly (exit 2)" "[ $rc -eq 2 ]"
   172	ok "  and names the ghost suite" "printf '%s' \"\$out\" | grep 'ghost-suite.sh' >/dev/null"
   173	
   174	# ── (5) tier-1 execution: the docs gate, dispatched for real against a fixture ────────────────────
   175	# Real validate.sh + real classifier; stubbed PDDA gates (what tier 1 runs is pdda.sh's decision,
   176	# which has its own suites — here we pin the DISPATCH, not PDDA's internals).
   177	mkfixture() {  # -> prints fixture repo path
   178	  local r
   179	  r="$(mktemp -d "$WORK/repo.XXXXXX")"
   180	  require_fixture "$r" "mkfixture repo"
  1335	  rt_emit stage non-suite "telemetry-merge" "$RT_DISPATCH_MS" "$(rt_now_ms)" 0 "merged_malformed=$_merge"
  1336	
  1337	  # Every failure is RE-RUN SEQUENTIALLY before it is believed, with the pool drained and the lock
  1338	  # lane finished — so the driver lock is free and nothing else is competing for CPU.
  1339	  #
  1340	  # This exists because the lane list above cannot be verified by reading it. A suite that merely
  1341	  # *touches* a driver contends, and its refusal surfaces as whatever assertion happened to be
  1342	  # downstream — for gh322 that was a parity mismatch naming two exit codes, which reads exactly like
  1343	  # a real product bug. Without this pass, an incomplete lane list makes `--parallel` report failures
  1344	  # that sequential does not have, which would destroy the one property the flag is supposed to have:
  1345	  # the same answer as the sequential gate, faster. A suite that fails here and passes alone is not
  1346	  # "flaky" and is not dismissed — it is named as contention on a shared resource (a lane-list gap)
  1347	  # to fix, and NEVER counted as a failed run (GH-15).
  1348	  #
  1349	  # GH-15: two ways this pass was observed NOT honoring that contract, both fixed here.
  1350	  # (1) The serial re-run inherited THIS LOOP'S stdin — which is $RESULTS itself. A re-run suite
  1351	  #     that merely read stdin therefore swallowed every result line after it: the failures those
  1352	  #     lines recorded were never re-run, never reported, and the run exited GREEN with a short
  1353	  #     summary ("passed: 3 / 5" with a suite that always fails silently uncounted — reproduced
  1354	  #     deterministically in the GH-15 investigation). The re-run now gets </dev/null, which is
  1355	  #     ALSO the pool's stdin regime (xargs hands its workers /dev/null), so the re-run is the
  1356	  #     same experiment as the pooled attempt instead of a second, different one.
  1357	  # (2) A suite whose worker died without writing a result line was uncounted everywhere: neither
  1358	  #     re-run nor reported. The completeness catch-up below gives a missing line the same
  1359	  #     treatment as a nonzero rc — re-run alone before believing anything.
  1360	  CONTENDED=()
  1361	  vp_rerun_alone() {  # <suite> <why> [rc_first] — classify one suite by its ALONE verdict; never by the pool's
  1362	    local t="$1" why="$2" rc_first="${3:-1}" log _s _e rc_alone
  1363	    log="$RUN_DIR/$(printf '%s' "$t" | tr '/' '_').log"
  1364	    echo
  1365	    echo "==============================="
  1366	    echo "$why: $t — re-running it alone to see if that verdict survives"
  1367	    echo "==============================="
  1368	    _s="$(rt_now_ms)"
  1369	    if $NICE_CMD bash "$HERE/test/$t" > "$log.serial" 2>&1 </dev/null; then
  1370	      rc_alone=0
  1371	      PASSED+=("$t")
  1372	      CONTENDED+=("$t")
  1373	      echo "  ... PASSES when run alone. Counting it as passed (sequential is the source of truth)."
  1374	      echo "  ... This means a shared resource is contended — see the warning at the end of this run."
  1375	      rt_emit retry retry "$t" "$_s" "$(rt_now_ms)" "$rc_alone" "rc_first=$rc_first" "classified=contended"
  1376	      rt_suite retry "$t" "$_s" "$(rt_now_ms)" "$rc_alone" "$log.serial"
  1377	    else
  1378	      rc_alone=$?
  1379	      FAILED+=("$t")
  1380	      echo "  ... fails alone too. Real failure; last 40 lines of the SERIAL run:"
  1381	      tail -40 "$log.serial"
  1382	      rt_emit retry retry "$t" "$_s" "$(rt_now_ms)" "$rc_alone" "rc_first=$rc_first" "classified=real-failure"
  1383	      rt_suite retry "$t" "$_s" "$(rt_now_ms)" "$rc_alone" "$log.serial"
  1384	    fi
  1385	  }
  1386	  while IFS=' ' read -r rc t; do
  1387	    if [ "$rc" = "0" ]; then
  1388	      PASSED+=("$t")
  1389	      continue
  1390	    fi
zsh:1: no matches found: PROJECT/2-WORKING/GH-854*

exec
/bin/zsh -lc "nl -ba test/gh35-test-tiers.sh | sed -n '124,151p'; nl -ba validate.sh | sed -n '1555,1587p'; rg -n 'completion|909|910' validate.sh | tail -12; nl -ba .github/workflows/ci.yml | sed -n '486,497p'" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-16535-02sbwo67
 succeeded in 0ms:
   124	out="$(probe --subsystem hq)"
   125	ok "--subsystem hq selects tier 2 and names the subsystem" \
   126	   "printf '%s' \"\$out\" | grep 'tier 2 — subsystem hq' >/dev/null"
   127	rc=0; out="$(bash "$V" --subsystem nope --print-mode 2>&1)" || rc=$?
   128	ok "an unknown subsystem is refused (exit 2)" "[ $rc -eq 2 ]"
   129	
   130	# PR #55 review, finding 1: --tier N alongside a selector is legal as CONFIRMATION (this is
   131	# the exact spelling ROUTER.md documents) and an error as a contradiction.
   132	out="$(probe --tier 2 --subsystem hq)"; rc=$?
   133	ok "--tier 2 --subsystem hq (the ROUTER.md example) works (rc=$rc)" \
   134	   "[ $rc -eq 0 ] && printf '%s' \"\$out\" | grep 'tier 2 — subsystem hq' >/dev/null"
   135	rc=0; out="$(bash "$V" --print-mode --tier 1 --subsystem hq 2>&1)" || rc=$?
   136	ok "a CONTRADICTING --tier 1 --subsystem hq is refused (exit 2)" "[ $rc -eq 2 ]"
   137	ok "  and the error says which tier the selector chose" \
   138	   "printf '%s' \"\$out\" | grep 'contradicts the selector' >/dev/null"
   139	
   140	# ── (4) the registry drift guard — the releases-skill lesson as a test ───────────────────────────
   141	# Every registered suite must (a) exist in test/ and (b) be registered in validate.sh's TESTS,
   142	# or `--tier 2` would "pass" by running nothing. ci-route.sh's own listing check covers (a);
   143	# THIS covers (b), which nothing else can see.
   144	tests_blob="$(sed -n '/^TESTS=(/,/^)/p' "$V")"
   145	reg_lines="$(bash "$ROUTER" subsystems | cut -f2 | tr ' ' '\n')"
   146	[ -n "$reg_lines" ] || { echo "  FAIL: registry listing came back empty"; fail=$((fail+1)); }
   147	_drift=""
   148	while read -r t; do
   149	  [ -n "$t" ] || continue
   150	  grep -q "\"$t\"" <<<"$tests_blob" || _drift="$_drift $t"
   151	done <<<"$reg_lines"
  1555	# GH-732 timing summary BEGIN — controlled GH-365 JSONL fields, no new telemetry.
  1556	# Only suite events: each retry also emits event=retry, which must not double its cost.
  1557	if [ -n "${RT_FILE:-}" ] && [ -s "$RT_FILE" ]; then
  1558	  awk '
  1559	    function field(key, value) {
  1560	      if (!match($0, "\"" key "\"[[:space:]]*:[[:space:]]*\"?[^,}\"]+")) return ""
  1561	      value = substr($0, RSTART, RLENGTH)
  1562	      sub(/^[^:]*:[[:space:]]*"?/, "", value)
  1563	      return value
  1564	    }
  1565	    field("event") == "suite" {
  1566	      lane = field("lane"); name = field("name")
  1567	      ms = field("duration_ms"); rc = field("rc")
  1568	      if (name == "" || ms !~ /^[0-9]+$/ || rc !~ /^[0-9]+$/) next
  1569	      if (lane == "retry") {
  1570	        retry_ms += ms
  1571	        if (!retried[name]++) retry_count++
  1572	      } else if (lane ~ /^(pool|driver-lock|sequential)$/ && !seen[name]++) {
  1573	        print ms, name, rc
  1574	      }
  1575	    }
  1576	    END { print -1, retry_count + 0, retry_ms + 0 }
  1577	  ' "$RT_FILE" 2>/dev/null | LC_ALL=C sort -k1,1nr -k2,2 | awk '
  1578	    BEGIN { print "10 slowest suites:"; print "  name  duration_s  rc" }
  1579	    $1 == -1 { printf "re-run ladder: %d suite(s), %.3fs total\n", $2, $3 / 1000; next }
  1580	    ++rows <= 10 { printf "  %s  %.3f  %s\n", $2, $1 / 1000, $3 }
  1581	  ' || :
  1582	fi
  1583	# GH-732 timing summary END
  1584	if [ -n "$XYZ_ENV_FAULTS" ]; then
  1585	  echo "ENVIRONMENT FAULTS (GH-732): $XYZ_ENV_FAULTS — this run is NOT promotion evidence."
  1586	fi
  1587	if [ "${#SKIPPED_SUITES[@]}" -gt 0 ]; then
198:  "litmus-release.sh"            # Litmus 0.2.0 frozen-manifest audit. Suite mode fails ONLY on a false completion claim (a CLOSED manifest issue whose gate is missing/unregistered/undeclared); remaining work is INFO. The goalpost itself is `--release-gate` (red until done). Control: `--mutate-evidence` 9/0 — NOT run by this suite; run it by hand when touching audit_entry
254:  "nightwatch-release.sh"        # Nightwatch 0.3.0 frozen-manifest goalpost. Suite mode fails ONLY on a false completion claim (a CLOSED manifest issue whose gate is missing/unregistered/uncontrolled) or a disagreement with RELEASES.md; remaining work is INFO. The goalpost itself is `--release-gate` (red until done, and it EXECUTES the lifecycle suites rather than auditing them). Control: `--mutate-evidence` 34/0 — NOT run by this suite; run it by hand when touching audit_manifest
261:  "meter-release.sh"             # Meter 0.6.0 PUBLIC-LAUNCH goalpost (RE-POINTED 2026-08-15; the metering manifest moved to Sundown). Suite mode fails ONLY on a false completion claim (a CLOSED manifest issue whose gate is missing/unregistered/uncontrolled) or a ledger disagreement; remaining work is INFO. The goalpost itself is `--release-gate` (red until the sanitized artifact exists AND a credential-free clone completes the documented happy path; the artifact is named by XYZ_LAUNCH_ARTIFACT). Membership is read from RELEASES.md's machine-readable `Manifest-Members:` field and compared in BOTH directions — the prose `Manifest:` paragraph names RETIRED members and must never be parsed, which is the defect that made the pre-2026-08-15 version report a false GOALPOST MET. Control: `--mutate-evidence` — NOT run by this suite; run it by hand when touching audit_artifact or the cross-check
262:  "ballast-release.sh"           # Ballast 0.7.0 POST-LAUNCH-HARDENING goalpost — the launched repo holds up under a stranger's first run and an outside contributor's first push. Suite mode fails ONLY on a false completion claim or a ledger disagreement; remaining work is INFO. The goalpost itself is `--release-gate` (red until every manifest member — #14 #15 #4 #3, post-#10-cut — is complete AND the stranger's path is executed fresh in a clone named by XYZ_BALLAST_STRANGER_CLONE: ten consecutive parallel runs, an ungated clone's in-band warning, a forced-red push refused, and #14's cross-process stress case). Control: `--mutate-evidence` 7/0 — NOT run by this suite; run it by hand when touching audit_manifest or the cross-check
579:  "xyz-completion.sh"
   486	      - name: Run validate.sh suite (minus a documented flaky test)
   487	        if: steps.route.outputs.route == 'full'
   488	        env:
   489	          RELAY_SELF_SUFFICIENCY_SKIP: "1"
   490	        run: |
   491	          set -euo pipefail
   492	          ./validate.sh --parallel 6 \
   493	            --skip acorn-extract.sh \
   494	            --skip registry-lock-concurrency.sh \
   495	            --skip pdda-repo-contract.sh
   496	
   497	      # GH-509 Phase 2 — the canary's verdict, written where a human and a script can both find it.

codex
(1) **ANSWER:** Proceed with this narrow disposition. I found no implementation blocker at the stated base; three small clarifications would make execution and acceptance precise. Source review only; no tests or mutations performed.

(2) **FINDINGS**

- **[Should] Include existing `gh35-test-tiers.sh` in focused verification.** It checks subsystem membership against `validate.sh` registrations—the exact contract affected by removing the oracle from ATE. `ci-route.sh` alone is not that check. See `test/gh35-test-tiers.sh:140–150`.
- **[Should] Define “zero-retry” acceptance explicitly.** The unchanged parallel runner automatically reruns pooled failures and counts a successful rerun as passed (`validate.sh:1337–1375`). Both fresh development runs must have **zero retry activity**, as well as no failure or drift; exit 0 alone cannot establish this. Inspect existing receipts/transcripts; no runner changes are needed.
- **[Should] Update adjacent workflow prose and the step title.** `.github/workflows/ci.yml:452–457` still says registry concurrency remains skipped as a documented Linux flake; line 486 calls the step “minus a documented flaky test.” Those become misleading after removing its skip. Cite the deferred disposition without asserting a proven cause.
- **[Pass] Registry and downstream edits are coherent.** The base contains 410 registrations, including exactly these two targets. Existing exemption checks require retained files and reject double registration (`test/gh306-registry-bidirectional.sh:130–148`). Removing the obsolete local-run assertion at `test/ci-workflow.sh:429–433` is appropriate.
- **[Pass] GH-379 needs no assertion replacement.** Its canary grammar permits a variable number of skips, and its registration check will correctly reject a leftover registry skip (`test/gh379-canary-uses-validate.sh:201–228,272–286`).
- **[Pass] Scope preserves the landed completion regression suite:** `xyz-completion.sh` remains registered at `validate.sh:579`. Historical root-cause investigation remains deferred and outside this implementation.

(3) **RECOMMENDATION:** Execute the approved plan with these small additions, then prepare the ready PR for operator approval at landing.
tokens used
67,797
(1) **ANSWER:** Proceed with this narrow disposition. I found no implementation blocker at the stated base; three small clarifications would make execution and acceptance precise. Source review only; no tests or mutations performed.

(2) **FINDINGS**

- **[Should] Include existing `gh35-test-tiers.sh` in focused verification.** It checks subsystem membership against `validate.sh` registrations—the exact contract affected by removing the oracle from ATE. `ci-route.sh` alone is not that check. See `test/gh35-test-tiers.sh:140–150`.
- **[Should] Define “zero-retry” acceptance explicitly.** The unchanged parallel runner automatically reruns pooled failures and counts a successful rerun as passed (`validate.sh:1337–1375`). Both fresh development runs must have **zero retry activity**, as well as no failure or drift; exit 0 alone cannot establish this. Inspect existing receipts/transcripts; no runner changes are needed.
- **[Should] Update adjacent workflow prose and the step title.** `.github/workflows/ci.yml:452–457` still says registry concurrency remains skipped as a documented Linux flake; line 486 calls the step “minus a documented flaky test.” Those become misleading after removing its skip. Cite the deferred disposition without asserting a proven cause.
- **[Pass] Registry and downstream edits are coherent.** The base contains 410 registrations, including exactly these two targets. Existing exemption checks require retained files and reject double registration (`test/gh306-registry-bidirectional.sh:130–148`). Removing the obsolete local-run assertion at `test/ci-workflow.sh:429–433` is appropriate.
- **[Pass] GH-379 needs no assertion replacement.** Its canary grammar permits a variable number of skips, and its registration check will correctly reject a leftover registry skip (`test/gh379-canary-uses-validate.sh:201–228,272–286`).
- **[Pass] Scope preserves the landed completion regression suite:** `xyz-completion.sh` remains registered at `validate.sh:579`. Historical root-cause investigation remains deferred and outside this implementation.

(3) **RECOMMENDATION:** Execute the approved plan with these small additions, then prepare the ready PR for operator approval at landing.
