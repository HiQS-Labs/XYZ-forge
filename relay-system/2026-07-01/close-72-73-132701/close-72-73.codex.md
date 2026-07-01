Reading additional input from stdin...
OpenAI Codex v0.139.0
--------
workdir: /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-97461-32007
model: gpt-5.4
provider: openai
approval: never
sandbox: read-only
reasoning effort: high
reasoning summaries: none
session id: 019f1f5d-1841-7090-8feb-76a3f425b110
--------
user
You are an INDEPENDENT advisor in a one-shot cross-model consult. Another model is answering the SAME question separately and a coordinator will reconcile both answers, so give your own honest, specific read — do not hedge toward a consensus you cannot see. Read any repo files the question references (cite file:line). Respond with: (1) a short direct ANSWER; (2) graded FINDINGS — [Blocker]/[Should]/[Nit]/[Pass] — where applicable; (3) a one-line RECOMMENDATION. You are ADVISORY ONLY: output your analysis as text; do not rely on writing files (you are running in a throwaway copy).

=== CONSULT QUESTION ===
# Consult: are GitHub issues #72 and #73 safe to close?

Both fixes are ALREADY merged to main. You are an independent reviewer. Read the files yourself and
give a clear **close** or **keep-open** recommendation for EACH issue, with any blocking bug.

## #72 — advisory lock to stop concurrent vendor/install from losing a registry row

The lock is implemented (identically) in `relay-automation/xyz-vendor.sh` (~lines 59-150) and
`install.sh` (~lines 90-175): `cleanup()` + `trap cleanup EXIT INT TERM HUP`, `remember_lock`,
`forget_lock`, `advisory_lock_path`, `acquire_advisory_lock`, `release_advisory_lock`,
`run_with_advisory_lock`. Call sites in `install.sh`: line ~285 wraps the registry read-modify-write
(`write_install_registry_row`), line ~237 wraps the projection write (`write_registry_projection`).

Assess specifically, citing file:line:
1. **TOCTOU race (the main question):** `acquire_advisory_lock` does `mkdir "$lockdir"` to win, THEN
   in a separate statement `printf '%s\n' "$$" > "$lockdir/pid"`. A concurrent acquirer that fails the
   `mkdir` reads `holder="$(cat "$lockdir/pid")"`. If it reads BEFORE the winner writes the pid, holder
   is EMPTY, so the `kill -0` alive-check is skipped and it falls into the stale branch and
   `rm -rf "$lockdir"` — destroying the winner's just-created lock. Does this defeat mutual exclusion
   under tight contention? How severe (note the lock is fail-open, so worst case degrades to the
   pre-existing unlocked behavior = losing a row)? Is it a blocker for closing #72, or an acceptable
   known limitation?
2. **Deadlock:** the registry write holds `registry.lock` and then (inside `write_install_registry_row`
   → `publish_registry_projection`) acquires the projection lock. Is the lock ordering consistent /
   deadlock-free?
3. **Fail-open correctness:** on lock-acquire failure does it still run the write (never hard-fail the
   install)? Is the EXIT trap cleanup correct (releases all held locks on crash)?
4. **Critical-section coverage:** is the ENTIRE read-modify-write (read existing rows, append, atomic
   `mv`) inside the lock, or only part of it?
5. Any other correctness bug in the lock you find.

## #73 — doc-only fix

`skills/relay-xyz/SKILL.md` and `relay-automation/README.md` had examples pinning fixed transcript-log
paths (e.g. `CODEX_LOG="${TMPDIR:-/tmp}/codex-turn.log"`), which two concurrent same-machine runs would
clobber. They were changed to per-PID `-$$.log` forms. The shims already defaulted to per-PID; this was
docs catching up. Confirm whether this is trivially closeable or if anything is missed.

## Output
For EACH issue: **CLOSE** or **KEEP-OPEN**, one-line reason, and any blocking bug with a file:line and a
concrete fix.
codex
Verdict will depend on the shell code details, so I’m reading the repo startup docs first and then the two lock implementations plus the doc examples to check the exact race, ordering, and coverage.
exec
/bin/zsh -lc pwd in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-97461-32007
 succeeded in 0ms:
/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-97461-32007

exec
/bin/zsh -lc "rg --files -g 'ROUTER.md' -g 'GUIDING-PRINCIPLES.md' -g 'PROJECT/PDDA.md' -g 'relay-automation/xyz-vendor.sh' -g 'install.sh' -g 'skills/relay-xyz/SKILL.md' -g 'relay-automation/README.md'" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-97461-32007
 succeeded in 0ms:
GUIDING-PRINCIPLES.md
skills/relay-xyz/SKILL.md
skills/relay-xyz/install.sh
ROUTER.md
install.sh
relay-automation/xyz-vendor.sh
skills/relay-to-issue/install.sh
relay-automation/README.md
PROJECT/PDDA.md

