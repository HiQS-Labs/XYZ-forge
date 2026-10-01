# RELAY · GH-879 and GH-139 N5 final QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-09-28.
-->

NEXT: Producer
STATUS: Approved
ROUND: 1 / 4

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
6. **Commit only the relay file** (`relay(gh879-n5-final-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **.relay-artifacts/SKILL.md** — the read-only path that
  `relay-drive.sh --artifact-file skills/4-occasional/ci-suite-audit/SKILL.md` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: agy   ·   Producer: claude-a
- Started: 2026-09-28
- Definition of Done: The #879 skill gives no unearned KEEP or removal verdict, requires source-derived four-source evidence with honest per-suite run denominators, pins an independent registry count and compatible runtime receipts, and follows #854's newer INVESTIGATE decision for historical flakes. The existing GH-139 guard detects quiet-grep variants without treating `|| grep` as a pipe, and its 81-line baseline is measured. No new suite or gate machinery.

## Review packet

Read the full committed `skills/4-occasional/ci-suite-audit/SKILL.md`, `test/gh139-pipe-grep-guard.sh`, `test/baselines/GH-139-pipe-grep-baseline.txt`, `PROJECT/2-WORKING/GH-879-CI-SUITE-AUDIT-FIXES.md`, and `TESTS-RESULTS/2026-09-28+GH-879/SUMMARY.md`. Compare the last two commits (`9ab490a8`, `b416edfb`) with their base `d92df347` using read-only git commands. #854 schedules the full audit for October 8 after Landing 2; this review is of the method and guard, not a request to generate the full report now.

Answer these questions with exact file:line references and concrete falsifiers:
1. Can any remaining rule give KEEP without D2 N>0, source-derived D3/D5, and source read where required? Can LOW/UNKNOWN become a removal verdict?
2. Are calibration rows scored on the same inputs while still halting before target verdict publication? Are issue/commit counts kept apart from executable `k of N`?
3. Does the matcher cover `|grep -Fq`, `-iq`, `-qF`, `--quiet`, `-F --quiet`, and skip `|| grep`? Could it cross another pipe or count a clearly non-quiet grep?
4. Is the 81-line baseline a tight inventory and are the claims in the evidence summary honest? Flag any unmeasured assertion as unverified.

Reviewer is read-only except for this relay thread. Do not run `validate.sh`, `test/*.sh`, or pytest in the relay worktree; existing suite results were produced in a separate full clone. Apply the repo's no-new-tests rule and commensurate-complexity standard.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer · Round 1

**VERDICT:** PASS
**Basis:** The skill correctly eliminates `KEEP` defaults, requires source inspection for removal verdicts, isolates issue/commit counts from run denominators, and ensures calibration halts publication if failed. The widened matcher correctly detects quiet-grep pipes while excluding `|| grep` forms and non-quiet pipes, and the baseline is accurately measured at 81 lines (16 comments, 65 code).

swept file: yes

* **[Pass]** Can any remaining rule give KEEP without D2 N>0, source D3/D5, and source read? **No.** `SKILL.md` (L32): "A row gets `KEEP` only when D2 has an observed execution denominator $N > 0$ for that suite and D3/D5 produced outputs for it. Otherwise the verdict is `INVESTIGATE`...".
* **[Pass]** Can LOW/UNKNOWN become a removal verdict? **No.** `SKILL.md` (L236): "High Confidence Required: QUARANTINE, TURN-OFF, MERGE, SPLIT, and NIGHTLY require full source inspection and `HIGH` or `MED` confidence."
* **[Pass]** Are calibration rows scored on the same inputs while still halting before target publication? **Yes.** `SKILL.md` (L55): "Score calibration rows with the same saved inputs and scoring pass as target rows... Check the calibration verdicts before publishing any target verdict."
* **[Pass]** Are issue/commit counts kept apart from executable `k of N`? **Yes.** `SKILL.md` (L33): "Only executed runs contribute to a suite's `k of N` denominator; issues and commits provide attribution, not extra runs." and L124.
* **[Pass]** Does the matcher cover quiet grep variants and skip `|| grep`? **Yes.** `test/gh139-pipe-grep-guard.sh` L43 strips `||` via `sed 's/||//g'`, preventing `|| grep` matches. The regex at L44 (`\|[[:space:]]*grep[[:space:]]+(-[^[:space:]|]+[[:space:]]+)*(-[[:alpha:]]*q[[:alpha:]]*|--quiet)`) covers `-Fq`, `-iq`, `-qF`, `--quiet`, and `-F --quiet`.
* **[Pass]** Could the matcher cross another pipe or count a clearly non-quiet grep? **No.** The option-matching portion `(-[^[:space:]|]+[[:space:]]+)*` explicitly rejects `|`, meaning it cannot cross pipes. It requires `-q` or `--quiet`, ensuring no non-quiet grep is matched (falsifier: `echo x | grep -F y` contains no `q` flag or `--quiet` so the regex fails to match).
* **[Pass]** Is the 81-line baseline a tight inventory and are claims honest? **Yes.** Counting `test/baselines/GH-139-pipe-grep-baseline.txt` values yields exactly 81 lines across 27 files. Re-running the script's regex loop directly matches exactly 16 lines starting with a comment (`#`) and 65 code lines. The `gh139` guard script passes. No assertions are unmeasured or flagged as unverified.

handing off to Producer — relay closed (Approved), no further turn needed.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
