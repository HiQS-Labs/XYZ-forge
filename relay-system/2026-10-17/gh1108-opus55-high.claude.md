# RELAY · GH-1108 delivery1 QA — Claude Code Opus 5.5 high
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-17.
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
6. **Commit only the relay file** (`relay(gh1108-opus55-high): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: Complete delivery1 diff from b26c9edb73f61587a71287f68cb4338409188042 to 7d4ed1c5; whole touched runtime source `utils/py/jog_run.py`, `releases_app.py`, `harness_paths.py`, `gate_receipt.py`, merge-cleanup scripts `merge_cleanup.py` and `ledger_merge.py`; material existing callers; canonical `PROJECT/2-WORKING/GH-1108-JOG-LAND-RECEIPTS.md`; retained `TESTS-RESULTS/2026-10-17+GH-1108` evidence plus historical portable bundles.
- Reviewer: claude-opus-reviewer · Producer: codex-producer
- Definition of Done: Independent final QA using Claude Code Opus 5.5 high. Local operator CLI scope, commensurate complexity, surgical DRY. User requires two PRs: delivery1 one-writer guard/disposable execution/committed receipts/mechanical landing proof/mapped merge-cleanup hook; delivery2 exclusively direct transition publication and non-FF fresh-intent retry. Delivery1 manual primary commit/push checkpoint and common real auto-merge refusal are intentional interim policy, not missing delivery2. No merge authorized. No new suites/gates. Only this relay is writable; no production edits, Git commands, builders, pytest, validate.sh or test/*.sh in review worktree. Narrow read-only scratch probes allowed. Full gate is running separately; no result claimed. Historical re-land currently proved with disposable primary plus live GH data; actual machine primary recovery pending.

### Questions
1. Do all Jog write paths refuse outside pinned primary before DB writes, while real execution uses separate full clone and existing #1104/#1099 root helpers without writing lane releases files?
2. Are green result/gate bytes preserved and committed as portable evidence, with cache-independent land identity/hash/gate/reconcile checks and safe receipt publication/resume?
3. Does the approval tail proof reject changed/reverted source commits, allow six-path-only commits, and mechanically prove upstream merges using reachable second parent plus conflict-free identical stripped trees (ledger exclusions recorded)?
4. Does merge-cleanup call land only for mapped rows after hosted reconcile and reuse its final post-merge publication; does existing plain/old/vendored consumer behavior survive? Both real executor auto-merge paths now refuse interim unpublished state before lease, simulation/dry-run stay compatible.
5. Does retained red/green/manual and focused 223/34/180/8 evidence support claims within stated limits? Any concrete blocker/should, unnecessary layers or unexamined touched-file defects? Cite exact file:line, observed input, affected scope and falsifier. Do not ask for new suites.

Terminal token protocol: claim as instructed. On Approved, call tick done RELAY-gh1108-opus55-high --agent claude-opus-reviewer (with this checkout's TICK_REPO_ROOT), not release. On findings release to codex-producer. Never run Git: shim commits relay only.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
