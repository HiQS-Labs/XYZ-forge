# RELAY · GH-1580 final QA round 4 (F8 only)
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-11-23.
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
     A `[Blocker]` must cite an observed failure.
     A finding from an earlier round stays open, and the verdict stays failing, until new evidence closes it.
     This includes earlier [Nit] findings; only a newly raised [Nit] with VERDICT: PASS on STATUS: Approved remains optional.
     This is a protocol rule, not a mechanical check —
     the Producer may disposition a request lacking these as `Declined — unproven generalization`.
   - **Producer:** log a disposition for every open finding (Implemented / Modified / Declined + why,
     including `Declined — unproven generalization` for a behaviour-change request that carries no
     `Observed input:` / `Affected scope:` / `Falsifier:`), make the change, then add new work.
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
   Reviewer headings may be `### Reviewer · Round N`, `### Round N · Reviewer · <agent>`, `### Reviewer (<agent>)` (optionally followed by `— rN`), or `### Reviewer — Round N` (optionally followed by `(<agent>)`); follow the heading with a non-empty review body.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Manual relay: commit only the relay file** (`relay(gh1580-final-qa-r4): <role> r<N>`); no push.
   **Driven turn (relay-drive, marathon): do not run git — the harness commits the turn.** **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. (The window wording is
   for a manual relay; in a driven turn, name the next role.) The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **.relay-artifacts/gh1580-final.diff** — the read-only path that
  `relay-drive.sh --artifact-file /private/tmp/claude-501/-Users-noelsaw-Documents-GH-Repos-XYZ-forge/d67c8fc2-b01d-447c-9384-355c25b46faa/scratchpad/gh1580-final.diff` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-11-23
- Definition of Done: F8 is closed, and the plan's `## Acceptance` list in `PROJECT/2-WORKING/GH-1580-PREFLIGHT-MISREPORTS-GAPS.md` is satisfied by the committed change with substantiating evidence under `TESTS-RESULTS/2026-11-23+GH-1580/`. Nothing is deferred (preflight is a gate surface).

## Authority and history (read first)

This is **round 4**, the one extra round the operator authorized, limited to F8: GitHub comment https://github.com/HiQS-Labs/XYZ-forge/issues/1580#issuecomment-7114054883 ("Operator decision 2026-11-23": one extra repair + final-QA round, limited to F8, refresh the clone-identity evidence; if round 4 fails, #1580 parks). The prior thread is `relay-system/2026-11-23/gh1580-final-qa.md` (rounds 1-3, STATUS Escalated at its cap): F1-F4 and F5-F7 were repaired and you closed them in rounds 2 and 3; F8 was the only open finding. Read that thread's Round 3 Reviewer block and the Producer Round 3 handback for the finding and recipe.

## Review brief

**Step 0 - paraphrase first.** Before reading source, write **What this changes** and **How the existing system works** (2-5 sentences each) from the plan doc alone; then review source-backed.

**What changed since your round 3.** Commit 940d58499: `_gate_tokens`' fold pass now treats a command position as "after an operator, or after control-prefix words only" (`if`, `elif`, `while`, `until`, `!`, `time`, `then`, `do`, `{`), so `[[ a && b ]]` / `(( … ))` there is one skipped word; the commands after `]]` are still checked. New controls D2w (your exact failing shape, fixture form), D2x (a missing command inside the same if-block is still found), D2y (`if ! [[ a && b ]]`). Evidence regenerated: red at 5f51d28c8 (`outputs/prerepair-r3.txt`, 33/3: D2w D2x D2y red) and green at the new head (`outputs/green.txt`, 36/0); suites and the 129-contract replay re-run at the repaired head in a fresh disposable full clone with a complete identity bracket (HEAD, origin, core.bare, local user.name/user.email, clean tree; before and after, unchanged) in `outputs/existing-suites.txt`.

**Operational envelope.** Local developer CLI/harness code. Grade against the requirements, commensurate complexity and this repo's rules: no new tests/suites/gates (GH-831), Python authoritative and the Bash twin FROZEN (GH-308), `githooks/` untouched. Challenge over-building; prefer conservative skips over more shell machinery.

**Read:** the seeded diff `.relay-artifacts/gh1580-final.diff`, then `utils/py/swarm_preflight.py` (`_gate_tokens` fold pass, `_gate_program_gap`, `gate_command_gap`, `eval_probes`, `acceptance_gaps`, evaluate_candidate wiring), the plan doc, `TESTS-RESULTS/2026-11-23+GH-1580/{manual-check.md,controls.sh,provenance.jsonl,outputs/*}`. Measure with narrow read-only probes under `.relay-scratch/`; do not run suites.

