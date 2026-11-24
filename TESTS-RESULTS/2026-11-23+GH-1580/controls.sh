#!/usr/bin/env bash
# GH-1580 manual red/green controls (no new suite, GH-831). Replays the three swarm_preflight
# defects found by BinoidCBD/LTVera-Pandas#1205 through the REAL preflight entry point, against a
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

# A gate that is not a plain `&&` list keeps the base first-command check and must carry the advisory gap line.
NONPLAIN_GAP='^  gap +: gate is not a plain'
case_nonplain() {  # case_nonplain <label> <repo> <doc>  -> READY (no new refusal) + the gap line
  case_text "$1" "$2" "$3" 0 'verdict +: ready' '' "$NONPLAIN_GAP"
}
case_plain_ok() {  # a plain gate whose commands all resolve: READY and NO gap line
  case_text "$1" "$2" "$3" 0 'verdict +: ready' "$NONPLAIN_GAP"
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

# ── Defect 2: only a gate's first command is existence-checked ───────────────────────────────────
# PLAIN gate (one line, plain word characters, `&&` the only operator): EVERY command is checked.
PROBE='[{"type":"path_absent","path":"NEW.txt"}]'
R="$(make_repo gate-uv-first 201 'uv lock --check && bash -n src/ok.sh' "$PROBE" yes)"
case_text "D2a plain 'uv lock --check && bash -n ...' (uv absent, first command) -> NOT-READY" "$R" PROJECT/2-WORKING/GH-201-fixture.md 5 "command 'uv' not found in PATH"
R="$(make_repo gate-uv-second 202 'bash -n src/ok.sh && uv lock --check' "$PROBE" yes)"
case_text "D2b plain 'bash -n ... && uv lock --check' (uv absent, second command: the #1140 gate) -> NOT-READY" "$R" PROJECT/2-WORKING/GH-202-fixture.md 5 "command 'uv' not found in PATH"
R="$(make_repo gate-script-second 204 'true && bash src/missing.sh' "$PROBE" yes)"
case_text "D2d plain 'true && bash src/missing.sh' (missing script, second command) -> NOT-READY" "$R" PROJECT/2-WORKING/GH-204-fixture.md 5 'gate script not found.*missing\.sh'
R="$(make_repo gate-script-dash-c 211 'true && bash src/absent.sh -c' "$PROBE" yes)"
case_text "D2k plain 'true && bash src/absent.sh -c': -c after the script is its own argument, script missing -> NOT-READY" "$R" PROJECT/2-WORKING/GH-211-fixture.md 5 'gate script not found.*absent\.sh'
R="$(make_repo gate-script-dash-s 221 'true && bash src/absent.sh -s' "$PROBE" yes)"
case_text "D2s plain 'true && bash src/absent.sh -s': -s after the script is its own argument, script missing -> NOT-READY" "$R" PROJECT/2-WORKING/GH-221-fixture.md 5 'gate script not found.*absent\.sh'
R="$(make_repo gate-plain-ok 228 'true && bash -n src/ok.sh && test -f config.txt' "$PROBE" yes "x")"
case_plain_ok "D2z plain gate, every command resolves -> READY and NO non-plain gap line" "$R" PROJECT/2-WORKING/GH-228-fixture.md

# NOT plain: the base first-command check is kept (no new refusal), plus an advisory gap line. These are the
# inputs behind final-QA findings F1-F9; every one must be READY, and the gap line is asserted so it can fail.
R="$(make_repo gate-chain 203 'true && cd src && bash -n ok.sh && env FOO=1 python3 -c pass | cat' "$PROBE" yes)"
case_nonplain "D2c cd + env-prefix + pipe -> not plain: READY + gap" "$R" PROJECT/2-WORKING/GH-203-fixture.md
R="$(make_repo gate-cd-missing 205 'true && cd src && bash -n missing.sh' "$PROBE" yes)"
case_nonplain "D2e 'true && cd src && bash -n missing.sh': a cd gate is not plain, the later script is NOT checked -> READY + gap (accepted trade-off)" "$R" PROJECT/2-WORKING/GH-205-fixture.md
case_json "D2e json: the same gate carries the gap in readiness.gaps" "$R" PROJECT/2-WORKING/GH-205-fixture.md 'has:not a plain'
R="$(make_repo gate-skips 206 'bash -n src/ok.sh && bash -c "nonexistent_inner_cmd; true" && "${LTV_PYTHON:?set me}" -m pytest' "$PROBE" yes)"
case_nonplain "D2f bash -c body and an expansion word -> not plain: READY + gap" "$R" PROJECT/2-WORKING/GH-206-fixture.md
R="$(make_repo gate-cd-or 207 'true || cd src; bash -n src/ok.sh' "$PROBE" yes)"
case_nonplain "D2g F1 'true || cd src; bash -n src/ok.sh' -> READY + gap" "$R" PROJECT/2-WORKING/GH-207-fixture.md
R="$(make_repo gate-cd-pipe 208 'true && cd src | cat; bash -n src/ok.sh' "$PROBE" yes)"
case_nonplain "D2h F1 'true && cd src | cat; bash -n src/ok.sh' -> READY + gap" "$R" PROJECT/2-WORKING/GH-208-fixture.md
R="$(make_repo gate-cd-and-or 210 'false && cd src && true || bash -n config.txt' "$PROBE" yes "echo x")"
case_nonplain "D2j F1 'false && cd src && true || bash -n config.txt' -> READY + gap" "$R" PROJECT/2-WORKING/GH-210-fixture.md
R="$(make_repo gate-redir-ok 212 'true && bash -n src/ok.sh>/dev/null' "$PROBE" yes)"
case_nonplain "D2l F3 'true && bash -n src/ok.sh>/dev/null' -> READY + gap" "$R" PROJECT/2-WORKING/GH-212-fixture.md
R="$(make_repo gate-redir-missing 213 'true && bash -n src/absent.sh>/dev/null' "$PROBE" yes)"
case_nonplain "D2m F3 'true && bash -n src/absent.sh>/dev/null': not plain, later script NOT checked -> READY + gap (accepted trade-off)" "$R" PROJECT/2-WORKING/GH-213-fixture.md
R="$(make_repo gate-assign-cd 216 'true && FOO=1 cd src && bash -n ok.sh' "$PROBE" yes)"
case_nonplain "D2n F5 'true && FOO=1 cd src && bash -n ok.sh' -> READY + gap" "$R" PROJECT/2-WORKING/GH-216-fixture.md
R="$(make_repo gate-assign-cd-missing 217 'true && FOO=1 cd src && bash -n missing.sh' "$PROBE" yes)"
case_nonplain "D2o F5 'true && FOO=1 cd src && bash -n missing.sh': not plain, later script NOT checked -> READY + gap (accepted trade-off)" "$R" PROJECT/2-WORKING/GH-217-fixture.md
R="$(make_repo gate-heredoc 218 $'cat <<EOF\nhello\nEOF\nbash -n src/ok.sh' "$PROBE" yes)"
case_nonplain "D2p F6 heredoc body is data, not a command -> READY + gap" "$R" PROJECT/2-WORKING/GH-218-fixture.md
R="$(make_repo gate-heredoc-missing 219 $'cat <<EOF\nhello\nEOF\nbash -n src/missing.sh' "$PROBE" yes)"
case_nonplain "D2q F6 a missing script after a heredoc: not plain, NOT checked -> READY + gap (accepted trade-off)" "$R" PROJECT/2-WORKING/GH-219-fixture.md
R="$(make_repo gate-bash-s 220 'true && bash -s ignored-arg </dev/null' "$PROBE" yes)"
case_nonplain "D2r F7 'true && bash -s ignored-arg </dev/null' -> READY + gap" "$R" PROJECT/2-WORKING/GH-220-fixture.md
R="$(make_repo gate-procsub 224 'diff <(echo a) <(echo b) && bash -n src/ok.sh' "$PROBE" yes)"
case_nonplain "D2v audit: process substitution -> READY + gap" "$R" PROJECT/2-WORKING/GH-224-fixture.md
R="$(make_repo gate-if-dbracket 225 'true && if [[ -f src/ok.sh && -f config.txt ]]; then bash -n src/ok.sh; fi' "$PROBE" yes "x")"
case_nonplain "D2w F8 'true && if [[ -f a && -f b ]]; then bash -n src/ok.sh; fi' -> READY + gap" "$R" PROJECT/2-WORKING/GH-225-fixture.md
R="$(make_repo gate-if-dbracket-missing 226 'true && if [[ -f src/ok.sh && -f config.txt ]]; then gh1580_absent_command; fi' "$PROBE" yes "x")"
case_nonplain "D2x F8 a missing command in an if-block: not plain, NOT checked -> READY + gap (accepted trade-off)" "$R" PROJECT/2-WORKING/GH-226-fixture.md
R="$(make_repo gate-f9 229 'true && if [[ "]]" && -f src/ok.sh ]]; then bash -n src/ok.sh; fi' "$PROBE" yes "x")"
case_nonplain "D2f9 F9 'true && if [[ \"]]\" && -f src/ok.sh ]]; then bash -n src/ok.sh; fi' -> READY + gap" "$R" PROJECT/2-WORKING/GH-229-fixture.md
R="$(make_repo gate-assign-first 230 'FOO=1 true && bash -n src/ok.sh' "$PROBE" yes)"
case_text "D2aa not plain, first token 'FOO=1' not found: unchanged from base (NOT-READY exit 5), gap line still printed" "$R" PROJECT/2-WORKING/GH-230-fixture.md 5 "command 'FOO=1' not found in PATH" '' "$NONPLAIN_GAP"

