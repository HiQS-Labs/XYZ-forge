# GH-1236 manual smoke: pre-push reuses a passing full-gate receipt for the exact pushed commit

- **Date:** 2026-10-29
- **Platform:** macOS (Darwin arm64), Bash 3.2, Python 3
- **Base commit:** `93f41cb8409068182f85dbc9352b2ab909427b7f` (`development`), worktree HEAD `627aeeec54f69e2ddfcfa9dd3842dec467fea14f`
- **Target surface:** `validate.sh`, `githooks/pre-push`, `utils/py/gate_receipt.py`, `utils/py/marathon_drive.py`
  - Candidate `validate.sh` SHA-256: `46a8f5c24eabe13006ec75476d726d19e60681e261dab3795bc74e5becc90b24` (base `93f41cb8`: `5bc9e473af296edb9029aedef8b4fbd0a281b3e7545803d055f5ac895a207220`)
  - Candidate `githooks/pre-push` SHA-256: `bd6009eaad974a6552f9fe6c9edfddab31a1a531f4d3f02e9e98e8dc70da13db` (base `93f41cb8`: `29edf96df79282e39f497d89f222c30ad27e71eea35ecf88dfe5baee4d474268`)
  - Candidate `utils/py/gate_receipt.py` SHA-256: `06f8ca103c9417475132f6fb39634bb6e8da9dd113b22380eb78142223de6644` (base `93f41cb8`: `adbb53e13c663cf243aac94ca8f47a3edb4ddda8f638654404a63319f6d3badb`)
  - Candidate `utils/py/marathon_drive.py` SHA-256: `cff5511d68be2b7d31bb4b1c7c4f0deda4f547d1c8b22fd7726cea8e0629d1b0` (base `93f41cb8`: `8233aded9cd3b4b88937625229a6df859b527572fe73c9943d3bc024008cad54`)
- **No new test suite added** (GH-831).

## Self-Contained Reproducible Manual Recipe

Run with `PYTHONDONTWRITEBYTECODE=1 python3 -` from the repository root (uses `tempfile.TemporaryDirectory()` under `$TMPDIR` and performs zero writes inside the repository):

