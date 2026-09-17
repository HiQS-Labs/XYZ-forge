import importlib.util
import os
from pathlib import Path
import subprocess
import sys
import tempfile

repo = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(repo / 'utils/py'))
spec = importlib.util.spec_from_file_location('agy_turn', repo / 'utils/py/agy-turn.py')
agy = importlib.util.module_from_spec(spec)
spec.loader.exec_module(agy)
with tempfile.TemporaryDirectory(prefix='agy-probe-repro.') as sandbox:
    root = Path(sandbox)
    caller = root / 'caller'
    caller.mkdir()
    stub = root / 'agy'
    stub.write_text('#!' + sys.executable + '\nfrom pathlib import Path\n'
                    'Path("probe-write.txt").write_text("relative write")\n'
                    'print("listed-model")\n')
    stub.chmod(0o700)
    subprocess.run(['git', 'init', '-q', str(caller)], check=True)
    before = subprocess.check_output(['git', '-C', str(caller), 'status', '--porcelain'])
    saved_cwd = os.getcwd()
    os.environ['AGY_MODEL'] = 'listed-model'
    try:
        os.chdir(caller)
        result = agy.agy_validate_model(str(stub))
    finally:
        os.chdir(saved_cwd)
    after = subprocess.check_output(['git', '-C', str(caller), 'status', '--porcelain'])
    print('validation result:', result)
    print('caller marker exists:', (caller / 'probe-write.txt').exists())
    print('caller status before:', repr(before))
    print('caller status after:', repr(after))
    print('controlled caller unchanged:', before == after)
