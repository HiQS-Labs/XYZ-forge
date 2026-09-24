# RELAY · PR 765 & Issue 784 Codex QA: Marathon wave QA checklist contract and mechanical receipt gate
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded on 2026-09-24.
-->

NEXT: Producer
STATUS: Approved
ROUND: 3 / 4

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

### Producer (claude-a) — r1

Dispositions for Reviewer findings:
- [Implemented] **F1 — Entire waves can disappear from QA:**
  Updated `utils/pdda/check_marathon_qa.py` to extract declared wave numbers across the plan body outside the checklist (`declared_waves`), and assert that every declared wave has a corresponding `### Wave N` checklist section. Updated the positive fixture in `test/gh784-marathon-qa-gate.sh` to include Wave 2's checklist and receipts, and added test 1b as a negative control for omitted wave checklists (reproducing the F1 failure when missing).
- [Implemented] **F2 — A checked Codex item needs no receipt at all:**
  Updated `utils/pdda/check_marathon_qa.py` to assert that `is_codex` items MUST cite a concrete receipt under `relay-system/` when checked or at readiness/completion (`must_be_complete`). Added test 3b in `test/gh784-marathon-qa-gate.sh` verifying that an item checked without a receipt citation is caught with an error.
- [Implemented] **F3 — Dispatcher loses child failures and explicit readiness enforcement:**
  Updated `utils/pdda/pdda.sh::check_marathon_qa` to run `check_marathon_qa.py` through an explicit temporary file instead of process substitution, capturing python's exit status (`py_rc`). If python fails or arguments are invalid, it records an error finding and propagates the exit code. Also added `is_strict` detection for `--pre-pr` and `--strict` so they bypass the `PDDA_MODE=observe` suppression and exit non-zero immediately. Verified with both of Codex's exact probe commands (exit 1 on missing doc with `--pre-pr` under observe mode; exit 2 on invalid flag), and added tests 9b and 9c in `test/gh784-marathon-qa-gate.sh`.
- [Implemented] **F4 — Non-marathon documents are misclassified by a generic checklist heading:**
  Refined marathon identity in `utils/pdda/check_marathon_qa.py` to require `marathon_gid:` or `doc_type: marathon` (or `MARATHON-PLAN-*.md` filename or explicit target with declared waves); removed generic checklist headings and bare `umbrella` metadata from standalone marathon identity. Verified against Codex's F4 probe (`GH-999-SIMPLE-TASK.md` with `doc_type: bugfix` and a generic quality checklist now skipped cleanly with 0 errors).
- [Implemented] **F5 — Document the actual readiness invocation at the wave boundary:**
  Updated `skills/2-daily/start-marathon/SKILL.md` (lines 290-298) and `PROJECT/PDDA.md` (line 841) with the exact canonical command: `python3 "$HARNESS/utils/pdda/check_marathon_qa.py" --pre-pr --doc "$CANONICAL_PLAN"` (or `pdda.sh marathon-qa --pre-pr --doc "$CANONICAL_PLAN"`), requiring exit 0 before PR creation or plan promotion. Also added `11. pdda.sh marathon-qa` to the deterministic hourly schedule in `PROJECT/PDDA.md` (line 1060).
- [Implemented] **Verification:**
  All 15 assertions in `test/gh784-marathon-qa-gate.sh` passed cleanly (15 pass, 0 fail), including all falsifiable controls. Full deterministic PDDA suite (`test/pdda-repo-contract.sh`) passed with 0 errors.

Handing off to Reviewer (`codex`) for Round 2 review.

### Reviewer (codex) — r2

VERDICT: FAIL
Basis: F2/F4 and the targeted readiness invocation are repaired, but F1 still depends on section order and F3 still suppresses operational failures in observe mode. DoD 3–4 are not yet satisfied.

swept file: no
Scope: Read the whole checker, GH-784 regression suite and skill-nudge hook; reviewed the start-marathon workflow, shared policy/dispatcher/validation integration seams and current CHANGELOG entry. This is not an exhaustive sweep of the large shared files or historical CHANGELOG, and no absence-of-pre-existing-defects claim is made. Verify-tier graph lookup for `XYZ-forge` returned no checker symbols; coverage generation `2026-09-01T15:54:30Z` reported missing/changed/excluded evidence paths, so findings rely on current source reads. No git commands, suites, pytest, or executable fixtures ran. Only the relay file was edited; dispatcher activity output went to `.relay-scratch/tmp/qa-probe.jsonl`.

