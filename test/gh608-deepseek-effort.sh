#!/usr/bin/env bash
# GH-608: verify DEEPSEEK_REASONING_EFFORT matrix, early claim prevention, and telemetry normalization
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export PYTHONPATH="$ROOT/utils/py:${PYTHONPATH:-}"
export REPO_ROOT="$ROOT"

python3 -B - <<'PY'
import importlib.util
import os
import pathlib
import sys
import unittest
from unittest.mock import patch, MagicMock

ROOT = pathlib.Path(os.environ['REPO_ROOT']).resolve()
sys.path.insert(0, str(ROOT / 'utils/py'))
spec = importlib.util.spec_from_file_location('shim', ROOT / 'utils/py/deepseek-turn.py')
shim = importlib.util.module_from_spec(spec)
spec.loader.exec_module(shim)

class EffortTests(unittest.TestCase):
    def overlay(self, value):
        with patch.dict(os.environ, {}, clear=True):
            if value is not None:
                os.environ['DEEPSEEK_REASONING_EFFORT'] = value
            name = shim.generate_patch_overlay('alibaba', 'qwen3.8-max', 'ALIBABA_TOKEN_PLAN_API_KEY')
            try:
                return pathlib.Path(name).read_text()
            finally:
                if os.path.exists(name):
                    os.unlink(name)

    def test_matrix(self):
        for value, expected in [(None, 'high'), ('off', 'off'), ('low', 'low'), ('high', 'high'), ('max', 'max')]:
            with self.subTest(value=value):
                text = self.overlay(value)
                self.assertIn('reasoningEffort: ' + expected, text)
                self.assertIn('thinking: ' + ('disabled' if expected == 'off' else 'enabled'), text)
                self.assertIn('model: qwen3.8-max', text)
                self.assertIn('apiKeyEnv: ALIBABA_TOKEN_PLAN_API_KEY', text)

    def test_invalid_before_claim(self):
        env = {
            'RELAY_AGENT': 'deepseek',
            'DEEPSEEK_AGENT': 'deepseek',
            'RELAY_FILE': 'unused.md',
            'DEEPSEEK_REASONING_EFFORT': 'medium',
            'DEEPSEEK_PROVIDER': 'alibaba',
        }
        with patch.dict(os.environ, env, clear=True), \
             patch.object(shim, 'claim_task_or_exit') as claim, \
             patch.object(sys, 'argv', ['shim']):
            with self.assertRaises(SystemExit) as result:
                shim.main()
            self.assertEqual(result.exception.code, 2)
            claim.assert_not_called()

    def test_invalid_overlay(self):
        for value in ['', 'medium', 'off\nbaseURL: invalid']:
            with self.subTest(value=value), self.assertRaises(SystemExit):
                self.overlay(value)

    def test_telemetry_vocabulary(self):
        import ast
        tree = ast.parse((ROOT / 'utils/py/deepseek-turn.py').read_text())
        call = next(
            n for n in ast.walk(tree)
            if isinstance(n, ast.Call)
            and isinstance(n.func, ast.Name)
            and n.func.id == 'HarnessTurnLogger'
        )
        value = next(k.value for k in call.keywords if k.arg == 'reasoning_effort')
        expression = compile(ast.Expression(value), '<logger effort>', 'eval')
        for effort in ['off', 'low', 'high', 'max']:
            expected = 'none' if effort == 'off' else effort
            self.assertEqual(eval(expression, {'reasoning_effort': effort}), expected)

if __name__ == '__main__':
    unittest.main()
PY
echo "gh608-deepseek-effort: PASS"
