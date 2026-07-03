Reading additional input from stdin...
OpenAI Codex v0.139.0
--------
workdir: /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-61154-16825
model: gpt-5.4
provider: openai
approval: never
sandbox: read-only
reasoning effort: high
reasoning summaries: none
session id: 019f259e-52ea-71f2-a062-0dda7ca0dce7
--------
user
You are an INDEPENDENT advisor in a one-shot cross-model consult. Another model is answering the SAME question separately and a coordinator will reconcile both answers, so give your own honest, specific read — do not hedge toward a consensus you cannot see. Read any repo files the question references (cite file:line). Respond with: (1) a short direct ANSWER; (2) graded FINDINGS — [Blocker]/[Should]/[Nit]/[Pass] — where applicable; (3) a one-line RECOMMENDATION. You are ADVISORY ONLY: output your analysis as text; do not rely on writing files (you are running in a throwaway copy).

=== CONSULT QUESTION ===
# Consult: review the GH-45 per-lane attempt-cap implementation

I hand-built GH-45 (a per-lane attempt cap / anti-rabbit-hole guard) directly into the two relay
driver scripts, because building it *through* the marathon would edit the running driver
(self-hosting corruption hazard). It needs an independent cross-model review before merge — this
consult IS that review (GP #12 independent verification).

## What to review
Run `git diff main...HEAD` in this worktree, focused on:
- `relay-automation/relay-drive.sh` and `relay-automation/marathon-drive.sh` — the new
  `lane_attempt_gate` function (should be BYTE-IDENTICAL in both) + where each calls it.
- `test/lane-attempt-cap.sh` — the new regression test (19 checks).
- `AGENTS.md` — the re-anchor/park rail.

## The contract (ponytail-v1)
1. Each driver appends one line per fire to `.tick/attempts/<lane>` (lane = sanitized `PHASE_ID` for
   marathon-drive, `RELAY_TASK` for relay-drive; stable across re-fires) and REFUSES to start a lane at
   `>= LANE_MAX_ATTEMPTS` (default 2, env-overridable) with a non-zero exit + a park message, seeding
   **no** relay token.
2. `--force` bypasses the cap for one fire and logs the override.
3. A parked lane surfaces its findings (the park message).
4. Must NOT touch `relay-turn-lib.sh` or `bin/tick`.

## Answer concretely (grade [Blocker]/[Should]/[Nit]/[Pass])
1. **Correctness of the cap:** is the check-then-append order right (default 2 ⇒ two fires allowed,
   third parked)? Any off-by-one? Does a *parked* fire correctly NOT append (so the count is stable)?
2. **The nested double-count guard:** `marathon-drive` counts the lane, then invokes `relay-drive` with
   `LANE_ATTEMPT_COUNTED=1` so the nested relay-drive short-circuits. Is that guard correct and
   complete? Any path where the same lane is double-counted, or where a DIRECT relay-drive run wrongly
   skips the cap?
3. **Hermeticity / blast radius:** the attempts store is keyed off `${TICK_REPO_ROOT:-$ROOT_DIR}` (relay)
   / `${TICK_REPO_ROOT:-$ROOT}` (marathon). Does this correctly isolate test runs (which set
   `TICK_REPO_ROOT` to a temp dir) from the real repo? Could a real run ever write attempts to the wrong
   place, or could a stale `.tick/attempts/` file wedge a lane permanently (no natural reset)?
4. **Exit code 8:** the cap exits 8. Does 8 collide with any meaningful exit code in
   `marathon-drive.sh` / `relay-drive.sh` / `marathon.sh` (which chains marathon-drive)? Is a parked
   lane distinguishable from a real failure by the caller?
5. **The `--review-once` / dry-run skip:** relay-drive skips the cap for a single `--review-once` turn
   and dry-runs. Is that the right call, or should reviews also be capped?
6. **Anything unsafe, racy, or non-portable** (bash 3.2 / BSD `wc`/`tr`/`date`; concurrent fires racing
   on the same attempts file; a lane key that collides after sanitization).

`GUIDING-PRINCIPLES.md` is the tie-breaker on any judgment call (esp. #3 containment, #7 least-code,
#8 honest/operator-decides). Be blunt; cite `file:line`. Advisory only — do not edit.
codex
Reviewing the GH-45 diff against `main` and the repo rails first, then I’ll inspect the two driver scripts, the regression test, and the guidance docs with line references.
exec
/bin/zsh -lc "nl -ba GUIDING-PRINCIPLES.md | sed -n '1,260p'" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-61154-16825
exec
/bin/zsh -lc "pwd && nl -ba ROUTER.md | sed -n '1,220p'" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-61154-16825
 succeeded in 0ms:
/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-61154-16825
     1	# ROUTER.md
     2	
     3	This file is the first entry point for an AI agent working in this repo: it tells you what to read, what to run, and which files are canonical.
     4	
     5	## Role split
     6	
     7	- `ROUTER.md` = startup order and canonical entry points
     8	- `AGENTS.md` = behavioral rules, decision quality, reversibility, blast radius, proof
     9	- `README.md` = human-facing repo/product overview
    10	- `ROADMAP.md` = pointer ledger of queued, current, completed, attempted, and deferred work
    11	- `CHANGELOG.md` = the end-of-iteration running log (first-class PDDA artifact; governed by `PROJECT/PDDA.md`)
    12	- `PROJECT/**` docs = canonical execution detail for a specific effort
    13	- `PROJECT/PDDA.md` = document contract and automation rules (incl. the CHANGELOG contract)
    14	
    15	## Startup sequence
    16	
    17	1. Read `ROUTER.md` to understand the repo's operating order and canonical files. -> expect one clear next file, not a repo-wide scavenger hunt.
    18	2. Read `AGENTS.md` before making recommendations or edits. -> expect explicit assumptions, a reversibility read on consequential changes, and verified claims only.
    19	3. Read `ROADMAP.md` to find the active effort or parked intake. -> expect links outward to the canonical `PROJECT/**` docs; `ROADMAP.md` is a pointer ledger, not a plan body.
    20	4. Read the linked `PROJECT/**` document that owns the work you are touching. -> expect the near-top `## Status` table to tell you what was just completed and what is next.
    21	5. If the task touches project docs, read `PROJECT/PDDA.md` and follow the PDDA contract. -> expect `PROJECT/2-WORKING` docs to have frontmatter, the exact status table, and QA gates when phased.
    22	6. Before reporting success on code or runtime work, run `./validate.sh`. -> expect the suite to stay green; do not claim completion if it fails or was skipped.
    23	7. Before reporting success on doc-hygiene or roadmap work, run `utils/pdda/pdda.sh run` (or the relevant `utils/pdda/pdda.sh <check>` subcommand). -> expect deterministic findings first, then any LLM review.
    24	
    25	## Canonical rules
    26	
    27	- Do not put phase checklists, build steps, or deep execution notes in `ROADMAP.md`.
    28	- Every active doc in `PROJECT/2-WORKING/` must be reflected by a pointer in `ROADMAP.md` — a one-line ledger entry that links it. A working doc that should not appear opts out with `roadmap_exempt: true` in its frontmatter. Enforced by `utils/pdda/pdda.sh roadmap-coverage`; governance lives in `PROJECT/PDDA.md` → "ROADMAP.md contract".
    29	- Every captured GitHub issue doc in `PROJECT/1-INBOX/GH-*.md` must also be parked in `ROADMAP.md` as a one-line queue entry immediately at intake, then promoted or removed later. Enforced by `utils/pdda/pdda.sh roadmap-coverage`; governance lives in `PROJECT/PDDA.md` → "GitHub issue intake" + "ROADMAP.md contract".
    30	- Do not create a second competing plan when a canonical `PROJECT/**` doc already exists.
    31	- Issue-first: any change beyond a **2–3 line** fix opens a GitHub issue first, then a pointer doc **named after the issue** (`GH-<number>-VERY-SHORT-DESC.md`, e.g. `GH-1234-SHOWME-COMMAND.md`), and that capture is **parked in `ROADMAP.md` immediately** before execution begins. The issue is the signal stream; the pointer doc is the execution surface of record. Genuinely trivial edits (≤2–3 line fixes, typos, path repoints, doc-only one-liners) are exempt. Governed by `PROJECT/PDDA.md` → "GitHub issue intake".
    32	- Do not override deterministic PDDA findings with prose.
    33	- Do not report a win you did not verify with the relevant script or test.
    34	- Update `CHANGELOG.md` at the end of each iteration; its governance lives in `PROJECT/PDDA.md` — do not re-specify CHANGELOG rules in `AGENTS.md` or elsewhere.
    35	
    36	## Command rails
    37	
    38	For repo correctness:
    39	
    40	```bash
    41	./validate.sh
    42	```
    43	
    44	For document hygiene:
    45	
    46	```bash
    47	utils/pdda/pdda.sh run
    48	```
    49	
    50	For targeted PDDA debugging (subcommands of the single dispatcher):
    51	
    52	```bash
    53	utils/pdda/pdda.sh frontmatter
    54	utils/pdda/pdda.sh status-table
    55	utils/pdda/pdda.sh hardcoded-paths
    56	utils/pdda/pdda.sh roadmap
    57	utils/pdda/pdda.sh roadmap-coverage
    58	utils/pdda/pdda.sh changelog
    59	utils/pdda/pdda.sh stale
    60	utils/pdda/pdda.sh issue-doc-sync   # warn-only: flags 2-WORKING/GH-*.md docs drifted from their GitHub issue state
    61	utils/pdda/pdda.sh doc-ready        # LLM readiness review — set PDDA_LLM_BIN (codex/claude/agy) for recommendations, else it self-skips
    62	```
    63	
    64	## Routing hints
    65	
    66	- If the task is about current priorities or active work, start in `ROADMAP.md`, then follow the linked `PROJECT/**` doc.
    67	- If the task is about fresh GitHub intake or duplicate-prevention, start in `ROADMAP.md`'s queue, then follow the linked `PROJECT/1-INBOX/GH-*.md` capture doc.
    68	- If the task is about document quality, active-doc lifecycle, roadmap sprawl, or automation policy, start in `PROJECT/PDDA.md`.
    69	- If the task is about the CHANGELOG, provenance, or end-of-iteration logging, the governance is in `PROJECT/PDDA.md` (the "CHANGELOG.md — end-of-iteration record" contract).
    70	- If the task is about the `tick` runtime, event projection, or multi-agent coordination kernel, start in `README.md`, then `bin/`, `src/`, `test/`, and the active project doc.
    71	- If the task is about running, driving, or reviewing via the relay (`relay-automation/` — `relay-drive.sh`, `poll.sh`, the turn shims, `marathon*.sh`), **invoke the `relay-xyz` skill first — do not improvise the handoff or hand-roll a harness from `ls relay-automation/`.** The skill owns the locator, sandbox rules, exit codes, and the safety boundary; a `PreToolUse` guard (`relay-automation/hooks/relay-xyz-guard.sh`) blocks driving a harness driver before the skill is loaded. For the two live-Claude-windows, same-machine duel recipe (Reporter↔Maintainer with a human go-gate), the copy-paste form is [relay-automation/DUELING-CLAUDES.md](relay-automation/DUELING-CLAUDES.md).
    72	- If the task is about relay session telemetry, the `focus5float` health feed, or extraction scripts under `utils/telemetry/`, start in `PROJECT/1-INBOX/GH-24-RELAY-TELEMETRY-EXTRACTOR.md`.
    73	- If the task is about live per-session completion telemetry — the `XYZ.json` log every relay/marathon/swarm session appends to at the harness repo root (schema: `harness`/`sessionId`/`health`/`title`/`description`/`updatedAt`), the shared writer `utils/telemetry/append-xyz-completion.sh`, or the shared health mapping `utils/telemetry/health-lib.sh` — start in `PROJECT/1-INBOX/GH-75-XYZ-JSON-COMPLETION-TELEMETRY.md`. `XYZ.json` is local + gitignored (machine-specific).
    74	- If the task is about a proposed roadmap-steward agent, start here, then read `PROJECT/PDDA.md` and its `Proposed roadmap steward extension` section.
    75	- Issue-first SOP: any change beyond a 2–3 line fix (and every project plan) opens a GitHub issue *first*, then gets a pointer doc named after the issue at `PROJECT/1-INBOX/GH-<number>-VERY-SHORT-DESC.md` — e.g. `GH-1234-SHOWME-COMMAND.md` — and that capture is parked in the `ROADMAP.md` queue immediately (format + lifecycle owned by `PROJECT/PDDA.md` → "GitHub issue intake"), following the normal `1-INBOX` → `2-WORKING` flow. Genuinely trivial edits (≤2–3 line fixes, typos, path repoints, doc-only one-liners) are exempt and commit directly.

 succeeded in 0ms:
     1	# Guiding Principles
     2	
     3	North star for **xyz-3-agents-swarm**, the multi-agent coordination harness behind the `tick` event-log kernel and `relay-automation/` relay stack. When a choice is unclear, the option that keeps agents synchronized, contained, and verifiable — without leaking or destroying work — wins. AGENTS.md is the behavioral playbook; ROUTER.md is the entry-point map; this is the *why*.
     4	
     5	## Purpose
     6	
     7	`tick` coordinates Claude Code, Codex, and agy (Antigravity CLI) on the same branch without collision: a shared local event log under `.tick/events/`, claims serialized by `O_EXCL` locks, and a `Marathon` harness that chains multi-phase build→review cycles from a `MARATHON.yaml`. The relay layer (`relay-automation/`) drives headless turns, isolates agent writes to worktrees, and enforces an allowlist so no headless agent destroys work it didn't intend to touch. The goal: a multi-agent swarm safe enough to run against a real external codebase and correct enough that its output is worth shipping.
     8	
     9	## The quality bar
    10	
    11	Every agent turn is a signal. A turn is high-quality only when it is all four:
    12	
    13	- **Attested** — carries its receipts: source, evidence, confidence. Never a bare verdict. A relay review names which claim is wrong and why; a build turn names the seam it touched.
    14	- **Relevant** — ranked, not dumped. Volume is not value. One real bug beats five nits and a phantom.
    15	- **Fresh** — current, not stale. A turn that reads a stale `STATE.md` or misses an epoch fence is wrong by construction.
    16	- **Structured** — one shape, clean for the operator to read and for downstream agents to feed on.
    17	
    18	Fail a pillar, and the turn, feature, or relay review isn't done.
    19	
    20	## How it's built
    21	
    22	1. **Coordination is local-transport only.** `.tick/events/` is the shared bus; claims resolve from there, not from a remote. No per-event push/fetch; no remote dependency at runtime. A coordination primitive that reaches out is a coordination primitive that can fail or leak.
    23	
    24	2. **One canonical event log; every surface is a projection.** `tick` accretes events; `STATE.md` is the current projection. Reads go through the projection; writes go through a `claim/take/scope/done` verb. Nothing canonical lives in two places where it can drift. An agent that hard-codes state outside `.tick/` is creating drift.
    25	
    26	3. **Containment is non-negotiable.** A headless turn must not: self-commit mid-turn, orphan a peer's concurrent commit, or write outside its allowlist. The allowlist, worktree isolation, and commit-bypass guard exist because a driven agent will do all three if unconstrained — not hypothetically, but as documented live incidents (GH-13, GH-14, GH-17). New relay paths must clear the containment bar before they ship.
    27	
    28	4. **Skill-first; never improvise the harness.** The `relay-xyz` skill owns the locator, sandbox rules, exit codes, and the safety boundary. A session that improvises those from `ls relay-automation/` silently skips the skill's safety layer. The `PreToolUse` guard (`relay-automation/hooks/relay-xyz-guard.sh`) enforces this by blocking driver calls before the skill loads. Add capabilities to the skill; do not work around it.
    29	
    30	5. **Adversarially proven before commercially viable.** The harness exists to run against real codebases. Features in the adversarial-hardening track (epoch fencing, chaos suite, cross-repo E2E) must be verified to survive deliberate abuse — stale writers, zombie claims, macOS case-sensitivity, concurrent peer commits — not just the happy path. A feature that clears the happy path and skips chaos is half-done.
    31	
    32	6. **Build durable, not band-aid.** Durable means it removes the root cause and the next planned change builds on it — not a patch torn out when the obvious next feature lands. A band-aid is wasted work unless a demo strictly needs one, and a demo band-aid is tagged for removal so it isn't silently inherited.
    33	
    34	7. **Least code that clears the bar.** Node standard library only — no deps, no lockfile; the repo ships no root manifest. Prefer reusing or extending what exists; the smallest change that stays correct, contained, and durable wins. Net-new code is a cost to justify. Deleting code counts as progress.
    35	
    36	8. **Honest; the operator decides.** Surface what failed and why — never mask a stall as success or an escalation as a stall. A headless turn self-repairs within a bounded exit-code menu (`exit 3` stall, `exit 4` escalated-by-design, `exit 6` containment revert), then stops; it never loops forever or silently swallows an error. Destructive actions require explicit authorization.
    37	
    38	9. **Docs are resumable runtime state (PDDA).** Agent work is stoppable, resumable, and handed off from `PROJECT/**` alone — ROUTER points, project docs hold detail, CHANGELOG logs dated outcomes. ROADMAP.md is a pointer/ledger only; execution detail lives in the linked `PROJECT/**` doc. If reality and the docs disagree, the docs are the bug.
    39	
    40	10. **Done means verified.** "Done" is `validate.sh` green, the relevant PDDA checks passing, and any relay review returning `Approved` — not work that looks finished. An unverified success claim is itself a low-quality signal.
    41	
    42	11. **Issue-first; every non-trivial change has a signal stream.** Any change beyond a 2–3 line fix opens a GitHub issue first, then gets a `GH-<number>` in-repo pointer doc, then lands. The issue is the machine-queryable signal stream; the `PROJECT/**` doc is the execution surface of record. Genuinely trivial edits (≤2–3 line fixes, typos, path repoints, doc-only one-liners) are exempt.
    43	
    44	12. **Independent Verification (Separated Grading)** — The agent that produces a turn must not be the sole grader of its own quality. Verification must be performed by an independent deterministic check or a separate reviewing agent before the lock releases. Applies to: the relay's structural block validator (`bin/validate-relay-block` — Phase 1 of GH-21), consult-verify diversity (Phase 3), and any other post-generation quality gate.
    45	
    46	## Applying this
    47	
    48	Adding a feature or weighing a tradeoff, ask: *does this keep agents coordinated without collision, contained within their scope, and verifiable to an outside observer? And is "done" provable by running `validate.sh`?* If any answer is no, reconsider.
    49	
    50	---
    51	
    52	## Appendix: AI Doc Review Heuristics
    53	
    54	When reviewing any repo doc (roadmap entries, plans, architecture notes, audits, task writeups), apply these. Priority: containment > coordination correctness > signal quality > implementation speed and operator friction.
    55	
    56	**Heuristics**
    57	
    58	1. **Containment preserved?** Any headless path that could self-commit, touch off-allowlist files, or orphan a peer commit without an explicit containment argument → reject or escalate.
    59	2. **Skill-first respected?** Any plan that bypasses `relay-xyz` or improvises the harness from scratch without the skill layer → reject. Add to the skill instead.
    60	3. **Coordination through the event log?** Reads/writes to shared state route through `tick` verbs; hard-coded state outside `.tick/` needs explicit justification.
    61	4. **Done verifiable?** Names runnable gates (`validate.sh`, specific tests, `utils/pdda/pdda.sh run`). None = low-quality signal.
    62	5. **Drift reduced, not created?** No duplicated docs, no execution detail in ROADMAP.md, no reinventing a path the event-log contract already documents.
    63	6. **Next action singular?** One explicit next step, not buried in prose; status cells non-empty.
    64	7. **Operator control explicit?** No silent retry, no auto-repair outside the bounded exit-code menu, no masked failure; destructive ops surface before executing.
    65	8. **Four pillars pass?** Each turn/output is Attested, Relevant, Fresh, Structured. Fail one → not done.
    66	
    67	**Tie-breakers**
    68	
    69	- **Containment vs speed:** choose containment; flag friction as a design question, not a shortcut.
    70	- **New relay path vs reuse:** extend the existing skill and harness over forking a parallel path; if the harness can't accommodate it, surface the gap.
    71	- **Ambitious vs resumable:** a shorter plan an agent can resume cold beats a comprehensive one that buries state in prose.
    72	
    73	**Reject or escalate when**
    74	
    75	- A headless path has no allowlist, no worktree isolation, and no commit-bypass guard — and the doc doesn't justify why.
    76	- "Done" has no runnable verification step.
    77	- Adding a new relay lane requires editing the event-log kernel or the `tick` verb schema without a decision record under `decisions/`.
    78	- Hardcoded absolute paths, silent destructive operations, or opaque epoch-fence assumptions.
    79	- ROADMAP.md would need execution detail to make the plan legible.

exec
/bin/zsh -lc "git diff --stat main...HEAD && printf '\\n====\\n' && git diff --unified=80 main...HEAD -- relay-automation/relay-drive.sh relay-automation/marathon-drive.sh test/lane-attempt-cap.sh AGENTS.md" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-61154-16825
codex
The doc rails are clear: containment and honest operator-visible failure are the tie-breakers here. I’m pulling the exact diff and then checking line-by-line whether the cap semantics actually match the stated contract.
 succeeded in 5436ms:
2026-07-02 18:36:16.621 xcodebuild[62492:22664165]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-07-02 18:36:17.045 xcodebuild[62492:22664163] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.
git: warning: confstr() failed with code 5: couldn't get path of DARWIN_USER_TEMP_DIR; using /tmp instead
git: error: couldn't create cache file '/tmp/xcrun_db-ABRjIeL9' (errno=Operation not permitted)
2026-07-02 18:36:17.773 xcodebuild[62605:22664399]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-07-02 18:36:17.957 xcodebuild[62605:22664398] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.
 AGENTS.md                                          |  6 ++
 CHANGELOG.md                                       |  3 +
 .../1-INBOX/GH-88-CROSS-REPO-MARATHON-MONITOR.md   | 70 ++++++++++++++++++
 ROADMAP-DASHBOARD.md                               |  4 +-
 ROADMAP.md                                         |  2 +
 relay-automation/marathon-drive.sh                 | 34 +++++++++
 relay-automation/relay-drive.sh                    | 37 +++++++++-
 test/lane-attempt-cap.sh                           | 83 ++++++++++++++++++++++
 validate.sh                                        |  1 +
 9 files changed, 238 insertions(+), 2 deletions(-)

====
git: warning: confstr() failed with code 5: couldn't get path of DARWIN_USER_TEMP_DIR; using /tmp instead
git: error: couldn't create cache file '/tmp/xcrun_db-GGtR1GOy' (errno=Operation not permitted)
2026-07-02 18:36:19.268 xcodebuild[62720:22664605]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-07-02 18:36:19.443 xcodebuild[62720:22664601] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.
git: warning: confstr() failed with code 5: couldn't get path of DARWIN_USER_TEMP_DIR; using /tmp instead
git: error: couldn't create cache file '/tmp/xcrun_db-XbFI3aKu' (errno=Operation not permitted)
2026-07-02 18:36:20.000 xcodebuild[62723:22664621]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-07-02 18:36:20.204 xcodebuild[62723:22664620] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.
diff --git a/AGENTS.md b/AGENTS.md
index bce8b02..8d35e02 100644
--- a/AGENTS.md
+++ b/AGENTS.md
@@ -1,77 +1,83 @@
 # AGENTS.md
 
 Read `ROUTER.md` first for startup order and canonical files.
 
 Read `GUIDING-PRINCIPLES.md` for the product north stars.
 
 Read `PROJECT/PDDA.md` when the task touches project docs, `ROADMAP.md`, or `CHANGELOG.md`.
 
 ## What this file owns
 
 This file is the behavioral playbook for work in this repo: decision quality, reversibility, blast
 radius, planning shape, and proof.
 
 Do not restate routing, roadmap, changelog, or active-doc contracts here. Those live in
 `ROUTER.md` and `PROJECT/PDDA.md`.
 
 ## Operating principles
 
 ### 1. Lead with the line that survives skimming
 
 Your first sentence gives the verdict, current state, or call. No setup first.
 
 ### 2. Make the bet explicit before acting
 
 State the assumption, tradeoff, and failure mode that matter before you commit to a path. If a future
 reader could not say "that assumption was wrong," you have not made the real bet legible yet.
 
 ### 3. Use one reversibility scale
 
 Consequential changes get a read on the shared scale: **Easy / Costly / One-way door**, with one line
 of why. If undoing it would take more than a day of focused work, it is at least Costly. Costly
 changes need a rollback path. One-way doors need explicit confirmation before proceeding.
 
 ### 4. Size the blast radius before changing shared surfaces
 
 Before a refactor, schema change, dependency bump, coordination-kernel change, or relay-containment
 change, say what ripples, what might break, and who notices. A change you cannot size is not ready.
 
 ### 5. One plan, one ordered list
 
 When you give executable steps, put them in one numbered list in execution order. Keep verification
 inline (`-> expect ...`). Do not scatter action items across prose.
 
 ### 6. Verified beats plausible
 
 Do not claim success without the relevant test, script, or observable proof. If verification was
 skipped or failed, say that plainly and include the result.
 
 ### 7. Record only consequential bets
 
 If a change is Costly, One-way door, or assumption-heavy, record the bet in `CHANGELOG.md` per
 `PROJECT/PDDA.md`. Below that threshold, skip the ritual.
 
 ### 8. Stay quiet on trivial work
 
 Most edits are small and reversible. Do not manufacture ceremony for a rename, typo fix, or other
 local change.
 
 ## Repo-specific rails
 
 - `ROUTER.md` owns startup order, canonical files, command rails, and the issue-first SOP.
 - `GUIDING-PRINCIPLES.md` owns the product/runtime priorities: local event-log coordination,
   containment, skill-first relay work, durable fixes, and verified done.
 - `PROJECT/PDDA.md` owns doc lifecycle, `ROADMAP.md` pointer-ledger rules, and `CHANGELOG.md`
   governance.
 - `validate.sh` is the code/runtime gate. `utils/pdda/pdda.sh run` and its targeted
   `utils/pdda/pdda.sh <check>` subcommands are the doc-hygiene gates.
 - Changes to `.tick/events/`, `src/project.js`, relay containment, or event/verb shape are usually
   broader than they look. Treat them as at least Costly until proven otherwise.
+- **Commit to the QUEUE; re-anchor, don't rabbit-hole (GH-45).** A wave's committed lane list *is* the
+  active commitment — after each lane attempt, re-read it before acting further. A driven lane that
+  fails **parks** after `LANE_MAX_ATTEMPTS` (default 2): the driver (`marathon-drive.sh` /
+  `relay-drive.sh`) refuses to re-fire it (exit 8, no token), you capture the findings as an issue and
+  stop. Re-firing a parked lane or going off-wave to deep-dive one item requires an explicit operator
+  override (`--force`) or a replan note — never a quiet slide off the plan.
 
 ## Conflict order
 
 1. The current user request
 2. The canonical doc that owns the surface you are touching (`ROUTER.md`, `GUIDING-PRINCIPLES.md`,
    `PROJECT/PDDA.md`, or the active `PROJECT/**` doc)
 3. This file
 4. Skill defaults
diff --git a/relay-automation/marathon-drive.sh b/relay-automation/marathon-drive.sh
index 8fcef81..131f5e1 100755
--- a/relay-automation/marathon-drive.sh
+++ b/relay-automation/marathon-drive.sh
@@ -1,226 +1,254 @@
 #!/usr/bin/env bash
 set -euo pipefail
 #
 # marathon-drive.sh — Phase 3: single-phase headless relay loop.
 #
 # Renders phases/p1/RELAY.md from the phase brief, seeds the tick token (handoff → builder),
 # calls relay-drive.sh unmodified, runs the pre-advance gate, emits phase events, and saves
 # the transcript. Does NOT reimplement any loop logic — relay-drive.sh IS the loop.
 #
 # Usage:
 #   relay-automation/marathon-drive.sh \
 #     --phase-brief <FILE>       phase brief (markdown; baked into the relay template)
 #     --reviewer    <AGENT_ID>   reviewer agent (codex* or gemini*)
 #     [--builder    <AGENT_ID>]  builder agent (default: claude)
 #     [--round-cap  <N>]         relay-drive round cap (default: 5 = 2*2+1)
 #     [--pre-advance-cmd <CMD>]  gate before phase.approved (default: bash validate.sh)
 #     [--phases-dir <DIR>]       where to create phases/<id>/ (default: <repo-root>/phases)
 #     [--phase-id <ID>]          which phase to drive: phases/<id>/ (default: p1; the orchestrator sets it)
 #     [--relay-task <ID>]        tick task name (default: MARATHON-<PHASE_ID>-TURN)
 #     [--artifact <PATHS>]       comma-separated repo-relative file(s) the builder may create/edit
 #                                beyond the relay file (passed to the shims as ALLOW_PATHS). Omit for
 #                                a relay-only phase (conversation → approval, no source edit).
 #     [--require-clean]          hard-stop if the workspace has pre-existing changes (unattended runs)
 #     [--dry-run]                render relay file and print tick seed cmd, then exit
 #
 # Environment overrides (for tests):
 #   MARATHON_ROOT         — git repo root (default: parent of this script's dir)
 #   MARATHON_RELAY_DRIVE  — relay-drive.sh path (default: this script's dir/relay-drive.sh)
 #   MARATHON_AGENT_CMD    — --agent-cmd value (default: this script's dir/marathon-agent.sh)
 #   TICK_BIN              — tick binary (default: <repo-root>/bin/tick)
 #
 # Exit: 0 phase approved + gate passed · 3 relay no-progress · 4 relay cap/mismatch ·
 #        5 pre-advance gate failed · 6 containment violation (turn-taker reverted an off-lane edit) ·
 #        2 usage.
 
 HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
 ROOT="${MARATHON_ROOT:-"$(cd "$HERE/.." && pwd)"}"
 TICK_BIN="${TICK_BIN:-"$ROOT/bin/tick"}"
 RELAY_DRIVE_BIN="${MARATHON_RELAY_DRIVE:-"$HERE/relay-drive.sh"}"
 AGENT_CMD="${MARATHON_AGENT_CMD:-"$HERE/marathon-agent.sh"}"
 
+# GH-45 — QUEUE commitment contract: per-lane attempt cap (anti-rabbit-hole / WIP discipline).
+# Appends one line per fire to .tick/attempts/<lane> and REFUSES to start a lane at
+# >= LANE_MAX_ATTEMPTS (default 2, env-overridable) with exit 8 + a park message, seeding NO relay
+# token. --force bypasses for one fire and logs it. A nested call (marathon-drive → relay-drive) is
+# guarded by LANE_ATTEMPT_COUNTED so the same lane is counted exactly once. Byte-consistent mirror in
+# relay-drive.sh; relay-turn-lib.sh / bin/tick are NOT touched.
+lane_attempt_gate() {
+  local root="$1" raw="$2" force="${3:-0}"
+  [ -n "${LANE_ATTEMPT_COUNTED:-}" ] && return 0
+  local key; key=$(printf '%s' "$raw" | tr -c 'A-Za-z0-9._-' '_')
+  local max="${LANE_MAX_ATTEMPTS:-2}"
+  local dir="$root/.tick/attempts" file count
+  file="$dir/$key"
+  mkdir -p "$dir" 2>/dev/null || true
+  count=0; [ -f "$file" ] && count=$(wc -l < "$file" 2>/dev/null | tr -d ' '); [ -n "$count" ] || count=0
+  if [ "$force" = "1" ]; then
+    printf 'lane-attempt-cap: --force override — lane %s at %s attempt(s) (cap %s), proceeding.\n' "$key" "$count" "$max" >&2
+  elif [ "$count" -ge "$max" ]; then
+    printf 'lane-attempt-cap: lane %s PARKED after %s attempt(s) (cap %s) — no relay token seeded.\n' "$key" "$count" "$max" >&2
+    printf '  Re-anchor to the committed QUEUE lanes (AGENTS.md) or re-fire with --force. Attempts log: %s\n' "$file" >&2
+    return 8
+  fi
+  printf '%s fire\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || echo fire)" >> "$file"
+  return 0
+}
+
 if [[ "${RELAY_DRIVER_LOCKED:-0}" != "1" ]]; then
   # GH-49b: the lock lives in .git/ (never committed) for a normal clone; a vendored .xyz/ copy has no
   # .git/, so fall back to a hidden lock beside the scripts (the .xyz/ dir is itself gitignored in the
   # foreign repo, so it stays uncommitted just the same). Same lock NAME as relay-drive so a marathon
   # and a relay driver still mutually exclude in one clone. Unchanged when .git/ exists.
   if [[ -d "$ROOT/.git" ]]; then
     _lock="$ROOT/.git/relay-driver.lock"; _lock_label=".git/relay-driver.lock"
   else
     _lock="$ROOT/.relay-driver.lock";     _lock_label=".relay-driver.lock"
   fi
   if ! mkdir "$_lock" 2>/dev/null; then
     # GH-42 self-heal: the lock exists — reclaim it only if its holder is dead. A crashed/killed/
     # SIGKILL'd driver used to leave a stale lock that blocked every later run until a manual rmdir.
     _holder="$(cat "$_lock/pid" 2>/dev/null || true)"
     if [[ -n "$_holder" ]] && kill -0 "$_holder" 2>/dev/null; then
       printf 'marathon-drive: another driver is active in this repo (pid %s, lock: %s).\n' "$_holder" "$_lock_label" >&2
       printf 'marathon-drive: Concurrent runs in the same clone are unsafe (GH-42 ROOT HEAD hazard).\n' >&2
       exit 1
     fi
     printf 'marathon-drive: reclaiming stale relay-driver.lock (holder pid %s not running).\n' "${_holder:-none}" >&2
     rm -rf "$_lock"
     mkdir "$_lock" 2>/dev/null || { printf 'marathon-drive: could not acquire relay-driver.lock after reclaiming a stale one.\n' >&2; exit 1; }
     # ponytail: tiny TOCTOU window (two drivers could both reclaim a stale lock); acceptable for a
     # single-operator clone — add an atomic PID-CAS only if true multi-operator concurrency appears.
   fi
   printf '%s\n' "$$" > "$_lock/pid"
   trap 'rm -rf "$_lock" 2>/dev/null || true' EXIT
   export RELAY_DRIVER_LOCKED=1
 fi
 
 die()  { printf 'marathon-drive: %s\n' "$*" >&2; exit 2; }
 log()  { printf 'marathon-drive: %s\n' "$*"; }
 
 XYZ_APPEND_BIN="${XYZ_APPEND_BIN:-"$ROOT/utils/telemetry/append-xyz-completion.sh"}"
 
 # GH-75: append ONE final-completion record for a run whose WHOLE completion IS this single-phase
 # marathon-drive — i.e. a bare `marathon-drive.sh` run (harness:"marathon") or a swarm-preflight-
 # originated run (harness:"swarm", tagged via XYZ_HARNESS_CONTEXT=swarm baked into the generated
 # invocation). Stays SILENT when marathon.sh drives us per-phase (XYZ_HARNESS_CONTEXT=marathon-phase):
 # marathon.sh emits the single whole-run record itself. Health is binary green/red (halt-on-first-
 # failure has no distinct "escalated mid-chain" state). Best-effort — never changes marathon-drive's
 # own exit code.
 xyz_marathon_emit() {  # <health> <description>
   local ctx="${XYZ_HARNESS_CONTEXT:-}"
   [[ "$ctx" == "marathon-phase" ]] && return 0
   [[ -x "$XYZ_APPEND_BIN" ]] || return 0
   local health="$1" desc="$2" harness title sid
   case "$ctx" in swarm) harness="swarm" ;; *) harness="marathon" ;; esac
   title="$(basename "$PHASE_BRIEF_FILE" .md 2>/dev/null)"; [[ -n "$title" ]] || title="$PHASE_ID"
   # sessionId: PHASE_ID defaults to "p1", which is a constant across every swarm/bare run — useless for
   # telling one run from another. Let the invoker override it (swarm-preflight bakes the per-run slug
   # into its generated command via XYZ_SESSION_ID); fall back to PHASE_ID otherwise (GH-75 review).
   sid="${XYZ_SESSION_ID:-$PHASE_ID}"
   "$XYZ_APPEND_BIN" "$harness" "$sid" "$health" "$title" "$desc" >/dev/null 2>&1 || true
 }
 
 usage() {
   cat <<'EOF'
 Usage: relay-automation/marathon-drive.sh --phase-brief FILE --reviewer AGENT [options]
 
   --phase-brief FILE      Phase brief markdown baked into the relay template (required).
   --reviewer AGENT        Reviewer agent id; must start with 'codex' or 'gemini' (required).
   --builder AGENT         Builder agent id (default: claude).
   --round-cap N           relay-drive turn cap (default: 5).
   --pre-advance-cmd CMD   Gate before phase.approved (default: bash validate.sh).
   --phases-dir DIR        Where to create phases/<id>/ (default: <repo-root>/phases).
   --phase-id ID           Which phase to drive: phases/<id>/ (default: p1).
   --relay-task ID         Tick task name (default: MARATHON-<PHASE_ID>-TURN).
   --artifact PATHS        Comma-separated repo-relative file(s) the builder may create/edit beyond
                           the relay file (ALLOW_PATHS for the turn-takers). Omit for a relay-only phase.
   --target-root DIR       Foreign git repo the BUILD lands in (GH-11). The relay thread + tick token
                           stay in this repo; forwarded to relay-drive.sh, and the pre-advance gate runs
                           with cwd = DIR. Omit for a same-repo phase.
   --require-clean         Hard-stop (exit 2) if the workspace has pre-existing changes before seeding.
   --dry-run               Render the relay file and print the tick seed; exit without running.
 EOF
 }
 
 PHASE_BRIEF_FILE=""
 BUILDER="claude"
 REVIEWER=""
 ROUND_CAP=5
 PRE_ADVANCE_CMD=""   # resolved to default after ROOT is set
 PHASES_DIR=""        # resolved to default after ROOT is set
 PHASE_ID="p1"        # which phase this invocation drives (phases/<id>/); the orchestrator sets it
 RELAY_TASK=""        # resolved to MARATHON-<PHASE_ID>-TURN after parsing, unless given
 ARTIFACT_PATHS=""    # comma-separated repo-relative file(s) the builder may create/edit (beyond RELAY.md)
 REQUIRE_CLEAN=0      # --require-clean: hard-stop if the workspace has pre-existing changes
