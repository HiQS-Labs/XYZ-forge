# GH-1236 manual smoke: pre-push reuses a passing full-gate receipt for the exact pushed commit

- **Date:** 2026-10-29
- **Platform:** macOS (Darwin arm64), Bash 3.2, Python 3
- **Base commit:** `93f41cb8409068182f85dbc9352b2ab909427b7f` (`development`), worktree HEAD `5f3f8a8b5fb3f50470787ec2748da8004f78a1e4`
- **Target surface:** `validate.sh`, `githooks/pre-push`, `utils/py/gate_receipt.py`, `utils/py/marathon_drive.py`
  - Candidate `validate.sh` SHA-256: `46a8f5c24eabe13006ec75476d726d19e60681e261dab3795bc74e5becc90b24` (base `93f41cb8`: `5bc9e473af296edb9029aedef8b4fbd0a281b3e7545803d055f5ac895a207220`)
  - Candidate `githooks/pre-push` SHA-256: `bd6009eaad974a6552f9fe6c9edfddab31a1a531f4d3f02e9e98e8dc70da13db` (base `93f41cb8`: `29edf96df79282e39f497d89f222c30ad27e71eea35ecf88dfe5baee4d474268`)
  - Candidate `utils/py/gate_receipt.py` SHA-256: `06f8ca103c9417475132f6fb39634bb6e8da9dd113b22380eb78142223de6644` (base `93f41cb8`: `adbb53e13c663cf243aac94ca8f47a3edb4ddda8f638654404a63319f6d3badb`)
  - Candidate `utils/py/marathon_drive.py` SHA-256: `cff5511d68be2b7d31bb4b1c7c4f0deda4f547d1c8b22fd7726cea8e0629d1b0` (base `93f41cb8`: `8233aded9cd3b4b88937625229a6df859b527572fe73c9943d3bc024008cad54`)
- **No new test suite added** (GH-831).

## Self-Contained Reproducible Manual Recipe

Run from a disposable full clone root (uses `tempfile.TemporaryDirectory()` under `$TMPDIR` and performs zero writes inside the repository):
- **Candidate verification (`rc=0`):**
  ```sh
  PYTHONDONTWRITEBYTECODE=1 python3 -c 'import pathlib; code = pathlib.Path("TESTS-RESULTS/2026-10-29+GH-1236/smoke.md").read_text().split("```python\n", 1)[1].split("```", 1)[0]; exec(compile(code, "smoke.md", "exec"))'
  ```
- **Base red control (`93f41cb8`, `rc=1` with `AssertionError` on the 4 target assertions):**
  ```sh
  PYTHONDONTWRITEBYTECODE=1 python3 -c 'import pathlib; code = pathlib.Path("TESTS-RESULTS/2026-10-29+GH-1236/smoke.md").read_text().split("```python\n", 1)[1].split("```", 1)[0]; exec(compile(code, "smoke.md", "exec"))' --base
  ```

