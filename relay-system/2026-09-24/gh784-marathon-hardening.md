# RELAY · PR 765 & Issue 784 Codex QA: Marathon wave QA checklist contract and mechanical receipt gate
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded on 2026-09-24.
-->

NEXT: Producer
STATUS: Open
ROUND: 1 / 4

## ▶ TAKE YOUR TURN — read this first (works for ANY agent: Claude, Codex, agy)
1. **Read this whole file** (header, Setup, Ground rules, every block in the Log).
2. **Check it's your turn:** `NEXT` (top) names the role to act. Confirm you are bound to it and the
   last Log block isn't already yours. If not → STOP and reply "wrong window — nudge the <other> window."
3. **Do your role's work** on the artifact named in Setup:
   - **Reviewer:** review vs the Definition of Done → graded findings
     (`[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`), each with a concrete fix → set a **VERDICT**
     (exactly PASS, FAIL, or PARKED) and a **Basis** (explanation). **Review the whole file, not just the diff** (GH-268):
     Pre-existing defects in a file you are touching are IN SCOPE; if you find none, say so explicitly rather than leaving it unstated.
     **Declare it: every review block must contain a literal `swept file: yes` or `swept file: no` line.**
     Any `[Pass]` or "verified"/"confirmed" finding MUST carry a quoted span or a `file:line` citation.
     Do **not** edit the artifact; only append findings here.
   - **Producer:** log a disposition for every open finding, make the change, then add new work.
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns.
   Reviewer headings may be `### Reviewer (codex) — r1` or `### Reviewer — Round N (codex)`; follow the heading with a non-empty review body.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(gh784-marathon-hardening): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268).

## Setup
- Artifact under review: PR #765 and GH-784 marathon hardening; inspect `skills/2-daily/start-marathon/SKILL.md`, `AGENTS.md`, `PROJECT/PDDA.md`, `ROUTER.md`, `utils/pdda/check_marathon_qa.py`, `utils/pdda/pdda.sh`, `test/gh784-marathon-qa-gate.sh`, `relay-automation/hooks/skill-nudge.sh`, `test/xyz-harness-hooks.sh`, `validate.sh`, and `CHANGELOG.md`.
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-09-24
- Operational envelope: local developer CLI & repo governance; no runaway abstraction or unrequested enterprise multi-tenant machinery. Read-only review; no `validate.sh`, `test/*.sh`, pytest, or executable fixtures in the relay worktree. Use narrow static inspection and committed evidence. Keep any scratch under `.relay-scratch/` after setting `PYTHONDONTWRITEBYTECODE=1` and `TMPDIR` there.
- Definition of Done: decide whether the GH-784 hardening improvements and CodeRabbit comment resolutions are content-ready and architecturally sound. Explicitly answer:
  1. Does `skills/2-daily/start-marathon/SKILL.md` properly mandate Step 6 (Wave Plan QA) and Step 8 (Post-Build Codex QA Relay) parity per wave, and enforce the Acceptance & Quality Checklist contract?
  2. Does `AGENTS.md` clearly codify Orchestrator vs Review Protocol Separation (prohibiting orchestrators from self-attesting review by only observing passing tests)?
  3. Is `utils/pdda/check_marathon_qa.py` surgical, DRY, and robust against false positives on non-marathon docs while strictly flagging missing wave items, missing/unexpanded transcripts, and unverified checklist items on PR readiness?
  4. Are `PROJECT/PDDA.md`, `ROUTER.md`, and `utils/pdda/pdda.sh` properly updated in lockstep, and does `test/gh784-marathon-qa-gate.sh` provide falsifiable verification?
  5. Are CodeRabbit review feedback items properly addressed (skill-nudge pattern and marathon-plan.sh --check)?
  Give `VERDICT: PASS` or `FAIL` with `Basis:` and cited findings. `STATUS: Approved` only for PASS; otherwise hand back specific repairs.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer (codex) — r1

VERDICT: FAIL
Basis: The policy language is sound, but the mechanical gate can approve an omitted wave or an absent receipt, and its dispatcher can turn failures into success. These violate DoD 3–4; content is not ready for approval.

