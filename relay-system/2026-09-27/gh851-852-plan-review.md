# RELAY · GH-851/852 plan review — merge-cleanup landing resilience
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-09-27.
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
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns.
   Reviewer headings may be `### Reviewer · Round N`, `### Round N · Reviewer · <agent>`, `### Reviewer (<agent>)` (optionally followed by `— rN`), or `### Reviewer — Round N` (optionally followed by `(<agent>)`); follow the heading with a non-empty review body.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(gh851-852-plan-review): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **.relay-artifacts/GH-851-MERGE-CLEANUP-LANDING-RESILIENCE.md** — the read-only path that
  `relay-drive.sh --artifact-file PROJECT/1-INBOX/GH-851-MERGE-CLEANUP-LANDING-RESILIENCE.md` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-09-27
- Definition of Done: **Approved** when all of these hold:
  - (a) every recon claim R1–R9 matches the cited file and line at the branch base `030ab5ba`. That includes the R2 list of unbounded network git calls; say if any network call site is missing;
  - (b) each finding F1–F5 has a change that fixes the observed incident, not a generalization of it. Each has a falsifiable red/green witness that is red at the base and green at the head;
  - (c) the plan extends the existing GH-623 `_net_git` / `_retry_call` and GH-736 `_await_mergeable` machinery. It adds no new module, helper family, suite, registry entry or gate machinery (AGENTS.md *No new tests*);
  - (d) the risks are real and the rollback is sound. F2 cannot report a merge that GitHub does not show as `MERGED` with a merge commit. F3 fails closed;
  - (e) the ratings (#851 `55/35/50/85`, #852 `60/45/50/65`) are grounded in the cited #849 evidence, and appeal is neutral.

## Review packet

**What this is.** One PR for #851 and #852. It is the first direct-path item of #854, the operator-approved
stabilization plan (revision 3), and it carries #854's decision D5 (the 5400 s hosted-wait default). Every finding
was hit in the #849 merge batch on 2026-09-27. The plan is the committed capture doc
`PROJECT/1-INBOX/GH-851-MERGE-CLEANUP-LANDING-RESILIENCE.md`, seeded as the artifact above.

**Read these sources yourself.**
- `skills/2-daily/merge-cleanup/scripts/merge_cleanup.py`:
  - `_gh` `:70`, `_net_git` `:106`, `_retry_call` `:117`, `execute_pr_merge` `:148-174`;
  - `prepare_landing_clone` `:278-308`, `validate_head_in_second_clone` `:311-333`, `push_resolved_head` `:336-346`;
  - `wait_for_hosted_reconcile` `:422-501`, `run_post_merge_reconcile` `:523-570`, `commit_and_push_phase5_writes` `:584-620`;
  - `_await_mergeable` `:790-805`, the post-B1 re-gate `:961-974`, `--reconcile-pr` in `main` `:1109-1115`.
- `skills/2-daily/merge-cleanup/scripts/scan_clones.py`: `run_git` `:86-110`, the fetch at `:437`.
- `skills/2-daily/merge-cleanup/SKILL.md:153`.
- Tests: `test/gh534_phase_c_tests.py` (`TestGh623Resilience`, `TestParityGuard`) and `test/gh674-merge-cleanup-hosted-lookup.sh`.
- Incident evidence: #849 comments 5852638878 and 5857312850; #851; #852 and its two comments.

**Specific questions.**
1. Is R3 right? Does `subprocess.run(timeout=…)` on macOS stop counting while the machine sleeps, so that no in-script bound can cap wall time? If so, is adding git's `http.lowSpeedLimit` / `http.lowSpeedTime` still worth it on top of `timeout`?
2. F1: is 3600 s right for the post-merge `push` at `:601`? That push runs the repo's pre-push hook, which can run a gate.
3. F2: is "re-query once after a non-zero `gh pr merge`" enough? Should it reuse the zero-exit path's six-poll loop (`:167-173`) instead of a single read?
4. F3: is refusing a not-yet-merged PR in `--reconcile-pr` the right fail-closed behaviour? Can any existing caller or suite depend on the old behaviour?
5. F4: can waiting for `headRefOid == pushed commit` be defeated? For example, a third party pushing to the branch in the window. Today `push_resolved_head` refuses when the remote head moved before the push.
6. Witnesses: are the stub-based red/green witnesses under `TESTS-RESULTS/` falsifiable enough? Or must a behaviour one of them shows be pinned by editing an existing test, because an existing test pins the old behaviour?

**Operating envelope.** This is a single-operator developer tool run from one laptop against one GitHub repo.
Grade against the stated requirements and commensurate complexity: a few surgical changes in an existing script.
Do not grade against multi-tenant or adversarial threat models, or ask for new infrastructure.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
