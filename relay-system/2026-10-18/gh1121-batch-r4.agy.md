# RELAY · GH1121 final unseeded target-tree QA4of4
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-17.
-->

NEXT: Reviewer
STATUS: Open
ROUND: 4 / 4

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
6. **Do not self-commit.** Harness owns the commit/attestation; no push.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Target under review: the actual isolated repository tree at the driver-pinned HEAD; full production files listed in TESTS-RESULTS/2026-10-17+GH-1121/qa-resume-input.json. No seeded artifact.
- Reviewer: agy   ·   Producer: codex-producer
- Started: 2026-10-17
- Definition of Done: Unseeded pinned-target whole-source and sequence review. Actual independent Claude-family reviewer; no Critical/High blockers; strict append-only helper; current exact-head input; all applicable gates preserved.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). No self-commit; harness owns attestation.

## Log

## Final round4of4 — target tree, no seeded artifact

Noel explicitly approved up to FOUR cumulative QA attempts; three consumed, this is the last. No cap reset or extension. This review is of the ACTUAL isolated repository tree at the HEAD the driver pins, not a copied .relay-artifacts input. There is NO --artifact-file on this invocation. Read canonical TESTS-RESULTS/2026-10-17+GH-1121/QA-RESUME.md, BATCH-PLAN.md and qa-resume-input.json as context only; their old attempt3 instructions are historical. Target: the full combined production files listed in production_sha256, current source/code/metadata at pinned HEAD, original source heads1062/1089/1097/1120 and base7f19d57d. R3's full report may inform you but cannot replace your own target-tree review. Reviewer Claude Opus5.5 High through configured Agy, Anthropic family; author GPT family.

Review whole changed production files and the grouping/order, semantic interactions, current-base resolution, exact source preservation, license, rollback and required gates. Read-only local file/hash/SQLite inspection allowed. No tests, Git commands, Git pack parsing, installs, source edits, network posting or self-commit. Only this relay is writable; scratch under .relay-scratch allowed. Caller leaves source tree untouched during your run. Record findings with real file:line/quotes and actual commands/results; don't invent evidence. No Critical/High finding may remain; defer Medium/Low/Nit to GH1121 with clear severity, as instructed. Existing full publication409/409 at a2a13890 covers unchanged production/runtime/test hashes; later normal docs gates cover review/base metadata. Fresh exact-head hosted smoke and actual post-merge hosted full qualification remain mandatory, no promotion.

Process causes fixed: R1 caller concurrent file edit rejected containment; source now clean and caller makes NO tree writes. R2 rewrote earlier blank lines; use EXISTING utils/py/relay_attest.py::append_before_marker(path,text) for your report, then modify ONLY first NEXT/STATUS header lines without normalizing other bytes. Do NOT self-commit; ignore any generic template self-commit rule. Close the handed-off token normally after writing. R3 passed append-only but used --artifact-file, which creates artifact_sha256 and is never target-tree merge-eligible. This invocation is unseeded. After your attestation, caller will store any receipts ONLY in relay-system/ and use relay_attest.load plus candidate_ok before landing; no non-transcript change is allowed without another valid review, and no attempts remain after this one.

Write a Reviewer Round4 block, actual model identity, swept file yes/no, bounded whole-file coverage, graded findings, literal VERDICT: PASS|FAIL|PARKED and cited Basis. If reviewed target is sound with zero Critical/High, set STATUS Approved and NEXT —. Approval is source/strategy review, not unrun gate qualification. Do not dispatch/retry yourself.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
