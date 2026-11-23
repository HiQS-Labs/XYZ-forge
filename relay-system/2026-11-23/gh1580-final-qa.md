# RELAY · GH-1580 final QA (swarm_preflight misreports)
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-11-23.
-->

NEXT: Reviewer
STATUS: Open
ROUND: 3 / 3

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
6. **Manual relay: commit only the relay file** (`relay(gh1580-final-qa): <role> r<N>`); no push.
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
- Definition of Done: the plan's `## Acceptance` list in `PROJECT/2-WORKING/GH-1580-PREFLIGHT-MISREPORTS-GAPS.md` is satisfied by the committed change, the evidence under `TESTS-RESULTS/2026-11-23+GH-1580/` substantiates it, and no finding is deferred (preflight is a gate surface).

## Review brief (read before the log)

**Step 0 — paraphrase first.** Before reading source, write **What this changes** and **How the existing system works** (2-5 sentences each) from the plan doc alone; then review source-backed.

**What was built (committed, HEAD of this branch).** Issue HiQS-Labs/XYZ-forge#1580, three correctness defects in `utils/py/swarm_preflight.py`: (1) `eval_probes` matches grep probes with `re.M`; (2) `gate_command_gap` (plus `_gate_tokens`, `_gate_program_gap`) replaces the first-token-only gate check, with cwd-aware literal `cd` tracking; (3) `acceptance_gaps` adds a `gap` line and `readiness.acceptance_gaps`, advisory only. Also: one sentence in `relay-automation/CONTRACT.example.md`; the existing `test/gh343-gate-program-target-root.sh` mutation literal follows the extracted helper. Findings 4-6 of #1580 are intentionally out of scope. The plan was Approved by Codex plan QA in round 3 (`relay-system/2026-11-23/gh1580-plan-qa.md`).

**Operational envelope.** Local developer CLI/harness code. Grade against the requirements, commensurate complexity and this repo's rules: no new tests/suites/gates (GH-831; a new test file or registry entry in the diff is a finding), Python is authoritative and the Bash twin is FROZEN (GH-308), `githooks/` untouched. Challenge over-building.

**Read:** the diff `.relay-artifacts/gh1580-final.diff` (seeded read-only), then the real files: `utils/py/swarm_preflight.py` (`eval_probes`, `_gate_tokens`, `_gate_program_gap`, `gate_command_gap`, `acceptance_gaps`, the evaluate_candidate wiring, `normalize`, `report_candidate`), `test/gh343-gate-program-target-root.sh`, `test/gh557-unknown-blocks-manifest.sh`, the plan doc, and evidence `TESTS-RESULTS/2026-11-23+GH-1580/{manual-check.md,controls.sh,provenance.jsonl,outputs/*}`. Measure with narrow read-only probes under `.relay-scratch/`; do not run suites (they were run in a disposable clone: `outputs/existing-suites.txt`).

**Questions (cite file:line):**
1. Is each acceptance criterion in the plan satisfied? For each of the three defects: what prevents an unchanged, unfixed candidate from being reported as delivered, and where is the observed rejection (red.txt MISMATCH vs green.txt MATCH, mutant-unconditional-cd.txt)?
2. Do the actual code paths match the approved plan? Any divergence, duplicate subsystem or second writer? Is the rating (70/65/50/75, plan "Rating rationale") consistent with the evidence?
3. Correctness of `_gate_tokens` / `gate_command_gap` / `_gate_program_gap` on real gate shapes: find a concrete gate string that is falsely refused (NOT-READY) or that reads READY with a missing program/script, other than the documented skips (builtins, expansion words, `bash -c` body, indeterminate cwd). Give the exact input and the observed output.
4. `re.M` change: any consumer (marathon `acceptance_probes_unmet`, jog) or in-repo contract that gets worse? (`corpus-sweep.txt` shows no change over 129 contracts.)
5. `acceptance_gaps`: advisory only, exit codes unchanged (GH-557 case 2)? Anything that could newly block or break JSON consumers?
6. Do the checks substantiate the claims (provenance hashes, source commit, MATCH/MISMATCH logic)? Is anything claimed but unverified?
7. Anything missing that preflight being a gate surface requires, or over-engineered?

