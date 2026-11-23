# RELAY · GH-1580 plan QA (swarm_preflight misreports)
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-11-23.
-->

NEXT: Reviewer
STATUS: Open
ROUND: 2 / 3

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
6. **Manual relay: commit only the relay file** (`relay(gh1580-plan-qa): <role> r<N>`); no push.
   **Driven turn (relay-drive, marathon): do not run git — the harness commits the turn.** **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. (The window wording is
   for a manual relay; in a driven turn, name the next role.) The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: PROJECT/1-INBOX/GH-1580-PREFLIGHT-MISREPORTS-GAPS.md (the PLAN; nothing is implemented yet)
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-11-23
- Definition of Done: the plan's `## Acceptance` list is satisfiable by the planned change, and the plan is grounded, surgical and falsifiable.

## Review brief (read this before the log)

**Step 0 — paraphrase first (GH-1414).** BEFORE reading any source file or the requirements below, read ONLY the plan doc and write, as the first thing in your block: **What this proposes** (2-5 sentences), **How the existing system works, per this document** (2-5 sentences), and a short **What it's not** where a consequential expectation could be mistaken. Label inference vs. stated. Then continue with the technical review and label that part source-backed.

**Requirements.** GitHub issue HiQS-Labs/XYZ-forge#1580 (its text is quoted in the plan's "Observed problem"). Three correctness defects in `utils/py/swarm_preflight.py`: (1) probe patterns must honour `^`/`$` per line (or reject anchors loudly); (2) every command in a gate must be existence-checked, not just the first; (3) a missing acceptance section must be reported as a gap, not a silent pass. Findings 4-6 of #1580 are follow-ups and out of scope. Preflight is a gate surface, so a finding on it is never deferred.

**Operational envelope.** Local developer CLI/harness code, one Python file plus one doc sentence. Grade against these requirements, commensurate complexity, and this repo's rules: no new tests/suites/gates (GH-831 / AGENTS.md "No new tests"; verification is existing suites + a manual red/green check under TESTS-RESULTS with provenance.jsonl), Python is authoritative and the Bash twin `utils/swarm-preflight.sh` is FROZEN (GH-308), do not touch `githooks/`. Challenge over-building; do not ask for a shell parser or new subsystems.

**Source to read (read-only, measure with narrow probes under `.relay-scratch/`; do not run test suites):**
- `utils/py/swarm_preflight.py`: `eval_probes` (~250-292), `check_acceptance_fidelity` (~928), `evaluate_candidate` gate block (~1785-1814) and acceptance block (~1703-1762), `report_candidate` (~1941-1958), `normalize` readiness (~396-416), `collect_inline_checklist` (~783).
- `utils/py/marathon_drive.py` ~2042-2082 (its own pre-advance gate check, not changed) and ~2636-2700 (`acceptance_probes_unmet` also calls `eval_probes`).
- `test/gh557-unknown-blocks-manifest.sh` (case 2 pins non-manifest `no-issue-section` => ready exit 0), `test/gh308-swarm-gate-path.sh`, `test/gh343-gate-program-target-root.sh`, `test/swarm-preflight.sh`.
- Red evidence: `TESTS-RESULTS/2026-11-23+GH-1580/controls.sh` and `outputs/red.txt` (replay against origin/development 81eefac61).

**Questions (answer each, cite file:line):**
1. Are the plan's claims about the current code accurate (anchors, first-token gate check, `unknown [no-issue-section]` verdict staying ready)? Any claim not grounded in the actual paths?
2. Anchors: is `re.search(pattern, text, re.M)` in `eval_probes` the right and sufficient fix? Any in-repo contract or consumer (marathon `acceptance_probes_unmet`, jog) whose behaviour would silently change for the worse? Give a concrete pattern if so.
3. Gate: does the planned per-command existence check avoid false NOT-READY on real gate shapes in this repo (`&&` chains, `cd`, env prefix, `env VAR=1 prog`, pipes, `${VAR:?}` program words, `bash -c '...'`, quoted newlines)? What realistic gate shape would it get wrong, and is the plan's skip list adequate or over-built?
4. Acceptance gap: is "gap line + `readiness.acceptance_gaps` JSON key, exit code unchanged" a faithful reading of #1580 point 3 ("report a gap instead of passing silently, or accept synonyms") given GH-557's pinned advisory behaviour? Is rejecting synonym-heading acceptance and non-blocking the right call? Does adding a JSON key risk any golden/consumer (test/gh291-contract-goldens.sh, jog, marathon-plan)?
5. For each of the three defects: what prevents an unchanged, unfixed candidate from being reported as delivered, and where is the observed rejection? (Plan-time: name the intended rejection and the control in `controls.sh`; is each control able to fail on the pre-change code? Check red.txt.)
6. Is the plan surgical and DRY (extends the existing evaluator and report path, no new subsystem, no new test file or registry entry)? Anything missing, over-engineered, or mis-scoped? Anything that should be in scope because preflight is a gate surface?

