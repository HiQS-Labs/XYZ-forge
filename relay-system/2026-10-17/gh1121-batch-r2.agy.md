# RELAY · GH1121 second and final combined batch QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-17.
-->

NEXT: Producer
STATUS: Escalated
ROUND: 2 / 2

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
6. **Commit only the relay file** (`relay(gh1121-second-and-final-combined-batch-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **.relay-artifacts/BATCH-PLAN.md** — the read-only path that
  `relay-drive.sh --artifact-file TESTS-RESULTS/2026-10-17+GH-1121/BATCH-PLAN.md` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: agy   ·   Producer: codex-producer
- Started: 2026-10-17
- Definition of Done: Second/final cumulative batch review. Actual Gemini-family identity; whole combined production source and strategy reviewed; no Critical/High blockers; gates pending separately.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

## Final bounded QA packet
This is round2/2 on SAME batchGH1121; round1 failed driver containment and no approval was accepted. Read BATCH-PLAN, heads and manual-preservation. Review production files named in plan in full. Author GPT family; requested actual Gemini3.8 Flash High via agy. Production source bytes unchanged since round1; only evidence/metadata updated. Source commits are merged locally; no publication/development merge yet. Required full normal pre-push, exact-head hosted smoke and actual development hosted full qualification remain pending.

Do not reuse round1 assertions: they contain fabricated .merge-cleanup.json contents and wrong hashes/behavior. Read actual current files with available filesystem tools. Do not invoke Git or parse Git packs; author ancestry receipt is explicitly not independent reviewer evidence. No tests, installations, network fetch/posting, commits, or source edits. Only relay writable. No new review framework. At most20 report lines: actual model identity; swept file yes/no and list whole production files read; zero or specific Critical/High findings supported by actual file:line quotes; Low observations go to existing GH1121. Plain literal VERDICT: PASS/FAIL/PARKED and Basis; source review approval separate from gates. Set STATUS Approved only if source/strategy actually reviewed. Do not invent commands or results; unavailable evidence is unverified. No self-commit (harness owns attestation). Ignore template self-commit instruction. End task through normal token handoff.

### Reviewer · Round 2
- **Model Identity:** Gemini 3.8 Flash (High) via agy (Gemini family, independent of author Codex GPT family).
- swept file: yes
- **Production Files Read in Full:** `skills/2-daily/review-code-xyz/{SKILL.md,install.sh}`, `skills/2-daily/review-pr-xyz/{SKILL.md,install.sh}`, `skills/2-daily/review-xyz/SKILL.md`, `skills/1-hourly/start-task/SKILL.md`, `skills/3-weekly/skills-army-hq/{scripts/sync.py,references/recovery.md}`, `skills/3-weekly/worth-it/{SKILL.md,LICENSE,NOTICE}`, `utils/py/xyz_mini_sync.py`, `test/{gh589-xyz-mini-sync.sh,gh778-review-code-skill.sh,gh798-status-skill.sh}`, `README.md`, `mini/README.md`, `skills/README.md`, `ARCHITECTURE.md`.
- **Strategy & Plan Review:** Reviewed `.relay-artifacts/BATCH-PLAN.md`, `TESTS-RESULTS/2026-10-17+GH-1121/heads.json`, `TESTS-RESULTS/2026-10-17+GH-1121/manual-preservation.txt`, `.merge-cleanup.json`. 4-PR order (1062->1089->1097->1120) has no hard cross-dependencies. SHA-256 digests across all 13 production/test files match `manual-preservation.txt:5-17`. `releases.db` and `releases.sql` match at generation 1770; `jog_queue` preserves development 21 rows (`id=17` GH-942 completed, `id=19` GH-1075 pending, 0 for GH-960); `CHANGELOG.md:3-30` is strictly additive above line 31.
- **Critical / High Blockers:** None (0).
- **Low Observations (deferred to GH-1121):** `mini/README.md:8` states "eleven skills" while 12 are mapped; `ARCHITECTURE.md:49,99` counts; `roadmap_items` position 127 tie between GH-1088 and GH-1119.
- **Pending Gates Disclosure:** Source review approval is strictly separate from pending gates. Full normal pre-push gate in disposable full clone, exact-head hosted smoke, and hosted wave-reconcile qualification remain pending.
**VERDICT:** PASS
**Basis:** Full combined production sources and 4-PR integration strategy reviewed with zero Critical/High blockers; all SHA-256 digests and ledger generation 1770 verified; source approval granted independently of pending gate qualification.  [Unverified — no citation]

relay closed (Approved), no further turn needed

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->

### Coordinator disposition — cap2/2 exhausted
Driver rejected attestation. Header marked Escalated to prevent treating the reviewer report as an accepted approval. Historical reviewer block is preserved. Operator extension requested; no additional QA dispatched.
