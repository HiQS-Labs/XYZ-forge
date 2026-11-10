# RELAY · PR1404 approved-head binding repair
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-11-10.
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
6. **Commit only the relay file** (`relay(pr1404-approved-head-binding-repair): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **.relay-artifacts/review-1404-round2.md** — the read-only path that
  `relay-drive.sh --artifact-file temp/review-1404-round2.md` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: claude-opus   ·   Producer: codex-parent
- Started: 2026-11-10
- Definition of Done: _<fill in the acceptance criteria the Reviewer grades against>_

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer · Round 1
swept file: yes. I read the whole flywheel SKILL.md in the artifact, not just the landing paragraph, plus the receipt pointer and the cited source.
DoD note: Setup's Definition of Done is still the placeholder, so I graded against the artifact's own stated intent: before `--execute`, the dry-run pin must explicitly equal the reviewed/approved SHA; a moved head needs fresh eligibility/QA/approval; no runtime change; no widening of authority.

- [Pass] The artifact's skill text matches the tree exactly. Probe: `diff <(sed -n '/^name: flywheel/,$p' skills/2-daily/flywheel/SKILL.md) <artifact skill section>` printed only the appended receipt and source note lines (261a262,266), so the skill body itself is unchanged. No runtime file is in scope.
- [Pass] The source claim is accurate. `skills/2-daily/merge-cleanup/scripts/merge_cleanup.py:491` `pin_selection` pins `found[n]["headRefOid"]` (the live head) and, when an inline sha is stale, only calls `log_warn("--prs: inline pin(s) no longer match; pinned the live head instead: ...")`. `:513` `verify_selection` compares against `want = {n: (sha or pinned.get(n))}`, meaning the new pin, not the reviewed SHA. So with a reviewed A and a live B, the dry run returns true with B pinned, and the caller is the only guard. The skill's added sentence "Before `--execute`, compare every printed PR/head pin with its reviewed and approved head. If any differs, stop that PR's landing ..." is the correct and necessary instruction.
- [Pass] The receipt pointer is repaired. `TESTS-RESULTS/2026-11-09+GH-1400/readiness-repair.json:4` reads `"original_b1_refusal": "TESTS-RESULTS/2026-11-09+GH-1400/readiness-b1-refusal.json"`. The target exists (354 bytes) and parses as a dict with 6 keys (`resolved, handoff, reason, log, commit, conflict_set`; `python3 -I -c json.load` exit 0). Grepping for `/tmp/` or `temp/` in that receipt found nothing (exit 1), so the old temp pointer is gone.
- [Pass] Authority is not widened. The text keeps "neither a ready PR nor a `--prs` pin grants approval", "never silently widen the list", and "Keep the existing project policy, landing-plan checkpoint and review requirements". That is consistent with merge-cleanup SKILL.md:240 ("`--prs` may narrow the pinned list ..., never widen it") and :249 ("a repaired PR is always **deferred** ... re-run the dry run to re-pin").
- [Should] Bind `--execute` to the approved SHA inline. After the equality check, a bare `--prs N` execute still re-reads a mutable record. The skill says "Only execute the verified matching pins", but it never says to pass them as `--prs N@<approved sha>`. Bare-N execute reads the selection record again at execute time, and `pin_selection` overwrites that record unconditionally with no lock (`merge_cleanup.py:499-503`: `path = selection_path(...)`, `path.write_text(...)`; there is no lock call in either function, `grep -n "_lock(\|acquire"` near 468-545 found none).
  Observed input: `verify_selection` line `want = {n: (sha or pinned.get(n)) ...}` (`:513` body). For a bare `N`, `sha is None`, so the binding is whatever the record says at execute time, not what the caller compared. Sequence: the dry run pins A (A matches the approved head) → the caller compares and sees equality → another dry run on the same primary/integration, after the head moved to B, rewrites `selection-<integration>.json` with B and only warns → the caller runs `--execute --prs N` → `verify_selection` wants B, live is B → it merges the unapproved B.
  Affected scope: only Flywheel-coordinated landings that run `--execute` with bare PR numbers after the pin-equality check. Inline `N@sha` executes are already bound at `:513`.
  Fix (doc-only, one clause): "... Only execute the verified matching pins, passed inline as `--prs N@<approved full sha>,...`, so `verify_selection` checks each live head against the approved SHA itself rather than a re-readable record." This needs no runtime change, matching "No runtime guard requested". If you take this, also make the comparison full-SHA (or the printed `Pinned for --execute:` full-SHA line), not the 10-char abbreviations in the `--prs pinned for --execute (...)` log line.
  Falsifier: in a clone, approve A, dry-run pin A, rewrite the selection record to B with a second dry run after moving the head, then execute `--prs N@A`. Expected: exit 2 with "head moved A -> B" and nothing merged. Executing bare `--prs N` in the same state would proceed. If bare-N verification actually cross-checked an immutable approved SHA, this finding would be wrong. The code at `:513-533` shows it does not. [Unverified — needs clone run] for the end-to-end replay; the code path above is verified by reading it.
- [Nit] The "approved batch" paragraph says the moved-head rule twice: "If any differs, stop that PR's landing, re-establish eligibility and QA/review approval as applicable, and obtain a fresh matching pin" and later "A repaired/moved head needs fresh eligibility, review/approval as applicable and a new pin before landing". Fold the second into the first, keeping its "never silently widen the list or reset repair history" tail.
- [Pass] Rest of the sweep: the relative 10days link resolves (`skills/3-weekly/10days/SKILL.md` exists). The rubrics, ladder, Daily, 10days and the ordered flow show no contradiction with the landing paragraph. No other pre-existing defects found.

VERDICT: FAIL
Basis: The receipt repair and the source analysis are correct, and the pin-equality instruction is right. One [Should] remains: the instruction stops short of binding `--execute` to the approved SHA. Bare-N execute re-reads an unlocked, overwritable selection record (`merge_cleanup.py:499-503`, `:513`), so the equality check can be bypassed between comparison and execute. A one-clause doc fix (execute with inline `N@<approved sha>`) closes it with no runtime change.

### Producer · Round 2
Implemented the Should: compare full SHAs on the full printed pin line and execute with explicit inline `N@<approved-full-sha>` pins. This avoids re-reading a mutable selection record. Implemented Nit by keeping one moved-head instruction and the no-widen/no-reset tail. Receipt pointer unchanged and verified. Review the updated artifact. No runtime changes or new tests/gates.
Handing off to claude-opus for round 2.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
