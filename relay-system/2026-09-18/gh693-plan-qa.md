# RELAY · GH-693 plan QA — Lessons Learned advisory
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-09-18.
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
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(gh693-plan-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **.relay-artifacts/gh693-plan.md** — the read-only path that
  `relay-drive.sh --artifact-file relay-system/2026-09-18/gh693-plan.md` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: agy   ·   Producer: claude
- Started: 2026-09-18
- Definition of Done: the plan is sound if (1) §2's enforcement inventory is complete — every place the reconciler refuses, dies, skips, or a test pins the old behaviour is listed with file:line (verify with `rg -n "Lessons Learned|validate_lessons_learned" utils/ test/ skills/ *.md PROJECT/PDDA.md` on the seeded tree); (2) §3's mechanism is the least one — one detector, one advisory emitter, three call sites, no flag, no new module; (3) each flipped/added test in §3 would FAIL on the parent commit (red-before) and the negative control keeps frontmatter mandatory; (4) §4 names every behaviour that changes, including the hosted lane, `--pre-merge`, vendored `.xyz/` copies, and #691's self-close; (5) §6's express bounds are legitimate operator-tunable tuning and no hard refusal (frozen twin, kernel surface, `.sh` under utils/ or relay-automation/) is touched. Grade each; PASS only when no [Blocker] remains.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

## Reviewer (agy, 2026-09-18)
swept file: yes
- `[Pass]` DoD 1: Enforcement inventory is complete. Verified via `rg` that the 3 call sites for `validate_lessons_learned` (`utils/py/wave_reconcile.py:1025`, `utils/py/wave_reconcile.py:1795`, `utils/py/wave_reconcile.py:2051`) and the 2 tests pinning the old behaviour (`test/wave-reconcile.sh:238-250`, `test/gh496-phase2-reconciliation-views.sh:317-330`) are accurately listed.
- `[Pass]` DoD 2: Least mechanism. The plan uses the existing `log()` with a `WARN —` prefix since `log_warn` doesn't exist, preserving one detector (`utils/py/wave_reconcile.py:931`) and adding one advisory emitter without any new modules or flags.
- `[Pass]` DoD 3: Tests fail on parent. `test/wave-reconcile.sh` Test 4 currently expects exit 5; flipping it to expect exit 0 will fail on the parent commit. Similarly, `test/gh496-phase2-reconciliation-views.sh:317-330` expects exit 5 on `--pre-merge`; flipping to expect exit 0 fails on parent.
- `[Pass]` DoD 4: Blast radius. §4 accurately names every changing behaviour, including `"the four #691 docs promote to 3-COMPLETED without the section and #691 closes itself"`, `--pre-merge`, and `"Vendored .xyz/ copies"`.
- `[Pass]` DoD 5: Express bounds. §6 specifies legitimate tuning (`"--max-files 12 --max-insertions 400 --allow-multi-subsystem"`). No touched files (`utils/py/wave_reconcile.py`, `sentinel-overlay/pr-emit.sh`, etc.) are hard refusals (frozen twin, kernel surface, or `.sh` under `utils/` or `relay-automation/`).
- `[Nit]` Unaffected fixtures: `test/gh280-jog-marathon-adapter.sh:871` and `test/baselines/GH-421-negative-control.md:10` also contain the section and are unaffected, though they were omitted from the illustrative list in §2.

VERDICT: PASS
Basis: All DoD criteria are met and the plan accurately describes the complete surface area and blast radius of the change.

relay closed (Approved), no further turn needed


### Attestation · relay-drive — 2026-09-18T14:48:21Z
task: RELAY-gh693-plan-qa
reviewer: agy
status: Approved
reviewed-head: 30910cc6b805cfc25bf37cd652ebf4793672995f
added-range: 5940+1936
added-sha256: 7b7a14d0e8ef7537940b1bfd9af72bfcd6ba00aff9703382c23f1eff96ceac88
<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
