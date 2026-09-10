# RELAY · GH-549 work-state event stream — plan QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-09-10.
-->

NEXT: Reviewer
STATUS: Open
ROUND: 1 / 3

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
6. **Commit only the relay file** (`relay(gh549-work-events-plan-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **.relay-artifacts/GH-549-WORK-STATE-EVENT-STREAM.md** — the read-only path that
  `relay-drive.sh --artifact-file PROJECT/2-WORKING/GH-549-WORK-STATE-EVENT-STREAM.md` seeds into the isolated worktree (read it there; do NOT edit it).
- Supporting context, all in the repo you are reviewing (read them, do not take the plan's word):
  - `PROJECT/1-INBOX/recon-gh549-work-events.md` — the recon map the plan is written against.
  - `PROJECT/1-INBOX/recon-projects-board-sync.md` — the earlier map of what writes to the board today.
  - `utils/py/releases_app.py` — `perform_write` at :1317, `op_receipts` DDL + triggers at :603-621,
    `business_digest` at :1224-1226, `dump_text` at :1034 with the `include_receipts` guard at :1214,
    `MIGRATIONS` registry at :966-974, `cmd_check`'s chain walk at :4659-4704, `load_dump` at :4950.
  - `utils/py/board_sync.py`, `utils/py/device_config.py`, `utils/py/mock_gh_board.py`,
    `githooks/pre-push`, `skills/merge-cleanup/scripts/merge_cleanup.py`,
    `test/gh402-board-sync.sh`, `test/gh405-mock-board-harness.sh`, `utils/ci-route.sh`, `validate.sh`.
  - Issue: https://github.com/HiQS-Labs/XYZ-forge/issues/549
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-09-10
- Definition of Done: the plan, if executed exactly as written, satisfies every acceptance criterion
  on issue #549; every claim it makes about the existing code is true at commit `52938679`; it extends
  the existing subsystem and the existing single write path rather than building a second one; the
  blast radius, dependency ordering, rollback and red controls are sufficient to catch the failures
  they claim to catch; and no acceptance criterion is left without a check that can actually go red.

## Review questions — adjudicate each, cite `file:line` or a quoted span

**This is a PLAN review. No code has been written yet.** Grade the plan, not an implementation.

1. **Are the plan's factual claims about the code true?** It asserts, among others: `perform_write`
   is at `releases_app.py:1317` and is the single write path for 28 domain verbs; `op_receipts` is
   append-only via triggers at `:618-621`; `business_digest` (`:1224-1226`) excludes anything inside
   `dump_text`'s `include_receipts` guard (`:1214`); `jog_set_status` (`:4417`) computes its `op`
   string. Verify each against the source and say which, if any, is wrong.

2. **Is Phase 1.3 actually correct?** The plan's central claim is that putting `connector_cursors`
   into `business_digest` would break the receipt chain on *every* subsequent ledger write, because a
   cursor advances after the transaction. Trace `cmd_check`'s chain walk at `:4659-4704` and say
   whether that is true, whether the proposed placement genuinely prevents it, and whether the stated
   red control (move the emit above the guard, run two `roadmap add` calls, expect `receipt-chain`)
   would actually fire.

3. **Is there a write path this design misses?** The recon map claims `perform_write` is the only
   domain write path, with four in-file exceptions (`cmd_init`, `perform_migration`, `_rebuild`,
   `load_dump`) and one real bypass (`jog_run.py:1638`/`:1692`). If a ledger mutation can reach the DB
   without passing `perform_write`, this whole design silently loses events. Confirm or refute.

4. **Does the connector layer extend the existing config system or duplicate it?** The plan copies
   `board_sync.py:89-119`'s `resolve_settings()` idiom instead of routing through
   `device_config.resolve_device_setting`. Is that the right call given `board_sync.py:90-92`, or is
   it a second config system wearing a borrowed idiom? Is a third copy of that idiom (after
   `board_sync` and `profile_resolve`) the point at which it should be factored out instead?

5. **Is the failure isolation real?** "Ledger write commits first, then dispatch detached with a
   timeout and an ignored exit code." Does anything in the plan let a connector still block, hang, or
   change the host verb's exit code — particularly the `perform_write` call site after `:1391-1402`,
   and the `pre-push` emitter, given that file runs `set -uo pipefail` with no `-e`?

6. **Are the acceptance criteria each covered by a check that can go red?** Walk issue #549's nine
   criteria against the plan's verification steps and name any criterion whose check would pass even
   if the feature were absent or broken.

7. **Is the `op` → event mapping complete and honest?** 28 callers, one with a computed `op`. Does the
   mapping table cover the states the issue promises (ready / in flight / ready for review / merged),
   and is "unmapped ops emit nothing" safe, or does it silently drop states users will expect?

8. **Sequencing and blast radius.** GH-424's `--status-marker` writer has landed, so rows can now be
   flipped to `🚧`. The plan claims the only thing keeping board writes inert today is that nothing
   calls the writer, and that this work removes that protection. Is the "unconfigured is a silent
   no-op" criterion sufficient protection, and is its red control strong enough?

9. **Whole-file sweep (GH-268).** Pre-existing defects in the files this plan touches are IN SCOPE.
   Declare a literal `swept file: yes` or `swept file: no` line. If you swept and found nothing, say
   so explicitly.

10. **Is anything in this plan unnecessary?** Name any phase, table, verb or abstraction that could be
    cut without failing an acceptance criterion. A plan that survives this question unchanged is
    suspicious.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
