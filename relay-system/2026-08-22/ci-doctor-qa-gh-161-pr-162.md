# RELAY · ci-doctor QA (GH-161 / PR #162)
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-08-22.
-->

NEXT: Reviewer
STATUS: Open
ROUND: 2 / 4

## ▶ TAKE YOUR TURN — read this first (works for ANY agent: Claude, Codex, agy)
1. **Read this whole file** (header, Setup, Ground rules, every block in the Log).
2. **Check it's your turn:** `NEXT` (top) names the role to act. Confirm you are bound to it and the
   last Log block isn't already yours. If not → STOP and reply "wrong window — nudge the <other> window."
3. **Do your role's work** on the artifact named in Setup:
   - **Reviewer:** review vs the Definition of Done → graded findings
     (`[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`), each with a concrete fix → set a **Verdict**
     (Approved | Changes requested | Blocked). **Review the whole file, not just the diff** (GH-268):
     a beta test had this loop reach `Approved` in two rounds while an independent audit of the same
     branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the
     change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN
     SCOPE; if you find none, say so explicitly rather than leaving it unstated.
     **Declare it: every review block must contain a literal `swept file: yes` or `swept file: no`
     line.** Without it a reviewer that skipped the sweep is indistinguishable in the transcript from
     one that did it and found nothing — which is how the original 20 issues stayed invisible.
     Any `[Pass]` or "verified"/"confirmed" finding MUST
     carry a quoted span or a `file:line` citation — an uncited one is mechanically downgraded to
     `[Unverified — no citation]` (GH-173 B3). Do **not** edit the artifact; only append findings here.
   - **Producer:** log a disposition for every open finding (Implemented / Modified / Declined + why),
     make the change, then add new work.
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(ci-doctor-qa-gh-161-pr-162): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **.relay-artifacts/benchmark-runners.sh** — the read-only path that
  `relay-drive.sh --artifact-file skills/ci-doctor/benchmark-runners.sh` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: stealth-ox-alpha   ·   Producer: claude-a
- Started: 2026-08-22
- Definition of Done: benchmark-runners.sh (1) does a literal, not regex, find/replace on the
  workflow's runs-on line(s), verified by a post-substitution assertion before committing; (2)
  picks up the dispatched run by workflow_dispatch event, never by "most recent run on branch"
  alone; (3) never aborts the whole benchmark loop on one variant's failure (missing FIND, failed
  substitution, failed dispatch, unresolved run, missing python3, dirty tree) — it skips that
  variant and continues; (4) passes `bash -n` and `shellcheck -S error` clean; (5) the two
  Blockers and all Should/Nit findings from R2 are each dispositioned below.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### R1 · stealth-ox-alpha · Reviewer · 2026-08-22

swept file: no

**Verdict: Blocked** — the review could not start. No code findings this round; zero lines of the
artifact were inspected, so no `[Pass]`/"verified" claims are made (none are possible).

- [Blocker] Artifact absent from the Reviewer window: `.relay-artifacts/benchmark-runners.sh` was
  never added to this context — the only file present is this relay file. Nothing was read, so
  nothing can be graded or cited. Fix: seed/paste the artifact contents into the Reviewer window
  (attach it to the chat like the relay file) and re-run this Reviewer turn before ROUND advances.
- [Blocker] Definition of Done is an unfilled placeholder (`_<fill in the acceptance criteria the
  Reviewer grades against>_`). Even with the artifact visible there would be no criteria to grade
  against — the same silent-missing-input failure mode GH-268 documents, where a turn looks complete
  while a required input was never actually supplied. Fix: Producer fills Setup → Definition of Done
  with concrete, checkable criteria before flipping NEXT back to Reviewer.

Explicitly NOT claiming a clean sweep: `swept file: no` here means the sweep did not happen, not
that it happened and found nothing. No pre-existing-defect statement is offered, because no
pre-existing code was seen.

handing off to claude-a (Producer) — go to the Producer window and say "take your turn": fill in the
Definition of Done, make `.relay-artifacts/benchmark-runners.sh` available to the Reviewer window,
then flip NEXT back to Reviewer for the real R1/R2 sweep.

### R2 · stealth-ox-alpha · Reviewer · 2026-08-22

swept file: yes — full 162-line read of the artifact this turn (static review only; nothing
executed, nothing written outside this file, no git, no tick).

**Verdict: Changes requested** — R1's missing-artifact Blocker is resolved (artifact now in the
Reviewer window). R1's DoD Blocker is downgraded to the process note below, since a substantive
review was possible against the script's own stated contract (header lines 4–17) plus general
correctness. Findings on `skills/ci-doctor/benchmark-runners.sh`:

- [Blocker] sed substitutes by regex but the guard checks literally (73–79): `grep -qF "$FIND"` (73)
  passes strings like `runs-on: [self-hosted, linux]` whose `[...]` sed's BRE (79) then matches
  wrongly — or matches nothing, in which case the committed "variant" is byte-identical to BASE and
  the benchmark silently reports the baseline's number as the variant's: exactly the meaningless
  number the GH-161 header (9–11) claims this tool makes impossible. Unescaped `&`/`\` in the
  replacement (79) are also sed-expanded, and `|` in either string still breaks the "rare
  separator" (78). Fix: literal substitution, e.g.
  `awk -v f="$FIND" -v r="$line" '{if(i=index($0,f))$0=substr($0,1,i-1) r substr($0,i+length(f));print}' "$WORKFLOW" > "$WORKFLOW.tmp" && mv "$WORKFLOW.tmp" "$WORKFLOW"`,
  then assert `grep -qF "$line" "$WORKFLOW"` before committing.
- [Blocker] Run pickup has no event filter (90): `gh run list --branch "$branch" --limit 1` grabs the
  most recent run on the branch, but pushing the bench branch can itself trigger a push-event run
  (any `on: push` workflow — i.e. a repo's fast lane), and a `concurrency` group with
  cancel-in-progress can cancel one of the two. The table then reports the fast-lane or `cancelled`
  run's wall-clock/conclusion as the variant's — the GH-161 failure mode again. Fix:
  `gh run list --repo "$REPO" --branch "$branch" --event workflow_dispatch --limit 1 --json databaseId --jq '.[0].databaseId'`
  (optionally also match `headSha` against the pushed commit).
- [Should] `git checkout "$BASE"` (75, 96, 144) assumes a local BASE branch exists; after only
  `git fetch origin "$BASE"` (70) it may not (fork clone, CI checkout, BASE ≠ default branch) →
  `set -e` kills the loop after a full priced CI run, repo left on the bench branch. Fix:
  `git checkout -q "$BASE" 2>/dev/null || git checkout -q --detach "origin/$BASE"` at all three sites.
- [Should] `gh workflow run` failure aborts the whole benchmark (84): missing `workflow_dispatch`
  trigger, fork-vs-upstream ref mismatch, rate limit — the assignment's non-zero status under
  `set -e` exits, discarding every remaining variant. Fix:
  `if ! dispatch_out="$(gh workflow run ... 2>&1)"; then echo "skipping $label: $dispatch_out" >&2; git checkout ...; continue; fi`.
  Related: preflight that the workflow actually declares `workflow_dispatch` (the header's GH-161
  guarantee is asserted, never verified) and that the local clone's origin corresponds to `$REPO`.
- [Should] python3 is load-bearing but unchecked (105, 114): the two JSON-parsing calls have no
  fallback (only the time-math call at 131 does, via `|| echo "?"`) → a missing python3 kills the
  script mid-loop, after the CI run's cost, with a bare command-not-found. Fix:
  `command -v python3 >/dev/null 2>&1 || { echo "ci-doctor: python3 required" >&2; exit 1; }`
  beside the preflights at 58–59.
- [Should] No dirty-tree / git-identity preflight: `git checkout -B` (71) fails on uncommitted
  tracked changes and `git commit` (81) fails without user.name/user.email — both mid-loop under
  `set -e`. Fix: preflight `git diff --quiet && git diff --cached --quiet` and
  `git config user.email`, or commit as
  `git -c user.name=ci-doctor -c user.email=ci-doctor@local commit -q -m ...`.
- [Nit] `--variant` without `=` mis-parses (49): with no `=` in the value, `${2%%=*}` and `${2#*=}`
  BOTH return the whole string → LABEL=LINE=whole string, which gets committed and priced. Fix:
  `[[ "$2" == *=* ]] || { echo "ci-doctor: --variant expects LABEL=LINE" >&2; exit 2; }`.
- [Nit] Operand-less flag crashes under `set -u` (43–47): `benchmark-runners.sh --repo` dies with
  `$2: unbound variable` instead of usage. Fix: `[[ $# -ge 2 ]] || { usage >&2; exit 2; }` before
  each `shift 2`.
- [Nit] Empty results table can crash old bash (154): with every variant skipped,
  `"${!RESULT_LABEL[@]}"` on an empty array under `set -u` errors on bash ≤ 4.3 (macOS ships 3.2).
  Fix: guard `[ "${#RESULT_LABEL[@]}" -gt 0 ]` around the loop.
- [Nit] FIND occurring on N lines replaces all N (79 — no `g` flag, but sed applies per line): fine
  if intended (every job's `runs-on:`), surprising otherwise. State it in usage (22–25) or warn when
  `grep -cF "$FIND" "$WORKFLOW"` > 1.
- [Nit] `--job` exact match is brittle (109): matrix jobs render as `name (matrix values)`; a
  near-miss silently yields empty `times` → `?` in the table with no hint why. Fix: on no match,
  print the available `j['name']` values to stderr before recording `?`.
- [Pass] Preflights fail loud (58–59): `gh auth status >/dev/null 2>&1 || { ...; exit 1; }` and
  `git rev-parse --show-toplevel >/dev/null 2>&1 || { ...; exit 1; }`.
- [Pass] Branch names are invocation-unique (61, 67): `ci-doctor-bench-<slug>-$(date +%s)` — the
  `--branch` pickup (90) cannot collide with a prior invocation's runs.
- [Pass] Missing FIND skips the variant instead of dying (73–77):
  `if ! grep -qF "$FIND" "$WORKFLOW"; then ...; continue; fi`.
- [Pass] Wall-clock derives from API job timestamps, not watch elapsed (101, 103, 117–121): a
  dropped/failed `gh run watch` (101, `|| true`) cannot corrupt the measurement — min(starts)/
  max(ends) is re-derived from `gh run view` JSON at 103.
- [Pass] Cleanup is best-effort (146–147): both the remote delete and `git branch -D` carry
  `|| true`; `--keep-branches` (48) is honored.

Process note: Setup → Definition of Done is STILL the unfilled placeholder. This review was graded
against the script's own contract (header 4–17) + general correctness; before opening the next
cycle, Producer fills the DoD with concrete, checkable criteria so R3 can approve against something
explicit rather than reviewer discretion.

handing off to claude-a (Producer) — go to the Producer window and say "take your turn": disposition
every finding above (Implemented / Modified / Declined + why), fix at minimum the two Blockers,
fill the Definition of Done, then flip NEXT back to Reviewer and bump ROUND to 2 / 4.

### R2 · claude-a · Producer · 2026-08-22

Verified every citation against the real file before acting (line numbers, quoted code) — all
confirmed real, none hallucinated. Dispositions:

- [Blocker] sed-vs-literal mismatch — **Implemented.** Replaced the `sed "s|$FIND|$line|"` with a
  literal (non-regex) `awk`-based substring replace (`literal_replace()`), plus a post-substitution
  `grep -qF "$line"` assertion that skips the variant (not commits a no-op) if it didn't apply.
  Smoke-tested against the reviewer's exact repro (`runs-on: [self-hosted, linux]`) — confirmed the
  old code's failure mode and the new code's correct literal replace.
- [Blocker] run pickup had no event filter — **Implemented.** `gh run list` now takes
  `--event workflow_dispatch`, dropping the ambiguous no-filter lookup entirely (simpler than also
  matching `headSha`, and sufficient: a workflow_dispatch run's branch+event pair is already unique
  per invocation given the timestamped branch name).
- [Should] `git checkout "$BASE"` assumed a local branch — **Implemented.** Extracted to
  `back_to_base()`: `git checkout -q "$BASE" 2>/dev/null || git checkout -q --detach "origin/$BASE"`,
  used at all exit points (was 3 call sites, now every skip/continue path routes through it).
  De-duplicating into one function was not itself requested but follows directly from applying the
  same fix at every site the reviewer named.
- [Should] `gh workflow run` failure aborted the loop — **Implemented.** Wrapped in `if ! dispatch_out=...`,
  logs and skips the variant instead of exiting. (Did not add the suggested `workflow_dispatch`-trigger
  preflight or origin/`$REPO` correspondence check — declined as a separate, larger concern; the
  per-variant failure handling this finding actually asked for is in place.)
- [Should] unchecked python3 — **Implemented.** `command -v python3` preflight alongside the existing
  `gh`/git checks, fails loud before any CI run is spent.
- [Should] no dirty-tree/git-identity preflight — **Implemented, via the cheaper of the two suggested
  fixes.** Added the dirty-tree preflight (`git diff --quiet && git diff --cached --quiet`) and
  switched the commit to `git -c user.name=ci-doctor -c user.email=ci-doctor@local commit` — sidesteps
  requiring global git identity rather than validating it, per the finding's own alternative.
- [Nit] `--variant` without `=` mis-parsed — **Implemented.** Validates `*=*` before splitting;
  confirmed the fix rejects a bare value with the right message (smoke-tested).
- [Nit] operand-less flag crash under `set -u` — **Implemented.** Added `need_arg()`, called before
  every 2-arg flag's `shift 2`.
- [Nit] empty results array crash on old bash — **Implemented.** Guarded the results loop on
  `${#RESULT_LABEL[@]} -eq 0`, prints an explicit "(no variant produced a result...)" line instead.
- [Nit] FIND matching N lines replaces all N — **Implemented.** Usage text now states this
  explicitly, and a `grep -cF` count > 1 prints a NOTE at run time.
- [Nit] `--job` exact-match brittleness — **Implemented.** On no match, the inline python now prints
  the run's actual job names to stderr instead of silently falling through to `?` in the table.

`bash -n` and `shellcheck -S error` re-verified clean on the revised script. Not yet re-run against
a live `gh workflow run` dispatch end-to-end (would spend real CI minutes on HiQS-Suite/XYZ-forge
outside this review's scope) — the fixes are verified by direct code inspection + the two targeted
unit smoke tests above, not a full live run.

**Every finding above is dispositioned.** Setup → Definition of Done is now filled with concrete
criteria (see above).

handing off to stealth-ox-alpha (Reviewer) — go to the Reviewer window and say "take your turn":
re-sweep the revised `.relay-artifacts/benchmark-runners.sh` against the filled Definition of Done
and this round's dispositions; grade whether each Implemented fix actually resolves its finding.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
