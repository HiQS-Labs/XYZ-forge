#!/usr/bin/env bash
# test/gh267-express-skill.sh — GH-267 regression guard for the /express driver.
#
# WHY THIS EXISTS: /express is the only sanctioned no-human-gate landing path in
# this repo (it mechanizes SOP §4's express-to-development carve-out). Its value
# IS its refusal surface: a lane that can be talked past any guardrail is just a
# direct push with extra steps. This suite pins the guardrails shut.
#
# WHAT IS CHECKED (all hermetic — a fake `gh` on PATH serves issue state, a
# local bare remote serves origin/development; no network, no real GitHub):
#   refusals: task-branch, task-clone, frozen-twin, shared-runtime, no-new-bash,
#             kernel-surface, scratch (.orig editor artifact), too-many-files,
#             suite-unregistered, issue-closed
#   happy path: check PASS on a legal single-subsystem fix with a registered suite;
#               docs (.md) never count against the file bound
#   docs: capture doc born complete (Lessons Learned present from birth) +
#         CHANGELOG entry inserted under a fresh dated Unreleased section +
#         CHANGELOG entry NOT silently dropped when today's section lacks a
#         ### Fixed heading (deepseek QA finding 3)
#   telemetry: every refusal writes a .tick express-refused event carrying the rule
#   source audit: cmd_land/build_offline_manifest never call args_repo() — the
#             --repo flag must thread through every landing gh call (QA finding 1)
#
# CONTAINMENT (GH-567): every path derived from $WORK is asserted non-empty and
# lexically under $WORK at the point of use, not just at mktemp time. The suite
# never writes outside $WORK and never touches the real clone it runs from.

set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
DRIVER="$HERE/../utils/py/express.py"
WORK="$(mktemp -d /tmp/gh267-express.XXXXXX)" || { echo "FAIL: mktemp"; exit 1; }
BIN="$WORK/bin"; GH_STATE="$WORK/gh-state"
mkdir -p "$BIN" "$GH_STATE"

# GH-1 adoption: the central fixture guard (GH-564 kill conditions + GH-567
# use-boundary resolution), armed at source time — no private copies.
. "$HERE/lib/fixture-guard.sh"
fixture_guard_init "$WORK"

case "$WORK" in /tmp/gh267-express.*) ;; *) echo "FAIL: unsafe WORK=$WORK"; exit 1;; esac

PASS=0; FAIL=0
ok()   { PASS=$((PASS+1)); echo "  pass: $1"; }
bad()  { FAIL=$((FAIL+1)); echo "  FAIL: $1"; }
check_rule() { # check_rule <expected-rule> <stderr-file>
  grep -q "express-refused: rule=$1" "$2" || echo "    [stderr was: $(tail -1 "$2" 2>/dev/null)]"
}

# ── fake gh ──────────────────────────────────────────────────────────────────
cat > "$BIN/gh" <<'GH'
#!/usr/bin/env bash
# gh267 suite stub: serves `issue view <N> --json ...` from $GH_STATE/issue-<N>.json
set -u
if [ "$1 $2" = "issue view" ]; then
  n=""
  prev=""
  for a in "$@"; do
    [ "$prev" = "view" ] && n="$a"
    prev="$a"
  done
  cat "$GH_STATE/issue-$n.json" && exit 0
fi
echo "gh-stub: unsupported invocation: $*" >&2; exit 1
GH
chmod +x "$BIN/gh"
export PATH="$BIN:$PATH"
export GH_STATE
issue_json() { printf '{"state":"%s","title":"%s","url":"https://github.com/H/H/issues/%s","createdAt":"2026-08-27T00:00:00Z"}\n' "$1" "$2" "$3" > "$GH_STATE/issue-$3.json"; }
issue_json OPEN "Demo hotfix" 999
issue_json CLOSED "Already done" 888