# Single allow-list repair: unusual shell flags and shell builtins retain first-command behavior.
R="$(make_repo gate-bash-plus 231 'true && bash +x -n src/ok.sh' "$PROBE" yes)"
case_nonplain "D2ab bash +x before the script -> READY + gap" "$R" PROJECT/2-WORKING/GH-231-fixture.md
R="$(make_repo gate-bash-bundled 232 'true && bash -eO extglob src/ok.sh' "$PROBE" yes)"
case_nonplain "D2ac bash -eO before the script -> READY + gap" "$R" PROJECT/2-WORKING/GH-232-fixture.md
R="$(make_repo gate-shopt 233 'true && shopt -s nullglob' "$PROBE" yes)"
case_nonplain "D2ad shopt builtin -> READY + gap" "$R" PROJECT/2-WORKING/GH-233-fixture.md
R="$(make_repo gate-bash-simple-flags 234 'true && bash -nx src/ok.sh' "$PROBE" yes)"
case_plain_ok "D2ae bash -nx with a present script -> READY without a gate gap" "$R" PROJECT/2-WORKING/GH-234-fixture.md
R="$(make_repo gate-bash-missing 235 'true && bash -n src/missing.sh' "$PROBE" yes)"
case_text "D2af bash -n with an absent script -> NOT-READY" "$R" PROJECT/2-WORKING/GH-235-fixture.md 5 'gate script not found.*missing\.sh'
R="$(make_repo gate-missing-external 236 'true && gh1580_missing_command' "$PROBE" yes)"
case_text "D2ag absent external command -> NOT-READY" "$R" PROJECT/2-WORKING/GH-236-fixture.md 5 "command 'gh1580_missing_command' not found in PATH"

# ── Final-QA r1 repair F4 (path_present) ─────────────────────────────────────────────────────────
R="$(make_repo path-present-gone 214 true '[{"type":"path_present","path":"GONE.txt"}]' yes)"
case_text "D4a F4 path_present on an unwanted path that is already gone -> landed (STALE, exit 4), not blocked" "$R" PROJECT/2-WORKING/GH-214-fixture.md 4 'verdict +: STALE'
R="$(make_repo path-present-here 215 true '[{"type":"path_present","path":"config.txt"}]' yes "x")"
case_text "D4b path_present on an unwanted path that is still there -> unfixed, ready" "$R" PROJECT/2-WORKING/GH-215-fixture.md 0 'verdict +: ready'

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
