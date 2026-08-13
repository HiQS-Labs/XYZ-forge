**NO FIRSTHAND VERIFICATION CITED** — treat conclusions as conditional (codex's answer carries an unsupported [Pass]/verified/confirmed-style claim with no quoted span or file:line citation nearby, despite the consult PREAMBLE asking advisors to cite evidence.)

> **ATTESTATION**
> Model: gpt-5.6-terra
> Provider: openai
> Sandbox: read-only

Reading additional input from stdin...
2026-08-12T04:33:57.166238Z ERROR codex_models_manager::cache: failed to load models cache: missing field `base_instructions` at line 95 column 5
OpenAI Codex v0.144.6
--------
workdir: /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-69972-gxaghv_u
model: gpt-5.6-terra
provider: openai
approval: never
sandbox: read-only
reasoning effort: high
reasoning summaries: none
session id: 019ff43f-9cc6-79c0-8bb6-821102ee5ac1
--------
user
You are an INDEPENDENT advisor in a one-shot cross-model consult. Another model is answering the SAME question separately and a coordinator will reconcile both answers, so give your own honest, specific read — do not hedge toward a consensus you cannot see. Read any repo files the question references (cite file:line). Respond with: (1) a short direct ANSWER; (2) graded FINDINGS — [Blocker]/[Should]/[Nit]/[Pass] — where applicable; (3) a one-line RECOMMENDATION. You are ADVISORY ONLY: output your analysis as text; do not rely on writing files (you are running in a throwaway copy).

=== CONSULT QUESTION ===
# Adjudicate: close three held Nightwatch issues on NET EFFECTIVENESS, or keep them open?

You are advising the operator of `xyz-3-agents-swarm`. Release **0.3.0 "Nightwatch"** is a Release
Candidate: `bash test/nightwatch-release.sh --release-gate` exits 0 and reports
`GOALPOST MET — all 8 manifest entries complete and every lifecycle case executes green`.

The frozen manifest (per `RELEASES.md`, which is the canonical SOT for release scope) is:
**#408, #409, #426, #388, #387, #384, #358, plus #354 Phase 1.**

Five are now CLOSED (#387, #408, #409, #426, #384) after a per-criterion audit. **Three are held:
#388, #358, #354.** Adjudicate each.

## The operator's actual question — read this before anything else

The operator is **explicitly de-prioritising letter-of-the-law acceptance-criteria compliance** and
asking about **net effectiveness**: did the shipped work solve the real problem? He does not want
issues hanging open on technicalities. He has also said: *"If a solution had to be pivoted to solve
the problem, then perhaps the acceptance criteria needs to be pivoted too."*

So for each issue, choose exactly one verdict:

- **A — CLOSE AS-IS.** The problem is solved; remaining gaps are immaterial.
- **B — AMEND CRITERIA, THEN CLOSE.** The implementation pivoted for good reason and the *written*
  criteria are now the stale artifact. State the exact replacement wording.
- **C — KEEP OPEN.** Real, material value is unshipped. Name precisely what, and what would close it.

Do not hedge across two verdicts. Pick one per issue and defend it.

## The tension you must resolve

`RELEASES.md`'s 0.2.0 block records a deliberate precedent *against* closing on a green gate:

> **#375 and #390 remain OPEN on purpose:** their gates are registered, green and control-observed,
> which is what this release's exit criterion measures, but each has acceptance criteria that did not
> ship... **Closing them silently would have repeated exactly the #401→#461 mistake this release
> exists to catch.**

Note the word **silently**. Is a *documented, reasoned* deviation materially different from a silent
one? Or does that reasoning erode the guard the repo built after #401→#461? That is the crux.

## The three issues

### #388 — marathon run-log durability
`PROJECT/2-WORKING/GH-388-MARATHON-RUN-LOG-DURABILITY.md` marks **all 7 criteria Met**, but carries a
separate section `## Acceptance — deviations found while building` stating that **criterion 5 did not
ship as written**. Criterion 5 says a default log path resolving into a non-durable root must **fail
the run**. Shipped behaviour is narrower: the rule targets **relocation** — a transcript resolving
*inside the repo being driven* is permitted even when that repo sits under `$TMPDIR`; only a path both
non-durable *and outside the repo* is refused. The stated rationale: the literal reading refuses to
run the harness inside every fixture in the suite (all are repos under `$TMPDIR`), so *"a guard that
cannot be exercised is not a guard, and 'fails the run' would have meant 'fails every run'."*
Gate: `test/gh388-run-log-durability.sh` 24/0 locally; control 9 red pre-fix → 0.

**Question:** is the narrowed rule the *correct* rule (making criterion 5 simply mis-written), or does
it leave a real hole — a run whose evidence still lands somewhere a reboot erases, undetected?

### #358 — CI lock flake
*"CI: xyz-completion's 16-way concurrent-append assertion flakes on the shared runner (a record is
lost)."* Phase 1 (instrumentation naming the terminal lock state) shipped. `RELEASES.md` records that
**Phase 2 is a disposition blocked on an observation** — it needs a real CI failure carrying the new
instrumentation, and the capture doc **forbids pre-committing one**. This assertion still fails on CI
today (two `conc-1` failures in every `development` run) while passing locally.

**Question:** an issue whose remaining work is *"wait for a real-world observation"* — is that a
hanging issue that should be closed (with Phase 2 refiled as its own observation-triggered issue), or
is it legitimately open? Consider that it is currently *actively red in CI*, which is either evidence
it should stay open, or evidence it is a CI-environment problem misfiled as a product defect.

### #354 — Concurrent Swarms
Manifest membership is **"Phase 1 only"** — clone-wide driver exclusion for linked worktrees — and
`RELEASES.md` records that Phase 1 *"was delivered by #376/#448 rather than by this release, recorded
as such rather than rebuilt."* The issue itself is much broader than Phase 1 (concurrent swarms
generally). Its own comment thread spawned **#448** for an observability defect found at three
consumer sites.

**Question:** should a broad parent issue be closed because the one narrow phase a release claimed is
done? Or is closing it a scope-loss risk — the remaining phases becoming invisible? Is the right move
to close it and ensure successors (#376, #448) carry the rest, or to keep it as a tracking parent?

## Also give a general rule

Beyond the three, state the **decision rule** this repo should apply going forward when shipped work
diverges from written acceptance criteria. It must be usable by an agent without the operator present,
and must not degenerate into either (a) rubber-stamping any divergence as "we pivoted", or (b) the
current failure mode of issues hanging open indefinitely on technicalities.

## Output format

For each of #388, #358, #354: **verdict letter, one-paragraph justification, and — if B — the exact
replacement criterion wording.** Then the general rule in under 150 words. Be decisive and concrete;
vague both-sides answers are worthless here. If you think the operator's premise is wrong, say so.

hook: SessionStart
hook: SessionStart Completed
codex
I’ll inspect the canonical release, working notes, and the three issue records, then give a decisive net-effectiveness judgment with line citations.
exec
/bin/zsh -lc "pwd && rg --files -g 'WORKTREE-SAFETY.md' -g 'ROUTER.md' -g 'GUIDING-PRINCIPLES.md' -g 'RELEASES.md' -g 'GH-388-MARATHON-RUN-LOG-DURABILITY.md' -g '*358*' -g '*354*'" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-69972-gxaghv_u
 succeeded in 0ms:
/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-69972-gxaghv_u
GUIDING-PRINCIPLES.md
ROUTER.md
RELEASES.md
WORKTREE-SAFETY.md
test/baselines/GH-358-negative-control.md
test/gh358-lock-instrumentation.sh
relay-system/2026-08-10/marathon-gh358-lock-flake-instrumentation-222216.md
relay-system/2026-08-10/marathon-gh358-lock-flake-instrumentation-230559.md
PROJECT/2-WORKING/GH-358-LOCK-FLAKE-INSTRUMENTATION.md
PROJECT/2-WORKING/GH-388-MARATHON-RUN-LOG-DURABILITY.md
PROJECT/2-WORKING/GH-354-CONCURRENT-SWARMS.md
PROJECT/2-WORKING/MARATHON-2026-08-10-NIGHTWATCH/brief-gh358-lock-flake-instrumentation.md

exec
/bin/zsh -lc 'for f in WORKTREE-SAFETY.md ROUTER.md GUIDING-PRINCIPLES.md RELEASES.md PROJECT/2-WORKING/GH-388-MARATHON-RUN-LOG-DURABILITY.md PROJECT/2-WORKING/GH-358-LOCK-FLAKE-INSTRUMENTATION.md PROJECT/2-WORKING/GH-354-CONCURRENT-SWARMS.md; do echo "===== $f"; nl -ba "$f"; done' in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-69972-gxaghv_u
 succeeded in 0ms:
===== WORKTREE-SAFETY.md
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
===== ROUTER.md
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
===== GUIDING-PRINCIPLES.md
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
===== RELEASES.md
     1	# Major Releases
     2	
     3	Forward-looking planning ledger for major releases — one block per release, minimal fields, blank
     4	line between blocks. Marathon plans and other forward planning cross-reference this doc for
     5	target release names/dates; it is not a history of what shipped (that's CHANGELOG.md — lessons
     6	learned belong there at ship time, not duplicated here). Contract lives in PROJECT/PDDA.md ->
     7	"RELEASES.md — release ledger". Add new fields only when a real need shows up.
     8	
     9	## This file is OPTIONAL (GH-381)
    10	
    11	**Read this before proposing an edit to it.**
    12	
    13	`RELEASES.md` is an *optional planning aid*. It is not a required artifact, it is not a checklist,
    14	and it is **not something to keep topped up**. An empty file, a stale file, or no file at all are
    15	all perfectly valid states. The tooling agrees: `pdda.sh releases` is warn-only, never blocks, and
    16	skips entirely when the file is absent — *"RELEASES.md not found — nothing to check."*
    17	
    18	**Do not offer to fill this in, populate it, bring it up to date, or add the release you just
    19	shipped.** Do not treat a sparse file as an incomplete one. If nobody is actively planning a release
    20	arc right now, the correct amount of content here is whatever is already present — including
    21	nothing.
    22	
    23	Edit it only when an operator explicitly asks for release *planning*. That is the whole trigger.
    24	
    25	## Scope boundary — Litmus (0.2.0) vs Nightwatch (0.3.0)
    26	
    27	Added 2026-08-08 after a cross-model consult (codex + agy) found the two descriptions **not
    28	decidable**: a competent agent could not route a new issue between them from the prose alone, because
    29	Litmus says checks must "report red" correctly while Nightwatch says hostile states must "fail
    30	clearly." Both advisors independently flagged this as blocking, and the overlap is worst exactly where
    31	orchestration failures emit gate-looking verdicts.
    32	
    33	> **Litmus owns faulty decision semantics.** A named acceptance, preflight, reviewer, or pre-advance
    34	> check returns pass, fail, or a *reason* inconsistent with a controlled input's observable outcome —
    35	> or lacks a recorded negative control.
    36	>
    37	> **Nightwatch owns run lifecycle.** Dispatch, target and worktree containment, claims, durable
    38	> logging, interruption, and resume — **even when lifecycle code emits a misleading message.**
    39	>
    40	> **Classify by the violated invariant, not by the wording of the message.** Split an issue that
    41	> violates both.
    42	
    43	That last clause is the load-bearing one. The intuitive rule — "a lying message is Litmus" — gives the
    44	wrong answer: #426 exits 6 claiming containment worked while a file leaked, but the invariant it
    45	violates is run containment, so it is Nightwatch, with the assertion of its lie written as a
    46	Litmus-style test. Conversely #407 reports `pre-advance-failed` when no gate ran, and that *is* a
    47	Litmus defect, because the violated invariant is the verdict itself.
    48	
    49	**A release is not its milestone.** A milestone is a backlog and grows while you work; a release needs
    50	a frozen manifest and a testable exit criterion, both recorded in the blocks below. "The open issues
    51	are done" is not an exit criterion, because working on a release generates more of them.
    52	
    53	## What belongs here, on the occasions it is used
    54	
    55	**Major and meaningful releases only. Not every release number.**
    56	
    57	A block earns its place by being worth *planning toward* — a named arc with a theme, a target date,
    58	and a milestone. If the only thing you can write in `Description:` is a restatement of what changed,
    59	it belongs in CHANGELOG.md and nowhere else.
    60	
    61	`Iterations:` reserves a band of patch numbers for a release. **Reserved, deliberately not
    62	enumerated** — versions inside a band ship freely and are recorded in CHANGELOG.md only. They never
    63	get a block here. The band is what makes "where does 0.2.3 go?" a question with a written answer
    64	instead of one resolved by adding a row.
    65	
    66	**A version inside an existing band is already accounted for, so a new block for it is a
    67	duplicate.** That is the admission rule, and it is the only one.
    68	
    69	Why this is written down rather than assumed: the failure mode is not a wrong entry, it is a file
    70	that stays correct at every single step while turning into the wrong thing. Add `0.2.1` because it
    71	shipped, add `0.2.2` for symmetry, and this becomes a **de-facto pre-CHANGELOG** — a second,
    72	hand-maintained history that is guaranteed to disagree with the real one the first time someone
    73	updates one and not the other. Two sources of truth for the same fact is the defect; the row count
    74	is only the symptom.
    75	
    76	An assistant that keeps asking for this file to be filled produces exactly that outcome, one
    77	helpful suggestion at a time. Hence the section above.
    78	
    79	When a band is exhausted, widen it or promote the next release — do not start enumerating.
    80	
    81	`Milestone:` is the release -> issue-set join key (GH-284 Phase 3): a GitHub MILESTONE TITLE, not a
    82	URL and not a list of issues. `GH_URL:` can name only one thing, which cannot express a release's
    83	scope. Ask GitHub what is in a release instead of maintaining a list here:
    84	
    85	    gh issue list --milestone "Quicksilver" --state open --json number,title,labels
    86	
    87	Release: 0.1.0
    88	Iterations: 0.1.0-0.1.4
    89	Status: Shipped
    90	Target Date: 2026-08-01
    91	Codename: Quicksilver
    92	Description: Python-authoritative Tier-A twins. Licensed AGPL-3.0-only (`LICENSE`) with a commercial option (`LICENSE-COMMERCIAL.md`), adopted 2026-07-29 post-ship; the pre-existing conflicting `LICENSE.md` was removed 2026-07-30 (#372).
    93	GH_URL: [GH 308](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/308)
    94	Milestone: Quicksilver
    95	Front-door reviewed: No
    96	Shakedown reviewed: No
    97	License file: Yes
    98	
    99	Release: 0.2.0
   100	Iterations: 0.2.0-0.2.4
   101	Status: Release Candidate — exit criterion MET 2026-08-09 on `development` @ `263816c`
   102	Target Date: 2026-09-05
   103	RC evidence: `bash test/litmus-release.sh --release-gate` → `GOALPOST MET — all 6 manifest entries complete` (6/6, 0 remaining, 0 false completion claims). Its own negative control, `--mutate-evidence`, was re-run on the same commit and reports `negative control OBSERVED in both directions (6 pass, 0 fail)` — it detects a stripped declaration, an unregistered gate (the #461 defect), and an invariant violated in either direction. Four of the six issues are CLOSED with per-criterion evidence (#407, #417, #457, #461). **#375 and #390 remain OPEN on purpose:** their gates are registered, green and control-observed, which is what this release's exit criterion measures, but each has acceptance criteria that did not ship — #390 defers a host free-memory floor and packet-driven per-phase overrides to a Phase 2 its own code comment names (`marathon_drive.py:1253`), and #375's shipped three-state `unverifiable` verdict deliberately contradicts its criteria 1 and 5 because implementing them literally took `relay-self-sufficiency.sh` from 4/0 to 0/4 on a working machine. Both are audited per-criterion on the issues. Closing them silently would have repeated exactly the #401→#461 mistake this release exists to catch.
   104	Codename: Litmus
   105	Description: Make the checks capable of failing. Every gate in the Litmus manifest is shown to report red against a real defect, or is explicitly downgraded to advisory — a check never observed failing is not evidence (#419). Ordered first because it is the release that makes the next one measurable. It is also what the self-improvement chain (#431) is blocked on: a Reviewer is a gate, so #419 applies to it, and its qualification gate is currently un-runnable (#428) and has only ever been measured once (#429).
   106	Exit criterion: `bash test/litmus-release.sh --release-gate` exits 0. Red today by design; turning it green is what "done" means. Its own negative control is `--mutate-evidence`, which must detect a stripped declaration and an unregistered gate. NOTE the honest limit, stated in that file: the audit proves registration, declaration shape and the absence of false completion claims. It does NOT prove a control was truly observed, because `gate_inventory.py` reads a declaration authored by the same person who wrote the gate. Recorded execution of each control is deliberately out of scope for this release.
   107	Manifest: FROZEN 2026-08-08 — #375, #390, #407, #417, #457, #461. Six named decision gates, a fixed denominator rather than a percentage. "Every gate" was unshippable prose: `gate_inventory.py` reports 152 of 158 gates with no declared control, and retrofitting them is explicitly out of scope. Adding an entry is a RE-SCOPE, not a bugfix: a mid-release discovery joins only if it makes the exit command fail or falsifies a named invariant, has a reproducer demonstrating that, and the operator explicitly swaps out an existing entry or accepts a date slip. Discovery is not admission — #457, #460 and #461 were all filed while executing Litmus, which is what an unfrozen boundary looks like.
   108	GH_URL:
   109	Milestone: Litmus
   110	Front-door reviewed: No
   111	Shakedown reviewed: No
   112	License file: Yes
   113	
   114	Release: 0.3.0
   115	Iterations: 0.3.0-0.3.4
   116	Status: Release Candidate — exit criterion MET 2026-08-11 on `development`
   117	Target Date: 2026-10-10
   118	RC evidence: `bash test/nightwatch-release.sh --release-gate` → `GOALPOST MET — all 8 manifest entries complete and every lifecycle case executes green` (manifest 8/8, lifecycle 5 passing / 0 failing / 0 NOT COVERED). Its own negative control, `--mutate-evidence`, reports 34/0 and `negative control OBSERVED in both directions`. Every manifest entry carries a recorded pre-fix control under `test/baselines/`, not an assertion that one happened. **Two entries are honest about their limits and are worth reading before signing off:** #358's Phase 2 is a *disposition* that needs a real CI failure carrying the new instrumentation, and its capture doc forbids pre-committing one — so Phase 1 shipped and Phase 2 is blocked on an observation, not on work; and #354's membership is Phase 1 only, which was delivered by #376/#448 rather than by this release, recorded as such rather than rebuilt. **#426's outcome inverted its own diagnosis:** a factorial control showed the leak survives with worktree isolation OFF, so teardown was exonerated and the real cause was the GH-375 auth pre-flight running with the caller's CWD, outside containment. **Twelve open Nightwatch-milestone issues remain and gate nothing**, per this block's own "a release is not its milestone" rule.
   119	Codename: Nightwatch
   120	Description: An unattended marathon against a real target repo survives, records, and recovers. Before dispatching work, it proves the target can accept the harness write-set and preserves the local-state contract, so hostile ignore rules or linked worktrees fail clearly rather than silently splitting, leaking, or losing the run. GH-354 Phase 1 is an early Nightwatch containment prerequisite: restore clone-wide driver exclusion for linked worktrees and prove all driver pairs fail closed. A run interrupted, killed at its cap, or panicking the host leaves a durable record and recovery path instead of a clean tree full of ungated commits. Depends on Litmus. The same durability work is what makes a reflection corpus trustworthy (#431): a run with no record is invisible to any later pass over it, and the loop's own evidence has never survived a reboot (#430).
   121	Exit criterion: `bash test/nightwatch-release.sh --release-gate` exits 0. **BUILT 2026-08-11 and red by design**, exactly as Litmus's was; turning it green is what "done" means. It has two halves because a metadata audit cannot answer this release's question. Half A audits the frozen manifest — each entry's gate EXISTS, is REGISTERED in `validate.sh` (a gate absent from TESTS is indistinguishable from one that passes — the #461 defect), and has a RECORDED control under `test/baselines/`; it also cross-checks that this list and the `Manifest:` line below agree, since a boundary that disagrees with itself is not frozen. Half B **executes** the lifecycle cases rather than auditing them, delegating to the suites that already drive real children and kill them rather than growing a second driver fixture here. Status on 2026-08-11: **manifest 8/8 complete; lifecycle 5 passing, 0 NOT COVERED — GOALPOST MET.** The last gap was the hostile-target write-set case, closed by #514, which was filed while executing this release and deliberately NOT admitted to the manifest (discovery is not admission); it belongs to the lifecycle list because the exit criterion always named that case — what was missing was a suite driving it. That lane also corrected its own premise: the pre-fix tree does not dispatch a turn first, it dies at the render's `git add` with an unhandled `CalledProcessError` traceback, so the discriminating assertion is the absence of that traceback rather than the absence of a dispatch. Its own negative control is `--mutate-evidence` (34/0), which unregisters a gate and deletes a recorded control in a fixture copy, requires both to be detected, and re-checks the unmutated inputs green in the same run so an always-red detector cannot pass for one. Honest limit, inherited from Litmus: Half A reads a declaration and a filename and cannot know a recorded control was honestly recorded; Half B is what narrows that, and is why this criterion is a command that kills children rather than a checklist.
   122	Manifest: FROZEN 2026-08-11 — #408, #409, #426, #388, #387, #384, #358, plus #354 Phase 1. Eight named entries, a fixed denominator rather than a percentage. The first six were moved out of Litmus on 2026-08-08 after a codex+agy consult; #387 and #384 are added at freeze time because the exit criterion above already names their cases — it requires a cap-killed child and a restarted recovery, and nothing else in the milestone supplies either. **The milestone is not the manifest.** Nightwatch's milestone holds 18 open issues; the twelve not listed here (#376, #378, #379, #380, #382, #386, #391, #392, #402, #467, #491, and anything filed during execution) are backlog worked inside the 0.3.0-0.3.4 band, and none of them gates the release. Adding an entry is a RE-SCOPE, not a bugfix, under the same admission rule Litmus used: a mid-release discovery joins only if it makes the exit command fail or falsifies a named invariant, has a reproducer demonstrating that, and the operator explicitly swaps out an existing entry or accepts a date slip. Discovery is not admission.
   123	GH_URL:
   124	Milestone: Nightwatch
   125	Front-door reviewed: No
   126	Shakedown reviewed: No
   127	License file: Yes
   128	
   129	Release: 0.4.0
   130	Iterations: 0.4.0-0.4.4
   131	Status: Draft
   132	Target Date: 2026-11-14
   133	Codename: Plumbline
   134	Description: Assisted reflection and a bounded self-improvement loop, measured before either is trusted. The reflection pipeline turns durable Nightwatch records into proposals (`proposals-sink.sh` gains its first production caller) and is graded against external ground truth — the 49 human-filed findings from the two rebalance-OS marathons (#405/#406) — for recall and precision. Ships a committed benchmark and a recorded go/no-go; "not worth automating yet" is a passing result, per #431's own Phase 2 exit criterion. Operator sign-off stays manual. Depends on Nightwatch.
   135	GH_URL: [GH 431](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/431)
   136	Milestone: Plumbline
   137	Front-door reviewed: No
   138	Shakedown reviewed: No
   139	License file: Yes
   140	
   141	Release: 0.5.0
   142	Iterations: 0.5.0-0.5.4
   143	Status: Draft
   144	Target Date: 2026-12-12
   145	Codename: Lantern
   146	Description: When the harness fails, the information needed to act already exists inside it — make it say so. Not "add checks": every case was already detected, and some were then described wrongly (a stack trace, a fabricated path, a success exit code, silence). Scope is one epic, deliberately narrow, and deliberately NOT Nightwatch: that milestone owns run lifecycle "even when lifecycle code emits a misleading message" (see the scope boundary above), and none of Lantern's cases violates a lifecycle invariant — they violate the legibility of a failure whose lifecycle handling was already correct. All four members were found in one afternoon during Nightwatch wave 3, which halted three times at zero paid-turn cost; each halt was avoidable from information the system already held. Depends on nothing; independent of Plumbline.
   147	Manifest: FROZEN at one issue on creation — #499, which supersedes and closes #494, #495, #496 and #498. Four phases, each shippable alone: relay-drive launch preflight; a gate refusal that states its real reason; a launcher whose exit code survives plus a gate-readiness check; and a change-impact reporter. Freezing at one is the whole point — these were filed as four and unified precisely to stop a single coherent change spreading across four PRs. Adding a member is a RE-SCOPE, not a bugfix, per the Litmus rule above.
   148	GH_URL: [GH 499](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/499)
   149	Milestone: not created yet — #499 is unmilestoned by design while Nightwatch is the active goalpost
   150	Front-door reviewed: No
   151	Shakedown reviewed: No
   152	License file: Yes
===== PROJECT/2-WORKING/GH-388-MARATHON-RUN-LOG-DURABILITY.md
     1	---
     2	gh_issue: 388
     3	source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/388
     4	title: "GH-388 — marathon.sh persists no run log, and per-phase transcripts are written only on completion"
     5	status: "BUILT 2026-08-11 (both phases) as a lane of release 0.3.0 Nightwatch, to which it moved on 2026-08-08. Built Opus-direct rather than fired: the 2026-08-10 wave-1 plan had already recorded why this lane is not marathon-buildable — it edits marathon.sh, the outer driver bash that is reading itself by byte offset as the chain runs. Negative control recorded in test/baselines/GH-388-negative-control.md (9 red pre-fix). Full validate.sh green."
     6	created: 2026-08-06
     7	updated: 2026-08-11
     8	owner: noel
     9	doc_type: project
    10	release: "0.2.0 Litmus"
    11	complexity: 2
    12	risk: 2
    13	effort: 3
    14	phases: 2
    15	ratings_provisional: true
    16	related:
    17	  - "#419 — the class. The harness keeps a permanent record of every phase that succeeded and none of the phase that failed, so the archive is systematically biased toward success."
    18	  - "#382 — the crash whose first occurrence produced no usable profile precisely because of this."
    19	  - "#384 — recovery after an interrupted run, which is much harder without a run log."
    20	  - "#390 — its layer-5 evidence requirement depends on what this lane makes durable."
    21	non_goals:
    22	  - "Changing what the per-phase transcripts contain on success. They work; the gap is the failure path."
    23	  - "Making the invoker responsible for redirection. That is the current state and is the defect."
    24	goal: >
    25	  The failure mode guarantees the absence of the record. Per-phase transcripts are written when a
    26	  phase completes, so the phase that dies is the one phase with no transcript, and the chain-level
    27	  narrative exists only on the operator's terminal. Whether any of it survives a crash depends on
    28	  whether whoever typed the command happened to redirect stdout somewhere durable.
    29	---
    30	
    31	# GH-388 · the phase that fails is the one with no record
    32	
    33	## Status
    34	
    35	| What was just completed | What's next |
    36	|---|---|
    37	| **Both phases built 2026-08-11.** `marathon.sh` owns a durable chain run log under the same transcript root as the per-phase transcripts, announced at chain start; a phase killed mid-run leaves a content-bearing `PHASE-INTERRUPTED.md`; `rtl_default_log` refuses on both lanes instead of silently relocating to volatile storage; and the non-durable locations are stated in one runtime-read file. `test/gh388-run-log-durability.sh` 24/0, observed **9 red** pre-fix. | Close #388 against the acceptance block below. All seven criteria met — see "Acceptance — outcome". |
    38	
    39	## Acceptance — outcome
    40	
    41	1. **Met.** `marathon.sh` opens `<transcript-root>/run-logs/<date>/marathon-<plan>-<time>-<pid>.log` and `tee`s stdout+stderr into it as produced. Armed after plan validation and before the phase loop, so a usage error or an unparseable plan leaves no log implying a run happened; `--dry-run` is excluded for the same reason, and that exclusion is asserted.
    42	2. **Met.** `marathon: run log: <path>` is printed at chain start, and the test parses that line rather than guessing the path — if the announcement breaks, the test cannot find the file.
    43	3. **Met.** `_write_interrupted_phase_record` writes `PHASE-INTERRUPTED.md` carrying the phase id, the relay `STATUS:` read *at interruption*, the recorded round count, the reason and the exit code. Asserted on content, not existence, and against a marker stamped after dispatch — the empty-file and pre-created-file loopholes the issue's own review found.
    44	4. **Met, both lanes.** `rtl_default_log` in `utils/py/rtl.py` and in `relay-turn-lib.sh` now exit 5 rather than returning a `$TMPDIR` path, and the resolver's stderr is no longer swallowed (`quiet=True` is gone), so the refusal names *why* the root failed to resolve. `test/relay-turn-trace.sh`'s case 3c, which pinned the old fallback, is inverted with the rationale recorded in place.
    45	5. **Met.** `relay-automation/non-durable-log-roots.conf` is the single registry, read at runtime by `durable-log-lib.sh` (Bash) and `rtl.py::non_durable_reason` (Python). The test asserts the two readers agree on every probe path *and* that an invented entry changes the verdict — without that second assertion the file could be decorative while the real list lived in the readers.
    46	6. **Met.** Part C kills a running phase; Part D kills a running chain. Both assert on what is left on disk.
    47	7. **Met.** `test/baselines/GH-388-negative-control.md` carries both runs in full: 9 red pre-fix, 0 after.
    48	
    49	## Acceptance — deviations found while building
    50	
    51	**The durability rule is scoped to RELOCATION, not to absolute location.** A transcript that resolves
    52	*inside the repo being driven* is permitted even when that repo sits in `$TMPDIR`; only a path that is
    53	both non-durable *and* outside the repo is refused. Criterion 5 reads "a default log path resolving
    54	into one of them fails the run", which taken literally refuses to run the harness inside every fixture
    55	in this suite — every one of them is a repo under `$TMPDIR`. A guard that cannot be exercised is not a
    56	guard, and "fails the run" would have meant "fails every run". The defect being fixed is the harness
    57	*silently moving* evidence out of the repo; a repo the operator put in `/tmp` makes the code, the
    58	commits and the log volatile together, visibly, by their choice.
    59	
    60	**Two defects were found by this lane's own test rather than reasoned about.**
    61	
    62	- **The driver's narrative was block-buffered.** Python block-buffers stdout when it is not a TTY, and
    63	  a marathon is never a TTY — so the buffering is not an edge case, it *is* the unattended path. The
    64	  first kill-mid-run recovered a log containing the child turn-shim's output and none of
    65	  `marathon-drive`'s own: the subprocesses wrote straight to the fd and survived, while every
    66	  `marathon-drive: …` line sat in a buffer that SIGTERM discards. A run log fed by a buffered writer
    67	  records the run right up to the moment something goes wrong. Fixed with `line_buffering=True`.
    68	- **SIGTERM never reached the exit hooks.** `marathon_drive.py` already had an `_ON_EXIT` list run from
    69	  a `finally`, but SIGTERM terminates CPython immediately — no `finally`, no hooks, no record. SIGINT
    70	  already raised `KeyboardInterrupt` and so already reached them; SIGTERM is what an unattended run
    71	  actually receives. Converted to `SystemExit(128+signum)`, which is the convention `_exit_meaning`
    72	  and `marathon.sh`'s halt table already read. **SIGKILL and a host panic remain unreachable** — that
    73	  is stated in the code rather than papered over, and is why #384's recovery path is a separate lane
    74	  rather than something this one quietly claims to cover.
    75	
    76	## The defect
    77	
    78	`marathon.sh` persists none of its own output — no `tee`, no `exec >`, no log-file variable. What is
    79	durable is written **per phase, on completion**. In the observed run, phases 1–4 completed and each
    80	has a transcript; phase 5 is the one that killed the host, and there is no transcript for it.
    81	
    82	**The fallback is not a fallback.** The only surviving account of phase 5 was the terminal stream,
    83	which had been redirected to a path the platform clears at boot. After the panic reboot it was gone.
    84	That choice was the invoker's and a poor one — but the harness offered no alternative and gave no
    85	indication one was needed.
    86	
    87	**There is a related silent path inside XYZ itself.** `rtl_default_log` resolves the durable
    88	transcript root and, on failure, falls back to a temporary directory *with the diagnostic
    89	suppressed*. A misconfigured archive root silently relocates turn logs into the one directory a crash
    90	erases, and prints nothing. This did not fire in the observed run — it is a live code path, not an
    91	observed failure, and this doc keeps that distinction.
    92	
    93	## Two corrections the review produced
    94	
    95	Both from codex, both verified against `development` @ `3b37072` before being acted on:
    96	
    97	- **A criterion of mine rested on a false premise.** It asserted that *"the repo's own PDDA lint
    98	  already classifies those locations as non-durable."* It does not — `check_hardcoded_paths` reads
    99	  `pdda_list_working_docs` and scans **documentation** for literal absolute paths. It says nothing
   100	  about runtime log destinations. The criterion was rewritten to require the harness to state the
   101	  non-durable set somewhere it actually reads at runtime.
   102	- **"Writes a partial transcript" was satisfiable by an empty file.** A static or pre-created
   103	  transcript met the words while the failing phase's evidence remained absent. It now requires the
   104	  file to have been created or modified *after that phase started* and to carry the phase id, the
   105	  relay state at interruption, and the failure reason.
   106	
   107	Agy independently found the third: *"no longer silent"* was satisfiable by adding a print statement
   108	while still writing to volatile storage — the logs would still be destroyed, the defect completely
   109	unfixed.
   110	
   111	## Acceptance
   112	
   113	*Copied verbatim from [issue #388](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/388)
   114	(`## Acceptance`), fetched 2026-08-06. Deviations, if any, are recorded below this block.*
   115	
   116	- [ ] A durable run log captures the whole chain's output as it is produced, under the same transcript root the per-phase transcripts already use. Where the run narrative goes is the harness's decision, not the invoker's.
   117	- [ ] The run log's path is printed at chain start, so an operator knows where to look afterwards.
   118	- [ ] A phase that escalates, times out, or dies mid-gate leaves a transcript that was **created or modified after that phase started** and contains the phase id, the relay state at interruption, and the failure or kill reason. An empty or pre-created file does not satisfy this.
   119	- [ ] `rtl_default_log` does not silently relocate turn logs to volatile storage. It either resolves a durable root or refuses before the turn launches; if a volatile fallback is retained, it is reported as non-durable and is never presented as the turn transcript. Adding a message while still writing to storage a reboot erases does not satisfy this.
   120	- [ ] The locations the harness treats as non-durable are stated in one place it actually reads at runtime, and a default log path resolving into one of them fails the run rather than proceeding.
   121	- [ ] A regression test kills a phase mid-run and asserts that both a chain-level run log and a content-bearing partial phase transcript survive.
   122	- [ ] The regression test is observed failing against the pre-fix revision, and a durable record states the reproducer command, the pre-fix revision, the pre-fix result and the post-fix result. A sentence asserting a negative control happened is not the record, per #419.
   123	
   124	## Acceptance — deviations from the issue
   125	
   126	None. Every criterion is carried verbatim.
   127	
   128	The criteria were **authored onto the issue on 2026-08-05** (it had none) and **revised on 2026-08-06**
   129	after the codex+agy review, for the three reasons above. The `tee` prescription was also dropped —
   130	both reviewers noted it named a mechanism where an outcome was wanted.
   131	
   132	## Phases
   133	
   134	| Phase | Deliverable | Artifacts | cx/risk/eff |
   135	|---|---|---|---|
   136	| 1 | The chain run log. One durable file opened at chain start under the same transcript root the per-phase transcripts use, capturing the chain's output as it is produced, with its path printed at start. Plus a content-bearing partial transcript when a phase escalates, times out, or dies mid-gate. | `relay-automation/marathon.sh`, `utils/py/marathon_drive.py` | 2/2/3 |
   137	| 2 | The durability rule. The non-durable locations are stated in one place the harness reads at runtime; `rtl_default_log` resolves a durable root or refuses before the turn launches, and a retained volatile fallback is never presented as the turn transcript. Plus the kill-mid-run regression. | `utils/py/rtl.py`, `test/gh388-run-log-durability.sh`, `validate.sh` | 2/2/3 |
   138	
   139	## Litmus tests
   140	
   141	- **A green suite is not evidence here.** Everything works on the success path today. The only
   142	  assertion that matters is what survives a kill, so the regression must actually kill a phase.
   143	- **An empty transcript passes a naive check.** Assert content — phase id, relay state, reason — not
   144	  existence. This was a real hole in the first draft.
   145	- **A message is not a fix.** If the fallback still writes to storage a reboot erases, the evidence
   146	  still disappears; the message only means someone could have known.
   147	
   148	## Swarm Preflight Contract
   149	
   150	```json
   151	{
   152	  "target":        { "repo": ".", "ref": "development" },
   153	  "gate":          "bash validate.sh",
   154	  "fix_probes":    [
   155	    { "type": "path_absent", "path": "test/gh388-run-log-durability.sh" },
   156	    { "type": "grep_absent", "path": "relay-automation/marathon.sh", "pattern": "run log" }
   157	  ],
   158	  "artifacts":     [ "relay-automation/marathon.sh", "utils/py/marathon_drive.py", "utils/py/rtl.py", "test/gh388-run-log-durability.sh", "validate.sh" ],
   159	  "artifacts_new": [ "test/gh388-run-log-durability.sh" ],
   160	  "remediation":   { "source": "issue#388", "criteria": "the harness owns a durable chain run log, and a failing phase leaves evidence — ranking summary only, NOT the definition of done (that is the verbatim ## Acceptance block above)" },
   161	  "lanes":         { "agy_safe": [], "orchestrator_only": [] }
   162	}
   163	```
   164	
   165	**Probe polarity** (probes detect the **bug**, not the fix): `path_absent` reports `landed` when the
   166	path *exists*; `grep_absent` reports `landed` when the pattern *is found*. Verified 2026-08-06:
   167	`run log` occurs **0 times** (case-insensitive) in `relay-automation/marathon.sh`.
   168	
   169	**`relay-automation/marathon.sh` is not a frozen twin** — verified 2026-08-06, no GH-308 banner — so
   170	Phase 1 may edit it directly. `utils/py/rtl.py` is the authoritative Python lane.
   171	
   172	## Method note
   173	
   174	The phase-5 evidence, the cleared-temp-directory finding and the `rtl_default_log` code path are
   175	carried from the issue. The PDDA-lint correction and the empty-transcript loophole came from the
   176	codex review and were verified directly before being written as criteria. No open PR or branch
   177	touches this issue — checked before authoring.
===== PROJECT/2-WORKING/GH-358-LOCK-FLAKE-INSTRUMENTATION.md
     1	---
     2	gh_issue: 358
     3	source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/358
     4	title: "GH-358 — xyz-completion's 16-way concurrent-append assertion flakes on the shared CI runner"
     5	status: "Intake (2-WORKING) — captured 2026-08-06 for release 0.2.0 Litmus, preflight READY, awaiting operator go."
     6	created: 2026-08-06
     7	updated: 2026-08-06
     8	owner: noel
     9	doc_type: project
    10	release: "0.2.0 Litmus"
    11	complexity: 2
    12	risk: 2
    13	effort: 2
    14	phases: 2
    15	ratings_provisional: true
    16	related:
    17	  - "#419 — the class, in an unusual form: the test is a decision gate that cannot distinguish a flake from the defect it exists to catch, so neither verdict is evidence."
    18	  - "#232 — the CI step is already named 'minus a documented flaky test', so a second exclusion arriving unnoticed is how a suite drifts into being re-run until green."
    19	non_goals:
    20	  - "Lowering M from 16. It makes the symptom disappear and the safety property untested."
    21	  - "Dropping the distinctness check, for the same reason."
    22	  - "Deciding the disposition before the instrumentation exists. The issue is explicit that instrumenting comes first."
    23	  - "Treating this as an ordinary flake. A flaky LOCK test is the one kind that cannot be waved off."
    24	goal: >
    25	  A 16-way concurrent-append assertion intermittently loses one record on the shared runner. Both
    26	  assertions are correct statements about a real safety property. The problem is that "flaky" and
    27	  "the lock genuinely loses a write under contention" produce an identical symptom, and nothing in
    28	  the output can tell them apart — so the test cannot currently be evidence either way.
    29	---
    30	
    31	# GH-358 · a lock test that cannot tell a flake from the bug
    32	
    33	## Status
    34	
    35	| What was just completed | What's next |
    36	|---|---|
    37	| Captured 2026-08-06 as a lane of release 0.2.0 Litmus. Acceptance criteria authored on the issue (it had none) and revised after an adversarial codex+agy review, which found that every appender's exit status is discarded today and that two different lock bounds are in play. | Operator go. Then Phase 1 (instrument: retain exit status, report the missing record's terminal state, name both bounds) and only then Phase 2 (choose the disposition on that evidence). |
    38	
    39	## The defect
    40	
    41	`test/xyz-completion.sh`'s lock-under-concurrency case fails intermittently on the shared runner,
    42	losing one of 16 records. The same commit re-run passed; it passes locally. The originating PR's
    43	diff touched neither the test nor the appender.
    44	
    45	**Why this is not "just re-run it":**
    46	
    47	1. **It is a lock test.** "Flaky" and "the lock genuinely loses a write under contention" produce
    48	   the identical symptom. The failure says a record was clobbered — which is *also* exactly what a
    49	   real lock bug says.
    50	2. **A second flaky exclusion arriving unnoticed** is how a suite drifts into being re-run until
    51	   green. The CI step is already named for one documented exclusion.
    52	3. **A red run on an unrelated PR trains people to re-run rather than read**, which is the habit
    53	   that lets a real regression through.
    54	
    55	## What the review added
    56	
    57	Two findings from the codex review, both verified against `development` @ `3b37072`:
    58	
    59	- **Every appender's exit status is discarded.** The harvest loop is
    60	  `for p in $pids; do wait "$p" 2>/dev/null || true; done`, in two places. So a crashed or killed
    61	  appender is indistinguishable from one that acquired the lock and lost its record — the test
    62	  cannot currently attribute the failure even in principle.
    63	- **Two different bounds are in play.** The test waits on one budget; the writer defaults to
    64	  `XYZ_LOCK_WAIT_S` at another, smaller value. A report that names "the timeout" without saying
    65	  which one was exhausted is not actionable.
    66	
    67	## Acceptance
    68	
    69	*Copied verbatim from [issue #358](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/358)
    70	(`## Acceptance`), fetched 2026-08-06. Deviations, if any, are recorded below this block.*
    71	
    72	- [ ] Each of the 16 appenders' exit status is retained and asserted. Today every one is discarded (`wait "$p" 2>/dev/null || true`), so a crashed appender is indistinguishable from a lost record; any non-zero exit must fail the assertion in its own right.
    73	- [ ] On a mismatch the report identifies the missing `sessionId` **and its terminal state**: lock acquired and record lost, lock never acquired, or process failed. Those have opposite priorities and today produce an identical symptom.
    74	- [ ] Both effective lock bounds are named in the failure output — the test's own wait and the writer's `XYZ_LOCK_WAIT_S` default, which differ today — and the report states which one was exhausted.
    75	- [ ] The change ships the instrumentation output from a reproduced failure, and the disposition applied is the one that evidence indicates. A disposition chosen without that output does not satisfy this.
    76	- [ ] `M` is not lowered from 16 and the distinctness check is not dropped. Both make the symptom disappear and leave the safety property untested.
    77	- [ ] If it goes on the CI exclusion list, the workflow states **why**, so a reader does not take the exclusion to mean the property is not worth checking.
    78	- [ ] The instrumentation is demonstrated to distinguish the causes: a deliberately clobbered record and a deliberately starved appender produce visibly different reports. A lock test that cannot tell a flake from a real lost update is not evidence, per #419.
    79	
    80	## Acceptance — deviations from the issue
    81	
    82	None. Every criterion is carried verbatim.
    83	
    84	The criteria were **authored onto the issue on 2026-08-05** (it had none) and **revised on 2026-08-06**
    85	after the codex+agy review. Two changes are worth naming: the exit-status criterion is new and came
    86	from reading the test rather than the issue, and the original *"the disposition is chosen after that
    87	evidence exists"* was replaced — both reviewers correctly said a reviewer cannot verify the temporal
    88	order of someone's decisions. It now requires the instrumentation output to ship with the change.
    89	
    90	## Phases
    91	
    92	| Phase | Deliverable | Artifacts | cx/risk/eff |
    93	|---|---|---|---|
    94	| 1 | Instrumentation. Retain and assert each appender's exit status; on mismatch report the missing record's terminal state — lock acquired and record lost, lock never acquired, or process failed — and name both effective bounds with the one that was exhausted. | `test/xyz-completion.sh`, `utils/telemetry/append-xyz-completion.sh`, `test/gh358-lock-instrumentation.sh` | 2/2/2 |
    95	| 2 | Disposition, on that evidence. Raise the bound, retry the assertion, or exclude with a stated reason in the workflow. `M` stays 16 and the distinctness check stays. | `.github/workflows/ci.yml` or `test/xyz-completion.sh` | 1/2/1 |
    96	
    97	**Phase 2 must not be pre-committed in the packet.** A builder told which disposition to apply will
    98	produce instrumentation that agrees with the instruction — the same defect as grading against a
    99	model-authored requirement.
   100	
   101	## Litmus tests
   102	
   103	- **The instrumentation is itself a decision gate**, so it needs its own negative control: a
   104	  deliberately clobbered record and a deliberately starved appender must produce visibly different
   105	  reports. If it cannot tell those apart it has not fixed anything.
   106	- **A green run proves nothing here.** The failure is intermittent; a passing suite after the change
   107	  is consistent with the instrumentation never having been exercised. The controls above are the
   108	  only evidence.
   109	- **If the answer turns out to be a real lock bug, the priority changes completely** and this lane
   110	  should stop and re-file rather than proceed to Phase 2's exclusion option.
   111	
   112	## Swarm Preflight Contract
   113	
   114	```json
   115	{
   116	  "target":        { "repo": ".", "ref": "development" },
   117	  "gate":          "bash validate.sh",
   118	  "fix_probes":    [
   119	    { "type": "path_absent", "path": "test/gh358-lock-instrumentation.sh" },
   120	    { "type": "grep_absent", "path": "test/xyz-completion.sh", "pattern": "terminal state" }
   121	  ],
   122	  "artifacts":     [ "test/xyz-completion.sh", "utils/telemetry/append-xyz-completion.sh", "test/gh358-lock-instrumentation.sh", ".github/workflows/ci.yml", "validate.sh" ],
   123	  "artifacts_new": [ "test/gh358-lock-instrumentation.sh" ],
   124	  "remediation":   { "source": "issue#358", "criteria": "make the lock assertion able to distinguish a flake from a lost update — ranking summary only, NOT the definition of done (that is the verbatim ## Acceptance block above)" },
   125	  "lanes":         { "agy_safe": [], "orchestrator_only": [] }
   126	}
   127	```
   128	
   129	**Probe polarity** (probes detect the **bug**, not the fix): `path_absent` reports `landed` when the
   130	path *exists*; `grep_absent` reports `landed` when the pattern *is found*. Verified 2026-08-06:
   131	`terminal state` occurs **0 times** in `test/xyz-completion.sh`.
   132	
   133	**This lane's artifacts include `test/*.sh` it must edit.** Per the marathon plan's standing note,
   134	those are read-only specs in-turn and the outer harness gate verifies them after the turn, outside
   135	the isolated worktree.
   136	
   137	## Method note
   138	
   139	The flake evidence and the "do not lower M / do not drop distinctness" constraints are carried from
   140	the issue. The discarded-exit-status finding and the two-bound mismatch came from the codex review
   141	and were verified directly against `development` @ `3b37072` before being written as criteria. No
   142	open PR or branch touches this issue — checked before authoring.
===== PROJECT/2-WORKING/GH-354-CONCURRENT-SWARMS.md
     1	---
     2	title: Concurrent swarms — make the driver-lock scope true, provable, and observable before selling parallelism
     3	status: "Active (2-WORKING) — opened 2026-07-30. Phase 0 discovery COMPLETE (findings below, verified against `development` at `b93fd93`). Phase 0 overturns three of issue #354's five collision claims and promotes its single observability footnote to the plan's highest-severity finding. Phase 1 is next and is a correctness fix, not a feature."
     4	created: 2026-07-30
     5	updated: 2026-07-30
     6	owner: noel
     7	gh_issue: 354
     8	source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/354
     9	doc_type: bugfix
    10	effort: 3
    11	complexity: 4
    12	risk: 3
    13	phases: 5
    14	branch: claude/pdda-compliance-plan-e4mua0
    15	non_goals:
    16	  - Shipping per-worktree concurrent swarms. This plan does NOT enable parallelism.
    17	    Phases 1–3 make the current exclusion contract true and observable; Phase 4 only
    18	    decides whether opt-in per-worktree parallelism is worth building, and needs its
    19	    own issue + GO if the answer is yes.
    20	  - Removing or weakening the GH-42 `ROOT@HEAD` guard. The guard stays until
    21	    something proves containment, and Phase 0 found no such proof in the tree.
    22	  - Reworking `TICK_REPO_ROOT` resolution. Phase 0 established `.tick/` is already
    23	    per-worktree; the vendored-mismatch question is GH-272's and stays there.
    24	  - Reviving the Bash twins as an authored surface. GH-308 froze them; this plan
    25	    patches them only where a fix must land on both lanes to be real.
    26	  - Any change to `xyz-vendor.sh`'s preserve list. `.relay-driver.lock` is already
    27	    preserved (`relay-automation/xyz-vendor.sh:300`); Phase 1 changes where the lock
    28	    lives in a linked worktree, not what vendoring keeps.
    29	related:
    30	  - "#354 — the originating analysis this plan reviews and corrects."
    31	  - "#42 — the `ROOT@HEAD` concurrent-run hazard the driver lock exists to prevent.
    32	    Phase 0 found the lock does not actually cover two of the three concurrency
    33	    pairs, so #42's guarantee is narrower in a linked worktree than its own error
    34	    message claims."
    35	  - "#49 / GH-49b — the vendored-`.xyz/` and linked-worktree lock-path resolution
    36	    that `marathon-drive` has and `relay-drive` never received."
    37	  - "#308 — Bash-twin freeze + behavior audit. Every Phase 1/2 fix has to land on
    38	    the Python twin (the default lane since GH-264) AND its frozen Bash sibling, or
    39	    it silently does not run; this is the exact failure class #308 catalogued."
    40	  - "#272 — `TICK_REPO_ROOT` vendored mismatch. Adjacent, deliberately NOT merged in:
    41	    Phase 0 found `.tick/` is per-worktree today, so the namespacing #354 proposed
    42	    is not needed for the worktree shape."
    43	  - "#292 — `find-harness.sh` misses a vendored `.xyz/` from a linked worktree. Same
    44	    root cause family: `-d .git` as a proxy for \"is a repo root\"."
    45	  - "#11 — `--target-root` / registry cross-repo targeting, the separate-clones shape
    46	    this plan's quick-win path leans on."
    47	goal: >
    48	  A single truthful sentence about concurrency, provable by a test, and visible in
    49	  the monitors: state exactly which driver pairs exclude each other in a linked
    50	  worktree, make all three pairs behave the way the lock's own error message already
    51	  claims they do, and stop the fleet monitors reporting a LIVE worktree run as IDLE.
    52	  Only then decide whether opt-in parallelism is worth building.
    53	---
    54	
    55	# GH-354 — Concurrent swarms: make the lock contract true before making it optional
    56	
    57	Issue [#354](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/354)
    58	answers "can two swarms run in linked worktrees of one clone?" with *no, by design* and lists five
    59	collisions plus one observability bug. This doc is the review of that answer.
    60	
    61	The verdict changes. #354's conclusion — **use separate clones** — is right, and Phase 0 confirms it.
    62	But it is right for a different reason than the issue gives, and #354's own footnote is the most
    63	serious defect in the set. Specifically:
    64	
    65	- The lock is **not** the hard blocker #354 describes. It blocks one of three concurrency pairs.
    66	- Three of the five "what still collides if you bypassed the lock" items **do not collide** in a
    67	  linked worktree, because `.tick/` is already per-worktree.
    68	- The observability bug filed as "worth filing regardless" is **not one script**. It is three, and
    69	  it means an operator cannot see the state that the whole exclusion argument depends on.
    70	
    71	## Status
    72	
    73	| What was just completed | What's next |
    74	|---|---|
    75	| **2026-07-30: Phase 0 discovery complete.** Reviewed the actual lock, lane-namespace, session-identity and monitor surfaces on `development` at `b93fd93` — including `relay-drive.sh` and `relay-turn-lib.sh`, which #354 flagged as unavailable and therefore reasoned about from `marathon-drive.sh`'s comments. Both are present and the comments are wrong. **Confirmed:** the marathon↔marathon exclusion, `MARATHON_LANE_NS` existing as the lane override, the `XYZ_SESSION_ID` → `PHASE_ID` fallback, and the monitor's false-IDLE. **Overturned:** (a) marathon↔relay and relay↔relay do **not** mutually exclude in a linked worktree — `relay-drive` never received GH-49b's worktree branch, on either runtime, so it takes a per-worktree lock while `marathon-drive` takes a shared one; (b) `.tick/` task ids, lane attempt counters and `tick analyze` cost do **not** commingle across linked worktrees, because `TICK_REPO_ROOT` defaults to each shim's own `ROOT`; (c) the `git worktree add/prune` exposure is the shared `worktrees/` admin registry and an add-vs-prune race, not `ROOT@HEAD` — `--detach … HEAD` resolves per-worktree. **Escalated:** the false-IDLE bug also exists in `utils/hq/marathon-live.sh` and `utils/hq/hourly-global-scan.sh`. Findings, with `file:line`, in [Phase 0](#phase-0--discovery-verify-354s-claims-against-the-code-complete). | Phase 1 — mirror GH-49b's worktree lock branch into `relay-drive` on **both** runtimes, with a regression test that fails pre-fix. This is a GH-42 containment fix and should not wait on the rest of the plan. |
    76	
    77	## Table of contents
    78	
    79	- [Phase 0 — Discovery: verify #354's claims against the code (COMPLETE)](#phase-0--discovery-verify-354s-claims-against-the-code-complete)
    80	- [Phase 1 — Close the relay-drive worktree lock gap (correctness)](#phase-1--close-the-relay-drive-worktree-lock-gap-correctness)
    81	- [Phase 2 — Make a live worktree run visible to the monitors](#phase-2--make-a-live-worktree-run-visible-to-the-monitors)
    82	- [Phase 3 — Write the one true concurrency sentence, and test it](#phase-3--write-the-one-true-concurrency-sentence-and-test-it)
    83	- [Phase 4 — Decision gate: is opt-in per-worktree parallelism worth building?](#phase-4--decision-gate-is-opt-in-per-worktree-parallelism-worth-building)
    84	
    85	---
    86	
    87	## Phase 0 — Discovery: verify #354's claims against the code (COMPLETE)
    88	
    89	**What was investigated.** Every mechanism #354 names, read on `development` at `b93fd93`: the driver
    90	lock in both drivers on both runtimes, the lane-attempt and session-identity namespacing, the
    91	throwaway-worktree lifecycle in `relay-turn-lib.sh`, `.tick/` root resolution, and the fleet monitors.
    92	#354 carries an explicit caveat that `relay-drive.sh` and `relay-turn-lib.sh` "aren't in this
    93	project's files," so its lock-mirror and `rtl_worktree_begin` claims rest on `marathon-drive.sh`'s
    94	comments. Both files are in the tree. Closing that caveat is what changes the plan.
    95	
    96	### Finding 0.1 — CONFIRMED, and narrower than stated: the marathon lock is shared per clone
    97	
    98	`relay-automation/marathon-drive.sh:197-208` and its Python twin
    99	`utils/py/marathon_drive.py:293-313` resolve the lock in three branches: `.git` is a directory →
   100	`ROOT/.git/relay-driver.lock`; `.git` is a *file* (linked worktree) → `git rev-parse
   101	--git-common-dir` → `<common>/relay-driver.lock`; neither (vendored `.xyz/`) →
   102	`ROOT/.relay-driver.lock`. Two linked worktrees of one clone therefore resolve the **same** lock and
   103	the second marathon exits 1 with *"Concurrent runs in the same clone are unsafe (GH-42 ROOT HEAD
   104	hazard)"* (`marathon-drive.sh:214-216`). #354 is exactly right here.
   105	
   106	**What it changes:** nothing on its own — this is the one pair that works.
   107	
   108	### Finding 0.2 — OVERTURNED, and the plan's headline: `relay-drive` never got the worktree branch
   109	
   110	`relay-automation/relay-drive.sh:147-152` has **two** branches, not three:
   111	
   112	```text
   113	if [[ -d "$ROOT_DIR/.git" ]]; then  _lock="$ROOT_DIR/.git/relay-driver.lock"
   114	else                                _lock="$ROOT_DIR/.relay-driver.lock"
   115	```
   116	
   117	In a linked worktree `.git` is a file, so `-d` is false and relay-drive falls to the **vendored**
   118	branch — a per-worktree `.relay-driver.lock`. `utils/py/relay_drive.py:386-391` is identical, so the
   119	gap is on the **default** runtime too (`XYZ_PYTHON-1`, `relay-drive.sh:9`), not just the frozen twin.
   120	
   121	`marathon-drive.sh:194-196` asserts the opposite in a comment: *"Same lock NAME as relay-drive so a
   122	marathon and a relay driver still mutually exclude in one clone."* The name matches. The **path** does
   123	not. So in a linked worktree:
   124	
   125	| Pair | Lock paths | Excludes? |
   126	|---|---|---|
   127	| marathon ↔ marathon | `<common>/relay-driver.lock` (both) | **yes** |
   128	| marathon ↔ relay | `<common>/relay-driver.lock` vs `<wt>/.relay-driver.lock` | **no** |
   129	| relay ↔ relay | `<wt1>/.relay-driver.lock` vs `<wt2>/.relay-driver.lock` | **no** |
   130	
   131	Two of three pairs run concurrently while printing nothing. The marathon↔relay case is the worst:
   132	both drivers operate on the **same working tree**, same HEAD, same `.tick/` — the GH-42 hazard with
   133	no guard at all, reached without bypassing anything.
   134	
   135	Second-order: the fallback lands `.relay-driver.lock` **inside the working tree**, and it is not in
   136	`.gitignore` (checked — `.gitignore` covers `.tick/` and the GH-75 telemetry trio, not the lock). That
   137	is the untracked-bookkeeping problem GH-49b's comment says the worktree branch exists to avoid
   138	(`marathon-drive.sh:191-193`). `relay-drive` has no `--require-clean` of its own, so this does not
   139	trip a documented gate today — call it a latent dirt source, not a live break, and let Phase 1's test
   140	pin it rather than asserting a consequence this pass did not observe.
   141	
   142	**What it changes:** #354's framing — *"the hard blocker (by design)"* — does not hold, so its
   143	conclusion cannot rest on the lock. Phase 1 exists, and is a GH-42 correctness fix that should not
   144	be sequenced behind the parallelism question at all.
   145	
   146	### Finding 0.3 — OVERTURNED: `.tick/` is already per-worktree, so claims 1, 2 and 4 do not fire
   147	
   148	#354 lists commingled tick task names, shared lane attempt counters
   149	(`.tick/attempts/<_lane_key>`) and one cumulative `tick analyze` total as things that "still collide
   150	if you bypassed the lock." In the linked-worktree shape they do not.
   151	
   152	`marathon-drive.sh:74-76` / `marathon_drive.py:184-198` set `ROOT` to the harness clone dir — the
   153	**worktree** path for a linked worktree — and `marathon_drive.py:805` (`relay-drive` and every turn
   154	shim likewise, e.g. `relay-automation/claude-turn.sh:101-103`) exports `TICK_REPO_ROOT="$ROOT"`.
   155	`bin/tick:19` honours that env var first. `.tick/` is gitignored (`.gitignore:1`), so it is never
   156	checked out and each worktree materialises its own. Attempt counters
   157	(`marathon-drive.sh:99`, `:130`) and `tick analyze` (`marathon-drive.sh:180`) both read
   158	`${TICK_REPO_ROOT:-$ROOT}` and are therefore per-worktree.
   159	
   160	Two swarms both driving a task named `MARATHON-P1-TURN` (`marathon-drive.sh:760`) in **separate**
   161	`.tick` roots is harmless — the id is only a collision when the root is shared. That happens in a
   162	different shape: two swarms in the *same* directory, or an operator pinning `TICK_REPO_ROOT` to a
   163	common root (which the isolated-turn path deliberately does — `aider-turn.sh:268` keeps `.tick`
   164	coordination state shared on purpose).
   165	
   166	**What it changes:** deletes three of five collision items from the worktree shape and re-points them
   167	at the shared-`TICK_REPO_ROOT` shape, where they are real. It also removes the need for the
   168	`.tick`-namespacing work #354 proposed as "harder" step 2 — that work is not required for worktrees
   169	and belongs to GH-272's question if it is required at all. Net: the plan gets smaller and more honest.
   170	
   171	### Finding 0.4 — REFRAMED: the throwaway-worktree exposure is the admin registry, not `ROOT@HEAD`
   172	
   173	`relay_turn_lib.sh`'s `rtl_worktree_begin` (`relay-automation/relay-turn-lib.sh:539-562`) does
   174	`mktemp -d` then `git -C "$RTL_ROOT" worktree add --detach "$wt" HEAD`; `rtl_worktree_end`
   175	(`:714-715`) does `worktree remove --force` then `worktree prune`. Because `HEAD` is resolved through
   176	`git -C "$RTL_ROOT"`, each linked worktree pins **its own** HEAD, and `mktemp -d` guarantees distinct
   177	paths even on GH-236's relocated root (`<common>/rtl-worktrees`, `:552-556`) which *is* shared.
   178	
   179	So the two throwaway trees do not collide by path or by commit. What they share is the
   180	`<common>/worktrees/` admin registry that `add` and `prune` both mutate. One driver's `prune` will
   181	not remove a peer's live tree (its directory exists), but `prune` concurrent with a mid-flight `add`
   182	is a plausible narrow race on a partially-written entry. This pass did **not** reproduce it — stating
   183	it as a hypothesis with a named test, not a finding, is the honest form and Phase 4 owns proving or
   184	dismissing it.
   185	
   186	**What it changes:** #354's *"That's the GH-42 hazard directly"* is too strong. The `ROOT@HEAD`
   187	hazard needs a different argument than the throwaway trees, and Phase 0 found **no** written
   188	reasoning for it anywhere — `marathon-drive.sh:215` asserts unsafety and cites GH-42; neither the
   189	script nor the twin explains the mechanism. #354 already noticed this; it survives Phase 0 intact and
   190	is the single biggest blocker to any future parallelism, which is why Phase 4 is a decision gate and
   191	not an implementation phase.
   192	
   193	### Finding 0.5 — CONFIRMED and ESCALATED: three monitors report a LIVE worktree run as IDLE
   194	
   195	`relay-automation/marathon-ls.sh:44-50`:
   196	
   197	```text
   198	lock_path_for_repo() { if [ -d "$repo/.git" ]; then printf '%s/.git/relay-driver.lock' ...
   199	                       else printf '%s/.relay-driver.lock' ... }
   200	```
   201	
   202	Same `-d .git` proxy. From a linked worktree it returns `<wt>/.relay-driver.lock`, which a marathon
   203	never writes (Finding 0.1 puts it in the common dir), so the monitor sees no lock and derives
   204	**IDLE** for a genuinely LIVE run.
   205	
   206	#354 files this as one script. It is three:
   207	
   208	- `relay-automation/marathon-ls.sh:44-50` — as described.
   209	- `utils/hq/marathon-live.sh:94-95` — probes `$repo/.git/relay-driver.lock` then
   210	  `$repo/.xyz/.relay-driver.lock` and returns non-zero otherwise; in a linked worktree `.git` is a
   211	  file so the first path cannot exist. The cross-repo "is-it-really-driving" answer is **no** for
   212	  every live worktree marathon in the fleet.
   213	- `utils/hq/hourly-global-scan.sh:28` — same `.git/relay-driver.lock` assumption in the hourly
   214	  global scan, so the rolling fleet snapshot inherits the same blind spot every hour.
   215	
   216	**What it changes:** promotes this from a footnote to Phase 2, and it is load-bearing for the rest of
   217	the plan. Every exclusion argument here is verified by *observing which lock is held*; if the
   218	operator's three windows onto that state are all blind in exactly the shape under discussion, no
   219	concurrency claim can be checked in the field. Note the asymmetry that makes this dangerous rather
   220	than merely wrong: post-Phase-1, a live **relay** in a worktree *will* be seen (its lock is
   221	per-worktree, which is what the monitors look for) while a live **marathon** will not — so the fleet
   222	view is not uniformly pessimistic, it is selectively wrong.
   223	
   224	### Phase 0 QA gate
   225	
   226	- [x] `relay-drive.sh` and `relay-turn-lib.sh` read directly; #354's caveat closed and its
   227	      comment-derived claims re-tested against code.
   228	- [x] Every claim in #354 marked CONFIRMED / OVERTURNED / REFRAMED / ESCALATED with `file:line`.
   229	- [x] Both runtimes checked for each finding (Bash + `utils/py/`), since a Bash-only reading of a
   230	      Python-default lane is the GH-308 failure class.
   231	- [x] Findings written back into this doc (PDDA discovery contract), not left in session context.
   232	- [x] Unproven items (the add-vs-prune race; the `.relay-driver.lock` dirt consequence) labelled as
   233	      hypotheses with owning phases, not reported as findings.
   234	
   235	---
   236	
   237	## Phase 1 — Close the relay-drive worktree lock gap (correctness)
   238	
   239	Ship Finding 0.2's fix. Mirror `marathon-drive`'s three-branch resolution into `relay-drive` so the
   240	lock name and the lock **path** agree, on both runtimes.
   241	
   242	Scope — four files, one behavior:
   243	
   244	- `relay-automation/relay-drive.sh:147-152` — add the `-f "$ROOT_DIR/.git"` → `--git-common-dir`
   245	  branch, byte-consistent with `marathon-drive.sh:197-208` including the `.git/relay-driver.lock`
   246	  label and the empty-`common-dir` fallback.
   247	- `utils/py/relay_drive.py:386-391` — same, mirroring `utils/py/marathon_drive.py:293-313`.
   248	- The Bash pair is GH-308-frozen. It gets the patch anyway: leaving `XYZ_PYTHON=0` with a silently
   249	  weaker containment guard is the same "fake safety gate in the fallback" call already made at
   250	  `marathon-drive.sh:685`. Note it in the GH-308 audit doc rather than inventing a new exemption.
   251	
   252	Deliberately **not** in Phase 1: extracting the resolution into one shared helper. That is the right
   253	end state and the wrong first move — a fifth copy is a fifth thing to drift, but a refactor across a
   254	frozen twin and a live lane is a bigger blast radius than the bug. Re-raise it after Phase 3's test
   255	pins the behavior from both sides.
   256	
   257	### Phase 1 QA gate
   258	
   259	- `test/driver-lock.sh` extended (or a sibling added and **registered in `validate.sh`'s explicit
   260	  `TESTS=()` array** — GH-292 recorded that an unregistered test silently never runs) covering, in a
   261	  real `git worktree add`ed fixture:
   262	  - a live marathon lock in the common dir **refuses** a relay start in the worktree (exit 1) — this
   263	    is the assertion that fails pre-fix;
   264	  - a live relay in worktree W1 **refuses** a relay in W2 of the same clone;
   265	  - both assertions run under `XYZ_PYTHON=1` **and** `XYZ_PYTHON=0`;
   266	  - the vendored `.xyz/` (no `.git`) and plain-clone paths are **unchanged** — byte-identical lock
   267	    path to pre-fix, so the fix cannot regress the two shapes that work today.
   268	- The new test is observed **failing before** the fix and passing after, and that observation is
   269	  recorded here (`gh319`/`gh312` precedent: a test not seen red is not evidence).
   270	- `./validate.sh` green, with the run's pass/fail counts recorded here — not "green" as prose.
   271	- `utils/pdda/pdda.sh run` clean.
   272	
   273	---
   274	
   275	## Phase 2 — Make a live worktree run visible to the monitors
   276	
   277	Fix Finding 0.5 in all three monitors. Each needs the same `-f .git` → `--git-common-dir` probe added
   278	ahead of its existing fallbacks, and each must keep working when `git` is absent or the path is not a
   279	repo at all (these are read-only fleet monitors — degrade to the current answer, never error).
   280	
   281	- `relay-automation/marathon-ls.sh:44-50` — `lock_path_for_repo` returns the common-dir path for a
   282	  linked worktree. Its header comment (`:41-43`) documents only two shapes and must document three.
   283	- `utils/hq/marathon-live.sh:94-95` — add the common-dir probe to the ordered candidate list.
   284	- `utils/hq/hourly-global-scan.sh:28` — same, so the hourly snapshot stops inheriting the blind spot.
   285	
   286	Sequenced **after** Phase 1 on purpose: post-Phase-1 both drivers write predictable per-shape paths,
   287	so the monitors are taught one rule rather than being taught to model today's inconsistency.
   288	
   289	### Phase 2 QA gate
   290	
   291	- A fixture worktree with a marathon lock held in the common dir renders **LIVE** in
   292	  `marathon-ls.sh`, and `marathon-live.sh` answers "really driving: yes" — both assertions failing
   293	  pre-fix.
   294	- Plain-clone and vendored-`.xyz/` repos render exactly as before (regression guard on the two
   295	  working shapes).
   296	- No monitor errors or exits non-zero on: a bare path that is not a git repo, a worktree whose common
   297	  dir is gone, and `git` unavailable on `PATH`.
   298	- `./validate.sh` green with counts recorded; `utils/pdda/pdda.sh run` clean.
   299	
   300	---
   301	
   302	## Phase 3 — Write the one true concurrency sentence, and test it
   303	
   304	The reason this issue was asked at all is that no document says what the lock guarantees, and the one
   305	place that tries — `marathon-drive.sh:194-196` — is wrong. Fix the docs *from the tests*, so the
   306	sentence and the behavior cannot drift apart again.
   307	
   308	- State the exclusion matrix (Finding 0.2's table, post-Phase-1: all three pairs exclude per clone)
   309	  in `skills/relay-xyz/SKILL.md`, which is the vendored surface every `.xyz/` install reads — it
   310	  currently describes the lock at `:109` without the worktree shape.
   311	- Correct `marathon-drive.sh:194-196`'s comment and its Python counterpart so "same NAME" is no
   312	  longer offered as the reason two drivers exclude; the reason is the resolved path.
   313	- Record the recommended shape for actually running two swarms — **separate full clones**, per #354's
   314	  quick win, which Phase 0 endorses — plus the cheap per-run hygiene that makes the event stream
   315	  readable even across clones: distinct `--phase-id` / `--relay-task` (`marathon-drive.sh:655-656`),
   316	  `MARATHON_LANE_NS` (`marathon-drive.sh:761` — the lane override already exists, confirming #354's
   317	  quick win #2) and `XYZ_SESSION_ID`, whose fallback to `PHASE_ID`
   318	  (`marathon-drive.sh:436`, `marathon_drive.py:366`) the code's own comment calls useless for telling
   319	  one run from another.
   320	- Correct the record on #354 itself: post a comment noting which claims Phase 0 overturned, so the
   321	  issue thread does not remain the fleet's reference for a wrong collision list.
   322	
   323	### Phase 3 QA gate
   324	
   325	- The exclusion matrix appears in exactly **one** canonical place, with the others linking to it
   326	  (PDDA Principle #4 — one canonical place per fact); no second copy of the matrix in a driver
   327	  comment.
   328	- Every row of the documented matrix is backed by a named assertion from Phase 1/2's tests, cited by
   329	  test name in the doc.
   330	- `relay-drive.sh`'s own header documents its lock shapes to the same standard as
   331	  `marathon-drive.sh:190-196`.
   332	- `utils/pdda/pdda.sh run` clean; `#354` updated.
   333	
   334	---
   335	
   336	## Phase 4 — Decision gate: is opt-in per-worktree parallelism worth building?
   337	
   338	A gate, not an implementation phase. It ends in a written GO / NO-GO in this doc, and a NO-GO is a
   339	perfectly good outcome — Phase 0 already shows the operator's real need is met by separate clones,
   340	which cost a `git clone` and need no code.
   341	
   342	GO requires all four, and each is a real risk of coming back negative:
   343	
   344	1. **The `ROOT@HEAD` hazard is written down.** Finding 0.4: nothing in the tree explains the
   345	   mechanism. Until someone can state what breaks, `XYZ_LOCK_SCOPE=worktree` would relax a guard
   346	   whose purpose is unknown — the definition of a one-way door taken blind.
   347	2. **The add-vs-prune race is resolved.** Reproduce it against a shared `<common>/rtl-worktrees` root
   348	   (`relay-turn-lib.sh:552-556`) or dismiss it with reasoning. A hypothesis cannot gate a design and
   349	   must not be quietly dropped either.
   350	3. **Shared-ref collision has an answer.** Linked worktrees have separate HEAD and index but share
   351	   refs; two drivers committing to the same branch is not a lock problem and the lock cannot fix it.
   352	   If the answer is "each swarm owns a distinct branch," that is a contract to state and enforce, not
   353	   an assumption.
   354	4. **A real operator demand exists that separate clones do not meet.** Named, with the reason clones
   355	   were insufficient. Absent that, NO-GO on cost alone.
   356	
   357	On GO, the shape is #354's own: an opt-in `XYZ_LOCK_SCOPE=worktree` keeping the lock in `$ROOT`,
   358	default off, mirrored across all four driver files, its own issue, and its own plan doc. Not this one
   359	— by then this doc's job is done.
   360	
   361	### Phase 4 QA gate
   362	
   363	- A GO/NO-GO decision is written **into this doc** with its reasoning, and each of the four criteria
   364	  is answered explicitly (an unanswered criterion is a NO-GO, not a deferral).
   365	- On NO-GO: `#354` is closed with the separate-clones recommendation and a pointer to the Phase 3
   366	  matrix; this doc moves to `PROJECT/3-COMPLETED/` and its `ROADMAP.md` pointer is updated.
   367	- On GO: a new issue + `PROJECT/1-INBOX/GH-<n>-*.md` capture exists and is parked in `ROADMAP.md`
   368	  per the issue-first SOP; no implementation begins under this doc.
   369	- The `PROJECT/DO-NOT-BUILD.md` and `PROJECT/CONSTITUTION.md` reversibility stance is checked against
   370	  the decision before it is recorded.
   371	
   372	---
   373	
   374	## Reversibility read
   375	
   376	- **Phases 1–2 — Easy.** Both are additive branches in path-resolution functions; the plain-clone and
   377	  vendored shapes keep byte-identical paths, and each phase's gate pins that. Revert is a one-commit
   378	  `git revert`. The one live-state caveat: a driver started before the fix holds its lock at the old
   379	  path, so a mid-flight upgrade can leave a stale lock at the pre-fix location — the GH-42 self-heal
   380	  reclaims it only when the holder is dead, which is the correct behavior, and it is worth naming in
   381	  Phase 3's docs rather than discovering in the field.
   382	- **Phase 3 — Easy.** Docs and comments.
   383	- **Phase 4 — one-way door, which is why it is a gate.** Relaxing lock scope changes the containment
   384	  contract every consumer and every vendored `.xyz/` install inherits; `risk: 3` on this doc covers
   385	  Phases 1–3, and a GO would carry its own higher rating in its own doc.

exec
/bin/zsh -lc 'wc -l ROUTER.md GUIDING-PRINCIPLES.md RELEASES.md PROJECT/2-WORKING/GH-388-MARATHON-RUN-LOG-DURABILITY.md PROJECT/2-WORKING/GH-358-LOCK-FLAKE-INSTRUMENTATION.md PROJECT/2-WORKING/GH-354-CONCURRENT-SWARMS.md && nl -ba ROUTER.md && nl -ba GUIDING-PRINCIPLES.md' in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-69972-gxaghv_u
 succeeded in 0ms:
      89 ROUTER.md
     149 GUIDING-PRINCIPLES.md
     152 RELEASES.md
     177 PROJECT/2-WORKING/GH-388-MARATHON-RUN-LOG-DURABILITY.md
     142 PROJECT/2-WORKING/GH-358-LOCK-FLAKE-INSTRUMENTATION.md
     385 PROJECT/2-WORKING/GH-354-CONCURRENT-SWARMS.md
    1094 total
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

exec
/bin/zsh -lc 'nl -ba RELEASES.md
nl -ba PROJECT/2-WORKING/GH-388-MARATHON-RUN-LOG-DURABILITY.md
nl -ba PROJECT/2-WORKING/GH-358-LOCK-FLAKE-INSTRUMENTATION.md' in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-69972-gxaghv_u
 succeeded in 0ms:
     1	# Major Releases
     2	
     3	Forward-looking planning ledger for major releases — one block per release, minimal fields, blank
     4	line between blocks. Marathon plans and other forward planning cross-reference this doc for
     5	target release names/dates; it is not a history of what shipped (that's CHANGELOG.md — lessons
     6	learned belong there at ship time, not duplicated here). Contract lives in PROJECT/PDDA.md ->
     7	"RELEASES.md — release ledger". Add new fields only when a real need shows up.
     8	
     9	## This file is OPTIONAL (GH-381)
    10	
    11	**Read this before proposing an edit to it.**
    12	
    13	`RELEASES.md` is an *optional planning aid*. It is not a required artifact, it is not a checklist,
    14	and it is **not something to keep topped up**. An empty file, a stale file, or no file at all are
    15	all perfectly valid states. The tooling agrees: `pdda.sh releases` is warn-only, never blocks, and
    16	skips entirely when the file is absent — *"RELEASES.md not found — nothing to check."*
    17	
    18	**Do not offer to fill this in, populate it, bring it up to date, or add the release you just
    19	shipped.** Do not treat a sparse file as an incomplete one. If nobody is actively planning a release
    20	arc right now, the correct amount of content here is whatever is already present — including
    21	nothing.
    22	
    23	Edit it only when an operator explicitly asks for release *planning*. That is the whole trigger.
    24	
    25	## Scope boundary — Litmus (0.2.0) vs Nightwatch (0.3.0)
    26	
    27	Added 2026-08-08 after a cross-model consult (codex + agy) found the two descriptions **not
    28	decidable**: a competent agent could not route a new issue between them from the prose alone, because
    29	Litmus says checks must "report red" correctly while Nightwatch says hostile states must "fail
    30	clearly." Both advisors independently flagged this as blocking, and the overlap is worst exactly where
    31	orchestration failures emit gate-looking verdicts.
    32	
    33	> **Litmus owns faulty decision semantics.** A named acceptance, preflight, reviewer, or pre-advance
    34	> check returns pass, fail, or a *reason* inconsistent with a controlled input's observable outcome —
    35	> or lacks a recorded negative control.
    36	>
    37	> **Nightwatch owns run lifecycle.** Dispatch, target and worktree containment, claims, durable
    38	> logging, interruption, and resume — **even when lifecycle code emits a misleading message.**
    39	>
    40	> **Classify by the violated invariant, not by the wording of the message.** Split an issue that
    41	> violates both.
    42	
    43	That last clause is the load-bearing one. The intuitive rule — "a lying message is Litmus" — gives the
    44	wrong answer: #426 exits 6 claiming containment worked while a file leaked, but the invariant it
    45	violates is run containment, so it is Nightwatch, with the assertion of its lie written as a
    46	Litmus-style test. Conversely #407 reports `pre-advance-failed` when no gate ran, and that *is* a
    47	Litmus defect, because the violated invariant is the verdict itself.
    48	
    49	**A release is not its milestone.** A milestone is a backlog and grows while you work; a release needs
    50	a frozen manifest and a testable exit criterion, both recorded in the blocks below. "The open issues
    51	are done" is not an exit criterion, because working on a release generates more of them.
    52	
    53	## What belongs here, on the occasions it is used
    54	
    55	**Major and meaningful releases only. Not every release number.**
    56	
    57	A block earns its place by being worth *planning toward* — a named arc with a theme, a target date,
    58	and a milestone. If the only thing you can write in `Description:` is a restatement of what changed,
    59	it belongs in CHANGELOG.md and nowhere else.
    60	
    61	`Iterations:` reserves a band of patch numbers for a release. **Reserved, deliberately not
    62	enumerated** — versions inside a band ship freely and are recorded in CHANGELOG.md only. They never
    63	get a block here. The band is what makes "where does 0.2.3 go?" a question with a written answer
    64	instead of one resolved by adding a row.
    65	
    66	**A version inside an existing band is already accounted for, so a new block for it is a
    67	duplicate.** That is the admission rule, and it is the only one.
    68	
    69	Why this is written down rather than assumed: the failure mode is not a wrong entry, it is a file
    70	that stays correct at every single step while turning into the wrong thing. Add `0.2.1` because it
    71	shipped, add `0.2.2` for symmetry, and this becomes a **de-facto pre-CHANGELOG** — a second,
    72	hand-maintained history that is guaranteed to disagree with the real one the first time someone
    73	updates one and not the other. Two sources of truth for the same fact is the defect; the row count
    74	is only the symptom.
    75	
    76	An assistant that keeps asking for this file to be filled produces exactly that outcome, one
    77	helpful suggestion at a time. Hence the section above.
    78	
    79	When a band is exhausted, widen it or promote the next release — do not start enumerating.
    80	
    81	`Milestone:` is the release -> issue-set join key (GH-284 Phase 3): a GitHub MILESTONE TITLE, not a
    82	URL and not a list of issues. `GH_URL:` can name only one thing, which cannot express a release's
    83	scope. Ask GitHub what is in a release instead of maintaining a list here:
    84	
    85	    gh issue list --milestone "Quicksilver" --state open --json number,title,labels
    86	
    87	Release: 0.1.0
    88	Iterations: 0.1.0-0.1.4
    89	Status: Shipped
    90	Target Date: 2026-08-01
    91	Codename: Quicksilver
    92	Description: Python-authoritative Tier-A twins. Licensed AGPL-3.0-only (`LICENSE`) with a commercial option (`LICENSE-COMMERCIAL.md`), adopted 2026-07-29 post-ship; the pre-existing conflicting `LICENSE.md` was removed 2026-07-30 (#372).
    93	GH_URL: [GH 308](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/308)
    94	Milestone: Quicksilver
    95	Front-door reviewed: No
    96	Shakedown reviewed: No
    97	License file: Yes
    98	
    99	Release: 0.2.0
   100	Iterations: 0.2.0-0.2.4
   101	Status: Release Candidate — exit criterion MET 2026-08-09 on `development` @ `263816c`
   102	Target Date: 2026-09-05
   103	RC evidence: `bash test/litmus-release.sh --release-gate` → `GOALPOST MET — all 6 manifest entries complete` (6/6, 0 remaining, 0 false completion claims). Its own negative control, `--mutate-evidence`, was re-run on the same commit and reports `negative control OBSERVED in both directions (6 pass, 0 fail)` — it detects a stripped declaration, an unregistered gate (the #461 defect), and an invariant violated in either direction. Four of the six issues are CLOSED with per-criterion evidence (#407, #417, #457, #461). **#375 and #390 remain OPEN on purpose:** their gates are registered, green and control-observed, which is what this release's exit criterion measures, but each has acceptance criteria that did not ship — #390 defers a host free-memory floor and packet-driven per-phase overrides to a Phase 2 its own code comment names (`marathon_drive.py:1253`), and #375's shipped three-state `unverifiable` verdict deliberately contradicts its criteria 1 and 5 because implementing them literally took `relay-self-sufficiency.sh` from 4/0 to 0/4 on a working machine. Both are audited per-criterion on the issues. Closing them silently would have repeated exactly the #401→#461 mistake this release exists to catch.
   104	Codename: Litmus
   105	Description: Make the checks capable of failing. Every gate in the Litmus manifest is shown to report red against a real defect, or is explicitly downgraded to advisory — a check never observed failing is not evidence (#419). Ordered first because it is the release that makes the next one measurable. It is also what the self-improvement chain (#431) is blocked on: a Reviewer is a gate, so #419 applies to it, and its qualification gate is currently un-runnable (#428) and has only ever been measured once (#429).
   106	Exit criterion: `bash test/litmus-release.sh --release-gate` exits 0. Red today by design; turning it green is what "done" means. Its own negative control is `--mutate-evidence`, which must detect a stripped declaration and an unregistered gate. NOTE the honest limit, stated in that file: the audit proves registration, declaration shape and the absence of false completion claims. It does NOT prove a control was truly observed, because `gate_inventory.py` reads a declaration authored by the same person who wrote the gate. Recorded execution of each control is deliberately out of scope for this release.
   107	Manifest: FROZEN 2026-08-08 — #375, #390, #407, #417, #457, #461. Six named decision gates, a fixed denominator rather than a percentage. "Every gate" was unshippable prose: `gate_inventory.py` reports 152 of 158 gates with no declared control, and retrofitting them is explicitly out of scope. Adding an entry is a RE-SCOPE, not a bugfix: a mid-release discovery joins only if it makes the exit command fail or falsifies a named invariant, has a reproducer demonstrating that, and the operator explicitly swaps out an existing entry or accepts a date slip. Discovery is not admission — #457, #460 and #461 were all filed while executing Litmus, which is what an unfrozen boundary looks like.
   108	GH_URL:
   109	Milestone: Litmus
   110	Front-door reviewed: No
   111	Shakedown reviewed: No
   112	License file: Yes
   113	
   114	Release: 0.3.0
   115	Iterations: 0.3.0-0.3.4
   116	Status: Release Candidate — exit criterion MET 2026-08-11 on `development`
   117	Target Date: 2026-10-10
   118	RC evidence: `bash test/nightwatch-release.sh --release-gate` → `GOALPOST MET — all 8 manifest entries complete and every lifecycle case executes green` (manifest 8/8, lifecycle 5 passing / 0 failing / 0 NOT COVERED). Its own negative control, `--mutate-evidence`, reports 34/0 and `negative control OBSERVED in both directions`. Every manifest entry carries a recorded pre-fix control under `test/baselines/`, not an assertion that one happened. **Two entries are honest about their limits and are worth reading before signing off:** #358's Phase 2 is a *disposition* that needs a real CI failure carrying the new instrumentation, and its capture doc forbids pre-committing one — so Phase 1 shipped and Phase 2 is blocked on an observation, not on work; and #354's membership is Phase 1 only, which was delivered by #376/#448 rather than by this release, recorded as such rather than rebuilt. **#426's outcome inverted its own diagnosis:** a factorial control showed the leak survives with worktree isolation OFF, so teardown was exonerated and the real cause was the GH-375 auth pre-flight running with the caller's CWD, outside containment. **Twelve open Nightwatch-milestone issues remain and gate nothing**, per this block's own "a release is not its milestone" rule.
   119	Codename: Nightwatch
   120	Description: An unattended marathon against a real target repo survives, records, and recovers. Before dispatching work, it proves the target can accept the harness write-set and preserves the local-state contract, so hostile ignore rules or linked worktrees fail clearly rather than silently splitting, leaking, or losing the run. GH-354 Phase 1 is an early Nightwatch containment prerequisite: restore clone-wide driver exclusion for linked worktrees and prove all driver pairs fail closed. A run interrupted, killed at its cap, or panicking the host leaves a durable record and recovery path instead of a clean tree full of ungated commits. Depends on Litmus. The same durability work is what makes a reflection corpus trustworthy (#431): a run with no record is invisible to any later pass over it, and the loop's own evidence has never survived a reboot (#430).
   121	Exit criterion: `bash test/nightwatch-release.sh --release-gate` exits 0. **BUILT 2026-08-11 and red by design**, exactly as Litmus's was; turning it green is what "done" means. It has two halves because a metadata audit cannot answer this release's question. Half A audits the frozen manifest — each entry's gate EXISTS, is REGISTERED in `validate.sh` (a gate absent from TESTS is indistinguishable from one that passes — the #461 defect), and has a RECORDED control under `test/baselines/`; it also cross-checks that this list and the `Manifest:` line below agree, since a boundary that disagrees with itself is not frozen. Half B **executes** the lifecycle cases rather than auditing them, delegating to the suites that already drive real children and kill them rather than growing a second driver fixture here. Status on 2026-08-11: **manifest 8/8 complete; lifecycle 5 passing, 0 NOT COVERED — GOALPOST MET.** The last gap was the hostile-target write-set case, closed by #514, which was filed while executing this release and deliberately NOT admitted to the manifest (discovery is not admission); it belongs to the lifecycle list because the exit criterion always named that case — what was missing was a suite driving it. That lane also corrected its own premise: the pre-fix tree does not dispatch a turn first, it dies at the render's `git add` with an unhandled `CalledProcessError` traceback, so the discriminating assertion is the absence of that traceback rather than the absence of a dispatch. Its own negative control is `--mutate-evidence` (34/0), which unregisters a gate and deletes a recorded control in a fixture copy, requires both to be detected, and re-checks the unmutated inputs green in the same run so an always-red detector cannot pass for one. Honest limit, inherited from Litmus: Half A reads a declaration and a filename and cannot know a recorded control was honestly recorded; Half B is what narrows that, and is why this criterion is a command that kills children rather than a checklist.
   122	Manifest: FROZEN 2026-08-11 — #408, #409, #426, #388, #387, #384, #358, plus #354 Phase 1. Eight named entries, a fixed denominator rather than a percentage. The first six were moved out of Litmus on 2026-08-08 after a codex+agy consult; #387 and #384 are added at freeze time because the exit criterion above already names their cases — it requires a cap-killed child and a restarted recovery, and nothing else in the milestone supplies either. **The milestone is not the manifest.** Nightwatch's milestone holds 18 open issues; the twelve not listed here (#376, #378, #379, #380, #382, #386, #391, #392, #402, #467, #491, and anything filed during execution) are backlog worked inside the 0.3.0-0.3.4 band, and none of them gates the release. Adding an entry is a RE-SCOPE, not a bugfix, under the same admission rule Litmus used: a mid-release discovery joins only if it makes the exit command fail or falsifies a named invariant, has a reproducer demonstrating that, and the operator explicitly swaps out an existing entry or accepts a date slip. Discovery is not admission.
   123	GH_URL:
   124	Milestone: Nightwatch
   125	Front-door reviewed: No
   126	Shakedown reviewed: No
   127	License file: Yes
   128	
   129	Release: 0.4.0
   130	Iterations: 0.4.0-0.4.4
   131	Status: Draft
   132	Target Date: 2026-11-14
   133	Codename: Plumbline
   134	Description: Assisted reflection and a bounded self-improvement loop, measured before either is trusted. The reflection pipeline turns durable Nightwatch records into proposals (`proposals-sink.sh` gains its first production caller) and is graded against external ground truth — the 49 human-filed findings from the two rebalance-OS marathons (#405/#406) — for recall and precision. Ships a committed benchmark and a recorded go/no-go; "not worth automating yet" is a passing result, per #431's own Phase 2 exit criterion. Operator sign-off stays manual. Depends on Nightwatch.
   135	GH_URL: [GH 431](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/431)
   136	Milestone: Plumbline
   137	Front-door reviewed: No
   138	Shakedown reviewed: No
   139	License file: Yes
   140	
   141	Release: 0.5.0
   142	Iterations: 0.5.0-0.5.4
   143	Status: Draft
   144	Target Date: 2026-12-12
   145	Codename: Lantern
   146	Description: When the harness fails, the information needed to act already exists inside it — make it say so. Not "add checks": every case was already detected, and some were then described wrongly (a stack trace, a fabricated path, a success exit code, silence). Scope is one epic, deliberately narrow, and deliberately NOT Nightwatch: that milestone owns run lifecycle "even when lifecycle code emits a misleading message" (see the scope boundary above), and none of Lantern's cases violates a lifecycle invariant — they violate the legibility of a failure whose lifecycle handling was already correct. All four members were found in one afternoon during Nightwatch wave 3, which halted three times at zero paid-turn cost; each halt was avoidable from information the system already held. Depends on nothing; independent of Plumbline.
   147	Manifest: FROZEN at one issue on creation — #499, which supersedes and closes #494, #495, #496 and #498. Four phases, each shippable alone: relay-drive launch preflight; a gate refusal that states its real reason; a launcher whose exit code survives plus a gate-readiness check; and a change-impact reporter. Freezing at one is the whole point — these were filed as four and unified precisely to stop a single coherent change spreading across four PRs. Adding a member is a RE-SCOPE, not a bugfix, per the Litmus rule above.
   148	GH_URL: [GH 499](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/499)
   149	Milestone: not created yet — #499 is unmilestoned by design while Nightwatch is the active goalpost
   150	Front-door reviewed: No
   151	Shakedown reviewed: No
   152	License file: Yes
     1	---
     2	gh_issue: 388
     3	source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/388
     4	title: "GH-388 — marathon.sh persists no run log, and per-phase transcripts are written only on completion"
     5	status: "BUILT 2026-08-11 (both phases) as a lane of release 0.3.0 Nightwatch, to which it moved on 2026-08-08. Built Opus-direct rather than fired: the 2026-08-10 wave-1 plan had already recorded why this lane is not marathon-buildable — it edits marathon.sh, the outer driver bash that is reading itself by byte offset as the chain runs. Negative control recorded in test/baselines/GH-388-negative-control.md (9 red pre-fix). Full validate.sh green."
     6	created: 2026-08-06
     7	updated: 2026-08-11
     8	owner: noel
     9	doc_type: project
    10	release: "0.2.0 Litmus"
    11	complexity: 2
    12	risk: 2
    13	effort: 3
    14	phases: 2
    15	ratings_provisional: true
    16	related:
    17	  - "#419 — the class. The harness keeps a permanent record of every phase that succeeded and none of the phase that failed, so the archive is systematically biased toward success."
    18	  - "#382 — the crash whose first occurrence produced no usable profile precisely because of this."
    19	  - "#384 — recovery after an interrupted run, which is much harder without a run log."
    20	  - "#390 — its layer-5 evidence requirement depends on what this lane makes durable."
    21	non_goals:
    22	  - "Changing what the per-phase transcripts contain on success. They work; the gap is the failure path."
    23	  - "Making the invoker responsible for redirection. That is the current state and is the defect."
    24	goal: >
    25	  The failure mode guarantees the absence of the record. Per-phase transcripts are written when a
    26	  phase completes, so the phase that dies is the one phase with no transcript, and the chain-level
    27	  narrative exists only on the operator's terminal. Whether any of it survives a crash depends on
    28	  whether whoever typed the command happened to redirect stdout somewhere durable.
    29	---
    30	
    31	# GH-388 · the phase that fails is the one with no record
    32	
    33	## Status
    34	
    35	| What was just completed | What's next |
    36	|---|---|
    37	| **Both phases built 2026-08-11.** `marathon.sh` owns a durable chain run log under the same transcript root as the per-phase transcripts, announced at chain start; a phase killed mid-run leaves a content-bearing `PHASE-INTERRUPTED.md`; `rtl_default_log` refuses on both lanes instead of silently relocating to volatile storage; and the non-durable locations are stated in one runtime-read file. `test/gh388-run-log-durability.sh` 24/0, observed **9 red** pre-fix. | Close #388 against the acceptance block below. All seven criteria met — see "Acceptance — outcome". |
    38	
    39	## Acceptance — outcome
    40	
    41	1. **Met.** `marathon.sh` opens `<transcript-root>/run-logs/<date>/marathon-<plan>-<time>-<pid>.log` and `tee`s stdout+stderr into it as produced. Armed after plan validation and before the phase loop, so a usage error or an unparseable plan leaves no log implying a run happened; `--dry-run` is excluded for the same reason, and that exclusion is asserted.
    42	2. **Met.** `marathon: run log: <path>` is printed at chain start, and the test parses that line rather than guessing the path — if the announcement breaks, the test cannot find the file.
    43	3. **Met.** `_write_interrupted_phase_record` writes `PHASE-INTERRUPTED.md` carrying the phase id, the relay `STATUS:` read *at interruption*, the recorded round count, the reason and the exit code. Asserted on content, not existence, and against a marker stamped after dispatch — the empty-file and pre-created-file loopholes the issue's own review found.
    44	4. **Met, both lanes.** `rtl_default_log` in `utils/py/rtl.py` and in `relay-turn-lib.sh` now exit 5 rather than returning a `$TMPDIR` path, and the resolver's stderr is no longer swallowed (`quiet=True` is gone), so the refusal names *why* the root failed to resolve. `test/relay-turn-trace.sh`'s case 3c, which pinned the old fallback, is inverted with the rationale recorded in place.
    45	5. **Met.** `relay-automation/non-durable-log-roots.conf` is the single registry, read at runtime by `durable-log-lib.sh` (Bash) and `rtl.py::non_durable_reason` (Python). The test asserts the two readers agree on every probe path *and* that an invented entry changes the verdict — without that second assertion the file could be decorative while the real list lived in the readers.
    46	6. **Met.** Part C kills a running phase; Part D kills a running chain. Both assert on what is left on disk.
    47	7. **Met.** `test/baselines/GH-388-negative-control.md` carries both runs in full: 9 red pre-fix, 0 after.
    48	
    49	## Acceptance — deviations found while building
    50	
    51	**The durability rule is scoped to RELOCATION, not to absolute location.** A transcript that resolves
    52	*inside the repo being driven* is permitted even when that repo sits in `$TMPDIR`; only a path that is
    53	both non-durable *and* outside the repo is refused. Criterion 5 reads "a default log path resolving
    54	into one of them fails the run", which taken literally refuses to run the harness inside every fixture
    55	in this suite — every one of them is a repo under `$TMPDIR`. A guard that cannot be exercised is not a
    56	guard, and "fails the run" would have meant "fails every run". The defect being fixed is the harness
    57	*silently moving* evidence out of the repo; a repo the operator put in `/tmp` makes the code, the
    58	commits and the log volatile together, visibly, by their choice.
    59	
    60	**Two defects were found by this lane's own test rather than reasoned about.**
    61	
    62	- **The driver's narrative was block-buffered.** Python block-buffers stdout when it is not a TTY, and
    63	  a marathon is never a TTY — so the buffering is not an edge case, it *is* the unattended path. The
    64	  first kill-mid-run recovered a log containing the child turn-shim's output and none of
    65	  `marathon-drive`'s own: the subprocesses wrote straight to the fd and survived, while every
    66	  `marathon-drive: …` line sat in a buffer that SIGTERM discards. A run log fed by a buffered writer
    67	  records the run right up to the moment something goes wrong. Fixed with `line_buffering=True`.
    68	- **SIGTERM never reached the exit hooks.** `marathon_drive.py` already had an `_ON_EXIT` list run from
    69	  a `finally`, but SIGTERM terminates CPython immediately — no `finally`, no hooks, no record. SIGINT
    70	  already raised `KeyboardInterrupt` and so already reached them; SIGTERM is what an unattended run
    71	  actually receives. Converted to `SystemExit(128+signum)`, which is the convention `_exit_meaning`
    72	  and `marathon.sh`'s halt table already read. **SIGKILL and a host panic remain unreachable** — that
    73	  is stated in the code rather than papered over, and is why #384's recovery path is a separate lane
    74	  rather than something this one quietly claims to cover.
    75	
    76	## The defect
    77	
    78	`marathon.sh` persists none of its own output — no `tee`, no `exec >`, no log-file variable. What is
    79	durable is written **per phase, on completion**. In the observed run, phases 1–4 completed and each
    80	has a transcript; phase 5 is the one that killed the host, and there is no transcript for it.
    81	
    82	**The fallback is not a fallback.** The only surviving account of phase 5 was the terminal stream,
    83	which had been redirected to a path the platform clears at boot. After the panic reboot it was gone.
    84	That choice was the invoker's and a poor one — but the harness offered no alternative and gave no
    85	indication one was needed.
    86	
    87	**There is a related silent path inside XYZ itself.** `rtl_default_log` resolves the durable
    88	transcript root and, on failure, falls back to a temporary directory *with the diagnostic
    89	suppressed*. A misconfigured archive root silently relocates turn logs into the one directory a crash
    90	erases, and prints nothing. This did not fire in the observed run — it is a live code path, not an
    91	observed failure, and this doc keeps that distinction.
    92	
    93	## Two corrections the review produced
    94	
    95	Both from codex, both verified against `development` @ `3b37072` before being acted on:
    96	
    97	- **A criterion of mine rested on a false premise.** It asserted that *"the repo's own PDDA lint
    98	  already classifies those locations as non-durable."* It does not — `check_hardcoded_paths` reads
    99	  `pdda_list_working_docs` and scans **documentation** for literal absolute paths. It says nothing
   100	  about runtime log destinations. The criterion was rewritten to require the harness to state the
   101	  non-durable set somewhere it actually reads at runtime.
   102	- **"Writes a partial transcript" was satisfiable by an empty file.** A static or pre-created
   103	  transcript met the words while the failing phase's evidence remained absent. It now requires the
   104	  file to have been created or modified *after that phase started* and to carry the phase id, the
   105	  relay state at interruption, and the failure reason.
   106	
   107	Agy independently found the third: *"no longer silent"* was satisfiable by adding a print statement
   108	while still writing to volatile storage — the logs would still be destroyed, the defect completely
   109	unfixed.
   110	
   111	## Acceptance
   112	
   113	*Copied verbatim from [issue #388](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/388)
   114	(`## Acceptance`), fetched 2026-08-06. Deviations, if any, are recorded below this block.*
   115	
   116	- [ ] A durable run log captures the whole chain's output as it is produced, under the same transcript root the per-phase transcripts already use. Where the run narrative goes is the harness's decision, not the invoker's.
   117	- [ ] The run log's path is printed at chain start, so an operator knows where to look afterwards.
   118	- [ ] A phase that escalates, times out, or dies mid-gate leaves a transcript that was **created or modified after that phase started** and contains the phase id, the relay state at interruption, and the failure or kill reason. An empty or pre-created file does not satisfy this.
   119	- [ ] `rtl_default_log` does not silently relocate turn logs to volatile storage. It either resolves a durable root or refuses before the turn launches; if a volatile fallback is retained, it is reported as non-durable and is never presented as the turn transcript. Adding a message while still writing to storage a reboot erases does not satisfy this.
   120	- [ ] The locations the harness treats as non-durable are stated in one place it actually reads at runtime, and a default log path resolving into one of them fails the run rather than proceeding.
   121	- [ ] A regression test kills a phase mid-run and asserts that both a chain-level run log and a content-bearing partial phase transcript survive.
   122	- [ ] The regression test is observed failing against the pre-fix revision, and a durable record states the reproducer command, the pre-fix revision, the pre-fix result and the post-fix result. A sentence asserting a negative control happened is not the record, per #419.
   123	
   124	## Acceptance — deviations from the issue
   125	
   126	None. Every criterion is carried verbatim.
   127	
   128	The criteria were **authored onto the issue on 2026-08-05** (it had none) and **revised on 2026-08-06**
   129	after the codex+agy review, for the three reasons above. The `tee` prescription was also dropped —
   130	both reviewers noted it named a mechanism where an outcome was wanted.
   131	
   132	## Phases
   133	
   134	| Phase | Deliverable | Artifacts | cx/risk/eff |
   135	|---|---|---|---|
   136	| 1 | The chain run log. One durable file opened at chain start under the same transcript root the per-phase transcripts use, capturing the chain's output as it is produced, with its path printed at start. Plus a content-bearing partial transcript when a phase escalates, times out, or dies mid-gate. | `relay-automation/marathon.sh`, `utils/py/marathon_drive.py` | 2/2/3 |
   137	| 2 | The durability rule. The non-durable locations are stated in one place the harness reads at runtime; `rtl_default_log` resolves a durable root or refuses before the turn launches, and a retained volatile fallback is never presented as the turn transcript. Plus the kill-mid-run regression. | `utils/py/rtl.py`, `test/gh388-run-log-durability.sh`, `validate.sh` | 2/2/3 |
   138	
   139	## Litmus tests
   140	
   141	- **A green suite is not evidence here.** Everything works on the success path today. The only
   142	  assertion that matters is what survives a kill, so the regression must actually kill a phase.
   143	- **An empty transcript passes a naive check.** Assert content — phase id, relay state, reason — not
   144	  existence. This was a real hole in the first draft.
   145	- **A message is not a fix.** If the fallback still writes to storage a reboot erases, the evidence
   146	  still disappears; the message only means someone could have known.
   147	
   148	## Swarm Preflight Contract
   149	
   150	```json
   151	{
   152	  "target":        { "repo": ".", "ref": "development" },
   153	  "gate":          "bash validate.sh",
   154	  "fix_probes":    [
   155	    { "type": "path_absent", "path": "test/gh388-run-log-durability.sh" },
   156	    { "type": "grep_absent", "path": "relay-automation/marathon.sh", "pattern": "run log" }
   157	  ],
   158	  "artifacts":     [ "relay-automation/marathon.sh", "utils/py/marathon_drive.py", "utils/py/rtl.py", "test/gh388-run-log-durability.sh", "validate.sh" ],
   159	  "artifacts_new": [ "test/gh388-run-log-durability.sh" ],
   160	  "remediation":   { "source": "issue#388", "criteria": "the harness owns a durable chain run log, and a failing phase leaves evidence — ranking summary only, NOT the definition of done (that is the verbatim ## Acceptance block above)" },
   161	  "lanes":         { "agy_safe": [], "orchestrator_only": [] }
   162	}
   163	```
   164	
   165	**Probe polarity** (probes detect the **bug**, not the fix): `path_absent` reports `landed` when the
   166	path *exists*; `grep_absent` reports `landed` when the pattern *is found*. Verified 2026-08-06:
   167	`run log` occurs **0 times** (case-insensitive) in `relay-automation/marathon.sh`.
   168	
   169	**`relay-automation/marathon.sh` is not a frozen twin** — verified 2026-08-06, no GH-308 banner — so
   170	Phase 1 may edit it directly. `utils/py/rtl.py` is the authoritative Python lane.
   171	
   172	## Method note
   173	
   174	The phase-5 evidence, the cleared-temp-directory finding and the `rtl_default_log` code path are
   175	carried from the issue. The PDDA-lint correction and the empty-transcript loophole came from the
   176	codex review and were verified directly before being written as criteria. No open PR or branch
   177	touches this issue — checked before authoring.
     1	---
     2	gh_issue: 358
     3	source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/358
     4	title: "GH-358 — xyz-completion's 16-way concurrent-append assertion flakes on the shared CI runner"
     5	status: "Intake (2-WORKING) — captured 2026-08-06 for release 0.2.0 Litmus, preflight READY, awaiting operator go."
     6	created: 2026-08-06
     7	updated: 2026-08-06
     8	owner: noel
     9	doc_type: project
    10	release: "0.2.0 Litmus"
    11	complexity: 2
    12	risk: 2
    13	effort: 2
    14	phases: 2
    15	ratings_provisional: true
    16	related:
    17	  - "#419 — the class, in an unusual form: the test is a decision gate that cannot distinguish a flake from the defect it exists to catch, so neither verdict is evidence."
    18	  - "#232 — the CI step is already named 'minus a documented flaky test', so a second exclusion arriving unnoticed is how a suite drifts into being re-run until green."
    19	non_goals:
    20	  - "Lowering M from 16. It makes the symptom disappear and the safety property untested."
    21	  - "Dropping the distinctness check, for the same reason."
    22	  - "Deciding the disposition before the instrumentation exists. The issue is explicit that instrumenting comes first."
    23	  - "Treating this as an ordinary flake. A flaky LOCK test is the one kind that cannot be waved off."
    24	goal: >
    25	  A 16-way concurrent-append assertion intermittently loses one record on the shared runner. Both
    26	  assertions are correct statements about a real safety property. The problem is that "flaky" and
    27	  "the lock genuinely loses a write under contention" produce an identical symptom, and nothing in
    28	  the output can tell them apart — so the test cannot currently be evidence either way.
    29	---
    30	
    31	# GH-358 · a lock test that cannot tell a flake from the bug
    32	
    33	## Status
    34	
    35	| What was just completed | What's next |
    36	|---|---|
    37	| Captured 2026-08-06 as a lane of release 0.2.0 Litmus. Acceptance criteria authored on the issue (it had none) and revised after an adversarial codex+agy review, which found that every appender's exit status is discarded today and that two different lock bounds are in play. | Operator go. Then Phase 1 (instrument: retain exit status, report the missing record's terminal state, name both bounds) and only then Phase 2 (choose the disposition on that evidence). |
    38	
    39	## The defect
    40	
    41	`test/xyz-completion.sh`'s lock-under-concurrency case fails intermittently on the shared runner,
    42	losing one of 16 records. The same commit re-run passed; it passes locally. The originating PR's
    43	diff touched neither the test nor the appender.
    44	
    45	**Why this is not "just re-run it":**
    46	
    47	1. **It is a lock test.** "Flaky" and "the lock genuinely loses a write under contention" produce
    48	   the identical symptom. The failure says a record was clobbered — which is *also* exactly what a
    49	   real lock bug says.
    50	2. **A second flaky exclusion arriving unnoticed** is how a suite drifts into being re-run until
    51	   green. The CI step is already named for one documented exclusion.
    52	3. **A red run on an unrelated PR trains people to re-run rather than read**, which is the habit
    53	   that lets a real regression through.
    54	
    55	## What the review added
    56	
    57	Two findings from the codex review, both verified against `development` @ `3b37072`:
    58	
    59	- **Every appender's exit status is discarded.** The harvest loop is
    60	  `for p in $pids; do wait "$p" 2>/dev/null || true; done`, in two places. So a crashed or killed
    61	  appender is indistinguishable from one that acquired the lock and lost its record — the test
    62	  cannot currently attribute the failure even in principle.
    63	- **Two different bounds are in play.** The test waits on one budget; the writer defaults to
    64	  `XYZ_LOCK_WAIT_S` at another, smaller value. A report that names "the timeout" without saying
    65	  which one was exhausted is not actionable.
    66	
    67	## Acceptance
    68	
    69	*Copied verbatim from [issue #358](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/358)
    70	(`## Acceptance`), fetched 2026-08-06. Deviations, if any, are recorded below this block.*
    71	
    72	- [ ] Each of the 16 appenders' exit status is retained and asserted. Today every one is discarded (`wait "$p" 2>/dev/null || true`), so a crashed appender is indistinguishable from a lost record; any non-zero exit must fail the assertion in its own right.
    73	- [ ] On a mismatch the report identifies the missing `sessionId` **and its terminal state**: lock acquired and record lost, lock never acquired, or process failed. Those have opposite priorities and today produce an identical symptom.
    74	- [ ] Both effective lock bounds are named in the failure output — the test's own wait and the writer's `XYZ_LOCK_WAIT_S` default, which differ today — and the report states which one was exhausted.
    75	- [ ] The change ships the instrumentation output from a reproduced failure, and the disposition applied is the one that evidence indicates. A disposition chosen without that output does not satisfy this.
    76	- [ ] `M` is not lowered from 16 and the distinctness check is not dropped. Both make the symptom disappear and leave the safety property untested.
    77	- [ ] If it goes on the CI exclusion list, the workflow states **why**, so a reader does not take the exclusion to mean the property is not worth checking.
    78	- [ ] The instrumentation is demonstrated to distinguish the causes: a deliberately clobbered record and a deliberately starved appender produce visibly different reports. A lock test that cannot tell a flake from a real lost update is not evidence, per #419.
    79	
    80	## Acceptance — deviations from the issue
    81	
    82	None. Every criterion is carried verbatim.
    83	
    84	The criteria were **authored onto the issue on 2026-08-05** (it had none) and **revised on 2026-08-06**
    85	after the codex+agy review. Two changes are worth naming: the exit-status criterion is new and came
    86	from reading the test rather than the issue, and the original *"the disposition is chosen after that
    87	evidence exists"* was replaced — both reviewers correctly said a reviewer cannot verify the temporal
    88	order of someone's decisions. It now requires the instrumentation output to ship with the change.
    89	
    90	## Phases
    91	
    92	| Phase | Deliverable | Artifacts | cx/risk/eff |
    93	|---|---|---|---|
    94	| 1 | Instrumentation. Retain and assert each appender's exit status; on mismatch report the missing record's terminal state — lock acquired and record lost, lock never acquired, or process failed — and name both effective bounds with the one that was exhausted. | `test/xyz-completion.sh`, `utils/telemetry/append-xyz-completion.sh`, `test/gh358-lock-instrumentation.sh` | 2/2/2 |
    95	| 2 | Disposition, on that evidence. Raise the bound, retry the assertion, or exclude with a stated reason in the workflow. `M` stays 16 and the distinctness check stays. | `.github/workflows/ci.yml` or `test/xyz-completion.sh` | 1/2/1 |
    96	
    97	**Phase 2 must not be pre-committed in the packet.** A builder told which disposition to apply will
    98	produce instrumentation that agrees with the instruction — the same defect as grading against a
    99	model-authored requirement.
   100	
   101	## Litmus tests
   102	
   103	- **The instrumentation is itself a decision gate**, so it needs its own negative control: a
   104	  deliberately clobbered record and a deliberately starved appender must produce visibly different
   105	  reports. If it cannot tell those apart it has not fixed anything.
   106	- **A green run proves nothing here.** The failure is intermittent; a passing suite after the change
   107	  is consistent with the instrumentation never having been exercised. The controls above are the
   108	  only evidence.
   109	- **If the answer turns out to be a real lock bug, the priority changes completely** and this lane
   110	  should stop and re-file rather than proceed to Phase 2's exclusion option.
   111	
   112	## Swarm Preflight Contract
   113	
   114	```json
   115	{
   116	  "target":        { "repo": ".", "ref": "development" },
   117	  "gate":          "bash validate.sh",
   118	  "fix_probes":    [
   119	    { "type": "path_absent", "path": "test/gh358-lock-instrumentation.sh" },
   120	    { "type": "grep_absent", "path": "test/xyz-completion.sh", "pattern": "terminal state" }
   121	  ],
   122	  "artifacts":     [ "test/xyz-completion.sh", "utils/telemetry/append-xyz-completion.sh", "test/gh358-lock-instrumentation.sh", ".github/workflows/ci.yml", "validate.sh" ],
   123	  "artifacts_new": [ "test/gh358-lock-instrumentation.sh" ],
   124	  "remediation":   { "source": "issue#358", "criteria": "make the lock assertion able to distinguish a flake from a lost update — ranking summary only, NOT the definition of done (that is the verbatim ## Acceptance block above)" },
   125	  "lanes":         { "agy_safe": [], "orchestrator_only": [] }
   126	}
   127	```
   128	
   129	**Probe polarity** (probes detect the **bug**, not the fix): `path_absent` reports `landed` when the
   130	path *exists*; `grep_absent` reports `landed` when the pattern *is found*. Verified 2026-08-06:
   131	`terminal state` occurs **0 times** in `test/xyz-completion.sh`.
   132	
   133	**This lane's artifacts include `test/*.sh` it must edit.** Per the marathon plan's standing note,
   134	those are read-only specs in-turn and the outer harness gate verifies them after the turn, outside
   135	the isolated worktree.
   136	
   137	## Method note
   138	
   139	The flake evidence and the "do not lower M / do not drop distinctness" constraints are carried from
   140	the issue. The discarded-exit-status finding and the two-bound mismatch came from the codex review
   141	and were verified directly against `development` @ `3b37072` before being written as criteria. No
   142	open PR or branch touches this issue — checked before authoring.

exec
/bin/zsh -lc 'rg -n -C 5 "deviation|non-durable|outside the repo|inside the repo|criterion 5|Met|Phase 2|observation|conc-1|#448|#376|Phase 1" RELEASES.md PROJECT/2-WORKING/GH-388-MARATHON-RUN-LOG-DURABILITY.md PROJECT/2-WORKING/GH-358-LOCK-FLAKE-INSTRUMENTATION.md PROJECT/2-WORKING/GH-354-CONCURRENT-SWARMS.md test/gh388-run-log-durability.sh test/gh358-lock-instrumentation.sh test/baselines/GH-388-negative-control.md test/baselines/GH-358-negative-control.md 2>/dev/null' in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-69972-gxaghv_u
 succeeded in 0ms:
test/baselines/GH-388-negative-control.md-1-# GH-388 — recorded negative control (#419)
test/baselines/GH-388-negative-control.md-2-
test/baselines/GH-388-negative-control.md-3-Test:     `test/gh388-run-log-durability.sh` (TEST_SOFT_FAIL=1, so one run enumerates every gap)
test/baselines/GH-388-negative-control.md-4-Baseline: `a75cafd24eebcc5225c5f868dc6b1a339b6b24d3` — `marathon.sh`, `relay-turn-lib.sh`, `rtl.py` and `marathon_drive.py` at
test/baselines/GH-388-negative-control.md-5-          their pre-fix content, and the two new shared files (`durable-log-lib.sh`,
test/baselines/GH-388-negative-control.md:6:          `non-durable-log-roots.conf`) absent, since the fix introduces them.
test/baselines/GH-388-negative-control.md-7-Date:     2026-08-11
test/baselines/GH-388-negative-control.md-8-
test/baselines/GH-388-negative-control.md-9-**A green suite proves nothing on this issue** — everything already worked on the success
test/baselines/GH-388-negative-control.md-10-path, and the defect is defined by what is MISSING after a failure. So the pre-fix run below
test/baselines/GH-388-negative-control.md-11-is the finding, not a formality: the chain announced no run log, and the phase killed
--
test/baselines/GH-388-negative-control.md-15-
test/baselines/GH-388-negative-control.md-16-```
test/baselines/GH-388-negative-control.md-17-== test: gh388-run-log-durability ==
test/baselines/GH-388-negative-control.md-18-  workdir: <tmp>
test/baselines/GH-388-negative-control.md-19--- A: one registry, two readers, same verdict
test/baselines/GH-388-negative-control.md:20:  FAIL: GH-388 criterion 5: no single place states the non-durable locations
test/baselines/GH-388-negative-control.md-21-test/gh388-run-log-durability.sh: line 36: /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/relay-automation/durable-log-lib.sh: No such file or directory
test/baselines/GH-388-negative-control.md-22-test/gh388-run-log-durability.sh: line 43: xyz_non_durable_reason: command not found
test/baselines/GH-388-negative-control.md-23-Traceback (most recent call last):
test/baselines/GH-388-negative-control.md-24-  File "<string>", line 3, in <module>
test/baselines/GH-388-negative-control.md-25-    print(rtl.non_durable_reason('/tmp/x.log'))
--
test/baselines/GH-388-negative-control.md-55-    print(rtl.non_durable_reason('/usr/local/share/keepme'))
test/baselines/GH-388-negative-control.md-56-          ^^^^^^^^^^^^^^^^^^^^^^
test/baselines/GH-388-negative-control.md-57-AttributeError: module 'rtl' has no attribute 'non_durable_reason'
test/baselines/GH-388-negative-control.md-58-  PASS: the Bash and Python readers agree on every probe path
test/baselines/GH-388-negative-control.md-59-test/gh388-run-log-durability.sh: line 55: xyz_path_is_durable: command not found
test/baselines/GH-388-negative-control.md:60:  FAIL: the repo's own transcript root was classified non-durable
test/baselines/GH-388-negative-control.md-61-test/gh388-run-log-durability.sh: line 58: xyz_path_is_durable: command not found
test/baselines/GH-388-negative-control.md:62:  PASS: /tmp is classified non-durable
test/baselines/GH-388-negative-control.md-63-cp: /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/relay-automation/durable-log-lib.sh: No such file or directory
test/baselines/GH-388-negative-control.md-64-bash: relay-automation/durable-log-lib.sh: No such file or directory
test/baselines/GH-388-negative-control.md-65-bash: xyz_non_durable_reason: command not found
test/baselines/GH-388-negative-control.md-66-  FAIL: adding an entry to the registry changed nothing — the real list is hardcoded somewhere (got: '')
test/baselines/GH-388-negative-control.md-67--- B: a misconfigured archive root refuses, rather than quietly writing to volatile storage
--
test/baselines/GH-388-negative-control.md-97-
test/baselines/GH-388-negative-control.md-98-```
test/baselines/GH-388-negative-control.md-99-== test: gh388-run-log-durability ==
test/baselines/GH-388-negative-control.md-100-  workdir: <tmp>
test/baselines/GH-388-negative-control.md-101--- A: one registry, two readers, same verdict
test/baselines/GH-388-negative-control.md:102:  PASS: the registry file exists (non-durable-log-roots.conf)
test/baselines/GH-388-negative-control.md-103-  PASS: the Bash and Python readers agree on every probe path
test/baselines/GH-388-negative-control.md:104:  PASS: a path inside the repo's own relay-system is durable
test/baselines/GH-388-negative-control.md:105:  PASS: /tmp is classified non-durable
test/baselines/GH-388-negative-control.md-106-  PASS: the registry is genuinely read at runtime (an invented entry changes the verdict)
test/baselines/GH-388-negative-control.md-107--- B: a misconfigured archive root refuses, rather than quietly writing to volatile storage
test/baselines/GH-388-negative-control.md-108-  PASS: python lane REFUSES on an unusable archive root (exit 5)
test/baselines/GH-388-negative-control.md-109-  PASS: the refusal names WHY the root did not resolve (the resolver's stderr is no longer swallowed)
test/baselines/GH-388-negative-control.md-110-  PASS: bash lane REFUSES on the same input (exit 5)
--
test/baselines/GH-358-negative-control.md-1-# GH-358 — recorded negative control (#419)
test/baselines/GH-358-negative-control.md-2-
test/baselines/GH-358-negative-control.md:3:Test:     `test/gh358-lock-instrumentation.sh` (Phase 1: instrumentation)
test/baselines/GH-358-negative-control.md-4-Revision: `b4f98ce27ead37cd380ffd0e13589abe27c967ac`
test/baselines/GH-358-negative-control.md-5-Date:     2026-08-11
test/baselines/GH-358-negative-control.md-6-
test/baselines/GH-358-negative-control.md-7-Unlike the other Nightwatch entries, this control is **self-contained**: the suite constructs both
test/baselines/GH-358-negative-control.md-8-failure shapes itself and requires the instrumentation to tell them apart. The two `FAIL:` lines
test/baselines/GH-358-negative-control.md-9-below are the controls firing on purpose — a clobbered record and a starved appender — and the
test/baselines/GH-358-negative-control.md:10:point is that they read DIFFERENTLY. Before Phase 1 both produced the same bare mismatch, which
test/baselines/GH-358-negative-control.md-11-is why the flake was never dispositioned: nobody could say whether the record was lost under a
test/baselines/GH-358-negative-control.md-12-held lock or never written because the lock was never acquired.
test/baselines/GH-358-negative-control.md-13-
test/baselines/GH-358-negative-control.md-14-## OBSERVED — both controls fire, and are distinguishable
test/baselines/GH-358-negative-control.md-15-
--
test/baselines/GH-358-negative-control.md-18-  PASS: clobbered-record control fails as intended
test/baselines/GH-358-negative-control.md-19-  PASS: clobber names the missing successful session
test/baselines/GH-358-negative-control.md-20-  PASS: clobber reports both normal lock bounds
test/baselines/GH-358-negative-control.md-21-  PASS: clobber remains distinct from starvation
test/baselines/GH-358-negative-control.md-22-  clobber diagnostic (observed failure):
test/baselines/GH-358-negative-control.md:23:      FAIL: concurrent mismatch: missing sessionId=conc-1; terminal state=lock acquired, record lost. test wait=60s; writer XYZ_LOCK_WAIT_S=30s (default=30s)
test/baselines/GH-358-negative-control.md-24-  PASS: starved-appender control fails as intended
test/baselines/GH-358-negative-control.md-25-  PASS: starvation identifies the terminal lock state
test/baselines/GH-358-negative-control.md-26-  PASS: starvation identifies the exhausted writer bound
test/baselines/GH-358-negative-control.md-27-  PASS: starvation reports both effective lock bounds
test/baselines/GH-358-negative-control.md-28-  PASS: starvation remains distinct from a lost record
test/baselines/GH-358-negative-control.md-29-  starvation diagnostic (observed failure):
test/baselines/GH-358-negative-control.md:30:      FAIL: appender sessionId=conc-1; terminal state=lock never acquired; writer XYZ_LOCK_WAIT_S=1s exhausted. test wait=60s; writer XYZ_LOCK_WAIT_S=1s (default=30s)
test/baselines/GH-358-negative-control.md-31-  gh358-lock-instrumentation: 9 pass, 0 fail
test/baselines/GH-358-negative-control.md-32-```
test/baselines/GH-358-negative-control.md-33-
test/baselines/GH-358-negative-control.md:34:## Phase 2 is BLOCKED ON AN OBSERVATION, not on work
test/baselines/GH-358-negative-control.md-35-
test/baselines/GH-358-negative-control.md:36:Phase 2 is "disposition, on that evidence" — raise the bound, retry the assertion, or exclude with
test/baselines/GH-358-negative-control.md-37-a stated reason. That decision needs a real CI failure carrying the new instrumentation, and the
test/baselines/GH-358-negative-control.md-38-capture doc is explicit that it must not be pre-committed: *"a builder told which disposition to
test/baselines/GH-358-negative-control.md-39-apply will produce instrumentation that agrees with the instruction."* The suite DOES run on the
test/baselines/GH-358-negative-control.md-40-shared runner (`.github/workflows/ci.yml` runs the full `validate.sh` minus two documented skips,
test/baselines/GH-358-negative-control.md-41-and `xyz-completion.sh` is not one of them), so the exposure is live — it simply has not fired
--
PROJECT/2-WORKING/GH-354-CONCURRENT-SWARMS.md-1----
PROJECT/2-WORKING/GH-354-CONCURRENT-SWARMS.md-2-title: Concurrent swarms — make the driver-lock scope true, provable, and observable before selling parallelism
PROJECT/2-WORKING/GH-354-CONCURRENT-SWARMS.md:3:status: "Active (2-WORKING) — opened 2026-07-30. Phase 0 discovery COMPLETE (findings below, verified against `development` at `b93fd93`). Phase 0 overturns three of issue #354's five collision claims and promotes its single observability footnote to the plan's highest-severity finding. Phase 1 is next and is a correctness fix, not a feature."
PROJECT/2-WORKING/GH-354-CONCURRENT-SWARMS.md-4-created: 2026-07-30
PROJECT/2-WORKING/GH-354-CONCURRENT-SWARMS.md-5-updated: 2026-07-30
PROJECT/2-WORKING/GH-354-CONCURRENT-SWARMS.md-6-owner: noel
PROJECT/2-WORKING/GH-354-CONCURRENT-SWARMS.md-7-gh_issue: 354
PROJECT/2-WORKING/GH-354-CONCURRENT-SWARMS.md-8-source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/354
--
PROJECT/2-WORKING/GH-354-CONCURRENT-SWARMS.md-22-  - Reworking `TICK_REPO_ROOT` resolution. Phase 0 established `.tick/` is already
PROJECT/2-WORKING/GH-354-CONCURRENT-SWARMS.md-23-    per-worktree; the vendored-mismatch question is GH-272's and stays there.
PROJECT/2-WORKING/GH-354-CONCURRENT-SWARMS.md-24-  - Reviving the Bash twins as an authored surface. GH-308 froze them; this plan
PROJECT/2-WORKING/GH-354-CONCURRENT-SWARMS.md-25-    patches them only where a fix must land on both lanes to be real.
PROJECT/2-WORKING/GH-354-CONCURRENT-SWARMS.md-26-  - Any change to `xyz-vendor.sh`'s preserve list. `.relay-driver.lock` is already
PROJECT/2-WORKING/GH-354-CONCURRENT-SWARMS.md:27:    preserved (`relay-automation/xyz-vendor.sh:300`); Phase 1 changes where the lock
PROJECT/2-WORKING/GH-354-CONCURRENT-SWARMS.md-28-    lives in a linked worktree, not what vendoring keeps.
PROJECT/2-WORKING/GH-354-CONCURRENT-SWARMS.md-29-related:
PROJECT/2-WORKING/GH-354-CONCURRENT-SWARMS.md-30-  - "#354 — the originating analysis this plan reviews and corrects."
PROJECT/2-WORKING/GH-354-CONCURRENT-SWARMS.md-31-  - "#42 — the `ROOT@HEAD` concurrent-run hazard the driver lock exists to prevent.
PROJECT/2-WORKING/GH-354-CONCURRENT-SWARMS.md-32-    Phase 0 found the lock does not actually cover two of the three concurrency
PROJECT/2-WORKING/GH-354-CONCURRENT-SWARMS.md-33-    pairs, so #42's guarantee is narrower in a linked worktree than its own error
PROJECT/2-WORKING/GH-354-CONCURRENT-SWARMS.md-34-    message claims."
PROJECT/2-WORKING/GH-354-CONCURRENT-SWARMS.md-35-  - "#49 / GH-49b — the vendored-`.xyz/` and linked-worktree lock-path resolution
PROJECT/2-WORKING/GH-354-CONCURRENT-SWARMS.md-36-    that `marathon-drive` has and `relay-drive` never received."
PROJECT/2-WORKING/GH-354-CONCURRENT-SWARMS.md:37:  - "#308 — Bash-twin freeze + behavior audit. Every Phase 1/2 fix has to land on
PROJECT/2-WORKING/GH-354-CONCURRENT-SWARMS.md-38-    the Python twin (the default lane since GH-264) AND its frozen Bash sibling, or
PROJECT/2-WORKING/GH-354-CONCURRENT-SWARMS.md-39-    it silently does not run; this is the exact failure class #308 catalogued."
PROJECT/2-WORKING/GH-354-CONCURRENT-SWARMS.md-40-  - "#272 — `TICK_REPO_ROOT` vendored mismatch. Adjacent, deliberately NOT merged in:
PROJECT/2-WORKING/GH-354-CONCURRENT-SWARMS.md-41-    Phase 0 found `.tick/` is per-worktree today, so the namespacing #354 proposed
PROJECT/2-WORKING/GH-354-CONCURRENT-SWARMS.md-42-    is not needed for the worktree shape."
--
PROJECT/2-WORKING/GH-354-CONCURRENT-SWARMS.md-70-
PROJECT/2-WORKING/GH-354-CONCURRENT-SWARMS.md-71-## Status
PROJECT/2-WORKING/GH-354-CONCURRENT-SWARMS.md-72-
PROJECT/2-WORKING/GH-354-CONCURRENT-SWARMS.md-73-| What was just completed | What's next |
PROJECT/2-WORKING/GH-354-CONCURRENT-SWARMS.md-74-|---|---|
PROJECT/2-WORKING/GH-354-CONCURRENT-SWARMS.md:75:| **2026-07-30: Phase 0 discovery complete.** Reviewed the actual lock, lane-namespace, session-identity and monitor surfaces on `development` at `b93fd93` — including `relay-drive.sh` and `relay-turn-lib.sh`, which #354 flagged as unavailable and therefore reasoned about from `marathon-drive.sh`'s comments. Both are present and the comments are wrong. **Confirmed:** the marathon↔marathon exclusion, `MARATHON_LANE_NS` existing as the lane override, the `XYZ_SESSION_ID` → `PHASE_ID` fallback, and the monitor's false-IDLE. **Overturned:** (a) marathon↔relay and relay↔relay do **not** mutually exclude in a linked worktree — `relay-drive` never received GH-49b's worktree branch, on either runtime, so it takes a per-worktree lock while `marathon-drive` takes a shared one; (b) `.tick/` task ids, lane attempt counters and `tick analyze` cost do **not** commingle across linked worktrees, because `TICK_REPO_ROOT` defaults to each shim's own `ROOT`; (c) the `git worktree add/prune` exposure is the shared `worktrees/` admin registry and an add-vs-prune race, not `ROOT@HEAD` — `--detach … HEAD` resolves per-worktree. **Escalated:** the false-IDLE bug also exists in `utils/hq/marathon-live.sh` and `utils/hq/hourly-global-scan.sh`. Findings, with `file:line`, in [Phase 0](#phase-0--discovery-verify-354s-claims-against-the-code-complete). | Phase 1 — mirror GH-49b's worktree lock branch into `relay-drive` on **both** runtimes, with a regression test that fails pre-fix. This is a GH-42 containment fix and should not wait on the rest of the plan. |
PROJECT/2-WORKING/GH-354-CONCURRENT-SWARMS.md-76-
PROJECT/2-WORKING/GH-354-CONCURRENT-SWARMS.md-77-## Table of contents
PROJECT/2-WORKING/GH-354-CONCURRENT-SWARMS.md-78-
PROJECT/2-WORKING/GH-354-CONCURRENT-SWARMS.md-79-- [Phase 0 — Discovery: verify #354's claims against the code (COMPLETE)](#phase-0--discovery-verify-354s-claims-against-the-code-complete)
PROJECT/2-WORKING/GH-354-CONCURRENT-SWARMS.md:80:- [Phase 1 — Close the relay-drive worktree lock gap (correctness)](#phase-1--close-the-relay-drive-worktree-lock-gap-correctness)
PROJECT/2-WORKING/GH-354-CONCURRENT-SWARMS.md:81:- [Phase 2 — Make a live worktree run visible to the monitors](#phase-2--make-a-live-worktree-run-visible-to-the-monitors)
PROJECT/2-WORKING/GH-354-CONCURRENT-SWARMS.md-82-- [Phase 3 — Write the one true concurrency sentence, and test it](#phase-3--write-the-one-true-concurrency-sentence-and-test-it)
PROJECT/2-WORKING/GH-354-CONCURRENT-SWARMS.md-83-- [Phase 4 — Decision gate: is opt-in per-worktree parallelism worth building?](#phase-4--decision-gate-is-opt-in-per-worktree-parallelism-worth-building)
PROJECT/2-WORKING/GH-354-CONCURRENT-SWARMS.md-84-
PROJECT/2-WORKING/GH-354-CONCURRENT-SWARMS.md-85----
PROJECT/2-WORKING/GH-354-CONCURRENT-SWARMS.md-86-
--
PROJECT/2-WORKING/GH-354-CONCURRENT-SWARMS.md-134-
PROJECT/2-WORKING/GH-354-CONCURRENT-SWARMS.md-135-Second-order: the fallback lands `.relay-driver.lock` **inside the working tree**, and it is not in
PROJECT/2-WORKING/GH-354-CONCURRENT-SWARMS.md-136-`.gitignore` (checked — `.gitignore` covers `.tick/` and the GH-75 telemetry trio, not the lock). That
PROJECT/2-WORKING/GH-354-CONCURRENT-SWARMS.md-137-is the untracked-bookkeeping problem GH-49b's comment says the worktree branch exists to avoid
PROJECT/2-WORKING/GH-354-CONCURRENT-SWARMS.md-138-(`marathon-drive.sh:191-193`). `relay-drive` has no `--require-clean` of its own, so this does not
PROJECT/2-WORKING/GH-354-CONCURRENT-SWARMS.md:139:trip a documented gate today — call it a latent dirt source, not a live break, and let Phase 1's test
PROJECT/2-WORKING/GH-354-CONCURRENT-SWARMS.md-140-pin it rather than asserting a consequence this pass did not observe.
PROJECT/2-WORKING/GH-354-CONCURRENT-SWARMS.md-141-
PROJECT/2-WORKING/GH-354-CONCURRENT-SWARMS.md-142-**What it changes:** #354's framing — *"the hard blocker (by design)"* — does not hold, so its
PROJECT/2-WORKING/GH-354-CONCURRENT-SWARMS.md:143:conclusion cannot rest on the lock. Phase 1 exists, and is a GH-42 correctness fix that should not
PROJECT/2-WORKING/GH-354-CONCURRENT-SWARMS.md-144-be sequenced behind the parallelism question at all.
PROJECT/2-WORKING/GH-354-CONCURRENT-SWARMS.md-145-
PROJECT/2-WORKING/GH-354-CONCURRENT-SWARMS.md-146-### Finding 0.3 — OVERTURNED: `.tick/` is already per-worktree, so claims 1, 2 and 4 do not fire
PROJECT/2-WORKING/GH-354-CONCURRENT-SWARMS.md-147-
PROJECT/2-WORKING/GH-354-CONCURRENT-SWARMS.md-148-#354 lists commingled tick task names, shared lane attempt counters
--
PROJECT/2-WORKING/GH-354-CONCURRENT-SWARMS.md-211-  file so the first path cannot exist. The cross-repo "is-it-really-driving" answer is **no** for
PROJECT/2-WORKING/GH-354-CONCURRENT-SWARMS.md-212-  every live worktree marathon in the fleet.
PROJECT/2-WORKING/GH-354-CONCURRENT-SWARMS.md-213-- `utils/hq/hourly-global-scan.sh:28` — same `.git/relay-driver.lock` assumption in the hourly
PROJECT/2-WORKING/GH-354-CONCURRENT-SWARMS.md-214-  global scan, so the rolling fleet snapshot inherits the same blind spot every hour.
PROJECT/2-WORKING/GH-354-CONCURRENT-SWARMS.md-215-
PROJECT/2-WORKING/GH-354-CONCURRENT-SWARMS.md:216:**What it changes:** promotes this from a footnote to Phase 2, and it is load-bearing for the rest of
PROJECT/2-WORKING/GH-354-CONCURRENT-SWARMS.md-217-the plan. Every exclusion argument here is verified by *observing which lock is held*; if the
PROJECT/2-WORKING/GH-354-CONCURRENT-SWARMS.md-218-operator's three windows onto that state are all blind in exactly the shape under discussion, no
PROJECT/2-WORKING/GH-354-CONCURRENT-SWARMS.md-219-concurrency claim can be checked in the field. Note the asymmetry that makes this dangerous rather
PROJECT/2-WORKING/GH-354-CONCURRENT-SWARMS.md-220-than merely wrong: post-Phase-1, a live **relay** in a worktree *will* be seen (its lock is
PROJECT/2-WORKING/GH-354-CONCURRENT-SWARMS.md-221-per-worktree, which is what the monitors look for) while a live **marathon** will not — so the fleet
--
PROJECT/2-WORKING/GH-354-CONCURRENT-SWARMS.md-232-- [x] Unproven items (the add-vs-prune race; the `.relay-driver.lock` dirt consequence) labelled as
PROJECT/2-WORKING/GH-354-CONCURRENT-SWARMS.md-233-      hypotheses with owning phases, not reported as findings.
PROJECT/2-WORKING/GH-354-CONCURRENT-SWARMS.md-234-
PROJECT/2-WORKING/GH-354-CONCURRENT-SWARMS.md-235----
PROJECT/2-WORKING/GH-354-CONCURRENT-SWARMS.md-236-
PROJECT/2-WORKING/GH-354-CONCURRENT-SWARMS.md:237:## Phase 1 — Close the relay-drive worktree lock gap (correctness)
PROJECT/2-WORKING/GH-354-CONCURRENT-SWARMS.md-238-
PROJECT/2-WORKING/GH-354-CONCURRENT-SWARMS.md-239-Ship Finding 0.2's fix. Mirror `marathon-drive`'s three-branch resolution into `relay-drive` so the
PROJECT/2-WORKING/GH-354-CONCURRENT-SWARMS.md-240-lock name and the lock **path** agree, on both runtimes.
PROJECT/2-WORKING/GH-354-CONCURRENT-SWARMS.md-241-
PROJECT/2-WORKING/GH-354-CONCURRENT-SWARMS.md-242-Scope — four files, one behavior:
--
PROJECT/2-WORKING/GH-354-CONCURRENT-SWARMS.md-247-- `utils/py/relay_drive.py:386-391` — same, mirroring `utils/py/marathon_drive.py:293-313`.
PROJECT/2-WORKING/GH-354-CONCURRENT-SWARMS.md-248-- The Bash pair is GH-308-frozen. It gets the patch anyway: leaving `XYZ_PYTHON=0` with a silently
PROJECT/2-WORKING/GH-354-CONCURRENT-SWARMS.md-249-  weaker containment guard is the same "fake safety gate in the fallback" call already made at
PROJECT/2-WORKING/GH-354-CONCURRENT-SWARMS.md-250-  `marathon-drive.sh:685`. Note it in the GH-308 audit doc rather than inventing a new exemption.
PROJECT/2-WORKING/GH-354-CONCURRENT-SWARMS.md-251-
PROJECT/2-WORKING/GH-354-CONCURRENT-SWARMS.md:252:Deliberately **not** in Phase 1: extracting the resolution into one shared helper. That is the right
PROJECT/2-WORKING/GH-354-CONCURRENT-SWARMS.md-253-end state and the wrong first move — a fifth copy is a fifth thing to drift, but a refactor across a
PROJECT/2-WORKING/GH-354-CONCURRENT-SWARMS.md-254-frozen twin and a live lane is a bigger blast radius than the bug. Re-raise it after Phase 3's test
PROJECT/2-WORKING/GH-354-CONCURRENT-SWARMS.md-255-pins the behavior from both sides.
PROJECT/2-WORKING/GH-354-CONCURRENT-SWARMS.md-256-
PROJECT/2-WORKING/GH-354-CONCURRENT-SWARMS.md:257:### Phase 1 QA gate
PROJECT/2-WORKING/GH-354-CONCURRENT-SWARMS.md-258-
PROJECT/2-WORKING/GH-354-CONCURRENT-SWARMS.md-259-- `test/driver-lock.sh` extended (or a sibling added and **registered in `validate.sh`'s explicit
PROJECT/2-WORKING/GH-354-CONCURRENT-SWARMS.md-260-  `TESTS=()` array** — GH-292 recorded that an unregistered test silently never runs) covering, in a
PROJECT/2-WORKING/GH-354-CONCURRENT-SWARMS.md-261-  real `git worktree add`ed fixture:
PROJECT/2-WORKING/GH-354-CONCURRENT-SWARMS.md-262-  - a live marathon lock in the common dir **refuses** a relay start in the worktree (exit 1) — this
PROJECT/2-WORKING/GH-354-CONCURRENT-SWARMS.md-263-    is the assertion that fails pre-fix;
PROJECT/2-WORKING/GH-354-CONCURRENT-SWARMS.md-264-  - a live relay in worktree W1 **refuses** a relay in W2 of the same clone;
PROJECT/2-WORKING/GH-354-CONCURRENT-SWARMS.md-265-  - both assertions run under `XYZ_PYTHON=1` **and** `XYZ_PYTHON=0`;
PROJECT/2-WORKING/GH-354-CONCURRENT-SWARMS.md-266-  - the vendored `.xyz/` (no `.git`) and plain-clone paths are **unchanged** — byte-identical lock
PROJECT/2-WORKING/GH-354-CONCURRENT-SWARMS.md-267-    path to pre-fix, so the fix cannot regress the two shapes that work today.
PROJECT/2-WORKING/GH-354-CONCURRENT-SWARMS.md:268:- The new test is observed **failing before** the fix and passing after, and that observation is
PROJECT/2-WORKING/GH-354-CONCURRENT-SWARMS.md-269-  recorded here (`gh319`/`gh312` precedent: a test not seen red is not evidence).
PROJECT/2-WORKING/GH-354-CONCURRENT-SWARMS.md-270-- `./validate.sh` green, with the run's pass/fail counts recorded here — not "green" as prose.
PROJECT/2-WORKING/GH-354-CONCURRENT-SWARMS.md-271-- `utils/pdda/pdda.sh run` clean.
PROJECT/2-WORKING/GH-354-CONCURRENT-SWARMS.md-272-
PROJECT/2-WORKING/GH-354-CONCURRENT-SWARMS.md-273----
PROJECT/2-WORKING/GH-354-CONCURRENT-SWARMS.md-274-
PROJECT/2-WORKING/GH-354-CONCURRENT-SWARMS.md:275:## Phase 2 — Make a live worktree run visible to the monitors
PROJECT/2-WORKING/GH-354-CONCURRENT-SWARMS.md-276-
PROJECT/2-WORKING/GH-354-CONCURRENT-SWARMS.md-277-Fix Finding 0.5 in all three monitors. Each needs the same `-f .git` → `--git-common-dir` probe added
PROJECT/2-WORKING/GH-354-CONCURRENT-SWARMS.md-278-ahead of its existing fallbacks, and each must keep working when `git` is absent or the path is not a
PROJECT/2-WORKING/GH-354-CONCURRENT-SWARMS.md-279-repo at all (these are read-only fleet monitors — degrade to the current answer, never error).
PROJECT/2-WORKING/GH-354-CONCURRENT-SWARMS.md-280-
PROJECT/2-WORKING/GH-354-CONCURRENT-SWARMS.md-281-- `relay-automation/marathon-ls.sh:44-50` — `lock_path_for_repo` returns the common-dir path for a
PROJECT/2-WORKING/GH-354-CONCURRENT-SWARMS.md-282-  linked worktree. Its header comment (`:41-43`) documents only two shapes and must document three.
PROJECT/2-WORKING/GH-354-CONCURRENT-SWARMS.md-283-- `utils/hq/marathon-live.sh:94-95` — add the common-dir probe to the ordered candidate list.
PROJECT/2-WORKING/GH-354-CONCURRENT-SWARMS.md-284-- `utils/hq/hourly-global-scan.sh:28` — same, so the hourly snapshot stops inheriting the blind spot.
PROJECT/2-WORKING/GH-354-CONCURRENT-SWARMS.md-285-
PROJECT/2-WORKING/GH-354-CONCURRENT-SWARMS.md:286:Sequenced **after** Phase 1 on purpose: post-Phase-1 both drivers write predictable per-shape paths,
PROJECT/2-WORKING/GH-354-CONCURRENT-SWARMS.md-287-so the monitors are taught one rule rather than being taught to model today's inconsistency.
PROJECT/2-WORKING/GH-354-CONCURRENT-SWARMS.md-288-
PROJECT/2-WORKING/GH-354-CONCURRENT-SWARMS.md:289:### Phase 2 QA gate
PROJECT/2-WORKING/GH-354-CONCURRENT-SWARMS.md-290-
PROJECT/2-WORKING/GH-354-CONCURRENT-SWARMS.md-291-- A fixture worktree with a marathon lock held in the common dir renders **LIVE** in
PROJECT/2-WORKING/GH-354-CONCURRENT-SWARMS.md-292-  `marathon-ls.sh`, and `marathon-live.sh` answers "really driving: yes" — both assertions failing
PROJECT/2-WORKING/GH-354-CONCURRENT-SWARMS.md-293-  pre-fix.
PROJECT/2-WORKING/GH-354-CONCURRENT-SWARMS.md-294-- Plain-clone and vendored-`.xyz/` repos render exactly as before (regression guard on the two
--
PROJECT/2-WORKING/GH-354-CONCURRENT-SWARMS.md-323-### Phase 3 QA gate
PROJECT/2-WORKING/GH-354-CONCURRENT-SWARMS.md-324-
PROJECT/2-WORKING/GH-354-CONCURRENT-SWARMS.md-325-- The exclusion matrix appears in exactly **one** canonical place, with the others linking to it
PROJECT/2-WORKING/GH-354-CONCURRENT-SWARMS.md-326-  (PDDA Principle #4 — one canonical place per fact); no second copy of the matrix in a driver
PROJECT/2-WORKING/GH-354-CONCURRENT-SWARMS.md-327-  comment.
PROJECT/2-WORKING/GH-354-CONCURRENT-SWARMS.md:328:- Every row of the documented matrix is backed by a named assertion from Phase 1/2's tests, cited by
PROJECT/2-WORKING/GH-354-CONCURRENT-SWARMS.md-329-  test name in the doc.
PROJECT/2-WORKING/GH-354-CONCURRENT-SWARMS.md-330-- `relay-drive.sh`'s own header documents its lock shapes to the same standard as
PROJECT/2-WORKING/GH-354-CONCURRENT-SWARMS.md-331-  `marathon-drive.sh:190-196`.
PROJECT/2-WORKING/GH-354-CONCURRENT-SWARMS.md-332-- `utils/pdda/pdda.sh run` clean; `#354` updated.
PROJECT/2-WORKING/GH-354-CONCURRENT-SWARMS.md-333-
--
test/gh358-lock-instrumentation.sh-21-# Control 1: all appenders exit 0, then one record is deliberately removed.  This must identify a
test/gh358-lock-instrumentation.sh-22-# successful writer whose record vanished, not report starvation or a generic count mismatch.
test/gh358-lock-instrumentation.sh-23-clobber_dir="$WORK/clobber"
test/gh358-lock-instrumentation.sh-24-mkdir -p "$clobber_dir"
test/gh358-lock-instrumentation.sh-25-clobber_log="$WORK/clobber.log"
test/gh358-lock-instrumentation.sh:26:if TMPDIR="$clobber_dir" XYZ_COMPLETION_TEST_CLOBBER_SESSION_ID=conc-1 bash "$XYZ_TEST" >"$clobber_log" 2>&1; then
test/gh358-lock-instrumentation.sh-27-  fail "clobbered-record control unexpectedly passed"
test/gh358-lock-instrumentation.sh-28-else
test/gh358-lock-instrumentation.sh-29-  pass "clobbered-record control fails as intended"
test/gh358-lock-instrumentation.sh-30-fi
test/gh358-lock-instrumentation.sh:31:require_log "$clobber_log" "missing sessionId=conc-1; terminal state=lock acquired, record lost" "clobber names the missing successful session"
test/gh358-lock-instrumentation.sh-32-require_log "$clobber_log" "test wait=60s; writer XYZ_LOCK_WAIT_S=30s (default=30s)" "clobber reports both normal lock bounds"
test/gh358-lock-instrumentation.sh-33-if grep -Fq "terminal state=lock never acquired" "$clobber_log"; then
test/gh358-lock-instrumentation.sh-34-  fail "clobber is not mislabeled as lock starvation"
test/gh358-lock-instrumentation.sh-35-else
test/gh358-lock-instrumentation.sh-36-  pass "clobber remains distinct from starvation"
--
PROJECT/2-WORKING/GH-388-MARATHON-RUN-LOG-DURABILITY.md-32-
PROJECT/2-WORKING/GH-388-MARATHON-RUN-LOG-DURABILITY.md-33-## Status
PROJECT/2-WORKING/GH-388-MARATHON-RUN-LOG-DURABILITY.md-34-
PROJECT/2-WORKING/GH-388-MARATHON-RUN-LOG-DURABILITY.md-35-| What was just completed | What's next |
PROJECT/2-WORKING/GH-388-MARATHON-RUN-LOG-DURABILITY.md-36-|---|---|
PROJECT/2-WORKING/GH-388-MARATHON-RUN-LOG-DURABILITY.md:37:| **Both phases built 2026-08-11.** `marathon.sh` owns a durable chain run log under the same transcript root as the per-phase transcripts, announced at chain start; a phase killed mid-run leaves a content-bearing `PHASE-INTERRUPTED.md`; `rtl_default_log` refuses on both lanes instead of silently relocating to volatile storage; and the non-durable locations are stated in one runtime-read file. `test/gh388-run-log-durability.sh` 24/0, observed **9 red** pre-fix. | Close #388 against the acceptance block below. All seven criteria met — see "Acceptance — outcome". |
PROJECT/2-WORKING/GH-388-MARATHON-RUN-LOG-DURABILITY.md-38-
PROJECT/2-WORKING/GH-388-MARATHON-RUN-LOG-DURABILITY.md-39-## Acceptance — outcome
PROJECT/2-WORKING/GH-388-MARATHON-RUN-LOG-DURABILITY.md-40-
PROJECT/2-WORKING/GH-388-MARATHON-RUN-LOG-DURABILITY.md:41:1. **Met.** `marathon.sh` opens `<transcript-root>/run-logs/<date>/marathon-<plan>-<time>-<pid>.log` and `tee`s stdout+stderr into it as produced. Armed after plan validation and before the phase loop, so a usage error or an unparseable plan leaves no log implying a run happened; `--dry-run` is excluded for the same reason, and that exclusion is asserted.
PROJECT/2-WORKING/GH-388-MARATHON-RUN-LOG-DURABILITY.md:42:2. **Met.** `marathon: run log: <path>` is printed at chain start, and the test parses that line rather than guessing the path — if the announcement breaks, the test cannot find the file.
PROJECT/2-WORKING/GH-388-MARATHON-RUN-LOG-DURABILITY.md:43:3. **Met.** `_write_interrupted_phase_record` writes `PHASE-INTERRUPTED.md` carrying the phase id, the relay `STATUS:` read *at interruption*, the recorded round count, the reason and the exit code. Asserted on content, not existence, and against a marker stamped after dispatch — the empty-file and pre-created-file loopholes the issue's own review found.
PROJECT/2-WORKING/GH-388-MARATHON-RUN-LOG-DURABILITY.md:44:4. **Met, both lanes.** `rtl_default_log` in `utils/py/rtl.py` and in `relay-turn-lib.sh` now exit 5 rather than returning a `$TMPDIR` path, and the resolver's stderr is no longer swallowed (`quiet=True` is gone), so the refusal names *why* the root failed to resolve. `test/relay-turn-trace.sh`'s case 3c, which pinned the old fallback, is inverted with the rationale recorded in place.
PROJECT/2-WORKING/GH-388-MARATHON-RUN-LOG-DURABILITY.md:45:5. **Met.** `relay-automation/non-durable-log-roots.conf` is the single registry, read at runtime by `durable-log-lib.sh` (Bash) and `rtl.py::non_durable_reason` (Python). The test asserts the two readers agree on every probe path *and* that an invented entry changes the verdict — without that second assertion the file could be decorative while the real list lived in the readers.
PROJECT/2-WORKING/GH-388-MARATHON-RUN-LOG-DURABILITY.md:46:6. **Met.** Part C kills a running phase; Part D kills a running chain. Both assert on what is left on disk.
PROJECT/2-WORKING/GH-388-MARATHON-RUN-LOG-DURABILITY.md:47:7. **Met.** `test/baselines/GH-388-negative-control.md` carries both runs in full: 9 red pre-fix, 0 after.
PROJECT/2-WORKING/GH-388-MARATHON-RUN-LOG-DURABILITY.md-48-
PROJECT/2-WORKING/GH-388-MARATHON-RUN-LOG-DURABILITY.md:49:## Acceptance — deviations found while building
PROJECT/2-WORKING/GH-388-MARATHON-RUN-LOG-DURABILITY.md-50-
PROJECT/2-WORKING/GH-388-MARATHON-RUN-LOG-DURABILITY.md-51-**The durability rule is scoped to RELOCATION, not to absolute location.** A transcript that resolves
PROJECT/2-WORKING/GH-388-MARATHON-RUN-LOG-DURABILITY.md:52:*inside the repo being driven* is permitted even when that repo sits in `$TMPDIR`; only a path that is
PROJECT/2-WORKING/GH-388-MARATHON-RUN-LOG-DURABILITY.md:53:both non-durable *and* outside the repo is refused. Criterion 5 reads "a default log path resolving
PROJECT/2-WORKING/GH-388-MARATHON-RUN-LOG-DURABILITY.md-54-into one of them fails the run", which taken literally refuses to run the harness inside every fixture
PROJECT/2-WORKING/GH-388-MARATHON-RUN-LOG-DURABILITY.md-55-in this suite — every one of them is a repo under `$TMPDIR`. A guard that cannot be exercised is not a
PROJECT/2-WORKING/GH-388-MARATHON-RUN-LOG-DURABILITY.md-56-guard, and "fails the run" would have meant "fails every run". The defect being fixed is the harness
PROJECT/2-WORKING/GH-388-MARATHON-RUN-LOG-DURABILITY.md-57-*silently moving* evidence out of the repo; a repo the operator put in `/tmp` makes the code, the
PROJECT/2-WORKING/GH-388-MARATHON-RUN-LOG-DURABILITY.md-58-commits and the log volatile together, visibly, by their choice.
--
PROJECT/2-WORKING/GH-388-MARATHON-RUN-LOG-DURABILITY.md-93-## Two corrections the review produced
PROJECT/2-WORKING/GH-388-MARATHON-RUN-LOG-DURABILITY.md-94-
PROJECT/2-WORKING/GH-388-MARATHON-RUN-LOG-DURABILITY.md-95-Both from codex, both verified against `development` @ `3b37072` before being acted on:
PROJECT/2-WORKING/GH-388-MARATHON-RUN-LOG-DURABILITY.md-96-
PROJECT/2-WORKING/GH-388-MARATHON-RUN-LOG-DURABILITY.md-97-- **A criterion of mine rested on a false premise.** It asserted that *"the repo's own PDDA lint
PROJECT/2-WORKING/GH-388-MARATHON-RUN-LOG-DURABILITY.md:98:  already classifies those locations as non-durable."* It does not — `check_hardcoded_paths` reads
PROJECT/2-WORKING/GH-388-MARATHON-RUN-LOG-DURABILITY.md-99-  `pdda_list_working_docs` and scans **documentation** for literal absolute paths. It says nothing
PROJECT/2-WORKING/GH-388-MARATHON-RUN-LOG-DURABILITY.md-100-  about runtime log destinations. The criterion was rewritten to require the harness to state the
PROJECT/2-WORKING/GH-388-MARATHON-RUN-LOG-DURABILITY.md:101:  non-durable set somewhere it actually reads at runtime.
PROJECT/2-WORKING/GH-388-MARATHON-RUN-LOG-DURABILITY.md-102-- **"Writes a partial transcript" was satisfiable by an empty file.** A static or pre-created
PROJECT/2-WORKING/GH-388-MARATHON-RUN-LOG-DURABILITY.md-103-  transcript met the words while the failing phase's evidence remained absent. It now requires the
PROJECT/2-WORKING/GH-388-MARATHON-RUN-LOG-DURABILITY.md-104-  file to have been created or modified *after that phase started* and to carry the phase id, the
PROJECT/2-WORKING/GH-388-MARATHON-RUN-LOG-DURABILITY.md-105-  relay state at interruption, and the failure reason.
PROJECT/2-WORKING/GH-388-MARATHON-RUN-LOG-DURABILITY.md-106-
--
PROJECT/2-WORKING/GH-388-MARATHON-RUN-LOG-DURABILITY.md-114-(`## Acceptance`), fetched 2026-08-06. Deviations, if any, are recorded below this block.*
PROJECT/2-WORKING/GH-388-MARATHON-RUN-LOG-DURABILITY.md-115-
PROJECT/2-WORKING/GH-388-MARATHON-RUN-LOG-DURABILITY.md-116-- [ ] A durable run log captures the whole chain's output as it is produced, under the same transcript root the per-phase transcripts already use. Where the run narrative goes is the harness's decision, not the invoker's.
PROJECT/2-WORKING/GH-388-MARATHON-RUN-LOG-DURABILITY.md-117-- [ ] The run log's path is printed at chain start, so an operator knows where to look afterwards.
PROJECT/2-WORKING/GH-388-MARATHON-RUN-LOG-DURABILITY.md-118-- [ ] A phase that escalates, times out, or dies mid-gate leaves a transcript that was **created or modified after that phase started** and contains the phase id, the relay state at interruption, and the failure or kill reason. An empty or pre-created file does not satisfy this.
PROJECT/2-WORKING/GH-388-MARATHON-RUN-LOG-DURABILITY.md:119:- [ ] `rtl_default_log` does not silently relocate turn logs to volatile storage. It either resolves a durable root or refuses before the turn launches; if a volatile fallback is retained, it is reported as non-durable and is never presented as the turn transcript. Adding a message while still writing to storage a reboot erases does not satisfy this.
PROJECT/2-WORKING/GH-388-MARATHON-RUN-LOG-DURABILITY.md:120:- [ ] The locations the harness treats as non-durable are stated in one place it actually reads at runtime, and a default log path resolving into one of them fails the run rather than proceeding.
PROJECT/2-WORKING/GH-388-MARATHON-RUN-LOG-DURABILITY.md-121-- [ ] A regression test kills a phase mid-run and asserts that both a chain-level run log and a content-bearing partial phase transcript survive.
PROJECT/2-WORKING/GH-388-MARATHON-RUN-LOG-DURABILITY.md-122-- [ ] The regression test is observed failing against the pre-fix revision, and a durable record states the reproducer command, the pre-fix revision, the pre-fix result and the post-fix result. A sentence asserting a negative control happened is not the record, per #419.
PROJECT/2-WORKING/GH-388-MARATHON-RUN-LOG-DURABILITY.md-123-
PROJECT/2-WORKING/GH-388-MARATHON-RUN-LOG-DURABILITY.md:124:## Acceptance — deviations from the issue
PROJECT/2-WORKING/GH-388-MARATHON-RUN-LOG-DURABILITY.md-125-
PROJECT/2-WORKING/GH-388-MARATHON-RUN-LOG-DURABILITY.md-126-None. Every criterion is carried verbatim.
PROJECT/2-WORKING/GH-388-MARATHON-RUN-LOG-DURABILITY.md-127-
PROJECT/2-WORKING/GH-388-MARATHON-RUN-LOG-DURABILITY.md-128-The criteria were **authored onto the issue on 2026-08-05** (it had none) and **revised on 2026-08-06**
PROJECT/2-WORKING/GH-388-MARATHON-RUN-LOG-DURABILITY.md-129-after the codex+agy review, for the three reasons above. The `tee` prescription was also dropped —
--
PROJECT/2-WORKING/GH-388-MARATHON-RUN-LOG-DURABILITY.md-132-## Phases
PROJECT/2-WORKING/GH-388-MARATHON-RUN-LOG-DURABILITY.md-133-
PROJECT/2-WORKING/GH-388-MARATHON-RUN-LOG-DURABILITY.md-134-| Phase | Deliverable | Artifacts | cx/risk/eff |
PROJECT/2-WORKING/GH-388-MARATHON-RUN-LOG-DURABILITY.md-135-|---|---|---|---|
PROJECT/2-WORKING/GH-388-MARATHON-RUN-LOG-DURABILITY.md-136-| 1 | The chain run log. One durable file opened at chain start under the same transcript root the per-phase transcripts use, capturing the chain's output as it is produced, with its path printed at start. Plus a content-bearing partial transcript when a phase escalates, times out, or dies mid-gate. | `relay-automation/marathon.sh`, `utils/py/marathon_drive.py` | 2/2/3 |
PROJECT/2-WORKING/GH-388-MARATHON-RUN-LOG-DURABILITY.md:137:| 2 | The durability rule. The non-durable locations are stated in one place the harness reads at runtime; `rtl_default_log` resolves a durable root or refuses before the turn launches, and a retained volatile fallback is never presented as the turn transcript. Plus the kill-mid-run regression. | `utils/py/rtl.py`, `test/gh388-run-log-durability.sh`, `validate.sh` | 2/2/3 |
PROJECT/2-WORKING/GH-388-MARATHON-RUN-LOG-DURABILITY.md-138-
PROJECT/2-WORKING/GH-388-MARATHON-RUN-LOG-DURABILITY.md-139-## Litmus tests
PROJECT/2-WORKING/GH-388-MARATHON-RUN-LOG-DURABILITY.md-140-
PROJECT/2-WORKING/GH-388-MARATHON-RUN-LOG-DURABILITY.md-141-- **A green suite is not evidence here.** Everything works on the success path today. The only
PROJECT/2-WORKING/GH-388-MARATHON-RUN-LOG-DURABILITY.md-142-  assertion that matters is what survives a kill, so the regression must actually kill a phase.
--
PROJECT/2-WORKING/GH-388-MARATHON-RUN-LOG-DURABILITY.md-165-**Probe polarity** (probes detect the **bug**, not the fix): `path_absent` reports `landed` when the
PROJECT/2-WORKING/GH-388-MARATHON-RUN-LOG-DURABILITY.md-166-path *exists*; `grep_absent` reports `landed` when the pattern *is found*. Verified 2026-08-06:
PROJECT/2-WORKING/GH-388-MARATHON-RUN-LOG-DURABILITY.md-167-`run log` occurs **0 times** (case-insensitive) in `relay-automation/marathon.sh`.
PROJECT/2-WORKING/GH-388-MARATHON-RUN-LOG-DURABILITY.md-168-
PROJECT/2-WORKING/GH-388-MARATHON-RUN-LOG-DURABILITY.md-169-**`relay-automation/marathon.sh` is not a frozen twin** — verified 2026-08-06, no GH-308 banner — so
PROJECT/2-WORKING/GH-388-MARATHON-RUN-LOG-DURABILITY.md:170:Phase 1 may edit it directly. `utils/py/rtl.py` is the authoritative Python lane.
PROJECT/2-WORKING/GH-388-MARATHON-RUN-LOG-DURABILITY.md-171-
PROJECT/2-WORKING/GH-388-MARATHON-RUN-LOG-DURABILITY.md:172:## Method note
PROJECT/2-WORKING/GH-388-MARATHON-RUN-LOG-DURABILITY.md-173-
PROJECT/2-WORKING/GH-388-MARATHON-RUN-LOG-DURABILITY.md-174-The phase-5 evidence, the cleared-temp-directory finding and the `rtl_default_log` code path are
PROJECT/2-WORKING/GH-388-MARATHON-RUN-LOG-DURABILITY.md-175-carried from the issue. The PDDA-lint correction and the empty-transcript loophole came from the
PROJECT/2-WORKING/GH-388-MARATHON-RUN-LOG-DURABILITY.md-176-codex review and were verified directly before being written as criteria. No open PR or branch
PROJECT/2-WORKING/GH-388-MARATHON-RUN-LOG-DURABILITY.md-177-touches this issue — checked before authoring.
--
PROJECT/2-WORKING/GH-358-LOCK-FLAKE-INSTRUMENTATION.md-32-
PROJECT/2-WORKING/GH-358-LOCK-FLAKE-INSTRUMENTATION.md-33-## Status
PROJECT/2-WORKING/GH-358-LOCK-FLAKE-INSTRUMENTATION.md-34-
PROJECT/2-WORKING/GH-358-LOCK-FLAKE-INSTRUMENTATION.md-35-| What was just completed | What's next |
PROJECT/2-WORKING/GH-358-LOCK-FLAKE-INSTRUMENTATION.md-36-|---|---|
PROJECT/2-WORKING/GH-358-LOCK-FLAKE-INSTRUMENTATION.md:37:| Captured 2026-08-06 as a lane of release 0.2.0 Litmus. Acceptance criteria authored on the issue (it had none) and revised after an adversarial codex+agy review, which found that every appender's exit status is discarded today and that two different lock bounds are in play. | Operator go. Then Phase 1 (instrument: retain exit status, report the missing record's terminal state, name both bounds) and only then Phase 2 (choose the disposition on that evidence). |
PROJECT/2-WORKING/GH-358-LOCK-FLAKE-INSTRUMENTATION.md-38-
PROJECT/2-WORKING/GH-358-LOCK-FLAKE-INSTRUMENTATION.md-39-## The defect
PROJECT/2-WORKING/GH-358-LOCK-FLAKE-INSTRUMENTATION.md-40-
PROJECT/2-WORKING/GH-358-LOCK-FLAKE-INSTRUMENTATION.md-41-`test/xyz-completion.sh`'s lock-under-concurrency case fails intermittently on the shared runner,
PROJECT/2-WORKING/GH-358-LOCK-FLAKE-INSTRUMENTATION.md-42-losing one of 16 records. The same commit re-run passed; it passes locally. The originating PR's
--
PROJECT/2-WORKING/GH-358-LOCK-FLAKE-INSTRUMENTATION.md-75-- [ ] The change ships the instrumentation output from a reproduced failure, and the disposition applied is the one that evidence indicates. A disposition chosen without that output does not satisfy this.
PROJECT/2-WORKING/GH-358-LOCK-FLAKE-INSTRUMENTATION.md-76-- [ ] `M` is not lowered from 16 and the distinctness check is not dropped. Both make the symptom disappear and leave the safety property untested.
PROJECT/2-WORKING/GH-358-LOCK-FLAKE-INSTRUMENTATION.md-77-- [ ] If it goes on the CI exclusion list, the workflow states **why**, so a reader does not take the exclusion to mean the property is not worth checking.
PROJECT/2-WORKING/GH-358-LOCK-FLAKE-INSTRUMENTATION.md-78-- [ ] The instrumentation is demonstrated to distinguish the causes: a deliberately clobbered record and a deliberately starved appender produce visibly different reports. A lock test that cannot tell a flake from a real lost update is not evidence, per #419.
PROJECT/2-WORKING/GH-358-LOCK-FLAKE-INSTRUMENTATION.md-79-
PROJECT/2-WORKING/GH-358-LOCK-FLAKE-INSTRUMENTATION.md:80:## Acceptance — deviations from the issue
PROJECT/2-WORKING/GH-358-LOCK-FLAKE-INSTRUMENTATION.md-81-
PROJECT/2-WORKING/GH-358-LOCK-FLAKE-INSTRUMENTATION.md-82-None. Every criterion is carried verbatim.
PROJECT/2-WORKING/GH-358-LOCK-FLAKE-INSTRUMENTATION.md-83-
PROJECT/2-WORKING/GH-358-LOCK-FLAKE-INSTRUMENTATION.md-84-The criteria were **authored onto the issue on 2026-08-05** (it had none) and **revised on 2026-08-06**
PROJECT/2-WORKING/GH-358-LOCK-FLAKE-INSTRUMENTATION.md-85-after the codex+agy review. Two changes are worth naming: the exit-status criterion is new and came
--
PROJECT/2-WORKING/GH-358-LOCK-FLAKE-INSTRUMENTATION.md-92-| Phase | Deliverable | Artifacts | cx/risk/eff |
PROJECT/2-WORKING/GH-358-LOCK-FLAKE-INSTRUMENTATION.md-93-|---|---|---|---|
PROJECT/2-WORKING/GH-358-LOCK-FLAKE-INSTRUMENTATION.md-94-| 1 | Instrumentation. Retain and assert each appender's exit status; on mismatch report the missing record's terminal state — lock acquired and record lost, lock never acquired, or process failed — and name both effective bounds with the one that was exhausted. | `test/xyz-completion.sh`, `utils/telemetry/append-xyz-completion.sh`, `test/gh358-lock-instrumentation.sh` | 2/2/2 |
PROJECT/2-WORKING/GH-358-LOCK-FLAKE-INSTRUMENTATION.md-95-| 2 | Disposition, on that evidence. Raise the bound, retry the assertion, or exclude with a stated reason in the workflow. `M` stays 16 and the distinctness check stays. | `.github/workflows/ci.yml` or `test/xyz-completion.sh` | 1/2/1 |
PROJECT/2-WORKING/GH-358-LOCK-FLAKE-INSTRUMENTATION.md-96-
PROJECT/2-WORKING/GH-358-LOCK-FLAKE-INSTRUMENTATION.md:97:**Phase 2 must not be pre-committed in the packet.** A builder told which disposition to apply will
PROJECT/2-WORKING/GH-358-LOCK-FLAKE-INSTRUMENTATION.md-98-produce instrumentation that agrees with the instruction — the same defect as grading against a
PROJECT/2-WORKING/GH-358-LOCK-FLAKE-INSTRUMENTATION.md-99-model-authored requirement.
PROJECT/2-WORKING/GH-358-LOCK-FLAKE-INSTRUMENTATION.md-100-
PROJECT/2-WORKING/GH-358-LOCK-FLAKE-INSTRUMENTATION.md-101-## Litmus tests
PROJECT/2-WORKING/GH-358-LOCK-FLAKE-INSTRUMENTATION.md-102-
--
PROJECT/2-WORKING/GH-358-LOCK-FLAKE-INSTRUMENTATION.md-105-  reports. If it cannot tell those apart it has not fixed anything.
PROJECT/2-WORKING/GH-358-LOCK-FLAKE-INSTRUMENTATION.md-106-- **A green run proves nothing here.** The failure is intermittent; a passing suite after the change
PROJECT/2-WORKING/GH-358-LOCK-FLAKE-INSTRUMENTATION.md-107-  is consistent with the instrumentation never having been exercised. The controls above are the
PROJECT/2-WORKING/GH-358-LOCK-FLAKE-INSTRUMENTATION.md-108-  only evidence.
PROJECT/2-WORKING/GH-358-LOCK-FLAKE-INSTRUMENTATION.md-109-- **If the answer turns out to be a real lock bug, the priority changes completely** and this lane
PROJECT/2-WORKING/GH-358-LOCK-FLAKE-INSTRUMENTATION.md:110:  should stop and re-file rather than proceed to Phase 2's exclusion option.
PROJECT/2-WORKING/GH-358-LOCK-FLAKE-INSTRUMENTATION.md-111-
PROJECT/2-WORKING/GH-358-LOCK-FLAKE-INSTRUMENTATION.md-112-## Swarm Preflight Contract
PROJECT/2-WORKING/GH-358-LOCK-FLAKE-INSTRUMENTATION.md-113-
PROJECT/2-WORKING/GH-358-LOCK-FLAKE-INSTRUMENTATION.md-114-```json
PROJECT/2-WORKING/GH-358-LOCK-FLAKE-INSTRUMENTATION.md-115-{
--
PROJECT/2-WORKING/GH-358-LOCK-FLAKE-INSTRUMENTATION.md-132-
PROJECT/2-WORKING/GH-358-LOCK-FLAKE-INSTRUMENTATION.md-133-**This lane's artifacts include `test/*.sh` it must edit.** Per the marathon plan's standing note,
PROJECT/2-WORKING/GH-358-LOCK-FLAKE-INSTRUMENTATION.md-134-those are read-only specs in-turn and the outer harness gate verifies them after the turn, outside
PROJECT/2-WORKING/GH-358-LOCK-FLAKE-INSTRUMENTATION.md-135-the isolated worktree.
PROJECT/2-WORKING/GH-358-LOCK-FLAKE-INSTRUMENTATION.md-136-
PROJECT/2-WORKING/GH-358-LOCK-FLAKE-INSTRUMENTATION.md:137:## Method note
PROJECT/2-WORKING/GH-358-LOCK-FLAKE-INSTRUMENTATION.md-138-
PROJECT/2-WORKING/GH-358-LOCK-FLAKE-INSTRUMENTATION.md-139-The flake evidence and the "do not lower M / do not drop distinctness" constraints are carried from
PROJECT/2-WORKING/GH-358-LOCK-FLAKE-INSTRUMENTATION.md-140-the issue. The discarded-exit-status finding and the two-bound mismatch came from the codex review
PROJECT/2-WORKING/GH-358-LOCK-FLAKE-INSTRUMENTATION.md-141-and were verified directly against `development` @ `3b37072` before being written as criteria. No
PROJECT/2-WORKING/GH-358-LOCK-FLAKE-INSTRUMENTATION.md-142-open PR or branch touches this issue — checked before authoring.
--
RELEASES.md-98-
RELEASES.md-99-Release: 0.2.0
RELEASES.md-100-Iterations: 0.2.0-0.2.4
RELEASES.md-101-Status: Release Candidate — exit criterion MET 2026-08-09 on `development` @ `263816c`
RELEASES.md-102-Target Date: 2026-09-05
RELEASES.md:103:RC evidence: `bash test/litmus-release.sh --release-gate` → `GOALPOST MET — all 6 manifest entries complete` (6/6, 0 remaining, 0 false completion claims). Its own negative control, `--mutate-evidence`, was re-run on the same commit and reports `negative control OBSERVED in both directions (6 pass, 0 fail)` — it detects a stripped declaration, an unregistered gate (the #461 defect), and an invariant violated in either direction. Four of the six issues are CLOSED with per-criterion evidence (#407, #417, #457, #461). **#375 and #390 remain OPEN on purpose:** their gates are registered, green and control-observed, which is what this release's exit criterion measures, but each has acceptance criteria that did not ship — #390 defers a host free-memory floor and packet-driven per-phase overrides to a Phase 2 its own code comment names (`marathon_drive.py:1253`), and #375's shipped three-state `unverifiable` verdict deliberately contradicts its criteria 1 and 5 because implementing them literally took `relay-self-sufficiency.sh` from 4/0 to 0/4 on a working machine. Both are audited per-criterion on the issues. Closing them silently would have repeated exactly the #401→#461 mistake this release exists to catch.
RELEASES.md-104-Codename: Litmus
RELEASES.md-105-Description: Make the checks capable of failing. Every gate in the Litmus manifest is shown to report red against a real defect, or is explicitly downgraded to advisory — a check never observed failing is not evidence (#419). Ordered first because it is the release that makes the next one measurable. It is also what the self-improvement chain (#431) is blocked on: a Reviewer is a gate, so #419 applies to it, and its qualification gate is currently un-runnable (#428) and has only ever been measured once (#429).
RELEASES.md-106-Exit criterion: `bash test/litmus-release.sh --release-gate` exits 0. Red today by design; turning it green is what "done" means. Its own negative control is `--mutate-evidence`, which must detect a stripped declaration and an unregistered gate. NOTE the honest limit, stated in that file: the audit proves registration, declaration shape and the absence of false completion claims. It does NOT prove a control was truly observed, because `gate_inventory.py` reads a declaration authored by the same person who wrote the gate. Recorded execution of each control is deliberately out of scope for this release.
RELEASES.md-107-Manifest: FROZEN 2026-08-08 — #375, #390, #407, #417, #457, #461. Six named decision gates, a fixed denominator rather than a percentage. "Every gate" was unshippable prose: `gate_inventory.py` reports 152 of 158 gates with no declared control, and retrofitting them is explicitly out of scope. Adding an entry is a RE-SCOPE, not a bugfix: a mid-release discovery joins only if it makes the exit command fail or falsifies a named invariant, has a reproducer demonstrating that, and the operator explicitly swaps out an existing entry or accepts a date slip. Discovery is not admission — #457, #460 and #461 were all filed while executing Litmus, which is what an unfrozen boundary looks like.
RELEASES.md-108-GH_URL:
--
RELEASES.md-113-
RELEASES.md-114-Release: 0.3.0
RELEASES.md-115-Iterations: 0.3.0-0.3.4
RELEASES.md-116-Status: Release Candidate — exit criterion MET 2026-08-11 on `development`
RELEASES.md-117-Target Date: 2026-10-10
RELEASES.md:118:RC evidence: `bash test/nightwatch-release.sh --release-gate` → `GOALPOST MET — all 8 manifest entries complete and every lifecycle case executes green` (manifest 8/8, lifecycle 5 passing / 0 failing / 0 NOT COVERED). Its own negative control, `--mutate-evidence`, reports 34/0 and `negative control OBSERVED in both directions`. Every manifest entry carries a recorded pre-fix control under `test/baselines/`, not an assertion that one happened. **Two entries are honest about their limits and are worth reading before signing off:** #358's Phase 2 is a *disposition* that needs a real CI failure carrying the new instrumentation, and its capture doc forbids pre-committing one — so Phase 1 shipped and Phase 2 is blocked on an observation, not on work; and #354's membership is Phase 1 only, which was delivered by #376/#448 rather than by this release, recorded as such rather than rebuilt. **#426's outcome inverted its own diagnosis:** a factorial control showed the leak survives with worktree isolation OFF, so teardown was exonerated and the real cause was the GH-375 auth pre-flight running with the caller's CWD, outside containment. **Twelve open Nightwatch-milestone issues remain and gate nothing**, per this block's own "a release is not its milestone" rule.
RELEASES.md-119-Codename: Nightwatch
RELEASES.md:120:Description: An unattended marathon against a real target repo survives, records, and recovers. Before dispatching work, it proves the target can accept the harness write-set and preserves the local-state contract, so hostile ignore rules or linked worktrees fail clearly rather than silently splitting, leaking, or losing the run. GH-354 Phase 1 is an early Nightwatch containment prerequisite: restore clone-wide driver exclusion for linked worktrees and prove all driver pairs fail closed. A run interrupted, killed at its cap, or panicking the host leaves a durable record and recovery path instead of a clean tree full of ungated commits. Depends on Litmus. The same durability work is what makes a reflection corpus trustworthy (#431): a run with no record is invisible to any later pass over it, and the loop's own evidence has never survived a reboot (#430).
RELEASES.md-121-Exit criterion: `bash test/nightwatch-release.sh --release-gate` exits 0. **BUILT 2026-08-11 and red by design**, exactly as Litmus's was; turning it green is what "done" means. It has two halves because a metadata audit cannot answer this release's question. Half A audits the frozen manifest — each entry's gate EXISTS, is REGISTERED in `validate.sh` (a gate absent from TESTS is indistinguishable from one that passes — the #461 defect), and has a RECORDED control under `test/baselines/`; it also cross-checks that this list and the `Manifest:` line below agree, since a boundary that disagrees with itself is not frozen. Half B **executes** the lifecycle cases rather than auditing them, delegating to the suites that already drive real children and kill them rather than growing a second driver fixture here. Status on 2026-08-11: **manifest 8/8 complete; lifecycle 5 passing, 0 NOT COVERED — GOALPOST MET.** The last gap was the hostile-target write-set case, closed by #514, which was filed while executing this release and deliberately NOT admitted to the manifest (discovery is not admission); it belongs to the lifecycle list because the exit criterion always named that case — what was missing was a suite driving it. That lane also corrected its own premise: the pre-fix tree does not dispatch a turn first, it dies at the render's `git add` with an unhandled `CalledProcessError` traceback, so the discriminating assertion is the absence of that traceback rather than the absence of a dispatch. Its own negative control is `--mutate-evidence` (34/0), which unregisters a gate and deletes a recorded control in a fixture copy, requires both to be detected, and re-checks the unmutated inputs green in the same run so an always-red detector cannot pass for one. Honest limit, inherited from Litmus: Half A reads a declaration and a filename and cannot know a recorded control was honestly recorded; Half B is what narrows that, and is why this criterion is a command that kills children rather than a checklist.
RELEASES.md:122:Manifest: FROZEN 2026-08-11 — #408, #409, #426, #388, #387, #384, #358, plus #354 Phase 1. Eight named entries, a fixed denominator rather than a percentage. The first six were moved out of Litmus on 2026-08-08 after a codex+agy consult; #387 and #384 are added at freeze time because the exit criterion above already names their cases — it requires a cap-killed child and a restarted recovery, and nothing else in the milestone supplies either. **The milestone is not the manifest.** Nightwatch's milestone holds 18 open issues; the twelve not listed here (#376, #378, #379, #380, #382, #386, #391, #392, #402, #467, #491, and anything filed during execution) are backlog worked inside the 0.3.0-0.3.4 band, and none of them gates the release. Adding an entry is a RE-SCOPE, not a bugfix, under the same admission rule Litmus used: a mid-release discovery joins only if it makes the exit command fail or falsifies a named invariant, has a reproducer demonstrating that, and the operator explicitly swaps out an existing entry or accepts a date slip. Discovery is not admission.
RELEASES.md-123-GH_URL:
RELEASES.md-124-Milestone: Nightwatch
RELEASES.md-125-Front-door reviewed: No
RELEASES.md-126-Shakedown reviewed: No
RELEASES.md-127-License file: Yes
--
RELEASES.md-129-Release: 0.4.0
RELEASES.md-130-Iterations: 0.4.0-0.4.4
RELEASES.md-131-Status: Draft
RELEASES.md-132-Target Date: 2026-11-14
RELEASES.md-133-Codename: Plumbline
RELEASES.md:134:Description: Assisted reflection and a bounded self-improvement loop, measured before either is trusted. The reflection pipeline turns durable Nightwatch records into proposals (`proposals-sink.sh` gains its first production caller) and is graded against external ground truth — the 49 human-filed findings from the two rebalance-OS marathons (#405/#406) — for recall and precision. Ships a committed benchmark and a recorded go/no-go; "not worth automating yet" is a passing result, per #431's own Phase 2 exit criterion. Operator sign-off stays manual. Depends on Nightwatch.
RELEASES.md-135-GH_URL: [GH 431](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/431)
RELEASES.md-136-Milestone: Plumbline
RELEASES.md-137-Front-door reviewed: No
RELEASES.md-138-Shakedown reviewed: No
RELEASES.md-139-License file: Yes
--
test/gh388-run-log-durability.sh-22-# shellcheck source=/dev/null
test/gh388-run-log-durability.sh-23-source "$HERE/_setup.sh" gh388-run-log-durability
test/gh388-run-log-durability.sh-24-PY="${PYTHON:-python3}"
test/gh388-run-log-durability.sh-25-
test/gh388-run-log-durability.sh-26-# ---------------------------------------------------------------------------
test/gh388-run-log-durability.sh:27:# Part A — the non-durable registry is ONE file, read by BOTH lanes
test/gh388-run-log-durability.sh-28-# ---------------------------------------------------------------------------
test/gh388-run-log-durability.sh-29-echo "-- A: one registry, two readers, same verdict"
test/gh388-run-log-durability.sh-30-
test/gh388-run-log-durability.sh:31:CONF="$ROOT_DIR/relay-automation/non-durable-log-roots.conf"
test/gh388-run-log-durability.sh-32-[ -f "$CONF" ] && pass "the registry file exists ($(basename "$CONF"))" \
test/gh388-run-log-durability.sh:33:               || fail "GH-388 criterion 5: no single place states the non-durable locations"
test/gh388-run-log-durability.sh-34-
test/gh388-run-log-durability.sh-35-# shellcheck source=/dev/null
test/gh388-run-log-durability.sh-36-source "$ROOT_DIR/relay-automation/durable-log-lib.sh"
test/gh388-run-log-durability.sh-37-
test/gh388-run-log-durability.sh-38-# Both readers must agree. Two hardcoded lists would satisfy "stated in one place" on paper and drift
--
test/gh388-run-log-durability.sh-51-[ -z "$disagreed" ] \
test/gh388-run-log-durability.sh-52-  && pass "the Bash and Python readers agree on every probe path" \
test/gh388-run-log-durability.sh-53-  || fail "GH-388: the two lanes disagree about durability —$disagreed"
test/gh388-run-log-durability.sh-54-
test/gh388-run-log-durability.sh-55-xyz_path_is_durable "$ROOT_DIR/relay-system/logs/a.log" \
test/gh388-run-log-durability.sh:56:  && pass "a path inside the repo's own relay-system is durable" \
test/gh388-run-log-durability.sh:57:  || fail "the repo's own transcript root was classified non-durable"
test/gh388-run-log-durability.sh-58-xyz_path_is_durable /tmp/whatever \
test/gh388-run-log-durability.sh-59-  && fail "/tmp was classified DURABLE — the registry is not being read" \
test/gh388-run-log-durability.sh:60:  || pass "/tmp is classified non-durable"
test/gh388-run-log-durability.sh-61-
test/gh388-run-log-durability.sh-62-# The registry is data, not code: adding a line must change the verdict. Without this the conf file
test/gh388-run-log-durability.sh-63-# could be a decorative artifact while the real list lives in the readers.
test/gh388-run-log-durability.sh-64-TMPCONF="$WORK/conf-probe"
test/gh388-run-log-durability.sh-65-mkdir -p "$TMPCONF/relay-automation"
test/gh388-run-log-durability.sh-66-cp "$ROOT_DIR/relay-automation/durable-log-lib.sh" "$TMPCONF/relay-automation/"
test/gh388-run-log-durability.sh:67:printf '/an-invented-volatile-root\n' >"$TMPCONF/relay-automation/non-durable-log-roots.conf"
test/gh388-run-log-durability.sh-68-probe="$(cd "$TMPCONF" && bash -c 'source relay-automation/durable-log-lib.sh; xyz_non_durable_reason /an-invented-volatile-root/x')"
test/gh388-run-log-durability.sh-69-[ "$probe" = "/an-invented-volatile-root" ] \
test/gh388-run-log-durability.sh-70-  && pass "the registry is genuinely read at runtime (an invented entry changes the verdict)" \
test/gh388-run-log-durability.sh-71-  || fail "adding an entry to the registry changed nothing — the real list is hardcoded somewhere (got: '$probe')"
test/gh388-run-log-durability.sh-72-

exec
/bin/zsh -lc "nl -ba test/gh388-run-log-durability.sh | sed -n '27,150p'
nl -ba relay-automation/durable-log-lib.sh
nl -ba utils/py/rtl.py | sed -n '1,180p'
nl -ba test/baselines/GH-358-negative-control.md | sed -n '34,90p'
nl -ba test/gh358-lock-instrumentation.sh | sed -n '1,220p'" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-69972-gxaghv_u
 succeeded in 0ms:
    27	# Part A — the non-durable registry is ONE file, read by BOTH lanes
    28	# ---------------------------------------------------------------------------
    29	echo "-- A: one registry, two readers, same verdict"
    30	
    31	CONF="$ROOT_DIR/relay-automation/non-durable-log-roots.conf"
    32	[ -f "$CONF" ] && pass "the registry file exists ($(basename "$CONF"))" \
    33	               || fail "GH-388 criterion 5: no single place states the non-durable locations"
    34	
    35	# shellcheck source=/dev/null
    36	source "$ROOT_DIR/relay-automation/durable-log-lib.sh"
    37	
    38	# Both readers must agree. Two hardcoded lists would satisfy "stated in one place" on paper and drift
    39	# in practice — this is what keeps the claim true, and it is the assertion that fails first if
    40	# someone later inlines a copy into either lane.
    41	disagreed=""
    42	for p in /tmp/x.log /private/tmp/x /var/tmp/y /dev/shm/z "$ROOT_DIR/relay-system/logs/a.log" /usr/local/share/keepme; do
    43	  bash_reason="$(xyz_non_durable_reason "$p")"
    44	  py_reason="$("$PY" -c "
    45	import sys; sys.path.insert(0, '$ROOT_DIR/utils/py'); import rtl
    46	print(rtl.non_durable_reason('$p'))")"
    47	  bash_verdict=$([ -n "$bash_reason" ] && echo NON-DURABLE || echo DURABLE)
    48	  py_verdict=$([ -n "$py_reason" ] && echo NON-DURABLE || echo DURABLE)
    49	  [ "$bash_verdict" = "$py_verdict" ] || disagreed="$disagreed $p(bash=$bash_verdict,py=$py_verdict)"
    50	done
    51	[ -z "$disagreed" ] \
    52	  && pass "the Bash and Python readers agree on every probe path" \
    53	  || fail "GH-388: the two lanes disagree about durability —$disagreed"
    54	
    55	xyz_path_is_durable "$ROOT_DIR/relay-system/logs/a.log" \
    56	  && pass "a path inside the repo's own relay-system is durable" \
    57	  || fail "the repo's own transcript root was classified non-durable"
    58	xyz_path_is_durable /tmp/whatever \
    59	  && fail "/tmp was classified DURABLE — the registry is not being read" \
    60	  || pass "/tmp is classified non-durable"
    61	
    62	# The registry is data, not code: adding a line must change the verdict. Without this the conf file
    63	# could be a decorative artifact while the real list lives in the readers.
    64	TMPCONF="$WORK/conf-probe"
    65	mkdir -p "$TMPCONF/relay-automation"
    66	cp "$ROOT_DIR/relay-automation/durable-log-lib.sh" "$TMPCONF/relay-automation/"
    67	printf '/an-invented-volatile-root\n' >"$TMPCONF/relay-automation/non-durable-log-roots.conf"
    68	probe="$(cd "$TMPCONF" && bash -c 'source relay-automation/durable-log-lib.sh; xyz_non_durable_reason /an-invented-volatile-root/x')"
    69	[ "$probe" = "/an-invented-volatile-root" ] \
    70	  && pass "the registry is genuinely read at runtime (an invented entry changes the verdict)" \
    71	  || fail "adding an entry to the registry changed nothing — the real list is hardcoded somewhere (got: '$probe')"
    72	
    73	# ---------------------------------------------------------------------------
    74	# Part B — rtl_default_log refuses instead of silently relocating
    75	# ---------------------------------------------------------------------------
    76	echo "-- B: a misconfigured archive root refuses, rather than quietly writing to volatile storage"
    77	
    78	# XYZ_ARCHIVE_ROOT that is not a git repo → rtl_transcript_root returns nothing. Pre-fix, BOTH lanes
    79	# answered with a $TMPDIR path and said nothing at all.
    80	BADARCH="$WORK/not-a-git-repo"
    81	mkdir -p "$BADARCH"
    82	
    83	set +e
    84	py_out="$(XYZ_ARCHIVE_ROOT="$BADARCH" "$PY" -c "
    85	import sys; sys.path.insert(0, '$ROOT_DIR/utils/py'); import rtl
    86	print(rtl.rtl_default_log('$A', 'agy-turn', 'T-1'))" 2>&1)"
    87	py_rc=$?
    88	set -e
    89	if [ "$py_rc" -ne 0 ]; then
    90	  pass "python lane REFUSES on an unusable archive root (exit $py_rc)"
    91	else
    92	  fail "GH-388: python lane returned a path instead of refusing — got: $py_out"
    93	fi
    94	case "$py_out" in
    95	  *"$WORK"*|*TMPDIR*|*/tmp/*|*/var/folders/*)
    96	    # Only a failure if it was RETURNED as the transcript path; in the refusing case the temp path
    97	    # must not appear as an answer at all.
    98	    [ "$py_rc" -eq 0 ] && fail "GH-388: the returned transcript path is in volatile storage: $py_out" ;;
    99	esac
   100	case "$py_out" in
   101	  *"not a git repo"*|*"XYZ_ARCHIVE_ROOT"*)
   102	    pass "the refusal names WHY the root did not resolve (the resolver's stderr is no longer swallowed)" ;;
   103	  *) fail "the refusal did not explain the cause — got: $py_out" ;;
   104	esac
   105	
   106	set +e
   107	bash_out="$(XYZ_ARCHIVE_ROOT="$BADARCH" bash -c "
   108	source '$ROOT_DIR/relay-automation/relay-turn-lib.sh' >/dev/null 2>&1
   109	rtl_default_log '$A' agy-turn T-1" 2>&1)"
   110	bash_rc=$?
   111	set -e
   112	[ "$bash_rc" -ne 0 ] \
   113	  && pass "bash lane REFUSES on the same input (exit $bash_rc)" \
   114	  || fail "GH-388: bash lane returned '$bash_out' instead of refusing — the lanes disagree"
   115	
   116	# The other direction, and it is load-bearing: a WORKING configuration must still return a path.
   117	# A "fix" that refuses everything passes every assertion above and breaks every turn in the fleet.
   118	set +e
   119	ok_out="$("$PY" -c "
   120	import sys; sys.path.insert(0, '$ROOT_DIR/utils/py'); import rtl
   121	print(rtl.rtl_default_log('$A', 'agy-turn', 'T-1'))" 2>/dev/null)"
   122	ok_rc=$?
   123	set -e
   124	if [ "$ok_rc" -eq 0 ] && [ -n "$ok_out" ]; then
   125	  pass "a healthy default (no XYZ_ARCHIVE_ROOT) still resolves: ${ok_out#"$A"/}"
   126	else
   127	  fail "the durability guard broke the normal path — rc=$ok_rc out=$ok_out"
   128	fi
   129	case "$ok_out" in
   130	  "$A"/relay-system/*) pass "and it resolves under the repo's own relay-system, unchanged" ;;
   131	  *) fail "the healthy path moved: $ok_out" ;;
   132	esac
   133	
   134	# ---------------------------------------------------------------------------
   135	# Part C — a KILLED phase leaves a content-bearing record
   136	# ---------------------------------------------------------------------------
   137	echo "-- C: kill a phase mid-run; assert what survives"
   138	
   139	# A phase that never finishes. The stub blocks, the driver is signalled, and the question is whether
   140	# anything durable is left behind naming what was happening.
   141	DRIVE="$ROOT_DIR/relay-automation/marathon-drive.sh"
   142	printf 'STATUS: Open\n# relay body\n' >"$A/relay.md"
   143	printf '.tick/\n' >"$A/.gitignore"
   144	git -C "$A" add relay.md .gitignore >/dev/null 2>&1
   145	git -C "$A" commit -q -m "seed" >/dev/null 2>&1
   146	mkdir -p "$A/PROJECT/2-WORKING"
   147	printf '# brief\n\nDo the thing.\n' >"$A/PROJECT/2-WORKING/brief.md"
   148	
   149	HANG="$WORK/hang-agent"
   150	cat >"$HANG" <<'HANG_EOF'
     1	#!/usr/bin/env bash
     2	# durable-log-lib.sh — GH-388: is this path somewhere evidence will still be after a reboot?
     3	#
     4	# The registry itself is NOT in this file. It is `relay-automation/non-durable-log-roots.conf`, read
     5	# at runtime, and `utils/py/rtl.py::path_is_durable` reads the SAME file — so the two lanes cannot
     6	# disagree, and there is no second list to go stale. `test/gh388-run-log-durability.sh` asserts both
     7	# readers return the same verdict for the same paths, which is the only thing that keeps that claim
     8	# true. Same shape as driver-lock-lib.sh (GH-448), for the same reason: a consumer that inlines its
     9	# own version of this decision is the defect the shared file exists to kill.
    10	#
    11	# API:
    12	#   xyz_non_durable_conf                — prints the path to the registry file
    13	#   xyz_path_is_durable <path>          — exit 0 if durable, 1 if it resolves into a non-durable root
    14	#   xyz_non_durable_reason <path>       — prints the matched prefix (empty if durable)
    15	set -u
    16	
    17	_XYZ_DURABLE_LIB_HOME="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
    18	
    19	xyz_non_durable_conf() {
    20	  printf '%s/relay-automation/non-durable-log-roots.conf' "$_XYZ_DURABLE_LIB_HOME"
    21	}
    22	
    23	# Resolve a path to its REAL location without requiring the path itself to exist yet — the log file
    24	# is usually about to be created. Walk up to the nearest existing ancestor, canonicalize THAT, then
    25	# re-append the tail. Canonicalizing matters: on macOS /tmp is a symlink to /private/tmp, so a
    26	# logical-form check alone lets the same directory through under its other name.
    27	_xyz_realish_path() {
    28	  local p="$1" tail="" base
    29	  case "$p" in /*) ;; *) p="$PWD/$p" ;; esac
    30	  while [ -n "$p" ] && [ "$p" != "/" ] && [ ! -e "$p" ]; do
    31	    base="$(basename "$p")"
    32	    tail="${base}${tail:+/$tail}"
    33	    p="$(dirname "$p")"
    34	  done
    35	  if [ -d "$p" ]; then
    36	    p="$(cd "$p" 2>/dev/null && pwd -P)" || p="$1"
    37	  fi
    38	  printf '%s' "${p%/}${tail:+/$tail}"
    39	}
    40	
    41	xyz_non_durable_reason() {  # <path> — prints the matched non-durable prefix, or nothing
    42	  local path real conf line prefix
    43	  path="${1:-}"
    44	  [ -n "$path" ] || return 0
    45	  real="$(_xyz_realish_path "$path")"
    46	  conf="$(xyz_non_durable_conf)"
    47	
    48	  # TMPDIR is a value, not a literal a file can hold — see the conf's own note. Checked first so a
    49	  # relocated TMPDIR is caught even when it points somewhere the static list never anticipated.
    50	  if [ -n "${TMPDIR:-}" ]; then
    51	    prefix="$(_xyz_realish_path "${TMPDIR%/}")"
    52	    if [ -n "$prefix" ] && { [ "$real" = "$prefix" ] || case "$real" in "$prefix"/*) true ;; *) false ;; esac; }; then
    53	      printf '%s' "$prefix"
    54	      return 0
    55	    fi
    56	  fi
    57	
    58	  [ -f "$conf" ] || return 0
    59	  while IFS= read -r line; do
    60	    line="${line%%#*}"
    61	    line="${line#"${line%%[![:space:]]*}"}"
    62	    line="${line%"${line##*[![:space:]]}"}"
    63	    [ -n "$line" ] || continue
    64	    prefix="${line%/}"
    65	    if [ "$real" = "$prefix" ] || case "$real" in "$prefix"/*) true ;; *) false ;; esac; then
    66	      printf '%s' "$prefix"
    67	      return 0
    68	    fi
    69	  done <"$conf"
    70	  return 0
    71	}
    72	
    73	xyz_path_is_durable() {  # <path> — exit 0 durable, 1 non-durable
    74	  local matched
    75	  matched="$(xyz_non_durable_reason "${1:-}")"
    76	  [ -z "$matched" ]
    77	}
     1	import atexit
     2	import os
     3	import shlex
     4	import subprocess
     5	import tempfile
     6	import sys
     7	
     8	# GH-375 — agy's auth pre-flight cannot decide on exit status alone. `agy whoami` EXITS 0 while
     9	# failing to run at all when there is no TTY ("CLI error: bubbletea: error opening TTY: ... open
    10	# /dev/tty: device not configured"), and every marathon or driven relay turn is headless, so that is
    11	# the NORMAL path under automation rather than an edge case. Both callers (agy-turn.py, consult.py)
    12	# had the same shape and the same hole, so the verdict lives here once rather than in two copies
    13	# that can drift.
    14	#
    15	# Matched as line PREFIXES, not as a bare "error" substring anywhere in the output. `whoami` prints
    16	# ACCOUNT IDENTITY on success — a substring test would fail any lane whose handle, org, or banner
    17	# happens to contain "error", and a false failure stops the run outright, which is a worse outcome
    18	# than the bug being fixed. The TTY signature is matched separately: it is the exact shape the issue
    19	# reports and it does not necessarily carry an error prefix.
    20	# GH-375 follow-up. AGY_AUTH_TIMEOUT_S defaulted to 5 while `agy whoami` cost 1.3-2.3s idle on the
    21	# reference machine — under 2x headroom, and concurrent load closed it twice. The second time was AFTER
    22	# the timeout branch was taught to reclassify a TTY-diagnosed timeout as unverifiable: the probe was
    23	# killed before it could FLUSH its diagnostic, so the capture was empty, the reclassification had
    24	# nothing to match on, and the lane was blocked anyway. That flush race was predicted by one reviewer
    25	# and dismissed by another (and by me) as bounded; it then fired in the next consult and cost the agy
    26	# seat. Observed, so no longer a judgement call.
    27	#
    28	# 20s is chosen against the measurement, not by feel: ~9x the worst idle probe, which leaves room for
    29	# the load that closed a 2x margin. The cost is bounded and lands only on a genuine interactive-login
    30	# hang, which now takes 20s to reject instead of 5 — a rare path, and rejecting it late is cheaper than
    31	# blocking a working lane. Same reasoning as GH-457's tiers: size a cap against what the thing actually
    32	# costs, not against a number that looks tidy.
    33	AGY_AUTH_TIMEOUT_DEFAULT_S = 20
    34	WORST_OBSERVED_WHOAMI_S = 2.3   # 1.3 / 1.9 / 2.3 measured idle, 2026-08-09
    35	
    36	AGY_AUTH_ERROR_PREFIXES = ("cli error:", "error:", "panic:", "fatal:")
    37	AGY_AUTH_TTY_MARKERS = ("could not open tty", "error opening tty")
    38	
    39	
    40	def agy_auth_output_verdict(out_file):
    41	    """Classify agy's own probe output. Returns (severity, message).
    42	
    43	    severity is one of:
    44	      ""              — nothing suspicious; treat the probe as passed.
    45	      "unverifiable"  — the probe COULD NOT RUN, so it established nothing either way. Report it
    46	                        loudly; do NOT fail the lane on it.
    47	      "failed"        — the probe ran and agy reported an error. Fail the lane.
    48	
    49	    THE THIRD STATE IS THE WHOLE POINT, and it was learned the expensive way. GH-375's suggested fix
    50	    was to treat the TTY error as a failed probe and stop the turn. That was implemented literally and
    51	    it broke the agy lane outright: test/relay-self-sufficiency.sh went 4/0 to 0/4 with `agy shim
    52	    exited 5`, on a machine where agy was signed in and working.
    53	
    54	    The measurement that settles it, taken on this repo:
    55	
    56	      * `agy whoami` cannot run headless at all. It exits 0 while printing
    57	        `CLI error: bubbletea: error opening TTY: ... /dev/tty: device not configured`.
    58	      * `agy -p` — the print mode the ACTUAL turn uses — runs headless perfectly well. The live turn
    59	        in relay-self-sufficiency.sh claims its token, writes the relay file and commits.
    60	
    61	    So a TTY error from `whoami` says nothing about whether auth works; it says this probe is the
    62	    wrong instrument in this environment. Treating it as failure converts an unmeasurable check into
    63	    a hard block on a lane that demonstrably works — strictly worse than the bug GH-375 reported,
    64	    which merely let a possibly-unauthed lane proceed. One of two working builders, stopped by its
    65	    own guard.
    66	
    67	    What GH-375 established stands and is preserved: exit status alone cannot decide this, and the
    68	    captured output must not be deleted. Those were the real defects. The inference "the probe could
    69	    not run, therefore auth is bad" is the part that does not follow.
    70	    """
    71	    try:
    72	        with open(out_file, "r", encoding="utf-8", errors="replace") as f:
    73	            output = f.read()
    74	    except OSError:
    75	        return ("unverifiable", "the probe produced no readable output")
    76	    # EMPTY OUTPUT IS NOT TREATED AS FAILURE, deliberately. "A probe that establishes nothing must
    77	    # not report success" is a tempting rule and it was written here first — then it failed a turn
    78	    # within minutes: test/gh410-containment-advisory.sh's agy stub prints nothing for `whoami`, so
    79	    # the pre-flight rejected it, the turn exited 5 before running, and a containment assertion that
    80	    # had nothing to do with auth went red. That is the false-failure direction this function's whole
    81	    # matching strategy is built to avoid, and it arrived on first contact.
    82	    #
    83	    # The asymmetry is the point: agy exiting 0 with a VISIBLE error is observed and documented
    84	    # (GH-375). Agy exiting 0 SILENTLY on success is not something this repo can rule out, and
    85	    # guessing wrong there breaks every turn in the fleet rather than one. Match the evidence that
    86	    # exists; do not infer failure from the absence of evidence. stderr is folded into this capture,
    87	    # so a real error has somewhere to appear.
    88	    for raw in output.splitlines():
    89	        line = raw.strip()
    90	        low = line.lower()
    91	        # TTY FIRST, and it must stay first: agy's TTY banner is itself prefixed `CLI error:`, so the
    92	        # error-prefix branch below would otherwise claim it and fail a lane that is perfectly fine.
    93	        if any(m in low for m in AGY_AUTH_TTY_MARKERS):
    94	            return ("unverifiable", f"agy could not run headless, so auth was not verified: {line}")
    95	        if any(low.startswith(p) for p in AGY_AUTH_ERROR_PREFIXES):
    96	            return ("failed", f"agy reported an error: {line}")
    97	    return ("", "")
    98	
    99	
   100	def agy_auth_timeout_verdict(out_file):
   101	    """Classify a probe that TIMED OUT. Returns (severity, message) — never "".
   102	
   103	    A separate function from agy_auth_output_verdict on purpose. That one reads an output stream from
   104	    a process that EXITED, where "nothing suspicious" legitimately means pass. A timeout has no exit
   105	    status to interpret, and silence there is not reassurance — so this function never returns the
   106	    pass verdict, and reusing the other one here would have converted a hung probe into a green one.
   107	
   108	    GH-375 follow-up. The three-state fix covered `whoami` EXITING with a TTY error. It did not cover
   109	    the probe blowing its timeout, which still went straight to fatal — and that is the branch that
   110	    actually fired: a /consult on 2026-08-09 lost its agy seat to
   111	
   112	        consult: agy auth pre-flight timed out after 5s; likely expired auth opening an interactive
   113	                 login. Run `agy login` in a normal terminal, then retry.
   114	
   115	    on a machine where, measured in the same minute, `agy whoami` printed the TTY error and `agy -p`
   116	    (what the turn actually uses) answered correctly. A false block, from the guard, on a working lane
   117	    — the same failure direction GH-375's own fix was written to avoid, one branch over.
   118	
   119	    The rule: reclassify ONLY on positive evidence of the TTY cause. If the captured output already
   120	    says agy could not open a TTY, the timeout carries no more information about auth than the fast
   121	    failure did — on a platform where `whoami` can never succeed headlessly, a timeout is just a
   122	    slower spelling of the same thing. Anything else — an interactive login prompt, an unfamiliar
   123	    error, or NO output at all — stays fatal, which keeps the branch's original purpose intact for a
   124	    genuine hang on a login prompt.
   125	
   126	    Deliberately narrower than "a timeout is unverifiable". That broader rule would also swallow the
   127	    real hang this branch exists to catch, and silence is exactly the shape a login prompt waiting on
   128	    stdin produces.
   129	    """
   130	    try:
   131	        with open(out_file, "r", encoding="utf-8", errors="replace") as f:
   132	            output = f.read()
   133	    except OSError:
   134	        output = ""
   135	    for raw in output.splitlines():
   136	        line = raw.strip()
   137	        if any(m in line.lower() for m in AGY_AUTH_TTY_MARKERS):
   138	            return ("unverifiable",
   139	                    "agy could not open a TTY and then exceeded the probe timeout, so auth was not "
   140	                    f"verified (the timeout is the same TTY failure, slower): {line}")
   141	    return ("failed", "the probe timed out with no TTY diagnostic, which is the shape of a genuine "
   142	                      "hang on an interactive login prompt")
   143	
   144	
   145	def split_allow_paths(allow_paths):
   146	    paths = []
   147	    for path in (allow_paths or "").split(","):
   148	        path = path.strip()
   149	        if path:
   150	            paths.append(path)
   151	    return paths
   152	
   153	def claim_paths_for_turn(root, relay_file, allow_paths):
   154	    # Resolve both through realpath before computing the relative path. `root` and `relay_file` can
   155	    # come from different resolution paths — e.g. root via resolve_turn_root's `git rev-parse
   156	    # --show-toplevel` fallback, which returns the PHYSICAL path, vs. a caller-supplied relay_file
   157	    # still in macOS's unresolved /var-or-/tmp-symlink form — and a symlink-form mismatch here makes
   158	    # relpath climb all the way out to an unrelated "../../.."-prefixed path instead of a clean
   159	    # repo-relative one (the same GH-51 class of bug relay-turn-lib.sh's rtl_init already guards
   160	    # against on the bridged/bash side; this native Python computation had no equivalent). (GH-296)
   161	    paths = [os.path.relpath(os.path.realpath(relay_file), os.path.realpath(root))]
   162	    paths.extend(split_allow_paths(allow_paths))
   163	    return paths
   164	
   165	def resolve_tick_repo_root(root):
   166	    return os.environ.get("TICK_REPO_ROOT", root)
   167	
   168	def resolve_turn_root(explicit_root, xyz_root):
   169	    # Mirror the Bash shims' ROOT default (codex-turn.sh): an explicit override wins, else the
   170	    # CWD's git toplevel — so a shim invoked from inside a same-repo vendored .xyz/ (relay-xyz's
   171	    # documented `cd $HARNESS`) roots at the TRUE target repo, not xyz_root (the harness's own
   172	    # directory on disk, which can differ from the git toplevel in that layout even though both
   173	    # paths belong to the same git repo) — else xyz_root as a last resort off a git repo. (GH-296)
   174	    #
   175	    # GH-417: --show-toplevel returns the PHYSICAL path, so ROOT can differ in symlink form from a
   176	    # relay-file path the caller built from its own $PWD. That is survivable, not accidental:
   177	    # relay-turn-lib.sh's rtl_init canonicalizes both sides before stripping (GH-261, 312a2c3), and
   178	    # claim_paths_for_turn above does the same natively. Read the "caught live" warning at
   179	    # relay-turn-lib.sh's GH-160 collapse as scoped to that collapse — it is not an argument against
   180	    # this default. Pinned by test/gh417-turn-root-symlink-prefix.sh, whose control shows the exit-6
    34	## Phase 2 is BLOCKED ON AN OBSERVATION, not on work
    35	
    36	Phase 2 is "disposition, on that evidence" — raise the bound, retry the assertion, or exclude with
    37	a stated reason. That decision needs a real CI failure carrying the new instrumentation, and the
    38	capture doc is explicit that it must not be pre-committed: *"a builder told which disposition to
    39	apply will produce instrumentation that agrees with the instruction."* The suite DOES run on the
    40	shared runner (`.github/workflows/ci.yml` runs the full `validate.sh` minus two documented skips,
    41	and `xyz-completion.sh` is not one of them), so the exposure is live — it simply has not fired
    42	since the instrumentation landed. Choosing a disposition now would be guessing with extra steps.
     1	#!/usr/bin/env bash
     2	# GH-358: prove the concurrent append diagnostic distinguishes a lost record from lock starvation.
     3	set -uo pipefail
     4	
     5	HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
     6	ROOT="$(cd "$HERE/.." && pwd)"
     7	XYZ_TEST="$HERE/xyz-completion.sh"
     8	WORK="$(mktemp -d "${TMPDIR:-/tmp}/gh358-lock-instrumentation.XXXXXX")"
     9	trap 'rm -rf "$WORK"' EXIT
    10	
    11	PASS=0; FAIL=0
    12	pass() { echo "  PASS: $*"; PASS=$((PASS+1)); }
    13	fail() { echo "  FAIL: $*" >&2; FAIL=$((FAIL+1)); }
    14	require_log() {
    15	  local log="$1" text="$2" description="$3"
    16	  grep -Fq "$text" "$log" && pass "$description" || fail "$description (missing: $text)"
    17	}
    18	
    19	echo "== test: gh358-lock-instrumentation =="
    20	
    21	# Control 1: all appenders exit 0, then one record is deliberately removed.  This must identify a
    22	# successful writer whose record vanished, not report starvation or a generic count mismatch.
    23	clobber_dir="$WORK/clobber"
    24	mkdir -p "$clobber_dir"
    25	clobber_log="$WORK/clobber.log"
    26	if TMPDIR="$clobber_dir" XYZ_COMPLETION_TEST_CLOBBER_SESSION_ID=conc-1 bash "$XYZ_TEST" >"$clobber_log" 2>&1; then
    27	  fail "clobbered-record control unexpectedly passed"
    28	else
    29	  pass "clobbered-record control fails as intended"
    30	fi
    31	require_log "$clobber_log" "missing sessionId=conc-1; terminal state=lock acquired, record lost" "clobber names the missing successful session"
    32	require_log "$clobber_log" "test wait=60s; writer XYZ_LOCK_WAIT_S=30s (default=30s)" "clobber reports both normal lock bounds"
    33	if grep -Fq "terminal state=lock never acquired" "$clobber_log"; then
    34	  fail "clobber is not mislabeled as lock starvation"
    35	else
    36	  pass "clobber remains distinct from starvation"
    37	fi
    38	echo "  clobber diagnostic (observed failure):"
    39	grep -F "terminal state=" "$clobber_log" | head -n 1 | sed 's/^/    /'
    40	
    41	# Control 2: hold x4's lock while the writer has a one-second bound.  The outer test wait stays at
    42	# 60 seconds, so the output must attribute the failure to the writer bound rather than the test wait.
    43	starve_dir="$WORK/starve"
    44	mkdir -p "$starve_dir"
    45	starve_log="$WORK/starve.log"
    46	TMPDIR="$starve_dir" XYZ_COMPLETION_WRITER_LOCK_WAIT_S=1 bash "$XYZ_TEST" >"$starve_log" 2>&1 &
    47	test_pid=$!
    48	workdir=""
    49	for _ in $(seq 1 100); do
    50	  workdir="$(sed -n 's/^  workdir: //p' "$starve_log" | head -n 1)"
    51	  [ -n "$workdir" ] && break
    52	  sleep 0.05
    53	done
    54	
    55	if [ -z "$workdir" ]; then
    56	  fail "starvation control did not expose its temporary work directory"
    57	  wait "$test_pid" 2>/dev/null || true
    58	else
    59	  sleep 20 &
    60	  holder_pid=$!
    61	  mkdir "$workdir/x4.json.lock"
    62	  printf '%s\n' "$holder_pid" > "$workdir/x4.json.lock/pid"
    63	  wait "$test_pid"; starve_rc=$?
    64	  kill "$holder_pid" 2>/dev/null || true
    65	  wait "$holder_pid" 2>/dev/null || true
    66	  [ "$starve_rc" -ne 0 ] && pass "starved-appender control fails as intended" || fail "starved-appender control unexpectedly passed"
    67	fi
    68	
    69	require_log "$starve_log" "terminal state=lock never acquired" "starvation identifies the terminal lock state"
    70	require_log "$starve_log" "writer XYZ_LOCK_WAIT_S=1s exhausted" "starvation identifies the exhausted writer bound"
    71	require_log "$starve_log" "test wait=60s; writer XYZ_LOCK_WAIT_S=1s (default=30s)" "starvation reports both effective lock bounds"
    72	if grep -Fq "terminal state=lock acquired, record lost" "$starve_log"; then
    73	  fail "starvation is not mislabeled as a lost record"
    74	else
    75	  pass "starvation remains distinct from a lost record"
    76	fi
    77	echo "  starvation diagnostic (observed failure):"
    78	grep -F "terminal state=" "$starve_log" | head -n 1 | sed 's/^/    /'
    79	
    80	echo "  gh358-lock-instrumentation: $PASS pass, $FAIL fail"
    81	[ "$FAIL" -eq 0 ] || exit 1

exec
/bin/zsh -lc 'rg -n -C 8 "Acceptance.*deviat|inside.*repo|outside.*repo|relocat|fails the run|criterion 5" PROJECT test relay-automation utils RELEASES.md | head -n 500' in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-69972-gxaghv_u
 succeeded in 0ms:
relay-automation/DUELING-CLAUDES.md-100-(Maintainer) is a session on THIS repo. Thread:
relay-automation/DUELING-CLAUDES.md-101-[relay-system/2026-06-23/codex-relay-review.md](../relay-system/2026-06-23/codex-relay-review.md).
relay-automation/DUELING-CLAUDES.md-102-
relay-automation/DUELING-CLAUDES.md-103-Because the Reporter is on a foreign CWD it must (i) read the code-under-review and the relay
relay-automation/DUELING-CLAUDES.md-104-file by **absolute path** (relative paths resolve against ITS repo, not this one); (ii) hand off
relay-automation/DUELING-CLAUDES.md-105-the lock with the env-pinned absolute `bin/tick`; and (iii) stage+commit the relay file with
relay-automation/DUELING-CLAUDES.md-106-`git -C "<xyz repo>"` — a bare `git commit` from its CWD would touch the wrong repo. On the same
relay-automation/DUELING-CLAUDES.md-107-machine the files are reachable, but that Claude session will prompt for permission to read/write
relay-automation/DUELING-CLAUDES.md:108:paths outside its own workspace — approve them (or add the xyz repo as an additional dir).
relay-automation/DUELING-CLAUDES.md-109-
relay-automation/DUELING-CLAUDES.md-110-**Step 0 — seed (run once in this repo).** `tick claim` requires `--paths` (scope the lock to the
relay-automation/DUELING-CLAUDES.md-111-relay file); compute the deadline ONCE and paste the literal — never inline `$(date)` in a loop.
relay-automation/DUELING-CLAUDES.md-112-
relay-automation/DUELING-CLAUDES.md-113-```bash
relay-automation/DUELING-CLAUDES.md-114-cd "/Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm"
relay-automation/DUELING-CLAUDES.md-115-TOKEN="DUELING-CODEX-0623"                 # fresh name per run; a done token can't reopen
relay-automation/DUELING-CLAUDES.md-116-DEADLINE=$(date -v+60M +%s)                # e.g. 1782251974 — paste this literal into BOTH loops
--
relay-automation/durable-log-lib.sh-41-xyz_non_durable_reason() {  # <path> — prints the matched non-durable prefix, or nothing
relay-automation/durable-log-lib.sh-42-  local path real conf line prefix
relay-automation/durable-log-lib.sh-43-  path="${1:-}"
relay-automation/durable-log-lib.sh-44-  [ -n "$path" ] || return 0
relay-automation/durable-log-lib.sh-45-  real="$(_xyz_realish_path "$path")"
relay-automation/durable-log-lib.sh-46-  conf="$(xyz_non_durable_conf)"
relay-automation/durable-log-lib.sh-47-
relay-automation/durable-log-lib.sh-48-  # TMPDIR is a value, not a literal a file can hold — see the conf's own note. Checked first so a
relay-automation/durable-log-lib.sh:49:  # relocated TMPDIR is caught even when it points somewhere the static list never anticipated.
relay-automation/durable-log-lib.sh-50-  if [ -n "${TMPDIR:-}" ]; then
relay-automation/durable-log-lib.sh-51-    prefix="$(_xyz_realish_path "${TMPDIR%/}")"
relay-automation/durable-log-lib.sh-52-    if [ -n "$prefix" ] && { [ "$real" = "$prefix" ] || case "$real" in "$prefix"/*) true ;; *) false ;; esac; }; then
relay-automation/durable-log-lib.sh-53-      printf '%s' "$prefix"
relay-automation/durable-log-lib.sh-54-      return 0
relay-automation/durable-log-lib.sh-55-    fi
relay-automation/durable-log-lib.sh-56-  fi
relay-automation/durable-log-lib.sh-57-
--
PROJECT/3-COMPLETED/GH-400-CAPTURE-DOC-ACCEPTANCE-FIDELITY.md-123-(or a `GH-N-` filename resolved by `--gh-issue`) and no `source:`. Under the new rule those are
PROJECT/3-COMPLETED/GH-400-CAPTURE-DOC-ACCEPTANCE-FIDELITY.md-124-invalid capture docs, so the fixtures were wrong. Narrowing the gate to frontmatter-only would have
PROJECT/3-COMPLETED/GH-400-CAPTURE-DOC-ACCEPTANCE-FIDELITY.md-125-made both pass untouched — and would have reintroduced exactly the "omit a field to dodge the check"
PROJECT/3-COMPLETED/GH-400-CAPTURE-DOC-ACCEPTANCE-FIDELITY.md-126-bypass agy found in this checker during the #413 QA round. The rule was kept; the fixtures moved.
PROJECT/3-COMPLETED/GH-400-CAPTURE-DOC-ACCEPTANCE-FIDELITY.md-127-
PROJECT/3-COMPLETED/GH-400-CAPTURE-DOC-ACCEPTANCE-FIDELITY.md-128-## How criterion 3's "fails rather than warning" is read
PROJECT/3-COMPLETED/GH-400-CAPTURE-DOC-ACCEPTANCE-FIDELITY.md-129-
PROJECT/3-COMPLETED/GH-400-CAPTURE-DOC-ACCEPTANCE-FIDELITY.md-130-No deviation is declared — every criterion is carried verbatim. (This section is deliberately *not*
PROJECT/3-COMPLETED/GH-400-CAPTURE-DOC-ACCEPTANCE-FIDELITY.md:131:titled "Acceptance — deviations from the issue": that heading now has a machine meaning, and a
PROJECT/3-COMPLETED/GH-400-CAPTURE-DOC-ACCEPTANCE-FIDELITY.md-132-section claiming deviations that do not exist is itself a divergence the checker rejects.) The one
PROJECT/3-COMPLETED/GH-400-CAPTURE-DOC-ACCEPTANCE-FIDELITY.md-133-scope reading worth stating:
PROJECT/3-COMPLETED/GH-400-CAPTURE-DOC-ACCEPTANCE-FIDELITY.md-134-
PROJECT/3-COMPLETED/GH-400-CAPTURE-DOC-ACCEPTANCE-FIDELITY.md-135-- **Divergence detected → hard fail (NOT-READY).** Not negotiable; this is the criterion.
PROJECT/3-COMPLETED/GH-400-CAPTURE-DOC-ACCEPTANCE-FIDELITY.md-136-- **Divergence *undeterminable*** (no `gh_issue`, `gh` absent, unauthenticated, offline, or the issue has
PROJECT/3-COMPLETED/GH-400-CAPTURE-DOC-ACCEPTANCE-FIDELITY.md-137-  no `## Acceptance` section) **→ report `acceptance_verified: unknown` loudly, do not block.** An
PROJECT/3-COMPLETED/GH-400-CAPTURE-DOC-ACCEPTANCE-FIDELITY.md-138-  unreachable network is not evidence of drift, and blocking on it would make every offline preflight fail.
PROJECT/3-COMPLETED/GH-400-CAPTURE-DOC-ACCEPTANCE-FIDELITY.md-139-  This is GUIDING-PRINCIPLES §8 (honest; never mask, never invent) rather than a softening of the gate.
--
utils/ate/scripts/run_variations.py-167-         running ATE against xyz-3-agents-swarm itself would wipe the harness.
utils/ate/scripts/run_variations.py-168-         Hard-refused unconditionally; --allow-destructive-reset does NOT
utils/ate/scripts/run_variations.py-169-         override this one.
utils/ate/scripts/run_variations.py-170-      2. `repo` has a configured git remote — a fresh `git init` scratch repo
utils/ate/scripts/run_variations.py-171-         has none; a real project clone almost always does. Refused unless
utils/ate/scripts/run_variations.py-172-         --allow-destructive-reset is passed to acknowledge the risk.
utils/ate/scripts/run_variations.py-173-    """
utils/ate/scripts/run_variations.py-174-    if not _git(repo, "rev-parse", "--is-inside-work-tree", check=False).returncode == 0:
utils/ate/scripts/run_variations.py:175:        raise RepoGuardError(f"--repo is not inside a git work tree: {repo}")
utils/ate/scripts/run_variations.py-176-
utils/ate/scripts/run_variations.py-177-    repo_top = _git(repo, "rev-parse", "--show-toplevel").stdout.strip()
utils/ate/scripts/run_variations.py-178-    harness_top = _git(harness_root, "rev-parse", "--show-toplevel", check=False).stdout.strip()
utils/ate/scripts/run_variations.py-179-    if harness_top and os.path.realpath(repo_top) == os.path.realpath(harness_top):
utils/ate/scripts/run_variations.py-180-        raise RepoGuardError(
utils/ate/scripts/run_variations.py-181-            f"refusing to run: --repo resolves to the harness repo itself ({repo_top}). "
utils/ate/scripts/run_variations.py-182-            "ATE's per-variation `git reset --hard` + `git clean -fdx` would destroy it. "
utils/ate/scripts/run_variations.py-183-            "Point --repo at a disposable scratch repo (see SKILL.md 'Quick start')."
--
relay-automation/README.md-115-| [CROSSMODEL-OPTIONA-PLAN.md](CROSSMODEL-OPTIONA-PLAN.md) | The Option-A cross-model headless turn-taker plan (Codex / agy shims). |
relay-automation/README.md-116-| [MARATHON.example.yaml](MARATHON.example.yaml) | Example multi-build marathon manifest for `marathon.sh`. |
relay-automation/README.md-117-
relay-automation/README.md-118-## `marathon.sh` roots
relay-automation/README.md-119-
relay-automation/README.md-120-`marathon.sh` resolves two different roots on purpose:
relay-automation/README.md-121-
relay-automation/README.md-122-- `MARATHON_HOME`: the harness install that owns `bin/tick`, `bin/marathon-yaml`, and telemetry helpers. Default: the script's own parent dir (`relay-automation/..`).
relay-automation/README.md:123:- `MARATHON_ROOT`: the target repo that owns the plan's `brief:` files, `marathon-system/`, `.tick/`, and commit target. Default: `git -C "$PWD" rev-parse --show-toplevel`; outside a git repo it falls back to `MARATHON_HOME`.
relay-automation/README.md-124-
relay-automation/README.md-125-That split preserves dev-checkout behavior (`MARATHON_HOME == MARATHON_ROOT`) and makes vendored installs work with no bin overrides:
relay-automation/README.md-126-
relay-automation/README.md-127-```bash
relay-automation/README.md-128-cd /path/to/target-repo
relay-automation/README.md-129-./.xyz/relay-automation/marathon.sh --plan marathon-plans/my-wave/MARATHON.yaml
relay-automation/README.md-130-```
relay-automation/README.md-131-
--
relay-automation/README.md-242-headless worker you plan to drive. **Install and sign in to the worker CLIs
relay-automation/README.md-243-first** — every shim shells out to them, so an unauthenticated CLI fails the turn
relay-automation/README.md-244-mid-run rather than at startup:
relay-automation/README.md-245-
relay-automation/README.md-246-| Worker | Install | Authenticate |
relay-automation/README.md-247-|---|---|---|
relay-automation/README.md-248-| **Codex** (OpenAI) | <https://openai.com/index/introducing-the-codex-app/> | Sign in with your ChatGPT account — `codex` prompts on first run. Billing follows the ChatGPT subscription, not API credits. |
relay-automation/README.md-249-| **agy** (Google Antigravity — install the **CLI**, not just the desktop app) | <https://antigravity.google/product/antigravity-cli> | Sign in through the Antigravity desktop app. On macOS the CLI lands at `~/.local/bin/agy`, which is **not** on the default `PATH`. |
relay-automation/README.md:250:| **Pi** (optional third lane, GH-295) | Ships outside this repo — put `pi` on `PATH`, or point `PI_BIN` at it | Provider credential via `PI_PROVIDER` (defaults to `openrouter`, reusing `OPENROUTER_API_KEY`) |
relay-automation/README.md-251-
relay-automation/README.md-252-You can also hand the Antigravity URL to Claude Code and ask it to do the install
relay-automation/README.md-253-for you. Codex and agy are the two the beta onboarding path assumes; Pi is
relay-automation/README.md-254-additive.
relay-automation/README.md-255-
relay-automation/README.md-256-Once installed, verify Node, git, and the lane you actually plan to drive:
relay-automation/README.md-257-
relay-automation/README.md-258-```bash
--
relay-automation/codex-turn.sh-59-# Exit: 0 acted/deferred · 5 codex failed / token ownership missing · 6 off-allowlist edit
relay-automation/codex-turn.sh-60-#       (reverted) · 7 timeout-killed · 2 usage.
relay-automation/codex-turn.sh-61-
relay-automation/codex-turn.sh-62-HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
relay-automation/codex-turn.sh-63-# shellcheck source=relay-turn-lib.sh
relay-automation/codex-turn.sh-64-source "$HERE/relay-turn-lib.sh"
relay-automation/codex-turn.sh-65-
relay-automation/codex-turn.sh-66-# Default ROOT to the CWD's git toplevel (the repo the operator is actually driving) so a
relay-automation/codex-turn.sh:67:# NON-VENDORED run — this shim invoked from outside the target repo, e.g. straight from the swarm
relay-automation/codex-turn.sh-68-# checkout — roots worktree isolation + artifact copyback at the TARGET, not this shim's own repo
relay-automation/codex-turn.sh-69-# ($HERE/..). Explicit CODEX_TURN_ROOT still wins (fixtures); fall back to $HERE/.. off a git repo.
relay-automation/codex-turn.sh-70-ROOT="${CODEX_TURN_ROOT:-"$(git rev-parse --show-toplevel 2>/dev/null || (cd "$HERE/.." && pwd))"}"
relay-automation/codex-turn.sh-71-CODEX_BIN="${CODEX_BIN:-codex}"
relay-automation/codex-turn.sh-72-die() { printf 'codex-turn: %s\n' "$*" >&2; exit 2; }
relay-automation/codex-turn.sh-73-
relay-automation/codex-turn.sh-74-me="${RELAY_AGENT:-}"; f="${RELAY_FILE:-}"; t="${RELAY_TASK:-RELAY-TURN}"
relay-automation/codex-turn.sh-75-codex_agent="${CODEX_AGENT:-}"
--
test/hq-marathon-live.sh-1-#!/usr/bin/env bash
test/hq-marathon-live.sh-2-# GH-218 Phase 1: hermetic regression lock for utils/hq/marathon-live.sh.
test/hq-marathon-live.sh-3-#
test/hq-marathon-live.sh-4-# Builds fixture XYZ-registry repos, seeds each with a pre-projected .tick/STATE.md + a no-op tick
test/hq-marathon-live.sh-5-# stub, and asserts marathon-live classifies the three live states — a claim WITH a held driver lock
test/hq-marathon-live.sh-6-# (live), a claim with NO lock/no recent worktree (claimed, not driving), and nothing claimed (idle) —
test/hq-marathon-live.sh:7:# without writing inside any target repo.
test/hq-marathon-live.sh-8-
test/hq-marathon-live.sh-9-set -uo pipefail
test/hq-marathon-live.sh-10-
test/hq-marathon-live.sh-11-HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
test/hq-marathon-live.sh-12-ROOT="$(cd "$HERE/.." && pwd)"
test/hq-marathon-live.sh-13-LIVE="$ROOT/utils/hq/marathon-live.sh"
test/hq-marathon-live.sh-14-
test/hq-marathon-live.sh-15-WORK="$(mktemp -d "${TMPDIR:-/tmp}/hq-marathon-live.XXXXXX")"
--
test/hq-marathon-live.sh-95-  && grep -q -- '- Claimed but not driving: 1' "$OUT" \
test/hq-marathon-live.sh-96-  && grep -q -- '- Idle repos: 1' "$OUT" \
test/hq-marathon-live.sh-97-  && pass "summary counts match the fixture matrix (1 live / 1 stalled / 1 idle)" \
test/hq-marathon-live.sh-98-  || fail "summary counts wrong: $(grep -E '^- (Live|Claimed|Idle)' "$OUT")"
test/hq-marathon-live.sh-99-
test/hq-marathon-live.sh-100-# Read-only: marathon-live must never write into a target repo (only .tick/STATE.md regen, which the
test/hq-marathon-live.sh-101-# no-op stub leaves untouched here — assert no report/aggregate leaked into any fixture repo).
test/hq-marathon-live.sh-102-if find "$WORK/repos" -name 'HQ-MARATHON-LIVE-*' | grep -q .; then
test/hq-marathon-live.sh:103:  fail "marathon-live wrote an aggregate inside a target repo"
test/hq-marathon-live.sh-104-else
test/hq-marathon-live.sh-105-  pass "marathon-live stayed read-only over target repos"
test/hq-marathon-live.sh-106-fi
test/hq-marathon-live.sh-107-
test/hq-marathon-live.sh-108-echo "== hq-marathon-live: $PASS passed, $FAIL failed =="
test/hq-marathon-live.sh-109-[ "$FAIL" -eq 0 ]
--
utils/pdda/pdda-edit-doc-hook.sh-24-# so a simple capture is safe; if it yields nothing we just exit 0 (fail-open).
utils/pdda/pdda-edit-doc-hook.sh-25-file_path="$(printf '%s' "$payload" \
utils/pdda/pdda-edit-doc-hook.sh-26-  | sed -n 's/.*"file_path"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -n1)"
utils/pdda/pdda-edit-doc-hook.sh-27-[ -n "$file_path" ] || exit 0
utils/pdda/pdda-edit-doc-hook.sh-28-
utils/pdda/pdda-edit-doc-hook.sh-29-# Normalize to a repo-relative path for the doc-type test.
utils/pdda/pdda-edit-doc-hook.sh-30-case "$file_path" in
utils/pdda/pdda-edit-doc-hook.sh-31-  "$PDDA_REPO_ROOT"/*) rel="${file_path#"$PDDA_REPO_ROOT"/}" ;;
utils/pdda/pdda-edit-doc-hook.sh:32:  /*) exit 0 ;;                # absolute path outside this repo — not ours
utils/pdda/pdda-edit-doc-hook.sh-33-  *) rel="$file_path" ;;       # already repo-relative
utils/pdda/pdda-edit-doc-hook.sh-34-esac
utils/pdda/pdda-edit-doc-hook.sh-35-
utils/pdda/pdda-edit-doc-hook.sh-36-# Instant no-op unless it is a PDDA-governed doc.
utils/pdda/pdda-edit-doc-hook.sh-37-case "$rel" in
utils/pdda/pdda-edit-doc-hook.sh-38-  ROADMAP.md|PROJECT/*.md) : ;;
utils/pdda/pdda-edit-doc-hook.sh-39-  *) exit 0 ;;
utils/pdda/pdda-edit-doc-hook.sh-40-esac
--
relay-automation/agy-turn.sh-77-# Exit: 0 acted/deferred · 5 agy failed or produced empty output · 6 off-allowlist edit (reverted) ·
relay-automation/agy-turn.sh-78-#       7 timeout-killed · 2 usage.
relay-automation/agy-turn.sh-79-
relay-automation/agy-turn.sh-80-HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
relay-automation/agy-turn.sh-81-# shellcheck source=relay-turn-lib.sh
relay-automation/agy-turn.sh-82-source "$HERE/relay-turn-lib.sh"
relay-automation/agy-turn.sh-83-
relay-automation/agy-turn.sh-84-# Default ROOT to the CWD's git toplevel (the repo the operator is actually driving) so a
relay-automation/agy-turn.sh:85:# NON-VENDORED run — this shim invoked from outside the target repo, e.g. straight from the swarm
relay-automation/agy-turn.sh-86-# checkout — roots worktree isolation + artifact copyback at the TARGET, not this shim's own repo
relay-automation/agy-turn.sh-87-# ($HERE/..). Explicit AGY_TURN_ROOT still wins (fixtures); fall back to $HERE/.. off a git repo.
relay-automation/agy-turn.sh-88-ROOT="${AGY_TURN_ROOT:-"$(git rev-parse --show-toplevel 2>/dev/null || (cd "$HERE/.." && pwd))"}"
relay-automation/agy-turn.sh-89-AGY_BIN="${AGY_BIN:-agy}"
relay-automation/agy-turn.sh-90-die() { printf 'agy-turn: %s\n' "$*" >&2; exit 2; }
relay-automation/agy-turn.sh-91-agy_auth_preflight() {
relay-automation/agy-turn.sh-92-  local secs="${AGY_AUTH_TIMEOUT_S:-5}" out rc=0 line
relay-automation/agy-turn.sh-93-  out="${TMPDIR:-/tmp}/agy-auth-$$.log"
--
relay-automation/hooks/gh177-sandbox-test-guard.sh-1-#!/usr/bin/env bash
relay-automation/hooks/gh177-sandbox-test-guard.sh-2-#
relay-automation/hooks/gh177-sandbox-test-guard.sh-3-# gh177-sandbox-test-guard.sh — PreToolUse guard: never EXECUTE this repo's test
relay-automation/hooks/gh177-sandbox-test-guard.sh-4-# suite under a sandboxed Claude Code Bash call.
relay-automation/hooks/gh177-sandbox-test-guard.sh-5-#
relay-automation/hooks/gh177-sandbox-test-guard.sh-6-# The incident this closes (GH-177, twice): an agent ran an innocuous-looking
relay-automation/hooks/gh177-sandbox-test-guard.sh-7-# `./validate.sh` under the Bash sandbox; the sandbox silently broke `mktemp -d`
relay-automation/hooks/gh177-sandbox-test-guard.sh:8:# inside a test script, `cd ""` stayed at the repo root, and the script's
relay-automation/hooks/gh177-sandbox-test-guard.sh-9-# destructive `rm -rf` EXIT trap wiped the working tree plus parts of `.git`.
relay-automation/hooks/gh177-sandbox-test-guard.sh-10-# The dangerous command never appeared at the CLI boundary — so a deny-list of
relay-automation/hooks/gh177-sandbox-test-guard.sh-11-# "rm -rf"-shaped commands cannot catch it. This guard keys on the TRIGGER
relay-automation/hooks/gh177-sandbox-test-guard.sh-12-# (sandboxed suite execution) instead of the payload.
relay-automation/hooks/gh177-sandbox-test-guard.sh-13-#
relay-automation/hooks/gh177-sandbox-test-guard.sh-14-# Wiring (.claude/settings.json):
relay-automation/hooks/gh177-sandbox-test-guard.sh-15-#   "hooks": { "PreToolUse": [ { "matcher": "Bash",
relay-automation/hooks/gh177-sandbox-test-guard.sh-16-#     "hooks": [ { "type": "command",
--
relay-automation/aider-turn.sh-86-# Exit: 0 acted/deferred · 5 aider failed / no OPENROUTER_API_KEY / empty output · 6 off-allowlist edit
relay-automation/aider-turn.sh-87-#       (reverted) · 7 timeout-killed · 2 usage.
relay-automation/aider-turn.sh-88-
relay-automation/aider-turn.sh-89-HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
relay-automation/aider-turn.sh-90-# shellcheck source=relay-turn-lib.sh
relay-automation/aider-turn.sh-91-source "$HERE/relay-turn-lib.sh"
relay-automation/aider-turn.sh-92-
relay-automation/aider-turn.sh-93-# Default ROOT to the CWD's git toplevel (the repo the operator is actually driving) so a
relay-automation/aider-turn.sh:94:# NON-VENDORED run — this shim invoked from outside the target repo, e.g. straight from the swarm
relay-automation/aider-turn.sh-95-# checkout — roots worktree isolation + artifact copyback at the TARGET, not this shim's own repo
relay-automation/aider-turn.sh-96-# ($HERE/..). Explicit AIDER_TURN_ROOT still wins (fixtures); fall back to $HERE/.. off a git repo.
relay-automation/aider-turn.sh-97-ROOT="${AIDER_TURN_ROOT:-"$(git rev-parse --show-toplevel 2>/dev/null || (cd "$HERE/.." && pwd))"}"
relay-automation/aider-turn.sh-98-AIDER_BIN="${AIDER_BIN:-aider}"
relay-automation/aider-turn.sh-99-# GH-147 Phase 2 (LM_STUDIO lane): two seams share this shim, same contract Phase 1 proved in
relay-automation/aider-turn.sh-100-# consult.sh. AIDER_OPENAI_API_BASE set -> LM Studio / OpenAI-compatible seam (default model
relay-automation/aider-turn.sh-101-# openai/agents-a1); unset -> the OpenRouter default, byte-identical to the pre-GH-147 behavior.
relay-automation/aider-turn.sh-102-if [[ -n "${AIDER_OPENAI_API_BASE:-}" ]]; then
--
relay-automation/aider-turn.sh-213-# was missed, so every aider-turn failure transcript was lost as soon as the tmp file was reaped,
relay-automation/aider-turn.sh-214-# including the GH-280 worktree-mode failures this was supposed to help diagnose.
relay-automation/aider-turn.sh-215-AIDER_LOG="${AIDER_LOG:-$(rtl_default_log "$ROOT" aider-turn "$t")}"
relay-automation/aider-turn.sh-216-
relay-automation/aider-turn.sh-217-# GH-77 live-E2E fix: redirect Aider's own aux/history files OUT of the target repo. By default Aider
relay-automation/aider-turn.sh-218-# writes `.aider.chat.history.md` + `.aider.input.history` (and `.aider.llm.history`) into CWD; with
relay-automation/aider-turn.sh-219-# `--no-gitignore` they land as UNTRACKED files in the working tree and trip rtl_enforce's off-allowlist
relay-automation/aider-turn.sh-220-# guard (exit 6) — so every REAL turn failed even though the stub tests (which never create them) passed.
relay-automation/aider-turn.sh:221:# Point them at a throwaway dir outside the repo so containment only ever sees the intended relay/artifact
relay-automation/aider-turn.sh-222-# edits. (`--map-tokens 0` already suppresses the `.aider.tags.cache.*` repo-map; `--no-analytics` the rest.)
relay-automation/aider-turn.sh-223-AIDER_AUX_DIR="${AIDER_AUX_DIR:-${TMPDIR:-/tmp}/aider-aux-$$}"; mkdir -p "$AIDER_AUX_DIR" 2>/dev/null || true
relay-automation/aider-turn.sh-224-
relay-automation/aider-turn.sh-225-# GH-186: vendored installs can run older aider builds where --add-gitignore-files still exists and
relay-automation/aider-turn.sh-226-# is needed for gitignored relay files, while current aider releases removed it and now hard-fail on
relay-automation/aider-turn.sh-227-# the flag. Probe the installed binary's actual CLI surface instead of hardcoding either behavior.
relay-automation/aider-turn.sh-228-aider_supports_add_gitignore_files() {
relay-automation/aider-turn.sh-229-  local _help
--
relay-automation/pi-turn.sh-81-# Exit: 0 acted/deferred · 5 pi failed / produced empty output / PI_MODEL unset / auth pre-flight
relay-automation/pi-turn.sh-82-#       failed · 6 off-allowlist edit (reverted) · 7 timeout-killed · 2 usage.
relay-automation/pi-turn.sh-83-
relay-automation/pi-turn.sh-84-HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
relay-automation/pi-turn.sh-85-# shellcheck source=relay-turn-lib.sh
relay-automation/pi-turn.sh-86-source "$HERE/relay-turn-lib.sh"
relay-automation/pi-turn.sh-87-
relay-automation/pi-turn.sh-88-# Default ROOT to the CWD's git toplevel (the repo the operator is actually driving) so a
relay-automation/pi-turn.sh:89:# NON-VENDORED run — this shim invoked from outside the target repo, e.g. straight from the swarm
relay-automation/pi-turn.sh-90-# checkout — roots worktree isolation + artifact copyback at the TARGET, not this shim's own repo
relay-automation/pi-turn.sh-91-# ($HERE/..). Explicit PI_TURN_ROOT still wins (fixtures); fall back to $HERE/.. off a git repo.
relay-automation/pi-turn.sh-92-ROOT="${PI_TURN_ROOT:-"$(git rev-parse --show-toplevel 2>/dev/null || (cd "$HERE/.." && pwd))"}"
relay-automation/pi-turn.sh-93-PI_BIN="${PI_BIN:-pi}"
relay-automation/pi-turn.sh-94-PI_PROVIDER="${PI_PROVIDER:-openrouter}"
relay-automation/pi-turn.sh-95-die() { printf 'pi-turn: %s\n' "$*" >&2; exit 2; }
relay-automation/pi-turn.sh-96-
relay-automation/pi-turn.sh-97-me="${RELAY_AGENT:-}"; f="${RELAY_FILE:-}"; t="${RELAY_TASK:-RELAY-TURN}"
--
relay-automation/relay-drive.sh-285-# startup instead of spending the turn. The documented fix is to vendor the harness into the target
relay-automation/relay-drive.sh-286-# repo so the relay file, harness and source share one writable root, then drop --target-root.
relay-automation/relay-drive.sh-287-if [[ -n "${TARGET_ROOT:-}" ]]; then
relay-automation/relay-drive.sh-288-  _gh245_tr="$(cd "$TARGET_ROOT" 2>/dev/null && pwd -P)"
relay-automation/relay-drive.sh-289-  _gh245_rf="$(cd "$(dirname "$RELAY_FILE")" 2>/dev/null && pwd -P)/$(basename "$RELAY_FILE")"
relay-automation/relay-drive.sh-290-  if [[ -n "$_gh245_tr" && "$_gh245_rf" != "$_gh245_tr"/* ]]; then
relay-automation/relay-drive.sh-291-    _gh289_turn_kind="build"
relay-automation/relay-drive.sh-292-    if ((REVIEW_ONCE)); then _gh289_turn_kind="review"; fi
relay-automation/relay-drive.sh:293:    die "--target-root $_gh289_turn_kind turn cannot report: relay file '$RELAY_FILE' resolves outside the target root '$TARGET_ROOT', so a $_gh289_turn_kind turn (ALLOW_PATHS=\"\") has no writable path for its findings and the turn would be discarded after full cost. Vendor the harness into the target repo (relay-automation/xyz-vendor.sh '$TARGET_ROOT') and drop --target-root, or move the relay thread under the target root."
relay-automation/relay-drive.sh-294-  fi
relay-automation/relay-drive.sh-295-fi
relay-automation/relay-drive.sh-296-
relay-automation/relay-drive.sh-297-# GH-45: per-lane attempt cap. A real build/review LOOP counts; a single --review-once turn and a
relay-automation/relay-drive.sh-298-# dry-run do not (they can't rabbit-hole). Keyed on the relay task, stable across re-fires.
relay-automation/relay-drive.sh-299-if ((DRY_RUN == 0)) && ((REVIEW_ONCE == 0)); then
relay-automation/relay-drive.sh-300-  # Attempts live with the tick token (its repo), so tests that point TICK_REPO_ROOT at a temp dir
relay-automation/relay-drive.sh-301-  # stay hermetic; a real standalone run falls back to this clone.
--
relay-automation/relay-drive.sh-315-# regardless of HEAD-tracked status — relay-turn-lib.sh:247). So an uncommitted relay file is usually
relay-automation/relay-drive.sh-316-# still visible to the reviewer; the original "will find nothing" claim was a false-positive
relay-automation/relay-drive.sh-317-# generator for that common case (confirmed live 2026-07-07 night: a driven turn completed normally
relay-automation/relay-drive.sh-318-# on an uncommitted relay file). The ONE case seeding does NOT cover: the relay file lives in a
relay-automation/relay-drive.sh-319-# DIFFERENT git repo than the turn-taker's effective root (e.g. an XYZ_ARCHIVE_ROOT-redirected
relay-automation/relay-drive.sh-320-# transcript) — rtl_init normalizes an out-of-root path to an absolute string the seed step's
relay-automation/relay-drive.sh-321-# relative existence check won't match (GH-30 Phase 3), so it genuinely can be invisible there.
relay-automation/relay-drive.sh-322-# Never block either way (a non-isolated run is free to use an uncommitted file, and a relay file
relay-automation/relay-drive.sh:323:# outside any git repo is fine too).
relay-automation/relay-drive.sh-324-warn_if_relay_file_untracked() {
relay-automation/relay-drive.sh-325-  [[ "${RELAY_WORKTREE_ISOLATION:-1}" != 0 ]] || return 0
relay-automation/relay-drive.sh-326-  local dir prefix rel
relay-automation/relay-drive.sh-327-  dir="$(cd "$(dirname "$RELAY_FILE")" 2>/dev/null && pwd)" || return 0   # not a real dir → skip
relay-automation/relay-drive.sh-328-  # --show-prefix yields the repo-root-relative path of $dir (empty at root); building the relative
relay-automation/relay-drive.sh-329-  # path this way avoids subtracting an absolute toplevel, which breaks under macOS /var → /private/var
relay-automation/relay-drive.sh-330-  # symlinks (logical pwd vs git's physical toplevel).
relay-automation/relay-drive.sh-331-  prefix="$(git -C "$dir" rev-parse --show-prefix 2>/dev/null)" || return 0  # not in a git repo → skip
--
relay-automation/marathon-drive.sh-456-  # telling one run from another. Let the invoker override it (swarm-preflight bakes the per-run slug
relay-automation/marathon-drive.sh-457-  # into its generated command via XYZ_SESSION_ID); fall back to PHASE_ID otherwise (GH-75 review).
relay-automation/marathon-drive.sh-458-  sid="${XYZ_SESSION_ID:-$PHASE_ID}"
relay-automation/marathon-drive.sh-459-  "$XYZ_APPEND_BIN" "$harness" "$sid" "$health" "$title" "$desc" >/dev/null 2>&1 || true
relay-automation/marathon-drive.sh-460-}
relay-automation/marathon-drive.sh-461-
relay-automation/marathon-drive.sh-462-# Sentinel Tier 1 (GH-281): append ONE PDDA-output-contract JSONL finding to $DEBUG_LOG_FILE.
relay-automation/marathon-drive.sh-463-# Opt-in (XYZ_DEBUG_LOG=1), default off. Writes only this one local file — no network, no
relay-automation/marathon-drive.sh:464:# PDDA-ACTIVITY.jsonl, no telemetry. NEVER fails the run.
relay-automation/marathon-drive.sh-465-_json_esc() {  # normalize all C0/DEL controls (UTF-8 safe), then escape backslash + quote
relay-automation/marathon-drive.sh-466-  local s="$1"; s="$(printf '%s' "$s" | tr '\000-\037\177' ' ')"; s="${s//\\/\\\\}"; s="${s//\"/\\\"}"
relay-automation/marathon-drive.sh-467-  printf '%s' "$s"
relay-automation/marathon-drive.sh-468-}
relay-automation/marathon-drive.sh-469-xyz_debug_log_append() {  # <severity> <check> <message> [file] [action] [probe]
relay-automation/marathon-drive.sh-470-  [[ "${XYZ_DEBUG_LOG:-0}" == "1" ]] || return 0
relay-automation/marathon-drive.sh-471-  local sev="$1" chk="$2" msg="$3" file="${4:-}" action="${5:-}" probe="${6:-}" ts scope
relay-automation/marathon-drive.sh-472-  ts="$(date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || echo unknown)"
--
utils/pdda/PDDA-INSTALL.md-31-verbatim and silently destroyed repo-authored versions.) To deliberately refresh a target's startup docs
utils/pdda/PDDA-INSTALL.md-32-from the canonical repo — for instance to pick up a corrected `ROUTER.md` — pass
utils/pdda/PDDA-INSTALL.md-33-`--with-startup-docs --force`, and diff before committing.
utils/pdda/PDDA-INSTALL.md-34-
utils/pdda/PDDA-INSTALL.md-35-### Migrating a repo that predates the `utils/pdda/` layout
utils/pdda/PDDA-INSTALL.md-36-
utils/pdda/PDDA-INSTALL.md-37-Older installs put the runtime **flat** under `utils/` (`utils/pdda.sh`, `utils/pdda-lib.sh`,
utils/pdda/PDDA-INSTALL.md-38-`utils/pdda-doc-ready.sh`, sometimes `utils/pdda-catchup.sh`, plus `utils/PDDA-INSTALL.md` and a
utils/pdda/PDDA-INSTALL.md:39:legacy `utils/pdda-phase-out/`). The runtime is relocatable (it sources via `HERE="$(dirname "$0")"`),
utils/pdda/PDDA-INSTALL.md-40-so both layouts *run* — but a plain re-install **adds** the new `utils/pdda/` subfolder beside the old
utils/pdda/PDDA-INSTALL.md-41-flat files, leaving **two copies** and an ambiguous source of truth.
utils/pdda/PDDA-INSTALL.md-42-
utils/pdda/PDDA-INSTALL.md-43-`install.sh` detects the flat layout and **migrates it automatically** (one canonical `utils/pdda/`):
utils/pdda/PDDA-INSTALL.md-44-it removes the now-duplicate PDDA-owned flat files (`utils/pdda.sh`, `utils/pdda-lib.sh`,
utils/pdda/PDDA-INSTALL.md-45-`utils/pdda-doc-ready.sh`, `utils/pdda-catchup.sh`, `utils/PDDA-INSTALL.md`, the legacy
utils/pdda/PDDA-INSTALL.md-46-`utils/pdda-phase-out/`), repoints old-path references (`utils/pdda.sh` → `utils/pdda/pdda.sh`, etc.)
utils/pdda/PDDA-INSTALL.md-47-in tracked docs, and prints a summary of what moved. The target repo's own non-PDDA `utils/` files are
--
utils/pdda/PDDA-INSTALL.md-226-reachable from; default `ROUTER.md`), and three GH-15 exemption-manifest overrides scoped to the docs
utils/pdda/PDDA-INSTALL.md-227-that ship to every target install (`PDDA-INSTALL.md`, `PROJECT/PDDA.md`) so a fresh install's first
utils/pdda/PDDA-INSTALL.md-228-`pdda.sh run` doesn't self-inflict dead-reference/env-var noise from files `install.sh` deliberately
utils/pdda/PDDA-INSTALL.md-229-never copies: `PDDA_GOV_SHIPPED_DOCS` (which shipped docs the exemptions apply to; default
utils/pdda/PDDA-INSTALL.md-230-`utils/pdda/PDDA-INSTALL.md PROJECT/PDDA.md`), `PDDA_GOV_SHIPPED_DOC_REF_EXEMPTIONS` (basenames/paths
utils/pdda/PDDA-INSTALL.md-231-those docs may dead-reference without a warn — the target's own startup docs, canonical-only skill and
utils/pdda/PDDA-INSTALL.md-232-companion-doc paths, and the pre-`utils/pdda/` legacy install path), and
utils/pdda/PDDA-INSTALL.md-233-`PDDA_GOV_SHIPPED_DOC_ENVVAR_EXEMPTIONS` (canonical-only-tool env vars those docs may mention without a warn).
utils/pdda/PDDA-INSTALL.md:234:A repo-authored governance doc outside `PDDA_GOV_SHIPPED_DOCS` (e.g. this repo's own `ROUTER.md`) is
utils/pdda/PDDA-INSTALL.md-235-never exempted — a dead reference there stays a real drift signal.
utils/pdda/PDDA-INSTALL.md-236-
utils/pdda/PDDA-INSTALL.md-237-## Minimal target-repo expectations
utils/pdda/PDDA-INSTALL.md-238-
utils/pdda/PDDA-INSTALL.md-239-PDDA assumes these repo concepts exist, either literally or through overrides:
utils/pdda/PDDA-INSTALL.md-240-
utils/pdda/PDDA-INSTALL.md-241-- an active-doc folder
utils/pdda/PDDA-INSTALL.md-242-- an archive/misc folder
--
relay-automation/marathon.sh-34-#
relay-automation/marathon.sh-35-# The MARATHON.yaml phase fields drive each marathon-drive call: id→--phase-id, reviewer→--reviewer,
relay-automation/marathon.sh-36-# brief→--phase-brief (required to run), artifact→--artifact, turn_timeout_s→RELAY_TURN_TIMEOUT_S,
relay-automation/marathon.sh-37-# max_review_rounds→--round-cap.
relay-automation/marathon.sh-38-#
relay-automation/marathon.sh-39-# Environment overrides (for tests):
relay-automation/marathon.sh-40-#   MARATHON_HOME       — harness home (default: parent of this script's dir)
relay-automation/marathon.sh-41-#   MARATHON_ROOT       — target repo root (default: `git -C "$PWD" rev-parse --show-toplevel`,
relay-automation/marathon.sh:42:#                         falling back to MARATHON_HOME outside a git repo)
relay-automation/marathon.sh-43-#   MARATHON_DRIVE      — marathon-drive.sh path (default: <harness-home>/relay-automation/marathon-drive.sh)
relay-automation/marathon.sh-44-#   MARATHON_YAML_BIN   — bin/marathon-yaml path (default: <harness-home>/bin/marathon-yaml)
relay-automation/marathon.sh-45-#   TICK_BIN            — tick binary (default: <harness-home>/bin/tick)
relay-automation/marathon.sh-46-#   MARATHON_CLOSEOUT_BIN — marathon-closeout.sh path (default: <harness-home>/relay-automation/marathon-closeout.sh)
relay-automation/marathon.sh-47-#   MARATHON_ALLOW_PLAN_OUTSIDE_WORKING — 1 permits a --plan outside PROJECT/2-WORKING/ (GH-212)
relay-automation/marathon.sh-48-# Real runs also inherit the turn-taker env (CLAUDE_BIN, *_TURN_ROOT, …), passed straight through.
relay-automation/marathon.sh-49-#
relay-automation/marathon.sh-50-# Exit: 0 all phases approved · N the failing phase's marathon-drive exit code · 2 usage/parse error.
--
relay-automation/marathon.sh-216-    # documented default is <root>/relay-system, and a run that can record itself there should.
relay-automation/marathon.sh-217-    if [[ -z "${XYZ_ARCHIVE_ROOT:-}" ]]; then
relay-automation/marathon.sh-218-      _run_log_base="$ROOT/relay-system"
relay-automation/marathon.sh-219-    else
relay-automation/marathon.sh-220-      die "XYZ_ARCHIVE_ROOT is set but no durable transcript root could be resolved from it — fix it, or unset it to use <root>/relay-system (GH-388). A marathon that cannot record itself must not start."
relay-automation/marathon.sh-221-    fi
relay-automation/marathon.sh-222-  fi
relay-automation/marathon.sh-223-
relay-automation/marathon.sh:224:  # Scoped to RELOCATION, matching rtl_default_log: a run log inside the repo being driven shares
relay-automation/marathon.sh:225:  # that repo's fate; one outside it, in storage a reboot erases, is the silent relocation this
relay-automation/marathon.sh-226-  # issue is about. Without the scoping every fixture repo under $TMPDIR would refuse to run.
relay-automation/marathon.sh-227-  _run_log_reason="$(xyz_non_durable_reason "$_run_log_base")"
relay-automation/marathon.sh-228-  if [[ -n "$_run_log_reason" ]] && [[ "$(_xyz_realish_path "$_run_log_base")" != "$(_xyz_realish_path "$ROOT")"/* ]]; then
relay-automation/marathon.sh-229-    die "the resolved run-log root $_run_log_base is under $_run_log_reason, which this harness records as non-durable storage ($(xyz_non_durable_conf)), and it is OUTSIDE the repo being driven ($ROOT). A marathon's own record must survive a reboot — that is the whole of GH-388. Point XYZ_ARCHIVE_ROOT at a committed archive, or unset it."
relay-automation/marathon.sh-230-  fi
relay-automation/marathon.sh-231-
relay-automation/marathon.sh-232-  _run_log_dir="$_run_log_base/run-logs/$(date +%Y-%m-%d 2>/dev/null || echo unknown-date)"
relay-automation/marathon.sh-233-  mkdir -p "$_run_log_dir" || die "could not create the run-log directory $_run_log_dir"
--
relay-automation/relay-turn-lib.sh-183-# Persistent default transcript path, reusing rtl_transcript_root so no new path-resolution logic is
relay-automation/relay-turn-lib.sh-184-# introduced. IMPORTANT: the resolved directory ("$root/relay-system/logs" on the common path) MUST
relay-automation/relay-turn-lib.sh-185-# stay gitignored (see .gitignore's "relay-system/logs/" entry) — rtl_check already removes any file
relay-automation/relay-turn-lib.sh-186-# that lands in the tracked tree matching RTL_LOG_REL ("the shim's own transcript log ... is not an
relay-automation/relay-turn-lib.sh-187-# agent edit"), so an UN-ignored path here would be silently deleted at the end of every single turn,
relay-automation/relay-turn-lib.sh-188-# defeating the entire point of "persistent." Falls back to today's PID-keyed tmp path (byte-identical
relay-automation/relay-turn-lib.sh-189-# to the pre-GH-161 default) on any resolver or mkdir failure — logging must never fail a turn.
relay-automation/relay-turn-lib.sh-190-# GH-388: the $TMPDIR fallbacks below are GONE, and this now REFUSES (exit 5) rather than silently
relay-automation/relay-turn-lib.sh:191:# relocating a turn transcript into storage a reboot erases. The header above ends "logging must never
relay-automation/relay-turn-lib.sh-192-# fail a turn", and that trade is what this issue reversed: refusing costs a turn that has not started,
relay-automation/relay-turn-lib.sh-193-# whereas the old behaviour cost the RECORD of a turn that had — discovered only after a host panic,
relay-automation/relay-turn-lib.sh-194-# when the evidence was already gone. The resolver's own stderr is no longer swallowed either, because
relay-automation/relay-turn-lib.sh-195-# WHY the root failed to resolve is the whole of the fix from the operator's side.
relay-automation/relay-turn-lib.sh-196-#
relay-automation/relay-turn-lib.sh-197-# Mirrors utils/py/rtl.py::rtl_default_log. Both read the same non-durable registry via
relay-automation/relay-turn-lib.sh-198-# durable-log-lib.sh / rtl.py::non_durable_reason — one file, so the lanes cannot drift.
relay-automation/relay-turn-lib.sh-199-rtl_default_log() {  # <root> <tool-turn-name> <task> — e.g. rtl_default_log "$ROOT" codex-turn "$t"
--
relay-automation/relay-turn-lib.sh-206-  day="$(date +%Y-%m-%d 2>/dev/null || echo unknown-date)"
relay-automation/relay-turn-lib.sh-207-  path="$base/logs/$day/${tool}-${tslug}-$$.log"
relay-automation/relay-turn-lib.sh-208-
relay-automation/relay-turn-lib.sh-209-  _dl_lib="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/durable-log-lib.sh"
relay-automation/relay-turn-lib.sh-210-  if [[ -f "$_dl_lib" ]]; then
relay-automation/relay-turn-lib.sh-211-    # shellcheck source=/dev/null
relay-automation/relay-turn-lib.sh-212-    source "$_dl_lib"
relay-automation/relay-turn-lib.sh-213-    _reason="$(xyz_non_durable_reason "$path")"
relay-automation/relay-turn-lib.sh:214:    # Scoped to RELOCATION — see the Python twin's comment. A transcript inside the repo being driven
relay-automation/relay-turn-lib.sh-215-    # shares that repo's fate and was not moved anywhere by this harness; one OUTSIDE it, in storage a
relay-automation/relay-turn-lib.sh:216:    # reboot erases, is the silent relocation GH-388 exists to stop.
relay-automation/relay-turn-lib.sh-217-    if [[ -n "$_reason" ]]; then
relay-automation/relay-turn-lib.sh-218-      local _root_real _path_real
relay-automation/relay-turn-lib.sh-219-      _root_real="$(_xyz_realish_path "${root%/}")"
relay-automation/relay-turn-lib.sh-220-      _path_real="$(_xyz_realish_path "$path")"
relay-automation/relay-turn-lib.sh-221-      if [[ "$_path_real" != "$_root_real"/* ]]; then
relay-automation/relay-turn-lib.sh:222:        printf 'rtl_default_log: refusing to start a %s turn — the resolved transcript path %s is under %s, which this harness records as non-durable storage (%s), and it is OUTSIDE the repo being driven (%s). That is a silent relocation of the evidence, which is exactly what GH-388 exists to stop. Point XYZ_ARCHIVE_ROOT at a committed archive, or unset it to use <root>/relay-system.\n' "$tool" "$path" "$_reason" "$(xyz_non_durable_conf)" "$root" >&2
relay-automation/relay-turn-lib.sh-223-        exit 5
relay-automation/relay-turn-lib.sh-224-      fi
relay-automation/relay-turn-lib.sh-225-    fi
relay-automation/relay-turn-lib.sh-226-  fi
relay-automation/relay-turn-lib.sh-227-
relay-automation/relay-turn-lib.sh-228-  if mkdir -p "$(dirname "$path")" 2>/dev/null; then
relay-automation/relay-turn-lib.sh-229-    printf '%s' "$path"
relay-automation/relay-turn-lib.sh-230-  else
relay-automation/relay-turn-lib.sh:231:    printf 'rtl_default_log: refusing to start a %s turn — could not create the durable transcript directory %s. Previously this silently relocated the transcript to temporary storage (GH-388).\n' "$tool" "$(dirname "$path")" >&2
relay-automation/relay-turn-lib.sh-232-    exit 5
relay-automation/relay-turn-lib.sh-233-  fi
relay-automation/relay-turn-lib.sh-234-}
relay-automation/relay-turn-lib.sh-235-
relay-automation/relay-turn-lib.sh-236-rtl_tick_bin() {  # [<tick_repo_root>] → absolute tick executable path
relay-automation/relay-turn-lib.sh-237-  local tickroot="${1:-${TICK_REPO_ROOT:-${RTL_ROOT:-}}}"
relay-automation/relay-turn-lib.sh-238-  [[ -n "${TICK_BIN:-}" ]] && { printf '%s' "$TICK_BIN"; return 0; }
relay-automation/relay-turn-lib.sh-239-  [[ -n "$tickroot" && -x "$tickroot/bin/tick" ]] && { printf '%s/bin/tick' "$tickroot"; return 0; }
--
relay-automation/relay-turn-lib.sh-613-rtl_worktree_begin() {
relay-automation/relay-turn-lib.sh-614-  # Create the worktree, seed the CURRENT working-tree allowlist into it (the HEAD checkout may be
relay-automation/relay-turn-lib.sh-615-  # stale, e.g. an uncommitted relay file), and echo the worktree path. Returns non-zero on failure
relay-automation/relay-turn-lib.sh-616-  # so the caller can fall back to an in-ROOT run. Sets RTL_WT.
relay-automation/relay-turn-lib.sh-617-  local wt a wt_root _root_abs _tmp_abs _gcd
relay-automation/relay-turn-lib.sh-618-  # GH-236: in /tmp-rooted environments $TMPDIR can resolve INSIDE the working root, which drops the
relay-automation/relay-turn-lib.sh-619-  # throwaway isolation worktree inside the very tree the turn operates on and breaks codex turns —
relay-automation/relay-turn-lib.sh-620-  # a failure that then surfaces mislabeled as a turn timeout. Default to $TMPDIR so behaviour is
relay-automation/relay-turn-lib.sh:621:  # unchanged everywhere else; ONLY when $TMPDIR lands inside RTL_ROOT, relocate the worktree root
relay-automation/relay-turn-lib.sh-622-  # under the repo's own git metadata dir (never part of the working tree, never under $TMPDIR) —
relay-automation/relay-turn-lib.sh-623-  # git worktree add accepts a checkout there and git status ignores it.
relay-automation/relay-turn-lib.sh-624-  wt_root="${TMPDIR:-/tmp}"
relay-automation/relay-turn-lib.sh-625-  _root_abs="$(cd "$RTL_ROOT" 2>/dev/null && pwd -P)"
relay-automation/relay-turn-lib.sh-626-  _tmp_abs="$(cd "$wt_root" 2>/dev/null && pwd -P)"
relay-automation/relay-turn-lib.sh-627-  if [[ -n "$_root_abs" && -n "$_tmp_abs" && ( "$_tmp_abs" == "$_root_abs" || "$_tmp_abs" == "$_root_abs"/* ) ]]; then
relay-automation/relay-turn-lib.sh-628-    _gcd="$(git -C "$RTL_ROOT" rev-parse --git-common-dir 2>/dev/null)"
relay-automation/relay-turn-lib.sh-629-    [[ -n "$_gcd" && "$_gcd" != /* ]] && _gcd="$RTL_ROOT/$_gcd"
--
relay-automation/relay-turn-lib.sh-1284-  # this instrumentation existed. Gate on `git status --porcelain` (NOT tracked-vs-untracked): a
relay-automation/relay-turn-lib.sh-1285-  # gitignored persistent log (the GH-161 default, under relay-system/logs/) must NEVER be swept here —
relay-automation/relay-turn-lib.sh-1286-  # it is untracked BY DESIGN and is meant to survive. `git status --porcelain` naturally excludes
relay-automation/relay-turn-lib.sh-1287-  # ignored paths, so it only flags the genuine stray case rtl_check already handles mid-loop (an
relay-automation/relay-turn-lib.sh-1288-  # un-ignored log path that reappeared after our late writes) — never a tracked file, never an
relay-automation/relay-turn-lib.sh-1289-  # intentionally-ignored one.
relay-automation/relay-turn-lib.sh-1290-  # RTL_LOG_REL is only genuinely "in RTL_ROOT" when the earlier `${log#"$RTL_ROOT"/}` strip actually
relay-automation/relay-turn-lib.sh-1291-  # matched, leaving a RELATIVE path — the overwhelmingly common CODEX_LOG=/dev/null case (used by most
relay-automation/relay-turn-lib.sh:1292:  # of the test suite, and any operator override outside the repo) leaves RTL_LOG_REL as the ORIGINAL
relay-automation/relay-turn-lib.sh-1293-  # absolute path unstripped. Passing that straight to `git status --porcelain --` as a pathspec is a
relay-automation/relay-turn-lib.sh:1294:  # FATAL git error ("outside repository", exit 128) that — unguarded — would trip the caller's `set -e`
relay-automation/relay-turn-lib.sh-1295-  # and silently kill an otherwise-successful turn. Skip entirely unless it is repo-relative.
relay-automation/relay-turn-lib.sh-1296-  if [[ -n "$RTL_LOG_REL" && "$RTL_LOG_REL" != /* ]]; then
relay-automation/relay-turn-lib.sh-1297-    local _rtl_log_leftover
relay-automation/relay-turn-lib.sh-1298-    _rtl_log_leftover="$(git -C "$RTL_ROOT" status --porcelain -- "$RTL_LOG_REL" 2>/dev/null || true)"
relay-automation/relay-turn-lib.sh-1299-    # NB: an `if`/`fi` here, not `[[ .. ]] && rm ..` — as the LAST statement of this function, a bare
relay-automation/relay-turn-lib.sh-1300-    # `test && action` returns the test's own (false) status when there is nothing to sweep, which
relay-automation/relay-turn-lib.sh-1301-    # under the caller's `set -e` (every turn-taker shim) would silently exit the whole turn nonzero.
relay-automation/relay-turn-lib.sh-1302-    # An `if` with no `else` always returns 0 when its condition is false.
--
relay-automation/claude-turn.sh-75-#
relay-automation/claude-turn.sh-76-# Exit: 0 acted/deferred · 3 claude not found · 5 claude failed · 6 off-allowlist edit (reverted) · 7 timeout-killed · 2 usage.
relay-automation/claude-turn.sh-77-
relay-automation/claude-turn.sh-78-HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
relay-automation/claude-turn.sh-79-# shellcheck source=relay-turn-lib.sh
relay-automation/claude-turn.sh-80-source "$HERE/relay-turn-lib.sh"
relay-automation/claude-turn.sh-81-
relay-automation/claude-turn.sh-82-# Default ROOT to the CWD's git toplevel (the repo the operator is actually driving) so a
relay-automation/claude-turn.sh:83:# NON-VENDORED run — this shim invoked from outside the target repo, e.g. straight from the swarm
relay-automation/claude-turn.sh-84-# checkout — roots worktree isolation + artifact copyback at the TARGET, not this shim's own repo
relay-automation/claude-turn.sh-85-# ($HERE/..). Explicit CLAUDE_TURN_ROOT still wins (fixtures); fall back to $HERE/.. off a git repo.
relay-automation/claude-turn.sh-86-ROOT="${CLAUDE_TURN_ROOT:-"$(git rev-parse --show-toplevel 2>/dev/null || (cd "$HERE/.." && pwd))"}"
relay-automation/claude-turn.sh-87-CLAUDE_BIN="${CLAUDE_BIN:-}"
relay-automation/claude-turn.sh-88-die() { printf 'claude-turn: %s\n' "$*" >&2; exit 2; }
relay-automation/claude-turn.sh-89-
relay-automation/claude-turn.sh-90-me="${RELAY_AGENT:-}"; f="${RELAY_FILE:-}"; t="${RELAY_TASK:-RELAY-TURN}"
relay-automation/claude-turn.sh-91-claude_agent="${CLAUDE_AGENT:-}"

codex
I’ve confirmed the release gate’s status and the explicit exception records. I’m now checking whether each exception leaves a live operational hole rather than merely a mismatch in wording.
exec
/bin/zsh -lc 'rg -n -C 4 "GH-354|#354|GH-376|#376|GH-448|#448|driver-lock|common-dir|all driver pairs|linked worktree" CHANGELOG.md ROADMAP.md PROJECT/3-COMPLETED PROJECT/2-WORKING test relay-automation utils/py utils/hq | head -n 700' in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-69972-gxaghv_u
 succeeded in 0ms:
ROADMAP.md-72-- **GH-497 · agent2agent compact multi-session rendezvous** 🚧 **active 2026-08-11 on `feature/agent2agent`** — reuse the existing file-based relay as a serialized discussion channel for 2+ sessions, addressed by a collision-safe six-digit ID and plain `agent1`/`agent2`/`agentN` identities; seed turn 1 from the invitation subject and leave Tick's schema unchanged. → [GH-497-AGENT2AGENT.md](PROJECT/2-WORKING/GH-497-AGENT2AGENT.md) · [#497](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/497)
ROADMAP.md-73-- **GH-480 · XYZ Cockpit — read-only VS Code view for Marathons, Releases, Worktrees** 🆕 **captured 2026-08-09, alpha scaffold built on `feat/gh480-vscode-cockpit-ext` (PR #481, draft)** — standalone extension (Traycer's own Activity Bar view is a closed single webview with no extension point, checked directly), one webview with three collapsible card sections and copy-to-clipboard. Read-only: nothing is executed. Still needs a live F5 visual check before the PR leaves draft. → [GH-480-VSCODE-COCKPIT-EXT.md](PROJECT/1-INBOX/GH-480-VSCODE-COCKPIT-EXT.md) · [#480](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/480)
ROADMAP.md-74-- **GH-451 · Marathon: support Pi builders on the Python-default path** 🆕 **captured 2026-08-08** — route Pi through the existing dispatcher and preflight `PI_BIN` before any relay/tick mutation; no provider policy or fallback-twin change. → [GH-451-PI-MARATHON-ROUTING.md](PROJECT/1-INBOX/GH-451-PI-MARATHON-ROUTING.md) · [#451](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/451)
ROADMAP.md-75-- **GH-453 · Design an issue-derived fuzzing evidence pipeline** 🆕 **second-pass design 2026-08-08** — qualify closed issue/fix pairs from a rolling 30-day corpus with a blinded pre-fix/post-fix oracle; run generated artifacts only in credential-free throwaway clones, measure reproduction precision and novel defect-class yield, then require human promotion. → [GH-453-ISSUE-DERIVED-FUZZING.md](PROJECT/2-WORKING/GH-453-ISSUE-DERIVED-FUZZING.md) · [#453](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/453)
ROADMAP.md:76:- **GH-441 · the pre-advance gate inherits the marathon state it is supposed to judge** ✅ **Phases 1 AND 2 SHIPPED 2026-08-08 — acceptance 1-5 met** — `validate.sh` is marathon-drive's default `--pre-advance-cmd`, so it ran as a child of a live driver and inherited variables that silently flipped suite verdicts (`gh284` 20/0→15/5, `gh331` 8/0→5/3, `oracle-guard` on ambient `ALLOW_PATHS`). Every affected suite passed standalone every time, which is why it halted the Litmus marathon twice and was misdiagnosed as flakiness both times. **Phase 1** (`3ea23fd`) fixed it per-suite — two suites clear the flag for themselves, the idiom `test/driver-lock.sh:11` already used — after a *global* scrub was landed and **reverted** (measured on a clean tree, the one state where the flag is never set). **Phase 2** (`c9a17d7`) made the boundary governed: `utils/py/gate_env.py` classifies all 19 driver exports scrub-or-pass **with a reason**, `relay-automation/gate-env.sh` gives custom gates the same clean environment without copying a prologue, and the contract test fails loudly on an unclassified export (**observed**). `RELAY_DRIVER_LOCKED` stays PASS by measurement, pinned so the revert cannot recur. **The full gate caught three defects in Phase 2 itself** — a driver-killing `import`, an `eval` the security gate rejected, and a duplicate list — all recorded in the doc. cx/risk/eff 2/2/2, 2 phases. → [GH-441-GATE-ENV-CONTRACT.md](PROJECT/2-WORKING/GH-441-GATE-ENV-CONTRACT.md) · [#441](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/441) · [#419](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/419) · [#407](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/407)
ROADMAP.md-77-- **GH-390 remainder · the gate guard's other kill branch has never been observed firing** 🆕 **captured 2026-08-08 for release 0.2.0 Litmus, OPERATOR GO GIVEN — phase 3 of 3 in [MARATHON-2026-08-08-LITMUS-WAVE-2](PROJECT/2-WORKING/MARATHON-2026-08-08-LITMUS-WAVE-2/MARATHON.yaml)** — the guard itself SHIPPED in PR #393 and is exercised on every gate run (5x observed, 704-806s, exit 0). What did not ship is coverage of its *attribution*: macOS delivers `SIGXCPU` on the soft `RLIMIT_CPU` while Linux checks the **hard** limit first and delivers `SIGKILL`, so a test can only ever observe its own kernel's branch and one half is unreachable on any single machine. **Not hypothetical — that branch already cost a day:** PR #393 failed Linux-only, a first fix mapping another SIGXCPU shape failed identically because `ulimit -t N` sets soft AND hard together, and what produced the answer was a diagnostic commit printing `gate exit -9` — observing the branch, not reasoning about it. Two structural blockers: the runnability pre-check rejects a literal `exec`, and the guard helpers are nested inside `main()` so there is no unit hook. This is #419 applied to the guard, and #407 is the wrong verdict it protects. cx/risk/eff 3/2/3, 2 phases. → [GH-390-GATE-GUARD-COVERAGE.md](PROJECT/2-WORKING/GH-390-GATE-GUARD-COVERAGE.md) · [#390](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/390) · [#419](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/419)
ROADMAP.md-78-- **GH-409 + GH-408 · a leaked tick claim wedges the next turn, and every layer that could name the cause discards it** 🆕 **captured 2026-08-08 for release 0.2.0 Litmus, combined into ONE lane, awaiting operator go** — a shim claims its token and does not release it when the agent fails, so **two failed turns wedge that agent at its claim cap**. Then: the ownership error suggests a diagnostic that shows a *healthy* token, `rtl.py:74` sends the claim's stdout **and** stderr to `DEVNULL` so the `claim limit reached (holding …)` line naming both culprits is thrown away, `tick claim` prints that failure and **exits 0** so an exit-status check learns nothing either, and marathon-drive reports the result as `pre-advance-failed` on a phase **whose gate never ran** (#407). **Both fired live on 2026-08-07 and cost ~2h**, #409's transcript reproducing character-for-character with `agy` for `claude`. Combined because #408 is *why* #409 costs hours. Two additions the issues do not name: a **second** discard site (`rtl.py:74`, on every turn's path — #408 names only `_run_tick_loud`), and a **second** leak producer (a test suite claiming in the production log; fixed `7785c2a`, control 95→95 events). #432 shipped the persistence half and does **not** cover this. cx/risk/eff 2/2/3, 3 phases. → [GH-409-408-TOKEN-FAILURE-VISIBILITY.md](PROJECT/2-WORKING/GH-409-408-TOKEN-FAILURE-VISIBILITY.md) · [#409](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/409) · [#408](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/408) · [#407](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/407)
ROADMAP.md-79-- **GH-432 · a failed builder turn takes the one exit that skips `rtl_enforce`** 🆕 **captured 2026-08-06, in progress on `claude/gh432-turn-failure-persist`** — the generic-failure branch calls `sys.exit(5)` two lines before the timeout branch falls THROUGH to `rtl_enforce`, so a crashed turn skips the file-scoped commit, the allowlist containment check, the transcript archive, the GH-67 token handoff, and the drift signal in one step. **Worktree isolation makes the loss precise:** `worktree_end` has already copied the agent's allowlisted edits back into the real tree, so they are sitting there correct and uncommitted when the exit discards the only path that would commit them — the reporter confirms Round 3's lost patch "closely matched the fix I ended up applying by hand." **All five Python shims share the shape**, so the report is reachable via codex, agy, pi, and aider too; fixing only the reported file would leave it live. Largely subsumes **#409** (same defect from the token side); **#408** is adjacent and NOT fixed here. The issue carried no acceptance block — criteria derived from its "Suggested fix direction" per the GH-400 contract, with the deviations declared in the doc. Its second suggestion (a `RELAY_PEER` interaction) was **checked and declined**: unset `RELAY_PEER` only reaches a WARN branch that cannot fail a turn. cx/risk/eff 2/2/2, 2 phases. → [GH-432-TURN-FAILURE-PERSIST.md](PROJECT/3-COMPLETED/GH-432-TURN-FAILURE-PERSIST.md) · [#432](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/432) · [#409](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/409)
ROADMAP.md-80-- **GH-314 · a pre-existing `phases/`/`relay-system/` ignore rule HALTs a marathon, and `--dry-run` cannot see it** 🆕 **capture written 2026-08-07 (issue open since 2026-07-28)** — `marathon_drive.py` unconditionally `git add`s three files into the target; any ignored one raises `CalledProcessError` and halts the chain. Filed from `LTVera-Pandas` 2026-07-28 with no doc and no ROADMAP entry, so it never became work — then cost a second operator an afternoon in `aegis-sleuth-slack-bot` on 2026-08-07. That run added three things to the issue: a **third** call site, `phases/<lane>/ESCALATION.md` (`marathon_drive.py:956`), which fires *inside* `escalate()` so the crash destroys the record of why the phase halted; serial discovery costing ~1.5h per landmine (un-ignore `RELAY.md` → burn a full phase → crash on `ESCALATION.md`, with the `relay-system/` transcript still queued); and confirmation that **`--target-root` is not an escape hatch** — GH-245/GH-289 correctly reject it for BUILD turns, so a repo that deliberately does not track harness output has *no supported configuration*. On a public target the only workaround publishes builder/reviewer transcripts the repo had explicitly decided to withhold. Operator preference: fail fast in preflight naming all three paths, wired into `--dry-run` too (cf. [#117](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/117)) — explicitly **not** `git add -f`, which would publish silently. Likely the same seam as [#440](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/440) (same `ensure_gitignore`, opposite direction) — worth doing together. Reported via /file-xyz-bug from `aegis-sleuth-slack-bot`. Issue [#314](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/314). -> [PROJECT/1-INBOX/GH-314-VENDOR-GITIGNORE-HALT.md](PROJECT/1-INBOX/GH-314-VENDOR-GITIGNORE-HALT.md)
ROADMAP.md-81-- **GH-440 · `xyz-vendor.sh` gitignores `.xyz/` but not `/.tick/`, so tick runtime state lands untracked in the consuming repo** 🆕 **captured 2026-08-07** — `ensure_gitignore()` (`relay-automation/xyz-vendor.sh:211-218`) appends only `.xyz/`, so the first driven relay drops `<repo>/.tick/` at the repo root as `?? .tick/`, committable by an unrelated `git add -A`. Deterministic, every time. `.tick/` is explicitly per-device state (`skills/relay-xyz/SKILL.md`), so nothing in it is meaningful when shared. Prior art checked: [#18](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/18) named the same symptom for the `--target-root` cross-repo case and closed **doc-only**, leaving the vendor-time gap in code; [#314](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/314) is open against the *same* function in the opposite direction (never un-ignoring `phases/`/`relay-system/`) and is likely the same seam — worth doing together rather than as a second append path. Low severity, hygiene class, but a public-repo footgun. Filed via /file-xyz-bug from `giant-brains-claude-skills`. Issue [#440](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/440). -> [PROJECT/1-INBOX/GH-440-VENDOR-TICK-GITIGNORE.md](PROJECT/1-INBOX/GH-440-VENDOR-TICK-GITIGNORE.md)
ROADMAP.md:82:- **GH-439 · GH-11's foreign-repo split has no guard for a linked worktree of the SAME repo** 🆕 **captured 2026-08-07** — with a vendored `.xyz/`, `ROOT` is the host repo, so `--target-root <linked worktree>` silently commits the relay thread to the main checkout's branch while the build lands on the worktree's. Working-as-designed per [#11](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/11); the ask is a warning naming both branches. `marathon.sh` is unaffected. Filed via /file-xyz-bug from `LTVera-Pandas`. Issue [#439](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/439). -> [PROJECT/1-INBOX/GH-439-SAME-REPO-WORKTREE-SPLIT.md](PROJECT/1-INBOX/GH-439-SAME-REPO-WORKTREE-SPLIT.md)
ROADMAP.md:83:- **GH-435 · XYZ's coordination model is a sequential chain, not a DAG** 🆕 **captured 2026-08-06** — a question about whether XYZ does "graph engineering" turned up a documentation gap, not a defect. The multi-phase model is coherent and its limits look deliberate, but nothing a reader meets says so: `README.md`'s Glossary describes Marathon as chaining phases "in `depends_on` order" and stops, so anyone carrying standard agent-graph vocabulary infers a DAG, parallel stages, and dependency-derived scheduling — none of which exist. Verified against `development`@`80cab6b`: `depends_on` is **scalar-only**, so a join is inexpressible (`MARATHON.example.yaml:42-46`; a list form parses as the literal string and aborts); phases run **strictly one at a time** and a disjoint write-set buys no parallelism (`MARATHON.example.yaml:7-11`, `marathon.sh:168` — one serial `while read` loop); `depends_on` **validates** authored order rather than deriving it, inverting the graph model; failure **halts** with no conditional edge (`marathon.sh:214-226`, nine exit codes → nine halt reasons); and **`Wave` appears in no executor** — only the renderers (`utils/marathon-plan.sh`, `utils/py/_marathon_plan.py`) and reporting (`utils/hq/marathon-scan.sh`). What *does* match is the micro level: nodes with LLM bodies, a genuine LLM-selected edge (`relay_drive.py:278`, reviewer `STATUS:` → terminal or another round), gates that must be able to start before turn 1, and an inspectable state machine. Graph-shaped inside a phase, deliberately not between them — `swarm-preflight.sh:28-29` / GUIDING-PRINCIPLES §8 hand scheduling to the operator. Names the shared root of three open issues: **#354** (parallel stages; its own Phase 0 found the lock excludes marathon↔marathon but silently not marathon↔relay or relay↔relay), **#359** (wave grouping asserted in prose, unverifiable — sharper once the waves never execute), **#391** (the chain is hand-transcribed, so the graph is authored twice and only one copy runs), plus **#396**'s conflict-as-signal restated: disagreement escalates on a *count* rather than routing on substance. Ships the README FAQ; changes nothing in the model; makes "should XYZ execute a DAG?" an explicit decision downstream of #354's Phase 4 gate. cx/risk/eff 2/1/1 (provisional). → [GH-435-COORDINATION-MODEL.md](PROJECT/1-INBOX/GH-435-COORDINATION-MODEL.md) · [#435](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/435)
ROADMAP.md-84-- **GH-396 · Accuracy Ledger — design constraints to settle before build** 🆕 **captured 2026-08-01** — four constraints recorded before the Ledger exists, from a contributor thread on the Mythos cryptanalysis results whose framing (a model "routing around its constraints") did not survive reading the published run — Claude edited a harness it already had write access to, which is strategy adaptation in-lane, not evasion. What is real: **(1) placement** — the Ledger lives outside every agent-writable path (#50's pillar 2 one level up), and since `rtl_enforce` deliberately skips gitignored files (`relay-turn-lib.sh:1011-1015`), a Ledger under `.tick/` would get *zero* containment — decide tracked-path-vs-close-the-gap up front; **(2) observed vs. declared writes** — `oracle-guard.sh` asserts `ALLOW_PATHS ∩ ORACLE_PATHS = ∅` from CSV lists and never observes what was written, the same declared-trust-vs-actual-execution class as #390, and **PR #393 does not close it** (resource caps only), though `rtl_enforce()` and `requires_test_delta()` are existing reuse candidates; **(3) external ground truth** — our only oracle is the pre-advance gate plus an opt-in `requires_test` that asserts a path merely *changed*, over a gate defaulting to the target's own `validate.sh` (GH-238), i.e. the workpiece — so the Ledger cannot be more trustworthy than its oracle and #390 is necessary but not sufficient; **(4) an untested premise** — per-advisor calibration assumes uncorrelated advisors, but `consult.sh:287` is `(codex agy gemini aider)` where `gemini` is a legacy alias for `AGY_BIN` (a default panel may be one binary twice), `claude` is a builder not an advisor, and `aider` is an OpenRouter harness — cheap divergence replay proposed, but **not** against `.tick/`, whose schema carries no verdict/status/finding field (`src/events.js:12-30`), so it runs on `relay-system/**` transcripts or waits on new emission. Also names one thing buildable now with no Ledger: relay disagreement escalates on a **count** (`relay_drive.py:439,620` → `cap-or-close-mismatch`) rather than on the substance of the dispute. Nothing implemented; the Ledger, reflection pipeline, and semantic-oracle wiring stay future-tense per the #40 post-close review. cx/risk/eff 3/2/3 (provisional). → [GH-396-ACCURACY-LEDGER.md](PROJECT/1-INBOX/GH-396-ACCURACY-LEDGER.md) · [#396](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/396)
ROADMAP.md-85-- **GH-343 · a target-relative gate program is checked against cwd/PATH instead of `target_root`, so a ready contract reports NOT-READY** ✅ **BUILT 2026-08-08 in the Litmus marathon — agy-approved, full gate passed (715s). Took THREE builds, and the first two failures were the PLAN's fault.** Acceptance criterion 3 ("a gate script **or** program that … is not executable sets NOT-READY, rather than passing readiness and failing at execution time") had a FALSE premise for the interpreter branch: `bash foo.sh` runs a mode-644 file fine. Two independent codex builds implemented it literally and both regressed `test/swarm-preflight.sh` **98/0 → 91/7** (T15/T33/T36). `chmod +x`-ing the fixtures would have shipped a NEW false NOT-READY for `gate: "bash validate.sh"` in any repo whose `validate.sh` is 644 — the lane shipping the bug it exists to fix. Criterion 3 was narrowed on the issue (operator-approved) to **directly-executed** programs only; the third build then produced the correct split — `isfile` alone on the interpreter branch, `isfile` + `X_OK` on the separator-containing program branch — first try. Same builder, same lane; only the criterion changed. **preflight READY, awaiting operator go** — the `bash`/`sh` branch joins the gate script onto `target_root`; the program branch calls `shutil.which()`, which for a separator-containing string tests it against the **process's** cwd. So the identical contract is `ready (exit 0)` from the target repo and `NOT-READY (exit 5)` from the harness clone, with the message blaming PATH. **A false NOT-READY silently drops an issue from a sweep** — `/10days` Step 6 treats any non-zero exit as a reason to drop, and exit 5 is indistinguishable from a real verdict. **Not a GH-308 regression:** the old exemption list never covered a target-relative interpreter, so it failed identically before. Criteria were **authored onto the issue** (it had none) and then **revised after a codex+agy review that found the original satisfiable by making the CORRECT branch wrong** — *"the two branches agree"* is met by resolving both against cwd. cx/risk/eff 2/1/2, 2 phases. → [GH-343-GATE-PROGRAM-TARGET-ROOT.md](PROJECT/3-COMPLETED/GH-343-GATE-PROGRAM-TARGET-ROOT.md) · [#343](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/343) · [#419](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/419)
ROADMAP.md-86-- **GH-378 · a marathon can only run against a repo whose suite is already green** 🆕 **captured 2026-08-10 for release 0.3.0 Nightwatch, doc drafted, NOT yet preflightable — its central design question is open** — `marathon.sh` takes ONE `--pre-advance-cmd` for a whole run, so the global gate is the full suite, and a marathon exists to work on repos whose suites are not green. Measured on rebalance-OS: all 9 lanes' own scoped gates pass, the full suite is red 5/1587, and the failures are unrelated to any lane. It bit this repo twice on 2026-08-10 — both Nightwatch waves halted an already-**Approved** phase on a red that had nothing to do with the lane. **The blocker is sharper than "parsing arbitrary gate output is hard":** `run_pre_advance_gate()` calls `subprocess.Popen(...)` with **no `stdout=`/`stderr=`** (`utils/py/marathon_drive.py:1352-1353`), so the driver retains **only an exit code** — there is no output for any baseline-allowance scheme to parse, and every option is gated behind a capture change first. The doc deliberately does **not** pick a design; it enumerates them and records the choice as the operator's. **Can never be a marathon lane** — it edits the live driver that would be gating its own change. cx/risk/eff TBD. → [GH-378-GATE-REQUIRES-GREEN-SUITE.md](PROJECT/2-WORKING/GH-378-GATE-REQUIRES-GREEN-SUITE.md) · [#378](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/378)
ROADMAP.md-87-
--
ROADMAP.md-98-- **GH-402 · a marathon commits to whatever branch the target has checked out, and the `marathon/<slug>` branch is advisory text nothing enforces** 🆕 **captured 2026-08-10 for release 0.3.0 Nightwatch — the issue names one of two failure directions, and the MISSING one reproduced LIVE during this doc's own drafting** — direction A (the issue's): nothing in the ready/verdict computation references branch or dirty state, and `--require-clean` is opt-in (`utils/py/marathon_drive.py:1735`). Direction B (unnamed): a run **leaves** the shared clone parked on a non-trunk branch, so a later unrelated commit silently lands there — `skills/10days/SKILL.md:381-382` cuts `marathon/10days-<today>` and never restores, and `CHANGELOG.md:239` already admits the clone "can be left … parked on a `marathon/*` branch". **On 2026-08-10, while this very doc was being written, a concurrent process moved the shared root from `development` (`d121cac`) to `feature/agent-devtools-fuzzing` (`68ade4d`) mid-session with no signal; the next commit would have landed all 11 Nightwatch capture docs on the fuzzing branch, silently, with every gate green.** Batch 2 was landed from an isolated worktree pinned to `development` instead — a workaround, not a fix. **The issue's proposed fix makes direction B more likely**, since its remediation is to hand-cut a `marathon/*` branch. Root cause is design, not oversight: `PROJECT/3-COMPLETED/GH-69-MARATHON-BRANCH-PROMPT.md:40-41` shows this was built as a human-in-the-loop prompt, an assumption that breaks unattended. Nine of the issue's file:line citations have drifted. Phase 1 touches the running driver — **direct PR only.** cx/risk/eff 3/4/3. → [GH-402-MARATHON-BRANCH-ENFORCEMENT.md](PROJECT/2-WORKING/GH-402-MARATHON-BRANCH-ENFORCEMENT.md) · [#402](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/402) · [#69](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/69)
ROADMAP.md-99-
ROADMAP.md-100-- **GH-492 · agy hangs headless with no CPU and no progress, and its only pre-flight warning fires on every turn** ✅ **BUILT 2026-08-10/11 — both surfaces done. Captured for release 0.3.0 Nightwatch — operationally urgent: agy is the reviewer half of the cross-model QA pipeline and it failed TWICE on 2026-08-10** — the 900s bound is **wall-clock only** (`utils/py/agy-turn.py:246` `subprocess.run(..., timeout=…)`); `TurnDiagnostics.classify()` runs post-hoc at `:301`, after `TimeoutExpired` already fired at `:247`, so nothing detects a process burning wall clock at zero CPU. The TTY warning is unconditional in headless mode (`utils/py/rtl.py:39-96` returns `"unverifiable"`, and headless always has `stdin=DEVNULL` at `agy-turn.py:22`), so the one available signal cannot distinguish a hang from three healthy runs. **The scope gap neither the issue nor the title names:** `utils/py/consult.py` — where the SECOND failure actually happened — has **zero** `TurnDiagnostics` (`agy-turn.py` has 2 references, `consult.py` has 0) and its own older 300s `CONSULT_TIMEOUT` (`:374`); implementing only in `agy-turn.py` leaves that surface exactly as blind. `consult.py` also lacks the empty-output guard `agy-turn.py:307-313` has — a distinct, unreported silent-success gap. Restored 2026-08-10 by an interactive `agy login`, itself the evidence: the failure was an expired auth session headless mode could not report as such. **This host has no GNU `timeout`/`gtimeout`**, so any fix assuming `timeout(1)` will not run here. **Built:** `TurnDiagnostics.idle_seconds()` measures forward from the last CPU growth or file write; `agy-turn.py` now bounds the turn by BOTH an idle threshold (`RELAY_TURN_IDLE_S`, default 300s, `0` disables) and the wall cap, killing the whole process group. The blocking `subprocess.run(timeout=)` became an explicit poll loop, because a blocking call cannot consult the sampler measuring it. `test/gh492-idle-kill.sh` 9/0 — and the **negative control is the point**: a slow-but-progressing turn measured 0.06s idle against the blocked turn's 4.09s. Proven falsifiable behaviourally, not just by a missing symbol: dropping worktree progress from the idle signal makes the control fail 2/9, which is exactly what a trigger-happy bound looks like. Criterion 3 was met WITHOUT touching the kernel — the every-turn `WARNING` is demoted to a one-line `NOTE` and re-raised in full only on the failure path, where an unverifiable auth probe is a live hypothesis rather than noise. Criterion 4 is satisfied by RECORDING the finding: no reliable headless agy probe exists and none is shipped, per GH-375's measured cost. **consult.py now covered too** — the surface where the SECOND 2026-08-10 failure actually happened. It needed a distinction a turn shim never does: a consult launches every advisor as a SIBLING under one parent inside ONE shared worktree, so measuring the parent sums all advisors and a fast codex answer masks a hung agy. `TurnDiagnostics` gained an explicit `root_pid` and now accepts a FILE as the progress signal, so each advisor is scoped to its own subtree and its own transcript. The test pins the masking BOTH ways — correctly scoped sees 2.99s idle, shared-parent scope sees 0.14s — so it cannot pass on a build where scoping does nothing. `CONSULT_IDLE_S` default 90s, `0` disables. Live consult re-run after the change: 1 answered, 0 failed, no false kill. 16/0. cx/risk/eff 4/4/4. → [GH-492-AGY-IDLE-HANG-DETECTION.md](PROJECT/2-WORKING/GH-492-AGY-IDLE-HANG-DETECTION.md) · [#492](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/492) · [#390](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/390) · [#414](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/414)
ROADMAP.md-101-
ROADMAP.md:102:- **GH-376 · relay-drive and marathon-drive take different locks from a linked worktree, so their mutual exclusion does not exist** ✅ **SHIPPED 2026-08-11 (direct PR) — the fix was "adopt the resolver that already shipped", not "write one"** — both twins now call GH-448's shared resolver; `test/gh376-relay-drive-lock-parity.sh` 18/0 against a real `git worktree add`, with the pre-fix resolution replayed on BOTH lanes and observed sailing past a held lock, plus normal-clone and vendored controls and source guards pinning that the resolver is called rather than re-inlined. **Confirmed live, not only in fixture:** a marathon in a sibling clone (pid 39588) held the lock in this repo's common `.git/`, and post-fix `poll-relay` + `relay-escalation-not-stall` correctly refuse from a linked worktree (both 12/0 and 5/0 in a standalone clone) — the exact collision the issue describes, occurring by accident during its own fix. Consequence now documented: the suite can no longer run from a linked worktree while a driver holds the main clone's lock, which pre-fix it could *because* the worktree got its own private lock. Original capture below. — GH-448 (PR #449) shipped a proven 3-branch resolver, `driver_lock_path` (`utils/py/rtl.py:477`), plus a Bash twin; `utils/py/marathon_drive.py` imports and uses it (`:20`, `:611`) and **`utils/py/relay_drive.py` does not** — it still hand-rolls a 2-branch version at `:385-391` keyed on `os.path.isdir(root/.git)`, which is **false in a linked worktree** (there `.git` is a file), so the two drivers resolve different paths and neither excludes the other. GH-448's own doc explicitly scoped this out as "sibling issue #376". Also found: `rtl.py`'s docstring claims to match relay_drive's resolution too — currently false, a second stale comment in the same area. Traced why it only bites standalone: `marathon_drive.py:649` sets `RELAY_DRIVER_LOCKED=1` before invoking relay-drive, making it skip its own buggy acquisition — so the real collision is two independently-launched top-level drivers, not marathon's internal chaining. `relay-drive` is the per-turn subprocess the driver re-execs every turn, so the write-set is self-modifying in substance — **direct PR only.** Frozen-twin pair #8; Bash edits need a `Frozen-twin-exception:` trailer. cx/risk/eff 2/3/2. → [GH-376-RELAY-DRIVE-LOCK-PATH-DIVERGENCE.md](PROJECT/2-WORKING/GH-376-RELAY-DRIVE-LOCK-PATH-DIVERGENCE.md) · [#376](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/376) · [#448](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/448)
ROADMAP.md-103-
ROADMAP.md-104-- **GH-386 · `claude-turn` caps at 600s while every other builder defaults to 900s, and the computed `RELAY_TURN_TIMEOUT_S` is never wired through** 🆕 **captured 2026-08-10 for release 0.3.0 Nightwatch — both halves still reproduce, but the issue mis-states the second one in a way that would have sent the fix into an unfireable file** — (a) confirmed: `utils/py/claude-turn.py:97` defaults **600**, while `agy-turn.py:205`, `codex-turn.py:73` and `pi-turn.py:105` all default **900**; no rationale comment at either claude twin. (b) the issue says "marathon.sh does not read the packet's suggestion" — **false as stated**: `relay-automation/marathon.sh:236-238` DOES export `RELAY_TURN_TIMEOUT_S` when a phase sets `turn_timeout_s:`, and `bin/marathon-yaml` carries the field end to end (both wave-2 phases set `900`). The real gap is only the last hop: **nothing auto-populates that field from swarm-preflight's computed number** (`utils/py/swarm_preflight.py:1535` prints it to `packet.md` and stops), so a plan author hand-transcribes it. That correction matters operationally — taken at face value the fix lands in `marathon.sh`/`marathon_drive.py` and is **unfireable by the self-modification rule**; steered into `marathon-plan` instead, it stays a legal marathon lane. A 2026-07-31 issue comment establishes the 600 value's lineage via GH-320 — deliberate per-file, just undocumented cross-shim. Line citations drifted up to 652 lines. No acceptance criteria on the issue; authored separately. cx/risk/eff 2/2/2. → [GH-386-CLAUDE-TURN-TIMEOUT-ASYMMETRY.md](PROJECT/2-WORKING/GH-386-CLAUDE-TURN-TIMEOUT-ASYMMETRY.md) · [#386](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/386) · [#387](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/387) · [#320](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/320)
ROADMAP.md-105-
ROADMAP.md-106-- **GH-379 · a budget-exhausted claude builder is escalated as `pre-advance-failed` and its own error text is discarded** 🆕 **captured 2026-08-10 for release 0.3.0 Nightwatch — the headline already shipped in GH-407; only a propagation step remains** — the title-level complaint no longer reproduces: `utils/py/marathon_drive.py:2058` now escalates `relay-failed-before-gate` when the gate never ran, distinct from `pre-advance-failed` when it ran and failed, and `test/gh407-gate-ran-attribution.sh` pins it with a **pre-fix replay** inside the fixture. The "error text is discarded" half is stale for the path that actually runs: `utils/py/claude-turn.py:72` persists via `rtl_default_log()` (commit `7812710`, 2026-07-31 — one day AFTER this issue was filed, in direct response to the same panic run). The quoted `$TMPDIR/claude-turn-<pid>.json` is real only on the **frozen Bash twin** (`relay-automation/claude-turn.sh:159`). What genuinely remains: nothing copies `subtype`/`terminal_reason` forward into `ESCALATION.md`. Deliberately **not merged** with #408/#409 — #408 is *active suppression* (`stderr=DEVNULL`), this is a *missing propagation* of data already persisted; cousins pointing at the same absent reason-channel, not one bug. Bonus defect found: `claude-turn.sh:46` documents defaults of `20` turns / `2.00` budget while `:175-176` sets `12` / `0.50` — its own header contradicts its own code, twice. Driver touch — **direct PR or supervised relay, not an automated lane.** cx/risk/eff 2/2/2. → [GH-379-CLAUDE-BUILDER-DIAGNOSIS-SURFACING.md](PROJECT/2-WORKING/GH-379-CLAUDE-BUILDER-DIAGNOSIS-SURFACING.md) · [#379](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/379) · [#407](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/407) · [#408](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/408)
--
ROADMAP.md-108-- **GH-380 · a claude builder silently ignores the target repo's permissions unless the directory was pre-trusted** 🆕 **captured 2026-08-10 for release 0.3.0 Nightwatch — the issue describes the DEAD half of a frozen twin pair** — its evidence table says the warning lands in `$TMPDIR/claude-turn-<pid>.json` and is "never copied into the phase directory". True of `relay-automation/claude-turn.sh:159`, the **frozen Bash** shim; **false of the path that actually runs** — `utils/py/claude-turn.py:72` → `rtl_default_log()` (`utils/py/rtl.py:307-324`) already writes to a persistent in-repo `relay-system/logs/<date>/…` path as of `7812710`, confirmed an ancestor of HEAD. So the issue's suggested fix #4 ("preserve the turn log") is **already shipped** and is scoped out. The core defect stands untouched: nothing surfaces the trust *warning line itself* anywhere operator-visible, so a builder degrades to default permissions silently. Verified orthogonal to the separate "claude not headless" gap — `marathon_drive.py:238-260`'s binary probe (GH-117) fail-fasts before any tick mutation but is PATH-only, never trust-aware. Write-set is the Python half only — **no `Frozen-twin-exception:` trailer needed, and this one CAN run as a marathon lane.** Issue has no acceptance criteria; five authored separately. cx/risk/eff 2/2/2. → [GH-380-CLAUDE-BUILDER-TRUST-SILENT-DEGRADE.md](PROJECT/2-WORKING/GH-380-CLAUDE-BUILDER-TRUST-SILENT-DEGRADE.md) · [#380](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/380)
ROADMAP.md-109-
ROADMAP.md-110-- **GH-382 · a marathon reports tokens and wall-clock but no memory — an unattended run ended in a kernel panic with no signal in the telemetry** 🆕 **captured 2026-08-10 for release 0.3.0 Nightwatch — the issue is accurate; a SIBLING DOC is what's wrong** — `src/analyze.js:550-566` / `computeCost()` at `:363-385` carry zero references to memory, rss, swap, compressor or `vm_stat`, exactly as claimed. But `PROJECT/2-WORKING/GH-390-GATE-GUARD-COVERAGE.md:99` asserts a host-pressure floor "shipped in PR #393", and it did not — contradicted by `utils/py/marathon_drive.py:1320` ("Layer 4 (host free-memory floor) … are Phase 2") and by the shipping commit's own title (`94cafc9`, "Phase 1 — layers 1-3"). Flagged so nobody builds on the sibling doc's claim. A trap a plausible-but-wrong fix would walk into: the gate ALREADY computes a peak-RSS number and then discards it, log-only (`marathon_drive.py:1397-1403`). Pairs with GH-392, which publishes the **static** sizing guidance measured from this very crash; #382 is the **runtime** counterpart and neither substitutes for the other. Write-set almost certainly includes the running driver plus `relay_drive.py` — **direct PR only.** cx/risk/eff 3/3/3. → [GH-382-MARATHON-MEMORY-TELEMETRY.md](PROJECT/2-WORKING/GH-382-MARATHON-MEMORY-TELEMETRY.md) · [#382](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/382) · [#392](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/392) · [#390](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/390)
ROADMAP.md-111-
ROADMAP.md:112:- **GH-384 · no recovery path after an interrupted marathon — a crash leaves a clean tree containing ungated commits, and nothing reports it** 🆕 **captured 2026-08-10 for release 0.3.0 Nightwatch — scoped deliberately so it CAN be a marathon lane** — the mechanism the issue asserts but never explains: the turn's commit lands at `relay-turn-lib.sh:1144`, `run_pre_advance_gate()` runs later at `marathon_drive.py:1557`, and `phase.approved` is logged only after the gate passes at `:1580` — so an interruption in that window is structurally an ungated commit. Two issue claims corrected: the `phases/<plan>--p*/` residue row is stale (**GH-484 flipped the default phase-output dir to `marathon-system/`** the same day — `marathon_drive.py:697-700`, `marathon.sh:174-178`; the old path survives only as a fallback in the two monitors), and "no tooling reports phase state" is an overstatement — `marathon-ls.sh` and `marathon-detail.sh` already report driver-lock LIVE/STALE/IDLE and `STATUS:`/`NEXT:`. The genuinely missing thing is narrower and worth stating exactly: **no tool cross-references "phase Open + a commit exists + no `phase.approved` ever landed".** The issue's own suggestion 1 (`marathon --status/--recover`) would edit the running driver and be unfireable, so acceptance is scoped to a **new standalone script** instead — which keeps it a legal lane. Depends on #388 for a durable record to recover FROM. No acceptance criteria on the issue; authored separately. cx/risk/eff 3/2/3. → [GH-384-MARATHON-CRASH-RECOVERY.md](PROJECT/2-WORKING/GH-384-MARATHON-CRASH-RECOVERY.md) · [#384](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/384) · [#388](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/388) · [#387](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/387)
ROADMAP.md-113-
ROADMAP.md-114-- **GH-467 · a builder is told "Do NOT run git", so a lane whose deliverable is an index change cannot perform its own work** 🆕 **captured 2026-08-10 for release 0.3.0 Nightwatch — the ban is PROTECTIVE, so the fix is not "remove it"** — the packet text is verbatim at `relay-automation/marathon-drive.sh:1017,1023` and `utils/py/marathon_drive.py:1757,1772`, and the rationale is real and documented (`relay-turn-lib.sh:1026-1053`, `PROJECT/3-COMPLETED/RELAY-CONTAINMENT-HARDENING.md:31`): the harness performs the commit itself, and a builder committing mid-turn has previously reset HEAD and orphaned a peer agent's commit. The issue deliberately declines to choose among three shapes ("Not choosing here"), so criteria were authored for **option 3 only** (declare the intent, let preflight refuse) — chosen because options 1 and 2 touch the driver and the kernel respectively and could never be marathon lanes, while option 3's write-set is `utils/py/swarm_preflight.py` alone and **can** be. Key fact the issue omits: `lanes.orchestrator_only` already exists (`swarm_preflight.py:199-234`) but is **advisory-only — nothing outside that file reads it**, so "preflight refuses to dispatch" is new behaviour, not existing. Also: no test asserts the ban string's presence, so a fix should add a regression guard against silently weakening it. The #466 workaround is confirmed in `git log` (`81b3127` untracked `phases/p1/RELAY.md` by hand). cx/risk/eff 3/3/3. → [GH-467-INDEX-ONLY-LANE-GIT-BAN.md](PROJECT/2-WORKING/GH-467-INDEX-ONLY-LANE-GIT-BAN.md) · [#467](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/467) · [#466](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/466)
ROADMAP.md-115-
ROADMAP.md-116-- **GH-358 · the 16-way concurrent-append lock assertion flakes on the shared CI runner** 🆕 **captured 2026-08-06 for release 0.2.0 Litmus, preflight READY, awaiting operator go** — a flaky **lock** test is the one kind that cannot be waved off: *"flaky"* and *"the lock genuinely loses a write under contention"* produce an identical symptom, so neither verdict is currently evidence. The review added two findings verified against the tree: **every appender's exit status is discarded** (`wait "$p" 2>/dev/null || true`, in two places), so a crashed appender is indistinguishable from a lost record; and **two different lock bounds are in play** — the test's own wait and the writer's `XYZ_LOCK_WAIT_S` default — so a report naming "the timeout" is not actionable. Instrument first, decide after; **`M` stays 16 and the distinctness check stays**, both of which only make the symptom disappear. cx/risk/eff 2/2/2, 2 phases. → [GH-358-LOCK-FLAKE-INSTRUMENTATION.md](PROJECT/2-WORKING/GH-358-LOCK-FLAKE-INSTRUMENTATION.md) · [#358](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/358) · [#419](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/419)
--
ROADMAP.md-130-- **GH-400 · `/10days` capture docs restate a GitHub issue's acceptance criteria instead of copying them — a measured case inverted one, and the marathon delivered the inversion** ✅ **SHIPPED 2026-08-03 (PR #413, `d06139c`); closed — re-verified before registering** — Step 4 has a model summarise an issue into `PROJECT/2-WORKING/`, and everything downstream (preflight → packet → relay file → builder → reviewer) reads the **summary**, never the issue; nothing compares the two. Independently re-derived from both source repos rather than taken on the report's word: `rebalance-OS` #202 requires the malformed row be *"never silently dropped"*, the capture doc requires asserting *"the actual current behavior (drop the row…)"*, and the delivered test (`3673257f`, reproduced identically by a second run at `7525d047`) adds a function named **`malformed_source_row_is_dropped`** — every quoted string matches byte-for-byte, and the delivered artifact is worse than reported. Two criteria were dropped outright, including the one written specifically to prevent what shipped. **No downstream role can catch it**: builder and reviewer both read the packet, so no undamaged copy of the requirement exists anywhere in the pipeline — every gate was green and the phase closed. Not a source-material problem: 9 of 9 sampled issues carry an explicit `## Acceptance` block; the degradation is introduced in translation. **Two corrections to the report:** its suggested fix leans on *"preflight already fetches the issue"* — **it does not**, neither twin invokes `gh` at all, so the gate must introduce the first body-fetch into that path and carry its own offline contract; and companion **#399** cites `utils/swarm-preflight.sh:882`, which GH-308 **froze** — the line that actually runs is `utils/py/swarm_preflight.py:844`. Fix is a copy-not-restate skill contract, an explicit deviations section, and a preflight check that hard-fails on unexplained divergence while reporting `unknown` (never blocking) when the issue is simply unreachable. cx/risk/eff 3/3/3. → [GH-400-CAPTURE-DOC-ACCEPTANCE-FIDELITY.md](PROJECT/3-COMPLETED/GH-400-CAPTURE-DOC-ACCEPTANCE-FIDELITY.md) · [#400](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/400) · [#399](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/399) — **criterion 2 closed 2026-08-04**: it had shipped as prose only (`SKILL.md` told the model to set `source:`; no gate read the field), so `source: issue#400` or no `source:` at all passed everything — this issue's own defect inside its own fix. `check_source_url()` now hard-fails NOT-READY on a doc that does not cite its issue's URL; blast radius measured at 1 of 48 before choosing the posture, and that one doc fixed in the same commit. `test/gh400-source-url.sh` **13/0**, observed **2/11** pre-fix. All four criteria met.
ROADMAP.md-131-- **GH-381 · `/Releases` rolling release-train planner** 🆕 **captured 2026-07-30** — proposal for a preview-first planning skill that lays out 4–5 upcoming releases, each with four or five explicit iteration slots, and hands one bounded milestone-derived iteration to `/10days` without duplicating the `RELEASES.md` ledger or GitHub issue membership. → [GH-381-RELEASES-ROLLING-TRAIN.md](PROJECT/1-INBOX/GH-381-RELEASES-ROLLING-TRAIN.md) · [#381](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/381)
ROADMAP.md-132-- **GH-351 · the registered dashboard gate graded its own answer key** ✅ **done (2026-07-30)** — `test/roadmap-dashboard.sh` rendered the dashboard **into the repo** and then `--check`ed the copy it had just written, so its drift assertion could never fail; its own pass string read *"--check passes on the committed artifact"*, which was false by the time it ran. **The renderer was never the defect** — standalone `utils/roadmap-dashboard.sh --check` returned `rc=1` on all three of the day's stale dashboards, so the correct signal existed the whole time and the test overwrote its input before asking. A second, quieter fault: the test **wrote into `$ROOT`**, so `validate.sh` silently un-staled the dashboard mid-run — a suite repairing the evidence it was meant to judge, and leaving the tree dirty. Three stale dashboards reached `development` on 2026-07-30 alone from three different authors (GH-342, #356, #350); it fires on essentially every ROADMAP-touching PR. Fixed by two rules: `--check` runs **first** against the **committed** artifact, and nothing writes `$ROOT` (write-mode goes through `ROADMAP_DASHBOARD_OUTPUT`, which the renderer already supported — no renderer change). **4 → 9 cases**, including a mutation proof (case 4 plants a canary and requires `--check` to reject it, since cases 1 and 3 are unfalsifiable alone) and a no-side-effect assertion. **Verified against the real commit, not a synthetic fixture:** replaying `719867f`, the old test scores **4 pass / 0 fail** on a genuinely stale dashboard while the new one scores **6 pass / 3 fail**. Two findings only visible by running it — the old test left `ROADMAP-DASHBOARD.md` modified afterwards, and **case 9 (section counts) was already correct and still reported green**, because the regeneration ran first: the bug did not add a bad assertion, it *disabled a good one*. Sixth instance of *an assertion that compares a thing to a freshly-derived copy of itself* after #348/#342/#362(B)/#369. cx/risk/eff 2/2/2. → [GH-351-DASHBOARD-TEST-GRADES-ITS-OWN-ANSWER-KEY.md](PROJECT/3-COMPLETED/GH-351-DASHBOARD-TEST-GRADES-ITS-OWN-ANSWER-KEY.md) · [#351](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/351)
ROADMAP.md-133-- **GH-369 · `/10days`' capture-doc lookup hung forever on a valueless `--root`, in a skill built to run unattended** ✅ **done (2026-07-30)** — found reviewing PR #364 before merge; that PR's own GH-344 fix is correct and shipped, these are defects in the argument parser it introduced. `shift 2` with one argument left shifts nothing and returns non-zero, and `find-doc.sh` is deliberately `-e`-exempt, so `$#` never decreased, `$1` stayed `--root`, and the loop re-entered forever — confirmed at **rc=142/SIGALRM** under an `alarm(5)` wrapper. The severity is not the malformed call but the *shape*: `/10days` runs unattended, so this stalls a sweep with no error, no output and no timeout — the absent-signal class of #315/#319/#351, not a wrong answer. Second defect: a bad `$TENDAYS_ROOT` reported `--root not a directory:`, naming a flag never passed and printing an empty path; the resolver now records which of its four sources supplied the value. (My first fix repeated the same class — printing `$ROOT`, already emptied by the failed substitution — kept as `$ROOT_RAW`.) **The durable half is coverage**: the file had *no* test and was absent from `validate.sh`'s `TESTS=()`, which is why both defects and GH-344's resolution order shipped unguarded. New `test/gh369-find-doc-root-resolution.sh` **14/0**, hang-capable cases under a hard `alarm` cap so a regression fails the gate instead of hanging it. Observed failing against **both** prior revisions: **12/2** vs pre-fix (exactly cases 1–2), **4/10** vs pre-#364 (case 6: *"answered GH-163 from the HARNESS tree"*). **Case 6 was wrong first** — it probed an issue absent from both trees, so bug and fix both returned `null` and it passed against the code it existed to catch; a fifth member of the *assertion that cannot distinguish the bug from the fix* family after #348/#342/#351/#362(B). cx/risk/eff 2/2/1. → [GH-369-FIND-DOC-ARG-PARSE-AND-ROOT-RESOLUTION.md](PROJECT/3-COMPLETED/GH-369-FIND-DOC-ARG-PARSE-AND-ROOT-RESOLUTION.md) · [#369](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/369)
ROADMAP.md:134:- **GH-354 · concurrent swarms: the driver lock blocks 1 of 3 pairs, and the monitors can't see the one it does** 🟡 **active — Phase 0 discovery complete 2026-07-30; Phase 1 (relay-drive worktree lock) next** — review of [#354](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/354)'s own analysis, which reasoned about `relay-drive.sh`/`relay-turn-lib.sh` from `marathon-drive.sh`'s comments because it lacked the files. Reading them overturns the conclusion's basis: `relay-drive` never received GH-49b's linked-worktree lock branch on **either** runtime (`relay-drive.sh:147-152`, `utils/py/relay_drive.py:386-391`), so it takes a per-worktree lock while `marathon-drive` takes a shared one — marathon↔marathon excludes, marathon↔relay and relay↔relay silently do **not**, the second being two drivers on one working tree with no guard at all. Also overturned: `.tick/` task ids, lane attempt counters and `tick analyze` cost do **not** commingle across linked worktrees (`TICK_REPO_ROOT` defaults to each shim's own `ROOT`), deleting 3 of #354's 5 collision claims and the `.tick`-namespacing work it proposed. #354's one-line observability footnote is escalated to a phase: the false-IDLE is in **three** monitors (`marathon-ls.sh:44-50`, `utils/hq/marathon-live.sh:94-95`, `utils/hq/hourly-global-scan.sh:28`), so the operator's every window onto the lock state is blind in exactly the shape under discussion. Separate full clones remains the right operator answer — for a different reason than #354 gave. Plan does **not** enable parallelism: Phases 1–3 make the exclusion contract true, provable and observable; Phase 4 is a GO/NO-GO gate whose first criterion is that nobody has ever written down the GH-42 `ROOT@HEAD` mechanism. cx/risk/eff 4/3/3. → [GH-354-CONCURRENT-SWARMS.md](PROJECT/2-WORKING/GH-354-CONCURRENT-SWARMS.md) · [#354](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/354)
ROADMAP.md-135-- **GH-347 · pi CLI installed inside another app's folder, invisible to PATH** 🆕 (2026-07-29) — found driving the GH-336 round-4 review: `find-harness.sh --check` reported `pi` absent while it was installed and working inside `~/.hermes/node`, a separate agent app's bundled Node runtime. Cause is ambient, not a typo — that app symlinked its `npm` onto PATH, so `npm config get prefix` returns its folder and a bare `npm install -g` lands our tools there silently, exit 0, with no `~/.npmrc` involved. Risk is silent loss on a foreign app's update schedule, and `--check` cannot distinguish "wiped" from "never installed" — same observation-layer disease as #315/#319. Phases 1 and 2 are **done** (2026-07-30): `pi` reinstalled via Homebrew's npm into `~/.local` (launcher now `~/.local/bin/pi`, same shape as `codex`/`agy`), removed from `~/.hermes` (132 packages), Hermes's own symlinks untouched, `test/pi-turn.sh` 39/0; and the `GUIDING-PRINCIPLES.md` convention landed. **Correction:** `find-harness.sh` never probed for `pi` at all (it exports only tick/codex/agy), so a missing `pi` gives *no* signal rather than a negative one — Phase 3 now carries adding that probe, and is no longer optional. → [GH-347-TOOL-INSTALL-PATHS.md](PROJECT/1-INBOX/GH-347-TOOL-INSTALL-PATHS.md) · [#347](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/347)
ROADMAP.md-136-- **GH-336 · planning context: phase metadata signals before deterministic marathon contracts** 🆕 — proposed three-phase, advisory-first planning context linking release alignment, delivery arc, and churn signals; ships Python-only, default-off, writing a sidecar so the plan doc is byte-identical in every mode. Release alignment delegates to `utils/release-lanes.sh seed|rollup` (#330) rather than re-deriving scope. Relay-reviewed across 4 rounds / 3 models (codex, agy, pi+qwen) → Approved at r3, re-opened at r4 which overturned two criteria. **Re-tested 2026-07-30 (GH-370):** all four rounds cited `_marathon_plan_node.js`, which #340 deleted — 7 of 8 findings hold, and the 5 stale/false claims are corrected. → [GH-336-PLANNING-CONTEXT.md](PROJECT/1-INBOX/GH-336-PLANNING-CONTEXT.md) · [#336](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/336) · [#370](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/370)
ROADMAP.md-137-- **GH-320 · the executing Python lane caps turns at a third of the documented budget** 🆕 (2026-07-28) - found when it killed the agy review turn for PR #318: `agy -p exceeded 300s wall-clock cap`, on a shim whose header and code both say **900**. XYZ has been Python-default since GH-264, so `agy-turn.sh` `exec`s `utils/py/agy-turn.py` — which defaulted to **300**. Same split in `codex-turn` (900↔300) and `claude-turn` (600↔300); `aider-turn`/`pi-turn` were consistent. The failure surfaces as `exit 7` *(turn timeout / hang)*, which reads as a hung model rather than a misconfigured ceiling — and the natural response, retrying, burns another turn at the same wrong cap. **GH-308's freeze does not cover this**: freezing the twins stops them drifting *forward* and says nothing about values that had already diverged. Fixed by aligning the three Python defaults, plus `test/gh320-twin-timeout-parity.sh`, which reads the default from **both** files rather than hardcoding an expectation (a third copy would be a third thing to drift) and separately asserts each Bash header's documented `(default: N)` matches its own code. Open follow-on for GH-308 Phase 2: nothing establishes the turn timeout was the only constant that diverged. Issue [#320](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/320). -> [PROJECT/3-COMPLETED/GH-320-TWIN-TURN-TIMEOUT-DRIFT.md](PROJECT/3-COMPLETED/GH-320-TWIN-TURN-TIMEOUT-DRIFT.md)
ROADMAP.md-138-- **GH-319 · the marathon pre-advance gate word-splits a spaced repo path and passes on the wrong file** 🆕 (2026-07-28) - found while verifying the 2026-07-27 marathon by direct inspection instead of trusting its exit code. `utils/py/marathon_drive.py` interpolated the default gate **unquoted** into a `shell=True` command, so at `.../GH Repos/xyz-3-agents-swarm` the shell ran `bash $HOME/Documents/GH` — an unrelated **0-byte file** — exiting 0 in 0.0s with no output. All four phases logged `STATUS: Approved, gate passed` while `bash validate.sh` was in fact RED. Timing was the tell: 6.6s/7.5s from `agy-done` to `phase.approved` against a **483s** real suite. GH-238's gate-runnable preflight did not catch it — its `(\S+)` regex captured the same wrong fragment and `isfile()` on the decoy returned True, so **the guard and the gate agreed on the wrong file**. Third instance of one failure class after [#315](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/315) and the sandboxed-liveness gap: a broken observation layer where failure is invisible. Fixed with `shlex.quote` + `shlex.split`; `test/gh319-gate-path-with-space.sh` plants the same 0-byte decoy at the split point and was observed **failing pre-fix** (driver printed "gate passed", exit 0, while the fixture gate exited 1) and passes 6/0 post-fix. `relay-automation/marathon-drive.sh:493` has the identical defect and is **deliberately left unpatched** — GH-308 froze it in the same PR — so `XYZ_PYTHON=0` at a spaced path retains a fake gate until Phase 2 retires the twin. Issue [#319](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/319). -> [PROJECT/3-COMPLETED/GH-319-MARATHON-GATE-PATH-WORD-SPLIT.md](PROJECT/3-COMPLETED/GH-319-MARATHON-GATE-PATH-WORD-SPLIT.md)
--
ROADMAP.md-153-- **GH-276 · Weekly risk-control reconciliation — keeping GH-275 on the ball** 🆕 **captured 2026-07-22** — recurring, comment-based evidence review that reconciles the live `development` branch, GitHub state, PDDA docs, containment/parity incidents, vendor drift, and recovery controls without becoming a second plan or auto-firing work. → [GH-276-WEEKLY-RISK-RECONCILIATION.md](PROJECT/1-INBOX/GH-276-WEEKLY-RISK-RECONCILIATION.md) · [#276](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/276)
ROADMAP.md-154-- **GH-275 · Long-Term Risk Remediation — balanced, evidence-led safety program** 🆕 **captured and reconciled 2026-07-22** — umbrella residual-risk register, rewritten as a six-phase actionable checklist after a timed rescan of `development`; reuses existing issues, treats shipped work as controls, caps committed work at three proof-sized lanes, and delegates weekly drift checks to GH-276. → [GH-275-LONG-TERM-RISK.md](PROJECT/1-INBOX/GH-275-LONG-TERM-RISK.md) · [#275](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/275)
ROADMAP.md-155-- **GH-274 · marathon-drive: re-invoking a phase whose tick token is already done clobbers RELAY.md's Approved record instead of detecting a satisfied lane** 🆕 **found live 2026-07-21 during GH-273 Phase 0's real fire** — the relay succeeded (Codex builder, agy reviewer, Approved), the `bash validate.sh` pre-advance gate flaked on an unrelated pre-existing test, and retrying via `marathon-drive.sh` re-rendered `RELAY.md` back to `STATUS: Open` and failed on the already-`done` tick token (can't reopen), discarding the accurate Approved record — recovered manually via `git revert`. Fix direction: extend the existing GH-207 satisfied-lane detection to also cover "gate failed after an already-terminal relay," not just its current mid-relay reroute case. Not blocking — a distinct `--phase-id` per fire avoids the collision entirely (confirmed live during GH-273 Phase 1's fire), but `swarm-preflight`'s suggested command never varies it, so any caller copying that verbatim across repeat fires hits this. cx/risk/eff 3/2/2. → [GH-274-MARATHON-DRIVE-DONE-TOKEN-RETRY-CLOBBER.md](PROJECT/3-COMPLETED/GH-274-MARATHON-DRIVE-DONE-TOKEN-RETRY-CLOBBER.md) · [#274](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/274)
ROADMAP.md-156-- **GH-294 · swarm-preflight: isolation flag not carried into the suggested marathon command** 🆕 **landed 2026-07-26 (marathon phase 1/4)** — the preflight packet's suggested invocation omitted the worktree-isolation flag, so a copy-paste fire silently ran unisolated. Relay Approved, lane satisfied. → [GH-294-PREFLIGHT-ISOLATION-FLAG.md](PROJECT/3-COMPLETED/GH-294-PREFLIGHT-ISOLATION-FLAG.md) · [#294](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/294)
ROADMAP.md:157:- **GH-292 · A linked worktree cannot discover the main checkout's vendored .xyz harness** 🆕 **landed 2026-07-26 (marathon phase 3/4)** — `find-harness.sh` now resolves the main checkout's `.xyz/` from a linked worktree via the shared `.git` probe, and falls back truthfully when that vendor is unusable. Gate initially failed on two static guards (GH-177 mktemp shape, GH-64 unsanitized eval) in the new fixture; both fixed rather than baselined. → [GH-292-WORKTREE-VENDORED-DISCOVERY.md](PROJECT/3-COMPLETED/GH-292-WORKTREE-VENDORED-DISCOVERY.md) · [#292](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/292)
ROADMAP.md-158-- **GH-272 · Driven relay turn's tick release resolves wrong TICK_REPO_ROOT in a vendored same-repo lane** 🆕 **captured 2026-07-21 via /file-xyz-bug from `sleuth-app`; root-caused + fixed 2026-07-23 via GH-296/PR #297, NOT this doc's own contract** — traced to `RelayTurnLib._run_rtl()` (`utils/py/rtl.py`) feeding `codex-turn.py`/`agy-turn.py`/`claude-turn.py`'s buggy `root` default into every bridged `relay-turn-lib.sh` call (incl. the turn-prompt text and the GH-67 backstop release) as `TICK_REPO_ROOT`. Confirmed via a live A/B repro with `xyz-vendor.sh`: pre-fix baked `TICK_REPO_ROOT="<target>/.xyz"` into the prompt and the backstop release itself, matching this issue's exact symptom; post-fix (PR #297) resolves both. This doc's own drafted contract targeted `relay-turn-lib.sh`'s `rtl_tick_bin()` — the wrong file — and is marked superseded/do-not-fire. cx/risk/eff 3/2/2 (provisional, now moot). → [GH-272-TICK-REPO-ROOT-VENDORED-MISMATCH.md](PROJECT/2-WORKING/GH-272-TICK-REPO-ROOT-VENDORED-MISMATCH.md) · [#272](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/272) · [#297](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/pull/297)
ROADMAP.md-159-- **GH-284 · marathon closeout → release-driven selection (6 phases; P1-P4 ✅ SHIPPED, P4 2026-07-29)** 🟡 **captured 2026-07-23 (/10days sweep)** — **P1** closeout PR (`--open-only` + `--closeout-pr`), PR [#316](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/pull/316). **P2** file-based driver liveness + opt-in idempotent GitHub run log, PR [#317](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/pull/317) — its marathon surfaced [#319](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/319) (every phase gate was fake) and [#320](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/320), and its merge surfaced [#322](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/322) (`--log-github` silently swallowed by the Python lane, so P2's feature was inert by default). **#322 closed 2026-07-29 and P2 is now effective**: PR [#324](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/pull/324) stopped the silence, then the port landed BOTH Phase 2 halves in `utils/py/marathon_drive.py` — the run log *and* the driver heartbeat, which #322 had believed was already there (its "12 references" were `xyz_marathon_heartbeat_*`, the unrelated GH-75 session record; `grep -c driver_heartbeat` on the Python twin was 0). `test/gh322-runlog-python-lane.sh` 5/19 pre-fix → 26/0. **P3** the release→issue-set join key: `RELEASES.md` gains `Milestone:` (a GitHub milestone title, not a URL and not an issue list), the `pdda.sh releases` check warns when a dated unshipped release lacks one, `releases-current` surfaces it, and GitHub milestone **Quicksilver** was created with #308 assigned. `test/gh284-p3-release-milestone.sh` is the **first test the releases check has ever had** (10 pass/5 fail pre-fix, 15/0 after). **P4** SHIPPED 2026-07-29 — `utils/release-lanes.sh` closes the loop in both directions: `seed` turns a release's `Milestone:` into a marathon candidate list in the same JSON shape `skills/10days/scan-issues.sh` emits, and `rollup` reports `N/M landed` from git ancestry. GitHub's own PR↔issue linkage turned out to be **empty on every issue in this repo**, so "landed" is evidenced by a commit whose CONVENTIONAL SCOPE claims the issue (`type(GH-N):` / leading `GH-N`); a bare `#N` is the squash-merge PR number and is rejected. Reports `landed`/`mentioned`/`absent`, because the matcher under-reports (a fix inside a marathon commit claims no issue) and a silent binary would call that a clean "not done". `test/gh284-p4-release-lanes.sh` 33/0, mutation-tested. **P5-P6 scoped, not contracted.** Original capture: — after a marathon run completes successfully, open a non-merging PR (opt-in `--closeout-pr` flag) carrying deterministic notes built from the plan name/phase count/tick events, reusing `marathon-closeout.sh`'s existing PR-creation code behind a new `--open-only` flag. Fully spec'd by the issue itself (exact seam, acceptance criteria, explicit non-goals: no merge, no force-push, no branch creation). cx/risk/eff 2/2/2 (provisional). → [GH-284-MARATHON-CLOSEOUT-PR.md](PROJECT/2-WORKING/GH-284-MARATHON-CLOSEOUT-PR.md) · [#284](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/284)
ROADMAP.md-160-- **GH-153 · Cost observability: Codex per-turn token capture (parseCodexStats)** 🆕 **captured 2026-07-23 (/10days sweep)** — was gated on #151 (Phase 4 discovery spike), now CLOSED; its recorded finding says the Codex capture gate check passes and `parseCodexStats` can mirror the existing `parseGeminiStats` almost exactly. Confirmed unimplemented in `src/cost.js`; `codex-turn.sh` needs `--json` wired into its `codex exec` invocation. Full spec already written in `PROJECT/1-INBOX/COST-OBSERVABILITY-PLAN.md` Phase 7. cx/risk/eff 2/1/2 (provisional). → [GH-153-CODEX-TOKEN-CAPTURE.md](PROJECT/2-WORKING/GH-153-CODEX-TOKEN-CAPTURE.md) · [#153](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/153)
ROADMAP.md-161-- **GH-268 · Beta onboarding & build-quality test report — remediation plan (re: #123)** 🔄 **Phases 1–2 done 2026-07-28; Phases 3–4 open** — Phase 1 closed: skill installers shipped via PR #282, and the clean-clone Quickstart was **verified green** (fresh clone of `development`, 133/133, exit 0) rather than needing a fix — only its "~1 minute" claim was wrong (~8 min measured). Phase 2 closed: README reordered to lead with what-it-is + Quickstart, CLI prerequisites lifted above the fast path with real install URLs, `relay-automation/README.md` retitled "Set up Codex, agy, and Pi" with an install/auth table, sandbox-hang callout added — plus **two dead prerequisite anchors** the report never saw (`a595c6f` renamed the target heading on 2026-07-23). Still open: **Phase 3** (relay handoff cues; the review loop checks the diff not the file it lands in) and **Phase 4** (cross-model re-test). Original findings: beta tester (Matthew Taylor) found 2 blocking onboarding issues (Quickstart fails on a clean clone; a named skill has no installer), 4 fix-before-broader-beta README/sandbox items, 2 follow-up process gaps (manual relay handoff; the review loop checks the diff not the file it lands in — an independent audit found 20 issues incl. 1 critical in code a relay approved), and 1 untested item (cross-model Codex/agy lane never ran — blocked on #232, now closed). Single plan doc, 4 phases, no per-finding issue split per operator instruction. cx/risk/eff 4/3/5 (provisional). → [GH-268-BETA-ONBOARDING-BUILD-QUALITY-REMEDIATION.md](PROJECT/3-COMPLETED/GH-268-BETA-ONBOARDING-BUILD-QUALITY-REMEDIATION.md) · [#268](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/268)
--
ROADMAP.md-204-- **GH-215 · utils/py/consult.py missing Bash degraded-panel SINGLE-MODEL stamping** ✅ **SHIPPED 2026-07-17 via a marathon lane (worktree-isolated Sonnet subagent)** — ported the `SINGLE-MODEL — NOT RECONCILED` stamping from `consult.sh` into `consult.py` verbatim, 2 new `test/consult.sh` cases, gate `bash test/consult.sh` 50/50 green. **Found in the process:** `XYZ_PYTHON=1 bash test/consult.sh` is still red for an unrelated, pre-existing reason this bug was masking (GH-178 A4's citation stamping was never ported to Python either) — tracked as [#223](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/223), not fixed here. cx/risk/eff 2/1/2. → [GH-215-CONSULT-PY-DEGRADED-PANEL-PARITY.md](PROJECT/3-COMPLETED/GH-215-CONSULT-PY-DEGRADED-PANEL-PARITY.md) · [#215](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/215)
ROADMAP.md-205-- **GH-208 · worktree-isolation.sh: flaky moved-ROOT-HEAD preserve-case race (GH-13/#14 guard)** ✅ **SHIPPED 2026-07-17 via the GH208-154-149-198 marathon (codex builder, agy reviewer, Approved)** — 9 local runs of `test/worktree-isolation.sh` at HEAD had produced 8 failures (case 6, `rc=6`); root cause turned out NOT to be a `relay-turn-lib.sh` race (that logic was correct) but a **test-fixture timing bug**: case (5)'s deliberate async write hadn't landed before case (6)'s cleanup ran. Fixed with a 2s wait in the fixture, no source-code change. Verified 8/8 clean repeated runs. Full `validate.sh`: 113/114 (only the separately-fixed `relay-pkg-freshness.sh` staleness). cx/risk/eff 2/2/2. → [GH-208-WORKTREE-ISOLATION-RACE.md](PROJECT/3-COMPLETED/GH-208-WORKTREE-ISOLATION-RACE.md) · [#208](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/208)
ROADMAP.md-206-- **GH-154 · port-drift: marathon-plan shell heredoc vs. Python-layer port diverged (missing GH-48 zone model)** ✅ **SHIPPED 2026-07-17 via the GH208-154-149-198 marathon (Approved)** — ported `compileZoneConfig`/`QP_ZONES_CONFIG`/`QUEUE_PLAN_ZONES_FILE` into `utils/py/_marathon_plan_node.js`; also wired `utils/marathon-plan.sh`'s `XYZ_PYTHON=1` dispatcher to translate `--zones-config` into `QUEUE_PLAN_ZONES_FILE` so the flag survives the shell→Python→Node handoff. 2 new parity assertions in `test/marathon-plan.sh` (explicit-zones dry-run + rendered doc, shell vs. `XYZ_PYTHON=1`). Full `bash test/marathon-plan.sh`: 60/60 (up from 58). GH-110 P3a is now unblocked. cx/risk/eff 2/2/3. → [GH-154-MARATHON-PLAN-PORT-PARITY.md](PROJECT/3-COMPLETED/GH-154-MARATHON-PLAN-PORT-PARITY.md) · [#154](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/154)
ROADMAP.md-207-- **Marathon Plan G · marathon/relay driver hardening (GH-149, GH-198)** ✅ **both lanes SHIPPED 2026-07-17 (codex builder, agy reviewer, both Approved)** — two small, independent driver-script bugs, neither fitting Plan F's theme: Lane 1 (#149) fixed, Lane 2 (#198 Bug 2) fixed — see their own entries below. → [MARATHON-PLAN-2026-07-17-G-DRIVER-HARDENING.md](PROJECT/3-COMPLETED/MARATHON-PLAN-2026-07-17-G-DRIVER-HARDENING.md)
ROADMAP.md:208:- **GH-149 · marathon-drive --require-clean self-trips on its own .relay-driver.lock inside a linked worktree** ✅ **SHIPPED 2026-07-17 via the GH208-154-149-198 marathon (Approved)** — `marathon-drive.sh` now resolves the driver lock via `git rev-parse --git-common-dir "$ROOT"` when `$ROOT/.git` is a file (linked worktree), landing it in the real `.git/` dir outside the worktree's own `git status --porcelain` view (falls back to the original hidden-lock behavior for a vendored `.xyz/` copy). New regression case in `test/marathon-drive.sh`. Full `bash test/marathon-drive.sh`: 105/105. cx/risk/eff 2/2/2. → [GH-149-REQUIRE-CLEAN-SELFTRIP.md](PROJECT/3-COMPLETED/GH-149-REQUIRE-CLEAN-SELFTRIP.md) · [#149](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/149)
ROADMAP.md-209-- **GH-198 · relay-drive.sh headless turn: file-scoped commit ignores pathspec + uncommitted-artifact review fails opaquely** ✅ **Bug 2 SHIPPED 2026-07-17 via the GH208-154-149-198 marathon (Approved); Bug 1 already fixed separately (commit `bee1abf`)** — `relay-drive.sh` gained `preflight_setup_artifact_paths()`, called before each turn dispatch: scans the relay file's `Setup` section, fails fast with `artifact path not found in worktree: <path>` if a referenced artifact is missing, instead of failing opaquely mid-turn. 2 new cases in `test/relay-artifact-file.sh`. Full suite: 13/13 (up from 11). cx/risk/eff 1/1/2. → [GH-198-RELAY-DRIVE-ARTIFACT-PREFLIGHT.md](PROJECT/3-COMPLETED/GH-198-RELAY-DRIVE-ARTIFACT-PREFLIGHT.md) · [#198](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/198)
ROADMAP.md-210-- **Marathon Plan H · cross-repo live marathon status query (GH-218)** 🆕 **captured 2026-07-17 via `/idea`, promoted to 2-WORKING, 2-phase marathon built** — lets the operator/Claude ask "what marathons are running right now" across every XYZ-vendored repo, returning repo + marathon/lane + in-flight task + claimant. Composes entirely existing primitives (`hq_known_repos`/registry.tsv for repo discovery, `tick project`'s own derived `STATE.md` for live claim state, `rollup.sh`'s existing embed mechanism for Obsidian) — explicitly rejects a per-repo MCP server as unjustified overkill (everything needed is a local file/process read on this machine). Phase 1: new `utils/hq/marathon-live.sh`. Phase 2: small `rollup.sh` hook to embed its report. cx/risk/eff 3/1/2. → [MARATHON-PLAN-2026-07-17-H-LIVE-MARATHON-STATUS.md](PROJECT/2-WORKING/MARATHON-PLAN-2026-07-17-H-LIVE-MARATHON-STATUS.md)
ROADMAP.md-211-- **GH-218 · Cross-repo live marathon status query (repo + lane + in-flight task), no per-repo MCP servers** ✅ **SHIPPED — closed 2026-07-21** (commit `d919e92`, merged PR #256) — see Marathon Plan H above for the full scope; capture doc carries the Phase 1/2 checklists and Swarm Preflight Contract. cx/risk/eff 3/1/2. → [GH-218-CROSS-REPO-LIVE-MARATHON-STATUS.md](PROJECT/3-COMPLETED/GH-218-CROSS-REPO-LIVE-MARATHON-STATUS.md) · [#218](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/218)
ROADMAP.md-212-- **GH-171 · codex-turn.sh's claim-before-launch never fires in vendored .xyz consumer repos — no-progress persists after GH-165** ✅ **SHIPPED 2026-07-07 (merge commit `625d26f`); #171 closed** — found live re-firing sleuth-app's stalled marathon after syncing in GH-165: `_tickbin` was blindly built as `$TICK_REPO_ROOT/bin/tick`, which doesn't exist in a vendored install (real binary is `.xyz/bin/tick`) — the `-x` check silently failed, so GH-165's whole claim block was skipped with no error, exactly reproducing the pre-GH-165 symptom. Fixed on `fix/gh-171-chain-root-cause` (commit `b00ee48`), merged to main via `625d26f`: new `rtl_tick_bin()` resolver (TICK_BIN override → real path under the pinned root → harness-local fallback), preserves an inherited `TICK_REPO_ROOT` instead of clobbering it, extends the same claim-before-launch guard to `agy-turn.sh`. New regression test reproduces the exact vendored-consumer shape end-to-end (`test/marathon-drive.sh`, 5 new cases); independently verified twice — once pre-merge and again post-merge (not trusting the commit message either time): `marathon-drive.sh` 60/0, `codex-turn.sh` 37/0, `relay-turn-handoff.sh` 2/0, `agy-turn.sh` 33/0, `aider-turn.sh` 36/0, `claude-turn.sh` 30/0, `XYZ_PYTHON=1 codex-turn.sh` 37/0 — zero regressions. Review surfaced one parity gap, split out as #174. Still needs: re-verify sleuth-app's actual GH-349 marathon lane now that the fix is live. → [#171](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/171)
--
ROADMAP.md-239-- **GH-124 · deep-research.mjs shipped un-run against real `agy` — add a real-`agy` smoke test + runaway-grounding guard** ✅ **SHIPPED 2026-07-04 (`6daaff5`, 45/45 + self-skipping live test) · part of [Marathon Plan C](PROJECT/3-COMPLETED/MARATHON-PLAN-2026-07-04-C-RELIABILITY.md)** — GH-87's adapter hung on *every* real `agy` call (stub-only tests hid it); two bugs fixed post-merge (`91f17f2` missing `--dangerously-skip-permissions`; `74cd553` `execFile` silently ignores `stdio` → agy stdin never EOF'd → switched to `spawn`). Now works (~27–52s, real citations, `test/deep-research.sh` 23/23). Hardening follow-up: an **opt-in real-`agy` smoke test** (network + `agy` on PATH, self-skips like `relay-self-sufficiency.sh`) so a stub can't again hide a real-backend break; a guard against `--search-context-size high` runaway grounding; revisit the default 120s timeout. Surfaced dogfooding #111. cx/risk/eff 2/1/2. → [GH-124-DEEP-RESEARCH-REAL-AGY-HARDENING.md](PROJECT/3-COMPLETED/GH-124-DEEP-RESEARCH-REAL-AGY-HARDENING.md) · [#124](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/124)
ROADMAP.md-240-- **GH-118 · Make Aider edit formats more forgiving for OpenRouter models** ✅ **closed** — captured 2026-07-03 · rated · live-confirmed — Aider natively uses a 'whole' or 'udiff' edit format depending on the model, but unknown OpenRouter models (like GLM-5.2) often default to formats they don't strictly follow (e.g. outputting standard diffs instead of 'whole' file), causing Aider to fail with 'no tracked changes'. **2026-07-03 live tests confirmed the diagnosis and the fix on two models:** GLM-5.2 (first attempt: no edit emitted at all, just chat; retry with `AIDER_FLAGS=--edit-format diff` produced valid SEARCH/REPLACE) and Nemotron Ultra 3 free tier (same 'whole' default — zero nvidia/nemotron entries anywhere in Aider's model-settings.yml or heuristic chain — failed by emitting a raw unified-diff hunk, reproducing the original bug report almost exactly). Revised fix: document `AIDER_FLAGS=--edit-format diff` (already a passthrough) rather than adding a new `AIDER_EDIT_FORMAT` var; maintain a running known-model compat note. cx/risk/eff 2/1/2. → [GH-118-AIDER-OPENROUTER-FORMAT.md](PROJECT/3-COMPLETED/GH-118-AIDER-OPENROUTER-FORMAT.md) · [#118](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/118)
ROADMAP.md-241-- **GH-119 · aider-turn.sh: reviewer can auto-add and edit out-of-scope tracked files under --yes-always; all-or-nothing containment discards the valid in-lane edit too** ✅ **SHIPPED 2026-07-03 (`93e2366`); closed 2026-07-04 · sibling of #54/#107** — surfaced live while testing GH-118's fix: GLM-5.2, acting as Reviewer, found a real bug and emitted a valid SEARCH/REPLACE for the relay file, but also emitted an edit for `marathon-drive.sh` (never added to the chat) which Aider's `--yes-always` auto-confirmed adding. The off-lane guard correctly caught it but discarded the *entire* turn, including the valid relay-file review. Same containment mechanism as #54/#107, different (deliberate, role-violating) trigger. Fixed: pre-seeds the diff's changed files as `--read` for review-only turns (`ALLOW_PATHS=""`) so they're structurally unwritable regardless of `--yes-always`; new `test/aider-turn.sh` case; independently re-verified via two reverse-dogfood reviews (24-file scale, zero scope-creep both times). cx/risk/eff 2/2/2. → [GH-119-AIDER-REVIEWER-SCOPE-CREEP.md](PROJECT/3-COMPLETED/GH-119-AIDER-REVIEWER-SCOPE-CREEP.md) · [#119](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/119)
ROADMAP.md-242-- **GH-120 · Build a fuzzy-match OpenRouter model-name lookup table (alias → canonical slug)** ✅ **SHIPPED 2026-07-03 (`17e2681`); closed** — resolving colloquial model names ("GLM 5.2", "Nemotron Ultra 3") to canonical OpenRouter slugs currently required a live API query every time. Shipped: `relay-automation/openrouter-model-aliases.yml` + `resolve-model-alias.sh` (4-tier fuzzy match) + `test/model-alias.sh` (10/10), wired into `validate.sh`, documented. Independently re-verified via a GLM 5.2 reverse-dogfood review, which also caught and fixed a stale README claim (`1642304`). cx/risk/eff 1/1/2. → [GH-120-OPENROUTER-MODEL-ALIAS-TABLE.md](PROJECT/3-COMPLETED/GH-120-OPENROUTER-MODEL-ALIAS-TABLE.md) · [#120](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/120)
ROADMAP.md:243:- **GH-117 · fix(marathon-drive): --dry-run must probe builder/reviewer binary before mutating tick state** ✅ **SHIPPED 2026-07-04 (`b4e73df`, 55/55) · part of [Marathon Plan C](PROJECT/3-COMPLETED/MARATHON-PLAN-2026-07-04-C-RELIABILITY.md)** — `marathon-drive.sh` didn't probe builder/reviewer binary availability before seeding tick state, so missing-binary errors fired after the tick task was already seeded and spent (no recovery without a fresh relay-task id). Fixed: binary probe after arg parsing, before any tick mutation — catches missing `claude`/`agy`/`codex` on both `--dry-run` and live runs. (Integration commit `d5a1681` then stubbed `CLAUDE_BIN`/`AGY_BIN` in `driver-lock.sh`/`xyz-harness-hooks.sh`, which this probe correctly rejected for their unresolvable default builder.) Found in a live 3-phase marathon run. cx/risk/eff 2/1/2. → [GH-117-MARATHON-DRIVE-BINARY-PREFLIGHT.md](PROJECT/3-COMPLETED/GH-117-MARATHON-DRIVE-BINARY-PREFLIGHT.md) · [#117](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/117)
ROADMAP.md-244-- **GH-116 · fix(tick): misleading 'break' error on open tasks + marathon retry flag** ✅ **SHIPPED — Bug A (`bb9138b`), Bug B 2026-07-04 (`53c8dce`, 17/17) · part of [Marathon Plan C](PROJECT/3-COMPLETED/MARATHON-PLAN-2026-07-04-C-RELIABILITY.md)** — Bug A (`tick break` on an `open` task said "only the claiming agent can mutate it" — misleading; real problem was the task not being `claimed` at all) landed in `src/scope.js`, confirmed live. Bug B: `marathon.sh` had no retry flag, so recovering a spent task meant manually renaming the phase id in YAML. Fixed: `--retry <phase-id>` passes a suffixed `--relay-task` to that phase's `marathon-drive.sh` call (which already supported the override natively — no change needed there). Found in live run. cx/risk/eff 2/1/2 (Bug B only). → [GH-116-MARATHON-RETRY-FLAG.md](PROJECT/3-COMPLETED/GH-116-MARATHON-RETRY-FLAG.md) · [#116](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/116)
ROADMAP.md-245-- **GH-114 · chore: remove deprecated gemini-turn.sh and scrub dead GEMINI references** ✅ **SHIPPED 2026-07-03; closed 2026-07-04** — `gemini-turn.sh` marked DEPRECATED 2026-06-19; Gemini CLI phased out. Delete the shim, remove its README row and `GEMINI_AGENT` comment from `marathon-agent.sh`. `agy-turn.sh` is the live permanent replacement. **✅ Follow-up gap found + fixed 2026-07-03:** the original `2b5f8a3` fix deleted `relay-automation/gemini-turn.sh` and dropped `gemini` from `marathon-drive.sh`'s help/validation, but left 5 test files still hardcoding `--reviewer gemini` / `RELAY_AGENT=gemini` / a direct reference to the deleted shim (`test/gemini-turn.sh`, `test/relay-turn-timeout.sh`, `test/marathon-yaml.sh`, `test/marathon-drive.sh`, `test/xyz-harness-hooks.sh`) — surfaced when today's GH-118/119/120 marathon ran the full suite (6 failures, all traced to this one root cause via zero-diff confirmation against pre-marathon HEAD). Fixed: deleted the dangling `test/gemini-turn.sh` (and its now-invalid `validate.sh` entry), swapped the other 4 files' gemini usage to `agy` (discovering along the way that `agy-turn.sh`'s auth pre-flight + empty-log guard needed dedicated stubs, unlike codex/claude). `validate.sh`: **90/90**. cx/risk/eff 1/1/1. → [#114](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/114)
ROADMAP.md-246-- **GH-113 · fix(marathon-yaml): validator rejects agy reviewer — blocks multi-phase YAML plans** ✅ **SHIPPED 2026-07-03; closed 2026-07-04** — `marathon-yaml.js:114` hard-codes `codex|gemini` allowlist; `MARATHON.example.yaml` documents and uses `reviewer: agy`; `marathon-drive.sh` already routes `agy*`→`AGY_AGENT`. Blocking bug: any multi-phase YAML plan with an agy reviewer phase fails at parse time. Single-phase `marathon-drive.sh --reviewer agy` runs are unaffected. One-line regex fix. **✅ Follow-up gap found + fixed 2026-07-03:** `test/marathon-yaml.sh`'s reviewer-rejection assertion hardcoded the pre-agy error string (`"must start with codex or gemini"`), which went stale the moment the actual message changed to `"must start with codex, gemini, or agy"` when agy was added — a false failure, not a real regression. Relaxed the assertion to check the `"must start with codex"` substring (resilient to future prefix-list changes) instead of hardcoding the full message. Note: `gemini` remains a genuinely accepted reviewer prefix in `src/marathon-yaml.js` itself (out of scope for this test-only fix). cx/risk/eff 1/1/1. → [#113](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/113)
ROADMAP.md-247-- **GH-112 · Progressive Python port — boundary decision + opt-in Python layer** 🐍 **spike SHIPPED · port LANDED as opt-in 2026-07-04 (`gh112-python-optin`)** — spike answered all three questions ([decision record](decisions/2026-07-04-python-port-boundary.md): `relay-turn-lib.sh` stays Bash permanently; Option A discrete Python CLIs; zero test-suite changes needed). The full port first arrived as PR #121 (Python-by-default, `development`-targeted, conflicting) — **not merged**; rebuilt file-level on a clean branch off post-#134/#135 `main`: 13 modules under `utils/py/` + pytest layer, with the toggle **inverted** — Bash stays the default in all 11 entry scripts, `XYZ_PYTHON=1` opts into the Python route (same CLI/exit-code contract). `validate.sh` 100/100 green default-mode; toggle routing 22/22; pytest 8/8. **#134 parity lane SHIPPED 2026-07-05 (marathon-drive; codex→agy Approved):** ported GH-106/GH-117/GH-108 into the `utils/py/` twins + 4 parity tests (incl. a GH-107 inheritance assertion via `rtl.py`), and wired `pytest` into `validate.sh` (102/102). **Issue #112 CLOSED 2026-07-05** — port scope done; promotion of Python to the DEFAULT is intentionally deferred (Bash stays default per the decision record; a fresh issue can track any future default-flip). ✅ cx/risk/eff 2/2/2. → [GH-112-PYTHON-134-PARITY.md](PROJECT/3-COMPLETED/GH-112-PYTHON-134-PARITY.md) · [GH-112-PYTHON-PORT-SPIKE.md](PROJECT/3-COMPLETED/GH-112-PYTHON-PORT-SPIKE.md) · [#112](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/112)
--
ROADMAP.md-292-- **Part B — Adversarial hardening** ⚠️ — Phase 1 (epoch fencing) shipped; Phase 2 chaos-suite *detection* partials landed; Phases 2–4 are the active "adversarially proven → commercially viable" frontier. Immediate next-up: promote exactly one proof-sized Phase-2 slice into a contract-backed lane (important because Part B only keeps momentum if it advances in small, verifiable proofs instead of reopening the whole frontier at once). → [ADVERSARIAL-HARDENING.md](PROJECT/2-WORKING/ADVERSARIAL-HARDENING.md)
ROADMAP.md-293-- **Tooling · relay-to-issue skill** ✅ **SHIPPED + VERIFIED END-TO-END 2026-07-05; closed** — a post-relay skill that distills a closed `/relay` thread into ONE checklist-style GitHub issue, filed in the repo the relay was *about* (cross-repo aware; dedup-stamped; auto-posts via `gh`). `skills/relay-to-issue/` (SKILL + `relay-to-issue.sh` + `install.sh`); the full `resolve → file → provenance-stamp → dedup` loop proven live against a real closed relay — a live `gh issue create` posted #139, and a re-run correctly reported `ALREADY_FILED` (dedup holds). Nothing outstanding. **Correction (2026-07-07):** this line was stale (still marked 🟡, pointing at a `2-WORKING` path that no longer exists) — the doc had already moved to `3-COMPLETED`, and the generated [MARATHON-PLAN-2026-07-07.md](PROJECT/4-MISC/MARATHON-PLAN-2026-07-07.md) was surfacing this as a live Wave 1 item off that drift. Re-run `utils/marathon-plan.sh` to clear the ghost lane once this line is corrected. → [RELAY-TO-ISSUE-SKILL.md](PROJECT/3-COMPLETED/RELAY-TO-ISSUE-SKILL.md)
ROADMAP.md-294-
ROADMAP.md-295-### Completed
ROADMAP.md:296:- **GH-448 · driver-lock consumers guess the path with 2 branches while the drivers use 3, so a linked worktree's LIVE marathon reads as IDLE** ✅ **SHIPPED 2026-08-10 (PR #449)** — `marathon-drive` (frozen `.sh` + authoritative `utils/py/marathon_drive.py`) correctly resolves its lock 3 ways (`.git` dir / `.git` file → git common dir / absent → vendored); `marathon-ls.sh`, `utils/hq/marathon-live.sh`, and `find-harness.sh --check` had each drifted to a 2-branch guess that misses the linked-worktree case, so a genuinely-live driver reads as `IDLE`/"claimed, not driving"/silent. New shared resolver (`utils/py/rtl.py::driver_lock_path` + `relay-automation/driver-lock-lib.sh`, parity-tested) used by all three; `marathon_drive.py` refactored onto it too (no behavior change, `driver-lock.sh` still 4/4). `test/gh448-driver-lock-resolver.sh` (17/17): bash/python parity, a negative control replaying the pre-fix logic against a REAL `git worktree add` fixture (observed missing the lock), and an end-to-end pass of the fixed scripts against that same fixture (observed LIVE/🟢 live/warning). Sibling **#376** (driver-side `relay-drive.sh`/`relay_drive.py` half of the same defect) is explicitly out of scope here. cx/risk/eff 3/2/3, 1 phase. → [GH-448-DRIVER-LOCK-RESOLVER.md](PROJECT/2-WORKING/GH-448-DRIVER-LOCK-RESOLVER.md) · [#448](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/448) · [#376](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/376) · [#354](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/354)
ROADMAP.md-297-- **GH-484 · redefine the canonical marathon-phase directory default from phases/ to marathon-system/** ✅ **SHIPPED 2026-08-09 (branch `feat/gh484-marathon-system-default`)** — the phase-output default now matches `relay-system/`'s naming; `--phases-dir`/`PHASES_DIR` override it exactly as before and the ~72 committed historical `phases/<run-id>/` records are deliberately not migrated. **Three independent defaults had to move, not one** — a pre-implementation consult (codex; agy timed out twice, single-model and stated as such) caught that `marathon.sh` computes its own at `:167` and forwards the flag on every phase, so a driver-only flip would have left the multi-phase orchestrator untouched while still satisfying the original acceptance criteria. Carried a **latent bug that predates the rename**: the dirty-tree pre-flight excluded a hardcoded `"phases/"` instead of the configured directory, so any `--phases-dir` user already had their own phase output called stray, and a vendored `<repo>/.xyz/phases/` was never matched at all. **The most instructive defect was in the fix itself** — `git rev-parse --show-toplevel` always reports the physical path, so a repo behind a symlinked ancestor (macOS `/var`, `/tmp`) silently emptied the computed prefix and disabled the exclusion, exactly the failure the fix existed to remove; both twins had it, and the new test caught it. That test's own first two drafts were vacuous and passed against pre-fix code (the driver dies on the gate probe before the clean check; porcelain collapses untracked dirs to `?? state/`) — now controlled and replay-verified red pre-fix. Monitors get dual-path lookup, not a swap, so pre-flip runs and not-yet-re-synced fleet repos stay visible. Phase 0's grep classification missed two live sites that only running the suite found, recorded in the doc rather than folded in quietly. GH-308 exception process followed for the one frozen twin. cx/risk/eff 3/2/3, 3 phases. → [GH-484-MARATHON-SYSTEM-DEFAULT.md](PROJECT/3-COMPLETED/GH-484-MARATHON-SYSTEM-DEFAULT.md) · [#484](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/484)
ROADMAP.md-298-- **GH-307 · Marathon pre-advance gate inherits the run's identity tags, so `bash validate.sh` can never pass inside a marathon** ✅ **SHIPPED 2026-07-27 (PR #309)** — `marathon.sh` drives each phase with `XYZ_HARNESS_CONTEXT` / `MARATHON_LANE_NS` set (and packet-generated invocations add `XYZ_SESSION_ID`); the gate ran as a plain subprocess and inherited all three, breaking `test/xyz-harness-hooks.sh` and `test/debug-mantra.sh` — so the *documented default gate* halted every packet-driven run at phase 1. Scrubbed in both twins (`utils/py/marathon_drive.py` is the one that runs by default), narrowly: `MARATHON_ROOT` / `TICK_BIN` / `TICK_REPO_ROOT` are preserved. Guarded by `test/gh307-gate-env-scrub.sh` (structural parity) and a behavioural case in `test/marathon-drive.sh` §5b. Proven live — the gate passed in marathon phase 2 of the same run that previously halted. No capture doc: found and fixed in-flight while driving the marathon. · [#307](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/307)
ROADMAP.md-299-- **GH-278 · aider-turn per-turn timeout drifts across twins and docs (py 300s / sh 600s / docs 900s)** ✅ **SHIPPED 2026-07-27 (PR #309, marathon phase 4/4)** — 900s asserted across both twins and the relay-xyz skill by a static parity guard, plus a behavioural guard that a timeout-killed turn (exit 7) leaves no 0-byte stubs (untracked removed, tracked restored from HEAD). The phase escalated once on a containment violation traced to the fixture, not the product: the shims' `--help` probe is deliberately not cwd-wrapped, and the stub CLI wrote unconditionally, so fixtures leaked into the caller's cwd. Fixed; phase deliberately not re-driven (a re-fire would regenerate the leaky fixture). → [GH-278-AIDER-TURN-TIMEOUT-DRIFT.md](PROJECT/3-COMPLETED/GH-278-AIDER-TURN-TIMEOUT-DRIFT.md) · [#278](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/278)
ROADMAP.md-300-- **GH-300 · swe-diagram: search input touches/overflows the font-picker when typing — two distinct bugs, same symptom family** ✅ **SHIPPED 2026-07-23** — **(1)** `type="search"` never reset `-webkit-appearance`, letting WebKit's native cancel-button decoration override the input's explicit 180px width; fixed, but not independently re-verified in Safari (no Safari automation in this environment). **(2)** found on operator re-report: `positionPicker()` only ran on load/font-change/resize, never on the search box's own `input` event, so the custom clear button appearing (growing the right-anchored `.swe-search` box leftward) left the picker stranded — a window resize incidentally fixed it by recomputing from the now-current width, which is exactly the behavior reported. Fixed by dispatching a `swe-search-resize` event from `renderer.js`'s search handlers; **verified quantitatively** (headless-Chrome bounding-rect measurement: gap went from a healthy 8px to a -22px overlap after typing, now stays a constant 8px with no resize needed) — this fix is plain DOM logic, not WebKit-specific, so the Chrome verification is directly conclusive. `test/swe-diagram.sh` 42/42 throughout. → [GH-300-SWE-DIAGRAM-SEARCH-INPUT-OVERFLOW.md](PROJECT/3-COMPLETED/GH-300-SWE-DIAGRAM-SEARCH-INPUT-OVERFLOW.md) · [#300](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/300)
--
CHANGELOG.md-13-
CHANGELOG.md-14-### Fixed
CHANGELOG.md-15-- **A marathon committed to whatever branch the target happened to have checked out, and `marathon/<slug>-<date>` was advisory text nothing enforced.** The driver now refuses before its first commit when the **receiving** repo is sitting on its trunk. Measured against `args.target_root or root` and against *that* repo's trunk — under `--target-root` they are different repos with different defaults, and checking the harness's own would be the plausible wrong answer that passes every test written on a same-repo fixture. `trunk_ref()` was hardcoded to `root`; it now takes a repo path and defaults to `root`, so its existing caller (the run log's landed-yes/no probe) is byte-identical. **The refusal is scoped to a SHARED trunk — one `origin/HEAD` actually resolves to — and that narrowing is load-bearing in two directions.** The harm is stated in the message itself: a marathon's turns commit continuously, so a run that lands on trunk cannot be un-landed by stopping it, only by rewriting history *someone else may already have pulled*. In a repo with no remote there is no someone else and `git reset` undoes everything, so blocking there would spend a hard stop on a fully recoverable state. It is also what keeps the guard testable at all — every fixture in this suite is a fresh `git init` on `main` with no origin, and a permissive trunk fallback would have refused to run in all of them, the same untestable-guard trap GH-388's durability rule was scoped away from. The no-remote case is asserted as an explicit **non**-block rather than left untested. **`--force` deliberately does not open this door**, and there is a test for it: `--force` bounds per-lane *attempts*, and one flag for both would mean an operator retrying a flaky lane silently acquires permission to land on main — a coupling that is only obvious after it happens. The two documented ways past are `--allow-trunk-commit` and preflight's existing risk=1/independent-zone carve-out, honoured from `SP_SKIP_BRANCH_PROMPT` in the environment rather than by parsing a packet (the driver does not read packets; GH-386 is what happens when something pretends it does). The remedy names preflight's own `SP_SUGGESTED_BRANCH` when present, so the operator gets the exact branch to cut. `test/gh402-branch-enforcement.sh` 13/0, observed **8 red** pre-fix with the pre-fix run **committing to trunk** in the recording — the defect as an observation, not a description. Phase 1 only, and `marathon.sh` / `relay-turn-lib.sh` / `rtl.py` are untouched, per the lane's own scoping. **One design correction, made after the guard's first full run and worth recording because the first instinct was wrong:** I expected fixtures to be unaffected on the grounds that they have no remote. They do — `test/_setup.sh` clones every fixture from a bare repo it creates, so they carry a real `origin/HEAD` and sit on `main`, indistinguishable to the driver from a live target. **Eight suites went red**, and `test/marathon-drive.sh` alone has ~98 driver invocations. Threading `--allow-trunk-commit` through every call site would have been a permanent tax on every future marathon fixture, with far more chance of introducing a mistake than the guard has of catching one in a fixture — so the bypass is declared **once**, in the single file every fixture already sources, as what it actually is: a test harness stating that branch protection is not what is under test. `test/gh402-branch-enforcement.sh` **unsets it**, so the protection has a suite that proves it fires rather than one that silently never reaches it. → [#402](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/402)
CHANGELOG.md-16-- **`claude` was the only builder capped below 900s, and the packet that told operators otherwise was printing a number nothing read.** Two defects, joined because the second is what made the first expensive. `agy`, `codex`, `aider` and `pi` all defaulted to a 900s wall cap; `claude` defaulted to **600**, and nothing anywhere said why — GH-320's comment directly above that line explains why the *twins* must agree, not why the value differs from every other agent. The obvious guess is "600 is a cost control, because a headless `claude -p` bills per call", and it is **wrong**: cost is already bounded three lines up by `CLAUDE_MAX_BUDGET`, passed to the CLI as `--max-budget-usd` (default $0.50). A shorter wall cap buys no money that flag is not already saving; what it buys is a builder killed mid-edit — the same failure GH-320 fixed one notch lower (300→600) and #386 observed again at this one, on a phase whose packet read 900 and which died at 600 partway through a ~1690-LOC artifact pair. Raised to 900 on both lanes, with the rationale written down so the next reader does not re-derive the wrong guess; GH-492's idle bound (`RELAY_TURN_IDLE_S`) is the mechanism that ends a genuinely stuck turn early, and it is builder-agnostic, so the wall cap behind it has no reason to vary by agent. **Separately, `swarm-preflight` printed `RELAY_TURN_TIMEOUT_S=<n>` into every packet and nothing read it** — `marathon.sh` does not parse packets, so the figure the operator read was never the figure the run used. The suggestion now names **`turn_timeout_s:` in the phase's MARATHON.yaml entry**, which is the mechanism that already worked (`marathon.sh` reads that field and applies it per phase), and the test asserts that claim is *true* rather than merely written. **The sizing ladder behind the number was the trap in the fix.** It was 300/600/900, built around a 300s default that has not existed since GH-320 — so raising the cap and stopping there would leave the packet suggesting **300 or 600**, a silent downgrade below the default, inside a sentence whose own words promise headroom. It now only ever suggests *more*: work that fits in 900 gets `none needed` and says so, and only the largest bucket proposes an override (1800 — stated in the code as a doubling and a starting point, not a measurement, because the old steps were never measured either and the difference is admitting it). The stale "300s default" prose is gone from the packet text; the GH-51 comment explaining why artifact *count* matters is **kept and relabelled historical**, because a test that forbids describing a superseded design forces the history out of the file. `test/gh386-turn-budget-honesty.sh` 10/0, observed **9 red** pre-fix (`test/baselines/GH-386-negative-control.md`); Part C exercises the shipped ladder across a range of artifact sizes rather than reimplementing it, and fails if any suggestion falls below the default. Both frozen Bash twins carry `Frozen-twin-exception:` trailers — `claude-turn.sh`'s edit is *required* by GH-320's parity guard, not optional. → [#386](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/386) · [#320](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/320) · [#382](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/382)
CHANGELOG.md:17:- **The "worktree isolation leaks an off-lane creation into the harness repo" defect is real, reproduces exactly as filed — and is not a worktree defect at all.** #426 named worktree teardown as the place to look, and explicitly warned against treating that as the answer: *"a builder that treats this as the answer will produce a fix shaped like the guess rather than like the defect."* A factorial control settled it in three runs — same fixture, one variable at a time: stub writes + isolation **ON** → leak; stub writes **nothing** + isolation ON → no leak; stub writes + isolation **OFF** → **leak**. The third case is fatal to the stated theory: the leak survives with isolation disabled, so teardown cannot be the mechanism. Logging every invocation of the agent binary showed the real one — there are **two per turn**, `agy whoami` (the GH-375 auth pre-flight) and then the turn itself, and **the pre-flight ran with the caller's CWD**, i.e. the harness clone, which is the one execution of the agent binary that happens entirely outside the turn's containment. The reproducing stub — like `test/gh410-containment-advisory.sh`'s — writes on *every* invocation, so the pre-flight invocation is what reached the harness root. The turn's own copy was always discarded, `worktree_end` always fired, and the worktree's `git-common-dir` always resolved to `AGY_TURN_ROOT`: **criterion 3 was already true and needed proof, not a change.** The fix is still worth making, for a different reason than the one filed — real `agy whoami` does not write to its CWD, but *"the binary we shell out to happens not to write"* is a claim about someone else's program rather than a property this harness enforces, and it is exactly the assumption that made a test stub indistinguishable from a containment failure. `agy_auth_preflight` now runs in a throwaway directory and **reports** anything the probe leaves there instead of discarding it silently. **`test/gh410-containment-advisory.sh`'s cleanup block is deleted, and its absence is the proof**: it used to `rm -f "$ROOT/offlane.md"` and print a NOTE, so a returning leak now makes that suite litter a live repo again rather than quietly tidying up after itself. `test/gh426-worktree-leak.sh` 7/0 — absence asserted in **both** repos in separate assertions (checking only the declared target is the miss this criterion exists for), exit 6 asserted **first** so a fix cannot buy containment by weakening the verdict, and criterion 3 read from the turn invocation's own `git-common-dir` *while the worktree still exists* (an earlier draft asserted it after teardown and reported "could not resolve", which is not a verdict). Controls: **2 red** here and **1 red** in gh410's new C4c against the pre-fix `agy-turn.py` (`test/baselines/GH-426-negative-control.md`). → [#426](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/426) · [#410](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/410) · [#375](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/375)
CHANGELOG.md-18-- **The marathon orchestrator persisted nothing of its own, so the phase that dies was the one phase with no record — and building the fix found two more layers doing the same thing.** `marathon.sh` had no `tee`, no `exec >`, no log-file variable. What was durable got written **per phase, on completion**, which biases the archive toward success by construction: in the run that produced this issue, phases 1-4 each have a transcript and phase 5 — the one that panicked the host — has none. The only surviving account was a terminal stream the invoker had redirected to a path the platform clears at boot; after the reboot it was gone. That choice was theirs and a poor one, but the harness offered no alternative and gave no indication one was needed. **Where the run narrative goes is the harness's decision now**: a run log opens under the same transcript root the per-phase transcripts already use, is announced as `run log: <path>` at chain start, and is `tee`d as output is produced — armed after plan validation and before the first phase, so a usage error or an unparseable plan leaves no empty log implying a run happened (`--dry-run` is excluded for the same reason, and that exclusion is asserted). **Two further defects were found by the regression test rather than reasoned about, and both are the same bug one layer down.** (1) `marathon_drive.py`'s own narrative was **block-buffered** — Python block-buffers stdout when it is not a TTY, and a marathon is never a TTY, so this was not an edge case but *the* unattended path: the first kill-mid-run recovered a log holding the child turn-shim's output and none of the driver's, because subprocesses wrote straight to the fd while every `marathon-drive: …` line sat in a buffer SIGTERM discards. (2) **SIGTERM never reached the exit hooks at all** — the driver already ran them from a `finally`, but SIGTERM terminates CPython immediately; SIGINT raised `KeyboardInterrupt` and so already worked, and SIGTERM is what an unattended run actually receives. Now converted to `SystemExit(128+signum)`, the convention `_exit_meaning` and `marathon.sh`'s halt table already read. A phase killed mid-run leaves `PHASE-INTERRUPTED.md` carrying the phase id, the relay `STATUS:` read **at interruption**, the round count and the reason — asserted on *content* against a marker stamped after dispatch, because "writes a partial transcript" was satisfiable by an empty or pre-created file, a real hole the issue's own adversarial review caught. **SIGKILL and a host panic remain unreachable and the code says so** rather than implying coverage; that is why #384's recovery path is a separate lane. `test/gh388-run-log-durability.sh` 24/0 — Part C kills a running phase, Part D kills a running chain, because a green success path proves nothing on an issue defined by what is missing after a failure. Observed **9 red** pre-fix (`test/baselines/GH-388-negative-control.md`). → [#388](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/388) · [#382](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/382) · [#419](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/419)
CHANGELOG.md:19:- **`rtl_default_log` silently relocated turn transcripts into the one directory a reboot erases, and the assertion pinning that behaviour has been inverted rather than deleted.** On any resolver failure — a misconfigured `XYZ_ARCHIVE_ROOT`, an uncreatable directory — both lanes returned `${TMPDIR}/<tool>-<pid>.log` **with the diagnostic suppressed** (`quiet=True` in Python, `2>/dev/null` in Bash). The evidence was therefore already gone by the time anyone had a reason to look for it, and nothing in the run indicated a choice had been made at all. Both lanes now **refuse (exit 5) before the turn launches**, and the resolver's stderr is no longer swallowed, because *why* the root failed to resolve is the whole of the fix from the operator's side. The trade was reversed knowingly: refusing costs a turn that has not started, whereas the fallback cost the record of a turn that had. **Adding a warning while still writing to volatile storage was considered and rejected in the issue's review** — the logs would still be destroyed, and the message would only mean someone could have known. `test/relay-turn-trace.sh`'s case 3c asserted the old fallback verbatim and now asserts the refusal, with the reversal's rationale written in place rather than the old case quietly disappearing. **The non-durable locations are stated in ONE file read at runtime** — `relay-automation/non-durable-log-roots.conf`, consumed by `durable-log-lib.sh` (Bash, same shape as GH-448's `driver-lock-lib.sh`) and `rtl.py::non_durable_reason` (Python). Two hardcoded lists would have satisfied "stated in one place" on paper and drifted in practice, so the test asserts both readers agree on every probe path **and** that an invented entry changes the verdict — without that second assertion the conf could be decorative while the real list lived in the readers. **One honest scoping deviation, recorded on the capture doc:** the rule targets *relocation*, so a transcript inside the repo being driven is permitted even when that repo sits in `$TMPDIR`; applying the criterion literally refuses to run the harness inside every fixture in this suite, and a guard that cannot be exercised is not a guard. → [#388](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/388)
CHANGELOG.md-20-- **`tick claim` announced its own failure and exited 0, and all three callers that could have read the announcement sent it to `/dev/null` — so the one command that knew the answer was silenced twice over.** At the per-agent cap (`MAX_ACTIVE_CLAIMS_PER_AGENT = 2`) `tick claim` printed `lost: claim limit reached (holding T-cite, T-offlane)` — the exact two tasks to release — and returned **0**. A caller doing the correct thing (`if ! tick claim …`) learned nothing, and the only remaining signal was stdout, which `rtl.claim_task_or_exit` and `marathon_drive`'s `_run_tick_loud` both discarded on *both* streams. **Both belts cut, so the turn failed with a message about the wrong thing**: `could not establish token ownership of TURN-2 (claimer=none) … inspect \`tick info TURN-2\`` — and `tick info` reports that token `status: open, handoff-to: agy`, perfectly healthy. The suggested diagnostic actively argued against the cause. On 2026-08-07 that cost roughly two hours of a live Litmus marathon. **Every `lost:` branch now exits 1** (cap, wrong owner, spent task), documented in `tick --help` alongside the existing 2/6/8 — and the idempotent re-claim by the holder, which `claim()` already reports as a *win*, still exits 0, which is the assertion that stops a naive "non-`won` is an error" fix from failing every healthy turn, since the shims all claim unconditionally on a token they may already hold. **The cap hit is now its own message** and names `tick reap <agent> --task <held>`; it mentions `tick info` only to say it will look healthy and is the wrong instrument, which is stronger than omitting it, because running it is exactly the operator's next reflex. The wrong-owner branch keeps the original wording, where `tick info` *is* right. **`_run_tick_loud` was a closure inside `main()`** whose name promised loudness while its body sent both streams to DEVNULL and then `sys.exit`ed on the result — the one path guaranteed to end the run was the one guaranteed to explain nothing; it is now module-level `run_tick_loud`, prints both streams on failure, stays silent on success (these fire four times per phase), and is directly testable for the first time. **The fix deliberately touches no `relay-automation/*-turn.sh`**: all five shims and `marathon-drive.sh` carry the GH-308 frozen banner, so `utils/py/` and `bin/tick` are the whole write-set. `test/gh408-tick-failure-visibility.sh` 22/0, observed **12 red** against the pre-fix sources with the full transcript in `test/baselines/GH-408-negative-control.md`. Criterion 6 (a resource failure still mislabelled `pre-advance-failed` when no gate ran) is **explicitly deferred to #407**, as that criterion's own wording allows — the mislabel remains, its cost does not. → [#408](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/408) · [#409](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/409) · [#407](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/407)
CHANGELOG.md-21-- **A turn that died before its own cleanup kept its tick claim, and two of those wedged an agent permanently — self-inflicted, and it never cleared itself.** The claim is taken in `rtl.claim_task_or_exit`, several hundred lines before `rtl_enforce`, which is what normally releases or hands it off. GH-432 already fixed the neighbouring half — a failed *agent* now reaches enforce — but three paths exit **above** it and never consult the agent's result at all: worktree setup failing (`sys.exit(5)`), containment rejecting the turn (`sys.exit(6)`), and any exception escaping. The claim simply stayed held, and since the cap is 2, the **third** turn was refused for a reason two phases old. `claim_task_or_exit` now arms an `atexit` release, and the property that makes it safe is that it is **idempotent by construction**: it re-reads `tick info` and releases only if the task is *still* claimed by this agent, so after a normal turn — token already handed to the peer under GH-67, or done — it does nothing and cannot clobber the handoff a successful turn just made. A blanket release would; there is an explicit assertion for it. Deliberately a `release` and not a `reap` (this process is the legitimate owner cleaning up after itself, and the event log should say so), and deliberately **no auto-reap on a cap error** — silently stealing a claim trades a loud stall for a race against a genuinely busy agent, which is the issue's own non-goal. SIGKILL and host panics stay the watchdog's job; `atexit` cannot reach them, and the code says so rather than implying coverage. **`test/gh409-claim-leak.sh` fails every case TWICE before asserting**, because the cap is 2 and a single leak is invisible — a suite that fails one turn and then succeeds proves nothing, which is precisely the shape of the notes both prior sessions left on these issues. 8/0, observed **4 red** pre-fix; the recorded control (`test/baselines/GH-409-negative-control.md`) is worth reading as the incident itself, since case 2 leaks two claims and the later cases then fail at the cap without ever exercising their own paths — the cascade that wedged the live marathon. The suite reaps between cases so each is an independent measurement, and refuses to pass a case that did not reproduce rather than reporting a silent skip as green. → [#409](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/409) · [#432](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/432)
CHANGELOG.md-22-
CHANGELOG.md-23-### Added
CHANGELOG.md:24:- **Release 0.3.0 Nightwatch's manifest is FROZEN at eight entries, before execution rather than during.** `RELEASES.md`'s own Nightwatch block already said to freeze first and named why — Litmus's scope grew by three issues mid-flight because its boundary was only a milestone — so the freeze is the first act of execution, not a later tidy-up. The six moved out of Litmus on 2026-08-08 (#408, #409, #426, #388, #358, #354 Phase 1) plus **#387 and #384**, added at freeze because the exit criterion *already names their cases*: it requires a cap-killed child and a restarted recovery, and nothing else in the milestone supplies either. Freezing with them in is honest; discovering mid-flight that the exit gate cannot be written without them is the failure mode the freeze exists to prevent. The **twelve** remaining open Nightwatch-milestone issues stay backlog inside the 0.3.0–0.3.4 band and gate nothing, per the block's own "a release is not its milestone" rule. Admission rule carried over from Litmus verbatim: discovery is not admission. → [#284](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/284)
CHANGELOG.md-25-
CHANGELOG.md-26-### Fixed
CHANGELOG.md:27:- **A test I added to prove GH-376 halted the very next marathon — it asserted on lock acquisition while inheriting the one variable that disables it.** `test/gh376-relay-drive-lock-parity.sh` passed **18/0** standalone, in a linked worktree, and in a fresh clone; inside Nightwatch wave 3's pre-advance gate it went **12/6** and stopped the chain at phase 1, for a defect in the test file rather than in the phase's own work (that lane's builder had added a new `marathon-recover.sh` plus a README section — nothing that could touch a lock). Cause: when `validate.sh` runs as a live marathon's gate it inherits `RELAY_DRIVER_LOCKED=1`, which `marathon_drive.py:649` exports so its NESTED relay-drive skips a lock the parent already holds. `gate_env.py` **deliberately does not scrub it** — that was tried, landed and reverted on 2026-08-07, and its docstring carries the measured four-suite table showing no single value is right for the whole gate. Inherited, every driver invocation in the suite skipped the lock block entirely and all six "must refuse" assertions inverted. **The remedy was already shipped and documented**: GH-441 Phase 1's per-suite clear, which `test/driver-lock.sh:11`, `gh284-runlog-heartbeat.sh:12`, `gh331-cost-summary.sh:24` and `gh342-sentinel-debug-log-python.sh:27` each already do; this file is the fifth to need it and simply failed to. **An `unset` alone would leave the behaviour untested, so it is now pinned instead of avoided**: new section F asserts that `RELAY_DRIVER_LOCKED=1` *does* skip acquisition on both lanes (the nested-driver contract), and that clearing the flag flips the same invocation against the same held lock back to refusing — so if this file is ever inherited-flag-poisoned again it fails loudly rather than going quietly vacuous. **One assertion was also weak enough to hide the failure**: the twin-parity check compared the two lanes' first output line for equality, which passed green while both lanes emitted the same NON-refusal; it now requires the matched line to be a refusal. 21/0 with a clean environment, 21/0 under the exact gate condition, and **7/15 when the `unset` is removed and the flag set** — verified in both directions rather than only the one under investigation. **Two further gate breaks from the same GH-376 change were found the same way and fixed together**: `test/path-integrity.sh` reads any path-shaped token in a comment as a real reference, so abbreviating this file's own name with an ellipsis broke it (the replacement spells the invocation out and records why); and `relay-pkg-freshness` went red with `drift: relay-automation/relay-drive.sh`, because editing that frozen twin staled `skills/relay-automation/relay-pkg.tar.gz`, which packages it — regenerated with `make-pkg.sh`. **The common cause is worth naming: GH-376 shipped after ~14 targeted suites and no full `validate.sh` run**, so the gate found three defects the author had never given it the chance to find, halting the same marathon phase twice. The tree is now verified with a complete run under the real gate condition (`RELAY_DRIVER_LOCKED=1`): **177 suites green**, `acorn-extract` excepted only where `npm ci` has not been run. → [#376](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/376) · [#441](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/441)
CHANGELOG.md-28-
CHANGELOG.md-29-### Fixed
CHANGELOG.md:30:- **A relay driver and a marathon driver could each hold what it believed was THE lock, against the same tree, invisible to each other — and the fix caught the collision happening for real while it was being built.** `marathon-drive.sh:195-196` asserts in prose that the two "still mutually exclude" because they share one lock NAME. From a normal clone that was true. From a **linked worktree** it was false: `.git` is a file, marathon-drive followed it to the git COMMON dir, and relay-drive's own inline 2-branch guess (`.git` is a dir → `.git/…`, ELSE a hidden lock beside the scripts) had no case for that at all, so it locked *inside* the worktree. Not an exotic topology — it is the one `swarm-preflight.sh:821`'s own recommended invocation creates via `RELAY_WORKTREE_ISOLATION=1`. **The fix is two call sites, not a new resolver:** both `relay_drive.py` and the frozen `relay-drive.sh` now route through the resolver GH-448 already shipped and proved (`utils/py/rtl.py::driver_lock_path` / `relay-automation/driver-lock-lib.sh`), so the two drivers agree by construction rather than by coincidence. **The observable is deliberately not a path string** — the drivers never print the path and the EXIT trap removes the lock, so nothing post-hoc can see where it went; `test/gh376-relay-drive-lock-parity.sh` instead holds a lock at the path *marathon-drive* resolves and runs relay-drive for real against a real `git worktree add`. If it agrees it must refuse; if it resolves anywhere else it sails past. That refusal **is** the mutual exclusion, observed end-to-end. 18/0, with the pre-fix resolution replayed on **both** lanes and observed sailing past the same held lock, normal-clone and vendored (no `.git`) controls proving the worktree case was not bought at their expense, and **source guards pinning that the resolver is CALLED, never re-inlined** — a correct re-inlined 3-branch copy would pass every behavioural assertion while recreating the exact drift class #448 exists to kill. The replay aborts loudly if the post-fix call site is missing, so it cannot go quietly vacuous later. **Confirmed live, not only in fixture:** mid-build, a marathon running in a *sibling clone* of this repo (pid 39588) held the lock in this repo's common `.git/`, and post-fix `test/poll-relay.sh` and `test/relay-escalation-not-stall.sh` began refusing from the linked worktree the work was happening in — both verified passing (12/0, 5/0) in a standalone clone with no driver running, rather than assumed. **Operational consequence, stated plainly:** the suite can no longer be run from a linked worktree while any driver holds the main clone's lock. Pre-fix it could, *because* the worktree got its own private lock — which was the bug. `relay-drive.sh` is frozen-twin pair #8, so its edit carries a `Frozen-twin-exception:` trailer; `marathon-drive`'s own resolution, `rtl.py`, and `driver-lock-lib.sh` are untouched, all stated non-goals. → [#376](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/376) · [#448](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/448)
CHANGELOG.md-31-
CHANGELOG.md-32-## 2026-08-10
CHANGELOG.md-33-
CHANGELOG.md-34-### Fixed
CHANGELOG.md-35-- **#460's SIGPIPE shape was still live in a release goalpost, where it inverted the verdict instead of adding noise — and a marathon had to lose the race to find it.** `test/litmus-release.sh:147`'s registration check did `printf '%s' "$inv" | grep -Fq "\"$gate\""`. `grep -Fq` exits the instant it matches and closes the pipe while `printf` is still writing; under `set -euo pipefail` that SIGPIPE becomes the *pipeline's* status, so **finding** the gate reported it as missing. The 2026-08-10 Nightwatch marathon halted on it: `FAIL: #375 is CLOSED but its gate is not complete — not-registered-in-validate.sh` for a gate registered at `validate.sh:91`, with six `printf: write error: Broken pipe` lines directly above the FAIL, and the same audit reporting **6/6 complete** when re-run by hand minutes later. **The fix for this exact symptom already existed five lines below it**: check (2) writes the inventory to a file precisely because it produced these warnings in CI. The conversion landed on the check where the consequence was cosmetic and not on the one that decides whether a release is done — and this is a live instance of the latent class #472 was filed and closed for, which the #460 entry below explicitly declined to blind-sweep across 366 files. **Why it survived until now: the real inventory is ~60KB at 173 gates, just under the 64KB buffer**, so `printf` usually finishes first and the check is *intermittently* correct — the worst possible shape for a goalpost. Fixed by grepping the file. **Mutation D pins it with three assertions rather than one**, because two of them are vacuous without the third: a precondition guard asserting the fixture inventory actually exceeds the buffer (120,397 bytes — otherwise the control passes against unfixed code), a **pre-fix replay observed reporting a registered gate as not-registered**, and the fixed check surviving the same input. The target gate is deliberately *first* in the fixture's `TESTS` array — grep must match early, while `printf` still has bytes left, or there is no SIGPIPE and the control proves nothing. Control mode: 6/0 → **9/0**. Two stale declarations corrected while there: `validate.sh:75` advertised the control as `4/0` when it had been 6/0, and now also states plainly that the suite **does not run** `--mutate-evidence`, so a reader does not assume the new control runs in CI. → [#460](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/460) · [#472](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/472)
CHANGELOG.md-36-
CHANGELOG.md-37-### Added
CHANGELOG.md:38:- **Release 0.3.0 Nightwatch, wave 1 authored and fired — one lane, and the number is the finding.** `PROJECT/2-WORKING/MARATHON-2026-08-10-NIGHTWATCH/`. Write-sets were read from each capture doc's preflight contract rather than carried over from Litmus's notes, and of the six named manifest members exactly **one** is marathon-buildable: #388 edits `marathon.sh`, the outer driver bash is reading by byte offset as the chain runs; #426 edits the turn kernel; #409+#408 and #354 carry no `## Swarm Preflight Contract` at all and so are not verdictable under GUIDING-PRINCIPLES §11. **The tempting rescue for #426 does not work and the plan records why**: "run it as a single phase so a wedge costs nothing downstream" fails because a phase is not one turn — the builder commits, then the *reviewer* turn re-sources the kernel it just changed, plus up to `max_review_rounds` more. Single-phase isolation contains a driver change, not a kernel change. **#358 was admitted despite Litmus wave 2 excluding it for editing CI**, because that write-set belongs to its Phase 2; Phase 1 is CI-free, and firing Phase 1 alone is what its capture doc *demands* rather than permits. A marathon cannot close the Nightwatch milestone — the same structural conclusion Litmus reached, recorded now rather than rediscovered at manifest freeze. → [#358](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/358)
CHANGELOG.md-39-- **The GH-484 `marathon-system/` default was exercised end-to-end by a real run, through the default rather than an override.** Phase output, the tick `--paths` claim and the builder's write allowlist all resolved to `marathon-system/nightwatch-wave-1-2026-08-10--gh358-lock-flake-instrumentation/`; `--dry-run` created nothing. **The GH-385 disagreement log fired in production for the first time** — `--retry` allocates a fresh token suffix, so the driver correctly saw a terminal relay whose new token was not `done` and *said so* instead of silently rebuilding, which is the entire point of that one line. A live-path exposure was contained rather than waved off: `utils/telemetry/append-xyz-completion.sh` is in the lane's write-set **and** is what the running driver invokes for its end-of-run record (`marathon.sh:69`, `marathon_drive.py:656`) — a coupling an artifacts-vs-driver-code grep does not surface, because it is an env-var default, not a call site. `XYZ_APPEND_BIN` was pinned to a pre-run snapshot; verified afterwards that the builder changed the tree copy while the snapshot's sha was untouched.
CHANGELOG.md-40-
CHANGELOG.md-41-### Fixed
CHANGELOG.md:42:- **`marathon-closeout.sh` commits the whole dirty working tree, not the lane's write-set.** The Nightwatch closeout swept **20 unrelated files / 10,397 insertions** into the lane's PR — four foreign `PROJECT/1-INBOX` capture docs, two stale pre-GH-484-rename `phases/` run outputs, and fourteen `relay-system/` consult transcripts belonging to the GH-484 and GH-448 lanes. The driver had printed `WARNING: workspace is not clean` naming those exact eight paths **one line earlier** and then committed them anyway: the warning and the commit disagree, and the commit wins. Reverted on the branch with `git rm --cached` so every file stays on disk in its prior untracked state; verified 20/20 in both directions with `comm`, touching no `gh358` or `marathon-system/` path. The closeout defect itself is on the triage list, not yet filed, per the standing no-new-issues gate.
CHANGELOG.md-43-
CHANGELOG.md-44-## 2026-08-09
CHANGELOG.md-45-
CHANGELOG.md-46-### Changed
--
CHANGELOG.md-80-- **GH-442 · first `/radar` calibration run on this repo — the skill survived contact with its own subject, at the price of four fixes it wrote into itself.** Full three-lens pass, window 2026-07-17..2026-08-07. **Flow:** Run 71% / Grow 4% / Transform 0% / Unclassified 25% over a 260-commit RGT denominator (178 harness commits excluded); trend vs the prior window is the headline — **Grow collapsed 15%→4%** while Run rose 54%→71%, read as the Litmus pivot executing, not drift. **Targets:** the #419 class (13 kinship citations) reported as *claimed by Litmus* — context, not recommendation; **RADAR-ensure-gitignore** is the top unclaimed target (#18 → #314 day 34 → #440 day 44, one function failing in both directions, 8-repo blast radius, score ≈24); **RADAR-class-foreign-repo-field-gaps** (#312/#438/#439) — 5 field reports in 10 days from 4 distinct vendored repos, none claimed by any band. **Lens 3:** Litmus aligned; **Nightwatch drifting** — the field is filing its theme early and the band claims none of it; orphan share 67/98 open issues (68%). **The four calibration fixes, each from a real divergence:** (1) `related:` citation counts conflate defect kinship with infrastructure context — #308 drew 11 citations, *all* FROZEN-twin contract references, and a naive tally would have ranked it the #2 defect cluster; kinship-language rule codified. (2) Harness prefixes must match as families — `relay-pkg:` leaked through the exact-match list. (3) Per-commit seam heat is flat in a squash-heavy repo (GH-432 fixed 5 shims in one commit = 1 count each) — group by issue. (4) Lens 3 gained the orphan-share line, the sharpest planning fact the run produced. **Bonus, on open question 5:** first confirmed instance of the doc-only-close recurrence predictor — #18 was created and closed doc-only within **2 hours** on 2026-06-24, and the same seam re-fired twice. Both sinks written on one confirmation: immutable [RADAR-REPORT-2026-08-07.md](PROJECT/1-INBOX/RADAR-REPORT-2026-08-07.md) (evidence) + [#444](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/444) under the new `radar` label (live checklist). Remaining Phase 1: the low-structure vendored-repo degradation run. → [GH-442-RADAR.md](PROJECT/2-WORKING/GH-442-RADAR.md) · [#442](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/442) · [#444](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/444)
CHANGELOG.md-81-- **GH-442 · `/radar` skill authored, after its Phase 0 kill gate ran and passed — by a stronger route than the plan expected.** The gate asked for one hand-run cluster the operator would confirm as high-value; the hand-run found that the operator had **already confirmed it before the radar existed**: tallying every issue reference inside the 66 `related:` frontmatter blocks in `PROJECT/**`, the top cluster center is **#419 (13 citations)** — the exact cluster the 2026-08-05 Litmus release was hand-derived from (*"derived from where the failures actually cluster, not from a backlog sweep"*). The method is validated by its own prior manual execution. Two Phase 0 findings changed the design before a line of the skill was written: **(1)** of 438 window commits, the top "prefixes" are `relay` (122) and `marathon` (43) — harness-generated turn/render commits that a naive Lens 1 tally would let swamp the signal, so the skill gained a fifth **Harness** bucket, counted but excluded from the RGT denominator (the remaining human work reads ≈94% Run / 6% Grow / 0 Transform, recognizable for a gate-repair period); **(2)** #419 is **class-shaped** (one defect class across many files) where `ensure_gitignore` is seam-shaped, settling the doc's open question 2 — clusters come in both shapes and the skill supports both ID forms (`RADAR-<seam-slug>` / `RADAR-class-<slug>`). Ships `skills/radar/SKILL.md` + `install.sh` (sibling symlink pattern): three lenses over a 21-day window, two-sink persistence (immutable dated `RADAR-REPORT-*.md` owns evidence; one `radar`-labeled issue owns the live checklist), never-re-slug alias rule for renamed seams, and a degradation table for repos missing `gh`/`PROJECT/**`/conventional commits. The doc-only-closure recurrence predictor (open question 5) is deliberately still untested — closed-issue archaeology, not rushed for the gate. Remaining Phase 1: end-to-end runs on this repo + a low-structure vendored repo. → [GH-442-RADAR.md](PROJECT/2-WORKING/GH-442-RADAR.md) · [#442](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/442)
CHANGELOG.md-82-
CHANGELOG.md-83-### Fixed
CHANGELOG.md:84:- **GH-441 Phase 1 · the marathon's own pre-advance gate could not pass, because it inherited the state it was supposed to judge.** `validate.sh` is `marathon-drive`'s **default** `--pre-advance-cmd`, so it runs as a child of a live driver and inherits `RELAY_DRIVER_LOCKED=1` (`marathon-drive.sh:245`, the nested-driver re-entrancy guard — correct for its own purpose). Inherited, it tells every driver a test spawns that the lock is already held, so suites asserting real lock/heartbeat/cost-summary behaviour measured the **parent** instead of themselves: `gh284-runlog-heartbeat` 20/0 → **15/5**, `gh331-cost-summary` 8/0 → **5/3**. `oracle-guard` fails the same way on an inherited `ALLOW_PATHS`. **Every affected suite passes standalone, every time**, which is the expensive part — this halted the Litmus marathon **twice** and was misdiagnosed as flakiness both times, the second time after three clean standalone re-runs. **Both wrong turns are recorded, because they are the argument for Phase 2.** The first remedy attempted was *skipping* the two suites in the gate — narrowing a gate to make a marathon pass, in the release whose entire theme is that a check which cannot fail is not evidence. The second was a **global** `unset` in `validate.sh`, landed and then **reverted**: it was measured on a clean tree with no parent lock, the one state in which the flag is never set, and in the real nested state it merely traded 8 failing assertions for 6 (`gh322` 17/3, `gh268` 31/3) — nested drivers need the flag SET, lock assertions need it UNSET, and its commit message claimed it "removes the need to skip any suite", which was untested and false. **The fix is what a global scrub ruled out but a per-suite one did not.** Only **two** suites were ever wrong, and both drive against their own throwaway `$A` from `test/_setup.sh` — so the lock they would acquire is theirs, not the ambient repo's, and each can clear the flag *for itself* while the other ~40 driver-spawning suites keep inheriting it. That is not a new idea: `test/driver-lock.sh:11` already does exactly this, with a comment naming this failure mode ("if this test runs UNDER a marathon gate, it would inherit that export and skip the very logic it's testing"). `validate.sh` is **unchanged** and **no suite is skipped**. Measured with the flag SET **and** the driver lock HELD — the state a real marathon produces, not a clean tree: **`gh284` 20/0, `gh331` 8/0, `gh322` 29/0, `gh268` 34/0, `driver-lock` 4/0, `oracle-guard` 11/0, identical standalone — and `bash validate.sh` itself exits 0 with zero failing assertions.** That last one is the end-to-end assertion the reverted commit never made, and making it is precisely what would have caught that commit being wrong. **A second, independent defect surfaced and was deliberately not folded in:** the driver's lock block runs at `marathon-drive.sh:189` but `--help` is not parsed until `:664`, so **`--help` refuses to print whenever any driver is active** — it emits the lock-contention notice instead. It was masking one `gh284` assertion, a help-text grep that has no business touching the ambient lock; that assertion was given its own `MARATHON_ROOT` rather than weakened, and the ordering fix is filed separately because it is a driver change needing Bash+Python twin parity (GH-308). **Phase 2 is still open and is the part that lasts:** `GATE_SCRUBBED_ENV` denylists three names while the driver exports ten-plus, `_gate_env()` is the natural enforcement point but every gate defends itself instead, and a custom `--pre-advance-cmd` has nothing to source — so any hand-written gate is silently wrong, which was observed live on the same run. Phase 1 fixed two names; it did not make the boundary governed. → [GH-441-GATE-ENV-CONTRACT.md](PROJECT/1-INBOX/GH-441-GATE-ENV-CONTRACT.md) · [#441](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/441) · [#419](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/419)
CHANGELOG.md-85-- **GH-432 · a failed builder turn took the one exit that skips `rtl_enforce`, so its work was never committed and its token never handed off.** The generic-failure branch called `sys.exit(5)` two lines above the timeout branch that deliberately falls THROUGH to `enforce` — so the single case where persistence matters most was the single case that skipped the file-scoped commit, the allowlist containment check, the transcript archive, the GH-67 token handoff, and the drift signal, all at once. Nothing in the code explained the asymmetry. **Worktree isolation made the loss precise rather than partial:** `worktree_end()` has already copied the agent's allowlisted edits back into the real tree by that point, so they sit there correct and uncommitted while the exit discards the only path that would commit them — the reporter confirms the lost Round-3 patch "closely matched the fix I ended up applying by hand." **All five Python shims shared the shape** (`claude`, `codex`, `agy`, `pi`, `aider`), so the report was reachable through four builders the issue never named; fixing only the reported file would have left it live. Exit 5 is unchanged — only the side effects preceding it. **`aider-turn` needed a second change to stay correct:** its GH-278 empty-stub cleanup was gated on `bounded_rc == 7`, which was sufficient only because a generic failure could never reach a commit; widened to any non-zero exit, or the GH-432 fix would have started committing 0-byte stubs as progress — the exact regression that guard exists to prevent. **The agy review of the first fix filed one Blocker and it was correct** — three shims (`agy`, `pi`, `aider`) carry a THIRD early exit with the same defect, the "backend exited 0 but produced NO output" guard, which is the harness declaring the turn failed and which leaked exactly what the crash path leaked by a different route. That route matters more than the reported one: a sandboxed `agy` run does precisely this, so the most likely field encounter was the case the first fix left open. Corrected as agy proposed (`sys.exit(5)` → `bounded_rc = 5`, reusing the new fall-through), with a dedicated negative control confirming the two new assertions observe it (2/2 fail when only that finding is reverted). New `test/gh432-failed-turn-persist.sh`, **12/0 post-fix with a 5/4 pre-fix negative control**, asserting only side effects (commit landed, token handed off) — an exit-code assertion would have passed throughout the defect's life and proved nothing. **Two defects in the test itself were caught by running that control:** `git show HEAD` was matching the seed commit and reported PASS while nothing had been committed, and the happy-path guard, ordered last, failed on the pre-fix replay because a leaked claim from an earlier crash case starves the claim cap — a true failure with a false explanation. Both corrected; the happy-path guard now runs first, and the commit check is scoped to `$before..HEAD`. Largely subsumes **#409**; **#408** is adjacent and untouched. The issue's second suggestion — a possible `RELAY_PEER` interaction with crash handling — was checked and declined: unset `RELAY_PEER` only reaches a WARN branch that cannot fail a turn. → [GH-432-TURN-FAILURE-PERSIST.md](PROJECT/2-WORKING/GH-432-TURN-FAILURE-PERSIST.md) · [#432](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/432)
CHANGELOG.md-86-
CHANGELOG.md-87-## 2026-08-06
CHANGELOG.md-88-
--
CHANGELOG.md-97-
CHANGELOG.md-98-## 2026-08-05
CHANGELOG.md-99-
CHANGELOG.md-100-### Added
CHANGELOG.md:101:- **Release planning: `0.2.0 Litmus` and `0.3.0 Nightwatch` added to `RELEASES.md`, with both GitHub milestones created and 32 open issues assigned.** Authored at explicit operator request, which is the sole trigger `RELEASES.md` permits (#381) — recorded here so a later reader does not mistake it for the fill-it-in drift that file warns about. **The two arcs were derived from where the failures actually cluster, not from a backlog sweep.** *Litmus* (17 issues, target 2026-09-05) is the observation layer: make every gate capable of reporting red, or downgrade it to advisory. Its spine is **#419**, and the sessions since it was filed kept supplying evidence — #418 (preflight reads neither issue state nor FROZEN banners), #425 (the source-URL gate compares the issue number and ignores the repo slug, so an unrelated repo's same-numbered issue passes), #426 (containment exits 6 correctly and the file lands in the harness root anyway, while the obvious test checked the other repo and passed), #416 (three shipped guardrails deleted, CI red two days, read as noise), #375 (`agy whoami` exits 0 on a TTY error, so the probe cannot fail in the headless context it exists for), #344 (24 of 49 issues got an already-done verdict from same-numbered foreign documents), #368 (a `--check` documented as a `validate.sh` drift guard that `validate.sh` never runs). *Nightwatch* (15 issues, target 2026-10-10) is unattended durability against a real target repo: #384 (a crash leaves a clean tree containing ungated commits and nothing reports it), #387 (a turn killed at its wall-clock cap is committed and gated as if it completed), #383 (a hanging gate stalls an unattended run indefinitely), #382 (a kernel panic with no signal in the telemetry), #402 (the run commits to whatever branch the target happens to have checked out). **The ordering is the recommendation, not the calendar.** Nightwatch's fixes are verified by the instruments Litmus exists to make trustworthy; shipping durability first means measuring it with checks that have never been shown capable of reading anything but green — the #419 shape applied to a whole release. `Iterations:` bands reserve `0.2.0-0.2.4` and `0.3.0-0.3.4` per the admission rule, so patch releases inside an arc are recorded in this file only. Deliberately left unassigned rather than padded in: the multi-agent swarm cluster (#423/#354/#415), which is a third arc with its own theme, and the prompt-stack analyses (#398/#404), which are findings rather than scoped work. `pdda.sh releases` **errors=0 warns=0**. → [#381](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/381) · [#334](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/334) · [#419](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/419)
CHANGELOG.md-102-
CHANGELOG.md-103-- **Acceptance criteria authored for seven Litmus issues, then reviewed adversarially by codex and agy in one consult — both found criteria satisfiable without the defect being fixed.** **First, a correction to the previous entry's count:** re-measuring with the gate's own extractor rather than a narrower grep showed **10 of 17** Litmus issues already had usable acceptance sections, not 7 — `ACC_HEADING_RE` accepts `## Suggested acceptance criteria`, which #409/#408/#407 carry (4/3/4 criteria). So seven issues needed authorship, not ten. **47 criteria were written for #343, #344, #358, #375, #388, #390, #401**, leaning on each issue's own stated constraints rather than invented ones — #358's *"do not lower M from 16 or drop the distinctness check"*, #390's deferral of gate-in-container, the GH-308 frozen-twin boundaries on #343/#375. **The review was worth more than the drafting.** Codex returned REWRITE on five of seven, agy on two, and **both independently found the same blocker in #343**: *"the two branches agree"* is satisfied by changing the **correct** branch to match the broken one — a criterion whose plain reading permits making the defect worse. Codex alone found #390's: every kill-path criterion was satisfied by a guard that kills *every* gate, because nothing required a normal gate to still pass and advance. **Codex read the tree rather than the issue text, and five of its factual claims were verified before any were acted on** — all five held. Two were errors of mine: #388's criterion asserted *"the repo's own PDDA lint already classifies those locations as non-durable"*, which is **false** (`check_hardcoded_paths` scans `pdda_list_working_docs` — documentation — and says nothing about runtime log destinations), and #401's *"writes nothing into any git repository"* was too absolute, contradicting a legitimate existing test that renders into a caller-supplied fixture root. **The fifth changed a lane materially: #344's root-resolution half already shipped** — `1612878` resolves `PROJECT/**` from the swept repo, and `test/gh369-find-doc-root-resolution.sh` pins the measured collision directly (*"case 5: same issue number from beta's cwd resolves BETA's doc"*). What remains is the identity guard the issue raised as an aside: `find-doc.sh` has **no** `gh_issue`/`source:` check, so a filename number match is still treated as identity. That is the **second** Litmus lane found mostly-shipped (after #416), both caught by reading the tree and neither catchable by preflight — which is #418's whole point. **Two reviewer findings were rejected with reasons:** agy's *"a file number match from the correct repository is sufficient"* contradicts #344's own *"Also worth a guard"* paragraph, and its *"remove entirely"* for #401's tracked-file question discards something the issue explicitly raises — codex's concrete-state replacement is better than deletion. **The cross-cutting finding is the one that outlives this batch** and is recorded on #419: *"observed failing against pre-fix code and recorded"* has no required location, command or result, so **the negative-control requirement is currently satisfiable by writing a sentence** — true of #400's `1 pass / 19 fail`, #410's `7 pass / 4 fail` and #422's `15/3` alike. All seven sets now require a durable baseline artifact naming the reproducer, the pre-fix revision, and both results. → [#419](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/419) · [#344](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/344) · [#390](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/390) · [#343](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/343)
CHANGELOG.md-104-- **Litmus lane prep: six capture docs, seven preflight-READY contracts, five ROADMAP entries, and today's marathon plan — all seven lanes gated on operator GO.** Prepared at operator request for release 0.2.0. **Measured before authoring rather than estimated:** of Litmus's 17 issues, only **7** carry a `## Acceptance` section, so only those can get a capture doc that is a verbatim copy. The other 10 were deliberately left unprepared — a capture doc for an issue with no acceptance section means the *model* writes the definition of done, and then the builder and reviewer both grade against that wording with no undamaged copy anywhere, which is the GH-202 inversion #400 exists to prevent. **Every acceptance block was machine-inserted from `gh`**, never retyped; all seven now read `acceptance: match` and `verdict: ready (exit 0)`. **Four findings came out of the preparation, none of which a plan on paper would have surfaced.** (1) `utils/marathon-plan.sh` carries the **GH-308 FROZEN banner**, and #368's own recommended fix is to delete a comment from it — so #368 is precisely the lane #418's frozen-artifact check would refuse, and both are in this release. Resolution recorded identically in both docs: **fire #368 first**, which costs nothing and leaves the check strict, rather than weakening it. (2) The plan generator's *"gated on operator GO"* decision is a **regex over the ledger entry's prose** (`gated on operator go|…|awaiting go`), so #425's entry — which said *"BLOCKED ON A DESIGN CALL, do not fire"* in plain English — was scheduled as an **active lane**. Reworded to a matching phrase so today's plan is correct; the defect is the #410 shape (a decision made by grepping prose) sitting in the planner. (3) **#416 is one criterion wide, not five** — criteria 1–4 shipped in PR #413 and were verified by direct inspection, so a doc restating all five would have sent a builder to rebuild four things that exist, and preflight could not have caught it (that is #418). Its remaining criterion cannot live in `PROJECT/PDDA.md`, which is **sync-managed** — a policy about surviving syncs, in a file the sync replaces, is the incident restaged. (4) **Two gates are mechanically incompatible**: fidelity requires the acceptance block byte-for-byte, `pdda-check-hardcoded-paths` rejects a path substring #417's criterion legitimately contained, and a `[changed]` deviation must quote the original text — **reintroducing the rejected substring**, so declaring the deviation cannot satisfy the second gate either. Resolved at the source by rewording the criterion **on the issue** (meaning-preserving, recorded in an issue comment); the general consequence — *an issue whose acceptance text names a path cannot be copied verbatim* — is recorded for the #419 inventory. **The suite caught one of my own errors:** #368's first deviation attempt declared a deviation against a still-verbatim list and was rejected as vacuous — the C8b hole closed during #399/#400, working on its author. → [#419](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/419) · [#418](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/418) · [#417](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/417) · [#426](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/426) · [#425](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/425) · [#416](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/416) · [#368](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/368)
CHANGELOG.md-105-
--
CHANGELOG.md-225-
CHANGELOG.md-226-### Changed
CHANGELOG.md-227-- **GH-264 Phase 3: the XYZ_PYTHON default is FLIPPED — this repo now runs the Python implementation by default (`XYZ_PYTHON` unset → Python).** One isolated commit (`af7bb4d`) changes only the toggle default `${XYZ_PYTHON-0}` → `${XYZ_PYTHON-1}` at all 11 entry-point shims — nothing else — so `git revert af7bb4d` is a guaranteed-safe, zero-collateral rollback. The entry gates (both merged in PR #262) were re-confirmed at HEAD before flipping: **Python `validate.sh` 117/117, zero Python-attributable failures** (`comm -13` empty), Phase-2 hardening in place (`-` not `:-`, python3≥3.8 guard w/ Bash fallback). Post-flip proof: with `XYZ_PYTHON` unset the default now routes Python (117/117, matching the old opt-in run); `XYZ_PYTHON=0` still routes Bash (116/117, only the pre-existing `marathon-drive.sh` GH-171/172 containment bug). **Rollback levers** (unchanged, now the documented default-off path): one command `XYZ_PYTHON=0 <command>` · session/CI `export XYZ_PYTHON=0` · permanent `git revert af7bb4d`. The inline Bash body stays in every shim, so the opt-out is real. Fleet propagation (the 8 vendored `.xyz/` copies) is a separate staged rollout, NOT done by this flip. → [#264](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/264) · [#255](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/255)
CHANGELOG.md-228-- **GH-255: the Python parity ports were QA'd by a Codex `/relay-xyz` review — 5 rounds, 8 real findings (2 Blocker, 6 Should), all fixed and verified; the branch's `utils/py/*.py` diff was graded line-for-line against the Bash source.** Drove Codex headless (`relay-drive.sh --review-once --artifact-file <diff>`) over the 1,300-line Python-twin diff. Each round surfaced *different*, real parity divergences a green 117/117 suite could not catch — the two most valuable being safety/contract gaps found by reading the Bash reference, not by any test: **(r4, Blocker)** `marathon_drive.py` silently dropped the GH-249 `--requires-test` contract (declared no such flag, `parse_known_args` swallowed it, and it approved after the gate) so under `XYZ_PYTHON=1` a caller got a false exit-0 `marathon.phase.approved` without the nominated test changing → ported the flag + `pre_phase_head` snapshot + `requires_test_delta` + the exit-5 `requires-test-missing` escalation (functionally proven: an unchanged test now escalates instead of approving); **(r2, Blocker)** `rtl.py`'s `_rtl_transcript_root` was a naive absolutize-only stub of the Bash archive resolver → full port (rejects non-absolute/missing/non-git `XYZ_ARCHIVE_ROOT`, namespaces `<archive>/relay-system/<repo-slug>`, `$TMPDIR` fallback). The 6 Shoulds: `marathon_plan.py` continuation-line + canonical-boundary doc-shim correctness (r2/r3), `_rtl_repo_slug` ASCII-only sanitizer vs Python `str.isalnum()` Unicode (r3), `rtl_default_log` resolver-stderr suppression on the fallback path (r3), the consult classifier honoring `RTL_CITATION_WINDOW` (r3), and the GH-75 lifecycle heartbeat write/clear omitted from `marathon_drive.py` (r5). Relay thread: `relay-system/2026-07-20/gh-255-python-cutover-parity-ports-review.md` (Closed by operator after one confirming round). Post-QA sweep unchanged: **Python 117/117, Bash 116/117, zero Python-attributable failures.** → [#255](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/255)
CHANGELOG.md:229:- **GH-255: Phase 1 of the Python cutover CLEARED — `XYZ_PYTHON=1 validate.sh` is 117/117 with ZERO Python-attributable failures, closing the cutover gate; the one remaining red (`marathon-drive.sh`) is a pre-existing BASH-only bug, split to #261.** The #255 ledger's 10 Python-only-failing files are closed and verified two-mode on branch `gh255-phase2-toggle-harden`. **`utils/py/marathon_drive.py`** ported to full parity (test/marathon-drive.sh 89/23 → **112/0** under Python): GH-207 lane namespacing + byte-identical re-render skip (git `diff --cached --quiet`, no more "nothing to commit" halt) + satisfied-lane recovery (`--review-once` reroute + `lane_already_satisfied`), GH-238 gate-runnable preflight (exit 2 before spending a turn, ordered *after* the binary probes so a missing builder still fails first), `--require-clean` linked-worktree lock relocated to the git-common-dir, GH-162 debug-mantra note, GH-205 timeout recovery — which also greened the two files that only fail *through* it (`marathon.sh` 33/0, `debug-mantra.sh` 14/0). **Four independent twins ported in PARALLEL via a subagent workflow**, each independently re-verified green in both modes: `swarm_preflight.py` (88/8→96/0: GH-203 stale `.git/index.lock`, contract-heading detection, artifacts-subset validation, effective-artifacts/`fs_touching_tests`), `consult.py` (55/7→62/0: the whole GH-235 A4 prompt-trace provenance surface — `.PROMPT.txt` snapshot, ECHOED-vs-FIRSTHAND classifier, `.PROVENANCE.txt` sidecar), `marathon_plan.py` (55/5→60/0: GH-150 docOf lane-pointer + GH-86 review-lanes overlay, as twin-side shims because the drifted `_marathon_plan_node.js` engine was out of the port's scope — flagged for a cleaner direct sync), `aider-turn.py` (57/4→61/0: GH-168/186 `--add-gitignore-files` capability probe + GH-251 transcript-salvage backstop). **`relay_drive.py`** (GH-198 Setup-artifact preflight exit-2 + GH-245 `--review-once` evidence-of-work oracle). **`codex-turn.py` + `rtl.py`** (GH-161 persistent turn transcript — new `rtl_default_log`, `RTL_LOG` exported before the first rtl call, and append-not-truncate so `rtl_init`'s trace survives). A caught-in-flight regression — the GH-238 preflight's `bash -n` syntax check tripped `test_python_layer.py`'s "no subprocess before the builder-binary check" contract — was fixed by ordering the preflight after `_probe_agent_bin`. **Same-commit two-mode sweep: Python 117/117 (Python-attributable set = ∅, the cutover criterion), Bash 116/117.** The lone Bash red, `marathon-drive.sh` GH-171/172 (vendored `.xyz/` + worktree + macOS `$TMPDIR` containment exit-6), is a multi-factor bug in the permanent-Bash containment core (`relay-turn-lib.sh` `/var`-vs-`/private/var` symlink-form strip + inherited `TICK_REPO_ROOT`) that pre-dates this work and does NOT fail under Python (the Python driver resolves paths consistently and sidesteps it); a partial symlink fix was **reverted** to keep the safety core clean, with the full diagnosis on #261 for a reviewed fix. → [#255](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/255) · [#261](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/261)
CHANGELOG.md-230-- **GH-255: Phase 2 of the `XYZ_PYTHON` flip executed — all 11 shim entry points hardened, behavior-provably unchanged; surfaced + filed #261 and #260 from the first real vendored-copy dogfood.** Ran UPGRADE.md §4 on branch `gh255-phase2-toggle-harden`: **(2a)** `${XYZ_PYTHON:-0}`→`${XYZ_PYTHON-0}` at all 11 sites so an explicit *empty* `XYZ_PYTHON` reads as not-1 → Bash (the colon-dash "clear the var to turn it off silently gets Python" trap, load-bearing only once the default flips); **(2b)** a version-enforcing guard (`command -v python3` **and** a `>=3.8` predicate) that falls back to Bash with a warning instead of `exec`-ing a missing/too-old interpreter — the single scariest flip failure mode (every entry point bricked) becomes a graceful degrade. `utils/marathon-plan.sh` keeps its GH-154 `--zones-config → QUEUE_PLAN_ZONES_FILE` translation *inside* the guarded branch (not collapsed to the generic shim). **Behavior-preserving, proven not asserted:** condition-line invariant holds (exactly one distinct line across all 11); `bash -n` clean on all 11; the truth table verified empirically (`empty -1 → BASH` where the old `:-1 → PYTHON`; version guard `EXEC-PYTHON` vs `FALLBACK-BASH`); and a full two-mode `TEST_SOFT_FAIL=1` `validate.sh` sweep at the same commit showed the **Python-attributable set did not grow** — still 9 files (`comm -13`: swarm-preflight/consult/debug-mantra/marathon/marathon-plan/relay-artifact-file/relay-turn-trace/aider-turn/relay-review-once), exactly #255's list minus the already-fixed `agy-turn.sh`. Bash mode 114/117, Python 105/117 (up from #255's 104/116 via the agy-turn fix). Editing the bundled shims made `relay-pkg.tar.gz` stale (the `skill-extract.sh`/`relay-pkg-freshness.sh` guards correctly caught it) → regenerated via `make-pkg.sh`, which also cleared the pre-existing `relay-pkg-freshness` staleness #255 flagged, so Bash-mode failures drop to just `marathon-drive.sh`. **Phase 3 (the flip) stays blocked** until Phase 1 is clean. **Two issues filed from the same dogfood** (first real vendored-`.xyz/` leaf, `hyper-pandas-python-stack`): **#261** — reconcile the `marathon-drive` Bash/Python disjoint-failure union (the last Phase-1 gate #255 said needs its own issue, which never existed); **#260** — UPGRADE.md leaf/bootstrap/root-ordering gaps, now folded into the doc (a §0.5 STOP gate for "vendored copy + unflipped root", the absent-`.xyz/` bootstrap note, "pick a full clone to dogfood the flip", and a §9 "re-vendor a stale copy before judging parity" note). The dogfood itself proved the port sound IRL on the copy: locator green, `TICK_REPO_ROOT` correctly at the consumer root (not `.xyz/`), exit-code parity on error paths, and the swarm-preflight gap reproducing identically to root HEAD (88/8). → [#255](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/255) · [#261](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/261) · [#260](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/260)
CHANGELOG.md-231-
CHANGELOG.md-232-### Added
CHANGELOG.md-233-- **Runtime triage labels for the post-flip dual-runtime harness — `runtime:python` / `runtime:bash` / `runtime:parity` created in the repo, and `/file-xyz-bug` now harvests+applies them.** Since the `XYZ_PYTHON` flip a harness bug can live in the Python twin (default), the legacy Bash opt-out path (`XYZ_PYTHON=0`), or as a *divergence* between the two (`runtime:parity` — e.g. `agy-turn.py` failing open where `agy-turn.sh` exits 5). `skills/file-xyz-bug/SKILL.md` gains a Runtime harvest row (a `.py` traceback ⇒ python, an inline `line NNN:` shell error ⇒ bash, differing behavior at the same commit ⇒ parity), a `--label "runtime:*"` step in `gh issue create` (omit rather than guess if unclear), and a Runtime line in the capture doc's Environment block. Labels only — no code path changed.
--
CHANGELOG.md-244-
CHANGELOG.md-245-## 2026-07-20
CHANGELOG.md-246-
CHANGELOG.md-247-### Fixed
CHANGELOG.md:248:- **Marathon Plan L fired end-to-end on branch `marathon/plan-l-followup-2026-07-19` — 3 lanes (GH-251, GH-241, GH-218), all preflight exit 0, single wave, gate green relative to baseline.** The post-marathon follow-up queue ([MARATHON-PLAN-2026-07-19-L](PROJECT/2-WORKING/MARATHON-PLAN-2026-07-19-L-POST-MARATHON-FOLLOWUP.md)) was carried from a fresh `swarm-preflight --gh-issue` (3× exit 0), through a disjoint-write-set overlap check (`relay-automation/aider-turn.sh` ‖ `bin/marathon-yaml`+test ‖ `utils/hq/*`+tests — no intersection, so one wave), to execution and gating. Run **serial Opus-direct** rather than worktree-isolated subagents: only 3 small lanes, and the Agent worktree-isolation branches from `main` not the marathon branch (GH-225), so a serial pass on the branch avoids the cherry-pick reconciliation for no concurrency benefit. **GH-241** — `bin/marathon-yaml` now rejects the `depends_on` YAML flow-sequence form (`[p1]`) with a shape-specific "flow sequence" error instead of the bewildering `unknown phase '[p1]'` lookup at `bin/marathon-yaml:102-105`; this is the code fix (3) the 2026-07-19 docs-only pass deliberately deferred, plus a `test/marathon-yaml.sh` regression case (list form → shape error; scalar still parses). **GH-251** — the OpenRouter/aider reviewer seam gets two complementary fixes inside `relay-automation/aider-turn.sh`: an explicit **review mode** posture on review-only turns (append a graded review to the relay file — the only writable target), and a **transcript-salvage backstop** that, when a review turn lands no relay-file delta but the transcript carries a `Verdict:` anchor, appends the transcript (attributed) so the completed review lands instead of being discarded as a stall — composes with the GH-245 `--review-once` classifier (an empty/non-review turn leaves no anchor → not salvaged → still a genuine stall); two regression cases added. **GH-218** — new read-only `utils/hq/marathon-live.sh` reports cross-repo LIVE marathon status by composing existing local primitives (repo registry, each repo's own `tick project` STATE.md `## Claimed` section, driver-lock + `marathon/*`-worktree liveness cross-check) with no new per-repo MCP server; `utils/hq/rollup.sh` embeds it as a `## Live Marathons (cross-repo, right now)` section via a shared `demote_embed` helper. Tests: `test/hq-marathon-live.sh` (live/claimed-not-driving/idle fixture matrix, read-only asserted) registered in `validate.sh`; `test/hq-rollup.sh` extended with the embedded live section + a live-status-failure banner case. Each lane stayed within its contract's `artifacts` allowlist (plus the one-line `validate.sh` test registration for GH-218). **Gate:** `bash validate.sh` — the 5 reds (`marathon-drive.sh`, `relay-pkg-freshness.sh`, `acorn-extract.sh`, `relay-self-sufficiency.sh`, `python:test_python_layer.py`) were confirmed pre-existing/environmental by re-running each on `development` (identical failures); all 4 new/touched test files pass. Auto-drafted GH-241/GH-251 contracts were verified against the real code during the run. **Merged to `development` via PR #256.** → [#241](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/241) · [#251](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/251) · [#218](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/218)
CHANGELOG.md-249-
CHANGELOG.md-250-## 2026-07-19
CHANGELOG.md-251-
CHANGELOG.md-252-### Changed
--
CHANGELOG.md-301-
CHANGELOG.md-302-### Added
CHANGELOG.md-303-- **[GH-221](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/221) — explicit builder/orchestrator role split, closing a real doc gap causing session drift.** Some Claude Code sessions had started trying to use the Claude CLI as a marathon/relay builder. The code-level default was already correct (GH-212: `--builder` defaults to `codex`), but the only existing doc caveat was cost-framed ("don't assume it's free"), never role-framed — nothing stated that Claude Code is the orchestrator/reviewer, Agy/Codex CLI are the builders, and Claude CLI is an explicit user opt-in only. Worse, the vendored `skills/relay-xyz/SKILL.md` — the doc a vendored `.xyz/` install's own sessions actually read — had zero mention of a role split at all. Fixed both: added the explicit role statement to `AGENTS.md`'s "Repo-specific rails" and to `skills/relay-xyz/SKILL.md` (this file IS in `xyz-vendor.sh`'s `VENDOR_DIRS`, so it reaches every vendored `.xyz/` install on its next re-vendor — existing already-vendored copies need a manual re-vendor to pick it up immediately). Docs-only, no script behavior changed. `pdda.sh run` clean (pre-existing unrelated failures on GH-141/151/152/155 left untouched, out of scope).
CHANGELOG.md-304-- **PR #217 merged into `development` (not `main`) — widened the GH-216 "development is the WIP branch" policy to cover marathon-fired lanes too.** Originally opened against `main` per the existing GH-212 convention; retargeted mid-flight after confirming it was mechanically safe (`development` was a strict ancestor of the PR branch, 0 divergence). `gh pr merge --delete-branch` crashed mid-operation with a local `.git/index.lock` error (the PR merged fine on GitHub's side; the local branch ref just didn't fast-forward and the remote branch didn't get deleted) — recovered via `git merge --ff-only origin/development` plus a manual `git push origin --delete`. `AGENTS.md`'s rail updated: marathon/relay-fired lanes now branch off and PR into `development`, same as manual work; `main` no longer receives direct marathon merges. Local memory (`development-branch-is-wip-branch.md`) updated with both the policy widening and the `index.lock` recovery steps, so future sessions don't have to rediscover them.
CHANGELOG.md:305:- **Recent-issues (last 10 days) sweep — 4 new lanes triaged, captured, and fired as a combined marathon.** Reviewed every GitHub issue opened in the last 10 days for validity/reproducibility/completion; most were already captured or handled by prior passes. Four were new, still reproducible, and lane-sized: **[#208](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/208)** (`worktree-isolation.sh`'s moved-ROOT-HEAD race — reproduced 8/9 fail on 9 local runs, a genuine timing race not the "env-unfixable" the title speculated; queued into Marathon Plan F as Lane 12), **[#154](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/154)** (`utils/py/_marathon_plan_node.js` missing the GH-48 zone model that `utils/marathon-plan.sh` has — confirmed 0 references, no fix landed since filing; queued as Plan F Lane 13), **[#149](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/149)** (`marathon-drive.sh --require-clean` self-trips on its own `.relay-driver.lock` inside a linked worktree — confirmed still present by direct code read; new Marathon Plan G Lane 1), and **[#198](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/198)** Bug 2 only (`relay-drive.sh` has no fail-fast preflight check for a missing Setup-referenced artifact — Bug 1 of this issue turned out to already be fixed separately, commit `bee1abf`, `test/relay-commit-pathspec.sh` 9/9; new Plan G Lane 2). Wrote capture docs + Swarm Preflight Contracts for all four, verified each `ready` (exit 0) via `swarm-preflight.sh --gh-issue N --dry-run` individually (a combined `--gh-issue` bundle correctly refused with exit 7, "gate commands differ" — the 4 lanes have different `gate` tests, as expected for independent fixes). Added the two Plan-F-fitting lanes (208, 154) to `MARATHON-PLAN-2026-07-07-F-VALIDATE-FIXES.md`; authored a new `MARATHON-PLAN-2026-07-17-G-DRIVER-HARDENING.md` for the two driver-hardening bugs (149, 198), which don't fit Plan F's validate.sh/parity theme. Confirmed all 4 lanes' file sets are mutually disjoint (no write-set collisions), built a single 4-phase `MARATHON.yaml` (fully parallel, no `depends_on`) under `PROJECT/2-WORKING/MARATHON-2026-07-17-GH208-154-149-198/`, cut branch `marathon/gh208-154-149-198-2026-07-17`, and fired it via `marathon.sh --plan`. `#174`/`#215` (Plan F Lanes 10-11, ready from a prior pass) were deliberately left out of this fire — #174 shares `test/marathon-drive.sh` with #149, and firing both concurrently would collide; they remain available to fire separately. **All 4 phases Approved** (codex builder, agy reviewer, `bash validate.sh` gate each phase). Verified each fix by diffing the branch against `main` rather than trusting the "Approved" status alone: **#208**'s real root cause was NOT the suspected `relay-turn-lib.sh` race — it was a test-fixture timing bug (case 5's async write hadn't landed before case 6's cleanup), fixed with a 2s wait in the fixture; 8/8 clean repeated runs post-fix. **#154** ported the GH-48 zone model into `utils/py/_marathon_plan_node.js` and additionally had to wire `--zones-config` → `QUEUE_PLAN_ZONES_FILE` through `utils/marathon-plan.sh`'s `XYZ_PYTHON=1` dispatcher for the flag to survive the shell→Python→Node handoff; `test/marathon-plan.sh` 60/60 (2 new parity cases). **#149** resolves the driver lock via `git rev-parse --git-common-dir` in a linked worktree; `test/marathon-drive.sh` 105/105. **#198** Bug 2 added a Setup-artifact preflight check to `relay-drive.sh`; `test/relay-artifact-file.sh` 13/13. Full `bash validate.sh` post-marathon: 113/114 — only `relay-pkg-freshness.sh` red (the marathon's own commits touched `relay-turn-lib.sh`-adjacent scripts without rebuilding the packaged tarball), fixed by rebuilding it via `make-pkg.sh` and regenerating `ROADMAP-DASHBOARD.md`. The 4 capture docs' Status tables and checklists were NOT updated by the marathon builders despite the briefs asking for it — updated them by hand from the verified diffs instead of trusting the builder's self-report. `bash utils/pdda/pdda.sh run`: all checks passed after fixing two doc-hygiene errors this sweep introduced — a Status-table cell that broke the checker's naive pipe-split (a `||` inside inline code) and a missing `## Status` table in the new Plan G doc.
CHANGELOG.md-306-- **New `/10days` skill, dogfooded live on its first run — 11-14-day issue sweep, 5 of 6 candidates shipped.** Built `skills/10days/` (SKILL.md + `scan-issues.sh`/`find-doc.sh` deterministic helpers) to automate: scan a GH issue age window → verify each is still valid/reproducible/not-already-fixed via subagent fan-out → build + preflight a marathon → cut a branch and execute, unattended. Statically reviewed via `/consult --models agy` before running (caught and fixed: unsafe hand-rolled JSON in `find-doc.sh`, a `swarm-preflight.sh` multi-`--gh-issue` bundling misunderstanding, missing concurrent-marathon/behind-origin checks, no worktree isolation for parallel lanes). First live run (11-14 day window, chosen to not overlap the concurrent `#208/#154/#149/#198` sweep) scanned 16 issues, excluded 7 with commit/PR evidence (already-landed: #109, #111, #144, #96; gated-on-another-issue: #153; stale/paused: #97, #156, #157) and 2 more (#149, #154) for being actively claimed by that concurrent marathon — a collision the skill's own logic didn't catch on its own; caught by cross-referencing the other marathon's branch name live. Surfaced a real design gap along the way: `marathon-plan.sh` ranks the *entire* ROADMAP ledger, not just a sweep's own candidates, so its generated waves silently included the 2 already-claimed issues — fixed `SKILL.md` to require filtering to the sweep's own candidate set before firing anything. 6 issues survived triage; **5 shipped**: [#110](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/110) P2b (`test/roadmap-dashboard.sh` skip-guard + new top-level `run-tests.sh` entry point, `49c7b8d`), [#147](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/147) P2 (LM Studio lane threaded through the production Aider relay turn shim, byte-identical default OpenRouter path, 55/55 tests, `160c0fe`), [#151](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/151) P4 (cost-observability coverage-truth spike: Codex usage surface feasible, agy confirmed structurally cost-blind, Gemini relay-lane recommended for retirement, `7c77e4f`), [#152](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/152) P6 (`relay-drive.sh` now auto-surfaces the `tick analyze` cost block at end-of-run behind an env toggle, wired through the existing `EXIT` trap without touching the real exit code, `89d823a`), [#155](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/155) (3 new agy hardening regression cases — S2/S5/S8 — 54/54 own tests, `5f37954`). **[#141](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/141) deliberately shipped no fix** — investigated and correctly declined: no code-only signal can distinguish a peer session's concurrent edit from the agent's own off-lane self-escape (both produce identical porcelain diffs), and `rtl_enforce`'s revert is the documented backstop for a real, already-exploited self-escape vector (GH-22) — "fixing" this without an attribution signal would silently disable that protection. Recorded two non-detection follow-ups (recoverable backup-before-revert; document the don't-hand-edit-a-live-clone constraint) for an operator decision instead. Consolidated Wave 1 gate surfaced two real (non-flaky) cross-lane issues only visible once all 5 lanes merged together: a new unbaselined `credential-literal` finding from `#147`'s test fixture (`test/aider-turn.sh:322`, a dummy key — baselined, same class as the existing `test/deep-research.sh` entry) and a stale `relay-pkg.tar.gz` (two lanes each regenerated it for their own change via `make-pkg.sh`, but neither reflected the other's — refreshed once against the fully-merged tree). `worktree-isolation.sh` and `acorn-extract.sh` also failed in the gate; independently verified both fail identically against the pre-merge base commit in a scratch worktree (pre-existing GH-208 flaky race; missing `acorn` npm module) before ruling them out as unrelated. Live incident along the way: worktree directories (including the sweep's own and multiple lane worktrees) were deleted out from under running agents mid-`validate.sh` by an external, unrelated process — no committed work was lost (all recoverable from the branch), but it forced a switch to faster, targeted per-lane gates instead of the full suite to reduce the exposure window.
CHANGELOG.md-307-- **[GH-215](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/215) filed — GH-172 cutover-recommendation follow-up, plus Marathon Plan F made preflight-valid and a stale-issue finding.** Filed #215 for the residual `utils/py/consult.py` degraded-panel `SINGLE-MODEL — NOT RECONCILED` parity gap GH-172's cutover recommendation named. Added it to Marathon Plan F as Lane 11, alongside re-scoping Lane 10: **#174**'s actual code fix (the `utils/py/agy-turn.py` claim-before-launch guard) turned out to already be landed as a side effect of GH-172 Phase 0 (commit `7e9e683`, confirmed live) — commented on #174 with the evidence rather than closing it, since its own checklist's dedicated regression test is still missing; re-scoped to test-only (cx/risk/eff 2/1/2 → 1/1/1). While building Swarm Preflight Contracts for the plan's remaining lanes, **found Lanes 1-9 (umbrella #170) are themselves STALE**: `swarm-preflight.sh --gh-issue 170` returns exit 4, and all 9 originally-failing tests now independently verify green (incl. 5x repeats of the two confirmed-flaky lanes; full `validate.sh` shows only the pre-existing `#208` red repo-wide) — root cause of the flip unconfirmed (no commit explains it, unlike #174), commented on #170 recommending closure rather than closing unilaterally. Promoted `GH-170-VALIDATE-FAILING-TESTS.md`, `GH-174-AGY-PY-CLAIM-GUARD.md` (both `1-INBOX` → `2-WORKING`) and `MARATHON-PLAN-2026-07-07-F-VALIDATE-FIXES.md` (`4-MISC` → `2-WORKING`, required for `marathon.sh --plan`'s GH-212 plan-location guard), added Swarm Preflight Contracts to all three plus `GH-147-LM-STUDIO.md` (scoped to its Phase 2). `swarm-preflight.sh --dry-run` confirmed ready (exit 0) for #174, #215, and #147. `bash utils/pdda/pdda.sh run`: all checks passed.
CHANGELOG.md-308-- **[GH-172](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/172) — vendored harness root-semantics audit: 4-phase marathon merged via [PR #214](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/pull/214); #172 closed.** Phase 0 (already-shipped root/claim parity fixes) plus 4 new phases, codex builder/agy reviewer, `bash validate.sh` gate: **Phase 1 (Bash audit)** checked `marathon-drive.sh`, `relay-drive.sh`, `marathon-agent.sh`, `relay-turn-lib.sh`, `aider-turn.sh`, `consult.sh`, `relay-loop.sh`, `watchdog.sh`, `runner.sh`, and `swarm-preflight.sh` against the three-root contract — found and fixed a real gap in `relay-automation/consult.sh` (stale `${TICK_BIN:-$ROOT/bin/tick}` fallback broke the tick-binary/coordination-root split in a vendored/root-split run), every other file verified clean. **Phase 2 (Python audit)** checked `marathon_drive.py`, `relay_drive.py`, `rtl.py`, `aider-turn.py`, and `consult.py` for parity with the hardened Bash behavior — found and fixed the matching gap in `utils/py/consult.py`, plus an unrelated `utils/py/relay_drive.py` warning-parity gap (same-repo vs. cross-repo uncommitted relay-file visibility warning didn't match the Bash split). **Phase 3** extended `test/marathon-drive.sh` with vendored `.xyz` consumer-repo E2E coverage (builder + reviewer legs, both Bash and `XYZ_PYTHON=1`). **Phase 4** wrote the durable root contract into the capture doc and an explicit cutover recommendation: safe to cut a stable Bash branch now; **not yet safe** to switch `main` to Python-default — `utils/py/consult.py` still lacks the Bash degraded-panel `SINGLE-MODEL — NOT RECONCILED` stamping, keeping `XYZ_PYTHON=1 bash test/consult.sh` red — filed as [#215](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/215), see its own entry below. Full `validate.sh` green except the pre-existing, tracked [#208](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/208) environment red — independently re-verified outside the marathon's own gate. Capture doc + findings: [GH-172-VENDORED-ROOT-AUDIT.md](PROJECT/3-COMPLETED/GH-172-VENDORED-ROOT-AUDIT.md) · [GH-172-BASH-AUDIT-FINDINGS.md](PROJECT/3-COMPLETED/GH-172-BASH-AUDIT-FINDINGS.md) · [GH-172-PYTHON-AUDIT-FINDINGS.md](PROJECT/3-COMPLETED/GH-172-PYTHON-AUDIT-FINDINGS.md) · [GH-172-CUTOVER-RECOMMENDATION.md](PROJECT/3-COMPLETED/GH-172-CUTOVER-RECOMMENDATION.md).
CHANGELOG.md-309-- **GH-213/209/203 — 3-lane marathon, all Approved, first real dogfood of the GH-212 conventions.** All three built from the last-7-days issue sweep, each with a capture doc + Swarm Preflight Contract under `PROJECT/2-WORKING/`. **GH-213**: `find-harness.sh --check` gains a case-collision detector (two git-tracked paths differing only by case — a macOS `core.ignorecase=true` landmine distinct from GH-17's narrower fix), `test/find-harness.sh` 20/20. **GH-209**: scope narrowed from the issue's full architectural ask (risks breaking GH-206's zero-config goal) down to a static audit (`test/marathon-root-audit.sh`, 13/13, new) — codex's own build turn found and fixed the ACTUAL root cause behind a gate false-negative hit earlier in this same marathon: `MARATHON_LANE_NS` leaking from a live `marathon-drive.sh` process into a nested `test/marathon.sh` invocation's own rendered paths. **GH-203**: scope narrowed to a non-destructive `swarm-preflight.sh` preflight warning for a stale `.git/index.lock` (`lsof`-based, advisory-only, never changes the verdict), `test/swarm-preflight.sh` 94/94 (+7 new cases). Two recoveries needed along the way, both cleanly diagnosed and fixed rather than papered over: (1) gh213's own shared `--pre-advance-cmd` nested `test/marathon.sh` inside the still-live outer marathon process, causing the false-negative above — worked around by verifying that suite standalone instead of nested; (2) gh209's agy review tripped the known, already-tracked GH-183 isolation-breach false positive (content-scan flagging a legitimate mention of "the real repo root") — the actual review was independently re-verified as correct and its Approved content committed by hand after re-running every affected test suite standalone. Also found and fixed in passing: the phase-brief `.md` files this marathon wrote under `PROJECT/2-WORKING/` tripped PDDA's blanket frontmatter/status-table enforcement (every `.md` there is scanned as an active-doc capture) — added minimal frontmatter + `roadmap_exempt: true` to mark them as consumed builder-input, not capture docs. Full `validate.sh` green throughout except the pre-existing, tracked [#208](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/208) environment red. Capture docs: [GH-213-CASE-COLLISION-LANDMINE.md](PROJECT/3-COMPLETED/GH-213-CASE-COLLISION-LANDMINE.md) · [GH-209-MARATHON-ROOT-LEAK-AUDIT.md](PROJECT/3-COMPLETED/GH-209-MARATHON-ROOT-LEAK-AUDIT.md) · [GH-203-STALE-INDEX-LOCK-PREFLIGHT.md](PROJECT/3-COMPLETED/GH-203-STALE-INDEX-LOCK-PREFLIGHT.md).
--
CHANGELOG.md-436-### Wave 2: GH-143 front-door gate + GH-144 PDDA governance docs (parallel subagent lanes)
CHANGELOG.md-437-Fired the next collision-safe wave as two parallel drafting subagents (disjoint write-sets; orchestrator commits sequentially — the `marathon-execution-pattern`, not headless codex, since both are gate-less judgment-heavy authoring lanes). **GH-143** (`67068da`): hoisted `find-harness.sh --check` from ~50 lines deep to line 21 of `skills/relay-xyz/SKILL.md` as a hard gate right after the H1 ("ALWAYS run this first — never claim the harness is missing without running it"), and added a "Per-repo persistence (don't cache a path)" section — closing FRONTDOOR.md rows **FD-11**/**FD-12** (both verified + flipped ✅). **GH-144** (in `1019503`+`52f4521`): synthesized the 2026-06-23 external feedback review (Perplexity/ChatGPT/Gemini) into two canonical governance docs — `PROJECT/CONSTITUTION.md` (policy of record: PDDA's lane + 5 non-negotiables) and `PROJECT/DO-NOT-BUILD.md` (anti-scope list, each item tied to the incumbent that owns it) — linked both from `ROUTER.md`'s Role split (the Phase-1 startup-path QA gate). Both issues stay **open** (GH-143 still has FD-09/FD-10; GH-144 Phases 2–5 deferred/decision-gated). Notable: a concurrent peer session's Aider auto-commit (`1019503 aider-studio: sync`) swept the two new governance docs into its own commit alongside in-flight GH-147 work — content intact, but attribution split; pushed both per operator decision. **GH-142** (agy-reliability) deliberately **held** — its Phase 1 is live-agy S1–S10 characterization, not a headless-able lane.
CHANGELOG.md-438-
CHANGELOG.md-439-### Wave 1 shipped (GH-133) + triage follow-through (#138 closed, #149 filed)
CHANGELOG.md:440:Landed the **GH-133** relay-dep-drift flake fix on `main`: `test/relay-dep-drift.sh` case 4 replaced the SIGPIPE-prone `git log --oneline | grep -q 'RELAY-T'` with a capture + `[[ "$turn_log" == *RELAY-T* ]]` match. Built via `marathon-drive` in an isolated worktree (codex build → agy Approved, gate 12/0), then verified flake-free with 6/6 + 8/8 clean re-runs before applying the 2-line fix directly to `main` (marathon transcript/packet artifacts intentionally **not** merged). **Closed [#133](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/133)**; doc → `3-COMPLETED`. **Closed [#138](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/138)** as STALE — both halves verified live on `main` (`hq promote` at hq.sh:504; marathon-plan glob broadened `MARATHON-PLAN-*.md`→`MARATHON-*.md` at hq-lib.sh:288; `test/hq-promote.sh` 8/0, wired into `validate.sh`); doc → `3-COMPLETED`. Filed **[#149](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/149)** — `marathon-drive --require-clean` self-trips on its own `.relay-driver.lock/` inside a linked worktree (the lock resolves repo-relative because a worktree's `.git` is a file; the clean-check then flags the driver's own mutex). Confirmed **GH-110**'s doc↔issue linkage is correct (filename `SHELLCHECK-VENDOR-FIXES` is a content slug for the "Fable 5 Max audit" issue #110) — no action needed.
CHANGELOG.md-441-
CHANGELOG.md-442-### Inbox marathon-triage sweep + new `marathon-triage` skill
CHANGELOG.md-443-Triaged `PROJECT/1-INBOX` lowest-GH-number-first to build a collision-safe marathon queue, and codified the recurring workflow as a machine-wide Claude skill (`~/.claude/skills/marathon-triage`). Reconciled every `GH-*` capture doc against live issue state: **16 stale docs** for already-CLOSED issues (GH-22/45/56/58/59/64/66/68/69/70/71/75/78/83/84/85) archived to `3-COMPLETED`. **Closed [#61](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/61)** — `swarm-preflight` returns STALE (Tier-1 CI already live on PR #145); doc archived. Promoted the four preflight-ready open issues to `2-WORKING` with `GH-<n>-*.md` names so `swarm-preflight --gh-issue` resolves them: **GH-133** (relay-dep-drift flake → `test/relay-dep-drift.sh`), **GH-142** (agy reliability → `test/agy-turn.sh`+`swarm-preflight.sh`+`_setup.sh`), **GH-143** (front-door → `skills/relay-xyz/SKILL.md`), **GH-144** (PDDA synthesis → `PROJECT/CONSTITUTION.md`+`DO-NOT-BUILD.md`); all four verdict `ready (0)`, disjoint write-sets → one 4-wide parallel wave. Authored preflight contracts for **GH-138** (now preflights STALE — `test/hq-promote.sh` already exists, candidate to close like #61) and **GH-141** (orchestrator-only lane on `relay-turn-lib.sh`; fix direction unratified, honestly flagged). Broadened **GH-94**'s contract write-set (`skills/xyz/SKILL.md` is the real bug site; added `install.sh`+`package.json` for the npx path). Kicked off Wave 1 Lane A (GH-133) via `marathon-drive` in an isolated worktree.
CHANGELOG.md-444-
--
CHANGELOG.md-939-
CHANGELOG.md-940-### GH-49b (#65) — vendor the marathon runtime so a foreign repo can run marathons independently
CHANGELOG.md-941-Follow-on to #49: the GH-49 vendor snapshotted the **relay** set, so a vendored `.xyz/` could run relays but not `marathon-drive`. Extends it so a pinned `.xyz/` is a *full* harness (relays **and** marathons) — the enabler for running e.g. the rebalance-OS marathon decoupled from a live (possibly-dirty) harness clone. Issue [#65](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/65).
CHANGELOG.md-942-- **`xyz-vendor.sh`**: also vendors `relay-automation/{marathon-drive,marathon,marathon-agent,claude-turn}.sh` (marathon-agent dispatches to the claude/codex/agy turn shims, so `claude-turn.sh` — absent from the relay set — comes along). The relay-pkg manifest stays the single source for the relay files; the marathon runtime is an explicit additional list.
CHANGELOG.md:943:- **`marathon-drive.sh` driver-lock**: mirrored the #49 `.git/`-fallback fix — the lock lived at `$ROOT/.git/relay-driver.lock` and a vendored `.xyz/` has no `.git/`, so marathon-drive couldn't acquire it; now falls back to `$ROOT/.relay-driver.lock` (same lock *name* as relay-drive, so a marathon and a relay driver still mutually exclude in one clone). Unchanged when `.git/` exists.
CHANGELOG.md-944-- **Verified**: `test/xyz-vendor.sh` extended (marathon runtime vendored + parses) → **29 assertions**, `validate.sh` **70/70** (marathon-drive 38/38 unchanged). Vendored-marathon smoke: the vendored `marathon-drive --dry-run` (ROOT deriving to `.xyz/`, no `.git/`) acquired its lock, rendered the phase relay file, and seeded the tick token. **Watch item for the first real run**: marathon-drive renders the phase relay thread *inside* `.xyz/phases/` (gitignored) — a real multi-round marathon will exercise the worktree-isolation-vs-gitignored-relay path the dry-run doesn't, and may need a thread-location/isolation tweak (to be surfaced + fixed at run time, as the #49 relay dogfood surfaced its two bugs).
CHANGELOG.md-945-
CHANGELOG.md-946-### GH-49 — portable vendored harness copy (COMPLETE, Phase 0–6: vendor + `.xyz/` locator/staleness + `xyz-sync` + reminder hook + self-hosting dogfood, swarm-produced)
CHANGELOG.md-947-Started the opt-in vendored-mode build so a foreign repo can run relays from a pinned, git-ignored `.xyz/` snapshot instead of coupling to a live (mid-WIP / unavailable) harness clone. Issue [#49](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/49); execution doc [GH-49-VENDORED-LOCAL-COPY.md](PROJECT/2-WORKING/GH-49-VENDORED-LOCAL-COPY.md).
--
CHANGELOG.md-952-- **A real dogfood signal from the swarm build:** codex's produce turn on this delicate file **hit the 480s wall-clock cap and wandered off-lane** (created an unrelated `PROJECT/1-INBOX/SELF-HEALING.md`) — **containment reverted the off-lane file and failed the turn (exit 6)**, exactly as designed; the allowlisted `find-harness.sh` edit survived and was coherent. Rather than trust a killed turn on a containment file, **claude-a independently verified by execution** (GUIDING #12): default no-`.xyz/` path **byte-identical to HEAD on stdout+stderr** for `--root`/`--env`/`--check`; `.xyz/` preferred; `behind`→stderr banner with `--env` exit 0 + pure-export stdout; `XYZ_HARNESS` wins; standalone silent. Then a formal **agy review → Approved** (5/5 DoD Pass) as the swarm-review layer. Relay thread: [gh49-phase23-locator.md](relay-system/2026-06-30/gh49-phase23-locator.md).
CHANGELOG.md-953-- **Phase 4 — `relay-automation/xyz-sync.sh` (registry-backed list/update/delete of vendored copies; also closes the GH-62 `xyz-sync` follow-on).** codex-produced → **agy review → Approved (6/6 DoD Pass)** → **execution-verified**: `list` prints vendored rows (install_dir basename `.xyz`) with `source_commit` + on-disk present/**MISSING**; `update <dir>|--all` re-vendors via `xyz-vendor.sh` (restamped a deliberately-corrupted `VERSION` back to the live HEAD, kept one registry row); `delete <dir>|--all` **dry-runs by default** (prints WOULD REMOVE/PRUNE), and only with `--yes` does it `rm -rf` the `.xyz/` + drop the row (atomic tmp+mv) — verified it removes only the registered `.xyz/` and leaves the repo dir itself intact; a stale/missing `.xyz/` is fail-open (`list`=MISSING, `delete --all --yes` prunes the orphan → 0 rows, `update` skips). bash 3.2-safe, `set -euo pipefail`. Relay thread: [gh49-phase4-xyzsync.md](relay-system/2026-06-30/gh49-phase4-xyzsync.md).
CHANGELOG.md-954-- **Phase 5 — session reminder hook.** `relay-automation/hooks/xyz-vendor-reminder.sh` (print-only, non-blocking, always exit 0, never deletes), wired as a **SessionStart** hook in `.claude/settings.json`. It surfaces a heads-up **only when an on-disk vendored `.xyz/` copy exists** (else fully silent — no context noise), listing the paths + the `xyz-sync.sh list` / `delete <dir> --yes` remedy; opt out with `XYZ_NO_VENDOR_REMINDER=1`. SessionStart (not SessionEnd) because that's the hook channel whose stdout Claude Code injects as visible context — a SessionEnd reminder wouldn't be seen — so "after the session is done" surfaces at the next session start, exactly when a leftover copy is actionable (per the decision record: remind, never auto-delete, operator decides). Authored directly (trivial additive print-only) + execution-verified (silent when none/moved; fires with count+path+remedy when present; opt-out silent; exit 0; settings JSON valid).
CHANGELOG.md-955-- **Phase 6 — tests + the self-hosting dogfood (COMPLETE).** `test/xyz-vendor.sh` (**28 assertions**: vendor completeness, idempotency, `--no-register`, locator default-path-intact + `.xyz/` preference + `XYZ_HARNESS` precedence, staleness current-silent/behind-banner/stdout-pure, `xyz-sync` list/update/delete, reminder hook) wired into `validate.sh` → **70/70**. **Level-2 dogfood (self-hosting proof):** vendored `.xyz/` into a scratch foreign repo and drove a real `relay-xyz` **agy** review turn using *only* the vendored `.xyz/relay-automation/*` + `.xyz/bin/tick` (no live clone referenced, `--target-root` into the foreign repo) — agy caught both planted issues (`rm -rf /`, hardcoded key) as `[Blocker]`s and committed its turn file-scoped in the foreign repo. **The harness self-hosts from its snapshot.**
CHANGELOG.md:956:- **Two containment-kernel gaps the dogfood surfaced + fixed (byte-identical for a normal clone; suite 70/70).** Driving a foreign repo from its *own* nested `.xyz/` (the primary GH-49 usage) exposed two spots that assumed the harness root is a normal clone: (1) **`relay-drive.sh` driver-lock** lived at `$ROOT_DIR/.git/relay-driver.lock` and a vendored `.xyz/` has no `.git/`, so the vendored harness couldn't acquire the lock at all → now falls back to `$ROOT_DIR/.relay-driver.lock` when `.git/` is absent; (2) **`relay-turn-lib.sh` `rtl_init` GH-51 same-repo collapse** rooted `RTL_ROOT` at the caller root `$1`, but a vendored `.xyz/` is a subdir of the foreign repo so `$1` isn't the repo root → the foreign repo's own relay file failed its off-lane match (exit 6); now collapses to the git **toplevel** when `$1` is a subdir, keeping `$1` when it *is* the repo root (GH-51 case unchanged, `relay-target-root.sh` 9/9). Both recorded in [decisions/2026-06-30-vendored-harness-locator.md](decisions/2026-06-30-vendored-harness-locator.md). **GH-49 is complete** — doc moved to `PROJECT/3-COMPLETED/`.
CHANGELOG.md-957-
CHANGELOG.md-958-### GH-62 — XYZ install registry (call-home to remember install locations)
CHANGELOG.md-959-Borrowed PDDA's install→call-home pattern so a future `tick` version can be pushed to the copies that are behind. Filed while preflighting the rebalance-OS Marathon Queue, which surfaced that we keep no record of where `tick` is installed. Issue [#62](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/62); capture [GH-62-XYZ-INSTALL-REGISTRY.md](PROJECT/3-COMPLETED/GH-62-XYZ-INSTALL-REGISTRY.md).
CHANGELOG.md-960-- **New `install.sh`** (repo root): materializes the canonical modular runtime (`bin/tick` + all `src/*.js`) into a target dir, then registers the install in a per-user, machine-local `~/.config/xyz/registry.tsv` (override `XYZ_REGISTRY`; opt out `--no-register`). Key = `install_dir` (dedup, latest wins); columns `last_install_utc · tick_version · source_commit · coordinated_repo`. `--repo <path>` (or `$TICK_REPO_ROOT`) records the coordinated repo. Best-effort git-pulse projection for multi-device rollup (path-normalized; fail-open). Never committed — lives in `$HOME`.
--
CHANGELOG.md-1059-### GH-46 / GH-33 Phase 4 SHIPPED via marathon — #14 fix confirmed end-to-end
CHANGELOG.md-1060-The payoff of the #14 fix: the **3rd** GH-46 Phase-4 marathon dogfood (codex builder, agy reviewer) **succeeded** where the prior two failed at the codex self-commit reset.
CHANGELOG.md-1061-- **Phase 4 landed:** `relay-loop.sh --background` now dispatches the **cross-model shim** on `DECISION: nudge-cross-model` via a `--cross-model-cmd` flag (reusing the Phase-3 `bg_launch` + pidfile single-turn lock), and degrades to the human nudge when no command/CLI is available. Built by codex in the marathon, agy-approved; `test/relay-loop.sh` 11 → 15 (4 cross-model cases).
CHANGELOG.md-1062-- **#14 confirmed:** codex `committed codex turn (file-scoped, no push)` with no reset+exit-6 — the exact failure mode of the prior 2 runs is gone. The marathon builder lane is unblocked.
CHANGELOG.md:1063:- **driver-lock.sh test made hermetic:** the marathon's pre-advance gate failed only because `test/driver-lock.sh` inherited `RELAY_DRIVER_LOCKED=1` from the parent marathon and skipped the lock logic (the seeded lock "leaked"). Fixed by `unset RELAY_DRIVER_LOCKED` in the test — a clean dogfood catch (the gate caught a non-hermetic test). `validate.sh` 56/56.
CHANGELOG.md-1064-- **Bet outcome:** the 2026-06-29 `RTL_WT_USED`-persistence diagnosis is validated end-to-end (graduate). Phase 4 was built **by the harness itself** — the first cross-model marathon to land containment-adjacent work post-fix.
CHANGELOG.md-1065-
CHANGELOG.md-1066-### #14 / #13 root-cause + GH-42 stale-lock self-heal — unblock the marathon builder lane
CHANGELOG.md-1067-The two harness bugs that made the XYZ marathon unusable on 2026-06-29 (the codex Phase-4 dogfood failed 2×).
CHANGELOG.md-1068-- **#14 / #13 (the real fix):** the GH-13 "a moved ROOT HEAD during a worktree turn is a concurrent peer commit — preserve it, don't reset" branch in `rtl_enforce` was **dead code for the real shims**. `rtl_worktree_begin` runs in a `wt="$(…)"` subshell, so the `RTL_WT_USED=1` it set never reached `rtl_enforce` — every codex/agy worktree turn whose ROOT HEAD moved hit the in-ROOT `reset --hard` + exit-6 path and **discarded the build**. The earlier `relay-concurrent-commit.sh` (7/7) hid this by driving the lib in-shell, never through a shim subshell. **Fix:** re-assert `RTL_WT_USED=1` in `rtl_worktree_end` (caller's shell, always before `rtl_enforce`). One line; in-ROOT/attended path byte-for-byte unchanged. [relay-automation/relay-turn-lib.sh](relay-automation/relay-turn-lib.sh).
CHANGELOG.md-1069-- **GH-42 stale-lock self-heal:** `marathon-drive.sh` / `relay-drive.sh` now record the holder PID in `.git/relay-driver.lock` and **reclaim a stale lock when its holder is dead** (`kill -0`), instead of a crashed/killed driver leaving a lock that blocks every later run until a manual `rmdir` (hit between the two marathon runs). Live holder → still refuses (the real concurrency guard). `ponytail:` small TOCTOU window noted, acceptable for a single-operator clone.
CHANGELOG.md:1070:- **Tests:** new shim-level regression `test/worktree-isolation.sh` test 4 (concurrent ROOT commit mid worktree-turn → exit 0, peer preserved, allowlist copied back) → 15/15; new `test/driver-lock.sh` (stale-reclaim + live-refuse) 4/4. **`validate.sh` 56/56.**
CHANGELOG.md-1071-- **Bet:** the `RTL_WT_USED` fix is the diagnosed cause of the codex marathon failures; reversibility Easy (one line). Next signal: re-fire the GH-46 Phase-4 marathon and confirm the codex builder lane no longer resets+fails — high-confidence diagnosis, not yet end-to-end-proven.
CHANGELOG.md-1072-
CHANGELOG.md-1073-## 2026-06-28
CHANGELOG.md-1074-
--
utils/hq/marathon-live.sh-8-#   - live claim     : each repo's OWN `tick project` regenerates its `.tick/STATE.md` from its event
utils/hq/marathon-live.sh-9-#                      log; the `## Claimed` section names the task id + claimant currently holding work
utils/hq/marathon-live.sh-10-#                      (the live signal the doc-status scanner marathon-scan.sh cannot see).
utils/hq/marathon-live.sh-11-#   - is-it-really-driving : cross-checked against the driver lock file (resolved by the SAME shared
utils/hq/marathon-live.sh:12:#                      resolver the driver itself writes through — relay-automation/driver-lock-lib.sh,
utils/hq/marathon-live.sh:13:#                      GH-448 — so a linked worktree's lock in the git common dir is found, not missed)
utils/hq/marathon-live.sh-14-#                      and any `marathon/*`-branch worktree with a commit inside the activity window —
utils/hq/marathon-live.sh-15-#                      a claim without either is "claimed, not driving".
utils/hq/marathon-live.sh-16-#
utils/hq/marathon-live.sh-17-# Emits one compact Markdown table: repo | marathon/lane | task | claimant | live | last activity.
--
utils/hq/marathon-live.sh-35-HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
utils/hq/marathon-live.sh-36-ROOT="$(cd "$HERE/../.." && pwd)"
utils/hq/marathon-live.sh-37-# shellcheck source=utils/hq/hq-lib.sh
utils/hq/marathon-live.sh-38-. "$HERE/hq-lib.sh"
utils/hq/marathon-live.sh:39:# shellcheck source=relay-automation/driver-lock-lib.sh
utils/hq/marathon-live.sh:40:. "$ROOT/relay-automation/driver-lock-lib.sh"
utils/hq/marathon-live.sh-41-
utils/hq/marathon-live.sh-42-TODAY="${HQ_MARATHON_LIVE_TODAY:-"$(date -u +%Y-%m-%d)"}"
utils/hq/marathon-live.sh-43-NOW="${HQ_MARATHON_LIVE_NOW:-"$(date -u +%Y-%m-%dT%H:%M:%SZ)"}"
utils/hq/marathon-live.sh-44-NOW_EPOCH="${HQ_MARATHON_LIVE_NOW_EPOCH:-"$(date +%s)"}"
--
utils/hq/marathon-live.sh-91-  task="${task%-TURN}"
utils/hq/marathon-live.sh-92-  printf '%s' "$task"
utils/hq/marathon-live.sh-93-}
utils/hq/marathon-live.sh-94-
utils/hq/marathon-live.sh:95:# Is the driver lock present for this repo? Prints the lock path or nothing. GH-448: resolved via the
utils/hq/marathon-live.sh:96:# shared resolver (relay-automation/driver-lock-lib.sh) — the SAME path the driver itself writes,
utils/hq/marathon-live.sh-97-# including the linked-worktree case (.git is a FILE -> the git common dir, not <repo>/.git/…) and the
utils/hq/marathon-live.sh-98-# vendored case (no .git -> <repo>/.relay-driver.lock, NOT <repo>/.xyz/.relay-driver.lock — the driver
utils/hq/marathon-live.sh-99-# never writes inside .xyz/, so the old .xyz/-scoped check here could never have matched a real lock).
utils/hq/marathon-live.sh-100-driver_lock_path() {
--
utils/hq/marathon-live.sh-150-  if [[ -n "$wt_epoch" ]] && (( NOW_EPOCH - wt_epoch <= window_secs )); then recent_wt=1; fi
utils/hq/marathon-live.sh-151-  is_driving=0
utils/hq/marathon-live.sh-152-  [[ -n "$lock_path" || "$recent_wt" == 1 ]] && is_driving=1
utils/hq/marathon-live.sh-153-
utils/hq/marathon-live.sh:154:  # Last-activity display: newest marathon worktree commit, else the driver-lock mtime, else em dash.
utils/hq/marathon-live.sh-155-  last_activity="—"
utils/hq/marathon-live.sh-156-  if [[ -n "$wt_epoch" ]]; then
utils/hq/marathon-live.sh-157-    last_activity="$(date -u -r "$wt_epoch" +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u -d "@$wt_epoch" +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || printf 'epoch:%s' "$wt_epoch")"
utils/hq/marathon-live.sh-158-  elif [[ -n "$lock_path" ]]; then
--
PROJECT/2-WORKING/MARATHON-PLAN-2026-07-17-H-LIVE-MARATHON-STATUS.md-34-
PROJECT/2-WORKING/MARATHON-PLAN-2026-07-17-H-LIVE-MARATHON-STATUS.md-35-## Why this shape, why now
PROJECT/2-WORKING/MARATHON-PLAN-2026-07-17-H-LIVE-MARATHON-STATUS.md-36-
PROJECT/2-WORKING/MARATHON-PLAN-2026-07-17-H-LIVE-MARATHON-STATUS.md-37-The operator asked mid-session whether marathons running on the machine could be read in realtime.
PROJECT/2-WORKING/MARATHON-PLAN-2026-07-17-H-LIVE-MARATHON-STATUS.md:38:Answering required 4 manual, ad-hoc checks (`ps aux`, `git worktree list`, a driver-lock peek,
PROJECT/2-WORKING/MARATHON-PLAN-2026-07-17-H-LIVE-MARATHON-STATUS.md-39-`marathon-scan.sh`'s doc-status scan) — and even then the doc-status scan couldn't see an actively
PROJECT/2-WORKING/MARATHON-PLAN-2026-07-17-H-LIVE-MARATHON-STATUS.md-40-running marathon in sibling worktrees, since it only reads `MARATHON-PLAN-*.md` frontmatter, not
PROJECT/2-WORKING/MARATHON-PLAN-2026-07-17-H-LIVE-MARATHON-STATUS.md-41-live process/tick state. This plan closes that gap with the smallest addition that composes with
PROJECT/2-WORKING/MARATHON-PLAN-2026-07-17-H-LIVE-MARATHON-STATUS.md-42-what already exists, per `/ponytail`: `tick project` already derives exactly the live state needed
--
utils/py/gate_env.py-42-SET, a nested driver correctly skips a lock its parent holds, but suites asserting real
utils/py/gate_env.py-43-lock-acquisition measure the parent. UNSET, those assertions become honest and every nested driver
utils/py/gate_env.py-44-collides with the held lock instead. The fix for that is per-suite and already shipped (GH-441
utils/py/gate_env.py-45-Phase 1): the two suites that were ever wrong clear the flag for THEMSELVES, because each drives
utils/py/gate_env.py:46:against its own throwaway repo. See `test/driver-lock.sh:11`, which used that idiom first.
utils/py/gate_env.py-47-
utils/py/gate_env.py-48-The lesson encoded here: a global answer to a per-suite question is what produced the reverted commit.
utils/py/gate_env.py-49-"""
utils/py/gate_env.py-50-
--
utils/py/gate_env.py-104-        "MUST NOT BE SCRUBBED — see this module's docstring. Scrubbing it globally was landed and "
utils/py/gate_env.py-105-        "REVERTED (2026-08-07): ~40 gate suites spawn nested drivers that need it SET to skip a lock "
utils/py/gate_env.py-106-        "their parent holds, and unsetting it breaks them (gh322 17/3, gh268 31/3). The two suites "
utils/py/gate_env.py-107-        "that need it clear for THEMSELVES clear it themselves — GH-441 Phase 1, the idiom from "
utils/py/gate_env.py:108:        "test/driver-lock.sh:11. A per-suite question has no global answer.",
utils/py/gate_env.py-109-    ),
utils/py/gate_env.py-110-    "TICK_REPO_ROOT": (
utils/py/gate_env.py-111-        PASS,
utils/py/gate_env.py-112-        "Pins which clone's event log tick writes to. The gate genuinely needs this: a bare or "
--
relay-automation/relay-turn-lib.sh-624-  wt_root="${TMPDIR:-/tmp}"
relay-automation/relay-turn-lib.sh-625-  _root_abs="$(cd "$RTL_ROOT" 2>/dev/null && pwd -P)"
relay-automation/relay-turn-lib.sh-626-  _tmp_abs="$(cd "$wt_root" 2>/dev/null && pwd -P)"
relay-automation/relay-turn-lib.sh-627-  if [[ -n "$_root_abs" && -n "$_tmp_abs" && ( "$_tmp_abs" == "$_root_abs" || "$_tmp_abs" == "$_root_abs"/* ) ]]; then
relay-automation/relay-turn-lib.sh:628:    _gcd="$(git -C "$RTL_ROOT" rev-parse --git-common-dir 2>/dev/null)"
relay-automation/relay-turn-lib.sh-629-    [[ -n "$_gcd" && "$_gcd" != /* ]] && _gcd="$RTL_ROOT/$_gcd"
relay-automation/relay-turn-lib.sh-630-    if [[ -n "$_gcd" ]] && mkdir -p "$_gcd/rtl-worktrees" 2>/dev/null; then
relay-automation/relay-turn-lib.sh-631-      wt_root="$_gcd/rtl-worktrees"
relay-automation/relay-turn-lib.sh-632-      rtl_trace "rtl_worktree_begin: RELOCATED worktree root off \$TMPDIR (inside RTL_ROOT) -> $wt_root (GH-236)"
--
PROJECT/3-COMPLETED/GH-49-VENDORED-LOCAL-COPY.md-30-## Status
PROJECT/3-COMPLETED/GH-49-VENDORED-LOCAL-COPY.md-31-
PROJECT/3-COMPLETED/GH-49-VENDORED-LOCAL-COPY.md-32-| What was just completed | What's next |
PROJECT/3-COMPLETED/GH-49-VENDORED-LOCAL-COPY.md-33-|---|---|
PROJECT/3-COMPLETED/GH-49-VENDORED-LOCAL-COPY.md:34:| **Phase 6 — tests + the self-hosting dogfood. ALL 6 PHASES DONE.** `test/xyz-vendor.sh` (28 assertions) wired into `validate.sh` (**70/70**). **Level-2 dogfood succeeded**: the vendored `.xyz/` harness (relay-drive + agy-turn + relay-turn-lib + bin/tick, *no live clone*) drove **agy** to review a foreign-repo artifact, catch both planted issues (`rm -rf /`, hardcoded key) as `[Blocker]`s, and commit its turn file-scoped in the foreign repo — **the harness self-hosts from its snapshot.** The dogfood also surfaced + **fixed 2 containment-kernel gaps** (driver-lock assumed `.git/`; GH-51 collapse rooted at the `.xyz/` subdir not the toplevel) — byte-identical for a normal clone, `relay-target-root.sh` 9/9. | **Complete** — move to `3-COMPLETED`, close #49. |
PROJECT/3-COMPLETED/GH-49-VENDORED-LOCAL-COPY.md-35-
PROJECT/3-COMPLETED/GH-49-VENDORED-LOCAL-COPY.md-36-## Table of Contents
PROJECT/3-COMPLETED/GH-49-VENDORED-LOCAL-COPY.md-37-
PROJECT/3-COMPLETED/GH-49-VENDORED-LOCAL-COPY.md-38-- [Status](#status)
--
utils/py/rtl.py-656-        return 0, None
utils/py/rtl.py-657-    return count, first
utils/py/rtl.py-658-
utils/py/rtl.py-659-def driver_lock_path(root):
utils/py/rtl.py:660:    # GH-448: the ONE shared resolver for the relay-driver lock path, matching the DRIVER's own
utils/py/rtl.py-661-    # write-side resolution (marathon_drive.py / marathon-drive.sh, relay_drive.py / relay-drive.sh) —
utils/py/rtl.py-662-    # every read-only consumer (marathon-ls.sh, marathon-live.sh, find-harness.sh) must resolve the
utils/py/rtl.py-663-    # SAME path or it probes a location the driver never writes and reports a live run as idle.
utils/py/rtl.py-664-    #   .git is a directory  -> <root>/.git/relay-driver.lock                (normal clone)
utils/py/rtl.py:665:    #   .git is a file       -> <git-common-dir>/relay-driver.lock           (linked worktree)
utils/py/rtl.py-666-    #   no .git (vendored)   -> <root>/.relay-driver.lock                    (vendored .xyz/ copy)
utils/py/rtl.py-667-    # Returns (lock_path, lock_label) — lock_label is always the SHORT display form used in messages.
utils/py/rtl.py-668-    git_path = os.path.join(root, ".git")
utils/py/rtl.py-669-    if os.path.isdir(git_path):
--
utils/py/rtl.py-671-    if os.path.isfile(git_path):
utils/py/rtl.py-672-        common = ""
utils/py/rtl.py-673-        try:
utils/py/rtl.py-674-            common = subprocess.check_output(
utils/py/rtl.py:675:                ["git", "-C", root, "rev-parse", "--path-format=absolute", "--git-common-dir"],
utils/py/rtl.py-676-                stderr=subprocess.DEVNULL).decode("utf-8").strip()
utils/py/rtl.py-677-        except Exception:
utils/py/rtl.py-678-            common = ""
utils/py/rtl.py-679-        if common:
--
PROJECT/2-WORKING/MARATHON-PLAN-2026-08-05.md-92-- #281 GH-281 · Sentinel / Debug Flywheel — opt-in debug capture (public) + private triage overlay — `already-closed`
PROJECT/2-WORKING/MARATHON-PLAN-2026-08-05.md-93-- #279 GH-279 · aider-qwen marathon trial — consolidated run issues — `already-closed`
PROJECT/2-WORKING/MARATHON-PLAN-2026-08-05.md-94-- #274 GH-274 · marathon-drive: re-invoking a phase whose tick token is already done clobbers RELAY.md's Approved record instead of detecting a satisfied lane — `already-closed`
PROJECT/2-WORKING/MARATHON-PLAN-2026-08-05.md-95-- #294 GH-294 · swarm-preflight: isolation flag not carried into the suggested marathon command — `already-closed`
PROJECT/2-WORKING/MARATHON-PLAN-2026-08-05.md:96:- #292 GH-292 · A linked worktree cannot discover the main checkout's vendored .xyz harness — `already-closed`
PROJECT/2-WORKING/MARATHON-PLAN-2026-08-05.md-97-- #268 GH-268 · Beta onboarding & build-quality test report — remediation plan (re: #123) — `already-closed`
PROJECT/2-WORKING/MARATHON-PLAN-2026-08-05.md-98-- #261 GH-261 · marathon-drive: reconcile the Bash/Python disjoint-failure union (last Phase-1 gate for the XYZ_PYTHON flip) — `already-closed`
PROJECT/2-WORKING/MARATHON-PLAN-2026-08-05.md-99-- #266 GH-266 · rtl_worktree_end doesn't exempt relay-system/ (its own transcript dir) — false containment violation discards a fully in-scope turn — `already-closed`
PROJECT/2-WORKING/MARATHON-PLAN-2026-08-05.md-100-- #263 GH-263 · codex-turn.sh isolation=0 path can't reach the parent-root .tick lock in vendored installs — `already-closed`
--
PROJECT/2-WORKING/MARATHON-PLAN-2026-08-05.md-207-- #416 GH-416 · a dependency sync silently deleted three working guardrails, and CI stayed red on development for two days because the failures read as noise — `gated` (would score 107)
PROJECT/2-WORKING/MARATHON-PLAN-2026-08-05.md-208-
PROJECT/2-WORKING/MARATHON-PLAN-2026-08-05.md-209-### ⚠️ Not yet sequenceable — rate / add doc / add contract
PROJECT/2-WORKING/MARATHON-PLAN-2026-08-05.md-210-- #381 GH-381 · /Releases rolling release-train planner — `needs-contract`
PROJECT/2-WORKING/MARATHON-PLAN-2026-08-05.md:211:- #354 GH-354 · concurrent swarms: the driver lock blocks 1 of 3 pairs, and the monitors can't see the one it does — `needs-contract`
PROJECT/2-WORKING/MARATHON-PLAN-2026-08-05.md-212-- #347 GH-347 · pi CLI installed inside another app's folder, invisible to PATH — `needs-contract`
PROJECT/2-WORKING/MARATHON-PLAN-2026-08-05.md-213-- #336 GH-336 · planning context: phase metadata signals before deterministic marathon contracts — `needs-contract`
PROJECT/2-WORKING/MARATHON-PLAN-2026-08-05.md-214-- #305 GH-305 — 4-agent swarm validation test — `needs-contract`
PROJECT/2-WORKING/MARATHON-PLAN-2026-08-05.md-215-- #280 GH-280 · Investigate Aider+Qwen3.8-Max reliability vs Aider+Claude-Sonnet-5 control ($5 OpenRouter budget) — `needs-contract`
--
utils/py/relay_drive.py-7-import shutil
utils/py/relay_drive.py-8-import pathlib
utils/py/relay_drive.py-9-from contextlib import contextmanager
utils/py/relay_drive.py-10-
utils/py/relay_drive.py:11:# GH-376: resolve the driver lock through the ONE shared resolver rather than reimplementing it.
utils/py/relay_drive.py-12-# Imported relative to this file (utils/py/), independent of CWD/PYTHONPATH — some callers load this
utils/py/relay_drive.py-13-# module via importlib.util.spec_from_file_location rather than `python3 <path>`, which does NOT put
utils/py/relay_drive.py-14-# the script's own directory on sys.path. Same pattern, and the same reason, as marathon_drive.py:19.
utils/py/relay_drive.py-15-sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
--
utils/py/relay_drive.py-389-        desc = f"Relay session ended: STATUS {s or 'unknown'} (health {health})."
utils/py/relay_drive.py-390-        subprocess.run([xyz_append_bin, "relay", slug, health, title, desc], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
utils/py/relay_drive.py-391-
utils/py/relay_drive.py-392-    if get_env("RELAY_DRIVER_LOCKED", "0") != "1":
utils/py/relay_drive.py:393:        # GH-376: this was a 2-branch guess (.git is a dir -> .git/relay-driver.lock, ELSE a hidden
utils/py/relay_drive.py:394:        # lock beside the scripts) with no case for a linked worktree, where .git is a FILE. That
utils/py/relay_drive.py-395-        # topology is not exotic — it is the one swarm-preflight's own recommended invocation creates
utils/py/relay_drive.py-396-        # via RELAY_WORKTREE_ISOLATION=1. The marathon driver already followed .git to the git COMMON
utils/py/relay_drive.py-397-        # dir, so the two drivers resolved DIFFERENT paths from the same tree and each held what it
utils/py/relay_drive.py-398-        # believed was the one mutex, invisible to the other. marathon-drive.sh:195-196 asserts in
utils/py/relay_drive.py-399-        # prose that they mutually exclude; this call is what makes that true.
utils/py/relay_drive.py-400-        #
utils/py/relay_drive.py:401:        # driver_lock_path is #448's shared resolver (Bash twin: relay-automation/driver-lock-lib.sh).
utils/py/relay_drive.py-402-        # Reused, never reimplemented — a fourth inline copy is the bug class, not the fix.
utils/py/relay_drive.py-403-        lock_dir, lock_label = driver_lock_path(root_dir)
utils/py/relay_drive.py-404-
utils/py/relay_drive.py-405-
--
relay-automation/relay-drive.sh-144-  # .xyz/ copy has no .git/, so mkdir'ing a lock there would fail — fall back to a hidden lock beside
relay-automation/relay-drive.sh-145-  # the scripts (the .xyz/ dir is itself gitignored in the foreign repo, so it stays uncommitted just
relay-automation/relay-drive.sh-146-  # the same). When .git/ exists the path is unchanged, so a normal clone behaves byte-identically.
relay-automation/relay-drive.sh-147-  #
relay-automation/relay-drive.sh:148:  # GH-376: the inline 2-branch guess that used to live here had NO case for a linked worktree, where
relay-automation/relay-drive.sh-149-  # .git is a FILE pointing at the shared gitdir — so this driver locked inside the worktree while
relay-automation/relay-drive.sh-150-  # marathon-drive locked in the git COMMON dir, and the mutual exclusion asserted at
relay-automation/relay-drive.sh:151:  # marathon-drive.sh:195-196 silently did not exist. Resolution now goes through GH-448's shared
relay-automation/relay-drive.sh:152:  # driver-lock-lib.sh (Python twin: utils/py/rtl.py::driver_lock_path), so the two drivers agree by
relay-automation/relay-drive.sh-153-  # construction instead of by coincidence.
relay-automation/relay-drive.sh:154:  source "$(dirname "${BASH_SOURCE[0]}")/driver-lock-lib.sh"
relay-automation/relay-drive.sh-155-  _lock="$(driver_lock_path_for_repo "$ROOT_DIR")"
relay-automation/relay-drive.sh-156-  # The label is the SHORT display form used in the messages below, derived from the resolved path
relay-automation/relay-drive.sh-157-  # rather than recomputed: the vendored fallback is the ONLY branch that yields <root>/.relay-driver.lock,
relay-automation/relay-drive.sh-158-  # so this reproduces rtl.py's label mapping exactly without re-testing .git a second time.
--
relay-automation/marathon-drive.sh-187-}
relay-automation/marathon-drive.sh-188-
relay-automation/marathon-drive.sh-189-if [[ "${RELAY_DRIVER_LOCKED:-0}" != "1" ]]; then
relay-automation/marathon-drive.sh-190-  # GH-49b: the lock lives in .git/ (never committed) for a normal clone; a vendored .xyz/ copy has no
relay-automation/marathon-drive.sh:191:  # .git/. In a linked worktree, .git is a file pointing at the shared gitdir, so resolve the real
relay-automation/marathon-drive.sh-192-  # common dir and place the lock there; otherwise --require-clean sees the driver's own bookkeeping as
relay-automation/marathon-drive.sh-193-  # untracked dirt inside the worktree. A vendored .xyz/ copy still falls back to a hidden lock beside
relay-automation/marathon-drive.sh-194-  # the scripts (the .xyz/ dir is itself gitignored in the foreign repo, so it stays uncommitted just
relay-automation/marathon-drive.sh-195-  # the same). Same lock NAME as relay-drive so a marathon and a relay driver still mutually exclude in
relay-automation/marathon-drive.sh-196-  # one clone.
relay-automation/marathon-drive.sh-197-  if [[ -d "$ROOT/.git" ]]; then
relay-automation/marathon-drive.sh-198-    _lock="$ROOT/.git/relay-driver.lock"; _lock_label=".git/relay-driver.lock"
relay-automation/marathon-drive.sh-199-  elif [[ -f "$ROOT/.git" ]]; then
relay-automation/marathon-drive.sh:200:    _git_common_dir="$(git -C "$ROOT" rev-parse --git-common-dir 2>/dev/null || true)"
relay-automation/marathon-drive.sh-201-    if [[ -n "$_git_common_dir" ]]; then
relay-automation/marathon-drive.sh-202-      _lock="$_git_common_dir/relay-driver.lock"; _lock_label=".git/relay-driver.lock"
relay-automation/marathon-drive.sh-203-    else
relay-automation/marathon-drive.sh-204-      _lock="$ROOT/.relay-driver.lock";           _lock_label=".relay-driver.lock"
--
relay-automation/marathon-drive.sh-748-}
relay-automation/marathon-drive.sh-749-# GH-238: a --dry-run renders the relay file and prints the tick seed, then exits — it never
relay-automation/marathon-drive.sh-750-# dispatches a builder or reviewer turn, so there is no wasted-turn cost to protect against and
relay-automation/marathon-drive.sh-751-# halting would be pure downside. It also breaks fixtures that drive unrelated paths in repos with
relay-automation/marathon-drive.sh:752:# no gate script (test/driver-lock.sh regressed exactly this way when the check halted every run).
relay-automation/marathon-drive.sh-753-# Still surface the problem, so --dry-run stays a useful plan sanity-check: the subshell contains
relay-automation/marathon-drive.sh-754-# pre_advance_not_runnable's die(), turning the halt into a warning on this path only.
relay-automation/marathon-drive.sh-755-if ((DRY_RUN)); then
relay-automation/marathon-drive.sh-756-  ( preflight_pre_advance_gate ) \
--
utils/py/marathon_drive.py-13-import datetime as _dt
utils/py/marathon_drive.py-14-
utils/py/marathon_drive.py-15-# Import rtl relative to this file (utils/py/), independent of CWD/PYTHONPATH — needed because some
utils/py/marathon_drive.py-16-# callers load this module via importlib.util.spec_from_file_location rather than `python3 <path>`,
utils/py/marathon_drive.py:17:# which does NOT put the script's own directory on sys.path (GH-448 regression, test/gh322-runlog-
utils/py/marathon_drive.py-18-# python-lane.sh caught it). Same pattern as marathon_plan.py's `_marathon_plan` import.
utils/py/marathon_drive.py-19-sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
utils/py/marathon_drive.py-20-from rtl import driver_lock_path  # noqa: E402
utils/py/marathon_drive.py-21-
--
utils/py/marathon_drive.py-681-        # GH-49b/GH-207: the lock lives in .git/ (never committed) for a normal clone. In a linked
utils/py/marathon_drive.py-682-        # worktree .git is a FILE pointing at the shared gitdir, so resolve the real common dir and put
utils/py/marathon_drive.py-683-        # the lock there — otherwise --require-clean sees the driver's own lock as untracked dirt inside
utils/py/marathon_drive.py-684-        # the worktree. A vendored .xyz/ copy (no .git) falls back to a hidden lock beside the scripts.
utils/py/marathon_drive.py:685:        # GH-448: this resolution is the canonical write-side one — every read-only consumer (marathon-
utils/py/marathon_drive.py-686-        # ls.sh, marathon-live.sh, find-harness.sh) must agree with it, so it lives in rtl.py's shared
utils/py/marathon_drive.py:687:        # driver_lock_path (with a byte-for-byte Bash twin in relay-automation/driver-lock-lib.sh)
utils/py/marathon_drive.py-688-        # rather than being reimplemented here.
utils/py/marathon_drive.py-689-        lock_dir, lock_label = driver_lock_path(root)
utils/py/marathon_drive.py-690-
utils/py/marathon_drive.py-691-        try:
--
relay-automation/marathon-ls.sh-31-done
relay-automation/marathon-ls.sh-32-SELF_DIR="$(cd -P "$(dirname "$_src")" >/dev/null 2>&1 && pwd)"
relay-automation/marathon-ls.sh-33-HUB_REPO="$(cd "$SELF_DIR/.." && pwd)"
relay-automation/marathon-ls.sh-34-
relay-automation/marathon-ls.sh:35:# shellcheck source=relay-automation/driver-lock-lib.sh
relay-automation/marathon-ls.sh:36:. "$SELF_DIR/driver-lock-lib.sh"
relay-automation/marathon-ls.sh-37-
relay-automation/marathon-ls.sh-38-# ---------------------------------------------------------------------------
relay-automation/marathon-ls.sh-39-# helpers
relay-automation/marathon-ls.sh-40-# ---------------------------------------------------------------------------
relay-automation/marathon-ls.sh-41-
relay-automation/marathon-ls.sh-42-trim_cr() { printf '%s' "${1%$'\r'}"; }
relay-automation/marathon-ls.sh-43-
relay-automation/marathon-ls.sh-44-# Resolve the relay-driver lock path for a given repo root — delegates to the shared resolver
relay-automation/marathon-ls.sh:45:# (GH-448: this used to guess 2 branches inline and missed the linked-worktree case, where .git is a
relay-automation/marathon-ls.sh-46-# FILE and the driver's real lock lives at the git common dir, not <repo>/.git/relay-driver.lock).
relay-automation/marathon-ls.sh-47-lock_path_for_repo() {
relay-automation/marathon-ls.sh-48-  driver_lock_path_for_repo "$1"
relay-automation/marathon-ls.sh-49-}
--
relay-automation/durable-log-lib.sh-4-# The registry itself is NOT in this file. It is `relay-automation/non-durable-log-roots.conf`, read
relay-automation/durable-log-lib.sh-5-# at runtime, and `utils/py/rtl.py::path_is_durable` reads the SAME file — so the two lanes cannot
relay-automation/durable-log-lib.sh-6-# disagree, and there is no second list to go stale. `test/gh388-run-log-durability.sh` asserts both
relay-automation/durable-log-lib.sh-7-# readers return the same verdict for the same paths, which is the only thing that keeps that claim
relay-automation/durable-log-lib.sh:8:# true. Same shape as driver-lock-lib.sh (GH-448), for the same reason: a consumer that inlines its
relay-automation/durable-log-lib.sh-9-# own version of this decision is the defect the shared file exists to kill.
relay-automation/durable-log-lib.sh-10-#
relay-automation/durable-log-lib.sh-11-# API:
relay-automation/durable-log-lib.sh-12-#   xyz_non_durable_conf                — prints the path to the registry file
--
relay-automation/driver-lock-lib.sh-1-#!/usr/bin/env bash
relay-automation/driver-lock-lib.sh:2:# driver-lock-lib.sh — GH-448: the ONE shared resolver for the relay-driver lock path.
relay-automation/driver-lock-lib.sh-3-#
relay-automation/driver-lock-lib.sh-4-# Mirrors the DRIVER's own write-side resolution (marathon_drive.py / marathon-drive.sh,
relay-automation/driver-lock-lib.sh-5-# relay_drive.py / relay-drive.sh) byte-for-byte (utils/py/rtl.py's driver_lock_path is the Python
relay-automation/driver-lock-lib.sh:6:# twin — the two MUST agree, asserted by test/gh448-driver-lock-resolver.sh). SOURCED by every
relay-automation/driver-lock-lib.sh-7-# read-only consumer of the lock (marathon-ls.sh, utils/hq/marathon-live.sh,
relay-automation/driver-lock-lib.sh-8-# skills/relay-xyz/find-harness.sh) — a consumer that constructs this path inline instead of calling
relay-automation/driver-lock-lib.sh-9-# this function is the bug this file exists to kill (5 of 7 construction sites had drifted to a
relay-automation/driver-lock-lib.sh-10-# 2-branch guess that misses the linked-worktree case, silently reporting a LIVE marathon as IDLE).
relay-automation/driver-lock-lib.sh-11-#
relay-automation/driver-lock-lib.sh-12-#   .git is a directory  -> <repo>/.git/relay-driver.lock              (normal clone)
relay-automation/driver-lock-lib.sh:13:#   .git is a file       -> <git-common-dir>/relay-driver.lock         (linked worktree)
relay-automation/driver-lock-lib.sh-14-#   no .git (vendored)   -> <repo>/.relay-driver.lock                  (vendored .xyz/ copy)
relay-automation/driver-lock-lib.sh-15-#
relay-automation/driver-lock-lib.sh-16-# API:
relay-automation/driver-lock-lib.sh-17-#   driver_lock_path_for_repo <repo-root>   — prints the resolved lock path (no trailing newline)
--
relay-automation/driver-lock-lib.sh-24-    return 0
relay-automation/driver-lock-lib.sh-25-  fi
relay-automation/driver-lock-lib.sh-26-  if [ -f "$repo/.git" ]; then
relay-automation/driver-lock-lib.sh-27-    local common
relay-automation/driver-lock-lib.sh:28:    common="$(git -C "$repo" rev-parse --path-format=absolute --git-common-dir 2>/dev/null || true)"
relay-automation/driver-lock-lib.sh-29-    if [ -n "$common" ]; then
relay-automation/driver-lock-lib.sh-30-      printf '%s/relay-driver.lock' "$common"
relay-automation/driver-lock-lib.sh-31-      return 0
relay-automation/driver-lock-lib.sh-32-    fi
--
relay-automation/marathon-recover.sh-33-  case "$_src" in /*) ;; *) _src="$_dir/$_src" ;; esac
relay-automation/marathon-recover.sh-34-done
relay-automation/marathon-recover.sh-35-SELF_DIR="$(cd -P "$(dirname "$_src")" >/dev/null 2>&1 && pwd)"
relay-automation/marathon-recover.sh-36-
relay-automation/marathon-recover.sh:37:# shellcheck source=relay-automation/driver-lock-lib.sh
relay-automation/marathon-recover.sh:38:. "$SELF_DIR/driver-lock-lib.sh"
relay-automation/marathon-recover.sh-39-
relay-automation/marathon-recover.sh-40-status_for_relay() {
relay-automation/marathon-recover.sh-41-  local relay="$1" status
relay-automation/marathon-recover.sh-42-  status="$(sed -n 's/^STATUS:[[:space:]]*//p' "$relay" | head -1)"
--
test/gh284-runlog-heartbeat.sh-1-#!/usr/bin/env bash
test/gh284-runlog-heartbeat.sh-2-# GH-284 Phase 2: file-based driver liveness and opt-in, non-fatal GitHub run-log.
test/gh284-runlog-heartbeat.sh-3-source "$(dirname "$0")/_setup.sh" gh284-runlog-heartbeat
test/gh284-runlog-heartbeat.sh-4-
test/gh284-runlog-heartbeat.sh:5:# GH-441 — hermetic against an ambient driver, same reason as test/driver-lock.sh:11. This suite
test/gh284-runlog-heartbeat.sh-6-# drives marathon-drive against its own throwaway repo ($A) and asserts on what THAT driver does.
test/gh284-runlog-heartbeat.sh-7-# When validate.sh runs as a live marathon's --pre-advance-cmd it inherits RELAY_DRIVER_LOCKED=1
test/gh284-runlog-heartbeat.sh-8-# (exported by marathon-drive.sh:245 so a nested driver doesn't deadlock on its parent's lock), and
test/gh284-runlog-heartbeat.sh-9-# the drivers spawned below would then skip the heartbeat/run-log block entirely — the very logic
--
test/gh342-sentinel-debug-log-python.sh-21-#   7  end-to-end on the default lane: a real marathon-drive run reclaiming a stale driver lock
test/gh342-sentinel-debug-log-python.sh-22-#      appends the stale-lock record (and writes nothing when the flag is off)
test/gh342-sentinel-debug-log-python.sh-23-source "$(dirname "$0")/_setup.sh" gh342-sentinel-debug-log-python
test/gh342-sentinel-debug-log-python.sh-24-
test/gh342-sentinel-debug-log-python.sh:25:# See test/driver-lock.sh: inherited from a marathon gate, this would skip the very lock block
test/gh342-sentinel-debug-log-python.sh-26-# case 7 exercises.
test/gh342-sentinel-debug-log-python.sh-27-unset RELAY_DRIVER_LOCKED
test/gh342-sentinel-debug-log-python.sh-28-# Load-bearing for the whole file: every case must exercise the DEFAULT lane.
test/gh342-sentinel-debug-log-python.sh-29-unset XYZ_PYTHON
--
test/gh342-sentinel-debug-log-python.sh-302-  fail "python behavior block did not report counts (exited $_py_rc before finishing)"
test/gh342-sentinel-debug-log-python.sh-303-fi
test/gh342-sentinel-debug-log-python.sh-304-
test/gh342-sentinel-debug-log-python.sh-305-# ── 7. End-to-end on the DEFAULT lane ────────────────────────────────────────────────────────
test/gh342-sentinel-debug-log-python.sh:306:# The stale-driver-lock reclaim is the one Tier-1 hook reachable from --dry-run (the lock block runs
test/gh342-sentinel-debug-log-python.sh-307-# long before the dry-run exit), which makes it the cheapest honest end-to-end proof that the capture
test/gh342-sentinel-debug-log-python.sh:308:# fires on the lane that actually executes. Setup copied from test/driver-lock.sh.
test/gh342-sentinel-debug-log-python.sh-309-#
test/gh342-sentinel-debug-log-python.sh-310-# Deliberately NOT claimed here: the escalation and lane-park hooks sit past the --dry-run exit and
test/gh342-sentinel-debug-log-python.sh-311-# would need a full driven relay to reach. They are covered by the wiring assertion (1g, an AST check
test/gh342-sentinel-debug-log-python.sh-312-# that they are called from their real call sites) plus the record-level parity in case 4 — which is
--
PROJECT/2-WORKING/MARATHON-2026-08-08-LITMUS-WAVE-2/MARATHON.yaml-150-# ---------------------------------------------------------------------------------------
PROJECT/2-WORKING/MARATHON-2026-08-08-LITMUS-WAVE-2/MARATHON.yaml-151-# RUN 1 (2026-08-08 22:56 PDT) — HALTED at phase 1. gh416 IS DONE; ITS LANE IS REMOVED BELOW.
PROJECT/2-WORKING/MARATHON-2026-08-08-LITMUS-WAVE-2/MARATHON.yaml-152-# ---------------------------------------------------------------------------------------
PROJECT/2-WORKING/MARATHON-2026-08-08-LITMUS-WAVE-2/MARATHON.yaml-153-# gh416 was BUILT AND APPROVED TWICE, by two independent codex builds with agy approving each:
PROJECT/2-WORKING/MARATHON-2026-08-08-LITMUS-WAVE-2/MARATHON.yaml:154:#   * run 0 (linked worktree, stopped by the operator to move to a clone) → origin f1403bd,
PROJECT/2-WORKING/MARATHON-2026-08-08-LITMUS-WAVE-2/MARATHON.yaml-155-#     PROJECT/PDDA-SYNC-POLICY.md at 68 lines / 6 sections
PROJECT/2-WORKING/MARATHON-2026-08-08-LITMUS-WAVE-2/MARATHON.yaml-156-#   * run 1 (this clone)                                                 → origin 2cd8673,
PROJECT/2-WORKING/MARATHON-2026-08-08-LITMUS-WAVE-2/MARATHON.yaml-157-#     same file at 44 lines / 4 sections
PROJECT/2-WORKING/MARATHON-2026-08-08-LITMUS-WAVE-2/MARATHON.yaml-158-# The shipped artifact is run 0's, with two additions grafted from run 1 (scope widened to
--
test/driver-lock.sh-1-#!/usr/bin/env bash
test/driver-lock.sh:2:# driver-lock.sh — GH-42 self-heal: marathon-drive reclaims a STALE relay-driver.lock (the holder
test/driver-lock.sh-3-# process is dead) so a crashed/killed driver never blocks every later run until a manual rmdir — but
test/driver-lock.sh-4-# it still REFUSES to start when the lock's holder is alive (the real concurrent-driver hazard).
test/driver-lock.sh:5:source "$(dirname "$0")/_setup.sh" driver-lock
test/driver-lock.sh-6-
test/driver-lock.sh-7-# Hermetic: the driver lock block is skipped when RELAY_DRIVER_LOCKED=1 (so a driver delegating to a
test/driver-lock.sh-8-# sub-driver doesn't double-lock). If this test runs UNDER a marathon gate, it would inherit that
test/driver-lock.sh-9-# export and skip the very logic it's testing (the lock would "leak"). Unset it so we always exercise
--
PROJECT/3-COMPLETED/MARATHON-2026-07-17-GH208-154-149-198/brief-gh149-require-clean.md-32-file.
PROJECT/3-COMPLETED/MARATHON-2026-07-17-GH208-154-149-198/brief-gh149-require-clean.md-33-
PROJECT/3-COMPLETED/MARATHON-2026-07-17-GH208-154-149-198/brief-gh149-require-clean.md-34-### What to do
PROJECT/3-COMPLETED/MARATHON-2026-07-17-GH208-154-149-198/brief-gh149-require-clean.md-35-
PROJECT/3-COMPLETED/MARATHON-2026-07-17-GH208-154-149-198/brief-gh149-require-clean.md:36:1. In `relay-automation/marathon-drive.sh`, when `$ROOT/.git` is a file (linked worktree), resolve
PROJECT/3-COMPLETED/MARATHON-2026-07-17-GH208-154-149-198/brief-gh149-require-clean.md:37:   the lock path via `git rev-parse --git-common-dir "$ROOT"` instead of placing it at
PROJECT/3-COMPLETED/MARATHON-2026-07-17-GH208-154-149-198/brief-gh149-require-clean.md-38-   `$ROOT/.relay-driver.lock` directly — this puts the lock in the real `.git/` dir, outside the
PROJECT/3-COMPLETED/MARATHON-2026-07-17-GH208-154-149-198/brief-gh149-require-clean.md-39-   worktree's own `git status --porcelain` view.
PROJECT/3-COMPLETED/MARATHON-2026-07-17-GH208-154-149-198/brief-gh149-require-clean.md-40-2. Add a regression test to `test/marathon-drive.sh` (a new, additive case) that runs
PROJECT/3-COMPLETED/MARATHON-2026-07-17-GH208-154-149-198/brief-gh149-require-clean.md:41:   `marathon-drive.sh --require-clean` from inside a linked worktree and asserts it no longer
PROJECT/3-COMPLETED/MARATHON-2026-07-17-GH208-154-149-198/brief-gh149-require-clean.md-42-   self-trips on its own lock.
PROJECT/3-COMPLETED/MARATHON-2026-07-17-GH208-154-149-198/brief-gh149-require-clean.md-43-3. Do not touch unrelated `marathon-drive.sh` logic — this is a narrow, single-purpose fix.
PROJECT/3-COMPLETED/MARATHON-2026-07-17-GH208-154-149-198/brief-gh149-require-clean.md-44-
PROJECT/3-COMPLETED/MARATHON-2026-07-17-GH208-154-149-198/brief-gh149-require-clean.md-45-### Acceptance / done means
PROJECT/3-COMPLETED/MARATHON-2026-07-17-GH208-154-149-198/brief-gh149-require-clean.md-46-
PROJECT/3-COMPLETED/MARATHON-2026-07-17-GH208-154-149-198/brief-gh149-require-clean.md:47:- `marathon-drive.sh --require-clean` succeeds from inside a linked worktree when nothing else is
PROJECT/3-COMPLETED/MARATHON-2026-07-17-GH208-154-149-198/brief-gh149-require-clean.md-48-  dirty (currently it fails on the lock alone).
PROJECT/3-COMPLETED/MARATHON-2026-07-17-GH208-154-149-198/brief-gh149-require-clean.md-49-- Full `bash test/marathon-drive.sh` green, including the new case.
PROJECT/3-COMPLETED/MARATHON-2026-07-17-GH208-154-149-198/brief-gh149-require-clean.md-50-- Leave a one-line status update in `GH-149-REQUIRE-CLEAN-SELFTRIP.md`'s Status table.
--
test/gh384-crash-recovery.sh-169-# ---------------------------------------------------------------------------
test/gh384-crash-recovery.sh-170-echo "-- driver lock state"
test/gh384-crash-recovery.sh-171-case "$out" in
test/gh384-crash-recovery.sh-172-  *"DRIVER LOCK: IDLE"*) pass "no lock present reports IDLE" ;;
test/gh384-crash-recovery.sh:173:  *) fail "GH-384: driver-lock state was not reported — report was:
test/gh384-crash-recovery.sh-174-$out" ;;
test/gh384-crash-recovery.sh-175-esac
test/gh384-crash-recovery.sh-176-
test/gh384-crash-recovery.sh-177-# A lock naming a pid that cannot exist must read STALE, not LIVE. The distinction is the whole
test/gh384-crash-recovery.sh-178-# reason the criterion names it: a stale lock self-heals, a LIVE one means something is still running.
test/gh384-crash-recovery.sh-179-# shellcheck source=/dev/null
test/gh384-crash-recovery.sh:180:source "$ROOT_DIR/relay-automation/driver-lock-lib.sh"
test/gh384-crash-recovery.sh-181-lockdir="$(driver_lock_path_for_repo "$R")"
test/gh384-crash-recovery.sh-182-mkdir -p "$lockdir"
test/gh384-crash-recovery.sh-183-printf '999999\n' >"$lockdir/pid"
test/gh384-crash-recovery.sh-184-out3="$(bash "$RECOVER" "$R" 2>&1)"
--
test/gh448-driver-lock-resolver.sh-1-#!/usr/bin/env bash
test/gh448-driver-lock-resolver.sh:2:# test/gh448-driver-lock-resolver.sh — GH-448: the shared driver-lock resolver.
test/gh448-driver-lock-resolver.sh-3-#
test/gh448-driver-lock-resolver.sh:4:# marathon-drive writes its lock to the git COMMON dir when .git is a FILE (a linked worktree). Every
test/gh448-driver-lock-resolver.sh-5-# read-only consumer used to guess the path with its OWN 2-branch inline logic (dir vs "everything
test/gh448-driver-lock-resolver.sh-6-# else"), which is wrong for the worktree case — so a LIVE marathon reported as IDLE. This test:
test/gh448-driver-lock-resolver.sh-7-#
test/gh448-driver-lock-resolver.sh:8:#   A. Parity — the Bash resolver (relay-automation/driver-lock-lib.sh) and the Python resolver
test/gh448-driver-lock-resolver.sh-9-#      (utils/py/rtl.py's driver_lock_path) agree byte-for-byte on all three branches: .git dir,
test/gh448-driver-lock-resolver.sh:10:#      .git file (real linked worktree), and no .git (vendored).
test/gh448-driver-lock-resolver.sh-11-#   B. Negative control (per #419) — the OLD 2-branch logic each consumer carried pre-fix, replayed
test/gh448-driver-lock-resolver.sh-12-#      verbatim against the SAME linked-worktree fixture, observably misses the lock the driver holds.
test/gh448-driver-lock-resolver.sh:13:#   C. End-to-end, real linked worktree — marathon-ls.sh, utils/hq/marathon-live.sh, and
test/gh448-driver-lock-resolver.sh-14-#      skills/relay-xyz/find-harness.sh --check, run for real against a `git worktree add` fixture
test/gh448-driver-lock-resolver.sh:15:#      with the lock held at the driver's real (common-dir) path, all observe it correctly.
test/gh448-driver-lock-resolver.sh-16-set -uo pipefail
test/gh448-driver-lock-resolver.sh-17-
test/gh448-driver-lock-resolver.sh-18-HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
test/gh448-driver-lock-resolver.sh-19-ROOT="$(cd "$HERE/.." && pwd)"
test/gh448-driver-lock-resolver.sh:20:LIB="$ROOT/relay-automation/driver-lock-lib.sh"
test/gh448-driver-lock-resolver.sh-21-LS="$ROOT/relay-automation/marathon-ls.sh"
test/gh448-driver-lock-resolver.sh-22-LIVE="$ROOT/utils/hq/marathon-live.sh"
test/gh448-driver-lock-resolver.sh-23-FH="$ROOT/skills/relay-xyz/find-harness.sh"
test/gh448-driver-lock-resolver.sh-24-
test/gh448-driver-lock-resolver.sh:25:# shellcheck source=relay-automation/driver-lock-lib.sh
test/gh448-driver-lock-resolver.sh-26-. "$LIB"
test/gh448-driver-lock-resolver.sh-27-
test/gh448-driver-lock-resolver.sh:28:WORK="$(mktemp -d "${TMPDIR:-/tmp}/gh448-driver-lock.XXXXXX")"
test/gh448-driver-lock-resolver.sh-29-# GH-177: guard BEFORE the re-capture below and BEFORE the rm -rf trap is armed. A failed mktemp
test/gh448-driver-lock-resolver.sh-30-# leaves $WORK empty, `cd ""` succeeds (it is a no-op), and `pwd -P` would then hand back the
test/gh448-driver-lock-resolver.sh-31-# script's own cwd — the repository root — straight into `rm -rf`. That is the historical repo-wipe
test/gh448-driver-lock-resolver.sh-32-# shape, and test/mktemp-trap-guard.sh caught this exact omission in CI when the re-capture was
--
test/gh448-driver-lock-resolver.sh-35-# scans `;`-delimited segments, so a `{ echo ...; exit 1; }` parks the abort in a different segment
test/gh448-driver-lock-resolver.sh-36-# from the `||` and reads as unguarded. Same shape as test/gh292-worktree-vendored-discovery.sh:16.
test/gh448-driver-lock-resolver.sh-37-[ -n "$WORK" ] && [ -d "$WORK" ] || { echo "  FAIL: mktemp -d produced no usable dir" >&2 && exit 1; }
test/gh448-driver-lock-resolver.sh-38-# Resolve to the PHYSICAL path before deriving any fixture path from it. The resolver under test
test/gh448-driver-lock-resolver.sh:39:# reads `git rev-parse --path-format=absolute --git-common-dir`, and git ALWAYS reports a physical
test/gh448-driver-lock-resolver.sh-40-# path; on macOS $TMPDIR lives under /var, a symlink to /private/var, so a $TMPDIR-derived expected
test/gh448-driver-lock-resolver.sh-41-# string ("/var/...") never equals git's answer ("/private/var/...") and 3 of 17 assertions fail.
test/gh448-driver-lock-resolver.sh-42-# Linux CI has no such symlink, which is why this passed there (17/0) and failed only on macOS —
test/gh448-driver-lock-resolver.sh-43-# an environment split, not a defect in the resolver: the driver writes the lock through this same
--
test/gh448-driver-lock-resolver.sh-49-PASS=0; FAIL=0
test/gh448-driver-lock-resolver.sh-50-pass() { printf '  PASS: %s\n' "$*"; PASS=$((PASS+1)); }
test/gh448-driver-lock-resolver.sh-51-fail() { printf '  FAIL: %s\n' "$*" >&2; FAIL=$((FAIL+1)); }
test/gh448-driver-lock-resolver.sh-52-
test/gh448-driver-lock-resolver.sh:53:echo "== test: gh448-driver-lock-resolver =="
test/gh448-driver-lock-resolver.sh-54-echo "  workdir: $WORK"
test/gh448-driver-lock-resolver.sh-55-
test/gh448-driver-lock-resolver.sh-56-py_resolve() {  # <repo> -> prints the python resolver's lock path
test/gh448-driver-lock-resolver.sh-57-  python3 -c '
--
test/gh448-driver-lock-resolver.sh-73-# (2) Vendored: no .git at all.
test/gh448-driver-lock-resolver.sh-74-ABSENT_REPO="$WORK/absent-repo"
test/gh448-driver-lock-resolver.sh-75-mkdir -p "$ABSENT_REPO"
test/gh448-driver-lock-resolver.sh-76-
test/gh448-driver-lock-resolver.sh:77:# (3) Real linked worktree: .git is a FILE pointing at the shared gitdir.
test/gh448-driver-lock-resolver.sh-78-MAIN_REPO="$WORK/main-repo"
test/gh448-driver-lock-resolver.sh-79-mkdir -p "$MAIN_REPO"
test/gh448-driver-lock-resolver.sh-80-git init -q "$MAIN_REPO"
test/gh448-driver-lock-resolver.sh-81-git -C "$MAIN_REPO" config user.email t@example.com
--
test/gh448-driver-lock-resolver.sh-84-git -C "$MAIN_REPO" add seed.txt
test/gh448-driver-lock-resolver.sh-85-git -C "$MAIN_REPO" commit -qm seed
test/gh448-driver-lock-resolver.sh-86-WT="$WORK/wt"
test/gh448-driver-lock-resolver.sh-87-git -C "$MAIN_REPO" worktree add -q "$WT" -b gh448-wt-branch
test/gh448-driver-lock-resolver.sh:88:[ -f "$WT/.git" ] && pass "fixture: linked worktree's .git is a FILE (not a dir)" \
test/gh448-driver-lock-resolver.sh-89-  || fail "fixture setup: expected $WT/.git to be a file"
test/gh448-driver-lock-resolver.sh-90-
test/gh448-driver-lock-resolver.sh-91-COMMON_LOCK="$MAIN_REPO/.git/relay-driver.lock"
test/gh448-driver-lock-resolver.sh-92-
--
test/gh448-driver-lock-resolver.sh-114-#    asserted-in-prose. All three must MISS the lock the driver holds.
test/gh448-driver-lock-resolver.sh-115-# ===========================================================================
test/gh448-driver-lock-resolver.sh-116-echo "-- B. negative control: pre-fix 2-branch logic misses the worktree lock --"
test/gh448-driver-lock-resolver.sh-117-
test/gh448-driver-lock-resolver.sh:118:# marathon-ls.sh's original lock_path_for_repo (pre-GH-448):
test/gh448-driver-lock-resolver.sh-119-old_marathon_ls_lock() {
test/gh448-driver-lock-resolver.sh-120-  local repo="$1"
test/gh448-driver-lock-resolver.sh-121-  if [ -d "$repo/.git" ]; then printf '%s/.git/relay-driver.lock' "$repo"
test/gh448-driver-lock-resolver.sh-122-  else printf '%s/.relay-driver.lock' "$repo"; fi
test/gh448-driver-lock-resolver.sh-123-}
test/gh448-driver-lock-resolver.sh-124-
test/gh448-driver-lock-resolver.sh:125:# utils/hq/marathon-live.sh's original driver_lock_path (pre-GH-448):
test/gh448-driver-lock-resolver.sh-126-old_marathon_live_lock() {
test/gh448-driver-lock-resolver.sh-127-  local repo="$1"
test/gh448-driver-lock-resolver.sh-128-  [ -e "$repo/.git/relay-driver.lock" ] && { printf '%s' "$repo/.git/relay-driver.lock"; return 0; }
test/gh448-driver-lock-resolver.sh-129-  [ -e "$repo/.xyz/.relay-driver.lock" ] && { printf '%s' "$repo/.xyz/.relay-driver.lock"; return 0; }
--

2026-08-12T04:35:05.762314Z ERROR codex_models_manager::manager: failed to renew cache TTL: missing field `base_instructions` at line 95 column 5
exec
/bin/zsh -lc "rg --files PROJECT | rg 'GH-(376|448)' && rg -n -C 6 \"Phase 1|#354|all three|relay.*relay|marathon.*relay|linked worktree|close\" PROJECT/3-COMPLETED/GH-376* PROJECT/3-COMPLETED/GH-448* PROJECT/2-WORKING/GH-448* 2>/dev/null; nl -ba relay-automation/driver-lock-lib.sh; nl -ba test/gh448-driver-lock-resolver.sh | sed -n '53,240p'" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-69972-gxaghv_u
 succeeded in 0ms:
PROJECT/3-COMPLETED/GH-448-DRIVER-LOCK-RESOLVER.md
PROJECT/2-WORKING/GH-376-RELAY-DRIVE-LOCK-PATH-DIVERGENCE.md
zsh:1: no matches found: PROJECT/3-COMPLETED/GH-376*
     1	#!/usr/bin/env bash
     2	# driver-lock-lib.sh — GH-448: the ONE shared resolver for the relay-driver lock path.
     3	#
     4	# Mirrors the DRIVER's own write-side resolution (marathon_drive.py / marathon-drive.sh,
     5	# relay_drive.py / relay-drive.sh) byte-for-byte (utils/py/rtl.py's driver_lock_path is the Python
     6	# twin — the two MUST agree, asserted by test/gh448-driver-lock-resolver.sh). SOURCED by every
     7	# read-only consumer of the lock (marathon-ls.sh, utils/hq/marathon-live.sh,
     8	# skills/relay-xyz/find-harness.sh) — a consumer that constructs this path inline instead of calling
     9	# this function is the bug this file exists to kill (5 of 7 construction sites had drifted to a
    10	# 2-branch guess that misses the linked-worktree case, silently reporting a LIVE marathon as IDLE).
    11	#
    12	#   .git is a directory  -> <repo>/.git/relay-driver.lock              (normal clone)
    13	#   .git is a file       -> <git-common-dir>/relay-driver.lock         (linked worktree)
    14	#   no .git (vendored)   -> <repo>/.relay-driver.lock                  (vendored .xyz/ copy)
    15	#
    16	# API:
    17	#   driver_lock_path_for_repo <repo-root>   — prints the resolved lock path (no trailing newline)
    18	set -u
    19	
    20	driver_lock_path_for_repo() {
    21	  local repo="$1"
    22	  if [ -d "$repo/.git" ]; then
    23	    printf '%s/.git/relay-driver.lock' "$repo"
    24	    return 0
    25	  fi
    26	  if [ -f "$repo/.git" ]; then
    27	    local common
    28	    common="$(git -C "$repo" rev-parse --path-format=absolute --git-common-dir 2>/dev/null || true)"
    29	    if [ -n "$common" ]; then
    30	      printf '%s/relay-driver.lock' "$common"
    31	      return 0
    32	    fi
    33	  fi
    34	  printf '%s/.relay-driver.lock' "$repo"
    35	}
    53	echo "== test: gh448-driver-lock-resolver =="
    54	echo "  workdir: $WORK"
    55	
    56	py_resolve() {  # <repo> -> prints the python resolver's lock path
    57	  python3 -c '
    58	import sys
    59	sys.path.insert(0, sys.argv[2])
    60	from rtl import driver_lock_path
    61	print(driver_lock_path(sys.argv[1])[0], end="")
    62	' "$1" "$ROOT/utils/py"
    63	}
    64	
    65	# ---------------------------------------------------------------------------
    66	# Fixtures
    67	# ---------------------------------------------------------------------------
    68	
    69	# (1) Normal clone: .git is a directory.
    70	DIR_REPO="$WORK/dir-repo"
    71	mkdir -p "$DIR_REPO/.git"
    72	
    73	# (2) Vendored: no .git at all.
    74	ABSENT_REPO="$WORK/absent-repo"
    75	mkdir -p "$ABSENT_REPO"
    76	
    77	# (3) Real linked worktree: .git is a FILE pointing at the shared gitdir.
    78	MAIN_REPO="$WORK/main-repo"
    79	mkdir -p "$MAIN_REPO"
    80	git init -q "$MAIN_REPO"
    81	git -C "$MAIN_REPO" config user.email t@example.com
    82	git -C "$MAIN_REPO" config user.name "gh448 test"
    83	printf 'seed\n' >"$MAIN_REPO/seed.txt"
    84	git -C "$MAIN_REPO" add seed.txt
    85	git -C "$MAIN_REPO" commit -qm seed
    86	WT="$WORK/wt"
    87	git -C "$MAIN_REPO" worktree add -q "$WT" -b gh448-wt-branch
    88	[ -f "$WT/.git" ] && pass "fixture: linked worktree's .git is a FILE (not a dir)" \
    89	  || fail "fixture setup: expected $WT/.git to be a file"
    90	
    91	COMMON_LOCK="$MAIN_REPO/.git/relay-driver.lock"
    92	
    93	# ===========================================================================
    94	# A. Parity — Bash resolver vs Python resolver, all three branches
    95	# ===========================================================================
    96	echo "-- A. resolver parity (bash vs python) --"
    97	
    98	for case_name_repo in "dir:$DIR_REPO" "absent:$ABSENT_REPO" "worktree:$WT"; do
    99	  name="${case_name_repo%%:*}"; repo="${case_name_repo#*:}"
   100	  bash_out="$(driver_lock_path_for_repo "$repo")"
   101	  py_out="$(py_resolve "$repo")"
   102	  [ "$bash_out" = "$py_out" ] \
   103	    && pass "parity ($name): bash and python agree ($bash_out)" \
   104	    || fail "parity ($name): bash='$bash_out' python='$py_out'"
   105	done
   106	
   107	[ "$(driver_lock_path_for_repo "$WT")" = "$COMMON_LOCK" ] \
   108	  && pass "worktree case resolves to the git COMMON dir, not <worktree>/.git/…" \
   109	  || fail "worktree case resolved wrong: $(driver_lock_path_for_repo "$WT") (expected $COMMON_LOCK)"
   110	
   111	# ===========================================================================
   112	# B. Negative control — the OLD 2-branch logic each site carried, replayed
   113	#    verbatim against the SAME worktree fixture. Per #419: observed, not
   114	#    asserted-in-prose. All three must MISS the lock the driver holds.
   115	# ===========================================================================
   116	echo "-- B. negative control: pre-fix 2-branch logic misses the worktree lock --"
   117	
   118	# marathon-ls.sh's original lock_path_for_repo (pre-GH-448):
   119	old_marathon_ls_lock() {
   120	  local repo="$1"
   121	  if [ -d "$repo/.git" ]; then printf '%s/.git/relay-driver.lock' "$repo"
   122	  else printf '%s/.relay-driver.lock' "$repo"; fi
   123	}
   124	
   125	# utils/hq/marathon-live.sh's original driver_lock_path (pre-GH-448):
   126	old_marathon_live_lock() {
   127	  local repo="$1"
   128	  [ -e "$repo/.git/relay-driver.lock" ] && { printf '%s' "$repo/.git/relay-driver.lock"; return 0; }
   129	  [ -e "$repo/.xyz/.relay-driver.lock" ] && { printf '%s' "$repo/.xyz/.relay-driver.lock"; return 0; }
   130	  return 1
   131	}
   132	
   133	mkdir -p "$COMMON_LOCK"; printf '%s\n' "$$" >"$COMMON_LOCK/pid"
   134	
   135	old_ls_path="$(old_marathon_ls_lock "$WT")"
   136	[ "$old_ls_path" != "$COMMON_LOCK" ] && [ ! -e "$old_ls_path" ] \
   137	  && pass "negative control: old marathon-ls.sh logic guesses '$old_ls_path' — misses the held lock" \
   138	  || fail "negative control: old marathon-ls.sh logic unexpectedly found the lock"
   139	
   140	if old_live_path="$(old_marathon_live_lock "$WT")"; then
   141	  fail "negative control: old marathon-live.sh logic unexpectedly found the lock ($old_live_path)"
   142	else
   143	  pass "negative control: old marathon-live.sh logic (checks .git/… or .xyz/… under \$WT) misses the held lock"
   144	fi
   145	
   146	old_fh_found=0
   147	for _lk in "$WT/.git/relay-driver.lock" "$WT/.relay-driver.lock"; do
   148	  [ -d "$_lk" ] && old_fh_found=1
   149	done
   150	[ "$old_fh_found" -eq 0 ] \
   151	  && pass "negative control: old find-harness.sh 2-candidate loop misses the held lock" \
   152	  || fail "negative control: old find-harness.sh 2-candidate loop unexpectedly found the lock"
   153	
   154	rm -rf "$COMMON_LOCK"
   155	
   156	# ===========================================================================
   157	# C. End-to-end, real linked worktree — the ACTUAL (fixed) scripts
   158	# ===========================================================================
   159	echo "-- C. end-to-end: fixed scripts observe LIVE from a linked worktree --"
   160	
   161	mkdir -p "$COMMON_LOCK"; printf '%s\n' "$$" >"$COMMON_LOCK/pid"
   162	
   163	# C1. marathon-ls.sh — registry row pointing at the worktree.
   164	REGISTRY="$WORK/registry.tsv"
   165	printf 'install_dir\tlast_install_utc\ttick_version\tsource_commit\tcoordinated_repo\n' >"$REGISTRY"
   166	printf '%s\t2026-08-08\tv1\tabc\t%s\n' "$WT/.xyz" "$WT" >>"$REGISTRY"
   167	
   168	ls_out="$(XYZ_REGISTRY="$REGISTRY" bash "$LS" 2>/dev/null || true)"
   169	ls_state="$(printf '%s' "$ls_out" | awk -F'\t' -v r="$WT" '$1 == r { print $2 }')"
   170	[ "$ls_state" = "LIVE" ] \
   171	  && pass "marathon-ls.sh: linked worktree with held common-dir lock -> LIVE" \
   172	  || fail "marathon-ls.sh: expected LIVE, got '${ls_state:-<no row>}'"
   173	
   174	# C2. utils/hq/marathon-live.sh — claimed task + the same held lock.
   175	mkdir -p "$WT/.tick" "$WT/bin"
   176	cat >"$WT/bin/tick" <<'EOF'
   177	#!/usr/bin/env bash
   178	exit 0
   179	EOF
   180	chmod +x "$WT/bin/tick"
   181	{
   182	  printf '# Coordination State\n\n## Open\n_(none)_\n\n## Claimed\n'
   183	  printf -- '- MARATHON-GH448-DRIVER-LOCK-TURN by agy\n'
   184	  printf '\n## Done\n_(none)_\n'
   185	} >"$WT/.tick/STATE.md"
   186	
   187	XYZ_REG2="$WORK/xyz.tsv"
   188	printf '%s\t2026-08-08T00:00:00Z\tv1\tabc\t%s\n' "$WT/.xyz" "$WT" >"$XYZ_REG2"
   189	
   190	LIVE_OUT="$WORK/HQ-MARATHON-LIVE-gh448.md"
   191	HQ_PDDA_REGISTRY_DIR="$WORK/empty-pdda" \
   192	HQ_REBALANCE_DB="$WORK/nonexistent.db" \
   193	HQ_XYZ_REGISTRY="$XYZ_REG2" \
   194	HQ_SEARCH_ROOTS="$WORK" \
   195	HQ_MARATHON_LIVE_TODAY="2026-08-08" \
   196	HQ_MARATHON_LIVE_NOW="2026-08-08T12:00:00Z" \
   197	HQ_MARATHON_LIVE_NOW_EPOCH="1000000000" \
   198	bash "$LIVE" --out "$LIVE_OUT" >/dev/null 2>&1
   199	grep -q '🟢 live' "$LIVE_OUT" 2>/dev/null \
   200	  && pass "marathon-live.sh: claimed task + linked-worktree common-dir lock -> 🟢 live" \
   201	  || fail "marathon-live.sh: expected a 🟢 live row: $(grep -E '^\| ' "$LIVE_OUT" 2>/dev/null || echo '(no report)')"
   202	
   203	# C3. find-harness.sh --check — a "harness" fixture whose skill script + lib live in a linked
   204	# worktree, invoked from a separate FOREIGN caller repo so the concurrency-warning gate fires.
   205	HARNESS_MAIN="$WORK/harness-main"
   206	mkdir -p "$HARNESS_MAIN/relay-automation" "$HARNESS_MAIN/skills/relay-xyz"
   207	printf '#!/usr/bin/env bash\n:\n' >"$HARNESS_MAIN/relay-automation/relay-drive.sh"
   208	chmod +x "$HARNESS_MAIN/relay-automation/relay-drive.sh"
   209	cp "$LIB" "$HARNESS_MAIN/relay-automation/driver-lock-lib.sh"
   210	cp "$FH" "$HARNESS_MAIN/skills/relay-xyz/find-harness.sh"
   211	git init -q "$HARNESS_MAIN"
   212	git -C "$HARNESS_MAIN" config user.email t@example.com
   213	git -C "$HARNESS_MAIN" config user.name "gh448 test"
   214	git -C "$HARNESS_MAIN" add -A
   215	git -C "$HARNESS_MAIN" commit -qm seed
   216	HARNESS_WT="$WORK/harness-wt"
   217	git -C "$HARNESS_MAIN" worktree add -q "$HARNESS_WT" -b gh448-harness-wt-branch
   218	
   219	HARNESS_COMMON_LOCK="$HARNESS_MAIN/.git/relay-driver.lock"
   220	mkdir -p "$HARNESS_COMMON_LOCK"; printf '%s\n' "$$" >"$HARNESS_COMMON_LOCK/pid"
   221	
   222	FOREIGN="$WORK/foreign"
   223	mkdir -p "$FOREIGN"
   224	git init -q "$FOREIGN"
   225	
   226	fh_out="$(cd "$FOREIGN" && bash "$HARNESS_WT/skills/relay-xyz/find-harness.sh" --check 2>&1)"
   227	printf '%s' "$fh_out" | grep -q 'a driver lock is currently HELD' \
   228	  && pass "find-harness.sh --check: linked-worktree harness + held common-dir lock -> warns" \
   229	  || fail "find-harness.sh --check: expected a held-lock warning, got: $fh_out"
   230	printf '%s' "$fh_out" | grep -qF "$HARNESS_COMMON_LOCK" \
   231	  && pass "find-harness.sh --check: warning names the REAL (common-dir) lock path" \
   232	  || fail "find-harness.sh --check: warning did not name $HARNESS_COMMON_LOCK: $fh_out"
   233	
   234	# ---------------------------------------------------------------------------
   235	echo "-- syntax check --"
   236	for s in "$LIB" "$LS" "$LIVE" "$FH" "$HERE/gh448-driver-lock-resolver.sh"; do
   237	  bash -n "$s" 2>/dev/null && pass "syntax OK: $(basename "$s")" || fail "syntax error in: $s"
   238	done
   239	
   240	printf '\ngh448-driver-lock-resolver: %d pass, %d fail\n' "$PASS" "$FAIL"

2026-08-12T04:35:11.305870Z ERROR codex_models_manager::manager: failed to renew cache TTL: missing field `base_instructions` at line 95 column 5
exec
/bin/zsh -lc "nl -ba PROJECT/2-WORKING/GH-376-RELAY-DRIVE-LOCK-PATH-DIVERGENCE.md | sed -n '1,260p'
nl -ba PROJECT/3-COMPLETED/GH-448-DRIVER-LOCK-RESOLVER.md | sed -n '1,220p'
rg -n -C 3 \"driver_lock_path|relay-driver.lock|RELAY_DRIVER_LOCKED\" utils/py/relay_drive.py utils/py/marathon_drive.py relay-automation/relay-drive.sh relay-automation/marathon-drive.sh | head -n 350" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-69972-gxaghv_u
 succeeded in 0ms:
     1	---
     2	gh_issue: 376
     3	source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/376
     4	title: "GH-376 — relay-drive and marathon-drive take different locks from a linked worktree, so the mutual exclusion they both believe in does not exist"
     5	status: "BUILT 2026-08-11 — shipped as a direct PR against `development`, as the capture required. Both twins now resolve the lock through GH-448's shared resolver (`utils/py/rtl.py::driver_lock_path` / `relay-automation/driver-lock-lib.sh`) instead of their own 2-branch guess. `test/gh376-relay-drive-lock-parity.sh` 18/0 against a REAL `git worktree add` fixture; negative control replays the pre-fix resolution on BOTH lanes and observes each sail past a held lock. Normal-clone and vendored controls unchanged. The defect was confirmed LIVE while building, not only in fixture: a marathon running in a sibling clone (pid 39588) held the lock in this repo's common `.git/`, and post-fix `test/poll-relay.sh` + `test/relay-escalation-not-stall.sh` correctly refuse from a linked worktree — both pass in a standalone clone with no driver running. That refusal IS the fix; see the operational note appended below. Awaiting operator close."
     6	created: 2026-08-10
     7	updated: 2026-08-10
     8	owner: noel
     9	doc_type: project
    10	release: "0.3.0 Nightwatch"
    11	complexity: 2
    12	risk: 3
    13	effort: 2
    14	phases: 1
    15	ratings_provisional: true
    16	roadmap_exempt: false
    17	related:
    18	  - "#448 — CLOSED, shipped in PR #449 (merged `000aa6ce`). Built the ONE shared driver-lock resolver (`relay-automation/driver-lock-lib.sh` + `utils/py/rtl.py::driver_lock_path`) for every READ-ONLY consumer of the lock, and its own doc explicitly carves this issue out: 'relay-drive.sh/relay_drive.py are tracked separately by sibling issue #376 (the driver-side half of the same defect class).' #448 does not fix #376 — it changes what the cheapest correct fix for #376 now looks like, because a proven-correct resolver already exists to reuse instead of writing a third inline copy."
    19	  - "#358 — a DIFFERENT lock entirely: an advisory mkdir lock on a per-repo `$XYZ_JSON.lock` guarding `utils/telemetry/append-xyz-completion.sh`'s read-modify-write of the completion-event log, not `relay-driver.lock`. Phase 1 (retain each appender's exit status, report terminal state) shipped in PR #489. Its instrumentation is single-process, single-repo, and carries no path-resolution logic — it changes nothing about #376. Both are 'a lock is wrong' findings in the same release, at unrelated call sites, with unrelated fixes."
    20	  - "#354 — the parent analysis. This issue's own text calls itself 'the actionable defect its code review turned up,' and #354 itself has no ## Acceptance section and no Swarm Preflight Contract (named as such in the Nightwatch wave-1 CHANGELOG entry), so it is not itself preflightable."
    21	  - "#149 — CLOSED. Same relay-driver.lock, a different failure: marathon-drive's own `--require-clean` self-tripping on its own lock directory, not a cross-driver path mismatch."
    22	  - "#141 — CLOSED. Adjacent blind spot: containment cannot see a concurrent peer at all. #376 is sharper — the two drivers DO try to see each other through this lock; the mechanism is just broken in one topology (linked worktree)."
    23	non_goals:
    24	  - "The mode-aware lockout redesign the issue itself proposes as a 'broader shape worth considering' (a lock record naming the mode/phase, a compatibility matrix, mode-aware refusal messages). The issue says this 'may belong in the GH-354 plan rather than here.' Out of scope here; the single-mutex path-resolution bug is what this lane fixes."
    25	  - "Changing lock ACQUISITION or reclaim semantics — stale-holder reclaim, the TOCTOU window noted at `marathon-drive.sh:226-227`, pid bookkeeping. This is a path-resolution fix only, mirroring #448's own non-goal on the identical code area."
    26	  - "Editing `relay-automation/marathon-drive.sh` or `utils/py/marathon_drive.py`'s own lock resolution. Both are already correct (verified below) and #448 left the Bash side byte-unchanged for the same reason."
    27	  - "Editing `utils/py/rtl.py::driver_lock_path` or `relay-automation/driver-lock-lib.sh` themselves. Both are the shared resolver #448 already shipped; this lane may call/import them but must not modify them — `rtl.py` is the turn kernel, and editing it would make this lane self-modifying in a second, worse way."
    28	  - "Firing this as a marathon or relay lane. See Reversibility & blast radius — the write-set is the marathon driver's own per-turn-loop subprocess."
    29	goal: >
    30	  marathon-drive.sh:195-196 states, in-tree, that a marathon and a relay driver mutually exclude via
    31	  one shared lock NAME. From a normal clone that is true. From a linked worktree — the exact topology
    32	  swarm-preflight.sh's own recommended invocation creates via RELAY_WORKTREE_ISOLATION=1 — .git is a
    33	  file, not a directory, and the two drivers' resolvers diverge: marathon-drive (and, since #448,
    34	  utils/py/marathon_drive.py via the shared resolver) correctly follows .git to the git COMMON dir;
    35	  relay-drive still guesses with the old 2-branch logic and lands on a lock local to whichever
    36	  worktree it happens to run in. Two independently-launched top-level drivers can then each hold what
    37	  they believe is THE lock while running against the same working tree, invisible to each other. Make
    38	  relay-drive's Bash and Python resolution agree with marathon-drive's from a linked worktree, so the
    39	  exclusion the comment already claims becomes true.
    40	---
    41	
    42	# GH-376 · relay-drive resolves a different lock than marathon-drive from a linked worktree
    43	
    44	## Status
    45	
    46	| What was just completed | What's next |
    47	|---|---|
    48	| Captured 2026-08-10 as a lane of release 0.3.0 Nightwatch. The issue has no `## Acceptance` section; criteria are authored below in a clearly separate section. Every locking claim in the issue was re-verified against the current tree and holds. Verification also surfaced two things the issue does not say: (1) `#448` already shipped a proven-correct shared resolver this fix should reuse rather than duplicate a third time, and (2) `relay-drive.sh` is not an inert helper — it is the literal per-phase-turn subprocess `marathon-drive.sh`/`marathon_drive.py` exec, by its own comment ("relay-drive.sh IS the loop"), which makes this fix self-modifying. | Direct PR against `development`. Not preflightable as a marathon lane — see Reversibility & blast radius. |
    49	
    50	**Issue:** https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/376
    51	
    52	## The defect
    53	
    54	**The divergence, verified byte-for-byte against the issue's own claims, tree at 2026-08-10:**
    55	
    56	`relay-automation/marathon-drive.sh:189-208` — three branches (comment at 190-196 asserts the
    57	exclusion):
    58	
    59	```
    60	189  if [[ "${RELAY_DRIVER_LOCKED:-0}" != "1" ]]; then
    61	197    if [[ -d "$ROOT/.git" ]]; then
    62	198      _lock="$ROOT/.git/relay-driver.lock"; _lock_label=".git/relay-driver.lock"
    63	199    elif [[ -f "$ROOT/.git" ]]; then
    64	200      _git_common_dir="$(git -C "$ROOT" rev-parse --git-common-dir 2>/dev/null || true)"
    65	201-205  [common-dir branch]
    66	206    else
    67	207      _lock="$ROOT/.relay-driver.lock";     _lock_label=".relay-driver.lock"
    68	208    fi
    69	```
    70	
    71	`relay-automation/relay-drive.sh:142-151` — **two** branches, no `-f` case, exactly as the issue
    72	describes:
    73	
    74	```
    75	142  if [[ "${RELAY_DRIVER_LOCKED:-0}" != "1" ]]; then
    76	147    if [[ -d "$ROOT_DIR/.git" ]]; then
    77	148      _lock="$ROOT_DIR/.git/relay-driver.lock"; _lock_label=".git/relay-driver.lock"
    78	149    else
    79	150      _lock="$ROOT_DIR/.relay-driver.lock";     _lock_label=".relay-driver.lock"
    80	151    fi
    81	```
    82	
    83	`utils/py/relay_drive.py:385-391` carries the identical 2-branch shape (no `isfile`/common-dir case)
    84	— confirmed, matching the issue's claim about the default Python runtime.
    85	
    86	`utils/swarm-preflight.sh:821` confirmed: `RELAY_WORKTREE_ISOLATION=1` is present in the invocation
    87	`swarm-preflight` recommends, so the linked-worktree topology is not exotic — it is what preflight
    88	itself creates.
    89	
    90	**Not in the issue — finding 1: a shared resolver already exists and one driver already uses it.**
    91	`utils/py/rtl.py:477-499` defines `driver_lock_path(root)`, a 3-branch resolver (dir / file+
    92	`git-common-dir` / absent) whose own docstring (line 478-481) claims it matches "the DRIVER's own
    93	write-side resolution (marathon_drive.py / marathon-drive.sh, relay_drive.py / relay-drive.sh)".
    94	`utils/py/marathon_drive.py:20` imports it (`from rtl import driver_lock_path`) and calls it at
    95	`:611` — so the Python marathon driver already resolves correctly via the shared function. But
    96	`utils/py/relay_drive.py` does **not** import it; it still constructs the path inline (385-391). So
    97	`rtl.py`'s own comment is currently false about half of what it claims to describe — a second wrong
    98	comment in this area, not just `marathon-drive.sh:195-196`. This resolver was built by `#448`
    99	(closed, PR #449) specifically for read-only lock *consumers* (`marathon-ls.sh`,
   100	`utils/hq/marathon-live.sh`, `skills/relay-xyz/find-harness.sh`); `#448`'s own doc explicitly excludes
   101	`relay-drive.sh`/`relay_drive.py` as this issue's scope. A Bash twin of the same resolver,
   102	`relay-automation/driver-lock-lib.sh:20-35` (`driver_lock_path_for_repo`), is sourced only by
   103	`marathon-ls.sh` — not by `marathon-drive.sh` (which keeps its own inline copy, left byte-unchanged
   104	by #448 since it was already correct) and not by `relay-drive.sh`.
   105	
   106	**Not in the issue — finding 2: this write-set is the marathon driver's own turn loop.**
   107	`relay-automation/marathon-drive.sh:27-28`: "calls relay-drive.sh unmodified, runs the pre-advance
   108	gate, emits phase events, and saves the transcript. Does NOT reimplement any loop logic —
   109	relay-drive.sh IS the loop." `marathon-drive.sh:82` and `utils/py/marathon_drive.py:474` both default
   110	to invoking exactly `relay-automation/relay-drive.sh` as that subprocess. The buggy 2-branch lock
   111	code only actually *executes* when `relay-drive` is launched standalone, not nested inside a running
   112	marathon: `marathon_drive.py:649` (and `marathon-drive.sh:245`) sets `RELAY_DRIVER_LOCKED=1` in the
   113	environment after acquiring its own (correct) lock, and both `relay-drive.sh:142` and
   114	`relay_drive.py:385` skip their own lock-acquisition block entirely when that variable is already
   115	`1`. So the actual collision the issue describes is between two *independently launched, top-level*
   116	drivers — one via `marathon-drive`, one via a standalone `relay-drive` invocation (e.g. `/relay-xyz`)
   117	— from two linked worktrees of the same repo. But `relay-drive.sh`'s *other* code still runs, fresh,
   118	as a subprocess on every single phase turn a marathon takes. See Reversibility & blast radius.
   119	
   120	Both target files are GH-308 frozen twins: `relay-automation/relay-drive.sh` : `utils/py/relay_drive.py`
   121	is `TWINS` entry #8 in `test/gh308-frozen-twin-guard.sh:21`. Both open with `# FROZEN (GH-308): Python
   122	is authoritative — do not make behavior changes here` (`relay-drive.sh:2`), and both currently default
   123	to Python at runtime: `${XYZ_PYTHON-1}` (`relay-drive.sh:9`) evaluates to `1` when the variable is
   124	unset, so the in-file comment "Default (unset/0) runs... Bash" (`relay-drive.sh:7-8`) is itself stale
   125	relative to the repo-wide Python-default flip — a third stale comment nearby, noted for completeness,
   126	not part of this issue's scope to fix.
   127	
   128	## Acceptance
   129	
   130	*Issue #376 contains no `## Acceptance` section — verified against the fetched issue body. There is
   131	no verbatim block to copy. Criteria are authored in the section immediately below, kept clearly
   132	separate from this heading per the drafting brief's instruction never to put authored criteria inside
   133	`## Acceptance` itself.*
   134	
   135	## Acceptance criteria — authored (the issue has none)
   136	
   137	- [ ] From a **real** linked worktree (`.git` is a file — created with `git worktree add`, not
   138	      simulated), `relay-drive.sh`'s standalone lock-acquisition path (i.e. `RELAY_DRIVER_LOCKED`
   139	      unset, the same condition already gating that code block at `relay-drive.sh:142`) resolves to
   140	      the identical absolute lock path that `marathon-drive.sh`'s own resolution
   141	      (`marathon-drive.sh:189-208`) would compute for the same repo.
   142	- [ ] `utils/py/relay_drive.py`'s equivalent standalone lock-acquisition path resolves to the
   143	      identical path `utils/py/marathon_drive.py` already resolves via `driver_lock_path`
   144	      (`marathon_drive.py:611`) for the same repo.
   145	- [ ] `relay-drive.sh` and `relay_drive.py` agree with **each other**, byte-for-byte, on all three
   146	      branches (`.git` dir / `.git` file / no `.git`) — not just each independently agreeing with the
   147	      marathon side.
   148	- [ ] A test demonstrates this against a real `git worktree add` fixture, not asserted in prose, and
   149	      includes a negative control per #419: the OLD 2-branch logic (shown verbatim in The defect,
   150	      above) replayed against the identical fixture is shown to diverge from marathon-drive's path,
   151	      before the fixed logic is shown to agree — mirroring the shape `test/gh448-driver-lock-resolver.sh`
   152	      already established for the sibling defect.
   153	- [ ] `relay-automation/marathon-drive.sh` and `utils/py/marathon_drive.py`'s own lock resolution are
   154	      unchanged (both already correct, per The defect above).
   155	- [ ] `utils/py/rtl.py` and `relay-automation/driver-lock-lib.sh` are unchanged in behavior — the fix
   156	      may import/call `driver_lock_path` / `driver_lock_path_for_repo` but must not modify either.
   157	- [ ] `relay-drive.sh` carries a `Frozen-twin-exception:` trailer naming the file if it is edited (per
   158	      GH-308; `utils/py/relay_drive.py` is the authoritative side).
   159	- [ ] Ships as a direct PR against `development`. Never dispatched as a marathon or relay lane — see
   160	      Reversibility & blast radius for why.
   161	- [ ] The mode-aware lockout redesign the issue floats as a "broader shape worth considering" is
   162	      explicitly out of scope for this change (see non_goals).
   163	
   164	There is no `## Acceptance — deviations from the issue` section: there is no verbatim block to
   165	deviate from, so that heading is omitted rather than left empty.
   166	
   167	## Litmus tests
   168	
   169	- **A real `git worktree add` fixture is the only evidence that counts.** GH-448's own test makes
   170	  this argument for the sibling defect; the same reasoning applies here — a path-string assertion
   171	  with no real linked worktree cannot exercise git's actual `--git-common-dir` behavior.
   172	- **Negative control per #419**: replaying the pre-fix 2-branch logic against the same fixture must
   173	  be shown, in the test itself, to land somewhere the marathon-side lock is *not* — before the fixed
   174	  logic is shown to agree. A fix that skips this is not evidence, the same standard #358 and #448
   175	  were both held to.
   176	- **Bash/Python parity, not just each twin's individual correctness against marathon-drive.** The two
   177	  `relay-drive` implementations must agree with each other, not merely each happen to agree with the
   178	  marathon side independently — GH-448's own parity test (Section A) is the direct precedent.
   179	- **A green `validate.sh` proves nothing here.** Nothing in the existing suite stands up two
   180	  concurrent top-level drivers from two linked worktrees of the same repo; a passing suite is
   181	  consistent with the defect being completely untouched.
   182	- **Check the fix against the comment, not just the code.** `marathon-drive.sh:195-196` ("Same lock
   183	  NAME as relay-drive so a marathon and a relay driver still mutually exclude in one clone") is
   184	  currently false from a linked worktree. After a real fix, a reviewer should be able to construct
   185	  the worktree, run both drivers, and find the comment now true — not merely find that the diff
   186	  "looks right."
   187	
   188	## Reversibility & blast radius
   189	
   190	**Major, atypically for a change the issue itself calls "small and symmetrical" — because of what
   191	this write-set touches, not what it changes.** `relay-automation/relay-drive.sh` and
   192	`utils/py/relay_drive.py` are not an inert path-resolution helper: `marathon-drive.sh:27-28` states
   193	outright that it "calls relay-drive.sh unmodified... Does NOT reimplement any loop logic —
   194	relay-drive.sh IS the loop," and both `marathon-drive.sh:82` and `utils/py/marathon_drive.py:474`
   195	invoke exactly this file as the per-phase-turn subprocess by default. A marathon builder turn that
   196	edited it would have the very **next** phase-turn subprocess exec — a fresh process launch from disk,
   197	not a sourced-and-cached kernel function — run the changed script. That is at least as sharp a
   198	self-modification hazard as the `relay-turn-lib.sh`/`rtl.py` case the drafting brief calls out by
   199	name, even though `relay-drive.sh` is not itself on that named list. **This must ship as a direct PR
   200	against `development`; it cannot be fired as a marathon lane or a relay lane.**
   201	
   202	Both target files are GH-308 frozen twins (`test/gh308-frozen-twin-guard.sh:21`, TWINS entry #8);
   203	Python (`relay_drive.py`) is authoritative, and any behavior-changing edit to the Bash side
   204	(`relay-drive.sh`) needs a `Frozen-twin-exception:` trailer naming the file.
   205	
   206	**What breaks if this goes wrong:** getting the resolved path wrong in a *new* way could make two
   207	separate drivers silently agree on a lock path neither correctly protects — worse than today's status
   208	quo, where at least the marathon side resolves correctly. Getting it right changes only path
   209	resolution, not acquisition, reclaim, or release semantics (mirroring #448's own explicit non-goal on
   210	this exact code area), so the change is narrow by construction.
   211	
   212	**How hard to undo:** trivial. Revert the one commit. The lock itself is a transient `mkdir`
   213	directory, never committed to git, and self-heals via the existing stale-holder reclaim logic
   214	(`relay-drive.sh:152-164` / `relay_drive.py:394+`) regardless of which path-resolution version is
   215	live.
   216	
   217	## Swarm Preflight Contract
   218	
   219	**Not fireable as a marathon lane** — recorded here in the exemplar's shape for completeness and
   220	because it documents what a direct-PR reviewer should check, not because `swarm-preflight` should
   221	ever dispatch it.
   222	
   223	```json
   224	{
   225	  "target":        { "repo": ".", "ref": "development" },
   226	  "gate":          "bash validate.sh",
   227	  "fix_probes":    [
   228	    { "type": "grep_absent", "path": "relay-automation/relay-drive.sh", "pattern": "git-common-dir" },
   229	    { "type": "grep_absent", "path": "utils/py/relay_drive.py", "pattern": "driver_lock_path" }
   230	  ],
   231	  "artifacts":     ["relay-automation/relay-drive.sh", "utils/py/relay_drive.py", "test/gh376-relay-drive-lock-parity.sh"],
   232	  "artifacts_new": ["test/gh376-relay-drive-lock-parity.sh"],
   233	  "remediation":   { "source": "issue #376", "criteria": "make relay-drive's Bash and Python lock-path resolution agree with marathon-drive's from a linked worktree — ranking summary only, NOT the definition of done (that is the verbatim Acceptance criteria section above). NEVER dispatch this as a marathon or relay lane: relay-drive.sh is the marathon driver's own per-turn-loop subprocess (marathon-drive.sh:27-28), so this write-set is self-modifying in substance. Ship as a direct PR." },
   234	  "lanes": { "agy_safe": [], "orchestrator_only": ["relay-automation/relay-drive.sh", "utils/py/relay_drive.py"] }
   235	}
   236	```
   237	
   238	**Probe polarity** (probes detect the **bug**, not the fix): both are `grep_absent`, so each reports
   239	`landed` only once its marker string *appears*. `git-common-dir` is 0 matches in
   240	`relay-automation/relay-drive.sh` today (confirmed) — chosen because `marathon-drive.sh`'s own
   241	(already-correct, frozen) Bash side resolves the worktree branch inline with exactly that git flag
   242	rather than sourcing `driver-lock-lib.sh`, and `#448` left that inline-vs-shared choice alone for the
   243	Bash frozen twin; the parallel, precedent-consistent fix for `relay-drive.sh` is the same inline
   244	3-branch copy, not a new sourcing dependency. `driver_lock_path` is 0 matches in
   245	`utils/py/relay_drive.py` today (confirmed) — chosen because `utils/py/marathon_drive.py` already
   246	imports that exact shared function (`marathon_drive.py:20`) rather than duplicating the branches in
   247	Python, and the parallel, precedent-consistent fix for `relay_drive.py` is to do the same. If an
   248	implementation takes a different concrete shape than either precedent, these two specific probes may
   249	need updating before firing — the acceptance criteria above are the actual definition of done, not
   250	these markers.
   251	
   252	## Provenance
   253	
   254	Surfaced by the `#354` code review (`5660aae`, "3 of 5 collision claims overturned"), which did not
   255	carry its own issue; filed as `#376`. Captured 2026-08-10 as part of Nightwatch batch 2. Every
   256	locking claim in the issue body was independently re-verified against `development` at the current
   257	tree before this doc was written; none were found stale. Two additional findings not present in the
   258	issue — the already-shipped `#448` shared resolver, and the self-modification hazard in the write-set
   259	— were found during that verification and are recorded above.
   260	
     1	---
     2	gh_issue: 448
     3	source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/448
     4	title: "Every driver-lock CONSUMER resolves the path with 2 branches while the drivers use 3, so from a linked worktree the monitors report a LIVE marathon as IDLE"
     5	status: "3-COMPLETED — shipped in PR #449 (merged `000aa6ce`), issue #448 closed. Sibling #376 remains open and out of scope."
     6	created: 2026-08-08
     7	updated: 2026-08-08
     8	owner: noel
     9	doc_type: bugfix
    10	complexity: 3
    11	risk: 2
    12	effort: 3
    13	phases: 1
    14	ratings_provisional: false
    15	non_goals:
    16	  - Not touching relay-drive.sh / relay_drive.py — the driver-side 2-branch defect there is the
    17	    sibling issue #376's scope, not this one's.
    18	  - Not editing relay-automation/marathon-drive.sh (GH-308 FROZEN twin) — it is already correct
    19	    (3-branch); left byte-unchanged per the issue's own acceptance criterion, no
    20	    Frozen-twin-exception needed since no behavior change is required there.
    21	  - Not changing lock ACQUISITION/reclaim semantics anywhere — this is a read-only path-resolution
    22	    fix for consumers, not a change to how or when the driver takes or releases the lock.
    23	related:
    24	  - utils/py/rtl.py
    25	  - utils/py/marathon_drive.py
    26	  - relay-automation/driver-lock-lib.sh
    27	  - relay-automation/marathon-ls.sh
    28	  - utils/hq/marathon-live.sh
    29	  - skills/relay-xyz/find-harness.sh
    30	  - test/gh448-driver-lock-resolver.sh
    31	  - PROJECT/1-INBOX/GH-354-CONCURRENT-SWARMS.md
    32	goal: >
    33	  One shared driver-lock-path resolver (a Bash lib + a Python function, agreeing byte-for-byte),
    34	  used by every read-only consumer of the lock, so a linked worktree's held lock is observed as
    35	  LIVE/driving/blocking instead of silently misread as IDLE/not-driving/no-warning.
    36	roadmap_exempt: false
    37	---
    38	
    39	# GH-448 · Driver-lock resolver: one shared path, not five inline guesses
    40	
    41	**Why:** `marathon-drive` (both the frozen `.sh` and the authoritative `utils/py/marathon_drive.py`)
    42	correctly resolves its lock with 3 branches — `.git` dir (normal clone), `.git` file (linked
    43	worktree → the git **common dir**), or absent (vendored `.xyz/`). Every read-only consumer of that
    44	lock had drifted to a 2-branch guess that only handles "dir" vs "everything else," so from a linked
    45	worktree it probes a path the driver never writes. The consumer doesn't report "couldn't tell" — it
    46	reports the *positive, reassuring* wrong answer: `marathon-ls.sh` says `IDLE`, `utils/hq/marathon-
    47	live.sh` says "claimed, not driving", `skills/relay-xyz/find-harness.sh --check` says nothing at all.
    48	Found live during the Litmus wave-2 marathon (2026-08-08), running from a linked worktree.
    49	
    50	**Audit (from the issue):** 7 sites construct this path; 5 use the wrong 2-branch version.
    51	`relay-drive.sh`/`relay_drive.py` are tracked separately by sibling issue **#376** (the driver-side
    52	half of the same defect class). This doc's scope is the other three: `marathon-ls.sh`,
    53	`utils/hq/marathon-live.sh`, `skills/relay-xyz/find-harness.sh`.
    54	
    55	## Status
    56	
    57	| What was just completed | What's next |
    58	|---|---|
    59	| Implemented + tested in one pass 2026-08-08: shared resolver (`utils/py/rtl.py::driver_lock_path` + new `relay-automation/driver-lock-lib.sh`, byte-for-byte parity asserted by test); `marathon_drive.py` refactored to call it (no behavior change, confirmed by `test/driver-lock.sh` still 4/4); the three broken consumers (`marathon-ls.sh`, `utils/hq/marathon-live.sh`, `find-harness.sh`) now call the shared resolver instead of guessing inline. New `test/gh448-driver-lock-resolver.sh` (17/17): bash/python parity across all 3 branches, a negative control replaying the OLD 2-branch logic against a REAL `git worktree add` fixture (observed missing the lock), and an end-to-end run of the three real, fixed scripts against that same fixture (observed LIVE / 🟢 live / held-lock warning). Existing regression suites (`marathon-monitor.sh`, `hq-marathon-live.sh`, `find-harness.sh`, `driver-lock.sh`) still green. | Open the PR into `development`. Sibling **#376** (driver-side `relay-drive.sh`/`relay_drive.py` 2-branch fix) is out of this doc's scope and stays a separate follow-up. |
    60	
    61	## Acceptance (transcribed from #448)
    62	
    63	- [x] A single shared resolver produces the driver-lock path; the in-scope consumers (marathon-ls.sh,
    64	      marathon-live.sh, find-harness.sh) call it instead of constructing the path inline.
    65	      `marathon-drive.sh` (frozen) is unchanged since it was already correct; `relay-drive.sh`/
    66	      `relay_drive.py` are explicitly #376's scope, not re-litigated here.
    67	- [x] The shell and Python resolvers agree on all inputs asserted by a test (`.git` dir, `.git` file
    68	      via a REAL `git worktree add`, absent/vendored) — `test/gh448-driver-lock-resolver.sh` section A.
    69	- [x] From a **linked worktree** with a driver holding the lock: `marathon-ls` reports `LIVE`,
    70	      `marathon-live` reports 🟢 live, and `find-harness.sh --check` prints its held-lock warning
    71	      naming the real (common-dir) path — all three **observed** against real fixed scripts + a real
    72	      `git worktree add`, not inferred — section C.
    73	- [x] The negative control is observed and recorded per #419: section B replays each site's ORIGINAL
    74	      2-branch logic verbatim against the identical worktree fixture and shows it misses the held
    75	      lock, before section C shows the fixed logic finding it — both revisions, same fixture, written
    76	      into the test itself (not just asserted in prose here).
    77	- [x] `relay-automation/marathon-drive.sh` is a GH-308 frozen twin — left byte-unchanged (no
    78	      `Frozen-twin-exception:` needed, since it required no behavior change).
    79	- [~] "A consumer that genuinely cannot determine the lock state reports that, distinctly from IDLE":
    80	      not implemented as a new formal state. The shared resolver mirrors the driver's OWN fallback
    81	      behavior exactly (on a `git rev-parse --git-common-dir` failure it falls back to
    82	      `<repo>/.relay-driver.lock`, same as the driver would), so a consumer now sees exactly what the
    83	      driver would resolve to in every case the driver itself handles — there is no case left where
    84	      the consumer "can't tell" that the driver itself could. Scoped out as disproportionate net-new
    85	      state-machine surface for a resolution path the driver never treats as unknown either.
    86	
    87	## Reconciled: the `.xyz/` 4th case
    88	
    89	`utils/hq/marathon-live.sh` checked `<repo>/.xyz/.relay-driver.lock` for the vendored case — a path
    90	the driver **never writes** (the driver's vendored fallback is `<repo>/.relay-driver.lock`, same
    91	hidden-file-at-root shape as the clone case, just without `.git/`). Reconciled by deletion: the
    92	shared resolver has no `.xyz/`-scoped branch, and `marathon-live.sh` now agrees with the driver.
relay-automation/marathon-drive.sh-186-  printf '\nmarathon-drive: end-of-run cost summary (tick analyze) —\n%s\n' "$block" >&2
relay-automation/marathon-drive.sh-187-}
relay-automation/marathon-drive.sh-188-
relay-automation/marathon-drive.sh:189:if [[ "${RELAY_DRIVER_LOCKED:-0}" != "1" ]]; then
relay-automation/marathon-drive.sh-190-  # GH-49b: the lock lives in .git/ (never committed) for a normal clone; a vendored .xyz/ copy has no
relay-automation/marathon-drive.sh-191-  # .git/. In a linked worktree, .git is a file pointing at the shared gitdir, so resolve the real
relay-automation/marathon-drive.sh-192-  # common dir and place the lock there; otherwise --require-clean sees the driver's own bookkeeping as
--
relay-automation/marathon-drive.sh-195-  # the same). Same lock NAME as relay-drive so a marathon and a relay driver still mutually exclude in
relay-automation/marathon-drive.sh-196-  # one clone.
relay-automation/marathon-drive.sh-197-  if [[ -d "$ROOT/.git" ]]; then
relay-automation/marathon-drive.sh:198:    _lock="$ROOT/.git/relay-driver.lock"; _lock_label=".git/relay-driver.lock"
relay-automation/marathon-drive.sh-199-  elif [[ -f "$ROOT/.git" ]]; then
relay-automation/marathon-drive.sh-200-    _git_common_dir="$(git -C "$ROOT" rev-parse --git-common-dir 2>/dev/null || true)"
relay-automation/marathon-drive.sh-201-    if [[ -n "$_git_common_dir" ]]; then
relay-automation/marathon-drive.sh:202:      _lock="$_git_common_dir/relay-driver.lock"; _lock_label=".git/relay-driver.lock"
relay-automation/marathon-drive.sh-203-    else
relay-automation/marathon-drive.sh:204:      _lock="$ROOT/.relay-driver.lock";           _lock_label=".relay-driver.lock"
relay-automation/marathon-drive.sh-205-    fi
relay-automation/marathon-drive.sh-206-  else
relay-automation/marathon-drive.sh:207:    _lock="$ROOT/.relay-driver.lock";     _lock_label=".relay-driver.lock"
relay-automation/marathon-drive.sh-208-  fi
relay-automation/marathon-drive.sh-209-  if ! mkdir "$_lock" 2>/dev/null; then
relay-automation/marathon-drive.sh-210-    # GH-42 self-heal: the lock exists — reclaim it only if its holder is dead. A crashed/killed/
--
relay-automation/marathon-drive.sh-215-      printf 'marathon-drive: Concurrent runs in the same clone are unsafe (GH-42 ROOT HEAD hazard).\n' >&2
relay-automation/marathon-drive.sh-216-      exit 1
relay-automation/marathon-drive.sh-217-    fi
relay-automation/marathon-drive.sh:218:    printf 'marathon-drive: reclaiming stale relay-driver.lock (holder pid %s not running).\n' "${_holder:-none}" >&2
relay-automation/marathon-drive.sh-219-    # Sentinel Tier 1 (GH-281): the append helper isn't defined this early — inline a gated write.
relay-automation/marathon-drive.sh-220-    if [[ "${XYZ_DEBUG_LOG:-0}" == "1" ]]; then
relay-automation/marathon-drive.sh-221-      { printf '{"timestamp":"%s","severity":"info","check":"marathon.stale-lock","scope":"harness","repo":"%s","message":"stale driver lock reclaimed","action":"none (auto-healed)"}\n' \
relay-automation/marathon-drive.sh-222-          "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$ROOT" >> "${DEBUG_LOG_FILE:-$ROOT/debug.log}"; } 2>/dev/null || true
relay-automation/marathon-drive.sh-223-    fi
relay-automation/marathon-drive.sh-224-    rm -rf "$_lock"
relay-automation/marathon-drive.sh:225:    mkdir "$_lock" 2>/dev/null || { printf 'marathon-drive: could not acquire relay-driver.lock after reclaiming a stale one.\n' >&2; exit 1; }
relay-automation/marathon-drive.sh-226-    # ponytail: tiny TOCTOU window (two drivers could both reclaim a stale lock); acceptable for a
relay-automation/marathon-drive.sh-227-    # single-operator clone — add an atomic PID-CAS only if true multi-operator concurrency appears.
relay-automation/marathon-drive.sh-228-  fi
--
relay-automation/marathon-drive.sh-242-    exit "$_code"
relay-automation/marathon-drive.sh-243-  }
relay-automation/marathon-drive.sh-244-  trap _marathon_drive_on_exit EXIT
relay-automation/marathon-drive.sh:245:  export RELAY_DRIVER_LOCKED=1
relay-automation/marathon-drive.sh-246-fi
relay-automation/marathon-drive.sh-247-
relay-automation/marathon-drive.sh-248-die()  { printf 'marathon-drive: %s\n' "$*" >&2; exit 2; }
--
relay-automation/relay-drive.sh-139-  printf '\nrelay-drive: end-of-run cost summary (tick analyze) —\n%s\n' "$block" >&2
relay-automation/relay-drive.sh-140-}
relay-automation/relay-drive.sh-141-
relay-automation/relay-drive.sh:142:if [[ "${RELAY_DRIVER_LOCKED:-0}" != "1" ]]; then
relay-automation/relay-drive.sh-143-  # The driver lock lives in .git/ (never committed) for a normal harness clone. A GH-49 vendored
relay-automation/relay-drive.sh-144-  # .xyz/ copy has no .git/, so mkdir'ing a lock there would fail — fall back to a hidden lock beside
relay-automation/relay-drive.sh-145-  # the scripts (the .xyz/ dir is itself gitignored in the foreign repo, so it stays uncommitted just
--
relay-automation/relay-drive.sh-149-  # .git is a FILE pointing at the shared gitdir — so this driver locked inside the worktree while
relay-automation/relay-drive.sh-150-  # marathon-drive locked in the git COMMON dir, and the mutual exclusion asserted at
relay-automation/relay-drive.sh-151-  # marathon-drive.sh:195-196 silently did not exist. Resolution now goes through GH-448's shared
relay-automation/relay-drive.sh:152:  # driver-lock-lib.sh (Python twin: utils/py/rtl.py::driver_lock_path), so the two drivers agree by
relay-automation/relay-drive.sh-153-  # construction instead of by coincidence.
relay-automation/relay-drive.sh-154-  source "$(dirname "${BASH_SOURCE[0]}")/driver-lock-lib.sh"
relay-automation/relay-drive.sh:155:  _lock="$(driver_lock_path_for_repo "$ROOT_DIR")"
relay-automation/relay-drive.sh-156-  # The label is the SHORT display form used in the messages below, derived from the resolved path
relay-automation/relay-drive.sh:157:  # rather than recomputed: the vendored fallback is the ONLY branch that yields <root>/.relay-driver.lock,
relay-automation/relay-drive.sh-158-  # so this reproduces rtl.py's label mapping exactly without re-testing .git a second time.
relay-automation/relay-drive.sh:159:  if [[ "$_lock" == "$ROOT_DIR/.relay-driver.lock" ]]; then
relay-automation/relay-drive.sh:160:    _lock_label=".relay-driver.lock"
relay-automation/relay-drive.sh-161-  else
relay-automation/relay-drive.sh:162:    _lock_label=".git/relay-driver.lock"
relay-automation/relay-drive.sh-163-  fi
relay-automation/relay-drive.sh-164-  if ! mkdir "$_lock" 2>/dev/null; then
relay-automation/relay-drive.sh-165-    # GH-42 self-heal: reclaim the lock only if its holder is dead. A crashed/killed driver used to
--
relay-automation/relay-drive.sh-170-      printf 'relay-drive: Concurrent runs in the same clone are unsafe (GH-42 ROOT HEAD hazard).\n' >&2
relay-automation/relay-drive.sh-171-      exit 1
relay-automation/relay-drive.sh-172-    fi
relay-automation/relay-drive.sh:173:    printf 'relay-drive: reclaiming stale relay-driver.lock (holder pid %s not running).\n' "${_holder:-none}" >&2
relay-automation/relay-drive.sh-174-    rm -rf "$_lock"
relay-automation/relay-drive.sh:175:    mkdir "$_lock" 2>/dev/null || { printf 'relay-drive: could not acquire relay-driver.lock after reclaiming a stale one.\n' >&2; exit 1; }
relay-automation/relay-drive.sh-176-  fi
relay-automation/relay-drive.sh-177-  printf '%s\n' "$$" > "$_lock/pid"
relay-automation/relay-drive.sh-178-  # GH-152: the cost summary is wired into the SAME exit trap as the lock cleanup (the one place
--
relay-automation/relay-drive.sh-190-    exit "$_code"
relay-automation/relay-drive.sh-191-  }
relay-automation/relay-drive.sh-192-  trap _relay_drive_on_exit EXIT
relay-automation/relay-drive.sh:193:  export RELAY_DRIVER_LOCKED=1
relay-automation/relay-drive.sh-194-fi
relay-automation/relay-drive.sh-195-
relay-automation/relay-drive.sh-196-usage() {
--
utils/py/marathon_drive.py-17-# which does NOT put the script's own directory on sys.path (GH-448 regression, test/gh322-runlog-
utils/py/marathon_drive.py-18-# python-lane.sh caught it). Same pattern as marathon_plan.py's `_marathon_plan` import.
utils/py/marathon_drive.py-19-sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
utils/py/marathon_drive.py:20:from rtl import driver_lock_path  # noqa: E402
utils/py/marathon_drive.py-21-
utils/py/marathon_drive.py-22-# GH-284 Phase 2 / GH-322: hooks run on EVERY terminal path with the driver's real exit code — the
utils/py/marathon_drive.py-23-# Python equivalent of marathon-drive.sh's `trap _marathon_drive_on_exit EXIT`. Same contract as
--
utils/py/marathon_drive.py-677-                    "Read it before re-guessing.\n")
utils/py/marathon_drive.py-678-        return out
utils/py/marathon_drive.py-679-
utils/py/marathon_drive.py:680:    if get_env("RELAY_DRIVER_LOCKED", "0") != "1":
utils/py/marathon_drive.py-681-        # GH-49b/GH-207: the lock lives in .git/ (never committed) for a normal clone. In a linked
utils/py/marathon_drive.py-682-        # worktree .git is a FILE pointing at the shared gitdir, so resolve the real common dir and put
utils/py/marathon_drive.py-683-        # the lock there — otherwise --require-clean sees the driver's own lock as untracked dirt inside
utils/py/marathon_drive.py-684-        # the worktree. A vendored .xyz/ copy (no .git) falls back to a hidden lock beside the scripts.
utils/py/marathon_drive.py-685-        # GH-448: this resolution is the canonical write-side one — every read-only consumer (marathon-
utils/py/marathon_drive.py-686-        # ls.sh, marathon-live.sh, find-harness.sh) must agree with it, so it lives in rtl.py's shared
utils/py/marathon_drive.py:687:        # driver_lock_path (with a byte-for-byte Bash twin in relay-automation/driver-lock-lib.sh)
utils/py/marathon_drive.py-688-        # rather than being reimplemented here.
utils/py/marathon_drive.py:689:        lock_dir, lock_label = driver_lock_path(root)
utils/py/marathon_drive.py-690-
utils/py/marathon_drive.py-691-        try:
utils/py/marathon_drive.py-692-            os.mkdir(lock_dir)
--
utils/py/marathon_drive.py-710-                eprint("marathon-drive: Concurrent runs in the same clone are unsafe (GH-42 ROOT HEAD hazard).")
utils/py/marathon_drive.py-711-                sys.exit(1)
utils/py/marathon_drive.py-712-            
utils/py/marathon_drive.py:713:            eprint(f"marathon-drive: reclaiming stale relay-driver.lock (holder pid {holder or 'none'} not running).")
utils/py/marathon_drive.py-714-            # Sentinel Tier 1 (GH-281/GH-342): record the auto-heal. Emitted BEFORE the reclaim, so
utils/py/marathon_drive.py-715-            # the finding survives even if the rmtree/mkdir below fails and the run exits 1.
utils/py/marathon_drive.py-716-            xyz_debug_log_stale_lock(root)
--
utils/py/marathon_drive.py-718-                shutil.rmtree(lock_dir)
utils/py/marathon_drive.py-719-                os.mkdir(lock_dir)
utils/py/marathon_drive.py-720-            except:
utils/py/marathon_drive.py:721:                eprint("marathon-drive: could not acquire relay-driver.lock after reclaiming a stale one.")
utils/py/marathon_drive.py-722-                sys.exit(1)
utils/py/marathon_drive.py-723-        
utils/py/marathon_drive.py-724-        with open(os.path.join(lock_dir, "pid"), 'w') as f:
utils/py/marathon_drive.py-725-            f.write(str(os.getpid()) + "\n")
utils/py/marathon_drive.py-726-        
utils/py/marathon_drive.py:727:        os.environ["RELAY_DRIVER_LOCKED"] = "1"
utils/py/marathon_drive.py-728-        def cleanup_lock():
utils/py/marathon_drive.py-729-            try: shutil.rmtree(lock_dir)
utils/py/marathon_drive.py-730-            except: pass
--
utils/py/marathon_drive.py-1448-    # classifies EVERY variable the drivers export as scrub-or-pass with a reason, and
utils/py/marathon_drive.py-1449-    # test/gh441-gate-env-contract.sh fails loudly if a new export is added without a classification.
utils/py/marathon_drive.py-1450-    #
utils/py/marathon_drive.py:1451:    # It deliberately does NOT scrub RELAY_DRIVER_LOCKED; see that module's docstring for the measured
utils/py/marathon_drive.py-1452-    # reason (scrubbing it globally was landed and reverted — the nested drivers need it SET and the
utils/py/marathon_drive.py-1453-    # lock assertions need it UNSET, so the fix is per-suite, which shipped as Phase 1).
utils/py/marathon_drive.py-1454-    # GH-441 Phase 2 widened this from three names to every variable the drivers export. The
--
utils/py/marathon_drive.py-1466-    # The two copies cannot drift: test/gh441-gate-env-contract.sh asserts this literal is exactly
utils/py/marathon_drive.py-1467-    # gate_env.SCRUBBED_NAMES, and fails if either side changes alone.
utils/py/marathon_drive.py-1468-    #
utils/py/marathon_drive.py:1469:    # RELAY_DRIVER_LOCKED is deliberately ABSENT — scrubbing it globally was landed and reverted on
utils/py/marathon_drive.py-1470-    # 2026-08-07 (nested drivers need it SET, lock assertions need it UNSET; no global value is
utils/py/marathon_drive.py-1471-    # correct). See gate_env.py's docstring for the measured matrix.
utils/py/marathon_drive.py-1472-    GATE_SCRUBBED_ENV = (
--
utils/py/relay_drive.py-13-# module via importlib.util.spec_from_file_location rather than `python3 <path>`, which does NOT put
utils/py/relay_drive.py-14-# the script's own directory on sys.path. Same pattern, and the same reason, as marathon_drive.py:19.
utils/py/relay_drive.py-15-sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
utils/py/relay_drive.py:16:from rtl import driver_lock_path  # noqa: E402
utils/py/relay_drive.py-17-
utils/py/relay_drive.py-18-def eprint(*args, **kwargs):
utils/py/relay_drive.py-19-    print(*args, file=sys.stderr, **kwargs)
--
utils/py/relay_drive.py-389-        desc = f"Relay session ended: STATUS {s or 'unknown'} (health {health})."
utils/py/relay_drive.py-390-        subprocess.run([xyz_append_bin, "relay", slug, health, title, desc], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
utils/py/relay_drive.py-391-
utils/py/relay_drive.py:392:    if get_env("RELAY_DRIVER_LOCKED", "0") != "1":
utils/py/relay_drive.py:393:        # GH-376: this was a 2-branch guess (.git is a dir -> .git/relay-driver.lock, ELSE a hidden
utils/py/relay_drive.py-394-        # lock beside the scripts) with no case for a linked worktree, where .git is a FILE. That
utils/py/relay_drive.py-395-        # topology is not exotic — it is the one swarm-preflight's own recommended invocation creates
utils/py/relay_drive.py-396-        # via RELAY_WORKTREE_ISOLATION=1. The marathon driver already followed .git to the git COMMON
--
utils/py/relay_drive.py-398-        # believed was the one mutex, invisible to the other. marathon-drive.sh:195-196 asserts in
utils/py/relay_drive.py-399-        # prose that they mutually exclude; this call is what makes that true.
utils/py/relay_drive.py-400-        #
utils/py/relay_drive.py:401:        # driver_lock_path is #448's shared resolver (Bash twin: relay-automation/driver-lock-lib.sh).
utils/py/relay_drive.py-402-        # Reused, never reimplemented — a fourth inline copy is the bug class, not the fix.
utils/py/relay_drive.py:403:        lock_dir, lock_label = driver_lock_path(root_dir)
utils/py/relay_drive.py-404-
utils/py/relay_drive.py-405-
utils/py/relay_drive.py-406-        try:
--
utils/py/relay_drive.py-425-                eprint("relay-drive: Concurrent runs in the same clone are unsafe (GH-42 ROOT HEAD hazard).")
utils/py/relay_drive.py-426-                sys.exit(1)
utils/py/relay_drive.py-427-            
utils/py/relay_drive.py:428:            eprint(f"relay-drive: reclaiming stale relay-driver.lock (holder pid {holder or 'none'} not running).")
utils/py/relay_drive.py-429-            try:
utils/py/relay_drive.py-430-                shutil.rmtree(lock_dir)
utils/py/relay_drive.py-431-                os.mkdir(lock_dir)
utils/py/relay_drive.py-432-            except:
utils/py/relay_drive.py:433:                eprint("relay-drive: could not acquire relay-driver.lock after reclaiming a stale one.")
utils/py/relay_drive.py-434-                sys.exit(1)
utils/py/relay_drive.py-435-        
utils/py/relay_drive.py-436-        with open(os.path.join(lock_dir, "pid"), 'w') as f:
utils/py/relay_drive.py-437-            f.write(str(os.getpid()) + "\n")
utils/py/relay_drive.py-438-        
utils/py/relay_drive.py:439:        os.environ["RELAY_DRIVER_LOCKED"] = "1"
utils/py/relay_drive.py-440-        # GH-331: the cost summary is wired into the SAME atexit as the lock cleanup (the one place
utils/py/relay_drive.py-441-        # every exit path funnels through), mirroring relay-drive.sh's GH-152 EXIT trap. The summary
utils/py/relay_drive.py:442:        # runs FIRST, then the lock is removed. Skipped entirely when nested (RELAY_DRIVER_LOCKED=1):
utils/py/relay_drive.py-443-        # the outer driver owns this exit hook, exactly as the Bash trap is only armed by the lock owner.
utils/py/relay_drive.py-444-        def _relay_drive_on_exit():
utils/py/relay_drive.py-445-            xyz_relay_cost_summary()

2026-08-12T04:35:16.974324Z ERROR codex_models_manager::manager: failed to renew cache TTL: missing field `base_instructions` at line 95 column 5
exec
/bin/zsh -lc "nl -ba test/gh376-relay-drive-lock-parity.sh | sed -n '1,260p'
nl -ba PROJECT/3-COMPLETED/GH-448-DRIVER-LOCK-RESOLVER.md | sed -n '1,150p'
nl -ba PROJECT/2-WORKING/GH-354-CONCURRENT-SWARMS.md | sed -n '300,385p'
rg -n -C 3 \"Phase 2|Phase 3|Phase 4|GO / NO-GO|NO-GO|Phase 1\" PROJECT/2-WORKING/GH-354-CONCURRENT-SWARMS.md" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-69972-gxaghv_u
 succeeded in 0ms:
     1	#!/usr/bin/env bash
     2	# test/gh376-relay-drive-lock-parity.sh — GH-376.
     3	#
     4	# marathon-drive.sh:195-196 asserts, in prose, that a marathon driver and a relay driver "still
     5	# mutually exclude in one clone" because they share one lock NAME. From a normal clone that was true.
     6	# From a LINKED WORKTREE it was false: .git is a FILE, marathon-drive followed it to the git COMMON
     7	# dir, and relay-drive's own inline 2-branch guess (.git is a dir -> .git/…, ELSE a hidden lock beside
     8	# the scripts) had no case for that at all — so it locked inside the worktree instead. Two top-level
     9	# drivers could each hold what they believed was THE mutex, against the same tree, invisible to each
    10	# other. That topology is not exotic: it is the one swarm-preflight's own recommended invocation
    11	# creates via RELAY_WORKTREE_ISOLATION=1.
    12	#
    13	# The fix routes both relay-drive twins through GH-448's shared resolver
    14	# (relay-automation/driver-lock-lib.sh / utils/py/rtl.py::driver_lock_path), which marathon-drive's
    15	# Python half already uses — so the two agree by construction rather than by coincidence.
    16	#
    17	# WHY THE OBSERVABLE IS "DOES IT REFUSE", NOT "WHAT PATH DID IT PRINT":
    18	# the drivers never print their lock path on the happy path, and the EXIT trap removes the lock, so a
    19	# post-hoc filesystem probe cannot see it. Holding the lock at the path MARATHON-DRIVE resolves and
    20	# then running relay-drive is the direct test of the claim the comment makes: if relay-drive resolves
    21	# the same path it must refuse; if it resolves anywhere else it sails past. That refusal IS the
    22	# mutual exclusion, observed end-to-end through the real scripts rather than asserted about a string.
    23	#
    24	# Hermetic: a throwaway harness clone + a REAL `git worktree add`. No network, no agent, no paid turn.
    25	
    26	set -uo pipefail
    27	
    28	# THIS SUITE DRIVES REAL LOCK ACQUISITION, so it must own RELAY_DRIVER_LOCKED rather than inherit it.
    29	# When validate.sh runs as a live marathon's --pre-advance-cmd, marathon_drive.py:649 has already
    30	# exported RELAY_DRIVER_LOCKED=1 so its NESTED relay-drive skips a lock the parent already holds. The
    31	# gate inherits that on purpose: gate_env.py deliberately does NOT scrub it (tried, landed, REVERTED
    32	# 2026-08-07 — its docstring carries the measured 4-suite table showing neither value is right for
    33	# the whole gate). Inherited here, every driver invocation below skips the lock block entirely and
    34	# each "must refuse" assertion silently inverts.
    35	#
    36	# NOT hypothetical: this suite went 12/6 inside the Nightwatch wave-3 gate on 2026-08-11 while
    37	# passing 18/0 standalone, and halted the marathon at phase 1 for a defect that was in this file and
    38	# not in the phase's own work. Setting RELAY_DRIVER_LOCKED=1 and running this file reproduces it
    39	# exactly. (Spell that invocation out rather than abbreviating the filename: test/path-integrity.sh
    40	# reads a path-shaped token in any comment as a real reference and fails the gate on the ellipsis.)
    41	#
    42	# The per-suite clear is the shipped remedy for exactly this (GH-441 Phase 1), and this file is the
    43	# fifth to need it — see test/driver-lock.sh:11, gh284-runlog-heartbeat.sh:12, gh331-cost-summary.sh:24,
    44	# gh342-sentinel-debug-log-python.sh:27. Section F below then re-asserts the inherited=1 behaviour
    45	# deliberately, so what cost a marathon phase is covered rather than merely avoided.
    46	unset RELAY_DRIVER_LOCKED
    47	
    48	HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    49	REPO="$(cd "$HERE/.." && pwd)"
    50	
    51	WORK="$(mktemp -d "${TMPDIR:-/tmp}/gh376.XXXXXX")"
    52	# GH-177: guard BEFORE the physical re-capture and BEFORE the rm -rf trap is armed. A failed mktemp
    53	# leaves $WORK empty, `cd ""` is a no-op, and `pwd -P` would then hand back the repository root
    54	# straight into `rm -rf`. Same shape (and the same `&& exit 1` inside the braces, which the scanner
    55	# requires in the SAME `;`-delimited segment as the `||`) as test/gh448-driver-lock-resolver.sh:37.
    56	[ -n "$WORK" ] && [ -d "$WORK" ] || { echo "  FAIL: mktemp -d produced no usable dir" >&2 && exit 1; }
    57	# Resolve to the PHYSICAL path first: git always reports a physical path from
    58	# `rev-parse --path-format=absolute --git-common-dir`, and on macOS $TMPDIR lives under /var, a
    59	# symlink to /private/var. A $TMPDIR-derived expected string would never equal git's answer.
    60	WORK="$(cd "$WORK" && pwd -P)"
    61	[ -n "$WORK" ] && [ -d "$WORK" ] || { echo "  FAIL: could not resolve \$WORK to a physical path" >&2 && exit 1; }
    62	trap 'rm -rf "$WORK"' EXIT
    63	
    64	PASS=0; FAIL=0
    65	pass() { printf '  PASS: %s\n' "$*"; PASS=$((PASS+1)); }
    66	fail() { printf '  FAIL: %s\n' "$*" >&2; FAIL=$((FAIL+1)); }
    67	
    68	echo "== test: gh376-relay-drive-lock-parity =="
    69	echo "  workdir: $WORK"
    70	
    71	# ── fixtures ─────────────────────────────────────────────────────────────────────────────────────
    72	# A harness clone carrying the REAL scripts. relay-drive resolves its lock from its OWN location
    73	# (ROOT_DIR = dirname(script)/..), not from a target repo, so the thing that must live in a linked
    74	# worktree is the HARNESS itself. Same construction as gh448's section C3.
    75	MAIN="$WORK/harness"
    76	mkdir -p "$MAIN"
    77	cp -R "$REPO/relay-automation" "$REPO/utils" "$REPO/bin" "$MAIN/" 2>/dev/null
    78	git init -q "$MAIN"
    79	git -C "$MAIN" config user.email t@example.com
    80	git -C "$MAIN" config user.name "gh376 test"
    81	git -C "$MAIN" add -A >/dev/null 2>&1
    82	git -C "$MAIN" commit -qm seed >/dev/null 2>&1
    83	WT="$WORK/harness-wt"
    84	git -C "$MAIN" worktree add -q "$WT" -b gh376-wt-branch
    85	
    86	[ -f "$WT/.git" ] \
    87	  && pass "fixture: the linked worktree's .git is a FILE (the branch that had no case)" \
    88	  || fail "fixture setup: expected $WT/.git to be a file"
    89	
    90	# The path MARATHON-DRIVE resolves for this worktree — the git common dir, i.e. the main clone's .git.
    91	COMMON_LOCK="$MAIN/.git/relay-driver.lock"
    92	# The path the PRE-FIX relay-drive resolved instead: a lock local to whichever worktree it ran in.
    93	WORKTREE_LOCAL_LOCK="$WT/.relay-driver.lock"
    94	
    95	RELAY="$WORK/RELAY.md"
    96	printf 'STATUS: In progress\n' > "$RELAY"
    97	
    98	HOLDER=""
    99	hold_lock() {  # <lock-dir> — hold it with a genuinely LIVE pid, or the GH-42 stale-reclaim path
   100	               # fires and the driver takes the lock for a completely different (correct) reason.
   101	  release_lock
   102	  rm -rf "$1"; mkdir -p "$1"
   103	  /bin/sleep 300 & HOLDER=$!
   104	  printf '%s\n' "$HOLDER" > "$1/pid"
   105	}
   106	release_lock() {
   107	  # `wait` after `kill` reaps the job so bash does not print its own "Terminated: 15" job-control
   108	  # line to the terminal — that notice is emitted by the shell, not by the test, and cannot be
   109	  # silenced by redirecting the kill alone.
   110	  [ -n "$HOLDER" ] && { kill "$HOLDER" 2>/dev/null; wait "$HOLDER" 2>/dev/null; }
   111	  HOLDER=""
   112	}
   113	trap 'release_lock; rm -rf "$WORK"' EXIT
   114	
   115	run_driver() {  # <harness-root> <lane: py|sh> — prints the driver's stderr
   116	  local h="$1" lane="$2"
   117	  if [ "$lane" = "py" ]; then
   118	    python3 "$h/utils/py/relay_drive.py" \
   119	      --relay-file "$RELAY" --agent-cmd /bin/true --dry-run 2>&1
   120	  else
   121	    XYZ_PYTHON=0 bash "$h/relay-automation/relay-drive.sh" \
   122	      --relay-file "$RELAY" --agent-cmd /bin/true --dry-run 2>&1
   123	  fi
   124	}
   125	refused() { printf '%s' "$1" | grep -q 'another driver is active in this repo'; }
   126	
   127	# ═══════════════════════════════════════════════════════════════════════════════════════════════
   128	# A. THE PIN — from a linked worktree, both twins now see the lock marathon-drive holds
   129	# ═══════════════════════════════════════════════════════════════════════════════════════════════
   130	echo "-- A. linked worktree: relay-drive excludes against the marathon-side lock --"
   131	
   132	hold_lock "$COMMON_LOCK"
   133	
   134	py_out="$(run_driver "$WT" py)"
   135	refused "$py_out" \
   136	  && pass "THE PIN (python): relay_drive.py refuses — it resolved the git COMMON dir, like marathon-drive" \
   137	  || fail "THE PIN FAILED (python): did not see the held lock; got: $(printf '%s' "$py_out" | head -1)"
   138	
   139	sh_out="$(run_driver "$WT" sh)"
   140	refused "$sh_out" \
   141	  && pass "THE PIN (bash): relay-drive.sh refuses — the frozen twin agrees with the Python half" \
   142	  || fail "THE PIN FAILED (bash): did not see the held lock; got: $(printf '%s' "$sh_out" | head -1)"
   143	
   144	# Equality ALONE is not enough, and the wave-3 gate proved it: when both lanes skipped the lock they
   145	# emitted the same NON-refusal and this assertion passed green while the two pins beside it failed.
   146	# Requiring that the matched line is a refusal is what makes parity mean something.
   147	if refused "$py_out" && refused "$sh_out" \
   148	   && [ "$(printf '%s' "$py_out" | head -1)" = "$(printf '%s' "$sh_out" | head -1)" ]; then
   149	  pass "twin parity: both lanes emit a byte-identical REFUSAL (same path, same label, same pid)"
   150	else
   151	  fail "twin parity: py='$(printf '%s' "$py_out" | head -1)' sh='$(printf '%s' "$sh_out" | head -1)'"
   152	fi
   153	
   154	[ ! -e "$WORKTREE_LOCAL_LOCK" ] \
   155	  && pass "neither lane left a worktree-local lock behind at \$WT/.relay-driver.lock" \
   156	  || fail "a lane created $WORKTREE_LOCAL_LOCK — it is still resolving inside the worktree"
   157	
   158	release_lock
   159	
   160	# ═══════════════════════════════════════════════════════════════════════════════════════════════
   161	# B. NEGATIVE CONTROL (per #419) — the pre-fix logic, replayed against the SAME fixture
   162	#
   163	# Replaying the OLD resolution must be shown to sail straight past the held lock, or section A is
   164	# only evidence that a lock can be held at all. The Python replay restores the removed 2-branch block
   165	# verbatim. The Bash replay swaps the sourced resolver for one carrying the old body — behaviourally
   166	# identical to the inline block relay-drive.sh used to own, at the same call site.
   167	# ═══════════════════════════════════════════════════════════════════════════════════════════════
   168	echo "-- B. negative control: pre-fix resolution does NOT exclude --"
   169	
   170	PRE="$WORK/harness-prefix-wt"
   171	cp -R "$WT/" "$PRE/" 2>/dev/null
   172	
   173	python3 - "$PRE/utils/py/relay_drive.py" <<'PY'
   174	import sys
   175	p = sys.argv[1]
   176	s = open(p).read()
   177	old = ('        if os.path.isdir(os.path.join(root_dir, ".git")):\n'
   178	       '            lock_dir = os.path.join(root_dir, ".git", "relay-driver.lock")\n'
   179	       '            lock_label = ".git/relay-driver.lock"\n'
   180	       '        else:\n'
   181	       '            lock_dir = os.path.join(root_dir, ".relay-driver.lock")\n'
   182	       '            lock_label = ".relay-driver.lock"\n')
   183	new = "        lock_dir, lock_label = driver_lock_path(root_dir)\n"
   184	if new not in s:
   185	    sys.exit("gh376 replay: the post-fix call site was not found — this control is vacuous")
   186	open(p, "w").write(s.replace(new, old, 1))
   187	PY
   188	[ $? -eq 0 ] || fail "negative control: could not build the python pre-fix replay"
   189	
   190	cat > "$PRE/relay-automation/driver-lock-lib.sh" <<'EOF'
   191	#!/usr/bin/env bash
   192	set -u
   193	driver_lock_path_for_repo() {
   194	  local repo="$1"
   195	  if [ -d "$repo/.git" ]; then printf '%s/.git/relay-driver.lock' "$repo"
   196	  else printf '%s/.relay-driver.lock' "$repo"; fi
   197	}
   198	EOF
   199	
   200	# The replay runs against the ORIGINAL worktree's common dir: $PRE is a copy of the worktree, so its
   201	# own .git file still points at $MAIN. Hold the same lock the real drivers just honoured.
   202	hold_lock "$COMMON_LOCK"
   203	
   204	pre_py="$(run_driver "$PRE" py)"
   205	refused "$pre_py" \
   206	  && fail "negative control (python) is VACUOUS: the pre-fix logic also refused — the fixture is not exercising the worktree branch" \
   207	  || pass "negative control (python): pre-fix 2-branch logic sails past the held lock — the defect, reproduced"
   208	
   209	pre_sh="$(run_driver "$PRE" sh)"
   210	refused "$pre_sh" \
   211	  && fail "negative control (bash) is VACUOUS: the pre-fix logic also refused" \
   212	  || pass "negative control (bash): pre-fix 2-branch logic sails past the held lock"
   213	
   214	release_lock
   215	
   216	# ═══════════════════════════════════════════════════════════════════════════════════════════════
   217	# C. CONTROL — a normal clone must behave EXACTLY as before
   218	#
   219	# The fix is worthless if it bought the worktree case at the cost of the common one. Run from $MAIN,
   220	# where .git is a directory: the resolved path is unchanged, so exclusion must still hold.
   221	# ═══════════════════════════════════════════════════════════════════════════════════════════════
   222	echo "-- C. control: a normal clone (.git is a directory) is unchanged --"
   223	
   224	hold_lock "$COMMON_LOCK"
   225	
   226	refused "$(run_driver "$MAIN" py)" \
   227	  && pass "CONTROL (python): a normal clone still excludes at .git/relay-driver.lock" \
   228	  || fail "CONTROL (python): the fix broke the ordinary single-clone case"
   229	refused "$(run_driver "$MAIN" sh)" \
   230	  && pass "CONTROL (bash): a normal clone still excludes at .git/relay-driver.lock" \
   231	  || fail "CONTROL (bash): the fix broke the ordinary single-clone case"
   232	
   233	release_lock
   234	
   235	# ═══════════════════════════════════════════════════════════════════════════════════════════════
   236	# D. CONTROL — a vendored .xyz/ copy (no .git anywhere) still falls back beside the scripts
   237	# ═══════════════════════════════════════════════════════════════════════════════════════════════
   238	echo "-- D. control: a vendored copy with no .git falls back to .relay-driver.lock --"
   239	
   240	VEND="$WORK/vendored"
   241	mkdir -p "$VEND"
   242	cp -R "$MAIN/relay-automation" "$MAIN/utils" "$MAIN/bin" "$VEND/" 2>/dev/null
   243	rm -rf "$VEND/.git"
   244	
   245	hold_lock "$VEND/.relay-driver.lock"
   246	
   247	vend_py="$(run_driver "$VEND" py)"
   248	refused "$vend_py" && printf '%s' "$vend_py" | grep -q '\.relay-driver\.lock' \
   249	  && pass "CONTROL (python): vendored copy resolves the hidden lock beside the scripts" \
   250	  || fail "CONTROL (python): vendored fallback changed; got: $(printf '%s' "$vend_py" | head -1)"
   251	vend_sh="$(run_driver "$VEND" sh)"
   252	refused "$vend_sh" && printf '%s' "$vend_sh" | grep -q '\.relay-driver\.lock' \
   253	  && pass "CONTROL (bash): vendored copy resolves the hidden lock beside the scripts" \
   254	  || fail "CONTROL (bash): vendored fallback changed; got: $(printf '%s' "$vend_sh" | head -1)"
   255	
   256	release_lock
   257	
   258	# ═══════════════════════════════════════════════════════════════════════════════════════════════
   259	# E. SOURCE GUARDS — the resolver is REUSED, not reimplemented
   260	#
     1	---
     2	gh_issue: 448
     3	source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/448
     4	title: "Every driver-lock CONSUMER resolves the path with 2 branches while the drivers use 3, so from a linked worktree the monitors report a LIVE marathon as IDLE"
     5	status: "3-COMPLETED — shipped in PR #449 (merged `000aa6ce`), issue #448 closed. Sibling #376 remains open and out of scope."
     6	created: 2026-08-08
     7	updated: 2026-08-08
     8	owner: noel
     9	doc_type: bugfix
    10	complexity: 3
    11	risk: 2
    12	effort: 3
    13	phases: 1
    14	ratings_provisional: false
    15	non_goals:
    16	  - Not touching relay-drive.sh / relay_drive.py — the driver-side 2-branch defect there is the
    17	    sibling issue #376's scope, not this one's.
    18	  - Not editing relay-automation/marathon-drive.sh (GH-308 FROZEN twin) — it is already correct
    19	    (3-branch); left byte-unchanged per the issue's own acceptance criterion, no
    20	    Frozen-twin-exception needed since no behavior change is required there.
    21	  - Not changing lock ACQUISITION/reclaim semantics anywhere — this is a read-only path-resolution
    22	    fix for consumers, not a change to how or when the driver takes or releases the lock.
    23	related:
    24	  - utils/py/rtl.py
    25	  - utils/py/marathon_drive.py
    26	  - relay-automation/driver-lock-lib.sh
    27	  - relay-automation/marathon-ls.sh
    28	  - utils/hq/marathon-live.sh
    29	  - skills/relay-xyz/find-harness.sh
    30	  - test/gh448-driver-lock-resolver.sh
    31	  - PROJECT/1-INBOX/GH-354-CONCURRENT-SWARMS.md
    32	goal: >
    33	  One shared driver-lock-path resolver (a Bash lib + a Python function, agreeing byte-for-byte),
    34	  used by every read-only consumer of the lock, so a linked worktree's held lock is observed as
    35	  LIVE/driving/blocking instead of silently misread as IDLE/not-driving/no-warning.
    36	roadmap_exempt: false
    37	---
    38	
    39	# GH-448 · Driver-lock resolver: one shared path, not five inline guesses
    40	
    41	**Why:** `marathon-drive` (both the frozen `.sh` and the authoritative `utils/py/marathon_drive.py`)
    42	correctly resolves its lock with 3 branches — `.git` dir (normal clone), `.git` file (linked
    43	worktree → the git **common dir**), or absent (vendored `.xyz/`). Every read-only consumer of that
    44	lock had drifted to a 2-branch guess that only handles "dir" vs "everything else," so from a linked
    45	worktree it probes a path the driver never writes. The consumer doesn't report "couldn't tell" — it
    46	reports the *positive, reassuring* wrong answer: `marathon-ls.sh` says `IDLE`, `utils/hq/marathon-
    47	live.sh` says "claimed, not driving", `skills/relay-xyz/find-harness.sh --check` says nothing at all.
    48	Found live during the Litmus wave-2 marathon (2026-08-08), running from a linked worktree.
    49	
    50	**Audit (from the issue):** 7 sites construct this path; 5 use the wrong 2-branch version.
    51	`relay-drive.sh`/`relay_drive.py` are tracked separately by sibling issue **#376** (the driver-side
    52	half of the same defect class). This doc's scope is the other three: `marathon-ls.sh`,
    53	`utils/hq/marathon-live.sh`, `skills/relay-xyz/find-harness.sh`.
    54	
    55	## Status
    56	
    57	| What was just completed | What's next |
    58	|---|---|
    59	| Implemented + tested in one pass 2026-08-08: shared resolver (`utils/py/rtl.py::driver_lock_path` + new `relay-automation/driver-lock-lib.sh`, byte-for-byte parity asserted by test); `marathon_drive.py` refactored to call it (no behavior change, confirmed by `test/driver-lock.sh` still 4/4); the three broken consumers (`marathon-ls.sh`, `utils/hq/marathon-live.sh`, `find-harness.sh`) now call the shared resolver instead of guessing inline. New `test/gh448-driver-lock-resolver.sh` (17/17): bash/python parity across all 3 branches, a negative control replaying the OLD 2-branch logic against a REAL `git worktree add` fixture (observed missing the lock), and an end-to-end run of the three real, fixed scripts against that same fixture (observed LIVE / 🟢 live / held-lock warning). Existing regression suites (`marathon-monitor.sh`, `hq-marathon-live.sh`, `find-harness.sh`, `driver-lock.sh`) still green. | Open the PR into `development`. Sibling **#376** (driver-side `relay-drive.sh`/`relay_drive.py` 2-branch fix) is out of this doc's scope and stays a separate follow-up. |
    60	
    61	## Acceptance (transcribed from #448)
    62	
    63	- [x] A single shared resolver produces the driver-lock path; the in-scope consumers (marathon-ls.sh,
    64	      marathon-live.sh, find-harness.sh) call it instead of constructing the path inline.
    65	      `marathon-drive.sh` (frozen) is unchanged since it was already correct; `relay-drive.sh`/
    66	      `relay_drive.py` are explicitly #376's scope, not re-litigated here.
    67	- [x] The shell and Python resolvers agree on all inputs asserted by a test (`.git` dir, `.git` file
    68	      via a REAL `git worktree add`, absent/vendored) — `test/gh448-driver-lock-resolver.sh` section A.
    69	- [x] From a **linked worktree** with a driver holding the lock: `marathon-ls` reports `LIVE`,
    70	      `marathon-live` reports 🟢 live, and `find-harness.sh --check` prints its held-lock warning
    71	      naming the real (common-dir) path — all three **observed** against real fixed scripts + a real
    72	      `git worktree add`, not inferred — section C.
    73	- [x] The negative control is observed and recorded per #419: section B replays each site's ORIGINAL
    74	      2-branch logic verbatim against the identical worktree fixture and shows it misses the held
    75	      lock, before section C shows the fixed logic finding it — both revisions, same fixture, written
    76	      into the test itself (not just asserted in prose here).
    77	- [x] `relay-automation/marathon-drive.sh` is a GH-308 frozen twin — left byte-unchanged (no
    78	      `Frozen-twin-exception:` needed, since it required no behavior change).
    79	- [~] "A consumer that genuinely cannot determine the lock state reports that, distinctly from IDLE":
    80	      not implemented as a new formal state. The shared resolver mirrors the driver's OWN fallback
    81	      behavior exactly (on a `git rev-parse --git-common-dir` failure it falls back to
    82	      `<repo>/.relay-driver.lock`, same as the driver would), so a consumer now sees exactly what the
    83	      driver would resolve to in every case the driver itself handles — there is no case left where
    84	      the consumer "can't tell" that the driver itself could. Scoped out as disproportionate net-new
    85	      state-machine surface for a resolution path the driver never treats as unknown either.
    86	
    87	## Reconciled: the `.xyz/` 4th case
    88	
    89	`utils/hq/marathon-live.sh` checked `<repo>/.xyz/.relay-driver.lock` for the vendored case — a path
    90	the driver **never writes** (the driver's vendored fallback is `<repo>/.relay-driver.lock`, same
    91	hidden-file-at-root shape as the clone case, just without `.git/`). Reconciled by deletion: the
    92	shared resolver has no `.xyz/`-scoped branch, and `marathon-live.sh` now agrees with the driver.
   300	---
   301	
   302	## Phase 3 — Write the one true concurrency sentence, and test it
   303	
   304	The reason this issue was asked at all is that no document says what the lock guarantees, and the one
   305	place that tries — `marathon-drive.sh:194-196` — is wrong. Fix the docs *from the tests*, so the
   306	sentence and the behavior cannot drift apart again.
   307	
   308	- State the exclusion matrix (Finding 0.2's table, post-Phase-1: all three pairs exclude per clone)
   309	  in `skills/relay-xyz/SKILL.md`, which is the vendored surface every `.xyz/` install reads — it
   310	  currently describes the lock at `:109` without the worktree shape.
   311	- Correct `marathon-drive.sh:194-196`'s comment and its Python counterpart so "same NAME" is no
   312	  longer offered as the reason two drivers exclude; the reason is the resolved path.
   313	- Record the recommended shape for actually running two swarms — **separate full clones**, per #354's
   314	  quick win, which Phase 0 endorses — plus the cheap per-run hygiene that makes the event stream
   315	  readable even across clones: distinct `--phase-id` / `--relay-task` (`marathon-drive.sh:655-656`),
   316	  `MARATHON_LANE_NS` (`marathon-drive.sh:761` — the lane override already exists, confirming #354's
   317	  quick win #2) and `XYZ_SESSION_ID`, whose fallback to `PHASE_ID`
   318	  (`marathon-drive.sh:436`, `marathon_drive.py:366`) the code's own comment calls useless for telling
   319	  one run from another.
   320	- Correct the record on #354 itself: post a comment noting which claims Phase 0 overturned, so the
   321	  issue thread does not remain the fleet's reference for a wrong collision list.
   322	
   323	### Phase 3 QA gate
   324	
   325	- The exclusion matrix appears in exactly **one** canonical place, with the others linking to it
   326	  (PDDA Principle #4 — one canonical place per fact); no second copy of the matrix in a driver
   327	  comment.
   328	- Every row of the documented matrix is backed by a named assertion from Phase 1/2's tests, cited by
   329	  test name in the doc.
   330	- `relay-drive.sh`'s own header documents its lock shapes to the same standard as
   331	  `marathon-drive.sh:190-196`.
   332	- `utils/pdda/pdda.sh run` clean; `#354` updated.
   333	
   334	---
   335	
   336	## Phase 4 — Decision gate: is opt-in per-worktree parallelism worth building?
   337	
   338	A gate, not an implementation phase. It ends in a written GO / NO-GO in this doc, and a NO-GO is a
   339	perfectly good outcome — Phase 0 already shows the operator's real need is met by separate clones,
   340	which cost a `git clone` and need no code.
   341	
   342	GO requires all four, and each is a real risk of coming back negative:
   343	
   344	1. **The `ROOT@HEAD` hazard is written down.** Finding 0.4: nothing in the tree explains the
   345	   mechanism. Until someone can state what breaks, `XYZ_LOCK_SCOPE=worktree` would relax a guard
   346	   whose purpose is unknown — the definition of a one-way door taken blind.
   347	2. **The add-vs-prune race is resolved.** Reproduce it against a shared `<common>/rtl-worktrees` root
   348	   (`relay-turn-lib.sh:552-556`) or dismiss it with reasoning. A hypothesis cannot gate a design and
   349	   must not be quietly dropped either.
   350	3. **Shared-ref collision has an answer.** Linked worktrees have separate HEAD and index but share
   351	   refs; two drivers committing to the same branch is not a lock problem and the lock cannot fix it.
   352	   If the answer is "each swarm owns a distinct branch," that is a contract to state and enforce, not
   353	   an assumption.
   354	4. **A real operator demand exists that separate clones do not meet.** Named, with the reason clones
   355	   were insufficient. Absent that, NO-GO on cost alone.
   356	
   357	On GO, the shape is #354's own: an opt-in `XYZ_LOCK_SCOPE=worktree` keeping the lock in `$ROOT`,
   358	default off, mirrored across all four driver files, its own issue, and its own plan doc. Not this one
   359	— by then this doc's job is done.
   360	
   361	### Phase 4 QA gate
   362	
   363	- A GO/NO-GO decision is written **into this doc** with its reasoning, and each of the four criteria
   364	  is answered explicitly (an unanswered criterion is a NO-GO, not a deferral).
   365	- On NO-GO: `#354` is closed with the separate-clones recommendation and a pointer to the Phase 3
   366	  matrix; this doc moves to `PROJECT/3-COMPLETED/` and its `ROADMAP.md` pointer is updated.
   367	- On GO: a new issue + `PROJECT/1-INBOX/GH-<n>-*.md` capture exists and is parked in `ROADMAP.md`
   368	  per the issue-first SOP; no implementation begins under this doc.
   369	- The `PROJECT/DO-NOT-BUILD.md` and `PROJECT/CONSTITUTION.md` reversibility stance is checked against
   370	  the decision before it is recorded.
   371	
   372	---
   373	
   374	## Reversibility read
   375	
   376	- **Phases 1–2 — Easy.** Both are additive branches in path-resolution functions; the plain-clone and
   377	  vendored shapes keep byte-identical paths, and each phase's gate pins that. Revert is a one-commit
   378	  `git revert`. The one live-state caveat: a driver started before the fix holds its lock at the old
   379	  path, so a mid-flight upgrade can leave a stale lock at the pre-fix location — the GH-42 self-heal
   380	  reclaims it only when the holder is dead, which is the correct behavior, and it is worth naming in
   381	  Phase 3's docs rather than discovering in the field.
   382	- **Phase 3 — Easy.** Docs and comments.
   383	- **Phase 4 — one-way door, which is why it is a gate.** Relaxing lock scope changes the containment
   384	  contract every consumer and every vendored `.xyz/` install inherits; `risk: 3` on this doc covers
   385	  Phases 1–3, and a GO would carry its own higher rating in its own doc.
1----
2-title: Concurrent swarms — make the driver-lock scope true, provable, and observable before selling parallelism
3:status: "Active (2-WORKING) — opened 2026-07-30. Phase 0 discovery COMPLETE (findings below, verified against `development` at `b93fd93`). Phase 0 overturns three of issue #354's five collision claims and promotes its single observability footnote to the plan's highest-severity finding. Phase 1 is next and is a correctness fix, not a feature."
4-created: 2026-07-30
5-updated: 2026-07-30
6-owner: noel
--
14-branch: claude/pdda-compliance-plan-e4mua0
15-non_goals:
16-  - Shipping per-worktree concurrent swarms. This plan does NOT enable parallelism.
17:    Phases 1–3 make the current exclusion contract true and observable; Phase 4 only
18-    decides whether opt-in per-worktree parallelism is worth building, and needs its
19-    own issue + GO if the answer is yes.
20-  - Removing or weakening the GH-42 `ROOT@HEAD` guard. The guard stays until
--
24-  - Reviving the Bash twins as an authored surface. GH-308 froze them; this plan
25-    patches them only where a fix must land on both lanes to be real.
26-  - Any change to `xyz-vendor.sh`'s preserve list. `.relay-driver.lock` is already
27:    preserved (`relay-automation/xyz-vendor.sh:300`); Phase 1 changes where the lock
28-    lives in a linked worktree, not what vendoring keeps.
29-related:
30-  - "#354 — the originating analysis this plan reviews and corrects."
--
34-    message claims."
35-  - "#49 / GH-49b — the vendored-`.xyz/` and linked-worktree lock-path resolution
36-    that `marathon-drive` has and `relay-drive` never received."
37:  - "#308 — Bash-twin freeze + behavior audit. Every Phase 1/2 fix has to land on
38-    the Python twin (the default lane since GH-264) AND its frozen Bash sibling, or
39-    it silently does not run; this is the exact failure class #308 catalogued."
40-  - "#272 — `TICK_REPO_ROOT` vendored mismatch. Adjacent, deliberately NOT merged in:
--
72-
73-| What was just completed | What's next |
74-|---|---|
75:| **2026-07-30: Phase 0 discovery complete.** Reviewed the actual lock, lane-namespace, session-identity and monitor surfaces on `development` at `b93fd93` — including `relay-drive.sh` and `relay-turn-lib.sh`, which #354 flagged as unavailable and therefore reasoned about from `marathon-drive.sh`'s comments. Both are present and the comments are wrong. **Confirmed:** the marathon↔marathon exclusion, `MARATHON_LANE_NS` existing as the lane override, the `XYZ_SESSION_ID` → `PHASE_ID` fallback, and the monitor's false-IDLE. **Overturned:** (a) marathon↔relay and relay↔relay do **not** mutually exclude in a linked worktree — `relay-drive` never received GH-49b's worktree branch, on either runtime, so it takes a per-worktree lock while `marathon-drive` takes a shared one; (b) `.tick/` task ids, lane attempt counters and `tick analyze` cost do **not** commingle across linked worktrees, because `TICK_REPO_ROOT` defaults to each shim's own `ROOT`; (c) the `git worktree add/prune` exposure is the shared `worktrees/` admin registry and an add-vs-prune race, not `ROOT@HEAD` — `--detach … HEAD` resolves per-worktree. **Escalated:** the false-IDLE bug also exists in `utils/hq/marathon-live.sh` and `utils/hq/hourly-global-scan.sh`. Findings, with `file:line`, in [Phase 0](#phase-0--discovery-verify-354s-claims-against-the-code-complete). | Phase 1 — mirror GH-49b's worktree lock branch into `relay-drive` on **both** runtimes, with a regression test that fails pre-fix. This is a GH-42 containment fix and should not wait on the rest of the plan. |
76-
77-## Table of contents
78-
79-- [Phase 0 — Discovery: verify #354's claims against the code (COMPLETE)](#phase-0--discovery-verify-354s-claims-against-the-code-complete)
80:- [Phase 1 — Close the relay-drive worktree lock gap (correctness)](#phase-1--close-the-relay-drive-worktree-lock-gap-correctness)
81:- [Phase 2 — Make a live worktree run visible to the monitors](#phase-2--make-a-live-worktree-run-visible-to-the-monitors)
82:- [Phase 3 — Write the one true concurrency sentence, and test it](#phase-3--write-the-one-true-concurrency-sentence-and-test-it)
83:- [Phase 4 — Decision gate: is opt-in per-worktree parallelism worth building?](#phase-4--decision-gate-is-opt-in-per-worktree-parallelism-worth-building)
84-
85----
86-
--
136-`.gitignore` (checked — `.gitignore` covers `.tick/` and the GH-75 telemetry trio, not the lock). That
137-is the untracked-bookkeeping problem GH-49b's comment says the worktree branch exists to avoid
138-(`marathon-drive.sh:191-193`). `relay-drive` has no `--require-clean` of its own, so this does not
139:trip a documented gate today — call it a latent dirt source, not a live break, and let Phase 1's test
140-pin it rather than asserting a consequence this pass did not observe.
141-
142-**What it changes:** #354's framing — *"the hard blocker (by design)"* — does not hold, so its
143:conclusion cannot rest on the lock. Phase 1 exists, and is a GH-42 correctness fix that should not
144-be sequenced behind the parallelism question at all.
145-
146-### Finding 0.3 — OVERTURNED: `.tick/` is already per-worktree, so claims 1, 2 and 4 do not fire
--
180-`<common>/worktrees/` admin registry that `add` and `prune` both mutate. One driver's `prune` will
181-not remove a peer's live tree (its directory exists), but `prune` concurrent with a mid-flight `add`
182-is a plausible narrow race on a partially-written entry. This pass did **not** reproduce it — stating
183:it as a hypothesis with a named test, not a finding, is the honest form and Phase 4 owns proving or
184-dismissing it.
185-
186-**What it changes:** #354's *"That's the GH-42 hazard directly"* is too strong. The `ROOT@HEAD`
187-hazard needs a different argument than the throwaway trees, and Phase 0 found **no** written
188-reasoning for it anywhere — `marathon-drive.sh:215` asserts unsafety and cites GH-42; neither the
189-script nor the twin explains the mechanism. #354 already noticed this; it survives Phase 0 intact and
190:is the single biggest blocker to any future parallelism, which is why Phase 4 is a decision gate and
191-not an implementation phase.
192-
193-### Finding 0.5 — CONFIRMED and ESCALATED: three monitors report a LIVE worktree run as IDLE
--
213-- `utils/hq/hourly-global-scan.sh:28` — same `.git/relay-driver.lock` assumption in the hourly
214-  global scan, so the rolling fleet snapshot inherits the same blind spot every hour.
215-
216:**What it changes:** promotes this from a footnote to Phase 2, and it is load-bearing for the rest of
217-the plan. Every exclusion argument here is verified by *observing which lock is held*; if the
218-operator's three windows onto that state are all blind in exactly the shape under discussion, no
219-concurrency claim can be checked in the field. Note the asymmetry that makes this dangerous rather
--
234-
235----
236-
237:## Phase 1 — Close the relay-drive worktree lock gap (correctness)
238-
239-Ship Finding 0.2's fix. Mirror `marathon-drive`'s three-branch resolution into `relay-drive` so the
240-lock name and the lock **path** agree, on both runtimes.
--
249-  weaker containment guard is the same "fake safety gate in the fallback" call already made at
250-  `marathon-drive.sh:685`. Note it in the GH-308 audit doc rather than inventing a new exemption.
251-
252:Deliberately **not** in Phase 1: extracting the resolution into one shared helper. That is the right
253-end state and the wrong first move — a fifth copy is a fifth thing to drift, but a refactor across a
254:frozen twin and a live lane is a bigger blast radius than the bug. Re-raise it after Phase 3's test
255-pins the behavior from both sides.
256-
257:### Phase 1 QA gate
258-
259-- `test/driver-lock.sh` extended (or a sibling added and **registered in `validate.sh`'s explicit
260-  `TESTS=()` array** — GH-292 recorded that an unregistered test silently never runs) covering, in a
--
272-
273----
274-
275:## Phase 2 — Make a live worktree run visible to the monitors
276-
277-Fix Finding 0.5 in all three monitors. Each needs the same `-f .git` → `--git-common-dir` probe added
278-ahead of its existing fallbacks, and each must keep working when `git` is absent or the path is not a
--
283-- `utils/hq/marathon-live.sh:94-95` — add the common-dir probe to the ordered candidate list.
284-- `utils/hq/hourly-global-scan.sh:28` — same, so the hourly snapshot stops inheriting the blind spot.
285-
286:Sequenced **after** Phase 1 on purpose: post-Phase-1 both drivers write predictable per-shape paths,
287-so the monitors are taught one rule rather than being taught to model today's inconsistency.
288-
289:### Phase 2 QA gate
290-
291-- A fixture worktree with a marathon lock held in the common dir renders **LIVE** in
292-  `marathon-ls.sh`, and `marathon-live.sh` answers "really driving: yes" — both assertions failing
--
299-
300----
301-
302:## Phase 3 — Write the one true concurrency sentence, and test it
303-
304-The reason this issue was asked at all is that no document says what the lock guarantees, and the one
305-place that tries — `marathon-drive.sh:194-196` — is wrong. Fix the docs *from the tests*, so the
--
320-- Correct the record on #354 itself: post a comment noting which claims Phase 0 overturned, so the
321-  issue thread does not remain the fleet's reference for a wrong collision list.
322-
323:### Phase 3 QA gate
324-
325-- The exclusion matrix appears in exactly **one** canonical place, with the others linking to it
326-  (PDDA Principle #4 — one canonical place per fact); no second copy of the matrix in a driver
327-  comment.
328:- Every row of the documented matrix is backed by a named assertion from Phase 1/2's tests, cited by
329-  test name in the doc.
330-- `relay-drive.sh`'s own header documents its lock shapes to the same standard as
331-  `marathon-drive.sh:190-196`.
--
333-
334----
335-
336:## Phase 4 — Decision gate: is opt-in per-worktree parallelism worth building?
337-
338:A gate, not an implementation phase. It ends in a written GO / NO-GO in this doc, and a NO-GO is a
339-perfectly good outcome — Phase 0 already shows the operator's real need is met by separate clones,
340-which cost a `git clone` and need no code.
341-
--
352-   If the answer is "each swarm owns a distinct branch," that is a contract to state and enforce, not
353-   an assumption.
354-4. **A real operator demand exists that separate clones do not meet.** Named, with the reason clones
355:   were insufficient. Absent that, NO-GO on cost alone.
356-
357-On GO, the shape is #354's own: an opt-in `XYZ_LOCK_SCOPE=worktree` keeping the lock in `$ROOT`,
358-default off, mirrored across all four driver files, its own issue, and its own plan doc. Not this one
359-— by then this doc's job is done.
360-
361:### Phase 4 QA gate
362-
363:- A GO/NO-GO decision is written **into this doc** with its reasoning, and each of the four criteria
364:  is answered explicitly (an unanswered criterion is a NO-GO, not a deferral).
365:- On NO-GO: `#354` is closed with the separate-clones recommendation and a pointer to the Phase 3
366-  matrix; this doc moves to `PROJECT/3-COMPLETED/` and its `ROADMAP.md` pointer is updated.
367-- On GO: a new issue + `PROJECT/1-INBOX/GH-<n>-*.md` capture exists and is parked in `ROADMAP.md`
368-  per the issue-first SOP; no implementation begins under this doc.
--
378-  `git revert`. The one live-state caveat: a driver started before the fix holds its lock at the old
379-  path, so a mid-flight upgrade can leave a stale lock at the pre-fix location — the GH-42 self-heal
380-  reclaims it only when the holder is dead, which is the correct behavior, and it is worth naming in
381:  Phase 3's docs rather than discovering in the field.
382:- **Phase 3 — Easy.** Docs and comments.
383:- **Phase 4 — one-way door, which is why it is a gate.** Relaxing lock scope changes the containment
384-  contract every consumer and every vendored `.xyz/` install inherits; `risk: 3` on this doc covers
385-  Phases 1–3, and a GO would carry its own higher rating in its own doc.

2026-08-12T04:35:29.964727Z ERROR codex_models_manager::manager: failed to renew cache TTL: missing field `base_instructions` at line 95 column 5
codex
ANSWER: Keep all three open. The green Nightwatch gate proves the frozen release goalpost, not that these parent issues have no material remainder.

FINDINGS

- [Blocker] **#388 — C, KEEP OPEN.** The shipped exception permits a default transcript/run-log path inside the driven repo even when that repo is under `$TMPDIR` ([marathon.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-69972-gxaghv_u/relay-automation/marathon.sh:224), [relay-turn-lib.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-69972-gxaghv_u/relay-automation/relay-turn-lib.sh:214)). A reboot can therefore erase the entire target checkout and its only run evidence without a refusal or warning—the exact operational failure the issue is meant to prevent. Fixture friction is real, but it is not a reason to redefine volatile storage as durable. Close when the default refuses any runtime-listed non-durable destination, with an explicit test-only/opt-in volatile mode if fixtures require it; retain the current outside-repo refusal too. Criterion 5 already states that necessary invariant ([GH-388 doc](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-69972-gxaghv_u/PROJECT/2-WORKING/GH-388-MARATHON-RUN-LOG-DURABILITY.md:120)).

- [Blocker] **#358 — C, KEEP OPEN.** This is not a technicality or an inert observation wait: CI is actively red on the 16-way safety assertion. The shipped instrumentation distinguishes “lock acquired, record lost” from “lock never acquired” ([negative control](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-69972-gxaghv_u/test/baselines/GH-358-negative-control.md:23)); the missing value is the resulting disposition, which the issue deliberately requires to follow real evidence ([GH-358 doc](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-69972-gxaghv_u/PROJECT/2-WORKING/GH-358-LOCK-FLAKE-INSTRUMENTATION.md:72)). A CI-environment cause is still a material product/release-signal defect, not grounds to close it. Close after capturing an instrumented CI failure and either fixing the demonstrated lock failure or making an explicit, reasoned CI exclusion/retry decision while preserving `M=16` and distinctness.

- [Should] **#354 — C, KEEP OPEN as the tracking parent.** #376 and #448 credibly delivered the narrow Phase-1 containment and observability slices ([#376 status](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-69972-gxaghv_u/PROJECT/2-WORKING/GH-376-RELAY-DRIVE-LOCK-PATH-DIVERGENCE.md:5), [#448 status](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-69972-gxaghv_u/PROJECT/3-COMPLETED/GH-448-DRIVER-LOCK-RESOLVER.md:5)). But the parent still owns the canonical concurrency contract and the GO/NO-GO on per-worktree parallelism; neither has been completed ([Phase 3](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-69972-gxaghv_u/PROJECT/2-WORKING/GH-354-CONCURRENT-SWARMS.md:302), [Phase 4](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-69972-gxaghv_u/PROJECT/2-WORKING/GH-354-CONCURRENT-SWARMS.md:336)). Closing now would erase the owner of that decision. Close only after documenting the exclusion matrix and recording a reasoned NO-GO with the separate-clones recommendation, or after spawning a successor for a justified GO.

- [Pass] A documented deviation is materially better than a silent one, and Nightwatch correctly separates RC gate success from issue closure ([RELEASES.md](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-69972-gxaghv_u/RELEASES.md:118)). It is not, however, a substitute for deciding whether the deviation preserves the real invariant.

General rule (≤150 words): An agent may close an issue after divergence only if it writes an atomic adjudication: (1) state the original invariant, (2) state the shipped invariant, (3) show a realistic counterexample analysis and controls, and (4) update the acceptance wording before closing. Choose **B** only when the new invariant protects every material user-facing failure mode the old criterion protected, and improves feasibility or safety. Choose **C** when any realistic supported run can still lose, corrupt, mislead, or leave unowned the value the issue exists to protect; split only genuinely independent future work into successors. A green release gate never decides this question. **A** is reserved for no substantive divergence.

RECOMMENDATION: Keep #388, #358, and #354 open; treat #388 and #358 as active correctness work, and #354 as the explicit tracking/decision parent.
tokens used
130,664
ANSWER: Keep all three open. The green Nightwatch gate proves the frozen release goalpost, not that these parent issues have no material remainder.

FINDINGS

- [Blocker] **#388 — C, KEEP OPEN.** The shipped exception permits a default transcript/run-log path inside the driven repo even when that repo is under `$TMPDIR` ([marathon.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-69972-gxaghv_u/relay-automation/marathon.sh:224), [relay-turn-lib.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-69972-gxaghv_u/relay-automation/relay-turn-lib.sh:214)). A reboot can therefore erase the entire target checkout and its only run evidence without a refusal or warning—the exact operational failure the issue is meant to prevent. Fixture friction is real, but it is not a reason to redefine volatile storage as durable. Close when the default refuses any runtime-listed non-durable destination, with an explicit test-only/opt-in volatile mode if fixtures require it; retain the current outside-repo refusal too. Criterion 5 already states that necessary invariant ([GH-388 doc](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-69972-gxaghv_u/PROJECT/2-WORKING/GH-388-MARATHON-RUN-LOG-DURABILITY.md:120)).

- [Blocker] **#358 — C, KEEP OPEN.** This is not a technicality or an inert observation wait: CI is actively red on the 16-way safety assertion. The shipped instrumentation distinguishes “lock acquired, record lost” from “lock never acquired” ([negative control](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-69972-gxaghv_u/test/baselines/GH-358-negative-control.md:23)); the missing value is the resulting disposition, which the issue deliberately requires to follow real evidence ([GH-358 doc](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-69972-gxaghv_u/PROJECT/2-WORKING/GH-358-LOCK-FLAKE-INSTRUMENTATION.md:72)). A CI-environment cause is still a material product/release-signal defect, not grounds to close it. Close after capturing an instrumented CI failure and either fixing the demonstrated lock failure or making an explicit, reasoned CI exclusion/retry decision while preserving `M=16` and distinctness.

- [Should] **#354 — C, KEEP OPEN as the tracking parent.** #376 and #448 credibly delivered the narrow Phase-1 containment and observability slices ([#376 status](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-69972-gxaghv_u/PROJECT/2-WORKING/GH-376-RELAY-DRIVE-LOCK-PATH-DIVERGENCE.md:5), [#448 status](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-69972-gxaghv_u/PROJECT/3-COMPLETED/GH-448-DRIVER-LOCK-RESOLVER.md:5)). But the parent still owns the canonical concurrency contract and the GO/NO-GO on per-worktree parallelism; neither has been completed ([Phase 3](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-69972-gxaghv_u/PROJECT/2-WORKING/GH-354-CONCURRENT-SWARMS.md:302), [Phase 4](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-69972-gxaghv_u/PROJECT/2-WORKING/GH-354-CONCURRENT-SWARMS.md:336)). Closing now would erase the owner of that decision. Close only after documenting the exclusion matrix and recording a reasoned NO-GO with the separate-clones recommendation, or after spawning a successor for a justified GO.

- [Pass] A documented deviation is materially better than a silent one, and Nightwatch correctly separates RC gate success from issue closure ([RELEASES.md](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-69972-gxaghv_u/RELEASES.md:118)). It is not, however, a substitute for deciding whether the deviation preserves the real invariant.

General rule (≤150 words): An agent may close an issue after divergence only if it writes an atomic adjudication: (1) state the original invariant, (2) state the shipped invariant, (3) show a realistic counterexample analysis and controls, and (4) update the acceptance wording before closing. Choose **B** only when the new invariant protects every material user-facing failure mode the old criterion protected, and improves feasibility or safety. Choose **C** when any realistic supported run can still lose, corrupt, mislead, or leave unowned the value the issue exists to protect; split only genuinely independent future work into successors. A green release gate never decides this question. **A** is reserved for no substantive divergence.

RECOMMENDATION: Keep #388, #358, and #354 open; treat #388 and #358 as active correctness work, and #354 as the explicit tracking/decision parent.
