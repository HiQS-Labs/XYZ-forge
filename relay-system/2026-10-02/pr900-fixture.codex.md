# RELAY · PR900 day02 fixture correction QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-02.
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
6. **Commit only the relay file** (`relay(pr900-day02-fixture-correction-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **pr900-fixture-qa.md** (embedded below — read it here).
- Reviewer: codex   ·   Producer: codex-producer
- Started: 2026-10-02

### Artifact — pr900-fixture-qa.md
```
Narrow independent follow-up QA on one-line test correction at 7e088c84. Prior source/ledger QA is Approved in relay-system/2026-10-01/pr900-merge.codex.md. The only new non-receipt delta is test/test_deploy_skills.py:272: replace next archive not ending -02.zip with min archives by filename length. Actual existing suite failed StopIteration on UTC day02 because sample-2026-10-02.zip and sample-2026-10-02-02.zip both end -02.zip. Confirm prior expression fails on those two names (scratch memory red control) and corrected expression selects first archive on any date; read entire existing test method and archive naming implementation skills/3-weekly/skills-army-hq/scripts/intake.py:326. Does this retain meaningful roundtrip verification and fix only the test? No new tests/gates. Focused existing 3 shell suites plus Python21/21 passed with inherited XYZ_HARNESS,XYZ_SKILLS_ROOT,XYZ_FORGE_ROOT,TICK_REPO_ROOT unset. Full clean-environment Small rerun underway separately. Only relay writable. Cite exact observed names, lines and output; VERDICT PASS/FAIL, swept file: yes. Approve if no concrete blocker. Do NOT reopen already approved unrelated source review; scope is the fixture followup. Close token with tick done on approval.
```
- Definition of Done: _<fill in the acceptance criteria the Reviewer grades against>_

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log


### Reviewer · Round 1
VERDICT: PASS
Basis: The day02 failure is reproduced in memory, and the corrected selection retains the original archive roundtrip assertion. No concrete blocker or additional pre-existing defect found in the swept test file within this fixture-followup scope; prior unrelated source/ledger approval is not reopened.
swept file: yes

- [Pass] Date-independent selection: `test/test_deploy_skills.py:272` uses `min(archives, key=lambda p: len(p.name))`. Archive naming at `skills/3-weekly/skills-army-hq/scripts/intake.py:331-339` gives the first archive no collision suffix and appends `-02` to the second. Exact observed names were `sample-2026-10-02.zip` and `sample-2026-10-02-02.zip`. The old predicate fails on both; the current expression selects the unsuffixed archive. Fix: none.
  Probe command (in-memory only; no fixture imported or executed):
  ```sh
  export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"
  mkdir -p "$TMPDIR"
  python3 -B - <<'PYPROBE'
import ast
from pathlib import Path
from datetime import date, timedelta
tree = ast.parse(Path("test/test_deploy_skills.py").read_text())
method = next(n for n in ast.walk(tree) if isinstance(n, ast.FunctionDef) and n.name == "test_a2_archives_round_trip_and_same_day_collisions")
selection = next(n.value for n in method.body if isinstance(n, ast.Assign) and any(isinstance(t, ast.Name) and t.id == "first" for t in n.targets))
code = compile(ast.Expression(selection), "<current-line-272>", "eval")
archives = [Path("sample-2026-10-02.zip"), Path("sample-2026-10-02-02.zip")]
print("names:", [p.name for p in archives])
try:
    next(p for p in archives if not p.name.endswith("-02.zip"))
except StopIteration:
    print("OLD: StopIteration (witnessed red control)")
else:
    raise AssertionError("red control did not fail")
print("CURRENT:", eval(code, {"archives": archives}).name)
count = 0
for year in (2026, 2028):
    day = date(year, 1, 1)
    while day.year == year:
        stem = f"sample-{day.isoformat()}"
        pair = [Path(f"{stem}{'' if index == 1 else '-' + str(index).zfill(2)}.zip") for index in (1, 2)]
        for order in (pair, pair[::-1]):
            assert eval(code, {"archives": order}) == pair[0], pair
        count += 1
        day += timedelta(days=1)
print(f"CURRENT: {count} valid dates, both input orders select unsuffixed first archive")
PYPROBE
  ```
  Exit status: 0. Decisive output:
  ```text
names: ['sample-2026-10-02.zip', 'sample-2026-10-02-02.zip']
OLD: StopIteration (witnessed red control)
CURRENT: sample-2026-10-02.zip
CURRENT: 731 valid dates, both input orders select unsuffixed first archive
  ```
  The general date claim follows from fixed-width ISO dates and a strictly longer collision suffix; the probe samples all valid dates in a common and leap year. It assumes the existing same-day fixture completes within one UTC day.
- [Pass] Meaningful roundtrip retained: `test/test_deploy_skills.py:265` captures the original snapshot before updates; `:270` requires two archives; `:276-290` checks CRC, confines extraction, restores bytes/link targets/modes, and compares the restored snapshot to that original. The fixture at `:76-79` includes an executable file and a symlink. Selecting the second archive would restore version 2 instead of the original payload, so the final snapshot equality remains discriminating. Fix: none.
- [Pass] The entire embedded artifact and all 625 lines of `test/test_deploy_skills.py` were read, including the complete method at `:262-293` and archive naming implementation at `intake.py:326-364`. No new tests or gates are proposed. Graph-first discovery was attempted: nearest available project `XYZ-forge` points to a different checkout, generation `2026-09-01T15:54:30Z`; both candidate paths returned freshness `not_tracked` and the symbol query returned zero results. All material conclusions therefore use current local source, not that stale graph. Fix: none.
- [Unverified — needs clone run] The embedded artifact reports focused shell/Python passes and a Small rerun underway. Those executions were not independently reproduced here; no validate/test/pytest or executable fixture was run. Harness gate evidence remains separate from this narrow expression/source approval.

NEXT: Producer (codex-producer). Relay closed (Approved), no further turn needed; harness owns the file-scoped commit and subsequent gate.


### Attestation · relay-drive — 2026-10-02T07:04:28Z
task: RELAY-pr900-fixture
reviewer: codex
status: Approved
reviewed-head: 1bd4d88d7dfc6a0792e35e7e184eafa18ba6740c
added-range: 6532+4420
added-sha256: ff2a77a5ab5e58aaa2751cd9ec8bf84f79e5e423d7a0f5053e994d888fa41ad0
<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
