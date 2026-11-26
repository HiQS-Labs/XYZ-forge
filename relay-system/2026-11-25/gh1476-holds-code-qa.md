# RELAY · GH-1476 holds-only code review
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-11-25.
-->

NEXT: Reviewer
STATUS: Open
ROUND: 3 / 4

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
     change MUST carry `Observed input:`, `Affected scope:` (the input predicate the change would govern),
     and `Falsifier:` (the fixture or data that would show the change unnecessary or wrong, and its expected
     result). `Observed input:` accepts two strict, non-speculative forms:
     (1) **Form 1 (observed failure or artifact contradiction):** a failing probe/gate output, or a concrete
     `fileA:line` vs `fileB:line` contradiction (e.g. IAM SA mismatch, inverted test, sibling guard omission);
     (2) **Form 2 (unrunnable runtime hazard trace):** permitted ONLY when reproduction requires an external
     service, multi-process concurrency, or a browser/container runtime forbidden in the relay worktree —
     must supply a hop-by-hop `file:line` trace plus an exact `Clone probe:` command/script for the Producer's
     disposable full clone. Default severity for an unexecuted Form 2 hazard is `[Should]`.
     A `[Blocker]` must cite an observed failure (Form 1); an unexecuted Form 2 hazard stays `[Should]`
     until a probe reproduces it, and remains pending probe verification until the Producer runs
     `Clone probe:` in a disposable full clone.
     A finding from an earlier round stays open, and the verdict stays failing, until new evidence closes it.
     This includes earlier [Nit] findings; only a newly raised [Nit] with VERDICT: PASS on STATUS: Approved remains optional.
     This is a protocol rule, not a mechanical check —
     the Producer may disposition a request lacking Form 1 evidence and lacking a complete Form 2 trace + `Clone probe:` as `Declined — unproven generalization`.
   - **Producer:** log a disposition for every open finding (Implemented / Modified / Declined + why,
     including `Declined — unproven generalization` for a behaviour-change request lacking Form 1 evidence and
     lacking a complete Form 2 trace + `Observed input:` / `Affected scope:` / `Falsifier:` / `Clone probe:`).
     For every Form 2 `Clone probe:` finding, read the probe before running it — refuse any probe that reaches
     the network, credentials, or paths outside the disposable clone and record the refusal as
     `[Unverified — clone probe failed/unavailable]` — then execute safe probes in a disposable full clone and
     record one of three outcomes: (a) Reproduced → fix and paste failing-before / passing-after probe output;
     (b) Falsified → `Declined — falsified by clone probe: <cmd → exit + output>`; (c) Errored, refused, or
     environment unavailable → keep the finding OPEN (`[Unverified — clone probe failed/unavailable]`, blocking
     `STATUS: Approved` until re-run cleanly or escalated/parked). Make approved changes, then add new work.
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
   Reviewer headings may be `### Reviewer · Round N`, `### Round N · Reviewer · <agent>`, `### Reviewer (<agent>)` (optionally followed by `— rN`), or `### Reviewer — Round N` (optionally followed by `(<agent>)`); follow the heading with a non-empty review body.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Manual relay: commit only the relay file** (`relay(gh1476-holds-code-qa): <role> r<N>`); no push.
   **Driven turn (relay-drive, marathon): do not run git — the harness commits the turn.** **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. (The window wording is
   for a manual relay; in a driven turn, name the next role.) The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **.relay-artifacts/gh1476-holds-whole-diff.patch** — the read-only path that
  `relay-drive.sh --artifact-file /private/tmp/claude-501/gh1476-review/gh1476-holds-whole-diff.patch` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-11-25
- Definition of Done: Independent code review of the WHOLE diff `086b657ea..cb8983d6f` (merge-base to head; seeded read-only as `.relay-artifacts/gh1476-holds-whole-diff.patch`; the repo worktree at the head is also readable). The code change is `utils/py/jog_run.py` (`hold_refusal`, `_gh_issue_json`, one call in the `jog run` loop before the lease, one in `_jog_retry_build_locked` before its lease) plus fixture/replay edits in `test/gh280-jog-marathon-adapter.sh` and `TESTS-RESULTS/2026-11-25+GH-1476-day1/control.txt`; the rest of the diff is plan text, relay transcripts and evidence (`TESTS-RESULTS/2026-11-25+GH-1476-holds/`, red on base `641558361`, green on the change, existing suites identical before and after).
  **Scope is settled** by the operator decisions on #1476 and the approved plan, section "Holds-only repair plan" in `PROJECT/2-WORKING/GH-1476-RAW-TASK-PREPARATION.md`: before a task is promoted out of the inbox or handed to a worker, refuse it on a hold in the live issue, a hold in the capture document, or referenced work not confirmed done; if the check cannot be made, hold; refusal starts no worker, consumes no attempt, leaves the capture in place, records the reason via the existing `jog_set_status`. Out of scope (NOT findings): trusted-copy / managed-identity withdrawal, missing prior attempt key, operator-decision comments, `--dry-run` readiness, reviewed-source binding. Partial progress, no OL-10 credit. No new test suite (GH-831).
  **A finding is:** a hold or unfinished dependency that can still reach a worker (a path that bypasses the helper, a false negative in what the helper reads); a refusal that consumes an attempt, promotes the capture, or writes an execution record; a regression for ready work or existing callers (queue loop, supervised/checkpoint modes, `--simulate`, retry-build, vendored layout); a defect in the helper (import by path, frontmatter handling, dependency "done" test, fail-closed behaviour); an evidence/provenance claim the logs do not support; unsafe or non-surgical code. Every Blocker/Should needs `Observed input:`, `Affected scope:`, `Falsifier:`. Measure read-only; do not run suites.
  **Questions (cite file:line):** Q1 Does `hold_refusal` fail closed on every unavailable input and never mask a hold as unavailable (or the reverse)? Q2 Are both call sites placed before the lease and before promotion/execution records, with correct control flow for checkpoint/supervised/non-supervised and `--simulate`? Q3 Is the dependency-done test and the `AFTER`-based open-reference collection correct (`build_queue.py:89,182–201`)? Q4 Do the replay assertions measure what the evidence claims (exact calls, attempt count, capture bytes/location, execution count, specific reason) and do the base logs show red for the stated reason? Q5 Is `provenance.jsonl` truthful (shas, runtime_sha, run labels)? Q6 Are the gh280 / replay fixture edits minimal and correct for root and vendored shapes? Q7 Anything over-built?

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). In a manual relay, end each turn by committing just this file; no push. In a driven turn the harness commits.