```python
import json, os, shutil, stat, subprocess, sys, tempfile
from pathlib import Path

WT = Path(".").resolve()
BASE_COMMIT = "93f41cb8409068182f85dbc9352b2ab909427b7f"

def git_show(rev_path: str) -> bytes:
    return subprocess.check_output(["git", "-C", str(WT), "show", rev_path])

def setup_fixture_repo(root: Path, use_base: bool = False):
    root.mkdir(parents=True, exist_ok=True)
    subprocess.run(["git", "-C", str(root), "init", "-q"], check=True)
    subprocess.run(["git", "-C", str(root), "config", "user.email", "t@example.invalid"], check=True)
    subprocess.run(["git", "-C", str(root), "config", "user.name", "Tester"], check=True)
    shutil.copy2(WT / ".gitignore", root / ".gitignore")
    for d in ("githooks", "utils/py", "utils/pdda"):
        (root / d).mkdir(parents=True, exist_ok=True)
    if use_base:
        (root / "githooks/pre-push").write_bytes(git_show(f"{BASE_COMMIT}:githooks/pre-push"))
        (root / "utils/py/gate_receipt.py").write_bytes(git_show(f"{BASE_COMMIT}:utils/py/gate_receipt.py"))
    else:
        shutil.copy2(WT / "githooks/pre-push", root / "githooks/pre-push")
        shutil.copy2(WT / "utils/py/gate_receipt.py", root / "utils/py/gate_receipt.py")
    shutil.copy2(WT / "utils/ci-route.sh", root / "utils/ci-route.sh")
    for p in (root / "githooks/pre-push", root / "utils/ci-route.sh", root / "utils/py/gate_receipt.py"):
        p.chmod(p.stat().st_mode | stat.S_IXUSR)
    stub_validate = root / "validate.sh"
    stub_validate.write_text(
        "#!/usr/bin/env bash\n"
        'if [ "${1:-}" = "--print-mode" ]; then echo "validate.sh: PARALLEL mode 4-wide — stub"; exit 0; fi\n'
        'printf "invoked:%s\\n" "$*" >> "${STUB_LOG:?}"\n'
        'echo "stub validate.sh ran"\n'
        "exit 0\n",
        encoding="utf-8",
    )
    stub_validate.chmod(0o755)
    (root / "tool.js").write_text("console.log('v1');\n", encoding="utf-8")
    subprocess.run(["git", "-C", str(root), "add", "-A"], check=True)
    subprocess.run(["git", "-C", str(root), "commit", "-qm", "base"], check=True)
    base_sha = subprocess.check_output(["git", "-C", str(root), "rev-parse", "HEAD"], text=True).strip()
    (root / "tool.js").write_text("console.log('v2');\n", encoding="utf-8")
    subprocess.run(["git", "-C", str(root), "add", "tool.js"], check=True)
    subprocess.run(["git", "-C", str(root), "commit", "-qm", "change"], check=True)
    head_sha = subprocess.check_output(["git", "-C", str(root), "rev-parse", "HEAD"], text=True).strip()
    return base_sha, head_sha

def drive_prepush(root: Path, stdin_text: str):
    stub_log = root / "temp/stub-validate.log"
    stub_log.parent.mkdir(parents=True, exist_ok=True)
    stub_log.unlink(missing_ok=True)
    env = os.environ.copy()
    env["PYTHONDONTWRITEBYTECODE"] = "1"
    env["STUB_LOG"] = str(stub_log)
    proc = subprocess.run(
        ["bash", "githooks/pre-push"],
        cwd=str(root),
        input=stdin_text,
        text=True,
        capture_output=True,
        env=env,
    )
    invoked = stub_log.exists() and stub_log.read_text(encoding="utf-8").strip() != ""
    stub_log.unlink(missing_ok=True)
    return proc.returncode, (proc.stdout + proc.stderr).strip(), invoked
```

## Case 1 — Fix & Base Red Control: `pre-push` reuse of eligible `scope: full` receipt

- **On the fix (`githooks/pre-push` + `utils/py/gate_receipt.py`):**
  Writing an eligible receipt (`gate: "validate.sh"`, `mode: "parallel"`, `scope: "full"`, `exit_code: 0`) for the pushed local SHA (`a0ca3468...`) and feeding `refs/heads/feat <head_sha> refs/heads/feat <base_sha>` to `githooks/pre-push`:
  ```
  CASE 1 (fix eligible receipt): rc=0, invoked=False | pre-push: reusing the passing full-gate receipt for a0ca3468 (validate.sh, scope full) — the full gate already ran on this exact commit.
  ```
  `validate.sh` is **not** invoked (`invoked=False`) and `pre-push` exits `0`.

- **Base Red Control (`93f41cb8`):**
  With the identical receipt at `.xyz/receipts/<head_sha>.json`, `93f41cb8`'s `githooks/pre-push` ignores the receipt and runs the full `validate.sh` gate (`invoked=True`):
  ```
  CASE 2 (base red control): rc=0, invoked=True | pre-push: running the full gate before this push reaches the remote (GH-544).
  ```

## Case 2 — Producer (`validate.sh`) `--skip` exclusion vs unskipped `scope: full` receipt

- **On the fix (`validate.sh`):**
  - Running `bash validate.sh --sequential --skip s2.sh` on a clean fixture tree exits `0`, prints `QUARANTINED (GH-379): 1 suite(s) did NOT run — s2.sh`, and writes **no** receipt under `.xyz/receipts/<sha>.json` (`receipt_written=False`).
  - Running `bash validate.sh --sequential` (tier 3, no `--subsystem`, no `--skip`, no `XYZ_ENV_FAULTS`, clean tree) writes `.xyz/receipts/<sha>.json` with `"gate": "validate.sh"`, `"mode": "parallel"`, `"scope": "full"`, `"exit_code": 0`.