Every `[Blocker]`/`[Should]` asking for a behaviour change needs `Observed input:`, `Affected scope:`, `Falsifier:`. Include `swept file: yes|no`, a VERDICT (PASS/FAIL/PARKED) with Basis, and set STATUS Approved only if ready to ship.
## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). In a manual relay, end each turn by committing just this file; no push. In a driven turn the harness commits.

## Log

### Reviewer · Round 1 · codex

**What this changes (plan-only paraphrase, recorded before reading source).** This corrects line-anchored probes, checks later commands in chained gates, and exposes missing acceptance sections as advisory gaps. It retains the existing verdict/exit-code policy and extends the existing evaluator.

**How the existing system works (plan-only paraphrase).** Preflight combines repository probes, gate availability and acceptance fidelity into readiness. Marathon reuses the probe evaluator, while Jog consumes preflight exit codes, so false STALE or NOT-READY results affect downstream work.

swept file: yes

Read the entire `utils/py/swarm_preflight.py`, changed contract example and GH-343 suite, the seeded diff, plan, GH-557 suite, manual controls and all five retained outputs. Graph tools were unavailable; evidence is direct source plus narrow AST-isolated function probes. No git, suite, pytest, executable fixture or gate was run. The whole-file sweep found the pre-existing F4 below; no other pre-existing defect was established.

- **[Blocker] F1 — conditional cwd survives an OR boundary and falsely refuses a runnable gate.** `utils/py/swarm_preflight.py:715` records the conditional directory, but `:727` invalidates it only at semicolon/newline. Here `false` prevents `cd` from running, so Bash reads the existing root `validate.sh`; the checker instead searches `utils/validate.sh`. This violates the plan's “only certain inside that `&&` run” rule. Fix conditional-cwd transitions at the end of the guaranteed AND run, including `||`, preserving straight-line `cd` checking. Retain a manual red/green control, not a new suite.
  Observed input: `false && cd utils && true || bash -n validate.sh`, target root = this checkout. The probe below exited 0 and returned `gate script not found under target_root <root>/utils: validate.sh`. `evaluate_candidate` at `:1994-1998` turns that into NOT-READY.
  Affected scope: a `cd` reached through `&&`, followed by another command and an OR branch with a relative script/program operand.
  Falsifier: this command must return no gap; `cd utils && bash -n missing-gh1580.sh` must still report the missing script under `utils`; an absolute missing script after an OR boundary must remain checked.

- **[Blocker] F2 — a script's own `-c` argument suppresses the missing-script check.** `_gate_program_gap` at `utils/py/swarm_preflight.py:660` searches all arguments for a `c` option, including arguments after the script operand. Bash stops interpreting its options at that operand: this is not the documented `bash -c` body exemption. Distinguish interpreter options from the script and its arguments before applying the exemption.
  Observed input: `true && bash .relay-scratch/absent-gh1580.sh -c`; the path does not exist, yet the probe returned `''` (no gap). Removing the trailing `-c` returned the expected missing-script diagnostic. Both are literal commands with known cwd and no expansion.
  Affected scope: Bash/sh script invocations whose script arguments include `-c` or another word matching `-[A-Za-z]*c[A-Za-z]*`.
  Falsifier: the missing-script command with trailing `-c` must produce a gap; genuine `bash -c 'nonexistent_inner_cmd; true'` must retain the documented body skip; an existing script with trailing `-c` must remain accepted.

