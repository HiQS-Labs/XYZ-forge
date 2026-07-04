Reading additional input from stdin...
OpenAI Codex v0.139.0
--------
workdir: /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-79403-29214
model: gpt-5.4
provider: openai
approval: never
sandbox: read-only
reasoning effort: high
reasoning summaries: none
session id: 019f2d97-3a36-71b2-8f94-b04f06314b9c
--------
user
You are an INDEPENDENT advisor in a one-shot cross-model consult. Another model is answering the SAME question separately and a coordinator will reconcile both answers, so give your own honest, specific read — do not hedge toward a consensus you cannot see. Read any repo files the question references (cite file:line). Respond with: (1) a short direct ANSWER; (2) graded FINDINGS — [Blocker]/[Should]/[Nit]/[Pass] — where applicable; (3) a one-line RECOMMENDATION. You are ADVISORY ONLY: output your analysis as text; do not rely on writing files (you are running in a throwaway copy).

=== CONSULT QUESTION ===
## Consult question: GH-48 design review

Read `PROJECT/2-WORKING/GH-48-QUEUE-PLAN-CROSS-REPO-ZONES.md` in full, and cross-check its claims
against the real code in `utils/marathon-plan.sh` (specifically `zoneOf()` around line 350-373, the
`KERNEL_PATHS`/`SHIM_RE` constants around line 148-153, and the wave-packing loop around line
643-690).

Context: `marathon-plan.sh`'s zone classifier (kernel/shim/independent) is hardcoded to this repo's
own filenames, so it can't compute a meaningful swarm/serialize plan for an external repo (e.g.
rebalance-OS, whose real collision constraint is a shared signed helper file the classifier has no
model of). The doc commits to a design — replacing the hardcoded constants with a configurable,
data-driven zone-rules list (path prefixes/regex + `maxPerWave` + `conservativeWhenInferred` +
`penalty` per zone), defaulting to this repo's exact current values so nothing about its own
planning changes. A competing idea ("contract-only mode" — skip keyword inference when every item
has a swarm-preflight contract) was considered and rejected, because the doc's author found the
hardcoded classification runs even on contract-backed items today, so that idea alone would not fix
the external-repo case. A third idea (a foreign ledger/queue-format reader) was deferred as
speculative and unnecessary for now.

Answer these three questions directly, citing the doc section and/or code lines where relevant:

1. **Does the zone-rules schema actually generalize the current kernel/shim semantics without losing
   any existing behavior?** Walk through whether every current hardcoded rule (KERNEL_PATHS,
   SHIM_RE, the keyword-inference regexes, ZONE_PEN, the max-1-kernel-per-wave rule, and the
   shim-conservative-when-inferred rule) has a faithful equivalent in the proposed schema. Flag any
   asymmetry, edge case, or silent behavior change the default config might introduce.

2. **Is deferring the foreign ledger/queue-format adapter (idea #3) the right call**, or does the
   rebalance-OS dogfood specifically need it sooner than "revisit if Phase 2 proves it necessary"?

3. **Any gap in the resolution-order precedence** (`--zones-config` flag > `QP_ZONES_FILE` env test
   seam > `<target-root>/.marathon-plan-zones.json` > built-in default) that would surprise an
   operator running this against a real foreign repo — e.g. discoverability, a missing/malformed
   config file's failure mode, or an interaction with `--target-root` you'd want made explicit?

Respond with: (1) a direct ANSWER to each of the three questions; (2) graded findings —
[Blocker]/[Should]/[Nit]/[Pass] — for anything you'd want fixed before code gets written; (3) a
one-line RECOMMENDATION (build as designed / build with named fixes / rethink).
hook: SessionStart
hook: SessionStart Completed
codex
I’m checking the cited plan doc and the current `marathon-plan.sh` implementation side by side, starting with repo routing files and the indexed code graph so the review is grounded in the actual source.
exec
/bin/zsh -lc "pwd && printf '\\n---\\n' && nl -ba ROUTER.md | sed -n '1,220p'" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-79403-29214
exec
/bin/zsh -lc "nl -ba GUIDING-PRINCIPLES.md | sed -n '1,220p'" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-79403-29214
 succeeded in 0ms:
/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-79403-29214

---
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
    71	- If the task is about the **Aider ↔ OpenRouter** turn-taker lane (`relay-automation/aider-turn.sh` — an OpenAI-standard build lane discrete from Codex; `AIDER_MODEL`/`OPENROUTER_API_KEY`, `--builder aider`), start in `PROJECT/3-COMPLETED/GH-77-AIDER-OPENROUTER-LANE.md`. The shim owns the tick token ops (Aider can't run shell mid-turn), asserts token ownership before launching Aider, and runs Aider `--no-auto-commits` (the harness commits).
    72	- If the task is about running, driving, or reviewing via the relay (`relay-automation/` — `relay-drive.sh`, `poll.sh`, the turn shims, `marathon*.sh`), **invoke the `relay-xyz` skill first — do not improvise the handoff or hand-roll a harness from `ls relay-automation/`.** The skill owns the locator, sandbox rules, exit codes, and the safety boundary; a `PreToolUse` guard (`relay-automation/hooks/relay-xyz-guard.sh`) blocks driving a harness driver before the skill is loaded. For the two live-Claude-windows, same-machine duel recipe (Reporter↔Maintainer with a human go-gate), the copy-paste form is [relay-automation/DUELING-CLAUDES.md](relay-automation/DUELING-CLAUDES.md).
    73	- If the task is about relay session telemetry, the `focus5float` health feed, or extraction scripts under `utils/telemetry/`, start in `PROJECT/1-INBOX/GH-24-RELAY-TELEMETRY-EXTRACTOR.md`.
    74	- If the task is about live per-session completion telemetry — the `XYZ.json` log every relay/marathon/swarm session appends to at the harness repo root (schema: `harness`/`sessionId`/`health`/`title`/`description`/`updatedAt`), the shared writer `utils/telemetry/append-xyz-completion.sh`, or the shared health mapping `utils/telemetry/health-lib.sh` — start in `PROJECT/1-INBOX/GH-75-XYZ-JSON-COMPLETION-TELEMETRY.md`. `XYZ.json` is local + gitignored (machine-specific).
    75	- If the task is about a proposed roadmap-steward agent, start here, then read `PROJECT/PDDA.md` and its `Proposed roadmap steward extension` section.
    76	- Issue-first SOP: any change beyond a 2–3 line fix (and every project plan) opens a GitHub issue *first*, then gets a pointer doc named after the issue at `PROJECT/1-INBOX/GH-<number>-VERY-SHORT-DESC.md` — e.g. `GH-1234-SHOWME-COMMAND.md` — and that capture is parked in the `ROADMAP.md` queue immediately (format + lifecycle owned by `PROJECT/PDDA.md` → "GitHub issue intake"), following the normal `1-INBOX` → `2-WORKING` flow. Genuinely trivial edits (≤2–3 line fixes, typos, path repoints, doc-only one-liners) are exempt and commit directly.

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

mcp: codebase-memory-mcp/list_projects started
mcp: codebase-memory-mcp/list_projects (failed)
user cancelled MCP tool call
exec
/bin/zsh -lc "nl -ba PROJECT/2-WORKING/GH-48-QUEUE-PLAN-CROSS-REPO-ZONES.md | sed -n '1,260p'" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-79403-29214
 succeeded in 0ms:
     1	---
     2	gh_issue: 48
     3	source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/48
     4	title: Generalize marathon-plan's zone model for true cross-repo pre-pre-flight
     5	status: Designed — awaiting /consult (Agy + Codex) before build
     6	created: 2026-06-29
     7	updated: 2026-07-04
     8	owner: noel
     9	doc_type: feature
    10	goal: >
    11	  Replace utils/marathon-plan.sh's hardcoded kernel/shim zone classifier with a configurable,
    12	  declarative zone-rules layer (path prefixes/regex + max-per-wave + inference-conservatism per
    13	  zone), defaulting to xyz's current rules byte-for-byte, so marathon-plan can compute a correct
    14	  swarm/serialize wave plan for an external repo (validated against the live rebalance-OS 3-lane
    15	  queue) without xyz-specific keyword coupling.
    16	non_goals:
    17	  - No foreign ledger/queue-format reader (park-and-discuss idea #3 from the original issue) — the
    18	    near-term path (per-lane swarm-preflight contracts) already works today per ROADMAP.md's
    19	    existing guidance; revisit only if the rebalance dogfood proves that insufficient.
    20	  - No change to swarm-preflight.sh itself — its write-set disjointness engine is already generic.
    21	  - No change to xyz's own planning output — the default zone config is xyz's current
    22	    KERNEL_PATHS/SHIM_RE values verbatim, so test/marathon-plan.sh must stay byte-identical.
    23	complexity: 3
    24	risk: 2
    25	effort: 3
    26	phases: 2
    27	roadmap_exempt: false
    28	related:
    29	  - utils/marathon-plan.sh
    30	  - utils/swarm-preflight.sh
    31	  - test/marathon-plan.sh
    32	---
    33	
    34	## Status
    35	
    36	| What was just completed | What's next |
    37	|---|---|
    38	| Design committed (this doc) — replaces the three park-and-discuss ideas with one decided approach (Option 1, configurable zone rules) grounded in the actual `zoneOf()`/wave-packing code (`utils/marathon-plan.sh:148-153`, `:350-373`, `:643-690`). Not yet built. | Run `/consult` (Agy + Codex) to review this design before writing code — see [Consult ask](#consult-ask). If Approved (or Approved-with-fixes), promote to a marathon lane with the contract below; this lane is explicitly **excluded** from the current Plan B firing round. |
    39	
    40	## Problem (grounded in the current code)
    41	
    42	`utils/marathon-plan.sh`'s `zoneOf(contract, item)` (line 350) labels every item `kernel | shim |
    43	independent` using two **hardcoded, xyz-specific** constants:
    44	
    45	```js
    46	const KERNEL_PATHS = [
    47	  "relay-automation/relay-turn-lib.sh",
    48	  "bin/tick",
    49	  "relay-automation/relay-drive.sh",
    50	];
    51	const SHIM_RE = /relay-automation\/[a-z0-9-]+-turn\.sh$|relay-automation\/consult\.sh$/i;
    52	```
    53	
    54	The important detail the original issue capture under-specified: **this hardcoding applies even
    55	when an item has a real swarm-preflight contract.** `zoneOf`'s "proven zone" branch (line
    56	359-365) still runs the contract's `artifacts[]` write-set through `KERNEL_PATHS`/`SHIM_RE` —
    57	so a foreign repo's contract naming `scripts/apple_reminders_helper_app.swift` as its write-set
    58	matches neither, and falls through to `independent` **even with a fully-specified contract**. The
    59	gap isn't "missing contracts" (park-and-discuss idea #2 assumed that) — it's that the
    60	classification *rules themselves* are xyz's filenames, contract or no contract. Idea #2 alone
    61	would not fix the rebalance case.
    62	
    63	The wave-packing loop (line 643, 672-690) has the same hardcoding one level up: `ZONE_PEN`,
    64	`kernelTaken` (max-1-kernel-per-wave), and `inferredShimClash` (shim items without a proven
    65	write-set can't share a wave) all key off the literal strings `"kernel"`/`"shim"`.
    66	
    67	`swarm-preflight.sh`'s write-set disjointness is already fully generic (confirmed, not
    68	re-litigated here) — this doc scopes strictly to the `marathon-plan.sh` ranker/classifier gap.
    69	
    70	## Decision: build Option 1 (configurable zone rules), not idea #2 or #3
    71	
    72	- **Option 1 — configurable zone rules.** Committed. Replaces `KERNEL_PATHS`/`SHIM_RE` and the
    73	  wave-packing constants with a data-driven zone-rules list, loaded from a config file, with xyz's
    74	  current values shipped as the built-in default (zero behavior change for xyz itself).
    75	- **Option 2 — contract-only mode.** Not a separate deliverable — proven-vs-inferred priority
    76	  already exists in `zoneOf` today; the real fix is making the *proven* path's matching rules
    77	  configurable (which Option 1 does). Superseded by Option 1, not built alongside it.
    78	- **Option 3 — foreign ledger/queue-format adapter.** Explicitly deferred. ROADMAP.md's existing
    79	  near-term note already recommends per-lane `swarm-preflight` contracts as today's workable path
    80	  for cross-repo work; a foreign-ledger reader is a bigger, more speculative lift (every foreign
    81	  repo's queue format differs) that isn't required to unblock the rebalance dogfood. If the live
    82	  validation in Phase 2 below proves this genuinely needed, it becomes its own follow-up issue —
    83	  not silently folded into this one.
    84	
    85	## Design
    86	
    87	### Zone-rules schema
    88	
    89	```json
    90	{
    91	  "zones": [
    92	    {
    93	      "name": "kernel",
    94	      "pathPrefixes": ["relay-automation/relay-turn-lib.sh", "bin/tick", "relay-automation/relay-drive.sh"],
    95	      "inferKeywordRegex": "relay-turn-lib|containment kernel|bin/tick|relay-drive|commit semantics|epoch fenc",
    96	      "maxPerWave": 1,
    97	      "penalty": 2
    98	    },
    99	    {
   100	      "name": "shim",
   101	      "pathRegex": "relay-automation/[a-z0-9-]+-turn\\.sh$|relay-automation/consult\\.sh$",
   102	      "inferKeywordRegex": "-turn\\.sh|consult\\.sh|\\bshim\\b",
   103	      "conservativeWhenInferred": true,
   104	      "penalty": 1
   105	    }
   106	  ],
   107	  "defaultZone": { "name": "independent", "penalty": 0 }
   108	}
   109	```
   110	
   111	This is xyz's **exact current behavior** re-expressed as data — the default config `utils/marathon-plan-zones.default.json` ships this verbatim, so nothing about xyz's own planning changes.
   112	
   113	A foreign repo's override, e.g. `rebalance-os-zones.json`:
   114	
   115	```json
   116	{
   117	  "zones": [
   118	    {
   119	      "name": "signed-helper",
   120	      "pathPrefixes": ["scripts/apple_reminders_helper_app.swift"],
   121	      "maxPerWave": 1,
   122	      "penalty": 2
   123	    }
   124	  ],
   125	  "defaultZone": { "name": "independent", "penalty": 0 }
   126	}
   127	```
   128	
   129	### Resolution order (first match wins)
   130	
   131	1. `--zones-config <path>` CLI flag (explicit override).
   132	2. `QP_ZONES_FILE` env var — hermetic test seam, mirroring the existing `QP_BASE_FILES_FILE` /
   133	   `QP_GH_STATE_FILE` / `QP_BRANCHES_FILE` pattern already in `utils/marathon-plan.sh`.
   134	3. `<target-root>/.marathon-plan-zones.json` — repo-local convention, analogous to how
   135	   `swarm-preflight` already treats `--target-root` as "the repo this plan is about."
   136	4. Built-in xyz default (`utils/marathon-plan-zones.default.json`) — always available, never
   137	   requires a flag for xyz's own repo.
   138	
   139	### Code changes (Phase 1)
   140	
   141	- `zoneOf(contract, item)`: iterate the loaded zone list in order; for the proven-contract path,
   142	  match `artifacts[]` against each zone's `pathPrefixes`/`pathRegex`; for the inferred path (no
   143	  contract), match title+body text against each zone's `inferKeywordRegex`. First match wins;
   144	  falls through to `defaultZone`. Same two-tier proven-vs-inferred priority as today — only the
   145	  matching rules move from hardcoded consts to config data.
   146	- Wave-packing (`ZONE_PEN`, `kernelTaken`, `inferredShimClash`): generalize to read `penalty` /
   147	  `maxPerWave` / `conservativeWhenInferred` off the matched zone object instead of string-comparing
   148	  `"kernel"`/`"shim"`. A zone with no `maxPerWave` behaves like today's `independent`/`shim` (no cap
   149	  beyond write-set disjointness); `conservativeWhenInferred` generalizes the shim-specific rule to
   150	  any zone that opts in.
   151	- Collision-map rendering (~line 810): iterate the configured zone list instead of the hardcoded
   152	  `["kernel", "shim", "independent"]` array.
   153	
   154	### Phase 2 — live acceptance validation (not a code change)
   155	
   156	Run `marathon-plan.sh --target-root <rebalance-OS clone> --zones-config rebalance-os-zones.json`
   157	against the **real** rebalance-OS 3-lane queue (`PROJECT/4-MISC/QUEUE-2026-06-27.md` in that repo),
   158	with each lane carrying a swarm-preflight contract (per ROADMAP's existing near-term
   159	recommendation — this was already the intended path regardless of this issue). Confirms the
   160	shared-helper lane lands alone in its own wave (`maxPerWave: 1` enforced) while the other two lanes
   161	wave together. This is the acceptance gate, not a nice-to-have — "done" means this actually ran
   162	against the live repo, not a synthetic fixture standing in for it.
   163	
   164	## Acceptance criteria
   165	
   166	- [ ] `test/marathon-plan.sh` fully green with **zero** output diff versus today — the default zone
   167	  config reproduces xyz's current classification and wave-packing exactly.
   168	- [ ] New test coverage (extend `test/marathon-plan.sh` or add `test/marathon-plan-zones.sh`): a
   169	  synthetic foreign zone-config correctly reclassifies a write-set the hardcoded regexes would have
   170	  missed, and correctly enforces `maxPerWave`/`conservativeWhenInferred`.
   171	- [ ] Resolution-order precedence tested: `--zones-config` > `QP_ZONES_FILE` > `<target-root>/.marathon-plan-zones.json` > built-in default.
   172	- [ ] Live validation (Phase 2): the actual rebalance-OS 3-lane queue produces the correct wave
   173	  split, run against the real repo, output captured in this doc's Status table.
   174	- [ ] Schema documented in `utils/marathon-plan.sh`'s header comment and `relay-automation/README.md`.
   175	
   176	## Reversibility & blast radius
   177	
   178	**Medium-low.** Pure refactor of one internal classification function + wave-packing constants,
   179	behind a new optional config layer whose default is provably identical to today's hardcoded
   180	behavior (acceptance criterion 1 is the regression guard). Touches `utils/marathon-plan.sh`, one of
   181	Plan B's own contended shared-file zones (collision map: `#86 → #48`, serialize, never run
   182	together) — this lane must run **after** #86 lands, exactly as Plan B's existing wave ordering
   183	already requires. No kernel (`relay-turn-lib.sh`/`bin/tick`) surface touched.
   184	
   185	## Consult ask
   186	
   187	Before writing code: `/consult` Agy + Codex on this design specifically —
   188	1. Does the zone-rules schema (path prefixes/regex + `maxPerWave` + `conservativeWhenInferred` +
   189	   `penalty`) actually generalize the current kernel/shim semantics without losing any existing
   190	   behavior?
   191	2. Is deferring Option 3 (foreign ledger/queue-format adapter) the right call, or does the
   192	   rebalance dogfood specifically need it sooner than "revisit if Phase 2 proves it necessary"?
   193	3. Any gap in the resolution-order precedence (flag > env seam > repo-local file > built-in
   194	   default) that would surprise an operator running this against a real foreign repo?
   195	
   196	## Swarm Preflight Contract (draft — for after /consult Approves)
   197	
   198	```json
   199	{
   200	  "target": { "repo": ".", "ref": "main" },
   201	  "gate": "bash test/marathon-plan.sh",
   202	  "fix_probes": [
   203	    { "type": "path_absent", "path": "utils/marathon-plan-zones.default.json" }
   204	  ],
   205	  "artifacts": [
   206	    "utils/marathon-plan.sh",
   207	    "utils/marathon-plan-zones.default.json",
   208	    "test/marathon-plan.sh"
   209	  ],
   210	  "remediation": "Replace utils/marathon-plan.sh's hardcoded KERNEL_PATHS/SHIM_RE and the ZONE_PEN/kernelTaken/inferredShimClash wave-packing constants with a zone-rules list loaded per the resolution order (--zones-config flag > QP_ZONES_FILE env seam > <target-root>/.marathon-plan-zones.json > built-in utils/marathon-plan-zones.default.json, which ships xyz's current values verbatim). zoneOf() and the wave-packing loop key off the matched zone object's pathPrefixes/pathRegex/inferKeywordRegex/maxPerWave/conservativeWhenInferred/penalty fields instead of literal 'kernel'/'shim' strings. test/marathon-plan.sh must show zero output diff for xyz's own default config; add coverage for a foreign zone-config fixture and the resolution-order precedence.",
   211	  "lanes": {
   212	    "agy_safe": ["utils/marathon-plan.sh", "utils/marathon-plan-zones.default.json", "test/marathon-plan.sh"],
   213	    "orchestrator_only": [],
   214	    "note": "Shares utils/marathon-plan.sh with #86 — collision map requires #86 land first (serialize, never run together). Not part of the current Plan B firing round; queued for after /consult review."
   215	  }
   216	}
   217	```
   218	
   219	## Provenance
   220	
   221	Filed 2026-06-29 while planning the rebalance-OS cross-repo marathon dogfood (the ROADMAP queue
   222	entry). The swarm-vs-relay compute was found to be **generic in `swarm-preflight`** (write-set
   223	disjointness, `--target-root`) but **xyz-coupled in `marathon-plan`** (ledger format + kernel/shim
   224	keywords). Design committed 2026-07-04 after re-reading the actual `zoneOf()`/wave-packing code
   225	(see Problem section above) — the original issue's idea #2 turned out not to fix the rebalance case
   226	on its own, which is why this doc commits to idea #1 instead. Relates to the rebalance dogfood
   227	ROADMAP entry and GH-33 / #46 (the marathon path itself).

codex
I have the design doc. Next I’m reading the current `marathon-plan.sh` implementation at the exact seams the doc cites so I can check for silent behavior drift, not just intent drift.
exec
/bin/zsh -lc "nl -ba utils/marathon-plan.sh | sed -n '340,390p'" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-79403-29214
exec
/bin/zsh -lc "nl -ba utils/marathon-plan.sh | sed -n '130,190p'" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-79403-29214
 succeeded in 0ms:
   130	const path = require("path");
   131	const { execSync } = require("child_process");
   132	
   133	const E = process.env;
   134	const ROOT = E.QP_ROOT;
   135	const TODAY = E.QP_TODAY;
   136	const NOW = E.QP_NOW;
   137	const POLICY = E.QP_POLICY;
   138	const FORMAT = E.QP_FORMAT;
   139	const DEEP = E.QP_DEEP === "1";
   140	const REQUIRE_GH = E.QP_REQUIRE_GH === "1";
   141	const SWARM_PREFLIGHT = E.QP_SWARM_PREFLIGHT || "";
   142	const SP_CMD = E.QP_SP_CMD || "utils/swarm-preflight.sh";
   143	const MD_CMD = E.QP_MD_CMD || "relay-automation/marathon-drive.sh";
   144	const MP_CMD = E.QP_MP_CMD || "utils/marathon-plan.sh";
   145	const BASE_FILES_FILE = E.QP_BASE_FILES_FILE || "";
   146	
   147	// ── kernel write-set: the serialization bottleneck (QUEUE-2026-06-27 "the one safety rule") ──
   148	const KERNEL_PATHS = [
   149	  "relay-automation/relay-turn-lib.sh",
   150	  "bin/tick",
   151	  "relay-automation/relay-drive.sh",
   152	];
   153	const SHIM_RE = /relay-automation\/[a-z0-9-]+-turn\.sh$|relay-automation\/consult\.sh$/i;
   154	
   155	// Ledger sections we sequence from vs. only reference.
   156	const SECTIONS = ["Queue / parked intake", "In progress", "Completed", "Deferred · vision"];
   157	const KNOWN_EMOJI = ["🟢", "🟡", "⏸️", "⛔", "✅", "🔮", "🔲", "⚠️", "🆕", "🐞", "🔴"];
   158	
   159	// ── tiny readers ─────────────────────────────────────────────────────────────
   160	function readFileSafe(p) { try { return fs.readFileSync(p, "utf8"); } catch { return null; } }
   161	function existsAt(rel, base) { try { return fs.existsSync(path.resolve(base || ROOT, rel)); } catch { return false; } }
   162	
   163	// Check if file existed at a given ref (to identify net-new artifacts).
   164	// Hermetic test seam: if BASE_FILES_FILE is set, read it as a list of existing base paths.
   165	let BASE_FILES = null;
   166	function fileExistedAtBaseRef(relPath, ref) {
   167	  let normalized = relPath;
   168	  if (normalized.startsWith("./")) normalized = normalized.slice(2);
   169	  if (BASE_FILES_FILE) {
   170	    if (!BASE_FILES) {
   171	      try {
   172	        BASE_FILES = new Set(
   173	          fs.readFileSync(BASE_FILES_FILE, "utf8")
   174	            .split(/\r?\n/)
   175	            .map((s) => s.trim())
   176	            .filter(Boolean)
   177	        );
   178	      } catch {
   179	        BASE_FILES = new Set();
   180	      }
   181	    }
   182	    return BASE_FILES.has(normalized);
   183	  }
   184	  try {
   185	    // Check if the file existed at the base ref using git
   186	    execSync(`git cat-file -e "${ref}:${normalized}"`, { cwd: ROOT, stdio: ["ignore", "pipe", "ignore"] });
   187	    return true;
   188	  } catch {
   189	    return false;
   190	  }

 succeeded in 0ms:
   340	function docOf(item) {
   341	  const mds = item.links.map((l) => l.target).filter((t) => /\.md($|#)/.test(t) && /PROJECT\//.test(t) && !/relay-system\//.test(t));
   342	  if (mds.length === 0) return null;
   343	  const pick = mds.find((t) => /2-WORKING\/GH-\d+-/i.test(t)) || mds.find((t) => /2-WORKING\//.test(t)) || mds[0];
   344	  return pick.replace(/#.*$/, "");
   345	}
   346	function slugOf(docRel, title) {
   347	  const base = docRel ? path.basename(docRel, ".md") : title;
   348	  return base.toLowerCase().replace(/[^a-z0-9]+/g, "-").replace(/^-+|-+$/g, "") || "item";
   349	}
   350	function zoneOf(contract, item) {
   351	  // Proven zone from the contract write-set; else keyword-inferred (flagged zone-inferred).
   352	  if (contract && Array.isArray(contract.artifacts)) {
   353	    const arts = contract.artifacts;
   354	    const orchOnly = (contract.lanes && contract.lanes.orchestrator_only) || [];
   355	    // Zone is derived from the WRITE-SET (artifacts) only. orchestrator_only is a guardrail — paths the
   356	    // lane must NOT touch — so it never adds to the write-set; it only reclassifies an artifact that
   357	    // falls UNDER an orchestrator_only prefix as kernel-owned. (Unioning it in wrongly serialized any
   358	    // shim whose contract merely names relay-turn-lib.sh as off-limits.)
   359	    const touchesKernel = arts.some(
   360	      (a) => KERNEL_PATHS.some((k) => a === k || a.startsWith(k)) ||
   361	             orchOnly.some((o) => a === o || a.startsWith(o))
   362	    );
   363	    if (touchesKernel) return { zone: "kernel", inferred: false, writeset: arts };
   364	    if (arts.some((a) => SHIM_RE.test(a))) return { zone: "shim", inferred: false, writeset: arts };
   365	    return { zone: "independent", inferred: false, writeset: arts };
   366	  }
   367	  const hay = (item.title + " " + item.raw).toLowerCase();
   368	  if (/relay-turn-lib|containment kernel|bin\/tick|relay-drive|commit semantics|epoch fenc/.test(hay))
   369	    return { zone: "kernel", inferred: true, writeset: [] };
   370	  if (/-turn\.sh|consult\.sh|\bshim\b/.test(hay))
   371	    return { zone: "shim", inferred: true, writeset: [] };
   372	  return { zone: "independent", inferred: true, writeset: [] };
   373	}
   374	function depsOf(item) {
   375	  const deps = new Set();
   376	  // Match a dependency keyword followed by a LIST of issue refs (comma/and/&/slash separated), so
   377	  // "after GH-29, GH-30 and #31" yields all three. The list stops at the first non-issue token, so
   378	  // "after GH-29 the fix landed" still yields only 29 (no over-capture).
   379	  // Separator between refs is a RUN of comma/&//conjunction tokens (zero-or-more), so a compound
   380	  // separator like ", and" / ", & " / "and/or" is consumed and the following ref is still captured
   381	  // ("GH-100, GH-101, and GH-102" ⇒ all three). Each token consumes ≥1 char, so the `*` can't loop.
   382	  const re = /(?:after|once|depends on|gated on|blocked by)\s+((?:(?:GH-|#)\d+(?:\s*(?:,|&|\/|and|or)\s*)*)+)/gi;
   383	  let m;
   384	  while ((m = re.exec(item.raw)) !== null) {
   385	    let n; const num = /(?:GH-|#)(\d+)/g;
   386	    while ((n = num.exec(m[1])) !== null) deps.add(Number(n[1]));
   387	  }
   388	  return [...deps];
   389	}
   390	function isGoGated(item) {

exec
/bin/zsh -lc "nl -ba utils/marathon-plan.sh | sed -n '635,705p'" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-79403-29214
 succeeded in 0ms:
   635	    }
   636	  }
   637	}
   638	
   639	// ── scoring (printed per item; deterministic) ─────────────────────────────────
   640	const W = { eff: 2, cx: 1, risk: 2, dep: 3, zone: 1 };
   641	const RISK_SIGN = POLICY === "derisk-first" ? -1 : 1;
   642	const RISK_W = POLICY === "derisk-first" ? 4 : W.risk;
   643	const ZONE_PEN = { independent: 0, shim: 1, kernel: 2 };
   644	function scoreOf(r) {
   645	  // Held-but-scored (gated) items get the GO penalty so they sort after active work but keep a
   646	  // sensible relative order. Only items with full ratings are scored; others are held out.
   647	  if (!r.rated) return null;
   648	  let s = W.eff * r.ratings.effort + W.cx * r.ratings.complexity + RISK_SIGN * RISK_W * r.ratings.risk;
   649	  s += W.dep * r.deps.length + W.zone * ZONE_PEN[r.zone];
   650	  if (r.state === "gated") s += 100;
   651	  return s;
   652	}
   653	for (const r of deduped) r.score = scoreOf(r);
   654	
   655	// ── wave packing (collision-safe; ≤1 kernel item per wave; deps push later) ───
   656	const active = deduped.filter((r) => r.state === "ready").sort((a, b) => {
   657	  if (a.score !== b.score) return a.score - b.score;
   658	  if (a.deps.length !== b.deps.length) return a.deps.length - b.deps.length;
   659	  const zr = { independent: 0, shim: 1, kernel: 2 };
   660	  if (zr[a.zone] !== zr[b.zone]) return zr[a.zone] - zr[b.zone];
   661	  if ((a.gh || 1e9) !== (b.gh || 1e9)) return (a.gh || 1e9) - (b.gh || 1e9);
   662	  return a.slug < b.slug ? -1 : a.slug > b.slug ? 1 : 0;
   663	});
   664	
   665	const waves = [];
   666	const placedIssue = new Map(); // gh issue → wave index it landed in (for dep ordering)
   667	const pending = active.slice();
   668	let guard = 0;
   669	while (pending.length && guard++ < 100) {
   670	  const wave = [];
   671	  const waveWriteset = new Set();
   672	  let kernelTaken = false;
   673	  const deferred = [];
   674	  for (const r of pending) {
   675	    // dependency: a dep is satisfied only if it is genuinely resolved (done/landed/closed/out-of-scope)
   676	    // OR already placed in an earlier wave. A dep that is merely HELD (unrated/needs-contract/gated) is
   677	    // NOT in `active` but is also not built — so it must still block its dependent (agy QA [Blocker]).
   678	    const depUnmet = r.deps.some((d) => {
   679	      const dep = deduped.find((x) => x.gh === d);
   680	      if (!dep || DEP_RESOLVED.has(dep.state)) return false;
   681	      return !placedIssue.has(d);
   682	    });
   683	    const collides = r.writeset.some((p) => waveWriteset.has(p));
   684	    const kernelClash = r.zone === "kernel" && kernelTaken;
   685	    // zone-inferred shim items (no proven write-set) conservatively can't share a wave with another shim.
   686	    const inferredShimClash = r.zone === "shim" && r.zoneInferred && wave.some((w) => w.zone === "shim");
   687	    if (depUnmet || collides || kernelClash || inferredShimClash) { deferred.push(r); continue; }
   688	    wave.push(r);
   689	    r.writeset.forEach((p) => waveWriteset.add(p));
   690	    if (r.zone === "kernel") kernelTaken = true;
   691	  }
   692	  if (wave.length === 0) { // unbreakable dep cycle / all deferred — flush remainder to its own wave
   693	    waves.push(deferred); deferred.forEach((r) => { if (r.gh != null) placedIssue.set(r.gh, waves.length - 1); });
   694	    break;
   695	  }
   696	  waves.push(wave);
   697	  wave.forEach((r) => { if (r.gh != null) placedIssue.set(r.gh, waves.length - 1); });
   698	  pending.length = 0; pending.push(...deferred);
   699	}
   700	waves.forEach((w, i) => w.forEach((r) => (r.wave = i + 1)));
   701	
   702	// GH-5: within each wave, flag pairs of write-disjoint lanes that share a directory spine — they
   703	// likely share a contract seam. Advisory (never re-waves them): the fix is to pin a contract, after
   704	// which they run parallel safely. Only lanes with a PROVEN write-set (from a contract) are judged.
   705	const contractSeams = [];

mcp: codebase-memory-mcp/search_graph started
mcp: codebase-memory-mcp/search_graph (failed)
user cancelled MCP tool call
codex
I’ve confirmed the current hardcoded semantics in `zoneOf()` and the wave packer. I’m checking the surrounding CLI/config patterns and the repo’s own cross-repo guidance next, because the main risk now is operator surprise rather than algorithm shape.
exec
/bin/zsh -lc "nl -ba utils/marathon-plan.sh | sed -n '1,130p'" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-79403-29214
 succeeded in 0ms:
     1	#!/usr/bin/env bash
     2	# utils/marathon-plan.sh — deterministic "pre-pre-flight" queue planner.
     3	#
     4	# Reads the canonical ROADMAP.md ledger (a queue of work: GitHub issues + PROJECT/**.md docs),
     5	# validates each item is still real (not already fixed / silently half-done), factors in the PDDA
     6	# complexity/risk/effort ratings, and emits TWO artifacts:
     7	#
     8	#   1. a VALIDATION / DRIFT REPORT on stdout — deterministic signals, each a FLAG for a human,
     9	#      never an auto-fix (already-closed / already-landed / undocumented-partial / drift / unrated);
    10	#   2. a SEQUENCED marathon-plan doc  PROJECT/2-WORKING/MARATHON-PLAN-YYYY-MM-DD.md — ratings-ranked, collision-lane
    11	#      aware, reproducing the shape of the hand-authored QUEUE-2026-06-27.md.
    12	#
    13	# It is the stage BEFORE utils/swarm-preflight.sh (which is per-item readiness). Overlap is intended:
    14	# this planner REUSES swarm-preflight's contract shape + probe semantics, and can DELEGATE to it
    15	# per-item with --deep. The planner is a PRODUCER of a plan; it never executes a marathon
    16	# (GUIDING-PRINCIPLES.md §8 — the operator decides).
    17	#
    18	# Determinism: the score for every item is printed alongside its inputs so any ordering is
    19	# reproducible by hand. Same ledger + same ratings + same NOW/TODAY ⇒ byte-identical output
    20	# (so --check works as a drift guard in validate.sh, mirroring roadmap-dashboard.sh --check).
    21	#
    22	# Usage:
    23	#   utils/marathon-plan.sh                         # report on stdout + write today's marathon-plan doc
    24	#   utils/marathon-plan.sh --dry-run               # report only; write nothing
    25	#   utils/marathon-plan.sh --check                 # exit non-zero if today's marathon-plan doc is out of sync
    26	#   utils/marathon-plan.sh --policy derisk-first   # high-risk work sorts earlier (default: quick-wins)
    27	#   utils/marathon-plan.sh --deep                  # also delegate to swarm-preflight --dry-run per item
    28	#   utils/marathon-plan.sh --format json           # findings as JSON lines (pdda finding shape)
    29	#
    30	# Exit: 0 clean · 2 usage · 3 ROADMAP missing/unparseable ·
    31	#       4 emitted, drift present (already-landed/closed — reconcile the ledger) ·
    32	#       5 emitted, items held out of sequencing (unrated / note-only / not-ready) ·
    33	#       6 gh required but unavailable (--require-gh only).
    34	#
    35	# Test seam (all optional; unset in production):
    36	#   QUEUE_PLAN_ROOT / QUEUE_PLAN_ROADMAP / QUEUE_PLAN_QUEUE_DIR / QUEUE_PLAN_NOW / QUEUE_PLAN_TODAY
    37	#   QUEUE_PLAN_GH_STATE_FILE   JSON map {"24":"CLOSED",...} used instead of calling `gh` (hermetic)
    38	#   QUEUE_PLAN_BRANCHES_FILE   newline list of branch names used instead of calling `git branch`
    39	#   QUEUE_PLAN_GH              force gh mode: off|stub (off ⇒ gh-unverified; stub needs *_STATE_FILE)
    40	
    41	set -uo pipefail
    42	
    43	HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    44	# Vendored install: HERE is <target>/.xyz/utils → parent is .xyz → target root is grandparent.
    45	_here_parent="$(cd "$HERE/.." && pwd)"
    46	if [ "$(basename "$_here_parent")" = ".xyz" ]; then
    47	  ROOT="${QUEUE_PLAN_ROOT:-"$(cd "$_here_parent/.." && pwd)"}"
    48	  _SP_CMD=".xyz/utils/swarm-preflight.sh"
    49	  _MD_CMD=".xyz/relay-automation/marathon-drive.sh"
    50	  _MP_CMD=".xyz/utils/marathon-plan.sh"
    51	else
    52	  ROOT="${QUEUE_PLAN_ROOT:-"$_here_parent"}"
    53	  _SP_CMD="utils/swarm-preflight.sh"
    54	  _MD_CMD="relay-automation/marathon-drive.sh"
    55	  _MP_CMD="utils/marathon-plan.sh"
    56	fi
    57	ROADMAP="${QUEUE_PLAN_ROADMAP:-"$ROOT/ROADMAP.md"}"
    58	QUEUE_DIR="${QUEUE_PLAN_QUEUE_DIR:-"$ROOT/PROJECT/2-WORKING"}"
    59	NOW="${QUEUE_PLAN_NOW:-"$(date -u +%Y-%m-%dT%H:%M:%SZ)"}"
    60	TODAY="${QUEUE_PLAN_TODAY:-"$(date -u +%Y-%m-%d)"}"
    61	
    62	die()  { printf 'marathon-plan: %s\n' "$*" >&2; exit 2; }
    63	emit() { printf '%s\n' "$*" >&2; }
    64	
    65	usage() {
    66	  cat <<'EOF'
    67	Usage: utils/marathon-plan.sh [--dry-run | --check] [--policy quick-wins|derisk-first]
    68	                           [--deep] [--require-gh] [--format text|json]
    69	
    70	  (default)        Print the validation report and write PROJECT/2-WORKING/MARATHON-PLAN-<today>.md.
    71	  --dry-run        Print the report; write no marathon-plan doc.
    72	  --check          Re-render and compare against today's marathon-plan doc; non-zero on drift. Writes nothing.
    73	  --policy P       quick-wins (default; momentum, low-cost first) | derisk-first (high-risk first).
    74	  --deep           Additionally delegate to utils/swarm-preflight.sh --dry-run per ready item
    75	                   (authoritative ref-based freshness/probe verdict; slower, needs network).
    76	  --require-gh     Treat an unavailable/offline `gh` as a hard error (exit 6) instead of degrading.
    77	  --format F       text (default) | json (findings as one JSON object per line).
    78	
    79	Exit: 0 clean · 2 usage · 3 ROADMAP unparseable · 4 drift present · 5 items held · 6 gh required-but-absent.
    80	EOF
    81	}
    82	
    83	POLICY="quick-wins"
    84	FORMAT="text"
    85	RUN_MODE="write"     # write | dry-run | check
    86	DEEP=0
    87	REQUIRE_GH=0
    88	
    89	while (($# > 0)); do
    90	  case "$1" in
    91	    --dry-run)    RUN_MODE="dry-run"; shift ;;
    92	    --check)      RUN_MODE="check"; shift ;;
    93	    --policy)     POLICY="${2:-}"; shift 2 ;;
    94	    --deep)       DEEP=1; shift ;;
    95	    --require-gh) REQUIRE_GH=1; shift ;;
    96	    --format)     FORMAT="${2:-}"; shift 2 ;;
    97	    --help|-h)    usage; exit 0 ;;
    98	    *)            usage; die "unknown argument: $1" ;;
    99	  esac
   100	done
   101	
   102	case "$POLICY" in quick-wins|derisk-first) ;; *) die "--policy must be 'quick-wins' or 'derisk-first'" ;; esac
   103	case "$FORMAT" in text|json) ;; *) die "--format must be 'text' or 'json'" ;; esac
   104	[[ -f "$ROADMAP" ]] || { emit "ROADMAP not found: $ROADMAP"; exit 3; }
   105	command -v node >/dev/null 2>&1 || die "node is required (Node stdlib only; no deps) but not found in PATH"
   106	
   107	TMP="$(mktemp -d "${TMPDIR:-/tmp}/marathon-plan.XXXXXX")"
   108	trap 'rm -rf "$TMP"' EXIT
   109	RENDER_OUT="$TMP/MARATHON-PLAN-$TODAY.md"
   110	QUEUE_DOC="$QUEUE_DIR/MARATHON-PLAN-$TODAY.md"
   111	
   112	# Resolve the swarm-preflight path for --deep delegation (skipped silently if absent).
   113	SWARM_PREFLIGHT="$HERE/swarm-preflight.sh"
   114	[[ "$DEEP" -eq 1 && -x "$SWARM_PREFLIGHT" ]] || SWARM_PREFLIGHT=""
   115	
   116	# One embedded Node program does the compute (parse ledger → resolve items → signals → score →
   117	# wave-pack → render). It prints the report to stdout, writes the rendered marathon-plan doc to QP_RENDER_OUT,
   118	# and exits with the flag-derived code. git/gh are reached via execSync, but the test seam env files
   119	# short-circuit them so the suite stays hermetic. CommonJS (node - <<'NODE') like roadmap-dashboard.sh.
   120	QP_ROOT="$ROOT" QP_ROADMAP="$ROADMAP" QP_QUEUE_DIR="$QUEUE_DIR" \
   121	QP_TODAY="$TODAY" QP_NOW="$NOW" QP_POLICY="$POLICY" QP_FORMAT="$FORMAT" \
   122	QP_DEEP="$DEEP" QP_REQUIRE_GH="$REQUIRE_GH" QP_SWARM_PREFLIGHT="$SWARM_PREFLIGHT" \
   123	QP_SP_CMD="$_SP_CMD" QP_MD_CMD="$_MD_CMD" QP_MP_CMD="$_MP_CMD" \
   124	QP_RENDER_OUT="$RENDER_OUT" \
   125	QP_GH_STATE_FILE="${QUEUE_PLAN_GH_STATE_FILE:-}" QP_BRANCHES_FILE="${QUEUE_PLAN_BRANCHES_FILE:-}" \
   126	QP_GH_FORCE="${QUEUE_PLAN_GH:-}" QP_BASE_FILES_FILE="${QUEUE_PLAN_BASE_FILES_FILE:-}" \
   127	node - <<'NODE'
   128	"use strict";
   129	const fs = require("fs");
   130	const path = require("path");

