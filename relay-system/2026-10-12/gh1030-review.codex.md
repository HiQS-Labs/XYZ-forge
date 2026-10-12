# RELAY · GH1030 merged-risk review and GH1019 policy review
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-12.
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
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns.
   Reviewer headings may be `### Reviewer · Round N`, `### Round N · Reviewer · <agent>`, `### Reviewer (<agent>)` (optionally followed by `— rN`), or `### Reviewer — Round N` (optionally followed by `(<agent>)`); follow the heading with a non-empty review body.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(gh1030-merged-risk-review-and-gh1019-policy-review): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **.relay-artifacts/merge_cleanup_candidate.py** — the read-only path that
  `relay-drive.sh --artifact-file temp/gh1030/merge_cleanup_candidate.py` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: codex   ·   Producer: operator-review
- Started: 2026-10-12
- Definition of Done: Independent code review, no implementation or test runs. Explicitly separate code behavior from test evidence (the full gate is running elsewhere). Only modify this relay file, no other writes, commits or pushes. Do not merge any PR.

Operational envelope: Post-merge regression review of development d09b8f9d and policy code proposed by PR1019 74b871f4. Read-only source review. No new features, suites or gates. The candidate merge_cleanup.py is seeded under .relay-artifacts/merge_cleanup_candidate.py. Review relevant callers in the existing cleanup orchestrator as well as the proposed policy.

Questions:
1. Read relay-automation/relay-turn-lib.sh relevant scratch and worktree functions in full, and git diff 53e40d6c^ 53e40d6c for these paths. Are nested/hyphen scratch files confined to the intended worktree copyback and root behavior?
2. Read utils/py/harness_paths.py and the lane_attempt_gate function plus both call sites in utils/py/marathon_drive.py. Does vendored .xyz precede XYZ_HARNESS; does check_only prevent capped relay commits and duplicate fire records?
3. Read the embedded progress observer and integration in relay-automation/marathon.sh. Is there a second executor or a concrete regression? Check symlink identity fix 45afc936 and missing/mismatched receipt handling. Do not treat synthetic metadata as actual approval.
4. Read merged slug identity changes in utils/py/releases_app.py and relay-automation/xyz-releases-onboard.sh. Can foreign owner/repo rows be admitted by the new normalization? Inspect prior_art_recon.py bounded fallback and addon app.js/preview.py for concrete regressions.
5. Confirm validate.sh gh492-idle-kill removal and test/gh306-registry-bidirectional.sh exemption, and review gh609 assertions relevant to already-merged governance.
6. Review the entire candidate merge_cleanup.py and compare with current file: default opt-out, target-owned policy, strategy rejection, capability failure behavior, cleanup, ledger side effects. Can it rewrite shared history without an explicit request? Note the tracked Forge opt-in .merge-cleanup.json in PR1019. Its current conflict in CHANGELOG.md/releases.db/releases.sql is a known landing blocker, not a runtime-code finding.

Output: concise graded findings with file:line, literal swept file: yes/no for each area, Observed input/Affected scope/Falsifier for change requests. Do not invent failures or demand new tests. If no concrete code findings, say so and Approve source review only; no merge readiness claim. If findings remain, hand back. Only update this relay, and let the driver own its commit.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
