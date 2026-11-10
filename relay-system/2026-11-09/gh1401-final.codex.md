# RELAY · GH-1401 conveyor final QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-11-09.
-->

NEXT: Producer
STATUS: Approved
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
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
   Reviewer headings may be `### Reviewer · Round N`, `### Round N · Reviewer · <agent>`, `### Reviewer (<agent>)` (optionally followed by `— rN`), or `### Reviewer — Round N` (optionally followed by `(<agent>)`); follow the heading with a non-empty review body.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(gh-1401-conveyor-final-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **.relay-artifacts/SKILL.md** — the read-only path that
  `relay-drive.sh --artifact-file skills/1-hourly/conveyor/SKILL.md` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: codex   ·   Producer: author
- Started: 2026-11-09
- Definition of Done: Review the complete conveyor skill and this branch diff against PROJECT/2-WORKING/GH-1401-CONVEYOR.md, recon-conveyor.md, issue #1401 requirements, ARCHITECTURE index and TESTS-RESULTS/2026-11-09+GH-1401 receipts. Operational envelope: skill-only local developer preparation workflow, no implementation, schemas, scheduler or new tests/gates. Questions: (1) Are all issue modes covered with bounded authorized writes? (2) Is canonical parser/PRS/Jog composition truthful, especially polarity and label versus admission? (3) Do docs publish before readiness and preserve holds/ovr/rerun state? (4) Are manual main/adjacent/red controls sufficient for instruction-only scope and honest about acceptance unknown? (5) Any duplicate subsystem, unsupported command, unsafe mutation or unnecessary machinery? Cite file:line. Plan QA Approved round 2; smoke assertions passed and preflight READY/STALE results retained. Documentation gate is in flight; do not treat pending result as pass. Review all skill text, scope and retained evidence; no suites in review worktree.

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
Basis: Approve the instruction-only artifact against the local canonical plan and traced consumer contracts. No blocking or should-fix defect found across the complete seeded skill, including pre-existing text. Publication qualification remains dependent on the pending documentation gate.
swept file: yes

- [Pass] Bounded issue IDs, ranked discovery, scheduled batches and authorized event payloads share one preparation flow. Scope excludes implementation/admission and installation, with unresolved items held. Evidence: `.relay-artifacts/SKILL.md:10-25`; canonical requirements in `PROJECT/2-WORKING/GH-1401-CONVEYOR.md`, Requirements and boundaries. No additional subsystem is introduced by these instructions.
- [Pass] Contract schema and polarity match the actual parser/evaluator and Jog shape checker. Evidence: `.relay-artifacts/SKILL.md:29-31,44-61`; `utils/py/swarm_preflight.py:54-151,196-245`; `utils/py/jog_run.py:1577-1632`. Probe inspection, disposable-clone isolation and explicit dry-run side effects bound the executable surface.
- [Pass] Canonical pickup preserves existing ratings/override and stays separate from accepted execution start. Evidence: `.relay-artifacts/SKILL.md:27,33-42`; `utils/py/releases_app.py:3823-3871,4115-4251`. Read-back and verified canonical repointing cover rerun state without a second writer.
- [Pass] Publication precedes readiness, with final integration-ref preflight, owner-resolved holds and reviewed-content matching required. Label discovery remains distinct from Jog admission, and refresh failure removes stale readiness within selected scope. Evidence: `.relay-artifacts/SKILL.md:63-71`. `ARCHITECTURE.md:57` points to the skill, and the seeded artifact matches the installed repository skill byte-for-byte (`cmp .relay-artifacts/SKILL.md skills/1-hourly/conveyor/SKILL.md`, exit 0, no output).
- [Pass] Retained manual controls are proportionate to this instruction-only composition. `TESTS-RESULTS/2026-11-09+GH-1401/conveyor-smoke.log` quotes `RED empty fix_probes rejected exit=3`, `PAIR grep_present BUG: bug-present= unfixed fixed= landed` and the inverted `landed unfixed` control. `provenance.jsonl` records main exit 0 at `39207869450ee7115dcd9b552fb1bcacd15e203b` and adjacent exit 4 at `31424e4ff421037c413c0ef3fef2ad55ba4afaa8`; both corresponding JSON artifacts retain the expected probe verdicts. These are inspected producer receipts, not a fresh execution in this review worktree. SUMMARY explicitly discloses acceptance fidelity `unknown/no-issue-section`.
- [Unverified — needs clone run] Pending documentation gate is not counted as passing. No suite, pytest, executable fixture or full gate ran during this review. No Git command ran, so a complete branch-diff audit was unavailable under this turn's constraints. Live issue refresh command `gh issue view 1401 --repo HiQS-Labs/XYZ-forge --json title,body` exited 1 with `error connecting to api.github.com`; issue-requirement comparison uses the local canonical plan and retained receipts.

relay closed (Approved), no further turn needed.


### System · relay-drive — 2026-11-10T05:16:00Z
terminal STATUS Approved written by FAILED reviewer turn (codex; shim returned non-zero) — reverted

### Producer · Round 2

The first reviewer found no defects, but driver exit 6 invalidated its terminal verdict because the author concurrently appended the completed docs-gate provenance in the parent clone. The guard reverted that author line; this was caller interference, not reviewer misconduct. Gate receipt is now committed before this turn. No concurrent parent edits will run. Documentation gate exited 0 with zero errors/656 warnings, retained summaries/provenance disclose the exact limitation and final pre-push gate still applies. Please re-review current skill/plan/evidence for final approval. No production artifact changed since round 1.

Handing off to Reviewer.

### Reviewer · Round 2

VERDICT: PASS
Basis: Approve the complete instruction-only skill against the canonical plan, recon and retained consumer evidence. No blocking or should-fix defects found, including pre-existing text. This approves preparation content; final publication qualification remains with the normal push gate.
swept file: yes

- [Pass] All input modes stay bounded and reuse the same preparation flow; authority excludes implementation, admission and installation. Evidence: `.relay-artifacts/SKILL.md:10-25`. Publication waits for integration-ref availability, authorized hold resolution and fresh preflight; the label is explicitly discovery only (`.relay-artifacts/SKILL.md:63-71`).
- [Pass] Schema, probe polarity and parser/Jog composition match the inspected consumer code: `.relay-artifacts/SKILL.md:29-61`, `utils/py/swarm_preflight.py:54-151,196-245`, `utils/py/jog_run.py:1577-1632`. PRS pickup preserves existing scores/override and remains distinct from accepted start: `.relay-artifacts/SKILL.md:27,33-42`, `utils/py/releases_app.py:3823-3861,4115-4251`. No duplicate writer, scheduler or gate is introduced.
- [Pass] Full artifact matches the repository skill: command `cmp .relay-artifacts/SKILL.md skills/1-hourly/conveyor/SKILL.md`, exit 0, no output. `ARCHITECTURE.md:57` links that skill. Canonical plan requirements and `PROJECT/2-WORKING/recon-conveyor.md` describe the same bounded preparation/consumer seam.
- [Pass] Retained manual controls discriminate main, adjacent and bad-input cases. `TESTS-RESULTS/2026-11-09+GH-1401/conveyor-smoke.log` quotes `RED empty fix_probes rejected exit=3`, `PAIR grep_present BUG: bug-present= unfixed fixed= landed`, and inversion `landed unfixed`. Main/rerun JSON retain candidate states `ready`/`stale` at their recorded evaluated SHAs; provenance records exit 0/4. SUMMARY explicitly discloses acceptance fidelity `unknown/no-issue-section`. These are inspected producer receipts, not fresh executions here.
- [Pass] Documentation receipt now exists: `TESTS-RESULTS/2026-11-09+GH-1401/docs-gate.txt` says `PDDA run complete: no errors, 656 warning(s) to review`; provenance records exit 0 and explicitly states the gate began before final evidence/review-only commits. This is adequate retained evidence for instruction-only review, without claiming final-head qualification.
- [Unverified — needs clone run] No suites, pytest, executable fixtures or gate ran in this review worktree. No Git command ran, so a complete branch-diff audit was unavailable. Live issue requirements were assessed through the canonical local plan and retained issue/preflight evidence rather than a fresh GitHub query. Final-head push qualification remains outstanding as disclosed by the producer receipt.

relay closed (Approved), no further turn needed.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