+FORCE=0              # --force: bypass the GH-45 per-lane attempt cap for this one fire
 DRY_RUN=0
 TARGET_ROOT=""       # --target-root: foreign repo the BUILD lands in (GH-11). Relay thread stays in ROOT;
                      # forwarded to relay-drive.sh (which exports RELAY_TARGET_ROOT for artifact routing).
 
 while (($# > 0)); do
   case "$1" in
     --phase-brief)     PHASE_BRIEF_FILE="${2:-}"; shift 2 ;;
     --builder)         BUILDER="${2:-}"; shift 2 ;;
     --reviewer)        REVIEWER="${2:-}"; shift 2 ;;
     --round-cap)       ROUND_CAP="${2:-}"; shift 2 ;;
     --pre-advance-cmd) PRE_ADVANCE_CMD="${2:-}"; shift 2 ;;
     --phases-dir)      PHASES_DIR="${2:-}"; shift 2 ;;
     --phase-id)        PHASE_ID="${2:-}"; shift 2 ;;
     --relay-task)      RELAY_TASK="${2:-}"; shift 2 ;;
     --artifact)        ARTIFACT_PATHS="${2:-}"; shift 2 ;;
     --target-root)     TARGET_ROOT="${2:-}"; shift 2 ;;
     --require-clean)   REQUIRE_CLEAN=1; shift ;;
+    --force)           FORCE=1; shift ;;
     --dry-run)         DRY_RUN=1; shift ;;
     --help)            usage; exit 0 ;;
     *)                 die "unknown argument: $1" ;;
   esac
 done
 
 [[ -n "$PHASE_BRIEF_FILE" ]] || { usage; die "--phase-brief FILE required"; }
 [[ -f "$PHASE_BRIEF_FILE" ]] || die "phase brief not found: $PHASE_BRIEF_FILE"
 [[ -n "$REVIEWER"         ]] || { usage; die "--reviewer AGENT required"; }
 [[ -n "$BUILDER"          ]] || die "--builder cannot be empty"
 [[ -n "$PHASE_ID"         ]] || die "--phase-id cannot be empty"
 if [[ -n "$TARGET_ROOT" ]]; then
   git -C "$TARGET_ROOT" rev-parse --show-toplevel >/dev/null 2>&1 \
     || die "invalid --target-root (not a git repo): $TARGET_ROOT"
 fi
 
 PHASES_DIR="${PHASES_DIR:-"$ROOT/phases"}"
 PRE_ADVANCE_CMD="${PRE_ADVANCE_CMD:-"bash $ROOT/validate.sh"}"
 # Default the tick token name off the phase id (p1 → MARATHON-P1-TURN), keeping the Phase-3 default.
 RELAY_TASK="${RELAY_TASK:-"MARATHON-$(printf '%s' "$PHASE_ID" | tr '[:lower:]' '[:upper:]')-TURN"}"
 
 # Map builder/reviewer to _AGENT env vars for marathon-agent.sh routing. Both actors are routed to
 # their shim by name prefix (claude/codex/agy/gemini), so the harness supports cross-model BUILDERS
 # (e.g. agy) — not just Claude. Builder defaults to claude for back-compat.
 export MARATHON_BUILDER="$BUILDER"
 export MARATHON_REVIEWER="$REVIEWER"
 export CLAUDE_AGENT="" CODEX_AGENT="" AGY_AGENT="" GEMINI_AGENT=""
 route_agent() {  # <agent-id> → export the matching *_AGENT var marathon-agent.sh routes on
   case "$1" in
     claude*) export CLAUDE_AGENT="$1" ;;
     codex*)  export CODEX_AGENT="$1" ;;
     agy*)    export AGY_AGENT="$1" ;;
     gemini*) export GEMINI_AGENT="$1" ;;
     *)       die "agent '$1' not recognized — must start with claude/codex/agy/gemini" ;;
   esac
 }
 [[ "$BUILDER" == "$REVIEWER" ]] && die "builder and reviewer must be different agent ids (got '$BUILDER' for both)"
 route_agent "$BUILDER"
 route_agent "$REVIEWER"
 # Reviewer must be a QA-capable model lane (codex/gemini/agy), never the Claude builder lane.
 case "$REVIEWER" in codex*|gemini*|agy*) ;; *) die "reviewer '$REVIEWER' must start with codex/gemini/agy" ;; esac
 
 # Artifact allowlist: when a phase targets real file(s), pass them as ALLOW_PATHS so the turn-takers
 # may create/edit them. The shared safety core (relay-turn-lib.sh) reverts ANY edit outside this
 # allowlist + the always-allowed relay file — so containment still holds; the builder just gains a
 # real write surface. Without --artifact, ALLOW_PATHS stays unset and the phase is relay-only.
 if [[ -n "$ARTIFACT_PATHS" ]]; then
   export ALLOW_PATHS="$ARTIFACT_PATHS"
 else
   unset ALLOW_PATHS
 fi
 
 PHASE_DIR="$PHASES_DIR/$PHASE_ID"
 RELAY_FILE="$PHASE_DIR/RELAY.md"
 REL_RELAY="${RELAY_FILE#"$ROOT"/}"   # repo-root-relative path the agent edits / declares in claim --paths
 
 # ── Step 0: clean-workspace check (Phase 3.6) ──────────────────────────────
 # Stray pre-existing files distract an autonomous builder — a 2026-06-17 dogfood builder was pulled
 # off-task by unrelated AUDIT/*.md briefs left in the tree. Surface them before seeding. Exclude the
 # marathon's own paths (phases/, .tick/). --require-clean turns the warning into a hard stop for
 # unattended runs (DRY_RUN skips it — nothing is committed).
 if ((! DRY_RUN)); then
   dirty="$(git -C "$ROOT" status --porcelain 2>/dev/null \
     | awk '{ p=substr($0,4); if (p !~ /^phases\// && p !~ /^\.tick\//) print p }')"
   if [[ -n "$dirty" ]]; then
     log "WARNING: workspace is not clean — an autonomous builder can be distracted by stray files."
     while IFS= read -r p; do [[ -n "$p" ]] && log "  • $p"; done <<< "$dirty"
     ((REQUIRE_CLEAN)) && die "--require-clean set and the workspace has pre-existing changes (above)"
   fi
 fi
 
 # ── Step 1: render phases/p1/RELAY.md ──────────────────────────────────────
 
 mkdir -p "$PHASE_DIR"
 BRIEF_TEXT="$(cat "$PHASE_BRIEF_FILE")"
 
 # Bake the ABSOLUTE tick path into the relay. A headless turn's cwd is not guaranteed to be the
 # repo root, so a relative "./bin/tick" is a guess — a real builder turn (2026-06-17) looked for it
 # in the phase dir, logged "tick not present", and skipped the token handoff entirely (phase then
 # escalated no-progress). An absolute path the agent can run from anywhere removes that failure mode.
