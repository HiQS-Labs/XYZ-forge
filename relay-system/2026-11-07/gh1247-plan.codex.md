# RELAY · GH-1247 GH-1362 shared plan QA; GH-1359 research only
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-11-07.
-->

NEXT: Producer
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
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
   Reviewer headings may be `### Reviewer · Round N`, `### Round N · Reviewer · <agent>`, `### Reviewer (<agent>)` (optionally followed by `— rN`), or `### Reviewer — Round N` (optionally followed by `(<agent>)`); follow the heading with a non-empty review body.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(gh-1247-gh-1362-shared-plan-qa-gh-1359-research-only): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **.relay-artifacts/GH-1247-RETIRE-REMOTE-TAGS.md** — the read-only path that
  `relay-drive.sh --artifact-file PROJECT/1-INBOX/GH-1247-RETIRE-REMOTE-TAGS.md` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: codex   ·   Producer: producer
- Started: 2026-11-07
- Definition of Done: _<fill in the acceptance criteria the Reviewer grades against>_

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer · Round 1

VERDICT: PASS
Basis: Approve the bounded implementation plan against its stated goal and acceptance list (artifact lines 26–28, 136–140). This approves planning, not runtime behavior or checkout deletion. Whole artifact swept; no additional blocking pre-existing plan defects found.
swept file: yes

- [Pass] Tag handling is sufficiently precise: artifact line 130 requires exact full ref names and unpeeled object IDs **before ancestry**, with missing/different tags preserved even when their targets are reachable. This covers annotated-tag identity rather than only peeled commits. The current ancestry-first loop is visible in `skills/2-daily/merge-cleanup/scripts/scan_clones.py:611`; the plan expressly replaces that ordering for tags without changing branch/detached rules.
- [Pass] Trusted lookup extends the existing owner rather than importing caller-tree discovery: artifact lines 124 and 131 name `_tick_binary`, explicit configuration, canonical Forge origin and executable validation, while retaining override behavior. The configuration paths exist in `skills/1-hourly/relay-xyz/find-harness.sh:122–125`. Existing claim inspection pins TICK_REPO_ROOT and fails closed (`scan_clones.py:305–329`); the disposition consumer preserves unknown claims (`scan_clones.py:1091–1099`). No new resolver framework is needed.
- [Pass] Safety and verification are scoped adequately for a plan: artifact lines 126 and 133 require stopping on false-safe controls before deployment, no user-checkout disposal during verification, existing-suite/manual red-green checks in a separate full clone, and retained provenance. Artifact lines 132 and 134 explicitly limit #1359 to research and keep it open; implementation does not claim to solve the broader lifecycle.
- [Nit] Historical capture text is stale beside the shared plan: artifact lines 33–35 say no Status table exists, lines 70–75 name `checkout_ref_provenance` as unconfirmed, while lines 102–122 supply the table and updated recon. On promotion, label the old material historical or reconcile it with the shared plan. This does not invalidate the ordered implementation.
- [Unverified — needs clone run] Base reproductions and runtime acceptance remain producer claims, not independently executed here. No validate.sh, test/*.sh, pytest, executable fixtures, or git commands were run. Carry the required clone evidence into final QA; plan approval is not an attestation that those checks passed.
- [Unverified — source access] Full live #1359/#1362 requirement comparison was unavailable. Read-only commands `gh issue view 1362 --repo HiQS-Labs/XYZ-forge --json body` and the equivalent for 1359 each exited 1: "error connecting to api.github.com". Review used the seeded artifact and local issue captures; recheck the live issue bodies before final QA. Graph discovery was attempted with search_graph and denied by the runtime ("approval policy is never"); direct reads were used. No claim of live issue completeness or PRS persistence is made.

Relay closed (Approved), no further turn needed. Producer may proceed with the scoped implementation and disposable-clone verification; the harness owns the relay-file commit.


### Attestation · relay-drive — 2026-11-07T23:51:13Z
task: RELAY-gh1247-plan
reviewer: codex
status: Approved
reviewed-head: 954c3c61a417d26e13c6cf7165db0347d3d99bae
added-range: 5869+3226
added-sha256: a9a0f437ce2636031091e19814a7db9dd6944d0784430e55e0bdca08681167ac
<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
