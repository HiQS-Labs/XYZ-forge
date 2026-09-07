**SINGLE-MODEL — NOT RECONCILED** (only codex answered; 1 of 2 requested advisor(s) failed — this is one model's read, not a cross-model consult. Do not treat any claim below as cross-verified.)

**NO FIRSTHAND VERIFICATION CITED** — treat conclusions as conditional (codex's answer carries an unsupported [Pass]/verified/confirmed-style claim with no quoted span or file:line citation nearby, despite the consult PREAMBLE asking advisors to cite evidence.)

> **ATTESTATION**
> Model: gpt-5.6-terra
> Provider: openai
> Sandbox: read-only

Reading additional input from stdin...
OpenAI Codex v0.153.4
--------
workdir: /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-33750-j8h2ug9_
model: gpt-5.6-terra
provider: openai
approval: never
sandbox: read-only
reasoning effort: high
reasoning summaries: none
session id: 01a07d81-6389-77c1-a846-1e8a5176a5fd
--------
user
You are an INDEPENDENT advisor in a one-shot cross-model consult. Another model is answering the SAME question separately and a coordinator will reconcile both answers, so give your own honest, specific read — do not hedge toward a consensus you cannot see. Read any repo files the question references (cite file:line). Respond with: (1) a short direct ANSWER; (2) graded FINDINGS — [Blocker]/[Should]/[Nit]/[Pass] — where applicable; (3) a one-line RECOMMENDATION. You are ADVISORY ONLY: output your analysis as text; do not rely on writing files (you are running in a throwaway copy).

=== CONSULT QUESTION ===
# Adjudicate PR #485: the push guard should read the renderer's stderr instead of classifying by table name

You are reviewing a change in THIS repository, in the working tree you are running in. **Read the
real files.** Do not answer from memory, from a cached copy of this repo, or from any scratch
directory elsewhere on disk — if a file you expect is absent here, say so and treat this worktree as
authoritative. Cite `file:line` for every load-bearing claim and name the command you ran.

The worktree is checked out on `fix/gh474-dropped-row-signal`, so the change is ALREADY APPLIED in
the files you read. Compare against `development` with
`git diff development -- githooks/dashboard-staleness-guard.sh` to see what changed. Say which state
you read — a review of the wrong side is worse than no review.

## Background: the defect

`githooks/dashboard-staleness-guard.sh` runs from `githooks/pre-push`. It refuses a push whose range
writes the roadmap ledger (`releases.sql` / `releases.db`) without also moving
`ROADMAP-DASHBOARD.md`.

When regenerating the dashboard produces NO diff, one hazard survives: a roadmap row the renderer
DROPPED. A dropped row renders to nothing, so the committed artifact still matches a fresh render
byte-for-byte while the ledger row is invisible in the view. A byte comparison cannot see it.

To detect that, the guard used to classify the `releases.sql` diff BY TABLE NAME against a
hand-maintained allowlist. That allowlist went short twice and left 8 dump tables unclassified, each
producing a FALSE refusal.

## The change

One file: `githooks/dashboard-staleness-guard.sh`.

1. Capture the renderer's stderr instead of discarding it:
   `render_err="$(bash "$TMP_PROJ/utils/roadmap-dashboard.sh" --check 2>&1 >/dev/null)"`
2. In the no-drift arm, refuse if and only if `render_err` contains
   `roadmap-dashboard: warning: dropped ` — and quote the matched line in the refusal.
3. Delete the table classifier.

`utils/roadmap-dashboard.sh` is NOT modified.

## Questions — answer each, adversarially

1. **Is the premise true?** Does `utils/roadmap-dashboard.sh --check` really emit
   `roadmap-dashboard: warning: dropped N unparseable row(s): <ids>` on stderr? Trace it: where does
   the node render run relative to the `MODE == "check"` branch? Quote line numbers. If the render
   is NOT unconditional, the whole change rests on a false premise — say so loudly.

2. **Is the stderr capture correct Bash?** Scrutinise `render_err="$(cmd 2>&1 >/dev/null)"` under
   `set -uo pipefail` (note: NO `set -e`).
   - Does it capture stderr only, or does stdout leak in?
   - Does the assignment carry `cmd`'s exit status to the enclosing `if`, so the drift verdict is
     genuinely unchanged?
   - The guard reads `render_err` with a `while IFS= read -r` loop over an UNQUOTED heredoc
     (`<<EOF_ERR` / `$render_err` / `EOF_ERR`). Is that safe, or can renderer output containing `$`,
     backticks or backslashes be expanded or mangled? **This is the line I most want attacked.**
   - The refusal `cat >&2 <<EOF` heredoc is also unquoted so it can interpolate `$dropped_line`.
     Can renderer-controlled text cause command substitution or any injection there?

3. **Does it fail in the right direction?** The old mechanism failed CLOSED for an unknown table
   (catch-all, then refuse). The new one ALLOWS when the renderer is silent. Enumerate the ways the
   renderer can be silent while a row is effectively missing from the view — a crash before the
   warning, a `node`/`python3` lookup failure, an empty `roadmap list --json`, the legacy
   `ROADMAP.md` fallback path. For each: does the guard refuse, or silently allow? Is any of those a
   real regression versus the old behaviour?

4. **The projection.** The guard renders from `git archive <local_sha> | tar -x` into a private temp
   root, not the working tree. Does the warning survive that projection in every case the guard
   cares about? What if the projected commit lacks `releases.db`, or lacks
   `utils/py/releases_app.py`? Trace `utils/roadmap-dashboard.sh`'s fallbacks.

5. **The exit contract.** The change deliberately does NOT give `--check` a new exit code, because
   five consumers read its status and four are suites that treat any non-zero as failure
   (`githooks/dashboard-staleness-guard.sh`, `test/gh269-roadmap-retired.sh:26`,
   `test/gh280-jog-marathon-adapter.sh:1021` and `:1033`, `test/gh57-live-merge-resolve.sh:290`,
   `test/roadmap-dashboard.sh:49`). Verify that enumeration — is it complete, and is the reasoning
   sound? Is "signal on stderr" genuinely better than "new exit code plus fix four suites", or is it
   dodging a one-time cost at the price of a fragile string match?

6. **Are the tests real proof or theatre?** In `test/gh243-dashboard-staleness-guard.sh`, tests 7,
   7b and 8b use a STUB renderer (a shell script that exits 0, optionally echoing to stderr). Only
   `test/gh257-roadmap-ledger-fixes.sh` case 11 exercises the real renderer through the real
   projection. Is the red control (test 8) genuinely red — would it fail against the pre-change
   guard? Would any of these pass for the wrong reason? **Name a mutation to the guard that every
   one of these tests would MISS.**

7. **Should this ship?** Pick one: SHIP, SHIP WITH CHANGES (name them precisely), or DO NOT SHIP
   (name what would change your mind). A balanced survey is a failed answer.

Grade findings [Blocker] / [Should] / [Nit]. End with a one-line verdict.

codex
I’ll review the applied `fix/gh474-dropped-row-signal` state against `development`, trace the renderer and tests, and report only evidence from this worktree.
codex
I’m using the consult workflow because this is explicitly a one-shot cross-model review; I’ll keep it advisory and inspect the checked-out change rather than modifying anything.
exec
/bin/zsh -lc "pwd && sed -n '1,240p' /Users/noelsaw/.codex/skills/agent-chorus/SKILL.md >/dev/null; sed -n '1,260p' /Users/noelsaw/.codex/skills/.system/../../skills/consult/SKILL.md" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-33750-j8h2ug9_
 succeeded in 0ms:
/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-33750-j8h2ug9_
---
name: consult
description: One-shot cross-model CONSULT — fan the same question out to Codex and agy in parallel (repo-isolated, advisory), then reconcile their answers into one. Use when the user wants a "second opinion", to "ask Codex and agy", a "panel" or "cross-model" check, or an independent gut-check on a decision/design/doc before committing — and does NOT need an iterative build/review loop. NOT a relay: a relay is an iterative 1:1 Producer↔Reviewer loop that converges an artifact; a consult is a parallel 1-shot 1:N second opinion, reconciled once. Depends on the codex + agy CLIs and the relay-automation shims; runs in any repo that ships them at the repo root OR in a vendored `.xyz/` install (the skill resolves either).
---

# Consult

**One question → N independent models in parallel → one reconciled answer.**

A consult asks Codex and agy the *same* question at the same time, isolated from your real tree, and then a
coordinator (Claude) reconciles their answers — surfacing where they **agree**, where they
**disagree**, and giving a single reconciled **call**. It is the fast "ask the other brains before I
commit" move: no copy-paste, no window-shuttling, one step.

## Consult vs. relay — pick the right tool

| | **consult** (this skill) | **relay** |
|---|---|---|
| shape | parallel fan-out, 1 question → N models | iterative loop, 2 agents |
| rounds | exactly **one** | many, until `Approved` |
| writes | **none** — advisory only | Producer edits the artifact |
| output | reconciled answer + divergences | a converged artifact |
| use for | a decision, a design gut-check, "is this doc sound?" | building/fixing an artifact under review |

If after a consult you decide the work needs iteration, *start a relay* — the consult is the cheap
first look, the relay is the build loop.

## When to use

- "Get a second opinion." "Ask Codex and agy." "What do the other models think?"
- "Panel review" / "cross-model check" / "sanity-check this before I commit."
- An independent gut-check on a plan, design, schema, or doc — where you want *divergent* reads, not
  a single model's confident answer.

Do **not** use it to build or fix an artifact iteratively — that's `relay`.

## How it works

`relay-automation/consult.sh` (path is relative to **this repo's root**, not your cwd) fans the question
out to both advisors **in parallel** and writes each transcript to a per-run dir
`relay-system/<today>/<label>-<HHMMSS>/`. The synthesis is **yours** — the script only gathers the raw
opinions.

**Locating the script — resolve it cwd-independently; never assume your cwd is the repo root.** A bare
`consult.sh` or `relay-automation/consult.sh` only resolves when you happen to be sitting at the root,
so invoke it through its repo-root anchor instead. Two homes are supported so consult works both in
the `xyz-3-agents-swarm` checkout **and** in any repo that has a vendored `.xyz/` install: the
top-level `relay-automation/` if present, otherwise the vendored `.xyz/relay-automation/`.

```
ROOT="$(git rev-parse --show-toplevel)"
SCRIPT="$ROOT/relay-automation/consult.sh"
[ -f "$SCRIPT" ] || SCRIPT="$ROOT/.xyz/relay-automation/consult.sh"
# CONSULT_ROOT MUST be the repo root: consult.sh otherwise infers its root as the script's parent-of-
# parent, which for the vendored copy is `.xyz/` (wrong). Setting it pins the consult to the real repo
# and its `relay-system/` output. Harmless (a no-op) for the top-level copy.
CONSULT_ROOT="$ROOT" "$SCRIPT" --prompt "…" --label …
```

`git rev-parse --show-toplevel` works from any subdirectory of the repo. If you are not inside a repo
that has consult (no top-level `relay-automation/` and no `.xyz/`), either `cd` into the
`xyz-3-agents-swarm` worktree, or vendor a `.xyz/` into the target repo first
(`relay-automation/xyz-vendor.sh <repo>`). (Do **not** go hunting the disk for `consult.sh`; the
anchor above always finds it.)

**Provable no-mutation boundary (not best-effort).** Advisors run with their working directory set to a
**throwaway git worktree** checked out from your *current* state — tracked WIP (via `git stash create`)
plus untracked-non-ignored files copied in — so they see your working state (minus `.gitignore`d
files), including a brand-new file under
review. Anything an advisor writes lands in that disposable worktree and is destroyed with it; your
real working tree is **never** the advisors' surface, so there is nothing to revert and ambient WIP
cannot be clobbered. (Codex additionally runs `-s read-only`.) This replaced an earlier best-effort
post-hoc revert that the skill's own first dogfood flagged as unsafe.

```
consult.sh --prompt-file Q.md            # question is the file's contents (may reference repo paths)
consult.sh --prompt "Is X sound?"        # inline question
  [--models codex,agy]                   # which advisors (default both)
  [--out DIR]                            # parent dir (default relay-system/<today>/)
  [--label SLUG]                         # run-subdir + transcript stem (default "consult")
```

Each run gets its own `<label>-<HHMMSS>/` subdir, so two consults the same day never overwrite each
other. Behavior is covered by `test/consult.sh` in `validate.sh` (WIP preservation, no advisor leak,
graceful degrade, non-git refusal).

Exit `0` = at least one advisor answered; `5` = all failed; `3` = not a git repo (isolation needs
one); `2` = usage. Per-model failures are reported, not fatal — if Codex's backend is down, Gemini's
answer still comes back (**graceful degrade**, and the degrade is stated, never silent).

## Steps (the coordinator's job)

1. **Frame one sharp question.** Put it in a prompt file when it references repo paths (the advisors
   read the files themselves). Be explicit about what "good" looks like, just like a relay's
   Definition of Done.
2. **Fan out:** run the script through its repo-root anchor (see "Locating the script" above — prefer
   `$ROOT/relay-automation/consult.sh`, fall back to `$ROOT/.xyz/relay-automation/consult.sh`, and
   always pass `CONSULT_ROOT="$ROOT"`) with the prompt + a `--label`. Both models run at once. Don't
   invoke a bare `consult.sh`; it only resolves at the repo root.
3. **Read both transcripts** in `relay-system/<today>/<label>-<HHMMSS>/<label>.codex.md` and `…agy.*`.
4. **Reconcile — this is the load-bearing step.** Produce a synthesis with four parts, in this order:
   - **TLDR** (new — one to two sentences, before anything else): the reconciled call and how confident
     it is, so the operator can stop reading right there if that's all they need. e.g. *"Both models
     agree the migration is safe — go ahead. Codex flagged one edge case worth a follow-up (see below)."*
   - **Disagree** (it's the whole point of asking two models): every point the two differ on, with your
     adjudication and *why*. Never in the TLDR — the TLDR previews the call, it doesn't bury the split.
   - **Agree:** what both independently converged on (higher confidence because it's cross-model).
   - **Sorted categories** (new — closes the synthesis, replaces a bare prose recommendation): bucket
     every point either advisor raised — agreements and adjudicated disagreements alike — into exactly
     one:
     - **Blocking** — a real risk either advisor surfaced; must address before proceeding.
     - **Worth doing, optional** — a real improvement; the operator's call.
     - **Skip / out of scope** — noted and dismissed, named so it doesn't resurface.
     Drop empty buckets. For a short, clean consult (both advisors agree, one or two minor notes),
     skip the buckets and give the recommendation as plain prose instead — don't force structure on a
     synthesis with nothing to sort.
5. **Hand the synthesis back** to the operator. If it reveals the work needs iteration, offer to
   start a `relay`.

## The one rule that makes a consult worth running

**Surface disagreement; never average it away.** The entire value of asking two models is the *delta*
between them — the place one caught what the other missed. A synthesis that smooths two answers into
one confident paragraph throws that away and is worse than asking one model, because it launders two
guesses into false consensus. Lead with the disagreements, adjudicate them explicitly, and if you
can't adjudicate one, say so and flag it for the human. (Same failure mode as a review that only
hunts overclaims and misses silent drops: the easy direction satisfices.)

## Honest caveats

- **Two models, not ground truth.** Cross-model agreement raises confidence; it does not prove
  correctness — both can share a blind spot or a wrong prior. Treat a unanimous answer as *strong
  signal*, not proof, especially when correctness rides on runtime behavior neither model ran.
- **Repo-isolated, not process-sandboxed.** Advisors run in a throwaway worktree and cannot reach
  your real tree, so a consult never changes your code even if an advisor ignores the "advisory only"
  instruction. Be precise about the boundary: this protects your *repository*, not the *host process*.
  Codex additionally runs `-s read-only`; agy runs with `--dangerously-skip-permissions` and is
  repo-isolated but not a sandboxed process (it can still reach the network / the host outside the
  worktree). For a hard process boundary, run consult inside your own sandbox. If a fix is needed,
  *you* (or a relay) apply it — the independent check stays independent.
- **The worktree shows tracked + untracked state, not ignored files.** `.gitignore`d local context is
  excluded from what advisors see; reference it inline in the question if it matters.
- **Cost capture is not available for agy.** agy has no JSON/token output, so an agy lane is cost-blind
  (a floor). Codex token parsing is also still deferred. Neither lane captures `tick cost` events in a consult.
- **Needs the shims present, but is not tied to one repo.** Unlike `relay` (model-agnostic, file-only),
  consult hard-depends on the `codex` + `agy` CLIs being installed and authed and on the
  `relay-automation` shims. Those shims can live at the repo root **or** in a vendored `.xyz/` install,
  so any repo carrying a `.xyz/` (see `relay-automation/xyz-vendor.sh`) can run consult standalone.

## Gotcha: run consult OUTSIDE Claude Code's Bash sandbox

If you launch `consult.sh` from a Claude Code session, **disable the Bash sandbox for that call**
(`dangerouslyDisableSandbox: true`). **Both advisors fail under the sandbox:**
- **Codex** — the sandbox blocks the macOS keychain (`no native root CA certificates found` / `No keychain is available`) and does not allowlist `chatgpt.com`.
- **agy** — the sandbox blocks agy's backend network; `agy -p` exits 0 with **empty output** (the shim treats this as a hard failure, exit 5).

The symptom is a two-sided `0 answered, 2 failed` degrade. Disabling the sandbox here is safe:
consult's isolation comes from its **throwaway worktree** (and Codex's own `-s read-only`), not from
the Bash sandbox, so nothing is weakened.

## What success looks like

The operator asks one question and gets back a single, honest, reconciled answer that **shows its
seams** — what the two models agreed on, where they split, and which way the coordinator called it and
why — in one step, with both raw transcripts on disk for audit.

exec
/bin/zsh -lc "sed -n '1,220p' ROUTER.md && git status --short --branch && git diff --check development -- githooks/dashboard-staleness-guard.sh && git diff --unified=80 development -- githooks/dashboard-staleness-guard.sh && nl -ba githooks/dashboard-staleness-guard.sh && nl -ba utils/roadmap-dashboard.sh" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-33750-j8h2ug9_
 succeeded in 8321ms:
2026-09-07 13:14:01.641 xcodebuild[42155:4435967]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-09-07 13:14:02.072 xcodebuild[42155:4435843] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.
git: warning: confstr() failed with code 5: couldn't get path of DARWIN_USER_TEMP_DIR; using /tmp instead
git: error: couldn't create cache file '/tmp/xcrun_db-uhINJIHq' (errno=Operation not permitted)
2026-09-07 13:14:02.764 xcodebuild[43286:4437579]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-09-07 13:14:02.986 xcodebuild[43286:4437537] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.
## HEAD (no branch)
?? relay-system/2026-09-07/gh485-dropped-row-signal-131345/
git: warning: confstr() failed with code 5: couldn't get path of DARWIN_USER_TEMP_DIR; using /tmp instead
git: error: couldn't create cache file '/tmp/xcrun_db-uYB2VDHx' (errno=Operation not permitted)
2026-09-07 13:14:04.482 xcodebuild[44652:4439572]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-09-07 13:14:04.693 xcodebuild[44652:4439529] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.
git: warning: confstr() failed with code 5: couldn't get path of DARWIN_USER_TEMP_DIR; using /tmp instead
git: error: couldn't create cache file '/tmp/xcrun_db-yUnZS8Td' (errno=Operation not permitted)
2026-09-07 13:14:05.275 xcodebuild[45234:4440422]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-09-07 13:14:05.510 xcodebuild[45234:4440379] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.
git: warning: confstr() failed with code 5: couldn't get path of DARWIN_USER_TEMP_DIR; using /tmp instead
git: error: couldn't create cache file '/tmp/xcrun_db-2dnDp0J2' (errno=Operation not permitted)
2026-09-07 13:14:06.846 xcodebuild[46378:4442077]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-09-07 13:14:07.068 xcodebuild[46378:4442038] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.
git: warning: confstr() failed with code 5: couldn't get path of DARWIN_USER_TEMP_DIR; using /tmp instead
git: error: couldn't create cache file '/tmp/xcrun_db-f5Mbm7zH' (errno=Operation not permitted)
2026-09-07 13:14:07.688 xcodebuild[46991:4443072]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-09-07 13:14:07.960 xcodebuild[46991:4443020] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.
diff --git a/githooks/dashboard-staleness-guard.sh b/githooks/dashboard-staleness-guard.sh
index 81524e29..3f481b3a 100755
--- a/githooks/dashboard-staleness-guard.sh
+++ b/githooks/dashboard-staleness-guard.sh
@@ -41,156 +41,154 @@ get_dev_inode() {
   # between two identical inodes. `-c` is not a BSD flag, so probing GNU-first fails cleanly there.
   stat -c "%d %i" "$target" 2>/dev/null || stat -f "%d %i" "$target" 2>/dev/null || true
 }
 
 cleanup_guard() {
   local exit_code=$?
   [ -n "$GUARD_ROOT" ] || return "$exit_code"
   [ -e "$GUARD_ROOT" ] || return "$exit_code"
   if [ -L "$GUARD_ROOT" ]; then
     echo "dashboard-staleness-guard: refusing cleanup — guard root is a symlink" >&2
     exit 1
   fi
   local cur_phys
   cur_phys="$(cd -P "$GUARD_ROOT" 2>/dev/null && pwd -P)" || {
     echo "dashboard-staleness-guard: failed to resolve guard root physical path" >&2
     exit 1
   }
   if [ -n "$GUARD_ROOT_PHYS" ] && [ "$cur_phys" != "$GUARD_ROOT_PHYS" ]; then
     echo "dashboard-staleness-guard: refusing cleanup — guard root path drifted ($cur_phys != $GUARD_ROOT_PHYS)" >&2
     exit 1
   fi
   local cur_dev_inode
   cur_dev_inode="$(get_dev_inode "$cur_phys")"
   local cur_dev="${cur_dev_inode%% *}"
   local cur_inode="${cur_dev_inode##* }"
   if [ -z "$GUARD_DEV" ] || [ -z "$GUARD_INODE" ] || [ -z "$cur_dev" ] || [ -z "$cur_inode" ] || \
      [ "$cur_dev" != "$GUARD_DEV" ] || [ "$cur_inode" != "$GUARD_INODE" ]; then
     echo "dashboard-staleness-guard: refusing cleanup — guard root identity mismatch ($cur_dev:$cur_inode != $GUARD_DEV:$GUARD_INODE)" >&2
     exit 1
   fi
   case "$cur_phys" in
     "$SYS_TMP"/*) rm -rf "$cur_phys" || exit 1 ;;
     *) echo "dashboard-staleness-guard: refusing cleanup of non-descendant $cur_phys" >&2; exit 1 ;;
   esac
   return "$exit_code"
 }
 trap cleanup_guard EXIT INT TERM
 
 GUARD_ROOT="$(mktemp -d "$SYS_TMP/staleness-guard.XXXXXX")"
 [ -n "$GUARD_ROOT" ] || { echo "dashboard-staleness-guard: mktemp failed" >&2; exit 1; }
 
 GUARD_ROOT_PHYS="$(cd -P "$GUARD_ROOT" 2>/dev/null && pwd -P)" || GUARD_ROOT_PHYS=""
 [ -n "$GUARD_ROOT_PHYS" ] && [ -d "$GUARD_ROOT_PHYS" ] || { echo "dashboard-staleness-guard: failed to resolve guard root" >&2; exit 1; }
 case "$GUARD_ROOT_PHYS" in
   "$SYS_TMP"/*) ;;
   *) echo "dashboard-staleness-guard: guard root $GUARD_ROOT_PHYS is not a resolved descendant of $SYS_TMP" >&2; exit 1 ;;
 esac
 
 init_dev_inode="$(get_dev_inode "$GUARD_ROOT_PHYS")"
 GUARD_DEV="${init_dev_inode%% *}"
 GUARD_INODE="${init_dev_inode##* }"
 if [ -z "$GUARD_DEV" ] || [ -z "$GUARD_INODE" ]; then
   echo "dashboard-staleness-guard: failed to establish guard root device/inode identity" >&2
   exit 1
 fi
 
 while [ "$#" -ge 2 ]; do
   local_sha="$1"; remote_sha="$2"; shift 2
   case "$remote_sha" in
     ''|0000000000000000000000000000000000000000) continue ;;   # new branch: no range to inspect
   esac
   git -C "$REPO" cat-file -e "${remote_sha}^{commit}" 2>/dev/null || continue
 
   touched_ledger=0
   touched_dashboard=0
   while IFS= read -r path; do
     case "$path" in
       releases.sql|releases.db) touched_ledger=1 ;;
       ROADMAP-DASHBOARD.md)     touched_dashboard=1 ;;
     esac
   done < <(git -C "$REPO" diff --no-renames --name-only "$remote_sha" "$local_sha" 2>/dev/null)
 
   if [ "$touched_ledger" -eq 1 ] && [ "$touched_dashboard" -eq 0 ]; then
     # GH-257 Task 4: check whether regenerating ROADMAP-DASHBOARD.md produces drift or no diff.
     # Run the diagnosis against a commit-pinned temporary projection of local_sha inside the
     # private GUARD_ROOT_PHYS so uncommitted working-tree modifications do not skew the classification.
     TMP_PROJ="$GUARD_ROOT_PHYS/proj-$local_sha"
     mkdir -p "$TMP_PROJ"
 
     drift_detected=1
+    render_err=""
     if git -C "$REPO" archive "$local_sha" 2>/dev/null | tar -x -C "$TMP_PROJ" 2>/dev/null \
        && [ -f "$TMP_PROJ/utils/roadmap-dashboard.sh" ]; then
-      if bash "$TMP_PROJ/utils/roadmap-dashboard.sh" --check >/dev/null 2>&1; then
+      # GH-474: KEEP the renderer's stderr. `--check` runs the full render before it reaches its
+      # mode branch (utils/roadmap-dashboard.sh — node render, then `if [[ "$MODE" == "check" ]]`),
+      # so the dropped-row warning it already emits is available here. Discarding it is what
+      # forced the no-drift arm below to infer the same fact from table names.
+      # `2>&1 >/dev/null` keeps stderr and drops stdout (order matters); the assignment carries
+      # the renderer's own exit status, so the drift verdict is unchanged.
+      if render_err="$(bash "$TMP_PROJ/utils/roadmap-dashboard.sh" --check 2>&1 >/dev/null)"; then
         drift_detected=0
       else
         drift_detected=1
       fi
     fi
 
     if [ "$drift_detected" -eq 1 ]; then
       cat >&2 <<'EOF'
 dashboard-staleness-guard: REFUSING the push — this range writes the roadmap ledger
 (releases.sql / releases.db) without regenerating ROADMAP-DASHBOARD.md, so the human-readable
 view would ship stale against the data under it (GH-243 / GH-169 item 3).
 
 Fix (one command, then commit the result into the same push):
     bash utils/roadmap-dashboard.sh && git add ROADMAP-DASHBOARD.md && git commit -m "docs: regenerate roadmap dashboard"
 
 Bypass (deliberately loud, e.g. a WIP branch): git push --no-verify
 EOF
     else
-      # The other legitimate no-diff case: a ledger change the dashboard cannot render.
-      # The renderer's only data input is `releases_app.py roadmap list --json`, a flat
-      # SELECT * FROM roadmap_items with no join or reference resolution — so roadmap_items
-      # is the ONLY projected table, and a write confined to anything else can never stale
-      # the view. Two write shapes are classified here, by their full dump fan-out:
-      #   jog     (GH-315) — jog_queue     + op_receipts + the settings generation counter
-      #   marathon         — marathons + issue_refs + op_receipts + that same counter
-      # `marathon add` creates the issue_refs row itself when the tracking URL is new, so the
-      # two tables must be allowed together or the refusal returns for any unseen issue.
-      # If every changed data line targets that set, allow; anything else keeps the
-      # dropped-row refusal below.
+      # No drift: the committed dashboard matches a fresh render. Exactly one hazard survives
+      # that — a roadmap row the renderer DROPPED. A dropped row renders to nothing, so the
+      # artifact still matches byte-for-byte while the ledger row is invisible in the view.
       #
-      # KNOWN GAP, deliberate: this is an allowlist, so the 8 remaining tables in the dump
-      # (doc_lines, grandfather_entries, legacy_lines, manifest_items, manifest_state_events,
-      # releases, repos, schema_migrations) still hit the catch-all and still produce the same
-      # FALSE refusal this arm exists to stop — a `releases add` will trip it. Enumerating
-      # tables is the wrong mechanism and is being replaced: the renderer already knows which
-      # rows it dropped and throws that away (see #474). Do not "simplify" this into a
-      # roadmap_items-only denylist in the meantime — that fails OPEN if the renderer ever
-      # gains a second projected table, where this fails closed.
-      projected_or_unknown_data=0
-      while IFS= read -r dline; do
-        case "$dline" in
-          '-'INSERT\ INTO\ jog_queue*|'+'INSERT\ INTO\ jog_queue*) ;;
-          '-'INSERT\ INTO\ marathons*|'+'INSERT\ INTO\ marathons*) ;;
-          '-'INSERT\ INTO\ issue_refs*|'+'INSERT\ INTO\ issue_refs*) ;;
-          '-'INSERT\ INTO\ op_receipts*|'+'INSERT\ INTO\ op_receipts*) ;;
-          *INSERT\ INTO\ settings*generation*) ;;
-          '-'INSERT\ INTO\ *|'+'INSERT\ INTO\ *) projected_or_unknown_data=1; break ;;
+      # GH-474: ASK the renderer instead of guessing. It already names every dropped row on
+      # stderr ("roadmap-dashboard: warning: dropped N unparseable row(s): <ids>", emitted from
+      # the droppedRows array), and $render_err above holds it. This replaces the GH-243/GH-315
+      # table-name allowlist, which had to infer the same fact from the dump's fan-out per write
+      # shape (jog, then marathon) and went short twice — 8 dump tables were still unclassified
+      # and still produced the FALSE refusal this arm exists to prevent.
+      #
+      # Direction of failure, deliberately: this reads the renderer's own report, so it cannot
+      # go short as a table list does. If the renderer is silent, the row rendered — allow.
+      dropped_line=""
+      while IFS= read -r eline; do
+        case "$eline" in
+          *"roadmap-dashboard: warning: dropped "*) dropped_line="$eline"; break ;;
         esac
-      done < <(git -C "$REPO" diff --no-renames "$remote_sha" "$local_sha" -- releases.sql 2>/dev/null)
-      if [ "$projected_or_unknown_data" -eq 0 ]; then
+      done <<EOF_ERR
+$render_err
+EOF_ERR
+      if [ -z "$dropped_line" ]; then
         continue
       fi
-      cat >&2 <<'EOF'
+      cat >&2 <<EOF
 dashboard-staleness-guard: REFUSING the push — this range writes the roadmap ledger
 (releases.sql / releases.db) without modifying ROADMAP-DASHBOARD.md, but regenerating the
 dashboard produces NO diff (GH-243 / GH-257).
 
-This happens when a parked row was dropped by the renderer (e.g. malformed raw_text).
-To diagnose:
-    bash utils/roadmap-dashboard.sh
-and inspect stderr for warnings on dropped rows. Correct the row with:
+The renderer dropped a roadmap row, so it contributes nothing to the view and the artifact
+still matches. It reported:
+    $dropped_line
+
+Correct the named row with:
     releases roadmap update --issue-num <N> --raw-text "- **GH-<N> · <title>** ..."
 then regenerate and commit:
     bash utils/roadmap-dashboard.sh && git add releases.db releases.sql ROADMAP-DASHBOARD.md && git commit -m "docs: fix roadmap row and regenerate dashboard"
 
 Bypass (deliberately loud, e.g. a WIP branch): git push --no-verify
 EOF
     fi
     exit 1
   fi
 done
 
 exit 0
     1	#!/usr/bin/env bash
     2	# dashboard-staleness-guard.sh — refuse a push whose range writes the roadmap ledger but not the
     3	# dashboard (GH-243, the enforcement half of GH-169 item 3).
     4	#
     5	# WHY: since the ROADMAP_SOURCE=releases flip, ROADMAP-DASHBOARD.md is the ONLY human-readable
     6	# view of the roadmap ledger — the DB is what every tool trusts, and nothing else re-renders the
     7	# view. A ledger write (releases.sql / releases.db) that ships without a dashboard regeneration
     8	# publishes a web/agent view that silently disagrees with the data under it.
     9	#
    10	# WHERE IT RUNS: called by githooks/pre-push with the same "<local_sha> <remote_sha>" ref pairs
    11	# the gate already parses — the push boundary is this repo's one wired, branch-independent
    12	# enforcement point (GH-549); a pre-commit hook would need a second stub wiring that does not
    13	# exist. Local commits stay free and ungated on purpose.
    14	#
    15	# SCOPE: applies only when the repo being pushed declares ROADMAP_SOURCE=releases in .pdda-mode.
    16	# Legacy-mode repos and branches predating the flip are untouched. A new branch (all-zero remote
    17	# sha) has no computable range; it falls through to the full gate like every other unclassifiable
    18	# push — this guard only ever ADDS a refusal, never replaces the gate.
    19	#
    20	# Usage: dashboard-staleness-guard.sh <repo_root> <local_sha> <remote_sha> [<local_sha> <remote_sha>...]
    21	# Exit:  0 ok (guard passed or not applicable) · 1 refuse the push · 2 usage.
    22	set -uo pipefail
    23	
    24	REPO="${1:-}"; shift || true
    25	[ -n "$REPO" ] && [ -d "$REPO" ] || { echo "dashboard-staleness-guard: usage: <repo_root> <local_sha> <remote_sha>..." >&2; exit 2; }
    26	
    27	grep -q "ROADMAP_SOURCE=releases" "$REPO/.pdda-mode" 2>/dev/null || exit 0
    28	
    29	SYS_TMP="$(cd -P "${TMPDIR:-/tmp}" 2>/dev/null && pwd -P)" || SYS_TMP="/tmp"
    30	GUARD_ROOT=""
    31	GUARD_ROOT_PHYS=""
    32	GUARD_INODE=""
    33	GUARD_DEV=""
    34	
    35	get_dev_inode() {
    36	  local target="$1"
    37	  # GNU coreutils spells --format as -c and uses -f for --file-system; BSD spells --format as -f.
    38	  # Probing BSD-first therefore SUCCEEDS on Linux for the wrong reason: `-f` is accepted, "%d %i"
    39	  # is read as a filename, and stdout gets a multi-line filesystem block instead of "<dev> <inode>".
    40	  # The caller's "${x%% *}" then yields an empty device and the guard reports an identity mismatch
    41	  # between two identical inodes. `-c` is not a BSD flag, so probing GNU-first fails cleanly there.
    42	  stat -c "%d %i" "$target" 2>/dev/null || stat -f "%d %i" "$target" 2>/dev/null || true
    43	}
    44	
    45	cleanup_guard() {
    46	  local exit_code=$?
    47	  [ -n "$GUARD_ROOT" ] || return "$exit_code"
    48	  [ -e "$GUARD_ROOT" ] || return "$exit_code"
    49	  if [ -L "$GUARD_ROOT" ]; then
    50	    echo "dashboard-staleness-guard: refusing cleanup — guard root is a symlink" >&2
    51	    exit 1
    52	  fi
    53	  local cur_phys
    54	  cur_phys="$(cd -P "$GUARD_ROOT" 2>/dev/null && pwd -P)" || {
    55	    echo "dashboard-staleness-guard: failed to resolve guard root physical path" >&2
    56	    exit 1
    57	  }
    58	  if [ -n "$GUARD_ROOT_PHYS" ] && [ "$cur_phys" != "$GUARD_ROOT_PHYS" ]; then
    59	    echo "dashboard-staleness-guard: refusing cleanup — guard root path drifted ($cur_phys != $GUARD_ROOT_PHYS)" >&2
    60	    exit 1
    61	  fi
    62	  local cur_dev_inode
    63	  cur_dev_inode="$(get_dev_inode "$cur_phys")"
    64	  local cur_dev="${cur_dev_inode%% *}"
    65	  local cur_inode="${cur_dev_inode##* }"
    66	  if [ -z "$GUARD_DEV" ] || [ -z "$GUARD_INODE" ] || [ -z "$cur_dev" ] || [ -z "$cur_inode" ] || \
    67	     [ "$cur_dev" != "$GUARD_DEV" ] || [ "$cur_inode" != "$GUARD_INODE" ]; then
    68	    echo "dashboard-staleness-guard: refusing cleanup — guard root identity mismatch ($cur_dev:$cur_inode != $GUARD_DEV:$GUARD_INODE)" >&2
    69	    exit 1
    70	  fi
    71	  case "$cur_phys" in
    72	    "$SYS_TMP"/*) rm -rf "$cur_phys" || exit 1 ;;
    73	    *) echo "dashboard-staleness-guard: refusing cleanup of non-descendant $cur_phys" >&2; exit 1 ;;
    74	  esac
    75	  return "$exit_code"
    76	}
    77	trap cleanup_guard EXIT INT TERM
    78	
    79	GUARD_ROOT="$(mktemp -d "$SYS_TMP/staleness-guard.XXXXXX")"
    80	[ -n "$GUARD_ROOT" ] || { echo "dashboard-staleness-guard: mktemp failed" >&2; exit 1; }
    81	
    82	GUARD_ROOT_PHYS="$(cd -P "$GUARD_ROOT" 2>/dev/null && pwd -P)" || GUARD_ROOT_PHYS=""
    83	[ -n "$GUARD_ROOT_PHYS" ] && [ -d "$GUARD_ROOT_PHYS" ] || { echo "dashboard-staleness-guard: failed to resolve guard root" >&2; exit 1; }
    84	case "$GUARD_ROOT_PHYS" in
    85	  "$SYS_TMP"/*) ;;
    86	  *) echo "dashboard-staleness-guard: guard root $GUARD_ROOT_PHYS is not a resolved descendant of $SYS_TMP" >&2; exit 1 ;;
    87	esac
    88	
    89	init_dev_inode="$(get_dev_inode "$GUARD_ROOT_PHYS")"
    90	GUARD_DEV="${init_dev_inode%% *}"
    91	GUARD_INODE="${init_dev_inode##* }"
    92	if [ -z "$GUARD_DEV" ] || [ -z "$GUARD_INODE" ]; then
    93	  echo "dashboard-staleness-guard: failed to establish guard root device/inode identity" >&2
    94	  exit 1
    95	fi
    96	
    97	while [ "$#" -ge 2 ]; do
    98	  local_sha="$1"; remote_sha="$2"; shift 2
    99	  case "$remote_sha" in
   100	    ''|0000000000000000000000000000000000000000) continue ;;   # new branch: no range to inspect
   101	  esac
   102	  git -C "$REPO" cat-file -e "${remote_sha}^{commit}" 2>/dev/null || continue
   103	
   104	  touched_ledger=0
   105	  touched_dashboard=0
   106	  while IFS= read -r path; do
   107	    case "$path" in
   108	      releases.sql|releases.db) touched_ledger=1 ;;
   109	      ROADMAP-DASHBOARD.md)     touched_dashboard=1 ;;
   110	    esac
   111	  done < <(git -C "$REPO" diff --no-renames --name-only "$remote_sha" "$local_sha" 2>/dev/null)
   112	
   113	  if [ "$touched_ledger" -eq 1 ] && [ "$touched_dashboard" -eq 0 ]; then
   114	    # GH-257 Task 4: check whether regenerating ROADMAP-DASHBOARD.md produces drift or no diff.
   115	    # Run the diagnosis against a commit-pinned temporary projection of local_sha inside the
   116	    # private GUARD_ROOT_PHYS so uncommitted working-tree modifications do not skew the classification.
   117	    TMP_PROJ="$GUARD_ROOT_PHYS/proj-$local_sha"
   118	    mkdir -p "$TMP_PROJ"
   119	
   120	    drift_detected=1
   121	    render_err=""
   122	    if git -C "$REPO" archive "$local_sha" 2>/dev/null | tar -x -C "$TMP_PROJ" 2>/dev/null \
   123	       && [ -f "$TMP_PROJ/utils/roadmap-dashboard.sh" ]; then
   124	      # GH-474: KEEP the renderer's stderr. `--check` runs the full render before it reaches its
   125	      # mode branch (utils/roadmap-dashboard.sh — node render, then `if [[ "$MODE" == "check" ]]`),
   126	      # so the dropped-row warning it already emits is available here. Discarding it is what
   127	      # forced the no-drift arm below to infer the same fact from table names.
   128	      # `2>&1 >/dev/null` keeps stderr and drops stdout (order matters); the assignment carries
   129	      # the renderer's own exit status, so the drift verdict is unchanged.
   130	      if render_err="$(bash "$TMP_PROJ/utils/roadmap-dashboard.sh" --check 2>&1 >/dev/null)"; then
   131	        drift_detected=0
   132	      else
   133	        drift_detected=1
   134	      fi
   135	    fi
   136	
   137	    if [ "$drift_detected" -eq 1 ]; then
   138	      cat >&2 <<'EOF'
   139	dashboard-staleness-guard: REFUSING the push — this range writes the roadmap ledger
   140	(releases.sql / releases.db) without regenerating ROADMAP-DASHBOARD.md, so the human-readable
   141	view would ship stale against the data under it (GH-243 / GH-169 item 3).
   142	
   143	Fix (one command, then commit the result into the same push):
   144	    bash utils/roadmap-dashboard.sh && git add ROADMAP-DASHBOARD.md && git commit -m "docs: regenerate roadmap dashboard"
   145	
   146	Bypass (deliberately loud, e.g. a WIP branch): git push --no-verify
   147	EOF
   148	    else
   149	      # No drift: the committed dashboard matches a fresh render. Exactly one hazard survives
   150	      # that — a roadmap row the renderer DROPPED. A dropped row renders to nothing, so the
   151	      # artifact still matches byte-for-byte while the ledger row is invisible in the view.
   152	      #
   153	      # GH-474: ASK the renderer instead of guessing. It already names every dropped row on
   154	      # stderr ("roadmap-dashboard: warning: dropped N unparseable row(s): <ids>", emitted from
   155	      # the droppedRows array), and $render_err above holds it. This replaces the GH-243/GH-315
   156	      # table-name allowlist, which had to infer the same fact from the dump's fan-out per write
   157	      # shape (jog, then marathon) and went short twice — 8 dump tables were still unclassified
   158	      # and still produced the FALSE refusal this arm exists to prevent.
   159	      #
   160	      # Direction of failure, deliberately: this reads the renderer's own report, so it cannot
   161	      # go short as a table list does. If the renderer is silent, the row rendered — allow.
   162	      dropped_line=""
   163	      while IFS= read -r eline; do
   164	        case "$eline" in
   165	          *"roadmap-dashboard: warning: dropped "*) dropped_line="$eline"; break ;;
   166	        esac
   167	      done <<EOF_ERR
   168	$render_err
   169	EOF_ERR
   170	      if [ -z "$dropped_line" ]; then
   171	        continue
   172	      fi
   173	      cat >&2 <<EOF
   174	dashboard-staleness-guard: REFUSING the push — this range writes the roadmap ledger
   175	(releases.sql / releases.db) without modifying ROADMAP-DASHBOARD.md, but regenerating the
   176	dashboard produces NO diff (GH-243 / GH-257).
   177	
   178	The renderer dropped a roadmap row, so it contributes nothing to the view and the artifact
   179	still matches. It reported:
   180	    $dropped_line
   181	
   182	Correct the named row with:
   183	    releases roadmap update --issue-num <N> --raw-text "- **GH-<N> · <title>** ..."
   184	then regenerate and commit:
   185	    bash utils/roadmap-dashboard.sh && git add releases.db releases.sql ROADMAP-DASHBOARD.md && git commit -m "docs: fix roadmap row and regenerate dashboard"
   186	
   187	Bypass (deliberately loud, e.g. a WIP branch): git push --no-verify
   188	EOF
   189	    fi
   190	    exit 1
   191	  fi
   192	done
   193	
   194	exit 0
     1	#!/usr/bin/env bash
     2	# utils/roadmap-dashboard.sh — render a read-only dashboard from ROADMAP.md (GH-27).
     3	
     4	set -euo pipefail
     5	
     6	HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
     7	# GH-272: releases-merge-resolve.sh drives this renderer against a --root TARGET repo —
     8	# the ledger it renders and the dashboard it writes must follow the target, not this
     9	# script's own checkout. Self-location stays the default for every other caller.
    10	ROOT="${ROADMAP_DASHBOARD_ROOT:-$(cd "$HERE/.." && pwd)}"
    11	SOURCE_FILE="${ROADMAP_DASHBOARD_SOURCE:-"$ROOT/ROADMAP.md"}"
    12	OUTPUT_FILE="${ROADMAP_DASHBOARD_OUTPUT:-"$ROOT/ROADMAP-DASHBOARD.md"}"
    13	
    14	usage() {
    15	  cat <<'EOF'
    16	Usage: bash utils/roadmap-dashboard.sh [--check]
    17	
    18	  Default: render ROADMAP-DASHBOARD.md from the canonical root ROADMAP.md.
    19	  --check: exit 0 when ROADMAP-DASHBOARD.md is in sync; non-zero on drift.
    20	EOF
    21	}
    22	
    23	MODE="write"
    24	if (($# > 1)); then
    25	  usage
    26	  exit 2
    27	fi
    28	if (($# == 1)); then
    29	  case "$1" in
    30	    --check) MODE="check" ;;
    31	    --help|-h) usage; exit 0 ;;
    32	    *) usage; exit 2 ;;
    33	  esac
    34	fi
    35	
    36	command -v node >/dev/null 2>&1 || {
    37	  echo "roadmap-dashboard: node is required" >&2
    38	  exit 2
    39	}
    40	
    41	TMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/roadmap-dashboard.XXXXXX")"
    42	trap 'rm -rf "$TMP_DIR"' EXIT
    43	RENDERED="$TMP_DIR/ROADMAP-DASHBOARD.md"
    44	
    45	# GH-243: in a releases-mode repo the DB is the roadmap's source of truth and ROADMAP.md is
    46	# frozen — render from `roadmap list --json` (each row's lossless raw_text under its section)
    47	# instead of the legacy file. An explicit ROADMAP_DASHBOARD_SOURCE still wins (test seam), and
    48	# any failure here falls back to the legacy file rather than emitting an empty dashboard.
    49	if [ -z "${ROADMAP_DASHBOARD_SOURCE:-}" ] \
    50	   && (grep -q "ROADMAP_SOURCE=releases" "$ROOT/.pdda-mode" 2>/dev/null || [ ! -f "$ROOT/ROADMAP.md" ]) \
    51	   && [ -f "$ROOT/releases.db" ] && command -v python3 >/dev/null 2>&1; then
    52	  DB_SRC="$TMP_DIR/roadmap-from-db.md"
    53	  DB_JSON="$TMP_DIR/roadmap-rows.json"
    54	  # JSON goes through a temp file passed as argv — `python3 -` takes its PROGRAM from the
    55	  # heredoc on stdin, so piping data in as well would feed the parser nothing (the PR #240
    56	  # rollup.sh bug, same shape). The APP resolves from HERE (this script's own checkout) while
    57	  # --root follows $ROOT: under ROADMAP_DASHBOARD_ROOT (GH-272) the target repo may ship the
    58	  # ledger without a utils/ tree at all.
    59	  if python3 "$HERE/py/releases_app.py" --root "$ROOT" roadmap list --json > "$DB_JSON" 2>/dev/null \
    60	     && python3 - "$DB_JSON" > "$DB_SRC" <<'PY'
    61	import json, sys
    62	with open(sys.argv[1]) as f:
    63	    rows = json.load(f)
    64	print("# ROADMAP (rendered from the RELEASES DB — GH-243; ROADMAP.md is frozen legacy)\n")
    65	print("## Ledger\n")   # the renderer only counts sections below this heading
    66	sections = {}
    67	for r in rows:
    68	    sections.setdefault(r.get("section") or "(unsectioned)", []).append(r)
    69	for section, items in sections.items():
    70	    print(f"### {section}\n")
    71	    for r in sorted(items, key=lambda x: x.get("position") or 0):
    72	        line = (r.get("raw_text") or "").strip()
    73	        if not line:
    74	            gh = f"GH-{r['gh_number']} · " if r.get("gh_number") is not None else ""
    75	            line = f"- **{gh}{r.get('title', '')}**"
    76	        print(line)
    77	    print()
    78	PY
    79	  then
    80	    [ -s "$DB_SRC" ] && SOURCE_FILE="$DB_SRC"
    81	  fi
    82	fi
    83	
    84	if [ ! -f "$SOURCE_FILE" ]; then
    85	  echo "roadmap-dashboard: source not found: $SOURCE_FILE" >&2
    86	  exit 3
    87	fi
    88	
    89	node - "$SOURCE_FILE" >"$RENDERED" <<'NODE'
    90	const fs = require("fs");
    91	
    92	const sourcePath = process.argv[2];
    93	const raw = fs.readFileSync(sourcePath, "utf8");
    94	const lines = raw.split(/\r?\n/);
    95	
    96	const banner = "<!-- GENERATED by utils/roadmap-dashboard.sh — DO NOT EDIT; edit ROADMAP.md -->";
    97	const ledgerSections = [
    98	  "Queue / parked intake",
    99	  "Queue",              // GH-243: early `releases roadmap add` rows parked under the short name
   100	  "In progress",
   101	  "Completed",
   102	  "Deferred · vision",
   103	];
   104	const knownStatuses = ["🟢", "🟡", "⏸️", "⛔", "✅", "🔮", "🔲"];
   105	const extraStatuses = ["⚠️"];
   106	
   107	function escapeCell(value) {
   108	  return String(value)
   109	    .replace(/\|/g, "\\|")
   110	    .replace(/</g, "&lt;")
   111	    .replace(/>/g, "&gt;");
   112	}
   113	
   114	function stripMarkdown(value) {
   115	  return value
   116	    .replace(/`([^`]+)`/g, "$1")
   117	    .replace(/\*\*([^*]+)\*\*/g, "$1")
   118	    .replace(/\*([^*]+)\*/g, "$1")
   119	    .replace(/\[([^\]]+)\]\(([^)]+)\)/g, "$1")
   120	    .trim();
   121	}
   122	
   123	function parseBullet(block) {
   124	  const text = block.map((line) => line.trim()).join(" ").replace(/\s+/g, " ").trim();
   125	  const titleMatch = text.match(/^- \*\*(.+?)\*\*/);
   126	  const title = titleMatch ? stripMarkdown(titleMatch[1]) : stripMarkdown(text.replace(/^- /, ""));
   127	
   128	  let status = "—";
   129	  for (const emoji of knownStatuses.concat(extraStatuses)) {
   130	    if (text.includes(emoji)) {
   131	      status = emoji;
   132	      break;
   133	    }
   134	  }
   135	
   136	  const links = [];
   137	  const linkPattern = /\[([^\]]+)\]\(([^)]+)\)/g;
   138	  let match;
   139	  while ((match = linkPattern.exec(text)) !== null) {
   140	    links.push(`[${match[1]}](${match[2]})`);
   141	  }
   142	
   143	  return { title, status, links };
   144	}
   145	
   146	function formatTally(items) {
   147	  const counts = new Map();
   148	  for (const emoji of knownStatuses) counts.set(emoji, 0);
   149	  const extras = [];
   150	
   151	  for (const item of items) {
   152	    if (counts.has(item.status)) {
   153	      counts.set(item.status, counts.get(item.status) + 1);
   154	      continue;
   155	    }
   156	    if (item.status !== "—") {
   157	      if (!counts.has(item.status)) extras.push(item.status);
   158	      counts.set(item.status, (counts.get(item.status) || 0) + 1);
   159	    }
   160	  }
   161	
   162	  const ordered = knownStatuses.slice();
   163	  for (const emoji of extras) {
   164	    if (!ordered.includes(emoji)) ordered.push(emoji);
   165	  }
   166	
   167	  return ordered.map((emoji) => `${emoji} ${counts.get(emoji) || 0}`).join(" · ");
   168	}
   169	
   170	const sections = new Map();
   171	for (const heading of ledgerSections) sections.set(heading, []);
   172	
   173	let inLedger = false;
   174	let currentSection = null;
   175	const droppedRows = [];
   176	
   177	for (let i = 0; i < lines.length; i++) {
   178	  const line = lines[i];
   179	
   180	  if (!inLedger) {
   181	    if (/^##\s+Ledger\s*$/.test(line.trim())) inLedger = true;
   182	    continue;
   183	  }
   184	
   185	  if (/^##\s+/.test(line) && !/^##\s+Ledger\s*$/.test(line.trim())) break;
   186	
   187	  const sectionMatch = line.match(/^###\s+(.+?)\s*$/);
   188	  if (sectionMatch) {
   189	    const heading = sectionMatch[1].trim();
   190	    currentSection = sections.has(heading) ? heading : null;
   191	    continue;
   192	  }
   193	
   194	  if (!currentSection) continue;
   195	
   196	  const trimmed = line.trim();
   197	  if (!trimmed || trimmed.startsWith("<!--") || trimmed.startsWith("#")) continue;
   198	
   199	  if (!/^- \*\*[^\r\n*]+?\*\*/.test(line)) {
   200	    // GH-257: track non-empty dropped/unparseable line under an active ledger section
   201	    const issueMatch = trimmed.match(/(?:GH-?|#)(\d+)/i);
   202	    const id = issueMatch ? `#${issueMatch[1]}` : JSON.stringify(trimmed.length > 30 ? trimmed.slice(0, 30) + "..." : trimmed);
   203	    droppedRows.push({ section: currentSection, id, line: trimmed });
   204	    continue;
   205	  }
   206	
   207	  const block = [line];
   208	  while (i + 1 < lines.length) {
   209	    const next = lines[i + 1];
   210	    if (/^###\s+/.test(next) || /^##\s+/.test(next) || /^\s*[-*+]\s+/.test(next)) break;
   211	    block.push(next);
   212	    i += 1;
   213	  }
   214	  sections.get(currentSection).push(parseBullet(block));
   215	}
   216	
   217	if (droppedRows.length > 0) {
   218	  const ids = droppedRows.map((d) => d.id).join(", ");
   219	  process.stderr.write(`roadmap-dashboard: warning: dropped ${droppedRows.length} unparseable row(s): ${ids}\n`);
   220	}
   221	
   222	const output = [];
   223	output.push(banner);
   224	output.push("");
   225	output.push("# ROADMAP Dashboard");
   226	output.push("");
   227	output.push("Read-only derived view of the root [ROADMAP.md](ROADMAP.md) ledger.");
   228	output.push("");
   229	
   230	for (const heading of ledgerSections) {
   231	  const items = sections.get(heading) || [];
   232	  output.push(`## ${heading}`);
   233	  output.push("");
   234	  output.push(`Summary: ${items.length} items | Tally: ${formatTally(items)}`);
   235	  output.push("");
   236	  output.push("| Item | Status | Links |");
   237	  output.push("| --- | --- | --- |");
   238	  for (const item of items) {
   239	    const links = item.links.length > 0 ? item.links.join(" · ") : "—";
   240	    output.push(`| ${escapeCell(item.title)} | ${escapeCell(item.status)} | ${links} |`);
   241	  }
   242	  if (items.length === 0) {
   243	    output.push("| — | — | — |");
   244	  }
   245	  output.push("");
   246	}
   247	
   248	process.stdout.write(output.join("\n"));
   249	NODE
   250	
   251	if [[ "$MODE" == "check" ]]; then
   252	  if [[ ! -f "$OUTPUT_FILE" ]]; then
   253	    echo "roadmap-dashboard: missing artifact: $OUTPUT_FILE" >&2
   254	    exit 1
   255	  fi
   256	  if cmp -s "$RENDERED" "$OUTPUT_FILE"; then
   257	    echo "roadmap-dashboard: artifact is in sync"
   258	    exit 0
   259	  fi
   260	  echo "roadmap-dashboard: artifact drift detected: $OUTPUT_FILE" >&2
   261	  diff -u "$OUTPUT_FILE" "$RENDERED" || true
   262	  exit 1
   263	fi
   264	
   265	cp "$RENDERED" "$OUTPUT_FILE"
   266	echo "roadmap-dashboard: wrote $OUTPUT_FILE"

exec
/bin/zsh -lc "git branch --show-current; git diff --unified=30 development -- githooks/dashboard-staleness-guard.sh; printf '\\n--- check consumers ---\\n'; rg -n -U '(roadmap-dashboard\\.sh["'^'"\\n]*(\\\\| )--check|--check["'^'"\\n]*(\\\\| )?roadmap-dashboard\\.sh)' --glob '"'!temp/**'"' .; printf '\\n--- focused tests ---\\n'; nl -ba test/gh243-dashboard-staleness-guard.sh | sed -n '1,420p'; nl -ba test/gh257-roadmap-ledger-fixes.sh | sed -n '1,520p'; printf '\\n--- specified consumer sections ---\\n'; nl -ba test/gh269-roadmap-retired.sh | sed -n '1,80p'; nl -ba test/gh280-jog-marathon-adapter.sh | sed -n '990,1050p'; nl -ba test/gh57-live-merge-resolve.sh | sed -n '270,310p'; nl -ba test/roadmap-dashboard.sh | sed -n '1,75p'" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-33750-j8h2ug9_
 succeeded in 5535ms:
2026-09-07 13:14:17.914 xcodebuild[54267:4454000]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-09-07 13:14:18.132 xcodebuild[54267:4453957] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.
git: warning: confstr() failed with code 5: couldn't get path of DARWIN_USER_TEMP_DIR; using /tmp instead
git: error: couldn't create cache file '/tmp/xcrun_db-DJ3fGNBr' (errno=Operation not permitted)
2026-09-07 13:14:18.766 xcodebuild[54867:4454949]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-09-07 13:14:19.256 xcodebuild[54867:4454910] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.
git: warning: confstr() failed with code 5: couldn't get path of DARWIN_USER_TEMP_DIR; using /tmp instead
git: error: couldn't create cache file '/tmp/xcrun_db-WdOCQO4U' (errno=Operation not permitted)
2026-09-07 13:14:20.918 xcodebuild[55576:4456211]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-09-07 13:14:21.141 xcodebuild[55576:4456163] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.
git: warning: confstr() failed with code 5: couldn't get path of DARWIN_USER_TEMP_DIR; using /tmp instead
git: error: couldn't create cache file '/tmp/xcrun_db-d5TQ1AEp' (errno=Operation not permitted)
2026-09-07 13:14:21.765 xcodebuild[56139:4457045]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-09-07 13:14:21.975 xcodebuild[56139:4456994] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.
diff --git a/githooks/dashboard-staleness-guard.sh b/githooks/dashboard-staleness-guard.sh
index 81524e29..3f481b3a 100755
--- a/githooks/dashboard-staleness-guard.sh
+++ b/githooks/dashboard-staleness-guard.sh
@@ -91,106 +91,104 @@ GUARD_DEV="${init_dev_inode%% *}"
 GUARD_INODE="${init_dev_inode##* }"
 if [ -z "$GUARD_DEV" ] || [ -z "$GUARD_INODE" ]; then
   echo "dashboard-staleness-guard: failed to establish guard root device/inode identity" >&2
   exit 1
 fi
 
 while [ "$#" -ge 2 ]; do
   local_sha="$1"; remote_sha="$2"; shift 2
   case "$remote_sha" in
     ''|0000000000000000000000000000000000000000) continue ;;   # new branch: no range to inspect
   esac
   git -C "$REPO" cat-file -e "${remote_sha}^{commit}" 2>/dev/null || continue
 
   touched_ledger=0
   touched_dashboard=0
   while IFS= read -r path; do
     case "$path" in
       releases.sql|releases.db) touched_ledger=1 ;;
       ROADMAP-DASHBOARD.md)     touched_dashboard=1 ;;
     esac
   done < <(git -C "$REPO" diff --no-renames --name-only "$remote_sha" "$local_sha" 2>/dev/null)
 
   if [ "$touched_ledger" -eq 1 ] && [ "$touched_dashboard" -eq 0 ]; then
     # GH-257 Task 4: check whether regenerating ROADMAP-DASHBOARD.md produces drift or no diff.
     # Run the diagnosis against a commit-pinned temporary projection of local_sha inside the
     # private GUARD_ROOT_PHYS so uncommitted working-tree modifications do not skew the classification.
     TMP_PROJ="$GUARD_ROOT_PHYS/proj-$local_sha"
     mkdir -p "$TMP_PROJ"
 
     drift_detected=1
+    render_err=""
     if git -C "$REPO" archive "$local_sha" 2>/dev/null | tar -x -C "$TMP_PROJ" 2>/dev/null \
        && [ -f "$TMP_PROJ/utils/roadmap-dashboard.sh" ]; then
-      if bash "$TMP_PROJ/utils/roadmap-dashboard.sh" --check >/dev/null 2>&1; then
+      # GH-474: KEEP the renderer's stderr. `--check` runs the full render before it reaches its
+      # mode branch (utils/roadmap-dashboard.sh — node render, then `if [[ "$MODE" == "check" ]]`),
+      # so the dropped-row warning it already emits is available here. Discarding it is what
+      # forced the no-drift arm below to infer the same fact from table names.
+      # `2>&1 >/dev/null` keeps stderr and drops stdout (order matters); the assignment carries
+      # the renderer's own exit status, so the drift verdict is unchanged.
+      if render_err="$(bash "$TMP_PROJ/utils/roadmap-dashboard.sh" --check 2>&1 >/dev/null)"; then
         drift_detected=0
       else
         drift_detected=1
       fi
     fi
 
     if [ "$drift_detected" -eq 1 ]; then
       cat >&2 <<'EOF'
 dashboard-staleness-guard: REFUSING the push — this range writes the roadmap ledger
 (releases.sql / releases.db) without regenerating ROADMAP-DASHBOARD.md, so the human-readable
 view would ship stale against the data under it (GH-243 / GH-169 item 3).
 
 Fix (one command, then commit the result into the same push):
     bash utils/roadmap-dashboard.sh && git add ROADMAP-DASHBOARD.md && git commit -m "docs: regenerate roadmap dashboard"
 
 Bypass (deliberately loud, e.g. a WIP branch): git push --no-verify
 EOF
     else
-      # The other legitimate no-diff case: a ledger change the dashboard cannot render.
-      # The renderer's only data input is `releases_app.py roadmap list --json`, a flat
-      # SELECT * FROM roadmap_items with no join or reference resolution — so roadmap_items
-      # is the ONLY projected table, and a write confined to anything else can never stale
-      # the view. Two write shapes are classified here, by their full dump fan-out:
-      #   jog     (GH-315) — jog_queue     + op_receipts + the settings generation counter
-      #   marathon         — marathons + issue_refs + op_receipts + that same counter
-      # `marathon add` creates the issue_refs row itself when the tracking URL is new, so the
-      # two tables must be allowed together or the refusal returns for any unseen issue.
-      # If every changed data line targets that set, allow; anything else keeps the
-      # dropped-row refusal below.
+      # No drift: the committed dashboard matches a fresh render. Exactly one hazard survives
+      # that — a roadmap row the renderer DROPPED. A dropped row renders to nothing, so the
+      # artifact still matches byte-for-byte while the ledger row is invisible in the view.
       #
-      # KNOWN GAP, deliberate: this is an allowlist, so the 8 remaining tables in the dump
-      # (doc_lines, grandfather_entries, legacy_lines, manifest_items, manifest_state_events,
-      # releases, repos, schema_migrations) still hit the catch-all and still produce the same
-      # FALSE refusal this arm exists to stop — a `releases add` will trip it. Enumerating
-      # tables is the wrong mechanism and is being replaced: the renderer already knows which
-      # rows it dropped and throws that away (see #474). Do not "simplify" this into a
-      # roadmap_items-only denylist in the meantime — that fails OPEN if the renderer ever
-      # gains a second projected table, where this fails closed.
-      projected_or_unknown_data=0
-      while IFS= read -r dline; do
-        case "$dline" in
-          '-'INSERT\ INTO\ jog_queue*|'+'INSERT\ INTO\ jog_queue*) ;;
-          '-'INSERT\ INTO\ marathons*|'+'INSERT\ INTO\ marathons*) ;;
-          '-'INSERT\ INTO\ issue_refs*|'+'INSERT\ INTO\ issue_refs*) ;;
-          '-'INSERT\ INTO\ op_receipts*|'+'INSERT\ INTO\ op_receipts*) ;;
-          *INSERT\ INTO\ settings*generation*) ;;
-          '-'INSERT\ INTO\ *|'+'INSERT\ INTO\ *) projected_or_unknown_data=1; break ;;
+      # GH-474: ASK the renderer instead of guessing. It already names every dropped row on
+      # stderr ("roadmap-dashboard: warning: dropped N unparseable row(s): <ids>", emitted from
+      # the droppedRows array), and $render_err above holds it. This replaces the GH-243/GH-315
+      # table-name allowlist, which had to infer the same fact from the dump's fan-out per write
+      # shape (jog, then marathon) and went short twice — 8 dump tables were still unclassified
+      # and still produced the FALSE refusal this arm exists to prevent.
+      #
+      # Direction of failure, deliberately: this reads the renderer's own report, so it cannot
+      # go short as a table list does. If the renderer is silent, the row rendered — allow.
+      dropped_line=""
+      while IFS= read -r eline; do
+        case "$eline" in
+          *"roadmap-dashboard: warning: dropped "*) dropped_line="$eline"; break ;;
         esac
