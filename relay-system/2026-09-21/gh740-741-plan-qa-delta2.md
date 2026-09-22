# RELAY · GH-740/741 plan QA — F6a re-grade (coalesced retry targets) on the revised plan
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-09-21.
-->

NEXT: Producer
STATUS: Approved
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
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(gh740-741-plan-qa-delta2): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: PROJECT/2-WORKING/GH-740-HOSTED-LANE-PUSH-RACE.md at commit a6557c55 — **F6a only** (relay-system/2026-09-21/gh740-741-plan-qa-delta.md round 1). The previous delta round graded a plan whose F6a edit had not been written (Producer error, disclosed in that thread's closing note). F1–F6 are closed and not re-opened unless F6a's text breaks one of them.
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-09-21
- Definition of Done: F6a resolved in the plan text — §1 "Serialisation (F6a)" states that `--pr`/`--commit` are `nargs="+"` store options (`utils/py/wave_reconcile.py:1870-1879`) whose repetition overwrites, that the publisher parses `RECONCILE_ARGS` and emits **one** `--pr` group (original values + every receipt `pr`) and **one** `--commit` group (original values + every receipt `landing_commit`), retaining all other flags; the Requirements row carries the parser-level acceptance (production parser on the built argv for original `--pr 42` + receipts #5/#6 → `['42','5','6']`; red control: repeated-option form → `['5']`) and the original-already-receipted OPEN-reference case; the Risks paragraph's replay-target contract says "coalesced … never a repeated option"; no `dict.fromkeys` dedupe claim remains. Verify each with `grep` against the file at a6557c55. Grade [Must]/[Should]/[Nit]; **Approved** when no [Must] remains; do not widen scope.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

## Reviewer — codex — round 1

VERDICT: PASS
Basis: F6a is resolved in the seeded plan: target values are coalesced before serialization, the original target and multiple receipt targets have parser-level acceptance, and the already-receipted OPEN-reference case is explicit. No Must remains.
swept file: yes

Read the entire 251-line plan and the prior delta relay; checked the parser and explicit-target, recovery, ownership and merge-evidence paths. No additional pre-existing defect within this bounded F6a review was found, and F1–F6 remain closed. Only this relay file is edited (Easy reversibility). No Git commands, suites, executable fixtures or reconciler invocation ran. The seeded artifact is reviewed as supplied; commit a6557c55 attribution comes from Setup, not an independently queried Git object.

- **[Pass] F6a serialization.** `PROJECT/2-WORKING/GH-740-HOSTED-LANE-PUSH-RACE.md:119-127` explicitly states `nargs="+"` store semantics, original PR values plus every receipt PR in **one** group, the corresponding commit group, and “all other original flags are retained verbatim”. This matches the declarations at `utils/py/wave_reconcile.py:1870-1879`; repeated groups overwrite before target construction at `:1981-1982`. No change requested.
- **[Pass] Falsifiable acceptance.** Plan `:74` requires the publisher-built argv to retain #42/#5/#6 in the production parser and preserve merge evidence for an original already-receipted #42 referencing an OPEN issue. Plan `:125-127` gives the exact repeated-option red control and commit analogue. This closes the original-target discovery gap: receipted recovery exclusion at `wave_reconcile.py:1223-1224` and OPEN-issue skip at `:1254-1256` cannot recover an overwritten target. No change requested.
- **[Pass] Consistent bounded replay.** Plan `:203-207` says “coalesced” and “never a repeated option”, limits identities to this run's published receipts, and retains fail-closed handling of missing identity. Whole-file search finds no `dict.fromkeys` claim. Ownership over full metadata remains stated at `:94-95`; the coalescing revision does not alter it. No change requested.

Evidence commands:
```sh
rg -n 'Serialisation|nargs=|original.*values|all other original|production parser|already-receipted|coalesced|never a repeated option|dict.fromkeys' PROJECT/2-WORKING/GH-740-HOSTED-LANE-PUSH-RACE.md
```
Exit **0**; decisive matches at lines 74, 119–125, 204–205 contain the requirements cited above.

Non-mutating parser probe (source-extracted production argument declarations only):
```sh
export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"
python3 - <<'PYPROBE'
import argparse, ast
from pathlib import Path
main = next(n for n in ast.parse(Path('utils/py/wave_reconcile.py').read_text()).body if isinstance(n, ast.FunctionDef) and n.name == 'main')
parser = argparse.ArgumentParser()
nodes = [n for n in main.body if isinstance(n, ast.Expr) and isinstance(n.value, ast.Call) and isinstance(n.value.func, ast.Attribute) and n.value.func.attr == 'add_argument']
assert nodes
for n in nodes:
    exec(compile(ast.Module(body=[n], type_ignores=[]), '<source-parser>', 'exec'), {'parser': parser})
for flag, values in (('--pr', ['42','5','6']), ('--commit', ['a'*40,'b'*40,'c'*40])):
    for targets in ([flag,values[0],flag,values[1]], [flag,*values]):
        args = parser.parse_args(targets + ['--catch-up','--gate','--qualify'])
        print(flag, 'groups='+str(targets.count(flag)), 'targets='+repr(getattr(args,flag[2:])))
s = Path('PROJECT/2-WORKING/GH-740-HOSTED-LANE-PUSH-RACE.md').read_text()
assert s
print('plan lines:', len(s.splitlines()), 'dict.fromkeys present:', 'dict.fromkeys' in s)
PYPROBE
```
Exit **0**. Decisive output: `--pr groups=2 targets=['5']`; `--pr groups=1 targets=['42', '5', '6']`; commit repeated form retains only the b SHA, coalesced form retains all a/b/c SHAs; `plan lines: 251 dict.fromkeys present: False`. Both forms were parsed with the original catch-up/gate/qualify flags. This measures parser semantics, not a built publisher. An initial version of this probe exited **1** while printing `args.gate` (`AttributeError: 'Namespace' object has no attribute 'gate'`); removing that probe-only attribute assumption produced the result above without changing production code.

- **[Unverified — needs clone run]** Publisher-built argv integration, raced publication, original OPEN-reference merge-evidence persistence and zero retry qualification calls remain implementation acceptance. No runtime or merge approval is implied.

Relay closed (Approved), no further turn needed. Producer (claude-a) may proceed with the approved plan; the harness owns the file-scoped commit.


### Attestation · relay-drive — 2026-09-21T22:06:31Z
task: gh740-741-plan-qa-delta2
reviewer: codex
status: Approved
reviewed-head: 6398ebf2083cee58fa9803b2a57d8e89b42d3b8b
added-range: 6184+4730
added-sha256: 13f195327712bb6205663aff7f46346a8efa119413d4fdf026e1025ac1ef64e1
<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
