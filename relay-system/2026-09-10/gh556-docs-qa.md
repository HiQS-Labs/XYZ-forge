# RELAY · GH-556 installer docs QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-09-10.
-->

NEXT: Producer
STATUS: Open
ROUND: 1 / 4

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
6. **Commit only the relay file** (`relay(gh556-docs-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: `skills/skills-army-hq/README.md` + `skills/skills-army-hq/references/recovery.md` (commit 35cc1bfc on feat/gh556-skills-docs; `git diff origin/development..HEAD -- skills/` shows the docs diff). Supporting: the live relocated collection at `~/git-pulse-sync/Deployed Skills` (read-only) and issue #556.
- Reviewer: agy   ·   Producer: claude-a
- Started: 2026-09-10
- Definition of Done: the two doc edits are accurate against the GH-536 reality, complete (no stale path references left), and scoped as docs-only.
- Review questions — adjudicate each with file:line or quoted span:
  1. README: does the updated primary-use-case paragraph correctly name the GH-536 home and point at the SKILL.md adoption runbook? Grep the whole skill folder for any remaining `Documents/Deployed Skills` references.
  2. recovery.md: is the exclusion list in the new subsection complete and consistent with what actually leaked during GH-536 (`.deploy-skills.lock`, `.staging/`, `__pycache__/*.pyc`) and with the live collection's `.gitignore` (read `~/git-pulse-sync/Deployed Skills/.gitignore`)?
  3. Is the commit-after-mutation rule stated with the correct failure mode (pre-write `pull --rebase` refusal, exit 128)?
  4. Is the digest mode-normalization rule technically accurate (git tracks only the executable bit)?
  5. Scope: confirm the branch diff is docs + ledger only — no behavioral changes smuggled in.
  6. Whole-file sweep (GH-268) of both edited files — declare `swept file: yes|no`.
  End with `VERDICT: PASS` or `VERDICT: FAIL` plus a non-empty `Basis:` line, and set `STATUS: Approved` if approving.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

<!-- GH-529 mitigation: no trailing marker — append at end of file -->

### Reviewer (agy) — Round 1

swept file: yes

* **[Pass] README GH-536 home:** The primary-use-case paragraph correctly names the new location and points to the runbook (`skills/skills-army-hq/README.md:22-26`: "The actual skill folders stay in one collection — since GH-536, `~/git-pulse-sync/Deployed Skills`, carried by the hourly Git Pulse writer (see SKILL.md → \"Adopting the collection on another machine\").").
* **[Blocker] Stale path references:** The whole-folder grep revealed 4 remaining stale `Documents/Deployed Skills` paths in `skills/skills-army-hq/README.md`.
  * Fix: Update paths on lines 42, 44, 64, and 79 to the new `~/git-pulse-sync/Deployed Skills` path to fully satisfy the "no stale path references left" DoD.
* **[Nit] recovery.md exclusion list completeness:** The list in `skills/skills-army-hq/references/recovery.md:50-53` is missing `.lock`, which is present in the live `.gitignore`.
  * Fix: Add `.lock` to the listed items in `recovery.md` to perfectly match the live file's contents.
* **[Pass] Commit-after-mutation rule:** Correctly stated with the proper failure mode (`skills/skills-army-hq/references/recovery.md:55-57`: "The carrier's pre-write `pull --rebase` refuses on uncommitted tracked changes, wedging its whole cycle (observed: exit 128...)").
* **[Pass] Digest mode-normalization rule:** Technically accurate (`skills/skills-army-hq/references/recovery.md:58-60`: "git normalizes file modes (only the executable bit survives)").
* **[Pass] Scope:** Branch diff contains only docs and ledgers (`README.md`, `recovery.md`, `ROADMAP-DASHBOARD.md`, `LEADERBOARD.md`, `releases.*`, `relay-system/`). No behavioral code changes were found.

VERDICT: FAIL
Basis: Remaining stale path references in README.md violate the Definition of Done.

Handing off to Producer — go to the claude-a window and say 'take your turn'.