**Questions (cite file:line):**
1. Is F8 closed for your exact input and its positive/negative controls (`true && if [[ -f validate.sh && -f ROUTER.md ]]; then bash -n validate.sh; fi` no gap; `... then gh1580_absent_command; fi` reports the missing command)? Do F1-F7 controls stay green?
2. Any new false NOT-READY or false no-gap introduced by the changed fold pass (e.g. `[[` as an argument, nested `if`, `elif`, `while`/`until`, `{ [[ … ]]; }`)? Give the exact input and observed output; do not assert general shell correctness.
3. Does the evidence substantiate the claims (provenance hashes non-empty and matching, MATCH/MISMATCH counts, source hash vs green.txt, the complete identity bracket, the 129-contract replay)? Anything claimed but unverified? The full `validate.sh` gate is intentionally not run at this stage (it runs once at push via the pre-push hook, GH-1518); say so rather than treating it as a defect.
4. Acceptance 1-5 of the plan: satisfied? Any finding must carry `Observed input:`, `Affected scope:`, `Falsifier:` if it asks for a behaviour change.

Include `swept file: yes|no`, a VERDICT (PASS/FAIL/PARKED) with Basis, and set STATUS Approved only if ready to ship.
## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). In a manual relay, end each turn by committing just this file; no push. In a driven turn the harness commits.

## Log

### Reviewer · Round 1 · codex (final QA round 4)

**What this changes (plan-only paraphrase, recorded before source review).** Preflight matches probe anchors per line, checks statically resolvable commands throughout a gate, and reports missing acceptance sections without changing verdict policy. This round addresses F8: expressions after control words must be skipped as expressions while subsequent commands remain checked.

**How the existing system works (plan-only paraphrase).** Python preflight combines probe, gate and acceptance checks into readiness consumed by the harness. Gate checks inspect command text without executing it and conservatively skip unresolved shell constructs; Marathon shares the probe evaluator, while Jog and the orchestration skills consume its verdicts.

swept file: yes

**Block for this no-deferral gate review.** Read all 2,462 lines of `utils/py/swarm_preflight.py`, the seeded diff, complete contract example and changed GH-343 suite, plan, controls and retained evidence. Graph tools are unavailable; direct source reads and AST-isolated probes supplied evidence. No git, test suite, pytest, executable fixture or gate ran; Bash was invoked only with `-n -c` to parse the four quoted probe strings. No unrelated pre-existing defect was established. Only this relay file was edited.

- **[Pass] The original F8 input is repaired; its required negative control remains effective.** `true && if [[ -f validate.sh && -f ROUTER.md ]]; then bash -n validate.sh; fi` now returns `''`; replacing the body with `gh1580_absent_command` returns `"command 'gh1580_absent_command' not found in PATH"`. Both files exist. The unprefixed expression, single-predicate `if`, and `if ! [[ … ]]` controls also return `''`. The changed command-position predicate is at `utils/py/swarm_preflight.py:676-685`. Retained CLI evidence discriminates the repair: `outputs/prerepair-r3.txt:112-122` has D2w/D2x/D2y MISMATCH, whereas `outputs/green.txt:112-122` has all three MATCH. All `outputs/` paths in this block are under `TESTS-RESULTS/2026-11-23+GH-1580/`.

- **[Should] F8 follow-up — a quoted closing-delimiter value still ends the expression early and produces the same false refusal.** Quote removal at `utils/py/swarm_preflight.py:643-650` loses the distinction between the literal string `"]]"` and the closing token. The fold at `:683` selects that literal as the terminator, exposing the expression's internal `&&` and then treating `-f` as a command. The gap becomes NOT-READY at `:2084-2088`. This is a remaining boundary defect in the F8 expression skip, not a request to execute or generally interpret shell code. Preserve enough lexical information to distinguish a quoted delimiter (or conservatively skip the uncertain expression), and keep checking the command after the actual expression. No new suite or parser subsystem is requested.
  Observed input: `true && if [[ "]]" && -f validate.sh ]]; then bash -n validate.sh; fi` returns `"command '-f' not found in PATH"`. `/bin/bash -n -c` accepts that exact input with exit **0**, empty stderr; `validate.sh` exists. Changing only `"]]"` to `"value"` returns `''`. The expression is a nonempty literal string AND an existing-file predicate; all actual commands resolve. The probe process exited **0**.
  Affected scope: a supported `[[ … ]]` expression containing a quoted literal `]]` before an internal command-looking operator, including the newly supported `if [[ … ]]` position. This case is outside the 36 retained controls; their green result does not establish it.
  Falsifier: the exact input must return no gap; the identical conditional with body `gh1580_absent_command` must report that missing command, not `-f`. The `"value"` control and original D2w/D2x/D2y results must remain unchanged. The quoted case currently reports `-f` even when its body is the missing-command control.

