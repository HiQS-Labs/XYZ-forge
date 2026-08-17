# GH-4 Negative Control

To verify the first-run check works, the `githooks/install.sh` hook was uninstalled, and `./validate.sh` was run.

**Output observed:**
```
validate.sh: WARNING — this clone is UNGATED (pre-push hook not installed).
validate.sh: The install step is a correctness requirement for pushing.
validate.sh: Fix: bash githooks/install.sh
```

This demonstrates that a fresh clone that has not run the installer produces a visible warning naming the missing gate and the one-command fix, while still allowing local evaluation without blocking execution.
