# RELAY · GH-1376 flywheel skill final QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-11-08.
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
6. **Commit only the relay file** (`relay(gh1376-flywheel-final): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **.relay-artifacts/SKILL.md** — the read-only path that
  `relay-drive.sh --artifact-file skills/2-daily/flywheel/SKILL.md` seeds into the isolated worktree (read it there; do NOT edit it).
- Committed candidate: `3f0014e6f464ca8e382e32e9bdc51c8c358054e9`, including integrated development base `ade50aed69f8dce5569e357cf934e9b31d5e294b`.
- Read in the committed tree: `PROJECT/2-WORKING/GH-1376-FLYWHEEL-SKILL.md` (requirements, recon and plan), `ARCHITECTURE.md` Skills Index, `TESTS-RESULTS/2026-11-08+GH-1376/SUMMARY.md` and `provenance.jsonl`, and `relay-system/2026-11-08/gh1376-flywheel-plan.codex.md` (Approved plan QA).
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-11-08
- Operational envelope: one local documentation-only routing skill. No production code, new test suite, new gate, deployed-skill mutation, automatic merge, marathon firing, or enterprise/multi-tenant threat model. Apply commensurate complexity and reject duplicate machinery.
- Definition of Done: the skill and index row satisfy #1376; the two #1358 work modes, three rubrics, exact autonomous-repair sentence and four-rung authorization ladder are present; the ordered flow routes to all eight existing skill owners without duplicating their state or commands; Jog recovery order, existing caps/locks/containment, per-PR merge approval and separate deployment remain intact; consumer smoke and the classified PDDA gate substantiate the result with committed provenance; no new test/gate appears; and no unrelated defect or scope leakage is introduced.

Questions:
1. Does the committed artifact satisfy every #1376 acceptance requirement except the PR-publication step that follows this review?
2. Is any rule internally contradictory, especially around autonomous bounded supervisor/config repairs versus formal unattended work?
3. Does any routing step duplicate a queue, runner, scheduler, writer, review or deployment owner, or accidentally repeat an already completed lifecycle?
4. Do the consumer smoke, classified gate and committed provenance support the stated documentation-only result? Is any required evidence empty or missing?
5. Is the Skills Index placement and source link correct, and are all eight companion-skill links valid?
6. Are there concrete blocking findings requiring a source change? If so, cite file:line and provide Observed input/Affected scope/Falsifier. Do not request speculative machinery or new tests.

Approve if the current committed deliverable is ready for normal gated publication and a development PR. Otherwise name the smallest required correction.

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
Basis: Ship for normal gated publication and a development PR. The complete seeded skill satisfies the documentation-only acceptance contract; no source correction or pre-existing defect was found in the swept artifact. This approval does not authorize merge, deployment or marathon dispatch.
swept file: yes

- [Pass] Policy and repair boundaries: `.relay-artifacts/SKILL.md:30–61` carries both work modes, Rubrics 2/3 and the exact autonomous-repair sentence at line 37. Lines 67–83 supply all four authorization rungs, including verified running-version changes, bounded recovery, independent work and actual escalation boundaries. Formal readiness and bounded repairs are compatible rather than contradictory; the approved plan receipt's policy-source comparison supports the #1358 projection (`relay-system/2026-11-08/gh1376-flywheel-plan.codex.md`, Reviewer Round 1, “Policy coverage”). No unrelated campaign policy is replaced (artifact lines 85–89).
- [Pass] Existing owners remain authoritative: artifact lines 19–21 and 93–141 route to all eight owners without copying their queues or commands. Resume reconciliation at lines 98–99 prevents repeating completed intake; Jog retains primary-writer/runner ownership at lines 107–117. Recovery at lines 125–128 matches `skills/2-daily/jog/SKILL.md:182–202`; landing at lines 129–135 matches its primary publication/merge-cleanup contract at lines 159–175. Per-PR approval, supported independent advancement, separate explicit deployment and app-link containment remain intact. The completion contract (artifact lines 145–152) requires actual outcome/state reporting rather than inferring unattended reliability.
- [Pass] Consumer source and index: `ARCHITECTURE.md:85` places the relative source link in the existing 2-daily table. Narrow read-only probe: `python3` read the seeded and consumer files and asserted byte equality, extracted the eight development skill URLs and asserted each corresponding local source file exists, then parsed `TESTS-RESULTS/2026-11-08+GH-1376/provenance.jsonl` and asserted each hashed evidence file is nonempty and matches SHA-256. Exit 0; decisive output: “consumer-smoke.txt 97 hash matches”, “pdda-initial.log 42281 hash matches”, “pdda-integrated.log 42281 hash matches”, and “PASS: seeded artifact equals consumer source; 8/8 owner paths exist; nonempty receipt hashes match”. No network availability of future development links is implied.
- [Pass] Proportionate recorded evidence: `TESTS-RESULTS/2026-11-08+GH-1376/SUMMARY.md` → “Consumer smoke” records 12/12 segments and 8/8 links; its “Classified documentation gate” and the matching provenance records identify the isolated PDDA runs and revisions. `pdda-integrated.log` ends “PDDA run complete: no errors, 100 warning(s) to review”. Evidence supports a documentation-only result, with existing warnings and optional LLM hook skip disclosed. The artifact introduces no executable, suite or gate; no sensitivity experiment on a new decision gate is required.
- [Unverified — needs clone run] This turn did not rerun the classified gate or executable fixtures, nor independently attest the final candidate through a git query. Recorded integrated gate evidence names `681809230bec851f4fa11748d9f5c6993f3804e4`, not the Setup candidate `3f0014e6f464ca8e382e32e9bdc51c8c358054e9`. The harness/publication gate must attest the final committed state as planned; prior receipts are not represented as a current-candidate gate. PR publication/base/head/check inspection remains subsequent work, not a completed acceptance item.

Relay closed (Approved), no further turn needed. The harness owns the one-file commit; the Producer may continue normal gated publication under existing task authorization.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
