# GH-1459 — CodeRabbit Major fixes after merging development (2026-11-19)

Manual check (no new suite, GH-831). Pre-fix: PR head `6f0d34d71`. Probe stubs every GitHub call
(no network writes); source below. Command: `python3 probe.py <checkout> ok|prev-fail`.

| Finding | Fix | Fixed | Pre-fix `6f0d34d71` |
|---|---|---|---|
| Planner ran a checkout-local `bin/tick` during scans | `_resolve_tick_bin` returns only the engine's own `bin/tick` (`TICK_REPO_ROOT` still points at the checkout) | `fix2 tick: engine (<engine>/bin/tick)` | `fix2 tick: checkout-local` |
| Retirement-candidate branch rows became active claims | operator claim loop skips rows whose `next_action` starts `retire?` | `mode=ok ... claims=[42]` | `claims=[41, 42]` (41 is the retire row) |
| Publish replaced claims when carryover inputs failed | `--publish-ledger` refuses (exit 3) when previous-ledger comments failed or carryover is unverified | `mode=prev-fail rc=3 publish_calls=[] receipt=refused` | `mode=prev-fail rc=0 publish_calls=[900]` |
| Skill told the agent to publish without asking | daily-planner Step 4 requires an explicit operator yes before `--publish-ledger` | text | — |

Happy path unchanged: `mode=ok rc=0 publish_calls=[900]` on both.

## Probe source

```python
"""Stubbed probe for PR #1460 CodeRabbit Major fixes. No GitHub calls: every gh-touching helper is stubbed."""
import os, sys, types, tempfile, stat
from datetime import datetime, timezone
from pathlib import Path
root = Path(sys.argv[1]); sys.path.insert(0, str(root / "skills/3-weekly/weekly-planner/scripts"))
import planner_core as pc

# Fix 2: checkout-local bin/tick is never chosen
tmp = Path(tempfile.mkdtemp()); (tmp / "bin").mkdir(); t = tmp / "bin" / "tick"; t.write_text("#!/bin/sh\necho pwned\n"); t.chmod(0o755)
got = pc._resolve_tick_bin(tmp)
print("fix2 tick:", "checkout-local" if got == t else f"engine ({got})")

today = {"number": 900, "ledger_date": "2026-11-19"}; prev = {"number": 899, "ledger_date": "2026-11-18"}
def disc_stub(**kw):
    kw["coverage"].append(pc._coverage("ledger discovery", "ok"))
    return {"today_ledger": today, "today_duplicates": [today], "previous_ledger": prev, "previous_duplicates": [prev],
            "created_issue": False, "auth_refused": None}
calls = []
pc.resolve_gh_slug = lambda r, g: "x/y"
pc.run_cmd = lambda argv, cwd=None, **k: "noelsaw1" if argv[:3] == ["gh", "api", "user"] else ""
pc.get_open_issues = lambda r, s: {41: {"title": "t41"}, 42: {"title": "t42"}}
pc._gh_json = lambda *a, **k: []
pc.find_or_create_daily_ledger_issue = disc_stub
pc.discover_local_roots = lambda *a, **k: [Path("/nonexistent")]
pc.scan_local_checkout = lambda *a, **k: [
    {"kind": "branch", "ref": "old", "issue_numbers": [41], "next_action": "retire? name match — verify with /merge-cleanup"},
    {"kind": "branch", "ref": "live", "issue_numbers": [42], "next_action": "continue"}]
pc.sync_daily_ledger_comment = lambda **kw: (calls.append(kw["issue_num"]) or (True, "stub-synced", {"action": "stub"}))
mode = sys.argv[2]
def rlc(repo_root, slug, issues, label, coverage):
    if label == "previous ledger comments" and mode == "prev-fail":
        coverage.append(pc._coverage(label, "failed", "stub failure")); return None
    coverage.append(pc._coverage(label, "ok", count=0)); return []
pc.read_ledger_comments = rlc
args = types.SimpleNamespace(ledger_tz="UTC", repo_mode="gh-only", device_id="probe", allow_delegate_comment=False,
                             operator="noelsaw1", local_roots=["/nonexistent"], ledger_issue=None, publish_ledger=True)
data, rc = pc.run_daily_ledger(root, "x/y", [], {}, args, datetime.now(timezone.utc))
print(f"mode={mode} rc={rc} publish_calls={calls} claims={data['operator_claim_issues']} receipt={data.get('publish_receipt',{}).get('action')}")
```
