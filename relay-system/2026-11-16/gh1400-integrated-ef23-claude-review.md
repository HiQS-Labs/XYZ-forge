# RELAY · GH1400 integrated ef23 Claude review
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-11-16.
-->

NEXT: Reviewer
STATUS: Open
ROUND: 1 / 1

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
6. **Commit only the relay file** (`relay(gh1400-integrated-ef23-claude-review): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: the integrated GH-1400 supervisor candidate `ef23e77b24e51add4be9476191257bcbc7d7c432` (task delta vs `origin/development` `f346d8908a42`: `utils/py/jog_run.py`, `utils/py/releases_app.py`, `skills/2-daily/jog/SKILL.md`, `CHANGELOG.md`, `PROJECT/2-WORKING/GH-1400-SUPERVISION-COMPOSITION.md`, `decisions/2026-11-15-gh1400-bounded-jog-wake.md`, `releases.sql`), its upstream integration vs published PR head `0d1dc0fe8395` (notably `utils/py/swarm_preflight.py` and its Jog consumer seams), and the evidence-only commit `7a95a1d0c8c8` (`TESTS-RESULTS/2026-11-16+GH-1400/integration-ef23-review/`).
- Reviewer: claude   ·   Producer: claude-a
- Started: 2026-11-16
- Definition of Done: the integrated candidate preserves the approved task-local failure continuation (`relay-system/2026-11-16/gh1400-followup-final.claude.md`, attested PASS at `185db9741037`) with no new integration regression; shared-safety conditions still stop all dispatch; saved-approved-result adoption on restart happens exactly once and inconsistent or missing receipts hold; Jog's use of the upstream `swarm_preflight.py` changes still works; evidence and limits are stated honestly.

## Review packet

Read in this order:
1. `git diff f346d8908..ef23e77b2 -- utils/py/jog_run.py utils/py/releases_app.py skills/2-daily/jog/SKILL.md CHANGELOG.md releases.sql` (task delta on development).
2. `git diff 0d1dc0fe8..ef23e77b2 -- utils/py/swarm_preflight.py` and confirm `git diff 0d1dc0fe8..ef23e77b2 -- utils/py/jog_run.py utils/py/releases_app.py` is empty (Jog runtime blobs unchanged from the attested head). Then check Jog's preflight consumer seams against the new preflight (`--gh-issue`/`--out`, readiness exit handling, `marathon-invocation.json` publication).
3. `git show ef23e77b2` (plan outer-loop alignment only) and `git show 7a95a1d0c --stat` (reports only).
4. `relay-system/2026-11-16/gh1400-integrated-ef23-review-status.md` (the verification agent's bounded source assessment; it is NOT an independent approval, so do not inherit its conclusions — verify cited lines yourself).
5. `TESTS-RESULTS/2026-11-16+GH-1400/integration-ef23-review/SUMMARY.md`, `results.json`, `provenance.jsonl`, identity JSON, and the per-control logs (`restart-*`, `red-*`, `stop-*`, `local*`, `held.log`, `jog-adapter.log`).

Questions:
1. Classification: does `_jog_task_local_failure` and its use in `jog_run_main` still continue only on a task-local red gate, fail closed on every exception or non-matching field, and sit only on the supervised `failed` path after integration? Cite lines.
2. Shared safety: can any path skip the lock/ownership, deadline/max-tasks, target-alignment or checkpoint checks before the next dispatch? Cite lines.
3. Saved-result adoption: does `_jog_supervise_recover` → `jog_resume` → `publish_jog_receipt` adopt a saved approved result exactly once without a builder, keep budgets, and hold on missing/corrupt/mismatched receipts? Which `restart-*` log proves each?
4. Integration: does any upstream change (especially `swarm_preflight.py`) break or weaken a Jog seam, exit code or file contract? Cite both sides.
5. Evidence honesty: do the 23/23 controls and 227/227 suite logs match the claims, are identities unchanged, and are limits (shared environment fault indistinguishable from task-local red, one bounded attempt per later task, mid-wake checkpoint contradiction detected at finish, synthetic-only controls) stated truthfully?
6. Any scope creep, new suite/registry/gate, env leak, retry or duplicate writer in the task delta?

Pending, not a finding: the classified full gate runs once on the approved commit after this review. Grade it as pending.

Do not run suites or tests and do not modify source. Only this relay file is writable. Read-only git and file reads are allowed. Behaviour-change findings need `Observed input:`, `Affected scope:`, `Falsifier:`. Whole-file sweep of all touched files is not expected for `swarm_preflight.py`'s unrelated upstream refactor; declare `swept file:` honestly for what you read.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
