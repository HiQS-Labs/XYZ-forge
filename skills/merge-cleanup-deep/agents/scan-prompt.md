# Sub-agent prompt template — one read-only medium scan per branch family

Fill every `{{…}}` before launching. Launch at most three agents per run; give every clone of one
branch name to the same agent. Model: a Sonnet-class agent is sufficient.

---

You are doing a READ-ONLY "medium scan" of {{N}} stale task clones of the GitHub repo
{{OWNER}}/{{REPO}} to decide what unlanded work is worth turning into a PR. You are one of
{{AGENT_COUNT}} agents; you own these clone directories (all under {{PARENT_DIR}}/):

{{CLONE_LIST — one line each: name (branch @ short-sha; dirty files; anything already known)}}

HARD RULES (a violation is worse than an incomplete report):
- Read-only. Never run: git checkout/switch/reset/stash/clean/rebase/merge/commit/push/branch -D,
  rm, mv, or any test suite (validate.sh, test/*.sh, pytest). Do not edit any file in any clone.
- Use `git -C "<path>"` for every git command; never cd into a clone.
- `git fetch origin {{INTEGRATION_BRANCH}}` is allowed. Fetching a PR head into a temporary ref is
  allowed: `git fetch origin refs/pull/<N>/head:refs/deepscan/pr<N>`. Fetching a sibling clone's
  HEAD is allowed: `git -C <A> fetch <path-to-B> HEAD:refs/deepscan/<B>`. If a clone's `origin` is a
  LOCAL path, fetch the integration branch from https://github.com/{{OWNER}}/{{REPO}}.git into
  `refs/deepscan/dev`. Delete every `refs/deepscan/*` ref you created with `git update-ref -d`
  before you finish.
- Do not touch any other directory under {{PARENT_DIR}} (other agents own them; {{PRIMARY_NAME}}
  is the operator's primary; {{LIVE_CLONES}} belong to live sessions).
- Write your report ONLY to {{REPORT_PATH}} (mkdir -p its directory).

SHARED FACTS ({{DATE}}): origin/{{INTEGRATION_BRANCH}} on GitHub is at {{DEV_HEAD}}. Merged PRs:
{{MERGED_PRS — #N (branch, head sha, squash sha)}}. Open PRs: {{OPEN_PRS — #N (branch, head sha,
draft?, mergeable?)}}. `gh pr list --repo {{OWNER}}/{{REPO}} --state all --head <branch>` and
`gh issue view <N> --repo {{OWNER}}/{{REPO}} --json state,title,closedAt` are read-only and allowed.

FOR EACH CLONE gather, with commands and their actual output as evidence:
a. `git remote -v`, branch, HEAD sha, `git status --porcelain --untracked-files=all` (name every
   dirty file; for modified tracked files show `git diff --stat` and, unless it is a generated view
   such as LEADERBOARD.md / releases.db / releases.sql, the first ~40–60 lines of the diff). List
   non-trivial ignored files (`git status --porcelain --ignored`, skipping node_modules/.venv/
   __pycache__) and say in one line whether each holds anything not regenerable.
b. Unlanded commits for EVERY local ref (`git for-each-ref refs/heads`, plus a detached HEAD, plus
   `backup/*`): `git log --format='%h %ad %an %s' --date=short <dev>..<ref>` and
   `git diff --stat $(git merge-base <dev> <ref>)..<ref>`. Count them and list files touched.
c. Landed-elsewhere test — the key question:
   - by ancestry: `git merge-base --is-ancestor <ref> refs/deepscan/pr<N>` against each merged PR
     head that could have absorbed the work;
   - by content: for each non-generated source/test file touched, `git diff <dev> <ref> -- <path>`
     (empty or whitespace-only = LANDED). Where a diff remains, grep <dev> for a distinctive
     identifier from the hunk (`git grep -n '<identifier>' <dev> -- <path>`) to catch hunks that
     landed in a different shape. Summarize per file: LANDED / PARTIALLY LANDED (what remains) /
     NOT LANDED;
   - against open PR heads: `git diff refs/deepscan/pr<N> <ref> --stat -- <key paths>`; state
     whether the clone holds anything the PR branch does not (commits ahead, dirty files).
d. QA attestation: grep the unlanded commit messages and any relay-system/ or PROJECT/2-WORKING/
   GH-*.md docs in the clone for "relay-drive: attest", "final QA approved", "LGTM", "QA approved".
   Quote what you find and say what it attests (a plan, or the implementation).
e. Linked issue(s): from the branch name / commit messages, then `gh issue view` for state.
f. Family view (when you own several clones of one branch name): establish the ancestry chain
   between their HEADs pairwise; which is the most advanced; are the others strict ancestors of it,
   or independent re-executions? For a producer/validation pair, which holds the superset?
g. Verdict, exactly one of: PR-WORTHY (unique, coherent, attested or near-attested work not on
   <dev> or in an open PR), SUPERSEDED (content already on <dev> or in an open PR — name where),
   NEEDS-OWNER (unique but incomplete/unattested — name what is missing), ABANDON-CANDIDATE
   (nothing unique beyond generated views, scratch, or backups whose content landed), HOLD (HEAD
   equals an open PR head exactly). Give the evidence line that decides it and one recommended
   next step.

REPORT FORMAT (markdown): a summary table at the top (clone | branch@HEAD | unlanded commits (all
refs) | dirty/ignored of note | verdict | next step), then one section per clone with the evidence,
then a short family/pair view. Be concrete: shas, counts, file paths, quoted lines. Do not
speculate beyond the evidence; write "not established" when you could not establish something. If
a briefed sha or file does not match what you find, say so and proceed from what is there. Keep
the whole report under ~250 lines.
