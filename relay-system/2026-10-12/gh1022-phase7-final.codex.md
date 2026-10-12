# RELAY · GH1022 Phase7 declared-work census final QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-11.
-->

NEXT: Producer
STATUS: Approved
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
6. **Commit only the relay file** (`relay(gh1022-phase7-final): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: whole utils/py/releases_app.py, relay-automation/marathon.sh, skills/3-weekly/weekly-planner/scripts/planner_core.py and issue_intake.py; Phase7 plan/weekly skill/manual evidence under TESTS-RESULTS/2026-10-11+GH-1022/phase7-*
- Reviewer: codex · Producer: author
- Started: 2026-10-12
- Definition of Done: Independently sweep every changed owner in full, including preexisting defects and actual applicable covering fixtures. Review this genuinely new held read-only census implementation against approved Phase7 plan; ownership/identity, raw NULL-gh facts, stable generation/head/runtime, conflict/provenance retention, no writes/signals/connector/dispatch/global-idle claim, legacy outputs and preparation runtime compatibility. Source candidate290566bf. Existing/manual controls only: no individual new CI tests/cases/registrations authorized. No live Marathon/Jog, publication, production action or primary/deployed skill edits. Use own normal new-scope cap3; corrective accumulation R6FAIL/1028 and approved Phase6 remain immutable, do not reset them. Not full1022/W7–11 or merge authority.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Producer · Round 1

VERDICT: PARKED
Basis: Candidate is implemented; independent final review is pending, not approved.

Review the exact current source and all four owners in full. Candidate290566bf implements the approved Phase7 census. Manual owner/core reads: Jog24/work15/observer8/core12; existing preparation runtime controls19. Evidence and measured complete source hashes are committed. Negative controls established UNKNOWN for missing/malformed/foreign/conflicting observations, metadata ownership, journal/generation errors and final runtime drift. Available raw unknown responses remain retained. Fixtures and stdout artifacts write owned local temporary state; census readers do not write. No permanent CI tests/cases/registrations added.

No reviewer source edits, subagents, suite/fixture executable runs, network/connectors/live actions, or Git writes except this relay; harmless in-memory source probes permitted. Existing covering suites run independently in the separate disposable verification clone. Cite concrete observed input/scope/falsifier for behavior-change findings. Preserve prior corrective accumulation R6FAIL6/6/MediumGH1028 and Phase6Approved3/3; own new-scope cap3 is not a reset. Census is only W7 prerequisite; remaining W7–11 and full1022 remain active. Handing off to Reviewer(codex)—take this final new-scope turn.


### Reviewer · Round 1

VERDICT: FAIL
Basis: Two witnessed census defects violate Phase7's malformed/foreign-record and known-fact retention contracts. This is new-scope final R1/3 only; R6FAIL6/6/MediumGH1028 and Phase6Approved3/3 remain unchanged. No full1022/W7–11, publication, landing or merge approval.

swept file: no

Review boundary: Read the complete intake owner and planner core, observer helpers/snapshot and launcher paths, canonical held-read envelope, Phase7 plan, weekly skill and committed manual responses. The large RELEASES owner read was partially truncated; its remaining pre-existing implementation and complete applicable fixture sweep remain outstanding. This is a defect disposition, not a whole-owner approval. Graph project/generation/coverage could not be queried because no graph tools are exposed. Direct source fallback used. No claim that unreviewed pre-existing code is defect-free. No source/artifact edits, Git commands, suites, executable fixtures, connectors or live actions ran.

- [Blocker] **B1 — Malformed or foreign receipt becomes complete/PASS.** At `relay-automation/marathon.sh:307`–`318`, completeness depends only on whether bounded text exists; `matching_receipt` collapses malformed/foreign JSON to `{}`, then the snapshot returns rc0/PASS. The plan requires “unavailable/malformed/foreign/drifting records return UNKNOWN/nonzero rather than empty/complete” (`PROJECT/2-WORKING/GH-1022-WEEKLY-INTAKE.md:868`). This concerns structural availability/attribution, not peer authenticity or criterion approval.
  Observed input: Otherwise valid, stable context for execution `exec`, with its declared result-file bytes `{`; second control substitutes a syntactically valid `marathon-drive/result@1` whose `execution_id` is `foreign` instead of `exec`. Both yield `{"rc":0,"status":"PASS","read_complete":true,"receipt":{}}`. Removing the same file instead yields rc2/UNKNOWN.
  Affected scope: One-shot snapshots with a declared phase and an existing malformed receipt, or a receipt that fails the existing execution/phase/lane/product/token attribution. Keep known context/report and available raw metadata visible while returning UNKNOWN/nonzero; do not alter legacy observe/finish policy or infer authenticity.
  Falsifier: Matching valid receipt under the same context remains complete/PASS rc0; malformed or foreign receipt is UNKNOWN rc2 with known facts retained; missing receipt remains UNKNOWN rc2. The matching and missing controls already distinguish these cases in this probe.
  Root cause: snapshot's completeness predicate counts file availability but never accounts for the receipt parser/matcher's rejected data; Fix site: snapshot's read-envelope construction using existing bounded/matching helpers; Why not upstream/downstream: foreign or malformed external metadata is a supported UNKNOWN input, and a consumer cannot recover the distinctions discarded by this owner.

- [Blocker] **B2 — An observer error discards a successful inventory's normalized facts.** `planner_core.py:895` stores a successful inventory before context calls; failures at `904`–`911` set `item["error"]`. `issue_intake.py:295`–`301` then skips that inventory entirely. This loses known accounting facts from the public `facts` collection even though raw observations remain, contrary to Phase7's retained-known-facts requirement and partial-root evidence claim.
  Observed input: Source A has a complete initialized `releases/work-inventory@1`, generation1/schema8/HEAD `a*40`, repository `acme/a` with `repo-`+`0*26`, and one owned pending `jog-`+`1*26` row with dispatchfalse. With no error, normalization returns one fact/HELD; adding `error="command refused (2): bash malformed observer output"` returns zero facts/UNKNOWN while raw_rows remains1.
  Affected scope: A valid already-read inventory accompanied by a later context-command/output error (or later runtime check error recorded on the same source). Preserve and qualify its known facts with their original provenance while marking the aggregate UNKNOWN; continue to reject invalid inventory identity/schema. Do not suppress the observer error.
  Falsifier: Same source without error returns one fact/HELD; same inventory plus context error returns one fact/UNKNOWN and retained error/raw source; genuinely missing or invalid inventory remains UNKNOWN without manufactured facts.
  Root cause: normalizer conflates a source-level observation error with inventory invalidity; Fix site: `normalise_work_observations` source admission; Why not upstream/downstream: the adapter correctly records both the successful inventory and later error, and normalization must retain those independent observations.

- [Should] **S1 — Document the new read capability.** The complete `skills/3-weekly/weekly-planner/SKILL.md` contains neither `weekly-work` nor `authority-file`; Phase7 step4 explicitly requires exposing this seam (`PROJECT/2-WORKING/GH-1022-WEEKLY-INTAKE.md:887`). Add the opt-in invocation, minimal `weekly/authorities@1` root/context shape, explicit ownership/metadata roots, HELD versus UNKNOWN/nonzero contract, and no-dispatch/no-global-idle limitation to the repository skill. No installation/deployed skill change requested.

Probe evidence (scratch is disposable; decisive output retained here): command `export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"; python3 -` with the following in-memory source extraction and inputs; exit0. No artifact/fixture executable was run. The observer's bounded read was replaced only with a dictionary lookup; the actual snapshot/parser/matcher/report functions ran unchanged.

```python
import ast, contextlib, io, json, os
from pathlib import Path
from types import SimpleNamespace
source = Path("relay-automation/marathon.sh").read_text().split(
    "<<'MARATHON_PROGRESS_PY'\n", 1)[1].split("\nMARATHON_PROGRESS_PY", 1)[0]
tree = ast.parse(source)
tree.body = [n for n in tree.body if isinstance(
    n, (ast.Import, ast.ImportFrom, ast.FunctionDef))]
ns = {"__name__": "probe"}
exec(compile(tree, "relay-automation/marathon.sh", "exec"), ns)
base = os.environ["TMPDIR"]
ctxpath, beat, receipt, relay = [
    base + "/" + f for f in ("context.json", "beat.json", "receipt.json", "RELAY.md")]
ctx = {
    "run_id": "1"*32, "root": base, "product_root": base,
    "harness_root": base, "plan": base+"/plan", "run_log": base+"/log",
    "heartbeat_file": beat, "started_utc": "2026-10-11T00:00:00+00:00",
    "initial_head": "a"*40, "initial_origin": "https://github.com/acme/a.git",
    "owner": 123, "total": 1, "returned_success": 0, "verified_phases": 0,
    "last_milestone": None,
    "phase": {"id": "p1", "lane": "lane", "token_family": "TASK",
              "execution_id": "exec", "result_file": receipt,
              "relay_file": relay, "index": 1, "driver_pid": 456}}
valid = {"schema": "marathon-drive/result@1", "execution_id": "exec",
         "phase": "p1", "lane": "lane", "target_repo": {"path": base}, "token": "TASK"}
beatvalid = {"phase_id": "p1", "pid": 456, "relay_task": "TASK",
             "updated_utc": "2026-10-11T00:01:00+00:00",
             "started_utc": "2026-10-11T00:00:00+00:00"}
data = {ctxpath: json.dumps(ctx), beat: json.dumps(beatvalid),
        receipt: json.dumps(valid), relay: "NEXT: Reviewer\nSTATUS: Open\n"}
ns["bounded_read"] = lambda p: data.get(str(p))
args = SimpleNamespace(root=base, product_root=base,
                       metadata_root=[], context=Path(ctxpath))
for label, value in [
    ("matching control", json.dumps(valid)),
    ("malformed JSON", "{"),
    ("foreign execution", json.dumps(dict(valid, execution_id="foreign"))),
    ("missing control", None)]:
    data[receipt] = value
    out = io.StringIO()
    with contextlib.redirect_stdout(out):
        rc = ns["snapshot"](args)
    result = json.loads(out.getvalue().split("marathon-progress: ", 1)[1])
    print(label, rc, result["status"], result["read_complete"], result.get("receipt"))

intake_ns = {"__name__": "probe"}
exec(compile(Path("skills/3-weekly/weekly-planner/scripts/issue_intake.py").read_text(),
             "issue_intake.py", "exec"), intake_ns)
repo = "repo-"+"0"*26
fact = {"global_id": "jog-"+"1"*26, "repository": "acme/a",
        "repo_global_id": repo, "dispatch": False, "status": "pending"}
inv = {"schema": "releases/work-inventory@1", "read_complete": True,
       "initialized": True, "dispatch": False, "generation": 1,
       "schema_version": 8, "git_head": "a"*40,
       "repositories": [{"repository": "acme/a", "global_id": repo}],
       "rows": [fact], "marathons": [], "lifecycle": []}
for error in [None, "command refused (2): bash malformed observer output"]:
    src = {"id": "A", "declared_root": base, "repository": "acme/a",
           "inventory": inv, "contexts": []}
    if error:
        src["error"] = error
    r = intake_ns["normalise_work_observations"]([src])
    print(error, len(r["facts"]), r["status"],
          len(r["observations"][0]["inventory"]["rows"]))
```

Decisive output:
```text
matching control: rc0 PASS read_complete=true, matching receipt retained
malformed JSON: rc0 PASS read_complete=true receipt={}
foreign execution: rc0 PASS read_complete=true receipt={}
missing control: rc2 UNKNOWN read_complete=false receipt={}
inventory control: facts=1 status=HELD raw_rows=1
inventory plus error: facts=0 status=UNKNOWN raw_rows=1
```

- [Pass] **Candidate byte identity only.** Python SHA256 measurements against `phase7-source-hashes.json` returned true for all four owners (command `PYTHONDONTWRITEBYTECODE=1 python3 -`, exit0, mapping: releases_app=true, marathon=true, planner_core=true, issue_intake=true). This corroborates the exact complete-byte hashes in `TESTS-RESULTS/2026-10-11+GH-1022/phase7-source-hashes.json:4`, not functional correctness or Git commit/remote identity.
- [Unverified — needs clone run] Executable covering-suite and preparation-runtime compatibility. Inspected legacy Jog list/filter cases at `test/jog-queue.sh:85`–`139`, launcher coverage references and `test/gh698-planner-db-ratings.sh` source, plus committed Phase7 manual responses/runtime19 and provenance. Did not rerun them; their producer receipts do not substitute for independent final-clone qualification. No new CI suites/cases/registrations requested. Complete fixture/owner sweep remains required before any later PASS.

Handing off to Producer (author) — address B1/B2 and S1, retain this failed R1 and prior phase/corrective history, then open R2/3 with exact candidate evidence. Go to the author window and say 'take your turn'.

### Producer · Round 2

B1 Implemented: snapshot's completeness now includes existing receipt attribution, heartbeat attribution and available relay role/status; rejected records stay UNKNOWN/nonzero with bounded raw metadata, known context/report and matching facts retained. Legacy observe/finish helpers and policy remain unchanged. Actual CLI negative controls malformed/foreign receipt, malformed heartbeat and unsupported relay are UNKNOWN; matching control PASS and missing metadata UNKNOWN, bytes unchanged (observer12).

B2 Implemented: source error holds aggregate UNKNOWN separately from inventory schema/identity admission. Valid inventory remains qualified/normalized with provenance; genuinely invalid/missing inventory produces no fabricated facts. Actual late-observer RuntimeError retains qualified facts and raw error (core13), sharedwork15 passes.

S1 Implemented: repository weekly-planner skill now documents weekly-work/authority-file with minimal JSON, explicit roots/contexts/metadata ownership and HELD/UNKNOWN/no-global-idle/no-dispatch limitations. No deployed collection changed.

Exact source candidate3bf10ded; complete source hashes in phase7-r2-source-hashes.json. Earlier candidate53c covering suites passed adapter223/lifecycle125/work-state28/lock18/artifact10/refusal19; R2 snapshot/normalization source now has actual source-bound manual evidence and AST/Bash syntax passed. Qualification statements retain their exact source limits; final-clone full gate remains pending. No new CI test/case/parameter/registration.

Complete the four-owner and applicable fixture sweep before any PASS: R1 explicitly swept file no; do not inherit a whole-owner approval. Read the remaining canonical RELEASES owner in small bounded chunks with line-count coverage so no tool truncation hides pre-existing code. Preserve all R1 findings, R6FAIL/Medium1028 and Phase6Approved history. No source edits, extra agents, suite/fixture executable runs, network/connectors or live effects; only relay writes and harmless in-memory probes. Own cap2/3, not a reset. FullW7–11 active, no umbrella/landing approval. Handing off to Reviewer(codex)—take Round2 on the exact candidate.

### Reviewer · Round 2

VERDICT: FAIL
Basis: R1's malformed/foreign receipt and late-observer fact-loss controls now pass, but an observed malformed-relay case still yields complete/PASS. New-scope R2/3 only; R6FAIL6/6/MediumGH1028 and Phase6Approved3/3 remain immutable. No full1022/W7–11, publication, landing or merge approval.

swept file: yes

Sweep boundary: Read all four owners in full: releases_app.py lines1–7136, marathon.sh lines1–796, planner_core.py lines1–1485 and issue_intake.py lines1–369. Bounded follow-up reads recovered truncated spans, including RELEASES schema and dashboard/parser boundaries and planner preparation/legacy classification. Read the Phase7 plan and complete repository weekly-planner skill. No graph tools were exposed, so project/generation/coverage could not be queried; direct source fallback used. Inspected complete existing jog-queue, marathon, marathon-monitor, gh698, gh448, gh32-artifacts and gh54 fixture sources; the large gh549/gh280/gh605 suites were not completely swept or executed this turn. This FAIL is not exhaustive fixture qualification. No additional newly witnessed pre-existing defect in the four owners; existing advisory readiness limitations at planner_core.py:207–208 and cycle handling at :222–225 are already recorded for W8 and remain unapproved readiness policy, not reopened corrective findings.

- [Blocker] **B3 — Present malformed relay fields still count as complete.** `relay-automation/marathon.sh:324` tests only the literal sentinel `unknown`; `emit` copies arbitrary or empty field values at :198. Consequently stable declared metadata containing `STATUS: Banana\nNEXT: Nobody\n`, or `STATUS: \nNEXT: \n`, yields rc0/PASS/read_complete=true. The Phase7 contract explicitly requires malformed records to return UNKNOWN/nonzero (`PROJECT/2-WORKING/GH-1022-WEEKLY-INTAKE.md:868`). The R2 manual “unsupported relay metadata UNKNOWN” control only exercises missing fields, leaving this admission gap.
  Observed input: The first complete response in `TESTS-RESULTS/2026-10-11+GH-1022/phase7-r2-observer-manual.json`, with only its raw RELAY.md value replaced by the two exact strings above. The matching context/receipt/heartbeat are otherwise unchanged. Valid `STATUS: Approved/NEXT: Builder` produces rc0/PASS; removing RELAY.md produces rc2/UNKNOWN; unsupported and empty fields produce rc0/PASS.
  Affected scope: One-shot snapshot admission of a declared phase's bounded relay role/status metadata. Validate nonempty supported values using the existing relay contract, retain available raw/context/receipt observations and return UNKNOWN/nonzero for unsupported/empty fields. Keep legacy emit/observe/finish policy unchanged; this is structural completeness, not criterion or authenticity approval.
  Falsifier: Same stable input with valid Builder/Reviewer and supported relay status stays PASS/rc0; the two exact malformed strings become UNKNOWN/rc2 with raw bytes and known context/receipt retained; missing fields remain UNKNOWN/rc2. If either malformed input already returned UNKNOWN against the candidate source, this finding would be unnecessary; it did not.
  Root cause: snapshot mistakes the absence sentinel for a vocabulary/shape validator. Fix site: snapshot's relay completeness admission. Why not upstream/downstream: legacy emit is a reporting helper and must preserve its outputs; downstream receives read_complete=true after this owner accepted unsupported metadata. Use existing/manual controls only; no CI test/case/registration requested.

- [Pass] **R1 B1 receipt rejection repaired for the witnessed inputs.** Actual unchanged snapshot/parser/matcher functions, with bounded reads substituted by the seeded raw dictionary, returned matching rc0/PASS and malformed/foreign/missing rc2/UNKNOWN; context remained present in all four results. Repair predicate and retained outputs: `marathon.sh:320–333`. This is narrow in-memory evidence, not an executable CLI/clone gate or receipt-authenticity finding.
- [Pass] **R1 B2 retained known fact repaired.** The same valid generation1/schema8/HEAD a×40 inventory and owned pending jog-1×26 fact used in R1 returns facts=1/HELD without error and facts=1/UNKNOWN with the later observer error. Source error qualification no longer skips admission (`issue_intake.py:295–300`); original provenance is retained at :345–349.
- [Pass] **R1 S1 capability documented.** Complete repository skill now includes the opt-in invocation, minimal authority JSON, explicit roots/context metadata and “Complete observations remain HELD with dispatch_allowed false” / “Empty context lists do not prove idle” (`skills/3-weekly/weekly-planner/SKILL.md`, “Opt-in declared work observation”). No deployed-skill assertion.
- [Pass] **Complete-byte candidate identity.** SHA256 comparison returned true for all four paths against `TESTS-RESULTS/2026-10-11+GH-1022/phase7-r2-source-hashes.json:4`. No Git/remote identity assertion.
- [Unverified — needs clone run] Final committed-state covering suites, complete remaining fixture sweep and preparation runtime compatibility. Producer logs/provenance are explicitly source-qualified: existing adapter223/lifecycle125/work-state28 receipts precede R2 remediation; `phase7-runtime-controls.log` records19 controls. They are not independent final-candidate qualification. The harness must run the appropriate gate in a disposable full clone after the turn; no forbidden suite/pytest/executable-fixture or Git command ran here.

Probe command: `export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"; python3 -` (exit0). Decisive output, retained because scratch is disposable:
```text
valid 0 PASS True Builder Approved
unsupported 0 PASS True Nobody Banana
empty 0 PASS True [empty role] [empty status]
missing 2 UNKNOWN False unknown unknown
receipt matching 0 PASS context_present=True
receipt malformed 2 UNKNOWN context_present=True
receipt foreign 2 UNKNOWN context_present=True
receipt missing 2 UNKNOWN context_present=True
inventory None 1 HELD
inventory command refused (2): bash malformed observer output 1 UNKNOWN
hashes: releases_app=True, marathon=True, planner_core=True, issue_intake=True
```

Reproduction of B3 (in-memory source probe; no artifact/fixture executable or Git invocation):
```python
import ast, contextlib, copy, io, json
from pathlib import Path
from types import SimpleNamespace
src = Path("relay-automation/marathon.sh").read_text().split(
    "<<'MARATHON_PROGRESS_PY'\n", 1)[1].split("\nMARATHON_PROGRESS_PY", 1)[0]
tree = ast.parse(src)
tree.body = [n for n in tree.body if isinstance(n, (ast.Import, ast.ImportFrom, ast.FunctionDef))]
ns = {"__name__": "probe"}
exec(compile(tree, "observer", "exec"), ns)
seed = json.loads(Path("TESTS-RESULTS/2026-10-11+GH-1022/phase7-r2-observer-manual.json").read_text())["controls"][0]["response"]
ctx, data = seed["context"], copy.deepcopy(seed["raw_metadata"])
ns["bounded_read"] = lambda p: data.get(str(p))
args = SimpleNamespace(root=ctx["root"], product_root=ctx["product_root"], metadata_root=[],
    context=Path(next(p for p in data if p.endswith(".progress.json"))))
relay = ctx["phase"]["relay_file"]
original = data[relay]
for label, value in [("valid", original), ("unsupported", "STATUS: Banana\nNEXT: Nobody\n"),
                     ("empty", "STATUS: \nNEXT: \n"), ("missing", None)]:
    data[relay] = value
    out = io.StringIO()
    with contextlib.redirect_stdout(out):
        rc = ns["snapshot"](args)
    r = json.loads(out.getvalue().split("marathon-progress: ", 1)[1])
    print(label, rc, r["status"], r["read_complete"], r.get("observation", {}).get("role"),
          r.get("observation", {}).get("relay_status"))
```

Handing off to Producer (author) — address B3 with existing/manual source-bound controls, retain all prior findings/history and open R3/3. Complete remaining fixture inspection and final-clone qualification before any later PASS. Go to the author window and say 'take your turn'.

### Producer · Round 3

B3 Implemented at candidate dffae622: snapshot requires Open/Approved/Closed/Escalated and supported Builder/Producer/Reviewer roles. Both shipped Marathon drivers declare task/builder/reviewer/roundcap in their marker; matching token-family marker adds their named actor IDs, with Python role annotations and frozen Bash bare IDs. Unsupported/empty values hold UNKNOWN/nonzero; legacy emit/observe/finish behavior remains unchanged. Actual source-bound observer18 includes the exact Banana/Nobody and empty negative cases, valid initial control, four named actor forms, malformed/foreign/missing metadata, logical-product ownership and unchanged bytes. Raw metadata/context/receipt retained. Fixture examples and owner marker constructors at marathon_drive.py:2964–2966/marathon-drive.sh:1036–1039 explain this vocabulary; no invented agent-registration/authenticity claim.

Measured complete source hashes phase7-r3-source-hashes.json: canonical/core/intake are byte-identical to R2; observer is changed. R2 whole-owner sweep yes found no additional witnessed preexisting defect. Complete the remaining large fixture source inspection and recheck the whole changed observer before PASS; do not claim exhausted/unread fixture coverage. No source/fixture edits, executable suites, extra agents, network/connectors or live effects in this review; harmless in-memory source probes and relay-only writes permitted.

Actual existing covering suite records: adapter223/lifecycle125/work-state28/lock18/artifact10/refusal19 at53c; Jog34 at3cdf (queue owner bytes unchanged). Preparation runtime19 uses final core bytes unchanged sinceR1. Core13/work15 fromR2 use current core/intake bytes; observer18 uses final current owner. These are scoped clone/manual qualification, not the yet-to-run mandatory final normal pre-push full gate. No new CI tests/cases/registrations. Producer will run that existing gate in the disposable clone after a source review approval; no push or broad completion precedes it. Any approval here must remain code/scope qualified, not final gate/remote/live/full1022 permission.

Retain R1/R2 failures and closed R6FAIL6/6/Medium1028 and Phase6Approved3/3 without resets. Own final cap3/3. Full W7–11 remains required. Handing off to Reviewer(codex)—take Round3 on the exact candidate and record any remaining proven defect without broadening or downranking history.

### Reviewer · Round 3

VERDICT: PASS
Basis: Approve the Phase7 held census source scope: B1/B2/B3 and S1 are addressed for the witnessed inputs, the whole changed observer has been reviewed, and the previously outstanding fixture-source inspection is complete. This is source-review approval at new-scope R3/3, with the mandatory final normal gate still pending in a disposable full clone. Preserve R1/R2 failures, R6FAIL6/6/MediumGH1028 and Phase6Approved3/3. No full1022/W7–11, publication, production, landing or merge approval.

swept file: yes

Sweep boundary: Whole-owner review spans R2 plus this R3: R2's full RELEASES/core/intake sweep remains applicable because independently measured complete bytes are identical; this turn re-read their census/admission/runtime seams and the complete intake, and read the entire changed marathon.sh (1–805), recovering truncated output with bounded follow-ups. Completed the outstanding fixture-source sweep: gh549-work-events.sh (1–1512), gh280-jog-marathon-adapter.sh (1–1287), both gh605 wrappers and their actual Python bodies test_gh605_work_state.py (1–650) and test_gh605_board_policy.py (1–1029). R2's other completed fixture-source reads remain recorded above. No additional witnessed pre-existing owner defect found. This does not claim repository-wide fixture exhaustion or executable-suite qualification.

Graph limitation: list_projects returned all82 projects, no current worktree index. Nearest canonical XYZ-forge is a different checkout; index_status/check_index_coverage report generation2026-09-01T15:54:30Z, changed owner metadata, missing intake and partial marathon range351. That index cannot attest this candidate. Exact local source reads, including the reported partial range, and measured bytes supplied the evidence; no indexing or source mutation occurred.

- [Pass] **B3 repaired without rejecting the shipped actor forms.** The actual snapshot/parser/report functions now return rc2/UNKNOWN/read_complete=false for the exact `STATUS: Banana\nNEXT: Nobody\n` and empty-field inputs, retaining context/raw metadata. Matching generic role returns rc0/PASS; matching marker actor forms `codex`, `agy`, `codex (Builder)` and `agy (Reviewer)` all return rc0/PASS. Named actor with a foreign token marker returns rc2/UNKNOWN. Admission is at marathon.sh:324–340; the declared actor vocabulary comes from the actual marker constructors at utils/py/marathon_drive.py:2964–2966 and relay-automation/marathon-drive.sh:1036–1039. This establishes structural read completeness only; it does not authenticate a peer or approve criteria.
- [Pass] **B1/B2 regression inputs remain repaired.** Malformed `{`, foreign execution ID and missing receipt all return rc2/UNKNOWN with context/raw metadata retained (marathon.sh:320–340). The same owned pending jog fact and generation1/schema8/HEAD a×40 used in R1 returns facts1/HELD without error and facts1/UNKNOWN with the later observer error; provenance retains root A, /declared/a, original HEAD and generation (issue_intake.py:295–300,345–359). No observer error was suppressed.
- [Pass] **Owner/adapter policy remains held and distinct from readiness.** RELEASES explicitly includes terminal facts and raw lifecycle rows, including unqualified issue references and decoded/raw payloads (releases_app.py:4753–4783); the adapter calls the selected canonical owners with declared roots, checks runtime identity and retains source errors (planner_core.py:854–923). The normalizer retains raw observations and conflicting stable facts with provenance, returns HELD/UNKNOWN and dispatch_allowed=false (issue_intake.py:287–369). The repository skill's complete “Opt-in declared work observation” section documents explicit roots, contexts and metadata ownership and says “Empty context lists do not prove idle.” This carries no readiness/global-idle or deployed-skill assertion.
- [Pass] **Complete-byte continuity.** All four SHA256 measurements equal phase7-r3-source-hashes.json:4; RELEASES/core/intake also equal R2 hashes, observer differs as declared. This is byte identity, not Git/remote identity. The producer's observer18 JSON and runtime19 log are source-qualified records, not an independent gate run.
- [Unverified — needs clone run] **Final committed-state execution and preparation compatibility.** No validate.sh, test/*.sh, pytest or executable fixture ran here. Prior producer suite/runtime receipts remain scoped to the revisions/bytes named in their provenance. The harness/Producer must run the existing final normal gate in a disposable full clone after this relay-only turn; this approval must not substitute for that result. No new test/case/registration requested.

Independent probe command: `export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"; mkdir -p "$TMPDIR"; python3 -` (observer/hash exit0); second `python3 -` (normalizer exit0). Both used in-memory source only. The observer AST retained only Import/ImportFrom/FunctionDef nodes, so main/launcher never ran; bounded_read alone was replaced by the seeded dictionary. Exact R2 reproduction above remains valid, with these R3 variations:

```python
# After R2's ns/ctx/data/args/relay initialization:
original = copy.deepcopy(data)
receipt = ctx["phase"]["result_file"]
family = ctx["phase"]["token_family"]
# Call unchanged ns["snapshot"] under redirected stdout for each variation.
for value in [original[relay], "STATUS: Banana\nNEXT: Nobody\n",
              "STATUS: \nNEXT: \n", None]:
    data[relay] = value
    # rc / status / read_complete / context-present / raw-present recorded below
for actor in ["codex", "agy", "codex (Builder)", "agy (Reviewer)"]:
    data[relay] = (f"STATUS: Open\nNEXT: {actor}\n"
        f"<!-- marathon-drive: task={family} builder=codex reviewer=agy round-cap=3 -->\n")
# Foreign marker: same named actor, task=FOREIGN.
# B1: restore original dictionary, substitute receipt "{", foreign execution_id, None.
# Hash: hashlib.sha256(Path(path).read_bytes()).hexdigest() against each R3/R2 value.
```

Decisive output:
```text
hash releases_app=True unchanged_R2=True
hash marathon=True unchanged_R2=False
hash planner_core=True unchanged_R2=True
hash issue_intake=True unchanged_R2=True
valid 0 PASS True context True raw True
unsupported 2 UNKNOWN False context True raw True
empty 2 UNKNOWN False context True raw True
missing 2 UNKNOWN False context True raw True
codex 0 PASS True context True raw True
agy 0 PASS True context True raw True
codex (Builder) 0 PASS True context True raw True
agy (Reviewer) 0 PASS True context True raw True
foreign marker 2 UNKNOWN False context True raw True
receipt malformed 2 UNKNOWN False context True raw True
receipt foreign 2 UNKNOWN False context True raw True
receipt missing 2 UNKNOWN False context True raw True
inventory None 1 HELD provenance=A,/declared/a,HEAD a×40,generation1
inventory 'command refused (2): bash malformed observer output' 1 UNKNOWN same provenance
```

For the second probe, compiled complete issue_intake.py with `__name__="probe"`, used R1's exact inv/fact shape and `normalise_work_observations([source])`, changing only source error as shown; root=/declared/a. No DB, Git, connector, worker, signal, dispatch, artifact or fixture executable was invoked. Only this relay was edited; scratch directory is under .relay-scratch.

Relay closed (Approved), no further review turn needed. Handing completion to Producer (author) for the required disposable-clone final gate and source-qualified reporting; full W7–11 remains active.


### Attestation · relay-drive — 2026-10-12T07:01:13Z
task: GH1022-PHASE7-FINAL-R3
reviewer: codex
status: Approved
reviewed-head: 4e7594611565ba8939ffcd1a776906f1c31a5b40
added-range: 30767+7587
added-sha256: 864ea7360c4560847a8f4b207c29ec58b2cd1cb379f604e9660bb67e76e7abde
<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
