import sys
import os
import subprocess
import tempfile
import importlib.util
import pytest

# Ensure the 'utils' folder is accessible
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..', 'utils', 'py')))

REPO_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))

def load_module(module_name, relative_path):
    module_path = os.path.join(REPO_ROOT, relative_path)
    spec = importlib.util.spec_from_file_location(module_name, module_path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module

def test_rtl_module_load():
    import rtl
    assert rtl is not None

def test_poll_module_load():
    import poll
    assert poll is not None

def test_consult_module_load():
    import consult
    assert consult is not None

def test_marathon_drive_module_load():
    import marathon_drive
    assert marathon_drive is not None
    
def test_swarm_preflight_module_load():
    import swarm_preflight
    assert swarm_preflight is not None
    
def test_marathon_plan_module_load():
    import marathon_plan
    assert marathon_plan is not None

from unittest.mock import patch, MagicMock

def test_codex_turn_default_flags_match_bash_default():
    codex_turn = load_module("codex_turn_py", "utils/py/codex-turn.py")

    with patch.dict(os.environ, {}, clear=False):
        os.environ.pop("CODEX_FLAGS", None)
        assert codex_turn.default_codex_flags() == [
            "-s",
            "workspace-write",
            "-c",
            "approval_policy=never",
        ]

def test_marathon_drive_fails_before_tick_state_when_builder_binary_missing():
    import marathon_drive

    with tempfile.TemporaryDirectory() as tmpdir:
        phase_brief = os.path.join(tmpdir, "phase.md")
        with open(phase_brief, "w") as f:
            f.write("# brief\n")

        with patch.dict(
            os.environ,
            {
                "MARATHON_ROOT": tmpdir,
                "CODEX_BIN": "missing-codex",
            },
            clear=False,
        ), patch("shutil.which", side_effect=lambda name: None if name == "missing-codex" else "/bin/true"), \
             patch("subprocess.run") as run_mock, \
             patch("subprocess.check_output") as check_output_mock, \
             patch.object(
                 sys,
                 "argv",
                 [
                     "marathon_drive.py",
                     "--phase-brief",
                     phase_brief,
                     "--builder",
                     "codex",
                     "--reviewer",
                     "agy",
                 ],
             ):
            with pytest.raises(SystemExit) as excinfo:
                marathon_drive.main()
            assert excinfo.value.code == 2
            run_mock.assert_not_called()
            check_output_mock.assert_not_called()

def test_swarm_preflight_gh108_bundle_helpers():
    import swarm_preflight

    artifact = "utils/py/swarm_preflight.py"

    caveat = swarm_preflight.gate_scoping_caveat(
        "python3 -m pytest test/test_python_layer.py -- -k python_layer"
    )
    assert "Gate-scoping caveat (GH-108)" in caveat
    assert swarm_preflight.gate_scoping_caveat("python3 -m pytest test/test_python_layer.py -q") == ""

    assert swarm_preflight.is_genuine_ref(f'bash "{artifact}"', artifact)
    assert not swarm_preflight.is_genuine_ref(f"# mention {artifact} in a comment", artifact)

    assert swarm_preflight.is_fs_touching("echo hi > out.txt")
    assert not swarm_preflight.is_fs_touching("echo hi 2>&1")
    assert not swarm_preflight.is_fs_touching("status -> note")

def test_swarm_preflight_default_root_gh267():
    # GH-267: swarm_preflight.py lives one directory deeper (utils/py/) than its Bash
    # sibling (utils/), so its default-root computation needs an extra ".." to land on
    # the same anchor. This must hold WITHOUT SWARM_PREFLIGHT_ROOT set — the existing
    # test/swarm-preflight.sh suite always sets that override, so it never exercised
    # this path and the one-directory-too-shallow bug went uncaught.
    import swarm_preflight

    non_vendored = "/some/repo/utils/py/swarm_preflight.py"
    root, drive_cmd = swarm_preflight.compute_default_root(non_vendored)
    assert root == "/some/repo"
    assert drive_cmd == "relay-automation/marathon-drive.sh"

    vendored = "/some/target/.xyz/utils/py/swarm_preflight.py"
    root, drive_cmd = swarm_preflight.compute_default_root(vendored)
    assert root == "/some/target"
    assert drive_cmd == ".xyz/relay-automation/marathon-drive.sh"

def test_rtl_bridge_honors_containment_ignore_in_python_mode():
    import rtl

    relay = rtl.RelayTurnLib(REPO_ROOT, REPO_ROOT, os.path.join(REPO_ROOT, "phases/gh112b/RELAY.md"), "")
    res = relay._run_rtl(
        'CONTAINMENT_IGNORE=".codebase-memory"; '
        'if rtl_is_containment_ignored ".codebase-memory/cache.db"; then echo -n yes; else echo -n no; fi'
    )

    assert res.returncode == 0
    assert res.stdout == "yes"

def test_rtl_run_rtl_returns_code_without_exiting():
    # Contract (GH-112 Codex-review Blocker fix): _run_rtl must NOT sys.exit on a
    # non-zero shell status — callers (before/enforce/worktree_begin) need to inspect
    # the code to route containment (exit 6) and worktree-failure (exit 5) branches.
    import rtl

    r = rtl.RelayTurnLib("/fake/root", "/fake/xyz", "/fake/relay", "")

    mock_res = MagicMock()
    mock_res.returncode = 5

    with patch('subprocess.run', return_value=mock_res):
        res = r._run_rtl("some_cmd")   # must not raise
        assert res.returncode == 5


def test_rtl_run_checked_fails_fast():
    # The must-succeed derivation calls (artifact/prompt/drift) still fail fast, but
    # now explicitly at _run_checked — one layer up from the shared runner.
    import rtl

    r = rtl.RelayTurnLib("/fake/root", "/fake/xyz", "/fake/relay", "")

    mock_res = MagicMock()
    mock_res.returncode = 5

    with patch('subprocess.run', return_value=mock_res):
        with pytest.raises(SystemExit) as excinfo:
            r._run_checked("some_cmd")
        assert excinfo.value.code == 5
        
def test_poll_relay_field():
    import poll
    import tempfile
    
    with tempfile.NamedTemporaryFile("w", delete=False) as f:
        f.write("`**status**:  `ok`  \n")
        f.write("**NEXT**: `claimer` \n")
        f.flush()
        name = f.name
        
    try:
        assert poll.relay_field(name, "status") == "ok"
        assert poll.relay_field(name, "NEXT") == "claimer"
    finally:
        os.remove(name)

def test_swarm_preflight_sanitizes_inferred_paths_gh137():
    # Python-parity regression for the independent Codex review Blocker (GH-146 follow-up,
    # relay-system/2026-07-05/gh112-134-parity-codex-review.md): the Bash swarm-preflight.sh
    # gates every INFERRED test/helper through sanitizeInferredPath (GH-137) before it can
    # widen ALLOW_PATHS; the initial Python port only checked `.startswith("test/")`, which a
    # `test/../...` string or a __pycache__/*.pyc path defeats. Mirrors
    # test/swarm-preflight.sh's T35b fixture: a real sibling covering test + helper still land,
    # a `test/..` escape and a generated .pyc do not.
    import swarm_preflight

    with tempfile.TemporaryDirectory() as tmpdir:
        os.makedirs(os.path.join(tmpdir, "relay-automation"))
        os.makedirs(os.path.join(tmpdir, "test", "__pycache__"))

        artifact = "relay-automation/consult.sh"
        with open(os.path.join(tmpdir, artifact), "w") as f:
            f.write("#!/usr/bin/env bash\n")

        with open(os.path.join(tmpdir, "test", "_setup.sh"), "w") as f:
            f.write("# helper\n")

        with open(os.path.join(tmpdir, "test", "__pycache__", "generated.pyc"), "w") as f:
            f.write("compiled\n")

        # The real covering test: genuinely references the declared artifact + a helper.
        with open(os.path.join(tmpdir, "test", "consult.sh"), "w") as f:
            f.write(
                '#!/usr/bin/env bash\n'
                'source "$(dirname "$0")/_setup.sh"\n'
                'CONSULT="$(cd "$(dirname "$0")/.." && pwd)/relay-automation/consult.sh"\n'
            )

        contract = {"artifacts": [artifact]}
        result = swarm_preflight.expand_effective_artifacts(tmpdir, contract)

        all_paths = result["artifacts"] + result["inferred_tests"] + result["inferred_helpers"]
        assert not any(".." in p.split("/") for p in all_paths), all_paths
        assert not any("__pycache__" in p or p.endswith(".pyc") for p in all_paths), all_paths
        assert "test/consult.sh" in result["inferred_tests"]
        assert "test/_setup.sh" in result["inferred_helpers"]

def test_swarm_preflight_sanitize_inferred_path_rejects_traversal_and_generated():
    import swarm_preflight

    root = REPO_ROOT
    test_root = os.path.join(root, "test")

    # A genuine in-repo test path passes through normalized.
    assert swarm_preflight.sanitize_inferred_path(root, test_root, "test/test_python_layer.py") \
        == "test/test_python_layer.py"
    # String-prefix bypass that a naive `.startswith("test/")` check would accept.
    assert swarm_preflight.sanitize_inferred_path(root, test_root, "test/../src/project.js") is None
    assert swarm_preflight.sanitize_inferred_path(root, test_root, "test/../../etc/passwd") is None
    # Generated/gitignored entries never widen ALLOW_PATHS.
    assert swarm_preflight.sanitize_inferred_path(root, test_root, "test/__pycache__/x.pyc") is None
    assert swarm_preflight.sanitize_inferred_path(root, test_root, "test/sub/mod.pyc") is None
    # Not under test/ at all.
    assert swarm_preflight.sanitize_inferred_path(root, test_root, "src/project.js") is None