@@ -251,185 +279,191 @@ NEXT: ${BUILDER}
 <!-- marathon-drive: task=${RELAY_TASK} builder=${BUILDER} reviewer=${REVIEWER} round-cap=${ROUND_CAP} -->
 
 ## Phase Brief
 
 ${BRIEF_TEXT}
 
 ---
 
 ▶ TAKE YOUR TURN (${BUILDER} — BUILDER role)
 
 You are the BUILDER for this phase. Read the phase brief above and implement it.
 1. ${BUILDER_IMPL_LINE}
 2. Append a build block to this relay file: \`### Round N · Builder · ${BUILDER}\` summarizing what you did (files touched, key decisions).
 3. Use this exact tick binary (run it from any directory): ${TICK_CLI}
    - ${TICK_CLI} claim ${RELAY_TASK} --agent ${BUILDER} --paths "${CLAIM_PATHS}"
    - ${TICK_CLI} ping ${RELAY_TASK} --agent ${BUILDER}
    - ${TICK_CLI} release ${RELAY_TASK} --agent ${BUILDER} --to ${REVIEWER}
 4. ${BUILDER_SCOPE_LINE}
 
 ---
 
 ▶ TAKE YOUR TURN (${REVIEWER} — REVIEWER role)
 
 You are the REVIEWER for this phase. ${REVIEWER_READ_LINE}
 1. Append a review block: \`### Round N · Reviewer · ${REVIEWER}\` followed by your assessment.
 2. If changes needed: add \`**Verdict:** Changes requested\` then: ${TICK_CLI} release ${RELAY_TASK} --agent ${REVIEWER} --to ${BUILDER}
 3. If satisfied: add \`**Verdict:** Approved\`, set \`STATUS: Approved\`, then: ${TICK_CLI} done ${RELAY_TASK} --agent ${REVIEWER}
 4. Use this exact tick binary (run it from any directory) for all token operations: ${TICK_CLI}
    ${REVIEWER_SCOPE_LINE}
 RELAY_EOF
 
 if ((DRY_RUN)); then
   log "dry-run: relay file rendered at $RELAY_FILE"
   printf 'tick seed: log task.created %s + claim --agent marathon + release --to %s\n' "$RELAY_TASK" "$BUILDER"
   exit 0
 fi
 
 # ── Step 2: commit the relay file (rtl_before needs a clean HEAD) ───────────
 
 git -C "$ROOT" add -- "$RELAY_FILE"
 git -C "$ROOT" commit -q -m "marathon: render phase ${PHASE_ID} relay (${RELAY_TASK})"
 log "relay file committed: $RELAY_FILE"
 
 # ── Step 3: seed tick token with handoff → builder ──────────────────────────
 
 export TICK_REPO_ROOT="$ROOT"
 
 reconcile_relay_task() {
   local info status handoff claimer
   if ! info="$("$TICK_BIN" info "$RELAY_TASK" 2>/dev/null)"; then
     return 0  # no prior task state to reconcile
   fi
 
   status="$(printf '%s\n' "$info" | sed -n 's/^status:[[:space:]]*//p' | head -n1)"
   handoff="$(printf '%s\n' "$info" | sed -n 's/^handoff-to:[[:space:]]*//p' | head -n1)"
   claimer="$(printf '%s\n' "$info" | sed -n 's/^claimer:[[:space:]]*//p' | head -n1)"
 
   case "$status" in
     claimed)
       die "relay task $RELAY_TASK already has a live claim by ${claimer:-unknown}; refusing to reap a live claim"
       ;;
     open)
       [[ -n "$handoff" ]] || return 0
       case "$handoff" in
         "$BUILDER"|"$REVIEWER")
           # GH-56: a rerun can inherit an OPEN handoff from the previous pass. Clear only that stale
           # reservation by consuming it as its routed target, then releasing it unreserved. Never reap a
           # live claim here; parked claims are the watchdog's authority path.
           "$TICK_BIN" claim "$RELAY_TASK" --agent "$handoff" --paths "$REL_RELAY" > /dev/null
           "$TICK_BIN" release "$RELAY_TASK" --agent "$handoff" > /dev/null
           log "reconciled leaked open handoff: $RELAY_TASK (cleared stale reservation for $handoff)"
           ;;
         *)
           die "relay task $RELAY_TASK is open but reserved for unexpected agent '$handoff'"
           ;;
       esac
       ;;
   esac
 }
 
+# GH-45: per-lane attempt cap — refuse to start this phase once it has hit LANE_MAX_ATTEMPTS
+# (keyed on PHASE_ID, stable across re-fires), seeding no token; --force overrides. Counted here, so
+# the nested relay-drive below (LANE_ATTEMPT_COUNTED=1) does not double-count this same lane.
+lane_attempt_gate "${TICK_REPO_ROOT:-$ROOT}" "$PHASE_ID" "$FORCE" || exit $?
+
 reconcile_relay_task
 
 "$TICK_BIN" log task.created "$RELAY_TASK" --agent marathon > /dev/null
 "$TICK_BIN" claim           "$RELAY_TASK" --agent marathon --paths "$REL_RELAY" > /dev/null
 "$TICK_BIN" release         "$RELAY_TASK" --agent marathon --to "$BUILDER" > /dev/null
 log "tick token seeded: $RELAY_TASK → $BUILDER"
 
 # ── Step 4: emit phase.start ────────────────────────────────────────────────
 
 "$TICK_BIN" log marathon.phase.start "$RELAY_TASK" --agent marathon > /dev/null
 log "phase start: running relay-drive --round-cap $ROUND_CAP"
 
 # ── Step 5: run relay-drive (the loop — unmodified) ────────────────────────
 
 # relay-drive runs a bare executable --agent-cmd path directly (space-safe, even ".../GH Repos/..."),
 # falling back to eval only for command strings — so we pass the path as-is, no %q quoting needed.
 relay_exit=0
 target_root_args=()
 [[ -n "$TARGET_ROOT" ]] && target_root_args=(--target-root "$TARGET_ROOT")
 # GH-75: the nested relay loop reaches its own terminal exit once PER PHASE. Force its XYZ.json hook
 # silent (XYZ_HARNESS_CONTEXT=marathon-phase) so a per-phase relay completion never emits its own
 # record — this marathon-drive run (or marathon.sh above it) owns the single whole-run record. This is
 # scoped to the relay-drive child only; marathon-drive's OWN context (swarm|unset) is left intact for
 # its hook below.
 RELAY_FILE="$RELAY_FILE" \
+LANE_ATTEMPT_COUNTED=1 \
 XYZ_HARNESS_CONTEXT=marathon-phase \
   "$RELAY_DRIVE_BIN" \
     --relay-file "$RELAY_FILE" \
     --relay-task "$RELAY_TASK" \
     --agent-cmd  "$AGENT_CMD" \
     --round-cap  "$ROUND_CAP" \
     ${target_root_args[@]+"${target_root_args[@]}"} \
   || relay_exit=$?
 
 # ── Step 6: act on relay-drive exit code ───────────────────────────────────
 
 escalate() {  # <reason> <relay-exit>
   local reason="$1" rexit="$2"
   cat > "$PHASE_DIR/ESCALATION.md" << ESC_EOF
 # ESCALATION — Marathon Phase ${PHASE_ID}
 
 phase: ${PHASE_ID}
 task: ${RELAY_TASK}
 relay-drive-exit: ${rexit}
 reason: ${reason}
 relay-file: ${REL_RELAY}
 ESC_EOF
   git -C "$ROOT" add -- "$PHASE_DIR/ESCALATION.md"
   git -C "$ROOT" commit -q -m "marathon: phase ${PHASE_ID} escalation (${reason})"
   "$TICK_BIN" log marathon.phase.escalated "$RELAY_TASK" --agent marathon > /dev/null || true
   log "escalation written: $PHASE_DIR/ESCALATION.md (reason: $reason)"
 }
 
 save_transcript() {
   local date_dir; date_dir="$ROOT/relay-system/$(date +%Y-%m-%d)"
   mkdir -p "$date_dir"
   local ts; ts="$(date +%H%M%S)"
   local dest="$date_dir/marathon-${PHASE_ID}-${ts}.md"
   cp "$RELAY_FILE" "$dest"
   git -C "$ROOT" add -- "$dest"
   git -C "$ROOT" commit -q -m "marathon: phase ${PHASE_ID} transcript saved (${RELAY_TASK})"
   log "transcript saved: $dest"
 }
 
 case "$relay_exit" in
   0)
     # relay closed Approved. Run the pre-advance gate before emitting phase.approved.
     log "relay approved — running pre-advance gate: $PRE_ADVANCE_CMD"
     gate_exit=0
     # Gate belongs to the target repo when --target-root is set (e.g. a foreign repo's `npm test`).
     ( [[ -n "$TARGET_ROOT" ]] && cd "$TARGET_ROOT"; eval "$PRE_ADVANCE_CMD" ) || gate_exit=$?
     if [[ "$gate_exit" -ne 0 ]]; then
       log "pre-advance gate FAILED (exit $gate_exit) — escalating"
       escalate "pre-advance-failed" "$relay_exit"
       xyz_marathon_emit red "halted at phase ${PHASE_ID} — pre-advance gate failed"
       exit 5
     fi
     "$TICK_BIN" log marathon.phase.approved "$RELAY_TASK" --agent marathon > /dev/null || true
     save_transcript
     log "phase ${PHASE_ID} complete — STATUS: Approved, gate passed"
     xyz_marathon_emit green "phase ${PHASE_ID} complete — STATUS: Approved, gate passed"
     exit 0
     ;;
   3)
     log "relay escalated: no-progress (relay-drive exit 3)"
     escalate "no-progress" 3
     xyz_marathon_emit red "halted at phase ${PHASE_ID} — relay no-progress"
     exit 3
     ;;
   4)
     log "relay escalated: cap/close-mismatch (relay-drive exit 4)"
     escalate "cap-or-close-mismatch" 4
     xyz_marathon_emit red "halted at phase ${PHASE_ID} — relay cap/close-mismatch"
     exit 4
     ;;
   6)
     # A turn-taker shim hit an off-lane edit, reverted it, and failed the turn (exit 6) — the
     # containment boundary fired. This is a DEFINED escalation, not an "unexpected" crash: the
     # builder strayed but the safety core held. Record it like any other escalation. (Dogfood
     # 2026-06-17: an autonomous builder edited an off-lane file; rtl_enforce caught + reverted it.)
     log "relay escalated: containment violation — a turn-taker reverted an off-lane edit (exit 6)"
     escalate "containment-violation (off-lane edit reverted by a turn-taker)" 6
     xyz_marathon_emit red "halted at phase ${PHASE_ID} — containment violation (off-lane edit reverted)"
     exit 6
     ;;
diff --git a/relay-automation/relay-drive.sh b/relay-automation/relay-drive.sh
index 16ecc51..8227359 100755
--- a/relay-automation/relay-drive.sh
+++ b/relay-automation/relay-drive.sh
@@ -1,225 +1,260 @@
 #!/usr/bin/env bash
 set -euo pipefail
 #
 # relay-drive.sh — Phase 4(a): supervise a /relay thread to termination, with the
 # turn-token held as a tick **RELAY-TURN task** (claim / ping / release --to / done).
 #
 # This is the SUPERVISOR, not the turn-taker. Each turn is taken by --agent-cmd
 # (a fake in tests; the baton/live window in Option B; a headless CLI in a future
 # Option A). The turn-taker owns the work + thread mutation — it claims/resumes the
 # RELAY-TURN task as RELAY_AGENT, `tick ping`s it, appends its block + sets the
 # file's STATUS/verdict, then **`tick release RELAY-TURN --to <other>`** to hand off
 # (or **`tick done RELAY-TURN`** + STATUS: Approved on the final turn), and commits.
 #
 # Whose-turn is the tick token (so the Phase-1 handoff-exclusive rule applies and the
 # Phase-2 watchdog can see a stalled turn). The human-readable thread's STATUS is the
 # terminal (Approved/Closed) signal. The supervisor only:
 #   - reads the RELAY-TURN actor + the file STATUS to decide whether to continue,
 #   - invokes the turn-taker for the current actor,
 #   - enforces a round cap, and
 #   - escalates on no-progress (token actor didn't move) instead of looping forever.
 #
 # Turn-taker env: RELAY_FILE, RELAY_TASK, RELAY_AGENT (the current actor).
 # Exit: 0 = relay closed Approved/Closed · 3 = no-progress (stall) · 4 = cap / closed-not-approved /
 #       escalated-to-human-by-design (STATUS: Escalated) · 5 = review-once: reviewer completed a turn
 #       (non-approval handback — a successful single review, NOT a stall) · 2 = usage.
 
 ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
 TICK_BIN="${TICK_BIN:-"$ROOT_DIR/bin/tick"}"
 CONSULT_SH="${CONSULT_SH:-"$ROOT_DIR/relay-automation/consult.sh"}"
 XYZ_APPEND_BIN="${XYZ_APPEND_BIN:-"$ROOT_DIR/utils/telemetry/append-xyz-completion.sh"}"
 
+# GH-45 — QUEUE commitment contract: per-lane attempt cap (anti-rabbit-hole / WIP discipline).
+# Appends one line per fire to .tick/attempts/<lane> and REFUSES to start a lane at
+# >= LANE_MAX_ATTEMPTS (default 2, env-overridable) with exit 8 + a park message, seeding NO relay
+# token. --force bypasses for one fire and logs it. A nested call (marathon-drive → relay-drive) is
+# guarded by LANE_ATTEMPT_COUNTED so the same lane is counted exactly once. Byte-consistent mirror in
+# marathon-drive.sh; relay-turn-lib.sh / bin/tick are NOT touched.
+lane_attempt_gate() {
+  local root="$1" raw="$2" force="${3:-0}"
+  [ -n "${LANE_ATTEMPT_COUNTED:-}" ] && return 0
+  local key; key=$(printf '%s' "$raw" | tr -c 'A-Za-z0-9._-' '_')
+  local max="${LANE_MAX_ATTEMPTS:-2}"
+  local dir="$root/.tick/attempts" file count
+  file="$dir/$key"
+  mkdir -p "$dir" 2>/dev/null || true
+  count=0; [ -f "$file" ] && count=$(wc -l < "$file" 2>/dev/null | tr -d ' '); [ -n "$count" ] || count=0
+  if [ "$force" = "1" ]; then
+    printf 'lane-attempt-cap: --force override — lane %s at %s attempt(s) (cap %s), proceeding.\n' "$key" "$count" "$max" >&2
+  elif [ "$count" -ge "$max" ]; then
+    printf 'lane-attempt-cap: lane %s PARKED after %s attempt(s) (cap %s) — no relay token seeded.\n' "$key" "$count" "$max" >&2
+    printf '  Re-anchor to the committed QUEUE lanes (AGENTS.md) or re-fire with --force. Attempts log: %s\n' "$file" >&2
+    return 8
+  fi
+  printf '%s fire\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || echo fire)" >> "$file"
+  return 0
+}
+
 # GH-75: append ONE final-completion record to XYZ.json at the harness repo root when a STANDALONE
 # /relay session terminates. Stays SILENT when this relay-drive runs nested inside a marathon/swarm
 # phase — marathon-drive.sh sets XYZ_HARNESS_CONTEXT for the nested call (marathon-phase|swarm) and the
 # outer harness owns the whole-run record, so a per-phase relay completion must not double-emit.
 # Best-effort: a telemetry failure must never change the relay's own exit path.
 xyz_relay_emit() {  # <health>
   case "${XYZ_HARNESS_CONTEXT:-relay}" in relay) ;; *) return 0 ;; esac
   [[ -x "$XYZ_APPEND_BIN" ]] || return 0
   local health="$1" slug title s desc
   slug="$(basename "$RELAY_FILE" .md)"
   title="$(grep -m1 '^# ' "$RELAY_FILE" 2>/dev/null | sed 's/^#[[:space:]]*//; s/[[:space:]]*$//')" || true
   [[ -n "$title" ]] || title="$slug"
   s="$(file_status)"
   desc="Relay session ended: STATUS ${s:-unknown} (health ${health})."
   "$XYZ_APPEND_BIN" relay "$slug" "$health" "$title" "$desc" >/dev/null 2>&1 || true
 }
 
 if [[ "${RELAY_DRIVER_LOCKED:-0}" != "1" ]]; then
   # The driver lock lives in .git/ (never committed) for a normal harness clone. A GH-49 vendored
   # .xyz/ copy has no .git/, so mkdir'ing a lock there would fail — fall back to a hidden lock beside
   # the scripts (the .xyz/ dir is itself gitignored in the foreign repo, so it stays uncommitted just
   # the same). When .git/ exists the path is unchanged, so a normal clone behaves byte-identically.
   if [[ -d "$ROOT_DIR/.git" ]]; then
     _lock="$ROOT_DIR/.git/relay-driver.lock"; _lock_label=".git/relay-driver.lock"
   else
     _lock="$ROOT_DIR/.relay-driver.lock";     _lock_label=".relay-driver.lock"
   fi
   if ! mkdir "$_lock" 2>/dev/null; then
     # GH-42 self-heal: reclaim the lock only if its holder is dead. A crashed/killed driver used to
     # leave a stale lock that blocked every later run until a manual rmdir.
     _holder="$(cat "$_lock/pid" 2>/dev/null || true)"
     if [[ -n "$_holder" ]] && kill -0 "$_holder" 2>/dev/null; then
       printf 'relay-drive: another driver is active in this repo (pid %s, lock: %s).\n' "$_holder" "$_lock_label" >&2
       printf 'relay-drive: Concurrent runs in the same clone are unsafe (GH-42 ROOT HEAD hazard).\n' >&2
       exit 1
     fi
     printf 'relay-drive: reclaiming stale relay-driver.lock (holder pid %s not running).\n' "${_holder:-none}" >&2
     rm -rf "$_lock"
     mkdir "$_lock" 2>/dev/null || { printf 'relay-drive: could not acquire relay-driver.lock after reclaiming a stale one.\n' >&2; exit 1; }
   fi
   printf '%s\n' "$$" > "$_lock/pid"
   trap 'rm -rf "$_lock" 2>/dev/null || true' EXIT
   export RELAY_DRIVER_LOCKED=1
 fi
 
 usage() {
   cat <<'EOF'
 Usage: relay-automation/relay-drive.sh --relay-file PATH --agent-cmd CMD [options]
 
   --relay-file PATH   The relay thread (reads STATUS: as the terminal signal).
   --agent-cmd CMD     Turn-taker; invoked with env RELAY_FILE + RELAY_TASK + RELAY_AGENT.
                       Must take the turn on the RELAY-TURN task (claim/ping/append/
                       release --to <other> | done) and commit.
   --relay-task ID     The relay turn-token task (default: RELAY-TURN).
   --round-cap N       Max turns before escalating (default: 6).
   --target-root DIR   The target git repository root (must be an existing git repo).
   --consult-verify    After each turn, invoke consult.sh to independently challenge the
                       turn-taker's VERDICT. Fires 1-2 real API calls per turn (codex +
                       gemini). Do NOT use in CI or budget-sensitive runs.
   --artifact-file P   Seed an external read-only artifact (a cross-repo PR/diff or any file) into the
                       isolated worktree at .relay-artifacts/<basename> so the reviewer can READ it
                       without it being committed into the target repo. Requires worktree isolation
                       (the default). The reviewer may not edit it (an edit fails the turn). Implements #15.
   --review-once       Drive exactly ONE turn (a single review) and classify its outcome:
                       Approved/Closed -> 0; a completed non-approval handback ("changes
                       requested") -> 5 (NOT the stall's 3); reviewer-did-nothing stall -> 3;
                       Escalated -> 4. Forces --round-cap 1.
   --dry-run           Print the turn it WOULD drive next, then stop (no invocation).
   --help
 EOF
 }
 
 die() { printf 'relay-drive: %s\n' "$*" >&2; exit 2; }
 
-RELAY_FILE=""; AGENT_CMD=""; RELAY_TASK="RELAY-TURN"; ROUND_CAP=6; DRY_RUN=0; CONSULT_VERIFY=0; REVIEW_ONCE=0; ARTIFACT_FILE=""
+RELAY_FILE=""; AGENT_CMD=""; RELAY_TASK="RELAY-TURN"; ROUND_CAP=6; DRY_RUN=0; CONSULT_VERIFY=0; REVIEW_ONCE=0; ARTIFACT_FILE=""; FORCE=0
 while (($# > 0)); do
   case "$1" in
     --relay-file) RELAY_FILE="${2:-}"; shift 2 ;;
     --agent-cmd) AGENT_CMD="${2:-}"; shift 2 ;;
     --relay-task) RELAY_TASK="${2:-}"; shift 2 ;;
     --round-cap) ROUND_CAP="${2:-}"; shift 2 ;;
     --target-root) TARGET_ROOT="${2:-}"; shift 2 ;;
     --consult-verify) CONSULT_VERIFY=1; shift ;;
     --review-once) REVIEW_ONCE=1; shift ;;
     --artifact-file) ARTIFACT_FILE="${2:-}"; shift 2 ;;
+    --force) FORCE=1; shift ;;      # GH-45: bypass the per-lane attempt cap for this one fire
     --dry-run) DRY_RUN=1; shift ;;
     --help) usage; exit 0 ;;
     *) die "unknown argument: $1" ;;
   esac
 done
 [[ -n "$RELAY_FILE" ]] || { usage; die "--relay-file is required"; }
 [[ -n "$AGENT_CMD" || "$DRY_RUN" -eq 1 ]] || { usage; die "--agent-cmd is required"; }
 
 # --review-once drives a single review turn; its success oracle (a completed non-approval handback
 # exits 5, not the stall's 3) replaces the multi-round no-progress/cap logic, so force the cap to 1.
 ((REVIEW_ONCE)) && ROUND_CAP=1
 
 if [[ -n "${TARGET_ROOT+set}" ]]; then
   [[ -n "$TARGET_ROOT" ]] || die "--target-root requires a non-empty path"   # else git -C '' falls back to CWD
   git -C "$TARGET_ROOT" rev-parse --show-toplevel >/dev/null 2>&1 \
     || die "invalid target root (not a git repo): $TARGET_ROOT"
   export RELAY_TARGET_ROOT="$TARGET_ROOT"
 fi
 
 # Resolve --relay-file AFTER --target-root is known. With --target-root the thread lives in the
 # TARGET repo, so a repo-relative path must resolve relative to the target root, not the harness CWD
 # (GH-18 #2): if it isn't found as given but exists under --target-root, use that. Absolute paths and
 # CWD-relative paths that already resolve are unchanged. (ALLOW_PATHS is already target-relative — the
 # shim resolves it against RELAY_TARGET_ROOT in relay-turn-lib.sh.)
 if [[ ! -f "$RELAY_FILE" && -n "${TARGET_ROOT:-}" && "$RELAY_FILE" != /* && -f "$TARGET_ROOT/$RELAY_FILE" ]]; then
   RELAY_FILE="$TARGET_ROOT/$RELAY_FILE"
 fi
 [[ -f "$RELAY_FILE" ]] || die "relay file does not exist: $RELAY_FILE"
 
+# GH-45: per-lane attempt cap. A real build/review LOOP counts; a single --review-once turn and a
+# dry-run do not (they can't rabbit-hole). Keyed on the relay task, stable across re-fires.
+if ((DRY_RUN == 0)) && ((REVIEW_ONCE == 0)); then
+  # Attempts live with the tick token (its repo), so tests that point TICK_REPO_ROOT at a temp dir
+  # stay hermetic; a real standalone run falls back to this clone.
+  lane_attempt_gate "${TICK_REPO_ROOT:-$ROOT_DIR}" "$RELAY_TASK" "$FORCE" || exit $?
+fi
+
 # Containment default for unattended/driven runs: isolate the turn-taker in a throwaway worktree
 # (ROOT@HEAD) so an off-task model's stray creations/renames can't reach the real tree. The leaf
 # shims (codex/agy/claude-turn.sh) read RELAY_WORKTREE_ISOLATION; exporting it here makes every
 # DRIVEN turn contained by default. Opt out per run with RELAY_WORKTREE_ISOLATION=0. (Direct/attended
 # shim use keeps the leaf default OFF — only the orchestration layer defaults it ON.)
 : "${RELAY_WORKTREE_ISOLATION:=1}"; export RELAY_WORKTREE_ISOLATION
 
 # GH-32 #1: under worktree isolation the turn-taker runs in a throwaway worktree at ROOT@HEAD, so a
 # relay file that isn't committed at HEAD is INVISIBLE to it (untracked-not-ignored — relay-system/ is
 # tracked here except two specific files). The reviewer then "finds nothing" and silently does no work.
 # Warn loudly with the exact remedy; never block (a non-isolated run is free to use an uncommitted file,
 # and a relay file outside any git repo is fine too). Mirrors the cross-repo warning style in the shims.
 warn_if_relay_file_untracked() {
   [[ "${RELAY_WORKTREE_ISOLATION:-1}" != 0 ]] || return 0
   local dir prefix rel
   dir="$(cd "$(dirname "$RELAY_FILE")" 2>/dev/null && pwd)" || return 0   # not a real dir → skip
   # --show-prefix yields the repo-root-relative path of $dir (empty at root); building the relative
   # path this way avoids subtracting an absolute toplevel, which breaks under macOS /var → /private/var
   # symlinks (logical pwd vs git's physical toplevel).
   prefix="$(git -C "$dir" rev-parse --show-prefix 2>/dev/null)" || return 0  # not in a git repo → skip
   rel="${prefix}$(basename "$RELAY_FILE")"
   git -C "$dir" cat-file -e "HEAD:$rel" 2>/dev/null && return 0           # present at HEAD → visible
   printf 'relay-drive: WARNING — relay file is not committed at HEAD: %s\n' "$rel" >&2
   printf '  RELAY_WORKTREE_ISOLATION=1 runs the turn-taker in a worktree at HEAD, so this untracked\n' >&2
   printf '  file is INVISIBLE to the reviewer (it will find nothing and do no work). Remedy: commit\n' >&2
   printf '  the relay file first, or re-run with RELAY_WORKTREE_ISOLATION=0.\n' >&2
 }
 warn_if_relay_file_untracked
 
 # GH-31 / #15: a read-only artifact under review. Absolutize it (the shim runs with a different CWD)
 # and export it so relay-turn-lib seeds it into the isolated worktree. It only works under isolation —
 # warn loudly if isolation is off, so the reviewer isn't left silently unable to see it.
 if [[ -n "$ARTIFACT_FILE" ]]; then
   [[ -f "$ARTIFACT_FILE" ]] || die "artifact file not found: $ARTIFACT_FILE"
   case "$ARTIFACT_FILE" in
     /*) : ;;
     *)  ARTIFACT_FILE="$(cd "$(dirname "$ARTIFACT_FILE")" && pwd)/$(basename "$ARTIFACT_FILE")" ;;
   esac
   export RELAY_ARTIFACT_FILE="$ARTIFACT_FILE"
   [[ "$RELAY_WORKTREE_ISOLATION" != 0 ]] || \
     printf 'relay-drive: WARNING — --artifact-file needs worktree isolation to seed the artifact; with RELAY_WORKTREE_ISOLATION=0 the reviewer will not see it.\n' >&2
 fi
 
 file_status() { sed -n 's/^STATUS:[[:space:]]*//p' "$RELAY_FILE" | head -1 | sed 's/[[:space:]]*$//'; }
 terminal_status() { case "$1" in Approved|Closed) return 0 ;; *) return 1 ;; esac; }
 # Escalated is TERMINAL BY DESIGN: the reviewer handed back to a human (e.g. at the round cap),
 # typically WITHOUT releasing the token. The explicit status IS the intent signal — a true stall
 # leaves STATUS unchanged — so this is NOT a no-progress failure. Reported as a clean, distinct
 # outcome (exit 4 = terminal/not-approved) so a correct handback doesn't read as a stall (GH-18 #5).
 escalated_status() { case "$1" in Escalated) return 0 ;; *) return 1 ;; esac; }
 
 # Current actor of the RELAY-TURN token: claimer (if claimed) else handoff_to (if
 # open) else "" (done/missing). Echoes "<status>\t<actor>".
 token_state() {
   local info status claimer handoff actor
   info="$("$TICK_BIN" info "$RELAY_TASK" 2>/dev/null || true)"
   status="$(printf '%s\n' "$info"  | sed -n 's/^status:[[:space:]]*//p'     | head -1)"
   claimer="$(printf '%s\n' "$info" | sed -n 's/^claimer:[[:space:]]*//p'    | head -1)"
   handoff="$(printf '%s\n' "$info" | sed -n 's/^handoff-to:[[:space:]]*//p' | head -1)"
   case "$status" in
     claimed) actor="$claimer" ;;
     open)    actor="$handoff" ;;
     *)       actor="" ;;
   esac
   printf '%s\t%s\n' "$status" "$actor"
 }
 
 round=0
 while ((round < ROUND_CAP)); do
   s="$(file_status)"
   IFS=$'\t' read -r tstatus actor < <(token_state)
 
   # Terminal CLOSE requires AGREEMENT: file STATUS terminal AND the RELAY-TURN
   # token no longer live (done/gone). file-terminal-but-token-live is a leaked
   # close — escalate, never report success. (Codex r1 Blocker.)
   if terminal_status "$s"; then
     if [[ -n "$actor" ]]; then
       printf 'relay-drive: STATUS %s but RELAY-TURN still live (%s/%s) — close mismatch, escalating\n' "$s" "$tstatus" "$actor" >&2
       exit 4
     fi
diff --git a/test/lane-attempt-cap.sh b/test/lane-attempt-cap.sh
new file mode 100755
index 0000000..8b1c577
--- /dev/null
+++ b/test/lane-attempt-cap.sh
@@ -0,0 +1,83 @@
+#!/usr/bin/env bash
+# GH-45 — QUEUE commitment contract: per-lane attempt cap (anti-rabbit-hole / WIP discipline).
+# Proves the cap logic in relay-drive.sh + marathon-drive.sh: a lane is REFUSED (exit 8, no token)
+# once it hits LANE_MAX_ATTEMPTS; --force overrides; a nested (LANE_ATTEMPT_COUNTED) call is a no-op;
+# and both drivers carry a byte-consistent mirror + wire the gate at the right seam.
+set -u
+HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
+ROOT="$(cd "$HERE/.." && pwd)"
+WORK="$(mktemp -d -t "lane-attempt-cap.XXXXXX")"
+trap 'rm -rf "$WORK"' EXIT
+
+PASS=0; FAIL=0
+pass() { echo "  PASS: $*"; PASS=$((PASS+1)); }
+fail() { echo "  FAIL: $*" >&2; FAIL=$((FAIL+1)); }
+echo "== test: lane-attempt-cap =="
+
+RELAY_DRIVE="$ROOT/relay-automation/relay-drive.sh"
+MARATHON_DRIVE="$ROOT/relay-automation/marathon-drive.sh"
+
+# ── 1. Both drivers parse + are wired ──────────────────────────────────────
+bash -n "$RELAY_DRIVE"     && pass "relay-drive.sh parses"     || fail "relay-drive.sh syntax"
+bash -n "$MARATHON_DRIVE"  && pass "marathon-drive.sh parses"  || fail "marathon-drive.sh syntax"
+
+grep -qE 'lane_attempt_gate .*"\$RELAY_TASK" "\$FORCE"' "$RELAY_DRIVE" \
+  && pass "relay-drive.sh calls lane_attempt_gate (keyed on RELAY_TASK)" || fail "relay-drive gate call missing"
+grep -qE 'lane_attempt_gate .*"\$PHASE_ID" "\$FORCE"' "$MARATHON_DRIVE" \
+  && pass "marathon-drive.sh calls lane_attempt_gate (keyed on PHASE_ID)" || fail "marathon-drive gate call missing"
+grep -q 'TICK_REPO_ROOT:-' "$RELAY_DRIVE" \
+  && pass "relay-drive.sh keys attempts off TICK_REPO_ROOT (hermetic in tests)" || fail "relay-drive not TICK_REPO_ROOT-anchored"
+grep -q 'LANE_ATTEMPT_COUNTED=1' "$MARATHON_DRIVE" \
+  && pass "marathon-drive.sh guards the nested relay-drive against double-count" || fail "LANE_ATTEMPT_COUNTED guard missing"
+grep -qE 'REVIEW_ONCE == 0' "$RELAY_DRIVE" \
+  && pass "relay-drive.sh skips the cap for a single --review-once turn" || fail "review-once cap-skip missing"
+
+# ── 2. Byte-consistent mirror (the contract requires it) ───────────────────
+extract() { sed -n '/^lane_attempt_gate() {/,/^}/p' "$1"; }
+extract "$RELAY_DRIVE" > "$WORK/fn-relay.sh"
+extract "$MARATHON_DRIVE" > "$WORK/fn-marathon.sh"
+[ -s "$WORK/fn-relay.sh" ] && pass "lane_attempt_gate present in relay-drive.sh" || fail "function missing in relay-drive"
+if diff -q "$WORK/fn-relay.sh" "$WORK/fn-marathon.sh" >/dev/null; then
+  pass "lane_attempt_gate is byte-identical in both drivers"
+else
+  fail "lane_attempt_gate diverges between the two drivers"
+fi
+
+# ── 3. Behavior — source the real function and exercise it ─────────────────
+. "$WORK/fn-relay.sh"
+R="$WORK/repo"; mkdir -p "$R/.tick"
+
+# default cap = 2: two fires pass, the third parks (exit 8)
+( LANE_MAX_ATTEMPTS=2; lane_attempt_gate "$R" "LANE-A" 0 ); r1=$?
+( LANE_MAX_ATTEMPTS=2; lane_attempt_gate "$R" "LANE-A" 0 ); r2=$?
+out="$(LANE_MAX_ATTEMPTS=2 lane_attempt_gate "$R" "LANE-A" 0 2>&1)"; r3=$?
+[ "$r1" = 0 ] && [ "$r2" = 0 ] && pass "first two fires proceed (exit 0)" || fail "early fires blocked (r1=$r1 r2=$r2)"
+[ "$r3" = 8 ] && pass "third fire PARKED with exit 8 (cap reached)" || fail "cap did not fire (r3=$r3)"
+printf '%s' "$out" | grep -q 'PARKED' && pass "park message printed" || fail "no park message: $out"
+[ "$(wc -l < "$R/.tick/attempts/LANE-A" | tr -d ' ')" = 2 ] \
+  && pass "parked fire seeded NO extra attempt (still 2 recorded)" || fail "parked fire wrongly appended"
+
+# --force bypasses the cap and logs the override, and DOES count
+out="$(LANE_MAX_ATTEMPTS=2 lane_attempt_gate "$R" "LANE-A" 1 2>&1)"; rf=$?
+[ "$rf" = 0 ] && pass "--force proceeds past the cap (exit 0)" || fail "--force blocked (rf=$rf)"
+printf '%s' "$out" | grep -q 'force override' && pass "--force logs the override" || fail "no override log: $out"
+[ "$(wc -l < "$R/.tick/attempts/LANE-A" | tr -d ' ')" = 3 ] \
+  && pass "--force fire is recorded (now 3 attempts)" || fail "--force fire not recorded"
+
+# nested guard: LANE_ATTEMPT_COUNTED makes it a no-op (no refuse, no append)
+before=$(wc -l < "$R/.tick/attempts/LANE-A" | tr -d ' ')
+( LANE_MAX_ATTEMPTS=2; LANE_ATTEMPT_COUNTED=1; lane_attempt_gate "$R" "LANE-A" 0 ); rn=$?
+after=$(wc -l < "$R/.tick/attempts/LANE-A" | tr -d ' ')
+[ "$rn" = 0 ] && [ "$before" = "$after" ] \
+  && pass "LANE_ATTEMPT_COUNTED short-circuits (no refuse, no double-count)" || fail "nested guard failed (rn=$rn $before->$after)"
+
+# env-overridable cap + key sanitization (a path-like lane id is flattened)
+( LANE_MAX_ATTEMPTS=1; lane_attempt_gate "$R" "PROJECT/1-INBOX/GH-45.md" 0 ); k1=$?
+o2="$(LANE_MAX_ATTEMPTS=1 lane_attempt_gate "$R" "PROJECT/1-INBOX/GH-45.md" 0 2>&1)"; k2=$?
+[ "$k1" = 0 ] && [ "$k2" = 8 ] && pass "LANE_MAX_ATTEMPTS=1 caps after one fire" || fail "custom cap wrong (k1=$k1 k2=$k2)"
+[ -f "$R/.tick/attempts/PROJECT_1-INBOX_GH-45.md" ] \
+  && pass "path-like lane id sanitized to a single flat key" || fail "key not sanitized"
+
+echo "  lane-attempt-cap: $PASS pass, $FAIL fail"
+[ "$FAIL" -eq 0 ] || exit 1
+exit 0

codex
The core change is visible now. Next I’m checking the final file state with line numbers, then I’ll probe for exit-code collisions and any missing path through the nested `marathon-drive -> relay-drive` call.
mcp: codebase-memory-mcp/list_projects started
mcp: codebase-memory-mcp/list_projects (failed)
user cancelled MCP tool call
exec
/bin/zsh -lc "nl -ba relay-automation/relay-drive.sh | sed -n '1,240p'" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-61154-16825
 succeeded in 0ms:
     1	#!/usr/bin/env bash
     2	set -euo pipefail
     3	#
     4	# relay-drive.sh — Phase 4(a): supervise a /relay thread to termination, with the
     5	# turn-token held as a tick **RELAY-TURN task** (claim / ping / release --to / done).
     6	#
     7	# This is the SUPERVISOR, not the turn-taker. Each turn is taken by --agent-cmd
     8	# (a fake in tests; the baton/live window in Option B; a headless CLI in a future
     9	# Option A). The turn-taker owns the work + thread mutation — it claims/resumes the
    10	# RELAY-TURN task as RELAY_AGENT, `tick ping`s it, appends its block + sets the
    11	# file's STATUS/verdict, then **`tick release RELAY-TURN --to <other>`** to hand off
    12	# (or **`tick done RELAY-TURN`** + STATUS: Approved on the final turn), and commits.
    13	#
    14	# Whose-turn is the tick token (so the Phase-1 handoff-exclusive rule applies and the
    15	# Phase-2 watchdog can see a stalled turn). The human-readable thread's STATUS is the
    16	# terminal (Approved/Closed) signal. The supervisor only:
    17	#   - reads the RELAY-TURN actor + the file STATUS to decide whether to continue,
    18	#   - invokes the turn-taker for the current actor,
    19	#   - enforces a round cap, and
    20	#   - escalates on no-progress (token actor didn't move) instead of looping forever.
    21	#
    22	# Turn-taker env: RELAY_FILE, RELAY_TASK, RELAY_AGENT (the current actor).
    23	# Exit: 0 = relay closed Approved/Closed · 3 = no-progress (stall) · 4 = cap / closed-not-approved /
    24	#       escalated-to-human-by-design (STATUS: Escalated) · 5 = review-once: reviewer completed a turn
    25	#       (non-approval handback — a successful single review, NOT a stall) · 2 = usage.
    26	
    27	ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
    28	TICK_BIN="${TICK_BIN:-"$ROOT_DIR/bin/tick"}"
    29	CONSULT_SH="${CONSULT_SH:-"$ROOT_DIR/relay-automation/consult.sh"}"
    30	XYZ_APPEND_BIN="${XYZ_APPEND_BIN:-"$ROOT_DIR/utils/telemetry/append-xyz-completion.sh"}"
    31	
    32	# GH-45 — QUEUE commitment contract: per-lane attempt cap (anti-rabbit-hole / WIP discipline).
    33	# Appends one line per fire to .tick/attempts/<lane> and REFUSES to start a lane at
    34	# >= LANE_MAX_ATTEMPTS (default 2, env-overridable) with exit 8 + a park message, seeding NO relay
    35	# token. --force bypasses for one fire and logs it. A nested call (marathon-drive → relay-drive) is
    36	# guarded by LANE_ATTEMPT_COUNTED so the same lane is counted exactly once. Byte-consistent mirror in
    37	# marathon-drive.sh; relay-turn-lib.sh / bin/tick are NOT touched.
    38	lane_attempt_gate() {
    39	  local root="$1" raw="$2" force="${3:-0}"
    40	  [ -n "${LANE_ATTEMPT_COUNTED:-}" ] && return 0
    41	  local key; key=$(printf '%s' "$raw" | tr -c 'A-Za-z0-9._-' '_')
    42	  local max="${LANE_MAX_ATTEMPTS:-2}"
    43	  local dir="$root/.tick/attempts" file count
    44	  file="$dir/$key"
    45	  mkdir -p "$dir" 2>/dev/null || true
    46	  count=0; [ -f "$file" ] && count=$(wc -l < "$file" 2>/dev/null | tr -d ' '); [ -n "$count" ] || count=0
    47	  if [ "$force" = "1" ]; then
    48	    printf 'lane-attempt-cap: --force override — lane %s at %s attempt(s) (cap %s), proceeding.\n' "$key" "$count" "$max" >&2
    49	  elif [ "$count" -ge "$max" ]; then
    50	    printf 'lane-attempt-cap: lane %s PARKED after %s attempt(s) (cap %s) — no relay token seeded.\n' "$key" "$count" "$max" >&2
    51	    printf '  Re-anchor to the committed QUEUE lanes (AGENTS.md) or re-fire with --force. Attempts log: %s\n' "$file" >&2
    52	    return 8
    53	  fi
    54	  printf '%s fire\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || echo fire)" >> "$file"
    55	  return 0
    56	}
    57	
    58	# GH-75: append ONE final-completion record to XYZ.json at the harness repo root when a STANDALONE
    59	# /relay session terminates. Stays SILENT when this relay-drive runs nested inside a marathon/swarm
    60	# phase — marathon-drive.sh sets XYZ_HARNESS_CONTEXT for the nested call (marathon-phase|swarm) and the
    61	# outer harness owns the whole-run record, so a per-phase relay completion must not double-emit.
    62	# Best-effort: a telemetry failure must never change the relay's own exit path.
    63	xyz_relay_emit() {  # <health>
    64	  case "${XYZ_HARNESS_CONTEXT:-relay}" in relay) ;; *) return 0 ;; esac
    65	  [[ -x "$XYZ_APPEND_BIN" ]] || return 0
    66	  local health="$1" slug title s desc
    67	  slug="$(basename "$RELAY_FILE" .md)"
    68	  title="$(grep -m1 '^# ' "$RELAY_FILE" 2>/dev/null | sed 's/^#[[:space:]]*//; s/[[:space:]]*$//')" || true
    69	  [[ -n "$title" ]] || title="$slug"
    70	  s="$(file_status)"
    71	  desc="Relay session ended: STATUS ${s:-unknown} (health ${health})."
    72	  "$XYZ_APPEND_BIN" relay "$slug" "$health" "$title" "$desc" >/dev/null 2>&1 || true
    73	}
    74	
    75	if [[ "${RELAY_DRIVER_LOCKED:-0}" != "1" ]]; then
    76	  # The driver lock lives in .git/ (never committed) for a normal harness clone. A GH-49 vendored
    77	  # .xyz/ copy has no .git/, so mkdir'ing a lock there would fail — fall back to a hidden lock beside
    78	  # the scripts (the .xyz/ dir is itself gitignored in the foreign repo, so it stays uncommitted just
    79	  # the same). When .git/ exists the path is unchanged, so a normal clone behaves byte-identically.
    80	  if [[ -d "$ROOT_DIR/.git" ]]; then
    81	    _lock="$ROOT_DIR/.git/relay-driver.lock"; _lock_label=".git/relay-driver.lock"
    82	  else
    83	    _lock="$ROOT_DIR/.relay-driver.lock";     _lock_label=".relay-driver.lock"
    84	  fi
    85	  if ! mkdir "$_lock" 2>/dev/null; then
    86	    # GH-42 self-heal: reclaim the lock only if its holder is dead. A crashed/killed driver used to
    87	    # leave a stale lock that blocked every later run until a manual rmdir.
    88	    _holder="$(cat "$_lock/pid" 2>/dev/null || true)"
    89	    if [[ -n "$_holder" ]] && kill -0 "$_holder" 2>/dev/null; then
    90	      printf 'relay-drive: another driver is active in this repo (pid %s, lock: %s).\n' "$_holder" "$_lock_label" >&2
    91	      printf 'relay-drive: Concurrent runs in the same clone are unsafe (GH-42 ROOT HEAD hazard).\n' >&2
    92	      exit 1
    93	    fi
    94	    printf 'relay-drive: reclaiming stale relay-driver.lock (holder pid %s not running).\n' "${_holder:-none}" >&2
    95	    rm -rf "$_lock"
    96	    mkdir "$_lock" 2>/dev/null || { printf 'relay-drive: could not acquire relay-driver.lock after reclaiming a stale one.\n' >&2; exit 1; }
    97	  fi
    98	  printf '%s\n' "$$" > "$_lock/pid"
    99	  trap 'rm -rf "$_lock" 2>/dev/null || true' EXIT
   100	  export RELAY_DRIVER_LOCKED=1
   101	fi
   102	
   103	usage() {
   104	  cat <<'EOF'
   105	Usage: relay-automation/relay-drive.sh --relay-file PATH --agent-cmd CMD [options]
   106	
   107	  --relay-file PATH   The relay thread (reads STATUS: as the terminal signal).
   108	  --agent-cmd CMD     Turn-taker; invoked with env RELAY_FILE + RELAY_TASK + RELAY_AGENT.
   109	                      Must take the turn on the RELAY-TURN task (claim/ping/append/
   110	                      release --to <other> | done) and commit.
   111	  --relay-task ID     The relay turn-token task (default: RELAY-TURN).
   112	  --round-cap N       Max turns before escalating (default: 6).
   113	  --target-root DIR   The target git repository root (must be an existing git repo).
   114	  --consult-verify    After each turn, invoke consult.sh to independently challenge the
   115	                      turn-taker's VERDICT. Fires 1-2 real API calls per turn (codex +
   116	                      gemini). Do NOT use in CI or budget-sensitive runs.
   117	  --artifact-file P   Seed an external read-only artifact (a cross-repo PR/diff or any file) into the
   118	                      isolated worktree at .relay-artifacts/<basename> so the reviewer can READ it
   119	                      without it being committed into the target repo. Requires worktree isolation
   120	                      (the default). The reviewer may not edit it (an edit fails the turn). Implements #15.
   121	  --review-once       Drive exactly ONE turn (a single review) and classify its outcome:
   122	                      Approved/Closed -> 0; a completed non-approval handback ("changes
   123	                      requested") -> 5 (NOT the stall's 3); reviewer-did-nothing stall -> 3;
   124	                      Escalated -> 4. Forces --round-cap 1.
   125	  --dry-run           Print the turn it WOULD drive next, then stop (no invocation).
   126	  --help
   127	EOF
   128	}
   129	
   130	die() { printf 'relay-drive: %s\n' "$*" >&2; exit 2; }
   131	
   132	RELAY_FILE=""; AGENT_CMD=""; RELAY_TASK="RELAY-TURN"; ROUND_CAP=6; DRY_RUN=0; CONSULT_VERIFY=0; REVIEW_ONCE=0; ARTIFACT_FILE=""; FORCE=0
   133	while (($# > 0)); do
   134	  case "$1" in
   135	    --relay-file) RELAY_FILE="${2:-}"; shift 2 ;;
   136	    --agent-cmd) AGENT_CMD="${2:-}"; shift 2 ;;
   137	    --relay-task) RELAY_TASK="${2:-}"; shift 2 ;;
   138	    --round-cap) ROUND_CAP="${2:-}"; shift 2 ;;
   139	    --target-root) TARGET_ROOT="${2:-}"; shift 2 ;;
   140	    --consult-verify) CONSULT_VERIFY=1; shift ;;
   141	    --review-once) REVIEW_ONCE=1; shift ;;
   142	    --artifact-file) ARTIFACT_FILE="${2:-}"; shift 2 ;;
   143	    --force) FORCE=1; shift ;;      # GH-45: bypass the per-lane attempt cap for this one fire
   144	    --dry-run) DRY_RUN=1; shift ;;
   145	    --help) usage; exit 0 ;;
   146	    *) die "unknown argument: $1" ;;
   147	  esac
   148	done
   149	[[ -n "$RELAY_FILE" ]] || { usage; die "--relay-file is required"; }
   150	[[ -n "$AGENT_CMD" || "$DRY_RUN" -eq 1 ]] || { usage; die "--agent-cmd is required"; }
   151	
   152	# --review-once drives a single review turn; its success oracle (a completed non-approval handback
   153	# exits 5, not the stall's 3) replaces the multi-round no-progress/cap logic, so force the cap to 1.
   154	((REVIEW_ONCE)) && ROUND_CAP=1
   155	
   156	if [[ -n "${TARGET_ROOT+set}" ]]; then
   157	  [[ -n "$TARGET_ROOT" ]] || die "--target-root requires a non-empty path"   # else git -C '' falls back to CWD
   158	  git -C "$TARGET_ROOT" rev-parse --show-toplevel >/dev/null 2>&1 \
   159	    || die "invalid target root (not a git repo): $TARGET_ROOT"
   160	  export RELAY_TARGET_ROOT="$TARGET_ROOT"
   161	fi
   162	
   163	# Resolve --relay-file AFTER --target-root is known. With --target-root the thread lives in the
   164	# TARGET repo, so a repo-relative path must resolve relative to the target root, not the harness CWD
   165	# (GH-18 #2): if it isn't found as given but exists under --target-root, use that. Absolute paths and
   166	# CWD-relative paths that already resolve are unchanged. (ALLOW_PATHS is already target-relative — the
   167	# shim resolves it against RELAY_TARGET_ROOT in relay-turn-lib.sh.)
   168	if [[ ! -f "$RELAY_FILE" && -n "${TARGET_ROOT:-}" && "$RELAY_FILE" != /* && -f "$TARGET_ROOT/$RELAY_FILE" ]]; then
   169	  RELAY_FILE="$TARGET_ROOT/$RELAY_FILE"
   170	fi
   171	[[ -f "$RELAY_FILE" ]] || die "relay file does not exist: $RELAY_FILE"
   172	
   173	# GH-45: per-lane attempt cap. A real build/review LOOP counts; a single --review-once turn and a
   174	# dry-run do not (they can't rabbit-hole). Keyed on the relay task, stable across re-fires.
   175	if ((DRY_RUN == 0)) && ((REVIEW_ONCE == 0)); then
   176	  # Attempts live with the tick token (its repo), so tests that point TICK_REPO_ROOT at a temp dir
   177	  # stay hermetic; a real standalone run falls back to this clone.
   178	  lane_attempt_gate "${TICK_REPO_ROOT:-$ROOT_DIR}" "$RELAY_TASK" "$FORCE" || exit $?
   179	fi
   180	
   181	# Containment default for unattended/driven runs: isolate the turn-taker in a throwaway worktree
   182	# (ROOT@HEAD) so an off-task model's stray creations/renames can't reach the real tree. The leaf
   183	# shims (codex/agy/claude-turn.sh) read RELAY_WORKTREE_ISOLATION; exporting it here makes every
   184	# DRIVEN turn contained by default. Opt out per run with RELAY_WORKTREE_ISOLATION=0. (Direct/attended
   185	# shim use keeps the leaf default OFF — only the orchestration layer defaults it ON.)
   186	: "${RELAY_WORKTREE_ISOLATION:=1}"; export RELAY_WORKTREE_ISOLATION
   187	
   188	# GH-32 #1: under worktree isolation the turn-taker runs in a throwaway worktree at ROOT@HEAD, so a
   189	# relay file that isn't committed at HEAD is INVISIBLE to it (untracked-not-ignored — relay-system/ is
   190	# tracked here except two specific files). The reviewer then "finds nothing" and silently does no work.
   191	# Warn loudly with the exact remedy; never block (a non-isolated run is free to use an uncommitted file,
   192	# and a relay file outside any git repo is fine too). Mirrors the cross-repo warning style in the shims.
   193	warn_if_relay_file_untracked() {
   194	  [[ "${RELAY_WORKTREE_ISOLATION:-1}" != 0 ]] || return 0
   195	  local dir prefix rel
   196	  dir="$(cd "$(dirname "$RELAY_FILE")" 2>/dev/null && pwd)" || return 0   # not a real dir → skip
   197	  # --show-prefix yields the repo-root-relative path of $dir (empty at root); building the relative
   198	  # path this way avoids subtracting an absolute toplevel, which breaks under macOS /var → /private/var
   199	  # symlinks (logical pwd vs git's physical toplevel).
   200	  prefix="$(git -C "$dir" rev-parse --show-prefix 2>/dev/null)" || return 0  # not in a git repo → skip
   201	  rel="${prefix}$(basename "$RELAY_FILE")"
   202	  git -C "$dir" cat-file -e "HEAD:$rel" 2>/dev/null && return 0           # present at HEAD → visible
   203	  printf 'relay-drive: WARNING — relay file is not committed at HEAD: %s\n' "$rel" >&2
   204	  printf '  RELAY_WORKTREE_ISOLATION=1 runs the turn-taker in a worktree at HEAD, so this untracked\n' >&2
   205	  printf '  file is INVISIBLE to the reviewer (it will find nothing and do no work). Remedy: commit\n' >&2
   206	  printf '  the relay file first, or re-run with RELAY_WORKTREE_ISOLATION=0.\n' >&2
   207	}
   208	warn_if_relay_file_untracked
   209	
   210	# GH-31 / #15: a read-only artifact under review. Absolutize it (the shim runs with a different CWD)
   211	# and export it so relay-turn-lib seeds it into the isolated worktree. It only works under isolation —
   212	# warn loudly if isolation is off, so the reviewer isn't left silently unable to see it.
   213	if [[ -n "$ARTIFACT_FILE" ]]; then
   214	  [[ -f "$ARTIFACT_FILE" ]] || die "artifact file not found: $ARTIFACT_FILE"
   215	  case "$ARTIFACT_FILE" in
   216	    /*) : ;;
   217	    *)  ARTIFACT_FILE="$(cd "$(dirname "$ARTIFACT_FILE")" && pwd)/$(basename "$ARTIFACT_FILE")" ;;
   218	  esac
   219	  export RELAY_ARTIFACT_FILE="$ARTIFACT_FILE"
   220	  [[ "$RELAY_WORKTREE_ISOLATION" != 0 ]] || \
   221	    printf 'relay-drive: WARNING — --artifact-file needs worktree isolation to seed the artifact; with RELAY_WORKTREE_ISOLATION=0 the reviewer will not see it.\n' >&2
   222	fi
   223	
   224	file_status() { sed -n 's/^STATUS:[[:space:]]*//p' "$RELAY_FILE" | head -1 | sed 's/[[:space:]]*$//'; }
   225	terminal_status() { case "$1" in Approved|Closed) return 0 ;; *) return 1 ;; esac; }
   226	# Escalated is TERMINAL BY DESIGN: the reviewer handed back to a human (e.g. at the round cap),
   227	# typically WITHOUT releasing the token. The explicit status IS the intent signal — a true stall
   228	# leaves STATUS unchanged — so this is NOT a no-progress failure. Reported as a clean, distinct
   229	# outcome (exit 4 = terminal/not-approved) so a correct handback doesn't read as a stall (GH-18 #5).
   230	escalated_status() { case "$1" in Escalated) return 0 ;; *) return 1 ;; esac; }
   231	
   232	# Current actor of the RELAY-TURN token: claimer (if claimed) else handoff_to (if
   233	# open) else "" (done/missing). Echoes "<status>\t<actor>".
   234	token_state() {
   235	  local info status claimer handoff actor
   236	  info="$("$TICK_BIN" info "$RELAY_TASK" 2>/dev/null || true)"
   237	  status="$(printf '%s\n' "$info"  | sed -n 's/^status:[[:space:]]*//p'     | head -1)"
   238	  claimer="$(printf '%s\n' "$info" | sed -n 's/^claimer:[[:space:]]*//p'    | head -1)"
   239	  handoff="$(printf '%s\n' "$info" | sed -n 's/^handoff-to:[[:space:]]*//p' | head -1)"
   240	  case "$status" in

exec
/bin/zsh -lc "nl -ba AGENTS.md | sed -n '1,140p'" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-61154-16825
 succeeded in 0ms:
     1	# AGENTS.md
     2	
     3	Read `ROUTER.md` first for startup order and canonical files.
     4	
     5	Read `GUIDING-PRINCIPLES.md` for the product north stars.
     6	
     7	Read `PROJECT/PDDA.md` when the task touches project docs, `ROADMAP.md`, or `CHANGELOG.md`.
     8	
     9	## What this file owns
    10	
    11	This file is the behavioral playbook for work in this repo: decision quality, reversibility, blast
    12	radius, planning shape, and proof.
    13	
    14	Do not restate routing, roadmap, changelog, or active-doc contracts here. Those live in
    15	`ROUTER.md` and `PROJECT/PDDA.md`.
    16	
    17	## Operating principles
    18	
    19	### 1. Lead with the line that survives skimming
    20	
    21	Your first sentence gives the verdict, current state, or call. No setup first.
    22	
    23	### 2. Make the bet explicit before acting
    24	
    25	State the assumption, tradeoff, and failure mode that matter before you commit to a path. If a future
    26	reader could not say "that assumption was wrong," you have not made the real bet legible yet.
    27	
    28	### 3. Use one reversibility scale
    29	
    30	Consequential changes get a read on the shared scale: **Easy / Costly / One-way door**, with one line
    31	of why. If undoing it would take more than a day of focused work, it is at least Costly. Costly
    32	changes need a rollback path. One-way doors need explicit confirmation before proceeding.
    33	
    34	### 4. Size the blast radius before changing shared surfaces
    35	
    36	Before a refactor, schema change, dependency bump, coordination-kernel change, or relay-containment
    37	change, say what ripples, what might break, and who notices. A change you cannot size is not ready.
    38	
    39	### 5. One plan, one ordered list
    40	
    41	When you give executable steps, put them in one numbered list in execution order. Keep verification
    42	inline (`-> expect ...`). Do not scatter action items across prose.
    43	
    44	### 6. Verified beats plausible
    45	
    46	Do not claim success without the relevant test, script, or observable proof. If verification was
    47	skipped or failed, say that plainly and include the result.
    48	
    49	### 7. Record only consequential bets
    50	
    51	If a change is Costly, One-way door, or assumption-heavy, record the bet in `CHANGELOG.md` per
    52	`PROJECT/PDDA.md`. Below that threshold, skip the ritual.
    53	
    54	### 8. Stay quiet on trivial work
    55	
    56	Most edits are small and reversible. Do not manufacture ceremony for a rename, typo fix, or other
    57	local change.
    58	
    59	## Repo-specific rails
    60	
    61	- `ROUTER.md` owns startup order, canonical files, command rails, and the issue-first SOP.
    62	- `GUIDING-PRINCIPLES.md` owns the product/runtime priorities: local event-log coordination,
    63	  containment, skill-first relay work, durable fixes, and verified done.
    64	- `PROJECT/PDDA.md` owns doc lifecycle, `ROADMAP.md` pointer-ledger rules, and `CHANGELOG.md`
    65	  governance.
    66	- `validate.sh` is the code/runtime gate. `utils/pdda/pdda.sh run` and its targeted
    67	  `utils/pdda/pdda.sh <check>` subcommands are the doc-hygiene gates.
    68	- Changes to `.tick/events/`, `src/project.js`, relay containment, or event/verb shape are usually
    69	  broader than they look. Treat them as at least Costly until proven otherwise.
    70	- **Commit to the QUEUE; re-anchor, don't rabbit-hole (GH-45).** A wave's committed lane list *is* the
    71	  active commitment — after each lane attempt, re-read it before acting further. A driven lane that
    72	  fails **parks** after `LANE_MAX_ATTEMPTS` (default 2): the driver (`marathon-drive.sh` /
    73	  `relay-drive.sh`) refuses to re-fire it (exit 8, no token), you capture the findings as an issue and
    74	  stop. Re-firing a parked lane or going off-wave to deep-dive one item requires an explicit operator
    75	  override (`--force`) or a replan note — never a quiet slide off the plan.
    76	
    77	## Conflict order
    78	
    79	1. The current user request
    80	2. The canonical doc that owns the surface you are touching (`ROUTER.md`, `GUIDING-PRINCIPLES.md`,
    81	   `PROJECT/PDDA.md`, or the active `PROJECT/**` doc)
    82	3. This file
    83	4. Skill defaults

exec
/bin/zsh -lc "nl -ba test/lane-attempt-cap.sh | sed -n '1,220p'" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-61154-16825
 succeeded in 0ms:
     1	#!/usr/bin/env bash
     2	# GH-45 — QUEUE commitment contract: per-lane attempt cap (anti-rabbit-hole / WIP discipline).
     3	# Proves the cap logic in relay-drive.sh + marathon-drive.sh: a lane is REFUSED (exit 8, no token)
     4	# once it hits LANE_MAX_ATTEMPTS; --force overrides; a nested (LANE_ATTEMPT_COUNTED) call is a no-op;
     5	# and both drivers carry a byte-consistent mirror + wire the gate at the right seam.
     6	set -u
     7	HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
     8	ROOT="$(cd "$HERE/.." && pwd)"
     9	WORK="$(mktemp -d -t "lane-attempt-cap.XXXXXX")"
    10	trap 'rm -rf "$WORK"' EXIT
    11	
    12	PASS=0; FAIL=0
    13	pass() { echo "  PASS: $*"; PASS=$((PASS+1)); }
    14	fail() { echo "  FAIL: $*" >&2; FAIL=$((FAIL+1)); }
    15	echo "== test: lane-attempt-cap =="
    16	
    17	RELAY_DRIVE="$ROOT/relay-automation/relay-drive.sh"
    18	MARATHON_DRIVE="$ROOT/relay-automation/marathon-drive.sh"
    19	
    20	# ── 1. Both drivers parse + are wired ──────────────────────────────────────
    21	bash -n "$RELAY_DRIVE"     && pass "relay-drive.sh parses"     || fail "relay-drive.sh syntax"
    22	bash -n "$MARATHON_DRIVE"  && pass "marathon-drive.sh parses"  || fail "marathon-drive.sh syntax"
    23	
    24	grep -qE 'lane_attempt_gate .*"\$RELAY_TASK" "\$FORCE"' "$RELAY_DRIVE" \
    25	  && pass "relay-drive.sh calls lane_attempt_gate (keyed on RELAY_TASK)" || fail "relay-drive gate call missing"
    26	grep -qE 'lane_attempt_gate .*"\$PHASE_ID" "\$FORCE"' "$MARATHON_DRIVE" \
    27	  && pass "marathon-drive.sh calls lane_attempt_gate (keyed on PHASE_ID)" || fail "marathon-drive gate call missing"
    28	grep -q 'TICK_REPO_ROOT:-' "$RELAY_DRIVE" \
    29	  && pass "relay-drive.sh keys attempts off TICK_REPO_ROOT (hermetic in tests)" || fail "relay-drive not TICK_REPO_ROOT-anchored"
    30	grep -q 'LANE_ATTEMPT_COUNTED=1' "$MARATHON_DRIVE" \
    31	  && pass "marathon-drive.sh guards the nested relay-drive against double-count" || fail "LANE_ATTEMPT_COUNTED guard missing"
    32	grep -qE 'REVIEW_ONCE == 0' "$RELAY_DRIVE" \
    33	  && pass "relay-drive.sh skips the cap for a single --review-once turn" || fail "review-once cap-skip missing"
    34	
    35	# ── 2. Byte-consistent mirror (the contract requires it) ───────────────────
    36	extract() { sed -n '/^lane_attempt_gate() {/,/^}/p' "$1"; }
    37	extract "$RELAY_DRIVE" > "$WORK/fn-relay.sh"
    38	extract "$MARATHON_DRIVE" > "$WORK/fn-marathon.sh"
    39	[ -s "$WORK/fn-relay.sh" ] && pass "lane_attempt_gate present in relay-drive.sh" || fail "function missing in relay-drive"
    40	if diff -q "$WORK/fn-relay.sh" "$WORK/fn-marathon.sh" >/dev/null; then
    41	  pass "lane_attempt_gate is byte-identical in both drivers"
    42	else
    43	  fail "lane_attempt_gate diverges between the two drivers"
    44	fi
    45	
    46	# ── 3. Behavior — source the real function and exercise it ─────────────────
    47	. "$WORK/fn-relay.sh"
    48	R="$WORK/repo"; mkdir -p "$R/.tick"
    49	
    50	# default cap = 2: two fires pass, the third parks (exit 8)
    51	( LANE_MAX_ATTEMPTS=2; lane_attempt_gate "$R" "LANE-A" 0 ); r1=$?
    52	( LANE_MAX_ATTEMPTS=2; lane_attempt_gate "$R" "LANE-A" 0 ); r2=$?
    53	out="$(LANE_MAX_ATTEMPTS=2 lane_attempt_gate "$R" "LANE-A" 0 2>&1)"; r3=$?
    54	[ "$r1" = 0 ] && [ "$r2" = 0 ] && pass "first two fires proceed (exit 0)" || fail "early fires blocked (r1=$r1 r2=$r2)"
    55	[ "$r3" = 8 ] && pass "third fire PARKED with exit 8 (cap reached)" || fail "cap did not fire (r3=$r3)"
    56	printf '%s' "$out" | grep -q 'PARKED' && pass "park message printed" || fail "no park message: $out"
    57	[ "$(wc -l < "$R/.tick/attempts/LANE-A" | tr -d ' ')" = 2 ] \
    58	  && pass "parked fire seeded NO extra attempt (still 2 recorded)" || fail "parked fire wrongly appended"
    59	
    60	# --force bypasses the cap and logs the override, and DOES count
    61	out="$(LANE_MAX_ATTEMPTS=2 lane_attempt_gate "$R" "LANE-A" 1 2>&1)"; rf=$?
    62	[ "$rf" = 0 ] && pass "--force proceeds past the cap (exit 0)" || fail "--force blocked (rf=$rf)"
    63	printf '%s' "$out" | grep -q 'force override' && pass "--force logs the override" || fail "no override log: $out"
    64	[ "$(wc -l < "$R/.tick/attempts/LANE-A" | tr -d ' ')" = 3 ] \
    65	  && pass "--force fire is recorded (now 3 attempts)" || fail "--force fire not recorded"
    66	
    67	# nested guard: LANE_ATTEMPT_COUNTED makes it a no-op (no refuse, no append)
    68	before=$(wc -l < "$R/.tick/attempts/LANE-A" | tr -d ' ')
    69	( LANE_MAX_ATTEMPTS=2; LANE_ATTEMPT_COUNTED=1; lane_attempt_gate "$R" "LANE-A" 0 ); rn=$?
    70	after=$(wc -l < "$R/.tick/attempts/LANE-A" | tr -d ' ')
    71	[ "$rn" = 0 ] && [ "$before" = "$after" ] \
    72	  && pass "LANE_ATTEMPT_COUNTED short-circuits (no refuse, no double-count)" || fail "nested guard failed (rn=$rn $before->$after)"
    73	
    74	# env-overridable cap + key sanitization (a path-like lane id is flattened)
    75	( LANE_MAX_ATTEMPTS=1; lane_attempt_gate "$R" "PROJECT/1-INBOX/GH-45.md" 0 ); k1=$?
    76	o2="$(LANE_MAX_ATTEMPTS=1 lane_attempt_gate "$R" "PROJECT/1-INBOX/GH-45.md" 0 2>&1)"; k2=$?
    77	[ "$k1" = 0 ] && [ "$k2" = 8 ] && pass "LANE_MAX_ATTEMPTS=1 caps after one fire" || fail "custom cap wrong (k1=$k1 k2=$k2)"
    78	[ -f "$R/.tick/attempts/PROJECT_1-INBOX_GH-45.md" ] \
    79	  && pass "path-like lane id sanitized to a single flat key" || fail "key not sanitized"
    80	
    81	echo "  lane-attempt-cap: $PASS pass, $FAIL fail"
    82	[ "$FAIL" -eq 0 ] || exit 1
    83	exit 0

exec
/bin/zsh -lc "nl -ba relay-automation/marathon-drive.sh | sed -n '1,260p'" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-61154-16825
 succeeded in 0ms:
     1	#!/usr/bin/env bash
     2	set -euo pipefail
     3	#
     4	# marathon-drive.sh — Phase 3: single-phase headless relay loop.
     5	#
     6	# Renders phases/p1/RELAY.md from the phase brief, seeds the tick token (handoff → builder),
     7	# calls relay-drive.sh unmodified, runs the pre-advance gate, emits phase events, and saves
     8	# the transcript. Does NOT reimplement any loop logic — relay-drive.sh IS the loop.
     9	#
    10	# Usage:
    11	#   relay-automation/marathon-drive.sh \
    12	#     --phase-brief <FILE>       phase brief (markdown; baked into the relay template)
    13	#     --reviewer    <AGENT_ID>   reviewer agent (codex* or gemini*)
    14	#     [--builder    <AGENT_ID>]  builder agent (default: claude)
    15	#     [--round-cap  <N>]         relay-drive round cap (default: 5 = 2*2+1)
    16	#     [--pre-advance-cmd <CMD>]  gate before phase.approved (default: bash validate.sh)
    17	#     [--phases-dir <DIR>]       where to create phases/<id>/ (default: <repo-root>/phases)
    18	#     [--phase-id <ID>]          which phase to drive: phases/<id>/ (default: p1; the orchestrator sets it)
    19	#     [--relay-task <ID>]        tick task name (default: MARATHON-<PHASE_ID>-TURN)
    20	#     [--artifact <PATHS>]       comma-separated repo-relative file(s) the builder may create/edit
    21	#                                beyond the relay file (passed to the shims as ALLOW_PATHS). Omit for
    22	#                                a relay-only phase (conversation → approval, no source edit).
    23	#     [--require-clean]          hard-stop if the workspace has pre-existing changes (unattended runs)
    24	#     [--dry-run]                render relay file and print tick seed cmd, then exit
    25	#
    26	# Environment overrides (for tests):
    27	#   MARATHON_ROOT         — git repo root (default: parent of this script's dir)
    28	#   MARATHON_RELAY_DRIVE  — relay-drive.sh path (default: this script's dir/relay-drive.sh)
    29	#   MARATHON_AGENT_CMD    — --agent-cmd value (default: this script's dir/marathon-agent.sh)
    30	#   TICK_BIN              — tick binary (default: <repo-root>/bin/tick)
    31	#
    32	# Exit: 0 phase approved + gate passed · 3 relay no-progress · 4 relay cap/mismatch ·
    33	#        5 pre-advance gate failed · 6 containment violation (turn-taker reverted an off-lane edit) ·
    34	#        2 usage.
    35	
    36	HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    37	ROOT="${MARATHON_ROOT:-"$(cd "$HERE/.." && pwd)"}"
    38	TICK_BIN="${TICK_BIN:-"$ROOT/bin/tick"}"
    39	RELAY_DRIVE_BIN="${MARATHON_RELAY_DRIVE:-"$HERE/relay-drive.sh"}"
    40	AGENT_CMD="${MARATHON_AGENT_CMD:-"$HERE/marathon-agent.sh"}"
    41	
    42	# GH-45 — QUEUE commitment contract: per-lane attempt cap (anti-rabbit-hole / WIP discipline).
    43	# Appends one line per fire to .tick/attempts/<lane> and REFUSES to start a lane at
    44	# >= LANE_MAX_ATTEMPTS (default 2, env-overridable) with exit 8 + a park message, seeding NO relay
    45	# token. --force bypasses for one fire and logs it. A nested call (marathon-drive → relay-drive) is
    46	# guarded by LANE_ATTEMPT_COUNTED so the same lane is counted exactly once. Byte-consistent mirror in
    47	# relay-drive.sh; relay-turn-lib.sh / bin/tick are NOT touched.
    48	lane_attempt_gate() {
    49	  local root="$1" raw="$2" force="${3:-0}"
    50	  [ -n "${LANE_ATTEMPT_COUNTED:-}" ] && return 0
    51	  local key; key=$(printf '%s' "$raw" | tr -c 'A-Za-z0-9._-' '_')
    52	  local max="${LANE_MAX_ATTEMPTS:-2}"
    53	  local dir="$root/.tick/attempts" file count
    54	  file="$dir/$key"
    55	  mkdir -p "$dir" 2>/dev/null || true
    56	  count=0; [ -f "$file" ] && count=$(wc -l < "$file" 2>/dev/null | tr -d ' '); [ -n "$count" ] || count=0
    57	  if [ "$force" = "1" ]; then
    58	    printf 'lane-attempt-cap: --force override — lane %s at %s attempt(s) (cap %s), proceeding.\n' "$key" "$count" "$max" >&2
    59	  elif [ "$count" -ge "$max" ]; then
    60	    printf 'lane-attempt-cap: lane %s PARKED after %s attempt(s) (cap %s) — no relay token seeded.\n' "$key" "$count" "$max" >&2
    61	    printf '  Re-anchor to the committed QUEUE lanes (AGENTS.md) or re-fire with --force. Attempts log: %s\n' "$file" >&2
    62	    return 8
    63	  fi
    64	  printf '%s fire\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || echo fire)" >> "$file"
    65	  return 0
    66	}
    67	
    68	if [[ "${RELAY_DRIVER_LOCKED:-0}" != "1" ]]; then
    69	  # GH-49b: the lock lives in .git/ (never committed) for a normal clone; a vendored .xyz/ copy has no
    70	  # .git/, so fall back to a hidden lock beside the scripts (the .xyz/ dir is itself gitignored in the
    71	  # foreign repo, so it stays uncommitted just the same). Same lock NAME as relay-drive so a marathon
    72	  # and a relay driver still mutually exclude in one clone. Unchanged when .git/ exists.
    73	  if [[ -d "$ROOT/.git" ]]; then
    74	    _lock="$ROOT/.git/relay-driver.lock"; _lock_label=".git/relay-driver.lock"
    75	  else
    76	    _lock="$ROOT/.relay-driver.lock";     _lock_label=".relay-driver.lock"
    77	  fi
    78	  if ! mkdir "$_lock" 2>/dev/null; then
    79	    # GH-42 self-heal: the lock exists — reclaim it only if its holder is dead. A crashed/killed/
    80	    # SIGKILL'd driver used to leave a stale lock that blocked every later run until a manual rmdir.
    81	    _holder="$(cat "$_lock/pid" 2>/dev/null || true)"
    82	    if [[ -n "$_holder" ]] && kill -0 "$_holder" 2>/dev/null; then
    83	      printf 'marathon-drive: another driver is active in this repo (pid %s, lock: %s).\n' "$_holder" "$_lock_label" >&2
    84	      printf 'marathon-drive: Concurrent runs in the same clone are unsafe (GH-42 ROOT HEAD hazard).\n' >&2
    85	      exit 1
    86	    fi
    87	    printf 'marathon-drive: reclaiming stale relay-driver.lock (holder pid %s not running).\n' "${_holder:-none}" >&2
    88	    rm -rf "$_lock"
    89	    mkdir "$_lock" 2>/dev/null || { printf 'marathon-drive: could not acquire relay-driver.lock after reclaiming a stale one.\n' >&2; exit 1; }
    90	    # ponytail: tiny TOCTOU window (two drivers could both reclaim a stale lock); acceptable for a
    91	    # single-operator clone — add an atomic PID-CAS only if true multi-operator concurrency appears.
    92	  fi
    93	  printf '%s\n' "$$" > "$_lock/pid"
    94	  trap 'rm -rf "$_lock" 2>/dev/null || true' EXIT
    95	  export RELAY_DRIVER_LOCKED=1
    96	fi
    97	
    98	die()  { printf 'marathon-drive: %s\n' "$*" >&2; exit 2; }
    99	log()  { printf 'marathon-drive: %s\n' "$*"; }
   100	
   101	XYZ_APPEND_BIN="${XYZ_APPEND_BIN:-"$ROOT/utils/telemetry/append-xyz-completion.sh"}"
   102	
   103	# GH-75: append ONE final-completion record for a run whose WHOLE completion IS this single-phase
   104	# marathon-drive — i.e. a bare `marathon-drive.sh` run (harness:"marathon") or a swarm-preflight-
   105	# originated run (harness:"swarm", tagged via XYZ_HARNESS_CONTEXT=swarm baked into the generated
   106	# invocation). Stays SILENT when marathon.sh drives us per-phase (XYZ_HARNESS_CONTEXT=marathon-phase):
   107	# marathon.sh emits the single whole-run record itself. Health is binary green/red (halt-on-first-
   108	# failure has no distinct "escalated mid-chain" state). Best-effort — never changes marathon-drive's
   109	# own exit code.
   110	xyz_marathon_emit() {  # <health> <description>
   111	  local ctx="${XYZ_HARNESS_CONTEXT:-}"
   112	  [[ "$ctx" == "marathon-phase" ]] && return 0
   113	  [[ -x "$XYZ_APPEND_BIN" ]] || return 0
   114	  local health="$1" desc="$2" harness title sid
   115	  case "$ctx" in swarm) harness="swarm" ;; *) harness="marathon" ;; esac
   116	  title="$(basename "$PHASE_BRIEF_FILE" .md 2>/dev/null)"; [[ -n "$title" ]] || title="$PHASE_ID"
   117	  # sessionId: PHASE_ID defaults to "p1", which is a constant across every swarm/bare run — useless for
   118	  # telling one run from another. Let the invoker override it (swarm-preflight bakes the per-run slug
   119	  # into its generated command via XYZ_SESSION_ID); fall back to PHASE_ID otherwise (GH-75 review).
   120	  sid="${XYZ_SESSION_ID:-$PHASE_ID}"
   121	  "$XYZ_APPEND_BIN" "$harness" "$sid" "$health" "$title" "$desc" >/dev/null 2>&1 || true
   122	}
   123	
   124	usage() {
   125	  cat <<'EOF'
   126	Usage: relay-automation/marathon-drive.sh --phase-brief FILE --reviewer AGENT [options]
   127	
   128	  --phase-brief FILE      Phase brief markdown baked into the relay template (required).
   129	  --reviewer AGENT        Reviewer agent id; must start with 'codex' or 'gemini' (required).
   130	  --builder AGENT         Builder agent id (default: claude).
   131	  --round-cap N           relay-drive turn cap (default: 5).
   132	  --pre-advance-cmd CMD   Gate before phase.approved (default: bash validate.sh).
   133	  --phases-dir DIR        Where to create phases/<id>/ (default: <repo-root>/phases).
   134	  --phase-id ID           Which phase to drive: phases/<id>/ (default: p1).
   135	  --relay-task ID         Tick task name (default: MARATHON-<PHASE_ID>-TURN).
   136	  --artifact PATHS        Comma-separated repo-relative file(s) the builder may create/edit beyond
   137	                          the relay file (ALLOW_PATHS for the turn-takers). Omit for a relay-only phase.
   138	  --target-root DIR       Foreign git repo the BUILD lands in (GH-11). The relay thread + tick token
   139	                          stay in this repo; forwarded to relay-drive.sh, and the pre-advance gate runs
   140	                          with cwd = DIR. Omit for a same-repo phase.
   141	  --require-clean         Hard-stop (exit 2) if the workspace has pre-existing changes before seeding.
   142	  --dry-run               Render the relay file and print the tick seed; exit without running.
   143	EOF
   144	}
   145	
   146	PHASE_BRIEF_FILE=""
   147	BUILDER="claude"
   148	REVIEWER=""
   149	ROUND_CAP=5
   150	PRE_ADVANCE_CMD=""   # resolved to default after ROOT is set
   151	PHASES_DIR=""        # resolved to default after ROOT is set
   152	PHASE_ID="p1"        # which phase this invocation drives (phases/<id>/); the orchestrator sets it
   153	RELAY_TASK=""        # resolved to MARATHON-<PHASE_ID>-TURN after parsing, unless given
   154	ARTIFACT_PATHS=""    # comma-separated repo-relative file(s) the builder may create/edit (beyond RELAY.md)
   155	REQUIRE_CLEAN=0      # --require-clean: hard-stop if the workspace has pre-existing changes
   156	FORCE=0              # --force: bypass the GH-45 per-lane attempt cap for this one fire
   157	DRY_RUN=0
   158	TARGET_ROOT=""       # --target-root: foreign repo the BUILD lands in (GH-11). Relay thread stays in ROOT;
   159	                     # forwarded to relay-drive.sh (which exports RELAY_TARGET_ROOT for artifact routing).
   160	
   161	while (($# > 0)); do
   162	  case "$1" in
   163	    --phase-brief)     PHASE_BRIEF_FILE="${2:-}"; shift 2 ;;
   164	    --builder)         BUILDER="${2:-}"; shift 2 ;;
   165	    --reviewer)        REVIEWER="${2:-}"; shift 2 ;;
   166	    --round-cap)       ROUND_CAP="${2:-}"; shift 2 ;;
   167	    --pre-advance-cmd) PRE_ADVANCE_CMD="${2:-}"; shift 2 ;;
   168	    --phases-dir)      PHASES_DIR="${2:-}"; shift 2 ;;
   169	    --phase-id)        PHASE_ID="${2:-}"; shift 2 ;;
   170	    --relay-task)      RELAY_TASK="${2:-}"; shift 2 ;;
   171	    --artifact)        ARTIFACT_PATHS="${2:-}"; shift 2 ;;
   172	    --target-root)     TARGET_ROOT="${2:-}"; shift 2 ;;
   173	    --require-clean)   REQUIRE_CLEAN=1; shift ;;
   174	    --force)           FORCE=1; shift ;;
   175	    --dry-run)         DRY_RUN=1; shift ;;
   176	    --help)            usage; exit 0 ;;
   177	    *)                 die "unknown argument: $1" ;;
   178	  esac
   179	done
   180	
   181	[[ -n "$PHASE_BRIEF_FILE" ]] || { usage; die "--phase-brief FILE required"; }
   182	[[ -f "$PHASE_BRIEF_FILE" ]] || die "phase brief not found: $PHASE_BRIEF_FILE"
   183	[[ -n "$REVIEWER"         ]] || { usage; die "--reviewer AGENT required"; }
   184	[[ -n "$BUILDER"          ]] || die "--builder cannot be empty"
   185	[[ -n "$PHASE_ID"         ]] || die "--phase-id cannot be empty"
   186	if [[ -n "$TARGET_ROOT" ]]; then
   187	  git -C "$TARGET_ROOT" rev-parse --show-toplevel >/dev/null 2>&1 \
   188	    || die "invalid --target-root (not a git repo): $TARGET_ROOT"
   189	fi
   190	
   191	PHASES_DIR="${PHASES_DIR:-"$ROOT/phases"}"
   192	PRE_ADVANCE_CMD="${PRE_ADVANCE_CMD:-"bash $ROOT/validate.sh"}"
   193	# Default the tick token name off the phase id (p1 → MARATHON-P1-TURN), keeping the Phase-3 default.
   194	RELAY_TASK="${RELAY_TASK:-"MARATHON-$(printf '%s' "$PHASE_ID" | tr '[:lower:]' '[:upper:]')-TURN"}"
   195	
   196	# Map builder/reviewer to _AGENT env vars for marathon-agent.sh routing. Both actors are routed to
   197	# their shim by name prefix (claude/codex/agy/gemini), so the harness supports cross-model BUILDERS
   198	# (e.g. agy) — not just Claude. Builder defaults to claude for back-compat.
   199	export MARATHON_BUILDER="$BUILDER"
   200	export MARATHON_REVIEWER="$REVIEWER"
   201	export CLAUDE_AGENT="" CODEX_AGENT="" AGY_AGENT="" GEMINI_AGENT=""
   202	route_agent() {  # <agent-id> → export the matching *_AGENT var marathon-agent.sh routes on
   203	  case "$1" in
   204	    claude*) export CLAUDE_AGENT="$1" ;;
   205	    codex*)  export CODEX_AGENT="$1" ;;
   206	    agy*)    export AGY_AGENT="$1" ;;
   207	    gemini*) export GEMINI_AGENT="$1" ;;
   208	    *)       die "agent '$1' not recognized — must start with claude/codex/agy/gemini" ;;
   209	  esac
   210	}
   211	[[ "$BUILDER" == "$REVIEWER" ]] && die "builder and reviewer must be different agent ids (got '$BUILDER' for both)"
   212	route_agent "$BUILDER"
   213	route_agent "$REVIEWER"
   214	# Reviewer must be a QA-capable model lane (codex/gemini/agy), never the Claude builder lane.
   215	case "$REVIEWER" in codex*|gemini*|agy*) ;; *) die "reviewer '$REVIEWER' must start with codex/gemini/agy" ;; esac
   216	
   217	# Artifact allowlist: when a phase targets real file(s), pass them as ALLOW_PATHS so the turn-takers
   218	# may create/edit them. The shared safety core (relay-turn-lib.sh) reverts ANY edit outside this
   219	# allowlist + the always-allowed relay file — so containment still holds; the builder just gains a
   220	# real write surface. Without --artifact, ALLOW_PATHS stays unset and the phase is relay-only.
   221	if [[ -n "$ARTIFACT_PATHS" ]]; then
   222	  export ALLOW_PATHS="$ARTIFACT_PATHS"
   223	else
   224	  unset ALLOW_PATHS
   225	fi
   226	
   227	PHASE_DIR="$PHASES_DIR/$PHASE_ID"
   228	RELAY_FILE="$PHASE_DIR/RELAY.md"
   229	REL_RELAY="${RELAY_FILE#"$ROOT"/}"   # repo-root-relative path the agent edits / declares in claim --paths
   230	
   231	# ── Step 0: clean-workspace check (Phase 3.6) ──────────────────────────────
   232	# Stray pre-existing files distract an autonomous builder — a 2026-06-17 dogfood builder was pulled
   233	# off-task by unrelated AUDIT/*.md briefs left in the tree. Surface them before seeding. Exclude the
   234	# marathon's own paths (phases/, .tick/). --require-clean turns the warning into a hard stop for
   235	# unattended runs (DRY_RUN skips it — nothing is committed).
   236	if ((! DRY_RUN)); then
   237	  dirty="$(git -C "$ROOT" status --porcelain 2>/dev/null \
   238	    | awk '{ p=substr($0,4); if (p !~ /^phases\// && p !~ /^\.tick\//) print p }')"
   239	  if [[ -n "$dirty" ]]; then
   240	    log "WARNING: workspace is not clean — an autonomous builder can be distracted by stray files."
   241	    while IFS= read -r p; do [[ -n "$p" ]] && log "  • $p"; done <<< "$dirty"
   242	    ((REQUIRE_CLEAN)) && die "--require-clean set and the workspace has pre-existing changes (above)"
   243	  fi
   244	fi
   245	
   246	# ── Step 1: render phases/p1/RELAY.md ──────────────────────────────────────
   247	
   248	mkdir -p "$PHASE_DIR"
   249	BRIEF_TEXT="$(cat "$PHASE_BRIEF_FILE")"
   250	
   251	# Bake the ABSOLUTE tick path into the relay. A headless turn's cwd is not guaranteed to be the
   252	# repo root, so a relative "./bin/tick" is a guess — a real builder turn (2026-06-17) looked for it
   253	# in the phase dir, logged "tick not present", and skipped the token handoff entirely (phase then
   254	# escalated no-progress). An absolute path the agent can run from anywhere removes that failure mode.
   255	TICK_CLI="$TICK_BIN"
   256	case "$TICK_CLI" in /*) ;; *) TICK_CLI="$ROOT/$TICK_CLI" ;; esac
   257	
   258	# Builder/reviewer instruction text + the tick claim --paths depend on whether this phase targets
   259	# real artifact file(s) (--artifact) or is relay-only. Built here so the heredoc stays a flat template.
   260	if [[ -n "$ARTIFACT_PATHS" ]]; then

codex
I have the changed lines pinned. One unresolved area is the caller contract around exit `8`, so I’m checking `marathon.sh` and the nested invocation path now rather than assuming the new exit is harmless.
exec
/bin/zsh -lc "nl -ba relay-automation/marathon-drive.sh | sed -n '260,520p'" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-61154-16825
 succeeded in 0ms:
   260	if [[ -n "$ARTIFACT_PATHS" ]]; then
   261	  CLAIM_PATHS="${REL_RELAY},${ARTIFACT_PATHS}"
   262	  BUILDER_IMPL_LINE="Implement the brief by creating/editing the artifact file(s): ${ARTIFACT_PATHS}"
   263	  BUILDER_SCOPE_LINE="Edit ONLY these paths: ${REL_RELAY} and ${ARTIFACT_PATHS}. Do NOT run git. Do NOT touch any other file — the harness commits for you."
   264	  REVIEWER_READ_LINE="Read the latest builder block above AND review the artifact file(s) on disk: ${ARTIFACT_PATHS}."
   265	  REVIEWER_SCOPE_LINE="Edit ONLY ${REL_RELAY} (your review block + STATUS). Do NOT edit the artifact yourself — request changes instead. Do NOT run git."
   266	else
   267	  CLAIM_PATHS="${REL_RELAY}"
   268	  BUILDER_IMPL_LINE="Record your work directly in this relay file (relay-only phase — no source file to edit)."
   269	  BUILDER_SCOPE_LINE="Edit ONLY ${REL_RELAY}. Do NOT run git. Do NOT touch any other file — the harness commits for you."
   270	  REVIEWER_READ_LINE="Read the latest builder block above."
   271	  REVIEWER_SCOPE_LINE="Do NOT run git. Do NOT touch any other file."
   272	fi
   273	
   274	cat > "$RELAY_FILE" << RELAY_EOF
   275	# Marathon Phase ${PHASE_ID}
   276	STATUS: Open
   277	NEXT: ${BUILDER}
   278	
   279	<!-- marathon-drive: task=${RELAY_TASK} builder=${BUILDER} reviewer=${REVIEWER} round-cap=${ROUND_CAP} -->
   280	
   281	## Phase Brief
   282	
   283	${BRIEF_TEXT}
   284	
   285	---
   286	
   287	▶ TAKE YOUR TURN (${BUILDER} — BUILDER role)
   288	
   289	You are the BUILDER for this phase. Read the phase brief above and implement it.
   290	1. ${BUILDER_IMPL_LINE}
   291	2. Append a build block to this relay file: \`### Round N · Builder · ${BUILDER}\` summarizing what you did (files touched, key decisions).
   292	3. Use this exact tick binary (run it from any directory): ${TICK_CLI}
   293	   - ${TICK_CLI} claim ${RELAY_TASK} --agent ${BUILDER} --paths "${CLAIM_PATHS}"
   294	   - ${TICK_CLI} ping ${RELAY_TASK} --agent ${BUILDER}
   295	   - ${TICK_CLI} release ${RELAY_TASK} --agent ${BUILDER} --to ${REVIEWER}
   296	4. ${BUILDER_SCOPE_LINE}
   297	
   298	---
   299	
   300	▶ TAKE YOUR TURN (${REVIEWER} — REVIEWER role)
   301	
   302	You are the REVIEWER for this phase. ${REVIEWER_READ_LINE}
   303	1. Append a review block: \`### Round N · Reviewer · ${REVIEWER}\` followed by your assessment.
   304	2. If changes needed: add \`**Verdict:** Changes requested\` then: ${TICK_CLI} release ${RELAY_TASK} --agent ${REVIEWER} --to ${BUILDER}
   305	3. If satisfied: add \`**Verdict:** Approved\`, set \`STATUS: Approved\`, then: ${TICK_CLI} done ${RELAY_TASK} --agent ${REVIEWER}
   306	4. Use this exact tick binary (run it from any directory) for all token operations: ${TICK_CLI}
   307	   ${REVIEWER_SCOPE_LINE}
   308	RELAY_EOF
   309	
   310	if ((DRY_RUN)); then
   311	  log "dry-run: relay file rendered at $RELAY_FILE"
   312	  printf 'tick seed: log task.created %s + claim --agent marathon + release --to %s\n' "$RELAY_TASK" "$BUILDER"
   313	  exit 0
   314	fi
   315	
   316	# ── Step 2: commit the relay file (rtl_before needs a clean HEAD) ───────────
   317	
   318	git -C "$ROOT" add -- "$RELAY_FILE"
   319	git -C "$ROOT" commit -q -m "marathon: render phase ${PHASE_ID} relay (${RELAY_TASK})"
   320	log "relay file committed: $RELAY_FILE"
   321	
   322	# ── Step 3: seed tick token with handoff → builder ──────────────────────────
   323	
   324	export TICK_REPO_ROOT="$ROOT"
   325	
   326	reconcile_relay_task() {
   327	  local info status handoff claimer
   328	  if ! info="$("$TICK_BIN" info "$RELAY_TASK" 2>/dev/null)"; then
   329	    return 0  # no prior task state to reconcile
   330	  fi
   331	
   332	  status="$(printf '%s\n' "$info" | sed -n 's/^status:[[:space:]]*//p' | head -n1)"
   333	  handoff="$(printf '%s\n' "$info" | sed -n 's/^handoff-to:[[:space:]]*//p' | head -n1)"
   334	  claimer="$(printf '%s\n' "$info" | sed -n 's/^claimer:[[:space:]]*//p' | head -n1)"
   335	
   336	  case "$status" in
   337	    claimed)
   338	      die "relay task $RELAY_TASK already has a live claim by ${claimer:-unknown}; refusing to reap a live claim"
   339	      ;;
   340	    open)
   341	      [[ -n "$handoff" ]] || return 0
   342	      case "$handoff" in
   343	        "$BUILDER"|"$REVIEWER")
   344	          # GH-56: a rerun can inherit an OPEN handoff from the previous pass. Clear only that stale
   345	          # reservation by consuming it as its routed target, then releasing it unreserved. Never reap a
   346	          # live claim here; parked claims are the watchdog's authority path.
   347	          "$TICK_BIN" claim "$RELAY_TASK" --agent "$handoff" --paths "$REL_RELAY" > /dev/null
   348	          "$TICK_BIN" release "$RELAY_TASK" --agent "$handoff" > /dev/null
   349	          log "reconciled leaked open handoff: $RELAY_TASK (cleared stale reservation for $handoff)"
   350	          ;;
   351	        *)
   352	          die "relay task $RELAY_TASK is open but reserved for unexpected agent '$handoff'"
   353	          ;;
   354	      esac
   355	      ;;
   356	  esac
   357	}
   358	
   359	# GH-45: per-lane attempt cap — refuse to start this phase once it has hit LANE_MAX_ATTEMPTS
   360	# (keyed on PHASE_ID, stable across re-fires), seeding no token; --force overrides. Counted here, so
   361	# the nested relay-drive below (LANE_ATTEMPT_COUNTED=1) does not double-count this same lane.
   362	lane_attempt_gate "${TICK_REPO_ROOT:-$ROOT}" "$PHASE_ID" "$FORCE" || exit $?
   363	
   364	reconcile_relay_task
   365	
   366	"$TICK_BIN" log task.created "$RELAY_TASK" --agent marathon > /dev/null
   367	"$TICK_BIN" claim           "$RELAY_TASK" --agent marathon --paths "$REL_RELAY" > /dev/null
   368	"$TICK_BIN" release         "$RELAY_TASK" --agent marathon --to "$BUILDER" > /dev/null
   369	log "tick token seeded: $RELAY_TASK → $BUILDER"
   370	
   371	# ── Step 4: emit phase.start ────────────────────────────────────────────────
   372	
   373	"$TICK_BIN" log marathon.phase.start "$RELAY_TASK" --agent marathon > /dev/null
   374	log "phase start: running relay-drive --round-cap $ROUND_CAP"
   375	
   376	# ── Step 5: run relay-drive (the loop — unmodified) ────────────────────────
   377	
   378	# relay-drive runs a bare executable --agent-cmd path directly (space-safe, even ".../GH Repos/..."),
   379	# falling back to eval only for command strings — so we pass the path as-is, no %q quoting needed.
   380	relay_exit=0
   381	target_root_args=()
   382	[[ -n "$TARGET_ROOT" ]] && target_root_args=(--target-root "$TARGET_ROOT")
   383	# GH-75: the nested relay loop reaches its own terminal exit once PER PHASE. Force its XYZ.json hook
   384	# silent (XYZ_HARNESS_CONTEXT=marathon-phase) so a per-phase relay completion never emits its own
   385	# record — this marathon-drive run (or marathon.sh above it) owns the single whole-run record. This is
   386	# scoped to the relay-drive child only; marathon-drive's OWN context (swarm|unset) is left intact for
   387	# its hook below.
   388	RELAY_FILE="$RELAY_FILE" \
   389	LANE_ATTEMPT_COUNTED=1 \
   390	XYZ_HARNESS_CONTEXT=marathon-phase \
   391	  "$RELAY_DRIVE_BIN" \
   392	    --relay-file "$RELAY_FILE" \
   393	    --relay-task "$RELAY_TASK" \
   394	    --agent-cmd  "$AGENT_CMD" \
   395	    --round-cap  "$ROUND_CAP" \
   396	    ${target_root_args[@]+"${target_root_args[@]}"} \
   397	  || relay_exit=$?
   398	
   399	# ── Step 6: act on relay-drive exit code ───────────────────────────────────
   400	
   401	escalate() {  # <reason> <relay-exit>
   402	  local reason="$1" rexit="$2"
   403	  cat > "$PHASE_DIR/ESCALATION.md" << ESC_EOF
   404	# ESCALATION — Marathon Phase ${PHASE_ID}
   405	
   406	phase: ${PHASE_ID}
   407	task: ${RELAY_TASK}
   408	relay-drive-exit: ${rexit}
   409	reason: ${reason}
   410	relay-file: ${REL_RELAY}
   411	ESC_EOF
   412	  git -C "$ROOT" add -- "$PHASE_DIR/ESCALATION.md"
   413	  git -C "$ROOT" commit -q -m "marathon: phase ${PHASE_ID} escalation (${reason})"
   414	  "$TICK_BIN" log marathon.phase.escalated "$RELAY_TASK" --agent marathon > /dev/null || true
   415	  log "escalation written: $PHASE_DIR/ESCALATION.md (reason: $reason)"
   416	}
   417	
   418	save_transcript() {
   419	  local date_dir; date_dir="$ROOT/relay-system/$(date +%Y-%m-%d)"
   420	  mkdir -p "$date_dir"
   421	  local ts; ts="$(date +%H%M%S)"
   422	  local dest="$date_dir/marathon-${PHASE_ID}-${ts}.md"
   423	  cp "$RELAY_FILE" "$dest"
   424	  git -C "$ROOT" add -- "$dest"
   425	  git -C "$ROOT" commit -q -m "marathon: phase ${PHASE_ID} transcript saved (${RELAY_TASK})"
   426	  log "transcript saved: $dest"
   427	}
   428	
   429	case "$relay_exit" in
   430	  0)
   431	    # relay closed Approved. Run the pre-advance gate before emitting phase.approved.
   432	    log "relay approved — running pre-advance gate: $PRE_ADVANCE_CMD"
   433	    gate_exit=0
   434	    # Gate belongs to the target repo when --target-root is set (e.g. a foreign repo's `npm test`).
   435	    ( [[ -n "$TARGET_ROOT" ]] && cd "$TARGET_ROOT"; eval "$PRE_ADVANCE_CMD" ) || gate_exit=$?
   436	    if [[ "$gate_exit" -ne 0 ]]; then
   437	      log "pre-advance gate FAILED (exit $gate_exit) — escalating"
   438	      escalate "pre-advance-failed" "$relay_exit"
   439	      xyz_marathon_emit red "halted at phase ${PHASE_ID} — pre-advance gate failed"
   440	      exit 5
   441	    fi
   442	    "$TICK_BIN" log marathon.phase.approved "$RELAY_TASK" --agent marathon > /dev/null || true
   443	    save_transcript
   444	    log "phase ${PHASE_ID} complete — STATUS: Approved, gate passed"
   445	    xyz_marathon_emit green "phase ${PHASE_ID} complete — STATUS: Approved, gate passed"
   446	    exit 0
   447	    ;;
   448	  3)
   449	    log "relay escalated: no-progress (relay-drive exit 3)"
   450	    escalate "no-progress" 3
   451	    xyz_marathon_emit red "halted at phase ${PHASE_ID} — relay no-progress"
   452	    exit 3
   453	    ;;
   454	  4)
   455	    log "relay escalated: cap/close-mismatch (relay-drive exit 4)"
   456	    escalate "cap-or-close-mismatch" 4
   457	    xyz_marathon_emit red "halted at phase ${PHASE_ID} — relay cap/close-mismatch"
   458	    exit 4
   459	    ;;
   460	  6)
   461	    # A turn-taker shim hit an off-lane edit, reverted it, and failed the turn (exit 6) — the
   462	    # containment boundary fired. This is a DEFINED escalation, not an "unexpected" crash: the
   463	    # builder strayed but the safety core held. Record it like any other escalation. (Dogfood
   464	    # 2026-06-17: an autonomous builder edited an off-lane file; rtl_enforce caught + reverted it.)
   465	    log "relay escalated: containment violation — a turn-taker reverted an off-lane edit (exit 6)"
   466	    escalate "containment-violation (off-lane edit reverted by a turn-taker)" 6
   467	    xyz_marathon_emit red "halted at phase ${PHASE_ID} — containment violation (off-lane edit reverted)"
   468	    exit 6
   469	    ;;
   470	  *)
   471	    die "relay-drive exited with unexpected code $relay_exit"
   472	    ;;
   473	esac

