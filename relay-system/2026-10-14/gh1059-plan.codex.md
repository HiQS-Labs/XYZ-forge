# RELAY · GH1059 published retirement plan QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-14.
-->

NEXT: —
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
6. **Commit only the relay file** (`relay(gh1059-published-retirement-plan-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **.relay-artifacts/GH-1059-PUBLISHED-CLONE-RETIREMENT.md** — the read-only path that
  `relay-drive.sh --artifact-file PROJECT/2-WORKING/GH-1059-PUBLISHED-CLONE-RETIREMENT.md` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: codex   ·   Producer: codex-producer
- Started: 2026-10-14
- Definition of Done: _<fill in the acceptance criteria the Reviewer grades against>_

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->

## Bounded plan QA packet
Operator explicitly authorizes retirement after branch+PR fully published to origin, before merge. Authoritative plan: PROJECT/2-WORKING/GH-1059-PUBLISHED-CLONE-RETIREMENT.md. Read it and relevant source: scan_clones.py classify_local_refs/inspect_checkout; merge_cleanup.py main/refresh_for_teardown/teardown_checkout under skills/2-daily/merge-cleanup/scripts; start-task Step9; WORKTREE-SAFETY section7; SOP section4.
Operational envelope: local developer checkout closeout, same canonical GitHub repo, no daemon/new remover/new suite/new gate. Scope is this task's explicit paths; normal merged-only cleanup unchanged. No speculative enterprise threat model, lock framework or broad audit. Reuse existing safety paths; review concrete requirements and commensurate complexity.
Questions: (1) Does the proposed exact PR/origin/head proof suffice to retire only remote-recoverable refs without widening ordinary cleanup? (2) Does the targeted mode preserve local-only/active/dependent/unknown state, and avoid primary writes and accidental broad merges? (3) Is source+consumer handoff complete, including invocation outside target and unavailable older driver? (4) Are verification cases/red controls grounded and sufficient without new suites? Reject speculative machinery.
Read-only review, only this thread writable. No git commands or test/validate/pytest/fixtures; any nonmutating probes only in .relay-scratch with bytecode disabled. APPEND review at absolute EOF with exact parser-supported heading `### Reviewer (codex) · Round 1`, VERDICT: PASS/FAIL and nonempty Basis, swept file: yes/no. Cite actionable concrete findings. On PASS STATUS: Approved, NEXT: — and tick done RELAY-GH1059-PLAN-20261014.

### Reviewer (codex) · Round 1

Ship the plan for implementation.

VERDICT: PASS
Basis: Graded against the bounded packet questions and artifact acceptance list; Setup still contains a placeholder DoD. The existing inspection/removal owners can carry this opt-in policy without broadening ordinary cleanup. This approves the plan, not an implemented or runtime-verified remover.
swept file: yes

- [Pass] Publication proof is bounded: `.relay-artifacts/GH-1059-PUBLISHED-CLONE-RETIREMENT.md:57` requires live canonical-origin PR identity, matching base, non-draft OPEN/MERGED same-repository state, exact fetched branch/head equality, and ancestry for admitted local refs/HEAD. Other refs retain existing landed proof; default behavior remains unchanged. This extends the actual provenance owner (`skills/2-daily/merge-cleanup/scripts/scan_clones.py:460`, detached HEAD at `:494`).
- [Pass] Safety reaches the removal consumer: artifact `:51` threads proof through classification, eligibility and fresh inspection; `:58` dispatches exact-path mode before broad scan/merge/primary writers, rejects mixed modes and protected paths, defaults to preview and returns nonzero for refusal. Existing dirty/query/stash/ref/dependent preservation is in `scan_clones.py:999`; fresh inspection and safe-disposition-only removal are in `skills/2-daily/merge-cleanup/scripts/merge_cleanup.py:724` and `:752`. Native worktree removal (`:777`) and Trash-only clone removal (`:804`) remain the writers. The packet's “no primary writes” means no primary landing, working-tree or governance writes; native worktree deregistration necessarily updates its parent Git metadata.
- [Pass] Consumer/rollout coverage is sufficient: artifact `:59` updates authorization, recital and Step 9, invokes from outside retiring paths, retains evidence first, releases only owned completed activity, and preserves peer/local-only evidence. Artifact `:51` and `:59` require a supporting driver revision and prohibit manual deletion fallback. These address the current retain-until-requested handoff in `skills/1-hourly/start-task/SKILL.md:284` and recital at `:50`. IDE refresh and unrelated inventories are explicitly outside scope (artifact `:53`).
- [Pass] Verification is commensurate and falsifiable: artifact `:60` names existing GH436/GH534/start-task coverage, targeted manual success/preservation cases, admission-removal and publication-guard-removal red controls, disposable full-clone isolation, and retained commands/inputs/outputs/provenance under `TESTS-RESULTS/2026-10-14+GH-1059/`. Artifact `:61` requires independent final QA and the classified final gate before PR publication, without authorizing merge/deployment. No new suite or gate is proposed.
- [Unverified — needs clone run] The proposed mode does not exist yet; publication/ref failures, automatic closeout and red controls remain implementation obligations. No git command, test suite, pytest, executable fixture or gate was run in this reviewer worktree.

Evidence limits: Verify-tier discovery used graph project `Users-noelsaw-Documents-GH-Repos-XYZ-forge`, generation `2026-10-13T06:40:42Z`. Coverage reported matching metadata/no recorded gap for the source owners and cleanup policies, changed start-task metadata, and no indexed seeded artifact. The artifact and start-task were read in full; relevant source was read directly. Graph trace calls were denied by the tool approval layer, so direct source supplied the bounded call trace. Static query `rg -n 'refresh_for_teardown\(|teardown_checkout\(|classify_local_refs\(' skills/2-daily/merge-cleanup/scripts test/gh534_phase_a_tests.py test/gh534_phase_c_tests.py` exited 0; decisive output: `scan_clones.py:915: prov = classify_local_refs(...)`, `merge_cleanup.py:1459: fresh = refresh_for_teardown(...)`, `merge_cleanup.py:1485: ok = teardown_checkout(...)`. The direct source at `merge_cleanup.py:733` calls `inspect_checkout`. Coverage is best-effort, not an exhaustive audit.

No additional defects were found in the full seeded plan, including its pre-existing sections, or the bounded source seams reviewed. No Blocker/Should findings remain.

Relay closed (Approved), no further turn needed. Producer may implement the approved plan and retain the required final verification receipts.
