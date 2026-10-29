# GH-1251 manual smoke: marathon planner fails closed on unknown preflight exits, missing dependencies and unplaceable lanes

- **Date:** 2026-10-29
- **Platform:** macOS (Darwin arm64), Python 3
- **Base commit:** `93f41cb8409068182f85dbc9352b2ab909427b7f` (`development`), worktree HEAD `bb8c9d4cd427e4470c58c6873869f52a54a56bc3`
- **Target surface:** `utils/py/_marathon_plan.py` (`Engine.run`, `Engine._render_queue_doc`)
  - Candidate `utils/py/_marathon_plan.py` SHA-256: `4c68dc4636c1358cccacd2a343fe327af854c4cc39904f28c55a1155fcc6830e`
  - Base `93f41cb8` `utils/py/_marathon_plan.py` SHA-256: `e8d4bcd4f8298bfc80d636b8400ab9ecc3c3ea0ff6898a65ceb99f0390fcebed`
- **No new test suite added** (GH-831).

## Phase 0

1. **Planner fixtures grep (`test/marathon-plan.sh`, `test/gh418-planner-ledger-source.sh`, `test/gh362-marathon-plan-link-bullets.sh`, `test/gh423-roadmap-render.sh`):**
   - `test/marathon-plan.sh` Scenario A (`:117`) tests a ready dependency (`GH-104` after `GH-100`, both in the ledger).
   - `test/marathon-plan.sh` Scenario G (`:234-250`) tests a dependency on a **present-but-held** ledger item (`GH-701` depends on `GH-710`, which is in the ledger and unrated), not a missing ledger row.
   - `test/marathon-plan.sh` Scenario H (`:255-272`) tests Oxford-comma dependencies (`GH-802` depends on `GH-800`, `GH-801`, `GH-803`, all present in the ledger).
   - `test/marathon-plan.sh` Scenario T (`:629-725`) has neither a dependency cycle, a missing dependency, nor `--deep` delegation, so cross-lane parity (`70 passed, 0 failed, 2 skipped`) is unaffected; the GH-698 rendered-table skip (`:688-697`) is untouched.
   - None of the existing planner suites (`test/marathon-plan.sh`, `test/gh418-planner-ledger-source.sh`, `test/gh362-marathon-plan-link-bullets.sh`, `test/gh423-roadmap-render.sh`) pin the old advisory behaviour on missing dependencies, unknown `--deep` preflight exits, or unplaceable wave cycles. Zero test files required edits.

## Self-Contained Reproducible Manual Recipe

Run with `PYTHONDONTWRITEBYTECODE=1 python3 -` from the repository root (uses `tempfile.TemporaryDirectory()` under `$TMPDIR` and performs zero writes inside the repository):

````python
import hashlib, importlib.util, io, os, stat, sys, tempfile
from contextlib import redirect_stdout
from pathlib import Path

REPO_ROOT = Path(".").resolve()
sys.path.insert(0, str(REPO_ROOT / "utils/py"))

def load_from_source(src: str, mod_name: str):
    with tempfile.NamedTemporaryFile("w", suffix=".py", delete=False, encoding="utf-8") as tf:
        tf.write(src)
        tmp_path = Path(tf.name)
    try:
        spec = importlib.util.spec_from_file_location(mod_name, str(tmp_path))
        mod = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(mod)
        return mod
    finally:
        tmp_path.unlink(missing_ok=True)

cand_src = (REPO_ROOT / "utils/py/_marathon_plan.py").read_text(encoding="utf-8")
cand_sha = hashlib.sha256(cand_src.encode("utf-8")).hexdigest()