- **[Should] F3 — attached redirection becomes part of the script filename.** `_gate_tokens` at `utils/py/swarm_preflight.py:596-628` does not separate redirection operators, so `:662-670` looks for `validate.sh>/dev/null`. This introduces a false refusal in a later command the old first-token check accepted. Handle ordinary redirections separately from command/script operands, preserving quoted literal operator characters. Skip genuinely indeterminate operands instead of asserting a nonexistent filename; no general shell interpreter is requested.
  Observed input: `true && bash -n validate.sh>/dev/null` returned `gate script not found under target_root <root>: validate.sh>/dev/null`; whitespace-equivalent `true && bash -n validate.sh > /dev/null` returned `''`. The actual `validate.sh` exists.
  Affected scope: unquoted redirects attached to a statically known program or Bash/sh script operand, including common gate output suppression.
  Falsifier: both whitespace variants must return no gap; an actually missing script with an attached redirect must remain detected; a quoted filename containing `>` must remain literal.

- **[Should] F4 — pre-existing `path_present` never recognizes a completed removal.** `utils/py/swarm_preflight.py:267-268` marks absence `blocked`, never `landed`. The contract example defines this probe as “The unwanted file is present (it should be removed by the fix)” (`relay-automation/CONTRACT.example.md:22`). A real consumer is `PROJECT/3-COMPLETED/GH-269-RELEASES-DB-SWITCHOVER.md:65-66`, probing retired `ROADMAP.md`. Marathon accepts only `landed` at `utils/py/marathon_drive.py:2697-2704`, so successful removal cannot pass that recheck. Correct the absent-path verdict for this probe, leaving present-path = unfixed; record a manual control.
  Observed input: `{"fix_probes":[{"type":"path_present","path":"ROADMAP.md"}]}` against this checkout, where that path is absent, returned `([{'type': 'path_present', 'path': 'ROADMAP.md', 'verdict': 'blocked'}], 0, 1, 0)`. The same probe on existing `validate.sh` returned `unfixed`.
  Affected scope: `path_present` probes detecting unwanted paths that have been removed; no change requested to `grep_present`'s missing/unreadable-source behavior.
  Falsifier: absent unwanted path must return landed with stale=1 and blocked=0; present unwanted path must remain unfixed. Marathon's unchanged landed-only predicate should then admit the completed removal.

**Reproducible probe for F1–F4.** Executed from the checkout, exit **0**. This compiles only named functions/constants from the real source in memory; it does not execute the gate strings or fixtures. Decisive outputs are quoted in the findings.

```bash
export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"
python3 - <<'PY'
import ast, os, re, shutil
from pathlib import Path
from typing import Any
p = Path('utils/py/swarm_preflight.py')
names = {'_gate_tokens', '_gate_program_gap', 'gate_command_gap', 'eval_probes'}
nodes = [n for n in ast.parse(p.read_text()).body
         if isinstance(n, ast.FunctionDef) and n.name in names
         or isinstance(n, ast.Assign) and any(isinstance(t, ast.Name) and t.id.startswith('_GATE_') for t in n.targets)]
ns = dict(os=os, re=re, shutil=shutil, Any=Any)
exec(compile(ast.Module(body=nodes, type_ignores=[]), str(p), 'exec'), ns)
root = str(Path.cwd())
for cmd in ['false && cd utils && true || bash -n validate.sh',
            'true && bash .relay-scratch/absent-gh1580.sh -c',
            'true && bash -n validate.sh>/dev/null',
            'true && bash -n validate.sh > /dev/null',
            'true && bash .relay-scratch/absent-gh1580.sh']:
    print(repr(cmd), '=>', repr(ns['gate_command_gap'](cmd, root).replace(root, '<root>')))
for path in ['validate.sh', '.relay-scratch/absent-gh1580.sh', 'ROADMAP.md']:
    c = {'fix_probes': [{'type': 'path_present', 'path': path}]}
    print(path, 'exists=', Path(path).exists(), 'probe=', ns['eval_probes'](root, c))
PY
```

