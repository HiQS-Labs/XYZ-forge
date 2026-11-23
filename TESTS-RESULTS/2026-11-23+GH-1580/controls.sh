#!/usr/bin/env bash
# GH-1580 manual red/green controls (no new suite, GH-831). Replays the three swarm_preflight
# defects found by BinoidCBD/LTVera-Pandas#1205 through the REAL preflight entry point, against a
# throwaway fixture repo, with `gh` stubbed and `uv` absent from PATH (the #1140 condition).
#
#   usage: controls.sh <xyz-root> <label>
#     <xyz-root>  a tree holding utils/py/swarm_preflight.py (red: pristine origin/development
#                 export; green: the changed head)
#     <label>     red | green — names the output file only
#
# Output: outputs/<label>.txt next to this script. Exit code is always 0; read the verdicts.
set -uo pipefail
XYZ_ROOT_UNDER_TEST="${1:?xyz-root}"; LABEL="${2:?label}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PY="$XYZ_ROOT_UNDER_TEST/utils/py/swarm_preflight.py"
[ -f "$PY" ] || { echo "missing $PY" >&2; exit 1; }
PYTHON="$(command -v python3)"
WORK="$(mktemp -d "${TMPDIR:-/tmp}/gh1580.XXXXXX")"; trap 'rm -rf "$WORK"' EXIT
mkdir -p "$WORK/bin" "$WORK/issues" "$HERE/outputs"
OUT="$HERE/outputs/$LABEL.txt"; : >"$OUT"
say() { printf '%s\n' "$*" | tee -a "$OUT" >/dev/null; }

# PATH carries bash/coreutils and python3 but NOT uv (the LTVera #1140 host).
ln -s "$PYTHON" "$WORK/bin/python3"
cat >"$WORK/bin/gh" <<'STUB'
#!/usr/bin/env bash
n=""; for a in "$@"; do case "$a" in ''|*[!0-9]*) ;; *) n="$a"; break ;; esac; done
[ -n "$n" ] && [ -f "$GH_STUB_DIR/$n.md" ] || { echo "gh: no such issue" >&2; exit 1; }
cat "$GH_STUB_DIR/$n.md"
STUB
chmod +x "$WORK/bin/gh"; export GH_STUB_DIR="$WORK/issues"
SAFE_PATH="$WORK/bin:/usr/bin:/bin"
if PATH="$SAFE_PATH" command -v uv >/dev/null 2>&1; then echo "uv unexpectedly on PATH" >&2; exit 1; fi

# make_repo <name> <issue> <gate> <probes-json> <doc-acceptance:yes|no> [config-text]
make_repo() {
  local name="$1" issue="$2" gate="$3" probes="$4" doc_acc="$5" config="${6:-}"
  local repo="$WORK/$name"
  mkdir -p "$repo/PROJECT/2-WORKING" "$repo/src"
  printf 'echo ok\n' >"$repo/src/ok.sh"; : >"$repo/src/target.txt"
  printf '%s' "$config" >"$repo/config.txt"
  {
    printf -- '---\ngh_issue: %s\nsource: https://github.com/fixture/repo/issues/%s\n' "$issue" "$issue"
    printf 'title: "GH-%s fixture"\n---\n\n# GH-%s\n\n' "$issue" "$issue"
    [ "$doc_acc" = yes ] && printf '## Acceptance\n\n- [ ] The lockfile check passes.\n\n'
    printf '## Swarm Preflight Contract\n\n```json\n'
    GATE="$gate" PROBES="$probes" "$PYTHON" -c '
import json, os
print(json.dumps({"target": {"repo": ".", "ref": "main"}, "gate": os.environ["GATE"],
  "fix_probes": json.loads(os.environ["PROBES"]), "artifacts": ["src/target.txt", "config.txt"],
  "remediation": {"source": "issue#1", "criteria": "fixture lane"}}, indent=2))'
    printf '```\n'
  } >"$repo/PROJECT/2-WORKING/GH-$issue-fixture.md"
  git -C "$repo" init -q -b main
  git -C "$repo" -c user.email=t@t -c user.name=t add -A >/dev/null
  git -C "$repo" -c user.email=t@t -c user.name=t commit -qm init >/dev/null
  git init -q --bare "$repo.origin"; git -C "$repo" remote add origin "$repo.origin"
  git -C "$repo" push -q origin main; git -C "$repo" branch -q --set-upstream-to=origin/main main
  printf '%s' "$repo"
}

