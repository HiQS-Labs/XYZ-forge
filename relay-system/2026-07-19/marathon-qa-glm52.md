# RELAY · Marathon 2026-07-19 QA — GLM 5.2 reviews the 5 highest-risk lanes
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-07-19.
-->

NEXT: Producer
STATUS: Approved
ROUND: 3 / 4

## ▶ TAKE YOUR TURN — read this first (works for ANY agent: Claude, Codex, agy)
1. **Read this whole file** (header, Setup, Ground rules, every block in the Log).
2. **Check it's your turn:** `NEXT` (top) names the role to act. Confirm you are bound to it and the
   last Log block isn't already yours. If not → STOP and reply "wrong window — nudge the <other> window."
3. **Do your role's work** on the artifact named in Setup:
   - **Reviewer:** review vs the Definition of Done → graded findings
     (`[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`), each with a concrete fix → set a **Verdict**
     (Approved | Changes requested | Blocked). Any `[Pass]` or "verified"/"confirmed" finding MUST
     carry a quoted span or a `file:line` citation — an uncited one is mechanically downgraded to
     `[Unverified — no citation]` (GH-173 B3). Do **not** edit the artifact; only append findings here.
   - **Producer:** log a disposition for every open finding (Implemented / Modified / Declined + why),
     make the change, then add new work.
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(marathon-qa-glm52): <role> r<N>`); no push. **Stop** and report one line.

## Setup
- Artifact under review: **.relay-artifacts/marathon-qa-glm52-brief.md** — the read-only path that
  `relay-drive.sh --artifact-file relay-system/2026-07-19/marathon-qa-glm52-brief.md` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: glm   ·   Producer: claude-a
- Started: 2026-07-19
- Definition of Done: each of the 5 highest-risk marathon lanes (GH-245, GH-236, GH-249, GH-232, GH-224) is correct, backward-compatible, edge-safe, and does not regress the harness; every finding carries a `file:line` citation.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Round 1 · Reviewer · glm (GLM 5.2 via OpenRouter/aider)

> Recovered verbatim from the aider transcript: aider produced this full review but its file append
> did not persist through worktree containment (it auto-added off-allowlist repo files and lost focus),
> so `relay-drive --review-once` correctly scored the unchanged relay file as a stall (exit 3) — a live
> confirmation of the GH-245 evidence-based classifier under review here. Transcribed by claude-a.

**Verdict: Approved**

Reviewed the 5 highest-risk/impact changes against the supplied source files and QA brief.

**GH-236 — relocate isolation worktree off `$TMPDIR`**
- [Pass] The `pwd -P` symlink resolution and prefix match (`"$_tmp_abs" == "$_root_abs"/*`) correctly detect when `$TMPDIR` resolves inside `RTL_ROOT`. Fallback to `$TMPDIR` on `git rev-parse` or `mkdir` failure preserves backward-compat. `relay-turn-lib.sh:440-448`.
- [Nit] `rtl_worktree_end` does not explicitly `rmdir` the `$_gcd/rtl-worktrees` dir if it becomes empty, leaving a stray empty dir under `.git/`. Harmless but untidy.

**GH-245 — `--target-root` review guard + evidence-based review-once classifier**
- [Pass] The startup guard (`relay-drive.sh:253-260`) correctly refuses a `--review-once --target-root` run when the relay file resolves outside the target root, preventing a wasted turn. Scoped to `REVIEW_ONCE` only.
- [Pass] The evidence-based oracle (`relay-drive.sh:543-552`) correctly classifies on relay-file content signature, NEXT pointer, and STATUS changes, dropping the misleading token-state signal. This fixes both Run A (token-only move → stall) and Run B (append with token left claimed → success). Fallbacks for `relay_content_sig` are safe.

**GH-249 — opt-in `--requires-test` gate in marathon-drive.sh**
- [Pass] `requires_test_delta()` (`marathon-drive.sh:309-326`) correctly checks for a non-empty file and a committed diff or untracked status since `PRE_PHASE_HEAD`. The gate is strictly opt-in (`REQUIRES_TEST` defaults empty) and additive, so backward-compat is preserved.

**GH-232 — ubuntu CI env prep + re-enable validate.sh minus 12 tests**
- [Pass] The CI step (`.github/workflows/ci.yml:87-137`) correctly prepares git config for ubuntu and runs the suite minus 12 explicitly named environmental failures. The skip list is well-documented with per-test reasons.

**GH-224 — PDDA drift reconcile (46 files) + outward action**
- [Pass] The `ROADMAP.md` diff correctly flips stale status markers (🆕 → ✅) for GH-230, GH-187, and GH-118.
- [Should] The brief notes the subagent closed GH #211 and #163 on GitHub. While likely benign if the issues were resolved by the shipped code, closing issues is an outward action that may be out of scope for a strictly doc-hygiene lane. Recommend confirming the lane contract permitted this.

### Round 2 · Producer · claude-a

Disposition of round-1 findings:

- **GH-236 [Nit] (empty `.git/rtl-worktrees` dir):** Acknowledged, **deferred as a tracked follow-up** — not implemented now. The dir lives under `.git/` (git ignores it), git's own `worktree prune` already runs in `rtl_worktree_end`, and re-touching the kernel `relay-turn-lib.sh` would force a full re-gate of an already-green marathon for a cosmetic gain. Good catch; logged for the next kernel pass.
- **GH-245 [Pass] ×2:** No action. Noted that this exact classifier is what scored *your own* round-1 turn as a stall — the fix demonstrably works on a live false-positive.
- **GH-249 / GH-232 [Pass]:** No action.
- **GH-224 [Should] (outward GitHub closures):** **Confirmed in-scope, with a caveat surfaced to the operator.** The lane's contract (`GH-224` capture doc) scoped `artifacts` to `ROADMAP.md` + `PROJECT/3-COMPLETED` and its remediation source was issue #224 (reconcile ledger/issue-state drift). Closing #211/#163 followed from that mandate — both were verified shipped from evidence in their own issue bodies before closing, and issue-state reconciliation is the lane's stated purpose. It **is** an outward action beyond a pure file edit, so it was explicitly flagged in the marathon report for operator visibility. Disposition: **kept**, flagged, not reverted.

No open blockers remain. Handing back for a confirming re-review.

### Round 3 · Reviewer · glm (GLM 5.2 via OpenRouter/aider)

> Recovered verbatim from the aider transcript (same non-persisting-append behaviour as round 1;
> `relay-drive --review-once` again correctly scored the unchanged file a stall). Transcribed by claude-a.

**Verdict: Approved**

Producer's dispositions are sound. The deferral of the GH-236 [Nit] is acceptable given the containment
constraints and the cosmetic nature of the issue. The clarification on GH-224 [Should] confirms the
outward action was intentional and flagged. No further changes requested.

**Relay closed — Approved by glm after 3 turns.**

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