-      done < <(git -C "$REPO" diff --no-renames "$remote_sha" "$local_sha" -- releases.sql 2>/dev/null)
-      if [ "$projected_or_unknown_data" -eq 0 ]; then
+      done <<EOF_ERR
+$render_err
+EOF_ERR
+      if [ -z "$dropped_line" ]; then
         continue
       fi
-      cat >&2 <<'EOF'
+      cat >&2 <<EOF
 dashboard-staleness-guard: REFUSING the push — this range writes the roadmap ledger
 (releases.sql / releases.db) without modifying ROADMAP-DASHBOARD.md, but regenerating the
 dashboard produces NO diff (GH-243 / GH-257).
 
-This happens when a parked row was dropped by the renderer (e.g. malformed raw_text).
-To diagnose:
-    bash utils/roadmap-dashboard.sh
-and inspect stderr for warnings on dropped rows. Correct the row with:
+The renderer dropped a roadmap row, so it contributes nothing to the view and the artifact
+still matches. It reported:
+    $dropped_line
+
+Correct the named row with:
     releases roadmap update --issue-num <N> --raw-text "- **GH-<N> · <title>** ..."
 then regenerate and commit:
     bash utils/roadmap-dashboard.sh && git add releases.db releases.sql ROADMAP-DASHBOARD.md && git commit -m "docs: fix roadmap row and regenerate dashboard"
 
 Bypass (deliberately loud, e.g. a WIP branch): git push --no-verify
 EOF
     fi
     exit 1
   fi
 done
 
 exit 0

