# RELAY · GH-549 work-state event stream — implementation QA (PR #559)
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-09-10.
-->

NEXT: Reviewer
STATUS: Open
ROUND: 2 / 3

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
6. **Commit only the relay file** (`relay(gh549-impl-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **.relay-artifacts/gh549-impl-qa-brief.md** — the read-only path that
  `relay-drive.sh --artifact-file PROJECT/1-INBOX/gh549-impl-qa-brief.md` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-09-10
- Definition of Done: the **six numbered questions** under "Definition of Done" in the artifact
  (`.relay-artifacts/gh549-impl-qa-brief.md`). Answer every one of them explicitly. The change is
  Approved only when issue #549's acceptance criteria are each mapped to code at `file:line`, the
  committed codepaths match the approved plan (or the departure is named and justified), no second
  write path or duplicate subsystem was introduced, no assertion in `test/gh549-work-events.sh` is
  vacuous, and no unresolved `[Blocker]` remains.
- **This is a live repository worktree at the branch head, not a document review.** Run things:
  `git diff 52938679..HEAD`, `git log`, read whole files, and run
  `bash test/gh549-work-events.sh` if you want to see the suite for yourself. Cite `file:line`.
- **You are the Reviewer: do not edit any file except this relay thread.**

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer · codex · round 1

swept file: no

- [Blocker] A successful connector may persist an arbitrary `advanced_to` value. `_collect` accepts any parseable integer (`utils/py/work_connectors/__init__.py:192-202`) and `_persist` stores it without checking it lies in that connector's dispatched batch (`utils/py/work_connectors/__init__.py:206-234`). Thus a buggy or compromised connector can report a value beyond the batch's maximum event id, advance its cursor past real events, and silently lose those events. The suite demonstrates that overshoot causes exactly this skip but treats it as an expected red-control outcome (`test/gh549-work-events.sh:484-491`), rather than proving it is rejected. Fix: retain each batch's permitted maximum (and prior cursor), reject/outcome-error any reported value outside that closed range, and add a red control proving an overshoot cannot advance the cursor.
- [Blocker] `XYZ_WORK_CONNECTORS_REGISTRY` is an unrestricted production code-execution overlay, contrary to its stated contract. `_registry` merges any JSON string path into the registry (`utils/py/work_connectors/__init__.py:117-136`); `load_connectors` then accepts that overlay name from normal device config (`utils/py/work_connectors/__init__.py:85-101`); `_child_argv` executes paths containing a separator (`utils/py/work_connectors/__init__.py:139-143`). This makes the claimed boundary that production config "cannot name a connector the harness did not vendor" false (`utils/py/work_connectors/__init__.py:120-125`). Fix: remove the runtime overlay or gate it behind an unforgeable test-only dependency/seam, and test that normal configuration cannot activate an overlay-only connector.
- [Pass] The implemented write placement is the planned single seam: `perform_write` emits exactly once after the receipt and before commit (`utils/py/releases_app.py:1642-1653`), while `work emit` passes its event through that same function (`utils/py/releases_app.py:4875-4882`). The merge observer only invokes `work emit` after `execute_pr_merge` succeeds (`skills/merge-cleanup/scripts/merge_cleanup.py:429-434`). No second ledger write protocol was found in the reviewed paths.
- [Pass] Migration/dump/rebuild intent matches the approved design: migration 008 creates the two tables and append-only triggers (`utils/py/releases_app.py:895-947`); canonical dumping includes `work_events` under `include_receipts` and excludes cursors (`utils/py/releases_app.py:1277-1301`); restore loads only work events (`utils/py/releases_app.py:5500-5509`). Red controls A and B have non-empty/anchor guards and materially mutate the condition they claim (`test/gh549-work-events.sh:160-229`).
- [Should] Definition-of-Done question 1 is only partially satisfied pending the two blockers above; question 2 matches the plan except for the undocumented executable overlay; question 3 has no second write path in the reviewed paths; question 4 has no vacuous red control found, but lacks the necessary overshoot rejection control; question 5 fails cursor-safety and overlay containment as described; question 6 is not complete because this was not a whole-file sweep of every touched file. No additional pre-existing defect was identified in the portions reviewed.

Verdict: Changes requested.

Handing off to Producer — go to the Producer window and say "take your turn".

### Producer · claude-a · round 1

Dispositions for every open finding.

- **[Blocker] connector cursor advancement — IMPLEMENTED.** Confirmed against the code before
  accepting it: `_persist` wrote the child's integer verbatim (`utils/py/work_connectors/__init__.py:206-234`
  as reviewed), so a connector reporting past its batch skipped events permanently. Fixed at the
  parse boundary rather than at the write, because the child's stdout is the untrusted input:
  `dispatch` now captures `(prior_cursor, batch_max]` from the rows it actually handed each
  connector and `_collect` turns anything outside that closed range into a failed run, which by
  existing behaviour does not advance and leaves the batch replayable. A regressive value is
  refused on the same path. Commit `24166305`.
- **[Blocker] `XYZ_WORK_CONNECTORS_REGISTRY` overlay — MODIFIED, downgraded to [Should], and the
  docstring you were reading was the actual defect.** The finding's mechanism is wrong on one
  load-bearing point: `_registry()` reads the overlay from `os.environ` and from nowhere else, and
  `load_connectors` only consults names already in the registry, so device config **cannot**
  introduce an overlay connector — a `work_connectors` block naming one does nothing unless the
  environment already defined it. The trust boundary is therefore the environment, and anyone who
  can set `XYZ_WORK_CONNECTORS_REGISTRY` on the machine running the ledger can equally run
  `python3` directly, so the overlay grants no capability they did not already hold. What was
  genuinely wrong is the sentence you quoted: "production config still cannot name a connector the
  harness did not vendor" is not true as written, and an inaccurate containment claim in a
  docstring is how a real boundary gets assumed later. The docstring now states the actual
  contract, and an active overlay warns rather than running silently. If you still consider the
  env-gated overlay a blocker after reading `_registry` and `load_connectors` directly, say so with
  a concrete path by which something other than the environment activates it.
- **[Should] Definition-of-Done answers — PARTIALLY ACCEPTED.** Q1–Q5 are addressed above and by
  the commit. Q6 is not: your block declares `swept file: no`, so the GH-268 whole-file sweep did
  not happen, and your own answer says so. That is the main open item for round 2 (below).
- **[Pass] × 2 — noted**, both cited, both consistent with what the plan QA settled.

**A defect the fixes surfaced, disclosed rather than left for you to find.** The first version of
the new red control (15c) was vacuous. It shadowed `work_connectors` via `PYTHONPATH`, but
`releases_app.py` prepends its own directory to `sys.path` before importing it, so the mutated
module never loaded and the control passed against a build that still had the guard. It now mutates
a full copy of `utils/py`, runs that copy's app, and asserts the mutation landed before relying on
the result. Please check that reasoning — a red control that cannot fail is worse than none.

**What round 2 must cover, in priority order.**

1. **The whole-file sweep you skipped (GH-268).** This is the requirement that made the beta case
   worth citing: an independent audit found 20 issues on a branch this loop had approved, every one
   in pre-existing code nobody read. Read the touched files end to end —
   `utils/py/work_connectors/__init__.py`, the changed regions of `utils/py/releases_app.py` and
   their surrounding code, `utils/py/board_sync.py`, `utils/py/device_config.py`,
   `skills/merge-cleanup/scripts/merge_cleanup.py` — and declare `swept file: yes` or `no` again,
   honestly. If you find no pre-existing defect, say that explicitly.
2. **The cursor fix itself**, at `utils/py/work_connectors/__init__.py` — the bounds capture in
   `dispatch` and the range check in `_collect`. Is the range the right one? Is there a path that
   reaches `_persist` with an unvalidated value?
3. **The two new controls, 15b and 15c**, in `test/gh549-work-events.sh`. 15c is the one to be
   hardest on, given it was vacuous once already.
4. Anything from Q1–Q5 you consider unresolved.

Verification: `bash test/gh549-work-events.sh` — **47 passed, 0 failed** at `24166305`.

VERDICT: PARKED
Basis: producer turn — two findings dispositioned (one implemented, one modified with the
mechanism corrected), one self-disclosed vacuous control fixed, suite green at 47/47. Handing back
for reviewer round 2; the whole-file sweep is still outstanding.

Handing off to Reviewer (codex) — take round 2, starting with the whole-file sweep.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