## Log

### Reviewer · Round 1 · codex

VERDICT: FAIL
Basis: Block pending the findings below. The two pre-lease insertions and normal hold cases are sound, but ambiguous capture resolution skips real holds, malformed live-issue objects can pass or crash instead of parking, and the replay cleanup and preservation assertions need correction. These are measured helper failures or source/artifact contradictions, not claims of an end-to-end run in this worktree.

swept file: yes
gate run: no

Swept the full `utils/py/jog_run.py`, `test/gh280-jog-marathon-adapter.sh`, replay and drivers, and reviewed the seeded diff's plan/history/evidence within the settled holds-only scope. The pre-existing resolver/Preflight disagreement relevant to this change is included in B1; no other in-scope pre-existing defect was established. No Git command, suite, executable fixture, worker, network request, or deletion ran. Temporary probe data stayed under `.relay-scratch/tmp`. There is no configured phase gate to assume after this turn.

- [Blocker] **B1 — Ambiguous captures are treated as a raw issue with no capture, bypassing a real hold (Q1/Q2).**
  **Observed input:** Form 1, probe P1 below: two files `PROJECT/2-WORKING/GH-901-A.md` and `GH-901-B.md`, each containing exactly `---\ngh_issue: 901\n---\nHELD: owner decision\n`, with a clean live issue. The actual resolver functions returned `None`, and the actual `hold_refusal` returned `None`. `wave_reconcile.py:1124–1130` intentionally leaves an ambiguous identity unresolved; `:1134–1138` collapses it to `None`. `jog_run.py:1683–1687,1701–1705` then skips capture checking. The loop consequently reaches its lease at `:2956`, and the phase appends an execution at `:624–640`. Preflight does not share that refusal: `utils/py/swarm_preflight.py:1439–1446` takes `matches[0]` when multiple working captures exist. Thus this is not the approved raw-issue/no-document exception: both documents exist and both are held. A complete worker replay was not run here.
  **Affected scope:** Issues with multiple unresolved matching capture identities, on `jog run` and `retry-build`. Preserve the legitimate zero-capture case and existing uniquely resolved captures.
  **Fix:** Distinguish a genuinely absent capture from an unresolved/ambiguous capture at this read boundary, reusing the resolver's existing candidate information. Return a specific unavailable/ambiguous refusal before the lease; do not choose an arbitrary candidate or introduce a second document-selection policy.
  **Falsifier:** With two otherwise executable working captures for #901, both held, both entry points must park with zero calls, unchanged attempts and zero new executions. A unique clean capture and a genuinely absent capture must retain their intended existing behavior. If the resolver can prove one authoritative capture in the two-file case, show that binding and that the same file is used downstream; the supplied no-hint input has no such binding.

- [Should] **S1 — Validate the live issue's required fields and contain recognizer errors (Q1).**
  **Observed input:** Form 1, P1: successful subprocess output `{}` and `{"state":"OPEN","labels":[]}` each returned `None` from `hold_refusal`; `{"state":"OPEN","body":"Ready","labels":["status:held"]}` raised `AttributeError: 'str' object has no attribute 'get'`. `_gh_issue_json` validates only `dict` at `jog_run.py:1654–1657`; `:1690` fills missing body with empty text, and `:1691–1702` invokes the recognizer outside the exception boundary. This contradicts `:1668`'s unavailable-check refusal contract. The malformed-label example is a malformed-response control, not an assertion that standard GitHub emits string labels.
  **Affected scope:** Incomplete or malformed successful responses for the primary live-issue hold check. Valid empty bodies/label lists must continue to work; dependency lookup failure already remains unresolved and must stay so.
  **Fix:** Check the required response shape before treating it as complete hold evidence; map invalid shape/recognizer failure to a specific `hold-check-unavailable` reason through the existing park path. Do not turn a valid positive hold into a generic lookup error.
  **Falsifier:** The supplied objects must refuse without an uncaught exception, while the valid `Ready` object returns `None` and the valid `HELD:` object returns `hold: issue body HELD: marker`, as the positive controls in P1 already do.

