#!/usr/bin/env bash
# GH-1428 manual check: marathon-drive --dry-run renders the reviewer 3a GATE EVIDENCE step for each
# gate shape. Usage: gh1428-render.sh <xyz-clone> <workdir>
set -u
X="$1" W="$2"; rm -rf "$W"; mkdir -p "$W/tgt/tests" "$W/tgt/.venv/bin"
A="$W/tgt"; T="$X/bin/tick"
printf '.tick/\n.venv/\n' >"$A/.gitignore"; touch "$A/tests/test_dashboard_snapshot_refresh_filter.py"
git -C "$A" init -q && git -C "$A" add -A && git -C "$A" commit -qm init
TICK_REPO_ROOT="$A" "$T" init >/dev/null 2>&1
printf '## Implement x\nDo x.\n' >"$W/brief.md"
printf '## Implement x\nDo x.\n- Do NOT run ANY test or gate yourself — Those tests create temporary git fixtures/files inside your isolated worktree\n' >"$W/brief-gh54.md"
S="$W/stub"; printf '#!/usr/bin/env bash\nexit 0\n' >"$S"; chmod +x "$S"
render() { # <label> <brief> [--pre-advance-cmd CMD]
  local label="$1" brief="$2"; shift 2
  MARATHON_ROOT="$A" TICK_REPO_ROOT="$A" TICK_BIN="$T" CLAUDE_BIN="$S" AGY_BIN="$S" CODEX_BIN="$S" \
    bash "$X/relay-automation/marathon-drive.sh" --phases-dir "$A/phases" --phase-brief "$brief" \
    --target-root "$A" --builder codex --reviewer claude-reviewer --dry-run "$@" >"$W/$label.out" 2>&1
  local line; line="$(grep -m1 '^3a\. GATE EVIDENCE' "$W/$label.out" | cut -c1-120)"
  printf '%-22s %s\n' "$label" "${line:-<<no 3a line; rc/log in $label.out>>}"
}
render gh955-focused   "$W/brief.md"     --pre-advance-cmd '.venv/bin/pytest -q tests/test_dashboard_snapshot_refresh_filter.py'
render node-selector   "$W/brief.md"     --pre-advance-cmd '.venv/bin/pytest -q tests/test_dashboard_snapshot_refresh_filter.py::test_a -p no:cacheprovider'
render default-gate    "$W/brief.md"
render unscoped-pytest "$W/brief.md"     --pre-advance-cmd 'python3 -m pytest'
render file-plus-dir   "$W/brief.md"     --pre-advance-cmd 'pytest tests/test_dashboard_snapshot_refresh_filter.py tests/'
render compound        "$W/brief.md"     --pre-advance-cmd 'pytest tests/test_dashboard_snapshot_refresh_filter.py && true'
render gh54-fixtures   "$W/brief-gh54.md" --pre-advance-cmd '.venv/bin/pytest -q tests/test_dashboard_snapshot_refresh_filter.py'
echo "--- builder unverified: line rendered?"; grep -c '`unverified: <what> — <why>`' "$W/gh955-focused.out"
echo "--- worktree/tooling-only fallback wording (gh955-focused):"
grep -o 'cwd = your worktree[^;]*; if a test or source path is missing, do NOT substitute[^.]*\.' "$W/gh955-focused.out" | sed "s#$W#<work>#g"
