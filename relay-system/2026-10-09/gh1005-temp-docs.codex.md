# RELAY · GH1005 documentation-only commit parking policy
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-09.
-->

NEXT: Producer
STATUS: Approved
ROUND: 1 / 2

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
6. **Commit only the relay file** (`relay(gh1005-documentation-only-commit-parking-policy): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: _<fill in the repo-relative path(s) the turn reviews>_
- Reviewer: codex   ·   Producer: express
- Started: 2026-10-09
- Definition of Done: _<fill in the acceptance criteria the Reviewer grades against>_

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Review scope

Review the full skills/2-daily/merge-cleanup/SKILL.md and its new caller-owned parking policy; independently inspect TESTS-RESULTS/2026-10-09+GH-1005/manual-controls.json and provenance, policy/ledger/changelog/capture diffs versus origin/development. Verify exact original transcript classification/publication, history-wide old/new blobs including rename/deletion, source-code revert and binary rejection, creation-only remote lease semantics, durable unchecked checklist, dirty/active/dependent preservation, and post-queue operator disposition. Python readiness/teardown behavior is unchanged and must stay strict; this policy is implemented by the driving agent, not a new automatic CLI feature. Check internal contradictions with the rest of the full skill and scope creep.
The manual receipt demonstrates one valid document accepted and five corrupt/non-document controls rejected in isolated fixtures; the source commits 062ae45f and 8b310626 change only marathon-system/p1/RELAY.md and their published refs match exact SHAs. Independently falsify at least one stated protection using read-only/in-memory artifact inspection; do not merely trust the supplied verdicts. Runtime/registry/test sources are unchanged.
Graph context: Verify tier canonical project Users-noelsaw-Documents-GH-Repos-XYZ-forge; last observed ready index covers express.py, merge_cleanup.py, gh436 suite and SKILL.md with no recorded gap. Task clone is a different checkout, so inspect its exact local artifacts and disclose any unavailable graph calls. Relevant express bounds are 4 core files/150 insertions; current registered covering suite is test/gh436-merge-cleanup.sh.
Review only; never run suites/pytest/fixtures or mutating DB/Git commands in the linked review worktree. Only edit this relay. Express gate and landing are still outstanding, so do not attest them or production checks. Return concrete findings or Approved with citations and truthful limits. Keep the review log concise (approximately 12-15 lines) without omitting material findings.

## Log

### Reviewer · Round 1 · codex
VERDICT: PASS
Basis: Approve the caller-owned documentation policy; no material defect or scope creep found in the full skill, including pre-existing sections. Reversibility: Easy (policy revert); publication grants no landing/deletion authority.
swept file: yes
- [Pass] skills/2-daily/merge-cleanup/SKILL.md:112 requires non-empty, history-wide inspection of both rename sides and old/new blobs, ordinary UTF-8 non-executable documents, semantic purpose, and rejection of reverted code/mixed history.
- [Pass] TESTS-RESULTS/2026-10-09+GH-1005/manual-controls.json:1 and provenance.jsonl:1: receipt/policy SHA256 values match current bytes; independent read-only object inspection admitted valid-doc and rejected binary-md, reverted-code, symlink-md, renamed-code and deleted-binary (command "python3 -B $TMPDIR/object_probe.py", exit 0; inspected blob IDs independently SHA1-checked).
- [Pass] Old-blob falsifier for SKILL.md:117: command "python3 -B -c 'from pathlib import Path; import zlib; p=Path(\"/Users/noelsaw/Documents/GH Repos/XYZ-forge-gh1005-temp-docs-2026-10-09/temp/documentation-controls/deleted-binary/.git/objects/85/371f28269e95b7ebc156df3ceb24b3285f3ead\"); d=zlib.decompress(p.read_bytes()).split(b\"\\0\",1)[1]; safe=lambda blobs: all(b\"\\0\" not in b for b in blobs); print(\"old+new admits:\",safe([d]),\"new-only mutant admits:\",safe([]),\"old bytes:\",len(d)); assert not safe([d]) and safe([])'"; exit 0; decisive output "old+new admits: False new-only mutant admits: True old bytes: 10".
- [Pass] Original commits 062ae45f01faf73bf78bcc10fcba86cd7d5c2ad7 and 8b310626e2d4d7095390dfb12ca7375990bbc720 independently change only marathon-system/p1/RELAY.md, mode 100644, cf6bcd55… → 4572ee56…; inspected blobs are relay text. GitHub fetch_commit on each named temp ref returned its exact respective SHA and that sole path (receipt: manual-controls.json:1).
- [Pass] SKILL.md:120 specifies creation-only absent-ref lease, identical-SHA reuse, publication verification and fail-closed continuation; SKILL.md:131 retains dirty/active/claim/dependent safeguards and reruns strict Phase 0 without reset or override.
- [Pass] SKILL.md:126 makes the unchecked checklist durable and resumable; inspected /Users/noelsaw/Documents/GH Repos/XYZ-forge/.tick/merge-cleanup/HiQS-Labs-XYZ-forge/temp-docs.md:5 and :6 retain both exact tips, links and pending operator disposition. SKILL.md:137 requires overlap reporting and keep/reviewed-recovery/discard choices, including stopped runs, without automatic merge/deletion/teardown.
- [Pass] Object-tree comparison of seeded f2bc1a90… against 7435a38c… limits changes to skill, GH-1005 capture, CHANGELOG, ledger pair, two receipts and relay; working runtime/gate files match baseline blobs (merge_cleanup.py bd7cbb63…, express.py 197aa591…, gh436 shell 313d3b79…). releases.sql:835 points GH-1005 to its capture; CHANGELOG.md:1259 names the existing landing gate.
- [Unverified — needs clone run] No suite, pytest, executable fixture, Git command or production check ran here; express gate/landing, live lease-race behavior and branch-recreation execution remain outstanding. Approval covers policy and inspected evidence, not those outcomes. Shell GitHub access failed; connector reads independently resolved publications.
- Graph: Verify tier, canonical project Users-noelsaw-Documents-GH-Repos-XYZ-forge, ready generation 2026-10-09T10:38:13Z; coverage records no gap for skill/merge_cleanup/express/gh436. Different checkout/current policy verified from exact local objects, not stale graph text.
Relay closed (Approved), no further review turn needed; Producer express owns the subsequent clone gate and landing.


### Attestation · relay-drive — 2026-10-09T15:17:49Z
task: GH1005-TEMP-DOCS-QA
reviewer: codex
status: Approved
reviewed-head: f2bc1a9084a63e5c862d824ff5cf1e8faf8e3a8b
added-range: 7323+3733
added-sha256: a60ba88059d3ef925fbc3796c766c66582717ae5bd0451c2b71640c0a1ae9c5a
<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
