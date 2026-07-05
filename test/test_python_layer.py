import sys
import os
import subprocess
import pytest

# Ensure the 'utils' folder is accessible
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..', 'utils', 'py')))

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

def test_rtl_returncode_check():
    import rtl
    import sys
    
    r = rtl.RelayTurnLib("/fake/root", "/fake/xyz", "/fake/relay", "")
    
    # Mock subprocess.run to return a non-zero exit code
    mock_res = MagicMock()
    mock_res.returncode = 5
    
    with patch('subprocess.run', return_value=mock_res) as mock_run:
        with pytest.raises(SystemExit) as excinfo:
            r._run_rtl("some_cmd")
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

