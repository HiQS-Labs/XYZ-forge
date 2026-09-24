# RELAY · GH-797 final QA: Flightdeck unknown-state help
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
6. **Commit only the relay file** (`relay(gh797-final-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: commit `d5fef5ba` on `fix/gh797-flightdeck-unknown-help` (`git show d5fef5ba`). Files:
  `web/flightdeck/presentation.mjs`, `web/flightdeck/app.js`, `web/flightdeck/app.css`,
  `web/flightdeck/README.md`, `test/flightdeck/work-status-checks.mjs`, `CHANGELOG.md`, and the
  plan `PROJECT/2-WORKING/GH-797-FLIGHTDECK-UNKNOWN-HELP.md` (read it in full). Issue: https://github.com/HiQS-Labs/XYZ-forge/issues/797
- Ground truth for the snapshot fields the UI reads: `src/flightdeck/connectors.py` (`read_connectors`,
  `_read_json_source`, `read_xyz_work`, `empty_batch`) and `src/flightdeck/contract.py` (`ConnectorConfig.from_environment`).
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-09-24
- Operational envelope: a local, loopback-only, single-operator dashboard. This is a presentation-only
  copy and labeling change. Grade against the stated acceptance criteria and commensurate complexity. Do
  not demand new observability, error-handling machinery, server-side hint fields, or new test frameworks;
  the operator explicitly asked to adapt the existing code and not build another system.
- Definition of Done (from #797):
  1. Cards no longer say "Progress coverage unknown"; the label reads as "not measured", and help text says why and that it is not an error.
  2. A `disabled` source, and an `unavailable` source with no error, render grey (`off`) with a how-to-enable hint naming the right env var.
  3. A source whose read failed (`error` set, or an xyz_work `roots[].error`) stays red (`failed`) and names the error.
  4. Focused checks pass, and the new assertions fail against the old behaviour (red control: a mutation that paints an unconfigured source red fails `work-status-checks.mjs`).
- Evidence (Producer-run, in the task clone): `node test/flightdeck/work-status-checks.mjs` rc=0; the mutation red control fails with an AssertionError;
  `python3 -m pytest -q test/flightdeck` → 39 passed; `node test/flightdeck/browser-status-checks.mjs` (real Chrome) passed; the live headless screenshot shows "Progress not measured" with a grey dot.
- Questions:
  1. Does `sourceStatus` map every `availability`/`error` combination the connectors actually emit (`connectors.py` `read_connectors` and each reader) to the right tone? Is any real read failure shown grey, or any unconfigured source shown red?
  2. Are the env var names in `SOURCE_SETUP` correct against `contract.py`? For example, does `disabled` for xyz_work really mean `FLIGHTDECK_XYZ_ROOTS` is unset?
  3. Did the `renderSources` change regress anything: the stale handling, the excluded-rows suffix, or anything else that read the old `.unavailable` class?
  4. Is the change surgical and DRY: no duplicated subsystem, and no unneeded machinery?
  5. Is anything in the README/CHANGELOG wording inaccurate?
  Cite file:line for every finding.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