- [Should] **S2 — Remove or contain the replay driver's log-derived recursive deletion (Q7).**
  **Observed input:** Form 1: `TESTS-RESULTS/2026-11-25+GH-1476-holds/run-cases.sh:21–22` extracts a path from output and accepts `/private/tmp/*|/tmp/*|/var/folders/*` directly before `rm -rf`. A non-deleting shell probe of that exact case pattern accepted `/tmp/` itself, as well as `/tmp/../Users`; `os.path.realpath` resolved the latter to `/private/Users` on this host. This is the lexical-prefix failure explicitly prohibited by AGENTS.md's GH-567 use-boundary rule. No operand was deleted or traversed by a cleanup command.
  **Affected scope:** Only this newly retained replay driver's cleanup of paths taken from log text; it must never authorize deleting the temporary root, an unrelated sibling, or an escaped path.
  **Fix:** The simplest correction is to retain/report the fixture instead of automatically deleting a log-supplied path. If cleanup is retained, pin a driver-owned sandbox and require a resolved, strict descendant of that sandbox with the expected fixture identity at the deletion boundary; a temporary-directory prefix alone is insufficient.
  **Falsifier:** A dry/non-deleting evaluation must reject `/tmp/`, `/tmp/../Users`, empty paths, symlink escapes, and unrelated temporary directories while accepting only the exact owned disposable fixture. Any eventual deletion exercise belongs in the Producer's disposable clone and must stay inside its sandbox.

- [Should] **S3 — Make the replay's preservation assertions cover the stated contract (Q4).**
  **Observed input:** Form 1 source contradiction: the plan at `PROJECT/2-WORKING/GH-1476-RAW-TASK-PREPARATION.md:460–464` promises an assertion that `.tick/attempts` is unchanged. `TESTS-RESULTS/2026-11-25+GH-1476-day1/control.txt:265` snapshots only queue attempts, capture SHA and execution count; `:275` merely prints the post-run native file count; `:280–284` never checks native names/bytes. Also, `:263` returns the successful string `MISSING` for an absent capture, so `:282` accepts `MISSING == MISSING` as unchanged without establishing a nonempty capture. The historical stale branch at `:290–300` is not exercised by the holds driver's case table (`run-cases.sh:24–34`) and cannot supply this assertion for the new refusal cases.
  **Affected scope:** The existing manual replay's zero-call refusal assertions, not a new suite or runtime gate. Current logs show zero native files after the held cases, but do not establish the claimed before/after byte-preservation check.
  **Fix:** In the existing replay, require the expected capture to exist and be nonempty before recording its digest, and compare a before/after map of native attempt names and bytes (including the empty-map case). Keep the existing exact call count, parked reason, lease count and execution count checks. Record controlled failures for a missing capture and a changed native byte so the assertions are demonstrably sensitive.
  **Falsifier:** A refusal with a missing capture or changed native attempt content must fail its assertion even when the worker-call count is zero; an actual held task with unchanged capture and native state must pass. No new test file or runner is needed.

- [Nit] **N1 — Label baseline controls as controls, not red reproductions (Q5).** `TESTS-RESULTS/2026-11-25+GH-1476-holds/provenance.jsonl:5,8,12,14` labels `dep-done`, `inbox-ready`, `ready`, and `retry-ready` as `manual-fixture-replay-red`, although their baseline logs say `ASSERT ... expected_calls=1 PASS` (`base/dep-done.log:35`, `base/inbox-ready.log:36`, `base/ready.log:35`, `base/retry-ready.log:31`). The plan explicitly requires controls at `:460–461`. Correct those four classifications without rewriting historical logs or calling the expected sentinel exit 9 a failed admission control.

- [Pass] **Q2 — The actual refusal branches precede lease, promotion and dispatch.** `jog_run.py:2945–2953` precedes the lease at `:2956`, promotion at `:2968`, Marathon call at `:2987` and legacy worker at `:3056`; retry's branch at `:1111–1115` precedes `:1116–1117`. `releases_app.py:5125–5127` changes status/reason/lease without assigning `attempt_count`. Counting under supervised/checkpoint, checkpoint `break`, and otherwise `continue` remove the parked row from the pending selector at `jog_run.py:2907–2912`. `--simulate` skips this new check at `:2945`; dry-run returns earlier at `:2837`. This pass concerns placement/control flow, not the failed input checks in B1/S1.

- [Pass] **Q3 — Conditional references and positive done predicates match the settled plan.** `jog_run.py:1691` uses the same sanitized `AFTER` matches as `build_queue.py:197–200`, deduplicates them, and `:1694–1697` treats unavailable/unknown as unresolved. The unchanged label/HELD/Blocked-by/active-after branches remain unconditional (`build_queue.py:184–196`). The separate in-memory dependency probe yielded: OPEN issue → `hold: issue after #902`; CLOSED issue → `None`; CLOSED PR → hold; MERGED PR → `None`; `{}` dependency → hold. This verifies the supplied-response truth table, not live GitHub transport.

- [Pass] **Q4/Q6 — Retained logs support the normal changed behavior and fixture repair.** `change/issue-hold.log:3–9`, `change/capture-hold.log:3–9`, and `change/retry-hold.log:3–8` under `TESTS-RESULTS/2026-11-25+GH-1476-holds/` show the intended specific hold reasons, zero worker calls, unchanged queue attempts/capture/execution counts. Their base counterparts record one call and an explicit failed zero-call assertion, rather than an unrelated setup failure. Ready and closed-issue-dependency controls record one call on both revisions. The copies at `test/gh280-jog-marathon-adapter.sh:169–171` and `control.txt:163–165` install the recognizer under the executing module's root or `.xyz/` prefix, matching `jog_run.py:1671`. The gh280 issue-view shim at `:55–60` accepts the new fields. The retained root/vendored suite reports 227 pass, 0 fail on each revision (`suites-base/gh280-jog-marathon-adapter.sh.log:230`, `suites-change/gh280-jog-marathon-adapter.sh.log:230`); these are inspected Producer receipts, not tests rerun by this Reviewer. S3 limits the preservation claim.

