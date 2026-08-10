**SINGLE-MODEL — NOT RECONCILED** (only codex answered; 1 of 2 requested advisor(s) failed — this is one model's read, not a cross-model consult. Do not treat any claim below as cross-verified.)

**NO FIRSTHAND VERIFICATION CITED** — treat conclusions as conditional (codex's answer carries an unsupported [Pass]/verified/confirmed-style claim with no quoted span or file:line citation nearby, despite the consult PREAMBLE asking advisors to cite evidence.)

> **ATTESTATION**
> Model: gpt-5.6-terra
> Provider: openai
> Sandbox: read-only

Reading additional input from stdin...
2026-08-10T04:57:47.415718Z ERROR codex_models_manager::cache: failed to load models cache: missing field `supports_reasoning_summaries` at line 87 column 5
OpenAI Codex v0.144.6
--------
workdir: /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-67768-b0m00j9w
model: gpt-5.6-terra
provider: openai
approval: never
sandbox: read-only
reasoning effort: high
reasoning summaries: none
session id: 019fea08-c01c-7f63-bdf2-38b3530a9e92
--------
user
You are an INDEPENDENT advisor in a one-shot cross-model consult. Another model is answering the SAME question separately and a coordinator will reconcile both answers, so give your own honest, specific read — do not hedge toward a consensus you cannot see. Read any repo files the question references (cite file:line). Respond with: (1) a short direct ANSWER; (2) graded FINDINGS — [Blocker]/[Should]/[Nit]/[Pass] — where applicable; (3) a one-line RECOMMENDATION. You are ADVISORY ONLY: output your analysis as text; do not rely on writing files (you are running in a throwaway copy).

=== CONSULT QUESTION ===
Review PROJECT/1-INBOX/GH-484-MARATHONS-DEFAULT.md (issue #484) for correctness and completeness
of the plan to flip the marathon-phase run-output directory default from `phases/` to `MARATHONS/`.

Read the actual code, not just the plan doc's claims — verify or refute each claim below against
the real files.

Focus specifically on:

1. Whether the scope is right — is flipping the two twins' `--phases-dir`/`PHASES_DIR` default
   (utils/py/marathon_drive.py and relay-automation/marathon-drive.sh) plus fixing the 2 identified
   hardcoded literal-path checks (marathon_drive.py:1666, marathon-drive.sh:961) actually
   sufficient, or is something load-bearing being missed that would only surface at runtime.

2. Whether the GH-308 frozen-twin exception process (test/gh308-frozen-twin-guard.sh --check --base
   <rev> --allow-exceptions) is being invoked correctly for this kind of change.

3. Whether the phase ordering (0: discovery/enumerate which files actually assert the default value
   vs. just describe/override it; 1: flip default + fix the 2 literals + twin-parity test; 2: apply
   Phase 0's checklist + docs) is safe, or whether Phase 1 should not land before Phase 0 completes.

4. Any other hardcoded "phases" path assumption in the live driver code that a grep-based audit
   might have missed — e.g. anything constructed via string formatting/concatenation rather than a
   literal, or anything in utils/swarm-preflight.sh / utils/py/swarm_preflight.py / relay-automation/
   poll.sh / relay-automation/relay-turn-lib.sh that assumes the literal directory name "phases".

5. The plan's claim that a gitignore of the phase-output directory would crash a same-repo phase via
   `git add --` + `check=True` (marathon_drive.py, three call sites) — verify this claim is real, not
   assumed, and confirm test/marathon-root-audit.sh actually asserts against it today.

Report concrete findings with file:line citations, not general praise. If the plan is sound as
written, say so plainly rather than manufacturing findings.

hook: SessionStart
hook: SessionStart Completed
codex
I’ll audit the issue plan against the live Python/Bash driver paths and the specified guards/tests. This is read-only; I’ll cite exact locations.
mcp: codebase-memory-mcp/list_projects started
mcp: codebase-memory-mcp/list_projects (failed)
user cancelled MCP tool call
mcp: codebase-memory-mcp/index_repository started
mcp: codebase-memory-mcp/index_repository (failed)
user cancelled MCP tool call
exec
/bin/zsh -lc "for file in WORKTREE-SAFETY.md ROUTER.md GUIDING-PRINCIPLES.md PROJECT/PDDA.md PROJECT/1-INBOX/GH-484-MARATHONS-DEFAULT.md; do printf '\\n===== %s =====\\n' \""'$file"; nl -ba "$file"; done' in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-67768-b0m00j9w
 succeeded in 0ms:

===== WORKTREE-SAFETY.md =====
     1	# Git Worktree Safety Guide for Agents
     2	
     3	Author: Noel Saw (@noelsaw1)  
     4	Licensed under: Apache 2.0  
     5	Copyright 2026 Neochrome, Inc.  
     6	
     7	> **Purpose:** Prevent destructive footguns when scripting with Git worktrees.  
     8	> **Scope:** Shell scripts, CI pipelines, and agent workflows that create, manage, or clean up worktrees.
     9	
    10	---
    11	
    12	## 1. The "rm -rf worktree path" trap
    13	
    14	**Anti-pattern:** Deleting a worktree by just removing its directory.
    15	
    16	```bash
    17	# WRONG — leaves stale metadata in .git/worktrees/
    18	rm -rf ../feature-branch
    19	
    20	# Also WRONG — git still thinks the worktree exists
    21	git worktree remove ../feature-branch  # fails: "not a working tree"
    22	```
    23	
    24	**Why it's dangerous:** Git maintains metadata in `.git/worktrees/<name>/` and in a `.git` file inside the worktree. If you `rm -rf` the directory, you get:
    25	- Orphaned metadata polluting your repo
    26	- The branch may still be checked out according to git, blocking operations
    27	- `.git/worktrees/<name>/index` can grow large and never gets cleaned
    28	
    29	**Correct approach:**
    30	```bash
    31	# Always use git worktree remove
    32	git worktree remove ../feature-branch
    33	
    34	# If the directory is already gone, let git reconcile its own metadata —
    35	# don't hand-delete .git/worktrees/<name> yourself:
    36	git worktree prune
    37	
    38	# If the worktree still exists but was moved/relinked and git can't find it,
    39	# `repair` (Git 2.29+) is the documented fix, not manual surgery on .git/worktrees/:
    40	git worktree repair ../feature-branch
    41	```
    42	Manual `rm -rf .git/worktrees/<name>` is a last resort for a clearly corrupt admin
    43	stub that `prune`/`repair` won't touch — not the normal cleanup path.
    44	
    45	---
    46	
    47	## 2. Scripting `git worktree add` without failure handling
    48	
    49	**Anti-pattern:** Assuming `git worktree add` succeeds.
    50	
    51	```bash
    52	git worktree add ../hotfix hotfix-branch
    53	cd ../hotfix || exit 1
    54	# ... do work ...
    55	```
    56	
    57	**Why it's dangerous:**
    58	- Branch might already be checked out in another worktree (git refuses with "already checked out")
    59	- Path might already exist
    60	- Disk might be full
    61	- Detached HEAD might not be what you expected
    62	
    63	**Defensive version:**
    64	```bash
    65	if ! git worktree add ../hotfix hotfix-branch 2>/dev/null; then
    66	    echo "Worktree creation failed — branch may already be checked out or path exists" >&2
    67	    exit 1
    68	fi
    69	```
    70	
    71	---
    72	
    73	## 3. Trap cleaning worktrees with `rm -rf` and relative paths
    74	
    75	**Anti-pattern:** The sibling of the `mktemp` bug — cleaning worktrees in traps.
    76	
    77	```bash
    78	WORKTREE="../feature-$(date +%s)"
    79	git worktree add "$WORKTREE" feature-branch
    80	trap 'rm -rf "$WORKTREE"' EXIT
    81	```
    82	
    83	**Why it's dangerous:**
    84	- If `git worktree add` fails and `WORKTREE` is empty/malformed, a quoted `rm -rf "$WORKTREE"` errors on an empty string (`rm: missing operand`) rather than silently targeting cwd — but an *unquoted* `rm -rf $WORKTREE` word-splits an empty value to zero arguments, which for GNU `rm` is also a no-op/error, NOT an implicit `.`. The real risk isn't a specific "resolves to cwd" mechanism at all: it's that an unvalidated variable in a destructive trap can hold anything (a partial path, a stray `*`, a value from a prior failed `cd`) by the time `EXIT` fires, and nothing between assignment and the trap firing re-checks it
    85	- If the script `cd`s into the worktree, the relative path `../` now points somewhere else
    86	- `rm -rf` leaves stale metadata in `.git/worktrees/`
    87	
    88	**Defensive version:**
    89	```bash
    90	# NOTE: unlike mktemp, git worktree add does NOT expand "XXXX" into a random
    91	# suffix — that string would be used verbatim as the path. Build the unique
    92	# path yourself before calling git, and don't rely on parsing git's output
    93	# (--quiet suppresses exactly the text a naive script would try to awk out of it).
    94	WORKTREE="$(pwd)/../feature-$$-$(date +%s)"
    95	git worktree add "$WORKTREE" feature-branch || { echo "Worktree creation failed" >&2; exit 1; }
    96	WORKTREE="$(cd "$WORKTREE" && pwd -P)"  # canonicalize AFTER validation
    97	
    98	cleanup() {
    99	    # --force here is NOT the §12 anti-pattern: this worktree was just created by THIS script for a
   100	    # throwaway purpose and is being torn down in its own exit trap, not force-removed out from under
   101	    # someone else's uncommitted work. §12's warning is about scripts reaching for --force to silence
   102	    # an error on a worktree they don't own/didn't create.
   103	    git worktree remove --force "$WORKTREE" 2>/dev/null || true
   104	    git worktree prune 2>/dev/null || true
   105	}
   106	trap cleanup EXIT
   107	```
   108	
   109	---
   110	
   111	## 4. Moving/renaming worktree directories outside of git
   112	
   113	**Anti-pattern:** Using `mv` to relocate a worktree.
   114	
   115	```bash
   116	mv ../feature-branch ../feature-branch-old
   117	```
   118	
   119	**Why it's dangerous:** The `.git` file inside the worktree contains an absolute or relative path back to the main repo. Moving it breaks that link. Git now can't find the worktree, and `git worktree remove` fails.
   120	
   121	**Correct approach:**
   122	```bash
   123	# git worktree move shipped in Git 2.17.0 — use it instead of mv
   124	git worktree move ../feature-branch ../feature-branch-renamed
   125	
   126	# Pre-2.17: remove and re-add
   127	git worktree remove ../feature-branch
   128	git worktree add ../feature-branch-renamed feature-branch
   129	
   130	# If a worktree (or the main worktree) was ALREADY moved outside git's
   131	# knowledge — e.g. via `mv`, a backup restore, or a renamed parent dir — the
   132	# documented fix is `repair` (Git 2.29+), not manual .git-file surgery:
   133	git worktree repair ../feature-branch-renamed
   134	```
   135	
   136	---
   137	
   138	## 5. Assuming `main` (or any shared branch) is free for checkout
   139	
   140	**Anti-pattern:** `git worktree add` for a branch that's already checked out elsewhere.
   141	
   142	```bash
   143	# Script adds a worktree for "main" to run tests
   144	git worktree add ../main-worktree main
   145	```
   146	
   147	**Why it's dangerous:** If any other worktree already has `main` checked out, this fails. This is especially problematic in CI or multi-session environments.
   148	
   149	**Defensive version:**
   150	```bash
   151	# Use a unique branch name or detached HEAD
   152	git worktree add --detach ../test-run-$$ main
   153	
   154	# Or check first — parse --porcelain, not human-readable output. The plain
   155	# `git worktree list` format is not a stable API and grep can false-match on
   156	# pathnames that happen to contain "[main]"-like substrings.
   157	if git worktree list --porcelain | grep -qx 'branch refs/heads/main'; then
   158	    echo "main is already checked out in another worktree" >&2
   159	    exit 1
   160	fi
   161	```
   162	
   163	---
   164	
   165	## 6. Garbage collection while worktrees exist
   166	
   167	**Anti-pattern:** Running aggressive GC without considering worktrees.
   168	
   169	```bash
   170	git gc --aggressive --prune=now
   171	```
   172	
   173	**Why it's dangerous:**
   174	- Worktrees share the same object database, and (with the exception of
   175	  `refs/bisect`, `refs/worktree`, and `refs/rewritten`) the same refs — modern
   176	  Git *is* worktree-aware and does scan all registered worktrees' refs/logs
   177	  before pruning, so "gc can't see another worktree's refs" is not the
   178	  mechanism
   179	- The real documented risk is **concurrency**: `--prune=now` disables the
   180	  normal grace-period safety margin, so if another process (a build in a
   181	  linked worktree, a concurrent commit) creates an object that isn't
   182	  referenced by a ref yet, `--prune=now` can delete it out from under that
   183	  process — a race, not a worktree-visibility gap
   184	- A secondary, worktree-specific risk: if a worktree directory was manually
   185	  `rm -rf`'d without `git worktree prune`, its stale `.git/worktrees/<name>/`
   186	  admin entry can leave git's bookkeeping out of sync with reality until
   187	  pruned
   188	
   189	**Defensive approach:**
   190	```bash
   191	# Always list worktrees before GC to understand what's shared
   192	git worktree list
   193	
   194	# Avoid --prune=now while any worktree might be mid-write (build, commit, checkout)
   195	# Or avoid --prune=now entirely
   196	git gc --auto  # conservative, safe
   197	```
   198	
   199	---
   200	
   201	## 7. Deleting the main worktree's `.git` directory
   202	
   203	**Anti-pattern:** Treating the main `.git` directory as just another git database.
   204	
   205	```bash
   206	# Thinking you're cleaning up an old clone
   207	rm -rf .git
   208	```
   209	
   210	**Why it's dangerous:** All linked worktrees reference the main repo's object database via their `.git` files. Deleting the main `.git` irrecoverably breaks every linked worktree.
   211	
   212	**Real-world scenario:** You have 3 worktrees off a main checkout. Someone decides to "clean up" by deleting the main checkout folder. Now all 3 worktrees are orphaned with no object database, and even `git log` fails.
   213	
   214	**Precaution:**
   215	```bash
   216	# Before removing any repo, check if it's the primary for worktrees
   217	git worktree list
   218	# If other worktrees reference this one's objects, don't delete .git
   219	```
   220	
   221	---
   222	
   223	## 8. Scripts that `cd` into a worktree then use relative paths back
   224	
   225	**Anti-pattern:**
   226	```bash
   227	cd ../feature-branch
   228	# ... do stuff ...
   229	../../main-repo/some-script.sh  # fragile relative path
   230	```
   231	
   232	**Why it's dangerous:** The worktree is a separate directory. Your relative path `../../` assumes a specific directory layout that may not hold (the worktree could be anywhere on disk, not necessarily a sibling).
   233	
   234	**Defensive approach:**
   235	```bash
   236	MAIN_REPO="$(git rev-parse --git-common-dir)"  # finds the shared .git
   237	MAIN_ROOT="$(cd "$MAIN_REPO/.." && pwd)"        # parent of shared .git
   238	```
   239	Caveat: `"$MAIN_REPO/.."` assumes the standard "`.git` directory sits directly
   240	under the repo root" layout. It breaks for repos using `--separate-git-dir`
   241	or a bare common dir, where `.git` isn't a sibling of the working files. For
   242	those layouts, don't derive the root by walking up from `--git-common-dir` —
   243	resolve it explicitly (e.g. from `git worktree list --porcelain`, which
   244	reports each worktree's actual path).
   245	
   246	---
   247	
   248	## 9. Assuming `git branch -D` on a worktree-occupied branch is dangerous the way you think
   249	
   250	**Corrected claim:** Git actually protects you here — both `git branch -d` *and* `git branch -D`
   251	(force) refuse to delete a branch that's checked out in **any** worktree, main or linked. This was
   252	verified empirically (Git 2.50.1): `git branch -D feature-branch` fails with
   253	`error: cannot delete branch 'feature-branch' used by worktree at 'PATH'` (exit 1). There is no
   254	"force-delete succeeds and leaves that worktree in detached HEAD" failure mode — that was this
   255	doc's own error, not a real Git footgun.
   256	
   257	```bash
   258	git branch -d feature-branch  # fails if checked out elsewhere
   259	git branch -D feature-branch  # ALSO fails — Git blocks this even with -D
   260	```
   261	
   262	**What's still worth guarding against:** the actual footgun is scripts that treat this failure as
   263	fatal-and-unexpected instead of handling it, or that work around it by first force-removing the
   264	occupying worktree (`git worktree remove --force`) to clear the way — which *does* discard that
   265	worktree's uncommitted work. If a script needs to delete a branch, check occupancy first and fail
   266	loud rather than reaching for `--force` on the worktree to unblock the branch deletion:
   267	
   268	```bash
   269	if git worktree list --porcelain | grep -qx "branch refs/heads/feature-branch"; then
   270	    echo "Branch is checked out in a worktree — aborting deletion (do not --force the worktree to work around this)" >&2
   271	    exit 1
   272	fi
   273	```
   274	
   275	---
   276	
   277	## 10. `git stash` is GLOBAL, not per-worktree — popping in the wrong worktree corrupts the wrong tree
   278	
   279	**Corrected claim:** Stashes are **shared** across all worktrees via the single ref `refs/stash` in
   280	the main repo's shared ref store — `git-worktree`'s docs list `refs/bisect`, `refs/worktree`, and
   281	`refs/rewritten` as the only per-worktree ref namespaces, and `refs/stash` is not among them. This
   282	was verified empirically: a stash pushed in the main worktree shows up identically in
   283	`git stash list` run from a linked worktree.
   284	
   285	```bash
   286	# In worktree A
   287	git stash push -m "WIP: half-done feature"
   288	
   289	# In worktree B
   290	git stash list  # shows the SAME stash — it is not worktree-local
   291	git stash pop   # applies worktree A's stash onto worktree B's files — likely the WRONG tree
   292	```
   293	
   294	**Why it's actually dangerous:** because the stash is shared, popping it in the wrong worktree
   295	applies changes meant for one branch/tree onto a different one — conflicts, or silent application
   296	to unrelated files, and the stash is now consumed so worktree A can't get it back without digging
   297	through the reflog (`git fsck --unreachable`, `git stash list` right after `pop` won't show it).
   298	
   299	**Correct mental model:** Stashes are a single shared stack across the whole repo, indexed the same
   300	way from every worktree. Use unmistakable `-m` messages, and run `git stash list` in the worktree
   301	you're about to pop into (not the one you pushed from) to confirm which entry is `stash@{0}` before
   302	popping.
   303	
   304	---
   305	
   306	## 11. Selective `.git` corruption & skeleton loss (the GH-177 scenario)
   307	
   308	**What actually happened here (2026-07-07):** this repo's main `.git` directory lost `HEAD`,
   309	`objects/`, `refs/`, and `index`, while `hooks/`, `worktrees/`, and `config` survived intact. This
   310	is **not** the "someone ran `rm -rf .git`" scenario in §7 above — that deletes everything uniformly.
   311	This was a *partial* loss (consistent with a selective backup/restore gap), and none of the 10
   312	anti-patterns above describe it or would have helped diagnose it.
   313	
   314	**Detection — verify before trusting a repo:**
   315	```bash
   316	# A healthy repo has ALL of these. Any missing = don't trust git commands here yet.
   317	for f in HEAD objects refs config; do
   318	    [ -e ".git/$f" ] || echo "MISSING: .git/$f"
   319	done
   320	git fsck --no-progress 2>&1 | head -5   # first real integrity check once the above pass
   321	```
   322	Also check `.git/worktrees/*/gitdir` stubs for staleness — a stub with no valid path behind it (or
   323	just a bare `commondir` file and nothing else) is metadata cruft from the same class of incident,
   324	not a real linked worktree; `git worktree prune` clears it once the main repo is healthy again.
   325	
   326	**Recovery — in order, verifying before each destructive-looking step:**
   327	```bash
   328	# 1. git init is DOCUMENTED SAFE to re-run on an existing repo: it only fills in
   329	#    missing standard files (HEAD, objects/, refs/, description, info/exclude,
   330	#    sample hooks) and does NOT overwrite an existing config, hooks, or any
   331	#    working-tree file.
   332	git init
   333	
   334	# 2. Repopulate history from the remote — additive only, does not touch the
   335	#    working tree or local branch refs.
   336	git fetch origin
   337	
   338	# 3. Before pointing any local ref at origin, or touching the working tree,
   339	#    build an index from the candidate branch WITHOUT checkout (read-tree does
   340	#    not write to the working tree) and diff it against what's on disk:
   341	git read-tree origin/main
   342	git status   # compare — do NOT `checkout -f` / `reset --hard` / `clean` yet
   343	
   344	# 4. Only once you've confirmed the working tree matches (or you've decided
   345	#    what to do about genuine local divergence), point the branch ref at the
   346	#    remote — this only writes a ref, still doesn't touch the working tree:
   347	git update-ref refs/heads/main origin/main
   348	
   349	# 5. Restore any tracked files that are genuinely missing/corrupted on disk
   350	#    (confirmed absent or differing from origin, not local WIP) from the
   351	#    remote's tree — scoped to just those paths, not a blanket checkout:
   352	git checkout origin/main -- path/to/missing-file
   353	```
   354	The critical discipline: steps 1–3 are provably non-destructive to the working tree (`init` fills
   355	gaps only, `fetch` writes only to `.git/objects` and remote-tracking refs, `read-tree` populates the
   356	index without touching files). Do not reach for `checkout -f`, `reset --hard`, or `clean` until
   357	you've diffed and know exactly what you'd be overwriting — those commands assume the working tree is
   358	disposable, which after a partial-corruption incident it specifically is not.
   359	
   360	---
   361	
   362	## 12. Other footguns worth knowing before scripting worktrees
   363	
   364	- **Untracked or modified files block `git worktree remove`.** It refuses if the worktree has any
   365	  uncommitted changes; `--force` is required to proceed — and `--force` silently discards those
   366	  changes. Never default a script to `--force` as a way to "fix" a remove that failed.
   367	- **`git worktree move` does not support worktrees containing submodules** — the relative links
   368	  back to `.git/modules/` break. Don't script a blind `move` without checking `.gitmodules` first.
   369	- **`--force` on `add` / `move` / `remove` overrides the exact safeguards this guide teaches** (branch
   370	  occupancy, dirty-worktree protection, path collisions). Treat any script that reaches for `-f`/`--force`
   371	  to silence a worktree error as a signal to stop and understand *why* git refused, not a shortcut.
   372	- **Lock worktrees on removable/unstable storage.** `git worktree lock <path>` prevents `git worktree
   373	  prune` (including the prune that `git gc` can trigger) from reaping a worktree's metadata just
   374	  because its directory is temporarily unreachable (unmounted drive, network share).
   375	- **Prefer `git worktree list --porcelain` over the human-readable format** in any script. The
   376	  plain-text table is not a stable API; porcelain output is machine-parseable and won't false-match
   377	  on branch/path substrings the way a `grep` over the table can.
   378	
   379	---
   380	
   381	## Golden Rules for Worktree Safety
   382	
   383	1. **Always use `git worktree remove`/`prune`/`repair`, never manual `rm -rf` or `mv`** on worktree
   384	   directories or `.git/worktrees/<name>` — repair (2.29+) and move (2.17+) are git's own tools for
   385	   exactly these cases
   386	2. **Validate before destroying** — check that paths are non-empty, real directories, and not repo
   387	   roots before any destructive operation
   388	3. **Be path-aware in traps** — canonicalize paths early, validate them, and never `rm -rf` on
   389	   relative paths or unvalidated variables
   390	4. **The main repo's `.git` is the single source of truth** — protect it like a database, and verify
   391	   its skeleton (`HEAD`/`objects`/`refs`/`config`) is intact before trusting any command run against
   392	   it (§11); partial corruption is a real failure mode, not just total deletion
   393	5. **Worktrees share almost everything — objects, refs, AND stashes/logs.** The only genuinely
   394	   per-worktree ref namespaces are `refs/bisect`, `refs/worktree`, and `refs/rewritten`. Don't assume
   395	   isolation you don't have (§10); Git also actively *protects* shared state you might expect it not
   396	   to (§9's branch-delete block)
   397	6. **Prefer git's own recovery tools over hand-surgery on `.git/`** — `init` (safe to re-run),
   398	   `fetch`, `prune`, `repair` — and reach for `read-tree`/`diff`/`status` to inspect before any
   399	   command that can overwrite the working tree (`checkout -f`, `reset --hard`, `clean`)
   400	7. **Script against `--porcelain` output, never the human-readable table** — `git worktree list`'s
   401	   plain format is not a stable, grep-safe API
   402	
   403	---
   404	
   405	## See Also
   406	
   407	- [Git Worktree Documentation](https://git-scm.com/docs/git-worktree)
   408	- [git-init](https://git-scm.com/docs/git-init) — confirms re-running `init` on an existing repo is safe/non-clobbering
   409	- [git-fsck](https://git-scm.com/docs/git-fsck) — integrity check, first step after any suspected `.git` corruption
   410	- [git-gc](https://git-scm.com/docs/git-gc) — documents the `--prune=now` concurrency risk cited in §6
   411	- Related: [Temp Directory Safety Guide](./temp-dir-safety.md) — for the `mktemp` failure mode that can cascade into worktree destruction
   412	
   413	---
   414	
   415	Licensed under: Apache 2.0   
   416	Copyright 2026 Neochrome, Inc.  

===== ROUTER.md =====
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
    12	- `RELEASES.md` = forward-looking release-planning ledger (first-class PDDA artifact; governed by `PROJECT/PDDA.md`)
    13	- `PROJECT/**` docs = canonical execution detail for a specific effort
    14	- `PROJECT/PDDA.md` = document contract and automation rules (incl. the CHANGELOG contract)
    15	- `PROJECT/CONSTITUTION.md` = the policy of record: PDDA's lane and its non-negotiables (deterministic-before-LLM, verified-success-only, reversibility, local-first)
    16	- `PROJECT/DO-NOT-BUILD.md` = the anti-scope list — product directions PDDA must not become (companion to `CONSTITUTION.md`)
    17	
    18	## Startup sequence
    19	
    20	1. Read `ROUTER.md` to understand the repo's operating order and canonical files. -> expect one clear next file, not a repo-wide scavenger hunt.
    21	2. Read `AGENTS.md` before making recommendations or edits. -> expect explicit assumptions, a reversibility read on consequential changes, and verified claims only.
    22	3. Read `ROADMAP.md` to find the active effort or parked intake. -> expect links outward to the canonical `PROJECT/**` docs; `ROADMAP.md` is a pointer ledger, not a plan body.
    23	4. Read the linked `PROJECT/**` document that owns the work you are touching. -> expect the near-top `## Status` table to tell you what was just completed and what is next.
    24	5. If the task touches project docs, read `PROJECT/PDDA.md` and follow the PDDA contract. -> expect `PROJECT/2-WORKING` docs to have frontmatter, the exact status table, and QA gates when phased.
    25	6. Before reporting success on code or runtime work, run `./validate.sh`. -> expect the suite to stay green; do not claim completion if it fails or was skipped.
    26	7. Before reporting success on doc-hygiene or roadmap work, run `utils/pdda/pdda.sh run` (or the relevant `utils/pdda/pdda.sh <check>` subcommand). -> expect deterministic findings first, then any LLM review.
    27	
    28	## Canonical rules
    29	
    30	- Do not put phase checklists, build steps, or deep execution notes in `ROADMAP.md`.
    31	- Every active doc in `PROJECT/2-WORKING/` must be reflected by a pointer in `ROADMAP.md` — a one-line ledger entry that links it. A working doc that should not appear opts out with `roadmap_exempt: true` in its frontmatter. Enforced by `utils/pdda/pdda.sh roadmap-coverage`; governance lives in `PROJECT/PDDA.md` → "ROADMAP.md contract".
    32	- Every captured GitHub issue doc in `PROJECT/1-INBOX/GH-*.md` must also be parked in `ROADMAP.md` as a one-line queue entry immediately at intake, then promoted or removed later. Enforced by `utils/pdda/pdda.sh roadmap-coverage`; governance lives in `PROJECT/PDDA.md` → "GitHub issue intake" + "ROADMAP.md contract".
    33	- Do not create a second competing plan when a canonical `PROJECT/**` doc already exists.
    34	- Issue-first: any change beyond a **2–3 line** fix opens a GitHub issue first, then a pointer doc **named after the issue** (`GH-<number>-VERY-SHORT-DESC.md`, e.g. `GH-1234-SHOWME-COMMAND.md`), and that capture is **parked in `ROADMAP.md` immediately** before execution begins. The issue is the signal stream; the pointer doc is the execution surface of record. Genuinely trivial edits (≤2–3 line fixes, typos, path repoints, doc-only one-liners) are exempt. Governed by `PROJECT/PDDA.md` → "GitHub issue intake".
    35	- Runtime triage labels: since the `XYZ_PYTHON` flip the harness is dual-runtime, so any harness-bug issue gets a `runtime:` label — `runtime:python` (default path), `runtime:bash` (`XYZ_PYTHON=0` opt-out), or `runtime:parity` (the twins diverge). `/file-xyz-bug` harvests and applies it; for in-repo intake (`/triage`, hand-filed `gh issue create`) apply it by hand. Omit rather than guess — a wrong runtime tag misroutes triage.
    36	- Do not override deterministic PDDA findings with prose.
    37	- Do not report a win you did not verify with the relevant script or test.
    38	- Update `CHANGELOG.md` at the end of each iteration; its governance lives in `PROJECT/PDDA.md` — do not re-specify CHANGELOG rules in `AGENTS.md` or elsewhere.
    39	
    40	## Command rails
    41	
    42	For repo correctness:
    43	
    44	```bash
    45	./validate.sh
    46	```
    47	
    48	For document hygiene:
    49	
    50	```bash
    51	utils/pdda/pdda.sh run
    52	```
    53	
    54	For targeted PDDA debugging (subcommands of the single dispatcher):
    55	
    56	```bash
    57	utils/pdda/pdda.sh frontmatter
    58	utils/pdda/pdda.sh status-table
    59	utils/pdda/pdda.sh hardcoded-paths
    60	utils/pdda/pdda.sh roadmap
    61	utils/pdda/pdda.sh roadmap-coverage
    62	utils/pdda/pdda.sh changelog
    63	utils/pdda/pdda.sh stale
    64	utils/pdda/pdda.sh issue-doc-sync   # warn-only: flags 2-WORKING/GH-*.md docs drifted from their GitHub issue state
    65	utils/pdda/pdda.sh releases         # validate RELEASES.md, the OPTIONAL release-planning ledger (warn-only; skips a missing file)
    66	utils/pdda/pdda.sh releases-current # read-only roll-up: RELEASES.md entries whose Status isn't "Shipped"
    67	utils/pdda/pdda.sh quad-concepts    # opt-in: requires a "## Quad Concepts" section of 1-4 bullets (lever: .pdda-quad / PDDA_QUAD)
    68	utils/pdda/pdda.sh glance           # read-only roll-up: title + Quad Concepts for each PROJECT/2-WORKING doc
    69	utils/pdda/pdda.sh gh-refresh       # refresh the cached GitHub issue-state file issue-doc-sync reads offline (needs gh)
    70	utils/pdda/pdda.sh catchup          # LLM repo triage + ROUTER.md recommendations (delegates to pdda-catchup.sh)
    71	utils/pdda/pdda.sh doc-ready        # LLM readiness review — set PDDA_LLM_BIN (codex/claude/agy) for recommendations, else it self-skips
    72	```
    73	
    74	## Routing hints
    75	
    76	- If the task is about current priorities or active work, start in `ROADMAP.md`, then follow the linked `PROJECT/**` doc.
    77	- If the task is about fresh GitHub intake or duplicate-prevention, start in `ROADMAP.md`'s queue, then follow the linked `PROJECT/1-INBOX/GH-*.md` capture doc.
    78	- If the task is about document quality, active-doc lifecycle, roadmap sprawl, or automation policy, start in `PROJECT/PDDA.md`.
    79	- If the task is about the CHANGELOG, provenance, or end-of-iteration logging, the governance is in `PROJECT/PDDA.md` (the "CHANGELOG.md — end-of-iteration record" contract).
    80	- If the task is about planning or publishing a major release, start in `RELEASES.md`; governance is in `PROJECT/PDDA.md` (the "RELEASES.md — release ledger" contract). `/release-plan` authors entries, `/release` publishes an entry to GitHub.
    81	- If the task is about the `tick` runtime, event projection, or multi-agent coordination kernel, start in `README.md`, then `bin/`, `src/`, `test/`, and the active project doc.
    82	- If the task is about the **Aider ↔ OpenRouter** turn-taker lane (`relay-automation/aider-turn.sh` — an OpenAI-standard build lane discrete from Codex; `AIDER_MODEL`/`OPENROUTER_API_KEY`, `--builder aider`), start in `PROJECT/3-COMPLETED/GH-77-AIDER-OPENROUTER-LANE.md`. The shim owns the tick token ops (Aider can't run shell mid-turn), asserts token ownership before launching Aider, and runs Aider `--no-auto-commits` (the harness commits).
    83	- If the task is about running, driving, or reviewing via the relay (`relay-automation/` — `relay-drive.sh`, `poll.sh`, the turn shims, `marathon*.sh`), **invoke the `relay-xyz` skill first — do not improvise the handoff or hand-roll a harness from `ls relay-automation/`.** The skill owns the locator, sandbox rules, exit codes, and the safety boundary; a `PreToolUse` guard (`relay-automation/hooks/relay-xyz-guard.sh`) blocks driving a harness driver before the skill is loaded. For the two live-Claude-windows, same-machine duel recipe (Reporter↔Maintainer with a human go-gate), the copy-paste form is [relay-automation/DUELING-CLAUDES.md](relay-automation/DUELING-CLAUDES.md).
    84	- If the task is about the ATE (Automated Testing Environment) skill — unattended Aider variation-test fuzzing driven by a local Gemma worker under `utils/ate/` — start in `utils/ate/SKILL.md`. Currently hardcoded to Aider despite the generic name/description; generalizing it to other harnesses is tracked, not urgent, in `PROJECT/1-INBOX/GH-191-ATE-GENERALIZE-HARNESS.md`.
    85	- If the task is about relay session telemetry, the `focus5float` health feed, or extraction scripts under `utils/telemetry/`, start in `PROJECT/1-INBOX/GH-24-RELAY-TELEMETRY-EXTRACTOR.md`.
    86	- If the task is about live per-session completion telemetry — the `XYZ.json` log every relay/marathon/swarm session appends to at the harness repo root (schema: `harness`/`sessionId`/`health`/`title`/`description`/`updatedAt`), the shared writer `utils/telemetry/append-xyz-completion.sh`, or the shared health mapping `utils/telemetry/health-lib.sh` — start in `PROJECT/1-INBOX/GH-75-XYZ-JSON-COMPLETION-TELEMETRY.md`. `XYZ.json` is local + gitignored (machine-specific).
    87	- If the task is about cross-repo HQ tooling (`utils/hq/` — `hq.sh` single-repo actions, `rollup.sh` the Obsidian daily ROADMAP rollup, `marathon-scan.sh` the cross-repo marathon-preflight aggregator, `hq-lib.sh` the shared repo registry), start in `PROJECT/3-COMPLETED/GH-27-ROADMAP-DASHBOARD.md` and `PROJECT/3-COMPLETED/GH-158-HQ-MARATHON-SCAN.md`. The two rollups are deliberately separate today (`rollup.sh` → Obsidian, generic; `marathon-scan.sh` → hub repo, preflight-aware) and are not yet bridged — tracked in `PROJECT/1-INBOX/GH-192-HQ-MARATHON-OBSIDIAN-ROLLUP.md`.
    88	- If the task is about a proposed roadmap-steward agent, start here, then read `PROJECT/PDDA.md` and its `Proposed roadmap steward extension` section.
    89	- Issue-first SOP: any change beyond a 2–3 line fix (and every project plan) opens a GitHub issue *first*, then gets a pointer doc named after the issue at `PROJECT/1-INBOX/GH-<number>-VERY-SHORT-DESC.md` — e.g. `GH-1234-SHOWME-COMMAND.md` — and that capture is parked in the `ROADMAP.md` queue immediately (format + lifecycle owned by `PROJECT/PDDA.md` → "GitHub issue intake"), following the normal `1-INBOX` → `2-WORKING` flow. Genuinely trivial edits (≤2–3 line fixes, typos, path repoints, doc-only one-liners) are exempt and commit directly.

===== GUIDING-PRINCIPLES.md =====
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
    46	13. **A green gate without a witnessed red control is not evidence.** Every new or materially changed decision gate ships a recorded demonstration that it fails for the right reason: a pre-fix replay, deliberate mutation, or controlled bad fixture. Do not mistake a check that validates the artifact it just generated (#351) or a parity check that compares a lane to itself (#348) for evidence; both shapes are structurally unable to falsify their claim.
    47	
    48	## Applying this
    49	
    50	Adding a feature or weighing a tradeoff, ask: *does this keep agents coordinated without collision, contained within their scope, and verifiable to an outside observer? And is "done" provable by running `validate.sh`?* If any answer is no, reconsider.
    51	
    52	---
    53	
    54	## Conventions
    55	
    56	### Strict-mode policy (bash `set -e`)
    57	
    58	Strict mode is **per-subsystem, not repo-wide** (GH-110 P3b). The split is deliberate:
    59	
    60	- **`relay-automation/` drivers and turn shims run `set -euo pipefail`.** They orchestrate risky,
    61	  multi-step, containment-sensitive turns where a silently-ignored failure can commit off-lane or
    62	  orphan a peer. Abort-on-error (`-e`) is the correct default there.
    63	- **`utils/` analysis tools (`pdda/*`, `marathon-plan.sh`, `swarm-preflight.sh`) run `set -uo pipefail`
    64	  or `set -u`, deliberately *without* `-e`.** These are long single-pass scripts whose normal control
    65	  flow includes many expected-nonzero probes (`git rev-parse`, `gh` lookups, `grep` misses). Under
    66	  `-e` a benign "no match" would abort the whole run, so they set `-u` (catch unset vars) + explicit
    67	  per-call error handling instead. This is an exemption, not an oversight.
    68	
    69	Every currently `-e`-exempt script carries a one-line `# strict-mode: -e exempt — …` header next to
    70	its `set -` line so the exemption is self-documenting. New scripts default to `set -euo pipefail`
    71	unless they fit the analysis-tool profile above, in which case they add the exemption header.
    72	
    73	### Tool install paths — never inside another app's folder (GH-347)
    74	
    75	**This harness's tool binaries never live inside another application's private directory.** Not the
    76	worker CLIs (`codex`, `agy`, `pi`, `aider`), not `tick`, not anything the harness shells out to.
    77	
    78	The failure mode is specific and quiet: a foreign app owns its own directory, so its next update or
    79	reinstall deletes our dependency with it — on that app's schedule, with no signal we control. Worse, the
    80	readiness check cannot tell the two apart. `find-harness.sh --check` tests only whether a worker is *on
    81	PATH*, so "the neighbouring app just wiped our tool" and "never installed" produce the byte-identical
    82	line. That is the same disease as GH-315/GH-319: a broken observation layer where failure is invisible
    83	and every available signal agrees.
    84	
    85	**The `npm install -g` trap — this is how GH-347 actually happened.** npm derives its global prefix from
    86	whichever `npm` is on PATH, so a bare `npm install -g <pkg>` inherits a foreign app's runtime silently
    87	and exits 0. On the machine that filed GH-347, another agent app had symlinked its bundled Node onto PATH
    88	(`~/.local/bin/npm -> ~/.hermes/node/bin/npm`) with no `~/.npmrc` involved at all, so `pi` installed into
    89	that app's folder and — because only `node`/`npm` were symlinked out, not `pi` — was invisible to every
    90	shell while being perfectly functional. **Run `npm config get prefix` before any global install and
    91	confirm it is a path this repo's tooling owns.** Never assume.
    92	
    93	The positive pattern is already on disk in the two lanes that have never had this problem: a tool's own
    94	app directory with a symlink onto PATH (`~/.local/bin/codex -> ~/.codex/packages/…/bin/codex`), or a real
    95	binary in a shared user-local `bin`. Either is fine. Someone else's runtime is not.
    96	
    97	**Scope note:** where a *working* binary lives stays the operator's call. This is a convention and a
    98	warning, deliberately **not** a gate — a false positive that blocks a relay is worse than the papercut it
    99	prevents.
   100	
   101	### Marathon builder default & plan location (GH-212)
   102	
   103	Two vendored-harness defaults, made explicit so an agent given only the vendored bundle picks the
   104	right behavior without pattern-matching a downstream repo's prior drift:
   105	
   106	- **Builder default is `codex`, not a billed CLI.** `marathon.sh`/`marathon-drive.sh` (and the
   107	  `XYZ_PYTHON=1` port) default `--builder` to `codex` — build turns bill via the Codex/ChatGPT
   108	  subscription, not the Anthropic API (agy is the other cost-blind option). `--builder claude`
   109	  spawns a headless Claude Code CLI subprocess instead: a separate, per-call API-billed turn-taker.
   110	  Use it only as an explicit, cost-acknowledged choice — never assume it's free because an
   111	  interactive session is already running. `swarm-preflight.sh`'s suggested invocation and
   112	  `marathon.sh`'s own default now agree; don't let them drift apart again.
   113	- **A marathon's plan lives under `PROJECT/2-WORKING/`.** The `MARATHON.yaml` + its phase briefs
   114	  belong under `PROJECT/2-WORKING/<capture-doc>/` — never a standalone top-level folder (e.g.
   115	  `marathon-plans/<slug>/`). `marathon.sh --plan` enforces this: it refuses (exit 2) a plan that
   116	  resolves outside `PROJECT/2-WORKING/`, exempting only paths under the harness's own home
   117	  (`MARATHON_HOME` — shipped reference examples like `MARATHON.example.yaml`) or an explicit
   118	  `MARATHON_ALLOW_PLAN_OUTSIDE_WORKING=1` override for a genuinely non-default location.
   119	
   120	---
   121	
   122	## Appendix: AI Doc Review Heuristics
   123	
   124	When reviewing any repo doc (roadmap entries, plans, architecture notes, audits, task writeups), apply these. Priority: containment > coordination correctness > signal quality > implementation speed and operator friction.
   125	
   126	**Heuristics**
   127	
   128	1. **Containment preserved?** Any headless path that could self-commit, touch off-allowlist files, or orphan a peer commit without an explicit containment argument → reject or escalate.
   129	2. **Skill-first respected?** Any plan that bypasses `relay-xyz` or improvises the harness from scratch without the skill layer → reject. Add to the skill instead.
   130	3. **Coordination through the event log?** Reads/writes to shared state route through `tick` verbs; hard-coded state outside `.tick/` needs explicit justification.
   131	4. **Done verifiable?** Names runnable gates (`validate.sh`, specific tests, `utils/pdda/pdda.sh run`). None = low-quality signal.
   132	5. **Drift reduced, not created?** No duplicated docs, no execution detail in ROADMAP.md, no reinventing a path the event-log contract already documents.
   133	6. **Next action singular?** One explicit next step, not buried in prose; status cells non-empty.
   134	7. **Operator control explicit?** No silent retry, no auto-repair outside the bounded exit-code menu, no masked failure; destructive ops surface before executing.
   135	8. **Four pillars pass?** Each turn/output is Attested, Relevant, Fresh, Structured. Fail one → not done.
   136	
   137	**Tie-breakers**
   138	
   139	- **Containment vs speed:** choose containment; flag friction as a design question, not a shortcut.
   140	- **New relay path vs reuse:** extend the existing skill and harness over forking a parallel path; if the harness can't accommodate it, surface the gap.
   141	- **Ambitious vs resumable:** a shorter plan an agent can resume cold beats a comprehensive one that buries state in prose.
   142	
   143	**Reject or escalate when**
   144	
   145	- A headless path has no allowlist, no worktree isolation, and no commit-bypass guard — and the doc doesn't justify why.
   146	- "Done" has no runnable verification step.
   147	- Adding a new relay lane requires editing the event-log kernel or the `tick` verb schema without a decision record under `decisions/`.
   148	- Hardcoded absolute paths, silent destructive operations, or opaque epoch-fence assumptions.
   149	- ROADMAP.md would need execution detail to make the plan legible.

===== PROJECT/PDDA.md =====
     1	# Project-Driven Doc Automation (PDDA)
     2	
     3	PDDA is the document operating layer for this repo. Its job is to keep project plans, bug-fix docs,
     4	research notes, and roadmap pointers clean enough that an agent can pick up work with minimal drift
     5	and enough structure that routine hygiene can be automated instead of re-decided every session.
     6	
     7	The core idea is simple:
     8	
     9	- deterministic scripts enforce the parts that should never require judgment
    10	- an LLM reviewer flags structural or planning-quality gaps that are hard to express as regex alone
    11	- `ROADMAP.md` stays a pointer/index, while project detail lives in the individual project docs
    12	
    13	## Goals
    14	
    15	- Keep `PROJECT/2-WORKING` limited to docs that are truly active.
    16	- Ensure every active doc answers two questions at a glance: what was just completed, and what is next.
    17	- Make phased plans automation-ready by requiring explicit QA gates.
    18	- Prevent plan rot: stale files, missing next steps, hardcoded paths, and hidden scope drift.
    19	- Give agents one repeatable contract for project docs, bug-fix docs, and experimental plans.
    20	
    21	## Non-goals
    22	
    23	- PDDA does not replace the project docs themselves.
    24	- PDDA does not decide product strategy.
    25	- PDDA does not auto-rewrite nuanced plan content without review.
    26	- PDDA does not turn `ROADMAP.md` into a second execution plan.
    27	
    28	## Canonical document model
    29	
    30	PDDA assumes four lifecycle buckets:
    31	
    32	- `PROJECT/1-INBOX`: new ideas, rough proposals, untriaged notes
    33	- `PROJECT/2-WORKING`: active docs that should be updated as work progresses
    34	- `PROJECT/3-COMPLETED`: completed docs with an outcome
    35	- `PROJECT/4-MISC`: reference, stale, superseded, or abandoned docs
    36	
    37	Within that model:
    38	
    39	- `ROADMAP.md` is the index of current, completed, attempted, and deferred work
    40	- project detail lives in the individual `PROJECT/**` documents
    41	- a working doc is the canonical source of truth for that effort until it is completed, deferred, or superseded
    42	- `blank.md` placeholders are scaffolding and should be ignored by PDDA checks
    43	
    44	## Required contract for active docs
    45	
    46	Every doc in `PROJECT/2-WORKING` should have:
    47	
    48	1. YAML frontmatter with at least `title`, `status`, `created`, `updated`, `owner`, and `goal`
    49	2. a near-top status table with the exact columns:
    50	
    51	```md
    52	## Status
    53	
    54	| What was just completed | What's next |
    55	|---|---|
    56	| ... | ... |
    57	```
    58	
    59	3. clear phase or work sections if the doc is a plan
    60	4. a table of contents (`## Table of contents`) listing each phase, if the plan is multi-phase — so a
    61	   cold agent can see the full phase span and jump to the live one without scrolling the whole body
    62	5. QA gates or acceptance criteria after each phase if the plan is multi-phase
    63	6. for any discovery or spike phase, its findings written **back into this doc** before its QA gate can
    64	   pass (see [Discovery & spike phases (Memory Injection)](#discovery--spike-phases-memory-injection))
    65	7. repo-relative paths only; no hardcoded absolute local paths
    66	8. before moving to `PROJECT/3-COMPLETED`, a `## Lessons Learned (For Future Agents)` section appended to capture quirks and gotchas
    67	
    68	Recommended fields when relevant:
    69	
    70	- `related`
    71	- `context_tags` (e.g. `[auth, flaky-tests, build]`)
    72	- `reviewed`
    73	- `branch`
    74	- `non_goals`
    75	- `gh_issue`
    76	- `effort`, `complexity`, `risk`, `phases` — triage ratings; **required for medium-large work** (see
    77	  [Triage ratings for medium-large work](#triage-ratings-for-medium-large-work))
    78	
    79	## Quad Concepts (opt-in)
    80	
    81	An **opt-in** glance layer, **off by default**. The `## Status` table says *where* the work is; Quad
    82	Concepts says *what* it is — a 5-second read of the core problems a plan tackles and how, so an operator
    83	can see whether the real pain points are covered. (Distinct from `context_tags`: those are for search;
    84	this is for glance.)
    85	
    86	When enabled system-wide via the `.pdda-quad` lever (or the `PDDA_QUAD` env var — **orthogonal** to the
    87	enforcement mode), tracked plan docs must carry a `## Quad Concepts` section of **1–4 bullets**,
    88	conventionally right after `## Status`:
    89	
    90	```md
    91	## Quad Concepts
    92	- <pain the doc addresses> → <how it addresses it>
    93	```
    94	
    95	- **Shape (deterministic):** 1–4 **top-level, non-empty** `-`/`*` bullets in the first `## Quad Concepts`
    96	  section. `pain → fix` phrasing is the convention (nudged by the LLM readiness rubric), not a hard regex.
    97	- **Scope:** `PROJECT/2-WORKING`, `PROJECT/1-INBOX/GH-*.md`, and `PROJECT/3-COMPLETED` (the last keeps a
    98	  glanceable summary for cold-start recall). `PROJECT/4-MISC` is out.
    99	- **Enable:** set `.pdda-quad` to `on` (or `PDDA_QUAD=1`). The enforcement mode still governs whether a
   100	  missing/malformed section merely reports or blocks. **Opt a doc out** with `quad_exempt: true`.
   101	- Enforced by `pdda.sh quad-concepts` (deterministic, structure-only) plus a warn-only readiness rubric.
   102	- `pdda.sh glance` (read-only, always available) rolls up `title + Quad Concepts` across `2-WORKING` for
   103	  a one-screen view of what the active portfolio is addressing.
   104	
   105	## Triage ratings for medium-large work
   106	
   107	So automation can pick *which* task to pursue without re-reading every plan, every newly recorded
   108	**medium-large** task or project carries four triage fields in its frontmatter:
   109	
   110	| Field | Range | Meaning |
   111	|---|---|---|
   112	| `effort` | integer `1`–`5` | how much work — `1` low, `5` highest |
   113	| `complexity` | integer `1`–`5` | how intricate / how many moving parts — `1` low, `5` highest |
   114	| `risk` | integer `1`–`5` | blast radius + uncertainty — `1` safe/contained, `5` one-way-door or unknown |
   115	| `phases` | positive integer | total number of phases in the plan |
   116	
   117	```yaml
   118	effort: 2
   119	complexity: 3
   120	risk: 1
   121	phases: 4
   122	```
   123	
   124	`risk` should track the repo's existing reversibility scale (`Easy / Costly / One-way door`,
   125	`AGENTS.md` #3): `1`–`2` ≈ Easy, `3` ≈ Costly, `4`–`5` ≈ one-way door / high uncertainty. It is not a
   126	parallel notion of danger — it is that scale expressed as a number.
   127	
   128	**Scope.** Required for medium-large work (project plans, experiments, features, multi-phase efforts).
   129	Genuinely small/trivial docs (a typo, a path repoint, a ≤2–3 line bug-fix — the same floor as the
   130	issue-first SOP) do not need them. "Medium-large" is a judgment, so *presence* is enforced by the LLM
   131	layer, not a regex (below).
   132	
   133	### How to combine them — derive, don't store
   134	
   135	There is deliberately **no stored composite "score" field.** A frozen aggregate would (a) drift from
   136	the three numbers it came from, violating Principle #4 (*one canonical place per fact*), and (b) bake a
   137	weighting choice into every doc that you then cannot re-tune without rewriting them. Compute the
   138	selection signal **live, at selection time**, from the raw fields:
   139	
   140	- **`risk` is a gate, not an addend.** A trivial-but-risky task (`effort 1`, `complexity 1`, `risk 5`)
   141	  is easy to *do* but exactly what automation should not auto-pick — folding risk into a linear sum
   142	  lets it slip through mid-ranked. Gate on it instead.
   143	- **`effort` and `complexity` are correlated** (complex work is usually effortful), so summing them is
   144	  a rough "size" proxy, not two independent signals — treat the sum as one ease axis, not two.
   145	
   146	Reference selection rule (tune the thresholds per repo):
   147	
   148	```text
   149	eligible      = risk <= 2 AND not ratings_provisional   # safety gate; risk >= 4 => route to a human
   150	ease          = effort + complexity       # 2..10, lower = easier
   151	pick          = among eligible, lowest ease, then fewest phases as the tiebreak
   152	```
   153	
   154	`ratings_provisional: true` is an **eligibility gate, not just metadata.** Auto-drafted intake (e.g.
   155	the `/idea` skill) ships best-guess ratings marked provisional; a rough `risk: 2` guess on a large
   156	effort must **not** become auto-selectable on the strength of that guess. So a provisional doc is held
   157	out of auto-selection until a human confirms the ratings and clears the flag — the same "route to a
   158	human" posture as `risk >= 4`.
   159	
   160	This keeps the raw ratings canonical and queryable while letting the "what's the easiest *safe* thing
   161	to grab" logic live in one place that can evolve. (See the resolved `priority` note under
   162	[Proposed extensions](#proposed-extensions-not-yet-locked).)
   163	
   164	### How this is enforced
   165	
   166	- **deterministic (values)** — `pdda.sh frontmatter` validates the fields **only when present**:
   167	  `effort`/`complexity`/`risk` must be integers `1`–`5`, `phases` a positive integer. A present-but-bad
   168	  value is unambiguous, so it `error`s. The script does **not** force presence — it cannot know whether
   169	  a doc is "medium-large."
   170	- **LLM (presence)** — `pdda-doc-ready.sh` flags a medium-large plan that is *missing* the triage
   171	  ratings. Whether a doc is medium-large is a judgment, so it stays advisory/warn-capped like every
   172	  other readiness finding.
   173	
   174	## Why the two-column status header matters
   175	
   176	The status table is the front door for both humans and automation.
   177	
   178	- The left column is the last verified state change.
   179	- The right column is the next action.
   180	- If either is missing, an agent has to reconstruct state from the body, which is slow and error-prone.
   181	
   182	PDDA therefore treats the exact header names as a contract, not a style preference. The header must be
   183	exactly `What was just completed | What's next` — there is no alias/compatibility window. (One was
   184	specced with a `2026-07-31` cutover, but a single-repo system controls its own docs: no doc here used
   185	an old alias, so a dated, silently-changing branch guarded nothing and was removed 2026-06-22.)
   186	
   187	## Discovery & spike phases (Memory Injection)
   188	
   189	Discovery and spike phases exist to *learn* — reverse-engineer an existing system, probe an unknown,
   190	prove or kill a risky approach before committing the plan to it. Their output is durable **memory**, and under
   191	Principle #1 (*docs are the runtime state, not a record of it*) that knowledge is project state. If it
   192	lives only in an agent's context or a throwaway scratch note, a cold agent resuming the plan cannot see
   193	what was learned, why a path was chosen or abandoned, or what the spike actually proved — and the work
   194	gets re-done.
   195	
   196	Contract: **a phase tagged as discovery or spike must write its findings back into the originating plan
   197	doc before its QA gate can pass.** This is active memory injection. Concretely, that phase's section (or a clearly linked sibling
   198	section in the same doc) must capture:
   199	
   200	- **what was investigated** — the system/area reverse-engineered or the question the spike asked
   201	- **what was found (quirks, gotchas, mechanics)** — the concrete mechanics learned, with repo-relative pointers (`file:line`) where
   202	  the finding lives in code, not a vague summary
   203	- **what it changes** — how the finding confirms, redirects, or kills the plan's later phases; an
   204	  unfinished "we'll know after the spike" left dangling is itself the gap
   205	
   206	This satisfies Principle #4 (*one canonical place per fact*): the originating plan is that place. A
   207	spike whose findings sit in chat is the exact drift PDDA exists to prevent. The QA gate for a
   208	discovery/spike phase therefore includes "findings are written back to this doc" as an acceptance
   209	criterion alongside the phase's normal checks.
   210	
   211	Enforcement is **advisory (LLM layer, warn-capped)** — `pdda-doc-ready.sh` flags a discovery/spike
   212	phase whose findings were not written back. "Did the agent actually capture what it learned" is a
   213	judgment a regex cannot make honestly, so it stays with the LLM reviewer and, like every finding from
   214	that layer, never blocks a build (see [LLM-assisted doc readiness review](#2-llm-assisted-doc-readiness-review)).
   215	To tag a phase, name it plainly (e.g. `## Phase 2 — Discovery: …` / `## Phase 3 — Spike: …`) or set
   216	`doc_type: research` / a phase-level marker the reviewer can see.
   217	
   218	## Bug-fix doc stance
   219	
   220	Bug-fix docs may use a lighter template than multi-phase project plans, but they still need:
   221	
   222	- the minimum frontmatter
   223	- the same `## Status` table while active
   224	- a short bug description
   225	- source of truth for intake, including a GitHub issue when relevant
   226	- verification steps
   227	
   228	GitHub issues are the default intake for substantive bug reports (issue-first SOP — see below). They are not a
   229	substitute for the local active-work doc once execution starts in this repo.
   230	
   231	## GitHub issue intake
   232	
   233	GitHub issues are the **default front door** for substantive work — every project plan and every
   234	non-trivial bug/fix opens an issue *first*, and that issue gets an in-repo pointer doc. The signal
   235	stream lives in GitHub (machine-queryable state, labels, commit↔issue linkage); the execution
   236	surface of record stays in `PROJECT/**`. This is the **issue-first SOP**; the bug-fix stance above
   237	states the principle, and this section owns the *format*. To prevent duplicate intake and forgotten
   238	work, every captured `GH-*.md` doc is also **parked immediately in `ROADMAP.md`** as a one-line queue
   239	entry until it is promoted, deferred, or closed.
   240	
   241	**Floor (what needs an issue).** The operational test is **lines of code touched**: any change
   242	beyond a **2–3 line** fix opens a GitHub issue first, and its local plan doc is named after that
   243	issue (see Filename below). Project plans, experiments, and features are always above this line.
   244	**Exempt:** genuinely trivial edits — a ≤2–3 line code fix, a typo, a path repoint, a doc-only
   245	one-liner, formatting — commit directly with a clear message and no issue. When in doubt, open the
   246	issue — it is a cheap `gh issue create`. The SOP applies to *new* efforts going forward; in-flight
   247	`1-INBOX`/`2-WORKING` docs are not backfilled.
   248	
   249	Capture a tracked issue as a doc in `PROJECT/1-INBOX/` using this convention:
   250	
   251	- **Filename:** `GH-<number>-VERY-SHORT-DESCRIPTION.md` — the local plan doc is always named after
   252	  its GitHub issue (e.g. `GH-1234-SHOWME-COMMAND.md`, `GH-11-CROSS-REPO-TARGETING.md`). Keep the
   253	  description to ~2–4 words; the issue number is the real key, the slug is just a human hint.
   254	  SCREAMING-KEBAB to match the other inbox docs; no zero-padding — mirror the GitHub issue number.
   255	  `<number>` resolves against `origin` (a single canonical repo), so the bare number is unambiguous.
   256	- **Minimum frontmatter:** `gh_issue`, `source` (the full issue URL), `title`, `status`
   257	  (`Proposed (1-INBOX — not yet active)`), `created`, and `doc_type` (`feedback` or `bugfix`).
   258	  For medium-large captures, also include the triage ratings `effort`, `complexity`, `risk`, `phases`
   259	  at capture time, so the queue can be triaged before promotion (see
   260	  [Triage ratings for medium-large work](#triage-ratings-for-medium-large-work)).
   261	- **Body:** transcribe the issue's actionable substance (the asks / acceptance criteria), not the whole
   262	  thread. The live issue stays the discussion surface; this doc is the in-repo capture and back-reference.
   263	
   264	Lifecycle:
   265	
   266	- The `GH-` inbox doc is the **capture**, not the active-work doc. It carries no `## Status` table while
   267	  it sits in `1-INBOX` (the inbox is the rough/untriaged bucket).
   268	- Capture time also adds a **one-line `ROADMAP.md` queue pointer** linking that inbox doc. This is a
   269	  temporary parking slot: it makes fresh intake visible to humans and automation before promotion,
   270	  which is the duplicate-prevention guard.
   271	- When execution starts, **promote** it to `PROJECT/2-WORKING/` — keep the `GH-` prefix for provenance —
   272	  and it must then satisfy the full active-doc contract (frontmatter, exact status table, QA gates if
   273	  phased), **carrying `gh_issue` forward**. The `ROADMAP.md` pointer is therefore required twice:
   274	  first as a queued parking entry at capture, then as an active-work ledger entry after promotion.
   275	  This is the concrete mechanism behind "GitHub issues are not a substitute for the local active-work
   276	  doc once execution starts" (bug-fix stance above).
   277	- If a captured issue is never actioned it ages out of `1-INBOX` like any other untriaged note; if it is
   278	  closed without work, move the doc to `PROJECT/4-MISC` and remove its queue pointer from `ROADMAP.md`.
   279	
   280	A foreign-repo issue (not `origin`) is the rare exception: the `source:` URL disambiguates it, since the
   281	bare `GH-<number>` only guarantees uniqueness within the canonical repo.
   282	
   283	## Automation layers
   284	
   285	PDDA should have two classes of automation:
   286	
   287	Implementation note:
   288	
   289	- the automation ships as a single dispatcher, `utils/pdda/pdda.sh`, which sources shared helpers from
   290	  `utils/pdda/pdda-lib.sh`
   291	- every deterministic check is a subcommand: `pdda.sh frontmatter`, `pdda.sh status-table`,
   292	  `pdda.sh hardcoded-paths`, `pdda.sh roadmap`, `pdda.sh roadmap-coverage`, `pdda.sh changelog`,
   293	  `pdda.sh stale`, `pdda.sh issue-doc-sync`, `pdda.sh governance`
   294	- the aggregate runner is `pdda.sh run` (it runs the deterministic checks in order, then the LLM
   295	  review)
   296	- each finding still carries a stable `check` id (e.g. `pdda-check-frontmatter`) in stdout and the
   297	  activity log, independent of how the check is invoked
   298	- **`run` reports what it found, not what it blocked on.** The mode gate forces every check's exit code
   299	  to `0` outside `full`, so the closing line has three outcomes, not two: *all checks passed* (nothing
   300	  found), *N error(s) found, not blocking in `<mode>` mode* (found, gate suppressed the failure), and
   301	  *failures:* (found and blocked). Warnings never move the run out of the first state — a `warn` is the
   302	  house-style advisory, and letting it read as failure would collapse the distinction. Inferring success
   303	  from the gated exit code was BUG-001b: `run` printed *all checks passed* over real errors in `observe`
   304	  and `light`, which are precisely the modes a new adopter starts in. The LLM readiness review is gated
   305	  on the same signal, so an error-laden repo never spends an LLM call. **The rule:** a check that could
   306	  not run — or could not block — must never be scored as a check that passed.
   307	
   308	### 1. Deterministic hygiene checks
   309	
   310	These catch issues where the answer should be the same every time.
   311	
   312	#### A. `pdda.sh stale`
   313	
   314	Purpose:
   315	- inspect docs in `PROJECT/2-WORKING`
   316	- detect stale docs based on file modification time
   317	- **flag** them for a human to move (this check never moves files itself)
   318	
   319	Minimum behavior:
   320	- find docs in `PROJECT/2-WORKING` whose last edit is older than 4 days
   321	- emit a `warn` finding per stale doc recommending the exact `git mv` to `PROJECT/4-MISC`
   322	- honor a `pdda_hold: true` frontmatter override (skip the flag for held docs)
   323	- log every flag to the activity log; **never** auto-move, so this check can never block a build
   324	
   325	Why flag-only (design call, 2026-06-22):
   326	- the auto-move was the repo's only destructive mechanic, and the activity log showed it never once
   327	  fired a real move. The value is the flag; the move is risk with no proven payoff — a human runs one
   328	  reversible `git mv`. mtime staleness is a deliberately loose signal, and flag-only makes a wrong
   329	  guess cost nothing but an ignorable line. An opt-in move can be re-added later behind `pdda_hold` +
   330	  `full` mode if it ever earns the miles.
   331	
   332	#### B. `pdda.sh status-table`
   333	
   334	Purpose:
   335	- verify every doc in `PROJECT/2-WORKING` contains the exact two-column status table
   336	
   337	Minimum behavior:
   338	- fail if the `## Status` section is missing
   339	- fail if the table headers are not exactly `What was just completed` and `What's next`
   340	- fail if either first-row cell is blank
   341	
   342	#### B2. `pdda.sh quad-concepts` (opt-in)
   343	
   344	Purpose:
   345	- when the `.pdda-quad` / `PDDA_QUAD` lever is on, verify each in-scope plan doc carries a
   346	  `## Quad Concepts` section of 1–4 bullets (see [Quad Concepts (opt-in)](#quad-concepts-opt-in))
   347	
   348	Minimum behavior:
   349	- scope: `PROJECT/2-WORKING` + `PROJECT/1-INBOX/GH-*.md` + `PROJECT/3-COMPLETED`; skip `quad_exempt: true`
   350	- parse the first `## Quad Concepts` section; count top-level, non-empty `-`/`*` bullets (skip fenced
   351	  code, indented/nested and empty bullets; stop on the next h1/h2 or a blank line after a bullet)
   352	- fail if the section is missing, has 0 bullets, or has more than 4
   353	- **structure-only** — bullet *quality* (are they real `pain → fix` concepts?) is a warn-only job for
   354	  the LLM readiness rubric, not this deterministic check
   355	- runs standalone always; joins `pdda.sh run` only when the lever is enabled (orthogonal to the mode)
   356	
   357	#### C. `pdda.sh frontmatter`
   358	
   359	Purpose:
   360	- ensure active docs expose the minimum machine-readable metadata
   361	
   362	Minimum behavior:
   363	- verify required keys exist
   364	- flag empty required values
   365	- flag invalid or missing dates
   366	- when the triage ratings are present, validate their values — `effort`/`complexity`/`risk` must be
   367	  integers `1`–`5`, `phases` a positive integer (presence itself is judged by the LLM layer; see
   368	  [Triage ratings for medium-large work](#triage-ratings-for-medium-large-work))
   369	
   370	#### D. `pdda.sh hardcoded-paths`
   371	
   372	Purpose:
   373	- catch absolute machine-specific paths before they fossilize into plans
   374	
   375	Minimum behavior:
   376	- scan working docs for obvious absolute paths such as `/Users/`, `/private/`, `/tmp/`, drive-letter paths, or `file://`
   377	- report file + line for each hit
   378	
   379	Expected exceptions:
   380	- quoted terminal output
   381	- explicitly marked transcript blocks
   382	
   383	#### E. `pdda.sh roadmap`
   384	
   385	Purpose:
   386	- enforce the `ROADMAP.md` pointer/ledger contract deterministically (the cheap, hourly guard that
   387	  does not need an LLM), so detail cannot silently leak back into the roadmap
   388	
   389	Minimum behavior:
   390	- scan `ROADMAP.md` (override via `PDDA_ROADMAP`)
   391	- `error` on any GFM task-list item (`- [ ]` / `- [x]`) — a ledger carries no task checkboxes
   392	- `error` on any `### Checklist` / `### QA checklist` heading — phase/QA detail belongs in the project doc
   393	- `warn` when the file exceeds a line-count / heading-count budget (sprawl signal)
   394	
   395	Expected exceptions:
   396	- fenced `console` / `text` / `transcript` blocks and blockquote lines (the carve-out exception note)
   397	  are not scanned — same convention as `pdda.sh hardcoded-paths`
   398	
   399	The fuzzy judgment ("deep execution notes that belong elsewhere") stays with the LLM layer below; this
   400	script only catches the unambiguous signals.
   401	
   402	#### F. `pdda.sh changelog`
   403	
   404	Purpose:
   405	- nudge that `CHANGELOG.md` (the first-class end-of-iteration record) was updated this iteration
   406	
   407	Minimum behavior:
   408	- read `CHANGELOG.md` (override via `PDDA_CHANGELOG`); find the newest dated heading, accepting both
   409	  `## YYYY-MM-DD` and `## [x.y.z] - YYYY-MM-DD`
   410	- `warn` (never `error` — does not block, even in `full`) when that entry predates the latest git
   411	  commit by more than `PDDA_CHANGELOG_STALE_DAYS` days (default `0`)
   412	- `warn` if `CHANGELOG.md` is missing or has no dated entry; emit `info` (skip the compare) when there
   413	  is no git history
   414	
   415	Why warn-only:
   416	- "did you update the changelog" is a reminder, not a correctness gate — blocking a build because a
   417	  human hasn't written the prose yet is the wrong kind of friction (the calibration principle)
   418	
   419	#### G. `pdda.sh roadmap-coverage`
   420	
   421	Purpose:
   422	- enforce the *coverage* direction of the `ROADMAP.md` contract: every active doc in `PROJECT/2-WORKING`
   423	  must be reflected by a pointer in `ROADMAP.md`, so the ledger can never silently fall behind the
   424	  working set. This is the inverse of `pdda.sh roadmap` (which keeps execution detail from leaking
   425	  *into* the roadmap); together they guard the pointer/working-set relationship in both directions.
   426	
   427	Minimum behavior:
   428	- list the working docs (`PROJECT/2-WORKING/*.md`, `blank.md` excluded)
   429	- `error` on any working doc whose repo-relative path (`PROJECT/2-WORKING/<name>.md`) does not appear in
   430	  `ROADMAP.md` (override the roadmap location via `PDDA_ROADMAP`) — the action is "add a one-line ledger
   431	  entry linking it"
   432	- `error` if `ROADMAP.md` is missing entirely
   433	
   434	Expected exceptions:
   435	- a working doc that should not appear in the ledger opts out with `roadmap_exempt: true` in its
   436	  frontmatter (mirrors the `pdda_hold` escape hatch in `pdda.sh stale`); the check then
   437	  emits `info` (skip) for that doc
   438	
   439	#### H. `pdda.sh issue-doc-sync`
   440	
   441	Purpose:
   442	- catch a tracked plan doc whose recorded state has drifted from its **GitHub issue**, in either
   443	  direction — the gap a 2026-06-29 manual reconciliation pass had to cross-reference by hand
   444	
   445	Scope: **both** `PROJECT/2-WORKING/` (active plans) and `PROJECT/3-COMPLETED/` (finished plans). The
   446	completed bucket is not optional. Scanning `2-WORKING` alone means the check stops watching a doc at the
   447	exact moment it completes — so the `git mv` that drift (a) recommends is what blinds it, and the issue is
   448	orphaned forever (GH-27).
   449	
   450	Minimum behavior:
   451	- for each doc in either bucket, resolve its issue number from the `gh_issue` frontmatter key (preferred)
   452	  or the `GH-<number>-` filename; silently skip docs that carry neither (they are not issue-tracked)
   453	- resolve each issue's state from the best available source (see gh-degrade below), then flag:
   454	  - **(a)** issue **CLOSED** but the doc is still in `2-WORKING` -> `warn`, recommending the exact
   455	    `git mv` to `PROJECT/3-COMPLETED` (flag-only; a human runs the one reversible move)
   456	  - **(b)** issue **OPEN** but the doc's `status:` lead word declares it done (`complete`, `done`,
   457	    `shipped`, `fixed`, `closed`, `merged`, `resolved`, `landed`) -> `warn` to reconcile. Anchoring on the
   458	    status **lead word** means a mid-status mention like `Active — Phase 0 complete` never false-flags.
   459	  - **(b2)** issue **OPEN** but the doc's `status:` carries an explicit hand-off phrase anywhere
   460	    (`ready to close`, `ready for 3-completed`, `awaiting close`) -> `warn`. Signal (b) alone is defeated
   461	    by a self-contradictory status such as `Active — Phases 1-4 complete … Ready to close to 3-COMPLETED`:
   462	    every human reads that as done; the lead word is `active`. The phrase list stays short and literal —
   463	    a general "does this prose mean done?" parse is the false-positive machine the lead-word anchor exists
   464	    to avoid.
   465	  - **(c)** doc is in `3-COMPLETED` but the issue is **OPEN** -> `warn`, recommending `gh issue close <n>`.
   466	    The lifecycle bucket is a deterministic signal; the status prose is not. `3-COMPLETED/` *is* the
   467	    operator's assertion that the work is done, recorded in a path and verifiable with `test -f`.
   468	    A doc in `3-COMPLETED` with a **CLOSED** issue is the fully reconciled end state: no finding.
   469	- `warn` (never `error` — does not block, even in `full`, mirroring `pdda.sh changelog`); **flag-only**,
   470	  never moves a file and never closes an issue
   471	- gh-degrade: with `PDDA_ISSUE_SYNC_SOURCE=auto` (default) it uses live `gh` when that succeeds, else a
   472	  cached state file (`PDDA_GH_STATE_CACHE`). `gh`/`cache` force one source. **A successful live lookup
   473	  writes the cache** (best-effort, atomic), so the offline consumers — chiefly the `Stop` hook — have
   474	  last-known state without a network call. When neither source yields a state, the affected doc emits a
   475	  `warn` saying the sync was **NOT evaluated**: a check that could not run is not a check that passed.
   476	
   477	Why warn-only + flag-only:
   478	- every drift class here is mechanical, so the check carries zero false-judgment risk; a false flag is
   479	  one ignorable warn line and a missed flag just leaves today's manual reconciliation — both cheap, so
   480	  warn-only never-blocks is the right calibration (same stance as `pdda.sh stale` and `pdda.sh changelog`)
   481	- closing an issue is a **human judgment** about whether the work is genuinely done, so no script does it.
   482	  The `Stop` hook names the wrap (`/pdda-eod`) when this check reports reconciliation drift; the skill
   483	  proposes, the operator confirms. Detect deterministically, act only with a yes.
   484	
   485	#### I. `pdda.sh governance`
   486	
   487	Purpose:
   488	- evaluate the repo's own governance docs — `ROUTER.md`, `AGENTS.md`, `GUIDING-PRINCIPLES.md`,
   489	  `README.md`, `CLAUDE.md`, `PROJECT/PDDA.md`, `utils/pdda/PDDA-INSTALL.md` — for the specific class of
   490	  drift that Principle #4 (*one canonical place per fact*) exists to prevent: a doc pointing at a file
   491	  that has moved or never existed, a doc that exists but no cold agent's read order will ever reach it,
   492	  or a contract doc and the shipped code silently disagreeing about what commands or env vars exist
   493	
   494	Minimum behavior (four checks, one shared `pdda-check-governance` id):
   495	- **dead references** (`warn`) — every filename ending in `.md` **or `.sh`** named inside a governance
   496	  doc must resolve to a real file, checked against the repo root or (for `./`/`../` links) the
   497	  referencing file's own directory. A bare filename
   498	  with no directory component (e.g. `blank.md`,
   499	  which legitimately exists once per lifecycle folder) additionally falls back to a repo-wide basename
   500	  search before being called dead — only a name absent *everywhere* is flagged. A `GH-<n>-*.md` name is
   501	  never flagged; those are illustrative instances of the issue-doc naming convention, not fixed
   502	  cross-references. `warn`, not `error`: prose extraction is inherently more heuristic than the
   503	  mechanical checks above, so a false flag should cost one ignorable line, not a blocked build (same
   504	  calibration as `pdda.sh stale`/`pdda.sh changelog`).
   505	  - **Three extraction patterns** (union, then deduplicated): the target of a markdown link; a code span
   506	    that contains nothing but the path; and **command-position paths** — a script token that opens a code
   507	    span or a scanned fence line. The third exists because a router's most load-bearing references are
   508	    the commands it tells an agent to run, and those carry arguments, so they close neither a link nor a
   509	    backtick span right after the suffix. A vendored harness script invoked with a `--help` flag inside a
   510	    code span, and a bare sync-tool invocation with its subcommand inside a scanned ` ```bash ` fence,
   511	    both name a real file and matched nothing before GH-23 P3. Command position — line start, or
   512	    immediately after a backtick — is where a shell command's *program* sits; a script name appearing
   513	    later in a sentence is prose, and is not extracted. That is what keeps a documented invocation such
   514	    as `pdda.sh run` from being read as two separate references. A leading `./` is stripped, because in
   515	    command position it means "from the repo root I am standing in", not "relative to this doc".
   516	  - **Suffix widening was not free.** `.sh` references are the ones that differ most between the canonical
   517	    repo and a target, so the exemption manifest below had to grow with them — a fresh install went from
   518	    0 to 46 self-inflicted warns before it did. A ref to a script that exists only on the operator's
   519	    `PATH` (never in the repo) is a known, accepted false positive; it costs one advisory warn.
   520	  - **GH-15 shipped-doc exemption manifest:** `utils/pdda/PDDA-INSTALL.md` and `PROJECT/PDDA.md` ship
   521	    to every target install (`PDDA_GOV_SHIPPED_DOCS_DEFAULT`) but legitimately reference files
   522	    `install.sh` deliberately does not copy there — the target's own repo-authored startup docs
   523	    (`ROUTER.md`, `AGENTS.md`, `GUIDING-PRINCIPLES.md`, `README.md`, `CLAUDE.md`), canonical-only skill and
   524	    companion-doc paths (`.claude/skills/pdda/SKILL.md`, `.claude/skills/governance-audit/SKILL.md`,
   525	    `PROJECT/3-COMPLETED/PDDA-SYNC-TO-OTHER-REPOS.md`), and the pre-`utils/pdda/` legacy layout path
   526	    (`utils/PDDA-INSTALL.md`, named only in migration-note prose). A fresh `install.sh . --mode observe`
   527	    self-inflicted ~30 dead-reference/env-var warns from exactly this mismatch on its very first
   528	    `pdda.sh run`, drowning a new adopter's own repo drift in PDDA-on-PDDA noise. The dead-reference scan
   529	    skips a match against `PDDA_GOV_SHIPPED_DOC_REF_EXEMPTIONS_DEFAULT`, scoped strictly to the docs in
   530	    `PDDA_GOV_SHIPPED_DOCS_DEFAULT` — a repo-authored governance doc (e.g. this canonical repo's own `ROUTER.md`)
   531	    referencing one of these is still a real dead-reference bug and is never exempted. The manifest was
   532	    built from an actual dead-reference scan of a bare `install.sh` target, not retyped from an issue's
   533	    illustrative list — re-run that scan if the shipped-doc set or its prose changes materially.
   534	    **GH-17 (resolved separately from this manifest):** this file's own "CHANGELOG.md" section used to
   535	    dead-reference two specific filenames (a retired recap note, a compliance-observations file) that
   536	    turned out to be artifacts of the repo this contract doc was originally adapted from, never real
   537	    files in this standalone PDDA repo. Naming them here was a copy-paste leftover, not a real PDDA
   538	    requirement — genericized below rather than exempted, since a name that's dead *everywhere* is a
   539	    real accuracy bug (Principle #4), not an install-boundary false positive like the manifest above.
   540	  - **GH-23 P3 additions to the same manifest**, each read off a real scan of a bare
   541	    `--with-startup-docs` target (46 warns before, 0 after), in three groups:
   542	    canonical-only **tools** a target never receives (the installer itself; the sync engine, which
   543	    `pdda-sync-manifest.conf` excludes because targets are leaf nodes; `templates/`; `test/`);
   544	    **legacy flat-layout paths** (`utils/pdda.sh`, `utils/pdda-lib.sh`, …) that the install manifest names
   545	    *precisely because they must not exist* — it documents the layout `install.sh` migrates away from,
   546	    and their `.md` sibling was already exempt for this reason; and `config.sh`, which belongs to
   547	    git-pulse, a separate program.
   548	    **Known separate issue, not covered by this manifest:** this file's own CHANGELOG section
   549	    dead-references the retired RECAP note-file and the REAL-AGENT-OBSERVATIONS compliance-findings
   550	    file (see the "CHANGELOG.md" section below), neither of which exist anywhere in this repo, not
   551	    even the canonical repo — a pre-existing doc-accuracy drift unrelated to the install-omission pattern above; left
   552	    flagged rather than silently exempted pending a human decision on those files' fate.
   553	- **orphan governance docs** (`warn`) — a present governance doc whose filename never appears anywhere
   554	  in the index doc (`ROUTER.md` by default) — a doc a cold agent's startup sequence would never surface.
   555	- **subcommand drift** (`error`) — every subcommand in `utils/pdda/pdda.sh`'s dispatcher `case` block
   556	  must be named somewhere in the index doc. Parsing the `case` statement is mechanical (zero prose
   557	  ambiguity), so this earns the same blocking severity as the structural checks — it is the concrete
   558	  enforcement of AGENTS.md #5 ("keep the installer surface in lockstep").
   559	- **env-var drift** (`warn`) — every `PDDA_*` token mentioned in a governance doc should actually be
   560	  read or set somewhere in a shipped script (`utils/pdda/*.sh` or the repo-root `install.sh`). `warn`,
   561	  not `error`: `utils/pdda/PDDA-INSTALL.md` ships to every target install but also documents
   562	  `utils/pdda/pdda-sync.sh` — a canonical-only tool never copied to targets (it isn't in the "Canonical
   563	  install set" above) — so a var like `PDDA_SYNC_BACKUPS` legitimately won't resolve in a target
   564	  install's own scripts. That's expected, not drift, confirmed by installing this check into a second
   565	  repo and seeing exactly that false positive fire — same calibration as dead-reference above.
   566	  - **GH-15:** the same exemption mechanism above covers this class of mismatch too —
   567	    `PDDA_GOV_SHIPPED_DOC_ENVVAR_EXEMPTIONS_DEFAULT` (`PDDA_REGISTRY`, `PDDA_GITPULSE_DIR`,
   568	    `PDDA_SYNC_MAX_SHRINK`) lists canonical-only-tool env vars that `PDDA-INSTALL.md`/`PROJECT/PDDA.md`
   569	    legitimately document but no target-installed script reads, scoped to the same `PDDA_GOV_SHIPPED_DOCS`
   570	    set so a repo-authored doc's phantom env var still fires.
   571	
   572	Expected exceptions:
   573	- fenced `console`/`text`/`transcript` blocks and blockquote lines are not scanned (same carve-out as
   574	  `pdda.sh hardcoded-paths`)
   575	- override the doc set with `PDDA_GOVERNANCE_DOCS` (space-separated, repo-relative) and the index doc
   576	  with `PDDA_GOVERNANCE_INDEX` (default `ROUTER.md`) for a repo with a different layout
   577	- override the shipped-doc exemption manifest with `PDDA_GOV_SHIPPED_DOCS`,
   578	  `PDDA_GOV_SHIPPED_DOC_REF_EXEMPTIONS`, and `PDDA_GOV_SHIPPED_DOC_ENVVAR_EXEMPTIONS` (all
   579	  space-separated) for a repo with a different shipped-doc layout
   580	
   581	This check is deterministic-only; it catches the mechanical drift classes above. Semantic
   582	contradictions in prose (two docs stating conflicting policy, a claim that quietly went stale) are a
   583	judgment call for the LLM layer or a human — see the `/governance-audit` skill, which runs this check
   584	first and then reads the same doc set for that fuzzier class of inconsistency.
   585	
   586	#### J. `pdda.sh releases`
   587	
   588	Purpose:
   589	- validate `RELEASES.md`, the single forward-looking release-planning ledger — deliberately light.
   590	  This replaced an earlier per-tag-doc lifecycle (`PROJECT/releases/RELEASE-<tag>.md` with a
   591	  Draft/RC/Published status, linked marathons, linked issues, and a GitHub release-tag cache) that
   592	  turned out to be too much data to keep current for an initial release. Fields and checks grow
   593	  only as a real need shows up — see "RELEASES.md — release ledger" below.
   594	
   595	Scope: every `Release:` block in `RELEASES.md`.
   596	
   597	Minimum behavior:
   598	- parse `RELEASES.md` into blocks (one per `Release:` line; see format below)
   599	- **release-value check**: `error` if a block's `Release:` value is empty (a malformed-doc guard,
   600	  not a readiness gate)
   601	- **target-date check** (optional field): `warn` if `Target Date` is set but is not a valid
   602	  `YYYY-MM-DD` calendar date
   603	- **overdue check**: `warn` if `Target Date` has passed and `Status` doesn't read exactly `Shipped`
   604	  (case-insensitive) — `Status: Shipped` is the sole "already shipped" signal; a populated `GH_URL`
   605	  alone does not silence this (it means a Release object exists, not that it shipped)
   606	- **QA-gate field check** (optional fields): `warn` if `Front-door reviewed`, `Shakedown reviewed`,
   607	  or `License file` is set but its value isn't exactly `Yes` or `No` (case-insensitive); a blank
   608	  value is fine (not yet answered)
   609	- **iteration-band check** (optional field): `warn` if `Iterations` is set but isn't a well-formed
   610	  `<lo>-<hi>` band — both sides plain dotted-numeric, `lo` no greater than `hi`. Strict on purpose:
   611	  a band nobody can evaluate is worse than no band, because the duplicate check below silently
   612	  stops covering that release
   613	- **in-band duplicate check**: `warn` if a block's `Release:` version falls inside a *different*
   614	  block's reserved `Iterations` band. This is the admission rule made mechanical — a version inside
   615	  a band is already accounted for, so a block for it is by definition a duplicate. Only plain
   616	  dotted-numeric versions are tested; a prerelease or date-shaped version is left to human judgment
   617	  rather than guessed at
   618	- **never blocks, even in `full` mode** — this check does not gate its exit code at all, regardless
   619	  of findings. The one `error` above (empty `Release:` value) is a malformed-doc guard, surfaced
   620	  loudly so it isn't missed, but deliberately cannot fail a build
   621	
   622	gh-degrade: none. The check is purely file-driven (no GitHub calls), which is a deliberate
   623	simplification over the old per-tag-doc check's issue/tag cross-checks against `gh`.
   624	
   625	#### RELEASES.md — release ledger
   626	
   627	**`RELEASES.md` is an optional planning aid.** It is not a required artifact, not a checklist, and
   628	not something to keep topped up. An empty file, a stale file, or no file at all are all valid
   629	states — `pdda.sh releases` skips a missing file entirely ("RELEASES.md not found — nothing to
   630	check") and never blocks, even in `full` mode.
   631	
   632	**Do not proactively offer to fill it in, populate it, bring it current, or add a release that has
   633	already shipped. Do not treat a sparse file as an incomplete one.** Edit it only when an operator
   634	explicitly asks for release *planning*.
   635	
   636	That instruction is aimed at the reader who is likeliest to erode this file, which is increasingly
   637	an LLM maintainer. The failure mode is not one bad decision; it is a long series of individually
   638	reasonable offers to help — "want me to add the release you just shipped?" — that in aggregate turn
   639	a planning aid into a second, hand-maintained history of what shipped. Two sources of truth for the
   640	same fact is the defect, and it arrives one helpful suggestion at a time. `CHANGELOG.md` is the
   641	history. This file is not.
   642	
   643	What it *is*: a first-class root file, like `ROADMAP.md`/`CHANGELOG.md` — a single forward-looking
   644	planning ledger for major releases, not a lifecycle bucket of per-tag docs. Marathon plans and other
   645	forward planning cross-reference it for target release names/dates.
   646	
   647	**The admission rule.** A block earns its place by being worth *planning toward* — a named arc with
   648	a theme, usually carrying a target date and a milestone. If the only thing that can go in
   649	`Description:` is a restatement of what changed, it belongs in `CHANGELOG.md` and nowhere else.
   650	Everything below the threshold goes in an `Iterations:` band (see the field docs) rather than getting
   651	its own block.
   652	
   653	The test is the theme, not the paperwork: `Target Date:` and `Milestone:` are optional fields and
   654	their absence never disqualifies a block. A release can be worth planning toward before anyone knows
   655	when it lands.
   656	
   657	Format — one flat `Label: value` block per release, blank line between blocks (blank lines are
   658	just visual spacing; a new block starts at the next `Release:` line). Field order is not parsed and
   659	every field except `Release:` is optional, so a real block is usually shorter than this:
   660	
   661	```text
   662	Release: 1.0.0
   663	Iterations: 1.0.0-1.0.4
   664	Status: Draft
   665	Target Date: 2026-07-31
   666	Codename: n/a
   667	Milestone:
   668	Description:
   669	GH_URL:
   670	Front-door reviewed:
   671	Shakedown reviewed:
   672	License file:
   673	```
   674	
   675	Fields:
   676	- `Release:` (required) — the version being planned
   677	- `Status:` (optional) — free-text, unvalidated by design (`Draft`, `Working`, `Shipped`, whatever
   678	  an operator finds useful). **`Status: Shipped` is the sole "already shipped" signal** — both
   679	  `pdda.sh releases`'s overdue nudge and `pdda.sh releases-current`'s "in progress" filter key off
   680	  it exclusively. This is a rough signal, not a gated lifecycle — no fixed vocabulary is enforced.
   681	- `Iterations:` (optional) — a **reserved band of version numbers**, written `<lo>-<hi>` (e.g.
   682	  `0.2.0-0.2.4`). Versions inside a band ship freely and are recorded in `CHANGELOG.md` only; they
   683	  **never get a block here**, and the band deliberately does not enumerate them. Absence of the
   684	  field means no band is reserved.
   685	
   686	  **The band's owner is the one exception.** A band is written on the block it belongs to, and that
   687	  block's own `Release:` is the band's `<lo>` — so the owner sits inside its own band and keeps its
   688	  block. Every *other* version in the range is covered by the band and gets none. `pdda.sh releases`
   689	  identifies the owner by line, not by version text, so a second block that merely repeats the
   690	  owner's version is still caught as the duplicate it is.
   691	
   692	  This is what gives the admission rule an answer instead of an argument. "Where does 0.2.3 go?"
   693	  resolved case-by-case is resolved by adding a row, every time; with a band it has a written
   694	  answer, and `pdda.sh releases` can check it — a version inside an existing band is already
   695	  accounted for, so a block for it is by definition a duplicate. That is testable in a way "is this
   696	  release meaningful?" never will be.
   697	
   698	  **When a band is exhausted** — `0.2.5` is needed and the band ends at `0.2.4` — **widen the band.
   699	  Do not start enumerating, and do not add a block.** Promote to the next release only when the work
   700	  genuinely became a new arc with its own theme, never merely because the numbers ran out; a version
   701	  number driven by an accounting artifact is the convention rotting rather than holding.
   702	
   703	  Rejected alternative, recorded so it isn't re-proposed: persisting `Iteration 1:` … `Iteration 5:`
   704	  labels per release. That is 20–25 named rows across a five-release horizon, each an invitation to
   705	  fill in what shipped — the same drift, arriving as structure instead of as appended blocks. One
   706	  optional field beats five required ones.
   707	- `Target Date:` (optional) — `YYYY-MM-DD`; `pdda.sh releases` warns once this passes and `Status`
   708	  doesn't read `Shipped`
   709	- `Codename:` (optional) — `n/a` is fine
   710	- `Milestone:` (optional) — free-text, unvalidated, the **release → issue-set join key**. It holds a
   711	  GitHub milestone *title*, so a release's scope can be queried rather than hand-maintained here:
   712	
   713	  ```bash
   714	  gh issue list --milestone "Quicksilver" --state open --json number,title,labels
   715	  ```
   716	
   717	  That query *is* release-driven work selection, with no second cache and no issue list copied into
   718	  this file — which is why the field is worth having and why it stays a pointer. Unvalidated for the
   719	  same reason as `Status:`: checking a title against GitHub would need a `gh` call, and this check is
   720	  deliberately network-free. **Not warned on when absent** — a release with no milestone is a normal
   721	  state, and a nudge here would recreate exactly the fill-it-in pressure this section exists to stop.
   722	- `Description:` (optional) — one line for now; grows into something richer only if needed
   723	- `GH_URL:` (optional) — populated once *a* GitHub Release object exists, including a draft (see
   724	  `/release` skill). **This means "a Release object exists," not "shipped"** — a draft's `GH_URL`
   725	  is real but the release isn't out. Flip `Status: Shipped` yourself (or let `/release` do it on an
   726	  actual, non-draft publish) when it's really out; `GH_URL` alone no longer implies that.
   727	- `Front-door reviewed:` / `Shakedown reviewed:` / `License file:` (optional) — pre-release QA-gate
   728	  checkboxes: has the `/front-door` onboarding audit run, has the `/shakedown` script-path audit
   729	  run, is a `LICENSE` file present. `Yes` or `No`; `pdda.sh releases` warns on any other non-blank
   730	  value. A blank value just means not yet answered, not a failure.
   731	
   732	Add new fields only when a real need shows up. This format intentionally started smaller than the
   733	earlier per-tag-doc convention (status lifecycle, linked marathons, linked issues, a GitHub
   734	release-tag cache) — that was more data than was practical to keep current for an initial release.
   735	`Status:` is the first field added back in, deliberately kept unvalidated (baby steps, not a new
   736	gated lifecycle) rather than reintroducing the old rigid `Draft → RC → Published` enum. The three
   737	QA-gate fields are the second: a real pre-release checklist need (open-sourcing a release means a
   738	front-door pass, a shakedown pass, and a `LICENSE` file all need to be true before shipping) that,
   739	unlike `Status`, has an unambiguous right answer — so they're validated `Yes`/`No` rather than free-text.
   740	`Iterations:` and `Milestone:` are the third pair, and both are additive: the parser ignores labels
   741	it doesn't know, absence means "not reserved" / "no milestone", and neither produces a finding in a
   742	ledger that has never used them. A repo can adopt them, or never hear of them, with no migration.
   743	
   744	Two skills operate on this file: `/release-plan` **authors** entries (interviews the operator,
   745	proposes a canonical version by cross-referencing `CHANGELOG.md`, previews, appends on confirmation)
   746	and `/release` **publishes** an existing entry to GitHub once its `Status` is ready to ship. Both are
   747	operator-triggered by design and neither should be offered unprompted — a skill that exists to keep a
   748	file populated is the most efficient possible way to violate the optionality rule at the top of this
   749	section.
   750	
   751	#### `pdda.sh releases-current`
   752	
   753	Read-only roll-up (not part of `PDDA_DETERMINISTIC_CHECKS` — emits no findings, never gates): lists
   754	every `RELEASES.md` entry whose `Status` is empty or not exactly `Shipped`. A rough, non-authoritative
   755	answer to "what's currently in progress" — for a human, or for another repo's tooling (e.g. the XYZ
   756	sibling harness) to shell out to instead of re-implementing `RELEASES.md` parsing itself. Because
   757	`Status` is free-text, this is a best-effort filter, not a guarantee — an entry with a typo'd or
   758	unconventional `Status` value still shows up (safer default: never silently hide something that
   759	lacks an explicit `Shipped` signal).
   760	
   761	The four-tier shipping chain:
   762	
   763	```
   764	task/issue  (GH-*.md in 1-INBOX)
   765	  → project (2-WORKING active doc)
   766	    → marathon (marathon/MARATHON-*.yaml + PROJECT/2-WORKING/MARATHON-PLAN-*.md)
   767	      → release (RELEASES.md entry + GitHub Release)
   768	```
   769	
   770	### 2. LLM-assisted doc readiness review
   771	
   772	This catches the issues where structure exists but planning quality is weak.
   773	
   774	#### `pdda-doc-ready.sh`
   775	
   776	Purpose:
   777	- review active project plans and flag docs that are not ready for reliable automation
   778	
   779	It should check for:
   780	
   781	- phased plans missing QA gates after a phase
   782	- phase sections with actions but no observable acceptance criteria
   783	- multi-phase plans missing a table of contents listing each phase
   784	- discovery or spike phases whose findings were not written back into the plan doc
   785	- medium-large plans missing the triage ratings (`effort`, `complexity`, `risk`, `phases`)
   786	- status tables that are technically present but stale versus the body
   787	- docs that bury the next action in prose instead of making it explicit
   788	- plans that duplicate detail already meant to live in another canonical doc
   789	- contradictory status, such as frontmatter saying `Completed` while the body says active
   790	
   791	It should not:
   792	
   793	- auto-rewrite the plan body without review
   794	- invent technical claims not grounded in the doc
   795	- silently override deterministic lints
   796	- **block a build.** The LLM layer is advisory: its findings are capped at `warn` (any model `error`
   797	  is clamped to `warn` in `pdda-doc-ready.sh`), so a non-deterministic oracle can never fail a build —
   798	  the same doc must not pass at 2pm and fail at 3pm. Only deterministic checks earn blocking power.
   799	
   800	### 3. Doc-health hooks (event-triggered delivery)
   801	
   802	The deterministic checks above can also run automatically from Claude Code hooks, as a two-tier
   803	doc-health system. The hooks are pure **delivery** — they run the SAME section-1 checks on a trigger;
   804	they add no new analysis class. Both are **warn-only and fail-open: they always exit `0` and can never
   805	block** an edit or a stop (a doc-hygiene reminder is never worth interrupting work — the calibration
   806	principle, same as `pdda.sh changelog`).
   807	
   808	- **Tier 1 — `pdda-edit-doc-hook.sh` (`PostToolUse` on `Edit|Write|MultiEdit`).** Reads the edited
   809	  `tool_input.file_path`; exits `0` instantly unless it is `ROADMAP.md` or a `PROJECT/**/*.md` doc;
   810	  otherwise runs the fast **local single-file** subset for just that file — `frontmatter`,
   811	  `status-table`, `hardcoded-paths`, `roadmap-coverage` (and `roadmap` for `ROADMAP.md`), scoped via
   812	  `PDDA_ONLY_FILE`. **No network, no `gh`, no LLM**, so it stays instant and cannot gate an edit.
   813	- **Tier 2 — Stop full-scan (`pdda-stop-doc-health.sh`).** The companion that runs one consolidated,
   814	  system-wide doc-health scan per turn (the deterministic suite plus `issue-doc-sync` against the
   815	  cached gh-state file). See [Suggested Stop doc-health scan](#suggested-stop-doc-health-scan).
   816	
   817	`PDDA_ONLY_FILE=<path>` is the seam that scopes any check to a single file (unset = full scan, the
   818	default everywhere else). Wiring is repo-local in `.claude/settings.json`; installs receive the hook
   819	scripts via the manifest and opt in by adding the hook entries.
   820	
   821	#### Suggested Stop doc-health scan
   822	
   823	Tier 2's `pdda-stop-doc-health.sh` runs **one** system-wide scan per turn and prints a **single
   824	consolidated report**:
   825	
   826	- it runs the deterministic suite with `PDDA_ISSUE_SYNC_SOURCE=cache`, so `issue-doc-sync` reads the
   827	  cached gh-state file (written by `pdda.sh gh-refresh`) and the scan makes **no network call**;
   828	- it runs in `observe` mode with the LLM layer disabled — purely deterministic, fast, offline;
   829	- it aggregates the run into one report: a header with the error/warn totals, then the warn/error
   830	  finding lines (an `all clear` line when there are none);
   831	- it **always exits `0`** (proven by `test/pdda-doc-health-hooks.sh`), so it can never block a stop.
   832	
   833	Wire it as a `Stop` hook in `.claude/settings.json` (no matcher). Because it reads the cache rather
   834	than calling `gh`, keep `pdda.sh gh-refresh` on the hourly cadence so the Stop report stays current.
   835	
   836	## Enforcement modes
   837	
   838	PDDA runs in one of three modes. The mode is resolved in this order: **the `PDDA_MODE` env var wins if
   839	set; otherwise the first non-comment line of a repo-root `.pdda-mode` file; otherwise the built-in
   840	default `observe`.** (So an env var overrides a committed `.pdda-mode` — convenient for a one-off
   841	`PDDA_MODE=observe` pass against a repo otherwise committed to `full`.) The point is an **adoption
   842	ramp**: a freshly-installed PDDA should never break a build on day one, and a project should graduate
   843	onto the rails deliberately.
   844	
   845	| Mode | When | Findings reported | Exit on `error` |
   846	|---|---|---|---|
   847	| `observe` | just installed | yes | always `0` |
   848	| `light` | transitioning | yes | `0` (warn, don't block) |
   849	| `full` | fully on rails | yes | non-zero (blocks) |
   850	
   851	- The default is `observe` so a brand-new install is non-blocking — it shows the team what PDDA
   852	  *would* flag without failing anything.
   853	- `light` is the transition phase: loud reports, but still never fails a build, while the backlog of
   854	  doc debt is cleared.
   855	- `full` is the strict end state: `error` findings block with a non-zero exit. A repo declares it by
   856	  committing `.pdda-mode` with `full`.
   857	- **No mode mutates the tree.** Stale docs are *flagged, never auto-moved* — the only destructive
   858	  mechanic was removed (see the stale-doc check above). Mode controls one thing only: whether an
   859	  `error` blocks. Every check ends with `exit "$(pdda_gated_exit "$EXIT_CODE")"`, which returns the
   860	  real code only in `full`.
   861	
   862	## ROADMAP.md contract
   863	
   864	`ROADMAP.md` is a pointer file, not a plan body.
   865	
   866	It should contain:
   867	
   868	- queued / parked intake pointers for newly captured `GH-*.md` docs
   869	- projects in progress
   870	- completed work
   871	- attempted work
   872	- deferred work
   873	- links to the canonical project docs
   874	
   875	It should usually not contain:
   876	
   877	- detailed phase checklists
   878	- step-by-step build instructions
   879	- deep execution notes already owned by a project file
   880	
   881	Strict exemption:
   882	- a short exception note is allowed when omitting the note would hide an operationally critical fact
   883	
   884	Maintainer rule:
   885	- when a roadmap entry needs more than a one-line status + a link, that is the signal to put the
   886	  detail in the entry's `PROJECT/**` doc and leave only the pointer here — do not grow the roadmap
   887	
   888	Coverage rule:
   889	- every active doc in `PROJECT/2-WORKING` must be reflected here by a pointer (a one-line ledger entry
   890	  that links it), so the ledger never falls behind the working set. A working doc that legitimately
   891	  should not appear opts out with `roadmap_exempt: true` in its frontmatter. This is the inverse of the
   892	  "no detail leaks in" rule above: nothing active goes *missing from* the roadmap either.
   893	- every captured GitHub issue doc in `PROJECT/1-INBOX/GH-*.md` must also be reflected here as a
   894	  one-line **queued / parked** pointer until it is promoted, deferred out, or closed, so intake cannot
   895	  quietly disappear and later be duplicated.
   896	
   897	How this is enforced (so it cannot quietly rot in either direction):
   898	- **deterministic (no leak in)** — `pdda.sh roadmap` errors on task checklists / `### Checklist` /
   899	  `### QA checklist` headings and warns on size sprawl (runs hourly, free, no model needed)
   900	- **deterministic (no gap missing)** — `pdda.sh roadmap-coverage` errors when either an
   901	  active `PROJECT/2-WORKING` doc has no pointer here, or a captured `PROJECT/1-INBOX/GH-*.md` doc is
   902	  not parked here as a queue entry (honors `roadmap_exempt: true`)
   903	- **LLM** — `utils/pdda/pdda-doc-ready.sh` reviews `ROADMAP.md` against the full pointer contract for the
   904	  fuzzier "this paragraph is really execution detail" cases (honors the carve-out)
   905	- the file itself carries a top banner restating the contract, so a human editing it sees the rule
   906	
   907	## CHANGELOG.md — end-of-iteration record (first-class)
   908	
   909	`CHANGELOG.md` is a first-class PDDA artifact: the canonical, newest-first running log of what changed,
   910	updated **at the end of each iteration**. It is the one narrative/provenance log this contract
   911	prescribes — if an adopting repo kept its own ad hoc recap or run-observation notes before adopting
   912	PDDA, `CHANGELOG.md` supersedes them; PDDA does not require or name any such file itself (Principle #4 —
   913	one canonical place per fact). Durable Costly / one-way-door bets still earn a `decisions/` record.
   914	updated **at the end of each iteration**. It supersedes the retired RECAP convention as the running
   915	provenance/narrative log, and it also absorbs the run-specific compliance findings the retired
   916	REAL-AGENT-OBSERVATIONS convention used to collect. Durable Costly / one-way-door bets still earn a
   917	`decisions/` record.
   918	
   919	It should contain:
   920	
   921	- newest-first, dated sections headed either `## YYYY-MM-DD` or `## [x.y.z] - YYYY-MM-DD`
   922	- one entry per substantive iteration: what changed, why, and the verification (test / suite result)
   923	- the bet behind a consequential change when one applies (the call, the expected signal, reversibility)
   924	
   925	It should not contain:
   926	
   927	- per-file diffs or deep execution detail that belongs in the entry's `PROJECT/**` doc
   928	- aspirational plans — those live in the project doc and the `ROADMAP.md` ledger
   929	
   930	Maintained append-only:
   931	
   932	- add a new dated entry per iteration; **never rewrite a past entry's numbers, claims, or
   933	  recommendation** — *especially* not when it turned out wrong. Correct a past entry by appending a
   934	  dated correction, not by editing history. This append-only guarantee is the whole point of having one
   935	  canonical narrative log instead of scattered ad hoc notes.
   936	  dated correction, not by editing history. This is the provenance guarantee the retired RECAP
   937	  convention used to carry.
   938	
   939	Recording a bet (when a change is consequential):
   940	
   941	- when a decision is Costly, a one-way door, or rides on an assumption that could be wrong, the entry
   942	  records the call, the bet/assumption, the expected signal with a by-when, the reversibility read, a
   943	  revisit trigger, and a graduate / iterate / abandon recommendation. Below that threshold a plain
   944	  entry suffices. Durable bets also earn a `decisions/` record. An adopting repo is free to keep its own
   945	  separate run-specific compliance-observations doc if that's useful to it, but that's a local
   946	  convention this contract neither requires nor names. (`AGENTS.md` principle #7 supplies the
   947	  behavioral trigger — *record the bet*; this contract owns the *where and how*.)
   948	  entry suffices. Durable bets also earn a `decisions/` record; run-specific compliance findings go in
   949	  the iteration's own `CHANGELOG.md` entry. (`AGENTS.md` principle #7 supplies the behavioral trigger —
   950	  *record the bet*; this contract owns the *where and how*, so governance is not fragmented across the
   951	  two files.)
   952	
   953	How this is enforced (a nudge, not a gate):
   954	- **deterministic** — `pdda.sh changelog` **warns** (never `error`, so it never blocks —
   955	  even in `full`) when the newest dated entry predates the latest git commit by more than
   956	  `PDDA_CHANGELOG_STALE_DAYS` days (default `0`), i.e. an iteration shipped without a changelog entry
   957	- whether an entry is actually *substantive* stays a human / LLM judgment, not a regex
   958	
   959	## Activity log artifact
   960	
   961	PDDA should write an append-only activity log to:
   962	
   963	- `PROJECT/PDDA-ACTIVITY.jsonl`
   964	
   965	Each script run should append:
   966	
   967	- per-finding entries
   968	- one summary entry for the script
   969	- enough metadata to tell what moved, what failed, and when
   970	
   971	## Suggested hourly schedule
   972	
   973	Run the deterministic checks every hour in this order:
   974	
   975	1. `pdda.sh frontmatter`
   976	2. `pdda.sh status-table`
   977	3. `pdda.sh hardcoded-paths`
   978	4. `pdda.sh roadmap`
   979	5. `pdda.sh roadmap-coverage`
   980	6. `pdda.sh changelog`
   981	7. `pdda.sh stale`
   982	8. `pdda.sh issue-doc-sync`
   983	9. `pdda.sh releases`
   984	10. `pdda.sh governance`
   985	
   986	Then run:
   987	
   988	11. `pdda.sh doc-ready`
   989	
   990	(`pdda.sh run` runs exactly this sequence and applies the active `PDDA_MODE` gate. Scheduling the
   991	single aggregate command is the recommended hourly cron entry.)
   992	
   993	The cached GitHub issue-state refresh is a separate, network-only step. Run `pdda.sh gh-refresh`
   994	(the standalone `utils/pdda/pdda-gh-refresh.sh`) on the same hourly cron/launchd cadence, **before**
   995	the suite, so `issue-doc-sync` and the Stop doc-health scan read fresh state. It is the only step that
   996	needs `gh`/the network; it writes `PDDA_GH_STATE_CACHE` atomically and leaves the existing cache
   997	untouched on any `gh` failure, so the suite itself stays offline-tolerant by reading the cache.
   998	
   999	Reason for the order:
  1000	
  1001	- deterministic failures should surface first
  1002	- the network-dependent `issue-doc-sync` runs last among the deterministic checks, so every local
  1003	  check still completes when `gh` is offline (it then degrades to the cache or an `info` skip)
  1004	- the LLM review should spend time only on docs that passed basic structural hygiene
  1005	
  1006	## Suggested output contract
  1007	
  1008	To make these scripts composable, each should emit:
  1009	
  1010	- a short human-readable summary to stdout
  1011	- a machine-readable result format, ideally JSON lines
  1012	- non-zero exit when blocking issues are found
  1013	
  1014	Suggested fields per finding:
  1015	
  1016	- `severity`
  1017	- `check`
  1018	- `file`
  1019	- `line`
  1020	- `message`
  1021	- `action`
  1022	- `timestamp`
  1023	
  1024	Severity proposal:
  1025	
  1026	- `error`: automation-blocking
  1027	- `warn`: should be fixed soon but not blocking
  1028	- `info`: advisory only
  1029	
  1030	## Readiness rubric for automation
  1031	
  1032	A doc is "automation ready" when:
  1033	
  1034	- it is in the correct lifecycle folder
  1035	- it has valid frontmatter
  1036	- it has the exact status table
  1037	- the next action is singular and explicit
  1038	- each phase has a visible QA gate
  1039	- a multi-phase plan has a table of contents listing its phases
  1040	- any discovery or spike phase has its findings written back into the doc
  1041	- links to canonical related docs are present where needed
  1042	- there are no hardcoded absolute paths
  1043	- `ROADMAP.md` is pointing at it rather than duplicating it
  1044	
  1045	## Failure modes PDDA is trying to prevent
  1046	
  1047	- active docs with no visible next step
  1048	- too many half-live docs in `PROJECT/2-WORKING`
  1049	- plans that look complete but have no verification gates
  1050	- stale working docs silently lingering forever
  1051	- roadmap sprawl where detail leaks into `ROADMAP.md`
  1052	- agent sessions restarting the same reasoning because the doc never captured "what changed"
  1053	
  1054	## Proposed extensions not yet locked
  1055	
  1056	These are likely useful for full automation, but they are still policy choices:
  1057	
  1058	- a `doc_type` field such as `project`, `bugfix`, `research`, `feedback`, `roadmap`
  1059	- ~~a `priority` field if you want deterministic triage beyond folder placement~~ **superseded** by the
  1060	  `effort`/`complexity`/`risk`/`phases` [triage ratings](#triage-ratings-for-medium-large-work), which
  1061	  give richer triage than a single priority scalar — automation derives the selection signal from them
  1062	  rather than storing one frozen number
  1063	- a `pdda_hold: true` override for docs that should remain in `2-WORKING` despite inactivity
  1064	- a second generated PDDA summary artifact beyond the activity log
  1065	
  1066	## Open questions
  1067	
  1068	These need a decision before the automation should be considered stable:
  1069	
  1070	1. Should `PROJECT/PDDA-ACTIVITY.jsonl` remain append-only forever, or rotate by month once the volume grows?
  1071	2. Should `ROADMAP.md` remain root-level canonical only, or do you also want a project-local roadmap index under `PROJECT/`?
  1072	
  1073	Resolved:
  1074	
  1075	- ~~Should the compatibility window end on `2026-07-31`, or be shorter/longer?~~ **Resolved
  1076	  2026-06-22:** removed entirely. No doc in the repo used an old alias, so a dated cutover guarded
  1077	  nothing — and a script whose behavior changes silently on a hardcoded date is the same fossilized
  1078	  assumption the hardcoded-path check exists to prevent. Headers are now exact-or-`error`, no window.
  1079	- ~~Should `gh_issue` stay optional metadata, or become required for bug-fix docs that originated from
  1080	  GitHub?~~ **Resolved 2026-06-21:** `gh_issue` stays optional in general, but is **required** on any
  1081	  doc that originated from a GitHub issue — which the `GH-<number>-…` filename guarantees. See
  1082	  [GitHub issue intake](#github-issue-intake).
  1083	
  1084	## Recommended v1 stance
  1085	
  1086	If the goal is "get project docs onto rails quickly," the safest v1 is:
  1087	
  1088	- start in `observe` mode, then graduate `light` → `full` as the doc backlog is cleared
  1089	- enforce exact status-table headers (no alias window)
  1090	- require QA gates on phased plans
  1091	- forbid hardcoded absolute paths
  1092	- run deterministic checks hourly
  1093	- let the LLM reviewer flag readiness issues
  1094	- keep `ROADMAP.md` pointer-only (deterministic `pdda.sh roadmap` + the LLM rubric guard it)
  1095	- append all script activity to `PROJECT/PDDA-ACTIVITY.jsonl`

===== PROJECT/1-INBOX/GH-484-MARATHONS-DEFAULT.md =====
     1	---
     2	title: "GH-484 — redefine the canonical marathon-phase directory default from phases/ to MARATHONS/"
     3	status: 1-INBOX
     4	created: 2026-08-09
     5	owner: noel
     6	doc_type: project
     7	goal: >
     8	  Flip the DEFAULT value of the marathon drivers' per-phase run-output directory from
     9	  `$ROOT/phases` to `$ROOT/MARATHONS`, for every new install (vendored or not), while the
    10	  existing `--phases-dir` / `PHASES_DIR` override keeps working exactly as it does today.
    11	  Naming-consistency issue, not a bug fix — the harness's entire vocabulary says "marathon"
    12	  except the one directory holding a marathon's actual run state.
    13	roadmap_exempt: true
    14	EOF_NOTE: not yet parked in ROADMAP.md — do that before this leaves 1-INBOX (GH-480's own gate caught this once already; don't repeat it)
    15	---
    16	
    17	Issue: [#484](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/484)
    18	
    19	## Why this shape (ponytail: cheapest path that's actually correct)
    20	
    21	The obvious-sounding version of this task is "rename `phases/` to `MARATHONS/` everywhere" — a
    22	repo-wide search-and-replace across ~70 files. That is not what's actually needed, and building it
    23	that way would be doing far more than the ask requires:
    24	
    25	- `utils/py/marathon_drive.py` and its frozen GH-308 Bash twin `relay-automation/marathon-drive.sh`
    26	  **already** take `--phases-dir` / `PHASES_DIR`, both defaulting to `$ROOT/phases`. The override
    27	  mechanism has parity today. Flipping the *default* value is a 1-line change in each twin — no new
    28	  config surface needs to be invented.
    29	- `relay-automation/xyz-vendor.sh` (the vendoring installer) has **zero** hardcoded "phases"
    30	  references, grep-confirmed. A vendored install inherits whatever default the driver code defines.
    31	  Nothing to touch there for "all new (vendored) installations" — that requirement is already met by
    32	  changing the two twins' default.
    33	- Of the ~70 files a bare grep for "phases" turns up, the large majority are prose mentions in docs,
    34	  historical `PROJECT/3-COMPLETED/**` records, and `temp/relay-system-collected/**` (other repos'
    35	  archived transcripts, not this repo's live code) — none of those need editing for the tool's actual
    36	  behavior to change.
    37	
    38	So the real work is small and mechanical: flip 2 defaults, fix 2 already-latent literal-string bugs,
    39	and enumerate (not assume) which of the remaining files actually assert the *default value* rather
    40	than just describing or using the override.
    41	
    42	## What's actually broken today, independent of this rename
    43	
    44	Found while grounding this, not part of the ask, but real and worth fixing in the same lane since
    45	the same lines are being touched anyway:
    46	
    47	- `utils/py/marathon_drive.py:1666` — `p.startswith("phases/")` — a hardcoded literal in a
    48	  containment-adjacent check. It does not read `phases_dir`, so it is **already wrong today** for
    49	  anyone who passes a non-default `--phases-dir`: their phase output would not match this check.
    50	- `relay-automation/marathon-drive.sh:961` — `awk '{ p=substr($0,4); if (p !~ /^phases\// && p !~
    51	  /^\.tick\//) print p }'` inside the dirty-tree pre-flight warning — same class of bug, same twin
    52	  pairing, same fix shape (read `$PHASES_DIR`, not a literal).
    53	
    54	Both need to become variable-driven rather than string-literal regardless of what the default is
    55	named, which is exactly what this issue needs anyway.
    56	
    57	## The gitignore landmine (found during grounding, flagging because it's live right now)
    58	
    59	`marathon_drive.py` stages phase output with `git add --` + `check=True` at three call sites
    60	(`:1129` ESCALATION.md, `:1169`, `:1728` RELAY.md). `git add` on an explicitly gitignored path exits
    61	1, so `check=True` raises and the phase dies while trying to record itself.
    62	
    63	`test/marathon-root-audit.sh` (added **2026-08-09**, today) pins exactly this: it asserts that phase
    64	artifacts the driver commits are never gitignored, because someone gitignored the whole `/phases/`
    65	directory that same day and reverted it hours later after hitting this crash. Whatever the new
    66	default directory is named, it needs the equivalent assertion from day one, or the first same-repo
    67	phase to run against it will crash.
    68	
    69	## `marathon-plans/` — confirmed dead, explicitly out of scope
    70	
    71	`marathon-plans/2026-07-15-gh205-207/MARATHON.yaml` has zero references anywhere in scripts or
    72	docs and exactly 2 commits, both from 2026-07-15 — a one-off artifact from a single past marathon
    73	run, superseded by the live `PROJECT/2-WORKING/MARATHON-PLAN-*.md` convention (generated by
    74	`utils/marathon-plan.sh`). Noted here only so nobody conflates the two conventions; not touched by
    75	this issue.
    76	
    77	## Anti-goals
    78	
    79	- No migration of the ~72 already-committed historical `phases/<run-id>/` records. They stay where
    80	  they are as history. The new default applies to new runs only — this is a forward-looking default
    81	  change, not a repo reorganization.
    82	- No change to `PROJECT/2-WORKING/MARATHON-PLAN-*.md` or `marathon-plans/` — different, unrelated
    83	  convention, already covered above.
    84	- No new environment variable, config file, or abstraction layer. `MARATHON_ROOT` (repo root) and
    85	  `--phases-dir`/`PHASES_DIR` (phase-output dir) already fully cover this; adding a third knob would
    86	  be unrequested surface for a value that has exactly one real override case.
    87	- Not a blanket repo-wide rename of every prose mention of "phases". Phase 0 below decides, file by
    88	  file, which of the non-driver references actually need to change.
    89	
    90	## Phases
    91	
    92	### Phase 0 — enumerate, don't assume (cx 1, risk 1, eff 1)
    93	
    94	Turn the ~70-file grep hit list into a real classification before any edit lands:
    95	1. Mentions/prose only (docs, `PROJECT/3-COMPLETED/**`, `temp/relay-system-collected/**`) → no
    96	   change needed, explicitly recorded as reviewed-and-skipped, not silently ignored.
    97	2. Tests that hardcode the *default value* specifically (would silently start asserting against a
    98	   directory the driver no longer writes to) → must update.
    99	3. Tests that already pass an explicit `--phases-dir` fixture path → unaffected, recorded as such.
   100	4. Skills/docs that document the default for a new user (`skills/marathon-triage/SKILL.md`,
   101	   `skills/file-xyz-bug/SKILL.md`, `README.md`, `relay-automation/README.md`,
   102	   `relay-automation/CONTRACT.example.md`) → must update for consistency.
   103	
   104	Output: a short table in this doc (or a linked file) naming every file in categories 2–4 by path,
   105	so Phase 2 has a checklist instead of a re-grep.
   106	
   107	### Phase 1 — flip the default, fix the two literals, prove parity (cx 2, risk 2, eff 2)
   108	
   109	- `utils/py/marathon_drive.py`: change the `--phases-dir` default from `os.path.join(root,
   110	  "phases")` to `os.path.join(root, "MARATHONS")`; fix the `:1666` literal to read the resolved
   111	  `phases_dir` variable instead of the string `"phases/"`.
   112	- `relay-automation/marathon-drive.sh`: same two changes — `PHASES_DIR="${PHASES_DIR:-"$ROOT/
   113	  MARATHONS"}"`, and the `:961` awk pattern reads `$PHASES_DIR`'s basename rather than a literal.
   114	- Both are GH-308 frozen twins → go through the documented exception process
   115	  (`test/gh308-frozen-twin-guard.sh --check --base <rev> --allow-exceptions`), not around it. The
   116	  operator has already accepted this cost explicitly.
   117	- Extend (or add a sibling to) `test/marathon-root-audit.sh`'s gitignore-safety assertion to cover
   118	  the new default path — this is the fix for the landmine above, and it is the one piece of this
   119	  phase that must land before any real same-repo phase runs against the new default.
   120	- New/extended regression test proving twin parity: a fresh run with no `--phases-dir` writes under
   121	  `MARATHONS/` in both twins; `--phases-dir <custom>` still overrides in both; the two
   122	  containment-literal fixes correctly recognize a non-default `--phases-dir` value (this is the
   123	  falsifiable case that catches the pre-fix bug — assert it fails against the pre-fix code, not just
   124	  passes against the fix).
   125	
   126	### Phase 2 — apply the Phase 0 checklist, docs, close (cx 1–2, risk 1, eff 1–2, size depends on Phase 0's count)
   127	
   128	- Update every file Phase 0 categorized as 2–4. Each edit references its Phase 0 line, not a fresh
   129	  ad-hoc decision.
   130	- `README.md` / `relay-automation/README.md` / `ARCHITECTURE.md` (if it names the directory) updated
   131	  to describe `MARATHONS/` as the default, `--phases-dir` as the override.
   132	- Re-run the full `validate.sh` suite; confirm no drift beyond what Phase 0 predicted (a surprise
   133	  failure here means Phase 0's classification missed something and should be corrected, not papered
   134	  over).
   135	
   136	## Acceptance (copied verbatim from issue #484, do not restate)
   137	
   138	1. A fresh same-repo marathon run (no `--phases-dir` passed) writes to `MARATHONS/`, not the old
   139	   directory, in both the Python and Bash drivers, with identical behavior between twins.
   140	2. `--phases-dir <custom>` still overrides the default exactly as today, in both twins.
   141	3. The two hardcoded containment literals track the actual configured directory, not a fixed
   142	   string — verified with a fixture that passes a non-default `--phases-dir` and confirms the
   143	   containment/dirty-check logic still recognizes it correctly.
   144	4. A `git add --` on the new default's phase artifacts does not crash — equivalent assertion to the
   145	   existing gitignore-safety regression test, extended to the new path.
   146	5. Every test identified in Phase 0 that hardcoded the old default is either updated or confirmed
   147	   unaffected, with the reasoning recorded per-file, not asserted in bulk.
   148	6. GH-308 frozen-twin exception process followed for both edited Bash twins, not bypassed.
   149	
   150	## Sizing
   151	
   152	cx/risk/eff **2/2/2**, 3 phases (Phase 0 discovery is cheap and de-risks the rest; Phase 1 is the
   153	load-bearing twin-parity change and carries the frozen-twin process cost; Phase 2's size is bounded
   154	by what Phase 0 actually finds, not assumed up front).

exec
/bin/zsh -lc "rg -n -i --glob '"'!temp/relay-system-collected/**'"' '(phases|PHASES_DIR|phases-dir|MARATHONS)' utils/py/marathon_drive.py relay-automation/marathon-drive.sh utils/py/swarm_preflight.py utils/swarm-preflight.sh relay-automation/poll.sh relay-automation/relay-turn-lib.sh test/marathon-root-audit.sh test/gh308-frozen-twin-guard.sh relay-automation/xyz-vendor.sh" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-67768-b0m00j9w
 succeeded in 0ms:
test/marathon-root-audit.sh:8:# invocation in test/gh268-relay-cue-and-target-checks.sh therefore wrote phases/p1/RELAY.md into
test/marathon-root-audit.sh:241:# Not hypothetical: `/phases/` was added to .gitignore on 2026-08-09 to stop the #401/#461 churn, and
test/marathon-root-audit.sh:243:# makes the revert stick. Verified directly before writing it: in a scratch repo ignoring /phases/,
test/marathon-root-audit.sh:244:# `git add -- phases/newrun/RELAY.md` exits 1.
test/marathon-root-audit.sh:250:for probe in phases/audit-probe/RELAY.md phases/audit-probe/ESCALATION.md; do
utils/swarm-preflight.sh:44:#       "remediation": { "source": "self#phases", "criteria": "Phases 1-7 of GH-25" },
utils/swarm-preflight.sh:745:DOC_HAS_PHASES=0
utils/swarm-preflight.sh:746:grep -Eq '^##+ .*[Pp]hase|^- \[[ xX]\]' "$PRIMARY_DOC" 2>/dev/null && DOC_HAS_PHASES=1
utils/swarm-preflight.sh:750:if [[ -z "$REMED_SRC$REMED_CRIT" && "$DOC_HAS_PHASES" -eq 0 ]]; then
utils/py/swarm_preflight.py:1236:    doc_has_phases = 0
utils/py/swarm_preflight.py:1241:                    doc_has_phases = 1
utils/py/swarm_preflight.py:1247:    if not remed_src and not remed_crit and doc_has_phases == 0:
relay-automation/marathon-drive.sh:26:# Renders phases/p1/RELAY.md from the phase brief, seeds the tick token (handoff → builder),
relay-automation/marathon-drive.sh:40:#     [--phases-dir <DIR>]       where to create phases/<id>/ (default: <repo-root>/phases)
relay-automation/marathon-drive.sh:41:#     [--phase-id <ID>]          which phase to drive: phases/<id>/ (default: p1; the orchestrator sets it)
relay-automation/marathon-drive.sh:49:#                                fails (exit 5) even if --pre-advance-cmd passed. Omit for phases with
relay-automation/marathon-drive.sh:71:# (basename ".xyz"). ROOT = work root = where git ops, phases/, .tick/, validate.sh live.
relay-automation/marathon-drive.sh:164:# phase's print is the whole chain's true final total; earlier phases' prints are an additive
relay-automation/marathon-drive.sh:603:  --phases-dir DIR        Where to create phases/<id>/ (default: <repo-root>/phases).
relay-automation/marathon-drive.sh:604:  --phase-id ID           Which phase to drive: phases/<id>/ (default: p1).
relay-automation/marathon-drive.sh:614:                          even when --pre-advance-cmd passed. Omit for phases with no test surface
relay-automation/marathon-drive.sh:633:PHASES_DIR=""        # resolved to default after ROOT is set
relay-automation/marathon-drive.sh:634:PHASE_ID="p1"        # which phase this invocation drives (phases/<id>/); the orchestrator sets it
relay-automation/marathon-drive.sh:654:    --phases-dir)      PHASES_DIR="${2:-}"; shift 2 ;;
relay-automation/marathon-drive.sh:679:PHASES_DIR="${PHASES_DIR:-"$ROOT/phases"}"
relay-automation/marathon-drive.sh:833:PHASE_DIR="$PHASES_DIR/$LANE_STATE_KEY"
relay-automation/marathon-drive.sh:957:# marathon's own paths (phases/, .tick/). --require-clean turns the warning into a hard stop for
relay-automation/marathon-drive.sh:961:    | awk '{ p=substr($0,4); if (p !~ /^phases\// && p !~ /^\.tick\//) print p }')"
relay-automation/marathon-drive.sh:969:# ── Step 1: render phases/p1/RELAY.md ──────────────────────────────────────
utils/py/marathon_drive.py:383:    parser.add_argument("--phases-dir", dest="phases_dir")
utils/py/marathon_drive.py:687:    phases_dir = args.phases_dir or os.path.join(root, "phases")
utils/py/marathon_drive.py:1136:    phase_dir = os.path.join(phases_dir, lane_state_key)
utils/py/marathon_drive.py:1666:                    if not p.startswith("phases/") and not p.startswith(".tick/"):
utils/py/marathon_drive.py:1677:    # phase dir creation used to live here, above the render, so a dry run materialized phases/<id>/
utils/py/marathon_drive.py:1678:    # in whatever repo it resolved to — the harness itself when no MARATHON_ROOT/--phases-dir was

exec
/bin/zsh -lc "nl -ba utils/py/marathon_drive.py | sed -n '340,410p;650,710p;1100,1180p;1620,1745p'
nl -ba relay-automation/marathon-drive.sh | sed -n '1,95p;580,700p;800,990p'
nl -ba test/marathon-root-audit.sh | sed -n '1,280p'
nl -ba test/gh308-frozen-twin-guard.sh | sed -n '1,320p'" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-67768-b0m00j9w
 succeeded in 0ms:
   340	
   341	def _gate_kill_group(proc, reason):
   342	    """TERM the whole gate process group, then KILL whatever ignored it."""
   343	    log(f"gate-guard: KILLING gate process group (pgid {proc.pid}) — {reason}")
   344	    for sig in (signal.SIGTERM, signal.SIGKILL):
   345	        try:
   346	            os.killpg(proc.pid, sig)
   347	        except (ProcessLookupError, PermissionError, OSError) as exc:
   348	            log(f"gate-guard: killpg({proc.pid}, {sig!r}) failed: {exc}")
   349	        deadline = time.monotonic() + 2.0
   350	        while time.monotonic() < deadline:
   351	            if proc.poll() is not None:
   352	                return
   353	            time.sleep(0.1)
   354	    proc.wait()
   355	
   356	
   357	def gate_guard_cpu_attribution(returncode, cpu_s):
   358	    """Return (guard_exit_code, diagnostic) for a CPU-limit result.
   359	
   360	    This intentionally recognizes only the two signals the guard itself can cause,
   361	    in both Bash reporting shapes.  Every other gate failure remains a red gate.
   362	    """
   363	    if cpu_s <= 0:
   364	        return returncode, None
   365	    if returncode in (128 + signal.SIGXCPU, -signal.SIGXCPU):
   366	        return (GATE_GUARD_KILL_EXIT,
   367	                f"gate-guard: gate exceeded the {cpu_s}s CPU cap (SIGXCPU)")
   368	    if returncode in (128 + signal.SIGKILL, -signal.SIGKILL):
   369	        return (GATE_GUARD_KILL_EXIT,
   370	                f"gate-guard: gate ignored SIGXCPU and hit the "
   371	                f"{cpu_s + GATE_CPU_HARD_MARGIN_S}s hard CPU cap (SIGKILL)")
   372	    return returncode, None
   373	
   374	
   375	def main():
   376	    parser = argparse.ArgumentParser(description="marathon-drive", add_help=False)
   377	    parser.add_argument("--phase-brief", dest="phase_brief_file")
   378	    parser.add_argument("--builder", dest="builder", default="codex")  # GH-212: no per-call API charge
   379	    parser.add_argument("--reviewer", dest="reviewer")
   380	    parser.add_argument("--round-cap", dest="round_cap", type=int, default=5)
   381	    parser.add_argument("--pre-advance-cmd", dest="pre_advance_cmd")
   382	    parser.add_argument("--post-approve-cmd", dest="post_approve_cmd")
   383	    parser.add_argument("--phases-dir", dest="phases_dir")
   384	    parser.add_argument("--phase-id", dest="phase_id", default="p1")
   385	    parser.add_argument("--relay-task", dest="relay_task")
   386	    parser.add_argument("--artifact", dest="artifact_paths")
   387	    parser.add_argument("--target-root", dest="target_root")
   388	    parser.add_argument("--require-clean", dest="require_clean", action="store_true")
   389	    parser.add_argument("--requires-test", dest="requires_test")  # GH-249: nominated test must change
   390	    parser.add_argument("--force", dest="force", action="store_true")
   391	    parser.add_argument("--dry-run", dest="dry_run", action="store_true")
   392	    parser.add_argument("--log-github", dest="log_github", action="store_true")  # GH-284 P2 / GH-322
   393	    parser.add_argument("--help", action="store_true")
   394	
   395	    args, unknown = parser.parse_known_args()
   396	    if args.help:
   397	        print("Usage: relay-automation/marathon-drive.sh --phase-brief FILE --reviewer AGENT [options]")
   398	        print("  --pre-advance-cmd CMD   Gate before phase.approved (default: bash validate.sh).")
   399	        print("  --post-approve-cmd CMD  Optional command after phase.approved + green telemetry (default: unset).")
   400	        print("                           Failure preserves approval, writes reason post-approve-failed, and exits 9.")
   401	        print("  --log-github            GH-284 opt-in run log (default OFF). Updates the lane's EXISTING GitHub")
   402	        print("                          issue in place via a marker comment — never creates an issue, never closes")
   403	        print("                          one. A missing/unauthenticated gh degrades to local telemetry only.")
   404	        sys.exit(0)
   405	
   406	    # GH-322: `unknown` was captured and never read, so ANY unrecognised flag was silently
   407	    # discarded. Because Python is the executing lane (GH-264), that made `--log-github` — the
   408	    # headline feature of GH-284 Phase 2, which existed only in the Bash twin — a no-op: the marathon
   409	    # ran, exited 0, reported success, and never posted a run log. All three Bash twins `die
   410	    # "unknown argument: $1"`; this restores that contract byte-for-byte (same prefix, same exit 2).
   650	        if ctx == "marathon-phase": return
   651	        if not os.access(xyz_append_bin, os.X_OK): return
   652	        
   653	        harness = "swarm" if ctx == "swarm" else "marathon"
   654	        title = os.path.splitext(os.path.basename(args.phase_brief_file))[0]
   655	        if not title: title = args.phase_id
   656	        
   657	        sid = get_env("XYZ_SESSION_ID", args.phase_id)
   658	        subprocess.run([xyz_append_bin, harness, sid, health, title, desc], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
   659	
   660	    # GH-75/GH-249 lifecycle heartbeat: write operational liveness before driving the relay and clear
   661	    # it on any terminal path (registered via atexit right after the write, so every success/failure
   662	    # branch clears it). Best-effort — never changes marathon-drive's exit code. Mirrors Bash
   663	    # xyz_marathon_heartbeat_write/clear (relay-automation/marathon-drive.sh).
   664	    xyz_heartbeat_bin = get_env("XYZ_HEARTBEAT_BIN", os.path.join(xyz_harness, "utils", "telemetry", "write-xyz-heartbeat.sh"))
   665	
   666	    def _heartbeat(clear):
   667	        if not os.access(xyz_heartbeat_bin, os.X_OK):
   668	            return
   669	        ctx = get_env("XYZ_HARNESS_CONTEXT", "")
   670	        harness = "swarm" if ctx == "swarm" else "marathon"
   671	        sid = get_env("XYZ_SESSION_ID", args.phase_id)
   672	        env = os.environ.copy()
   673	        if clear:
   674	            env["XYZ_HEARTBEAT_CLEAR"] = "1"
   675	        try:
   676	            subprocess.run([xyz_heartbeat_bin, harness, sid], env=env,
   677	                           stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
   678	        except Exception:
   679	            pass
   680	
   681	    def xyz_marathon_heartbeat_write():
   682	        _heartbeat(clear=False)
   683	
   684	    def xyz_marathon_heartbeat_clear():
   685	        _heartbeat(clear=True)
   686	
   687	    phases_dir = args.phases_dir or os.path.join(root, "phases")
   688	    # GH-319: the default gate is interpolated into a string that run_pre_advance_gate() hands to
   689	    # `bash -c`, so an UNQUOTED root word-splits on any space in the repo path. Observed live: a
   690	    # clone at ".../Documents/GH Repos/xyz-3-agents-swarm" produced `bash /Users/.../Documents/GH
   691	    # Repos/.../validate.sh`, bash executed the unrelated 0-byte file `/Users/.../Documents/GH`, and
   692	    # the gate returned 0 in 0.0s. Every phase of a 4-lane marathon reported "gate passed" while
   693	    # validate.sh was in fact RED. shlex.quote is the fix; the preflight below already knew to strip
   694	    # quotes off the script arg, it was just never given a quoted default to strip.
   695	    # GH-268 item 8: a cross-repo lane had NO GATE. The default gate is this repo's validate.sh, and
   696	    # a foreign --target-root usually has none, so GH-238's runnability preflight refused the whole
   697	    # lane ("script file does not exist") — leaving the operator to either pass an explicit
   698	    # --pre-advance-cmd or run ungated. The beta report is what that costs: a Producer/Reviewer loop
   699	    # reached "Approved" while an independent audit of the same branch found 20 issues (1 critical,
   700	    # 4 high) in the file the relay built on. relay-automation/target-checks.sh knows how to ask a
   701	    # foreign repo for its OWN checks (php -l, phpcs, npm lint/test, pytest, ruff, make test), so a
   702	    # cross-repo lane gets a real gate by default instead of no gate. An explicit --pre-advance-cmd
   703	    # always wins.
   704	    #
   705	    # Codex cross-vendor consult (GH-268 item 9) found the first draft claimed "a target that HAS its
   706	    # own validate.sh keeps using it" while the code did the opposite — that case fell to the else
   707	    # branch and ran the HARNESS's validate.sh against a foreign repo. Both branches below now use
   708	    # the target's own path when --target-root is set.
   709	    #
   710	    # target_root is absolutised first: run_pre_advance_gate() executes with cwd=target_root, so a
  1100	
  1101	    _probe_agent_bin(args.builder, "builder")
  1102	    _probe_agent_bin(args.reviewer, "reviewer")
  1103	
  1104	    # GH-238 preflight runs AFTER the binary probes (missing builder/reviewer binary fails first, via
  1105	    # shutil.which with no subprocess) but BEFORE any render/tick/dispatch — so a non-runnable default
  1106	    # gate still halts with exit 2 before spending a turn.
  1107	    if args.dry_run:
  1108	        # dry-run never dispatches a turn, so surface the problem but keep going (matches Bash).
  1109	        try:
  1110	            _preflight_check_issue_closed()
  1111	            _preflight_pre_advance_gate()
  1112	        except SystemExit as _e:
  1113	            if _e.code not in (0, None):
  1114	                eprint("marathon-drive: (dry-run continues; a live run would halt here)")
  1115	    else:
  1116	        _preflight_check_issue_closed()
  1117	        _preflight_pre_advance_gate()
  1118	
  1119	    if args.artifact_paths:
  1120	        os.environ["ALLOW_PATHS"] = args.artifact_paths
  1121	    else:
  1122	        if "ALLOW_PATHS" in os.environ:
  1123	            del os.environ["ALLOW_PATHS"]
  1124	
  1125	    # GH-249: snapshot HEAD in the repo the artifact lands in (TARGET_ROOT when set, else ROOT) BEFORE
  1126	    # this phase's first commit, so requires_test_delta has a true "before this phase" baseline. Captured
  1127	    # unconditionally (cheap); unused unless --requires-test is set.
  1128	    pre_phase_head = ""
  1129	    try:
  1130	        pre_phase_head = subprocess.check_output(
  1131	            ["git", "-C", (args.target_root or root), "rev-parse", "HEAD"],
  1132	            stderr=subprocess.DEVNULL).decode("utf-8").strip()
  1133	    except Exception:
  1134	        pre_phase_head = ""
  1135	
  1136	    phase_dir = os.path.join(phases_dir, lane_state_key)
  1137	    relay_file = os.path.join(phase_dir, "RELAY.md")
  1138	    
  1139	    # repo-root-relative path
  1140	    if relay_file.startswith(root + "/"):
  1141	        rel_relay = relay_file[len(root)+1:]
  1142	    else:
  1143	        rel_relay = relay_file
  1144	
  1145	    # Bound early (moved ahead of Step 3's own copy below) so the GH-274 satisfied-lane check
  1146	    # just below — and the escalate/complete_phase_success defs it may call — read/write tick
  1147	    # state against the right repo even when a caller invoked us without pre-exporting it.
  1148	    os.environ["TICK_REPO_ROOT"] = root
  1149	
  1150	    # escalate/save_transcript/run_pre_advance_gate/file_status/terminal_status/token_state/
  1151	    # requires_test_delta/complete_phase_success are defined here (ahead of the render below)
  1152	    # instead of beside their original later call sites, so the GH-274 satisfied-lane
  1153	    # short-circuit just below — which must run BEFORE the render — can call
  1154	    # complete_phase_success directly rather than duplicating its gate/requires-test/telemetry
  1155	    # logic.
  1156	    def escalate(reason, rexit):
  1157	        # GH-407: every escalation records `gate:` — not-run / green / red — because the reason alone
  1158	        # cannot be trusted to say whether the gate executed, and the operator's first move on a
  1159	        # failed phase is decided by that one fact. `pre-advance-failed` sends them to read the diff
  1160	        # and the test output; when the gate never ran there IS no test output and nothing in the
  1161	        # record said so. Observed three times in one 10-lane marathon on 2026-08-02, wrong all three
  1162	        # times. It is recorded on EVERY reason, not only the gate-related ones, so the answer is
  1163	        # present even when the reason taxonomy is incomplete — which the issue itself argued is the
  1164	        # robust half of the fix. run_gate_result is the existing state that already knows this; no
  1165	        # parallel flag is introduced, because a second source of truth would be a third thing to
  1166	        # keep in sync.
  1167	        # Sentinel Tier 1 (GH-281/GH-342): harvest this failed phase's Side Findings BEFORE the
  1168	        # escalation record is written, matching marathon-drive.sh:848-853 — a phase that escalated
  1169	        # is exactly the one whose findings are about to be lost.
  1170	        xyz_harvest_findings(harvest_findings_bin, relay_file, root, args.target_root,
  1171	                             xyz_debug_log_file(root))
  1172	        esc_file = os.path.join(phase_dir, "ESCALATION.md")
  1173	        with open(esc_file, 'w') as f:
  1174	            f.write(f"""# ESCALATION — Marathon Phase {args.phase_id}
  1175	
  1176	phase: {args.phase_id}
  1177	task: {relay_task}
  1178	relay-drive-exit: {rexit}
  1179	reason: {reason}
  1180	gate: {run_gate_result[0]}
  1620	        #      falls back to the base token — i.e. exactly the pre-GH-385 behavior, which is safe.
  1621	        #
  1622	        # The rejection is logged rather than silently absorbed: a lane that rebuilds because its
  1623	        # directive was refused should say so, or this becomes another check nobody can see working.
  1624	        if args.relay_task:
  1625	            return relay_task
  1626	        recorded = ""
  1627	        try:
  1628	            with open(relay_file, "r", encoding="utf-8", errors="replace") as f:
  1629	                for line in f:
  1630	                    if not line.lstrip().startswith("<!-- marathon-drive:"):
  1631	                        continue
  1632	                    for field in line.split():
  1633	                        if field.startswith("task="):
  1634	                            recorded = field.split("=", 1)[1].strip()
  1635	                    break
  1636	        except OSError:
  1637	            pass
  1638	        if not recorded or recorded == relay_task:
  1639	            return relay_task
  1640	        if re.fullmatch(re.escape(relay_task) + r"-\d+", recorded):
  1641	            return recorded
  1642	        log(f"relay directive names task '{recorded}', which is not {relay_task} or a retry derivative of it "
  1643	            f"— ignoring it and resolving the satisfied check against {relay_task}")
  1644	        return relay_task
  1645	
  1646	    def satisfied_lane_terminal():
  1647	        if not os.path.isfile(relay_file):
  1648	            return False
  1649	        s = file_status()
  1650	        if not terminal_status(s):
  1651	            return False
  1652	        tstatus, _actor = token_state(completed_relay_task())
  1653	        return tstatus == "done"
  1654	
  1655	    if not args.dry_run and satisfied_lane_terminal():
  1656	        log(f"phase {args.phase_id} already reached a terminal relay (STATUS: {file_status()}, token done) — skipping render/reseed, re-running only the pre-advance gate")
  1657	        complete_phase_success("already-satisfied")
  1658	
  1659	    if not args.dry_run:
  1660	        try:
  1661	            out = subprocess.check_output(["git", "-C", root, "status", "--porcelain"], stderr=subprocess.DEVNULL).decode('utf-8')
  1662	            dirty = []
  1663	            for line in out.splitlines():
  1664	                if len(line) >= 4:
  1665	                    p = line[3:]
  1666	                    if not p.startswith("phases/") and not p.startswith(".tick/"):
  1667	                        dirty.append(p)
  1668	            if dirty:
  1669	                log("WARNING: workspace is not clean — an autonomous builder can be distracted by stray files.")
  1670	                for p in dirty:
  1671	                    if p: log(f"  • {p}")
  1672	                if args.require_clean:
  1673	                    die("--require-clean set and the workspace has pre-existing changes (above)")
  1674	        except Exception: pass
  1675	
  1676	    # GH-401: NOTHING below may touch the filesystem until the --dry-run exit has been passed. The
  1677	    # phase dir creation used to live here, above the render, so a dry run materialized phases/<id>/
  1678	    # in whatever repo it resolved to — the harness itself when no MARATHON_ROOT/--phases-dir was
  1679	    # given. Both the reads below (phase brief, prior-attempt peek) work fine against a phase dir that
  1680	    # does not exist yet, so the mkdir moves down next to the write it actually exists for.
  1681	    with open(args.phase_brief_file, "r") as f:
  1682	        brief_text = f.read()
  1683	
  1684	    # GH-162: peek at prior attempts BEFORE rendering so a re-fired phase carries the debug-mantra note.
  1685	    debug_mantra_prior = debug_mantra_prior_attempts(get_env("TICK_REPO_ROOT", root), lane_state_key)
  1686	    debug_mantra_text = debug_mantra_note(
  1687	        debug_mantra_prior, phase_dir, os.path.join(xyz_harness, "relay-automation", "DEBUG-MANTRA.md"))
  1688	
  1689	    tick_cli = tick_bin if tick_bin.startswith("/") else os.path.join(root, tick_bin)
  1690	
  1691	    if args.artifact_paths:
  1692	        claim_paths = f"{rel_relay},{args.artifact_paths}"
  1693	        builder_impl_line = f"Implement the brief by creating/editing the artifact file(s): {args.artifact_paths}"
  1694	        builder_scope_line = f"Edit ONLY these paths: {rel_relay} and {args.artifact_paths}. Do NOT run git. Do NOT touch any other file — the harness commits for you."
  1695	        reviewer_read_line = (
  1696	            f"Read the latest builder block above AND review the artifact file(s) on disk: {args.artifact_paths}. "
  1697	            "REVIEW THE WHOLE FILE, NOT JUST THE DIFF (GH-268): a beta test had this loop reach 'Approved' in two "
  1698	            "rounds while an independent audit of the same branch found 20 issues (1 critical, 4 high) — every one of "
  1699	            "them in the pre-existing code the change sat on, which nobody had read. Pre-existing defects in a file you "
  1700	            "are touching are IN SCOPE; say so explicitly if you find none. DECLARE IT: your review "
  1701	            "block MUST contain a literal 'swept file: yes' or 'swept file: no' line — without it a "
  1702	            "reviewer that skipped the sweep is indistinguishable in the transcript from one that did "
  1703	            "it and found nothing, which is exactly how those 20 issues stayed invisible."
  1704	        )
  1705	        reviewer_scope_line = f"Edit ONLY {rel_relay} (your review block + STATUS). Do NOT edit the artifact yourself — request changes instead. Do NOT run git."
  1706	    else:
  1707	        claim_paths = rel_relay
  1708	        builder_impl_line = "Record your work directly in this relay file (relay-only phase — no source file to edit)."
  1709	        builder_scope_line = f"Edit ONLY {rel_relay}. Do NOT run git. Do NOT touch any other file — the harness commits for you."
  1710	        reviewer_read_line = "Read the latest builder block above."
  1711	        reviewer_scope_line = "Do NOT run git. Do NOT touch any other file."
  1712	
  1713	    relay_content = f"""# Marathon Phase {args.phase_id}
  1714	STATUS: Open
  1715	NEXT: {args.builder} (Builder)
  1716	
  1717	<!-- marathon-drive: task={relay_task} builder={args.builder} reviewer={args.reviewer} round-cap={args.round_cap} -->
  1718	
  1719	## Phase Brief
  1720	
  1721	{brief_text}
  1722	{debug_mantra_text}
  1723	---
  1724	
  1725	▶ TAKE YOUR TURN ({args.builder} — BUILDER role)
  1726	
  1727	You are the BUILDER for this phase. Read the phase brief above and implement it.
  1728	1. {builder_impl_line}
  1729	2. Append a build block to this relay file: `### Round N · Builder · {args.builder}` summarizing what you did (files touched, key decisions).
  1730	3. Use this exact tick binary (run it from any directory): {tick_cli}
  1731	   - {tick_cli} claim {relay_task} --agent {args.builder} --paths "{claim_paths}"
  1732	   - {tick_cli} ping {relay_task} --agent {args.builder}
  1733	   - {tick_cli} release {relay_task} --agent {args.builder} --to {args.reviewer}
  1734	4. {builder_scope_line}
  1735	5. HAND OFF EXPLICITLY (GH-268): after releasing the token, end your turn by naming who acts next —
  1736	   "handing off to {args.reviewer} — {args.reviewer}, take your turn." A turn that ends without that line
  1737	   leaves a human guessing whether the relay is waiting on them or has stalled. Do this EVERY round,
  1738	   not just the first. ALSO, you MUST update the `NEXT:` line at the top of this file to exactly: `NEXT: {args.reviewer} (Reviewer)`
  1739	
  1740	---
  1741	
  1742	▶ TAKE YOUR TURN ({args.reviewer} — REVIEWER role)
  1743	
  1744	You are the REVIEWER for this phase. {reviewer_read_line}
  1745	1. Append a review block: `### Round N · Reviewer · {args.reviewer}` followed by your assessment.
     1	#!/usr/bin/env bash
     2	# FROZEN (GH-308): Python is authoritative — do not make behavior changes here.
     3	# Historical Bash fallback only; update utils/py/marathon_drive.py instead. See issue #308.
     4	set -euo pipefail
     5	
     6	# GH-112 opt-in Python mode: XYZ_PYTHON=1 reroutes this entry point to the Python port in
     7	# utils/py/ (same CLI contract + exit codes). Default (unset/0) runs the canonical Bash
     8	# implementation below — Bash stays the supported default until the port is promoted.
     9	if [[ "${XYZ_PYTHON-1}" == "1" ]]; then
    10	  # UPGRADE.md §4 Phase-2 hardening (GH-255): (2a) `-` not `:-` so an explicit empty XYZ_PYTHON reads
    11	  # as not-1 → Bash (load-bearing once the default flips to 1); (2b) require python3 >=3.8 and fall
    12	  # back to Bash with a warning if it's missing/too-old, so a bad interpreter degrades, not bricks.
    13	  if command -v python3 >/dev/null 2>&1 \
    14	     && python3 -c 'import sys; raise SystemExit(0 if sys.version_info >= (3,8) else 1)' 2>/dev/null; then
    15	    _xyz_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
    16	    export XYZ_ROOT="$_xyz_root"
    17	    export PYTHONPATH="$_xyz_root/utils/py${PYTHONPATH:+:$PYTHONPATH}"
    18	    exec python3 "$_xyz_root/utils/py/marathon_drive.py" "$@"
    19	  else
    20	    echo "xyz: XYZ_PYTHON=1 but python3 missing or < 3.8 — falling back to Bash" >&2
    21	  fi
    22	fi
    23	#
    24	# marathon-drive.sh — Phase 3: single-phase headless relay loop.
    25	#
    26	# Renders phases/p1/RELAY.md from the phase brief, seeds the tick token (handoff → builder),
    27	# calls relay-drive.sh unmodified, runs the pre-advance gate, emits phase events, and saves
    28	# the transcript. Does NOT reimplement any loop logic — relay-drive.sh IS the loop.
    29	#
    30	# Usage:
    31	#   relay-automation/marathon-drive.sh \
    32	#     --phase-brief <FILE>       phase brief (markdown; baked into the relay template)
    33	#     --reviewer    <AGENT_ID>   reviewer agent (codex* or gemini*)
    34	#     [--builder    <AGENT_ID>]  builder agent (default: codex — GH-212: no per-call API charge;
    35	#                                --builder claude spawns a billed headless Claude Code CLI
    36	#                                subprocess instead — an explicit, cost-acknowledged opt-in)
    37	#     [--round-cap  <N>]         relay-drive round cap (default: 5 = 2*2+1)
    38	#     [--pre-advance-cmd <CMD>]  gate before phase.approved (default: bash validate.sh)
    39	#     [--post-approve-cmd <CMD>] optional command after phase.approved + green telemetry (default: unset)
    40	#     [--phases-dir <DIR>]       where to create phases/<id>/ (default: <repo-root>/phases)
    41	#     [--phase-id <ID>]          which phase to drive: phases/<id>/ (default: p1; the orchestrator sets it)
    42	#     [--relay-task <ID>]        tick task name (default: MARATHON-<PHASE_ID>-TURN)
    43	#     [--artifact <PATHS>]       comma-separated repo-relative file(s) the builder may create/edit
    44	#                                beyond the relay file (passed to the shims as ALLOW_PATHS). Omit for
    45	#                                a relay-only phase (conversation → approval, no source edit).
    46	#     [--require-clean]          hard-stop if the workspace has pre-existing changes (unattended runs)
    47	#     [--requires-test <PATH>]   GH-249 requires_test contract field (opt-in): repo-relative test file
    48	#                                that must be added/modified since this phase started, or the gate
    49	#                                fails (exit 5) even if --pre-advance-cmd passed. Omit for phases with
    50	#                                no test surface (docs-only, config-only) — default behavior unchanged.
    51	#     [--log-github]             GH-284 opt-in run log: update the lane's existing GitHub issue with
    52	#                                one marker comment. Default OFF; missing/unauthenticated gh is ignored.
    53	#     [--dry-run]                render relay file and print tick seed cmd, then exit
    54	#
    55	# Environment overrides (for tests):
    56	#   MARATHON_ROOT         — git repo root (default: parent of this script's dir)
    57	#   MARATHON_RELAY_DRIVE  — relay-drive.sh path (default: this script's dir/relay-drive.sh)
    58	#   MARATHON_AGENT_CMD    — --agent-cmd value (default: this script's dir/marathon-agent.sh)
    59	#   TICK_BIN              — tick binary (default: <repo-root>/bin/tick)
    60	#
    61	# Exit: 0 phase approved + gate passed · 3 relay no-progress · 4 relay cap/mismatch ·
    62	#        5 pre-advance gate failed (also covers a failed --requires-test check — see ESCALATION.md
    63	#        reason: pre-advance-failed vs. requires-test-missing) ·
    64	#        6 containment violation (turn-taker reverted an off-lane edit) ·
    65	#        7 turn timeout / hang · 8 lane parked (GH-45 attempt cap — no token seeded; re-fire with
    66	#        --force) · 9 post-approve command failed (phase remains approved) · 2 usage.
    67	
    68	HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    69	# _xyz_harness: the directory containing relay-automation/ (and bin/, src/, utils/).
    70	# Vendored install: HERE is <target>/.xyz/relay-automation → _xyz_harness is <target>/.xyz
    71	# (basename ".xyz"). ROOT = work root = where git ops, phases/, .tick/, validate.sh live.
    72	_xyz_harness="$(cd "$HERE/.." && pwd)"
    73	if [ "$(basename "$_xyz_harness")" = ".xyz" ]; then
    74	  ROOT="${MARATHON_ROOT:-"$(cd "$_xyz_harness/.." && pwd)"}"
    75	else
    76	  ROOT="${MARATHON_ROOT:-"$_xyz_harness"}"
    77	fi
    78	# GH-30 Phase 2: transcript-root resolver (rtl_transcript_root) — redirects relay-system/ to
    79	# $XYZ_ARCHIVE_ROOT when set, else byte-for-byte "$ROOT/relay-system". Sourced beside this script.
    80	source "$HERE/relay-turn-lib.sh"
    81	TICK_BIN="${TICK_BIN:-"$_xyz_harness/bin/tick"}"
    82	RELAY_DRIVE_BIN="${MARATHON_RELAY_DRIVE:-"$HERE/relay-drive.sh"}"
    83	AGENT_CMD="${MARATHON_AGENT_CMD:-"$HERE/marathon-agent.sh"}"
    84	
    85	# GH-45 — QUEUE commitment contract: per-lane attempt cap (anti-rabbit-hole / WIP discipline).
    86	# lane_attempt_gate appends one line per fire to .tick/attempts/<lane> and REFUSES to start a lane at
    87	# >= LANE_MAX_ATTEMPTS (default 2, env-overridable) with exit 8 + a park message, seeding NO relay
    88	# token. --force bypasses for one fire and logs it. lane_attempt_reset clears the counter when a lane
    89	# COMPLETES successfully (Approved), so the cap counts CONSECUTIVE failures and can never permanently
    90	# wedge a lane (reviewer feedback: without a reset a default-keyed lane parks forever). A nested call
    91	# (marathon-drive → relay-drive) is guarded by LANE_ATTEMPT_COUNTED so the same lane is counted (and
    92	# reset) exactly once. Byte-consistent mirror in relay-drive.sh; relay-turn-lib.sh/bin/tick untouched.
    93	_lane_key() { printf '%s' "$1" | tr -c 'A-Za-z0-9._-' '_'; }
    94	lane_attempt_gate() {
    95	  local root="$1" raw="$2" force="${3:-0}"
   580	  git -C "$root" status --porcelain -- "$git_path" 2>/dev/null | grep -qE '^(\?\?|A )' && return 0
   581	  return 1
   582	}
   583	
   584	requires_test_delta() {  # <path> — true if <path> was added/modified since PRE_PHASE_HEAD
   585	  path_has_nonempty_phase_delta "$1"
   586	}
   587	
   588	usage() {
   589	  cat <<'EOF'
   590	Usage: relay-automation/marathon-drive.sh --phase-brief FILE --reviewer AGENT [options]
   591	
   592	  --phase-brief FILE      Phase brief markdown baked into the relay template (required).
   593	  --reviewer AGENT        Reviewer agent id; must start with 'codex', 'gemini', or 'agy' (required).
   594	  --builder AGENT         Builder agent id (default: codex — GH-212: no per-call API charge; bills
   595	                          via the Codex/ChatGPT subscription, agy is the other cost-blind option).
   596	                          --builder claude spawns a headless Claude Code CLI subprocess instead: a
   597	                          SEPARATE, PER-CALL API-BILLED turn-taker — use it only as an explicit,
   598	                          cost-acknowledged choice, not the default.
   599	  --round-cap N           relay-drive turn cap (default: 5).
   600	  --pre-advance-cmd CMD   Gate before phase.approved (default: bash validate.sh).
   601	  --post-approve-cmd CMD  Optional command after phase.approved + green telemetry (default: unset).
   602	                          Failure preserves approval, writes reason post-approve-failed, and exits 9.
   603	  --phases-dir DIR        Where to create phases/<id>/ (default: <repo-root>/phases).
   604	  --phase-id ID           Which phase to drive: phases/<id>/ (default: p1).
   605	  --relay-task ID         Tick task name (default: MARATHON-<PHASE_ID>-TURN).
   606	  --artifact PATHS        Comma-separated repo-relative file(s) the builder may create/edit beyond
   607	                          the relay file (ALLOW_PATHS for the turn-takers). Omit for a relay-only phase.
   608	  --target-root DIR       Foreign git repo the BUILD lands in (GH-11). The relay thread + tick token
   609	                          stay in this repo; forwarded to relay-drive.sh, and the pre-advance gate runs
   610	                          with cwd = DIR. Omit for a same-repo phase.
   611	  --require-clean         Hard-stop (exit 2) if the workspace has pre-existing changes before seeding.
   612	  --requires-test PATH    GH-249 requires_test contract field (opt-in): repo-relative test file that
   613	                          must be added/modified by this phase, or the pre-advance gate fails (exit 5)
   614	                          even when --pre-advance-cmd passed. Omit for phases with no test surface
   615	                          (e.g. docs-only) — default gate behavior is unchanged without this flag.
   616	  --force                 GH-45: bypass the per-lane attempt cap for this fire (re-fire a parked lane).
   617	  --log-github            GH-284 opt-in run log (default OFF). Updates the lane's EXISTING GitHub
   618	                          issue in place via a marker comment — never creates an issue, never closes
   619	                          one. Records landed-on-trunk, driver liveness, branch, PR link (or an
   620	                          explicit NO PR OPENED), and the gate result. If gh is missing or
   621	                          unauthenticated it degrades to local telemetry and NEVER changes the
   622	                          marathon's own exit code.
   623	  --dry-run               Render the relay file and print the tick seed; exit without running.
   624	EOF
   625	}
   626	
   627	PHASE_BRIEF_FILE=""
   628	BUILDER="codex"
   629	REVIEWER=""
   630	ROUND_CAP=5
   631	PRE_ADVANCE_CMD=""   # resolved to default after ROOT is set
   632	POST_APPROVE_CMD=""  # optional command after approval + green telemetry; empty = disabled
   633	PHASES_DIR=""        # resolved to default after ROOT is set
   634	PHASE_ID="p1"        # which phase this invocation drives (phases/<id>/); the orchestrator sets it
   635	RELAY_TASK=""        # resolved to MARATHON-<PHASE_ID>-TURN after parsing, unless given
   636	ARTIFACT_PATHS=""    # comma-separated repo-relative file(s) the builder may create/edit (beyond RELAY.md)
   637	REQUIRE_CLEAN=0      # --require-clean: hard-stop if the workspace has pre-existing changes
   638	REQUIRES_TEST=""     # --requires-test PATH: GH-249 requires_test contract field (opt-in; empty = off)
   639	FORCE=0              # --force: bypass the GH-45 per-lane attempt cap for this one fire
   640	LOG_GITHUB=0         # GH-284: external run-log comment; opt-in only
   641	RUN_GATE_RESULT="not-run"
   642	DRY_RUN=0
   643	TARGET_ROOT=""       # --target-root: foreign repo the BUILD lands in (GH-11). Relay thread stays in ROOT;
   644	                     # forwarded to relay-drive.sh (which exports RELAY_TARGET_ROOT for artifact routing).
   645	
   646	while (($# > 0)); do
   647	  case "$1" in
   648	    --phase-brief)     PHASE_BRIEF_FILE="${2:-}"; shift 2 ;;
   649	    --builder)         BUILDER="${2:-}"; shift 2 ;;
   650	    --reviewer)        REVIEWER="${2:-}"; shift 2 ;;
   651	    --round-cap)       ROUND_CAP="${2:-}"; shift 2 ;;
   652	    --pre-advance-cmd) PRE_ADVANCE_CMD="${2:-}"; shift 2 ;;
   653	    --post-approve-cmd) POST_APPROVE_CMD="${2:-}"; shift 2 ;;
   654	    --phases-dir)      PHASES_DIR="${2:-}"; shift 2 ;;
   655	    --phase-id)        PHASE_ID="${2:-}"; shift 2 ;;
   656	    --relay-task)      RELAY_TASK="${2:-}"; shift 2 ;;
   657	    --artifact)        ARTIFACT_PATHS="${2:-}"; shift 2 ;;
   658	    --target-root)     TARGET_ROOT="${2:-}"; shift 2 ;;
   659	    --require-clean)   REQUIRE_CLEAN=1; shift ;;
   660	    --requires-test)   REQUIRES_TEST="${2:-}"; shift 2 ;;
   661	    --force)           FORCE=1; shift ;;
   662	    --log-github)      LOG_GITHUB=1; shift ;;
   663	    --dry-run)         DRY_RUN=1; shift ;;
   664	    --help)            usage; exit 0 ;;
   665	    *)                 die "unknown argument: $1" ;;
   666	  esac
   667	done
   668	
   669	[[ -n "$PHASE_BRIEF_FILE" ]] || { usage; die "--phase-brief FILE required"; }
   670	[[ -f "$PHASE_BRIEF_FILE" ]] || die "phase brief not found: $PHASE_BRIEF_FILE"
   671	[[ -n "$REVIEWER"         ]] || { usage; die "--reviewer AGENT required"; }
   672	[[ -n "$BUILDER"          ]] || die "--builder cannot be empty"
   673	[[ -n "$PHASE_ID"         ]] || die "--phase-id cannot be empty"
   674	if [[ -n "$TARGET_ROOT" ]]; then
   675	  git -C "$TARGET_ROOT" rev-parse --show-toplevel >/dev/null 2>&1 \
   676	    || die "invalid --target-root (not a git repo): $TARGET_ROOT"
   677	fi
   678	
   679	PHASES_DIR="${PHASES_DIR:-"$ROOT/phases"}"
   680	# GH-319: this string is later run through `eval`, so an UNQUOTED $ROOT word-splits on any space in
   681	# the repo path. A clone at ".../GH Repos/xyz-3-agents-swarm" produced `bash /Users/.../Documents/GH`
   682	# — an unrelated 0-byte file — which exits 0 in 0.0s, so every phase reported "gate passed" while
   683	# validate.sh was RED. `printf %q` is the eval-safe form. This edit is a DELIBERATE EXCEPTION to the
   684	# GH-308 freeze on this file (agy review of PR #318, [Blocker]): the freeze routes *behavior* changes
   685	# to utils/py/marathon_drive.py, but leaving a silently-fake safety gate in the XYZ_PYTHON=0 fallback
   686	# is worse than the exception. Keep this byte-consistent with the Python twin.
   687	# Single quotes, not `printf %q`: %q backslash-escapes the space, which is eval-safe but still leaves
   688	# a space in the token, so the preflight regex below would capture ".../GH\" and die "script file does
   689	# not exist" — trading a false pass for a hard failure. Single-quoting is also byte-consistent with
   690	# what Python's shlex.quote() emits for the same path.
   691	PRE_ADVANCE_CMD="${PRE_ADVANCE_CMD:-"bash '$ROOT/validate.sh'"}"
   692	
   693	# GH-238: a vendored consumer normally has no root-level validate.sh.  Do not spend a builder and
   694	# reviewer turn only to discover that the default gate cannot start after approval.  This is a
   695	# deliberately non-executing probe: gates such as `test -f build/output` may only become true after
   696	# the builder runs, so executing them here would turn valid gates into false preflight failures.
   697	pre_advance_not_runnable() {  # <reason>
   698	  die "pre-advance gate not runnable: '$PRE_ADVANCE_CMD' ($1). Pass --pre-advance-cmd '<runnable command>' to override it."
   699	}
   700	preflight_pre_advance_gate() {
   800	_probe_claude_bin() {  # <role-label> — mirrors claude-turn.sh's own CLAUDE_BIN resolution (GH-58):
   801	                       # explicit CLAUDE_BIN override, else `claude` on PATH, else the local Claude
   802	                       # Code install fallback. Kept in lockstep so this probe never rejects a setup
   803	                       # the real dispatch would still accept.
   804	  if [[ -n "${CLAUDE_BIN:-}" ]]; then
   805	    command -v "$CLAUDE_BIN" >/dev/null 2>&1 && return 0
   806	  else
   807	    command -v claude >/dev/null 2>&1 && return 0
   808	    [[ -x "$HOME/.claude/local/claude" ]] && return 0
   809	  fi
   810	  die "$1 binary 'claude' not found on PATH (set CLAUDE_BIN or use a codex/agy --$1 agent)"
   811	}
   812	_probe_agent_bin() {  # <agent-id> <role-label>
   813	  case "$1" in
   814	    claude*) _probe_claude_bin "$2" ;;
   815	    codex*)  _probe_bin "${CODEX_BIN:-codex}" "$2" "$1" ;;
   816	    agy*)    _probe_bin "${AGY_BIN:-agy}"     "$2" "$1" ;;
   817	    aider*)  _probe_bin "${AIDER_BIN:-aider}" "$2" "$1" ;;
   818	  esac
   819	}
   820	_probe_agent_bin "$BUILDER"  builder
   821	_probe_agent_bin "$REVIEWER" reviewer
   822	
   823	# Artifact allowlist: when a phase targets real file(s), pass them as ALLOW_PATHS so the turn-takers
   824	# may create/edit them. The shared safety core (relay-turn-lib.sh) reverts ANY edit outside this
   825	# allowlist + the always-allowed relay file — so containment still holds; the builder just gains a
   826	# real write surface. Without --artifact, ALLOW_PATHS stays unset and the phase is relay-only.
   827	if [[ -n "$ARTIFACT_PATHS" ]]; then
   828	  export ALLOW_PATHS="$ARTIFACT_PATHS"
   829	else
   830	  unset ALLOW_PATHS
   831	fi
   832	
   833	PHASE_DIR="$PHASES_DIR/$LANE_STATE_KEY"
   834	RELAY_FILE="$PHASE_DIR/RELAY.md"
   835	REL_RELAY="${RELAY_FILE#"$ROOT"/}"   # repo-root-relative path the agent edits / declares in claim --paths
   836	
   837	# Bound early (moved ahead of Step 3's own copy below) so the GH-274 satisfied-lane check
   838	# just below — and the escalate/complete_phase_success defs it may call — read/write tick
   839	# state against the right repo even when a caller invoked us without pre-exporting it.
   840	export TICK_REPO_ROOT="$ROOT"
   841	
   842	# escalate/save_transcript/complete_phase_success are defined here (ahead of Step 1) instead
   843	# of beside their Step 6 call sites so the GH-274 satisfied-lane short-circuit below — which
   844	# must run BEFORE Step 1's render — can call complete_phase_success directly rather than
   845	# duplicating its gate/requires-test/telemetry logic.
   846	escalate() {  # <reason> <relay-exit>
   847	  local reason="$1" rexit="$2"
   848	  # Sentinel Tier 1 (GH-281): harvest a failed phase's Side Findings before they are lost.
   849	  if [[ "${XYZ_DEBUG_LOG:-0}" == "1" && -x "$HERE/harvest-findings.sh" ]]; then
   850	    "$HERE/harvest-findings.sh" --relay "$RELAY_FILE" \
   851	      --scope "${TARGET_ROOT:+target:$TARGET_ROOT}" --repo "${TARGET_ROOT:-$ROOT}" \
   852	      --out "${DEBUG_LOG_FILE:-$ROOT/debug.log}" >/dev/null 2>&1 || true
   853	  fi
   854	  cat > "$PHASE_DIR/ESCALATION.md" << ESC_EOF
   855	# ESCALATION — Marathon Phase ${PHASE_ID}
   856	
   857	phase: ${PHASE_ID}
   858	task: ${RELAY_TASK}
   859	relay-drive-exit: ${rexit}
   860	reason: ${reason}
   861	relay-file: ${REL_RELAY}
   862	ESC_EOF
   863	  git -C "$ROOT" add -- "$PHASE_DIR/ESCALATION.md"
   864	  git -C "$ROOT" commit -q -m "marathon: phase ${PHASE_ID} escalation (${reason})"
   865	  "$TICK_BIN" log marathon.phase.escalated "$RELAY_TASK" --agent marathon > /dev/null || true
   866	  log "escalation written: $PHASE_DIR/ESCALATION.md (reason: $reason)"
   867	  xyz_debug_log_append error "marathon.escalation" "$reason (relay-drive-exit=$rexit)" \
   868	    "$REL_RELAY" "promote to PROJECT/1-INBOX capture doc"
   869	}
   870	
   871	save_transcript() {
   872	  # GH-30 Phase 2: resolve the transcript base (honors XYZ_ARCHIVE_ROOT; hard-errors if set-invalid).
   873	  # Declare then assign separately so the resolver's exit code isn't masked by `local` under set -e.
   874	  local date_dir _ts_base; _ts_base="$(rtl_transcript_root "$ROOT")" || return 1
   875	  date_dir="$_ts_base/$(date +%Y-%m-%d)"
   876	  mkdir -p "$date_dir"
   877	  local ts; ts="$(date +%H%M%S)"
   878	  local dest="$date_dir/marathon-${PHASE_ID}-${ts}.md"
   879	  cp "$RELAY_FILE" "$dest"
   880	  # Sentinel Tier 1 (GH-281): harvest Side Findings from the saved transcript.
   881	  if [[ "${XYZ_DEBUG_LOG:-0}" == "1" && -x "$HERE/harvest-findings.sh" ]]; then
   882	    "$HERE/harvest-findings.sh" --relay "$RELAY_FILE" \
   883	      --scope "${TARGET_ROOT:+target:$TARGET_ROOT}" --repo "${TARGET_ROOT:-$ROOT}" \
   884	      --out "${DEBUG_LOG_FILE:-$ROOT/debug.log}" >/dev/null 2>&1 || true
   885	  fi
   886	  git -C "$ROOT" add -- "$dest"
   887	  if git -C "$ROOT" diff --cached --quiet -- "$dest"; then
   888	    log "transcript unchanged: $dest"
   889	  else
   890	    git -C "$ROOT" commit -q -m "marathon: phase ${PHASE_ID} transcript saved (${RELAY_TASK})"
   891	    log "transcript saved: $dest"
   892	  fi
   893	}
   894	
   895	complete_phase_success() {
   896	  local success_mode="${1:-approved}" gate_exit=0 post_approve_exit=0 success_text=""
   897	  log "relay approved — running pre-advance gate: $PRE_ADVANCE_CMD"
   898	  run_pre_advance_gate || gate_exit=$?
   899	  if [[ "$gate_exit" -ne 0 ]]; then
   900	    log "pre-advance gate FAILED (exit $gate_exit) — escalating"
   901	    escalate "pre-advance-failed" 0
   902	    xyz_marathon_heartbeat_clear
   903	    xyz_marathon_emit red "halted at phase ${PHASE_ID} — pre-advance gate failed"
   904	    exit 5
   905	  fi
   906	  if [[ -n "$REQUIRES_TEST" ]] && ! requires_test_delta "$REQUIRES_TEST"; then
   907	    log "requires-test FAILED — no new/updated test detected at: $REQUIRES_TEST"
   908	    escalate "requires-test-missing" 0
   909	    xyz_marathon_heartbeat_clear
   910	    xyz_marathon_emit red "halted at phase ${PHASE_ID} — required test not added/updated: $REQUIRES_TEST"
   911	    exit 5
   912	  fi
   913	  if [[ "$success_mode" == "already-satisfied" ]]; then
   914	    success_text="phase ${PHASE_ID} complete — lane_already_satisfied, reviewer approved, gate passed"
   915	  else
   916	    success_text="phase ${PHASE_ID} complete — STATUS: Approved, gate passed"
   917	  fi
   918	  "$TICK_BIN" log marathon.phase.approved "$RELAY_TASK" --agent marathon > /dev/null || true
   919	  lane_attempt_reset "${TICK_REPO_ROOT:-$ROOT}" "$LANE_STATE_KEY"
   920	  save_transcript
   921	  xyz_marathon_heartbeat_clear
   922	  log "$success_text"
   923	  xyz_marathon_emit green "$success_text"
   924	  if [[ -n "$POST_APPROVE_CMD" ]]; then
   925	    log "phase approved — running post-approve command: $POST_APPROVE_CMD"
   926	    run_post_approve_cmd || post_approve_exit=$?
   927	    if [[ "$post_approve_exit" -ne 0 ]]; then
   928	      log "post-approve command FAILED (exit $post_approve_exit) — phase remains approved; escalating closeout"
   929	      escalate "post-approve-failed" 0
   930	      exit 9
   931	    fi
   932	  fi
   933	  exit 0
   934	}
   935	
   936	# ── Step 0.4 (GH-274): satisfied-lane short-circuit ────────────────────────
   937	# A phase whose relay is already terminal AND whose tick token is already done needs no
   938	# render/reseed/relay-drive at all — only the pre-advance gate (and requires-test, if set)
   939	# re-run, exactly like any other already-satisfied completion. DRY_RUN is exempted: its whole
   940	# point is to render + show the tick seed for inspection, and there is nothing to commit or
   941	# seed on this path anyway.
   942	if ((! DRY_RUN)) && satisfied_lane_terminal; then
   943	  log "phase ${PHASE_ID} already reached a terminal relay (STATUS: $(file_status), token done) — skipping render/reseed, re-running only the pre-advance gate"
   944	  MARATHON_DRIVE_STARTED=1
   945	  complete_phase_success already-satisfied
   946	fi
   947	
   948	# GH-162: peek at prior attempts BEFORE rendering (read-only; lane_attempt_gate in Step 3 still owns
   949	# the append/park write) so a re-fired phase's relay file can carry the debug-mantra note. Empty
   950	# DEBUG_MANTRA_TEXT on a first fire (prior=0) — the render below is then byte-identical to before.
   951	DEBUG_MANTRA_PRIOR="$(debug_mantra_prior_attempts "${TICK_REPO_ROOT:-$ROOT}" "$LANE_STATE_KEY")"
   952	DEBUG_MANTRA_TEXT="$(debug_mantra_note "$DEBUG_MANTRA_PRIOR" "$PHASE_DIR" "$HERE/DEBUG-MANTRA.md")"
   953	
   954	# ── Step 0: clean-workspace check (Phase 3.6) ──────────────────────────────
   955	# Stray pre-existing files distract an autonomous builder — a 2026-06-17 dogfood builder was pulled
   956	# off-task by unrelated AUDIT/*.md briefs left in the tree. Surface them before seeding. Exclude the
   957	# marathon's own paths (phases/, .tick/). --require-clean turns the warning into a hard stop for
   958	# unattended runs (DRY_RUN skips it — nothing is committed).
   959	if ((! DRY_RUN)); then
   960	  dirty="$(git -C "$ROOT" status --porcelain 2>/dev/null \
   961	    | awk '{ p=substr($0,4); if (p !~ /^phases\// && p !~ /^\.tick\//) print p }')"
   962	  if [[ -n "$dirty" ]]; then
   963	    log "WARNING: workspace is not clean — an autonomous builder can be distracted by stray files."
   964	    while IFS= read -r p; do [[ -n "$p" ]] && log "  • $p"; done <<< "$dirty"
   965	    ((REQUIRE_CLEAN)) && die "--require-clean set and the workspace has pre-existing changes (above)"
   966	  fi
   967	fi
   968	
   969	# ── Step 1: render phases/p1/RELAY.md ──────────────────────────────────────
   970	
   971	mkdir -p "$PHASE_DIR"
   972	BRIEF_TEXT="$(cat "$PHASE_BRIEF_FILE")"
   973	
   974	# Bake the ABSOLUTE tick path into the relay. A headless turn's cwd is not guaranteed to be the
   975	# repo root, so a relative "./bin/tick" is a guess — a real builder turn (2026-06-17) looked for it
   976	# in the phase dir, logged "tick not present", and skipped the token handoff entirely (phase then
   977	# escalated no-progress). An absolute path the agent can run from anywhere removes that failure mode.
   978	TICK_CLI="$TICK_BIN"
   979	case "$TICK_CLI" in /*) ;; *) TICK_CLI="$ROOT/$TICK_CLI" ;; esac
   980	
   981	# Builder/reviewer instruction text + the tick claim --paths depend on whether this phase targets
   982	# real artifact file(s) (--artifact) or is relay-only. Built here so the heredoc stays a flat template.
   983	if [[ -n "$ARTIFACT_PATHS" ]]; then
   984	  CLAIM_PATHS="${REL_RELAY},${ARTIFACT_PATHS}"
   985	  BUILDER_IMPL_LINE="Implement the brief by creating/editing the artifact file(s): ${ARTIFACT_PATHS}"
   986	  BUILDER_SCOPE_LINE="Edit ONLY these paths: ${REL_RELAY} and ${ARTIFACT_PATHS}. Do NOT run git. Do NOT touch any other file — the harness commits for you."
   987	  REVIEWER_READ_LINE="Read the latest builder block above AND review the artifact file(s) on disk: ${ARTIFACT_PATHS}."
   988	  REVIEWER_SCOPE_LINE="Edit ONLY ${REL_RELAY} (your review block + STATUS). Do NOT edit the artifact yourself — request changes instead. Do NOT run git."
   989	else
   990	  CLAIM_PATHS="${REL_RELAY}"
     1	#!/usr/bin/env bash
     2	set -euo pipefail
     3	
     4	HERE="$(cd "$(dirname "$0")" && pwd)"
     5	
     6	# GH-401: this audit exists for GH-209 — "every test invocation of the marathon driver is
     7	# MARATHON_ROOT-scoped" — but its scope was two hardcoded filenames. An unscoped `--dry-run`
     8	# invocation in test/gh268-relay-cue-and-target-checks.sh therefore wrote phases/p1/RELAY.md into
     9	# the HARNESS repo on every `bash validate.sh`, and the audit reported PASS the whole time: it was
    10	# out of reach because of its FILENAME, not because it was safe. A guard whose coverage is a literal
    11	# list silently stops covering the thing it was written for the moment someone adds a file.
    12	#
    13	# Audit every test script instead, and let discover_file_metadata/find_invocation_target decide what
    14	# is actually an invocation — a file with none is simply skipped. The audit excludes only itself:
    15	# it necessarily contains the driver path literals it matches on, so it would self-report.
    16	FILES=()
    17	for candidate in "$HERE"/*.sh; do
    18	  [ "$candidate" = "${BASH_SOURCE[0]}" ] && continue
    19	  [ "$(basename "$candidate")" = "$(basename "${BASH_SOURCE[0]}")" ] && continue
    20	  FILES+=("$candidate")
    21	done
    22	
    23	safe_vars=()
    24	alias_names=()
    25	alias_targets=()
    26	failures=0
    27	checked=0
    28	
    29	add_safe_var() {
    30	  local candidate="$1"
    31	  local existing
    32	  for existing in "${safe_vars[@]}"; do
    33	    [ "$existing" = "$candidate" ] && return 0
    34	  done
    35	  safe_vars+=("$candidate")
    36	}
    37	
    38	reset_safe_vars() {
    39	  safe_vars=(A B)
    40	}
    41	
    42	is_safe_var() {
    43	  local candidate="$1"
    44	  local existing
    45	  for existing in "${safe_vars[@]}"; do
    46	    [ "$existing" = "$candidate" ] && return 0
    47	  done
    48	  return 1
    49	}
    50	
    51	reset_aliases() {
    52	  alias_names=()
    53	  alias_targets=()
    54	}
    55	
    56	set_alias() {
    57	  local name="$1"
    58	  local target="$2"
    59	  local i
    60	  for ((i = 0; i < ${#alias_names[@]}; i++)); do
    61	    if [ "${alias_names[$i]}" = "$name" ]; then
    62	      alias_targets[$i]="$target"
    63	      return 0
    64	    fi
    65	  done
    66	  alias_names+=("$name")
    67	  alias_targets+=("$target")
    68	}
    69	
    70	get_alias_target() {
    71	  local name="$1"
    72	  local i
    73	  for ((i = 0; i < ${#alias_names[@]}; i++)); do
    74	    if [ "${alias_names[$i]}" = "$name" ]; then
    75	      printf '%s\n' "${alias_targets[$i]}"
    76	      return 0
    77	    fi
    78	  done
    79	  return 1
    80	}
    81	
    82	line_has_safe_cwd() {
    83	  local line="$1"
    84	  local candidate
    85	  if [[ "$line" =~ cd[[:space:]]+\"\$([A-Z][A-Z0-9_]*)\" ]]; then
    86	    candidate="${BASH_REMATCH[1]}"
    87	    is_safe_var "$candidate"
    88	    return $?
    89	  fi
    90	  return 1
    91	}
    92	
    93	discover_file_metadata() {
    94	  local file="$1"
    95	  local line name target
    96	
    97	  reset_safe_vars
    98	  reset_aliases
    99	
   100	  while IFS= read -r line || [ -n "$line" ]; do
   101	    if [[ "$line" =~ ^([A-Z][A-Z0-9_]*)=\"\$WORK/ ]]; then
   102	      add_safe_var "${BASH_REMATCH[1]}"
   103	    fi
   104	
   105	    if [[ "$line" =~ ^([A-Z][A-Z0-9_]*)=.*relay-automation/(marathon|marathon-drive)\.sh ]]; then
   106	      name="${BASH_REMATCH[1]}"
   107	      target="${BASH_REMATCH[2]}"
   108	      set_alias "$name" "$target"
   109	    fi
   110	  done < "$file"
   111	}
   112	
   113	find_invocation_target() {
   114	  local line="$1"
   115	  local rest var target
   116	
   117	  if [[ "$line" == *'./.xyz/relay-automation/marathon-drive.sh'* ]]; then
   118	    printf '%s\n' "marathon-drive"
   119	    return 0
   120	  fi
   121	
   122	  if [[ "$line" == *'./.xyz/relay-automation/marathon.sh'* ]]; then
   123	    printf '%s\n' "marathon"
   124	    return 0
   125	  fi
   126	
   127	  rest="${line#*bash \"\$}"
   128	  if [ "$rest" != "$line" ]; then
   129	    var="${rest%%\"*}"
   130	    target="$(get_alias_target "$var" || true)"
   131	    if [ -n "$target" ]; then
   132	      printf '%s\n' "$target"
   133	      return 0
   134	    fi
   135	  fi
   136	
   137	  return 1
   138	}
   139	
   140	check_invocation_safety() {
   141	  local idx="$1"
   142	  shift
   143	  local -a lines=("$@")
   144	  local start j boundary_found=0
   145	  local line="${lines[$idx]}"
   146	
   147	  if [[ "$line" == *'MARATHON_ROOT='* ]]; then
   148	    return 0
   149	  fi
   150	
   151	  if line_has_safe_cwd "$line"; then
   152	    return 0
   153	  fi
   154	
   155	  for ((j = idx - 1; j >= 0; j--)); do
   156	    if [[ "${lines[$j]}" == *'MARATHON_ROOT='* ]]; then
   157	      return 0
   158	    fi
   159	    if line_has_safe_cwd "${lines[$j]}"; then
   160	      return 0
   161	    fi
   162	    [[ "${lines[$j]}" =~ \\[[:space:]]*$ ]] || break
   163	  done
   164	
   165	  start=$((idx > 40 ? idx - 40 : 0))
   166	  for ((j = idx - 1; j >= start; j--)); do
   167	    if [[ "${lines[$j]}" =~ ^[[:space:]]*[A-Za-z_][A-Za-z0-9_]*[[:space:]]*\(\)[[:space:]]*\{ ]]; then
   168	      start="$j"
   169	      boundary_found=1
   170	      break
   171	    fi
   172	    if [[ "${lines[$j]}" =~ ^[[:space:]]*\([[:space:]]*$ ]]; then
   173	      start="$j"
   174	      boundary_found=1
   175	      break
   176	    fi
   177	  done
   178	
   179	  [ "$boundary_found" -eq 1 ] || return 1
   180	
   181	  for ((j = start; j < idx; j++)); do
   182	    if [[ "${lines[$j]}" == *'MARATHON_ROOT='* ]]; then
   183	      return 0
   184	    fi
   185	    if line_has_safe_cwd "${lines[$j]}"; then
   186	      return 0
   187	    fi
   188	  done
   189	
   190	  return 1
   191	}
   192	
   193	audit_file() {
   194	  local file="$1"
   195	  local -a lines=()
   196	  local line target idx
   197	
   198	  discover_file_metadata "$file"
   199	
   200	  while IFS= read -r line || [ -n "$line" ]; do
   201	    lines+=("$line")
   202	  done < "$file"
   203	
   204	  for ((idx = 0; idx < ${#lines[@]}; idx++)); do
   205	    target="$(find_invocation_target "${lines[$idx]}" || true)"
   206	    [ -z "$target" ] && continue
   207	    checked=$((checked + 1))
   208	    if check_invocation_safety "$idx" "${lines[@]}"; then
   209	      printf 'PASS: %s:%d %s invocation is rooted or fixture-local\n' \
   210	        "${file#$HERE/}" "$((idx + 1))" "$target"
   211	    else
   212	      printf 'FAIL: %s:%d %s invocation lacks MARATHON_ROOT and fixture-local cwd\n' \
   213	        "${file#$HERE/}" "$((idx + 1))" "$target" >&2
   214	      failures=$((failures + 1))
   215	    fi
   216	  done
   217	}
   218	
   219	for file in "${FILES[@]}"; do
   220	  audit_file "$file"
   221	done
   222	
   223	if [ "$checked" -eq 0 ]; then
   224	  echo "FAIL: no real marathon script invocations found to audit" >&2
   225	  exit 1
   226	fi
   227	
   228	if [ "$failures" -ne 0 ]; then
   229	  echo "FAIL: $failures unsafe marathon invocation(s) found" >&2
   230	  exit 1
   231	fi
   232	
   233	echo "PASS: audited $checked real marathon invocation(s)"
   234	
   235	# ── the driver commits phase artifacts, so they must not be gitignored ────────────────────────────
   236	# marathon_drive.py stages phase output with `git add --` and check=True at three sites
   237	# (:1129 ESCALATION.md, :1169, :1728 RELAY.md). `git add` on an EXPLICIT path that .gitignore covers
   238	# exits 1 — "The following paths are ignored ... Use -f if you really want to add them" — so
   239	# check=True raises CalledProcessError and the phase dies while trying to record itself.
   240	#
   241	# Not hypothetical: `/phases/` was added to .gitignore on 2026-08-09 to stop the #401/#461 churn, and
   242	# it would have crashed the first new same-repo phase. Reverted the same day; this assertion is what
   243	# makes the revert stick. Verified directly before writing it: in a scratch repo ignoring /phases/,
   244	# `git add -- phases/newrun/RELAY.md` exits 1.
   245	#
   246	# If phase records should stop being committed, that is a driver change (and a #388 durability
   247	# question), not a .gitignore line — the ignore alone breaks the write without removing the intent.
   248	audit_root="$(cd "$(dirname "$0")/.." && pwd)"
   249	ignore_violations=0
   250	for probe in phases/audit-probe/RELAY.md phases/audit-probe/ESCALATION.md; do
   251	  if git -C "$audit_root" check-ignore -q "$probe" 2>/dev/null; then
   252	    echo "FAIL: .gitignore covers $probe, but the driver stages it with \`git add --\` + check=True — a new same-repo phase would exit 1 while recording itself" >&2
   253	    ignore_violations=$((ignore_violations + 1))
   254	  fi
   255	done
   256	if [ "$ignore_violations" -ne 0 ]; then
   257	  exit 1
   258	fi
   259	echo "PASS: phase artifacts the driver commits are not gitignored (git add -- would exit 1 if they were)"
     1	#!/usr/bin/env bash
     2	# GH-308 — Freeze the Bash compatibility twins while keeping XYZ_PYTHON=0 reversible.
     3	#
     4	# Guard usage for a real change:
     5	#   bash test/gh308-frozen-twin-guard.sh --check --staged
     6	#   GH308_FROZEN_TWIN_BASE=<merge-base> bash test/gh308-frozen-twin-guard.sh --check
     7	#   bash test/gh308-frozen-twin-guard.sh --check --base REV --allow-exceptions   # what CI runs
     8	# The normal test validates the banners and demonstrates committed-range blocking in a throwaway repo.
     9	set -euo pipefail
    10	
    11	HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    12	ROOT="${GH308_GUARD_ROOT:-$(cd "$HERE/.." && pwd)}"
    13	TWINS=(
    14	  relay-automation/agy-turn.sh:utils/py/agy-turn.py
    15	  relay-automation/aider-turn.sh:utils/py/aider-turn.py
    16	  relay-automation/claude-turn.sh:utils/py/claude-turn.py
    17	  relay-automation/codex-turn.sh:utils/py/codex-turn.py
    18	  relay-automation/pi-turn.sh:utils/py/pi-turn.py
    19	  relay-automation/poll.sh:utils/py/poll.py
    20	  relay-automation/relay-loop.sh:utils/py/relay_loop.py
    21	  relay-automation/relay-drive.sh:utils/py/relay_drive.py
    22	  relay-automation/consult.sh:utils/py/consult.py
    23	  relay-automation/marathon-drive.sh:utils/py/marathon_drive.py
    24	  utils/swarm-preflight.sh:utils/py/swarm_preflight.py
    25	  # GH-362: marathon-plan was GH-308's ONE documented exception — its Bash body stayed authoritative
    26	  # and dual-maintained because the "port" delegated to a copied, drifted node engine. GH-340 removed
    27	  # that reason: `utils/py/_marathon_plan.py` is a native stdlib engine, the copied JS is deleted, and
    28	  # the Python lane needs no Node. The exception outlived its rationale, so it is retired here and
    29	  # marathon-plan becomes the 12th frozen twin.
    30	  utils/marathon-plan.sh:utils/py/marathon_plan.py
    31	)
    32	
    33	mode=test staged=0 base="" allow_exceptions=0
    34	while (($#)); do
    35	  case "$1" in
    36	    --check) mode=check ;;
    37	    --staged) staged=1 ;;
    38	    --base) base="${2:?--base needs a revision}"; shift ;;
    39	    --allow-exceptions) allow_exceptions=1 ;;
    40	    --help)
    41	      sed -n '2,9p' "$0"
    42	      exit 0
    43	      ;;
    44	    *) printf 'usage: %s [--check [--staged | --base REV] [--allow-exceptions]]\n' "$0" >&2; exit 2 ;;
    45	  esac
    46	  shift
    47	done
    48	
    49	frozen_paths() {
    50	  local pair
    51	  for pair in "${TWINS[@]}"; do printf '%s\n' "${pair%%:*}"; done
    52	}
    53	
    54	check_changes() {
    55	  local -a paths=()
    56	  local pair
    57	  for pair in "${TWINS[@]}"; do paths+=("${pair%%:*}"); done
    58	  local changed
    59	  if (( staged )); then
    60	    changed="$(git -C "$ROOT" diff --cached --name-only -- "${paths[@]}")"
    61	  else
    62	    [[ -n "$base" ]] || { echo 'gh308 guard: --check needs --staged or --base REV' >&2; return 2; }
    63	    git -C "$ROOT" rev-parse --verify "${base}^{commit}" >/dev/null
    64	    changed="$(git -C "$ROOT" diff --name-only "${base}..HEAD" -- "${paths[@]}")"
    65	  fi
    66	  if [[ -n "$changed" ]]; then
    67	    printf 'gh308 guard: FROZEN Bash twin edit blocked; change its Python twin instead:\n%s\n' "$changed" >&2
    68	    return 1
    69	  fi
    70	  echo 'gh308 guard: no frozen Bash twin changed'
    71	}
    72	
    73	# ── GH-321: per-file exception coverage ─────────────────────────────────────────────────────────
    74	# The escape hatch shipped in PR #318 was RANGE-scoped: one `Frozen-twin-exception:` trailer anywhere
    75	# in BASE..HEAD excused EVERY frozen-twin edit in the PR, including files nobody reasoned about, in
    76	# commits that declared nothing. CI then printed "1 commit(s) declare Frozen-twin-exception —
    77	# allowing:" and listed the declaring commit, so the log read like a narrow reviewed exception when
    78	# it was a blanket one — the undeclared edit was never named. Marathon PRs are the common case and
    79	# the worst shape for it: 4+ autonomous lanes on one branch make an undeclared twin edit riding
    80	# behind someone else's declared exception the expected accident, not an exotic one.
    81	#
    82	# A trailer must now name the twin(s) it covers, and every changed twin must be named by some trailer
    83	# in the range:
    84	#
    85	#   Frozen-twin-exception: relay-automation/marathon-drive.sh — silently-fake pre-advance gate (GH-319)
    86	#
    87	# Per-file coverage across the range, deliberately NOT "the trailer must be on the same commit as the
    88	# edit": a later fixup commit correcting an earlier one is ordinary and should not need its own
    89	# re-declaration. What the looseness actually cost was attribution, and naming the file recovers it.
    90	#
    91	# The reason text is separated by an em dash (or ` -- `) and is NOT scanned for paths, so a reason may
    92	# freely mention `validate.sh` or any other file without being read as a coverage claim.
    93	is_frozen_path() {  # <path>
    94	  local pair
    95	  for pair in "${TWINS[@]}"; do [[ "${pair%%:*}" == "$1" ]] && return 0; done
    96	  return 1
    97	}
    98	
    99	# ── GH-362: the freeze itself is not a violation of the freeze ───────────────────────────────────
   100	# A range whose base predates the freeze contains the commit that ADDED the FROZEN banners, and that
   101	# commit necessarily touches every frozen twin. The guard was structurally unable to pass there: it
   102	# blocked the release PR that first merged `development` into `main` (#361), naming all 11 twins,
   103	# with nothing wrong in the diff.
   104	#
   105	# The predicate is narrow on purpose. A commit that *introduces* a path's FROZEN banner establishes
   106	# the freeze for that path; edits to that path AFTER that commit are ordinary violations and are
   107	# still caught. So this exempts the establishing edit, not the file.
   108	#
   109	# Not self-limiting, despite appearances: once `main` contains the freeze, later `main..development`
   110	# ranges are clean — but a bisect run, a long-lived branch, a fork comparing against an old base, or
   111	# a release branch cut from before the freeze all reach back past it again.
   112	freeze_commit_for() {  # <base> <path> → stdout: the commit in base..HEAD that introduced FROZEN, or ""
   113	  local base="$1" path="$2" out
   114	  # Deliberately NOT `| head -1`: head closing the pipe early makes git's write fail, and under
   115	  # `set -euo pipefail` that surfaced as `printf: write error: Interrupted system call` on every call.
   116	  # Take the first line in-shell instead.
   117	  out="$(git -C "$ROOT" log --format=%H --reverse -S 'FROZEN' "${base}..HEAD" -- "$path" 2>/dev/null || true)"
   118	  [[ -n "$out" ]] || return 0
   119	  printf '%s\n' "${out%%$'\n'*}"
   120	}
   121	
   122	# Is every edit to <path> in this range at-or-before the commit that froze it?
   123	path_edits_are_only_the_freeze() {  # <base> <path>
   124	  local base="$1" path="$2" fc after
   125	  fc="$(freeze_commit_for "$base" "$path")"
   126	  [[ -n "$fc" ]] || return 1                     # the freeze is not in this range; nothing to exempt
   127	  # Any commit touching the path strictly after the freeze commit is a real post-freeze edit.
   128	  after="$(git -C "$ROOT" log --format=%H "${fc}..HEAD" -- "$path" 2>/dev/null)"
   129	  [[ -z "$after" ]]
   130	}
   131	
   132	# The set of commits in the range that establish a freeze for at least one twin. Their commit
   133	# messages predate the GH-321 per-file trailer format, so their trailers must not hard-fail parsing.
   134	freeze_establishing_commits() {  # <base> → stdout: one SHA per line
   135	  local base="$1" pair p fc
   136	  for pair in "${TWINS[@]}"; do
   137	    p="${pair%%:*}"
   138	    fc="$(freeze_commit_for "$base" "$p")"
   139	    [[ -n "$fc" ]] && printf '%s\n' "$fc"
   140	  done | sort -u
   141	}
   142	
   143	collect_declared() {  # <base> → stdout: covered paths, one per line. rc 1 if ANY trailer is malformed.
   144	  local base="$1" rc=0 line rest paths_part reason token found
   145	  local -a skip_commits=()
   146	  # GH-362(B): a malformed trailer used to hard-fail the WHOLE run, even when it sat in a commit whose
   147	  # edits need no coverage at all. `07ae1e7` is exactly that case — its trailer is the pre-GH-321 bare
   148	  # form (`Frozen-twin-exception: <reason>`, no path), which was correct when written, and it is the
   149	  # freeze-establishing commit whose edits (A) already exempts. Git history cannot be rewritten, so
   150	  # the format change shipped in GH-321 needs this back-compat or it permanently rejects its own past.
   151	  #
   152	  # Scoped deliberately: ONLY freeze-establishing commits are skipped. Every other commit still gets
   153	  # the full GH-321 treatment, so a new pathless trailer is still rejected — which is what GH-321 was
   154	  # actually for.
   155	  # Portable collect: `mapfile` is a bash 4+ builtin and macOS ships bash 3.2, which this repo's
   156	  # scripts must keep working under.
   157	  local _sc
   158	  while IFS= read -r _sc; do
   159	    [[ -n "$_sc" ]] && skip_commits+=("$_sc")
   160	  done < <(freeze_establishing_commits "$base")
   161	  while IFS= read -r line; do
   162	    case "$line" in
   163	      Frozen-twin-exception:*) ;;
   164	      *) continue ;;
   165	    esac
   166	    rest="${line#Frozen-twin-exception:}"
   167	    if [[ "$rest" == *"—"* ]]; then
   168	      paths_part="${rest%%—*}"; reason="${rest#*—}"
   169	    elif [[ "$rest" == *" -- "* ]]; then
   170	      paths_part="${rest%% -- *}"; reason="${rest#* -- }"
   171	    else
   172	      # Includes the legacy bare form (`Frozen-twin-exception: <reason>`), which named no file and is
   173	      # exactly what made the hatch blanket-scoped. Failing loudly beats covering nothing in silence.
   174	      printf 'gh308 guard: malformed Frozen-twin-exception trailer — no path/reason separator:\n  %s\n' "$line" >&2
   175	      printf '  expected: Frozen-twin-exception: <path>[, <path>...] — <reason>\n' >&2
   176	      rc=1; continue
   177	    fi
   178	    if [[ ! "$reason" =~ [^[:space:]] ]]; then
   179	      printf 'gh308 guard: Frozen-twin-exception trailer has no reason text:\n  %s\n' "$line" >&2
   180	      rc=1; continue
   181	    fi
   182	    found=0
   183	    paths_part="${paths_part//,/ }"
   184	    for token in $paths_part; do   # deliberate word splitting: the path list is space/comma separated
   185	      if is_frozen_path "$token"; then
   186	        printf '%s\n' "$token"
   187	        found=1
   188	      else
   189	        printf 'gh308 guard: Frozen-twin-exception names a path that is not a frozen twin: %s\n' "$token" >&2
   190	        printf '  A typo here would silently cover nothing, so it fails instead. Frozen twins:\n' >&2
   191	        frozen_paths | sed 's/^/    /' >&2
   192	        rc=1
   193	      fi
   194	    done
   195	    if (( found == 0 )); then
   196	      printf 'gh308 guard: Frozen-twin-exception trailer names no frozen twin:\n  %s\n' "$line" >&2
   197	      rc=1
   198	    fi
   199	  done < <(eligible_trailer_lines "$base" "${skip_commits[@]+"${skip_commits[@]}"}")
   200	  return "$rc"
   201	}
   202	
   203	# Emit trailer candidate lines from every commit in base..HEAD EXCEPT the given skip commits, with
   204	# git-standard indented continuation lines folded onto their trailer.
   205	#
   206	# Folding is limited to INDENTED continuations, which is the form `git interpret-trailers` recognises.
   207	# A trailer wrapped flush-left (as `07ae1e7`'s is) is indistinguishable from the start of the next
   208	# paragraph, and guessing would let arbitrary prose become part of a coverage claim. Such a trailer is
   209	# therefore still read as its first line only — correct, and harmless now that (A)/(B) stop that
   210	# commit from failing the run. Wrap new trailers with indentation, or keep them on one line.
   211	eligible_trailer_lines() {  # <base> [skip-sha...]
   212	  local base="$1"; shift
   213	  local -a skip=("$@")
   214	  local sha body line pending="" s skipthis
   215	  while IFS= read -r sha; do
   216	    [[ -n "$sha" ]] || continue
   217	    skipthis=0
   218	    for s in ${skip[@]+"${skip[@]}"}; do [[ "$s" == "$sha" ]] && { skipthis=1; break; }; done
   219	    (( skipthis )) && continue
   220	    pending=""
   221	    while IFS= read -r line; do
   222	      if [[ -n "$pending" && "$line" =~ ^[[:space:]]+[^[:space:]] ]]; then
   223	        # indented continuation of the trailer we are holding
   224	        pending="$pending ${line#"${line%%[![:space:]]*}"}"
   225	        continue
   226	      fi
   227	      [[ -n "$pending" ]] && { printf '%s\n' "$pending"; pending=""; }
   228	      case "$line" in
   229	        Frozen-twin-exception:*) pending="$line" ;;
   230	        *) printf '%s\n' "$line" ;;
   231	      esac
   232	    done < <(git -C "$ROOT" log -1 --format='%B' "$sha")
   233	    [[ -n "$pending" ]] && printf '%s\n' "$pending"
   234	  done < <(git -C "$ROOT" log --format=%H "${base}..HEAD")
   235	}
   236	
   237	check_exception_coverage() {  # <base> — called only after check_changes has already failed
   238	  local base="$1" changed declared f uncovered=0
   239	  local -a paths=()
   240	  local pair
   241	  for pair in "${TWINS[@]}"; do paths+=("${pair%%:*}"); done
   242	  changed="$(git -C "$ROOT" diff --name-only "${base}..HEAD" -- "${paths[@]}")"
   243	  declared="$(collect_declared "$base")" || return 1
   244	  while IFS= read -r f; do
   245	    [[ -n "$f" ]] || continue
   246	    # GH-362(A): the commit that established this path's freeze is not a violation of it. Only exempt
   247	    # when the freeze is the LAST thing that touched the path in this range — a later edit is real.
   248	    if path_edits_are_only_the_freeze "$base" "$f"; then
   249	      printf 'gh308 guard: %s — the only edit in this range IS the commit that froze it (%s)\n' \
   250	        "$f" "$(freeze_commit_for "$base" "$f" | cut -c1-8)"
   251	    elif printf '%s\n' "$declared" | grep -Fxq -- "$f"; then
   252	      printf 'gh308 guard: %s — covered by a declared Frozen-twin-exception\n' "$f"
   253	    else
   254	      # Name the file. The whole defect in the range-scoped version was that it never did.
   255	      printf 'gh308 guard: %s was edited with NO Frozen-twin-exception trailer naming it\n' "$f" >&2
   256	      uncovered=1
   257	    fi
   258	  done <<EOF
   259	$changed
   260	EOF
   261	  if (( uncovered )); then
   262	    printf 'gh308 guard: put the fix in the Python twin, or declare the exception per file:\n' >&2
   263	    printf '  Frozen-twin-exception: <path> — <reason>\n' >&2
   264	    return 1
   265	  fi
   266	  return 0
   267	}
   268	
   269	if [[ "$mode" == check ]]; then
   270	  if (( allow_exceptions )) && (( staged )); then
   271	    echo 'gh308 guard: --allow-exceptions needs --base REV (staged changes have no commit trailers yet)' >&2
   272	    exit 2
   273	  fi
   274	  rc=0
   275	  check_changes || rc=$?
   276	  (( rc == 0 )) && exit 0
   277	  (( rc == 2 )) && exit 2
   278	  (( allow_exceptions )) || exit "$rc"
   279	  echo "---"
   280	  if check_exception_coverage "$base"; then
   281	    # Wording matters: an edit can be permitted for two different reasons and conflating them would
   282	    # let a reader believe a declaration exists where none does (GH-362).
   283	    echo 'gh308 guard: every frozen-twin edit in this range is accounted for — declared, or the freeze itself'
   284	    exit 0
   285	  fi
   286	  exit 1
   287	fi
   288	
   289	# CI supplies the merge-base explicitly; local validation intentionally stays structural so the
   290	# bootstrap commit that adds these banners can establish the frozen baseline.
   291	if [[ -n "${GH308_FROZEN_TWIN_BASE:-}" ]]; then
   292	  base="$GH308_FROZEN_TWIN_BASE"
   293	  check_changes
   294	fi
   295	
   296	pass=0 fail=0
   297	ok() { echo "  PASS: $1"; pass=$((pass + 1)); }
   298	bad() { echo "  FAIL: $1"; fail=$((fail + 1)); }
   299	echo '== test: gh308-frozen-twin-guard =='
   300	
   301	for pair in "${TWINS[@]}"; do
   302	  sh_path="${pair%%:*}"; py_path="${pair#*:}"
   303	  if [[ -f "$ROOT/$py_path" ]] && grep -Fq '# FROZEN (GH-308): Python is authoritative' "$ROOT/$sh_path" \
   304	      && grep -Fq "$py_path" "$ROOT/$sh_path" && grep -Fq 'issue #308' "$ROOT/$sh_path"; then
   305	    ok "$sh_path is frozen in favor of $py_path"
   306	  else
   307	    bad "$sh_path needs its GH-308 FROZEN banner and Python pointer ($py_path)"
   308	  fi
   309	done
   310	
   311	# GH-362: this assertion is INVERTED from what it pinned before. marathon-plan was GH-308's one
   312	# Bash-authoritative exception; GH-340 deleted the copied node engine that was its entire rationale,
   313	# so the exception is retired and the file is the 12th frozen twin. Kept as an explicit assertion
   314	# rather than deleted, so a future revert of the freeze fails loudly instead of silently restoring an
   315	# exception whose reason no longer exists.
   316	if grep -Fq 'FROZEN (GH-308)' "$ROOT/utils/marathon-plan.sh"; then
   317	  ok 'marathon-plan is frozen — the GH-308 exception is retired (GH-362)'
   318	else
   319	  bad 'marathon-plan lost its FROZEN banner: the GH-362 retirement was reverted without a decision'
   320	fi

2026-08-10T04:58:18.763156Z ERROR codex_models_manager::manager: failed to renew cache TTL: missing field `base_instructions` at line 95 column 5
exec
/bin/zsh -lc "rg -n -C 5 'git.*add|check=True|PHASES_DIR|phases/|phase_dir|git status|awk' utils/py/marathon_drive.py relay-automation/marathon-drive.sh
rg -n -i --glob '*.py' --glob '*.sh' --glob '"'!temp/**'"' --glob '"'!PROJECT/**'"' --glob '"'!test/**'"' '(phases/|/phases|\"phases\"|\\x27phases\\x27|PHASES_DIR|phases-dir)' .
rg -n -i --glob '*.sh' --glob '*.py' 'marathon-drive|phases-dir|PHASES_DIR|MARATHON_ROOT' test utils relay-automation | head -1000" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-67768-b0m00j9w
 succeeded in 0ms:
relay-automation/marathon-drive.sh-21-  fi
relay-automation/marathon-drive.sh-22-fi
relay-automation/marathon-drive.sh-23-#
relay-automation/marathon-drive.sh-24-# marathon-drive.sh — Phase 3: single-phase headless relay loop.
relay-automation/marathon-drive.sh-25-#
relay-automation/marathon-drive.sh:26:# Renders phases/p1/RELAY.md from the phase brief, seeds the tick token (handoff → builder),
relay-automation/marathon-drive.sh-27-# calls relay-drive.sh unmodified, runs the pre-advance gate, emits phase events, and saves
relay-automation/marathon-drive.sh-28-# the transcript. Does NOT reimplement any loop logic — relay-drive.sh IS the loop.
relay-automation/marathon-drive.sh-29-#
relay-automation/marathon-drive.sh-30-# Usage:
relay-automation/marathon-drive.sh-31-#   relay-automation/marathon-drive.sh \
--
relay-automation/marathon-drive.sh-35-#                                --builder claude spawns a billed headless Claude Code CLI
relay-automation/marathon-drive.sh-36-#                                subprocess instead — an explicit, cost-acknowledged opt-in)
relay-automation/marathon-drive.sh-37-#     [--round-cap  <N>]         relay-drive round cap (default: 5 = 2*2+1)
relay-automation/marathon-drive.sh-38-#     [--pre-advance-cmd <CMD>]  gate before phase.approved (default: bash validate.sh)
relay-automation/marathon-drive.sh-39-#     [--post-approve-cmd <CMD>] optional command after phase.approved + green telemetry (default: unset)
relay-automation/marathon-drive.sh:40:#     [--phases-dir <DIR>]       where to create phases/<id>/ (default: <repo-root>/phases)
relay-automation/marathon-drive.sh:41:#     [--phase-id <ID>]          which phase to drive: phases/<id>/ (default: p1; the orchestrator sets it)
relay-automation/marathon-drive.sh-42-#     [--relay-task <ID>]        tick task name (default: MARATHON-<PHASE_ID>-TURN)
relay-automation/marathon-drive.sh-43-#     [--artifact <PATHS>]       comma-separated repo-relative file(s) the builder may create/edit
relay-automation/marathon-drive.sh-44-#                                beyond the relay file (passed to the shims as ALLOW_PATHS). Omit for
relay-automation/marathon-drive.sh-45-#                                a relay-only phase (conversation → approval, no source edit).
relay-automation/marathon-drive.sh-46-#     [--require-clean]          hard-stop if the workspace has pre-existing changes (unattended runs)
--
relay-automation/marathon-drive.sh-66-#        --force) · 9 post-approve command failed (phase remains approved) · 2 usage.
relay-automation/marathon-drive.sh-67-
relay-automation/marathon-drive.sh-68-HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
relay-automation/marathon-drive.sh-69-# _xyz_harness: the directory containing relay-automation/ (and bin/, src/, utils/).
relay-automation/marathon-drive.sh-70-# Vendored install: HERE is <target>/.xyz/relay-automation → _xyz_harness is <target>/.xyz
relay-automation/marathon-drive.sh:71:# (basename ".xyz"). ROOT = work root = where git ops, phases/, .tick/, validate.sh live.
relay-automation/marathon-drive.sh-72-_xyz_harness="$(cd "$HERE/.." && pwd)"
relay-automation/marathon-drive.sh-73-if [ "$(basename "$_xyz_harness")" = ".xyz" ]; then
relay-automation/marathon-drive.sh-74-  ROOT="${MARATHON_ROOT:-"$(cd "$_xyz_harness/.." && pwd)"}"
relay-automation/marathon-drive.sh-75-else
relay-automation/marathon-drive.sh-76-  ROOT="${MARATHON_ROOT:-"$_xyz_harness"}"
--
relay-automation/marathon-drive.sh-136-# attempt (prior=0) — mirrors relay-turn-lib.sh's rtl_drift_brief "say nothing when there is nothing to
relay-automation/marathon-drive.sh-137-# say" convention, so a normal first-fire relay file is byte-identical to before this feature existed.
relay-automation/marathon-drive.sh-138-# Cites the last ESCALATION.md reason (if any) as the concrete breadcrumb, rather than inventing a new
relay-automation/marathon-drive.sh-139-# ledger — GH-162 Phase 0 found the harness already persists exactly this evidence.
relay-automation/marathon-drive.sh-140-debug_mantra_note() {  # <prior-count> <phase-dir> <debug-mantra-file>
relay-automation/marathon-drive.sh:141:  local prior="$1" phase_dir="$2" mantra_file="$3" reason=""
relay-automation/marathon-drive.sh-142-  [ "${prior:-0}" -ge 1 ] 2>/dev/null || return 0
relay-automation/marathon-drive.sh:143:  [ -f "$phase_dir/ESCALATION.md" ] && reason="$(sed -n 's/^reason:[[:space:]]*//p' "$phase_dir/ESCALATION.md" | head -1)"
relay-automation/marathon-drive.sh-144-  printf '\n## Debug mantra (auto-triggered — %s prior attempt(s) on this phase did not reach Approved)\n\n' "$prior"
relay-automation/marathon-drive.sh-145-  printf 'Before trying again, read %s and follow its four-step discipline: reproduce reliably, know the fail path, question the hypothesis, treat this round as a breadcrumb for the next one.\n' "$mantra_file"
relay-automation/marathon-drive.sh-146-  if [ -n "$reason" ]; then
relay-automation/marathon-drive.sh:147:    printf 'Last recorded reason (%s/ESCALATION.md): `%s`. Read it before re-guessing.\n' "$phase_dir" "$reason"
relay-automation/marathon-drive.sh-148-  fi
relay-automation/marathon-drive.sh-149-}
relay-automation/marathon-drive.sh-150-
relay-automation/marathon-drive.sh-151-# GH-222 (COST-OBSERVABILITY-PLAN.md Phase 6 follow-on): auto-surface the `tick analyze` cost block
relay-automation/marathon-drive.sh-152-# at end-of-run so a marathon-drive.sh phase (standalone or as one phase of a marathon.sh chain)
--
relay-automation/marathon-drive.sh-598-                          cost-acknowledged choice, not the default.
relay-automation/marathon-drive.sh-599-  --round-cap N           relay-drive turn cap (default: 5).
relay-automation/marathon-drive.sh-600-  --pre-advance-cmd CMD   Gate before phase.approved (default: bash validate.sh).
relay-automation/marathon-drive.sh-601-  --post-approve-cmd CMD  Optional command after phase.approved + green telemetry (default: unset).
relay-automation/marathon-drive.sh-602-                          Failure preserves approval, writes reason post-approve-failed, and exits 9.
relay-automation/marathon-drive.sh:603:  --phases-dir DIR        Where to create phases/<id>/ (default: <repo-root>/phases).
relay-automation/marathon-drive.sh:604:  --phase-id ID           Which phase to drive: phases/<id>/ (default: p1).
relay-automation/marathon-drive.sh-605-  --relay-task ID         Tick task name (default: MARATHON-<PHASE_ID>-TURN).
relay-automation/marathon-drive.sh-606-  --artifact PATHS        Comma-separated repo-relative file(s) the builder may create/edit beyond
relay-automation/marathon-drive.sh-607-                          the relay file (ALLOW_PATHS for the turn-takers). Omit for a relay-only phase.
relay-automation/marathon-drive.sh-608-  --target-root DIR       Foreign git repo the BUILD lands in (GH-11). The relay thread + tick token
relay-automation/marathon-drive.sh-609-                          stay in this repo; forwarded to relay-drive.sh, and the pre-advance gate runs
--
relay-automation/marathon-drive.sh-628-BUILDER="codex"
relay-automation/marathon-drive.sh-629-REVIEWER=""
relay-automation/marathon-drive.sh-630-ROUND_CAP=5
relay-automation/marathon-drive.sh-631-PRE_ADVANCE_CMD=""   # resolved to default after ROOT is set
relay-automation/marathon-drive.sh-632-POST_APPROVE_CMD=""  # optional command after approval + green telemetry; empty = disabled
relay-automation/marathon-drive.sh:633:PHASES_DIR=""        # resolved to default after ROOT is set
relay-automation/marathon-drive.sh:634:PHASE_ID="p1"        # which phase this invocation drives (phases/<id>/); the orchestrator sets it
relay-automation/marathon-drive.sh-635-RELAY_TASK=""        # resolved to MARATHON-<PHASE_ID>-TURN after parsing, unless given
relay-automation/marathon-drive.sh-636-ARTIFACT_PATHS=""    # comma-separated repo-relative file(s) the builder may create/edit (beyond RELAY.md)
relay-automation/marathon-drive.sh-637-REQUIRE_CLEAN=0      # --require-clean: hard-stop if the workspace has pre-existing changes
relay-automation/marathon-drive.sh-638-REQUIRES_TEST=""     # --requires-test PATH: GH-249 requires_test contract field (opt-in; empty = off)
relay-automation/marathon-drive.sh-639-FORCE=0              # --force: bypass the GH-45 per-lane attempt cap for this one fire
--
relay-automation/marathon-drive.sh-649-    --builder)         BUILDER="${2:-}"; shift 2 ;;
relay-automation/marathon-drive.sh-650-    --reviewer)        REVIEWER="${2:-}"; shift 2 ;;
relay-automation/marathon-drive.sh-651-    --round-cap)       ROUND_CAP="${2:-}"; shift 2 ;;
relay-automation/marathon-drive.sh-652-    --pre-advance-cmd) PRE_ADVANCE_CMD="${2:-}"; shift 2 ;;
relay-automation/marathon-drive.sh-653-    --post-approve-cmd) POST_APPROVE_CMD="${2:-}"; shift 2 ;;
relay-automation/marathon-drive.sh:654:    --phases-dir)      PHASES_DIR="${2:-}"; shift 2 ;;
relay-automation/marathon-drive.sh-655-    --phase-id)        PHASE_ID="${2:-}"; shift 2 ;;
relay-automation/marathon-drive.sh-656-    --relay-task)      RELAY_TASK="${2:-}"; shift 2 ;;
relay-automation/marathon-drive.sh-657-    --artifact)        ARTIFACT_PATHS="${2:-}"; shift 2 ;;
relay-automation/marathon-drive.sh-658-    --target-root)     TARGET_ROOT="${2:-}"; shift 2 ;;
relay-automation/marathon-drive.sh-659-    --require-clean)   REQUIRE_CLEAN=1; shift ;;
--
relay-automation/marathon-drive.sh-674-if [[ -n "$TARGET_ROOT" ]]; then
relay-automation/marathon-drive.sh-675-  git -C "$TARGET_ROOT" rev-parse --show-toplevel >/dev/null 2>&1 \
relay-automation/marathon-drive.sh-676-    || die "invalid --target-root (not a git repo): $TARGET_ROOT"
relay-automation/marathon-drive.sh-677-fi
relay-automation/marathon-drive.sh-678-
relay-automation/marathon-drive.sh:679:PHASES_DIR="${PHASES_DIR:-"$ROOT/phases"}"
relay-automation/marathon-drive.sh-680-# GH-319: this string is later run through `eval`, so an UNQUOTED $ROOT word-splits on any space in
relay-automation/marathon-drive.sh-681-# the repo path. A clone at ".../GH Repos/xyz-3-agents-swarm" produced `bash /Users/.../Documents/GH`
relay-automation/marathon-drive.sh-682-# — an unrelated 0-byte file — which exits 0 in 0.0s, so every phase reported "gate passed" while
relay-automation/marathon-drive.sh-683-# validate.sh was RED. `printf %q` is the eval-safe form. This edit is a DELIBERATE EXCEPTION to the
relay-automation/marathon-drive.sh-684-# GH-308 freeze on this file (agy review of PR #318, [Blocker]): the freeze routes *behavior* changes
--
relay-automation/marathon-drive.sh-828-  export ALLOW_PATHS="$ARTIFACT_PATHS"
relay-automation/marathon-drive.sh-829-else
relay-automation/marathon-drive.sh-830-  unset ALLOW_PATHS
relay-automation/marathon-drive.sh-831-fi
relay-automation/marathon-drive.sh-832-
relay-automation/marathon-drive.sh:833:PHASE_DIR="$PHASES_DIR/$LANE_STATE_KEY"
relay-automation/marathon-drive.sh-834-RELAY_FILE="$PHASE_DIR/RELAY.md"
relay-automation/marathon-drive.sh-835-REL_RELAY="${RELAY_FILE#"$ROOT"/}"   # repo-root-relative path the agent edits / declares in claim --paths
relay-automation/marathon-drive.sh-836-
relay-automation/marathon-drive.sh-837-# Bound early (moved ahead of Step 3's own copy below) so the GH-274 satisfied-lane check
relay-automation/marathon-drive.sh-838-# just below — and the escalate/complete_phase_success defs it may call — read/write tick
--
relay-automation/marathon-drive.sh-858-task: ${RELAY_TASK}
relay-automation/marathon-drive.sh-859-relay-drive-exit: ${rexit}
relay-automation/marathon-drive.sh-860-reason: ${reason}
relay-automation/marathon-drive.sh-861-relay-file: ${REL_RELAY}
relay-automation/marathon-drive.sh-862-ESC_EOF
relay-automation/marathon-drive.sh:863:  git -C "$ROOT" add -- "$PHASE_DIR/ESCALATION.md"
relay-automation/marathon-drive.sh-864-  git -C "$ROOT" commit -q -m "marathon: phase ${PHASE_ID} escalation (${reason})"
relay-automation/marathon-drive.sh-865-  "$TICK_BIN" log marathon.phase.escalated "$RELAY_TASK" --agent marathon > /dev/null || true
relay-automation/marathon-drive.sh-866-  log "escalation written: $PHASE_DIR/ESCALATION.md (reason: $reason)"
relay-automation/marathon-drive.sh-867-  xyz_debug_log_append error "marathon.escalation" "$reason (relay-drive-exit=$rexit)" \
relay-automation/marathon-drive.sh-868-    "$REL_RELAY" "promote to PROJECT/1-INBOX capture doc"
--
relay-automation/marathon-drive.sh-881-  if [[ "${XYZ_DEBUG_LOG:-0}" == "1" && -x "$HERE/harvest-findings.sh" ]]; then
relay-automation/marathon-drive.sh-882-    "$HERE/harvest-findings.sh" --relay "$RELAY_FILE" \
relay-automation/marathon-drive.sh-883-      --scope "${TARGET_ROOT:+target:$TARGET_ROOT}" --repo "${TARGET_ROOT:-$ROOT}" \
relay-automation/marathon-drive.sh-884-      --out "${DEBUG_LOG_FILE:-$ROOT/debug.log}" >/dev/null 2>&1 || true
relay-automation/marathon-drive.sh-885-  fi
relay-automation/marathon-drive.sh:886:  git -C "$ROOT" add -- "$dest"
relay-automation/marathon-drive.sh-887-  if git -C "$ROOT" diff --cached --quiet -- "$dest"; then
relay-automation/marathon-drive.sh-888-    log "transcript unchanged: $dest"
relay-automation/marathon-drive.sh-889-  else
relay-automation/marathon-drive.sh-890-    git -C "$ROOT" commit -q -m "marathon: phase ${PHASE_ID} transcript saved (${RELAY_TASK})"
relay-automation/marathon-drive.sh-891-    log "transcript saved: $dest"
--
relay-automation/marathon-drive.sh-952-DEBUG_MANTRA_TEXT="$(debug_mantra_note "$DEBUG_MANTRA_PRIOR" "$PHASE_DIR" "$HERE/DEBUG-MANTRA.md")"
relay-automation/marathon-drive.sh-953-
relay-automation/marathon-drive.sh-954-# ── Step 0: clean-workspace check (Phase 3.6) ──────────────────────────────
relay-automation/marathon-drive.sh-955-# Stray pre-existing files distract an autonomous builder — a 2026-06-17 dogfood builder was pulled
relay-automation/marathon-drive.sh-956-# off-task by unrelated AUDIT/*.md briefs left in the tree. Surface them before seeding. Exclude the
relay-automation/marathon-drive.sh:957:# marathon's own paths (phases/, .tick/). --require-clean turns the warning into a hard stop for
relay-automation/marathon-drive.sh-958-# unattended runs (DRY_RUN skips it — nothing is committed).
relay-automation/marathon-drive.sh-959-if ((! DRY_RUN)); then
relay-automation/marathon-drive.sh-960-  dirty="$(git -C "$ROOT" status --porcelain 2>/dev/null \
relay-automation/marathon-drive.sh:961:    | awk '{ p=substr($0,4); if (p !~ /^phases\// && p !~ /^\.tick\//) print p }')"
relay-automation/marathon-drive.sh-962-  if [[ -n "$dirty" ]]; then
relay-automation/marathon-drive.sh-963-    log "WARNING: workspace is not clean — an autonomous builder can be distracted by stray files."
relay-automation/marathon-drive.sh-964-    while IFS= read -r p; do [[ -n "$p" ]] && log "  • $p"; done <<< "$dirty"
relay-automation/marathon-drive.sh-965-    ((REQUIRE_CLEAN)) && die "--require-clean set and the workspace has pre-existing changes (above)"
relay-automation/marathon-drive.sh-966-  fi
relay-automation/marathon-drive.sh-967-fi
relay-automation/marathon-drive.sh-968-
relay-automation/marathon-drive.sh:969:# ── Step 1: render phases/p1/RELAY.md ──────────────────────────────────────
relay-automation/marathon-drive.sh-970-
relay-automation/marathon-drive.sh-971-mkdir -p "$PHASE_DIR"
relay-automation/marathon-drive.sh-972-BRIEF_TEXT="$(cat "$PHASE_BRIEF_FILE")"
relay-automation/marathon-drive.sh-973-
relay-automation/marathon-drive.sh-974-# Bake the ABSOLUTE tick path into the relay. A headless turn's cwd is not guaranteed to be the
--
relay-automation/marathon-drive.sh-1044-  exit 0
relay-automation/marathon-drive.sh-1045-fi
relay-automation/marathon-drive.sh-1046-
relay-automation/marathon-drive.sh-1047-# ── Step 2: commit the relay file (rtl_before needs a clean HEAD) ───────────
relay-automation/marathon-drive.sh-1048-
relay-automation/marathon-drive.sh:1049:git -C "$ROOT" add -- "$RELAY_FILE"
relay-automation/marathon-drive.sh-1050-if git -C "$ROOT" diff --cached --quiet -- "$RELAY_FILE"; then
relay-automation/marathon-drive.sh-1051-  log "relay file unchanged: $RELAY_FILE"
relay-automation/marathon-drive.sh-1052-else
relay-automation/marathon-drive.sh-1053-  git -C "$ROOT" commit -q -m "marathon: render phase ${PHASE_ID} relay (${RELAY_TASK})"
relay-automation/marathon-drive.sh-1054-  log "relay file committed: $RELAY_FILE"
--
utils/py/marathon_drive.py-428-        die("--phase-id cannot be empty")
utils/py/marathon_drive.py-429-
utils/py/marathon_drive.py-430-    if args.target_root:
utils/py/marathon_drive.py-431-        try:
utils/py/marathon_drive.py-432-            subprocess.run(["git", "-C", args.target_root, "rev-parse", "--show-toplevel"], 
utils/py/marathon_drive.py:433:                           stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, check=True)
utils/py/marathon_drive.py-434-        except subprocess.CalledProcessError:
utils/py/marathon_drive.py-435-            die(f"invalid --target-root (not a git repo): {args.target_root}")
utils/py/marathon_drive.py-436-
utils/py/marathon_drive.py-437-    here = os.path.dirname(os.path.abspath(__file__))
utils/py/marathon_drive.py-438-    xyz_harness = os.path.abspath(os.path.join(here, "..", ".."))
--
utils/py/marathon_drive.py-518-                    return sum(1 for _ in fh)
utils/py/marathon_drive.py-519-            except Exception:
utils/py/marathon_drive.py-520-                return 0
utils/py/marathon_drive.py-521-        return 0
utils/py/marathon_drive.py-522-
utils/py/marathon_drive.py:523:    def debug_mantra_note(prior, phase_dir_, mantra_file):
utils/py/marathon_drive.py-524-        # GH-162: the note injected into the relay when a prior attempt exists; empty on a first fire
utils/py/marathon_drive.py-525-        # (prior=0) so a normal first-fire relay file stays byte-identical to before this feature.
utils/py/marathon_drive.py-526-        if not prior or prior < 1:
utils/py/marathon_drive.py-527-            return ""
utils/py/marathon_drive.py-528-        reason = ""
utils/py/marathon_drive.py:529:        esc = os.path.join(phase_dir_, "ESCALATION.md")
utils/py/marathon_drive.py-530-        if os.path.isfile(esc):
utils/py/marathon_drive.py-531-            try:
utils/py/marathon_drive.py-532-                with open(esc) as fh:
utils/py/marathon_drive.py-533-                    for line in fh:
utils/py/marathon_drive.py-534-                        if line.startswith("reason:"):
--
utils/py/marathon_drive.py-559-                return p
utils/py/marathon_drive.py-560-            return p if r.startswith("..") else r
utils/py/marathon_drive.py-561-
utils/py/marathon_drive.py-562-        harness_root = os.path.dirname(os.path.dirname(mantra_file))
utils/py/marathon_drive.py-563-        mantra_rel = _rel(mantra_file, harness_root)          # relay-automation/DEBUG-MANTRA.md
utils/py/marathon_drive.py:564:        phase_rel = _rel(phase_dir_, root)
utils/py/marathon_drive.py-565-        out = (f"\n## Debug mantra (auto-triggered — {prior} prior attempt(s) on this phase did not reach Approved)\n\n"
utils/py/marathon_drive.py-566-               f"Before trying again, read `{mantra_rel}` (relative to the harness root) and follow its "
utils/py/marathon_drive.py-567-               f"four-step discipline: reproduce reliably, know the fail path, question the hypothesis, treat this "
utils/py/marathon_drive.py-568-               f"round as a breadcrumb for the next one.\n")
utils/py/marathon_drive.py-569-        if reason:
--
utils/py/marathon_drive.py-1131-            ["git", "-C", (args.target_root or root), "rev-parse", "HEAD"],
utils/py/marathon_drive.py-1132-            stderr=subprocess.DEVNULL).decode("utf-8").strip()
utils/py/marathon_drive.py-1133-    except Exception:
utils/py/marathon_drive.py-1134-        pre_phase_head = ""
utils/py/marathon_drive.py-1135-
utils/py/marathon_drive.py:1136:    phase_dir = os.path.join(phases_dir, lane_state_key)
utils/py/marathon_drive.py:1137:    relay_file = os.path.join(phase_dir, "RELAY.md")
utils/py/marathon_drive.py-1138-    
utils/py/marathon_drive.py-1139-    # repo-root-relative path
utils/py/marathon_drive.py-1140-    if relay_file.startswith(root + "/"):
utils/py/marathon_drive.py-1141-        rel_relay = relay_file[len(root)+1:]
utils/py/marathon_drive.py-1142-    else:
--
utils/py/marathon_drive.py-1167-        # Sentinel Tier 1 (GH-281/GH-342): harvest this failed phase's Side Findings BEFORE the
utils/py/marathon_drive.py-1168-        # escalation record is written, matching marathon-drive.sh:848-853 — a phase that escalated
utils/py/marathon_drive.py-1169-        # is exactly the one whose findings are about to be lost.
utils/py/marathon_drive.py-1170-        xyz_harvest_findings(harvest_findings_bin, relay_file, root, args.target_root,
utils/py/marathon_drive.py-1171-                             xyz_debug_log_file(root))
utils/py/marathon_drive.py:1172:        esc_file = os.path.join(phase_dir, "ESCALATION.md")
utils/py/marathon_drive.py-1173-        with open(esc_file, 'w') as f:
utils/py/marathon_drive.py-1174-            f.write(f"""# ESCALATION — Marathon Phase {args.phase_id}
utils/py/marathon_drive.py-1175-
utils/py/marathon_drive.py-1176-phase: {args.phase_id}
utils/py/marathon_drive.py-1177-task: {relay_task}
utils/py/marathon_drive.py-1178-relay-drive-exit: {rexit}
utils/py/marathon_drive.py-1179-reason: {reason}
utils/py/marathon_drive.py-1180-gate: {run_gate_result[0]}
utils/py/marathon_drive.py-1181-relay-file: {rel_relay}
utils/py/marathon_drive.py-1182-""")
utils/py/marathon_drive.py:1183:        subprocess.run(["git", "-C", root, "add", "--", esc_file], check=True)
utils/py/marathon_drive.py-1184-        # GH-207: an identical escalation record must not HALT on nothing-to-commit.
utils/py/marathon_drive.py-1185-        if subprocess.run(["git", "-C", root, "diff", "--cached", "--quiet", "--", esc_file]).returncode != 0:
utils/py/marathon_drive.py:1186:            subprocess.run(["git", "-C", root, "commit", "-q", "-m", f"marathon: phase {args.phase_id} escalation ({reason})"], check=True)
utils/py/marathon_drive.py-1187-        # Archive the failed phase's relay transcript too — save_transcript otherwise runs only
utils/py/marathon_drive.py-1188-        # on success, so an escalated/reverted phase leaves no durable record of its rounds. The
utils/py/marathon_drive.py-1189-        # 2026-07-30 rebalance-OS marathon (GH-382's panic run) reverted its p5 phase twice and
utils/py/marathon_drive.py-1190-        # the relay state survived nowhere. Non-fatal: losing the archive must not mask the
utils/py/marathon_drive.py-1191-        # escalation itself.
--
utils/py/marathon_drive.py-1218-        shutil.copy2(relay_file, dest)
utils/py/marathon_drive.py-1219-        # Sentinel Tier 1 (GH-281/GH-342): harvest Side Findings from the saved transcript
utils/py/marathon_drive.py-1220-        # (marathon-drive.sh:880-885) — after the copy, before the commit, same as Bash.
utils/py/marathon_drive.py-1221-        xyz_harvest_findings(harvest_findings_bin, relay_file, root, args.target_root,
utils/py/marathon_drive.py-1222-                             xyz_debug_log_file(root))
utils/py/marathon_drive.py:1223:        subprocess.run(["git", "-C", root, "add", "--", dest], check=True)
utils/py/marathon_drive.py-1224-        # GH-207: an identical transcript (same-second re-render) must not HALT on nothing-to-commit.
utils/py/marathon_drive.py-1225-        if subprocess.run(["git", "-C", root, "diff", "--cached", "--quiet", "--", dest]).returncode == 0:
utils/py/marathon_drive.py-1226-            log(f"transcript unchanged: {dest}")
utils/py/marathon_drive.py-1227-        else:
utils/py/marathon_drive.py:1228:            subprocess.run(["git", "-C", root, "commit", "-q", "-m", f"marathon: phase {args.phase_id} transcript saved ({relay_task})"], check=True)
utils/py/marathon_drive.py-1229-            log(f"transcript saved: {dest}")
utils/py/marathon_drive.py-1230-        return True
utils/py/marathon_drive.py-1231-
utils/py/marathon_drive.py-1232-    # GH-307: the gate is a correctness check on the REPO — it is not part of this run's
utils/py/marathon_drive.py-1233-    # provenance, and it must not be able to see who is driving it. These tags otherwise leak
--
utils/py/marathon_drive.py-1661-            out = subprocess.check_output(["git", "-C", root, "status", "--porcelain"], stderr=subprocess.DEVNULL).decode('utf-8')
utils/py/marathon_drive.py-1662-            dirty = []
utils/py/marathon_drive.py-1663-            for line in out.splitlines():
utils/py/marathon_drive.py-1664-                if len(line) >= 4:
utils/py/marathon_drive.py-1665-                    p = line[3:]
utils/py/marathon_drive.py:1666:                    if not p.startswith("phases/") and not p.startswith(".tick/"):
utils/py/marathon_drive.py-1667-                        dirty.append(p)
utils/py/marathon_drive.py-1668-            if dirty:
utils/py/marathon_drive.py-1669-                log("WARNING: workspace is not clean — an autonomous builder can be distracted by stray files.")
utils/py/marathon_drive.py-1670-                for p in dirty:
utils/py/marathon_drive.py-1671-                    if p: log(f"  • {p}")
utils/py/marathon_drive.py-1672-                if args.require_clean:
utils/py/marathon_drive.py-1673-                    die("--require-clean set and the workspace has pre-existing changes (above)")
utils/py/marathon_drive.py-1674-        except Exception: pass
utils/py/marathon_drive.py-1675-
utils/py/marathon_drive.py-1676-    # GH-401: NOTHING below may touch the filesystem until the --dry-run exit has been passed. The
utils/py/marathon_drive.py:1677:    # phase dir creation used to live here, above the render, so a dry run materialized phases/<id>/
utils/py/marathon_drive.py-1678-    # in whatever repo it resolved to — the harness itself when no MARATHON_ROOT/--phases-dir was
utils/py/marathon_drive.py-1679-    # given. Both the reads below (phase brief, prior-attempt peek) work fine against a phase dir that
utils/py/marathon_drive.py-1680-    # does not exist yet, so the mkdir moves down next to the write it actually exists for.
utils/py/marathon_drive.py-1681-    with open(args.phase_brief_file, "r") as f:
utils/py/marathon_drive.py-1682-        brief_text = f.read()
utils/py/marathon_drive.py-1683-
utils/py/marathon_drive.py-1684-    # GH-162: peek at prior attempts BEFORE rendering so a re-fired phase carries the debug-mantra note.
utils/py/marathon_drive.py-1685-    debug_mantra_prior = debug_mantra_prior_attempts(get_env("TICK_REPO_ROOT", root), lane_state_key)
utils/py/marathon_drive.py-1686-    debug_mantra_text = debug_mantra_note(
utils/py/marathon_drive.py:1687:        debug_mantra_prior, phase_dir, os.path.join(xyz_harness, "relay-automation", "DEBUG-MANTRA.md"))
utils/py/marathon_drive.py-1688-
utils/py/marathon_drive.py-1689-    tick_cli = tick_bin if tick_bin.startswith("/") else os.path.join(root, tick_bin)
utils/py/marathon_drive.py-1690-
utils/py/marathon_drive.py-1691-    if args.artifact_paths:
utils/py/marathon_drive.py-1692-        claim_paths = f"{rel_relay},{args.artifact_paths}"
--
utils/py/marathon_drive.py-1773-        print(relay_content, end="")
utils/py/marathon_drive.py-1774-        print("--- END RENDERED RELAY ---")
utils/py/marathon_drive.py-1775-        print(f"tick seed: log task.created {relay_task} + claim --agent marathon + release --to {args.builder}")
utils/py/marathon_drive.py-1776-        sys.exit(0)
utils/py/marathon_drive.py-1777-
utils/py/marathon_drive.py:1778:    os.makedirs(phase_dir, exist_ok=True)
utils/py/marathon_drive.py-1779-    with open(relay_file, 'w') as f:
utils/py/marathon_drive.py-1780-        f.write(relay_content)
utils/py/marathon_drive.py-1781-
utils/py/marathon_drive.py:1782:    subprocess.run(["git", "-C", root, "add", "--", relay_file], check=True)
utils/py/marathon_drive.py-1783-    # GH-207: only commit when the render actually changed — a byte-identical re-render must not HALT on
utils/py/marathon_drive.py-1784-    # a "nothing to commit" git error; treat it as unchanged and continue.
utils/py/marathon_drive.py-1785-    if subprocess.run(["git", "-C", root, "diff", "--cached", "--quiet", "--", relay_file]).returncode == 0:
utils/py/marathon_drive.py-1786-        log(f"relay file unchanged: {relay_file}")
utils/py/marathon_drive.py-1787-    else:
utils/py/marathon_drive.py:1788:        subprocess.run(["git", "-C", root, "commit", "-q", "-m", f"marathon: render phase {args.phase_id} relay ({relay_task})"], check=True)
utils/py/marathon_drive.py-1789-        log(f"relay file committed: {relay_file}")
utils/py/marathon_drive.py-1790-
utils/py/marathon_drive.py-1791-    os.environ["TICK_REPO_ROOT"] = root
utils/py/marathon_drive.py-1792-
utils/py/marathon_drive.py-1793-    def reconcile_relay_task():
./sentinel-overlay/sentinel-nightly.sh:34:    print(f"{i('effort')+i('complexity')}\t{i('phases')}\t{p}")
./skills/skills-sync-trinity/scripts/render_working_doc.py:124:    parser.add_argument("--phase", action="append", dest="phases")
./relay-automation/marathon.sh:15:#   relay-automation/marathon.sh --plan MARATHON.yaml [--builder codex] [--phases-dir DIR]
./relay-automation/marathon.sh:84:Usage: marathon.sh --plan MARATHON.yaml [--builder A] [--phases-dir D] [--pre-advance-cmd C]
./relay-automation/marathon.sh:94:  --phases-dir DIR        Where to create phases/<id>/ (default: <repo-root>/phases).
./relay-automation/marathon.sh:96:                          The relay thread, tick token, phases/ and relay-system/ transcripts all stay
./relay-automation/marathon.sh:98:                          repo cannot track harness output (e.g. a public repo that gitignores phases/
./relay-automation/marathon.sh:111:PLAN=""; BUILDER="codex"; PHASES_DIR=""; PRE_ADVANCE_CMD=""; DRY_RUN=0; FORCE=0; RETRY_PHASE=""; CLOSEOUT_PR=0
./relay-automation/marathon.sh:117:    --phases-dir)      PHASES_DIR="${2:-}"; shift 2 ;;
./relay-automation/marathon.sh:167:PHASES_DIR="${PHASES_DIR:-"$ROOT/phases"}"
./relay-automation/marathon.sh:200:               --phase-brief "$brief_path" --round-cap "$cap" --phases-dir "$PHASES_DIR" )
./relay-automation/marathon-detail.sh:5:#   - STATUS: / NEXT: lines from the newest phases/*/RELAY.md (if any)
./relay-automation/marathon-detail.sh:39:# Newest phases/*/RELAY.md
./relay-automation/marathon-detail.sh:40:PHASES_DIR="$REPO/phases"
./relay-automation/marathon-detail.sh:42:if [ -d "$PHASES_DIR" ]; then
./relay-automation/marathon-detail.sh:44:  RELAY_FILE="$(ls -t "$PHASES_DIR"/*/RELAY.md 2>/dev/null | head -1 || true)"
./relay-automation/marathon-detail.sh:53:  printf '(no phases/*/RELAY.md found)\n'
./relay-automation/marathon-drive.sh:26:# Renders phases/p1/RELAY.md from the phase brief, seeds the tick token (handoff → builder),
./relay-automation/marathon-drive.sh:40:#     [--phases-dir <DIR>]       where to create phases/<id>/ (default: <repo-root>/phases)
./relay-automation/marathon-drive.sh:41:#     [--phase-id <ID>]          which phase to drive: phases/<id>/ (default: p1; the orchestrator sets it)
./relay-automation/marathon-drive.sh:71:# (basename ".xyz"). ROOT = work root = where git ops, phases/, .tick/, validate.sh live.
./relay-automation/marathon-drive.sh:603:  --phases-dir DIR        Where to create phases/<id>/ (default: <repo-root>/phases).
./relay-automation/marathon-drive.sh:604:  --phase-id ID           Which phase to drive: phases/<id>/ (default: p1).
./relay-automation/marathon-drive.sh:633:PHASES_DIR=""        # resolved to default after ROOT is set
./relay-automation/marathon-drive.sh:634:PHASE_ID="p1"        # which phase this invocation drives (phases/<id>/); the orchestrator sets it
./relay-automation/marathon-drive.sh:654:    --phases-dir)      PHASES_DIR="${2:-}"; shift 2 ;;
./relay-automation/marathon-drive.sh:679:PHASES_DIR="${PHASES_DIR:-"$ROOT/phases"}"
./relay-automation/marathon-drive.sh:833:PHASE_DIR="$PHASES_DIR/$LANE_STATE_KEY"
./relay-automation/marathon-drive.sh:957:# marathon's own paths (phases/, .tick/). --require-clean turns the warning into a hard stop for
./relay-automation/marathon-drive.sh:969:# ── Step 1: render phases/p1/RELAY.md ──────────────────────────────────────
./relay-automation/marathon-ls.sh:110:# Find newest phases/*/RELAY.md path for a repo (used in RELAY-FILE column).
./relay-automation/marathon-ls.sh:113:  local phases_dir="$repo/phases"
./relay-automation/marathon-ls.sh:114:  [ -d "$phases_dir" ] || { printf '-'; return 0; }
./relay-automation/marathon-ls.sh:117:  f="$(ls -t "$phases_dir"/*/RELAY.md 2>/dev/null | head -1 || true)"
./utils/pdda/pdda.sh:95:    if pdda_frontmatter_has_key "$file" "phases"; then
./utils/pdda/pdda.sh:96:      value="$(pdda_trim "$(pdda_frontmatter_value "$file" "phases")")"
./utils/pdda/pdda.sh:98:        pdda_record_finding error "$CHECK_NAME" "$file" 1 "frontmatter 'phases' must be a positive integer (got '$value')" "fix-phases-value"
./utils/py/marathon_drive.py:383:    parser.add_argument("--phases-dir", dest="phases_dir")
./utils/py/marathon_drive.py:687:    phases_dir = args.phases_dir or os.path.join(root, "phases")
./utils/py/marathon_drive.py:1136:    phase_dir = os.path.join(phases_dir, lane_state_key)
./utils/py/marathon_drive.py:1666:                    if not p.startswith("phases/") and not p.startswith(".tick/"):
./utils/py/marathon_drive.py:1677:    # phase dir creation used to live here, above the render, so a dry run materialized phases/<id>/
./utils/py/marathon_drive.py:1678:    # in whatever repo it resolved to — the harness itself when no MARATHON_ROOT/--phases-dir was
relay-automation/marathon-agent.sh:18:# Peer threading (set by marathon-drive.sh — prevents "release to literal role-string" failure):
utils/telemetry/append-xyz-completion.sh:7:# Called from the three harnesses at their proven terminal points (relay-drive.sh, marathon-drive.sh,
relay-automation/relay-drive.sh:63:# (marathon-drive → relay-drive) is guarded by LANE_ATTEMPT_COUNTED so the same lane is counted (and
relay-automation/relay-drive.sh:64:# reset) exactly once. Byte-consistent mirror in marathon-drive.sh; relay-turn-lib.sh/bin/tick untouched.
relay-automation/relay-drive.sh:93:# phase — marathon-drive.sh sets XYZ_HARNESS_CONTEXT for the nested call (marathon-phase|swarm) and the
relay-automation/improve-loop.sh:12:# Each iteration: build a challenger (--build-cmd, pluggable — a real agent via marathon-drive, or any
relay-automation/claude-turn.sh:48:#                       subprocess only (default: codex gemini consult consult.sh marathon-drive.sh
relay-automation/claude-turn.sh:186:block_cmds="${CLAUDE_BLOCK_CMDS-codex gemini consult consult.sh marathon-drive.sh relay-drive.sh}"
relay-automation/marathon-drive.sh:24:# marathon-drive.sh — Phase 3: single-phase headless relay loop.
relay-automation/marathon-drive.sh:31:#   relay-automation/marathon-drive.sh \
relay-automation/marathon-drive.sh:40:#     [--phases-dir <DIR>]       where to create phases/<id>/ (default: <repo-root>/phases)
relay-automation/marathon-drive.sh:56:#   MARATHON_ROOT         — git repo root (default: parent of this script's dir)
relay-automation/marathon-drive.sh:74:  ROOT="${MARATHON_ROOT:-"$(cd "$_xyz_harness/.." && pwd)"}"
relay-automation/marathon-drive.sh:76:  ROOT="${MARATHON_ROOT:-"$_xyz_harness"}"
relay-automation/marathon-drive.sh:91:# (marathon-drive → relay-drive) is guarded by LANE_ATTEMPT_COUNTED so the same lane is counted (and
relay-automation/marathon-drive.sh:152:# at end-of-run so a marathon-drive.sh phase (standalone or as one phase of a marathon.sh chain)
relay-automation/marathon-drive.sh:161:# own exit. Driven via marathon.sh, each phase's marathon-drive subprocess still prints its OWN
relay-automation/marathon-drive.sh:181:    printf 'marathon-drive: tick analyze failed — end-of-run cost summary unavailable (MARATHON_COST_SUMMARY=0 to silence)\n' >&2
relay-automation/marathon-drive.sh:186:  printf '\nmarathon-drive: end-of-run cost summary (tick analyze) —\n%s\n' "$block" >&2
relay-automation/marathon-drive.sh:214:      printf 'marathon-drive: another driver is active in this repo (pid %s, lock: %s).\n' "$_holder" "$_lock_label" >&2
relay-automation/marathon-drive.sh:215:      printf 'marathon-drive: Concurrent runs in the same clone are unsafe (GH-42 ROOT HEAD hazard).\n' >&2
relay-automation/marathon-drive.sh:218:    printf 'marathon-drive: reclaiming stale relay-driver.lock (holder pid %s not running).\n' "${_holder:-none}" >&2
relay-automation/marathon-drive.sh:225:    mkdir "$_lock" 2>/dev/null || { printf 'marathon-drive: could not acquire relay-driver.lock after reclaiming a stale one.\n' >&2; exit 1; }
relay-automation/marathon-drive.sh:248:die()  { printf 'marathon-drive: %s\n' "$*" >&2; exit 2; }
relay-automation/marathon-drive.sh:249:log()  { printf 'marathon-drive: %s\n' "$*"; }
relay-automation/marathon-drive.sh:426:# marathon-drive — i.e. a bare `marathon-drive.sh` run (harness:"marathon") or a swarm-preflight-
relay-automation/marathon-drive.sh:430:# failure has no distinct "escalated mid-chain" state). Best-effort — never changes marathon-drive's
relay-automation/marathon-drive.sh:498:# (re)build or (re)review — the only reason to re-invoke marathon-drive.sh for it is to
relay-automation/marathon-drive.sh:527:    # Deliberately narrow: run-identity tags only, never repo/config inputs like MARATHON_ROOT,
relay-automation/marathon-drive.sh:590:Usage: relay-automation/marathon-drive.sh --phase-brief FILE --reviewer AGENT [options]
relay-automation/marathon-drive.sh:603:  --phases-dir DIR        Where to create phases/<id>/ (default: <repo-root>/phases).
relay-automation/marathon-drive.sh:633:PHASES_DIR=""        # resolved to default after ROOT is set
relay-automation/marathon-drive.sh:654:    --phases-dir)      PHASES_DIR="${2:-}"; shift 2 ;;
relay-automation/marathon-drive.sh:679:PHASES_DIR="${PHASES_DIR:-"$ROOT/phases"}"
relay-automation/marathon-drive.sh:754:    || printf 'marathon-drive: (dry-run continues; a live run would halt here)\n' >&2
relay-automation/marathon-drive.sh:833:PHASE_DIR="$PHASES_DIR/$LANE_STATE_KEY"
relay-automation/marathon-drive.sh:1002:<!-- marathon-drive: task=${RELAY_TASK} builder=${BUILDER} reviewer=${REVIEWER} round-cap=${ROUND_CAP} -->
relay-automation/marathon-drive.sh:1060:# The outer marathon-drive invocation owns the lane attempt count. A leaked caller env var would skip
relay-automation/marathon-drive.sh:1212:# record — this marathon-drive run (or marathon.sh above it) owns the single whole-run record. This is
relay-automation/marathon-drive.sh:1213:# scoped to the relay-drive child only; marathon-drive's OWN context (swarm|unset) is left intact for
relay-automation/relay-turn-lib.sh:64:  # (Producer|Reviewer); marathon-drive writes an AGENT ID (claude|codex|agy). The role test below can
relay-automation/relay-turn-lib.sh:75:  # So derive the role instead of trusting an assertion. marathon-drive renders a machine-readable
relay-automation/relay-turn-lib.sh:83:    directive="$(grep -E '^[[:space:]]*<!--[[:space:]]*marathon-drive:' "$f" 2>/dev/null | head -1)"
relay-automation/relay-turn-lib.sh:104:# Every transcript writer (consult.sh, marathon-drive.sh, relay-drive.sh, swarm-preflight.sh,
relay-automation/relay-turn-lib.sh:243:  # whenever marathon-drive/relay-drive don't export CODEX_TURN_ROOT/AGY_TURN_ROOT — they never do)
relay-automation/relay-turn-lib.sh:270:  # root-cause; 312a2c3's own message names the test/marathon-drive.sh GH-171/GH-172 failures Plan K
relay-automation/relay-turn-lib.sh:727:        # very marathon-drive.sh, or its relay-drive.sh subprocess — both are legitimate copyback
utils/swarm-preflight.sh:29:# relay-automation/marathon-drive.sh. It is the PRODUCER of the packet, never the
utils/swarm-preflight.sh:61:# marathon-drive.sh — "This lane will commit to <branch>. Suggested branch: <suggested_branch>. Cut it
utils/swarm-preflight.sh:76:  _DRIVE_CMD=".xyz/relay-automation/marathon-drive.sh"
utils/swarm-preflight.sh:79:  _DRIVE_CMD="relay-automation/marathon-drive.sh"
utils/swarm-preflight.sh:955:## Suggested marathon-drive.sh invocation
utils/marathon-plan.sh:99:  _MD_CMD=".xyz/relay-automation/marathon-drive.sh"
utils/marathon-plan.sh:104:  _MD_CMD="relay-automation/marathon-drive.sh"
utils/marathon-plan.sh:198:const MD_CMD = E.QP_MD_CMD || "relay-automation/marathon-drive.sh";
utils/marathon-plan.sh:1010:  o.push(`| Generated by \`utils/marathon-plan.sh\` on ${TODAY} from the live ROADMAP ledger (${deduped.length} items; ${active.length} active across ${waves.length} wave(s); ${held.length} held). Drift present: ${hasDrift ? "yes — see Held/Flagged" : "no"}. | **Wave 1:** ${firstWave}. Fire each lane via \`swarm-preflight → marathon-drive\`, scoped by \`ALLOW_PATHS\`. Re-run this script when the ledger changes. |`);
relay-automation/target-checks.sh:32:#   marathon-drive.sh --target-root /path/to/repo \
relay-automation/hooks/relay-xyz-guard.sh:107:  *relay-automation/marathon-drive.sh*|\
utils/py/gate_env.py:6:`validate.sh` is `marathon-drive`'s DEFAULT `--pre-advance-cmd`, so it routinely runs as a child of a
utils/hq/marathon-scan.sh:504:| Scanned $repos_total repo(s), found $docs_total marathon doc(s), preflighted $active_lanes active lane(s): $fireable_ready ready, $blocked_not_promoted blocked-not-promoted, $blocked_other blocked-other, $stale_already_landed stale-already-landed, $ambiguous_count ambiguous; $held_docs held marathon(s) surfaced but not counted. | Re-run \`utils/hq/marathon-scan.sh\` to refresh; fire any ready lane via that repo's own \`swarm-preflight.sh\` → \`marathon-drive.sh\`. |
utils/py/claude-turn.py:77:    block_cmds_str = os.environ.get("CLAUDE_BLOCK_CMDS", "codex gemini consult consult.sh marathon-drive.sh relay-drive.sh")
utils/hq/hq-lib.sh:370:# CLI flags, matching this repo's existing passthrough convention (MARATHON_ROOT, CODEX_LOG, etc.) and
relay-automation/marathon.sh:5:# order, and runs each phase through marathon-drive.sh (the unmodified single-phase loop). Advances
relay-automation/marathon.sh:7:# leaving that phase's ESCALATION.md (written by marathon-drive) and NOT starting later phases.
relay-automation/marathon.sh:15:#   relay-automation/marathon.sh --plan MARATHON.yaml [--builder codex] [--phases-dir DIR]
relay-automation/marathon.sh:32:# its task name exactly as before. marathon-drive.sh already supports --relay-task natively; this is
relay-automation/marathon.sh:33:# purely a marathon.sh-side task-name override, no change to marathon-drive.sh itself.
relay-automation/marathon.sh:35:# The MARATHON.yaml phase fields drive each marathon-drive call: id→--phase-id, reviewer→--reviewer,
relay-automation/marathon.sh:41:#   MARATHON_ROOT       — target repo root (default: `git -C "$PWD" rev-parse --show-toplevel`,
relay-automation/marathon.sh:43:#   MARATHON_DRIVE      — marathon-drive.sh path (default: <harness-home>/relay-automation/marathon-drive.sh)
relay-automation/marathon.sh:50:# Exit: 0 all phases approved · N the failing phase's marathon-drive exit code · 2 usage/parse error.
relay-automation/marathon.sh:54:if [[ -n "${MARATHON_ROOT:-}" ]]; then
relay-automation/marathon.sh:55:  ROOT="$MARATHON_ROOT"
relay-automation/marathon.sh:62:DRIVE_BIN="${MARATHON_DRIVE:-"$MARATHON_HOME/relay-automation/marathon-drive.sh"}"
relay-automation/marathon.sh:72:# marathon-drive runs with XYZ_HARNESS_CONTEXT=marathon-phase (its own hook silent), so this is the
relay-automation/marathon.sh:75:# emitting nothing — worse than a bare marathon-drive halt, which does emit red). Best-effort.
relay-automation/marathon.sh:84:Usage: marathon.sh --plan MARATHON.yaml [--builder A] [--phases-dir D] [--pre-advance-cmd C]
relay-automation/marathon.sh:94:  --phases-dir DIR        Where to create phases/<id>/ (default: <repo-root>/phases).
relay-automation/marathon.sh:95:  --target-root DIR       Foreign git repo the BUILD lands in; forwarded to marathon-drive.sh (GH-11).
relay-automation/marathon.sh:99:                          and relay-system/ on purpose): without it, marathon-drive's `git add` of
relay-automation/marathon.sh:111:PLAN=""; BUILDER="codex"; PHASES_DIR=""; PRE_ADVANCE_CMD=""; DRY_RUN=0; FORCE=0; RETRY_PHASE=""; CLOSEOUT_PR=0
relay-automation/marathon.sh:117:    --phases-dir)      PHASES_DIR="${2:-}"; shift 2 ;;
relay-automation/marathon.sh:139:# from `git rev-parse --show-toplevel` (symlink-resolved) or a raw MARATHON_ROOT env override
relay-automation/marathon.sh:167:PHASES_DIR="${PHASES_DIR:-"$ROOT/phases"}"
relay-automation/marathon.sh:200:               --phase-brief "$brief_path" --round-cap "$cap" --phases-dir "$PHASES_DIR" )
relay-automation/marathon.sh:206:  # marathon-drive.sh derive its default MARATHON-<ID>-TURN name, unaffected.
relay-automation/marathon.sh:222:  # GH-75: mark each per-phase marathon-drive call so its (and its nested relay-drive's) XYZ.json hook
relay-automation/marathon.sh:226:    MARATHON_ROOT="$ROOT" MARATHON_LANE_NS="$lane_ns" TICK_BIN="$TICK_BIN" XYZ_HARNESS_CONTEXT=marathon-phase \
relay-automation/marathon.sh:230:    MARATHON_ROOT="$ROOT" MARATHON_LANE_NS="$lane_ns" TICK_BIN="$TICK_BIN" XYZ_HARNESS_CONTEXT=marathon-phase \
relay-automation/marathon.sh:234:    log "HALT: phase $id failed (marathon-drive exit $phase_exit) — chain stops; later phases NOT started"
relay-automation/marathon.sh:241:      *) _halt_reason="marathon-drive exit $phase_exit" ;;
utils/py/_marathon_plan.py:129:        self.MD_CMD = cfg.get("md_cmd") or "relay-automation/marathon-drive.sh"
utils/py/_marathon_plan.py:1204:        o.append("| Generated by `utils/marathon-plan.sh` on %s from the live ROADMAP ledger (%d items; %d active across %d wave(s); %d held). Drift present: %s. | **Wave 1:** %s. Fire each lane via `swarm-preflight → marathon-drive`, scoped by `ALLOW_PATHS`. Re-run this script when the ledger changes. |"
relay-automation/marathon-detail.sh:40:PHASES_DIR="$REPO/phases"
relay-automation/marathon-detail.sh:42:if [ -d "$PHASES_DIR" ]; then
relay-automation/marathon-detail.sh:44:  RELAY_FILE="$(ls -t "$PHASES_DIR"/*/RELAY.md 2>/dev/null | head -1 || true)"
utils/py/swarm_preflight.py:17:        return os.path.abspath(os.path.join(here_parent, "..")), ".xyz/relay-automation/marathon-drive.sh"
utils/py/swarm_preflight.py:18:    return here_parent, "relay-automation/marathon-drive.sh"
utils/py/swarm_preflight.py:1335:                # A direct program path is executed with cwd=target_root by marathon-drive.  Checking it
utils/py/swarm_preflight.py:1552:## Suggested marathon-drive.sh invocation
utils/py/marathon_plan.py:118:        md_cmd = ".xyz/relay-automation/marathon-drive.sh"
utils/py/marathon_plan.py:123:        md_cmd = "relay-automation/marathon-drive.sh"
relay-automation/codex-turn.sh:88:# inherited TICK_REPO_ROOT from marathon-drive/relay-drive (notably a vendored .xyz run whose real
test/xyz-vendor.sh:56:for mf in marathon-drive.sh marathon.sh marathon-agent.sh claude-turn.sh; do
utils/py/marathon_drive.py:16:# Python equivalent of marathon-drive.sh's `trap _marathon_drive_on_exit EXIT`. Same contract as
utils/py/marathon_drive.py:43:    """Plain-language gloss for a marathon-drive exit code, for the run log.
utils/py/marathon_drive.py:88:# marathon-drive.sh carried this capture; Python is the default lane since GH-264, so arming
utils/py/marathon_drive.py:157:    Deliberately NOT routed through xyz_debug_log_append: `marathon-drive.sh:220` inlines a SHORTER
utils/py/marathon_drive.py:175:    are (`marathon-drive.sh:849`, `:881`). Output discarded, exit code ignored: a harvest failure
utils/py/marathon_drive.py:204:    eprint(f"marathon-drive: {msg}")
utils/py/marathon_drive.py:208:    print(f"marathon-drive: {msg}")
utils/py/marathon_drive.py:376:    parser = argparse.ArgumentParser(description="marathon-drive", add_help=False)
utils/py/marathon_drive.py:383:    parser.add_argument("--phases-dir", dest="phases_dir")
utils/py/marathon_drive.py:397:        print("Usage: relay-automation/marathon-drive.sh --phase-brief FILE --reviewer AGENT [options]")
utils/py/marathon_drive.py:418:        eprint("Usage: relay-automation/marathon-drive.sh --phase-brief FILE --reviewer AGENT [options]")
utils/py/marathon_drive.py:423:        eprint("Usage: relay-automation/marathon-drive.sh --phase-brief FILE --reviewer AGENT [options]")
utils/py/marathon_drive.py:444:    root = get_env("MARATHON_ROOT", default_root)
utils/py/marathon_drive.py:482:            # (marathon-drive.sh:1103-1106); this gate exits directly, so it emits here instead —
utils/py/marathon_drive.py:621:                eprint(f"marathon-drive: another driver is active in this repo (pid {holder}, lock: {lock_label}).")
utils/py/marathon_drive.py:622:                eprint("marathon-drive: Concurrent runs in the same clone are unsafe (GH-42 ROOT HEAD hazard).")
utils/py/marathon_drive.py:625:            eprint(f"marathon-drive: reclaiming stale relay-driver.lock (holder pid {holder or 'none'} not running).")
utils/py/marathon_drive.py:633:                eprint("marathon-drive: could not acquire relay-driver.lock after reclaiming a stale one.")
utils/py/marathon_drive.py:662:    # branch clears it). Best-effort — never changes marathon-drive's exit code. Mirrors Bash
utils/py/marathon_drive.py:663:    # xyz_marathon_heartbeat_write/clear (relay-automation/marathon-drive.sh).
utils/py/marathon_drive.py:687:    phases_dir = args.phases_dir or os.path.join(root, "phases")
utils/py/marathon_drive.py:740:    # relay-automation/marathon-drive.sh. That twin `exec`s this file at its own line 18, long before
utils/py/marathon_drive.py:955:        # GH-331 (mirrors marathon-drive.sh GH-222 / relay-drive.sh GH-152): auto-surface the
utils/py/marathon_drive.py:982:        print("\nmarathon-drive: end-of-run cost summary (tick analyze) —\n" + "\n".join(block_lines))
utils/py/marathon_drive.py:1034:            eprint(f"marathon-drive: lane parked — issue {issue_display} is already closed")
utils/py/marathon_drive.py:1114:                eprint("marathon-drive: (dry-run continues; a live run would halt here)")
utils/py/marathon_drive.py:1136:    phase_dir = os.path.join(phases_dir, lane_state_key)
utils/py/marathon_drive.py:1168:        # escalation record is written, matching marathon-drive.sh:848-853 — a phase that escalated
utils/py/marathon_drive.py:1199:        # marathon-drive.sh:867-868 — last thing escalate() does, carrying the relay-drive exit code.
utils/py/marathon_drive.py:1220:        # (marathon-drive.sh:880-885) — after the copy, before the commit, same as Bash.
utils/py/marathon_drive.py:1240:    # like MARATHON_ROOT, TICK_BIN or TICK_REPO_ROOT, which a gate may legitimately need.
utils/py/marathon_drive.py:1583:    # (re)build or (re)review — the only reason to re-invoke marathon-drive for it is to retry a
utils/py/marathon_drive.py:1599:        # The relay file already records which task it was rendered for, in the marathon-drive
utils/py/marathon_drive.py:1630:                    if not line.lstrip().startswith("<!-- marathon-drive:"):
utils/py/marathon_drive.py:1678:    # in whatever repo it resolved to — the harness itself when no MARATHON_ROOT/--phases-dir was
utils/py/marathon_drive.py:1717:<!-- marathon-drive: task={relay_task} builder={args.builder} reviewer={args.reviewer} round-cap={args.round_cap} -->
utils/py/marathon_drive.py:1816:    # The outer marathon-drive invocation owns this lane's attempt count. A parent relay-drive
relay-automation/marathon-ls.sh:113:  local phases_dir="$repo/phases"
relay-automation/marathon-ls.sh:114:  [ -d "$phases_dir" ] || { printf '-'; return 0; }
relay-automation/marathon-ls.sh:117:  f="$(ls -t "$phases_dir"/*/RELAY.md 2>/dev/null | head -1 || true)"
test/gh308-frozen-twin-guard.sh:23:  relay-automation/marathon-drive.sh:utils/py/marathon_drive.py
test/gh308-frozen-twin-guard.sh:85:#   Frozen-twin-exception: relay-automation/marathon-drive.sh — silently-fake pre-advance gate (GH-319)
test/marathon-closeout.sh:181:DRIVE="$WORK/marathon-drive.sh"
test/marathon-closeout.sh:197:GIT_CACHED_DIFF_RC=1 MARATHON_ROOT="$REPO" MARATHON_DRIVE="$DRIVE" MARATHON_YAML_BIN="$YAML_BIN" \
test/marathon-closeout.sh:211:GH_FAIL_ON='pr create' GIT_CACHED_DIFF_RC=1 MARATHON_ROOT="$REPO" MARATHON_DRIVE="$DRIVE" MARATHON_YAML_BIN="$YAML_BIN" \
test/gh278-turn-timeout-parity.sh:95:# containment guard and failed the phase (marathon-drive exit 6). Answer the probe the
test/gh438-acceptance-recheck.sh:89:  MARATHON_ROOT="$A" MARATHON_RELAY_DRIVE="$WORK/rd.sh" TICK_REPO_ROOT="$A" TICK_BIN="$TICK" \
test/gh438-acceptance-recheck.sh:91:  python3 "$DRIVER" --phases-dir "$A/phases" --phase-brief "$b" --reviewer agy --builder claude \
test/gh401-dry-run-no-mutation.sh:5:# `marathon-drive --dry-run` used to RENDER AND WRITE phases/<id>/RELAY.md before reaching its exit,
test/gh401-dry-run-no-mutation.sh:6:# so a dry run mutated the working tree. Unscoped (no MARATHON_ROOT, no --phases-dir) that landed on
test/gh401-dry-run-no-mutation.sh:15:# so aiming the same code path at a throwaway MARATHON_ROOT proves the same property — and a
test/gh401-dry-run-no-mutation.sh:22:DRV="$ROOT/relay-automation/marathon-drive.sh"
test/gh401-dry-run-no-mutation.sh:39:# --builder claude, the same convention test/marathon-drive.sh (GH-212/GH-232) and debug-mantra.sh
test/gh401-dry-run-no-mutation.sh:45:out="$(MARATHON_ROOT="$MROOT" CLAUDE_BIN="$STUB_CLAUDE" AGY_BIN="$STUB_AGY" \
test/gh284-runlog-heartbeat.sh:6:# drives marathon-drive against its own throwaway repo ($A) and asserts on what THAT driver does.
test/gh284-runlog-heartbeat.sh:8:# (exported by marathon-drive.sh:245 so a nested driver doesn't deadlock on its parent's lock), and
test/gh284-runlog-heartbeat.sh:16:DRIVER="$ROOT/relay-automation/marathon-drive.sh"
test/gh284-runlog-heartbeat.sh:90:  XYZ_PYTHON=0 MARATHON_COST_SUMMARY=0 MARATHON_ROOT="$A" MARATHON_RELAY_DRIVE="$STUB_RD" \
test/gh284-runlog-heartbeat.sh:92:    PATH="$NODE_ONLY:/usr/bin:/bin" bash "$DRIVER" --phases-dir "$A/phases" --phase-brief "$BRIEF" \
test/gh284-runlog-heartbeat.sh:108:# GH-441: MARATHON_ROOT="$A" keeps this hermetic. This assertion reads HELP TEXT, but the driver's
test/gh284-runlog-heartbeat.sh:109:# lock block (marathon-drive.sh:189) runs long before --help is parsed (:664), so without a root of
test/gh284-runlog-heartbeat.sh:114:MARATHON_ROOT="$A" XYZ_PYTHON=0 bash "$DRIVER" --help | grep -q -- '--log-github' \
test/gh284-runlog-heartbeat.sh:171:  XYZ_PYTHON=0 MARATHON_COST_SUMMARY=0 MARATHON_ROOT="$A" MARATHON_RELAY_DRIVE="$STUB_RD" \
test/gh284-runlog-heartbeat.sh:173:    PATH="$GH_STUB_DIR:$NODE_ONLY:/usr/bin:/bin" bash "$DRIVER" --phases-dir "$A/phases" \
test/gh284-runlog-heartbeat.sh:203:  "$ROOT/relay-automation/marathon-drive.sh" | sed '1d;$d' > "$PARSER"
test/gh284-runlog-heartbeat.sh:205:  || fail "could not extract the marker parser from marathon-drive.sh"
test/gh284-runlog-heartbeat.sh:213:INVOKE="$(grep -n 'python3' "$ROOT/relay-automation/marathon-drive.sh" | grep -F "$(printf '%s' 'runlog_marker_py')" || true)"
test/gh284-runlog-heartbeat.sh:217:grep -Eq 'python3 +- +"\$marker"' "$ROOT/relay-automation/marathon-drive.sh" \
test/gh390-gate-guard.sh:27:DRIVER="$ROOT_REPO/relay-automation/marathon-drive.sh"
test/gh390-gate-guard.sh:92:  MARATHON_ROOT="$ROOT" \
test/gh390-gate-guard.sh:98:    --phases-dir "$ROOT/phases" \
test/gh457-gate-tiers.sh:28:DRIVER="$ROOT_REPO/relay-automation/marathon-drive.sh"
test/gh457-gate-tiers.sh:113:  MARATHON_ROOT="$ROOT" \
test/gh457-gate-tiers.sh:119:    --phases-dir "$ROOT/phases" \
test/gh438-removal-is-progress.sh:67:  MARATHON_ROOT="$A" MARATHON_RELAY_DRIVE="$WORK/rd.sh" TICK_REPO_ROOT="$A" TICK_BIN="$TICK" \
test/gh438-removal-is-progress.sh:69:  python3 "$DRIVER" --phases-dir "$A/phases" --phase-brief "$BRIEF" --reviewer agy --builder claude \
test/gh342-sentinel-debug-log-python.sh:5:# The gap this pins: XYZ_DEBUG_LOG=1 was honored only by relay-automation/marathon-drive.sh, which
test/gh342-sentinel-debug-log-python.sh:15:#      test/sentinel-driver-hooks.sh; both are needed while marathon-drive.sh stays a frozen twin)
test/gh342-sentinel-debug-log-python.sh:21:#   7  end-to-end on the default lane: a real marathon-drive run reclaiming a stale driver lock
test/gh342-sentinel-debug-log-python.sh:35:SH_TWIN="$REPO_ROOT/relay-automation/marathon-drive.sh"
test/gh342-sentinel-debug-log-python.sh:325:      DEBUG_LOG_FILE="$DBG" MARATHON_ROOT="$A" TICK_BIN="$TICK" \
test/relay-target-root.sh:124:# the relay-file + artifact edits commit. Worktree isolation ON; relay file passed ABSOLUTE as marathon-drive does.
test/archive-writers.sh:9:# Structural (regression lock for all four writers — marathon-drive/relay-drive drive full relay loops
test/archive-writers.sh:85:check_writer "relay-automation/marathon-drive.sh" ROOT
test/gh397-reviewer-turn-role.sh:3:# gate-evidence: {"form":"pre-fix-replay","observed":true,"result":"reproducer: bash test/gh397-reviewer-turn-role.sh; pre-fix revision: relay-turn-lib.sh before d4999cd, where rtl_is_reviewer_turn read only the agent-maintained NEXT: prose; pre-fix result: case 3 FAILED — a builder that never flipped NEXT: left the reviewer running with the builder's write scope; post-fix result: 11/0, role derived from the marathon-drive directive with the NEXT: line kept only as the fallback"}
test/gh397-reviewer-turn-role.sh:6:# it. relay-drive writes a ROLE (Producer|Reviewer); marathon-drive writes an AGENT ID
test/gh397-reviewer-turn-role.sh:19:# readable role directive marathon-drive renders into the relay file, and RELAY_AGENT, which
test/gh397-reviewer-turn-role.sh:27:  printf '# Marathon Phase p1\nSTATUS: Open\nNEXT: %s\n\n<!-- marathon-drive: task=MARATHON-p1 builder=codex reviewer=agy round-cap=6 -->\n\nbody\n' \
test/gh397-reviewer-turn-role.sh:74:printf '# Marathon Phase p1\nSTATUS: Open\nNEXT: agy (Reviewer)\n\n<!-- marathon-drive: task=MARATHON-p1 builder=agy reviewer=agy round-cap=6 -->\n\nbody\n' > "$M"
test/test_python_layer.py:101:                "MARATHON_ROOT": tmpdir,
test/test_python_layer.py:139:            {"MARATHON_ROOT": tmpdir, "PI_BIN": "missing-pi"},
test/test_python_layer.py:183:    assert drive_cmd == "relay-automation/marathon-drive.sh"
test/test_python_layer.py:188:    assert drive_cmd == ".xyz/relay-automation/marathon-drive.sh"
test/xyz-harness-hooks.sh:4:# Drives the REAL relay-drive.sh, marathon-drive.sh, and marathon.sh to their terminal points and
test/xyz-harness-hooks.sh:12:#   - bare marathon-drive → harness:marathon; swarm-context marathon-drive → harness:swarm
test/xyz-harness-hooks.sh:13:#   - marathon-drive under marathon.sh (marathon-phase) stays silent
test/xyz-harness-hooks.sh:21:MARATHON_DRIVE="$REPO/relay-automation/marathon-drive.sh"
test/xyz-harness-hooks.sh:143:# ── Marathon-drive: real driver + STUB relay-drive + stub agent ─────────────
test/xyz-harness-hooks.sh:167:  MARATHON_ROOT="$A" MARATHON_RELAY_DRIVE="$STUB_RD" MARATHON_AGENT_CMD="$NOOP" \
test/xyz-harness-hooks.sh:170:    bash "$MARATHON_DRIVE" --phases-dir "$A/phases" --phase-brief "$BRIEF" \
test/xyz-harness-hooks.sh:174:# ── (M1) bare marathon-drive success → harness:marathon, green ─────────────
test/xyz-harness-hooks.sh:177:[ "$rc" -eq 0 ] && pass "bare marathon-drive success exits 0" || fail "bare md exit=$rc"
test/xyz-harness-hooks.sh:178:[ "$(count "$XM")" = "1" ] && pass "bare marathon-drive writes one record" || fail "bare md count=$(count "$XM")"
test/xyz-harness-hooks.sh:179:[ "$(field "$XM" 0 harness)" = "marathon" ] && pass "bare marathon-drive harness=marathon" || fail "harness=$(field "$XM" 0 harness)"
test/xyz-harness-hooks.sh:180:[ "$(field "$XM" 0 health)" = "green" ] && pass "bare marathon-drive health=green" || fail "health=$(field "$XM" 0 health)"
test/xyz-harness-hooks.sh:183:# ── (M2) swarm-context marathon-drive → harness:swarm ──────────────────────
test/xyz-harness-hooks.sh:186:[ "$(count "$XS")" = "1" ] && pass "swarm-context marathon-drive writes one record" || fail "swarm md count=$(count "$XS")"
test/xyz-harness-hooks.sh:187:[ "$(field "$XS" 0 harness)" = "swarm" ] && pass "swarm-context marathon-drive harness=swarm (not marathon)" || fail "harness=$(field "$XS" 0 harness)"
test/xyz-harness-hooks.sh:192:[ ! -e "$XP" ] && pass "marathon-phase marathon-drive writes NO record" || fail "marathon-phase emitted: $(cat "$XP" 2>/dev/null)"
test/xyz-harness-hooks.sh:194:# ── (M4) bare marathon-drive halt (relay exit 4) → marathon/red ────────────
test/xyz-harness-hooks.sh:197:[ "$rc" -eq 4 ] && pass "bare marathon-drive halt exits 4" || fail "halt exit=$rc"
test/xyz-harness-hooks.sh:216:MARATHON_ROOT="$A" MARATHON_DRIVE="$MARATHON_DRIVE" MARATHON_RELAY_DRIVE="$STUB_RD" \
test/xyz-harness-hooks.sh:244:MARATHON_ROOT="$A" MARATHON_DRIVE="$MARATHON_DRIVE" MARATHON_RELAY_DRIVE="$STUB_RD" \
test/xyz-harness-hooks.sh:259:  MARATHON_ROOT="$A" MARATHON_RELAY_DRIVE="$STUB_RD" MARATHON_AGENT_CMD="$NOOP" \
test/xyz-harness-hooks.sh:262:    bash "$MARATHON_DRIVE" --phases-dir "$A/phases" --phase-brief "$BRIEF" \
test/driver-lock.sh:2:# driver-lock.sh — GH-42 self-heal: marathon-drive reclaims a STALE relay-driver.lock (the holder
test/driver-lock.sh:13:MD="$(cd "$(dirname "$0")/.." && pwd)/relay-automation/marathon-drive.sh"
test/driver-lock.sh:19:# GH-117: marathon-drive now probes builder/reviewer binaries up front (before lock-protected work),
test/driver-lock.sh:25:run_md(){ MARATHON_ROOT="$A" TICK_BIN="$TICK" CODEX_BIN="$STUB_BIN" CLAUDE_BIN="$STUB_BIN" AGY_BIN="$STUB_BIN" bash "$MD" --phase-brief "$brief" --reviewer agy --dry-run >/dev/null 2>&1; }
test/gh319-gate-path-with-space.sh:21:DRIVER="$ROOT_REPO/relay-automation/marathon-drive.sh"
test/gh319-gate-path-with-space.sh:87:  MARATHON_ROOT="$ROOT" \
test/gh319-gate-path-with-space.sh:93:    --phases-dir "$ROOT/phases" \
test/gh319-gate-path-with-space.sh:128:# GH-308 froze relay-automation/marathon-drive.sh and routes behavior fixes to the Python twin, but
test/gh307-gate-env-scrub.sh:13:# can actually see, driven through the real driver) lives in test/marathon-drive.sh §5b.
test/gh307-gate-env-scrub.sh:29:KEEP=(MARATHON_ROOT TICK_BIN TICK_REPO_ROOT)
test/gh307-gate-env-scrub.sh:31:SH="$ROOT/relay-automation/marathon-drive.sh"
test/gh322-unknown-arg-rejection.sh:23:  "relay-automation/marathon-drive.sh:marathon-drive"
test/gh322-unknown-arg-rejection.sh:100:py_out="$(bash "$ROOT/relay-automation/marathon-drive.sh" --log-github 2>&1)"; py_rc=$?
test/marathon-root-audit.sh:7:# MARATHON_ROOT-scoped" — but its scope was two hardcoded filenames. An unscoped `--dry-run`
test/marathon-root-audit.sh:105:    if [[ "$line" =~ ^([A-Z][A-Z0-9_]*)=.*relay-automation/(marathon|marathon-drive)\.sh ]]; then
test/marathon-root-audit.sh:117:  if [[ "$line" == *'./.xyz/relay-automation/marathon-drive.sh'* ]]; then
test/marathon-root-audit.sh:118:    printf '%s\n' "marathon-drive"
test/marathon-root-audit.sh:147:  if [[ "$line" == *'MARATHON_ROOT='* ]]; then
test/marathon-root-audit.sh:156:    if [[ "${lines[$j]}" == *'MARATHON_ROOT='* ]]; then
test/marathon-root-audit.sh:182:    if [[ "${lines[$j]}" == *'MARATHON_ROOT='* ]]; then
test/marathon-root-audit.sh:212:      printf 'FAIL: %s:%d %s invocation lacks MARATHON_ROOT and fixture-local cwd\n' \
test/gh407-gate-ran-attribution.sh:30:DRIVER="$ROOT_REPO/relay-automation/marathon-drive.sh"
test/gh407-gate-ran-attribution.sh:69:  MARATHON_ROOT="$ROOT" \
test/gh407-gate-ran-attribution.sh:75:    --phases-dir "$ROOT/phases" \
test/gh407-gate-ran-attribution.sh:166:PRE_DRIVER="$FIXH/relay-automation/marathon-drive.sh"
test/gh407-gate-ran-attribution.sh:170:MARATHON_ROOT="$PRE_ROOT" \
test/gh407-gate-ran-attribution.sh:175:  bash "$PRE_DRIVER" --phases-dir "$PRE_ROOT/phases" --phase-brief "$BRIEF" \
test/gh268-relay-cue-and-target-checks.sh:143:DRV="$ROOT/relay-automation/marathon-drive.sh"
test/gh268-relay-cue-and-target-checks.sh:148:# no longer write at all, but they stay MARATHON_ROOT-scoped regardless: a dry run is not the only
test/gh268-relay-cue-and-target-checks.sh:166:out="$(MARATHON_ROOT="$MROOT" bash "$DRV" --target-root "$HASV" --phase-brief "$BRIEF" --reviewer agy --builder codex --dry-run 2>&1)"
test/gh268-relay-cue-and-target-checks.sh:194:out="$(MARATHON_ROOT="$MROOT" bash "$DRV" --target-root "$NOV" --phase-brief "$BRIEF" --reviewer agy --builder codex --dry-run 2>&1)"
test/gh331-cost-summary.sh:3:# implemented only in the Bash twins (relay-drive.sh GH-152, marathon-drive.sh GH-222), so on the
test/gh331-cost-summary.sh:13:#   (4) the same three properties for marathon-drive with MARATHON_COST_SUMMARY.
test/gh331-cost-summary.sh:19:# assertion here drives relay-drive/marathon-drive against this suite's own throwaway repo ($A) and
test/gh331-cost-summary.sh:37:# not the lock; MARATHON_ROOT is honoured by marathon-drive only — which is why the sibling
test/gh331-cost-summary.sh:38:# test/gh284-runlog-heartbeat.sh, scoped with MARATHON_ROOT="$A", was never affected).
test/gh331-cost-summary.sh:70:# marathon-drive needs NO such treatment and deliberately keeps the real path: every assertion below
test/gh331-cost-summary.sh:71:# passes MARATHON_ROOT="$A" (line ~141), which marathon-drive honours for lock resolution, and
test/gh331-cost-summary.sh:74:MDRIVE="$ROOT/relay-automation/marathon-drive.sh"
test/gh331-cost-summary.sh:145:# ── marathon-drive ──────────────────────────────────────────────────────────────────────
test/gh331-cost-summary.sh:146:MCOST_LINE='marathon-drive: end-of-run cost summary (tick analyze)'
test/gh331-cost-summary.sh:159:  env "$@" MARATHON_ROOT="$A" MARATHON_RELAY_DRIVE="$STUB_RD" TICK_REPO_ROOT="$A" TICK_BIN="$TICK" \
test/gh331-cost-summary.sh:161:    bash "$MDRIVE" --phases-dir "$A/phases" --phase-brief "$BRIEF" --phase-id "$pid" \
test/gh331-cost-summary.sh:168:  && pass "marathon-drive default lane: driven phase prints the cost summary (exit preserved: 3)" \
test/gh331-cost-summary.sh:169:  || fail "marathon-drive default lane: expected exit 3 + cost summary; got rc=$mRc (out: $(printf '%s' "$mOut" | tail -5))"
test/gh331-cost-summary.sh:174:  && pass "marathon-drive: MARATHON_COST_SUMMARY=0 opts out of the summary" \
test/gh331-cost-summary.sh:175:  || fail "marathon-drive: MARATHON_COST_SUMMARY=0 did not silence the summary (rc=$mRc0): $(printf '%s' "$mOut0" | tail -5)"
test/swarm-preflight.sh:71:# and the marathon-drive run records harness:"swarm" (not "marathon") in XYZ.json, no extra step.
test/swarm-preflight.sh:72:head -1 "$R/packet/marathon-invocation.txt" | grep -q '^XYZ_HARNESS_CONTEXT=swarm XYZ_SESSION_ID=[^ ]* RELAY_WORKTREE_ISOLATION=1 relay-automation/marathon-drive.sh' \
test/marathon-drive.sh:2:# marathon-drive.sh test: single-phase driver — renders relay file, seeds tick token,
test/marathon-drive.sh:5:source "$(dirname "$0")/_setup.sh" marathon-drive
test/marathon-drive.sh:8:DRIVER="$(cd "$(dirname "$0")/.." && pwd)/relay-automation/marathon-drive.sh"
test/marathon-drive.sh:31:# GH-117: stub builder/reviewer binaries so marathon-drive's binary-existence probe (added ahead of
test/marathon-drive.sh:46:# GH-212: this suite's default builder identity is pinned to `claude` here (not marathon-drive's
test/marathon-drive.sh:51:  MARATHON_ROOT="$A" \
test/marathon-drive.sh:57:    --phases-dir "$A/phases" \
test/marathon-drive.sh:198:  printf 'MARATHON_ROOT=%s\n'       "${MARATHON_ROOT-<unset>}"
test/marathon-drive.sh:218:  for keep in MARATHON_ROOT TICK_REPO_ROOT; do
test/marathon-drive.sh:264:  HELP_OUT="$(MARATHON_ROOT="$A" XYZ_PYTHON="$runtime" bash "$DRIVER" --help 2>&1)"; rc=$?
test/marathon-drive.sh:356:# eval only for command strings. marathon-drive passes the path as-is (no %q quoting). This case uses
test/marathon-drive.sh:377:MARATHON_ROOT="$A" MARATHON_RELAY_DRIVE="$EVAL_RD" MARATHON_AGENT_CMD="$SPACED_AGENT" \
test/marathon-drive.sh:380:  bash "$DRIVER" --phases-dir "$A/phases" --phase-brief "$BRIEF" \
test/marathon-drive.sh:406:MARATHON_ROOT="$A" MARATHON_RELAY_DRIVE="$EVAL_RD" MARATHON_AGENT_CMD="$ENV_AGENT" \
test/marathon-drive.sh:409:  bash "$DRIVER" --phases-dir "$A/phases" --phase-brief "$BRIEF" \
test/marathon-drive.sh:419:MARATHON_ROOT="$A" MARATHON_RELAY_DRIVE="$EVAL_RD" MARATHON_AGENT_CMD="$ENV_AGENT" \
test/marathon-drive.sh:422:  bash "$DRIVER" --phases-dir "$A/phases" --phase-brief "$BRIEF" \
test/marathon-drive.sh:500:SAT_OUT="$(MARATHON_ROOT="$A" MARATHON_RELAY_DRIVE="$RD_SAT" MARATHON_LANE_NS="satisfied-plan--p1" \
test/marathon-drive.sh:502:  bash "$DRIVER" --phases-dir "$A/phases" --phase-brief "$BRIEF" --reviewer agy --artifact src/satisfied.js \
test/marathon-drive.sh:534:STALL_OUT="$(MARATHON_ROOT="$A" MARATHON_RELAY_DRIVE="$RD_STALLED" MARATHON_LANE_NS="stalled-plan--p1" \
test/marathon-drive.sh:536:  bash "$DRIVER" --phases-dir "$A/phases" --phase-brief "$BRIEF" --reviewer agy --artifact src/stalled.js \
test/marathon-drive.sh:568:ZERO_OUT="$(MARATHON_ROOT="$A" MARATHON_RELAY_DRIVE="$RD_GH279" MARATHON_LANE_NS="gh279-zero--p1" \
test/marathon-drive.sh:570:  bash "$DRIVER" --phases-dir "$A/phases" --phase-brief "$BRIEF" --reviewer agy --artifact src/zero-artifact.js \
test/marathon-drive.sh:584:UNCHANGED_OUT="$(MARATHON_ROOT="$A" MARATHON_RELAY_DRIVE="$RD_GH279" MARATHON_LANE_NS="gh279-unchanged--p1" \
test/marathon-drive.sh:586:  bash "$DRIVER" --phases-dir "$A/phases" --phase-brief "$BRIEF" --reviewer agy --artifact src/unchanged-artifact.js \
test/marathon-drive.sh:626:FIRST_OUT="$(MARATHON_ROOT="$A" MARATHON_RELAY_DRIVE="$RD_GH274" \
test/marathon-drive.sh:628:  bash "$DRIVER" --phases-dir "$A/phases" --phase-brief "$BRIEF" --reviewer agy \
test/marathon-drive.sh:642:RETRY_OUT="$(MARATHON_ROOT="$A" MARATHON_RELAY_DRIVE="$RD_GH274" \
test/marathon-drive.sh:644:  bash "$DRIVER" --phases-dir "$A/phases" --phase-brief "$BRIEF" --reviewer agy \
test/marathon-drive.sh:673:  MARATHON_ROOT="$WT" \
test/marathon-drive.sh:680:    --phases-dir "$WT/phases" \
test/marathon-drive.sh:713:GATE_PREFLIGHT_OUT="$(MARATHON_ROOT="$A" MARATHON_RELAY_DRIVE="$STUB_RD" \
test/marathon-drive.sh:716:  bash "$DRIVER" --phases-dir "$A/phases" --phase-brief "$BRIEF" --reviewer agy --builder claude 2>&1)"; rc=$?
test/marathon-drive.sh:808:# marathon-drive -> relay-drive -> marathon-agent -> codex-turn/agy-turn with worktree isolation ON
test/marathon-drive.sh:838:  unset MARATHON_ROOT MARATHON_HOME MARATHON_DRIVE MARATHON_YAML_BIN TICK_BIN XYZ_APPEND_BIN
test/marathon-drive.sh:840:    ./.xyz/relay-automation/marathon-drive.sh \
test/marathon-drive.sh:871:  unset MARATHON_ROOT MARATHON_HOME MARATHON_DRIVE MARATHON_YAML_BIN TICK_BIN XYZ_APPEND_BIN
test/marathon-drive.sh:873:    ./.xyz/relay-automation/marathon-drive.sh \
test/marathon-drive.sh:939:  unset MARATHON_ROOT MARATHON_HOME MARATHON_DRIVE MARATHON_YAML_BIN TICK_BIN XYZ_APPEND_BIN
test/marathon-drive.sh:941:    ./.xyz/relay-automation/marathon-drive.sh \
test/marathon-drive.sh:979:  unset MARATHON_ROOT MARATHON_HOME MARATHON_DRIVE MARATHON_YAML_BIN TICK_BIN XYZ_APPEND_BIN
test/marathon-drive.sh:981:    ./.xyz/relay-automation/marathon-drive.sh \
test/marathon-drive.sh:1017:DEFAULT_BUILDER_OUT="$(RELAY_DRIVE_EXIT=0 MARATHON_ROOT="$A" MARATHON_RELAY_DRIVE="$STUB_RD" \
test/marathon-drive.sh:1020:  bash "$DRIVER" --phases-dir "$A/phases" --phase-brief "$BRIEF" --reviewer agy \
test/marathon-monitor.sh:57:  local f="$events_dir/marathon-DRIVE.jsonl"
test/gh322-runlog-python-lane.sh:4:# Phase 2 shipped both features in relay-automation/marathon-drive.sh only. That twin `exec`s
test/gh322-runlog-python-lane.sh:15:DRIVER="$ROOT/relay-automation/marathon-drive.sh"
test/gh322-runlog-python-lane.sh:99:  MARATHON_COST_SUMMARY=0 MARATHON_ROOT="$A" MARATHON_RELAY_DRIVE="$STUB_RD" \
test/gh322-runlog-python-lane.sh:101:    PATH="${GH_ON_PATH:-}$NODE_ONLY:/usr/bin:/bin" bash "$DRIVER" --phases-dir "$A/phases" \
test/gh322-runlog-python-lane.sh:269:# GH-401: --help never reaches the render, but it stays MARATHON_ROOT-scoped like every other driver
test/gh322-runlog-python-lane.sh:272:MARATHON_ROOT="$WORK/mroot-help" \
test/gh385-retry-token-satisfied.sh:19:# The driver now reads which task the relay was actually rendered for, from its own marathon-drive
test/gh385-retry-token-satisfied.sh:49:  printf '# Marathon Phase p1\nSTATUS: Approved\nNEXT: agy (Reviewer)\n\n<!-- marathon-drive: task=%s builder=claude reviewer=agy round-cap=5 -->\n\nbody\n' \
test/gh385-retry-token-satisfied.sh:59:run_driver() {  # [extra marathon-drive args...]
test/gh385-retry-token-satisfied.sh:61:  MARATHON_ROOT="$A" MARATHON_RELAY_DRIVE="$RD" TICK_REPO_ROOT="$A" TICK_BIN="$TICK" \
test/gh385-retry-token-satisfied.sh:63:  python3 "$DRIVER" --phases-dir "$A/phases" --phase-brief "$BRIEF" \
test/gh399-packet-acceptance-continuation.sh:148:# MARATHON_ROOT is load-bearing: without it the driver resolves ROOT to the HARNESS repo, takes the
test/gh399-packet-acceptance-continuation.sh:152:relay_out="$(cd "$R" && PATH="$WORK/stubbin:$PATH" MARATHON_ROOT="$R" MARATHON_RELAY_DRIVE="$STUB" \
test/gh399-packet-acceptance-continuation.sh:164:    sys.stdout.write("marathon-drive did not return within 60s\n")
test/gh399-packet-acceptance-continuation.sh:183:  fail "C4 no relay file produced (marathon-drive rc=$mrc): $(printf '%s' "$relay_out" | tail -3)"
test/marathon.sh:3:# order via marathon-drive (STUBBED), HALTS on the first failure (later phases NOT started), and
test/marathon.sh:14:# Stub marathon-drive: record "id|cap|reviewer|artifact|relay-task|turn-timeout|lane-ns" per phase;
test/marathon.sh:38:  RELAY_TURN_TIMEOUT_S= MARATHON_ROOT="$A" MARATHON_DRIVE="$STUB" MARATHON_YAML_BIN="$YBIN" TICK_BIN="$TICK" \
test/marathon.sh:145:MD_BIN="$REPO/relay-automation/marathon-drive.sh"
test/marathon.sh:185:MARATHON_ROOT="$A" MARATHON_RELAY_DRIVE="$RD_RESUME" TICK_BIN="$TICK" CODEX_BIN="$CODEX_OK" AGY_BIN="$AGY_OK" \
test/marathon.sh:191:  && pass "GH-205: marathon-drive re-entered relay-drive for the reviewer round after exit 7" \
test/marathon.sh:212:MARATHON_ROOT="$A" MARATHON_RELAY_DRIVE="$RD_HANG" TICK_BIN="$TICK" CODEX_BIN="$CODEX_OK" AGY_BIN="$AGY_OK" \
test/marathon.sh:246:cat > "$V/.xyz/relay-automation/marathon-drive.sh" <<STUB
test/marathon.sh:249:phase_brief=""; phases_dir=""
test/marathon.sh:253:    --phases-dir)  phases_dir="\$2"; shift 2 ;;
test/marathon.sh:257:printf '%s|%s|%s|%s\n' "\$phase_brief" "\$phases_dir" "\${MARATHON_ROOT:-}" "\${TICK_BIN:-}" >> "$WORK/vendored-drive-ran"
test/marathon.sh:260:chmod +x "$V/.xyz/relay-automation/marathon-drive.sh"
test/marathon.sh:264:  unset MARATHON_HOME MARATHON_ROOT MARATHON_DRIVE MARATHON_YAML_BIN TICK_BIN XYZ_APPEND_BIN
test/improve-loop-dogfood.sh:8:# a deterministic builder standing in for an agent (the production builder is marathon-drive plugged
test/relay-xyz-skill-guard.sh:57:run "sess-fp" Bash "bash test/marathon-drive.sh"
test/relay-xyz-skill-guard.sh:58:[ "$RC" = 0 ] && pass "test/marathon-drive.sh is not treated as driving" \
test/gh343-gate-program-target-root.sh:89:                # A direct program path is executed with cwd=target_root by marathon-drive.  Checking it
test/gh417-turn-root-symlink-prefix.sh:20:#   stripping. That commit names test/marathon-drive.sh's GH-171/GH-172 cases in its own message; they
test/debug-mantra.sh:4:# (debug_mantra_note) via marathon-drive.sh's real --dry-run render (fast: dry-run exits BEFORE
test/debug-mantra.sh:8:DRIVER="$(cd "$(dirname "$0")/.." && pwd)/relay-automation/marathon-drive.sh"
test/debug-mantra.sh:19:# GH-117: marathon-drive.sh probes builder/reviewer binaries before rendering — stub them so this
test/debug-mantra.sh:20:# test never depends on claude/agy actually being installed (mirrors test/marathon-drive.sh).
test/debug-mantra.sh:25:  # GH-232: pin --builder claude (mirrors test/marathon-drive.sh's GH-212 convention) — the actual
test/debug-mantra.sh:27:  MARATHON_ROOT="$A" TICK_REPO_ROOT="$A" TICK_BIN="$TICK" \
test/debug-mantra.sh:30:    --phases-dir "$A/phases" \
test/agy-turn.sh:347:# marathon-drive.sh's Step 0, outside this shim — so the containment agy-turn.sh DOES own is the shared
test/sentinel-driver-hooks.sh:2:# test/sentinel-driver-hooks.sh — GH-281 §1.7 acceptance for the marathon-drive.sh Tier-1 hooks.
test/sentinel-driver-hooks.sh:6:#   wiring:         all six §1.3 hooks are present at their call sites in marathon-drive.sh.
test/sentinel-driver-hooks.sh:11:DRIVE="$HERE/../relay-automation/marathon-drive.sh"
test/lane-attempt-cap.sh:3:# Proves the cap logic in relay-drive.sh + marathon-drive.sh: a lane is REFUSED (exit 8, no token)
test/lane-attempt-cap.sh:18:MARATHON_DRIVE="$ROOT/relay-automation/marathon-drive.sh"
test/lane-attempt-cap.sh:22:bash -n "$MARATHON_DRIVE"  && pass "marathon-drive.sh parses"  || fail "marathon-drive.sh syntax"
test/lane-attempt-cap.sh:27:  && pass "marathon-drive.sh calls lane_attempt_gate (keyed on PHASE_ID/LANE_STATE_KEY)" || fail "marathon-drive gate call missing"
test/lane-attempt-cap.sh:31:  && pass "marathon-drive.sh guards the nested relay-drive against double-count" || fail "LANE_ATTEMPT_COUNTED guard missing"
test/lane-attempt-cap.sh:47:grep -qE 'lane_attempt_reset .*"\$(PHASE_ID|LANE_STATE_KEY)"' "$MARATHON_DRIVE" && pass "marathon-drive resets the counter on phase Approved" || fail "marathon reset-on-success missing"

2026-08-10T04:58:24.989832Z ERROR codex_models_manager::manager: failed to renew cache TTL: missing field `base_instructions` at line 95 column 5
2026-08-10T04:58:39.940989Z ERROR codex_models_manager::manager: failed to renew cache TTL: missing field `base_instructions` at line 95 column 5
exec
/bin/zsh -lc "rg -n -C 3 'subprocess\\.run\\(\\[\"git\", \"-C\", root, \"add\"|subprocess\\.run\\(\\[\"git\".*\"add\"|check=True' utils/py/marathon_drive.py
nl -ba utils/py/marathon_drive.py | sed -n '1200,1255p;1765,1820p'
rg -n -i --glob '*.sh' --glob '*.py' --glob '"'!test/**'"' --glob '"'!temp/**'"' --glob '"'!PROJECT/**'"' 'phases' .
rg -n --glob '"'!temp/**'"' --glob '"'!PROJECT/**'"' '(/phases/|ROOT/phases|root, \"phases\"|\"phases/|\\x27phases/|phases/audit-probe)' .
rg -n --glob '*.md' --glob '*.sh' --glob '*.py' --glob '"'!temp/**'"' 'phases-dir|PHASES_DIR|<repo-root>/phases|\\"'$ROOT/phases|root, "phases"'"' ." in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-67768-b0m00j9w
 succeeded in 0ms:
430-    if args.target_root:
431-        try:
432-            subprocess.run(["git", "-C", args.target_root, "rev-parse", "--show-toplevel"], 
433:                           stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, check=True)
434-        except subprocess.CalledProcessError:
435-            die(f"invalid --target-root (not a git repo): {args.target_root}")
436-
--
1180-gate: {run_gate_result[0]}
1181-relay-file: {rel_relay}
1182-""")
1183:        subprocess.run(["git", "-C", root, "add", "--", esc_file], check=True)
1184-        # GH-207: an identical escalation record must not HALT on nothing-to-commit.
1185-        if subprocess.run(["git", "-C", root, "diff", "--cached", "--quiet", "--", esc_file]).returncode != 0:
1186:            subprocess.run(["git", "-C", root, "commit", "-q", "-m", f"marathon: phase {args.phase_id} escalation ({reason})"], check=True)
1187-        # Archive the failed phase's relay transcript too — save_transcript otherwise runs only
1188-        # on success, so an escalated/reverted phase leaves no durable record of its rounds. The
1189-        # 2026-07-30 rebalance-OS marathon (GH-382's panic run) reverted its p5 phase twice and
--
1220-        # (marathon-drive.sh:880-885) — after the copy, before the commit, same as Bash.
1221-        xyz_harvest_findings(harvest_findings_bin, relay_file, root, args.target_root,
1222-                             xyz_debug_log_file(root))
1223:        subprocess.run(["git", "-C", root, "add", "--", dest], check=True)
1224-        # GH-207: an identical transcript (same-second re-render) must not HALT on nothing-to-commit.
1225-        if subprocess.run(["git", "-C", root, "diff", "--cached", "--quiet", "--", dest]).returncode == 0:
1226-            log(f"transcript unchanged: {dest}")
1227-        else:
1228:            subprocess.run(["git", "-C", root, "commit", "-q", "-m", f"marathon: phase {args.phase_id} transcript saved ({relay_task})"], check=True)
1229-            log(f"transcript saved: {dest}")
1230-        return True
1231-
--
1779-    with open(relay_file, 'w') as f:
1780-        f.write(relay_content)
1781-
1782:    subprocess.run(["git", "-C", root, "add", "--", relay_file], check=True)
1783-    # GH-207: only commit when the render actually changed — a byte-identical re-render must not HALT on
1784-    # a "nothing to commit" git error; treat it as unchanged and continue.
1785-    if subprocess.run(["git", "-C", root, "diff", "--cached", "--quiet", "--", relay_file]).returncode == 0:
1786-        log(f"relay file unchanged: {relay_file}")
1787-    else:
1788:        subprocess.run(["git", "-C", root, "commit", "-q", "-m", f"marathon: render phase {args.phase_id} relay ({relay_task})"], check=True)
1789-        log(f"relay file committed: {relay_file}")
1790-
1791-    os.environ["TICK_REPO_ROOT"] = root
  1200	        xyz_debug_log_append(
  1201	            root, "error", "marathon.escalation",
  1202	            f"{reason} (relay-drive-exit={rexit})",
  1203	            file=rel_relay, action="promote to PROJECT/1-INBOX capture doc",
  1204	            target_root=args.target_root, phase_id=args.phase_id, relay_task=relay_task)
  1205	
  1206	    def save_transcript():
  1207	        try:
  1208	            # We must use relay-turn-lib.sh to resolve rtl_transcript_root
  1209	            ts_base = subprocess.check_output(f"source \"{os.path.join(xyz_harness, 'relay-automation', 'relay-turn-lib.sh')}\" && rtl_transcript_root \"{root}\"", shell=True, executable="/bin/bash").decode('utf-8').strip()
  1210	        except subprocess.CalledProcessError:
  1211	            return False
  1212	
  1213	        import datetime
  1214	        now = datetime.datetime.utcnow()
  1215	        date_dir = os.path.join(ts_base, now.strftime("%Y-%m-%d"))
  1216	        os.makedirs(date_dir, exist_ok=True)
  1217	        dest = os.path.join(date_dir, f"marathon-{args.phase_id}-{now.strftime('%H%M%S')}.md")
  1218	        shutil.copy2(relay_file, dest)
  1219	        # Sentinel Tier 1 (GH-281/GH-342): harvest Side Findings from the saved transcript
  1220	        # (marathon-drive.sh:880-885) — after the copy, before the commit, same as Bash.
  1221	        xyz_harvest_findings(harvest_findings_bin, relay_file, root, args.target_root,
  1222	                             xyz_debug_log_file(root))
  1223	        subprocess.run(["git", "-C", root, "add", "--", dest], check=True)
  1224	        # GH-207: an identical transcript (same-second re-render) must not HALT on nothing-to-commit.
  1225	        if subprocess.run(["git", "-C", root, "diff", "--cached", "--quiet", "--", dest]).returncode == 0:
  1226	            log(f"transcript unchanged: {dest}")
  1227	        else:
  1228	            subprocess.run(["git", "-C", root, "commit", "-q", "-m", f"marathon: phase {args.phase_id} transcript saved ({relay_task})"], check=True)
  1229	            log(f"transcript saved: {dest}")
  1230	        return True
  1231	
  1232	    # GH-307: the gate is a correctness check on the REPO — it is not part of this run's
  1233	    # provenance, and it must not be able to see who is driving it. These tags otherwise leak
  1234	    # into the gate subprocess and break tests that legitimately assert on them
  1235	    # (test/xyz-harness-hooks.sh reads XYZ_HARNESS_CONTEXT / XYZ_SESSION_ID;
  1236	    # test/debug-mantra.sh reads MARATHON_LANE_NS), which made `bash validate.sh` — the
  1237	    # DOCUMENTED DEFAULT GATE — impossible to pass inside a marathon: every phase 1 escalated
  1238	    # with reason `pre-advance-failed` while its own change was correct and approved.
  1239	    # Scrubbing is deliberately narrow: only the run-identity tags, never repo/config inputs
  1240	    # like MARATHON_ROOT, TICK_BIN or TICK_REPO_ROOT, which a gate may legitimately need.
  1241	    # GH-441 Phase 2 — the gate's inherited environment is governed by a stated contract, not by a
  1242	    # denylist maintained here and a second, different one in validate.sh's prologue. That split was
  1243	    # the defect: marathon_drive popped 3 names, validate.sh unset 6 MORE, and any custom
  1244	    # --pre-advance-cmd that omitted the prologue was silently wrong (observed live — a hand-written
  1245	    # gate reproduced the oracle-guard flip on ambient ALLOW_PATHS). utils/py/gate_env.py now
  1246	    # classifies EVERY variable the drivers export as scrub-or-pass with a reason, and
  1247	    # test/gh441-gate-env-contract.sh fails loudly if a new export is added without a classification.
  1248	    #
  1249	    # It deliberately does NOT scrub RELAY_DRIVER_LOCKED; see that module's docstring for the measured
  1250	    # reason (scrubbing it globally was landed and reverted — the nested drivers need it SET and the
  1251	    # lock assertions need it UNSET, so the fix is per-suite, which shipped as Phase 1).
  1252	    # GH-441 Phase 2 widened this from three names to every variable the drivers export. The
  1253	    # registry with the REASON for each classification lives in utils/py/gate_env.py; this stays a
  1254	    # plain literal on purpose, for two reasons that both cost a full gate run to learn:
  1255	    #
  1765	        # GH-401: a dry run must not write, but it must still SHOW its work — otherwise the flag
  1766	        # becomes "do nothing and tell you nothing", and the render (the expensive, interesting part)
  1767	        # is unobservable. Emitting it here is not a test affordance: test/debug-mantra.sh has always
  1768	        # relied on --dry-run to produce a rendered relay it can inspect WITHOUT driving a phase or
  1769	        # touching .tick/attempts/<lane>, which is the state that test hand-seeds. That need is real;
  1770	        # the file write it used to ride on is what was wrong. Fenced so a caller can extract the
  1771	        # render exactly, and so a grep for template text can't be confused with a driver log line.
  1772	        print("--- BEGIN RENDERED RELAY ---")
  1773	        print(relay_content, end="")
  1774	        print("--- END RENDERED RELAY ---")
  1775	        print(f"tick seed: log task.created {relay_task} + claim --agent marathon + release --to {args.builder}")
  1776	        sys.exit(0)
  1777	
  1778	    os.makedirs(phase_dir, exist_ok=True)
  1779	    with open(relay_file, 'w') as f:
  1780	        f.write(relay_content)
  1781	
  1782	    subprocess.run(["git", "-C", root, "add", "--", relay_file], check=True)
  1783	    # GH-207: only commit when the render actually changed — a byte-identical re-render must not HALT on
  1784	    # a "nothing to commit" git error; treat it as unchanged and continue.
  1785	    if subprocess.run(["git", "-C", root, "diff", "--cached", "--quiet", "--", relay_file]).returncode == 0:
  1786	        log(f"relay file unchanged: {relay_file}")
  1787	    else:
  1788	        subprocess.run(["git", "-C", root, "commit", "-q", "-m", f"marathon: render phase {args.phase_id} relay ({relay_task})"], check=True)
  1789	        log(f"relay file committed: {relay_file}")
  1790	
  1791	    os.environ["TICK_REPO_ROOT"] = root
  1792	
  1793	    def reconcile_relay_task():
  1794	        try:
  1795	            info = subprocess.check_output([tick_bin, "info", relay_task], stderr=subprocess.DEVNULL).decode('utf-8').splitlines()
  1796	        except:
  1797	            return
  1798	        
  1799	        status, claimer, handoff = "", "", ""
  1800	        for line in info:
  1801	            if line.startswith("status:"): status = line.split(":", 1)[1].strip()
  1802	            elif line.startswith("claimer:"): claimer = line.split(":", 1)[1].strip()
  1803	            elif line.startswith("handoff-to:"): handoff = line.split(":", 1)[1].strip()
  1804	            
  1805	        if status == "claimed":
  1806	            die(f"relay task {relay_task} already has a live claim by {claimer or 'unknown'}; refusing to reap a live claim")
  1807	        elif status == "open":
  1808	            if not handoff: return
  1809	            if handoff in [args.builder, args.reviewer]:
  1810	                _run_tick_loud([tick_bin, "claim", relay_task, "--agent", handoff, "--paths", rel_relay])
  1811	                _run_tick_loud([tick_bin, "release", relay_task, "--agent", handoff])
  1812	                log(f"reconciled leaked open handoff: {relay_task} (cleared stale reservation for {handoff})")
  1813	            else:
  1814	                die(f"relay task {relay_task} is open but reserved for unexpected agent '{handoff}'")
  1815	
  1816	    # The outer marathon-drive invocation owns this lane's attempt count. A parent relay-drive
  1817	    # process may have set this flag to suppress its nested accounting; do not let that inherited
  1818	    # value skip this invocation's own gate. The child relay-drive environment sets it explicitly
  1819	    # below to avoid double-counting, matching the Bash implementation.
  1820	    os.environ.pop("LANE_ATTEMPT_COUNTED", None)
./skills/skills-sync-trinity/scripts/render_working_doc.py:11:DEFAULT_PHASES = [
./skills/skills-sync-trinity/scripts/render_working_doc.py:35:    phases: list[str],
./skills/skills-sync-trinity/scripts/render_working_doc.py:49:        for idx, phase in enumerate(phases, start=1)
./skills/skills-sync-trinity/scripts/render_working_doc.py:53:    for idx, phase in enumerate(phases, start=1):
./skills/skills-sync-trinity/scripts/render_working_doc.py:84:phases: {len(phases)}
./skills/skills-sync-trinity/scripts/render_working_doc.py:124:    parser.add_argument("--phase", action="append", dest="phases")
./skills/skills-sync-trinity/scripts/render_working_doc.py:130:    phases = args.phases or list(DEFAULT_PHASES)
./skills/skills-sync-trinity/scripts/render_working_doc.py:140:        phases=phases,
./skills/skills-sync-trinity/scripts/sync_trinity.py:123:            phases=["Working doc contract", "Skill contract", "Deterministic helpers"],
./relay-automation/marathon-drive.sh:26:# Renders phases/p1/RELAY.md from the phase brief, seeds the tick token (handoff → builder),
./relay-automation/marathon-drive.sh:40:#     [--phases-dir <DIR>]       where to create phases/<id>/ (default: <repo-root>/phases)
./relay-automation/marathon-drive.sh:41:#     [--phase-id <ID>]          which phase to drive: phases/<id>/ (default: p1; the orchestrator sets it)
./relay-automation/marathon-drive.sh:49:#                                fails (exit 5) even if --pre-advance-cmd passed. Omit for phases with
./relay-automation/marathon-drive.sh:71:# (basename ".xyz"). ROOT = work root = where git ops, phases/, .tick/, validate.sh live.
./relay-automation/marathon-drive.sh:164:# phase's print is the whole chain's true final total; earlier phases' prints are an additive
./relay-automation/marathon-drive.sh:603:  --phases-dir DIR        Where to create phases/<id>/ (default: <repo-root>/phases).
./relay-automation/marathon-drive.sh:604:  --phase-id ID           Which phase to drive: phases/<id>/ (default: p1).
./relay-automation/marathon-drive.sh:614:                          even when --pre-advance-cmd passed. Omit for phases with no test surface
./relay-automation/marathon-drive.sh:633:PHASES_DIR=""        # resolved to default after ROOT is set
./relay-automation/marathon-drive.sh:634:PHASE_ID="p1"        # which phase this invocation drives (phases/<id>/); the orchestrator sets it
./relay-automation/marathon-drive.sh:654:    --phases-dir)      PHASES_DIR="${2:-}"; shift 2 ;;
./relay-automation/marathon-drive.sh:679:PHASES_DIR="${PHASES_DIR:-"$ROOT/phases"}"
./relay-automation/marathon-drive.sh:833:PHASE_DIR="$PHASES_DIR/$LANE_STATE_KEY"
./relay-automation/marathon-drive.sh:957:# marathon's own paths (phases/, .tick/). --require-clean turns the warning into a hard stop for
./relay-automation/marathon-drive.sh:961:    | awk '{ p=substr($0,4); if (p !~ /^phases\// && p !~ /^\.tick\//) print p }')"
./relay-automation/marathon-drive.sh:969:# ── Step 1: render phases/p1/RELAY.md ──────────────────────────────────────
./relay-automation/marathon-ls.sh:110:# Find newest phases/*/RELAY.md path for a repo (used in RELAY-FILE column).
./relay-automation/marathon-ls.sh:113:  local phases_dir="$repo/phases"
./relay-automation/marathon-ls.sh:114:  [ -d "$phases_dir" ] || { printf '-'; return 0; }
./relay-automation/marathon-ls.sh:117:  f="$(ls -t "$phases_dir"/*/RELAY.md 2>/dev/null | head -1 || true)"
./sentinel-overlay/sentinel-nightly.sh:16:# then phases. PDDA's rule verbatim. Pure frontmatter parse — no egress.
./sentinel-overlay/sentinel-nightly.sh:34:    print(f"{i('effort')+i('complexity')}\t{i('phases')}\t{p}")
./relay-automation/marathon.sh:7:# leaving that phase's ESCALATION.md (written by marathon-drive) and NOT starting later phases.
./relay-automation/marathon.sh:10:# Per-phase round cap = 2 * max_review_rounds + 1 (turns ≠ rounds; the off-by-one kills phases early).
./relay-automation/marathon.sh:15:#   relay-automation/marathon.sh --plan MARATHON.yaml [--builder codex] [--phases-dir DIR]
./relay-automation/marathon.sh:50:# Exit: 0 all phases approved · N the failing phase's marathon-drive exit code · 2 usage/parse error.
./relay-automation/marathon.sh:84:Usage: marathon.sh --plan MARATHON.yaml [--builder A] [--phases-dir D] [--pre-advance-cmd C]
./relay-automation/marathon.sh:94:  --phases-dir DIR        Where to create phases/<id>/ (default: <repo-root>/phases).
./relay-automation/marathon.sh:96:                          The relay thread, tick token, phases/ and relay-system/ transcripts all stay
./relay-automation/marathon.sh:98:                          repo cannot track harness output (e.g. a public repo that gitignores phases/
./relay-automation/marathon.sh:111:PLAN=""; BUILDER="codex"; PHASES_DIR=""; PRE_ADVANCE_CMD=""; DRY_RUN=0; FORCE=0; RETRY_PHASE=""; CLOSEOUT_PR=0
./relay-automation/marathon.sh:117:    --phases-dir)      PHASES_DIR="${2:-}"; shift 2 ;;
./relay-automation/marathon.sh:167:PHASES_DIR="${PHASES_DIR:-"$ROOT/phases"}"
./relay-automation/marathon.sh:172:[[ -n "$PLAN_TSV" ]] || die "plan has no phases"
./relay-automation/marathon.sh:200:               --phase-brief "$brief_path" --round-cap "$cap" --phases-dir "$PHASES_DIR" )
./relay-automation/marathon.sh:234:    log "HALT: phase $id failed (marathon-drive exit $phase_exit) — chain stops; later phases NOT started"
./relay-automation/marathon.sh:265:Phases approved: $phase_count/$phase_count
./utils/pdda/pdda-doc-ready.sh:42:- a multi-phase plan with no table of contents listing its phases
./utils/pdda/pdda-doc-ready.sh:45:  findings (what was investigated, what was found, what it changes for later phases)
./utils/pdda/pdda-doc-ready.sh:47:  missing the triage ratings effort, complexity, risk, phases (used by automation to select work);
./relay-automation/marathon-detail.sh:5:#   - STATUS: / NEXT: lines from the newest phases/*/RELAY.md (if any)
./relay-automation/marathon-detail.sh:39:# Newest phases/*/RELAY.md
./relay-automation/marathon-detail.sh:40:PHASES_DIR="$REPO/phases"
./relay-automation/marathon-detail.sh:42:if [ -d "$PHASES_DIR" ]; then
./relay-automation/marathon-detail.sh:44:  RELAY_FILE="$(ls -t "$PHASES_DIR"/*/RELAY.md 2>/dev/null | head -1 || true)"
./relay-automation/marathon-detail.sh:53:  printf '(no phases/*/RELAY.md found)\n'
./utils/pdda/pdda.sh:85:    # complexity, and risk are integers 1 (low) .. 5 (highest); phases is a positive integer.
./utils/pdda/pdda.sh:95:    if pdda_frontmatter_has_key "$file" "phases"; then
./utils/pdda/pdda.sh:96:      value="$(pdda_trim "$(pdda_frontmatter_value "$file" "phases")")"
./utils/pdda/pdda.sh:98:        pdda_record_finding error "$CHECK_NAME" "$file" 1 "frontmatter 'phases' must be a positive integer (got '$value')" "fix-phases-value"
./utils/pdda/pdda.sh:553:# status such as `Active — Phases 1-4 complete … Ready to close to 3-COMPLETED.` — every human reads
./utils/hq/hq-lib.sh:358:#                    [<complexity>] [<risk>] [<effort>] [<phases>]
./utils/hq/hq-lib.sh:368:# HQ_PARK_RELATED / HQ_PARK_COMPLEXITY / HQ_PARK_RISK / HQ_PARK_EFFORT / HQ_PARK_PHASES before calling
./utils/hq/hq-lib.sh:374:  local complexity="${9:-}" risk="${10:-}" effort="${11:-}" phases="${12:-}"
./utils/hq/hq-lib.sh:384:  [ -n "$phases" ]     || phases=1
./utils/hq/hq-lib.sh:416:phases: $phases
./utils/hq/hq.sh:42:                                          RISK,EFFORT,PHASES} (GH-164 Phase 1).
./utils/hq/hq.sh:199:#   HQ_PARK_COMPLEXITY / HQ_PARK_RISK / HQ_PARK_EFFORT / HQ_PARK_PHASES  — integers 1-5 / phase count
./utils/hq/hq.sh:206:  local p_complexity="${HQ_PARK_COMPLEXITY:-}" p_risk="${HQ_PARK_RISK:-}" p_effort="${HQ_PARK_EFFORT:-}" p_phases="${HQ_PARK_PHASES:-}"
./utils/hq/hq.sh:266:      "$p_complexity" "$p_risk" "$p_effort" "$p_phases" "$p_why" "$p_kc" "$p_ng" "$p_rel" \
./utils/hq/hq.sh:295:    "$p_complexity" "$p_risk" "$p_effort" "$p_phases" "$p_why" "$p_kc" "$p_ng" "$p_rel" \
./utils/swarm-preflight.sh:44:#       "remediation": { "source": "self#phases", "criteria": "Phases 1-7 of GH-25" },
./utils/swarm-preflight.sh:745:DOC_HAS_PHASES=0
./utils/swarm-preflight.sh:746:grep -Eq '^##+ .*[Pp]hase|^- \[[ xX]\]' "$PRIMARY_DOC" 2>/dev/null && DOC_HAS_PHASES=1
./utils/swarm-preflight.sh:750:if [[ -z "$REMED_SRC$REMED_CRIT" && "$DOC_HAS_PHASES" -eq 0 ]]; then
./utils/py/rtl.py:436:# (#410): two phases in one run, same builder and same isolation settings, where the one with TEN
./utils/py/marathon_drive.py:383:    parser.add_argument("--phases-dir", dest="phases_dir")
./utils/py/marathon_drive.py:687:    phases_dir = args.phases_dir or os.path.join(root, "phases")
./utils/py/marathon_drive.py:1136:    phase_dir = os.path.join(phases_dir, lane_state_key)
./utils/py/marathon_drive.py:1666:                    if not p.startswith("phases/") and not p.startswith(".tick/"):
./utils/py/marathon_drive.py:1677:    # phase dir creation used to live here, above the render, so a dry run materialized phases/<id>/
./utils/py/marathon_drive.py:1678:    # in whatever repo it resolved to — the harness itself when no MARATHON_ROOT/--phases-dir was
./utils/py/swarm_preflight.py:1236:    doc_has_phases = 0
./utils/py/swarm_preflight.py:1241:                    doc_has_phases = 1
./utils/py/swarm_preflight.py:1247:    if not remed_src and not remed_crit and doc_has_phases == 0:
./relay-system/2026-08-07/marathon-gh343-gate-program-target-root-232432.md:128:   - /private/tmp/claude-501/-Users-noelsaw-Documents-GH-Repos-xyz-3-agents-swarm/2569ea28-6a7e-429b-87d2-4a92b81c3694/scratchpad/wt-litmus/bin/tick claim MARATHON-GH343-GATE-PROGRAM-TARGET-ROOT-TURN-2 --agent codex --paths "phases/litmus-trustworthy-gates-2026-08-06--gh343-gate-program-target-root/RELAY.md,utils/py/swarm_preflight.py,test/gh343-gate-program-target-root.sh,validate.sh"
./relay-system/2026-08-08/marathon-gh419-trustworthy-gates-005705.md:116:   - /private/tmp/claude-501/-Users-noelsaw-Documents-GH-Repos-xyz-3-agents-swarm/2569ea28-6a7e-429b-87d2-4a92b81c3694/scratchpad/wt-litmus/bin/tick claim MARATHON-GH419-TRUSTWORTHY-GATES-TURN --agent codex --paths "phases/litmus-trustworthy-gates-2026-08-06--gh419-trustworthy-gates/RELAY.md,GUIDING-PRINCIPLES.md,utils/py/gate_inventory.py,test/gh419-gate-inventory.sh,validate.sh"
./relay-system/2026-08-07/marathon-gh418-preflight-issue-state-234915.md:126:   - /private/tmp/claude-501/-Users-noelsaw-Documents-GH-Repos-xyz-3-agents-swarm/2569ea28-6a7e-429b-87d2-4a92b81c3694/scratchpad/wt-litmus/bin/tick claim MARATHON-GH418-PREFLIGHT-ISSUE-STATE-TURN --agent codex --paths "phases/litmus-trustworthy-gates-2026-08-06--gh418-preflight-issue-state/RELAY.md,utils/py/swarm_preflight.py,test/gh418-issue-state-frozen.sh,validate.sh"
./relay-system/2026-08-07/marathon-gh419-trustworthy-gates-161447.md:116:   - /private/tmp/claude-501/-Users-noelsaw-Documents-GH-Repos-xyz-3-agents-swarm/2569ea28-6a7e-429b-87d2-4a92b81c3694/scratchpad/wt-litmus/bin/tick claim MARATHON-GH419-TRUSTWORTHY-GATES-TURN --agent codex --paths "phases/litmus-trustworthy-gates-2026-08-06--gh419-trustworthy-gates/RELAY.md,GUIDING-PRINCIPLES.md,utils/py/gate_inventory.py,test/gh419-gate-inventory.sh,validate.sh"
./relay-system/2026-08-08/marathon-gh419-trustworthy-gates-000634.md:116:   - /private/tmp/claude-501/-Users-noelsaw-Documents-GH-Repos-xyz-3-agents-swarm/2569ea28-6a7e-429b-87d2-4a92b81c3694/scratchpad/wt-litmus/bin/tick claim MARATHON-GH419-TRUSTWORTHY-GATES-TURN --agent codex --paths "phases/litmus-trustworthy-gates-2026-08-06--gh419-trustworthy-gates/RELAY.md,GUIDING-PRINCIPLES.md,utils/py/gate_inventory.py,test/gh419-gate-inventory.sh,validate.sh"
./relay-system/2026-08-07/marathon-gh419-trustworthy-gates-160216.md:116:   - /private/tmp/claude-501/-Users-noelsaw-Documents-GH-Repos-xyz-3-agents-swarm/2569ea28-6a7e-429b-87d2-4a92b81c3694/scratchpad/wt-litmus/bin/tick claim MARATHON-GH419-TRUSTWORTHY-GATES-TURN --agent codex --paths "phases/litmus-trustworthy-gates-2026-08-06--gh419-trustworthy-gates/RELAY.md,GUIDING-PRINCIPLES.md,utils/py/gate_inventory.py,test/gh419-gate-inventory.sh,validate.sh"
./relay-system/2026-08-08/marathon-gh418-preflight-issue-state-012949.md:163:   - /private/tmp/claude-501/-Users-noelsaw-Documents-GH-Repos-xyz-3-agents-swarm/2569ea28-6a7e-429b-87d2-4a92b81c3694/scratchpad/wt-litmus/bin/tick claim MARATHON-GH418-PREFLIGHT-ISSUE-STATE-TURN --agent codex --paths "phases/litmus-trustworthy-gates-2026-08-06--gh418-preflight-issue-state/RELAY.md,utils/py/swarm_preflight.py,test/gh418-issue-state-frozen.sh,validate.sh"
./relay-system/2026-07-03/gh102-qa-082014/gh102-qa.codex.md:1751:    67	PHASES_DIR="${PHASES_DIR:-"$ROOT/phases"}"
./relay-system/2026-07-03/gh102-qa-082014/gh102-qa.codex.md:2040:./phases/gh33p4/RELAY.md:44:- [x] `tick` claim/heartbeat cadence is unchanged — only the *poll* cadence adapts (wrapper touches no token logic).
./relay-system/2026-08-07/marathon-gh419-trustworthy-gates-150542.md:116:   - /private/tmp/claude-501/-Users-noelsaw-Documents-GH-Repos-xyz-3-agents-swarm/2569ea28-6a7e-429b-87d2-4a92b81c3694/scratchpad/wt-litmus/bin/tick claim MARATHON-GH419-TRUSTWORTHY-GATES-TURN --agent codex --paths "phases/litmus-trustworthy-gates-2026-08-06--gh419-trustworthy-gates/RELAY.md,GUIDING-PRINCIPLES.md,utils/py/gate_inventory.py,test/gh419-gate-inventory.sh,validate.sh"
./decisions/2026-06-30-target-root-same-repo-normalization.md:27:the relay file as an **absolute** path — and `${"/abs/.../phases/<id>/RELAY.md"#"./"}` strips nothing, so
./relay-system/2026-08-08/marathon-gh418-preflight-issue-state-001117.md:131:   - /private/tmp/claude-501/-Users-noelsaw-Documents-GH-Repos-xyz-3-agents-swarm/2569ea28-6a7e-429b-87d2-4a92b81c3694/scratchpad/wt-litmus/bin/tick claim MARATHON-GH418-PREFLIGHT-ISSUE-STATE-TURN-2 --agent codex --paths "phases/litmus-trustworthy-gates-2026-08-06--gh418-preflight-issue-state/RELAY.md,utils/py/swarm_preflight.py,test/gh418-issue-state-frozen.sh,validate.sh"
./relay-system/2026-07-09/ate-skill-review-083544/ate-skill-review.codex.md:1369:./phases/gh27/RELAY.md:46:     (a) a top banner `<!-- GENERATED by utils/roadmap-dashboard.sh — DO NOT EDIT; edit ROADMAP.md -->`,
./relay-system/2026-07-09/ate-skill-review-083544/ate-skill-review.codex.md:1403:./phases/gh112/RELAY.md:62:   genuine-ref check + GH-127 bare-`>` redirect detection. Absent from `utils/py/swarm_preflight.py`.
./relay-system/2026-07-09/ate-skill-review-083544/ate-skill-review.codex.md:1404:./phases/gh112/RELAY.md:97:  "remediation": "Port three PRE-#134 gaps into the opt-in Python twins so utils/py mirrors Bash. (1) GH-106: in utils/py/codex-turn.py, change the default CODEX_FLAGS to match relay-automation/codex-turn.sh's post-#134 default (include `-c approval_policy=never`); add a `GH-106` marker comment. (2) GH-117: in utils/py/marathon_drive.py, probe the builder AND reviewer binaries (shutil.which / equivalent) BEFORE any tick-state mutation, mirroring relay-automation/marathon-drive.sh; fail early if missing; add a `GH-117` marker comment. (3) GH-108: in utils/py/swarm_preflight.py, add the gate-scoping caveat + GH-126 genuine-ref check + GH-127 bare-`>` redirect detection from utils/swarm-preflight.sh; add a `GH-108` marker comment. Then add one behavioral parity test per fix to test/test_python_layer.py (assert the Python module reproduces the Bash behavior), plus one test asserting GH-107's containment exemption is honored in Python mode via rtl.py (do NOT reimplement GH-107). Finally, wire `python3 -m pytest test/test_python_layer.py` into validate.sh so the Python layer is gated. Do NOT change any default-mode Bash behavior; validate.sh must stay green in default mode. Do NOT flip XYZ_PYTHON to default. Do NOT touch relay-turn-lib.sh.",
./relay-system/2026-07-09/ate-skill-review-083544/ate-skill-review.codex.md:1414:./phases/gh112b/RELAY.md:62:   genuine-ref check + GH-127 bare-`>` redirect detection. Absent from `utils/py/swarm_preflight.py`.
./relay-system/2026-07-09/ate-skill-review-083544/ate-skill-review.codex.md:1415:./phases/gh112b/RELAY.md:97:  "remediation": "Port three PRE-#134 gaps into the opt-in Python twins so utils/py mirrors Bash. (1) GH-106: in utils/py/codex-turn.py, change the default CODEX_FLAGS to match relay-automation/codex-turn.sh's post-#134 default (include `-c approval_policy=never`); add a `GH-106` marker comment. (2) GH-117: in utils/py/marathon_drive.py, probe the builder AND reviewer binaries (shutil.which / equivalent) BEFORE any tick-state mutation, mirroring relay-automation/marathon-drive.sh; fail early if missing; add a `GH-117` marker comment. (3) GH-108: in utils/py/swarm_preflight.py, add the gate-scoping caveat + GH-126 genuine-ref check + GH-127 bare-`>` redirect detection from utils/swarm-preflight.sh; add a `GH-108` marker comment. Then add one behavioral parity test per fix to test/test_python_layer.py (assert the Python module reproduces the Bash behavior), plus one test asserting GH-107's containment exemption is honored in Python mode via rtl.py (do NOT reimplement GH-107). Finally, wire `python3 -m pytest test/test_python_layer.py` into validate.sh so the Python layer is gated. Do NOT change any default-mode Bash behavior; validate.sh must stay green in default mode. Do NOT flip XYZ_PYTHON to default. Do NOT touch relay-turn-lib.sh.",
./relay-system/2026-08-07/marathon-gh419-trustworthy-gates-172903.md:116:   - /private/tmp/claude-501/-Users-noelsaw-Documents-GH-Repos-xyz-3-agents-swarm/2569ea28-6a7e-429b-87d2-4a92b81c3694/scratchpad/wt-litmus/bin/tick claim MARATHON-GH419-TRUSTWORTHY-GATES-TURN --agent codex --paths "phases/litmus-trustworthy-gates-2026-08-06--gh419-trustworthy-gates/RELAY.md,GUIDING-PRINCIPLES.md,utils/py/gate_inventory.py,test/gh419-gate-inventory.sh,validate.sh"
./relay-system/2026-08-08/marathon-gh343-gate-program-target-root-011455.md:136:   - /private/tmp/claude-501/-Users-noelsaw-Documents-GH-Repos-xyz-3-agents-swarm/2569ea28-6a7e-429b-87d2-4a92b81c3694/scratchpad/wt-litmus/bin/tick claim MARATHON-GH343-GATE-PROGRAM-TARGET-ROOT-TURN-3 --agent codex --paths "phases/litmus-trustworthy-gates-2026-08-06--gh343-gate-program-target-root/RELAY.md,utils/py/swarm_preflight.py,test/gh343-gate-program-target-root.sh,validate.sh"
./relay-system/2026-08-07/marathon-gh343-gate-program-target-root-163253.md:117:   - /private/tmp/claude-501/-Users-noelsaw-Documents-GH-Repos-xyz-3-agents-swarm/2569ea28-6a7e-429b-87d2-4a92b81c3694/scratchpad/wt-litmus/bin/tick claim MARATHON-GH343-GATE-PROGRAM-TARGET-ROOT-TURN --agent codex --paths "phases/litmus-trustworthy-gates-2026-08-06--gh343-gate-program-target-root/RELAY.md,utils/py/swarm_preflight.py,test/gh343-gate-program-target-root.sh,validate.sh"
./relay-system/2026-08-08/marathon-gh425-source-url-slug-014823.md:122:   - /private/tmp/claude-501/-Users-noelsaw-Documents-GH-Repos-xyz-3-agents-swarm/2569ea28-6a7e-429b-87d2-4a92b81c3694/scratchpad/wt-litmus/bin/tick claim MARATHON-GH425-SOURCE-URL-SLUG-TURN --agent codex --paths "phases/litmus-trustworthy-gates-2026-08-06--gh425-source-url-slug/RELAY.md,utils/py/swarm_preflight.py,skills/10days/SKILL.md,test/gh425-source-url-slug.sh,validate.sh"
./relay-system/2026-08-07/marathon-gh419-trustworthy-gates-162840.md:116:   - /private/tmp/claude-501/-Users-noelsaw-Documents-GH-Repos-xyz-3-agents-swarm/2569ea28-6a7e-429b-87d2-4a92b81c3694/scratchpad/wt-litmus/bin/tick claim MARATHON-GH419-TRUSTWORTHY-GATES-TURN --agent codex --paths "phases/litmus-trustworthy-gates-2026-08-06--gh419-trustworthy-gates/RELAY.md,GUIDING-PRINCIPLES.md,utils/py/gate_inventory.py,test/gh419-gate-inventory.sh,validate.sh"
./relay-system/2026-08-07/marathon-gh419-trustworthy-gates-234538.md:116:   - /private/tmp/claude-501/-Users-noelsaw-Documents-GH-Repos-xyz-3-agents-swarm/2569ea28-6a7e-429b-87d2-4a92b81c3694/scratchpad/wt-litmus/bin/tick claim MARATHON-GH419-TRUSTWORTHY-GATES-TURN --agent codex --paths "phases/litmus-trustworthy-gates-2026-08-06--gh419-trustworthy-gates/RELAY.md,GUIDING-PRINCIPLES.md,utils/py/gate_inventory.py,test/gh419-gate-inventory.sh,validate.sh"
./relay-system/2026-08-07/marathon-gh419-trustworthy-gates-152223.md:116:   - /private/tmp/claude-501/-Users-noelsaw-Documents-GH-Repos-xyz-3-agents-swarm/2569ea28-6a7e-429b-87d2-4a92b81c3694/scratchpad/wt-litmus/bin/tick claim MARATHON-GH419-TRUSTWORTHY-GATES-TURN --agent codex --paths "phases/litmus-trustworthy-gates-2026-08-06--gh419-trustworthy-gates/RELAY.md,GUIDING-PRINCIPLES.md,utils/py/gate_inventory.py,test/gh419-gate-inventory.sh,validate.sh"
./relay-system/2026-08-07/marathon-gh419-trustworthy-gates-232130.md:116:   - /private/tmp/claude-501/-Users-noelsaw-Documents-GH-Repos-xyz-3-agents-swarm/2569ea28-6a7e-429b-87d2-4a92b81c3694/scratchpad/wt-litmus/bin/tick claim MARATHON-GH419-TRUSTWORTHY-GATES-TURN --agent codex --paths "phases/litmus-trustworthy-gates-2026-08-06--gh419-trustworthy-gates/RELAY.md,GUIDING-PRINCIPLES.md,utils/py/gate_inventory.py,test/gh419-gate-inventory.sh,validate.sh"
./relay-system/2026-07-22/marathon-gh268r2a-installers-063411.md:49:   - /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick claim MARATHON-GH268R2A-INSTALLERS-TURN --agent aider-qwen --paths "phases/gh268r2a-installers/RELAY.md,skills/consult/install.sh,skills/open-router/install.sh"
./relay-system/2026-07-05/marathon-gh96seam1-182947.md:68:   - /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick claim MARATHON-GH96SEAM1-TURN --agent codex --paths "phases/gh96seam1/RELAY.md,utils/telemetry/write-xyz-heartbeat.sh,relay-automation/relay-drive.sh,relay-automation/marathon-drive.sh,relay-automation/README.md,.gitignore,test/xyz-completion.sh,test/agy-turn.sh,test/aider-turn.sh,test/archive-commit.sh,test/claude-turn.sh,test/codex-turn.sh,test/driver-lock.sh,test/find-harness.sh,test/fixtures/canary-peer-orphan/verify-fixture.sh,test/lane-attempt-cap.sh,test/marathon-drive.sh,test/poll-relay.sh,test/relay-artifact-file.sh,test/relay-concurrent-commit.sh,test/relay-escalation-not-stall.sh,test/relay-review-once.sh,test/relay-self-sufficiency.sh,test/relay-target-root-newfile.sh,test/relay-target-root-paths.sh,test/relay-target-root-relayfile.sh,test/relay-target-root.sh,test/relay-token-collision.sh,test/relay-turn-timeout.sh,test/relay-untracked-file-warn.sh,test/relay-xyz-skill-guard.sh,test/shim-worktree.sh,test/swarm-preflight.sh,test/worktree-isolation.sh,test/xyz-harness-hooks.sh,test/xyz-vendor.sh,test/_setup.sh,test/_scratch-repo.sh"
./relay-system/2026-07-05/marathon-gh137-091059.md:117:   - /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick claim MARATHON-GH137-TURN --agent codex --paths "phases/gh137/RELAY.md,utils/swarm-preflight.sh,test/swarm-preflight.sh"
./relay-system/2026-07-22/marathon-gh268cgb-installers-153633.md:46:   - /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick claim MARATHON-GH268CGB-INSTALLERS-TURN --agent codex --paths "phases/gh268cgb-installers/RELAY.md,skills/relay-automation/install.sh"
./test/debug-mantra.sh:104:mkdir -p "$A/.tick/attempts" "$A/phases/p1"
./test/debug-mantra.sh:106:cat > "$A/phases/p1/ESCALATION.md" << 'ESC_EOF'
./relay-system/2026-06-17/phase4-qa-220946/phase4-qa.codex.md:332:   100	PHASES_DIR="${PHASES_DIR:-"$ROOT/phases"}"
./relay-system/2026-06-17/phase4-qa-220946/phase4-qa.codex.md:604:    53	PHASES_DIR="${PHASES_DIR:-"$ROOT/phases"}"
./relay-system/2026-06-17/phase4-qa-220946/phase4-qa.codex.md:2273:    46	[ -f "$A/phases/p1/RELAY.md" ] && pass "dry-run renders phases/p1/RELAY.md" || fail "relay file should exist after dry-run"
./relay-system/2026-06-17/phase4-qa-220946/phase4-qa.codex.md:2285:    58	grep -q "TAKE YOUR TURN.*claude.*BUILDER" "$A/phases/p1/RELAY.md" 2>/dev/null \
./relay-system/2026-06-17/phase4-qa-220946/phase4-qa.codex.md:2288:    61	grep -q "TAKE YOUR TURN.*gemini.*REVIEWER" "$A/phases/p1/RELAY.md" 2>/dev/null \
./relay-system/2026-06-17/phase4-qa-220946/phase4-qa.codex.md:2291:    64	grep -q "STATUS: Open" "$A/phases/p1/RELAY.md" 2>/dev/null \
./relay-system/2026-06-17/phase4-qa-220946/phase4-qa.codex.md:2294:    67	grep -q "Implement a hello-world" "$A/phases/p1/RELAY.md" 2>/dev/null \
./relay-system/2026-06-17/phase4-qa-220946/phase4-qa.codex.md:2351:   124	[ -f "$A/phases/p1/ESCALATION.md" ] && pass "ESCALATION.md written on gate failure" || fail "ESCALATION.md missing"
./relay-system/2026-06-17/phase4-qa-220946/phase4-qa.codex.md:2352:   125	grep -q "pre-advance-failed" "$A/phases/p1/ESCALATION.md" \
./relay-system/2026-06-17/phase4-qa-220946/phase4-qa.codex.md:2361:   134	[ -f "$A/phases/p1/ESCALATION.md" ] && pass "ESCALATION.md written on relay cap" || fail "ESCALATION.md missing on cap"
./relay-system/2026-06-17/phase4-qa-220946/phase4-qa.codex.md:2362:   135	grep -q "relay-drive-exit: 4" "$A/phases/p1/ESCALATION.md" \
./relay-system/2026-06-17/phase4-qa-220946/phase4-qa.codex.md:2371:   144	[ -f "$A/phases/p1/ESCALATION.md" ] && pass "ESCALATION.md written on no-progress" || fail "ESCALATION.md missing on no-progress"
./relay-system/2026-06-17/phase4-qa-220946/phase4-qa.codex.md:2380:   153	[ -f "$A/phases/p1/ESCALATION.md" ] && pass "ESCALATION.md written on containment violation" || fail "ESCALATION.md missing on exit 6"
./relay-system/2026-06-17/phase4-qa-220946/phase4-qa.codex.md:2381:   154	grep -q "containment-violation" "$A/phases/p1/ESCALATION.md" \
./relay-system/2026-06-17/phase4-qa-220946/phase4-qa.codex.md:2440:   213	grep -q "$ART" "$A/phases/p1/RELAY.md" 2>/dev/null \
./relay-system/2026-06-17/phase4-qa-220946/phase4-qa.codex.md:2442:   215	grep -q -- "--paths \"phases/p1/RELAY.md,$ART\"" "$A/phases/p1/RELAY.md" 2>/dev/null \
./relay-system/2026-06-17/phase4-qa-220946/phase4-qa.codex.md:2485:   258	[ ! -f "$A/phases/p1/RELAY.md" ] && pass "dirty + --require-clean does not seed the phase" || fail "phase seeded despite --require-clean on dirty tree"
./relay-system/2026-07-02/marathon-gh85-173828.md:61:   - /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick claim MARATHON-GH85-TURN --agent agy --paths "phases/gh85/RELAY.md,utils/marathon-plan.sh,test/marathon-plan.sh"
./relay-system/2026-07-22/marathon-gh268cga-installers-153352.md:51:   - /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick claim MARATHON-GH268CGA-INSTALLERS-TURN --agent codex --paths "phases/gh268cga-installers/RELAY.md,skills/ponytail/install.sh,skills/release/install.sh,skills/skills-sync-trinity/install.sh,skills/swe/install.sh,skills/weekly-shipped/install.sh,skills/xyz/install.sh"
./relay-system/2026-07-03/gh30-phase2-151736/gh30-phase2.codex.md:553:   211	PHASES_DIR="${PHASES_DIR:-"$ROOT/phases"}"
./relay-system/2026-07-02/marathon-gh84-172853.md:55:   - /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick claim MARATHON-GH84-TURN --agent agy --paths "phases/gh84/RELAY.md,relay-automation/runner.sh,test/runner-loop.sh"
./relay-system/2026-07-15/marathon-gh206-root-split-112540.md:50:   - /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick claim MARATHON-GH206-ROOT-SPLIT-TURN --agent codex --paths "phases/gh206-root-split/RELAY.md,relay-automation/marathon.sh,relay-automation/marathon-drive.sh,test/marathon.sh,test/marathon-drive.sh,relay-automation/README.md"
./relay-system/2026-07-02/marathon-gh58-173436.md:58:   - /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick claim MARATHON-GH58-TURN --agent agy --paths "phases/gh58/RELAY.md,relay-automation/claude-turn.sh,test/claude-turn.sh,validate.sh"
./relay-system/2026-07-02/marathon-gh58-173436.md:80:  - [RELAY.md](file:///Users/noelsaw/Documents/GH%20Repos/xyz-3-agents-swarm/phases/gh58/RELAY.md)
./utils/py/marathon_drive.py:687:    phases_dir = args.phases_dir or os.path.join(root, "phases")
./utils/py/marathon_drive.py:1666:                    if not p.startswith("phases/") and not p.startswith(".tick/"):
./relay-system/2026-07-02/marathon-p1-120832.md:64:   - /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick claim MARATHON-GH59-P1 --agent codex --paths "phases/p1/RELAY.md,relay-automation/relay-turn-lib.sh,test/worktree-isolation.sh"
./relay-system/2026-07-02/marathon-p1-110551.md:100:   - /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick claim MARATHON-GH61-P1B --agent codex --paths "phases/p1/RELAY.md,.github/workflows/ci.yml,test/ci-workflow.sh,validate.sh"
./relay-system/2026-06-26/marathon-gh27-091627.md:90:   - /Users/noelsaw/Documents/GitHub-Repos/xyz-3-agents-swarm/bin/tick claim MARATHON-GH27-TURN --agent codex --paths "phases/gh27/RELAY.md,utils/roadmap-dashboard.sh,ROADMAP-DASHBOARD.md,test/roadmap-dashboard.sh"
./test/gh401-dry-run-no-mutation.sh:56:[ ! -e "$MROOT/phases" ] \
./test/gh401-dry-run-no-mutation.sh:58:  || fail "--dry-run created $MROOT/phases — the mkdir is back above the dry-run exit"
./relay-system/2026-07-02/gh45-review-183600/gh45-review.codex.md:540: PHASES_DIR="${PHASES_DIR:-"$ROOT/phases"}"
./relay-system/2026-07-02/gh45-review-183600/gh45-review.codex.md:1768:   191	PHASES_DIR="${PHASES_DIR:-"$ROOT/phases"}"
./relay-system/2026-07-02/gh45-review-183600/gh45-review.codex.md:2127:    66	PHASES_DIR="${PHASES_DIR:-"$ROOT/phases"}"
./test/gh457-gate-tiers.sh:119:    --phases-dir "$ROOT/phases" \
./test/gh457-gate-tiers.sh:125:esc_reason() { sed -n 's/^reason: //p' "$ROOT/phases/$1/ESCALATION.md" 2>/dev/null; }
./test/gh438-acceptance-recheck.sh:79:TICK_REPO_ROOT="$A" "$TICK" claim "\$task" --agent agy --paths "phases/p1/RELAY.md" >/dev/null 2>&1 || true
./test/gh438-acceptance-recheck.sh:109:grep -q 'reason: acceptance-probes-unmet' "$A/phases/p1/ESCALATION.md" 2>/dev/null \
./test/gh438-acceptance-recheck.sh:111:  || fail "escalation record missing or wrong reason: $(cat "$A/phases/p1/ESCALATION.md" 2>/dev/null)"
./test/gh342-sentinel-debug-log-python.sh:122:    file="phases/p1/RELAY.md", action="promote",
./test/gh342-sentinel-debug-log-python.sh:133:    ("file", "phases/p1/RELAY.md"), ("action", "promote"),
./test/gh342-sentinel-debug-log-python.sh:197:         "phases/p1/RELAY.md", "promote to PROJECT/1-INBOX capture doc", "", "p1", "TASK-1", ""),
./relay-system/2026-06-26/kwfs-dueling-bugfix.md:154:  (`/tests/`, `/.tick/`, `/.claude/`, `/MARATHON.yaml`, `/phases-briefs/`, `/phases/`), and build hygiene
./test/gh390-gate-guard.sh:98:    --phases-dir "$ROOT/phases" \
./test/gh390-gate-guard.sh:106:  sed -n 's/^reason: //p' "$ROOT/phases/$1/ESCALATION.md" 2>/dev/null
./relay-system/2026-06-26/marathon-wpcc-095945.md:101:   - /Users/noelsaw/Documents/GitHub-Repos/xyz-marathon-wpcc/bin/tick claim MARATHON-WPCC-TURN3 --agent codex --paths "phases/wpcc/RELAY.md,dist/patterns/ts-type-suppression.json,dist/tests/fixtures/ts-type-suppression.ts,dist/PATTERN-LIBRARY.json,dist/PATTERN-LIBRARY.md,dist/tests/run-fixture-tests.sh"
./test/marathon.sh:173:  TICK_REPO_ROOT="$A" "$TICK" claim "$task" --agent codex --paths "phases/**,src/gh205.js" >/dev/null 2>&1 || true
./test/marathon.sh:179:TICK_REPO_ROOT="$A" "$TICK" claim "$task" --agent agy --paths "phases/**" >/dev/null 2>&1 || true
./test/marathon.sh:193:grep -q '^STATUS: Approved' "$A/phases/gh205/RELAY.md" \
./test/marathon.sh:220:grep -q 'reason: timeout-no-artifact' "$A/phases/gh205-hang/ESCALATION.md" \
./test/gh385-retry-token-satisfied.sh:48:  mkdir -p "$A/phases/p1"
./test/gh385-retry-token-satisfied.sh:50:    "$1" > "$A/phases/p1/RELAY.md"
./test/gh385-retry-token-satisfied.sh:55:  tick_a claim "$1" --agent claude --paths "phases/p1/RELAY.md" >/dev/null 2>&1 || true
./test/gh385-retry-token-satisfied.sh:107:mkdir -p "$A/phases/p1"
./test/gh385-retry-token-satisfied.sh:108:printf '# Marathon Phase p1\nSTATUS: Approved\nNEXT: agy\n\nbody\n' > "$A/phases/p1/RELAY.md"
./test/gh397-reviewer-turn-role.sh:82:mkdir -p "$A/phases/p1"
./test/gh397-reviewer-turn-role.sh:83:MP="$A/phases/p1/RELAY.md"
./test/marathon-root-audit.sh:241:# Not hypothetical: `/phases/` was added to .gitignore on 2026-08-09 to stop the #401/#461 churn, and
./test/marathon-root-audit.sh:243:# makes the revert stick. Verified directly before writing it: in a scratch repo ignoring /phases/,
./test/marathon-root-audit.sh:250:for probe in phases/audit-probe/RELAY.md phases/audit-probe/ESCALATION.md; do
./test/marathon-monitor.sh:42:  mkdir -p "$repo/.git" "$repo/.tick/events" "$repo/phases/p1"
./test/marathon-monitor.sh:48:  mkdir -p "$repo/.tick/events" "$repo/phases/p1"
./relay-automation/marathon-drive.sh:679:PHASES_DIR="${PHASES_DIR:-"$ROOT/phases"}"
./test/litmus-release.sh:104:# gate. Trying to satisfy it from the other side by gitignoring /phases/ is worse — `git add` on an
./test/test_python_layer.py:193:    relay = rtl.RelayTurnLib(REPO_ROOT, REPO_ROOT, os.path.join(REPO_ROOT, "phases/gh112b/RELAY.md"), "")
./test/gh319-gate-path-with-space.sh:93:    --phases-dir "$ROOT/phases" \
./test/gh407-gate-ran-attribution.sh:75:    --phases-dir "$ROOT/phases" \
./test/gh407-gate-ran-attribution.sh:81:esc_field() { sed -n "s/^$2: //p" "$ROOT/phases/$1/ESCALATION.md" 2>/dev/null; }
./test/gh407-gate-ran-attribution.sh:169:rm -rf "$PRE_ROOT/phases"
./test/gh407-gate-ran-attribution.sh:175:  bash "$PRE_DRIVER" --phases-dir "$PRE_ROOT/phases" --phase-brief "$BRIEF" \
./test/gh407-gate-ran-attribution.sh:178:pre_reason="$(sed -n 's/^reason: //p' "$PRE_ROOT/phases/no-gate/ESCALATION.md" 2>/dev/null)"
./test/gh407-gate-ran-attribution.sh:179:pre_gate="$(sed -n 's/^gate: //p' "$PRE_ROOT/phases/no-gate/ESCALATION.md" 2>/dev/null)"
./test/marathon-drive.sh:66:# GH-401: this case used to assert `[ -f "$A/phases/p1/RELAY.md" ]` — it pinned the defect as the
./test/marathon-drive.sh:89:grep -q "TAKE YOUR TURN.*claude.*BUILDER" "$A/phases/p1/RELAY.md" 2>/dev/null \
./test/marathon-drive.sh:92:grep -q "TAKE YOUR TURN.*agy.*REVIEWER" "$A/phases/p1/RELAY.md" 2>/dev/null \
./test/marathon-drive.sh:95:grep -q "STATUS: Open" "$A/phases/p1/RELAY.md" 2>/dev/null \
./test/marathon-drive.sh:98:grep -q "Implement a hello-world" "$A/phases/p1/RELAY.md" 2>/dev/null \
./test/marathon-drive.sh:116:tick_a claim MARATHON-P1-TURN --agent seed --paths "phases/p1/RELAY.md" >/dev/null
./test/marathon-drive.sh:137:tick_a claim MARATHON-P1-TURN --agent claude --paths "phases/p1/RELAY.md" >/dev/null
./test/marathon-drive.sh:237:[ -f "$A/phases/p1/ESCALATION.md" ] && pass "ESCALATION.md written on gate failure" || fail "ESCALATION.md missing"
./test/marathon-drive.sh:238:grep -q "pre-advance-failed" "$A/phases/p1/ESCALATION.md" \
./test/marathon-drive.sh:299:  grep -q '^reason: post-approve-failed$' "$A/phases/p1/ESCALATION.md" 2>/dev/null \
./test/marathon-drive.sh:312:[ -f "$A/phases/p1/ESCALATION.md" ] && pass "ESCALATION.md written on relay cap" || fail "ESCALATION.md missing on cap"
./test/marathon-drive.sh:313:grep -q "relay-drive-exit: 4" "$A/phases/p1/ESCALATION.md" \
./test/marathon-drive.sh:322:[ -f "$A/phases/p1/ESCALATION.md" ] && pass "ESCALATION.md written on no-progress" || fail "ESCALATION.md missing on no-progress"
./test/marathon-drive.sh:331:[ -f "$A/phases/p1/ESCALATION.md" ] && pass "ESCALATION.md written on containment violation" || fail "ESCALATION.md missing on exit 6"
./test/marathon-drive.sh:332:grep -q "containment-violation" "$A/phases/p1/ESCALATION.md" \
./test/marathon-drive.sh:392:grep -q "$ART" "$A/phases/p1/RELAY.md" 2>/dev/null \
./test/marathon-drive.sh:394:grep -q -- "--paths \"phases/p1/RELAY.md,$ART\"" "$A/phases/p1/RELAY.md" 2>/dev/null \
./test/marathon-drive.sh:434:[ -f "$A/phases/plan-a--p1/RELAY.md" ] \
./test/marathon-drive.sh:443:[ -f "$A/phases/plan-b--p1/RELAY.md" ] \
./test/marathon-drive.sh:493:TICK_REPO_ROOT="$A" "$TICK" claim "$task" --agent agy --paths "phases/satisfied-plan--p1/RELAY.md" >/dev/null 2>&1 || true
./test/marathon-drive.sh:509:grep -q '^STATUS: Approved' "$A/phases/satisfied-plan--p1/RELAY.md" \
./test/marathon-drive.sh:543:grep -q 'reason: no-progress' "$A/phases/stalled-plan--p1/ESCALATION.md" \
./test/marathon-drive.sh:613:TICK_REPO_ROOT="$A" "$TICK" claim "$task" --agent claude --paths "phases/p1/RELAY.md" >/dev/null 2>&1 || true
./test/marathon-drive.sh:615:TICK_REPO_ROOT="$A" "$TICK" claim "$task" --agent agy --paths "phases/p1/RELAY.md" >/dev/null 2>&1 || true
./test/marathon-drive.sh:632:grep -q '^STATUS: Approved' "$A/phases/p1/RELAY.md" \
./test/marathon-drive.sh:634:  || fail "GH-274: RELAY.md should show STATUS: Approved: $(cat "$A/phases/p1/RELAY.md" 2>/dev/null)"
./test/marathon-drive.sh:638:BEFORE_RETRY_RELAY="$(cat "$A/phases/p1/RELAY.md")"
./test/marathon-drive.sh:651:[ "$(cat "$A/phases/p1/RELAY.md")" = "$BEFORE_RETRY_RELAY" ] \
./test/marathon-drive.sh:653:  || fail "GH-274: RELAY.md changed on retry: $(cat "$A/phases/p1/RELAY.md")"
./test/marathon-drive.sh:654:grep -q '^STATUS: Open' "$A/phases/p1/RELAY.md" \
./test/marathon-drive.sh:692:[ -f "$WT/phases/p1/RELAY.md" ] && pass "linked worktree + --require-clean still seeds the phase" \
./test/marathon-drive.sh:701:[ ! -f "$A/phases/p1/RELAY.md" ] && pass "dirty + --require-clean does not seed the phase" || fail "phase seeded despite --require-clean on dirty tree"
./test/marathon-drive.sh:725:[ ! -f "$A/phases/p1/RELAY.md" ] && pass "GH-238: missing default gate never renders turn 1 relay" \
./test/marathon-drive.sh:743:[ ! -f "$A/phases/p1/RELAY.md" ] && pass "GH-117: missing builder — relay file never rendered" \
./test/marathon-drive.sh:757:[ ! -f "$A/phases/p1/RELAY.md" ] && pass "GH-117: missing reviewer — relay file never rendered" \
./test/marathon-drive.sh:819:printf '\n### Round 1 · Builder · %s (stub)\nVERDICT: FAIL\nBasis: test builder\n' "$RELAY_AGENT" >> "$PWD/phases/p1/RELAY.md"
./test/marathon-drive.sh:832:printf '\n### Round 2 · Reviewer · %s (stub)\n**Verdict:** Changes requested\nBasis: test reviewer\n' "$RELAY_AGENT" >> "$PWD/phases/p1/RELAY.md"
./test/marathon-drive.sh:917:printf '\n### Round 1 · Builder · %s (stub)\nImplemented: test builder update\n' "$RELAY_AGENT" >> "$PWD/phases/p1/RELAY.md"
./test/marathon-drive.sh:930:sed -i.bak 's/^STATUS:[[:space:]]*.*/STATUS: Approved/' "$PWD/phases/p1/RELAY.md"; rm -f "$PWD/phases/p1/RELAY.md.bak"
./test/marathon-drive.sh:931:printf '\n### Round 2 · Reviewer · %s (stub)\n**Verdict:** Approved\nBasis: test reviewer\n' "$RELAY_AGENT" >> "$PWD/phases/p1/RELAY.md"
./test/marathon-drive.sh:1024:grep -q "TAKE YOUR TURN.*codex.*BUILDER" "$A/phases/p1/RELAY.md" 2>/dev/null \
./test/sentinel-driver-hooks.sh:36:xyz_debug_log_append error "marathon.escalation" "$(printf 'no-progress\t"x" \\y')" "phases/p1/RELAY.md" "promote"
./test/sentinel-driver-hooks.sh:42:assert row["file"] == "phases/p1/RELAY.md" and row["action"] == "promote", row
./relay-automation/marathon.sh:167:PHASES_DIR="${PHASES_DIR:-"$ROOT/phases"}"
./relay-system/2026-07-16/marathon-gh154-marathon-plan-parity-225134.md:70:   - /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick claim MARATHON-GH154-MARATHON-PLAN-PARITY-TURN --agent codex --paths "phases/gh208-154-149-198-issue-sweep--gh154-marathon-plan-parity/RELAY.md,utils/marathon-plan.sh,utils/py/_marathon_plan_node.js,test/marathon-plan.sh"
./relay-system/2026-07-16/marathon-gh149-require-clean-selftrip-225633.md:68:   - /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick claim MARATHON-GH149-REQUIRE-CLEAN-SELFTRIP-TURN --agent codex --paths "phases/gh208-154-149-198-issue-sweep--gh149-require-clean-selftrip/RELAY.md,relay-automation/marathon-drive.sh,test/marathon-drive.sh"
./relay-system/2026-07-16/marathon-gh172-cutover-doc-205632.md:81:   - /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick claim MARATHON-GH172-CUTOVER-DOC-TURN --agent codex --paths "phases/gh172-root-audit--gh172-cutover-doc/RELAY.md,PROJECT/2-WORKING/GH-172-VENDORED-ROOT-AUDIT.md,PROJECT/2-WORKING/MARATHON-2026-07-16-GH172-ROOT-AUDIT/GH-172-CUTOVER-RECOMMENDATION.md"
./relay-system/2026-07-29/gh336-planning-context-review.md:367:  files/phases/ESCALATION.md, never the plan doc's fire section. So an end-appended advisory section
./relay-system/2026-07-16/marathon-gh172-vendored-e2e-205118.md:72:   - /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick claim MARATHON-GH172-VENDORED-E2E-TURN --agent codex --paths "phases/gh172-root-audit--gh172-vendored-e2e/RELAY.md,test/marathon-drive.sh"
./relay-system/2026-07-16/marathon-gh172-bash-audit-203621.md:103:   - /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick claim MARATHON-GH172-BASH-AUDIT-TURN --agent codex --paths "phases/gh172-root-audit--gh172-bash-audit/RELAY.md,relay-automation/marathon-drive.sh,relay-automation/relay-drive.sh,relay-automation/marathon-agent.sh,relay-automation/relay-turn-lib.sh,relay-automation/aider-turn.sh,relay-automation/consult.sh,relay-automation/relay-loop.sh,relay-automation/watchdog.sh,relay-automation/runner.sh,utils/swarm-preflight.sh,PROJECT/2-WORKING/MARATHON-2026-07-16-GH172-ROOT-AUDIT/GH-172-BASH-AUDIT-FINDINGS.md"
./relay-system/2026-06-27/pr77-codex-review.md:79:+/phases/
./relay-system/2026-07-16/marathon-gh198-relay-drive-artifact-preflight-230222.md:75:   - /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick claim MARATHON-GH198-RELAY-DRIVE-ARTIFACT-PREFLIGHT-TURN --agent codex --paths "phases/gh208-154-149-198-issue-sweep--gh198-relay-drive-artifact-preflight/RELAY.md,relay-automation/relay-drive.sh,test/relay-artifact-file.sh"
./relay-system/2026-07-20/gh255-branch.diff:394:     phases_dir = args.phases_dir or os.path.join(root, "phases")
./relay-system/2026-07-16/marathon-gh172-python-audit-204459.md:94:   - /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick claim MARATHON-GH172-PYTHON-AUDIT-TURN --agent codex --paths "phases/gh172-root-audit--gh172-python-audit/RELAY.md,utils/py/marathon_drive.py,utils/py/relay_drive.py,utils/py/rtl.py,utils/py/aider-turn.py,utils/py/consult.py,PROJECT/2-WORKING/MARATHON-2026-07-16-GH172-ROOT-AUDIT/GH-172-PYTHON-AUDIT-FINDINGS.md"
./test/gh438-removal-is-progress.sh:58:TICK_REPO_ROOT="$A" "$TICK" claim "\$task" --agent agy --paths "phases/p1/RELAY.md" >/dev/null 2>&1 || true
./relay-system/2026-07-16/marathon-gh203-094142.md:77:   - /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick claim MARATHON-GH203-TURN --agent codex --paths "phases/gh213-209-203-gh203only--gh203/RELAY.md,utils/swarm-preflight.sh,test/swarm-preflight.sh,relay-automation/README.md"
./relay-system/2026-06-27/p51-design-080020/p51-design.codex.md:43:./phases/gh27/RELAY.md
./relay-system/2026-06-27/p51-design-080020/p51-design.codex.md:44:./phases/p1/ESCALATION.md
./relay-system/2026-06-27/p51-design-080020/p51-design.codex.md:45:./phases/p1/RELAY.md
./CHANGELOG.md:902:- **Verified**: `test/xyz-vendor.sh` extended (marathon runtime vendored + parses) → **29 assertions**, `validate.sh` **70/70** (marathon-drive 38/38 unchanged). Vendored-marathon smoke: the vendored `marathon-drive --dry-run` (ROOT deriving to `.xyz/`, no `.git/`) acquired its lock, rendered the phase relay file, and seeded the tick token. **Watch item for the first real run**: marathon-drive renders the phase relay thread *inside* `.xyz/phases/` (gitignored) — a real multi-round marathon will exercise the worktree-isolation-vs-gitignored-relay path the dry-run doesn't, and may need a thread-location/isolation tweak (to be surfaced + fixed at run time, as the #49 relay dogfood surfaced its two bugs).
./relay-system/2026-07-16/marathon-gh208-worktree-isolation-race-224149.md:69:   - /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick claim MARATHON-GH208-WORKTREE-ISOLATION-RACE-TURN --agent codex --paths "phases/gh208-154-149-198-issue-sweep--gh208-worktree-isolation-race/RELAY.md,relay-automation/relay-turn-lib.sh,test/worktree-isolation.sh"
./relay-system/2026-07-27/marathon-gh294-preflight-isolation-043145.md:62:   - /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick claim MARATHON-GH294-PREFLIGHT-ISOLATION-TURN --agent codex --paths "phases/vendored-lane-hardening-2026-07-26--gh294-preflight-isolation/RELAY.md,utils/swarm-preflight.sh,utils/py/swarm_preflight.py,test/swarm-preflight.sh"
./relay-system/2026-07-28/marathon-gh311-validate-pdda-contract-160624.md:85:   - /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick claim MARATHON-GH311-VALIDATE-PDDA-CONTRACT-TURN --agent codex --paths "phases/gate-and-fleet-integrity-2026-07-27--gh311-validate-pdda-contract/RELAY.md,validate.sh,test/pdda-repo-contract.sh"
./relay-system/2026-07-27/marathon-gh274-done-token-clobber-043847.md:57:   - /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick claim MARATHON-GH274-DONE-TOKEN-CLOBBER-TURN --agent codex --paths "phases/vendored-lane-hardening-2026-07-26--gh274-done-token-clobber/RELAY.md,relay-automation/marathon-drive.sh,utils/py/marathon_drive.py,test/marathon-drive.sh"
./relay-system/2026-07-28/marathon-gh289-target-root-build-turn-161115.md:95:   - /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick claim MARATHON-GH289-TARGET-ROOT-BUILD-TURN-TURN --agent codex --paths "phases/gate-and-fleet-integrity-2026-07-27--gh289-target-root-build-turn/RELAY.md,relay-automation/relay-drive.sh,relay-automation/relay-turn-lib.sh,test/gh289-target-root-build-turn.sh,validate.sh"
./relay-system/2026-07-28/marathon-p1-023826.md:62:   - /Users/noelsaw/Documents/GitHub-Repos/xyz-3-agents-swarm/bin/tick claim MARATHON-P1-TURN --agent codex --paths "phases/p1/RELAY.md,relay-automation/marathon-drive.sh,utils/py/marathon_drive.py,relay-automation/aider-turn.sh,utils/py/aider-turn.py,test/marathon-drive.sh,test/aider-turn.sh,test/debug-mantra.sh,test/driver-lock.sh,test/lane-attempt-cap.sh,test/marathon-root-audit.sh,test/marathon.sh,test/relay-xyz-skill-guard.sh,test/sentinel-driver-hooks.sh,test/test_python_layer.py,test/xyz-harness-hooks.sh,test/_setup.sh"
./relay-system/2026-07-28/marathon-gh308-freeze-bash-twins-162246.md:98:   - /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick claim MARATHON-GH308-FREEZE-BASH-TWINS-TURN --agent codex --paths "phases/gate-and-fleet-integrity-2026-07-27--gh308-freeze-bash-twins/RELAY.md,relay-automation/agy-turn.sh,relay-automation/aider-turn.sh,relay-automation/claude-turn.sh,relay-automation/codex-turn.sh,relay-automation/pi-turn.sh,relay-automation/poll.sh,relay-automation/relay-loop.sh,relay-automation/relay-drive.sh,relay-automation/consult.sh,relay-automation/marathon-drive.sh,utils/swarm-preflight.sh,AGENTS.md,UPGRADE.md,test/gh308-frozen-twin-guard.sh,validate.sh"
./relay-system/2026-07-28/marathon-p1-030215.md:62:   - /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick claim MARATHON-GH284-P1-20260728 --agent codex --paths "phases/p1/RELAY.md,relay-automation/marathon-closeout.sh,relay-automation/marathon.sh,test/marathon-closeout.sh"
./relay-system/2026-07-27/marathon-gh274-done-token-clobber-035715.md:57:   - /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick claim MARATHON-GH274-DONE-TOKEN-CLOBBER-TURN --agent codex --paths "phases/vendored-lane-hardening-2026-07-26--gh274-done-token-clobber/RELAY.md,relay-automation/marathon-drive.sh,utils/py/marathon_drive.py,test/marathon-drive.sh"
./relay-system/2026-07-27/marathon-gh294-preflight-isolation-034452.md:62:   - /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick claim MARATHON-GH294-PREFLIGHT-ISOLATION-TURN --agent codex --paths "phases/vendored-lane-hardening-2026-07-26--gh294-preflight-isolation/RELAY.md,utils/swarm-preflight.sh,utils/py/swarm_preflight.py,test/swarm-preflight.sh"
./relay-system/2026-07-27/marathon-gh292-worktree-discovery-044600.md:67:   - /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick claim MARATHON-GH292-WORKTREE-DISCOVERY-TURN --agent codex --paths "phases/vendored-lane-hardening-2026-07-26--gh292-worktree-discovery/RELAY.md,skills/relay-xyz/find-harness.sh,test/gh292-worktree-vendored-discovery.sh,validate.sh"
./relay-system/2026-07-28/marathon-gh293-vendored-guard-drift-161822.md:87:   - /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick claim MARATHON-GH293-VENDORED-GUARD-DRIFT-TURN --agent codex --paths "phases/gate-and-fleet-integrity-2026-07-27--gh293-vendored-guard-drift/RELAY.md,relay-automation/xyz-sync.sh,relay-automation/xyz-vendor.sh,test/gh293-vendored-guard-drift.sh,validate.sh"
./relay-system/2026-06-29/marathon-gh37f-164158.md:70:   - /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick claim MARATHON-GH37F-TURN --agent codex --paths "phases/gh37f/RELAY.md,relay-automation/consult.sh,relay-automation/agy-turn.sh,test/agy-turn.sh,test/shim-worktree.sh"
./relay-automation/marathon-drive.sh:40:#     [--phases-dir <DIR>]       where to create phases/<id>/ (default: <repo-root>/phases)
./relay-automation/marathon-drive.sh:603:  --phases-dir DIR        Where to create phases/<id>/ (default: <repo-root>/phases).
./relay-automation/marathon-drive.sh:633:PHASES_DIR=""        # resolved to default after ROOT is set
./relay-automation/marathon-drive.sh:654:    --phases-dir)      PHASES_DIR="${2:-}"; shift 2 ;;
./relay-automation/marathon-drive.sh:679:PHASES_DIR="${PHASES_DIR:-"$ROOT/phases"}"
./relay-automation/marathon-drive.sh:833:PHASE_DIR="$PHASES_DIR/$LANE_STATE_KEY"
./test/gh438-removal-is-progress.sh:69:  python3 "$DRIVER" --phases-dir "$A/phases" --phase-brief "$BRIEF" --reviewer agy --builder claude \
./relay-system/2026-07-03/gh102-qa-082014/gh102-qa.codex.md:1736:    52	PLAN=""; BUILDER="claude"; PHASES_DIR=""; PRE_ADVANCE_CMD=""; DRY_RUN=0; FORCE=0
./relay-system/2026-07-03/gh102-qa-082014/gh102-qa.codex.md:1741:    57	    --phases-dir)      PHASES_DIR="${2:-}"; shift 2 ;;
./relay-system/2026-07-03/gh102-qa-082014/gh102-qa.codex.md:1745:    61	    --help)            printf 'Usage: marathon.sh --plan MARATHON.yaml [--builder A] [--phases-dir D] [--pre-advance-cmd C] [--dry-run] [--force]\n'; exit 0 ;;
./relay-system/2026-07-03/gh102-qa-082014/gh102-qa.codex.md:1751:    67	PHASES_DIR="${PHASES_DIR:-"$ROOT/phases"}"
./relay-system/2026-07-03/gh102-qa-082014/gh102-qa.codex.md:1776:    92	               --phase-brief "$brief_path" --round-cap "$cap" --phases-dir "$PHASES_DIR" )
./test/gh284-runlog-heartbeat.sh:92:    PATH="$NODE_ONLY:/usr/bin:/bin" bash "$DRIVER" --phases-dir "$A/phases" --phase-brief "$BRIEF" \
./test/gh284-runlog-heartbeat.sh:173:    PATH="$GH_STUB_DIR:$NODE_ONLY:/usr/bin:/bin" bash "$DRIVER" --phases-dir "$A/phases" \
./test/gh390-gate-guard.sh:98:    --phases-dir "$ROOT/phases" \
./test/gh390-gate-guard.sh:106:  sed -n 's/^reason: //p' "$ROOT/phases/$1/ESCALATION.md" 2>/dev/null
./test/gh401-dry-run-no-mutation.sh:6:# so a dry run mutated the working tree. Unscoped (no MARATHON_ROOT, no --phases-dir) that landed on
./test/debug-mantra.sh:30:    --phases-dir "$A/phases" \
./test/gh438-acceptance-recheck.sh:91:  python3 "$DRIVER" --phases-dir "$A/phases" --phase-brief "$b" --reviewer agy --builder claude \
./test/gh457-gate-tiers.sh:119:    --phases-dir "$ROOT/phases" \
./test/gh457-gate-tiers.sh:125:esc_reason() { sed -n 's/^reason: //p' "$ROOT/phases/$1/ESCALATION.md" 2>/dev/null; }
./relay-system/2026-06-17/phase4-qa-220946/phase4-qa.codex.md:249:    17	#     [--phases-dir <DIR>]       where to create phases/<id>/ (default: <repo-root>/phases)
./relay-system/2026-06-17/phase4-qa-220946/phase4-qa.codex.md:286:    54	  --phases-dir DIR        Where to create phases/<id>/ (default: <repo-root>/phases).
./relay-system/2026-06-17/phase4-qa-220946/phase4-qa.codex.md:301:    69	PHASES_DIR=""        # resolved to default after ROOT is set
./relay-system/2026-06-17/phase4-qa-220946/phase4-qa.codex.md:315:    83	    --phases-dir)      PHASES_DIR="${2:-}"; shift 2 ;;
./relay-system/2026-06-17/phase4-qa-220946/phase4-qa.codex.md:332:   100	PHASES_DIR="${PHASES_DIR:-"$ROOT/phases"}"
./relay-system/2026-06-17/phase4-qa-220946/phase4-qa.codex.md:356:   124	PHASE_DIR="$PHASES_DIR/$PHASE_ID"
./relay-system/2026-06-17/phase4-qa-220946/phase4-qa.codex.md:566:    15	#   relay-automation/marathon.sh --plan MARATHON.yaml [--builder claude] [--phases-dir DIR]
./relay-system/2026-06-17/phase4-qa-220946/phase4-qa.codex.md:590:    39	PLAN=""; BUILDER="claude"; PHASES_DIR=""; PRE_ADVANCE_CMD=""; DRY_RUN=0
./relay-system/2026-06-17/phase4-qa-220946/phase4-qa.codex.md:595:    44	    --phases-dir)      PHASES_DIR="${2:-}"; shift 2 ;;
./relay-system/2026-06-17/phase4-qa-220946/phase4-qa.codex.md:598:    47	    --help)            printf 'Usage: marathon.sh --plan MARATHON.yaml [--builder A] [--phases-dir D] [--pre-advance-cmd C] [--dry-run]\n'; exit 0 ;;
./relay-system/2026-06-17/phase4-qa-220946/phase4-qa.codex.md:604:    53	PHASES_DIR="${PHASES_DIR:-"$ROOT/phases"}"
./relay-system/2026-06-17/phase4-qa-220946/phase4-qa.codex.md:629:    78	               --phase-brief "$brief_path" --round-cap "$cap" --phases-dir "$PHASES_DIR" )
./relay-system/2026-06-17/phase4-qa-220946/phase4-qa.codex.md:2263:    36	    --phases-dir "$A/phases" \
./relay-system/2026-06-17/phase4-qa-220946/phase4-qa.codex.md:2428:   201	  bash "$DRIVER" --phases-dir "$A/phases" --phase-brief "$BRIEF" \
./relay-system/2026-06-17/phase4-qa-220946/phase4-qa.codex.md:2456:   229	  bash "$DRIVER" --phases-dir "$A/phases" --phase-brief "$BRIEF" \
./relay-system/2026-06-17/phase4-qa-220946/phase4-qa.codex.md:2467:   240	  bash "$DRIVER" --phases-dir "$A/phases" --phase-brief "$BRIEF" \
./relay-automation/marathon.sh:15:#   relay-automation/marathon.sh --plan MARATHON.yaml [--builder codex] [--phases-dir DIR]
./relay-automation/marathon.sh:84:Usage: marathon.sh --plan MARATHON.yaml [--builder A] [--phases-dir D] [--pre-advance-cmd C]
./relay-automation/marathon.sh:94:  --phases-dir DIR        Where to create phases/<id>/ (default: <repo-root>/phases).
./relay-automation/marathon.sh:111:PLAN=""; BUILDER="codex"; PHASES_DIR=""; PRE_ADVANCE_CMD=""; DRY_RUN=0; FORCE=0; RETRY_PHASE=""; CLOSEOUT_PR=0
./relay-automation/marathon.sh:117:    --phases-dir)      PHASES_DIR="${2:-}"; shift 2 ;;
./relay-automation/marathon.sh:167:PHASES_DIR="${PHASES_DIR:-"$ROOT/phases"}"
./relay-automation/marathon.sh:200:               --phase-brief "$brief_path" --round-cap "$cap" --phases-dir "$PHASES_DIR" )
./relay-automation/marathon-detail.sh:40:PHASES_DIR="$REPO/phases"
./relay-automation/marathon-detail.sh:42:if [ -d "$PHASES_DIR" ]; then
./relay-automation/marathon-detail.sh:44:  RELAY_FILE="$(ls -t "$PHASES_DIR"/*/RELAY.md 2>/dev/null | head -1 || true)"
./test/xyz-harness-hooks.sh:170:    bash "$MARATHON_DRIVE" --phases-dir "$A/phases" --phase-brief "$BRIEF" \
./test/xyz-harness-hooks.sh:262:    bash "$MARATHON_DRIVE" --phases-dir "$A/phases" --phase-brief "$BRIEF" \
./relay-system/2026-07-03/gh30-phase2-151736/gh30-phase2.codex.md:359:    17	#     [--phases-dir <DIR>]       where to create phases/<id>/ (default: <repo-root>/phases)
./relay-system/2026-07-03/gh30-phase2-151736/gh30-phase2.codex.md:494:   152	  --phases-dir DIR        Where to create phases/<id>/ (default: <repo-root>/phases).
./relay-system/2026-07-03/gh30-phase2-151736/gh30-phase2.codex.md:513:   171	PHASES_DIR=""        # resolved to default after ROOT is set
./relay-system/2026-07-03/gh30-phase2-151736/gh30-phase2.codex.md:530:   188	    --phases-dir)      PHASES_DIR="${2:-}"; shift 2 ;;
./relay-system/2026-07-03/gh30-phase2-151736/gh30-phase2.codex.md:553:   211	PHASES_DIR="${PHASES_DIR:-"$ROOT/phases"}"
./relay-system/2026-07-03/gh30-phase2-151736/gh30-phase2.codex.md:590:   248	PHASE_DIR="$PHASES_DIR/$PHASE_ID"
./test/gh322-runlog-python-lane.sh:101:    PATH="${GH_ON_PATH:-}$NODE_ONLY:/usr/bin:/bin" bash "$DRIVER" --phases-dir "$A/phases" \
./test/gh319-gate-path-with-space.sh:93:    --phases-dir "$ROOT/phases" \
./test/gh331-cost-summary.sh:161:    bash "$MDRIVE" --phases-dir "$A/phases" --phase-brief "$BRIEF" --phase-id "$pid" \
./CHANGELOG.md:780:- **Should — swarm/bare-marathon records carried a constant `sessionId:"p1"`** (the default `PHASE_ID`; swarm-preflight's generated invocation passed no `--phase-id`), making the field useless for telling swarm runs apart. Fixed telemetry-only (no change to phases-dir / tick-task naming): `marathon-drive` honors an optional `XYZ_SESSION_ID` override, and `swarm-preflight`'s generated command self-propagates the per-run slug via `XYZ_SESSION_ID=<slug>`. Tests M7 + the swarm-preflight invocation assertion.
./test/gh385-retry-token-satisfied.sh:63:  python3 "$DRIVER" --phases-dir "$A/phases" --phase-brief "$BRIEF" \
./test/marathon.sh:253:    --phases-dir)  phases_dir="\$2"; shift 2 ;;
./utils/py/marathon_drive.py:383:    parser.add_argument("--phases-dir", dest="phases_dir")
./utils/py/marathon_drive.py:687:    phases_dir = args.phases_dir or os.path.join(root, "phases")
./utils/py/marathon_drive.py:1678:    # in whatever repo it resolved to — the harness itself when no MARATHON_ROOT/--phases-dir was
./test/gh407-gate-ran-attribution.sh:75:    --phases-dir "$ROOT/phases" \
./test/gh407-gate-ran-attribution.sh:81:esc_field() { sed -n "s/^$2: //p" "$ROOT/phases/$1/ESCALATION.md" 2>/dev/null; }
./test/gh407-gate-ran-attribution.sh:175:  bash "$PRE_DRIVER" --phases-dir "$PRE_ROOT/phases" --phase-brief "$BRIEF" \
./test/marathon-drive.sh:57:    --phases-dir "$A/phases" \
./test/marathon-drive.sh:380:  bash "$DRIVER" --phases-dir "$A/phases" --phase-brief "$BRIEF" \
./test/marathon-drive.sh:409:  bash "$DRIVER" --phases-dir "$A/phases" --phase-brief "$BRIEF" \
./test/marathon-drive.sh:422:  bash "$DRIVER" --phases-dir "$A/phases" --phase-brief "$BRIEF" \
./test/marathon-drive.sh:502:  bash "$DRIVER" --phases-dir "$A/phases" --phase-brief "$BRIEF" --reviewer agy --artifact src/satisfied.js \
./test/marathon-drive.sh:536:  bash "$DRIVER" --phases-dir "$A/phases" --phase-brief "$BRIEF" --reviewer agy --artifact src/stalled.js \
./test/marathon-drive.sh:570:  bash "$DRIVER" --phases-dir "$A/phases" --phase-brief "$BRIEF" --reviewer agy --artifact src/zero-artifact.js \
./test/marathon-drive.sh:586:  bash "$DRIVER" --phases-dir "$A/phases" --phase-brief "$BRIEF" --reviewer agy --artifact src/unchanged-artifact.js \
./test/marathon-drive.sh:628:  bash "$DRIVER" --phases-dir "$A/phases" --phase-brief "$BRIEF" --reviewer agy \
./test/marathon-drive.sh:644:  bash "$DRIVER" --phases-dir "$A/phases" --phase-brief "$BRIEF" --reviewer agy \
./test/marathon-drive.sh:680:    --phases-dir "$WT/phases" \
./test/marathon-drive.sh:716:  bash "$DRIVER" --phases-dir "$A/phases" --phase-brief "$BRIEF" --reviewer agy --builder claude 2>&1)"; rc=$?
./test/marathon-drive.sh:1020:  bash "$DRIVER" --phases-dir "$A/phases" --phase-brief "$BRIEF" --reviewer agy \
./relay-system/2026-07-02/gh45-review-183600/gh45-review.codex.md:366: #     [--phases-dir <DIR>]       where to create phases/<id>/ (default: <repo-root>/phases)
./relay-system/2026-07-02/gh45-review-183600/gh45-review.codex.md:482:   --phases-dir DIR        Where to create phases/<id>/ (default: <repo-root>/phases).
./relay-system/2026-07-02/gh45-review-183600/gh45-review.codex.md:500: PHASES_DIR=""        # resolved to default after ROOT is set
./relay-system/2026-07-02/gh45-review-183600/gh45-review.codex.md:517:     --phases-dir)      PHASES_DIR="${2:-}"; shift 2 ;;
./relay-system/2026-07-02/gh45-review-183600/gh45-review.codex.md:540: PHASES_DIR="${PHASES_DIR:-"$ROOT/phases"}"
./relay-system/2026-07-02/gh45-review-183600/gh45-review.codex.md:576: PHASE_DIR="$PHASES_DIR/$PHASE_ID"
./relay-system/2026-07-02/gh45-review-183600/gh45-review.codex.md:1594:    17	#     [--phases-dir <DIR>]       where to create phases/<id>/ (default: <repo-root>/phases)
./relay-system/2026-07-02/gh45-review-183600/gh45-review.codex.md:1710:   133	  --phases-dir DIR        Where to create phases/<id>/ (default: <repo-root>/phases).
./relay-system/2026-07-02/gh45-review-183600/gh45-review.codex.md:1728:   151	PHASES_DIR=""        # resolved to default after ROOT is set
./relay-system/2026-07-02/gh45-review-183600/gh45-review.codex.md:1745:   168	    --phases-dir)      PHASES_DIR="${2:-}"; shift 2 ;;
./relay-system/2026-07-02/gh45-review-183600/gh45-review.codex.md:1768:   191	PHASES_DIR="${PHASES_DIR:-"$ROOT/phases"}"
./relay-system/2026-07-02/gh45-review-183600/gh45-review.codex.md:1804:   227	PHASE_DIR="$PHASES_DIR/$PHASE_ID"
./relay-system/2026-07-02/gh45-review-183600/gh45-review.codex.md:2076:    15	#   relay-automation/marathon.sh --plan MARATHON.yaml [--builder claude] [--phases-dir DIR]
./relay-system/2026-07-02/gh45-review-183600/gh45-review.codex.md:2113:    52	PLAN=""; BUILDER="claude"; PHASES_DIR=""; PRE_ADVANCE_CMD=""; DRY_RUN=0
./relay-system/2026-07-02/gh45-review-183600/gh45-review.codex.md:2118:    57	    --phases-dir)      PHASES_DIR="${2:-}"; shift 2 ;;
./relay-system/2026-07-02/gh45-review-183600/gh45-review.codex.md:2121:    60	    --help)            printf 'Usage: marathon.sh --plan MARATHON.yaml [--builder A] [--phases-dir D] [--pre-advance-cmd C] [--dry-run]\n'; exit 0 ;;
./relay-system/2026-07-02/gh45-review-183600/gh45-review.codex.md:2127:    66	PHASES_DIR="${PHASES_DIR:-"$ROOT/phases"}"
./relay-system/2026-07-02/gh45-review-183600/gh45-review.codex.md:2152:    91	               --phase-brief "$brief_path" --round-cap "$cap" --phases-dir "$PHASES_DIR" )
./relay-system/2026-07-02/gh45-review-183600/gh45-review.codex.md:2257:relay-automation/marathon.sh:60:    --help)            printf 'Usage: marathon.sh --plan MARATHON.yaml [--builder A] [--phases-dir D] [--pre-advance-cmd C] [--dry-run]\n'; exit 0 ;;
./relay-system/2026-07-02/gh45-review-183600/gh45-review.codex.md:2537: PHASES_DIR=""        # resolved to default after ROOT is set
./PROJECT/1-INBOX/GH-484-MARATHONS-DEFAULT.md:9:  `$ROOT/phases` to `$ROOT/MARATHONS`, for every new install (vendored or not), while the
./PROJECT/1-INBOX/GH-484-MARATHONS-DEFAULT.md:10:  existing `--phases-dir` / `PHASES_DIR` override keeps working exactly as it does today.
./PROJECT/1-INBOX/GH-484-MARATHONS-DEFAULT.md:26:  **already** take `--phases-dir` / `PHASES_DIR`, both defaulting to `$ROOT/phases`. The override
./PROJECT/1-INBOX/GH-484-MARATHONS-DEFAULT.md:49:  anyone who passes a non-default `--phases-dir`: their phase output would not match this check.
./PROJECT/1-INBOX/GH-484-MARATHONS-DEFAULT.md:52:  pairing, same fix shape (read `$PHASES_DIR`, not a literal).
./PROJECT/1-INBOX/GH-484-MARATHONS-DEFAULT.md:85:  `--phases-dir`/`PHASES_DIR` (phase-output dir) already fully cover this; adding a third knob would
./PROJECT/1-INBOX/GH-484-MARATHONS-DEFAULT.md:99:3. Tests that already pass an explicit `--phases-dir` fixture path → unaffected, recorded as such.
./PROJECT/1-INBOX/GH-484-MARATHONS-DEFAULT.md:109:- `utils/py/marathon_drive.py`: change the `--phases-dir` default from `os.path.join(root,
./PROJECT/1-INBOX/GH-484-MARATHONS-DEFAULT.md:112:- `relay-automation/marathon-drive.sh`: same two changes — `PHASES_DIR="${PHASES_DIR:-"$ROOT/
./PROJECT/1-INBOX/GH-484-MARATHONS-DEFAULT.md:113:  MARATHONS"}"`, and the `:961` awk pattern reads `$PHASES_DIR`'s basename rather than a literal.
./PROJECT/1-INBOX/GH-484-MARATHONS-DEFAULT.md:120:- New/extended regression test proving twin parity: a fresh run with no `--phases-dir` writes under
./PROJECT/1-INBOX/GH-484-MARATHONS-DEFAULT.md:121:  `MARATHONS/` in both twins; `--phases-dir <custom>` still overrides in both; the two
./PROJECT/1-INBOX/GH-484-MARATHONS-DEFAULT.md:122:  containment-literal fixes correctly recognize a non-default `--phases-dir` value (this is the
./PROJECT/1-INBOX/GH-484-MARATHONS-DEFAULT.md:131:  to describe `MARATHONS/` as the default, `--phases-dir` as the override.
./PROJECT/1-INBOX/GH-484-MARATHONS-DEFAULT.md:138:1. A fresh same-repo marathon run (no `--phases-dir` passed) writes to `MARATHONS/`, not the old
./PROJECT/1-INBOX/GH-484-MARATHONS-DEFAULT.md:140:2. `--phases-dir <custom>` still overrides the default exactly as today, in both twins.
./PROJECT/1-INBOX/GH-484-MARATHONS-DEFAULT.md:142:   string — verified with a fixture that passes a non-default `--phases-dir` and confirms the
./relay-system/2026-07-27/gh-284-phase-2-qa-driver-heartbeat-log-github-run-log.md:446:+    PATH="$NODE_ONLY:/usr/bin:/bin" bash "$DRIVER" --phases-dir "$A/phases" --phase-brief "$BRIEF" \
./PROJECT/1-INBOX/GH-439-SAME-REPO-WORKTREE-SPLIT.md:80:`:207,211` from `git -C "$PWD" rev-parse --show-toplevel` (`:54-58`), passes `--phases-dir`, and
./PROJECT/3-COMPLETED/GH-116-MARATHON-RETRY-FLAG.md:62:1. Accept the flag alongside the existing `--plan`/`--phases-dir`/`--builder`/`--pre-advance-cmd`

2026-08-10T04:58:53.270717Z ERROR codex_models_manager::manager: failed to renew cache TTL: missing field `base_instructions` at line 95 column 5
exec
/bin/zsh -lc "nl -ba relay-automation/marathon.sh | sed -n '1,215p'
nl -ba relay-automation/marathon-ls.sh | sed -n '1,145p'
nl -ba relay-automation/marathon-detail.sh | sed -n '1,75p'
rg -n -i 'phases|PHASES_DIR|MARATHON_ROOT|marathon-drive' utils/py/swarm_preflight.py utils/swarm-preflight.sh relay-automation/poll.sh relay-automation/relay-turn-lib.sh relay-automation/xyz-vendor.sh
rg -n --glob '"'!temp/**'"' --glob '"'!PROJECT/**'"' --glob '"'!relay-system/**'"' --glob '"'!phases/**'"' --glob '"'!test/**'"' '(ROOT/phases|repo/phases|REPO/phases|/phases/|\"phases\"|\\x27phases\\x27)' relay-automation utils .gitignore README.md ARCHITECTURE.md" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-67768-b0m00j9w
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
    15	#   relay-automation/marathon.sh --plan MARATHON.yaml [--builder codex] [--phases-dir DIR]
    16	#                                [--pre-advance-cmd CMD] [--dry-run] [--retry PHASE-ID]
    17	#
    18	# GH-212: default builder is `codex` — no per-call API charge (bills via the Codex/ChatGPT
    19	# subscription; agy is the other cost-blind option). `--builder claude` spawns a headless Claude
    20	# Code CLI subprocess instead: a SEPARATE, PER-CALL API-BILLED turn-taker, distinct from an
    21	# interactive session. Use it only as an explicit, cost-acknowledged choice.
    22	#
    23	# GH-212: a plan's `--plan` YAML (+ its phase briefs) must resolve under PROJECT/2-WORKING/ in the
    24	# target repo — not a standalone top-level folder (e.g. marathon-plans/<slug>/) an agent might
    25	# pattern-match from a prior repo. Exempt: paths under this harness's own home (MARATHON_HOME —
    26	# covers shipped examples like MARATHON.example.yaml). Override: MARATHON_ALLOW_PLAN_OUTSIDE_WORKING=1.
    27	#
    28	# GH-116: --retry <phase-id> recovers a phase whose relay task was left open/never-claimed
    29	# (permanently spent, per this repo's claim-then-abandon constraint) WITHOUT manually renaming the
    30	# phase id in MARATHON.yaml. It overrides just that one phase's --relay-task with the first unused
    31	# MARATHON-<ID>-TURN-<N> suffix (N starts at 2, checked via `tick info`) — every other phase derives
    32	# its task name exactly as before. marathon-drive.sh already supports --relay-task natively; this is
    33	# purely a marathon.sh-side task-name override, no change to marathon-drive.sh itself.
    34	#
    35	# The MARATHON.yaml phase fields drive each marathon-drive call: id→--phase-id, reviewer→--reviewer,
    36	# brief→--phase-brief (required to run), artifact→--artifact, turn_timeout_s→RELAY_TURN_TIMEOUT_S,
    37	# max_review_rounds→--round-cap.
    38	#
    39	# Environment overrides (for tests):
    40	#   MARATHON_HOME       — harness home (default: parent of this script's dir)
    41	#   MARATHON_ROOT       — target repo root (default: `git -C "$PWD" rev-parse --show-toplevel`,
    42	#                         falling back to MARATHON_HOME outside a git repo)
    43	#   MARATHON_DRIVE      — marathon-drive.sh path (default: <harness-home>/relay-automation/marathon-drive.sh)
    44	#   MARATHON_YAML_BIN   — bin/marathon-yaml path (default: <harness-home>/bin/marathon-yaml)
    45	#   TICK_BIN            — tick binary (default: <harness-home>/bin/tick)
    46	#   MARATHON_CLOSEOUT_BIN — marathon-closeout.sh path (default: <harness-home>/relay-automation/marathon-closeout.sh)
    47	#   MARATHON_ALLOW_PLAN_OUTSIDE_WORKING — 1 permits a --plan outside PROJECT/2-WORKING/ (GH-212)
    48	# Real runs also inherit the turn-taker env (CLAUDE_BIN, *_TURN_ROOT, …), passed straight through.
    49	#
    50	# Exit: 0 all phases approved · N the failing phase's marathon-drive exit code · 2 usage/parse error.
    51	
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
    94	  --phases-dir DIR        Where to create phases/<id>/ (default: <repo-root>/phases).
    95	  --target-root DIR       Foreign git repo the BUILD lands in; forwarded to marathon-drive.sh (GH-11).
    96	                          The relay thread, tick token, phases/ and relay-system/ transcripts all stay
    97	                          in THIS harness repo — only code changes land in DIR. Use this when the target
    98	                          repo cannot track harness output (e.g. a public repo that gitignores phases/
    99	                          and relay-system/ on purpose): without it, marathon-drive's `git add` of
   100	                          RELAY.md / ESCALATION.md / the transcript fails and the phase HALTs.
   101	                          Plan and brief paths resolve against DIR when set.
   102	  --pre-advance-cmd CMD   Gate before phase.approved (default: bash validate.sh, per phase).
   103	  --dry-run               Render each phase's relay file and print the tick seed; exit without running.
   104	  --force                 GH-45: bypass the per-lane attempt cap for this run.
   105	  --retry PHASE-ID        GH-116: retry one phase with a fresh relay-task suffix.
   106	  --closeout-pr           Open (but never merge) a PR after a successful marathon. Closeout failure is logged
   107	                          and does not change the successful marathon exit code.
   108	EOF
   109	}
   110	
   111	PLAN=""; BUILDER="codex"; PHASES_DIR=""; PRE_ADVANCE_CMD=""; DRY_RUN=0; FORCE=0; RETRY_PHASE=""; CLOSEOUT_PR=0
   112	TARGET_ROOT=""   # GH-11 passthrough: foreign repo the BUILD lands in; relay/transcripts stay in ROOT
   113	while (($# > 0)); do
   114	  case "$1" in
   115	    --plan)            PLAN="${2:-}"; shift 2 ;;
   116	    --builder)         BUILDER="${2:-}"; shift 2 ;;
   117	    --phases-dir)      PHASES_DIR="${2:-}"; shift 2 ;;
   118	    --target-root)     TARGET_ROOT="${2:-}"; shift 2 ;;
   119	    --pre-advance-cmd) PRE_ADVANCE_CMD="${2:-}"; shift 2 ;;
   120	    --dry-run)         DRY_RUN=1; shift ;;
   121	    --force)           FORCE=1; shift ;;   # GH-45: forward to each phase so a parked lane can be re-fired
   122	    --retry)           RETRY_PHASE="${2:-}"; shift 2 ;;   # GH-116: retry one phase with a fresh relay-task suffix
   123	    --closeout-pr)     CLOSEOUT_PR=1; shift ;;
   124	    --help)            usage; exit 0 ;;
   125	    *)                 die "unknown argument: $1" ;;
   126	  esac
   127	done
   128	[[ -n "$PLAN" ]] || { die "--plan MARATHON.yaml required"; }
   129	[[ -f "$PLAN" ]] || die "plan not found: $PLAN"
   130	
   131	# GH-212: plan-location guard. A marathon's plan artifacts (this YAML + its phase briefs) belong
   132	# under PROJECT/2-WORKING/<capture-doc>/, not a standalone top-level folder (e.g. marathon-plans/)
   133	# an agent might pattern-match from a prior repo. Exempt: paths under this harness's own home
   134	# (MARATHON_HOME) — shipped reference examples (e.g. MARATHON.example.yaml), not an agent-authored
   135	# plan for a target repo. Override for a legitimate non-default location:
   136	# MARATHON_ALLOW_PLAN_OUTSIDE_WORKING=1.
   137	_plan_abs="$(cd "$(dirname "$PLAN")" && pwd -P)/$(basename "$PLAN")"
   138	# Canonicalize with `pwd -P` unconditionally (relative AND already-absolute input): ROOT can come
   139	# from `git rev-parse --show-toplevel` (symlink-resolved) or a raw MARATHON_ROOT env override
   140	# (whatever form the caller passed), so either side of this comparison can be a logical (non -P)
   141	# path — canonicalize both or a macOS /var -> /private/var checkout falsely flags every plan.
   142	# symlinks (e.g. macOS /var -> /private/var), so a logical (non -P) comparison here would falsely
   143	# flag every plan as "outside" on such a checkout (same pitfall swarm-preflight.sh works around).
   144	# On a --target-root run the plan lives in the TARGET repo's PROJECT/2-WORKING/, not the harness's,
   145	# so this guard must measure against that repo — otherwise every cross-repo plan falsely "resolves
   146	# outside PROJECT/2-WORKING/" and dies. GH-212's intent is unchanged: the plan must sit under
   147	# PROJECT/2-WORKING/ of whichever repo owns it.
   148	_plan_base="${TARGET_ROOT:-$ROOT}"
   149	_root_canon="$(cd "$_plan_base" 2>/dev/null && pwd -P || printf '%s' "$_plan_base")"
   150	_home_canon="$(cd "$MARATHON_HOME" 2>/dev/null && pwd -P || printf '%s' "$MARATHON_HOME")"
   151	_plan_rel_root="${_plan_abs#"$_root_canon"/}"
   152	case "$_plan_rel_root" in
   153	  PROJECT/2-WORKING/*) ;;   # in the expected home — proceed
   154	  *)
   155	    case "$_plan_abs" in
   156	      "$_home_canon"/*) ;;   # harness-owned reference material — exempt
   157	      *)
   158	        if [[ "${MARATHON_ALLOW_PLAN_OUTSIDE_WORKING:-0}" != "1" ]]; then
   159	          die "plan '$PLAN' resolves outside PROJECT/2-WORKING/ (got: $_plan_rel_root). Marathon plans (MARATHON.yaml + phase briefs) belong under PROJECT/2-WORKING/<capture-doc>/, not a standalone folder — see GUIDING-PRINCIPLES.md Conventions. Override: MARATHON_ALLOW_PLAN_OUTSIDE_WORKING=1."
   160	        fi
   161	        log "MARATHON_ALLOW_PLAN_OUTSIDE_WORKING=1 — proceeding with a plan outside PROJECT/2-WORKING/ ($_plan_rel_root)"
   162	        ;;
   163	    esac
   164	    ;;
   165	esac
   166	
   167	PHASES_DIR="${PHASES_DIR:-"$ROOT/phases"}"
   168	export TICK_REPO_ROOT="$ROOT"
   169	
   170	# Parse + validate + resolve order. A malformed/cyclic plan halts the whole run here (exit 2).
   171	PLAN_TSV="$("$YAML_BIN" "$PLAN")" || die "plan parse failed (see above)"
   172	[[ -n "$PLAN_TSV" ]] || die "plan has no phases"
   173	PLAN_NAME="$(sed -n 's/^name:[[:space:]]*//p' "$PLAN" | head -n1 | sed 's/[[:space:]]*$//')"
   174	phase_count="$(printf '%s\n' "$PLAN_TSV" | grep -c .)"
   175	log "plan: $PLAN — $phase_count phase(s) in execution order"
   176	
   177	idx=0
   178	# Read TSV with a NON-whitespace field separator (US / \037): `IFS=$'\t' read` coalesces consecutive
   179	# tabs (tab is whitespace-class), which would collapse empty columns and shift every field. Translate
   180	# tabs → \037 so empty fields (no rounds / no depends_on / no artifact / no turn_timeout_s) are
   181	# preserved positionally.
   182	while IFS=$'\037' read -r id reviewer rounds depends_on brief artifact turn_timeout_s name; do
   183	  [[ -n "$id" ]] || continue
   184	  idx=$((idx + 1))
   185	  rounds="${rounds:-2}"
   186	  cap=$((2 * rounds + 1))
   187	  lane_ns=""
   188	  [[ -n "$PLAN_NAME" ]] && lane_ns="${PLAN_NAME}--${id}"
   189	  [[ -n "$brief" ]] || die "phase $id: no 'brief:' in the plan — a phase needs a task to run"
   190	  # Briefs live beside the plan, so they resolve against the repo the plan came from. On a
   191	  # --target-root run that is the TARGET repo, not this harness — resolving against $ROOT would
   192	  # look for the target's briefs inside the harness clone and die "brief file not found".
   193	  brief_base="${TARGET_ROOT:-$ROOT}"
   194	  case "$brief" in /*) brief_path="$brief" ;; *) brief_path="$brief_base/$brief" ;; esac
   195	  [[ -f "$brief_path" ]] || die "phase $id: brief file not found: $brief_path"
   196	
   197	  log "── phase $idx/$phase_count: $id (reviewer=$reviewer, round-cap=$cap${artifact:+, artifact=$artifact}${turn_timeout_s:+, turn-timeout=${turn_timeout_s}s}) ──"
   198	
   199	  drive_args=( --phase-id "$id" --reviewer "$reviewer" --builder "$BUILDER"
   200	               --phase-brief "$brief_path" --round-cap "$cap" --phases-dir "$PHASES_DIR" )
   201	  [[ -n "$artifact" ]] && drive_args+=( --artifact "$artifact" )
   202	  [[ -n "$TARGET_ROOT" ]] && drive_args+=( --target-root "$TARGET_ROOT" )
   203	  [[ -n "$PRE_ADVANCE_CMD" ]] && drive_args+=( --pre-advance-cmd "$PRE_ADVANCE_CMD" )
   204	  ((FORCE)) && drive_args+=( --force )   # GH-45: bypass the per-lane attempt cap for this run
   205	  # GH-116: only the phase named by --retry gets a task-name override — every other phase still lets
   206	  # marathon-drive.sh derive its default MARATHON-<ID>-TURN name, unaffected.
   207	  if [[ -n "$RETRY_PHASE" && "$id" == "$RETRY_PHASE" ]]; then
   208	    id_upper="$(printf '%s' "$id" | tr '[:lower:]' '[:upper:]')"
   209	    retry_n=2
   210	    # First unused suffix, not a hardcoded -2: keep bumping while that task name already exists
   211	    # (tick info exits 0 once a task has any recorded state — spent or not, it's not reusable).
   212	    while "$TICK_BIN" info "MARATHON-${id_upper}-TURN-${retry_n}" >/dev/null 2>&1; do
   213	      retry_n=$((retry_n + 1))
   214	    done
   215	    retry_task="MARATHON-${id_upper}-TURN-${retry_n}"
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
    35	# ---------------------------------------------------------------------------
    36	# helpers
    37	# ---------------------------------------------------------------------------
    38	
    39	trim_cr() { printf '%s' "${1%$'\r'}"; }
    40	
    41	# Resolve the relay-driver lock directory for a given repo root.
    42	# Clone: <repo>/.git/relay-driver.lock
    43	# Vendored (.xyz/ with no .git/): <repo>/.relay-driver.lock
    44	lock_path_for_repo() {
    45	  local repo="$1"
    46	  if [ -d "$repo/.git" ]; then
    47	    printf '%s/.git/relay-driver.lock' "$repo"
    48	  else
    49	    printf '%s/.relay-driver.lock' "$repo"
    50	  fi
    51	}
    52	
    53	# Find the newest *marathon*.jsonl file under <repo>/.tick/events/.
    54	newest_marathon_jsonl() {
    55	  local repo="$1"
    56	  local events_dir="$repo/.tick/events"
    57	  [ -d "$events_dir" ] || return 0
    58	  # Use ls -t (newest first) rather than `find -newer` for bash 3.2 compat.
    59	  # Glob for files matching *marathon*.jsonl; pick the first (newest by mtime).
    60	  local f
    61	  # shellcheck disable=SC2012
    62	  f="$(ls -t "$events_dir"/*marathon*.jsonl 2>/dev/null | head -1 || true)"
    63	  printf '%s' "$f"
    64	}
    65	
    66	# Extract the last event line from a jsonl file and return phase type + timestamp.
    67	# Outputs: TYPE<TAB>TIMESTAMP  (or empty strings when not parseable).
    68	last_event_fields() {
    69	  local jsonl="$1"
    70	  [ -f "$jsonl" ] || { printf '\t'; return 0; }
    71	  local last_line type ts
    72	  last_line="$(tail -1 "$jsonl" 2>/dev/null || true)"
    73	  [ -n "$last_line" ] || { printf '\t'; return 0; }
    74	  # Parse with sed: no jq dependency requirement.
    75	  type="$(printf '%s' "$last_line" | sed 's/.*"type"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/' 2>/dev/null || true)"
    76	  ts="$(printf '%s' "$last_line" | sed 's/.*"ts"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/' 2>/dev/null || true)"
    77	  # If sed didn't actually find a match it returns the whole string unchanged; detect that.
    78	  [ "$type" = "$last_line" ] && type=""
    79	  [ "$ts" = "$last_line" ] && ts=""
    80	  printf '%s\t%s' "${type:-}" "${ts:-}"
    81	}
    82	
    83	# Determine the STATE for a repo given its lock dir path.
    84	# Sets globals: _STATE _PID
    85	resolve_state() {
    86	  local lock="$1"
    87	  _STATE="IDLE"
    88	  _PID="-"
    89	
    90	  if [ -d "$lock" ]; then
    91	    local pid_file="$lock/pid"
    92	    local pid=""
    93	    [ -f "$pid_file" ] && pid="$(cat "$pid_file" 2>/dev/null || true)"
    94	    pid="$(trim_cr "${pid:-}")"
    95	    if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
    96	      _STATE="LIVE"
    97	      _PID="$pid"
    98	    else
    99	      _STATE="STALE"
   100	      _PID="${pid:--}"
   101	    fi
   102	    return 0
   103	  fi
   104	
   105	  # No lock — state is IDLE (no lock present).
   106	  _STATE="IDLE"
   107	  _PID="-"
   108	}
   109	
   110	# Find newest phases/*/RELAY.md path for a repo (used in RELAY-FILE column).
   111	newest_relay_file() {
   112	  local repo="$1"
   113	  local phases_dir="$repo/phases"
   114	  [ -d "$phases_dir" ] || { printf '-'; return 0; }
   115	  local f
   116	  # shellcheck disable=SC2012
   117	  f="$(ls -t "$phases_dir"/*/RELAY.md 2>/dev/null | head -1 || true)"
   118	  printf '%s' "${f:--}"
   119	}
   120	
   121	# ---------------------------------------------------------------------------
   122	# print one row per repo
   123	# ---------------------------------------------------------------------------
   124	
   125	print_row() {
   126	  local repo="$1"
   127	  local repo_abs
   128	
   129	  # Canonicalize path (no readlink -f on macOS bash 3.2).
   130	  if [ -d "$repo" ]; then
   131	    repo_abs="$(cd "$repo" && pwd)"
   132	  else
   133	    repo_abs="$repo"
   134	  fi
   135	
   136	  # GONE: repo does not exist on disk.
   137	  if [ ! -d "$repo_abs" ]; then
   138	    printf '%s\tGONE\t-\t-\t-\t-\n' "$repo_abs"
   139	    return 0
   140	  fi
   141	
   142	  local lock
   143	  lock="$(lock_path_for_repo "$repo_abs")"
   144	
   145	  resolve_state "$lock"
     1	#!/usr/bin/env bash
     2	# marathon-detail.sh <repo> — preview for ONE repo path (read-only).
     3	#
     4	# Prints:
     5	#   - STATUS: / NEXT: lines from the newest phases/*/RELAY.md (if any)
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
    39	# Newest phases/*/RELAY.md
    40	PHASES_DIR="$REPO/phases"
    41	RELAY_FILE=""
    42	if [ -d "$PHASES_DIR" ]; then
    43	  # shellcheck disable=SC2012
    44	  RELAY_FILE="$(ls -t "$PHASES_DIR"/*/RELAY.md 2>/dev/null | head -1 || true)"
    45	fi
    46	
    47	if [ -n "$RELAY_FILE" ] && [ -f "$RELAY_FILE" ]; then
    48	  section "RELAY.md: $(basename "$(dirname "$RELAY_FILE")")/RELAY.md"
    49	  # Extract STATUS: and NEXT: lines (case-sensitive as used in relay templates).
    50	  grep -E '^(STATUS|NEXT):' "$RELAY_FILE" 2>/dev/null || printf '(no STATUS:/NEXT: lines found)\n'
    51	else
    52	  section "RELAY.md"
    53	  printf '(no phases/*/RELAY.md found)\n'
    54	fi
    55	
    56	# ---------------------------------------------------------------------------
    57	# Recent tick events
    58	# ---------------------------------------------------------------------------
    59	
    60	EVENTS_DIR="$REPO/.tick/events"
    61	MARATHON_JSONL=""
    62	if [ -d "$EVENTS_DIR" ]; then
    63	  # shellcheck disable=SC2012
    64	  MARATHON_JSONL="$(ls -t "$EVENTS_DIR"/*marathon*.jsonl 2>/dev/null | head -1 || true)"
    65	fi
    66	
    67	section "Recent tick events"
    68	if [ -n "$MARATHON_JSONL" ] && [ -f "$MARATHON_JSONL" ]; then
    69	  printf 'File: %s\n' "$MARATHON_JSONL"
    70	  tail -10 "$MARATHON_JSONL"
    71	else
    72	  printf '(no *marathon*.jsonl events found in %s)\n' "$EVENTS_DIR"
    73	fi
relay-automation/relay-turn-lib.sh:64:  # (Producer|Reviewer); marathon-drive writes an AGENT ID (claude|codex|agy). The role test below can
relay-automation/relay-turn-lib.sh:75:  # So derive the role instead of trusting an assertion. marathon-drive renders a machine-readable
relay-automation/relay-turn-lib.sh:83:    directive="$(grep -E '^[[:space:]]*<!--[[:space:]]*marathon-drive:' "$f" 2>/dev/null | head -1)"
relay-automation/relay-turn-lib.sh:104:# Every transcript writer (consult.sh, marathon-drive.sh, relay-drive.sh, swarm-preflight.sh,
relay-automation/relay-turn-lib.sh:243:  # whenever marathon-drive/relay-drive don't export CODEX_TURN_ROOT/AGY_TURN_ROOT — they never do)
relay-automation/relay-turn-lib.sh:270:  # root-cause; 312a2c3's own message names the test/marathon-drive.sh GH-171/GH-172 failures Plan K
relay-automation/relay-turn-lib.sh:727:        # very marathon-drive.sh, or its relay-drive.sh subprocess — both are legitimate copyback
utils/swarm-preflight.sh:29:# relay-automation/marathon-drive.sh. It is the PRODUCER of the packet, never the
utils/swarm-preflight.sh:44:#       "remediation": { "source": "self#phases", "criteria": "Phases 1-7 of GH-25" },
utils/swarm-preflight.sh:61:# marathon-drive.sh — "This lane will commit to <branch>. Suggested branch: <suggested_branch>. Cut it
utils/swarm-preflight.sh:76:  _DRIVE_CMD=".xyz/relay-automation/marathon-drive.sh"
utils/swarm-preflight.sh:79:  _DRIVE_CMD="relay-automation/marathon-drive.sh"
utils/swarm-preflight.sh:745:DOC_HAS_PHASES=0
utils/swarm-preflight.sh:746:grep -Eq '^##+ .*[Pp]hase|^- \[[ xX]\]' "$PRIMARY_DOC" 2>/dev/null && DOC_HAS_PHASES=1
utils/swarm-preflight.sh:750:if [[ -z "$REMED_SRC$REMED_CRIT" && "$DOC_HAS_PHASES" -eq 0 ]]; then
utils/swarm-preflight.sh:955:## Suggested marathon-drive.sh invocation
utils/py/swarm_preflight.py:17:        return os.path.abspath(os.path.join(here_parent, "..")), ".xyz/relay-automation/marathon-drive.sh"
utils/py/swarm_preflight.py:18:    return here_parent, "relay-automation/marathon-drive.sh"
utils/py/swarm_preflight.py:1236:    doc_has_phases = 0
utils/py/swarm_preflight.py:1241:                    doc_has_phases = 1
utils/py/swarm_preflight.py:1247:    if not remed_src and not remed_crit and doc_has_phases == 0:
utils/py/swarm_preflight.py:1335:                # A direct program path is executed with cwd=target_root by marathon-drive.  Checking it
utils/py/swarm_preflight.py:1552:## Suggested marathon-drive.sh invocation
relay-automation/marathon-drive.sh:679:PHASES_DIR="${PHASES_DIR:-"$ROOT/phases"}"
utils/pdda/pdda.sh:95:    if pdda_frontmatter_has_key "$file" "phases"; then
utils/pdda/pdda.sh:96:      value="$(pdda_trim "$(pdda_frontmatter_value "$file" "phases")")"
utils/pdda/pdda.sh:98:        pdda_record_finding error "$CHECK_NAME" "$file" 1 "frontmatter 'phases' must be a positive integer (got '$value')" "fix-phases-value"
relay-automation/marathon-ls.sh:113:  local phases_dir="$repo/phases"
relay-automation/marathon-detail.sh:40:PHASES_DIR="$REPO/phases"
relay-automation/marathon.sh:167:PHASES_DIR="${PHASES_DIR:-"$ROOT/phases"}"
utils/py/marathon_drive.py:687:    phases_dir = args.phases_dir or os.path.join(root, "phases")

2026-08-10T04:59:02.163616Z ERROR codex_models_manager::manager: failed to renew cache TTL: missing field `base_instructions` at line 95 column 5
exec
/bin/zsh -lc "nl -ba utils/swarm-preflight.sh | sed -n '60,90p;930,985p'
nl -ba utils/py/swarm_preflight.py | sed -n '1,30p;1515,1585p'
rg -n --glob '"'!temp/**'"' --glob '"'!PROJECT/**'"' --glob '"'!relay-system/**'"' --glob '"'!phases/**'"' --glob '"'!test/**'"' 'phases/' relay-automation utils README.md ARCHITECTURE.md .gitignore
rg -n --glob '"'!temp/**'"' --glob '"'!PROJECT/**'"' --glob '"'!relay-system/**'"' --glob '"'!phases/**'"' --glob '"'!test/**'"' '\\bphases\\b' relay-automation utils README.md ARCHITECTURE.md .gitignore" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-67768-b0m00j9w
 succeeded in 0ms:
    60	# exist?). If `branch_ready: false` and `skip_branch_prompt: false`, ASK THE OPERATOR before invoking
    61	# marathon-drive.sh — "This lane will commit to <branch>. Suggested branch: <suggested_branch>. Cut it
    62	# now? [yes / no / custom name]" (never auto-cut — GUIDING-PRINCIPLES.md §8). `skip_branch_prompt: true`
    63	# (risk==1 in the doc frontmatter AND an independent-zone artifact set — no kernel/shim path) means
    64	# proceed on the current branch without asking. packet.md/packet.json both carry these fields inline,
    65	# and the packet.md "Suggested branch" line already states which of the two applies — a driving agent
    66	# reading the packet doesn't need to recompute it.
    67	
    68	set -uo pipefail
    69	# strict-mode: -e exempt — analysis tool with expected-nonzero probes (git/gh/grep); errors handled explicitly. See GUIDING-PRINCIPLES.md#strict-mode-policy.
    70	
    71	HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    72	# Vendored install: HERE is <target>/.xyz/utils → parent is .xyz → target root is grandparent.
    73	_here_parent="$(cd "$HERE/.." && pwd)"
    74	if [ "$(basename "$_here_parent")" = ".xyz" ]; then
    75	  ROOT="${SWARM_PREFLIGHT_ROOT:-"$(cd "$_here_parent/.." && pwd)"}"
    76	  _DRIVE_CMD=".xyz/relay-automation/marathon-drive.sh"
    77	else
    78	  ROOT="${SWARM_PREFLIGHT_ROOT:-"$_here_parent"}"
    79	  _DRIVE_CMD="relay-automation/marathon-drive.sh"
    80	fi
    81	# GH-30 Phase 2: transcript-root resolver (rtl_transcript_root) — redirects relay-system/ to
    82	# $XYZ_ARCHIVE_ROOT when set, else byte-for-byte "$ROOT/relay-system". relay-turn-lib.sh is a sibling
    83	# dir of utils/ (both under the harness root, or both under .xyz/ in a vendored install).
    84	source "$HERE/../relay-automation/relay-turn-lib.sh"
    85	NOW="${SWARM_PREFLIGHT_NOW:-"$(date -u +%Y-%m-%dT%H:%M:%SZ)"}"
    86	TODAY="${SWARM_PREFLIGHT_TODAY:-"$(date -u +%Y-%m-%d)"}"
    87	
    88	die()  { printf 'swarm-preflight: %s\n' "$*" >&2; exit 2; }
    89	log()  { printf 'swarm-preflight: %s\n' "$*" >&2; }
    90	emit() { printf '%s\n' "$*"; }   # stdout: operator-facing report lines
   930	# Marathon preflight packet — $SLUG
   931	
   932	- Generated: $NOW
   933	- Mode: $MODE
   934	- Sources: $(printf '%s ' "${SOURCE_DOCS[@]}")
   935	- Target root: $TARGET_ROOT ($BRANCH @ ${COMMIT:0:9})
   936	- Suggested branch: \`$SUGGESTED_BRANCH\` (branch_ready=$([[ "$BRANCH_READY" -eq 1 ]] && echo true || echo false)$([[ "$BRANCH_READY" -eq 0 && "$SKIP_BRANCH_PROMPT" -eq 0 ]] && echo " — not cut yet; ask the operator before proceeding, per GUIDING-PRINCIPLES.md §8")$([[ "$SKIP_BRANCH_PROMPT" -eq 1 ]] && echo " — carve-out: risk=1/independent zone, proceed on the current branch without asking"))
   937	- Verdict: $VERDICT
   938	- Gate: \`$GATE_CMD\`
   939	$GH108_GATE_CAVEAT
   940	- Artifacts: $ART_CSV
   941	$GH55_AUTO_LINE
   942	- Suggested turn budget: \`RELAY_TURN_TIMEOUT_S=$GH39_TIMEOUT\` (sized to ≈ $GH39_ART_LOC LOC across $GH39_ART_N artifact(s); a build that also edits tests needs headroom over the 300s default)
   943	
   944	This packet is the producer's output. The orchestrator launches the run; the planner does not
   945	(GUIDING-PRINCIPLES.md §8).
   946	
   947	## Acceptance criteria — the build is DONE when these hold (inlined from the capture doc)
   948	$GH39_ACC
   949	
   950	## Scope lock — builder, do exactly this and nothing else
   951	- Edit ONLY: \`$ART_CSV\` (plus the relay file). Any other edit is reverted and FAILS the turn.
   952	$GH54_VERIFY_RULE
   953	- Do NOT analyze the roadmap, file issues, or refactor adjacent code. Implement the acceptance criteria above — nothing more.
   954	
   955	## Suggested marathon-drive.sh invocation
   956	
   957	\`\`\`bash
   958	$INVOCATION
   959	\`\`\`
   960	
   961	## Files in this packet
   962	- \`run-candidate.json\` — normalized run candidate (provenance + contract + checks)
   963	- \`freshness.json\` — branch state + fix-still-required probes
   964	- \`readiness.json\` — remediation readiness verdict
   965	- \`lane-plan.json\` — Codex / agy / orchestrator lane assignment
   966	- \`marathon-invocation.txt\` — the invocation hint above
   967	EOF
   968	
   969	# In --format json mode, stdout must hold only the JSON object — route the status to stderr.
   970	if [[ "$FORMAT" == json ]]; then
   971	  log "packet written: $OUT_DIR"
   972	else
   973	  emit ""; emit "Packet written: $OUT_DIR"
   974	fi
   975	exit 0
     1	import argparse
     2	import os
     3	import sys
     4	import subprocess
     5	import time
     6	import re
     7	import json
     8	import shutil
     9	import datetime
    10	
    11	def compute_default_root(this_file):
    12	    # GH-267: this_file lives one directory deeper than its Bash sibling (utils/py/ vs
    13	    # utils/), so it needs two ".." to reach the same anchor (repo root, or vendored .xyz/).
    14	    here = os.path.dirname(os.path.abspath(this_file))
    15	    here_parent = os.path.abspath(os.path.join(here, "..", ".."))
    16	    if os.path.basename(here_parent) == ".xyz":
    17	        return os.path.abspath(os.path.join(here_parent, "..")), ".xyz/relay-automation/marathon-drive.sh"
    18	    return here_parent, "relay-automation/marathon-drive.sh"
    19	
    20	def eprint(*args, **kwargs):
    21	    print(*args, file=sys.stderr, **kwargs)
    22	
    23	def get_env(key, default=None):
    24	    return os.environ.get(key, default)
    25	
    26	def die(msg):
    27	    eprint(f"swarm-preflight: {msg}")
    28	    sys.exit(2)
    29	
    30	def log(msg):
  1515	    if gh39_art_loc > 200 or gh39_art_n >= 3: gh39_timeout = 600
  1516	    if gh39_art_loc > 400 or gh39_art_n >= 4: gh39_timeout = 900
  1517	    
  1518	    br_ready_str = 'true' if branch_ready else 'false'
  1519	    if branch_ready == 0 and skip_branch_prompt == 0: br_prompt_str = " — not cut yet; ask the operator before proceeding, per GUIDING-PRINCIPLES.md §8"
  1520	    elif skip_branch_prompt == 1: br_prompt_str = " — carve-out: risk=1/independent zone, proceed on the current branch without asking"
  1521	    else: br_prompt_str = ""
  1522	    
  1523	    packet_md = f"""# Marathon preflight packet — {slug}
  1524	
  1525	- Generated: {now}
  1526	- Mode: {mode}
  1527	- Sources: {" ".join(source_docs)} 
  1528	- Target root: {target_root} ({branch} @ {commit[:9]})
  1529	- Suggested branch: `{suggested_branch}` (branch_ready={br_ready_str}{br_prompt_str})
  1530	- Verdict: {verdict}
  1531	- {issue_state_packet_line[2:]}
  1532	- Gate: `{gate_cmd}`
  1533	{gh108_gate_caveat}
  1534	- Artifacts: {art_csv}
  1535	- Suggested turn budget: `RELAY_TURN_TIMEOUT_S={gh39_timeout}` (sized to ≈ {gh39_art_loc} LOC across {gh39_art_n} artifact(s); a build that also edits tests needs headroom over the 300s default)
  1536	{gh55_auto_line}
  1537	
  1538	This packet is the producer's output. The orchestrator launches the run; the planner does not
  1539	(GUIDING-PRINCIPLES.md §8).
  1540	
  1541	## Acceptance criteria — the build is DONE when these hold
  1542	*Inlined verbatim from `{primary_doc}` ({acc_scope_note}). Continuation lines included; if a
  1543	criterion here reads as a fragment, that is the source text, not a truncation.*
  1544	{acc_provenance_line}
  1545	{gh39_acc}
  1546	
  1547	## Scope lock — builder, do exactly this and nothing else
  1548	- Edit ONLY: `{art_csv}` (plus the relay file). Any other edit is reverted and FAILS the turn.
  1549	{gh54_verify_rule}
  1550	- Do NOT analyze the roadmap, file issues, or refactor adjacent code. Implement the acceptance criteria above — nothing more.
  1551	
  1552	## Suggested marathon-drive.sh invocation
  1553	
  1554	```bash
  1555	{invocation}
  1556	```
  1557	
  1558	## Files in this packet
  1559	- `run-candidate.json` — normalized run candidate (provenance + contract + checks)
  1560	- `freshness.json` — branch state + fix-still-required probes
  1561	- `readiness.json` — remediation readiness verdict
  1562	- `lane-plan.json` — Codex / agy / orchestrator lane assignment
  1563	- `marathon-invocation.txt` — the invocation hint above
  1564	"""
  1565	
  1566	    with open(os.path.join(out_dir, "packet.md"), "w") as f:
  1567	        f.write(packet_md)
  1568	
  1569	    if args.format == "json":
  1570	        log(f"packet written: {out_dir}")
  1571	    else:
  1572	        emit(f"\nPacket written: {out_dir}")
  1573	        
  1574	    sys.exit(0)
  1575	
  1576	if __name__ == "__main__":
  1577	    main()
README.md:215:**What matches.** Phases are real nodes — each gets `phases/<id>/RELAY.md`, a tick token, a
relay-automation/MARATHON.example.yaml:36:#   id                 phase id → phases/<id>/RELAY.md + tick token MARATHON-<ID>-TURN   (required)
relay-automation/marathon-drive.sh:26:# Renders phases/p1/RELAY.md from the phase brief, seeds the tick token (handoff → builder),
relay-automation/marathon-drive.sh:40:#     [--phases-dir <DIR>]       where to create phases/<id>/ (default: <repo-root>/phases)
relay-automation/marathon-drive.sh:41:#     [--phase-id <ID>]          which phase to drive: phases/<id>/ (default: p1; the orchestrator sets it)
relay-automation/marathon-drive.sh:71:# (basename ".xyz"). ROOT = work root = where git ops, phases/, .tick/, validate.sh live.
relay-automation/marathon-drive.sh:603:  --phases-dir DIR        Where to create phases/<id>/ (default: <repo-root>/phases).
relay-automation/marathon-drive.sh:604:  --phase-id ID           Which phase to drive: phases/<id>/ (default: p1).
relay-automation/marathon-drive.sh:634:PHASE_ID="p1"        # which phase this invocation drives (phases/<id>/); the orchestrator sets it
relay-automation/marathon-drive.sh:957:# marathon's own paths (phases/, .tick/). --require-clean turns the warning into a hard stop for
relay-automation/marathon-drive.sh:969:# ── Step 1: render phases/p1/RELAY.md ──────────────────────────────────────
relay-automation/marathon.sh:94:  --phases-dir DIR        Where to create phases/<id>/ (default: <repo-root>/phases).
relay-automation/marathon.sh:96:                          The relay thread, tick token, phases/ and relay-system/ transcripts all stay
relay-automation/marathon.sh:98:                          repo cannot track harness output (e.g. a public repo that gitignores phases/
relay-automation/marathon-ls.sh:110:# Find newest phases/*/RELAY.md path for a repo (used in RELAY-FILE column).
relay-automation/README.md:123:- `MARATHON_ROOT`: the target repo that owns the plan's `brief:` files, `phases/`, `.tick/`, and commit target. Default: `git -C "$PWD" rev-parse --show-toplevel`; outside a git repo it falls back to `MARATHON_HOME`.
relay-automation/marathon-detail.sh:5:#   - STATUS: / NEXT: lines from the newest phases/*/RELAY.md (if any)
relay-automation/marathon-detail.sh:39:# Newest phases/*/RELAY.md
relay-automation/marathon-detail.sh:53:  printf '(no phases/*/RELAY.md found)\n'
utils/py/marathon_drive.py:1666:                    if not p.startswith("phases/") and not p.startswith(".tick/"):
utils/py/marathon_drive.py:1677:    # phase dir creation used to live here, above the render, so a dry run materialized phases/<id>/
.gitignore:66:/phases
README.md:202:- **Marathon** (`relay-automation/marathon.sh`) — chains several relay build→review phases from a
README.md:215:**What matches.** Phases are real nodes — each gets `phases/<id>/RELAY.md`, a tick token, a
README.md:226:`relay-automation/MARATHON.example.yaml` states that phases run strictly one at a time and that a
README.md:240:### Do phases run in parallel? What does `depends_on` actually do?
README.md:250:Analysing your phases for a disjoint write-set is still worth doing — it is how you learn which
README.md:251:phases genuinely need `depends_on` — but it will not make them concurrent.
relay-automation/MARATHON.example.yaml:7:# SEQUENCING (GH-241): phases run STRICTLY ONE AT A TIME — there is no concurrent execution, and
relay-automation/MARATHON.example.yaml:10:# Analysing your phases for a disjoint write-set is still worthwhile (it is how you know which
relay-automation/MARATHON.example.yaml:11:# phases genuinely need `depends_on`), but a disjoint write-set does NOT buy you parallelism here.
relay-automation/MARATHON.example.yaml:36:#   id                 phase id → phases/<id>/RELAY.md + tick token MARATHON-<ID>-TURN   (required)
relay-automation/MARATHON.example.yaml:50:phases:
relay-automation/MARATHON.example.yaml:54:    brief: phases-briefs/p1-schema.md
relay-automation/MARATHON.example.yaml:62:    brief: phases-briefs/p2-lease.md
relay-automation/marathon-drive.sh:26:# Renders phases/p1/RELAY.md from the phase brief, seeds the tick token (handoff → builder),
relay-automation/marathon-drive.sh:40:#     [--phases-dir <DIR>]       where to create phases/<id>/ (default: <repo-root>/phases)
relay-automation/marathon-drive.sh:41:#     [--phase-id <ID>]          which phase to drive: phases/<id>/ (default: p1; the orchestrator sets it)
relay-automation/marathon-drive.sh:49:#                                fails (exit 5) even if --pre-advance-cmd passed. Omit for phases with
relay-automation/marathon-drive.sh:71:# (basename ".xyz"). ROOT = work root = where git ops, phases/, .tick/, validate.sh live.
relay-automation/marathon-drive.sh:164:# phase's print is the whole chain's true final total; earlier phases' prints are an additive
relay-automation/marathon-drive.sh:603:  --phases-dir DIR        Where to create phases/<id>/ (default: <repo-root>/phases).
relay-automation/marathon-drive.sh:604:  --phase-id ID           Which phase to drive: phases/<id>/ (default: p1).
relay-automation/marathon-drive.sh:614:                          even when --pre-advance-cmd passed. Omit for phases with no test surface
relay-automation/marathon-drive.sh:634:PHASE_ID="p1"        # which phase this invocation drives (phases/<id>/); the orchestrator sets it
relay-automation/marathon-drive.sh:654:    --phases-dir)      PHASES_DIR="${2:-}"; shift 2 ;;
relay-automation/marathon-drive.sh:679:PHASES_DIR="${PHASES_DIR:-"$ROOT/phases"}"
relay-automation/marathon-drive.sh:957:# marathon's own paths (phases/, .tick/). --require-clean turns the warning into a hard stop for
relay-automation/marathon-drive.sh:961:    | awk '{ p=substr($0,4); if (p !~ /^phases\// && p !~ /^\.tick\//) print p }')"
relay-automation/marathon-drive.sh:969:# ── Step 1: render phases/p1/RELAY.md ──────────────────────────────────────
utils/pdda/pdda-doc-ready.sh:42:- a multi-phase plan with no table of contents listing its phases
utils/pdda/pdda-doc-ready.sh:45:  findings (what was investigated, what was found, what it changes for later phases)
utils/pdda/pdda-doc-ready.sh:47:  missing the triage ratings effort, complexity, risk, phases (used by automation to select work);
utils/pdda/pdda.sh:85:    # complexity, and risk are integers 1 (low) .. 5 (highest); phases is a positive integer.
utils/pdda/pdda.sh:95:    if pdda_frontmatter_has_key "$file" "phases"; then
utils/pdda/pdda.sh:96:      value="$(pdda_trim "$(pdda_frontmatter_value "$file" "phases")")"
utils/pdda/pdda.sh:98:        pdda_record_finding error "$CHECK_NAME" "$file" 1 "frontmatter 'phases' must be a positive integer (got '$value')" "fix-phases-value"
relay-automation/marathon.sh:7:# leaving that phase's ESCALATION.md (written by marathon-drive) and NOT starting later phases.
relay-automation/marathon.sh:10:# Per-phase round cap = 2 * max_review_rounds + 1 (turns ≠ rounds; the off-by-one kills phases early).
relay-automation/marathon.sh:15:#   relay-automation/marathon.sh --plan MARATHON.yaml [--builder codex] [--phases-dir DIR]
relay-automation/marathon.sh:50:# Exit: 0 all phases approved · N the failing phase's marathon-drive exit code · 2 usage/parse error.
relay-automation/marathon.sh:84:Usage: marathon.sh --plan MARATHON.yaml [--builder A] [--phases-dir D] [--pre-advance-cmd C]
relay-automation/marathon.sh:94:  --phases-dir DIR        Where to create phases/<id>/ (default: <repo-root>/phases).
relay-automation/marathon.sh:96:                          The relay thread, tick token, phases/ and relay-system/ transcripts all stay
relay-automation/marathon.sh:98:                          repo cannot track harness output (e.g. a public repo that gitignores phases/
relay-automation/marathon.sh:117:    --phases-dir)      PHASES_DIR="${2:-}"; shift 2 ;;
relay-automation/marathon.sh:167:PHASES_DIR="${PHASES_DIR:-"$ROOT/phases"}"
relay-automation/marathon.sh:172:[[ -n "$PLAN_TSV" ]] || die "plan has no phases"
relay-automation/marathon.sh:200:               --phase-brief "$brief_path" --round-cap "$cap" --phases-dir "$PHASES_DIR" )
relay-automation/marathon.sh:234:    log "HALT: phase $id failed (marathon-drive exit $phase_exit) — chain stops; later phases NOT started"
relay-automation/marathon-ls.sh:110:# Find newest phases/*/RELAY.md path for a repo (used in RELAY-FILE column).
relay-automation/marathon-ls.sh:113:  local phases_dir="$repo/phases"
relay-automation/marathon-detail.sh:5:#   - STATUS: / NEXT: lines from the newest phases/*/RELAY.md (if any)
relay-automation/marathon-detail.sh:39:# Newest phases/*/RELAY.md
relay-automation/marathon-detail.sh:40:PHASES_DIR="$REPO/phases"
relay-automation/marathon-detail.sh:53:  printf '(no phases/*/RELAY.md found)\n'
utils/hq/hq-lib.sh:358:#                    [<complexity>] [<risk>] [<effort>] [<phases>]
utils/hq/hq-lib.sh:374:  local complexity="${9:-}" risk="${10:-}" effort="${11:-}" phases="${12:-}"
utils/hq/hq-lib.sh:384:  [ -n "$phases" ]     || phases=1
utils/hq/hq-lib.sh:416:phases: $phases
relay-automation/CONTRACT.example.md:43:phases: 1
relay-automation/README.md:4:build swarms. Built in phases on top of `tick` (see
relay-automation/README.md:123:- `MARATHON_ROOT`: the target repo that owns the plan's `brief:` files, `phases/`, `.tick/`, and commit target. Default: `git -C "$PWD" rev-parse --show-toplevel`; outside a git repo it falls back to `MARATHON_HOME`.
utils/swarm-preflight.sh:44:#       "remediation": { "source": "self#phases", "criteria": "Phases 1-7 of GH-25" },
utils/py/rtl.py:436:# (#410): two phases in one run, same builder and same isolation settings, where the one with TEN
utils/py/marathon_drive.py:383:    parser.add_argument("--phases-dir", dest="phases_dir")
utils/py/marathon_drive.py:687:    phases_dir = args.phases_dir or os.path.join(root, "phases")
utils/py/marathon_drive.py:1666:                    if not p.startswith("phases/") and not p.startswith(".tick/"):
utils/py/marathon_drive.py:1677:    # phase dir creation used to live here, above the render, so a dry run materialized phases/<id>/
utils/py/marathon_drive.py:1678:    # in whatever repo it resolved to — the harness itself when no MARATHON_ROOT/--phases-dir was

2026-08-10T04:59:07.842935Z ERROR codex_models_manager::manager: failed to renew cache TTL: missing field `base_instructions` at line 95 column 5
exec
/bin/zsh -lc "nl -ba .gitignore | sed -n '50,75p'
nl -ba test/marathon-root-audit.sh | sed -n '235,265p'
git check-ignore -v phases/audit-probe/RELAY.md || true
git check-ignore -v MARATHONS/audit-probe/RELAY.md || true
rg -n -i --glob '"'!temp/**'"' --glob '"'!PROJECT/**'"' --glob '"'!relay-system/**'"' --glob '"'!phases/**'"' '(MARATHON(S)?|phases)' test/marathon-ls.sh test/marathon-detail.sh test 2>/dev/null | rg 'marathon-ls|marathon-detail|DEFAULT|default|phases-dir|phases/'" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-67768-b0m00j9w
 succeeded in 6392ms:
2026-08-09 21:59:20.196 xcodebuild[74575:95520170]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-08-09 21:59:20.713 xcodebuild[74575:95520084] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.
git: warning: confstr() failed with code 5: couldn't get path of DARWIN_USER_TEMP_DIR; using /tmp instead
git: error: couldn't create cache file '/tmp/xcrun_db-6ovdT8Sn' (errno=Operation not permitted)
2026-08-09 21:59:21.585 xcodebuild[75308:95521459]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-08-09 21:59:21.819 xcodebuild[75308:95521457] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.
.gitignore:66:/phases	phases/audit-probe/RELAY.md
git: warning: confstr() failed with code 5: couldn't get path of DARWIN_USER_TEMP_DIR; using /tmp instead
git: error: couldn't create cache file '/tmp/xcrun_db-8aqYKf7x' (errno=Operation not permitted)
2026-08-09 21:59:23.345 xcodebuild[75324:95521631]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-08-09 21:59:23.527 xcodebuild[75324:95521627] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.
git: warning: confstr() failed with code 5: couldn't get path of DARWIN_USER_TEMP_DIR; using /tmp instead
git: error: couldn't create cache file '/tmp/xcrun_db-poMY8Ir2' (errno=Operation not permitted)
2026-08-09 21:59:24.133 xcodebuild[75409:95521769]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-08-09 21:59:24.376 xcodebuild[75409:95521768] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.
test/gh319-gate-path-with-space.sh:93:    --phases-dir "$ROOT/phases" \
test/debug-mantra.sh:30:    --phases-dir "$A/phases" \
test/debug-mantra.sh:104:mkdir -p "$A/.tick/attempts" "$A/phases/p1"
test/debug-mantra.sh:106:cat > "$A/phases/p1/ESCALATION.md" << 'ESC_EOF'
test/debug-mantra.sh:113:relay-file: phases/p1/RELAY.md
test/gh322-runlog-python-lane.sh:101:    PATH="${GH_ON_PATH:-}$NODE_ONLY:/usr/bin:/bin" bash "$DRIVER" --phases-dir "$A/phases" \
test/gh322-runlog-python-lane.sh:110:  && pass "--log-github on the default lane preserves the marathon exit code" \
test/gh397-reviewer-turn-role.sh:82:mkdir -p "$A/phases/p1"
test/gh397-reviewer-turn-role.sh:83:MP="$A/phases/p1/RELAY.md"
test/marathon-monitor.sh:2:# test/marathon-monitor.sh — dependency-free tests for marathon-ls.sh.
test/marathon-monitor.sh:19:LS="$HERE/../relay-automation/marathon-ls.sh"
test/marathon-monitor.sh:42:  mkdir -p "$repo/.git" "$repo/.tick/events" "$repo/phases/p1"
test/marathon-monitor.sh:48:  mkdir -p "$repo/.tick/events" "$repo/phases/p1"
test/marathon-monitor.sh:108:# Delete the path now so marathon-ls.sh sees it as GONE.
test/marathon-monitor.sh:112:# Run marathon-ls.sh with our fake registry
test/marathon-monitor.sh:181:  "$HERE/../relay-automation/marathon-ls.sh"
test/marathon-monitor.sh:182:  "$HERE/../relay-automation/marathon-detail.sh"
test/gh390-gate-guard.sh:98:    --phases-dir "$ROOT/phases" \
test/gh390-gate-guard.sh:106:  sed -n 's/^reason: //p' "$ROOT/phases/$1/ESCALATION.md" 2>/dev/null
test/test_python_layer.py:128:    # GH-451: Pi is a Python-default marathon builder. Its binary must be checked in the same
test/test_python_layer.py:193:    relay = rtl.RelayTurnLib(REPO_ROOT, REPO_ROOT, os.path.join(REPO_ROOT, "phases/gh112b/RELAY.md"), "")
test/gh331-cost-summary.sh:161:    bash "$MDRIVE" --phases-dir "$A/phases" --phase-brief "$BRIEF" --phase-id "$pid" \
test/gh331-cost-summary.sh:165:# (4a) default lane, cost summary ON → marathon prints its own block, still exits 3.
test/gh331-cost-summary.sh:168:  && pass "marathon-drive default lane: driven phase prints the cost summary (exit preserved: 3)" \
test/gh331-cost-summary.sh:169:  || fail "marathon-drive default lane: expected exit 3 + cost summary; got rc=$mRc (out: $(printf '%s' "$mOut" | tail -5))"
test/gh401-dry-run-no-mutation.sh:3:# gate-evidence: {"form":"pre-fix-replay","observed":true,"result":"reproducer: bash test/gh401-dry-run-no-mutation.sh; pre-fix revision: marathon_drive.py before d4999cd, where os.makedirs + the RELAY.md write ran ABOVE the dry-run exit; pre-fix result: --dry-run created phases/p1/ and wrote RELAY.md, leaving the marathon root's git status dirty; post-fix result: 4/0 — status byte-identical, no phases/ directory, and the positive control confirms the render still happens and is reported"}
test/gh401-dry-run-no-mutation.sh:5:# `marathon-drive --dry-run` used to RENDER AND WRITE phases/<id>/RELAY.md before reaching its exit,
test/gh401-dry-run-no-mutation.sh:6:# so a dry run mutated the working tree. Unscoped (no MARATHON_ROOT, no --phases-dir) that landed on
test/gh401-dry-run-no-mutation.sh:7:# the HARNESS repo's own tracked phases/p1/RELAY.md: `bash validate.sh` left the tree dirty, the diff
test/gh401-dry-run-no-mutation.sh:57:  && pass "--dry-run creates no phases/ directory" \
test/swarm-preflight.sh:537:    { "type": "path_absent", "path": "relay-automation/marathon-ls.sh" },
test/swarm-preflight.sh:538:    { "type": "path_absent", "path": "relay-automation/marathon-detail.sh" },
test/swarm-preflight.sh:543:    "relay-automation/marathon-ls.sh",
test/swarm-preflight.sh:544:    "relay-automation/marathon-detail.sh",
test/swarm-preflight.sh:549:    "relay-automation/marathon-ls.sh",
test/swarm-preflight.sh:550:    "relay-automation/marathon-detail.sh",
test/gh438-removal-is-progress.sh:58:TICK_REPO_ROOT="$A" "$TICK" claim "\$task" --agent agy --paths "phases/p1/RELAY.md" >/dev/null 2>&1 || true
test/gh438-removal-is-progress.sh:69:  python3 "$DRIVER" --phases-dir "$A/phases" --phase-brief "$BRIEF" --reviewer agy --builder claude \
test/gh438-acceptance-recheck.sh:79:TICK_REPO_ROOT="$A" "$TICK" claim "\$task" --agent agy --paths "phases/p1/RELAY.md" >/dev/null 2>&1 || true
test/gh438-acceptance-recheck.sh:91:  python3 "$DRIVER" --phases-dir "$A/phases" --phase-brief "$b" --reviewer agy --builder claude \
test/gh438-acceptance-recheck.sh:109:grep -q 'reason: acceptance-probes-unmet' "$A/phases/p1/ESCALATION.md" 2>/dev/null \
test/gh438-acceptance-recheck.sh:111:  || fail "escalation record missing or wrong reason: $(cat "$A/phases/p1/ESCALATION.md" 2>/dev/null)"
test/gh385-retry-token-satisfied.sh:48:  mkdir -p "$A/phases/p1"
test/gh385-retry-token-satisfied.sh:50:    "$1" > "$A/phases/p1/RELAY.md"
test/gh385-retry-token-satisfied.sh:55:  tick_a claim "$1" --agent claude --paths "phases/p1/RELAY.md" >/dev/null 2>&1 || true
test/gh385-retry-token-satisfied.sh:63:  python3 "$DRIVER" --phases-dir "$A/phases" --phase-brief "$BRIEF" \
test/gh385-retry-token-satisfied.sh:107:mkdir -p "$A/phases/p1"
test/gh385-retry-token-satisfied.sh:108:printf '# Marathon Phase p1\nSTATUS: Approved\nNEXT: agy\n\nbody\n' > "$A/phases/p1/RELAY.md"
test/gh342-sentinel-debug-log-python.sh:6:# exec's utils/py/marathon_drive.py near the top, and Python is the default lane since GH-264. So
test/gh342-sentinel-debug-log-python.sh:21:#   7  end-to-end on the default lane: a real marathon-drive run reclaiming a stale driver lock
test/gh342-sentinel-debug-log-python.sh:122:    file="phases/p1/RELAY.md", action="promote",
test/gh342-sentinel-debug-log-python.sh:133:    ("file", "phases/p1/RELAY.md"), ("action", "promote"),
test/gh342-sentinel-debug-log-python.sh:197:         "phases/p1/RELAY.md", "promote to PROJECT/1-INBOX capture doc", "", "p1", "TASK-1", ""),
test/gh284-runlog-heartbeat.sh:92:    PATH="$NODE_ONLY:/usr/bin:/bin" bash "$DRIVER" --phases-dir "$A/phases" --phase-brief "$BRIEF" \
test/gh284-runlog-heartbeat.sh:173:    PATH="$GH_STUB_DIR:$NODE_ONLY:/usr/bin:/bin" bash "$DRIVER" --phases-dir "$A/phases" \
test/gh307-gate-env-scrub.sh:9:# so `bash validate.sh` — the documented default gate — could never pass inside a marathon:
test/litmus-release.sh:74:# `complete` while `phases/p1/RELAY.md` was still tracked with 9 machine-specific absolute paths — a
test/litmus-release.sh:99:# mistake #461's row made and it is why the row is now empty. #461 required phases/p1/RELAY.md to stay
test/litmus-release.sh:104:# gate. Trying to satisfy it from the other side by gitignoring /phases/ is worse — `git add` on an
test/litmus-release.sh:271:  # phases/p1/RELAY.md was still tracked, so the column that fixes that must be proven to bite.
test/gh457-gate-tiers.sh:2:# gate-evidence: {"form":"deliberate-mutation","observed":true,"result":"reproducer: bash test/gh457-gate-tiers.sh. The registry entry for the default tier is mutated to wall_s=1 and the resolver is required to return 1, then restored and required to return the shipped value — so a cosmetically-tiered implementation with hardcoded caps fails while every other assertion in the file still passes. Observed in both directions in one run. The kill that a cap authorises is observed separately by the driven fast-tier overrun case (real subprocess, escalates gate-killed) and by the driven red-gate case (still pre-advance-failed); this control does NOT push a mutated registry through a subprocess marathon, and the pairing rather than a single end-to-end mutation is what is claimed."}
test/gh457-gate-tiers.sh:119:    --phases-dir "$ROOT/phases" \
test/gh457-gate-tiers.sh:125:esc_reason() { sed -n 's/^reason: //p' "$ROOT/phases/$1/ESCALATION.md" 2>/dev/null; }
test/marathon.sh:71:  && pass "p1: round-cap=5, no timeout override by default, lane namespace set" || fail "p1 cap/env: [$(grep p1 "$WORK/phases-ran")]"
test/marathon.sh:173:  TICK_REPO_ROOT="$A" "$TICK" claim "$task" --agent codex --paths "phases/**,src/gh205.js" >/dev/null 2>&1 || true
test/marathon.sh:179:TICK_REPO_ROOT="$A" "$TICK" claim "$task" --agent agy --paths "phases/**" >/dev/null 2>&1 || true
test/marathon.sh:193:grep -q '^STATUS: Approved' "$A/phases/gh205/RELAY.md" \
test/marathon.sh:220:grep -q 'reason: timeout-no-artifact' "$A/phases/gh205-hang/ESCALATION.md" \
test/marathon.sh:253:    --phases-dir)  phases_dir="\$2"; shift 2 ;;
test/hq-park-synthesis.sh:57:grep -q '^phases: 1$' "$DOC" && pass "default phases=1" || fail "default phases wrong"
test/marathon-root-audit.sh:8:# invocation in test/gh268-relay-cue-and-target-checks.sh therefore wrote phases/p1/RELAY.md into
test/marathon-root-audit.sh:241:# Not hypothetical: `/phases/` was added to .gitignore on 2026-08-09 to stop the #401/#461 churn, and
test/marathon-root-audit.sh:243:# makes the revert stick. Verified directly before writing it: in a scratch repo ignoring /phases/,
test/marathon-root-audit.sh:244:# `git add -- phases/newrun/RELAY.md` exits 1.
test/marathon-root-audit.sh:250:for probe in phases/audit-probe/RELAY.md phases/audit-probe/ESCALATION.md; do
test/marathon-plan.sh:476:cp "$O/PROJECT/2-WORKING/MARATHON-PLAN-$DAY.md" "$O/default.md"
test/marathon-plan.sh:477:run_qp "$O" --zones-config "$ROOT/utils/marathon-plan-zones.default.json" >/dev/null 2>&1
test/marathon-plan.sh:478:cmp -s "$O/default.md" "$O/PROJECT/2-WORKING/MARATHON-PLAN-$DAY.md" \
test/marathon-plan.sh:723:# line unreachable — so `marathon-plan.sh --bogus` exited 0 on the DEFAULT lane while Bash exited 2.
test/gh268-relay-cue-and-target-checks.sh:146:# own tracked phases/p1/RELAY.md — `bash validate.sh` left the tree dirty, and the polluted file was
test/xyz-harness-hooks.sh:170:    bash "$MARATHON_DRIVE" --phases-dir "$A/phases" --phase-brief "$BRIEF" \
test/xyz-harness-hooks.sh:262:    bash "$MARATHON_DRIVE" --phases-dir "$A/phases" --phase-brief "$BRIEF" \
test/sentinel-driver-hooks.sh:36:xyz_debug_log_append error "marathon.escalation" "$(printf 'no-progress\t"x" \\y')" "phases/p1/RELAY.md" "promote"
test/sentinel-driver-hooks.sh:42:assert row["file"] == "phases/p1/RELAY.md" and row["action"] == "promote", row
test/gh407-gate-ran-attribution.sh:75:    --phases-dir "$ROOT/phases" \
test/gh407-gate-ran-attribution.sh:81:esc_field() { sed -n "s/^$2: //p" "$ROOT/phases/$1/ESCALATION.md" 2>/dev/null; }
test/gh407-gate-ran-attribution.sh:175:  bash "$PRE_DRIVER" --phases-dir "$PRE_ROOT/phases" --phase-brief "$BRIEF" \
test/gh407-gate-ran-attribution.sh:178:pre_reason="$(sed -n 's/^reason: //p' "$PRE_ROOT/phases/no-gate/ESCALATION.md" 2>/dev/null)"
test/gh407-gate-ran-attribution.sh:179:pre_gate="$(sed -n 's/^gate: //p' "$PRE_ROOT/phases/no-gate/ESCALATION.md" 2>/dev/null)"
test/pi-turn.sh:222:# --- (14) dispatcher: a Python-default marathon's --agent-cmd reaches pi-turn.py ------------------
test/marathon-drive.sh:46:# GH-212: this suite's default builder identity is pinned to `claude` here (not marathon-drive's
test/marathon-drive.sh:57:    --phases-dir "$A/phases" \
test/marathon-drive.sh:66:# GH-401: this case used to assert `[ -f "$A/phases/p1/RELAY.md" ]` — it pinned the defect as the
test/marathon-drive.sh:68:# tracked phases/p1/RELAY.md and left `bash validate.sh` with a dirty tree. The property worth
test/marathon-drive.sh:89:grep -q "TAKE YOUR TURN.*claude.*BUILDER" "$A/phases/p1/RELAY.md" 2>/dev/null \
test/marathon-drive.sh:92:grep -q "TAKE YOUR TURN.*agy.*REVIEWER" "$A/phases/p1/RELAY.md" 2>/dev/null \
test/marathon-drive.sh:95:grep -q "STATUS: Open" "$A/phases/p1/RELAY.md" 2>/dev/null \
test/marathon-drive.sh:98:grep -q "Implement a hello-world" "$A/phases/p1/RELAY.md" 2>/dev/null \
test/marathon-drive.sh:116:tick_a claim MARATHON-P1-TURN --agent seed --paths "phases/p1/RELAY.md" >/dev/null
test/marathon-drive.sh:137:tick_a claim MARATHON-P1-TURN --agent claude --paths "phases/p1/RELAY.md" >/dev/null
test/marathon-drive.sh:237:[ -f "$A/phases/p1/ESCALATION.md" ] && pass "ESCALATION.md written on gate failure" || fail "ESCALATION.md missing"
test/marathon-drive.sh:238:grep -q "pre-advance-failed" "$A/phases/p1/ESCALATION.md" \
test/marathon-drive.sh:299:  grep -q '^reason: post-approve-failed$' "$A/phases/p1/ESCALATION.md" 2>/dev/null \
test/marathon-drive.sh:312:[ -f "$A/phases/p1/ESCALATION.md" ] && pass "ESCALATION.md written on relay cap" || fail "ESCALATION.md missing on cap"
test/marathon-drive.sh:313:grep -q "relay-drive-exit: 4" "$A/phases/p1/ESCALATION.md" \
test/marathon-drive.sh:322:[ -f "$A/phases/p1/ESCALATION.md" ] && pass "ESCALATION.md written on no-progress" || fail "ESCALATION.md missing on no-progress"
test/marathon-drive.sh:331:[ -f "$A/phases/p1/ESCALATION.md" ] && pass "ESCALATION.md written on containment violation" || fail "ESCALATION.md missing on exit 6"
test/marathon-drive.sh:332:grep -q "containment-violation" "$A/phases/p1/ESCALATION.md" \
test/marathon-drive.sh:380:  bash "$DRIVER" --phases-dir "$A/phases" --phase-brief "$BRIEF" \
test/marathon-drive.sh:392:grep -q "$ART" "$A/phases/p1/RELAY.md" 2>/dev/null \
test/marathon-drive.sh:394:grep -q -- "--paths \"phases/p1/RELAY.md,$ART\"" "$A/phases/p1/RELAY.md" 2>/dev/null \
test/marathon-drive.sh:409:  bash "$DRIVER" --phases-dir "$A/phases" --phase-brief "$BRIEF" \
test/marathon-drive.sh:422:  bash "$DRIVER" --phases-dir "$A/phases" --phase-brief "$BRIEF" \
test/marathon-drive.sh:434:[ -f "$A/phases/plan-a--p1/RELAY.md" ] \
test/marathon-drive.sh:443:[ -f "$A/phases/plan-b--p1/RELAY.md" ] \
test/marathon-drive.sh:493:TICK_REPO_ROOT="$A" "$TICK" claim "$task" --agent agy --paths "phases/satisfied-plan--p1/RELAY.md" >/dev/null 2>&1 || true
test/marathon-drive.sh:502:  bash "$DRIVER" --phases-dir "$A/phases" --phase-brief "$BRIEF" --reviewer agy --artifact src/satisfied.js \
test/marathon-drive.sh:509:grep -q '^STATUS: Approved' "$A/phases/satisfied-plan--p1/RELAY.md" \
test/marathon-drive.sh:536:  bash "$DRIVER" --phases-dir "$A/phases" --phase-brief "$BRIEF" --reviewer agy --artifact src/stalled.js \
test/marathon-drive.sh:543:grep -q 'reason: no-progress' "$A/phases/stalled-plan--p1/ESCALATION.md" \
test/marathon-drive.sh:570:  bash "$DRIVER" --phases-dir "$A/phases" --phase-brief "$BRIEF" --reviewer agy --artifact src/zero-artifact.js \
test/marathon-drive.sh:586:  bash "$DRIVER" --phases-dir "$A/phases" --phase-brief "$BRIEF" --reviewer agy --artifact src/unchanged-artifact.js \
test/marathon-drive.sh:613:TICK_REPO_ROOT="$A" "$TICK" claim "$task" --agent claude --paths "phases/p1/RELAY.md" >/dev/null 2>&1 || true
test/marathon-drive.sh:615:TICK_REPO_ROOT="$A" "$TICK" claim "$task" --agent agy --paths "phases/p1/RELAY.md" >/dev/null 2>&1 || true
test/marathon-drive.sh:628:  bash "$DRIVER" --phases-dir "$A/phases" --phase-brief "$BRIEF" --reviewer agy \
test/marathon-drive.sh:632:grep -q '^STATUS: Approved' "$A/phases/p1/RELAY.md" \
test/marathon-drive.sh:634:  || fail "GH-274: RELAY.md should show STATUS: Approved: $(cat "$A/phases/p1/RELAY.md" 2>/dev/null)"
test/marathon-drive.sh:638:BEFORE_RETRY_RELAY="$(cat "$A/phases/p1/RELAY.md")"
test/marathon-drive.sh:644:  bash "$DRIVER" --phases-dir "$A/phases" --phase-brief "$BRIEF" --reviewer agy \
test/marathon-drive.sh:651:[ "$(cat "$A/phases/p1/RELAY.md")" = "$BEFORE_RETRY_RELAY" ] \
test/marathon-drive.sh:653:  || fail "GH-274: RELAY.md changed on retry: $(cat "$A/phases/p1/RELAY.md")"
test/marathon-drive.sh:654:grep -q '^STATUS: Open' "$A/phases/p1/RELAY.md" \
test/marathon-drive.sh:680:    --phases-dir "$WT/phases" \
test/marathon-drive.sh:692:[ -f "$WT/phases/p1/RELAY.md" ] && pass "linked worktree + --require-clean still seeds the phase" \
test/marathon-drive.sh:701:[ ! -f "$A/phases/p1/RELAY.md" ] && pass "dirty + --require-clean does not seed the phase" || fail "phase seeded despite --require-clean on dirty tree"
test/marathon-drive.sh:716:  bash "$DRIVER" --phases-dir "$A/phases" --phase-brief "$BRIEF" --reviewer agy --builder claude 2>&1)"; rc=$?
test/marathon-drive.sh:725:[ ! -f "$A/phases/p1/RELAY.md" ] && pass "GH-238: missing default gate never renders turn 1 relay" \
test/marathon-drive.sh:743:[ ! -f "$A/phases/p1/RELAY.md" ] && pass "GH-117: missing builder — relay file never rendered" \
test/marathon-drive.sh:757:[ ! -f "$A/phases/p1/RELAY.md" ] && pass "GH-117: missing reviewer — relay file never rendered" \
test/marathon-drive.sh:819:printf '\n### Round 1 · Builder · %s (stub)\nVERDICT: FAIL\nBasis: test builder\n' "$RELAY_AGENT" >> "$PWD/phases/p1/RELAY.md"
test/marathon-drive.sh:832:printf '\n### Round 2 · Reviewer · %s (stub)\n**Verdict:** Changes requested\nBasis: test reviewer\n' "$RELAY_AGENT" >> "$PWD/phases/p1/RELAY.md"
test/marathon-drive.sh:917:printf '\n### Round 1 · Builder · %s (stub)\nImplemented: test builder update\n' "$RELAY_AGENT" >> "$PWD/phases/p1/RELAY.md"
test/marathon-drive.sh:930:sed -i.bak 's/^STATUS:[[:space:]]*.*/STATUS: Approved/' "$PWD/phases/p1/RELAY.md"; rm -f "$PWD/phases/p1/RELAY.md.bak"
test/marathon-drive.sh:931:printf '\n### Round 2 · Reviewer · %s (stub)\n**Verdict:** Approved\nBasis: test reviewer\n' "$RELAY_AGENT" >> "$PWD/phases/p1/RELAY.md"
test/marathon-drive.sh:1017:DEFAULT_BUILDER_OUT="$(RELAY_DRIVE_EXIT=0 MARATHON_ROOT="$A" MARATHON_RELAY_DRIVE="$STUB_RD" \
test/marathon-drive.sh:1020:  bash "$DRIVER" --phases-dir "$A/phases" --phase-brief "$BRIEF" --reviewer agy \
test/marathon-drive.sh:1024:grep -q "TAKE YOUR TURN.*codex.*BUILDER" "$A/phases/p1/RELAY.md" 2>/dev/null \

exec
/bin/zsh -lc "git status --short
git diff -- .gitignore test/marathon-root-audit.sh PROJECT/1-INBOX/GH-484-MARATHONS-DEFAULT.md
git log -1 --format='%H%n%s%n%b' -- .gitignore test/marathon-root-audit.sh
rg -n --glob '"'!temp/**'"' --glob '"'!PROJECT/**'"' --glob '"'!relay-system/**'"' --glob '"'!phases/**'"' 'marathon-ls\\.sh|marathon-detail\\.sh' .
rg -n -i --glob '"'!temp/**'"' --glob '"'!PROJECT/**'"' --glob '"'!relay-system/**'"' --glob '"'!phases/**'"' 'marathon\\.sh.*phases-dir|phases-dir.*marathon\\.sh|ROOT/phases|repo/phases' README.md relay-automation skills utils test | head -500" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-67768-b0m00j9w
2026-08-10T04:59:46.744978Z ERROR codex_models_manager::manager: failed to renew cache TTL: missing field `base_instructions` at line 95 column 5
 succeeded in 7686ms:
2026-08-09 21:59:39.285 xcodebuild[76786:95524552]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-08-09 21:59:39.527 xcodebuild[76786:95524551] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.
git: warning: confstr() failed with code 5: couldn't get path of DARWIN_USER_TEMP_DIR; using /tmp instead
git: error: couldn't create cache file '/tmp/xcrun_db-AgUYTjXQ' (errno=Operation not permitted)
2026-08-09 21:59:40.222 xcodebuild[76790:95524580]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-08-09 21:59:40.439 xcodebuild[76790:95524579] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.
?? PROJECT/1-INBOX/GH-314-VENDOR-GITIGNORE-HALT.md
?? PROJECT/1-INBOX/GH-439-SAME-REPO-WORKTREE-SPLIT.md
?? PROJECT/1-INBOX/GH-440-VENDOR-TICK-GITIGNORE.md
?? PROJECT/1-INBOX/GH-484-MARATHONS-DEFAULT.md
?? relay-system/2026-08-09/
git: warning: confstr() failed with code 5: couldn't get path of DARWIN_USER_TEMP_DIR; using /tmp instead
git: error: couldn't create cache file '/tmp/xcrun_db-y38qkJdB' (errno=Operation not permitted)
2026-08-09 21:59:41.876 xcodebuild[76880:95524809]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-08-09 21:59:42.063 xcodebuild[76880:95524808] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.
git: warning: confstr() failed with code 5: couldn't get path of DARWIN_USER_TEMP_DIR; using /tmp instead
git: error: couldn't create cache file '/tmp/xcrun_db-UpyfmrNG' (errno=Operation not permitted)
2026-08-09 21:59:42.729 xcodebuild[76944:95524959]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-08-09 21:59:42.936 xcodebuild[76944:95524935] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.
git: warning: confstr() failed with code 5: couldn't get path of DARWIN_USER_TEMP_DIR; using /tmp instead
git: error: couldn't create cache file '/tmp/xcrun_db-IXfKID1n' (errno=Operation not permitted)
2026-08-09 21:59:44.428 xcodebuild[76975:95525136]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-08-09 21:59:44.632 xcodebuild[76975:95525135] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.
git: warning: confstr() failed with code 5: couldn't get path of DARWIN_USER_TEMP_DIR; using /tmp instead
git: error: couldn't create cache file '/tmp/xcrun_db-EmPc6Cpa' (errno=Operation not permitted)
2026-08-09 21:59:45.277 xcodebuild[77138:95525425]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-08-09 21:59:45.481 xcodebuild[77138:95525419] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.
1e952857c20acdd34984c5a7f3e0048e347115e8
WIP on development: 7b4b7e4 fix(GH-480): card titles were wrapping one character per line

./ROADMAP.md:102:- **GH-354 · concurrent swarms: the driver lock blocks 1 of 3 pairs, and the monitors can't see the one it does** 🟡 **active — Phase 0 discovery complete 2026-07-30; Phase 1 (relay-drive worktree lock) next** — review of [#354](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/354)'s own analysis, which reasoned about `relay-drive.sh`/`relay-turn-lib.sh` from `marathon-drive.sh`'s comments because it lacked the files. Reading them overturns the conclusion's basis: `relay-drive` never received GH-49b's linked-worktree lock branch on **either** runtime (`relay-drive.sh:147-152`, `utils/py/relay_drive.py:386-391`), so it takes a per-worktree lock while `marathon-drive` takes a shared one — marathon↔marathon excludes, marathon↔relay and relay↔relay silently do **not**, the second being two drivers on one working tree with no guard at all. Also overturned: `.tick/` task ids, lane attempt counters and `tick analyze` cost do **not** commingle across linked worktrees (`TICK_REPO_ROOT` defaults to each shim's own `ROOT`), deleting 3 of #354's 5 collision claims and the `.tick`-namespacing work it proposed. #354's one-line observability footnote is escalated to a phase: the false-IDLE is in **three** monitors (`marathon-ls.sh:44-50`, `utils/hq/marathon-live.sh:94-95`, `utils/hq/hourly-global-scan.sh:28`), so the operator's every window onto the lock state is blind in exactly the shape under discussion. Separate full clones remains the right operator answer — for a different reason than #354 gave. Plan does **not** enable parallelism: Phases 1–3 make the exclusion contract true, provable and observable; Phase 4 is a GO/NO-GO gate whose first criterion is that nobody has ever written down the GH-42 `ROOT@HEAD` mechanism. cx/risk/eff 4/3/3. → [GH-354-CONCURRENT-SWARMS.md](PROJECT/2-WORKING/GH-354-CONCURRENT-SWARMS.md) · [#354](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/354)
./test/swarm-preflight.sh:537:    { "type": "path_absent", "path": "relay-automation/marathon-ls.sh" },
./test/swarm-preflight.sh:538:    { "type": "path_absent", "path": "relay-automation/marathon-detail.sh" },
./test/swarm-preflight.sh:543:    "relay-automation/marathon-ls.sh",
./test/swarm-preflight.sh:544:    "relay-automation/marathon-detail.sh",
./test/swarm-preflight.sh:549:    "relay-automation/marathon-ls.sh",
./test/swarm-preflight.sh:550:    "relay-automation/marathon-detail.sh",
./test/marathon-monitor.sh:2:# test/marathon-monitor.sh — dependency-free tests for marathon-ls.sh.
./test/marathon-monitor.sh:19:LS="$HERE/../relay-automation/marathon-ls.sh"
./test/marathon-monitor.sh:108:# Delete the path now so marathon-ls.sh sees it as GONE.
./test/marathon-monitor.sh:112:# Run marathon-ls.sh with our fake registry
./test/marathon-monitor.sh:181:  "$HERE/../relay-automation/marathon-ls.sh"
./test/marathon-monitor.sh:182:  "$HERE/../relay-automation/marathon-detail.sh"
./relay-automation/marathon-ls.sh:2:# marathon-ls.sh — cross-repo marathon monitor engine (read-only).
./relay-automation/marathon-tui.sh:4:# Pipes marathon-ls.sh into fzf with a ~2s auto-refresh and a preview pane
./relay-automation/marathon-tui.sh:5:# powered by marathon-detail.sh. Field 1 of each row is the repo path.
./relay-automation/marathon-tui.sh:20:LS_SCRIPT="$SELF_DIR/marathon-ls.sh"
./relay-automation/marathon-tui.sh:21:DETAIL_SCRIPT="$SELF_DIR/marathon-detail.sh"
./relay-automation/marathon-tui.sh:37:#   --preview                 marathon-detail.sh on the selected repo (field 1)
./relay-automation/marathon-detail.sh:2:# marathon-detail.sh <repo> — preview for ONE repo path (read-only).
./relay-automation/marathon-detail.sh:12:  printf 'Usage: marathon-detail.sh <repo-path>\n' >&2
relay-automation/marathon-drive.sh:679:PHASES_DIR="${PHASES_DIR:-"$ROOT/phases"}"
test/gh457-gate-tiers.sh:119:    --phases-dir "$ROOT/phases" \
test/gh457-gate-tiers.sh:125:esc_reason() { sed -n 's/^reason: //p' "$ROOT/phases/$1/ESCALATION.md" 2>/dev/null; }
test/gh390-gate-guard.sh:98:    --phases-dir "$ROOT/phases" \
test/gh390-gate-guard.sh:106:  sed -n 's/^reason: //p' "$ROOT/phases/$1/ESCALATION.md" 2>/dev/null
test/gh401-dry-run-no-mutation.sh:56:[ ! -e "$MROOT/phases" ] \
test/gh401-dry-run-no-mutation.sh:58:  || fail "--dry-run created $MROOT/phases — the mkdir is back above the dry-run exit"
relay-automation/marathon.sh:15:#   relay-automation/marathon.sh --plan MARATHON.yaml [--builder codex] [--phases-dir DIR]
relay-automation/marathon.sh:84:Usage: marathon.sh --plan MARATHON.yaml [--builder A] [--phases-dir D] [--pre-advance-cmd C]
relay-automation/marathon.sh:167:PHASES_DIR="${PHASES_DIR:-"$ROOT/phases"}"
relay-automation/marathon-detail.sh:40:PHASES_DIR="$REPO/phases"
relay-automation/marathon-ls.sh:113:  local phases_dir="$repo/phases"
test/marathon.sh:273:   && "$vendored_phases" == "$vendored_root/phases" \
test/gh319-gate-path-with-space.sh:93:    --phases-dir "$ROOT/phases" \
test/gh407-gate-ran-attribution.sh:75:    --phases-dir "$ROOT/phases" \
test/gh407-gate-ran-attribution.sh:81:esc_field() { sed -n "s/^$2: //p" "$ROOT/phases/$1/ESCALATION.md" 2>/dev/null; }
test/gh407-gate-ran-attribution.sh:169:rm -rf "$PRE_ROOT/phases"
test/gh407-gate-ran-attribution.sh:175:  bash "$PRE_DRIVER" --phases-dir "$PRE_ROOT/phases" --phase-brief "$BRIEF" \
test/gh407-gate-ran-attribution.sh:178:pre_reason="$(sed -n 's/^reason: //p' "$PRE_ROOT/phases/no-gate/ESCALATION.md" 2>/dev/null)"
test/gh407-gate-ran-attribution.sh:179:pre_gate="$(sed -n 's/^gate: //p' "$PRE_ROOT/phases/no-gate/ESCALATION.md" 2>/dev/null)"
test/marathon-monitor.sh:42:  mkdir -p "$repo/.git" "$repo/.tick/events" "$repo/phases/p1"
test/marathon-monitor.sh:48:  mkdir -p "$repo/.tick/events" "$repo/phases/p1"

exec
/bin/zsh -lc "nl -ba test/marathon.sh | sed -n '230,285p'
nl -ba test/marathon-monitor.sh | sed -n '1,130p;165,195p'
nl -ba test/gh401-dry-run-no-mutation.sh | sed -n '1,75p'
nl -ba relay-automation/marathon-tui.sh | sed -n '1,65p'
rg -n --glob '*.py' --glob '*.sh' --glob '"'!temp/**'"' --glob '"'!PROJECT/**'"' --glob '"'!relay-system/**'"' --glob '"'!phases/**'"' 'os\\.path\\.join\\(["'^'"\\n]*(phase|PHASE)|\\"'$'"\\{?[A-Za-z_]+\\}?/phase|phase[s]?_dir|PHASES_DIR' utils relay-automation | head -1000" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-67768-b0m00j9w
 succeeded in 0ms:
   230	printf '.tick/\n.xyz/.tick/\n' > "$V/.gitignore"
   231	printf 'brief for vendored p1\n' > "$V/briefs-p1.tmp"
   232	mkdir -p "$V/briefs" "$V/PROJECT/2-WORKING"
   233	mv "$V/briefs-p1.tmp" "$V/briefs/p1.md"
   234	cat > "$V/PROJECT/2-WORKING/vendored.yaml" <<'YAML'
   235	name: vendored
   236	phases:
   237	  - id: p1
   238	    reviewer: codex
   239	    brief: briefs/p1.md
   240	YAML
   241	mkdir -p "$V/.xyz"
   242	cp -R "$REPO/relay-automation" "$V/.xyz/"
   243	cp -R "$REPO/bin" "$V/.xyz/"
   244	cp -R "$REPO/src" "$V/.xyz/"
   245	cp -R "$REPO/utils" "$V/.xyz/"
   246	cat > "$V/.xyz/relay-automation/marathon-drive.sh" <<STUB
   247	#!/usr/bin/env bash
   248	set -eu
   249	phase_brief=""; phases_dir=""
   250	while ((\$#)); do
   251	  case "\$1" in
   252	    --phase-brief) phase_brief="\$2"; shift 2 ;;
   253	    --phases-dir)  phases_dir="\$2"; shift 2 ;;
   254	    *)             shift ;;
   255	  esac
   256	done
   257	printf '%s|%s|%s|%s\n' "\$phase_brief" "\$phases_dir" "\${MARATHON_ROOT:-}" "\${TICK_BIN:-}" >> "$WORK/vendored-drive-ran"
   258	exit 0
   259	STUB
   260	chmod +x "$V/.xyz/relay-automation/marathon-drive.sh"
   261	rm -f "$WORK/vendored-drive-ran"; rm -rf "$V/.tick"
   262	(
   263	  cd "$V"
   264	  unset MARATHON_HOME MARATHON_ROOT MARATHON_DRIVE MARATHON_YAML_BIN TICK_BIN XYZ_APPEND_BIN
   265	  ./.xyz/relay-automation/marathon.sh --plan PROJECT/2-WORKING/vendored.yaml
   266	) >/dev/null 2>&1
   267	rc=$?
   268	[ "$rc" -eq 0 ] && pass "GH-206: vendored marathon.sh runs with zero env overrides" \
   269	  || fail "GH-206: vendored marathon.sh exit=$rc"
   270	IFS='|' read -r vendored_brief vendored_phases vendored_root vendored_tick < "$WORK/vendored-drive-ran"
   271	vendored_tick_home="$(cd "$(dirname "$vendored_tick")/.." && pwd -P)"
   272	[[ "$vendored_brief" == "$vendored_root/briefs/p1.md" \
   273	   && "$vendored_phases" == "$vendored_root/phases" \
   274	   && "$vendored_root" == "$(git -C "$V" rev-parse --show-toplevel)" \
   275	   && "$vendored_tick_home" == "$vendored_root/.xyz" \
   276	   && "$vendored_tick" != "$vendored_root/bin/tick" ]] \
   277	  && pass "GH-206: vendored run resolves repo-local briefs/phases separately from harness-local tick" \
   278	  || fail "GH-206: vendored root split wrong: [$(cat "$WORK/vendored-drive-ran" 2>/dev/null)]"
   279	ls "$V/.tick/events/" 2>/dev/null | grep -q "marathon.complete" \
   280	  && pass "GH-206: vendored run emits marathon.complete in the consumer repo tick log" \
   281	  || fail "GH-206: vendored run missing consumer repo marathon.complete"
   282	
   283	# --- (12) GH-212: a plan outside PROJECT/2-WORKING/ is refused by default -------
   284	rm -f "$WORK/phases-ran"; rm -rf "$A/.tick"
   285	printf 'name: outside\nphases:\n  - id: p1\n    reviewer: codex\n    brief: briefs/p1.md\n' > "$A/outside.yaml"
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
    41	  local repo="$1"
    42	  mkdir -p "$repo/.git" "$repo/.tick/events" "$repo/phases/p1"
    43	}
    44	
    45	make_vendored_repo() {
    46	  # make_vendored_repo <path> — create a fake "vendored" repo (no .git/)
    47	  local repo="$1"
    48	  mkdir -p "$repo/.tick/events" "$repo/phases/p1"
    49	}
    50	
    51	write_marathon_event() {
    52	  # write_marathon_event <repo> <type> [<ts>]
    53	  local repo="$1" type="$2" ts="${3:-2026-07-02T00:00:00.000Z}"
    54	  local events_dir="$repo/.tick/events"
    55	  mkdir -p "$events_dir"
    56	  # Use a fixed filename that matches *marathon*.jsonl.
    57	  local f="$events_dir/marathon-DRIVE.jsonl"
    58	  printf '{"type":"%s","ts":"%s"}\n' "$type" "$ts" >> "$f"
    59	}
    60	
    61	# ---------------------------------------------------------------------------
    62	# Build fake registry.tsv
    63	# ---------------------------------------------------------------------------
    64	REGISTRY="$D/registry.tsv"
    65	# Columns: install_dir  last_install_utc  tick_version  source_commit  coordinated_repo
    66	# Header line.
    67	printf 'install_dir\tlast_install_utc\ttick_version\tsource_commit\tcoordinated_repo\n' > "$REGISTRY"
    68	
    69	# We will add rows after creating fixtures below.
    70	
    71	# ---------------------------------------------------------------------------
    72	# Fixture 1: LIVE — normal clone (.git/) + live PID
    73	# ---------------------------------------------------------------------------
    74	REPO_LIVE="$D/repo-live"
    75	make_clone_repo "$REPO_LIVE"
    76	write_marathon_event "$REPO_LIVE" "marathon.start"
    77	# Create .git/relay-driver.lock/pid with our own PID (definitely alive).
    78	mkdir -p "$REPO_LIVE/.git/relay-driver.lock"
    79	printf '%s\n' "$$" > "$REPO_LIVE/.git/relay-driver.lock/pid"
    80	printf '%s\t2026-07-02\tv1\tabc\t%s\n' "$REPO_LIVE/.xyz" "$REPO_LIVE" >> "$REGISTRY"
    81	
    82	# ---------------------------------------------------------------------------
    83	# Fixture 2: STALE — vendored (.relay-driver.lock/) + dead PID
    84	# ---------------------------------------------------------------------------
    85	REPO_STALE="$D/repo-stale"
    86	make_vendored_repo "$REPO_STALE"
    87	write_marathon_event "$REPO_STALE" "marathon.start"
    88	# Create .relay-driver.lock/pid with a dead PID.
    89	mkdir -p "$REPO_STALE/.relay-driver.lock"
    90	printf '%s\n' "999999" > "$REPO_STALE/.relay-driver.lock/pid"
    91	printf '%s\t2026-07-02\tv1\tabc\t%s\n' "$REPO_STALE/.xyz" "$REPO_STALE" >> "$REGISTRY"
    92	
    93	# ---------------------------------------------------------------------------
    94	# Fixture 3: IDLE — clone, no lock, marathon.complete event
    95	# ---------------------------------------------------------------------------
    96	REPO_IDLE="$D/repo-idle"
    97	make_clone_repo "$REPO_IDLE"
    98	write_marathon_event "$REPO_IDLE" "marathon.complete" "2026-07-02T12:00:00.000Z"
    99	# No lock directory.
   100	printf '%s\t2026-07-02\tv1\tabc\t%s\n' "$REPO_IDLE/.xyz" "$REPO_IDLE" >> "$REGISTRY"
   101	
   102	# ---------------------------------------------------------------------------
   103	# Fixture 4: GONE — path that we will delete before running the check
   104	# ---------------------------------------------------------------------------
   105	REPO_GONE="$D/repo-gone"
   106	make_clone_repo "$REPO_GONE"
   107	printf '%s\t2026-07-02\tv1\tabc\t%s\n' "$REPO_GONE/.xyz" "$REPO_GONE" >> "$REGISTRY"
   108	# Delete the path now so marathon-ls.sh sees it as GONE.
   109	rm -rf "$REPO_GONE"
   110	
   111	# ---------------------------------------------------------------------------
   112	# Run marathon-ls.sh with our fake registry
   113	# ---------------------------------------------------------------------------
   114	OUTPUT="$(XYZ_REGISTRY="$REGISTRY" bash "$LS" 2>/dev/null || true)"
   115	
   116	# Helper: get the STATE column (col 2) for a given repo path.
   117	state_for() {
   118	  local repo="$1"
   119	  printf '%s' "$OUTPUT" | awk -F'\t' -v r="$repo" '$1 == r { print $2 }'
   120	}
   121	
   122	# ---------------------------------------------------------------------------
   123	# Assertions
   124	# ---------------------------------------------------------------------------
   125	
   126	# (a) BOTH lock-path cases (LIVE uses .git/ clone; STALE uses vendored no-.git/)
   127	LIVE_STATE="$(state_for "$REPO_LIVE")"
   128	[ "$LIVE_STATE" = "LIVE" ] \
   129	  && pass "LIVE: clone with .git/relay-driver.lock + live pid -> LIVE" \
   130	  || fail "LIVE: expected LIVE, got '${LIVE_STATE}' (repo=$REPO_LIVE)"
   165	[ -d "$REPO_LIVE/.git/relay-driver.lock" ] \
   166	  && pass "LIVE fixture has .git/relay-driver.lock (clone path)" \
   167	  || fail "LIVE fixture missing .git/relay-driver.lock"
   168	
   169	[ ! -d "$REPO_STALE/.git" ] \
   170	  && pass "STALE fixture has no .git/ (vendored path)" \
   171	  || fail "STALE fixture unexpectedly has .git/"
   172	
   173	[ -d "$REPO_STALE/.relay-driver.lock" ] \
   174	  && pass "STALE fixture has .relay-driver.lock (vendored path)" \
   175	  || fail "STALE fixture missing .relay-driver.lock"
   176	
   177	# ---------------------------------------------------------------------------
   178	# bash -n syntax check on all 4 scripts
   179	# ---------------------------------------------------------------------------
   180	SCRIPTS=(
   181	  "$HERE/../relay-automation/marathon-ls.sh"
   182	  "$HERE/../relay-automation/marathon-detail.sh"
   183	  "$HERE/../relay-automation/marathon-tui.sh"
   184	  "$HERE/marathon-monitor.sh"
   185	)
   186	for s in "${SCRIPTS[@]}"; do
   187	  if bash -n "$s" 2>/dev/null; then
   188	    pass "syntax OK: $(basename "$s")"
   189	  else
   190	    fail "syntax error in: $s"
   191	  fi
   192	done
   193	
   194	# ---------------------------------------------------------------------------
   195	printf '\nmarathon-monitor: %d pass, %d fail\n' "$PASS" "$FAIL"
     1	#!/usr/bin/env bash
     2	# test/gh401-dry-run-no-mutation.sh — GH-401 regression.
     3	# gate-evidence: {"form":"pre-fix-replay","observed":true,"result":"reproducer: bash test/gh401-dry-run-no-mutation.sh; pre-fix revision: marathon_drive.py before d4999cd, where os.makedirs + the RELAY.md write ran ABOVE the dry-run exit; pre-fix result: --dry-run created phases/p1/ and wrote RELAY.md, leaving the marathon root's git status dirty; post-fix result: 4/0 — status byte-identical, no phases/ directory, and the positive control confirms the render still happens and is reported"}
     4	#
     5	# `marathon-drive --dry-run` used to RENDER AND WRITE phases/<id>/RELAY.md before reaching its exit,
     6	# so a dry run mutated the working tree. Unscoped (no MARATHON_ROOT, no --phases-dir) that landed on
     7	# the HARNESS repo's own tracked phases/p1/RELAY.md: `bash validate.sh` left the tree dirty, the diff
     8	# churned to a different value on every machine (it embeds the absolute bin/tick path), and the
     9	# rendered artifact was committed at least once that way (f83b929, #325).
    10	#
    11	# A dry run being side-effect free is the entire contract of the flag, and it is the flag someone
    12	# reaches for precisely when they are unsure what a command will do.
    13	#
    14	# WHY A FIXTURE ROOT, NOT THE UNSCOPED REPRO: the write is unconditional on which root it resolves to,
    15	# so aiming the same code path at a throwaway MARATHON_ROOT proves the same property — and a
    16	# regression can never dirty the real repo just by running the suite (which is how the polluted file
    17	# got committed in the first place). The static half of this fix — that no test invokes the driver
    18	# unscoped at all — is test/marathon-root-audit.sh, whose scope GH-401 widened from two hardcoded
    19	# filenames to every test script.
    20	source "$(dirname "$0")/_setup.sh" gh401-dry-run-no-mutation
    21	ROOT="$(cd "$(dirname "$0")/.." && pwd)"
    22	DRV="$ROOT/relay-automation/marathon-drive.sh"
    23	
    24	mk_repo() {  # <dir>
    25	  mkdir -p "$1"; git init -q "$1"
    26	  git -C "$1" config user.email gh401@t; git -C "$1" config user.name gh401
    27	  printf 'x\n' > "$1/seed.txt"
    28	  git -C "$1" add -A >/dev/null 2>&1; git -C "$1" commit -q -m init
    29	}
    30	
    31	MROOT="$WORK/mroot"; mk_repo "$MROOT"
    32	TGT="$WORK/target";  mk_repo "$TGT"
    33	BRIEF="$WORK/brief.md"; printf '## brief\nbody\n' > "$BRIEF"
    34	
    35	# GH-117: the driver probes the builder/reviewer binaries BEFORE rendering, and exits 2 when one is
    36	# missing. The first version of this test named `--builder codex` with nothing stubbed: it passed on
    37	# a developer Mac with codex installed and exited 2 on the ubuntu CI runner, where it is not on PATH,
    38	# so the dry-run render under test was never reached. Caught by CI, not locally. Stub both and pin
    39	# --builder claude, the same convention test/marathon-drive.sh (GH-212/GH-232) and debug-mantra.sh
    40	# use — a test of the render must not depend on which agents happen to be installed on the host.
    41	STUB_CLAUDE="$WORK/stub-claude"; printf '#!/usr/bin/env bash\nexit 0\n' > "$STUB_CLAUDE"; chmod +x "$STUB_CLAUDE"
    42	STUB_AGY="$WORK/stub-agy"; printf '#!/usr/bin/env bash\nexit 0\n' > "$STUB_AGY"; chmod +x "$STUB_AGY"
    43	
    44	before="$(git -C "$MROOT" status --porcelain)"
    45	out="$(MARATHON_ROOT="$MROOT" CLAUDE_BIN="$STUB_CLAUDE" AGY_BIN="$STUB_AGY" \
    46	        bash "$DRV" --target-root "$TGT" --phase-brief "$BRIEF" \
    47	        --reviewer agy --builder claude --dry-run 2>&1)"; rc=$?
    48	after="$(git -C "$MROOT" status --porcelain)"
    49	
    50	[ "$rc" -eq 0 ] && pass "--dry-run exits 0" || fail "--dry-run exited $rc: $out"
    51	
    52	[ "$before" = "$after" ] \
    53	  && pass "--dry-run leaves the marathon root's git status unchanged" \
    54	  || fail "--dry-run dirtied the marathon root (porcelain: $after)"
    55	
    56	[ ! -e "$MROOT/phases" ] \
    57	  && pass "--dry-run creates no phases/ directory" \
    58	  || fail "--dry-run created $MROOT/phases — the mkdir is back above the dry-run exit"
    59	
    60	# POSITIVE CONTROL. Without this the two assertions above would also pass for a driver that died
    61	# long before the render — "nothing was written" would prove nothing about the write being skipped
    62	# deliberately. This repo has shipped three separate assertions that could not fail (#333, #348,
    63	# #351); an assertion whose green state has two explanations is the same defect in slower motion.
    64	printf '%s' "$out" | grep -Fq "would be rendered" \
    65	  && pass "--dry-run still performs the render and reports it (the write, and only the write, is skipped)" \
    66	  || fail "--dry-run printed no render report — it exited before the render, so the no-mutation assertions above are vacuous: $out"
    67	
    68	exit 0
     1	#!/usr/bin/env bash
     2	# marathon-tui.sh — interactive cross-repo marathon monitor (fzf TUI).
     3	#
     4	# Pipes marathon-ls.sh into fzf with a ~2s auto-refresh and a preview pane
     5	# powered by marathon-detail.sh. Field 1 of each row is the repo path.
     6	#
     7	# Requires: fzf (brew install fzf)
     8	# Writes NO state anywhere.
     9	set -euo pipefail
    10	
    11	# Resolve sibling script paths relative to this script's directory.
    12	_src="${BASH_SOURCE[0]}"
    13	while [ -h "$_src" ]; do
    14	  _dir="$(cd -P "$(dirname "$_src")" >/dev/null 2>&1 && pwd)"
    15	  _src="$(readlink "$_src")"
    16	  case "$_src" in /*) ;; *) _src="$_dir/$_src" ;; esac
    17	done
    18	SELF_DIR="$(cd -P "$(dirname "$_src")" >/dev/null 2>&1 && pwd)"
    19	
    20	LS_SCRIPT="$SELF_DIR/marathon-ls.sh"
    21	DETAIL_SCRIPT="$SELF_DIR/marathon-detail.sh"
    22	
    23	# Guard: fzf must be installed.
    24	if ! command -v fzf >/dev/null 2>&1; then
    25	  printf 'marathon-tui.sh: fzf is not installed.\n' >&2
    26	  printf 'Install it with:  brew install fzf\n' >&2
    27	  exit 1
    28	fi
    29	
    30	[ -f "$LS_SCRIPT" ]     || { printf 'marathon-tui.sh: missing %s\n' "$LS_SCRIPT" >&2; exit 1; }
    31	[ -f "$DETAIL_SCRIPT" ] || { printf 'marathon-tui.sh: missing %s\n' "$DETAIL_SCRIPT" >&2; exit 1; }
    32	
    33	# Run fzf:
    34	#   --header-lines=1          treat the TSV header row as a sticky header
    35	#   --delimiter='\t'          split on tabs so {1} is the REPO column
    36	#   --reload-sync / load      auto-reload every ~2 s (fzf 0.35+ bind syntax)
    37	#   --preview                 marathon-detail.sh on the selected repo (field 1)
    38	bash "$LS_SCRIPT" | fzf \
    39	  --header-lines=1 \
    40	  --delimiter=$'\t' \
    41	  --with-nth='1,2,3,4,5' \
    42	  --bind "load:reload-sync(sleep 2; bash '$LS_SCRIPT')" \
    43	  --bind "change:reload-sync(bash '$LS_SCRIPT')" \
    44	  --preview "bash '$DETAIL_SCRIPT' {1}" \
    45	  --preview-window='right:50%:wrap' \
    46	  --prompt='marathon> ' \
    47	  --info=inline \
    48	  --ansi
relay-automation/marathon-drive.sh:141:  local prior="$1" phase_dir="$2" mantra_file="$3" reason=""
relay-automation/marathon-drive.sh:143:  [ -f "$phase_dir/ESCALATION.md" ] && reason="$(sed -n 's/^reason:[[:space:]]*//p' "$phase_dir/ESCALATION.md" | head -1)"
relay-automation/marathon-drive.sh:147:    printf 'Last recorded reason (%s/ESCALATION.md): `%s`. Read it before re-guessing.\n' "$phase_dir" "$reason"
relay-automation/marathon-drive.sh:633:PHASES_DIR=""        # resolved to default after ROOT is set
relay-automation/marathon-drive.sh:654:    --phases-dir)      PHASES_DIR="${2:-}"; shift 2 ;;
relay-automation/marathon-drive.sh:679:PHASES_DIR="${PHASES_DIR:-"$ROOT/phases"}"
relay-automation/marathon-drive.sh:833:PHASE_DIR="$PHASES_DIR/$LANE_STATE_KEY"
relay-automation/marathon-detail.sh:40:PHASES_DIR="$REPO/phases"
relay-automation/marathon-detail.sh:42:if [ -d "$PHASES_DIR" ]; then
relay-automation/marathon-detail.sh:44:  RELAY_FILE="$(ls -t "$PHASES_DIR"/*/RELAY.md 2>/dev/null | head -1 || true)"
relay-automation/marathon-ls.sh:113:  local phases_dir="$repo/phases"
relay-automation/marathon-ls.sh:114:  [ -d "$phases_dir" ] || { printf '-'; return 0; }
relay-automation/marathon-ls.sh:117:  f="$(ls -t "$phases_dir"/*/RELAY.md 2>/dev/null | head -1 || true)"
relay-automation/marathon.sh:111:PLAN=""; BUILDER="codex"; PHASES_DIR=""; PRE_ADVANCE_CMD=""; DRY_RUN=0; FORCE=0; RETRY_PHASE=""; CLOSEOUT_PR=0
relay-automation/marathon.sh:117:    --phases-dir)      PHASES_DIR="${2:-}"; shift 2 ;;
relay-automation/marathon.sh:167:PHASES_DIR="${PHASES_DIR:-"$ROOT/phases"}"
relay-automation/marathon.sh:200:               --phase-brief "$brief_path" --round-cap "$cap" --phases-dir "$PHASES_DIR" )
utils/py/marathon_drive.py:383:    parser.add_argument("--phases-dir", dest="phases_dir")
utils/py/marathon_drive.py:523:    def debug_mantra_note(prior, phase_dir_, mantra_file):
utils/py/marathon_drive.py:529:        esc = os.path.join(phase_dir_, "ESCALATION.md")
utils/py/marathon_drive.py:564:        phase_rel = _rel(phase_dir_, root)
utils/py/marathon_drive.py:570:            out += (f"Last recorded reason (`{os.path.join(phase_rel, 'ESCALATION.md')}`): `{reason}`. "
utils/py/marathon_drive.py:687:    phases_dir = args.phases_dir or os.path.join(root, "phases")
utils/py/marathon_drive.py:1136:    phase_dir = os.path.join(phases_dir, lane_state_key)
utils/py/marathon_drive.py:1137:    relay_file = os.path.join(phase_dir, "RELAY.md")
utils/py/marathon_drive.py:1172:        esc_file = os.path.join(phase_dir, "ESCALATION.md")
utils/py/marathon_drive.py:1217:        dest = os.path.join(date_dir, f"marathon-{args.phase_id}-{now.strftime('%H%M%S')}.md")
utils/py/marathon_drive.py:1687:        debug_mantra_prior, phase_dir, os.path.join(xyz_harness, "relay-automation", "DEBUG-MANTRA.md"))
utils/py/marathon_drive.py:1778:    os.makedirs(phase_dir, exist_ok=True)

2026-08-10T04:59:53.665136Z ERROR codex_models_manager::manager: failed to renew cache TTL: missing field `supports_reasoning_summaries` at line 87 column 5
exec
/bin/zsh -lc "nl -ba relay-automation/marathon-drive.sh | sed -n '1,28p'
nl -ba test/gh308-frozen-twin-guard.sh | sed -n '54,71p;237,286p'
nl -ba PROJECT/1-INBOX/GH-484-MARATHONS-DEFAULT.md | sed -n '19,67p;90,150p'
rg -n --glob '"'!temp/**'"' --glob '"'!PROJECT/**'"' --glob '"'!relay-system/**'"' --glob '"'!phases/**'"' 'MARATHON_ROOT|MARATHON_HOME|marathon\\.sh|marathon-drive\\.sh' skills/marathon-triage/SKILL.md skills/file-xyz-bug/SKILL.md README.md relay-automation/README.md relay-automation/CONTRACT.example.md ARCHITECTURE.md 2>/dev/null" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-67768-b0m00j9w
 succeeded in 0ms:
     1	#!/usr/bin/env bash
     2	# FROZEN (GH-308): Python is authoritative — do not make behavior changes here.
     3	# Historical Bash fallback only; update utils/py/marathon_drive.py instead. See issue #308.
     4	set -euo pipefail
     5	
     6	# GH-112 opt-in Python mode: XYZ_PYTHON=1 reroutes this entry point to the Python port in
     7	# utils/py/ (same CLI contract + exit codes). Default (unset/0) runs the canonical Bash
     8	# implementation below — Bash stays the supported default until the port is promoted.
     9	if [[ "${XYZ_PYTHON-1}" == "1" ]]; then
    10	  # UPGRADE.md §4 Phase-2 hardening (GH-255): (2a) `-` not `:-` so an explicit empty XYZ_PYTHON reads
    11	  # as not-1 → Bash (load-bearing once the default flips to 1); (2b) require python3 >=3.8 and fall
    12	  # back to Bash with a warning if it's missing/too-old, so a bad interpreter degrades, not bricks.
    13	  if command -v python3 >/dev/null 2>&1 \
    14	     && python3 -c 'import sys; raise SystemExit(0 if sys.version_info >= (3,8) else 1)' 2>/dev/null; then
    15	    _xyz_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
    16	    export XYZ_ROOT="$_xyz_root"
    17	    export PYTHONPATH="$_xyz_root/utils/py${PYTHONPATH:+:$PYTHONPATH}"
    18	    exec python3 "$_xyz_root/utils/py/marathon_drive.py" "$@"
    19	  else
    20	    echo "xyz: XYZ_PYTHON=1 but python3 missing or < 3.8 — falling back to Bash" >&2
    21	  fi
    22	fi
    23	#
    24	# marathon-drive.sh — Phase 3: single-phase headless relay loop.
    25	#
    26	# Renders phases/p1/RELAY.md from the phase brief, seeds the tick token (handoff → builder),
    27	# calls relay-drive.sh unmodified, runs the pre-advance gate, emits phase events, and saves
    28	# the transcript. Does NOT reimplement any loop logic — relay-drive.sh IS the loop.
    54	check_changes() {
    55	  local -a paths=()
    56	  local pair
    57	  for pair in "${TWINS[@]}"; do paths+=("${pair%%:*}"); done
    58	  local changed
    59	  if (( staged )); then
    60	    changed="$(git -C "$ROOT" diff --cached --name-only -- "${paths[@]}")"
    61	  else
    62	    [[ -n "$base" ]] || { echo 'gh308 guard: --check needs --staged or --base REV' >&2; return 2; }
    63	    git -C "$ROOT" rev-parse --verify "${base}^{commit}" >/dev/null
    64	    changed="$(git -C "$ROOT" diff --name-only "${base}..HEAD" -- "${paths[@]}")"
    65	  fi
    66	  if [[ -n "$changed" ]]; then
    67	    printf 'gh308 guard: FROZEN Bash twin edit blocked; change its Python twin instead:\n%s\n' "$changed" >&2
    68	    return 1
    69	  fi
    70	  echo 'gh308 guard: no frozen Bash twin changed'
    71	}
   237	check_exception_coverage() {  # <base> — called only after check_changes has already failed
   238	  local base="$1" changed declared f uncovered=0
   239	  local -a paths=()
   240	  local pair
   241	  for pair in "${TWINS[@]}"; do paths+=("${pair%%:*}"); done
   242	  changed="$(git -C "$ROOT" diff --name-only "${base}..HEAD" -- "${paths[@]}")"
   243	  declared="$(collect_declared "$base")" || return 1
   244	  while IFS= read -r f; do
   245	    [[ -n "$f" ]] || continue
   246	    # GH-362(A): the commit that established this path's freeze is not a violation of it. Only exempt
   247	    # when the freeze is the LAST thing that touched the path in this range — a later edit is real.
   248	    if path_edits_are_only_the_freeze "$base" "$f"; then
   249	      printf 'gh308 guard: %s — the only edit in this range IS the commit that froze it (%s)\n' \
   250	        "$f" "$(freeze_commit_for "$base" "$f" | cut -c1-8)"
   251	    elif printf '%s\n' "$declared" | grep -Fxq -- "$f"; then
   252	      printf 'gh308 guard: %s — covered by a declared Frozen-twin-exception\n' "$f"
   253	    else
   254	      # Name the file. The whole defect in the range-scoped version was that it never did.
   255	      printf 'gh308 guard: %s was edited with NO Frozen-twin-exception trailer naming it\n' "$f" >&2
   256	      uncovered=1
   257	    fi
   258	  done <<EOF
   259	$changed
   260	EOF
   261	  if (( uncovered )); then
   262	    printf 'gh308 guard: put the fix in the Python twin, or declare the exception per file:\n' >&2
   263	    printf '  Frozen-twin-exception: <path> — <reason>\n' >&2
   264	    return 1
   265	  fi
   266	  return 0
   267	}
   268	
   269	if [[ "$mode" == check ]]; then
   270	  if (( allow_exceptions )) && (( staged )); then
   271	    echo 'gh308 guard: --allow-exceptions needs --base REV (staged changes have no commit trailers yet)' >&2
   272	    exit 2
   273	  fi
   274	  rc=0
   275	  check_changes || rc=$?
   276	  (( rc == 0 )) && exit 0
   277	  (( rc == 2 )) && exit 2
   278	  (( allow_exceptions )) || exit "$rc"
   279	  echo "---"
   280	  if check_exception_coverage "$base"; then
   281	    # Wording matters: an edit can be permitted for two different reasons and conflating them would
   282	    # let a reader believe a declaration exists where none does (GH-362).
   283	    echo 'gh308 guard: every frozen-twin edit in this range is accounted for — declared, or the freeze itself'
   284	    exit 0
   285	  fi
   286	  exit 1
    19	## Why this shape (ponytail: cheapest path that's actually correct)
    20	
    21	The obvious-sounding version of this task is "rename `phases/` to `MARATHONS/` everywhere" — a
    22	repo-wide search-and-replace across ~70 files. That is not what's actually needed, and building it
    23	that way would be doing far more than the ask requires:
    24	
    25	- `utils/py/marathon_drive.py` and its frozen GH-308 Bash twin `relay-automation/marathon-drive.sh`
    26	  **already** take `--phases-dir` / `PHASES_DIR`, both defaulting to `$ROOT/phases`. The override
    27	  mechanism has parity today. Flipping the *default* value is a 1-line change in each twin — no new
    28	  config surface needs to be invented.
    29	- `relay-automation/xyz-vendor.sh` (the vendoring installer) has **zero** hardcoded "phases"
    30	  references, grep-confirmed. A vendored install inherits whatever default the driver code defines.
    31	  Nothing to touch there for "all new (vendored) installations" — that requirement is already met by
    32	  changing the two twins' default.
    33	- Of the ~70 files a bare grep for "phases" turns up, the large majority are prose mentions in docs,
    34	  historical `PROJECT/3-COMPLETED/**` records, and `temp/relay-system-collected/**` (other repos'
    35	  archived transcripts, not this repo's live code) — none of those need editing for the tool's actual
    36	  behavior to change.
    37	
    38	So the real work is small and mechanical: flip 2 defaults, fix 2 already-latent literal-string bugs,
    39	and enumerate (not assume) which of the remaining files actually assert the *default value* rather
    40	than just describing or using the override.
    41	
    42	## What's actually broken today, independent of this rename
    43	
    44	Found while grounding this, not part of the ask, but real and worth fixing in the same lane since
    45	the same lines are being touched anyway:
    46	
    47	- `utils/py/marathon_drive.py:1666` — `p.startswith("phases/")` — a hardcoded literal in a
    48	  containment-adjacent check. It does not read `phases_dir`, so it is **already wrong today** for
    49	  anyone who passes a non-default `--phases-dir`: their phase output would not match this check.
    50	- `relay-automation/marathon-drive.sh:961` — `awk '{ p=substr($0,4); if (p !~ /^phases\// && p !~
    51	  /^\.tick\//) print p }'` inside the dirty-tree pre-flight warning — same class of bug, same twin
    52	  pairing, same fix shape (read `$PHASES_DIR`, not a literal).
    53	
    54	Both need to become variable-driven rather than string-literal regardless of what the default is
    55	named, which is exactly what this issue needs anyway.
    56	
    57	## The gitignore landmine (found during grounding, flagging because it's live right now)
    58	
    59	`marathon_drive.py` stages phase output with `git add --` + `check=True` at three call sites
    60	(`:1129` ESCALATION.md, `:1169`, `:1728` RELAY.md). `git add` on an explicitly gitignored path exits
    61	1, so `check=True` raises and the phase dies while trying to record itself.
    62	
    63	`test/marathon-root-audit.sh` (added **2026-08-09**, today) pins exactly this: it asserts that phase
    64	artifacts the driver commits are never gitignored, because someone gitignored the whole `/phases/`
    65	directory that same day and reverted it hours later after hitting this crash. Whatever the new
    66	default directory is named, it needs the equivalent assertion from day one, or the first same-repo
    67	phase to run against it will crash.
    90	## Phases
    91	
    92	### Phase 0 — enumerate, don't assume (cx 1, risk 1, eff 1)
    93	
    94	Turn the ~70-file grep hit list into a real classification before any edit lands:
    95	1. Mentions/prose only (docs, `PROJECT/3-COMPLETED/**`, `temp/relay-system-collected/**`) → no
    96	   change needed, explicitly recorded as reviewed-and-skipped, not silently ignored.
    97	2. Tests that hardcode the *default value* specifically (would silently start asserting against a
    98	   directory the driver no longer writes to) → must update.
    99	3. Tests that already pass an explicit `--phases-dir` fixture path → unaffected, recorded as such.
   100	4. Skills/docs that document the default for a new user (`skills/marathon-triage/SKILL.md`,
   101	   `skills/file-xyz-bug/SKILL.md`, `README.md`, `relay-automation/README.md`,
   102	   `relay-automation/CONTRACT.example.md`) → must update for consistency.
   103	
   104	Output: a short table in this doc (or a linked file) naming every file in categories 2–4 by path,
   105	so Phase 2 has a checklist instead of a re-grep.
   106	
   107	### Phase 1 — flip the default, fix the two literals, prove parity (cx 2, risk 2, eff 2)
   108	
   109	- `utils/py/marathon_drive.py`: change the `--phases-dir` default from `os.path.join(root,
   110	  "phases")` to `os.path.join(root, "MARATHONS")`; fix the `:1666` literal to read the resolved
   111	  `phases_dir` variable instead of the string `"phases/"`.
   112	- `relay-automation/marathon-drive.sh`: same two changes — `PHASES_DIR="${PHASES_DIR:-"$ROOT/
   113	  MARATHONS"}"`, and the `:961` awk pattern reads `$PHASES_DIR`'s basename rather than a literal.
   114	- Both are GH-308 frozen twins → go through the documented exception process
   115	  (`test/gh308-frozen-twin-guard.sh --check --base <rev> --allow-exceptions`), not around it. The
   116	  operator has already accepted this cost explicitly.
   117	- Extend (or add a sibling to) `test/marathon-root-audit.sh`'s gitignore-safety assertion to cover
   118	  the new default path — this is the fix for the landmine above, and it is the one piece of this
   119	  phase that must land before any real same-repo phase runs against the new default.
   120	- New/extended regression test proving twin parity: a fresh run with no `--phases-dir` writes under
   121	  `MARATHONS/` in both twins; `--phases-dir <custom>` still overrides in both; the two
   122	  containment-literal fixes correctly recognize a non-default `--phases-dir` value (this is the
   123	  falsifiable case that catches the pre-fix bug — assert it fails against the pre-fix code, not just
   124	  passes against the fix).
   125	
   126	### Phase 2 — apply the Phase 0 checklist, docs, close (cx 1–2, risk 1, eff 1–2, size depends on Phase 0's count)
   127	
   128	- Update every file Phase 0 categorized as 2–4. Each edit references its Phase 0 line, not a fresh
   129	  ad-hoc decision.
   130	- `README.md` / `relay-automation/README.md` / `ARCHITECTURE.md` (if it names the directory) updated
   131	  to describe `MARATHONS/` as the default, `--phases-dir` as the override.
   132	- Re-run the full `validate.sh` suite; confirm no drift beyond what Phase 0 predicted (a surprise
   133	  failure here means Phase 0's classification missed something and should be corrected, not papered
   134	  over).
   135	
   136	## Acceptance (copied verbatim from issue #484, do not restate)
   137	
   138	1. A fresh same-repo marathon run (no `--phases-dir` passed) writes to `MARATHONS/`, not the old
   139	   directory, in both the Python and Bash drivers, with identical behavior between twins.
   140	2. `--phases-dir <custom>` still overrides the default exactly as today, in both twins.
   141	3. The two hardcoded containment literals track the actual configured directory, not a fixed
   142	   string — verified with a fixture that passes a non-default `--phases-dir` and confirms the
   143	   containment/dirty-check logic still recognizes it correctly.
   144	4. A `git add --` on the new default's phase artifacts does not crash — equivalent assertion to the
   145	   existing gitignore-safety regression test, extended to the new path.
   146	5. Every test identified in Phase 0 that hardcoded the old default is either updated or confirmed
   147	   unaffected, with the reasoning recorded per-file, not asserted in bulk.
   148	6. GH-308 frozen-twin exception process followed for both edited Bash twins, not bypassed.
   149	
   150	## Sizing
README.md:202:- **Marathon** (`relay-automation/marathon.sh`) — chains several relay build→review phases from a
relay-automation/README.md:86:| Bare `marathon-drive.sh` | Exactly one `marathon` record per invocation |
relay-automation/README.md:87:| Swarm-originated `marathon-drive.sh` (`XYZ_HARNESS_CONTEXT=swarm`) | Exactly one `swarm` record per invocation |
relay-automation/README.md:88:| `marathon.sh` orchestrated multi-phase run | Exactly one `marathon` record for the whole run; nested phase-level `marathon-drive.sh` completion hooks stay silent |
relay-automation/README.md:105:| Any `marathon-drive.sh` phase | Overwritten once right after `marathon.phase.start` |
relay-automation/README.md:106:| Nested `relay-drive.sh` inside `marathon-drive.sh` | Silent; the phase-level marathon heartbeat owns freshness so a nested relay round does not double-write |
relay-automation/README.md:116:| [MARATHON.example.yaml](MARATHON.example.yaml) | Example multi-build marathon manifest for `marathon.sh`. |
relay-automation/README.md:118:## `marathon.sh` roots
relay-automation/README.md:120:`marathon.sh` resolves two different roots on purpose:
relay-automation/README.md:122:- `MARATHON_HOME`: the harness install that owns `bin/tick`, `bin/marathon-yaml`, and telemetry helpers. Default: the script's own parent dir (`relay-automation/..`).
relay-automation/README.md:123:- `MARATHON_ROOT`: the target repo that owns the plan's `brief:` files, `phases/`, `.tick/`, and commit target. Default: `git -C "$PWD" rev-parse --show-toplevel`; outside a git repo it falls back to `MARATHON_HOME`.
relay-automation/README.md:125:That split preserves dev-checkout behavior (`MARATHON_HOME == MARATHON_ROOT`) and makes vendored installs work with no bin overrides:
relay-automation/README.md:129:./.xyz/relay-automation/marathon.sh --plan marathon-plans/my-wave/MARATHON.yaml
relay-automation/README.md:451:For multi-phase plans, prefer the per-lane `turn_timeout_s:` field in `MARATHON.yaml`; `marathon.sh`
relay-automation/README.md:528:- **Set:** all transcript writers (`consult.sh`, `marathon-drive.sh`,

2026-08-10T05:00:04.360720Z ERROR codex_models_manager::manager: failed to renew cache TTL: missing field `supports_reasoning_summaries` at line 87 column 5
exec
/bin/zsh -lc "rg -n -C 4 'INVOCATION=|invocation =|--phase-brief|--phases-dir' utils/swarm-preflight.sh utils/py/swarm_preflight.py relay-automation/poll.sh relay-automation/relay-turn-lib.sh
rg -n --glob '"'!temp/**'"' --glob '"'!PROJECT/**'"' --glob '"'!relay-system/**'"' --glob '"'!phases/**'"' '(phases|PHASES_DIR)' relay-automation/marathon-closeout.sh relay-automation/marathon-tui.sh relay-automation/xyz-vendor.sh utils/py/poll.py
nl -ba test/gh308-frozen-twin-guard.sh | sed -n '13,31p;143,200p'" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-67768-b0m00j9w
 succeeded in 0ms:
utils/swarm-preflight.sh-817-# wrongly emit --target-root for a same-repo lane). Resolve both with `pwd -P` before comparing.
utils/swarm-preflight.sh-818-_root_canon="$(cd "$ROOT" 2>/dev/null && pwd -P || printf '%s' "$ROOT")"
utils/swarm-preflight.sh-819-_target_canon="$(cd "$TARGET_ROOT" 2>/dev/null && pwd -P || printf '%s' "$TARGET_ROOT")"
utils/swarm-preflight.sh-820-[[ "$_target_canon" != "$_root_canon" ]] && TARGET_ROOT_LINE=$'\n'"  --target-root $TARGET_ROOT \\"
utils/swarm-preflight.sh:821:INVOCATION="XYZ_HARNESS_CONTEXT=swarm XYZ_SESSION_ID=$SLUG RELAY_WORKTREE_ISOLATION=1 $_DRIVE_CMD \\
utils/swarm-preflight.sh:822:  --phase-brief <packet>/packet.md \\
utils/swarm-preflight.sh-823-  --reviewer agy \\
utils/swarm-preflight.sh-824-  --builder codex \\
utils/swarm-preflight.sh-825-  --artifact $ART_CSV \\$TARGET_ROOT_LINE
utils/swarm-preflight.sh-826-  --pre-advance-cmd '$GATE_CMD' \\
--
utils/py/swarm_preflight.py-1400-    target_root_line = ""
utils/py/swarm_preflight.py-1401-    if os.path.realpath(target_root) != os.path.realpath(root):
utils/py/swarm_preflight.py-1402-        target_root_line = f"\n  --target-root {target_root} \\"
utils/py/swarm_preflight.py-1403-        
utils/py/swarm_preflight.py:1404:    invocation = f"""XYZ_HARNESS_CONTEXT=swarm XYZ_SESSION_ID={slug} RELAY_WORKTREE_ISOLATION=1 {drive_cmd} \\
utils/py/swarm_preflight.py:1405:  --phase-brief <packet>/packet.md \\
utils/py/swarm_preflight.py-1406-  --reviewer agy \\
utils/py/swarm_preflight.py-1407-  --builder codex \\
utils/py/swarm_preflight.py-1408-  --artifact {art_csv} \\{target_root_line}
utils/py/swarm_preflight.py-1409-  --pre-advance-cmd '{gate_cmd}' \\
    13	TWINS=(
    14	  relay-automation/agy-turn.sh:utils/py/agy-turn.py
    15	  relay-automation/aider-turn.sh:utils/py/aider-turn.py
    16	  relay-automation/claude-turn.sh:utils/py/claude-turn.py
    17	  relay-automation/codex-turn.sh:utils/py/codex-turn.py
    18	  relay-automation/pi-turn.sh:utils/py/pi-turn.py
    19	  relay-automation/poll.sh:utils/py/poll.py
    20	  relay-automation/relay-loop.sh:utils/py/relay_loop.py
    21	  relay-automation/relay-drive.sh:utils/py/relay_drive.py
    22	  relay-automation/consult.sh:utils/py/consult.py
    23	  relay-automation/marathon-drive.sh:utils/py/marathon_drive.py
    24	  utils/swarm-preflight.sh:utils/py/swarm_preflight.py
    25	  # GH-362: marathon-plan was GH-308's ONE documented exception — its Bash body stayed authoritative
    26	  # and dual-maintained because the "port" delegated to a copied, drifted node engine. GH-340 removed
    27	  # that reason: `utils/py/_marathon_plan.py` is a native stdlib engine, the copied JS is deleted, and
    28	  # the Python lane needs no Node. The exception outlived its rationale, so it is retired here and
    29	  # marathon-plan becomes the 12th frozen twin.
    30	  utils/marathon-plan.sh:utils/py/marathon_plan.py
    31	)
   143	collect_declared() {  # <base> → stdout: covered paths, one per line. rc 1 if ANY trailer is malformed.
   144	  local base="$1" rc=0 line rest paths_part reason token found
   145	  local -a skip_commits=()
   146	  # GH-362(B): a malformed trailer used to hard-fail the WHOLE run, even when it sat in a commit whose
   147	  # edits need no coverage at all. `07ae1e7` is exactly that case — its trailer is the pre-GH-321 bare
   148	  # form (`Frozen-twin-exception: <reason>`, no path), which was correct when written, and it is the
   149	  # freeze-establishing commit whose edits (A) already exempts. Git history cannot be rewritten, so
   150	  # the format change shipped in GH-321 needs this back-compat or it permanently rejects its own past.
   151	  #
   152	  # Scoped deliberately: ONLY freeze-establishing commits are skipped. Every other commit still gets
   153	  # the full GH-321 treatment, so a new pathless trailer is still rejected — which is what GH-321 was
   154	  # actually for.
   155	  # Portable collect: `mapfile` is a bash 4+ builtin and macOS ships bash 3.2, which this repo's
   156	  # scripts must keep working under.
   157	  local _sc
   158	  while IFS= read -r _sc; do
   159	    [[ -n "$_sc" ]] && skip_commits+=("$_sc")
   160	  done < <(freeze_establishing_commits "$base")
   161	  while IFS= read -r line; do
   162	    case "$line" in
   163	      Frozen-twin-exception:*) ;;
   164	      *) continue ;;
   165	    esac
   166	    rest="${line#Frozen-twin-exception:}"
   167	    if [[ "$rest" == *"—"* ]]; then
   168	      paths_part="${rest%%—*}"; reason="${rest#*—}"
   169	    elif [[ "$rest" == *" -- "* ]]; then
   170	      paths_part="${rest%% -- *}"; reason="${rest#* -- }"
   171	    else
   172	      # Includes the legacy bare form (`Frozen-twin-exception: <reason>`), which named no file and is
   173	      # exactly what made the hatch blanket-scoped. Failing loudly beats covering nothing in silence.
   174	      printf 'gh308 guard: malformed Frozen-twin-exception trailer — no path/reason separator:\n  %s\n' "$line" >&2
   175	      printf '  expected: Frozen-twin-exception: <path>[, <path>...] — <reason>\n' >&2
   176	      rc=1; continue
   177	    fi
   178	    if [[ ! "$reason" =~ [^[:space:]] ]]; then
   179	      printf 'gh308 guard: Frozen-twin-exception trailer has no reason text:\n  %s\n' "$line" >&2
   180	      rc=1; continue
   181	    fi
   182	    found=0
   183	    paths_part="${paths_part//,/ }"
   184	    for token in $paths_part; do   # deliberate word splitting: the path list is space/comma separated
   185	      if is_frozen_path "$token"; then
   186	        printf '%s\n' "$token"
   187	        found=1
   188	      else
   189	        printf 'gh308 guard: Frozen-twin-exception names a path that is not a frozen twin: %s\n' "$token" >&2
   190	        printf '  A typo here would silently cover nothing, so it fails instead. Frozen twins:\n' >&2
   191	        frozen_paths | sed 's/^/    /' >&2
   192	        rc=1
   193	      fi
   194	    done
   195	    if (( found == 0 )); then
   196	      printf 'gh308 guard: Frozen-twin-exception trailer names no frozen twin:\n  %s\n' "$line" >&2
   197	      rc=1
   198	    fi
   199	  done < <(eligible_trailer_lines "$base" "${skip_commits[@]+"${skip_commits[@]}"}")
   200	  return "$rc"

2026-08-10T05:00:24.283178Z ERROR codex_models_manager::manager: failed to renew cache TTL: missing field `supports_reasoning_summaries` at line 87 column 5
codex
ANSWER: The plan is not complete or safe to land as written. It misses the multi-phase orchestrator and live monitors, and its gitignore state claim is contradicted by the current tree.

FINDINGS

- [Blocker] `relay-automation/marathon.sh` independently defaults `PHASES_DIR` to `$ROOT/phases` and always forwards it explicitly to the driver (`relay-automation/marathon.sh:167`, `relay-automation/marathon.sh:199-200`). Thus changing only the two driver defaults leaves ordinary `marathon.sh` runs on `phases/`—and potentially crashing because that path is ignored. This file, its help/docs, and its vendored-default assertion (`test/marathon.sh:270-278`) belong in the implementation phase.

- [Blocker] Two live monitor components will become blind after the flip: `marathon-ls.sh` searches `$repo/phases` (`relay-automation/marathon-ls.sh:110-118`) and `marathon-detail.sh` searches `$REPO/phases` (`relay-automation/marathon-detail.sh:39-53`); the TUI delegates to both (`relay-automation/marathon-tui.sh:20-21`, `:38-44`). These are runtime behavior, not merely Phase-2 prose updates. Their fixture is also hardcoded to `phases` (`test/marathon-monitor.sh:39-49`).

- [Blocker] The plan’s “reverted hours later” gitignore claim is false in this worktree: `.gitignore` currently contains `/phases` (`.gitignore:66`). The audit really does assert against this condition (`test/marathon-root-audit.sh:250-257`), so it should currently fail for `phases/audit-probe/RELAY.md`. The underlying crash claim is real: Python invokes `git add --` with `check=True` for escalation, transcript, and relay artifacts (`utils/py/marathon_drive.py:1183`, `:1223`, `:1782`). The plan’s cited line numbers are stale, but the behavior is correct.

- [Should] The proposed variable-driven dirty-tree fix is underspecified and the Bash “basename” approach is wrong for valid nested overrides. Git porcelain paths are repo-relative (`utils/py/marathon_drive.py:1661-1667`; `relay-automation/marathon-drive.sh:959-965`). For `--phases-dir "$ROOT/state/marathon-runs"`, comparing only `marathon-runs/` will not exclude `state/marathon-runs/...`; regex metacharacters in a basename also make the `awk` form unsafe. Derive and safely match the normalized repo-relative configured path, and test a nested custom directory.

- [Should] The GH-308 command is valid only on a committed range with a real base revision, but the plan omits the required trailer. `--allow-exceptions` rejects `--staged` because staged changes have no commit message (`test/gh308-frozen-twin-guard.sh:269-272`), and the changed Bash file must be named by a trailer such as `Frozen-twin-exception: relay-automation/marathon-drive.sh — <reason>` (`test/gh308-frozen-twin-guard.sh:251-264`). There is one edited frozen Bash twin, not “both edited Bash twins” (`test/gh308-frozen-twin-guard.sh:23`).

- [Should] The parity test must force the Bash fallback. With the normal environment, the shell shim execs Python (`relay-automation/marathon-drive.sh:9-18`), so a pair of ordinary shim invocations would only test Python twice. Exercise Python plus `XYZ_PYTHON=0` Bash explicitly.

- [Should] Phase 0 must finish before Phase 1, but its categories need a “live callers/consumers” class, not only tests and docs. The current ordering says discovery happens first (`PROJECT/1-INBOX/GH-484-MARATHONS-DEFAULT.md:92-105`), which is the right rule; amend its checklist to require `marathon.sh`, `marathon-ls.sh`, `marathon-detail.sh`, TUI behavior, and their tests before landing the default flip.

- [Pass] `utils/swarm-preflight.sh` and `utils/py/swarm_preflight.py` generate a direct `marathon-drive` invocation without `--phases-dir` (`utils/swarm-preflight.sh:821-826`, `utils/py/swarm_preflight.py:1404-1409`), so they will inherit the corrected driver default. No run-output-directory assumption was found in `poll.sh` or `relay-turn-lib.sh`.

RECOMMENDATION: Amend Phase 0/1 to include `marathon.sh` and the monitor stack, fix the active `/phases` ignore conflict, require a repo-relative override matcher plus forced-Bash parity test, and name the Bash exception trailer before running the range guard.
tokens used
122,687
ANSWER: The plan is not complete or safe to land as written. It misses the multi-phase orchestrator and live monitors, and its gitignore state claim is contradicted by the current tree.

FINDINGS

- [Blocker] `relay-automation/marathon.sh` independently defaults `PHASES_DIR` to `$ROOT/phases` and always forwards it explicitly to the driver (`relay-automation/marathon.sh:167`, `relay-automation/marathon.sh:199-200`). Thus changing only the two driver defaults leaves ordinary `marathon.sh` runs on `phases/`—and potentially crashing because that path is ignored. This file, its help/docs, and its vendored-default assertion (`test/marathon.sh:270-278`) belong in the implementation phase.

- [Blocker] Two live monitor components will become blind after the flip: `marathon-ls.sh` searches `$repo/phases` (`relay-automation/marathon-ls.sh:110-118`) and `marathon-detail.sh` searches `$REPO/phases` (`relay-automation/marathon-detail.sh:39-53`); the TUI delegates to both (`relay-automation/marathon-tui.sh:20-21`, `:38-44`). These are runtime behavior, not merely Phase-2 prose updates. Their fixture is also hardcoded to `phases` (`test/marathon-monitor.sh:39-49`).

- [Blocker] The plan’s “reverted hours later” gitignore claim is false in this worktree: `.gitignore` currently contains `/phases` (`.gitignore:66`). The audit really does assert against this condition (`test/marathon-root-audit.sh:250-257`), so it should currently fail for `phases/audit-probe/RELAY.md`. The underlying crash claim is real: Python invokes `git add --` with `check=True` for escalation, transcript, and relay artifacts (`utils/py/marathon_drive.py:1183`, `:1223`, `:1782`). The plan’s cited line numbers are stale, but the behavior is correct.

- [Should] The proposed variable-driven dirty-tree fix is underspecified and the Bash “basename” approach is wrong for valid nested overrides. Git porcelain paths are repo-relative (`utils/py/marathon_drive.py:1661-1667`; `relay-automation/marathon-drive.sh:959-965`). For `--phases-dir "$ROOT/state/marathon-runs"`, comparing only `marathon-runs/` will not exclude `state/marathon-runs/...`; regex metacharacters in a basename also make the `awk` form unsafe. Derive and safely match the normalized repo-relative configured path, and test a nested custom directory.

- [Should] The GH-308 command is valid only on a committed range with a real base revision, but the plan omits the required trailer. `--allow-exceptions` rejects `--staged` because staged changes have no commit message (`test/gh308-frozen-twin-guard.sh:269-272`), and the changed Bash file must be named by a trailer such as `Frozen-twin-exception: relay-automation/marathon-drive.sh — <reason>` (`test/gh308-frozen-twin-guard.sh:251-264`). There is one edited frozen Bash twin, not “both edited Bash twins” (`test/gh308-frozen-twin-guard.sh:23`).

- [Should] The parity test must force the Bash fallback. With the normal environment, the shell shim execs Python (`relay-automation/marathon-drive.sh:9-18`), so a pair of ordinary shim invocations would only test Python twice. Exercise Python plus `XYZ_PYTHON=0` Bash explicitly.

- [Should] Phase 0 must finish before Phase 1, but its categories need a “live callers/consumers” class, not only tests and docs. The current ordering says discovery happens first (`PROJECT/1-INBOX/GH-484-MARATHONS-DEFAULT.md:92-105`), which is the right rule; amend its checklist to require `marathon.sh`, `marathon-ls.sh`, `marathon-detail.sh`, TUI behavior, and their tests before landing the default flip.

- [Pass] `utils/swarm-preflight.sh` and `utils/py/swarm_preflight.py` generate a direct `marathon-drive` invocation without `--phases-dir` (`utils/swarm-preflight.sh:821-826`, `utils/py/swarm_preflight.py:1404-1409`), so they will inherit the corrected driver default. No run-output-directory assumption was found in `poll.sh` or `relay-turn-lib.sh`.

RECOMMENDATION: Amend Phase 0/1 to include `marathon.sh` and the monitor stack, fix the active `/phases` ignore conflict, require a repo-relative override matcher plus forced-Bash parity test, and name the Bash exception trailer before running the range guard.
