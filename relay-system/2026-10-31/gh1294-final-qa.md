# RELAY · GH-1294 final QA: hold delivered issues that have a draft brief
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-31.
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
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
   Reviewer headings may be `### Reviewer · Round N`, `### Round N · Reviewer · <agent>`, `### Reviewer (<agent>)` (optionally followed by `— rN`), or `### Reviewer — Round N` (optionally followed by `(<agent>)`); follow the heading with a non-empty review body.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(gh1294-final-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **gh1294-qa-artifact.md** (embedded below — read it here).
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-10-31

### Artifact — gh1294-qa-artifact.md
````
## Diff (code), base b81f4205 .. HEAD

```diff
diff --git a/utils/py/harness.py b/utils/py/harness.py
index 7f01e929..4c759faa 100755
--- a/utils/py/harness.py
+++ b/utils/py/harness.py
@@ -554,6 +554,13 @@ def _probe_landing(engine, rec: dict) -> tuple[list[dict], int]:
     return results, sum(r["result"] == "landed" for r in results)
 
 
+def _delivered_hold(delivered: dict, issue) -> str | None:
+    """Held reason when a merged PR closed `issue` but the issue is still open (GH-1294)."""
+    if str(issue) not in delivered:
+        return None
+    return "possibly delivered: closed by merged PR " + ", ".join(f"#{n}" for n in delivered[str(issue)]) + "; issue still open"
+
+
 def _build_proposal(engine, computed: dict, briefs: list[dict], manifest: dict, tick_id: str, request_id: str) -> dict:
     """Planner waves as computed, plus provisional packing of copied records with sourced drafts."""
     by_gh = {r["gh"]: r for r in computed["deduped"] if r["gh"] is not None}
@@ -568,9 +575,9 @@ def _build_proposal(engine, computed: dict, briefs: list[dict], manifest: dict,
         if r["gh"] in refused:
             continue
         # GH-1270: every provisional lane gets the read-only readiness checks, briefed or not.
-        if str(r["gh"]) in delivered:
-            held.append({"issue": r["gh"], "reason": "possibly delivered: closed by merged PR "
-                         + ", ".join(f"#{n}" for n in delivered[str(r["gh"])]) + "; issue still open"})
+        reason = _delivered_hold(delivered, r["gh"])
+        if reason:
+            held.append({"issue": r["gh"], "reason": reason})
             continue
         results, landed = _probe_landing(engine, r)
         if landed:
@@ -581,6 +588,10 @@ def _build_proposal(engine, computed: dict, briefs: list[dict], manifest: dict,
         lanes.append(lane)
     for b in briefs:
         if b["draft_status"] == "draft":
+            reason = _delivered_hold(delivered, b["issue"])
+            if reason:  # GH-1294: the second loop must hold delivered work too
+                held.append({"issue": b["issue"], "reason": reason})
+                continue
             base = by_gh.get(b["issue"]) or {**_unregistered_record(b["issue"], b["title"], ""), "deps": b["deps"]}
             lane = copy.deepcopy(base)
             paths = [w["path"] for w in b["write_set"]]
```

## Evidence (TESTS-RESULTS/2026-10-31+GH-1294/SUMMARY.md)

# GH-1294: delivered issues with a draft brief are held, not scheduled

- **Change:** `utils/py/harness.py`. `_build_proposal` applied the "possibly delivered" hold only in its loop over planner-active lanes; the second loop, over accepted draft briefs, packed every `draft` brief. The reason string moves into `_delivered_hold` and both loops use it.
- **Manual check (red/green, no test file, GH-831):** `gh1294-check.py` calls `_build_proposal` with a stub planner engine, a draft brief for #384 (delivered by PR #386) and one for #777. Output: `gh1294-check-output.txt`.

| Run | Scheduled | Held |
|---|---|---|
| origin/development `b81f4205` (red) | #384, #777 | none |
| fixed branch (green) | #777 | #384: possibly delivered: closed by merged PR #386; issue still open |

- **Limit:** the original canary round trip (`stageb_controls.py roundtrip`, which found this in the #1279 window) is not reproducible today. `init` freezes the 300 most recent merged PRs, #384's PR has dropped out of that window, and `init` refuses the canary row (`roundtrip-attempt-output.txt`). The stub check exercises the same function with the same `delivered` shape. That real-state canary drift is a finding for any future soak, not fixed here.
- **Not in this change:** #1295 (injected text) and the empty-`reason` check are deferred until a generated launch packet is first launched (see #1298); #1296 belongs to the admission experiment.

## Check output

```
BASELINE (origin/development b81f4205):
{"scheduled": [384, 777], "held": []}
FIXED (task clone):
{"scheduled": [777], "held": [{"issue": 384, "reason": "possibly delivered: closed by merged PR #386; issue still open"}]}
```

## The check script

```python
"""GH-1294 manual check: _build_proposal with a draft brief for an issue a merged PR delivered. Not a test suite (GH-831)."""
import importlib.util, json, sys
spec = importlib.util.spec_from_file_location("harness", sys.argv[1] + "/utils/py/harness.py")
h = importlib.util.module_from_spec(spec); sys.modules["harness"] = h; sys.path.insert(0, sys.argv[1] + "/utils/py"); spec.loader.exec_module(h)

class Engine:
    def _zone_of(self, a, lane): return {"zone": "z", "zoneRule": "r"}
    def _pack_waves(self, lanes, view, force_tail=False): return ([lanes] if lanes else []), []
    def _contract_seams(self, waves): return []
    def _eval_probe(self, p): return "unlanded"

def brief(n, status="draft", ws=("utils/py/x.py",)):
    return {"issue": n, "title": f"t{n}", "draft_status": status, "held_reason": None, "deps": [],
            "write_set": [{"path": p, "source": "issue"} for p in ws], "request_id": f"r{n}"}
manifest = {"delivered": {"384": [386]}, "requests": {"r384": {}, "r777": {}}, "excluded": []}
computed = {"active": [], "deduped": [], "waves": [], "contract_seams": []}
p = h._build_proposal(Engine(), computed, [brief(384), brief(777)], manifest, "t", "r")
print(json.dumps({"scheduled": [l["issue"] for w in p["provisional"]["waves"] for l in w], "held": p["held"]}))
```
````
- Definition of Done: #1294 is satisfied: an open issue that a merged PR closed (`manifest["delivered"]`) and that has a `draft` brief is held with the possibly-delivered reason and is in no provisional wave; the existing planner-lane hold behaves as before; no new test file or registry entry (GH-831); the change is the smallest one in the existing function.

**Operational envelope.** Local single-operator repo; a ~14-line change in `utils/py/harness.py::_build_proposal` plus a manual red/green check. Grade against the stated acceptance and commensurate complexity, not enterprise threat models. You may read the repo checkout (current `development` plus this change is embedded below; run no git, no suites). Do not edit any file except this relay file.

**Questions.**
1. Does the diff hold exactly the delivered issues with `draft` briefs, and leave planner-lane holds, `ready` briefs, and non-delivered drafts unchanged? Check `_build_proposal` in `utils/py/harness.py` for any other path that admits a brief into a wave without the delivered check (for example a `ready` brief whose lane is not in `computed["active"]`).
2. Is the shared helper `_delivered_hold` the right size (no duplicate subsystem, reason string byte-identical to the old one)?
3. Does the manual check actually detect the failure (red on `b81f4205`, green on the fix), and are its limits honestly stated in `SUMMARY.md`, including that the live canary round trip could not be reproduced?
4. Any file in the diff that should not be there (new test file, registry entry, stray artifact)? The diff shows code only; the other changed files are `TESTS-RESULTS/2026-10-31+GH-1294/{SUMMARY.md,gh1294-check.py,gh1294-check-output.txt,roundtrip-attempt-output.txt,provenance.jsonl}` and this relay file.

Out of scope on purpose: #1295 (injected text) and the empty-`reason` check, deferred; #1296 (admission experiment). Do not ask for them.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer · Round 1

VERDICT: PASS
Basis: Ship within the stated single-operator envelope. The delivered-draft omission is fixed in the existing admission loop; planner-lane behavior is preserved. No blocking or should-fix finding.
swept file: yes

- [Pass] Admission: `utils/py/harness.py:574-603` has exactly two lane-append paths. Planner records pass the delivered guard at lines 578-581; draft briefs now pass it at lines 591-594. A `ready` brief outside `computed["active"]` reaches neither append. The read-only probe below observes the expected delivered/ordinary draft and active/inactive ready outcomes. No correction required.
- [Pass] Size and reason: `utils/py/harness.py:557-561` centralizes the existing membership check and identical reason expression used in the embedded old diff. Multiple PRs retain comma-space formatting, and an absent issue returns `None` (probe below). This is a bounded local helper, with no new subsystem. No correction required.
- [Pass] Evidence honesty: `TESTS-RESULTS/2026-10-31+GH-1294/gh1294-check.py:15-18` supplies nonempty delivered/draft inputs and prints observable scheduling; `gh1294-check-output.txt:1-4` records the claimed baseline/fixed difference. The independent in-memory guard-removal control below reproduces the failure. `SUMMARY.md` explicitly states “the original canary round trip ... is not reproducible today”; `roundtrip-attempt-output.txt` reports “issue #384 is not in the expected frozen state (held-delivered)”. No claim of a successful live round trip is made. No correction required.
- [Pass] Scope and sweep: read all of `utils/py/harness.py:1-1708`, including brief generation/admission (642-740), verification (743-767), and the provisional-wave packet consumer (1263-1346), plus all five listed evidence files and this relay. No additional pre-existing defect found within this review's stated envelope, beyond the explicitly deferred topics. The Setup's declared changed-file list contains no new `test/` suite or registry change; the manual script is evidence under `TESTS-RESULTS/`. No correction required. A repository-wide diff inventory was not independently queried because this turn forbids Git.
- [Unverified — needs clone run] Full harness/real packer execution, exact baseline `b81f4205` replay, and the live canary round trip were not independently run here. The probe substitutes packing/zone selection and executes only the three extracted, non-mutating source functions; it proves admission decisions, not dependency packing or end-to-end behavior. Full gate attestation remains with the harness after this turn.

Narrow probe command (exit 0; no source-module imports, fixtures, Git, suite, database, or runtime writes; mutation exists only in memory):

```sh
export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"
mkdir -p "$TMPDIR"
python3 - <<'PY'
import ast, copy, json
from pathlib import Path
from types import SimpleNamespace
tree = ast.parse(Path("utils/py/harness.py").read_text())
names = {"_delivered_hold", "_build_proposal", "_probe_landing"}
nodes = [n for n in tree.body if isinstance(n, ast.FunctionDef) and n.name in names]
assert len(nodes) == 3
def load(ns_nodes):
    ns = {"copy": copy, "DRAFT_LABEL": "draft"}
    exec(compile(ast.Module(body=ns_nodes, type_ignores=[]), "<source-probe>", "exec"), ns)
    return ns
ns = load(nodes)
engine = SimpleNamespace(_zone_of=lambda *_: {"zone": "z", "zoneRule": "r"},
    _pack_waves=lambda lanes, view, **kw: ([lanes] if lanes else [], []),
    _contract_seams=lambda _: [])
def measure(space, status, active, delivered):
    r = {"gh": 384, "state": "ready" if active else "needs-contract",
         "writeset": ["utils/py/x.py"], "contract": None}
    b = {"issue": 384, "draft_status": status, "title": "t", "deps": [],
         "write_set": [{"path": "utils/py/x.py"}], "request_id": "r"}
    c = {"active": [r] if active else [], "deduped": [r], "waves": [], "contract_seams": []}
    m = {"delivered": {"384": [386]} if delivered else {}, "requests": {"r": {}}, "excluded": []}
    p = space["_build_proposal"](engine, c, [b], m, "t", "r")
    return {"scheduled": [l["issue"] for w in p["provisional"]["waves"] for l in w], "held": p["held"]}
for label, args in [
    ("delivered draft", ("draft", False, True)),
    ("ordinary draft", ("draft", False, False)),
    ("delivered ready active", ("ready", True, True)),
    ("ordinary ready active", ("ready", True, False)),
    ("delivered ready inactive", ("ready", False, True)),
    ("ordinary ready inactive", ("ready", False, False))]:
    print(label + ": " + json.dumps(measure(ns, *args)))
mutated = copy.deepcopy(nodes)
fn = next(n for n in mutated if n.name == "_build_proposal")
loop = next(n for n in fn.body if isinstance(n, ast.For) and isinstance(n.target, ast.Name) and n.target.id == "b")
assert isinstance(loop.body[0], ast.If)
loop.body[0].body = loop.body[0].body[2:]
red = measure(load(mutated), "draft", False, True)
assert red["scheduled"] == [384] and not red["held"]
print("guard-removed control: " + json.dumps(red))
reason = "possibly delivered: closed by merged PR #386, #400; issue still open"
assert ns["_delivered_hold"]({"384": [386, 400]}, 384) == reason
assert ns["_delivered_hold"]({}, 384) is None
print("reason bytes and absent key: OK")
PY
```

Decisive output:

```text
delivered draft: {"scheduled": [], "held": [{"issue": 384, "reason": "possibly delivered: closed by merged PR #386; issue still open"}]}
ordinary draft: {"scheduled": [384], "held": []}
delivered ready active: {"scheduled": [], "held": [{"issue": 384, "reason": "possibly delivered: closed by merged PR #386; issue still open"}]}
ordinary ready active: {"scheduled": [384], "held": []}
delivered ready inactive: {"scheduled": [], "held": []}
ordinary ready inactive: {"scheduled": [], "held": []}
guard-removed control: {"scheduled": [384], "held": []}
reason bytes and absent key: OK
```

Relay closed (Approved), no further turn needed.


### Attestation · relay-drive — 2026-10-31T19:07:55Z
task: RELAY-gh1294-final-qa
reviewer: codex
status: Approved
reviewed-head: 0d20c8a386263ad1c7c92da03af0558d2102b07b
added-range: 12989+5991
added-sha256: 3465ab02a88c705795f0fd2a9bde9a7d862ca834e7d1422f79222c7e6fbf6d28
<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
