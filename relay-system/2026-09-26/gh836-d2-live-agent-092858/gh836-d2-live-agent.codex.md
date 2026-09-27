**SINGLE-MODEL — NOT RECONCILED** (only codex answered; 1 of 2 requested advisor(s) failed — this is one model's read, not a cross-model consult. Do not treat any claim below as cross-verified.)

**NO FIRSTHAND VERIFICATION CITED** — treat conclusions as conditional (codex's answer carries an unsupported [Pass]/verified/confirmed-style claim with no quoted span or file:line citation nearby, despite the consult PREAMBLE asking advisors to cite evidence.)

> **ATTESTATION**
> Model: gpt-6-astra
> Provider: openai
> Sandbox: read-only

Reading additional input from stdin...
OpenAI Codex v0.153.4
--------
workdir: /private/var/folders/z0/92pfvhnn06z2_7hnpdb4kkbw0000gn/T/consult-wt-92092-h1_gqux_
model: gpt-6-astra
provider: openai
approval: never
sandbox: read-only
reasoning effort: medium
reasoning summaries: none
session id: 01a0de8c-6e6b-7362-9aeb-db581672eb6d
--------
user
You are an INDEPENDENT advisor in a one-shot cross-model consult. Another model is answering the SAME question separately and a coordinator will reconcile both answers, so give your own honest, specific read — do not hedge toward a consensus you cannot see. Read any repo files the question references (cite file:line). Respond with: (1) a short direct ANSWER; (2) graded FINDINGS — [Blocker]/[Should]/[Nit]/[Pass] — where applicable; (3) a one-line RECOMMENDATION. You are ADVISORY ONLY: output your analysis as text; do not rely on writing files (you are running in a throwaway copy).

=== CONSULT QUESTION ===
# Consult: should the local pre-push gate stop making a live agent call?

**Advisory only.** Do not edit files. Answer from the repository, and cite `file:line`.

## Facts (verify them)

- `test/relay-self-sufficiency.sh` runs a **real headless agent turn** (agy, or codex as fallback) against a
  minimal relay template. It checks that the `▶ TAKE YOUR TURN` block is enough for a context-free agent to
  complete a turn: shim exit 0, token handoff, and valid VERDICT and Basis fields (`:1-11`, `:75-129`).
- It skips (exit 0) when no agent is on `PATH` or when `RELAY_SELF_SUFFICIENCY_SKIP=1`. When an agent is present
  and the turn fails, it **fails** (exit 1).
- `ci-local.sh:404` and all three `.github/workflows/ci.yml` jobs (`:194`, `:402`, `:483`) set
  `RELAY_SELF_SUFFICIENCY_SKIP=1`. That covers the promotion boundary, the hosted reconcile's run
  (`utils/py/wave_reconcile.py` inherits `ci.yml`'s env? check) and `ci-local`. The **local pre-push hook**
  (`githooks/pre-push` → `validate.sh`) does not set it.
- So on a developer machine with agy or codex installed, **every local full gate** makes one real API call.
  That costs about 2.3–2.7 minutes of wall time (measured on two Macs, #835) plus API cost. A backend or
  network hiccup refuses the push.
- It is not in the Small tier (`utils/ci-route.sh` `SUBSYSTEM_TESTS_small`).
- The template it protects comes from `relay-automation/new-relay.sh`. Any change there routes the full gate
  (`utils/ci-route.sh`, `relay-automation/*` is full-required).
- The repo rule: **no new tests and no new gate machinery** (AGENTS.md, *No new tests*). Editing an existing
  suite or setting an environment default is allowed; a new routing lane is not.

## The question (#836 decision D2)

Should the local pre-push full gate skip this live agent turn by default?

- **A — keep as is.** Every local full gate makes the live call when an agent is on `PATH`.
- **B — skip by default in the pre-push path.** Set `RELAY_SELF_SUFFICIENCY_SKIP=1` in the hook or where the hook
  calls `validate.sh`, with an explicit opt-in to run it. Consequence: it then runs **nowhere** unless someone
  opts in, because every CI path already skips it.
- **C — something narrower,** without new machinery. For example: run it only when the push touches the
  template's source, if the existing hook or classifier can express that; make it opt-in but require it in a
  named manual step such as the relay-automation release or promotion checklist; or keep it but make an
  agent/network failure a witnessed skip instead of a push-blocking red. Say whether any of these needs new
  machinery.

## Please

1. Verify the facts, and correct any that are wrong. In particular, does the hosted reconcile's
   `validate.sh --sequential` run inherit `RELAY_SELF_SUFFICIENCY_SKIP`?
2. What does this suite actually protect, and how often does the protected template change? Check
   `git log -- relay-automation/new-relay.sh`.
3. Recommend A, B or C, with the specific form, and name its risk. If B, what keeps the check from quietly
   never running again?
4. One-line recommendation at the end.

codex
I’ll trace the gate and reconcile environments, inspect what the live suite proves, and check the template’s change history before making a recommendation.

exec
/bin/zsh -lc 'cat ROUTER.md' in /private/var/folders/z0/92pfvhnn06z2_7hnpdb4kkbw0000gn/T/consult-wt-92092-h1_gqux_
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
full-gate surfaces for every file.
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

exec
/bin/zsh -lc 'cat GUIDING-PRINCIPLES.md HARNESS-MODELS-REGISTRY.md TESTS-RESULTS/README.md WORKTREE-SAFETY.md' in /private/var/folders/z0/92pfvhnn06z2_7hnpdb4kkbw0000gn/T/consult-wt-92092-h1_gqux_
 succeeded in 0ms:
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
# Harness & Models Registry

Canonical evidence ledger for agent harnesses and model routes considered by XYZ. The evaluation SOP is
[`PROJECT/1-INBOX/GH-17-SOP-HARNESS-MODEL-EVAL.md`](PROJECT/1-INBOX/GH-17-SOP-HARNESS-MODEL-EVAL.md).

**Scope and evidence boundary (reviewed 2026-08-16).** This registry distinguishes a standing
operating-policy choice from an evaluated harness–model route. Historical results came from the
preceding `xyz-3-agents-swarm` checkout and its GitHub issues; they demonstrate the recorded versions,
providers, and harness configuration only. They do not automatically qualify a renamed model, a new
provider endpoint, or a new harness version.

## Grading rubric

| Grade | Classification | Evidence required |
|:---:|:---|:---|
| **A** | Production-ready | At least three verified end-to-end runs of the exact route, clean scoped diffs, and a passing qualifying gate. The evidence must be reviewable and the final PR/commit state known. |
| **B** | Functional with caveats | A working route whose safe use depends on explicit flags, timeouts, role limits, or supervision; also the holding grade for otherwise-promising runs awaiting final integration/review. |
| **C** | Problematic | Reproducible severe failure mode that prevents unattended use. |
| **N/A** | Untested / insufficient evidence | Cataloged or trialed, but not enough evidence to recommend it. |

Policy designations are deliberately **not grades**. A default lane can be operationally chosen while
its exact current model release awaits the same evidence required of every other route.

## 1. Standing operating lanes (policy, not a model grade)

| Harness | Current policy role | Operating constraint | Policy source |
|---|---|---|---|
| Command Code & Codex CLI | Builder evaluation for GH-57 (2026-08-19) | Non-interactive `cmd --print` on complex synthesis stalled across Muse Spark (4.5 min cap), Qwen 3.8-Max, and GLM-5.2 due to stdout buffering / missing interactive turn cycle. Codex CLI fallback succeeded, producing the 42-assertion `test/gh57-releases-fuzz.sh` suite and updating `utils/fuzzing/fuzz-loop.sh` (42/42 pass). | [#57](https://github.com/HiQS-Labs/XYZ-forge/issues/57) |
| Claude Code | Orchestrator and final reviewer | Do not use as a default headless builder; a Claude builder is operator-selected only. Native subscription mode is documented in the [harness guide](relay-automation/README.md#claude-subscription-mode). [GH-610 evidence](TESTS-RESULTS/2026-09-13+GH-610/validation.jsonl) covers one Max account: consult, attested standalone review, and a contained builder smoke (CLI 2.1.270); no model-grade promotion. | GH-221 / [`AGENTS.md`](AGENTS.md) |
| Codex CLI | Cost-blind default builder and reviewer | Use the subscription-authenticated CLI lane; exact model release must be evaluated separately. | GH-212 / [`AGENTS.md`](AGENTS.md) |
| Antigravity (`agy`) | Cost-blind cross-model builder/reviewer lane | Run sandbox-off; an empty exit-0 response is a known failure mode and its print mode is cost-blind. | GH-178 / [`AGENTS.md`](AGENTS.md) |

## 2. Evaluated compatibility matrix

| Harness | Model / route evaluated | Type | Safe role | Grade | Required flags / limits | Evidence |
|---|---|:---:|---|:---:|---|---|
| DeepSeek Harness (`dsh`) | `openrouter/deepseek/deepseek-v4-pro` | Cloud | Autonomous Headless Builder & Task Solver | **A** | `DSH_PERMISSION_MODE=danger-full-access node .../apps/cli/lib/bin.js --profile headless --patch <overlay.cordis.yml> "<task>"`. Evaluated across 4 real repository bugs in isolated full clone. | [GH-148 umbrella tracking](https://github.com/HiQS-Labs/XYZ-forge/issues/148); [PR #150](https://github.com/HiQS-Labs/XYZ-forge/pull/150), [PR #157](https://github.com/HiQS-Labs/XYZ-forge/pull/157). Successfully resolved GH-142 (`compile_issue.py` missing import and error exit code propagation), GH-68 (`HARNESS-MODELS-REGISTRY.md` Table 1 schema alignment), GH-65 (`test/` portable 3-tier artifact hashing), and GH-156 (turn shims usage `--help`/`-h` flags across all 7 shims) with zero human intervention and 15–40s wall-clock latency per task. |
| OpenRouter / `review-xyz` | `deepseek/deepseek-chat` (DeepSeek-V3) | Cloud | Systems Architecture & Governance Reviewer | **A-** | `python3 utils/py/review_xyz.py --model deepseek/deepseek-chat` or direct OpenRouter engine. High-rigor systems topology and anti-duplication invariant analysis; 20–30s latency. | [GH-165 capture](https://github.com/HiQS-Labs/XYZ-forge/issues/165); evaluated against full governance script trace. Formulated 2-workflow finite state machine and designed AST static regression guard (`test/gh165-governance-canonical-paths-guard.py`). Zero hallucinations; 100% structured actionable output. |
| Command Code | `Qwen/Qwen3.8-Max` | Cloud | Builder & Formal Code Reviewer (`/review-xyz`) | **A-** | `cmd -p --tools-all --yolo -t` for builder runs; `python3 utils/py/review_xyz.py --model Qwen/Qwen3.8-Max` for code review in throwaway worktree isolation. | [GH-18 capture](PROJECT/1-INBOX/GH-18-COMMANDCODE-EVAL.md); [PR #19](https://github.com/HiQS-Labs/XYZ-forge/pull/19), [#20](https://github.com/HiQS-Labs/XYZ-forge/pull/20), [#21](https://github.com/HiQS-Labs/XYZ-forge/pull/21); GH-132 dogfood review of `/review-xyz` engine identifying 5 actionable edge-case improvements with 0 hallucinated findings. |
| Command Code | `qwen/qwen3.7-flash` | Cloud | Builder and advisory review | **B** | Four recorded evaluations: a ~23 s SOP review plus three autonomous builder runs. The builder run-count threshold is met, but retain B pending final PR integration: AEGIS PR #61 and rebalanceOS PR #21 are open, and the rebalanceOS run needed supervisor remediation of three subtle defects. | [GH-18 capture](PROJECT/1-INBOX/GH-18-COMMANDCODE-EVAL.md); [AEGIS #58](https://github.com/HiQS-Labs/AEGIS-Sleuth-Slackbot/issues/58#issuecomment-5310915230) (7 files; 1,940 tests and CI reported green); [AEGIS #60](https://github.com/HiQS-Labs/AEGIS-Sleuth-Slackbot/issues/60#issuecomment-5311414037) ([PR #61](https://github.com/HiQS-Labs/AEGIS-Sleuth-Slackbot/pull/61), open); [rebalanceOS #16](https://github.com/HiQS-Labs/rebalanceOS/issues/16#issuecomment-5311691591) ([PR #21](https://github.com/HiQS-Labs/rebalanceOS/pull/21), open) |
| Command Code | `meta/muse-spark-1.2-contributor` | Cloud | Bounded builder and review turn | **B** | Use only through `commandcode-turn.sh` with its Python `rtl` containment, durable log, timeout, and worktree isolation. Require Codex-owned completion and final QA; do not use unattended for safety-critical changes. | [#41](https://github.com/HiQS-Labs/XYZ-forge/issues/41) (two runs plus live relay); [#42](https://github.com/HiQS-Labs/XYZ-forge/issues/42); [PR #44](https://github.com/HiQS-Labs/XYZ-forge/pull/44), open. |
| Command Code | `laguna-s-2.1-free` | Cloud | None pending a successful bounded evaluation | **N/A** | One worktree-isolated, review-only relay against #48/#49 reached a 300 s cap with zero usable output and `timeout-idle-no-progress`. The free tier is not evidence of a safe unattended lane; retry only under an explicit cap with retained output. | [Command Code pricing](https://commandcode.ai/docs/resources/pricing-limits#laguna-s-2.1-free); [#48](https://github.com/HiQS-Labs/XYZ-forge/issues/48); [#49](https://github.com/HiQS-Labs/XYZ-forge/issues/49); [PR #44](https://github.com/HiQS-Labs/XYZ-forge/pull/44). |
| Muse Code (`muse`) | `muse-spark-1.3-contributor` / `muse-spark-1.3` | Cloud | Advisory reviewer and scoped builder — **NOT a relay turn-taker** | **B** | `muse exec --model <id> [--workspace <dir>] --prompt-file <f>` via `relay-automation/muse-turn.sh`; binary by ABSOLUTE path (installed `MUSE_NO_MODIFY_PATH=1`). Advisory runs omit `--workspace`. **The relay lane does not work yet — see the stall below.** Tier policy is enforced in code, not convention: `resolve_model()` requires EVERY repo root in play to be confirmed public before the discounted tier is used (`test/gh518-muse-model-policy.sh`, 15/0, with a negative control). **The `-contributor` tier carries a data-use clause** — Meta states submitted content, including inter-session messages, may be used for product improvement — so it is public-repository-only. | [GH-518](https://github.com/HiQS-Labs/XYZ-forge/issues/518), [PR #520](https://github.com/HiQS-Labs/XYZ-forge/pull/520). Four surfaces exercised 2026-09-08 on Muse Code 1.0.3. **Builder: pass** — wrote `semver.py` + suite in 33 s; 13/13 its own tests and 11/11 adversarial cases it never saw. **Reviewer: pass** — 34 s; independently identified the same confused-deputy tier-selection defect Codex QA raised on #520, plus the public-repo-vs-public-content gap. **Consult: pass** — 29 s through the new `muse` advisor lane. **Relay: FAIL** — three driven turns produced no relay block. Run 1 (no workspace tools) wrote only its banner; run 2 is void (operator's concurrent writes in the same clone tripped the GH-141 revert, not the model); run 3 was clean and hit the 600 s cap classified `timeout-idle-no-progress` — `cpu=0.00s/s over 59 samples, worktree-progress=no`, i.e. blocked on something external, not working. Bisection ruled out `--trust-workspace` (6.8 s), a 51-skill repo worktree (2.6 s), a prompt file outside the workspace root (2.9 s) and the full relay env (4.5 s); the residual variable is the relay turn prompt itself. Grade is **B, not A**: the rubric wants three verified end-to-end runs of the exact route and this route has **zero** successful relay turns. The three passing surfaces are all single-shot, non-relay. Containment is separately evidenced — the GH-141 revert and the process-group reap both fired correctly (`test/gh518-muse-adapter-containment.sh`, 6/0). |
| OpenRouter / Aider | `openrouter/stealth/ox-alpha` | Cloud | Adversarial Code Review & Technical Audit (`/review-xyz`) | **A-** | Direct `/review-xyz --model stealth/ox-alpha` or `AIDER_AGENT=aider ALLOW_PATHS="" RELAY_WORKTREE_ISOLATION=1 RELAY_TURN_TIMEOUT_S=900`. High-rigor adversarial reasoning; budget 300–600s for large multi-file diffs. Five clean evaluations. | [rebalanceOS #107-#110](https://github.com/HiQS-Labs/rebalanceOS/tree/fix/gh107-110-consolidated-fixes) (v0.75.3, `gh107-110-review.md`, Approved); [rebalanceOS #103](https://github.com/HiQS-Labs/rebalanceOS/issues/103) (`gh103-doctor-critical-path-audit.md`, Approved); [XYZ-forge #119](https://github.com/HiQS-Labs/XYZ-forge/pull/119) (`gh119-linux-evidence-qa.md`, 10 detailed findings R-1..R-10 on `repro.sh`); [XYZ-forge #124](https://github.com/HiQS-Labs/XYZ-forge/issues/124) (`gh124-closeout-auto-pr-review.md`, agent2agent #658731, `gh124-closeout-implementation-qa.md`, Approved); [PR #133 review](https://github.com/HiQS-Labs/XYZ-forge/pull/133) (uncovered 2 Blockers B1/B2 and 8 Nits on `/review-xyz` engine, all verified and resolved). |
| Aider + OpenRouter | `openrouter/z-ai/glm-5.2` | Cloud | Builder only | **B** | Force `AIDER_FLAGS=--edit-format diff`; Aider reviewer turns can produce a review without persisting it, so route reviews to another harness. | Legacy [#118](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/118), [#251](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/251) |
| Aider + OpenRouter | `openrouter/qwen/qwen3.8-max` | Cloud | Advisory review **under supervision only** — never unattended; builder untested on this exact route | **C** | **The model's review content was the strongest recorded this day; the Aider reviewer SEAM is what fails.** Turn 1 landed a correct, fully-cited 7-blocker review with zero false positives. Turn 2 on the same thread produced no findings at all — the model entered a meta-loop about its own output format (whether to edit the `NEXT:` line, how to nest triple-backtick fences when echoing a file containing them) — and `aider-turn.sh`'s GH-251 salvage then appended ~1,200 lines of raw chain-of-thought into the relay file as if it were review content. Budget a human to read and truncate after **every** turn. The shim's qwen brevity instruction (`aider-turn.sh:145-147`, "under 50 words") does not hold on review-only turns. **SECOND USAGE 2026-08-20 (GH-111 + GH-108 code QA) — same split, sharper.** One `--review-once` turn against a 1,944-line diff: 13m 44s wall clock, verdict *Changes requested*, 0 Blockers, 2 `[Should]`, 3 `[Nit]`, 16 `[Pass]` each carrying a file/symbol citation, plus an honest `swept file: yes`. **Every finding was reproduced by the operator before acceptance and every one held** — two real regex false positives that refused a correctly scored entry, one under-graded correctness gap (baseline provenance was mutable; upgraded to Should and shipped as migration 005), one cosmetic bug. Zero hallucinated findings. **The seam failed the same way again:** the model did not append to the relay file; GH-251 salvage recovered the review from the transcript. New datum — the salvage output was **usable this time** (~1,200 lines of thinking with a correctly graded review at the end), so the salvage is not purely a noise amplifier; but 1 of 3 review turns has now landed natively, which is why this stays **C** and not a promotion. | [#111](https://github.com/HiQS-Labs/XYZ-forge/issues/111), [#108](https://github.com/HiQS-Labs/XYZ-forge/issues/108); relays `relay-system/2026-08-20/gh111-dialed-in-qa.md` (usage 1) and `relay-system/2026-08-20/gh111-gh108-qa.md` (usage 2, with the operator's finding-by-finding adjudication) |
| Aider + direct Alibaba MaaS | `qwen3.8-max-preview` | Cloud | Builder only | **B** | Force `AIDER_FLAGS=--edit-format diff`; 900 s was borderline on large-context turns, and multi-file whole-format turns are unsafe. | Legacy [#278](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/278), [#280](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/280) |
| Aider + OpenRouter | `openrouter/anthropic/claude-sonnet-5` | Cloud | Builder only | **B** | The historical model string was unlisted in Aider and auto-selected `whole`; explicitly force `diff` until re-evaluated against the current catalog/version. | Legacy [#280](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/280) |
| Aider + OpenRouter | `nvidia/nemotron-3-ultra` / historical “Nemotron Ultra 3” | Cloud | None recommended | **N/A** | Needs explicit edit format if retried; the recorded reviewer trial did not engage meaningfully, not a builder qualification. | Legacy [#118](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/118), [#119](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/119) |
| Pi | OpenRouter `openai/gpt-mini-latest`; direct Alibaba `qwen3.8-max-preview` | Multi-provider | Builder only | **B** | Set `PI_MODEL` explicitly; Python-default routing was proven, but Pi reviewer support remains rejected/unqualified. | Legacy [#295](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/295), [#414](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/414), [#451](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/451) |
| ATE variation runner + Aider | LM Studio / OpenAI-compatible local endpoint | Local | Variation-test harness, not a production builder | **B** | Opt-in endpoint seam; the runner was Aider-specific and its generalization remained open. Do not read the variation count as a model-quality grade. | Legacy [PR #195](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/pull/195), [#191](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/191) |
| ATE variation runner (`run_variations.py`) | `google/gemma-4-31b-qat` (LM Studio) | Local | Automated test triage classifier only | **B** | Dedicated to structured test variation triage in `run_variations.py`; not a builder or relay turn-taker. | `TESTS-RESULTS/2026-08-20+GH-94/` (438 runs across 3 hours with 0 schema failures); Section 3.2. |
| SmallCode + LM Studio | `qwen/qwen2.5-coder-32b` | Local | Experiment only | **C** | Not safe unattended: repeated successful `tick claim` calls and repeated file reads loop until timeout. | Legacy [#522](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/522) |
| Command Code | `zai-org/GLM-5.3` (GLM 5.3 High) | Cloud | Autonomous Marathon Driver, Builder, and PR Orchestration | **A-** | `cmd -p --tools-all --yolo -t` with isolated workspace clones; verified across two multi-phase marathons (5 phases total). Zero test regressions; clean PRs, branch push verification, and workspace teardown. | [rebalanceOS PR #117](https://github.com/HiQS-Labs/rebalanceOS/pull/117) (Build 0.76.0, 2/2 phases approved, 2,018 tests passed); [rebalanceOS PR #118](https://github.com/HiQS-Labs/rebalanceOS/pull/118) (Build 0.77.0, 3/3 phases approved, 2,026 tests passed) |
| Command Code | `deepseek/deepseek-v4-pro`, `x-ai/grok-4.6`, `moonshotai/kimi-k3`, `minimaxai/minimax-m3` | Cloud | None | **N/A** | Catalog candidates only; no recorded isolated evaluation. | [GH-18](https://github.com/HiQS-Labs/XYZ-forge/issues/18) |

### Frontier Chinese Lab Models Catalog (Command Code Native)

All canonical IDs are exact for use with `cmd -p "<prompt>" -m <id> --tools-all --yolo -t`.

| Lab / Family | Exact Model ID | Context | Reasoning Effort | Pricing ($/1M in / out) | Cache Read ($/1M) | Best For |
|:---|:---|:---:|:---:|:---:|:---:|:---|
| **DeepSeek** | `deepseek/deepseek-v4-pro` | **1,000,000 (1M)** | `high`, `max` | **$0.435 / $0.87** | $0.0036 | Hybrid-attention long-context reasoning |
| **DeepSeek** | `deepseek/deepseek-v4-flash` | **1,000,000 (1M)** | `high`, `max` | **$0.14 / $0.28** | $0.0028 | Ultra-fast hybrid-attention reasoning |
| **Qwen (Alibaba)** | `Qwen/Qwen3.8-Max` | **1,000,000 (1M)** | `low`, `medium`, `xhigh` | **$2.00 / $6.00** | $0.25 | Flagship autonomous coding & professional work |
| **Qwen (Alibaba)** | `Qwen/Qwen3.7-Max` | **1,000,000 (1M)** | — | **$2.50 / $7.50** | $0.50 | Frontier coding & long-horizon agent execution |
| **Qwen (Alibaba)** | `Qwen/Qwen3.7-Plus` | **1,000,000 (1M)** | — | **$0.40 / $1.60** | $0.08 | Agentic coding & reasoning at lower cost |
| **Qwen (Alibaba)** | `Qwen/Qwen3.7-Flash` | **1,000,000 (1M)** | — | **$0.03 / $0.13** | $0.006 | Fast low-cost agentic coding & review audits |
| **Z.ai (Zhipu)** | `zai-org/GLM-5.3` | **1,000,000 (1M)** | `low`, `high`, `max` | **$1.40 / $4.40** | $0.26 | Brand-new flagship with cyber & thinking capabilities |
| **Z.ai (Zhipu)** | `zai-org/GLM-5.2` | **1,000,000 (1M)** | `high`, `max` | **$1.40 / $4.40** | $0.26 | 1M context long-horizon multi-file coding |
| **Z.ai (Zhipu)** | `zai-org/GLM-5.2-Fast` | **1,000,000 (1M)** | — | **$3.00 / $10.25** | $0.50 | High-throughput GLM-5.2 with 1M context |
| **Moonshot AI (Kimi)** | `moonshotai/Kimi-K3` | **1,000,000 (1M)** | — | **$3.00 / $15.00** | $0.30 | 1M context deep knowledge & whole-repo reasoning |
| **Moonshot AI (Kimi)** | `moonshotai/Kimi-K2.7-Code` | **256,000 (256K)** | — | **$0.95 / $4.00** | $0.19 | Long-horizon coding with vision |
| **Moonshot AI (Kimi)** | `moonshotai/Kimi-K2.7-Code-Highspeed` | **262,000 (262K)** | — | **$1.90 / $8.00** | $0.38 | High-speed coding with vision |
| **MiniMax** | `MiniMaxAI/MiniMax-M3` | **1,000,000 (1M)** | — | **$0.30 / $1.20** | $0.06 | Frontier coding, agents & native multimodality |
| **MiniMax** | `MiniMaxAI/MiniMax-M2.7` | — | — | **$0.30 / $1.20** | $0.06 | End-to-end software engineering agent |
| **Xiaomi (MiMo)** | `xiaomi/mimo-v2.5-pro` | **1,000,000 (1M)** | — | **$0.435 / $0.87** | $0.0036 | High-capability long-context agentic coding |
| **Xiaomi (MiMo)** | `xiaomi/mimo-v2.5` | **1,000,000 (1M)** | — | **$0.14 / $0.28** | $0.0028 | Efficient long-context agentic coding |
| **StepFun** | `stepfun/Step-3.7-Flash` | **256,000 (256K)** | — | **$0.20 / $1.15** | $0.04 | Multimodal sparse-MoE reasoning |
| **StepFun** | `stepfun/Step-3.5-Flash` | **1,000,000 (1M)** | — | **$0.10 / $0.30** | $0.02 | Fast sparse-MoE agentic reasoning |
| **Tencent (Hunyuan)** | `tencent/hy3-paid` | **262,000 (262K)** | — | **$0.14 / $0.58** | $0.035 | Sparse-MoE reasoning & agentic tool use |

### Aider-wide constraints

- The Aider turn-taker itself was live-proven as a contained OpenRouter builder lane, but its own
  history/chat files must be redirected outside the repository and it must use `--no-auto-commits`.
  See legacy [#77](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/77).
- For model IDs absent from Aider's model settings, `whole` format can silently discard a valid unified
  diff and leave zero-byte pre-created files. Treat `AIDER_FLAGS=--edit-format diff` as mandatory until
  an exact route earns separate evidence.
- The legacy OpenRouter/Aider reviewer seam was not reliable: it could retain a correct review in its
  transcript while failing to append it to the relay file. Aider is therefore listed as builder-only.
- **Re-confirmed 2026-08-20 (GH-111), with a second, worse failure shape.** The builder-only listing
  above is not stale advice — it was violated by choosing this lane for a review and the documented
  failure recurred on the second turn. Two lessons beyond the original finding:
  1. **The seam is intermittent, not uniformly broken.** Turn 1 appended a genuinely excellent review;
     turn 2 on the same thread appended nothing usable. One good reviewer turn is therefore *not*
     evidence the seam is fixed, and must not be cited to promote Aider out of builder-only.
  2. **GH-251 salvage amplifies a bad turn.** When the model produces reasoning instead of a review,
     the salvage path faithfully preserves that reasoning *as relay content* — here ~1,200 lines.
     The mechanism is correct (it exists to rescue reviews that don't land) but it cannot tell a
     rescued review from rescued noise. Anyone running an Aider review turn should expect to inspect
     and truncate the relay file afterwards, and containment (`ALLOW_PATHS=""`) is what keeps the
     damage confined to that one file — it held, and the reviewed artifact was never at risk.
- **Third review turn, 2026-08-20 (GH-111 + GH-108 code QA) — the split is now a stable pattern, not
  a one-off.** Across three recorded review turns on this route the model's CONTENT has been strong
  twice and useless once, while the DELIVERY has landed natively once out of three. Two further
  lessons:
  3. **Judge the route on content-quality and delivery separately, and grade on the worse one.** The
     second usage produced the most precisely cited review this repo has taken from any harness —
     every finding reproduced on first attempt, none hallucinated — and still did not append to the
     relay file. A reviewer that is right and cannot deliver is a reviewer you must supervise.
  4. **`--review-once` is the right driver mode for this lane.** It classifies a non-approval
     handback as exit 5 (a successful single review) rather than letting the multi-round loop run on
     a seam that may not append. Combined with `ALLOW_PATHS=""`, one turn is inspected and the lane
     closes; the failure modes above cannot compound across rounds.
- **Check this section before choosing a review lane.** The builder-only constraint predates and
  predicted the GH-111 failure; consulting it first would have routed that review to Codex.

## 3. Harness operational profile

| Harness | Execution engine | Billing / observability | Headless contract | Notes |
|---|---|---|---|---|
| Claude Code | Native Anthropic CLI | Subscription or API according to authentication; structured usage is not proof of billing | `claude -p` | Native consult, standalone relay reviewer, explicit operator-selected builder; `CLAUDE_AUTH_MODE=subscription` verifies the account route. |
| Codex CLI | Native OpenAI CLI | Subscription default; token capture historically partial | `codex exec` | Builder/reviewer policy lane. |
| Antigravity | Antigravity CLI | Subscription/cost-blind print mode | `agy -p` | Sandbox-off; empty exit-0 must be detected. |
| Command Code | Node.js / Langbase | Subscription and/or credits | `cmd -p` or `cmd --print --model <id>` | The supported relay route is `commandcode-turn.sh`; current evidence remains pending PR integration. |
| Aider | Python / LiteLLM | API-metered; no reliable stdout usage record in `--message` mode | `aider --message` | Builder-only, with model-specific edit-format constraints. |
| Pi | Node.js multi-provider agent | JSON mode exposes usage/cost events | `pi -p --mode json` | Builder-only evidence; no silent default model. |
| SmallCode | Node.js / local LM Studio | Local inference | `smallcode.js -P` | Experiment only; repeat-loop failure. |
| ATE | Python variation runner | Depends on configured endpoint | `run_variations.py` | Test infrastructure, now instrumented with structured telemetry (GH-94). |

### 3.1 Programmatic Tool Calling & Code-Mode Architecture (GH-94 / GH-101)

- **The "26 Tool" Hypothesis:** Based on PwC's research ([*The Bitter Lesson of Tool Calling*](https://arxiv.org/html/2608.06370v1)), when agent systems scale beyond $\approx 25$ distinct tools or require multi-step chained operations, programmatic script-mode execution (generating and running Python scripts via `utils/py/script_runner.py`) provides an architectural alternative to verbose JSON schema context flooding.
- **Production Qualification & Empirical Evidence (GH-101):** Programmatic tool mode (`--tool-mode programmatic`) is fully qualified and supported across both `consult.py` and `relay_drive.py` (defaulting off to `standard`). Verified via:
  1. *Test 1:* Architectural review and fail-closed threat-model scoping (PRD signed off).
  2. *Test 2:* `consult.py` dogfooding with throwaway worktree isolation, pre-created `.relay-scratch/`, and a 1,935-trial paired density benchmark committed in `TESTS-RESULTS/2026-08-20+GH-101/`.
  3. *Test 3:* Relay-drive integration with fail-closed sandbox checks (`sandbox-exec`/`bwrap`), PGID process-group lifecycle cleanup, and synthetic verification in `test/synthetic/gh101-relay-programmatic-stress.sh` (10/10 synthetic tests PASS).
- **Containment Invariant:** Programmatic execution in `utils/py/script_runner.py` requires process-group isolation (`setsid` + `SIGTERM`/`SIGKILL` cleanup), AST serialization normalization, and OS-level write sandboxing (`sandbox-exec`/`bwrap`) when `--containment-root` is provided (verified by `test/synthetic/gh94-containment-invariants.sh` and `test/synthetic/gh101-relay-programmatic-stress.sh`).

### 3.2 Automated Triage Evaluation: Local Gemma 4 in ATE (GH-94 / GH-141)

Local Gemma 4 (`google/gemma-4-31b-qat` via LM Studio) was evaluated as the automated triage judge in `utils/ate/scripts/run_variations.py` across two multi-hour campaigns: the 438-iteration GH-94 campaign and the 143-iteration GH-141 1-hour soak campaign (`TESTS-RESULTS/2026-08-22+GH-141/`). It performed reliably with zero JSON schema failures and 100% parseable structured triage classifications. Because `run_variations.py` is an experimental testing script rather than a core XYZ runtime shim, this evaluation qualifies Gemma 4 specifically for offline test triage ($0 operational token cost) rather than production coding or relay turn execution.

### 3.3 DeepSeek Harness (dsh) & DeepSeek V4 Pro (GH-148 / GH-156)

DeepSeek Harness (`dsh`) driving OpenRouter `deepseek/deepseek-v4-pro` in headless profile mode (`--profile headless --patch <overlay.cordis.yml>`) was evaluated across 4 real repository issues in isolated full-clone environments (GH-564):
1. **GH-142:** Fixed `compile_issue.py` missing `import sys` and error exit code propagation (11/11 tests PASS).
2. **GH-68:** Realigned `HARNESS-MODELS-REGISTRY.md` Table 1 schema.
3. **GH-65:** Modernized `test/` artifacts with portable 3-tier SHA-256 hashing.
4. **GH-156:** Added clean `--help` / `-h` top-level usage handling across all 7 Python turn twins (`utils/py/agy-turn.py`, `codex-turn.py`, `claude-turn.py`, `aider-turn.py`, `pi-turn.py`, `commandcode-turn.py`, `deepseek-turn.py`) in ~110s with 14/14 regression tests passing.

DeepSeek V4 Pro demonstrated 100% success across all 4 tasks with zero human intervention, 15–40s wall clock latency on focused edits, and clean minimal diffs. Promoted to **Grade A** (Production-Ready Autonomous Headless Builder).

### 3.4 Direct DeepSeek Review Engine (`review-xyz` / GH-165)

DeepSeek (`deepseek/deepseek-chat` / DeepSeek-V3 via direct OpenRouter engine in `utils/py/review_xyz.py`) was evaluated on complex systems architecture and governance topology synthesis for GH-165. It delivered high-rigor architectural analysis, formalizing the repository's post-merge lifecycles into a 2-workflow finite state machine (Mutation/Write path vs Verification/Read path) and designing an AST-based static regression test (`test/gh165-governance-canonical-paths-guard.py`) to prevent parallel script sprawl. Output was 100% structured, actionable, and completed in ~25s with zero hallucinations. Rated **Grade A-** (Production-Ready Systems Architecture & Governance Reviewer).

## 4. Promotion and re-evaluation rules

1. Create a dedicated tracking issue and isolated full-clone evaluation per the GH-17 SOP.
2. Record the exact harness version, provider endpoint, model slug, flags, task shape, run artifact,
   and gate result. A model rename or provider change starts a new evidence trail.
3. Promote to **A** only after three reviewable, end-to-end successes meet the rubric above. Open PRs,
   self-reported results without retained evidence, or a policy designation are not an A promotion.
4. Any B/C entry must name the mechanism and its safe operating limit. A regression, provider change,
   or harness upgrade reopens the evaluation.

## 5. Running changelog

| Date | Target / subject | Action | Evidence-based result |
|---|---|---|---|
| **2026-08-22** | OpenRouter / `review-xyz` + `deepseek/deepseek-chat` | Graded **Production-Ready Reviewer (A-)** | Evaluated on live GH-165 governance trace and lifecycle architecture review. Formulated unified 2-workflow state machine and designed AST static regression guard preventing parallel governance script sprawl. Zero hallucinations; 100% structured actionable output with ~25s latency. |
| **2026-08-22** | Aider + OpenRouter + `stealth/ox-alpha`, **reviewer role** | Added **C** | First use of this route, driven via `relay-drive.sh --review-once`, `ALLOW_PATHS=""`, worktree isolation ON, against `skills/4-occasional/ci-doctor/benchmark-runners.sh` (GH-161, PR #162). **R1: Blocked, correctly.** The turn-taker's `--artifact-file` seeding hadn't landed in the reviewer's context yet; the model declared `swept file: no` and refused to fabricate `[Pass]` findings against code it hadn't read — the honest failure mode, not a hallucination. **R2 (re-run after the artifact was seeded): the strongest first-attempt content seen from a new route.** Full 162-line static read, `swept file: yes`, verdict *Changes requested* with 2 `[Blocker]`, 4 `[Should]`, 5 `[Nit]`, 5 cited `[Pass]`. **Every finding verified true** against the real file before the operator acted: a `sed`-vs-literal mismatch that could silently commit a byte-identical no-op benchmark (undermining the tool's entire premise — GH-161's own header claims this exact failure mode impossible), and an unfiltered `gh run list --branch` pickup that could grab a wrong (push-triggered fast-lane, or cancelled) run instead of the dispatched one. Both confirmed by direct code inspection plus a targeted smoke test reproducing the reviewer's exact repro case (`runs-on: [self-hosted, linux]`) before fixing. Zero hallucinated findings; zero uncited Passes. **Delivery — mixed, root cause identified, not a model defect.** R1→R2 required a manual re-seed (environment/tooling gap). The R3 re-sweep (verifying the Producer's fixes) **timed out at the 900s wall-clock cap** (`aider-turn` exit 7) — but the turn's own log shows the model generated a full, well-formed second review in one clean LLM call (8.4k sent / 29k received, no retries) before the kill. Root cause: `aider-turn` ran `openrouter/stealth/ox-alpha` under Aider's default `whole` edit format (not in Aider's `model-settings.yml`), and the model wrote its response in diff-style (`+`-prefixed) lines, which `whole` format cannot parse as a file replacement — no error, no reflection, the turn simply idled with a correct response already sitting unused in the log until the wall-clock kill. This is the pre-existing, already-documented GH-118 edit-format quirk (see `skills/4-occasional/open-router/SKILL.md` and `relay-automation/README.md`, now updated with this model), not a reasoning or reliability failure of the model itself — the fix is `AIDER_FLAGS=--edit-format diff`, applied proactively for any new/unlisted OpenRouter model going forward. **Net: content quality is the strongest first-attempt showing of any route in this registry (2 real Blockers, zero hallucination, zero uncited Passes, twice); the one incomplete turn was a known, fixed harness-configuration gap, not the model.** Fixes verified independently (`bash -n`, `shellcheck -S error`, targeted smoke tests) rather than by the stalled R3 turn. **R3 re-run with `AIDER_FLAGS=--edit-format diff` applied: a second, different delivery failure.** Edit format was no longer the blocker, but the model then attempted an off-lane edit (outside the reviewer's `ALLOW_PATHS=""` scope) — `relay-turn-lib.sh`'s containment correctly discarded it and failed the turn (exit 6). Safety boundary held; nothing was lost or corrupted. **Closing the loop here** (operator-set boundary, no further root-causing): two independent delivery failures across three turns (timeout, then a containment violation) against one clean, high-quality review (R2) is not yet a route to trust unattended. Grade holds at **C** — real intelligence, unproven delivery, now on its second distinct failure mode rather than a resolved one. Verification of PR #162's actual code fixes stands independently of this stalled automated loop and does not depend on it closing. [#161](https://github.com/HiQS-Labs/XYZ-forge/issues/161), [#162](https://github.com/HiQS-Labs/XYZ-forge/pull/162); relay `relay-system/2026-08-22/ci-doctor-qa-gh-161-pr-162.md`. |
| **2026-08-22** | DeepSeek Harness (`dsh`) + `deepseek/deepseek-v4-pro` | Promoted to **Production-Ready (A)** | Evaluated across 4 real repository issues in isolated full clones: GH-142 (exit code propagation), GH-68 (markdown schema alignment), GH-65 (portable artifact hashing), and GH-156 (turn shims `--help`/`-h` usage across all 7 shims). Zero human intervention; clean scoped diffs; verified against 11/11 `gh148-deepseek-turn` and 14/14 `gh156-turn-shims-help` regression suites; PR #150 merged into `development`, PR #157 opened. |
| **2026-08-22** | ATE 1-Hour Fuzz Campaign (GH-141 soak) | Policy & benchmark baseline recorded | Executed 60.0-minute automated testing campaign across all 7 turn shims with local Gemma 4 31B triage on LM Studio. Completed 143 full execution-and-classification cycles with zero crashes, hangs, or memory leaks; telemetry receipts archived to `TESTS-RESULTS/2026-08-22+GH-141/error_log.jsonl`. |
| **2026-08-20** | Aider + OpenRouter + Qwen 3.8-Max, **reviewer role — 2nd reported usage** | **C confirmed, not promoted** | Second review turn on this route, against CODE this time (the 1,944-line GH-111 + GH-108 diff) rather than a plan doc. `--review-once`, `ALLOW_PATHS=""`, worktree isolation ON, 13m 44s. **Content: the strongest signal-to-noise yet.** Verdict *Changes requested* with 0 Blockers, 2 `[Should]`, 3 `[Nit]`, 16 cited `[Pass]`, and a declared `swept file: yes`. The operator reproduced every finding before acting: both `[Should]`s were live regex false positives that refused a correctly scored ROADMAP entry, and one `[Nit]` was under-graded — `baseline_source` was mutable, letting a `backfilled` baseline be quietly relabelled `observed`, which is a correctness gap in the metric and shipped as migration 005. **Zero hallucinated findings; zero uncited Passes.** **Delivery: failed identically to usage 1** — no relay-file append, GH-251 salvage recovered the review from the transcript. The salvage output was *usable* this time, which is new, but native delivery now stands at 1 of 3 turns. **Net: the grade holds at C for exactly the reason the registry already states — one good turn is not evidence the seam is fixed, and two good turns out of three still means a human reads every one.** [#111](https://github.com/HiQS-Labs/XYZ-forge/issues/111), [#108](https://github.com/HiQS-Labs/XYZ-forge/issues/108); relay `relay-system/2026-08-20/gh111-gh108-qa.md`. |
| **2026-08-20** | Programmatic Tool Execution (`script_runner.py`, GH-101) | Promoted to **Production-Ready (A)** | Completed 3-stage qualification ladder: Test 1 architectural fail-closed scoping; Test 2 `consult.py` throwaway worktree isolation with 1,935-trial paired density benchmark (`TESTS-RESULTS/2026-08-20+GH-101/`); Test 3 `relay_drive.py` / `relay-turn-lib.sh` integration with fail-closed sandbox verification, `.relay-scratch/` isolation, PGID cleanup, and synthetic stress verification (`test/synthetic/gh101-relay-programmatic-stress.sh`, 10/10 synthetic fuzz pass). |
| **2026-08-20** | Aider + OpenRouter + Qwen 3.8-Max, **reviewer role** | Added **C** | Both halves recorded deliberately, because they point opposite ways. **Positive — the review content was excellent, arguably the best of the day across three harnesses.** One turn against a plan doc produced seven blocking findings, each citing file and line, and **every one verified true against the live schema before acceptance**: SQLite cannot ALTER a CHECK constraint in place (the migration as drafted was unimplementable); an existing `UNIQUE (release_id, issue_ref_id)` made the drafted state machine impossible; an entire table the plan ignored (`manifest_state_events`, with its own old-vocabulary CHECKs, append-only triggers, and a `NOT NULL` reason column that the proposed `manifest ship` verb had no value for); and a backfill that named `releases.created_at`, **a column that does not exist**. It also returned explicit verdicts on all five of the plan's open questions. Zero false positives. **Negative — the seam failed on the very next turn, twice.** The model produced no findings, instead looping on its own output format; GH-251 salvage then appended ~1,200 lines of chain-of-thought into the relay file as review content. `ALLOW_PATHS=""` containment held and the reviewed artifact was untouched. Lane abandoned by operator instruction after one retry; verification rerouted. **Net: use this route for advisory review only with a human reading every turn — the intelligence is real, the delivery is not.** [#111](https://github.com/HiQS-Labs/XYZ-forge/issues/111); relay `relay-system/2026-08-20/gh111-dialed-in-qa.md`. |
| **2026-08-20** | Programmatic Tool Calling (GH-94) | Policy & benchmark baseline recorded | Integrated `utils/py/script_runner.py` with PGID timeout containment and macOS seatbelt sandboxing; instrumented `utils/ate/scripts/run_variations.py` with structured telemetry (schema 1.0); completed 438-iteration harness stability campaign under local Gemma triage (retained in `TESTS-RESULTS/2026-08-20+GH-94/`); verified synthetic suites `gh94-script-serialization.sh` and `gh94-containment-invariants.sh` (7/7 PASS). |
| **2026-08-18** | Command Code + Laguna S 2.1 Free | Added **N/A** | The provider lists this route as free while capacity lasts. One real worktree-isolated review-only relay had no output or worktree progress and was killed at its 300 s cap (`timeout-idle-no-progress`); containment handed the token back. This is insufficient evidence for C but does not qualify any safe relay role. [#48](https://github.com/HiQS-Labs/XYZ-forge/issues/48), [#49](https://github.com/HiQS-Labs/XYZ-forge/issues/49), [PR #44](https://github.com/HiQS-Labs/XYZ-forge/pull/44). |
| **2026-08-18** | Command Code + Muse Spark 1.2 Contributor | Added **B** | Two bounded build attempts and a real worktree-isolated relay review are recorded. The first build produced no code; the second produced the initial adapter but reached its turn cap. The live review found two real containment gaps, fixed by Codex with focused regressions; the full gate reached 215/216 before a separately repaired generated-dashboard drift. Keep the route B pending PR #44 review/integration and more independent successful runs. [#41](https://github.com/HiQS-Labs/XYZ-forge/issues/41), [#42](https://github.com/HiQS-Labs/XYZ-forge/issues/42), [PR #44](https://github.com/HiQS-Labs/XYZ-forge/pull/44). |
| **2026-08-16** | Registry audit | Refined | Reconciled the legacy Swarm checkout and both repositories’ issues/PR state. Split policy lanes from grades; Aider is builder-only with explicit-format constraints; Pi is builder-only; SmallCode remains C. |
| **2026-08-16** | Command Code + Qwen 3.8-Max | Regraded **A → B** | Three successful builds are documented, but PRs #19–#21 remain open; this does not yet satisfy the registry’s final-state/review evidence requirement. |
| **2026-08-16** | Command Code + Qwen 3.7-Flash | B retained; evidence expanded | The registry now records three autonomous builder runs plus the SOP review. AEGIS #58 reports a 7-file build with 1,940 tests and CI green; AEGIS #60 reports a 30+-file refactor with 1,915 Jest tests and 116 Node subtests green; rebalanceOS #16 reports lint, formatting, mypy, and test suites green after supervisor remediation of three subtle defects. The two linked PRs are open, so the route remains B pending final review/integration rather than A. [#58](https://github.com/HiQS-Labs/AEGIS-Sleuth-Slackbot/issues/58#issuecomment-5310915230), [#60](https://github.com/HiQS-Labs/AEGIS-Sleuth-Slackbot/issues/60#issuecomment-5311414037), [#16](https://github.com/HiQS-Labs/rebalanceOS/issues/16#issuecomment-5311691591) |
| **2026-07-23** | Aider + Qwen 3.8-Max | Conditional builder route recorded | Production-scale evidence attributed the major failure to Aider’s unlisted-model `whole` format; `--edit-format diff` restored substantive edits, while timeout sensitivity remained. [#280](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/280) |
| **2026-07-23–24** | Pi | Builder route recorded | Real isolated end-to-end turns were recorded via OpenRouter and direct Alibaba; later routing work did not qualify Pi as a reviewer. [#295](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/295), [#414](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/414) |
| **2026-08-12–13** | SmallCode + Qwen 2.5 Coder 32B | Retained **C** | Four-run experiment made a real fix but repeatedly entered tool-call/read loops; unattended use is unsafe. [#522](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/522) |

## 6. Resources & Canonical References

External research, standards, model platforms, and tooling relevant to operating, benchmarking, and debugging the harnesses above. Listed for reference and technical authority — not graded lanes; an entry here is a pointer and canonical citation.

| Category | Resource / Specification | Canonical Link | Relevance & Architectural Context |
|---|---|---|---|
| **Foundational AI Research** | *The Bitter Lesson of Tool Calling* (PwC Research) | [arXiv:2608.06370](https://arxiv.org/html/2608.06370v1) | Core motivation for programmatic code-mode execution (`script_runner.py`) over context-heavy JSON schemas at scale ($\ge 25$ tools). |
| **Foundational AI Research** | *The Bitter Lesson* (Rich Sutton, 2019) | [Incomplete Ideas](http://www.incompleteideas.net/IncIdeas/BitterLesson.html) | Foundational essay on general methods leveraging computation and search over human-engineered heuristics. |
| **Benchmarks** | SWE-bench (Princeton / SWE-bench Verified) | [swebench.com](https://www.swebench.com/) | Primary benchmark for evaluating end-to-end multi-agent software engineering and bug resolution. |
| **Agent Protocols** | Model Context Protocol (MCP Specification) | [modelcontextprotocol.io](https://modelcontextprotocol.io/) | Open standard for multi-agent tool, resource, and context interchange. |
| **Model Platforms** | OpenRouter Model Registry & Pricing | [openrouter.ai/models](https://openrouter.ai/models) | Canonical multi-model gateway pricing, throughput, and context-window specifications. |
| **Model Platforms** | DeepSeek Platform & API Docs | [api-docs.deepseek.com](https://api-docs.deepseek.com/) | Official API reference for DeepSeek V3 / R1 / V4 architectures and reasoning configurations. |
| **Model Platforms** | Alibaba Cloud Model Studio (Qwen Catalog) | [alibabacloud.com/help](https://www.alibabacloud.com/help/en/model-studio/) | Enterprise platform and documentation for Qwen 3.8-Max, 3.7-Flash, and coder models. |
| **Core Architecture** | Git Worktree SCM Reference | [git-scm.com/docs/git-worktree](https://git-scm.com/docs/git-worktree) | Official git reference for worktree semantics, shared `.git` objects, and isolation boundaries (GH-564). |
| **Core Architecture** | SQLite Foreign Key & ACID Invariants | [sqlite.org/foreignkeys](https://www.sqlite.org/foreignkeys.html) | Authoritative reference for transactional guarantees backing the `releases.db` ledger. |
| **Observability & Debugging** | Agent-Devtools | [GitHub Repo](https://github.com/Jacopos311/Agent-Devtools) | Local-first visual replay, behavior diff, and prompt/context debugger for AI agents. |
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
# Git Worktree and Full-Clone Safety Guide for Agents

Author: Noel Saw (@noelsaw1)  
License: See [`LICENSE`](LICENSE) and [`LICENSE-COMMERCIAL.md`](LICENSE-COMMERCIAL.md)  
Copyright 2026 Neochrome, Inc.  

> **Purpose:** Prevent destructive checkout and repository-state failures in agent-driven Git workflows.
> **Scope:** Shell scripts, CI pipelines, and agent workflows that create, use, verify, move, or
> remove linked worktrees and full-clone folders.

> **Safety and warranty:** XYZ Forge is provided **“AS IS,” without warranty**, under the applicable
> license. Coding models may choose commands through their own runtimes and safety controls, outside
> the intended harness workflow. These mitigations cannot guarantee model behavior or data integrity;
> maintain tested, independent backups and follow industry-standard backup and recovery practices.

---

## Table of contents

- [Safety model: linked worktrees and full clones](#safety-model-linked-worktrees-and-full-clones)
- [1. The `rm -rf` worktree-path trap](#1-the-rm--rf-worktree-path-trap)
- [2. Scripting `git worktree add` without failure handling](#2-scripting-git-worktree-add-without-failure-handling)
- [3. Trap cleanup with relative or unvalidated paths](#3-trap-cleanup-with-relative-or-unvalidated-paths)
- [4. Moving worktree directories outside Git](#4-moving-worktree-directories-outside-git)
- [5. Assuming a shared branch is free for checkout](#5-assuming-a-shared-branch-is-free-for-checkout)
- [6. Garbage collection while worktrees are active](#6-garbage-collection-while-worktrees-are-active)
- [7. Deleting a clone's `.git` or full-clone folder](#7-deleting-a-clones-git-or-full-clone-folder)
- [8. Using fragile relative paths between checkouts](#8-using-fragile-relative-paths-between-checkouts)
- [9. What branch deletion actually protects](#9-what-branch-deletion-actually-protects)
- [10. `git stash` is global within a worktree family](#10-git-stash-is-global-within-a-worktree-family)
- [11. Selective `.git` corruption and skeleton loss](#11-selective-git-corruption-and-skeleton-loss)
- [12. Run the full gate only in a disposable full clone](#12-run-the-full-gate-only-in-a-disposable-full-clone)
- [13. Other worktree and full-clone footguns](#13-other-worktree-and-full-clone-footguns)
- [14. Recovering a checkout that is already gone](#14-recovering-a-checkout-that-is-already-gone)
- [15. Audit trails that make the next incident solvable](#15-audit-trails-that-make-the-next-incident-solvable)
- [16. Containment: limiting blast radius outside Git](#16-containment-limiting-blast-radius-outside-git)
- [Golden rules](#golden-rules)
- [See also](#see-also)

## Safety model: linked worktrees and full clones

The boundary that matters is the Git directory, not the number of folders on disk. A linked
worktree gives a branch its own working files but shares repository state with its parent. A full
clone owns a separate Git directory, but it is safe to destroy only when it contains no unique work
and no linked worktrees depend on it.

| Checkout type | Git storage | What it isolates | Safe default use |
|---|---|---|---|
| Primary checkout of a full clone | `.git/` directory | Independent from other full clones; shared with its own linked worktrees | Valued repository state; do not treat as a test fixture |
| Linked worktree | `.git` file pointing into the parent clone | Working-tree files only | Editing and committing within a known branch lane |
| Disposable full clone | Independent `.git/` directory with no unique state or dependent worktrees | Working tree and Git config, refs, objects, hooks, and stashes | Mutation-heavy gates and destructive experiments |

“Disposable” is an operator-owned lifecycle, not a Git property. A normal clone becomes valued as
soon as it holds an unpushed commit, stash, reflog-only recovery object, local configuration, or a
linked worktree that another process still uses.

---

## 1. The `rm -rf` worktree-path trap

**Anti-pattern:** Deleting a worktree by just removing its directory.

```bash
# WRONG — leaves stale metadata in .git/worktrees/
rm -rf ../feature-branch

# Also WRONG — git still thinks the worktree exists
git worktree remove ../feature-branch  # fails: "not a working tree"
```

**Why it's dangerous:** Git maintains metadata in `.git/worktrees/<name>/` and in a `.git` file inside the worktree. If you `rm -rf` the directory, you get:
- Orphaned metadata polluting your repo
- The branch may still be checked out according to git, blocking operations
- `.git/worktrees/<name>/index` can grow large and never gets cleaned

**Correct approach:**
```bash
# Always use git worktree remove
git worktree remove ../feature-branch

# If the directory is already gone, let git reconcile its own metadata —
# don't hand-delete .git/worktrees/<name> yourself:
git worktree prune

# If the worktree still exists but was moved/relinked and git can't find it,
# `repair` (Git 2.29+) is the documented fix, not manual surgery on .git/worktrees/:
git worktree repair ../feature-branch
```
Manual `rm -rf .git/worktrees/<name>` is a last resort for a clearly corrupt admin
stub that `prune`/`repair` won't touch — not the normal cleanup path.

---

## 2. Scripting `git worktree add` without failure handling

**Anti-pattern:** Assuming `git worktree add` succeeds.

```bash
git worktree add ../hotfix hotfix-branch
cd ../hotfix || exit 1
# ... do work ...
```

**Why it's dangerous:**
- Branch might already be checked out in another worktree (git refuses with "already checked out")
- Path might already exist
- Disk might be full
- Detached HEAD might not be what you expected

**Defensive version:**
```bash
if ! git worktree add ../hotfix hotfix-branch 2>/dev/null; then
    echo "Worktree creation failed — branch may already be checked out or path exists" >&2
    exit 1
fi
```

---

## 3. Trap cleanup with relative or unvalidated paths

**Anti-pattern:** The sibling of the `mktemp` bug — cleaning worktrees in traps.

```bash
WORKTREE="../feature-$(date +%s)"
git worktree add "$WORKTREE" feature-branch
trap 'rm -rf "$WORKTREE"' EXIT
```

**Why it's dangerous:**
- If `git worktree add` fails and `WORKTREE` is empty/malformed, a quoted `rm -rf "$WORKTREE"` errors on an empty string (`rm: missing operand`) rather than silently targeting cwd — but an *unquoted* `rm -rf $WORKTREE` word-splits an empty value to zero arguments, which for GNU `rm` is also a no-op/error, NOT an implicit `.`. The real risk isn't a specific "resolves to cwd" mechanism at all: it's that an unvalidated variable in a destructive trap can hold anything (a partial path, a stray `*`, a value from a prior failed `cd`) by the time `EXIT` fires, and nothing between assignment and the trap firing re-checks it
- If the script `cd`s into the worktree, the relative path `../` now points somewhere else
- `rm -rf` leaves stale metadata in `.git/worktrees/`

**Defensive version:**
```bash
# NOTE: unlike mktemp, git worktree add does NOT expand "XXXX" into a random
# suffix — that string would be used verbatim as the path. Build the unique
# path yourself before calling git, and don't rely on parsing git's output
# (--quiet suppresses exactly the text a naive script would try to awk out of it).
WORKTREE="$(pwd)/../feature-$$-$(date +%s)"
git worktree add "$WORKTREE" feature-branch || { echo "Worktree creation failed" >&2; exit 1; }
WORKTREE="$(cd "$WORKTREE" && pwd -P)"  # canonicalize AFTER validation

cleanup() {
    # --force here is NOT the §13 anti-pattern: this worktree was just created by THIS script for a
    # throwaway purpose and is being torn down in its own exit trap, not force-removed out from under
    # someone else's uncommitted work. §13's warning is about scripts reaching for --force to silence
    # an error on a worktree they don't own/didn't create.
    git worktree remove --force "$WORKTREE" 2>/dev/null || true
    git worktree prune 2>/dev/null || true
}
trap cleanup EXIT
```

---

## 4. Moving worktree directories outside Git

**Anti-pattern:** Using `mv` to relocate a worktree.

```bash
mv ../feature-branch ../feature-branch-old
```

**Why it's dangerous:** The `.git` file inside the worktree contains an absolute or relative path back to the main repo. Moving it breaks that link. Git now can't find the worktree, and `git worktree remove` fails.

**Correct approach:**
```bash
# git worktree move shipped in Git 2.17.0 — use it instead of mv
git worktree move ../feature-branch ../feature-branch-renamed

# Pre-2.17: remove and re-add
git worktree remove ../feature-branch
git worktree add ../feature-branch-renamed feature-branch

# If a worktree (or the main worktree) was ALREADY moved outside git's
# knowledge — e.g. via `mv`, a backup restore, or a renamed parent dir — the
# documented fix is `repair` (Git 2.29+), not manual .git-file surgery:
git worktree repair ../feature-branch-renamed
```

---

## 5. Assuming a shared branch is free for checkout

**Anti-pattern:** `git worktree add` for a branch that's already checked out elsewhere.

```bash
# Script adds a worktree for "main" to run tests
git worktree add ../main-worktree main
```

**Why it's dangerous:** If any other worktree already has `main` checked out, this fails. This is especially problematic in CI or multi-session environments.

The occupancy rule applies within one worktree family. A separate full clone has independent refs
and may check out a branch with the same name, but the two branch refs can then diverge; matching
names do not make them shared state.

**Defensive version:**
```bash
# Use a unique branch name or detached HEAD
git worktree add --detach ../test-run-$$ main

# Or check first — parse --porcelain, not human-readable output. The plain
# `git worktree list` format is not a stable API and grep can false-match on
# pathnames that happen to contain "[main]"-like substrings.
if git worktree list --porcelain | grep -qx 'branch refs/heads/main'; then
    echo "main is already checked out in another worktree" >&2
    exit 1
fi
```

---

## 6. Garbage collection while worktrees are active

**Anti-pattern:** Running aggressive GC without considering worktrees.

```bash
git gc --aggressive --prune=now
```

**Why it's dangerous:**
- Worktrees share the same object database, and (with the exception of
  `refs/bisect`, `refs/worktree`, and `refs/rewritten`) the same refs — modern
  Git *is* worktree-aware and does scan all registered worktrees' refs/logs
  before pruning, so "gc can't see another worktree's refs" is not the
  mechanism
- The real documented risk is **concurrency**: `--prune=now` disables the
  normal grace-period safety margin, so if another process (a build in a
  linked worktree, a concurrent commit) creates an object that isn't
  referenced by a ref yet, `--prune=now` can delete it out from under that
  process — a race, not a worktree-visibility gap
- A secondary, worktree-specific risk: if a worktree directory was manually
  `rm -rf`'d without `git worktree prune`, its stale `.git/worktrees/<name>/`
  admin entry can leave git's bookkeeping out of sync with reality until
  pruned

The blast radius stops at the full-clone boundary. Another full clone has its own object database;
every linked worktree registered to the current clone does not.

**Defensive approach:**
```bash
# Always list worktrees before GC to understand what's shared
git worktree list

# Avoid --prune=now while any worktree might be mid-write (build, commit, checkout)
# Or avoid --prune=now entirely
git gc --auto  # conservative, safe
```

---

## 7. Deleting a clone's `.git` or full-clone folder

**Anti-pattern:** Treating a clone's `.git` directory—or the folder containing it—as disposable
before checking what depends on it and what exists only there.

```bash
# WRONG — destroys the database behind the current checkout and its linked worktrees
rm -rf .git
```

**Why it's dangerous:** A full clone is independent from *other clones*, not from its own linked
worktrees. Those worktrees point back to its Git directory. The clone may also hold local-only
branches, unpushed commits, stashes, reflog recovery objects, hooks, and configuration that a clean
working tree does not reveal.

**Real-world scenario:** You have three linked worktrees registered to one full clone. Someone
deletes the clone folder because its primary checkout looks idle. The linked folders remain on disk,
but their object database and refs are gone; even `git log` fails.

**Preflight a full-clone cleanup:**

```bash
CLONE_INPUT=/absolute/path/to/candidate-clone
[ -n "$CLONE_INPUT" ] || { echo "refusing: empty clone path" >&2; exit 2; }
CLONE="$(cd "$CLONE_INPUT" 2>/dev/null && pwd -P)" \
    || { echo "refusing: clone path does not resolve" >&2; exit 2; }
[ -d "$CLONE/.git" ] \
    || { echo "refusing: not a conventional full clone: $CLONE" >&2; exit 2; }

git -C "$CLONE" status --short
git -C "$CLONE" stash list
git -C "$CLONE" for-each-ref \
    --format='%(refname:short) %(upstream:short) %(upstream:track)' refs/heads
git -C "$CLONE" worktree list --porcelain
```

Stop if the output shows unique work or more than the primary checkout. Remove owned linked
worktrees with `git worktree remove`, then `git worktree prune`; never delete the parent clone out
from under them. For a standalone clone that is genuinely disposable, prefer a recoverable move to
trash over immediate recursive deletion. Automation must additionally prove that the resolved path
is a descendant of its dedicated task-clone root—not `$HOME`, a workspace root, or a path supplied
only through an unchecked variable.

---

## 8. Using fragile relative paths between checkouts

**Anti-pattern:**
```bash
cd ../feature-branch
# ... do stuff ...
../../main-repo/some-script.sh  # fragile relative path
```

**Why it's dangerous:** Worktrees and full clones can live anywhere. A relative path assumes a
directory layout that may not hold and may resolve to a different clone after one `cd`.

**Defensive approach:**
```bash
MAIN_REPO="$(git rev-parse --git-common-dir)"  # finds the shared .git
MAIN_ROOT="$(cd "$MAIN_REPO/.." && pwd)"        # parent of shared .git
```
Caveat: `"$MAIN_REPO/.."` assumes the standard "`.git` directory sits directly
under the repo root" layout. It breaks for repos using `--separate-git-dir`
or a bare common dir, where `.git` isn't a sibling of the working files. For
those layouts, don't derive the root by walking up from `--git-common-dir` —
resolve it explicitly (e.g. from `git worktree list --porcelain`, which
reports each worktree's actual path).

---

## 9. What branch deletion actually protects

**Corrected claim:** Git actually protects you here — both `git branch -d` *and* `git branch -D`
(force) refuse to delete a branch that's checked out in **any** worktree, main or linked. This was
verified empirically (Git 2.50.1): `git branch -D feature-branch` fails with
`error: cannot delete branch 'feature-branch' used by worktree at 'PATH'` (exit 1). There is no
"force-delete succeeds and leaves that worktree in detached HEAD" failure mode — that was this
doc's own error, not a real Git footgun.

```bash
git branch -d feature-branch  # fails if checked out elsewhere
git branch -D feature-branch  # ALSO fails — Git blocks this even with -D
```

**What's still worth guarding against:** the actual footgun is scripts that treat this failure as
fatal-and-unexpected instead of handling it, or that work around it by first force-removing the
occupying worktree (`git worktree remove --force`) to clear the way — which *does* discard that
worktree's uncommitted work. If a script needs to delete a branch, check occupancy first and fail
loud rather than reaching for `--force` on the worktree to unblock the branch deletion:

```bash
if git worktree list --porcelain | grep -qx "branch refs/heads/feature-branch"; then
    echo "Branch is checked out in a worktree — aborting deletion (do not --force the worktree to work around this)" >&2
    exit 1
fi
```

---

## 10. `git stash` is global within a worktree family

**Corrected claim:** Stashes are **shared** across all worktrees via the single ref `refs/stash` in
the main repo's shared ref store — `git-worktree`'s docs list `refs/bisect`, `refs/worktree`, and
`refs/rewritten` as the only per-worktree ref namespaces, and `refs/stash` is not among them. This
was verified empirically: a stash pushed in the main worktree shows up identically in
`git stash list` run from a linked worktree.

A separate full clone has a separate `refs/stash`. That isolation does not copy stashes between
clones or make either stash recoverable after its owning clone folder is removed.

```bash
# In worktree A
git stash push -m "WIP: half-done feature"

# In worktree B
git stash list  # shows the SAME stash — it is not worktree-local
git stash pop   # applies worktree A's stash onto worktree B's files — likely the WRONG tree
```

**Why it's actually dangerous:** because the stash is shared, popping it in the wrong worktree
applies changes meant for one branch/tree onto a different one — conflicts, or silent application
to unrelated files, and the stash is now consumed so worktree A can't get it back without digging
through the reflog (`git fsck --unreachable`, `git stash list` right after `pop` won't show it).

**Correct mental model:** Stashes are a single shared stack across the whole repo, indexed the same
way from every worktree. Use unmistakable `-m` messages, and run `git stash list` in the worktree
you're about to pop into (not the one you pushed from) to confirm which entry is `stash@{0}` before
popping.

---

## 11. Selective `.git` corruption and skeleton loss

**What actually happened here (2026-07-07):** this repo's main `.git` directory lost `HEAD`,
`objects/`, `refs/`, and `index`, while `hooks/`, `worktrees/`, and `config` survived intact. This
is **not** the "someone ran `rm -rf .git`" scenario in §7 above — that deletes everything uniformly.
This was a *partial* loss (consistent with a selective backup/restore gap), and none of the 10
anti-patterns above describe it or would have helped diagnose it.

**Detection — verify before trusting a repo:**
```bash
# A healthy repo has ALL of these. Any missing = don't trust git commands here yet.
for f in HEAD objects refs config; do
    [ -e ".git/$f" ] || echo "MISSING: .git/$f"
done
git fsck --no-progress 2>&1 | head -5   # first real integrity check once the above pass
```
Also check `.git/worktrees/*/gitdir` stubs for staleness — a stub with no valid path behind it (or
just a bare `commondir` file and nothing else) is metadata cruft from the same class of incident,
not a real linked worktree; `git worktree prune` clears it once the main repo is healthy again.

**Recovery — in order, verifying before each destructive-looking step:**
```bash
# 1. git init is DOCUMENTED SAFE to re-run on an existing repo: it only fills in
#    missing standard files (HEAD, objects/, refs/, description, info/exclude,
#    sample hooks) and does NOT overwrite an existing config, hooks, or any
#    working-tree file.
git init

# 2. Repopulate history from the remote — additive only, does not touch the
#    working tree or local branch refs.
git fetch origin

# 3. Before pointing any local ref at origin, or touching the working tree,
#    build an index from the candidate branch WITHOUT checkout (read-tree does
#    not write to the working tree) and diff it against what's on disk:
git read-tree origin/main
git status   # compare — do NOT `checkout -f` / `reset --hard` / `clean` yet

# 4. Only once you've confirmed the working tree matches (or you've decided
#    what to do about genuine local divergence), point the branch ref at the
#    remote — this only writes a ref, still doesn't touch the working tree:
git update-ref refs/heads/main origin/main

# 5. Restore any tracked files that are genuinely missing/corrupted on disk
#    (confirmed absent or differing from origin, not local WIP) from the
#    remote's tree — scoped to just those paths, not a blanket checkout:
git checkout origin/main -- path/to/missing-file
```
The critical discipline: steps 1–3 are provably non-destructive to the working tree (`init` fills
gaps only, `fetch` writes only to `.git/objects` and remote-tracking refs, `read-tree` populates the
index without touching files). Do not reach for `checkout -f`, `reset --hard`, or `clean` until
you've diffed and know exactly what you'd be overwriting — those commands assume the working tree is
disposable, which after a partial-corruption incident it specifically is not.

---

## 12. Run the full gate only in a disposable full clone

**Rule:** Run `validate.sh` and full `ci-local.sh` only in a separate full clone whose loss will not
damage active work. A linked worktree exposes its parent clone; a valued full clone exposes itself.
Neither is the right containment boundary for a fixture-heavy suite.

**Anti-patterns:**

```bash
# WRONG: the linked worktree shares the parent clone's .git.
git worktree add ../repo-feature -b feature origin/development
(cd ../repo-feature && bash validate.sh)

# ALSO WRONG: this is a full clone, but it holds state the operator cares about.
(cd /path/to/primary-clone && bash validate.sh)
```

### Why the boundary matters

A linked worktree shares the parent clone's config, refs, objects, hooks, and most reflogs. A suite
that escapes a fixture therefore writes into the parent repository. A separate full clone stops
that cross-clone blast radius, but the suite can still corrupt the clone in which it runs; the word
*disposable* is load-bearing.

On 2026-08-19, a gate run from a linked worktree escaped its fixture and changed the parent clone:

- `core.bare` became `true`
- `remote.origin.url` pointed at a temporary bare repository that was later deleted
- every `refs/remotes/origin/*` ref was deleted
- local `development` and `main` moved to fixture commits
- fixture files appeared in the working tree

The objects survived, but the run was no longer attributable to the clone that started it. This is
the GH-564/GH-567 failure class: an empty or invalid fixture path reaches the caller's repository.
A suite can also behave differently in a linked worktree because `.git` is a file there, not a
directory. A linked-worktree run is both unsafe and an invalid measurement.

### What XYZ enforces now

- [`validate.sh`](validate.sh) and [`ci-local.sh`](ci-local.sh) refuse linked worktrees with exit 2
  before the suite starts. They compare the checkout's absolute Git directory with its resolved
  common directory, checking both the script root and invocation directory where applicable.
- `XYZ_ALLOW_WORKTREE_GATE=1` is an announced override. It changes the refusal, not the isolation;
  use it only when the entire parent clone and every linked worktree registered to it are disposable.
- [`test/gh35-test-tiers.sh`](test/gh35-test-tiers.sh) pins the refusal, override, absolute-path
  invocation, and normal-full-clone control.
- The full gate captures clone identity before the suite and asserts it afterward. Drift in
  `core.bare`, `origin`, local user identity, or `HEAD` fails the run. This detects corruption after
  it happens; it does not protect a valued clone from the mutation.

### What the clone boundary does not cover

A disposable clone contains everything the suite does *to a repository*. It does not contain what the
suite does to the machine, and the identity invariant above only watches Git state.

Observed 2026-08-30: running the full gate from a throwaway clone repointed six real symlinks under
`~/.gemini/**/skills/` at that clone, because a skill-install suite installs from whatever checkout it
is running in. The gate passed and reported nothing unusual — correctly, since no Git state drifted.
Step 5 below then says to discard the clone, which is exactly what turns those symlinks into dangling
links pointing at a deleted temporary directory. The damage lands outside Git, outside the clone, and
after a green run.

This is §16's point applied to the gate itself: a suite that writes to `$HOME` is not contained by
choosing where its `.git` lives. Two practical consequences:

- Before deleting a gate clone, check whether the run installed anything pointing back at it:
  `find ~ -maxdepth 6 -type l -lname '*<clone-path-fragment>*' 2>/dev/null`.
- Prefer running such suites in the checkout that will still exist afterwards, or give the gate clone a
  scratch `HOME` so home-directory writes land somewhere disposable too.

### Correct workflow

1. Edit and commit in the assigned worktree or task clone.
2. Bring that exact commit into a dedicated full clone; do not substitute a similarly named branch.
3. Confirm the gate clone has a real `.git/` directory, a clean working tree, and no registered
   linked worktrees beyond its primary checkout.
4. Run the gate from that clone. -> expect the linked-worktree guard to stay silent and the final
   clone-identity invariant to pass.
5. If clone identity changes, discard the gate result and the disposable clone, create a fresh full
   clone, and rerun at the same concurrency. Repairing the damaged clone does not rehabilitate the
   prior result.

Tracked as [GH-45](https://github.com/HiQS-Labs/XYZ-forge/issues/45), with the broader fixture
containment and identity work tracked by GH-564/GH-567.

---

## 13. Other worktree and full-clone footguns

- **Untracked or modified files block `git worktree remove`.** It refuses if the worktree has any
  uncommitted changes; `--force` is required to proceed — and `--force` silently discards those
  changes. Never default a script to `--force` as a way to "fix" a remove that failed.
- **`git worktree move` does not support worktrees containing submodules** — the relative links
  back to `.git/modules/` break. Don't script a blind `move` without checking `.gitmodules` first.
- **`--force` on `add` / `move` / `remove` overrides the exact safeguards this guide teaches** (branch
  occupancy, dirty-worktree protection, path collisions). Treat any script that reaches for `-f`/`--force`
  to silence a worktree error as a signal to stop and understand *why* git refused, not a shortcut.
- **Lock worktrees on removable/unstable storage.** `git worktree lock <path>` prevents `git worktree
  prune` (including the prune that `git gc` can trigger) from reaping a worktree's metadata just
  because its directory is temporarily unreachable (unmounted drive, network share).
- **Prefer `git worktree list --porcelain` over the human-readable format** in any script. The
  plain-text table is not a stable API; porcelain output is machine-parseable and won't false-match
  on branch/path substrings the way a `grep` over the table can.
- **A clean clone can still hold unique state.** `git status --short` does not show unpushed branch
  tips, stashes, reflog-only objects, hooks, or local configuration. Check them before cleanup (§7).
- **Do not move a full-clone folder while it owns linked worktrees.** Their administrative files
  point back to the clone's common directory. If a clone was already moved, use `git worktree
  repair` with the real checkout paths; do not hand-edit `.git` files.
- **Same branch name does not mean same branch state across full clones.** Verify the exact commit
  SHA before grading, publishing, or deleting either clone.

---

## 14. Recovering a checkout that is already gone

Sections 1–13 prevent damage. This section assumes prevention failed: a linked worktree or a full-clone
folder is missing, and the first job is to recover the bytes and establish a timeline. Work in this
order — the cheapest, least destructive sources first.

**Do not re-run the agent, re-clone into the same path, or `git init` the parent directory yet.** Each
of those writes to the volume and can overwrite the free blocks a recovery would have used.

### 14.1 Local APFS snapshots and Time Machine

macOS can keep automatic local APFS snapshots even with no backup disk attached, which makes this the
highest-yield first check. It is not guaranteed: `tmutil localsnapshot` only covers APFS volumes
included in a configured Time Machine backup, so a machine that has never been configured may have
none. Check first, and never treat a snapshot as a precondition that must exist.

```bash
# What point-in-time views exist on the boot volume?
tmutil listlocalsnapshots /

# Mount one read-only and copy files out. NOTE: the tool is mount_apfs -s,
# not "mount_apfs_snapshot" — the latter does not exist.
mkdir -p /tmp/snap
sudo mount_apfs -s com.apple.TimeMachine.2026-08-27-073000 / /tmp/snap
ls "/tmp/snap/Users/$USER/Documents/GH Repos/"

# When finished
sudo umount /tmp/snap
```

Copy out of the snapshot; never work inside it. If an external Time Machine disk is attached, browse it
in Finder instead — same data, friendlier interface.

### 14.2 Trash, then any sync provider

`rm -rf` does not use the Trash, but a Finder-driven or script-driven move might have. Check `~/.Trash`
before assuming permanent loss. If the path lived under Dropbox, iCloud Drive, Google Drive, or a NAS
sync root, check that provider's web UI — most keep deleted-file and version history well past the
local deletion.

### 14.3 Git can rebuild more than you think

A destroyed *working tree* need not mean destroyed *history* — but only if the objects survive
somewhere, and each source has a real limit. A **remote** carries only what was pushed and is still
reachable there. A **linked worktree is not an independent object store**: it helps only if the parent
clone's common Git directory survived, which is exactly what §7 warns you can destroy. A **sibling full
clone** is independent, and is the strongest of the three. Before treating a loss as total:

```bash
# Does the remote still carry the work?
git ls-remote origin 'refs/heads/*'

# Does a sibling full clone or the parent of a linked worktree still hold the objects?
git --git-dir=/path/to/other/clone/.git log --oneline --all | head

# Unreferenced commits in a surviving clone — the reflog MAY outlive branch deletion.
# Retention is finite (gc.reflogExpire, default 90d; 30d unreachable) and `git gc`
# can prune it, so run this early rather than after more repo activity.
git --git-dir=/path/to/other/clone/.git reflog --date=iso | head -50
git --git-dir=/path/to/other/clone/.git fsck --lost-found
```

This is the payoff for §7 and §12: if the destroyed folder was a *disposable* full clone, recovery is a
fresh `git clone` and nothing was lost. The recovery cost of an incident is set by the discipline applied
before it.

### 14.4 This harness's two non-Git stores

Before concluding anything is unrecoverable, check the two places this harness keeps data that `git`
will never show you.

**`.tick/orphan-backups/` — the relay's pre-revert copies.** A driven turn reverts any edit outside its
allowlist, and since 2026-07-18 it copies the file's prior content out first rather than discarding it
(`relay-automation/relay-turn-lib.sh`). If a hand-edit was made in a clone while a turn was in flight
there, this is where it went:

```bash
ls -lt .tick/orphan-backups/ | head          # newest incident first
find .tick/orphan-backups -name '*<filename>*'
```

**Vendored `.xyz/` has no Git recovery at all.** It is gitignored (`.gitignore`), so nothing inside it
has a reflog, a stash, or an `fsck --lost-found` behind it — a destroyed relay thread or `.tick/` log
under `.xyz/` is simply gone. `xyz-sync.sh update` preserves a known list of runtime paths across the
rebuild, and anything not on that list is deleted unread. Snapshots (§14.1) are the only recovery path
for this directory, which is why §15.4's pre-run snapshot matters more here than anywhere else.

### 14.5 Correlate with shell history

```bash
grep -n -E 'rm -rf|git clean|git worktree remove|reset --hard|rsync.*--delete' ~/.zsh_history
```

Without `EXTENDED_HISTORY` (§15.1) these lines carry no timestamps, so you get sequence but not time.
Enable it now so the *next* incident has both.

### 14.6 Unified logging

macOS retains system log data for a limited window, so capture this early:

```bash
# Everything a given process did in the last few hours
log show --last 3h --predicate 'process == "node"' --info --style compact

# Narrow to a path fragment that appears in error messages
log show --last 3h --style compact | grep -i 'GH Repos'
```

Unified logging will not hand you "this command deleted this folder." It gives process names, restart and
crash events, and paths quoted in errors — enough to bound the window and identify the actor.

---

## 15. Audit trails that make the next incident solvable

§14 is only as good as the evidence that exists before the incident. All three of these are cheap and
worth enabling once.

### 15.1 Timestamped shell history

```zsh
# ~/.zshrc
setopt EXTENDED_HISTORY        # record start time and duration per command
setopt INC_APPEND_HISTORY      # write as commands run, not only at shell exit
setopt HIST_IGNORE_DUPS
```

`INC_APPEND_HISTORY` matters as much as the timestamps: without it, a shell killed mid-incident —
which is exactly what happens when an agent run goes wrong — never flushes its history to disk.

### 15.2 An agent action log

Have the harness, not the model, record every destructive intent before it executes. Log the resolved
absolute path, the operation, and the justification:

```python
import datetime, json, os, pathlib

LOG = pathlib.Path(os.environ.get("AGENT_ACTION_LOG", "~/agent-logs/actions.jsonl")).expanduser()

def log_action(action: str, **details):
    LOG.parent.mkdir(parents=True, exist_ok=True)
    entry = {"ts": datetime.datetime.now(datetime.timezone.utc).isoformat(),
             "action": action, **details}
    with LOG.open("a") as f:                     # append-only, one JSON object per line
        f.write(json.dumps(entry) + "\n")
        f.flush()
        os.fsync(f.fileno())                     # survive a hard kill
```

The `fsync` is the point. A buffered log loses precisely the last few entries — the ones describing the
operation that killed the process.

### 15.3 Filesystem-level events with `eslogger`

`eslogger` ships with macOS 13+ and reports Endpoint Security events directly. It requires root and Full
Disk Access for the invoking terminal, and it is verbose — treat it as a diagnostic you switch on while
hunting a specific problem, not a permanent daemon:

```bash
# Deletion-and-move audit. Subscribe ONLY to what the selector actually handles.
sudo eslogger unlink rename 2>/dev/null \
  | jq -c --arg re 'GH Repos|agent-workspaces' '
      [ .event.unlink.target.path,
        .event.rename.source.path,
        .event.rename.destination.new_path,
        .event.rename.destination.existing_file.path ]
      | map(select(. != null))
      | select(any(.[]; test($re)))' \
  >> ~/agent-logs/file-events.jsonl
```

Three things this deliberately gets right, because the obvious version gets them wrong:

- **Do not subscribe to an event you do not extract.** Adding `create` to the command line while the
  selector has no `.event.create` arm produces a log that looks complete and silently drops every
  creation. Either handle it or leave it unsubscribed.
- **A rename has two ends.** Filtering only on `.source.path` misses a move *into* a watched root.
  `rename` reports its destination as either `new_path` or an `existing_file` being clobbered,
  so check both.
- **This JSON is not a stable API.** Apple documents the Endpoint Security event schema as subject to
  change, so treat the field paths above as verified-at-time-of-writing and confirm against
  `eslogger --list-events` and a sample event on your OS version before relying on them.

This tells you the exact time, full path, and responsible process for every delete — the one source that
attributes a deletion to a process rather than inferring it. It cannot tell you which prompt caused it;
that is what §15.2 is for.

### 15.4 Snapshot before a destructive run

```bash
tmutil localsnapshot && echo "snapshot taken: $(date -u +%FT%TZ)"
```

Cheap (copy-on-write, seconds) and the single highest-value pre-flight for any mass refactor, migration,
or cleanup. Wire it into the harness ahead of destructive lanes rather than remembering it by hand.

Two limits to encode rather than assume. Snapshots are pruned automatically under disk pressure, so
they are a short-horizon undo buffer, never a backup. And the command fails on a machine with no
suitable Time Machine configuration — a harness preflight should **report** that it could not snapshot
and carry on, not treat snapshot support as universally available:

```bash
if tmutil localsnapshot 2>/dev/null | grep -q 'Created local snapshot'; then
  echo "pre-run snapshot: ok"
else
  echo "pre-run snapshot: UNAVAILABLE — proceeding without an undo buffer" >&2
fi
```

---

## 16. Containment: limiting blast radius outside Git

Git-level care (§1–§13) does not help when a command never reaches Git. These limits are what keep a
mistaken path from reaching valued data at all.

### 16.1 Give agents a dedicated root

**Anti-pattern:** letting an agent run with its working directory anywhere under `$HOME`, so a
mis-resolved relative path lands on `~/Documents` or `~/Desktop`.

Keep agent-writable work under one root, and require an explicit override to leave it:

```python
from pathlib import Path

SAFE_ROOTS = [
    Path.home() / "Documents" / "GH Repos",
    Path.home() / "agent-workspaces",
    Path.home() / "Documents" / "agent-workspaces",
    Path.home() / "marathon-clones",   # where /start-task, /jog and marathon flows put task clones
]  # this list IS skills/2-daily/merge-cleanup/scripts/scan_clones.py DEFAULT_SAFE_ROOTS (test-pinned, GH-534)
NEVER_DELETE = {Path.home(), Path.home() / "Documents", Path.home() / "Desktop", Path("/")}

def _within(child: Path, parent: Path) -> bool:
    """True only if child is STRICTLY inside parent. Python 3.8-compatible:
    Path.is_relative_to() was added in 3.9, and it also returns True for
    child == parent, which would authorize deleting the safe root itself."""
    if child == parent:
        return False
    try:
        child.relative_to(parent)
        return True
    except ValueError:
        return False

def assert_deletable(path: Path):
    p = path.resolve()                                   # resolve symlinks BEFORE comparing
    if p in {r.resolve() for r in NEVER_DELETE}:         # resolve BOTH sides, or the test misses
        raise RuntimeError(f"refusing to delete a protected root: {p}")
    if not any(_within(p, root.resolve()) for root in SAFE_ROOTS):
        raise RuntimeError(f"refusing to delete outside safe roots: {p}")
    log_action("file_delete", path=str(p))
```

Four things here are load-bearing, and three of them are defects this example had in an earlier draft:

- **Resolve before comparing.** Without it a path inside the safe root can still point outside it via a
  symlink — the same class of defect as §3's unvalidated trap paths.
- **Resolve both sides.** Comparing a resolved `p` against unresolved `NEVER_DELETE` members silently
  misses when `~` or any parent is itself a symlink.
- **Component-aware containment, not string prefixes.** `str.startswith` accepts
  `/Users/me/Documents-backup` as being inside `/Users/me/Documents`.
- **Reject `child == parent`.** `Path.is_relative_to` returns `True` for a path against itself, so the
  obvious one-liner authorizes `rm -rf ~/Documents/GH Repos` — deleting *every* repo — as "inside a safe
  root." `_within` rejects it explicitly. It also keeps the check working on Python 3.8, this repo's
  declared floor (`README.md:198`); `is_relative_to` needs 3.9+.

`resolve()` is non-strict by default, so it still returns a usable path when the leaf does not exist.

**What this check does not do — know the boundary before you rely on it.** `assert_deletable` validates
a path at one instant; the caller deletes at a later one. Anything able to change what a path points at
in between — retargeting a symlink inside a safe root, swapping a parent directory — redirects the
delete to somewhere the check already approved. That is a genuine time-of-check-to-time-of-use gap, and
it is not closable at this layer.

It is also outside what this guard is for. The threat model here is **a mistaken path, not a hostile
one**: an agent resolving `../..` one level too far, or interpolating an empty variable. Against that,
a one-instant check is sufficient and worth having. Against a local attacker deliberately racing your
process, it is not — and no amount of pre-validation makes it so. If that is your threat model, the
answer is §16.4's isolation or an `openat`-style handle-based delete, not a better string check.

### 16.2 Make critical directories refuse writes

```bash
chflags uchg ~/ImportantData          # set the immutable flag
chflags nouchg ~/ImportantData        # release it deliberately, for a known operation
```

`rm -rf` fails against `uchg` even as your own user, which turns a silent catastrophe into an error
message. It is not a security boundary — anyone able to run `chflags` can undo it — but it is an
effective guard against an unthinking command.

### 16.3 Wrap destructive commands, and prefer dry-run first

Put a wrapper earlier on `PATH` than the real binary so an unqualified `rm -rf` cannot run unattended:

```bash
#!/bin/zsh
# ~/bin/safe-rm — refuses ANY recursive delete without an explicit acknowledgement
set -euo pipefail

ack=0 recursive=0 end_of_opts=0
for arg in "$@"; do
  [[ "$arg" == "--i-mean-it" ]] && { ack=1; continue; }
  (( end_of_opts )) && continue
  [[ "$arg" == "--" ]] && { end_of_opts=1; continue; }
  case "$arg" in
    --recursive) recursive=1 ;;               # GNU spelling; macOS /bin/rm rejects it, but flag it anyway
    --*) ;;                                   # any other long option: not recursive
    -*[rR]*) recursive=1 ;;                   # -r, -R, -rf, -fr, -Rv, and every other cluster
  esac
done

if (( recursive && ! ack )); then
  print -u2 "safe-rm: recursive delete requires --i-mean-it"
  print -u2 "  command: rm $*"
  exit 1
fi
exec /bin/rm "${@:#--i-mean-it}"     # zsh: drop the sentinel, then exec the real rm
```

The gate is on **`-r`/`-R` alone**, not on the combination of `-r` and `-f`. An earlier draft matched
only single words containing both letters, which let `safe-rm -r target`, `safe-rm -R target`, and
`safe-rm -r -f target` (two separate words) through ungated — the wrapper advertised a guarantee it did
not provide, which is worse than no wrapper. `-r` without `-f` still destroys a directory tree, so it
needs the same acknowledgement. Options are scanned only up to `--`, so a file literally named `-rf`
after the separator does not trip the gate — correct, since `rm -- -rf` deletes one file, not a tree.

One known wart, in the safe direction: a file literally named `--i-mean-it` is stripped along with the
sentinel, so it survives instead of being deleted. That is a false negative, not a gate bypass, and it
is the right way round for a safety wrapper to fail.

Pair it with a two-phase habit for any bulk operation: run with `--dry-run`, read the plan it prints,
then re-run for real. An agent that cannot articulate what it is about to delete should not delete it.

### 16.4 Isolate the environment when the stakes justify it

- **Containers** — mount only the specific project directory into the container; everything else is
  simply absent from the filesystem the agent can see. Lowest overhead of the three.
- **Virtual machines** — a full VM with a snapshot taken before each session, reverted afterwards.
  Heaviest, and the only option that also contains a compromised toolchain.
- **A separate macOS user account** — run agents as a distinct user whose home directory holds only
  agent workspaces. POSIX permissions then do the enforcing, with no wrapper to bypass.

For this harness specifically, §12's disposable full clone is already the containment boundary for
mutation-heavy gates. These options extend the same principle to everything the agent does outside Git.

---

## Golden rules

1. **Always use `git worktree remove`/`prune`/`repair`, never manual `rm -rf` or `mv`** on worktree
   directories or `.git/worktrees/<name>` — repair (2.29+) and move (2.17+) are git's own tools for
   exactly these cases
2. **Validate before destroying** — resolve the exact path, prove it is inside the operation's
   dedicated root, and inventory worktree dependencies plus local-only state before cleanup
3. **Be path-aware in traps** — canonicalize paths early, validate them, and never `rm -rf` on
   relative paths or unvalidated variables
4. **Each full clone's `.git` is the source of truth for its worktree family** — protect it like a
   database, and verify its skeleton (`HEAD`/`objects`/`refs`/`config`) before trusting commands run
   against it (§11); partial corruption is a real failure mode, not just total deletion
5. **Linked worktrees share almost everything — objects, refs, AND stashes/logs.** The only genuinely
   per-worktree ref namespaces are `refs/bisect`, `refs/worktree`, and `refs/rewritten`. Don't assume
   isolation you don't have (§10); Git also actively *protects* shared state you might expect it not
   to (§9's branch-delete block). Separate full clones do not share that state.
6. **Prefer git's own recovery tools over hand-surgery on `.git/`** — `init` (safe to re-run),
   `fetch`, `prune`, `repair` — and reach for `read-tree`/`diff`/`status` to inspect before any
   command that can overwrite the working tree (`checkout -f`, `reset --hard`, `clean`)
7. **Script against `--porcelain` output, never the human-readable table** — `git worktree list`'s
   plain format is not a stable, grep-safe API
8. **Run the full test gate only in a separate disposable full clone** (§12) — never in a linked
   worktree or a primary clone whose state matters. The identity bracket detects damage; it does not
   make damage acceptable.
9. **Assume prevention will eventually fail, and pay the small costs that make recovery possible** —
   timestamped shell history, an `fsync`ed action log, and a `tmutil localsnapshot` before destructive
   runs (§15). After a loss, capture snapshots and logs *before* re-running anything (§14).
10. **Constrain the agent's writable world outside Git, not just inside it** — a resolved-path safe-root
    check, `chflags uchg` on data that should not move, and containment for mutation-heavy work (§16).
    Resolve symlinks before any path comparison; `startswith` on a path string is not containment.

---

## See also

- [Git Clone Documentation](https://git-scm.com/docs/git-clone)
- [Git Worktree Documentation](https://git-scm.com/docs/git-worktree)
- [git-init](https://git-scm.com/docs/git-init) — confirms re-running `init` on an existing repo is safe/non-clobbering
- [git-fsck](https://git-scm.com/docs/git-fsck) — integrity check, first step after any suspected `.git` corruption
- [git-gc](https://git-scm.com/docs/git-gc) — documents the `--prune=now` concurrency risk cited in §6
- [git-reflog](https://git-scm.com/docs/git-reflog) — the recovery path in §14.3 for commits no branch points at
- [tmutil(8)](https://keith.github.io/xcode-man-pages/tmutil.8.html) — `listlocalsnapshots` and `localsnapshot`, §14.1 and §15.4
- [mount_apfs(8)](https://keith.github.io/xcode-man-pages/mount_apfs.8.html) — `-s` mounts a named snapshot read-only (§14.1)
- [chflags(1)](https://keith.github.io/xcode-man-pages/chflags.1.html) — the `uchg` immutable flag used in §16.2
- [Apple: Endpoint Security](https://developer.apple.com/documentation/endpointsecurity) — the framework behind `eslogger` (§15.3)

---

License: See [`LICENSE`](LICENSE) and [`LICENSE-COMMERCIAL.md`](LICENSE-COMMERCIAL.md)  
Copyright 2026 Neochrome, Inc.  

exec
/bin/zsh -lc 'nl -ba test/relay-self-sufficiency.sh; nl -ba githooks/pre-push' in /private/var/folders/z0/92pfvhnn06z2_7hnpdb4kkbw0000gn/T/consult-wt-92092-h1_gqux_
 succeeded in 0ms:
     1	#!/usr/bin/env bash
     2	set -u
     3	#
     4	# relay-self-sufficiency.sh — verify that the ▶ TAKE YOUR TURN block in a minimal relay
     5	# file template is sufficient for a context-free headless agent to complete a turn correctly.
     6	#
     7	# This test uses a REAL headless agent (agy or codex). It is skipped automatically when no
     8	# live agent is found on PATH, or when RELAY_SELF_SUFFICIENCY_SKIP=1 is set.
     9	#
    10	# CI gate: set RELAY_SELF_SUFFICIENCY_SKIP=1 in keyless environments (no API key / network).
    11	# Cost: one real API call per run (~10-60s turn depending on agent speed).
    12	#
    13	# FAIL criteria (checked by assertions below):
    14	#   (A) Agent fails to claim/release — relay file not modified (path/env wrong in TAKE YOUR TURN)
    15	#   (B) Agent omits required log fields — VERDICT: or Basis: missing from written block
    16	#   (C) Agent writes off-allowlist files — shim exits non-zero (exit 6)
    17	
    18	HERE="$(cd "$(dirname "$0")" && pwd)"
    19	HARNESS="$(cd "$HERE/.." && pwd)"
    20	TICK="$HARNESS/bin/tick"
    21	
    22	PASS=0; FAIL=0
    23	pass() { echo "  PASS: $*"; PASS=$((PASS+1)); }
    24	fail() { echo "  FAIL: $*" >&2; FAIL=$((FAIL+1)); }
    25	
    26	echo "== test: relay-self-sufficiency =="
    27	
    28	# --- Skip: CI gate or explicit opt-out ---
    29	if [ "${RELAY_SELF_SUFFICIENCY_SKIP:-0}" = "1" ]; then
    30	  echo "  SKIPPED: RELAY_SELF_SUFFICIENCY_SKIP=1 (CI gate — no live agent in this environment)"
    31	  echo "  relay-self-sufficiency: 0 pass, 0 fail (skipped)"
    32	  exit 0
    33	fi
    34	
    35	# --- Locate live headless agent (agy preferred; codex fallback) ---
    36	LIVE_AGENT_BIN=""
    37	LIVE_AGENT_ID=""
    38	_agy_bin="${AGY_BIN:-}"
    39	if [ -z "$_agy_bin" ]; then
    40	  for c in agy "$HOME/.local/bin/agy"; do
    41	    if [ -x "$c" ] || command -v "$c" >/dev/null 2>&1; then _agy_bin="$c"; break; fi
    42	  done
    43	fi
    44	if [ -n "$_agy_bin" ]; then
    45	  LIVE_AGENT_BIN="$_agy_bin"
    46	  LIVE_AGENT_ID="agy"
    47	fi
    48	if [ -z "$LIVE_AGENT_BIN" ]; then
    49	  _codex_bin="${CODEX_BIN:-}"
    50	  [ -z "$_codex_bin" ] && command -v codex >/dev/null 2>&1 && _codex_bin="codex"
    51	  if [ -n "$_codex_bin" ]; then
    52	    LIVE_AGENT_BIN="$_codex_bin"
    53	    LIVE_AGENT_ID="codex"
    54	  fi
    55	fi
    56	
    57	if [ -z "$LIVE_AGENT_BIN" ]; then
    58	  echo "  SKIPPED: no live headless agent (agy/codex not on PATH; set AGY_BIN or CODEX_BIN to override)"
    59	  echo "  relay-self-sufficiency: 0 pass, 0 fail (skipped)"
    60	  exit 0
    61	fi
    62	
    63	WORK="$(mktemp -d -t "tick-relay-self-sufficiency.XXXXXX")"
    64	. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/fixture-guard.sh"   # GH-10: shared fixture containment
    65	fixture_guard_init "$WORK"   # GH-10: pin the sandbox root
    66	trap 'rm -rf "$WORK"' EXIT
    67	
    68	REPO="$WORK/repo"
    69	mkdir -p "$REPO/bin"
    70	
    71	echo "  workdir: $WORK"
    72	echo "  agent:   $LIVE_AGENT_BIN ($LIVE_AGENT_ID)"
    73	echo "  (live API call — requires network + credentials; ~10-60s)"
    74	
    75	# --- Set up isolated temp git repo (no CLAUDE.md, AGENTS.md, or ambient repo context) ---
    76	git init -q "$REPO"
    77	git -C "$REPO" config user.email "test@t"
    78	git -C "$REPO" config user.name "test"
    79	
    80	# .tick/ coordination state lives here; gitignore it so it's invisible to rtl_enforce.
    81	printf '.tick/\n' > "$REPO/.gitignore"
    82	
    83	# Seed relay file from the minimal fixture (no baton-pattern.md content).
    84	RELAY_FILE="$REPO/relay.md"
    85	cp "$HERE/fixtures/minimal-relay.md" "$RELAY_FILE"
    86	
    87	git -C "$REPO" add .gitignore relay.md
    88	git -C "$REPO" commit -q -m "seed minimal relay"
    89	
    90	# Create a tick wrapper so the agent's tick invocation (built into rtl_turn_prompt as
    91	# TICK_REPO_ROOT="$REPO" "$REPO/bin/tick") resolves to the real harness bin/tick while
    92	# keeping all events in $REPO/.tick/ (not the harness). Node's require() follows the
    93	# symlink's real path for src/ resolution, so a wrapper shell script is safer than a symlink.
    94	cat > "$REPO/bin/tick" <<TICK_WRAPPER
    95	#!/usr/bin/env bash
    96	TICK_REPO_ROOT="$REPO" exec node "$HARNESS/bin/tick" "\$@"
    97	TICK_WRAPPER
    98	chmod +x "$REPO/bin/tick"
    99	
   100	# --- Seed the relay task in the isolated repo's .tick/ ---
   101	TASK="RELAY-SELF-SUFFICIENCY-$$"
   102	TICK_REPO_ROOT="$REPO" "$TICK" log task.created "$TASK" --agent claude-a >/dev/null
   103	TICK_REPO_ROOT="$REPO" "$TICK" claim "$TASK" --agent claude-a --paths relay.md >/dev/null
   104	TICK_REPO_ROOT="$REPO" "$TICK" release "$TASK" --agent claude-a --to "$LIVE_AGENT_ID" >/dev/null
   105	
   106	# --- Drive one real headless agent turn ---
   107	AGY_LOG="$WORK/agent-turn.log"
   108	turn_rc=0
   109	
   110	# Run in a subshell cd'd to $REPO so the agent's relative paths (relay.md) resolve correctly
   111	# against the isolated repo, not the harness CWD. This mirrors RELAY_WORKTREE_ISOLATION=1
   112	# behavior (CWD = target repo) but without the worktree bug (GH-22).
   113	(
   114	  cd "$REPO"
   115	  if [ "$LIVE_AGENT_ID" = "agy" ]; then
   116	    RELAY_AGENT="$LIVE_AGENT_ID" RELAY_FILE="$RELAY_FILE" RELAY_TASK="$TASK" \
   117	      AGY_AGENT="$LIVE_AGENT_ID" AGY_BIN="$LIVE_AGENT_BIN" \
   118	      AGY_TURN_ROOT="$REPO" AGY_LOG="$AGY_LOG" \
   119	      RELAY_WORKTREE_ISOLATION=0 TICK_REPO_ROOT="$REPO" \
   120	      bash "$HARNESS/relay-automation/agy-turn.sh"
   121	  else
   122	    RELAY_AGENT="$LIVE_AGENT_ID" RELAY_FILE="$RELAY_FILE" RELAY_TASK="$TASK" \
   123	      CODEX_AGENT="$LIVE_AGENT_ID" CODEX_BIN="$LIVE_AGENT_BIN" \
   124	      CODEX_TURN_ROOT="$REPO" CODEX_LOG="$AGY_LOG" \
   125	      RELAY_WORKTREE_ISOLATION=0 TICK_REPO_ROOT="$REPO" \
   126	      bash "$HARNESS/relay-automation/codex-turn.sh"
   127	  fi
   128	) >/dev/null 2>&1 || turn_rc=$?
   129	
   130	# --- Assertion (C): shim exited 0 (no off-allowlist edit, no agent crash) ---
   131	if [ "$turn_rc" -eq 0 ]; then
   132	  pass "(C) shim exit 0 — no off-allowlist edits, no agent failure"
   133	else
   134	  fail "(C) $LIVE_AGENT_ID shim exited $turn_rc"
   135	  if [ -s "$AGY_LOG" ]; then
   136	    echo "  --- agent transcript (tail 20 lines) ---" >&2
   137	    tail -20 "$AGY_LOG" >&2
   138	  fi
   139	fi
   140	
   141	# --- Assertion (A): relay file was modified AND task is no longer claimed by claude-a ---
   142	relay_commit_count="$(git -C "$REPO" log --oneline relay.md 2>/dev/null | wc -l | tr -d ' ')"
   143	task_claimer="$(TICK_REPO_ROOT="$REPO" "$TICK" info "$TASK" 2>/dev/null | grep '^claimer:' | awk '{print $2}' || true)"
   144	if [ "$relay_commit_count" -gt 1 ] && [ "${task_claimer:-none}" != "claude-a" ]; then
   145	  pass "(A) agent claimed token + wrote relay file (commit observed, token moved from claude-a)"
   146	else
   147	  if [ "$relay_commit_count" -le 1 ]; then
   148	    fail "(A) relay file not modified — agent may have failed to claim/release (path assumptions wrong)"
   149	  else
   150	    fail "(A) relay file modified but token still claimed by claude-a — agent did not complete the handoff"
   151	  fi
   152	  echo "  Diagnostic: the TAKE YOUR TURN block's tick command may need adjustment." >&2
   153	  echo "  Fix: update test/fixtures/minimal-relay.md and commit the diff." >&2
   154	fi
   155	
   156	# Read the Log section for field assertions
   157	log_section=""
   158	if [ -f "$RELAY_FILE" ]; then
   159	  log_section="$(sed -e '1,/^## Log/d' "$RELAY_FILE")"
   160	fi
   161	
   162	# --- Assertion (B1): VERDICT: line present and valid ---
   163	if grep -qE '^VERDICT: (PASS|FAIL|PARKED)$' <<<"$(echo "$log_section")"; then
   164	  pass "(B1) VERDICT: field present and valid"
   165	else
   166	  verdict_val="$(echo "$log_section" | grep -E '^VERDICT:' | head -1 || true)"
   167	  fail "(B1) VERDICT: field missing or invalid (found: '${verdict_val:-<none>}')"
   168	  echo "  Diagnostic: agent did not write a VERDICT: line in the log block." >&2
   169	  echo "  Fix: add clearer VERDICT: instruction to test/fixtures/minimal-relay.md." >&2
   170	fi
   171	
   172	# --- Assertion (B2): Basis: line present and non-empty ---
   173	if grep -qE '^Basis: .+' <<<"$(echo "$log_section")"; then
   174	  pass "(B2) Basis: field present and non-empty"
   175	else
   176	  basis_val="$(echo "$log_section" | grep -E '^Basis:' | head -1 || true)"
   177	  fail "(B2) Basis: field missing or empty (found: '${basis_val:-<none>}')"
   178	  echo "  Diagnostic: agent did not write a Basis: line in the log block." >&2
   179	  echo "  Fix: add clearer Basis: instruction to test/fixtures/minimal-relay.md." >&2
   180	fi
   181	
   182	echo ""
   183	echo "  relay-self-sufficiency: $PASS pass, $FAIL fail"
   184	[ "$FAIL" -eq 0 ] || exit 1
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
   101	# GH-487: resolve each pushed ref pair to the range that classifies it. An existing remote ref
   102	# uses its own SHA (the update range, exactly as before). A first push of a new branch has no
   103	# update range, so the integration base is verified against the LIVE remote — not merely the
   104	# local tracking ref: a backward force-push of the integration branch leaves the tracking ref
   105	# newer than the true tip, and a range computed from it can be a SUBSET of the true integration
   106	# diff (review round 1, issue #487 comment 6). The freshness proof is `git ls-remote` equality;
   107	# every unresolvable, stale, or ambiguous pair refuses the narrow routes wholesale.
   108	_base_pairs=()
   109	_base_note=""
   110	_push_remote="${1:-}"
   111	resolve_base_pairs() {
   112	  _base_pairs=()
   113	  _base_note=""
   114	  [ "${#_real_ref_pairs[@]}" -gt 0 ] || { _base_note="pre-push: no ref pairs to classify — running the full gate."; return 1; }
   115	  local pair local_sha remote_sha cand base adv mbs
   116	  local _adv_dev="" _adv_main="" _lsremote_needed=0
   117	  for pair in "${_real_ref_pairs[@]}"; do
   118	    case "${pair#*|}" in
   119	      ''|0000000000000000000000000000000000000000) _lsremote_needed=1 ;;
   120	    esac
   121	  done
   122	  if [ "$_lsremote_needed" -eq 1 ]; then
   123	    case "$_push_remote" in
   124	      ''|*://*|*@*:*)
   125	        _base_note="pre-push: remote '${_push_remote:-<none>}' is not a configured remote name (a URL push?) — no verifiable integration base, running the full gate."
   126	        return 1
   127	        ;;
   128	    esac
   129	    # Freshness is proven against the PUSH destination (CodeRabbit #2 on PR #488): a remote may
   130	    # carry a separate pushurl, and `git ls-remote <name>` resolves the FETCH url — which would
   131	    # attest a server the push never touches. Resolve the push URL explicitly and probe that.
   132	    _probe_target="$(git remote get-url --push "$_push_remote" 2>/dev/null)" || _probe_target=""
   133	    [ -n "$_probe_target" ] || {
   134	      _base_note="pre-push: cannot resolve a push URL for '$_push_remote' — running the full gate."
   135	      return 1
   136	    }
   137	    # One round trip for both candidates, wall-clock bounded so a wedged connection costs seconds,
   138	    # not minutes: the HTTP low-speed settings do not bind SSH, so a portable perl alarm wraps the
   139	    # probe (a missing perl degrades to the HTTP bound only, never to an unbounded hang policy
   140	    # change). The probe's EXIT STATUS is authoritative (round 3 review): a nonzero ls-remote that
   141	    # emitted partial refs (one ref advertised, then the connection died) must fail closed, because
   142	    # partial output is indistinguishable from a complete answer unless the status says so.
   143	    _adv_out=""
   144	    if command -v perl >/dev/null 2>&1; then
   145	      _probe_cmd=(perl -e 'alarm shift; exec @ARGV' "${XYZ_PREPUSH_PROBE_TIMEOUT_S:-30}" git ls-remote "$_probe_target" refs/heads/development refs/heads/main)
   146	    else
   147	      _probe_cmd=(git ls-remote "$_probe_target" refs/heads/development refs/heads/main)
   148	    fi
   149	    if ! _adv_out="$(GIT_HTTP_LOW_SPEED_LIMIT=1000 GIT_HTTP_LOW_SPEED_TIME=30 "${_probe_cmd[@]}" 2>/dev/null)"; then
   150	      _base_note="pre-push: could not verify the integration tip on '$_push_remote' via its push URL (git ls-remote failed or timed out) — running the full gate.
   151	pre-push:   (if offline, bypass with 'XYZ_SKIP_PREPUSH=1 git push' or 'git push --no-verify')"
   152	      return 1
   153	    fi
   154	    while read -r _sha _ref; do
   155	      [ -n "${_sha:-}" ] || continue
   156	      case "$_ref" in
   157	        refs/heads/development) _adv_dev="$_sha" ;;
   158	        refs/heads/main)        _adv_main="$_sha" ;;
   159	      esac
   160	    done <<<"$_adv_out"
   161	    if [ -z "$_adv_dev" ] && [ -z "$_adv_main" ]; then
   162	      _base_note="pre-push: no integration branch advertised on '$_push_remote' (neither development nor main) — running the full gate."
   163	      return 1
   164	    fi
   165	  fi
   166	  for pair in "${_real_ref_pairs[@]}"; do
   167	    IFS='|' read -r local_sha remote_sha <<<"$pair"
   168	    base=""
   169	    case "$remote_sha" in
   170	      ''|0000000000000000000000000000000000000000)
   171	        for cand in "development:$_adv_dev" "main:$_adv_main"; do
   172	          local cand_name="${cand%%:*}" adv="${cand#*:}"
   173	          [ -n "$adv" ] || continue
   174	          cand="refs/remotes/$_push_remote/$cand_name"
   175	          # Freshness proof: the tracking ref must equal the tip the remote advertises RIGHT NOW.
   176	          # "Behind" and "rewritten under us" are indistinguishable locally, and only the first
   177	          # direction is safe — so any mismatch means stale evidence, which is the full gate's
   178	          # job (the issue's own contract). A fetch makes the narrow route available again.
   179	          [ "$(git rev-parse --verify --quiet "$cand^{commit}" 2>/dev/null)" = "$adv" ] || continue
   180	          mbs="$(git merge-base --all "$cand" "$local_sha" 2>/dev/null)" || { continue; }
   181	          [ "$(printf '%s\n' "$mbs" | grep -c .)" -eq 1 ] || {
   182	            _base_note="pre-push: ambiguous integration base (multiple best common ancestors with $_push_remote/$cand_name) — running the full gate."
   183	            return 1
   184	          }
   185	          base="$mbs"
   186	          git cat-file -e "$base^{commit}" 2>/dev/null || { base=""; continue; }
   187	          [ "$base" != "$local_sha" ] || { base=""; continue; }   # empty range: nothing to classify
   188	          break
   189	        done
   190	        if [ -z "$base" ]; then
   191	          [ -n "$_base_note" ] || _base_note="pre-push: no fresh merge-base with $_push_remote's integration branch (tracking ref stale or absent — fetch and retry, or take the full gate)."
   192	          return 1
   193	        fi
   194	        ;;
   195	      *)
   196	        git cat-file -e "${remote_sha}^{commit}" 2>/dev/null || return 1
   197	        git merge-base --is-ancestor "$remote_sha" "$local_sha" 2>/dev/null || return 1
   198	        base="$remote_sha"
   199	        ;;
   200	    esac
   201	    _base_pairs+=("$local_sha|$base")
   202	  done
   203	  return 0
   204	}
   205	
   206	classify_push() {
   207	  [ -x "$REPO/utils/ci-route.sh" ] || return 1
   208	  [ "${#_base_pairs[@]}" -gt 0 ] || return 1
   209	
   210	  local pair local_sha base
   211	  for pair in "${_base_pairs[@]}"; do
   212	    IFS='|' read -r local_sha base <<<"$pair"
   213	    # `--no-renames` is load-bearing: the classifier must see the removed side of a renamed test.
   214	    git diff --no-renames --name-only "$base" "$local_sha" || return 1
   215	  done | "$REPO/utils/ci-route.sh" push
   216	}
   217	
   218	run_docs_gate() {
   219	  if [ ! -x "$REPO/utils/pdda/pdda.sh" ]; then
   220	    echo "pre-push: docs-only route selected but the PDDA gate is missing — REFUSING the push." >&2
   221	    return 1
   222	  fi
   223	  "$REPO/utils/pdda/pdda.sh" run || return 1
   224	  # Repo-owned PDDA additions are warn-only by contract; retain their diagnostics without turning
   225	  # a documentation-only push into an accidental second blocking policy.
   226	  [ ! -x "$REPO/utils/pdda-local-checks.sh" ] || "$REPO/utils/pdda-local-checks.sh" run || true
   227	}
   228	
   229	# Hand the push's changed paths to validate.sh --tier 2 (GH-35). The paths file is the contract
   230	# between the hook and the runner: validate.sh re-classifies it, refuses anything that is not
   231	# tier 2, and runs the registry's suites — so the hook never carries a second test list.
   232	run_tier2_gate() {
   233	  local paths_file="$1"
   234	  echo "pre-push: utility-only update — running the tier 2 subsystem gate, not the full suite (GH-35)."
   235	  "$REPO/validate.sh" --print-mode --tier 2 2>&1 | sed 's/^/pre-push:   /'
   236	  # NOT wrapped in `nice` here: `nice -n N` is RELATIVE to the caller, and validate.sh already
   237	  # runs every suite worker at +10. Nicing the runner too stacked to +20 — over-throttling the
   238	  # gate whose width/nice policy was measured at +10, and failing gh35-test-tiers.sh's own
   239	  # worker-nice pin on EVERY push. Resource policy belongs to validate.sh (GH-35's own rule).
   240	  "$REPO/validate.sh" --paths-file "$paths_file"
   241	}
   242	
   243	_base_ok=0
   244	resolve_base_pairs && _base_ok=1
   245	if [ "$_base_ok" -ne 1 ] && [ -n "$_base_note" ]; then
   246	  printf '%s\n' "$_base_note" >&2
   247	fi
   248	_cls=""
   249	if [ "$_base_ok" -eq 1 ]; then
   250	  _cls="$(classify_push 2>/dev/null || true)"
   251	fi
   252	_route="$(printf '%s\n' "$_cls" | sed -n 's/^route=//p')"
   253	_tier="$(printf '%s\n' "$_cls" | sed -n 's/^tier=//p')"
   254	_t2tests="$(printf '%s\n' "$_cls" | sed -n 's/^tier2_tests=//p')"
   255	_gate_name="full validation"
   256	_start=$SECONDS
   257	_paths_file=""
   258	if [ "$_route" = "docs" ]; then
   259	  _gate_name="deterministic documentation gate"
   260	  echo "pre-push: docs-only update — running the documentation gate, not validate.sh."
   261	  if run_docs_gate; then
   262	    echo "pre-push: documentation gate GREEN in $((SECONDS - _start))s — pushing."
   263	    exit 0
   264	  else
   265	    _rc=$?
   266	  fi
   267	elif [ "$_route" = "fast" ] && [ "$_tier" = "2" ] && [ -n "$_t2tests" ]; then
   268	  # route=fast alone is NOT enough (an unmapped code path also routes fast): the classifier
   269	  # must say tier 2 AND name runnable suites, or this arm is skipped and the full gate runs.
   270	  _paths_file="$(mktemp "${TMPDIR:-/tmp}/prepush-paths.XXXXXX")"
   271	  if [ -n "$_paths_file" ]; then
   272	    # Same resolved bases as classify_push — the range is computed ONCE per push, never twice.
   273	    for pair in "${_base_pairs[@]}"; do
   274	      IFS='|' read -r _ls _bs <<<"$pair"
   275	      git diff --no-renames --name-only "$_bs" "$_ls" >> "$_paths_file" 2>/dev/null
   276	    done
   277	    _gate_name="tier 2 subsystem gate (GH-35)"
   278	    if run_tier2_gate "$_paths_file"; then
   279	      echo "pre-push: tier 2 gate GREEN in $((SECONDS - _start))s — pushing."
   280	      rm -f "$_paths_file"
   281	      exit 0
   282	    else
   283	      _rc=$?
   284	    fi
   285	    rm -f "$_paths_file"
   286	  fi
   287	  # An unusable paths file falls through to the full gate below — fail closed, never open.
   288	else
   289	  echo "pre-push: running the full gate before this push reaches the remote (GH-544)."
   290	  echo "pre-push:   bypass with 'git push --no-verify' or XYZ_SKIP_PREPUSH=1 — both are recorded here, not hidden."
   291	  "$REPO/validate.sh" --print-mode 2>&1 | sed 's/^/pre-push:   /'
   292	
   293	  # See the note in run_tier2_gate: no outer `nice` — it is relative and stacks onto the +10
   294	  # validate.sh already applies to each worker.
   295	  if "$REPO/validate.sh"; then
   296	    echo "pre-push: full gate GREEN in $((SECONDS - _start))s — pushing."
   297	    exit 0
   298	  else
   299	    _rc=$?
   300	  fi
   301	fi
   302	cat >&2 <<EOF
   303	
   304	pre-push: $_gate_name RED (exit $_rc) after $((SECONDS - _start))s — push REFUSED.
   305	
   306	  The failing checks are named in the output above.
   307	
   308	  Hosted CI may run after the push, but this local boundary is the earliest full signal and the
   309	  Ubuntu pull-request lane is advisory. Do not use downstream CI as a reason to ignore this red.
   310	
   311	  To push anyway (and you may have a good reason — a WIP branch, a known-red baseline):
   312	    git push --no-verify
   313	EOF
   314	exit 1

exec
/bin/zsh -lc "rg -n 'RELAY_SELF|validate.sh|env:|ci.yml|subprocess|environ' .github/workflows/ci.yml .github/workflows/wave-reconcile.yml utils/py/wave_reconcile.py ci-local.sh; rg -n 'self-sufficiency|SUBSYSTEM_TESTS_small|relay-automation|full.required' validate.sh utils/ci-route.sh; git log --format='%h %ad %s' --date=short -- relay-automation/new-relay.sh" in /private/var/folders/z0/92pfvhnn06z2_7hnpdb4kkbw0000gn/T/consult-wt-92092-h1_gqux_
 succeeded in 0ms:
ci-local.sh:10:# It follows .github/workflows/ci.yml's job in ORDER and CONTENT, but NOT in coverage — see the
ci-local.sh:37:#   ./ci-local.sh --fast       # everything EXCEPT the full validate.sh suite (~1 min)
ci-local.sh:71:# The same gate-environment prologue validate.sh sources (GH-441 scrub of ambient marathon exports;
ci-local.sh:73:# it itself — a `validate.sh --list` child cannot export back into this shell.
ci-local.sh:77:# Same guard, same reason, same override as validate.sh's (kept inline in both rather than a new
ci-local.sh:79:# SAME suite validate.sh does, so running it from a worktree exposes the parent clone's shared
ci-local.sh:80:# .git to exactly the fixture-escape damage validate.sh refuses (2026-08-19 incident, GH-564).
ci-local.sh:155:# GH-365 step 2: retained JSONL telemetry, same lib and schema validate.sh uses. rt_begin is
ci-local.sh:188:# job in ci.yml is the other); no registered suite executes it — everything else in test/ is
ci-local.sh:189:# directives. Parallel at the balanced four-worker width (the same policy validate.sh's pool
ci-local.sh:251:# TESTS is parsed out of validate.sh exactly the way the workflow parses it, so the two cannot drift
ci-local.sh:252:# on WHICH tests run — only on the environment they run in.
ci-local.sh:274:  done < <(sed -n '/^TESTS=(/,/^)/p' validate.sh | grep -oE '"[^"]+\.sh"' | tr -d '"')
ci-local.sh:276:  [ "${#all_tests[@]}" -gt 0 ] || { echo "  could not parse TESTS from validate.sh" >&2; return 1; }
ci-local.sh:277:  echo "  ${#all_tests[@]} suites declared in validate.sh"
ci-local.sh:316:  # .sh-only subset. validate.sh owns three non-TESTS lanes; this runner supplies its own envelope
ci-local.sh:319:  # the loop now, recorded in the verdicts under validate.sh's own PASSED labels so the record and
ci-local.sh:349:# bracket validate.sh has, from the SAME shared helper (GH-365 step 1): identity drift fails the
ci-local.sh:361:printf '\033[1mci-local — mirroring .github/workflows/ci.yml tier1\033[0m\n'
ci-local.sh:364:[ "$FAST" -eq 1 ] && printf '\033[33mmode: --fast (full validate.sh suite SKIPPED)\033[0m\n'
ci-local.sh:365:# GH-365 step 2: open the retained telemetry record for THIS run (same schema as validate.sh).
ci-local.sh:368:# The denominator comes from validate.sh --list — the READ-ONLY registry surface #141 built for
ci-local.sh:370:# This is not "invoking validate.sh" in the sense gh544 pins: the gate never runs, no suites, no
ci-local.sh:372:_declared="$(bash "$HERE/validate.sh" --list | wc -l | tr -d ' ')"
ci-local.sh:391:# GH-10/GH-1 + GH-365 step 1: the qualifying run gets the SAME envelope validate.sh uses, from
ci-local.sh:404:  RELAY_SELF_SUFFICIENCY_SKIP=1 step "validate.sh suite" validate_suite
.github/workflows/wave-reconcile.yml:33:    env:
.github/workflows/wave-reconcile.yml:42:        env:
.github/workflows/wave-reconcile.yml:55:        env:
.github/workflows/wave-reconcile.yml:91:        env:
utils/py/wave_reconcile.py:19:import subprocess
utils/py/wave_reconcile.py:94:        res = subprocess.run(
utils/py/wave_reconcile.py:106:    except subprocess.TimeoutExpired:
utils/py/wave_reconcile.py:245:    r = subprocess.run(cmd, capture_output=True, text=True, check=False)
utils/py/wave_reconcile.py:269:    r = subprocess.run(cmd, capture_output=True, text=True, check=False)
utils/py/wave_reconcile.py:287:    r = subprocess.run(cmd, capture_output=True, text=True, check=False)
utils/py/wave_reconcile.py:299:    r = subprocess.run(cmd, capture_output=True, text=True, check=False)
utils/py/wave_reconcile.py:320:        r = subprocess.run(
utils/py/wave_reconcile.py:383:    r = subprocess.run(cmd, cwd=repo_root, capture_output=True, text=True, check=False)
utils/py/wave_reconcile.py:421:    resolved = subprocess.run(
utils/py/wave_reconcile.py:428:    reachable = subprocess.run(
utils/py/wave_reconcile.py:434:    shown = subprocess.run(
utils/py/wave_reconcile.py:459:QUALIFICATION_GATE = "validate.sh --sequential"
utils/py/wave_reconcile.py:462:SMALL_GATE = "validate.sh --sequential --subsystem small"
utils/py/wave_reconcile.py:468:    shown = subprocess.run(["git", "show", f"{commit}:utils/ci-route.sh"], cwd=repo_root,
utils/py/wave_reconcile.py:562:            if subprocess.run(["git", "merge-base", "--is-ancestor", older, newer],
utils/py/wave_reconcile.py:572:    paths = subprocess.check_output(["git", "ls-tree", "-r", "--name-only", "HEAD", "--",
utils/py/wave_reconcile.py:578:        raw = subprocess.check_output(["git", "show", f"HEAD:{path}"], cwd=repo_root, text=True)
utils/py/wave_reconcile.py:599:            diff = subprocess.run(["git", "diff", "--no-renames", "--name-only", f"{landing}^", landing],
utils/py/wave_reconcile.py:604:        routed = subprocess.run(["bash", "utils/ci-route.sh", "push"], cwd=clone, env=env,
utils/py/wave_reconcile.py:613:    except (OSError, subprocess.SubprocessError, ValueError, KeyError, TypeError) as exc:
utils/py/wave_reconcile.py:628:    tested = subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=repo_root, text=True).strip()
utils/py/wave_reconcile.py:633:                or subprocess.run(["git", "merge-base", "--is-ancestor", landing, tested],
utils/py/wave_reconcile.py:640:        # Reuse the harness environment contract, then isolate Git and runner controls.
utils/py/wave_reconcile.py:648:                   RELAY_SELF_SUFFICIENCY_SKIP="1", TICK_REPO_ROOT=str(clone))
utils/py/wave_reconcile.py:655:                raise subprocess.CalledProcessError(124 if result.timed_out else result.rc, args,
utils/py/wave_reconcile.py:662:            origin = subprocess.check_output(["git", "remote", "get-url", "origin"],
utils/py/wave_reconcile.py:685:        except (subprocess.SubprocessError, OSError, ValueError) as exc:
utils/py/wave_reconcile.py:687:    if subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=repo_root, text=True).strip() != tested:
utils/py/wave_reconcile.py:711:        if os.environ.get("GITHUB_ACTIONS") == "true":
utils/py/wave_reconcile.py:712:            entry["run_url"] = (f"https://github.com/{os.environ.get('GITHUB_REPOSITORY', '')}/actions/runs/"
utils/py/wave_reconcile.py:713:                                f"{os.environ.get('GITHUB_RUN_ID', '')}")
utils/py/wave_reconcile.py:814:        tree_files = subprocess.check_output(
utils/py/wave_reconcile.py:818:            stderr=subprocess.DEVNULL,
utils/py/wave_reconcile.py:831:        recent_shas = subprocess.check_output(
utils/py/wave_reconcile.py:835:            stderr=subprocess.DEVNULL,
utils/py/wave_reconcile.py:845:            content = subprocess.check_output(
utils/py/wave_reconcile.py:849:                stderr=subprocess.DEVNULL,
utils/py/wave_reconcile.py:866:                        resolved = subprocess.check_output(
utils/py/wave_reconcile.py:870:                            stderr=subprocess.DEVNULL,
utils/py/wave_reconcile.py:885:                                matched_sha = subprocess.check_output(
utils/py/wave_reconcile.py:889:                                    stderr=subprocess.DEVNULL,
utils/py/wave_reconcile.py:909:                                diff_out = subprocess.check_output(
utils/py/wave_reconcile.py:913:                                    stderr=subprocess.DEVNULL,
utils/py/wave_reconcile.py:1231:    result = subprocess.run(cmd, cwd=repo_root, capture_output=True, text=True, check=False)
utils/py/wave_reconcile.py:1267:    shallow = subprocess.check_output(['git', 'rev-parse', '--is-shallow-repository'],
utils/py/wave_reconcile.py:1271:    dates = subprocess.check_output(
utils/py/wave_reconcile.py:1280:    result = subprocess.run(
utils/py/wave_reconcile.py:1352:            result = subprocess.run(["gh", "api", "--paginate", "--slurp",
utils/py/wave_reconcile.py:1683:def run_subprocesses(repo_root, dry_run=False, journal=None, reconciled_issues=None):
utils/py/wave_reconcile.py:1763:                os.environ,
utils/py/wave_reconcile.py:1768:            r = subprocess.run(cmd, cwd=repo_root, capture_output=True, text=True, check=False, env=step_env)
utils/py/wave_reconcile.py:1791:    r = subprocess.run(
utils/py/wave_reconcile.py:1814:        head_sha = subprocess.check_output(
utils/py/wave_reconcile.py:1826:            r = subprocess.run(
utils/py/wave_reconcile.py:1848:            commits_text = subprocess.check_output(
utils/py/wave_reconcile.py:1867:            mb = subprocess.check_output(
utils/py/wave_reconcile.py:1871:                stderr=subprocess.DEVNULL,
utils/py/wave_reconcile.py:1877:        diff_status = subprocess.check_output(
utils/py/wave_reconcile.py:1881:            stderr=subprocess.DEVNULL,
utils/py/wave_reconcile.py:2067:        if args.force_local_reconcile and os.environ.get("GITHUB_ACTIONS") == "true":
utils/py/wave_reconcile.py:2077:        if not args.offline and not args.dry_run and os.environ.get("GITHUB_ACTIONS") != "true":
utils/py/wave_reconcile.py:2297:            # marathon lane was processed but happened not to move a doc: run_subprocesses does
utils/py/wave_reconcile.py:2314:            run_subprocesses(
.github/workflows/ci.yml:44:#        gh workflow run ci.yml --ref <branch>
.github/workflows/ci.yml:52:#    frozen-twin guard, acorn-extract, Fast Gate, validate.sh — silently never ran, for four days,
.github/workflows/ci.yml:62:#    environment noise, and see the GH-232 note further down for why that assumption is expensive.
.github/workflows/ci.yml:135:  # gate on the platform we ship to: `./validate.sh` (and, per GH-528, `--parallel N` for a ~3-minute
.github/workflows/ci.yml:156:    # locally" (GH-823): wave-reconcile.yml runs this same `validate.sh --sequential` on this same runner
.github/workflows/ci.yml:169:      - name: Prepare git environment for fixture-driven tests
.github/workflows/ci.yml:179:      # The hosted runner's Python has no pytest, and validate.sh's python lane needs it — the
.github/workflows/ci.yml:182:      # first time they ran on hosted macOS, the environment couldn't run them.
.github/workflows/ci.yml:190:        env:
.github/workflows/ci.yml:194:          RELAY_SELF_SUFFICIENCY_SKIP: "1"
.github/workflows/ci.yml:199:        # inherited: a future change to validate.sh's default must not be able to silently change what
.github/workflows/ci.yml:203:        run: ./validate.sh --sequential
.github/workflows/ci.yml:265:        env:
.github/workflows/ci.yml:390:      - name: Prepare git environment for fixture-driven tests
.github/workflows/ci.yml:401:        env:
.github/workflows/ci.yml:402:          RELAY_SELF_SUFFICIENCY_SKIP: "1"
.github/workflows/ci.yml:436:      # GH-232: PR #231 ran the full ./validate.sh suite on ubuntu-latest for the first time and
.github/workflows/ci.yml:437:      # found ~12 failures, assumed to be Ubuntu-environment-only and scoped out of CI. Re-diagnosed
.github/workflows/ci.yml:448:      # GH-379: this step CALLS validate.sh. It must never go back to iterating suites itself.
.github/workflows/ci.yml:450:      # It used to scrape the TESTS array out of validate.sh with sed/grep and run a serial
.github/workflows/ci.yml:455:      #   * THE CONTENTION-RETRY — validate.sh re-runs a pooled failure alone before believing it,
.github/workflows/ci.yml:461:      # The skips are now validate.sh's own --skip, which refuses an unregistered name, announces
.github/workflows/ci.yml:466:      # future change to validate.sh's default must not silently change what this job runs.
.github/workflows/ci.yml:469:      # POOL width, and validate.sh runs the serialized driver-lock lane as a concurrent background
.github/workflows/ci.yml:479:      # test/gh379-canary-uses-validate.sh asserts all of this, selector by selector.
.github/workflows/ci.yml:480:      - name: Run validate.sh suite (minus a documented flaky test)
.github/workflows/ci.yml:482:        env:
.github/workflows/ci.yml:483:          RELAY_SELF_SUFFICIENCY_SKIP: "1"
.github/workflows/ci.yml:486:          ./validate.sh --parallel 6 \
.github/workflows/ci.yml:530:      - name: Prepare git environment
.github/workflows/ci.yml:543:        env:
utils/ci-route.sh:38:SUBSYSTEM_TESTS_small="gh308-frozen-twin-guard.sh gh777-inventory-ratchet.sh gh400-acceptance-fidelity.sh gh400-source-url.sh litmus-release.sh gh422-backfill-source-url.sh gh425-source-url-slug.sh gh448-driver-lock-resolver.sh nightwatch-release.sh meter-release.sh ballast-release.sh gh549-work-events.sh gh646-status-label.sh gh1-fixture-guard.sh gh1-adoption-guard.sh gh139-pipe-grep-guard.sh gh168-wave-reconcile-scope.sh gh184-no-tracked-scratch.sh gh202-wave-reconcile-issue-state.sh gh232-wave-reconcile-multiphase.sh releases-skill.sh gh103-timeline-exporter.sh gh75-dashboard.sh gh32-releases-app.sh gh32-releases-artifacts.sh gh53-releases-merge-resolve.sh gh54-merged-dump-refusals.sh gh57-releases-fuzz.sh gh57-live-merge-resolve.sh gh69-roadmap-shadow.sh gh351-manifest-unship.sh gh360-scoped-receipt-chain-rebuild.sh gh349-releases-roadmap-vendored.sh gh429-wave-reconcile-vendored-observe.sh gh358-wave-reconcile-vendored-paths.sh gh32-release-target-advisory.sh gh39-releases-project-sync.sh relay-target-root.sh relay-target-root-paths.sh relay-target-root-relayfile.sh relay-target-root-newfile.sh gh649-pdda-migration.sh pdda-changelog.sh pdda-install-startup-docs.sh pdda-roadmap-coverage.sh pdda-repo-contract.sh pdda-local-checks.sh gh784-marathon-qa-gate.sh gh284-p3-release-milestone.sh gh284-p4-release-lanes.sh mktemp-trap-guard.sh gh567-roadmap-dashboard-retired.sh gh257-roadmap-ledger-fixes.sh gh269-roadmap-retired.sh gh568-releases-md-retired.sh gh454-reconciler-defects.sh gh424-roadmap-status-marker.sh gh421-auto-wave-reconcile.sh gh491-roadmap-section-validation.sh gh492-roadmap-state-sweep.sh gh605-work-state.sh gh605-board-policy.sh gh436-merge-cleanup.sh gh645-merge-cleanup-xyz-tools.sh gh674-merge-cleanup-hosted-lookup.sh gh527-issue-url-repair.sh gh153-releases-sidebar-rollup.sh security-scan.sh sentinel-network-guard.sh gh107-timeline-json-seam.sh wave-reconcile.sh gh496-phase2-reconciliation-views.sh gh306-registry-bidirectional.sh"
utils/ci-route.sh:59:#   3. the non-text files of core skills (relay, relay-xyz, relay-automation, merge-cleanup, express,
utils/ci-route.sh:61:#      catches every relay-xyz and relay-automation file;
utils/ci-route.sh:67:    skills/*/relay/*|skills/*/relay-xyz/*|skills/*/relay-automation/*|skills/*/merge-cleanup/*|skills/*/express/*|skills/*/jog/*) return 1 ;;
utils/ci-route.sh:108:      'full_required=true' \
utils/ci-route.sh:272:full_required=false
utils/ci-route.sh:327:        full_required=true
utils/ci-route.sh:331:      full_required=true
utils/ci-route.sh:334:      full_required=true
utils/ci-route.sh:336:    relay-automation/*|skills/*/relay-automation/*|skills/*/relay-xyz/*)
utils/ci-route.sh:337:      full_required=true
utils/ci-route.sh:342:      [ -n "$(subsystem_of "$path" || true)" ] || full_required=true
utils/ci-route.sh:345:      full_required=true
utils/ci-route.sh:348:      full_required=true
utils/ci-route.sh:424:        full_required=true
utils/ci-route.sh:450:  full_required=true
utils/ci-route.sh:453:if [[ "$full_required" == true ]]; then
utils/ci-route.sh:467:if [[ "$full_required" == true ]]; then
utils/ci-route.sh:496:  "full_required=$full_required" \
validate.sh:48:. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/relay-automation/gate-env.sh"
validate.sh:661:  "relay-self-sufficiency.sh"
validate.sh:700:# TESTS array, with one exception: the suites that execute the REAL relay-automation/relay-drive.sh
validate.sh:1247:# relay-automation/relay-drive.sh. If you add such a suite, add it here too — at 2+ jobs the
git: warning: confstr() failed with code 5: couldn't get path of DARWIN_USER_TEMP_DIR; using /tmp instead
git: error: couldn't create cache file '/tmp/xcrun_db-GEHHUAul' (errno=Operation not permitted)
git: warning: confstr() failed with code 5: couldn't get path of DARWIN_USER_TEMP_DIR; using /tmp instead
git: error: couldn't create cache file '/tmp/xcrun_db-eFufD91S' (errno=Operation not permitted)
c0a9b899 2026-09-22 feat(GH-749): marathon delivery — #720 review-once heading truth; #732 measurements, dated timing claims + slowest-suites summary, named environment faults (four lanes, all gates green) (#750)
55d8ab47 2026-09-17 fix(relay): Reviewer may measure read-only; generalizations carry a falsifier (GH-681) (#683)
99c263ea 2026-09-11 fix: stage relay, Tick, and merge-cleanup hotfixes (#529, #533, #554, #555) (#573)
1f0a5bf1 2026-08-15 XYZ: initial public release

exec
/bin/zsh -lc "nl -ba test/relay-self-sufficiency.sh; nl -ba utils/py/wave_reconcile.py | sed -n '620,680p'; nl -ba relay-automation/gate-env.sh | sed -n '1,130p'; rg -n '835|836|2\\.3|2\\.7|relay-self-sufficiency' PROJECT TESTS-RESULTS SOP.md | head -65" in /private/var/folders/z0/92pfvhnn06z2_7hnpdb4kkbw0000gn/T/consult-wt-92092-h1_gqux_
 succeeded in 0ms:
     1	#!/usr/bin/env bash
     2	set -u
     3	#
     4	# relay-self-sufficiency.sh — verify that the ▶ TAKE YOUR TURN block in a minimal relay
     5	# file template is sufficient for a context-free headless agent to complete a turn correctly.
     6	#
     7	# This test uses a REAL headless agent (agy or codex). It is skipped automatically when no
     8	# live agent is found on PATH, or when RELAY_SELF_SUFFICIENCY_SKIP=1 is set.
     9	#
    10	# CI gate: set RELAY_SELF_SUFFICIENCY_SKIP=1 in keyless environments (no API key / network).
    11	# Cost: one real API call per run (~10-60s turn depending on agent speed).
    12	#
    13	# FAIL criteria (checked by assertions below):
    14	#   (A) Agent fails to claim/release — relay file not modified (path/env wrong in TAKE YOUR TURN)
    15	#   (B) Agent omits required log fields — VERDICT: or Basis: missing from written block
    16	#   (C) Agent writes off-allowlist files — shim exits non-zero (exit 6)
    17	
    18	HERE="$(cd "$(dirname "$0")" && pwd)"
    19	HARNESS="$(cd "$HERE/.." && pwd)"
    20	TICK="$HARNESS/bin/tick"
    21	
    22	PASS=0; FAIL=0
    23	pass() { echo "  PASS: $*"; PASS=$((PASS+1)); }
    24	fail() { echo "  FAIL: $*" >&2; FAIL=$((FAIL+1)); }
    25	
    26	echo "== test: relay-self-sufficiency =="
    27	
    28	# --- Skip: CI gate or explicit opt-out ---
    29	if [ "${RELAY_SELF_SUFFICIENCY_SKIP:-0}" = "1" ]; then
    30	  echo "  SKIPPED: RELAY_SELF_SUFFICIENCY_SKIP=1 (CI gate — no live agent in this environment)"
    31	  echo "  relay-self-sufficiency: 0 pass, 0 fail (skipped)"
    32	  exit 0
    33	fi
    34	
    35	# --- Locate live headless agent (agy preferred; codex fallback) ---
    36	LIVE_AGENT_BIN=""
    37	LIVE_AGENT_ID=""
    38	_agy_bin="${AGY_BIN:-}"
    39	if [ -z "$_agy_bin" ]; then
    40	  for c in agy "$HOME/.local/bin/agy"; do
    41	    if [ -x "$c" ] || command -v "$c" >/dev/null 2>&1; then _agy_bin="$c"; break; fi
    42	  done
    43	fi
    44	if [ -n "$_agy_bin" ]; then
    45	  LIVE_AGENT_BIN="$_agy_bin"
    46	  LIVE_AGENT_ID="agy"
    47	fi
    48	if [ -z "$LIVE_AGENT_BIN" ]; then
    49	  _codex_bin="${CODEX_BIN:-}"
    50	  [ -z "$_codex_bin" ] && command -v codex >/dev/null 2>&1 && _codex_bin="codex"
    51	  if [ -n "$_codex_bin" ]; then
    52	    LIVE_AGENT_BIN="$_codex_bin"
    53	    LIVE_AGENT_ID="codex"
    54	  fi
    55	fi
    56	
    57	if [ -z "$LIVE_AGENT_BIN" ]; then
    58	  echo "  SKIPPED: no live headless agent (agy/codex not on PATH; set AGY_BIN or CODEX_BIN to override)"
    59	  echo "  relay-self-sufficiency: 0 pass, 0 fail (skipped)"
    60	  exit 0
    61	fi
    62	
    63	WORK="$(mktemp -d -t "tick-relay-self-sufficiency.XXXXXX")"
    64	. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/fixture-guard.sh"   # GH-10: shared fixture containment
    65	fixture_guard_init "$WORK"   # GH-10: pin the sandbox root
    66	trap 'rm -rf "$WORK"' EXIT
    67	
    68	REPO="$WORK/repo"
    69	mkdir -p "$REPO/bin"
    70	
    71	echo "  workdir: $WORK"
    72	echo "  agent:   $LIVE_AGENT_BIN ($LIVE_AGENT_ID)"
    73	echo "  (live API call — requires network + credentials; ~10-60s)"
    74	
    75	# --- Set up isolated temp git repo (no CLAUDE.md, AGENTS.md, or ambient repo context) ---
    76	git init -q "$REPO"
    77	git -C "$REPO" config user.email "test@t"
    78	git -C "$REPO" config user.name "test"
    79	
    80	# .tick/ coordination state lives here; gitignore it so it's invisible to rtl_enforce.
    81	printf '.tick/\n' > "$REPO/.gitignore"
    82	
    83	# Seed relay file from the minimal fixture (no baton-pattern.md content).
    84	RELAY_FILE="$REPO/relay.md"
    85	cp "$HERE/fixtures/minimal-relay.md" "$RELAY_FILE"
    86	
    87	git -C "$REPO" add .gitignore relay.md
    88	git -C "$REPO" commit -q -m "seed minimal relay"
    89	
    90	# Create a tick wrapper so the agent's tick invocation (built into rtl_turn_prompt as
    91	# TICK_REPO_ROOT="$REPO" "$REPO/bin/tick") resolves to the real harness bin/tick while
    92	# keeping all events in $REPO/.tick/ (not the harness). Node's require() follows the
    93	# symlink's real path for src/ resolution, so a wrapper shell script is safer than a symlink.
    94	cat > "$REPO/bin/tick" <<TICK_WRAPPER
    95	#!/usr/bin/env bash
    96	TICK_REPO_ROOT="$REPO" exec node "$HARNESS/bin/tick" "\$@"
    97	TICK_WRAPPER
    98	chmod +x "$REPO/bin/tick"
    99	
   100	# --- Seed the relay task in the isolated repo's .tick/ ---
   101	TASK="RELAY-SELF-SUFFICIENCY-$$"
   102	TICK_REPO_ROOT="$REPO" "$TICK" log task.created "$TASK" --agent claude-a >/dev/null
   103	TICK_REPO_ROOT="$REPO" "$TICK" claim "$TASK" --agent claude-a --paths relay.md >/dev/null
   104	TICK_REPO_ROOT="$REPO" "$TICK" release "$TASK" --agent claude-a --to "$LIVE_AGENT_ID" >/dev/null
   105	
   106	# --- Drive one real headless agent turn ---
   107	AGY_LOG="$WORK/agent-turn.log"
   108	turn_rc=0
   109	
   110	# Run in a subshell cd'd to $REPO so the agent's relative paths (relay.md) resolve correctly
   111	# against the isolated repo, not the harness CWD. This mirrors RELAY_WORKTREE_ISOLATION=1
   112	# behavior (CWD = target repo) but without the worktree bug (GH-22).
   113	(
   114	  cd "$REPO"
   115	  if [ "$LIVE_AGENT_ID" = "agy" ]; then
   116	    RELAY_AGENT="$LIVE_AGENT_ID" RELAY_FILE="$RELAY_FILE" RELAY_TASK="$TASK" \
   117	      AGY_AGENT="$LIVE_AGENT_ID" AGY_BIN="$LIVE_AGENT_BIN" \
   118	      AGY_TURN_ROOT="$REPO" AGY_LOG="$AGY_LOG" \
   119	      RELAY_WORKTREE_ISOLATION=0 TICK_REPO_ROOT="$REPO" \
   120	      bash "$HARNESS/relay-automation/agy-turn.sh"
   121	  else
   122	    RELAY_AGENT="$LIVE_AGENT_ID" RELAY_FILE="$RELAY_FILE" RELAY_TASK="$TASK" \
   123	      CODEX_AGENT="$LIVE_AGENT_ID" CODEX_BIN="$LIVE_AGENT_BIN" \
   124	      CODEX_TURN_ROOT="$REPO" CODEX_LOG="$AGY_LOG" \
   125	      RELAY_WORKTREE_ISOLATION=0 TICK_REPO_ROOT="$REPO" \
   126	      bash "$HARNESS/relay-automation/codex-turn.sh"
   127	  fi
   128	) >/dev/null 2>&1 || turn_rc=$?
   129	
   130	# --- Assertion (C): shim exited 0 (no off-allowlist edit, no agent crash) ---
   131	if [ "$turn_rc" -eq 0 ]; then
   132	  pass "(C) shim exit 0 — no off-allowlist edits, no agent failure"
   133	else
   134	  fail "(C) $LIVE_AGENT_ID shim exited $turn_rc"
   135	  if [ -s "$AGY_LOG" ]; then
   136	    echo "  --- agent transcript (tail 20 lines) ---" >&2
   137	    tail -20 "$AGY_LOG" >&2
   138	  fi
   139	fi
   140	
   141	# --- Assertion (A): relay file was modified AND task is no longer claimed by claude-a ---
   142	relay_commit_count="$(git -C "$REPO" log --oneline relay.md 2>/dev/null | wc -l | tr -d ' ')"
   143	task_claimer="$(TICK_REPO_ROOT="$REPO" "$TICK" info "$TASK" 2>/dev/null | grep '^claimer:' | awk '{print $2}' || true)"
   144	if [ "$relay_commit_count" -gt 1 ] && [ "${task_claimer:-none}" != "claude-a" ]; then
   145	  pass "(A) agent claimed token + wrote relay file (commit observed, token moved from claude-a)"
   146	else
   147	  if [ "$relay_commit_count" -le 1 ]; then
   148	    fail "(A) relay file not modified — agent may have failed to claim/release (path assumptions wrong)"
   149	  else
   150	    fail "(A) relay file modified but token still claimed by claude-a — agent did not complete the handoff"
   151	  fi
   152	  echo "  Diagnostic: the TAKE YOUR TURN block's tick command may need adjustment." >&2
   153	  echo "  Fix: update test/fixtures/minimal-relay.md and commit the diff." >&2
   154	fi
   155	
   156	# Read the Log section for field assertions
   157	log_section=""
   158	if [ -f "$RELAY_FILE" ]; then
   159	  log_section="$(sed -e '1,/^## Log/d' "$RELAY_FILE")"
   160	fi
   161	
   162	# --- Assertion (B1): VERDICT: line present and valid ---
   163	if grep -qE '^VERDICT: (PASS|FAIL|PARKED)$' <<<"$(echo "$log_section")"; then
   164	  pass "(B1) VERDICT: field present and valid"
   165	else
   166	  verdict_val="$(echo "$log_section" | grep -E '^VERDICT:' | head -1 || true)"
   167	  fail "(B1) VERDICT: field missing or invalid (found: '${verdict_val:-<none>}')"
   168	  echo "  Diagnostic: agent did not write a VERDICT: line in the log block." >&2
   169	  echo "  Fix: add clearer VERDICT: instruction to test/fixtures/minimal-relay.md." >&2
   170	fi
   171	
   172	# --- Assertion (B2): Basis: line present and non-empty ---
   173	if grep -qE '^Basis: .+' <<<"$(echo "$log_section")"; then
   174	  pass "(B2) Basis: field present and non-empty"
   175	else
   176	  basis_val="$(echo "$log_section" | grep -E '^Basis:' | head -1 || true)"
   177	  fail "(B2) Basis: field missing or empty (found: '${basis_val:-<none>}')"
   178	  echo "  Diagnostic: agent did not write a Basis: line in the log block." >&2
   179	  echo "  Fix: add clearer Basis: instruction to test/fixtures/minimal-relay.md." >&2
   180	fi
   181	
   182	echo ""
   183	echo "  relay-self-sufficiency: $PASS pass, $FAIL fail"
   184	[ "$FAIL" -eq 0 ] || exit 1
   620	    from proc_group import run_bounded
   621	
   622	    previous = committed_qualifications(repo_root)
   623	    pending = [meta for meta in metas if not any(
   624	        qualification_receipt_matches(repo_root, entry, meta) for entry in previous)]
   625	    if not pending:
   626	        return
   627	    check_porcelain_cleanliness(repo_root)
   628	    tested = subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=repo_root, text=True).strip()
   629	    for meta in pending:
   630	        landing = (meta.get("mergeCommit") or {}).get("oid", "")
   631	        if (meta.get("state") != "MERGED" or meta.get("baseRefName") != "development"
   632	                or not re.fullmatch(r"[0-9a-f]{40}", landing)
   633	                or subprocess.run(["git", "merge-base", "--is-ancestor", landing, tested],
   634	                                  cwd=repo_root, capture_output=True, check=False).returncode):
   635	            die(f"Qualification refuses {landing_label(meta)}: merge not in the tested development snapshot", code=6)
   636	    with tempfile.TemporaryDirectory(prefix="wave-qualification-") as temporary:
   637	        scratch = Path(temporary).resolve()
   638	        clone = scratch / "repo"
   639	        telemetry = clone / ".tick" / "telemetry"
   640	        # Reuse the harness environment contract, then isolate Git and runner controls.
   641	        env = {k: v for k, v in gate_env().items()
   642	               if not k.startswith(("GIT_", "RT_", "XYZ_VALIDATE_", "PYTEST_"))
   643	               and k not in ("XYZ_HARNESS_DB", "PYTHONPATH", "PYTHONHOME")}
   644	        config = scratch / "gitconfig"
   645	        config.write_text('[user]\nname = Qualification Fixture\nemail = qualification@example.invalid\n'
   646	                          '[init]\ndefaultBranch = main\n')
   647	        env.update(GIT_CONFIG_GLOBAL=str(config), GIT_CONFIG_NOSYSTEM="1",
   648	                   RELAY_SELF_SUFFICIENCY_SKIP="1", TICK_REPO_ROOT=str(clone))
   649	        def command(args, capture=False):
   650	            result = run_bounded(args, cwd=str(clone if clone.exists() else scratch), env=env, timeout=5400)
   651	            if not capture:
   652	                print(result.stdout, end="", flush=True)
   653	                print(result.stderr, end="", file=sys.stderr, flush=True)
   654	            if result.timed_out or result.rc != 0:
   655	                raise subprocess.CalledProcessError(124 if result.timed_out else result.rc, args,
   656	                                                    result.stdout, result.stderr)
   657	            return result
   658	        try:
   659	            # --no-local prevents object hardlinks/alternates as well as shared git metadata.
   660	            command(["git", "clone", "--no-local", "--quiet", repo_root, str(clone)])
   661	            command(["git", "checkout", "--quiet", "--detach", tested])
   662	            origin = subprocess.check_output(["git", "remote", "get-url", "origin"],
   663	                                             cwd=repo_root, text=True).strip()
   664	            command(["git", "remote", "set-url", "origin", origin])
   665	            before_config = command(["git", "config", "--local", "--list"], True).stdout
   666	            command(["python3", "-c", "import pytest"])
   667	            command(["npm", "ci"])
   668	            gate, expected, reason = select_qualification_gate(clone, pending, env)
   669	            log(f"Qualifying {len(pending)} landing(s) in integrated snapshot {tested} with "
   670	                f"`{gate}` ({reason})")
   671	            validation = command(["bash", *gate.split()])
   672	            if (command(["git", "rev-parse", "HEAD"], True).stdout.strip() != tested
   673	                    or command(["git", "status", "--porcelain"], True).stdout.strip()
   674	                    or command(["git", "config", "--local", "--list"], True).stdout != before_config):
   675	                die("Qualification clone identity/content changed under the suite", code=6)
   676	            # Suites may launch nested validator probes. Bind proof to the exact
   677	            # process we launched, not another passing run in the telemetry directory.
   678	            files = list(telemetry.glob(f"validate-sequential-*-{validation.pgid}.jsonl"))
   679	            if len(files) != 1:
   680	                die("Qualification requires exactly one retained validation run", code=6)
     1	#!/usr/bin/env bash
     2	# gate-env.sh — GH-441 Phase 2. SOURCE this at the top of any `--pre-advance-cmd`.
     3	#
     4	#   . "$(dirname "$0")/relay-automation/gate-env.sh"      # or an absolute path
     5	#
     6	# It clears the variables a live marathon exports that would otherwise flip a suite's verdict, so the
     7	# gate reports on the change under review rather than on its parent.
     8	#
     9	# WHY A HELPER AND NOT A COPIED PROLOGUE
    10	# `validate.sh` used to carry its own hardcoded `unset` line. That worked only for validate.sh: any
    11	# custom gate that did not copy it was silently wrong, and one did — a hand-written gate on
    12	# 2026-08-07 reproduced test/oracle-guard.sh's failure because it inherited ALLOW_PATHS (ambient →
    13	# 10 pass/1 fail; unset → 11/0). It cost two marathon rounds and three clean standalone re-runs
    14	# before the variable was found. A gate cannot be expected to remember a list it does not own.
    15	#
    16	# SINGLE SOURCE OF TRUTH
    17	# The list comes from utils/py/gate_env.py, the same registry `marathon_drive._gate_env()` uses, so
    18	# the shell side and the driver side cannot drift. Do not inline the names here — a second copy of
    19	# the list is the defect this replaces. `test/gh441-gate-env-contract.sh` asserts the two agree.
    20	#
    21	# NOT SCRUBBED: RELAY_DRIVER_LOCKED. Nested drivers need it SET; suites asserting real lock
    22	# acquisition need it UNSET; no global value is correct. Scrubbing it was landed and reverted
    23	# (2026-08-07). The two suites that need it clear do so themselves — GH-441 Phase 1.
    24	
    25	# Resolve the harness root from this script's own location, following symlinks, so sourcing works
    26	# from any CWD and from a vendored .xyz/ install. No machine path is ever hardcoded.
    27	# Every scratch name here is `_ge_`-prefixed and unset at the end: this file is SOURCED, so a bare
    28	# `_src` or `_hp_lib` would clobber the caller's own (GH-730 review finding).
    29	_ge_src="${BASH_SOURCE[0]:-$0}"
    30	while [ -h "$_ge_src" ] || [ -L "$_ge_src" ]; do
    31	  _ge_ldir="$(cd -P "$(dirname "$_ge_src")" >/dev/null 2>&1 && pwd)"
    32	  _ge_src="$(readlink "$_ge_src")"
    33	  case "$_ge_src" in /*) ;; *) _ge_src="$_ge_ldir/$_ge_src" ;; esac
    34	done
    35	_ge_dir="$(cd -P "$(dirname "$_ge_src")" >/dev/null 2>&1 && pwd)"
    36	
    37	_ge_hp_lib="$_ge_dir/harness-paths.sh"
    38	if [ -f "$_ge_hp_lib" ]; then
    39	  # shellcheck source=relay-automation/harness-paths.sh
    40	  . "$_ge_hp_lib"
    41	fi
    42	_ge_root="$(cd -P "$_ge_dir/.." && pwd)"
    43	_ge_py="$_ge_root/utils/py/gate_env.py"
    44	
    45	if [ -r "$_ge_py" ]; then
    46	  # One name per line from the registry, applied by an explicit loop.
    47	  #
    48	  # The first draft of this file instead shell-evaluated a generated `unset A B C` line. The GH-64
    49	  # security gate rejected it as `eval-unsanitized` and was right to: nothing should hand generated
    50	  # text to the shell for interpretation when a loop does the same job. This form has no shell
    51	  # evaluation at all, and validates each name against a strict pattern before acting on it.
    52	  #
    53	  # (The rewrite of this very comment was also a finding: the scanner matches the four-letter
    54	  # builtin anywhere in the file, comments included, so the earlier wording tripped it while the
    55	  # code beneath was already clean.)
    56	  # Read one name per line. A `for _ge_n in $_ge_names` loop would be a bug in any shell that does
    57	  # NOT word-split unquoted parameters — zsh does not, so it would pass the whole newline-joined blob
    58	  # as a single name and fail with `invalid parameter name` (observed 2026-08-07). A heredoc-fed
    59	  # `while read` behaves identically in bash and zsh, and unlike a pipe it keeps the loop in the
    60	  # CURRENT shell so the unsets survive.
    61	  _ge_names="$(python3 "$_ge_py" --list-scrubbed 2>/dev/null || true)"
    62	  if [ -n "$_ge_names" ]; then
    63	    while IFS= read -r _ge_n; do
    64	      [ -n "$_ge_n" ] || continue
    65	      case "$_ge_n" in
    66	        [A-Z_][A-Z_0-9]*) unset "$_ge_n" ;;
    67	        *) printf 'gate-env.sh: refusing to unset malformed name from the registry: %s\n' "$_ge_n" >&2 ;;
    68	      esac
    69	    done <<GATE_ENV_NAMES
    70	$_ge_names
    71	GATE_ENV_NAMES
    72	  else
    73	    # Fail LOUDLY rather than leaving the gate contaminated and looking clean. A gate that silently
    74	    # skips its own scrub is the exact shape GH-441 is about: a check reporting a verdict on a
    75	    # question it never asked.
    76	    printf 'gate-env.sh: could not read the scrub list from %s — refusing to run a gate with an ungoverned environment.\n' "$_ge_py" >&2
    77	    printf 'gate-env.sh: (this guard exists because a silently-unscrubbed gate reports its PARENT'\''s failures as the change'\''s own — see GH-441.)\n' >&2
    78	    return 1 2>/dev/null || exit 1
    79	  fi
    80	else
    81	  printf 'gate-env.sh: %s not found — refusing to run a gate with an ungoverned environment (GH-441).\n' "$_ge_py" >&2
    82	  return 1 2>/dev/null || exit 1
    83	fi
    84	
    85	unset _ge_src _ge_ldir _ge_dir _ge_hp_lib _ge_root _ge_py _ge_names _ge_n
    86	
    87	# GH-730: no bytecode into the tree from a gate run. Suites import repo modules directly
    88	# (importlib in test/agent-chorus.sh, the unittest files under test/), and every such import
    89	# wrote `__pycache__/` under skills/*/scripts and utils/py. Those caches are gitignored, so
    90	# they outlive the rename or removal of the directory that held them — `skills/agent2agent/`
    91	# survived the #193 rename as an ignored shell for a month and turned the pre-push gate red.
    92	# The relay shims already set this for reviewer turns (GH-682); the gate gets the same rule.
    93	export PYTHONDONTWRITEBYTECODE=1
TESTS-RESULTS/2026-09-14+GH-613/prepush-superseded.log:375:[parallel] relay-self-sufficiency.sh rc=0
TESTS-RESULTS/2026-09-14+GH-613/prepush-superseded.log:902:  + relay-self-sufficiency.sh
TESTS-RESULTS/2026-09-25+GH-823/baseline-9ab269c8-ci-local-gate-record.txt:403:relay-self-sufficiency.sh	pass
TESTS-RESULTS/2026-09-25+GH-823/push-gate-f8320d1e.log:430:[parallel] relay-self-sufficiency.sh rc=0
TESTS-RESULTS/2026-09-25+GH-823/push-gate-f8320d1e.log:483:  relay-self-sufficiency.sh  215.770  0
TESTS-RESULTS/2026-09-25+GH-823/push-gate-f8320d1e.log:911:  + relay-self-sufficiency.sh
TESTS-RESULTS/2026-09-25+GH-831/push-gate-7338ca94.log:421:[parallel] relay-self-sufficiency.sh rc=0
TESTS-RESULTS/2026-09-25+GH-831/push-gate-7338ca94.log:475:  relay-self-sufficiency.sh  164.360  0
TESTS-RESULTS/2026-09-25+GH-831/push-gate-7338ca94.log:894:  + relay-self-sufficiency.sh
TESTS-RESULTS/2026-09-25+GH-831/suite-map.tsv:17:gh415-guard-hook-entrypoints.sh	CORE	2.3		R6: the skill-first guard hook covers 6 of 12 Tier-A entrypoints — derive the set from AGE	core=10	CORE
TESTS-RESULTS/2026-09-25+GH-831/suite-map.tsv:122:gh457-gate-tiers.sh	CORE	12.3		Model aliasing & canonicalization: system spec, verified behaviors, gateway-blindness defe	core=5	CORE
TESTS-RESULTS/2026-09-25+GH-831/suite-map.tsv:269:gh429-wave-reconcile-vendored-observe.sh	SMALL:prs	2.3	status	wave_reconcile: three residual gaps on a vendored observe-mode repo — dashboard root, PDDA	core=3 pdda=2 prs=5	SMALL
TESTS-RESULTS/2026-09-25+GH-831/suite-map.tsv:304:xyz-sync-check.sh	CORE	2.3			core=4	CORE
TESTS-RESULTS/2026-09-25+GH-831/suite-map.tsv:353:gh568-releases-md-retired.sh	SMALL:prs	2.3		feat(ledger): end-to-end retirement of RELEASES.md in favor of releases.db	core=1 prs=5	SMALL
TESTS-RESULTS/2026-09-25+GH-831/suite-map.tsv:394:relay-self-sufficiency.sh	CORE	0.0			core=3	CORE
TESTS-RESULTS/2026-09-25+GH-831/small-run-9ecf2071-telemetry.jsonl:3:{"v":1,"ts_ms":1790395309758,"run":"9ecf2071b-62665","runner":"validate","event":"suite","lane":"sequential","name":"gh308-frozen-twin-guard.sh","queued_ms":1790395238363,"started_ms":1790395304628,"ended_ms":1790395309751,"duration_ms":5123,"rc":0,"worker":62665,"out_bytes":0,"out_sha256":"-","skip_lines":0}
TESTS-RESULTS/2026-09-25+GH-831/small-run-9ecf2071-telemetry.jsonl:4:{"v":1,"ts_ms":1790395310107,"run":"9ecf2071b-62665","runner":"validate","event":"suite","lane":"sequential","name":"gh777-inventory-ratchet.sh","queued_ms":1790395238363,"started_ms":1790395309767,"ended_ms":1790395310100,"duration_ms":333,"rc":0,"worker":62665,"out_bytes":0,"out_sha256":"-","skip_lines":0}
TESTS-RESULTS/2026-09-25+GH-831/small-run-9ecf2071-telemetry.jsonl:5:{"v":1,"ts_ms":1790395312242,"run":"9ecf2071b-62665","runner":"validate","event":"suite","lane":"sequential","name":"gh400-acceptance-fidelity.sh","queued_ms":1790395238363,"started_ms":1790395310116,"ended_ms":1790395312235,"duration_ms":2119,"rc":0,"worker":62665,"out_bytes":0,"out_sha256":"-","skip_lines":0}
TESTS-RESULTS/2026-09-25+GH-831/small-run-9ecf2071-telemetry.jsonl:6:{"v":1,"ts_ms":1790395313531,"run":"9ecf2071b-62665","runner":"validate","event":"suite","lane":"sequential","name":"gh400-source-url.sh","queued_ms":1790395238363,"started_ms":1790395312253,"ended_ms":1790395313523,"duration_ms":1270,"rc":0,"worker":62665,"out_bytes":0,"out_sha256":"-","skip_lines":0}
TESTS-RESULTS/2026-09-25+GH-831/small-run-9ecf2071-telemetry.jsonl:7:{"v":1,"ts_ms":1790395317354,"run":"9ecf2071b-62665","runner":"validate","event":"suite","lane":"sequential","name":"litmus-release.sh","queued_ms":1790395238363,"started_ms":1790395313539,"ended_ms":1790395317346,"duration_ms":3807,"rc":0,"worker":62665,"out_bytes":0,"out_sha256":"-","skip_lines":0}
TESTS-RESULTS/2026-09-25+GH-831/small-run-9ecf2071-telemetry.jsonl:8:{"v":1,"ts_ms":1790395318862,"run":"9ecf2071b-62665","runner":"validate","event":"suite","lane":"sequential","name":"gh422-backfill-source-url.sh","queued_ms":1790395238363,"started_ms":1790395317363,"ended_ms":1790395318855,"duration_ms":1492,"rc":0,"worker":62665,"out_bytes":0,"out_sha256":"-","skip_lines":0}
TESTS-RESULTS/2026-09-25+GH-831/small-run-9ecf2071-telemetry.jsonl:9:{"v":1,"ts_ms":1790395322105,"run":"9ecf2071b-62665","runner":"validate","event":"suite","lane":"sequential","name":"gh425-source-url-slug.sh","queued_ms":1790395238363,"started_ms":1790395318872,"ended_ms":1790395322098,"duration_ms":3226,"rc":0,"worker":62665,"out_bytes":0,"out_sha256":"-","skip_lines":0}
TESTS-RESULTS/2026-09-25+GH-831/small-run-9ecf2071-telemetry.jsonl:10:{"v":1,"ts_ms":1790395323003,"run":"9ecf2071b-62665","runner":"validate","event":"suite","lane":"sequential","name":"gh448-driver-lock-resolver.sh","queued_ms":1790395238363,"started_ms":1790395322114,"ended_ms":1790395322995,"duration_ms":881,"rc":0,"worker":62665,"out_bytes":0,"out_sha256":"-","skip_lines":0}
TESTS-RESULTS/2026-09-25+GH-831/small-run-9ecf2071-telemetry.jsonl:11:{"v":1,"ts_ms":1790395327028,"run":"9ecf2071b-62665","runner":"validate","event":"suite","lane":"sequential","name":"nightwatch-release.sh","queued_ms":1790395238363,"started_ms":1790395323013,"ended_ms":1790395327021,"duration_ms":4008,"rc":0,"worker":62665,"out_bytes":0,"out_sha256":"-","skip_lines":0}
TESTS-RESULTS/2026-09-25+GH-831/small-run-9ecf2071-telemetry.jsonl:12:{"v":1,"ts_ms":1790395328100,"run":"9ecf2071b-62665","runner":"validate","event":"suite","lane":"sequential","name":"meter-release.sh","queued_ms":1790395238363,"started_ms":1790395327037,"ended_ms":1790395328093,"duration_ms":1056,"rc":0,"worker":62665,"out_bytes":0,"out_sha256":"-","skip_lines":0}
TESTS-RESULTS/2026-09-25+GH-831/small-run-9ecf2071-telemetry.jsonl:13:{"v":1,"ts_ms":1790395330217,"run":"9ecf2071b-62665","runner":"validate","event":"suite","lane":"sequential","name":"ballast-release.sh","queued_ms":1790395238363,"started_ms":1790395328110,"ended_ms":1790395330209,"duration_ms":2099,"rc":0,"worker":62665,"out_bytes":0,"out_sha256":"-","skip_lines":0}
TESTS-RESULTS/2026-09-25+GH-831/small-run-9ecf2071-telemetry.jsonl:14:{"v":1,"ts_ms":1790395685216,"run":"9ecf2071b-62665","runner":"validate","event":"suite","lane":"sequential","name":"gh549-work-events.sh","queued_ms":1790395238363,"started_ms":1790395330226,"ended_ms":1790395685209,"duration_ms":354983,"rc":0,"worker":62665,"out_bytes":0,"out_sha256":"-","skip_lines":0}
TESTS-RESULTS/2026-09-25+GH-831/small-run-9ecf2071-telemetry.jsonl:15:{"v":1,"ts_ms":1790395693769,"run":"9ecf2071b-62665","runner":"validate","event":"suite","lane":"sequential","name":"gh646-status-label.sh","queued_ms":1790395238363,"started_ms":1790395685225,"ended_ms":1790395693762,"duration_ms":8537,"rc":0,"worker":62665,"out_bytes":0,"out_sha256":"-","skip_lines":0}
TESTS-RESULTS/2026-09-25+GH-831/small-run-9ecf2071-telemetry.jsonl:16:{"v":1,"ts_ms":1790395695279,"run":"9ecf2071b-62665","runner":"validate","event":"suite","lane":"sequential","name":"gh1-fixture-guard.sh","queued_ms":1790395238363,"started_ms":1790395693778,"ended_ms":1790395695272,"duration_ms":1494,"rc":0,"worker":62665,"out_bytes":0,"out_sha256":"-","skip_lines":0}
TESTS-RESULTS/2026-09-25+GH-831/small-run-9ecf2071-telemetry.jsonl:17:{"v":1,"ts_ms":1790395696866,"run":"9ecf2071b-62665","runner":"validate","event":"suite","lane":"sequential","name":"gh1-adoption-guard.sh","queued_ms":1790395238363,"started_ms":1790395695288,"ended_ms":1790395696858,"duration_ms":1570,"rc":0,"worker":62665,"out_bytes":0,"out_sha256":"-","skip_lines":0}
TESTS-RESULTS/2026-09-25+GH-831/small-run-9ecf2071-telemetry.jsonl:18:{"v":1,"ts_ms":1790395698018,"run":"9ecf2071b-62665","runner":"validate","event":"suite","lane":"sequential","name":"gh139-pipe-grep-guard.sh","queued_ms":1790395238363,"started_ms":1790395696875,"ended_ms":1790395698011,"duration_ms":1136,"rc":0,"worker":62665,"out_bytes":0,"out_sha256":"-","skip_lines":0}
TESTS-RESULTS/2026-09-25+GH-831/small-run-9ecf2071-telemetry.jsonl:19:{"v":1,"ts_ms":1790395699567,"run":"9ecf2071b-62665","runner":"validate","event":"suite","lane":"sequential","name":"gh168-wave-reconcile-scope.sh","queued_ms":1790395238363,"started_ms":1790395698027,"ended_ms":1790395699558,"duration_ms":1531,"rc":0,"worker":62665,"out_bytes":0,"out_sha256":"-","skip_lines":0}
TESTS-RESULTS/2026-09-25+GH-831/small-run-9ecf2071-telemetry.jsonl:20:{"v":1,"ts_ms":1790395699746,"run":"9ecf2071b-62665","runner":"validate","event":"suite","lane":"sequential","name":"gh184-no-tracked-scratch.sh","queued_ms":1790395238363,"started_ms":1790395699577,"ended_ms":1790395699738,"duration_ms":161,"rc":0,"worker":62665,"out_bytes":0,"out_sha256":"-","skip_lines":0}
TESTS-RESULTS/2026-09-25+GH-831/small-run-9ecf2071-telemetry.jsonl:21:{"v":1,"ts_ms":1790395703806,"run":"9ecf2071b-62665","runner":"validate","event":"suite","lane":"sequential","name":"gh202-wave-reconcile-issue-state.sh","queued_ms":1790395238363,"started_ms":1790395699756,"ended_ms":1790395703797,"duration_ms":4041,"rc":0,"worker":62665,"out_bytes":0,"out_sha256":"-","skip_lines":0}
TESTS-RESULTS/2026-09-25+GH-831/small-run-9ecf2071-telemetry.jsonl:22:{"v":1,"ts_ms":1790395704957,"run":"9ecf2071b-62665","runner":"validate","event":"suite","lane":"sequential","name":"gh232-wave-reconcile-multiphase.sh","queued_ms":1790395238363,"started_ms":1790395703815,"ended_ms":1790395704949,"duration_ms":1134,"rc":0,"worker":62665,"out_bytes":0,"out_sha256":"-","skip_lines":0}
TESTS-RESULTS/2026-09-25+GH-831/small-run-9ecf2071-telemetry.jsonl:23:{"v":1,"ts_ms":1790395705102,"run":"9ecf2071b-62665","runner":"validate","event":"suite","lane":"sequential","name":"releases-skill.sh","queued_ms":1790395238363,"started_ms":1790395704966,"ended_ms":1790395705094,"duration_ms":128,"rc":0,"worker":62665,"out_bytes":0,"out_sha256":"-","skip_lines":0}
TESTS-RESULTS/2026-09-25+GH-831/small-run-9ecf2071-telemetry.jsonl:24:{"v":1,"ts_ms":1790395709157,"run":"9ecf2071b-62665","runner":"validate","event":"suite","lane":"sequential","name":"gh103-timeline-exporter.sh","queued_ms":1790395238363,"started_ms":1790395705113,"ended_ms":1790395709149,"duration_ms":4036,"rc":0,"worker":62665,"out_bytes":0,"out_sha256":"-","skip_lines":0}
TESTS-RESULTS/2026-09-25+GH-831/small-run-9ecf2071-telemetry.jsonl:25:{"v":1,"ts_ms":1790395709808,"run":"9ecf2071b-62665","runner":"validate","event":"suite","lane":"sequential","name":"gh75-dashboard.sh","queued_ms":1790395238363,"started_ms":1790395709166,"ended_ms":1790395709801,"duration_ms":635,"rc":0,"worker":62665,"out_bytes":0,"out_sha256":"-","skip_lines":0}
TESTS-RESULTS/2026-09-25+GH-831/small-run-9ecf2071-telemetry.jsonl:26:{"v":1,"ts_ms":1790395732203,"run":"9ecf2071b-62665","runner":"validate","event":"suite","lane":"sequential","name":"gh32-releases-app.sh","queued_ms":1790395238363,"started_ms":1790395709817,"ended_ms":1790395732195,"duration_ms":22378,"rc":0,"worker":62665,"out_bytes":0,"out_sha256":"-","skip_lines":0}
TESTS-RESULTS/2026-09-25+GH-831/small-run-9ecf2071-telemetry.jsonl:27:{"v":1,"ts_ms":1790395732933,"run":"9ecf2071b-62665","runner":"validate","event":"suite","lane":"sequential","name":"gh32-releases-artifacts.sh","queued_ms":1790395238363,"started_ms":1790395732213,"ended_ms":1790395732926,"duration_ms":713,"rc":0,"worker":62665,"out_bytes":0,"out_sha256":"-","skip_lines":0}
TESTS-RESULTS/2026-09-25+GH-831/small-run-9ecf2071-telemetry.jsonl:28:{"v":1,"ts_ms":1790395739249,"run":"9ecf2071b-62665","runner":"validate","event":"suite","lane":"sequential","name":"gh53-releases-merge-resolve.sh","queued_ms":1790395238363,"started_ms":1790395732943,"ended_ms":1790395739241,"duration_ms":6298,"rc":0,"worker":62665,"out_bytes":0,"out_sha256":"-","skip_lines":0}
TESTS-RESULTS/2026-09-25+GH-831/small-run-9ecf2071-telemetry.jsonl:29:{"v":1,"ts_ms":1790395742877,"run":"9ecf2071b-62665","runner":"validate","event":"suite","lane":"sequential","name":"gh54-merged-dump-refusals.sh","queued_ms":1790395238363,"started_ms":1790395739260,"ended_ms":1790395742870,"duration_ms":3610,"rc":0,"worker":62665,"out_bytes":0,"out_sha256":"-","skip_lines":0}
TESTS-RESULTS/2026-09-25+GH-831/small-run-9ecf2071-telemetry.jsonl:30:{"v":1,"ts_ms":1790395752856,"run":"9ecf2071b-62665","runner":"validate","event":"suite","lane":"sequential","name":"gh57-releases-fuzz.sh","queued_ms":1790395238363,"started_ms":1790395742886,"ended_ms":1790395752848,"duration_ms":9962,"rc":0,"worker":62665,"out_bytes":0,"out_sha256":"-","skip_lines":0}
TESTS-RESULTS/2026-09-25+GH-831/small-run-9ecf2071-telemetry.jsonl:31:{"v":1,"ts_ms":1790395763575,"run":"9ecf2071b-62665","runner":"validate","event":"suite","lane":"sequential","name":"gh57-live-merge-resolve.sh","queued_ms":1790395238363,"started_ms":1790395752865,"ended_ms":1790395763567,"duration_ms":10702,"rc":0,"worker":62665,"out_bytes":0,"out_sha256":"-","skip_lines":0}
TESTS-RESULTS/2026-09-25+GH-831/small-run-9ecf2071-telemetry.jsonl:32:{"v":1,"ts_ms":1790395771497,"run":"9ecf2071b-62665","runner":"validate","event":"suite","lane":"sequential","name":"gh69-roadmap-shadow.sh","queued_ms":1790395238363,"started_ms":1790395763584,"ended_ms":1790395771490,"duration_ms":7906,"rc":0,"worker":62665,"out_bytes":0,"out_sha256":"-","skip_lines":0}
TESTS-RESULTS/2026-09-25+GH-831/small-run-9ecf2071-telemetry.jsonl:33:{"v":1,"ts_ms":1790395773934,"run":"9ecf2071b-62665","runner":"validate","event":"suite","lane":"sequential","name":"gh351-manifest-unship.sh","queued_ms":1790395238363,"started_ms":1790395771507,"ended_ms":1790395773927,"duration_ms":2420,"rc":0,"worker":62665,"out_bytes":0,"out_sha256":"-","skip_lines":0}
TESTS-RESULTS/2026-09-25+GH-831/small-run-9ecf2071-telemetry.jsonl:34:{"v":1,"ts_ms":1790395777229,"run":"9ecf2071b-62665","runner":"validate","event":"suite","lane":"sequential","name":"gh360-scoped-receipt-chain-rebuild.sh","queued_ms":1790395238363,"started_ms":1790395773944,"ended_ms":1790395777221,"duration_ms":3277,"rc":0,"worker":62665,"out_bytes":0,"out_sha256":"-","skip_lines":0}
TESTS-RESULTS/2026-09-25+GH-831/small-run-9ecf2071-telemetry.jsonl:35:{"v":1,"ts_ms":1790395779118,"run":"9ecf2071b-62665","runner":"validate","event":"suite","lane":"sequential","name":"gh349-releases-roadmap-vendored.sh","queued_ms":1790395238363,"started_ms":1790395777239,"ended_ms":1790395779110,"duration_ms":1871,"rc":0,"worker":62665,"out_bytes":0,"out_sha256":"-","skip_lines":0}
TESTS-RESULTS/2026-09-25+GH-831/small-run-9ecf2071-telemetry.jsonl:36:{"v":1,"ts_ms":1790395780941,"run":"9ecf2071b-62665","runner":"validate","event":"suite","lane":"sequential","name":"gh429-wave-reconcile-vendored-observe.sh","queued_ms":1790395238363,"started_ms":1790395779127,"ended_ms":1790395780934,"duration_ms":1807,"rc":0,"worker":62665,"out_bytes":0,"out_sha256":"-","skip_lines":0}
TESTS-RESULTS/2026-09-25+GH-831/small-run-9ecf2071-telemetry.jsonl:37:{"v":1,"ts_ms":1790395781749,"run":"9ecf2071b-62665","runner":"validate","event":"suite","lane":"sequential","name":"gh358-wave-reconcile-vendored-paths.sh","queued_ms":1790395238363,"started_ms":1790395780951,"ended_ms":1790395781741,"duration_ms":790,"rc":0,"worker":62665,"out_bytes":0,"out_sha256":"-","skip_lines":0}
TESTS-RESULTS/2026-09-25+GH-831/small-run-9ecf2071-telemetry.jsonl:38:{"v":1,"ts_ms":1790395783647,"run":"9ecf2071b-62665","runner":"validate","event":"suite","lane":"sequential","name":"gh32-release-target-advisory.sh","queued_ms":1790395238363,"started_ms":1790395781758,"ended_ms":1790395783639,"duration_ms":1881,"rc":0,"worker":62665,"out_bytes":0,"out_sha256":"-","skip_lines":0}
TESTS-RESULTS/2026-09-25+GH-831/small-run-9ecf2071-telemetry.jsonl:39:{"v":1,"ts_ms":1790395786371,"run":"9ecf2071b-62665","runner":"validate","event":"suite","lane":"sequential","name":"gh39-releases-project-sync.sh","queued_ms":1790395238363,"started_ms":1790395783656,"ended_ms":1790395786363,"duration_ms":2707,"rc":0,"worker":62665,"out_bytes":0,"out_sha256":"-","skip_lines":0}
TESTS-RESULTS/2026-09-25+GH-831/small-run-9ecf2071-telemetry.jsonl:40:{"v":1,"ts_ms":1790395801005,"run":"9ecf2071b-62665","runner":"validate","event":"suite","lane":"sequential","name":"relay-target-root.sh","queued_ms":1790395238363,"started_ms":1790395786380,"ended_ms":1790395800997,"duration_ms":14617,"rc":0,"worker":62665,"out_bytes":0,"out_sha256":"-","skip_lines":0}
TESTS-RESULTS/2026-09-25+GH-831/small-run-9ecf2071-telemetry.jsonl:41:{"v":1,"ts_ms":1790395805036,"run":"9ecf2071b-62665","runner":"validate","event":"suite","lane":"sequential","name":"relay-target-root-paths.sh","queued_ms":1790395238363,"started_ms":1790395801014,"ended_ms":1790395805028,"duration_ms":4014,"rc":0,"worker":62665,"out_bytes":0,"out_sha256":"-","skip_lines":0}
TESTS-RESULTS/2026-09-25+GH-831/small-run-9ecf2071-telemetry.jsonl:42:{"v":1,"ts_ms":1790395806253,"run":"9ecf2071b-62665","runner":"validate","event":"suite","lane":"sequential","name":"relay-target-root-relayfile.sh","queued_ms":1790395238363,"started_ms":1790395805045,"ended_ms":1790395806246,"duration_ms":1201,"rc":0,"worker":62665,"out_bytes":0,"out_sha256":"-","skip_lines":0}
TESTS-RESULTS/2026-09-25+GH-831/small-run-9ecf2071-telemetry.jsonl:43:{"v":1,"ts_ms":1790395810372,"run":"9ecf2071b-62665","runner":"validate","event":"suite","lane":"sequential","name":"relay-target-root-newfile.sh","queued_ms":1790395238363,"started_ms":1790395806262,"ended_ms":1790395810364,"duration_ms":4102,"rc":0,"worker":62665,"out_bytes":0,"out_sha256":"-","skip_lines":0}
TESTS-RESULTS/2026-09-25+GH-831/small-run-9ecf2071-telemetry.jsonl:44:{"v":1,"ts_ms":1790395843285,"run":"9ecf2071b-62665","runner":"validate","event":"suite","lane":"sequential","name":"gh649-pdda-migration.sh","queued_ms":1790395238363,"started_ms":1790395810381,"ended_ms":1790395843278,"duration_ms":32897,"rc":0,"worker":62665,"out_bytes":0,"out_sha256":"-","skip_lines":0}
TESTS-RESULTS/2026-09-25+GH-831/small-run-9ecf2071-telemetry.jsonl:45:{"v":1,"ts_ms":1790395848476,"run":"9ecf2071b-62665","runner":"validate","event":"suite","lane":"sequential","name":"pdda-changelog.sh","queued_ms":1790395238363,"started_ms":1790395843295,"ended_ms":1790395848469,"duration_ms":5174,"rc":0,"worker":62665,"out_bytes":0,"out_sha256":"-","skip_lines":0}
TESTS-RESULTS/2026-09-25+GH-831/small-run-9ecf2071-telemetry.jsonl:46:{"v":1,"ts_ms":1790395972635,"run":"9ecf2071b-62665","runner":"validate","event":"suite","lane":"sequential","name":"pdda-install-startup-docs.sh","queued_ms":1790395238363,"started_ms":1790395848485,"ended_ms":1790395972628,"duration_ms":124143,"rc":0,"worker":62665,"out_bytes":0,"out_sha256":"-","skip_lines":0}
TESTS-RESULTS/2026-09-25+GH-831/small-run-9ecf2071-telemetry.jsonl:47:{"v":1,"ts_ms":1790395977105,"run":"9ecf2071b-62665","runner":"validate","event":"suite","lane":"sequential","name":"pdda-roadmap-coverage.sh","queued_ms":1790395238363,"started_ms":1790395972644,"ended_ms":1790395977098,"duration_ms":4454,"rc":0,"worker":62665,"out_bytes":0,"out_sha256":"-","skip_lines":0}
TESTS-RESULTS/2026-09-25+GH-831/small-run-9ecf2071-telemetry.jsonl:48:{"v":1,"ts_ms":1790396042455,"run":"9ecf2071b-62665","runner":"validate","event":"suite","lane":"sequential","name":"pdda-repo-contract.sh","queued_ms":1790395238363,"started_ms":1790395977114,"ended_ms":1790396042448,"duration_ms":65334,"rc":0,"worker":62665,"out_bytes":0,"out_sha256":"-","skip_lines":0}
TESTS-RESULTS/2026-09-25+GH-831/small-run-9ecf2071-telemetry.jsonl:49:{"v":1,"ts_ms":1790396062883,"run":"9ecf2071b-62665","runner":"validate","event":"suite","lane":"sequential","name":"pdda-local-checks.sh","queued_ms":1790395238363,"started_ms":1790396042464,"ended_ms":1790396062875,"duration_ms":20411,"rc":0,"worker":62665,"out_bytes":0,"out_sha256":"-","skip_lines":0}
TESTS-RESULTS/2026-09-25+GH-831/small-run-9ecf2071-telemetry.jsonl:50:{"v":1,"ts_ms":1790396071140,"run":"9ecf2071b-62665","runner":"validate","event":"suite","lane":"sequential","name":"gh784-marathon-qa-gate.sh","queued_ms":1790395238363,"started_ms":1790396062892,"ended_ms":1790396071132,"duration_ms":8240,"rc":0,"worker":62665,"out_bytes":0,"out_sha256":"-","skip_lines":0}
TESTS-RESULTS/2026-09-25+GH-831/small-run-9ecf2071-telemetry.jsonl:51:{"v":1,"ts_ms":1790396075667,"run":"9ecf2071b-62665","runner":"validate","event":"suite","lane":"sequential","name":"gh284-p3-release-milestone.sh","queued_ms":1790395238363,"started_ms":1790396071150,"ended_ms":1790396075660,"duration_ms":4510,"rc":0,"worker":62665,"out_bytes":0,"out_sha256":"-","skip_lines":0}
TESTS-RESULTS/2026-09-25+GH-831/small-run-9ecf2071-telemetry.jsonl:52:{"v":1,"ts_ms":1790396077833,"run":"9ecf2071b-62665","runner":"validate","event":"suite","lane":"sequential","name":"gh284-p4-release-lanes.sh","queued_ms":1790395238363,"started_ms":1790396075676,"ended_ms":1790396077826,"duration_ms":2150,"rc":0,"worker":62665,"out_bytes":0,"out_sha256":"-","skip_lines":0}

codex
The reconcile run explicitly sets the skip flag itself; it does not inherit it from `ci.yml`. More significantly, the live suite copies a static fixture rather than generating a relay from `new-relay.sh`, so its coverage is narrower than the question assumes.

exec
/bin/zsh -lc "nl -ba test/fixtures/minimal-relay.md; rg -n 'TAKE YOUR TURN|VERDICT|Basis|minimal-relay|promotion|Promotion|checklist' relay-automation/new-relay.sh SOP.md test/relay-template.sh; rg --files PROJECT TESTS-RESULTS | rg '83[56]|self-sufficiency'; git log --format='%h %ad %s' --date=short -- test/fixtures/minimal-relay.md; git log -3 -p -- relay-automation/new-relay.sh" in /private/var/folders/z0/92pfvhnn06z2_7hnpdb4kkbw0000gn/T/consult-wt-92092-h1_gqux_
 succeeded in 0ms:
     1	# RELAY · self-sufficiency test
     2	
     3	NEXT: agy
     4	STATUS: In Progress
     5	
     6	## ▶ TAKE YOUR TURN — read this first
     7	
     8	You are the **Reviewer**, taking a single turn in this relay. No external files to read —
     9	everything you need is in this file and in the prompt you received.
    10	
    11	**Review criterion:** confirm that this relay file contains all three:
    12	1. A `NEXT:` header line (top of file)
    13	2. A `STATUS:` header line (top of file)
    14	3. A `## Log` section (bottom of this file)
    15	
    16	**Do this in order:**
    17	
    18	1. **Claim the relay token** — use the exact `tick claim` command from your prompt. The
    19	   `--paths` argument should point to this relay file.
    20	
    21	2. **Update the `STATUS:` header** at the top of this file to `STATUS: Approved`.
    22	
    23	3. **Append your verdict block after the `## Log` header at the very bottom of this file.**
    24	   Add the block as the last content in the file:
    25	
    26	   ```
    27	   ### <your-agent-id> review
    28	
    29	   VERDICT: PASS
    30	   Basis: textual only (NEXT:, STATUS:, ## Log all present in relay file)
    31	   ```
    32	
    33	   Use `VERDICT: FAIL` if any of the three items is missing; name the specific missing
    34	   item in `Basis:`.
    35	
    36	4. **Release the token** — use the exact `tick release` command from your prompt.
    37	
    38	**Stop.** One line to the operator: your agent id and verdict.
    39	
    40	## Log
rg: test/relay-template.sh: No such file or directory (os error 2)
relay-automation/new-relay.sh:6:# Emits a relay thread the harness can drive: NEXT:/STATUS: header, a "▶ TAKE YOUR TURN" block, a
relay-automation/new-relay.sh:74:## ▶ TAKE YOUR TURN — read this first (works for ANY agent: Claude, Codex, agy)
relay-automation/new-relay.sh:80:     (\`[Blocker]\`/\`[Should]\`/\`[Nit]\`/\`[Pass]\`), each with a concrete fix → set a **VERDICT**
relay-automation/new-relay.sh:81:     (exactly PASS, FAIL, or PARKED) and a **Basis** (explanation). **Review the whole file, not just the diff** (GH-268):
SOP.md:70:The promotion procedure is four DB/file steps on the RELEASES DB:
TESTS-RESULTS/2026-09-26+GH-836/baseline-gh549-top-gaps.txt
TESTS-RESULTS/2026-09-26+GH-836/baseline-gh436.out
TESTS-RESULTS/2026-09-26+GH-836/provenance.jsonl
TESTS-RESULTS/2026-09-26+GH-836/baseline-summary.log
TESTS-RESULTS/2026-09-26+GH-836/baseline-gh436-durations.out
TESTS-RESULTS/2026-09-26+GH-836/baseline-gh549.out
PROJECT/2-WORKING/GH-836-GATE-HOTSPOTS.md
TESTS-RESULTS/2026-09-26+GH-835/machine-specs.md
TESTS-RESULTS/2026-09-26+GH-835/profile-mdrive-summary.txt
TESTS-RESULTS/2026-09-26+GH-835/full-gate-b2c307b4.log
TESTS-RESULTS/2026-09-26+GH-835/profile-mdrive-stdout.log
TESTS-RESULTS/2026-09-26+GH-835/full-gate-b2c307b4-tmp-red.log
TESTS-RESULTS/2026-09-26+GH-835/profile-gh549-summary.txt
TESTS-RESULTS/2026-09-26+GH-835/profile-gh549-trace.log
TESTS-RESULTS/2026-09-26+GH-835/profile-mdrive-trace.log
TESTS-RESULTS/2026-09-26+GH-835/profile-gh549-stdout.log
TESTS-RESULTS/2026-09-26+GH-835/analyze-full-gate.txt
TESTS-RESULTS/2026-09-26+GH-835/gh436-pytest.log
TESTS-RESULTS/2026-09-26+GH-835/provenance.jsonl
TESTS-RESULTS/2026-09-26+GH-835/gate-telemetry-b2c307b4.jsonl
TESTS-RESULTS/2026-09-24+GH-591/wave-326e48121a6ac3e28362d25c0964dae99bbb203c/provenance.jsonl
TESTS-RESULTS/2026-09-24+GH-591/wave-326e48121a6ac3e28362d25c0964dae99bbb203c/validation.jsonl
git: warning: confstr() failed with code 5: couldn't get path of DARWIN_USER_TEMP_DIR; using /tmp instead
git: error: couldn't create cache file '/tmp/xcrun_db-N1E0Hqpo' (errno=Operation not permitted)
git: warning: confstr() failed with code 5: couldn't get path of DARWIN_USER_TEMP_DIR; using /tmp instead
git: error: couldn't create cache file '/tmp/xcrun_db-eFNpKNQl' (errno=Operation not permitted)
1f0a5bf1 2026-08-15 XYZ: initial public release
git: warning: confstr() failed with code 5: couldn't get path of DARWIN_USER_TEMP_DIR; using /tmp instead
git: error: couldn't create cache file '/tmp/xcrun_db-TBS3MW2d' (errno=Operation not permitted)
git: warning: confstr() failed with code 5: couldn't get path of DARWIN_USER_TEMP_DIR; using /tmp instead
git: error: couldn't create cache file '/tmp/xcrun_db-BtrDj2qZ' (errno=Operation not permitted)
commit c0a9b8998dfa939a4c7d860defaea8a57dac3314
Author: Noel Saw <56978803+noelsaw1@users.noreply.github.com>
Date:   Tue Sep 22 08:59:15 2026 -0700

    feat(GH-749): marathon delivery — #720 review-once heading truth; #732 measurements, dated timing claims + slowest-suites summary, named environment faults (four lanes, all gates green) (#750)
    
    * plan(GH-749): marathon intake — umbrella, contracts for GH-720/GH-732, ledger repairs, four-lane chain
    
    Umbrella #749 (relay exit-code truth + measured gate cost) registered as
    mar-01M33PJX8HPKMJHPQFH1S0WG6B. GH-720 and GH-732 promoted to 2-WORKING with
    Swarm Preflight Contracts (both `swarm-preflight --dry-run` ready, exit 0),
    ratings confirmed and provisional cleared; ledger rows repointed / marked 🚧 /
    rated through the writer; GH-673's raw_text gets its [plan] link (planner
    reads the link, not doc_path); GH-732's row carries its v6 title.
    
    Plan dir PROJECT/2-WORKING/GH-749-RELAY-GATE-COST/: CAPTURE.md, MARATHON.yaml
    (`marathon.sh --dry-run`: 4 phases in order) and briefs L1 (#720 review-once
    heading regex + gh648-l8 regression), L2 (#732 C.1/D.2 measurements over
    committed inputs), L3 (#732 A.1–A.5 dated timing claims + slowest-suites
    render from GH-365 telemetry), L4 (#732 B.1/B.2 named environment faults,
    --qualify exit-6 boundary kept). MARATHON-PLAN-2026-09-22.md regenerated:
    Wave 1 = #720 ‖ #732. #673 and #496 P3–5 held, recorded in CAPTURE.md.
    
    Refs #749 #720 #732 #673
    
    Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>
    
    * marathon: render phase p1 relay (MARATHON-P1-TURN)
    
    * relay(MARATHON-P1-TURN): codex turn (codex headless; no push)
    
    * relay(MARATHON-P1-TURN): agy turn (agy headless; no push)
    
    * relay-drive: attest MARATHON-P1-TURN approved by agy (reviewed 45b7d2cdba1e)
    
    * marathon: render phase p1 relay (MARATHON-P1-TURN)
    
    * marathon: render phase p1 relay (MARATHON-P1-TURN)
    
    * marathon: phase p1 escalation (pre-advance-failed)
    
    * marathon: phase p1 transcript saved (MARATHON-P1-TURN)
    
    * chore(relay-pkg): regenerate relay-pkg.tar.gz after the GH-720 L1 new-relay.sh change
    
    Phase p1's gate went red on relay-pkg-freshness.sh (drift: relay-automation/new-relay.sh).
    Regenerated with skills/relay-automation/make-pkg.sh — the step relay-xyz documents for any
    lane whose write-set touches relay-automation/.
    
    Refs #749 #720
    
    Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>
    
    * evidence(GH-720): L1 gate — nested refusal (#507 + stale relay-pkg), standalone 410/410 at 396d6978
    
    Refs #749 #720 #507
    
    Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>
    
    * marathon: phase p1 escalation (unattested-terminal)
    
    * marathon: phase p1 transcript saved (MARATHON-P1-TURN)
    
    * plan(GH-749): L1 write-set includes relay-pkg.tar.gz; brief carries the make-pkg step (retry note)
    
    Refs #749 #720
    
    Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>
    
    * marathon: render phase p1 relay (MARATHON-P1-TURN-2)
    
    * relay(MARATHON-P1-TURN-2): codex turn (codex headless; no push)
    
    * relay(MARATHON-P1-TURN-2): agy turn (agy headless; no push)
    
    * relay-drive: attest MARATHON-P1-TURN-2 approved by agy (reviewed 2d240ca1a437)
    
    * marathon: phase p1 transcript saved (MARATHON-P1-TURN-2)
    
    * marathon: render phase p2 relay (MARATHON-P2-TURN)
    
    * relay(MARATHON-P2-TURN): codex turn (codex headless; no push)
    
    * relay(MARATHON-P2-TURN): agy turn (agy headless; no push)
    
    * relay-drive: attest MARATHON-P2-TURN approved by agy (reviewed 5e9e0d5ede16)
    
    * marathon: phase p2 transcript saved (MARATHON-P2-TURN)
    
    * marathon: render phase p3 relay (MARATHON-P3-TURN)
    
    * relay(MARATHON-P3-TURN): codex turn (codex headless; no push)
    
    * relay(MARATHON-P3-TURN): agy turn (agy headless; no push)
    
    * relay-drive: attest MARATHON-P3-TURN approved by agy (reviewed a6b4a50c8964)
    
    * marathon: phase p3 transcript saved (MARATHON-P3-TURN)
    
    * marathon: render phase p4 relay (MARATHON-P4-TURN)
    
    * relay(MARATHON-P4-TURN): codex turn (codex headless; no push)
    
    * relay(MARATHON-P4-TURN): agy turn (agy headless; no push)
    
    * relay-drive: attest MARATHON-P4-TURN approved by agy (reviewed 10836fc9171f)
    
    * marathon: phase p4 escalation (pre-advance-failed)
    
    * marathon: phase p4 transcript saved (MARATHON-P4-TURN)
    
    * fix(test, GH-732 L4): gh268 red control proves the fault via validate.sh --print-mode, no eval
    
    security-scan.sh flagged the p4 lane's eval "$(sed -n … validate.sh)" as eval-unsanitized (real,
    not baselined). Same evidence, two halves: --print-mode on the shimmed PATH prints the named
    fault; XYZ_ENV_FAULTS=php exercises the suite-side skip — the contract validate.sh exports.
    security-scan 35/0, gh268 green standalone. L4 brief carries the retry note.
    
    Refs #749 #732
    
    Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>
    
    * marathon: phase p1 transcript saved (MARATHON-P1-TURN)
    
    * plan(GH-749): single-phase retry plan for p4 (GH-505 whole-tree check blocks re-firing the full chain)
    
    Refs #749
    
    Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>
    
    * marathon: render phase p4 relay (MARATHON-P4-TURN-2)
    
    * relay(MARATHON-P4-TURN-2): codex turn (codex headless; no push)
    
    * relay(MARATHON-P4-TURN-2): agy turn (agy headless; no push)
    
    * relay-drive: attest MARATHON-P4-TURN-2 approved by agy (reviewed 9155c15a309c)
    
    * marathon: phase p4 transcript saved (MARATHON-P4-TURN-2)
    
    * marathon: render phase p1 relay (MARATHON-P1-TURN)
    
    * marathon: render phase p1 relay (MARATHON-P1-TURN)
    
    * chore(#507): restore marathon-system/p1/ to development — nested-gate fixture noise, not lane content
    
    The four 'render phase p1 relay (MARATHON-P1-TURN)' commits on this branch were test/marathon-drive.sh's
    vendored fixture writing into the real clone while validate.sh ran under a live marathon-drive (#507),
    including the closeout push's own pre-push gate. Net change to the tracked file reverted; nothing else.
    
    Refs #749 #507
    
    Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>
    
    * docs(GH-749): CAPTURE.md status — delivered, PR #750, bridges and follow-ups recorded
    
    Refs #749
    
    Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>
    
    ---------
    
    Co-authored-by: Claude Opus 5 (1M context) <noreply@anthropic.com>

diff --git a/relay-automation/new-relay.sh b/relay-automation/new-relay.sh
index 3a02bcbe..efd7ec98 100755
--- a/relay-automation/new-relay.sh
+++ b/relay-automation/new-relay.sh
@@ -103,6 +103,7 @@ ROUND: 1 / $ROUND_CAP
      including \`Declined — unproven generalization\` for a behaviour-change request that carries no
      \`Observed input:\` / \`Affected scope:\` / \`Falsifier:\`), make the change, then add new work.
 4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns.
+   Reviewer headings may be \`### Reviewer · Round N\`, \`### Round N · Reviewer · <agent>\`, \`### Reviewer (<agent>)\` (optionally followed by \`— rN\`), or \`### Reviewer — Round N\` (optionally followed by \`(<agent>)\`); follow the heading with a non-empty review body.
 5. **Update the header:** flip \`NEXT\`; set \`STATUS\` (\`Approved\` closes — Reviewer only; else \`Open\`);
    the Producer bumps \`ROUND\` when opening a new cycle. If the max \`ROUND\` ends without \`Approved\`,
    set \`STATUS: Escalated\`.

commit 55d8ab47b8c0ea044b02fbd1e49a5ea9835a360d
Author: Noel Saw <56978803+noelsaw1@users.noreply.github.com>
Date:   Thu Sep 17 18:05:18 2026 -0700

    fix(relay): Reviewer may measure read-only; generalizations carry a falsifier (GH-681) (#683)
    
    Closes #681
    
    Adjudicated across two consults (Codex+agy; Codex Astra high + Fable high), plan of record on #681. Reviewer note in rtl_turn_prompt allows narrow non-mutating probes with a role-conditional verification clause; generalization/falsifier rule codified in new-relay.sh, the marathon brief, skills/relay and skills/relay-xyz. Containment unchanged. Regression test/gh681-reviewer-probe-rules.sh. Follow-up #682.
    
    Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>

diff --git a/relay-automation/new-relay.sh b/relay-automation/new-relay.sh
index 04331391..3a02bcbe 100755
--- a/relay-automation/new-relay.sh
+++ b/relay-automation/new-relay.sh
@@ -89,8 +89,19 @@ ROUND: 1 / $ROUND_CAP
      Any \`[Pass]\` or "verified"/"confirmed" finding MUST
      carry a quoted span or a \`file:line\` citation — an uncited one is mechanically downgraded to
      \`[Unverified — no citation]\` (GH-173 B3). Do **not** edit the artifact; only append findings here.
-   - **Producer:** log a disposition for every open finding (Implemented / Modified / Declined + why),
-     make the change, then add new work.
+     **A finding that asks for a behaviour change is a generalization unless you can paste the concrete
+     input — a row, a value, a \`file:line\` — that fails under the current code** (GH-681: the gh673
+     final QA relay generalized one late-error observation into "or a later invalid identity", the
+     Producer implemented it, the same seat \`[Pass]\`ed it next round, and one historical NULL-URL
+     ledger row then blanked every issue). Every \`[Blocker]\` or \`[Should]\` requesting a behaviour
+     change MUST carry three lines: \`Observed input:\` (the failing input you saw), \`Affected scope:\`
+     (the input predicate the change would govern), \`Falsifier:\` (the fixture or data that would show
+     the change unnecessary or wrong, and its expected result).
+     A \`[Blocker]\` must cite an observed failure. This is a protocol rule, not a mechanical check —
+     the Producer may disposition a request lacking these as \`Declined — unproven generalization\`.
+   - **Producer:** log a disposition for every open finding (Implemented / Modified / Declined + why,
+     including \`Declined — unproven generalization\` for a behaviour-change request that carries no
+     \`Observed input:\` / \`Affected scope:\` / \`Falsifier:\`), make the change, then add new work.
 4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns.
 5. **Update the header:** flip \`NEXT\`; set \`STATUS\` (\`Approved\` closes — Reviewer only; else \`Open\`);
    the Producer bumps \`ROUND\` when opening a new cycle. If the max \`ROUND\` ends without \`Approved\`,

commit 99c263ea8583f2ffe05eea3f40624ed7b1a36ef2
Author: Noel Saw <56978803+noelsaw1@users.noreply.github.com>
Date:   Fri Sep 11 07:36:20 2026 -0700

    fix: stage relay, Tick, and merge-cleanup hotfixes (#529, #533, #554, #555) (#573)
    
    * fix(relay): attest turns inserted above marker (GH-529)
    
    * fix(relay): align scaffold verdict vocabulary (GH-533)
    
    * fix(merge-cleanup): remove verified B1 backup (GH-555)
    
    * fix(tick): reject unknown flags before mutation (GH-554)
    
    * docs: record staged hotfix verification
    
    * test: retain PR 573 staging gate evidence
    
    * docs(pdda): add lessons learned, isolate upstream doc, and record test receipt
    
    * chore: update PR 573 provenance receipt
    
    ---------
    
    Co-authored-by: CI Runner <ci@runner.invalid>

diff --git a/relay-automation/new-relay.sh b/relay-automation/new-relay.sh
index f128c507..04331391 100755
--- a/relay-automation/new-relay.sh
+++ b/relay-automation/new-relay.sh
@@ -77,8 +77,8 @@ ROUND: 1 / $ROUND_CAP
    last Log block isn't already yours. If not → STOP and reply "wrong window — nudge the <other> window."
 3. **Do your role's work** on the artifact named in Setup:
    - **Reviewer:** review vs the Definition of Done → graded findings
-     (\`[Blocker]\`/\`[Should]\`/\`[Nit]\`/\`[Pass]\`), each with a concrete fix → set a **Verdict**
-     (Approved | Changes requested | Blocked). **Review the whole file, not just the diff** (GH-268):
+     (\`[Blocker]\`/\`[Should]\`/\`[Nit]\`/\`[Pass]\`), each with a concrete fix → set a **VERDICT**
+     (exactly PASS, FAIL, or PARKED) and a **Basis** (explanation). **Review the whole file, not just the diff** (GH-268):
      a beta test had this loop reach \`Approved\` in two rounds while an independent audit of the same
      branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the
      change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN

exec
/bin/zsh -lc "nl -ba PROJECT/2-WORKING/GH-836-GATE-HOTSPOTS.md | sed -n '1,160p'; rg -n 'relay-self-sufficiency' TESTS-RESULTS/2026-09-26+GH-835/{analyze-full-gate.txt,gate-telemetry-b2c307b4.jsonl,full-gate-b2c307b4.log}; nl -ba .github/workflows/wave-reconcile.yml | sed -n '27,105p'; nl -ba relay-automation/gate-env.sh | head -70; rg -n 'retry|re-run|rerun' validate.sh; rg -n 'No new tests|provenance.jsonl|SEPARATE FULL' AGENTS.md; rg -n 'minimal-relay|new-relay.sh' test/relay-self-sufficiency.sh test/*template* test/*533* test/*681*" in /private/var/folders/z0/92pfvhnn06z2_7hnpdb4kkbw0000gn/T/consult-wt-92092-h1_gqux_
 exited 1 in 0ms:
     1	---
     2	gh_issue: 836
     3	source: https://github.com/HiQS-Labs/XYZ-forge/issues/836
     4	title: "CI refactor: trim the measured gate hotspots (gh549 race leg and board-dispatch backfills, gh436 parity double-run, gh649 /tmp bug); take the tier decisions on hosted Small numbers"
     5	status: Active — plan under Codex review (2-WORKING)
     6	created: 2026-09-26
     7	updated: 2026-09-26
     8	owner: operator (via /start-task)
     9	doc_type: fix
    10	branch: fix/gh836-gate-hotspots
    11	non_goals:
    12	  - New suites, registry entries or gate machinery (AGENTS.md, No new tests).
    13	  - Moving gh549 or gh436 out of Small; that is D1, the operator's decision, taken on hosted numbers.
    14	  - Rewriting gh549 to run in one process, or gh436 on template fixtures (deferred in #836).
    15	  - Any change to utils/py/releases_app.py, the merge-cleanup scripts, ci-route or the runner.
    16	related:
    17	  - "#835 — the gate-timing snapshot and its three profiling reviews (closed as completed)"
    18	  - "#831 — the three-tier gate; its Phase 3 hosted Small evidence is still owed"
    19	goal: >
    20	  gh549 and gh436, which make up two-thirds of the hosted Small run, get cheaper where the time was measured.
    21	  Every trimmed leg keeps its assertion and red control, and gh649 stops failing falsely under /tmp.
    22	---
    23	
    24	# GH-836 — trim the measured gate hotspots
    25	
    26	## Status
    27	
    28	| What was just completed | What's next |
    29	|---|---|
    30	| Recon and a same-device baseline: `gh549` 346 s (124 passed) and `gh436` 292 s (180 passed), in a disposable clone. It traced the three hotspots to test-side causes, and the plan follows. | Codex plan review, then implementation on `fix/gh836-gate-hotspots`. |
    31	
    32	## Contents
    33	
    34	- [Rating](#rating--2026-09-26-70455070-prisevappealeffort)
    35	- [Recon](#recon)
    36	- [Plan](#plan)
    37	- [Verification and evidence](#verification-and-evidence)
    38	- [Decisions for the operator](#decisions-for-the-operator-not-in-this-pr)
    39	- [Risk and rollback](#risk-and-rollback)
    40	
    41	## Rating — 2026-09-26: `70/45/50/70` (pri/sev/appeal/effort)
    42	
    43	- **Severity 45.** No crash or data loss. The cost is time: `gh549` and `gh436` are about 12 of the hosted Small
    44	  run's ~18 minutes, and every docs, ledger and skill landing pays it.
    45	  - One real defect: `gh649` goes red on any clone under the `/tmp` symlink, a false failure in the gate
    46	    (GLM's red log, `TESTS-RESULTS/2026-09-26+GH-835/full-gate-b2c307b4-tmp-red.log`).
    47	- **Priority 70.** Gate cost is the operator's current focus. The 14-day window (2026-09-12 to 09-26) shows the
    48	  same class repeatedly:
    49	  - #802, #828's 79-minute reconcile failure, #831 and #835;
    50	  - the operator asked for this work directly.
    51	
    52	  The window before it (08-29 to 09-11) was not searched, so the trend is **unknown**, not rising.
    53	- **Appeal 50.** Neutral; the operator gave no score.
    54	- **Effort 70.** Cheap: edits to three existing suites, with no routing or runner change. The cost is witnessing
    55	  red controls and taking same-device before/after timings.
    56	
    57	## Recon
    58	
    59	Base `4bd8851a` (`development`). Baseline evidence is in `TESTS-RESULTS/2026-09-26+GH-836/baseline-*`. It is a
    60	disposable clone at `9c5d294e`, run with the gate's `PATH`, one suite at a time, with identity unchanged
    61	before and after.
    62	
    63	**R1 — `gh549` leg 21e's red control is 124.8 s** (`baseline-gh549-top-gaps.txt`, line 1068).
    64	
    65	- The red control copies `utils/py/` and mutates `releases_app.py` so the suppression read happens outside the
    66	  write transaction. The mutation inserts `import time as _t; _t.sleep(0.4)` between the read and the write
    67	  (`test/gh549-work-events.sh:1043-1062`).
    68	- Two backfills then race over the full fixture (`:1064-1068`). The fixture is a copy of the real ledger, with
    69	  about 274 roadmap rows.
    70	- The sleep runs on **every** row, so each racer crawls through 274 × 0.4 s ≈ 110 s in lockstep.
    71	- The leg needs only one duplicate (`NBF3 > NROWS`, `:1070`). A race window on the first few rows is enough.
    72	- The positive race itself (`:1052-1056`, two unmutated backfills) costs about 10 s and is not the problem.
    73	
    74	**R2 — two `work backfill` calls with the board connector on cost 68.8 s + 38.0 s** (lines 1127 and 1178,
    75	section 21f).
    76	
    77	- `rr` (`:1094`) runs its verb with the github_board connector enabled against the mock board.
    78	- `work backfill` projects every ledger row (`releases work backfill` has no issue filter). Each emit
    79	  dispatches to the connector post-commit (`_dispatch_work_connectors`, `utils/py/releases_app.py:1613`), one
    80	  mock-board subprocess per event.
    81	- Leg 21f's assertions read only `work_events` rows for issues 9920 and 9903 (`:1129-1146`), and its red (iii)
    82	  reads 9920's review_ready count (`:1180-1182`). None of them reads board state.
    83	- Connector dispatch is covered by legs 12–20. The same `work reconcile` alone, with the cursor at the tail,
    84	  ran in 1 s on a scratch fixture.
    85	- `XYZ_WORK_CONNECTORS=0` skips dispatch (`:1620`) and the review_ready scan (`:5269`). So it may be set only on
    86	  the **backfill** calls, never on the reconcile calls the leg asserts on.
    87	- Afterwards the github_board cursor must advance to the new tail. Otherwise the next `rr … work reconcile`
    88	  replays the whole backlog, and the cost only moves.
    89	
    90	**R3 — `gh436`'s parity test is 49.0 s of 292 s** (`baseline-gh436-durations.out`).
    91	
    92	- `TestParityGuard.test_skill_md_matches_code_and_tests` calls `parity_failures(..., run_tests=True)`
    93	  (`test/gh534_phase_c_tests.py:928`), which re-runs each script row's named test (`:587-590`).
    94	- A probe loaded `gh436`'s collection (180 tests). All 17 distinct named tests are in it: `gh436` imports
    95	  phases A, B and C with `import *` (`test/gh436-merge-cleanup.py:863-865`), and phase C defines no `__all__`.
    96	  Every named test therefore already runs once in the same suite run, and a failing one fails the suite.
    97	- No other caller passes `run_tests=True`. The five mutation controls (`:935-966`) call `_fails()`, which
    98	  leaves it off.
    99	- GH-534's spec says the guard "asserts every named test exists and runs"
   100	  (`PROJECT/3-COMPLETED/GH-534-MERGE-CLEANUP-FAILURE-MODES.md:443`). After this change, "runs" is met by the
   101	  suite's own collection. "Exists" stays checked by the guard, against the module globals that collection
   102	  draws from.
   103	
   104	**R4 — `gh649`'s `/tmp` false red.** `test/gh649-pdda-migration.sh:4` sets `ROOT` with a logical `pwd`, while
   105	`skills/4-occasional/vendor-stack/find-pdda.sh:22,26` resolves with `cd -P`. On macOS `/tmp` is a symlink, so under it the
   106	equality at `:15` fails. It is witnessed red in GLM's `full-gate-b2c307b4-tmp-red.log`.
   107	
   108	**R5 — agy's `relay-self-sufficiency` claim is true** (for D2, not this PR). The pre-push hook runs `validate.sh`
   109	without `RELAY_SELF_SUFFICIENCY_SKIP`, while `ci-local.sh:404` and all three `ci.yml` jobs set it. So each local
   110	full gate makes a real agent call when agy or codex is on `PATH` (`test/relay-self-sufficiency.sh:7-11`).
   111	
   112	## Plan
   113	
   114	Every step is an edit to an existing suite. Nothing is added to `test/` or the registry. Each red control is
   115	witnessed on the edited suite and recorded under `TESTS-RESULTS/2026-09-26+GH-836/`.
   116	
   117	1. **`gh549` 21e red control: bound the race window.** In the mutated copy only (`:1057-1062`), sleep for the
   118	   first 3 emits of each process instead of every emit, with a process-global counter in the inserted text.
   119	   The unmutated race, its `NROWS` fixture and both assertions are unchanged.
   120	   → expect: green. **Red control:** the mutated copy still duplicates (`NBF3 > NROWS`). It is witnessed 10
   121	   times in a row, so the smaller window is not flaky.
   122	2. **`gh549` 21f: backfill without board dispatch.**
   123	   - Set `XYZ_WORK_CONNECTORS=0` on the `work backfill` calls in 21f and 21f red (iii) (`:1127`, `:1132`,
   124	     `:1141`, `:1178`), and only those.
   125	   - After each, advance the github_board cursor to the current tail. This extends the existing
   126	     `seed_cursor_tail` helper (`:162`) with an optional id, defaulting to `$PRISTINE_TAIL`, so there is no
   127	     second helper.
   128	   - The reconcile calls keep the connector and the PR scan.
   129	
   130	   → expect: green, with all 21f assertions unchanged. **Red controls:** 21f red (iii) and red (ii) still
   131	   reproduce. **A witness that the cursor step is load-bearing:** without it, the next reconcile's wall time
   132	   comes back (recorded, not asserted).
   133	3. **`gh436` parity guard: one execution per named test.**
   134	   - `test_skill_md_matches_code_and_tests` stops passing `run_tests=True`.
   135	   - The now-unused `run_tests` parameter and branch are removed from `parity_failures`.
   136	   - A comment records that the suite's own collection runs each named test, and why that holds (`import *`,
   137	     no `__all__`).
   138	   - SKILL.md's description of the guard (`skills/2-daily/merge-cleanup/SKILL.md:213`) already makes no "runs"
   139	     claim, and stays as it is.
   140	
   141	   → expect: green. **Red controls:**
   142	   - (a) a SKILL.md row deleted in a scratch copy fails the parity test;
   143	   - (b) a named test forced to fail in a scratch copy still fails the `gh436` suite, now through collection.
   144	4. **`gh649`: `pwd -P` at line 4.**
   145	   → expect: green from a physical path. **Red control:** from a clone under `/tmp`, red before the fix and
   146	   green after it.
   147	5. **Measure after.** Same device, same procedure as the baseline: `gh549` traced, `gh436` plain and
   148	   `--durations`. The before/after table goes in this doc.
   149	6. **Hosted Small numbers (#836 step 2, #831 Phase 3).** When the first hosted Small run exists, record its run
   150	   ID and duration here and in the GH-831 plan. This may land in a later docs PR if the run comes after this PR
   151	   merges.
   152	
   153	**Expected:** `gh549` from about 346 s to about 130 s and `gh436` from about 292 s to about 243 s, locally.
   154	Hosted Small drops by roughly the same share, from ~18 minutes to ~12–13.
   155	
   156	## Verification and evidence
   157	
   158	- Each edited suite is run focused while iterating. The full gate runs **once** on the final approved commit,
   159	  in a disposable clone through the push hook. Test edits route tier 3.
   160	- The PR records same-device before/after numbers. Red-control logs carry exit codes, in `provenance.jsonl`.
TESTS-RESULTS/2026-09-26+GH-835/gate-telemetry-b2c307b4.jsonl:386:{"v":1,"ts_ms":1790435518468,"run":"b2c307b4e-35339","runner":"validate","event":"suite","lane":"pool","name":"relay-self-sufficiency.sh","queued_ms":1790434729984,"started_ms":1790435456865,"ended_ms":1790435518461,"duration_ms":61596,"rc":0,"worker":17512,"out_bytes":525,"out_sha256":"4a707a00363a","skip_lines":0}
TESTS-RESULTS/2026-09-26+GH-835/analyze-full-gate.txt:23: 13  relay-self-sufficiency.sh                    1.03 min    1.7%  rc=0
TESTS-RESULTS/2026-09-26+GH-835/analyze-full-gate.txt:41:relay-self-sufficiency.sh	61.596	0	pool
TESTS-RESULTS/2026-09-26+GH-835/full-gate-b2c307b4.log:408:[parallel] relay-self-sufficiency.sh rc=0
TESTS-RESULTS/2026-09-26+GH-835/full-gate-b2c307b4.log:883:  + relay-self-sufficiency.sh
    27	    runs-on: macos-latest
    28	    timeout-minutes: 120
    29	    permissions:
    30	      contents: write
    31	      issues: write   # GH-684: the final step opens/closes the one hosted-reconcile-attention issue
    32	      pull-requests: read
    33	    env:
    34	      GH_TOKEN: ${{ github.token }}
    35	      PYTHONDONTWRITEBYTECODE: '1'
    36	    steps:
    37	      - uses: actions/checkout@v7
    38	        with:
    39	          ref: development
    40	          fetch-depth: 0
    41	      - name: Check direct-push prerequisite
    42	        env:
    43	          REPO: ${{ github.repository }}
    44	        run: |
    45	          set -euo pipefail
    46	          # development was unprotected when implemented. Fail before writes if that changes;
    47	          # a protected branch needs a reviewed bot-bypass policy, never an implicit bypass.
    48	          test "$(gh api "repos/$REPO/branches/development" --jq .protected)" = false
    49	      - name: Install runtime dependencies
    50	        run: npm ci
    51	      - name: Install Python dependencies for complete qualification
    52	        run: python3 -m pip install --quiet --break-system-packages pytest requests PyYAML
    53	      - name: Reconcile merged PR or catch up
    54	        id: reconcile
    55	        env:
    56	          EVENT_NAME: ${{ github.event_name }}
    57	          PR_NUMBER: ${{ github.event.pull_request.number }}
    58	        # GH-684: the log is tee'd OUTSIDE the tree ($RUNNER_TEMP) — the commit step below refuses
    59	        # undeclared in-tree files — and stderr is folded in because the terminal
    60	        # `wave-reconcile: ERROR — …` line is written there. pipefail keeps the reconciler's exit.
    61	        # GH-740: the argv is built once and exported as RECONCILE_ARGS so the publish step's one
    62	        # bounded recompute re-runs exactly this command (plus --only-receipted --skip-pull).
    63	        run: |
    64	          set -euo pipefail
    65	          if [ "$EVENT_NAME" = pull_request ]; then
    66	            ARGS=(--pr "$PR_NUMBER" --catch-up --gate --qualify)
    67	          else
    68	            ARGS=(--catch-up --gate --qualify)
    69	          fi
    70	          echo "RECONCILE_ARGS=${ARGS[*]}" >> "$GITHUB_ENV"
    71	          python3 utils/py/wave_reconcile.py "${ARGS[@]}" 2>&1 | tee "$RUNNER_TEMP/reconcile.log"
    72	      - name: Commit declared artifacts and push
    73	        id: publish
    74	        # GH-740: utils/py/hosted_lane_publish.py — the former inline step, moved so it can be tested
    75	        # and retried. Same allowlist, explicit `git add`, bot identity, one fast-forward push; on a
    76	        # rejected push it discards the stale commit, lifts only the receipt files onto the fresh
    77	        # head, publishes them, and recomputes the transitions once with --only-receipted (which can
    78	        # never run the suite). Never rebases a generated SQLite DB, never force-pushes. Its log is
    79	        # tee'd for the report step (GH-741).
    80	        run: |
    81	          set -euo pipefail
    82	          python3 utils/py/hosted_lane_publish.py --reconcile-args "$RECONCILE_ARGS" 2>&1 | tee "$RUNNER_TEMP/publish.log"
    83	      - name: Report hosted lane
    84	        # GH-684: always runs, after the job's status is known. `job.status` reflects every preceding
    85	        # step — a successful reconcile followed by a rejected fast-forward push is still red here.
    86	        # One labelled issue is opened/commented on red or on any skipped backlog item, and closed
    87	        # on the next green run with no skips. See utils/py/hosted_lane_report.py.
    88	        # GH-741: the step outcomes decide WHICH log's error is the cause — a green reconcile step's
    89	        # log is full of the test suite's own expected ERROR lines and must never be blamed.
    90	        if: always()
    91	        env:
    92	          RUN_URL: ${{ github.server_url }}/${{ github.repository }}/actions/runs/${{ github.run_id }}
    93	        run: >-
    94	          python3 utils/py/hosted_lane_report.py --status "${{ job.status }}" --log "$RUNNER_TEMP/reconcile.log"
    95	          --run-url "$RUN_URL" --reconcile-outcome "${{ steps.reconcile.outcome }}"
    96	          --publish-outcome "${{ steps.publish.outcome }}" --publish-log "$RUNNER_TEMP/publish.log"
     1	#!/usr/bin/env bash
     2	# gate-env.sh — GH-441 Phase 2. SOURCE this at the top of any `--pre-advance-cmd`.
     3	#
     4	#   . "$(dirname "$0")/relay-automation/gate-env.sh"      # or an absolute path
     5	#
     6	# It clears the variables a live marathon exports that would otherwise flip a suite's verdict, so the
     7	# gate reports on the change under review rather than on its parent.
     8	#
     9	# WHY A HELPER AND NOT A COPIED PROLOGUE
    10	# `validate.sh` used to carry its own hardcoded `unset` line. That worked only for validate.sh: any
    11	# custom gate that did not copy it was silently wrong, and one did — a hand-written gate on
    12	# 2026-08-07 reproduced test/oracle-guard.sh's failure because it inherited ALLOW_PATHS (ambient →
    13	# 10 pass/1 fail; unset → 11/0). It cost two marathon rounds and three clean standalone re-runs
    14	# before the variable was found. A gate cannot be expected to remember a list it does not own.
    15	#
    16	# SINGLE SOURCE OF TRUTH
    17	# The list comes from utils/py/gate_env.py, the same registry `marathon_drive._gate_env()` uses, so
    18	# the shell side and the driver side cannot drift. Do not inline the names here — a second copy of
    19	# the list is the defect this replaces. `test/gh441-gate-env-contract.sh` asserts the two agree.
    20	#
    21	# NOT SCRUBBED: RELAY_DRIVER_LOCKED. Nested drivers need it SET; suites asserting real lock
    22	# acquisition need it UNSET; no global value is correct. Scrubbing it was landed and reverted
    23	# (2026-08-07). The two suites that need it clear do so themselves — GH-441 Phase 1.
    24	
    25	# Resolve the harness root from this script's own location, following symlinks, so sourcing works
    26	# from any CWD and from a vendored .xyz/ install. No machine path is ever hardcoded.
    27	# Every scratch name here is `_ge_`-prefixed and unset at the end: this file is SOURCED, so a bare
    28	# `_src` or `_hp_lib` would clobber the caller's own (GH-730 review finding).
    29	_ge_src="${BASH_SOURCE[0]:-$0}"
    30	while [ -h "$_ge_src" ] || [ -L "$_ge_src" ]; do
    31	  _ge_ldir="$(cd -P "$(dirname "$_ge_src")" >/dev/null 2>&1 && pwd)"
    32	  _ge_src="$(readlink "$_ge_src")"
    33	  case "$_ge_src" in /*) ;; *) _ge_src="$_ge_ldir/$_ge_src" ;; esac
    34	done
    35	_ge_dir="$(cd -P "$(dirname "$_ge_src")" >/dev/null 2>&1 && pwd)"
    36	
    37	_ge_hp_lib="$_ge_dir/harness-paths.sh"
    38	if [ -f "$_ge_hp_lib" ]; then
    39	  # shellcheck source=relay-automation/harness-paths.sh
    40	  . "$_ge_hp_lib"
    41	fi
    42	_ge_root="$(cd -P "$_ge_dir/.." && pwd)"
    43	_ge_py="$_ge_root/utils/py/gate_env.py"
    44	
    45	if [ -r "$_ge_py" ]; then
    46	  # One name per line from the registry, applied by an explicit loop.
    47	  #
    48	  # The first draft of this file instead shell-evaluated a generated `unset A B C` line. The GH-64
    49	  # security gate rejected it as `eval-unsanitized` and was right to: nothing should hand generated
    50	  # text to the shell for interpretation when a loop does the same job. This form has no shell
    51	  # evaluation at all, and validates each name against a strict pattern before acting on it.
    52	  #
    53	  # (The rewrite of this very comment was also a finding: the scanner matches the four-letter
    54	  # builtin anywhere in the file, comments included, so the earlier wording tripped it while the
    55	  # code beneath was already clean.)
    56	  # Read one name per line. A `for _ge_n in $_ge_names` loop would be a bug in any shell that does
    57	  # NOT word-split unquoted parameters — zsh does not, so it would pass the whole newline-joined blob
    58	  # as a single name and fail with `invalid parameter name` (observed 2026-08-07). A heredoc-fed
    59	  # `while read` behaves identically in bash and zsh, and unlike a pipe it keeps the loop in the
    60	  # CURRENT shell so the unsets survive.
    61	  _ge_names="$(python3 "$_ge_py" --list-scrubbed 2>/dev/null || true)"
    62	  if [ -n "$_ge_names" ]; then
    63	    while IFS= read -r _ge_n; do
    64	      [ -n "$_ge_n" ] || continue
    65	      case "$_ge_n" in
    66	        [A-Z_][A-Z_0-9]*) unset "$_ge_n" ;;
    67	        *) printf 'gate-env.sh: refusing to unset malformed name from the registry: %s\n' "$_ge_n" >&2 ;;
    68	      esac
    69	    done <<GATE_ENV_NAMES
    70	$_ge_names
252:  "gh385-retry-token-satisfied.sh" # GH-385 (a phase completed on a --retry suffixed token is satisfied) + GH-491 (--retry on an already-satisfied lane says a plain re-fire would have been gate-only) — 19/0; controls: un-completed recorded token must still rebuild; GH-491 advisory must NOT fire when the recorded token is not done, and must not change --retry's behaviour
259:  "gh491-gate-only-refire.sh"    # GH-491 (gate-only re-fire discoverability under --retry)
299:  "gh365-validate-telemetry.sh"        # GH-365 step 2 (retained JSONL telemetry, one lib for both runners) — unit schema, e2e pool/retry/sequential events with skip_lines + bytes/hash, live-denominator check, wiring pins
347:  "gh648-l2-token-aftermath.sh" # GH-648 L2 (timeout preserves same-role token retry)
518:                                 #   unchanged rerun is a byte no-op
579:  "gh528-parallel-contention-retry.sh" # GH-528 (--parallel re-runs a pooled failure alone before believing it, and names the contended suite; the driver-lock lane list cannot be validated by reading it)
632:                                     #   E2E in root + vendored installs with stubbed agents/GitHub, resume/retry/land
1183:# parallelism, its contention-retry, and three non-shell lanes the scrape could not see. Giving the
1251:# re-run below exists. It never "drives" anything — it passes a bogus flag and asserts both twins
1294:    # for every suite is what makes the pool/lane/serial-re-run verdicts comparable.
1334:  # the telemetry-merge line). The rerun lane below then writes straight to the retained file.
1351:  # (1) The serial re-run inherited THIS LOOP'S stdin — which is $RESULTS itself. A re-run suite
1353:  #     lines recorded were never re-run, never reported, and the run exited GREEN with a short
1355:  #     deterministically in the GH-15 investigation). The re-run now gets </dev/null, which is
1356:  #     ALSO the pool's stdin regime (xargs hands its workers /dev/null), so the re-run is the
1359:  #     re-run nor reported. The completeness catch-up below gives a missing line the same
1360:  #     treatment as a nonzero rc — re-run alone before believing anything.
1362:  vp_rerun_alone() {  # <suite> <why> [rc_first] — classify one suite by its ALONE verdict; never by the pool's
1367:    echo "$why: $t — re-running it alone to see if that verdict survives"
1376:      rt_emit retry retry "$t" "$_s" "$(rt_now_ms)" "$rc_alone" "rc_first=$rc_first" "classified=contended"
1377:      rt_suite retry "$t" "$_s" "$(rt_now_ms)" "$rc_alone" "$log.serial"
1383:      rt_emit retry retry "$t" "$_s" "$(rt_now_ms)" "$rc_alone" "rc_first=$rc_first" "classified=real-failure"
1384:      rt_suite retry "$t" "$_s" "$(rt_now_ms)" "$rc_alone" "$log.serial"
1392:    vp_rerun_alone "$t" "FAILED in parallel (rc=$rc)" "$rc"
1397:  # that is a pooled failure in every way that matters, so it gets the same serial re-run, never
1402:    grep -Fxq "$t" "$_vp_ran" || vp_rerun_alone "$t" "NO RESULT recorded in parallel"
1433:    # receipt cannot represent a failure). The retry path ten lines up has had the order right
1536:# suite-lane records (pool/driver-lock/sequential): retry legs add retry-lane records and the
1557:# Only suite events: each retry also emits event=retry, which must not double its cost.
1570:      if (lane == "retry") {
1571:        retry_ms += ms
1572:        if (!retried[name]++) retry_count++
1577:    END { print -1, retry_count + 0, retry_ms + 0 }
1580:    $1 == -1 { printf "re-run ladder: %d suite(s), %.3fs total\n", $2, $3 / 1000; next }
100:An uncommitted `provenance.jsonl` is not proof (GH-430). Any run cited as evidence in an issue, PR,
101:ROADMAP entry, or decision record must have its `provenance.jsonl` committed in the same PR — a path
108:Never add a suite to do it; see the *No new tests* rail. This is the precise way this principle fails while looking
136:- **No new tests (GH-831, operator decision 2026-09-25).** This covers three things:
142:  `TESTS-RESULTS/<date>+GH-<n>/` with its `provenance.jsonl`. Edit an existing suite only to keep it truthful
343:- **Run the suite in a SEPARATE FULL CLONE, never in a clone whose state you care about — and a
zsh:1: no matches found: test/*template*

exec
/bin/zsh -lc "rg -n 'relay-self-sufficiency' TESTS-RESULTS/2026-09-26+GH-835/analyze-full-gate.txt TESTS-RESULTS/2026-09-26+GH-835/gate-telemetry-b2c307b4.jsonl; nl -ba .github/workflows/ci.yml | sed -n '185,205p;396,416p;480,490p'; nl -ba .github/workflows/wave-reconcile.yml | sed -n '30,39p;63,82p'; nl -ba githooks/pre-push | sed -n '190,225p;285,302p'; nl -ba utils/ci-route.sh | sed -n '320,340p'; rg -n 'RELAY_SELF|AGY_BIN|CODEX_BIN' utils/py/gate_env.py; rg -n 'release|promotion|make-pkg' skills/4-occasional/relay-xyz/SKILL.md skills/relay-xyz/SKILL.md SOP.md" in /private/var/folders/z0/92pfvhnn06z2_7hnpdb4kkbw0000gn/T/consult-wt-92092-h1_gqux_
 exited 2 in 0ms:
TESTS-RESULTS/2026-09-26+GH-835/analyze-full-gate.txt:23: 13  relay-self-sufficiency.sh                    1.03 min    1.7%  rc=0
TESTS-RESULTS/2026-09-26+GH-835/analyze-full-gate.txt:41:relay-self-sufficiency.sh	61.596	0	pool
TESTS-RESULTS/2026-09-26+GH-835/gate-telemetry-b2c307b4.jsonl:386:{"v":1,"ts_ms":1790435518468,"run":"b2c307b4e-35339","runner":"validate","event":"suite","lane":"pool","name":"relay-self-sufficiency.sh","queued_ms":1790434729984,"started_ms":1790435456865,"ended_ms":1790435518461,"duration_ms":61596,"rc":0,"worker":17512,"out_bytes":525,"out_sha256":"4a707a00363a","skip_lines":0}
   185	
   186	      - name: Verify automatic wave reconciliation (GH-421)
   187	        run: bash test/gh421-auto-wave-reconcile.sh
   188	
   189	      - name: Run the authoritative validator (no skips)
   190	        env:
   191	          # The one documented exclusion, and it is not a coverage skip: this test makes a real
   192	          # billed API call to a live agent. It self-skips off-PATH anyway; the env var makes the
   193	          # intent explicit rather than incidental.
   194	          RELAY_SELF_SUFFICIENCY_SKIP: "1"
   195	        # `--sequential` is PINNED here and must stay pinned. GH-544 made parallel the default for the
   196	        # local gate, which is correct there — but this job is the promotion boundary, and the whole
   197	        # point of it is that its green means something the local run's cannot. Promotion evidence
   198	        # stays sequential (GH-528 Phase 2 has not been met), so the flag is explicit rather than
   199	        # inherited: a future change to validate.sh's default must not be able to silently change what
   200	        # this job attests. test/ci-workflow.sh asserts the flag is present. It runs the FULL registry
   201	        # whatever the classifier would say about the promotion range: the three-tier routing (GH-831)
   202	        # stops at the hosted reconcile, and this is the last full check before a release (O8).
   203	        run: ./validate.sh --sequential
   204	
   205	      - name: Promotion evidence
   396	          git config --global user.name "CI Runner"
   397	
   398	      - name: Run Fast Gate tests (Pull Request)
   399	        # Whole-job budget target: < 3 minutes for a code-only fast PR.
   400	        if: github.event_name == 'pull_request' && steps.route.outputs.route == 'fast'
   401	        env:
   402	          RELAY_SELF_SUFFICIENCY_SKIP: "1"
   403	          CHANGED_TESTS: ${{ steps.route.outputs.changed_tests }}
   404	        run: |
   405	          set -euo pipefail
   406	          FAST_TESTS=(
   407	            "worktree-isolation.sh"
   408	            "shim-worktree.sh"
   409	            "gh292-worktree-vendored-discovery.sh"
   410	            "relay-target-root.sh"
   411	            "relay-target-root-paths.sh"
   412	            "relay-target-root-relayfile.sh"
   413	            "relay-target-root-newfile.sh"
   414	            "gh289-target-root-build-turn.sh"
   415	            "gh410-containment-advisory.sh"
   416	            "tick-foreign-cwd.sh"
   480	      - name: Run validate.sh suite (minus a documented flaky test)
   481	        if: steps.route.outputs.route == 'full'
   482	        env:
   483	          RELAY_SELF_SUFFICIENCY_SKIP: "1"
   484	        run: |
   485	          set -euo pipefail
   486	          ./validate.sh --parallel 6 \
   487	            --skip acorn-extract.sh \
   488	            --skip registry-lock-concurrency.sh \
   489	            --skip pdda-repo-contract.sh
   490	
    30	      contents: write
    31	      issues: write   # GH-684: the final step opens/closes the one hosted-reconcile-attention issue
    32	      pull-requests: read
    33	    env:
    34	      GH_TOKEN: ${{ github.token }}
    35	      PYTHONDONTWRITEBYTECODE: '1'
    36	    steps:
    37	      - uses: actions/checkout@v7
    38	        with:
    39	          ref: development
    63	        run: |
    64	          set -euo pipefail
    65	          if [ "$EVENT_NAME" = pull_request ]; then
    66	            ARGS=(--pr "$PR_NUMBER" --catch-up --gate --qualify)
    67	          else
    68	            ARGS=(--catch-up --gate --qualify)
    69	          fi
    70	          echo "RECONCILE_ARGS=${ARGS[*]}" >> "$GITHUB_ENV"
    71	          python3 utils/py/wave_reconcile.py "${ARGS[@]}" 2>&1 | tee "$RUNNER_TEMP/reconcile.log"
    72	      - name: Commit declared artifacts and push
    73	        id: publish
    74	        # GH-740: utils/py/hosted_lane_publish.py — the former inline step, moved so it can be tested
    75	        # and retried. Same allowlist, explicit `git add`, bot identity, one fast-forward push; on a
    76	        # rejected push it discards the stale commit, lifts only the receipt files onto the fresh
    77	        # head, publishes them, and recomputes the transitions once with --only-receipted (which can
    78	        # never run the suite). Never rebases a generated SQLite DB, never force-pushes. Its log is
    79	        # tee'd for the report step (GH-741).
    80	        run: |
    81	          set -euo pipefail
    82	          python3 utils/py/hosted_lane_publish.py --reconcile-args "$RECONCILE_ARGS" 2>&1 | tee "$RUNNER_TEMP/publish.log"
   190	        if [ -z "$base" ]; then
   191	          [ -n "$_base_note" ] || _base_note="pre-push: no fresh merge-base with $_push_remote's integration branch (tracking ref stale or absent — fetch and retry, or take the full gate)."
   192	          return 1
   193	        fi
   194	        ;;
   195	      *)
   196	        git cat-file -e "${remote_sha}^{commit}" 2>/dev/null || return 1
   197	        git merge-base --is-ancestor "$remote_sha" "$local_sha" 2>/dev/null || return 1
   198	        base="$remote_sha"
   199	        ;;
   200	    esac
   201	    _base_pairs+=("$local_sha|$base")
   202	  done
   203	  return 0
   204	}
   205	
   206	classify_push() {
   207	  [ -x "$REPO/utils/ci-route.sh" ] || return 1
   208	  [ "${#_base_pairs[@]}" -gt 0 ] || return 1
   209	
   210	  local pair local_sha base
   211	  for pair in "${_base_pairs[@]}"; do
   212	    IFS='|' read -r local_sha base <<<"$pair"
   213	    # `--no-renames` is load-bearing: the classifier must see the removed side of a renamed test.
   214	    git diff --no-renames --name-only "$base" "$local_sha" || return 1
   215	  done | "$REPO/utils/ci-route.sh" push
   216	}
   217	
   218	run_docs_gate() {
   219	  if [ ! -x "$REPO/utils/pdda/pdda.sh" ]; then
   220	    echo "pre-push: docs-only route selected but the PDDA gate is missing — REFUSING the push." >&2
   221	    return 1
   222	  fi
   223	  "$REPO/utils/pdda/pdda.sh" run || return 1
   224	  # Repo-owned PDDA additions are warn-only by contract; retain their diagnostics without turning
   225	  # a documentation-only push into an accidental second blocking policy.
   285	    rm -f "$_paths_file"
   286	  fi
   287	  # An unusable paths file falls through to the full gate below — fail closed, never open.
   288	else
   289	  echo "pre-push: running the full gate before this push reaches the remote (GH-544)."
   290	  echo "pre-push:   bypass with 'git push --no-verify' or XYZ_SKIP_PREPUSH=1 — both are recorded here, not hidden."
   291	  "$REPO/validate.sh" --print-mode 2>&1 | sed 's/^/pre-push:   /'
   292	
   293	  # See the note in run_tier2_gate: no outer `nice` — it is relative and stacks onto the +10
   294	  # validate.sh already applies to each worker.
   295	  if "$REPO/validate.sh"; then
   296	    echo "pre-push: full gate GREEN in $((SECONDS - _start))s — pushing."
   297	    exit 0
   298	  else
   299	    _rc=$?
   300	  fi
   301	fi
   302	cat >&2 <<EOF
   320	  # These surfaces own the coordination kernel, containment boundary, frozen twins,
   321	  # worktree safety, or CI gate itself. They require the full suite before merge.
   322	  # (GH-35 moved utils/pdda/** and skills/*/agent-chorus code off this list and into the
   323	  # subsystem registry, per the issue's Tier-2 mapping; their focused suites run instead.)
   324	  case "$path" in
   325	    validate.sh)
   326	      if ! is_validate_append_only; then
   327	        full_required=true
   328	      fi
   329	      ;;
   330	    .github/workflows/*|utils/ci-route.sh|test/ci-route.sh|test/ci-workflow.sh)
   331	      full_required=true
   332	      ;;
   333	    bin/tick|bin/validate-relay-block|src/*)
   334	      full_required=true
   335	      ;;
   336	    relay-automation/*|skills/*/relay-automation/*|skills/*/relay-xyz/*)
   337	      full_required=true
   338	      ;;
   339	    utils/py/*)
   340	      # Subsystem code with focused suites (releases_app.py, wave_reconcile.py, ATE tools)
rg: skills/4-occasional/relay-xyz/SKILL.md: No such file or directory (os error 2)
rg: skills/relay-xyz/SKILL.md: No such file or directory (os error 2)
SOP.md:63:   `python3 utils/py/releases_app.py roadmap add --issue-num N --issue-url U --title T --created YYYY-MM-DD --doc-path P`
SOP.md:65:   this repo it refuses with "releases-mode repo" and is never part of the flow.
SOP.md:68:### Step 1b: Promoting a capture from 1-INBOX to 2-WORKING (releases-mode)
SOP.md:70:The promotion procedure is four DB/file steps on the RELEASES DB:
SOP.md:77:2. Repoint the parked row: `python3 utils/py/releases_app.py roadmap repoint --issue-num <n> --doc-path PROJECT/2-WORKING/GH-<n>-<SLUG>.md`.
SOP.md:78:3. Refresh the row text: `python3 utils/py/releases_app.py roadmap update --issue-num <n> --raw-text '- **GH-<n> · <title>** ...'`
SOP.md:81:   HTML) and verify: `releases check` clean + `utils/pdda/pdda.sh run` zero errors. pdda's
SOP.md:82:   coverage check reads the DB in releases-mode — a promoted doc needs **no** `ROADMAP.md` line.
SOP.md:276:  (roadmap ← `releases_app.py roadmap list --json`; models ← `harnesses.db`) and are
SOP.md:278:  Change their *data* through the normal ledger verbs (`releases_app`, `harness_app`);
SOP.md:297:triggers on changes to `PAGES/**`, `utils/py/site_build.py`, `utils/py/releases_app.py`,
SOP.md:298:`releases.db`/`releases.sql`, `harnesses.db`/`harnesses.sql`, and the workflow file —

exec
/bin/zsh -lc "rg -n 'relay-self-sufficiency|2\\.3|2\\.7|D2' PROJECT/2-WORKING/GH-836-GATE-HOTSPOTS.md TESTS-RESULTS/2026-09-26+GH-835/machine-specs.md; rg -n '"'^  [a-zA-Z_-]+:'"' .github/workflows/ci.yml; rg --files skills | rg 'relay-xyz/SKILL.md|finish-line/SKILL.md'; nl -ba relay-automation/new-relay.sh | sed -n '68,116p'; nl -ba validate.sh | sed -n '1362,1394p'; nl -ba AGENTS.md | sed -n '134,145p'" in /private/var/folders/z0/92pfvhnn06z2_7hnpdb4kkbw0000gn/T/consult-wt-92092-h1_gqux_
 succeeded in 0ms:
PROJECT/2-WORKING/GH-836-GATE-HOTSPOTS.md:108:**R5 — agy's `relay-self-sufficiency` claim is true** (for D2, not this PR). The pre-push hook runs `validate.sh`
PROJECT/2-WORKING/GH-836-GATE-HOTSPOTS.md:110:full gate makes a real agent call when agy or codex is on `PATH` (`test/relay-self-sufficiency.sh:7-11`).
PROJECT/2-WORKING/GH-836-GATE-HOTSPOTS.md:165:- **D2:** skip `relay-self-sufficiency.sh`'s live agent turn in the local pre-push gate by default. R5 confirms
99:  push:
101:  pull_request:
103:  workflow_dispatch:
108:  group: ${{ github.workflow }}-${{ github.event_name }}-${{ github.event.pull_request.number || github.ref }}
109:  cancel-in-progress: true
112:  contents: read
150:  boundary-macos:
243:  canary-ubuntu:
519:  vendored-smoke:
skills/1-hourly/relay-xyz/SKILL.md
    68	-->
    69	
    70	NEXT: Reviewer
    71	STATUS: Open
    72	ROUND: 1 / $ROUND_CAP
    73	
    74	## ▶ TAKE YOUR TURN — read this first (works for ANY agent: Claude, Codex, agy)
    75	1. **Read this whole file** (header, Setup, Ground rules, every block in the Log).
    76	2. **Check it's your turn:** \`NEXT\` (top) names the role to act. Confirm you are bound to it and the
    77	   last Log block isn't already yours. If not → STOP and reply "wrong window — nudge the <other> window."
    78	3. **Do your role's work** on the artifact named in Setup:
    79	   - **Reviewer:** review vs the Definition of Done → graded findings
    80	     (\`[Blocker]\`/\`[Should]\`/\`[Nit]\`/\`[Pass]\`), each with a concrete fix → set a **VERDICT**
    81	     (exactly PASS, FAIL, or PARKED) and a **Basis** (explanation). **Review the whole file, not just the diff** (GH-268):
    82	     a beta test had this loop reach \`Approved\` in two rounds while an independent audit of the same
    83	     branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the
    84	     change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN
    85	     SCOPE; if you find none, say so explicitly rather than leaving it unstated.
    86	     **Declare it: every review block must contain a literal \`swept file: yes\` or \`swept file: no\`
    87	     line.** Without it a reviewer that skipped the sweep is indistinguishable in the transcript from
    88	     one that did it and found nothing — which is how the original 20 issues stayed invisible.
    89	     Any \`[Pass]\` or "verified"/"confirmed" finding MUST
    90	     carry a quoted span or a \`file:line\` citation — an uncited one is mechanically downgraded to
    91	     \`[Unverified — no citation]\` (GH-173 B3). Do **not** edit the artifact; only append findings here.
    92	     **A finding that asks for a behaviour change is a generalization unless you can paste the concrete
    93	     input — a row, a value, a \`file:line\` — that fails under the current code** (GH-681: the gh673
    94	     final QA relay generalized one late-error observation into "or a later invalid identity", the
    95	     Producer implemented it, the same seat \`[Pass]\`ed it next round, and one historical NULL-URL
    96	     ledger row then blanked every issue). Every \`[Blocker]\` or \`[Should]\` requesting a behaviour
    97	     change MUST carry three lines: \`Observed input:\` (the failing input you saw), \`Affected scope:\`
    98	     (the input predicate the change would govern), \`Falsifier:\` (the fixture or data that would show
    99	     the change unnecessary or wrong, and its expected result).
   100	     A \`[Blocker]\` must cite an observed failure. This is a protocol rule, not a mechanical check —
   101	     the Producer may disposition a request lacking these as \`Declined — unproven generalization\`.
   102	   - **Producer:** log a disposition for every open finding (Implemented / Modified / Declined + why,
   103	     including \`Declined — unproven generalization\` for a behaviour-change request that carries no
   104	     \`Observed input:\` / \`Affected scope:\` / \`Falsifier:\`), make the change, then add new work.
   105	4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns.
   106	   Reviewer headings may be \`### Reviewer · Round N\`, \`### Round N · Reviewer · <agent>\`, \`### Reviewer (<agent>)\` (optionally followed by \`— rN\`), or \`### Reviewer — Round N\` (optionally followed by \`(<agent>)\`); follow the heading with a non-empty review body.
   107	5. **Update the header:** flip \`NEXT\`; set \`STATUS\` (\`Approved\` closes — Reviewer only; else \`Open\`);
   108	   the Producer bumps \`ROUND\` when opening a new cycle. If the max \`ROUND\` ends without \`Approved\`,
   109	   set \`STATUS: Escalated\`.
   110	6. **Commit only the relay file** (\`relay($SLUG): <role> r<N>\`); no push. **Stop** and report one line.
   111	7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   112	   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   113	   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   114	   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   115	   was merely waiting looked stalled. A turn that ends without this line is not finished.
   116	
  1362	  vp_rerun_alone() {  # <suite> <why> [rc_first] — classify one suite by its ALONE verdict; never by the pool's
  1363	    local t="$1" why="$2" rc_first="${3:-1}" log _s _e rc_alone
  1364	    log="$RUN_DIR/$(printf '%s' "$t" | tr '/' '_').log"
  1365	    echo
  1366	    echo "==============================="
  1367	    echo "$why: $t — re-running it alone to see if that verdict survives"
  1368	    echo "==============================="
  1369	    _s="$(rt_now_ms)"
  1370	    if $NICE_CMD bash "$HERE/test/$t" > "$log.serial" 2>&1 </dev/null; then
  1371	      rc_alone=0
  1372	      PASSED+=("$t")
  1373	      CONTENDED+=("$t")
  1374	      echo "  ... PASSES when run alone. Counting it as passed (sequential is the source of truth)."
  1375	      echo "  ... This means a shared resource is contended — see the warning at the end of this run."
  1376	      rt_emit retry retry "$t" "$_s" "$(rt_now_ms)" "$rc_alone" "rc_first=$rc_first" "classified=contended"
  1377	      rt_suite retry "$t" "$_s" "$(rt_now_ms)" "$rc_alone" "$log.serial"
  1378	    else
  1379	      rc_alone=$?
  1380	      FAILED+=("$t")
  1381	      echo "  ... fails alone too. Real failure; last 40 lines of the SERIAL run:"
  1382	      tail -40 "$log.serial"
  1383	      rt_emit retry retry "$t" "$_s" "$(rt_now_ms)" "$rc_alone" "rc_first=$rc_first" "classified=real-failure"
  1384	      rt_suite retry "$t" "$_s" "$(rt_now_ms)" "$rc_alone" "$log.serial"
  1385	    fi
  1386	  }
  1387	  while IFS=' ' read -r rc t; do
  1388	    if [ "$rc" = "0" ]; then
  1389	      PASSED+=("$t")
  1390	      continue
  1391	    fi
  1392	    vp_rerun_alone "$t" "FAILED in parallel (rc=$rc)" "$rc"
  1393	  done < "$RESULTS"
  1394	
   134	## Repo-specific rails
   135	
   136	- **No new tests (GH-831, operator decision 2026-09-25).** This covers three things:
   137	  - Do not add a new `test/` suite or a new entry in `validate.sh`'s `TESTS` registry.
   138	  - Do not add new gate machinery: guards, lanes, runners or telemetry stages.
   139	  - Do not add a test to enforce this rule.
   140	
   141	  Verify a change with the existing suite that covers it, or with a manual check recorded under
   142	  `TESTS-RESULTS/<date>+GH-<n>/` with its `provenance.jsonl`. Edit an existing suite only to keep it truthful
   143	  when the behaviour it pins changes. A red control (see *Verified beats plausible*) is witnessed on an
   144	  existing suite or recorded as a manual check. Reviewers treat a new test file as a finding.
   145	

codex
**ANSWER: Choose C: skip the live turn by default at pre-push, but require an explicit, recorded live smoke check in the relay release checklist.** Keep failures meaningful when someone deliberately runs it. The risk is reduced detection of agent/backend drift between releases; a bare B leaves that risk unmanaged.

- **[Pass] Reconcile explicitly skips it; there is no cross-workflow environment inheritance.** `wave_reconcile.py` sets `RELAY_SELF_SUFFICIENCY_SKIP="1"` in the subprocess environment and passes that environment to the selected validator (`utils/py/wave_reconcile.py:647`, `:650`, `:671`). This also covers local qualification through that function. `ci-local.sh:404` sets it too.

- **[Should] Correct “all three jobs” to three test steps.** The cited settings exist at `.github/workflows/ci.yml:194`, `:402`, and `:483`, but the latter two belong to the same `canary-ubuntu` job. The conclusion about those test paths skipping the live turn remains correct.

- **[Should] The suite does not directly protect the generated production template.** It copies `test/fixtures/minimal-relay.md`; it never invokes `new-relay.sh` (`test/relay-self-sufficiency.sh:83`). The fixture supplies a trivial header-presence review and literal verdict example (`test/fixtures/minimal-relay.md:11`, `:23`). Production instructions include substantially different review, heading, round, and handoff requirements (`relay-automation/new-relay.sh:74`, `:92`, `:105`). This is useful live integration coverage of the **fixture, turn prompt, shim, agent, and tick**, not proof that the current scaffold is self-sufficient.

- **[Should] “Token handoff” overstates the assertions.** The suite checks shim exit zero, an additional relay-file commit, a claimer other than `claude-a`, an allowed VERDICT, and nonempty Basis (`test/relay-self-sufficiency.sh:130`, `:142`, `:163`, `:173`). It already releases the seed token before invoking the agent (`:104`); the later assertion does not independently establish the precise claim/release sequence or intended recipient. It also accepts `VERDICT: FAIL` as structurally valid.

- **[Pass] The local full gate currently attempts the live turn.** The hook invokes `validate.sh` without assigning the skip variable (`githooks/pre-push:295`); the suite is registered (`validate.sh:661`). Explicit skip and absent-agent cases exit zero; assertion failures exit one (`test/relay-self-sufficiency.sh:29`, `:57`, `:184`). Discovery also supports binary overrides and `~/.local/bin/agy`, so PATH is not the entire condition (`:38`). It is absent from Small (`utils/ci-route.sh:38`), and `relay-automation/*` requires full routing (`:336`).

- **[Should] Qualify the cost claim.** The committed #835 telemetry records a **61.596-second, non-skipped** run, not 2.3–2.7 minutes (`TESTS-RESULTS/2026-09-26+GH-835/gate-telemetry-b2c307b4.jsonl:386`). That does not disprove other measurements, but I cannot verify the supplied range from this receipt. One agent turn is not necessarily one API request or separately billed usage. A pooled failure can trigger another complete suite execution before refusing the push (`validate.sh:1362`, `:1392`).

- **[Should] The template changes regularly enough to deserve deliberate verification.** `git log -- relay-automation/new-relay.sh` shows the initial public import on August 15 and changes on **September 11, 17, and 22**: verdict vocabulary, reviewer evidence rules, and heading forms respectively (`99c263ea`, `55d8ab47`, `c0a9b899`). Those affect current lines `80`, `92`, and `106`. The minimal fixture’s history shows only the initial import—further evidence that these are distinct coverage surfaces.

The specific implementation I recommend is a hook-local default on the existing invocation:

```bash
RELAY_SELF_SUFFICIENCY_SKIP="${RELAY_SELF_SUFFICIENCY_SKIP:-1}" "$REPO/validate.sh"
```

That preserves `RELAY_SELF_SUFFICIENCY_SKIP=0` as opt-in and leaves direct validator behavior unchanged. Update the existing skip message so it names an explicit skip rather than incorrectly implying missing credentials (`test/relay-self-sufficiency.sh:30`).

Require the release reviewer to verify a **non-skipped** standalone run, in a disposable full clone, with committed provenance before relay releases and relevant fixture/prompt/shim changes. A zero exit alone is insufficient because missing agents also return zero. Use the existing evidence mechanism (`AGENTS.md:100`, `:141`); add no runner, lane, or guard. Template changes additionally need review evidence exercising the actual generated instructions.

Source-conditional execution would require new selection logic: the classifier currently expresses “full gate,” not this suite’s dependency set. I would not add that machinery. Nor would I convert agent/network failures into successful skips: that retains the latency while obscuring whether the check worked.

**RECOMMENDATION: C—default-skip at pre-push, preserve explicit opt-in and hard failures, and make non-skipped live evidence a named relay-release review obligation.**
tokens used
64,363
**ANSWER: Choose C: skip the live turn by default at pre-push, but require an explicit, recorded live smoke check in the relay release checklist.** Keep failures meaningful when someone deliberately runs it. The risk is reduced detection of agent/backend drift between releases; a bare B leaves that risk unmanaged.

- **[Pass] Reconcile explicitly skips it; there is no cross-workflow environment inheritance.** `wave_reconcile.py` sets `RELAY_SELF_SUFFICIENCY_SKIP="1"` in the subprocess environment and passes that environment to the selected validator (`utils/py/wave_reconcile.py:647`, `:650`, `:671`). This also covers local qualification through that function. `ci-local.sh:404` sets it too.

- **[Should] Correct “all three jobs” to three test steps.** The cited settings exist at `.github/workflows/ci.yml:194`, `:402`, and `:483`, but the latter two belong to the same `canary-ubuntu` job. The conclusion about those test paths skipping the live turn remains correct.

- **[Should] The suite does not directly protect the generated production template.** It copies `test/fixtures/minimal-relay.md`; it never invokes `new-relay.sh` (`test/relay-self-sufficiency.sh:83`). The fixture supplies a trivial header-presence review and literal verdict example (`test/fixtures/minimal-relay.md:11`, `:23`). Production instructions include substantially different review, heading, round, and handoff requirements (`relay-automation/new-relay.sh:74`, `:92`, `:105`). This is useful live integration coverage of the **fixture, turn prompt, shim, agent, and tick**, not proof that the current scaffold is self-sufficient.

- **[Should] “Token handoff” overstates the assertions.** The suite checks shim exit zero, an additional relay-file commit, a claimer other than `claude-a`, an allowed VERDICT, and nonempty Basis (`test/relay-self-sufficiency.sh:130`, `:142`, `:163`, `:173`). It already releases the seed token before invoking the agent (`:104`); the later assertion does not independently establish the precise claim/release sequence or intended recipient. It also accepts `VERDICT: FAIL` as structurally valid.

- **[Pass] The local full gate currently attempts the live turn.** The hook invokes `validate.sh` without assigning the skip variable (`githooks/pre-push:295`); the suite is registered (`validate.sh:661`). Explicit skip and absent-agent cases exit zero; assertion failures exit one (`test/relay-self-sufficiency.sh:29`, `:57`, `:184`). Discovery also supports binary overrides and `~/.local/bin/agy`, so PATH is not the entire condition (`:38`). It is absent from Small (`utils/ci-route.sh:38`), and `relay-automation/*` requires full routing (`:336`).

- **[Should] Qualify the cost claim.** The committed #835 telemetry records a **61.596-second, non-skipped** run, not 2.3–2.7 minutes (`TESTS-RESULTS/2026-09-26+GH-835/gate-telemetry-b2c307b4.jsonl:386`). That does not disprove other measurements, but I cannot verify the supplied range from this receipt. One agent turn is not necessarily one API request or separately billed usage. A pooled failure can trigger another complete suite execution before refusing the push (`validate.sh:1362`, `:1392`).

- **[Should] The template changes regularly enough to deserve deliberate verification.** `git log -- relay-automation/new-relay.sh` shows the initial public import on August 15 and changes on **September 11, 17, and 22**: verdict vocabulary, reviewer evidence rules, and heading forms respectively (`99c263ea`, `55d8ab47`, `c0a9b899`). Those affect current lines `80`, `92`, and `106`. The minimal fixture’s history shows only the initial import—further evidence that these are distinct coverage surfaces.

The specific implementation I recommend is a hook-local default on the existing invocation:

```bash
RELAY_SELF_SUFFICIENCY_SKIP="${RELAY_SELF_SUFFICIENCY_SKIP:-1}" "$REPO/validate.sh"
```

That preserves `RELAY_SELF_SUFFICIENCY_SKIP=0` as opt-in and leaves direct validator behavior unchanged. Update the existing skip message so it names an explicit skip rather than incorrectly implying missing credentials (`test/relay-self-sufficiency.sh:30`).

Require the release reviewer to verify a **non-skipped** standalone run, in a disposable full clone, with committed provenance before relay releases and relevant fixture/prompt/shim changes. A zero exit alone is insufficient because missing agents also return zero. Use the existing evidence mechanism (`AGENTS.md:100`, `:141`); add no runner, lane, or guard. Template changes additionally need review evidence exercising the actual generated instructions.

Source-conditional execution would require new selection logic: the classifier currently expresses “full gate,” not this suite’s dependency set. I would not add that machinery. Nor would I convert agent/network failures into successful skips: that retains the latency while obscuring whether the check worked.

**RECOMMENDATION: C—default-skip at pre-push, preserve explicit opt-in and hard failures, and make non-skipped live evidence a named relay-release review obligation.**
