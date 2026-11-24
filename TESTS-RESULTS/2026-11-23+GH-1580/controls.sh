#!/usr/bin/env bash
# GH-1580 manual red/green controls (no new suite, GH-831). Replays the remaining swarm_preflight
# fixes and legacy gate controls found by BinoidCBD/LTVera-Pandas#1205 through the REAL preflight entry point, against a
# throwaway fixture repo, with `gh` stubbed and `uv` absent from PATH (the #1140 condition).
#
#   usage: controls.sh <xyz-root> <label> <source-commit>
#     <xyz-root>       a tree holding utils/py/swarm_preflight.py (red: a pristine origin/development
#                      export; green: the changed head)
#     <label>          red | green — names the output file and the provenance role
#     <source-commit>  the commit that tree corresponds to, recorded in provenance.jsonl
#
# Every case states the TRUE expectation (what a correct preflight does) and prints MATCH or
# MISMATCH against what the run under test did. Red must MISMATCH on the unchanged source; green must
# MATCH everywhere. The script itself always exits 0; read the MATCH/MISMATCH column and the totals.
# Output: outputs/<label>.txt next to this script; one line is appended to provenance.jsonl.
set -uo pipefail
XYZ_ROOT_UNDER_TEST="${1:?xyz-root}"; LABEL="${2:?label}"; SRC_COMMIT="${3:?source-commit}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PY="$XYZ_ROOT_UNDER_TEST/utils/py/swarm_preflight.py"
[ -f "$PY" ] || { echo "missing $PY" >&2; exit 1; }
PYTHON="$(command -v python3)"
WORK="$(mktemp -d "${TMPDIR:-/tmp}/gh1580.XXXXXX")"; trap 'rm -rf "$WORK"' EXIT
mkdir -p "$WORK/bin" "$WORK/issues" "$HERE/outputs"
OUT="$HERE/outputs/$LABEL.txt"; : >"$OUT"
say() { printf '%s\n' "$*" >>"$OUT"; }
MATCHES=0; MISMATCHES=0

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
    [ "$doc_acc" = no ] && printf '## Phase 1\n\n- [ ] The lockfile check passes.\n\n'
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

preflight() {  # preflight <repo> <doc> [extra args...] -> stdout+stderr; sets PF_RC
  local repo="$1" doc="$2"; shift 2
  PF_OUT="$(PATH="$SAFE_PATH" SWARM_PREFLIGHT_ROOT="$repo" XYZ_ROOT="$XYZ_ROOT_UNDER_TEST" \
        SWARM_PREFLIGHT_NOW="2026-11-23T00:00:00Z" SWARM_PREFLIGHT_TODAY="2026-11-23" \
        "$PYTHON" "$PY" --target-root "$repo" --project-doc "$doc" --dry-run "$@" 2>&1)"; PF_RC=$?
}

verdict() {  # verdict <label> <ok:0|1> <expectation> <observation>
  local tag="MATCH"; [ "$2" = 0 ] && MATCHES=$((MATCHES+1)) || { tag="MISMATCH"; MISMATCHES=$((MISMATCHES+1)); }
  say "── [$tag] $1"; say "   expect : $3"; say "   observed: $4"; say ""
}

# case <label> <repo> <doc> <expect-exit> <expect-regex-or-''> [<forbid-regex>] [<second-required-regex>]
case_text() {
  local label="$1" repo="$2" doc="$3" want_rc="$4" want_re="$5" forbid_re="${6:-}" want_re2="${7:-}" ok=0 lines
  preflight "$repo" "$doc"
  [ "$PF_RC" = "$want_rc" ] || ok=1
  if [ -n "$want_re" ]; then grep -Eq -- "$want_re" <<<"$PF_OUT" || ok=1; fi
  if [ -n "$want_re2" ]; then grep -Eq -- "$want_re2" <<<"$PF_OUT" || ok=1; fi
  if [ -n "$forbid_re" ]; then grep -Eq -- "$forbid_re" <<<"$PF_OUT" && ok=1; fi
  lines="$(grep -E '^(  (candidate|acceptance|gap|GAP|readiness|verdict)|CONTRACT|BLOCKED|swarm-preflight:)' <<<"$PF_OUT" | sed "s#$WORK#<work>#g" | tr '\n' '|')"
  verdict "$label" "$ok" "exit $want_rc${want_re:+, output matches /$want_re/}${want_re2:+, output matches /$want_re2/}${forbid_re:+, output does NOT match /$forbid_re/}" "exit $PF_RC; $lines"
}