```python
import importlib.util, json, os, re, shutil, stat, subprocess, sys, tempfile, textwrap
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

def write_json_receipt(root: Path, sha: str, payload: dict):
    rdir = root / ".xyz/receipts"
    rdir.mkdir(parents=True, exist_ok=True)
    (rdir / f"{sha}.json").write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")

def setup_producer_fixture(root: Path, use_base: bool = False):
    root.mkdir(parents=True, exist_ok=True)
    subprocess.run(["git", "-C", str(root), "init", "-q"], check=True)
    subprocess.run(["git", "-C", str(root), "config", "user.email", "t@example.invalid"], check=True)
    subprocess.run(["git", "-C", str(root), "config", "user.name", "Tester"], check=True)
    shutil.copy2(WT / ".gitignore", root / ".gitignore")
    for d in ("test/lib", "test/fixtures/gamma-poison", "utils/py", "relay-automation", "githooks"):
        (root / d).mkdir(parents=True, exist_ok=True)
    for p in (WT / "test/lib").glob("*.sh"):
        shutil.copy2(p, root / "test/lib" / p.name)
    for rel in (
        "relay-automation/gate-env.sh",
        "utils/py/gate_env.py",
        "utils/ci-route.sh",
        "githooks/install.sh",
    ):
        if (WT / rel).exists():
            shutil.copy2(WT / rel, root / rel)
    val_bytes = git_show(f"{BASE_COMMIT}:validate.sh") if use_base else (WT / "validate.sh").read_bytes()
    gr_bytes = git_show(f"{BASE_COMMIT}:utils/py/gate_receipt.py") if use_base else (WT / "utils/py/gate_receipt.py").read_bytes()
    val_text = val_bytes.decode("utf-8")
    val_text = re.sub(
        r"TESTS=\(\n.*?\n\)",
        'TESTS=(\n  "s1.sh"\n  "s2.sh"\n)',
        val_text,
        count=1,
        flags=re.S,
    )
    (root / "validate.sh").write_text(val_text, encoding="utf-8")
    (root / "validate.sh").chmod(0o755)
    (root / "utils/py/gate_receipt.py").write_bytes(gr_bytes)
    (root / "utils/py/gate_receipt.py").chmod(0o755)
    for name in ("s1.sh", "s2.sh"):
        p = root / "test" / name
        p.write_text("#!/usr/bin/env bash\nexit 0\n", encoding="utf-8")
        p.chmod(0o755)
    (root / "test/test_python_layer.py").write_text("def test_ok():\n    assert True\n", encoding="utf-8")
    (root / "poison_target.txt").write_text("clean\n", encoding="utf-8")
    (root / "test/fixtures/gamma-poison/poison.patch").write_text(
        "--- a/poison_target.txt\n+++ b/poison_target.txt\n@@ -1 +1 @@\n-clean\n+poisoned\n",
        encoding="utf-8",
    )
    subprocess.run(["git", "-C", str(root), "add", "-A"], check=True)
    subprocess.run(["git", "-C", str(root), "commit", "-qm", "producer-fixture"], check=True)
    return subprocess.check_output(["git", "-C", str(root), "rev-parse", "HEAD"], text=True).strip()

def load_module(name: str, path: Path):
    spec = importlib.util.spec_from_file_location(name, str(path))
    mod = importlib.util.module_from_spec(spec)
    sys.modules[name] = mod
    spec.loader.exec_module(mod)
    return mod

def invoke_marathon_receipt_writer(md_mod, md_path: Path, repo: Path, head_sha: str, cmd: str, harness: Path):
    if hasattr(md_mod, "_write_marathon_gate_receipt"):
        return md_mod._write_marathon_gate_receipt(str(repo), head_sha, cmd, str(harness))
    # Base 93f41cb8 had the receipt writer inlined in marathon_drive.py around line 2820
    src = md_path.read_text(encoding="utf-8")
    m = re.search(
        r"([ ]{8}if head_sha and not historical:\n(?:[ ]{12}.*\n)+?[ ]{12}except Exception:\n[ ]{16}pass\n)",
        src,
    )
    assert m, "could not locate inline marathon receipt writer in base marathon_drive.py"
    block = textwrap.dedent(m.group(1))
    ns = {
        "os": os,
        "subprocess": subprocess,
        "root": str(repo),
        "head_sha": head_sha,
        "historical": False,
        "xyz_harness": str(harness),
        "pre_advance_cmd": cmd,
    }
    exec(block, ns)
    return True

def run_suite(use_base: bool = False):
    failures = []
    def check(cond: bool, label: str, detail: str):
        try:
            assert cond, f"{label}: {detail}"
            print(f"[PASS] {label}: {detail}")
        except AssertionError as exc:
            print(f"[FAIL] {label}: {detail}")
            failures.append(str(exc))

    with tempfile.TemporaryDirectory(prefix="gh1236-smoke-") as td:
        tmp = Path(td)

        # Case 1: pre-push reuse of eligible scope=full receipt
        repo1 = tmp / "case1"
        base_sha, head_sha = setup_fixture_repo(repo1, use_base=use_base)
        write_json_receipt(repo1, head_sha, {
            "sha": head_sha,
            "gate": "validate.sh",
            "mode": "parallel",
            "scope": "full",
            "exit_code": 0,
            "passed": 10,
            "total": 10,
            "duration_s": 1,
            "timestamp": "2026-10-29T00:00:00Z",
        })
        ref_line = f"refs/heads/feat {head_sha} refs/heads/feat {base_sha}\n"
        rc, out, invoked = drive_prepush(repo1, ref_line)
        expected_msg = f"pre-push: reusing the passing full-gate receipt for {head_sha[:8]} (validate.sh, scope full) — the full gate already ran on this exact commit."
        check(
            rc == 0 and not invoked and expected_msg in out,
            "case1-prepush-reuse-eligible-receipt",
            f"rc={rc}, invoked={invoked}, out={out.splitlines()[0] if out else ''}",
        )

        # Case 2: producer (validate.sh) --skip exclusion vs unskipped scope=full write
        repo2 = tmp / "case2"
        p_sha = setup_producer_fixture(repo2, use_base=use_base)
        r_file = repo2 / ".xyz/receipts" / f"{p_sha}.json"
        r_file.unlink(missing_ok=True)
        env = os.environ.copy()
        env["PYTHONDONTWRITEBYTECODE"] = "1"
        env.pop("XYZ_ENV_FAULTS", None)
        p_skip = subprocess.run(
            ["bash", "validate.sh", "--sequential", "--skip", "s2.sh"],
            cwd=str(repo2), text=True, capture_output=True, env=env,
        )
        skip_wrote = r_file.exists()
        check(
            p_skip.returncode == 0 and not skip_wrote,
            "case2a-producer-skip-writes-no-receipt",
            f"rc={p_skip.returncode}, receipt_written={skip_wrote}",
        )
        r_file.unlink(missing_ok=True)
        p_full = subprocess.run(
            ["bash", "validate.sh", "--sequential"],
            cwd=str(repo2), text=True, capture_output=True, env=env,
        )
        full_data = json.loads(r_file.read_text(encoding="utf-8")) if r_file.exists() else {}
        check(
            p_full.returncode == 0 and full_data.get("scope") == "full" and full_data.get("gate") == "validate.sh" and full_data.get("exit_code") == 0,
            "case2b-producer-unskipped-writes-scope-full",
            f"rc={p_full.returncode}, scope={full_data.get('scope')}, gate={full_data.get('gate')}, exit_code={full_data.get('exit_code')}",
        )

        # Case 3: 7 adjacent negative cases (candidate assertions)
        if not use_base:
            # 3a: receipt without scope
            write_json_receipt(repo1, head_sha, {"sha": head_sha, "gate": "validate.sh", "mode": "parallel", "exit_code": 0})
            rc, _, inv = drive_prepush(repo1, ref_line)
            check(rc == 0 and inv, "case3a-no-scope-invokes-gate", f"rc={rc}, invoked={inv}")

            # 3b: --skip producer run (no receipt file)
            (repo1 / ".xyz/receipts" / f"{head_sha}.json").unlink(missing_ok=True)
            rc, _, inv = drive_prepush(repo1, ref_line)
            check(rc == 0 and inv, "case3b-skip-no-receipt-invokes-gate", f"rc={rc}, invoked={inv}")

            # 3c: mode=marathon with gate=validate.sh and scope=full
            write_json_receipt(repo1, head_sha, {"sha": head_sha, "gate": "validate.sh", "mode": "marathon", "scope": "full", "exit_code": 0})
            rc, _, inv = drive_prepush(repo1, ref_line)
            check(rc == 0 and inv, "case3c-mode-marathon-invokes-gate", f"rc={rc}, invoked={inv}")

            # 3d: receipt for another SHA (base_sha only)
            (repo1 / ".xyz/receipts" / f"{head_sha}.json").unlink(missing_ok=True)
            write_json_receipt(repo1, base_sha, {"sha": base_sha, "gate": "validate.sh", "mode": "parallel", "scope": "full", "exit_code": 0})
            rc, _, inv = drive_prepush(repo1, ref_line)
            check(rc == 0 and inv, "case3d-other-sha-invokes-gate", f"rc={rc}, invoked={inv}")

            # 3e: second pushed ref without a receipt
            write_json_receipt(repo1, head_sha, {"sha": head_sha, "gate": "validate.sh", "mode": "parallel", "scope": "full", "exit_code": 0})
            (repo1 / ".xyz/receipts" / f"{base_sha}.json").unlink(missing_ok=True)
            two_refs = f"refs/heads/feat1 {head_sha} refs/heads/feat1 {base_sha}\nrefs/heads/feat2 {base_sha} refs/heads/feat2 {'0'*40}\n"
            rc, _, inv = drive_prepush(repo1, two_refs)
            check(rc == 0 and inv, "case3e-second-ref-unreceipted-invokes-gate", f"rc={rc}, invoked={inv}")

            # 3f: empty stdin
            rc, _, inv = drive_prepush(repo1, "")
            check(rc == 0 and inv, "case3f-empty-stdin-invokes-gate", f"rc={rc}, invoked={inv}")

            # 3g: legacy .gate-evidence/<sha>.txt
            (repo1 / ".xyz/receipts" / f"{head_sha}.json").unlink(missing_ok=True)
            ge = repo1 / ".gate-evidence"
            ge.mkdir(parents=True, exist_ok=True)
            (ge / f"{head_sha}.txt").write_text(f"commit: {head_sha}\nresult: green\n", encoding="utf-8")
            plain_rc = subprocess.run([sys.executable, str(repo1 / "utils/py/gate_receipt.py"), "check", "--repo", str(repo1), "--sha", head_sha], capture_output=True).returncode
            full_rc = subprocess.run([sys.executable, str(repo1 / "utils/py/gate_receipt.py"), "check", "--repo", str(repo1), "--sha", head_sha, "--require-full-gate"], capture_output=True).returncode
            rc, _, inv = drive_prepush(repo1, ref_line)
            check(plain_rc == 0 and full_rc == 1 and rc == 0 and inv, "case3g-legacy-gate-evidence-invokes-gate", f"plain_rc={plain_rc}, full_rc={full_rc}, invoked={inv}")

        # Case 4: Marathon writer (_write_marathon_gate_receipt) preservation & repair
        repo4 = tmp / "case4"
        b4, h4 = setup_fixture_repo(repo4, use_base=use_base)
        md_dir = tmp / "py_mod"
        md_dir.mkdir(parents=True, exist_ok=True)
        for p in (WT / "utils/py").glob("*.py"):
            shutil.copy2(p, md_dir / p.name)
        if use_base:
            (md_dir / "gate_receipt.py").write_bytes(git_show(f"{BASE_COMMIT}:utils/py/gate_receipt.py"))
            (md_dir / "marathon_drive.py").write_bytes(git_show(f"{BASE_COMMIT}:utils/py/marathon_drive.py"))
        sys.path.insert(0, str(md_dir))
        gr_mod = load_module("gate_receipt", md_dir / "gate_receipt.py")
        md_mod = load_module("marathon_drive", md_dir / "marathon_drive.py")

        # 4a: eligible validate.sh scope=full receipt is preserved
        write_json_receipt(repo4, h4, {"sha": h4, "gate": "validate.sh", "mode": "parallel", "scope": "full", "exit_code": 0})
        replaced_4a = invoke_marathon_receipt_writer(md_mod, md_dir / "marathon_drive.py", repo4, h4, "bash validate.sh --auto development", repo4)
        after_4a = json.loads((repo4 / ".xyz/receipts" / f"{h4}.json").read_text(encoding="utf-8"))
        check(
            not replaced_4a and after_4a.get("mode") == "parallel" and after_4a.get("scope") == "full" and getattr(gr_mod, "is_full_gate_receipt", lambda d, s: False)(after_4a, h4),
            "case4a-marathon-preserves-eligible-receipt",
            f"replaced={replaced_4a}, mode={after_4a.get('mode')}, scope={after_4a.get('scope')}",
        )

        if not use_base:
            # 4b: corrupt file replaced and plain check_receipt passes
            rpath = repo4 / ".xyz/receipts" / f"{h4}.json"
            rpath.write_text("{corrupt json", encoding="utf-8")
            before_ok, _ = gr_mod.check_receipt(str(repo4), h4)
            replaced_4b = invoke_marathon_receipt_writer(md_mod, md_dir / "marathon_drive.py", repo4, h4, "bash validate.sh --auto development", repo4)
            after_ok, after_data = gr_mod.check_receipt(str(repo4), h4)
            check(not before_ok and replaced_4b and after_ok and after_data.get("mode") == "marathon", "case4b-marathon-repairs-corrupt-receipt", f"before={before_ok}, replaced={replaced_4b}, after={after_ok}, mode={after_data.get('mode')}")

            # 4c: failed (exit_code=1) receipt replaced
            write_json_receipt(repo4, h4, {"sha": h4, "gate": "validate.sh", "mode": "parallel", "scope": "full", "exit_code": 1})
            before_ok, _ = gr_mod.check_receipt(str(repo4), h4)
            replaced_4c = invoke_marathon_receipt_writer(md_mod, md_dir / "marathon_drive.py", repo4, h4, "bash validate.sh --auto development", repo4)
            after_ok, after_data = gr_mod.check_receipt(str(repo4), h4)
            check(not before_ok and replaced_4c and after_ok and after_data.get("exit_code") == 0, "case4c-marathon-repairs-failed-receipt", f"before={before_ok}, replaced={replaced_4c}, after={after_ok}")

            # 4d: wrong-SHA receipt replaced
            write_json_receipt(repo4, h4, {"sha": b4, "gate": "validate.sh", "mode": "parallel", "scope": "full", "exit_code": 0})
            before_ok, _ = gr_mod.check_receipt(str(repo4), h4)
            replaced_4d = invoke_marathon_receipt_writer(md_mod, md_dir / "marathon_drive.py", repo4, h4, "bash validate.sh --auto development", repo4)
            after_ok, after_data = gr_mod.check_receipt(str(repo4), h4)
            check(not before_ok and replaced_4d and after_ok and after_data.get("sha") == h4, "case4d-marathon-repairs-wrong-sha-receipt", f"before={before_ok}, replaced={replaced_4d}, after={after_ok}, sha_match={after_data.get('sha') == h4}")

            # 4e: weaker receipt (missing scope=full) replaced
            write_json_receipt(repo4, h4, {"sha": h4, "gate": "validate.sh", "mode": "parallel", "exit_code": 0})
            replaced_4e = invoke_marathon_receipt_writer(md_mod, md_dir / "marathon_drive.py", repo4, h4, "bash validate.sh --auto development", repo4)
            after_ok, after_data = gr_mod.check_receipt(str(repo4), h4)
            check(replaced_4e and after_ok and after_data.get("mode") == "marathon", "case4e-marathon-replaces-weaker-receipt", f"replaced={replaced_4e}, after={after_ok}, mode={after_data.get('mode')}")

    assert not failures, f"{len(failures)} assertion(s) failed: " + "; ".join(failures)

run_suite(use_base=("--base" in sys.argv))
```