exec
/bin/zsh -lc "nl -ba relay-automation/marathon.sh | sed -n '1,260p'" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-61154-16825
 succeeded in 0ms:
     1	#!/usr/bin/env bash
     2	set -euo pipefail
     3	#
     4	# marathon.sh — Phase 4 (M5): multi-phase orchestrator. Reads MARATHON.yaml, resolves depends_on
     5	# order, and runs each phase through marathon-drive.sh (the unmodified single-phase loop). Advances
     6	# on phase approval; HALTS on the first phase failure (relay no-progress / cap / gate / containment),
     7	# leaving that phase's ESCALATION.md (written by marathon-drive) and NOT starting later phases.
     8	# Emits marathon.complete only when every phase is approved.
     9	#
    10	# Per-phase round cap = 2 * max_review_rounds + 1 (turns ≠ rounds; the off-by-one kills phases early).
    11	# Cross-phase context injection (M6) and MARATHON-STATE.md projection (M7) are deliberately deferred —
    12	# the boundary events already land in .tick/events/ (phase.start/approved/escalated, marathon.complete).
    13	#
    14	# Usage:
    15	#   relay-automation/marathon.sh --plan MARATHON.yaml [--builder claude] [--phases-dir DIR]
    16	#                                [--pre-advance-cmd CMD] [--dry-run]
    17	#
    18	# The MARATHON.yaml phase fields drive each marathon-drive call: id→--phase-id, reviewer→--reviewer,
    19	# brief→--phase-brief (required to run), artifact→--artifact, max_review_rounds→--round-cap.
    20	#
    21	# Environment overrides (for tests):
    22	#   MARATHON_ROOT       — repo root (default: parent of this script's dir)
    23	#   MARATHON_DRIVE      — marathon-drive.sh path (default: this script's dir/marathon-drive.sh)
    24	#   MARATHON_YAML_BIN   — bin/marathon-yaml path (default: <repo-root>/bin/marathon-yaml)
    25	#   TICK_BIN            — tick binary (default: <repo-root>/bin/tick)
    26	# Real runs also inherit the turn-taker env (CLAUDE_BIN, *_TURN_ROOT, …), passed straight through.
    27	#
    28	# Exit: 0 all phases approved · N the failing phase's marathon-drive exit code · 2 usage/parse error.
    29	
    30	HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    31	ROOT="${MARATHON_ROOT:-"$(cd "$HERE/.." && pwd)"}"
    32	TICK_BIN="${TICK_BIN:-"$ROOT/bin/tick"}"
    33	DRIVE_BIN="${MARATHON_DRIVE:-"$HERE/marathon-drive.sh"}"
    34	YAML_BIN="${MARATHON_YAML_BIN:-"$ROOT/bin/marathon-yaml"}"
    35	
    36	die() { printf 'marathon: %s\n' "$*" >&2; exit 2; }
    37	log() { printf 'marathon: %s\n' "$*"; }
    38	
    39	XYZ_APPEND_BIN="${XYZ_APPEND_BIN:-"$ROOT/utils/telemetry/append-xyz-completion.sh"}"
    40	
    41	# GH-75: the ONE whole-run completion record for a marathon.sh-orchestrated run. Each per-phase
    42	# marathon-drive runs with XYZ_HARNESS_CONTEXT=marathon-phase (its own hook silent), so this is the
    43	# only place a marathon.sh run is recorded — on BOTH the success tail AND the halt path, so a failed
    44	# run isn't silently absent from XYZ.json (GH-75 review: an early halt used to skip the tail entirely,
    45	# emitting nothing — worse than a bare marathon-drive halt, which does emit red). Best-effort.
    46	xyz_marathon_run_emit() {  # <health> <description>
    47	  [[ -x "$XYZ_APPEND_BIN" ]] || return 0
    48	  local plan; plan="$(basename "$PLAN")"; plan="${plan%.*}"; [[ -n "$plan" ]] || plan="marathon"
    49	  "$XYZ_APPEND_BIN" marathon "$plan" "$1" "$plan" "$2" >/dev/null 2>&1 || true
    50	}
    51	
    52	PLAN=""; BUILDER="claude"; PHASES_DIR=""; PRE_ADVANCE_CMD=""; DRY_RUN=0
    53	while (($# > 0)); do
    54	  case "$1" in
    55	    --plan)            PLAN="${2:-}"; shift 2 ;;
    56	    --builder)         BUILDER="${2:-}"; shift 2 ;;
    57	    --phases-dir)      PHASES_DIR="${2:-}"; shift 2 ;;
    58	    --pre-advance-cmd) PRE_ADVANCE_CMD="${2:-}"; shift 2 ;;
    59	    --dry-run)         DRY_RUN=1; shift ;;
    60	    --help)            printf 'Usage: marathon.sh --plan MARATHON.yaml [--builder A] [--phases-dir D] [--pre-advance-cmd C] [--dry-run]\n'; exit 0 ;;
    61	    *)                 die "unknown argument: $1" ;;
    62	  esac
    63	done
    64	[[ -n "$PLAN" ]] || { die "--plan MARATHON.yaml required"; }
    65	[[ -f "$PLAN" ]] || die "plan not found: $PLAN"
    66	PHASES_DIR="${PHASES_DIR:-"$ROOT/phases"}"
    67	export TICK_REPO_ROOT="$ROOT"
    68	
    69	# Parse + validate + resolve order. A malformed/cyclic plan halts the whole run here (exit 2).
    70	PLAN_TSV="$("$YAML_BIN" "$PLAN")" || die "plan parse failed (see above)"
    71	[[ -n "$PLAN_TSV" ]] || die "plan has no phases"
    72	phase_count="$(printf '%s\n' "$PLAN_TSV" | grep -c .)"
    73	log "plan: $PLAN — $phase_count phase(s) in execution order"
    74	
    75	idx=0
    76	# Read TSV with a NON-whitespace field separator (US / \037): `IFS=$'\t' read` coalesces consecutive
    77	# tabs (tab is whitespace-class), which would collapse empty columns and shift every field. Translate
    78	# tabs → \037 so empty fields (no rounds / no depends_on / no artifact) are preserved positionally.
    79	while IFS=$'\037' read -r id reviewer rounds depends_on brief artifact name; do
    80	  [[ -n "$id" ]] || continue
    81	  idx=$((idx + 1))
    82	  rounds="${rounds:-2}"
    83	  cap=$((2 * rounds + 1))
    84	  [[ -n "$brief" ]] || die "phase $id: no 'brief:' in the plan — a phase needs a task to run"
    85	  case "$brief" in /*) brief_path="$brief" ;; *) brief_path="$ROOT/$brief" ;; esac
    86	  [[ -f "$brief_path" ]] || die "phase $id: brief file not found: $brief_path"
    87	
    88	  log "── phase $idx/$phase_count: $id (reviewer=$reviewer, round-cap=$cap${artifact:+, artifact=$artifact}) ──"
    89	
    90	  drive_args=( --phase-id "$id" --reviewer "$reviewer" --builder "$BUILDER"
    91	               --phase-brief "$brief_path" --round-cap "$cap" --phases-dir "$PHASES_DIR" )
    92	  [[ -n "$artifact" ]] && drive_args+=( --artifact "$artifact" )
    93	  [[ -n "$PRE_ADVANCE_CMD" ]] && drive_args+=( --pre-advance-cmd "$PRE_ADVANCE_CMD" )
    94	  if ((DRY_RUN)); then drive_args+=( --dry-run ); fi
    95	
    96	  phase_exit=0
    97	  # GH-75: mark each per-phase marathon-drive call so its (and its nested relay-drive's) XYZ.json hook
    98	  # stays silent — this orchestrator emits a SINGLE harness:"marathon" whole-run record below, never
    99	  # one per phase.
   100	  MARATHON_ROOT="$ROOT" TICK_BIN="$TICK_BIN" XYZ_HARNESS_CONTEXT=marathon-phase \
   101	    bash "$DRIVE_BIN" "${drive_args[@]}" || phase_exit=$?
   102	  if [[ "$phase_exit" -ne 0 ]]; then
   103	    log "HALT: phase $id failed (marathon-drive exit $phase_exit) — chain stops; later phases NOT started"
   104	    case "$phase_exit" in
   105	      3) _halt_reason="relay no-progress" ;;
   106	      4) _halt_reason="relay cap/close-mismatch" ;;
   107	      5) _halt_reason="pre-advance gate failed" ;;
   108	      6) _halt_reason="containment violation" ;;
   109	      *) _halt_reason="marathon-drive exit $phase_exit" ;;
   110	    esac
   111	    xyz_marathon_run_emit red "halted at phase $idx of $phase_count ($id) — $_halt_reason"
   112	    exit "$phase_exit"
   113	  fi
   114	done < <(printf '%s\n' "$PLAN_TSV" | tr '\t' '\037')
   115	
   116	if ((DRY_RUN)); then
   117	  log "dry-run complete: $phase_count phase(s) would run in order"
   118	  exit 0
   119	fi
   120	"$TICK_BIN" log marathon.complete "MARATHON-RUN" --agent marathon > /dev/null 2>&1 || true
   121	
   122	# GH-75: the whole-run success record (title/sessionId = plan name, "N of M phase(s) approved").
   123	xyz_marathon_run_emit green "$phase_count of $phase_count phase(s) approved"
   124	
   125	log "marathon complete — all $phase_count phase(s) approved"
   126	exit 0

exec
/bin/zsh -lc "rg -n \"exit 8|return 8|case .*8|\\b8\\)\" relay-automation test bin -g '"'!node_modules'"'" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-61154-16825
 succeeded in 0ms:
bin/tick:234:          return 8;
bin/tick:259:          return 8;
bin/validate-relay-block:20:  exit 8
bin/validate-relay-block:26:  exit 8
bin/validate-relay-block:32:  exit 8
bin/validate-relay-block:38:  exit 8
bin/validate-relay-block:46:  exit 8
bin/validate-relay-block:52:  exit 8
bin/validate-relay-block:58:  exit 8
test/poll-driver.sh:135:[ "$_dc" -ge 1 ] && [ "$_dc" -le 8 ] && pass "emit-delay: delay clamped to time-remaining before deadline ($_dc<=8)" || fail "expected clamp to <=8, got $_dc"
relay-automation/relay-drive.sh:34:# >= LANE_MAX_ATTEMPTS (default 2, env-overridable) with exit 8 + a park message, seeding NO relay
relay-automation/relay-drive.sh:52:    return 8
relay-automation/marathon-drive.sh:44:# >= LANE_MAX_ATTEMPTS (default 2, env-overridable) with exit 8 + a park message, seeding NO relay
relay-automation/marathon-drive.sh:62:    return 8
test/relay-loop.sh:91:# (8) background: a finished turn leaves a stale pidfile; the next tick clears it and acts
test/marathon-drive.sh:177:# ── (8) relay no-progress (exit 3) → ESCALATION.md, driver exits 3 ───────
test/agy-turn.sh:114:# --- (8) pre-existing dirty file is NOT reverted; turn still succeeds (MBP16 [1], shared core) ---
test/lane-attempt-cap.sh:3:# Proves the cap logic in relay-drive.sh + marathon-drive.sh: a lane is REFUSED (exit 8, no token)
test/lane-attempt-cap.sh:50:# default cap = 2: two fires pass, the third parks (exit 8)
test/lane-attempt-cap.sh:55:[ "$r3" = 8 ] && pass "third fire PARKED with exit 8 (cap reached)" || fail "cap did not fire (r3=$r3)"
test/cost.sh:97:# --- (8) PHASE 2: analyzer computes the cost section ----------------------
test/codex-turn.sh:156:# --- (8) .tick exemption independent of host .gitignore (MBP16 [2]) — LAST: mutates fixture .gitignore ---
test/path-integrity.sh:66:# exist in this tree — the real shim is lowercase — so this can never mask a real path break). See #80.
relay-automation/hooks/xyz-vendor-reminder.sh:18:#     surfaces the fact + the exact xyz-sync remedy; the operator decides (GUIDING #8).
test/claude-turn.sh:147:# --- (8) rename-hijack: staged rename (off-lane) is enforced ---------------
test/marathon-yaml.sh:84:# --- (8) json format emits the marathon name ------------------------------

exec
/bin/zsh -lc 'rg -n "LANE_ATTEMPT_COUNTED|lane_attempt_gate|--force|review-once|dry-run|TICK_REPO_ROOT|.tick/attempts" relay-automation/marathon-drive.sh relay-automation/relay-drive.sh relay-automation/marathon.sh test/lane-attempt-cap.sh AGENTS.md' in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-61154-16825
 succeeded in 0ms:
AGENTS.md:75:  override (`--force`) or a replan note — never a quiet slide off the plan.
test/lane-attempt-cap.sh:4:# once it hits LANE_MAX_ATTEMPTS; --force overrides; a nested (LANE_ATTEMPT_COUNTED) call is a no-op;
test/lane-attempt-cap.sh:24:grep -qE 'lane_attempt_gate .*"\$RELAY_TASK" "\$FORCE"' "$RELAY_DRIVE" \
test/lane-attempt-cap.sh:25:  && pass "relay-drive.sh calls lane_attempt_gate (keyed on RELAY_TASK)" || fail "relay-drive gate call missing"
test/lane-attempt-cap.sh:26:grep -qE 'lane_attempt_gate .*"\$PHASE_ID" "\$FORCE"' "$MARATHON_DRIVE" \
test/lane-attempt-cap.sh:27:  && pass "marathon-drive.sh calls lane_attempt_gate (keyed on PHASE_ID)" || fail "marathon-drive gate call missing"
test/lane-attempt-cap.sh:28:grep -q 'TICK_REPO_ROOT:-' "$RELAY_DRIVE" \
test/lane-attempt-cap.sh:29:  && pass "relay-drive.sh keys attempts off TICK_REPO_ROOT (hermetic in tests)" || fail "relay-drive not TICK_REPO_ROOT-anchored"
test/lane-attempt-cap.sh:30:grep -q 'LANE_ATTEMPT_COUNTED=1' "$MARATHON_DRIVE" \
test/lane-attempt-cap.sh:31:  && pass "marathon-drive.sh guards the nested relay-drive against double-count" || fail "LANE_ATTEMPT_COUNTED guard missing"
test/lane-attempt-cap.sh:33:  && pass "relay-drive.sh skips the cap for a single --review-once turn" || fail "review-once cap-skip missing"
test/lane-attempt-cap.sh:36:extract() { sed -n '/^lane_attempt_gate() {/,/^}/p' "$1"; }
test/lane-attempt-cap.sh:39:[ -s "$WORK/fn-relay.sh" ] && pass "lane_attempt_gate present in relay-drive.sh" || fail "function missing in relay-drive"
test/lane-attempt-cap.sh:41:  pass "lane_attempt_gate is byte-identical in both drivers"
test/lane-attempt-cap.sh:43:  fail "lane_attempt_gate diverges between the two drivers"
test/lane-attempt-cap.sh:51:( LANE_MAX_ATTEMPTS=2; lane_attempt_gate "$R" "LANE-A" 0 ); r1=$?
test/lane-attempt-cap.sh:52:( LANE_MAX_ATTEMPTS=2; lane_attempt_gate "$R" "LANE-A" 0 ); r2=$?
test/lane-attempt-cap.sh:53:out="$(LANE_MAX_ATTEMPTS=2 lane_attempt_gate "$R" "LANE-A" 0 2>&1)"; r3=$?
test/lane-attempt-cap.sh:57:[ "$(wc -l < "$R/.tick/attempts/LANE-A" | tr -d ' ')" = 2 ] \
test/lane-attempt-cap.sh:60:# --force bypasses the cap and logs the override, and DOES count
test/lane-attempt-cap.sh:61:out="$(LANE_MAX_ATTEMPTS=2 lane_attempt_gate "$R" "LANE-A" 1 2>&1)"; rf=$?
test/lane-attempt-cap.sh:62:[ "$rf" = 0 ] && pass "--force proceeds past the cap (exit 0)" || fail "--force blocked (rf=$rf)"
test/lane-attempt-cap.sh:63:printf '%s' "$out" | grep -q 'force override' && pass "--force logs the override" || fail "no override log: $out"
test/lane-attempt-cap.sh:64:[ "$(wc -l < "$R/.tick/attempts/LANE-A" | tr -d ' ')" = 3 ] \
test/lane-attempt-cap.sh:65:  && pass "--force fire is recorded (now 3 attempts)" || fail "--force fire not recorded"
test/lane-attempt-cap.sh:67:# nested guard: LANE_ATTEMPT_COUNTED makes it a no-op (no refuse, no append)
test/lane-attempt-cap.sh:68:before=$(wc -l < "$R/.tick/attempts/LANE-A" | tr -d ' ')
test/lane-attempt-cap.sh:69:( LANE_MAX_ATTEMPTS=2; LANE_ATTEMPT_COUNTED=1; lane_attempt_gate "$R" "LANE-A" 0 ); rn=$?
test/lane-attempt-cap.sh:70:after=$(wc -l < "$R/.tick/attempts/LANE-A" | tr -d ' ')
test/lane-attempt-cap.sh:72:  && pass "LANE_ATTEMPT_COUNTED short-circuits (no refuse, no double-count)" || fail "nested guard failed (rn=$rn $before->$after)"
test/lane-attempt-cap.sh:75:( LANE_MAX_ATTEMPTS=1; lane_attempt_gate "$R" "PROJECT/1-INBOX/GH-45.md" 0 ); k1=$?
test/lane-attempt-cap.sh:76:o2="$(LANE_MAX_ATTEMPTS=1 lane_attempt_gate "$R" "PROJECT/1-INBOX/GH-45.md" 0 2>&1)"; k2=$?
test/lane-attempt-cap.sh:78:[ -f "$R/.tick/attempts/PROJECT_1-INBOX_GH-45.md" ] \
relay-automation/marathon.sh:16:#                                [--pre-advance-cmd CMD] [--dry-run]
relay-automation/marathon.sh:59:    --dry-run)         DRY_RUN=1; shift ;;
relay-automation/marathon.sh:60:    --help)            printf 'Usage: marathon.sh --plan MARATHON.yaml [--builder A] [--phases-dir D] [--pre-advance-cmd C] [--dry-run]\n'; exit 0 ;;
relay-automation/marathon.sh:67:export TICK_REPO_ROOT="$ROOT"
relay-automation/marathon.sh:94:  if ((DRY_RUN)); then drive_args+=( --dry-run ); fi
relay-automation/marathon.sh:117:  log "dry-run complete: $phase_count phase(s) would run in order"
relay-automation/relay-drive.sh:24:#       escalated-to-human-by-design (STATUS: Escalated) · 5 = review-once: reviewer completed a turn
relay-automation/relay-drive.sh:33:# Appends one line per fire to .tick/attempts/<lane> and REFUSES to start a lane at
relay-automation/relay-drive.sh:35:# token. --force bypasses for one fire and logs it. A nested call (marathon-drive → relay-drive) is
relay-automation/relay-drive.sh:36:# guarded by LANE_ATTEMPT_COUNTED so the same lane is counted exactly once. Byte-consistent mirror in
relay-automation/relay-drive.sh:38:lane_attempt_gate() {
relay-automation/relay-drive.sh:40:  [ -n "${LANE_ATTEMPT_COUNTED:-}" ] && return 0
relay-automation/relay-drive.sh:43:  local dir="$root/.tick/attempts" file count
relay-automation/relay-drive.sh:48:    printf 'lane-attempt-cap: --force override — lane %s at %s attempt(s) (cap %s), proceeding.\n' "$key" "$count" "$max" >&2
relay-automation/relay-drive.sh:51:    printf '  Re-anchor to the committed QUEUE lanes (AGENTS.md) or re-fire with --force. Attempts log: %s\n' "$file" >&2
relay-automation/relay-drive.sh:121:  --review-once       Drive exactly ONE turn (a single review) and classify its outcome:
relay-automation/relay-drive.sh:125:  --dry-run           Print the turn it WOULD drive next, then stop (no invocation).
relay-automation/relay-drive.sh:141:    --review-once) REVIEW_ONCE=1; shift ;;
relay-automation/relay-drive.sh:143:    --force) FORCE=1; shift ;;      # GH-45: bypass the per-lane attempt cap for this one fire
relay-automation/relay-drive.sh:144:    --dry-run) DRY_RUN=1; shift ;;
relay-automation/relay-drive.sh:152:# --review-once drives a single review turn; its success oracle (a completed non-approval handback
relay-automation/relay-drive.sh:173:# GH-45: per-lane attempt cap. A real build/review LOOP counts; a single --review-once turn and a
relay-automation/relay-drive.sh:174:# dry-run do not (they can't rabbit-hole). Keyed on the relay task, stable across re-fires.
relay-automation/relay-drive.sh:176:  # Attempts live with the tick token (its repo), so tests that point TICK_REPO_ROOT at a temp dir
relay-automation/relay-drive.sh:178:  lane_attempt_gate "${TICK_REPO_ROOT:-$ROOT_DIR}" "$RELAY_TASK" "$FORCE" || exit $?
relay-automation/relay-drive.sh:358:  # --review-once: the single review turn is complete. Classify with a review oracle so a correct
relay-automation/relay-drive.sh:362:    # --review-once bypasses the loop's normal terminal/cap exits, so it needs its own XYZ.json emits
relay-automation/relay-drive.sh:366:      printf 'relay-drive: review-once — reviewer approved/closed (STATUS: %s) after 1 turn\n' "$ns"
relay-automation/relay-drive.sh:371:      printf 'relay-drive: review-once — reviewer completed a turn (STATUS: %s, token %s:%s); non-approval handback, not a stall\n' "$ns" "$ntstatus" "$nactor"
relay-automation/relay-drive.sh:375:    printf 'relay-drive: review-once — reviewer took no action (STATUS unchanged: %s, token still %s) — genuine stall\n' "$ns" "$prev" >&2
relay-automation/marathon-drive.sh:24:#     [--dry-run]                render relay file and print tick seed cmd, then exit
relay-automation/marathon-drive.sh:43:# Appends one line per fire to .tick/attempts/<lane> and REFUSES to start a lane at
relay-automation/marathon-drive.sh:45:# token. --force bypasses for one fire and logs it. A nested call (marathon-drive → relay-drive) is
relay-automation/marathon-drive.sh:46:# guarded by LANE_ATTEMPT_COUNTED so the same lane is counted exactly once. Byte-consistent mirror in
relay-automation/marathon-drive.sh:48:lane_attempt_gate() {
relay-automation/marathon-drive.sh:50:  [ -n "${LANE_ATTEMPT_COUNTED:-}" ] && return 0
relay-automation/marathon-drive.sh:53:  local dir="$root/.tick/attempts" file count
relay-automation/marathon-drive.sh:58:    printf 'lane-attempt-cap: --force override — lane %s at %s attempt(s) (cap %s), proceeding.\n' "$key" "$count" "$max" >&2
relay-automation/marathon-drive.sh:61:    printf '  Re-anchor to the committed QUEUE lanes (AGENTS.md) or re-fire with --force. Attempts log: %s\n' "$file" >&2
relay-automation/marathon-drive.sh:142:  --dry-run               Render the relay file and print the tick seed; exit without running.
relay-automation/marathon-drive.sh:156:FORCE=0              # --force: bypass the GH-45 per-lane attempt cap for this one fire
relay-automation/marathon-drive.sh:174:    --force)           FORCE=1; shift ;;
relay-automation/marathon-drive.sh:175:    --dry-run)         DRY_RUN=1; shift ;;
relay-automation/marathon-drive.sh:311:  log "dry-run: relay file rendered at $RELAY_FILE"
relay-automation/marathon-drive.sh:324:export TICK_REPO_ROOT="$ROOT"
relay-automation/marathon-drive.sh:360:# (keyed on PHASE_ID, stable across re-fires), seeding no token; --force overrides. Counted here, so
relay-automation/marathon-drive.sh:361:# the nested relay-drive below (LANE_ATTEMPT_COUNTED=1) does not double-count this same lane.
relay-automation/marathon-drive.sh:362:lane_attempt_gate "${TICK_REPO_ROOT:-$ROOT}" "$PHASE_ID" "$FORCE" || exit $?
relay-automation/marathon-drive.sh:389:LANE_ATTEMPT_COUNTED=1 \

codex
One subtlety I’m checking now is whether the new state can wedge a lane forever: the code intentionally has no reset path, so the question is whether that’s a policy decision the caller can live with or an operational bug.
exec
/bin/zsh -lc "nl -ba relay-automation/relay-drive.sh | sed -n '320,410p'" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-61154-16825
 succeeded in 0ms:
   320	    while IFS= read -r _cv_line; do
   321	      _cv_path="$(printf '%s\n' "$_cv_line" | sed -n 's/.*-> //p' | sed 's/[[:space:]]*$//')"
   322	      [[ -z "$_cv_path" || ! -f "$_cv_path" ]] && continue
   323	      _cv_model="$(printf '%s\n' "$_cv_line" | sed -n 's/.*\[ok\][[:space:]]*//p' | sed 's/[[:space:]]*->.*$//' | sed 's/[[:space:]]*$//')"
   324	      _cv_response="$(grep -oE '(AGREE-PASS|AGREE-FAIL|DISAGREE)' "$_cv_path" | head -1 || true)"
   325	      [[ -z "$_cv_response" ]] && _cv_response="(no verdict found)"
   326	      _cv_advisor_summary+="${_cv_model:-advisor}: $_cv_response"$'\n'
   327	      [[ "$_cv_response" == "DISAGREE" ]] && _cv_diverged=1
   328	    done < <(printf '%s\n' "$_cv_consult_out")
   329	
   330	    if ((_cv_diverged)); then
   331	      printf 'relay-drive: consult-verify DIVERGENCE after %s turn (taker: %s)\n%s' \
   332	        "$actor" "$_cv_taker_verdict" "$_cv_advisor_summary" >&2
   333	      # Append conflict-warning advisory block (MUST include VERDICT: + Basis: for bin/validate-relay-block)
   334	      printf '\n### consult-verify advisory — divergence detected (round %d)\n\nVERDICT: FAIL\nBasis: consult disagreed with turn-taker verdict "%s" (see transcripts)\n%s\nTurn-taker self-reported: %s\n' \
   335	        "$round" "$_cv_taker_verdict" "$_cv_advisor_summary" "$_cv_taker_verdict" >> "$RELAY_FILE"
   336	      # Set STATUS: Escalated
   337	      sed -i '' 's/^STATUS:[[:space:]]*.*/STATUS: Escalated/' "$RELAY_FILE"
   338	      _cv_relay_repo="$(git -C "$(dirname "$RELAY_FILE")" rev-parse --show-toplevel 2>/dev/null || echo "$ROOT_DIR")"
   339	      git -C "$_cv_relay_repo" add "$RELAY_FILE" 2>/dev/null || true
   340	      git -C "$_cv_relay_repo" commit -m "relay-drive: consult-verify divergence escalation (round $round)" 2>/dev/null || true
   341	      printf 'relay-drive: relay escalated by consult-verify (STATUS: Escalated) after %d turn(s)\n' "$round" >&2
   342	      exit 4
   343	    else
   344	      printf 'relay-drive: consult-verify AGREED after %s turn (taker: %s)\n' "$actor" "$_cv_taker_verdict" >&2
   345	    fi
   346	  fi
   347	
   348	  # No-progress guard (skipped once terminal — the close check at loop top handles that).
   349	  IFS=$'\t' read -r ntstatus nactor < <(token_state)
   350	  ns="$(file_status)"
   351	  # A by-design Escalated handback this turn is terminal, NOT a stall — even if the reviewer left the
   352	  # token live. Catch it before the no-progress guard so it doesn't read as exit 3 (GH-18 #5).
   353	  if escalated_status "$ns"; then
   354	    printf 'relay-drive: relay escalated to human by design (STATUS: %s, token %s:%s) after %d turn(s)\n' "$ns" "$ntstatus" "$nactor" "$round" >&2
   355	    xyz_relay_emit orange
   356	    exit 4
   357	  fi
   358	  # --review-once: the single review turn is complete. Classify with a review oracle so a correct
   359	  # "changes requested" handback is NOT conflated with a no-progress stall (GH-32 #2). Mirrors the
   360	  # Escalated carve-out above — a reviewer that actually DID something is a success, not exit 3.
   361	  if ((REVIEW_ONCE)); then
   362	    # --review-once bypasses the loop's normal terminal/cap exits, so it needs its own XYZ.json emits
   363	    # (approval → green, a completed changes-requested handback → orange, a genuine stall → red) — else
   364	    # this repo's own recommended one-shot review flow would never record a completion (GH-75 review).
   365	    if terminal_status "$ns"; then
   366	      printf 'relay-drive: review-once — reviewer approved/closed (STATUS: %s) after 1 turn\n' "$ns"
   367	      xyz_relay_emit green
   368	      exit 0
   369	    fi
   370	    if [[ "$ntstatus:$nactor" != "$prev" || "$ns" != "$s" ]]; then
   371	      printf 'relay-drive: review-once — reviewer completed a turn (STATUS: %s, token %s:%s); non-approval handback, not a stall\n' "$ns" "$ntstatus" "$nactor"
   372	      xyz_relay_emit orange
   373	      exit 5
   374	    fi
   375	    printf 'relay-drive: review-once — reviewer took no action (STATUS unchanged: %s, token still %s) — genuine stall\n' "$ns" "$prev" >&2
   376	    xyz_relay_emit red
   377	    exit 3
   378	  fi
   379	
   380	  if ! terminal_status "$ns" && [[ "$ntstatus:$nactor" == "$prev" ]]; then
   381	    printf 'relay-drive: no progress after %s turn (token still %s) — escalating\n' "$actor" "$prev" >&2
   382	    xyz_relay_emit red
   383	    exit 3
   384	  fi
   385	done
   386	
   387	# Cap reached: success only if file terminal AND token not live (same agreement).
   388	s="$(file_status)"; IFS=$'\t' read -r tstatus actor < <(token_state)
   389	if terminal_status "$s" && [[ -z "$actor" ]]; then
   390	  printf 'relay-drive: relay terminated (STATUS: %s)\n' "$s"; xyz_relay_emit green; exit 0
   391	fi
   392	printf 'relay-drive: round cap (%d) exceeded (STATUS: %s, token actor: %s) — escalating\n' "$ROUND_CAP" "$s" "${actor:-none}" >&2
   393	xyz_relay_emit red
   394	exit 4

