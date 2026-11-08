---
Goal: Final QA for GH-1309 (skills-army-hq --migrate-legacy)
Date: 2026-11-01
---

NEXT: codex
STATUS: Approved

# Context

Review the committed change for https://github.com/HiQS-Labs/XYZ-forge/issues/1309 against its approved plan (PROJECT/2-WORKING/GH-1309-SA-MIGRATE-LEGACY.md; plan QA Approved in relay-system/2026-11-01/gh1309-plan-qa.md). Diff: `git diff cb1bf933..HEAD -- skills CHANGELOG.md TESTS-RESULTS`. Evidence: TESTS-RESULTS/2026-11-01+GH-1309/ (manual-check.md has the full matrix output and the script text; provenance.jsonl).

Operational envelope: a small, opt-in change to the Skills Army HQ scripts. Grade against the stated requirement and commensurate complexity. No new test file or registry entry (GH-831). The tool states it is not a security boundary against a hostile process with the same user's write access. Review only: edit nothing except this relay file. No network calls.

Producer notes: plan QA asked for the overlap check to be specific to retirement and for the docs to say an older manager cannot replay the new pending receipts; both are in. During verification a redundant name comparison was found (skill_info already enforces folder/name) and removed (commit 190be352).

Questions:

1. Does the code satisfy the plan and issue #1309? Cite file:line for: the new flag and flag-combination errors (sync.py main), retire_legacy and the reconcile changes, the retire-directory apply change and replay rule, and the validate_receipt widening with the overlap check (intake.py).
2. Ordering and failure behaviour: is the retire-directory action always emitted immediately before its link action? What happens if archive() or the staging mkdir fails after planning other keys, or if reconcile later errors for the same key? Is any partial state left that a repeat run cannot handle?
3. Did anything slip in beyond the plan (a second writer, changed semantics of --adopt, --migrate, --migrate-from or --retire-trinity, unrelated edits)?
4. Does the evidence support the claims: 36 of 36 matrix checks including red controls A (base rejects the flag), B and C (forged receipts), replay, and the existing 33-test suite? Is any promised case missing? Is the docs text (recovery.md, SKILL.md) accurate against the code?
5. Is the persisted rating (45/30/50/60) still consistent? Is the Costly reversibility claim stated honestly in the CHANGELOG?

Each `[Blocker]` or `[Should]` must carry `Observed input:`, `Affected scope:` and `Falsifier:` lines. Cite file:line.

Write your verdict below. Set STATUS to Approved if the change can ship as committed (minor notes allowed). Otherwise hand back with changes requested.

<!-- ▽ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK ▽ -->
▶ TAKE YOUR TURN (codex)
<!-- △ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK △ -->


# Codex final QA — 2026-11-01

**Approved.** No Blocker or Should findings in the reviewed implementation. The explicit, archived migration satisfies the approved plan within the stated local CLI envelope. Reversibility remains **Costly**: app roots change, with verified ZIPs and retained staging providing rollback.

1. **Implementation — Pass.** In `skills/3-weekly/skills-army-hq/scripts/sync.py`, the repeatable flag and help are at :374-378, safe-name validation at :387-388, incompatible retirement selection at :410-413, and archive-only refusal at :415-416. `retire_legacy` (:242-262) requires explicit archival and a valid folder identity, records the digest and content comparison, and on apply archives before staging and checking the filesystem. `reconcile` (:265-320) selects only desired entries in enabled targets, leaves links/absent entries to the existing logic, and reports unknown names or “nothing to migrate.” In `skills/3-weekly/skills-army-hq/scripts/intake.py`, :537-549 selects the action's safe name and verifies retained content before accepting an absent/symlink leaf on replay; :570-574 permits deployed names plus trinity and excludes equality and both directions of collection overlap. The following link action still checks its exact expected destination/pre-state (:505-514).