# Reconstruct exact base 93f41cb8 source in memory for the red control
base_src = (
    cand_src
    .replace(
        '                if code == 3:\n'
        '                    r["state"] = "needs-contract"\n'
        '                    self._flag("info", "needs-contract", r,\n'
        '                               "swarm-preflight --dry-run → invalid contract (exit 3)",\n'
        '                               "fix the ## Swarm Preflight Contract json block")\n'
        '                elif code == 4:',
        '                if code == 4:'
    )
    .replace(
        '                elif code != 0:\n'
        '                    r["state"] = "preflight-error"\n'
        '                    self._flag("warn", "preflight-error", r,\n'
        '                               "unknown/failed preflight exit %d — hold; rerun swarm-preflight directly" % code,\n'
        '                               "rerun swarm-preflight directly")\n',
        ''
    )
    .replace(
        '                    if dep and (dep["state"] in DEP_RESOLVED or dep["state"] == "ready"):',
        '                    if not dep or dep["state"] in DEP_RESOLVED or dep["state"] == "ready":'
    )
    .replace(
        '        while pending:\n'
        '            wave = []',
        '        guard = 0\n'
        '        while pending and guard < 100:\n'
        '            guard += 1\n'
        '            wave = []'
    )
    .replace(
        '            if len(wave) == 0:\n'
        '                for r in deferred:\n'
        '                    r["state"] = "unplaceable"\n'
        '                    self._flag("warn", "unplaceable", r,\n'
        '                               "could not be placed in any wave (dependency cycle / zero zone cap) — hold, do not co-wave",\n'
        '                               "break the dependency cycle or raise the zone cap")\n'
        '                break',
        '            if len(wave) == 0:\n'
        '                waves.append(deferred)\n'
        '                break'
    )
    .replace(
        '        for i, w in enumerate(waves):\n'
        '            for r in w:\n'
        '                r["wave"] = i + 1\n'
        '        active = [r for w in waves for r in w]\n',
        '        for i, w in enumerate(waves):\n'
        '            for r in w:\n'
        '                r["wave"] = i + 1\n'
    )
    .replace(
        '        held = [r for r in deduped if r["state"] in\n'
        '                ("unrated", "needs-doc", "needs-contract", "note-only", "not-ready", "blocked", "blocked-dep",\n'
        '                 "preflight-error", "unplaceable")]',
        '        held = [r for r in deduped if r["state"] in\n'
        '                ("unrated", "needs-doc", "needs-contract", "note-only", "not-ready", "blocked", "blocked-dep")]'
    )
    .replace(
        '            ("⚠️ Not yet sequenceable — rate / add doc / add contract",\n'
        '             ["unrated", "needs-doc", "needs-contract", "not-ready", "blocked", "preflight-error", "unplaceable"]),',
        '            ("⚠️ Not yet sequenceable — rate / add doc / add contract",\n'
        '             ["unrated", "needs-doc", "needs-contract", "not-ready", "blocked"]),'
    )
)
base_sha = hashlib.sha256(base_src.encode("utf-8")).hexdigest()
assert cand_sha == "4c68dc4636c1358cccacd2a343fe327af854c4cc39904f28c55a1155fcc6830e", cand_sha
assert base_sha == "e8d4bcd4f8298bfc80d636b8400ab9ecc3c3ea0ff6898a65ceb99f0390fcebed", base_sha

DOC_TMPL = """---
complexity: 2
risk: 2
effort: 2
---
# GH-{gh}

## Swarm Preflight Contract
```json
{{"target":{{"repo":".","ref":"development"}},"gate":"true","fix_probes":[],"artifacts":["{art}"],"remediation":{{"source":"issue#{gh}","criteria":"test"}}}}
```
"""

