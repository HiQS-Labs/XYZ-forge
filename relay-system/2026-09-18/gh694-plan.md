# Plan: GH-694 — Express Telemetry Schema Alignment & Tick Fold Resilience

## 1. Problem Statement & Root Cause
In task clones where `/express` has fired, running `./bin/tick info`, `./bin/tick release`, or any command that invokes `fold` throws:
```text
TypeError: Cannot read properties of undefined (reading 'localeCompare')
```

### Root Cause
1. **Producer (`utils/py/express.py:97-110`):** `write_tick()` writes ad-hoc telemetry records to `.tick/events/` formatted as `{"at": "...", "actor": "express", "verb": "express-fired", "issue": 693}`. It omits `schema_version`, `ts`, `type`, `task`, and `agent`.
2. **Consumer (`src/project.js:53-63`):** `foldWithMeta()` buckets all events in `.tick/events/` by `ev.task`. When `ev.task` is undefined, `byTask` creates a map key `undefined`. Iterating over `byTask` instantiates a task `{ id: undefined, status: 'open', ... }`. Subsequently, `renderState()` (`src/project.js:295`) calls `a.id.localeCompare(b.id)` which throws on `undefined`.

## 2. Proposed Changes (Ponytail Least-Mechanism)

### Component A: Producer — Canonical Tick Event Envelope
**File:** `utils/py/express.py` (`write_tick()`)
Update `write_tick(root, verb, **fields)` to construct the event payload with the canonical 0.2.0 envelope:
```python
def write_tick(root, verb, **fields):
    events = os.path.join(root, ".tick", "events")
    ts = datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%dT%H-%M-%S.%f")[:-3] + "Z"
    target = "gh-%s" % fields.get("issue") if fields.get("issue") else "lane"
    filename = "%s-%s-%s.jsonl" % (ts, verb, target)
    
    ev_type = "express." + verb.replace("express-", "")
    task_id = "GH-%s" % fields.get("issue") if fields.get("issue") else "lane"
    
    rec = dict(
        schema_version="0.2.0",
        ts=now_iso(),
        type=ev_type,
        task=task_id,
        agent="express",
        at=now_iso(),
        actor="express",
        verb=verb,
    )
    rec.update({k: v for k, v in fields.items() if v is not None})
    payload = json.dumps(rec) + "\n"
    # Write to local .tick/events/ and central ~/.config/xyz/events/
```

### Component B: Consumer — Defensive Task Filter in Tick Fold
**File:** `src/project.js` (`foldWithMeta()`)
Tick is a task coordination kernel; non-task coordination events (e.g. `dependency.drift`, `cost.*`, `marathon.*`, `express.*`) and malformed events without a valid string `task` identity must never seed phantom tasks or mutate the task projection in `STATE.md`.
Retain and update the explanatory rationale comment above the filter in `src/project.js:54-63`:
```javascript
  for (const ev of events) {
    // Non-coordination events (dependency.drift GH-68, telemetry signals such as express.*,
    // cost.*, marathon.*) do not claim tasks or transition task states; skip them so they never
    // seed phantom `open` tasks in `tick project`/`next` or corrupt the task projection.
    if (!ev || typeof ev.task !== 'string' || !ev.task) continue;
    if (!ev.type || !ev.type.startsWith('task.')) continue;
    if (!byTask.has(ev.task)) byTask.set(ev.task, []);
    byTask.get(ev.task).push(ev);
  }
```

### Component C: Test Verification & Coexistence Pin
**File:** `test/gh267-express-skill.sh`
In `test/gh267-express-skill.sh`:
- In the `== refusals ==` section after `express-refused tick event written`:
  Add assertion:
  ```bash
  TICK_REPO_ROOT="$FX" "$HERE/../bin/tick" project >/dev/null 2>&1
  assert_eq "$?" "0" "tick project must fold cleanly after express-refused telemetry"
  ```
- In the `== run ==` happy-path section after `tick event written on run happy path`:
  Add assertion:
  ```bash
  TICK_REPO_ROOT="$FX" "$HERE/../bin/tick" project >/dev/null 2>&1
  assert_eq "$?" "0" "tick project must fold cleanly after express-fired telemetry"
  ```

## 3. Blast Radius & Non-Goals
- **Blast Radius:** 2 production files (`utils/py/express.py`, `src/project.js`), 1 test suite (`test/gh267-express-skill.sh`).
- **Non-Goals:**
  - No complex cross-language validation middleware.
  - No changes to central telemetry store (`~/.config/xyz/events/`).
  - No governance document edits (existing `AGENTS.md` and `GUIDING-PRINCIPLES.md` already govern shared kernel surfaces).

## 4. Verification Plan
1. **Focused Test:** `bash test/gh267-express-skill.sh` (all 98+ assertions PASS).
2. **Tick Engine Test:** `npm test` (all 23 tests PASS).
3. **Negative Control:** With the pre-fix `write_tick()` and without the `src/project.js` guard, `TICK_REPO_ROOT="$FX" "$HERE/../bin/tick" project` fails with `TypeError: Cannot read properties of undefined (reading 'localeCompare')`. With the fix, it exits 0 cleanly.