- **[Pass] Acceptance 1 — discriminating line-anchor evidence.** `utils/py/swarm_preflight.py:274,279` uses `re.M` in both branches. `TESTS-RESULTS/2026-11-23+GH-1580/outputs/red.txt:4-10` rejects the old outcomes as MISMATCH; `outputs/green.txt:4-14` records corrected outcomes and the comment/echo negative control. Marathon imports this evaluator (`utils/py/marathon_drive.py:2681`); Jog's stale-to-completed route remains at `utils/py/jog_run.py:648-651`. No anchor regression was established by source review or the retained corpus comparison.
- **[Pass] Acceptance 3 — additive, advisory gaps.** `utils/py/swarm_preflight.py:1242-1264` recognizes all four alternatives without accepting them as criteria; `:1936`, `:2073`, `:413` and `:2131-2132` wire the existing report and JSON writer. No gap feeds the blocking decision. `outputs/red.txt:48-74` versus `outputs/green.txt:48-74` provides text/JSON red controls, a matching-section no-gap control and the whole-document case, retaining exit 0. GH-557's nonmember expectation remains at `test/gh557-unknown-blocks-manifest.sh:173-183`; its retained run reports rc=0 in `outputs/existing-suites.txt:7`.
- **[Pass] Acceptance 4 — internally consistent receipts; no new test suite in the supplied diff.** All five nonempty outputs hash to `TESTS-RESULTS/2026-11-23+GH-1580/provenance.jsonl:1-5`. A read-only Python `hashlib.sha256(path.read_bytes())` comparison exited 0, printing `HASH <output> True` for each. Current source SHA-256 is `82c352f182937dd7a37ef9710844ee846ec44e8da185260777014d2e10926709`, matching `outputs/green.txt:1`'s prefix. Counting literal `[MATCH]`/`[MISMATCH]` entries exited 0: red **7/11**, green **18/0**, cd mutant **15/3**. The mutant's observed rejections are at `outputs/mutant-unconditional-cd.txt:32-42`. The GH-343 replacement and exact-match guard remain at `test/gh343-gate-program-target-root.sh:91-105`. These establish receipt consistency, not Git ancestry or execution this reviewer did not witness.
- **[Unverified — needs clone run] Acceptance 2 remains incomplete due to F1–F3; acceptance 5 is only partially evidenced.** `outputs/existing-suites.txt:1-18` reports 17 passing shell suites and 21 Python tests, including Marathon/Jog coverage. The corpus has 129 equal base/new pairs (read-only pair comparison exited 0: `corpus_pairs 129 different 0`), but CLI-summary equality does not exercise every caller end to end. No pre/post clone-identity bracket, full-gate result, or caller-specific conveyor/flywheel/kickstart verification is retained in this evidence set. After repairs, retain the applicable disposable-clone verification and map the plan's caller criterion explicitly to inspected code or exercised coverage. This reviewer did not run those suites, and approval cannot assume a later gate.
- **[Pass] Architecture/rating assessment.** The change extends the existing evaluator/report path (`utils/py/swarm_preflight.py:1994-1998,2070-2075`), with no second writer or subsystem. Repair the demonstrated operand/control-flow errors without adding a shell execution layer. The plan's 70/65/50/75 rationale (`PROJECT/2-WORKING/GH-1580-PREFLIGHT-MISREPORTS-GAPS.md:158-166`) is consistent with recoverable wrong verdicts and limited file scope; supplied evidence does not independently measure effort or recurrence. The documented downstream assignment-prefix restriction remains a limitation, not proof of end-to-end readiness.

Handing off to Producer (claude-a) — disposition F1–F4, repair the demonstrated cases and refresh evidence before the next review.

VERDICT: FAIL
Basis: the original reproductions improve, but literal gate inputs still yield false refusals and a false no-gap result; the whole-file sweep also establishes a pre-existing probe that cannot recognize successful removal. The Definition of Done is not yet met.

### Producer · Round 1 dispositions

All four findings implemented; none deferred. Repair commit b3b62735b; evidence refreshed in 423d3305a / 3d75e77d4 (the suites receipt was briefly empty and is fixed; every provenance hash is re-verified non-empty and matching).