- **Base Red Control (`93f41cb8`):**
  - At `93f41cb8`, `bash validate.sh --sequential --skip s2.sh` writes `.xyz/receipts/<sha>.json` (`receipt_written=True`) despite skipping `s2.sh`.

## Case 3 — Adjacent negative cases (all fall through and invoke `validate.sh`)

Every non-eligible case declines reuse and runs the full gate (`rc=0, invoked=True`):
1. **Receipt without `scope` (old producer):** `check --require-full-gate` exits `1`; `pre-push` invokes `validate.sh`.
2. **`--skip` producer run:** no receipt exists on disk; `pre-push` invokes `validate.sh`.
3. **`mode: marathon` receipt whose `gate` is `"validate.sh"` (even with `scope: "full"`):** rejected because `mode == "marathon"`; `pre-push` invokes `validate.sh`.
4. **Receipt for another SHA (`base_sha` instead of `head_sha`):** no receipt for `head_sha`; `pre-push` invokes `validate.sh`.
5. **Second pushed ref without a receipt (`feat1` has `scope: full` receipt, `feat2` does not):** `_real_ref_pairs` requires **every** pushed local SHA to pass `check --require-full-gate`; `pre-push` invokes `validate.sh`.
6. **Empty stdin:** `_real_ref_pairs` has `0` entries; `pre-push` does not reuse any receipt and invokes `validate.sh`.
7. **Legacy `.gate-evidence/<sha>.txt` file:** plain `gate_receipt.py check` still exits `0` (preserving `marathon-closeout.sh` compatibility), while `check --require-full-gate` and `pre-push` refuse `.gate-evidence` and invoke `validate.sh`.

## Case 4 — Marathon writer (`utils/py/marathon_drive.py`) preservation & repair

Driving `marathon_drive._write_marathon_gate_receipt(repo, head_sha, "bash validate.sh --auto development", harness)`:
1. **Valid eligible `validate.sh` (`scope: full`) receipt pre-existing:** preserved untouched (`replaced=False`, `check_receipt(..., require_full_gate=True)` stays `True`, `mode == "parallel"`, `scope == "full"`). At base `93f41cb8` (red control), `marathon_drive.py` unconditionally overwrote it with `mode: "marathon"` and no `scope`.
2. **Corrupt pre-existing file (`{corrupt json`):** plain `check_receipt` is `False` before; `_write_marathon_gate_receipt` replaces it (`replaced=True`); plain `check_receipt` (used by `marathon-closeout.sh`) then passes (`True`, `mode == "marathon"`).
3. **Failed (`exit_code: 1`) pre-existing receipt:** plain `check_receipt` is `False` before; replaced (`replaced=True`); plain `check_receipt` then passes (`True`).
4. **Wrong-SHA (`sha: base_sha`) pre-existing receipt at `<head_sha>.json`:** plain `check_receipt` is `False` before; replaced (`replaced=True`); plain `check_receipt` then passes (`True`, `sha == head_sha`).
5. **Weaker pre-existing receipt (missing `scope: "full"`):** replaced (`replaced=True`) with the marathon receipt; plain `check_receipt` passes (`True`).

## Existing Suites in Disposable Full Clone

Executed in isolated disposable full clones under `$TMPDIR` (cloned from `/Users/noelsaw/marathon-clones/marathon-gh-1250-phase0-followups` with candidate `validate.sh`, `githooks/pre-push`, `utils/py/gate_receipt.py`, and `utils/py/marathon_drive.py` copied in and cleaned up on exit):

```
gh544-pre-push-gate: 103 pass, 0 fail
gh591-prepush-commit-boundary: {"first_push_receipt_in_tree": false, "second_push_receipt_in_tree": true, "result": "pass"}
gh509-gate-evidence: 19 passed, 0 failed
gh124-closeout-suite: ALL GH-124 SYNTHETIC CHECKS PASSED (6/6)
gh290-ate-variation-grid: 37 pass, 0 fail
marathon-closeout: 23 passed, 0 failed
gh291-contract-goldens: 20 pass, 0 fail
test_python_layer.py: 21 passed in 23.16s
```

## Verdict

PASS.