# run <case-label> <repo> <doc>   -> prints the verdict lines and exit code into the output file
run() {
  local label="$1" repo="$2" doc="$3" out rc
  out="$(PATH="$SAFE_PATH" SWARM_PREFLIGHT_ROOT="$repo" XYZ_ROOT="$XYZ_ROOT_UNDER_TEST" \
        SWARM_PREFLIGHT_NOW="2026-11-23T00:00:00Z" SWARM_PREFLIGHT_TODAY="2026-11-23" \
        "$PYTHON" "$PY" --target-root "$repo" --project-doc "$doc" --dry-run 2>&1)"; rc=$?
  say "── $label"
  say "$(grep -E '^(  (candidate|acceptance|GAP|readiness|verdict)|CONTRACT|BLOCKED|swarm-preflight:)' <<<"$out" | sed "s#$WORK#<work>#g")"
  say "  exit=$rc"; say ""
}

say "# GH-1580 controls — label=$LABEL — swarm_preflight.py sha256=$(shasum -a 256 "$PY" | cut -c1-12)"
say "# fixture PATH has no uv; gh is stubbed; every case is a throwaway repo"; say ""

# ── Defect 1: probe line anchors ─────────────────────────────────────────────────────────────────
# Truth: ENABLE_X=1 is on its OWN LINE in the middle of the file, so a grep_present for it reads
# "unfixed" (match still present) and the lane is ready (exit 0).
CFG=$'# settings\nENABLE_X=1\nOTHER=2\n'
R="$(make_repo anchor-present 101 true '[{"type":"grep_present","path":"config.txt","pattern":"^ENABLE_X=1$"}]' yes "$CFG")"
run "D1a grep_present '^ENABLE_X=1\$' on a mid-file line (truth: unfixed -> ready, exit 0)" "$R" PROJECT/2-WORKING/GH-101-fixture.md
# Truth: `alembic check` is on its own line, so a grep_absent anchored with ^ reads "landed".
CFG2=$'alembic upgrade head\nalembic check\nexec app\n'
R="$(make_repo anchor-absent 102 true '[{"type":"grep_absent","path":"config.txt","pattern":"^alembic check"}]' yes "$CFG2")"
run "D1b grep_absent '^alembic check' with the fix on its own line (truth: landed, not exit 0)" "$R" PROJECT/2-WORKING/GH-102-fixture.md
# Control: the same anchored pattern must NOT match a commented-out line or an embedded mention.
CFG3=$'alembic upgrade head\n# alembic check\necho "alembic check"\n'
R="$(make_repo anchor-comment 103 true '[{"type":"grep_absent","path":"config.txt","pattern":"^alembic check"}]' yes "$CFG3")"
run "D1c grep_absent '^alembic check' vs comment/echo only (truth: unfixed -> ready, exit 0)" "$R" PROJECT/2-WORKING/GH-103-fixture.md

# ── Defect 2: only a gate's first command is existence-checked ───────────────────────────────────
PROBE='[{"type":"path_absent","path":"NEW.txt"}]'
R="$(make_repo gate-uv-first 201 'uv lock --check && bash -n src/ok.sh' "$PROBE" yes)"
run "D2a gate 'uv lock --check && bash -n ...' (uv absent; first command) -> NOT-READY exit 5" "$R" PROJECT/2-WORKING/GH-201-fixture.md
R="$(make_repo gate-uv-second 202 'bash -n src/ok.sh && uv lock --check' "$PROBE" yes)"
run "D2b gate 'bash -n ... && uv lock --check' (uv absent; second command, the #1140 gate) -> NOT-READY exit 5" "$R" PROJECT/2-WORKING/GH-202-fixture.md
R="$(make_repo gate-chain-ok 203 'cd src && bash -n ok.sh && env FOO=1 python3 -c pass | cat' "$PROBE" yes)"
run "D2c gate with cd, env-prefix and a pipe, every program present -> READY exit 0 (no false block)" "$R" PROJECT/2-WORKING/GH-203-fixture.md
R="$(make_repo gate-script-second 204 'true && bash src/missing.sh' "$PROBE" yes)"
run "D2d gate 'true && bash src/missing.sh' (missing script in the second command) -> NOT-READY exit 5" "$R" PROJECT/2-WORKING/GH-204-fixture.md

# ── Defect 3: acceptance check on an issue whose criteria sit under another heading ──────────────
printf '## Summary\nLockfile drift.\n\n## Done when\n\n- [ ] The lockfile check passes.\n' >"$WORK/issues/301.md"
R="$(make_repo acc-done-when 301 true "$PROBE" yes)"
run "D3 issue lists criteria under '## Done when' (no '## Acceptance'); doc has '## Acceptance'" "$R" PROJECT/2-WORKING/GH-301-fixture.md
printf '## Summary\nLockfile drift.\n\n## Acceptance\n\n- [ ] The lockfile check passes.\n' >"$WORK/issues/302.md"
R="$(make_repo acc-present 302 true "$PROBE" yes)"
run "D3-control issue has '## Acceptance' matching the doc verbatim -> match, no gap" "$R" PROJECT/2-WORKING/GH-302-fixture.md

echo "wrote $OUT"