exec
/bin/zsh -lc 'rg -n "QP_[A-Z_]+|target-root|QP_GH_STATE_FILE|QP_BRANCHES_FILE|QP_BASE_FILES_FILE|QP_.*FILE|argv|parse" utils/marathon-plan.sh' in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-79403-29214
exec
/bin/zsh -lc 'rg -n "swarm-preflight|target-root|rebalance|foreign|cross-repo|contract" ROADMAP.md PROJECT/4-MISC/QUEUE-2026-06-27.md PROJECT/2-WORKING/GH-48-QUEUE-PLAN-CROSS-REPO-ZONES.md' in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-79403-29214
 succeeded in 0ms:
30:# Exit: 0 clean · 2 usage · 3 ROADMAP missing/unparseable ·
79:Exit: 0 clean · 2 usage · 3 ROADMAP unparseable · 4 drift present · 5 items held · 6 gh required-but-absent.
116:# One embedded Node program does the compute (parse ledger → resolve items → signals → score →
117:# wave-pack → render). It prints the report to stdout, writes the rendered marathon-plan doc to QP_RENDER_OUT,
120:QP_ROOT="$ROOT" QP_ROADMAP="$ROADMAP" QP_QUEUE_DIR="$QUEUE_DIR" \
121:QP_TODAY="$TODAY" QP_NOW="$NOW" QP_POLICY="$POLICY" QP_FORMAT="$FORMAT" \
122:QP_DEEP="$DEEP" QP_REQUIRE_GH="$REQUIRE_GH" QP_SWARM_PREFLIGHT="$SWARM_PREFLIGHT" \
123:QP_SP_CMD="$_SP_CMD" QP_MD_CMD="$_MD_CMD" QP_MP_CMD="$_MP_CMD" \
124:QP_RENDER_OUT="$RENDER_OUT" \
125:QP_GH_STATE_FILE="${QUEUE_PLAN_GH_STATE_FILE:-}" QP_BRANCHES_FILE="${QUEUE_PLAN_BRANCHES_FILE:-}" \
126:QP_GH_FORCE="${QUEUE_PLAN_GH:-}" QP_BASE_FILES_FILE="${QUEUE_PLAN_BASE_FILES_FILE:-}" \
134:const ROOT = E.QP_ROOT;
135:const TODAY = E.QP_TODAY;
136:const NOW = E.QP_NOW;
137:const POLICY = E.QP_POLICY;
138:const FORMAT = E.QP_FORMAT;
139:const DEEP = E.QP_DEEP === "1";
140:const REQUIRE_GH = E.QP_REQUIRE_GH === "1";
141:const SWARM_PREFLIGHT = E.QP_SWARM_PREFLIGHT || "";
142:const SP_CMD = E.QP_SP_CMD || "utils/swarm-preflight.sh";
143:const MD_CMD = E.QP_MD_CMD || "relay-automation/marathon-drive.sh";
144:const MP_CMD = E.QP_MP_CMD || "utils/marathon-plan.sh";
145:const BASE_FILES_FILE = E.QP_BASE_FILES_FILE || "";
211:// utils/swarm-preflight.sh reads. Returns the parsed object or null (planner degrades, never dies).
227:  try { return JSON.parse(lines.slice(start, end).join("\n")); } catch { return null; }
253:  if (E.QP_BRANCHES_FILE) {
254:    BRANCHES = (readFileSafe(E.QP_BRANCHES_FILE) || "").split(/\r?\n/).map((s) => s.trim()).filter(Boolean);
271:  if (E.QP_GH_FORCE === "off") { GH_MODE = "off"; return; }
272:  if (E.QP_GH_STATE_FILE) {
273:    try { GH_STATE = JSON.parse(readFileSafe(E.QP_GH_STATE_FILE) || "{}"); GH_MODE = "stub"; return; } catch { GH_MODE = "off"; return; }
288:// ── ledger parse (the parser lifted + extended from roadmap-dashboard.sh) ──────
293:function parseBullet(block, section) {
305:function parseLedger(raw) {
322:    out.push(parseBullet(block, current));
432:const L = (x) => { const n = parseInt(String(x == null ? "" : x).trim(), 10); return n >= 1 && n <= 5 ? n : null; };
441:const raw = readFileSafe(E.QP_ROADMAP);
443:const ledger = parseLedger(raw);
444:if (ledger.length === 0) { process.stderr.write("marathon-plan: no ledger items parsed (is '## Ledger' present?)\n"); process.exit(3); }
566:  for (const full of listMdRecursive(E.QP_QUEUE_DIR)) {
746:  if (GH_MODE === "off") out.push(`  NOTE gh ${E.QP_GH_FORCE === "off" ? "disabled" : "unavailable"}: open/closed state not verified — relying on ledger section only`);
904:fs.writeFileSync(E.QP_RENDER_OUT, renderQueueDoc());
909:# Node failed hard (parse error / exit 3) — pass the code straight through.

 succeeded in 0ms:
PROJECT/4-MISC/QUEUE-2026-06-27.md:27:| **GH-29 (Wave 1 lead) shipped inline 2026-06-27** — the kernel commit-path unblock is done (`validate.sh` 54/54), so cross-repo dogfooding is no longer gated. Remaining open work is grouped into collision-safe lanes: the `relay-turn-lib.sh` containment kernel is the single serialization bottleneck; kernel lanes (GH-33 P3–4 → GH-30 → GH-13/14/3) run one-at-a-time, shims (GH-37/36/23) and independent lanes (GH-24/27/19, Part B chaos, front-door) fan out. | **Fire the rest of Wave 1** — `GH-37` ‖ `GH-36p` ‖ `GH-24` ‖ Part B chaos (now all disjoint, no kernel lane among them) via `swarm-preflight` → `marathon-drive`, scoped by `ALLOW_PATHS`. Each first needs a 2-WORKING capture doc + preflight contract. Re-derive waves when ledger priorities shift. |
PROJECT/4-MISC/QUEUE-2026-06-27.md:32:collision-free claim/heartbeat machinery (`tick`, `swarm-preflight`, `ALLOW_PATHS`,
PROJECT/4-MISC/QUEUE-2026-06-27.md:59:1. **GH-29 — cross-repo new-file commit gap** ✅ **DONE 2026-06-27** (per-path `git add -A`; `validate.sh` 54/54). The unblock is shipped. → [#29](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/29)
PROJECT/4-MISC/QUEUE-2026-06-27.md:67:- **GH-37 — agy consult auth hang** ✅ **preflight-ready** (`swarm-preflight --gh-issue 37` → ready) → `relay-automation/consult.sh`: fast pre-flight auth probe, skip the lane in seconds instead of a 300s hang. **Builder = Codex** (agy can't build its own auth fix). → [#37](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/37)
PROJECT/4-MISC/QUEUE-2026-06-27.md:74:- **GH-24 — relay telemetry extractor**: ⚠️ **NOT a build lane** — the script (`utils/telemetry/extract-relay-telemetry.sh`) already exists, so `swarm-preflight` would exit 4 (already-landed). This is a **verify-and-close**: run it against live `relay-system/`, eyeball the aggregated output, then close #24. Do it inline, not via marathon. → [#24](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/24)
PROJECT/4-MISC/QUEUE-2026-06-27.md:97:utils/swarm-preflight.sh --project-doc <PROJECT/**/doc.md>   # or --issues "#29"
ROADMAP.md:28:> gates, deep notes) lives in the linked `PROJECT/**` docs; keep it there. See the contract banner above.
ROADMAP.md:33:- **Part B — Adversarial Hardening:** epoch fencing (done) → chaos suite → cross-repo E2E → reference deploy
ROADMAP.md:40:| **2026-07-03 portability + marathon sweep:** **GH-104 portability fix** (`a17ef13`) — `utils/` vendored, tool-root separated from target-root in all three entrypoints, generated-doc paths install-aware, collision-safety test added; #104 closed. **Also shipped 2026-07-03 (marathon Wave 1):** **GH-5** contract-seam warning, **GH-4** work-stealing verdict, **GH-3** parked-claim false-positive, **GH-88** cross-repo monitor, **GH-63** signal triage, **GH-44** scratch-repo helper, **GH-77** Aider lane, **GH-78** doc preflight, **GH-45** attempt cap, **GH-41** terminality seal, **GH-30 Phase 1** transcript-root resolver (`XYZ_ARCHIVE_ROOT`, default-off). `validate.sh` **89/89** (also fixed a pre-existing `xyz-vendor.sh` typo red). | **Still open:** **GH-61 Tier 2** (needs operator `macos-latest`/`ubuntu-latest` runner decision). **Operator-driven:** **rebalance-OS cross-repo dogfood** (unblocked since GH-51). **Part B:** G2 dup-token determinism (next adversarial-hardening slice). **Queue / parked:** GH-87 deep research, GH-86 review-lane surface, **GH-30 Phases 2–5** (writer wiring + risk-4 containment), GH-48 cross-repo zone model. |
ROADMAP.md:44:1. ✅ **Done — GH-51 [1-kernel] fixed (2026-06-30).** `rtl_init` now collapses a same-repo `--target-root` to the caller's root (no-op), so `--target-root .` no longer reverts the relay file off-lane. Decision record + regression test; `validate.sh` 69/69. The remaining GH-51 items ([2]/[3]/[5]) are minor. → [#51](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/51)
ROADMAP.md:45:2. **Re-open the rebalance-OS cross-repo harness dogfood — now UNBLOCKED** (GH-51 [1-kernel] landed). Converts the #14 fix into a real external-repo proof: drive a scoped rebalance-OS lane via `swarm-preflight --target-root <clone> → marathon-drive`. The highest-value momentum test now that `--target-root` is containment-correct.
ROADMAP.md:46:3. **[GH-48-QUEUE-PLAN-CROSS-REPO-ZONES.md](PROJECT/2-WORKING/GH-48-QUEUE-PLAN-CROSS-REPO-ZONES.md) design committed 2026-07-04, awaiting `/consult` (Agy + Codex) before build.** Live rebalance-dogfood validation stays Phase 2 of that design, not a precondition to starting. (Planner generalization is useful but not the unblocker; per-lane `swarm-preflight` already works today.)
ROADMAP.md:73:- **GH-112 · Spike: progressive Python port — boundary decision + dogfood architecture** 🆕 **captured 2026-07-03 · rated** — one spike lane answers three questions before any port work is queued: (1) what stays Bash permanently (source-dep graph of relay-turn-lib.sh), (2) Option A (discrete Python CLIs behind Bash shims, safest) vs Option B (Python orchestrator with Bash FFI, higher payoff), (3) test-bridge contract (85 shell tests must stay green during transition). If boundary is clean → one follow-up issue per turn script, marathon-waveable. Deliverable: a `decisions/` record, not code. cx/risk/eff 3/3/2. → [GH-112-PYTHON-PORT-SPIKE.md](PROJECT/1-INBOX/GH-112-PYTHON-PORT-SPIKE.md) · [#112](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/112)
ROADMAP.md:81:- **GH-30 · optional centralized transcript archive** ✅ **ALL PHASES SHIPPED 2026-07-03 (Plan A lane 5 complete)** — optional `XYZ_ARCHIVE_ROOT` redirects relay/consult/marathon transcripts out of each foreign repo's `relay-system/` into one namespaced archive; default unset = byte-for-byte current. **Phases 1–2:** single resolver `rtl_transcript_root` + `rtl_repo_slug` in `relay-turn-lib.sh` (Model-A validation: absolute + exists + git repo, else HARD ERROR), and all writers derive their transcript base from it. **Phase 3 (Model A, risk-4 core):** `rtl_init` flags `RTL_ARCHIVE_MODE` when the relay file's git repo ≠ `RTL_ROOT`, and `rtl_enforce` commits the **transcript into the archive** via an isolated `git -C` pathspec commit while the **code artifact + `.tick` token stay on the target** — target tree free of `relay-system/`, no transcript commit in target history, and the isolated archive commit can never orphan a concurrent peer commit (GH-13 guard target-only, holds when token-tree ≠ transcript-tree). **Phase 4:** `extract-relay-telemetry.sh` reads the resolver, aggregating across all `<repo-slug>/` dirs. **Phase 5:** `new-relay.sh` wired; `CONSUMING.md` + `README.md` document the contract; CHANGELOG bet recorded. New `test/archive-commit.sh` (16) + `test/archive-telemetry.sh` (3) → `validate.sh` green. cx/risk/eff 3/4/3. Kernel lane (`relay-turn-lib.sh`). → [GH-30-CENTRALIZED-TRANSCRIPT-ARCHIVE.md](PROJECT/3-COMPLETED/GH-30-CENTRALIZED-TRANSCRIPT-ARCHIVE.md) · [#30](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/30)
ROADMAP.md:82:- **Marathon dogfood · rebalance-OS parallel build queue (cross-repo, `--target-root`)** 🆕 **captured 2026-06-28** — **orchestrate this from Claude Code in THIS repo** as a real cross-repo dogfood: drive the rebalance-OS build queue (`PROJECT/4-MISC/QUEUE-2026-06-27.md` in that repo) via `swarm-preflight → marathon-drive --target-root <rebalance-OS clone>`. It has **3 collision-free lanes**: **SWIFT-APP** (Focus5Float VS Code focus-if-open Phase 1, claim `macOS/Apps/Focus5Float/Sources/**`), **BACKEND** (Unified Refresh/Restart v1 — signed Reminders helper + pulse server, claim `scripts/**`), **SPIKE** (Focus 5 App Store Phase 0, new `macOS/Apps/Focus5Native/**`). Disjoint write-globs ⇒ XYZ-safe concurrently. Per-lane gates differ (`swift build`+`FOCUS5_SELFTEST=1` / `pytest`+live `/api/refresh` / spike build); the *verify-and-archive* items finish on an **operator GUI litmus** (no CLI agent can satisfy a LaunchServices GUI check). Do not touch rebalance-OS outside an explicit, scoped lane run. **Status 2026-06-29: Lane A (Focus5Float VS Code focus-if-open) shipped INLINE — built by hand, NOT via the harness, since the marathon builder lane was then blocked by #14 — and pushed to rebalance `feat/apple-reminders-write`. Lanes B (refresh/restart v1) + C (App Store spike) handed to Agy (its app, direct in rebalance); the archive sweep is operator GUI-litmus. #14 is now fixed. **Status 2026-07-01: UNBLOCKED — GH-51 [1-kernel] closed 2026-06-30; `--target-root` containment normalization is fixed. Deferral condition met. Fire one scoped lane as the cross-repo proof.**
ROADMAP.md:83:- **GH-48 · generalize marathon-plan's zone model for cross-repo pre-pre-flight** 🔨 **design committed 2026-07-04, awaiting `/consult` before build** — `marathon-plan`'s swarm-vs-serialize classifier (`zoneOf()`) is hardcoded to xyz's own files (`relay-turn-lib`/`bin/tick`/`*-turn.sh`), even for contract-backed items (the proven-zone branch still runs the write-set through xyz-specific `KERNEL_PATHS`/`SHIM_RE`) — so idea #2 ("contract-only mode") alone would not have fixed the rebalance-OS case. Committed instead to idea #1: a configurable zone-rules list (path prefixes/regex + `maxPerWave` + `conservativeWhenInferred` + `penalty`), default = xyz's exact current values (zero regression). Idea #3 (foreign ledger/queue-format adapter) explicitly deferred. Acceptance gate is a live run against the real rebalance-OS 3-lane queue (Phase 2), not a synthetic fixture. → [GH-48-QUEUE-PLAN-CROSS-REPO-ZONES.md](PROJECT/2-WORKING/GH-48-QUEUE-PLAN-CROSS-REPO-ZONES.md) · [#48](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/48)
ROADMAP.md:84:- **Dueling/relay · commit-signal advance (file-driven mode)** 🟡 — **built + tested 2026-06-26** (agy review pending): `poll.sh --turn-source file` reads whose-turn from the relay `NEXT:` field, making the tick token **optional** — exactly what the first cross-repo dueling run needed when the Maintainer Claude worked straight off the relay file and never joined `tick`. Optional `--peer-commit-repo`/`--peer-commit-match` add the "advance on the peer's fix commit" signal (idle → run-runner only once a matching commit lands). `relay_field` now tolerates `**bold**` markdown keys; STATUS terminal + artifact-scope-clean still apply. 7 new assertions in [test/poll-driver.sh](test/poll-driver.sh); `validate.sh` **48/48**. → [poll.sh](relay-automation/poll.sh) · [Field findings](PROJECT/4-MISC/AUTOMATED-RELAY.md#field-findings--first-cross-repo-dueling-run-2026-06-26)
ROADMAP.md:85:- **Dueling/relay · token resilience for a non-participating peer + multi-round reuse** 🟡 — **core addressed by `--turn-source file`** (token-optional ⇒ no `parked suspect` stall and no `spent/reserved — not claimable` mid-run, the two lock failures from 2026-06-26). Residual (only when you DO use the tick token): a non-watchdog `reap`+`claim` reconcile path (still manual) and token-reuse semantics that survive N `release --to peer` round-trips. Lower priority now that file-source is the recommended dueling path. → [AUTOMATED-RELAY.md → Field findings](PROJECT/4-MISC/AUTOMATED-RELAY.md#field-findings--first-cross-repo-dueling-run-2026-06-26)
ROADMAP.md:86:- **Gate design · convergence gates that pin a *worse* code shape** 🐞 — the KWFS `#70` gate statically extracts a literal `return array(...)` from *each* of three formatter methods and asserts equality, which makes the issue's intended fix (one canonical method + delegate/delete the duplicates) **fail the gate** — the Maintainer was forced to keep three duplicated-but-identical literals, divergence the gate calls "converged." Generalizes: static-extraction needle gates can pin a less-maintainable shape than the refactor they exist to enforce. Fix direction: assert runtime output-key equality (or canonical + delegation), not three literals. → [AUTOMATED-RELAY.md → Field findings](PROJECT/4-MISC/AUTOMATED-RELAY.md#field-findings--first-cross-repo-dueling-run-2026-06-26)
ROADMAP.md:87:- **Orchestration · in-loop gate verification must run sandbox-off** 🟡 — an orchestrator/watcher re-running a target gate (`bash tests/run.sh`) under the Claude Bash sandbox **false-fails** (PHP can't create lock files → bogus "syntax errors"); the peer's un-sandboxed run is authoritative. Handle: in-loop gate self-checks run sandbox-off, or trust the peer's run + spot-confirm sandbox-off (memory: `codex-cli-needs-sandbox-disabled` family). → [AUTOMATED-RELAY.md → Field findings](PROJECT/4-MISC/AUTOMATED-RELAY.md#field-findings--first-cross-repo-dueling-run-2026-06-26)
ROADMAP.md:89:- **Tooling · front-door onboarding health** 🟡 parked — read-only audit shipped → [FRONTDOOR.md](PROJECT/4-MISC/FRONTDOOR.md) (continuous deterministic dashboard; 10 findings, re-runnable checks) + a phased remediation plan. Verdict ⚠️ Bumpy: clone-to-working works (`validate.sh` 36/36, secrets clean), but stale test counts (3 docs) + 2 dead README links + a phantom-path `CLAUDE.md` + undocumented `--target-root`/`install.sh` remain. Phases 1–3 queued (doc-only). → [FRONT-DOOR/2026-06-22.md](PROJECT/1-INBOX/FRONT-DOOR/2026-06-22.md)
ROADMAP.md:90:- **PDDA · feedback-synthesis direction** 🟡 parked — **proposal (1-INBOX), agy-reviewed 2026-06-23**: reduces the three June 23 external feedback notes (Perplexity/ChatGPT/Gemini) to one direction — keep PDDA a *thin repo-governance + safety layer*. Near-term scope = Phases 1–2 (constitution/positioning + contract/mode hardening); Phases 3–5 (artifact ergonomics, the Perplexity-only evidence bridge, integrations) deferred. Relay-reviewed by agy: 1 Blocker + 3 Should applied → **Approved**. Awaiting promotion decision to `2-WORKING`. → [PDDA-FEEDBACK-SYNTHESIS-PLAN.md](PROJECT/1-INBOX/PDDA/PDDA-FEEDBACK-SYNTHESIS-PLAN.md) · relay [pdda-feedback-synthesis.md](relay-system/2026-06-23/pdda-feedback-synthesis.md)
ROADMAP.md:94:- **Tooling · PDDA runtime consolidation (upgrade)** ✅ **2026-06-30** — migrated this repo off its old split PDDA (`utils/pdda-run.sh` + 11 flat `pdda-check-*.sh`) onto the upstream single-dispatcher runtime (`utils/pdda/pdda.sh`, installed by `pdda/install.sh`). Adopted the upstream **integer `1`–`5`** triage-ratings contract (was `low|medium|high`): rewrote all 25 rated docs (`low→2/med→3/high→4`, order-preserving), updated `marathon-plan.sh` + its test; **dropped** `pdda-check-ratings.sh` (its enforcement now folded into `pdda.sh frontmatter` + `marathon-plan`'s unrated detection). Rewired hooks/gate-test/operator-docs; removed 12 flat files; kept repo-specific tooling. Gates green: `pdda.sh run` full-mode 0 errors, `test/marathon-plan.sh` 31/31, `validate.sh` 0. → [decision](decisions/2026-06-30-pdda-runtime-consolidation.md) · [PDDA-RUNTIME-CONSOLIDATION-MIGRATION.md](PROJECT/2-WORKING/PDDA-RUNTIME-CONSOLIDATION-MIGRATION.md)
ROADMAP.md:95:- **Part B — Adversarial hardening** ⚠️ — Phase 1 (epoch fencing) shipped; Phase 2 chaos-suite *detection* partials landed; Phases 2–4 are the active "adversarially proven → commercially viable" frontier. Immediate next-up: promote exactly one proof-sized Phase-2 slice into a contract-backed lane (important because Part B only keeps momentum if it advances in small, verifiable proofs instead of reopening the whole frontier at once). → [ADVERSARIAL-HARDENING.md](PROJECT/2-WORKING/ADVERSARIAL-HARDENING.md)
ROADMAP.md:96:- **Tooling · relay-to-issue skill** 🟡 — **shipped 2026-06-22**: a post-relay skill that distills a closed `/relay` thread into ONE checklist-style GitHub issue, filed in the repo the relay was *about* (cross-repo aware; dedup-stamped; auto-posts via `gh`). `skills/relay-to-issue/` (SKILL + `relay-to-issue.sh` + `install.sh`); `resolve` smoke-tested green. Remaining: operator `install.sh` + one un-sandboxed live `gh issue create` to confirm posting E2E. → [RELAY-TO-ISSUE-SKILL.md](PROJECT/2-WORKING/RELAY-TO-ISSUE-SKILL.md)
ROADMAP.md:99:- **GH-104 · Full-library portability + full-mirror vendor install** ✅ **SHIPPED 2026-07-03 (`5972ef4` + portability fix `a17ef13`)** — two-part close: **(1)** original full-mirror (`5972ef4`) replaced the drift-prone `make-pkg.sh` manifest with a complete directory mirror (`relay-automation/ bin/ src/ test/ skills/`); **(2)** portability fix (`a17ef13`) closed three remaining gaps: `utils/` added to `VENDOR_DIRS` (ships `swarm-preflight.sh`, `marathon-plan.sh`, `telemetry/`); tool-root separated from target-root in all three entrypoints (`swarm-preflight.sh`, `marathon-plan.sh`, `marathon-drive.sh` — `_here_parent`/`_xyz_harness` detection sets `ROOT` = target repo while `TICK_BIN`/`XYZ_APPEND_BIN` stay anchored to `.xyz/`); generated-doc paths (`packet.md` invocation, marathon-plan "How to fire a lane") now emit `.xyz/`-prefixed commands for vendored installs. `test/xyz-vendor.sh` gains `utils/` mirror check + collision-safety fixture (target `src/`/`utils/`/`bin/` untouched). Remaining separate follow-up: `install.sh`/`relay-pkg.tar.gz` still on stale manifest. → [#104](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/104)
ROADMAP.md:100:- **GH-5 · Contract-seam warning for coupled lanes** ✅ **SHIPPED 2026-07-03 (Plan A lane 4)** — the one thing that made two lanes actually independent in the real run was a coordinator-pinned shared contract (both coded TO the contract, not to each other's source), but nothing detected coupling — operators found it only when an agent stalled on another lane. The wave-packer defers only on EXACT write-set collision, so two lanes writing disjoint files under a common dir (e.g. `src/schema/producer.js` ‖ `src/schema/consumer.js`) co-wave and look independent. Now `marathon-plan.sh` detects the seam (`sharedSpine`: deepest shared dir of ≥2 segments; top-level-only sharing is not a seam) and emits a **"Contract seams — pin a contract"** section naming each coupled pair + the shared dir + the fix (pin a `CONTRACT.md`, point each lane prompt at it) — making the "pin the contract" step first-class (fix 1) + the coupled-lane warning (fix 2); deferred-coupled-work (fix 3) is the existing Held/flagged section. Advisory (never re-waves). Pairs with GH-4 work-stealing (a stolen coupled task would stall). `test/marathon-plan.sh` scenario K (+3: seam flagged, disjoint-subtree not, pin-a-contract stated); 39/39. Auto-scaffold + import-graph inference deferred. cx/risk/eff 3/2/2. → [GH-5-CONTRACT-SEAM-WARNING.md](PROJECT/3-COMPLETED/GH-5-CONTRACT-SEAM-WARNING.md) · [#5](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/5)
ROADMAP.md:107:- **GH-78 · optional hourly doc-preflight (contract-enforcing auto-edits + telemetry)** ✅ **SHIPPED 2026-07-03 (`115713f`, PR #81 — agy Approved via relay-xyz review 2026-07-02; rebased onto main, churn conflicts resolved to main, `validate.sh` green)** — opt-in `utils/telemetry/preflight-docs.sh`: when `PDDA_LLM_BIN` is set it runs an LLM doc-readiness pass that may apply contract-enforcing auto-edits, gated by a deterministic safety valve (rejects edits that worsen checks or exceed 30 lines) with JSON telemetry; a no-op that never blocks when unset. Thorough offline test coverage in `test/preflight-docs.sh` (14/14). → [GH-78-DOC-PREFLIGHT-AUTOMATION.md](PROJECT/1-INBOX/GH-78-DOC-PREFLIGHT-AUTOMATION.md) · [#81](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/pull/81) · [#78](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/78)
ROADMAP.md:108:- **GH-45 · QUEUE 'must-complete' commitment contract + anti-rabbit-hole safeguard** 🐞 ✅ **SHIPPED 2026-07-03 (PR #91 — marathon; cross-model review applied)** — make a wave/lane a *commitment contract* so a session can't silently abandon the plan to deep-dive one item (the GH-39 drift). v1: AGENTS.md re-anchor+park paragraph + a per-lane attempt cap (`.tick/attempts/<lane>`, default 2, `--force` override) in `marathon-drive.sh` + mirror in `relay-drive.sh` + `test/lane-attempt-cap.sh`; cross-model review added reset-on-success + `--force` passthrough through `marathon.sh`. Phases 3–4 deferred. cx/risk/eff 3/3/3. → [GH-45-QUEUE-COMMITMENT-CONTRACT.md](PROJECT/1-INBOX/GH-45-QUEUE-COMMITMENT-CONTRACT.md) · [#91](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/pull/91) · [#45](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/45)
ROADMAP.md:113:- **GH-59 · relay-turn-lib: allowlisted artifact in an untracked dir trips spurious off-lane (exit 6)** ✅ **SHIPPED 2026-07-02 (`ac6dacb`, marathon lane — codex + agy Approved, gate 23/0)** — `rtl_in_allow` now allows a git-collapsed untracked-dir entry (`dir/`) when it is a **true ancestor** of a concrete allowlisted **file** entry (`greenfield/` ⊂ `greenfield/output.txt`), never a bare prefix (`green/` still fails) — generalizing the `.relay-artifacts` exemption; case-insensitive variant mirrored, bash-3.2. **Retires the stub-dir workaround** for greenfield-in-a-new-dir marathon lanes (the GH-61 case). [decision](decisions/2026-07-02-offlane-untracked-dir.md) records the contract + 3 invariants; `test/worktree-isolation.sh` enforces all three (greenfield-fixed / off-lane-still-rejected / no copy-back widening). `validate.sh` **80/80**. → [GH-59-OFFLANE-UNTRACKED-DIR.md](PROJECT/1-INBOX/GH-59-OFFLANE-UNTRACKED-DIR.md) · [#59](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/59)
ROADMAP.md:115:- **GH-75 · XYZ.json — final completion telemetry at relay/swarm/marathon session end** ✅ **SHIPPED 2026-07-02** — every relay/marathon/swarm harness now appends a durable, newest-first completion record to a gitignored `XYZ.json` at the harness repo root (schema: `{harness, sessionId, health, title, description, updatedAt}`). Shared `utils/telemetry/health-lib.sh` factors GH-24's STATUS/VERDICT→health mapping out of `extract-relay-telemetry.sh` (extractor output byte-identical — no GH-24 regression); shared `utils/telemetry/append-xyz-completion.sh` does a locked (GH-72 `mkdir` advisory lock — no lost update) + atomic (temp-file + `os.replace` — no corruption/partial write) read-modify-write-prepend. Wired into `relay-drive.sh`'s terminal exits (green / orange×2 / red), `marathon-drive.sh`'s own per-run hook (gated by `XYZ_HARNESS_CONTEXT`; `harness:"swarm"` when swarm-preflight's generated invocation self-propagates the tag, else `"marathon"`; silent under `marathon-phase`), and `marathon.sh`'s single whole-run record — so a `marathon.sh` N-phase run emits exactly one record, never N/N+1. New `test/xyz-completion.sh` (writer + 16-way concurrency + corrupt-file self-heal + health-lib table) and `test/xyz-harness-hooks.sh` (all harness terminal paths + nesting), plus a swarm-tag assertion in `test/swarm-preflight.sh`. `validate.sh` green. → [GH-75-XYZ-JSON-COMPLETION-TELEMETRY.md](PROJECT/1-INBOX/GH-75-XYZ-JSON-COMPLETION-TELEMETRY.md) · [#75](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/75)
ROADMAP.md:116:- **GH-69 · Marathon branch suggestion + agent confirmation prompt** ✅ **SHIPPED 2026-07-01** — marathon builds commit several times (build → gate → review) but the pipeline had no branch-cutting step; partial/failed work landed on whatever was checked out. Three-stage fix: (1) `marathon-plan.sh` emits a deterministic `suggested_branch: marathon/<slug>-<date>` per active wave lane (read-only, no git writes); (2) `swarm-preflight.sh` checks real branch existence via `git show-ref` and emits `branch_ready`/`skip_branch_prompt` in the packet (JSON + `packet.md` + text report); (3) the orchestrating-agent contract ("ask the operator before proceeding when `branch_ready: false`, unless the carve-out applies") is documented inline in `swarm-preflight.sh`'s header and self-stated in every packet's "Suggested branch" line — a driving agent doesn't need to recompute it. Carve-out (`risk: 1` + independent-zone artifacts) verified to skip the prompt; kernel-zone artifacts and non-risk-1 items correctly do NOT skip it. No branch is ever auto-created. `test/marathon-plan.sh` 34/34, `test/swarm-preflight.sh` 44/44, `validate.sh` 77/77. → [GH-69-MARATHON-BRANCH-PROMPT.md](PROJECT/1-INBOX/GH-69-MARATHON-BRANCH-PROMPT.md) · [#69](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/69)
ROADMAP.md:119:- **GH-70 · relay-xyz: per-repo harness for concurrent automated relays** ✅ **Phases 1–2 SHIPPED 2026-07-01 (`e8d9999`)** — the per-clone global driver lock (GH-42) serializes all relays sharing one harness; per-repo concurrency comes from each repo having its own vendored `.xyz/` (GH-49). **Phase 1 (doc):** SKILL.md "Concurrent relays across repos" section — `xyz-vendor.sh` (not `install.sh`) is the path to per-repo isolation; "When to use" names the case. **Phase 2 (additive):** `find-harness.sh --check` warns when a foreign repo has no local `.xyz/` (using the centralized harness + shared lock) and points at `xyz-vendor.sh`; flags a held lock; fail-open (always exit 0). `test/find-harness.sh` (8 checks); `validate.sh` 76/76. **Phase 3 deferred** (`install.sh --with-harness`) — revisit when a real user finds `xyz-vendor.sh` too indirect. → [GH-70-CONCURRENT-RELAY-LOCAL-HARNESS.md](PROJECT/1-INBOX/GH-70-CONCURRENT-RELAY-LOCAL-HARNESS.md) · [#70](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/70)
ROADMAP.md:126:- **GH-51 · marathon/swarm-preflight harness defects (GH-37 dogfood)** ✅ **CLOSED 2026-06-30** — root cause (#1 `--target-root .` off-lane false-positive) + budget-scaling (#4) shipped (`19b8736`, `validate.sh` 69/69); cross-repo dogfood unblocked. 3 minor remainders split out: **#54** (brief: forbid in-turn fs-touching tests), **#55** (swarm-preflight: auto-include a changed artifact's tests), **#56** (marathon-drive: reconcile/fresh-id a leaked tick token). → [#51](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/51)
ROADMAP.md:129:- **GH-49 · optional vendored local copy of harness scripts (WIP-decoupled fallback)** ✅ 2026-06-30 (#49) — opt-in vendored mode: `relay-automation/xyz-vendor.sh` snapshots the curated harness (16-file `relay-pkg` manifest awk-parsed from `make-pkg.sh` + `bin/tick` + `src/*.js`) into a **git-ignored `.xyz/`** in a foreign repo, pinned + version-stamped, registered in the GH-62 registry. `find-harness.sh` prefers `.xyz/` (env → `.xyz/` → current-repo → script-relative; default path byte-identical) with a **warn-loudly-continue** staleness banner (never blocks). `xyz-sync.sh` list/update/delete (dry-run unless `--yes`; closes the GH-62 follow-on). SessionStart reminder hook. **Built swarm-produced** (codex authored Phases 1/2+3/4, agy reviewed → Approved) with every edit **independently execution-verified** (GUIDING #12); `test/xyz-vendor.sh` 28 assertions in `validate.sh` (**70/70**). **Level-2 dogfood self-hosted**: the vendored `.xyz/` harness drove agy to review a foreign-repo artifact and commit file-scoped with no live clone — surfacing + fixing **2 containment-kernel gaps** (driver-lock assumed `.git/`; GH-51 collapse rooted at the `.xyz/` subdir not the toplevel; both byte-identical for a normal clone). → [decision](decisions/2026-06-30-vendored-harness-locator.md) · [GH-49-VENDORED-LOCAL-COPY.md](PROJECT/3-COMPLETED/GH-49-VENDORED-LOCAL-COPY.md) · relays [p1](relay-system/2026-06-30/gh49-phase1-vendor.md)/[p2+3](relay-system/2026-06-30/gh49-phase23-locator.md)/[p4](relay-system/2026-06-30/gh49-phase4-xyzsync.md) · [#49](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/49)
ROADMAP.md:132:- **GH-11 · relay-xyz cross-repo targeting** ✅ 2026-06-30 (#11 closed) — Ask 1 (the `--target-root` flag + `relay-turn-lib.sh` kernel wiring routing worktree/allowlist/commit via `RELAY_TARGET_ROOT`, `test/relay-target-root.sh` 7/7) shipped 2026-06-21; **Asks 2–5 swept 2026-06-30** into `skills/relay-xyz/SKILL.md` (a cross-repo subsection documenting `--target-root` + `CONSULT_ROOT` with foreign-repo examples, the `$TMPDIR` absolute-path warning, and the find-harness-solves-the-inverse note). `skill-extract` + `path-integrity` green. → [GH-11-CROSS-REPO-TARGETING.md](PROJECT/3-COMPLETED/GH-11-CROSS-REPO-TARGETING.md) · [#11](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/11)
ROADMAP.md:136:- **Tooling · marathon planner (pre-pre-flight)** ✅ 2026-06-30 — `utils/marathon-plan.sh` (formerly `queue-plan.sh`) reviews this ledger, validates each item (already-closed / already-landed / undocumented-partial / drift / unrated — deterministic, flag-for-human), ranks survivors by the PDDA `complexity`/`risk`/`effort` ratings, and writes a sequenced collision-aware `MARATHON-PLAN-YYYY-MM-DD.md` (the stage before `swarm-preflight`). Ratings contract codified in `PROJECT/PDDA.md` (integer `1`–`5`), validated by `utils/pdda/pdda.sh frontmatter`. `test/marathon-plan.sh` 31/31; in `validate.sh`. **The final gating step — confirm the provisional ratings backfill + refresh the overlay — completed 2026-06-30** (all 7 provisional ratings resolved → 0 remaining; `MARATHON-PLAN-2026-06-30.md` regenerated, Wave 1 = #52). **Renamed `queue-plan`→`marathon-plan` 2026-06-30** for label clarity (output `QUEUE-*.md`→`MARATHON-PLAN-*.md`). → [MARATHON-PLANNER.md](PROJECT/3-COMPLETED/MARATHON-PLANNER.md)
ROADMAP.md:138:- **GH-37 · agy consult lane hangs on expired auth** ✅ 2026-06-29 (#37 closed) — **shipped via marathon dogfood** (Codex builder + agy reviewer → Approved, `validate.sh` 60/60). A fast `agy whoami` auth pre-flight now lives in both `agy-turn.sh` and `consult.sh`: an expired/failed session exits in seconds (shim exit 5; consult degrades to Codex-only) naming the `agy login` remedy, instead of the 300s interactive-prompt hang. New `agy-turn` auth-fail test (exit 5, no commit) added; all exit-6 containment assertions preserved. **The run surfaced 5 harness defects** (the build was correct on turn 1; every blocker was a swarm-preflight/marathon gap — timeout sizing, artifact-set scope, leaked-token reuse, self-verify-trips-containment, and the `--target-root .` relay-file off-lane false-positive); filed separately. → [GH-37-AGY-CONSULT-AUTH-HANG.md](PROJECT/3-COMPLETED/GH-37-AGY-CONSULT-AUTH-HANG.md) · [#37](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/37)
ROADMAP.md:140:- **GH-46 · Phase 4 swarm-preflight contract + cross-model hands-free marathon dogfood** ✅ 2026-06-29 (#46 closed) — split out of #33 so the *runnable* Phase 4 contract got its own issue + attention. Carried the **authoritative** Swarm Preflight Contract (unify Path A/B: `relay-loop.sh --background` launches the cross-model shim on `nudge-cross-model` via `--cross-model-cmd`; degrades to a human nudge when the CLI is absent; containment byte-identical to Path A). **SHIPPED 2026-06-29 via the marathon dogfood** (codex builder + agy reviewer): after 2 failures from #14 (codex self-commit → reset), the #14 fix landed and the **3rd run succeeded — codex built Phase 4, agy approved** — the **end-to-end #14 confirmation** that the codex builder lane no longer resets+fails. (The marathon's pre-advance gate tripped on a non-hermetic `driver-lock.sh` test inheriting `RELAY_DRIVER_LOCKED` — a test-env bug, fixed same day, `validate.sh` 56/56.) → [GH-46-PHASE4-SWARM-PREFLIGHT.md](PROJECT/3-COMPLETED/GH-46-PHASE4-SWARM-PREFLIGHT.md) · [#46](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/46)
ROADMAP.md:143:- **GH-39 · swarm preflight gaps (validation + scope-locked brief)** ✅ 2026-06-28 (#39 closed) — agy-authored gaps expanded from the GH-36 dogfood. **Slice 1 (validation, agy VERDICT PASS):** A2 artifact-paths-exist, A1 gate-resolves (flag-aware), A3 lane-CLI advisory. **Slice 2 (B6 scope-locked brief):** `swarm-preflight` packet now inlines the acceptance checklist + an edit-only/no-gate/no-wander scope-lock + a size-based `RELAY_TURN_TIMEOUT_S` rec (#43-1); `rtl_turn_prompt` forbids self-running the full gate (#43-3). `swarm-preflight` 31/31, `codex-turn` 30/30, `validate.sh` 55/55. A4 dropped as superseded by PR #38; A5/B7/#43-2 parked. → [GH-39-SWARM-PREFLIGHT-GAPS.md](PROJECT/3-COMPLETED/GH-39-SWARM-PREFLIGHT-GAPS.md) · [#39](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/39)
ROADMAP.md:145:- **GH-16 · same-device cross-repo swarm readiness (umbrella)** ✅ 2026-06-28 (#16 closed) — the epic to drive a multi-lane swarm against an external target repo on macOS without the harness reverting its own output. Its core gaps shipped via the children (GH-11 `--target-root`, GH-18 friction, GH-22 isolation, GH-29 new-file commit, #17 case-sensitivity); residual child issues remain tracked individually (#13/#14 closed 2026-06-29; #11 open — doc-only Asks 2–5; #3, #4, #5 open). Doc reconciled to `3-COMPLETED` 2026-06-29. → [GH-16-CROSS-REPO-SWARM.md](PROJECT/3-COMPLETED/GH-16-CROSS-REPO-SWARM.md) · [#16](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/16)
ROADMAP.md:146:- **GH-36 · headless Codex isolated-turn friction (`.tick` sandbox)** ✅ 2026-06-28 (#36 closed) — **first real marathon dogfood since GH-29**. Under worktree isolation Codex's default `-s workspace-write` can't write the shared `.tick/` lock (outside its sandbox) → `tick claim` EPERM → deadlock. Fix: pass `--add-dir "$ROOT/.tick"` to codex exec when isolation is on (default-off unchanged). Built by the Codex builder via `swarm-preflight → marathon-drive`: **v1 reproduced the bug live + containment held** (off-lane edits reverted, escalated, tree clean); **v2 (bypass flag + scope-locked brief) built the fix**; **agy cross-model review → Approved** (4× [Pass]). Regression: `test/codex-turn.sh` +2 (29/29); `validate.sh` 54/54. Dogfood findings → candidate **GH-38** (preflight brief should inline acceptance criteria). → [GH-36-HEADLESS-CODEX-TICK-SANDBOX.md](PROJECT/3-COMPLETED/GH-36-HEADLESS-CODEX-TICK-SANDBOX.md) · [#36](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/36)
ROADMAP.md:147:- **GH-29 · cross-repo (`--target-root`) build doesn't commit NEW untracked files** ✅ 2026-06-27 (#29 closed) — the first-wave dogfood blocker. A builder turn that *creates* files in a foreign target reported `no tracked changes` and committed nothing (even modified tracked files dropped), because the file-scoped commit batched `git add -- "${RTL_ALLOW[@]}"` — and `git add` aborts the **whole** batch on the first non-matching pathspec (an allowlist entry the turn was permitted to create but didn't). Fix: stage each allowlisted path independently (`git add -A -- <path>` per path, `|| true`). Regression test [relay-target-root-newfile.sh](test/relay-target-root-newfile.sh) (6 assertions) reproduces the batch-abort + asserts new+modified files commit cross-repo; `validate.sh` **54/54**. GH-22 sibling (same-repo copyback). → [GH-29-CROSS-REPO-NEWFILE-COMMIT.md](PROJECT/3-COMPLETED/GH-29-CROSS-REPO-NEWFILE-COMMIT.md) · [#29](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/29)
ROADMAP.md:148:- **Part A · Phase 6 — real-substrate dogfood (graduation test)** ✅ **FIRED + GRADUATED 2026-06-26**: the marathon ran end-to-end for the first time. **WPCC `ts-type-suppression`** built by codex, reviewed by agy → **Approved**, gate passed, scanner detects **3/3** suppression directives on the fixture; committed to WP-Code-Check `marathon-dogfood/ts-type-suppression` (`3e22f97`, first slice of WPCC #129). Run history: v1 escalated on an off-allowlist `PATTERN-LIBRARY.md` (containment held), v2/v3 surfaced the cross-repo new-file commit gap (**GH-29**, still open) → recovered by hand-commit. Pipeline `swarm-preflight → marathon-drive → codex build → gate → agy review` proven; GH-22 fix validated live (agy reviewed under isolation). → [MARATHON-DOGFOOD-2026-06-25-WPCC-TS-TYPE-SUPPRESSION.md](PROJECT/4-MISC/MARATHON-DOGFOOD-2026-06-25-WPCC-TS-TYPE-SUPPRESSION.md) · brief: [wpcc-ts-type-suppression-brief.md](PROJECT/4-MISC/wpcc-ts-type-suppression-brief.md) · transcript: [marathon-wpcc-095945.md](relay-system/2026-06-26/marathon-wpcc-095945.md) · retired substrates: [Sleuth](PROJECT/4-MISC/MARATHON-DOGFOOD-2026-06-24-SLEUTH-NEARMISS-2LITE.md) ([brief](PROJECT/4-MISC/sleuth-near-miss-2lite-brief.md)) · [WPCC-old](PROJECT/4-MISC/MARATHON-DOGFOOD-2026-06-18-WPCC-PHASE2.md)
ROADMAP.md:149:- **GH-31 · cross-repo external-artifact review flow** ✅ 2026-06-27 (#31 closed, merged #34) — first-class `--artifact-file` path (copy the artifact into the worktree, expose it read-only to the reviewer, closing #15) so reviewing another repo's PR/diff doesn't require embedding a large diff into the relay md; plus a fence-safe embed fallback and a `relay-automation/new-relay.sh` scaffolder. → [GH-31-CROSS-REPO-ARTIFACT-REVIEW.md](PROJECT/3-COMPLETED/GH-31-CROSS-REPO-ARTIFACT-REVIEW.md) · [#31](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/31)
ROADMAP.md:151:- **GH-25 · swarm preflight planner** ✅ 2026-06-26 (#25 closed) — `utils/swarm-preflight.sh`: one durable intake/preflight entrypoint that turns either a `PROJECT/2-WORKING` plan doc or a bundle of GitHub issues into a marathon-ready run packet (deterministic candidate/freshness checks, "fix still required" validation, remediation-readiness gate, Codex-vs-agy lane assignment), reusing the existing marathon/relay runtime instead of a second control plane. agy relay review passed → merged. → [GH-25-SWARM-PREFLIGHT-PLANNER.md](PROJECT/3-COMPLETED/GH-25-SWARM-PREFLIGHT-PLANNER.md) · [#25](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/25)
ROADMAP.md:154:- **GH-18 · cross-repo driven-relay friction** ✅ 2026-06-24, agy-approved — field-validated punch-list from a real cross-repo Codex review (thread/artifact in `rebalance-OS`, harness here via `--target-root`). Phase 0 verification reproduced #1/#2/#5 as real code bugs; #3 (foreign `.tick`) found **largely stale** for driven runs (mitigated by [codex-turn.sh:57](relay-automation/codex-turn.sh#L57)) → doc-only; #4 doc-only. Phase 2 code (`7709abc`): **#2** repo-relative `--relay-file` resolved under `--target-root`, **#1b** token-collision hints in `bin/tick` + `relay-drive.sh` (default unchanged), **#5** `STATUS: Escalated` now terminal-by-design (exit 4, not the stall's exit 3) — 3 new tests, **`validate.sh` 41→44/44**; agy headless review **Approved** (3×[Pass], confirmed #5 doesn't mask a true stall). Child of GH-16; issue #18 closed, doc archived. → [GH-18-CROSS-REPO-RELAY-FRICTION.md](PROJECT/3-COMPLETED/GH-18-CROSS-REPO-RELAY-FRICTION.md) · [#18](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/18)
PROJECT/2-WORKING/GH-48-QUEUE-PLAN-CROSS-REPO-ZONES.md:4:title: Generalize marathon-plan's zone model for true cross-repo pre-pre-flight
PROJECT/2-WORKING/GH-48-QUEUE-PLAN-CROSS-REPO-ZONES.md:14:  swarm/serialize wave plan for an external repo (validated against the live rebalance-OS 3-lane
PROJECT/2-WORKING/GH-48-QUEUE-PLAN-CROSS-REPO-ZONES.md:17:  - No foreign ledger/queue-format reader (park-and-discuss idea #3 from the original issue) — the
PROJECT/2-WORKING/GH-48-QUEUE-PLAN-CROSS-REPO-ZONES.md:18:    near-term path (per-lane swarm-preflight contracts) already works today per ROADMAP.md's
PROJECT/2-WORKING/GH-48-QUEUE-PLAN-CROSS-REPO-ZONES.md:19:    existing guidance; revisit only if the rebalance dogfood proves that insufficient.
PROJECT/2-WORKING/GH-48-QUEUE-PLAN-CROSS-REPO-ZONES.md:20:  - No change to swarm-preflight.sh itself — its write-set disjointness engine is already generic.
PROJECT/2-WORKING/GH-48-QUEUE-PLAN-CROSS-REPO-ZONES.md:30:  - utils/swarm-preflight.sh
PROJECT/2-WORKING/GH-48-QUEUE-PLAN-CROSS-REPO-ZONES.md:38:| Design committed (this doc) — replaces the three park-and-discuss ideas with one decided approach (Option 1, configurable zone rules) grounded in the actual `zoneOf()`/wave-packing code (`utils/marathon-plan.sh:148-153`, `:350-373`, `:643-690`). Not yet built. | Run `/consult` (Agy + Codex) to review this design before writing code — see [Consult ask](#consult-ask). If Approved (or Approved-with-fixes), promote to a marathon lane with the contract below; this lane is explicitly **excluded** from the current Plan B firing round. |
PROJECT/2-WORKING/GH-48-QUEUE-PLAN-CROSS-REPO-ZONES.md:42:`utils/marathon-plan.sh`'s `zoneOf(contract, item)` (line 350) labels every item `kernel | shim |
PROJECT/2-WORKING/GH-48-QUEUE-PLAN-CROSS-REPO-ZONES.md:55:when an item has a real swarm-preflight contract.** `zoneOf`'s "proven zone" branch (line
PROJECT/2-WORKING/GH-48-QUEUE-PLAN-CROSS-REPO-ZONES.md:56:359-365) still runs the contract's `artifacts[]` write-set through `KERNEL_PATHS`/`SHIM_RE` —
PROJECT/2-WORKING/GH-48-QUEUE-PLAN-CROSS-REPO-ZONES.md:57:so a foreign repo's contract naming `scripts/apple_reminders_helper_app.swift` as its write-set
PROJECT/2-WORKING/GH-48-QUEUE-PLAN-CROSS-REPO-ZONES.md:58:matches neither, and falls through to `independent` **even with a fully-specified contract**. The
PROJECT/2-WORKING/GH-48-QUEUE-PLAN-CROSS-REPO-ZONES.md:59:gap isn't "missing contracts" (park-and-discuss idea #2 assumed that) — it's that the
PROJECT/2-WORKING/GH-48-QUEUE-PLAN-CROSS-REPO-ZONES.md:60:classification *rules themselves* are xyz's filenames, contract or no contract. Idea #2 alone
PROJECT/2-WORKING/GH-48-QUEUE-PLAN-CROSS-REPO-ZONES.md:61:would not fix the rebalance case.
PROJECT/2-WORKING/GH-48-QUEUE-PLAN-CROSS-REPO-ZONES.md:67:`swarm-preflight.sh`'s write-set disjointness is already fully generic (confirmed, not
PROJECT/2-WORKING/GH-48-QUEUE-PLAN-CROSS-REPO-ZONES.md:75:- **Option 2 — contract-only mode.** Not a separate deliverable — proven-vs-inferred priority
PROJECT/2-WORKING/GH-48-QUEUE-PLAN-CROSS-REPO-ZONES.md:78:- **Option 3 — foreign ledger/queue-format adapter.** Explicitly deferred. ROADMAP.md's existing
PROJECT/2-WORKING/GH-48-QUEUE-PLAN-CROSS-REPO-ZONES.md:79:  near-term note already recommends per-lane `swarm-preflight` contracts as today's workable path
PROJECT/2-WORKING/GH-48-QUEUE-PLAN-CROSS-REPO-ZONES.md:80:  for cross-repo work; a foreign-ledger reader is a bigger, more speculative lift (every foreign
PROJECT/2-WORKING/GH-48-QUEUE-PLAN-CROSS-REPO-ZONES.md:81:  repo's queue format differs) that isn't required to unblock the rebalance dogfood. If the live
PROJECT/2-WORKING/GH-48-QUEUE-PLAN-CROSS-REPO-ZONES.md:113:A foreign repo's override, e.g. `rebalance-os-zones.json`:
PROJECT/2-WORKING/GH-48-QUEUE-PLAN-CROSS-REPO-ZONES.md:134:3. `<target-root>/.marathon-plan-zones.json` — repo-local convention, analogous to how
PROJECT/2-WORKING/GH-48-QUEUE-PLAN-CROSS-REPO-ZONES.md:135:   `swarm-preflight` already treats `--target-root` as "the repo this plan is about."
PROJECT/2-WORKING/GH-48-QUEUE-PLAN-CROSS-REPO-ZONES.md:141:- `zoneOf(contract, item)`: iterate the loaded zone list in order; for the proven-contract path,
PROJECT/2-WORKING/GH-48-QUEUE-PLAN-CROSS-REPO-ZONES.md:143:  contract), match title+body text against each zone's `inferKeywordRegex`. First match wins;
PROJECT/2-WORKING/GH-48-QUEUE-PLAN-CROSS-REPO-ZONES.md:156:Run `marathon-plan.sh --target-root <rebalance-OS clone> --zones-config rebalance-os-zones.json`
PROJECT/2-WORKING/GH-48-QUEUE-PLAN-CROSS-REPO-ZONES.md:157:against the **real** rebalance-OS 3-lane queue (`PROJECT/4-MISC/QUEUE-2026-06-27.md` in that repo),
PROJECT/2-WORKING/GH-48-QUEUE-PLAN-CROSS-REPO-ZONES.md:158:with each lane carrying a swarm-preflight contract (per ROADMAP's existing near-term
PROJECT/2-WORKING/GH-48-QUEUE-PLAN-CROSS-REPO-ZONES.md:169:  synthetic foreign zone-config correctly reclassifies a write-set the hardcoded regexes would have
PROJECT/2-WORKING/GH-48-QUEUE-PLAN-CROSS-REPO-ZONES.md:171:- [ ] Resolution-order precedence tested: `--zones-config` > `QP_ZONES_FILE` > `<target-root>/.marathon-plan-zones.json` > built-in default.
PROJECT/2-WORKING/GH-48-QUEUE-PLAN-CROSS-REPO-ZONES.md:172:- [ ] Live validation (Phase 2): the actual rebalance-OS 3-lane queue produces the correct wave
PROJECT/2-WORKING/GH-48-QUEUE-PLAN-CROSS-REPO-ZONES.md:191:2. Is deferring Option 3 (foreign ledger/queue-format adapter) the right call, or does the
PROJECT/2-WORKING/GH-48-QUEUE-PLAN-CROSS-REPO-ZONES.md:192:   rebalance dogfood specifically need it sooner than "revisit if Phase 2 proves it necessary"?
PROJECT/2-WORKING/GH-48-QUEUE-PLAN-CROSS-REPO-ZONES.md:194:   default) that would surprise an operator running this against a real foreign repo?
PROJECT/2-WORKING/GH-48-QUEUE-PLAN-CROSS-REPO-ZONES.md:210:  "remediation": "Replace utils/marathon-plan.sh's hardcoded KERNEL_PATHS/SHIM_RE and the ZONE_PEN/kernelTaken/inferredShimClash wave-packing constants with a zone-rules list loaded per the resolution order (--zones-config flag > QP_ZONES_FILE env seam > <target-root>/.marathon-plan-zones.json > built-in utils/marathon-plan-zones.default.json, which ships xyz's current values verbatim). zoneOf() and the wave-packing loop key off the matched zone object's pathPrefixes/pathRegex/inferKeywordRegex/maxPerWave/conservativeWhenInferred/penalty fields instead of literal 'kernel'/'shim' strings. test/marathon-plan.sh must show zero output diff for xyz's own default config; add coverage for a foreign zone-config fixture and the resolution-order precedence.",
PROJECT/2-WORKING/GH-48-QUEUE-PLAN-CROSS-REPO-ZONES.md:221:Filed 2026-06-29 while planning the rebalance-OS cross-repo marathon dogfood (the ROADMAP queue
PROJECT/2-WORKING/GH-48-QUEUE-PLAN-CROSS-REPO-ZONES.md:222:entry). The swarm-vs-relay compute was found to be **generic in `swarm-preflight`** (write-set
PROJECT/2-WORKING/GH-48-QUEUE-PLAN-CROSS-REPO-ZONES.md:223:disjointness, `--target-root`) but **xyz-coupled in `marathon-plan`** (ledger format + kernel/shim
PROJECT/2-WORKING/GH-48-QUEUE-PLAN-CROSS-REPO-ZONES.md:225:(see Problem section above) — the original issue's idea #2 turned out not to fix the rebalance case
PROJECT/2-WORKING/GH-48-QUEUE-PLAN-CROSS-REPO-ZONES.md:226:on its own, which is why this doc commits to idea #1 instead. Relates to the rebalance dogfood

exec
/bin/zsh -lc "nl -ba utils/marathon-plan.sh | sed -n '790,835p'" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-79403-29214
 succeeded in 0ms:
   790	  o.push("> The roadmap says **what/why**; this says **what is still real and in what order**. Execution");
   791	  o.push("> detail still lives in each `PROJECT/**` doc — this is a scheduling overlay.");
   792	  o.push("");
   793	  o.push("## Status");
   794	  o.push("");
   795	  o.push("| What was just completed | What's next |");
   796	  o.push("|---|---|");
   797	  const firstWave = waves[0] ? waves[0].map((r) => r.gh ? `#${r.gh}` : r.slug).join(" ‖ ") : "(none)";
   798	  o.push(`| Generated by \`utils/marathon-plan.sh\` on ${TODAY} from the live ROADMAP ledger (${deduped.length} items; ${active.length} active across ${waves.length} wave(s); ${held.length} held). Drift present: ${hasDrift ? "yes — see Held/Flagged" : "no"}. | **Wave 1:** ${firstWave}. Fire each lane via \`swarm-preflight → marathon-drive\`, scoped by \`ALLOW_PATHS\`. Re-run this script when the ledger changes. |`);
   799	  o.push("");
   800	  o.push("## The one safety rule");
   801	  o.push("");
   802	  o.push("Two lanes are safe to run concurrently **iff their write-sets are disjoint**. The kernel");
   803	  o.push("(`relay-automation/relay-turn-lib.sh`, `bin/tick`, `relay-automation/relay-drive.sh`) is the");
   804	  o.push("serialization bottleneck: **at most one kernel lane per wave**, even in separate worktrees.");
   805	  o.push("");
   806	  o.push("## Collision map");
   807	  o.push("");
   808	  o.push("| Zone | Parallel-safe? | Active items here |");
   809	  o.push("|---|---|---|");
   810	  for (const zone of ["kernel", "shim", "independent"]) {
   811	    const items = active.filter((r) => r.zone === zone).map((r) => r.gh ? `#${r.gh}` : r.slug);
   812	    const safe = zone === "kernel" ? "❌ serialize — one at a time" : "✅ one lane per file";
   813	    o.push(`| ${zone} | ${safe} | ${items.length ? items.join(", ") : "—"} |`);
   814	  }
   815	  o.push("");
   816	  o.push("## Per-item scoring");
   817	  o.push("");
   818	  o.push("Every input is shown so the ordering is verifiable by hand (lower score = earlier).");
   819	  o.push("");
   820	  o.push("| Item | cx | risk | eff | zone | deps | score | wave |");
   821	  o.push("|---|---|---|---|---|---|---|---|");
   822	  for (const r of active) {
   823	    const id = r.gh ? `[#${r.gh}] ${r.title}` : r.title;
   824	    o.push(`| ${cell(id)} | ${ratingNum(r.ratings.complexity)} | ${ratingNum(r.ratings.risk)} | ${ratingNum(r.ratings.effort)} | ${r.zone}${r.zoneInferred ? "*" : ""} | ${r.deps.length ? r.deps.map((d) => "#" + d).join(",") : "—"} | ${cell(r.score)} | ${cell(r.wave)} |`);
   825	  }
   826	  if (active.length === 0) o.push("| (no active, ready, rated items) | — | — | — | — | — | — | — |");
   827	  o.push("");
   828	  o.push("`*` = zone inferred from keywords (no preflight contract write-set to prove it).");
   829	  o.push("");
   830	  o.push("## Recommended waves");
   831	  o.push("");
   832	  if (waves.length === 0) o.push("_No active lanes — every item is held or flagged (see below)._");
   833	  waves.forEach((w, i) => {
   834	    const lanes = w.map((r) => r.gh ? `#${r.gh}` : r.slug).join(" ‖ ");
   835	    o.push(`**Wave ${i + 1}:** ${lanes || "(empty)"}`);

web search: 
web search: time: {"utc_offset":"-07:00"}
codex
One design seam is already visible: the doc talks about `--target-root`, but the current planner still appears to be rooted by env/install detection rather than a user-facing flag. I’m verifying whether that is real or just documented elsewhere.
exec
/bin/zsh -lc "nl -ba relay-automation/README.md | sed -n '1,220p'" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-79403-29214
 succeeded in 0ms:
     1	# relay-automation
     2	
     3	A tick-backed automation layer for the manual `/relay` review loop and `xyz`
     4	build swarms. Built in phases on top of `tick` (see
     5	[PROPOSAL-AUTOMATION.md](../PROJECT/1-INBOX/EXP-AUTOMATION/PROPOSAL-AUTOMATION.md)).
     6	
     7	**Execution contract: default live-window flow** — the default operator path is
     8	still the poll-driven, live-window flow: a Claude window under `/loop`, or a
     9	human one-line nudge when the turn belongs to a non-Claude window. Headless
    10	turn-takers now exist for Codex and agy (`codex-turn.sh`, `agy-turn.sh`).
    11	`relay-loop.sh --background --cross-model-cmd <shim>` can now auto-fire one of
    12	those shims on `DECISION: nudge-cross-model`; without that wrapper-only flag,
    13	the loop still degrades to the existing manual nudge. For the current headless path, see
    14	[the headless bring-up below](#headless-bring-up-codex--agy), plus
    15	[CROSSMODEL-OPTIONA-PLAN.md](CROSSMODEL-OPTIONA-PLAN.md).
    16	
    17	## Components
    18	| Script | Role |
    19	|---|---|
    20	| `poll.sh` | **Phase 4** per-tick poll driver. Reads state, applies the guard, dispatches `runner.sh`/`watchdog.sh` or idles. Run under `/loop`. |
    21	| `relay-loop.sh` | **GH-33 Phase 2/3 + GH-46 Phase 4** adaptive-cadence wrapper over `poll.sh` (which stays a pure oracle). Default = one tick that prints `NEXT-POLL: <s>` for a `/loop` dynamic tick / cron / any scheduler; `--sleep-loop` self-paces in pure bash (no Claude dep). **`--background`** dispatches the turn DETACHED on `run-runner`, and on `nudge-cross-model` it dispatches `--cross-model-cmd` only when that command is configured and reachable; otherwise it prints the same manual nudge `poll.sh` would have emitted. A pidfile (`<relay-file>.bgpid` or `--bg-pidfile`) is still the single-turn lock (`BG-RUNNING`, no double-dispatch; stale pidfile cleared before the fresh decision acts). Containment is **inherited** — the backgrounded process is the same runner/shim boundary, so the `relay-turn-lib.sh` boundary is byte-identical (`&` changes only when the parent returns). |
    22	| `runner.sh` | **Phase 3** single agent/turn: claim → run (`--agent-cmd`) → verdict gate (`VERDICT: PASS\|FAIL\|PARKED`) → done/retry; artifact-scoped clean-tree gate. |
    23	| `watchdog.sh` | **Phase 2** liveness: `tick analyze --format json` → parked `parked_suspects[]` → structured escalation record; reap gated behind `--allow-reap` (stub, pending an authority decision). |
    24	| `relay-drive.sh` | **Phase 4b** relay supervisor: loops a `/relay` Producer↔Reviewer thread to termination via a turn-taker; round cap + no-progress escalation. |
    25	| `relay-turn-lib.sh` | **Shared safety core** (sourced, not run): the model-agnostic containment contract — path-allowlist + commit-bypass guard + no-push. Both headless turn-takers source this so the boundary lives in ONE place. See [decisions/2026-06-15-unattended-agent-containment.md](../decisions/2026-06-15-unattended-agent-containment.md). |
    26	| `codex-turn.sh` | **Option-A** headless turn-taker for the **Codex** agent (`codex exec`); thin dispatch wrapper over `relay-turn-lib.sh`. |
    27	| `agy-turn.sh` | **Option-A** headless turn-taker for the **agy** (Antigravity CLI) agent (`agy -p`); thin dispatch wrapper over `relay-turn-lib.sh`. Permanent replacement for `gemini-turn.sh`; live-validated 2026-06-18. |
    28	| `aider-turn.sh` | Headless turn-taker for **Aider ↔ OpenRouter** (`aider --model openrouter/… --message`) — an OpenAI-standard lane discrete from Codex. Same `relay-turn-lib.sh` containment; because Aider is a file-editor (no mid-turn shell), the SHIM performs the tick token ops itself and runs Aider with `--no-auto-commits` (the harness owns the commit). Set `OPENROUTER_API_KEY` + `AIDER_MODEL` (e.g. `openrouter/anthropic/claude-3.5-sonnet`, `openrouter/openai/gpt-4o`, `openrouter/deepseek/deepseek-chat`). Works in **both** a marathon `--builder aider` lane AND a plain `/relay` — it routes through the shared `marathon-agent.sh` dispatcher (`relay-drive.sh`'s `--agent-cmd`), so a driven relay with `RELAY_AGENT=aider` fires it just like Codex/agy. |
    29	| `consult.sh` | Parallel read-only consult: asks the same question to **Codex, agy, and (opt-in) Aider↔OpenRouter** (`--models codex,agy,aider`), captures each transcript, and leaves synthesis to the caller. Advisory-only; also the engine behind `relay-drive.sh --consult-verify`. |
    30	
    31	## Recipes & docs (not scripts)
    32	| Doc | What it gives you |
    33	|---|---|
    34	| [DUELING-CLAUDES.md](DUELING-CLAUDES.md) | **"Dueling Claudes"** — copy-paste recipe for two live Claude windows running a Reporter↔Maintainer bug-fix relay on one machine, zero new code, with the single human go-gate before commit. The worked form of the hands-free Path B in the `relay-xyz` skill. |
    35	| [CONSUMING.md](CONSUMING.md) | How another repo consumes this harness (`--target-root`, cross-machine `.tick/` limits). |
    36	| [CROSSMODEL-OPTIONA-PLAN.md](CROSSMODEL-OPTIONA-PLAN.md) | The Option-A cross-model headless turn-taker plan (Codex / agy shims). |
    37	| [MARATHON.example.yaml](MARATHON.example.yaml) | Example multi-build marathon manifest for `marathon.sh`. |
    38	
    39	## Operator usage (default live-window flow)
    40	
    41	### Hands-free relay turn (all-Claude only)
    42	In each Claude window, run a guarded `/loop` that uses `poll.sh` as the gate, then
    43	takes the turn from the relay file's embedded `▶ TAKE YOUR TURN` instructions:
    44	```
    45	# Producer window (agent id = the agent the RELAY-TURN token is handed to)
    46	/loop 60s run relay-automation/poll.sh --mode relay --agent claude-a \
    47	  --relay-file relay-system/<date>/<slug>.md --artifact <path-under-review> --dry-run ;\
    48	  if it prints "DECISION: run-runner", take your turn on that relay file per its embedded \
    49	  instructions (review/produce, append your block, `tick release RELAY-TURN --to <other>` or
    50	  `done` on approve, commit, push); otherwise do nothing.
    51	# Reviewer window: same, with that window's --agent id
    52	```
    53	**Whose-turn is the `RELAY-TURN` tick task** (handed off via `tick release --to`), so the
    54	Phase-1 handoff-exclusive rule + the Phase-2 watchdog both apply. The guard *is* the lock:
    55	a window acts only when the token is claimable by **its** agent **and** the artifact scope is
    56	clean. `poll.sh` exits `10` on a closed relay (file `STATUS: Approved|Closed`) so the loop can stop.
    57	*(Default `--relay-task RELAY-TURN`; seed it at relay setup, handed to the first actor.)*
    58	
    59	**Poll interval — cache-warmth tradeoff.** `60s` keeps Claude Code's prompt cache warm
    60	(≈5-min TTL); the **lock/heartbeat is the real correctness guard, not the timer**, so a longer
    61	interval only adds latency, never a race. Use ~`60s` for active relays, longer (e.g. `120s`)
    62	for the lower-frequency watchdog poller.
    63	
    64	**Self-closing loops (no stray cron housekeeping).** Launch each loop with a deadline so it
    65	ends on the first of: relay `Approved`/`Closed`, **or** the deadline:
    66	`--deadline "$(date -v+30M +%s)"` (macOS) / `--deadline "$(date -d '+30 min' +%s)"` (GNU).
    67	Past the deadline `poll.sh` prints `DECISION: stop`; the loop prompt then `CronList`s and
    68	`CronDelete`s its own job. Cron jobs are per-session — you can't stop another window's loop
    69	from yours, so always set a deadline. See the `/relay` skill → "Self-closing loops".
    70	
    71	### Designated watchdog (exactly ONE window)
    72	Only one poller holds watchdog authority, so a stalled turn is escalated once
    73	without double-escalation:
    74	```
    75	/loop 120s run relay-automation/poll.sh --mode relay --agent coordinator \
    76	  --relay-file relay-system/<date>/<slug>.md --watchdog-authority ;\
    77	  if it prints "DECISION: run-watchdog", it has escalated the parked turn — surface it to me.
    78	```
    79	
    80	### Single-process relay supervision (one window drives the whole thread)
    81	```
    82	relay-automation/relay-drive.sh --relay-file relay-system/<date>/<slug>.md \
    83	  --agent-cmd "<turn-taker>" --round-cap 6
    84	```
    85	`--agent-cmd` is the turn-taker seam. In the live-window flow it can remain a
    86	window-driven/manual handoff; in the current headless path it can be a shipped
    87	shim such as `relay-automation/codex-turn.sh` or `relay-automation/agy-turn.sh`.
    88	Exits: `0` closed Approved/Closed, `3` no-progress, `4` round cap / closed-not-approved, `5`
    89	(with `--review-once`) reviewer completed a single non-approval review. Inspect whose-turn mid-drive
    90	with `tick info <task>` (the verb is `info`, not `status`).
    91	
    92	### Cross-model windows (Codex / agy)
    93	In the poll-based multi-window flow, non-Claude windows still need a wake-up path.
    94	Without `relay-loop.sh --background --cross-model-cmd <shim>`, the operator's
    95	whole job is **one line**:
    96	```
    97	take your turn on relay-system/<date>/<slug>.md
    98	```
    99	The relay file embeds the `▶ TAKE YOUR TURN` instructions, so any agent acts from
   100	the file alone. `poll.sh` detects a cross-model turn and emits this nudge text
   101	rather than silently idling. If you want the current headless cross-model path
   102	inside the `/loop` poll flow, wrap `poll.sh` with `relay-loop.sh --background`
   103	and pass `--cross-model-cmd relay-automation/codex-turn.sh` (or `agy-turn.sh`);
   104	the same pidfile lock prevents a second dispatch while that shim is still
   105	running. `relay-drive.sh` remains the deterministic single-window alternative.
   106	
   107	## Boundary (load-bearing)
   108	- **Hands-free poll is all-Claude only** — it relies on Claude Code's in-session `/loop`. Cross-model stays on the manual nudge.
   109	- **Not a durable scheduler / not unattended-without-a-window.** A Claude window must be open and looping for the default poll flow. Current headless turns exist, but durable unattended orchestration is still a separate problem.
   110	- The portable `/relay` skill stays dependency-free; this tick-driven automation lives here.
   111	
   112	## Headless bring-up (Codex + agy)
   113	
   114	This section is the canonical fresh-device bootstrap path for the two shipped
   115	headless Path-A workers: Codex and agy.
   116	
   117	> **What a single-device test proves.** `.tick/` is gitignored and device-local,
   118	> so two clones do not share token state over git. A fresh-device run proves
   119	> that the selected headless turn-taker works cleanly in a fresh clone behind
   120	> the safety shim; it does not prove cross-machine coordination.
   121	
   122	### 1. Prerequisites
   123	
   124	The shipped scripts assume Node, git, and whichever headless worker you plan to
   125	drive:
   126	
   127	```bash
   128	node --version
   129	codex exec -s workspace-write "create a file ok.txt with the text ok" < /dev/null   # Codex lane
   130	agy -p "Reply with exactly: PONG" < /dev/null                                        # agy lane; run sandbox-OFF
   131	git --version
   132	```
   133	
   134	Run the worker check for the lane you actually plan to drive; run both if you
   135	want both workers available on that machine.
   136	
   137	The Codex autonomy check matters: a bare `codex exec "say ok"` can succeed without
   138	proving Codex can write the relay file. `codex-turn.sh` defaults to
   139	`-s workspace-write`; if your device config still blocks writes, set
   140	`CODEX_FLAGS='--dangerously-bypass-approvals-and-sandbox'` or add
   141	`-c approval_policy=never`. If `codex` is not on `PATH` or is not authenticated,
   142	fix that before running the shim; override the binary with
   143	`CODEX_BIN=/path/to/codex` if needed.
   144	
   145	The agy check must also run unsandboxed. `agy-turn.sh` uses `agy -p`; when agy's
   146	backend is blocked by a sandbox it can exit `0` with empty output, which the
   147	shim correctly treats as a failed turn. If `agy` is not on `PATH` or is not
   148	authenticated through the Antigravity desktop app, fix that before driving the
   149	lane; override the binary with `AGY_BIN=/path/to/agy` if needed. Antigravity
   150	installs `agy` at `~/.local/bin/agy` on macOS by default (not on the system
   151	PATH); running `AGY_BIN=~/.local/bin/agy bash test/agy-turn.sh` confirms it
   152	works before adding it to your PATH or passing `AGY_BIN` to every drive command.
   153	
   154	If you are running under a sandboxed AI shell, run both workers outside that
   155	sandbox. Codex often fails there because it cannot reach the OS keychain or
   156	`chatgpt.com`; agy can fail "cleanly" with empty output when its backend network
   157	is blocked.
   158	
   159	### 2. Clone or refresh the harness
   160	
   161	```bash
   162	git clone https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm.git
   163	cd xyz-3-agents-swarm
   164	# or, in an existing clone: git pull origin main
   165	export TICK_REPO_ROOT="$PWD"
   166	```
   167	
   168	### 3. Smoke test the local machine
   169	
   170	Run the repo gate, then the shim test for the worker you plan to drive:
   171	
   172	```bash
   173	bash validate.sh
   174	bash test/codex-turn.sh   # before Codex runs
   175	bash test/agy-turn.sh     # before agy runs
   176	```
   177	
   178	If `validate.sh` cannot make tempdirs, that is usually a sandbox blocking
   179	`mktemp`; rerun it in a normal shell.
   180	
   181	### 4. Drive one headless turn in this repo
   182	
   183	The supervisor (`relay-drive.sh`) drives the turn; the selected shim
   184	(`codex-turn.sh` or `agy-turn.sh`) is the turn-taker and owns the safety
   185	boundary: path allowlist, commit-bypass guard, file-scoped commit, and no push.
   186	*(Note: Fixed log paths break concurrent same-machine runs. Prefer using the shims' default per-PID paths or specifying a per-PID log file path with `$$`.)*
   187	
   188	**Worktree isolation is ON by default for driven runs.** `relay-drive.sh`
   189	exports `RELAY_WORKTREE_ISOLATION=1`, so each shim runs inside a throwaway
   190	`git worktree` of `ROOT@HEAD`. Off-allowlist writes in the worktree are
   191	discarded and the turn fails with **exit 6**. One important side-effect: agents
   192	that write to the relay file via **absolute paths** bypass the worktree (those
   193	writes land in ROOT, not the throwaway tree) — so untracked relay files with
   194	absolute paths in the `▶ TAKE YOUR TURN` block remain accessible to the agent.
   195	Opt out per run with `RELAY_WORKTREE_ISOLATION=0` if you need to disable
   196	isolation (e.g. during testing).
   197	
   198	#### Codex worker
   199	
   200	```bash
   201	# Reuse an existing relay thread or scaffold a fresh one with embedded
   202	# TAKE YOUR TURN instructions.
   203	RELAY=relay-system/$(date +%F)/<your-slug>.md
   204	ARTIFACT=relay-automation/codex-turn.sh
   205	
   206	# Use a per-relay token id, not the literal RELAY-TURN.
   207	TASK="RELAY-$(basename "$RELAY" .md)"
   208	
   209	./bin/tick log task.created "$TASK" --agent claude-a
   210	./bin/tick claim   "$TASK" --agent claude-a --paths "$ARTIFACT"
   211	./bin/tick release "$TASK" --agent claude-a --to codex
   212	
   213	CODEX_AGENT=codex ALLOW_PATHS="$ARTIFACT" CODEX_LOG="${TMPDIR:-/tmp}/codex-turn-$$.log" \
   214	relay-automation/relay-drive.sh \
   215	  --relay-file "$RELAY" \
   216	  --relay-task "$TASK" \
   217	  --agent-cmd relay-automation/codex-turn.sh \
   218	  --round-cap 4
   219	```
   220	

exec
/bin/zsh -lc "rg -n -- '--target-root|QUEUE_PLAN_ROOT|QP_ZONES_FILE|marathon-plan-zones|zones-config' utils/marathon-plan.sh relay-automation/README.md ROADMAP.md PROJECT/2-WORKING/GH-48-QUEUE-PLAN-CROSS-REPO-ZONES.md" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-79403-29214
 succeeded in 0ms:
relay-automation/README.md:35:| [CONSUMING.md](CONSUMING.md) | How another repo consumes this harness (`--target-root`, cross-machine `.tick/` limits). |
relay-automation/README.md:287:  --target-root "$TARGET" \
relay-automation/README.md:303:  --target-root "$TARGET" \
relay-automation/README.md:312:`--target-root`.
utils/marathon-plan.sh:36:#   QUEUE_PLAN_ROOT / QUEUE_PLAN_ROADMAP / QUEUE_PLAN_QUEUE_DIR / QUEUE_PLAN_NOW / QUEUE_PLAN_TODAY
utils/marathon-plan.sh:47:  ROOT="${QUEUE_PLAN_ROOT:-"$(cd "$_here_parent/.." && pwd)"}"
utils/marathon-plan.sh:52:  ROOT="${QUEUE_PLAN_ROOT:-"$_here_parent"}"
PROJECT/2-WORKING/GH-48-QUEUE-PLAN-CROSS-REPO-ZONES.md:111:This is xyz's **exact current behavior** re-expressed as data — the default config `utils/marathon-plan-zones.default.json` ships this verbatim, so nothing about xyz's own planning changes.
PROJECT/2-WORKING/GH-48-QUEUE-PLAN-CROSS-REPO-ZONES.md:131:1. `--zones-config <path>` CLI flag (explicit override).
PROJECT/2-WORKING/GH-48-QUEUE-PLAN-CROSS-REPO-ZONES.md:132:2. `QP_ZONES_FILE` env var — hermetic test seam, mirroring the existing `QP_BASE_FILES_FILE` /
PROJECT/2-WORKING/GH-48-QUEUE-PLAN-CROSS-REPO-ZONES.md:134:3. `<target-root>/.marathon-plan-zones.json` — repo-local convention, analogous to how
PROJECT/2-WORKING/GH-48-QUEUE-PLAN-CROSS-REPO-ZONES.md:135:   `swarm-preflight` already treats `--target-root` as "the repo this plan is about."
PROJECT/2-WORKING/GH-48-QUEUE-PLAN-CROSS-REPO-ZONES.md:136:4. Built-in xyz default (`utils/marathon-plan-zones.default.json`) — always available, never
PROJECT/2-WORKING/GH-48-QUEUE-PLAN-CROSS-REPO-ZONES.md:156:Run `marathon-plan.sh --target-root <rebalance-OS clone> --zones-config rebalance-os-zones.json`
PROJECT/2-WORKING/GH-48-QUEUE-PLAN-CROSS-REPO-ZONES.md:168:- [ ] New test coverage (extend `test/marathon-plan.sh` or add `test/marathon-plan-zones.sh`): a
PROJECT/2-WORKING/GH-48-QUEUE-PLAN-CROSS-REPO-ZONES.md:171:- [ ] Resolution-order precedence tested: `--zones-config` > `QP_ZONES_FILE` > `<target-root>/.marathon-plan-zones.json` > built-in default.
PROJECT/2-WORKING/GH-48-QUEUE-PLAN-CROSS-REPO-ZONES.md:203:    { "type": "path_absent", "path": "utils/marathon-plan-zones.default.json" }
PROJECT/2-WORKING/GH-48-QUEUE-PLAN-CROSS-REPO-ZONES.md:207:    "utils/marathon-plan-zones.default.json",
PROJECT/2-WORKING/GH-48-QUEUE-PLAN-CROSS-REPO-ZONES.md:210:  "remediation": "Replace utils/marathon-plan.sh's hardcoded KERNEL_PATHS/SHIM_RE and the ZONE_PEN/kernelTaken/inferredShimClash wave-packing constants with a zone-rules list loaded per the resolution order (--zones-config flag > QP_ZONES_FILE env seam > <target-root>/.marathon-plan-zones.json > built-in utils/marathon-plan-zones.default.json, which ships xyz's current values verbatim). zoneOf() and the wave-packing loop key off the matched zone object's pathPrefixes/pathRegex/inferKeywordRegex/maxPerWave/conservativeWhenInferred/penalty fields instead of literal 'kernel'/'shim' strings. test/marathon-plan.sh must show zero output diff for xyz's own default config; add coverage for a foreign zone-config fixture and the resolution-order precedence.",
PROJECT/2-WORKING/GH-48-QUEUE-PLAN-CROSS-REPO-ZONES.md:212:    "agy_safe": ["utils/marathon-plan.sh", "utils/marathon-plan-zones.default.json", "test/marathon-plan.sh"],
PROJECT/2-WORKING/GH-48-QUEUE-PLAN-CROSS-REPO-ZONES.md:223:disjointness, `--target-root`) but **xyz-coupled in `marathon-plan`** (ledger format + kernel/shim
ROADMAP.md:44:1. ✅ **Done — GH-51 [1-kernel] fixed (2026-06-30).** `rtl_init` now collapses a same-repo `--target-root` to the caller's root (no-op), so `--target-root .` no longer reverts the relay file off-lane. Decision record + regression test; `validate.sh` 69/69. The remaining GH-51 items ([2]/[3]/[5]) are minor. → [#51](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/51)
ROADMAP.md:45:2. **Re-open the rebalance-OS cross-repo harness dogfood — now UNBLOCKED** (GH-51 [1-kernel] landed). Converts the #14 fix into a real external-repo proof: drive a scoped rebalance-OS lane via `swarm-preflight --target-root <clone> → marathon-drive`. The highest-value momentum test now that `--target-root` is containment-correct.
ROADMAP.md:82:- **Marathon dogfood · rebalance-OS parallel build queue (cross-repo, `--target-root`)** 🆕 **captured 2026-06-28** — **orchestrate this from Claude Code in THIS repo** as a real cross-repo dogfood: drive the rebalance-OS build queue (`PROJECT/4-MISC/QUEUE-2026-06-27.md` in that repo) via `swarm-preflight → marathon-drive --target-root <rebalance-OS clone>`. It has **3 collision-free lanes**: **SWIFT-APP** (Focus5Float VS Code focus-if-open Phase 1, claim `macOS/Apps/Focus5Float/Sources/**`), **BACKEND** (Unified Refresh/Restart v1 — signed Reminders helper + pulse server, claim `scripts/**`), **SPIKE** (Focus 5 App Store Phase 0, new `macOS/Apps/Focus5Native/**`). Disjoint write-globs ⇒ XYZ-safe concurrently. Per-lane gates differ (`swift build`+`FOCUS5_SELFTEST=1` / `pytest`+live `/api/refresh` / spike build); the *verify-and-archive* items finish on an **operator GUI litmus** (no CLI agent can satisfy a LaunchServices GUI check). Do not touch rebalance-OS outside an explicit, scoped lane run. **Status 2026-06-29: Lane A (Focus5Float VS Code focus-if-open) shipped INLINE — built by hand, NOT via the harness, since the marathon builder lane was then blocked by #14 — and pushed to rebalance `feat/apple-reminders-write`. Lanes B (refresh/restart v1) + C (App Store spike) handed to Agy (its app, direct in rebalance); the archive sweep is operator GUI-litmus. #14 is now fixed. **Status 2026-07-01: UNBLOCKED — GH-51 [1-kernel] closed 2026-06-30; `--target-root` containment normalization is fixed. Deferral condition met. Fire one scoped lane as the cross-repo proof.**
ROADMAP.md:89:- **Tooling · front-door onboarding health** 🟡 parked — read-only audit shipped → [FRONTDOOR.md](PROJECT/4-MISC/FRONTDOOR.md) (continuous deterministic dashboard; 10 findings, re-runnable checks) + a phased remediation plan. Verdict ⚠️ Bumpy: clone-to-working works (`validate.sh` 36/36, secrets clean), but stale test counts (3 docs) + 2 dead README links + a phantom-path `CLAUDE.md` + undocumented `--target-root`/`install.sh` remain. Phases 1–3 queued (doc-only). → [FRONT-DOOR/2026-06-22.md](PROJECT/1-INBOX/FRONT-DOOR/2026-06-22.md)
ROADMAP.md:126:- **GH-51 · marathon/swarm-preflight harness defects (GH-37 dogfood)** ✅ **CLOSED 2026-06-30** — root cause (#1 `--target-root .` off-lane false-positive) + budget-scaling (#4) shipped (`19b8736`, `validate.sh` 69/69); cross-repo dogfood unblocked. 3 minor remainders split out: **#54** (brief: forbid in-turn fs-touching tests), **#55** (swarm-preflight: auto-include a changed artifact's tests), **#56** (marathon-drive: reconcile/fresh-id a leaked tick token). → [#51](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/51)
ROADMAP.md:132:- **GH-11 · relay-xyz cross-repo targeting** ✅ 2026-06-30 (#11 closed) — Ask 1 (the `--target-root` flag + `relay-turn-lib.sh` kernel wiring routing worktree/allowlist/commit via `RELAY_TARGET_ROOT`, `test/relay-target-root.sh` 7/7) shipped 2026-06-21; **Asks 2–5 swept 2026-06-30** into `skills/relay-xyz/SKILL.md` (a cross-repo subsection documenting `--target-root` + `CONSULT_ROOT` with foreign-repo examples, the `$TMPDIR` absolute-path warning, and the find-harness-solves-the-inverse note). `skill-extract` + `path-integrity` green. → [GH-11-CROSS-REPO-TARGETING.md](PROJECT/3-COMPLETED/GH-11-CROSS-REPO-TARGETING.md) · [#11](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/11)
ROADMAP.md:138:- **GH-37 · agy consult lane hangs on expired auth** ✅ 2026-06-29 (#37 closed) — **shipped via marathon dogfood** (Codex builder + agy reviewer → Approved, `validate.sh` 60/60). A fast `agy whoami` auth pre-flight now lives in both `agy-turn.sh` and `consult.sh`: an expired/failed session exits in seconds (shim exit 5; consult degrades to Codex-only) naming the `agy login` remedy, instead of the 300s interactive-prompt hang. New `agy-turn` auth-fail test (exit 5, no commit) added; all exit-6 containment assertions preserved. **The run surfaced 5 harness defects** (the build was correct on turn 1; every blocker was a swarm-preflight/marathon gap — timeout sizing, artifact-set scope, leaked-token reuse, self-verify-trips-containment, and the `--target-root .` relay-file off-lane false-positive); filed separately. → [GH-37-AGY-CONSULT-AUTH-HANG.md](PROJECT/3-COMPLETED/GH-37-AGY-CONSULT-AUTH-HANG.md) · [#37](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/37)
ROADMAP.md:145:- **GH-16 · same-device cross-repo swarm readiness (umbrella)** ✅ 2026-06-28 (#16 closed) — the epic to drive a multi-lane swarm against an external target repo on macOS without the harness reverting its own output. Its core gaps shipped via the children (GH-11 `--target-root`, GH-18 friction, GH-22 isolation, GH-29 new-file commit, #17 case-sensitivity); residual child issues remain tracked individually (#13/#14 closed 2026-06-29; #11 open — doc-only Asks 2–5; #3, #4, #5 open). Doc reconciled to `3-COMPLETED` 2026-06-29. → [GH-16-CROSS-REPO-SWARM.md](PROJECT/3-COMPLETED/GH-16-CROSS-REPO-SWARM.md) · [#16](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/16)
ROADMAP.md:147:- **GH-29 · cross-repo (`--target-root`) build doesn't commit NEW untracked files** ✅ 2026-06-27 (#29 closed) — the first-wave dogfood blocker. A builder turn that *creates* files in a foreign target reported `no tracked changes` and committed nothing (even modified tracked files dropped), because the file-scoped commit batched `git add -- "${RTL_ALLOW[@]}"` — and `git add` aborts the **whole** batch on the first non-matching pathspec (an allowlist entry the turn was permitted to create but didn't). Fix: stage each allowlisted path independently (`git add -A -- <path>` per path, `|| true`). Regression test [relay-target-root-newfile.sh](test/relay-target-root-newfile.sh) (6 assertions) reproduces the batch-abort + asserts new+modified files commit cross-repo; `validate.sh` **54/54**. GH-22 sibling (same-repo copyback). → [GH-29-CROSS-REPO-NEWFILE-COMMIT.md](PROJECT/3-COMPLETED/GH-29-CROSS-REPO-NEWFILE-COMMIT.md) · [#29](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/29)
ROADMAP.md:154:- **GH-18 · cross-repo driven-relay friction** ✅ 2026-06-24, agy-approved — field-validated punch-list from a real cross-repo Codex review (thread/artifact in `rebalance-OS`, harness here via `--target-root`). Phase 0 verification reproduced #1/#2/#5 as real code bugs; #3 (foreign `.tick`) found **largely stale** for driven runs (mitigated by [codex-turn.sh:57](relay-automation/codex-turn.sh#L57)) → doc-only; #4 doc-only. Phase 2 code (`7709abc`): **#2** repo-relative `--relay-file` resolved under `--target-root`, **#1b** token-collision hints in `bin/tick` + `relay-drive.sh` (default unchanged), **#5** `STATUS: Escalated` now terminal-by-design (exit 4, not the stall's exit 3) — 3 new tests, **`validate.sh` 41→44/44**; agy headless review **Approved** (3×[Pass], confirmed #5 doesn't mask a true stall). Child of GH-16; issue #18 closed, doc archived. → [GH-18-CROSS-REPO-RELAY-FRICTION.md](PROJECT/3-COMPLETED/GH-18-CROSS-REPO-RELAY-FRICTION.md) · [#18](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/18)

exec
/bin/zsh -lc "nl -ba ROADMAP.md | sed -n '40,90p'" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-79403-29214
 succeeded in 0ms:
    40	| **2026-07-03 portability + marathon sweep:** **GH-104 portability fix** (`a17ef13`) — `utils/` vendored, tool-root separated from target-root in all three entrypoints, generated-doc paths install-aware, collision-safety test added; #104 closed. **Also shipped 2026-07-03 (marathon Wave 1):** **GH-5** contract-seam warning, **GH-4** work-stealing verdict, **GH-3** parked-claim false-positive, **GH-88** cross-repo monitor, **GH-63** signal triage, **GH-44** scratch-repo helper, **GH-77** Aider lane, **GH-78** doc preflight, **GH-45** attempt cap, **GH-41** terminality seal, **GH-30 Phase 1** transcript-root resolver (`XYZ_ARCHIVE_ROOT`, default-off). `validate.sh` **89/89** (also fixed a pre-existing `xyz-vendor.sh` typo red). | **Still open:** **GH-61 Tier 2** (needs operator `macos-latest`/`ubuntu-latest` runner decision). **Operator-driven:** **rebalance-OS cross-repo dogfood** (unblocked since GH-51). **Part B:** G2 dup-token determinism (next adversarial-hardening slice). **Queue / parked:** GH-87 deep research, GH-86 review-lane surface, **GH-30 Phases 2–5** (writer wiring + risk-4 containment), GH-48 cross-repo zone model. |
    41	
    42	### Immediate next-up (ordered)
    43	
    44	1. ✅ **Done — GH-51 [1-kernel] fixed (2026-06-30).** `rtl_init` now collapses a same-repo `--target-root` to the caller's root (no-op), so `--target-root .` no longer reverts the relay file off-lane. Decision record + regression test; `validate.sh` 69/69. The remaining GH-51 items ([2]/[3]/[5]) are minor. → [#51](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/51)
    45	2. **Re-open the rebalance-OS cross-repo harness dogfood — now UNBLOCKED** (GH-51 [1-kernel] landed). Converts the #14 fix into a real external-repo proof: drive a scoped rebalance-OS lane via `swarm-preflight --target-root <clone> → marathon-drive`. The highest-value momentum test now that `--target-root` is containment-correct.
    46	3. **[GH-48-QUEUE-PLAN-CROSS-REPO-ZONES.md](PROJECT/2-WORKING/GH-48-QUEUE-PLAN-CROSS-REPO-ZONES.md) design committed 2026-07-04, awaiting `/consult` (Agy + Codex) before build.** Live rebalance-dogfood validation stays Phase 2 of that design, not a precondition to starting. (Planner generalization is useful but not the unblocker; per-lane `swarm-preflight` already works today.)
    47	4. **Part B Phase-2 remainder: G2 dup-token determinism** (`test/chaos-dup-token.sh`) — the next adversarial-hardening slice now that **R2 (#52) + G4 are done**. Kernel epoch-fence territory → Opus + `decisions/` record.
    48	5. ✅ **Done — Part C real-agent run PROVEN (2026-06-30, operator GO).** `improve-loop` drove a live `marathon-drive` (**codex builder + agy reviewer**) as `--build-cmd`: baseline 4 → live build → `KEEP` oracle held → champion ACCEPTed (metric 3) → halted on the iteration cap, with provenance. Every safety invariant fired against a real build. The run surfaced two harness defects (neither a loop bug): **#58** (`--builder claude` not on PATH headless — use codex/agy) and **#59** (allowlisted artifact in an untracked dir → spurious off-lane exit 6). → [#50](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/50)
    49	
    50	> **Active scheduling overlay:** re-run `utils/marathon-plan.sh` to regenerate after today's ledger update. Last generated: [MARATHON-PLAN-2026-07-02.md](PROJECT/2-WORKING/MARATHON-PLAN-2026-07-02.md) (2026-07-02 — stale; the 2026-07-03 wave shipped ~10 items that were in the held list). Derived from this ledger; the ledger stays source of truth.
    51	
    52	## Model assignment (heuristic)
    53	
    54	Mechanical / pattern-following work → **Sonnet High**; trust-critical kernel-correctness reasoning
    55	(epoch-fencing kernel, dup-token determinism) → **Opus**. Full build-track table:
    56	[MARATHON-HARNESS.md → Model assignment](PROJECT/3-COMPLETED/MARATHON-HARNESS.md#model-assignment-build-track-guidance).
    57	
    58	> **Operational note (carve-out — operationally critical):** Gemini CLI retired 2026-06-19; **agy**
    59	> (Antigravity CLI) is the permanent cross-model lane. **Run agy turns sandbox-OFF** (it exits 0 with
    60	> empty output when its backend is blocked) and an agy lane is **cost-blind** (no token output).
    61	> Detail: [MARATHON-HARNESS.md → Operational note](PROJECT/3-COMPLETED/MARATHON-HARNESS.md#operational-note--cross-model-lane).
    62	
    63	## Ledger
    64	
    65	### Queue / parked intake
    66	- **GH-118 · Make Aider edit formats more forgiving for OpenRouter models** 🆕 **captured 2026-07-03 · rated · live-confirmed** — Aider natively uses a 'whole' or 'udiff' edit format depending on the model, but unknown OpenRouter models (like GLM-5.2) often default to formats they don't strictly follow (e.g. outputting standard diffs instead of 'whole' file), causing Aider to fail with 'no tracked changes'. **2026-07-03 live tests confirmed the diagnosis and the fix on two models:** GLM-5.2 (first attempt: no edit emitted at all, just chat; retry with `AIDER_FLAGS=--edit-format diff` produced valid SEARCH/REPLACE) and Nemotron Ultra 3 free tier (same 'whole' default — zero nvidia/nemotron entries anywhere in Aider's model-settings.yml or heuristic chain — failed by emitting a raw unified-diff hunk, reproducing the original bug report almost exactly). Revised fix: document `AIDER_FLAGS=--edit-format diff` (already a passthrough) rather than adding a new `AIDER_EDIT_FORMAT` var; maintain a running known-model compat note. cx/risk/eff 2/1/2. → [GH-118-AIDER-OPENROUTER-FORMAT.md](PROJECT/1-INBOX/GH-118-AIDER-OPENROUTER-FORMAT.md) · [#118](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/118)
    67	- **GH-119 · aider-turn.sh: reviewer can auto-add and edit out-of-scope tracked files under --yes-always; all-or-nothing containment discards the valid in-lane edit too** ✅ **SHIPPED 2026-07-03 (`93e2366`); closed 2026-07-04 · sibling of #54/#107** — surfaced live while testing GH-118's fix: GLM-5.2, acting as Reviewer, found a real bug and emitted a valid SEARCH/REPLACE for the relay file, but also emitted an edit for `marathon-drive.sh` (never added to the chat) which Aider's `--yes-always` auto-confirmed adding. The off-lane guard correctly caught it but discarded the *entire* turn, including the valid relay-file review. Same containment mechanism as #54/#107, different (deliberate, role-violating) trigger. Fixed: pre-seeds the diff's changed files as `--read` for review-only turns (`ALLOW_PATHS=""`) so they're structurally unwritable regardless of `--yes-always`; new `test/aider-turn.sh` case; independently re-verified via two reverse-dogfood reviews (24-file scale, zero scope-creep both times). cx/risk/eff 2/2/2. → [GH-119-AIDER-REVIEWER-SCOPE-CREEP.md](PROJECT/3-COMPLETED/GH-119-AIDER-REVIEWER-SCOPE-CREEP.md) · [#119](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/119)
    68	- **GH-120 · Build a fuzzy-match OpenRouter model-name lookup table (alias → canonical slug)** ✅ **SHIPPED 2026-07-03 (`17e2681`); closed** — resolving colloquial model names ("GLM 5.2", "Nemotron Ultra 3") to canonical OpenRouter slugs currently required a live API query every time. Shipped: `relay-automation/openrouter-model-aliases.yml` + `resolve-model-alias.sh` (4-tier fuzzy match) + `test/model-alias.sh` (10/10), wired into `validate.sh`, documented. Independently re-verified via a GLM 5.2 reverse-dogfood review, which also caught and fixed a stale README claim (`1642304`). cx/risk/eff 1/1/2. → [GH-120-OPENROUTER-MODEL-ALIAS-TABLE.md](PROJECT/3-COMPLETED/GH-120-OPENROUTER-MODEL-ALIAS-TABLE.md) · [#120](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/120)
    69	- **GH-117 · fix(marathon-drive): --dry-run must probe builder/reviewer binary before mutating tick state** 🆕 **captured 2026-07-03 · rated** — `marathon-drive.sh` doesn't probe builder/reviewer binary availability before seeding tick state. Missing binary errors fire after the tick task is already seeded and spent (no recovery without a fresh relay-task id). Fix: binary probe after arg parsing, before any tick mutation — catches missing `claude`/`agy`/`codex` on both `--dry-run` and live runs. Found in a live 3-phase marathon run. cx/risk/eff 2/1/2. → [#117](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/117)
    70	- **GH-116 · fix(tick): misleading 'break' error on open tasks + marathon retry flag** 🆕 **captured 2026-07-03 · rated** — two bugs: (a) `tick break` on an `open` (never-claimed) task says "only the claiming agent can mutate it" — misleading; real problem is the task is not `claimed` at all (fix landed in `src/scope.js`); (b) `marathon.sh` has no retry flag — recovering a spent task requires manually renaming the phase id in YAML. Suggested: `--retry <phase-id>` appends an attempt counter to the derived relay-task name. Found in live run. cx/risk/eff 2/2/2. → [#116](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/116)
    71	- **GH-114 · chore: remove deprecated gemini-turn.sh and scrub dead GEMINI references** 🆕 **captured 2026-07-03 · rated** — `gemini-turn.sh` marked DEPRECATED 2026-06-19; Gemini CLI phased out. Delete the shim, remove its README row and `GEMINI_AGENT` comment from `marathon-agent.sh`. `agy-turn.sh` is the live permanent replacement. **✅ Follow-up gap found + fixed 2026-07-03:** the original `2b5f8a3` fix deleted `relay-automation/gemini-turn.sh` and dropped `gemini` from `marathon-drive.sh`'s help/validation, but left 5 test files still hardcoding `--reviewer gemini` / `RELAY_AGENT=gemini` / a direct reference to the deleted shim (`test/gemini-turn.sh`, `test/relay-turn-timeout.sh`, `test/marathon-yaml.sh`, `test/marathon-drive.sh`, `test/xyz-harness-hooks.sh`) — surfaced when today's GH-118/119/120 marathon ran the full suite (6 failures, all traced to this one root cause via zero-diff confirmation against pre-marathon HEAD). Fixed: deleted the dangling `test/gemini-turn.sh` (and its now-invalid `validate.sh` entry), swapped the other 4 files' gemini usage to `agy` (discovering along the way that `agy-turn.sh`'s auth pre-flight + empty-log guard needed dedicated stubs, unlike codex/claude). `validate.sh`: **90/90**. cx/risk/eff 1/1/1. → [#114](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/114)
    72	- **GH-113 · fix(marathon-yaml): validator rejects agy reviewer — blocks multi-phase YAML plans** 🆕 **captured 2026-07-03 · rated** — `marathon-yaml.js:114` hard-codes `codex|gemini` allowlist; `MARATHON.example.yaml` documents and uses `reviewer: agy`; `marathon-drive.sh` already routes `agy*`→`AGY_AGENT`. Blocking bug: any multi-phase YAML plan with an agy reviewer phase fails at parse time. Single-phase `marathon-drive.sh --reviewer agy` runs are unaffected. One-line regex fix. **✅ Follow-up gap found + fixed 2026-07-03:** `test/marathon-yaml.sh`'s reviewer-rejection assertion hardcoded the pre-agy error string (`"must start with codex or gemini"`), which went stale the moment the actual message changed to `"must start with codex, gemini, or agy"` when agy was added — a false failure, not a real regression. Relaxed the assertion to check the `"must start with codex"` substring (resilient to future prefix-list changes) instead of hardcoding the full message. Note: `gemini` remains a genuinely accepted reviewer prefix in `src/marathon-yaml.js` itself (out of scope for this test-only fix). cx/risk/eff 1/1/1. → [#113](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/113)
    73	- **GH-112 · Spike: progressive Python port — boundary decision + dogfood architecture** 🆕 **captured 2026-07-03 · rated** — one spike lane answers three questions before any port work is queued: (1) what stays Bash permanently (source-dep graph of relay-turn-lib.sh), (2) Option A (discrete Python CLIs behind Bash shims, safest) vs Option B (Python orchestrator with Bash FFI, higher payoff), (3) test-bridge contract (85 shell tests must stay green during transition). If boundary is clean → one follow-up issue per turn script, marathon-waveable. Deliverable: a `decisions/` record, not code. cx/risk/eff 3/3/2. → [GH-112-PYTHON-PORT-SPIKE.md](PROJECT/1-INBOX/GH-112-PYTHON-PORT-SPIKE.md) · [#112](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/112)
    74	- **GH-109 · Gemini 3.1 Deep Think audit — watchdog process leak, tmp collision, DRY turn scripts, Python inline extraction** 🆕 **captured 2026-07-03 · rated** — 4 of 5 findings actioned: orphaned `sleep` grandchild leak in `consult.sh` watchdog (resource bug), `/tmp` permission collision in `relay-xyz-guard.sh` (trivial `$UID` fix), inline Python heredoc extraction to discrete utils (scoped-down Item 5), and DRY turn-script audit (scoped-down Item 1 — extend relay-turn-lib.sh, not a new dispatcher). Item 4 (retire scanner for Gitleaks/TruffleHog) declined — no-external-dep constraint. cx/risk/eff 3/3/3. → [GH-109-GEMINI-FEEDBACK.md](PROJECT/1-INBOX/GH-109-GEMINI-FEEDBACK.md) · [#109](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/109)
    75	- **GH-110 · Fable 5 Max audit — shellcheck + vendor integrity + strict-mode hardening** 🆕 **captured 2026-07-03 · rated** — Fable 5 Max ran shellcheck (63 findings, almost all cosmetic), executed all 85 tests in a clean Linux container, and diffed the vendor tarball. Five valid findings: broken test assertion in `xyz-vendor.sh:140`, stale `relay-pkg.tar.gz` (safety core — also the GH-104 remaining follow-up), 8/85 vendored-copy test failures, 788-line JS heredoc invisible to the Tier-1 check gate, and undocumented strict-mode convention. Phased: P1 quick fixes (~1 hr), P2 vendor integrity (~2–3 hrs), P3 code quality (~1 day). cx/risk/eff 3/2/3. → [GH-110-SHELLCHECK-VENDOR-FIXES.md](PROJECT/1-INBOX/GH-110-SHELLCHECK-VENDOR-FIXES.md) · [#110](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/110)
    76	- **GH-87 · Deep Research mode — provider-agnostic grounded search seam (Agy Gemini Search first adapter)** ✅ **Phase 1 MERGED 2026-07-04 (PR #122)** — the new Aider-capable harness needs a first-class grounded-search tool without hard-wiring the whole system to one vendor. Local framing intentionally keeps the **search-provider seam provider-agnostic** while taking **Agy Gemini Search** as the first backend (via the Agy CLI), with Perplexity as a follow-up phase. Shipped: `relay-automation/deep-research.mjs` (zero-dep Node adapter, runs `agy -p` in a throwaway tmpdir, fail-closed typed errors, normalized `{answer, citations, query, provider, model, raw}`) + `test/deep-research.sh` (21 assertions), wired into `validate.sh`. Reviewed via automated agy relay (Approved) + operator code review. Phase-1 limitation: `--temperature`/`--max-tokens` recorded in `raw.config` but not yet passed to `agy`. cx/risk/eff 3/2/3. → [GH-87-DEEP-RESEARCH-MODE.md](PROJECT/3-COMPLETED/GH-87-DEEP-RESEARCH-MODE.md) · [#87](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/87)
    77	- **GH-86 · marathon-plan — surface PR-review lanes so they don't silently drop** 🆕 **captured 2026-07-02 · rated** — `marathon-plan.sh` generates only build lanes; PR-review lanes live only in a manual `PR-REVIEW-QUEUE-<date>.md` overlay nothing surfaces, so two review lanes (PR #79/#81) were silently never run (caught 2026-07-02). Fix (Level 1): the plan prints a "Review lanes (run via relay-xyz)" section when today's overlay has open lanes. cx/risk/eff 2/1/2. → [GH-86-SURFACE-REVIEW-LANES.md](PROJECT/1-INBOX/GH-86-SURFACE-REVIEW-LANES.md) · [#86](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/86)
    78	- **GH-61 · CI GitHub Actions (Tier 1 lint/doc-hygiene + Tier 2 validate.sh)** ✅ **Tier 1 SHIPPED 2026-07-02 (`d9b8a14`, marathon dogfood — codex + agy Approved); Tier 2 held for the operator runner decision** — `.github/workflows/ci.yml` (single `ubuntu-latest` job: `shellcheck -S error` + `bash -n` + `node --check` + settings-JSON validate + `pdda.sh run`) + a dependency-free `test/ci-workflow.sh` wired into `validate.sh` (**80/80**). The run reproduced **#59** live (allowlisted artifact in a new untracked dir → spurious off-lane exit 6). **Tier 2 remaining:** running `./validate.sh` inside CI carries an unresolved `macos-latest` (fast, ~10× minutes) vs `ubuntu-latest` + portability/skip-gating decision — reserved for the operator; #61 stays open for it. no CI today; add Actions to catch the ~80% (bash logic + doc/path drift). **Tier 1** (cheap, always-green, no auth): `shellcheck` + `bash -n` on all `*.sh`, `node --check`/JSON-validate, `utils/pdda/pdda.sh run` full-mode. **Tier 2** (the real gate): `./validate.sh` 69-test suite — needs a portability + live-agent skip-gating pass, and a runner decision (`macos-latest` fast/~10× minutes vs `ubuntu` cheap/needs the pass) left open; don't make it *required* until reliably green. Marathon-sequenceable: Tier 1 = independent quick-win lane; Tier 2 depends on the skip-gating sub-task. → [GH-61-CI-GITHUB-ACTIONS.md](PROJECT/1-INBOX/GH-61-CI-GITHUB-ACTIONS.md) · brief: [gh-61-ci-tier1-brief.md](PROJECT/2-WORKING/briefs/gh-61-ci-tier1-brief.md) · [#61](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/61)
    79	- **GH-41 · `task.done` not terminal vs higher-epoch reclaim (silent token resurrection)** 🐞 ✅ **SHIPPED 2026-07-03 (Plan A lane 1 — PR #99)** — latent kernel gap (GH-40 canary #1): in `src/project.js` `foldWithMeta` a completed task was silently resurrected by a later higher-epoch `task.claimed` (`done`→`claimed`, 0 rejections). **Option A (terminality-seal)** landed (`/consult` Codex + agy unanimous; [decisions/2026-07-02-terminality-seal.md](decisions/2026-07-02-terminality-seal.md)): a terminal is now authorized against `ownerAsOf(terminal.ts)` (not the global winner), and once sealed every later claim is rejected as the new distinct reason `claim-after-terminal` — never a `done`→`claimed` flip. Canary **inverted** (`verify-fixture.sh`: `done 1 claim-after-terminal`; control `done 0`); all projection/tick/chaos suites green, no epoch-fence regression. Option B deferred. cx/risk/eff 4/4/3. → [GH-41-DONE-NOT-TERMINAL.md](PROJECT/3-COMPLETED/GH-41-DONE-NOT-TERMINAL.md) · [#41](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/41)
    80	- **GH-23 · Cursor CLI lane (3rd cross-model worker)** ⏸️ **parked-by-operator 2026-07-02** — add Cursor CLI as a Path-A worker (net-new `relay-automation/cursor-turn.sh` mirroring `codex-turn.sh`/`agy-turn.sh`). Assessed lane-shaped (2/2/2, shim) BUT (a) no capture doc yet and (b) only buildable if Cursor CLI has a headless print + auto-approve mode (unverified). Operator's call 2026-07-02: **skip/park** — Codex + agy already give cross-model coverage; revisit if a 3rd lane is wanted. → [#23](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/23)
    81	- **GH-30 · optional centralized transcript archive** ✅ **ALL PHASES SHIPPED 2026-07-03 (Plan A lane 5 complete)** — optional `XYZ_ARCHIVE_ROOT` redirects relay/consult/marathon transcripts out of each foreign repo's `relay-system/` into one namespaced archive; default unset = byte-for-byte current. **Phases 1–2:** single resolver `rtl_transcript_root` + `rtl_repo_slug` in `relay-turn-lib.sh` (Model-A validation: absolute + exists + git repo, else HARD ERROR), and all writers derive their transcript base from it. **Phase 3 (Model A, risk-4 core):** `rtl_init` flags `RTL_ARCHIVE_MODE` when the relay file's git repo ≠ `RTL_ROOT`, and `rtl_enforce` commits the **transcript into the archive** via an isolated `git -C` pathspec commit while the **code artifact + `.tick` token stay on the target** — target tree free of `relay-system/`, no transcript commit in target history, and the isolated archive commit can never orphan a concurrent peer commit (GH-13 guard target-only, holds when token-tree ≠ transcript-tree). **Phase 4:** `extract-relay-telemetry.sh` reads the resolver, aggregating across all `<repo-slug>/` dirs. **Phase 5:** `new-relay.sh` wired; `CONSUMING.md` + `README.md` document the contract; CHANGELOG bet recorded. New `test/archive-commit.sh` (16) + `test/archive-telemetry.sh` (3) → `validate.sh` green. cx/risk/eff 3/4/3. Kernel lane (`relay-turn-lib.sh`). → [GH-30-CENTRALIZED-TRANSCRIPT-ARCHIVE.md](PROJECT/3-COMPLETED/GH-30-CENTRALIZED-TRANSCRIPT-ARCHIVE.md) · [#30](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/30)
    82	- **Marathon dogfood · rebalance-OS parallel build queue (cross-repo, `--target-root`)** 🆕 **captured 2026-06-28** — **orchestrate this from Claude Code in THIS repo** as a real cross-repo dogfood: drive the rebalance-OS build queue (`PROJECT/4-MISC/QUEUE-2026-06-27.md` in that repo) via `swarm-preflight → marathon-drive --target-root <rebalance-OS clone>`. It has **3 collision-free lanes**: **SWIFT-APP** (Focus5Float VS Code focus-if-open Phase 1, claim `macOS/Apps/Focus5Float/Sources/**`), **BACKEND** (Unified Refresh/Restart v1 — signed Reminders helper + pulse server, claim `scripts/**`), **SPIKE** (Focus 5 App Store Phase 0, new `macOS/Apps/Focus5Native/**`). Disjoint write-globs ⇒ XYZ-safe concurrently. Per-lane gates differ (`swift build`+`FOCUS5_SELFTEST=1` / `pytest`+live `/api/refresh` / spike build); the *verify-and-archive* items finish on an **operator GUI litmus** (no CLI agent can satisfy a LaunchServices GUI check). Do not touch rebalance-OS outside an explicit, scoped lane run. **Status 2026-06-29: Lane A (Focus5Float VS Code focus-if-open) shipped INLINE — built by hand, NOT via the harness, since the marathon builder lane was then blocked by #14 — and pushed to rebalance `feat/apple-reminders-write`. Lanes B (refresh/restart v1) + C (App Store spike) handed to Agy (its app, direct in rebalance); the archive sweep is operator GUI-litmus. #14 is now fixed. **Status 2026-07-01: UNBLOCKED — GH-51 [1-kernel] closed 2026-06-30; `--target-root` containment normalization is fixed. Deferral condition met. Fire one scoped lane as the cross-repo proof.**
    83	- **GH-48 · generalize marathon-plan's zone model for cross-repo pre-pre-flight** 🔨 **design committed 2026-07-04, awaiting `/consult` before build** — `marathon-plan`'s swarm-vs-serialize classifier (`zoneOf()`) is hardcoded to xyz's own files (`relay-turn-lib`/`bin/tick`/`*-turn.sh`), even for contract-backed items (the proven-zone branch still runs the write-set through xyz-specific `KERNEL_PATHS`/`SHIM_RE`) — so idea #2 ("contract-only mode") alone would not have fixed the rebalance-OS case. Committed instead to idea #1: a configurable zone-rules list (path prefixes/regex + `maxPerWave` + `conservativeWhenInferred` + `penalty`), default = xyz's exact current values (zero regression). Idea #3 (foreign ledger/queue-format adapter) explicitly deferred. Acceptance gate is a live run against the real rebalance-OS 3-lane queue (Phase 2), not a synthetic fixture. → [GH-48-QUEUE-PLAN-CROSS-REPO-ZONES.md](PROJECT/2-WORKING/GH-48-QUEUE-PLAN-CROSS-REPO-ZONES.md) · [#48](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/48)
    84	- **Dueling/relay · commit-signal advance (file-driven mode)** 🟡 — **built + tested 2026-06-26** (agy review pending): `poll.sh --turn-source file` reads whose-turn from the relay `NEXT:` field, making the tick token **optional** — exactly what the first cross-repo dueling run needed when the Maintainer Claude worked straight off the relay file and never joined `tick`. Optional `--peer-commit-repo`/`--peer-commit-match` add the "advance on the peer's fix commit" signal (idle → run-runner only once a matching commit lands). `relay_field` now tolerates `**bold**` markdown keys; STATUS terminal + artifact-scope-clean still apply. 7 new assertions in [test/poll-driver.sh](test/poll-driver.sh); `validate.sh` **48/48**. → [poll.sh](relay-automation/poll.sh) · [Field findings](PROJECT/4-MISC/AUTOMATED-RELAY.md#field-findings--first-cross-repo-dueling-run-2026-06-26)
    85	- **Dueling/relay · token resilience for a non-participating peer + multi-round reuse** 🟡 — **core addressed by `--turn-source file`** (token-optional ⇒ no `parked suspect` stall and no `spent/reserved — not claimable` mid-run, the two lock failures from 2026-06-26). Residual (only when you DO use the tick token): a non-watchdog `reap`+`claim` reconcile path (still manual) and token-reuse semantics that survive N `release --to peer` round-trips. Lower priority now that file-source is the recommended dueling path. → [AUTOMATED-RELAY.md → Field findings](PROJECT/4-MISC/AUTOMATED-RELAY.md#field-findings--first-cross-repo-dueling-run-2026-06-26)
    86	- **Gate design · convergence gates that pin a *worse* code shape** 🐞 — the KWFS `#70` gate statically extracts a literal `return array(...)` from *each* of three formatter methods and asserts equality, which makes the issue's intended fix (one canonical method + delegate/delete the duplicates) **fail the gate** — the Maintainer was forced to keep three duplicated-but-identical literals, divergence the gate calls "converged." Generalizes: static-extraction needle gates can pin a less-maintainable shape than the refactor they exist to enforce. Fix direction: assert runtime output-key equality (or canonical + delegation), not three literals. → [AUTOMATED-RELAY.md → Field findings](PROJECT/4-MISC/AUTOMATED-RELAY.md#field-findings--first-cross-repo-dueling-run-2026-06-26)
    87	- **Orchestration · in-loop gate verification must run sandbox-off** 🟡 — an orchestrator/watcher re-running a target gate (`bash tests/run.sh`) under the Claude Bash sandbox **false-fails** (PHP can't create lock files → bogus "syntax errors"); the peer's un-sandboxed run is authoritative. Handle: in-loop gate self-checks run sandbox-off, or trust the peer's run + spot-confirm sandbox-off (memory: `codex-cli-needs-sandbox-disabled` family). → [AUTOMATED-RELAY.md → Field findings](PROJECT/4-MISC/AUTOMATED-RELAY.md#field-findings--first-cross-repo-dueling-run-2026-06-26)
    88	- **Tooling · agy reliability testing** ⏸️ parked — proposal + 3 dogfoods this session: agy **clean as a reviewer** (×2), **scope-sensitive as a builder** (failed a kernel-spanning task → F4/F6/F7 contained; succeeded on a small bounded one). Resume to run the S1–S10 matrix. → [AGY-RELIABILITY-TESTING.md](PROJECT/1-INBOX/AGY-RELIABILITY-TESTING.md)
    89	- **Tooling · front-door onboarding health** 🟡 parked — read-only audit shipped → [FRONTDOOR.md](PROJECT/4-MISC/FRONTDOOR.md) (continuous deterministic dashboard; 10 findings, re-runnable checks) + a phased remediation plan. Verdict ⚠️ Bumpy: clone-to-working works (`validate.sh` 36/36, secrets clean), but stale test counts (3 docs) + 2 dead README links + a phantom-path `CLAUDE.md` + undocumented `--target-root`/`install.sh` remain. Phases 1–3 queued (doc-only). → [FRONT-DOOR/2026-06-22.md](PROJECT/1-INBOX/FRONT-DOOR/2026-06-22.md)
    90	- **PDDA · feedback-synthesis direction** 🟡 parked — **proposal (1-INBOX), agy-reviewed 2026-06-23**: reduces the three June 23 external feedback notes (Perplexity/ChatGPT/Gemini) to one direction — keep PDDA a *thin repo-governance + safety layer*. Near-term scope = Phases 1–2 (constitution/positioning + contract/mode hardening); Phases 3–5 (artifact ergonomics, the Perplexity-only evidence bridge, integrations) deferred. Relay-reviewed by agy: 1 Blocker + 3 Should applied → **Approved**. Awaiting promotion decision to `2-WORKING`. → [PDDA-FEEDBACK-SYNTHESIS-PLAN.md](PROJECT/1-INBOX/PDDA/PDDA-FEEDBACK-SYNTHESIS-PLAN.md) · relay [pdda-feedback-synthesis.md](relay-system/2026-06-23/pdda-feedback-synthesis.md)

web search: 
web search: 
codex
There’s a second-order risk now: the design narrows on classification, but the live acceptance step is phrased as if `marathon-plan` can already consume a foreign queue doc. I’m checking the parser path to see whether that assumption is actually true.
exec
/bin/zsh -lc "nl -ba utils/marathon-plan.sh | sed -n '288,340p'" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-79403-29214
 succeeded in 0ms:
   288	// ── ledger parse (the parser lifted + extended from roadmap-dashboard.sh) ──────
   289	function stripMd(v) {
   290	  return v.replace(/`([^`]+)`/g, "$1").replace(/\*\*([^*]+)\*\*/g, "$1")
   291	    .replace(/\*([^*]+)\*/g, "$1").replace(/\[([^\]]+)\]\(([^)]+)\)/g, "$1").trim();
   292	}
   293	function parseBullet(block, section) {
   294	  const text = block.map((l) => l.trim()).join(" ").replace(/\s+/g, " ").trim();
   295	  const titleMatch = text.match(/^- \*\*(.+?)\*\*/);
   296	  const title = titleMatch ? stripMd(titleMatch[1]) : stripMd(text.replace(/^- /, ""));
   297	  let status = "—";
   298	  for (const e of KNOWN_EMOJI) { if (text.includes(e)) { status = e; break; } }
   299	  const links = [];
   300	  const re = /\[([^\]]+)\]\(([^)]+)\)/g;
   301	  let m;
   302	  while ((m = re.exec(text)) !== null) links.push({ label: m[1], target: m[2] });
   303	  return { title, status, links, raw: text, section };
   304	}
   305	function parseLedger(raw) {
   306	  const lines = raw.split(/\r?\n/);
   307	  const out = [];
   308	  let inLedger = false, current = null;
   309	  for (let i = 0; i < lines.length; i++) {
   310	    const line = lines[i];
   311	    if (!inLedger) { if (/^##\s+Ledger\s*$/.test(line.trim())) inLedger = true; continue; }
   312	    if (/^##\s+/.test(line) && !/^##\s+Ledger\s*$/.test(line.trim())) break;
   313	    const sm = line.match(/^###\s+(.+?)\s*$/);
   314	    if (sm) { current = SECTIONS.includes(sm[1].trim()) ? sm[1].trim() : null; continue; }
   315	    if (!current || !/^- \*\*/.test(line)) continue;
   316	    const block = [line];
   317	    while (i + 1 < lines.length) {
   318	      const nx = lines[i + 1];
   319	      if (/^###\s+/.test(nx) || /^##\s+/.test(nx) || /^- \*\*/.test(nx)) break;
   320	      block.push(nx); i += 1;
   321	    }
   322	    out.push(parseBullet(block, current));
   323	  }
   324	  return out;
   325	}
   326	
   327	// ── item resolution ──────────────────────────────────────────────────────────
   328	function ghIssueOf(item) {
   329	  // The canonical issue is the leading "GH-NN ·" in the TITLE. An in-prose issues/ link (e.g. GH-16's
   330	  // body cites #17/#11/…) is a reference, not the item's identity — so the title WINS over links; only
   331	  // fall back to the first issue link when the title carries no GH-NN (agy QA r4 [Blocker]).
   332	  const t = item.title.match(/\bGH-(\d+)\b/);
   333	  if (t) return Number(t[1]);
   334	  for (const l of item.links) {
   335	    const m = l.target.match(/github\.com\/[^\s)]+\/issues\/(\d+)/);
   336	    if (m) return Number(m[1]);
   337	  }
   338	  return null;
   339	}
   340	function docOf(item) {

exec
/bin/zsh -lc "nl -ba PROJECT/4-MISC/QUEUE-2026-06-27.md | sed -n '1,220p'" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-79403-29214
 succeeded in 0ms:
     1	---
     2	ratings_exempt: true
     3	title: Parallel Automation Queue — what can be built simultaneously, safely
     4	status: Archived (4-MISC) — moved from 2-WORKING 2026-07-03, stale (PDDA maintenance sweep)
     5	created: 2026-06-27
     6	updated: 2026-06-27
     7	owner: noel
     8	branch: main
     9	doc_type: project
    10	source: ../../ROADMAP.md (open ledger entries as of 2026-06-27)
    11	goal: >
    12	  A concurrency plan, not a roadmap. Groups the ROADMAP's open work into lanes that
    13	  can run AT THE SAME TIME without colliding, and names the lanes that must run one
    14	  at a time. "Safe" here means: no two concurrent lanes write the same file.
    15	---
    16	
    17	# QUEUE 2026-06-27 — Parallel Automation Plan
    18	
    19	> Derived from [ROADMAP.md](../../ROADMAP.md). The roadmap says **what** and **why**; this
    20	> says **what can run together right now**. Execution detail still lives in each
    21	> `PROJECT/**` doc — this is a scheduling overlay.
    22	
    23	## Status
    24	
    25	| What was just completed | What's next |
    26	|---|---|
    27	| **GH-29 (Wave 1 lead) shipped inline 2026-06-27** — the kernel commit-path unblock is done (`validate.sh` 54/54), so cross-repo dogfooding is no longer gated. Remaining open work is grouped into collision-safe lanes: the `relay-turn-lib.sh` containment kernel is the single serialization bottleneck; kernel lanes (GH-33 P3–4 → GH-30 → GH-13/14/3) run one-at-a-time, shims (GH-37/36/23) and independent lanes (GH-24/27/19, Part B chaos, front-door) fan out. | **Fire the rest of Wave 1** — `GH-37` ‖ `GH-36p` ‖ `GH-24` ‖ Part B chaos (now all disjoint, no kernel lane among them) via `swarm-preflight` → `marathon-drive`, scoped by `ALLOW_PATHS`. Each first needs a 2-WORKING capture doc + preflight contract. Re-derive waves when ledger priorities shift. |
    28	
    29	## The one safety rule
    30	
    31	Two lanes are safe to run concurrently **iff their write-sets are disjoint**. The
    32	collision-free claim/heartbeat machinery (`tick`, `swarm-preflight`, `ALLOW_PATHS`,
    33	worktree isolation) enforces this *mechanically* — but only if we hand it
    34	non-overlapping path scopes. So the whole plan reduces to one fact:
    35	
    36	> **`relay-automation/relay-turn-lib.sh` (26.7K) is the containment kernel.**
    37	> Every lane that edits it is mutually exclusive with every other lane that edits it.
    38	> It is the serialization bottleneck. Everything else can fan out.
    39	
    40	## Collision map
    41	
    42	| Zone | Files written | Parallel-safe? | Open work here |
    43	|---|---|---|---|
    44	| **Kernel** | `relay-turn-lib.sh`, `bin/tick`, `relay-drive.sh` | ❌ **serialize — one lane at a time** | GH-29, GH-33 P3–4, GH-30, GH-13, GH-14, GH-3 |
    45	| **Shims** | `codex-turn.sh` · `agy-turn.sh` · `consult.sh` · NEW `cursor-turn.sh` | ✅ one lane **per file** | GH-36 (codex), GH-37 (consult), GH-23 (new file) |
    46	| **Telemetry / dashboard** | `utils/telemetry/*`, `utils/roadmap-dashboard.sh` | ✅ independent | GH-24, GH-27 |
    47	| **Adversarial / chaos** | `test/chaos-*`, `ADVERSARIAL-HARDENING.md` | ✅ mostly new files | Part B Phase 2 |
    48	| **Hooks / docs** | `relay-automation/hooks/*`, `FRONTDOOR.md`, READMEs | ✅ independent | GH-19, front-door |
    49	
    50	Shim lanes are parallel-safe **with each other** because each shim is its own file —
    51	but any shim lane that needs a *new kernel API* must wait for the kernel lane that
    52	adds it (a dependency edge, not a collision).
    53	
    54	## Lane buckets
    55	
    56	### A — Kernel-serial queue (exactly ONE active, model: **Opus**)
    57	Trust-critical containment reasoning → Opus. Run in priority order, never overlapping:
    58	
    59	1. **GH-29 — cross-repo new-file commit gap** ✅ **DONE 2026-06-27** (per-path `git add -A`; `validate.sh` 54/54). The unblock is shipped. → [#29](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/29)
    60	2. **GH-33 Phases 3–4 — background dispatch + Path A/B unification** (gated on operator GO; the cross-model-hands-free win). → [#33](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/33)
    61	3. **GH-30 — centralized transcript archive** (`XYZ_ARCHIVE_ROOT`; touches commit semantics). → [#30](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/30)
    62	4. **GH-13 / GH-14 / GH-3 — containment hardening + concurrency** (the GH-16 epic's kernel slices). → [#13](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/13) [#14](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/14) [#3](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/3)
    63	
    64	### B — Shim lanes (parallel, one per file, model: **Sonnet High**)
    65	Mechanical, well-bounded, additive. Fire together:
    66	
    67	- **GH-37 — agy consult auth hang** ✅ **preflight-ready** (`swarm-preflight --gh-issue 37` → ready) → `relay-automation/consult.sh`: fast pre-flight auth probe, skip the lane in seconds instead of a 300s hang. **Builder = Codex** (agy can't build its own auth fix). → [#37](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/37)
    68	- **GH-36 (primary) — Codex `.tick` sandbox friction** ✅ **DONE 2026-06-28** — fixed via marathon dogfood (codex built `--add-dir "$ROOT/.tick"`, agy-approved); `validate.sh` 54/54; #36 closed. *(Secondary "warn into all shims" touches the kernel → still in bucket A.)* → [#36](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/36)
    69	- **GH-23 — Cursor CLI lane** → NEW `relay-automation/cursor-turn.sh` (mirror `codex-turn.sh` containment). Additive; only reads the kernel. *Best scheduled after GH-29 so it mirrors the fixed commit path.* → [#23](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/23)
    70	
    71	### C — Independent lanes (parallel, no relay-automation overlap)
    72	Each is "built, needs the last mile" or a fresh self-contained track:
    73	
    74	- **GH-24 — relay telemetry extractor**: ⚠️ **NOT a build lane** — the script (`utils/telemetry/extract-relay-telemetry.sh`) already exists, so `swarm-preflight` would exit 4 (already-landed). This is a **verify-and-close**: run it against live `relay-system/`, eyeball the aggregated output, then close #24. Do it inline, not via marathon. → [#24](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/24)
    75	- **GH-27 — ROADMAP dashboard**: wire regen into the doc-update flow + close. → [#27](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/27)
    76	- **GH-19 — relay-xyz skill guard**: confirm an organic catch in a fresh session + close. → [#19](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/19)
    77	- **Part B Phase 2 — chaos suite & auto-recovery**: new `test/` chaos cases. → [ADVERSARIAL-HARDENING.md](ADVERSARIAL-HARDENING.md)
    78	- **Front-door remediation** (Phases 1–3, doc-only): stale test counts, dead links, phantom-path `CLAUDE.md`. → [FRONTDOOR.md](../../FRONTDOOR.md)
    79	
    80	## Recommended waves
    81	
    82	**Wave 1 — `GH-29` ✅ done (inline). Remaining, fire concurrently (zero collisions):**
    83	`GH-37` ‖ `GH-36p` ‖ `Part B chaos` — all preflight-ready/independent, disjoint write-sets, no kernel
    84	lane among them. `GH-24` is an **inline verify-and-close** (not a marathon lane — script already exists).
    85	
    86	**Wave 2 — after GH-29 merges:**
    87	`GH-33 P3–4` (kernel, needs the fixed commit path) → then `GH-23` (cursor, mirrors it) ‖ `GH-27` close ‖ `GH-19` close ‖ front-door docs.
    88	
    89	**Wave 3 — kernel-heavy, run last, one at a time:**
    90	`GH-30` (biggest commit-semantics change) → `GH-13/14/3` (the GH-16 concurrency epic).
    91	
    92	## How to fire a lane
    93	
    94	Per lane, the existing pipeline applies — no new control plane:
    95	
    96	```
    97	utils/swarm-preflight.sh --project-doc <PROJECT/**/doc.md>   # or --issues "#29"
    98	   → ready packet (candidate/freshness/fix-still-required + lane assignment)
    99	relay-automation/marathon-drive.sh ...   # build→gate→review, contained
   100	```
   101	
   102	- **Lane scoping:** give each lane an `ALLOW_PATHS` matching only its zone above; that
   103	  is what makes "safe to parallel" true rather than hoped-for.
   104	- **Lane assignment:** kernel → Codex builder + agy reviewer (or Opus inline);
   105	  shims/independent → Sonnet High. Personal-data targets → agy reviewer-first.
   106	- **Never** run two kernel lanes at once, even in separate worktrees — see the memory
   107	  on commit-bypass orphaning a peer commit.
   108	
   109	---
   110	
   111	*This queue is a scheduling overlay on [ROADMAP.md](../../ROADMAP.md); when an item closes,
   112	update the roadmap ledger (source of truth) and re-derive waves here if priorities shift.*

exec
/bin/zsh -lc 'rg -n "QUEUE_PLAN_ROADMAP|QUEUE_PLAN_QUEUE_DIR|ROADMAP missing|## Ledger|SECTIONS =|parseLedger|PROJECT/2-WORKING" test/marathon-plan.sh utils/marathon-plan.sh' in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-79403-29214
 succeeded in 0ms:
utils/marathon-plan.sh:10:#   2. a SEQUENCED marathon-plan doc  PROJECT/2-WORKING/MARATHON-PLAN-YYYY-MM-DD.md — ratings-ranked, collision-lane
utils/marathon-plan.sh:30:# Exit: 0 clean · 2 usage · 3 ROADMAP missing/unparseable ·
utils/marathon-plan.sh:36:#   QUEUE_PLAN_ROOT / QUEUE_PLAN_ROADMAP / QUEUE_PLAN_QUEUE_DIR / QUEUE_PLAN_NOW / QUEUE_PLAN_TODAY
utils/marathon-plan.sh:57:ROADMAP="${QUEUE_PLAN_ROADMAP:-"$ROOT/ROADMAP.md"}"
utils/marathon-plan.sh:58:QUEUE_DIR="${QUEUE_PLAN_QUEUE_DIR:-"$ROOT/PROJECT/2-WORKING"}"
utils/marathon-plan.sh:70:  (default)        Print the validation report and write PROJECT/2-WORKING/MARATHON-PLAN-<today>.md.
utils/marathon-plan.sh:156:const SECTIONS = ["Queue / parked intake", "In progress", "Completed", "Deferred · vision"];
utils/marathon-plan.sh:305:function parseLedger(raw) {
utils/marathon-plan.sh:443:const ledger = parseLedger(raw);
utils/marathon-plan.sh:444:if (ledger.length === 0) { process.stderr.write("marathon-plan: no ledger items parsed (is '## Ledger' present?)\n"); process.exit(3); }
test/marathon-plan.sh:33:  mkdir -p "$root/PROJECT/2-WORKING"
test/marathon-plan.sh:42:  } >"$root/PROJECT/2-WORKING/$fn"
test/marathon-plan.sh:78:## Ledger
test/marathon-plan.sh:80:- **GH-100 · kernelA** 🆕 — kernel lane → [d](PROJECT/2-WORKING/GH-100-kernela.md) · [#100](https://github.com/o/r/issues/100)
test/marathon-plan.sh:81:- **GH-101 · kernelB** 🆕 — kernel lane → [d](PROJECT/2-WORKING/GH-101-kernelb.md) · [#101](https://github.com/o/r/issues/101)
test/marathon-plan.sh:82:- **GH-102 · indepA** 🆕 — independent → [d](PROJECT/2-WORKING/GH-102-indepa.md) · [#102](https://github.com/o/r/issues/102)
test/marathon-plan.sh:83:- **GH-103 · indepB** 🆕 — independent → [d](PROJECT/2-WORKING/GH-103-indepb.md) · [#103](https://github.com/o/r/issues/103)
test/marathon-plan.sh:84:- **GH-104 · shimDep** 🆕 — shim, scheduled after GH-100 → [d](PROJECT/2-WORKING/GH-104-shimdep.md) · [#104](https://github.com/o/r/issues/104)
test/marathon-plan.sh:87:doc="$A/PROJECT/2-WORKING/MARATHON-PLAN-$DAY.md"
test/marathon-plan.sh:125:## Ledger
test/marathon-plan.sh:127:- **GH-200 · closed item** 🟡 — listed but closed → [d](PROJECT/2-WORKING/GH-200-closed.md) · [#200](https://github.com/o/r/issues/200)
test/marathon-plan.sh:128:- **GH-210 · landed item** 🟢 — built → [d](PROJECT/2-WORKING/GH-210-landed.md) · [#210](https://github.com/o/r/issues/210)
test/marathon-plan.sh:129:- **GH-220 · partial item** 🟢 — partly built → [d](PROJECT/2-WORKING/GH-220-partial.md) · [#220](https://github.com/o/r/issues/220)
test/marathon-plan.sh:130:- **GH-221 · onesig item** 🟢 — only the emoji signal → [d](PROJECT/2-WORKING/GH-221-onesig.md) · [#221](https://github.com/o/r/issues/221)
test/marathon-plan.sh:131:- **GH-250 · gated item** 🟡 — gated on operator GO → [d](PROJECT/2-WORKING/GH-250-gated.md) · [#250](https://github.com/o/r/issues/250)
test/marathon-plan.sh:133:- **GH-230 · unrated item** 🆕 — missing a rating → [d](PROJECT/2-WORKING/GH-230-unrated.md) · [#230](https://github.com/o/r/issues/230)
test/marathon-plan.sh:134:- **GH-240 · dead pointer** 🆕 — doc link is broken → [d](PROJECT/2-WORKING/GH-240-missing.md) · [#240](https://github.com/o/r/issues/240)
test/marathon-plan.sh:138:doc="$B/PROJECT/2-WORKING/MARATHON-PLAN-$DAY.md"
test/marathon-plan.sh:161:## Ledger
test/marathon-plan.sh:163:- **GH-300 · low risk** 🆕 — → [d](PROJECT/2-WORKING/GH-300-low.md) · [#300](https://github.com/o/r/issues/300)
test/marathon-plan.sh:164:- **GH-301 · high risk** 🆕 — → [d](PROJECT/2-WORKING/GH-301-high.md) · [#301](https://github.com/o/r/issues/301)
test/marathon-plan.sh:166:run_qp "$C" >/dev/null 2>&1; doc="$C/PROJECT/2-WORKING/MARATHON-PLAN-$DAY.md"
test/marathon-plan.sh:209:## Ledger
test/marathon-plan.sh:211:- **GH-700 · free** 🆕 — → [d](PROJECT/2-WORKING/GH-700-free.md) · [#700](https://github.com/o/r/issues/700)
test/marathon-plan.sh:212:- **GH-701 · dep on held** 🆕 — depends on GH-710 → [d](PROJECT/2-WORKING/GH-701-dephld.md) · [#701](https://github.com/o/r/issues/701)
test/marathon-plan.sh:213:- **GH-710 · held (unrated)** 🆕 — → [d](PROJECT/2-WORKING/GH-710-held.md) · [#710](https://github.com/o/r/issues/710)
test/marathon-plan.sh:215:out="$(run_qp "$G" 2>/dev/null)"; doc="$G/PROJECT/2-WORKING/MARATHON-PLAN-$DAY.md"
test/marathon-plan.sh:229:## Ledger
test/marathon-plan.sh:231:- **GH-800 · kernel1** 🆕 — → [d](PROJECT/2-WORKING/GH-800-k1.md) · [#800](https://github.com/o/r/issues/800)
test/marathon-plan.sh:232:- **GH-801 · kernel2** 🆕 — → [d](PROJECT/2-WORKING/GH-801-k2.md) · [#801](https://github.com/o/r/issues/801)
test/marathon-plan.sh:233:- **GH-803 · kernel3** 🆕 — → [d](PROJECT/2-WORKING/GH-803-k3.md) · [#803](https://github.com/o/r/issues/803)
test/marathon-plan.sh:234:- **GH-802 · multi-dep** 🆕 — depends on GH-800, GH-801, and GH-803 → [d](PROJECT/2-WORKING/GH-802-multi.md) · [#802](https://github.com/o/r/issues/802)
test/marathon-plan.sh:236:run_qp "$H" >/dev/null 2>&1; doc="$H/PROJECT/2-WORKING/MARATHON-PLAN-$DAY.md"
test/marathon-plan.sh:249:## Ledger
test/marathon-plan.sh:251:- **GH-910 · epic umbrella** 🆕 — sequences the sub-issue [#911](https://github.com/o/r/issues/911) → [d](PROJECT/2-WORKING/GH-910-epic.md) · [#910](https://github.com/o/r/issues/910)
test/marathon-plan.sh:253:out="$(run_qp "$I" 2>/dev/null)"; doc="$I/PROJECT/2-WORKING/MARATHON-PLAN-$DAY.md"
test/marathon-plan.sh:277:## Ledger
test/marathon-plan.sh:279:- **GH-950 · existing artifact** 🆕 — all artifacts pre-exist → [d](PROJECT/2-WORKING/GH-950-existing.md) · [#950](https://github.com/o/r/issues/950)
test/marathon-plan.sh:280:- **GH-951 · genuine partial** 🆕 — genuine partial signals → [d](PROJECT/2-WORKING/GH-951-genuine.md) · [#951](https://github.com/o/r/issues/951)
test/marathon-plan.sh:284:doc="$J/PROJECT/2-WORKING/MARATHON-PLAN-$DAY.md"
test/marathon-plan.sh:309:## Ledger
test/marathon-plan.sh:311:- **GH-920 · producer** 🆕 — independent → [d](PROJECT/2-WORKING/GH-920-producer.md) · [#920](https://github.com/o/r/issues/920)
test/marathon-plan.sh:312:- **GH-921 · consumer** 🆕 — independent → [d](PROJECT/2-WORKING/GH-921-consumer.md) · [#921](https://github.com/o/r/issues/921)
test/marathon-plan.sh:313:- **GH-922 · report** 🆕 — independent → [d](PROJECT/2-WORKING/GH-922-report.md) · [#922](https://github.com/o/r/issues/922)
test/marathon-plan.sh:316:doc="$K/PROJECT/2-WORKING/MARATHON-PLAN-$DAY.md"
test/marathon-plan.sh:341:## Ledger
test/marathon-plan.sh:343:- **GH-930 · dir** 🆕 — independent → [d](PROJECT/2-WORKING/GH-930-dir.md) · [#930](https://github.com/o/r/issues/930)
test/marathon-plan.sh:344:- **GH-931 · file** 🆕 — independent → [d](PROJECT/2-WORKING/GH-931-file.md) · [#931](https://github.com/o/r/issues/931)
test/marathon-plan.sh:347:doc="$L/PROJECT/2-WORKING/MARATHON-PLAN-$DAY.md"
test/marathon-plan.sh:360:## Ledger
test/marathon-plan.sh:362:- **GH-940 · a** 🆕 — independent → [d](PROJECT/2-WORKING/GH-940-a.md) · [#940](https://github.com/o/r/issues/940)
test/marathon-plan.sh:363:- **GH-941 · b** 🆕 — independent → [d](PROJECT/2-WORKING/GH-941-b.md) · [#941](https://github.com/o/r/issues/941)
test/marathon-plan.sh:366:doc="$M/PROJECT/2-WORKING/MARATHON-PLAN-$DAY.md"

codex
I’ve got the relevant shell evidence. I’m still taking one pass through the code graph tooling because the repo asks for graph-first discovery, but the core consult is already grounded in the exact lines above.
mcp: codebase-memory-mcp/index_repository started
mcp: codebase-memory-mcp/index_repository (failed)
user cancelled MCP tool call
codex
**Answer**

1. The zone-rules idea mostly generalizes the current `kernel`/`shim` model, but not fully as written. The proposed fields do cover the obvious hardcoded pieces: `KERNEL_PATHS` → `pathPrefixes`, `SHIM_RE` → `pathRegex`, keyword inference → `inferKeywordRegex`, `ZONE_PEN` → `penalty`, max-one-kernel-per-wave → `maxPerWave: 1`, and inferred-shim serialization → `conservativeWhenInferred` ([plan](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-79403-29214/PROJECT/2-WORKING/GH-48-QUEUE-PLAN-CROSS-REPO-ZONES.md:87), [zoneOf](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-79403-29214/utils/marathon-plan.sh:350), [wave packer](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-79403-29214/utils/marathon-plan.sh:643)). But it misses at least three real behaviors if “exact current behavior” is the bar: current kernel classification also promotes any artifact under `contract.lanes.orchestrator_only` to kernel-owned, and that is not represented in the schema or Phase 1 notes ([utils/marathon-plan.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-79403-29214/utils/marathon-plan.sh:354)); current `SHIM_RE` is case-insensitive, while the JSON schema has no place to encode `/i` ([utils/marathon-plan.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-79403-29214/utils/marathon-plan.sh:153)); and current sort tie-breaks also hardcode zone order `independent < shim < kernel`, which the design does not mention preserving ([utils/marathon-plan.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-79403-29214/utils/marathon-plan.sh:659)). So: good direction, not yet a lossless spec.

2. Deferring the foreign ledger/queue-format adapter is the right call for the core GH-48 build. The repo’s own roadmap explicitly says the rebalance dogfood is already unblocked via per-lane `swarm-preflight --target-root <clone> → marathon-drive`, and that GH-48 is useful but “not the unblocker” ([ROADMAP.md](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-79403-29214/ROADMAP.md:45), [ROADMAP.md](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-79403-29214/ROADMAP.md:46), [ROADMAP.md](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-79403-29214/ROADMAP.md:83)). The competing “contract-only mode” rejection is also correct because `zoneOf()` still runs contract-backed artifacts through the hardcoded xyz rules today ([plan](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-79403-29214/PROJECT/2-WORKING/GH-48-QUEUE-PLAN-CROSS-REPO-ZONES.md:54), [utils/marathon-plan.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-79403-29214/utils/marathon-plan.sh:352)). The caveat is narrower: the Phase 2 acceptance text currently reads as if `marathon-plan` can already ingest an arbitrary foreign queue doc, but the real parser still expects `ROADMAP.md`, `PROJECT/2-WORKING`, a `## Ledger` section, and specific `###` subsection names ([utils/marathon-plan.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-79403-29214/utils/marathon-plan.sh:57), [utils/marathon-plan.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-79403-29214/utils/marathon-plan.sh:305), [utils/marathon-plan.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-79403-29214/utils/marathon-plan.sh:444), [plan](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-79403-29214/PROJECT/2-WORKING/GH-48-QUEUE-PLAN-CROSS-REPO-ZONES.md:154)). So the adapter can stay deferred, but the acceptance wording should stop implying native foreign-queue support.

3. Yes, there are precedence gaps that would surprise an operator. First, `QP_ZONES_FILE` is the wrong public seam name if this is meant to mirror existing test/env seams; the user-facing pattern in this script is `QUEUE_PLAN_*`, while `QP_*` is only the shell-to-embedded-Node internal bridge ([utils/marathon-plan.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-79403-29214/utils/marathon-plan.sh:35), [utils/marathon-plan.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-79403-29214/utils/marathon-plan.sh:120), [plan](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-79403-29214/PROJECT/2-WORKING/GH-48-QUEUE-PLAN-CROSS-REPO-ZONES.md:129)). Second, the failure mode for a malformed zones file needs to be explicit: for this classifier, silent fallback to xyz defaults on a foreign repo would be dangerous. Third, the doc needs to say what relative `--zones-config rebalance-os-zones.json` is relative to, especially when paired with `--target-root`; otherwise operators will reasonably wonder whether it resolves from cwd or the target repo ([plan](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-79403-29214/PROJECT/2-WORKING/GH-48-QUEUE-PLAN-CROSS-REPO-ZONES.md:131), [plan](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-79403-29214/PROJECT/2-WORKING/GH-48-QUEUE-PLAN-CROSS-REPO-ZONES.md:156)). Fourth, the built-in default must be resolved from the harness/tool root, not the target repo root, or vendored `.xyz` installs will misresolve it ([utils/marathon-plan.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-79403-29214/utils/marathon-plan.sh:43)).

**Findings**

- [Blocker] The design omits the current `orchestrator_only` → kernel reclassification path, so the claim that the default config preserves “exact current behavior” is false as written ([utils/marathon-plan.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-79403-29214/utils/marathon-plan.sh:354), [plan](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-79403-29214/PROJECT/2-WORKING/GH-48-QUEUE-PLAN-CROSS-REPO-ZONES.md:111)).

- [Should] The schema needs a way to preserve regex flags, or at least an explicit statement that `pathRegex` is compiled case-insensitive for the built-in shim rule; otherwise `SHIM_RE` is not faithfully encoded ([utils/marathon-plan.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-79403-29214/utils/marathon-plan.sh:153), [plan](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-79403-29214/PROJECT/2-WORKING/GH-48-QUEUE-PLAN-CROSS-REPO-ZONES.md:100)).

- [Should] The doc should not phrase Phase 2 as “run against the real rebalance queue” unless it also names the input-shape constraint or a temporary shim; current `marathon-plan` is still ROADMAP-ledger-specific, not a generic foreign queue reader ([utils/marathon-plan.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-79403-29214/utils/marathon-plan.sh:305), [plan](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-79403-29214/PROJECT/2-WORKING/GH-48-QUEUE-PLAN-CROSS-REPO-ZONES.md:156)).

- [Should] The precedence contract should use a consistent public env name (`QUEUE_PLAN_ZONES_FILE` is the natural fit), define malformed-file behavior, and define how relative `--zones-config` paths resolve under `--target-root` ([utils/marathon-plan.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-79403-29214/utils/marathon-plan.sh:35), [utils/marathon-plan.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-79403-29214/utils/marathon-plan.sh:120), [plan](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-79403-29214/PROJECT/2-WORKING/GH-48-QUEUE-PLAN-CROSS-REPO-ZONES.md:129)).

- [Nit] If “zero output diff” matters, the design should explicitly preserve today’s raw prefix semantics (`a === k || a.startsWith(k)`) and today’s zone tie-break order in sorting; both are behavior, not just implementation detail ([utils/marathon-plan.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-79403-29214/utils/marathon-plan.sh:359), [utils/marathon-plan.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-79403-29214/utils/marathon-plan.sh:659)).

- [Pass] Rejecting “contract-only mode” is correct; the hardcoded xyz classifier still runs on contract-backed items today, so that mode alone would not fix the rebalance case ([plan](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-79403-29214/PROJECT/2-WORKING/GH-48-QUEUE-PLAN-CROSS-REPO-ZONES.md:75), [utils/marathon-plan.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-79403-29214/utils/marathon-plan.sh:352)).

**Recommendation**

Build with named fixes: keep the zone-rules design, but add `orchestrator_only` fidelity, regex-flag fidelity, and explicit config-resolution/input-shape rules before implementation.
tokens used
93,088
**Answer**

1. The zone-rules idea mostly generalizes the current `kernel`/`shim` model, but not fully as written. The proposed fields do cover the obvious hardcoded pieces: `KERNEL_PATHS` → `pathPrefixes`, `SHIM_RE` → `pathRegex`, keyword inference → `inferKeywordRegex`, `ZONE_PEN` → `penalty`, max-one-kernel-per-wave → `maxPerWave: 1`, and inferred-shim serialization → `conservativeWhenInferred` ([plan](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-79403-29214/PROJECT/2-WORKING/GH-48-QUEUE-PLAN-CROSS-REPO-ZONES.md:87), [zoneOf](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-79403-29214/utils/marathon-plan.sh:350), [wave packer](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-79403-29214/utils/marathon-plan.sh:643)). But it misses at least three real behaviors if “exact current behavior” is the bar: current kernel classification also promotes any artifact under `contract.lanes.orchestrator_only` to kernel-owned, and that is not represented in the schema or Phase 1 notes ([utils/marathon-plan.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-79403-29214/utils/marathon-plan.sh:354)); current `SHIM_RE` is case-insensitive, while the JSON schema has no place to encode `/i` ([utils/marathon-plan.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-79403-29214/utils/marathon-plan.sh:153)); and current sort tie-breaks also hardcode zone order `independent < shim < kernel`, which the design does not mention preserving ([utils/marathon-plan.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-79403-29214/utils/marathon-plan.sh:659)). So: good direction, not yet a lossless spec.

2. Deferring the foreign ledger/queue-format adapter is the right call for the core GH-48 build. The repo’s own roadmap explicitly says the rebalance dogfood is already unblocked via per-lane `swarm-preflight --target-root <clone> → marathon-drive`, and that GH-48 is useful but “not the unblocker” ([ROADMAP.md](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-79403-29214/ROADMAP.md:45), [ROADMAP.md](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-79403-29214/ROADMAP.md:46), [ROADMAP.md](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-79403-29214/ROADMAP.md:83)). The competing “contract-only mode” rejection is also correct because `zoneOf()` still runs contract-backed artifacts through the hardcoded xyz rules today ([plan](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-79403-29214/PROJECT/2-WORKING/GH-48-QUEUE-PLAN-CROSS-REPO-ZONES.md:54), [utils/marathon-plan.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-79403-29214/utils/marathon-plan.sh:352)). The caveat is narrower: the Phase 2 acceptance text currently reads as if `marathon-plan` can already ingest an arbitrary foreign queue doc, but the real parser still expects `ROADMAP.md`, `PROJECT/2-WORKING`, a `## Ledger` section, and specific `###` subsection names ([utils/marathon-plan.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-79403-29214/utils/marathon-plan.sh:57), [utils/marathon-plan.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-79403-29214/utils/marathon-plan.sh:305), [utils/marathon-plan.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-79403-29214/utils/marathon-plan.sh:444), [plan](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-79403-29214/PROJECT/2-WORKING/GH-48-QUEUE-PLAN-CROSS-REPO-ZONES.md:154)). So the adapter can stay deferred, but the acceptance wording should stop implying native foreign-queue support.

3. Yes, there are precedence gaps that would surprise an operator. First, `QP_ZONES_FILE` is the wrong public seam name if this is meant to mirror existing test/env seams; the user-facing pattern in this script is `QUEUE_PLAN_*`, while `QP_*` is only the shell-to-embedded-Node internal bridge ([utils/marathon-plan.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-79403-29214/utils/marathon-plan.sh:35), [utils/marathon-plan.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-79403-29214/utils/marathon-plan.sh:120), [plan](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-79403-29214/PROJECT/2-WORKING/GH-48-QUEUE-PLAN-CROSS-REPO-ZONES.md:129)). Second, the failure mode for a malformed zones file needs to be explicit: for this classifier, silent fallback to xyz defaults on a foreign repo would be dangerous. Third, the doc needs to say what relative `--zones-config rebalance-os-zones.json` is relative to, especially when paired with `--target-root`; otherwise operators will reasonably wonder whether it resolves from cwd or the target repo ([plan](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-79403-29214/PROJECT/2-WORKING/GH-48-QUEUE-PLAN-CROSS-REPO-ZONES.md:131), [plan](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-79403-29214/PROJECT/2-WORKING/GH-48-QUEUE-PLAN-CROSS-REPO-ZONES.md:156)). Fourth, the built-in default must be resolved from the harness/tool root, not the target repo root, or vendored `.xyz` installs will misresolve it ([utils/marathon-plan.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-79403-29214/utils/marathon-plan.sh:43)).

**Findings**

- [Blocker] The design omits the current `orchestrator_only` → kernel reclassification path, so the claim that the default config preserves “exact current behavior” is false as written ([utils/marathon-plan.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-79403-29214/utils/marathon-plan.sh:354), [plan](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-79403-29214/PROJECT/2-WORKING/GH-48-QUEUE-PLAN-CROSS-REPO-ZONES.md:111)).

- [Should] The schema needs a way to preserve regex flags, or at least an explicit statement that `pathRegex` is compiled case-insensitive for the built-in shim rule; otherwise `SHIM_RE` is not faithfully encoded ([utils/marathon-plan.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-79403-29214/utils/marathon-plan.sh:153), [plan](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-79403-29214/PROJECT/2-WORKING/GH-48-QUEUE-PLAN-CROSS-REPO-ZONES.md:100)).

- [Should] The doc should not phrase Phase 2 as “run against the real rebalance queue” unless it also names the input-shape constraint or a temporary shim; current `marathon-plan` is still ROADMAP-ledger-specific, not a generic foreign queue reader ([utils/marathon-plan.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-79403-29214/utils/marathon-plan.sh:305), [plan](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-79403-29214/PROJECT/2-WORKING/GH-48-QUEUE-PLAN-CROSS-REPO-ZONES.md:156)).

- [Should] The precedence contract should use a consistent public env name (`QUEUE_PLAN_ZONES_FILE` is the natural fit), define malformed-file behavior, and define how relative `--zones-config` paths resolve under `--target-root` ([utils/marathon-plan.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-79403-29214/utils/marathon-plan.sh:35), [utils/marathon-plan.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-79403-29214/utils/marathon-plan.sh:120), [plan](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-79403-29214/PROJECT/2-WORKING/GH-48-QUEUE-PLAN-CROSS-REPO-ZONES.md:129)).

- [Nit] If “zero output diff” matters, the design should explicitly preserve today’s raw prefix semantics (`a === k || a.startsWith(k)`) and today’s zone tie-break order in sorting; both are behavior, not just implementation detail ([utils/marathon-plan.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-79403-29214/utils/marathon-plan.sh:359), [utils/marathon-plan.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-79403-29214/utils/marathon-plan.sh:659)).

- [Pass] Rejecting “contract-only mode” is correct; the hardcoded xyz classifier still runs on contract-backed items today, so that mode alone would not fix the rebalance case ([plan](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-79403-29214/PROJECT/2-WORKING/GH-48-QUEUE-PLAN-CROSS-REPO-ZONES.md:75), [utils/marathon-plan.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-79403-29214/utils/marathon-plan.sh:352)).

**Recommendation**

Build with named fixes: keep the zone-rules design, but add `orchestrator_only` fidelity, regex-flag fidelity, and explicit config-resolution/input-shape rules before implementation.