--- check consumers ---
./relay-system/2026-08-17/consult-130916/consult.codex.md:1153:- **GH-351 · the registered dashboard gate graded its own answer key** ✅ **done (2026-07-30)** — `test/roadmap-dashboard.sh` rendered the dashboard **into the repo** and then `--check`ed the copy it had just written, so its drift assertion could never fail; its own pass string read *"--check passes on the committed artifact"*, which was false by the time it ran. **The renderer was never the defect** — standalone `utils/roadmap-dashboard.sh --check` returned `rc=1` on all three of the day's stale dashboards, so the correct signal existed the whole time and the test overwrote its input before asking. A second, quieter fault: the test **wrote into `$ROOT`**, so `validate.sh` silently un-staled the dashboard mid-run — a suite repairing the evidence it was meant to judge, and leaving the tree dirty. Three stale dashboards reached `development` on 2026-07-30 alone from three different authors (GH-342, #356, #350); it fires on essentially every ROADMAP-touching PR. Fixed by two rules: `--check` runs **first** against the **committed** artifact, and nothing writes `$ROOT` (write-mode goes through `ROADMAP_DASHBOARD_OUTPUT`, which the renderer already supported — no renderer change). **4 → 9 cases**, including a mutation proof (case 4 plants a canary and requires `--check` to reject it, since cases 1 and 3 are unfalsifiable alone) and a no-side-effect assertion. **Verified against the real commit, not a synthetic fixture:** replaying `719867f`, the old test scores **4 pass / 0 fail** on a genuinely stale dashboard while the new one scores **6 pass / 3 fail**. Two findings only visible by running it — the old test left `ROADMAP-DASHBOARD.md` modified afterwards, and **case 9 (section counts) was already correct and still reported green**, because the regeneration ran first: the bug did not add a bad assertion, it *disabled a good one*. Sixth instance of *an assertion that compares a thing to a freshly-derived copy of itself* after #348/#342/#362(B)/#369. cx/risk/eff 2/2/2. → [GH-351-DASHBOARD-TEST-GRADES-ITS-OWN-ANSWER-KEY.md](PROJECT/3-COMPLETED/GH-351-DASHBOARD-TEST-GRADES-ITS-OWN-ANSWER-KEY.md) · [#351](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/351)
./relay-system/2026-09-07/gh485-dropped-row-signal-131345/gh485-dropped-row-signal.PROMPT.txt:32:   `render_err="$(bash "$TMP_PROJ/utils/roadmap-dashboard.sh" --check 2>&1 >/dev/null)"`
./relay-system/2026-09-07/gh485-dropped-row-signal-131345/gh485-dropped-row-signal.PROMPT.txt:41:1. **Is the premise true?** Does `utils/roadmap-dashboard.sh --check` really emit
./relay-system/2026-09-07/gh474-md-views-101147/gh474-md-views.PROMPT.txt:50:**B. Keep the views; fix #474 properly.** Give `roadmap-dashboard.sh --check` a distinct
./relay-system/2026-09-07/gh474-md-views-101147/gh474-md-views.codex.md:73:**B. Keep the views; fix #474 properly.** Give `roadmap-dashboard.sh --check` a distinct
./relay-system/2026-09-07/gh474-md-views-101147/gh474-md-views.codex.md:800:      if bash "$TMP_PROJ/utils/roadmap-dashboard.sh" --check >/dev/null 2>&1; then
./relay-system/2026-09-07/gh474-md-views-101147/gh474-md-views.codex.md:952:test/roadmap-dashboard.sh:4:# GH-351: this file used to render the dashboard INTO THE REPO and then --check the copy it had
./relay-system/2026-09-07/gh474-md-views-101147/gh474-md-views.codex.md:957:test/roadmap-dashboard.sh-9-#   1. --check runs FIRST, against the COMMITTED artifact, before anything in this file writes.
./relay-system/2026-09-07/gh474-md-views-101147/gh474-md-views.codex.md:961:test/roadmap-dashboard.sh-13-# Case 4 is the one that keeps this honest: it proves --check ACTUALLY FAILS on a drifted
./relay-system/2026-09-07/gh474-md-views-101147/gh474-md-views.codex.md:1012:test/roadmap-dashboard.sh-101-  out="$(ROADMAP_DASHBOARD_SOURCE="$drift_src" ROADMAP_DASHBOARD_OUTPUT="$ARTIFACT" bash "$RENDERER" --check 2>&1)"; rc=$?
./relay-system/2026-09-07/gh474-md-views-101147/gh474-md-views.codex.md:1039:test/roadmap-dashboard.sh-128-# no longer an invariant. Cases 1/3/4/6 already pin artifact-vs-live-source fidelity via --check
./relay-system/2026-09-07/gh474-md-views-101147/gh474-md-views.codex.md:1042:test/roadmap-dashboard.sh:131:  pass "case 9 skipped: releases-mode — dashboard parity is against the DB (covered by --check), not the frozen ROADMAP.md"
./relay-system/2026-09-07/gh474-md-views-101147/gh474-md-views.codex.md:1538:utils/roadmap-dashboard.sh:19:  --check: exit 0 when ROADMAP-DASHBOARD.md is in sync; non-zero on drift.
./relay-system/2026-09-07/gh474-md-views-101147/gh474-md-views.codex.md:1662:utils/roadmap-dashboard.sh:19:  --check: exit 0 when ROADMAP-DASHBOARD.md is in sync; non-zero on drift.
./relay-system/2026-09-07/gh474-md-views-101147/gh474-md-views.codex.md:1663:utils/roadmap-dashboard.sh:30:    --check) MODE="check" ;;
./relay-system/2026-09-07/gh474-md-views-101147/gh474-md-views.codex.md:2918:./utils/roadmap-dashboard.sh:19:  --check: exit 0 when ROADMAP-DASHBOARD.md is in sync; non-zero on drift.
./relay-system/2026-09-07/gh474-md-views-101147/gh474-md-views.codex.md:3843:./PROJECT/3-COMPLETED/GH-144-AGENT2AGENT-3PLUS-UX.md:60:- `bash utils/roadmap-dashboard.sh --check`
./relay-system/2026-09-07/gh474-md-views-101147/gh474-md-views.codex.md:4087:./test/gh280-jog-marathon-adapter.sh:1021:bash "$FR/utils/roadmap-dashboard.sh" --check >/dev/null 2>&1 \
./relay-system/2026-09-07/gh474-md-views-101147/gh474-md-views.codex.md:4093:./test/gh280-jog-marathon-adapter.sh:1033:bash "$FR/utils/roadmap-dashboard.sh" --check >/dev/null 2>&1 \
./relay-system/2026-09-07/gh474-md-views-101147/gh474-md-views.codex.md:4143:./relay-system/2026-08-17/consult-130916/consult.codex.md:1153:- **GH-351 · the registered dashboard gate graded its own answer key** ✅ **done (2026-07-30)** — `test/roadmap-dashboard.sh` rendered the dashboard **into the repo** and then `--check`ed the copy it had just written, so its drift assertion could never fail; its own pass string read *"--check passes on the committed artifact"*, which was false by the time it ran. **The renderer was never the defect** — standalone `utils/roadmap-dashboard.sh --check` returned `rc=1` on all three of the day's stale dashboards, so the correct signal existed the whole time and the test overwrote its input before asking. A second, quieter fault: the test **wrote into `$ROOT`**, so `validate.sh` silently un-staled the dashboard mid-run — a suite repairing the evidence it was meant to judge, and leaving the tree dirty. Three stale dashboards reached `development` on 2026-07-30 alone from three different authors (GH-342, #356, #350); it fires on ess
./relay-system/2026-09-07/gh474-md-views-101147/gh474-md-views.codex.md:4287:./relay-system/2026-09-07/gh474-md-views-101147/gh474-md-views.PROMPT.txt:50:**B. Keep the views; fix #474 properly.** Give `roadmap-dashboard.sh --check` a distinct
./relay-system/2026-09-07/gh474-md-views-101147/gh474-md-views.codex.md:4503:./test/gh57-live-merge-resolve.sh:290:   "ROADMAP_DASHBOARD_ROOT='$R8' bash '$ROOT_DIR/utils/roadmap-dashboard.sh' --check"
./relay-system/2026-09-07/gh474-md-views-101147/gh474-md-views.codex.md:5325:./relay-system/2026-09-06/gh243-marathon-allowlist-173919/gh243-marathon-allowlist.codex.md:349:   123	      if bash "$TMP_PROJ/utils/roadmap-dashboard.sh" --check >/dev/null 2>&1; then
./relay-system/2026-09-07/gh474-md-views-101147/gh474-md-views.codex.md:5429:./relay-system/2026-09-06/gh243-marathon-allowlist-173919/gh243-marathon-allowlist.codex.md:1241:utils/roadmap-dashboard.sh:19:  --check: exit 0 when ROADMAP-DASHBOARD.md is in sync; non-zero on drift.
./relay-system/2026-09-07/gh474-md-views-101147/gh474-md-views.codex.md:5743:./relay-system/2026-08-26/relay-gh257-roadmap-ledger-qa.md:71:   the decisive `roadmap-dashboard.sh --check` at `:48-54` reads the current checkout rather than
./relay-system/2026-09-07/gh474-md-views-101147/gh474-md-views.codex.md:5912:./relay-system/2026-09-06/gh243-marathon-codex-retry-174442/gh243-marathon-codex-retry.codex.md:802:   123	      if bash "$TMP_PROJ/utils/roadmap-dashboard.sh" --check >/dev/null 2>&1; then
./relay-system/2026-09-07/gh474-md-views-101147/gh474-md-views.codex.md:6022:./relay-system/2026-09-06/gh243-marathon-codex-retry-174442/gh243-marathon-codex-retry.codex.md:1813:utils/roadmap-dashboard.sh:19:  --check: exit 0 when ROADMAP-DASHBOARD.md is in sync; non-zero on drift.
./relay-system/2026-09-07/gh474-md-views-101147/gh474-md-views.codex.md:6115:./relay-system/2026-09-06/gh243-marathon-codex-retry-174442/gh243-marathon-codex-retry.codex.md:2392:- **[Should] The durable third option is renderer-owned projection validity, not asking the app for a table allowlist.** The renderer already knows exactly when it drops rows and emits a warning ([utils/roadmap-dashboard.sh:175](utils/roadmap-dashboard.sh:175), [utils/roadmap-dashboard.sh:199](utils/roadmap-dashboard.sh:199), [utils/roadmap-dashboard.sh:217](utils/roadmap-dashboard.sh:217)), but `--check` still exits zero when the resulting file matches ([utils/roadmap-dashboard.sh:251](utils/roadmap-dashboard.sh:251)). Give dropped rows a machine-readable distinct result, then let the guard refuse that result and allow a clean no-diff render regardless of which ledger tables changed. That directly tests the hazardous condition and eliminates both allowlist and denylist drift. File this as follow-up; it need not block the narrow fix.
./relay-system/2026-09-07/gh474-md-views-101147/gh474-md-views.codex.md:6133:./relay-system/2026-09-06/gh243-marathon-codex-retry-174442/gh243-marathon-codex-retry.codex.md:2421:- **[Should] The durable third option is renderer-owned projection validity, not asking the app for a table allowlist.** The renderer already knows exactly when it drops rows and emits a warning ([utils/roadmap-dashboard.sh:175](utils/roadmap-dashboard.sh:175), [utils/roadmap-dashboard.sh:199](utils/roadmap-dashboard.sh:199), [utils/roadmap-dashboard.sh:217](utils/roadmap-dashboard.sh:217)), but `--check` still exits zero when the resulting file matches ([utils/roadmap-dashboard.sh:251](utils/roadmap-dashboard.sh:251)). Give dropped rows a machine-readable distinct result, then let the guard refuse that result and allow a clean no-diff render regardless of which ledger tables changed. That directly tests the hazardous condition and eliminates both allowlist and denylist drift. File this as follow-up; it need not block the narrow fix.
./relay-system/2026-09-07/gh474-md-views-101147/gh474-md-views.codex.md:6774:   290	   "ROADMAP_DASHBOARD_ROOT='$R8' bash '$ROOT_DIR/utils/roadmap-dashboard.sh' --check"
./docs/ROADMAP-UPSTREAM-ARCHIVE.md:186:- **GH-351 · the registered dashboard gate graded its own answer key** ✅ **done (2026-07-30)** — `test/roadmap-dashboard.sh` rendered the dashboard **into the repo** and then `--check`ed the copy it had just written, so its drift assertion could never fail; its own pass string read *"--check passes on the committed artifact"*, which was false by the time it ran. **The renderer was never the defect** — standalone `utils/roadmap-dashboard.sh --check` returned `rc=1` on all three of the day's stale dashboards, so the correct signal existed the whole time and the test overwrote its input before asking. A second, quieter fault: the test **wrote into `$ROOT`**, so `validate.sh` silently un-staled the dashboard mid-run — a suite repairing the evidence it was meant to judge, and leaving the tree dirty. Three stale dashboards reached `development` on 2026-07-30 alone from three different authors (GH-342, #356, #350); it fires on essentially every ROADMAP-touching PR. Fixed by two rules: `--check` runs **first** against the **committed** artifact, and nothing writes `$ROOT` (write-mode goes through `ROADMAP_DASHBOARD_OUTPUT`, which the renderer already supported — no renderer change). **4 → 9 cases**, including a mutation proof (case 4 plants a canary and requires `--check` to reject it, since cases 1 and 3 are unfalsifiable alone) and a no-side-effect assertion. **Verified against the real commit, not a synthetic fixture:** replaying `719867f`, the old test scores **4 pass / 0 fail** on a genuinely stale dashboard while the new one scores **6 pass / 3 fail**. Two findings only visible by running it — the old test left `ROADMAP-DASHBOARD.md` modified afterwards, and **case 9 (section counts) was already correct and still reported green**, because the regeneration ran first: the bug did not add a bad assertion, it *disabled a good one*. Sixth instance of *an assertion that compares a thing to a freshly-derived copy of itself* after #348/#342/#362(B)/#369. cx/risk/eff 2/2/2. → [GH-351-DASHBOARD-TEST-GRADES-ITS-OWN-ANSWER-KEY.md](PROJECT/3-COMPLETED/GH-351-DASHBOARD-TEST-GRADES-ITS-OWN-ANSWER-KEY.md) · [#351](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/351)
./test/gh269-roadmap-retired.sh:26:if bash "$root/utils/roadmap-dashboard.sh" --check; then
./test/gh269-roadmap-retired.sh:27:  pass "roadmap-dashboard.sh --check passed from releases.db source"
./test/gh269-roadmap-retired.sh:29:  fail "roadmap-dashboard.sh --check failed with no ROADMAP.md"
./relay-system/2026-09-06/gh243-marathon-allowlist-173919/gh243-marathon-allowlist.codex.md:349:   123	      if bash "$TMP_PROJ/utils/roadmap-dashboard.sh" --check >/dev/null 2>&1; then
./relay-system/2026-09-06/gh243-marathon-allowlist-173919/gh243-marathon-allowlist.codex.md:1241:utils/roadmap-dashboard.sh:19:  --check: exit 0 when ROADMAP-DASHBOARD.md is in sync; non-zero on drift.
./relay-system/2026-09-06/gh243-marathon-codex-retry-174442/gh243-marathon-codex-retry.codex.md:802:   123	      if bash "$TMP_PROJ/utils/roadmap-dashboard.sh" --check >/dev/null 2>&1; then
./relay-system/2026-09-06/gh243-marathon-codex-retry-174442/gh243-marathon-codex-retry.codex.md:1813:utils/roadmap-dashboard.sh:19:  --check: exit 0 when ROADMAP-DASHBOARD.md is in sync; non-zero on drift.
./relay-system/2026-09-06/gh243-marathon-codex-retry-174442/gh243-marathon-codex-retry.codex.md:2392:- **[Should] The durable third option is renderer-owned projection validity, not asking the app for a table allowlist.** The renderer already knows exactly when it drops rows and emits a warning ([utils/roadmap-dashboard.sh:175](utils/roadmap-dashboard.sh:175), [utils/roadmap-dashboard.sh:199](utils/roadmap-dashboard.sh:199), [utils/roadmap-dashboard.sh:217](utils/roadmap-dashboard.sh:217)), but `--check` still exits zero when the resulting file matches ([utils/roadmap-dashboard.sh:251](utils/roadmap-dashboard.sh:251)). Give dropped rows a machine-readable distinct result, then let the guard refuse that result and allow a clean no-diff render regardless of which ledger tables changed. That directly tests the hazardous condition and eliminates both allowlist and denylist drift. File this as follow-up; it need not block the narrow fix.
./relay-system/2026-09-06/gh243-marathon-codex-retry-174442/gh243-marathon-codex-retry.codex.md:2421:- **[Should] The durable third option is renderer-owned projection validity, not asking the app for a table allowlist.** The renderer already knows exactly when it drops rows and emits a warning ([utils/roadmap-dashboard.sh:175](utils/roadmap-dashboard.sh:175), [utils/roadmap-dashboard.sh:199](utils/roadmap-dashboard.sh:199), [utils/roadmap-dashboard.sh:217](utils/roadmap-dashboard.sh:217)), but `--check` still exits zero when the resulting file matches ([utils/roadmap-dashboard.sh:251](utils/roadmap-dashboard.sh:251)). Give dropped rows a machine-readable distinct result, then let the guard refuse that result and allow a clean no-diff render regardless of which ledger tables changed. That directly tests the hazardous condition and eliminates both allowlist and denylist drift. File this as follow-up; it need not block the narrow fix.
./test/gh280-jog-marathon-adapter.sh:1021:bash "$FR/utils/roadmap-dashboard.sh" --check >/dev/null 2>&1 \
./test/gh280-jog-marathon-adapter.sh:1033:bash "$FR/utils/roadmap-dashboard.sh" --check >/dev/null 2>&1 \
./relay-system/2026-08-26/relay-gh257-roadmap-ledger-qa.md:71:   the decisive `roadmap-dashboard.sh --check` at `:48-54` reads the current checkout rather than
./CHANGELOG.md:787:- **GH-351: the registered dashboard gate rendered the artifact into the repo and then validated the copy it had just written.** `test/roadmap-dashboard.sh:27` ran the renderer — overwriting `$ROOT/ROADMAP-DASHBOARD.md` — and `:34` then `--check`ed that file. The assertion could not fail, and its own pass string read *"--check passes on the committed artifact"*, which was false by the time it ran. **The renderer was never the defect and was not touched:** standalone `utils/roadmap-dashboard.sh --check` returned `rc=1` on all three of the day's stale dashboards, so the correct signal existed the whole time — the test overwrote its input before asking. A second, quieter fault: the test **wrote into `$ROOT`**, so `validate.sh` itself silently un-staled the dashboard mid-run, a suite repairing the evidence it was meant to judge and leaving the working tree dirty afterwards. Three stale dashboards reached `development` on 2026-07-30 alone from three different authors (GH-342, #356, #350); it fires on essentially every PR that edits `ROADMAP.md`, and the only reason it was ever caught was someone running the standalone checker by hand. Fixed with two rules whose case ordering is load-bearing: **`--check` runs first, against the committed artifact, before anything writes**, and nothing writes `$ROOT` — write-mode is exercised through `ROADMAP_DASHBOARD_OUTPUT`, which the renderer already supported, so no renderer change was needed. **4 → 9 cases**, adding a missing-artifact case, the source-drift direction that actually occurs in practice, a no-side-effect assertion, and — the one that keeps this honest — **a mutation proof**: cases 1 and 3 are unfalsifiable alone, so case 4 plants a canary line in a copy and requires `--check` to reject it. **Verified against the real commit rather than a synthetic fixture:** replaying `719867f` (the #350 merge, genuinely stale), the old test scores **4 pass / 0 fail** while the new one scores **6 pass / 3 fail**. Two things visible only by running it — the old test left `ROADMAP-DASHBOARD.md` modified in the fixture afterwards, and **case 9 (section counts) was already correct in the old file and still reported green** because the regeneration ran first: the bug did not add a bad assertion, it *disabled a good one* (`roadmap=128 dashboard=127` is what it should have been saying). Sixth instance of *an assertion that compares a thing to a freshly-derived copy of itself*, after #348, #342, #362(B) and #369 — the last of which was in a test written earlier the same day. The recurring lesson is not "write more tests" but **run the new test against the old code**; every one of these was caught that way and none by review. → [GH-351-DASHBOARD-TEST-GRADES-ITS-OWN-ANSWER-KEY.md](PROJECT/2-WORKING/GH-351-DASHBOARD-TEST-GRADES-ITS-OWN-ANSWER-KEY.md) · [#351](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/351)
./CHANGELOG.md:789:- **GH-351, third instance in one day (three different authors): PR #350 landed a stale `ROADMAP-DASHBOARD.md` and CI stayed green.** Regenerated as `b6e4bf2`. Running both checkers immediately after the merge isolates the defect precisely: `utils/roadmap-dashboard.sh --check` returns **rc=1** — the standalone checker is correct and needs no change — while the *registered* `test/roadmap-dashboard.sh` regenerates the artifact and then validates the copy it just wrote. The gate is green because it grades its own answer key. Fires on essentially every ROADMAP-touching PR; the only reason it keeps being caught is someone running the standalone checker by hand afterwards. → [#351](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/351)
./githooks/dashboard-staleness-guard.sh:130:      if render_err="$(bash "$TMP_PROJ/utils/roadmap-dashboard.sh" --check 2>&1 >/dev/null)"; then
./test/gh57-live-merge-resolve.sh:290:   "ROADMAP_DASHBOARD_ROOT='$R8' bash '$ROOT_DIR/utils/roadmap-dashboard.sh' --check"
./PROJECT/3-COMPLETED/GH-144-AGENT2AGENT-3PLUS-UX.md:60:- `bash utils/roadmap-dashboard.sh --check`
./PROJECT/2-WORKING/GH-474-DASHBOARD-DROPPED-ROW-SIGNAL.md:21:  - Changing utils/roadmap-dashboard.sh, including its --check exit contract
./PROJECT/1-INBOX/recon-roadmap-dashboard-removal.md:62:| `--check` exit contract | `utils/roadmap-dashboard.sh:251-263` | 5 consumers | a new exit code is introduced — **avoided; the signal travels on stderr** |
./PROJECT/1-INBOX/recon-gh474-dropped-row-signal.md:9:silently drop a roadmap row?"*, and the `--check` contract of `utils/roadmap-dashboard.sh` it
./PROJECT/1-INBOX/recon-gh474-dropped-row-signal.md:33:if bash "$TMP_PROJ/utils/roadmap-dashboard.sh" --check >/dev/null 2>&1; then
./PROJECT/1-INBOX/recon-gh474-dropped-row-signal.md:47:| `--check` exit contract | `utils/roadmap-dashboard.sh:251-263` | 5 consumers (below) | a new exit code is introduced — **avoided by this design** |
./PROJECT/1-INBOX/recon-gh474-dropped-row-signal.md:59:            ├─ :120-127   git archive local_sha -> TMP_PROJ, run roadmap-dashboard.sh --check

