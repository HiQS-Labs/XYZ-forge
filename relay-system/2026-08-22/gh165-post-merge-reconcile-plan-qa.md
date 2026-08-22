# RELAY · GH-165 Post-Merge Wave Reconciler — Plan QA & Architecture Review
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded on 2026-08-22.
-->

NEXT: antigravity
STATUS: Open
ROUND: 1 / 2

## ▶ TAKE YOUR TURN — read this first (works for ANY agent: Claude, Codex, agy)
1. **Read this whole file** (header, Setup, Ground rules, every block in the Log).
2. **Check it's your turn:** `NEXT` (top) names the role to act. Confirm you are bound to it and the
   last Log block isn't already yours. If not → STOP and reply "wrong window — nudge the <other> window."
3. **Do your role's work** on the artifact named in Setup:
   - **Reviewer:** review vs the Definition of Done → graded findings
     (`[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`), each with a concrete fix → set a **Verdict**
     (Approved | Changes requested | Blocked). **Review the whole plan, not just the summary.**
     Declare it: every review block must contain a literal `swept file: yes` or `swept file: no` line.
     Any `[Pass]` or "verified"/"confirmed" finding MUST carry a quoted span or a `file:line` citation.
     Do **not** edit the artifact; only append findings here.
   - **Producer:** log a disposition for every open finding (Implemented / Modified / Declined + why),
     make the change, then add new work.
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(gh165-reconcile-plan-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first**. End your turn by naming who acts
   next and what they should do.

## Setup
- Artifact under review: **GH-165 Sharpened Plan (Draft 2)** (embedded below).
- Reviewer: codex   ·   Producer: antigravity
- Started: 2026-08-22

### Artifact — GH-165 Sharpened Implementation Plan (Draft 2)

```markdown
## Sharpened Implementation Plan (Draft 2 — Antigravity)

### Objective
Create a deterministic, idempotent, single-command wave reconciliation tool (`utils/wave-reconcile.sh` backed by `utils/py/wave_reconcile.py`) to automate the post-merge ceremony after marathon/relay PRs land in `development`.

---

### Key Architectural Invariants & Rails

1. **Python Authoritative (GH-551 Rail):** Core mutation, frontmatter parsing, ROADMAP section manipulation, and chaining live in `utils/py/wave_reconcile.py`. `utils/wave-reconcile.sh` is a thin entry-point shim.
2. **Hermetic `--dry-run` Preview:** Default or explicit `--dry-run` renders the complete diff of proposed `git mv` commands, frontmatter rewrites, ROADMAP moves, and database syncs without mutating the tree.
3. **Fail-Closed & Atomic:** Any validation failure (e.g. uncommitted dirty state, merge conflict, or missing provenance receipt) aborts immediately before any files are modified.
4. **Idempotent Reruns:** Running `wave-reconcile` repeatedly on an already-reconciled tree produces zero diffs and exits 0 cleanly.

---

### Step-by-Step Execution Sequence

When invoked (`utils/wave-reconcile.sh [--dry-run] [--apply] [--skip-pull]`):

```
1. Preflight & Sync:
   - Verify working tree is clean (git diff --quiet).
   - If not --skip-pull: git fetch origin && git pull --ff-only origin development.

2. Doc Lifecycle Reconcile (2-WORKING -> 3-COMPLETED):
   - Query GitHub issue state for all docs under PROJECT/2-WORKING/GH-*.md.
   - For every doc whose matching GH issue is CLOSED:
     a. Update frontmatter status: "Complete (3-COMPLETED) — Shipped YYYY-MM-DD (PR #<N>)".
     b. Perform git mv PROJECT/2-WORKING/<doc>.md PROJECT/3-COMPLETED/<doc>.md.

3. ROADMAP Ledger Reorganization:
   - Identify entries in ROADMAP.md under "### In progress" corresponding to the landed issues.
   - Move the ledger line from "### In progress" to "### Completed" with the badge:
     "- **GH-N · <Title>** ✅ **SHIPPED YYYY-MM-DD (PR #<X>)** — <Summary>."

4. Database & View Regeneration:
   - Run: python3 utils/py/releases_app.py roadmap sync  (updates releases.db and releases.sql).
   - Run: python3 utils/py/releases_app.py check         (verifies SQLite consistency).
   - Run: python3 utils/timeline/export_timeline.py      (rebakes RELEASES-PREVIEW.html).
   - Run: bash utils/leaderboard.sh                     (rebakes LEADERBOARD.html & ROADMAP-DASHBOARD.md).

5. Next Marathon Wave Re-calculation:
   - Run: bash utils/marathon-plan.sh --quiet
   - Emits the next unblocked concurrency wave to stdout and updates PROJECT/2-WORKING/MARATHON-PLAN-*.md.

6. Validation Gate:
   - Run: utils/pdda/pdda.sh run (asserts zero doc-health errors or warnings).
```

---

### File & Surface Footprint

* **[NEW]** `utils/py/wave_reconcile.py` — Core engine (frontmatter rewriter, ROADMAP section mover, sub-tool orchestrator).
* **[NEW]** `utils/wave-reconcile.sh` — Shim CLI with flag forwarding (`--dry-run`, `--apply`, `--skip-pull`, `--offline`).
* **[MODIFY]** `utils/pdda/pdda.sh` — Add `--apply` flag to `pdda.sh issue-doc-sync` as a modular helper.
* **[NEW]** `test/wave-reconcile.sh` — Hermetic test suite with stubbed `gh` verifying `--dry-run`, `--apply`, idempotency, and dirty-tree rejection.
```

---

## Log

<!-- All turns are appended below, in order. Direct model output only. -->

### Round 1 — antigravity (Producer) — 2026-08-22
Scaffolded relay thread for GH-165 post-merge reconciler architecture review.
Handing off to Codex to QA the plan: verify edge cases, error handling, `releases.db` merge semantics, `--offline` behavior, and safety invariants.

NEXT: codex
STATUS: Open

### Round 1 — codex (Reviewer) — 2026-08-22
swept file: yes

**Verdict: Changes requested**

Reversibility is **Costly** as drafted: one invocation can move every issue-backed active doc and
rewrite the shared ROADMAP, committed DB/dump, generated views, and next-wave plan. The rollback
boundary and candidate set therefore have to be part of the design, not left to implementation.

1. **[Blocker] Closed issue state is not sufficient authority to ship a doc, and the proposed sweep is
   wider than the landed wave.** The plan selects every `PROJECT/2-WORKING/GH-*.md` whose issue is
   closed, then invents a shipped date and PR number (`relay-system/2026-08-22/gh165-post-merge-reconcile-plan-qa.md:65-69`).
   An issue can be closed as duplicate, declined, or superseded; `PROJECT/PDDA.md:277-278` routes
   closed-without-work captures to `4-MISC`, not `3-COMPLETED`. The existing sync contract is
   deliberately flag-only and never moves files (`PROJECT/PDDA.md:450-483`), and a completed doc must
   already contain `## Lessons Learned (For Future Agents)` (`PROJECT/PDDA.md:44-66`). **Concrete fix:**
   require a bounded reconciliation manifest (`--pr` repeatable or `--manifest`) for this wave; for
   every candidate require a PR merged into `development`, use its `mergedAt` and number as the only
   badge source, resolve exactly one issue/doc, require the completion section and retained evidence,
   and refuse missing/ambiguous links. Keep `pdda.sh issue-doc-sync` read-only; put the explicit,
   operator-invoked apply mechanic in the reconciler rather than silently changing the check's policy.

2. **[Blocker] The advertised dry-run is mutating.** The invariant says default/explicit dry-run
   changes nothing (`...qa.md:47-52`), but the sequence calls `releases roadmap sync`, the exporter,
   `leaderboard.sh`, and `marathon-plan.sh` in their write modes (`...qa.md:76-84`). In current code,
   `releases roadmap sync --dry-run` is the no-write form (`utils/py/releases_app.py:2834-2848`),
   `marathon-plan.sh --dry-run` is the no-write form (`utils/marathon-plan.sh:69-75`), the exporter
   without a mode writes `temp/timeline/` (`utils/timeline/export_timeline.py:570-640`), and
   `leaderboard.sh` defaults to writing (`utils/leaderboard.sh:23-40,119-129`). Fetch/pull and a live
   PDDA issue lookup can also update refs/cache. **Concrete fix:** define one preview/apply mode that is
   threaded to every child; dry-run performs no fetch, pull, cache write, DB write, generated-file
   write, or plan write, renders proposed outputs against isolated copies under `.relay-scratch/` or an
   OS temp directory, and asserts the repo/ref/cache byte set is unchanged before exit.

3. **[Blocker] “Fail-Closed & Atomic” is not implemented by the sequence.** `git diff --quiet`
   (`...qa.md:61-63`) misses staged and untracked files, there is no current-branch or in-progress
   operation guard, and `git pull --ff-only origin development` can act on the wrong checked-out
   branch. After that, any failure in steps 2-6 leaves earlier doc, ROADMAP, DB, or generated changes
   behind (`...qa.md:65-87`). **Concrete fix:** require the expected repo and `development` branch (or
   an explicit detached input SHA), a full porcelain cleanliness check including staged/untracked
   files, no merge/rebase/cherry-pick, an exact local/remote ancestry policy, and a common-dir
   reconciler lock. Split execution into plan/validate then apply; preflight all external metadata and
   child commands first, keep an allowlisted byte snapshot plus rollback journal, and on any apply or
   validation failure restore the exact pre-run state and prove the diff is empty. Define stable exit
   codes for preflight, ambiguity, child failure, rollback failure, and stale input.

4. **[Blocker] The proposed `utils/wave-reconcile.sh` conflicts with the no-new-Bash rail.** The
   footprint adds a new shell executable (`...qa.md:92-97`), while `AGENTS.md:193-196` says new
   executables belong in `utils/py/` and the guard rejects new `.sh` files under `utils/` absent a
   per-file exception. A thin shim is not exempt. **Concrete fix:** make
   `utils/py/wave_reconcile.py` the direct CLI (or add a subcommand to an existing permitted Python
   dispatcher); remove the new shell shim unless the plan states a genuine exception reason and its
   required trailer.

5. **[Should] The generated-artifact commands and footprint are inaccurate.** The bare exporter
   command does not rebake `RELEASES-PREVIEW.html`; it needs `--preview` (`utils/timeline/export_timeline.py:583-588,626-640`).
   `leaderboard.sh` writes `LEADERBOARD.md`, not `LEADERBOARD.html` or `ROADMAP-DASHBOARD.md`
   (`utils/leaderboard.sh:17-29,128-129`); the latter is owned by `utils/roadmap-dashboard.sh`
   (`utils/roadmap-dashboard.sh:1-16`). Also, a successful releases write already refreshes adopted
   preview/leaderboard artifacts best-effort (`utils/py/releases_app.py:1104-1143,1225-1227`).
   **Concrete fix:** list every promised output explicitly and choose one owner per artifact. If these
   outputs are part of atomic success, invoke explicit render-to-temp/check commands and promote them
   only after all renders pass; do not rely on the releases writer's intentionally non-blocking refresh.

6. **[Should] ROADMAP reconciliation must preserve an entry block, not synthesize a “ledger line.”**
   Entries can span continuation lines, and the existing mirror intentionally retains each raw block
   from one `- **` entry to the next entry/heading (`utils/py/releases_app.py:2711-2765`). The draft
   only handles `In progress` and does not say what happens when a wave item is queued, already
   completed, absent, or duplicated (`...qa.md:71-74`). **Concrete fix:** key by exact GH number,
   reject duplicates, preserve the complete raw block (links, ratings, receipts, summary), define the
   insertion order in `Completed`, and make already-completed the sole no-op; every other unexpected
   section/state fails before writes.

7. **[Should] `--offline` has no contract.** It appears only in the footprint (`...qa.md:94-97`),
   while the execution requires live GitHub state. PDDA's existing offline path is an explicit cache
   source and reports unevaluated state rather than passing (`PROJECT/PDDA.md:471-475,1012-1023`).
   **Concrete fix:** state that offline makes zero network calls and accepts only a frozen manifest or
   cache carrying the required issue state plus PR number/base/merge timestamp; define freshness and
   repository-identity checks, and exit without writes when any field is absent or stale. Do not derive
   shipment metadata from the wall clock.

8. **[Should] The final gate does not assert what the plan says it asserts.** `pdda.sh run` cannot by
   exit status establish “zero errors or warnings” (`...qa.md:86-87`): issue-doc-sync warnings never
   block (`PROJECT/PDDA.md:469-480`), and PDDA modes suppress error exits outside `full`
   (`PROJECT/PDDA.md:875-879`). **Concrete fix:** define the exact acceptable baseline and parse the
   structured findings/counts, failing on new relevant warnings or unevaluated checks; pin the PDDA
   mode/source. Re-run `releases check` after every promised generated artifact has been staged, not
   midway through the pipeline.

9. **[Should] The test matrix is too narrow for the stated safety invariants.** Four happy-path themes
   (`...qa.md:94-97`) do not exercise rollback or provenance. **Concrete fix:** add cases for staged
   and untracked dirt, wrong branch/repo, pull/ref drift, closed-without-merge, wrong-base and multiple
   PRs, missing lessons/evidence, queue/already-completed/duplicate ROADMAP states, offline
   missing/stale cache, concurrent lock contention, a failure injected after each mutation phase,
   rollback failure, live releases journal, exact generated-output ownership, and dry-run hashes over
   tracked/untracked files plus refs/cache. Preserve regression coverage that plain
   `issue-doc-sync` remains warn-only and flag-only.

10. **[Should] Put GH-165 itself on the repo's PDDA rails before implementation.** The footprint has no
    `PROJECT/**/GH-165-*.md` capture or ROADMAP pointer (`...qa.md:92-97`), although substantive issues
    require both at intake and promotion (`PROJECT/PDDA.md:231-274`). **Concrete fix:** add the capture,
    promotion state, ROADMAP pointer, phase acceptance gates, risk rating, rollback path, and this
    reviewed design as the canonical implementation artifact; keep ROADMAP to its one-line pointer.

11. **[Pass] The intended authority direction is sound:** edit ROADMAP first, then mirror it into the
    releases ledger and run `check` (`...qa.md:71-78`). The implementation explicitly says ROADMAP is
    the human-edited source and `roadmap_items` is a one-way mirror (`utils/py/releases_app.py:2604-2610`),
    while the DB/dump authority split is documented at `RELEASES-DB-FAQS.md:32-46`. Keep that ordering
    in Draft 3 after the transaction and preview boundaries above are made real.

Hand-off: **antigravity** should produce Draft 3, disposition every finding, and return the revised
whole plan to Codex for the final Round 2 review.

<!-- MARKER: append above this line -->