def run_case(mod, case_id: str, preflight_rc: int = 0):
    with tempfile.TemporaryDirectory() as td:
        root = Path(td)
        (root / "PROJECT/1-INBOX").mkdir(parents=True, exist_ok=True)
        (root / "PROJECT/2-WORKING").mkdir(parents=True, exist_ok=True)
        if case_id == "case1":
            rm = "## Ledger\n### Queue / parked intake\n- **GH-100 · preflight test** — [doc](PROJECT/1-INBOX/GH-100-preflight.md)\n"
            docs = {"PROJECT/1-INBOX/GH-100-preflight.md": DOC_TMPL.format(gh=100, art="a.txt")}
            base_files = "a.txt\n"
            deep = True
        elif case_id == "case2":
            rm = "## Ledger\n### Queue / parked intake\n- **GH-200 · depends on missing** — [doc](PROJECT/1-INBOX/GH-200-missing.md) · after GH-999\n"
            docs = {"PROJECT/1-INBOX/GH-200-missing.md": DOC_TMPL.format(gh=200, art="b.txt")}
            base_files = "b.txt\n"
            deep = False
        elif case_id == "case3":
            rm = (
                "## Ledger\n### Queue / parked intake\n"
                "- **GH-300 · cycA** — [doc](PROJECT/1-INBOX/GH-300-cyca.md) · after GH-301\n"
                "- **GH-301 · cycB** — [doc](PROJECT/1-INBOX/GH-301-cycb.md) · after GH-300\n"
            )
            docs = {
                "PROJECT/1-INBOX/GH-300-cyca.md": DOC_TMPL.format(gh=300, art="c1.txt"),
                "PROJECT/1-INBOX/GH-301-cycb.md": DOC_TMPL.format(gh=301, art="c2.txt"),
            }
            base_files = "c1.txt\nc2.txt\n"
            deep = False
        elif case_id == "case4_101":
            lines = ["## Ledger", "### Queue / parked intake"]
            docs = {}
            for idx in range(1, 102):
                lines.append(f"- **GH-{idx} · serial lane {idx}** — [doc](PROJECT/1-INBOX/GH-{idx}-serial.md)")
                docs[f"PROJECT/1-INBOX/GH-{idx}-serial.md"] = DOC_TMPL.format(gh=idx, art="shared.txt")
            base_files = "shared.txt\n"
            rm = "\n".join(lines) + "\n"
            deep = False
        (root / "base_files.txt").write_text(base_files, encoding="utf-8")
        (root / "ROADMAP.md").write_text(rm, encoding="utf-8")
        for rel, content in docs.items():
            (root / rel).write_text(content, encoding="utf-8")
        pf = root / "stub_preflight.sh"
        pf.write_text(f"#!/usr/bin/env bash\nexit {preflight_rc}\n", encoding="utf-8")
        pf.chmod(pf.stat().st_mode | stat.S_IXUSR)

        cfg = {
            "root": str(root),
            "roadmap": str(root / "ROADMAP.md"),
            "queue_dir": str(root / "PROJECT/2-WORKING"),
            "today": "2026-10-29",
            "now": "2026-10-29T15:24:00Z",
            "policy": "quick-wins",
            "format": "text",
            "deep": deep,
            "require_gh": False,
            "swarm_preflight": str(pf) if deep else "",
            "sp_cmd": "utils/swarm-preflight.sh",
            "md_cmd": "relay-automation/marathon-drive.sh",
            "mp_cmd": "utils/marathon-plan.sh",
            "utils_dir": str(REPO_ROOT / "utils"),
            "zones_config": "",
            "gh_state_file": "",
            "branches_file": "",
            "branch_env": "development",
            "gh_force": "off",
            "base_files_file": str(root / "base_files.txt"),
            "zones_file_env": "",
        }
        render_out = root / "MARATHON-PLAN-2026-10-29.md"
        old_rm = os.environ.get("QUEUE_PLAN_ROADMAP")
        os.environ["QUEUE_PLAN_ROADMAP"] = str(root / "ROADMAP.md")
        try:
            buf = io.StringIO()
            with redirect_stdout(buf):
                rc = mod.run(cfg, str(render_out))
            doc = render_out.read_text(encoding="utf-8") if render_out.exists() else ""
            return rc, buf.getvalue(), doc
        finally:
            if old_rm is None:
                os.environ.pop("QUEUE_PLAN_ROADMAP", None)
            else:
                os.environ["QUEUE_PLAN_ROADMAP"] = old_rm

cand_mod = load_from_source(cand_src, "cand_mp")
base_mod = load_from_source(base_src, "base_mp")
for label, mod in [("CAND", cand_mod), ("BASE", base_mod)]:
    for code in (2, 3, 127):
        rc, out, _ = run_case(mod, "case1", preflight_rc=code)
        sum_line = [l for l in out.splitlines() if l.startswith("SUMMARY")][0]
        print(f"{label} case1(exit={code}): rc={rc} | {sum_line}")
    for cid in ("case2", "case3", "case4_101"):
        rc, out, _ = run_case(mod, cid)
        sum_line = [l for l in out.splitlines() if l.startswith("SUMMARY")][0]
        print(f"{label} {cid}: rc={rc} | {sum_line}")