Every `[Blocker]`/`[Should]` that asks for a behaviour change needs `Observed input:`, `Affected scope:`, `Falsifier:`. Include `swept file: yes|no`, a VERDICT (PASS/FAIL/PARKED) with Basis, and set STATUS Approved only if the plan is ready to build.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). In a manual relay, end each turn by committing just this file; no push. In a driven turn the harness commits.

## Log

### Reviewer · Round 1

**What this proposes (document-only paraphrase; stated).** The plan changes preflight to evaluate regex anchors per line, check programs throughout compound gate commands, and explicitly report missing acceptance sections in text and JSON. It keeps acceptance gaps advisory outside frozen manifests and records red/green evidence through existing coverage and manual controls.

**How the existing system works, per this document (stated).** Python owns preflight, and marathon reuses its probe evaluator after builds. Gate readiness currently checks only the first command word, while acceptance fidelity recognizes only `## Acceptance`; missing issue criteria stay advisory outside a frozen manifest. The document says these three behaviors have been replayed on the development base.

**What it's not (stated; inference labelled).** This does not implement synonym-heading criteria, change exit codes, modify the frozen Bash twin, or repair marathon's separate pre-advance gate check. I infer the proposed gate helper is a conservative static check, not a promise to interpret arbitrary shell programs.

**Technical review — source-backed.**

swept file: yes

Swept the entire plan, all 2,183 lines of `utils/py/swarm_preflight.py`, and the contract example; inspected the named consumer and existing-suite paths. Graph tools were unavailable, so evidence is direct source, targeted searches and narrow probes. No suites, executable fixtures, preflight CLI, or Git commands were run. Pre-existing limitations relevant to this change are identified below; this is not an exhaustive audit of other modules.

- **[Should] F1 — Account for `cd` before reusing target-root script resolution (Q3/Q6).** The plan at `PROJECT/1-INBOX/GH-1580-PREFLIGHT-MISREPORTS-GAPS.md:77-83` skips `cd` but applies the existing target-root rules to every later command. Its own D2c (`TESTS-RESULTS/2026-11-23+GH-1580/controls.sh:97`) changes directory to `src` before `bash -n ok.sh`; `ok.sh` exists only in `src` (`:40`). Reapplying `swarm_preflight.py:1795` against the original root falsely rejects that valid gate. Fix the plan to resolve relative scripts/programs against a known literal `cd` destination in a simple sequential chain; when the execution directory is indeterminate, describe the conservative limitation instead of claiming the path is absent. Retain D2c and a missing-script control in the same directory. No general shell interpreter is needed.
  Observed input: `cd src && bash -n ok.sh && env FOO=1 python3 -c pass | cat`, with only `src/ok.sh` present (controls.sh:40,97). The source-block probe below demonstrates the same failure with an existing repository script.
  Affected scope: relative script/program operands after a directory-changing command; absolute operands and ordinary target-root commands retain their rules.
  Falsifier: D2c returns READY while a missing relative script after the same `cd src` returns NOT-READY naming that script. A flat target-root resolver cannot satisfy both.

- **[Should] F2 — Make acceptance-gap delivery observable in the manual evidence (Q5/Q6).** `controls.sh:69` retains uppercase `GAP`, but the plan at `:86` specifies lowercase `gap`; the filter probe below drops that exact proposed line. `controls.sh:65-70` never requests JSON, and `:11` explicitly says its exit code is always zero. D3 records the same successful exit expected after the fix (`outputs/red.txt:53-58`), so an unchanged candidate can be called green unless the missing output is separately judged. Amend the verification plan and existing manual recorder to retain the actual gap line and parse nonempty JSON, checking `readiness.acceptance_gaps`, the alternative heading, unchanged exit, and the no-gap control; include the planned capture-doc whole-document case. A comparison in the existing evidence directory suffices; no new suite or gate. Record the unchanged source failing those expectations and the changed head passing. Supply the promised `provenance.jsonl` with revision/command/result attribution: it is absent from the seeded evidence directory, so the base-SHA provenance is currently an assertion rather than a tied receipt.
  Observed input: planned text `  gap         : issue #301: Done when; add Acceptance` is discarded by controls.sh:69; D3 invokes only text mode and records exit 0 before and after the proposed behavior.
  Affected scope: retained manual GH-1580 red/green evidence, particularly the acceptance-gap output contract; runtime exit semantics stay unchanged.
  Falsifier: the completed manual comparison rejects unchanged source for missing text/JSON gaps, while changed source passes D3 and the canonical-heading no-gap control; empty/invalid JSON fails the comparison.

