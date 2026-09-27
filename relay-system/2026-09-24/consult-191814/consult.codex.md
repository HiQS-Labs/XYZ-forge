**NO FIRSTHAND VERIFICATION CITED** — treat conclusions as conditional (codex's answer carries an unsupported [Pass]/verified/confirmed-style claim with no quoted span or file:line citation nearby, despite the consult PREAMBLE asking advisors to cite evidence.)

> **ATTESTATION**
> Model: gpt-6-astra
> Provider: openai
> Sandbox: read-only

Reading additional input from stdin...
OpenAI Codex v0.153.4
--------
workdir: /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-82909-ltrglyj2
model: gpt-6-astra
provider: openai
approval: never
sandbox: read-only
reasoning effort: low
reasoning summaries: none
session id: 01a0d65b-335f-74b1-b8c6-945b8c669555
--------
user
You are an INDEPENDENT advisor in a one-shot cross-model consult. Another model is answering the SAME question separately and a coordinator will reconcile both answers, so give your own honest, specific read — do not hedge toward a consensus you cannot see. Read any repo files the question references (cite file:line). Respond with: (1) a short direct ANSWER; (2) graded FINDINGS — [Blocker]/[Should]/[Nit]/[Pass] — where applicable; (3) a one-line RECOMMENDATION. You are ADVISORY ONLY: output your analysis as text; do not rely on writing files (you are running in a throwaway copy).

=== CONSULT QUESTION ===
Review the diff in HEAD for GH-804 (simplifying test/gh798-status-skill.sh and adding capture doc). Does this commit cleanly achieve GH-804 goals, retain all essential installer safety checks and falsification negative controls, and maintain clean gate compliance without regressions or overengineering?
warning: Skill descriptions were shortened to fit the skills context budget. Codex can still see every skill, but some descriptions are shorter. Disable unused skills or plugins to leave more room for the rest.
codex
I’ll read the HEAD diff and its surrounding test contract, then assess safety coverage and gate compliance without modifying the checkout.
exec
/bin/zsh -lc 'pwd; git show --stat --oneline HEAD; cat ROUTER.md' in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-82909-ltrglyj2
 succeeded in 4682ms:
2026-09-24 19:18:27.020 xcodebuild[94077:150515038]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-09-24 19:18:27.532 xcodebuild[94077:150514967] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.
git: warning: confstr() failed with code 5: couldn't get path of DARWIN_USER_TEMP_DIR; using /tmp instead
git: error: couldn't create cache file '/tmp/xcrun_db-72XQZrOh' (errno=Operation not permitted)
2026-09-24 19:18:28.667 xcodebuild[94788:150518765]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-09-24 19:18:28.934 xcodebuild[94788:150518685] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.
cf10847d feat(test): simplify GH-798 status skill tests and consolidate prose checks (refs #804)
 LEADERBOARD.md                                     |  75 +++++++++++----------
 ...SKILL-INSTRUCTION-TESTS-INTRODUCED-BY-GH-798.md |  48 +++++++++++++
 releases.db                                        | Bin 983040 -> 987136 bytes
 releases.sql                                       |   9 ++-
 test/gh798-status-skill.sh                         |  54 ++-------------
 5 files changed, 98 insertions(+), 88 deletions(-)
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
6. Before reporting success on code or runtime work, check that the same `python3` used by the gate imports `requests`, `yaml` (PyYAML), and `pytest`, then run `./validate.sh`. -> expect the suite to stay green; do not claim completion if it fails or was skipped.
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
./validate.sh --sequential # force the sequential run (see the hook’s measured GREEN in Ns line)
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
agent-chorus, standup, skills-army-hq); a push the classifier rates `tier=2` runs only those focused
suites at the boundary, `--tier 1` runs the docs gate, and everything else — unknown paths, unclaimed
test edits, kernel surfaces — runs the full suite. `--auto` classifies a local diff the same way.
Tiers 1 and 2 are pre-push speed and are labelled NOT promotion evidence; only `ci-local.sh`'s
sequential full run qualifies (GH-509).

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

mcp: codebase-memory-mcp/list_projects started
mcp: codebase-memory-mcp/list_projects (completed)
exec
/bin/zsh -lc 'git show HEAD -- test/gh798-status-skill.sh PROJECT/1-INBOX releases.sql LEADERBOARD.md; cat GUIDING-PRINCIPLES.md PROJECT/PDDA.md TESTS-RESULTS/README.md; cat /Users/noelsaw/.codex/skills/review-code/SKILL.md' in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-82909-ltrglyj2
 succeeded in 2861ms:
2026-09-24 19:18:35.210 xcodebuild[98888:150531520]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-09-24 19:18:35.485 xcodebuild[98888:150531465] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.
git: warning: confstr() failed with code 5: couldn't get path of DARWIN_USER_TEMP_DIR; using /tmp instead
git: error: couldn't create cache file '/tmp/xcrun_db-fXlgYkzb' (errno=Operation not permitted)
2026-09-24 19:18:36.182 xcodebuild[99581:150533358]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-09-24 19:18:36.426 xcodebuild[99581:150533262] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.
commit cf10847d0e6ee90f6bcdcc23eaa94daedea4859b
Author: Noel Saw <56978803+noelsaw1@users.noreply.github.com>
Date:   Thu Sep 24 19:17:55 2026 -0700

    feat(test): simplify GH-798 status skill tests and consolidate prose checks (refs #804)

diff --git a/LEADERBOARD.md b/LEADERBOARD.md
index 629f340d..b8858c2e 100644
--- a/LEADERBOARD.md
+++ b/LEADERBOARD.md
@@ -1,4 +1,4 @@
-<!-- releases-app generation: 1132 -->
+<!-- releases-app generation: 1134 -->
 <!-- GENERATED by utils/leaderboard.sh from releases.db — do not hand-edit. -->
 
 # Leaderboard
@@ -215,42 +215,43 @@ while the four axes keep their honest values underneath.
 | 202 | **195** | [GH-487](https://github.com/HiQS-Labs/XYZ-forge/issues/487) — ci: make new-branch skill/test pushes use bounded gates and clarify draft-review bypass | — | Completed | 55 | 30 | 50 | 60 | 195 | — |
 | 203 | **195** | [GH-549](https://github.com/HiQS-Labs/XYZ-forge/issues/549) — Work-state event stream + concurrent connectors: GitHub Kanban first, HQ and Flightdeck next | — | Completed | 70 | 50 | 50 | 25 | 195 | — |
 | 204 | **195** | [GH-561](https://github.com/HiQS-Labs/XYZ-forge/issues/561) — merge-cleanup: gate-run disposable clones preserved forever (telemetry-only .tick/ unverifiable) | — | Completed | 50 | 30 | 50 | 65 | 195 | — |
-| 205 | **193** | [GH-536](https://github.com/HiQS-Labs/XYZ-forge/issues/536) — relocate: Deployed Skills moves INTO the live Git Pulse Sync checkout (supersedes #508 verdict) | — | Completed | 65 | 38 | 50 | 40 | 193 | — |
-| 206 | **193** | [GH-642](https://github.com/HiQS-Labs/XYZ-forge/issues/642) — Low-hanging fruit from two foreign-repo marathons: make the consumer-repo SOP turnkey | — | Completed | 60 | 35 | 50 | 48 | 193 | — |
-| 207 | **190** | [GH-39](https://github.com/HiQS-Labs/XYZ-forge/issues/39) — RELEASES app: one-way GitHub Project release-card projection | — | Completed | 50 | 30 | 65 | 45 | 190 | — |
-| 208 | **190** | [GH-522](https://github.com/HiQS-Labs/XYZ-forge/issues/522) — Continuous issue admission into Jog/Marathon proposals | — | Queue / parked intake | 55 | 30 | 50 | 55 | 190 | — |
-| 209 | **190** | [GH-61](https://github.com/HiQS-Labs/XYZ-forge/issues/61) — RELEASES ledger durability hardening (GH-57 follow-up) | — | Queue / parked intake | 45 | 55 | 40 | 50 | 190 | — |
-| 210 | **185** | [GH-17](https://github.com/HiQS-Labs/XYZ-forge/issues/17) — SOP for evaluating new agent harnesses and frontier models | — | Queue / parked intake | 45 | 30 | 50 | 60 | 185 | — |
-| 211 | **185** | [GH-42](https://github.com/HiQS-Labs/XYZ-forge/issues/42) — relay automation: supported Commandcode turn-taker | — | Completed | 50 | 35 | 55 | 45 | 185 | — |
-| 212 | **185** | [GH-620](https://github.com/HiQS-Labs/XYZ-forge/issues/620) — XYZ Skills Army mini and reusable spin-off recipe | — | Completed | 65 | 25 | 50 | 45 | 185 | — |
-| 213 | **185** | [GH-661](https://github.com/HiQS-Labs/XYZ-forge/issues/661) — fix(containment): relative relay-file initialization can grant reviewers builder write scope | — | Completed | 20 | 20 | 50 | 95 | 185 | — |
-| 214 | **175** | [GH-101](https://github.com/HiQS-Labs/XYZ-forge/issues/101) — Feasibility Study: Promoting Programmatic Script Runner (`script_runner.py`) into Core Relay & Consult Runtimes | — | Completed | 45 | 20 | 70 | 40 | 175 | — |
-| 215 | **175** | [GH-744](https://github.com/HiQS-Labs/XYZ-forge/issues/744) — skills: organize skills/ into frequency-of-use tier folders (1-hourly, 2-daily, 3-weekly, 4-occasional) | — | Completed | 55 | 25 | 50 | 45 | 175 | — |
-| 216 | **175** | [GH-94](https://github.com/HiQS-Labs/XYZ-forge/issues/94) — research: programmatic tool calling & code-mode execution for harnesses, telemetry, and containment | — | Completed | 45 | 20 | 70 | 40 | 175 | — |
-| 217 | **170** | [GH-195](https://github.com/HiQS-Labs/XYZ-forge/issues/195) — marathon-root-audit's blind spot: a direct `python3 marathon_drive.py` call | — | Completed | 60 | 40 | 50 | 20 | 170 | — |
-| 218 | **170** | [GH-28](https://github.com/HiQS-Labs/XYZ-forge/issues/28) — RELEASES.md ledger discipline: deterministic bloat checks + per-release tracking issue | — | Queue / parked intake | 40 | 35 | 40 | 55 | 170 | — |
-| 219 | **170** | [GH-589](https://github.com/HiQS-Labs/XYZ-forge/issues/589) — Build XYZ mini: beginner-friendly stripped repo (relay, consult, agent-chorus, skill viewer) | — | Queue / parked intake | 55 | 25 | 50 | 40 | 170 | — |
-| 220 | **160** | [GH-18](https://github.com/HiQS-Labs/XYZ-forge/issues/18) — Harness evaluation: Command Code (cmd) and model matrix | — | Queue / parked intake | 35 | 25 | 45 | 55 | 160 | — |
-| 221 | **91** | [GH-533](https://github.com/HiQS-Labs/XYZ-forge/issues/533) — Relay scaffold verdict vocabulary contradicts validate-relay-block | — | Completed | 94 | 90 | 92 | 88 | 364 | 91 |
-| 222 | **89** | [GH-554](https://github.com/HiQS-Labs/XYZ-forge/issues/554) — tick mutating verbs silently accept unknown flags | — | Completed | 90 | 86 | 88 | 92 | 356 | 89 |
-| 223 | **88** | [GH-529](https://github.com/HiQS-Labs/XYZ-forge/issues/529) — Relay attestation rejects scaffold-required marker placement | — | Completed | 92 | 88 | 90 | 82 | 352 | 88 |
-| 224 | **83** | [GH-555](https://github.com/HiQS-Labs/XYZ-forge/issues/555) — merge-cleanup B1 leaves releases.db.bak after resolution | — | Completed | 82 | 74 | 80 | 94 | 330 | 83 |
-| 225 | **12** | [GH-267](https://github.com/HiQS-Labs/XYZ-forge/issues/267) — /express: hotfix fast lane — fix + suite + ledger + born-complete docs + gateless development landing + reconcile | Cargo | completed | 3 | 3 | 3 | 3 | 12 | — |
-| 226 | **12** | [GH-325](https://github.com/HiQS-Labs/XYZ-forge/issues/325) — Vendor legacy SWE skills and make skills/ canonical | — | In progress | 3 | 3 | 3 | 3 | 12 | — |
-| 227 | **9** | [GH-399](https://github.com/HiQS-Labs/XYZ-forge/issues/399) — Let the profile carry the route | — | Queue / parked intake | 2 | 3 | 2 | 2 | 9 | — |
-| 228 | **8** | [GH-256](https://github.com/HiQS-Labs/XYZ-forge/issues/256) — No preflight checks the builder can reach a phase artifact paths | Cargo | queue | 3 | 2 | 2 | 1 | 8 | — |
-| 229 | **8** | [GH-508](https://github.com/HiQS-Labs/XYZ-forge/issues/508) — Git Sync Pulse as a portable Skills Army HQ projection | — | Completed | 2 | 3 | 2 | 1 | 8 | — |
-| 230 | **8** | [GH-608](https://github.com/HiQS-Labs/XYZ-forge/issues/608) — fix(relay): honor Qwen/DeepSeek reasoning effort and correct false idle timeout attribution | Cargo | completed | 2 | 2 | 2 | 2 | 8 | — |
-| 231 | **8** | [GH-654](https://github.com/HiQS-Labs/XYZ-forge/issues/654) — Marathon containment exit-6 discards completed builder work; rtl_worktree_end records no off-lane path list — blocks GH-648 phase p1 (2/2 codex turns) | Cargo | completed | 2 | 2 | 2 | 2 | 8 | — |
-| 232 | **8** | [GH-658](https://github.com/HiQS-Labs/XYZ-forge/issues/658) — Containment allowlist stores the ABSOLUTE relay_file path — worktree-relative porcelain can never match it, so every instructed relay-file edit trips exit-6 (root cause of #654) | Cargo | completed | 2 | 2 | 2 | 2 | 8 | — |
-| 233 | **8** | [GH-659](https://github.com/HiQS-Labs/XYZ-forge/issues/659) — rtl_init splits allow_csv with bare IFS=',' — no trim, so every artifact AFTER THE FIRST in a "a, b, c" allowlist is invisible to containment (reproduced; root cause #2 of #654) | Cargo | completed | 2 | 2 | 2 | 2 | 8 | — |
-| 234 | **8** | [GH-660](https://github.com/HiQS-Labs/XYZ-forge/issues/660) — Deployed-skills drift: express SKILL.md hot-fixed directly in the vendored collection (git-pulse-sync) instead of re-vendoring from canonical skills/express — deployed copy missing GH-592 resume recipe | Cargo | completed | 2 | 2 | 2 | 2 | 8 | — |
-| 235 | **8** | [GH-663](https://github.com/HiQS-Labs/XYZ-forge/issues/663) — QA findings (agy relay review) on the GH-654/658/659/660 hotfix chain: turn_prompt csv leak, drift-check CLI ambiguity + CRLF false positives, offlane rename-source omission | Cargo | queue | 2 | 2 | 2 | 2 | 8 | — |
-| 236 | **4** | [GH-255](https://github.com/HiQS-Labs/XYZ-forge/issues/255) — marathon-drive blocked-before-dispatch refusal omits XYZ_ARCHIVE_ROOT | Cargo | queue | 1 | 1 | 1 | 1 | 4 | — |
-| 237 | **4** | [GH-406](https://github.com/HiQS-Labs/XYZ-forge/issues/406) — External review (Russ K.): eight findings on guards that cover a narrower path than the doc claims | — | Queue / parked intake | 3 | 3 | 4 | 3 | 13 | 4 |
-| 238 | **4** | [GH-410](https://github.com/HiQS-Labs/XYZ-forge/issues/410) — relay-block validator never runs on the driven path | Front-Door | completed | 95 | 80 | 90 | 40 | 305 | 4 |
-| 239 | **4** | [GH-412](https://github.com/HiQS-Labs/XYZ-forge/issues/412) — transient claim collision indistinguishable from durable loss | Front-Door | completed | 80 | 75 | 75 | 55 | 285 | 4 |
-| 240 | **4** | [GH-413](https://github.com/HiQS-Labs/XYZ-forge/issues/413) — launch-artifact marker authorises destructive rebuild | Front-Door | completed | 90 | 95 | 85 | 95 | 365 | 4 |
+| 205 | **195** | [GH-804](https://github.com/HiQS-Labs/XYZ-forge/issues/804) — Review and simplify skill instruction tests introduced by GH-798 | — | Queue / parked intake | 40 | 20 | 50 | 85 | 195 | — |
+| 206 | **193** | [GH-536](https://github.com/HiQS-Labs/XYZ-forge/issues/536) — relocate: Deployed Skills moves INTO the live Git Pulse Sync checkout (supersedes #508 verdict) | — | Completed | 65 | 38 | 50 | 40 | 193 | — |
+| 207 | **193** | [GH-642](https://github.com/HiQS-Labs/XYZ-forge/issues/642) — Low-hanging fruit from two foreign-repo marathons: make the consumer-repo SOP turnkey | — | Completed | 60 | 35 | 50 | 48 | 193 | — |
+| 208 | **190** | [GH-39](https://github.com/HiQS-Labs/XYZ-forge/issues/39) — RELEASES app: one-way GitHub Project release-card projection | — | Completed | 50 | 30 | 65 | 45 | 190 | — |
+| 209 | **190** | [GH-522](https://github.com/HiQS-Labs/XYZ-forge/issues/522) — Continuous issue admission into Jog/Marathon proposals | — | Queue / parked intake | 55 | 30 | 50 | 55 | 190 | — |
+| 210 | **190** | [GH-61](https://github.com/HiQS-Labs/XYZ-forge/issues/61) — RELEASES ledger durability hardening (GH-57 follow-up) | — | Queue / parked intake | 45 | 55 | 40 | 50 | 190 | — |
+| 211 | **185** | [GH-17](https://github.com/HiQS-Labs/XYZ-forge/issues/17) — SOP for evaluating new agent harnesses and frontier models | — | Queue / parked intake | 45 | 30 | 50 | 60 | 185 | — |
+| 212 | **185** | [GH-42](https://github.com/HiQS-Labs/XYZ-forge/issues/42) — relay automation: supported Commandcode turn-taker | — | Completed | 50 | 35 | 55 | 45 | 185 | — |
+| 213 | **185** | [GH-620](https://github.com/HiQS-Labs/XYZ-forge/issues/620) — XYZ Skills Army mini and reusable spin-off recipe | — | Completed | 65 | 25 | 50 | 45 | 185 | — |
+| 214 | **185** | [GH-661](https://github.com/HiQS-Labs/XYZ-forge/issues/661) — fix(containment): relative relay-file initialization can grant reviewers builder write scope | — | Completed | 20 | 20 | 50 | 95 | 185 | — |
+| 215 | **175** | [GH-101](https://github.com/HiQS-Labs/XYZ-forge/issues/101) — Feasibility Study: Promoting Programmatic Script Runner (`script_runner.py`) into Core Relay & Consult Runtimes | — | Completed | 45 | 20 | 70 | 40 | 175 | — |
+| 216 | **175** | [GH-744](https://github.com/HiQS-Labs/XYZ-forge/issues/744) — skills: organize skills/ into frequency-of-use tier folders (1-hourly, 2-daily, 3-weekly, 4-occasional) | — | Completed | 55 | 25 | 50 | 45 | 175 | — |
+| 217 | **175** | [GH-94](https://github.com/HiQS-Labs/XYZ-forge/issues/94) — research: programmatic tool calling & code-mode execution for harnesses, telemetry, and containment | — | Completed | 45 | 20 | 70 | 40 | 175 | — |
+| 218 | **170** | [GH-195](https://github.com/HiQS-Labs/XYZ-forge/issues/195) — marathon-root-audit's blind spot: a direct `python3 marathon_drive.py` call | — | Completed | 60 | 40 | 50 | 20 | 170 | — |
+| 219 | **170** | [GH-28](https://github.com/HiQS-Labs/XYZ-forge/issues/28) — RELEASES.md ledger discipline: deterministic bloat checks + per-release tracking issue | — | Queue / parked intake | 40 | 35 | 40 | 55 | 170 | — |
+| 220 | **170** | [GH-589](https://github.com/HiQS-Labs/XYZ-forge/issues/589) — Build XYZ mini: beginner-friendly stripped repo (relay, consult, agent-chorus, skill viewer) | — | Queue / parked intake | 55 | 25 | 50 | 40 | 170 | — |
+| 221 | **160** | [GH-18](https://github.com/HiQS-Labs/XYZ-forge/issues/18) — Harness evaluation: Command Code (cmd) and model matrix | — | Queue / parked intake | 35 | 25 | 45 | 55 | 160 | — |
+| 222 | **91** | [GH-533](https://github.com/HiQS-Labs/XYZ-forge/issues/533) — Relay scaffold verdict vocabulary contradicts validate-relay-block | — | Completed | 94 | 90 | 92 | 88 | 364 | 91 |
+| 223 | **89** | [GH-554](https://github.com/HiQS-Labs/XYZ-forge/issues/554) — tick mutating verbs silently accept unknown flags | — | Completed | 90 | 86 | 88 | 92 | 356 | 89 |
+| 224 | **88** | [GH-529](https://github.com/HiQS-Labs/XYZ-forge/issues/529) — Relay attestation rejects scaffold-required marker placement | — | Completed | 92 | 88 | 90 | 82 | 352 | 88 |
+| 225 | **83** | [GH-555](https://github.com/HiQS-Labs/XYZ-forge/issues/555) — merge-cleanup B1 leaves releases.db.bak after resolution | — | Completed | 82 | 74 | 80 | 94 | 330 | 83 |
+| 226 | **12** | [GH-267](https://github.com/HiQS-Labs/XYZ-forge/issues/267) — /express: hotfix fast lane — fix + suite + ledger + born-complete docs + gateless development landing + reconcile | Cargo | completed | 3 | 3 | 3 | 3 | 12 | — |
+| 227 | **12** | [GH-325](https://github.com/HiQS-Labs/XYZ-forge/issues/325) — Vendor legacy SWE skills and make skills/ canonical | — | In progress | 3 | 3 | 3 | 3 | 12 | — |
+| 228 | **9** | [GH-399](https://github.com/HiQS-Labs/XYZ-forge/issues/399) — Let the profile carry the route | — | Queue / parked intake | 2 | 3 | 2 | 2 | 9 | — |
+| 229 | **8** | [GH-256](https://github.com/HiQS-Labs/XYZ-forge/issues/256) — No preflight checks the builder can reach a phase artifact paths | Cargo | queue | 3 | 2 | 2 | 1 | 8 | — |
+| 230 | **8** | [GH-508](https://github.com/HiQS-Labs/XYZ-forge/issues/508) — Git Sync Pulse as a portable Skills Army HQ projection | — | Completed | 2 | 3 | 2 | 1 | 8 | — |
+| 231 | **8** | [GH-608](https://github.com/HiQS-Labs/XYZ-forge/issues/608) — fix(relay): honor Qwen/DeepSeek reasoning effort and correct false idle timeout attribution | Cargo | completed | 2 | 2 | 2 | 2 | 8 | — |
+| 232 | **8** | [GH-654](https://github.com/HiQS-Labs/XYZ-forge/issues/654) — Marathon containment exit-6 discards completed builder work; rtl_worktree_end records no off-lane path list — blocks GH-648 phase p1 (2/2 codex turns) | Cargo | completed | 2 | 2 | 2 | 2 | 8 | — |
+| 233 | **8** | [GH-658](https://github.com/HiQS-Labs/XYZ-forge/issues/658) — Containment allowlist stores the ABSOLUTE relay_file path — worktree-relative porcelain can never match it, so every instructed relay-file edit trips exit-6 (root cause of #654) | Cargo | completed | 2 | 2 | 2 | 2 | 8 | — |
+| 234 | **8** | [GH-659](https://github.com/HiQS-Labs/XYZ-forge/issues/659) — rtl_init splits allow_csv with bare IFS=',' — no trim, so every artifact AFTER THE FIRST in a "a, b, c" allowlist is invisible to containment (reproduced; root cause #2 of #654) | Cargo | completed | 2 | 2 | 2 | 2 | 8 | — |
+| 235 | **8** | [GH-660](https://github.com/HiQS-Labs/XYZ-forge/issues/660) — Deployed-skills drift: express SKILL.md hot-fixed directly in the vendored collection (git-pulse-sync) instead of re-vendoring from canonical skills/express — deployed copy missing GH-592 resume recipe | Cargo | completed | 2 | 2 | 2 | 2 | 8 | — |
+| 236 | **8** | [GH-663](https://github.com/HiQS-Labs/XYZ-forge/issues/663) — QA findings (agy relay review) on the GH-654/658/659/660 hotfix chain: turn_prompt csv leak, drift-check CLI ambiguity + CRLF false positives, offlane rename-source omission | Cargo | queue | 2 | 2 | 2 | 2 | 8 | — |
+| 237 | **4** | [GH-255](https://github.com/HiQS-Labs/XYZ-forge/issues/255) — marathon-drive blocked-before-dispatch refusal omits XYZ_ARCHIVE_ROOT | Cargo | queue | 1 | 1 | 1 | 1 | 4 | — |
+| 238 | **4** | [GH-406](https://github.com/HiQS-Labs/XYZ-forge/issues/406) — External review (Russ K.): eight findings on guards that cover a narrower path than the doc claims | — | Queue / parked intake | 3 | 3 | 4 | 3 | 13 | 4 |
+| 239 | **4** | [GH-410](https://github.com/HiQS-Labs/XYZ-forge/issues/410) — relay-block validator never runs on the driven path | Front-Door | completed | 95 | 80 | 90 | 40 | 305 | 4 |
+| 240 | **4** | [GH-412](https://github.com/HiQS-Labs/XYZ-forge/issues/412) — transient claim collision indistinguishable from durable loss | Front-Door | completed | 80 | 75 | 75 | 55 | 285 | 4 |
+| 241 | **4** | [GH-413](https://github.com/HiQS-Labs/XYZ-forge/issues/413) — launch-artifact marker authorises destructive rebuild | Front-Door | completed | 90 | 95 | 85 | 95 | 365 | 4 |
 
 **Top of the line:** GH-474 — Remove rendered MD views (ROADMAP-DASHBOARD.md & LEADERBOARD.md) to eliminate staleness guards (score 360).
 
diff --git a/releases.sql b/releases.sql
index a93197fc..291fd5b7 100644
--- a/releases.sql
+++ b/releases.sql
@@ -1,6 +1,6 @@
 -- releases-app canonical dump (GH-32 grammar: GID-keyed rows, natural keys elsewhere,
 -- no integer PKs/FKs as values; rebuild renumbers deterministically)
--- generation: 1132
+-- generation: 1134
 -- table: schema_migrations
 INSERT INTO schema_migrations(version, applied_at) VALUES('1', '2026-08-19T01:32:22Z');
 INSERT INTO schema_migrations(version, applied_at) VALUES('2', '2026-08-19T18:55:40Z');
@@ -13,7 +13,7 @@ INSERT INTO schema_migrations(version, applied_at) VALUES('8', '2026-09-12T16:07
 INSERT INTO schema_migrations(version, applied_at) VALUES('9', '2026-09-23T01:01:18Z');
 -- table: settings
 INSERT INTO settings(key, value, updated_at) VALUES('enforcement', 'lenient', '2026-09-08T05:45:05Z');
-INSERT INTO settings(key, value, updated_at) VALUES('generation', '1132', '2026-09-25T01:21:42Z');
+INSERT INTO settings(key, value, updated_at) VALUES('generation', '1134', '2026-09-25T02:06:18Z');
 INSERT INTO settings(key, value, updated_at) VALUES('repo_slug', 'XYZ-forge', '2026-09-08T05:45:05Z');
 -- table: repos
 INSERT INTO repos(global_id, slug, updated_at) VALUES('repo-01M0BTBRJ0PZF51EK6PCRJ20FS', 'XYZ-forge', '2026-09-08T05:45:05Z');
@@ -731,6 +731,7 @@ INSERT INTO roadmap_items(global_id, repo_gid, gh_number, title, section, positi
 INSERT INTO roadmap_items(global_id, repo_gid, gh_number, title, section, position, status_marker, complexity, risk, effort, doc_path, issue_url, raw_text, first_seen, updated_at, rating_pri, rating_sev, rating_appeal, rating_effort, rating_ovr, status_label) VALUES('rmi-01M334NT6E5JY8G3YDV2KPWJSM', 'repo-01M0BTBRJ0PZF51EK6PCRJ20FS', '742', 'xyz-vendor.sh: vendored .xyz/ ships no package.json, so every Node entry point breaks on a `"type":"module"` target', 'Completed', '111', '✅', NULL, NULL, NULL, 'PROJECT/3-COMPLETED/GH-742-VENDOR-PACKAGE-JSON-ESM.md', 'https://github.com/HiQS-Labs/XYZ-forge/issues/742', '- **GH-742 · xyz-vendor.sh: vendored .xyz/ ships no package.json, so every Node entry point breaks on a `"type":"module"` target** ✅ **SHIPPED 2026-09-24 (PR #753)** — [GH-742-VENDOR-PACKAGE-JSON-ESM.md](PROJECT/3-COMPLETED/GH-742-VENDOR-PACKAGE-JSON-ESM.md) · [#742](https://github.com/HiQS-Labs/XYZ-forge/issues/742) (rated 70/90/90/80)', '2026-09-21T23:26:33Z', '2026-09-24T19:13:47Z', '70', '90', '90', '80', NULL, NULL);
 INSERT INTO roadmap_items(global_id, repo_gid, gh_number, title, section, position, status_marker, complexity, risk, effort, doc_path, issue_url, raw_text, first_seen, updated_at, rating_pri, rating_sev, rating_appeal, rating_effort, rating_ovr, status_label) VALUES('rmi-01M3AWVQMM486M0HAXTKNHM8C3', 'repo-01M0BTBRJ0PZF51EK6PCRJ20FS', '798', 'feat(skills): add status skill and DRY/centralized-helper audit in review-code', 'Completed', '108', '✅', NULL, NULL, NULL, 'PROJECT/3-COMPLETED/GH-798-FEAT-SKILLS-ADD-STATUS-SKILL-AND-DRY-CENTRALIZED-HELPER-AUDI.md', 'https://github.com/HiQS-Labs/XYZ-forge/issues/798', '- **GH-798 · feat(skills): add status skill and DRY/centralized-helper audit in review-code** ✅ **SHIPPED 2026-09-24 (commit 137076593882)** — [doc](PROJECT/3-COMPLETED/GH-798-FEAT-SKILLS-ADD-STATUS-SKILL-AND-DRY-CENTRALIZED-HELPER-AUDI.md) · [#798](https://github.com/HiQS-Labs/XYZ-forge/issues/798)', '2026-09-24T23:43:54Z', '2026-09-25T01:21:40Z', NULL, NULL, NULL, NULL, NULL, NULL);
 INSERT INTO roadmap_items(global_id, repo_gid, gh_number, title, section, position, status_marker, complexity, risk, effort, doc_path, issue_url, raw_text, first_seen, updated_at, rating_pri, rating_sev, rating_appeal, rating_effort, rating_ovr, status_label) VALUES('rmi-01M3B2DEB0BED6JB6A33SW74BC', 'repo-01M0BTBRJ0PZF51EK6PCRJ20FS', '801', 'fix: GH-798 skill tests violate pipe-to-grep ratchet and block full gate', 'Completed', '108', '✅', NULL, NULL, NULL, 'PROJECT/3-COMPLETED/GH-801-FIX-GH-798-SKILL-TESTS-VIOLATE-PIPE-TO-GREP-RATCHET-AND-BLOC.md', 'https://github.com/HiQS-Labs/XYZ-forge/issues/801', '- **GH-801 · fix: GH-798 skill tests violate pipe-to-grep ratchet and block full gate** ✅ **SHIPPED 2026-09-24 (commit 137076593882)** — [doc](PROJECT/3-COMPLETED/GH-801-FIX-GH-798-SKILL-TESTS-VIOLATE-PIPE-TO-GREP-RATCHET-AND-BLOC.md) · [#801](https://github.com/HiQS-Labs/XYZ-forge/issues/801)', '2026-09-25T01:20:57Z', '2026-09-25T01:21:42Z', NULL, NULL, NULL, NULL, NULL, NULL);
+INSERT INTO roadmap_items(global_id, repo_gid, gh_number, title, section, position, status_marker, complexity, risk, effort, doc_path, issue_url, raw_text, first_seen, updated_at, rating_pri, rating_sev, rating_appeal, rating_effort, rating_ovr, status_label) VALUES('rmi-01M3B50BKKGA3CF186CTARDWYA', 'repo-01M0BTBRJ0PZF51EK6PCRJ20FS', '804', 'Review and simplify skill instruction tests introduced by GH-798', 'Queue / parked intake', '108', '🆕', NULL, NULL, NULL, 'PROJECT/2-WORKING/GH-804-SIMPLIFY-SKILL-INSTRUCTION-TESTS-INTRODUCED-BY-GH-798.md', 'https://github.com/HiQS-Labs/XYZ-forge/issues/804', '- **GH-804 · Review and simplify skill instruction tests introduced by GH-798** 🆕 **captured 2026-09-24 via HQ** — [GH-804-SIMPLIFY-SKILL-INSTRUCTION-TESTS-INTRODUCED-BY-GH-798.md](PROJECT/2-WORKING/GH-804-SIMPLIFY-SKILL-INSTRUCTION-TESTS-INTRODUCED-BY-GH-798.md) · [#804](https://github.com/HiQS-Labs/XYZ-forge/issues/804) (rated 40/20/50/85)', '2026-09-25T02:06:14Z', '2026-09-25T02:06:18Z', '40', '20', '50', '85', NULL, NULL);
 -- table: jog_queue
 INSERT INTO jog_queue(global_id, repo_gid, gh_number, position, status, created_at, updated_at, attempt_count, lease_pid, failure_reason) VALUES('jog-01M122D1G6F8AWEKQHKFPCFD37', 'repo-01M0BTBRJ0PZF51EK6PCRJ20FS', '275', '1', 'completed', '2026-08-27T16:56:10Z', '2026-08-27T18:11:04Z', '5', NULL, 'preflight: already-landed');
 INSERT INTO jog_queue(global_id, repo_gid, gh_number, position, status, created_at, updated_at, attempt_count, lease_pid, failure_reason) VALUES('jog-01M122D1WM4Z659A8N591AR0H8', 'repo-01M0BTBRJ0PZF51EK6PCRJ20FS', '269', '1', 'failed', '2026-08-27T16:56:10Z', '2026-08-27T18:39:22Z', '3', NULL, 'drive failed (exit 7)');
@@ -2048,6 +2049,8 @@ INSERT INTO op_receipts(op, target_gid, at, txn_id, session_id, state_digest_bef
 INSERT INTO op_receipts(op, target_gid, at, txn_id, session_id, state_digest_before, state_digest_after) VALUES('roadmap-update', 'rmi-01M3AWVQMM486M0HAXTKNHM8C3', '2026-09-25T01:21:40Z', '8f5890da8b1e4829ad57143458deff1c', 'default', '2339d10af667585e163fe9f26866fb252e5647647d145ec31015d0679f33a8da', 'bd2bf89a968741450d83fea340942c40c86e6d8576d82e9e9aeb66f36fe5e1aa');
 INSERT INTO op_receipts(op, target_gid, at, txn_id, session_id, state_digest_before, state_digest_after) VALUES('roadmap-repoint', 'rmi-01M3B2DEB0BED6JB6A33SW74BC', '2026-09-25T01:21:41Z', '8b5db4952209434caa84e95ee634000e', 'default', 'bd2bf89a968741450d83fea340942c40c86e6d8576d82e9e9aeb66f36fe5e1aa', '74bcb61bdb6bd320ed236e1ebcabb87ec265835206b00836909e3ec61f0fb7b1');
 INSERT INTO op_receipts(op, target_gid, at, txn_id, session_id, state_digest_before, state_digest_after) VALUES('roadmap-update', 'rmi-01M3B2DEB0BED6JB6A33SW74BC', '2026-09-25T01:21:42Z', '3474cf348c824a75949be75addcdb1bc', 'default', '74bcb61bdb6bd320ed236e1ebcabb87ec265835206b00836909e3ec61f0fb7b1', '7bba4da6ae5c36f0a8312dc635e25079014b2abaead266b8c4cff02dee7440b8');
+INSERT INTO op_receipts(op, target_gid, at, txn_id, session_id, state_digest_before, state_digest_after) VALUES('roadmap-add', 'rmi-01M3B50BKKGA3CF186CTARDWYA', '2026-09-25T02:06:14Z', '4098c36787f24ea4bff8a2a9f81ecdf8', 'default', '7bba4da6ae5c36f0a8312dc635e25079014b2abaead266b8c4cff02dee7440b8', '6a03a23def9f714d18bf29ca7e76db5159286ce2bba603b917d2e9b1acdf980a');
+INSERT INTO op_receipts(op, target_gid, at, txn_id, session_id, state_digest_before, state_digest_after) VALUES('roadmap-rate', 'rmi-01M3B50BKKGA3CF186CTARDWYA', '2026-09-25T02:06:18Z', 'b7a87668088546fa818f64599c3cdb11', 'default', '6a03a23def9f714d18bf29ca7e76db5159286ce2bba603b917d2e9b1acdf980a', '3c3fb53e3b25bc0d2bda47fd211c837eb11e24992c71385c474808e7813a57ff');
 -- table: work_events
 INSERT INTO work_events(global_id, repo_gid, gh_number, txn_id, event, payload, at) VALUES('wev-01M2CBC3C2HSWRSBY81TAZHYY0', 'repo-01M0BTBRJ0PZF51EK6PCRJ20FS', '568', 'df2ee890077d486dbe23311c5dd74d82', 'updated', '{"marker": "\u2705", "section": "Completed"}', '2026-09-13T03:01:02Z');
 INSERT INTO work_events(global_id, repo_gid, gh_number, txn_id, event, payload, at) VALUES('wev-01M2CGH1A7Z979TG5DQJHN8DX6', 'repo-01M0BTBRJ0PZF51EK6PCRJ20FS', '591', '6d3d7a7619c247b5a85a039ea98756bd', 'parked', '{"section": "Queue / parked intake"}', '2026-09-13T04:31:07Z');
@@ -2429,3 +2432,5 @@ INSERT INTO work_events(global_id, repo_gid, gh_number, txn_id, event, payload,
 INSERT INTO work_events(global_id, repo_gid, gh_number, txn_id, event, payload, at) VALUES('wev-01M3B2DGREAKERTWNR47HC6BSZ', 'repo-01M0BTBRJ0PZF51EK6PCRJ20FS', '801', '04d66cae6da84d76986f6d15634d442b', 'in_flight', '{"accepted_start": true, "marker": "\ud83d\udea7", "section": "In progress", "source": "roadmap-update", "transition": true}', '2026-09-25T01:20:59Z');
 INSERT INTO work_events(global_id, repo_gid, gh_number, txn_id, event, payload, at) VALUES('wev-01M3B2ES2M76D077RMVGQMY71C', 'repo-01M0BTBRJ0PZF51EK6PCRJ20FS', '798', '8f5890da8b1e4829ad57143458deff1c', 'updated', '{"marker": "\u2705", "section": "Completed", "source": "roadmap-update", "transition": false}', '2026-09-25T01:21:40Z');
 INSERT INTO work_events(global_id, repo_gid, gh_number, txn_id, event, payload, at) VALUES('wev-01M3B2ET3YN6EF0GW4XAS38ZGB', 'repo-01M0BTBRJ0PZF51EK6PCRJ20FS', '801', '3474cf348c824a75949be75addcdb1bc', 'completed', '{"marker": "\u2705", "section": "Completed", "source": "roadmap-update", "transition": true}', '2026-09-25T01:21:42Z');
+INSERT INTO work_events(global_id, repo_gid, gh_number, txn_id, event, payload, at) VALUES('wev-01M3B50BMETFXTHF1X5M2CTFJK', 'repo-01M0BTBRJ0PZF51EK6PCRJ20FS', '804', '4098c36787f24ea4bff8a2a9f81ecdf8', 'parked', '{"section": "Queue / parked intake"}', '2026-09-25T02:06:14Z');
+INSERT INTO work_events(global_id, repo_gid, gh_number, txn_id, event, payload, at) VALUES('wev-01M3B50FFDNM5W04JPCC0SJZA0', 'repo-01M0BTBRJ0PZF51EK6PCRJ20FS', '804', 'b7a87668088546fa818f64599c3cdb11', 'rated', '{"rated": "40/20/50/85"}', '2026-09-25T02:06:18Z');
diff --git a/test/gh798-status-skill.sh b/test/gh798-status-skill.sh
index 557a6e6c..7bf895c8 100755
--- a/test/gh798-status-skill.sh
+++ b/test/gh798-status-skill.sh
@@ -36,27 +36,17 @@ grep -q "Lane E. Centralized Helpers & DRY" "$REVIEW_CODE_FILE" && pass "review-
 grep -q "Centralized Helper Adherence" "$REVIEW_CODE_FILE" && pass "review-code has helper adherence check" || fail "missing helper adherence check"
 grep -q "Parallel Subsystem / Reinvention Trap" "$REVIEW_CODE_FILE" && pass "review-code has parallel subsystem trap" || fail "missing parallel subsystem trap"
 
-# Lane E subsections must explicitly bind required severities:
-grep -q 'is a `\[Blocker\]`' <<<"$(awk '/1\. \*\*Centralized Helper Adherence:\*\*/,/2\. \*\*Parallel Subsystem/' "$REVIEW_CODE_FILE")" && pass "Lane E helper adherence binds to [Blocker]" || fail "Lane E helper adherence not bound to [Blocker]"
-grep -q 'mandatory `\[Blocker\]`' <<<"$(awk '/2\. \*\*Parallel Subsystem \/ Reinvention Trap:\*\*/,/3\. \*\*Intra-Diff/' "$REVIEW_CODE_FILE")" && pass "Lane E parallel subsystem binds to [Blocker]" || fail "Lane E parallel subsystem not bound to [Blocker]"
-grep -q 'is a `\[Should\]`' <<<"$(awk '/3\. \*\*Intra-Diff & Cross-Module Duplication \(DRY\):\*\*/,/(\*\*Graph & Source Lookup|\-\-\-)/' "$REVIEW_CODE_FILE")" && pass "Lane E code duplication binds to [Should]" || fail "Lane E duplication not bound to [Should]"
-
-# Phase 4 categories must bind required severities:
-grep -q "reinventing a parallel subsystem" <<<"$(awk '/\[Blocker\]/,/\[Should\]/' "$REVIEW_CODE_FILE")" && pass "review-code binds parallel subsystem to [Blocker]" || fail "parallel subsystem is not under [Blocker]"
-grep -q "bypassing established centralized helpers" <<<"$(awk '/\[Blocker\]/,/\[Should\]/' "$REVIEW_CODE_FILE")" && pass "review-code binds helper bypass to [Blocker]" || fail "helper bypass is not under [Blocker]"
-grep -q "non-DRY duplicate logic" <<<"$(awk '/\[Should\]/,/\[Nit\]/' "$REVIEW_CODE_FILE")" && pass "review-code binds duplicate logic to [Should]" || fail "duplicate logic is not under [Should]"
-
 # --- 6. ARCHITECTURE.md registration ---
 grep -q "\[status\](skills/2-daily/status/SKILL.md)" "$ARCH_FILE" && pass "ARCHITECTURE.md has status link" || fail "missing ARCHITECTURE.md link"
 grep -q "### \`2-daily\` — A few times a day (16)" "$ARCH_FILE" && pass "ARCHITECTURE.md has updated 2-daily count (16)" || fail "missing updated 2-daily count"
 
 # --- 7. Installer gh678 compliance (in sandbox) ---
 H="$WORK/home"; A="$H/apps"
-mkdir -p "$A/claude" "$A/codex" "$A/gemcfg" "$A/antigrav" "$A/agents"
+mkdir -p "$A/claude" "$A/codex" "$A/gemcfg" "$A/antigrav" "$A/antigravcli" "$A/agents"
 run_installer() {
   HOME="$H" CLAUDE_SKILLS_DIR="$A/claude" CODEX_SKILLS_DIR="$A/codex" \
   GEMINI_CONFIG_SKILLS_DIR="$A/gemcfg" ANTIGRAVITY_SKILLS_DIR="$A/antigrav" \
-  AGENTS_SKILLS_DIR="$A/agents" \
+  ANTIGRAVITY_CLI_SKILLS_DIR="$A/antigravcli" AGENTS_SKILLS_DIR="$A/agents" \
   bash "$INSTALLER"
 }
 
@@ -81,45 +71,11 @@ cp "$SKILL_FILE" "$TMP_COPY"
 sed -i.bak '/Status Discipline:/d' "$TMP_COPY"
 grep -q "Status Discipline:" "$TMP_COPY" && fail "negative control 8a: mutation failed to delete recital" || pass "negative control 8a: mutation successfully detected missing recital"
 
-# 8b: Mutating [Blocker] to [Nit] in Phase 4 must fail the Blocker check
+# 8b: Lane E deletion on review-code/SKILL.md must fail Lane E check
 TMP_REV="$WORK/review_code_mutated.md"
 cp "$REVIEW_CODE_FILE" "$TMP_REV"
-sed -i.bak 's/\[Blocker\]/\[Nit\]/g' "$TMP_REV"
-if grep -q "reinventing a parallel subsystem" <<<"$(awk '/\[Blocker\]/,/\[Should\]/' "$TMP_REV")"; then
-  fail "negative control 8b: severity mutation failed to turn Blocker check red"
-else
-  pass "negative control 8b: severity mutation correctly made Blocker check fail (red)"
-fi
-
-# 8c: Mutating Lane E helper severity to [Nit] must fail Lane E helper check
-TMP_LANE_E1="$WORK/review_code_lane_e1.md"
-cp "$REVIEW_CODE_FILE" "$TMP_LANE_E1"
-sed -i.bak 's/is a `\[Blocker\]`/is a `[Nit]`/g' "$TMP_LANE_E1"
-if grep -q 'is a `\[Blocker\]`' <<<"$(awk '/1\. \*\*Centralized Helper Adherence:\*\*/,/2\. \*\*Parallel Subsystem/' "$TMP_LANE_E1")"; then
-  fail "negative control 8c: Lane E1 helper mutation failed to turn check red"
-else
-  pass "negative control 8c: Lane E1 helper mutation correctly made check fail (red)"
-fi
-
-# 8d: Mutating Lane E parallel subsystem severity to [Nit] must fail Lane E parallel check
-TMP_LANE_E2="$WORK/review_code_lane_e2.md"
-cp "$REVIEW_CODE_FILE" "$TMP_LANE_E2"
-sed -i.bak 's/mandatory `\[Blocker\]`/mandatory `[Nit]`/g' "$TMP_LANE_E2"
-if grep -q 'mandatory `\[Blocker\]`' <<<"$(awk '/2\. \*\*Parallel Subsystem \/ Reinvention Trap:\*\*/,/3\. \*\*Intra-Diff/' "$TMP_LANE_E2")"; then
-  fail "negative control 8d: Lane E2 parallel subsystem mutation failed to turn check red"
-else
-  pass "negative control 8d: Lane E2 parallel subsystem mutation correctly made check fail (red)"
-fi
-
-# 8e: Mutating Lane E duplication severity to [Nit] must fail Lane E duplication check
-TMP_LANE_E3="$WORK/review_code_lane_e3.md"
-cp "$REVIEW_CODE_FILE" "$TMP_LANE_E3"
-sed -i.bak 's/is a `\[Should\]`/is a `[Nit]`/g' "$TMP_LANE_E3"
-if grep -q 'is a `\[Should\]`' <<<"$(awk '/3\. \*\*Intra-Diff & Cross-Module Duplication \(DRY\):\*\*/,/(\*\*Graph & Source Lookup|\-\-\-)/' "$TMP_LANE_E3")"; then
-  fail "negative control 8e: Lane E3 duplication mutation failed to turn check red"
-else
-  pass "negative control 8e: Lane E3 duplication mutation correctly made check fail (red)"
-fi
+sed -i.bak '/Lane E. Centralized Helpers & DRY/d' "$TMP_REV"
+grep -q "Lane E. Centralized Helpers & DRY" "$TMP_REV" && fail "negative control 8b: mutation failed to delete Lane E" || pass "negative control 8b: mutation successfully detected missing Lane E"
 
 echo "  gh798-status-skill: $PASS pass, $FAIL fail"
 [ "$FAIL" -eq 0 ] || exit 1
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
# Project-Driven Doc Automation (PDDA)

Canonical development: [XYZ Forge](https://github.com/HiQS-Labs/XYZ-forge).
The shared contract below applies to installed copies; repo-specific adoption policy lives in the target’s startup docs.

PDDA is the document operating layer for this repo. Its job is to keep project plans, bug-fix docs,
research notes, and roadmap pointers clean enough that an agent can pick up work with minimal drift
and enough structure that routine hygiene can be automated instead of re-decided every session.

The core idea is simple:

- deterministic scripts enforce the parts that should never require judgment
- an LLM reviewer flags structural or planning-quality gaps that are hard to express as regex alone
- `ROADMAP.md` stays a pointer/index, while project detail lives in the individual project docs

## Goals

- Keep `PROJECT/2-WORKING` limited to docs that are truly active.
- Ensure every active doc answers two questions at a glance: what was just completed, and what is next.
- Make phased plans automation-ready by requiring explicit QA gates.
- Prevent plan rot: stale files, missing next steps, hardcoded paths, and hidden scope drift.
- Give agents one repeatable contract for project docs, bug-fix docs, and experimental plans.

## Non-goals

- PDDA does not replace the project docs themselves.
- PDDA does not decide product strategy.
- PDDA does not auto-rewrite nuanced plan content without review.
- PDDA does not turn `ROADMAP.md` into a second execution plan.

## Canonical document model

PDDA assumes four lifecycle buckets:

- `PROJECT/1-INBOX`: new ideas, rough proposals, untriaged notes
- `PROJECT/2-WORKING`: active docs that should be updated as work progresses
- `PROJECT/3-COMPLETED`: completed docs with an outcome
- `PROJECT/4-MISC`: reference, stale, superseded, or abandoned docs

Within that model:

- `ROADMAP.md` is the index of current, completed, attempted, and deferred work
- project detail lives in the individual `PROJECT/**` documents
- a working doc is the canonical source of truth for that effort until it is completed, deferred, or superseded
- `blank.md` placeholders are scaffolding and should be ignored by PDDA checks

## Required contract for active docs

Every doc in `PROJECT/2-WORKING` should have:

1. YAML frontmatter with at least `title`, `status`, `created`, `updated`, `owner`, and `goal`
2. a near-top status table with the exact columns:

```md
## Status

| What was just completed | What's next |
|---|---|
| ... | ... |
```

3. clear phase or work sections if the doc is a plan
4. a table of contents (`## Table of contents`) listing each phase, if the plan is multi-phase — so a
   cold agent can see the full phase span and jump to the live one without scrolling the whole body
5. QA gates or acceptance criteria after each phase if the plan is multi-phase
6. for any discovery or spike phase, its findings written **back into this doc** before its QA gate can
   pass (see [Discovery & spike phases (Memory Injection)](#discovery--spike-phases-memory-injection))
7. repo-relative paths only; no hardcoded absolute local paths

**Highly recommended** (not a gate since GH-693): before moving to `PROJECT/3-COMPLETED`, a
`## Lessons Learned (For Future Agents)` section capturing quirks and gotchas. `wave_reconcile.py`
warns when it is missing or a placeholder and promotes the doc anyway — the warning is in every
hosted-lane log, so a doc without one is visible, never blocked.

Recommended fields when relevant:

- `related`
- `context_tags` (e.g. `[auth, flaky-tests, build]`)
- `reviewed`
- `branch`
- `non_goals`
- `gh_issue`
- `effort`, `complexity`, `risk`, `phases` — triage ratings; **required for medium-large work** (see
  [Triage ratings for medium-large work](#triage-ratings-for-medium-large-work))

## Quad Concepts (opt-in)

An **opt-in** glance layer, **off by default**. The `## Status` table says *where* the work is; Quad
Concepts says *what* it is — a 5-second read of the core problems a plan tackles and how, so an operator
can see whether the real pain points are covered. (Distinct from `context_tags`: those are for search;
this is for glance.)

When enabled system-wide via the `.pdda-quad` lever (or the `PDDA_QUAD` env var — **orthogonal** to the
enforcement mode), tracked plan docs must carry a `## Quad Concepts` section of **1–4 bullets**,
conventionally right after `## Status`:

```md
## Quad Concepts
- <pain the doc addresses> → <how it addresses it>
```

- **Shape (deterministic):** 1–4 **top-level, non-empty** `-`/`*` bullets in the first `## Quad Concepts`
  section. `pain → fix` phrasing is the convention (nudged by the LLM readiness rubric), not a hard regex.
- **Scope:** `PROJECT/2-WORKING`, `PROJECT/1-INBOX/GH-*.md`, and `PROJECT/3-COMPLETED` (the last keeps a
  glanceable summary for cold-start recall). `PROJECT/4-MISC` is out.
- **Enable:** set `.pdda-quad` to `on` (or `PDDA_QUAD=1`). The enforcement mode still governs whether a
  missing/malformed section merely reports or blocks. **Opt a doc out** with `quad_exempt: true`.
- Enforced by `pdda.sh quad-concepts` (deterministic, structure-only) plus a warn-only readiness rubric.
- `pdda.sh glance` (read-only, always available) rolls up `title + Quad Concepts` across `2-WORKING` for
  a one-screen view of what the active portfolio is addressing.

## Triage ratings for medium-large work

So automation can pick *which* task to pursue without re-reading every plan, every newly recorded
**medium-large** task or project carries four triage fields in its frontmatter:

| Field | Range | Meaning |
|---|---|---|
| `effort` | integer `1`–`5` | how much work — `1` low, `5` highest |
| `complexity` | integer `1`–`5` | how intricate / how many moving parts — `1` low, `5` highest |
| `risk` | integer `1`–`5` | blast radius + uncertainty — `1` safe/contained, `5` one-way-door or unknown |
| `phases` | positive integer | total number of phases in the plan |

```yaml
effort: 2
complexity: 3
risk: 1
phases: 4
```

`risk` should track the repo's existing reversibility scale (`Easy / Costly / One-way door`,
`AGENTS.md` #3): `1`–`2` ≈ Easy, `3` ≈ Costly, `4`–`5` ≈ one-way door / high uncertainty. It is not a
parallel notion of danger — it is that scale expressed as a number.

**Scope.** Required for medium-large work (project plans, experiments, features, multi-phase efforts).
Genuinely small/trivial docs (a typo, a path repoint, a ≤2–3 line bug-fix — the same floor as the
issue-first SOP) do not need them. "Medium-large" is a judgment, so *presence* is enforced by the LLM
layer, not a regex (below).

### How to combine them — derive, don't store

There is deliberately **no stored composite "score" field.** A frozen aggregate would (a) drift from
the three numbers it came from, violating Principle #4 (*one canonical place per fact*), and (b) bake a
weighting choice into every doc that you then cannot re-tune without rewriting them. Compute the
selection signal **live, at selection time**, from the raw fields:

- **`risk` is a gate, not an addend.** A trivial-but-risky task (`effort 1`, `complexity 1`, `risk 5`)
  is easy to *do* but exactly what automation should not auto-pick — folding risk into a linear sum
  lets it slip through mid-ranked. Gate on it instead.
- **`effort` and `complexity` are correlated** (complex work is usually effortful), so summing them is
  a rough "size" proxy, not two independent signals — treat the sum as one ease axis, not two.

Reference selection rule (tune the thresholds per repo):

```text
eligible      = risk <= 2 AND not ratings_provisional   # safety gate; risk >= 4 => route to a human
ease          = effort + complexity       # 2..10, lower = easier
pick          = among eligible, lowest ease, then fewest phases as the tiebreak
```

`ratings_provisional: true` is an **eligibility gate, not just metadata.** Auto-drafted intake (e.g.
the `/idea` skill) ships best-guess ratings marked provisional; a rough `risk: 2` guess on a large
effort must **not** become auto-selectable on the strength of that guess. So a provisional doc is held
out of auto-selection until a human confirms the ratings and clears the flag — the same "route to a
human" posture as `risk >= 4`.

This keeps the raw ratings canonical and queryable while letting the "what's the easiest *safe* thing
to grab" logic live in one place that can evolve. (See the resolved `priority` note under
[Proposed extensions](#proposed-extensions-not-yet-locked).)

### How this is enforced

- **deterministic (values)** — `pdda.sh frontmatter` validates the fields **only when present**:
  `effort`/`complexity`/`risk` must be integers `1`–`5`, `phases` a positive integer. A present-but-bad
  value is unambiguous, so it `error`s. The script does **not** force presence — it cannot know whether
  a doc is "medium-large."
- **LLM (presence)** — `pdda-doc-ready.sh` flags a medium-large plan that is *missing* the triage
  ratings. Whether a doc is medium-large is a judgment, so it stays advisory/warn-capped like every
  other readiness finding.

## Why the two-column status header matters

The status table is the front door for both humans and automation.

- The left column is the last verified state change.
- The right column is the next action.
- If either is missing, an agent has to reconstruct state from the body, which is slow and error-prone.

PDDA therefore treats the exact header names as a contract, not a style preference. The header must be
exactly `What was just completed | What's next` — there is no alias/compatibility window. (One was
specced with a `2026-07-31` cutover, but a single-repo system controls its own docs: no doc here used
an old alias, so a dated, silently-changing branch guarded nothing and was removed 2026-06-22.)

## Discovery & spike phases (Memory Injection)

Discovery and spike phases exist to *learn* — reverse-engineer an existing system, probe an unknown,
prove or kill a risky approach before committing the plan to it. Their output is durable **memory**, and under
Principle #1 (*docs are the runtime state, not a record of it*) that knowledge is project state. If it
lives only in an agent's context or a throwaway scratch note, a cold agent resuming the plan cannot see
what was learned, why a path was chosen or abandoned, or what the spike actually proved — and the work
gets re-done.

Contract: **a phase tagged as discovery or spike must write its findings back into the originating plan
doc before its QA gate can pass.** This is active memory injection. Concretely, that phase's section (or a clearly linked sibling
section in the same doc) must capture:

- **what was investigated** — the system/area reverse-engineered or the question the spike asked
- **what was found (quirks, gotchas, mechanics)** — the concrete mechanics learned, with repo-relative pointers (`file:line`) where
  the finding lives in code, not a vague summary
- **what it changes** — how the finding confirms, redirects, or kills the plan's later phases; an
  unfinished "we'll know after the spike" left dangling is itself the gap

This satisfies Principle #4 (*one canonical place per fact*): the originating plan is that place. A
spike whose findings sit in chat is the exact drift PDDA exists to prevent. The QA gate for a
discovery/spike phase therefore includes "findings are written back to this doc" as an acceptance
criterion alongside the phase's normal checks.

Enforcement is **advisory (LLM layer, warn-capped)** — `pdda-doc-ready.sh` flags a discovery/spike
phase whose findings were not written back. "Did the agent actually capture what it learned" is a
judgment a regex cannot make honestly, so it stays with the LLM reviewer and, like every finding from
that layer, never blocks a build (see [LLM-assisted doc readiness review](#2-llm-assisted-doc-readiness-review)).
To tag a phase, name it plainly (e.g. `## Phase 2 — Discovery: …` / `## Phase 3 — Spike: …`) or set
`doc_type: research` / a phase-level marker the reviewer can see.

## Bug-fix doc stance

Bug-fix docs may use a lighter template than multi-phase project plans, but they still need:

- the minimum frontmatter
- the same `## Status` table while active
- a short bug description
- source of truth for intake, including a GitHub issue when relevant
- verification steps

GitHub issues are the default intake for substantive bug reports (issue-first SOP — see below). They are not a
substitute for the local active-work doc once execution starts in this repo.

## GitHub issue intake

GitHub issues are the **default front door** for substantive work — every project plan and every
non-trivial bug/fix opens an issue *first*, and that issue gets an in-repo pointer doc. The signal
stream lives in GitHub (machine-queryable state, labels, commit↔issue linkage); the execution
surface of record stays in `PROJECT/**`. This is the **issue-first SOP**; the bug-fix stance above
states the principle, and this section owns the *format*. To prevent duplicate intake and forgotten
work, every captured `GH-*.md` doc is also **parked immediately in `ROADMAP.md`** as a one-line queue
entry until it is promoted, deferred, or closed.

**Floor (what needs an issue).** The operational test is **lines of code touched**: any change
beyond a **2–3 line** fix opens a GitHub issue first, and its local plan doc is named after that
issue (see Filename below). Project plans, experiments, and features are always above this line.
**Exempt:** genuinely trivial edits — a ≤2–3 line code fix, a typo, a path repoint, a doc-only
one-liner, formatting — commit directly with a clear message and no issue. When in doubt, open the
issue — it is a cheap `gh issue create`. The SOP applies to *new* efforts going forward; in-flight
`1-INBOX`/`2-WORKING` docs are not backfilled.

Capture a tracked issue as a doc in `PROJECT/1-INBOX/` using this convention:

- **Filename:** `GH-<number>-VERY-SHORT-DESCRIPTION.md` — the local plan doc is always named after
  its GitHub issue (e.g. `GH-1234-SHOWME-COMMAND.md`, `GH-11-CROSS-REPO-TARGETING.md`). Keep the
  description to ~2–4 words; the issue number is the real key, the slug is just a human hint.
  SCREAMING-KEBAB to match the other inbox docs; no zero-padding — mirror the GitHub issue number.
  `<number>` resolves against `origin` (a single canonical repo), so the bare number is unambiguous.
- **Minimum frontmatter:** `gh_issue`, `source` (the full issue URL), `title`, `status`
  (`Proposed (1-INBOX — not yet active)`), `created`, and `doc_type` (`feedback` or `bugfix`).
  For medium-large captures, also include the triage ratings `effort`, `complexity`, `risk`, `phases`
  at capture time, so the queue can be triaged before promotion (see
  [Triage ratings for medium-large work](#triage-ratings-for-medium-large-work)).
- **Body:** transcribe the issue's actionable substance (the asks / acceptance criteria), not the whole
  thread. The live issue stays the discussion surface; this doc is the in-repo capture and back-reference.

Lifecycle:

- The `GH-` inbox doc is the **capture**, not the active-work doc. It carries no `## Status` table while
  it sits in `1-INBOX` (the inbox is the rough/untriaged bucket).
- Capture time also adds a **one-line `ROADMAP.md` queue pointer** linking that inbox doc. This is a
  temporary parking slot: it makes fresh intake visible to humans and automation before promotion,
  which is the duplicate-prevention guard.
- When execution starts, **promote** it to `PROJECT/2-WORKING/` — keep the `GH-` prefix for provenance —
  and it must then satisfy the full active-doc contract (frontmatter, exact status table, QA gates if
  phased), **carrying `gh_issue` forward**. The `ROADMAP.md` pointer is therefore required twice:
  first as a queued parking entry at capture, then as an active-work ledger entry after promotion.
  This is the concrete mechanism behind "GitHub issues are not a substitute for the local active-work
  doc once execution starts" (bug-fix stance above).
- If a captured issue is never actioned it ages out of `1-INBOX` like any other untriaged note; if it is
  closed without work, move the doc to `PROJECT/4-MISC` and remove its queue pointer from `ROADMAP.md`.

A foreign-repo issue (not `origin`) is the rare exception: the `source:` URL disambiguates it, since the
bare `GH-<number>` only guarantees uniqueness within the canonical repo.

## Automation layers

PDDA should have two classes of automation:

Implementation note:

- the automation ships as a single dispatcher, `utils/pdda/pdda.sh`, which sources shared helpers from
  `utils/pdda/pdda-lib.sh`
- every deterministic check is a subcommand: `pdda.sh frontmatter`, `pdda.sh status-table`,
  `pdda.sh hardcoded-paths`, `pdda.sh roadmap`, `pdda.sh roadmap-coverage`, `pdda.sh changelog`,
  `pdda.sh stale`, `pdda.sh issue-doc-sync`, `pdda.sh governance`
- the aggregate runner is `pdda.sh run` (it runs the deterministic checks in order, then the LLM
  review)
- each finding still carries a stable `check` id (e.g. `pdda-check-frontmatter`) in stdout and the
  activity log, independent of how the check is invoked
- **`run` reports what it found, not what it blocked on.** The mode gate forces every check's exit code
  to `0` outside `full`, so the closing line has three outcomes, not two: *all checks passed* (nothing
  found), *N error(s) found, not blocking in `<mode>` mode* (found, gate suppressed the failure), and
  *failures:* (found and blocked). Warnings never move the run out of the first state — a `warn` is the
  house-style advisory, and letting it read as failure would collapse the distinction. Inferring success
  from the gated exit code was BUG-001b: `run` printed *all checks passed* over real errors in `observe`
  and `light`, which are precisely the modes a new adopter starts in. The LLM readiness review is gated
  on the same signal, so an error-laden repo never spends an LLM call. **The rule:** a check that could
  not run — or could not block — must never be scored as a check that passed.

### 1. Deterministic hygiene checks

These catch issues where the answer should be the same every time.

#### A. `pdda.sh stale`

Purpose:
- inspect docs in `PROJECT/2-WORKING`
- detect stale docs based on file modification time
- **flag** them for a human to move (this check never moves files itself)

Minimum behavior:
- find docs in `PROJECT/2-WORKING` whose last edit is older than 4 days
- emit a `warn` finding per stale doc recommending the exact `git mv` to `PROJECT/4-MISC`
- honor a `pdda_hold: true` frontmatter override (skip the flag for held docs)
- log every flag to the activity log; **never** auto-move, so this check can never block a build

Why flag-only (design call, 2026-06-22):
- the auto-move was the repo's only destructive mechanic, and the activity log showed it never once
  fired a real move. The value is the flag; the move is risk with no proven payoff — a human runs one
  reversible `git mv`. mtime staleness is a deliberately loose signal, and flag-only makes a wrong
  guess cost nothing but an ignorable line. An opt-in move can be re-added later behind `pdda_hold` +
  `full` mode if it ever earns the miles.

#### B. `pdda.sh status-table`

Purpose:
- verify every doc in `PROJECT/2-WORKING` contains the exact two-column status table

Minimum behavior:
- fail if the `## Status` section is missing
- fail if the table headers are not exactly `What was just completed` and `What's next`
- fail if either first-row cell is blank

#### B2. `pdda.sh quad-concepts` (opt-in)

Purpose:
- when the `.pdda-quad` / `PDDA_QUAD` lever is on, verify each in-scope plan doc carries a
  `## Quad Concepts` section of 1–4 bullets (see [Quad Concepts (opt-in)](#quad-concepts-opt-in))

Minimum behavior:
- scope: `PROJECT/2-WORKING` + `PROJECT/1-INBOX/GH-*.md` + `PROJECT/3-COMPLETED`; skip `quad_exempt: true`
- parse the first `## Quad Concepts` section; count top-level, non-empty `-`/`*` bullets (skip fenced
  code, indented/nested and empty bullets; stop on the next h1/h2 or a blank line after a bullet)
- fail if the section is missing, has 0 bullets, or has more than 4
- **structure-only** — bullet *quality* (are they real `pain → fix` concepts?) is a warn-only job for
  the LLM readiness rubric, not this deterministic check
- runs standalone always; joins `pdda.sh run` only when the lever is enabled (orthogonal to the mode)

#### C. `pdda.sh frontmatter`

Purpose:
- ensure active docs expose the minimum machine-readable metadata

Minimum behavior:
- verify required keys exist
- flag empty required values
- flag invalid or missing dates
- when the triage ratings are present, validate their values — `effort`/`complexity`/`risk` must be
  integers `1`–`5`, `phases` a positive integer (presence itself is judged by the LLM layer; see
  [Triage ratings for medium-large work](#triage-ratings-for-medium-large-work))

#### D. `pdda.sh hardcoded-paths`

Purpose:
- catch absolute machine-specific paths before they fossilize into plans

Minimum behavior:
- scan working docs for obvious absolute paths such as `/Users/`, `/private/`, `/tmp/`, drive-letter paths, or `file://`
- report file + line for each hit

Expected exceptions:
- quoted terminal output
- explicitly marked transcript blocks

#### E. `pdda.sh roadmap`

Purpose:
- enforce the `ROADMAP.md` pointer/ledger contract deterministically (the cheap, hourly guard that
  does not need an LLM), so detail cannot silently leak back into the roadmap

Minimum behavior:
- scan `ROADMAP.md` (override via `PDDA_ROADMAP`)
- `error` on any GFM task-list item (`- [ ]` / `- [x]`) — a ledger carries no task checkboxes
- `error` on any `### Checklist` / `### QA checklist` heading — phase/QA detail belongs in the project doc
- `warn` when the file exceeds a line-count / heading-count budget (sprawl signal)

Expected exceptions:
- fenced `console` / `text` / `transcript` blocks and blockquote lines (the carve-out exception note)
  are not scanned — same convention as `pdda.sh hardcoded-paths`

The fuzzy judgment ("deep execution notes that belong elsewhere") stays with the LLM layer below; this
script only catches the unambiguous signals.

#### F. `pdda.sh changelog`

Purpose:
- nudge that `CHANGELOG.md` (the first-class end-of-iteration record) was updated this iteration

Minimum behavior:
- read `CHANGELOG.md` (override via `PDDA_CHANGELOG`); find the newest dated heading, accepting
  `## YYYY-MM-DD`, `## [x.y.z] - YYYY-MM-DD`, and unbracketed version headings such as `## x.y.z.w - YYYY-MM-DD`
- `warn` (never `error` — does not block, even in `full`) when that entry predates the latest git
  commit by more than `PDDA_CHANGELOG_STALE_DAYS` days (default `0`)
- `warn` if `CHANGELOG.md` is missing or has no dated entry; emit `info` (skip the compare) when there
  is no git history

Why warn-only:
- "did you update the changelog" is a reminder, not a correctness gate — blocking a build because a
  human hasn't written the prose yet is the wrong kind of friction (the calibration principle)

#### G. `pdda.sh roadmap-coverage`

Purpose:
- enforce the *coverage* direction of the `ROADMAP.md` contract: every active doc in `PROJECT/2-WORKING`
  must be reflected by a pointer in `ROADMAP.md`, so the ledger can never silently fall behind the
  working set. This is the inverse of `pdda.sh roadmap` (which keeps execution detail from leaking
  *into* the roadmap); together they guard the pointer/working-set relationship in both directions.

Minimum behavior:
- list the working docs (`PROJECT/2-WORKING/*.md`, `blank.md` excluded)
- `error` on any working doc whose repo-relative path (`PROJECT/2-WORKING/<name>.md`) does not appear in
  `ROADMAP.md` (override the roadmap location via `PDDA_ROADMAP`) — the action is "add a one-line ledger
  entry linking it"
- `error` if `ROADMAP.md` is missing entirely

Expected exceptions:
- a working doc that should not appear in the ledger opts out with `roadmap_exempt: true` in its
  frontmatter (mirrors the `pdda_hold` escape hatch in `pdda.sh stale`); the check then
  emits `info` (skip) for that doc

#### H. `pdda.sh issue-doc-sync`

Purpose:
- catch a tracked plan doc whose recorded state has drifted from its **GitHub issue**, in either
  direction — the gap a 2026-06-29 manual reconciliation pass had to cross-reference by hand

Scope: **both** `PROJECT/2-WORKING/` (active plans) and `PROJECT/3-COMPLETED/` (finished plans). The
completed bucket is not optional. Scanning `2-WORKING` alone means the check stops watching a doc at the
exact moment it completes — so the `git mv` that drift (a) recommends is what blinds it, and the issue is
orphaned forever (GH-27).

Minimum behavior:
- for each doc in either bucket, resolve its issue number from the `gh_issue` frontmatter key (preferred)
  or the `GH-<number>-` filename; silently skip docs that carry neither (they are not issue-tracked)
- resolve each issue's state from the best available source (see gh-degrade below), then flag:
  - **(a)** issue **CLOSED** but the doc is still in `2-WORKING` -> `warn`, recommending the exact
    `git mv` to `PROJECT/3-COMPLETED` (flag-only; a human runs the one reversible move)
  - **(b)** issue **OPEN** but the doc's `status:` lead word declares it done (`complete`, `done`,
    `shipped`, `fixed`, `closed`, `merged`, `resolved`, `landed`) -> `warn` to reconcile. Anchoring on the
    status **lead word** means a mid-status mention like `Active — Phase 0 complete` never false-flags.
  - **(b2)** issue **OPEN** but the doc's `status:` carries an explicit hand-off phrase anywhere
    (`ready to close`, `ready for 3-completed`, `awaiting close`) -> `warn`. Signal (b) alone is defeated
    by a self-contradictory status such as `Active — Phases 1-4 complete … Ready to close to 3-COMPLETED`:
    every human reads that as done; the lead word is `active`. The phrase list stays short and literal —
    a general "does this prose mean done?" parse is the false-positive machine the lead-word anchor exists
    to avoid.
  - **(c)** doc is in `3-COMPLETED` but the issue is **OPEN** -> `warn`, recommending `gh issue close <n>`.
    The lifecycle bucket is a deterministic signal; the status prose is not. `3-COMPLETED/` *is* the
    operator's assertion that the work is done, recorded in a path and verifiable with `test -f`.
    A doc in `3-COMPLETED` with a **CLOSED** issue is the fully reconciled end state: no finding.
- `warn` (never `error` — does not block, even in `full`, mirroring `pdda.sh changelog`); **flag-only**,
  never moves a file and never closes an issue
- gh-degrade: with `PDDA_ISSUE_SYNC_SOURCE=auto` (default) it uses live `gh` when that succeeds, else a
  cached state file (`PDDA_GH_STATE_CACHE`). `gh`/`cache` force one source. **A successful live lookup
  writes the cache** (best-effort, atomic), so the offline consumers — chiefly the `Stop` hook — have
  last-known state without a network call. When neither source yields a state, the affected doc emits a
  `warn` saying the sync was **NOT evaluated**: a check that could not run is not a check that passed.

Why warn-only + flag-only:
- every drift class here is mechanical, so the check carries zero false-judgment risk; a false flag is
  one ignorable warn line and a missed flag just leaves today's manual reconciliation — both cheap, so
  warn-only never-blocks is the right calibration (same stance as `pdda.sh stale` and `pdda.sh changelog`)
- closing an issue is a **human judgment** about whether the work is genuinely done, so no script does it.
  The `Stop` hook names the wrap (`/pdda-eod`) when this check reports reconciliation drift; the skill
  proposes, the operator confirms. Detect deterministically, act only with a yes.

#### I. `pdda.sh governance`

Purpose:
- evaluate the repo's own governance docs — `ROUTER.md`, `AGENTS.md`, `GUIDING-PRINCIPLES.md`,
  `README.md`, `CLAUDE.md`, `PROJECT/PDDA.md`, `utils/pdda/PDDA-INSTALL.md` — for the specific class of
  drift that Principle #4 (*one canonical place per fact*) exists to prevent: a doc pointing at a file
  that has moved or never existed, a doc that exists but no cold agent's read order will ever reach it,
  or a contract doc and the shipped code silently disagreeing about what commands or env vars exist

Minimum behavior (four checks, one shared `pdda-check-governance` id):
- **dead references** (`warn`) — every filename ending in `.md` **or `.sh`** named inside a governance
  doc must resolve to a real file, checked against the repo root or (for `./`/`../` links) the
  referencing file's own directory. A bare filename
  with no directory component (e.g. `blank.md`,
  which legitimately exists once per lifecycle folder) additionally falls back to a repo-wide basename
  search before being called dead — only a name absent *everywhere* is flagged. A `GH-<n>-*.md` name is
  never flagged; those are illustrative instances of the issue-doc naming convention, not fixed
  cross-references. `warn`, not `error`: prose extraction is inherently more heuristic than the
  mechanical checks above, so a false flag should cost one ignorable line, not a blocked build (same
  calibration as `pdda.sh stale`/`pdda.sh changelog`).
  - **Three extraction patterns** (union, then deduplicated): the target of a markdown link; a code span
    that contains nothing but the path; and **command-position paths** — a script token that opens a code
    span or a scanned fence line. The third exists because a router's most load-bearing references are
    the commands it tells an agent to run, and those carry arguments, so they close neither a link nor a
    backtick span right after the suffix. A vendored harness script invoked with a `--help` flag inside a
    code span, and a bare sync-tool invocation with its subcommand inside a scanned ` ```bash ` fence,
    both name a real file and matched nothing before GH-23 P3. Command position — line start, or
    immediately after a backtick — is where a shell command's *program* sits; a script name appearing
    later in a sentence is prose, and is not extracted. That is what keeps a documented invocation such
    as `pdda.sh run` from being read as two separate references. A leading `./` is stripped, because in
    command position it means "from the repo root I am standing in", not "relative to this doc".
  - **Suffix widening was not free.** `.sh` references are the ones that differ most between the canonical
    repo and a target, so the exemption manifest below had to grow with them — a fresh install went from
    0 to 46 self-inflicted warns before it did. A ref to a script that exists only on the operator's
    `PATH` (never in the repo) is a known, accepted false positive; it costs one advisory warn.
  - **GH-15 shipped-doc exemption manifest:** `utils/pdda/PDDA-INSTALL.md` and `PROJECT/PDDA.md` ship
    to every target install (`PDDA_GOV_SHIPPED_DOCS_DEFAULT`) but legitimately reference files
    `install.sh` deliberately does not copy there — the target's own repo-authored startup docs
    (`ROUTER.md`, `AGENTS.md`, `GUIDING-PRINCIPLES.md`, `README.md`, `CLAUDE.md`), canonical-only skill and
    companion-doc paths (`.claude/skills/pdda/SKILL.md`, `.claude/skills/governance-audit/SKILL.md`,
    `PROJECT/3-COMPLETED/PDDA-SYNC-TO-OTHER-REPOS.md`), and the pre-`utils/pdda/` legacy layout path
    (`utils/PDDA-INSTALL.md`, named only in migration-note prose). A fresh `install.sh . --mode observe`
    self-inflicted ~30 dead-reference/env-var warns from exactly this mismatch on its very first
    `pdda.sh run`, drowning a new adopter's own repo drift in PDDA-on-PDDA noise. The dead-reference scan
    skips a match against `PDDA_GOV_SHIPPED_DOC_REF_EXEMPTIONS_DEFAULT`, scoped strictly to the docs in
    `PDDA_GOV_SHIPPED_DOCS_DEFAULT` — a repo-authored governance doc (e.g. this canonical repo's own `ROUTER.md`)
    referencing one of these is still a real dead-reference bug and is never exempted. The manifest was
    built from an actual dead-reference scan of a bare `install.sh` target, not retyped from an issue's
    illustrative list — re-run that scan if the shipped-doc set or its prose changes materially.
    **GH-17 (resolved separately from this manifest):** this file's own "CHANGELOG.md" section used to
    dead-reference two specific filenames (a retired recap note, a compliance-observations file) that
    turned out to be artifacts of the repo this contract doc was originally adapted from, never real
    files in this standalone PDDA repo. Naming them here was a copy-paste leftover, not a real PDDA
    requirement — genericized below rather than exempted, since a name that's dead *everywhere* is a
    real accuracy bug (Principle #4), not an install-boundary false positive like the manifest above.
  - **GH-23 P3 additions to the same manifest**, each read off a real scan of a bare
    `--with-startup-docs` target (46 warns before, 0 after), in three groups:
    canonical-only **tools** a target never receives (the installer itself; the sync engine, which
    `pdda-sync-manifest.conf` excludes because targets are leaf nodes; `templates/`; `test/`);
    **legacy flat-layout paths** (`utils/pdda.sh`, `utils/pdda-lib.sh`, …) that the install manifest names
    *precisely because they must not exist* — it documents the layout `install.sh` migrates away from,
    and their `.md` sibling was already exempt for this reason; and `config.sh`, which belongs to
    git-pulse, a separate program.
    **Known separate issue, not covered by this manifest:** this file's own CHANGELOG section
    dead-references the retired RECAP note-file and the REAL-AGENT-OBSERVATIONS compliance-findings
    file (see the "CHANGELOG.md" section below), neither of which exist anywhere in this repo, not
    even the canonical repo — a pre-existing doc-accuracy drift unrelated to the install-omission pattern above; left
    flagged rather than silently exempted pending a human decision on those files' fate.
- **orphan governance docs** (`warn`) — a present governance doc whose filename never appears anywhere
  in the index doc (`ROUTER.md` by default) — a doc a cold agent's startup sequence would never surface.
- **subcommand drift** (`error`) — every subcommand in `utils/pdda/pdda.sh`'s dispatcher `case` block
  must be named somewhere in the index doc. Parsing the `case` statement is mechanical (zero prose
  ambiguity), so this earns the same blocking severity as the structural checks — it is the concrete
  enforcement of AGENTS.md #5 ("keep the installer surface in lockstep").
- **env-var drift** (`warn`) — every `PDDA_*` token mentioned in a governance doc should actually be
  read or set somewhere in a shipped script (`utils/pdda/*.sh` or the repo-root `install.sh`). `warn`,
  not `error`: `utils/pdda/PDDA-INSTALL.md` ships to every target install but also documents
  `utils/pdda/pdda-sync.sh` — a canonical-only tool never copied to targets (it isn't in the "Canonical
  install set" above) — so a var like `PDDA_SYNC_BACKUPS` legitimately won't resolve in a target
  install's own scripts. That's expected, not drift, confirmed by installing this check into a second
  repo and seeing exactly that false positive fire — same calibration as dead-reference above.
  - **GH-15:** the same exemption mechanism above covers this class of mismatch too —
    `PDDA_GOV_SHIPPED_DOC_ENVVAR_EXEMPTIONS_DEFAULT` (`PDDA_REGISTRY`, `PDDA_GITPULSE_DIR`,
    `PDDA_SYNC_MAX_SHRINK`) lists canonical-only-tool env vars that `PDDA-INSTALL.md`/`PROJECT/PDDA.md`
    legitimately document but no target-installed script reads, scoped to the same `PDDA_GOV_SHIPPED_DOCS`
    set so a repo-authored doc's phantom env var still fires.

Expected exceptions:
- fenced `console`/`text`/`transcript` blocks and blockquote lines are not scanned (same carve-out as
  `pdda.sh hardcoded-paths`)
- override the doc set with `PDDA_GOVERNANCE_DOCS` (space-separated, repo-relative) and the index doc
  with `PDDA_GOVERNANCE_INDEX` (default `ROUTER.md`) for a repo with a different layout
- override the shipped-doc exemption manifest with `PDDA_GOV_SHIPPED_DOCS`,
  `PDDA_GOV_SHIPPED_DOC_REF_EXEMPTIONS`, and `PDDA_GOV_SHIPPED_DOC_ENVVAR_EXEMPTIONS` (all
  space-separated) for a repo with a different shipped-doc layout

This check is deterministic-only; it catches the mechanical drift classes above. Semantic
contradictions in prose (two docs stating conflicting policy, a claim that quietly went stale) are a
judgment call for the LLM layer or a human — see the `/governance-audit` skill, which runs this check
first and then reads the same doc set for that fuzzier class of inconsistency.

#### J. `pdda.sh releases`

Purpose:
- validate `RELEASES.md`, the single forward-looking release-planning ledger — deliberately light.
  This replaced an earlier per-tag-doc lifecycle (`PROJECT/releases/RELEASE-<tag>.md` with a
  Draft/RC/Published status, linked marathons, linked issues, and a GitHub release-tag cache) that
  turned out to be too much data to keep current for an initial release. Fields and checks grow
  only as a real need shows up — see "RELEASES.md — release ledger" below.

Scope: every `Release:` block in `RELEASES.md`.

Minimum behavior:
- parse `RELEASES.md` into blocks (one per `Release:` line; see format below)
- **release-value check**: `error` if a block's `Release:` value is empty (a malformed-doc guard,
  not a readiness gate)
- **target-date check** (optional field): `warn` if `Target Date` is set but is not a valid
  `YYYY-MM-DD` calendar date
- **overdue check**: `warn` if `Target Date` has passed and `Status` doesn't read exactly `Shipped`
  (case-insensitive) — `Status: Shipped` is the sole "already shipped" signal; a populated `GH_URL`
  alone does not silence this (it means a Release object exists, not that it shipped)
- **QA-gate field check** (optional fields): `warn` if `Front-door reviewed`, `Shakedown reviewed`,
  or `License file` is set but its value isn't exactly `Yes` or `No` (case-insensitive); a blank
  value is fine (not yet answered)
- **iteration-band check** (optional field): `warn` if `Iterations` is set but isn't a well-formed
  `<lo>-<hi>` band — both sides plain dotted-numeric, `lo` no greater than `hi`. Strict on purpose:
  a band nobody can evaluate is worse than no band, because the duplicate check below silently
  stops covering that release
- **in-band duplicate check**: `warn` if a block's `Release:` version falls inside a *different*
  block's reserved `Iterations` band. This is the admission rule made mechanical — a version inside
  a band is already accounted for, so a block for it is by definition a duplicate. Only plain
  dotted-numeric versions are tested; a prerelease or date-shaped version is left to human judgment
  rather than guessed at
- **never blocks, even in `full` mode** — this check does not gate its exit code at all, regardless
  of findings. The one `error` above (empty `Release:` value) is a malformed-doc guard, surfaced
  loudly so it isn't missed, but deliberately cannot fail a build

gh-degrade: none. The check is purely file-driven (no GitHub calls), which is a deliberate
simplification over the old per-tag-doc check's issue/tag cross-checks against `gh`.

#### RELEASES.md — release ledger

**`RELEASES.md` is an optional planning aid.** It is not a required artifact, not a checklist, and
not something to keep topped up. An empty file, a stale file, or no file at all are all valid
states — `pdda.sh releases` skips a missing file entirely ("RELEASES.md not found — nothing to
check") and never blocks, even in `full` mode.

**Do not proactively offer to fill it in, populate it, bring it current, or add a release that has
already shipped. Do not treat a sparse file as an incomplete one.** Edit it only when an operator
explicitly asks for release *planning*.

That instruction is aimed at the reader who is likeliest to erode this file, which is increasingly
an LLM maintainer. The failure mode is not one bad decision; it is a long series of individually
reasonable offers to help — "want me to add the release you just shipped?" — that in aggregate turn
a planning aid into a second, hand-maintained history of what shipped. Two sources of truth for the
same fact is the defect, and it arrives one helpful suggestion at a time. `CHANGELOG.md` is the
history. This file is not.

What it *is*: a first-class root file, like `ROADMAP.md`/`CHANGELOG.md` — a single forward-looking
planning ledger for major releases, not a lifecycle bucket of per-tag docs. Marathon plans and other
forward planning cross-reference it for target release names/dates.

**The admission rule.** A block earns its place by being worth *planning toward* — a named arc with
a theme, usually carrying a target date and a milestone. If the only thing that can go in
`Description:` is a restatement of what changed, it belongs in `CHANGELOG.md` and nowhere else.
Everything below the threshold goes in an `Iterations:` band (see the field docs) rather than getting
its own block.

The test is the theme, not the paperwork: `Target Date:` and `Milestone:` are optional fields and
their absence never disqualifies a block. A release can be worth planning toward before anyone knows
when it lands.

Format — one flat `Label: value` block per release, blank line between blocks (blank lines are
just visual spacing; a new block starts at the next `Release:` line). Field order is not parsed and
every field except `Release:` is optional, so a real block is usually shorter than this:

```text
Release: 1.0.0
Iterations: 1.0.0-1.0.4
Status: Draft
Target Date: 2026-07-31
Codename: n/a
Milestone:
Description:
Exit criterion:
Manifest:
GH_URL:
Front-door reviewed:
Shakedown reviewed:
License file:
```

Fields:
- `Release:` (required) — the version being planned
- `Status:` (optional) — free-text, unvalidated by design (`Draft`, `Working`, `Shipped`, whatever
  an operator finds useful). **`Status: Shipped` is the sole "already shipped" signal** — both
  `pdda.sh releases`'s overdue nudge and `pdda.sh releases-current`'s "in progress" filter key off
  it exclusively. This is a rough signal, not a gated lifecycle — no fixed vocabulary is enforced.
- `Iterations:` (optional) — a **reserved band of version numbers**, written `<lo>-<hi>` (e.g.
  `0.2.0-0.2.4`). Versions inside a band ship freely and are recorded in `CHANGELOG.md` only; they
  **never get a block here**, and the band deliberately does not enumerate them. Absence of the
  field means no band is reserved.

  **The band's owner is the one exception.** A band is written on the block it belongs to, and that
  block's own `Release:` is the band's `<lo>` — so the owner sits inside its own band and keeps its
  block. Every *other* version in the range is covered by the band and gets none. `pdda.sh releases`
  identifies the owner by line, not by version text, so a second block that merely repeats the
  owner's version is still caught as the duplicate it is.

  This is what gives the admission rule an answer instead of an argument. "Where does 0.2.3 go?"
  resolved case-by-case is resolved by adding a row, every time; with a band it has a written
  answer, and `pdda.sh releases` can check it — a version inside an existing band is already
  accounted for, so a block for it is by definition a duplicate. That is testable in a way "is this
  release meaningful?" never will be.

  **When a band is exhausted** — `0.2.5` is needed and the band ends at `0.2.4` — **widen the band.
  Do not start enumerating, and do not add a block.** Promote to the next release only when the work
  genuinely became a new arc with its own theme, never merely because the numbers ran out; a version
  number driven by an accounting artifact is the convention rotting rather than holding.

  Rejected alternative, recorded so it isn't re-proposed: persisting `Iteration 1:` … `Iteration 5:`
  labels per release. That is 20–25 named rows across a five-release horizon, each an invitation to
  fill in what shipped — the same drift, arriving as structure instead of as appended blocks. One
  optional field beats five required ones.
- `Target Date:` (optional) — `YYYY-MM-DD`; `pdda.sh releases` warns once this passes and `Status`
  doesn't read `Shipped`
- `Codename:` (optional) — `n/a` is fine
- `Milestone:` (optional) — free-text, unvalidated, the **release → issue-set join key**. It holds a
  GitHub milestone *title*, so a release's scope can be queried rather than hand-maintained here:

  ```bash
  gh issue list --milestone "Quicksilver" --state open --json number,title,labels
  ```

  That query *is* release-driven work selection, with no second cache and no issue list copied into
  this file — which is why the field is worth having and why it stays a pointer. Unvalidated for the
  same reason as `Status:`: checking a title against GitHub would need a `gh` call, and this check is
  deliberately network-free. **Not warned on when absent** — a release with no milestone is a normal
  state, and a nudge here would recreate exactly the fill-it-in pressure this section exists to stop.
- `Description:` (optional) — a concise one-to-four-sentence statement of the release theme. It is
  not a run log, implementation plan, or second changelog; historical outcomes stay in
  `CHANGELOG.md` and execution detail stays in the canonical `PROJECT/**` document. `/releases`
  warns when this field exceeds four sentences or becomes multi-paragraph history.
- `Exit criterion:` (optional) — one runnable command or observable condition that proves the arc
  reached its goal. Keep the implementation and phased QA plan in `PROJECT/**`; this field is the
  release-level goalpost only.
- `Manifest:` (optional) — a concise, fixed release boundary, normally a dated `FROZEN` list of
  issue IDs. Prefer `Milestone:` when the intent is a live issue-set query. `/releases` triggers an
  ambition review above seven named issues and when the list mixes themes, grows without a dated
  re-scope, or lacks an exit criterion; the count is advisory, never an automatic rejection.
- `GH_URL:` (optional) — populated once *a* GitHub Release object exists, including a draft (see
  `/releases publish`). **This means "a Release object exists," not "shipped"** — a draft's
  `GH_URL` is real but the release isn't out. Flip `Status: Shipped` yourself (or let
  `/releases publish` do it on an actual, non-draft publish) when it's really out; `GH_URL` alone
  no longer implies that.
- `Front-door reviewed:` / `Shakedown reviewed:` / `License file:` (optional) — pre-release QA-gate
  checkboxes: has the `/front-door` onboarding audit run, has the `/shakedown` script-path audit
  run, is a `LICENSE` file present. `Yes` or `No`; `pdda.sh releases` warns on any other non-blank
  value. A blank value just means not yet answered, not a failure.

Add new fields only when a real need shows up. This format intentionally started smaller than the
earlier per-tag-doc convention (status lifecycle, linked marathons, linked issues, a GitHub
release-tag cache) — that was more data than was practical to keep current for an initial release.
`Status:` is the first field added back in, deliberately kept unvalidated (baby steps, not a new
gated lifecycle) rather than reintroducing the old rigid `Draft → RC → Published` enum. The three
QA-gate fields are the second: a real pre-release checklist need (open-sourcing a release means a
front-door pass, a shakedown pass, and a `LICENSE` file all need to be true before shipping) that,
unlike `Status`, has an unambiguous right answer — so they're validated `Yes`/`No` rather than free-text.
`Iterations:` and `Milestone:` are the third pair, and both are additive: the parser ignores labels
it doesn't know, absence means "not reserved" / "no milestone", and neither produces a finding in a
ledger that has never used them. A repo can adopt them, or never hear of them, with no migration.

One repo-owned skill operates on this file: `/releases`. It is a read-first router that synthesizes
the ledger, checks evidence-backed contradictions against `CHANGELOG.md`, reachable commits, merged
PRs, and GitHub Releases when available, then enters cleanup, author/update, historical-anchor, or
publish subroutines only on an explicit operator request. Every mutation and public release is
previewed and confirmation-gated. Its strategic-drift handoff is `/radar`; its frozen path-to-ship
handoff is `/finish-line`. It recommends either only when that distinct goal matches and never
duplicates or auto-invokes their workflows.

Invocation is operator-triggered by design. The initial synthesis may report contradictions in an
existing ledger, but it must never treat an absent, sparse, or merely old file as unfinished work or
offer to top it up. A skill that exists to keep this file populated is the most efficient possible
way to violate the optionality rule at the top of this section.

#### `pdda.sh releases-current`

Read-only roll-up (not part of `PDDA_DETERMINISTIC_CHECKS` — emits no findings, never gates): lists
every `RELEASES.md` entry whose `Status` is empty or not exactly `Shipped`. A rough, non-authoritative
answer to "what's currently in progress" — for a human, or for another repo's tooling (e.g. the XYZ
sibling harness) to shell out to instead of re-implementing `RELEASES.md` parsing itself. Because
`Status` is free-text, this is a best-effort filter, not a guarantee — an entry with a typo'd or
unconventional `Status` value still shows up (safer default: never silently hide something that
lacks an explicit `Shipped` signal).

The four-tier shipping chain:

```
task/issue  (GH-*.md in 1-INBOX)
  → project (2-WORKING active doc)
    → marathon (marathon/MARATHON-*.yaml + PROJECT/2-WORKING/MARATHON-PLAN-*.md)
      → release (RELEASES.md entry + GitHub Release)
```

### 2. LLM-assisted doc readiness review

This catches the issues where structure exists but planning quality is weak.

#### `pdda-doc-ready.sh`

Purpose:
- review active project plans and flag docs that are not ready for reliable automation

It should check for:

- phased plans missing QA gates after a phase
- phase sections with actions but no observable acceptance criteria
- multi-phase plans missing a table of contents listing each phase
- discovery or spike phases whose findings were not written back into the plan doc
- medium-large plans missing the triage ratings (`effort`, `complexity`, `risk`, `phases`)
- status tables that are technically present but stale versus the body
- docs that bury the next action in prose instead of making it explicit
- plans that duplicate detail already meant to live in another canonical doc
- contradictory status, such as frontmatter saying `Completed` while the body says active

It should not:

- auto-rewrite the plan body without review
- invent technical claims not grounded in the doc
- silently override deterministic lints
- **block a build.** The LLM layer is advisory: its findings are capped at `warn` (any model `error`
  is clamped to `warn` in `pdda-doc-ready.sh`), so a non-deterministic oracle can never fail a build —
  the same doc must not pass at 2pm and fail at 3pm. Only deterministic checks earn blocking power.

### 3. Doc-health hooks (event-triggered delivery)

The deterministic checks above can also run automatically from Claude Code hooks, as a two-tier
doc-health system. The hooks are pure **delivery** — they run the SAME section-1 checks on a trigger;
they add no new analysis class. Both are **warn-only and fail-open: they always exit `0` and can never
block** an edit or a stop (a doc-hygiene reminder is never worth interrupting work — the calibration
principle, same as `pdda.sh changelog`).

- **Tier 1 — `pdda-edit-doc-hook.sh` (`PostToolUse` on `Edit|Write|MultiEdit`).** Reads the edited
  `tool_input.file_path`; exits `0` instantly unless it is `ROADMAP.md` or a `PROJECT/**/*.md` doc;
  otherwise runs the fast **local single-file** subset for just that file — `frontmatter`,
  `status-table`, `hardcoded-paths`, `roadmap-coverage` (and `roadmap` for `ROADMAP.md`), scoped via
  `PDDA_ONLY_FILE`. **No network, no `gh`, no LLM**, so it stays instant and cannot gate an edit.
- **Tier 2 — Stop full-scan (`pdda-stop-doc-health.sh`).** The companion that runs one consolidated,
  system-wide doc-health scan per turn (the deterministic suite plus `issue-doc-sync` against the
  cached gh-state file). See [Suggested Stop doc-health scan](#suggested-stop-doc-health-scan).

`PDDA_ONLY_FILE=<path>` is the seam that scopes any check to a single file (unset = full scan, the
default everywhere else). Wiring is repo-local in `.claude/settings.json`; installs receive the hook
scripts via the manifest and opt in by adding the hook entries.

#### Suggested Stop doc-health scan

Tier 2's `pdda-stop-doc-health.sh` runs **one** system-wide scan per turn and prints a **single
consolidated report**:

- it runs the deterministic suite with `PDDA_ISSUE_SYNC_SOURCE=cache`, so `issue-doc-sync` reads the
  cached gh-state file (written by `pdda.sh gh-refresh`) and the scan makes **no network call**;
- it runs in `observe` mode with the LLM layer disabled — purely deterministic, fast, offline;
- it aggregates the run into one report: a header with the error/warn totals, then the warn/error
  finding lines (an `all clear` line when there are none);
- it **always exits `0`** (proven by `test/pdda-doc-health-hooks.sh`), so it can never block a stop.

Wire it as a `Stop` hook in `.claude/settings.json` (no matcher). Because it reads the cache rather
than calling `gh`, keep `pdda.sh gh-refresh` on the hourly cadence so the Stop report stays current.

## Enforcement modes

PDDA runs in one of three modes. The mode is resolved in this order: **the `PDDA_MODE` env var wins if
set; otherwise the first non-comment line of a repo-root `.pdda-mode` file; otherwise the built-in
default `observe`.** (So an env var overrides a committed `.pdda-mode` — convenient for a one-off
`PDDA_MODE=observe` pass against a repo otherwise committed to `full`.) The point is an **adoption
ramp**: a freshly-installed PDDA should never break a build on day one, and a project should graduate
onto the rails deliberately.

| Mode | When | Findings reported | Exit on `error` |
|---|---|---|---|
| `observe` | just installed | yes | always `0` |
| `light` | transitioning | yes | `0` (warn, don't block) |
| `full` | fully on rails | yes | non-zero (blocks) |

- The default is `observe` so a brand-new install is non-blocking — it shows the team what PDDA
  *would* flag without failing anything.
- `light` is the transition phase: loud reports, but still never fails a build, while the backlog of
  doc debt is cleared.
- `full` is the strict end state: `error` findings block with a non-zero exit. A repo declares it by
  committing `.pdda-mode` with `full`.
- **No mode mutates the tree.** Stale docs are *flagged, never auto-moved* — the only destructive
  mechanic was removed (see the stale-doc check above). Mode controls one thing only: whether an
  `error` blocks. Every check ends with `exit "$(pdda_gated_exit "$EXIT_CODE")"`, which returns the
  real code only in `full`.

## Roadmap ledger contract (ROADMAP.md / releases.db)

The roadmap ledger (stored as `ROADMAP.md` in legacy repos or in `releases.db` in releases-mode repos) is a pointer file/ledger, not a plan body.

It should contain:

- queued / parked intake pointers for newly captured `GH-*.md` docs
- projects in progress
- completed work
- attempted work
- deferred work
- links to the canonical project docs

It should usually not contain:

- detailed phase checklists
- step-by-step build instructions
- deep execution notes already owned by a project file

Strict exemption:
- a short exception note is allowed when omitting the note would hide an operationally critical fact

Maintainer rule:
- when a roadmap entry needs more than a one-line status + a link, that is the signal to put the
  detail in the entry's `PROJECT/**` doc and leave only the pointer here — do not grow the roadmap

Coverage rule:
- every active doc in `PROJECT/2-WORKING` must be reflected here by a pointer (a one-line ledger entry
  that links it), so the ledger never falls behind the working set. A working doc that legitimately
  should not appear opts out with `roadmap_exempt: true` in its frontmatter. This is the inverse of the
  "no detail leaks in" rule above: nothing active goes *missing from* the roadmap either.
- every captured GitHub issue doc in `PROJECT/1-INBOX/GH-*.md` must also be reflected here as a
  one-line **queued / parked** pointer until it is promoted, deferred out, or closed, so intake cannot
  quietly disappear and later be duplicated.

How this is enforced (so it cannot quietly rot in either direction):
- **deterministic (no leak in)** — `pdda.sh roadmap` errors on task checklists / `### Checklist` /
  `### QA checklist` headings and warns on size sprawl (runs hourly, free, no model needed)
- **deterministic (no gap missing)** — `pdda.sh roadmap-coverage` errors when either an
  active `PROJECT/2-WORKING` doc has no pointer here, or a captured `PROJECT/1-INBOX/GH-*.md` doc is
  not parked here as a queue entry (honors `roadmap_exempt: true`)
- **LLM** — `utils/pdda/pdda-doc-ready.sh` reviews `ROADMAP.md` against the full pointer contract for the
  fuzzier "this paragraph is really execution detail" cases (honors the carve-out)
- the file itself carries a top banner restating the contract, so a human editing it sees the rule

## CHANGELOG.md — end-of-iteration record (first-class)

`CHANGELOG.md` is a first-class PDDA artifact: the canonical, newest-first running log of what changed,
updated **at the end of each iteration**. It is the one narrative/provenance log this contract
prescribes — if an adopting repo kept its own ad hoc recap or run-observation notes before adopting
PDDA, `CHANGELOG.md` supersedes them; PDDA does not require or name any such file itself (Principle #4 —
one canonical place per fact). Durable Costly / one-way-door bets still earn a `decisions/` record.
updated **at the end of each iteration**. It supersedes the retired RECAP convention as the running
provenance/narrative log, and it also absorbs the run-specific compliance findings the retired
REAL-AGENT-OBSERVATIONS convention used to collect. Durable Costly / one-way-door bets still earn a
`decisions/` record.

It should contain:

- newest-first, dated sections headed either `## YYYY-MM-DD` or `## [x.y.z] - YYYY-MM-DD`
- one entry per substantive iteration: what changed, why, and the verification (test / suite result)
- the bet behind a consequential change when one applies (the call, the expected signal, reversibility)

It should not contain:

- per-file diffs or deep execution detail that belongs in the entry's `PROJECT/**` doc
- aspirational plans — those live in the project doc and the `ROADMAP.md` ledger

Maintained append-only:

- add a new dated entry per iteration; **never rewrite a past entry's numbers, claims, or
  recommendation** — *especially* not when it turned out wrong. Correct a past entry by appending a
  dated correction, not by editing history. This append-only guarantee is the whole point of having one
  canonical narrative log instead of scattered ad hoc notes.
  dated correction, not by editing history. This is the provenance guarantee the retired RECAP
  convention used to carry.

Recording a bet (when a change is consequential):

- when a decision is Costly, a one-way door, or rides on an assumption that could be wrong, the entry
  records the call, the bet/assumption, the expected signal with a by-when, the reversibility read, a
  revisit trigger, and a graduate / iterate / abandon recommendation. Below that threshold a plain
  entry suffices. Durable bets also earn a `decisions/` record. An adopting repo is free to keep its own
  separate run-specific compliance-observations doc if that's useful to it, but that's a local
  convention this contract neither requires nor names. (`AGENTS.md` principle #7 supplies the
  behavioral trigger — *record the bet*; this contract owns the *where and how*.)
  entry suffices. Durable bets also earn a `decisions/` record; run-specific compliance findings go in
  the iteration's own `CHANGELOG.md` entry. (`AGENTS.md` principle #7 supplies the behavioral trigger —
  *record the bet*; this contract owns the *where and how*, so governance is not fragmented across the
  two files.)

How this is enforced (a nudge, not a gate):
- **deterministic** — `pdda.sh changelog` **warns** (never `error`, so it never blocks —
  even in `full`) when the newest dated entry predates the latest git commit by more than
  `PDDA_CHANGELOG_STALE_DAYS` days (default `0`), i.e. an iteration shipped without a changelog entry
- whether an entry is actually *substantive* stays a human / LLM judgment, not a regex

## Activity log artifact

PDDA should write an append-only activity log to:

- `PROJECT/PDDA-ACTIVITY.jsonl`

Each script run should append:

- per-finding entries
- one summary entry for the script
- enough metadata to tell what moved, what failed, and when

## Suggested hourly schedule

Run the deterministic checks every hour in this order:

1. `pdda.sh frontmatter`
2. `pdda.sh status-table`
3. `pdda.sh hardcoded-paths`
4. `pdda.sh roadmap`
5. `pdda.sh roadmap-coverage`
6. `pdda.sh changelog`
7. `pdda.sh stale`
8. `pdda.sh issue-doc-sync`
9. `pdda.sh releases`
10. `pdda.sh governance`

Then run:

11. `pdda.sh doc-ready`

(`pdda.sh run` runs exactly this sequence and applies the active `PDDA_MODE` gate. Scheduling the
single aggregate command is the recommended hourly cron entry.)

The cached GitHub issue-state refresh is a separate, network-only step. Run `pdda.sh gh-refresh`
(the standalone `utils/pdda/pdda-gh-refresh.sh`) on the same hourly cron/launchd cadence, **before**
the suite, so `issue-doc-sync` and the Stop doc-health scan read fresh state. It is the only step that
needs `gh`/the network; it writes `PDDA_GH_STATE_CACHE` atomically and leaves the existing cache
untouched on any `gh` failure, so the suite itself stays offline-tolerant by reading the cache.

Reason for the order:

- deterministic failures should surface first
- the network-dependent `issue-doc-sync` runs last among the deterministic checks, so every local
  check still completes when `gh` is offline (it then degrades to the cache or an `info` skip)
- the LLM review should spend time only on docs that passed basic structural hygiene

## Suggested output contract

To make these scripts composable, each should emit:

- a short human-readable summary to stdout
- a machine-readable result format, ideally JSON lines
- non-zero exit when blocking issues are found

Suggested fields per finding:

- `severity`
- `check`
- `file`
- `line`
- `message`
- `action`
- `timestamp`

Severity proposal:

- `error`: automation-blocking
- `warn`: should be fixed soon but not blocking
- `info`: advisory only

## Readiness rubric for automation

A doc is "automation ready" when:

- it is in the correct lifecycle folder
- it has valid frontmatter
- it has the exact status table
- the next action is singular and explicit
- each phase has a visible QA gate
- a multi-phase plan has a table of contents listing its phases
- any discovery or spike phase has its findings written back into the doc
- links to canonical related docs are present where needed
- there are no hardcoded absolute paths
- `ROADMAP.md` is pointing at it rather than duplicating it

## Failure modes PDDA is trying to prevent

- active docs with no visible next step
- too many half-live docs in `PROJECT/2-WORKING`
- plans that look complete but have no verification gates
- stale working docs silently lingering forever
- roadmap sprawl where detail leaks into `ROADMAP.md`
- agent sessions restarting the same reasoning because the doc never captured "what changed"

## Proposed extensions not yet locked

These are likely useful for full automation, but they are still policy choices:

- a `doc_type` field such as `project`, `bugfix`, `research`, `feedback`, `roadmap`
- ~~a `priority` field if you want deterministic triage beyond folder placement~~ **superseded** by the
  `effort`/`complexity`/`risk`/`phases` [triage ratings](#triage-ratings-for-medium-large-work), which
  give richer triage than a single priority scalar — automation derives the selection signal from them
  rather than storing one frozen number
- a `pdda_hold: true` override for docs that should remain in `2-WORKING` despite inactivity
- a second generated PDDA summary artifact beyond the activity log

## Open questions

These need a decision before the automation should be considered stable:

1. Should `PROJECT/PDDA-ACTIVITY.jsonl` remain append-only forever, or rotate by month once the volume grows?
2. Should `ROADMAP.md` remain root-level canonical only, or do you also want a project-local roadmap index under `PROJECT/`?

Resolved:

- ~~Should the compatibility window end on `2026-07-31`, or be shorter/longer?~~ **Resolved
  2026-06-22:** removed entirely. No doc in the repo used an old alias, so a dated cutover guarded
  nothing — and a script whose behavior changes silently on a hardcoded date is the same fossilized
  assumption the hardcoded-path check exists to prevent. Headers are now exact-or-`error`, no window.
- ~~Should `gh_issue` stay optional metadata, or become required for bug-fix docs that originated from
  GitHub?~~ **Resolved 2026-06-21:** `gh_issue` stays optional in general, but is **required** on any
  doc that originated from a GitHub issue — which the `GH-<number>-…` filename guarantees. See
  [GitHub issue intake](#github-issue-intake).

## Recommended v1 stance

If the goal is "get project docs onto rails quickly," the safest v1 is:

- start in `observe` mode, then graduate `light` → `full` as the doc backlog is cleared
- enforce exact status-table headers (no alias window)
- require QA gates on phased plans
- forbid hardcoded absolute paths
- run deterministic checks hourly
- let the LLM reviewer flag readiness issues
- keep `ROADMAP.md` pointer-only (deterministic `pdda.sh roadmap` + the LLM rubric guard it)
- append all script activity to `PROJECT/PDDA-ACTIVITY.jsonl`
# Test Results & Artifacts (`TESTS-RESULTS/`)

This directory contains committed execution artifacts, benchmark datasets, and structured telemetry logs from autonomous testing campaigns (such as ATE variation runs, fuzzing loops, and harness evaluations).

## Purpose

Per repo rail **Rule 6 ("Verified beats plausible" / GH-430)**, claims cited in issues, PRs, ROADMAP entries, or model registries must be backed by retained, verifiable evidence. This directory provides a permanent, auditable home for these empirical test receipts.

## Directory Structure

Each testing campaign is recorded in a dedicated subfolder following the naming convention:

```
TESTS-RESULTS/
├── README.md
└── YYYY-MM-DD+GH-<issue-number>/
    ├── SUMMARY.md                          # Human-readable rollup & configuration details
    ├── error_log.jsonl                     # Structured telemetry & classifier output
    └── <benchmark-name>.jsonl              # Raw baseline measurements & metrics
```

### Contents of Each Folder

1. **`SUMMARY.md`**: Overview of the run, duration, model/harness under test, variations matrix, and high-level findings.
2. **`error_log.jsonl`**: Machine-readable JSONL records containing versioned schemas (`schema_version: "1.0"`), iteration metrics (`duration_ms`, `turn_count`, `prompt_tokens`, `completion_tokens`, `total_tokens`), command outputs, and local LLM classifications.
3. **Receipts & Baselines (`*.jsonl`)**: Raw trial outputs backing entries in `HARNESS-MODELS-REGISTRY.md` or active working docs.

## How to Inspect Results

To inspect recent runs or summarize triage distributions:

```bash
python3 utils/ate/scripts/checkin.py --tail 50 \
  --log "TESTS-RESULTS/YYYY-MM-DD+GH-<issue-number>/error_log.jsonl"
```
---
name: review-code
description: >-
  Meticulous code and pull request review ladder using /recon and /debug-mantra to test out each
  fix and feature against live ground truth. Supports PR targets under review-PR / --pr <PR#>.
  Loops through /workhorse and /unstuck ladders to autonomously resolve reversible adaptations and
  pivots without stopping for operator permission, driving verified forward movement.
metadata:
  argument-hint: "[diff, branch, file, or --pr <PR#>]"
---

# /review-code (and /review-pr) — Meticulous Ground-Truth Code & PR Review Ladder

`/review-code` is an empirical code and pull request review discipline that treats every proposed
change as a claim requiring firsthand verification. Rather than passively reading a diff and commenting
on style or plausible appearance, `/review-code` actively maps the system's blast radius, tests
fixes and features against live execution, and uses autonomous problem-resolution ladders to drive
forward movement.

It coordinates four specialized disciplines into a cohesive review workflow:
1. **[`/recon`](../../1-hourly/recon/SKILL.md)**: Seam and blast-radius mapping across callers, data
   flows, public contracts, and operational failure paths before forming an opinion.
2. **[`/debug-mantra`](../../1-hourly/debug-mantra/SKILL.md)**: Meticulous ground-truth testing.
   Falsifies symptom-fix patches, executes mutation tests to watch assertions go red, and verifies
   feature acceptance criteria with negative controls and measured evidence.
3. **[`/workhorse`](../workhorse/SKILL.md)**: Governed defect resolution ladder. Triages review
   findings into an atomic priority queue (`[Blocker]`, `[Should]`, `[Nit]`, `[Pass]`) and enforces
   least-mechanism architecture ([`/ponytail`](../../1-hourly/ponytail/SKILL.md)), governance compliance,
   and preservation invariants.
4. **[`/unstuck`](../../1-hourly/unstuck/SKILL.md)**: Autonomous forward movement and anti-hesitation
   engine. Classifies adaptations on the Reversibility Scale (`Easy` vs `Costly` vs `One-way door`):
   **autonomously adapts and tests `Easy` reversible pivots without stopping to prompt the operator**,
   freezes cogs, and applies foundational unblocking moves.

---

## Recite this — verbatim, as the first thing in your first response

> **Review-Code Discipline:**
> 1. **Ingest target & map blast radius (Phase 1 /recon).** Ingest the diff or PR (`review-PR`), map callers, state mutations, contracts, and failure paths before evaluating code.
> 2. **Meticulously test fixes & features (Phase 2 /debug-mantra).** Test every fix against root cause (falsify symptom patches; mutate guards to watch them fail) and verify feature acceptance criteria with measured ground truth and negative controls.
> 3. **Autonomous resolution & anti-hesitation (Phase 3 /workhorse + /unstuck).** If pivots or adaptations are needed, classify reversibility (`Easy`/`Costly`/`One-way door`): autonomously adapt and test `Easy` changes without operator round-trips; freeze cogs and execute foundational unblocking moves.
> 4. **Grade & synthesize verified findings (Phase 4).** Categorize findings (`[Blocker]`, `[Should]`, `[Nit]`, `[Pass]`) with exact `file:line` citations, emit the actionable checklist, and post or report PR verdict.
>
> **Overall Goal:** Every fix and feature verified against live behavior rather than plausible appearance, with reversible issues resolved autonomously and review conclusions grounded in runnable proof.

Then begin work. When `/review-code` (or `/review-pr`) is the active orchestrating skill, this recital
precedes subordinate skill invocations; subordinate skills ([`/recon`](../../1-hourly/recon/SKILL.md),
[`/debug-mantra`](../../1-hourly/debug-mantra/SKILL.md), etc.) are then loaded for their mechanics
without conflicting recitals.

---

## The 5-Phase Review Ladder

```text
Phase 0: Target Intake & Scope Resolution  ──► Local diff/branch vs GitHub PR (`review-PR`); isolate refs & context
                 │
                 ▼
Phase 1: Seam & Blast Radius Recon (/recon)──► Map callers (Lane A), state (Lane B), contracts (Lane C), tests (Lane D)
                 │
                 ▼
Phase 2: Meticulous Ground-Truth Testing   ──► Fixes: Repro -> trace fail path -> mutate-to-red (falsify)
         (/debug-mantra)                   ──► Features: Measured ground truth -> falsify criteria -> negative controls
                 │
                 ▼
Phase 3: Autonomous Pivot & Resolution     ──► Classify reversibility: Easy (autonomous forward move) vs Costly vs One-way
         (/workhorse + /unstuck)           ──► Self-invoke /unstuck on hesitation tripwires; apply /ponytail root-cause fix
                 │
                 ▼
Phase 4: Graded Findings & PR Actionability──► [Blocker] / [Should] / [Nit] / [Pass] with mandatory file:line citations;
                                               structured report, actionable checklist, and PR verdict / comment
```

---

## Phase 0: Target Intake & Scope Resolution

Resolve the exact target under review. Two primary entry modes are supported:

### Mode A: Local Code Review (`/review-code`)
Used for uncommitted working tree changes, staged diffs, branch diffs against upstream, or targeted files:
```bash
# Review uncommitted changes against HEAD
git diff HEAD

# Review current branch against development baseline
git diff origin/development...HEAD

# Stat changes to size the review blast radius
git diff --stat origin/development...HEAD
```

### Mode B: GitHub Pull Request Review (`review-PR` / `/review-code --pr <PR#>`)
Triggered via `review-PR`, `/review-pr <PR#>`, or `/review-code --pr <PR#>`:
```bash
# Inspect PR metadata, base branch, head branch, author, and description
gh pr view <PR#> --json number,title,body,baseRefName,headRefName,headRefOid,author,state

# Fetch the raw unified diff for the PR
gh pr diff <PR#>

# Inspect linked issues (Fixes #..., Closes #..., GH-...) and project documentation
grep -E "(Fixes|Closes|Resolves) #[0-9]+" <<< "$(gh pr view <PR#> --json body -q .body)"

# Check hosted CI check run statuses
gh pr checks <PR#>
```

**Scope Invariant:**
- Identify the target branch: ensure the PR targets the active WIP branch (`development`), not `main` (per orchestrator rails).
- Size the diff: a targeted bug fix should typically be focused (< 500 lines); large architectural diffs require all 4 recon lanes.

---

## Phase 1: Seam & Blast Radius Recon ([`/recon`](../../1-hourly/recon/SKILL.md))

A diff read in isolation is plausible fiction. Code review requires knowing what callers, state,
contracts, and failure modes are touched by the modification.

Run the four recon lanes across the touched symbols:

| Lane | Focus | Review Inquiry & Verification |
|---|---|---|
| **Lane A. Entry & Call Paths** | Callers & Dispatch | Trace callers of all modified functions. Did call signatures, parameter defaults, or return types change? Are callers in other modules updated? Check CLI shims, hook registries, plugin dispatch, and event handlers. |
| **Lane B. State & Data Flow** | Readers & Writers | What state is mutated? Verify the single-writer invariant. Are SQLite locks, file descriptors, transactions, or cache layers handled? Does this introduce competing write paths or dirty reads? |
| **Lane C. Contracts & Boundaries** | APIs & Protocols | Do changes alter public APIs, CLI flags, JSON schemas, environment variables, or error codes? Check consumers across sibling modules or external repositories. |
| **Lane D. Build, Failure & Tests** | Errors & Coverage | How does this code fail? Trace timeouts, process exits, broken pipes, signal handling (`SIGINT`/`SIGTERM`), and missing input files. What existing test suites cover this seam? |

**Graph & Source Lookup:**
- Prefer MCP graph tools (`search_graph`, `trace_path`, `get_code_snippet`) when available to locate callers and dependencies in one call.
- Fall back to targeted ripgrep / file inspection when MCP tools are unavailable.
- **The One Rule:** Every caller cited in the review must exist at `file:line`. Anything unread or unverified is recorded under **Unknowns**, never assumed safe.

---

## Phase 2: Meticulous Ground-Truth Testing ([`/debug-mantra`](../../1-hourly/debug-mantra/SKILL.md))

Verified beats plausible. Reviewers must not merely read code; they must test the behavior of
fixes and features against live reality.

### 1. Testing Fixes (Root Cause vs. Symptom-Fix Trap)

When reviewing a bug fix, apply the four debug mantras rigorously:

1. **Mantra 1 — Reproduce reliably:**
   - Verify there is an automated regression test reproducing the original defect.
   - If the regression test is missing, write one or require it before approving.
2. **Mantra 2 — Trace the fail path:**
   - Trace from the crash or incorrect output back to the root cause origin.
   - **The Symptom-Fix Trap:** Actively scrutinize whether the fix merely patches symptoms at the
     crash site (e.g. adding `try/except: pass`, defaulting a `None`, coercing types, adding loose
     regexes, or using `|| true`) while leaving the corrupt state producer intact upstream.
     *The crash site is where the invariant was checked; the bug is where it was broken.*
     A fix that masks the crash without preventing the bad state is a `[Blocker]`.
3. **Mantra 3 — Falsify the fix (The Mutation Test):**
   - **"A check that cannot fail is not a check."**
   - Mutate the fix in a disposable environment:
     - Invert the condition (`if not valid` → `if valid`).
     - Comment out the guard or remove the correction.
     - Transpose arguments or return dummy values.
   - Run the test suite: **Did the test turn RED?**
   - If the test still passes when the fix is broken, the test is decorative and reports confidence
     it never earned. This is a mandatory `[Blocker]`.
4. **Mantra 4 — Cross-reference breadcrumbs:**
   - Walk recent `CHANGELOG.md` entries and git history. Does this fix repeat a previously failed
     pattern or reopen a settled architectural decision?

### 2. Testing Features (Acceptance Criteria & Boundary Invariants)

When reviewing a new feature or enhancement:

1. **Measured Ground Truth at Review Time:**
   - Execute the feature's entry points directly. Do not rely on claimed execution logs.
   - Verify outputs, return codes, and side-effects match specifications.
2. **Falsify Acceptance Criteria:**
   - **"An empty input passes every check."** Verify that empty strings, missing files, or zero-byte
     inputs fail loudly rather than passing vacuously through unhandled command substitutions or
     permissive wildcards.
   - Size-check extracted artifacts before asserting correctness over them.
3. **Negative Controls & Boundary Stress:**
   - Test invalid CLI arguments, malformed configuration files, and nonexistent paths.
   - Test concurrency and lock contention (e.g. parallel runs of `./validate.sh` or concurrent database access).
   - Test idempotency: does running the feature twice in succession produce identical, safe results without duplicate records or side effects?

---

## Phase 3: Autonomous Pivot & Resolution Loop ([`/workhorse`](../workhorse/SKILL.md) + [`/unstuck`](../../1-hourly/unstuck/SKILL.md))

When review or ground-truth testing surfaces failures, gaps, or necessary adaptations, the agent
must avoid constant round-trips to the operator for routine adjustments.

### 1. The Reversibility Decision Matrix

Classify every necessary adaptation or pivot on the repository's shared scale:

```text
┌─────────────────────────────────────────────────────────────────────────────┐
│                       REVERSIBILITY CLASSIFICATION                          │
├─────────────────┬──────────────────────────────────┬────────────────────────┤
│ Classification  │ Scope & Characteristics          │ Action & Protocol      │
├─────────────────┼──────────────────────────────────┼────────────────────────┤
│ EASY            │ - Local test assertion fixes     │ AUTONOMOUSLY EXECUTE   │
│                 │ - Edge-case input handling       │ - Do NOT ask operator  │
│                 │ - Defensive parameter checks     │ - Implement & test     │
│                 │ - Fixing a typo or broken regex  │ - Record in ledger     │
│                 │ - /ponytail least-mechanism diff │ - Drive forward move   │
│                 │ - Adding missing negative tests  │                        │
├─────────────────┼──────────────────────────────────┼────────────────────────┤
│ COSTLY          │ - Re-architecting shared schema  │ PREPARE ROLLBACK & ASK │
│                 │ - Breaking public API contracts  │ - Formulate 2 options  │
│                 │ - Introducing new dependencies   │ - Prove rollback path  │
│                 │ - Major coordination changes     │ - Await confirmation   │
├─────────────────┼──────────────────────────────────┼────────────────────────┤
│ ONE-WAY DOOR    │ - External resource deletion     │ HARD STOP & CONFIRM    │
│                 │ - Publishing secrets / tokens    │ - Name permanent loss  │
│                 │ - Destructive database drops     │ - Require operator OK  │
│                 │ - Upstream force-pushes          │                        │
└─────────────────┴──────────────────────────────────┴────────────────────────┘
```

**Autonomous Action Rail:**
If a change is classified **`Easy`** and directly resolves a review blocker or test failure to allow
forward movement, **execute the adaptation immediately**. Do not stop, narrate hesitation, or prompt
the operator for permission. Document the pivot cleanly in the final report.

### 2. The Unstuck Anti-Hesitation Engine ([`/unstuck`](../../1-hourly/unstuck/SKILL.md))

Self-invoke the [`/unstuck`](../../1-hourly/unstuck/SKILL.md) interrupt when encountering any of the
four autonomous tripwires:
1. **Two-Turn No-Milestone Tripwire:** Catching yourself asking "Should I test X?" or "Would you like
   me to review Y?" across two turns without advancing the review. *Stop asking; execute the test.*
2. **Tool Exit Code Inertia:** A test or command fails during review verification (e.g. exit code 1 or 2),
   and the agent halts or asks what to do. *Trace the failure with `/debug-mantra`, apply the `Easy`
   foundational fix, and re-run.*
3. **Passive Narration Detection:** Typing phrases like "Waiting for...", "Now I will see...", or "Let
   me know how to proceed" while an in-flight review is pending. *Freeze the cogs and act.*
4. **False Completion Detection:** About to report "LGTM" or "Approved" when acceptance tests were
   skipped, unmutated, or unverified. *Reject completion until evidence is collected.*

**The Five Unstuck Rungs during Review:**
- *Rung 1: Freeze the cogs.* Do not invent new review frameworks, extra wrappers, or meta-analysis.
- *Rung 2: Re-anchor the finish line.* State the observable deliverable: "Verified review report with
  runnable test receipts emitted."
- *Rung 3: Test the blocker.* Is the finding a genuine goal blocker, required correctness/safety,
  or merely polish/cog? (Park polish; queue blockers).
- *Rung 4: Choose one foundational action.* Apply the **No Bandages / No Painkillers Law**: do not
  silence type checks (`@ts-ignore`, `# noqa`), suppress asserts, or bypass gates. Apply the cleanest
  foundational fix.
- *Rung 5: Act once, verify movement, and re-drive.* Execute the move, check that the milestone
  advanced, and resume.

### 3. The Workhorse Defect Resolution Ladder ([`/workhorse`](../workhorse/SKILL.md))

When the review process requires remediating discovered defects:
- **Rung 0: Triage:** Deconstruct all issues into an atomic priority queue (`[Blocker]` → `[Should]` → `[Nit]`).
- **Rung 1: Ground Truth:** Capture raw repros and trace fail paths.
- **Rung 2: Least Mechanism ([`/ponytail`](../../1-hourly/ponytail/SKILL.md)):** Use the standard library
  first, extend existing modules, and produce the shortest working diff. Zero code sprawl.
- **Rung 3: Governance Gate:** Check compliance with `AGENTS.md`, `SOP.md`, `GUIDING-PRINCIPLES.md`,
  and frozen twin guards (`test/gh308-frozen-twin-guard.sh`).
- **Rung 5: Preservation Gate:** Prove preservation invariants before applying any destructive edit.
- **Rung 6: Semantic Verification:** Re-run test suites and verify observable outputs.

---

## Phase 4: Graded Findings & PR Actionability

Structure review findings into four standard citation-backed categories. Every finding must cite
exact `file:line` or symbol references.

### 1. Finding Categories

- 🛑 **`[Blocker]`**: Correctness defects, regressions, security/credential leaks, data loss hazards,
  untested error states, symptom patches hiding root causes, or tests that pass on broken code.
  *Requires resolution before merge/approval.*
- ⚠️ **`[Should]`**: Architectural gaps, missing test coverage / negative controls, non-optimal complexity,
  missing error logging, or unhandled edge cases. *Strongly recommended improvements.*
- 💡 **`[Nit]`**: Style, documentation, variable naming, minor comment cleanups. *Non-blocking suggestions.*
- ✅ **`[Pass]`**: Confirmed correct execution paths with firsthand citations, verified test results,
  and passing mutation checks.

### 2. Structured Review Report Schema

Every `/review-code` report follows this structure:

```markdown
## 🛡️ Code Review Report: <Target / PR Title>

**Verdict:** `Approved` | `Changes Requested` | `Comment`
**Target:** `<Branch / Commit / PR #>` | **Diff Size:** `N lines (+A / -B)`
**Review Mode:** `Ground-Truth Verified (/recon + /debug-mantra)`

| Category | Count | Status |
|:---|:---:|:---|
| 🛑 `[Blocker]` | 0 | All clear |
| ⚠️ `[Should]`  | 1 | Action recommended |
| 💡 `[Nit]`     | 2 | Optional polish |
| ✅ `[Pass]`    | 8 | Verified firsthand |

---

### 🗺️ Recon Map & Blast Radius
- **Entry Points & Callers:** `src/entry.py:42`, `utils/cli.py:105` (all callers verified).
- **State & Data Invariants:** Single-writer verified; SQLite lock budget respected.
- **Contracts & Boundaries:** Public API backward-compatible; no breaking schema drift.

---

### 🔬 Meticulous Testing & Verification Evidence
- **Ground Truth Repro:** Verified regression test `test/gh123_regression.py` fails without fix.
- **Mutation Falsification:** Mutated guard at `src/core.py:88`; verified test went **RED** (exit code 1).
- **Negative Controls:** Tested empty input and invalid flags; verified appropriate errors.
- **Reversible Adaptations Executed:** [Detail any `Easy` autonomous fixes applied during review].

---

### 📋 Detailed Findings & Actionable Checklist

#### 🛑 Blockers
- [ ] `src/auth.py:112` — Token comparison uses non-constant-time equality. `[Blocker]`

#### ⚠️ Should Address
- [ ] `src/worker.py:45` — Missing negative control test for timeout event. `[Should]`

#### 💡 Nits & Minor Polish
- [ ] `src/utils.py:15` — Clarify docstring regarding return type. `[Nit]`

#### ✅ Verified Passes
- `src/core.py:88` — Thread-safe atomic update verified with concurrent worker test. `[Pass]`
```

### 3. PR Actionability (`review-PR`)

When targeting a pull request:
- **Format:** Ensure the output is formatted as clean GitHub-flavored markdown.
- **Automated Posting:** Post the review comment to the PR via `gh pr comment <PR#> --body-file <report.md>`
  or submit formal review via `gh pr review <PR#> --comment / --request-changes / --approve`.
- **Linked Issue Checklists:** If the PR closes issues (`Fixes #123`), verify that all requirements
  in the linked issue or PDDA tracking document (`PROJECT/1-INBOX/` or `PROJECT/2-WORKING/`) are
  satisfied and reflected in the checklist.

---

## Operating Rules & Safety Rails

1. **Lead with the line that survives skimming:** State the verdict, critical blocker count, and
   reversibility assessment in the very first sentence.
2. **Verified beats plausible:** Do not praise code or declare it "clean" without running tests,
   inspecting raw artifacts, or tracing execution paths. An unverified claim is an unknown.
3. **A check that cannot fail is not a check:** Always verify that assertions actually guard what they
   claim by witnessing them fail under mutation.
4. **An empty input passes every check:** Guard against vacuous passes by asserting extracted data
   volume and non-empty artifacts before evaluating results.
5. **Throwaway Full-Clone Isolation (GH-564 rail):** Never run mutation-heavy gates or destructive test
   suites in a primary clone whose state matters or in a linked worktree. Use a disposable full clone
   in `/tmp/` when running suites that touch git remotes, configs, or refs.
6. **Preserve working tree state (GH-527 rail):** Never use `git reset --hard`, `git checkout -- <path>`,
   or tree-wide `git stash` to clean up review experiments.
7. **Frozen Bash twins (GH-308 rail):** Ensure no modifications are made to legacy `.sh` twins under
   `utils/` or `relay-automation/`; all Tier-A runtime logic lives in Python under `utils/py/`.
8. **Builder/Orchestrator Role Split (GH-221 rail):** Claude is the orchestrator and reviewer.
   Autonomous adaptations are restricted to `Easy` reversible fixes and review assertions; do not
   drive headless full-system marathon builds without authorized builder lanes.

exec
/bin/zsh -lc 'git diff HEAD''^ HEAD -- test/gh798-status-skill.sh; nl -ba test/gh798-status-skill.sh; git diff HEAD''^ HEAD -- PROJECT/1-INBOX releases.sql' in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-82909-ltrglyj2
mcp: codebase-memory-mcp/list_projects started
mcp: codebase-memory-mcp/list_projects (completed)
 succeeded in 15964ms:
2026-09-24 19:18:42.185 xcodebuild[4510:150546030]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-09-24 19:18:42.967 xcodebuild[4510:150545890] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.
git: warning: confstr() failed with code 5: couldn't get path of DARWIN_USER_TEMP_DIR; using /tmp instead
git: error: couldn't create cache file '/tmp/xcrun_db-WcldGvbB' (errno=Operation not permitted)
2026-09-24 19:18:44.927 xcodebuild[6750:150552688]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-09-24 19:18:45.808 xcodebuild[6750:150552543] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.
diff --git a/test/gh798-status-skill.sh b/test/gh798-status-skill.sh
index 557a6e6c..7bf895c8 100755
--- a/test/gh798-status-skill.sh
+++ b/test/gh798-status-skill.sh
@@ -36,27 +36,17 @@ grep -q "Lane E. Centralized Helpers & DRY" "$REVIEW_CODE_FILE" && pass "review-
 grep -q "Centralized Helper Adherence" "$REVIEW_CODE_FILE" && pass "review-code has helper adherence check" || fail "missing helper adherence check"
 grep -q "Parallel Subsystem / Reinvention Trap" "$REVIEW_CODE_FILE" && pass "review-code has parallel subsystem trap" || fail "missing parallel subsystem trap"
 
-# Lane E subsections must explicitly bind required severities:
-grep -q 'is a `\[Blocker\]`' <<<"$(awk '/1\. \*\*Centralized Helper Adherence:\*\*/,/2\. \*\*Parallel Subsystem/' "$REVIEW_CODE_FILE")" && pass "Lane E helper adherence binds to [Blocker]" || fail "Lane E helper adherence not bound to [Blocker]"
-grep -q 'mandatory `\[Blocker\]`' <<<"$(awk '/2\. \*\*Parallel Subsystem \/ Reinvention Trap:\*\*/,/3\. \*\*Intra-Diff/' "$REVIEW_CODE_FILE")" && pass "Lane E parallel subsystem binds to [Blocker]" || fail "Lane E parallel subsystem not bound to [Blocker]"
-grep -q 'is a `\[Should\]`' <<<"$(awk '/3\. \*\*Intra-Diff & Cross-Module Duplication \(DRY\):\*\*/,/(\*\*Graph & Source Lookup|\-\-\-)/' "$REVIEW_CODE_FILE")" && pass "Lane E code duplication binds to [Should]" || fail "Lane E duplication not bound to [Should]"
-
-# Phase 4 categories must bind required severities:
-grep -q "reinventing a parallel subsystem" <<<"$(awk '/\[Blocker\]/,/\[Should\]/' "$REVIEW_CODE_FILE")" && pass "review-code binds parallel subsystem to [Blocker]" || fail "parallel subsystem is not under [Blocker]"
-grep -q "bypassing established centralized helpers" <<<"$(awk '/\[Blocker\]/,/\[Should\]/' "$REVIEW_CODE_FILE")" && pass "review-code binds helper bypass to [Blocker]" || fail "helper bypass is not under [Blocker]"
-grep -q "non-DRY duplicate logic" <<<"$(awk '/\[Should\]/,/\[Nit\]/' "$REVIEW_CODE_FILE")" && pass "review-code binds duplicate logic to [Should]" || fail "duplicate logic is not under [Should]"
-
 # --- 6. ARCHITECTURE.md registration ---
 grep -q "\[status\](skills/2-daily/status/SKILL.md)" "$ARCH_FILE" && pass "ARCHITECTURE.md has status link" || fail "missing ARCHITECTURE.md link"
 grep -q "### \`2-daily\` — A few times a day (16)" "$ARCH_FILE" && pass "ARCHITECTURE.md has updated 2-daily count (16)" || fail "missing updated 2-daily count"
 
 # --- 7. Installer gh678 compliance (in sandbox) ---
 H="$WORK/home"; A="$H/apps"
-mkdir -p "$A/claude" "$A/codex" "$A/gemcfg" "$A/antigrav" "$A/agents"
+mkdir -p "$A/claude" "$A/codex" "$A/gemcfg" "$A/antigrav" "$A/antigravcli" "$A/agents"
 run_installer() {
   HOME="$H" CLAUDE_SKILLS_DIR="$A/claude" CODEX_SKILLS_DIR="$A/codex" \
   GEMINI_CONFIG_SKILLS_DIR="$A/gemcfg" ANTIGRAVITY_SKILLS_DIR="$A/antigrav" \
-  AGENTS_SKILLS_DIR="$A/agents" \
+  ANTIGRAVITY_CLI_SKILLS_DIR="$A/antigravcli" AGENTS_SKILLS_DIR="$A/agents" \
   bash "$INSTALLER"
 }
 
@@ -81,45 +71,11 @@ cp "$SKILL_FILE" "$TMP_COPY"
 sed -i.bak '/Status Discipline:/d' "$TMP_COPY"
 grep -q "Status Discipline:" "$TMP_COPY" && fail "negative control 8a: mutation failed to delete recital" || pass "negative control 8a: mutation successfully detected missing recital"
 
-# 8b: Mutating [Blocker] to [Nit] in Phase 4 must fail the Blocker check
+# 8b: Lane E deletion on review-code/SKILL.md must fail Lane E check
 TMP_REV="$WORK/review_code_mutated.md"
 cp "$REVIEW_CODE_FILE" "$TMP_REV"
-sed -i.bak 's/\[Blocker\]/\[Nit\]/g' "$TMP_REV"
-if grep -q "reinventing a parallel subsystem" <<<"$(awk '/\[Blocker\]/,/\[Should\]/' "$TMP_REV")"; then
-  fail "negative control 8b: severity mutation failed to turn Blocker check red"
-else
-  pass "negative control 8b: severity mutation correctly made Blocker check fail (red)"
-fi
-
-# 8c: Mutating Lane E helper severity to [Nit] must fail Lane E helper check
-TMP_LANE_E1="$WORK/review_code_lane_e1.md"
-cp "$REVIEW_CODE_FILE" "$TMP_LANE_E1"
-sed -i.bak 's/is a `\[Blocker\]`/is a `[Nit]`/g' "$TMP_LANE_E1"
-if grep -q 'is a `\[Blocker\]`' <<<"$(awk '/1\. \*\*Centralized Helper Adherence:\*\*/,/2\. \*\*Parallel Subsystem/' "$TMP_LANE_E1")"; then
-  fail "negative control 8c: Lane E1 helper mutation failed to turn check red"
-else
-  pass "negative control 8c: Lane E1 helper mutation correctly made check fail (red)"
-fi
-
-# 8d: Mutating Lane E parallel subsystem severity to [Nit] must fail Lane E parallel check
-TMP_LANE_E2="$WORK/review_code_lane_e2.md"
-cp "$REVIEW_CODE_FILE" "$TMP_LANE_E2"
-sed -i.bak 's/mandatory `\[Blocker\]`/mandatory `[Nit]`/g' "$TMP_LANE_E2"
-if grep -q 'mandatory `\[Blocker\]`' <<<"$(awk '/2\. \*\*Parallel Subsystem \/ Reinvention Trap:\*\*/,/3\. \*\*Intra-Diff/' "$TMP_LANE_E2")"; then
-  fail "negative control 8d: Lane E2 parallel subsystem mutation failed to turn check red"
-else
-  pass "negative control 8d: Lane E2 parallel subsystem mutation correctly made check fail (red)"
-fi
-
-# 8e: Mutating Lane E duplication severity to [Nit] must fail Lane E duplication check
-TMP_LANE_E3="$WORK/review_code_lane_e3.md"
-cp "$REVIEW_CODE_FILE" "$TMP_LANE_E3"
-sed -i.bak 's/is a `\[Should\]`/is a `[Nit]`/g' "$TMP_LANE_E3"
-if grep -q 'is a `\[Should\]`' <<<"$(awk '/3\. \*\*Intra-Diff & Cross-Module Duplication \(DRY\):\*\*/,/(\*\*Graph & Source Lookup|\-\-\-)/' "$TMP_LANE_E3")"; then
-  fail "negative control 8e: Lane E3 duplication mutation failed to turn check red"
-else
-  pass "negative control 8e: Lane E3 duplication mutation correctly made check fail (red)"
-fi
+sed -i.bak '/Lane E. Centralized Helpers & DRY/d' "$TMP_REV"
+grep -q "Lane E. Centralized Helpers & DRY" "$TMP_REV" && fail "negative control 8b: mutation failed to delete Lane E" || pass "negative control 8b: mutation successfully detected missing Lane E"
 
 echo "  gh798-status-skill: $PASS pass, $FAIL fail"
 [ "$FAIL" -eq 0 ] || exit 1
     1	#!/usr/bin/env bash
     2	# test/gh798-status-skill.sh — GH-798: status skill and review-code DRY / helper audit
     3	source "$(dirname "$0")/_setup.sh" gh798-status-skill
     4	
     5	REPO="$(cd "$(dirname "$0")/.." && pwd)"
     6	SKILL_DIR="$REPO/skills/2-daily/status"
     7	SKILL_FILE="$SKILL_DIR/SKILL.md"
     8	INSTALLER="$SKILL_DIR/install.sh"
     9	REVIEW_CODE_FILE="$REPO/skills/2-daily/review-code/SKILL.md"
    10	ARCH_FILE="$REPO/ARCHITECTURE.md"
    11	
    12	echo "== test: gh798-status-skill =="
    13	
    14	# --- 1. File existence & basic structure ---
    15	[ -f "$SKILL_FILE" ] && pass "skills/2-daily/status/SKILL.md exists" || fail "missing status/SKILL.md"
    16	[ -f "$INSTALLER" ] && pass "skills/2-daily/status/install.sh exists" || fail "missing status/install.sh"
    17	[ -x "$INSTALLER" ] && pass "install.sh is executable" || fail "status/install.sh is not executable"
    18	
    19	# --- 2. YAML frontmatter validation ---
    20	grep -q "^name: status$" "$SKILL_FILE" && pass "frontmatter has name: status" || fail "missing name in frontmatter"
    21	grep -q "description:" "$SKILL_FILE" && pass "frontmatter has description" || fail "missing description in frontmatter"
    22	
    23	# --- 3. Recital and Core Discipline Presence ---
    24	grep -q "Status Discipline:" "$SKILL_FILE" && pass "recital block present" || fail "missing recital block"
    25	grep -q "/recon" "$SKILL_FILE" && pass "/recon integrated" || fail "missing /recon reference"
    26	grep -q "/debug-mantra" "$SKILL_FILE" && pass "/debug-mantra integrated" || fail "missing /debug-mantra reference"
    27	grep -q "/merge-cleanup" "$SKILL_FILE" && pass "/merge-cleanup integrated" || fail "missing /merge-cleanup reference"
    28	
    29	# --- 4. Quality gates & multi-checkout rules ---
    30	grep -q "A doc is a hypothesis-zero claim, never evidence" "$SKILL_FILE" && pass "hypothesis-zero doc rule present" || fail "missing hypothesis-zero rule"
    31	grep -q "The local checkout is not the only checkout" "$SKILL_FILE" && pass "multi-checkout discovery rule present" || fail "missing multi-checkout rule"
    32	grep -q "Ground Truth vs. Documentation Gap Matrix" "$SKILL_FILE" && pass "gap matrix schema present" || fail "missing gap matrix schema"
    33	
    34	# --- 5. Review-code DRY and centralized helper audit ---
    35	grep -q "Lane E. Centralized Helpers & DRY" "$REVIEW_CODE_FILE" && pass "review-code has Lane E DRY" || fail "missing Lane E in review-code"
    36	grep -q "Centralized Helper Adherence" "$REVIEW_CODE_FILE" && pass "review-code has helper adherence check" || fail "missing helper adherence check"
    37	grep -q "Parallel Subsystem / Reinvention Trap" "$REVIEW_CODE_FILE" && pass "review-code has parallel subsystem trap" || fail "missing parallel subsystem trap"
    38	
    39	# --- 6. ARCHITECTURE.md registration ---
    40	grep -q "\[status\](skills/2-daily/status/SKILL.md)" "$ARCH_FILE" && pass "ARCHITECTURE.md has status link" || fail "missing ARCHITECTURE.md link"
    41	grep -q "### \`2-daily\` — A few times a day (16)" "$ARCH_FILE" && pass "ARCHITECTURE.md has updated 2-daily count (16)" || fail "missing updated 2-daily count"
    42	
    43	# --- 7. Installer gh678 compliance (in sandbox) ---
    44	H="$WORK/home"; A="$H/apps"
    45	mkdir -p "$A/claude" "$A/codex" "$A/gemcfg" "$A/antigrav" "$A/antigravcli" "$A/agents"
    46	run_installer() {
    47	  HOME="$H" CLAUDE_SKILLS_DIR="$A/claude" CODEX_SKILLS_DIR="$A/codex" \
    48	  GEMINI_CONFIG_SKILLS_DIR="$A/gemcfg" ANTIGRAVITY_SKILLS_DIR="$A/antigrav" \
    49	  ANTIGRAVITY_CLI_SKILLS_DIR="$A/antigravcli" AGENTS_SKILLS_DIR="$A/agents" \
    50	  bash "$INSTALLER"
    51	}
    52	
    53	FOREIGN="$WORK/foreign"; mkdir -p "$FOREIGN"; echo "foreign" > "$FOREIGN/SKILL.md"
    54	ln -s "$FOREIGN" "$A/claude/status"
    55	set +e
    56	run_installer >"$WORK/out-foreign" 2>&1
    57	rc_for=$?
    58	set -e
    59	[ "$rc_for" -ne 0 ] && [ "$(readlink "$A/claude/status")" = "$FOREIGN" ] && pass "installer refuses live foreign link" || fail "installer replaced live foreign link"
    60	
    61	rm -f "$A/claude/status"
    62	ln -s "$WORK/nowhere/status" "$A/claude/status"
    63	run_installer >"$WORK/out-dangling" 2>&1
    64	rc_dan=$?
    65	[ "$rc_dan" -eq 0 ] && [ "$(readlink "$A/claude/status")" -ef "$SKILL_DIR" ] && pass "installer replaces dangling link" || fail "installer failed to replace dangling link"
    66	
    67	# --- 8. Negative control mutation (falsification) ---
    68	# 8a: Recital deletion on status/SKILL.md must fail recital check
    69	TMP_COPY="$WORK/skill_mutated.md"
    70	cp "$SKILL_FILE" "$TMP_COPY"
    71	sed -i.bak '/Status Discipline:/d' "$TMP_COPY"
    72	grep -q "Status Discipline:" "$TMP_COPY" && fail "negative control 8a: mutation failed to delete recital" || pass "negative control 8a: mutation successfully detected missing recital"
    73	
    74	# 8b: Lane E deletion on review-code/SKILL.md must fail Lane E check
    75	TMP_REV="$WORK/review_code_mutated.md"
    76	cp "$REVIEW_CODE_FILE" "$TMP_REV"
    77	sed -i.bak '/Lane E. Centralized Helpers & DRY/d' "$TMP_REV"
    78	grep -q "Lane E. Centralized Helpers & DRY" "$TMP_REV" && fail "negative control 8b: mutation failed to delete Lane E" || pass "negative control 8b: mutation successfully detected missing Lane E"
    79	
    80	echo "  gh798-status-skill: $PASS pass, $FAIL fail"
    81	[ "$FAIL" -eq 0 ] || exit 1
    82	exit 0
git: warning: confstr() failed with code 5: couldn't get path of DARWIN_USER_TEMP_DIR; using /tmp instead
git: error: couldn't create cache file '/tmp/xcrun_db-DrdSC2Xt' (errno=Operation not permitted)
2026-09-24 19:18:50.248 xcodebuild[9793:150563456]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-09-24 19:18:50.854 xcodebuild[9793:150563352] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.
git: warning: confstr() failed with code 5: couldn't get path of DARWIN_USER_TEMP_DIR; using /tmp instead
git: error: couldn't create cache file '/tmp/xcrun_db-T2nfFHaZ' (errno=Operation not permitted)
2026-09-24 19:18:52.523 xcodebuild[11316:150568215]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-09-24 19:18:54.107 xcodebuild[11316:150568084] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.
diff --git a/releases.sql b/releases.sql
index a93197fc..291fd5b7 100644
--- a/releases.sql
+++ b/releases.sql
@@ -1,6 +1,6 @@
 -- releases-app canonical dump (GH-32 grammar: GID-keyed rows, natural keys elsewhere,
 -- no integer PKs/FKs as values; rebuild renumbers deterministically)
--- generation: 1132
+-- generation: 1134
 -- table: schema_migrations
 INSERT INTO schema_migrations(version, applied_at) VALUES('1', '2026-08-19T01:32:22Z');
 INSERT INTO schema_migrations(version, applied_at) VALUES('2', '2026-08-19T18:55:40Z');
@@ -13,7 +13,7 @@ INSERT INTO schema_migrations(version, applied_at) VALUES('8', '2026-09-12T16:07
 INSERT INTO schema_migrations(version, applied_at) VALUES('9', '2026-09-23T01:01:18Z');
 -- table: settings
 INSERT INTO settings(key, value, updated_at) VALUES('enforcement', 'lenient', '2026-09-08T05:45:05Z');
-INSERT INTO settings(key, value, updated_at) VALUES('generation', '1132', '2026-09-25T01:21:42Z');
+INSERT INTO settings(key, value, updated_at) VALUES('generation', '1134', '2026-09-25T02:06:18Z');
 INSERT INTO settings(key, value, updated_at) VALUES('repo_slug', 'XYZ-forge', '2026-09-08T05:45:05Z');
 -- table: repos
 INSERT INTO repos(global_id, slug, updated_at) VALUES('repo-01M0BTBRJ0PZF51EK6PCRJ20FS', 'XYZ-forge', '2026-09-08T05:45:05Z');
@@ -731,6 +731,7 @@ INSERT INTO roadmap_items(global_id, repo_gid, gh_number, title, section, positi
 INSERT INTO roadmap_items(global_id, repo_gid, gh_number, title, section, position, status_marker, complexity, risk, effort, doc_path, issue_url, raw_text, first_seen, updated_at, rating_pri, rating_sev, rating_appeal, rating_effort, rating_ovr, status_label) VALUES('rmi-01M334NT6E5JY8G3YDV2KPWJSM', 'repo-01M0BTBRJ0PZF51EK6PCRJ20FS', '742', 'xyz-vendor.sh: vendored .xyz/ ships no package.json, so every Node entry point breaks on a `"type":"module"` target', 'Completed', '111', '✅', NULL, NULL, NULL, 'PROJECT/3-COMPLETED/GH-742-VENDOR-PACKAGE-JSON-ESM.md', 'https://github.com/HiQS-Labs/XYZ-forge/issues/742', '- **GH-742 · xyz-vendor.sh: vendored .xyz/ ships no package.json, so every Node entry point breaks on a `"type":"module"` target** ✅ **SHIPPED 2026-09-24 (PR #753)** — [GH-742-VENDOR-PACKAGE-JSON-ESM.md](PROJECT/3-COMPLETED/GH-742-VENDOR-PACKAGE-JSON-ESM.md) · [#742](https://github.com/HiQS-Labs/XYZ-forge/issues/742) (rated 70/90/90/80)', '2026-09-21T23:26:33Z', '2026-09-24T19:13:47Z', '70', '90', '90', '80', NULL, NULL);
 INSERT INTO roadmap_items(global_id, repo_gid, gh_number, title, section, position, status_marker, complexity, risk, effort, doc_path, issue_url, raw_text, first_seen, updated_at, rating_pri, rating_sev, rating_appeal, rating_effort, rating_ovr, status_label) VALUES('rmi-01M3AWVQMM486M0HAXTKNHM8C3', 'repo-01M0BTBRJ0PZF51EK6PCRJ20FS', '798', 'feat(skills): add status skill and DRY/centralized-helper audit in review-code', 'Completed', '108', '✅', NULL, NULL, NULL, 'PROJECT/3-COMPLETED/GH-798-FEAT-SKILLS-ADD-STATUS-SKILL-AND-DRY-CENTRALIZED-HELPER-AUDI.md', 'https://github.com/HiQS-Labs/XYZ-forge/issues/798', '- **GH-798 · feat(skills): add status skill and DRY/centralized-helper audit in review-code** ✅ **SHIPPED 2026-09-24 (commit 137076593882)** — [doc](PROJECT/3-COMPLETED/GH-798-FEAT-SKILLS-ADD-STATUS-SKILL-AND-DRY-CENTRALIZED-HELPER-AUDI.md) · [#798](https://github.com/HiQS-Labs/XYZ-forge/issues/798)', '2026-09-24T23:43:54Z', '2026-09-25T01:21:40Z', NULL, NULL, NULL, NULL, NULL, NULL);
 INSERT INTO roadmap_items(global_id, repo_gid, gh_number, title, section, position, status_marker, complexity, risk, effort, doc_path, issue_url, raw_text, first_seen, updated_at, rating_pri, rating_sev, rating_appeal, rating_effort, rating_ovr, status_label) VALUES('rmi-01M3B2DEB0BED6JB6A33SW74BC', 'repo-01M0BTBRJ0PZF51EK6PCRJ20FS', '801', 'fix: GH-798 skill tests violate pipe-to-grep ratchet and block full gate', 'Completed', '108', '✅', NULL, NULL, NULL, 'PROJECT/3-COMPLETED/GH-801-FIX-GH-798-SKILL-TESTS-VIOLATE-PIPE-TO-GREP-RATCHET-AND-BLOC.md', 'https://github.com/HiQS-Labs/XYZ-forge/issues/801', '- **GH-801 · fix: GH-798 skill tests violate pipe-to-grep ratchet and block full gate** ✅ **SHIPPED 2026-09-24 (commit 137076593882)** — [doc](PROJECT/3-COMPLETED/GH-801-FIX-GH-798-SKILL-TESTS-VIOLATE-PIPE-TO-GREP-RATCHET-AND-BLOC.md) · [#801](https://github.com/HiQS-Labs/XYZ-forge/issues/801)', '2026-09-25T01:20:57Z', '2026-09-25T01:21:42Z', NULL, NULL, NULL, NULL, NULL, NULL);
+INSERT INTO roadmap_items(global_id, repo_gid, gh_number, title, section, position, status_marker, complexity, risk, effort, doc_path, issue_url, raw_text, first_seen, updated_at, rating_pri, rating_sev, rating_appeal, rating_effort, rating_ovr, status_label) VALUES('rmi-01M3B50BKKGA3CF186CTARDWYA', 'repo-01M0BTBRJ0PZF51EK6PCRJ20FS', '804', 'Review and simplify skill instruction tests introduced by GH-798', 'Queue / parked intake', '108', '🆕', NULL, NULL, NULL, 'PROJECT/2-WORKING/GH-804-SIMPLIFY-SKILL-INSTRUCTION-TESTS-INTRODUCED-BY-GH-798.md', 'https://github.com/HiQS-Labs/XYZ-forge/issues/804', '- **GH-804 · Review and simplify skill instruction tests introduced by GH-798** 🆕 **captured 2026-09-24 via HQ** — [GH-804-SIMPLIFY-SKILL-INSTRUCTION-TESTS-INTRODUCED-BY-GH-798.md](PROJECT/2-WORKING/GH-804-SIMPLIFY-SKILL-INSTRUCTION-TESTS-INTRODUCED-BY-GH-798.md) · [#804](https://github.com/HiQS-Labs/XYZ-forge/issues/804) (rated 40/20/50/85)', '2026-09-25T02:06:14Z', '2026-09-25T02:06:18Z', '40', '20', '50', '85', NULL, NULL);
 -- table: jog_queue
 INSERT INTO jog_queue(global_id, repo_gid, gh_number, position, status, created_at, updated_at, attempt_count, lease_pid, failure_reason) VALUES('jog-01M122D1G6F8AWEKQHKFPCFD37', 'repo-01M0BTBRJ0PZF51EK6PCRJ20FS', '275', '1', 'completed', '2026-08-27T16:56:10Z', '2026-08-27T18:11:04Z', '5', NULL, 'preflight: already-landed');
 INSERT INTO jog_queue(global_id, repo_gid, gh_number, position, status, created_at, updated_at, attempt_count, lease_pid, failure_reason) VALUES('jog-01M122D1WM4Z659A8N591AR0H8', 'repo-01M0BTBRJ0PZF51EK6PCRJ20FS', '269', '1', 'failed', '2026-08-27T16:56:10Z', '2026-08-27T18:39:22Z', '3', NULL, 'drive failed (exit 7)');
@@ -2048,6 +2049,8 @@ INSERT INTO op_receipts(op, target_gid, at, txn_id, session_id, state_digest_bef
 INSERT INTO op_receipts(op, target_gid, at, txn_id, session_id, state_digest_before, state_digest_after) VALUES('roadmap-update', 'rmi-01M3AWVQMM486M0HAXTKNHM8C3', '2026-09-25T01:21:40Z', '8f5890da8b1e4829ad57143458deff1c', 'default', '2339d10af667585e163fe9f26866fb252e5647647d145ec31015d0679f33a8da', 'bd2bf89a968741450d83fea340942c40c86e6d8576d82e9e9aeb66f36fe5e1aa');
 INSERT INTO op_receipts(op, target_gid, at, txn_id, session_id, state_digest_before, state_digest_after) VALUES('roadmap-repoint', 'rmi-01M3B2DEB0BED6JB6A33SW74BC', '2026-09-25T01:21:41Z', '8b5db4952209434caa84e95ee634000e', 'default', 'bd2bf89a968741450d83fea340942c40c86e6d8576d82e9e9aeb66f36fe5e1aa', '74bcb61bdb6bd320ed236e1ebcabb87ec265835206b00836909e3ec61f0fb7b1');
 INSERT INTO op_receipts(op, target_gid, at, txn_id, session_id, state_digest_before, state_digest_after) VALUES('roadmap-update', 'rmi-01M3B2DEB0BED6JB6A33SW74BC', '2026-09-25T01:21:42Z', '3474cf348c824a75949be75addcdb1bc', 'default', '74bcb61bdb6bd320ed236e1ebcabb87ec265835206b00836909e3ec61f0fb7b1', '7bba4da6ae5c36f0a8312dc635e25079014b2abaead266b8c4cff02dee7440b8');
+INSERT INTO op_receipts(op, target_gid, at, txn_id, session_id, state_digest_before, state_digest_after) VALUES('roadmap-add', 'rmi-01M3B50BKKGA3CF186CTARDWYA', '2026-09-25T02:06:14Z', '4098c36787f24ea4bff8a2a9f81ecdf8', 'default', '7bba4da6ae5c36f0a8312dc635e25079014b2abaead266b8c4cff02dee7440b8', '6a03a23def9f714d18bf29ca7e76db5159286ce2bba603b917d2e9b1acdf980a');
+INSERT INTO op_receipts(op, target_gid, at, txn_id, session_id, state_digest_before, state_digest_after) VALUES('roadmap-rate', 'rmi-01M3B50BKKGA3CF186CTARDWYA', '2026-09-25T02:06:18Z', 'b7a87668088546fa818f64599c3cdb11', 'default', '6a03a23def9f714d18bf29ca7e76db5159286ce2bba603b917d2e9b1acdf980a', '3c3fb53e3b25bc0d2bda47fd211c837eb11e24992c71385c474808e7813a57ff');
 -- table: work_events
 INSERT INTO work_events(global_id, repo_gid, gh_number, txn_id, event, payload, at) VALUES('wev-01M2CBC3C2HSWRSBY81TAZHYY0', 'repo-01M0BTBRJ0PZF51EK6PCRJ20FS', '568', 'df2ee890077d486dbe23311c5dd74d82', 'updated', '{"marker": "\u2705", "section": "Completed"}', '2026-09-13T03:01:02Z');
 INSERT INTO work_events(global_id, repo_gid, gh_number, txn_id, event, payload, at) VALUES('wev-01M2CGH1A7Z979TG5DQJHN8DX6', 'repo-01M0BTBRJ0PZF51EK6PCRJ20FS', '591', '6d3d7a7619c247b5a85a039ea98756bd', 'parked', '{"section": "Queue / parked intake"}', '2026-09-13T04:31:07Z');
@@ -2429,3 +2432,5 @@ INSERT INTO work_events(global_id, repo_gid, gh_number, txn_id, event, payload,
 INSERT INTO work_events(global_id, repo_gid, gh_number, txn_id, event, payload, at) VALUES('wev-01M3B2DGREAKERTWNR47HC6BSZ', 'repo-01M0BTBRJ0PZF51EK6PCRJ20FS', '801', '04d66cae6da84d76986f6d15634d442b', 'in_flight', '{"accepted_start": true, "marker": "\ud83d\udea7", "section": "In progress", "source": "roadmap-update", "transition": true}', '2026-09-25T01:20:59Z');
 INSERT INTO work_events(global_id, repo_gid, gh_number, txn_id, event, payload, at) VALUES('wev-01M3B2ES2M76D077RMVGQMY71C', 'repo-01M0BTBRJ0PZF51EK6PCRJ20FS', '798', '8f5890da8b1e4829ad57143458deff1c', 'updated', '{"marker": "\u2705", "section": "Completed", "source": "roadmap-update", "transition": false}', '2026-09-25T01:21:40Z');
 INSERT INTO work_events(global_id, repo_gid, gh_number, txn_id, event, payload, at) VALUES('wev-01M3B2ET3YN6EF0GW4XAS38ZGB', 'repo-01M0BTBRJ0PZF51EK6PCRJ20FS', '801', '3474cf348c824a75949be75addcdb1bc', 'completed', '{"marker": "\u2705", "section": "Completed", "source": "roadmap-update", "transition": true}', '2026-09-25T01:21:42Z');
+INSERT INTO work_events(global_id, repo_gid, gh_number, txn_id, event, payload, at) VALUES('wev-01M3B50BMETFXTHF1X5M2CTFJK', 'repo-01M0BTBRJ0PZF51EK6PCRJ20FS', '804', '4098c36787f24ea4bff8a2a9f81ecdf8', 'parked', '{"section": "Queue / parked intake"}', '2026-09-25T02:06:14Z');
+INSERT INTO work_events(global_id, repo_gid, gh_number, txn_id, event, payload, at) VALUES('wev-01M3B50FFDNM5W04JPCC0SJZA0', 'repo-01M0BTBRJ0PZF51EK6PCRJ20FS', '804', 'b7a87668088546fa818f64599c3cdb11', 'rated', '{"rated": "40/20/50/85"}', '2026-09-25T02:06:18Z');

codex
The simplification preserves both installer safety cases and replaces the severity-specific mutations with a Lane E deletion control. I also found unrelated generated-view churn in HEAD. I’m checking the capture document and static gate checks; this read-only environment cannot run the mutation-heavy suite.
exec
/bin/zsh -lc "nl -ba PROJECT/2-WORKING/GH-804-SIMPLIFY-SKILL-INSTRUCTION-TESTS-INTRODUCED-BY-GH-798.md; rg -n 'pipe.to.grep|ANTIGRAVITY_CLI|gh798' test/gh*ratchet* test/*installer* utils/ci-route.sh; sed -n '1,90p' GUIDING-PRINCIPLES.md; rg -n 'Status|frontmatter|updated:|capture' PROJECT/PDDA.md | head -25; bash -n test/gh798-status-skill.sh; git diff --check HEAD"'^ HEAD' in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-82909-ltrglyj2
 succeeded in 12396ms:
2026-09-24 19:19:07.661 xcodebuild[21530:150600230]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-09-24 19:19:09.400 xcodebuild[21530:150600056] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.
git: warning: confstr() failed with code 5: couldn't get path of DARWIN_USER_TEMP_DIR; using /tmp instead
git: error: couldn't create cache file '/tmp/xcrun_db-cFlhPcW4' (errno=Operation not permitted)
2026-09-24 19:19:11.662 xcodebuild[24140:150608946]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-09-24 19:19:13.124 xcodebuild[24140:150608744] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.

exec
/bin/zsh -lc "python3 -B - <<'PY'
from pathlib import Path
import subprocess
for path, pattern in [('skills/2-daily/status/SKILL.md','Status Discipline:'),('skills/2-daily/review-code/SKILL.md','Lane E. Centralized Helpers & DRY')]:
    data=Path(path).read_bytes()
    positive=subprocess.run(['grep','-q',pattern],input=data).returncode
    mutated=subprocess.run(['sed','/'+pattern+'/d'],input=data,stdout=subprocess.PIPE,check=True).stdout
    negative=subprocess.run(['grep','-q',pattern],input=mutated).returncode
    print(path, 'bytes=',len(data),'positive=',positive,'mutated=',negative)
    assert data and mutated and positive == 0 and negative == 1
PY
rg -n 'pipe-to-grep|ratchet' test/gh139* | head -20; nl -ba LEADERBOARD.md | sed -n '215,222p'" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-82909-ltrglyj2
 succeeded in 0ms:
zsh:1: can't create temp file for here document: operation not permitted
18:# baseline in the same PR (the ratchet only turns one way).
59:# 2. shrunk counts: report and invite the ratchet forward (never a failure)
66:    echo "  INFO: $path shrank $base -> $cur — regenerate the baseline in this PR (GH-139 ratchet)"
   215	| 202 | **195** | [GH-487](https://github.com/HiQS-Labs/XYZ-forge/issues/487) — ci: make new-branch skill/test pushes use bounded gates and clarify draft-review bypass | — | Completed | 55 | 30 | 50 | 60 | 195 | — |
   216	| 203 | **195** | [GH-549](https://github.com/HiQS-Labs/XYZ-forge/issues/549) — Work-state event stream + concurrent connectors: GitHub Kanban first, HQ and Flightdeck next | — | Completed | 70 | 50 | 50 | 25 | 195 | — |
   217	| 204 | **195** | [GH-561](https://github.com/HiQS-Labs/XYZ-forge/issues/561) — merge-cleanup: gate-run disposable clones preserved forever (telemetry-only .tick/ unverifiable) | — | Completed | 50 | 30 | 50 | 65 | 195 | — |
   218	| 205 | **195** | [GH-804](https://github.com/HiQS-Labs/XYZ-forge/issues/804) — Review and simplify skill instruction tests introduced by GH-798 | — | Queue / parked intake | 40 | 20 | 50 | 85 | 195 | — |
   219	| 206 | **193** | [GH-536](https://github.com/HiQS-Labs/XYZ-forge/issues/536) — relocate: Deployed Skills moves INTO the live Git Pulse Sync checkout (supersedes #508 verdict) | — | Completed | 65 | 38 | 50 | 40 | 193 | — |
   220	| 207 | **193** | [GH-642](https://github.com/HiQS-Labs/XYZ-forge/issues/642) — Low-hanging fruit from two foreign-repo marathons: make the consumer-repo SOP turnkey | — | Completed | 60 | 35 | 50 | 48 | 193 | — |
   221	| 208 | **190** | [GH-39](https://github.com/HiQS-Labs/XYZ-forge/issues/39) — RELEASES app: one-way GitHub Project release-card projection | — | Completed | 50 | 30 | 65 | 45 | 190 | — |
   222	| 209 | **190** | [GH-522](https://github.com/HiQS-Labs/XYZ-forge/issues/522) — Continuous issue admission into Jog/Marathon proposals | — | Queue / parked intake | 55 | 30 | 50 | 55 | 190 | — |

exec
/bin/zsh -lc "python3 -B -c 'from pathlib import Path; import subprocess
for path, pattern in [(\"skills/2-daily/status/SKILL.md\",\"Status Discipline:\"),(\"skills/2-daily/review-code/SKILL.md\",\"Lane E. Centralized Helpers & DRY\")]:
 data=Path(path).read_bytes(); positive=subprocess.run([\"grep\",\"-q\",pattern],input=data).returncode; mutated=subprocess.run([\"sed\",\"/\"+pattern+\"/d\"],input=data,stdout=subprocess.PIPE,check=True).stdout; negative=subprocess.run([\"grep\",\"-q\",pattern],input=mutated).returncode; print(path, len(data), positive, negative); assert data and mutated and positive==0 and negative==1'" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-82909-ltrglyj2
 succeeded in 88ms:
skills/2-daily/status/SKILL.md 13679 0 1
skills/2-daily/review-code/SKILL.md 24761 0 1

codex
**ANSWER:** The test simplification achieves GH-804’s core intent without an apparent installer regression or overengineering. HEAD is not fully clean for merge: documentation and generated-view cleanup remain, and full gate compliance is unverified.

**FINDINGS**

- **[Pass] Essential installer checks remain intact.** Foreign live-link refusal verifies both nonzero exit and preservation of the original target; dangling-link replacement verifies success and the correct destination (`test/gh798-status-skill.sh:53–65`).
- **[Pass] Simplification is appropriately scoped.** Brittle awk/severity checks disappear while metadata, architecture registration, and core review-section checks remain (`test/gh798-status-skill.sh:14–41`). Removing severity mutations follows the stated acceptance criteria.
- **[Pass] Meaningful falsification survives.** Recital and Lane E deletion controls use the corresponding positive predicates (`test/gh798-status-skill.sh:67–78`). I independently exercised both transformations in memory: each original matched, and each mutated document failed its predicate.
- **[Should] Remove routine generated-view changes.** HEAD also modifies `LEADERBOARD.md`, contrary to the explicit task-branch rule (`AGENTS.md:55–56`; `LEADERBOARD.md:218`).
- **[Should] Update the active document and ledger before declaring completion.** The status still says planning/execution are next, every acceptance criterion is unchecked, and evidence is empty (`PROJECT/2-WORKING/GH-804-SIMPLIFY-SKILL-INSTRUCTION-TESTS-INTRODUCED-BY-GH-798.md:26–44`). The ledger still marks this active work as parked intake (`releases.sql:734`).
- **[Nit] Added CLI destination is unused.** `ANTIGRAVITY_CLI_SKILLS_DIR` and its directory add no coverage because this installer does not consume that variable (`test/gh798-status-skill.sh:45–49`; `skills/2-daily/status/install.sh:53–58`).

`bash -n` and `git diff --check` passed. The installer suite, GH-139 ratchet, and full gates were not run under this read-only sandbox; no blanket green-gate claim is justified.

**RECOMMENDATION:** Keep the simplification, remove generated-view churn, reconcile task status, and obtain passing focused and required gate evidence before merge.
tokens used
73,540
**ANSWER:** The test simplification achieves GH-804’s core intent without an apparent installer regression or overengineering. HEAD is not fully clean for merge: documentation and generated-view cleanup remain, and full gate compliance is unverified.

**FINDINGS**

- **[Pass] Essential installer checks remain intact.** Foreign live-link refusal verifies both nonzero exit and preservation of the original target; dangling-link replacement verifies success and the correct destination (`test/gh798-status-skill.sh:53–65`).
- **[Pass] Simplification is appropriately scoped.** Brittle awk/severity checks disappear while metadata, architecture registration, and core review-section checks remain (`test/gh798-status-skill.sh:14–41`). Removing severity mutations follows the stated acceptance criteria.
- **[Pass] Meaningful falsification survives.** Recital and Lane E deletion controls use the corresponding positive predicates (`test/gh798-status-skill.sh:67–78`). I independently exercised both transformations in memory: each original matched, and each mutated document failed its predicate.
- **[Should] Remove routine generated-view changes.** HEAD also modifies `LEADERBOARD.md`, contrary to the explicit task-branch rule (`AGENTS.md:55–56`; `LEADERBOARD.md:218`).
- **[Should] Update the active document and ledger before declaring completion.** The status still says planning/execution are next, every acceptance criterion is unchecked, and evidence is empty (`PROJECT/2-WORKING/GH-804-SIMPLIFY-SKILL-INSTRUCTION-TESTS-INTRODUCED-BY-GH-798.md:26–44`). The ledger still marks this active work as parked intake (`releases.sql:734`).
- **[Nit] Added CLI destination is unused.** `ANTIGRAVITY_CLI_SKILLS_DIR` and its directory add no coverage because this installer does not consume that variable (`test/gh798-status-skill.sh:45–49`; `skills/2-daily/status/install.sh:53–58`).

`bash -n` and `git diff --check` passed. The installer suite, GH-139 ratchet, and full gates were not run under this read-only sandbox; no blanket green-gate claim is justified.

**RECOMMENDATION:** Keep the simplification, remove generated-view churn, reconcile task status, and obtain passing focused and required gate evidence before merge.
