# RELAY · GH-788 plan QA — Python path with a space
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-09-24.
-->

NEXT: Reviewer
STATUS: Open
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
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns.
   Reviewer headings may be `### Reviewer · Round N`, `### Round N · Reviewer · <agent>`, `### Reviewer (<agent>)` (optionally followed by `— rN`), or `### Reviewer — Round N` (optionally followed by `(<agent>)`); follow the heading with a non-empty review body.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(gh788-plan-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: `PROJECT/1-INBOX/GH-788-PYTHON-PATH-SPACE.md` (the plan; no code has been written yet)
- Commit reviewed: 3ba43e1e on branch fix/gh788-python-path-space
- Issue: https://github.com/HiQS-Labs/XYZ-forge/issues/788 (root cause, repro, site list). Same class, previously: #651, fixed for `gh610` only by PR #753.
- Source to read (the plan's claims are about these):
  - `test/gh492-roadmap-state-sweep.sh:24`, `test/gh648-l2-token-aftermath.sh:65`, `test/gh648-l4-285-revalidate.sh:49`, `test/gh648-l5-gh237-repro.sh:35`, `test/gh648-l6-muse-attribution.sh:33`, `test/gh666_agy_model_probe.py:32,130-146`
  - `test/gh610-claude-subscription.sh:96-110,162` (#753's launcher convention and its red control)
  - `utils/py/fuzz_engine.py:220-230` (`build_argv`), `:375-392`; `utils/py/repro_synth.py:199`; `utils/py/gen4_campaign.py:329`
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-09-24
- Operational envelope: test fixtures and a local fuzz self-test in a developer CLI repo. The fix should be proportionate: one small helper, mechanical edits at the listed sites, one registered suite. Don't ask for frameworks, gate preflights, or migrating working code.
- Definition of Done for the **plan** (grade the plan, not an implementation):
  1. Every listed site exists at the cited line on `3ba43e1e` and is the defect described. No site was missed by the plan's patterns in `test/ utils/ relay-automation/ skills/`.
  2. The chosen stub launcher (`#!/bin/sh` + `"exec" <shlex.quote(python)> "$0" "$@"`, a sh/Python polyglot in one file) is correct: valid Python, valid sh, works with an empty `PATH` and argv containing spaces, and preserves the exact interpreter. It is consistent with #753's convention, not a competing system.
  3. Quoting via `shlex.quote` in the fuzz command strings round-trips through `build_argv`.
  4. The guard suite's red controls actually fail on the defect (a bare spaced shebang, an unquoted argv, and a planted ratchet sample), so an empty or broken matcher cannot pass.
  5. Scope is minimal: non-goals are justified, and nothing is duplicated or over-built.
- Questions (cite `file:line`; a probe under `.relay-scratch/` is allowed, no test runs):
  1. Is any `sys.executable`-in-shebang or unquoted-interpreter-in-command-string site missing from the plan? Name it.
  2. Does the polyglot break for any site's actual usage (e.g. a test that reads the stub's text, compares its first line, or runs it via `python stub` rather than executing it)?
  3. Is `utils/py/pystub.py` the right home, given 5/6 sites have `utils/py` on `PYTHONPATH`, or is there an existing module this belongs in?
  4. Is the ratchet's regex set sufficient without being noisy (e.g. false positives on `subprocess.run([sys.executable, …])` argv lists, which are safe)?
  5. Is the rating `75/70/50/70` grounded in the recurrence evidence cited (#651 → #788)?

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