exec
/bin/zsh -lc 'rg -n "LANE_ATTEMPT_COUNTED" -S .' in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-61154-16825
 succeeded in 0ms:
./relay-automation/relay-drive.sh:36:# guarded by LANE_ATTEMPT_COUNTED so the same lane is counted exactly once. Byte-consistent mirror in
./relay-automation/relay-drive.sh:40:  [ -n "${LANE_ATTEMPT_COUNTED:-}" ] && return 0
./relay-automation/marathon-drive.sh:46:# guarded by LANE_ATTEMPT_COUNTED so the same lane is counted exactly once. Byte-consistent mirror in
./relay-automation/marathon-drive.sh:50:  [ -n "${LANE_ATTEMPT_COUNTED:-}" ] && return 0
./relay-automation/marathon-drive.sh:361:# the nested relay-drive below (LANE_ATTEMPT_COUNTED=1) does not double-count this same lane.
./relay-automation/marathon-drive.sh:389:LANE_ATTEMPT_COUNTED=1 \
./test/lane-attempt-cap.sh:4:# once it hits LANE_MAX_ATTEMPTS; --force overrides; a nested (LANE_ATTEMPT_COUNTED) call is a no-op;
./test/lane-attempt-cap.sh:30:grep -q 'LANE_ATTEMPT_COUNTED=1' "$MARATHON_DRIVE" \
./test/lane-attempt-cap.sh:31:  && pass "marathon-drive.sh guards the nested relay-drive against double-count" || fail "LANE_ATTEMPT_COUNTED guard missing"
./test/lane-attempt-cap.sh:67:# nested guard: LANE_ATTEMPT_COUNTED makes it a no-op (no refuse, no append)
./test/lane-attempt-cap.sh:69:( LANE_MAX_ATTEMPTS=2; LANE_ATTEMPT_COUNTED=1; lane_attempt_gate "$R" "LANE-A" 0 ); rn=$?
./test/lane-attempt-cap.sh:72:  && pass "LANE_ATTEMPT_COUNTED short-circuits (no refuse, no double-count)" || fail "nested guard failed (rn=$rn $before->$after)"