# ── fixture repo ─────────────────────────────────────────────────────────────
FX="$WORK/repo"; REMOTE="$WORK/remote.git"
git init -q --bare "$REMOTE"
git init -q "$FX"
git -C "$FX" remote add origin "$REMOTE"
git -C "$FX" config user.email t@t; git -C "$FX" config user.name t
mkdir -p "$FX/utils/py" "$FX/test" "$FX/relay-automation" "$FX/PROJECT/2-WORKING" "$FX/CHANGELOG.d"
printf '#!/usr/bin/env bash\nTESTS=(\n  "gh999-demo.sh"\n  "other.sh"\n)\n' > "$FX/validate.sh"
printf 'old\n' > "$FX/utils/py/foo.py"
printf 'twin body\n' > "$FX/relay-automation/consult.sh"
printf 'shared runtime\n' > "$FX/relay-automation/relay-turn-lib.sh"
printf 'readme\n' > "$FX/README.md"
printf '# demo suite\n' > "$FX/test/gh999-demo.sh"
printf '# unregistered suite\n' > "$FX/test/gh999b-unreg.sh"
printf '# Changelog\n\nAll notable changes.\n\n## [Unreleased] - 2026-01-01\n\n### Fixed\n- old entry\n' > "$FX/CHANGELOG.md"
git -C "$FX" add -A && git -C "$FX" commit -qm base
git -C "$FX" branch -m development
git -C "$FX" push -q origin development
git -C "$FX" fetch -q origin
require_fixture "$FX"
require_fixture "$REMOTE"
echo "fixture ready"

new_task_branch() {
  # reset to a pristine task branch: discard tracked mods, untracked files, and
  # any stray commits, so each case starts from the exact base state
  require_fixture "$FX"
  git -C "$FX" checkout -q development
  git -C "$FX" reset -q --hard origin/development
  git -C "$FX" clean -fdq
  git -C "$FX" checkout -q -B task/gh-999 origin/development
}
run_check() {
  require_fixture "$FX"
  python3 "$DRIVER" --root "$FX" check --issue "${1:-999}" --suite "${2:-test/gh999-demo.sh}" ;
}

echo "== refusals =="
ERR="$WORK/err"; : > "$ERR"

new_task_branch; git -C "$FX" checkout -q development
run_check > /dev/null 2> "$ERR" && bad "on-development must refuse" || { check_rule task-branch "$ERR" && ok "task-branch refusal" || bad "task-branch rule"; }
EV="$(ls "$FX/.tick/events/"*express-refused*.jsonl 2>/dev/null | head -1)"
[ -n "$EV" ] && grep -q '"verb": "express-refused"' "$EV" && ok "express-refused tick event written" || bad "tick telemetry missing"

new_task_branch; printf 'x\n' >> "$FX/utils/py/foo.py"; git -C "$FX" add -A; git -C "$FX" commit -qm extra
run_check > /dev/null 2> "$ERR" && bad "HEAD-ahead must refuse" || { check_rule task-clone "$ERR" && ok "task-clone refusal (GH-527)" || bad "task-clone rule"; }

new_task_branch; printf 'x\n' >> "$FX/relay-automation/consult.sh"
run_check > /dev/null 2> "$ERR" && bad "twin edit must refuse" || { check_rule frozen-twin "$ERR" && ok "frozen-twin refusal (GH-308)" || bad "frozen-twin rule"; }

new_task_branch; printf 'x\n' >> "$FX/relay-automation/relay-turn-lib.sh"
run_check > /dev/null 2> "$ERR" && bad "shared runtime edit must refuse" || { check_rule shared-runtime "$ERR" && ok "shared-runtime refusal (QA F4: not mislabeled frozen-twin)" || bad "shared-runtime rule"; }

new_task_branch; printf 'x\n' > "$FX/utils/py/leftover.py.orig"
run_check > /dev/null 2> "$ERR" && bad ".orig artifact must refuse" || { check_rule scratch "$ERR" && ok "scratch refusal for .orig (QA F2)" || bad ".orig scratch rule"; }

new_task_branch; printf 'x\n' >> "$FX/relay-automation/new-thing.sh"
run_check > /dev/null 2> "$ERR" && bad "new bash must refuse" || { check_rule no-new-bash "$ERR" && ok "no-new-bash refusal (GH-551)" || bad "no-new-bash rule"; }

new_task_branch; mkdir -p "$FX/.tick/events"; printf '{}' > "$FX/.tick/events/evil.json"
run_check > /dev/null 2> "$ERR" && bad "kernel surface must refuse" || { check_rule kernel-surface "$ERR" && ok "kernel-surface refusal" || bad "kernel-surface rule"; }

new_task_branch; for i in 1 2 3 4 5; do printf 'x\n' > "$FX/utils/py/f$i.py"; done
run_check > /dev/null 2> "$ERR" && bad "5 files must refuse" || { check_rule too-many-files "$ERR" && ok "too-many-files refusal" || bad "too-many-files rule"; }

new_task_branch; printf 'x\n' >> "$FX/utils/py/foo.py"
run_check 999 test/gh999b-unreg.sh > /dev/null 2> "$ERR" && bad "unregistered suite must refuse" || { check_rule suite-unregistered "$ERR" && ok "suite-unregistered refusal" || bad "suite-unregistered rule"; }