--- focused tests ---
     1	#!/bin/bash
     2	# test/gh243-dashboard-staleness-guard.sh — the GH-243 push guard: a roadmap-ledger write without a
     3	# dashboard regeneration is refused, releases-mode only, and only when a real range exists.
     4	set -eu
     5	source test/_setup.sh "GH-243" || { echo "setup failed"; exit 1; }
     6	
     7	root="$(cd "$HERE/.." && pwd)"
     8	GUARD="$root/githooks/dashboard-staleness-guard.sh"
     9	
    10	# Fixture: a releases-mode repo with a base commit, then a ledger-only commit on top.
    11	R="$WORK/fixture"
    12	mkdir -p "$R"
    13	cd "$R"
    14	git init -q .
    15	git -c user.email=t@t -c user.name=t commit -q --allow-empty -m base
    16	echo "ROADMAP_SOURCE=releases" > .pdda-mode
    17	echo "-- dump v1" > releases.sql
    18	echo "dash v1" > ROADMAP-DASHBOARD.md
    19	git add .pdda-mode releases.sql ROADMAP-DASHBOARD.md
    20	git -c user.email=t@t -c user.name=t commit -q -m "v1"
    21	BASE="$(git rev-parse HEAD)"
    22	
    23	echo "-- dump v2" > releases.sql
    24	git add releases.sql
    25	git -c user.email=t@t -c user.name=t commit -q -m "ledger write, no dashboard"
    26	LEDGER_ONLY="$(git rev-parse HEAD)"
    27	cd "$root"
    28	
    29	# 1. Ledger write without dashboard -> refuse (exit 1) with the regen instruction.
    30	rc=0; out="$(bash "$GUARD" "$R" "$LEDGER_ONLY" "$BASE" 2>&1)" || rc=$?
    31	[ "$rc" -eq 1 ] || fail "expected refusal (1), got $rc"
    32	grep -q "roadmap-dashboard.sh" <<<"$out" || fail "refusal missing the regeneration instruction"
    33	
    34	# 2. Same range with the dashboard regenerated in it -> pass.
    35	cd "$R"
    36	echo "dash v2" > ROADMAP-DASHBOARD.md
    37	git add ROADMAP-DASHBOARD.md
    38	git -c user.email=t@t -c user.name=t commit -q -m "regen dashboard"
    39	FIXED="$(git rev-parse HEAD)"
    40	cd "$root"
    41	bash "$GUARD" "$R" "$FIXED" "$BASE" || fail "regenerated range should pass, got $?"
    42	
    43	# 3. Legacy-mode repo (no releases marker) -> guard is inert even on a ledger-only range.
    44	cd "$R"; : > .pdda-mode; cd "$root"
    45	bash "$GUARD" "$R" "$LEDGER_ONLY" "$BASE" || fail "legacy-mode repo must not be guarded, got $?"
    46	cd "$R"; echo "ROADMAP_SOURCE=releases" > .pdda-mode; cd "$root"
    47	
    48	# 4. New branch (all-zero remote sha) -> no range, no refusal.
    49	bash "$GUARD" "$R" "$LEDGER_ONLY" "0000000000000000000000000000000000000000" \
    50	  || fail "new-branch push must fall through, got $?"
    51	
    52	# 5. Non-ledger range (docs commit only) -> pass.
    53	cd "$R"
    54	echo "readme" > README.md
    55	git add README.md
    56	git -c user.email=t@t -c user.name=t commit -q -m docs
    57	DOCS="$(git rev-parse HEAD)"
    58	cd "$root"
    59	bash "$GUARD" "$R" "$DOCS" "$FIXED" || fail "non-ledger range must pass, got $?"
    60	
    61	# 6. Usage error -> exit 2.
    62	rc=0; bash "$GUARD" >/dev/null 2>&1 || rc=$?
    63	[ "$rc" -eq 2 ] || fail "expected usage exit 2, got $rc"
    64	
    65	
    66	# 7. GH-474: a ledger write the renderer renders cleanly -> ALLOW, whatever table it touched.
    67	# The guard no longer classifies by table name; it asks the renderer whether it dropped a row.
    68	# `jog_queue` is the GH-315 shape that first exposed the old allowlist going short. The fixture
    69	# needs a renderer whose --check passes to reach the guard's no-drift branch at all; this stub
    70	# exits 0 and says nothing on stderr, which is exactly "rendered fine, dropped nothing".
    71	mkdir -p "$R/utils"
    72	printf '#!/usr/bin/env bash\nexit 0\n' > "$R/utils/roadmap-dashboard.sh"
    73	chmod +x "$R/utils/roadmap-dashboard.sh"
    74	cd "$R"
    75	git add utils/roadmap-dashboard.sh
    76	git -c user.email=t@t -c user.name=t commit -q -m "add passing renderer"
    77	RENDERED="$(git rev-parse HEAD)"
    78	{ echo "-- dump v3"
    79	  echo "INSERT INTO settings(key, value) VALUES('generation', '9');"
    80	  echo "INSERT INTO jog_queue VALUES('seed');"
    81	  echo "INSERT INTO op_receipts(op, target_gid) VALUES('jog-add', 'seed');"
    82	} > releases.sql
    83	git add releases.sql
    84	git -c user.email=t@t -c user.name=t commit -q -m "jog-only ledger write"
    85	JOG_ONLY="$(git rev-parse HEAD)"
    86	cd "$root"
    87	bash "$GUARD" "$R" "$JOG_ONLY" "$RENDERED" \
    88	  || fail "jog-queue-only ledger write must pass the no-drift branch (GH-315), got $?"
    89	
    90	# 7b. THE REGRESSION THIS CHANGE FIXES. Every one of these tables hit the old allowlist's
    91	# catch-all and produced a FALSE refusal — `releases add` alone tripped it. They are not
    92	# enumerated anywhere in the guard any more, which is the point: the guard reads the renderer's
    93	# report, so a table it has never heard of cannot make it go short.
    94	cd "$R"
    95	{ echo "-- dump v3b"
    96	  echo "INSERT INTO settings(key, value) VALUES('generation', '10');"
    97	  echo "INSERT INTO releases(global_id, name) VALUES('rel-1', 'v9');"
    98	  echo "INSERT INTO repos(repo_id, name) VALUES(2, 'other');"
    99	  echo "INSERT INTO manifest_items(global_id) VALUES('mi-1');"
   100	  echo "INSERT INTO doc_lines(global_id) VALUES('dl-1');"
   101	  echo "INSERT INTO schema_migrations(version) VALUES('077');"
   102	  echo "INSERT INTO totally_new_table_v9(global_id) VALUES('nt-1');"
   103	} > releases.sql
   104	git add releases.sql
   105	git -c user.email=t@t -c user.name=t commit -q -m "previously-unclassified ledger write"
   106	UNCLASSIFIED="$(git rev-parse HEAD)"
   107	cd "$root"
   108	bash "$GUARD" "$R" "$UNCLASSIFIED" "$RENDERED" \
   109	  || fail "GH-474: a clean render must allow any table, including ones no allowlist knows, got $?"
   110	
   111	# 8. RED CONTROL for 7 and 7b. Same no-drift shape, same tables 7b just allowed — but now the
   112	# renderer reports a dropped row. The guard must refuse AND name the row it was told about.
   113	# This is what proves 7/7b pass because the renderer said "clean", not because the arm is inert.
   114	cd "$R"
   115	cat > utils/roadmap-dashboard.sh <<'EOFSTUB'
   116	#!/usr/bin/env bash
   117	echo "roadmap-dashboard: warning: dropped 1 unparseable row(s): #256" >&2
   118	exit 0
   119	EOFSTUB
   120	chmod +x utils/roadmap-dashboard.sh
   121	git add utils/roadmap-dashboard.sh
   122	git -c user.email=t@t -c user.name=t commit -q -m "renderer drops a row"
   123	DROPPED="$(git rev-parse HEAD)"
   124	cd "$root"
   125	rc=0; out="$(bash "$GUARD" "$R" "$DROPPED" "$RENDERED" 2>&1)" || rc=$?
   126	[ "$rc" -eq 1 ] || fail "expected no-drift refusal (1) when the renderer drops a row, got $rc"
   127	grep -q "NO diff" <<<"$out" || fail "expected the no-diff refusal message"
   128	grep -q "dropped 1 unparseable row(s): #256" <<<"$out" \
   129	  || fail "GH-474: refusal must NAME the dropped row the renderer reported, got: $out"
   130	
   131	# 8b. Negative control on the signal itself: renderer exits 0 with unrelated stderr chatter ->
   132	# ALLOW. Guards against matching any stderr output rather than the dropped-row warning.
   133	cd "$R"
   134	cat > utils/roadmap-dashboard.sh <<'EOFSTUB2'
   135	#!/usr/bin/env bash
   136	echo "roadmap-dashboard: note: rendered 41 rows" >&2
   137	exit 0
   138	EOFSTUB2
   139	chmod +x utils/roadmap-dashboard.sh
   140	git add utils/roadmap-dashboard.sh
   141	git -c user.email=t@t -c user.name=t commit -q -m "renderer chatters but drops nothing"
   142	CHATTY="$(git rev-parse HEAD)"
   143	cd "$root"
   144	bash "$GUARD" "$R" "$CHATTY" "$RENDERED" \
   145	  || fail "unrelated renderer stderr must not be read as a dropped row, got $?"
   146	
   147	echo "== GH-243 ALL PASSED =="
     1	#!/usr/bin/env bash
     2	# test/gh257-roadmap-ledger-fixes.sh — regression suite for GH-257:
     3	# 1. validate --raw-text on roadmap add and update against renderer bold bullet shape (single line)
     4	# 2. emit warning on dropped unparseable rows in roadmap-dashboard.sh
     5	# 3. roadmap update subcommand for parked raw_text with auditable receipt and rating sync
     6	# 4. staleness guard diagnostic guidance when regeneration yields no diff
     7	set -euo pipefail
     8	source test/_setup.sh "GH-257" || { echo "setup failed"; exit 1; }
     9	
    10	root="$(cd "$HERE/.." && pwd)"
    11	app() { python3 "$root/utils/py/releases_app.py" "$@"; }
    12	RENDERER="$root/utils/roadmap-dashboard.sh"
    13	GUARD="$root/githooks/dashboard-staleness-guard.sh"
    14	
    15	R="$WORK/repo"
    16	mkdir -p "$R/utils/py"
    17	cp -r "$root/utils/"* "$R/utils/"
    18	cd "$R"
    19	git init -q .
    20	git -c user.email=t@t -c user.name=t commit -q --allow-empty -m base
    21	echo "ROADMAP_SOURCE=releases" > .pdda-mode
    22	mkdir -p PROJECT/1-INBOX
    23	touch PROJECT/1-INBOX/GH-255-test.md
    24	
    25	app --root "$R" init --slug "test-repo"
    26	
    27	# -----------------------------------------------------------------------------
    28	# Case 1: roadmap add with malformed --raw-text is REFUSED at step 1
    29	# -----------------------------------------------------------------------------
    30	for bad_input in \
    31	  "- [ ] #255 malformed checkbox" \
    32	  "-   **GH-255 · repeated spaces** 🆕" \
    33	  "-	**GH-255 · tab after dash** 🆕" \
    34	  "- **GH-255 unclosed bold" \
    35	  "- **** empty title GH-255" \
    36	  $'- **GH-255 · title**\n- [ ] #999 smuggled row' \
    37	  $'- **GH-255 · title**\r\nmalformed continuation'
    38	do
    39	  rc=0
    40	  out="$(app --root "$R" roadmap add --issue-num 255 --issue-url "https://github.com/org/repo/issues/255" \
    41	    --title "test 255" --created "2026-08-26" --doc-path "PROJECT/1-INBOX/GH-255-test.md" \
    42	    --raw-text "$bad_input" 2>&1)" || rc=$?
    43	
    44	  [ "$rc" -ne 0 ] || fail "malformed raw_text '$bad_input' should be refused on add, got rc=0"
    45	  case "$out" in
    46	    *"rule=invalid-raw-text"*) pass "roadmap add refused malformed raw_text: '$bad_input'" ;;
    47	    *) fail "expected invalid-raw-text rule for '$bad_input', got: $out" ;;
    48	  esac
    49	done
    50	
    51	# -----------------------------------------------------------------------------
    52	# Case 2: roadmap add with mismatched issue number in --raw-text is REFUSED
    53	# -----------------------------------------------------------------------------
    54	rc=0
    55	out="$(app --root "$R" roadmap add --issue-num 255 --issue-url "https://github.com/org/repo/issues/255" \
    56	  --title "test 255" --created "2026-08-26" --doc-path "PROJECT/1-INBOX/GH-255-test.md" \
    57	  --raw-text "- **GH-999 · wrong issue** 🆕" 2>&1)" || rc=$?
    58	
    59	[ "$rc" -ne 0 ] || fail "mismatched issue number in raw_text should be refused, got rc=0"
    60	case "$out" in
    61	  *"rule=invalid-raw-text"*"GH-255"*) pass "roadmap add refused mismatched issue number" ;;
    62	  *) fail "expected issue number mismatch refusal, got: $out" ;;
    63	esac
    64	
    65	# -----------------------------------------------------------------------------
    66	# Case 3: roadmap add with valid --raw-text SUCCEEDS
    67	# -----------------------------------------------------------------------------
    68	app --root "$R" roadmap add --issue-num 255 --issue-url "https://github.com/org/repo/issues/255" \
    69	  --title "test 255" --created "2026-08-26" --doc-path "PROJECT/1-INBOX/GH-255-test.md" \
    70	  --raw-text "- **GH-255 · valid initial title** 🆕 — [doc](PROJECT/1-INBOX/GH-255-test.md) · [#255](https://github.com/org/repo/issues/255)"
    71	pass "roadmap add succeeded with valid raw_text"
    72	
    73	# -----------------------------------------------------------------------------
    74	# Case 4: roadmap update with symmetric negative controls is REFUSED
    75	# -----------------------------------------------------------------------------
    76	for bad_input in \
    77	  "- [ ] #255 bad update" \
    78	  "-   **GH-255 · extra spaces**" \
    79	  "-	**GH-255 · tab after dash**" \
    80	  "- **GH-255 unclosed title" \
    81	  "- **** empty title GH-255" \
    82	  $'- **GH-255 · title**\n- [ ] #999 bad line' \
    83	  $'- **GH-255 · title**\r\ncontinuation'
    84	do
    85	  rc=0
    86	  out="$(app --root "$R" roadmap update --issue-num 255 --raw-text "$bad_input" 2>&1)" || rc=$?
    87	  [ "$rc" -ne 0 ] || fail "malformed raw_text '$bad_input' on update should be refused, got rc=0"
    88	  case "$out" in
    89	    *"rule=invalid-raw-text"*) pass "roadmap update refused malformed raw_text: '$bad_input'" ;;
    90	    *) fail "expected invalid-raw-text on roadmap update for '$bad_input', got: $out" ;;
    91	  esac
    92	done
    93	
    94	# -----------------------------------------------------------------------------
    95	# Case 5: roadmap update --dry-run prints changes and PROVABLY mutates nothing
    96	# -----------------------------------------------------------------------------
    97	raw_before="$(sqlite3 "$R/releases.db" "SELECT raw_text FROM roadmap_items WHERE gh_number = 255")"
    98	out="$(app --root "$R" roadmap update --issue-num 255 \
    99	  --raw-text "- **GH-255 · dry run title** 🆕 — [doc](PROJECT/1-INBOX/GH-255-test.md) · [#255](https://github.com/org/repo/issues/255)" \
   100	  --dry-run)"
   101	case "$out" in
   102	  *"raw_text: "*"- **GH-255 · dry run title**"*) pass "roadmap update --dry-run reported planned diff" ;;
   103	  *) fail "expected dry-run diff output, got: $out" ;;
   104	esac
   105	raw_after="$(sqlite3 "$R/releases.db" "SELECT raw_text FROM roadmap_items WHERE gh_number = 255")"
   106	[ "$raw_before" = "$raw_after" ] || fail "dry-run must not mutate database"
   107	pass "dry-run verified non-mutating against database"
   108	
   109	# -----------------------------------------------------------------------------
   110	# Case 6: roadmap update SUCCEEDS and generates roadmap-update receipt
   111	# -----------------------------------------------------------------------------
   112	NEW_TEXT="- **GH-255 · updated title** 🆕 — [doc](PROJECT/1-INBOX/GH-255-test.md) · [#255](https://github.com/org/repo/issues/255)"
   113	app --root "$R" roadmap update --issue-num 255 --raw-text "$NEW_TEXT"
   114	pass "roadmap update succeeded for GH-255"
   115	
   116	list_out="$(app --root "$R" roadmap list --json)"
   117	case "$list_out" in
   118	  *"- **GH-255 · updated title**"*) pass "roadmap list reflects updated raw_text" ;;
   119	  *) fail "roadmap list did not show updated raw_text: $list_out" ;;
   120	esac
   121	
   122	grep -q "roadmap-update" "$R/releases.sql" || fail "releases.sql missing roadmap-update receipt event"
   123	pass "releases.sql carries roadmap-update receipt"
   124	
   125	# -----------------------------------------------------------------------------
   126	# Case 7: roadmap update is IDEMPOTENT (no-op on unchanged text)
   127	# -----------------------------------------------------------------------------
   128	receipt_count_before="$(grep -c "roadmap-update" "$R/releases.sql" || true)"
   129	out="$(app --root "$R" roadmap update --issue-num 255 --raw-text "$NEW_TEXT")"
   130	case "$out" in
   131	  *"unchanged; nothing written"*) pass "roadmap update idempotent when text unchanged" ;;
   132	  *) fail "expected unchanged text report, got: $out" ;;
   133	esac
   134	receipt_count_after="$(grep -c "roadmap-update" "$R/releases.sql" || true)"
   135	[ "$receipt_count_before" -eq "$receipt_count_after" ] || fail "idempotent update must not write extra receipts"
   136	pass "idempotent update wrote zero additional receipts"
   137	
   138	# -----------------------------------------------------------------------------
   139	# Case 8: roadmap update synchronizes ALL FIVE rating columns
   140	# -----------------------------------------------------------------------------
   141	# Unrated -> Rated
   142	RATED_TEXT="- **GH-255 · rated title** 🆕 (rated 80/70/90/60 ovr 320) — [#255](https://github.com/org/repo/issues/255)"
   143	app --root "$R" roadmap update --issue-num 255 --raw-text "$RATED_TEXT"
   144	read pri sev app_score eff ovr <<<"$(sqlite3 "$R/releases.db" "SELECT rating_pri, rating_sev, rating_appeal, rating_effort, rating_ovr FROM roadmap_items WHERE gh_number = 255" | tr '|' ' ')"
   145	[ "$pri" = "80" ] && [ "$sev" = "70" ] && [ "$app_score" = "90" ] && [ "$eff" = "60" ] && [ "$ovr" = "320" ] \
   146	  || fail "expected rating columns (80 70 90 60 320), got ($pri $sev $app_score $eff $ovr)"
   147	pass "roadmap update correctly populated all 5 rating columns"
   148	
   149	# Rated -> Unrated (must reset all 5 rating columns to NULL, not leave old scores)
   150	UNRATED_TEXT="- **GH-255 · unrated again** 🆕 — [#255](https://github.com/org/repo/issues/255)"
   151	app --root "$R" roadmap update --issue-num 255 --raw-text "$UNRATED_TEXT"
   152	cleared_counts="$(sqlite3 "$R/releases.db" "SELECT COUNT(*) FROM roadmap_items WHERE gh_number = 255 AND (rating_pri IS NOT NULL OR rating_sev IS NOT NULL OR rating_appeal IS NOT NULL OR rating_effort IS NOT NULL OR rating_ovr IS NOT NULL)")"
   153	[ "$cleared_counts" = "0" ] || fail "expected all rating columns to be NULL, found non-null values"
   154	pass "roadmap update correctly cleared all 5 rating columns to NULL on unrated line"
   155	
   156	# -----------------------------------------------------------------------------
   157	# Case 9: schema-behind refusal on pre-migration ledger without rating columns
   158	# -----------------------------------------------------------------------------
   159	R_OLD="$WORK/pre_migration_repo"
   160	mkdir -p "$R_OLD/utils/py"
   161	cp -r "$root/utils/"* "$R_OLD/utils/"
   162	cd "$R_OLD"
   163	git init -q .
   164	echo "ROADMAP_SOURCE=releases" > .pdda-mode
   165	mkdir -p PROJECT/1-INBOX
   166	touch PROJECT/1-INBOX/GH-100-test.md
   167	app --root "$R_OLD" init --slug "old-repo"
   168	app --root "$R_OLD" roadmap add --issue-num 100 --issue-url "https://github.com/org/repo/issues/100" \
   169	  --title "old 100" --created "2026-08-26" --doc-path "PROJECT/1-INBOX/GH-100-test.md" \
   170	  --raw-text "- **GH-100 · old initial** 🆕 — [#100](https://github.com/org/repo/issues/100)"
   171	
   172	# Simulate pre-migration schema by dropping rating columns
   173	sqlite3 "$R_OLD/releases.db" <<'EOSQL'
   174	CREATE TABLE roadmap_items_old AS SELECT id, global_id, repo_id, gh_number, title, section, position, status_marker, complexity, risk, effort, doc_path, issue_url, raw_text, first_seen, updated_at FROM roadmap_items;
   175	DROP TABLE roadmap_items;
   176	ALTER TABLE roadmap_items_old RENAME TO roadmap_items;
   177	EOSQL
   178	
   179	rc=0
   180	out="$(app --root "$R_OLD" roadmap update --issue-num 100 \
   181	  --raw-text "- **GH-100 · rated line on old ledger** 🆕 (rated 80/70/90/60) — [#100](https://github.com/org/repo/issues/100)" 2>&1)" || rc=$?
   182	[ "$rc" -ne 0 ] || fail "rated update against pre-migration ledger should be refused, got rc=0"
   183	case "$out" in
   184	  *"rule=schema-behind"*) pass "roadmap update refused rated line on pre-migration ledger with schema-behind" ;;
   185	  *) fail "expected schema-behind refusal, got: $out" ;;
   186	esac
   187	
   188	# -----------------------------------------------------------------------------
   189	# Case 10: renderer (utils/roadmap-dashboard.sh) emits stderr warning on dropped rows
   190	# -----------------------------------------------------------------------------
   191	MOCK_SRC="$WORK/mock_roadmap.md"
   192	cat > "$MOCK_SRC" <<'EOFMOCK'
   193	# ROADMAP
   194	## Ledger
   195	### Queue / parked intake
   196	- **GH-1 · valid row** 🟢 — [doc](doc.md)
   197	- [ ] #999 malformed row
   198	- #1000 another dropped bullet
   199	- **GH-1001 unclosed bold
   200	EOFMOCK
   201	
   202	MOCK_OUT="$WORK/mock_dashboard.md"
   203	err_out="$(ROADMAP_DASHBOARD_SOURCE="$MOCK_SRC" ROADMAP_DASHBOARD_OUTPUT="$MOCK_OUT" bash "$RENDERER" 2>&1 >/dev/null)" || true
   204	case "$err_out" in
   205	  *"roadmap-dashboard: warning: dropped 3 unparseable row(s): #999, #1000, #1001"*)
   206	    pass "renderer warned on dropped unparseable rows (including unclosed bold) on stderr"
   207	    ;;
   208	  *) fail "expected warning naming dropped rows #999, #1000, #1001, got: $err_out" ;;
   209	esac
   210	
   211	# -----------------------------------------------------------------------------
   212	# Case 11: End-to-end historical reproduction of malformed row diagnosis & fix
   213	# -----------------------------------------------------------------------------
   214	cd "$R"
   215	bash "$R/utils/roadmap-dashboard.sh"
   216	git add .pdda-mode releases.db releases.sql ROADMAP-DASHBOARD.md utils/ PROJECT/
   217	git -c user.email=t@t -c user.name=t commit -q -m "v1 clean base"
   218	BASE_COMMIT="$(git rev-parse HEAD)"
   219	
   220	# Simulate the historical bug: a malformed row (- [ ] #256 ...) is directly injected into ledger
   221	sqlite3 "$R/releases.db" <<'EOSQL'
   222	INSERT INTO roadmap_items (global_id, repo_id, gh_number, title, section, position, status_marker, doc_path, issue_url, raw_text, first_seen, updated_at)
   223	VALUES ('rmi-01M0ZVV0000000000000000256', 1, 256, 'bad 256', 'Queue / parked intake', 99, '🆕', 'PROJECT/1-INBOX/GH-255-test.md', 'https://github.com/org/repo/issues/256', '- [ ] #256 historical malformed row', datetime('now'), datetime('now'));
   224	EOSQL
   225	python3 -c "import sys; sys.path.insert(0, '$root/utils/py'); import releases_app as rel; root = rel.resolve_root('$R'); conn = rel.connect(rel.artifact_paths(root)['db']); gen = rel.get_generation(conn); open(rel.artifact_paths(root)['dump'], 'w').write(rel.dump_text(conn, gen)); conn.close()"
   226	
   227	# 1. Regenerating dashboard yields warnings and dropped row:
   228	dash_warn="$(bash "$R/utils/roadmap-dashboard.sh" 2>&1 >/dev/null)" || true
   229	case "$dash_warn" in
   230	  *"warning: dropped 1 unparseable row(s): #256"*) pass "end-to-end: renderer detected injected malformed row #256" ;;
   231	  *) fail "expected dropped row warning for #256, got: $dash_warn" ;;
   232	esac
   233	
   234	# 2. Commit the ledger change only (dashboard unchanged because row was dropped)
   235	git add releases.db releases.sql
   236	git -c user.email=t@t -c user.name=t commit -q -m "ledger has bad row #256, dashboard unchanged"
   237	BAD_COMMIT="$(git rev-parse HEAD)"
   238	cd "$root"
   239	
   240	# 3. Staleness guard catches it and outputs no-diff diagnosis:
   241	# Add uncommitted modification in working tree to PROVE guard is isolated to commit projection
   242	echo "dirty working tree modification" >> "$R/ROADMAP-DASHBOARD.md"
   243	
   244	GUARD_TMP="$WORK/guard_isolated_tmp"
   245	mkdir -p "$GUARD_TMP"
   246	
   247	rc=0
   248	guard_out="$(TMPDIR="$GUARD_TMP" bash "$GUARD" "$R" "$BAD_COMMIT" "$BASE_COMMIT" 2>&1)" || rc=$?
   249	[ "$rc" -eq 1 ] || fail "guard should refuse bad commit, got $rc"
   250	case "$guard_out" in
   251	  *"produces NO diff (GH-243 / GH-257)"*"releases roadmap update"*)
   252	    pass "end-to-end: staleness guard accurately diagnosed no-diff dropped row (even with dirty working tree)"
   253	    ;;
   254	  *) fail "expected no-diff diagnostic output from guard, got: $guard_out" ;;
   255	esac
   256	# GH-474: the guard reads the RENDERER's dropped-row warning rather than inferring it from table
   257	# names, and the renderer here is the real one, reached through the guard's `git archive`
   258	# projection. Asserting the row id proves the signal survives that projection — if it did not,
   259	# the guard would fall through to "allow" and this case would go red instead of quietly passing
   260	# for the wrong reason. This is the runnable check the #474 recon listed as its one unknown.
   261	case "$guard_out" in
   262	  *"dropped 1 unparseable row(s): #256"*)
   263	    pass "GH-474: refusal names the dropped row, so the renderer's warning survived the projection"
   264	    ;;
   265	  *) fail "expected the guard to name dropped row #256 from the renderer's own stderr, got: $guard_out" ;;
   266	esac
   267	[ "$(find "$GUARD_TMP" -maxdepth 1 -name "staleness-guard.*" | wc -l)" -eq 0 ] || fail "expected no leftover guard roots in GUARD_TMP after no-diff refusal"
   268	pass "guard cleaned up temporary root after no-diff refusal"
   269	
   270	# Restore working tree
   271	git -C "$R" checkout ROADMAP-DASHBOARD.md
   272	
   273	# 4. Multi-ref push test with BAD_COMMIT FIRST and clean BASE_COMMIT LAST
   274	# Proves per-ref evaluation does not merely inspect the last ref in the list
   275	rc=0
   276	guard_multi_out="$(TMPDIR="$GUARD_TMP" bash "$GUARD" "$R" "$BAD_COMMIT" "$BASE_COMMIT" "$BASE_COMMIT" "$BASE_COMMIT" 2>&1)" || rc=$?
   277	[ "$rc" -eq 1 ] || fail "guard should refuse multi-ref push with bad commit first, got $rc"
   278	case "$guard_multi_out" in
   279	  *"produces NO diff (GH-243 / GH-257)"*)
   280	    pass "end-to-end: multi-ref push correctly evaluates bad ref first and clean ref last"
   281	    ;;
   282	  *) fail "expected no-diff refusal in multi-ref push, got: $guard_multi_out" ;;
   283	esac
   284	[ "$(find "$GUARD_TMP" -maxdepth 1 -name "staleness-guard.*" | wc -l)" -eq 0 ] || fail "expected no leftover guard roots in GUARD_TMP after multi-ref refusal"
   285	pass "guard cleaned up temporary root after multi-ref refusal"
   286	
   287	# Cross-ref test: Ref 1 touches ledger only (BAD_COMMIT), Ref 2 touches dashboard only
   288	cd "$R"
   289	git checkout -q -b branch-dash-only "$BASE_COMMIT"
   290	echo "# modified dashboard" >> ROADMAP-DASHBOARD.md
   291	git add ROADMAP-DASHBOARD.md
   292	git -c user.email=t@t -c user.name=t commit -q -m "dashboard only commit"
   293	DASH_ONLY_COMMIT="$(git rev-parse HEAD)"
   294	git checkout -q -
   295	cd "$root"
   296	
   297	rc=0
   298	guard_cross_out="$(TMPDIR="$GUARD_TMP" bash "$GUARD" "$R" "$BAD_COMMIT" "$BASE_COMMIT" "$DASH_ONLY_COMMIT" "$BASE_COMMIT" 2>&1)" || rc=$?
   299	[ "$rc" -eq 1 ] || fail "cross-ref push should refuse bad ledger ref despite separate dashboard ref, got $rc"
   300	case "$guard_cross_out" in
   301	  *"produces NO diff (GH-243 / GH-257)"*)
   302	    pass "end-to-end: cross-ref push enforces per-ref consistency and refuses stale ledger ref"
   303	    ;;
   304	  *) fail "expected refusal on cross-ref push, got: $guard_cross_out" ;;
   305	esac
   306	[ "$(find "$GUARD_TMP" -maxdepth 1 -name "staleness-guard.*" | wc -l)" -eq 0 ] || fail "expected no leftover guard roots in GUARD_TMP after cross-ref refusal"
   307	pass "guard cleaned up temporary root after cross-ref refusal"
   308	
   309	# 5. Projection failure test:
   310	# Create a commit where ledger is touched, but utils/roadmap-dashboard.sh is missing from that commit.
   311	# The projection fails to run the script and must fail closed (drift_detected=1), refusing the push
   312	# and cleaning up temporary directory without consulting working tree.
   313	cd "$R"
   314	git checkout -q -b branch-proj-fail "$BAD_COMMIT"
   315	git rm -q utils/roadmap-dashboard.sh
   316	git -c user.email=t@t -c user.name=t commit -q -m "commit without renderer script"
   317	PROJ_FAIL_COMMIT="$(git rev-parse HEAD)"
   318	git checkout -q -
   319	cd "$root"
   320	
   321	rc=0
   322	guard_fail_out="$(TMPDIR="$GUARD_TMP" bash "$GUARD" "$R" "$PROJ_FAIL_COMMIT" "$BASE_COMMIT" 2>&1)" || rc=$?
   323	[ "$rc" -eq 1 ] || fail "guard should refuse when commit projection fails renderer lookup, got $rc"
   324	case "$guard_fail_out" in
   325	  *"without regenerating ROADMAP-DASHBOARD.md"*)
   326	    pass "end-to-end: projection failure fails closed as drift and refuses without working tree fallback"
   327	    ;;
   328	  *) fail "expected drift refusal on projection failure, got: $guard_fail_out" ;;
   329	esac
   330	[ "$(find "$GUARD_TMP" -maxdepth 1 -name "staleness-guard.*" | wc -l)" -eq 0 ] || fail "expected no leftover guard roots in GUARD_TMP after projection failure refusal"
   331	pass "guard cleaned up temporary root after projection failure refusal"
   332	
   333	# 6. Hostile root pivot/rename test:
   334	# Create a commit where roadmap-dashboard.sh tries to replace the guard root with a symlink to VICTIM_DIR
   335	VICTIM_DIR="$WORK/victim_dir"
   336	mkdir -p "$VICTIM_DIR"
   337	touch "$VICTIM_DIR/important_file"
   338	
   339	cd "$R"
   340	git checkout -q -b branch-hostile-pivot "$BAD_COMMIT"
   341	cat > utils/roadmap-dashboard.sh <<'EOFPIVOT'
   342	#!/usr/bin/env bash
   343	SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
   344	GUARD_ROOT_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"
   345	rm -rf "$GUARD_ROOT_DIR" 2>/dev/null || true
   346	ln -s "$VICTIM_DIR" "$GUARD_ROOT_DIR" 2>/dev/null || true
   347	exit 0
   348	EOFPIVOT
   349	chmod +x utils/roadmap-dashboard.sh
   350	git add utils/roadmap-dashboard.sh
   351	git -c user.email=t@t -c user.name=t commit -q -m "commit with hostile pivot script"
   352	PIVOT_COMMIT="$(git rev-parse HEAD)"
   353	git checkout -q "$BASE_COMMIT"
   354	cd "$root"
   355	
   356	rc=0
   357	guard_pivot_out="$(TMPDIR="$GUARD_TMP" VICTIM_DIR="$VICTIM_DIR" bash "$GUARD" "$R" "$PIVOT_COMMIT" "$BASE_COMMIT" 2>&1)" || rc=$?
   358	[ "$rc" -eq 1 ] || fail "guard should refuse on pivot attempt, got $rc"
   359	[ -f "$VICTIM_DIR/important_file" ] || fail "hostile pivot must not delete victim files"
   360	pass "end-to-end: hostile root symlink pivot safely refused and protected external directories"
   361	
   362	rm -rf "$GUARD_TMP"/staleness-guard.* 2>/dev/null || true
   363	
   364	# 7. Hostile root rename replacement test (directory swap / inode mismatch):
   365	# Create a commit where roadmap-dashboard.sh moves guard root aside and replaces it with a new real directory
   366	VICTIM_DIR2="$WORK/victim_dir2"
   367	mkdir -p "$VICTIM_DIR2"
   368	touch "$VICTIM_DIR2/safe_file"
   369	
   370	cd "$R"
   371	git checkout -q -b branch-hostile-rename "$BAD_COMMIT"
   372	cat > utils/roadmap-dashboard.sh <<'EOFRENAME'
   373	#!/usr/bin/env bash
   374	SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
   375	GUARD_ROOT_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"
   376	mv "$GUARD_ROOT_DIR" "$GUARD_ROOT_DIR.aside" 2>/dev/null || true
   377	mv "$VICTIM_DIR2" "$GUARD_ROOT_DIR" 2>/dev/null || true
   378	exit 0
   379	EOFRENAME
   380	chmod +x utils/roadmap-dashboard.sh
   381	git add utils/roadmap-dashboard.sh
   382	git -c user.email=t@t -c user.name=t commit -q -m "commit with hostile rename script"
   383	RENAME_COMMIT="$(git rev-parse HEAD)"
   384	git checkout -q "$BASE_COMMIT"
   385	cd "$root"
   386	
   387	rc=0
   388	guard_rename_out="$(TMPDIR="$GUARD_TMP" VICTIM_DIR2="$VICTIM_DIR2" bash "$GUARD" "$R" "$RENAME_COMMIT" "$BASE_COMMIT" 2>&1)" || rc=$?
   389	[ "$rc" -eq 1 ] || fail "guard should refuse on rename attempt, got $rc"
   390	case "$guard_rename_out" in
   391	  *"identity mismatch"*) pass "end-to-end: hostile directory rename detected by device/inode mismatch" ;;
   392	  *) fail "expected identity mismatch refusal, got: $guard_rename_out" ;;
   393	esac
   394	
   395	# Prove victim file was NOT deleted by the guard (it is preserved in the refused root)
   396	# SC2144: -f does not work with a glob -- the shell expands it to N words and `[` sees too many
   397	# arguments (or, with no match, tests the literal pattern). Iterate the expansion instead.
   398	victim_preserved=0
   399	for _safe in "$GUARD_TMP"/staleness-guard.*/safe_file; do
   400	  if [ -f "$_safe" ]; then victim_preserved=1; break; fi
   401	done
   402	[ "$victim_preserved" -eq 1 ] || fail "victim file was deleted by guard"
   403	pass "end-to-end: victim directory preserved and undeleted during hostile rename replacement attempt"
   404	
   405	rm -rf "$GUARD_TMP"/staleness-guard.* "$GUARD_TMP"/staleness-guard.*.aside 2>/dev/null || true
   406	
   407	# 8. Remediation: use roadmap update to fix raw_text
   408	cd "$R"
   409	git checkout -q "$BAD_COMMIT"
   410	app --root "$R" roadmap update --issue-num 256 --raw-text "- **GH-256 · fixed title** 🆕 — [#256](https://github.com/org/repo/issues/256)"
   411	bash "$R/utils/roadmap-dashboard.sh"
   412	grep -q "GH-256 · fixed title" "$R/ROADMAP-DASHBOARD.md" || fail "remediated row not in dashboard"
   413	pass "end-to-end: roadmap update remediated row and dashboard now includes it"
   414	
   415	git add releases.db releases.sql ROADMAP-DASHBOARD.md
   416	git -c user.email=t@t -c user.name=t commit -q -m "remediated row #256 and regenerated dashboard"
   417	REMEDIATED_COMMIT="$(git rev-parse HEAD)"
   418	cd "$root"
   419	
   420	# 8. Staleness guard now passes cleanly and leaves no temporary files:
   421	TMPDIR="$GUARD_TMP" bash "$GUARD" "$R" "$REMEDIATED_COMMIT" "$BASE_COMMIT"
   422	[ "$(find "$GUARD_TMP" -maxdepth 1 -name "staleness-guard.*" | wc -l)" -eq 0 ] || fail "expected no leftover guard roots in GUARD_TMP after clean pass"
   423	pass "end-to-end: staleness guard passes after roadmap update and leaves 0 temporary artifacts"
   424	
   425	echo "== GH-257 ALL PASSED =="