## Decisive Output (Candidate vs Base Red Control)

### Candidate run (`rc=0`)
```text
[PASS] case1-prepush-reuse-eligible-receipt: rc=0, invoked=False, out=pre-push: reusing the passing full-gate receipt for cb838b4e (validate.sh, scope full) — the full gate already ran on this exact commit.
[PASS] case2a-producer-skip-writes-no-receipt: rc=0, receipt_written=False
[PASS] case2b-producer-unskipped-writes-scope-full: rc=0, scope=full, gate=validate.sh, exit_code=0
[PASS] case3a-no-scope-invokes-gate: rc=0, invoked=True
[PASS] case3b-skip-no-receipt-invokes-gate: rc=0, invoked=True
[PASS] case3c-mode-marathon-invokes-gate: rc=0, invoked=True
[PASS] case3d-other-sha-invokes-gate: rc=0, invoked=True
[PASS] case3e-second-ref-unreceipted-invokes-gate: rc=0, invoked=True
[PASS] case3f-empty-stdin-invokes-gate: rc=0, invoked=True
[PASS] case3g-legacy-gate-evidence-invokes-gate: plain_rc=0, full_rc=1, invoked=True
[PASS] case4a-marathon-preserves-eligible-receipt: replaced=False, mode=parallel, scope=full
[PASS] case4b-marathon-repairs-corrupt-receipt: before=False, replaced=True, after=True, mode=marathon
[PASS] case4c-marathon-repairs-failed-receipt: before=False, replaced=True, after=True
[PASS] case4d-marathon-repairs-wrong-sha-receipt: before=False, replaced=True, after=True, sha_match=True
[PASS] case4e-marathon-replaces-weaker-receipt: replaced=True, after=True, mode=marathon
```