new_task_branch; printf 'x\n' >> "$FX/utils/py/foo.py"
run_check 888 > /dev/null 2> "$ERR" && bad "closed issue must refuse" || { check_rule issue-closed "$ERR" && ok "issue-closed refusal (already-landed guard)" || bad "issue-closed rule"; }

echo "== happy path =="
new_task_branch; printf 'fixed\n' > "$FX/utils/py/foo.py"; printf '# demo suite v2\n' > "$FX/test/gh999-demo.sh"
OUT="$(run_check 999)"
grep -q "express-check: PASS" <<<"$OUT" && ok "legal fix passes" || bad "legal fix refused: $OUT"

new_task_branch; printf 'fixed\n' > "$FX/utils/py/foo.py"; for i in 1 2 3; do printf 'x\n' > "$FX/utils/py/g$i.py"; done; printf 'doc edit\n' > "$FX/README.md"
run_check > /dev/null 2> "$ERR" && ok "docs (.md) exempt from the file bound (QA F5)" || bad "README counted against bounds: $(tail -1 "$ERR")"

echo "== docs born complete =="
python3 "$DRIVER" --root "$FX" docs --issue 999 --suite test/gh999-demo.sh --summary "demo" >/dev/null 2>"$ERR" || bad "docs scaffold failed: $(cat "$ERR")"
DOC="$FX/PROJECT/2-WORKING/GH-999-DEMO-HOTFIX.md"
[ -f "$DOC" ] && ok "capture doc created" || bad "capture doc missing"
grep -q "## Lessons Learned (For Future Agents)" "$DOC" 2>/dev/null && ok "Lessons Learned present from birth (GH-232 gate)" || bad "doc not born complete"
grep -q "^## Status$" "$DOC" && grep -q "^## Acceptance Criteria$" "$DOC" && ok "Status + Acceptance present" || bad "doc sections incomplete"
TODAY="$(date +%F)"
grep -q "## \[Unreleased\] - $TODAY" "$FX/CHANGELOG.md" && ok "CHANGELOG dated section inserted" || bad "CHANGELOG section missing"
CH_TODAY="$(awk "/## \[Unreleased\] - $TODAY/,0" "$FX/CHANGELOG.md")"
grep -q "GH-999" <<<"$CH_TODAY" && ok "CHANGELOG entry present" || bad "CHANGELOG entry missing"

# QA F3: a today-section WITHOUT a ### Fixed heading must not silently drop the entry
new_task_branch
printf '# Changelog\n\nAll notable changes.\n\n## [Unreleased] - %s\n\n### Added\n- someone added something\n\n## [Unreleased] - 2026-01-01\n\n### Fixed\n- old entry\n' "$TODAY" > "$FX/CHANGELOG.md"
rm -f "$FX/PROJECT/2-WORKING/GH-999-DEMO-HOTFIX.md"
python3 "$DRIVER" --root "$FX" docs --issue 999 --suite test/gh999-demo.sh --summary "demo" >/dev/null 2>"$ERR" || bad "docs scaffold (no-Fixed-heading) failed: $(cat "$ERR")"
CH_F3="$(awk "/## \[Unreleased\] - $TODAY/,/## \[Unreleased\] - 2026-01-01/" "$FX/CHANGELOG.md")"
grep -q "GH-999" <<<"$CH_F3" && ok "CHANGELOG entry survives a Fixed-less today-section (QA F3)" || bad "CHANGELOG entry silently dropped (QA F3 regression)"

echo "== source audit (QA F1) =="
LAND_BODY="$(awk '/^def cmd_land/,/^def [a-z_]+\(/' "$DRIVER"; true)"
[ -z "$(printf '%s' "$LAND_BODY" | grep -n "args_repo()")" ] && ok "cmd_land threads --repo (no args_repo fallback)" || bad "cmd_land still calls args_repo() — --repo split-brain (QA F1)"
grep -q "def build_offline_manifest(root, repo, pr_number)" "$DRIVER" && ok "build_offline_manifest takes repo explicitly" || bad "build_offline_manifest lost its repo param (QA F1)"

echo
echo "gh267-express-skill: pass=$PASS fail=$FAIL"
# cleanup mirrors gh1-adoption-guard: the guard refuses the bare sandbox root
# by design, so teardown uses the plain -d check
[ -n "$WORK" ] && [ -d "$WORK" ] && rm -rf "$WORK"
[ "$FAIL" -eq 0 ]