- **[Should] F3 — Allow the necessary existing GH-343 control update (Q6).** Moving the inline gate block into a helper changes the exact source span `test/gh343-gate-program-target-root.sh:91-104` uses to build its pre-fix control. It raises `could not construct the exact pre-GH-343 control branch` when that literal is absent. The plan promises the suite remains green but describes one Python file and one doc sentence (`plan:101,106-110`). Add a conditional edit of this existing suite's source replacement to the build scope, preserving its behavioral red control and checking the replacement actually occurred. This is keeping existing coverage truthful, not adding a test.
  Observed input: the literal `old` block at test/gh343-gate-program-target-root.sh:91-101 includes the inline indentation, comment and target-root branch scheduled for extraction.
  Affected scope: GH-343's existing pre-fix mutation construction if extraction changes that source span.
  Falsifier: the suite still constructs its intended mutation and observes the foreign-CWD rejection at :106-109 on the new implementation without an edit; then no suite edit is needed. Execution is [Unverified — needs clone run].

- **[Pass] Q1/Q2 — The anchor defect and shared fix are grounded.** Both regex calls omit multiline mode (`swarm_preflight.py:271,276`); `re.M` on both is sufficient for the specified line-anchor behavior and preserves inline `(?m)`. Preflight actually calls the evaluator from `inspect_repository` at `:1551`, not directly from `evaluate_candidate`; marathon calls it at `marathon_drive.py:2697` and rejects every result except `landed` at `:2704`. Jog credits exit 4 as completed (`jog_run.py:648-651`), so correcting false STALE matters. No concrete worsening contract was found in the inspected active-doc search: the visible `^  push:` example uses `kind`, not `type` (`PROJECT/2-WORKING/GH-544-LOCAL-GATE-BEFORE-PUSH.md:185-186`). Whole-file authors can use `\A`/`\Z`; no compatibility subsystem is justified by the inspected evidence.

- **[Pass] Q1/Q4 — Advisory gap reporting is a faithful, bounded option.** Missing issue sections return `unknown/no-issue-section` (`swarm_preflight.py:981-984`); frozen-manifest membership makes that cause block (`:1754-1762`). Nonmember exit zero is pinned by `test/gh557-unknown-blocks-manifest.sh:173-183`. Naming alternative headings without interpreting them preserves that policy. A readiness key is additive on the inspected paths: GH-291 goldens cover invocation/result artifacts, not run-candidate readiness (`test/gh291-contract-goldens.sh:4-8,100-125`); Jog loads `marathon-invocation.json` (`jog_run.py:661-663`); marathon-plan classifies return codes (`_marathon_plan.py:1308-1328`). Clone regression execution remains outstanding.

- **[Nit] Q1 — Tighten the recon language.** “Only a `## Acceptance` heading” and “Nothing says what to do” (`plan:38-41`) overstate the baseline: `ACC_HEADING_RE` accepts levels 2–6, Suggested Acceptance, Acceptance Criteria, colons and qualifiers (`swarm_preflight.py:562-568`), and the packet already says to establish criteria on the issue (`:2037-2045`). Describe the delta as explicit actionable text/JSON gaps and alternative-heading hints, preserving existing accepted variants. Correct the direct probe caller noted above. This is a plan wording correction, not a request to change heading semantics.

- **[Pass] Q3 — Keep the scanner bounded and qualify its promises.** Respecting quotes protects quoted newlines/compound arguments, skipping expansion-dependent words avoids bogus PATH failures, and exempting the argument of `bash -c` from script-file checking addresses the existing misclassification at `swarm_preflight.py:1791-1798`. Simple `&&`/pipe commands and `env FOO=1 prog` fit the proposed scanner once F1 is handled. The skip list is a reasonable conservative boundary, but “every command” must mean statically resolvable simple commands: `if missing_prog; then ...`, `bash -c 'missing_prog'`, `${VAR:?}` and substitutions are not proven by skipping their outer word. Do not recursively parse arbitrary shell. Also, a leading `NAME=value prog` may become acceptable to preflight under this plan but remains rejected by unchanged marathon at `marathon_drive.py:2074-2075`; record that downstream limitation instead of promising end-to-end readiness for it. No change to that excluded module is requested.