**Reproducible boundary probe — executed here, exit 0.** No gate string was executed. Decisive output: the first and third inputs below each printed `SYNTAX_RC 0 STDERR ''` and `GAP "command '-f' not found in PATH"`; the second printed `GAP ''`; the fourth printed `GAP "command 'gh1580_absent_command' not found in PATH"`. The first token dump contains `('word', '[[', True), ('op', '&&', False), ('word', '-f', False)`, showing the premature fold directly.

```bash
export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"
python3 - <<'PY'
import ast, os, re, shutil, subprocess
from pathlib import Path
from typing import Any
p=Path('utils/py/swarm_preflight.py')
ns=dict(os=os,re=re,shutil=shutil,Any=Any)
nodes=[n for n in ast.parse(p.read_text()).body if isinstance(n,ast.FunctionDef) and n.name in {'_gate_tokens','_gate_program_gap','gate_command_gap'} or isinstance(n,ast.Assign) and any(isinstance(t,ast.Name) and (t.id.startswith('_GATE_') or t.id=='Tok') for t in n.targets)]
exec(compile(ast.Module(body=nodes,type_ignores=[]),str(p),'exec'),ns)
for c in [
 'true && if [[ "]]" && -f validate.sh ]]; then bash -n validate.sh; fi',
 'true && if [[ "value" && -f validate.sh ]]; then bash -n validate.sh; fi',
 'true && if [[ "]]" && -f validate.sh ]]; then gh1580_absent_command; fi',
 'true && if [[ -f validate.sh && -f ROUTER.md ]]; then gh1580_absent_command; fi',
]:
 r=subprocess.run(['/bin/bash','-n','-c',c],capture_output=True,text=True)
 print('INPUT',repr(c),'SYNTAX_RC',r.returncode,'STDERR',repr(r.stderr))
 print('TOKENS',ns['_gate_tokens'](c))
 print('GAP',repr(ns['gate_command_gap'](c,str(Path.cwd()))))
PY
```

- **[Pass] The requested neighboring command positions do not swallow subsequent commands in the measured cases.** AST-isolated `gate_command_gap(input, str(Path.cwd()))` calls (Python exit **0**, same extraction as above) returned `"command 'gh1580_absent_command' not found in PATH"` for each exact input below. This supports these cases only, not general shell correctness (`utils/py/swarm_preflight.py:681-689,698-717`).

```text
echo [[ && gh1580_absent_command
echo if [[ && gh1580_absent_command
if [[ a && b ]]; then if [[ c && d ]]; then gh1580_absent_command; fi; fi
if false; then true; elif [[ a && b ]]; then gh1580_absent_command; fi
while [[ a && b ]]; do gh1580_absent_command; done
until [[ a && b ]]; do gh1580_absent_command; done
{ [[ a && b ]]; gh1580_absent_command; }
if (( 1 && 2 )); then gh1580_absent_command; fi
```

- **[Pass] F1–F7 remain closed for their demonstrated cases.** The same read-only helper probe (exit **0**) returned no gap for `false && cd utils && true || bash -n validate.sh`, `true && bash -n validate.sh>/dev/null`, assignment-prefixed `cd utils` followed by `bash -n pdda/pdda.sh`, and `true && bash -s ignored-argument </dev/null`. Missing-script operands followed by `-c` or `-s` still report the missing script; assignment-prefixed `cd utils` followed by `bash -n validate.sh` reports the absent `utils/validate.sh`. A quoted heredoc body is skipped and a following missing command is found. `eval_probes` reports absent `ROADMAP.md` as `landed`, stale=1, blocked=0, and present `validate.sh` as `unfixed` (`utils/py/swarm_preflight.py:271,605-612,728-730,803-833`). Retained witnesses remain green at `outputs/green.txt:52-98`.

- **[Pass] Receipt integrity and the requested clone-identity repair are substantiated.** The command below exited **0**: every one of eight outputs printed nonempty/hash-match **True True**. MATCH/MISMATCH counts are red **15/21**, prerepair-r1 **22/14**, prerepair-r2 **26/10**, prerepair-r3 **33/3**, green **36/0**, mutant **33/3**, agreeing with `provenance.jsonl:1-8`. The full source hash is `5136eca468f4e5b4b609ae51d91ac9c79053e6e7441ca8cc1d842467845ab815`, matching the recorded prefix in `outputs/green.txt:1`. The corpus has **129** paired rows; only GH-269 changes rc 6 to 4, with the same readiness=0 warning (`outputs/corpus-sweep.txt:147-148`). `outputs/existing-suites.txt:2,23` now records identical HEAD, origin, core.bare=false, local user.name/user.email=(unset), and clean tree before/after; lines 3-20 report 17 passing shell suites and 21 Python tests. The former missing-local-identity/before-bare evidence limitation is closed. These are inspected retained receipts, not a claim that this reviewer reran the suites or proved commit ancestry.

