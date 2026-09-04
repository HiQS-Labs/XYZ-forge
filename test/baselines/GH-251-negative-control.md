# GH-251 negative control — pre-fix absent pytest behavior

Pre-fix `validate.sh` treated the non-zero exit code of `python3 -m pytest` as an unconditional test failure when `pytest` was not installed on the host:

```
===============================
Running python3 -m pytest test/test_python_layer.py
===============================
No module named pytest

Summary
===============================
telemetry: ...
passed: 154 / 155
failed:
  - python:test_python_layer.py
```

Post-fix `validate.sh` checks `python3 -c "import pytest"` prior to executing `pytest`, records the missing dependency as a named `SKIPPED` entry, and avoids false `FAILED` verdicts on developer machines without `pytest`.
