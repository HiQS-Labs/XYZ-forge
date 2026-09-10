**NO FIRSTHAND VERIFICATION CITED** — treat conclusions as conditional (codex's answer carries an unsupported [Pass]/verified/confirmed-style claim with no quoted span or file:line citation nearby, despite the consult PREAMBLE asking advisors to cite evidence.)

> **ATTESTATION**
> Model: gpt-6-astra
> Provider: openai
> Sandbox: read-only

Reading additional input from stdin...
OpenAI Codex v0.153.4
--------
workdir: /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-25720-vf7abaoe
model: gpt-6-astra
provider: openai
approval: never
sandbox: read-only
reasoning effort: low
reasoning summaries: none
session id: 01a08986-ba96-7092-b279-b921b290ad00
--------
user
You are an INDEPENDENT advisor in a one-shot cross-model consult. Another model is answering the SAME question separately and a coordinator will reconcile both answers, so give your own honest, specific read — do not hedge toward a consensus you cannot see. Read any repo files the question references (cite file:line). Respond with: (1) a short direct ANSWER; (2) graded FINDINGS — [Blocker]/[Should]/[Nit]/[Pass] — where applicable; (3) a one-line RECOMMENDATION. You are ADVISORY ONLY: output your analysis as text; do not rely on writing files (you are running in a throwaway copy).

=== CONSULT QUESTION ===
Review GH-496 PR 1 (Phase 0 Recon & Phase 1 Out-of-Tree Telemetry Relocation): inspect utils/py/harness_app.py, test/gh496-telemetry-isolation.sh, validate.sh, utils/ci-route.sh, and TESTS-RESULTS/2026-09-09+GH-496-PR1/SUMMARY.md on branch feat/gh496-selective-ci. Verify correctness, edge cases, backwards compatibility, and sign off for PR 1 readiness.
codex
I’ll review the relocation behavior, regression coverage, and recorded validation, then give a concrete PR readiness verdict.
exec
/bin/zsh -lc 'pwd; git status --short; git branch --show-current; cat ROUTER.md' in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-25720-vf7abaoe
 succeeded in 5107ms:
2026-09-09 21:15:11.460 xcodebuild[26608:65564323]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-09-09 21:15:11.844 xcodebuild[26608:65564321] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.
git: warning: confstr() failed with code 5: couldn't get path of DARWIN_USER_TEMP_DIR; using /tmp instead
git: error: couldn't create cache file '/tmp/xcrun_db-h2nIhiM5' (errno=Operation not permitted)
2026-09-09 21:15:12.545 xcodebuild[26633:65564396]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-09-09 21:15:12.730 xcodebuild[26633:65564395] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.
?? relay-system/2026-09-09/gh496-pr1-qa-211502/
git: warning: confstr() failed with code 5: couldn't get path of DARWIN_USER_TEMP_DIR; using /tmp instead
git: error: couldn't create cache file '/tmp/xcrun_db-25Z8E0FN' (errno=Operation not permitted)
2026-09-09 21:15:14.044 xcodebuild[27066:65565238]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-09-09 21:15:14.245 xcodebuild[27066:65565208] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.
git: warning: confstr() failed with code 5: couldn't get path of DARWIN_USER_TEMP_DIR; using /tmp instead
git: error: couldn't create cache file '/tmp/xcrun_db-nElPxrxk' (errno=Operation not permitted)
2026-09-09 21:15:14.793 xcodebuild[27458:65565876]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-09-09 21:15:14.995 xcodebuild[27458:65565843] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.
# ROUTER.md

This file is the first entry point for an AI agent working in this repo: it tells you what to read, what to run, and which files are canonical.

## Role split

- `ROUTER.md` = startup order and canonical entry points
- `GUIDING-PRINCIPLES.md` = XYZ Forge’s product purpose, scope and *why*, and the canonical North Star: durable, reversible, DRY — extend what exists rather than forking a parallel system
- `AGENTS.md` = behavioral rules, decision quality, reversibility, blast radius, proof
- `README.md` = human-facing repo/product overview
- `ROADMAP-DASHBOARD.md` = the generated, human-readable view of the roadmap ledger (read this; regenerate with `utils/roadmap-dashboard.sh`); the RELEASES DB (`releases.db` via `releases.sql`) is the source of truth (`ROADMAP.md` retired per GH-269)
- `CHANGELOG.md` = the end-of-iteration running log (first-class PDDA artifact; governed by `PROJECT/PDDA.md`)
- `RELEASES.md` = forward-looking release-planning ledger (first-class PDDA artifact; governed by `PROJECT/PDDA.md`)
- `HARNESS-MODELS-REGISTRY.md` = evaluated agent harnesses, supported model grades (A/B/C), and CLI flags
- `MACHINE-CONTRACTS.md` = the Jog ↔ Preflight ↔ Marathon machine-contract reference (`marathon-invocation@1`, `marathon-drive/result@1`) and their version/deprecation policy
- `PROJECT/**` docs = canonical execution detail for a specific effort
- `PROJECT/PDDA.md` = imported PDDA document contract adopted by XYZ (incl. CHANGELOG); protected local adaptations are reviewed under the repo-owned sync policy
- `PROJECT/CONSTITUTION.md` = locally maintained PDDA-layer policy of record, with verified-success, reversibility and local-first safeguards adopted by XYZ; advisory-only LLM checking is PDDA-specific and does not replace XYZ relay approval
- `PROJECT/DO-NOT-BUILD.md` = locally maintained PDDA anti-scope; XYZ product scope remains in GUIDING-PRINCIPLES, not a blanket prohibition on coordination or execution
- `PROJECT/PDDA-MODE-GUIDE.md` = XYZ-maintained guidance for selecting PDDA’s enforcement mode
- `PROJECT/PDDA-SYNC-POLICY.md` = binding XYZ-owned review policy for PDDA dependency updates

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

exec
/bin/zsh -lc 'git diff origin/development...HEAD -- utils/py/harness_app.py test/gh496-telemetry-isolation.sh validate.sh utils/ci-route.sh; cat TESTS-RESULTS/2026-09-09+GH-496-PR1/SUMMARY.md; cat GUIDING-PRINCIPLES.md; cat TESTS-RESULTS/README.md' in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-25720-vf7abaoe
 succeeded in 1976ms:
2026-09-09 21:15:23.498 xcodebuild[32307:65573875]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-09-09 21:15:23.672 xcodebuild[32307:65573873] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.
git: warning: confstr() failed with code 5: couldn't get path of DARWIN_USER_TEMP_DIR; using /tmp instead
git: error: couldn't create cache file '/tmp/xcrun_db-sX1MllWr' (errno=Operation not permitted)
2026-09-09 21:15:24.198 xcodebuild[32315:65573914]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-09-09 21:15:24.375 xcodebuild[32315:65573913] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.
diff --git a/test/gh496-telemetry-isolation.sh b/test/gh496-telemetry-isolation.sh
new file mode 100755
index 00000000..ef72e382
--- /dev/null
+++ b/test/gh496-telemetry-isolation.sh
@@ -0,0 +1,214 @@
+#!/usr/bin/env bash
+# test/gh496-telemetry-isolation.sh — GH-496 Telemetry Relocation & Out-of-Tree Invariants.
+#
+# Proves:
+#   1. get_db_path() defaults to ~/.xyz/projects/<project_key>/telemetry/harnesses.db when unset.
+#   2. XYZ_HARNESS_DB environment override is strictly honored.
+#   3. get_sql_path() and get_generated_md_path() stay alongside the out-of-tree database.
+#   4. --local flag forces resolution to in-repo harnesses.db.
+#   5. First-turn auto-seed: a freshly initialized database auto-seeds canonical harnesses/models,
+#      guaranteeing turn shims succeed without foreign key errors.
+#   6. Working tree cleanliness: running turn logging leaves git status --porcelain 100% clean.
+#   7. Red control: invalid/unregistered harness fails foreign key check.
+#   8. Negative control: tracked repo files remain 100% byte-unchanged across turns.
+set -euo pipefail
+
+ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
+WORK="$(mktemp -d "${TMPDIR:-/tmp}/gh496-telemetry.XXXXXX")"
+[ -n "$WORK" ] || exit 1
+[ -d "$WORK" ] || exit 1
+. "$ROOT/test/lib/fixture-guard.sh"
+fixture_guard_init "$WORK"
+cleanup() { [ -n "${WORK:-}" ] && [ -d "$WORK" ] && rm -rf "$WORK"; }
+trap cleanup EXIT
+WORK="$(cd "$WORK" && pwd -P)"
+
+PASS=0
+FAIL=0
+
+pass() { echo "  PASS: $1"; PASS=$((PASS + 1)); }
+fail() { echo "  FAIL: $1" >&2; FAIL=$((FAIL + 1)); }
+
+export PYTHONPATH="$ROOT/utils/py:${PYTHONPATH:-}"
+HARNESS_APP="$ROOT/utils/py/harness_app.py"
+
+# Capture baseline checksums of tracked files
+BEFORE_DB_CKSUM="$(cksum "$ROOT/harnesses.db")"
+BEFORE_SQL_CKSUM="$(cksum "$ROOT/harnesses.sql")"
+BEFORE_GEN_MD_CKSUM="$(cksum "$ROOT/HARNESS-MODELS-REGISTRY.generated.md")"
+
+echo "== test: gh496-telemetry-isolation =="
+
+# 1. Default out-of-tree path resolution under ~/.xyz/projects/<key>/telemetry/harnesses.db
+FAKE_HOME="$WORK/fake_home"
+mkdir -p "$FAKE_HOME"
+resolved="$(HOME="$FAKE_HOME" unset_env=1 python3 - <<PY
+import os, sys
+sys.path.insert(0, '$ROOT/utils/py')
+os.environ.pop('XYZ_HARNESS_DB', None)
+import harness_app
+print(harness_app.get_db_path('$ROOT'))
+PY
+)"
+EXPECTED_PREFIX="$FAKE_HOME/.xyz/projects/"
+EXPECTED_SUFFIX="/telemetry/harnesses.db"
+if [[ "$resolved" == "$EXPECTED_PREFIX"* ]] && [[ "$resolved" == *"$EXPECTED_SUFFIX" ]]; then
+  pass "get_db_path() defaults to ~/.xyz/projects/<project_key>/telemetry/harnesses.db when unset"
+else
+  fail "get_db_path() did not resolve under ~/.xyz/projects/: got '$resolved'"
+fi
+
+# 2. XYZ_HARNESS_DB override is strictly honored
+overridden="$(XYZ_HARNESS_DB="$WORK/custom/my_harness.db" python3 - <<PY
+import sys
+sys.path.insert(0, '$ROOT/utils/py')
+import harness_app
+print(harness_app.get_db_path('$ROOT'))
+PY
+)"
+if [ "$overridden" = "$WORK/custom/my_harness.db" ]; then
+  pass "get_db_path() honors XYZ_HARNESS_DB environment override"
+else
+  fail "XYZ_HARNESS_DB override not honored: got '$overridden'"
+fi
+
+# 3. get_sql_path() and get_generated_md_path() stay alongside out-of-tree DB
+sql_resolved="$(XYZ_HARNESS_DB="$WORK/custom/my_harness.db" python3 - <<PY
+import sys
+sys.path.insert(0, '$ROOT/utils/py')
+import harness_app
+print(harness_app.get_sql_path('$ROOT'))
+PY
+)"
+md_resolved="$(XYZ_HARNESS_DB="$WORK/custom/my_harness.db" python3 - <<PY
+import sys
+sys.path.insert(0, '$ROOT/utils/py')
+import harness_app
+print(harness_app.get_generated_md_path('$ROOT'))
+PY
+)"
+if [ "$sql_resolved" = "$WORK/custom/my_harness.sql" ] && [ "$md_resolved" = "$WORK/custom/HARNESS-MODELS-REGISTRY.generated.md" ]; then
+  pass "get_sql_path() and get_generated_md_path() stay alongside the out-of-tree database"
+else
+  fail "paths did not resolve alongside DB: sql='$sql_resolved', md='$md_resolved'"
+fi
+
+# 4. --local flag forces resolution to in-repo harnesses.db
+local_db="$(python3 - <<PY
+import os, sys
+sys.path.insert(0, '$ROOT/utils/py')
+import harness_app
+# Simulate --local in main
+os.environ['XYZ_HARNESS_DB'] = os.path.join('$ROOT', 'harnesses.db')
+print(harness_app.get_db_path('$ROOT'))
+PY
+)"
+if [ "$local_db" = "$ROOT/harnesses.db" ]; then
+  pass "--local flag forces resolution to in-repo harnesses.db"
+else
+  fail "--local did not resolve in-repo: got '$local_db'"
+fi
+
+# 5. First-turn auto-seed: logging to a new empty DB succeeds without foreign key failure
+SCRATCH_DB="$WORK/auto_seed_test/harnesses.db"
+XYZ_HARNESS_DB="$SCRATCH_DB" python3 "$HARNESS_APP" log \
+  --device-id "test-device" \
+  --harness-id "codex" \
+  --model-id "deepseek/deepseek-v4-pro" \
+  --gateway "openrouter" \
+  --reasoning-effort "high" \
+  --shim "codex-turn.py" \
+  --task-scope "GH-496 auto-seed validation" \
+  --seconds 1.2 \
+  --exit-code 0 > "$WORK/log.out" 2> "$WORK/log.err" || true
+
+inv_id="$(cat "$WORK/log.out" 2>/dev/null || true)"
+if [ -n "$inv_id" ] && [[ "$inv_id" == inv-* ]]; then
+  pass "First-turn auto-seed: newly initialized database auto-populates harnesses and models on log"
+else
+  fail "First-turn auto-seed failed: log did not produce an invocation ID (err: $(cat "$WORK/log.err" 2>/dev/null))"
+fi
+
+# 6. Evaluation recording on auto-seeded database
+eval_id="$(XYZ_HARNESS_DB="$SCRATCH_DB" python3 "$HARNESS_APP" eval \
+  --invocation-id "$inv_id" \
+  --evaluated-by "tester" \
+  --role "Reviewer" \
+  --grade "A" \
+  --gate-passed 1 \
+  --narrative "Verified auto-seed evaluation recording" 2>"$WORK/eval.err" || true)"
+
+if [ -n "$eval_id" ] && [[ "$eval_id" == eval-* ]]; then
+  pass "Evaluation records cleanly into out-of-tree database without touching git working tree"
+else
+  fail "Evaluation recording failed: err: $(cat "$WORK/eval.err" 2>/dev/null)"
+fi
+
+# 7. Working tree cleanliness: running HarnessTurnLogger leaves git status 100% clean
+# We simulate a turn using fake HOME pointing into $WORK so it uses default out-of-tree resolution
+TURN_WORK="$WORK/turn_simulation"
+mkdir -p "$TURN_WORK/fake_user_home"
+HOME="$TURN_WORK/fake_user_home" XYZ_HARNESS_LOGGING=1 python3 - <<PY
+import os, sys
+sys.path.insert(0, '$ROOT/utils/py')
+os.environ.pop('XYZ_HARNESS_DB', None)
+from harness_turn_logger import HarnessTurnLogger
+
+with HarnessTurnLogger(
+    harness_id="agy",
+    shim="agy-turn.py",
+    task_scope="GH-496 working tree cleanliness check",
+    model_id="deepseek/deepseek-v4-pro",
+    reasoning_effort="high",
+) as logger:
+    logger.tokens = 500
+    logger.cost = 0.001
+    logger.exit_code = 0
+PY
+
+# Verify that the turn wrote to fake HOME
+SIM_DB="$TURN_WORK/fake_user_home/.xyz/projects"/*"/telemetry/harnesses.db"
+if ls $SIM_DB 1>/dev/null 2>&1; then
+  pass "Turn logging successfully routed to host runtime location (~/.xyz/.../telemetry/harnesses.db)"
+else
+  fail "Turn logging did not create database in expected out-of-tree telemetry directory"
+fi
+
+# Verify working tree has ZERO new uncommitted modifications to harnesses.*
+diff_status="$(git -C "$ROOT" status --porcelain harnesses.db harnesses.sql HARNESS-MODELS-REGISTRY.generated.md || true)"
+if [ -z "$diff_status" ]; then
+  pass "Working tree cleanliness: git status --porcelain shows zero tracked harness telemetry churn"
+else
+  fail "Working tree dirty after turn: $diff_status"
+fi
+
+# 8. Red Control: Invalid/unregistered harness fails foreign key check
+rc=0
+out="$(XYZ_HARNESS_DB="$SCRATCH_DB" python3 "$HARNESS_APP" log \
+  --device-id "test-device" \
+  --harness-id "nonexistent_harness_xyz_999" \
+  --model-id "deepseek/deepseek-v4-pro" \
+  --shim "test.py" \
+  --task-scope "Red control foreign key" 2>&1)" || rc=$?
+
+if [ "$rc" -ne 0 ] && grep -qi "foreign key" <<<"$out"; then
+  pass "Red control: unregistered harness_id is strictly rejected by foreign key constraint"
+else
+  fail "Red control failed: expected foreign key rejection, got rc=$rc, out=$out"
+fi
+
+# 9. Negative control: Tracked repo files remain 100% byte-unchanged
+AFTER_DB_CKSUM="$(cksum "$ROOT/harnesses.db")"
+AFTER_SQL_CKSUM="$(cksum "$ROOT/harnesses.sql")"
+AFTER_GEN_MD_CKSUM="$(cksum "$ROOT/HARNESS-MODELS-REGISTRY.generated.md")"
+
+if [ "$BEFORE_DB_CKSUM" = "$AFTER_DB_CKSUM" ] && \
+   [ "$BEFORE_SQL_CKSUM" = "$AFTER_SQL_CKSUM" ] && \
+   [ "$BEFORE_GEN_MD_CKSUM" = "$AFTER_GEN_MD_CKSUM" ]; then
+  pass "Negative control: tracked root files remain 100% byte-identical"
+else
+  fail "Negative control failed: tracked root files were modified during tests"
+fi
+
+echo "gh496-telemetry-isolation: $PASS pass, $FAIL fail"
+[ "$FAIL" -eq 0 ]
diff --git a/utils/ci-route.sh b/utils/ci-route.sh
index e218c0f8..1c15c8d1 100755
--- a/utils/ci-route.sh
+++ b/utils/ci-route.sh
@@ -24,7 +24,7 @@ ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
 SUBSYSTEMS="hq releases telemetry ate swe-diagram pdda agent-chorus standup skills-army-hq"
 SUBSYSTEM_TESTS_hq="hq.sh hq-park.sh hq-park-synthesis.sh hq-dispatch.sh hq-next.sh hq-locator.sh hq-hardening.sh hq-promote.sh hq-marathon-scan.sh hq-rollup.sh hq-marathon-live.sh roadmap-dashboard.sh gh238-hq-releases-mode.sh gh239-hq-status-releases-mode.sh"
 SUBSYSTEM_TESTS_releases="gh32-releases-app.sh gh103-timeline-exporter.sh gh32-releases-artifacts.sh gh53-releases-merge-resolve.sh gh54-merged-dump-refusals.sh gh57-live-merge-resolve.sh gh69-roadmap-shadow.sh gh32-release-target-advisory.sh gh39-releases-project-sync.sh gh153-releases-sidebar-rollup.sh releases-skill.sh gh284-p3-release-milestone.sh gh284-p4-release-lanes.sh litmus-release.sh nightwatch-release.sh meter-release.sh ballast-release.sh gh57-releases-fuzz.sh roadmap-dashboard.sh gh257-roadmap-ledger-fixes.sh gh269-roadmap-retired.sh"
-SUBSYSTEM_TESTS_telemetry="xyz-completion.sh gh358-lock-instrumentation.sh archive-telemetry.sh"
+SUBSYSTEM_TESTS_telemetry="xyz-completion.sh gh358-lock-instrumentation.sh archive-telemetry.sh gh496-telemetry-isolation.sh"
 SUBSYSTEM_TESTS_ate="ate-run-variations.sh gh298-ate-gen4-ci-smoke.sh gh-gen4-phase1-domain-oracles.sh gh-gen4-phase2-adaptive-ate.sh gh-gen4-phase3-fuzz-engine.sh gh-gen4-phase4-repro-synth.sh gh-gen4-phase5-campaign.sh gh478-runaway-guard.sh"
 SUBSYSTEM_TESTS_swe_diagram="swe-diagram.sh"
 SUBSYSTEM_TESTS_pdda="pdda-roadmap-coverage.sh pdda-repo-contract.sh pdda-local-checks.sh gh400-acceptance-fidelity.sh gh400-source-url.sh gh422-backfill-source-url.sh gh425-source-url-slug.sh wave-reconcile.sh gh202-wave-reconcile-issue-state.sh gh232-wave-reconcile-multiphase.sh gh358-wave-reconcile-vendored-paths.sh"
@@ -36,7 +36,7 @@ subsystem_of() {  # <path> -> subsystem name, or nothing when unmapped
   case "$1" in
     utils/hq/*|skills/hq/*)                                                                printf '%s\n' hq ;;
     utils/py/releases_app.py|skills/releases/*|utils/release-lanes.sh|releases.sql|releases.db|utils/releases-merge-resolve.sh|utils/leaderboard.sh|utils/roadmap-dashboard.sh) printf '%s\n' releases ;;
-    utils/telemetry/*)                                                                     printf '%s\n' telemetry ;;
+    utils/telemetry/*|test/gh496-telemetry-isolation.sh)                                  printf '%s\n' telemetry ;;
     utils/ate/*|utils/fuzzing/*|utils/py/telemetry_schema.py|utils/py/domain_oracles.py|utils/py/adaptive_ate.py|utils/py/calibrate_tier1.py|utils/py/fuzz_engine.py|utils/py/repro_synth.py|utils/py/gen4_campaign.py|utils/py/proc_group.py|utils/py/ate_runaway_sweep.py) printf '%s\n' ate ;;
     utils/swe-diagram/*)                                                                   printf '%s\n' swe-diagram ;;
     utils/pdda/*|utils/pdda-local-checks.sh|utils/pdda-catchup.sh|utils/pdda-doc-ready.sh|utils/py/wave_reconcile.py) printf '%s\n' pdda ;;
diff --git a/utils/py/harness_app.py b/utils/py/harness_app.py
index 124ef7a4..616a00bb 100755
--- a/utils/py/harness_app.py
+++ b/utils/py/harness_app.py
@@ -7,9 +7,12 @@ reasoning effort levels, deterministic post-turn AI evaluations, and grounded bl
 
 import argparse
 import datetime
+import hashlib
 import json
 import os
+import re
 import sqlite3
+import subprocess
 import sys
 from pathlib import Path
 from typing import Any, Dict, List, Optional, Tuple
@@ -20,40 +23,101 @@ def get_repo_root() -> str:
     return os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
 
 
+def slugify(value: str) -> str:
+    """Normalize a name into a stable slug."""
+    cleaned = re.sub(r"[^\w\s-]", "", value).strip().lower()
+    return re.sub(r"[-\s]+", "-", cleaned) or "repository"
+
+
+def get_canonical_repo_identity(repo_root: Optional[str] = None) -> Tuple[str, str]:
+    """Derive stable repository slug and canonical remote/path identity (GH-496)."""
+    root = Path(repo_root or get_repo_root()).resolve()
+    remote = ""
+    try:
+        r = subprocess.run(
+            ["git", "-C", str(root), "config", "--get", "remote.origin.url"],
+            capture_output=True,
+            text=True,
+            check=False,
+        )
+        if r.returncode == 0 and r.stdout.strip():
+            remote = r.stdout.strip()
+    except Exception:
+        remote = ""
+
+    identity = remote.rstrip("/") if remote else str(root)
+    if identity.endswith(".git"):
+        identity = identity[:-4]
+    name = identity.rsplit("/", 1)[-1].rsplit(":", 1)[-1] or root.name
+    short_id = hashlib.sha256(identity.encode("utf-8")).hexdigest()[:12]
+    return f"{slugify(name)}--{short_id}", identity
+
+
+def get_project_key(repo_root: Optional[str] = None) -> str:
+    """Derive stable project key for host telemetry store (GH-496)."""
+    key, _ = get_canonical_repo_identity(repo_root)
+    return key
+
+
 def get_db_path(repo_root: Optional[str] = None) -> str:
+    """Resolve SQLite database path (GH-496).
+    
+    Precedence:
+    1. XYZ_HARNESS_DB env var (explicit override for testing/fixtures).
+    2. Out-of-tree default: ~/.xyz/projects/<project-key>/telemetry/harnesses.db
+    3. In-repo fallback: <repo_root>/harnesses.db if HOME is unavailable.
+    """
     if "XYZ_HARNESS_DB" in os.environ:
         return os.environ["XYZ_HARNESS_DB"]
     root = repo_root or get_repo_root()
+    home = os.environ.get("HOME")
+    if home and os.path.isdir(home):
+        project_key = get_project_key(root)
+        telemetry_dir = os.path.join(home, ".xyz", "projects", project_key, "telemetry")
+        return os.path.join(telemetry_dir, "harnesses.db")
     return os.path.join(root, "harnesses.db")
 
 
 def get_sql_path(repo_root: Optional[str] = None) -> str:
+    """Resolve logical SQL dump path (GH-496)."""
     if "XYZ_HARNESS_SQL" in os.environ:
         return os.environ["XYZ_HARNESS_SQL"]
     if "XYZ_HARNESS_DB" in os.environ:
         base = os.path.splitext(os.environ["XYZ_HARNESS_DB"])[0]
         return base + ".sql"
     root = repo_root or get_repo_root()
-    return os.path.join(root, "harnesses.sql")
+    db_p = get_db_path(root)
+    base = os.path.splitext(db_p)[0]
+    return base + ".sql"
 
 
 def get_generated_md_path(repo_root: Optional[str] = None) -> str:
+    """Resolve generated markdown registry view path (GH-496)."""
     if "XYZ_HARNESS_GENERATED_MD" in os.environ:
         return os.environ["XYZ_HARNESS_GENERATED_MD"]
     if "XYZ_HARNESS_DB" in os.environ:
         db_dir = os.path.dirname(os.path.abspath(os.environ["XYZ_HARNESS_DB"]))
         return os.path.join(db_dir, "HARNESS-MODELS-REGISTRY.generated.md")
     root = repo_root or get_repo_root()
+    db_p = get_db_path(root)
+    db_dir = os.path.dirname(os.path.abspath(db_p))
+    if db_dir != os.path.abspath(root):
+        return os.path.join(db_dir, "HARNESS-MODELS-REGISTRY.generated.md")
     return os.path.join(root, "HARNESS-MODELS-REGISTRY.generated.md")
 
 
 def get_blog_doc_path(slug: str, repo_root: Optional[str] = None) -> str:
+    """Resolve generated blog case study path (GH-496)."""
     if "XYZ_HARNESS_DOCS_DIR" in os.environ:
         return os.path.join(os.environ["XYZ_HARNESS_DOCS_DIR"], f"blog-{slug}.md")
     if "XYZ_HARNESS_DB" in os.environ:
         db_dir = os.path.dirname(os.path.abspath(os.environ["XYZ_HARNESS_DB"]))
         return os.path.join(db_dir, "docs", f"blog-{slug}.md")
     root = repo_root or get_repo_root()
+    db_p = get_db_path(root)
+    db_dir = os.path.dirname(os.path.abspath(db_p))
+    if db_dir != os.path.abspath(root):
+        return os.path.join(db_dir, "docs", f"blog-{slug}.md")
     return os.path.join(root, "docs", f"blog-{slug}.md")
 
 
@@ -176,6 +240,10 @@ def init_db(db_path: str) -> sqlite3.Connection:
                 # migration having succeeded, not a failure — a turn must never lose its row to it.
                 if "duplicate column" not in str(e).lower():
                     raise
+        # GH-496: Auto-seed canonical registry if harnesses table is empty
+        h_count = conn.execute("SELECT COUNT(*) FROM harnesses;").fetchone()[0]
+        if h_count == 0:
+            seed_canonical_registry(conn)
     return conn
 
 
@@ -316,6 +384,13 @@ def check_integrity(repo_root: Optional[str] = None) -> int:
     """Validate database foreign keys, schema consistency, and generated views."""
     root = repo_root or get_repo_root()
     db_p = get_db_path(root)
+    # GH-496: If out-of-tree telemetry DB does not exist yet (e.g. cold runner),
+    # but in-repo harnesses.db exists, fall back to in-repo DB for check.
+    if not os.path.exists(db_p):
+        in_repo = os.path.join(root, "harnesses.db")
+        if os.path.exists(in_repo):
+            db_p = in_repo
+
     sql_p = get_sql_path(root)
     gen_md = get_generated_md_path(root)
 
@@ -341,6 +416,7 @@ def check_integrity(repo_root: Optional[str] = None) -> int:
 
 def main() -> int:
     parser = argparse.ArgumentParser(description="harness_app.py — Harness & Models SQLite Registry CLI")
+    parser.add_argument("--local", action="store_true", help="Force using in-repo harnesses.db instead of user telemetry path (GH-496)")
     subparsers = parser.add_subparsers(dest="subcommand", required=True)
 
     # Subcommand: init
@@ -394,6 +470,8 @@ def main() -> int:
 
     args = parser.parse_args()
     root = get_repo_root()
+    if getattr(args, "local", False):
+        os.environ["XYZ_HARNESS_DB"] = os.path.join(root, "harnesses.db")
     db_p = get_db_path(root)
     sql_p = get_sql_path(root)
     md_p = get_generated_md_path(root)
diff --git a/validate.sh b/validate.sh
index 32efdf25..ce7d9e0b 100755
--- a/validate.sh
+++ b/validate.sh
@@ -108,6 +108,7 @@ TESTS=(
   "gh518-muse-adapter-containment.sh" # GH-518 (adapter-level: execution-vs-coordination root classification, process-group reap on timeout)
   "gh346-resolver-fallback.sh"  # GH-346 Phase 1 (alias resolver is an enhancement over a literal floor, never a dependency)
   "gh346-telemetry-row-written.sh" # GH-346 Phase 0 checkbox 0.5 (a row actually lands, with the dispatched model)
+  "gh496-telemetry-isolation.sh"   # GH-496 Phase 1 (routine telemetry written out-of-tree to ~/.xyz/projects/<key>/telemetry/)
   "gh346-registry-view-freshness.sh" # GH-346 (the generated registry view must match harnesses.db)
   "gh346-gateway-allowlists.sh" # GH-346 Phase 2 (every agent-id allowlist agrees on the shipped gateway set)
   "gh346-profile-resolve.sh"    # GH-346 Phase 3a (one name -> harness/gateway/model; no tier may block a turn)
# GH-496 PR 1 — Gate Provenance & Test Results Summary

Branch: `feat/gh496-selective-ci`
Target Commit: `7e2084d2`
Qualification Environment: Disposable full clone `~/marathon-clones/xyz-gh496-gate-pr1` (un-sandboxed, independent `.git`)
Gate: `./validate.sh` (368 parallel test suites + pytest layer + clone invariants)

## Gate Results Summary

| Suite / Check | Result | Detail |
|---|---|---|
| `test/gh496-telemetry-isolation.sh` | 10 / 10 PASS | Default out-of-tree path, env overrides, auto-seed, clean working tree, red control |
| `test/gh35-test-tiers.sh` | 71 / 71 PASS | Test tiers, registry drift, subsystem mappings |
| `test/ci-route.sh` | 63 / 63 PASS | Fast routing, telemetry subsystem mappings |
| `test/mktemp-trap-guard.sh` | 1 / 1 PASS | Static audit of 523 shell scripts; no unguarded mktemp patterns |
| `test/gh1-adoption-guard.sh` | 11 / 11 PASS | Fixture containment audit; zero unaudited suites |
| Full `./validate.sh` | **368 / 368 PASS** | All suites passed; 0 failed |
| `clone-identity-invariant` | PASS | `core.bare=false`, `origin` intact, `HEAD` unchanged |

## Telemetry Relocation Invariant Attestation

1. Live harness turn shims append invocation and evaluation records to `~/.xyz/projects/<project-key>/telemetry/harnesses.db`.
2. Git working tree status across harness turns remains 100% clean (`git status --porcelain` is empty).
3. In-repo curated registry files (`harnesses.db`, `harnesses.sql`, `HARNESS-MODELS-REGISTRY.generated.md`) remain byte-identical.
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

9. **Docs support resumable work (PDDA).** ROUTER points to the governing contracts; the RELEASES DB owns this repository's roadmap ledger, and ROADMAP-DASHBOARD.md is its generated view. Linked PROJECT documents hold plans, decisions and handoff detail; CHANGELOG records dated outcomes. Resume execution using those documents together with the relevant runtime state and evidence. If current documentation contradicts the implementation, correct it or explicitly record the unresolved discrepancy.

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

exec
/bin/zsh -lc "nl -ba utils/py/harness_app.py | sed -n '120,510p'; rg -n '496|telemetry|harness' ROADMAP-DASHBOARD.md; rg --files TESTS-RESULTS/2026-09-09+GH-496-PR1 PROJECT | rg '496|PR1'; nl -ba utils/py/harness_turn_logger.py | sed -n '1,260p'" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-25720-vf7abaoe
 succeeded in 0ms:
   120	        return os.path.join(db_dir, "docs", f"blog-{slug}.md")
   121	    return os.path.join(root, "docs", f"blog-{slug}.md")
   122	
   123	
   124	def init_db(db_path: str) -> sqlite3.Connection:
   125	    """Initialize SQLite database with full schema, indexes, and PRAGMAs."""
   126	    os.makedirs(os.path.dirname(os.path.abspath(db_path)), exist_ok=True)
   127	    conn = sqlite3.connect(db_path)
   128	    conn.row_factory = sqlite3.Row
   129	    conn.execute("PRAGMA foreign_keys = ON;")
   130	    conn.execute("PRAGMA journal_mode = WAL;")
   131	
   132	    with conn:
   133	        conn.executescript("""
   134	        CREATE TABLE IF NOT EXISTS devices (
   135	            device_id TEXT PRIMARY KEY,
   136	            user_name TEXT NOT NULL,
   137	            os_version TEXT NOT NULL,
   138	            cpu_cores INTEGER NOT NULL,
   139	            ram_gb INTEGER NOT NULL,
   140	            created_at DATETIME DEFAULT CURRENT_TIMESTAMP
   141	        );
   142	
   143	        CREATE TABLE IF NOT EXISTS user_configs (
   144	            config_id TEXT PRIMARY KEY,
   145	            device_id TEXT NOT NULL REFERENCES devices(device_id),
   146	            default_harness TEXT NOT NULL,
   147	            default_gateway TEXT NOT NULL,
   148	            default_model TEXT NOT NULL,
   149	            default_reasoning_effort TEXT,
   150	            is_active INTEGER DEFAULT 1,
   151	            updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
   152	        );
   153	
   154	        CREATE TABLE IF NOT EXISTS harnesses (
   155	            harness_id TEXT PRIMARY KEY,
   156	            name TEXT NOT NULL,
   157	            execution_engine TEXT NOT NULL,
   158	            supports_programmatic INTEGER DEFAULT 0,
   159	            supports_reasoning_effort INTEGER DEFAULT 1,
   160	            headless_command_template TEXT NOT NULL,
   161	            standing_policy_role TEXT,
   162	            operating_constraint TEXT
   163	        );
   164	
   165	        CREATE TABLE IF NOT EXISTS models (
   166	            model_id TEXT PRIMARY KEY,
   167	            lab TEXT NOT NULL,
   168	            canonical_name TEXT NOT NULL,
   169	            gateway TEXT NOT NULL,
   170	            context_window INTEGER NOT NULL,
   171	            prompt_price_per_m REAL,
   172	            completion_price_per_m REAL,
   173	            cache_read_price_per_m REAL,
   174	            supported_reasoning_levels TEXT,
   175	            is_deprecated INTEGER DEFAULT 0
   176	        );
   177	
   178	        CREATE TABLE IF NOT EXISTS invocation_logs (
   179	            invocation_id TEXT PRIMARY KEY,
   180	            device_id TEXT NOT NULL REFERENCES devices(device_id),
   181	            harness_id TEXT NOT NULL REFERENCES harnesses(harness_id),
   182	            model_id TEXT NOT NULL REFERENCES models(model_id),
   183	            gateway TEXT NOT NULL,
   184	            reasoning_effort TEXT,
   185	            entry_point_shim TEXT NOT NULL,
   186	            cli_flags TEXT NOT NULL,
   187	            task_scope TEXT NOT NULL,
   188	            wall_clock_seconds REAL,
   189	            exit_code INTEGER NOT NULL,
   190	            total_tokens INTEGER,
   191	            prompt_tokens INTEGER,
   192	            completion_tokens INTEGER,
   193	            estimated_cost_usd REAL,
   194	            repo_diff_stat TEXT,
   195	            model_catalog_version TEXT,
   196	            created_at DATETIME DEFAULT CURRENT_TIMESTAMP
   197	        );
   198	
   199	        CREATE TABLE IF NOT EXISTS evaluations (
   200	            evaluation_id TEXT PRIMARY KEY,
   201	            invocation_id TEXT UNIQUE NOT NULL REFERENCES invocation_logs(invocation_id),
   202	            evaluated_by TEXT NOT NULL,
   203	            evaluation_role TEXT NOT NULL,
   204	            grade TEXT NOT NULL CHECK(grade IN ('A', 'A-', 'B+', 'B', 'B-', 'C', 'N/A')),
   205	            qualifying_gate_passed INTEGER NOT NULL,
   206	            diff_cleanliness_score INTEGER,
   207	            seam_reliability_score INTEGER,
   208	            work_description_narrative TEXT NOT NULL,
   209	            failure_mode_tag TEXT,
   210	            created_at DATETIME DEFAULT CURRENT_TIMESTAMP
   211	        );
   212	
   213	        CREATE TABLE IF NOT EXISTS blog_stories (
   214	            story_id TEXT PRIMARY KEY,
   215	            title TEXT NOT NULL,
   216	            slug TEXT NOT NULL UNIQUE,
   217	            theme TEXT NOT NULL,
   218	            source_evaluations TEXT NOT NULL,
   219	            story_metadata TEXT,
   220	            markdown_content TEXT NOT NULL,
   221	            published_at DATETIME,
   222	            created_at DATETIME DEFAULT CURRENT_TIMESTAMP
   223	        );
   224	
   225	        CREATE INDEX IF NOT EXISTS idx_invocation_device ON invocation_logs(device_id);
   226	        CREATE INDEX IF NOT EXISTS idx_invocation_harness ON invocation_logs(harness_id);
   227	        CREATE INDEX IF NOT EXISTS idx_invocation_model ON invocation_logs(model_id);
   228	        CREATE INDEX IF NOT EXISTS idx_eval_grade ON evaluations(grade);
   229	        """)
   230	        # GH-450: a database created before the Model-catalog integration has no
   231	        # model_catalog_version column, and CREATE TABLE IF NOT EXISTS will not add one. Additive,
   232	        # nullable, idempotent — rows logged before the column simply carry NULL.
   233	        cols = {r[1] for r in conn.execute("PRAGMA table_info(invocation_logs);").fetchall()}
   234	        if "model_catalog_version" not in cols:
   235	            try:
   236	                conn.execute("ALTER TABLE invocation_logs ADD COLUMN model_catalog_version TEXT;")
   237	            except sqlite3.OperationalError as e:
   238	                # Two shims opening the same pre-GH-450 db concurrently can both see the column
   239	                # missing; the loser's ALTER fails with "duplicate column name". That is the
   240	                # migration having succeeded, not a failure — a turn must never lose its row to it.
   241	                if "duplicate column" not in str(e).lower():
   242	                    raise
   243	        # GH-496: Auto-seed canonical registry if harnesses table is empty
   244	        h_count = conn.execute("SELECT COUNT(*) FROM harnesses;").fetchone()[0]
   245	        if h_count == 0:
   246	            seed_canonical_registry(conn)
   247	    return conn
   248	
   249	
   250	def seed_canonical_registry(conn: sqlite3.Connection):
   251	    """Seed initial canonical data from HARNESS-MODELS-REGISTRY baseline."""
   252	    # 1. Devices
   253	    with conn:
   254	        conn.execute("""
   255	        INSERT OR IGNORE INTO devices (device_id, user_name, os_version, cpu_cores, ram_gb)
   256	        VALUES ('primary-macbook-host', 'noelsaw1', 'macOS 15.6', 16, 64);
   257	        """)
   258	
   259	        # 2. User Config
   260	        conn.execute("""
   261	        INSERT OR IGNORE INTO user_configs (config_id, device_id, default_harness, default_gateway, default_model, default_reasoning_effort)
   262	        VALUES ('cfg-primary-default', 'primary-macbook-host', 'deepseek-harness', 'openrouter', 'deepseek/deepseek-v4-pro', 'high');
   263	        """)
   264	
   265	        # 3. Harnesses
   266	        harnesses_data = [
   267	            ('dsh', 'DeepSeek Harness', 'node_cordis', 1, 1, 'DSH_PERMISSION_MODE=danger-full-access node .../apps/cli/lib/bin.js --profile headless --patch {overlay} "{task}"', 'Autonomous Headless Builder', 'Evaluated across 4 repository bugs with zero intervention.'),
   268	            ('commandcode', 'Command Code', 'node_langbase', 1, 1, 'cmd -p --tools-all --yolo -t "{task}"', 'Builder & Systems Reviewer', 'Requires worktree isolation and timeout bounding.'),
   269	            ('codex', 'Codex CLI', 'native_cli', 0, 1, 'codex exec "{task}"', 'Cost-blind default builder and reviewer', 'Subscription authenticated.'),
   270	            ('agy', 'Antigravity CLI', 'native_cli', 0, 1, 'agy -p "{task}"', 'Cost-blind cross-model builder/reviewer', 'Sandbox-off required; check empty exit-0.'),
   271	            ('claude', 'Claude Code', 'native_cli', 0, 1, 'claude -p "{task}"', 'Orchestrator and final reviewer', 'Do not use as default headless builder.'),
   272	            ('aider', 'Aider', 'python_litellm', 0, 0, 'aider --message "{task}"', 'Builder only', 'Force AIDER_FLAGS=--edit-format diff; reviewer seam Intermittent.'),
   273	            ('pi', 'Pi Agent', 'node_multi', 0, 0, 'pi -p --mode json "{task}"', 'Builder only', 'Explicit PI_MODEL required.'),
   274	            ('muse', 'Muse Code', 'native_cli', 1, 1, 'muse exec --model {model} --reasoning-effort {effort} --workspace {workspace} --trust-workspace --prompt-file {task}', 'Evaluation only (GH-518)', 'Absolute MUSE_BIN (PATH not modified). Needs --workspace + --trust-workspace or the turn is read-only and silently writes nothing. Contributor tier carries a data-use clause: public repos only.'),
   275	        ]
   276	        for h in harnesses_data:
   277	            conn.execute("""
   278	            INSERT OR REPLACE INTO harnesses (harness_id, name, execution_engine, supports_programmatic, supports_reasoning_effort, headless_command_template, standing_policy_role, operating_constraint)
   279	            VALUES (?, ?, ?, ?, ?, ?, ?, ?);
   280	            """, h)
   281	
   282	        # 4. Models
   283	        models_data = [
   284	            ('openrouter/deepseek/deepseek-v4-pro', 'DeepSeek', 'DeepSeek V4 Pro', 'openrouter', 1000000, 0.435, 0.87, 0.0036, '["low", "medium", "high", "max"]'),
   285	            ('deepseek/deepseek-chat', 'DeepSeek', 'DeepSeek V3', 'openrouter', 1000000, 0.27, 1.10, 0.0028, '["none"]'),
   286	            ('Qwen/Qwen3.8-Max', 'Alibaba', 'Qwen 3.8-Max', 'openrouter', 1000000, 2.00, 6.00, 0.25, '["low", "medium", "xhigh"]'),
   287	            ('Qwen/Qwen3.7-Flash', 'Alibaba', 'Qwen 3.7-Flash', 'openrouter', 1000000, 0.03, 0.13, 0.006, '["none"]'),
   288	            ('openrouter/stealth/ox-alpha', 'Stealth', 'Stealth Ox-Alpha', 'openrouter', 1000000, 1.50, 4.50, 0.20, '["high", "max"]'),
   289	            ('zai-org/GLM-5.3', 'Z.ai', 'GLM 5.3 High', 'openrouter', 1000000, 1.40, 4.40, 0.26, '["low", "high", "max"]'),
   290	            ('google/gemma-4-31b-qat', 'Google', 'Gemma 4 31B QAT', 'lmstudio', 32768, 0.0, 0.0, 0.0, '["none"]'),
   291	            # GH-518. Prices and reasoning tiers are Meta's own provider-catalog values as served to
   292	            # Muse Code 1.0.3, not documentation. The two rows are the SAME model on different terms:
   293	            # the -contributor tier is ~12x cheaper because submitted content, including
   294	            # inter-session messages, may be used for product improvement. Note it also drops the
   295	            # `max` reasoning tier the full-price row carries.
   296	            ('muse-spark-1.3', 'Meta', 'Muse Spark 1.3', 'meta', 1007997, 1.25, 4.25, 0.15, '["minimal", "low", "medium", "high", "xhigh", "max"]'),
   297	            ('muse-spark-1.3-contributor', 'Meta', 'Muse Spark 1.3 Contributor', 'meta', 1007997, 0.10, 0.20, 0.002, '["minimal", "low", "medium", "high", "xhigh"]'),
   298	        ]
   299	        for m in models_data:
   300	            conn.execute("""
   301	            INSERT OR REPLACE INTO models (model_id, lab, canonical_name, gateway, context_window, prompt_price_per_m, completion_price_per_m, cache_read_price_per_m, supported_reasoning_levels)
   302	            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?);
   303	            """, m)
   304	
   305	
   306	def dump_sql(conn: sqlite3.Connection, sql_path: str):
   307	    """Losslessly dump database schema and contents into SQL text file."""
   308	    with open(sql_path, "w", encoding="utf-8") as f:
   309	        for line in conn.iterdump():
   310	            f.write(f"{line}\n")
   311	
   312	
   313	def generate_markdown(conn: sqlite3.Connection, md_path: str):
   314	    """Render canonical HARNESS-MODELS-REGISTRY.generated.md view from database."""
   315	    harnesses = conn.execute("SELECT * FROM harnesses ORDER BY harness_id;").fetchall()
   316	    models = conn.execute("SELECT * FROM models ORDER BY lab, canonical_name;").fetchall()
   317	    evals = conn.execute("""
   318	        SELECT e.grade, e.evaluated_by, e.evaluation_role, e.work_description_narrative,
   319	               i.harness_id, i.model_id, i.reasoning_effort, i.created_at
   320	        FROM evaluations e
   321	        JOIN invocation_logs i ON e.invocation_id = i.invocation_id
   322	        ORDER BY e.created_at DESC;
   323	    """).fetchall()
   324	
   325	    lines = [
   326	        "# Harness & Models Registry (Generated View)",
   327	        "",
   328	        "<!-- Auto-generated from harnesses.db by utils/py/harness_app.py — DO NOT HAND-EDIT -->",
   329	        "",
   330	        "## 1. Operating Harnesses & Policy Lanes",
   331	        "",
   332	        "| Harness | Execution Engine | Policy Role | Operating Constraint |",
   333	        "|---|---|---|---|",
   334	    ]
   335	    for h in harnesses:
   336	        lines.append(f"| **{h['name']}** (`{h['harness_id']}`) | `{h['execution_engine']}` | {h['standing_policy_role'] or '—'} | {h['operating_constraint'] or '—'} |")
   337	
   338	    lines.extend([
   339	        "",
   340	        "## 2. Frontier Models & Reasoning Catalog",
   341	        "",
   342	        "| Lab | Model | Context | Reasoning Levels | Pricing ($/1M in / out / cache) |",
   343	        "|---|---|:---:|:---:|:---:|",
   344	    ])
   345	    for m in models:
   346	        p_in = f"${m['prompt_price_per_m']:.2f}" if m['prompt_price_per_m'] is not None else "—"
   347	        p_out = f"${m['completion_price_per_m']:.2f}" if m['completion_price_per_m'] is not None else "—"
   348	        p_cache = f"${m['cache_read_price_per_m']:.4f}" if m['cache_read_price_per_m'] is not None else "—"
   349	        prices = f"{p_in} / {p_out} / {p_cache}"
   350	        raw_levels = m['supported_reasoning_levels'] or ""
   351	        if raw_levels.startswith("["):
   352	            try:
   353	                levels = ", ".join(json.loads(raw_levels))
   354	            except Exception:
   355	                levels = raw_levels
   356	        else:
   357	            levels = raw_levels
   358	        levels = levels or "—"
   359	        lines.append(f"| **{m['lab']}** | `{m['canonical_name']}` | {m['context_window']:,} | `{levels}` | {prices} |")
   360	
   361	    lines.extend([
   362	        "",
   363	        "## 3. Empirical Evaluation History & Qualitative Work Logs",
   364	        "",
   365	    ])
   366	    if not evals:
   367	        lines.append("*No evaluations recorded yet in database.*")
   368	    else:
   369	        for ev in evals:
   370	            lines.append(f"### `{ev['model_id']}` on `{ev['harness_id']}` — Grade **{ev['grade']}**")
   371	            lines.append(f"**Evaluated by:** `{ev['evaluated_by']}` ({ev['evaluation_role']}) | **Date:** {ev['created_at']}")
   372	            if ev['reasoning_effort']:
   373	                lines.append(f"**Reasoning Effort:** `{ev['reasoning_effort']}`")
   374	            lines.append("")
   375	            lines.append(ev['work_description_narrative'])
   376	            lines.append("")
   377	
   378	    content = "\n".join(lines) + "\n"
   379	    with open(md_path, "w", encoding="utf-8") as f:
   380	        f.write(content)
   381	
   382	
   383	def check_integrity(repo_root: Optional[str] = None) -> int:
   384	    """Validate database foreign keys, schema consistency, and generated views."""
   385	    root = repo_root or get_repo_root()
   386	    db_p = get_db_path(root)
   387	    # GH-496: If out-of-tree telemetry DB does not exist yet (e.g. cold runner),
   388	    # but in-repo harnesses.db exists, fall back to in-repo DB for check.
   389	    if not os.path.exists(db_p):
   390	        in_repo = os.path.join(root, "harnesses.db")
   391	        if os.path.exists(in_repo):
   392	            db_p = in_repo
   393	
   394	    sql_p = get_sql_path(root)
   395	    gen_md = get_generated_md_path(root)
   396	
   397	    if not os.path.exists(db_p):
   398	        print(f"harness check: FAIL — database missing at {db_p}", file=sys.stderr)
   399	        return 1
   400	
   401	    conn = init_db(db_p)
   402	    fk_errors = conn.execute("PRAGMA foreign_key_check;").fetchall()
   403	    if fk_errors:
   404	        print(f"harness check: FAIL — foreign key integrity errors: {fk_errors}", file=sys.stderr)
   405	        return 1
   406	
   407	    integ = conn.execute("PRAGMA integrity_check;").fetchall()
   408	    if not integ or integ[0][0] != "ok":
   409	        print(f"harness check: FAIL — SQLite integrity check failed: {integ}", file=sys.stderr)
   410	        return 1
   411	
   412	    print("OK: SQLite database integrity verified (foreign_keys=ON, integrity_check=ok)")
   413	    print("harness check: clean (0 failures, 0 warnings)")
   414	    return 0
   415	
   416	
   417	def main() -> int:
   418	    parser = argparse.ArgumentParser(description="harness_app.py — Harness & Models SQLite Registry CLI")
   419	    parser.add_argument("--local", action="store_true", help="Force using in-repo harnesses.db instead of user telemetry path (GH-496)")
   420	    subparsers = parser.add_subparsers(dest="subcommand", required=True)
   421	
   422	    # Subcommand: init
   423	    subparsers.add_parser("init", help="Initialize and seed harnesses.db")
   424	
   425	    # Subcommand: dump
   426	    subparsers.add_parser("dump", help="Dump database to harnesses.sql")
   427	
   428	    # Subcommand: gen
   429	    subparsers.add_parser("gen", help="Generate HARNESS-MODELS-REGISTRY.generated.md")
   430	
   431	    # Subcommand: check
   432	    subparsers.add_parser("check", help="Run integrity and schema validation checks")
   433	
   434	    # Subcommand: log
   435	    log_parser = subparsers.add_parser("log", help="Log a harness execution invocation")
   436	    log_parser.add_argument("--device-id", required=True)
   437	    log_parser.add_argument("--harness-id", required=True)
   438	    log_parser.add_argument("--model-id", required=True)
   439	    log_parser.add_argument("--gateway", default="openrouter")
   440	    log_parser.add_argument("--reasoning-effort", choices=["none", "low", "medium", "high", "max", "xhigh"])
   441	    log_parser.add_argument("--shim", required=True)
   442	    log_parser.add_argument("--flags", default="[]")
   443	    log_parser.add_argument("--task-scope", required=True)
   444	    log_parser.add_argument("--seconds", type=float, default=0.0)
   445	    log_parser.add_argument("--exit-code", type=int, default=0)
   446	    log_parser.add_argument("--tokens", type=int, default=0)
   447	    log_parser.add_argument("--cost", type=float, default=0.0)
   448	    log_parser.add_argument("--diff-stat", default="")
   449	    log_parser.add_argument("--catalog-version", default=None,
   450	                            help="GH-450: Model-catalog version the alias table was rendered from")
   451	
   452	    # Subcommand: eval
   453	    eval_parser = subparsers.add_parser("eval", help="Record a post-turn AI evaluation")
   454	    eval_parser.add_argument("--invocation-id", required=True)
   455	    eval_parser.add_argument("--evaluated-by", required=True)
   456	    eval_parser.add_argument("--role", required=True)
   457	    eval_parser.add_argument("--grade", choices=["A", "A-", "B+", "B", "B-", "C", "N/A"], required=True)
   458	    eval_parser.add_argument("--gate-passed", type=int, choices=[0, 1], required=True)
   459	    eval_parser.add_argument("--cleanliness", type=int, default=5)
   460	    eval_parser.add_argument("--seam-score", type=int, default=5)
   461	    eval_parser.add_argument("--narrative", required=True)
   462	    eval_parser.add_argument("--failure-tag", default="none")
   463	
   464	    # Subcommand: blog
   465	    blog_parser = subparsers.add_parser("blog", help="Blog story generator subcommands")
   466	    blog_sub = blog_parser.add_subparsers(dest="blog_command", required=True)
   467	    gen_blog = blog_sub.add_parser("gen", help="Generate a publishable case study story")
   468	    gen_blog.add_argument("--theme", required=True)
   469	    gen_blog.add_argument("--slug", required=True)
   470	
   471	    args = parser.parse_args()
   472	    root = get_repo_root()
   473	    if getattr(args, "local", False):
   474	        os.environ["XYZ_HARNESS_DB"] = os.path.join(root, "harnesses.db")
   475	    db_p = get_db_path(root)
   476	    sql_p = get_sql_path(root)
   477	    md_p = get_generated_md_path(root)
   478	
   479	    if args.subcommand == "init":
   480	        conn = init_db(db_p)
   481	        seed_canonical_registry(conn)
   482	        dump_sql(conn, sql_p)
   483	        generate_markdown(conn, md_p)
   484	        print(f"Initialized {db_p} -> dumped {sql_p} -> rendered {md_p}")
   485	        return 0
   486	
   487	    if args.subcommand == "dump":
   488	        conn = init_db(db_p)
   489	        dump_sql(conn, sql_p)
   490	        print(f"Dumped database to {sql_p}")
   491	        return 0
   492	
   493	    if args.subcommand == "gen":
   494	        conn = init_db(db_p)
   495	        generate_markdown(conn, md_p)
   496	        print(f"Rendered {md_p}")
   497	        return 0
   498	
   499	    if args.subcommand == "check":
   500	        return check_integrity(root)
   501	
   502	    if args.subcommand == "log":
   503	        conn = init_db(db_p)
   504	        inv_id = f"inv-{datetime.datetime.now(datetime.timezone.utc).strftime('%Y%m%d%H%M%S')}-{os.urandom(4).hex()}"
   505	        # Auto-infer lab from model identifier (e.g., 'anthropic/claude-3-7-sonnet' -> 'Anthropic')
   506	        lab = "Auto"
   507	        if "/" in args.model_id:
   508	            parts = [p.strip() for p in args.model_id.split("/") if p.strip()]
   509	            if parts:
   510	                if parts[0].lower() == "openrouter" and len(parts) >= 2:
21:| GH-17 · SOP for evaluating new agent harnesses and frontier models | — | [GH-17-SOP-HARNESS-MODEL-EVAL.md](PROJECT/1-INBOX/GH-17-SOP-HARNESS-MODEL-EVAL.md) · [#17](https://github.com/HiQS-Labs/XYZ-forge/issues/17) |
29:| GH-346 · Speed up harness → gateway → model resolution with a real cache | — | [GH-346-HARNESS-GATEWAY-MODEL-RESOLUTION.md](PROJECT/1-INBOX/GH-346-HARNESS-GATEWAY-MODEL-RESOLUTION.md) · [#346](https://github.com/HiQS-Labs/XYZ-forge/issues/346) |
59:| GH-515 · test/agent-chorus.sh: telemetry assertions time-bomb on the default-ON pilot window | — | [GH-515-AGENT-CHORUS-TELEMETRY-TIME-BOMB.md](PROJECT/1-INBOX/GH-515-AGENT-CHORUS-TELEMETRY-TIME-BOMB.md) · [#515](https://github.com/HiQS-Labs/XYZ-forge/issues/515) |
61:| GH-518 · harness: wire Meta's native muse CLI (Muse Spark 1.3 Contributor) as an XYZ route — catalog aliases, muse-turn.sh shim, four-surface evidence | — | [GH-518-MUSE-SPARK-HARNESS-ROUTE.md](PROJECT/1-INBOX/GH-518-MUSE-SPARK-HARNESS-ROUTE.md) · [#518](https://github.com/HiQS-Labs/XYZ-forge/issues/518) |
82:| GH-496 · ci: sharpen CI/CD per Ponytail & Guiding Principles — fix unreachable PR twin guard (#459) and widen Tier-2 routing | — | [GH-496-SHARPEN-CICD.md](PROJECT/2-WORKING/GH-496-SHARPEN-CICD.md) · [#496](https://github.com/HiQS-Labs/XYZ-forge/issues/496) |
110:| GH-197 · two-tier xyz-vendor.sh: Tier 1 core-harness default, Tier 2 opt-in RELEASES overlay + onboarding SOP (GH-105 follow-up) | ✅ | [GH-197-VENDOR-TIER-SPLIT.md](PROJECT/3-COMPLETED/GH-197-VENDOR-TIER-SPLIT.md) · [#197](https://github.com/HiQS-Labs/XYZ-forge/issues/197) |
118:| GH-180 · repro_builder crashes on timeout telemetry records (exit_code: null → TypeError) | ✅ | [GH-180-REPRO-TIMEOUT-CRASH.md](PROJECT/3-COMPLETED/GH-180-REPRO-TIMEOUT-CRASH.md) · [#180](https://github.com/HiQS-Labs/XYZ-forge/issues/180) |
120:| GH-181 · repro_builder emits non-reproducing reproducers from real telemetry (mis-tokenized unquoted command, rc 127 vs expected 2) | ✅ | [GH-181-REPRO-ADAPTER-FIDELITY.md](PROJECT/3-COMPLETED/GH-181-REPRO-ADAPTER-FIDELITY.md) · [#181](https://github.com/HiQS-Labs/XYZ-forge/issues/181) |
122:| GH-184 · committed scratch artifact .relay-scratch/probe_telemetry.json makes every real turn a tracked-file mutation | ✅ | [GH-184-TRACKED-SCRATCH-ARTIFACT.md](PROJECT/3-COMPLETED/GH-184-TRACKED-SCRATCH-ARTIFACT.md) · [#184](https://github.com/HiQS-Labs/XYZ-forge/issues/184) |
137:| GH-358 · wave_reconcile resolves its five harness tools repo-root-relative — inert on every vendored install | — | [GH-358-WAVE-RECONCILE-VENDORED-PATHS.md](PROJECT/2-WORKING/GH-358-WAVE-RECONCILE-VENDORED-PATHS.md) · [#358](https://github.com/HiQS-Labs/XYZ-forge/issues/358) |
141:| GH-365/377 · Test-suite recalibration: envelope, telemetry, contention-skip, PDDA single-scan, ShellCheck width, campaigns, tier routing, route matrix — executing under #377 (supersedes #365) | — | [doc](PROJECT/2-WORKING/GH-377-TEST-SUITE-RECALIBRATION.md) |
146:| GH-132 · feat(skills): formal /review-xyz code review skill & multi-model harness | ✅ | [GH-132-REVIEW-XYZ-SKILL.md](PROJECT/3-COMPLETED/GH-132-REVIEW-XYZ-SKILL.md) · [#132](https://github.com/HiQS-Labs/XYZ-forge/issues/132) |
150:| GH-405 · Local debugging mock harness for GitHub Projects V2 API | — | [GH-405-MOCK-BOARD-HARNESS.md](PROJECT/3-COMPLETED/GH-405-MOCK-BOARD-HARNESS.md) · [#405](https://github.com/HiQS-Labs/XYZ-forge/issues/405) |
164:| GH-94 · research: programmatic tool calling & code-mode execution for harnesses, telemetry, and containment | ✅ | [GH-94-PROGRAMMATIC-TOOL-CALLING.md](PROJECT/3-COMPLETED/GH-94-PROGRAMMATIC-TOOL-CALLING.md) · [#94](https://github.com/HiQS-Labs/XYZ-forge/issues/94) |
187:| GH-516 · skills: express hotfix lane v2 — true direct-push mode, commit-driven reconciliation, recovery subcommand, and central telemetry | ✅ | [doc](PROJECT/3-COMPLETED/GH-516-EXPRESS-TRUE-DIRECT-PUSH-PLAN.md) · [#516](https://github.com/HiQS-Labs/XYZ-forge/issues/516) |
TESTS-RESULTS/2026-09-09+GH-496-PR1/provenance.jsonl
TESTS-RESULTS/2026-09-09+GH-496-PR1/focused-gh496.log
TESTS-RESULTS/2026-09-09+GH-496-PR1/full-gate.log.gz
TESTS-RESULTS/2026-09-09+GH-496-PR1/SUMMARY.md
PROJECT/2-WORKING/GH-496-SHARPEN-CICD.md
PROJECT/2-WORKING/recon-gh496-merge-churn-and-telemetry.md
     1	#!/usr/bin/env python3
     2	"""harness_turn_logger.py (GH-174) — Turn Execution Telemetry Interceptor & Grading Hook.
     3	
     4	Provides a Python context manager (HarnessTurnLogger) to automatically log
     5	harness, gateway, model, reasoning level, wall-clock time, diff stats, and trigger
     6	post-turn AI/reviewer grading.
     7	"""
     8	
     9	import json
    10	import os
    11	import subprocess
    12	import sys as _sys
    13	import time
    14	from typing import Any, Dict, List, Optional
    15	from device_config import get_effective_runtime_config
    16	
    17	
    18	def _vendored_catalog_version(repo_root: str) -> Optional[str]:
    19	    """GH-450: read the vendored Model-catalog's version under repo_root; None on any failure.
    20	
    21	    `_sys` is imported at module scope on purpose: the handler below writes to stderr, and a name
    22	    bound inside the `try` would be unbound exactly when the handler runs — the swallowed-NameError
    23	    shape `test/gh346-telemetry-row-written.sh` exists to catch.
    24	    """
    25	    try:
    26	        here = os.path.dirname(os.path.abspath(__file__))
    27	        if here not in _sys.path:
    28	            _sys.path.insert(0, here)
    29	        from model_catalog import catalog_version  # noqa: E402
    30	        v = catalog_version(repo_root)
    31	        if not v:
    32	            # Never fatal — telemetry must not break a turn (GH-346 Phase 0) — but never silent
    33	            # either: a NULL model_catalog_version column is undiagnosable after the fact, and the
    34	            # cause is always one of "no vendored copy under this root" or "copy unreadable".
    35	            print(f"harness-turn-logger: no readable Model-catalog version under {repo_root} — "
    36	                  f"invocation row will carry a NULL model_catalog_version", file=_sys.stderr)
    37	        return v
    38	    except Exception as e:
    39	        print(f"harness-turn-logger: could not read the vendored Model-catalog version "
    40	              f"({type(e).__name__}: {e}) — invocation row will carry a NULL "
    41	              f"model_catalog_version", file=_sys.stderr)
    42	        return None
    43	
    44	
    45	class HarnessTurnLogger:
    46	    """Context manager for transparently logging turn execution into harnesses.db."""
    47	
    48	    def __init__(
    49	        self,
    50	        harness_id: str,
    51	        shim: str,
    52	        task_scope: str,
    53	        model_id: Optional[str] = None,
    54	        gateway: Optional[str] = None,
    55	        reasoning_effort: Optional[str] = None,
    56	        cli_flags: Optional[List[str]] = None,
    57	        repo_root: Optional[str] = None,
    58	        catalog_version: Optional[str] = None,
    59	    ):
    60	        self.cfg = get_effective_runtime_config()
    61	        self.device_id = self.cfg["device_id"]
    62	        self.harness_id = harness_id
    63	        self.shim = shim
    64	        self.task_scope = task_scope
    65	        self.model_id = model_id or self.cfg["model"]
    66	        self.gateway = gateway or self.cfg["gateway"]
    67	        self.reasoning_effort = reasoning_effort or self.cfg["reasoning_effort"]
    68	        self.cli_flags = cli_flags or []
    69	        self.repo_root = repo_root or os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
    70	        # GH-450: the Model-catalog version the alias table was rendered from, so the invocation
    71	        # row can say which catalog resolved this turn. Explicit arg > the export block
    72	        # resolve-profile.sh emits (XYZ_MODEL_CATALOG_VERSION) > the vendored copy under
    73	        # repo_root. None when nothing is readable; never raises, never blocks the turn.
    74	        self.catalog_version = (
    75	            catalog_version
    76	            or os.environ.get("XYZ_MODEL_CATALOG_VERSION")
    77	            or _vendored_catalog_version(self.repo_root)
    78	        )
    79	        self.start_time: float = 0.0
    80	        self.invocation_id: Optional[str] = None
    81	        self.exit_code: int = 0
    82	        self.tokens: int = 0
    83	        self.cost: float = 0.0
    84	        self.diff_stat: str = ""
    85	
    86	    def __enter__(self):
    87	        self.start_time = time.time()
    88	        return self
    89	
    90	    def __exit__(self, exc_type, exc_val, exc_tb):
    91	        if not self.cfg.get("logging_enabled", False):
    92	            return
    93	
    94	        duration = time.time() - self.start_time
    95	        if exc_type is not None:
    96	            self.exit_code = 1
    97	
    98	        # Extract diff stat if inside a git repo
    99	        try:
   100	            r = subprocess.run(
   101	                ["git", "diff", "--stat"],
   102	                cwd=self.repo_root,
   103	                capture_output=True,
   104	                text=True,
   105	                check=False,
   106	            )
   107	            self.diff_stat = r.stdout.strip().splitlines()[-1] if r.stdout.strip() else "0 files changed"
   108	        except Exception:
   109	            self.diff_stat = "n/a"
   110	
   111	        # Log invocation via harness_app.py
   112	        harness_app = os.path.join(self.repo_root, "utils", "py", "harness_app.py")
   113	        if os.path.exists(harness_app):
   114	            cmd = [
   115	                "python3", harness_app, "log",
   116	                "--device-id", str(self.device_id),
   117	                "--harness-id", str(self.harness_id),
   118	                "--model-id", str(self.model_id),
   119	                "--gateway", str(self.gateway),
   120	                "--reasoning-effort", str(self.reasoning_effort),
   121	                "--shim", str(self.shim),
   122	                "--flags", json.dumps(self.cli_flags),
   123	                "--task-scope", str(self.task_scope),
   124	                "--seconds", f"{duration:.2f}",
   125	                "--exit-code", str(self.exit_code),
   126	                "--tokens", str(self.tokens),
   127	                "--cost", f"{self.cost:.4f}",
   128	                "--diff-stat", str(self.diff_stat),
   129	            ]
   130	            if self.catalog_version:
   131	                cmd += ["--catalog-version", str(self.catalog_version)]
   132	            res = subprocess.run(cmd, cwd=self.repo_root, capture_output=True, text=True, check=False)
   133	            if res.returncode == 0:
   134	                self.invocation_id = res.stdout.strip()
   135	            else:
   136	                # GH-346: this branch did not exist. A non-zero harness_app.py exit was discarded in
   137	                # silence, so a turn could report success while writing NO audit row — measured, not
   138	                # hypothetical: invocation_logs has foreign keys to devices/harnesses/models, and an
   139	                # unseeded or unregistered harness_id fails with "FOREIGN KEY constraint failed".
   140	                # Still non-fatal (a turn must never fail because logging did), but never silent.
   141	                import sys as _sys
   142	                print(
   143	                    f"harness-turn-logger: telemetry row NOT written for {self.harness_id} "
   144	                    f"(harness_app.py exit {res.returncode}): {(res.stderr or '').strip()[-300:]}",
   145	                    file=_sys.stderr,
   146	                )
   147	
   148	    def record_evaluation(
   149	        self,
   150	        evaluated_by: str,
   151	        role: str,
   152	        grade: str,
   153	        gate_passed: bool,
   154	        narrative: str,
   155	        cleanliness: int = 5,
   156	        seam_score: int = 5,
   157	        failure_tag: str = "none",
   158	    ) -> Optional[str]:
   159	        """Record post-turn AI / reviewer evaluation into harnesses.db."""
   160	        if not self.invocation_id:
   161	            return None
   162	
   163	        harness_app = os.path.join(self.repo_root, "utils", "py", "harness_app.py")
   164	        cmd = [
   165	            "python3", harness_app, "eval",
   166	            "--invocation-id", str(self.invocation_id),
   167	            "--evaluated-by", str(evaluated_by),
   168	            "--role", str(role),
   169	            "--grade", str(grade),
   170	            "--gate-passed", "1" if gate_passed else "0",
   171	            "--cleanliness", str(cleanliness),
   172	            "--seam-score", str(seam_score),
   173	            "--narrative", str(narrative),
   174	            "--failure-tag", str(failure_tag),
   175	        ]
   176	        res = subprocess.run(cmd, cwd=self.repo_root, capture_output=True, text=True, check=False)
   177	        return res.stdout.strip() if res.returncode == 0 else None

codex
The main relocation path is coherent, but the integrity check can silently validate a different database than requested. I’m checking the migration contract and test receipts to distinguish readiness blockers from follow-up improvements. Graph tools are unavailable here, so I’m using direct source inspection.
exec
/bin/zsh -lc "cat TESTS-RESULTS/2026-09-09+GH-496-PR1/provenance.jsonl; nl -ba PROJECT/2-WORKING/recon-gh496-merge-churn-and-telemetry.md; nl -ba PROJECT/2-WORKING/GH-496-SHARPEN-CICD.md | sed -n '1,220p'; nl -ba utils/py/harness_app.py | sed -n '502,635p'; rg -n 'harness_app|harnesses.db' test/gh346-registry-view-freshness.sh ci-local.sh validate.sh utils/py/device_config.py utils/ci-route.sh" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-25720-vf7abaoe
 succeeded in 0ms:
{"timestamp": "2026-09-10T04:12:55.000000+00:00", "case": "full-gate-qualification", "command": "./validate.sh", "commit": "7e2084d2", "exit_code": 0, "output": "passed: 368 / 368; failed: 0", "environment": "un-sandboxed shell, disposable full clone ~/marathon-clones/xyz-gh496-gate-pr1; identity read before and after", "identity_unchanged": true, "identity_before": "7e2084d2e14288b0ec584ada7f57fa42036a1f0c", "identity_after": "7e2084d2e14288b0ec584ada7f57fa42036a1f0c", "dirty_after": 0, "note": "GH-496 PR 1 full validation gate clean"}
{"timestamp": "2026-09-10T04:01:13.000000+00:00", "case": "mktemp-and-fixture-guards", "command": "bash test/mktemp-trap-guard.sh && bash test/gh1-adoption-guard.sh", "commit": "7e2084d2", "exit_code": 0, "output": "mktemp-trap-guard: 1 passed, 0 failed; gh1-adoption-guard: 11 pass, 0 fail", "environment": "un-sandboxed shell, disposable full clone ~/marathon-clones/xyz-gh496-gate-pr1", "identity_unchanged": true, "note": "GH-177 and GH-10 static audits pass"}
{"timestamp": "2026-09-10T04:00:50.000000+00:00", "case": "telemetry-isolation-focused", "command": "bash test/gh496-telemetry-isolation.sh", "commit": "7e2084d2", "exit_code": 0, "output": "10 pass, 0 fail", "environment": "un-sandboxed shell, build clone ~/marathon-clones/xyz-gh496-build", "identity_unchanged": true, "note": "GH-496 Phase 1 hermetic regression suite"}
     1	---
     2	title: GH-496 Merge Churn, Telemetry Relocation, and Router Invariants — Recon Map
     3	status: In progress — Phase 0 bounded source recon
     4	created: 2026-09-10
     5	updated: 2026-09-10
     6	owner: Codex
     7	goal: Trace existing readers, writers, and routing invariants for merge-churn telemetry and releases surfaces.
     8	doc_type: research
     9	roadmap_exempt: true
    10	gh_issue: 496
    11	source: https://github.com/HiQS-Labs/XYZ-forge/issues/496
    12	---
    13	
    14	# Recon Map — GH-496 Merge Churn, Telemetry Relocation, and Router Invariants
    15	
    16	## Status
    17	
    18	| What was just completed | What's next |
    19	|---|---|
    20	| Phase 0 source recon completed; readers, writers, seams, and routing invariants traced. | Execute PR 1 (Phase 1 telemetry isolation to host directory). |
    21	
    22	Baseline SHA: `6261a789d411a78779ad4a630b2ff480ddaa552b`
    23	Mode: Codebase Memory Graph + Source Grep Verification
    24	Lanes: Phase 0 Grounding for PR 1 (Phases 0 & 1)
    25	
    26	---
    27	
    28	## 1. Executive Summary
    29	
    30	Merge landing analysis across the last 40 first-parent commits on `development` demonstrated that 6 shared files accounted for the majority of merge collisions, gate inflations, and dirty-primary checkouts:
    31	- `releases.sql` / `releases.db` (22/40)
    32	- `ROADMAP-DASHBOARD.md` (19/40)
    33	- `LEADERBOARD.md` (18/40)
    34	- `harnesses.sql` / `harnesses.db` (7/40)
    35	
    36	Under Phase 0, we traced the exact call paths, readers, writers, and routing invariants that govern these surfaces. We confirmed that `harnesses.db` is an unmapped path in `utils/ci-route.sh`, causing automatic escalation to Tier 3 (the full 367-suite gate, 10–13 minutes) even when accompanying a trivial docs or skill change (e.g. the 13-line edit in PR #531).
    37	
    38	---
    39	
    40	## 2. Telemetry Writers, Readers, and Seams
    41	
    42	### Writers
    43	Every agent turn shim (`claude-turn.py`, `codex-turn.py`, `agy-turn.py`, `deepseek-turn.py`, `aider-turn.py`, `pi-turn.py`, `muse-turn.py`, `commandcode-turn.py`) initializes a `HarnessTurnLogger` from `utils/py/harness_turn_logger.py`:
    44	1. **`HarnessTurnLogger.__exit__`**:
    45	   - Executes `python3 utils/py/harness_app.py log ...`
    46	   - `harness_app.py` resolves `db_path = get_db_path()`
    47	   - Inserts row into `invocation_logs`
    48	   - Executes `dump_sql(conn, sql_p)`
    49	2. **`HarnessTurnLogger.record_evaluation`**:
    50	   - Executes `python3 utils/py/harness_app.py eval ...`
    51	   - Inserts row into `evaluations`
    52	   - Executes `dump_sql(conn, sql_p)`
    53	   - Executes `generate_markdown(conn, md_p)`
    54	
    55	### Readers
    56	- `utils/py/harness_app.py` CLI: `check` (integrity check), `dump` (dump to SQL), `gen` (markdown view generation), `blog gen` (case study synthesis).
    57	- Test suites: `test/gh174-harness-registry.sh`, `test/gh346-telemetry-row-written.sh`, `test/gh450-model-catalog-pin.sh`.
    58	
    59	### The Seam Defect
    60	When `XYZ_HARNESS_DB` is unset, `get_db_path()` defaults to:
    61	`os.path.join(get_repo_root(), "harnesses.db")`
    62	This causes every turn to write into the tracked checkout, dirtying `harnesses.db` and dumping `harnesses.sql`.
    63	
    64	---
    65	
    66	## 3. Router Invariants and Replay Verification
    67	
    68	In `utils/ci-route.sh`:
    69	- `subsystem_of()` maps known subsystem files.
    70	- `harnesses.db` and `harnesses.sql` are **unmapped**.
    71	- Non-doc unmapped files fall through to:
    72	  `tier=3`
    73	  `tier_reason="unmapped path: $unmapped"`
    74	
    75	### Witnessed Replay Controls:
    76	```bash
    77	$ printf "skills/unstuck/SKILL.md\n" | bash utils/ci-route.sh push
    78	docs_only=true
    79	route=docs
    80	tier=1
    81	tier_reason=docs-only
    82	
    83	$ printf "harnesses.db\n" | bash utils/ci-route.sh push
    84	docs_only=false
    85	route=fast
    86	tier=3
    87	tier_reason=unmapped path: harnesses.db
    88	
    89	$ printf "skills/unstuck/SKILL.md\nharnesses.db\n" | bash utils/ci-route.sh push
    90	docs_only=false
    91	route=fast
    92	tier=3
    93	tier_reason=unmapped path: harnesses.db
    94	```
    95	**Finding:** Relocating `harnesses.db` out of the working tree immediately prevents this unmapped escalation, allowing skill edits to remain at Tier 1 (docs-only).
    96	
    97	---
    98	
    99	## 4. Established Runtime Hierarchy & Path Precedence
   100	
   101	The repository already establishes `~/.xyz/` as the host-local, out-of-tree runtime hierarchy (`~/.xyz/device_config.json`, `~/.xyz/board_sync_state.json`, `~/.xyz/salvage/`).
   102	
   103	`skills/agent-chorus/scripts/agent_chorus.py` establishes the canonical pattern for stable repository identity:
   104	- Normalizes canonical repository root via `git rev-parse --show-toplevel` and `--git-common-dir` (worktree-aware).
   105	- Extracts remote origin URL and computes a 12-char SHA-256 suffix: `f"{slugify(name)}--{short_id}"` (e.g., `xyz-forge--d67b89424bc7`).
   106	
   107	### Target Out-of-Tree Resolution Order for `harness_app.py`:
   108	1. `XYZ_HARNESS_DB` environment variable (if set, always wins).
   109	2. Stable macOS default: `~/.xyz/projects/<stable-project-key>/telemetry/harnesses.db`.
   110	3. Fallback: repo-relative `./harnesses.db` if home directory is unavailable.
   111	
   112	### SQL Dump and View Resolution:
   113	- `XYZ_HARNESS_SQL` > alongside DB (`base + ".sql"`).
   114	- `XYZ_HARNESS_GENERATED_MD` > alongside DB or `HARNESS-MODELS-REGISTRY.generated.md`.
   115	- `XYZ_HARNESS_DOCS_DIR` > `docs/` or override.
   116	
   117	### Fixture Containment Invariant:
   118	All test suites and harnesses running in test mode must explicitly set `XYZ_HARNESS_DB` to a fixture-contained path, asserting:
   119	- Zero writes to user `~/.xyz/`.
   120	- Zero writes to tracked working tree.
   121	
   122	---
   123	
   124	## 5. Curated Registry vs Runtime Telemetry Split
   125	
   126	The SQLite database contains two distinct classes of data:
   127	1. **Curated Versioned Registry**:
   128	   - `devices`, `user_configs`, `harnesses`, `models`.
   129	   - Seeded from `seed_canonical_registry()`.
   130	   - Deliberate edits (e.g. Model-catalog pins in GH-450) can be dumped to versioned git assets.
   131	2. **Live Runtime Telemetry**:
   132	   - `invocation_logs`, `evaluations`, `blog_stories`.
   133	   - Live turn outputs that append to the shared host runtime DB.
   134	
   135	When initializing an out-of-tree database for the first time:
   136	`harness_app.py init` or auto-init will seed the canonical registry tables from the committed baseline (or `seed_canonical_registry()`), ensuring foreign keys to `harnesses` and `models` succeed on the first turn without requiring manual bootstrapping.
   137	
   138	---
   139	
   140	## 6. PR 1 Scope Boundary (Phases 0 & 1)
   141	
   142	- **In Scope for PR 1**:
   143	  - Out-of-tree telemetry path resolution in `utils/py/harness_app.py`.
   144	  - Auto-initialization / seeding of the out-of-tree DB so turns never fail foreign key checks.
   145	  - Verification that ordinary turn shims leave git status 100% clean.
   146	  - Hermetic fixture test suite validating zero home writes, row preservation, and idempotent import.
   147	- **Out of Scope for PR 1 (Deferred to PR 2 & Beyond per Consensus)**:
   148	  - PR 2: Modifying `githooks/dashboard-staleness-guard.sh` or `wave_reconcile.py` view generation.
   149	  - PR 3: Untracking `releases.db` (conditional spike).
   150	  - PR 4: Adding four profile classifications to `utils/ci-route.sh`.
   151	  - PR 5: Contention serialization & benchmarking.
     1	---
     2	title: "GH-496: Reduce merge churn, then select CI by impact"
     3	status: In progress
     4	created: 2026-09-07
     5	updated: 2026-09-10
     6	owner: Antigravity (implementation); independent reviewer (QA)
     7	goal: Reduce merge churn by relocating routine telemetry and decoupling generated views first, then select CI by impact across four profiles using the existing selector
     8	gh_issue: 496
     9	source: https://github.com/HiQS-Labs/XYZ-forge/issues/496#issuecomment-5611834496
    10	branch: feat/gh496-selective-ci
    11	doc_type: enhancement
    12	effort: 4
    13	complexity: 3
    14	risk: 2
    15	---
    16	
    17	# GH-496 — Reduce Merge Churn, Then Select CI by Impact
    18	
    19	Canonical implementation plan: [Issue 496 Comment 5611834496](https://github.com/HiQS-Labs/XYZ-forge/issues/496#issuecomment-5611834496)
    20	Steering / Execution alignment: XYZ AgentChorus #358084 (stored in AgentChorus store)
    21	
    22	## Status
    23	
    24	| What was just completed | What's next |
    25	|---|---|
    26	| Full gate passed (368/368) in disposable clone; test logs & provenance recorded in TESTS-RESULTS/2026-09-09+GH-496-PR1 | Commit test receipts; run relay review; push & open PR 1 |
    27	
    28	## Problem statement
    29	
    30	Historical merge landing data (last 40 first-parent commits on `development`) shows routine churn on 6 shared files:
    31	- `releases.sql` / `releases.db` (22/40)
    32	- `ROADMAP-DASHBOARD.md` (19/40)
    33	- `LEADERBOARD.md` (18/40)
    34	- `harnesses.sql` / `harnesses.db` (7/40)
    35	
    36	These shared files cause repeated merge collisions across parallel task branches, dirty checkouts, and trigger expensive Tier-3 gate runs. Per the canonical plan synthesized by Astra and consensus reached in AgentChorus #358084, we address this in an ordered sequence of focused PRs.
    37	
    38	## Multi-PR Sequence (AgentChorus #358084 Consensus)
    39	
    40	1. **PR 1: Phase 0 (Baseline Freeze & Recon) + Phase 1 (Out-of-Tree Telemetry Relocation)**
    41	   - Replay baseline file sets and commit recon map.
    42	   - Route live invocation/evaluation telemetry in `harness_app.py` out of task checkouts to stable runtime location (`~/.xyz/projects/<stable-project-key>/telemetry/harnesses.db`), preserving versioned curated registry configurations in git.
    43	2. **PR 2: Phase 2 (Single Reconciliation Owner, View Decoupling & Pre-Merge Closeout Checks)**
    44	   - Task branches stop committing routine `ROADMAP-DASHBOARD.md` and `LEADERBOARD.md`; reconciler owns generated views.
    45	   - Pre-merge closeout checks detect missing metadata (e.g. Lessons Learned) before merge.
    46	3. **PR 3: Phase 3 (Conditional Release DB Transport Change Spike)**
    47	   - Spike untracking `releases.db`, treating `releases.sql` as versioned logical transport, with atomic `check --rebuild` bootstrap.
    48	4. **PR 4: Phase 4 (Four Impact Profiles in `ci-route.sh`)**
    49	   - CI/CD, Skills, Core harness, and Accessories profiles extending existing subsystem registry.
    50	5. **PR 5: Phase 5 (Contention Serialization & Speed Benchmark)**
    51	   - Serialize known-flaky contention (GH-528) and measure performance across replay corpus.
    52	
    53	## PR 1 Execution Checklist (Phase 0 & Phase 1)
    54	
    55	### Phase 0: Baseline Freeze, Recon Map, and Preservation Spikes
    56	- [x] Create fresh full clone at `~/marathon-clones/xyz-gh496-build` on `feat/gh496-selective-ci`.
    57	- [x] Install and verify git hooks (`bash githooks/install.sh --check`).
    58	- [x] Grounded recon of `harness_app.py`, writers, readers, callers, and runtime paths.
    59	- [x] Isolated preservation spikes: verify existing path overrides, assert no writes to tracked repo during turns, ensure model/device registry reads remain intact.
    60	- [x] Baseline replay of changed-file sets from #495, #526, #531.
    61	
    62	### Phase 1: Stop Routine Telemetry from Rewriting Task Branches
    63	- [x] Update `harness_app.py` path resolution to default runtime telemetry to `~/.xyz/projects/<stable-project-key>/telemetry/harnesses.db` when not overridden.
    64	- [x] Preserve environment overrides: `XYZ_HARNESS_DB`, `XYZ_HARNESS_SQL`, `XYZ_HARNESS_GENERATED_MD`, `XYZ_HARNESS_DOCS_DIR`.
    65	- [x] Keep versioned model/harness registry inputs intact in git while runtime logs append to external store.
    66	- [x] Concurrency, migration, and idempotent import tests with fixture-contained paths (`test/gh496-telemetry-isolation.sh`).
    67	- [x] Witnessed red controls: dropped row, writer directed to checkout, conflicting ID, foreign key validation.
    68	- [x] Verify clean git status on ordinary harness/relay turns.
    69	
    70	## Acceptance Criteria (PR 1)
    71	- [x] Live harness turns write invocation logs and evaluations to external runtime store without modifying tracked files in task clone.
    72	- [x] Tests hermetically contain all telemetry writes to fixture directories with zero writes to real home directory.
    73	- [x] Curated model registry configurations and benchmarks remain versioned and accessible in git.
    74	- [x] Full gate passes in a disposable clone with committed provenance and test logs.
   502	    if args.subcommand == "log":
   503	        conn = init_db(db_p)
   504	        inv_id = f"inv-{datetime.datetime.now(datetime.timezone.utc).strftime('%Y%m%d%H%M%S')}-{os.urandom(4).hex()}"
   505	        # Auto-infer lab from model identifier (e.g., 'anthropic/claude-3-7-sonnet' -> 'Anthropic')
   506	        lab = "Auto"
   507	        if "/" in args.model_id:
   508	            parts = [p.strip() for p in args.model_id.split("/") if p.strip()]
   509	            if parts:
   510	                if parts[0].lower() == "openrouter" and len(parts) >= 2:
   511	                    lab = parts[1].capitalize()
   512	                else:
   513	                    lab = parts[0].capitalize()
   514	
   515	        with conn:
   516	            conn.execute("""
   517	            INSERT OR IGNORE INTO devices (device_id, user_name, os_version, cpu_cores, ram_gb)
   518	            VALUES (?, ?, ?, ?, ?);
   519	            """, (args.device_id, os.environ.get("USER", "default_user"), sys.platform, os.cpu_count() or 4, 16))
   520	
   521	            conn.execute("""
   522	            INSERT OR IGNORE INTO models (model_id, lab, canonical_name, gateway, context_window, prompt_price_per_m, completion_price_per_m, cache_read_price_per_m, supported_reasoning_levels)
   523	            VALUES (?, ?, ?, ?, 1000000, 0.0, 0.0, 0.0, '["none"]');
   524	            """, (args.model_id, lab, args.model_id, args.gateway or "auto"))
   525	
   526	            conn.execute("""
   527	            INSERT INTO invocation_logs (
   528	                invocation_id, device_id, harness_id, model_id, gateway, reasoning_effort,
   529	                entry_point_shim, cli_flags, task_scope, wall_clock_seconds, exit_code,
   530	                total_tokens, estimated_cost_usd, repo_diff_stat, model_catalog_version
   531	            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
   532	            """, (
   533	                inv_id, args.device_id, args.harness_id, args.model_id, args.gateway,
   534	                args.reasoning_effort, args.shim, args.flags, args.task_scope,
   535	                args.seconds, args.exit_code, args.tokens, args.cost, args.diff_stat,
   536	                args.catalog_version or None
   537	            ))
   538	        dump_sql(conn, sql_p)
   539	        print(inv_id)
   540	        return 0
   541	
   542	    if args.subcommand == "eval":
   543	        conn = init_db(db_p)
   544	        eval_id = f"eval-{datetime.datetime.now(datetime.timezone.utc).strftime('%Y%m%d%H%M%S')}-{os.urandom(4).hex()}"
   545	        with conn:
   546	            conn.execute("""
   547	            INSERT INTO evaluations (
   548	                evaluation_id, invocation_id, evaluated_by, evaluation_role, grade,
   549	                qualifying_gate_passed, diff_cleanliness_score, seam_reliability_score,
   550	                work_description_narrative, failure_mode_tag
   551	            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
   552	            """, (
   553	                eval_id, args.invocation_id, args.evaluated_by, args.role, args.grade,
   554	                args.gate_passed, args.cleanliness, args.seam_score, args.narrative,
   555	                args.failure_tag
   556	            ))
   557	        dump_sql(conn, sql_p)
   558	        generate_markdown(conn, md_p)
   559	        print(eval_id)
   560	        return 0
   561	
   562	    if args.subcommand == "blog" and args.blog_command == "gen":
   563	        conn = init_db(db_p)
   564	        evals = conn.execute("""
   565	            SELECT e.grade, e.evaluated_by, e.work_description_narrative, e.qualifying_gate_passed,
   566	                   i.harness_id, i.model_id, i.reasoning_effort, i.wall_clock_seconds, i.estimated_cost_usd,
   567	                   i.task_scope, i.repo_diff_stat
   568	            FROM evaluations e
   569	            JOIN invocation_logs i ON e.invocation_id = i.invocation_id
   570	            ORDER BY e.created_at DESC;
   571	        """).fetchall()
   572	
   573	        story_id = f"story-{datetime.datetime.now(datetime.timezone.utc).strftime('%Y%m%d%H%M%S')}"
   574	        title = args.theme
   575	        body = [
   576	            f"# {title}",
   577	            "",
   578	            f"**Generated by:** `utils/py/harness_app.py blog gen` | **Published:** {datetime.datetime.now(datetime.timezone.utc).strftime('%Y-%m-%d')}",
   579	            "",
   580	            "## Executive Summary & Empirical Takeaways",
   581	            "",
   582	            f"This benchmark analysis synthesizes empirical results across {len(evals)} verified agent evaluations under load in `XYZ-forge`.",
   583	            "",
   584	            "## Evaluated Performance Matrix",
   585	            "",
   586	            "| Task Scope | Harness & Model | Reasoning Level | Duration | Gate Passed | Grade |",
   587	            "|---|---|:---:|:---:|:---:|:---:|",
   588	        ]
   589	        for ev in evals:
   590	            gate_badge = "✅ PASS" if ev['qualifying_gate_passed'] else "❌ FAIL"
   591	            body.append(f"| {ev['task_scope']} | `{ev['harness_id']}` + `{ev['model_id']}` | `{ev['reasoning_effort'] or 'standard'}` | {ev['wall_clock_seconds']:.1f}s | {gate_badge} | **{ev['grade']}** |")
   592	
   593	        body.extend([
   594	            "",
   595	            "## In-Depth Architectural Narratives & Field Notes",
   596	            "",
   597	        ])
   598	        for ev in evals:
   599	            body.append(f"### Case Study: `{ev['model_id']}` on `{ev['task_scope']}`")
   600	            body.append(ev['work_description_narrative'])
   601	            body.append("")
   602	
   603	        story_md = "\n".join(body) + "\n"
   604	        with conn:
   605	            conn.execute("""
   606	            INSERT OR REPLACE INTO blog_stories (story_id, title, slug, theme, source_evaluations, markdown_content, published_at)
   607	            VALUES (?, ?, ?, ?, ?, ?, CURRENT_TIMESTAMP);
   608	            """, (story_id, title, args.slug, args.theme, json.dumps([]), story_md))
   609	
   610	        dump_sql(conn, sql_p)
   611	        out_path = get_blog_doc_path(args.slug, root)
   612	        os.makedirs(os.path.dirname(os.path.abspath(out_path)), exist_ok=True)
   613	        with open(out_path, "w", encoding="utf-8") as f:
   614	            f.write(story_md)
   615	        print(f"Generated blog story {story_id} -> {out_path}")
   616	        return 0
   617	
   618	    return 0
   619	
   620	
   621	if __name__ == "__main__":
   622	    sys.exit(main())
test/gh346-registry-view-freshness.sh:2:# GH-346: HARNESS-MODELS-REGISTRY.generated.md must match what harnesses.db would render.
test/gh346-registry-view-freshness.sh:8:#   HARNESS-MODELS-REGISTRY.generated.md  rendered from harnesses.db by `harness_app.py gen`,
test/gh346-registry-view-freshness.sh:12:# turn -> HarnessTurnLogger -> harnesses.db -> generated view had no final arrow, so the view
test/gh346-registry-view-freshness.sh:25:DB="$ROOT/harnesses.db"
test/gh346-registry-view-freshness.sh:28:  pass "no harnesses.db in this clone — nothing to render (skipping)"
test/gh346-registry-view-freshness.sh:35:# Render into a scratch dir. harness_app.py resolves the view path beside XYZ_HARNESS_DB, so
test/gh346-registry-view-freshness.sh:37:cp "$DB" "$WORK/harnesses.db"
test/gh346-registry-view-freshness.sh:38:if XYZ_HARNESS_DB="$WORK/harnesses.db" python3 "$ROOT/utils/py/harness_app.py" gen >/dev/null 2>&1; then
test/gh346-registry-view-freshness.sh:39:  pass "harness_app.py gen renders without error"
test/gh346-registry-view-freshness.sh:41:  fail "harness_app.py gen failed — the generated view cannot be verified"
test/gh346-registry-view-freshness.sh:50:  pass "committed view matches what harnesses.db renders today"
test/gh346-registry-view-freshness.sh:54:  fail "HARNESS-MODELS-REGISTRY.generated.md is stale — run: python3 utils/py/harness_app.py gen"
validate.sh:112:  "gh346-registry-view-freshness.sh" # GH-346 (the generated registry view must match harnesses.db)
validate.sh:1145:# harness_app.py, whose every artifact path (db, dump, registry md, blog docs) follows
validate.sh:1147:# (harnesses.db/.sql, HARNESS-MODELS-REGISTRY.generated.md, docs/blog-*.md) stay untouched.
validate.sh:1148:# Regenerating them is an explicit harness_app.py command, never a gate side effect. A pre-set
validate.sh:1153:# the same suites with NO scratch envelope, so a green run dirtied the tracked harnesses.db and
ci-local.sh:389:# scratch envelope at all: harness_app.py writes landed in the TRACKED harnesses.db, the tree

exec
/bin/zsh -lc "PYTHONDONTWRITEBYTECODE=1 python3 - <<'PY'
import sys, os, gzip
from unittest.mock import patch, MagicMock
sys.path.insert(0,'utils/py')
import harness_app as h
c=MagicMock()
c.execute.return_value.fetchall.side_effect=[[], [('ok',)]]
with patch.dict(os.environ, {'XYZ_HARNESS_DB':'/missing/explicit.db'}), patch.object(h.os.path,'exists',side_effect=lambda p:p.endswith('/harnesses.db')), patch.object(h,'init_db',return_value=c) as init:
    print('explicit missing check rc=',h.check_integrity('/fixture/repo'))
    print('actual checked path=',init.call_args.args[0])
with gzip.open('TESTS-RESULTS/2026-09-09+GH-496-PR1/full-gate.log.gz','rt',errors='replace') as f:
    lines=f.readlines()
print('gate lines=',len(lines)); print(''.join(lines[-32:]))
PY
nl -ba utils/py/harness_app.py | sed -n '23,123p'; nl -ba utils/ci-route.sh | sed -n '20,90p'; cat TESTS-RESULTS/2026-09-09+GH-496-PR1/focused-gh496.log" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-25720-vf7abaoe
 succeeded in 0ms:
zsh:1: can't create temp file for here document: operation not permitted
    23	    return os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
    24	
    25	
    26	def slugify(value: str) -> str:
    27	    """Normalize a name into a stable slug."""
    28	    cleaned = re.sub(r"[^\w\s-]", "", value).strip().lower()
    29	    return re.sub(r"[-\s]+", "-", cleaned) or "repository"
    30	
    31	
    32	def get_canonical_repo_identity(repo_root: Optional[str] = None) -> Tuple[str, str]:
    33	    """Derive stable repository slug and canonical remote/path identity (GH-496)."""
    34	    root = Path(repo_root or get_repo_root()).resolve()
    35	    remote = ""
    36	    try:
    37	        r = subprocess.run(
    38	            ["git", "-C", str(root), "config", "--get", "remote.origin.url"],
    39	            capture_output=True,
    40	            text=True,
    41	            check=False,
    42	        )
    43	        if r.returncode == 0 and r.stdout.strip():
    44	            remote = r.stdout.strip()
    45	    except Exception:
    46	        remote = ""
    47	
    48	    identity = remote.rstrip("/") if remote else str(root)
    49	    if identity.endswith(".git"):
    50	        identity = identity[:-4]
    51	    name = identity.rsplit("/", 1)[-1].rsplit(":", 1)[-1] or root.name
    52	    short_id = hashlib.sha256(identity.encode("utf-8")).hexdigest()[:12]
    53	    return f"{slugify(name)}--{short_id}", identity
    54	
    55	
    56	def get_project_key(repo_root: Optional[str] = None) -> str:
    57	    """Derive stable project key for host telemetry store (GH-496)."""
    58	    key, _ = get_canonical_repo_identity(repo_root)
    59	    return key
    60	
    61	
    62	def get_db_path(repo_root: Optional[str] = None) -> str:
    63	    """Resolve SQLite database path (GH-496).
    64	    
    65	    Precedence:
    66	    1. XYZ_HARNESS_DB env var (explicit override for testing/fixtures).
    67	    2. Out-of-tree default: ~/.xyz/projects/<project-key>/telemetry/harnesses.db
    68	    3. In-repo fallback: <repo_root>/harnesses.db if HOME is unavailable.
    69	    """
    70	    if "XYZ_HARNESS_DB" in os.environ:
    71	        return os.environ["XYZ_HARNESS_DB"]
    72	    root = repo_root or get_repo_root()
    73	    home = os.environ.get("HOME")
    74	    if home and os.path.isdir(home):
    75	        project_key = get_project_key(root)
    76	        telemetry_dir = os.path.join(home, ".xyz", "projects", project_key, "telemetry")
    77	        return os.path.join(telemetry_dir, "harnesses.db")
    78	    return os.path.join(root, "harnesses.db")
    79	
    80	
    81	def get_sql_path(repo_root: Optional[str] = None) -> str:
    82	    """Resolve logical SQL dump path (GH-496)."""
    83	    if "XYZ_HARNESS_SQL" in os.environ:
    84	        return os.environ["XYZ_HARNESS_SQL"]
    85	    if "XYZ_HARNESS_DB" in os.environ:
    86	        base = os.path.splitext(os.environ["XYZ_HARNESS_DB"])[0]
    87	        return base + ".sql"
    88	    root = repo_root or get_repo_root()
    89	    db_p = get_db_path(root)
    90	    base = os.path.splitext(db_p)[0]
    91	    return base + ".sql"
    92	
    93	
    94	def get_generated_md_path(repo_root: Optional[str] = None) -> str:
    95	    """Resolve generated markdown registry view path (GH-496)."""
    96	    if "XYZ_HARNESS_GENERATED_MD" in os.environ:
    97	        return os.environ["XYZ_HARNESS_GENERATED_MD"]
    98	    if "XYZ_HARNESS_DB" in os.environ:
    99	        db_dir = os.path.dirname(os.path.abspath(os.environ["XYZ_HARNESS_DB"]))
   100	        return os.path.join(db_dir, "HARNESS-MODELS-REGISTRY.generated.md")
   101	    root = repo_root or get_repo_root()
   102	    db_p = get_db_path(root)
   103	    db_dir = os.path.dirname(os.path.abspath(db_p))
   104	    if db_dir != os.path.abspath(root):
   105	        return os.path.join(db_dir, "HARNESS-MODELS-REGISTRY.generated.md")
   106	    return os.path.join(root, "HARNESS-MODELS-REGISTRY.generated.md")
   107	
   108	
   109	def get_blog_doc_path(slug: str, repo_root: Optional[str] = None) -> str:
   110	    """Resolve generated blog case study path (GH-496)."""
   111	    if "XYZ_HARNESS_DOCS_DIR" in os.environ:
   112	        return os.path.join(os.environ["XYZ_HARNESS_DOCS_DIR"], f"blog-{slug}.md")
   113	    if "XYZ_HARNESS_DB" in os.environ:
   114	        db_dir = os.path.dirname(os.path.abspath(os.environ["XYZ_HARNESS_DB"]))
   115	        return os.path.join(db_dir, "docs", f"blog-{slug}.md")
   116	    root = repo_root or get_repo_root()
   117	    db_p = get_db_path(root)
   118	    db_dir = os.path.dirname(os.path.abspath(db_p))
   119	    if db_dir != os.path.abspath(root):
   120	        return os.path.join(db_dir, "docs", f"blog-{slug}.md")
   121	    return os.path.join(root, "docs", f"blog-{slug}.md")
   122	
   123	
    20	# three-part act: name the subsystem in SUBSYSTEMS, add its path patterns to subsystem_of(),
    21	# and list its suites in SUBSYSTEM_TESTS_<name>. Every listed suite must exist in test/ AND
    22	# be registered in validate.sh's TESTS array — test/gh35-test-tiers.sh enforces both, because
    23	# a registry naming a suite that never runs is a green lie (the releases-skill lesson).
    24	SUBSYSTEMS="hq releases telemetry ate swe-diagram pdda agent-chorus standup skills-army-hq"
    25	SUBSYSTEM_TESTS_hq="hq.sh hq-park.sh hq-park-synthesis.sh hq-dispatch.sh hq-next.sh hq-locator.sh hq-hardening.sh hq-promote.sh hq-marathon-scan.sh hq-rollup.sh hq-marathon-live.sh roadmap-dashboard.sh gh238-hq-releases-mode.sh gh239-hq-status-releases-mode.sh"
    26	SUBSYSTEM_TESTS_releases="gh32-releases-app.sh gh103-timeline-exporter.sh gh32-releases-artifacts.sh gh53-releases-merge-resolve.sh gh54-merged-dump-refusals.sh gh57-live-merge-resolve.sh gh69-roadmap-shadow.sh gh32-release-target-advisory.sh gh39-releases-project-sync.sh gh153-releases-sidebar-rollup.sh releases-skill.sh gh284-p3-release-milestone.sh gh284-p4-release-lanes.sh litmus-release.sh nightwatch-release.sh meter-release.sh ballast-release.sh gh57-releases-fuzz.sh roadmap-dashboard.sh gh257-roadmap-ledger-fixes.sh gh269-roadmap-retired.sh"
    27	SUBSYSTEM_TESTS_telemetry="xyz-completion.sh gh358-lock-instrumentation.sh archive-telemetry.sh gh496-telemetry-isolation.sh"
    28	SUBSYSTEM_TESTS_ate="ate-run-variations.sh gh298-ate-gen4-ci-smoke.sh gh-gen4-phase1-domain-oracles.sh gh-gen4-phase2-adaptive-ate.sh gh-gen4-phase3-fuzz-engine.sh gh-gen4-phase4-repro-synth.sh gh-gen4-phase5-campaign.sh gh478-runaway-guard.sh"
    29	SUBSYSTEM_TESTS_swe_diagram="swe-diagram.sh"
    30	SUBSYSTEM_TESTS_pdda="pdda-roadmap-coverage.sh pdda-repo-contract.sh pdda-local-checks.sh gh400-acceptance-fidelity.sh gh400-source-url.sh gh422-backfill-source-url.sh gh425-source-url-slug.sh wave-reconcile.sh gh202-wave-reconcile-issue-state.sh gh232-wave-reconcile-multiphase.sh gh358-wave-reconcile-vendored-paths.sh"
    31	SUBSYSTEM_TESTS_agent_chorus="agent-chorus.sh"
    32	SUBSYSTEM_TESTS_standup="gh77-standup-triage.sh"
    33	SUBSYSTEM_TESTS_skills_army_hq="skills-army-hq.sh"
    34	
    35	subsystem_of() {  # <path> -> subsystem name, or nothing when unmapped
    36	  case "$1" in
    37	    utils/hq/*|skills/hq/*)                                                                printf '%s\n' hq ;;
    38	    utils/py/releases_app.py|skills/releases/*|utils/release-lanes.sh|releases.sql|releases.db|utils/releases-merge-resolve.sh|utils/leaderboard.sh|utils/roadmap-dashboard.sh) printf '%s\n' releases ;;
    39	    utils/telemetry/*|test/gh496-telemetry-isolation.sh)                                  printf '%s\n' telemetry ;;
    40	    utils/ate/*|utils/fuzzing/*|utils/py/telemetry_schema.py|utils/py/domain_oracles.py|utils/py/adaptive_ate.py|utils/py/calibrate_tier1.py|utils/py/fuzz_engine.py|utils/py/repro_synth.py|utils/py/gen4_campaign.py|utils/py/proc_group.py|utils/py/ate_runaway_sweep.py) printf '%s\n' ate ;;
    41	    utils/swe-diagram/*)                                                                   printf '%s\n' swe-diagram ;;
    42	    utils/pdda/*|utils/pdda-local-checks.sh|utils/pdda-catchup.sh|utils/pdda-doc-ready.sh|utils/py/wave_reconcile.py) printf '%s\n' pdda ;;
    43	    skills/agent-chorus/*)                                                                 printf '%s\n' agent-chorus ;;
    44	    skills/standup/*)                                                                      printf '%s\n' standup ;;
    45	    skills/skills-army-hq/*|test/test_deploy_skills.py|test/skills-army-hq.sh)             printf '%s\n' skills-army-hq ;;
    46	  esac
    47	}
    48	
    49	event_name="${1:-}"
    50	
    51	case "$event_name" in
    52	  # Registry listing — the drift guard and `validate.sh --subsystem` read this instead of
    53	  # re-deriving the mapping. A registered suite missing from disk fails LOUDLY here: a silent
    54	  # skip would turn `--tier 2 --subsystem <name>` into a zero-test gate that exits green.
    55	  subsystems)
    56	    want="${2:-}"
    57	    for s in $SUBSYSTEMS; do
    58	      _tests="SUBSYSTEM_TESTS_${s//-/_}"
    59	      for t in ${!_tests}; do
    60	        [[ -f "$ROOT/test/$t" ]] || { echo "ci-route: subsystem $s registers missing test test/$t" >&2; exit 2; }
    61	      done
    62	    done
    63	    found=0
    64	    for s in $SUBSYSTEMS; do
    65	      [ -z "$want" ] || [ "$want" = "$s" ] || continue
    66	      found=1
    67	      _tests="SUBSYSTEM_TESTS_${s//-/_}"
    68	      if [ -n "$want" ]; then printf '%s\n' "${!_tests}"
    69	      else printf '%s\t%s\n' "$s" "${!_tests}"; fi
    70	    done
    71	    if [ "$found" -eq 0 ]; then
    72	      echo "ci-route: unknown subsystem: '${want}' (known: $(printf '%s' "$SUBSYSTEMS" | tr ' ' ','))" >&2
    73	      exit 2
    74	    fi
    75	    exit 0
    76	    ;;
    77	  workflow_dispatch|schedule)
    78	    # Deliberate, operator-initiated, and rare. These are the only unconditional full routes left:
    79	    # a manual dispatch is someone asking for the whole gate, and answering it with a routed subset
    80	    # would be answering a different question than the one asked.
    81	    printf '%s\n' \
    82	      'docs_only=false' \
    83	      'pdda_needed=true' \
    84	      'full_required=true' \
    85	      'changed_tests=' \
    86	      'route=full' \
    87	      'tier=3' \
    88	      'tier2_subsystems=' \
    89	      'tier2_tests=' \
    90	      'tier_reason=operator-initiated full run'
== test: gh496-telemetry-isolation ==
  PASS: get_db_path() defaults to ~/.xyz/projects/<project_key>/telemetry/harnesses.db when unset
  PASS: get_db_path() honors XYZ_HARNESS_DB environment override
  PASS: get_sql_path() and get_generated_md_path() stay alongside the out-of-tree database
  PASS: --local flag forces resolution to in-repo harnesses.db
  PASS: First-turn auto-seed: newly initialized database auto-populates harnesses and models on log
  PASS: Evaluation records cleanly into out-of-tree database without touching git working tree
  PASS: Turn logging successfully routed to host runtime location (~/.xyz/.../telemetry/harnesses.db)
  PASS: Working tree cleanliness: git status --porcelain shows zero tracked harness telemetry churn
  PASS: Red control: unregistered harness_id is strictly rejected by foreign key constraint
  PASS: Negative control: tracked root files remain 100% byte-identical
gh496-telemetry-isolation: 10 pass, 0 fail

exec
/bin/zsh -lc "PYTHONDONTWRITEBYTECODE=1 python3 -c 'import sys,os,gzip; from unittest.mock import patch,MagicMock; sys.path.insert(0,\"utils/py\"); import harness_app as h; c=MagicMock(); c.execute.return_value.fetchall.side_effect=[[],[(\"ok\",)]]
with patch.dict(os.environ,{\"XYZ_HARNESS_DB\":\"/missing/explicit.db\"}),patch.object(h.os.path,\"exists\",side_effect=lambda p:p.endswith(\"/harnesses.db\")),patch.object(h,\"init_db\",return_value=c) as init:
 print(\"explicit missing check rc=\",h.check_integrity(\"/fixture/repo\")); print(\"actual checked path=\",init.call_args.args[0])
with gzip.open(\"TESTS-RESULTS/2026-09-09+GH-496-PR1/full-gate.log.gz\",\"rt\",errors=\"replace\") as f: lines=f.readlines()
print(\"gate lines=\",len(lines)); print(\"\".join(lines[-22:]))'" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-25720-vf7abaoe
 succeeded in 0ms:
OK: SQLite database integrity verified (foreign_keys=ON, integrity_check=ok)
harness check: clean (0 failures, 0 warnings)
explicit missing check rc= 0
actual checked path= /fixture/repo/harnesses.db
gate lines= 807
  + gh105-vendor-releases-addon.sh
  + gh165-governance-canonical-paths-guard.sh
  + gh132-review-xyz-skill.sh
  + gh273-marathon-root-audit-python-shape.sh
  + gh312-vendor-preserves-state.sh
  + relay-uncited-findings.sh
  + wave-reconcile.sh
  + gh197-vendor-tier-split.sh
  + gh306-registry-bidirectional.sh
  + gh298-ate-gen4-ci-smoke.sh
  + gh-gen4-phase1-domain-oracles.sh
  + gh-gen4-phase2-adaptive-ate.sh
  + gh-gen4-phase4-repro-synth.sh
  + gh-gen4-phase3-fuzz-engine.sh
  + gh396-find-harness-roots.sh
  + gh393-deepseek-readiness.sh
  + gh-gen4-phase5-campaign.sh
  + relay-self-sufficiency.sh
  + gh280-jog-marathon-adapter.sh
  + python:test_python_layer.py
  + clone-identity-invariant
  + gamma-poison-staleness-probe


codex
**ANSWER:** I would not sign off PR 1 yet. The normal relocation path works structurally, but integrity checking violates explicit overrides, and the claimed migration/concurrency verification is absent.

**FINDINGS**

- **[Blocker] `check` can report success for the wrong database.** When `XYZ_HARNESS_DB` explicitly names a missing file, `check_integrity()` silently substitutes the tracked repository database (`utils/py/harness_app.py:389`). A read-only mocked probe confirmed return code `0` while checking `/fixture/repo/harnesses.db` instead of `/missing/explicit.db`. This defeats fixture isolation and the documented override contract. Restrict fallback to the implicit default, and identify the database actually checked.

- **[Blocker] Completed preservation claims exceed the implementation and tests.** The checklist marks concurrency, migration, idempotent import, dropped-row controls, and conflicting-ID controls complete (`PROJECT/2-WORKING/GH-496-SHARPEN-CICD.md:66`). The new suite exercises sequential initialization, logging, evaluation, and an unknown-harness rejection; it contains no migration/import or concurrent-writer exercise. Initialization seeds hardcoded registry data rather than importing existing rows (`utils/py/harness_app.py:243`, `utils/py/harness_app.py:250`). Existing telemetry remains physically preserved in git, but default evaluation/blog operations now use a separate database. Implement and verify the promised preservation behavior, or explicitly revise the accepted scope and document accessing historical data through `--local`.

- **[Should] Two central tests can pass with their target behavior broken.** The `--local` test assigns `XYZ_HARNESS_DB` itself instead of invoking the CLI flag (`test/gh496-telemetry-isolation.sh:90`). The turn test checks database existence, not whether an invocation row landed (`test/gh496-telemetry-isolation.sh:167`); initialization can create that file before logging fails. Invoke the real CLI and query exact invocation/evaluation rows. The foreign-key red control does not falsify these assertions.

- **[Should] Shared-store concurrency needs evidence.** Clones with matching origin strings now share a database, but SQL and Markdown exports still truncate their destination directly (`utils/py/harness_app.py:306`, `utils/py/harness_app.py:379`). SQLite transactions do not serialize these file writes. Test simultaneous cold starts and concurrent log/eval operations, checking row counts and complete, consistent exports.

- **[Should] Project identity has untested stability boundaries.** Identity hashes the remote string, or the individual checkout path when origin is absent (`utils/py/harness_app.py:48`). SSH versus HTTPS origins produce separate stores; origin-less linked worktrees also split. Define the intended equivalence and test it—the recon describes worktree-aware canonicalization that this implementation does not perform (`PROJECT/2-WORKING/recon-gh496-merge-churn-and-telemetry.md:103`).

- **[Pass] Routine paths and suite registration are coherent.** Existing artifact overrides remain supported; default SQL, Markdown, and blog paths follow the external database (`utils/py/harness_app.py:62`). The regression suite is registered in both full validation and the telemetry subsystem (`validate.sh:111`, `utils/ci-route.sh:27`). Harness implementation changes remain outside the narrowed subsystem mapping.

- **[Pass, limited] Retained evidence exists.** The summary’s 368-suite claim has committed provenance, a compressed gate log, and a focused 10-pass log (`TESTS-RESULTS/2026-09-09+GH-496-PR1/SUMMARY.md:17`, `TESTS-RESULTS/2026-09-09+GH-496-PR1/provenance.jsonl:1`). I inspected these artifacts; I did not rerun mutation-heavy suites in this read-only environment. They do not establish the missing preservation controls.

**RECOMMENDATION:** Hold sign-off until explicit-path checking is fixed and preservation/concurrency claims are backed by meaningful tests or an explicitly revised scope.
tokens used
59,932
**ANSWER:** I would not sign off PR 1 yet. The normal relocation path works structurally, but integrity checking violates explicit overrides, and the claimed migration/concurrency verification is absent.

**FINDINGS**

- **[Blocker] `check` can report success for the wrong database.** When `XYZ_HARNESS_DB` explicitly names a missing file, `check_integrity()` silently substitutes the tracked repository database (`utils/py/harness_app.py:389`). A read-only mocked probe confirmed return code `0` while checking `/fixture/repo/harnesses.db` instead of `/missing/explicit.db`. This defeats fixture isolation and the documented override contract. Restrict fallback to the implicit default, and identify the database actually checked.

- **[Blocker] Completed preservation claims exceed the implementation and tests.** The checklist marks concurrency, migration, idempotent import, dropped-row controls, and conflicting-ID controls complete (`PROJECT/2-WORKING/GH-496-SHARPEN-CICD.md:66`). The new suite exercises sequential initialization, logging, evaluation, and an unknown-harness rejection; it contains no migration/import or concurrent-writer exercise. Initialization seeds hardcoded registry data rather than importing existing rows (`utils/py/harness_app.py:243`, `utils/py/harness_app.py:250`). Existing telemetry remains physically preserved in git, but default evaluation/blog operations now use a separate database. Implement and verify the promised preservation behavior, or explicitly revise the accepted scope and document accessing historical data through `--local`.

- **[Should] Two central tests can pass with their target behavior broken.** The `--local` test assigns `XYZ_HARNESS_DB` itself instead of invoking the CLI flag (`test/gh496-telemetry-isolation.sh:90`). The turn test checks database existence, not whether an invocation row landed (`test/gh496-telemetry-isolation.sh:167`); initialization can create that file before logging fails. Invoke the real CLI and query exact invocation/evaluation rows. The foreign-key red control does not falsify these assertions.

- **[Should] Shared-store concurrency needs evidence.** Clones with matching origin strings now share a database, but SQL and Markdown exports still truncate their destination directly (`utils/py/harness_app.py:306`, `utils/py/harness_app.py:379`). SQLite transactions do not serialize these file writes. Test simultaneous cold starts and concurrent log/eval operations, checking row counts and complete, consistent exports.

- **[Should] Project identity has untested stability boundaries.** Identity hashes the remote string, or the individual checkout path when origin is absent (`utils/py/harness_app.py:48`). SSH versus HTTPS origins produce separate stores; origin-less linked worktrees also split. Define the intended equivalence and test it—the recon describes worktree-aware canonicalization that this implementation does not perform (`PROJECT/2-WORKING/recon-gh496-merge-churn-and-telemetry.md:103`).

- **[Pass] Routine paths and suite registration are coherent.** Existing artifact overrides remain supported; default SQL, Markdown, and blog paths follow the external database (`utils/py/harness_app.py:62`). The regression suite is registered in both full validation and the telemetry subsystem (`validate.sh:111`, `utils/ci-route.sh:27`). Harness implementation changes remain outside the narrowed subsystem mapping.

- **[Pass, limited] Retained evidence exists.** The summary’s 368-suite claim has committed provenance, a compressed gate log, and a focused 10-pass log (`TESTS-RESULTS/2026-09-09+GH-496-PR1/SUMMARY.md:17`, `TESTS-RESULTS/2026-09-09+GH-496-PR1/provenance.jsonl:1`). I inspected these artifacts; I did not rerun mutation-heavy suites in this read-only environment. They do not establish the missing preservation controls.

**RECOMMENDATION:** Hold sign-off until explicit-path checking is fixed and preservation/concurrency claims are backed by meaningful tests or an explicitly revised scope.
