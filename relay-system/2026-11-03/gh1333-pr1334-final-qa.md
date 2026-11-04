# RELAY · GH-1333 PR #1334 final QA: issue-state authority policy + Phase 1 fixes
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-11-03.
-->

NEXT: Producer
STATUS: Approved
ROUND: 2 / 2

## ▶ TAKE YOUR TURN — read this first (works for ANY agent: Claude, Codex, agy)
1. **Read this whole file** (header, Setup, Ground rules, every block in the Log).
2. **Check it's your turn:** `NEXT` (top) names the role to act. Confirm you are bound to it and the
   last Log block isn't already yours. If not → STOP and reply "wrong window — nudge the <other> window."
3. **Do your role's work** on the artifact named in Setup:
   - **Reviewer:** review vs the Definition of Done → graded findings
     (`[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`), each with a concrete fix → set a **VERDICT**
     (exactly PASS, FAIL, or PARKED) and a **Basis** (explanation). **Review the whole file, not just the diff** (GH-268):
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
     **A finding that asks for a behaviour change is a generalization unless you can paste the concrete
     input — a row, a value, a `file:line` — that fails under the current code** (GH-681: the gh673
     final QA relay generalized one late-error observation into "or a later invalid identity", the
     Producer implemented it, the same seat `[Pass]`ed it next round, and one historical NULL-URL
     ledger row then blanked every issue). Every `[Blocker]` or `[Should]` requesting a behaviour
     change MUST carry three lines: `Observed input:` (the failing input you saw), `Affected scope:`
     (the input predicate the change would govern), `Falsifier:` (the fixture or data that would show
     the change unnecessary or wrong, and its expected result).
     A `[Blocker]` must cite an observed failure. This is a protocol rule, not a mechanical check —
     the Producer may disposition a request lacking these as `Declined — unproven generalization`.
   - **Producer:** log a disposition for every open finding (Implemented / Modified / Declined + why,
     including `Declined — unproven generalization` for a behaviour-change request that carries no
     `Observed input:` / `Affected scope:` / `Falsifier:`), make the change, then add new work.
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
   Reviewer headings may be `### Reviewer · Round N`, `### Round N · Reviewer · <agent>`, `### Reviewer (<agent>)` (optionally followed by `— rN`), or `### Reviewer — Round N` (optionally followed by `(<agent>)`); follow the heading with a non-empty review body.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(gh1333-pr1334-final-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **pr1334.diff** (embedded below — read it here).
- Reviewer: codex (GPT-6 Astra, medium effort)   ·   Producer: claude-a
- Started: 2026-11-03

### Context

PR #1334 (HiQS-Labs/XYZ-forge, base `development`) has two commits.

**Commit 1 (`14e39087`)** writes three operator decisions from #1333 into `PROJECT/PDDA.md` as **policy only**:
1. The GitHub issue's state is the only authority for "done". A doc's folder and its ledger section are views of that state.
2. Readers find a `GH-<n>-` doc by its issue number, never a stored path.
3. One idempotent completion sweep, keyed on current issue state, replaces per-merge moves. It covers `1-INBOX` and `2-WORKING`, repoints the ledger, and never closes an issue.

It also adds a decision record and a CHANGELOG entry.

**Commit 2 (`693e9d22`)** makes four Phase 1 fixes:
- `utils/py/express.py` no longer writes `rated 2/2/2/2` into the rows it parks.
- `PROJECT/PDDA.md` and `skills/2-daily/start-marathon/SKILL.md` say the `ratings_provisional` hold is not enforced by code.
- `SOP.md` §3 no longer says the hosted `wave-reconcile.yml` reconciles automatically.

The embedded diff below is the whole PR, against the merge base with `origin/development`. The full files are in your worktree. Read the edited files **in full**, not only the hunks: `PROJECT/PDDA.md`, `SOP.md`, `utils/py/express.py`, `skills/2-daily/start-marathon/SKILL.md`, `decisions/2026-11-03-gh1333-issue-state-authority.md`, and the top entry of `CHANGELOG.md`.

**Operational envelope.** These are governance docs plus a one-line string change in a local developer CLI. Grade against the stated scope: policy text that must be true on merge, and a placeholder removal. Do not ask for the sweep, the reader changes or any later #1333 phase. Do not ask for new tests: XYZ-forge forbids new suites (GH-831), so verification is the existing `test/gh267-express-skill.sh` (113/113 passed) plus a recorded red/green `parse_rating` check. Narrow read-only probes are allowed (grep, reading files, `python3 -c` on `parse_rating`). Do not run `validate.sh` or `test/*.sh` here.

### Questions

1. **Policy consistency.** Do the `PROJECT/PDDA.md` edits state decisions 1-3 consistently? The edits are in "Canonical document model", "Lifecycle", and section H `issue-doc-sync` (a) and (c). Sweep the whole of PDDA.md for any passage the PR did *not* edit that now contradicts them, for example text that treats the folder as the authority for done, or another description of who moves docs. Cite `file:line`.
2. **Is "policy only" true?** Does any edited sentence claim behaviour the code does not have today? Check it against:
   - `utils/py/wave_reconcile.py`: the per-merge move; `RECONCILE_FOLDERS`; what happens when an issue is still OPEN;
   - `utils/pdda/pdda.sh` `check_issue_doc_sync`: its scan scope;
   - `skills/2-daily/merge-cleanup/scripts/merge_cleanup.py`: whether local reconcile is the default.
3. **The `ratings_provisional` claim.** The PR says no planner code reads `ratings_provisional`; `marathon_plan`, `jog` and `swarm_preflight` ignore it, and only `sentinel-overlay/` reads it. Measure it, for example with `grep -rn ratings_provisional utils/ relay-automation/ bin/ src/`. Is the claim exactly right, or over- or under-stated?
4. **SOP.md §3.** Is the new text accurate against:
   - the triggers in `.github/workflows/wave-reconcile.yml`;
   - the hosted in-flight check and `--force-local-reconcile` in `wave_reconcile.py`;
   - merge-cleanup's default?

   Does it contradict `AGENTS.md` or `ROUTER.md` (the ROUTER "GH-1127" paragraph)?
5. **`express.py`.** With the `rated` token removed, does any consumer of an express-parked row break: planner ranking, express's own flow, `roadmap add`, or a test fixture? Confirm with `parse_rating(raw, title)` that the new line yields an unrated row. `express.py:715-728` still writes `ratings_provisional: true` and legacy cx/risk/effort frontmatter, which the planner may still count as rated (`_marathon_plan.py:941-948`). Is that a defect *introduced or worsened* by this PR, or the pre-existing Phase 4 item #1333 already lists?
6. **Records.** Do the decision record and the CHANGELOG entry match the diff? Do the cited numbers (25 stranded docs, 45 stale `doc_path`) match #1333's measurements as quoted here? Does any text in the PR contain a closing clause that `wave_reconcile` or GitHub could read as closing #1333 or another issue? Negated phrasing such as "does not close #N" still counts.
7. **Scope and complexity.** Is anything over-reaching, or missing in a way that would make the policy text wrong once merged? Challenge anything that adds machinery or promises behaviour beyond the decisions.

Graded findings only, each with a `file:line` or quoted span. Set VERDICT PASS (STATUS `Approved`) if there is no Blocker or Should; otherwise FAIL with concrete fixes.

### Artifact — pr1334.diff
```
diff --git a/CHANGELOG.md b/CHANGELOG.md
index e2099b57..e382cc48 100644
--- a/CHANGELOG.md
+++ b/CHANGELOG.md
@@ -1,5 +1,15 @@
 # Changelog
 
+## 2026-11-03 — GH-1333 decisions: issue state is the authority for "done"; docs found by number; one completion sweep
+
+- `PROJECT/PDDA.md` now says the GitHub issue's state is the only authority for "done". A doc's folder and its ledger section are views of that state. Readers find a `GH-<n>-` doc by its issue number, not a stored path.
+- Completion moves are to come from one idempotent sweep, keyed on current issue state. It covers `1-INBOX` and `2-WORKING`, repoints the ledger row, runs from merge-cleanup and `start-marathon`, and never closes an issue. It replaces per-merge moves.
+- Policy only. The sweep and the reader changes are not built yet; until they land, `wave_reconcile.py --pr N` and `issue-doc-sync` behave as before. Decision record: `decisions/2026-11-03-gh1333-issue-state-authority.md`. #1333's other decisions (who closes issues, the appeal axis, when a ledger row is created) stay open.
+- #1333 Phase 1 fixes:
+  - `express` no longer writes `rated 2/2/2/2` into the rows it parks. That token put the 1-5 scale into the 1-100 grammar and ranked as a real score (#1177). Those rows now stay unrated until someone rates them.
+  - `PROJECT/PDDA.md` and the `start-marathon` skill no longer claim the planner enforces `ratings_provisional`. Only `sentinel-overlay/` reads it, so the hold is manual for now.
+  - `SOP.md` no longer says the hosted `wave-reconcile.yml` reconciles automatically. It has been dispatch-only since #1131, and local reconcile is the writer. The `AGENTS.md` copy is #1160, PR #1326.
+
 ## 2026-11-02 — GH-1308 decisions 9–13: receipt policy, teardown origin check, regression cases
 
 - `validate.sh` writes a gate receipt on every green tier-3 run of a clean tree again, as it did before #1253. Only a run with no skipped suite and no environment fault is stamped `--scope full`, which pre-push reuse still requires. `marathon-closeout.sh` therefore no longer refuses a host whose run skipped a suite.
diff --git a/PROJECT/PDDA.md b/PROJECT/PDDA.md
index 8e25144d..f56653bf 100644
--- a/PROJECT/PDDA.md
+++ b/PROJECT/PDDA.md
@@ -41,7 +41,14 @@ Within that model:
 
 - `ROADMAP.md` is the index of current, completed, attempted, and deferred work
 - project detail lives in the individual `PROJECT/**` documents
-- a working doc is the canonical source of truth for that effort until it is completed, deferred, or superseded
+- a working doc is the canonical source of truth for that effort's content until it is completed, deferred, or superseded; whether the work is done is not the doc's to say (next item)
+- **the GitHub issue's state is the only authority for "done"** (GH-1333, decided 2026-11-03,
+  [decision record](../decisions/2026-11-03-gh1333-issue-state-authority.md)). The folder a `GH-<n>-` doc
+  sits in and its ledger row's section are views of that state, not separate assertions. When they
+  disagree, the issue wins and the view is corrected.
+- **readers find a `GH-<n>-` doc by its issue number** (the `gh_issue` key, else the `GH-<n>-` filename
+  prefix), never by a stored path, so moving a doc cannot break a reference. A stored path, such as the
+  ledger's `doc_path`, is a cache that the completion sweep (see Lifecycle) repoints.
 - `blank.md` placeholders are scaffolding and should be ignored by PDDA checks
 
 ## Required contract for active docs
@@ -164,6 +171,11 @@ effort must **not** become auto-selectable on the strength of that guess. So a p
 out of auto-selection until a human confirms the ratings and clears the flag — the same "route to a
 human" posture as `risk >= 4`.
 
+**Not enforced today (GH-1333).** No planner code reads `ratings_provisional`. `marathon_plan`, `jog`
+and `swarm_preflight` ignore it; only the `sentinel-overlay/` scripts read it. Until #1333 Phase 4
+either implements the hold or retires it, the hold is manual. Whoever prepares a marathon must keep a
+provisional capture out of its waves.
+
 This keeps the raw ratings canonical and queryable while letting the "what's the easiest *safe* thing
 to grab" logic live in one place that can evolve. (See the resolved `priority` note under
 [Proposed extensions](#proposed-extensions-not-yet-locked).)
@@ -282,7 +294,19 @@ Lifecycle:
   This is the concrete mechanism behind "GitHub issues are not a substitute for the local active-work
   doc once execution starts" (bug-fix stance above).
 - If a captured issue is never actioned it ages out of `1-INBOX` like any other untriaged note; if it is
-  closed without work, move the doc to `PROJECT/4-MISC` and remove its queue pointer from `ROADMAP.md`.
+  closed without work, the completion sweep (next item) moves the doc to `PROJECT/4-MISC` and removes its
+  queue pointer from `ROADMAP.md`.
+- **Completion moves come from one sweep, keyed on current issue state** (GH-1333). The sweep reads the
+  issue state of every `GH-<n>-` doc in `1-INBOX` and `2-WORKING`:
+  - closed as completed: it moves the doc to `PROJECT/3-COMPLETED/`;
+  - closed as not planned: it moves the doc to `PROJECT/4-MISC/`.
+
+  It repoints the ledger row's section and `doc_path` in the same commit. It is idempotent and reads
+  state when it runs, not when a PR merges. That way a manual close, a bulk close, a `Refs`-only lane
+  PR, or a merge in the GitHub UI is caught on the next run. It replaces the per-merge moves in
+  `wave_reconcile.py --pr N`. It runs from the steps that already run: the merge-cleanup batch and
+  `start-marathon` Step 2. It never closes an issue. **Until it lands**, `wave_reconcile.py --pr N`
+  still moves docs on a closing-keyword merge, and `issue-doc-sync` (H) flags what that misses.
 
 A foreign-repo issue (not `origin`) is the rare exception: the `source:` URL disambiguates it, since the
 bare `GH-<number>` only guarantees uniqueness within the canonical repo.
@@ -459,7 +483,8 @@ Minimum behavior:
   or the `GH-<number>-` filename; silently skip docs that carry neither (they are not issue-tracked)
 - resolve each issue's state from the best available source (see gh-degrade below), then flag:
   - **(a)** issue **CLOSED** but the doc is still in `2-WORKING` -> `warn`, recommending the exact
-    `git mv` to `PROJECT/3-COMPLETED` (flag-only; a human runs the one reversible move)
+    `git mv` to `PROJECT/3-COMPLETED` (flag-only; once the GH-1333 completion sweep lands, that sweep makes
+    this move, including for `1-INBOX` docs, which this check does not yet scan)
   - **(b)** issue **OPEN** but the doc's `status:` lead word declares it done (`complete`, `done`,
     `shipped`, `fixed`, `closed`, `merged`, `resolved`, `landed`) -> `warn` to reconcile. Anchoring on the
     status **lead word** means a mid-status mention like `Active — Phase 0 complete` never false-flags.
@@ -469,12 +494,14 @@ Minimum behavior:
     every human reads that as done; the lead word is `active`. The phrase list stays short and literal —
     a general "does this prose mean done?" parse is the false-positive machine the lead-word anchor exists
     to avoid.
-  - **(c)** doc is in `3-COMPLETED` but the issue is **OPEN** -> `warn`, recommending `gh issue close <n>`.
-    The lifecycle bucket is a deterministic signal; the status prose is not. `3-COMPLETED/` *is* the
-    operator's assertion that the work is done, recorded in a path and verifiable with `test -f`.
+  - **(c)** doc is in `3-COMPLETED` but the issue is **OPEN** -> `warn`. Since GH-1333 the issue's state,
+    not the folder, says whether work is done. So (c) means either the doc moved early or the issue was
+    never closed after delivery. It is a prompt to whoever owns closing (still to be decided in #1333),
+    not evidence that the work is done; neither this check nor the sweep closes the issue.
     A doc in `3-COMPLETED` with a **CLOSED** issue is the fully reconciled end state: no finding.
 - `warn` (never `error` — does not block, even in `full`, mirroring `pdda.sh changelog`); **flag-only**,
-  never moves a file and never closes an issue
+  never moves a file and never closes an issue. The GH-1333 completion sweep (Lifecycle) is the one
+  mover; this check stays the detector.
 - gh-degrade: with `PDDA_ISSUE_SYNC_SOURCE=auto` (default) it uses live `gh` when that succeeds, else a
   cached state file (`PDDA_GH_STATE_CACHE`). `gh`/`cache` force one source. **A successful live lookup
   writes the cache** (best-effort, atomic), so the offline consumers — chiefly the `Stop` hook — have
diff --git a/SOP.md b/SOP.md
index e8e78c8b..69721ad4 100644
--- a/SOP.md
+++ b/SOP.md
@@ -258,12 +258,13 @@ An in-flight failing test or runner error is not automatically an urgent blocker
 2. **Batch same-seam scopes into one PR.** Five small PRs touching one seam is five
    gate + merge + reconcile cycles for what is really one unit of review. GH-291 shipped
    Scopes 1+5, 3+4, and 2 as three PRs; two would have carried the same review weight.
-3. **Reconciliation ownership and batching.** Hosted `wave-reconcile.yml` is the primary landing
-   writer on `development`, automatically reconciling docs, ledger, and views. If running local
-   reconciliation as fallback, the rule is to let hosted runs finish (or pass `--force-local-reconcile`
-   in emergencies) and batch multiple PRs (`wave_reconcile.py --pr <N> <M>`) rather than running
-   instantly per merge. Task branches must not commit routine view updates (`ROADMAP-DASHBOARD.md`,
-   `LEADERBOARD.md`).
+3. **Reconciliation ownership and batching.** Local `wave_reconcile.py --pr <N>` is the landing
+   writer on `development`; merge-cleanup runs it by default. Hosted `wave-reconcile.yml` has been
+   dispatch-only since GH-1127 / #1131, so nothing reconciles docs, ledger, and views after a merge
+   unless someone runs it. Batch multiple PRs (`wave_reconcile.py --pr <N> <M>`) rather than
+   reconciling per merge. Never reconcile locally while a dispatched hosted run is in flight; pass
+   `--force-local-reconcile` only in emergencies. Task branches must not commit routine view updates
+   (`ROADMAP-DASHBOARD.md`, `LEADERBOARD.md`).
 4. **Never write bare `#N` for another repo's issues in a PR body.** The reconciler
    resolves every `#N` against *this* repo and exits 6 when it cannot (GH-301 needed an
    offline-manifest escape mid-reconcile). Cross-repo references are written `GH-N`;
diff --git a/decisions/2026-11-03-gh1333-issue-state-authority.md b/decisions/2026-11-03-gh1333-issue-state-authority.md
new file mode 100644
index 00000000..d47a89d1
--- /dev/null
+++ b/decisions/2026-11-03-gh1333-issue-state-authority.md
@@ -0,0 +1,25 @@
+# Issue state is the authority for "done"; docs found by number; one completion sweep — GH-1333
+
+Recorded 2026-11-03. The operator approved three of the #1333 recommendations. The canonical rule text is in [PROJECT/PDDA.md](../PROJECT/PDDA.md), under "Canonical document model" and "Lifecycle".
+
+1. **The GitHub issue's state is the only authority for "done".** The `PROJECT/` folder of a `GH-<n>-` doc and its ledger row's section are views of that state. When they disagree, the issue wins.
+2. **Every reader finds a `GH-<n>-` doc by issue number, never by a stored path.** Stored paths (the ledger's `doc_path`) are a cache. Moving a doc can no longer break a reference: 45 ledger `doc_path` values were stale on 2026-11-03, and the #722 stall was a moved artifact path.
+3. **One idempotent sweep, keyed on current issue state, replaces per-merge moves.**
+   - It covers `1-INBOX` and `2-WORKING`.
+   - Closed as completed goes to `3-COMPLETED`; closed as not planned goes to `4-MISC`.
+   - It repoints the ledger row in the same commit.
+   - It runs from the merge-cleanup batch and `start-marathon` Step 2.
+   - It never closes an issue.
+
+Why: "done" was stored three times, and the only automatic writer fired on a PR merge with a closing keyword. Manual closes, bulk closes, `Refs`-only lane PRs and merges in the GitHub UI all left the copies disagreeing. On 2026-11-03 that left 25 closed issues with active docs. The measurements and the code trace are in #1333.
+
+Status: **policy decided, not yet implemented.** Until the sweep and the reader changes land, `wave_reconcile.py --pr N` still moves docs on a closing-keyword merge, and `pdda.sh issue-doc-sync` flags what it misses. No code, ledger row or doc location changed with this record.
+
+Not decided here, and still open in #1333:
+- who closes an issue after verified completion (decision 2);  [Unverified — no citation]
+- the appeal axis, and when a ledger row is created (decision 3);
+- whether to retire the folders entirely. That is to be decided about a month after the sweep runs, on whether anything but people browsing still reads them.
+
+Expected signal: once the sweep runs, `issue-doc-sync` warning (a) stays at zero across merge-cleanup batches, and no ledger `doc_path` points at a missing file. Revisit if the sweep moves a doc whose issue was reopened, or if a reader is found still resolving by stored path.
+
+Rollback: the policy is text. Revert this record and the PDDA.md edits. The sweep, once built, only moves files with `git mv` and rewrites ledger cache fields, and both can be reverted by commit.
diff --git a/skills/2-daily/start-marathon/SKILL.md b/skills/2-daily/start-marathon/SKILL.md
index 9d0bac17..ecb96b0b 100644
--- a/skills/2-daily/start-marathon/SKILL.md
+++ b/skills/2-daily/start-marathon/SKILL.md
@@ -203,7 +203,8 @@ CREATED="$(gh issue view "$NUM" --json createdAt --jq '.createdAt[0:10]')"
 DOC="PROJECT/1-INBOX/GH-${NUM}-$(hq_slug "$TITLE" | tr '[:lower:]' '[:upper:]').md"
 
 # <num> <src> <title> <created> <doc_type> <project> <repo> <request> — ratings default to
-# ratings_provisional: true, which marathon-plan already parks out of active waves.
+# ratings_provisional: true. marathon-plan does not read that flag yet (GH-1333), so hold
+# provisional captures out of waves by hand.
 hq_render_capture "$NUM" "$URL" "$TITLE" "$CREATED" bugfix <project> <org>/<repo> "$BODY" > "$DOC"
 
 python3 "$HARNESS/utils/py/releases_app.py" roadmap add \
diff --git a/utils/py/express.py b/utils/py/express.py
index e439f8ae..93d4f05b 100644
--- a/utils/py/express.py
+++ b/utils/py/express.py
@@ -843,7 +843,9 @@ def cmd_ledger(args):
             if not cands:
                 refuse(root, "no-doc", "run `express docs` first (or pass --doc-path)", issue=args.issue)
             doc = "PROJECT/2-WORKING/" + cands[0]
-        raw = ("- **GH-%d · %s** 🆕 rated 2/2/2/2 — [doc](%s) · [#%d](%s)" %
+        # No `rated` token: a hard-coded 2/2/2/2 put the 1-5 scale into the 1-100 PRS grammar and
+        # ranked as a real score (GH-1177, GH-1333). The row stays unrated until someone rates it.
+        raw = ("- **GH-%d · %s** 🆕 — [doc](%s) · [#%d](%s)" %
                (args.issue, meta["title"], doc, args.issue, meta["url"]))
         run_releases(root, "roadmap", "add",
                      "--issue-num", str(args.issue), "--issue-url", meta["url"],
```
- Definition of Done: _<fill in the acceptance criteria the Reviewer grades against>_

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer · Round 1 · codex

VERDICT: FAIL
Basis: The placeholder removal is sound and the future sweep is explicitly policy-only, but one surviving skill instruction still presents the provisional hold as automatic. Correct that sentence before approval; no later-phase implementation is requested.
swept file: yes

- [Should] **S1 — finish the provisional-hold correction in Step 4.** `skills/2-daily/start-marathon/SKILL.md:239-242` still says "`ratings_provisional: true` and `risk > 2` prevent automatic selection." That is the operational instruction immediately before invoking the planner, and conflicts with the newly corrected manual-hold comment at lines 205-207 and `PROJECT/PDDA.md:174-177`. Change it to explicitly instruct the preparer to exclude provisional captures manually because the planner does not enforce that flag; retain risk policy without claiming enforcement not established here.
  Observed input: the quoted Step 4 sentence survives in the full edited skill; the literal scan below finds no planner read of `ratings_provisional`.
  Affected scope: the skill's description of current selection behavior, not planner implementation or Phase 4.
  Falsifier: an actual planner admission read of `ratings_provisional` that holds a provisional, otherwise-ready item would make the manual-only correction unnecessary; none appears in the inspected runtime sources.

- [Pass] **The runtime claim itself is accurate.** Read-only command `rg -n 'ratings_provisional' utils/ relay-automation/ bin/ src/ sentinel-overlay/` exited 0. Runtime hits outside the overlay are writers (`utils/hq/hq-lib.sh:468`, `utils/py/express.py:728`) and an example (`relay-automation/CONTRACT.example.md:44`); reads are `sentinel-overlay/morning-report.sh:54` and `sentinel-overlay/sentinel-nightly.sh:32`. No hits in marathon_plan, jog or swarm_preflight. "Only reads" does not mean "only mentions."

- [Pass] **Express removes the fabricated PRS rating without breaking the row grammar.** `utils/py/express.py:848-853` keeps the same add arguments and markdown structure. `utils/py/releases_app.py:3325-3331` returns NULL fields for no tokens, and `:3639-3690` accepts and stores them. A read-only `python3` probe imported `parse_rating, validate_raw_text`, AST-extracted the actual `cmd_ledger` raw-format string, rendered issue 1333/title `Example`/doc `PROJECT/2-WORKING/GH-1333-EXAMPLE.md`, and compared it with `new.replace('🆕 —', '🆕 rated 2/2/2/2 —')`. Command assertions: `assert not all(v is None for v in parse_rating(old,'Example').values())` and `assert all(v is None for v in parse_rating(new,'Example').values())`; exit 0. Decisive output: old `{rating_pri: 2, rating_sev: 2, rating_appeal: 2, rating_effort: 2, rating_ovr: None}`, new all five fields `None`; `old all_null=False`, `new all_null=True`. Thus the old value is a witnessed red control for the unrated expectation. Express's subsequent manifest/landing flow does not require ratings (`express.py:858-869`, `:888-897`). The existing test uses `raw_text=None` already (`test/gh267-express-skill.sh:232-234`).

- [Pass] **Planner fallback remains pre-existing Phase 4 scope.** NULL DB axes produce no DB rank (`utils/py/_marathon_plan.py:791-797`), and unrated records have an explicit path (`:1060-1078`). Express still emits legacy `complexity/risk/effort: 2` and `ratings_provisional: true` (`express.py:725-728`); the planner counts those fields as rated (`_marathon_plan.py:923-948`) and can fall back to their score (`:1172-1177`). Removing the fake DB score exposes that existing fallback, but does not introduce the ignored provisional flag. No planner fix is required in this PR. Interpret CHANGELOG's "rows now stay unrated" as PRS columns, not a promise of planner exclusion.

- [Pass] **The three policy decisions are coherent and deferred.** `PROJECT/PDDA.md:45-51`, `:299-309`, `:497-504` make issue state authoritative, paths caches, and the sweep the planned mover; `:308` explicitly says "Until it lands." The decision record at lines 5-16 and CHANGELOG lines 5-7 preserve that boundary. Current `wave_reconcile.py:1067` already scans both active folders; `:2370-2374` selects closing-linked issues, and `:2390-2397` preserves positively OPEN issues absent force. `pdda.sh:603-671` scans WORKING and COMPLETED, not INBOX, and still recommends closing in case (c). Those are existing implementation limitations, not evidence the sweep has shipped. No additional folder-as-authority rule was found in the full PDDA prose sweep that overrides the new policy.

- [Pass] **SOP's local-writer correction matches code.** `.github/workflows/wave-reconcile.yml:9-10` exposes only `workflow_dispatch`; `merge_cleanup.py:893-932` defaults to local reconcile unless `MERGE_CLEANUP_USE_HOSTED=1`; `wave_reconcile.py:135-148` blocks an in-flight hosted writer unless forced. `ROUTER.md:118-122` agrees. `AGENTS.md:73-77` still contradicts it, while AGENTS line 224 agrees; CHANGELOG line 11 explicitly tracks that stale copy under #1160 / PR #1326. Do not restore incorrect SOP text to match it.

- [Pass] **Records and closing-clause safety.** Decision-record lines 6 and 14 repeat the supplied measurements exactly: 45 stale paths and 25 closed issues with active docs. This checks transcription, not a fresh recount. The record says policy-only at line 16; its "No code ... changed with this record" applies to the record, while CHANGELOG lines 8-11 separately describes Phase 1. Read-only `python3` probe loaded only the pure regex/extractor source span from `CLOSING_KEYWORD_CLAUSE =` through `extract_linked_issues`, extracted non-header `+` lines from the embedded diff, asserted nonempty input, and called `extract_linked_issues({'body': added}, 'HiQS-Labs/XYZ-forge')`. Exit 0; decisive output: `added lines: 81`, `added prose closers: []`. Control body `does not close #1333` yielded `[1333]`. This covers added artifact text, not an unseen live PR body or commit message.

- [Nit] **Pre-existing full-file observations, not required scope expansion.** SOP lines 80-82 still recommend a raw-text refresh without preserving ratings; `LESSONS-LEARNED.md:115-122` already records that loss and its remedy. PDDA lines 1025-1028, 1047-1048 and 1059-1062 contain duplicated legacy CHANGELOG prose. Step 4's provisional claim above is the relevant unresolved defect; these older cleanup items need not expand this patch.

- [Unverified — needs clone run] The seeded context reports `test/gh267-express-skill.sh` 113/113, but this turn did not execute it or a gate, and no GH-1333 test receipt was found in the seeded `TESTS-RESULTS` paths. Full-file review covered PDDA, SOP, express, start-marathon, the decision record and the top CHANGELOG entry; runtime validation remains with the harness's disposable-clone gate. No new suite, machinery, source edit or git command was used.

Handing off to Producer (claude-a) — correct S1, disposition the findings, and open the next review round.

### Producer · Round 2 · claude-a

- **S1: Implemented, and widened by one observed fact.** `skills/2-daily/start-marathon/SKILL.md:239-242` now says that PDDA policy holds `ratings_provisional: true` and `risk > 2` out of automatic selection, that the planner enforces neither, and that the preparer excludes them by hand. While checking, I found the `risk > 2` half is not enforced either. The planner uses `risk` only as a ranking weight (`utils/py/_marathon_plan.py:1160-1175`), and its `gated` state means "awaiting operator go" text (`:701-703`, `:1085-1086`), not risk. So the same correction is applied to the `PROJECT/PDDA.md` "Not enforced today" note (`:174-178`). The reference rule at `:163` is still labelled as tunable policy.
- **Planner fallback `[Pass]`: agreed, no change.** Legacy frontmatter counting as rated is the existing #1333 Phase 4 item. The CHANGELOG's "stay unrated" refers to the PRS columns.
- **Nits (SOP:80-82 raw-text refresh; duplicated legacy prose in PDDA:1025-1062): Declined.** They are pre-existing and outside this PR's scope; the reviewer marked them not required.
- **`[Unverified — needs clone run]`: addressed with a receipt.** `TESTS-RESULTS/2026-11-03+GH-1333/manual-check.md` and `provenance.jsonl` now record the express red/green, `test/gh267-express-skill.sh` 113/113 at `693e9d22`, the PDDA before/after, and both pre-push gate results. The suite was run unsandboxed in this clone, as the GH-177 guard requires.

ROUND bumped to 2. Handing off to Reviewer (codex). Re-review S1, the widened PDDA note, and the new receipt.

### Reviewer · Round 2 · codex

VERDICT: PASS
Basis: S1 is resolved. The widened risk note describes the current planner correctly, the express placeholder removal still parses as unrated, and the policy-only boundary remains explicit. No outstanding Blocker or Should. Approval is this artifact review, not an attestation that the final-state harness gate has run.
swept file: yes

- [Pass] **S1 resolved; the risk correction is supported.** `skills/2-daily/start-marathon/SKILL.md:239-244` now explicitly says to exclude provisional and high-risk items “by hand”; `PROJECT/PDDA.md:174-178` agrees. Read-only command `rg -n 'risk|ratings_provisional|gated' utils/py/_marathon_plan.py` exited 0: risk is read into ratings at line 924 and weighted at 1175; readiness at 1041-1088 has no risk threshold, and `goGated` comes from operator-go prose at 701-703. The canonical DB-rank branch at 1165-1171 bypasses legacy risk weighting altogether; neither path implements the policy hold. No implementation of Phase 4 is required here.

- [Pass] **Express red/green repeated against the seeded source.** `utils/py/express.py:848-853` retains the row shape and add arguments. Command: `PYTHONDONTWRITEBYTECODE=1 python3 -` importing `parse_rating` from `utils/py/releases_app.py`, AST-selecting the `raw` assignment inside `cmd_ledger`, and rendering it with `(1333, 'Example', 'PROJECT/2-WORKING/GH-1333-EXAMPLE.md', 1333, 'https://github.com/HiQS-Labs/XYZ-forge/issues/1333')`. The control was `old = new.replace('🆕 —', '🆕 rated 2/2/2/2 —')`; assertions required nonempty distinct inputs and `all(v is None for v in parse_rating(raw, 'Example').values()) == (label == 'new')`. Exit 0; decisive output: old `{rating_pri: 2, rating_sev: 2, rating_appeal: 2, rating_effort: 2, rating_ovr: None}`, new all five fields `None`. Legacy doc ratings at express lines 725-728 and planner fallback at `_marathon_plan.py:1172-1177` remain the previously identified Phase 4 limitation, not a new eligibility guarantee.

- [Pass] **Whole-file sweep preserves the policy boundary and local-writer correction.** Re-read all of PDDA, SOP, express, start-marathon, the decision record, and the top CHANGELOG entry. `PROJECT/PDDA.md:300-310` says “Until it lands”; decision-record line 16 says “policy decided, not yet implemented”; CHANGELOG line 7 explicitly defers sweep and reader implementation. `wave_reconcile.py:1067`, `:2370-2397`, and `utils/pdda/pdda.sh:603-671` retain the current scan/move limitations described in Round 1. SOP lines 261-267 match `wave-reconcile.yml:9-10`, `merge_cleanup.py:893-932`, and the in-flight guard at `wave_reconcile.py:135-148`. No additional blocking pre-existing defect or folder-as-done contradiction was found in the swept files; the Round 1 SOP rating-refresh and duplicated PDDA-prose nits remain deferred. The known stale AGENTS copy remains explicitly tracked by CHANGELOG line 11.

- [Pass] **No accidental closing clause in the reviewed additions.** Command: `PYTHONDONTWRITEBYTECODE=1 python3 -`, loading only the pure `wave_reconcile.py` source span from `CLOSING_KEYWORD_CLAUSE =` through `extract_linked_issues`, then calling `extract_linked_issues({'body': text}, 'HiQS-Labs/XYZ-forge')`. Input was the 81 non-header added lines from the embedded diff, plus the current decision record, manual-check receipt, PDDA lines 174-178 and skill lines 239-244; extraction was asserted nonempty. Exit 0; decisive output: `added lines 81 closers [] negative-phrase control [1333]`. The control was `does not close #1333`. This checks artifact text, not an unseen live PR body or commit message. Decision-record lines 6 and 14 still transcribe the supplied measurements as 45 stale paths and 25 closed issues with active docs; no fresh recount is claimed.

- [Unverified — needs clone run] **Receipts are now present; final-state gate remains outside this turn.** `TESTS-RESULTS/2026-11-03+GH-1333/manual-check.md:12-26` and `provenance.jsonl:1-3` record 113/113 and the full-gate result for `693e9d22`. They do not attest the later prose corrections or establish pre/post-run clone identity. The producer's “unsandboxed” wording alone is not proof of disposable-full-clone isolation. Accept these as reported historical evidence, not an independently witnessed final-state gate. The harness must perform its prescribed disposable-clone verification after this review; no suite, executable fixture, git command, or source mutation was run here. The graph inventory tool was unavailable under the session's approval policy, so source inspection used read-only file access.

Relay closed (Approved), no further turn needed.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