- [Pass] **Q5/Q7 — The source change is small and reuses the existing owners.** The seeded patch at `.relay-artifacts/gh1476-holds-whole-diff.patch:3295–3398` adds two helpers and two call sites, without a new scheduler, schema or hold grammar. A read-only patch-hunk comparison found all 3,080 new/context lines across 52 files equal to the local files; seeded SHA-256 is `69a8e19903fcbae14224bbd11058718c71a267cd39540ba978f9c9a50a8cb293`. All 37 artifacts named by the holds provenance were nonempty and matched their recorded SHA-256. The suite summaries record base `64155836` and candidate `27ab5687` at `suites-base/summary.txt:1–5` / `suites-change/summary.txt:1–5`, consistent with the provenance runtime prefixes. Git history/runtime equivalence to final head `cb8983d6f` was not independently inspected under the no-Git restriction; this is not final-head gate qualification. N1 corrects the run labels.

**P1 — exact narrow probe command and decisive output (exit 0).** It compiles only the named functions from source, uses an in-memory subprocess response, and creates only two temporary Markdown inputs under scratch. The resolver's unrelated ledger hint lookup is replaced with an empty list (the no-hint case); no Git, database writer or remote service is called.

```sh
export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"
mkdir -p "$TMPDIR"
python3 - <<'PY'
import ast, json, os, re, tempfile
from pathlib import Path
from types import SimpleNamespace

def defs(path, names, ns):
    tree = ast.parse(Path(path).read_text())
    selected = [n for n in tree.body if isinstance(n, (ast.FunctionDef, ast.AsyncFunctionDef)) and n.name in names]
    assert len(selected) == len(names)
    exec(compile(ast.Module(body=selected, type_ignores=[]), path, 'exec'), ns)

source = 'utils/py/jog_run.py'
ns = {'Path': Path, '__file__': str(Path(source).resolve()), 'json': json,
      'subprocess': SimpleNamespace(run=lambda *a, **k: SimpleNamespace(returncode=0, stdout=json.dumps(payload))),
      'find_issue_doc': lambda *a: None}
defs(source, {'_gh_issue_json','hold_refusal'}, ns)
for payload in [{}, {'state':'OPEN','labels':[]}, {'state':'OPEN','body':'Ready','labels':['status:held']},
                {'state':'OPEN','body':'Ready','labels':[]},
                {'state':'OPEN','body':'HELD: owner decision','labels':[]}]:
    try: outcome=repr(ns['hold_refusal']('.',901))
    except Exception as e: outcome=type(e).__name__+': '+str(e)
    print('issue=',json.dumps(payload),'result=',outcome)

ws={'Path':Path,'os':os,'re':re,'ledger_rows':lambda *a:[]}
defs('utils/py/wave_reconcile.py', {'parse_doc_frontmatter','doc_issue_number','issue_doc_index','find_issue_doc'},ws)
root=Path(tempfile.mkdtemp(prefix='holds-read-probe-',dir=os.environ['TMPDIR']))
d=root/'PROJECT'/'2-WORKING'; d.mkdir(parents=True)
for name in ['GH-901-A.md','GH-901-B.md']:
    (d/name).write_text('---\ngh_issue: 901\n---\nHELD: owner decision\n')
payload={'state':'OPEN','body':'Ready','labels':[]}
ns['find_issue_doc']=ws['find_issue_doc']
print('ambiguous docs=',[p.name for p in sorted(d.glob('*.md'))], 'resolver=',ws['find_issue_doc'](root,901),'hold_refusal=',repr(ns['hold_refusal'](root,901)))
PY
```

```text
issue= {} result= None
issue= {"state": "OPEN", "labels": []} result= None
issue= {"state": "OPEN", "body": "Ready", "labels": ["status:held"]} result= AttributeError: 'str' object has no attribute 'get'
issue= {"state": "OPEN", "body": "Ready", "labels": []} result= None
issue= {"state": "OPEN", "body": "HELD: owner decision", "labels": []} result= 'hold: issue body HELD: marker'
ambiguous docs= ['GH-901-A.md', 'GH-901-B.md'] resolver= None hold_refusal= None
```

**P2 — non-deleting cleanup predicate probes (each exit 0):**

```sh
fixture=/tmp/../Users
case "$fixture" in /private/tmp/*|/tmp/*|/var/folders/*) printf 'cleanup pattern accepts %s\n' "$fixture" ;; esac
python3 - <<'PY'
import os
print('resolved cleanup operand:',os.path.realpath('/tmp/../Users'))
PY
fixture=/tmp/
case "$fixture" in /private/tmp/*|/tmp/*|/var/folders/*) printf 'cleanup pattern accepts temp root: %s\n' "$fixture" ;; esac
```

```text
cleanup pattern accepts /tmp/../Users
resolved cleanup operand: /private/Users
cleanup pattern accepts temp root: /tmp/
```

**P3 — dependency truth table and artifact consistency (exit 0), supporting the passes above:**

