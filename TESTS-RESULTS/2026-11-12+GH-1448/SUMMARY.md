# GH1448: no runtime change recommended

## Decision

Reject hypothesis H as a production advisory extension. It warns on one of two fixed-output
controls, misses the wrapped constant, and warns on two legitimate input-dependent/specialized
checks. Retain current runtime and use the existing outcome-sensitive review questions from
GH1447. This is a bounded research conclusion, not proof that every possible lexical diagnostic
is useless. A reviewed evidence PR is the delivery; no validator improvement is claimed.

The operator explicitly authorized a small implementation if promising, superseding the intake's
research-only/later-authorization wording. The study found insufficient benefit to spend that
authorization. No runtime file, safety refusal, test suite, registry, gate, runner, ledger system,
hook or deployment was added/changed. PRS records use the existing writer. No unlazy installation,
import or vendoring occurred; its pinned idea was background only, not an independently verified
implementation dependency.

## Method and results

Base: `7acaa24508002a74e2445534af3ecaccc0b26b7a`. Eight cases and expected outcomes were committed
at `27adc227b8606cf1a49547508ab18ad22dd1ec84`, before plan approval and evaluation. Plan Codex QA
Approved at `relay-system/2026-11-12/gh1448-plan.codex.md`; driver exit 0. Admission followed with
`roadmap update --gid rmi-01M78YJ69DPHKP245NJMA04NWB --accepted-start` (exit 0).
Evaluation took 0.034 seconds at 2026-11-12T22:42:20Z; the additional-case research was stopped
at eight cases, well within 30 minutes. Only the current lint function and H were called.
No inherited command strings were executed, no live preflight/promotion/delivery replay occurred.

| Case | Existing admission | H warning | Desired warning | Interpretation |
|---|---|---|---|---|
| constant-printf | accept | yes | yes | Fixed-output positive caught |
| wrapped-constant | accept | no | yes | False negative: env wrapper |
| input-dependent-printf | accept | yes | no | False positive: Git output is measured |
| specialized-pipeline | accept | yes | no | False positive: JSON parser accepts known input |
| unrelated-regression | accept | no | no | Real regression check, not GH1448 acceptance |
| option-refusal | refuse at -q | no | no | Existing command-form mismatch preserved |
| retained-consult (GH1243) | accept | no | no | Specialized file probe preserved |
| retained-clock (GH1254) | accept | no | no | Specialized AST assertion via /dev/stdin preserved |

H totals: 1 true positive, 2 false positives, 1 false negative, 4 true negatives. Existing admission
matched 8/8 predeclared expectations. These counts score the selected sample against declared
expert labels; they are not population precision/recall or observed agent-effectiveness estimates.
The negative labels mean valid specialized checks in their stated contexts, not proof that every
check establishes its owning task's outcome. `pytest -q test/` is syntactically plausible but
actually refused by the path filter; this study neither executed it nor relaxed that refusal.
The unrelated regression is syntactically/admission-valid yet irrelevant to proving GH1448's
outcome: H's silence is not semantic acceptance. Both constant commands remain admitted by Jog;
that is a quality false negative if admission is mistaken for quality certification, not a breach
of a promised semantic contract. No additional production frequency was established.

The existing GH1447 seven-case replay was consumed, never rerun: inline `python3 -c` refused,
repaired script forms accepted, empty/trivial/missing refused. Its results/provenance hashes are
in this study's provenance. Those historical controls establish the concrete compatibility
mismatch; our new -q control witnesses the same token-position assumption without exempting
arbitrary options. H's adverse controls are retained unchanged, not tuned into passing examples.

### Exact non-executing calculation

From repository root, the evaluation's decisive calculation was:

```python
import json, re, sys
from pathlib import Path
sys.path.insert(0, str(Path.cwd() / 'utils/py'))
from jog_run import lint_probe
inputs = json.loads(Path('TESTS-RESULTS/2026-11-12+GH-1448/cases.json').read_text())
assert len(inputs['cases']) == 8
for case in inputs['cases']:
    admitted, reason = lint_probe(str(Path.cwd()), case['cmd'])
    warning = bool(re.match(r'^(?:printf|echo|true|exit\s+0)(?:\s|$)', case['cmd'].strip()))
    print(case['name'], admitted, reason, warning, case['desired_warning'])
```

`results.json` retains actual rows/counts and `provenance.jsonl` retains timestamps, source/input
hashes and exit status. Nonempty inputs and outputs were asserted before recording. This snippet
is an audit recipe, not a new executable suite or runner. Do not execute the case command strings.

## Traced boundaries and writers

