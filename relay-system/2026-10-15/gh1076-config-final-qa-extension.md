# RELAY · GH1076 configuration pivot supplemental final QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-15.
-->

NEXT: Producer
STATUS: Escalated
ROUND: 1 / 1

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
6. **Commit only the relay file** (`relay(gh1076-configuration-pivot-supplemental-final-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **.relay-artifacts/gh1076-config-final-packet.md** — the read-only path that
  `relay-drive.sh --artifact-file relay-system/2026-10-15/gh1076-config-final-packet.md` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: codex   ·   Producer: codex-producer
- Started: 2026-10-15
- Definition of Done: The complete scoped Definition of Done in the seeded gh1076-config-final-packet.md; review complete implementation and retained evidence, preserve original counters. This is Noel-authorized extra final QA1/1, no retry.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer · Round 1 · codex

VERDICT: FAIL
Basis: Block source approval on the concrete identity-drift/fallback contract defect below. This spends the authorized supplemental final QA1/1; no automatic fix/review retry or counter reset. Original plan3/3 FAIL, final3/3 PASS and supplemental plan results remain untouched.
swept file: no

- [Should] **Detected identity drift is treated as insufficient proof and retried on the same clone.** `utils/py/wave_reconcile.py:898–907` explicitly raises `ValueError("profile run/environment identity changed between phases")`, then catches that same exception and selects `QUALIFICATION_GATE`. Line908 runs the full phase on that clone, which can subsequently emit a passing @1 receipt. The process-identity mismatch at886–887 takes the same fallback. This contradicts the packet's “failures/identity drift stop, proof insufficiency gets bounded full fallback” distinction; the comment at903 does not match these branches. Concrete bounded correction: use the existing fatal qualification error path for detected environment/run/process identity mismatches; retain the single full fallback for genuinely missing/incomplete proof after otherwise successful, identity-stable commands. No new runner, module or CI test is needed.
  Observed input: the current source's explicit drift branch at898–900, and the launched-process mismatch branch at886–887, both produce `ValueError` consumed by902. For the former, `qualification_environment(...) != profile_identity["environment"]` is the precise failing predicate; no live contaminated clone or suite run is claimed.
  Affected scope: only already-detected environment/run/process identity discrepancies during the two profile phases; not initial unavailable environment metadata, ordinary ineligible scope, or absent telemetry.
  Falsifier: in a disposable full clone, an existing/manual control that changes the post-phase fingerprint or supplies a mismatched launched run ID must exit6 before launching full or writing passing provenance; an identity-stable missing-proof control should still receive at most one full fallback. If these mismatches already terminate before full, this finding is wrong. That end-to-end control remains [Unverified — needs clone run].
  Read-only probe: `python3` with the following stdin (exit0):
  ```python
  import ast
  from pathlib import Path
  p=Path('utils/py/wave_reconcile.py'); tree=ast.parse(p.read_text())
  for node in ast.walk(tree):
      if isinstance(node, ast.Raise) and node.exc and 'identity' in ast.unparse(node.exc):
          if 850 <= node.lineno <= 910:
              print(f'{p}:{node.lineno}: {ast.unparse(node)}')
  for node in ast.walk(tree):
      if isinstance(node, ast.ExceptHandler) and 880 <= node.lineno <= 905:
          print(f'{p}:{node.lineno}: {ast.unparse(node)}')
  ```
  Decisive output: `utils/py/wave_reconcile.py:900: raise ValueError('profile run/environment identity changed between phases')`; `:902: except (ValueError, UnicodeError) as exc:` followed by `gate, expected = (QUALIFICATION_GATE, None)`. This is static production-source evidence, not an executed gate or synthetic PASS.
- [Pass] The packet correctly distinguishes retained historical components from current qualification: “f874 Small75/75 and area9/9 are distinct real original runs, not current execution or an @2 qualification.” Keep that limitation and the post-review full-gate requirement; neither is waived by this turn. Configuration uses the existing owner with strict opt-in at `utils/py/device_config.py:127–129`, and the hosted override is explicit at `.github/workflows/wave-reconcile.yml:40`.
- [Unverified — needs clone run] No validate/test/pytest/fixture was executed here. Current full qualification and a live @2 writer/publication race remain unproved, as the packet discloses. The worktree has no matching indexed graph project (both list_projects pages inspected), so direct source was used. I read the entire seeded packet and inspected the primary implementation and publisher seams, including pre-existing qualification/premerge paths. A complete current-base Git diff and whole-file sweep of every touched governance/evidence file was not established under the no-Git restriction; the literal sweep declaration above deliberately records that limit. No additional pre-existing material defect is asserted from the inspected portions.

Handing off to codex-producer — report the FAIL and stop under the exhausted1/1 cap; any correction/review continuation needs fresh operator authority. No source approval, merge, activation, deployment or further automatic round is authorized by this review.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
