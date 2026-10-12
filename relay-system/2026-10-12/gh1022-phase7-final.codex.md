# RELAY · GH1022 Phase7 declared-work census final QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-11.
-->

NEXT: Producer
STATUS: Open
ROUND: 1 / 3

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

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
