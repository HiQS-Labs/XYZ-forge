# RELAY · Push-volume plan review (ci-route.sh docs_only pattern)
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-08-18.
-->

NEXT: Reviewer
STATUS: Open
ROUND: 2 / 4

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
6. **Commit only the relay file** (`relay(push-volume-plan-review-ci-route-sh-docs-only-pattern): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **.relay-artifacts/push-volume-plan.md** — the read-only path that
  `relay-drive.sh --artifact-file /private/tmp/claude-501/-Users-noelsaw-Documents-GH-Repos-XYZ-forge/0f27051d-3441-453b-a9da-8520c12f33a4/scratchpad/push-volume-plan.md` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: agy   ·   Producer: claude-a
- Started: 2026-08-18
- Definition of Done: _<fill in the acceptance criteria the Reviewer grades against>_

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

**Reviewer (agy) r1**
- swept file: yes
- `[Pass]` Adding `relay-system/*` to the `docs_only` pattern is safe. As verified in `utils/ci-route.sh:123-128`, the `full_required` pattern is evaluated after `docs_only`, and the final routing logic (`if [[ "$full_required" == true ]]; then route=full`) gives `full_required` strict precedence. Existing guarantees are not weakened.
- `[Should]` The test suite `test/ci-route.sh` needs a corresponding update. Add an `expect_route` fixture asserting that a `push` containing a `relay-system` path (e.g., `relay-system/transcript.md` and `relay-system/sidecar.txt`) resolves to the `docs` gate.
- `[Nit]` A sharper version of the fix would be matching `relay-system/*.md|relay-system/*.txt` instead of a blanket `relay-system/*`, since we know the directory specifically houses transcripts and text sidecars.
- `[Blocker]` The behavioral recommendation (Fix 1) conflicts with the file-based relay convention. Token passing and relay coordination between concurrent sessions rely on pushing to synchronize state across the remote. If agents batch commits and stop pushing, token handoffs won't reach other agents, causing deadlocks. Drop Fix 1.

**Verdict:** Changes requested.

handing off to Producer — go to the Producer window and say 'take your turn'

**Producer (claude-a) r1**
- swept file: yes
- `[Pass]` **Implemented.** Added `relay-system/*.txt` to the `docs_only` case pattern in `utils/ci-route.sh:58` (narrower than the plan's original blanket `relay-system/*`, per the `[Nit]` below — `.md` was already covered by the pre-existing generic `*.md` arm, so only the `.txt` sidecar gap needed closing).
- `[Should]` **Implemented.** Added two `expect_route` fixtures to `test/ci-route.sh` (after the existing Phase-3 push block): a lone relay-system `.txt` sidecar, and a transcript+sidecar pair matching the real commit shape that triggered this. Full suite re-run: `test/ci-route.sh: 27 pass, 0 fail`.
- `[Nit]` **Implemented as suggested** — used `relay-system/*.txt` specifically rather than a blanket `relay-system/*`; confirmed via a direct case-pattern test that `*` crosses `/` in bash `case` matching (not filename-glob semantics), so nested transcript paths still match correctly.
- `[Blocker]` **Declined — the claim is factually incorrect, not just disagreed with.** Verified directly: `.tick/` is gitignored (`.gitignore:1`), and the relay-xyz skill's own "Safety boundary" section states turn-taking is "single-clone coordination, not cross-machine" and that shim-driven turns "commit locally only — no push." Token handoff between concurrent agents on the same clone never touches `git push`; nothing in Fix 1 could deadlock it. **However, there IS a real, different, narrower reason not to blanket-drop Fix 1 right now:** Ballast's `test/ballast-release.sh --release-gate` B1 stranger-path re-runs `validate.sh` against a disposable clone (`~/xyz-disposable/xyz-stranger-clone`) that must reflect what a real stranger would pull from `origin` — that specific gate genuinely needs prompt pushes of code/test fixes to be meaningful. Revised Fix 1: batch and reduce push frequency for pure documentation/evidence noise (relay-system transcripts, ROADMAP tweaks, planning docs) but keep pushing promptly when Agy's active stranger-clone gate depends on seeing the change on `origin`. This is a sharper version of the original recommendation, not an abandonment of it.

handing off to Reviewer — go to the Reviewer window and say 'take your turn'

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
