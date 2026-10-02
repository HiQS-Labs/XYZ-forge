# RELAY · GH922 final QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-02.
-->

NEXT: Producer
STATUS: Approved
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
6. **Commit only the relay file** (`relay(gh922-final-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **final-qa.md** (embedded below — read it here).
- Reviewer: codex   ·   Producer: codex-producer
- Started: 2026-10-02

### Artifact — final-qa.md
```
Final review GH922 source diff from base 8c2e6cf3b18b2e3d58ff532f30d538a0dee3eb32. Read PROJECT/2-WORKING/GH-922-CODEX-SCOPE.md, entire task-sync codex.py/task_sync.py/core.py/SKILL.md and TESTS-RESULTS/2026-10-02+GH-922 evidence/provenance. Operational envelope local read-only desktop planner; native tools write; user authorized stacked PR on #902, no deployment. Questions: 1 Does projectId skip before activity validation fix pinned project chats and preserve all eligible checks? 2 Is one-line production diff DRY and sufficient, no new suite/gate/writer? 3 Do committed synthetic base-red, 11 fixed controls and 28 existing controls substantiate requirements? 4 Is rating 80/80/50/95 and dependency sequence #900/#902 honest? Qualifying Small gate runs after Approved in a separate full clone; do not claim it already passed. Review whole affected code; quote citations. Only relay writable, no tests/validate/pytest in worktree. Return Approved if implementation/focused evidence has no concrete blocker, include swept file: yes.
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
Basis: Implementation and focused evidence have no concrete blocker. Qualifying Small gate remains pending in a separate disposable full clone; this approval does not attest landing, deployment or hosted checks.
swept file: yes

- [Pass] Correct eligibility boundary: skills/3-weekly/task-sync/scripts/adapters/codex.py:91 adds 'or row.get("projectId") is not None' before activity lookup (:96). Non-null project chats skip even in Pinned; absent/null IDs remain eligible. Existing kind/local-host/heartbeat/section/updatedAt checks (:90-95), actual-turn validation and old-turn skip (:97-101) remain intact. Native policy at skills/3-weekly/task-sync/SKILL.md:104 says “Preserve project-grouped chats.” The in-memory probe below witnessed failure without the predicate and continued eligible-activity refusal with it. Fix: none.
- [Pass] Minimal and DRY: codex.py:104-105 still uses shared core.clean_base(max_length=None) and core.local_stamp; :110 avoids reaffirming existing pins; :106-112 emits proposals only. skills/3-weekly/task-sync/scripts/task_sync.py:210 refuses Codex apply/title/unpin/group before dispatch; core.py:72 retains shared default normalization. Read all of codex.py, task_sync.py, core.py and SKILL.md, including pre-existing code; no concrete pre-existing defect found in that sweep. No new helper, suite, gate or writer is needed. Fix: none.
- [Pass] Retained focused evidence is substantive: TESTS-RESULTS/2026-10-02+GH-922/manual-command.txt:11 seeds ten rows; :17 requires exactly two eligible renames and one new pin; :19 checks seven refusals; :32 checks idempotence; :33 requires CLI exit 3. base-red.log ends “Codex actual turn activity missing/invalid for project-pin”; fixed-green.log ends “TOTAL 11”; existing-probe.json lists 28 controls. Also read their original source in full, TESTS-RESULTS/2026-09-30+GH-901/manual_probe.py, including its nonempty assertion (:43) and red control (:87). All three artifact hashes match provenance.jsonl:1-3, which attributes base to 8c2e6cf3 and fixed to 65e60c9c. These are inspected recorded receipts, not suite reruns this turn. Fix: none.
- [Pass] Ratings and dependencies are honest as documented judgments: PROJECT/2-WORKING/GH-922-CODEX-SCOPE.md:36 explains 80/80/50/95 as work-blocking, local, no observed data loss and cheap effort, with preceding incident rate unknown. :32 counts one incident repeated across five ticks; :22 explicitly requires #900 then #902 and forbids deployment/merge. This does not claim either prerequisite has landed. Fix: none.
- [Unverified — needs clone run] Small qualifying gate, full acceptance replay and hosted exact-head checks were not run here as instructed. PROJECT/2-WORKING/GH-922-CODEX-SCOPE.md:43 and :52 keep them pending. Harness must complete the disposable-clone gate before merge readiness.

Evidence method: Verify-tier graph attempted after complete project pagination. This worktree is not indexed; nearest XYZ-forge generation 2026-09-01T15:54:30Z returned zero task-sync symbols. Coverage for all four source paths reported freshness missing and scope total 0. Therefore material claims use current full source reads, not graph completeness. No git, suite, pytest, executable fixture, live native mutation or artifact edit was performed.

Review-time command (exit 0; in-memory sweep query, no snapshot file or store writes):
~~~sh
export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"
mkdir -p "$TMPDIR"
python3 - <<'PROBE'
import hashlib,json,sys,time
from pathlib import Path
p=Path("TESTS-RESULTS/2026-10-02+GH-922")
records=[json.loads(s) for s in (p/"provenance.jsonl").read_text().splitlines()]
assert len(records)==3
for r in records:
 data=(p/r["artifact"]).read_bytes();assert data and hashlib.sha256(data).hexdigest()==r["artifact_sha256"]
 print("HASH OK",r["artifact"],"recorded exit",r["exit_code"])
sys.path.insert(0,str(Path("skills/3-weekly/task-sync/scripts").resolve()))
import core
from adapters.codex import CodexAdapter
now=time.time()
rows=[dict(id=i,kind="codex",hostId="local",projectId=project,title="Review example",updatedAt=now) for i,project in [("project-pin","project"),("eligible",None)]]
class Probe(CodexAdapter):
 def _snapshot(self):return now,rows,{"project-pin"},{"codex:thread:local:project-pin":"pinned","codex:thread:local:eligible":"chats"},{"eligible":now-100}
r=Probe("unused","heartbeat").sweep()
assert r["swept"]==1 and r["skipped"]==1 and [x["task_id"] for x in r["renamed"]]==["eligible"]
print("FIXED: project-pin skipped; eligible renamed and pinned")
source=Path("skills/3-weekly/task-sync/scripts/adapters/codex.py").read_text();line='                    or row.get("projectId") is not None\n'
assert source.count(line)==1
namespace={};exec(compile(source.replace(line,""),"<in-memory omitted predicate>","exec"),namespace)
class Red(namespace["CodexAdapter"]):
 _snapshot=Probe._snapshot
try:Red("unused","heartbeat").sweep()
except core.AdapterError as e:assert "project-pin" in str(e);print("RED:",str(e))
else:raise AssertionError("omitted predicate did not fail")
class Missing(Probe):
 def _snapshot(self):a,b,c,d,e=super()._snapshot();return a,b,c,d,{}
try:Missing("unused","heartbeat").sweep()
except core.AdapterError as e:assert "eligible" in str(e);print("ELIGIBLE REFUSAL:",str(e))
else:raise AssertionError("eligible activity check weakened")
print("PROBE PASS")
PROBE
~~~
Decisive output:
~~~text
HASH OK base-red.log recorded exit 1
HASH OK fixed-green.log recorded exit 0
HASH OK existing-probe.json recorded exit 0
FIXED: project-pin skipped; eligible renamed and pinned
RED: Codex actual turn activity missing/invalid for project-pin
ELIGIBLE REFUSAL: Codex actual turn activity missing/invalid for eligible
PROBE PASS
~~~

Relay closed (Approved), no further turn needed. Producer/harness proceeds with the separate-clone Small gate; token completed with done per operator instruction.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