````

## Case 1 — Deep delegation unknown/invalid preflight exits (`2`, `3`, `127`)

### On the fix (`utils/py/_marathon_plan.py`)
Running `Engine.run` (`--dry-run --deep`) with a stub `SWARM_PREFLIGHT` exiting `2`, `3`, and `127`:

- **Exit 2 (usage / unexpected failure):**
  ```
  FLAGS (deterministic signals — never auto-resolved)
    WARN [preflight-error]  GH-100 · preflight test
          unknown/failed preflight exit 2 — hold; rerun swarm-preflight directly
          → rerun swarm-preflight directly

  SUMMARY [marathon-plan] items=1 active=0 waves=0 drift=false held=1 (exit 5)
  ```
  Rendered under `### ⚠️ Not yet sequenceable — rate / add doc / add contract` as `- #100 GH-100 · preflight test — \`preflight-error\``. Planner exits `5`.

- **Exit 3 (invalid contract):**
  ```
  FLAGS (deterministic signals — never auto-resolved)
    INFO [needs-contract]  GH-100 · preflight test
          swarm-preflight --dry-run → invalid contract (exit 3)
          → fix the ## Swarm Preflight Contract json block

  SUMMARY [marathon-plan] items=1 active=0 waves=0 drift=false held=1 (exit 5)
  ```
  Rendered under `### ⚠️ Not yet sequenceable — rate / add doc / add contract` as `- #100 GH-100 · preflight test — \`needs-contract\``. Planner exits `5`.

- **Exit 127 (command not found / signal / other nonzero):**
  ```
  FLAGS (deterministic signals — never auto-resolved)
    WARN [preflight-error]  GH-100 · preflight test
          unknown/failed preflight exit 127 — hold; rerun swarm-preflight directly
          → rerun swarm-preflight directly

  SUMMARY [marathon-plan] items=1 active=0 waves=0 drift=false held=1 (exit 5)
  ```
  Rendered under `### ⚠️ Not yet sequenceable — rate / add doc / add contract` as `- #100 GH-100 · preflight test — \`preflight-error\``. Planner exits `5`.

### Base Red Control (`93f41cb8`)
At `93f41cb8`, all three stub exits (`2`, `3`, `127`) leave `r["state"] == "ready"` and pack `#100` into **Wave 1** with `exit 0`:
```
SUMMARY [marathon-plan] items=1 active=1 waves=1 drift=false held=0 (exit 0)
  DOC: **Wave 1:** #100
```

## Case 2 — Dependency on a missing issue (`#200` depends on `#999` not in ledger)

### On the fix (`utils/py/_marathon_plan.py`)
```
FLAGS (deterministic signals — never auto-resolved)
  INFO [blocked-dep]  GH-200 · depends on missing
        depends on a held/unbuildable item (#999) — excluded from active waves until the dependency is sequenceable
        → rate/unblock the dependency first
  INFO [dep-not-found]  GH-200 · depends on missing
        lists a dependency on #999, which is not in the ledger
        → fix the issue number or add a ledger pointer

SUMMARY [marathon-plan] items=1 active=0 waves=0 drift=false held=1 (exit 5)
```
`#200` is held as `blocked-dep` (rendered under `### ⛔ Blocked on a held dependency`), `active=0`, `waves=0`, `held=1`, and the planner exits `5`.

### Base Red Control (`93f41cb8`)
At `93f41cb8`, `#200` gets only the `dep-not-found` info flag, remains `ready`, and is packed into **Wave 1** with `exit 0`:
```
SUMMARY [marathon-plan] items=1 active=1 waves=1 drift=false held=0 (exit 0)
  DOC: **Wave 1:** #200
```

## Case 3 — Unplaceable lanes (two ready items in a dependency cycle: `#300` ↔ `#301`)

