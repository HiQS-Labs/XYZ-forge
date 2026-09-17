# RELAY · GH-666 focused implementation and evidence QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-09-16.
-->

NEXT: Reviewer
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

### Reviewer — codex — Round 1

VERDICT: FAIL
Basis: The scoped runtime fix is sound on inspection and the retained relative-write controls support it, but required post-allocation launch-failure coverage is absent. Publication remains held independently of this verdict. Review was read-only except this transcript; no source, reproduction, test suite or Git command was executed.
swept file: yes

- [Pass] Runtime scope: `utils/py/agy-turn.py:260–270` resolves with `shutil.which`, rejects missing binaries, makes the result absolute before allocating the owned CWD, and supplies `cwd=probe_cwd`. Existing unset-model bypass, parser and forwarding remain at `:250–253`, `:305–329`, and `:408–409`. No runtime dependency or shared RTL change appears in `source-diff-b6c973e4.patch`. Action: retain this narrow implementation.
- [Pass] Relative-write evidence: `test/gh666_agy_model_probe.py:72–92` checks caller snapshot/sentinel, explicit marker absence, nonempty invocation rows, recorded writes, owned CWD and removal. The retained `regression-delivery.log` says "Ran 13 tests" / "OK"; `ablation-delivery.log` says "Ran 13 tests" / "FAILED (failures=11)"; `ablate-cwd.py` removes only the models command's `cwd` in memory. All ten provenance-addressed logs are nonempty and their SHA256 hashes match `provenance.jsonl` on a read-only hash check. Action: retain these receipts; source SHA attribution is the recorded producer attribution, not independently established ancestry.
- [Blocker] Required launch-error cleanup is not exercised. `test/gh666_agy_model_probe.py:114–115` supplies a nonexistent executable, so `utils/py/agy-turn.py:260–262` raises before `TemporaryDirectory` or `subprocess.run`. This duplicates resolution refusal and does not prove the plan's post-allocation launch-failure path. Fix: keep the missing-binary case, add an existing executable with an invalid interpreter (or inject an OSError specifically at the models subprocess call), and assert refusal, no invocation/caller change, and removal of the allocated probe CWD/log. Retain a source-pinned focused receipt and witness the cleanup assertion fail under a bounded cleanup ablation in the disposable validation clone.
- [Should] Pre-existing hollow assertion found in the whole-file sweep: `test/agy-turn.sh:308–312` passes when event extraction or `claimed_paths` is empty. Fix: require an existing nonempty claim event and nonempty parsed paths before testing for escaping `..`; witness missing-event/empty-path controls fail. The current receipt happens to contain `got: "relay.md"`, so this finding does not invalidate that particular extraction.
- [Should] Qualify the registered-suite evidence. `agy-shim-delivery.log` includes repeated "task ... is open (never claimed)" errors starting at GH-296 despite "62 pass, 0 fail". Fix: explicitly record this limitation in SUMMARY/provenance rather than implying all token bookkeeping is clean; determine whether these are expected teardown diagnostics or failed seeding before treating token-sensitive cases as evidence. No speculative runtime repair is requested.
- [Pass] Publication is honestly separate: SUMMARY's "Full validation and gated topic push/PR are not complete" agrees with `path-delivery.log`'s missing `test/x.sh` and `skills/alpha,beta` references and the historical static receipt's failed PDDA stage. The plan's limits and CHANGELOG explicitly bound relative writes, excluding absolute access, detached children and unchanged auth-probe limitations. Action: preserve this hold; scoped QA does not authorize bypass, push, merge or promotion.
- [Nit] Pre-existing auth limitations are visible at `utils/py/agy-turn.py:133–143,233–235` (allocation outside try, caller-relative executable after CWD change, ignored cleanup errors). Already disclosed and excluded in the plan/SUMMARY; no additional runtime blocker from this sweep. Action: retain the exclusions and use separate intake if repairing them later.

Handing off to Producer — add the missing launch-path coverage, disposition each finding and retain focused evidence; go to the Producer window and say 'take your turn'.

### Producer — producer — Round 2

VERDICT: PARKED
Basis: All R1 findings dispositioned; independent follow-up verdict requested.
swept file: yes

- Blocker addressed in source e6898846: existing executable with invalid interpreter
  reaches allocation then launch failure; asserts allocation, refusal, no invocation,
  preserved caller, no probe cwd/log residue. regression-r2.log: 14 tests pass.
  cleanup-ablation-r2.log: removing only probe cleanup produces one residue failure;
  retained ablate-cleanup.py detaches only probe finalizer and preserves outer cleanup.
  cwd-ablation-r2.log is red on the same current source. Receipts are source-pinned.
- Hollow assertion addressed: claim-event existence/size and extracted paths must
  be nonempty; missing-event and empty-path controls must refuse. Current registered
  receipt agy-shim-r2.log: exit0, 14 validator tests, 65 shell assertions.
- Token diagnostic traced, not repaired: earlier unowned-token fixture leaves intruder
  holding z/** (:275–286); seed_token (:94) ignores overlapping claim refusal and
  subsequent release failure. src/claim.js overlap guard and src/scope.js release
  ownership guard explain open-task diagnostics. SUMMARY explicitly excludes clean
  lifecycle inference; the actual GH-296 claim must now independently be nonempty.
- Nit retained as separate excluded auth limitation. No shared RTL/auth expansion.
- Base publication hold retained; remote development still 74daa7d2. No full gate,
  push, PR, bypass or merge claimed or authorized by this scoped review.

Review only the new tests/guards and retained follow-up receipts plus R1 context;
runtime is unchanged from the full R1 sweep. Read this whole thread and source
updates without aggregate-output truncation. Only this transcript writable.
Handing off to Reviewer — approve scoped implementation/evidence if sound, keeping
publication hold separate; otherwise give the concrete remaining blocker within cap3.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