```bash
export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"
python3 - <<'PY'
import hashlib,json
from pathlib import Path
p=Path('TESTS-RESULTS/2026-11-23+GH-1580')
for r in map(json.loads,(p/'provenance.jsonl').read_text().splitlines()):
 b=(p/r['output']).read_bytes()
 print(r['output'],bool(b),hashlib.sha256(b).hexdigest()==r['output_sha256'],b.count(b'[MATCH]'),b.count(b'[MISMATCH]'))
print('source',hashlib.sha256(Path('utils/py/swarm_preflight.py').read_bytes()).hexdigest())
rows=(p/'outputs/corpus-sweep.txt').read_text().splitlines()
pairs=[(a.split('|',2),b.split('|',2)) for a,b in zip(rows[::2],rows[1::2])]
assert len(rows)==258 and all(a[0]=='base' and b[0]=='new' and a[1]==b[1] for a,b in pairs)
print('corpus',len(pairs),[(a[1],a[2],b[2]) for a,b in pairs if a[2]!=b[2]])
s=(p/'outputs/existing-suites.txt').read_text().splitlines()
print('identity_equal',s[1]==s[-2])
PY
```

- **[Pass] Acceptance 1, 3 and 4 have evidence; criterion 2's original cases pass but its no-false-refusal claim remains incomplete.** Both grep branches use `re.M` (`utils/py/swarm_preflight.py:278,283`); `outputs/red.txt:4-14` versus `outputs/green.txt:4-14` distinguishes anchors and comment/echo mentions. The missing-uv and resolvable cd/env/pipe controls pass at `outputs/green.txt:20-26`. Gap text and additive JSON, unchanged exit 0, and no-gap controls are retained at `outputs/green.txt:124-146`; the advisory wiring is at `utils/py/swarm_preflight.py:1336-1355,2027,2164,2222`. The diff adds no test suite, frozen twin change or githook change; GH-343's source-pin adjustment retains its failure guard (`test/gh343-gate-program-target-root.sh:103-104`). The observed expression-boundary failure above prevents overall acceptance 2.

- **[Pass] Acceptance 5 is supported by focused receipts and source compatibility, within that stated limit.** Marathon imports the shared evaluator and keeps its landed-only predicate (`utils/py/marathon_drive.py:2681,2697,2704`); Jog preserves its exit mapping (`utils/py/jog_run.py:648-659`). Conveyor documents these exits (`skills/1-hourly/conveyor/SKILL.md:101`), Flywheel delegates admission/preflight to Jog (`skills/2-daily/flywheel/SKILL.md:220-221`), and Kickstart composes these owners (`skills/1-hourly/kickstart/SKILL.md:18-19`). The retained gh438/gh280/gh291 and other suite results plus corpus replay support compatibility; they do not constitute separate end-to-end executions of every orchestration skill. The full `validate.sh` gate has intentionally not run at this stage. That is not a defect under this review brief, and no future gate is assumed as evidence.

- **[Nit] The seeded plan is still older than the checkout plan.** `.relay-artifacts/gh1580-final.diff:11,29` still says round 3 is blocked and the repair budget spent; the live plan at `PROJECT/2-WORKING/GH-1580-PREFLIGHT-MISREPORTS-GAPS.md:5,23,128` includes the authorized round 4. A read-only new-side hunk comparison (Python exit **0**) found all **386** Python, **17** GH-343 and **7** contract-example lines identical to the checkout, but **65** plan-line mismatches (including shifts from the added paragraph). Refresh the plan portion of any subsequent review artifact from its actual review revision. This does not invalidate the code correspondence or cause the failing verdict.

VERDICT: FAIL
Basis: The original F8 reproduction is fixed and the identity evidence is repaired, but a concrete valid conditional still produces F8's false `-f` command refusal through the same expression-folding boundary. The no-deferral Definition of Done is not met. This is the final authorized round; STATUS is Escalated, and #1580 parks under the recorded operator decision. No extra repair/review cycle is authorized by this finding.

Handing off to Producer (claude-a) — record the parked outcome and preserve the evidence; no further driven turn is requested without a new operator decision.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
