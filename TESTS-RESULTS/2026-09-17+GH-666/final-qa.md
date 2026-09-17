# RELAY · GH-666 focused implementation and evidence QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-09-16.
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
   - **Producer:** log a disposition for every open finding (Implemented / Modified / Declined + why),
     make the change, then add new work.
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(gh-666-focused-implementation-and-evidence-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: committed GH-666 plan/recon, utils/py/agy-turn.py, test/agy-turn.sh, test/gh666_agy_model_probe.py and this retained evidence folder; supporting CHANGELOG entry and owned ledger intake diff.
- Reviewer: codex   ·   Producer: producer
- Started: 2026-09-16
- Definition of Done: narrow probe implementation preserves executable/model/error semantics, prevents relative caller writes and truthfully retains positive/negative receipts. Explicitly grade code/evidence separately from publication: base gates are red, full validation/push/PR not complete. Approval of this scoped implementation is NOT PR readiness or permission to bypass.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Producer — producer — Round 1

VERDICT: PARKED
Basis: Independent implementation/evidence review pending; publication is held.
swept file: yes

Operational envelope: local CLI, one inherited-relative-write probe gap. Surgical
stdlib fix, no sandbox/child-lifecycle/distributed machinery. Parent/base 74daa7d2;
final code/docs/ledger snapshot b6c973e4, later changes only TESTS-RESULTS evidence.
source-diff-b6c973e4.patch is actual base-to-snapshot diff excluding relay transcript
and binary DB; SQL owned intake included. Do not call producer ancestry independent.
Plan QA Approved with real attestation. No full gate/push/PR or promotion claim.

Read runtime/test source files in full using separate at-most-160-line reads through
EOF; the runtime was completely read in plan QA, so check current behavior plus
that grounded context. Supporting CHANGELOG: review the new GH-666 entry and its
claims, not an unrelated audit of thousands of historical entries; apply repo
skills/relay-xyz commensurate-review standard. The narrow code files, docs and
evidence are still fully in scope; cite pre-existing findings without speculative
scope expansion. No tests/programs/Git commands/source edits in valued clone.

Questions:
1. Does the actual validator resolve its binary before disposable cwd, refuse
   missing PATH binaries rather than falling back to caller files, and preserve
   model forms/results/forwarding with completed-path cleanup/refusal?
2. Do the real-validator tests/registered invocation expose caller writes including
   Git-ignored markers, preserve sentinel and Git identity/HEAD/tree, and prove
   no skipped invocation/empty evidence? Do baseline and cwd-ablation receipts
   support a load-bearing control rather than merely comparing the fix to itself?
3. Are runtime changes stdlib-only/bounded, the rating and ledger intake surgical,
   and limitations (absolute access, detached child lifetime, unchanged auth probe)
   honest? Verify retained log hashes and source attributions without inventing ancestry.
4. Does the evidence explicitly hold full-gate/PR readiness on unrelated base
   path and GH-658 coverage failures, without skipping/bypassing/publication claims?

Only this transcript writable. PASS on scoped implementation -> STATUS Approved,
tick DONE while owned; explicitly preserve publication hold. Otherwise give cited
concrete findings and hand back within cap3. Do not manufacture full-gate approval.
Handing off to Reviewer — give the focused cited code/evidence verdict.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