--- specified consumer sections ---
     1	#!/bin/bash
     2	# test/gh269-roadmap-retired.sh — verify ROADMAP.md is retired and tools operate on releases.db
     3	set -eu
     4	source test/_setup.sh "GH-269" || { echo "setup failed"; exit 1; }
     5	
     6	root="$(cd "$HERE/.." && pwd)"
     7	
     8	# ── 1. Static canary: ROADMAP.md must not exist at repo root ────────────────────────
     9	if [ -f "$root/ROADMAP.md" ]; then
    10	  fail "ROADMAP.md is present at repo root — file must be retired in releases-mode"
    11	else
    12	  pass "ROADMAP.md is absent at repo root"
    13	fi
    14	
    15	# ── 2. Active tools execute without ROADMAP.md ───────────────────────────────────────
    16	rc=0
    17	out="$(QUEUE_PLAN_GH=off python3 "$root/utils/py/marathon_plan.py" --dry-run 2>&1)" || rc=$?
    18	# exit 0 (clean) or 4 (drift present) are valid execution verdicts; exit 3 (ROADMAP unparseable) is failure
    19	if [ "${rc:-0}" -eq 3 ]; then
    20	  fail "marathon_plan.py failed with exit 3 (unparseable/missing ROADMAP): $out"
    21	else
    22	  pass "marathon_plan.py executed without ROADMAP.md (exit ${rc:-0})"
    23	fi
    24	
    25	# ── 3. Roadmap dashboard passes check ────────────────────────────────────────────────
    26	if bash "$root/utils/roadmap-dashboard.sh" --check; then
    27	  pass "roadmap-dashboard.sh --check passed from releases.db source"
    28	else
    29	  fail "roadmap-dashboard.sh --check failed with no ROADMAP.md"
    30	fi
    31	
    32	# ── 4. PDDA doc checks pass without ROADMAP.md ───────────────────────────────────────
    33	if PDDA_REPO_ROOT="$root" bash "$root/utils/pdda/pdda.sh" roadmap-coverage >/dev/null 2>&1; then
    34	  pass "pdda.sh roadmap-coverage passed from releases.db"
    35	else
    36	  fail "pdda.sh roadmap-coverage failed when ROADMAP.md is absent"
    37	fi
    38	
    39	if PDDA_REPO_ROOT="$root" bash "$root/utils/pdda/pdda.sh" roadmap >/dev/null 2>&1; then
    40	  pass "pdda.sh roadmap passed cleanly when ROADMAP.md is absent"
    41	else
    42	  fail "pdda.sh roadmap failed when ROADMAP.md is absent"
    43	fi
    44	
    45	# ── 5. Fixture test: releases roadmap move and update CLI verbs ──────────────────────
    46	R="$WORK/fixture"
    47	mkdir -p "$R/PROJECT/2-WORKING" "$R/PROJECT/3-COMPLETED" "$R/utils/py"
    48	cp "$root/utils/py/releases_app.py" "$R/utils/py/"
    49	cp "$root/utils/py/harness_paths.py" "$R/utils/py/"
    50	
    51	cd "$R"
    52	git init -q .
    53	git -c user.email=t@t -c user.name=t commit -q --allow-empty -m base
    54	echo "ROADMAP_SOURCE=releases" > .pdda-mode
    55	python3 "$R/utils/py/releases_app.py" --root "$R" init >/dev/null 2>&1
    56	
    57	# Add a test item
    58	python3 "$R/utils/py/releases_app.py" --root "$R" roadmap add \
    59	  --issue-num 999 \
    60	  --issue-url "https://github.com/HiQS-Labs/XYZ-forge/issues/999" \
    61	  --title "Test Issue" \
    62	  --created "2026-09-04" \
    63	  --doc-path "PROJECT/2-WORKING/GH-999-TEST.md" >/dev/null
    64	
    65	# Verify row exists in Queue / parked intake
    66	sec="$(sqlite3 "$R/releases.db" "SELECT section FROM roadmap_items WHERE gh_number = 999")"
    67	[ "$sec" = "Queue / parked intake" ] || fail "expected Queue / parked intake, got $sec"
    68	pass "fixture: roadmap add inserted item into Queue / parked intake"
    69	
    70	# Move row to Completed via roadmap move
    71	python3 "$R/utils/py/releases_app.py" --root "$R" roadmap move \
    72	  --issue-num 999 \
    73	  --section "Completed" >/dev/null
    74	
    75	sec="$(sqlite3 "$R/releases.db" "SELECT section FROM roadmap_items WHERE gh_number = 999")"
    76	[ "$sec" = "Completed" ] || fail "expected Completed, got $sec"
    77	pass "fixture: roadmap move moved item to Completed"
    78	
    79	# Verify roadmap sync is a clean no-op in releases mode with no ROADMAP.md
    80	sync_out="$(python3 "$R/utils/py/releases_app.py" --root "$R" roadmap sync 2>&1)"
   990	                 "result_path": "$FR/.tick/jog/$GID/gh901-exec1/preflight/marathon-result.json"}]}
   991	JSEOF
   992	pr_view_json MERGED development deadbeef deadbeef > "$VIEW"
   993	make_land_receipt red "$FR"
   994	L8_OUT="$(GH_STUB_PR_VIEW_JSON="$VIEW" jog_verb land 901 --pr 42 2>&1)"; rc=$?
   995	[ "$rc" -eq 2 ] && has "$L8_OUT" "gate green on the landed head" \
   996	  && pass "L8 receipt without green gate evidence refused" || fail "L8 rc=$rc: $L8_OUT"
   997	make_land_receipt green "/definitely/not/this/repo"
   998	L9_OUT="$(GH_STUB_PR_VIEW_JSON="$VIEW" jog_verb land 901 --pr 42 2>&1)"; rc=$?
   999	[ "$rc" -eq 2 ] && has "$L9_OUT" "receipt repo is this repo" \
  1000	  && pass "L9 receipt naming a foreign repo refused" || fail "L9 rc=$rc: $L9_OUT"
  1001	
  1002	
  1003	# ═══ M. GH-292 follow-up fixes: F1 supervisor-state commit, F2 ledger re-key survival, F3 dashboard regen ══
  1004	cleanup_root_fixture
  1005	use_development
  1006	GID="$(sqlite3 "$FR/releases.db" "SELECT global_id FROM jog_queue WHERE gh_number = 901;")"
  1007	# Park a roadmap row so promotion genuinely repoints it (and the dashboard drifts);
  1008	# commit the in-sync dashboard BEFORE the run so post-promotion drift is falsifiable (F3)
  1009	# --root is REQUIRED: without it resolve_root() lands on the REAL clone running the gate
  1010	# and the fixture row escapes into the live releases.db (GH-195 class, observed live
  1011	# 2026-08-29: a phantom GH-901 row parked at 04:09:08Z failed roadmap-dashboard.sh mid-gate
  1012	# and — worse — neutered M1 below, because the fixture never held the row and the promotion's
  1013	# repoint silently no-such-row'd, leaving the F3 assertion vacuously green).
  1014	python3 "$FR/utils/py/releases_app.py" --root "$FR" roadmap add --issue-num 901 \
  1015	  --issue-url "https://github.com/example/example/issues/901" \
  1016	  --title "GH-901 fixture lane" --created 2026-08-28 \
  1017	  --doc-path "PROJECT/1-INBOX/$CAPTURE_DOC_NAME" >/dev/null 2>&1
  1018	printf '# Roadmap\n\n### In progress\n' > "$FR/ROADMAP.md"   # renderer reads it even in DB mode
  1019	bash "$FR/utils/roadmap-dashboard.sh" >/dev/null 2>&1 || true
  1020	git -C "$FR" add -A >/dev/null 2>&1; git -C "$FR" commit -qm "fixture: commit dashboard baseline" >/dev/null 2>&1
  1021	bash "$FR/utils/roadmap-dashboard.sh" --check >/dev/null 2>&1 \
  1022	  && pass "M0a baseline dashboard is in sync before the run" \
  1023	  || fail "M0a baseline dashboard already drifting — fixture invalid"
  1024	
  1025	M_OUT="$(GH_STUB_PR_JSON="$CANNED_PR" \
  1026	  env -u MARATHON_ALLOW_TRUNK_COMMIT SP_SUGGESTED_BRANCH="marathon/gh280-m-lane" \
  1027	  PATH="$JOG_AGENTS:$PATH" CODEX_BIN="$JOG_AGENTS/codex" AGY_BIN="$JOG_AGENTS/agy" \
  1028	  python3 "$FR/utils/py/releases_app.py" --root "$FR" jog run \
  1029	    --executor marathon --builder codex --reviewer agy 2>&1)"; rc=$?
  1030	[ "$rc" -eq 0 ] && pass "M0 promoted executor run exits 0" || fail "M0 exit=$rc: $M_OUT"
  1031	
  1032	# M1 (F3): the dashboard is in sync after a promotion (was drift-red pre-fix)
  1033	bash "$FR/utils/roadmap-dashboard.sh" --check >/dev/null 2>&1 \
  1034	  && pass "M1 dashboard in sync after promotion (F3)" \
  1035	  || fail "M1 dashboard drifted after promotion — F3 regen missing"
  1036	
  1037	# M3 (F1): a jog-state commit exists before dispatch, and a containment-style revert
  1038	# of tracked ledger files cannot destroy the queue row anymore
  1039	grep -q "jog-state:" <<<"$(git -C "$FR" log --oneline --grep="^jog-state:" -1)" \
  1040	  && pass "M3 supervisor-state commit landed before dispatch (F1)" \
  1041	  || fail "M3 no jog-state commit found"
  1042	grep -q "releases.db" <<<"$(git -C "$FR" show --name-only --format= "$(git -C "$FR" log --format=%H --grep="^jog-state:" -1)")" \
  1043	  && pass "M3 the supervisor commit carries releases.db" || fail "M3 supervisor commit lacks releases.db"
  1044	git -C "$FR" checkout -q -- releases.db releases.sql
  1045	N_ROWS="$(sqlite3 "$FR/releases.db" "SELECT count(*) FROM jog_queue WHERE gh_number = 901;")"
  1046	[ "$N_ROWS" -ge 1 ] \
  1047	  && pass "M3 containment-style tree revert leaves the queue row intact (F1)" \
  1048	  || fail "M3 queue row lost to tree revert"
  1049	
  1050	# M2 (F2): DB loss + re-add — the ledger is found by gh-number, no re-key surgery
   270	for f in $V8; do printf 'main touched %s\n' "$f" >> "$R8/$f"; done
   271	git -C "$R8" commit -qam main
   272	git -C "$R8" merge side -m merge >/dev/null 2>&1 || true
   273	ok "the adopted views really conflicted (both sides wrote them)" \
   274	   "has \"\$(git -C '$R8' diff --name-only --diff-filter=U)\" 'ROADMAP-DASHBOARD.md'"
   275	resolve_dump "$R8"
   276	out="$(resolver "$R8")"; rc=$?
   277	ok "resolver completes with adopted views in play (rc=$rc)" "[ $rc -eq 0 ]"
   278	ok "  and says it regenerated them" "has \"\$out\" 'regenerating adopted views'"
   279	ok "  and left no unmerged paths (views included)" \
   280	   "[ -z \"\$(git -C '$R8' diff --name-only --diff-filter=U)\" ]"
   281	STAGED="$(git -C "$R8" diff --cached --name-only)"
   282	for f in $V8; do
   283	  ok "  $f is staged resolved" "has \"\$STAGED\" '$f'"
   284	  ok "  $f carries no conflict markers" "[ \"\$(grep -c '^<<<<<<< ' '$R8/$f')\" -eq 0 ]"
   285	  ok "  $f carries neither side's stale touch" "! grep -q 'touched $f' '$R8/$f'"
   286	done
   287	# Idempotence: re-rendering from the resolved ledger reproduces the staged bytes, and the
   288	# dashboard/leaderboard --check modes agree the staged copies are in sync.
   289	ok "staged dashboard matches a fresh render (--check in sync)" \
   290	   "ROADMAP_DASHBOARD_ROOT='$R8' bash '$ROOT_DIR/utils/roadmap-dashboard.sh' --check"
   291	ok "staged LEADERBOARD.md matches a fresh render (--check in sync)" \
   292	   "LEADERBOARD_DB='$R8/releases.db' LEADERBOARD_OUTPUT='$R8/LEADERBOARD.md' bash '$ROOT_DIR/utils/leaderboard.sh' --check"
   293	# The staged preview was rendered from the MERGED ledger, not the stale ours-side: the bake
   294	# embeds the ledger's telemetry, and byte-comparing two bakes is wrong by design (each embeds
   295	# its own generatedAtDisplay timestamp). Ours-side-only would say releasesTotal 1; the merge
   296	# carried both sides' releases, so the regenerated bake must say 2.
   297	ok "staged RELEASES-PREVIEW.html reflects the MERGED ledger (both sides' releases present)" \
   298	   "grep -q '\"releasesTotal\": 2' '$R8/RELEASES-PREVIEW.html'"
   299	
   300	echo
   301	echo "  gh57-live-merge-resolve: $pass pass, $fail fail"
   302	[ "$fail" -eq 0 ]
     1	#!/usr/bin/env bash
     2	# test/roadmap-dashboard.sh — regression lock for utils/roadmap-dashboard.sh (GH-27).
     3	#
     4	# GH-351: this file used to render the dashboard INTO THE REPO and then --check the copy it had
     5	# just written, so the drift assertion could never fail. Three stale dashboards reached
     6	# `development` under a green gate on 2026-07-30 alone, from three different authors. Two rules
     7	# now hold, and the ordering of the cases below is load-bearing:
     8	#
     9	#   1. --check runs FIRST, against the COMMITTED artifact, before anything in this file writes.
    10	#   2. Nothing here ever writes $ROOT/ROADMAP-DASHBOARD.md. Write-mode is exercised against a
    11	#      temp path via ROADMAP_DASHBOARD_OUTPUT, which the renderer already supports.
    12	#
    13	# Case 4 is the one that keeps this honest: it proves --check ACTUALLY FAILS on a drifted
    14	# artifact. Without it this file would just be a differently-shaped version of the same bug —
    15	# an assertion that cannot distinguish the bug from the fix.
    16	
    17	set -uo pipefail
    18	
    19	HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    20	ROOT="$(cd "$HERE/.." && pwd)"
    21	RENDERER="$ROOT/utils/roadmap-dashboard.sh"
    22	ARTIFACT="$ROOT/ROADMAP-DASHBOARD.md"
    23	SOURCE="$ROOT/ROADMAP.md"
    24	
    25	PASS=0
    26	FAIL=0
    27	SKIP=0
    28	pass() { echo "  PASS: $*"; PASS=$((PASS + 1)); }
    29	fail() { echo "  FAIL: $*" >&2; FAIL=$((FAIL + 1)); }
    30	skip() { echo "  SKIP: $*"; SKIP=$((SKIP + 1)); }
    31	
    32	echo "== test: roadmap-dashboard =="
    33	
    34	# GH-110 P2b: ROADMAP-DASHBOARD.md is a repo-root artifact that does not travel with a vendored
    35	# install (VENDOR_DIRS mirrors relay-automation/bin/src/utils/test/skills only). In a vendored copy
    36	# there is nothing here to render/check, so skip the whole ROADMAP-DASHBOARD.md-dependent case
    37	# rather than dangle-fail — mirrors the guard already landed in test/oracle-guard.sh.
    38	if [ -e "$ARTIFACT" ]; then
    39	
    40	TMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/roadmap-dashboard-test.XXXXXX")"
    41	trap 'rm -rf "$TMP_ROOT"' EXIT
    42	
    43	# Fingerprint the committed artifact up front. Case 7 re-checks it at the end to prove this file
    44	# left the working tree alone — the side effect that made the old version destructive as well as
    45	# tautological.
    46	artifact_sum_before="$(cksum < "$ARTIFACT")"
    47	
    48	# --- Case 1: THE GATE. --check against the committed artifact, before anything writes. --------
    49	out="$(bash "$RENDERER" --check 2>&1)"; rc=$?
    50	if [[ $rc -eq 0 ]]; then
    51	  pass "--check passes on the COMMITTED artifact (nothing regenerated first)"
    52	else
    53	  fail "committed ROADMAP-DASHBOARD.md is stale — regenerate it with 'bash utils/roadmap-dashboard.sh'"$'\n'"$out"
    54	fi
    55	
    56	# --- Case 2: write-mode still works, redirected away from the repo -----------------------------
    57	tmp_out="$TMP_ROOT/written.md"
    58	out="$(ROADMAP_DASHBOARD_OUTPUT="$tmp_out" bash "$RENDERER" 2>&1)"; rc=$?
    59	if [[ $rc -eq 0 && -s "$tmp_out" ]]; then
    60	  pass "renderer writes a dashboard (to a temp path, never \$ROOT)"
    61	else
    62	  fail "renderer exited $rc or wrote nothing — $out"
    63	fi
    64	
    65	# --- Case 3: a fresh render of the current ROADMAP equals the committed artifact ---------------
    66	# Same property as case 1, reached independently: byte-compare rather than trusting --check's rc.
    67	if cmp -s "$tmp_out" "$ARTIFACT"; then
    68	  pass "a fresh render is byte-identical to the committed artifact"
    69	else
    70	  fail "fresh render differs from the committed artifact:"$'\n'"$(diff -u "$ARTIFACT" "$tmp_out" | head -20)"
    71	fi
    72	
    73	# --- Case 4: THE MUTATION PROOF. --check must actually FAIL on drift. -------------------------
    74	# Without this, cases 1 and 3 are unfalsifiable and this file repeats GH-351 in a new shape.
    75	drift_art="$TMP_ROOT/drifted.md"