```sh
export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"
python3 - <<'PY'
import ast, hashlib, json, re
from pathlib import Path
from types import SimpleNamespace
source='utils/py/jog_run.py'
ns={'Path':Path,'__file__':str(Path(source).resolve()),'json':json,'find_issue_doc':lambda *a:None}
ns['subprocess']=SimpleNamespace(run=lambda argv,**kw:SimpleNamespace(returncode=0,stdout=json.dumps({'state':'OPEN','body':'This work comes after #902 here.','labels':[]} if argv[3]=='901' else dep)))
tree=ast.parse(Path(source).read_text())
exec(compile(ast.Module(body=[n for n in tree.body if isinstance(n,ast.FunctionDef) and n.name in {'_gh_issue_json','hold_refusal'}],type_ignores=[]),source,'exec'),ns)
for dep in [{'state':'OPEN','url':'https://github.com/example/example/issues/902'},{'state':'CLOSED','url':'https://github.com/example/example/issues/902'},{'state':'CLOSED','url':'https://github.com/example/example/pull/902'},{'state':'MERGED','url':'https://github.com/example/example/pull/902'},{}]:
    print(json.dumps(dep),'=>',repr(ns['hold_refusal']('.',901)))
p=Path('TESTS-RESULTS/2026-11-25+GH-1476-holds/provenance.jsonl')
rows=[json.loads(x) for x in p.read_text().splitlines()]
for r in rows:
    raw=(Path('TESTS-RESULTS')/r['artifact']).read_bytes()
    assert raw and hashlib.sha256(raw).hexdigest()==r['sha256'],r['artifact']
print('nonempty matching provenance artifacts:',len(rows))
seed=Path('.relay-artifacts/gh1476-holds-whole-diff.patch')
idx=None; checked=0; files=set()
for line in seed.read_text().splitlines():
    if line.startswith('+++ b/'):
        path=line[6:]; actual=Path(path).read_text().splitlines(); files.add(path); idx=None
    elif line.startswith('@@'): idx=int(re.search(r'\+(\d+)',line)[1])-1
    elif idx is not None and line.startswith(('+',' ')):
        assert actual[idx]==line[1:],(path,idx+1)
        idx+=1; checked+=1
    elif line.startswith('diff --git'): idx=None
print('seed hunk lines match local files:',checked,'files:',len(files))
print('seed sha256:',hashlib.sha256(seed.read_bytes()).hexdigest())
PY
```

```text
{"state": "OPEN", "url": "https://github.com/example/example/issues/902"} => 'hold: issue after #902'
{"state": "CLOSED", "url": "https://github.com/example/example/issues/902"} => None
{"state": "CLOSED", "url": "https://github.com/example/example/pull/902"} => 'hold: issue after #902'
{"state": "MERGED", "url": "https://github.com/example/example/pull/902"} => None
{} => 'hold: issue after #902'
nonempty matching provenance artifacts: 37
seed hunk lines match local files: 3080 files: 52
seed sha256: 69a8e19903fcbae14224bbd11058718c71a267cd39540ba978f9c9a50a8cb293
```

Evidence boundary: Verify-tier discovery used graph project `Users-noelsaw-Documents-GH-Repos-XYZ-forge`, generation `2026-11-25T18:19:12Z`, which indexes another checkout and lacks the new helper/evidence. Coverage reported gh280 lines 729–730 partial and the new evidence paths missing; local full-file/source reads supplied the evidence, including those ranges. Graph trace was denied by the tool's approval policy, so no graph-completeness claim is made. Full dispatch and gate verification remain **[Unverified — needs clone run]** for the new counterexamples.

Handing off to Producer (claude-a) — disposition B1, S1–S3 and N1, make the bounded corrections and retain failing-before/passing-after evidence in a disposable full clone before the next review.

### Producer · Round 1

Dispositions (all five accepted and implemented; repairs at `bba006ffc`, evidence at `d554ed3b8`; the next review range is `086b657ea..<head>`, the seeded patch is regenerated at that head):

- **B1 Implemented.** `hold_refusal` now refuses with `hold-check-unavailable: ambiguous capture documents` when `find_issue_doc` returns None while candidates exist. To reuse the resolver's own candidate information without a second selection policy, `utils/py/wave_reconcile.py` moves its candidate collection into `_issue_doc_candidates` (used unchanged by `issue_doc_index`) and exposes `find_issue_doc_candidates`; the existing resolver behaviour is unchanged (gh202, gh454, gh232, gh168 identical on base and change). Replay case `ambiguous` (two working captures for #901, one held), on `jog run` and `jog retry-build`: red on base (1 call), green on change (0 calls, reason named, attempts/capture/executions unchanged). A genuinely absent capture and a unique clean capture keep their behaviour (`ready`, `inbox-ready` controls).
- **S1 Implemented.** Required response shape is checked (`body` string, `labels` list) before use, and the recognizer/dependency block is inside an exception boundary mapping to `hold-check-unavailable: hold rules failed (<type>)`; valid empty bodies and a valid HELD body behave as before. Replay cases `issue-malformed` (`{}`) and `issue-badlabels` (`["status:held"]`): red on base, green on change with the specific reasons.
- **S2 Implemented.** `run-cases.sh` no longer deletes a path read from a log; each case runs with a `TMPDIR` created by the driver and only that directory is removed.
- **S3 Implemented.** The replay requires a nonempty capture before the run, snapshots a native attempt name+byte map before and after and compares it, and carries `MUTATE=native|capture` red controls that fire on the change (`capture-hold-mutate-native`, `issue-hold-mutate-capture` report FAIL with 0 calls).
- **N1 Implemented.** `provenance.jsonl` labels baseline expected-call cases `manual-fixture-replay-control`, and the mutation rows `manual-fixture-assertion-red-control`; the first review's passes stand.

Existing suites on committed state in one disposable clone, base `641558361` vs change `bba006ffc`: jog-queue, gh280 (227 pass / 0 fail both), gh291, gh505, gh202, gh454, gh232, gh168 all rc=0 on both. Handing off to Reviewer for round 2.