exec
/bin/zsh -lc "nl -ba bin/tick | sed -n '220,270p'" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-61154-16825
 succeeded in 0ms:
   220	      scope(root, { task, agent: flags.agent, paths: parsePathsFlag(flags.paths) });
   221	      process.stdout.write(`scoped: ${task}\n`);
   222	      return 0;
   223	    }
   224	
   225	    case 'release': {
   226	      const [task] = positional;
   227	      if (!task || !flags.agent) { usage(); return 2; }
   228	      if (flags['relay-file']) {
   229	        const validateScript = path.resolve(__dirname, 'validate-relay-block');
   230	        try {
   231	          execFileSync(validateScript, [flags['relay-file']], { stdio: 'inherit' });
   232	        } catch (err) {
   233	          process.stderr.write(`tick: validation failed for ${flags['relay-file']}\n`);
   234	          return 8;
   235	        }
   236	      }
   237	      release(root, { task, agent: flags.agent, to_agent: typeof flags.to === 'string' ? flags.to : undefined });
   238	      process.stdout.write(`released: ${task}\n`);
   239	      return 0;
   240	    }
   241	
   242	    case 'break': {
   243	      const [task] = positional;
   244	      if (!task || !flags.agent) { usage(); return 2; }
   245	      circuitBreak(root, { task, agent: flags.agent, reason: typeof flags.reason === 'string' ? flags.reason : '' });
   246	      process.stdout.write(`broken: ${task}\n`);
   247	      return 0;
   248	    }
   249	
   250	    case 'done': {
   251	      const [task] = positional;
   252	      if (!task || !flags.agent) { usage(); return 2; }
   253	      if (flags['relay-file']) {
   254	        const validateScript = path.resolve(__dirname, 'validate-relay-block');
   255	        try {
   256	          execFileSync(validateScript, [flags['relay-file']], { stdio: 'inherit' });
   257	        } catch (err) {
   258	          process.stderr.write(`tick: validation failed for ${flags['relay-file']}\n`);
   259	          return 8;
   260	        }
   261	      }
   262	      done(root, { task, agent: flags.agent, note: typeof flags.note === 'string' ? flags.note : undefined });
   263	      process.stdout.write(`done: ${task}\n`);
   264	      return 0;
   265	    }
   266	
   267	    case 'drift': {
   268	      // GH-68 warn-only cross-agent dependency-drift signal. Emits a dependency.drift event when a
   269	      // landed relay turn changed a shared surface, so the next agent's shim can inject a heads-up.
   270	      // Purely informational — best-effort like `cost`/`log`, deliberately NOT in MUTATING_GUARD_VERBS

exec
/bin/zsh -lc 'rg -n "task.created .*RELAY_TASK|claim .*RELAY_TASK|release .*RELAY_TASK|done .*RELAY_TASK|log task.created|TICK_REPO_ROOT" relay-automation/marathon-drive.sh relay-automation/relay-drive.sh relay-automation/marathon.sh' in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-61154-16825
 succeeded in 0ms:
relay-automation/marathon.sh:67:export TICK_REPO_ROOT="$ROOT"
relay-automation/relay-drive.sh:176:  # Attempts live with the tick token (its repo), so tests that point TICK_REPO_ROOT at a temp dir
relay-automation/relay-drive.sh:178:  lane_attempt_gate "${TICK_REPO_ROOT:-$ROOT_DIR}" "$RELAY_TASK" "$FORCE" || exit $?
relay-automation/marathon-drive.sh:293:   - ${TICK_CLI} claim ${RELAY_TASK} --agent ${BUILDER} --paths "${CLAIM_PATHS}"
relay-automation/marathon-drive.sh:295:   - ${TICK_CLI} release ${RELAY_TASK} --agent ${BUILDER} --to ${REVIEWER}
relay-automation/marathon-drive.sh:304:2. If changes needed: add \`**Verdict:** Changes requested\` then: ${TICK_CLI} release ${RELAY_TASK} --agent ${REVIEWER} --to ${BUILDER}
relay-automation/marathon-drive.sh:305:3. If satisfied: add \`**Verdict:** Approved\`, set \`STATUS: Approved\`, then: ${TICK_CLI} done ${RELAY_TASK} --agent ${REVIEWER}
relay-automation/marathon-drive.sh:312:  printf 'tick seed: log task.created %s + claim --agent marathon + release --to %s\n' "$RELAY_TASK" "$BUILDER"
relay-automation/marathon-drive.sh:324:export TICK_REPO_ROOT="$ROOT"
relay-automation/marathon-drive.sh:347:          "$TICK_BIN" claim "$RELAY_TASK" --agent "$handoff" --paths "$REL_RELAY" > /dev/null
relay-automation/marathon-drive.sh:348:          "$TICK_BIN" release "$RELAY_TASK" --agent "$handoff" > /dev/null
relay-automation/marathon-drive.sh:362:lane_attempt_gate "${TICK_REPO_ROOT:-$ROOT}" "$PHASE_ID" "$FORCE" || exit $?
relay-automation/marathon-drive.sh:366:"$TICK_BIN" log task.created "$RELAY_TASK" --agent marathon > /dev/null
relay-automation/marathon-drive.sh:367:"$TICK_BIN" claim           "$RELAY_TASK" --agent marathon --paths "$REL_RELAY" > /dev/null
relay-automation/marathon-drive.sh:368:"$TICK_BIN" release         "$RELAY_TASK" --agent marathon --to "$BUILDER" > /dev/null

codex
I’ve confirmed the new exit `8` already exists in `bin/tick`, so the question is not “is 8 unique?” but “does the caller preserve its meaning well enough.” I’m doing one pass on runnable proof next, with the expectation that sandbox limits may prevent the temp-file parts from executing.
exec
/bin/zsh -lc 'rg -n "--force" relay-automation/marathon-drive.sh relay-automation/relay-drive.sh relay-automation/marathon.sh' in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-61154-16825
 exited 2 in 0ms:
rg: unrecognized flag --force

exec
/bin/zsh -lc 'bash -n relay-automation/relay-drive.sh && bash -n relay-automation/marathon-drive.sh && bash -n relay-automation/marathon.sh' in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-61154-16825
 succeeded in 0ms:
exec
/bin/zsh -lc "git diff --unified=5 main...HEAD -- relay-automation/marathon-drive.sh | sed -n '1,220p'" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-61154-16825
 succeeded in 2638ms:
2026-07-02 18:37:15.729 xcodebuild[65728:22670187]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-07-02 18:37:16.004 xcodebuild[65728:22670186] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.
git: warning: confstr() failed with code 5: couldn't get path of DARWIN_USER_TEMP_DIR; using /tmp instead
git: error: couldn't create cache file '/tmp/xcrun_db-RsQfkPHf' (errno=Operation not permitted)
2026-07-02 18:37:16.660 xcodebuild[65840:22670447]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-07-02 18:37:16.870 xcodebuild[65840:22670438] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.
diff --git a/relay-automation/marathon-drive.sh b/relay-automation/marathon-drive.sh
index 8fcef81..131f5e1 100755
--- a/relay-automation/marathon-drive.sh
+++ b/relay-automation/marathon-drive.sh
@@ -37,10 +37,36 @@ HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
 ROOT="${MARATHON_ROOT:-"$(cd "$HERE/.." && pwd)"}"
 TICK_BIN="${TICK_BIN:-"$ROOT/bin/tick"}"
 RELAY_DRIVE_BIN="${MARATHON_RELAY_DRIVE:-"$HERE/relay-drive.sh"}"
 AGENT_CMD="${MARATHON_AGENT_CMD:-"$HERE/marathon-agent.sh"}"
 
+# GH-45 — QUEUE commitment contract: per-lane attempt cap (anti-rabbit-hole / WIP discipline).
+# Appends one line per fire to .tick/attempts/<lane> and REFUSES to start a lane at
+# >= LANE_MAX_ATTEMPTS (default 2, env-overridable) with exit 8 + a park message, seeding NO relay
+# token. --force bypasses for one fire and logs it. A nested call (marathon-drive → relay-drive) is
+# guarded by LANE_ATTEMPT_COUNTED so the same lane is counted exactly once. Byte-consistent mirror in
+# relay-drive.sh; relay-turn-lib.sh / bin/tick are NOT touched.
+lane_attempt_gate() {
+  local root="$1" raw="$2" force="${3:-0}"
+  [ -n "${LANE_ATTEMPT_COUNTED:-}" ] && return 0
+  local key; key=$(printf '%s' "$raw" | tr -c 'A-Za-z0-9._-' '_')
+  local max="${LANE_MAX_ATTEMPTS:-2}"
+  local dir="$root/.tick/attempts" file count
+  file="$dir/$key"
+  mkdir -p "$dir" 2>/dev/null || true
+  count=0; [ -f "$file" ] && count=$(wc -l < "$file" 2>/dev/null | tr -d ' '); [ -n "$count" ] || count=0
+  if [ "$force" = "1" ]; then
+    printf 'lane-attempt-cap: --force override — lane %s at %s attempt(s) (cap %s), proceeding.\n' "$key" "$count" "$max" >&2
+  elif [ "$count" -ge "$max" ]; then
+    printf 'lane-attempt-cap: lane %s PARKED after %s attempt(s) (cap %s) — no relay token seeded.\n' "$key" "$count" "$max" >&2
+    printf '  Re-anchor to the committed QUEUE lanes (AGENTS.md) or re-fire with --force. Attempts log: %s\n' "$file" >&2
+    return 8
+  fi
+  printf '%s fire\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || echo fire)" >> "$file"
+  return 0
+}
+
 if [[ "${RELAY_DRIVER_LOCKED:-0}" != "1" ]]; then
   # GH-49b: the lock lives in .git/ (never committed) for a normal clone; a vendored .xyz/ copy has no
   # .git/, so fall back to a hidden lock beside the scripts (the .xyz/ dir is itself gitignored in the
   # foreign repo, so it stays uncommitted just the same). Same lock NAME as relay-drive so a marathon
   # and a relay driver still mutually exclude in one clone. Unchanged when .git/ exists.
@@ -125,10 +151,11 @@ PRE_ADVANCE_CMD=""   # resolved to default after ROOT is set
 PHASES_DIR=""        # resolved to default after ROOT is set
 PHASE_ID="p1"        # which phase this invocation drives (phases/<id>/); the orchestrator sets it
 RELAY_TASK=""        # resolved to MARATHON-<PHASE_ID>-TURN after parsing, unless given
 ARTIFACT_PATHS=""    # comma-separated repo-relative file(s) the builder may create/edit (beyond RELAY.md)
 REQUIRE_CLEAN=0      # --require-clean: hard-stop if the workspace has pre-existing changes
+FORCE=0              # --force: bypass the GH-45 per-lane attempt cap for this one fire
 DRY_RUN=0
 TARGET_ROOT=""       # --target-root: foreign repo the BUILD lands in (GH-11). Relay thread stays in ROOT;
                      # forwarded to relay-drive.sh (which exports RELAY_TARGET_ROOT for artifact routing).
 
 while (($# > 0)); do
@@ -142,10 +169,11 @@ while (($# > 0)); do
     --phase-id)        PHASE_ID="${2:-}"; shift 2 ;;
     --relay-task)      RELAY_TASK="${2:-}"; shift 2 ;;
     --artifact)        ARTIFACT_PATHS="${2:-}"; shift 2 ;;
     --target-root)     TARGET_ROOT="${2:-}"; shift 2 ;;
     --require-clean)   REQUIRE_CLEAN=1; shift ;;
+    --force)           FORCE=1; shift ;;
     --dry-run)         DRY_RUN=1; shift ;;
     --help)            usage; exit 0 ;;
     *)                 die "unknown argument: $1" ;;
   esac
 done
@@ -326,10 +354,15 @@ reconcile_relay_task() {
       esac
       ;;
   esac
 }
 
+# GH-45: per-lane attempt cap — refuse to start this phase once it has hit LANE_MAX_ATTEMPTS
+# (keyed on PHASE_ID, stable across re-fires), seeding no token; --force overrides. Counted here, so
+# the nested relay-drive below (LANE_ATTEMPT_COUNTED=1) does not double-count this same lane.
+lane_attempt_gate "${TICK_REPO_ROOT:-$ROOT}" "$PHASE_ID" "$FORCE" || exit $?
+
 reconcile_relay_task
 
 "$TICK_BIN" log task.created "$RELAY_TASK" --agent marathon > /dev/null
 "$TICK_BIN" claim           "$RELAY_TASK" --agent marathon --paths "$REL_RELAY" > /dev/null
 "$TICK_BIN" release         "$RELAY_TASK" --agent marathon --to "$BUILDER" > /dev/null
@@ -351,10 +384,11 @@ target_root_args=()
 # silent (XYZ_HARNESS_CONTEXT=marathon-phase) so a per-phase relay completion never emits its own
 # record — this marathon-drive run (or marathon.sh above it) owns the single whole-run record. This is
 # scoped to the relay-drive child only; marathon-drive's OWN context (swarm|unset) is left intact for
 # its hook below.
 RELAY_FILE="$RELAY_FILE" \
+LANE_ATTEMPT_COUNTED=1 \
 XYZ_HARNESS_CONTEXT=marathon-phase \
   "$RELAY_DRIVE_BIN" \
     --relay-file "$RELAY_FILE" \
     --relay-task "$RELAY_TASK" \
     --agent-cmd  "$AGENT_CMD" \

codex
The biggest substantive risk is no longer the off-by-one; that part is fine. The bigger question is lane identity: these keys are lifetime-sticky, and the defaults (`p1`, `RELAY-TURN`) are generic enough that unrelated future runs can inherit a permanent park.
exec
/bin/zsh -lc "nl -ba relay-automation/relay-drive.sh | sed -n '240,320p'" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-61154-16825
 succeeded in 0ms:
   240	  case "$status" in
   241	    claimed) actor="$claimer" ;;
   242	    open)    actor="$handoff" ;;
   243	    *)       actor="" ;;
   244	  esac
   245	  printf '%s\t%s\n' "$status" "$actor"
   246	}
   247	
   248	round=0
   249	while ((round < ROUND_CAP)); do
   250	  s="$(file_status)"
   251	  IFS=$'\t' read -r tstatus actor < <(token_state)
   252	
   253	  # Terminal CLOSE requires AGREEMENT: file STATUS terminal AND the RELAY-TURN
   254	  # token no longer live (done/gone). file-terminal-but-token-live is a leaked
   255	  # close — escalate, never report success. (Codex r1 Blocker.)
   256	  if terminal_status "$s"; then
   257	    if [[ -n "$actor" ]]; then
   258	      printf 'relay-drive: STATUS %s but RELAY-TURN still live (%s/%s) — close mismatch, escalating\n' "$s" "$tstatus" "$actor" >&2
   259	      exit 4
   260	    fi
   261	    printf 'relay-drive: relay terminated (STATUS: %s, token done) after %d turn(s)\n' "$s" "$round"
   262	    xyz_relay_emit green
   263	    exit 0
   264	  fi
   265	
   266	  # Escalated = terminal by design (handback to human); the token may legitimately stay live, so this
   267	  # is checked BEFORE the no-actor branch. A clean, distinct outcome — not a stall (GH-18 #5).
   268	  if escalated_status "$s"; then
   269	    printf 'relay-drive: relay escalated to human by design (STATUS: %s, token %s) after %d turn(s)\n' "$s" "${actor:-done}" "$round" >&2
   270	    xyz_relay_emit orange
   271	    exit 4
   272	  fi
   273	
   274	  # file not terminal but the token is gone/done → also a mismatch.
   275	  if [[ -z "$actor" ]]; then
   276	    printf 'relay-drive: %s has no actor (token %s) but STATUS=%s — escalating\n' "$RELAY_TASK" "${tstatus:-missing}" "$s" >&2
   277	    # A `done` token under a non-terminal thread is the classic reused-token collision (GH-18 #1):
   278	    # a prior relay spent this id. Point at the fix so recovery isn't a scavenger hunt.
   279	    [[ "$tstatus" == "done" ]] && printf "  → '%s' is spent from a prior relay; seed + drive with a fresh --relay-task (e.g. RELAY-%s)\n" "$RELAY_TASK" "$(basename "$RELAY_FILE" .md)" >&2
   280	    exit 4
   281	  fi
   282	
   283	  if ((DRY_RUN)); then
   284	    printf 'relay-drive: WOULD drive turn for agent: %s (token %s, STATUS: %s)\n' "$actor" "$tstatus" "$s"; exit 0
   285	  fi
   286	
   287	  prev="$tstatus:$actor"
   288	  RELAY_FILE="$RELAY_FILE" RELAY_TASK="$RELAY_TASK" RELAY_AGENT="$actor"
   289	  export RELAY_FILE RELAY_TASK RELAY_AGENT
   290	  # Invoke the turn-taker. A bare executable path (even absolute or containing spaces, e.g. a clone
   291	  # under ".../GH Repos/...") is run DIRECTLY so it survives spaces; a full command string
   292	  # (env-prefixed, shell-quoted, or %q-escaped by a caller) falls back to eval. This fixes spaced
   293	  # absolute --agent-cmd paths without breaking the command-string contract callers/tests rely on.
   294	  if [[ -x "$AGENT_CMD" ]]; then
   295	    "$AGENT_CMD"
   296	  else
   297	    eval "$AGENT_CMD"
   298	  fi
   299	  round=$((round + 1))
   300	
   301	  # --consult-verify: independent second opinion after each turn.
   302	  # Invokes consult.sh (codex + gemini) to challenge the turn-taker's self-reported VERDICT.
   303	  # On divergence: appends a conflict-warning advisory block, sets STATUS: Escalated, exits 4.
   304	  if ((CONSULT_VERIFY)); then
   305	    _cv_taker_verdict="$(sed -n '/^## Log/,$p' "$RELAY_FILE" | grep -E '^VERDICT: ' | tail -1 | sed 's/^VERDICT: //')"
   306	    _cv_label="consult-verify-$(basename "$RELAY_FILE" .md)-r${round}"
   307	    _cv_out_dir="$ROOT_DIR/relay-system/$(date +%F)"
   308	    # Write prompt to a temp file — avoids nested variable expansion fragility inside $()
   309	    _cv_prompt_file="$(mktemp -t cv-prompt.XXXXXX)"
   310	    printf 'Review the most recent log block in this relay file. Does the turn-taker'"'"'s VERDICT match their stated evidence in the Basis: line? Reply with exactly one of: AGREE-PASS (verdict supported), AGREE-FAIL (verdict supported), or DISAGREE (verdict not supported by evidence). One token only.\n\n=== RELAY FILE ===\n' > "$_cv_prompt_file"
   311	    cat "$RELAY_FILE" >> "$_cv_prompt_file"
   312	    _cv_consult_out="$(CONSULT_ROOT="$ROOT_DIR" "$CONSULT_SH" \
   313	      --prompt-file "$_cv_prompt_file" \
   314	      --label "$_cv_label" \
   315	      --out "$_cv_out_dir" 2>/dev/null)" || true
   316	    rm -f "$_cv_prompt_file"
   317	
   318	    # Parse advisor verdicts from transcript file paths in consult stdout ([ok] model -> path)
   319	    _cv_diverged=0; _cv_advisor_summary=""
   320	    while IFS= read -r _cv_line; do

mcp: codebase-memory-mcp/list_projects started
mcp: codebase-memory-mcp/list_projects (failed)
user cancelled MCP tool call
codex
**ANSWER**

Not merge-ready as-is. The off-by-one logic is correct and the nested `LANE_ATTEMPT_COUNTED` guard is placed correctly, but the lane key is too coarse: with the current defaults, unrelated future runs will inherit a permanent park from old `.tick/attempts/*` state, which is not a safe interpretation of “per-lane attempt cap” ([relay-drive.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-61154-16825/relay-automation/relay-drive.sh:132), [relay-drive.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-61154-16825/relay-automation/relay-drive.sh:178), [marathon-drive.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-61154-16825/relay-automation/marathon-drive.sh:152), [marathon-drive.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-61154-16825/relay-automation/marathon-drive.sh:362), [AGENTS.md](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-61154-16825/AGENTS.md:70)).

I could verify syntax/static wiring, but I could not complete `test/lane-attempt-cap.sh` behaviorally here because the sandbox blocks `mktemp` and temp-file writes.

**FINDINGS**

- [Blocker] The attempts key is lifetime-sticky and default names are reused across unrelated runs. `relay-drive.sh` keys on `RELAY_TASK`, which defaults to `RELAY-TURN`; `marathon-drive.sh` keys on `PHASE_ID`, which defaults to `p1`; the counter file is append-only and has no reset path. That means the third future standalone relay with default settings, or the third future `p1` phase in this repo, parks immediately even if it is new work ([relay-drive.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-61154-16825/relay-automation/relay-drive.sh:132), [relay-drive.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-61154-16825/relay-automation/relay-drive.sh:178), [marathon-drive.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-61154-16825/relay-automation/marathon-drive.sh:152), [marathon-drive.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-61154-16825/relay-automation/marathon-drive.sh:194), [marathon-drive.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-61154-16825/relay-automation/marathon-drive.sh:362)).

- [Should] `--force` exists but the operator path is incomplete. Both drivers parse `--force`, but neither usage block documents it, and `marathon.sh` does not accept/pass it through. In the normal orchestrated path, a parked phase cannot be re-fired from the top-level command with the rail that `AGENTS.md` now advertises ([relay-drive.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-61154-16825/relay-automation/relay-drive.sh:103), [relay-drive.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-61154-16825/relay-automation/relay-drive.sh:143), [marathon-drive.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-61154-16825/relay-automation/marathon-drive.sh:124), [marathon-drive.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-61154-16825/relay-automation/marathon-drive.sh:174), [marathon.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-61154-16825/relay-automation/marathon.sh:52), [AGENTS.md](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-61154-16825/AGENTS.md:74)).

- [Should] Exit `8` is only partly distinguishable. The gate prints a clear park message, but the script headers do not document exit `8`, `marathon.sh` maps it to generic “marathon-drive exit 8”, and `bin/tick` already uses `8` for relay-block validation failure. A human reading stderr can tell what happened; a caller treating `8` as uniquely “parked lane” cannot ([relay-drive.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-61154-16825/relay-automation/relay-drive.sh:23), [relay-drive.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-61154-16825/relay-automation/relay-drive.sh:49), [marathon-drive.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-61154-16825/relay-automation/marathon-drive.sh:32), [marathon-drive.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-61154-16825/relay-automation/marathon-drive.sh:60), [marathon.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-61154-16825/relay-automation/marathon.sh:104), [bin/tick](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-61154-16825/bin/tick:234)).

- [Nit] The new regression test is not defensive about temp-dir creation. In this read-only sandbox, `mktemp -d` failed and the script kept going with empty paths, producing misleading follow-on failures. That does not invalidate the production logic, but it does make the test noisier than it needs to be under constrained runners ([test/lane-attempt-cap.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-61154-16825/test/lane-attempt-cap.sh:9), [test/lane-attempt-cap.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-61154-16825/test/lane-attempt-cap.sh:37)).

- [Pass] The cap itself is implemented correctly. It checks before append, so default `2` allows two fires and parks the third; a parked fire does not append; `--review-once` and `--dry-run` skipping the cap is a reasonable fit for an anti-rabbit-hole guard; and the nested `marathon-drive -> relay-drive` path short-circuits exactly where it should ([relay-drive.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-61154-16825/relay-automation/relay-drive.sh:46), [relay-drive.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-61154-16825/relay-automation/relay-drive.sh:175), [relay-drive.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-61154-16825/relay-automation/relay-drive.sh:361), [marathon-drive.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-61154-16825/relay-automation/marathon-drive.sh:56), [marathon-drive.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-61154-16825/relay-automation/marathon-drive.sh:389), [test/lane-attempt-cap.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-61154-16825/test/lane-attempt-cap.sh:24)).

**RECOMMENDATION**

Rekey attempts to a run/wave-scoped lane identity instead of bare `p1` / `RELAY-TURN`, then document and plumb `--force` end-to-end (including `marathon.sh`) before merge.
tokens used
122,393
**ANSWER**

Not merge-ready as-is. The off-by-one logic is correct and the nested `LANE_ATTEMPT_COUNTED` guard is placed correctly, but the lane key is too coarse: with the current defaults, unrelated future runs will inherit a permanent park from old `.tick/attempts/*` state, which is not a safe interpretation of “per-lane attempt cap” ([relay-drive.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-61154-16825/relay-automation/relay-drive.sh:132), [relay-drive.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-61154-16825/relay-automation/relay-drive.sh:178), [marathon-drive.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-61154-16825/relay-automation/marathon-drive.sh:152), [marathon-drive.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-61154-16825/relay-automation/marathon-drive.sh:362), [AGENTS.md](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-61154-16825/AGENTS.md:70)).

I could verify syntax/static wiring, but I could not complete `test/lane-attempt-cap.sh` behaviorally here because the sandbox blocks `mktemp` and temp-file writes.

**FINDINGS**

- [Blocker] The attempts key is lifetime-sticky and default names are reused across unrelated runs. `relay-drive.sh` keys on `RELAY_TASK`, which defaults to `RELAY-TURN`; `marathon-drive.sh` keys on `PHASE_ID`, which defaults to `p1`; the counter file is append-only and has no reset path. That means the third future standalone relay with default settings, or the third future `p1` phase in this repo, parks immediately even if it is new work ([relay-drive.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-61154-16825/relay-automation/relay-drive.sh:132), [relay-drive.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-61154-16825/relay-automation/relay-drive.sh:178), [marathon-drive.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-61154-16825/relay-automation/marathon-drive.sh:152), [marathon-drive.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-61154-16825/relay-automation/marathon-drive.sh:194), [marathon-drive.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-61154-16825/relay-automation/marathon-drive.sh:362)).

- [Should] `--force` exists but the operator path is incomplete. Both drivers parse `--force`, but neither usage block documents it, and `marathon.sh` does not accept/pass it through. In the normal orchestrated path, a parked phase cannot be re-fired from the top-level command with the rail that `AGENTS.md` now advertises ([relay-drive.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-61154-16825/relay-automation/relay-drive.sh:103), [relay-drive.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-61154-16825/relay-automation/relay-drive.sh:143), [marathon-drive.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-61154-16825/relay-automation/marathon-drive.sh:124), [marathon-drive.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-61154-16825/relay-automation/marathon-drive.sh:174), [marathon.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-61154-16825/relay-automation/marathon.sh:52), [AGENTS.md](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-61154-16825/AGENTS.md:74)).

- [Should] Exit `8` is only partly distinguishable. The gate prints a clear park message, but the script headers do not document exit `8`, `marathon.sh` maps it to generic “marathon-drive exit 8”, and `bin/tick` already uses `8` for relay-block validation failure. A human reading stderr can tell what happened; a caller treating `8` as uniquely “parked lane” cannot ([relay-drive.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-61154-16825/relay-automation/relay-drive.sh:23), [relay-drive.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-61154-16825/relay-automation/relay-drive.sh:49), [marathon-drive.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-61154-16825/relay-automation/marathon-drive.sh:32), [marathon-drive.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-61154-16825/relay-automation/marathon-drive.sh:60), [marathon.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-61154-16825/relay-automation/marathon.sh:104), [bin/tick](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-61154-16825/bin/tick:234)).

- [Nit] The new regression test is not defensive about temp-dir creation. In this read-only sandbox, `mktemp -d` failed and the script kept going with empty paths, producing misleading follow-on failures. That does not invalidate the production logic, but it does make the test noisier than it needs to be under constrained runners ([test/lane-attempt-cap.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-61154-16825/test/lane-attempt-cap.sh:9), [test/lane-attempt-cap.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-61154-16825/test/lane-attempt-cap.sh:37)).

- [Pass] The cap itself is implemented correctly. It checks before append, so default `2` allows two fires and parks the third; a parked fire does not append; `--review-once` and `--dry-run` skipping the cap is a reasonable fit for an anti-rabbit-hole guard; and the nested `marathon-drive -> relay-drive` path short-circuits exactly where it should ([relay-drive.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-61154-16825/relay-automation/relay-drive.sh:46), [relay-drive.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-61154-16825/relay-automation/relay-drive.sh:175), [relay-drive.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-61154-16825/relay-automation/relay-drive.sh:361), [marathon-drive.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-61154-16825/relay-automation/marathon-drive.sh:56), [marathon-drive.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-61154-16825/relay-automation/marathon-drive.sh:389), [test/lane-attempt-cap.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-61154-16825/test/lane-attempt-cap.sh:24)).

**RECOMMENDATION**

Rekey attempts to a run/wave-scoped lane identity instead of bare `p1` / `RELAY-TURN`, then document and plumb `--force` end-to-end (including `marathon.sh`) before merge.