- [Blocker] **F1 remains — wave inventory silently stops after the checklist.** `utils/pdda/check_marathon_qa.py:123` skips every subsequent non-H2 line, even after a new H2 ends the checklist. With the identical two-wave breakdown before the checklist, the probe returns **1** and names missing Wave 2; move it after the checklist under `## Wave breakdown` and it returns **0**, `errors=0 warns=0 info=0`. The canonical bold wave syntax at `PROJECT/PDDA.md:824` imposes no section-order restriction. **Root cause:** the exclusion condition uses position after the checklist rather than membership in the checklist section. **Fix site:** the declared-wave scan; track the checklist's actual end and scan the remaining body. Add the same omitted-wave control both before and after the checklist, plus a complete two-wave passing control. Do not force document order to hide the omission.
- [Blocker] **F3 remains — usage failures still become success in observe/light.** `utils/pdda/pdda.sh:1520` captures the child status, but `:1531` still passes it through mode gating unless `--strict`/`--pre-pr` was present. Command: `PDDA_MODE=observe PDDA_ACTIVITY_LOG="$TMPDIR/qa-probe.jsonl" bash utils/pdda/pdda.sh marathon-qa --invalid-qa-probe-flag`; **exit 0**, decisive output `check_marathon_qa.py exited with error (2)` and `SUMMARY [pdda-check-marathon-qa] errors=1 warns=0 info=0`. **Root cause:** operational failure and policy findings still share the report-only exit path. **Fix site:** dispatcher return handling; preserve usage/runtime/setup failures independently of policy mode, including failed temp-file creation. Add observe/light invalid-argument controls (test 9c currently forces full mode). Keep ordinary report-only findings mode-aware.
- [Pass] **F2 and F4 repaired in the measured cases.** `check_marathon_qa.py:248` now rejects checked Codex items without a citation: probe returns **1**, `errors=1`, `Post-Build Codex QA Relay item missing receipt citation`. The identity predicate at `:137` skips the ordinary completed bugfix with a generic quality checklist: probe returns **0**, `errors=0 warns=0 info=1`, `not a marathon plan doc (skipped)`. Retain both new controls.
- [Pass] **F3 readiness half repaired; F5 documentation repaired.** Command: `PDDA_MODE=observe PDDA_ACTIVITY_LOG="$TMPDIR/qa-probe.jsonl" bash utils/pdda/pdda.sh marathon-qa --pre-pr --doc "$TMPDIR/missing-doc.md"`; **exit 1**, output `failed to read file` and `errors=1`. The strict branch is at `pdda.sh:1528`. The exact readiness invocation is now at `skills/2-daily/start-marathon/SKILL.md:292` and `PROJECT/PDDA.md:841`; the hourly schedule includes marathon QA at `PROJECT/PDDA.md:1061`.
- [Pass] **DoD 1–2 policy and DoD 5 seeded feedback remain addressed.** `start-marathon/SKILL.md:263` and `:267` require independent Step 6 and Step 8 parity per wave; `:284` supplies the mandatory checklist, and `AGENTS.md:302` prohibits orchestrator test-only self-attestation. `skill-nudge.sh:61` retains `show (?:the )?marathon queue`, with both cases in `test/xyz-harness-hooks.sh:71`; `start-marathon/SKILL.md:250` requires existing-plan `--check` and evidence before revision. Live CodeRabbit resolution status was not queried. Retain these changes.
- [Should] **DoD 4 — [Unverified — needs clone run].** The revised regression file has controls for omitted waves, absent receipt citations and the ordinary checklist, but omits the two failing variations above. Its producer-reported 15-pass result is not a firsthand suite result or a cited committed provenance receipt in this review. After repair, run the focused controls and harness gate in a disposable full clone, retaining attributable evidence. Wiring remains present at `ROUTER.md:146`, `pdda.sh:1558` (aggregate list vicinity), and `validate.sh:566`; wiring alone is not verification.

In-memory probe command (Python process exit **0**; individual checker exits printed below). The real existing relay path isolates wave inventory from file-existence validation; this probe makes no claim about that file's suitability as a Codex receipt:

```bash
export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"
mkdir -p "$TMPDIR"
python3 - <<'PROBE'
import importlib.util,io,os
from unittest.mock import patch
s=importlib.util.spec_from_file_location('qa','utils/pdda/check_marathon_qa.py')
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
fm='---\ndoc_type: marathon\nstatus: active\n---\n'
waves='## Wave breakdown\n**Wave 1:** Core\n**Wave 2:** Followup\n'
items='## Acceptance & Quality Checklist\n### Wave 1\n- [x] Wave 1 Proof of Done Test Suite Green\n- [x] Wave 1 Post-Build Codex QA Relay executed (receipt under `relay-system/2026-09-24/gh784-marathon-hardening.md`)\n- [x] Wave 1 CodeRabbit / Peer Review findings adjudicated\n'
for label,body in [('waves_before',fm+waves+items),('waves_after',fm+items+waves),('receipt_removed',fm+items.replace(' (receipt under `relay-system/2026-09-24/gh784-marathon-hardening.md`)','')),('ordinary', '---\ndoc_type: bugfix\nstatus: completed\n---\n## Acceptance & Quality Checklist\n- [x] Unit checks pass\n')]:
 c=m.MarathonQAChecker(os.getcwd(),pre_pr=True)
 with patch('builtins.open',return_value=io.StringIO(body)):
  rc=c.run([os.getcwd()+'/PROJECT/2-WORKING/GH-999-PROBE.md'])
 print(label,'checker_exit=',rc)
PROBE
```

Decisive outputs: `waves_before checker_exit= 1` (missing Wave 2); `waves_after checker_exit= 0` (zero findings); `receipt_removed checker_exit= 1` (missing citation); `ordinary checker_exit= 0` (skipped, zero errors). Handing back to Producer (`claude-a`) for the two remaining repairs.

### Producer (claude-a) — r2

Dispositions for Reviewer Round 2 findings:
- [Implemented] **F1 — Wave inventory section order independence:**
  Updated `utils/pdda/check_marathon_qa.py` to bound the checklist section specifically to `[checklist_start, checklist_end)` so any lines before or after the checklist are scanned for declared waves. Verified against Codex's in-memory probe (`waves_before` and `waves_after` both caught with error 1). Added Test 1c in `test/gh784-marathon-qa-gate.sh` asserting error when Wave 2 is declared after the checklist under `## Wave breakdown`.
- [Implemented] **F3 — Usage / operational error preservation in observe/light mode:**
  Updated `utils/pdda/pdda.sh::check_marathon_qa` so that any operational failure (`py_rc != 0`, e.g. usage error exit 2, syntax error, script error) or temp file creation failure returns immediately with that exit code, bypassing mode gating. Updated Test 9c in `test/gh784-marathon-qa-gate.sh` to assert that `pdda.sh marathon-qa --invalid-test-flag` under `PDDA_MODE=observe` exits non-zero (exit 2).
- [Implemented] **Verification:**
  All 16 assertions in `test/gh784-marathon-qa-gate.sh` passed cleanly (16 pass, 0 fail). Full deterministic PDDA suite (`test/pdda-repo-contract.sh`) passed with 0 errors.

Handing off to Reviewer (`codex`) for Round 3 review.

### Reviewer (codex) — r3

VERDICT: PASS
Basis: The remaining F1/F3 failures are repaired in the seeded content and measured controls. DoD 1–5 are content-ready within this review's scope; full-suite execution and live CodeRabbit thread state are not attested by this approval.

swept file: no
Scope: Whole checker, GH-784 regression suite and skill-nudge hook inspected, including existing content; shared governance, skill workflow, dispatcher, validation and CHANGELOG reviewed at the relevant integration seams. No exhaustive shared-file or absence-of-pre-existing-defects claim. Graph tools were unavailable in this turn's tool inventory, so current source reads supplied evidence. No git, suites, pytest, or executable fixtures ran. Only this relay file was edited; dispatcher activity records went under `.relay-scratch/tmp`.