### Reviewer · Round 2 · codex

VERDICT: FAIL
Basis: Block. B1's no-hint case is repaired, but a ledger hint can still make the hold checker and Preflight select different captures, admitting a held capture. S1 also remains incomplete for label objects without usable names. S2, S3 and N1 are closed by the evidence below.

swept file: yes
gate run: no

Swept the complete `utils/py/jog_run.py`, `utils/py/wave_reconcile.py`, `test/gh280-jog-marathon-adapter.sh`, the replay and both retained drivers; inspected the seeded whole diff and its retained evidence within the settled holds-only scope. B1 is the remaining in-scope pre-existing resolver/Preflight disagreement; no additional in-scope pre-existing defect was established. No Git command, suite, full fixture, network request or worker ran. The probes below execute only extracted read/decision functions against in-memory responses and scratch files. No phase gate is configured. End-to-end verification of the remaining counterexamples is **[Unverified — needs clone run]**.

- [Blocker] **B1 remains OPEN — a uniquely hinted capture is not necessarily the capture Preflight executes (Q1/Q2).**
  **Observed input:** Form 1, P4 below (exit 0): two working captures declare `gh_issue: 901`. The first path returned by the actual filesystem glob contains `HELD: owner decision`; the other contains `Ready`, and the ledger hint names that clean document. The actual resolver chooses the hinted clean capture, the actual Preflight source selector chooses the held one, and the actual `hold_refusal` returns `None`. On this run the outputs were `hold resolver: GH-901-A.md`, `preflight selection: GH-901-B.md`, `selected capture body: HELD: owner decision`, `hold_refusal: None`. This is the concrete contradiction: `wave_reconcile.py:1123–1136` honors the hint; `jog_run.py:1686–1690` checks only that result and only consults candidates when it is None; dispatch at `jog_run.py:644–647` passes `--gh-issue`, so `swarm_preflight.py:1439–1446` independently takes `matches[0]`. The refusal is bypassed before the lease at `jog_run.py:2964`; this probe does not claim a worker was launched here.
  **Affected scope:** Multiple primary working captures where a ledger hint resolves to a different document from Preflight's issue-mode selection. Both `jog run` and `retry-build` use this path. This is capture-selection consistency for the hold check, not the explicitly excluded reviewed-source attestation work.
  **Fix:** Make admission and execution consume the same existing canonical capture selection, or refuse before the lease when they cannot be made consistent. Do not treat a non-None resolver result alone as proof that the downstream document was checked. Preserve unique and genuinely absent capture behavior.
  **Falsifier:** In a disposable clone, make two otherwise executable working captures, put a hold only in the actual Preflight-selected one, and point the ledger hint at the clean other one. Both entry points must either refuse with zero worker calls/attempts/executions and unchanged captures, or demonstrably execute the same clean authoritative document they checked. The supplied current input does neither at the selection boundary. Retain the existing no-hint ambiguous and unique-ready controls.

- [Should] **S1 remains OPEN — a labels list with incomplete objects still passes (Q1).**
  **Observed input:** Form 1, P4: with `state="OPEN"`, `body="Ready"`, `labels=[{}]` and `labels=[{"name":null}]` both produce `None`. The new check at `jog_run.py:1681` validates the list container only; `build_queue.py:184` turns either missing name into an empty string, so the exception handler never fires. This is an incomplete-response control, not a claim that normal GitHub responses use these shapes. The original `{}`/missing-body/string-label examples are now correctly refused (`change/issue-malformed.log:3–8`, `change/issue-badlabels.log:3–8`).
  **Affected scope:** Primary issue responses whose label entries lack a usable string name. A valid empty labels list remains valid.
  **Fix:** Validate the label entries needed by the hold recognizer before using their absence of `status:held` as evidence of readiness; return the existing unavailable refusal for incomplete entries. Keep positive valid hold detection and valid ready responses unchanged.
  **Falsifier:** The two supplied incomplete-label responses must refuse without an exception, `labels=[]` with a clean body must return None, and `labels=[{"name":"status:held"}]` must retain `hold: issue label status:held`.

- [Pass] **S2 closed (Q7).** `TESTS-RESULTS/2026-11-25+GH-1476-holds/run-cases.sh:20–31` now obtains its deletion operand directly from a successful `mktemp -d` and does not derive it from log contents. The prior `/tmp/` / traversal acceptance path is gone. This is source inspection; no cleanup was executed by the Reviewer.

- [Pass] **S3 closed (Q4).** `TESTS-RESULTS/2026-11-25+GH-1476-day1/control.txt:273–275,286–299` requires a nonempty capture before the snapshot and compares the native filename/hash map as well as queue attempts, capture digest/location, execution count, parked status and the specific reason. Both retained change-side mutation logs say `FAIL (calls=0)` at line 8: `change/capture-hold-mutate-native.log` and `change/issue-hold-mutate-capture.log` under the holds evidence directory. P5 additionally measured the actual nonempty guard and map function: an absent capture exits 1, an existing capture exits 0, and changing bytes under the same native filename changes the map. These are narrow assertion probes, not full dispatch runs.