# json case: nonempty JSON, readiness.gaps list must satisfy <mode>
#   mode=has:<substring>  list is nonempty and some entry contains the substring
#   mode=empty            key is present and the list is empty
case_json() {
  local label="$1" repo="$2" doc="$3" mode="$4" ok=0 obs
  preflight "$repo" "$doc" --format json
  obs="$(JSON_TEXT="$PF_OUT" MODE="$mode" "$PYTHON" -c '
import json, os, sys
txt = os.environ["JSON_TEXT"]; mode = os.environ["MODE"]
i = txt.find("{")
if i < 0 or not txt.strip():
    print("empty-or-no-json"); sys.exit(1)
try:
    data = json.JSONDecoder().raw_decode(txt[i:])[0]
except ValueError as e:
    print("invalid-json: %s" % e); sys.exit(1)
r = data.get("readiness", {})
if "gaps" not in r:
    print("readiness has no gaps key; keys=%s" % sorted(r)); sys.exit(1)
g = r["gaps"]
if mode == "empty":
    print("gaps=%r" % (g,)); sys.exit(0 if g == [] else 1)
sub = mode.split(":", 1)[1]
print("gaps=%r" % (g,)); sys.exit(0 if any(sub in str(x) for x in g) else 1)
' 2>&1)" || ok=1
  [ "$PF_RC" = 0 ] || ok=1
  verdict "$label" "$ok" "exit 0, valid nonempty JSON, readiness.gaps ($mode)" "exit $PF_RC; $obs"
}

say "# GH-1580 controls — label=$LABEL — source=$SRC_COMMIT — swarm_preflight.py sha256=$(shasum -a 256 "$PY" | cut -c1-12)"
say "# fixture PATH has no uv; gh is stubbed; every case is a throwaway repo; expectations are the CORRECT behaviour"; say ""

# ── Defect 1: probe line anchors ─────────────────────────────────────────────────────────────────
# ENABLE_X=1 is on its own mid-file line, so a grep_present for it reads "unfixed" and the lane is ready.
CFG=$'# settings\nENABLE_X=1\nOTHER=2\n'
R="$(make_repo anchor-present 101 true '[{"type":"grep_present","path":"config.txt","pattern":"^ENABLE_X=1$"}]' yes "$CFG")"
case_text "D1a grep_present '^ENABLE_X=1\$' on a mid-file line: still unfixed -> ready" "$R" PROJECT/2-WORKING/GH-101-fixture.md 0 'verdict +: ready'
# `alembic check` is on its own line, so a grep_absent anchored with ^ reads "landed" (preflight STALE, exit 4).
CFG2=$'alembic upgrade head\nalembic check\nexec app\n'
R="$(make_repo anchor-absent 102 true '[{"type":"grep_absent","path":"config.txt","pattern":"^alembic check"}]' yes "$CFG2")"
case_text "D1b grep_absent '^alembic check' with the fix on its own line: landed -> STALE" "$R" PROJECT/2-WORKING/GH-102-fixture.md 4 'verdict +: STALE'
# Control: the same anchored pattern must NOT match a commented-out line or an embedded mention.
CFG3=$'alembic upgrade head\n# alembic check\necho "alembic check"\n'
R="$(make_repo anchor-comment 103 true '[{"type":"grep_absent","path":"config.txt","pattern":"^alembic check"}]' yes "$CFG3")"
case_text "D1c grep_absent '^alembic check' vs comment/echo only: still unfixed -> ready" "$R" PROJECT/2-WORKING/GH-103-fixture.md 0 'verdict +: ready'

# The operator dropped the multi-command gate extension after final QA. Guard legacy behavior.
PROBE='[{"type":"path_absent","path":"NEW.txt"}]'
R="$(make_repo gate-uv-first 201 'uv lock --check && bash -n src/ok.sh' "$PROBE" yes)"
case_text "D2 legacy: missing first command still blocks" "$R" PROJECT/2-WORKING/GH-201-fixture.md 5 "command 'uv' not found in PATH"
R="$(make_repo gate-uv-second 202 'bash -n src/ok.sh && uv lock --check' "$PROBE" yes)"
case_text "D2 legacy: a later missing command preserves the existing readiness result" "$R" PROJECT/2-WORKING/GH-202-fixture.md 0 'verdict +: ready'
R="$(make_repo gate-assignment 203 'true && PYTHONPATH+=:src python3 -V' "$PROBE" yes)"
case_text "D2 legacy: shell append assignment in a later segment preserves readiness" "$R" PROJECT/2-WORKING/GH-203-fixture.md 0 'verdict +: ready'

