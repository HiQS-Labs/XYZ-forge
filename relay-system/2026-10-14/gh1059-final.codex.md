# RELAY · GH1059 published retirement final QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-14.
-->

NEXT: codex
STATUS: Open
ROUND: 2 / 3

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
6. **Commit only the relay file** (`relay(gh1059-published-retirement-final-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: _<fill in the repo-relative path(s) the turn reviews>_
- Reviewer: codex   ·   Producer: codex-producer
- Started: 2026-10-14
- Definition of Done: operator-approved acceptance in PROJECT/2-WORKING/GH-1059-PUBLISHED-CLONE-RETIREMENT.md; inspect the actual final diff and retained evidence.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log


### Attestation · relay-drive — 2026-10-14T23:39:22Z
task: RELAY-GH1059-FINAL-20261014
reviewer: codex
status: Approved
reviewed-head: e86e137107b85c0b895a13d1298431c3f1548af8
added-range: 8125+5114
added-sha256: 22d193c3dda4e9d8ba9c099d7dbbc5640ee4f4224556e0ee0898a902d2d13c7c
<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->

## Bounded final QA packet
Goal: operator explicitly wants task checkout retirement after branch+PR fully pushed to origin, without waiting for merge. Plan QA attested Approved in gh1059-plan.codex.md; accepted-start recorded before implementation. Review actual code and evidence at HEAD, not just prose. Changed owners: skills/2-daily/merge-cleanup/scripts/scan_clones.py and merge_cleanup.py; policy consumers skills/1-hourly/start-task/SKILL.md, skills/2-daily/merge-cleanup/SKILL.md, WORKTREE-SAFETY section7 and SOP section4. Canonical plan and TESTS-RESULTS/2026-10-14+GH-1059 carry receipts.
Envelope: a local developer CLI, same-repository canonical GitHub publication, exact task-owned path list. No broad scan/merge/primary tree or governance writer in new mode; native worktree deregistration modifies parent Git metadata. Normal merged-only paths unchanged. No new deletion utility, daemon, suite, registry or CI gate. Commensurate rigor: ground every Blocker/Should in concrete failing inputs and the requested contract, not speculative enterprise machinery.
Verification in separate full gate clone: existing GH436/GH534180 tests pass at c391afec; at final production60c1ad18,39 retained manual cases and three existing start-task suites pass. Actual Git ancestry/fetch, Trash and native worktree operations with stubbed GitHub metadata; not live retirement proof yet. Red controls cover admission removal, draft-guard removal and invalid0 CLI broad-route witness before60c fix. Manual fresh-inspection case changes PR draft status between scan/removal and preserves. Config/remotes/user/tree identity intact; known candidate fast-forwards are documented, not suite drift. Full final publication gate intentionally follows approval and remains pending.
Questions: (1) Does exact publication proof reach the existing removal consumer, preserving every local-only/active/dependent/unknown case, protected primary and explicit scope? (2) Is default behavior unchanged and malformed mode selection rejected before broad routing? (3) Do policy wording and runtime handoff agree, including outside-target invocation and unsupported-driver preservation? (4) Do retained verification/red controls substantiate acceptance without new suites? Review bounded relevant existing callers and report actual material problems.
Read-only review, only this thread writable. No git, test/validate/pytest or executable fixture runs. Narrow nonmutating probes only in .relay-scratch with bytecode disabled. APPEND at absolute EOF under exact parser-supported heading `### Reviewer (codex) · Round 1`, VERDICT: PASS/FAIL, nonempty Basis and swept file: yes/no. On PASS STATUS: Approved, NEXT: — and tick done RELAY-GH1059-FINAL-20261014. Do not claim final gate/PR creation/retirement already happened.

### Reviewer (codex) · Round 1

Ship the reviewed implementation through the remaining publication gate.

VERDICT: PASS
Basis: The bounded packet and canonical acceptance are supported by current source and retained focused/manual evidence. The targeted mode extends the existing provenance, inspection and teardown owners; no material defect was found. This approves the implementation review, not final gate completion, PR publication, hosted checks or live retirement.
swept file: yes

- [Pass] Publication proof reaches removal. `skills/2-daily/merge-cleanup/scripts/scan_clones.py:460` binds canonical origin to the live same-repository, non-draft OPEN/MERGED PR and integration base, validates branch/head and requires fetched-head equality. Ref admission at `:563` requires ancestry to that head; other refs retain landed proof and detached HEAD is included at `:546`. `inspect_checkout` forwards the opt-in at `:975`; `skills/2-daily/merge-cleanup/scripts/merge_cleanup.py:1265` carries it through fresh inspection to the existing remover. Session, dirty, failed-query, stash, unpublished-ref and dependent-worktree preservation still govern (`scan_clones.py:1027`, `:1062`).
- [Pass] Scope and default routing remain bounded. `merge_cleanup.py:1241` rejects relative/symlink/protected/overlapping/foreign-origin paths before removal. `:1316` recognizes even zero-valued mode selection and rejects invalid/missing scope and mixed workflows before broad routing. Normal scan/Phase 6 callers omit the opt-in (`scan_clones.py:1126`, `merge_cleanup.py:1515`). Fresh-record/safe-disposition checks, native worktree removal and Trash-only clone movement remain the writers (`merge_cleanup.py:754`, `:779`, `:803`).
- [Pass] Caller and policy agree. `skills/1-hourly/start-task/SKILL.md:288` requires retained/pushed evidence, ready publication, exact owned paths, release of only completed owned activity, execution outside retiring paths, a supporting driver and preservation on failure. Its command at `:307` selects the targeted mode. `skills/2-daily/merge-cleanup/SKILL.md:442`, `WORKTREE-SAFETY.md:298` and `SOP.md:233` adopt the same pre-merge exception, including native parent-metadata updates and unsupported-driver preservation.
- [Pass] Retained evidence supports this review stage. `TESTS-RESULTS/2026-10-14+GH-1059/focused/gh436-focused.log:1921` reports “Ran 180 tests in 280.922s”, followed by “OK”; `provenance.jsonl:1` attributes it to c391afec. `manual/executed-probe.md:1` identifies stubbed GitHub metadata and real isolated Git/Trash operations; `manual/gh1059-manual-output.log:228` reports “Manual cases: 39”. The input includes changed-publication preservation and admission/draft red controls (`manual/executed-probe.md:77`, `:96`); `manual/zero-pr-red-control.log:1` records “RED: invalid zero PR reached broad workflow”. Receipts at `provenance.jsonl:2` and `:4` attribute final manual/start-task checks to 60c1ad18. These are retained producer results, not reviewer reruns.
- [Unverified — needs clone run] The classified final gate remains pending by design (`PROJECT/2-WORKING/GH-1059-PUBLISHED-CLONE-RETIREMENT.md:61`). Live GitHub publication/retirement and final hosted results remain producer obligations. No Git command, suite, pytest, executable fixture or gate ran here.

Coverage: read both Python owners and all four named policy files in full, including pre-existing sections; reviewed the canonical plan, plan approval, retained probe input/results/logs/provenance and bounded existing callers. No additional material pre-existing defects were found in that sweep. No Blocker/Should findings remain. Read-only `diff -u` comparisons against the maintained primary copies exited 1 and showed the opt-in validator, optional argument propagation and early targeted dispatch. These were filesystem comparisons, not an independently established Git merge-base diff; full current source supplied the review authority.

Evidence limits: Verify-tier graph discovery used project `Users-noelsaw-Documents-GH-Repos-XYZ-forge`, generation `2026-10-13T06:40:42Z`, with complete relevant search pagination. Coverage reported no recorded gaps for the six named paths and changed start-task metadata, but describes the maintained primary rather than this seeded revision. The graph predates the new functions; the trace tool required unavailable approval, so current source supplied the call trace. Static query `rg -n 'classify_local_refs\(|inspect_checkout\(|refresh_for_teardown\(|teardown_checkout\(' skills/2-daily/merge-cleanup/scripts test/gh436-merge-cleanup.py test/gh534_phase_a_tests.py test/gh534_phase_c_tests.py` exited 0; decisive edges are `scan_clones.py:975`, `merge_cleanup.py:734`, `:1265`, `:1267`, `:1271`, `:1515` and `:1541`. Coverage is best-effort, not a repository-wide completeness claim.

Relay closed (Approved), no further review turn needed. Handing completion back to codex-producer for the final classified gate, publication and narrowly scoped retirement or exact preservation report. Merge/deployment remain outside this approval.

### Producer · Round 2 — concrete input correction
Original final review approved e86e1371 (attestation8eb6f70c). A subsequent sentinel probe observed `--primary ""` inferring current directory and reaching targeted retirement. No removal occurred. The published-mode condition now requires an explicit absolute primary path and names it in the refusal message; ordinary modes are unchanged. Start-task/merge-cleanup wording states the absolute-path requirement. All core publication/ref/freshness/removal logic is unchanged.

Fresh full verify clone at6a71397b:41 manual cases pass, including empty/relative primary rejection and all earlier39 cases/red controls. Evidence is under manual/primary-scope with committed provenance. The initial8eb full gate was stopped, not passed, when this concrete gap was observed; only own gate processes were stopped, and clone identity stayed intact. A fresh full gate follows this corrected approval.

This is cumulative final round2/3, not a cap reset. Current token: RELAY-GH1059-FINAL-R2-20261014; prior token is terminal, do not touch it. Read prior full approval and the small e86e1371-to-current delta in merge_cleanup.py argument dispatch, two policy clarifications and current41-case input/output; grade explicit-primary identity, unchanged defaults and retained verification. No new machinery/test request. APPEND at absolute EOF with `### Reviewer (codex) · Round 2`, VERDICT: PASS/FAIL, nonempty Basis and swept file yes/no. On PASS set STATUS: Approved, NEXT: — and done current R2 token. Read-only, thread only; no git/tests/fixtures, permitted nonmutating scratch probes only.