### Base red control (`--base` at `93f41cb8`, `rc=1` — target assertions fail on base)
```text
[FAIL] case1-prepush-reuse-eligible-receipt: rc=0, invoked=True, out=pre-push: running the full gate before this push reaches the remote (GH-544).
[FAIL] case2a-producer-skip-writes-no-receipt: rc=0, receipt_written=True
[FAIL] case2b-producer-unskipped-writes-scope-full: rc=0, scope=None, gate=validate.sh, exit_code=0
[FAIL] case4a-marathon-preserves-eligible-receipt: replaced=True, mode=marathon, scope=None
AssertionError: 4 assertion(s) failed: case1-prepush-reuse-eligible-receipt: rc=0, invoked=True, out=pre-push: running the full gate before this push reaches the remote (GH-544).; case2a-producer-skip-writes-no-receipt: rc=0, receipt_written=True; case2b-producer-unskipped-writes-scope-full: rc=0, scope=None, gate=validate.sh, exit_code=0; case4a-marathon-preserves-eligible-receipt: replaced=True, mode=marathon, scope=None
```

## Case Breakdown

1. **Case 1 — Fix & Base Red Control (`pre-push` reuse of eligible `scope: full` receipt):**
   - **Candidate:** with `.xyz/receipts/<head_sha>.json` (`gate: "validate.sh"`, `mode: "parallel"`, `scope: "full"`, `exit_code: 0`), `githooks/pre-push` prints `pre-push: reusing the passing full-gate receipt for <sha8> (validate.sh, scope full) — the full gate already ran on this exact commit.` and exits `0` with `invoked=False`.
   - **Base red control (`93f41cb8`):** `githooks/pre-push` ignores the receipt and runs `validate.sh` (`invoked=True`), failing the assertion.