- **[Pass] Q5 — Anchor and later-command red cases discriminate at plan time.** D1a expects READY/0 but records STALE/4 (`controls.sh:79-81`, `outputs/red.txt:4-9`); D1b expects landed but records ready/0 (`controls.sh:83-85`, `red.txt:11-16`); D1c guards against comment/echo matches (`red.txt:18-23`). D2b/D2d must become NOT-READY/5 naming the missing program/script but currently record ready/0 (`controls.sh:95-100`, `red.txt:32-51`); D2a already observes the missing-uv refusal (`red.txt:25-30`). These are admission/evaluator controls, not evidence of a delivered build. D3 must reject absent gap output in the delivery comparison, not reject an exploratory lane at runtime; F2 supplies that missing observation. `shasum -a 256 utils/py/swarm_preflight.py` exited 0 with `cb543213bd4e4d9e63ef5680c11bcf74d6a23b641fa38f72418789b44f5f2136`, matching red.txt:1's prefix; that ties inspected source bytes to the log, but not the claimed Git revision without provenance.

**Narrow probe receipts (no fixture or gate executed).** This command applied the exact existing gate-check AST block to two directory contexts; Python exited 0. It demonstrates the proposed flat reuse problem, not an implemented helper result:

```sh
export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"
python3 - <<'PY'
import ast, os, pathlib, shutil
source=pathlib.Path('utils/py/swarm_preflight.py').read_text()
f=next(n for n in ast.parse(source).body if isinstance(n,ast.FunctionDef) and n.name=='evaluate_candidate')
block=next(n for n in f.body if isinstance(n,ast.If) and n.lineno==1785)
code=compile(ast.Module(body=[block],type_ignores=[]),'<gate block>','exec')
for root in [pathlib.Path.cwd(),pathlib.Path.cwd()/'test']:
    ns=dict(ready=1,ready_next='',gate_cmd='bash gh308-swarm-gate-path.sh',target_root=str(root),os=os,shutil=shutil)
    exec(code,ns)
    print(root.name, ns['ready'],ns['ready_next'].replace(str(pathlib.Path.cwd()),'<repo>'))
PY
```

Output: `rtl-wt.boPrFH 0 gate script not found under target_root <repo>: gh308-swarm-gate-path.sh`, then `test 1`.

```sh
printf '%s\n' '  gap         : issue #301: Done when; add Acceptance' | grep -E '^(  (candidate|acceptance|GAP|readiness|verdict)|CONTRACT|BLOCKED|swarm-preflight:)'
```

Exit 1, empty stdout: the planned gap line cannot survive the current recorder.

**VERDICT: FAIL**

**Basis:** The core direction is surgical and uses the right existing paths, but the gate algorithm contradicts its positive `cd` control, acceptance evidence discards the new signal, and the source-text mutation suite needs an explicit preservation step. Revise F1–F3 and the recon wording before building. Existing suites and full CLI/consumer flows remain [Unverified — needs clone run]; no later gate is assumed.

Handing off to Producer (claude-a) — disposition these findings and revise the plan and existing manual evidence, then request the next review round.

### Producer · Round 1 dispositions

- **F1 [Should] — Implemented.** Plan item 2 now tracks one working directory across the chain: it starts at target_root, a literal `cd <dir>` moves it, and relative scripts/program paths resolve against it; a non-literal `cd` makes later relative checks indeterminate (skipped, PATH lookups still run). Controls D2c (valid `cd src && bash -n ok.sh`) and D2e (`cd src && bash -n missing.sh` must be NOT-READY naming `missing.sh`) are in `controls.sh`.
- **F2 [Should] — Implemented.** `controls.sh` now states the correct expectation per case and prints MATCH/MISMATCH, keeps the lowercase `gap` line, runs the acceptance cases in text and `--format json` (nonempty JSON, `readiness.acceptance_gaps`, named alternative heading, exit 0, no-gap control, whole-document capture-doc case), and writes `provenance.jsonl`. Red re-run on the unchanged origin/development export: MATCH=5, MISMATCH=10 (`outputs/red.txt`, `provenance.jsonl`); green must be MATCH=15.
- **F3 [Should] — Implemented as a conditional edit.** Plan now lists the update of the existing `test/gh343-gate-program-target-root.sh` replacement literal (keeps its guard and its behavioural red control); no new test.
- **Nit (recon wording) — Implemented.** Baseline described accurately (`ACC_HEADING_RE` accepts level 2-6 and qualifiers; the delta is an actionable gap and naming the alternative heading); `eval_probes` caller corrected to `inspect_repository` (`:1551`), plus the marathon `:2704` and jog `:648-651` consumers.
- **Q3 qualification — Implemented.** Plan says "every statically resolvable simple command", lists what is skipped, and records the downstream limit that marathon-drive still refuses a leading `NAME=value prog` (`marathon_drive.py:2074-2075`).

Handing off to Reviewer for Round 2 on the revised plan `PROJECT/1-INBOX/GH-1580-PREFLIGHT-MISREPORTS-GAPS.md` and the updated `TESTS-RESULTS/2026-11-23+GH-1580/` (controls.sh, outputs/red.txt, provenance.jsonl). Re-check F1-F3 closure and anything newly introduced.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
