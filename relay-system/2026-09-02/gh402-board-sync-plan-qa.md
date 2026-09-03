# RELAY · GH-402 board-sync plan QA (Qwen 3.8 Max via Token Plan)
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-09-02.
-->

NEXT: Producer
STATUS: Open
ROUND: 1 / 1

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
6. **Commit only the relay file** (`relay(gh402-board-sync-plan-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **.relay-artifacts/gh402-board-sync-plan.md** — the read-only path that
  `relay-drive.sh --artifact-file /tmp/gh402-board-sync-plan.md` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: deepseek   ·   Producer: claude-a
- Started: 2026-09-02
- Definition of Done: the plan (issue #402 body, revision v4) is sound enough to build against — every load-bearing claim is verified or explicitly marked unverified; no architectural defect in the catch system, settings unification, GitHub API usage, failure semantics, or security posture; the phasing is executable as ordered.  [Unverified — no citation]

### Questions to adjudicate (answer each, numbered, with citations to the plan's sections)

1. **Catch system (the L0–L7 table):** besides the plan's own stated "honest floor", is there any work-start shape that slips ALL layers? Are any two layers' misses correlated in a way that breaks the union argument (e.g. both depending on the same artifact)?
2. **"Sensors sensitive, writer precise":** is the strong/weak signal classification complete and correctly assigned? Any signal listed as strong that can fire without real work starting (false positive), or listed weak that actually proves work?
3. **Settings unification into `~/.xyz/device_config.json`** (the GH-174 3-tier resolver): conflicts with existing consumers or resolution order? Is sharing per-device state (`~/.xyz/board_sync_state.json`) across clones sound (stale cache, multi-device races)?
4. **API mechanics:** the duplicate-card check-first race between two devices; option-ID caching staleness after a board edit; the GraphQL-vs-REST rate-budget reasoning. Any wrong or unverifiable claim?
5. **Failure semantics:** is there any path where an adapter could block a turn or push despite the warn-only design (pre-push fire-and-forget, post-commit/post-checkout exit codes, sweeper lock/launchd)?
6. **Column discipline and backfill** (entry ≠ start; 🚧→In progress, ✅→Done, 🆕→Backlog): semantic risks, especially the stale 🚧 markers?
7. **Phasing and verification:** are the witnessed-red requirements adequate to prove each guard? Anything out of order or missing a step?
8. **Security:** public repo + fine-grained PAT + fork-PR reachability — anything in the plan that could leak the token, the settings, or operator-private data (clone-dir names, board contents)?
9. **Calibration:** name the single most over-engineered element and the single most under-specified element of the plan, one each, with why.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

## deepseek r1 — Reviewer

swept file: yes

Read the whole artifact (all 155 lines), then probed every repo-side claim it makes
(`device_config.py`, the hq sweeper pair, `githooks/install.sh` + `pre-push`, a read-only copy of
`releases.db` in `.relay-scratch/releases-probe.db`, the tick kernel event vocabulary,
`wave_reconcile.py`). Pre-existing defects found in the artifact beyond the findings below: none.

### Adjudication answers (citations are artifact lines unless noted)

1. **Catch system:** No work-start shape found that slips all layers beyond the stated honest floor
   (line 76). Worked check: relay lanes in temp-named worktrees (dir matches no `*gh-?<n>*` pattern)
   are still caught by L0 (token names carry `gh<n>` — `task.claimed`, `src/claim.js:89`) and L5
   (`relay-system/**/gh<n>*` diff paths, line 59). BUT the union argument has two correlated-miss
   holes — see [Should] S1: L7 rescans L1–L6's own sources (so it adds temporal repair, not new
   coverage), and L2/L3/L4 share a common cause (convention adherence), so "misses don't correlate"
   (line 50) is too strong.
2. **Sensors:** classification is incomplete and one assignment is wrong — see S2. Clone-folder as
   **strong** fires for triage/QA/review clones (the plan's own evidence, line 35, shows issue
   numbers are constantly used for triage/closing, not work) → In-progress noise that violates
   constraint 1 (line 9). Weak list is otherwise correct; strong list omits L4/L5/derived signals.
3. **Settings unification:** sound, verified against code — no consumer conflict
   (`load_local_device_config()` is a plain `json.load` with no schema validation,
   `utils/py/device_config.py:32-41`; the nested-`profiles` precedent is already consumed this exact
   way, `utils/py/profile_resolve.py:52,190`; live file shape matches line 17 — probed keys
   `device_id/user_name/default_*/logging_enabled/profiles`; consumers real:
   `utils/py/harness_turn_logger.py:14`, `test/gh174-harness-registry.sh`, `test/gh346-*`).
   Cross-clone state sharing is sound as a cache but its concurrency is unspecified — see S5.
4. **API mechanics:** check-first race is real across processes/devices and dedupe is the only
   repair — fine, but say so; option-ID caching contradicts "resolved at runtime" (line 15 vs 102)
   with no invalidation path — see S5. GraphQL-vs-REST reasoning is observation-backed (line 119)
   and consistent with GitHub's separate GraphQL budget; Phase 0 re-probes it (line 131). One
   load-bearing API claim is neither verified nor marked unverified — see S4.  [Unverified — no citation]
5. **Failure semantics:** YES — four blocking paths despite the warn-only design; see [Blocker] B1.
6. **Column discipline/backfill:** the 🚧→In-progress backfill will post stale entries — probe shows
   all 11 🚧 rows last updated 2026-08-25→26, several plainly not in flight; 5 rows have blank
   `status_marker` (no mapping at all) — see S3. Ongoing: abandoned work with a 🚧 and no merged PR
   has no end-signal, so its card stays In progress until OQ 3/7 (lines 140, 144) get answers.
7. **Phasing:** order is executable (spike → core → adapters → enrichments) and the witnessed-red
   discipline is present (line 132) but too narrow — see N2; also no kill-switch (N1). Phase 3's
   backfill must apply S3's staleness filter or it lands noise before threshold tuning exists.
8. **Security:** no leak path found — settings/state/plist all live in `$HOME` or gitignored
   (lines 81, 102-103; precedent plist is generated+gitignored, `install-hourly-scan.sh:5-12`),
   token referenced by path in the `~/secrets/` convention (line 103; matches the AGENTS.md
   OpenRouter pattern), hooks are local-only, Actions rejected as primary / never fork-reachable
   (line 77). Residuals: the token KIND question (S4) changes this discussion if the fallback is a
   classic PAT, and the plan never says warnings/logs must not print the token — see N4.
9. **Calibration:** Most over-engineered: **L1 clone-dir watcher** — a per-device daemon for the
   weakest "strong" signal (S2's false-positive source); anything that ships is caught by L5 anyway,
   so it buys only earlier visibility. Most under-specified: **the adapter execution contract**
   (B1) — one sentence covers pre-push (line 71), nothing covers the other four adapter contexts.

### Findings

- `[Blocker]` **B1 (Q5) — blocking paths exist: the adapter execution contract is specified only for
  pre-push.** Git *waits* for advisory hooks: a synchronous `board_sync.py touch` in `post-commit`/
  `post-checkout` with a hung network call stalls every commit/checkout; a synchronous L2 call stalls
  `pdda.sh` mid-agent-turn; a synchronous L0 fire hook delays lane dispatch; and a *hung-but-alive*
  sweeper holds the mkdir-lock forever — the precedent's self-heal only reclaims DEAD pids
  (`utils/hq/hourly-global-scan.sh:29-35`), so "bounded staleness" (line 61) silently becomes
  unbounded. Lines 71/127 state "never block a turn or push" as an invariant but specify mechanism
  (background + timeout) only for pre-push — an implementation can satisfy the letter (exit 0) and
  still block. Fix: one paragraph extending the line-71 contract to ALL adapters (pdda L2,
  post-checkout, post-commit, L0 fires, watcher) — detached background + hard timeout — plus a
  timeout wrapper on the sweeper run so a hang dies and the lock self-heals; add a witnessed-red
  (DNS-dead environment → `git commit` returns promptly, gate exit unaffected).
- `[Should]` **S1 (Q1) — L7 row overclaims; union argument overstated.** Line 61 "Misses when:
  Nothing — bounded staleness, convergence guarantee" is wrong on both counts: L7 rescans L1–L6's
  sources, so its misses are fully correlated with their union (it repairs missed hook fires, it adds
  no structural coverage), and convergence holds only for artifacts that survive until scan time — a
  clone dir torn down or a branch pruned inside the hourly interval is never seen. Also line 50's
  "misses don't correlate" ignores that L2/L3/L4 share convention-adherence as a common cause.
  Fix: rewrite the L7 row ("misses when: everything L1–L6 structurally miss; guarantees recovery
  from missed fires + bounded staleness for surviving artifacts") and restate the union argument as
  union + L5 multi-artifact scan + L7 temporal repair, not independence.
- `[Should]` **S2 (Q2) — clone-folder "strong" false-positives; strength table incomplete.**
  Line 67 lists clone folder as strong, but folder creation proves presence, not work: triage/QA/
  review clones (line 35's own evidence: issue numbers are used constantly for triage/closing) would
  push issues to In progress — the exact entry≠start violation of line 9. Also the table omits
  signals the layer table uses: commit-message refs (L4), diff paths incl. `relay-system/**` and
  `releases.sql` rows (L5), jog `running` / 🚧 (derived v1, line 108), PR head branch (line 113).
  Fix: a complete signal→strength table; demote clone-folder to weak-until-corroborated (folder +
  branch cut/commit/PDDA move within a window), or explicitly accept and document the false positive.
- `[Should]` **S3 (Q6) — stale 🚧 backfill will pollute In progress.** Probe
  (`.relay-scratch/releases-probe.db`): all 11 🚧 rows have `updated_at` 2026-08-25→26 (a week+
  before this plan), including GH-32 — the long-shipped RELEASES ledger — while line 23 itself calls
  freshness "questionable"; 5 further rows have blank `status_marker` and no mapping. Phase 3's
  "one-time board backfill (🚧/✅/🆕)" (line 134) posts them verbatim. Fix: filter backfill by live
  issue state (skip closed) + recency; route stale 🚧 to Ready/triage; name the blank-marker mapping.
- `[Should]` **S4 (Q8/API) — fine-grained PAT capability on user-level Projects is asserted, not
  verified or marked.** DoD requires every load-bearing claim verified or explicitly marked
  unverified; line 103's "fine-grained PAT (Projects:write only)" is load-bearing for the entire
  write path and is neither — fine-grained PAT permissions are documented at org scope, and support
  for user-project mutations (`addProjectV2ItemById`) is unsettled here. Fix: mark it unverified and
  make it Phase 0's FIRST question, with the fallback named (classic PAT `project` scope + tighter
  handling) — before any token choice is baked into settings or plist.
- `[Should]` **S5 (Q3/Q4) — option-ID cache has no invalidation; state-file concurrency
  unspecified.** Line 15 says option IDs are "resolved at runtime, never hardcoded" while line 102
  caches "resolved option IDs" — after a board edit (option renamed/recreated) the stale ID makes
  updates fail or write the wrong column, with no re-resolve path. Separately, check-first against
  the shared `~/.xyz/board_sync_state.json` is TOCTOU across processes (hook ∥ sweeper ∥ multiple
  clones) and across devices (independent caches) → duplicate cards repaired only at the next dedupe;
  concurrent writers to one state file also need atomic writes (repo convention: `ATOMICALLY`,
  `utils/pdda/pdda-gh-refresh.sh:6`). Fix: re-resolve option IDs on update failure (and each
  sweeper run); specify write-temp+rename atomicity; state plainly that dedupe is the documented
  race repair (up to one sweeper interval of visible duplicates).
- `[Nit]` **N1 — no global kill-switch.** Adapters land inside `pdda.sh`, githooks, and launchd;
  nothing instant-disables the whole system. Add an env kill-switch every adapter honors
  (e.g. `XYZ_BOARD_SYNC=0` → no-op), consistent with the `XYZ_SKIP_PREPUSH` convention.
- `[Nit]` **N2 — widen the witnessed-red list (line 132).** Currently: extractor break + empty
  input. Add: bare `#<n>` mention never writes the board (the noise promise); board_sync failure
  leaves the host hook's/gate's exit unaffected (containment, pairs with B1); `reconcile --dedupe`
  removes exactly one of a seeded duplicate pair.
- `[Nit]` **N3 — resolver nuance for the implementer.** `resolve_device_setting()` resolves only
  TOP-LEVEL keys (`utils/py/device_config.py:44-56`); the per-key `XYZ_BOARD_SYNC_*` env tier for the
  nested object must be re-implemented in `board_sync.py`. The Loading bullet (line 101) already
  implies this — keep it explicit so nobody expects the generic resolver to handle nesting.
- `[Nit]` **N4 — token hygiene in diagnostics.** Failure semantics (line 127) warn to stderr; state
  explicitly that warnings/logs never print the token or Authorization header.
- `[Pass]` Settings unification is conflict-free and precedent-backed — quoted above (A3); verified
  consumers: `utils/py/harness_turn_logger.py:14`, `utils/py/profile_resolve.py:52`,
  `test/gh174-harness-registry.sh`, six `test/gh346-*` suites.
- `[Pass]` Sweeper precedent is accurately described, including gitignored generated plist and
  mkdir-lock — `utils/hq/install-hourly-scan.sh:5-12,38-41`,
  `utils/hq/hourly-global-scan.sh:26-38` — and launchd is established infrastructure on this device
  (`launchctl list` shows `com.xyz-3-agents-swarm.hq-marathon-scan` loaded).
- `[Pass]` RELEASES DB inventory is accurate — probe: 99 rows, ✅47 / 🆕36 / 🚧11; `op_receipts`
  append-only via triggers `op_no_update`/`op_no_delete` with digest chain
  (`state_digest_before/after`, 403 receipts); `jog_queue` has `gh_number/status/attempt_count/
  lease_pid`; `marathons` has exactly 1 row (`planned`).
- `[Pass]` Githooks extension surface is real and worktree-aware: common-dir stub install + `--check`
  (`githooks/install.sh:44-86`), and the `reference-transaction` exclusion (line 71) is correct git
  semantics (nonzero exit aborts the ref transaction — right risk call for an advisory mirror).
- `[Pass]` Security posture holds as written — token-by-path (`~/secrets/`, line 103), all
  state in `$HOME`/gitignored (lines 81, 102), nothing fork-reachable, Actions rejected as primary
  (line 77). Subject to S4's token-kind verification and N4.
- `[Pass]` Prompt-parsing rejection is evidence-based (lines 31-35) and the GraphQL-over-REST choice
  is observation-backed with a Phase 0 re-probe (lines 119, 131).

**Verdict: Changes requested** — 1 Blocker + 5 Shoulds, all fixable as prose edits to the plan in one
Producer round; the architecture itself (union catch + sensitive-sensors/precise-writer + settings
unification into `device_config.json`) is sound and every repo-side claim I probed checked out.

Handing off to Producer (claude-a) — go to the Producer window and say "take your turn": log a
disposition for every finding above (B1, S1–S5, N1–N4), revise the plan artifact accordingly, and
bump ROUND when opening the new cycle.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