2. **Ordering and failures — Pass.** Retirement actions remain local to the current key until `actions.extend(retire)`, immediately followed by that key's link append (`sync.py:280-307`). There is no intervening sort. An archive or staging failure is caught for that key (:315-316), without adding its retire/link pair; earlier independent keys remain planned and may apply as the existing partial-sync contract permits (:427-429). An archive failure can retain a partial ZIP; a staging failure can retain a verified ZIP; a filesystem refusal can also retain an empty stage. None has moved the app folder, and a repeat can use a new archive suffix/stage. There is no ordinary fallible ownership lookup between successful retirement planning and pair insertion for this branch: current is None and the key is desired. After application starts, `transact` writes the pending receipt before `finish` executes ordered actions (`intake.py:596-621`). A rename followed by link failure leaves the intact staged folder and pending receipt; recovery rechecks the digest, replays retirement as a no-op and retries the link. External changes can require inspection rather than blind retry, as documented. This is recoverability, not all-or-nothing filesystem rollback.

3. **Scope and existing semantics — Pass within inspected sources.** The existing archive, action handler and transaction writer are reused; no second writer or new gate is introduced here. The adopt/migrate/migrate-from branches still use their original link-only checks (`sync.py:287-303`); `retirement` retains the trinity source identity/content restriction (:323-359). The intended shared-handler changes are the generalized retirement name, root guard and replay behavior. I did not run git or independently enumerate the committed diff, so this is a bounded source/plan assessment, not an attestation that every file in the commit range was enumerated.

4. **Evidence and docs — Pass, with execution limits.** `TESTS-RESULTS/2026-11-01+GH-1309/manual-check.md` contains nonempty output and reproducible script text covering all promised matrix cases: stale content with mode/internal link, preview, refusal combinations, matching content, repeat/unknown name, mismatched frontmatter, action replay, and positive/negative receipt shapes. Its 36-check total is consistent with its counter logic (30 ordinary checks plus six receipt verdicts). A demonstrates the base feature gap; B/C demonstrate guard refusals alongside positive controls. The existing-suite receipt explicitly says 33 passed and four subtests passed, rather than merely relying on the wrapper's possibly skipped exit zero. `provenance.jsonl` ties the matrix/suite to 190be352 and gates to d28cce4e; `gates.md` records the disposable full clone, 6/6 subsystem gate, doc gate and intact identity. These are inspected producer receipts, **[Unverified — needs clone run]** for independent suite execution in this turn; no suite or executable fixture was run here. Cross-device migration and the real app migration remain unverified, explicitly disclosed. No promised matrix case is missing. `references/recovery.md:169-181` accurately explains selection, backups, rollback and the older manager's inability to recover the new receipts; `SKILL.md:198-199` supplies preview/apply commands and :164-170 retains specific approval and partial-result review.

5. **Rating and reversibility — Pass.** `releases.sql:958` persists 45/30/50/60, matching the plan's modest severity, operator-driven priority, neutral appeal and bounded effort. Other-device recurrence remains a hypothesis. `CHANGELOG.md:3-6` honestly states Costly and the two recovery copies; it does not claim automatic rollback or a deployed real-world fix.

6. **Review evidence boundaries.** Verify-tier discovery attempted the nearest `XYZ-forge` graph. Its generation was 2026-09-01T15:54:30Z, rooted in the primary checkout; the bounded symbol query returned zero, and coverage marked both current script paths `freshness: not_tracked`. I therefore read the seeded sources directly rather than treating the graph as current evidence. No negative completeness claim rests on that index. No network or git command ran. Only this relay file was edited; scratch setup used the authorized directory.

## Narrow probes witnessed during this turn

Both commands used `export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"`; `mkdir -p "$TMPDIR"` was the only probe setup write. Both ran as `python3 -B - <<'PY'` with the stdin below. Exit status **0** for each. These are bounded in-memory validation/planning probes, not filesystem migration or suite runs.

Receipt-guard probe stdin:

```python
import sys, json
from pathlib import Path
from unittest.mock import patch
base = Path.cwd() / "skills/3-weekly/skills-army-hq"
sys.path.insert(0, str(base / "scripts"))
import sync, intake as s
root = Path.cwd() / ".relay-scratch/tmp/collection"
parent = base.parent
name = base.name
state = {"schema":s.SCHEMA,"root":str(root),"collection":"0"*32,"skills":{name:{"digest":"b"*64}},"links":{}}
config = {"schema":s.SCHEMA,"targets":[]}
# Discover the exact config shape from the validator without executing filesystem actions.
import inspect
print(inspect.getsource(s.validate_targets))
def receipt(act):
    r={"schema":s.SCHEMA,"root":str(root),"state":state,"targets":config,"actions":[act]}
    r["checksum"]=s.receipt_digest(r)
    return r
good={"kind":"retire-directory","name":name,"root":str(parent),"op":"a"*32,"before":"b"*64,"after":None}
for label,act in [("valid",good),("equal",{**good,"root":str(root)}),("inside",{**good,"root":str(root/"backups")}),("ancestor",{**good,"root":str(root.parent)}),("unknown",{**good,"name":"unknown"})]:
    try:
        s.validate_receipt(root,receipt(act)); print(label+": accepted")
    except Exception as e: print(label+": "+str(e))
```

Decisive output (the command also printed the validator source):

```text
valid: accepted
equal: Retirement root overlaps collection
inside: Retirement root overlaps collection
ancestor: Retirement root overlaps collection
unknown: Invalid retirement
```

Planning-failure probe stdin:

```python
import sys, types
from pathlib import Path
from unittest.mock import patch
base=Path.cwd()/"skills/3-weekly/skills-army-hq"
sys.path.insert(0,str(base/"scripts"))
import sync, intake as s
root=Path.cwd()/".relay-scratch/tmp/collection"
parent=base.parent; name=base.name
config={"targets":[{"enabled":True,"path":str(parent)}]}
found={name:{"digest":"b"*64}}
original_stat=Path.stat
def stat(path,*a,**kw):
    if path.parent == root/".staging":
        return types.SimpleNamespace(st_dev=original_stat(base).st_dev)
    return original_stat(path,*a,**kw)
for mode in ("archive-fail","mkdir-fail","success"):
    state={"collection":"0"*32,"links":{}}
    with patch.object(s,"archive",side_effect=OSError("archive failed") if mode=="archive-fail" else None,return_value="backups/verified.zip"), patch.object(s,"digest",return_value="b"*64), patch.object(Path,"mkdir",side_effect=OSError("mkdir failed") if mode=="mkdir-fail" else None), patch.object(Path,"stat",stat):
        actions,errors,changes=sync.reconcile(root,state,config,found,legacy=(name,),archive_directories=True,apply=True)
    kinds=[a["kind"] for a in actions]
    assert kinds == ([] if mode!="success" else ["retire-directory","link"]), (mode,kinds)
    assert bool(errors)==(mode!="success")
    print(mode+": actions="+str(kinds)+"; errors="+str([e["error"] for e in errors]))
print("No action_apply/transact called; archive/mkdir mocked; existing app/source bytes untouched.")
```

Decisive output:

```text
archive-fail: actions=[]; errors=['archive failed']
mkdir-fail: actions=[]; errors=['mkdir failed']
success: actions=['retire-directory', 'link']; errors=[]
No action_apply/transact called; archive/mkdir mocked; existing app/source bytes untouched.
```

### Attestation · relay-drive — 2026-11-01T15:53:01Z
task: RELAY-gh1309-final-qa-075004
reviewer: codex
status: Approved
reviewed-head: 4017be270840851b69877f083ded1e8bcb35e90c
added-range: 2790+9250
added-sha256: a099b2007c1400bba4855e6af5666aa36c4674990d71acd62e2994f22af5ba07