codex
I’ve confirmed the relevant files. Next step is line-numbered reads of the startup docs and the exact lock sections so the recommendation is tied to the current code, not the issue summary.
exec
/bin/zsh -lc "nl -ba GUIDING-PRINCIPLES.md | sed -n '1,220p'" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-97461-32007
exec
/bin/zsh -lc "nl -ba skills/relay-xyz/SKILL.md | sed -n '1,220p'" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-97461-32007
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

 succeeded in 0ms:
     1	---
     2	name: relay-xyz
     3	description: >-
     4	  Drive an automated /relay review loop on THIS repo with the shipped
     5	  relay-automation harness (relay-drive.sh + codex-turn.sh / agy-turn.sh /
     6	  poll.sh) rather than improvising the handoff by hand. Use when the operator
     7	  wants to "run an automated relay", "have Codex or agy review this
     8	  end-to-end", "drive a relay to completion headless", "run the relay harness",
     9	  or set up the all-Claude hands-free poll loop — and the working tree is a
    10	  clone of the xyz-3-agents-swarm repo (it ships relay-automation/). /relay
    11	  scaffolds the thread and owns the turn protocol; relay-xyz is the repo-specific
    12	  layer that runs the real scripts. NOT for scaffolding a thread from scratch
    13	  (that is /relay), NOT for repos without relay-automation/.
    14	---
    15	
    16	# relay-xyz — automated relays on the shipped harness
    17	
    18	This repo **already ships** the relay automation. Don't reinvent the CLI handoff turn by turn — call
    19	the scripts under [`relay-automation/`](../../relay-automation/). `/relay` defines the thread format
    20	and turn protocol and scaffolds the dated file; **`relay-xyz` is the thin repo-specific layer that
    21	drives that thread to completion with the shipped supervisor + turn-takers.**
    22	
    23	Use `/relay` to *create* the thread (or reuse one under `relay-system/<date>/`), then `relay-xyz` to
    24	*run* it headless or hands-free.
    25	
    26	## When to use
    27	
    28	- "Run an automated relay" / "drive this relay to completion" / "run the relay harness."
    29	- "Have Codex or agy review `<file>` end-to-end."
    30	- Setting up the all-Claude hands-free `/loop` poll so two Claude windows self-serialize.
    31	- You have a relay thread (or are about to scaffold one with `/relay`) **and** the working tree is a
    32	  clone of this repo.
    33	
    34	**Not** for: scaffolding a brand-new thread from scratch (that's `/relay`), repos that don't ship
    35	`relay-automation/`, or work that needs a human checkpoint between every turn (use plain `/relay`
    36	manual mode).
    37	
    38	## First-time setup on a new clone or machine (make the skill discoverable)
    39	
    40	This repo keeps its skills in top-level `skills/`, which Claude Code does **not** scan. A session
    41	finds `relay-xyz` only if it's symlinked into `~/.claude/skills/`. A fresh clone or second machine has
    42	no such symlink, so the skill is invisible in **every** session there — the "other VS Code sessions
    43	can't find the relay-xyz files" failure. Fix it **once per clone** (idempotent, self-locating, no
    44	hardcoded path):
    45	
    46	```bash
    47	bash skills/relay-xyz/install.sh   # symlinks this clone's skills/relay-xyz into ~/.claude/skills/
    48	```
    49	
    50	It also replaces a stale/dangling symlink and verifies `find-harness.sh` resolves the harness. The
    51	locator below handles *where the harness scripts live*; this step handles *whether Claude Code can
    52	load the skill at all* — a layer the locator can't reach, since it runs only after the skill loads.
    53	
    54	## Preconditions — locate the harness (bundled locator, never hardcode a path)
    55	
    56	`relay-xyz` ships its own device-agnostic locator, [`find-harness.sh`](find-harness.sh), beside this
    57	skill. It resolves the harness repo (the clone that ships `relay-automation/`) **relative to its own
    58	installed location**, following symlinks — so it works from *any* working directory, including a clone
    59	that has only `relay-system/` thread storage (from `/relay`) but **not** the harness scripts. `$HOME`
    60	and the skill's own symlink are the only anchors; **no machine path is ever hardcoded.** That's what
    61	keeps relay-xyz from "complaining the harness isn't in this repo" when you launch it from a clone
    62	without `relay-automation/` + `bin/tick`.
    63	
    64	Run this first. It finds the locator, exports the harness env, `cd`s into the clone that ships the
    65	harness, and prints a one-glance readiness line:
    66	
    67	```bash
    68	# Find the bundled locator. The skill installs at one of these — all anchored on $HOME or
    69	# the CWD, never an absolute machine path:
    70	for L in "${XYZ_HARNESS:+$XYZ_HARNESS/skills/relay-xyz/find-harness.sh}" \
    71	         "$HOME/.claude/skills/relay-xyz/find-harness.sh" \
    72	         "./.claude/skills/relay-xyz/find-harness.sh" \
    73	         "$(git rev-parse --show-toplevel 2>/dev/null)/skills/relay-xyz/find-harness.sh"; do
    74	  [ -n "$L" ] && [ -x "$L" ] && break
    75	done
    76	[ -x "$L" ] || { echo "relay-xyz: locator not found — set XYZ_HARNESS to your xyz-3-agents-swarm clone"; exit 1; }
    77	
    78	eval "$("$L" --env)"   # exports HARNESS, TICK, TICK_REPO_ROOT, RELAY_HAS_{TICK,CODEX,AGY}
    79	cd "$HARNESS"
    80	"$L" --check           # prints: harness path + which Path-A workers (codex/agy/tick) are on PATH
    81	```
    82	
    83	After this, `$HARNESS` is the harness repo root, `$TICK` is the absolute `bin/tick`, and
    84	`TICK_REPO_ROOT` points `tick` at that clone's event log. The relay/turn scripts self-resolve their
    85	own location (`$(dirname "$BASH_SOURCE")/..`), so invoke them with **repo-relative** paths exactly as
    86	the [headless bring-up section](../../relay-automation/README.md#headless-bring-up-codex--agy) shows.
    87	The relay always operates on **the
    88	harness clone** (its `.tick/` log and guarded git root live there), whatever repo you launched from —
    89	so a clone with only `relay-system/` thread files still drives the real harness next door.
    90	
    91	## The two automated paths
    92	
    93	| Path | One session? | Models | Driver |
    94	|---|---|---|---|
    95	| **A. Headless single-session** | yes — Claude drives both roles | Codex / agy as co-equal headless workers | `relay-drive.sh` + a turn-taker shim |
    96	| **B. Hands-free poll** | no — two live Claude windows | all-Claude | `poll.sh` under `/loop` in each window |
    97	
    98	Path A is the marquee flow — what "have Codex or agy review this for me" means. Path B is the all-Claude
    99	self-serializing loop: no human nudge, no second model.
   100	
   101	### Path A — headless single-session (relay-drive.sh + a shim)
   102	
   103	`relay-drive.sh` is the **supervisor** (round cap, no-progress escalation, reads the file's `STATUS:`
   104	as the terminal signal). The **turn-taker** is `--agent-cmd` — a shipped shim (`codex-turn.sh` or
   105	`agy-turn.sh`) that owns the safety boundary: path-allowlist, commit-bypass guard, **no push**.
   106	Whose-turn is a `tick` relay task, handed off with `tick release --to`.
   107	
   108	End-to-end headless review of an artifact (run after Preconditions — `$TICK` and `$HARNESS` set, CWD
   109	is the harness clone). Choose either worker. The examples below pass `ALLOW_PATHS="$ARTIFACT"`, which
   110	fits a **build/fix** turn; for a pure **review** turn set `ALLOW_PATHS=""` (relay file only) so the
   111	reviewer reports instead of editing — see the env table's `ALLOW_PATHS` row (note that fixed log paths break concurrent same-machine runs; prefer the shims' per-PID default or use per-PID `$$` variables):
   112	
   113	| Worker | Availability check | Handoff target | Env prefix | Shim | Log |
   114	|---|---|---|---|---|---|
   115	| Codex | `"$RELAY_HAS_CODEX" = 1` | `codex` | `CODEX_AGENT=codex ALLOW_PATHS="$ARTIFACT" CODEX_LOG="${TMPDIR:-/tmp}/codex-turn-$$.log"` | `relay-automation/codex-turn.sh` | `${TMPDIR:-/tmp}/codex-turn-$$.log` |
   116	| agy | `"$RELAY_HAS_AGY" = 1` | `agy` | `AGY_AGENT=agy ALLOW_PATHS="$ARTIFACT" AGY_LOG="${TMPDIR:-/tmp}/agy-turn-$$.log"` | `relay-automation/agy-turn.sh` | `${TMPDIR:-/tmp}/agy-turn-$$.log` |
   117	
   118	Codex example:
   119	
   120	```bash
   121	# 0. The reviewer you want must be on PATH (set by the locator).
   122	[ "$RELAY_HAS_CODEX" = 1 ] || { echo "codex not on PATH — use agy or Path B"; exit 1; }
   123	
   124	# 1. Have a relay thread with an embedded "▶ TAKE YOUR TURN" block.
   125	#    Reuse one under relay-system/<date>/, or scaffold a fresh thread with /relay first.
   126	RELAY=relay-system/<date>/<slug>.md
   127	ARTIFACT=<repo-relative-path-the-turn-reviews>     # e.g. skills/relay-xyz/SKILL.md
   128	TASK="RELAY-$(basename "$RELAY" .md)"              # use a per-relay id, not literal RELAY-TURN
   129	
   130	# 2. Seed the relay task and hand the first turn to the Codex agent.
   131	"$TICK" log     task.created "$TASK" --agent claude-a
   132	"$TICK" claim   "$TASK" --agent claude-a --paths "$ARTIFACT"
   133	"$TICK" release "$TASK" --agent claude-a --to codex
   134	
   135	# 3. Drive it. The shim dispatches ONLY when the token's actor == CODEX_AGENT.
   136	CODEX_AGENT=codex ALLOW_PATHS="$ARTIFACT" CODEX_LOG="${TMPDIR:-/tmp}/codex-turn-$$.log" \
   137	relay-automation/relay-drive.sh \
   138	  --relay-file "$RELAY" \
   139	  --relay-task "$TASK" \
   140	  --agent-cmd  relay-automation/codex-turn.sh \
   141	  --round-cap  4
   142	```
   143	
   144	agy example:
   145	
   146	```bash
   147	[ "$RELAY_HAS_AGY" = 1 ] || { echo "agy not on PATH — use codex or Path B"; exit 1; }
   148	
   149	RELAY=relay-system/<date>/<slug>.md
   150	ARTIFACT=<repo-relative-path-the-turn-reviews>
   151	TASK="RELAY-$(basename "$RELAY" .md)"
   152	
   153	"$TICK" log     task.created "$TASK" --agent claude-a
   154	"$TICK" claim   "$TASK" --agent claude-a --paths "$ARTIFACT"
   155	"$TICK" release "$TASK" --agent claude-a --to agy
   156	
   157	AGY_AGENT=agy ALLOW_PATHS="$ARTIFACT" AGY_LOG="${TMPDIR:-/tmp}/agy-turn-$$.log" \
   158	relay-automation/relay-drive.sh \
   159	  --relay-file "$RELAY" \
   160	  --relay-task "$TASK" \
   161	  --agent-cmd  relay-automation/agy-turn.sh \
   162	  --round-cap  4
   163	```
   164	
   165	`$TICK` is absolute, so either worker path still works if CWD drifts.
   166	
   167	**Important — run the shim OUTSIDE the Bash sandbox.** When *you* (Claude Code) drive this, the
   168	`codex` / `agy` subprocess needs the OS keychain + outbound network to authenticate. Claude Code's
   169	Bash sandbox blocks both: `codex` errors (looks like a keychain/login fault, but it's the sandbox),
   170	and `agy -p` **fails silently — exit 0, empty output** (the shim catches this and exits 5, but only
   171	un-sandboxed). Run these Bash calls with `dangerouslyDisableSandbox: true`. (Memory:
   172	`codex-cli-needs-sandbox-disabled`, `agy-antigravity-cli`.)
   173	
   174	#### Inspecting token state, and a one-shot review
   175	
   176	- **Inspect whose-turn mid-drive:** `"$TICK" info <task>` prints the token's `status` / `claimer` /
   177	  `handoff-to` (this is what the driver reads internally). The verb is **`info`**, not `status` —
   178	  `tick status` is not a verb and errors with `unknown verb: status`.
   179	- **Single deliberate review turn:** pass `--review-once` to `relay-drive.sh` to drive exactly ONE
   180	  turn and classify the outcome by exit code, so a correct "changes requested" review is not mistaken
   181	  for a stall:
   182	
   183	  | Exit | Meaning |
   184	  |---|---|
   185	  | `0` | reviewer Approved/Closed |
   186	  | `5` | reviewer completed a turn and handed back **without** approving ("changes requested") — a *successful* single review, not a stall |
   187	  | `3` | genuine stall — the reviewer did nothing (token + STATUS unchanged) |
   188	  | `4` | escalated by design (`STATUS: Escalated`), round cap, or a close mismatch |
   189	
   190	  Without `--review-once` a non-approval handback advances the multi-round loop instead (the producer
   191	  takes the next turn); use `--review-once` when you want exactly one review and a clean exit code.
   192	
   193	- **Review an external / cross-repo artifact (a PR or diff from another repo):** pass
   194	  `--artifact-file <path>` to `relay-drive.sh` to seed it READ-ONLY into the isolated worktree at
   195	  `.relay-artifacts/<basename>` — the reviewer reads it there without it being committed into the
   196	  target repo (a reviewer edit fails the turn). To scaffold the thread for such a review, use
   197	  `relay-automation/new-relay.sh --title T --reviewer <agent> --artifact-file <path>` (add `--embed`
   198	  to inline the artifact in a fence-collision-safe block instead of referencing the seed path). The
   199	  scaffolder only writes a thread; you still drive it with `relay-drive.sh` per the paths above.
   200	
   201	- **Drive a full relay/build that lands in a DIFFERENT repo (`--target-root`):** the *normal* case —
   202	  the harness lives in `xyz-3-agents-swarm`, the code you want built or reviewed-and-committed lives in
   203	  your own repo. Pass `--target-root <repo>` to `relay-drive.sh` (or `marathon-drive.sh`): the relay
   204	  thread + `tick` token stay in the harness clone, while the worktree base, `ALLOW_PATHS` resolution,
   205	  and the file-scoped commit all route to `<repo>` (the harness clone is never touched). `find-harness.sh`
   206	  (Preconditions) solves discovery of *the harness*; `--target-root` is the inverse — pointing the
   207	  harness **at** your repo. **A same-repo lane must OMIT `--target-root`** — passing it for the harness's
   208	  own repo trips a relay-file off-lane false-positive (exit 6; see [#51](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/51)).
   209	
   210	- **One-shot cross-repo review without a relay loop (`CONSULT_ROOT`):** to apply a lens to a file in a
   211	  foreign repo with Codex/agy headless — no Producer↔Reviewer loop, advisory only — reach for
   212	  `consult.sh` with `CONSULT_ROOT` set to that repo. Advisors run in a throwaway worktree of
   213	  `CONSULT_ROOT`, so they read it but can never mutate it:
   214	  ```bash
   215	  CONSULT_ROOT=/path/to/your/repo \
   216	  relay-automation/consult.sh --models codex \
   217	    --prompt-file /abs/path/Q.md --out "$TMPDIR/consult"
   218	  ```
   219	  **`$TMPDIR` gotcha:** when a prompt/artifact is *authored* in a sandboxed step and *consumed*
   220	  un-sandboxed (or vice-versa), `$TMPDIR` resolves to a different dir and the path 404s

exec
/bin/zsh -lc "nl -ba install.sh | sed -n '1,420p'" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-97461-32007
exec
/bin/zsh -lc "nl -ba ROUTER.md | sed -n '1,220p'" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-97461-32007
 succeeded in 0ms:
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
    73	- If the task is about a proposed roadmap-steward agent, start here, then read `PROJECT/PDDA.md` and its `Proposed roadmap steward extension` section.
    74	- Issue-first SOP: any change beyond a 2–3 line fix (and every project plan) opens a GitHub issue *first*, then gets a pointer doc named after the issue at `PROJECT/1-INBOX/GH-<number>-VERY-SHORT-DESC.md` — e.g. `GH-1234-SHOWME-COMMAND.md` — and that capture is parked in the `ROADMAP.md` queue immediately (format + lifecycle owned by `PROJECT/PDDA.md` → "GitHub issue intake"), following the normal `1-INBOX` → `2-WORKING` flow. Genuinely trivial edits (≤2–3 line fixes, typos, path repoints, doc-only one-liners) are exempt and commit directly.

 succeeded in 0ms:
     1	#!/usr/bin/env bash
     2	set -euo pipefail
     3	
     4	# XYZ / tick installer — materialize the `tick` runtime (bin/tick + src/*.js) into a target DIR, then
     5	# "call home": record WHERE this copy was installed and on which source version/commit in a per-user,
     6	# machine-local registry. Run it from a clone of this repo:
     7	#
     8	#   ./install.sh [options] [target-dir]     # target-dir default: ./xyz-tick
     9	#
    10	# The registry is what lets a future `tick` version be pushed to the copies that are behind. It lives
    11	# in $HOME (never in the repo, so it can't leak into the eventually-public tree) and is never committed.
    12	#
    13	# This mirrors PDDA's install->call-home pattern (pdda/install.sh). The registry-writing block is kept
    14	# in lockstep with the compact inline version embedded in the /xyz SKILL self-extract block (§4);
    15	# change both together.
    16	
    17	SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    18	
    19	REGISTER=1
    20	TARGET=""
    21	COORD_REPO="${TICK_REPO_ROOT:-}"
    22	
    23	# Per-user, per-device install registry — one row per install dir, latest wins. Machine-local; never
    24	# committed. Override the path with XYZ_REGISTRY; skip writing it with --no-register.
    25	XYZ_REGISTRY="${XYZ_REGISTRY:-${XDG_CONFIG_HOME:-$HOME/.config}/xyz/registry.tsv}"
    26	
    27	# Optional multi-device rollup: if git-pulse (a GitHub-backed activity-sync tool) is present, drop a
    28	# PATH-NORMALIZED projection of the registry (repo/dir name + date + version; never absolute paths)
    29	# into git-pulse's repo under xyz/, and git-pulse's own sync carries it across devices. Best-effort and
    30	# fail-open: absent git-pulse -> silently skipped. Set XYZ_GITPULSE_DIR to override or disable.
    31	XYZ_GITPULSE_DIR="${XYZ_GITPULSE_DIR:-}"
    32	HELD_LOCKS=""
    33	
    34	usage() {
    35	  cat <<'USAGE'
    36	XYZ / tick installer — materialize the tick runtime into a dir and register the install.
    37	
    38	Usage:
    39	  ./install.sh [options] [target-dir]
    40	
    41	Arguments:
    42	  target-dir             Where to materialize the runtime (default: ./xyz-tick). Creates
    43	                         <target-dir>/bin/tick and <target-dir>/src/*.js.
    44	
    45	Options:
    46	  --repo <path>          Record the coordinated repo (the one holding .tick/) in the registry.
    47	                         Defaults to $TICK_REPO_ROOT if set, else "-".
    48	  --no-register          Skip recording this install in the per-user registry
    49	                         (default: $XDG_CONFIG_HOME/xyz/registry.tsv or ~/.config/xyz/registry.tsv;
    50	                         override with XYZ_REGISTRY). Also skips the git-pulse projection.
    51	  -h, --help             This message.
    52	
    53	After install, use it with:
    54	  export PATH="<target-dir>/bin:$PATH"
    55	  export TICK_REPO_ROOT="<repo to coordinate>"   # where .tick/ lives
    56	  tick --help
    57	USAGE
    58	}
    59	
    60	while [ "$#" -gt 0 ]; do
    61	  case "$1" in
    62	    --repo) COORD_REPO="${2:-}"; shift 2 ;;
    63	    --no-register) REGISTER=0; shift ;;
    64	    -h|--help) usage; exit 0 ;;
    65	    -*) printf 'install.sh: unknown option %q\n\n' "$1" >&2; usage >&2; exit 2 ;;
    66	    *) if [ -z "$TARGET" ]; then TARGET="$1"; shift; else printf 'install.sh: unexpected argument %q\n' "$1" >&2; exit 2; fi ;;
    67	  esac
    68	done
    69	
    70	TARGET="${TARGET:-xyz-tick}"
    71	
    72	# Source sanity: we ship the repo's canonical modular runtime (bin/tick requires ../src/*).
    73	[ -f "$SOURCE_DIR/bin/tick" ] || { printf 'install.sh: no bin/tick under %q — run this from a clone of the xyz repo.\n' "$SOURCE_DIR" >&2; exit 1; }
    74	[ -d "$SOURCE_DIR/src" ]      || { printf 'install.sh: no src/ under %q — run this from a clone of the xyz repo.\n' "$SOURCE_DIR" >&2; exit 1; }
    75	
    76	# Resolve target to an absolute path (create it first so `cd` succeeds).
    77	mkdir -p "$TARGET/bin" "$TARGET/src"
    78	TARGET="$(cd "$TARGET" && pwd)"
    79	
    80	if [ "$TARGET" = "$SOURCE_DIR" ]; then
    81	  printf 'install.sh: refusing to install into the source repo root (would clobber bin/tick). Pick a subdir.\n' >&2
    82	  exit 1
    83	fi
    84	
    85	say() { printf '%s\n' "$*"; }
    86	
    87	cleanup() {
    88	  local entry
    89	  while IFS= read -r entry; do
    90	    [ -n "$entry" ] || continue
    91	    rm -rf "$entry" 2>/dev/null || true
    92	  done <<EOF
    93	$HELD_LOCKS
    94	EOF
    95	}
    96	trap cleanup EXIT INT TERM HUP
    97	
    98	remember_lock() {
    99	  HELD_LOCKS="${HELD_LOCKS}${HELD_LOCKS:+
   100	}$1"
   101	}
   102	
   103	forget_lock() {
   104	  local needle="$1" kept="" entry
   105	  while IFS= read -r entry; do
   106	    [ -n "$entry" ] || continue
   107	    [ "$entry" = "$needle" ] && continue
   108	    kept="${kept}${kept:+
   109	}$entry"
   110	  done <<EOF
   111	$HELD_LOCKS
   112	EOF
   113	  HELD_LOCKS="$kept"
   114	}
   115	
   116	advisory_lock_path() {
   117	  local target="$1" dir stem
   118	  dir="$(dirname "$target")"
   119	  stem="$(basename "$target")"
   120	  case "$stem" in
   121	    *.*) stem="${stem%.*}" ;;
   122	  esac
   123	  printf '%s/%s.lock' "$dir" "$stem"
   124	}
   125	
   126	acquire_advisory_lock() {
   127	  local target="$1" label="$2" lockdir holder attempt
   128	  lockdir="$(advisory_lock_path "$target")"
   129	  attempt=0
   130	  while :; do
   131	    if mkdir "$lockdir" 2>/dev/null; then
   132	      printf '%s\n' "$$" > "$lockdir/pid" 2>/dev/null || true
   133	      remember_lock "$lockdir"
   134	      ADVISORY_LOCK_DIR="$lockdir"
   135	      return 0
   136	    fi
   137	    attempt=$((attempt + 1))
   138	    holder="$(cat "$lockdir/pid" 2>/dev/null || true)"
   139	    if [ -n "$holder" ] && kill -0 "$holder" 2>/dev/null; then
   140	      if [ "$attempt" -ge 5 ]; then
   141	        say "  ($label lock busy at $lockdir, pid $holder — proceeding without lock)"
   142	        ADVISORY_LOCK_DIR=""
   143	        return 1
   144	      fi
   145	      sleep 1
   146	      continue
   147	    fi
   148	    if [ "$attempt" -ge 5 ]; then
   149	      say "  ($label could not acquire $lockdir after stale-lock retries — proceeding without lock)"
   150	      ADVISORY_LOCK_DIR=""
   151	      return 1
   152	    fi
   153	    say "  ($label reclaiming stale lock at $lockdir, pid ${holder:-none})"
   154	    rm -rf "$lockdir" 2>/dev/null || true
   155	  done
   156	}
   157	
   158	release_advisory_lock() {
   159	  local lockdir="${1:-}"
   160	  [ -n "$lockdir" ] || return 0
   161	  rm -rf "$lockdir" 2>/dev/null || true
   162	  forget_lock "$lockdir"
   163	}
   164	
   165	run_with_advisory_lock() {
   166	  local target="$1" label="$2" lockdir="" rc
   167	  shift 2
   168	  if acquire_advisory_lock "$target" "$label"; then
   169	    lockdir="$ADVISORY_LOCK_DIR"
   170	  fi
   171	  "$@"
   172	  rc=$?
   173	  release_advisory_lock "$lockdir"
   174	  return "$rc"
   175	}
   176	
   177	say "Installing tick runtime into: $TARGET"
   178	say ""
   179	say "Runtime:"
   180	cp "$SOURCE_DIR/bin/tick" "$TARGET/bin/tick"
   181	chmod +x "$TARGET/bin/tick"
   182	say "  runtime   bin/tick"
   183	# Ship the whole module set — bin/tick require()s several src/* modules that transitively pull in the
   184	# rest; copying all of src/*.js keeps the install self-consistent regardless of the require graph.
   185	for f in "$SOURCE_DIR"/src/*.js; do
   186	  cp "$f" "$TARGET/src/$(basename "$f")"
   187	  say "  runtime   src/$(basename "$f")"
   188	done
   189	
   190	# --- call home -------------------------------------------------------------------------------------
   191	
   192	# Best-effort tick version: the SCHEMA_VERSION anchor lives in src/events.js. Fallback: unknown.
   193	tick_version() {
   194	  local v
   195	  v="$(sed -n "s/.*SCHEMA_VERSION[[:space:]]*=[[:space:]]*['\"]\([^'\"]*\)['\"].*/\1/p" "$SOURCE_DIR/src/events.js" 2>/dev/null | head -1)"
   196	  printf '%s' "${v:-unknown}"
   197	}
   198	
   199	write_registry_projection() {
   200	  local out="$1" tmp
   201	  tmp="$out.tmp.$$"
   202	  if {
   203	       printf '# XYZ install status (normalized to install-dir name; absolute paths intentionally omitted).\n'
   204	       printf '# Maintainer on another machine: locate the install by dir name, e.g.\n'
   205	       printf '#   find ~ -type d -name "<dir>" -exec test -f "{}/bin/tick" \\; -print 2>/dev/null\n'
   206	       printf '# install_dir\tlast_install_utc\ttick_version\tsource_commit\tcoordinated_repo\n'
   207	       awk -F'\t' 'BEGIN{OFS="\t"} /^#/{next} NF==0{next} {n=split($1,a,"/"); $1=a[n]; print}' "$XYZ_REGISTRY"
   208	     } > "$tmp" 2>/dev/null && mv "$tmp" "$out"; then
   209	    say "  publish   $(basename "$out") (normalized; git-pulse carries it)"
   210	  else
   211	    rm -f "$tmp" 2>/dev/null
   212	    say "  (git-pulse publish failed — projection unchanged)"
   213	  fi
   214	  return 0
   215	}
   216	
   217	# Publish a path-normalized projection of the registry into git-pulse's sync repo when present, so XYZ
   218	# install status rolls up across devices with NO new sync infrastructure. Normalized = col 1 absolute
   219	# path -> bare dir name; the projection never contains a filesystem path. Best-effort / fail-open; the
   220	# local registry stays the source of truth (it keeps absolute paths because a push tool cd's into them).
   221	publish_registry_projection() {
   222	  local gp="$XYZ_GITPULSE_DIR" dev cfg out cand
   223	  cfg="${XDG_CONFIG_HOME:-$HOME/.config}/git-pulse/config.sh"
   224	  if [ -z "$gp" ]; then
   225	    gp="$( ( . "$cfg" 2>/dev/null; printf '%s' "${sync_repo_dir:-}" ) )"
   226	    if [ -z "$gp" ] || [ ! -d "$gp/.git" ]; then
   227	      for cand in "${XDG_CONFIG_HOME:-$HOME/.config}/git-pulse/repo" "$HOME/git-pulse-sync"; do
   228	        [ -d "$cand/.git" ] && { gp="$cand"; break; }
   229	      done
   230	    fi
   231	  fi
   232	  [ -d "$gp/.git" ] || return 0
   233	  dev="$( ( . "$cfg" 2>/dev/null; printf '%s' "${device_id:-}" ) )"
   234	  [ -n "$dev" ] || dev="$(hostname -s 2>/dev/null || printf 'unknown-device')"
   235	  mkdir -p "$gp/xyz" 2>/dev/null || { say "  (git-pulse xyz/ not writable — publish skipped)"; return 0; }
   236	  out="$gp/xyz/registry-$dev.tsv"
   237	  run_with_advisory_lock "$out" "git-pulse projection" write_registry_projection "$out"
   238	  return 0
   239	}
   240	
   241	write_install_registry_row() {
   242	  local reg="$1" target="$2" row="$3" ver="$4" src_commit="$5" coord="$6" tmp
   243	  tmp="$reg.tmp.$$"
   244	  if awk -F'\t' -v t="$target" '$1 != t' "$reg" > "$tmp" 2>/dev/null; then
   245	    if printf '%s\n' "$row" >> "$tmp" && mv "$tmp" "$reg"; then
   246	      say "  register  $target -> $reg (tick $ver, $src_commit, repo=$coord)"
   247	      publish_registry_projection   # best-effort multi-device rollup; never fails the install
   248	    else
   249	      rm -f "$tmp" 2>/dev/null
   250	      say "  (registry write failed — skipped)"
   251	    fi
   252	  else
   253	    rm -f "$tmp"
   254	    say "  (registry write failed — skipped)"
   255	  fi
   256	  return 0
   257	}
   258	
   259	# Record this install (one row per install dir, latest wins). Machine-local; never committed.
   260	# Best-effort: a failure here never fails the install.
   261	register_install() {
   262	  [ "$REGISTER" -eq 1 ] || return 0
   263	  local reg="$XYZ_REGISTRY" dir
   264	  dir="$(dirname "$reg")"
   265	  mkdir -p "$dir" 2>/dev/null || { say "  (registry dir $dir not writable — skipped)"; return 0; }
   266	
   267	  local ts ver src_commit coord row
   268	  ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
   269	  ver="$(tick_version)"
   270	  src_commit="$(git -C "$SOURCE_DIR" rev-parse --short HEAD 2>/dev/null || printf 'unknown')"
   271	  coord="${COORD_REPO:-}"
   272	  # Guard the literal "-" sentinel: cd "-" would jump to $OLDPWD and corrupt the row (agy QA r1).
   273	  [ -n "$coord" ] && [ "$coord" != "-" ] && coord="$(cd "$coord" 2>/dev/null && pwd || printf '%s' "$COORD_REPO")"
   274	  coord="${coord:--}"
   275	
   276	  if [ ! -f "$reg" ]; then
   277	    {
   278	      printf '# XYZ install registry — per-user, per-device. Machine-local; do NOT commit.\n'
   279	      printf '# install_dir\tlast_install_utc\ttick_version\tsource_commit\tcoordinated_repo\n'
   280	    } > "$reg" 2>/dev/null || { say "  (registry not writable — skipped)"; return 0; }
   281	  fi
   282	
   283	  # One row per install dir: drop any prior row for this exact path (tab col 1), then append fresh.
   284	  row="$(printf '%s\t%s\t%s\t%s\t%s' "$TARGET" "$ts" "$ver" "$src_commit" "$coord")"
   285	  run_with_advisory_lock "$reg" "registry" write_install_registry_row "$reg" "$TARGET" "$row" "$ver" "$src_commit" "$coord"
   286	}
   287	
   288	say ""
   289	say "Registry:"
   290	register_install
   291	
   292	say ""
   293	say "tick runtime installed in $TARGET/"
   294	say "Use it with:"
   295	say "  export PATH=\"$TARGET/bin:\$PATH\""
   296	say "  export TICK_REPO_ROOT=\"${COORD_REPO:-<repo to coordinate>}\""
   297	say "  tick --help"

exec
/bin/zsh -lc "nl -ba relay-automation/xyz-vendor.sh | sed -n '1,260p'" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-97461-32007
 succeeded in 0ms:
     1	#!/usr/bin/env bash
     2	set -euo pipefail
     3	
     4	usage() {
     5	  cat <<'USAGE'
     6	Usage:
     7	  xyz-vendor.sh <target-repo> [--no-register]
     8	  xyz-vendor.sh -h | --help
     9	
    10	Materialize a vendored xyz harness snapshot into <target-repo>/.xyz/.
    11	USAGE
    12	}
    13	
    14	note() { printf '%s\n' "$*"; }
    15	die() { printf 'xyz-vendor.sh: %s\n' "$*" >&2; exit 1; }
    16	
    17	HELD_LOCKS=""
    18	
    19	# Resolve this script's real path without readlink -f (bash 3.2 / macOS safe).
    20	_src="${BASH_SOURCE[0]}"
    21	while [ -h "$_src" ]; do
    22	  _dir="$(cd -P "$(dirname "$_src")" >/dev/null 2>&1 && pwd)"
    23	  _src="$(readlink "$_src")"
    24	  case "$_src" in /*) ;; *) _src="$_dir/$_src" ;; esac
    25	done
    26	SELF_DIR="$(cd -P "$(dirname "$_src")" >/dev/null 2>&1 && pwd)"
    27	HARNESS_ROOT="$(cd "$SELF_DIR/.." >/dev/null 2>&1 && pwd)"
    28	
    29	REGISTER=1
    30	TARGET_REPO=""
    31	XYZ_REGISTRY="${XYZ_REGISTRY:-${XDG_CONFIG_HOME:-$HOME/.config}/xyz/registry.tsv}"
    32	
    33	while [ "$#" -gt 0 ]; do
    34	  case "$1" in
    35	    --no-register) REGISTER=0; shift ;;
    36	    -h|--help) usage; exit 0 ;;
    37	    -*) printf 'xyz-vendor.sh: unknown option %q\n\n' "$1" >&2; usage >&2; exit 2 ;;
    38	    *)
    39	      if [ -z "$TARGET_REPO" ]; then
    40	        TARGET_REPO="$1"
    41	        shift
    42	      else
    43	        printf 'xyz-vendor.sh: unexpected argument %q\n' "$1" >&2
    44	        exit 2
    45	      fi
    46	      ;;
    47	  esac
    48	done
    49	
    50	[ -n "$TARGET_REPO" ] || { usage >&2; exit 2; }
    51	[ -d "$TARGET_REPO" ] || die "target repo not found: $TARGET_REPO"
    52	[ -f "$HARNESS_ROOT/bin/tick" ] || die "missing bin/tick under $HARNESS_ROOT"
    53	[ -d "$HARNESS_ROOT/src" ] || die "missing src/ under $HARNESS_ROOT"
    54	
    55	TARGET_REPO="$(cd "$TARGET_REPO" >/dev/null 2>&1 && pwd)"
    56	VENDOR_DIR="$TARGET_REPO/.xyz"
    57	STAGE_DIR="$TARGET_REPO/.xyz.tmp.$$"
    58	
    59	cleanup() {
    60	  local entry
    61	  while IFS= read -r entry; do
    62	    [ -n "$entry" ] || continue
    63	    rm -rf "$entry" 2>/dev/null || true
    64	  done <<EOF
    65	$HELD_LOCKS
    66	EOF
    67	  if [ -n "${STAGE_DIR:-}" ] && [ -e "${STAGE_DIR:-}" ]; then
    68	    rm -rf "$STAGE_DIR"
    69	  fi
    70	}
    71	trap cleanup EXIT INT TERM HUP
    72	
    73	remember_lock() {
    74	  HELD_LOCKS="${HELD_LOCKS}${HELD_LOCKS:+
    75	}$1"
    76	}
    77	
    78	forget_lock() {
    79	  local needle="$1" kept="" entry
    80	  while IFS= read -r entry; do
    81	    [ -n "$entry" ] || continue
    82	    [ "$entry" = "$needle" ] && continue
    83	    kept="${kept}${kept:+
    84	}$entry"
    85	  done <<EOF
    86	$HELD_LOCKS
    87	EOF
    88	  HELD_LOCKS="$kept"
    89	}
    90	
    91	advisory_lock_path() {
    92	  local target="$1" dir stem
    93	  dir="$(dirname "$target")"
    94	  stem="$(basename "$target")"
    95	  case "$stem" in
    96	    *.*) stem="${stem%.*}" ;;
    97	  esac
    98	  printf '%s/%s.lock' "$dir" "$stem"
    99	}
   100	
   101	acquire_advisory_lock() {
   102	  local target="$1" label="$2" lockdir holder attempt
   103	  lockdir="$(advisory_lock_path "$target")"
   104	  attempt=0
   105	  while :; do
   106	    if mkdir "$lockdir" 2>/dev/null; then
   107	      printf '%s\n' "$$" > "$lockdir/pid" 2>/dev/null || true
   108	      remember_lock "$lockdir"
   109	      ADVISORY_LOCK_DIR="$lockdir"
   110	      return 0
   111	    fi
   112	    attempt=$((attempt + 1))
   113	    holder="$(cat "$lockdir/pid" 2>/dev/null || true)"
   114	    if [ -n "$holder" ] && kill -0 "$holder" 2>/dev/null; then
   115	      if [ "$attempt" -ge 5 ]; then
   116	        note "$label: lock busy ($lockdir, pid $holder); proceeding without lock"
   117	        ADVISORY_LOCK_DIR=""
   118	        return 1
   119	      fi
   120	      sleep 1
   121	      continue
   122	    fi
   123	    if [ "$attempt" -ge 5 ]; then
   124	      note "$label: could not acquire $lockdir after stale-lock retries; proceeding without lock"
   125	      ADVISORY_LOCK_DIR=""
   126	      return 1
   127	    fi
   128	    note "$label: reclaiming stale lock ($lockdir, pid ${holder:-none})"
   129	    rm -rf "$lockdir" 2>/dev/null || true
   130	  done
   131	}
   132	
   133	release_advisory_lock() {
   134	  local lockdir="${1:-}"
   135	  [ -n "$lockdir" ] || return 0
   136	  rm -rf "$lockdir" 2>/dev/null || true
   137	  forget_lock "$lockdir"
   138	}
   139	
   140	run_with_advisory_lock() {
   141	  local target="$1" label="$2" lockdir="" rc
   142	  shift 2
   143	  if acquire_advisory_lock "$target" "$label"; then
   144	    lockdir="$ADVISORY_LOCK_DIR"
   145	  fi
   146	  "$@"
   147	  rc=$?
   148	  release_advisory_lock "$lockdir"
   149	  return "$rc"
   150	}
   151	
   152	tick_version() {
   153	  local v
   154	  v="$(sed -n "s/.*SCHEMA_VERSION[[:space:]]*=[[:space:]]*['\"]\([^'\"]*\)['\"].*/\1/p" "$HARNESS_ROOT/src/events.js" 2>/dev/null | head -1)"
   155	  printf '%s' "${v:-unknown}"
   156	}
   157	
   158	manifest_from_make_pkg() {
   159	  awk '
   160	    $1 == "tar" && $2 == "czf" && $3 ~ /relay-pkg\.tar\.gz$/ { in_block = 1; next }
   161	    in_block {
   162	      line = $0
   163	      sub(/[[:space:]]*#.*/, "", line)
   164	      gsub(/[[:space:]]*\\[[:space:]]*$/, "", line)
   165	      gsub(/^[[:space:]]+|[[:space:]]+$/, "", line)
   166	      if (line == "") next
   167	      if (line ~ /^(relay-automation|test)\//) {
   168	        print line
   169	        next
   170	      }
   171	      exit
   172	    }
   173	  ' "$HARNESS_ROOT/skills/relay-automation/make-pkg.sh"
   174	}
   175	
   176	write_registry_row() {
   177	  local reg="$1" target="$2" row="$3" tmp
   178	  tmp="$reg.tmp.$$"
   179	  if awk -F '\t' -v t="$target" 'BEGIN{OFS="\t"} /^#/{print; next} NF==0{next} $1 != t {print}' "$reg" > "$tmp" 2>/dev/null; then
   180	    if printf '%s\n' "$row" >> "$tmp" && mv "$tmp" "$reg"; then
   181	      note "registry: updated $reg"
   182	    else
   183	      rm -f "$tmp" 2>/dev/null
   184	      note "registry: write failed; skipped"
   185	    fi
   186	  else
   187	    rm -f "$tmp" 2>/dev/null
   188	    note "registry: write failed; skipped"
   189	  fi
   190	  return 0
   191	}
   192	
   193	ensure_gitignore() {
   194	  local gitignore="$TARGET_REPO/.gitignore"
   195	  if [ ! -f "$gitignore" ]; then
   196	    : > "$gitignore"
   197	  fi
   198	  if ! grep -Fqx '.xyz/' "$gitignore" 2>/dev/null; then
   199	    printf '%s\n' '.xyz/' >> "$gitignore"
   200	  fi
   201	}
   202	
   203	register_vendor() {
   204	  [ "$REGISTER" -eq 1 ] || return 0
   205	
   206	  local reg dir ts ver src_commit row
   207	  reg="$XYZ_REGISTRY"
   208	  dir="$(dirname "$reg")"
   209	  mkdir -p "$dir" 2>/dev/null || { note "registry: $dir not writable; skipped"; return 0; }
   210	
   211	  ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
   212	  ver="$(tick_version)"
   213	  src_commit="$(git -C "$HARNESS_ROOT" rev-parse HEAD 2>/dev/null || printf 'unknown')"
   214	
   215	  if [ ! -f "$reg" ]; then
   216	    {
   217	      printf '# XYZ install registry — per-user, per-device. Machine-local; do NOT commit.\n'
   218	      printf '# install_dir\tlast_install_utc\ttick_version\tsource_commit\tcoordinated_repo\n'
   219	    } > "$reg" 2>/dev/null || { note "registry: $reg not writable; skipped"; return 0; }
   220	  fi
   221	
   222	  # Schema stays aligned with install.sh; vendored copies are identified by install_dir=.xyz and
   223	  # coordinated_repo=<target repo>.
   224	  row="$(printf '%s\t%s\t%s\t%s\t%s' "$VENDOR_DIR" "$ts" "$ver" "$src_commit" "$TARGET_REPO")"
   225	  run_with_advisory_lock "$reg" "registry" write_registry_row "$reg" "$VENDOR_DIR" "$row"
   226	  return 0
   227	}
   228	
   229	materialize_vendor() {
   230	  local rel src_file copied
   231	
   232	  rm -rf "$STAGE_DIR"
   233	  mkdir -p "$STAGE_DIR"
   234	  copied=0
   235	
   236	  while IFS= read -r rel; do
   237	    [ -n "$rel" ] || continue
   238	    src_file="$HARNESS_ROOT/$rel"
   239	    [ -f "$src_file" ] || die "manifest entry missing from harness: $rel"
   240	    mkdir -p "$STAGE_DIR/$(dirname "$rel")"
   241	    cp -p "$src_file" "$STAGE_DIR/$rel"
   242	    copied=$((copied + 1))
   243	  done <<EOF
   244	$(manifest_from_make_pkg)
   245	EOF
   246	
   247	  [ "$copied" -gt 0 ] || die "failed to derive relay manifest from skills/relay-automation/make-pkg.sh"
   248	
   249	  # GH-49b: the marathon runtime is NOT in the relay-pkg manifest — vendor it explicitly so the copy
   250	  # can run marathons (marathon-drive), not just relays. marathon-agent dispatches to the turn shims
   251	  # (claude/codex/agy), so claude-turn.sh comes along too even though it's absent from the relay set.
   252	  for mrel in relay-automation/marathon-drive.sh relay-automation/marathon.sh \
   253	              relay-automation/marathon-agent.sh relay-automation/claude-turn.sh; do
   254	    [ -f "$HARNESS_ROOT/$mrel" ] || die "marathon runtime missing from harness: $mrel"
   255	    mkdir -p "$STAGE_DIR/$(dirname "$mrel")"
   256	    cp -p "$HARNESS_ROOT/$mrel" "$STAGE_DIR/$mrel"
   257	  done
   258	
   259	  mkdir -p "$STAGE_DIR/bin" "$STAGE_DIR/src"
   260	  cp -p "$HARNESS_ROOT/bin/tick" "$STAGE_DIR/bin/tick"

exec
/bin/zsh -lc "nl -ba relay-automation/README.md | sed -n '1,240p'" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-97461-32007
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
    27	| `gemini-turn.sh` | **DEPRECATED 2026-06-19** — Gemini CLI retired; use `agy-turn.sh` instead. Kept as historical reference. |
    28	| `agy-turn.sh` | **Option-A** headless turn-taker for the **agy** (Antigravity CLI) agent (`agy -p`); thin dispatch wrapper over `relay-turn-lib.sh`. Permanent replacement for `gemini-turn.sh`; live-validated 2026-06-18. |
    29	| `consult.sh` | Parallel read-only consult: asks the same question to Codex and agy, captures both transcripts, and leaves synthesis to the caller. Advisory-only; not part of the relay loop. |
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
   221	Expect Codex to claim and ping the token, append its block to the relay file,
   222	release or `done` the token, revert any off-allowlist edits, commit only the
   223	allowlisted paths, and skip push. The transcript lands in
   224	`"${TMPDIR:-/tmp}/codex-turn-$$.log"`.
   225	
   226	#### agy worker
   227	
   228	```bash
   229	# Reuse an existing relay thread or scaffold a fresh one with embedded
   230	# TAKE YOUR TURN instructions.
   231	RELAY=relay-system/$(date +%F)/<your-slug>.md
   232	ARTIFACT=relay-automation/agy-turn.sh
   233	
   234	# Use a per-relay token id, not the literal RELAY-TURN.
   235	TASK="RELAY-$(basename "$RELAY" .md)"
   236	
   237	./bin/tick log task.created "$TASK" --agent claude-a
   238	./bin/tick claim   "$TASK" --agent claude-a --paths "$ARTIFACT"
   239	./bin/tick release "$TASK" --agent claude-a --to agy
   240	

codex
I’ve got the lock implementations. I’m checking call graphs now to verify whether the registry→projection nested lock has any reverse ordering anywhere else, and whether the documentation change really is only catching docs up to existing per-PID defaults.
exec
/bin/zsh -lc 'rg -n "publish_registry_projection|write_registry_projection|write_install_registry_row|run_with_advisory_lock|acquire_advisory_lock|CODEX_LOG=|AGY_LOG=" install.sh relay-automation/xyz-vendor.sh skills/relay-xyz/SKILL.md relay-automation/README.md' in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-97461-32007
 succeeded in 0ms:
relay-automation/xyz-vendor.sh:101:acquire_advisory_lock() {
relay-automation/xyz-vendor.sh:140:run_with_advisory_lock() {
relay-automation/xyz-vendor.sh:143:  if acquire_advisory_lock "$target" "$label"; then
relay-automation/xyz-vendor.sh:225:  run_with_advisory_lock "$reg" "registry" write_registry_row "$reg" "$VENDOR_DIR" "$row"
relay-automation/README.md:213:CODEX_AGENT=codex ALLOW_PATHS="$ARTIFACT" CODEX_LOG="${TMPDIR:-/tmp}/codex-turn-$$.log" \
relay-automation/README.md:241:AGY_AGENT=agy ALLOW_PATHS="$ARTIFACT" AGY_LOG="${TMPDIR:-/tmp}/agy-turn-$$.log" \
relay-automation/README.md:285:CODEX_LOG="${TMPDIR:-/tmp}/codex-turn-$$.log" \
relay-automation/README.md:301:AGY_LOG="${TMPDIR:-/tmp}/agy-turn-$$.log" \
install.sh:126:acquire_advisory_lock() {
install.sh:165:run_with_advisory_lock() {
install.sh:168:  if acquire_advisory_lock "$target" "$label"; then
install.sh:199:write_registry_projection() {
install.sh:221:publish_registry_projection() {
install.sh:237:  run_with_advisory_lock "$out" "git-pulse projection" write_registry_projection "$out"
install.sh:241:write_install_registry_row() {
install.sh:247:      publish_registry_projection   # best-effort multi-device rollup; never fails the install
install.sh:285:  run_with_advisory_lock "$reg" "registry" write_install_registry_row "$reg" "$TARGET" "$row" "$ver" "$src_commit" "$coord"
skills/relay-xyz/SKILL.md:115:| Codex | `"$RELAY_HAS_CODEX" = 1` | `codex` | `CODEX_AGENT=codex ALLOW_PATHS="$ARTIFACT" CODEX_LOG="${TMPDIR:-/tmp}/codex-turn-$$.log"` | `relay-automation/codex-turn.sh` | `${TMPDIR:-/tmp}/codex-turn-$$.log` |
skills/relay-xyz/SKILL.md:116:| agy | `"$RELAY_HAS_AGY" = 1` | `agy` | `AGY_AGENT=agy ALLOW_PATHS="$ARTIFACT" AGY_LOG="${TMPDIR:-/tmp}/agy-turn-$$.log"` | `relay-automation/agy-turn.sh` | `${TMPDIR:-/tmp}/agy-turn-$$.log` |
skills/relay-xyz/SKILL.md:136:CODEX_AGENT=codex ALLOW_PATHS="$ARTIFACT" CODEX_LOG="${TMPDIR:-/tmp}/codex-turn-$$.log" \
skills/relay-xyz/SKILL.md:157:AGY_AGENT=agy ALLOW_PATHS="$ARTIFACT" AGY_LOG="${TMPDIR:-/tmp}/agy-turn-$$.log" \

exec
/bin/zsh -lc 'rg -n "registry.lock|git-pulse projection|publish_registry_projection|write_registry_projection|run_with_advisory_lock" -S .' in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-97461-32007
 succeeded in 0ms:
./README.md:60:- `--no-register` — skip the registry write entirely (also skips git-pulse projection).
./install.sh:50:                         override with XYZ_REGISTRY). Also skips the git-pulse projection.
./install.sh:165:run_with_advisory_lock() {
./install.sh:199:write_registry_projection() {
./install.sh:221:publish_registry_projection() {
./install.sh:237:  run_with_advisory_lock "$out" "git-pulse projection" write_registry_projection "$out"
./install.sh:247:      publish_registry_projection   # best-effort multi-device rollup; never fails the install
./install.sh:285:  run_with_advisory_lock "$reg" "registry" write_install_registry_row "$reg" "$TARGET" "$row" "$ver" "$src_commit" "$coord"
./relay-automation/xyz-vendor.sh:140:run_with_advisory_lock() {
./relay-automation/xyz-vendor.sh:225:  run_with_advisory_lock "$reg" "registry" write_registry_row "$reg" "$VENDOR_DIR" "$row"
./PROJECT/3-COMPLETED/GH-62-XYZ-INSTALL-REGISTRY.md:41:- **Multi-device rollup:** best-effort git-pulse projection (path-normalized; never absolute paths),
./ROADMAP.md:107:- **GH-62 · XYZ install registry (call-home to remember install locations)** ✅ 2026-06-30 (#62) — borrowed PDDA's install→call-home pattern: new `install.sh` materializes the runtime (`bin/tick`+`src/*.js`) into a target dir, then registers the install in a machine-local `~/.config/xyz/registry.tsv` (key=`install_dir`, latest-wins; cols utc/`tick_version`/`source_commit`/`coordinated_repo`; best-effort git-pulse projection; never committed). Same fail-open register step mirrored into the `/xyz` SKILL self-extract (lockstep). Surfaces the `bin/tick`(0.2.0)↔SKILL-embed(0.1.0) drift per-install. **Independently QA'd via automated agy `/relay-xyz` (2 rounds → Approved)** — 3 hardening fixes folded in (`cd "-"` sentinel guard, registry-init fail-open, tmp-leak cleanup). `./validate.sh` 69/69. Follow-ons (out of scope): `xyz-sync` push tool + the embed-drift fix. → [GH-62-XYZ-INSTALL-REGISTRY.md](PROJECT/3-COMPLETED/GH-62-XYZ-INSTALL-REGISTRY.md) · relay [gh62-install-registry-qa.md](relay-system/2026-06-30/gh62-install-registry-qa.md) · [#62](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/62)
./CHANGELOG.md:76:- **New `install.sh`** (repo root): materializes the canonical modular runtime (`bin/tick` + all `src/*.js`) into a target dir, then registers the install in a per-user, machine-local `~/.config/xyz/registry.tsv` (override `XYZ_REGISTRY`; opt out `--no-register`). Key = `install_dir` (dedup, latest wins); columns `last_install_utc · tick_version · source_commit · coordinated_repo`. `--repo <path>` (or `$TICK_REPO_ROOT`) records the coordinated repo. Best-effort git-pulse projection for multi-device rollup (path-normalized; fail-open). Never committed — lives in `$HOME`.
./relay-system/2026-07-01/gh-70-definitive-unlock-review-same-device-concurrent-multi-repo-xyz.md:67:- [Should] Machine-global install state is still shared and unlocked, so same-device multi-repo operations can still clobber each other outside the relay lock itself. Both `relay-automation/xyz-vendor.sh` and `install.sh` rewrite `~/.config/xyz/registry.tsv` by reading the current file into `"$reg.tmp.$$"` and `mv`ing it back with no lock (`relay-automation/xyz-vendor.sh:98-131`, `install.sh:144-183`); `install.sh` also rewrites the git-pulse projection the same way (`install.sh:112-140`). Two concurrent vendor/install/update operations can lose one writer's row. Concrete fix: serialize registry/projection writes with a per-user lock (for example a `mkdir` lock beside the registry) or switch to an append-plus-merge scheme.
./relay-system/2026-06-30/pdda-git-pulse-multi-device-publish-iteration-1.md:40:    register_install() now calls publish_registry_projection() on every successful
./relay-system/2026-06-30/pdda-git-pulse-multi-device-publish-iteration-1.md:75:    register_install() now calls publish_registry_projection() on every successful
./relay-system/2026-06-30/pdda-git-pulse-multi-device-publish-iteration-1.md:106:+Wired Iteration 1 of the multi-device rollup: `install.sh` now has `publish_registry_projection()`, called
./relay-system/2026-06-30/pdda-git-pulse-multi-device-publish-iteration-1.md:146:+| **Iteration 1 built and shipped.** `publish_registry_projection()` added to `install.sh` and called from `register_install()` on every successful install/upgrade: when git-pulse is present it writes a path-normalized `pdda/registry-<device>.tsv` (bare repo name + date + source commit + mode; no absolute paths), carried by git-pulse's own sync. Best-effort/fail-open. Key = bare repo name with an exact-then-fuzzy maintainer `find` note. Backfilled today's ledger by hand earlier; this makes it automatic going forward. | Nothing committed remaining. Deferred (YAGNI, reopen if needed): a `roster` aggregation read and folding the projection into `pdda-sync.sh status`. |
./relay-system/2026-06-30/pdda-git-pulse-multi-device-publish-iteration-1.md:190:+                         Also skips the multi-device git-pulse projection (see below).
./relay-system/2026-06-30/pdda-git-pulse-multi-device-publish-iteration-1.md:222:+publish_registry_projection() {
./relay-system/2026-06-30/pdda-git-pulse-multi-device-publish-iteration-1.md:255:+# install. On success it also publishes the multi-device projection (publish_registry_projection).
./relay-system/2026-06-30/pdda-git-pulse-multi-device-publish-iteration-1.md:266:+      publish_registry_projection   # best-effort multi-device rollup; never fails the install
./relay-system/2026-06-30/pdda-git-pulse-multi-device-publish-iteration-1.md:278:+# Test: install.sh's git-pulse projection (publish_registry_projection).
./relay-system/2026-06-30/pdda-git-pulse-multi-device-publish-iteration-1.md:373:- Implemented the [Should]. `publish_registry_projection()` now writes the projection to a temp file in the same dir and atomically `mv`s it into place, so git-pulse's concurrent sync can never observe a half-truncated file; a failed generation leaves the prior good projection untouched (mirrors install.sh's own local-registry write).
./relay-system/2026-07-01/lane-b-gh72-registry-lock.md:15:**Problem:** `~/.config/xyz/registry.tsv` and the git-pulse projection are updated with an UNLOCKED
./relay-system/2026-07-01/lane-b-gh72-registry-lock.md:21:- Use a portable `mkdir`-based lock (atomic) beside the registry, e.g. `~/.config/xyz/registry.lock`
./relay-system/2026-07-01/lane-b-gh72-registry-lock.md:33:- `install.sh` (registry ~L144-183; git-pulse projection ~L112-140)
./relay-system/2026-07-01/lane-b-gh72-registry-lock.md:43:Basis: Added per-file `mkdir` advisory locks around the two registry writers and the git-pulse projection writer, with stale-lock reclaim, bounded wait, EXIT cleanup, and fail-open warnings; verified the lock behavior with focused parse + concurrency checks, and the remaining `bash test/xyz-vendor.sh` failure is the pre-existing no-`.xyz` locator assertion, outside these lock edits.
./relay-system/2026-07-01/lane-b-gh72-registry-lock.md:44:- `relay-automation/xyz-vendor.sh`: added a local `registry.lock` helper and wrapped the registry read-modify-write without changing the TSV row bytes.
./relay-system/2026-07-01/lane-b-gh72-registry-lock.md:45:- `install.sh`: added the same helper pattern and wrapped both the install registry writer and the git-pulse projection writer so each temp-file `mv` happens under its per-file lock.
./relay-system/2026-06-30/gh62-install-registry-qa.md:82:                         override with XYZ_REGISTRY). Also skips the git-pulse projection.
./relay-system/2026-06-30/gh62-install-registry-qa.md:145:publish_registry_projection() {
./relay-system/2026-06-30/gh62-install-registry-qa.md:206:      publish_registry_projection   # best-effort multi-device rollup; never fails the install
./relay-system/2026-06-30/gh62-install-registry-qa.md:236:     git-pulse projection is path-normalized (no absolute paths leak across devices).
./relay-system/2026-06-30/gh62-install-registry-qa.md:287:      publish_registry_projection   # best-effort multi-device rollup; never fails the install

exec
/bin/zsh -lc "rg -n \"TMPDIR:-/tmp.*codex-turn|TMPDIR:-/tmp.*agy-turn|codex-turn-\\"'$'"\\"'$|agy-turn-'"\\"'$'"\\"'$|codex-turn'"\\.log|agy-turn\\.log\" skills/relay-xyz/SKILL.md relay-automation/README.md relay-automation/*.sh" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-97461-32007
 succeeded in 0ms:
relay-automation/agy-turn.sh:114:AGY_LOG="${AGY_LOG:-${TMPDIR:-/tmp}/agy-turn-$$.log}"
relay-automation/README.md:213:CODEX_AGENT=codex ALLOW_PATHS="$ARTIFACT" CODEX_LOG="${TMPDIR:-/tmp}/codex-turn-$$.log" \
relay-automation/README.md:224:`"${TMPDIR:-/tmp}/codex-turn-$$.log"`.
relay-automation/README.md:241:AGY_AGENT=agy ALLOW_PATHS="$ARTIFACT" AGY_LOG="${TMPDIR:-/tmp}/agy-turn-$$.log" \
relay-automation/README.md:251:allowlisted paths, and skip push. The transcript lands in `"${TMPDIR:-/tmp}/agy-turn-$$.log"`.
relay-automation/README.md:285:CODEX_LOG="${TMPDIR:-/tmp}/codex-turn-$$.log" \
relay-automation/README.md:301:AGY_LOG="${TMPDIR:-/tmp}/agy-turn-$$.log" \
relay-automation/codex-turn.sh:74:CODEX_LOG="${CODEX_LOG:-${TMPDIR:-/tmp}/codex-turn-$$.log}"
skills/relay-xyz/SKILL.md:115:| Codex | `"$RELAY_HAS_CODEX" = 1` | `codex` | `CODEX_AGENT=codex ALLOW_PATHS="$ARTIFACT" CODEX_LOG="${TMPDIR:-/tmp}/codex-turn-$$.log"` | `relay-automation/codex-turn.sh` | `${TMPDIR:-/tmp}/codex-turn-$$.log` |
skills/relay-xyz/SKILL.md:116:| agy | `"$RELAY_HAS_AGY" = 1` | `agy` | `AGY_AGENT=agy ALLOW_PATHS="$ARTIFACT" AGY_LOG="${TMPDIR:-/tmp}/agy-turn-$$.log"` | `relay-automation/agy-turn.sh` | `${TMPDIR:-/tmp}/agy-turn-$$.log` |
skills/relay-xyz/SKILL.md:136:CODEX_AGENT=codex ALLOW_PATHS="$ARTIFACT" CODEX_LOG="${TMPDIR:-/tmp}/codex-turn-$$.log" \
skills/relay-xyz/SKILL.md:157:AGY_AGENT=agy ALLOW_PATHS="$ARTIFACT" AGY_LOG="${TMPDIR:-/tmp}/agy-turn-$$.log" \

codex
The docs update looks straightforward so far: the examples now match the shims’ existing per-PID defaults. I’m reading the shim defaults directly to confirm there isn’t another fixed-path example still left behind.
exec
/bin/zsh -lc "nl -ba relay-automation/codex-turn.sh | sed -n '60,95p'" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-97461-32007
exec
/bin/zsh -lc "nl -ba relay-automation/agy-turn.sh | sed -n '100,130p'" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-97461-32007
 succeeded in 0ms:
    60	# GH-68 warn-only: prepend any UNREAD cross-agent dependency-drift heads-up to the turn brief, so a
    61	# builder learns a peer changed a shared surface (kernel/projection/schema) since its last turn. No
    62	# unread drift → empty → prompt unchanged. Never blocks. (decisions/2026-07-01-cross-agent-dep-conflict.md)
    63	drift_brief="$(rtl_drift_brief "$me" "${TICK_REPO_ROOT:-$ROOT}")"
    64	[[ -n "$drift_brief" ]] && prompt="${drift_brief}"$'\n'"${prompt}"
    65	
    66	# Run the Codex turn headless (token ops + edit the relay file; NO git), then enforce the boundary.
    67	# CODEX_FLAGS gives the turn enough autonomy to actually write on a fresh device (default sandbox is
    68	# read-only); operator-overridable for tighter/looser policies.
    69	read -ra _cflags <<<"${CODEX_FLAGS:--s workspace-write}"
    70	codex_extra_flags=()
    71	# Transcript: default to a $TMPDIR file (NOT the repo tree — the in-tree log guard deletes it).
    72	# Persists the transcript so the headless run is auditable. (Codex token-stats parsing is a follow-up
    73	# — its usage format isn't probed yet, so cost.tokens for Codex turns stays a Phase-1 partial.)
    74	CODEX_LOG="${CODEX_LOG:-${TMPDIR:-/tmp}/codex-turn-$$.log}"
    75	rtl_before
    76	turn_timeout="${RELAY_TURN_TIMEOUT_S:-300}"
    77	bounded_rc=0
    78	
    79	# Worktree isolation (opt-in; ROADMAP Part A Phase 3.6 — same wiring as claude-turn.sh / agy-turn.sh).
    80	# When RELAY_WORKTREE_ISOLATION=1, run codex with CWD = a THROWAWAY git worktree of ROOT@HEAD, so any
    81	# async/background write lands in a tree we delete, never ROOT. .tick stays SHARED via TICK_REPO_ROOT.
    82	# Default OFF → the in-ROOT run below is byte-for-byte the prior behaviour.
    83	wt=""; cwd_wrap=()
    84	if [[ "${RELAY_WORKTREE_ISOLATION:-0}" == "1" ]]; then
    85	  if wt="$(rtl_worktree_begin)"; then
    86	    # TICK_REPO_ROOT already exported above (unconditional) — .tick stays SHARED with ROOT here.
    87	    cwd_wrap=(bash -c 'cd "$1" || exit 127; shift; exec "$@"' bash "$wt")
    88	    # GH-36: the isolated worktree is the primary workspace, so the shared token lock under
    89	    # $TICK_REPO_ROOT/.tick is outside Codex's default workspace-write sandbox unless we add it.
    90	    codex_extra_flags=(--add-dir "$ROOT/.tick")
    91	    printf 'codex-turn: worktree isolation ON (%s)\n' "$wt" >&2
    92	  else
    93	    printf 'codex-turn: worktree isolation requested but `git worktree add` failed — failing turn\n' >&2
    94	    exit 5
    95	  fi

 succeeded in 0ms:
   100	if [[ -n "$_cwd_git_root" && "$(cd "$ROOT" 2>/dev/null && pwd)" != "$_cwd_git_root" ]]; then
   101	  printf 'agy-turn: CROSS-REPO mode (AGY_TURN_ROOT=%s != CWD git root=%s) — agy resolves relative paths against CWD, not the target repo. List TARGET files by ABSOLUTE path in %s or agy will silently find nothing. (CONSUMING.md)\n' "$ROOT" "$_cwd_git_root" "$f" >&2
   102	fi
   103	
   104	prompt="$(rtl_turn_prompt "$me" "$f" "$t" "${ALLOW_PATHS:-}" "${RELAY_PEER:-}")"
   105	# GH-68 warn-only: prepend any UNREAD cross-agent dependency-drift heads-up to the turn brief, so a
   106	# builder learns a peer changed a shared surface (kernel/projection/schema) since its last turn. No
   107	# unread drift → empty → prompt unchanged. Never blocks. (decisions/2026-07-01-cross-agent-dep-conflict.md)
   108	drift_brief="$(rtl_drift_brief "$me" "${TICK_REPO_ROOT:-$ROOT}")"
   109	[[ -n "$drift_brief" ]] && prompt="${drift_brief}"$'\n'"${prompt}"
   110	
   111	# Transcript/log: default to a $TMPDIR file (NOT the repo tree — the in-tree log guard in
   112	# relay-turn-lib.sh deletes any in-tree log). Persisted so the headless run is auditable. Unlike the
   113	# Gemini shim there is no `-o json`, so this transcript is debug-only — no token stats to parse.
   114	AGY_LOG="${AGY_LOG:-${TMPDIR:-/tmp}/agy-turn-$$.log}"
   115	
   116	# Build the agy invocation. --print-timeout is pinned to the wall-clock cap so agy returns on its own
   117	# just before the rtl watchdog would kill it; --model and AGY_FLAGS are optional pass-throughs.
   118	turn_timeout="${RELAY_TURN_TIMEOUT_S:-300}"
   119	agy_args=(--dangerously-skip-permissions --print-timeout "${turn_timeout}s")
   120	[[ -n "${AGY_MODEL:-}" ]] && agy_args+=(--model "$AGY_MODEL")
   121	read -ra _aflags <<<"${AGY_FLAGS:-}"
   122	[[ "${#_aflags[@]}" -gt 0 ]] && agy_args+=("${_aflags[@]}")
   123	
   124	# Run the agy turn headless (token ops + edit the relay file; NO git), then enforce the boundary.
   125	rtl_before
   126	bounded_rc=0
   127	
   128	# Worktree isolation (opt-in; ROADMAP Part A Phase 3.6 — same wiring as claude-turn.sh). When
   129	# RELAY_WORKTREE_ISOLATION=1, run agy with CWD = a THROWAWAY git worktree of ROOT@HEAD, so any
   130	# async/background write lands in a tree we delete, never ROOT. .tick coordination state stays SHARED

exec
/bin/zsh -lc "nl -ba relay-automation/README.md | sed -n '200,315p'" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-97461-32007
 succeeded in 0ms:
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
   221	Expect Codex to claim and ping the token, append its block to the relay file,
   222	release or `done` the token, revert any off-allowlist edits, commit only the
   223	allowlisted paths, and skip push. The transcript lands in
   224	`"${TMPDIR:-/tmp}/codex-turn-$$.log"`.
   225	
   226	#### agy worker
   227	
   228	```bash
   229	# Reuse an existing relay thread or scaffold a fresh one with embedded
   230	# TAKE YOUR TURN instructions.
   231	RELAY=relay-system/$(date +%F)/<your-slug>.md
   232	ARTIFACT=relay-automation/agy-turn.sh
   233	
   234	# Use a per-relay token id, not the literal RELAY-TURN.
   235	TASK="RELAY-$(basename "$RELAY" .md)"
   236	
   237	./bin/tick log task.created "$TASK" --agent claude-a
   238	./bin/tick claim   "$TASK" --agent claude-a --paths "$ARTIFACT"
   239	./bin/tick release "$TASK" --agent claude-a --to agy
   240	
   241	AGY_AGENT=agy ALLOW_PATHS="$ARTIFACT" AGY_LOG="${TMPDIR:-/tmp}/agy-turn-$$.log" \
   242	relay-automation/relay-drive.sh \
   243	  --relay-file "$RELAY" \
   244	  --relay-task "$TASK" \
   245	  --agent-cmd relay-automation/agy-turn.sh \
   246	  --round-cap 4
   247	```
   248	
   249	Expect agy to claim and ping the token, append its block to the relay file,
   250	release or `done` the token, revert any off-allowlist edits, commit only the
   251	allowlisted paths, and skip push. The transcript lands in `"${TMPDIR:-/tmp}/agy-turn-$$.log"`.
   252	
   253	Exit codes:
   254	
   255	- `relay-drive.sh`: `0` closed Approved or Closed, `3` no progress, `4` round cap or closed-not-approved, `5` (with `--review-once`) reviewer completed a single non-approval review ("changes requested" — not a stall), `2` usage.
   256	- `codex-turn.sh`: `0` acted or deferred, `5` Codex failed, `6` off-allowlist edit reverted or Codex committed mid-turn, `7` timeout-killed, `2` usage.
   257	- `agy-turn.sh`: `0` acted or deferred, `5` agy failed or produced empty output, `6` off-allowlist edit reverted or agy committed mid-turn, `7` timeout-killed, `2` usage.
   258	- `bin/tick`: exits `8` when structural quality validation fail occurs (`bin/validate-relay-block` exits non-zero when `--relay-file` flag is provided to `release` or `done`).
   259	
   260	### 5. Review a file in another repo
   261	
   262	The common case is reviewing a target repo while using this clone only as the
   263	harness. The thread and artifact live in the target repo; `.tick` and `bin/tick`
   264	stay anchored to the harness.
   265	
   266	```bash
   267	HARNESS=/path/to/xyz-3-agents-swarm
   268	TARGET=/path/to/your-repo
   269	
   270	export TICK_REPO_ROOT="$HARNESS"
   271	
   272	# Run from the target root to keep relay and artifact paths repo-relative.
   273	cd "$TARGET"
   274	RELAY=relay-system/$(date +%F)/<your-slug>.md
   275	ARTIFACT=path/to/file/under/target.ext
   276	TASK="RELAY-$(basename "$RELAY" .md)"
   277	
   278	"$HARNESS/bin/tick" log task.created "$TASK" --agent claude-a
   279	"$HARNESS/bin/tick" claim   "$TASK" --agent claude-a --paths "$ARTIFACT"
   280	"$HARNESS/bin/tick" release "$TASK" --agent claude-a --to codex
   281	
   282	CODEX_AGENT=codex \
   283	ALLOW_PATHS="$ARTIFACT" \
   284	CODEX_FLAGS='--dangerously-bypass-approvals-and-sandbox' \
   285	CODEX_LOG="${TMPDIR:-/tmp}/codex-turn-$$.log" \
   286	"$HARNESS/relay-automation/relay-drive.sh" \
   287	  --target-root "$TARGET" \
   288	  --relay-file "$RELAY" \
   289	  --relay-task "$TASK" \
   290	  --agent-cmd "$HARNESS/relay-automation/codex-turn.sh" \
   291	  --round-cap 4
   292	```
   293	
   294	Swap the worker-specific lines to drive agy instead:
   295	
   296	```bash
   297	"$HARNESS/bin/tick" release "$TASK" --agent claude-a --to agy
   298	
   299	AGY_AGENT=agy \
   300	ALLOW_PATHS="$ARTIFACT" \
   301	AGY_LOG="${TMPDIR:-/tmp}/agy-turn-$$.log" \
   302	"$HARNESS/relay-automation/relay-drive.sh" \
   303	  --target-root "$TARGET" \
   304	  --relay-file "$RELAY" \
   305	  --relay-task "$TASK" \
   306	  --agent-cmd "$HARNESS/relay-automation/agy-turn.sh" \
   307	  --round-cap 4
   308	```
   309	
   310	The boundary is unchanged: path allowlist, file-scoped commit, no push, and
   311	worktree isolation of `target@HEAD`. Only the artifact side moves to
   312	`--target-root`.
   313	
   314	### 6. Device caveats
   315	

codex
I have enough of the implementation to judge the lock itself. I’m doing one last pass for any repo-local issue notes on `#72`/`#73`, in case there’s an intended scope or caveat that affects whether “safe to close” means “fully fixed” versus “fixed with a known follow-on.”
exec
/bin/zsh -lc 'rg -n "#72|GH-72|issue 72|#73|GH-73|issue 73" PROJECT relay-system ROADMAP.md CHANGELOG.md' in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-97461-32007
 succeeded in 0ms:
ROADMAP.md:97:- **GH-72 · Registry/projection write-lock** ✅ **SHIPPED 2026-07-01 (`d427a90`, concurrent dogfood Lane B / codex)** — `mkdir`-based per-user advisory lock (acquire/release/EXIT-trap, bounded wait, stale-reclaim, fail-open) around the registry + git-pulse read-modify-writes in `xyz-vendor.sh` + `install.sh`; concurrent vendor/install no longer lose a row; TSV bytes unchanged. `validate.sh` 74/74. Built by codex headless, concurrently with GH-73. → [#72](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/72)
ROADMAP.md:98:- **GH-73 · Docs pin fixed /tmp transcript log paths** ✅ **SHIPPED 2026-07-01 (`d427a90`, concurrent dogfood Lane A / agy)** — every fixed `/tmp` transcript-log example in `SKILL.md` + `README.md` switched to per-PID `-$$.log` + a note that fixed paths break concurrent same-machine runs (shims were already per-PID; only docs lagged). Built by agy headless, concurrently with GH-72. → [#73](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/73)
CHANGELOG.md:7:### Concurrent dogfood — GH-72 + GH-73 built by two headless builders AT ONCE (proves the concurrency)
CHANGELOG.md:9:- **Lane A (agy) → GH-73 (#73)**: doc fix — every fixed `/tmp` transcript-log example in `skills/relay-xyz/SKILL.md` + `relay-automation/README.md` switched to per-PID `-$$.log` (+ a note that fixed paths break concurrent same-machine runs). The shims already defaulted to per-PID; only the docs lagged.
CHANGELOG.md:10:- **Lane B (codex) → GH-72 (#72)**: a `mkdir`-based per-user **advisory lock** (acquire/release/EXIT-trap, bounded wait, stale-reclaim, **fail-open**) wrapping the registry + git-pulse read-modify-writes in `relay-automation/xyz-vendor.sh` + `install.sh`, so concurrent vendor/install ops can't lose a row. TSV bytes unchanged.
CHANGELOG.md:305:First **DUELING-CLAUDES** run against a foreign repo: the KISS-woo-fast-search bug-fix batch, four gate-verifiable phases (#72/#71/#68/#70). Reporter = an xyz window (files graded reports off the marathon handoff package), Maintainer = a Claude window on the plugin repo (fixes, runs the gate, stops for operator "go"); objective referee = the plugin's `bash tests/run.sh`. **Outcome: all four phases green, gate `12 passed / 1 failed`** (lone red = the #75 cache-key method, the deliberate human checkpoint — `GATE: FAIL` overall is the expected clean-run end state). Thread: [relay-system/2026-06-26/kwfs-dueling-bugfix.md](relay-system/2026-06-26/kwfs-dueling-bugfix.md).
CHANGELOG.md:309:- **Documented:** actionable items → [ROADMAP.md → Queue / parked intake](ROADMAP.md#queue--parked-intake) (4 entries); full findings → [AUTOMATED-RELAY.md → Field findings](PROJECT/2-WORKING/AUTOMATED-RELAY.md#field-findings--first-cross-repo-dueling-run-2026-06-26); operator limits → [DUELING-CLAUDES.md → Notes & limits](relay-automation/DUELING-CLAUDES.md#notes--limits). Plugin fixes committed locally on `BUG-FIXES-2026-06-26` (no push — operator's PR call against `development`); prod-data items (#73/#76/#75-wiring/#69-values) remain in the plugin's `tests/HUMAN-VERIFY.md`.
relay-system/combined/aggregated-2026-06-27-to-2026-06-30.json:4:		"title": "RELAY \u00b7 QA #73 coupon bulk rebuild (KISS-woo-fast-search)",
relay-system/combined/aggregated-2026-06-27-to-2026-06-30.json:10:		"title": "QA Review Packet \u2014 KISS-woo-fast-search issue #73 (coupon lookup bulk rebuild)",
relay-system/2026-06-26/kwfs-dueling-bugfix.md:23:1. **#72** — remove stale README/AUDIT.md security/perf warnings  → gate `#72` (phrase grep)
relay-system/2026-06-26/kwfs-dueling-bugfix.md:31:`#73` coupon rebuild, `#76` analytics path, `#75` cache wiring/invalidation, `#69` payment/shipping
relay-system/2026-06-26/kwfs-dueling-bugfix.md:40:1. Pick the next phase not yet reported below, in scope order (#72 → #71 → #68 → #70).
relay-system/2026-06-26/kwfs-dueling-bugfix.md:63:### REPORT — #72 (Reporter / claude-a)
relay-system/2026-06-26/kwfs-dueling-bugfix.md:77:`tests/gate.php`. Open `tests/gate.php`, find the `#72` needle list, and ensure **none** of those exact
relay-system/2026-06-26/kwfs-dueling-bugfix.md:79:offending sentences, not append "(Fixed)". Annotating in place will leave `#72` RED.
relay-system/2026-06-26/kwfs-dueling-bugfix.md:82:- `bash tests/run.sh` shows the `#72` invariant **PASS** (FAIL → PASS).
relay-system/2026-06-26/kwfs-dueling-bugfix.md:88:**NEXT:** claude-b — verify, fix smallest, run the gate, capture the `#72` FAIL→PASS delta, show the
relay-system/2026-06-26/kwfs-dueling-bugfix.md:93:### FIX — #72 (Maintainer / claude-b)
relay-system/2026-06-26/kwfs-dueling-bugfix.md:106:- `#72`: **FAIL → PASS** (all 4 needle checks green: README ×2, AUDIT ×2).
relay-system/2026-06-26/kwfs-dueling-bugfix.md:336:| #72 — stale README/AUDIT.md warnings removed | `d2eaa8a` | FAIL → PASS |
relay-system/2026-06-26/kwfs-dueling-bugfix.md:346:**Still human-gated (see `tests/HUMAN-VERIFY.md`):** #73 coupon rebuild, #76 analytics path, #75 cache
relay-system/2026-07-01/lane-b-gh72-registry-lock.md:1:# RELAY · Lane B — GH-72 registry/projection write-lock (BUILD turn, codex)
relay-system/2026-07-01/lane-b-gh72-registry-lock.md:13:## BUILD BRIEF (GH-72 — issue #72)
relay-system/2026-07-01/lane-a-gh73-tmp-log-docs.md:1:# RELAY · Lane A — GH-73 fixed-/tmp-log docs (BUILD turn, agy)
relay-system/2026-07-01/lane-a-gh73-tmp-log-docs.md:13:## BUILD BRIEF (GH-73 — issue #73)
PROJECT/2-WORKING/AUTOMATED-RELAY.md:65:four gate-verifiable phases (#72/#71/#68/#70), Reporter = an xyz window, Maintainer = a Claude window
relay-system/2026-06-29/pr77-qa.md:402: | **#73** | Coupon build indexes **all ~338k published** coupons (not ~55k) and finishes in <60s. The gate cannot stand up 363k coupons or a MySQL server. | Phase 1 QA for #73 — run the build on a copy of production, compare indexed count vs published count. |
relay-system/2026-06-29/pr77-qa.md:646:> **Reviewer praise (no action):** #73 coupon rebuild architecture, `get_edit_url()`
relay-system/2026-06-27/pr77-codex-review.md:143:+  - "#72  Stale README/AUDIT.md warnings (documentation, low)"
relay-system/2026-06-27/pr77-codex-review.md:144:+  - "#73  Coupon lookup build catastrophically slow (bug, CRITICAL)"
relay-system/2026-06-27/pr77-codex-review.md:149:+  - "Phase 1 — Critical & High correctness fixes (#73, #68)"
relay-system/2026-06-27/pr77-codex-review.md:152:+  - "Phase 4 — Packaging & documentation hygiene (#71, #72)"
relay-system/2026-06-27/pr77-codex-review.md:165:+| _None yet — project scoped from GitHub issues on 2026-06-26._ | **Phase 1 — Critical & High correctness fixes** (start with #73 coupon rebuild, then #68 HPOS edit URLs). |
relay-system/2026-06-27/pr77-codex-review.md:175:+  - [#73 — Coupon lookup table build catastrophically slow (CRITICAL)](#73--coupon-lookup-table-build-catastrophically-slow-critical)
relay-system/2026-06-27/pr77-codex-review.md:189:+  - [#72 — Stale README/AUDIT.md security/performance warnings (LOW)](#72--stale-readmeauditmd-securityperformance-warnings-low)
relay-system/2026-06-27/pr77-codex-review.md:199:+### #73 — Coupon lookup table build catastrophically slow (CRITICAL)
relay-system/2026-06-27/pr77-codex-review.md:215:+**QA for #73:**
relay-system/2026-06-27/pr77-codex-review.md:240:+- [ ] #73 and #68 each verified against their per-issue QA above.
relay-system/2026-06-27/pr77-codex-review.md:404:+### #72 — Stale README/AUDIT.md security/performance warnings (LOW)
relay-system/2026-06-27/pr77-codex-review.md:417:+**QA for #72:**
relay-system/2026-06-27/pr77-codex-review.md:423:+- [ ] #71 and #72 verified against their per-issue QA.
relay-system/2026-06-27/pr77-codex-review.md:433:+- **Verify-before-trust items:** #76's `wc_order_stats` completeness and #73's coupon counts both require validation against real production data before sign-off.
relay-system/2026-06-27/pr77-codex-review.md:956:+| **#73** | Coupon build indexes **all ~338k published** coupons (not ~55k) and finishes in <60s. The gate cannot stand up 363k coupons or a MySQL server. | Phase 1 QA for #73 — run the build on a copy of production, compare indexed count vs published count. |
relay-system/2026-06-27/pr77-codex-review.md:968:+- **#72** — README/AUDIT.md no longer contain the stale security/performance warnings.
relay-system/2026-06-27/pr77-codex-review.md:987:+ * tests/HUMAN-VERIFY.md (the invariants a machine CANNOT check — #73/#75-invalidation/#76).
relay-system/2026-06-27/pr77-codex-review.md:1085:+echo "== #73  coupon build uses bulk SQL, not per-row WC_Coupon hydration ==\n";
relay-system/2026-06-27/pr77-codex-review.md:1086:+// Regression guard for #73: the catastrophic build was a per-coupon `new WC_Coupon`
relay-system/2026-06-27/pr77-codex-review.md:1092:+check( 'lookup has bulk_upsert_posts() multi-row writer', strpos( $lk, 'function bulk_upsert_posts' ) !== false && strpos( $lk, 'ON DUPLICATE KEY UPDATE' ) !== false, 'add the bulk upsert writer (#73)' );
relay-system/2026-06-27/pr77-codex-review.md:1093:+check( 'lookup has rebuild_all() single-pass rebuild', strpos( $lk, 'function rebuild_all' ) !== false, 'add rebuild_all() (#73)' );
relay-system/2026-06-27/pr77-codex-review.md:1094:+check( 'backfill batch uses the bulk writer', strpos( $bf, 'bulk_upsert_posts' ) !== false, 'route backfill through bulk_upsert_posts (#73)' );
relay-system/2026-06-27/pr77-codex-review.md:1095:+check( 'backfill batch no longer hydrates per-row', strpos( $bf, 'upsert_coupon' ) === false, 'backfill must not call upsert_coupon per row (#73)' );
relay-system/2026-06-27/pr77-codex-review.md:1096:+check( 'builder runs a single-pass rebuild_all', strpos( $bd, 'rebuild_all' ) !== false, 'builder must drive rebuild_all() (#73)' );
relay-system/2026-06-27/pr77-codex-review.md:1129:+echo "== #72  README/AUDIT.md no longer warn about already-fixed issues ==\n";
relay-system/2026-06-27/pr77-codex-review.md:1137:+		check( "$file: stale warning removed — \"$p\"", strpos( $body, $p ) === false, 'remove or rewrite this stale warning (#72)' );
relay-system/2026-06-27/kwfs-73-review-packet.md:1:# QA Review Packet — KISS-woo-fast-search issue #73 (coupon lookup bulk rebuild)
relay-system/2026-06-27/kwfs-73-review-packet.md:11:## Diff (#73 commits 742df10 + 776d8a3, vs the pre-#73 commit 15a9e89)
relay-system/2026-06-27/kwfs-73-codex-qa.md:1:# RELAY · QA #73 coupon bulk rebuild (KISS-woo-fast-search)
relay-system/2026-06-27/kwfs-73-codex-qa.md:34:# QA Review Packet — KISS-woo-fast-search issue #73 (coupon lookup bulk rebuild)
relay-system/2026-06-27/kwfs-73-codex-qa.md:44:## Diff (#73 commits 742df10 + 776d8a3, vs the pre-#73 commit 15a9e89)
relay-system/2026-06-27/kwfs-73-codex-qa.md:1084:Verification: `php -l` clean; `bash tests/run.sh` → 27 passed / 1 failed (the 1 is the unrelated #75 human checkpoint). Thanks Codex — the silent-success-on-table-not-ready path was the exact failure class #73 set out to kill.

exec
/bin/zsh -lc "nl -ba relay-system/2026-07-01/lane-b-gh72-registry-lock.md | sed -n '1,220p'" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-97461-32007
 succeeded in 0ms:
     1	# RELAY · Lane B — GH-72 registry/projection write-lock (BUILD turn, codex)
     2	
     3	NEXT: codex
     4	STATUS: Open
     5	ROUND: 1 / 1
     6	
     7	## ▶ TAKE YOUR TURN — you are the BUILDER (codex). This is a BUILD turn, not a review.
     8	1. **Read this whole file.**
     9	2. **Implement the change below** by editing ONLY the allowed files. Do NOT edit any other file.
    10	3. **Append ONE short block** at the bottom (above the marker) noting what you changed, per file.
    11	4. Do NOT run git yourself; the harness commits your allowed files. Do NOT run the full `validate.sh`.
    12	
    13	## BUILD BRIEF (GH-72 — issue #72)
    14	
    15	**Problem:** `~/.config/xyz/registry.tsv` and the git-pulse projection are updated with an UNLOCKED
    16	read-modify-write (read into `"$reg.tmp.$$"`, then `mv` back). Two concurrent `xyz-vendor.sh` /
    17	`install.sh` operations on the same machine can interleave and lose a writer's row (last `mv` wins).
    18	
    19	**Task:** Add a small **per-user advisory lock** around each registry/projection read-modify-write so
    20	concurrent writers serialize instead of clobbering. Requirements:
    21	- Use a portable `mkdir`-based lock (atomic) beside the registry, e.g. `~/.config/xyz/registry.lock`
    22	  (resolve the same dir the registry uses — do NOT hardcode `$HOME` if the code already computes a
    23	  config dir). Acquire before the read, release (rmdir) after the `mv`, and on EXIT (trap) so a crash
    24	  can't deadlock.
    25	- **Fail-open:** if the lock can't be acquired within a short bounded wait (e.g. ~5s / a few retries),
    26	  reclaim a stale lock or proceed anyway with a warning — NEVER hard-fail the vendor/install on lock
    27	  contention. Match the fail-open spirit of the existing relay driver lock.
    28	- Keep the TSV schema and row format byte-identical. No behavior change when there is no contention.
    29	- Apply to BOTH registry writers and the projection writer.
    30	
    31	**Allowed files (edit ONLY these):**
    32	- `relay-automation/xyz-vendor.sh` (registry write ~L98-131)
    33	- `install.sh` (registry ~L144-183; git-pulse projection ~L112-140)
    34	
    35	**Acceptance (the harness/orchestrator will verify after):** concurrent writers never lose a row;
    36	lock is fail-open + stale-reclaiming; existing tests stay green. If a helper function is cleaner than
    37	inlining the lock in three places, define it once and call it (DRY).
    38	
    39	## Log
    40	
    41	### codex
    42	VERDICT: PASS
    43	Basis: Added per-file `mkdir` advisory locks around the two registry writers and the git-pulse projection writer, with stale-lock reclaim, bounded wait, EXIT cleanup, and fail-open warnings; verified the lock behavior with focused parse + concurrency checks, and the remaining `bash test/xyz-vendor.sh` failure is the pre-existing no-`.xyz` locator assertion, outside these lock edits.
    44	- `relay-automation/xyz-vendor.sh`: added a local `registry.lock` helper and wrapped the registry read-modify-write without changing the TSV row bytes.
    45	- `install.sh`: added the same helper pattern and wrapped both the install registry writer and the git-pulse projection writer so each temp-file `mv` happens under its per-file lock.
    46	- Verification: `bash -n relay-automation/xyz-vendor.sh`; `bash -n install.sh`; focused concurrency smoke passed (`2x ./install.sh` => 2 registry rows + 2 projection rows, stale lock reclaimed, live-holder contention fell back to warning + unlocked proceed).
    47	
    48	<!-- ↓↓↓ NEXT TURN goes here ↓↓↓ -->

exec
/bin/zsh -lc "nl -ba relay-system/2026-07-01/lane-a-gh73-tmp-log-docs.md | sed -n '1,140p'" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-97461-32007
 succeeded in 0ms:
     1	# RELAY · Lane A — GH-73 fixed-/tmp-log docs (BUILD turn, agy)
     2	
     3	NEXT: claude-a
     4	STATUS: Open
     5	ROUND: 1 / 1
     6	
     7	## ▶ TAKE YOUR TURN — you are the BUILDER (agy). This is a BUILD turn (doc edit), not a review.
     8	1. **Read this whole file.**
     9	2. **Make the doc change below** by editing ONLY the allowed files. Do NOT edit any other file.
    10	3. **Append ONE short block** at the bottom (above the marker) noting what you changed, per file.
    11	4. Do NOT run git yourself; the harness commits your allowed files. Do NOT run the full `validate.sh`.
    12	
    13	## BUILD BRIEF (GH-73 — issue #73)
    14	
    15	**Problem:** The turn shims already default their transcript logs to per-PID paths (`...-$$.log`,
    16	concurrency-safe). But the operator-facing DOCS pin FIXED log paths, which makes two concurrent
    17	same-machine runs write the same file and clobber each other's transcript.
    18	
    19	**Task:** In the docs below, make every transcript-log example concurrency-safe. For each occurrence of
    20	a fixed `CODEX_LOG`/`AGY_LOG` value like `"${TMPDIR:-/tmp}/codex-turn.log"` or `/tmp/agy-turn.log`:
    21	- EITHER change it to the per-PID form `"${TMPDIR:-/tmp}/codex-turn-$$.log"` /
    22	  `"${TMPDIR:-/tmp}/agy-turn-$$.log"`,
    23	- OR drop the explicit `CODEX_LOG=`/`AGY_LOG=` from the example entirely (the shims already default to
    24	  a unique per-PID path).
    25	Pick ONE approach and apply it consistently. Add a single short note near the first changed example
    26	that fixed log paths break concurrent same-machine runs (prefer the shims' per-PID default).
    27	Do NOT change any code or the shims — docs only. Keep all other prose intact.
    28	
    29	**Allowed files (edit ONLY these):**
    30	- `skills/relay-xyz/SKILL.md` (examples around the CODEX_LOG/AGY_LOG env, ~L113-116 and ~L136-157)
    31	- `relay-automation/README.md` (the `/tmp/codex-turn.log` / `/tmp/agy-turn.log` mentions, ~L212-300)
    32	
    33	**Acceptance:** no example in either file pins a fixed (non-`$$`) transcript path; prose otherwise
    34	unchanged; `skill-extract` / `path-integrity` gates stay green.
    35	
    36	## Log
    37	
    38	### Builder — agy — 2026-07-01
    39	- Edited `skills/relay-xyz/SKILL.md` to update all `CODEX_LOG` and `AGY_LOG` example values to use concurrency-safe per-PID paths (`...-$$.log`), and added a note warning that fixed log paths break concurrent same-machine runs.
    40	- Edited `relay-automation/README.md` to update all `/tmp/codex-turn.log` and `/tmp/agy-turn.log` example occurrences to their per-PID forms, and added a corresponding note warning that fixed log paths break concurrent same-machine runs.
    41	
    42	<!-- ↓↓↓ NEXT TURN goes here ↓↓↓ -->

codex
**ANSWER**

`#72` — **KEEP-OPEN.** The lock is not safe to declare fixed: both implementations have a real TOCTOU hole where a loser can delete a live lock before the winner writes `pid`, which means mutual exclusion can still fail under contention and the original “lose a row” bug can still happen. See [install.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-97461-32007/install.sh:131) lines 131-154 and [xyz-vendor.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-97461-32007/relay-automation/xyz-vendor.sh:106) lines 106-129.

`#73` — **CLOSE.** The docs now use per-PID transcript paths and match the shims’ existing per-PID defaults; I do not see a missed blocker in the referenced files. See [SKILL.md](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-97461-32007/skills/relay-xyz/SKILL.md:111), [SKILL.md](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-97461-32007/skills/relay-xyz/SKILL.md:115), [README.md](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-97461-32007/relay-automation/README.md:186), [README.md](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-97461-32007/relay-automation/README.md:213), plus the shim defaults at [codex-turn.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-97461-32007/relay-automation/codex-turn.sh:74) and [agy-turn.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-97461-32007/relay-automation/agy-turn.sh:114).

**FINDINGS**

`#72`
- [Blocker] The main race is real. After `mkdir "$lockdir"` succeeds, the winner writes `pid` in a separate step; a concurrent loser that sees the directory before `pid` exists gets `holder=""`, skips the live-holder check, and immediately runs the stale-reclaim `rm -rf "$lockdir"`. That defeats mutual exclusion in exactly the window the lock is supposed to protect. Evidence: [install.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-97461-32007/install.sh:131) lines 131-154 and [xyz-vendor.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-97461-32007/relay-automation/xyz-vendor.sh:106) lines 106-129. Concrete fix: do **not** reclaim on missing/empty `pid`; treat that state as “lock in progress/busy”, sleep and retry, and only reclaim when a non-empty recorded holder is confirmed dead. I would also record ownership before exposure and make release validate ownership before deleting.
- [Pass] Lock ordering is consistent, so I do not see a deadlock cycle. `install.sh` acquires `registry.lock`, then inside that path may acquire the projection lock via `publish_registry_projection`; I found no reverse projection→registry path. Evidence: [install.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-97461-32007/install.sh:221) lines 221-238, [install.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-97461-32007/install.sh:241) lines 241-247, [install.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-97461-32007/install.sh:285), and [xyz-vendor.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-97461-32007/relay-automation/xyz-vendor.sh:225).
- [Pass] Fail-open behavior is implemented as intended: if acquire fails, `run_with_advisory_lock` still executes the write path instead of aborting the install/vendor op. Evidence: [install.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-97461-32007/install.sh:165) lines 165-175 and [xyz-vendor.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-97461-32007/relay-automation/xyz-vendor.sh:140) lines 140-149.
- [Pass] Critical-section coverage is broad enough when the lock holds: the entire registry read-filter-append-`mv` is inside the wrapper in both scripts, and the entire projection temp-write-`mv` is inside its own wrapper. Evidence: [install.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-97461-32007/install.sh:199) lines 199-214, [install.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-97461-32007/install.sh:241) lines 241-256, [install.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-97461-32007/install.sh:237), [install.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-97461-32007/install.sh:285), and [xyz-vendor.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-97461-32007/relay-automation/xyz-vendor.sh:176) lines 176-190 plus [xyz-vendor.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-97461-32007/relay-automation/xyz-vendor.sh:225).
- [Should] Cleanup/release are unconditional `rm -rf` with no ownership check, so once the TOCTOU race has let another process steal/reacquire the same path, the original holder can later delete the new holder’s lock on normal release or EXIT cleanup. Evidence: [install.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-97461-32007/install.sh:87) lines 87-95 and [install.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-97461-32007/install.sh:158) lines 158-163; same pattern in [xyz-vendor.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-97461-32007/relay-automation/xyz-vendor.sh:59) lines 59-69 and [xyz-vendor.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-97461-32007/relay-automation/xyz-vendor.sh:133) lines 133-138.

`#73`
- [Pass] The referenced docs now use per-PID `-$$.log` forms in the operator-facing examples and explicitly warn that fixed paths break concurrent same-machine runs. Evidence: [SKILL.md](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-97461-32007/skills/relay-xyz/SKILL.md:111) lines 111-116, [SKILL.md](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-97461-32007/skills/relay-xyz/SKILL.md:136) lines 136-157, [README.md](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-97461-32007/relay-automation/README.md:186) and [README.md](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-97461-32007/relay-automation/README.md:213) lines 213-251 plus 285-301.
- [Pass] This matches existing code behavior rather than introducing a new convention: the shims already defaulted to per-PID logs. Evidence: [codex-turn.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-97461-32007/relay-automation/codex-turn.sh:74) and [agy-turn.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-97461-32007/relay-automation/agy-turn.sh:114).

**RECOMMENDATION**

Keep `#72` open until the empty-`pid` reclaim race is removed; close `#73` now.
tokens used
67,149
**ANSWER**

`#72` — **KEEP-OPEN.** The lock is not safe to declare fixed: both implementations have a real TOCTOU hole where a loser can delete a live lock before the winner writes `pid`, which means mutual exclusion can still fail under contention and the original “lose a row” bug can still happen. See [install.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-97461-32007/install.sh:131) lines 131-154 and [xyz-vendor.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-97461-32007/relay-automation/xyz-vendor.sh:106) lines 106-129.

`#73` — **CLOSE.** The docs now use per-PID transcript paths and match the shims’ existing per-PID defaults; I do not see a missed blocker in the referenced files. See [SKILL.md](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-97461-32007/skills/relay-xyz/SKILL.md:111), [SKILL.md](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-97461-32007/skills/relay-xyz/SKILL.md:115), [README.md](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-97461-32007/relay-automation/README.md:186), [README.md](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-97461-32007/relay-automation/README.md:213), plus the shim defaults at [codex-turn.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-97461-32007/relay-automation/codex-turn.sh:74) and [agy-turn.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-97461-32007/relay-automation/agy-turn.sh:114).

**FINDINGS**

`#72`
- [Blocker] The main race is real. After `mkdir "$lockdir"` succeeds, the winner writes `pid` in a separate step; a concurrent loser that sees the directory before `pid` exists gets `holder=""`, skips the live-holder check, and immediately runs the stale-reclaim `rm -rf "$lockdir"`. That defeats mutual exclusion in exactly the window the lock is supposed to protect. Evidence: [install.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-97461-32007/install.sh:131) lines 131-154 and [xyz-vendor.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-97461-32007/relay-automation/xyz-vendor.sh:106) lines 106-129. Concrete fix: do **not** reclaim on missing/empty `pid`; treat that state as “lock in progress/busy”, sleep and retry, and only reclaim when a non-empty recorded holder is confirmed dead. I would also record ownership before exposure and make release validate ownership before deleting.
- [Pass] Lock ordering is consistent, so I do not see a deadlock cycle. `install.sh` acquires `registry.lock`, then inside that path may acquire the projection lock via `publish_registry_projection`; I found no reverse projection→registry path. Evidence: [install.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-97461-32007/install.sh:221) lines 221-238, [install.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-97461-32007/install.sh:241) lines 241-247, [install.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-97461-32007/install.sh:285), and [xyz-vendor.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-97461-32007/relay-automation/xyz-vendor.sh:225).
- [Pass] Fail-open behavior is implemented as intended: if acquire fails, `run_with_advisory_lock` still executes the write path instead of aborting the install/vendor op. Evidence: [install.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-97461-32007/install.sh:165) lines 165-175 and [xyz-vendor.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-97461-32007/relay-automation/xyz-vendor.sh:140) lines 140-149.
- [Pass] Critical-section coverage is broad enough when the lock holds: the entire registry read-filter-append-`mv` is inside the wrapper in both scripts, and the entire projection temp-write-`mv` is inside its own wrapper. Evidence: [install.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-97461-32007/install.sh:199) lines 199-214, [install.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-97461-32007/install.sh:241) lines 241-256, [install.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-97461-32007/install.sh:237), [install.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-97461-32007/install.sh:285), and [xyz-vendor.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-97461-32007/relay-automation/xyz-vendor.sh:176) lines 176-190 plus [xyz-vendor.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-97461-32007/relay-automation/xyz-vendor.sh:225).
- [Should] Cleanup/release are unconditional `rm -rf` with no ownership check, so once the TOCTOU race has let another process steal/reacquire the same path, the original holder can later delete the new holder’s lock on normal release or EXIT cleanup. Evidence: [install.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-97461-32007/install.sh:87) lines 87-95 and [install.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-97461-32007/install.sh:158) lines 158-163; same pattern in [xyz-vendor.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-97461-32007/relay-automation/xyz-vendor.sh:59) lines 59-69 and [xyz-vendor.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-97461-32007/relay-automation/xyz-vendor.sh:133) lines 133-138.

`#73`
- [Pass] The referenced docs now use per-PID `-$$.log` forms in the operator-facing examples and explicitly warn that fixed paths break concurrent same-machine runs. Evidence: [SKILL.md](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-97461-32007/skills/relay-xyz/SKILL.md:111) lines 111-116, [SKILL.md](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-97461-32007/skills/relay-xyz/SKILL.md:136) lines 136-157, [README.md](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-97461-32007/relay-automation/README.md:186) and [README.md](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-97461-32007/relay-automation/README.md:213) lines 213-251 plus 285-301.
- [Pass] This matches existing code behavior rather than introducing a new convention: the shims already defaulted to per-PID logs. Evidence: [codex-turn.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-97461-32007/relay-automation/codex-turn.sh:74) and [agy-turn.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-97461-32007/relay-automation/agy-turn.sh:114).

**RECOMMENDATION**

Keep `#72` open until the empty-`pid` reclaim race is removed; close `#73` now.