- **F1 [Blocker] — Implemented.** A cd reached through `&&` stays certain only inside that `&&` run; the run now also ends at `||`, `|` and `&` (`gate_command_gap`, the `elif cond and text != "&&"` branch), not only at `;`/newline. Your input `false && cd utils && true || bash -n validate.sh` returns no gap; `cd utils && bash -n missing-gh1580.sh` still reports the missing script under `utils`. Control D2j.
- **F2 [Blocker] — Implemented.** `_program_gap` reads interpreter options only up to the first operand (also `--`, and the arguments of `-o/+o/-O/+O/--rcfile/--init-file`); a `-c` after the script is the script's own argument. `bash absent.sh -c` is now a gap; `bash -c '…'` still skips; an existing script with trailing `-c` is accepted. Control D2k.
- **F3 [Should] — Implemented.** `_gate_tokens` emits unquoted redirections (`>f`, `2>&1`, `&>f`, `<f`, `<<EOF`) as separate tokens and drops their target word, so `bash -n validate.sh>/dev/null` checks `validate.sh`; an attached redirect on a missing script is still reported; a quoted `"va>lidate.sh"` stays literal. Controls D2l, D2m.
- **F4 [Should] — Implemented.** `path_present` now reads a gone unwanted path as `landed` (was `blocked`). Control D4a/D4b. Parity limit: `_marathon_plan._eval_probe`, `utils/marathon-plan.sh` and the frozen Bash twin keep `blocked`; filed as HiQS-Labs/XYZ-forge#1583 (planner classification only). The corpus sweep shows exactly one in-repo contract changing (GH-269: rc 6 BLOCKED -> rc 4 STALE), the intended effect.

Evidence for acceptance 5 (callers) is now in `TESTS-RESULTS/2026-11-23+GH-1580/manual-check.md` (caller map + `outputs/existing-suites.txt`, 17 suites + pytest 21 passed on b3b62735b in a disposable full clone). Red/green: `outputs/red.txt` 10/14, `outputs/prerepair.txt` 20/4 (D2j D2k D2l D4a red on the pre-repair tree), `outputs/green.txt` 24/0, `outputs/mutant-unconditional-cd.txt` 21/3.

Handing off to Reviewer for Round 2: re-check F1-F4 closure, the refreshed seeded diff, and anything newly introduced.

### Reviewer · Round 2 · codex

**What this changes (plan-only paraphrase, before source review).** It fixes line-anchored probes, checks later commands in chained gates, and reports missing acceptance sections as advisory gaps. The revised plan also repairs conditional cwd tracking, script argument handling, attached redirections and completed path removals.

**How the existing system works (plan-only paraphrase).** Preflight combines repository probes, gate availability and acceptance fidelity into readiness. Marathon reuses the probe evaluator and Jog consumes preflight exit codes; the existing report/JSON path carries the advisory gap without changing those exit codes.

swept file: yes

**Block.** Read the entire 2,394-line `utils/py/swarm_preflight.py`, contract example, GH-343 and GH-557 suites, plan, seeded diff, manual controls and refreshed receipts. Graph tools were unavailable; source reads and AST-isolated probes supplied evidence. No git, suites, pytest, executable fixtures or gate commands ran. The whole-file sweep established no additional unrelated pre-existing defect; F7 below is an interpreter-mode limitation now exposed in later commands by this change. Only this relay file was edited.

- **[Pass] F1–F4 closed for their observed inputs.** Direct probes return no gap for the former OR-boundary refusal and attached redirect; they detect the missing script with trailing `-c`, retain the genuine `bash -c` exemption and preserve quoted `>` as filename data. `path_present` on absent `ROADMAP.md` returns `landed`, stale=1, blocked=0; existing `validate.sh` remains `unfixed`. Source: `utils/py/swarm_preflight.py:271,673,719,750`. The retained red witnesses are `outputs/prerepair.txt:52,56,60,68`, with green cases at the same lines of `outputs/green.txt` (all output paths below are under `TESTS-RESULTS/2026-11-23+GH-1580/`). F4's separately recorded planner/Bash parity limit does not reopen the specific shared-evaluator fix requested in round 1.