exec
/bin/zsh -lc "printf '%s\\n' '--- guard target ---'; nl -ba githooks/dashboard-staleness-guard.sh | sed -n '112,195p'; printf '%s\\n' '--- renderer bottom ---'; nl -ba utils/roadmap-dashboard.sh | sed -n '36,270p'; printf '%s\\n' '--- gh243 cases ---'; nl -ba test/gh243-dashboard-staleness-guard.sh | sed -n '1,245p'; printf '%s\\n' '--- gh257 case 11 vicinity ---'; rg -n -C 18 'case 11|11\\.|dropped|staleness guard' test/gh257-roadmap-ledger-fixes.sh; printf '%s\\n' '--- exact check invocations excluding generated records ---'; rg -n --glob '"'!relay-system/**'"' --glob '"'!temp/**'"' 'roadmap-dashboard\\.sh.*--check' ." in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-33750-j8h2ug9_
 succeeded in 6ms:
exec
/bin/zsh -lc "printf '%s\\n' '--- renderer source selection and roadmap section validation ---'; rg -n -C 3 'Queue / parked intake|Deferred · vision|VALID.*SECTION|section.*choices|section.*in \\(|validate.*section|ROADMAP_SECTIONS|roadmap.*section' utils/py/releases_app.py | sed -n '1,500p'; printf '%s\\n' '--- gh474 project / recon ---'; nl -ba PROJECT/2-WORKING/GH-474-DASHBOARD-DROPPED-ROW-SIGNAL.md | sed -n '1,240p'; nl -ba PROJECT/1-INBOX/recon-gh474-dropped-row-signal.md | sed -n '1,200p'; printf '%s\\n' '--- test dashboard remaining ---'; nl -ba test/roadmap-dashboard.sh | sed -n '70,170p'; printf '%s\\n' '--- check pipeline side behaviour in bash docs ---'; bash --version | head -1" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-33750-j8h2ug9_
 succeeded in 0ms:
--- renderer source selection and roadmap section validation ---
3147-        def mutate(conn):
3148-            _ensure_roadmap_schema(conn)
3149-            ts = now_iso()
3150:            section = "Queue / parked intake"   # the canonical ledger queue heading (GH-243)
3151:            max_pos = conn.execute("SELECT MAX(position) FROM roadmap_items WHERE section = ?", (section,)).fetchone()
3152-            pos = (max_pos[0] or 0) + 1 if max_pos else 1
3153-            
3154-            repo = conn.execute("SELECT id FROM repos ORDER BY id LIMIT 1").fetchone()
--
3372-
3373-
3374-def cmd_roadmap_move(args):
3375:    """GH-269: move a roadmap row to a new section (e.g. 'Completed', 'Deferred / cancelled')."""
3376-    return cmd_roadmap_update(args)
3377-
3378-
--
3551-            # a display, not an API — its column offsets shift whenever a field widens.
3552-            rows = []
3553-            if _table_exists(conn, "roadmap_items"):
3554:                for r in conn.execute("SELECT * FROM roadmap_items ORDER BY section, position"):
3555-                    rows.append({"global_id": r["global_id"], "gh_number": r["gh_number"],
3556-                                 "title": r["title"], "section": r["section"],
3557-                                 "position": r["position"], "status_marker": r["status_marker"],
--
3562-        if not _table_exists(conn, "roadmap_items"):
3563-            print("(no roadmap shadow yet — run `releases roadmap sync`)")
3564-            return
3565:        for r in conn.execute("""SELECT * FROM roadmap_items ORDER BY section, position"""):
3566-            gh = ("GH-%d" % r["gh_number"]) if r["gh_number"] is not None else "-"
3567-            cre = ("%s/%s/%s" % (r["complexity"], r["risk"], r["effort"])
3568-                   if r["complexity"] is not None else "-")
--
4535-                     (row["import_run"], rgid, row["rule"], row.get("source_value"),
4536-                      row.get("supplied_value"), row.get("disposition")))
4537-    for row in tables.get("roadmap_items", []):
4538:        conn.execute("""INSERT INTO roadmap_items(global_id, repo_id, gh_number, title, section,
4539-                        position, status_marker, complexity, risk, effort, doc_path, issue_url,
4540-                        raw_text, first_seen, updated_at,
4541-                        rating_pri, rating_sev, rating_appeal, rating_effort, rating_ovr)
--
4741-            ORDER BY position
4742-        """).fetchall()
4743-        
4744:        roadmap_by_section = {}
4745-        for item in roadmap_items:
4746:            roadmap_by_section.setdefault(item["section"], []).append(item)
4747-            
4748-        roadmap_html = "<h2>Roadmap</h2>"
4749:        for section, items in roadmap_by_section.items():
4750:            roadmap_html += f"<h3>{section}</h3><ul>"
4751-            for i in items:
4752-                gh = f"GH-{i['gh_number']} " if i['gh_number'] else ""
4753-                roadmap_html += f"<li>{i['status_marker'] or ''} {gh}{i['title']}</li>"
--
4993-    sp_ru.add_argument("--section", help="move the row to a new section (e.g. Completed/Deferred)")
4994-    sp_ru.add_argument("--dry-run", action="store_true", help="print what would be written and write nothing")
4995-
4996:    sp_rm = rsub.add_parser("move", help="move an existing roadmap row to a new section (GH-269)")
4997-    sp_rm.add_argument("--issue-num", type=int, help="GH issue number of the parked row")
4998-    sp_rm.add_argument("--gid", help="the row's rmi- global id")
4999-    sp_rm.add_argument("--section", required=True, help="new section name (e.g. 'Completed', 'Deferred / cancelled')")
--- gh474 project / recon ---
     1	---
     2	title: "GH-474: the staleness guard reads the renderer's dropped-row warning instead of guessing from table names"
     3	status: Active
     4	created: 2026-09-07
     5	updated: 2026-09-07
     6	owner: orchestrator (Claude Code)
     7	goal: githooks/dashboard-staleness-guard.sh refuses a push only when the renderer actually reports a dropped roadmap row, and names that row — replacing the table-name allowlist that produced false refusals
     8	gh_issue: 474
     9	source: https://github.com/HiQS-Labs/XYZ-forge/issues/474
    10	branch: fix/gh474-dropped-row-signal
    11	doc_type: bugfix
    12	effort: 1
    13	complexity: 2
    14	risk: 2
    15	related:
    16	  - "#243 — the guard itself; this repairs its input signal"
    17	  - "#315 — the first time the table allowlist went short (jog_queue)"
    18	  - "#257 — the malformed-row fixture that proves the signal end-to-end"
    19	non_goals:
    20	  - Removing, untracking, or gitignoring ROADMAP-DASHBOARD.md or LEADERBOARD.md
    21	  - Changing utils/roadmap-dashboard.sh, including its --check exit contract
    22	  - Retiring githooks/dashboard-staleness-guard.sh
    23	---
    24	
    25	# GH-474 — the guard asks the renderer instead of guessing
    26	
    27	## Status
    28	
    29	| What was just completed | What's next |
    30	|---|---|
    31	| guard reads the renderer's stderr and refuses on the dropped-row warning, naming the row; table classifier deleted; `gh243` rewritten with a real red control; `gh257` case 11 now asserts the row id through the real projection | full gate in a disposable clone, then PR |
    32	
    33	## The defect
    34	
    35	The guard refuses a push whose range writes the roadmap ledger without moving
    36	`ROADMAP-DASHBOARD.md`. When regenerating produces **no diff**, one hazard remains: a row the
    37	renderer *dropped*. A dropped row renders to nothing, so the committed artifact still matches
    38	byte-for-byte while the ledger row is invisible in the view — drift detection alone cannot see it.
    39	
    40	To detect that, the guard classified the `releases.sql` diff **by table name** against a
    41	hand-maintained allowlist. That allowlist went short twice (GH-315 for `jog_queue`, then
    42	`marathons`/`issue_refs`), and eight dump tables were still unclassified — `doc_lines`,
    43	`grandfather_entries`, `legacy_lines`, `manifest_items`, `manifest_state_events`, `releases`,
    44	`repos`, `schema_migrations`. Each was a latent **false refusal**; `releases add` alone tripped it.
    45	
    46	## The finding that shrank the fix
    47	
    48	The renderer already answers the question directly, and the guard was throwing the answer away.
    49	
    50	| `utils/roadmap-dashboard.sh` | What happens |
    51	| --- | --- |
    52	| `:89` | the node render runs — **unconditionally, in both modes** |
    53	| `:200-203` | every unparseable line is pushed onto `droppedRows` |
    54	| `:217-220` | `roadmap-dashboard: warning: dropped N unparseable row(s): <ids>` → **stderr** |
    55	| `:251` | *only now* does the `MODE == "check"` branch compare and exit |
    56	
    57	So `--check` already names every dropped row. `dashboard-staleness-guard.sh:123` discarded it with
    58	`>/dev/null 2>&1` and then inferred the same fact from table names.
    59	
    60	**This is why the issue's original plan — give `--check` a new exit code — is not needed and not
    61	wanted.** `--check`'s exit contract has five consumers, four of them suites that treat any non-zero
    62	as failure (`test/gh269-roadmap-retired.sh:26`, `test/gh280-jog-marathon-adapter.sh:1021,1033`,
    63	`test/gh57-live-merge-resolve.sh:290`, `test/roadmap-dashboard.sh:49`). Adding exit `2` would newly
    64	fail all four the first time a fixture carried a malformed row. Reading stderr changes none of them.
    65	
    66	## The change
    67	
    68	One file, `githooks/dashboard-staleness-guard.sh`:
    69	
    70	1. Keep the renderer's stderr — `2>&1 >/dev/null`, order significant — in `render_err`. The
    71	   assignment carries the renderer's exit status, so the drift verdict is unchanged.
    72	2. In the no-drift arm, refuse if and only if `render_err` carries the dropped-row warning, and
    73	   **quote the warning in the refusal** so the operator knows which row to fix.
    74	3. Delete the table classifier.
    75	
    76	`utils/roadmap-dashboard.sh` is untouched.
    77	
    78	## Direction of failure
    79	
    80	The old mechanism could go short: a table nobody enumerated fell to the catch-all and produced a
    81	false refusal. The new one cannot, because an unknown table is no longer a question the guard asks —
    82	it reads the renderer's own report. If the renderer is silent, the row rendered.
    83	
    84	## Proof
    85	
    86	- `test/gh243-dashboard-staleness-guard.sh` — tests 7/7b/8/8b rewritten. **7b is the regression
    87	  fixture**: a write touching `releases`, `repos`, `manifest_items`, `doc_lines`,
    88	  `schema_migrations` and a deliberately invented table, all of which the old allowlist falsely
    89	  refused, now passes. **8 is the red control**: same shape, renderer reports a dropped row →
    90	  refuse, and the refusal must name `#256`. **8b** proves unrelated stderr chatter is not read as a
    91	  dropped row.
    92	- `test/gh257-roadmap-ledger-fixes.sh` case 11 — the **real** renderer, driven through the guard's
    93	  `git archive` projection with an injected malformed row, now asserts the refusal names `#256`.
    94	  This settles the recon's one open unknown (does the warning survive the projection?): with the
    95	  classifier deleted, that assertion can pass only via the stderr signal.
    96	
    97	Both suites pass.
    98	
    99	## Rollback
   100	
   101	Revert one commit. No data, no schema, no generated artifact, no contract change.
   102	
   103	## What this issue is no longer
   104	
   105	The issue previously carried a plan to remove — then untrack — `ROADMAP-DASHBOARD.md` and
   106	`LEADERBOARD.md`. That was rejected on evidence: `AGENTS.md:139-143` and `GUIDING-PRINCIPLES.md:77`
   107	route to the dashboard with no CLI alternative, and `utils/py/router_audit.py` is a hard gate (via
   108	`test/gh353-vendored-router-audit.sh`) requiring `ROUTER.md` to declare the dashboard as the
   109	generated view. Untracking meant rewriting a gate to accommodate a convenience change. See
   110	[recon-roadmap-dashboard-removal.md](../1-INBOX/recon-roadmap-dashboard-removal.md) and
   111	[recon-leaderboard-removal.md](../1-INBOX/recon-leaderboard-removal.md), both rewritten to the plan
   112	of record; transcripts in `relay-system/2026-09-07/`.
   113	
   114	The rendered **HTML** views (`LEADERBOARD.html`, `RELEASES-PREVIEW.html`) remain a separate, live
   115	removal on `fix/gh474-retire-rendered-html` — they are pure adoption-by-presence with no guard and
   116	no governance route.
   117	
   118	## Architecture
   119	
   120	The guard ↔ renderer ↔ ledger loop is now diagrammed in
   121	[ARCHITECTURE.md](../../ARCHITECTURE.md#the-roadmap-view-pipeline-and-its-push-guard), including why
   122	the dropped-row signal travels on stderr rather than as an exit code.
     1	# Recon Map — GH-474 Option B: replace the guard's table classifier with the renderer's dropped-row signal
     2	
     3	Commit: `2e4f8d48` · Mode: grep-only (no knowledge graph) · Lanes: A–D, run serially in the main
     4	context. Radius is two files plus five call sites; a four-agent fan-out would have been ceremony.
     5	
     6	## Subject and change class
     7	
     8	Subject: the decision path in `githooks/dashboard-staleness-guard.sh` that answers *"did the renderer
     9	silently drop a roadmap row?"*, and the `--check` contract of `utils/roadmap-dashboard.sh` it
    10	currently infers that answer from.
    11	
    12	Change class: **contract change** — but see the headline finding, which shrinks it to a local edit.
    13	
    14	## Headline finding — the signal already exists and is being discarded
    15	
    16	The plan in #474 proposed giving `--check` a new machine-readable result for "rows were dropped".
    17	**That is not necessary.** Tracing the renderer top to bottom:
    18	
    19	| Line | What happens |
    20	| --- | --- |
    21	| `utils/roadmap-dashboard.sh:23,30` | `MODE` defaults to `write`, `--check` sets it to `check` |
    22	| `utils/roadmap-dashboard.sh:43` | `RENDERED="$TMP_DIR/ROADMAP-DASHBOARD.md"` |
    23	| `utils/roadmap-dashboard.sh:89` | the node render runs — **unconditionally, in both modes** |
    24	| `utils/roadmap-dashboard.sh:200-203` | every unparseable line is pushed onto `droppedRows` |
    25	| `utils/roadmap-dashboard.sh:217-220` | `roadmap-dashboard: warning: dropped N unparseable row(s): <ids>` → **stderr** |
    26	| `utils/roadmap-dashboard.sh:251` | *only now* does the `MODE == "check"` branch compare and exit |
    27	
    28	So `--check` **already emits the dropped-row warning on stderr, by name, with the row ids** — the
    29	exact fact the guard needs. The guard then throws it away:
    30	
    31	```bash
    32	# githooks/dashboard-staleness-guard.sh:123
    33	if bash "$TMP_PROJ/utils/roadmap-dashboard.sh" --check >/dev/null 2>&1; then
    34	```
    35	
    36	`2>&1` sends the warning to `/dev/null` alongside stdout. Having discarded the direct answer, the
    37	guard falls back to guessing from table names — the classifier at `:147-178` that has now gone short
    38	twice.
    39	
    40	**Consequence: Option B is a one-file change.** `utils/roadmap-dashboard.sh` does not need to change
    41	at all.
    42	
    43	## The seams
    44	
    45	| Seam | Location | Crosses | Breaks if |
    46	| --- | --- | --- | --- |
    47	| `--check` exit contract | `utils/roadmap-dashboard.sh:251-263` | 5 consumers (below) | a new exit code is introduced — **avoided by this design** |
    48	| stderr capture | `githooks/dashboard-staleness-guard.sh:123` | guard ↔ renderer | stderr stays redirected to `/dev/null` |
    49	| table classifier | `githooks/dashboard-staleness-guard.sh:147-178` | guard ↔ ledger schema | deleted by this change; nothing else reads it |
    50	| guard invocation | `githooks/pre-push:88-93` | every push in every clone with the hook | the guard's exit semantics change (they do not — still 0/1) |
    51	
    52	## Call paths in
    53	
    54	```
    55	git push
    56	  └─ githooks/pre-push:88-93
    57	       └─ githooks/dashboard-staleness-guard.sh <repo> <local_sha> <remote_sha>...
    58	            ├─ :105-113   classify range: touched_ledger? touched_dashboard?
    59	            ├─ :120-127   git archive local_sha -> TMP_PROJ, run roadmap-dashboard.sh --check
    60	            │               ^^ the render happens here; the dropped-row warning is emitted and discarded
    61	            ├─ :131-140   drift branch  -> refuse (unchanged by this plan)
    62	            └─ :142-178   no-drift branch -> TABLE CLASSIFIER (the thing being deleted)
    63	```
    64	
    65	## Contracts — the five consumers of `--check`
    66	
    67	This is the reason the exit contract must **not** change. Every one treats non-zero as failure, and
    68	today a dropped row with a matching artifact exits **0**:
    69	
    70	| Consumer | Line | Shape |
    71	| --- | --- | --- |
    72	| the guard | `githooks/dashboard-staleness-guard.sh:123` | `if ... --check >/dev/null 2>&1` |
    73	| `test/gh269-roadmap-retired.sh` | `:26` | `if --check; then pass else fail` |
    74	| `test/gh280-jog-marathon-adapter.sh` | `:1021`, `:1033` | `--check && pass \|\| fail` (twice) |
    75	| `test/gh57-live-merge-resolve.sh` | `:290` | `ok "staged dashboard matches a fresh render (--check in sync)"` |
    76	| `test/roadmap-dashboard.sh` | `:49-55` | `rc -eq 0 → pass`, else "committed artifact is stale" |
    77	
    78	Introducing exit `2` for "rows dropped" would newly fail all four test consumers the first time a
    79	fixture contains a malformed row. Reading stderr instead leaves all five untouched.
    80	
    81	## State
    82	
    83	Read sites: the guard reads `releases.sql` diffs (classifier — being deleted) and the renderer's
    84	output. Write sites: none; this change writes nothing. Source of truth is `releases.db`; the
    85	`droppedRows` array is transient per-render state, already surfaced on stderr and nowhere persisted.
    86	
    87	## Build, failure and rollback today
    88	
    89	- Build: no build step; both files are shell.
    90	- Failure today: the guard refuses with a **false** "a parked row was dropped" message for any ledger
    91	  write touching an unclassified table (8 remain: `doc_lines`, `grandfather_entries`, `legacy_lines`,
    92	  `manifest_items`, `manifest_state_events`, `releases`, `repos`, `schema_migrations`).
    93	- Failure after: the guard refuses only when the renderer actually reports dropped rows, and names
    94	  them.
    95	- Rollback: revert one file. `git revert` of a single commit; no data, no schema, no generated
    96	  artifact.
    97	
    98	## Unknowns
    99	
   100	| Unknown | Why it matters | What would settle it |
   101	| --- | --- | --- |
   102	| Does the warning survive `git archive` into `TMP_PROJ`? The guard renders from a commit-pinned projection, not the worktree. | If the projection lacks `releases.db`, the render there may fail for an unrelated reason and never reach the warning. | Run the guard against a commit containing a known malformed row and capture stderr — `test/gh257-roadmap-ledger-fixes.sh:212-255` already builds exactly that fixture and can be extended to assert it. |
   103	
   104	One unknown, and it is the one that must be resolved by a runnable check rather than by reading —
   105	recorded rather than smoothed over.
   106	
   107	## Current-state radius, one line
   108	
   109	Every developer and agent pushing to this repo with the hook installed, via `githooks/pre-push`; no
   110	data, no published artifact, and no other repo — the guard is per-clone and writes nothing.
--- test dashboard remaining ---
    70	  fail "fresh render differs from the committed artifact:"$'\n'"$(diff -u "$ARTIFACT" "$tmp_out" | head -20)"
    71	fi
    72	
    73	# --- Case 4: THE MUTATION PROOF. --check must actually FAIL on drift. -------------------------
    74	# Without this, cases 1 and 3 are unfalsifiable and this file repeats GH-351 in a new shape.
    75	drift_art="$TMP_ROOT/drifted.md"
    76	cp "$ARTIFACT" "$drift_art"
    77	printf '\n| DRIFT-CANARY | injected-by-test | GH-351 |\n' >> "$drift_art"
    78	out="$(ROADMAP_DASHBOARD_OUTPUT="$drift_art" bash "$RENDERER" --check 2>&1)"; rc=$?
    79	if [[ $rc -ne 0 ]]; then
    80	  pass "--check FAILS on a drifted artifact (rc=$rc) — the assertion is falsifiable"
    81	else
    82	  fail "--check passed a deliberately drifted artifact — GH-351 has regressed in a new shape"
    83	fi
    84	
    85	# --- Case 5: --check fails on a MISSING artifact, rather than passing vacuously ----------------
    86	out="$(ROADMAP_DASHBOARD_OUTPUT="$TMP_ROOT/does-not-exist.md" bash "$RENDERER" --check 2>&1)"; rc=$?
    87	if [[ $rc -ne 0 ]]; then
    88	  pass "--check fails on a missing artifact (rc=$rc)"
    89	else
    90	  fail "--check passed with no artifact present — a vacuous green"
    91	fi
    92	
    93	# --- Case 6: drift in the SOURCE is detected, not just in the artifact -------------------------
    94	# The real-world failure is always this direction: ROADMAP.md moves, the dashboard does not.
    95	drift_src="$TMP_ROOT/ROADMAP-changed.md"
    96	sed 's/^### Queue \/ parked intake$/### Queue \/ parked intake\n- **GH-000 · canary entry injected by test\*\* 🆕 — not a real item./' \
    97	  "$SOURCE" > "$drift_src"
    98	if cmp -s "$drift_src" "$SOURCE"; then
    99	  skip "case 6: could not inject a source canary (ROADMAP.md layout changed)"
   100	else
   101	  out="$(ROADMAP_DASHBOARD_SOURCE="$drift_src" ROADMAP_DASHBOARD_OUTPUT="$ARTIFACT" bash "$RENDERER" --check 2>&1)"; rc=$?
   102	  if [[ $rc -ne 0 ]]; then
   103	    pass "--check FAILS when ROADMAP.md gains an item the dashboard lacks (the real-world case)"
   104	  else
   105	    fail "--check passed while the source had an extra entry — drift is undetectable"
   106	  fi
   107	fi
   108	
   109	# --- Case 7: this test did not mutate the working tree ----------------------------------------
   110	# The old version regenerated $ROOT/ROADMAP-DASHBOARD.md as a side effect, so `validate.sh` could
   111	# silently un-stale a dashboard mid-run and hide the very drift it was meant to catch.
   112	if [ "$(cksum < "$ARTIFACT")" = "$artifact_sum_before" ]; then
   113	  pass "committed artifact is byte-unchanged — this test writes nothing into \$ROOT"
   114	else
   115	  fail "this test MUTATED \$ROOT/ROADMAP-DASHBOARD.md — the GH-351 side effect is back"
   116	fi
   117	
   118	# --- Case 8: the do-not-edit banner ------------------------------------------------------------
   119	if grep -qx '<!-- GENERATED by utils/roadmap-dashboard.sh — DO NOT EDIT; edit ROADMAP.md -->' "$ARTIFACT"; then
   120	  pass "artifact carries the do-not-edit banner"
   121	else
   122	  fail "artifact is missing the generated banner"
   123	fi
   124	
   125	# --- Case 9: section counts match ROADMAP.md ---------------------------------------------------
   126	# GH-243: in a releases-mode repo the dashboard renders from the RELEASES DB and ROADMAP.md is
   127	# frozen legacy — the DB legitimately gains rows the frozen file never will, so text-parity is
   128	# no longer an invariant. Cases 1/3/4/6 already pin artifact-vs-live-source fidelity via --check
   129	# (which regenerates from the real source, DB included); this case guards legacy repos only.
   130	if grep -q "ROADMAP_SOURCE=releases" "$ROOT/.pdda-mode" 2>/dev/null; then
   131	  pass "case 9 skipped: releases-mode — dashboard parity is against the DB (covered by --check), not the frozen ROADMAP.md"
   132	else
   133	counts_out="$(SOURCE_PATH="$SOURCE" ARTIFACT_PATH="$ARTIFACT" node <<'NODE' 2>&1
   134	const fs = require("fs");
   135	
   136	const sourcePath = process.env.SOURCE_PATH;
   137	const artifactPath = process.env.ARTIFACT_PATH;
   138	const expectedSections = [
   139	  "Queue / parked intake",
   140	  "In progress",
   141	  "Completed",
   142	  "Deferred · vision",
   143	];
   144	
   145	const sourceLines = fs.readFileSync(sourcePath, "utf8").split(/\r?\n/);
   146	const artifactLines = fs.readFileSync(artifactPath, "utf8").split(/\r?\n/);
   147	
   148	function extractRoadmapCounts(lines) {
   149	  const counts = {};
   150	  let inLedger = false;
   151	  let current = null;
   152	  for (const section of expectedSections) counts[section] = 0;
   153	
   154	  for (const line of lines) {
   155	    if (!inLedger) {
   156	      if (/^##\s+Ledger\s*$/.test(line.trim())) inLedger = true;
   157	      continue;
   158	    }
   159	    if (/^##\s+/.test(line) && !/^##\s+Ledger\s*$/.test(line.trim())) break;
   160	    const sectionMatch = line.match(/^###\s+(.+?)\s*$/);
   161	    if (sectionMatch) {
   162	      current = counts.hasOwnProperty(sectionMatch[1].trim()) ? sectionMatch[1].trim() : null;
   163	      continue;
   164	    }
   165	    if (current && /^- \*\*/.test(line)) counts[current] += 1;
   166	  }
   167	  return counts;
   168	}
   169	
   170	function extractDashboardCounts(lines) {
--- check pipeline side behaviour in bash docs ---
GNU bash, version 3.2.57(1)-release (arm64-apple-darwin24)

exec
/bin/zsh -lc "nl -ba utils/py/releases_app.py | sed -n '3040,3225p;3260,3415p;3520,3580p;4970,5010p'; printf '%s\\n' '--- full exact exit checks via token scan excluding docs and relay ---'; rg -l --glob '"'!relay-system/**'"' --glob '"'!temp/**'"' 'roadmap-dashboard\\.sh' . | while IFS= read -r f; do case \""'$f" in *.sh|*.py) rg -n -- '"'roadmap-dashboard\\.sh.*--check|--check.*roadmap-dashboard\\.sh' \""'$f";; esac; done; printf '"'%s\\n' '--- current projection requirements ---'; git ls-tree -r --name-only HEAD | rg '"'^(releases'"\\.db|releases\\.sql|ROADMAP\\.md|ROADMAP-DASHBOARD\\.md|utils/roadmap-dashboard\\.sh|utils/py/releases_app\\.py|utils/py/harness_paths\\.py)"'$'"'; printf '%s\\n' '--- diff stat/name ---'; git diff --stat development; git diff --name-only development" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-33750-j8h2ug9_
 succeeded in 7337ms:
130:      if render_err="$(bash "$TMP_PROJ/utils/roadmap-dashboard.sh" --check 2>&1 >/dev/null)"; then
1021:bash "$FR/utils/roadmap-dashboard.sh" --check >/dev/null 2>&1 \
1033:bash "$FR/utils/roadmap-dashboard.sh" --check >/dev/null 2>&1 \
290:   "ROADMAP_DASHBOARD_ROOT='$R8' bash '$ROOT_DIR/utils/roadmap-dashboard.sh' --check"
--- current projection requirements ---
git: warning: confstr() failed with code 5: couldn't get path of DARWIN_USER_TEMP_DIR; using /tmp instead
git: error: couldn't create cache file '/tmp/xcrun_db-JCl5oxwT' (errno=Operation not permitted)
2026-09-07 13:15:03.628 xcodebuild[93713:4514054]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-09-07 13:15:03.983 xcodebuild[93713:4514013] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.
git: warning: confstr() failed with code 5: couldn't get path of DARWIN_USER_TEMP_DIR; using /tmp instead
git: error: couldn't create cache file '/tmp/xcrun_db-RSil7B3D' (errno=Operation not permitted)
2026-09-07 13:15:04.607 xcodebuild[94343:4514940]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-09-07 13:15:04.805 xcodebuild[94343:4514939] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.
ROADMAP-DASHBOARD.md
releases.db
releases.sql
utils/py/harness_paths.py
utils/py/releases_app.py
utils/roadmap-dashboard.sh
--- diff stat/name ---
git: warning: confstr() failed with code 5: couldn't get path of DARWIN_USER_TEMP_DIR; using /tmp instead
git: error: couldn't create cache file '/tmp/xcrun_db-xAFmdhGs' (errno=Operation not permitted)
2026-09-07 13:15:06.062 xcodebuild[94402:4515145]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-09-07 13:15:06.260 xcodebuild[94402:4515144] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.
git: warning: confstr() failed with code 5: couldn't get path of DARWIN_USER_TEMP_DIR; using /tmp instead
git: error: couldn't create cache file '/tmp/xcrun_db-Vo3XgyfP' (errno=Operation not permitted)
2026-09-07 13:15:06.812 xcodebuild[94405:4515175]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-09-07 13:15:07.014 xcodebuild[94405:4515174] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.
 ARCHITECTURE.md                                    |   84 +-
 LEADERBOARD.md                                     |   98 +-
 PROJECT/1-INBOX/GH-481-CONSULT-AGY-STALE-TREE.md   |   56 +
 .../GH-482-RELAY-ARTIFACT-FILE-SILENT-NOOP.md      |   50 +
 PROJECT/1-INBOX/recon-gh474-dropped-row-signal.md  |  110 +
 PROJECT/1-INBOX/recon-leaderboard-removal.md       |   90 +-
 PROJECT/1-INBOX/recon-roadmap-dashboard-removal.md |  130 +-
 .../GH-474-DASHBOARD-DROPPED-ROW-SIGNAL.md         |  122 +
 ROADMAP-DASHBOARD.md                               |    6 +-
 githooks/dashboard-staleness-guard.sh              |   70 +-
 harnesses.db                                       |  Bin 364544 -> 364544 bytes
 harnesses.sql                                      |    1 +
 .../gh474-md-views.PROMPT.txt                      |   80 +
 .../gh474-md-views.agy.PROVENANCE.txt              |    3 +
 .../gh474-md-views-101147/gh474-md-views.agy.md    |   13 +
 .../gh474-md-views.codex.NO-CITATION.txt           |    1 +
 .../gh474-md-views.codex.PROVENANCE.txt            |   30 +
 .../gh474-md-views-101147/gh474-md-views.codex.md  | 7163 ++++++++++++++++++++
 relay-system/2026-09-07/gh474-plan-review.md       |  118 +
 releases.db                                        |  Bin 557056 -> 557056 bytes
 releases.sql                                       |   12 +-
 test/gh243-dashboard-staleness-guard.sh            |   82 +-
 test/gh257-roadmap-ledger-fixes.sh                 |   11 +
 23 files changed, 8147 insertions(+), 183 deletions(-)
git: warning: confstr() failed with code 5: couldn't get path of DARWIN_USER_TEMP_DIR; using /tmp instead
git: error: couldn't create cache file '/tmp/xcrun_db-r6YsJ4b0' (errno=Operation not permitted)
2026-09-07 13:15:08.418 xcodebuild[94453:4515299]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-09-07 13:15:08.620 xcodebuild[94453:4515296] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.
git: warning: confstr() failed with code 5: couldn't get path of DARWIN_USER_TEMP_DIR; using /tmp instead
git: error: couldn't create cache file '/tmp/xcrun_db-vMtZgv5t' (errno=Operation not permitted)
2026-09-07 13:15:09.185 xcodebuild[94481:4515433]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-09-07 13:15:09.387 xcodebuild[94481:4515432] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.
ARCHITECTURE.md
LEADERBOARD.md
PROJECT/1-INBOX/GH-481-CONSULT-AGY-STALE-TREE.md
PROJECT/1-INBOX/GH-482-RELAY-ARTIFACT-FILE-SILENT-NOOP.md
PROJECT/1-INBOX/recon-gh474-dropped-row-signal.md
PROJECT/1-INBOX/recon-leaderboard-removal.md
PROJECT/1-INBOX/recon-roadmap-dashboard-removal.md
PROJECT/2-WORKING/GH-474-DASHBOARD-DROPPED-ROW-SIGNAL.md
ROADMAP-DASHBOARD.md
githooks/dashboard-staleness-guard.sh
harnesses.db
harnesses.sql
relay-system/2026-09-07/gh474-md-views-101147/gh474-md-views.PROMPT.txt
relay-system/2026-09-07/gh474-md-views-101147/gh474-md-views.agy.PROVENANCE.txt
relay-system/2026-09-07/gh474-md-views-101147/gh474-md-views.agy.md
relay-system/2026-09-07/gh474-md-views-101147/gh474-md-views.codex.NO-CITATION.txt
relay-system/2026-09-07/gh474-md-views-101147/gh474-md-views.codex.PROVENANCE.txt
relay-system/2026-09-07/gh474-md-views-101147/gh474-md-views.codex.md
relay-system/2026-09-07/gh474-plan-review.md
releases.db
releases.sql
test/gh243-dashboard-staleness-guard.sh
test/gh257-roadmap-ledger-fixes.sh

exec
/bin/zsh -lc "printf '%s\\n' '--- actual current roadmap sections ---'; sqlite3 releases.db 'SELECT quote(section), count(*) FROM roadmap_items GROUP BY section ORDER BY section;' 2>&1; printf '%s\\n' '--- renderer ignored-section logic and public update path ---'; nl -ba utils/roadmap-dashboard.sh | sed -n '96,106p;170,220p'; nl -ba utils/py/releases_app.py | sed -n '3295,3376p;4984,5001p'; printf '%s\\n' '--- test invocation registration ---'; rg -n --glob '"'!relay-system/**'"' 'gh243-dashboard-staleness-guard|gh257-roadmap-ledger-fixes' validate.sh test .github 2>/dev/null; printf '%s\\n' '--- test suite exact old-vs-new (source diff) ---'; git diff --unified=20 development -- test/gh243-dashboard-staleness-guard.sh test/gh257-roadmap-ledger-fixes.sh" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-33750-j8h2ug9_
 succeeded in 2183ms:
2026-09-07 13:15:33.801 xcodebuild[95431:4518282]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-09-07 13:15:34.007 xcodebuild[95431:4518277] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.
git: warning: confstr() failed with code 5: couldn't get path of DARWIN_USER_TEMP_DIR; using /tmp instead
git: error: couldn't create cache file '/tmp/xcrun_db-amXwQJjN' (errno=Operation not permitted)
2026-09-07 13:15:34.565 xcodebuild[95461:4518354]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-09-07 13:15:34.766 xcodebuild[95461:4518353] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.
diff --git a/test/gh243-dashboard-staleness-guard.sh b/test/gh243-dashboard-staleness-guard.sh
index a9364165..6bd8811d 100644
--- a/test/gh243-dashboard-staleness-guard.sh
+++ b/test/gh243-dashboard-staleness-guard.sh
@@ -46,82 +46,102 @@ bash "$GUARD" "$R" "$LEDGER_ONLY" "$BASE" || fail "legacy-mode repo must not be
 cd "$R"; echo "ROADMAP_SOURCE=releases" > .pdda-mode; cd "$root"
 
 # 4. New branch (all-zero remote sha) -> no range, no refusal.
 bash "$GUARD" "$R" "$LEDGER_ONLY" "0000000000000000000000000000000000000000" \
   || fail "new-branch push must fall through, got $?"
 
 # 5. Non-ledger range (docs commit only) -> pass.
 cd "$R"
 echo "readme" > README.md
 git add README.md
 git -c user.email=t@t -c user.name=t commit -q -m docs
 DOCS="$(git rev-parse HEAD)"
 cd "$root"
 bash "$GUARD" "$R" "$DOCS" "$FIXED" || fail "non-ledger range must pass, got $?"
 
 # 6. Usage error -> exit 2.
 rc=0; bash "$GUARD" >/dev/null 2>&1 || rc=$?
 [ "$rc" -eq 2 ] || fail "expected usage exit 2, got $rc"
 
 
-# 7. GH-315: jog-queue-only ledger write, renderer in-sync, no dashboard change -> ALLOW
-# (jog rows have no dashboard projection; a no-diff regen is the expected outcome, not a
-# dropped-row symptom). The fixture needs a renderer whose --check passes to reach the
-# guard's no-drift branch at all.
+# 7. GH-474: a ledger write the renderer renders cleanly -> ALLOW, whatever table it touched.
+# The guard no longer classifies by table name; it asks the renderer whether it dropped a row.
+# `jog_queue` is the GH-315 shape that first exposed the old allowlist going short. The fixture
+# needs a renderer whose --check passes to reach the guard's no-drift branch at all; this stub
+# exits 0 and says nothing on stderr, which is exactly "rendered fine, dropped nothing".
 mkdir -p "$R/utils"
 printf '#!/usr/bin/env bash\nexit 0\n' > "$R/utils/roadmap-dashboard.sh"
 chmod +x "$R/utils/roadmap-dashboard.sh"
 cd "$R"
 git add utils/roadmap-dashboard.sh
 git -c user.email=t@t -c user.name=t commit -q -m "add passing renderer"
 RENDERED="$(git rev-parse HEAD)"
 { echo "-- dump v3"
   echo "INSERT INTO settings(key, value) VALUES('generation', '9');"
   echo "INSERT INTO jog_queue VALUES('seed');"
   echo "INSERT INTO op_receipts(op, target_gid) VALUES('jog-add', 'seed');"
 } > releases.sql
 git add releases.sql
 git -c user.email=t@t -c user.name=t commit -q -m "jog-only ledger write"
 JOG_ONLY="$(git rev-parse HEAD)"
 cd "$root"
 bash "$GUARD" "$R" "$JOG_ONLY" "$RENDERED" \
   || fail "jog-queue-only ledger write must pass the no-drift branch (GH-315), got $?"
 
-# 7b. Same shape, marathon fan-out: `releases marathon add` writes marathons + issue_refs
-# alongside the op_receipts/generation rows test 7 already covers, and neither new table is
-# projected by the renderer -> ALLOW. issue_refs is included because `marathon add` creates
-# that row itself whenever the tracking URL is new, so a marathons-only allowance would still
-# refuse the common case.
-#
-# WHAT THIS PROVES, EXACTLY: that the shell classifier accepts the canonical marathon dump
-# lines. It does NOT prove the two tables lack a dashboard projection — the fixture renderer
-# above is a stub that always exits 0, so no real rendering happens here. That claim rests on
-# `roadmap list` being a flat SELECT * FROM roadmap_items (utils/py/releases_app.py:3554) with
-# issue_url a denormalized TEXT column, not a foreign key (:605). See #474.
+# 7b. THE REGRESSION THIS CHANGE FIXES. Every one of these tables hit the old allowlist's
+# catch-all and produced a FALSE refusal — `releases add` alone tripped it. They are not
+# enumerated anywhere in the guard any more, which is the point: the guard reads the renderer's
+# report, so a table it has never heard of cannot make it go short.
 cd "$R"
 { echo "-- dump v3b"
   echo "INSERT INTO settings(key, value) VALUES('generation', '10');"
-  echo "INSERT INTO issue_refs(global_id, url) VALUES('ref-1', 'https://example.invalid/1');"
-  echo "INSERT INTO marathons(global_id, tracking_ref_gid) VALUES('mar-1', 'ref-1');"
-  echo "INSERT INTO op_receipts(op, target_gid) VALUES('marathon-add', 'mar-1');"
+  echo "INSERT INTO releases(global_id, name) VALUES('rel-1', 'v9');"
+  echo "INSERT INTO repos(repo_id, name) VALUES(2, 'other');"
+  echo "INSERT INTO manifest_items(global_id) VALUES('mi-1');"
+  echo "INSERT INTO doc_lines(global_id) VALUES('dl-1');"
+  echo "INSERT INTO schema_migrations(version) VALUES('077');"
+  echo "INSERT INTO totally_new_table_v9(global_id) VALUES('nt-1');"
 } > releases.sql
 git add releases.sql
-git -c user.email=t@t -c user.name=t commit -q -m "marathon-only ledger write"
-MARATHON_ONLY="$(git rev-parse HEAD)"
+git -c user.email=t@t -c user.name=t commit -q -m "previously-unclassified ledger write"
+UNCLASSIFIED="$(git rev-parse HEAD)"
 cd "$root"
-bash "$GUARD" "$R" "$MARATHON_ONLY" "$RENDERED" \
-  || fail "marathon-only ledger write must pass the no-drift branch, got $?"
+bash "$GUARD" "$R" "$UNCLASSIFIED" "$RENDERED" \
+  || fail "GH-474: a clean render must allow any table, including ones no allowlist knows, got $?"
 
-# 8. Control: a roadmap_items data change in the same no-drift shape still refuses.
-# This is the red control for 7 AND 7b — it is what proves the allowlist opened the gate for
-# unprojected tables only, and not for everything.
+# 8. RED CONTROL for 7 and 7b. Same no-drift shape, same tables 7b just allowed — but now the
+# renderer reports a dropped row. The guard must refuse AND name the row it was told about.
+# This is what proves 7/7b pass because the renderer said "clean", not because the arm is inert.
 cd "$R"
-{ echo "-- dump v4"; echo "INSERT INTO roadmap_items VALUES('r1');"; } > releases.sql
-git add releases.sql
-git -c user.email=t@t -c user.name=t commit -q -m "roadmap-only ledger write"
-ROADMAP_ONLY="$(git rev-parse HEAD)"
+cat > utils/roadmap-dashboard.sh <<'EOFSTUB'
+#!/usr/bin/env bash
+echo "roadmap-dashboard: warning: dropped 1 unparseable row(s): #256" >&2
+exit 0
+EOFSTUB
+chmod +x utils/roadmap-dashboard.sh
+git add utils/roadmap-dashboard.sh
+git -c user.email=t@t -c user.name=t commit -q -m "renderer drops a row"
+DROPPED="$(git rev-parse HEAD)"
 cd "$root"
-rc=0; out="$(bash "$GUARD" "$R" "$ROADMAP_ONLY" "$RENDERED" 2>&1)" || rc=$?
-[ "$rc" -eq 1 ] || fail "expected no-drift refusal (1) for non-jog data, got $rc"
+rc=0; out="$(bash "$GUARD" "$R" "$DROPPED" "$RENDERED" 2>&1)" || rc=$?
+[ "$rc" -eq 1 ] || fail "expected no-drift refusal (1) when the renderer drops a row, got $rc"
 grep -q "NO diff" <<<"$out" || fail "expected the no-diff refusal message"
+grep -q "dropped 1 unparseable row(s): #256" <<<"$out" \
+  || fail "GH-474: refusal must NAME the dropped row the renderer reported, got: $out"
+
+# 8b. Negative control on the signal itself: renderer exits 0 with unrelated stderr chatter ->
+# ALLOW. Guards against matching any stderr output rather than the dropped-row warning.
+cd "$R"
+cat > utils/roadmap-dashboard.sh <<'EOFSTUB2'
+#!/usr/bin/env bash
+echo "roadmap-dashboard: note: rendered 41 rows" >&2
+exit 0
+EOFSTUB2
+chmod +x utils/roadmap-dashboard.sh
+git add utils/roadmap-dashboard.sh
+git -c user.email=t@t -c user.name=t commit -q -m "renderer chatters but drops nothing"
+CHATTY="$(git rev-parse HEAD)"
+cd "$root"
+bash "$GUARD" "$R" "$CHATTY" "$RENDERED" \
+  || fail "unrelated renderer stderr must not be read as a dropped row, got $?"
 
 echo "== GH-243 ALL PASSED =="
diff --git a/test/gh257-roadmap-ledger-fixes.sh b/test/gh257-roadmap-ledger-fixes.sh
index f79b5ce4..cdec74be 100755
--- a/test/gh257-roadmap-ledger-fixes.sh
+++ b/test/gh257-roadmap-ledger-fixes.sh
@@ -236,40 +236,51 @@ git add releases.db releases.sql
 git -c user.email=t@t -c user.name=t commit -q -m "ledger has bad row #256, dashboard unchanged"
 BAD_COMMIT="$(git rev-parse HEAD)"
 cd "$root"
 
 # 3. Staleness guard catches it and outputs no-diff diagnosis:
 # Add uncommitted modification in working tree to PROVE guard is isolated to commit projection
 echo "dirty working tree modification" >> "$R/ROADMAP-DASHBOARD.md"
 
 GUARD_TMP="$WORK/guard_isolated_tmp"
 mkdir -p "$GUARD_TMP"
 
 rc=0
 guard_out="$(TMPDIR="$GUARD_TMP" bash "$GUARD" "$R" "$BAD_COMMIT" "$BASE_COMMIT" 2>&1)" || rc=$?
 [ "$rc" -eq 1 ] || fail "guard should refuse bad commit, got $rc"
 case "$guard_out" in
   *"produces NO diff (GH-243 / GH-257)"*"releases roadmap update"*)
     pass "end-to-end: staleness guard accurately diagnosed no-diff dropped row (even with dirty working tree)"
     ;;
   *) fail "expected no-diff diagnostic output from guard, got: $guard_out" ;;
 esac
+# GH-474: the guard reads the RENDERER's dropped-row warning rather than inferring it from table
+# names, and the renderer here is the real one, reached through the guard's `git archive`
+# projection. Asserting the row id proves the signal survives that projection — if it did not,
+# the guard would fall through to "allow" and this case would go red instead of quietly passing
+# for the wrong reason. This is the runnable check the #474 recon listed as its one unknown.
+case "$guard_out" in
+  *"dropped 1 unparseable row(s): #256"*)
+    pass "GH-474: refusal names the dropped row, so the renderer's warning survived the projection"
+    ;;
+  *) fail "expected the guard to name dropped row #256 from the renderer's own stderr, got: $guard_out" ;;
+esac
 [ "$(find "$GUARD_TMP" -maxdepth 1 -name "staleness-guard.*" | wc -l)" -eq 0 ] || fail "expected no leftover guard roots in GUARD_TMP after no-diff refusal"
 pass "guard cleaned up temporary root after no-diff refusal"
 
 # Restore working tree
 git -C "$R" checkout ROADMAP-DASHBOARD.md
 
 # 4. Multi-ref push test with BAD_COMMIT FIRST and clean BASE_COMMIT LAST
 # Proves per-ref evaluation does not merely inspect the last ref in the list
 rc=0
 guard_multi_out="$(TMPDIR="$GUARD_TMP" bash "$GUARD" "$R" "$BAD_COMMIT" "$BASE_COMMIT" "$BASE_COMMIT" "$BASE_COMMIT" 2>&1)" || rc=$?
 [ "$rc" -eq 1 ] || fail "guard should refuse multi-ref push with bad commit first, got $rc"
 case "$guard_multi_out" in
   *"produces NO diff (GH-243 / GH-257)"*)
     pass "end-to-end: multi-ref push correctly evaluates bad ref first and clean ref last"
     ;;
   *) fail "expected no-diff refusal in multi-ref push, got: $guard_multi_out" ;;
 esac
 [ "$(find "$GUARD_TMP" -maxdepth 1 -name "staleness-guard.*" | wc -l)" -eq 0 ] || fail "expected no leftover guard roots in GUARD_TMP after multi-ref refusal"
 pass "guard cleaned up temporary root after multi-ref refusal"
 

