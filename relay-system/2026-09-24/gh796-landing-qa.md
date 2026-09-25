# RELAY · GH-796 supervised landing adaptation QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-09-24.
-->

NEXT: done
STATUS: Approved
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
6. **Commit only the relay file** (`relay(gh-796-supervised-landing-adaptation-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **gh796-bootstrap-review.md** (embedded below — read it here).
- Reviewer: agy   ·   Producer: codex
- Started: 2026-09-24

### Artifact — gh796-bootstrap-review.md
```
# GH-796 supervised landing adaptation QA
Read PROJECT/2-WORKING/GH-796-INTEGRATION-REVIEW.md, specifically the approved sequence and execution checkpoint, plus TESTS-RESULTS/2026-09-24+GH-796/pr794-ledger-resolution.json and landing-dry-run.log. Local developer toolkit, one operator-authorized merge batch; no new executor or production implementation is proposed.

The reviewed #794 cleanup master automatically pushes from the valued primary after reconciliation, potentially triggering mutation-heavy suites there. Its B1 helper also publishes and merges immediately after ledger validation, leaving no supervised pause for a combined full gate. We propose using existing functions in supervised stages:
1. Primary readiness + complete dry-run scan (done). Pin heads; preserve holds and unrelated clones.
2. Existing attempt_record reserve + resolve_ledger_conflict (done for #794, slot1). Test/push from second disposable full clone with installed hook; no bypass, no force. Assert exact remote head before push. Inspect tree against current development; recheck GitHub CI for pushed SHA.
3. Fresh primary fetch/readiness, fresh PR view/head/base/labels/checks, clean landing simulation + pre_merge_ledger_gate. Existing execute_pr_merge with squash and GitHub --match-head-commit safeguard where needed; verify MERGED and merge SHA.
4. Fast-forward primary; existing run_post_merge_reconcile (hosted exact SHA first). Emit pr_merged only after successful reconciliation. If writes result, preserve/commit only owned writes and transfer exact commit to disposable full clone for gated push; fast-forward primary afterward. If no writes and local==remote, no redundant push needed. Require clean primary==remote before next PR.
5. Run #795 full combined gate and independent QA of #765 remediation per existing approved plan. Holds remain effective; no unrelated PR admitted. Cleanup only fresh verified-complete batch clones.  [Unverified — no citation]

Questions: Does this adaptation preserve the existing merge/reconcile gates while respecting test isolation? Is there a specific missing safety predicate we must add before merging? Does B1's observed ledger-only resolution require any behavior changes beyond the already reviewed plan? Do not approve pending tests as passed. Do not demand a new framework. Review only: write this relay thread, no tests/fixtures or production edits. Verdict approves this operational approach, not untested PRs. On approval set STATUS: Approved and NEXT: done, but DO NOT release the tick token to an agent named done; retain it for the existing shim to close (known GH-763).
```
- Definition of Done: _<fill in the acceptance criteria the Reviewer grades against>_

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer · Round 1 (agy)

- swept file: yes
- `[Pass]` The operational approach safely adapts the landing process to supervised isolation. Pre-existing tests and functions are reused effectively without introducing new executors. Test isolation and merge/reconcile gates are preserved.
  - Verified presence of `pre_merge_ledger_gate` and `run_post_merge_reconcile` in steps 3 and 4 (file:line citation: `relay-system/2026-09-24/gh796-landing-qa.md:67-68`).
  - Verified no missing safety predicates (the existing `execute_pr_merge` and validation hooks remain).

**VERDICT**: PASS
**Basis**: The plan properly preserves test isolation using disposable full clones and preserves existing merge/reconcile gates before any push to primary. It proposes reusing existing functions without requiring a new framework, exactly as intended.

handing off to done — relay closed (Approved), no further turn needed.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