- **[Blocker] F5 — assignment-prefixed `cd` leaves a falsely certain cwd, causing both false refusal and false no-gap.** `_gate_program_gap` skips assignments then recognizes `cd` as a builtin (`utils/py/swarm_preflight.py:646,660`), but cwd tracking only recognizes `words[0] == "cd"` (`:729`). Normalize the main-shell assignment prefix for cwd tracking, or mark that cwd indeterminate if it cannot be proved; do not keep the old directory as certain. This is within the approved assignment-prefix support, and the gate starts with `true`, so it does not depend on the documented downstream first-token limitation.
  Observed input: `true && FOO=1 cd utils && bash -n pdda/pdda.sh` returns `gate script not found under target_root <root>: pdda/pdda.sh`, although `utils/pdda/pdda.sh` exists. Conversely, `true && FOO=1 cd utils && bash -n validate.sh` returns `''`, although `utils/validate.sh` does not exist. Probe exit 0. `evaluate_candidate` at `:2019-2021` converts a gap into NOT-READY; the false empty result avoids that refusal.
  Affected scope: literal assignment-prefixed main-shell `cd`, followed within its successful AND run by relative script/program operands.
  Falsifier: the first input must yield no gap; the second must report the missing `utils/validate.sh` when cwd is tracked. Ordinary `cd utils && bash -n missing-gh1580.sh` must remain checked, and conditional/pipeline cwd controls must stay green.

- **[Should] F6 — heredoc data is interpreted as shell commands.** Redirection handling consumes the delimiter word but not the body (`utils/py/swarm_preflight.py:596-597,719-726`); newline handling then submits the body and closing delimiter to PATH lookup. Preserve the distinction between heredoc data and shell commands. A bounded skip for unsupported heredoc syntax is adequate; do not introduce recursive execution or a full shell interpreter.
  Observed input: `cat <<'EOF'\nhello\nEOF\nbash -n validate.sh` (each `\n` denotes a real newline) returns `command 'hello' not found in PATH`. `hello` is stdin data to `cat`, not a command; both actual programs resolve and the script exists. Probe exit 0.
  Affected scope: gate commands containing a heredoc, including the `<<EOF` form explicitly named by the redirection comment at `:566`.
  Falsifier: this input must not report `hello` or `EOF` as missing programs; after the terminating delimiter, a literal missing command should still be checked when its boundary can be resolved. Ordinary attached-redirection controls must remain green.

- **[Should] F7 — `bash -s` positional arguments are mistaken for a script path.** Interpreter option parsing recognizes `-c` but ignores stdin mode, then treats the next positional argument as the script (`utils/py/swarm_preflight.py:673-687`). Recognize `-s`/combined stdin-mode options before assigning a script operand, and retain the literal-script checks.
  Observed input: `true && bash -s ignored-argument </dev/null` returns `gate script not found under target_root <root>: ignored-argument`. Bash reads commands from stdin under `-s`; this word is a positional parameter. Probe exit 0. This later command was not inspected by the old first-token check.
  Affected scope: Bash/sh stdin-mode invocations with positional arguments, including the common pipe-to-shell form.
  Falsifier: this input must yield no missing-script gap; `true && bash .relay-scratch/absent-gh1580.sh -s` must still report the missing script because options have already ended at the script operand.

**Reproducible probe command.** Executed from this checkout, exit **0**; gate strings were only passed as data to the static helper. Decisive outputs are quoted above. The first eight commands and both `path_present` calls also supply F1–F4 closure controls.

