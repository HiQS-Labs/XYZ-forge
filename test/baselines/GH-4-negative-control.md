# GH-4 Negative Control

To verify the first-run check works, the hook was uninstalled, and `bash githooks/install.sh --check` was run.

**Output observed:**
```
$ bash githooks/install.sh --check
githooks: NOT INSTALLED in this clone.
  /Users/.../.git/hooks/pre-push does not exist.
  This clone will push WITHOUT running the gate. Fix: bash githooks/install.sh
  (The pre-push hook is a correctness requirement for this repository.)
```
**Exit Status**: 1

This demonstrates that checking an ungated clone surfaces a visible warning and non-zero exit status, explicitly naming the missing gate and the one-command fix. The check was kept exclusively in `githooks/install.sh` to respect the boundary forbidding changes to `validate.sh`.