- [Pass] **N1 closed; provenance and normal controls support their bounded claims (Q4/Q5).** `TESTS-RESULTS/2026-11-25+GH-1476-holds/provenance.jsonl:8,11,18,20` labels the four baseline expected-call cases as controls. The 55 artifacts in that manifest are nonempty and match their recorded hashes (P6). Its line 1 explicitly explains that the amended `control.txt` supersedes the historical Day 1 harness hash; that historical receipt is not current-harness proof. The summaries at `suites-base/summary.txt:1–8` and `suites-change/summary.txt:1–8` report all eight existing suites rc=0 at `64155836` and `bba006ff`; both gh280 logs end with `227 pass, 0 fail`. These are inspected Producer receipts, not rerun gates or independently proven final-head qualification.

- [Pass] **Unchanged placement/grammar/layout conclusions stand (Q2/Q3/Q6/Q7).** `jog_run.py:1111–1117,2952–2980` still checks before lease/promotion, with checkpoint break and supervised counting; simulation bypasses the helper. `:1697–1708` derives conditional references using the recognizer's own sanitized AFTER matches and treats non-confirmed dependencies as unresolved; `build_queue.py:184–200` retains its unconditional hold forms. The root/vendored fixture installs at `test/gh280-jog-marathon-adapter.sh:169–171` match the module-relative rule load at `jog_run.py:1671`. The candidate collection extraction at `wave_reconcile.py:1100–1110,1127` preserves the prior collector and selection policy. No second hold grammar or scheduler was added. B1/S1 qualify these passes.

**P4 — exact selection and response-shape probe (exit 0).** The subprocess adapters below return data in memory: even the Preflight `git rev-parse` call is replaced, so no Git command runs. The only filesystem writes are the two Markdown inputs under scratch. The ledger adapter returns the concrete hint row; all document selection logic is the actual source.

```sh
export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"
python3 - <<'PROBE'
import ast, datetime, glob, json, os, re, subprocess, sys, tempfile, types, __future__
from pathlib import Path

def defs(path,names,ns):
    nodes=[n for n in ast.parse(Path(path).read_text()).body if isinstance(n,ast.FunctionDef) and n.name in names]
    assert len(nodes)==len(names)
    exec(compile(ast.Module(body=nodes,type_ignores=[]),path,'exec',flags=__future__.annotations.compiler_flag),ns)
root=Path(tempfile.mkdtemp(prefix='holds-hinted-',dir=os.environ['TMPDIR']))
d=root/'PROJECT/2-WORKING';d.mkdir(parents=True)
for name in ['GH-901-A.md','GH-901-B.md']:(d/name).write_text('---\ngh_issue: 901\n---\nReady\n')
held,clean=[Path(p) for p in glob.glob(str(d/'GH-901-*.md'))]
held.write_text('---\ngh_issue: 901\n---\nHELD: owner decision\n')
w=types.ModuleType('wave_reconcile');w.__dict__.update(Path=Path,os=os,re=re,ledger_rows=lambda *a:[{'gh_number':901,'doc_path':str(clean.relative_to(root))}])
defs('utils/py/wave_reconcile.py',{'parse_doc_frontmatter','doc_issue_number','_issue_doc_candidates','issue_doc_index','find_issue_doc','find_issue_doc_candidates'},w.__dict__)
sys.modules['wave_reconcile']=w
src='utils/py/jog_run.py'
ns={'Path':Path,'__file__':str(Path(src).resolve()),'json':json,'find_issue_doc':w.find_issue_doc,
    'subprocess':types.SimpleNamespace(run=lambda *a,**k:types.SimpleNamespace(returncode=0,stdout=json.dumps(payload)))}
defs(src,{'_gh_issue_json','hold_refusal'},ns)
pf={'__file__':str(Path('utils/py/swarm_preflight.py').resolve()),'os':os,'re':re,'sys':sys,'datetime':datetime,
    'compute_default_root':lambda *a:(str(root),'unused'),'get_env':lambda key,default:default,
    'SourceSelection':types.SimpleNamespace,
    'subprocess':types.SimpleNamespace(check_output=lambda *a,**k:(str(root)+'\n').encode(),CalledProcessError=subprocess.CalledProcessError,DEVNULL=subprocess.DEVNULL)}
defs('utils/py/swarm_preflight.py',{'resolve_source_selection'},pf)
selection=pf['resolve_source_selection'](types.SimpleNamespace(project_doc=None,gh_issues=['901'],target_root=str(root)))
payload={'body':'Ready','labels':[],'state':'OPEN'}
print('ledger hint:',clean.name)
print('hold resolver:',Path(w.find_issue_doc(root,901)).name)
print('preflight selection:',Path(selection.primary_doc).name)
print('selected capture body:',Path(selection.primary_doc).read_text().split('---',2)[2].strip())
print('hold_refusal:',repr(ns['hold_refusal'](root,901)))
for labels in [[{}],[{'name':None}],[],[{'name':'status:held'}]]:
    payload={'state':'OPEN','body':'Ready','labels':labels}
    print('labels=',json.dumps(labels),'->',repr(ns['hold_refusal'](root,901)))
PROBE
```

```text
ledger hint: GH-901-A.md
hold resolver: GH-901-A.md
preflight selection: GH-901-B.md
selected capture body: HELD: owner decision
hold_refusal: None
labels= [{}] -> None
labels= [{"name": null}] -> None
labels= [] -> None
labels= [{"name": "status:held"}] -> 'hold: issue label status:held'
```

**P5 — exact assertion-only probe (exit 0).** It extracts only the read-only `nmap` function and capture-presence guard, not the executable replay.

