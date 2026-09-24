# RELAY · GH-788 final QA — Python path with a space
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
6. **Commit only the relay file** (`relay(gh788-final-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: `utils/py/pystub.py` (plus the full diff below)
- Diff: git diff 337813e0..a061be40 (branch fix/gh788-python-path-space). Plan: `PROJECT/2-WORKING/GH-788-PYTHON-PATH-SPACE.md`, approved in `relay-system/2026-09-24/gh788-plan-qa.md` (round 2).
- Changed files: `utils/py/pystub.py` (new); `test/gh788-python-path-space.sh` (new, registered in `validate.sh`); 6 stub writers (`test/gh492-roadmap-state-sweep.sh`, `test/gh648-l2-token-aftermath.sh`, `test/gh648-l4-285-revalidate.sh`, `test/gh648-l5-gh237-repro.sh`, `test/gh648-l6-muse-attribution.sh`, `test/gh666_agy_model_probe.py`); 7 command strings (`utils/py/fuzz_engine.py`, `utils/py/repro_synth.py`, `utils/py/gen4_campaign.py`); gen4 bash suites (`test/gh-gen4-phase3-fuzz-engine.sh`, `test/gh-gen4-phase4-repro-synth.sh`).
- Scope change vs the approved plan: a third form found in verification. The gen4 bash suites passed `--target "$PY …"` with an unquoted `PY=$(command -v python3)`. It is fixed with a shell-quoted `PYQ` and guarded by a third pattern (see the capture doc's "Implementation notes").
- Evidence (producer-run, spaced venv active: `sys.executable=/Users/…/Documents/GH Repos/rebalanceOS/.venv/bin/python3`, commit `a061be40`): `gh492`, `gh648-l2/l4/l5/l6`, `agy-turn`, `gh-gen4-phase3/4/5`, `gh788-python-path-space`, `gh610` — all rc=0. Before the fix, the first 9 were rc=1 on this machine and on pristine `development` `39c2ae6a`. Negative control: with the 13 site edits stashed, `gh788-python-path-space.sh` rc=1 and lists the sites.
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-09-24
- Operational envelope: test fixtures and a local fuzz self-test in a developer CLI repo. Grade proportionately; a new framework, a gate preflight, or migrating gh610's working launcher are out of scope (plan non-goals).
- Definition of Done (the plan's Acceptance):
  1. Every `'#!' + sys.executable` stub writer and every unquoted-interpreter command string (Python f-string or bash `--target "$PY …"`) in `test/ utils/ relay-automation/ skills/` is fixed. None remain, and none were missed.
  2. `pystub.launcher()` is correct: valid sh and Python for ordinary and spaced paths, exact interpreter, works with an empty `PATH`, refuses paths it can't embed. Each site's behaviour is otherwise unchanged (the stub bodies and what the tests assert).
  3. `test/gh788-python-path-space.sh` proves it: runtime cases, a bare-shebang red control, `build_argv` round-trip with its red control, and a ratchet with planted red controls for all three patterns. A scan error fails; safe forms don't match; the only excluded file is the suite itself.
  4. The edits are surgical and DRY: one helper, no second system, no unrelated changes. `validate.sh` registration is present.
  5. The capture doc truthfully records the scope change, the evidence and the rating; the ledger row is `In progress` and rated `75/70/50/70`.
- Questions (cite `file:line`; read-only probes under `.relay-scratch/` allowed, no test runs):
  1. Search for any remaining form of the defect the ratchet can't see, e.g. `sys.executable` interpolated into a shell string by `.format`/`%`, `subprocess(..., shell=True)` with an interpreter path, or other bash `$PYTHON`-style variables fed to `--target`. Name each with `file:line`, or say none found and how you searched.
  2. Is excluding the suite itself (`:(exclude)test/gh788-python-path-space.sh`) the right, minimal carve-out? Could a real site hide there?
  3. Do the six edited stubs keep their original body semantics? (Some previously had the body start on the same line as the shebang's `\n`.)
  4. Is `PYQ` (built with `python3 -c 'print(shlex.quote(sys.executable))'`) the same interpreter the suites used before (`command -v python3`)?
  5. Pre-existing defects in the touched functions/files: name any, or state none found.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
