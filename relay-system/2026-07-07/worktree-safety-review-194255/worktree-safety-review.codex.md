Reading additional input from stdin...
OpenAI Codex v0.139.0
--------
workdir: /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-48652-24158
model: gpt-5.4
provider: openai
approval: never
sandbox: read-only
reasoning effort: high
reasoning summaries: none
session id: 019f3f9b-6413-7b20-94d4-04f1b0a6c5e8
--------
user
You are an INDEPENDENT advisor in a one-shot cross-model consult. Another model is answering the SAME question separately and a coordinator will reconcile both answers, so give your own honest, specific read — do not hedge toward a consensus you cannot see. Read any repo files the question references (cite file:line). Respond with: (1) a short direct ANSWER; (2) graded FINDINGS — [Blocker]/[Should]/[Nit]/[Pass] — where applicable; (3) a one-line RECOMMENDATION. You are ADVISORY ONLY: output your analysis as text; do not rely on writing files (you are running in a throwaway copy).

=== CONSULT QUESTION ===
Review `WORKTREE-SAFETY.md` at the repo root (the git worktree safety anti-patterns guide referenced from `AGENTS.md` line 3: "Read `WORKTREE-SAFETY.md` for important Git Worktree Dangerous actions to avoid.").

Context: this doc was written after a real incident (tracked as GH-177) where this repo's main `.git` directory got destructively gutted — `HEAD`, `objects/`, `refs/`, and `index` were all lost, while `.git/hooks/`, `.git/worktrees/`, and `.git/config` survived. It had to be recovered via Time Machine restore (which brought back the working-tree files) plus `git init` (to refill the missing skeleton) plus `git fetch origin` (to repopulate history from GitHub). A stale `.git/worktrees/<name>/` metadata stub (just a `commondir` file, no valid gitdir) was also found and pruned.

Please review the document and answer:

1. **Technical accuracy** — are the git commands and their claimed behavior actually correct? Specifically check:
   - `git worktree prune` semantics
   - `git worktree move` (version availability, behavior)
   - `git gc --aggressive --prune=now` interaction with worktrees and shared object stores
   - Where stashes actually live per-worktree (`.git/worktrees/<name>/...`) vs the claim in the doc
   - The `git branch -D` on a branch checked out in another worktree — does it actually succeed, and does it really leave that worktree in detached HEAD as claimed?
   - Any other command whose described behavior might be wrong, outdated, or version-dependent