swept file: no
Scope: Read the complete checker, start-marathon skill, new GH-784 regression suite, and skill-nudge hook, including existing content. Reviewed the shared governance/dispatcher/validation files at their integration seams and the current CHANGELOG entries; this is not an exhaustive sweep of those large shared files or historical CHANGELOG. No blanket absence-of-pre-existing-defects claim. Graph lookup used `XYZ-forge` generation `2026-09-01T15:54:30Z`; no index matched this worktree, checker lookup returned zero nodes, and coverage reported missing/changed/excluded paths, so findings use current source reads instead. No git commands, test suites, pytest, or executable fixtures ran. Only this relay file was edited; probe logging was redirected into `.relay-scratch/tmp`.

- [Blocker] **F1 — Entire waves can disappear from QA.** `utils/pdda/check_marathon_qa.py:143` builds the wave inventory only inside the checklist, and `:202` iterates that inventory without comparing it with the plan's declared waves. A plan declaring Waves 1 and 2 with only Wave 1's complete checklist returns `errors=0` and exit 0 under `pre_pr=True` (probe below). The purported valid regression fixture already contains this defect: `test/gh784-marathon-qa-gate.sh:49` declares two waves but `:55` supplies only Wave 1 and `:63` expects success. **Fix:** derive expected waves from the canonical wave breakdown and reject a missing wave checklist; make the positive fixture complete and add a deletion-to-red control for a whole wave.
- [Blocker] **F2 — A checked Codex item needs no receipt at all.** `utils/pdda/check_marathon_qa.py:178` makes extraction optional, and `:226` skips all receipt validation when no path was found. A single-wave checklist with `- [x] Wave 1 Post-Build Codex QA Relay executed` and no transcript reference passes `pre_pr=True` with zero findings (probe below). **Fix:** require a concrete receipt on the Codex item when checked or at readiness/completion; keep unchecked in-progress placeholders permissible. Add a control that removes only the receipt reference from an otherwise valid item and expects failure.
- [Blocker] **F3 — Dispatcher loses child failures and explicit readiness enforcement.** `utils/pdda/pdda.sh:1502` uses process substitution without collecting Python's exit status, then `:1505` applies the ordinary mode gate even when `--pre-pr` or `--strict` was requested. Probe command (after `export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"`): `PDDA_MODE=observe PDDA_ACTIVITY_LOG="$TMPDIR/qa-probe.jsonl" bash utils/pdda/pdda.sh marathon-qa --pre-pr --doc "$TMPDIR/missing-doc.md"`; **exit 0**, decisive output `ERROR ... failed to read file` and `SUMMARY [pdda-check-marathon-qa] errors=1 warns=0 info=0`. Second command: `PDDA_MODE=full PDDA_ACTIVITY_LOG="$TMPDIR/qa-probe.jsonl" bash utils/pdda/pdda.sh marathon-qa --invalid-qa-probe-flag`; **exit 0**, output `error: unrecognized arguments: --invalid-qa-probe-flag` followed by `SUMMARY ... errors=0 warns=0 info=0`. **Fix:** capture the child status explicitly, preserve operational/usage failures, and honor explicit `--pre-pr`/`--strict` independently of routine observe/light behavior. Add dispatcher-level tests for both cases and a valid zero-finding control.
- [Should] **F4 — Non-marathon documents are misclassified by a generic checklist heading.** `utils/pdda/check_marathon_qa.py:125` treats `## Acceptance & Quality Checklist` alone as marathon identity. A completed `GH-999-SIMPLE-TASK.md` with `doc_type: bugfix` and one checked unit-test item produces three mandatory-wave errors and exit 1 (probe below), despite having no marathon metadata, waves, or filename. This reaches all working/completed Markdown via `:267`. **Fix:** establish marathon identity independently of the checklist heading (and avoid generic `umbrella` metadata alone as identity), then validate its checklist. Extend the non-marathon regression to include an ordinary quality checklist.
- [Should] **F5 — Document the actual readiness invocation at the wave boundary.** `skills/2-daily/start-marathon/SKILL.md:290` and `PROJECT/PDDA.md:841` promise a before-PR gate, but give only the checker/subcommand name; the skill's wave lifecycle never instructs a `--pre-pr --doc <canonical-plan>` invocation. Routine active-document checking intentionally only warns (`check_marathon_qa.py:249`). **Fix:** make the exact targeted readiness command and required exit 0 an explicit wave sign-off step after F3 is repaired; distinguish this from the routine aggregate scan. Also update `PROJECT/PDDA.md:1046`'s schedule, which still says the ten-check list is exactly what `pdda.sh run` executes although `pdda.sh:1535` now adds marathon QA.
- [Pass] **DoD 1–2, policy wording:** `skills/2-daily/start-marathon/SKILL.md:263` mandates independent pre-build Step 6 parity; `:267` mandates committed-diff post-build Codex Step 8 parity before pushes/PRs; `:284` supplies the three required per-wave items. `AGENTS.md:302` explicitly prohibits self-attestation by observing tests and requires an independent recorded QA turn. Retain these requirements; F1–F3 concern enforcement, not the stated policy.
- [Pass] **DoD 5, seeded CodeRabbit fixes:** `skill-nudge.sh:61` matches both queue phrases, and `test/xyz-harness-hooks.sh:71` supplies both examples. Direct read-only probe command: Python `subprocess.run(["bash", "relay-automation/hooks/skill-nudge.sh"], input=json.dumps({"prompt": p}), text=True, capture_output=True)` for `p` equal to `Show the marathon queue`, `Show marathon queue`, and `Show the release queue`. All exits **0**; first two emitted `BTW: start-marathon already does this` with `skills/2-daily/start-marathon/SKILL.md`, negative control emitted **nothing**. `start-marathon/SKILL.md:250` requires checking an existing plan first and prohibits automatic regeneration on drift. These address the two named feedback items in the seeded content; live CodeRabbit thread-resolution status was not queried.
- [Should] **DoD 4, verification remains incomplete — [Unverified — needs clone run].** Wiring exists at `ROUTER.md:146`, `PROJECT/PDDA.md:632`, `pdda.sh:1734`, and `validate.sh:566`. The receipt-deletion control at `test/gh784-marathon-qa-gate.sh:272` is falsifiable in design, but the two-wave positive fixture blesses missing QA (F1), and dispatcher tests at `:255` omit explicit readiness under observe mode and child failures. Repair these controls and run the focused suites plus the required harness gate in a disposable full clone. No suite-green or mutation-run claim is made here.