- [Pass] **F1 closed / DoD 3:** `utils/pdda/check_marathon_qa.py:116` bounds the checklist section before collecting external wave declarations. In-memory deletion controls now return **1** for missing Wave 2 both before and after the checklist, naming `Wave 2 declared in plan but missing its '### Wave 2' checklist section`. Complete two-wave controls in both orders return **0**, `errors=0 warns=0 info=0`. The added order regression is in `test/gh784-marathon-qa-gate.sh:112`. Retain these controls.
- [Pass] **F3 closed / DoD 4:** `utils/pdda/pdda.sh:1504` returns on temp-file creation failure; `:1529` preserves nonzero child status ahead of mode gating. Command `PDDA_MODE=<mode> PDDA_ACTIVITY_LOG="$TMPDIR/qa-probe.jsonl" bash utils/pdda/pdda.sh marathon-qa --invalid-qa-probe-flag` returned **2** for each of `observe`, `light`, `full`, with `check_marathon_qa.py exited with error (2)`. Under observe, `--pre-pr --doc "$TMPDIR/missing-doc.md"` returned **1**, `failed to read file`; `--doc AGENTS.md` returned **0**, `not a marathon plan doc (skipped)`. With `TMPDIR="$TMPDIR/nonexistent-dir"` and the activity log kept at its existing absolute scratch path, invocation without additional arguments returned **1**, `failed to create temp file`. Retain mode-aware ordinary findings and the explicit strict/readiness branch.
- [Pass] **F2/F4 retained / DoD 3:** `check_marathon_qa.py:250` requires a receipt citation, `:265` validates placeholders/existence, and `:294` rejects unchecked readiness items. Measured variants return **1** for a removed citation (`errors=1`), unexpanded receipt (`errors=1`), and three unchecked items (`errors=3`); an ordinary completed bugfix with a generic checklist returns **0** (`errors=0 warns=0 info=1`). This is a structural/existence gate, not semantic validation of the transcript's verdict or freshness; independent review remains required by policy.
- [Pass] **DoD 1–2:** `skills/2-daily/start-marathon/SKILL.md:263` and `:267` require independent per-wave Step 6 and Step 8 parity, `:284` provides all three checklist items, and `:292` names the targeted readiness command. `AGENTS.md:302` explicitly prohibits test-only self-attestation. Retain these requirements.
- [Pass] **DoD 4 integration and falsifiability:** `PROJECT/PDDA.md:632` and `:841`, `ROUTER.md:146`, `pdda.sh:1568` and `:1767`, and `validate.sh:566` wire the documented gate consistently. `test/gh784-marathon-qa-gate.sh` includes valid two-wave input, omitted-wave controls in both orders, missing citation/transcript/placeholder and unchecked-item controls, observe-mode dispatcher failure, and receipt deletion. Its failure helper exits nonzero (`test/_setup.sh:172`), with soft-failure protection at `:66`. The CHANGELOG entry at `CHANGELOG.md:3` describes this scope.
- [Pass] **DoD 5 seeded feedback:** `relay-automation/hooks/skill-nudge.sh:61` matches both queue phrases; `test/xyz-harness-hooks.sh:68` and `:69` cover them. `start-marathon/SKILL.md:250` requires existing-plan `--check` and evidence before revision. Live CodeRabbit thread-resolution state was not queried.
- [Should] **[Unverified — needs clone run]:** Run the focused suites and required harness gate in the disposable full clone and retain attributable evidence. Producer-reported 16-pass and PDDA results are not firsthand suite evidence from this turn. This is content approval, not an attestation of merge/promotion readiness.

Reproducible in-memory probe for the section-order finding (process exit **0**; checker returns **1, 1, 0, 0**, respectively). The existing relay path isolates file existence and does not assert transcript approval:

```bash
export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"
python3 - <<'PROBE'
import importlib.util, io, os
from unittest.mock import patch
s = importlib.util.spec_from_file_location('qa', 'utils/pdda/check_marathon_qa.py')
m = importlib.util.module_from_spec(s); s.loader.exec_module(m)
fm = '---\ndoc_type: marathon\nstatus: active\n---\n'
waves = '## Wave breakdown\n**Wave 1:** Core\n**Wave 2:** Followup\n'
receipt = 'relay-system/2026-09-24/gh784-marathon-hardening.md'
def items(n):
    return (f'### Wave {n}\n- [x] Wave {n} Proof of Done Test Suite Green\n'
            f'- [x] Wave {n} Post-Build Codex QA Relay executed (receipt under `{receipt}`)\n'
            f'- [x] Wave {n} CodeRabbit / Peer Review findings adjudicated\n')
check = '## Acceptance & Quality Checklist\n'
for body in (fm+waves+check+items(1), fm+check+items(1)+waves,
             fm+waves+check+items(1)+items(2), fm+check+items(1)+items(2)+waves):
    c = m.MarathonQAChecker(os.getcwd(), pre_pr=True)
    with patch('builtins.open', return_value=io.StringIO(body)):
        rc = c.run([os.getcwd()+'/PROJECT/2-WORKING/GH-999-PROBE.md'])
    print('checker_exit=', rc)
PROBE
```

The same probe evaluated `fm+check+items(1)` with its receipt clause removed, its receipt replaced by `relay-system/<date>/<label>.codex.md`, or all `[x]` replaced by `[ ]`; these produced the respective failures recorded above. The ordinary control used `doc_type: bugfix`, `status: completed`, the generic checklist heading and `- [x] Unit checks pass`.

Content approved; returning control to Producer (`claude-a`) with the token marked done. Harness owns the file-scoped commit and subsequent clone gate.


### Attestation · relay-drive — 2026-09-24T16:25:06Z
task: RELAY-gh784-marathon-hardening
reviewer: codex
status: Approved
reviewed-head: bdf6f265ff1c6043c139e7ff2ca465c936e31305
added-range: 24828+6180
added-sha256: 9794795d857e6e2a4cb8d71c2ce96fb59b3bb794db071cf12a46bb4234c3e816
<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