2. **Case 2 — Producer (`validate.sh`) `--skip` exclusion vs unskipped `scope: full` receipt:**
   - **Candidate:** `bash validate.sh --sequential --skip s2.sh` writes no receipt (`receipt_written=False`), while `bash validate.sh --sequential` writes `.xyz/receipts/<sha>.json` with `scope: "full"`.
   - **Base red control (`93f41cb8`):** `bash validate.sh --sequential --skip s2.sh` writes `.xyz/receipts/<sha>.json` (`receipt_written=True`) and unskipped `validate.sh` omits `scope`, failing both assertions.
3. **Case 3 — Adjacent negative cases (all 7 invoke `validate.sh`, `invoked=True`):**
   - `3a`: receipt without `scope` (old producer);
   - `3b`: `--skip` producer run (no receipt written);
   - `3c`: `mode: "marathon"` receipt whose `gate` is `"validate.sh"` and `scope` is `"full"`;
   - `3d`: receipt for another SHA (`base_sha` instead of `head_sha`);
   - `3e`: second pushed ref without a receipt;
   - `3f`: empty stdin;
   - `3g`: legacy `.gate-evidence/<sha>.txt` file (`plain_rc=0` for closeout compatibility, `full_rc=1` under `--require-full-gate`, `invoked=True` in `pre-push`).