exec
/bin/zsh -lc "git show development:githooks/dashboard-staleness-guard.sh | nl -ba | sed -n '112,198p'; printf '%s\\n' '--- applied guard shell syntax verification ---'; bash -n githooks/dashboard-staleness-guard.sh; printf '%s\\n' '--- branch / target identity ---'; git branch --show-current; git rev-parse --short HEAD; git rev-parse --short development" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-33750-j8h2ug9_
 succeeded in 9357ms:
2026-09-07 13:16:22.304 xcodebuild[16929:4551147]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-09-07 13:16:22.527 xcodebuild[16929:4551107] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.
git: warning: confstr() failed with code 5: couldn't get path of DARWIN_USER_TEMP_DIR; using /tmp instead
git: error: couldn't create cache file '/tmp/xcrun_db-TYrCuFvt' (errno=Operation not permitted)
2026-09-07 13:16:23.141 xcodebuild[17642:4552231]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-09-07 13:16:23.350 xcodebuild[17642:4552191] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.
   112	
   113	  if [ "$touched_ledger" -eq 1 ] && [ "$touched_dashboard" -eq 0 ]; then
   114	    # GH-257 Task 4: check whether regenerating ROADMAP-DASHBOARD.md produces drift or no diff.
   115	    # Run the diagnosis against a commit-pinned temporary projection of local_sha inside the
   116	    # private GUARD_ROOT_PHYS so uncommitted working-tree modifications do not skew the classification.
   117	    TMP_PROJ="$GUARD_ROOT_PHYS/proj-$local_sha"
   118	    mkdir -p "$TMP_PROJ"
   119	
   120	    drift_detected=1
   121	    if git -C "$REPO" archive "$local_sha" 2>/dev/null | tar -x -C "$TMP_PROJ" 2>/dev/null \
   122	       && [ -f "$TMP_PROJ/utils/roadmap-dashboard.sh" ]; then
   123	      if bash "$TMP_PROJ/utils/roadmap-dashboard.sh" --check >/dev/null 2>&1; then
   124	        drift_detected=0
   125	      else
   126	        drift_detected=1
   127	      fi
   128	    fi
   129	
   130	    if [ "$drift_detected" -eq 1 ]; then
   131	      cat >&2 <<'EOF'
   132	dashboard-staleness-guard: REFUSING the push — this range writes the roadmap ledger
   133	(releases.sql / releases.db) without regenerating ROADMAP-DASHBOARD.md, so the human-readable
   134	view would ship stale against the data under it (GH-243 / GH-169 item 3).
   135	
   136	Fix (one command, then commit the result into the same push):
   137	    bash utils/roadmap-dashboard.sh && git add ROADMAP-DASHBOARD.md && git commit -m "docs: regenerate roadmap dashboard"
   138	
   139	Bypass (deliberately loud, e.g. a WIP branch): git push --no-verify
   140	EOF
   141	    else
   142	      # The other legitimate no-diff case: a ledger change the dashboard cannot render.
   143	      # The renderer's only data input is `releases_app.py roadmap list --json`, a flat
   144	      # SELECT * FROM roadmap_items with no join or reference resolution — so roadmap_items
   145	      # is the ONLY projected table, and a write confined to anything else can never stale
   146	      # the view. Two write shapes are classified here, by their full dump fan-out:
   147	      #   jog     (GH-315) — jog_queue     + op_receipts + the settings generation counter
   148	      #   marathon         — marathons + issue_refs + op_receipts + that same counter
   149	      # `marathon add` creates the issue_refs row itself when the tracking URL is new, so the
   150	      # two tables must be allowed together or the refusal returns for any unseen issue.
   151	      # If every changed data line targets that set, allow; anything else keeps the
   152	      # dropped-row refusal below.
   153	      #
   154	      # KNOWN GAP, deliberate: this is an allowlist, so the 8 remaining tables in the dump
   155	      # (doc_lines, grandfather_entries, legacy_lines, manifest_items, manifest_state_events,
   156	      # releases, repos, schema_migrations) still hit the catch-all and still produce the same
   157	      # FALSE refusal this arm exists to stop — a `releases add` will trip it. Enumerating
   158	      # tables is the wrong mechanism and is being replaced: the renderer already knows which
   159	      # rows it dropped and throws that away (see #474). Do not "simplify" this into a
   160	      # roadmap_items-only denylist in the meantime — that fails OPEN if the renderer ever
   161	      # gains a second projected table, where this fails closed.
   162	      projected_or_unknown_data=0
   163	      while IFS= read -r dline; do
   164	        case "$dline" in
   165	          '-'INSERT\ INTO\ jog_queue*|'+'INSERT\ INTO\ jog_queue*) ;;
   166	          '-'INSERT\ INTO\ marathons*|'+'INSERT\ INTO\ marathons*) ;;
   167	          '-'INSERT\ INTO\ issue_refs*|'+'INSERT\ INTO\ issue_refs*) ;;
   168	          '-'INSERT\ INTO\ op_receipts*|'+'INSERT\ INTO\ op_receipts*) ;;
   169	          *INSERT\ INTO\ settings*generation*) ;;
   170	          '-'INSERT\ INTO\ *|'+'INSERT\ INTO\ *) projected_or_unknown_data=1; break ;;
   171	        esac
   172	      done < <(git -C "$REPO" diff --no-renames "$remote_sha" "$local_sha" -- releases.sql 2>/dev/null)
   173	      if [ "$projected_or_unknown_data" -eq 0 ]; then
   174	        continue
   175	      fi
   176	      cat >&2 <<'EOF'
   177	dashboard-staleness-guard: REFUSING the push — this range writes the roadmap ledger
   178	(releases.sql / releases.db) without modifying ROADMAP-DASHBOARD.md, but regenerating the
   179	dashboard produces NO diff (GH-243 / GH-257).
   180	
   181	This happens when a parked row was dropped by the renderer (e.g. malformed raw_text).
   182	To diagnose:
   183	    bash utils/roadmap-dashboard.sh
   184	and inspect stderr for warnings on dropped rows. Correct the row with:
   185	    releases roadmap update --issue-num <N> --raw-text "- **GH-<N> · <title>** ..."
   186	then regenerate and commit:
   187	    bash utils/roadmap-dashboard.sh && git add releases.db releases.sql ROADMAP-DASHBOARD.md && git commit -m "docs: fix roadmap row and regenerate dashboard"
   188	
   189	Bypass (deliberately loud, e.g. a WIP branch): git push --no-verify
   190	EOF
   191	    fi
   192	    exit 1
   193	  fi
   194	done
   195	
   196	exit 0
--- applied guard shell syntax verification ---
--- branch / target identity ---
git: warning: confstr() failed with code 5: couldn't get path of DARWIN_USER_TEMP_DIR; using /tmp instead
git: error: couldn't create cache file '/tmp/xcrun_db-CJTjKZYl' (errno=Operation not permitted)
2026-09-07 13:16:24.693 xcodebuild[18805:4553923]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-09-07 13:16:24.910 xcodebuild[18805:4553881] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.
git: warning: confstr() failed with code 5: couldn't get path of DARWIN_USER_TEMP_DIR; using /tmp instead
git: error: couldn't create cache file '/tmp/xcrun_db-hBDu752s' (errno=Operation not permitted)
2026-09-07 13:16:25.505 xcodebuild[19398:4554772]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-09-07 13:16:25.741 xcodebuild[19398:4554733] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.
git: warning: confstr() failed with code 5: couldn't get path of DARWIN_USER_TEMP_DIR; using /tmp instead
git: error: couldn't create cache file '/tmp/xcrun_db-RIpD929D' (errno=Operation not permitted)
2026-09-07 13:16:27.165 xcodebuild[20519:4556664]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-09-07 13:16:27.387 xcodebuild[20519:4556625] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.
git: warning: confstr() failed with code 5: couldn't get path of DARWIN_USER_TEMP_DIR; using /tmp instead
git: error: couldn't create cache file '/tmp/xcrun_db-DCP0Xlzt' (errno=Operation not permitted)
2026-09-07 13:16:27.979 xcodebuild[21154:4557586]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-09-07 13:16:28.192 xcodebuild[21154:4557546] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.
2aa33011
git: warning: confstr() failed with code 5: couldn't get path of DARWIN_USER_TEMP_DIR; using /tmp instead
git: error: couldn't create cache file '/tmp/xcrun_db-QVxvF8CY' (errno=Operation not permitted)
2026-09-07 13:16:29.534 xcodebuild[22297:4559314]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-09-07 13:16:29.741 xcodebuild[22297:4559275] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.
git: warning: confstr() failed with code 5: couldn't get path of DARWIN_USER_TEMP_DIR; using /tmp instead
git: error: couldn't create cache file '/tmp/xcrun_db-K2e8t5ro' (errno=Operation not permitted)
2026-09-07 13:16:30.305 xcodebuild[22884:4560166]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-09-07 13:16:30.514 xcodebuild[22884:4560127] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.
2e4f8d48

codex
ANSWER: DO NOT SHIP. The stderr capture is correct and the renderer does emit the stated warning, but “renderer silent” does not prove every row rendered: it silently ignores rows in unrecognised sections, while the public update command accepts any section string. That is a fail-open regression from `development`’s catch-all refusal.

I reviewed the applied detached-HEAD state (`2aa33011`) against `development` (`2e4f8d48`) with `git diff development -- githooks/dashboard-staleness-guard.sh`, plus `nl`, `rg`, `sqlite3`, `git show`, and `bash -n`. The named branch was not checked out locally.

FINDINGS

- [Blocker] The core “silent means rendered” premise is false beyond malformed lines. The renderer recognises only five section headings, changes an unknown heading to `currentSection = null`, then skips every row beneath it without adding a `droppedRows` warning. `releases_app.py roadmap update/move --section` accepts arbitrary strings with no validation. Thus an unknown-section row can be invisible with silent stderr; the old `development` classifier would fail closed on its `roadmap_items` dump lines. `utils/roadmap-dashboard.sh:97-103`, `utils/roadmap-dashboard.sh:187-204`, `utils/py/releases_app.py:3350-3368`, `githooks/dashboard-staleness-guard.sh (development):162-174`.

- [Pass] The narrow malformed-row premise is true. Node renders before the `MODE == check` branch, collects malformed active-section rows, writes exactly `roadmap-dashboard: warning: dropped …` to stderr, and only then compares bytes/returns the check status. `utils/roadmap-dashboard.sh:89-94`, `utils/roadmap-dashboard.sh:199-220`, `utils/roadmap-dashboard.sh:251-262`.

- [Pass] `render_err="$(cmd 2>&1 >/dev/null)"` is correct Bash: redirections are left-to-right, so stderr enters command substitution and stdout goes to `/dev/null`; the assignment receives the command substitution’s status, preserving the drift decision. `githooks/dashboard-staleness-guard.sh:120-134`.

- [Pass] Neither unquoted heredoc creates command injection here. Bash expands `$render_err`/`$dropped_line` once; bytes produced by that expansion are not reparsed for `$`, backticks, or command substitutions. `read -r` preserves backslashes. The unquoted delimiters are stylistically brittle, not an injection path in this form. `githooks/dashboard-staleness-guard.sh:163-180`.

- [Should] Failure direction is mixed. Node failure or a crash before the warning makes `--check` non-zero and the guard refuses. But missing/failing `python3` or projected `releases_app.py` falls back to legacy `ROADMAP.md`; if that file exists and is in sync, the guard can silently allow while ignoring the DB. A successful but erroneous empty JSON list similarly renders an empty dashboard and can allow. `utils/roadmap-dashboard.sh:45-81`, `utils/roadmap-dashboard.sh:84-87`, `githooks/dashboard-staleness-guard.sh:130-137`.

- [Should] The archive projection is correct for the current normal case and test 11 proves the malformed-row warning survives it: the guard archives `local_sha`, and the renderer uses its projected `utils/py/releases_app.py`. But the script explicitly supports the fallback paths above, so the warning is not guaranteed for projections missing the DB/app. `githooks/dashboard-staleness-guard.sh:122-130`, `utils/roadmap-dashboard.sh:56-80`, `test/gh257-roadmap-ledger-fixes.sh:247-265`.

- [Pass] The five `--check` consumers enumerated are complete among executable source: guard, plus the four named suites. Each treats non-zero as failure. Preserving the existing exit contract via stderr is sensible; a new exit code is not inherently better. `githooks/dashboard-staleness-guard.sh:130`, `test/gh269-roadmap-retired.sh:26-30`, `test/gh280-jog-marathon-adapter.sh:1021-1035`, `test/gh57-live-merge-resolve.sh:287-292`, `test/roadmap-dashboard.sh:48-54`.

- [Should] The tests prove the specific malformed-line signal, not the claimed universal property. Tests 7/7b/8/8b use stubs; test 8 is red against the old guard because the old error does not echo `#256`, though its old catch-all would also refuse that range. Case 11 is the needed real end-to-end projection proof. `test/gh243-dashboard-staleness-guard.sh:66-145`, `test/gh257-roadmap-ledger-fixes.sh:220-265`. A mutation every listed test misses: broaden the match to `*"dropped"*`; all fixtures still pass, but unrelated renderer stderr containing “dropped” would falsely refuse.

RECOMMENDATION: Do not ship until the renderer reports every omission—including unknown sections and failed DB-source construction—or the guard otherwise fails closed for those cases; then add real-renderer tests for both.
tokens used
108,116
ANSWER: DO NOT SHIP. The stderr capture is correct and the renderer does emit the stated warning, but “renderer silent” does not prove every row rendered: it silently ignores rows in unrecognised sections, while the public update command accepts any section string. That is a fail-open regression from `development`’s catch-all refusal.

I reviewed the applied detached-HEAD state (`2aa33011`) against `development` (`2e4f8d48`) with `git diff development -- githooks/dashboard-staleness-guard.sh`, plus `nl`, `rg`, `sqlite3`, `git show`, and `bash -n`. The named branch was not checked out locally.

FINDINGS

- [Blocker] The core “silent means rendered” premise is false beyond malformed lines. The renderer recognises only five section headings, changes an unknown heading to `currentSection = null`, then skips every row beneath it without adding a `droppedRows` warning. `releases_app.py roadmap update/move --section` accepts arbitrary strings with no validation. Thus an unknown-section row can be invisible with silent stderr; the old `development` classifier would fail closed on its `roadmap_items` dump lines. `utils/roadmap-dashboard.sh:97-103`, `utils/roadmap-dashboard.sh:187-204`, `utils/py/releases_app.py:3350-3368`, `githooks/dashboard-staleness-guard.sh (development):162-174`.

- [Pass] The narrow malformed-row premise is true. Node renders before the `MODE == check` branch, collects malformed active-section rows, writes exactly `roadmap-dashboard: warning: dropped …` to stderr, and only then compares bytes/returns the check status. `utils/roadmap-dashboard.sh:89-94`, `utils/roadmap-dashboard.sh:199-220`, `utils/roadmap-dashboard.sh:251-262`.

- [Pass] `render_err="$(cmd 2>&1 >/dev/null)"` is correct Bash: redirections are left-to-right, so stderr enters command substitution and stdout goes to `/dev/null`; the assignment receives the command substitution’s status, preserving the drift decision. `githooks/dashboard-staleness-guard.sh:120-134`.

- [Pass] Neither unquoted heredoc creates command injection here. Bash expands `$render_err`/`$dropped_line` once; bytes produced by that expansion are not reparsed for `$`, backticks, or command substitutions. `read -r` preserves backslashes. The unquoted delimiters are stylistically brittle, not an injection path in this form. `githooks/dashboard-staleness-guard.sh:163-180`.

- [Should] Failure direction is mixed. Node failure or a crash before the warning makes `--check` non-zero and the guard refuses. But missing/failing `python3` or projected `releases_app.py` falls back to legacy `ROADMAP.md`; if that file exists and is in sync, the guard can silently allow while ignoring the DB. A successful but erroneous empty JSON list similarly renders an empty dashboard and can allow. `utils/roadmap-dashboard.sh:45-81`, `utils/roadmap-dashboard.sh:84-87`, `githooks/dashboard-staleness-guard.sh:130-137`.

- [Should] The archive projection is correct for the current normal case and test 11 proves the malformed-row warning survives it: the guard archives `local_sha`, and the renderer uses its projected `utils/py/releases_app.py`. But the script explicitly supports the fallback paths above, so the warning is not guaranteed for projections missing the DB/app. `githooks/dashboard-staleness-guard.sh:122-130`, `utils/roadmap-dashboard.sh:56-80`, `test/gh257-roadmap-ledger-fixes.sh:247-265`.

- [Pass] The five `--check` consumers enumerated are complete among executable source: guard, plus the four named suites. Each treats non-zero as failure. Preserving the existing exit contract via stderr is sensible; a new exit code is not inherently better. `githooks/dashboard-staleness-guard.sh:130`, `test/gh269-roadmap-retired.sh:26-30`, `test/gh280-jog-marathon-adapter.sh:1021-1035`, `test/gh57-live-merge-resolve.sh:287-292`, `test/roadmap-dashboard.sh:48-54`.

- [Should] The tests prove the specific malformed-line signal, not the claimed universal property. Tests 7/7b/8/8b use stubs; test 8 is red against the old guard because the old error does not echo `#256`, though its old catch-all would also refuse that range. Case 11 is the needed real end-to-end projection proof. `test/gh243-dashboard-staleness-guard.sh:66-145`, `test/gh257-roadmap-ledger-fixes.sh:220-265`. A mutation every listed test misses: broaden the match to `*"dropped"*`; all fixtures still pass, but unrelated renderer stderr containing “dropped” would falsely refuse.

RECOMMENDATION: Do not ship until the renderer reports every omission—including unknown sections and failed DB-source construction—or the guard otherwise fails closed for those cases; then add real-renderer tests for both.