2. **Gap relative to the actual incident** — the doc's 10 anti-patterns are about worktree *directory* management (rm -rf on a worktree, moving it, GC, branch deletion, stashes). None of them describe the failure mode that actually happened: the *main* repo's `.git` losing `HEAD`/`objects`/`refs`/`index` while `hooks/`/`worktrees/`/`config` survived (a partial/selective backup-restore corruption, not a `rm -rf .git` in the classic sense the doc describes in section 7). Is anything missing that would have helped an agent or script either (a) prevent this exact failure mode, or (b) diagnose it faster / recover it correctly? Should the doc add a section on "how to detect and repair a partially-corrupted `.git` directory" (e.g., a Golden-Rule-style checklist: verify HEAD/objects/refs/index all exist before trusting a repo; how `git init` is safe to re-run on an existing repo without clobbering config/hooks; when it's safe to `git fetch` + reconstruct refs vs when you need to be more careful about diverging local work)?

3. **Missing footguns** — are there other common git-worktree footguns (that agents/scripts driving worktrees would hit) not covered by the current 10, worth adding?

Give a prioritized list of concrete edits (additions/corrections) to `WORKTREE-SAFETY.md`, not just general commentary.
hook: SessionStart
hook: SessionStart Completed
codex
Reviewing `WORKTREE-SAFETY.md` against the actual git behavior and the GH-177 failure mode. I’m reading the repo’s routing docs first, then the safety doc itself with line numbers so the findings can point to exact claims.
exec
/bin/zsh -lc 'nl -ba ROUTER.md' in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-48652-24158
exec
/bin/zsh -lc 'nl -ba WORKTREE-SAFETY.md' in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-48652-24158
exec
/bin/zsh -lc 'nl -ba AGENTS.md' in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-48652-24158
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
    14	- `PROJECT/CONSTITUTION.md` = the policy of record: PDDA's lane and its non-negotiables (deterministic-before-LLM, verified-success-only, reversibility, local-first)
    15	- `PROJECT/DO-NOT-BUILD.md` = the anti-scope list — product directions PDDA must not become (companion to `CONSTITUTION.md`)
    16	
    17	## Startup sequence
    18	
    19	1. Read `ROUTER.md` to understand the repo's operating order and canonical files. -> expect one clear next file, not a repo-wide scavenger hunt.
    20	2. Read `AGENTS.md` before making recommendations or edits. -> expect explicit assumptions, a reversibility read on consequential changes, and verified claims only.
    21	3. Read `ROADMAP.md` to find the active effort or parked intake. -> expect links outward to the canonical `PROJECT/**` docs; `ROADMAP.md` is a pointer ledger, not a plan body.
    22	4. Read the linked `PROJECT/**` document that owns the work you are touching. -> expect the near-top `## Status` table to tell you what was just completed and what is next.
    23	5. If the task touches project docs, read `PROJECT/PDDA.md` and follow the PDDA contract. -> expect `PROJECT/2-WORKING` docs to have frontmatter, the exact status table, and QA gates when phased.
    24	6. Before reporting success on code or runtime work, run `./validate.sh`. -> expect the suite to stay green; do not claim completion if it fails or was skipped.
    25	7. Before reporting success on doc-hygiene or roadmap work, run `utils/pdda/pdda.sh run` (or the relevant `utils/pdda/pdda.sh <check>` subcommand). -> expect deterministic findings first, then any LLM review.
    26	
    27	## Canonical rules
    28	
    29	- Do not put phase checklists, build steps, or deep execution notes in `ROADMAP.md`.
    30	- Every active doc in `PROJECT/2-WORKING/` must be reflected by a pointer in `ROADMAP.md` — a one-line ledger entry that links it. A working doc that should not appear opts out with `roadmap_exempt: true` in its frontmatter. Enforced by `utils/pdda/pdda.sh roadmap-coverage`; governance lives in `PROJECT/PDDA.md` → "ROADMAP.md contract".
    31	- Every captured GitHub issue doc in `PROJECT/1-INBOX/GH-*.md` must also be parked in `ROADMAP.md` as a one-line queue entry immediately at intake, then promoted or removed later. Enforced by `utils/pdda/pdda.sh roadmap-coverage`; governance lives in `PROJECT/PDDA.md` → "GitHub issue intake" + "ROADMAP.md contract".
    32	- Do not create a second competing plan when a canonical `PROJECT/**` doc already exists.
    33	- Issue-first: any change beyond a **2–3 line** fix opens a GitHub issue first, then a pointer doc **named after the issue** (`GH-<number>-VERY-SHORT-DESC.md`, e.g. `GH-1234-SHOWME-COMMAND.md`), and that capture is **parked in `ROADMAP.md` immediately** before execution begins. The issue is the signal stream; the pointer doc is the execution surface of record. Genuinely trivial edits (≤2–3 line fixes, typos, path repoints, doc-only one-liners) are exempt. Governed by `PROJECT/PDDA.md` → "GitHub issue intake".
    34	- Do not override deterministic PDDA findings with prose.
    35	- Do not report a win you did not verify with the relevant script or test.
    36	- Update `CHANGELOG.md` at the end of each iteration; its governance lives in `PROJECT/PDDA.md` — do not re-specify CHANGELOG rules in `AGENTS.md` or elsewhere.
    37	
    38	## Command rails
    39	
    40	For repo correctness:
    41	
    42	```bash
    43	./validate.sh
    44	```
    45	
    46	For document hygiene:
    47	
    48	```bash
    49	utils/pdda/pdda.sh run
    50	```
    51	
    52	For targeted PDDA debugging (subcommands of the single dispatcher):
    53	
    54	```bash
    55	utils/pdda/pdda.sh frontmatter
    56	utils/pdda/pdda.sh status-table
    57	utils/pdda/pdda.sh hardcoded-paths
    58	utils/pdda/pdda.sh roadmap
    59	utils/pdda/pdda.sh roadmap-coverage
    60	utils/pdda/pdda.sh changelog
    61	utils/pdda/pdda.sh stale
    62	utils/pdda/pdda.sh issue-doc-sync   # warn-only: flags 2-WORKING/GH-*.md docs drifted from their GitHub issue state
    63	utils/pdda/pdda.sh doc-ready        # LLM readiness review — set PDDA_LLM_BIN (codex/claude/agy) for recommendations, else it self-skips
    64	```
    65	
    66	## Routing hints
    67	
    68	- If the task is about current priorities or active work, start in `ROADMAP.md`, then follow the linked `PROJECT/**` doc.
    69	- If the task is about fresh GitHub intake or duplicate-prevention, start in `ROADMAP.md`'s queue, then follow the linked `PROJECT/1-INBOX/GH-*.md` capture doc.
    70	- If the task is about document quality, active-doc lifecycle, roadmap sprawl, or automation policy, start in `PROJECT/PDDA.md`.
    71	- If the task is about the CHANGELOG, provenance, or end-of-iteration logging, the governance is in `PROJECT/PDDA.md` (the "CHANGELOG.md — end-of-iteration record" contract).
    72	- If the task is about the `tick` runtime, event projection, or multi-agent coordination kernel, start in `README.md`, then `bin/`, `src/`, `test/`, and the active project doc.
    73	- If the task is about the **Aider ↔ OpenRouter** turn-taker lane (`relay-automation/aider-turn.sh` — an OpenAI-standard build lane discrete from Codex; `AIDER_MODEL`/`OPENROUTER_API_KEY`, `--builder aider`), start in `PROJECT/3-COMPLETED/GH-77-AIDER-OPENROUTER-LANE.md`. The shim owns the tick token ops (Aider can't run shell mid-turn), asserts token ownership before launching Aider, and runs Aider `--no-auto-commits` (the harness commits).
    74	- If the task is about running, driving, or reviewing via the relay (`relay-automation/` — `relay-drive.sh`, `poll.sh`, the turn shims, `marathon*.sh`), **invoke the `relay-xyz` skill first — do not improvise the handoff or hand-roll a harness from `ls relay-automation/`.** The skill owns the locator, sandbox rules, exit codes, and the safety boundary; a `PreToolUse` guard (`relay-automation/hooks/relay-xyz-guard.sh`) blocks driving a harness driver before the skill is loaded. For the two live-Claude-windows, same-machine duel recipe (Reporter↔Maintainer with a human go-gate), the copy-paste form is [relay-automation/DUELING-CLAUDES.md](relay-automation/DUELING-CLAUDES.md).
    75	- If the task is about relay session telemetry, the `focus5float` health feed, or extraction scripts under `utils/telemetry/`, start in `PROJECT/1-INBOX/GH-24-RELAY-TELEMETRY-EXTRACTOR.md`.
    76	- If the task is about live per-session completion telemetry — the `XYZ.json` log every relay/marathon/swarm session appends to at the harness repo root (schema: `harness`/`sessionId`/`health`/`title`/`description`/`updatedAt`), the shared writer `utils/telemetry/append-xyz-completion.sh`, or the shared health mapping `utils/telemetry/health-lib.sh` — start in `PROJECT/1-INBOX/GH-75-XYZ-JSON-COMPLETION-TELEMETRY.md`. `XYZ.json` is local + gitignored (machine-specific).
    77	- If the task is about a proposed roadmap-steward agent, start here, then read `PROJECT/PDDA.md` and its `Proposed roadmap steward extension` section.
    78	- Issue-first SOP: any change beyond a 2–3 line fix (and every project plan) opens a GitHub issue *first*, then gets a pointer doc named after the issue at `PROJECT/1-INBOX/GH-<number>-VERY-SHORT-DESC.md` — e.g. `GH-1234-SHOWME-COMMAND.md` — and that capture is parked in the `ROADMAP.md` queue immediately (format + lifecycle owned by `PROJECT/PDDA.md` → "GitHub issue intake"), following the normal `1-INBOX` → `2-WORKING` flow. Genuinely trivial edits (≤2–3 line fixes, typos, path repoints, doc-only one-liners) are exempt and commit directly.

 succeeded in 0ms:
     1	# Git Worktree Safety Guide for Agents
     2	
     3	> **Purpose:** Prevent destructive footguns when scripting with Git worktrees.  
     4	> **Scope:** Shell scripts, CI pipelines, and agent workflows that create, manage, or clean up worktrees.
     5	
     6	---
     7	
     8	## 1. The "rm -rf worktree path" trap
     9	
    10	**Anti-pattern:** Deleting a worktree by just removing its directory.
    11	
    12	```bash
    13	# WRONG — leaves stale metadata in .git/worktrees/
    14	rm -rf ../feature-branch
    15	
    16	# Also WRONG — git still thinks the worktree exists
    17	git worktree remove ../feature-branch  # fails: "not a working tree"
    18	```
    19	
    20	**Why it's dangerous:** Git maintains metadata in `.git/worktrees/<name>/` and in a `.git` file inside the worktree. If you `rm -rf` the directory, you get:
    21	- Orphaned metadata polluting your repo
    22	- The branch may still be checked out according to git, blocking operations
    23	- `.git/worktrees/<name>/index` can grow large and never gets cleaned
    24	
    25	**Correct approach:**
    26	```bash
    27	# Always use git worktree remove
    28	git worktree remove ../feature-branch
    29	
    30	# If already nuked, clean up manually
    31	git worktree prune
    32	# Or more aggressively:
    33	rm -rf .git/worktrees/feature-branch
    34	```
    35	
    36	---
    37	
    38	## 2. Scripting `git worktree add` without failure handling
    39	
    40	**Anti-pattern:** Assuming `git worktree add` succeeds.
    41	
    42	```bash
    43	git worktree add ../hotfix hotfix-branch
    44	cd ../hotfix || exit 1
    45	# ... do work ...
    46	```
    47	
    48	**Why it's dangerous:**
    49	- Branch might already be checked out in another worktree (git refuses with "already checked out")
    50	- Path might already exist
    51	- Disk might be full
    52	- Detached HEAD might not be what you expected
    53	
    54	**Defensive version:**
    55	```bash
    56	if ! git worktree add ../hotfix hotfix-branch 2>/dev/null; then
    57	    echo "Worktree creation failed — branch may already be checked out or path exists" >&2
    58	    exit 1
    59	fi
    60	```
    61	
    62	---
    63	
    64	## 3. Trap cleaning worktrees with `rm -rf` and relative paths
    65	
    66	**Anti-pattern:** The sibling of the `mktemp` bug — cleaning worktrees in traps.
    67	
    68	```bash
    69	WORKTREE="../feature-$(date +%s)"
    70	git worktree add "$WORKTREE" feature-branch
    71	trap 'rm -rf "$WORKTREE"' EXIT
    72	```
    73	
    74	**Why it's dangerous:**
    75	- If `git worktree add` fails and `WORKTREE` is empty/malformed, `rm -rf ""` resolves to cwd (same `cd ""` bug)
    76	- If the script `cd`s into the worktree, the relative path `../` now points somewhere else
    77	- `rm -rf` leaves stale metadata in `.git/worktrees/`
    78	
    79	**Defensive version:**
    80	```bash
    81	WORKTREE="$(git worktree add --quiet ../feature-XXXX feature-branch 2>&1 | awk '{print $NF}' | head -1)"
    82	[ -d "$WORKTREE" ] || { echo "Worktree creation failed" >&2; exit 1; }
    83	WORKTREE="$(cd "$WORKTREE" && pwd -P)"  # canonicalize AFTER validation
    84	
    85	cleanup() {
    86	    git worktree remove --force "$WORKTREE" 2>/dev/null || true
    87	    git worktree prune 2>/dev/null || true
    88	}
    89	trap cleanup EXIT
    90	```
    91	
    92	---
    93	
    94	## 4. Moving/renaming worktree directories outside of git
    95	
    96	**Anti-pattern:** Using `mv` to relocate a worktree.
    97	
    98	```bash
    99	mv ../feature-branch ../feature-branch-old
   100	```
   101	
   102	**Why it's dangerous:** The `.git` file inside the worktree contains an absolute or relative path back to the main repo. Moving it breaks that link. Git now can't find the worktree, and `git worktree remove` fails.
   103	
   104	**Correct approach:**
   105	```bash
   106	# Git 2.34+ supports moving
   107	git worktree move ../feature-branch ../feature-branch-renamed
   108	
   109	# Older versions: remove and re-add
   110	git worktree remove ../feature-branch
   111	git worktree add ../feature-branch-renamed feature-branch
   112	```
   113	
   114	---
   115	
   116	## 5. Assuming `main` (or any shared branch) is free for checkout
   117	
   118	**Anti-pattern:** `git worktree add` for a branch that's already checked out elsewhere.
   119	
   120	```bash
   121	# Script adds a worktree for "main" to run tests
   122	git worktree add ../main-worktree main
   123	```
   124	
   125	**Why it's dangerous:** If any other worktree already has `main` checked out, this fails. This is especially problematic in CI or multi-session environments.
   126	
   127	**Defensive version:**
   128	```bash
   129	# Use a unique branch name or detached HEAD
   130	git worktree add --detach ../test-run-$$ main
   131	
   132	# Or check first
   133	if git worktree list | grep -q '\[main\]'; then
   134	    echo "main is already checked out in another worktree" >&2
   135	    exit 1
   136	fi
   137	```
   138	
   139	---
   140	
   141	## 6. Garbage collection while worktrees exist
   142	
   143	**Anti-pattern:** Running aggressive GC without considering worktrees.
   144	
   145	```bash
   146	git gc --aggressive --prune=now
   147	```
   148	
   149	**Why it's dangerous:**
   150	- Worktrees share the same object database as the main repo
   151	- If a worktree has locally-created objects (stashes, unreachable commits, blob cache), GC can delete objects another worktree needs
   152	- `git gc` only considers refs from the worktree it's run in, but objects might be reachable from another worktree's refs
   153	
   154	**Defensive approach:**
   155	```bash
   156	# Always list worktrees before GC to understand what's shared
   157	git worktree list
   158	
   159	# Safer: run gc from the main worktree with all refs visible
   160	# Or avoid --prune=now when worktrees exist
   161	git gc --auto  # conservative, safe
   162	```
   163	
   164	---
   165	
   166	## 7. Deleting the main worktree's `.git` directory
   167	
   168	**Anti-pattern:** Treating the main `.git` directory as just another git database.
   169	
   170	```bash
   171	# Thinking you're cleaning up an old clone
   172	rm -rf .git
   173	```
   174	
   175	**Why it's dangerous:** All linked worktrees reference the main repo's object database via their `.git` files. Deleting the main `.git` irrecoverably breaks every linked worktree.
   176	
   177	**Real-world scenario:** You have 3 worktrees off a main checkout. Someone decides to "clean up" by deleting the main checkout folder. Now all 3 worktrees are orphaned with no object database, and even `git log` fails.
   178	
   179	**Precaution:**
   180	```bash
   181	# Before removing any repo, check if it's the primary for worktrees
   182	git worktree list
   183	# If other worktrees reference this one's objects, don't delete .git
   184	```
   185	
   186	---
   187	
   188	## 8. Scripts that `cd` into a worktree then use relative paths back
   189	
   190	**Anti-pattern:**
   191	```bash
   192	cd ../feature-branch
   193	# ... do stuff ...
   194	../../main-repo/some-script.sh  # fragile relative path
   195	```
   196	
   197	**Why it's dangerous:** The worktree is a separate directory. Your relative path `../../` assumes a specific directory layout that may not hold (the worktree could be anywhere on disk, not necessarily a sibling).
   198	
   199	**Defensive approach:**
   200	```bash
   201	MAIN_REPO="$(git rev-parse --git-common-dir)"  # finds the shared .git
   202	MAIN_ROOT="$(cd "$MAIN_REPO/.." && pwd)"        # parent of shared .git
   203	```
   204	
   205	---
   206	
   207	## 9. Branch deletion without checking worktree occupancy
   208	
   209	**Anti-pattern:** Deleting a branch that's checked out in a worktree.
   210	
   211	```bash
   212	git branch -d feature-branch  # fails if checked out elsewhere
   213	git branch -D feature-branch  # force-deletes, leaves worktree in detached HEAD
   214	```
   215	
   216	**Why it's dangerous:** Force-deleting the branch leaves the worktree in a detached HEAD state. The developer working there suddenly has no branch, and their next `git push` will fail or push to an unexpected ref. Their work is still there (in the working tree and reflog) but panic often ensues.
   217	
   218	**Check first:**
   219	```bash
   220	if git worktree list | grep -q 'feature-branch'; then
   221	    echo "Branch is checked out in a worktree — aborting deletion" >&2
   222	    exit 1
   223	fi
   224	```
   225	
   226	---
   227	
   228	## 10. `git stash` in a worktree and expecting it to appear in another
   229	
   230	**Anti-pattern:** Assuming stashes are shared across worktrees.
   231	
   232	```bash
   233	# In worktree A
   234	git stash push -m "WIP: half-done feature"
   235	
   236	# In worktree B
   237	git stash pop  # NOPE, stashes are per-worktree!
   238	```
   239	
   240	**Why it's dangerous:** Stashes are stored in the worktree's own refs (`.git/worktrees/<name>/refs/stash`), not in the shared refs. Popping in the wrong worktree gets you a different stash or nothing.
   241	
   242	**Correct mental model:** Stashes are worktree-local. Use `git stash list` in each worktree to see what's actually there.
   243	
   244	---
   245	
   246	## Golden Rules for Worktree Safety
   247	
   248	1. **Always use `git worktree remove`, never `rm -rf`** on a worktree directory
   249	2. **Validate before destroying** — check that paths are non-empty, real directories, and not repo roots before any destructive operation
   250	3. **Be path-aware in traps** — canonicalize paths early, validate them, and never `rm -rf` on relative paths or unvalidated variables
   251	4. **The main repo's `.git` is the single source of truth** — protect it like a database, because it is one
   252	5. **Worktrees share objects, not refs/logs/stashes** — understand what's shared and what's isolated before scripting
   253	
   254	---
   255	
   256	## See Also
   257	
   258	- [Git Worktree Documentation](https://git-scm.com/docs/git-worktree)
   259	- Related: [Temp Directory Safety Guide](./temp-dir-safety.md) — for the `mktemp` failure mode that can cascade into worktree destruction

 succeeded in 0ms:
     1	# AGENTS.md
     2	
     3	Read `WORKTREE-SAFETY.md` for important Git Worktree Dangerous actions to avoid.
     4	
     5	Read `ROUTER.md` first for startup order and canonical files.
     6	
     7	Read `GUIDING-PRINCIPLES.md` for the product north stars.
     8	
     9	Read `PROJECT/PDDA.md` when the task touches project docs, `ROADMAP.md`, or `CHANGELOG.md`.
    10	
    11	## What this file owns
    12	
    13	This file is the behavioral playbook for work in this repo: decision quality, reversibility, blast
    14	radius, planning shape, and proof.
    15	
    16	Do not restate routing, roadmap, changelog, or active-doc contracts here. Those live in
    17	`ROUTER.md` and `PROJECT/PDDA.md`.
    18	
    19	## Operating principles
    20	
    21	### 1. Lead with the line that survives skimming
    22	
    23	Your first sentence gives the verdict, current state, or call. No setup first.
    24	
    25	### 2. Make the bet explicit before acting
    26	
    27	State the assumption, tradeoff, and failure mode that matter before you commit to a path. If a future
    28	reader could not say "that assumption was wrong," you have not made the real bet legible yet.
    29	
    30	### 3. Use one reversibility scale
    31	
    32	Consequential changes get a read on the shared scale: **Easy / Costly / One-way door**, with one line
    33	of why. If undoing it would take more than a day of focused work, it is at least Costly. Costly
    34	changes need a rollback path. One-way doors need explicit confirmation before proceeding.
    35	
    36	### 4. Size the blast radius before changing shared surfaces
    37	
    38	Before a refactor, schema change, dependency bump, coordination-kernel change, or relay-containment
    39	change, say what ripples, what might break, and who notices. A change you cannot size is not ready.
    40	
    41	### 5. One plan, one ordered list
    42	
    43	When you give executable steps, put them in one numbered list in execution order. Keep verification
    44	inline (`-> expect ...`). Do not scatter action items across prose.
    45	
    46	### 6. Verified beats plausible
    47	
    48	Do not claim success without the relevant test, script, or observable proof. If verification was
    49	skipped or failed, say that plainly and include the result.
    50	
    51	### 7. Record only consequential bets
    52	
    53	If a change is Costly, One-way door, or assumption-heavy, record the bet in `CHANGELOG.md` per
    54	`PROJECT/PDDA.md`. Below that threshold, skip the ritual.
    55	
    56	### 8. Stay quiet on trivial work
    57	
    58	Most edits are small and reversible. Do not manufacture ceremony for a rename, typo fix, or other
    59	local change.
    60	
    61	## Repo-specific rails
    62	
    63	- `ROUTER.md` owns startup order, canonical files, command rails, and the issue-first SOP.
    64	- `GUIDING-PRINCIPLES.md` owns the product/runtime priorities: local event-log coordination,
    65	  containment, skill-first relay work, durable fixes, and verified done.
    66	- `PROJECT/PDDA.md` owns doc lifecycle, `ROADMAP.md` pointer-ledger rules, and `CHANGELOG.md`
    67	  governance.
    68	- `validate.sh` is the code/runtime gate. `utils/pdda/pdda.sh run` and its targeted
    69	  `utils/pdda/pdda.sh <check>` subcommands are the doc-hygiene gates.
    70	- **HQ (multi-repo command center)** — for cross-repo tasking (resolve a project → land intake on its
    71	  own PDDA rails → prepare dispatch), drive `utils/hq/hq.sh` via the `/hq` skill rather than hand-editing
    72	  another repo's docs. Full command surface (`status`/`resolve`/`next`/`park`/`promote`/`queue`/`fire`),
    73	  install, and the resolution ladder are in [README.md → HQ — multi-repo command center](README.md#hq--multi-repo-command-center); agent-facing invocation flow + guardrails live in [skills/hq/SKILL.md](skills/hq/SKILL.md). Write paths preview by default; `fire` never drives the harness.
    74	- Changes to `.tick/events/`, `src/project.js`, relay containment, or event/verb shape are usually
    75	  broader than they look. Treat them as at least Costly until proven otherwise.
    76	- **Commit to the QUEUE; re-anchor, don't rabbit-hole (GH-45).** A wave's committed lane list *is* the
    77	  active commitment — after each lane attempt, re-read it before acting further. A driven lane that
    78	  fails **parks** after `LANE_MAX_ATTEMPTS` (default 2): the driver (`marathon-drive.sh` /
    79	  `relay-drive.sh`) refuses to re-fire it (exit 8, no token), you capture the findings as an issue and
    80	  stop. Re-firing a parked lane or going off-wave to deep-dive one item requires an explicit operator
    81	  override (`--force`) or a replan note — never a quiet slide off the plan.
    82	- **Do not create new git branches** automatically. Only create a new branch if explicitly requested by the user.
    83	- **Aider Configuration (AIDER.md / GH-77)**: When using Aider as a headless runner against OpenRouter, do not hardcode the API key or attempt to use a secrets manager. The `OPENROUTER_API_KEY` is securely stored at `/Users/noelsaw/secrets/openrouter/openrouter.txt` and is exported dynamically by `~/.zshrc`.
    84	- **Aider edit-format compat for OpenRouter models (GH-118)**: many OpenRouter-proxied models
    85	  (confirmed: GLM-5.2, Nemotron Ultra 3) default to Aider's `whole` edit format and fail to emit
    86	  parseable edits, stalling the turn. Fix is `AIDER_FLAGS=--edit-format diff` (existing passthrough
    87	  in `aider-turn.sh`) — see `relay-automation/README.md`'s "Known OpenRouter edit-format quirks"
    88	  section before adding a new OpenRouter model to a driven lane.
    89	
    90	## Conflict order
    91	
    92	1. The current user request
    93	2. The canonical doc that owns the surface you are touching (`ROUTER.md`, `GUIDING-PRINCIPLES.md`,
    94	   `PROJECT/PDDA.md`, or the active `PROJECT/**` doc)
    95	3. This file
    96	4. Skill defaults

web search: 
web search: site:git-scm.com/docs git worktree prune move gc stash worktree refs stash refs/worktree official docs
web search: 
web search: https://git-scm.com/docs/git-worktree
web search: 
web search: 'prune' in https://git-scm.com/docs/git-worktree
web search: 
web search: 'main worktree' in https://git-scm.com/docs/git-worktree
web search: 
web search: https://git-scm.com/docs/git-gc
web search: 
web search: site:git-scm.com/docs git worktree move introduced 2.17
web search: 
web search: https://git-scm.com/docs/git-worktree/2.17.0
web search: 
web search: 'git worktree move' in https://git-scm.com/docs/git-worktree/2.16.6
codex
The main factual checks are in progress now. I’ve already found one concrete mismatch: the doc says `git worktree move` is “Git 2.34+”, but the official manual shows it present in Git 2.17.0 and absent in 2.16.6, so that claim is materially too new.
exec
/bin/zsh -lc 'nl -ba GUIDING-PRINCIPLES.md' in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-48652-24158
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
    52	## Conventions
    53	
    54	### Strict-mode policy (bash `set -e`)
    55	
    56	Strict mode is **per-subsystem, not repo-wide** (GH-110 P3b). The split is deliberate:
    57	
    58	- **`relay-automation/` drivers and turn shims run `set -euo pipefail`.** They orchestrate risky,
    59	  multi-step, containment-sensitive turns where a silently-ignored failure can commit off-lane or
    60	  orphan a peer. Abort-on-error (`-e`) is the correct default there.
    61	- **`utils/` analysis tools (`pdda/*`, `marathon-plan.sh`, `swarm-preflight.sh`) run `set -uo pipefail`
    62	  or `set -u`, deliberately *without* `-e`.** These are long single-pass scripts whose normal control
    63	  flow includes many expected-nonzero probes (`git rev-parse`, `gh` lookups, `grep` misses). Under
    64	  `-e` a benign "no match" would abort the whole run, so they set `-u` (catch unset vars) + explicit
    65	  per-call error handling instead. This is an exemption, not an oversight.
    66	
    67	Every currently `-e`-exempt script carries a one-line `# strict-mode: -e exempt — …` header next to
    68	its `set -` line so the exemption is self-documenting. New scripts default to `set -euo pipefail`
    69	unless they fit the analysis-tool profile above, in which case they add the exemption header.
    70	
    71	---
    72	
    73	## Appendix: AI Doc Review Heuristics
    74	
    75	When reviewing any repo doc (roadmap entries, plans, architecture notes, audits, task writeups), apply these. Priority: containment > coordination correctness > signal quality > implementation speed and operator friction.
    76	
    77	**Heuristics**
    78	
    79	1. **Containment preserved?** Any headless path that could self-commit, touch off-allowlist files, or orphan a peer commit without an explicit containment argument → reject or escalate.
    80	2. **Skill-first respected?** Any plan that bypasses `relay-xyz` or improvises the harness from scratch without the skill layer → reject. Add to the skill instead.
    81	3. **Coordination through the event log?** Reads/writes to shared state route through `tick` verbs; hard-coded state outside `.tick/` needs explicit justification.
    82	4. **Done verifiable?** Names runnable gates (`validate.sh`, specific tests, `utils/pdda/pdda.sh run`). None = low-quality signal.
    83	5. **Drift reduced, not created?** No duplicated docs, no execution detail in ROADMAP.md, no reinventing a path the event-log contract already documents.
    84	6. **Next action singular?** One explicit next step, not buried in prose; status cells non-empty.
    85	7. **Operator control explicit?** No silent retry, no auto-repair outside the bounded exit-code menu, no masked failure; destructive ops surface before executing.
    86	8. **Four pillars pass?** Each turn/output is Attested, Relevant, Fresh, Structured. Fail one → not done.
    87	
    88	**Tie-breakers**
    89	
    90	- **Containment vs speed:** choose containment; flag friction as a design question, not a shortcut.
    91	- **New relay path vs reuse:** extend the existing skill and harness over forking a parallel path; if the harness can't accommodate it, surface the gap.
    92	- **Ambitious vs resumable:** a shorter plan an agent can resume cold beats a comprehensive one that buries state in prose.
    93	
    94	**Reject or escalate when**
    95	
    96	- A headless path has no allowlist, no worktree isolation, and no commit-bypass guard — and the doc doesn't justify why.
    97	- "Done" has no runnable verification step.
    98	- Adding a new relay lane requires editing the event-log kernel or the `tick` verb schema without a decision record under `decisions/`.
    99	- Hardcoded absolute paths, silent destructive operations, or opaque epoch-fence assumptions.
   100	- ROADMAP.md would need execution detail to make the plan legible.

exec
/bin/zsh -lc 'git --version' in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-48652-24158
 succeeded in 3146ms:
2026-07-07 19:44:01.397 xcodebuild[53047:112393253]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-07-07 19:44:01.741 xcodebuild[53047:112393252] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.
git: warning: confstr() failed with code 5: couldn't get path of DARWIN_USER_TEMP_DIR; using /tmp instead
git: error: couldn't create cache file '/tmp/xcrun_db-fh1lm5Kc' (errno=Operation not permitted)
2026-07-07 19:44:02.457 xcodebuild[53171:112393490]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-07-07 19:44:02.651 xcodebuild[53171:112393489] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.
git version 2.50.1 (Apple Git-155)

web search: 
web search: 'REFS'
web search: 
web search: https://git-scm.com/docs/git-worktree
web search: 
web search: 'checked out'
web search: 
web search: https://git-scm.com/docs/git-branch
web search: 
web search: site:github.com/git/git "cannot delete branch" "checked out at"
web search: 
web search: github git worktree branch -D checked out in another worktree test site:github.com/git/git
web search: 
web search: "cannot delete branch" "checked out at" git
web search: 
web search: git branch delete checked out in another worktree
web search: 
web search: site:github.com/git/git "checked out at" branch.c
web search: 
web search: https://github.com/git/git/search?q=checked+out+at&type=code
web search: 
web search: https://raw.githubusercontent.com/git/git/master/builtin/branch.c
web search: 
web search: https://github.com/git/git/blob/master/builtin/branch.c
web search: 
web search: 'cannot delete branch' in https://raw.githubusercontent.com/git/git/master/builtin/branch.c
web search: 
web search: https://git-scm.com/docs/git-init
web search: 
web search: https://raw.githubusercontent.com/git/git/master/builtin/gc.c
web search: 
web search: https://git-scm.com/docs/git-reflog
web search: 
web search: 'HEAD'
web search: 
web search: https://git-scm.com/docs/gitrepository-layout
web search: 
web search: https://git-scm.com/docs/gitrepository-layout
web search: 
web search: 'gc.worktreePruneExpire' in https://git-scm.com/docs/git-worktree
codex
I’ve got enough to separate “wrong behavior claims” from “good intent, bad mechanism.” The biggest corrections are: `prune` timing/semantics, `move` version floor, the stash model, the `branch -D` claim, and the GC explanation.
exec
/bin/zsh -lc "sed -n '79,115p' WORKTREE-SAFETY.md | nl -ba -v79" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-48652-24158
exec
/bin/zsh -lc "sed -n '24,40p' WORKTREE-SAFETY.md | nl -ba -v24" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-48652-24158
exec
/bin/zsh -lc "sed -n '141,165p' WORKTREE-SAFETY.md | nl -ba -v141" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-48652-24158
 succeeded in 0ms:
    24	
    25	**Correct approach:**
    26	```bash
    27	# Always use git worktree remove
    28	git worktree remove ../feature-branch
    29	
    30	# If already nuked, clean up manually
    31	git worktree prune
    32	# Or more aggressively:
    33	rm -rf .git/worktrees/feature-branch
    34	```
    35	
    36	---
    37	
    38	## 2. Scripting `git worktree add` without failure handling
    39	
    40	**Anti-pattern:** Assuming `git worktree add` succeeds.

 succeeded in 0ms:
    79	**Defensive version:**
    80	```bash
    81	WORKTREE="$(git worktree add --quiet ../feature-XXXX feature-branch 2>&1 | awk '{print $NF}' | head -1)"
    82	[ -d "$WORKTREE" ] || { echo "Worktree creation failed" >&2; exit 1; }
    83	WORKTREE="$(cd "$WORKTREE" && pwd -P)"  # canonicalize AFTER validation
    84	
    85	cleanup() {
    86	    git worktree remove --force "$WORKTREE" 2>/dev/null || true
    87	    git worktree prune 2>/dev/null || true
    88	}
    89	trap cleanup EXIT
    90	```
    91	
    92	---
    93	
    94	## 4. Moving/renaming worktree directories outside of git
    95	
    96	**Anti-pattern:** Using `mv` to relocate a worktree.
    97	
    98	```bash
    99	mv ../feature-branch ../feature-branch-old
   100	```
   101	
   102	**Why it's dangerous:** The `.git` file inside the worktree contains an absolute or relative path back to the main repo. Moving it breaks that link. Git now can't find the worktree, and `git worktree remove` fails.
   103	
   104	**Correct approach:**
   105	```bash
   106	# Git 2.34+ supports moving
   107	git worktree move ../feature-branch ../feature-branch-renamed
   108	
   109	# Older versions: remove and re-add
   110	git worktree remove ../feature-branch
   111	git worktree add ../feature-branch-renamed feature-branch
   112	```
   113	
   114	---
   115	

 succeeded in 0ms:
   141	## 6. Garbage collection while worktrees exist
   142	
   143	**Anti-pattern:** Running aggressive GC without considering worktrees.
   144	
   145	```bash
   146	git gc --aggressive --prune=now
   147	```
   148	
   149	**Why it's dangerous:**
   150	- Worktrees share the same object database as the main repo
   151	- If a worktree has locally-created objects (stashes, unreachable commits, blob cache), GC can delete objects another worktree needs
   152	- `git gc` only considers refs from the worktree it's run in, but objects might be reachable from another worktree's refs
   153	
   154	**Defensive approach:**
   155	```bash
   156	# Always list worktrees before GC to understand what's shared
   157	git worktree list
   158	
   159	# Safer: run gc from the main worktree with all refs visible
   160	# Or avoid --prune=now when worktrees exist
   161	git gc --auto  # conservative, safe
   162	```
   163	
   164	---
   165	

exec
/bin/zsh -lc "sed -n '206,245p' WORKTREE-SAFETY.md | nl -ba -v206" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-48652-24158
 succeeded in 0ms:
   206	
   207	## 9. Branch deletion without checking worktree occupancy
   208	
   209	**Anti-pattern:** Deleting a branch that's checked out in a worktree.
   210	
   211	```bash
   212	git branch -d feature-branch  # fails if checked out elsewhere
   213	git branch -D feature-branch  # force-deletes, leaves worktree in detached HEAD
   214	```
   215	
   216	**Why it's dangerous:** Force-deleting the branch leaves the worktree in a detached HEAD state. The developer working there suddenly has no branch, and their next `git push` will fail or push to an unexpected ref. Their work is still there (in the working tree and reflog) but panic often ensues.
   217	
   218	**Check first:**
   219	```bash
   220	if git worktree list | grep -q 'feature-branch'; then
   221	    echo "Branch is checked out in a worktree — aborting deletion" >&2
   222	    exit 1
   223	fi
   224	```
   225	
   226	---
   227	
   228	## 10. `git stash` in a worktree and expecting it to appear in another
   229	
   230	**Anti-pattern:** Assuming stashes are shared across worktrees.
   231	
   232	```bash
   233	# In worktree A
   234	git stash push -m "WIP: half-done feature"
   235	
   236	# In worktree B
   237	git stash pop  # NOPE, stashes are per-worktree!
   238	```
   239	
   240	**Why it's dangerous:** Stashes are stored in the worktree's own refs (`.git/worktrees/<name>/refs/stash`), not in the shared refs. Popping in the wrong worktree gets you a different stash or nothing.
   241	
   242	**Correct mental model:** Stashes are worktree-local. Use `git stash list` in each worktree to see what's actually there.
   243	
   244	---
   245	

exec
/bin/zsh -lc "sed -n '166,185p' WORKTREE-SAFETY.md | nl -ba -v166" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-48652-24158
 succeeded in 0ms:
   166	## 7. Deleting the main worktree's `.git` directory
   167	
   168	**Anti-pattern:** Treating the main `.git` directory as just another git database.
   169	
   170	```bash
   171	# Thinking you're cleaning up an old clone
   172	rm -rf .git
   173	```
   174	
   175	**Why it's dangerous:** All linked worktrees reference the main repo's object database via their `.git` files. Deleting the main `.git` irrecoverably breaks every linked worktree.
   176	
   177	**Real-world scenario:** You have 3 worktrees off a main checkout. Someone decides to "clean up" by deleting the main checkout folder. Now all 3 worktrees are orphaned with no object database, and even `git log` fails.
   178	
   179	**Precaution:**
   180	```bash
   181	# Before removing any repo, check if it's the primary for worktrees
   182	git worktree list
   183	# If other worktrees reference this one's objects, don't delete .git
   184	```
   185	

codex
**Answer**
Not technically reliable as written. The guide has the right intent, but sections on `prune`, `move`, `gc`, `branch -D`, and stash behavior need correction, and it does not cover the actual GH-177 failure mode of partial `.git` corruption.

**Findings**
- [Blocker] Section 10 is factually wrong about stashes at [WORKTREE-SAFETY.md](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-48652-24158/WORKTREE-SAFETY.md:228). `git stash` stores the latest stash in `refs/stash`, and `git worktree` says refs under `refs/` are shared except `refs/bisect`, `refs/worktree`, and `refs/rewritten`. Concrete edit: rewrite this section to say stashes are shared across worktrees, not local to `.git/worktrees/<name>/refs/stash`. Sources: https://git-scm.com/docs/git-stash , https://git-scm.com/docs/git-worktree
- [Blocker] Section 9 is wrong about `git branch -D` at [WORKTREE-SAFETY.md](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-48652-24158/WORKTREE-SAFETY.md:207). Current Git refuses to delete a branch used by another worktree; it does not force-delete it and leave that worktree detached. Concrete edit: replace the claim with “both `-d` and `-D` should be treated as blocked when the branch is checked out elsewhere.” Sources: official command docs https://git-scm.com/docs/git-branch and Git source `builtin/branch.c` (`cannot delete branch '%s' used by worktree at '%s'`): https://raw.githubusercontent.com/git/git/master/builtin/branch.c
- [Blocker] Section 6’s GC explanation is wrong at [WORKTREE-SAFETY.md](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-48652-24158/WORKTREE-SAFETY.md:141). The real documented risk of `git gc --prune=now` is concurrent writers corrupting the repo, not “GC only sees refs from the current worktree.” `git reflog expire --all` also processes reflogs from all worktrees unless `--single-worktree` is used. Concrete edit: keep the warning against `--prune=now`, but explain it as a concurrency/reachability-risk issue, not a current-worktree-only issue. Sources: https://git-scm.com/docs/git-gc , https://git-scm.com/docs/git-reflog
- [Should] Section 1 cleanup advice is incomplete at [WORKTREE-SAFETY.md](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-48652-24158/WORKTREE-SAFETY.md:25). `git worktree prune` only prunes missing worktrees older than the expiry threshold; a plain `git worktree prune` may do nothing for a freshly deleted tree. Manual `rm -rf .git/worktrees/<name>` should be last-resort, because `git worktree repair` may be able to reconnect a moved tree. Concrete edit: change the recovery line to `git worktree prune --expire now`, mention `git worktree repair`, and demote manual metadata deletion. Sources: https://git-scm.com/docs/git-worktree , https://git-scm.com/docs/git-gc
- [Should] Section 4’s version claim is wrong at [WORKTREE-SAFETY.md](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-48652-24158/WORKTREE-SAFETY.md:104). `git worktree move` exists in Git 2.17.0, not “2.34+”. Also, modern Git has `git worktree repair` for manually moved main or linked worktrees. Concrete edit: update the version floor and add the `repair` path; also mention that the main worktree and linked worktrees containing submodules cannot be moved with `git worktree move`. Sources: https://git-scm.com/docs/git-worktree/2.17.0 , https://git-scm.com/docs/git-worktree
- [Should] Section 3’s “defensive version” is broken shell at [WORKTREE-SAFETY.md](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-48652-24158/WORKTREE-SAFETY.md:79). `git worktree add` does not expand `../feature-XXXX`, and `--quiet` suppresses the output the pipeline is trying to parse, so `WORKTREE` will often be empty. Concrete edit: generate the path first, then call `git worktree add "$WORKTREE" ...`, then canonicalize it.
- [Should] The guide misses the actual GH-177 failure mode. Section 7 at [WORKTREE-SAFETY.md](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-48652-24158/WORKTREE-SAFETY.md:166) only covers wholesale `rm -rf .git`, not partial corruption where `HEAD`, `objects`, `refs`, and `index` disappear while `config`, `hooks`, and `worktrees/` survive. Concrete edit: add a new section like “Partial `.git` corruption: detect, repair, reconcile” with an ordered checklist: verify `.git/HEAD`, `objects`, `refs`, `index`, `config`; rerun `git init` if the skeleton is missing; `git fetch` to repopulate remote history; inspect surviving local refs/reflogs/worktrees before resetting anything; run `git worktree repair` / `git worktree prune --expire now`; finish with `git fsck --full`. Sources: https://git-scm.com/docs/gitrepository-layout , https://git-scm.com/docs/git-init , https://git-scm.com/docs/git-worktree
- [Should] Missing worktree footguns worth adding: `git worktree add <path>` auto-creates a branch from the path basename if you omit a branch or `--detach`; un-locked portable/offline worktrees can be pruned; `git config` is shared unless you use `--worktree` and worktree config; `git rev-parse --git-dir` in a linked worktree points at the private admin dir, not the common repo dir. Sources: https://git-scm.com/docs/git-worktree , https://git-scm.com/docs/gitrepository-layout
- [Pass] The document’s core posture is sound: “use `git worktree remove`, not `rm -rf`” and “treat the main `.git` as shared state” are still the right guardrails.

1. Replace sections 6, 9, and 10 first; those are the highest-risk factual errors.
2. Rewrite section 1 and section 4 next to fix `prune`/`repair` semantics and the bad `move` version note.
3. Replace the broken shell example in section 3.
4. Add a new GH-177-style partial-corruption detection/recovery section.
5. Add the missing scripting footguns: auto-created branches, `lock`, worktree-local config, and `--git-dir` vs `--git-common-dir`.

**Recommendation**
Revise `WORKTREE-SAFETY.md` before treating it as authoritative: correct the five behavior claims above and add a dedicated partial-`.git` corruption recovery section modeled on GH-177.
tokens used
201,680
**Answer**
Not technically reliable as written. The guide has the right intent, but sections on `prune`, `move`, `gc`, `branch -D`, and stash behavior need correction, and it does not cover the actual GH-177 failure mode of partial `.git` corruption.

**Findings**
- [Blocker] Section 10 is factually wrong about stashes at [WORKTREE-SAFETY.md](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-48652-24158/WORKTREE-SAFETY.md:228). `git stash` stores the latest stash in `refs/stash`, and `git worktree` says refs under `refs/` are shared except `refs/bisect`, `refs/worktree`, and `refs/rewritten`. Concrete edit: rewrite this section to say stashes are shared across worktrees, not local to `.git/worktrees/<name>/refs/stash`. Sources: https://git-scm.com/docs/git-stash , https://git-scm.com/docs/git-worktree
- [Blocker] Section 9 is wrong about `git branch -D` at [WORKTREE-SAFETY.md](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-48652-24158/WORKTREE-SAFETY.md:207). Current Git refuses to delete a branch used by another worktree; it does not force-delete it and leave that worktree detached. Concrete edit: replace the claim with “both `-d` and `-D` should be treated as blocked when the branch is checked out elsewhere.” Sources: official command docs https://git-scm.com/docs/git-branch and Git source `builtin/branch.c` (`cannot delete branch '%s' used by worktree at '%s'`): https://raw.githubusercontent.com/git/git/master/builtin/branch.c
- [Blocker] Section 6’s GC explanation is wrong at [WORKTREE-SAFETY.md](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-48652-24158/WORKTREE-SAFETY.md:141). The real documented risk of `git gc --prune=now` is concurrent writers corrupting the repo, not “GC only sees refs from the current worktree.” `git reflog expire --all` also processes reflogs from all worktrees unless `--single-worktree` is used. Concrete edit: keep the warning against `--prune=now`, but explain it as a concurrency/reachability-risk issue, not a current-worktree-only issue. Sources: https://git-scm.com/docs/git-gc , https://git-scm.com/docs/git-reflog
- [Should] Section 1 cleanup advice is incomplete at [WORKTREE-SAFETY.md](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-48652-24158/WORKTREE-SAFETY.md:25). `git worktree prune` only prunes missing worktrees older than the expiry threshold; a plain `git worktree prune` may do nothing for a freshly deleted tree. Manual `rm -rf .git/worktrees/<name>` should be last-resort, because `git worktree repair` may be able to reconnect a moved tree. Concrete edit: change the recovery line to `git worktree prune --expire now`, mention `git worktree repair`, and demote manual metadata deletion. Sources: https://git-scm.com/docs/git-worktree , https://git-scm.com/docs/git-gc
- [Should] Section 4’s version claim is wrong at [WORKTREE-SAFETY.md](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-48652-24158/WORKTREE-SAFETY.md:104). `git worktree move` exists in Git 2.17.0, not “2.34+”. Also, modern Git has `git worktree repair` for manually moved main or linked worktrees. Concrete edit: update the version floor and add the `repair` path; also mention that the main worktree and linked worktrees containing submodules cannot be moved with `git worktree move`. Sources: https://git-scm.com/docs/git-worktree/2.17.0 , https://git-scm.com/docs/git-worktree
- [Should] Section 3’s “defensive version” is broken shell at [WORKTREE-SAFETY.md](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-48652-24158/WORKTREE-SAFETY.md:79). `git worktree add` does not expand `../feature-XXXX`, and `--quiet` suppresses the output the pipeline is trying to parse, so `WORKTREE` will often be empty. Concrete edit: generate the path first, then call `git worktree add "$WORKTREE" ...`, then canonicalize it.
- [Should] The guide misses the actual GH-177 failure mode. Section 7 at [WORKTREE-SAFETY.md](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-48652-24158/WORKTREE-SAFETY.md:166) only covers wholesale `rm -rf .git`, not partial corruption where `HEAD`, `objects`, `refs`, and `index` disappear while `config`, `hooks`, and `worktrees/` survive. Concrete edit: add a new section like “Partial `.git` corruption: detect, repair, reconcile” with an ordered checklist: verify `.git/HEAD`, `objects`, `refs`, `index`, `config`; rerun `git init` if the skeleton is missing; `git fetch` to repopulate remote history; inspect surviving local refs/reflogs/worktrees before resetting anything; run `git worktree repair` / `git worktree prune --expire now`; finish with `git fsck --full`. Sources: https://git-scm.com/docs/gitrepository-layout , https://git-scm.com/docs/git-init , https://git-scm.com/docs/git-worktree
- [Should] Missing worktree footguns worth adding: `git worktree add <path>` auto-creates a branch from the path basename if you omit a branch or `--detach`; un-locked portable/offline worktrees can be pruned; `git config` is shared unless you use `--worktree` and worktree config; `git rev-parse --git-dir` in a linked worktree points at the private admin dir, not the common repo dir. Sources: https://git-scm.com/docs/git-worktree , https://git-scm.com/docs/gitrepository-layout
- [Pass] The document’s core posture is sound: “use `git worktree remove`, not `rm -rf`” and “treat the main `.git` as shared state” are still the right guardrails.

1. Replace sections 6, 9, and 10 first; those are the highest-risk factual errors.
2. Rewrite section 1 and section 4 next to fix `prune`/`repair` semantics and the bad `move` version note.
3. Replace the broken shell example in section 3.
4. Add a new GH-177-style partial-corruption detection/recovery section.
5. Add the missing scripting footguns: auto-created branches, `lock`, worktree-local config, and `--git-dir` vs `--git-common-dir`.

**Recommendation**
Revise `WORKTREE-SAFETY.md` before treating it as authoritative: correct the five behavior claims above and add a dedicated partial-`.git` corruption recovery section modeled on GH-177.