| Boundary | Current owner and behavior | Consequence |
|---|---|---|
| Authoring | Existing PROJECT captures/working Preflight Contract JSON and legacy frontmatter | The author chooses a probe and polarity; neither syntax nor a green regression proves relevance |
| Legacy extraction | jog_run.extract_probes_from_doc, lines 1596–1619 | Regex extracts frontmatter strings; despite docstring, no general body-command extraction |
| JSON extraction | swarm_preflight.extract_contract, lines 89–194; jog_run.contract_probes_from_doc, lines 1624–1674 | Heading/fenced JSON plus shape checks; Jog validates allowed types/required values, calls lint_probe for command probes, does not execute them |
| Command admission | jog_run.lint_probe, lines 1568–1590 | Empty/trivial filter then whitespace token 1 path/glob lookup for bash/sh/python3/pytest; not shell parsing or semantic proof |
| Promotion | jog_run.promote_contract_to_working, lines 1677–1807; run caller around 2425 | Lints legacy strings; if none valid, tries JSON probes; unattended no-valid-probe refusal. Writes working doc and stages/removes source only after admission |
| Ledger | Promotion's releases_app.py repoint/pickup; task clone branch returns via jog_commit_execution_contract before primary repoint | Existing canonical PRS writer; this study used pickup/repoint/update in its own checkout, never invoked promotion or wrote primary |
| Evaluation | swarm_preflight.eval_probes, lines 243–296; caller at 1414 | Command shell runs at resolved target.ref worktree. A failed command is `landed` by default; with expect_nonzero, success is `landed`. Counts derive stale/blocked/ambiguous preparation state, not final delivery |

The original -c mismatch is real: Jog looks for a path named -c, preflight can execute a shell
command. It is not evidence that the inline command is relevant. Existing refusals stay intact.
The retained /dev/stdin form passes because that path exists, not because Jog understood its AST
assertion. Changing only command token exemptions could silently broaden admission without
adding the semantic guarantee the user sought. Do not conflate these separate problems.

## Alternatives and maintenance cost

A hard refusal for all printf-prefixed probes would block two legitimate cases in this sample.
An advisory warning avoids blocking but still imposes interpretation/noise on the author. A
shared rule in preflight would also alter the independent CLI's acceptance surface; no observed
need warrants coupling those paths here. Extending TRIVIAL_PROBE_PATTERNS would be the smallest
existing hard-filter site, but is the wrong severity for this ambiguous signal.

A narrower constant-only recognizer could avoid these particular pipeline/substitution false
positives. It was not evaluated and is not disproven by H's results. Correctly distinguishing
quoted literals, expansions, redirections, wrappers, shell functions and downstream status adds
maintenance; recognizing one spelling still says nothing about a valid unrelated regression or
a file script returning a constant. The sample contains no retained production fixed-output
incident from which to estimate the benefit of that maintenance. Therefore defer such code,
not because it is impossible, but because net usefulness is unestablished within this budget.

The zero-code alternative is already available: use supported script probe forms for concrete
compatibility failures, and ask reviewers what artifact/outcome is observed plus where the
unchanged candidate fails. This does not claim that GH1447 wording has proven agent effectiveness.
Revisit with repeated retained fixed-output preparation mistakes, expected labels from actual
users, and an exact narrow rule that preserves specialized checks. Any future compatibility
extension needs its own valid/invalid option controls; never blanket-exempt option tokens.

Rollback: this evidence/PRS change is Easy to revert; runtime rollout is none. No restoration of
other checkout state, merge, cleanup or Pulse action is part of the result.

## Acceptance and consumer smoke

Main consumer (preparing GH1448): report distinguishes unchanged runtime from delivered evidence;
its conclusions require measured rows and negative controls, not the unrelated codex regression's
passing exit. Adjacent consumer (specialized JSON/AST probe): the report records H false positives
and explains why a valid specialized assertion must not be rejected merely for a printf prefix.
These are source/report read-through observations, not executed agent or end-to-end workflow tests.
Read-through passed; no executable feature was introduced, so no new runtime main path exists.

The existing Codex turn prerequisite suite ran in an independent disposable full clone: 43 pass,
0 fail, pre/post HEAD/core.bare/origin/local email unchanged. This is harness readiness evidence,
not acceptance of a new linter. Plan QA Approved. PDDA exited 0 (101 existing governance/issue-sync/marathon warnings,
no errors); PRS check exited 0 (10 warnings); classifier route=docs/tier=1. Final QA and exact-head
publication gate will be recorded separately. No full gate is requested for this documentation/evidence/PRS diff unless
the existing classifier routes it there.

## Lessons Learned

| Changed component | Edit verdict | Basis |
|---|---|---|
| Research record | helped | Predeclared controls exposed H's false positives/negative |
| Production validators | no observed effect | Unchanged source; no runtime benefit claimed |
| PRS/docs lifecycle | confounded | One execution, no effectiveness comparison |

NO_ENTRY: bounded findings are task-specific; no general operational-effectiveness lesson is
established. Existing GH1447 guidance remains the baseline. This report is the task's decision
record rather than a new standing rule.
