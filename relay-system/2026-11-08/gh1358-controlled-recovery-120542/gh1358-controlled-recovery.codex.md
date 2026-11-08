**SINGLE-MODEL — NOT RECONCILED** (only codex answered; 1 of 2 requested advisor(s) failed — this is one model's read, not a cross-model consult. Do not treat any claim below as cross-verified.)

**NO FIRSTHAND VERIFICATION CITED** — treat conclusions as conditional (codex's answer carries an unsupported [Pass]/verified/confirmed-style claim with no quoted span or file:line citation nearby, despite the consult PREAMBLE asking advisors to cite evidence.)

> **ATTESTATION**
> Model: gpt-6.1-sol
> Provider: openai
> Sandbox: read-only

Reading additional input from stdin...
OpenAI Codex v0.167.0-alpha.3.2
--------
workdir: /private/var/folders/55/4ncr895946v1jymn1561yy340000gn/T/consult-wt-68417-hftky0hm
model: gpt-6.1-sol
provider: openai
approval: never
sandbox: read-only
reasoning effort: low
reasoning summaries: none
session id: 01a1bcc4-4eba-7151-aede-53561bd5fdfb
--------
user
You are an INDEPENDENT advisor in a one-shot cross-model consult. Another model is answering the SAME question separately and a coordinator will reconcile both answers, so give your own honest, specific read — do not hedge toward a consensus you cannot see. Read any repo files the question references (cite file:line). Respond with: (1) a short direct ANSWER; (2) graded FINDINGS — [Blocker]/[Should]/[Nit]/[Pass] — where applicable; (3) a one-line RECOMMENDATION. You are ADVISORY ONLY: output your analysis as text; do not rely on writing files (you are running in a throwaway copy).

=== CONSULT QUESTION ===
Review controlled persistent-state recovery, advisory read-only; no edits/tests/mutations. Source utils/py/jog_run.py JogCheckpoint, jog_resume, _jog_latest_receipt, jog_save_state, jog_project_marathon_outcome, _jog_retry_gate_locked. Primary /Users/noelsaw/Documents/GitHub/XYZ-forge live clean7da2f34ed043f860ad5014c3a5e206fba2fe1843 contains peer1318/1316 landings. Old supervisor1992 SIGSTOP afterchildfinished, checkpoint.json base980afdb13 phase running; lockpreservedoutsideprimary. Final terminal gate retry receipt gh1254-exec2-gateretry1 exit108 gate-killed stored /var/folders/55/4ncr895946v1jymn1561yy340000gn/T/gh1358-live-deployment-dr61f_tg/held-gh1254-final-result/marathon-result.json; symlink original .tick/jog/jog-01M6Y67FAWQFFXC8VQZ1J7HRNH/gh1254-exec2/gate-retry-1. state.json exec2 has no gate_retries entry because supervisor stoppedbeforepersistence. It insteadpoints originalexec2 admissionrefusal. No gate/builder active; sourceevidence0e503ac12 preserveslastfailure. Userauthorizes new90min recovery window gate1800, no newbuilder exhausted2/2, no schedules/merges. Proposedminimalrecovery: snapshot journal/state/ledger/receipt/hashes/refs, verify no children for1992 and no remotesideeffects pending, permanentlyterminate ONLYstoppedoldsupervisor withoutSIGCONT (SIGKILL preventsstale finally), preserveoldjournalbyrename outsideprimary so freshJogCheckpoint beginsatlivepeerbase underexistingprimarylock; register retainedretry metadata through existing jog_load_state/jog_save_state (appendonly, exactreceiptidentity validated), call jog_resume toprojectfailedgate truthfully, checkpoint.finish normalisolatedpublication. NoSQL/counterreset/oldreceiptedit. Validate primarynewcommitdescendspeerbase+bothmergeSHAs, retainspriorhistories andattempt2/2, cleanpublished. Then reuseexisting gate-onlyretry reviewedcandidate underfresh1800 budget, immutableoldinvocationpreserved, newdeadlineconfigurationonly. Is there a better existing supported recovery path? Identify concrete preservation hazards, whether directexisting statewriter invocation is acceptable versus minimalCLIextension. No architecture/generalization; stateclassification Easy reversible ownedmetadata backup butsharedpublication consequentialneedsindependentreview. Output concise approved/findings with filelines.

codex
I’ll inspect the recovery paths and state writers, focusing on preservation hazards and whether an existing command can perform this recovery safely.
exec
/bin/zsh -lc 'cat ROUTER.md; cat GUIDING-PRINCIPLES.md; cat WORKTREE-SAFETY.md' in /private/var/folders/55/4ncr895946v1jymn1561yy340000gn/T/consult-wt-68417-hftky0hm
 succeeded in 0ms:
# ROUTER.md

XYZ Forge exists for cross-model reviews and agentic work on business information, including private code, within the task’s authorized scope and applicable data-protection requirements.

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
- Captured GitHub issue docs in `PROJECT/1-INBOX/GH-*.md` exist as unstarted capture docs without a roadmap ledger row. Under GH-1340 / GH-1345 decision 6, the ledger row is created when work starts (at pickup/selection: `start-task`, Jog, `start-marathon`, `10days`), while active `2-WORKING` docs must have their pointer row. Governance lives in `PROJECT/PDDA.md` → "GitHub issue intake" + "ROADMAP contract".
- Incidental findings outside the active task go first to root `PARKED/` under its README contract.
  They need no issue or roadmap row until triage promotes them. “Queue / parked intake” in RELEASES
  names the later, formal issue queue; it is not a replacement for the root folder. Required work
  in the current task remains in its active plan rather than being parked.
- Do not create a second competing plan when a canonical `PROJECT/**` doc already exists.
- Issue-first: any change beyond a **2–3 line** fix opens a GitHub issue first, then a pointer doc **named after the issue** (`GH-<number>-VERY-SHORT-DESC.md`, e.g. `GH-1234-SHOWME-COMMAND.md`). Under decision 6, filing creates the issue and capture doc; the ledger row and stored rating are created when work starts (at pickup/selection) before execution begins. The issue is the signal stream; the pointer doc is the execution surface of record. Genuinely trivial edits (≤2–3 line fixes, typos, path repoints, doc-only one-liners) are exempt. Governed by `PROJECT/PDDA.md` → "GitHub issue intake".
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

**GH-1127 (2026-10-18, decision #1131): no hosted run per merge.** Development merges reconcile locally
(merge-cleanup → `wave_reconcile.py --pr N`). `wave-reconcile.yml` is dispatch-only; before each promotion
it runs `--promotion`, which always uses the full registry (`validate.sh --parallel 4`, #1134) on the
development tip and qualifies every landing since the last receipt together (procedure: AGENTS.md
**Promotion**). The GH-831 tiers below remain the classifier for a non-promotion `--qualify` run.

**GH-831 (2026-09-25) made these three tiers for what qualifies a landing.** The push hook is unchanged.
A non-promotion `--qualify` run picks **one** gate by classifying the landings' changes at the tested commit:

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
stays sequential. The post-push macOS boundary on main in `ci.yml` pins `--sequential` explicitly for the
same reason. The hosted pre-promotion qualification is the parallel exception (#1134 operator override;
its receipt records `mode`, `width` and any first-attempt failures). GH-528 Phase 2 (multi-width stress evidence) is still **owed** — the flip was an operator
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
python3 utils/py/releases_app.py roadmap pickup ... # GH-1345: create rated row at work pickup (start-task, Jog, marathon)
python3 utils/py/releases_app.py roadmap add ...    # low-level write path; puts row directly in roadmap
                                                   #   GH-249: put `rated N/N/N/N [ovr N]` in --raw-text to score it
python3 utils/py/releases_app.py roadmap rate ...   # GH-253: score a row that is ALREADY parked (--force to re-score)
python3 utils/py/releases_app.py roadmap list      # read the roadmap rows (--json for machine consumers)
python3 utils/py/releases_app.py roadmap sync      # LEGACY-mode only (mirrors ROADMAP.md); a guarded no-op in this repo
```

**Subsystem 1 — releases** (GH-32 / GH-568): the release ledger. App-managed writes
only; `releases.db` and the `releases` CLI (`releases list`, `releases show`) are the sole source of truth (`RELEASES.md` is retired per GH-568).
**Subsystem 2 — the roadmap ledger** (GH-69 shadow → GH-238/GH-243 canonical → GH-269 retired ROADMAP.md → GH-567 retired ROADMAP-DASHBOARD.md): since the
`ROADMAP_SOURCE=releases` flip, `roadmap_items` IS the ledger — write rows at pickup with
`releases roadmap pickup` (or `roadmap add`), read with `roadmap list`. `hq park` creates captures without premature ledger rows.
The legacy markdown roadmap files (ROADMAP and ROADMAP-DASHBOARD) have been retired. `roadmap sync` exists for legacy-mode repos only and
no-ops here by design (it would delete `add`-parked rows). Pinned by `test/gh69-roadmap-shadow.sh`,
`test/gh238-hq-releases-mode.sh`, `test/gh269-roadmap-retired.sh`, and `test/gh567-roadmap-dashboard-retired.sh`.

## Routing hints

- If the task is about current priorities or active work, start with `releases roadmap list`, then follow the linked `PROJECT/**` doc.
- If the task changes the roadmap ledger, write through the CLI (`releases roadmap pickup` at pickup/start time; start paths route there automatically).
- If the task touches `releases.db`, `releases.sql`, or a merge conflict on either, start in [RELEASES-DB-FAQS.md](RELEASES-DB-FAQS.md); writes go through the CLI, never a hand-edit.
- If the task is about fresh GitHub intake or duplicate-prevention, start in `PROJECT/1-INBOX/` and open issues (duplicate issue search + capture reuse), then inspect the roadmap ledger at pickup.
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
- Issue-first SOP: any change beyond a 2–3 line fix (and every project plan) opens a GitHub issue *first*, then gets a pointer doc named after the issue at `PROJECT/1-INBOX/GH-<number>-VERY-SHORT-DESC.md` — e.g. `GH-1234-SHOWME-COMMAND.md`. Row creation and stored rating are deferred to pickup/selection when work starts (decision 6), following the normal `1-INBOX` → `2-WORKING` flow. Genuinely trivial edits (≤2–3 line fixes, typos, path repoints, doc-only one-liners) are exempt and commit directly.
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

**Rigor must earn its cost.** Strong technical rigor supports useful, reliable work; it is not
an end in itself. Choose controls proportionate to the demonstrated risk, the task's scope and
the cost of recovery. Count their operational burden too: time, repeated reviews, maintenance
and interruptions. Prefer the simplest control that addresses the concrete failure, and simplify
or remove a rule when its burden outweighs its benefit. Explain the tradeoff so the operator can
choose; honor an explicit choice without quietly recreating the rejected restriction elsewhere.
Keep evidence honest about what was reviewed, tested and delivered, including any gaps. A
bookkeeping milestone need not repeat every quality gate: distinguish recording an outcome from
certifying its quality. This principle calls for deliberate changes to specific controls, not a
blanket bypass of containment, verification or protection against data loss.

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
This ordering guides doc-review tie-breakers; it does not exempt a control from
[the North Star](#the-north-star)’s proportionality assessment. Preserve containment while
considering simpler controls that adequately address the concrete failure.

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

**Published task closeout (GH-1059).** A start-task checkout need not remain on disk
until merge once its branch and ready PR are fully published to canonical origin.
Use merge-cleanup's explicit `--retire-published-pr N --checkout /absolute/task/path`
mode; do not turn an arbitrary pushed branch or cached tracking ref into proof.
It must bind the live same-origin, non-draft PR to its fetched origin head and prove
every local ref/HEAD recoverable from that head or an already verified landing.
All local-state, session, dependency, protected-path and fresh-inspection checks
still apply. Preserve local-only evidence and anything unknown; never delete the
protected primary or broaden this into a clone sweep. Run from outside the retiring
checkout. Full clones move only to Trash; linked worktrees use native Git removal
and retain their parent repository. In either cleanup mode, preserve a linked
worktree with any ignored files or a failed ignored-file enumeration: native removal
deletes ignored content, and Git refs do not prove its recovery. Ordinary cleanup
still requires the existing merged-only history proof.

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

One per-run addition sits outside that list: merge-cleanup also accepts the `--primary` clone's
parent folder, where start-task puts task clones (GH-970), unless that parent is a `NEVER_DELETE`
root. It counts only for checkouts whose `origin` names the primary's repository, and a failed or
empty origin lookup never matches, so another project's checkout in the same folder is neither
scanned by default nor removable. This holds in every mode: the default scan and Phase 6 teardown
(GH-722) and published-PR retirement (GH-1193). Checkouts inside a listed root are unaffected.

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
/bin/zsh -lc "rg -n 'class JogCheckpoint|def jog_resume|def _jog_latest_receipt|def jog_save_state|def jog_project_marathon_outcome|def _jog_retry_gate_locked|def jog_load_state|gate_retries|def finish' utils/py/jog_run.py" in /private/var/folders/55/4ncr895946v1jymn1561yy340000gn/T/consult-wt-68417-hftky0hm
 succeeded in 0ms:
312:def jog_load_state(root, gid):
327:def jog_save_state(root, gid, state):
381:def jog_project_marathon_outcome(root, gh_num, receipt, auto_merge=False,
686:def _jog_latest_receipt(root, gid, outcomes=None):
695:        candidates = [g.get("result_path") for g in reversed(record.get("gate_retries") or [])]
717:def jog_resume(root, gh_num, args=None):
740:        publication = next((entry for entry in reversed(latest.get("gate_retries") or [])
897:def _jog_retry_gate_locked(root, gh_num, args):
913:    published = ((record.get("gate_retries") or [{}])[-1].get("published_head")
958:    gate_retries = entry.setdefault("gate_retries", [])
959:    attempt_no = len(gate_retries) + 1
975:        gate_retries.append({"execution_id": record["execution_id"], "attempt": attempt_no,
981:    gate_retries.append({"execution_id": new_receipt["execution_id"], "attempt": attempt_no,
989:        gate_retries[-1]["committed_receipt"] = publish_jog_receipt(
991:        gate_retries[-1]["published_head"] = _git(invocation["target_root"], "rev-parse", "HEAD").decode().strip()
2059:class JogCheckpoint:
2115:    def finish(self):

exec
/bin/zsh -lc "nl -ba utils/py/jog_run.py | sed -n '290,450p;670,800p;860,1020p;2010,2270p'" in /private/var/folders/55/4ncr895946v1jymn1561yy340000gn/T/consult-wt-68417-hftky0hm
 succeeded in 0ms:
   290	        if os.path.isfile(path):
   291	            return gid
   292	    jog_dir = os.path.join(root, ".tick", "jog")
   293	    if not os.path.isdir(jog_dir):
   294	        return None
   295	    candidates = []
   296	    for name in os.listdir(jog_dir):
   297	        _base, path = _jog_state_paths(root, name)
   298	        if not os.path.isfile(path):
   299	            continue
   300	        try:
   301	            with open(path, "r", encoding="utf-8") as f:
   302	                state = json.load(f)
   303	        except (OSError, ValueError):
   304	            continue
   305	        if state.get("gh_number") == gh_num:
   306	            candidates.append((os.path.getmtime(path), name))
   307	    if not candidates:
   308	        return None
   309	    return max(candidates)[1]
   310	
   311	
   312	def jog_load_state(root, gid):
   313	    """Load the append-only execution ledger for a queue row; a fresh one if absent."""
   314	    _base, path = _jog_state_paths(root, gid)
   315	    if os.path.isfile(path):
   316	        try:
   317	            with open(path, "r", encoding="utf-8") as f:
   318	                state = json.load(f)
   319	            if isinstance(state, dict) and state.get("schema") == JOG_EXECUTION_STATE_SCHEMA \
   320	                    and isinstance(state.get("executions"), list):
   321	                return state
   322	        except (OSError, ValueError):
   323	            pass
   324	    return {"schema": JOG_EXECUTION_STATE_SCHEMA, "gid": gid, "executions": []}
   325	
   326	
   327	def jog_save_state(root, gid, state):
   328	    _require_jog_primary(root)
   329	    _base, path = _jog_state_paths(root, gid)
   330	    os.makedirs(_base, exist_ok=True)
   331	    tmp = path + f".tmp.{os.getpid()}"
   332	    with open(tmp, "w", encoding="utf-8") as f:
   333	        json.dump(state, f, indent=2)
   334	        f.write("\n")
   335	    os.replace(tmp, path)
   336	
   337	
   338	def jog_current_gid(root, gh_num):
   339	    """The queue row's global_id (its durable identity across retries)."""
   340	    conn = sqlite3.connect(os.path.join(root, "releases.db"))
   341	    conn.row_factory = sqlite3.Row
   342	    try:
   343	        row = conn.execute("SELECT global_id FROM jog_queue WHERE gh_number = ? "
   344	                           "ORDER BY id DESC LIMIT 1", (gh_num,)).fetchone()
   345	        return row["global_id"] if row else None
   346	    finally:
   347	        conn.close()
   348	
   349	
   350	def jog_verify_pr_before_merge(root, receipt, pr_number):
   351	    """GH-300 (PR #281 review B1): verify GitHub truth against the receipt BEFORE merging.
   352	
   353	    An approved receipt's PR identity is Marathon-owned and trusted as a record, but the
   354	    merge must not act on it blind: a stale PR number that happens to resolve in this repo
   355	    (or a PR whose head moved after the reviewed build) would otherwise be merged as-is.
   356	    Mirrors the verification family `jog land` performs post-merge, adapted to pre-merge:
   357	    the PR must still be OPEN with the receipt's base/head/head-SHA, the receipt must name
   358	    this repo, and the gate must be green for that head. Returns (failures, pr); an empty
   359	    failures list means the merge may proceed.
   360	    """
   361	    pr, err = _gh_pr_view(root, pr_number)
   362	    if pr is None:
   363	        return [f"pr view failed: {err}"], None
   364	    checks = [
   365	        ("state OPEN", pr.get("state") == "OPEN"),
   366	        (f"base {receipt.get('base_branch')}", pr.get("baseRefName") == receipt.get("base_branch")),
   367	        (f"head {receipt.get('head_branch')}", pr.get("headRefName") == receipt.get("head_branch")),
   368	        (f"head SHA {str(receipt.get('head_sha') or '')[:8]}",
   369	         pr.get("headRefOid") == receipt.get("head_sha")),
   370	        ("receipt repo is this repo",
   371	         not receipt.get("target_repo", {}).get("path")
   372	         or os.path.realpath(receipt["target_repo"]["path"]) == os.path.realpath(root)),
   373	    ]
   374	    gate = receipt.get("gate") or {}
   375	    checks.append(("gate green on the merge head",
   376	                   gate.get("result") == "green"
   377	                   and (not gate.get("receipt_path") or os.path.isfile(gate["receipt_path"]))))
   378	    return [name for name, ok in checks if not ok], pr
   379	
   380	
   381	def jog_project_marathon_outcome(root, gh_num, receipt, auto_merge=False,
   382	                                 execution_id=None, result_path=None):
   383	    """Project a validated Marathon result receipt into the queue via perform_write.
   384	
   385	    Marathon owns the outcome; this only records it. Returns the queue action taken
   386	    ("completed", "parked", "failed") plus a human reason. Never guesses a branch or PR:
   387	    landing identity comes from the receipt, and a green phase without a PR is parked with
   388	    the receipt's branch fields — it is never a global failure.
   389	
   390	    GH-291 Scope 4: refused/escalated/parked reasons carry a trace segment naming the
   391	    execution_id and result_path when the caller provides them, so a failed row points at
   392	    its receipt without a ledger inspection.
   393	    """
   394	    outcome = receipt.get("outcome")
   395	    reason = receipt.get("reason")
   396	    if outcome == "approved":
   397	        pr = receipt.get("pr") or {}
   398	        pr_number = pr.get("number")
   399	        if pr_number:
   400	            note = f"awaiting-landing (PR #{pr_number}: {pr.get('url') or 'url unavailable'})"
   401	            if auto_merge:
   402	                failures, _ = jog_verify_pr_before_merge(root, receipt, pr_number)
   403	                if failures:
   404	                    return "parked", (f"{note} — auto-merge refused (verification failed: "
   405	                                      f"{', '.join(failures)})")
   406	                # GH-505/GH-509: an approved receipt without a validated candidate came from an
   407	                # unattested run — park it; otherwise merge exactly that candidate.
   408	                if not receipt.get("reviewed_candidate") or not receipt.get("attest_path"):
   409	                    return "parked", f"{note} — auto-merge refused: receipt carries no reviewer attestation (GH-505)"
   410	                record, why = relay_attest.load(
   411	                    receipt.get("token"), expected_reviewer=receipt.get("reviewer"),
   412	                    relay_file=None, target_repo=root, path=receipt.get("attest_path"))
   413	                if record is None:
   414	                    return "parked", f"{note} — auto-merge refused: {why}"
   415	                merged, reason = _merge_reviewed_pr(root, pr_number, record,
   416	                                                    expected_candidate=receipt.get("reviewed_candidate"))
   417	                if merged:
   418	                    return "completed", f"marathon approved; PR #{pr_number} merged at {receipt['reviewed_candidate'][:12]}"
   419	                return "parked", f"{note} — auto-{reason}"
   420	            return "parked", note
   421	        head = receipt.get("head_branch")
   422	        base = receipt.get("base_branch")
   423	        pr_note = receipt.get("pr_note")
   424	        bits = [f"head={head or 'unknown'}", f"base={base or 'unknown'}"]
   425	        if pr_note:
   426	            bits.append(pr_note)
   427	        return "parked", "awaiting-landing (no PR yet — open one from the receipt's branches: " + \
   428	            "; ".join(bits) + ")"
   429	    label = f"marathon {outcome}: {reason} (exit {receipt.get('exit_code')})"
   430	    if execution_id or result_path:
   431	        label += f" [{execution_id or 'no-execution-id'}; result: {result_path or 'no-result-path'}]"
   432	    return ("failed", label) if outcome != "parked" else ("parked", label)
   433	
   434	
   435	def jog_reconcile_cold_start(root, gh_nums):
   436	    """GH-280 cold start for the marathon executor: for each orphan-reconciled row that has a
   437	    dispatched Marathon execution on record, inspect the durable result BEFORE the queue can
   438	    lease and refire. A valid terminal result is re-projected idempotently (no turn spent);
   439	    a dispatched execution with no valid result parks the row — never a silent refire."""
   440	    for gh_num in gh_nums:
   441	        gid = jog_resolve_ledger_gid(root, gh_num)
   442	        if not gid:
   443	            continue
   444	        state = jog_load_state(root, gid)
   445	        executions = state.get("executions") or []
   446	        if not executions:
   447	            continue
   448	        latest = executions[-1]
   449	        if latest.get("status") != "dispatched":
   450	            continue
   670	    record["status"] = "terminal"
   671	    record["outcome"] = receipt["outcome"]
   672	    record["reason"] = receipt["reason"]
   673	    jog_save_state(root, gid, state)
   674	
   675	    action, reason = jog_project_marathon_outcome(
   676	        root, gh_num, receipt, auto_merge=auto_merge,
   677	        execution_id=exec_id, result_path=invocation["result_path"])
   678	    record["status"] = f"projected-{action}"
   679	    record["projected_reason"] = reason
   680	    jog_save_state(root, gid, state)
   681	    return action, reason
   682	
   683	
   684	# ── GH-280 Phase 3: explicit resume / gate-only retry / rebuild / landing semantics ────────────
   685	
   686	def _jog_latest_receipt(root, gid, outcomes=None):
   687	    """Newest loadable receipt (optionally filtered by outcome): (record, receipt) or (None, None).
   688	
   689	    Scans executions newest-first; within an execution, its gate-retry receipts are newer than
   690	    the original dispatch receipt (a green gate retry is the outcome that lands). History is
   691	    read-only here — recovery never rewrites old receipts. Paths resolve relative-to-ledger
   692	    (GH-292 F2) with absolute legacy paths still honored."""
   693	    state = jog_load_state(root, gid)
   694	    for record in reversed(state.get("executions") or []):
   695	        candidates = [g.get("result_path") for g in reversed(record.get("gate_retries") or [])]
   696	        candidates.append(record.get("result_path"))
   697	        for rel_path in candidates:
   698	            path = _ledger_abs_path(root, gid, rel_path)
   699	            if not path or not os.path.isfile(path):
   700	                continue
   701	            try:
   702	                receipt = load_marathon_result(path)
   703	            except ContractError:
   704	                continue
   705	            if outcomes and receipt.get("outcome") not in outcomes:
   706	                continue
   707	            return record, receipt
   708	    return None, None
   709	
   710	
   711	def _jog_exec_dir(root, gid, record):
   712	    packet_dir = _ledger_abs_path(root, gid, record.get("packet_dir"))
   713	    return os.path.dirname(packet_dir or "") or \
   714	        os.path.join(_jog_state_paths(root, gid)[0], record.get("execution_id", "exec"))
   715	
   716	
   717	def jog_resume(root, gh_num, args=None):
   718	    """`jog resume <GH>` — reconcile existing durable state, spend nothing.
   719	
   720	    Reconciliation only: a valid terminal receipt is re-projected idempotently (no dispatch,
   721	    no token); a dispatched execution without a receipt parks the row (the operator chooses
   722	    retry-build); anything else is reported. Resume never fires Marathon on its own — a new
   723	    fire is always the explicit retry-build decision."""
   724	    _require_jog_primary(root)
   725	    gid = jog_resolve_ledger_gid(root, gh_num)
   726	    if not gid:
   727	        print(f"jog: GH-{gh_num} is not in the jog queue")
   728	        sys.exit(2)
   729	    state = jog_load_state(root, gid)
   730	    executions = state.get("executions") or []
   731	    if not executions:
   732	        print(f"jog: GH-{gh_num} has no marathon execution state — run `releases jog run "
   733	              f"--reviewer <agent>` (marathon is the default executor) or `jog retry-build` "
   734	              f"to dispatch")
   735	        return 0
   736	
   737	    latest = executions[-1]
   738	    record, receipt = _jog_latest_receipt(root, gid)
   739	    if record is not None and record.get("execution_id") == latest.get("execution_id"):
   740	        publication = next((entry for entry in reversed(latest.get("gate_retries") or [])
   741	                            if entry.get("execution_id") == receipt.get("execution_id")), latest)
   742	        invocation_path = os.path.join(_ledger_abs_path(root, gid, latest.get("packet_dir")) or "", "marathon-invocation.json")
   743	        if receipt.get("outcome") == "approved" and not publication.get("committed_receipt") and os.path.isfile(invocation_path):
   744	            invocation = load_marathon_invocation(invocation_path)
   745	            target = _execution_root(root, invocation["target_root"])
   746	            publication["committed_receipt"] = publish_jog_receipt(
   747	                target, receipt, _ledger_abs_path(root, gid, publication.get("result_path")),
   748	                base_ref="development")
   749	            publication["published_head"] = _git(target, "rev-parse", "HEAD").decode().strip()
   750	        action, reason = jog_project_marathon_outcome(
   751	            root, gh_num, receipt,
   752	            execution_id=latest.get("execution_id"), result_path=latest.get("result_path"))
   753	        latest["status"] = f"projected-{action}"
   754	        latest["projected_reason"] = reason
   755	        jog_save_state(root, gid, state)
   756	        jog_set_status(root, gh_num, action, failure_reason=reason)
   757	        print(f"jog: resume GH-{gh_num}: terminal Marathon result re-projected ({action}) — {reason}")
   758	        return 0
   759	    if latest.get("status") == "dispatched":
   760	        # GH-291 Scope 2: distinguish a future-schema/invalid receipt from a missing one —
   761	        # version skew must park with its cause named, not read as "no result".
   762	        load_error = None
   763	        _p = _ledger_abs_path(root, gid, latest.get("result_path"))
   764	        if _p and os.path.isfile(_p):
   765	            try:
   766	                load_marathon_result(_p)
   767	            except ContractError as exc:
   768	                load_error = str(exc)
   769	        latest["status"] = "cold-start-paused"
   770	        jog_save_state(root, gid, state)
   771	        jog_set_status(root, gh_num, "parked",
   772	                       failure_reason="resume: dispatched Marathon execution has no valid result "
   773	                                      "receipt"
   774	                                      + (f" (load error: {load_error})" if load_error else "")
   775	                                      + " — inspect, then `jog retry-build` if a rebuild is wanted")
   776	        print(f"jog: resume GH-{gh_num}: execution {latest.get('execution_id')} dispatched with no "
   777	              f"valid result{f' ({load_error})' if load_error else ''} — parked; no token spent")
   778	        return 1
   779	    print(f"jog: resume GH-{gh_num}: latest execution {latest.get('execution_id')} is "
   780	          f"'{latest.get('status')}' — nothing to reconcile; use jog retry-gate / retry-build / land")
   781	    return 0
   782	
   783	
   784	def jog_retry_gate(root, gh_num, args):
   785	    """`jog retry-gate <GH>` — re-run ONLY the gate against the same head SHA.
   786	
   787	    Marathon's native satisfied-lane path (GH-274) is the mechanism: with the phase's relay
   788	    terminal and its tick token done, re-invoking marathon-drive skips render/reseed/dispatch
   789	    and re-runs the pre-advance gate alone. Jog refuses if the head SHA moves during the
   790	    retry — that state needs retry-build, not a gate check."""
   791	    _require_jog_primary(root)
   792	    error = validate_marathon_executor(args)
   793	    if error:
   794	        print(f"jog: {error}", file=sys.stderr)
   795	        sys.exit(2)
   796	    # GH-300 (B2): retry verbs dispatch marathon-drive exactly like the run executor, so
   797	    # they hold the same supervisor lock — a retry fired beside a live drive is precisely
   798	    # the concurrency the lock exists to prevent (GH-42 / GH-354).
   799	    supervisor_lock = JogSupervisorLock(root)
   800	    supervisor_lock.acquire()
   860	        phase_rel = os.path.normpath(os.path.join(phases_dir, phase, "RELAY.md"))
   861	        allowed_files.add(phase_rel)
   862	        d = os.path.dirname(phase_rel)
   863	        for name in relay_attest.PHASE_RECORDS:
   864	            allowed_files.add(os.path.normpath(os.path.join(d, name)))
   865	
   866	    if receipt.get("relay_file_rel"):
   867	        r_rel = os.path.normpath(receipt["relay_file_rel"])
   868	        allowed_files.add(r_rel)
   869	        d = os.path.dirname(r_rel)
   870	        for name in relay_attest.PHASE_RECORDS:
   871	            allowed_files.add(os.path.normpath(os.path.join(d, name)))
   872	
   873	    if "--relay-file" in argv:
   874	        try:
   875	            idx = argv.index("--relay-file")
   876	            if idx + 1 < len(argv):
   877	                rf = argv[idx + 1]
   878	                rf_rel = os.path.relpath(rf, target_root) if os.path.isabs(rf) else rf
   879	                allowed_files.add(os.path.normpath(rf_rel))
   880	                d = os.path.dirname(rf_rel)
   881	                for name in relay_attest.PHASE_RECORDS:
   882	                    allowed_files.add(os.path.normpath(os.path.join(d, name)))
   883	        except (ValueError, IndexError):
   884	            pass
   885	
   886	    for path in changed_paths:
   887	        norm = os.path.normpath(path)
   888	        if norm.startswith(f"{relay_attest.TRANSCRIPT_DIR}/") or norm == relay_attest.TRANSCRIPT_DIR:
   889	            continue
   890	        if norm in allowed_files:
   891	            continue
   892	        return False, f"head moved (tail commit changes non-relay path: {path})"
   893	
   894	    return True, None
   895	
   896	
   897	def _jog_retry_gate_locked(root, gh_num, args):
   898	    gid = jog_resolve_ledger_gid(root, gh_num)
   899	    if not gid:
   900	        # Same refusal retry-build already had: a None gid here would otherwise surface
   901	        # as a TypeError traceback from jog_load_state instead of a clean exit.
   902	        print(f"jog: GH-{gh_num} has no jog queue row and no execution ledger", file=sys.stderr)
   903	        sys.exit(2)
   904	    record, receipt = _jog_latest_receipt(root, gid, outcomes=("approved",))
   905	    if record is None:
   906	        # A red gate escalates with outcome 'escalated'; the relay behind it is terminal and
   907	        # its receipt still names the head — retry-gate applies there too.
   908	        record, receipt = _jog_latest_receipt(root, gid, outcomes=("escalated",))
   909	    if record is None:
   910	        print(f"jog: GH-{gh_num} has no terminal Marathon execution to gate-retry", file=sys.stderr)
   911	        sys.exit(2)
   912	
   913	    published = ((record.get("gate_retries") or [{}])[-1].get("published_head")
   914	                 or record.get("published_head"))
   915	    prior_head = published or receipt.get("head_sha")
   916	    invocation_path = os.path.join(
   917	        _ledger_abs_path(root, gid, record.get("packet_dir")), "marathon-invocation.json")
   918	    try:
   919	        invocation = load_marathon_invocation(invocation_path)
   920	    except ContractError as exc:
   921	        print(f"jog: cannot gate-retry — {exc}", file=sys.stderr)
   922	        sys.exit(2)
   923	
   924	    _execution_root(root, invocation["target_root"])
   925	    ledger_before = _ledger_bytes(invocation["target_root"])
   926	
   927	    # The head-moved guard runs BEFORE dispatch: marathon's own runs commit transcripts (the
   928	    # receipt head legitimately advances by those), so the meaningful invariant is that the
   929	    # head is UNCHANGED between the execution and this retry — checked against the live repo
   930	    # pre-dispatch, not against the post-run receipt (which would false-trip on the retry's
   931	    # own transcript commit and burn a gate run to report it).
   932	    # GH-1332: accept a candidate head when all commits after prior_head touch only the lane's
   933	    # relay file or transcripts (the same candidate + receipt-only tail rule Phase 0 set).
   934	    pre_head = subprocess.run(["git", "rev-parse", "HEAD"], cwd=invocation["target_root"],
   935	                              capture_output=True, text=True)
   936	    if pre_head.returncode == 0 and pre_head.stdout.strip() != prior_head:
   937	        curr_head = pre_head.stdout.strip()
   938	        is_tail, tail_why = _is_relay_receipt_tail(
   939	            invocation["target_root"], prior_head, curr_head, invocation, receipt)
   940	        if not is_tail:
   941	            print(f"jog: refusing gate retry for GH-{gh_num} — head is {curr_head[:8]} "
   942	                  f"but the execution ran on {str(prior_head or '')[:8]}; the head moved between "
   943	                  f"runs (use jog retry-build)", file=sys.stderr)
   944	            sys.exit(2)
   945	        prior_head = curr_head
   946	
   947	    if published == prior_head and receipt.get("outcome") == "approved":
   948	        print("jog: approved gate receipt is already published; no gate retry needed")
   949	        return 0
   950	
   951	    state = jog_load_state(root, gid)
   952	    entry = next((e for e in state.get("executions") or []
   953	                  if e.get("execution_id") == record["execution_id"]), None)
   954	    if entry is None:
   955	        print(f"jog: ledger lost execution {record['execution_id']} — refusing to gate-retry",
   956	              file=sys.stderr)
   957	        sys.exit(2)
   958	    gate_retries = entry.setdefault("gate_retries", [])
   959	    attempt_no = len(gate_retries) + 1
   960	    retry_dir = os.path.join(_jog_exec_dir(root, gid, record), f"gate-retry-{attempt_no}")
   961	    os.makedirs(retry_dir, exist_ok=True)
   962	    argv = _marathon_argv_from_invocation(invocation, args.builder, args.reviewer)
   963	    argv += ["--execution-id", f"{record['execution_id']}-gateretry{attempt_no}",
   964	             "--result-file", os.path.join(retry_dir, "marathon-result.json")]
   965	
   966	    env = _marathon_env_from_invocation(invocation)
   967	    env.pop("RELAY_DRIVER_LOCKED", None)
   968	    print(f"jog: gate-only retry for GH-{gh_num} against head {prior_head} "
   969	          f"(no builder turn; satisfied-lane path)")
   970	    proc = subprocess.run(argv, cwd=invocation["target_root"], env=env)
   971	    result_path = os.path.join(retry_dir, "marathon-result.json")
   972	    try:
   973	        new_receipt = load_marathon_result(result_path)
   974	    except ContractError as exc:
   975	        gate_retries.append({"execution_id": record["execution_id"], "attempt": attempt_no,
   976	                             "status": "no-valid-result", "drive_exit": proc.returncode})
   977	        jog_save_state(root, gid, state)
   978	        print(f"jog: gate retry exited {proc.returncode} without a valid receipt: {exc}",
   979	              file=sys.stderr)
   980	        sys.exit(2)
   981	    gate_retries.append({"execution_id": new_receipt["execution_id"], "attempt": attempt_no,
   982	                         "status": new_receipt.get("outcome"),
   983	                         "result_path": result_path})
   984	    jog_save_state(root, gid, state)
   985	
   986	    if _ledger_bytes(invocation["target_root"]) != ledger_before:
   987	        raise ContractError("gate retry changed execution clone ledger")
   988	    if new_receipt.get("outcome") == "approved":
   989	        gate_retries[-1]["committed_receipt"] = publish_jog_receipt(
   990	            invocation["target_root"], new_receipt, result_path, base_ref="development")
   991	        gate_retries[-1]["published_head"] = _git(invocation["target_root"], "rev-parse", "HEAD").decode().strip()
   992	        jog_save_state(root, gid, state)
   993	    action, reason = jog_project_marathon_outcome(
   994	        root, gh_num, new_receipt,
   995	        auto_merge=getattr(args, "auto_merge", False),
   996	        execution_id=f"{record['execution_id']}-gateretry{attempt_no}",
   997	        result_path=_ledger_rel_path(root, gid, result_path))
   998	    jog_set_status(root, gh_num, action, failure_reason=reason)
   999	    print(f"jog: gate retry result: {new_receipt.get('outcome')} → queue {action} — {reason}")
  1000	    return 0 if new_receipt.get("outcome") == "approved" else 1
  1001	
  1002	
  1003	def jog_retry_build(root, gh_num, args):
  1004	    """`jog retry-build <GH>` — a fresh Marathon attempt on a fresh execution id.
  1005	
  1006	    Marathon's namespaced attempt record is the sole retry cap: the lane key is unchanged, so
  1007	    attempts accumulate and the cap parks the lane exactly as an ordinary marathon caller
  1008	    would experience. All prior Tick history and execution records are preserved."""
  1009	    _require_jog_primary(root)
  1010	    _execution_root(root, getattr(args, "target_root", None))
  1011	    error = validate_marathon_executor(args)
  1012	    if error:
  1013	        print(f"jog: {error}", file=sys.stderr)
  1014	        sys.exit(2)
  1015	    # GH-300 (B2): same supervisor lock as the run executor — see jog_retry_gate.
  1016	    supervisor_lock = JogSupervisorLock(root)
  1017	    supervisor_lock.acquire()
  1018	    try:
  1019	        return _jog_retry_build_locked(root, gh_num, args)
  1020	    finally:
  2010	                print(f"jog: auto-merge refused/failed: {reason}", file=sys.stderr)
  2011	                return False, "parked", f"auto-{reason}"
  2012	        else:
  2013	            # GH-510: no PR is not a landed task.
  2014	            return False, "parked", f"awaiting-landing (no open PR found for feat/gh{gh_num})"
  2015	
  2016	        # Re-anchor on development
  2017	        subprocess.run(["git", "checkout", "development"], cwd=root, capture_output=True)
  2018	        subprocess.run(["git", "pull", "--ff-only", "origin", "development"], cwd=root, capture_output=True)
  2019	        return True, "completed", None
  2020	
  2021	    if not sys.stdin.isatty():
  2022	        print(f"jog: unattended run without --auto-merge -> parking GH-{gh_num} awaiting landing confirmation.")
  2023	        return False, "parked", "awaiting-landing (unattended run without --auto-merge)"
  2024	
  2025	    print(f"\n[jog] Task GH-{gh_num} completed drive pass.")
  2026	    resp = input(f"Confirm merge into development and advance to next item? [Y/n] ").strip().lower()
  2027	    if resp in ("n", "no"):
  2028	        print(f"jog: operator paused merge for GH-{gh_num}; parking item in awaiting-landing state.")
  2029	        return False, "parked", "awaiting-landing (operator paused merge)"
  2030	
  2031	    # Operator confirmed merge
  2032	    pr_view = subprocess.run(
  2033	        ["gh", "pr", "list", "--head", f"feat/gh{gh_num}", "--json", "number,state", "--jq", ".[0].number"],
  2034	        cwd=root,
  2035	        capture_output=True,
  2036	        text=True,
  2037	    )
  2038	    pr_num = pr_view.stdout.strip()
  2039	    if pr_num and pr_num.isdigit():
  2040	        failures = _verify_legacy_pr_before_merge(root, pr_num)
  2041	        if failures:
  2042	            print(f"jog: merge refused (verification failed: {', '.join(failures)}) — parking; "
  2043	                  f"the discovered PR is not mergeable into development as confirmed",
  2044	                  file=sys.stderr)
  2045	            return False, "parked", f"merge refused (verification failed: {', '.join(failures)})"
  2046	        merged, reason = _merge_reviewed_pr(root, pr_num, record)
  2047	        if not merged:
  2048	            # GH-510: this branch used to discard the merge result and report completed.
  2049	            print(f"jog: {reason} — parking GH-{gh_num}", file=sys.stderr)
  2050	            return False, "parked", reason
  2051	    else:
  2052	        return False, "parked", f"awaiting-landing (no open PR found for feat/gh{gh_num})"
  2053	
  2054	    subprocess.run(["git", "checkout", "development"], cwd=root, capture_output=True)
  2055	    subprocess.run(["git", "pull", "--ff-only", "origin", "development"], cwd=root, capture_output=True)
  2056	    return True, "completed", None
  2057	
  2058	
  2059	class JogCheckpoint:
  2060	    """Opt-in publication around one existing Jog invocation (GH-1207/1358).
  2061	
  2062	    The primary owns only the two ledger artifacts. Push hooks run in a dedicated,
  2063	    disposable full clone. A retained journal makes a failed push retry publication
  2064	    before another queue effect; interrupted execution still uses Jog cold recovery.
  2065	    """
  2066	    paths = ("releases.db", "releases.sql")
  2067	
  2068	    def __init__(self, root, publication_root):
  2069	        self.root = root
  2070	        self.publication = os.path.realpath(publication_root)
  2071	        self.journal = Path(root, ".tick", "jog", "checkpoint.json")
  2072	        if (self.publication == os.path.realpath(root)
  2073	                or not Path(self.publication, ".git").is_dir()
  2074	                or primary_config_key(root) != primary_config_key(self.publication)):
  2075	            raise ContractError("checkpoint root must be a separate full clone with the same origin")
  2076	        self.state = None
  2077	
  2078	    def save(self):
  2079	        self.journal.parent.mkdir(parents=True, exist_ok=True)
  2080	        temporary = self.journal.with_suffix(".tmp")
  2081	        temporary.write_text(json.dumps(self.state, indent=2) + "\n")
  2082	        os.replace(temporary, self.journal)
  2083	
  2084	    def dirty(self, root):
  2085	        # Porcelain -z avoids quoting/whitespace ambiguity. Renames are foreign too.
  2086	        return _git(root, "status", "--porcelain=v1", "-z", "--untracked-files=all").decode().split("\0")
  2087	
  2088	    def check_owned(self):
  2089	        foreign = [r for r in self.dirty(self.root) if r and r[3:] not in self.paths]
  2090	        if foreign:
  2091	            raise ContractError("checkpoint refuses unrelated changes: " + repr(foreign))
  2092	
  2093	    def begin(self):
  2094	        _require_jog_primary(self.root)
  2095	        self.check_owned()
  2096	        if self.journal.exists():
  2097	            self.state = json.loads(self.journal.read_text())
  2098	            if self.state.get("phase") != "published":
  2099	                # Never dispatch a new task to recover an interrupted wake.
  2100	                reconciled = jog_reconcile_orphan_leases(self.root)
  2101	                jog_reconcile_cold_start(self.root, reconciled)
  2102	                self.finish()
  2103	                return False
  2104	        if any(self.dirty(self.root)):
  2105	            raise ContractError("checkpoint refuses pre-existing ledger changes without an active journal")
  2106	        _git(self.root, "fetch", "origin", "development")
  2107	        head = _git(self.root, "rev-parse", "HEAD").decode().strip()
  2108	        remote = _git(self.root, "rev-parse", "origin/development").decode().strip()
  2109	        if head != remote:
  2110	            raise ContractError("checkpoint requires primary HEAD at published origin/development")
  2111	        self.state = {"base": head, "phase": "running"}
  2112	        self.save()
  2113	        return True
  2114	
  2115	    def finish(self):
  2116	        self.check_owned()
  2117	        head = _git(self.root, "rev-parse", "HEAD").decode().strip()
  2118	        expected = self.state.get("commit", self.state["base"])
  2119	        if head != expected:
  2120	            # A crash immediately after commit is recognized by its exact parent/message.
  2121	            parent = _git(self.root, "rev-parse", "HEAD^").decode().strip()
  2122	            message = _git(self.root, "log", "-1", "--format=%s").decode().strip()
  2123	            if parent != self.state["base"] or message != self.message():
  2124	                raise ContractError("checkpoint primary HEAD changed outside this wake")
  2125	        if any(self.dirty(self.root)):
  2126	            if self.state.get("commit"):
  2127	                raise ContractError("checkpoint has new changes after its recorded commit")
  2128	            _git(self.root, "add", "--", *self.paths)
  2129	            _git(self.root, "commit", "-m", self.message(), "--", *self.paths)
  2130	        self.state["commit"] = _git(self.root, "rev-parse", "HEAD").decode().strip()
  2131	        self.state["phase"] = "committed"
  2132	        self.save()
  2133	        pub = self.publication
  2134	        if any(self.dirty(pub)):
  2135	            raise ContractError("checkpoint publication clone is dirty; preserve it before retry")
  2136	        if _git(pub, "symbolic-ref", "--short", "HEAD").decode().strip() != "development":
  2137	            raise ContractError("checkpoint publication clone must be on development")
  2138	        _git(pub, "fetch", self.root, self.state["commit"])
  2139	        _git(pub, "merge", "--ff-only", self.state["commit"])
  2140	        if _git(pub, "rev-parse", "HEAD").decode().strip() != self.state["commit"]:
  2141	            raise ContractError("publication clone contains commits beyond this checkpoint")
  2142	        # An empty wake or a crash after successful push needs no second push gate.
  2143	        # Read the live ref, not a potentially stale local tracking ref.
  2144	        published = _git(pub, "ls-remote", "--exit-code", "origin",
  2145	                         "refs/heads/development").decode().split()[0]
  2146	        if published != self.state["commit"]:
  2147	            # Normal push: never bypass the clone's configured gate or force a ref.
  2148	            _git(pub, "push", "origin", self.state["commit"] + ":refs/heads/development")
  2149	        _git(self.root, "fetch", "origin", "development")
  2150	        self.state["phase"] = "published"
  2151	        self.save()
  2152	        print("jog: published primary checkpoint " + self.state["commit"])
  2153	
  2154	    def message(self):
  2155	        return "jog: publish wake checkpoint " + self.state["base"]
  2156	
  2157	
  2158	def jog_run_main(args=None):
  2159	    """Main execution loop for jog supervisor."""
  2160	    if args is None:
  2161	        parser = argparse.ArgumentParser(description="Jog serial execution runner")
  2162	        parser.add_argument("--root", default=None, help="repository root path")
  2163	        parser.add_argument("--target-root", help="disposable full execution clone")
  2164	        parser.add_argument("--auto-merge", action="store_true", help="auto-merge passing PRs")
  2165	        parser.add_argument("--builder", default="agy", help="builder turn-taker (agy, codex, aider)")
  2166	        parser.add_argument("--reviewer", default=None,
  2167	                            help="reviewer agent — REQUIRED with --executor marathon (the "
  2168	                                 "default executor; no default is selected; must differ from "
  2169	                                 "--builder)")
  2170	        parser.add_argument("--executor", choices=["relay", "marathon"], default="marathon",
  2171	                            help="per-task executor (GH-280 Phase 5): 'marathon' is the default — "
  2172	                                 "the reviewed one-phase driver via the structured contracts, "
  2173	                                 "requires --reviewer; 'relay' is the legacy rollback path kept "
  2174	                                 "for a documented compatibility window")
  2175	        parser.add_argument("--checkpoint-root", help="dedicated disposable publication clone; one-task wake")
  2176	        parser.add_argument("--max-tasks", type=int, default=None, help="max tasks to process")
  2177	        parser.add_argument("--simulate", action="store_true", help="simulate drive execution (test mode)")
  2178	        parser.add_argument("--dry-run", action="store_true", help="simulate queue run without mutations")
  2179	        args = parser.parse_args()
  2180	
  2181	    # GH-280 Phase 5: marathon is the default executor. A namespace without an `executor`
  2182	    # attribute (programmatic callers) resolves to the same default as the CLI.
  2183	    executor = getattr(args, "executor", "marathon") or "marathon"
  2184	    simulate = getattr(args, "simulate", False)
  2185	    dry_run = getattr(args, "dry_run", False)
  2186	
  2187	    # Delivery 1 needs an explicit primary publication checkpoint before landing,
  2188	    # regardless of executor. Refuse before any supervisor state mutation.
  2189	    if not simulate and not dry_run and getattr(args, "auto_merge", False):
  2190	        print(f"jog: {JOG_AUTO_MERGE_CHECKPOINT}", file=sys.stderr)
  2191	        sys.exit(2)
  2192	
  2193	    # GH-280: reviewer/executor validation happens BEFORE the driver lock or any lease — an
  2194	    # invalid configuration must not mutate queue state at all. --simulate and --dry-run are
  2195	    # excluded: both stay on the hermetic/relay machinery and dispatch no Marathon execution,
  2196	    # so the reviewer policy (which governs real dispatches) does not apply to them.
  2197	    if executor == "marathon" and not simulate and not dry_run:
  2198	        executor_error = validate_marathon_executor(args)
  2199	        if executor_error:
  2200	            print(f"jog: {executor_error}", file=sys.stderr)
  2201	            sys.exit(2)
  2202	
  2203	    # GH-280 Phase 5: anything still on the relay machinery is legacy — explicit
  2204	    # `--executor relay` (THE documented rollback path) or `--simulate` (which stays on the
  2205	    # relay machinery by design). --dry-run dispatches nothing, so it stays silent.
  2206	    if not dry_run and (executor == "relay" or simulate):
  2207	        print(JOG_RELAY_DEPRECATION_NOTICE, file=sys.stderr)
  2208	
  2209	    root = os.path.abspath(getattr(args, "root", None) or os.getcwd())
  2210	    db_path = os.path.join(root, "releases.db")
  2211	
  2212	    if not os.path.exists(db_path):
  2213	        print(f"jog: releases.db not found at {db_path}", file=sys.stderr)
  2214	        sys.exit(1)
  2215	
  2216	    # Hermetic --dry-run: zero mutations, zero locks, zero DB writes
  2217	    if getattr(args, "dry_run", False):
  2218	        print(f"jog: [dry-run] simulating queue execution (root: {root})")
  2219	        conn = sqlite3.connect(f"file:{db_path}?mode=ro", uri=True)
  2220	        conn.row_factory = sqlite3.Row
  2221	        try:
  2222	            if not _table_exists(conn, "jog_queue"):
  2223	                print("jog: [dry-run] queue is empty (not initialized).")
  2224	                return
  2225	            rows = conn.execute(
  2226	                "SELECT gh_number, position, attempt_count FROM jog_queue WHERE status = 'pending' ORDER BY position ASC"
  2227	            ).fetchall()
  2228	            if not rows:
  2229	                print("jog: [dry-run] queue is empty (0 pending items).")
  2230	                return
  2231	            max_t = getattr(args, "max_tasks", None)
  2232	            limit_str = f" (capped at {max_t})" if max_t is not None else ""
  2233	            print(f"jog: [dry-run] would process {len(rows)} pending item(s){limit_str}:")
  2234	            for idx, r in enumerate(rows):
  2235	                if max_t is not None and idx >= max_t:
  2236	                    break
  2237	                print(f"  {r['position']}. GH-{r['gh_number']} (builder={args.builder}, auto_merge={args.auto_merge})")
  2238	        finally:
  2239	            conn.close()
  2240	        return
  2241	
  2242	    _require_jog_primary(root)
  2243	    try:
  2244	        target = _execution_root(root, getattr(args, "target_root", None))
  2245	    except (ContractError, OSError, subprocess.CalledProcessError) as exc:
  2246	        print(f"jog: {exc}", file=sys.stderr)
  2247	        sys.exit(2)
  2248	    checkpoint_root = getattr(args, "checkpoint_root", None)
  2249	    if checkpoint_root and (args.max_tasks != 1 or simulate or executor != "marathon"):
  2250	        raise ContractError("--checkpoint-root requires --max-tasks 1 and the real Marathon executor")
  2251	    if checkpoint_root and os.path.realpath(checkpoint_root) == os.path.realpath(target):
  2252	        raise ContractError("publication and execution clones must be distinct")
  2253	    supervisor_lock = JogSupervisorLock(root)
  2254	    supervisor_lock.acquire()
  2255	
  2256	    def _cleanup():
  2257	        supervisor_lock.release()
  2258	
  2259	    atexit.register(_cleanup)
  2260	
  2261	    def _signal_handler(signum, frame):
  2262	        print("\njog: interrupted by signal; cleaning up leases and locks.", file=sys.stderr)
  2263	        sys.exit(130)
  2264	
  2265	    signal.signal(signal.SIGINT, _signal_handler)
  2266	    signal.signal(signal.SIGTERM, _signal_handler)
  2267	
  2268	    checkpoint = None
  2269	    try:
  2270	        if checkpoint_root:

exec
/bin/zsh -lc "nl -ba utils/py/jog_run.py | sed -n '917,950p;2270,2295p;2420,2465p'; rg -n 'gate_timeout|gate-timeout|deadline|def _marathon_.*invocation|checkpoint.finish|retry-gate|jog_resume' utils/py/jog_run.py utils/py/releases_app.py" in /private/var/folders/55/4ncr895946v1jymn1561yy340000gn/T/consult-wt-68417-hftky0hm
 succeeded in 0ms:
   917	        _ledger_abs_path(root, gid, record.get("packet_dir")), "marathon-invocation.json")
   918	    try:
   919	        invocation = load_marathon_invocation(invocation_path)
   920	    except ContractError as exc:
   921	        print(f"jog: cannot gate-retry — {exc}", file=sys.stderr)
   922	        sys.exit(2)
   923	
   924	    _execution_root(root, invocation["target_root"])
   925	    ledger_before = _ledger_bytes(invocation["target_root"])
   926	
   927	    # The head-moved guard runs BEFORE dispatch: marathon's own runs commit transcripts (the
   928	    # receipt head legitimately advances by those), so the meaningful invariant is that the
   929	    # head is UNCHANGED between the execution and this retry — checked against the live repo
   930	    # pre-dispatch, not against the post-run receipt (which would false-trip on the retry's
   931	    # own transcript commit and burn a gate run to report it).
   932	    # GH-1332: accept a candidate head when all commits after prior_head touch only the lane's
   933	    # relay file or transcripts (the same candidate + receipt-only tail rule Phase 0 set).
   934	    pre_head = subprocess.run(["git", "rev-parse", "HEAD"], cwd=invocation["target_root"],
   935	                              capture_output=True, text=True)
   936	    if pre_head.returncode == 0 and pre_head.stdout.strip() != prior_head:
   937	        curr_head = pre_head.stdout.strip()
   938	        is_tail, tail_why = _is_relay_receipt_tail(
   939	            invocation["target_root"], prior_head, curr_head, invocation, receipt)
   940	        if not is_tail:
   941	            print(f"jog: refusing gate retry for GH-{gh_num} — head is {curr_head[:8]} "
   942	                  f"but the execution ran on {str(prior_head or '')[:8]}; the head moved between "
   943	                  f"runs (use jog retry-build)", file=sys.stderr)
   944	            sys.exit(2)
   945	        prior_head = curr_head
   946	
   947	    if published == prior_head and receipt.get("outcome") == "approved":
   948	        print("jog: approved gate receipt is already published; no gate retry needed")
   949	        return 0
   950	
  2270	        if checkpoint_root:
  2271	            checkpoint = JogCheckpoint(root, checkpoint_root)
  2272	            if not checkpoint.begin():
  2273	                checkpoint = None
  2274	                return
  2275	        # Reconcile orphan leases via perform_write on startup
  2276	        reconciled = jog_reconcile_orphan_leases(root)
  2277	        if reconciled:
  2278	            print(f"jog: reconciled orphan lease(s) for: {', '.join('GH-%d' % n for n in reconciled)}")
  2279	            if executor == "marathon" and not simulate:
  2280	                # GH-280 cold start: a dispatched Marathon execution on a crashed row is
  2281	                # reconciled from its durable result BEFORE the loop can lease and refire.
  2282	                jog_reconcile_cold_start(root, reconciled)
  2283	
  2284	        tasks_processed = 0
  2285	        while True:
  2286	            if args.max_tasks is not None and tasks_processed >= args.max_tasks:
  2287	                print(f"jog: reached max-tasks limit ({args.max_tasks}); pausing queue.")
  2288	                break
  2289	
  2290	            # Query next pending task
  2291	            conn = sqlite3.connect(db_path)
  2292	            conn.row_factory = sqlite3.Row
  2293	            try:
  2294	                _ensure_jog_schema(conn)
  2295	                row = conn.execute(
  2420	            jog_set_status(root, gh_num, status, failure_reason=reason)
  2421	
  2422	            if landed:
  2423	                tasks_processed += 1
  2424	            else:
  2425	                print("jog: advancing halted at landing boundary.")
  2426	                break
  2427	
  2428	        if checkpoint:
  2429	            checkpoint.finish()
  2430	    finally:
  2431	        _cleanup()
  2432	
  2433	
  2434	if __name__ == "__main__":
  2435	    jog_run_main()
utils/py/jog_run.py:485:def _marathon_argv_from_invocation(invocation, builder, reviewer):
utils/py/jog_run.py:488:    Policy overrides, in one place so every dispatch path (run / retry-gate / retry-build)
utils/py/jog_run.py:514:def _marathon_env_from_invocation(invocation):
utils/py/jog_run.py:717:def jog_resume(root, gh_num, args=None):
utils/py/jog_run.py:780:          f"'{latest.get('status')}' — nothing to reconcile; use jog retry-gate / retry-build / land")
utils/py/jog_run.py:785:    """`jog retry-gate <GH>` — re-run ONLY the gate against the same head SHA.
utils/py/jog_run.py:907:        # its receipt still names the head — retry-gate applies there too.
utils/py/jog_run.py:2429:            checkpoint.finish()
utils/py/releases_app.py:387:        deadline = time.time() + max(wait, 0.0)
utils/py/releases_app.py:399:                if time.time() >= deadline:
utils/py/releases_app.py:5209:def cmd_jog_resume(args):
utils/py/releases_app.py:5210:    _jog_verb_dispatch("jog_resume")(args)
utils/py/releases_app.py:7058:    sp_jrg = jsub.add_parser("retry-gate", help="re-run ONLY the gate against the same head SHA (no builder turn)")
utils/py/releases_app.py:7138:                          "run": cmd_jog_run, "resume": cmd_jog_resume,
utils/py/releases_app.py:7139:                          "retry-gate": cmd_jog_retry_gate, "retry-build": cmd_jog_retry_build,

exec
/bin/zsh -lc "nl -ba utils/py/jog_run.py | sed -n '485,535p'; nl -ba utils/py/releases_app.py | sed -n '5160,5218p;7050,7085p'; rg -n 'def load_marathon_result|execution_id|invocation' utils/py/marathon_contracts.py | head -35; git rev-parse HEAD; git status --porcelain" in /private/var/folders/55/4ncr895946v1jymn1561yy340000gn/T/consult-wt-68417-hftky0hm
 succeeded in 0ms:
   485	def _marathon_argv_from_invocation(invocation, builder, reviewer):
   486	    """The packet's argv with Jog's supervisor policy applied.
   487	
   488	    Policy overrides, in one place so every dispatch path (run / retry-gate / retry-build)
   489	    stays identical: the operator's reviewer/builder replace the packet's suggestions, the
   490	    packet's --require-clean is dropped (a supervisor's own queue writes make the tree
   491	    legitimately non-pristine between lease and dispatch), and the packet's suggested
   492	    per-issue phase id is adopted so Marathon's lane namespace (and its attempt cap) stays
   493	    per-issue instead of collapsing onto marathon's bare 'p1' default.
   494	    """
   495	    argv = list(invocation["argv"])
   496	    for flag, value in (("--reviewer", reviewer), ("--builder", builder)):
   497	        if flag in argv:
   498	            argv[argv.index(flag) + 1] = value
   499	        else:
   500	            argv += [flag, value]
   501	    # GH-1100: cwd does not override Marathon's ambient harness resolver.
   502	    if "--target-root" not in argv:
   503	        argv += ["--target-root", invocation["target_root"]]
   504	    if "--require-clean" in argv:
   505	        argv.remove("--require-clean")
   506	    if "--phase-id" not in argv and invocation.get("phase"):
   507	        argv += ["--phase-id", invocation["phase"]]
   508	    # A one-phase lane is not proof of whole-issue delivery (GH-1344).
   509	    while "--lane-closes-issue" in argv:
   510	        argv.remove("--lane-closes-issue")
   511	    return argv
   512	
   513	
   514	def _marathon_env_from_invocation(invocation):
   515	    """Keep Jog's tooling and coordination roots with its selected invocation."""
   516	    env = dict(os.environ)
   517	    env.update(invocation["env"])
   518	    # GH-1100: target-root alone leaves phase files under the ambient harness root.
   519	    # Preflight's executable is <harness>/relay-automation/marathon-drive.sh, also in .xyz/.
   520	    env["XYZ_HARNESS"] = os.path.dirname(os.path.dirname(invocation["argv"][0]))
   521	    env["MARATHON_ROOT"] = invocation["harness_root"]
   522	    return env
   523	
   524	
   525	def _execution_root(root, target):
   526	    _require_jog_primary(root)
   527	    if not target:
   528	        raise ContractError("--target-root <disposable-full-clone> is required for Jog dispatch")
   529	    target = os.path.realpath(os.path.expanduser(target))
   530	    if target == os.path.realpath(root) or not os.path.isdir(os.path.join(target, ".git")):
   531	        raise ContractError("execution target must be a separate full clone, not the primary or a worktree")
   532	    if primary_config_key(root) != primary_config_key(target):
   533	        raise ContractError("execution target origin differs from the primary")
   534	    dirty_ledger = _git(target, "diff", "--name-only", "HEAD", "--", "releases.db", "releases.sql")
   535	    lane_ledger = _git(target, "diff", "--name-only", "origin/development...HEAD", "--",
  5160	                if row is None:
  5161	                    continue
  5162	                if row["attempt_count"] >= 3:
  5163	                    status = "parked"
  5164	                    conn.execute("""UPDATE jog_queue SET status = 'parked', failure_reason = 'orphan lease: max attempts exceeded',
  5165	                                    lease_pid = NULL, updated_at = ? WHERE id = ?""", (ts, row["id"]))
  5166	                else:
  5167	                    status = "pending"
  5168	                    conn.execute("""UPDATE jog_queue SET status = 'pending', lease_pid = NULL, updated_at = ?
  5169	                                    WHERE id = ?""", (ts, row["id"]))
  5170	                work_events.append((
  5171	                    "jog_%s" % status, row["gh_number"],
  5172	                    {"source": "jog", "transition": True, "status": status,
  5173	                     "jog_global_id": row["global_id"]}, row["repo_id"]))
  5174	                reconciled.append(row["gh_number"])
  5175	
  5176	        perform_write(root, conn, "jog-reconcile", "jog_queue", mutate,
  5177	                      work_events=work_events)
  5178	        return reconciled
  5179	    finally:
  5180	        conn.close()
  5181	
  5182	
  5183	def cmd_jog_run(args):
  5184	    """Execute the serial jog queue supervisor."""
  5185	    try:
  5186	        from jog_run import jog_run_main
  5187	    except ImportError:
  5188	        sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
  5189	        from jog_run import jog_run_main
  5190	    jog_run_main(args)
  5191	
  5192	
  5193	def _jog_verb_dispatch(fn_name):
  5194	    """GH-280 Phase 3 verb dispatch: shared root/target resolution, then delegate to jog_run."""
  5195	    def handler(args):
  5196	        sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
  5197	        import jog_run
  5198	        root = resolve_root(getattr(args, "root", None))
  5199	        gh_num = resolve_issue_number(args.target)
  5200	        try:
  5201	            result = getattr(jog_run, fn_name)(root, gh_num, args)
  5202	        except jog_run.ContractError as exc:
  5203	            print(f"jog: {exc}", file=sys.stderr)
  5204	            sys.exit(2)
  5205	        sys.exit(result)
  5206	    return handler
  5207	
  5208	
  5209	def cmd_jog_resume(args):
  5210	    _jog_verb_dispatch("jog_resume")(args)
  5211	
  5212	
  5213	def cmd_jog_retry_gate(args):
  5214	    _jog_verb_dispatch("jog_retry_gate")(args)
  5215	
  5216	
  5217	def cmd_jog_retry_build(args):
  5218	    _jog_verb_dispatch("jog_retry_build")(args)
  7050	    sp_jc.add_argument("--dry-run", action="store_true", help="report what would be archived, write nothing")
  7051	
  7052	    sp_jtm = jsub.add_parser("to-marathon", help="export active jog items to marathon format")
  7053	
  7054	    sp_jres = jsub.add_parser("resume", help="reconcile durable Marathon state for an item (spends no token)")
  7055	    sp_jres.add_argument("target", help="issue number (e.g. 123 or GH-123)")
  7056	    sp_jres.add_argument("--root", default=argparse.SUPPRESS, help="repository root path")
  7057	
  7058	    sp_jrg = jsub.add_parser("retry-gate", help="re-run ONLY the gate against the same head SHA (no builder turn)")
  7059	    sp_jrg.add_argument("target", help="issue number (e.g. 123 or GH-123)")
  7060	    sp_jrg.add_argument("--builder", default="agy", help="builder identity recorded for the retry")
  7061	    sp_jrg.add_argument("--reviewer", default=None, help="reviewer agent (required; must differ from --builder)")
  7062	    sp_jrg.add_argument("--auto-merge", action="store_true", help="merge the PR if the gate retry approves")
  7063	    sp_jrg.add_argument("--root", default=argparse.SUPPRESS, help="repository root path")
  7064	
  7065	    sp_jrb = jsub.add_parser("retry-build", help="fresh Marathon attempt on a fresh execution id (history preserved)")
  7066	    sp_jrb.add_argument("target", help="issue number (e.g. 123 or GH-123)")
  7067	    sp_jrb.add_argument("--target-root", help="disposable full execution clone")
  7068	    sp_jrb.add_argument("--builder", default="agy", help="builder turn-taker (default: agy; or codex, aider)")
  7069	    sp_jrb.add_argument("--reviewer", default=None, help="reviewer agent (required; must differ from --builder)")
  7070	    sp_jrb.add_argument("--auto-merge", action="store_true", help="opt-in to auto-merge an approved PR")
  7071	    sp_jrb.add_argument("--root", default=argparse.SUPPRESS, help="repository root path")
  7072	
  7073	    sp_jl = jsub.add_parser("land", help="verify committed delivery after hosted reconciliation, complete the primary queue row")
  7074	    sp_jl.add_argument("target", help="issue number (e.g. 123 or GH-123)")
  7075	    sp_jl.add_argument("--pr", default=None, help="PR number or URL (required when the receipt has no PR identity)")
  7076	    sp_jl.add_argument("--root", default=argparse.SUPPRESS, help="repository root path")
  7077	
  7078	    sp_jrec = jsub.add_parser("reconcile", help="idempotent replay entry for jog land (same verification and steps)")
  7079	    sp_jrec.add_argument("target", help="issue number (e.g. 123 or GH-123)")
  7080	    sp_jrec.add_argument("--pr", default=None, help="PR number or URL (required when the receipt has no PR identity)")
  7081	    sp_jrec.add_argument("--root", default=argparse.SUPPRESS, help="repository root path")
  7082	
  7083	    sp_jrun = jsub.add_parser("run", help="execute the serial jog queue loop")
  7084	    sp_jrun.add_argument("--target-root", required=False, help="disposable full execution clone (required for dispatch)")
  7085	    sp_jrun.add_argument("--auto-merge", action="store_true", help="opt-in to auto-merge passing PRs on same-seam tasks")
rg: utils/py/marathon_contracts.py: IO error for operation on utils/py/marathon_contracts.py: No such file or directory (os error 2)
git: warning: confstr() failed with code 5: couldn't get path of DARWIN_USER_TEMP_DIR; using /tmp instead
git: error: couldn't create cache file '/tmp/xcrun_db-GW09pULm' (errno=Operation not permitted)
git: warning: confstr() failed with code 5: couldn't get path of DARWIN_USER_TEMP_DIR; using /tmp instead
git: error: couldn't create cache file '/tmp/xcrun_db-CT4MB1HH' (errno=Operation not permitted)
0e503ac12b9aaa1fb99b1b8c845f6cd86c172150
git: warning: confstr() failed with code 5: couldn't get path of DARWIN_USER_TEMP_DIR; using /tmp instead
git: error: couldn't create cache file '/tmp/xcrun_db-o5iTTuXp' (errno=Operation not permitted)
git: warning: confstr() failed with code 5: couldn't get path of DARWIN_USER_TEMP_DIR; using /tmp instead
git: error: couldn't create cache file '/tmp/xcrun_db-NBzOKEcF' (errno=Operation not permitted)
?? relay-system/2026-11-08/gh1358-controlled-recovery-120542/

codex
**ANSWER:** Conditionally approve the metadata recovery. I found no existing CLI path that imports an unregistered gate receipt and rebases a stale checkpoint journal. A narrowly reviewed invocation of existing state writers is reasonable; a CLI extension is unnecessary for this one recovery. The proposed fresh timeout still needs a concrete configuration path.

**FINDINGS**

- **[Blocker] Fresh gate budget is not established by the current retry CLI.** Retry reconstructs argv from the original invocation and overlays its saved environment onto the current environment; saved values therefore win. The CLI exposes no timeout override. Preserve the old invocation, but identify exactly how the new invocation receives gate=1800 and the new deadline before dispatch. [jog_run.py:495](utils/py/jog_run.py:495), [jog_run.py:514](utils/py/jog_run.py:514), [releases_app.py:7058](utils/py/releases_app.py:7058).

- **[Should] Treat direct state writing as controlled surgery.** `jog_save_state` atomically replaces JSON but enforces neither append-only history, receipt identity, nor locking; `jog_load_state` silently returns an empty ledger on malformed input. Under the existing exclusive lock, require the expected schema, gid, execution identity and prior-state hash; append exactly one retained retry and verify all prior entries remain unchanged. Registering retry 1 prevents the next retry from reusing its directory and result filename. [jog_run.py:312](utils/py/jog_run.py:312), [jog_run.py:327](utils/py/jog_run.py:327), [jog_run.py:958](utils/py/jog_run.py:958).

- **[Should] Resume projects the selected outcome with misleading trace metadata.** It prefers registered retry receipts, but passes the original execution’s ID/result path into the failure reason. Thus the queue can correctly say “gate-killed” while still pointing at the admission-refusal receipt. Preserve an explicit recovery record linking the selected retry identity, resolved path and hash; do not claim the resulting queue trace identifies it accurately. [jog_run.py:695](utils/py/jog_run.py:695), [jog_run.py:738](utils/py/jog_run.py:738), [jog_run.py:750](utils/py/jog_run.py:750).

- **[Should] Checkpoint replacement is necessary here, but narrowly scoped.** An existing unfinished journal invokes reconciliation and `finish`; `finish` rejects an unrelated newer HEAD. Archive only that journal after verifying the stopped supervisor’s identity and permanent termination. Fresh `begin` requires a clean primary at published `origin/development`; abort if either condition changed. [jog_run.py:2093](utils/py/jog_run.py:2093), [jog_run.py:2115](utils/py/jog_run.py:2115).

- **[Should] Preserve receipt storage independently of publication.** `finish` commits only `releases.db` and `releases.sql`; ignored execution state and the external symlink target remain outside that publication. Back up both the symlink and resolved receipt bytes, plus original invocation and retry history. A clean published checkpoint alone does not preserve these artifacts. [jog_run.py:2066](utils/py/jog_run.py:2066), [jog_run.py:2128](utils/py/jog_run.py:2128).

- **[Should] Verify the retry actually selects exec2.** Retry searches all approved receipts before searching escalated receipts, potentially selecting an older approved execution. Confirm the selected record, reviewed candidate and satisfied lane before invoking it; exhausted builder attempts are not themselves proof of a gate-only dispatch. [jog_run.py:904](utils/py/jog_run.py:904), [jog_run.py:962](utils/py/jog_run.py:962).

- **[Pass] Recovery and publication preserve the intended boundaries.** Failed-receipt resume performs no dispatch; checkpoint publication uses a separate clone and ordinary push. Keeping auto-merge disabled fits the authorization. [jog_run.py:750](utils/py/jog_run.py:750), [jog_run.py:2133](utils/py/jog_run.py:2133).

**RECOMMENDATION:** Proceed with locked, hash-checked metadata recovery and independent publication review; dispatch the next gate only after proving receipt selection and fresh budget configuration. Source reviewed at `0e503ac12`; live process/ref assertions were supplied, not independently verified.
tokens used
47,983
**ANSWER:** Conditionally approve the metadata recovery. I found no existing CLI path that imports an unregistered gate receipt and rebases a stale checkpoint journal. A narrowly reviewed invocation of existing state writers is reasonable; a CLI extension is unnecessary for this one recovery. The proposed fresh timeout still needs a concrete configuration path.

**FINDINGS**

- **[Blocker] Fresh gate budget is not established by the current retry CLI.** Retry reconstructs argv from the original invocation and overlays its saved environment onto the current environment; saved values therefore win. The CLI exposes no timeout override. Preserve the old invocation, but identify exactly how the new invocation receives gate=1800 and the new deadline before dispatch. [jog_run.py:495](utils/py/jog_run.py:495), [jog_run.py:514](utils/py/jog_run.py:514), [releases_app.py:7058](utils/py/releases_app.py:7058).

- **[Should] Treat direct state writing as controlled surgery.** `jog_save_state` atomically replaces JSON but enforces neither append-only history, receipt identity, nor locking; `jog_load_state` silently returns an empty ledger on malformed input. Under the existing exclusive lock, require the expected schema, gid, execution identity and prior-state hash; append exactly one retained retry and verify all prior entries remain unchanged. Registering retry 1 prevents the next retry from reusing its directory and result filename. [jog_run.py:312](utils/py/jog_run.py:312), [jog_run.py:327](utils/py/jog_run.py:327), [jog_run.py:958](utils/py/jog_run.py:958).

- **[Should] Resume projects the selected outcome with misleading trace metadata.** It prefers registered retry receipts, but passes the original execution’s ID/result path into the failure reason. Thus the queue can correctly say “gate-killed” while still pointing at the admission-refusal receipt. Preserve an explicit recovery record linking the selected retry identity, resolved path and hash; do not claim the resulting queue trace identifies it accurately. [jog_run.py:695](utils/py/jog_run.py:695), [jog_run.py:738](utils/py/jog_run.py:738), [jog_run.py:750](utils/py/jog_run.py:750).

- **[Should] Checkpoint replacement is necessary here, but narrowly scoped.** An existing unfinished journal invokes reconciliation and `finish`; `finish` rejects an unrelated newer HEAD. Archive only that journal after verifying the stopped supervisor’s identity and permanent termination. Fresh `begin` requires a clean primary at published `origin/development`; abort if either condition changed. [jog_run.py:2093](utils/py/jog_run.py:2093), [jog_run.py:2115](utils/py/jog_run.py:2115).

- **[Should] Preserve receipt storage independently of publication.** `finish` commits only `releases.db` and `releases.sql`; ignored execution state and the external symlink target remain outside that publication. Back up both the symlink and resolved receipt bytes, plus original invocation and retry history. A clean published checkpoint alone does not preserve these artifacts. [jog_run.py:2066](utils/py/jog_run.py:2066), [jog_run.py:2128](utils/py/jog_run.py:2128).

- **[Should] Verify the retry actually selects exec2.** Retry searches all approved receipts before searching escalated receipts, potentially selecting an older approved execution. Confirm the selected record, reviewed candidate and satisfied lane before invoking it; exhausted builder attempts are not themselves proof of a gate-only dispatch. [jog_run.py:904](utils/py/jog_run.py:904), [jog_run.py:962](utils/py/jog_run.py:962).

- **[Pass] Recovery and publication preserve the intended boundaries.** Failed-receipt resume performs no dispatch; checkpoint publication uses a separate clone and ordinary push. Keeping auto-merge disabled fits the authorization. [jog_run.py:750](utils/py/jog_run.py:750), [jog_run.py:2133](utils/py/jog_run.py:2133).

**RECOMMENDATION:** Proceed with locked, hash-checked metadata recovery and independent publication review; dispatch the next gate only after proving receipt selection and fresh budget configuration. Source reviewed at `0e503ac12`; live process/ref assertions were supplied, not independently verified.