4. **Case 4 — Marathon writer (`utils/py/marathon_drive.py`) preservation & repair:**
   - **Candidate:** `4a` preserves an eligible `validate.sh` (`scope: "full"`) receipt (`replaced=False`, `mode="parallel"`, `scope="full"`); `4b`–`4e` replace corrupt, failed (`exit_code: 1`), wrong-SHA, and weaker (no `scope`) pre-existing files so `check_receipt` passes (`after=True`, `mode="marathon"`).
   - **Base red control (`93f41cb8`):** inline marathon writer unconditionally overwrites the eligible `scope: "full"` receipt (`replaced=True, mode=marathon, scope=None`), failing `case4a`.

## Existing Suites in Disposable Full Clone

Executed in isolated disposable full clones under `$TMPDIR` (cloned from `/Users/noelsaw/marathon-clones/marathon-gh-1250-phase0-followups` with candidate `validate.sh`, `githooks/pre-push`, `utils/py/gate_receipt.py`, and `utils/py/marathon_drive.py` copied in and cleaned up on exit):

```text
gh544-pre-push-gate: 103 pass, 0 fail
gh591-prepush-commit-boundary: {"first_push_receipt_in_tree": false, "second_push_receipt_in_tree": true, "result": "pass"}
gh509-gate-evidence: 19 passed, 0 failed
gh124-closeout-suite: ALL GH-124 SYNTHETIC CHECKS PASSED (6/6)
gh290-ate-variation-grid: 37 pass, 0 fail
gh280-jog-marathon-adapter: 223 pass, 0 fail
marathon-closeout: 23 passed, 0 failed
gh291-contract-goldens: 20 pass, 0 fail
test_python_layer.py: 21 passed in 23.16s
```