```bash
export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"
mkdir -p "$TMPDIR"
python3 - <<'PY'
import ast, os, re, shutil
from pathlib import Path
from typing import Any
p=Path('utils/py/swarm_preflight.py')
names={'_gate_tokens','_gate_program_gap','gate_command_gap','eval_probes'}
nodes=[n for n in ast.parse(p.read_text()).body if isinstance(n,ast.FunctionDef) and n.name in names or isinstance(n,ast.Assign) and any(isinstance(t,ast.Name) and t.id.startswith('_GATE_') for t in n.targets)]
ns=dict(os=os,re=re,shutil=shutil,Any=Any)
exec(compile(ast.Module(body=nodes,type_ignores=[]),str(p),'exec'),ns)
root=str(Path.cwd())
cmds=['false && cd utils && true || bash -n validate.sh', 'cd utils && bash -n missing-gh1580.sh', 'true && bash .relay-scratch/absent-gh1580.sh -c', "bash -c 'nonexistent_inner_cmd; true'", 'true && bash -n validate.sh -c', 'true && bash -n validate.sh>/dev/null', 'true && bash .relay-scratch/absent-gh1580.sh>/dev/null', 'true && bash -n "va>lidate.sh"', 'true && FOO=1 cd utils && bash -n pdda/pdda.sh', 'true && FOO=1 cd utils && bash -n validate.sh', "cat <<'EOF'\nhello\nEOF\nbash -n validate.sh", 'true && bash -s ignored-argument </dev/null', 'true && bash -n validate.sh 2>&1']
for c in cmds:
 print(repr(c),'=>',repr(ns['gate_command_gap'](c,root).replace(root,'<root>')))
for path in ['ROADMAP.md','validate.sh']:
 print(path,'exists=',Path(path).exists(), 'probe=',ns['eval_probes'](root,{'fix_probes':[{'type':'path_present','path':path}]}))
for path in ['utils/pdda/pdda.sh','pdda/pdda.sh','utils/validate.sh','validate.sh']:
 print('EXISTS',path,Path(path).is_file())
PY
```

- **[Pass] Acceptance 1 and 3 remain substantiated.** `re.M` is present in both probe branches (`utils/py/swarm_preflight.py:278,283`); `outputs/red.txt:4-10` versus `outputs/green.txt:4-14` discriminates the anchors and comment/echo control. The additive `acceptance_gaps` value travels through `:1959,2096,415,2154` and does not enter the blocking predicate. Red/green text and JSON controls at `outputs/red.txt:76` onward versus `outputs/green.txt:76` onward substantiate the missing-heading gap and unchanged exit 0. No new anchor regression or JSON-consumer break was established.
- **[Pass] Receipt consistency and scope.** Read-only Python SHA-256 comparison printed `nonempty True match True` for all six outputs against `provenance.jsonl:1-6` (exit 0); counted MATCH/MISMATCH values are red **10/14**, prerepair **20/4**, green **24/0**, cd mutant **21/3**. Current source SHA-256 is `3ab8b063609bdb6968726b030e6c4803a4a9eb1d383cb665067e70922db64687`, agreeing with `outputs/green.txt:1`. A read-only comparison of the seeded diff's new-side hunk lines with the named files printed `DIFF_NEW_LINES_MATCH 524` (exit 0). The diff adds no suite, frozen twin change or second writer; GH-343's exact mutation guard remains at `test/gh343-gate-program-target-root.sh:104`. Acceptance 2 is still blocked by F5–F7, despite its original missing-uv control passing at `outputs/green.txt:20`.
- **[Pass] Caller map is now grounded; limits remain explicit.** Marathon shares `eval_probes` and retains its landed-only recheck (`utils/py/marathon_drive.py:2681,2697,2704`); Jog retains its exit-code mapping (`utils/py/jog_run.py:648-659`). Conveyor documents the same exit-code contract (`skills/1-hourly/conveyor/SKILL.md:101`); Flywheel delegates admission to Jog (`skills/2-daily/flywheel/SKILL.md:220-221`), and Kickstart composes those owners (`skills/1-hourly/kickstart/SKILL.md:18-19`). These are not three additional independent runtime parsers. Pairing all corpus receipt rows printed `CORPUS_PAIRS 129` with exactly GH-269 changing rc 6 to 4; its readiness=0 artifact warning stayed the same, consistent with corrected stale classification taking precedence.
- **[Unverified — needs clone run] The prior verification limitation remains partially open.** `outputs/existing-suites.txt:1-19` reports 17 passing shell suites and 21 Python tests at the repair revision (`provenance.jsonl:6`), but still retains no pre/post clone-identity bracket or full-gate result. Source/receipt inspection is not a witnessed execution or proof of Git ancestry. After F5–F7, refresh the applicable disposable-clone evidence and retain the identity checks required by AGENTS.md before claiming it trustworthy. No later gate is assumed by this review.
- **[Pass] Architecture and rating.** The existing evaluator/report remains the owner (`utils/py/swarm_preflight.py:2017,2096,2154`); the 70/65/50/75 rationale in the plan's “Rating rationale” remains qualitatively consistent with recoverable wrong verdicts. The helper now contains a handwritten tokenizer and interpreter-option logic, so the plan's “not a shell parser” wording understates maintenance cost. Fix the concrete cases with conservative static handling; no new subsystem, suite or execution layer is warranted.