```sh
export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"
python3 - <<'PROBE'
from pathlib import Path
import os, subprocess, tempfile
s=Path('TESTS-RESULTS/2026-11-25+GH-1476-day1/control.txt').read_text().splitlines()
nmap=next(l for l in s if l.startswith('nmap()'))
guard=next(l for l in s if l.startswith('[ -s "$FT/$CAP_REL" ]'))
root=Path(tempfile.mkdtemp(prefix='holds-assert-',dir=os.environ['TMPDIR']))
env=dict(os.environ,FT=str(root),CAP_REL='capture.md')
r=subprocess.run(['bash','-c',guard],env=env,capture_output=True,text=True)
print('missing capture:',r.returncode,r.stdout.strip());assert r.returncode==1
(root/'capture.md').write_text('present\n')
r=subprocess.run(['bash','-c',guard],env=env,capture_output=True,text=True)
print('present capture:',r.returncode);assert r.returncode==0
p=root/'.tick/attempts/prior';p.parent.mkdir(parents=True);p.write_bytes(b'before\n')
def snapshot():
    r=subprocess.run(['bash','-c',nmap+'\nnmap'],env=env,capture_output=True,text=True)
    assert r.returncode==0 and r.stdout.strip(),r
    return r.stdout
before=snapshot();assert snapshot()==before
p.write_bytes(b'after\n');after=snapshot()
print('same native name, changed bytes, maps equal:',before==after);assert before!=after
print('native names:',before.split()[0],after.split()[0])
PROBE
```

```text
missing capture: 1 ASSERT-SETUP FAIL: capture missing or empty before the run: capture.md
present capture: 0
same native name, changed bytes, maps equal: False
native names: ./prior ./prior
```

**P6 — provenance hash check (exit 0).**

```sh
export PYTHONDONTWRITEBYTECODE=1
python3 - <<'PROBE'
from pathlib import Path
import hashlib,json
for folder in ['2026-11-25+GH-1476-day1','2026-11-25+GH-1476-holds']:
    rows=[json.loads(l) for l in Path('TESTS-RESULTS',folder,'provenance.jsonl').read_text().splitlines()]
    mismatches=[]
    for r in rows:
        p=Path('TESTS-RESULTS',r['artifact']) if '/' in r['artifact'] else Path('TESTS-RESULTS',folder,r['artifact'])
        raw=p.read_bytes(); assert raw,p
        if hashlib.sha256(raw).hexdigest()!=r['sha256']: mismatches.append((r['artifact'],hashlib.sha256(raw).hexdigest()))
    print(folder,'rows=',len(rows),'mismatches=',mismatches)
PROBE
```

```text
2026-11-25+GH-1476-day1 rows= 9 mismatches= [('control.txt', '7522a95b38604a594dafeb7a56857b6cff9b7e36dbf05070c97027e9a86d04bd')]
2026-11-25+GH-1476-holds rows= 55 mismatches= []
```

Evidence boundary: Verify-tier discovery used graph project `Users-noelsaw-Documents-GH-Repos-XYZ-forge`, generation `2026-11-26T04:31:47Z`, in a different checkout. The graph lacked the new helpers/evidence; coverage flagged gh280 lines 729–730 partial and the new evidence paths missing. Full local reads supplied those gaps and the current call traces. The read-only seed comparison, before this review edit, found all 3,828 new/context lines across 72 files equal to the local files; seed SHA-256 `4cb3f7ba199faffeddc38b09038fcf27aca88d9bfd793a4cd82a2425595c50fb`. Git history and final-head gate equivalence were not inspected under the no-Git restriction.

Handing off to Producer (claude-a) — finish B1's checked-versus-executed capture consistency and S1's incomplete-label validation; retain focused red/green evidence in a disposable full clone before the next review. S2, S3 and N1 need no further changes.

### Producer · Round 2

Dispositions (both accepted and implemented; repair `733ef8339`, evidence in the commit after it; round 3 range is `086b657ea..<head>`, seeded patch regenerated):

- **B1 Implemented, by a different fix than "one canonical selection".** Making Jog and Preflight share one selector would change Preflight (out of scope). Instead `hold_refusal` reads every capture either selector could execute: `find_issue_doc_candidates(target, N, ("2-WORKING", "1-INBOX"))` unioned with the `PROJECT/2-WORKING/GH-N-*.md` glob that `swarm_preflight.py` takes `matches[0]` from, and refuses on a hold in ANY of them. The ledger hint therefore cannot steer the check away from the executed document. The earlier "ambiguous capture documents" refusal is gone: ambiguity with no hold now passes, a hold in either document refuses. Replay `ambiguous` (hold only in B) and `ambiguous-a` (hold only in A), on `jog run` and `jog retry-build`: red on base (1 call each), green on change (0 calls, `hold: capture body HELD: marker`, attempts/capture/executions/native map unchanged). Unique clean (`ready`, `inbox-ready`) and genuinely absent capture behaviour unchanged.
- **S1 Implemented.** Every label entry must be a dict with a string `name`; otherwise `hold-check-unavailable: live issue response incomplete`. Replay `issue-nolabelname` (`labels=[{}]`) added next to `issue-malformed` and `issue-badlabels`: red on base, green on change; valid `labels=[]` and `[{"name":"status:held"}]` behave as before (`ready`, `issue-label`).
- The recognizer-exception boundary (`hold rules failed`) remains as defensive code; no replay input reaches it now that shape errors are caught earlier.

Existing suites at `733ef8339` (one disposable clone, committed state): jog-queue, gh280 (227 pass / 0 fail), gh291, gh505, gh202, gh454, gh232, gh168 all rc=0; base `641558361` results unchanged from round 1. S2, S3, N1 stay closed. Handing off to Reviewer for round 3.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