## Verdict

PASS.

## Orchestrator addendum — post-approval fix (2026-10-29)

The branch's pre-push gate failed `test/gh371-interrupt-snapshot.sh` and `test/gh372-escalation-log-tail.sh`, and both failures reproduced alone, with `ModuleNotFoundError: gate_receipt`. p4's module-level import broke fixtures that copy a subset of `utils/py`.

Final shape after post-fix QA r1 and r2:
- `_write_marathon_gate_receipt` loads `gate_receipt.py` lazily from the **resolved harness writer path** and judges eligibility with that same module.
- If the writer cannot judge (it predates the predicate, or fails to load), it never downgrades a passing receipt for the SHA. Absent, corrupt, failed and wrong-SHA files are still replaced.

Results:
- gh371 2/0, gh372 3/0, gh280 223/0.
- The recipe above reruns with rc=0 (15 PASS, 0 FAIL).
- Split-harness control (rc=0): the AST-extracted function, with the local `import gate_receipt` forced to fail. The external harness is either the current writer or an "old" copy with the predicate removed.

```
[PASS] split-harness (current writer; local gate_receipt missing) — eligible scope=full: replaced=False mode=parallel scope=full
[PASS] split-harness (current writer; local gate_receipt missing) — weaker (no scope): replaced=True mode=marathon scope=None
[PASS] split-harness (old writer, no predicate; local gate_receipt missing) — eligible scope=full: replaced=False mode=parallel scope=full
[PASS] split-harness (old writer, no predicate; local gate_receipt missing) — corrupt JSON: replaced=True mode=marathon scope=None
[PASS] split-harness (old writer, no predicate; local gate_receipt missing) — failed exit_code=1: replaced=True mode=marathon scope=None
```