### On the fix (`utils/py/_marathon_plan.py`)
```
FLAGS (deterministic signals — never auto-resolved)
  WARN [unplaceable]  GH-300 · cycA
        could not be placed in any wave (dependency cycle / zero zone cap) — hold, do not co-wave
        → break the dependency cycle or raise the zone cap
  WARN [unplaceable]  GH-301 · cycB
        could not be placed in any wave (dependency cycle / zero zone cap) — hold, do not co-wave
        → break the dependency cycle or raise the zone cap

SUMMARY [marathon-plan] items=2 active=0 waves=0 drift=false held=2 (exit 5)
```
- Neither `#300` nor `#301` is placed in a wave (`active=0`, `waves=0`, `held=2`, planner exits `5`).
- `active` is recomputed from placed waves, so the per-item scoring table renders `| (no active, ready, rated items) | — | — | — | — | — |` rather than reporting the held lanes as both active and held.
- Both items render under `### ⚠️ Not yet sequenceable — rate / add doc / add contract` with state `` `unplaceable` ``.

### Base Red Control (`93f41cb8`)
At `93f41cb8`, the no-progress fallback appends all deferred lanes together into **Wave 1** (`#300 ‖ #301`) with `exit 0`:
```
SUMMARY [marathon-plan] items=2 active=2 waves=1 drift=false held=0 (exit 0)
  DOC: **Wave 1:** #300 ‖ #301
```

## Case 4 — 101 serialized ready lanes (no 100-wave silent drop)

### On the fix (`utils/py/_marathon_plan.py`)
Removing the redundant `guard < 100` bound (every productive iteration places at least one lane from `pending`, and `len(wave) == 0` breaks immediately) places all 101 serialized lanes across 101 waves without dropping `#101` from `active` or `held`:
```
CAND case4_101: rc=0 | SUMMARY [marathon-plan] items=101 active=101 waves=101 drift=false held=0 (exit 0)
```

### Base Red Control (`93f41cb8`)
At `93f41cb8`, the `guard < 100` cap stops at 100 waves (`waves=100`), leaving `#101` unplaced (`wave=None`):
```
BASE case4_101: rc=0 | SUMMARY [marathon-plan] items=101 active=101 waves=100 drift=false held=0 (exit 0)
```

## Existing Planner Suites in Disposable Full Clone

Executed in an isolated disposable full clone at `/var/folders/z0/92pfvhnn06z2_7hnpdb4kkbw0000gn/T/gh1251-suite-clone.MvB01E` (cloned from `/Users/noelsaw/marathon-clones/marathon-gh-1250-phase0-followups` with candidate `utils/py/_marathon_plan.py` `sha256:4c68dc4636c1358cccacd2a343fe327af854c4cc39904f28c55a1155fcc6830e` copied in and cleaned up on exit):

```
DISPOSABLE_CLONE=/var/folders/z0/92pfvhnn06z2_7hnpdb4kkbw0000gn/T/gh1251-suite-clone.MvB01E
  marathon-plan: 70 passed, 0 failed, 2 skipped
PASS: GH-418 planner ledger source
gh362-marathon-plan-link-bullets: 9 pass, 0 fail
# 8 tests, 8 passed, 0 failed (test/gh423-roadmap-render.sh)
gh308-frozen-twin-guard: clean (0 frozen twins modified)
```

## Verdict

PASS.

## Orchestrator addendum — CodeRabbit review on PR #1253 (2026-10-29)

1. **Consumer gap (Major), fixed.** `utils/py/wave_reconcile.py` `marathon_plan_findings` `held_types` now includes `preflight-error` and `unplaceable`. Before the fix, an exit-5 report carrying only these findings was treated as unstructured, and reconciliation continued. Red/green check (in-memory, both module versions):

```
base (pre-fix): exit-5 findings recognised = [] -> issues []
fix: exit-5 findings recognised = ['marathon-plan/preflight-error', 'marathon-plan/unplaceable'] -> issues [901, 902]
```

   Suites: `test/gh421-auto-wave-reconcile.sh` OK, `test/gh202-wave-reconcile-issue-state.sh` 40/0, `test/wave-reconcile.sh` 23/0, `test/gh168-wave-reconcile-scope.sh` 7/0.
2. **Rendering (Minor), fixed.** The recipe's outer fence is now four backticks, so its embedded ` ```json ` block no longer ends the recipe early on GitHub.
