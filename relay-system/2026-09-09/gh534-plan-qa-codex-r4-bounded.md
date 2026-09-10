---
Goal: Bounded round 4 — re-adjudicate ONLY R3-A, R3-B and E.6 of plan rev 4 (GH-534)
Date: 2026-09-09
Producer: claude-a
Reviewer: codex
NEXT: codex
STATUS: Open
Round-cap: 1
Supersedes: relay-system/2026-09-09/gh534-merge-cleanup-plan-qa-codex.md (three rounds, cap exhausted)
---

# Context

The operator authorized exactly one more review round, **bounded to three sections** of
`PROJECT/1-INBOX/GH-534-MERGE-CLEANUP-FAILURE-MODES.md` (rev 4, this commit). Everything else in
the plan was accepted in rounds 1–3 of the superseded thread and is **not** under review here;
do not re-open it. This is a plan review, not a build turn; edit only this file.

Read:

- The three sections under review in the plan: **A.4** (the `lsof` three-outcome contract and the
  `tick claims` notes), the **Phase C attempt record** ("One durable attempt record, at one pinned
  coordinator"), and **E.6** (the pre-merge ledger gate). Also their acceptance entries: **A.4**
  (viii)–(xii), **C**, and **E.6**.
- Your own round-3 verdict in the superseded thread (sections R3-A and R3-B) and the producer's
  round-3 response below it, so you can check the corrections against what you asked for.
- `merge_cleanup.py:247` (how `--primary` is chosen), `bin/tick:19` (`TICK_REPO_ROOT`),
  `src/events.js:204-212` (`readAllEvents` returns `[]` on a missing dir),
  `relay-automation/driver-lock-lib.sh` (the existing `flock`), `utils/releases-merge-resolve.sh`
  and `utils/py/releases_app.py` `check` / `roadmap reconcile-state` (what E.6 invokes).

Empirical input you did not have in round 3, probed by the producer on this macOS:
`lsof +D <dir>` exits **1 in all four cases** — idle directory, held file descriptor inside it,
nonexistent path, unreadable subdirectory. The traversal-failure cases print
`lsof: WARNING: can't opendir(...)` / `can't stat(...)` on stderr; the idle and held-fd cases
print nothing on stderr. The probing shell's own process appeared in the idle run's stdout.

# Questions — answer these three only

1. **R3-A closed?** Does A.4's contract — outcome decided by stderr (any line → incomplete →
   preserve) plus `-F pn` records filtered component-wise to the checkout with the scanner's own
   PID and ancestors excluded, run from a CWD outside the checkout, never by exit code — give
   the three outcomes you required (verified matches / verified complete no-match / incomplete)?
   Is "any stderr line ⇒ incomplete" the reliable distinction on macOS, given the probe? Are
   fixtures (viii)–(xii) and their red controls sufficient, and do (viii) and (x) fail in the
   right direction when the guard is mutated? Anything still Blocking, cite plan text.

2. **R3-B closed?** Is the record now a single physical file — pinned at the explicit
   `--primary` coordinator, absolute path resolved once and carried as `MERGE_CLEANUP_RECORD`
   into every handoff and worker, missing/unreadable ⇒ stop, never inferred from CWD? Is
   admission under the existing driver `flock` adequate for "check count and reserve together"?
   Is "only repair attempts count, bound to `head_sha`, two per PR whatever the head" the right
   accounting, and does the two-full-clone fixture (caller attempt from clone 1, script B1 from
   clone 2, third refused from either, red when root is CWD-derived) actually detect a
   fresh-clone reset? Anything still Blocking, cite plan text.

3. **E.6 — new scope, first look.** For every PR: disposable clone of the PR head, merge
   `origin/<integration-branch>`, then `releases check` and `roadmap reconcile-state --dry-run`;
   red or a failed command never merges; post-merge `check` becomes gating. Is the *merge into
   the PR head* the right simulation of a squash landing for ledger purposes, or does it need
   the squash itself (e.g. `git merge --squash` + the resolver's generation rule)? Does the gate
   interact correctly with B1 (a merge conflict routes to B1; a clean merge with a red `check`
   parks) and with `reconcile-state`'s own refusal modes (#527 made it per-row; does a
   `roadmap-issue-identity` warning count as red here)? Is the E.6 fixture (PR 2 clean alone,
   red after PR 1 lands, not merged, red control removes the gate) sufficient? Anything
   Blocking, cite plan text.

Mark each of the three **Closed** or **Blocking** with the plan text you dispute. Do not raise
findings outside these three sections; if you notice one, list it under a final
"Out of scope, noted" line without a verdict. Set `STATUS: Approved` if all three are Closed;
otherwise leave `STATUS: Open` and set `NEXT: claude-a`.

<!-- ▽ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK ▽ -->
▶ TAKE YOUR TURN (codex)
<!-- △ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK △ -->

# Log