# ── Final-QA r1 repair F4 (path_present) ─────────────────────────────────────────────────────────
R="$(make_repo path-present-gone 214 true '[{"type":"path_present","path":"GONE.txt"}]' yes)"
case_text "D4a F4 path_present on an unwanted path that is already gone -> landed (STALE, exit 4), not blocked" "$R" PROJECT/2-WORKING/GH-214-fixture.md 4 'verdict +: STALE'
R="$(make_repo path-present-here 215 true '[{"type":"path_present","path":"config.txt"}]' yes "x")"
case_text "D4b path_present on an unwanted path that is still there -> unfixed, ready" "$R" PROJECT/2-WORKING/GH-215-fixture.md 0 'verdict +: ready'

R="$(make_repo path-present-dangling 216 true '[{"type":"path_present","path":"link.txt"}]' yes)"
ln -s "$R/missing-target" "$R/link.txt"
case_text "D4c dangling unwanted symlink is still present -> unfixed, ready" "$R" PROJECT/2-WORKING/GH-216-fixture.md 0 'verdict +: ready'

# ── Defect 3: acceptance gap ─────────────────────────────────────────────────────────────────────
printf '## Summary\nLockfile drift.\n\n## Done when\n\n- [ ] The lockfile check passes.\n' >"$WORK/issues/301.md"
R="$(make_repo acc-done-when 301 true "$PROBE" yes)"
case_text "D3 text: issue criteria under '## Done when', no '## Acceptance' -> gap line names 'Done when'; exit unchanged (0)" "$R" PROJECT/2-WORKING/GH-301-fixture.md 0 'gap +: .*#301.*Done when'
case_json "D3 json: same case -> readiness.gaps names 'Done when'" "$R" PROJECT/2-WORKING/GH-301-fixture.md 'has:Done when'
printf '## Summary\nLockfile drift.\n\n## Acceptance\n\n- [ ] The lockfile check passes.\n' >"$WORK/issues/302.md"
R="$(make_repo acc-present 302 true "$PROBE" yes)"
case_text "D3-control text: issue has '## Acceptance' matching the doc verbatim -> match, no gap line" "$R" PROJECT/2-WORKING/GH-302-fixture.md 0 'acceptance +: match' '^  gap +:'
case_json "D3-control json: same case -> readiness.gaps present and empty" "$R" PROJECT/2-WORKING/GH-302-fixture.md 'empty'
R="$(make_repo acc-doc-whole 304 true "$PROBE" no)"   # no issue 304 in the stub: gh fails -> fetch-failed
case_text "D3-doc text: capture doc has no '## Acceptance' (checklist read from the whole document) -> gap line names the doc" "$R" PROJECT/2-WORKING/GH-304-fixture.md 0 'gap +: .*capture doc'
case_json "D3-doc json: same case -> readiness.gaps names the capture doc" "$R" PROJECT/2-WORKING/GH-304-fixture.md 'has:capture doc'

say "# totals: MATCH=$MATCHES MISMATCH=$MISMATCHES"
echo "wrote $OUT (MATCH=$MATCHES MISMATCH=$MISMATCHES)"

# One provenance line per run (GH-430): revision, command, output and its hash.
OUT_SHA="$(shasum -a 256 "$OUT" | cut -d' ' -f1)"
LABEL="$LABEL" SRC="$SRC_COMMIT" OUTSHA="$OUT_SHA" M="$MATCHES" X="$MISMATCHES" PYV="$("$PYTHON" -c 'import sys;print(sys.version.split()[0])')" \
  PROV_DIR="$HERE" CMD="bash controls.sh <$LABEL tree> $LABEL $SRC_COMMIT" "$PYTHON" -c '
import json, os, datetime
role = {"red": "RED: unchanged origin/development; MISMATCH expected on the defect cases",
        "green": "GREEN: changed head; MATCH expected on every case"}.get(os.environ["LABEL"], os.environ["LABEL"])
rec = {"at": datetime.datetime.now(datetime.timezone.utc).isoformat(), "command": os.environ["CMD"],
       "exit_code": 0, "match": int(os.environ["M"]), "mismatch": int(os.environ["X"]),
       "output": "outputs/%s.txt" % os.environ["LABEL"], "output_sha256": os.environ["OUTSHA"],
       "python": os.environ["PYV"], "role": role, "source_commit": os.environ["SRC"]}
open(os.path.join(os.environ.get("PROV_DIR", "."), "provenance.jsonl"), "a").write(json.dumps(rec, sort_keys=True) + "\n")
'