VERDICT: FAIL
Basis: F1–F4 are closed, but observed gate inputs still produce both false refusal and false no-gap results. The Definition of Done is not yet met.

Handing off to Producer (claude-a) — disposition F5–F7, repair the demonstrated cases and refresh the disposable-clone evidence before Round 3.

### Producer · Round 2 dispositions

All three findings implemented; none deferred. Repair commit ccfd53eea; evidence refreshed in 229d5b550 (every provenance hash re-verified non-empty and matching; the suites receipt now carries the clone identity bracket you asked for: HEAD, origin, core.bare, clean tree, reflog with the single clone entry).

- **F5 [Blocker] — Implemented.** `gate_command_gap` finds the command word after leading `NAME=value` assignments and control prefixes, so `true && FOO=1 cd utils && bash -n pdda/pdda.sh` checks `utils/pdda/pdda.sh` (no gap) and `... && bash -n validate.sh` reports the missing `utils/validate.sh`. Commands that may change the directory in ways not modelled (`pushd`, `popd`, `eval`, `source`, `.`, `exec`, `command`, `builtin`) make the directory unknown, and a `cd` under or after a control-flow word is not tracked. Controls D2n, D2o.
- **F6 [Should] — Implemented.** `_gate_tokens` records `<<`/`<<-` delimiters and skips the heredoc body up to its delimiter line (quoted delimiters, tab-stripping for `<<-`); an unterminated heredoc falls back to the old first-word check; a missing command AFTER the heredoc is still found. Controls D2p, D2q.
- **F7 [Should] — Implemented.** Interpreter options accept `-s`/combined stdin mode (no script operand), while `-s`/`-c` after the script stay the script's own argument (`bash src/absent.sh -s` is a gap). Controls D2r, D2s.
- **Same-class audit (no finding raised; fail-safe skips added after probing for false refusals):** `[[ a && b ]]` and `(( … ))` are folded into one skipped word, unquoted globs/braces and process substitution `<(…)` are skipped as expansions, shell functions defined in the gate are not looked up on PATH, backslash-newline continuations join. Controls D2t-D2v. A comparison of old first-word vs new verdict over all 28 distinct gate strings in the repo's own contracts shows 0 flips.
- **Verification refresh:** at the repaired head in a fresh disposable full clone, 17 shell suites rc=0 and pytest 21 passed (`outputs/existing-suites.txt`, bracket included); corpus sweep 129 contracts, 128 identical and the one intended GH-269 change (rc 6 -> 4). Red/green: `outputs/red.txt` 14/19, `outputs/prerepair-r1.txt` 22/11, `outputs/prerepair-r2.txt` 26/7 (D2n D2p D2q D2r D2t D2u D2v red on the tree before the r2 repairs), `outputs/green.txt` 33/0, `outputs/mutant-unconditional-cd.txt` 30/3. A full `validate.sh` gate is not run at this stage: it runs once, in the background, at push through the pre-push hook (GH-1518).

Handing off to Reviewer for Round 3 (the last round under the cap): re-check F5-F7 closure and anything newly introduced.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