Probe receipt for F1/F2/F4 (in-memory inputs only; no executable fixture files). Commands executed with `PYTHONDONTWRITEBYTECODE=1`; the equivalent consolidated command below imports the seeded checker and substitutes only its document read:

```bash
export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"
python3 - <<'PROBE'
import importlib.util, io, os
from unittest.mock import patch
s = importlib.util.spec_from_file_location('qa', 'utils/pdda/check_marathon_qa.py')
m = importlib.util.module_from_spec(s); s.loader.exec_module(m)
root = os.getcwd()
base = ('---\ndoc_type: marathon\nstatus: active\n---\n'
        '**Wave 1:** Core\n**Wave 2:** Followup\n'
        '## Acceptance & Quality Checklist\n### Wave 1\n'
        '- [x] Wave 1 Proof of Done Test Suite Green\n'
        '- [x] Wave 1 Post-Build Codex QA Relay executed\n'
        '- [x] Wave 1 CodeRabbit / Peer Review findings adjudicated\n')
receipt = ' (receipt recorded under `relay-system/2026-09-24/gh784-marathon-hardening.md`)'
cases = [
    ('F1', 'PROJECT/2-WORKING/MARATHON-PLAN-PROBE.md',
     base.replace('Relay executed', 'Relay executed' + receipt)),
    ('F2', 'PROJECT/2-WORKING/MARATHON-PLAN-PROBE.md',
     base.replace('**Wave 2:** Followup\n', '')),
    ('F4', 'PROJECT/3-COMPLETED/GH-999-SIMPLE-TASK.md',
     '---\ndoc_type: bugfix\nstatus: completed\n---\n'
     '## Acceptance & Quality Checklist\n- [x] Unit checks pass\n')]
for label, path, body in cases:
    checker = m.MarathonQAChecker(root, pre_pr=True)
    with patch('builtins.open', return_value=io.StringIO(body)):
        rc = checker.run([root + '/' + path])
    print(label, 'checker_exit=', rc)
PROBE
```

Observed decisive results (Python probe processes exited **0**, and the checker returns were printed separately): F1 `errors=0 warns=0 info=0`, checker exit **0**; F2 same, checker exit **0**; F4 `errors=3 warns=0 info=0`, checker exit **1**, naming missing Proof of Done, Codex QA Relay, and peer adjudication. The existing relay path in F1 isolates wave coverage from path-existence checking; it is not asserted to be a valid review receipt.

Handoff: Producer (`claude-a`) to repair F1–F5, extend the regression controls, and return with clone-run evidence. STATUS remains Open.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
