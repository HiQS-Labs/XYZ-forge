---
Goal: QA the GH-421 plan — automate post-merge wave reconciliation
Date: 2026-09-04
NEXT: Reviewer
STATUS: Open
---

# Context

Adjudicate the plan at `PROJECT/1-INBOX/GH-421-AUTO-WAVE-RECONCILE.md` against the code it
describes. This is a **review turn** — report, do not edit. Cite `file:line` wherever you disagree
with a specific claim.

Read in full:

- `PROJECT/1-INBOX/GH-421-AUTO-WAVE-RECONCILE.md` — the plan under review
- `utils/py/wave_reconcile.py` — the tool being automated (esp. `:459-560` ROADMAP.md writes,
  `:671` DB rollback, `:715` the ledger call, `:925` the OPEN-issue guard)
- `utils/py/releases_app.py:3374-3383` — the `roadmap sync` releases-mode skip
- `.pdda-mode` — the `ROADMAP_SOURCE=releases` marker
- `.github/workflows/ci.yml` — esp. `:99-112` (triggers, concurrency, permissions) and `:559`
- `AGENTS.md` §13 and `GUIDING-PRINCIPLES.md` — the house rules the plan claims to follow

Repo context you should assume rather than rediscover: this repo is in releases-mode, the DB
(`releases.db` via `releases.sql`) is planning truth, `ROADMAP.md` is frozen legacy, and all ledger
writes go through `utils/py/releases_app.py` — never direct SQL.

# Questions

Answer each one explicitly. A bare "looks fine" on any of these is not an answer.

1. **Is the phase ordering right, and is the blocker real?** The plan refuses to wire any trigger
   until `wave_reconcile.py` writes the DB, arguing that automating it first would write a wrong
   record at machine speed and exit 0. Verify that claim against `wave_reconcile.py:715` and
   `releases_app.py:3374-3383`. Is `roadmap sync` genuinely the tool's *only* ledger write — or did
   the plan miss a DB write elsewhere in the file? If the blocker is overstated, say so.

2. **Is Phase 1's write set correct and complete?** The plan maps two transitions to
   `manifest ship --evidence` and `roadmap repoint`. Are those the right verbs? Is anything the
   reconciler already computes left without a DB write — in particular, what should happen to a
   `roadmap_items` row's `status_marker` when work completes, given that in releases-mode
   `roadmap sync` is the only thing that used to set it? If that is a real hole, name it.

3. **Are the six determinism requirements sufficient AND individually testable?** For each of the
   six, say whether a test can actually falsify it as written. Call out any that is a statement of
   intent rather than a checkable property. Specifically: is the idempotency claim ("second run
   writes nothing") testable given the reconciler regenerates dashboards that may embed timestamps?

4. **Is `pull_request: closed` the right trigger, and is the anti-loop argument sound?** The plan
   claims that shape cannot self-retrigger. Verify. Also: what happens when a PR merges while
   another reconcile is mid-run — is `concurrency: {group, cancel-in-progress: false}` sufficient,
   or does the queued run operate on a base commit that has since moved?

5. **Does anything here invent a subsystem it does not need?** Judge through a YAGNI lens. The plan
   claims "no new script or module," but Phase 2 adds a new workflow file. Is a separate
   `.github/workflows/wave-reconcile.yml` justified, or should this be a job inside the existing
   `ci.yml`? Argue the cheaper option if there is one.

6. **What is missing that would bite in production?** Concretely: `--gate` is left as an open
   question in the plan; a reconcile needs a token with `contents: write` and this repo's `ci.yml`
   is `contents: read`; a bot-authored commit to `development` may interact with branch protection.
   Name the failure modes the plan does not cover, and rank them.

7. **Are the reds falsifiable?** The plan proposes reproducing PRs #420 and #409 as red controls.
   Can those actually be replayed deterministically, or does replaying a merged PR require state
   that no longer exists? If they cannot be replayed, propose reds that can.

Flag anything wrong, missing, incorrectly scoped, or over/under-engineered. Where you disagree with
the plan, cite the line in the plan and the line in the code that contradicts it.

Write your verdict below. Set `STATUS: Approved` only if the plan is implementable as written;
otherwise leave it Open and hand back with your findings.

<!-- ▽ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK ▽ -->
▶ TAKE YOUR TURN (codex)
<!-- △ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK △ -->
