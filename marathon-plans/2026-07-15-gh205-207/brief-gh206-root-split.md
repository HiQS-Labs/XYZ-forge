# Lane brief — GH-206: split harness-home from repo-root in marathon.sh

Execution surface of record: `PROJECT/1-INBOX/GH-206-VENDORED-MARATHON-ROOT-SPLIT.md`
(issue: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/206)

## Task

`relay-automation/marathon.sh:37-40` derives one `ROOT` and uses it as both the harness home
(`TICK_BIN="$ROOT/bin/tick"`, `MARATHON_YAML_BIN="$ROOT/bin/marathon-yaml"`) and the target repo
root (brief paths `"$ROOT/$brief"`, `TICK_REPO_ROOT`). In a vendored `.xyz/` install these differ
(`repo/.xyz/` vs `repo/`) and no single ROOT value works.

Implement the split:

1. `MARATHON_HOME` — defaults from the script's own location (`$HERE/..`): resolves `bin/tick`,
   `bin/marathon-yaml`, `utils/telemetry/append-xyz-completion.sh`, phase-render defaults.
2. `MARATHON_ROOT` — defaults from `git -C "$PWD" rev-parse --show-toplevel`: resolves briefs,
   `TICK_REPO_ROOT`, commit target. Falls back to `MARATHON_HOME` when not inside a git repo.
3. Both independently overridable via env (keep the existing `MARATHON_YAML_BIN` / `TICK_BIN` /
   `XYZ_APPEND_BIN` overrides working).
4. Dev checkout (home == root) must behave exactly as before.
5. Audit `marathon-drive.sh` for the same conflation; fix here if small, otherwise note it in the
   relay thread for a follow-up issue.

## Definition of done

- Vendored layout: `.xyz/relay-automation/marathon.sh --plan <repo-relative>` from the target repo
  root runs with zero env overrides (add a vendored-layout case to `test/marathon.sh`: harness dir
  ≠ git toplevel).
- Dev layout: existing `test/marathon.sh` cases stay green.
- `relay-automation/README.md` documents the two roots.
- `bash validate.sh` green.
