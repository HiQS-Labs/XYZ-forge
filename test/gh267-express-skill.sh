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
#   production projections: every adopted releases view + the roadmap dashboard
#   TOCTOU: both new paths and mutations of already-qualified bytes refuse
#   closeout: ship is persisted before clean-tree reconciliation; every failure ticks
#   source audit: cmd_land/build_offline_manifest never call args_repo() — the
#             --repo flag must thread through every landing gh call (QA finding 1)
#
# CONTAINMENT (GH-567): every path derived from $WORK is asserted non-empty and
# lexically under $WORK at the point of use, not just at mktemp time. The suite
# never writes outside $WORK and never touches the real clone it runs from.

set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
DRIVER="$HERE/../utils/py/express.py"
export EXPRESS_CANONICAL_PY="$(cd "$HERE/../utils/py" && pwd)"
export EXPRESS_REPO="H/H" XYZ_WORK_CONNECTORS=0
WORK="$(mktemp -d /tmp/gh267-express.XXXXXX)" || { echo "FAIL: mktemp"; exit 1; }
BIN="$WORK/bin"; GH_STATE="$WORK/gh-state"; export HOME="$WORK/home"
mkdir -p "$BIN" "$GH_STATE" "$HOME"

# GH-1 adoption: the central fixture guard (GH-564 kill conditions + GH-567
# use-boundary resolution), armed at source time — no private copies.
. "$HERE/lib/fixture-guard.sh"
require_forge_root githooks/install.sh   # GH-708: forge-root only — witnessed skip in a vendored .xyz/
fixture_guard_init "$WORK"

case "$WORK" in /tmp/gh267-express.*) ;; *) echo "FAIL: unsafe WORK=$WORK"; exit 1;; esac

PASS=0; FAIL=0
ok()   { PASS=$((PASS+1)); echo "  pass: $1"; }
bad()  { FAIL=$((FAIL+1)); echo "  FAIL: $1"; }
check_rule() { # check_rule <expected-rule> <stderr-file>
  if grep -q "express-refused: rule=$1" "$2"; then
    return 0
  fi
  echo "    [stderr was: $(tail -1 "$2" 2>/dev/null)]"
  return 1
}

# ── fake gh ──────────────────────────────────────────────────────────────────
cat > "$BIN/gh" <<'GH'
#!/usr/bin/env bash
# gh267 suite stub: issue view/close from $GH_STATE.
set -u
if [ "$1" = api ]; then
  case "$2" in repos/H/H/issues/[0-9]*) ;; *) echo "foreign native issue" >&2; exit 1;; esac
  python3 - "$2" <<'PY'
import json, os, sys
number = int(sys.argv[1].rsplit("/", 1)[-1])
with open(os.path.join(os.environ["GH_STATE"], "issue-%d.json" % number)) as source:
    issue = json.load(source)
print(json.dumps(dict(number=number, html_url=issue["url"],
                     state=issue["state"].lower(), labels=[{"name":"unrelated"}])))
PY
  exit $?
fi
if [ "$1 $2" = "issue view" ]; then
  n=""; prev=""
  for a in "$@"; do
    [ "$prev" = "view" ] && n="$a"
    prev="$a"
  done
  cat "$GH_STATE/issue-$n.json" && exit 0
fi
if [ "$1 $2" = "issue close" ]; then
  n=""; prev=""
  for a in "$@"; do
    [ "$prev" = "close" ] && n="$a"
    prev="$a"
  done
  [ -z "$n" ] && n=999
  printf '{"state":"CLOSED","title":"Demo hotfix","url":"https://github.com/H/H/issues/%s","createdAt":"2026-08-27T00:00:00Z"}\n' "$n" > "$GH_STATE/issue-$n.json"
  exit 0
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
export EXPRESS_FX="$FX"
git init -q --bare "$REMOTE"
git init -q "$FX"
git -C "$FX" remote add origin "$REMOTE"
git -C "$FX" config user.email t@t; git -C "$FX" config user.name t
mkdir -p "$FX/utils/py" "$FX/utils" "$FX/test" "$FX/relay-automation" "$FX/src" "$FX/PROJECT/2-WORKING" "$FX/CHANGELOG.d" "$FX/githooks"
printf '#!/usr/bin/env bash\nTESTS=(\n  "gh999-demo.sh"\n  "gh999-drift.sh"\n  "gh999-content-drift.sh"\n  "gh999-hook-drift.sh"\n  "other.sh"\n)\n' > "$FX/validate.sh"
printf 'old\n' > "$FX/utils/py/foo.py"
printf 'twin body\n' > "$FX/relay-automation/consult.sh"
printf 'shared runtime\n' > "$FX/relay-automation/relay-turn-lib.sh"
printf 'kernel\n' > "$FX/src/project.js"
printf 'readme\n' > "$FX/README.md"
printf '.tick/\nTESTS-RESULTS/.relay-scratch/\n' > "$FX/.gitignore"
printf '# demo suite\n' > "$FX/test/gh999-demo.sh"
printf '# suite that writes a stray file at run time (TOCTOU probe)\nprintf stray > stray-suite-artifact.txt\n' > "$FX/test/gh999-drift.sh"
printf '# suite that rewrites a qualified path (content TOCTOU probe)\nprintf suite-mutated > utils/py/foo.py\n' > "$FX/test/gh999-content-drift.sh"
printf '# suite that replaces the untracked git-metadata hook\nprintf "#!/bin/sh\\nexit 0\\n" > .git/hooks/pre-push\nchmod +x .git/hooks/pre-push\n' > "$FX/test/gh999-hook-drift.sh"
printf '# unregistered suite\n' > "$FX/test/gh999b-unreg.sh"
# Use the real installer contract with a tiny fixture gate. A foreign executable
# hook must not satisfy `install.sh --check`.
cp "$HERE/../githooks/install.sh" "$FX/githooks/install.sh"
printf '#!/usr/bin/env bash\nexit 0\n' > "$FX/githooks/pre-push"
chmod +x "$FX/githooks/install.sh" "$FX/githooks/pre-push"

# Faithful write-surface stub: every mutating releases verb changes the DB/dump
# and every adopted projection that production refresh_preview owns.
cat > "$FX/utils/py/releases_app.py" <<'RA'
#!/usr/bin/env python3
import os, sys
sys.path.insert(0, os.environ["EXPRESS_CANONICAL_PY"])
import releases_app as canonical
a = sys.argv[1:]
if a[:1] == ["next"]:
    c = canonical.connect("releases.db")
    print("NEXT: stub gid=" + c.execute("SELECT global_id FROM releases LIMIT 1").fetchone()[0])
    c.close()
if a[:2] in (["roadmap", "add"], ["roadmap", "update"], ["manifest", "dial-in"], ["manifest", "ship"]):
    c = canonical.connect("releases.db")
    before = canonical.get_generation(c)
    if a[:1] == ["roadmap"]:
        # Admission exercises the real ownership/native/schema/locked receipt boundary.
        canonical.main(["--root", os.getcwd()] + a)
    else:
        def mutate(conn):
            conn.execute("CREATE TABLE IF NOT EXISTS fixture_writes (id INTEGER PRIMARY KEY, verb TEXT)")
            conn.execute("INSERT INTO fixture_writes(verb) VALUES (?)", (" ".join(a[:2]),))
            if a[:2] == ["manifest", "ship"]:
                conn.execute("UPDATE manifest_items SET state='shipped'")
        canonical.perform_write(os.getcwd(), c,
                                "manifest-ship" if a[1] == "ship" else "manifest-add", None, mutate)
    changed = canonical.get_generation(c) != before
    c.close()
    if a[:2] == ["manifest", "ship"]:
        inject = os.environ.get("STUB_INJECT_PATH")  # GH-592 control (i): dirt after the clean check
        if inject:
            os.makedirs(os.path.dirname(inject), exist_ok=True)
            open(inject, "a").write('{"commit": "deadbeef", "case": "unrelated"}\n')
    for name in (("RELEASES-PREVIEW.html", "LEADERBOARD.html", "LEADERBOARD.md") if changed else ()):
        with open(name, "a", encoding="utf-8") as f:
            f.write("stub-release-write: %s\n" % " ".join(a[:2]))
print("stub-releases:", " ".join(a[:2]))
RA
cat > "$FX/utils/py/wave_reconcile.py" <<'WR'
#!/usr/bin/env python3
import os, subprocess, sys
if os.environ.get("WR_FAIL") == "1":
    print("forced reconcile failure", file=sys.stderr); sys.exit(9)
if subprocess.run(["git", "status", "--porcelain"], capture_output=True, text=True).stdout.strip():
    print("reconcile requires a clean tree", file=sys.stderr); sys.exit(8)
if subprocess.run(["git", "branch", "--show-current"], capture_output=True, text=True).stdout.strip() != "development":
    print("reconcile requires development", file=sys.stderr); sys.exit(7)
# GH-592: the driver must pass --gate; the gate mirrors check_provenance_receipts'
# identity check — some TESTS-RESULTS/**/provenance.jsonl line must carry the commit.
if "--gate" not in sys.argv:
    print("stub: --gate was not supplied", file=sys.stderr); sys.exit(11)
import json
sha = sys.argv[sys.argv.index("--commit") + 1]
found = False
for d, _, fs in os.walk("TESTS-RESULTS"):
    if "provenance.jsonl" in fs:
        fp = os.path.join(d, "provenance.jsonl")
        if os.path.islink(fp):
            continue
        for line in open(fp, encoding="utf-8"):
            try:
                rec = json.loads(line)
            except ValueError:
                continue
            if "pr" in rec or "pr_number" in rec:
                continue  # explicit PR identity conflicts with a commit landing (real matcher: pr fields must match)
            if rec.get("commit") == sha: found = True
if not found:
    print("--gate failure: No provenance.jsonl or error_log.jsonl entry matches PR #%s" % sha[:12], file=sys.stderr); sys.exit(6)
print("stub: Provenance receipt matched for commit %s" % sha[:12])
if os.path.isdir("PROJECT/2-WORKING"):
    for root_dir, dirs, files in os.walk("PROJECT/2-WORKING"):
        for f in files:
            if f.endswith(".md"):
                src = os.path.join(root_dir, f)
                dst = os.path.join("PROJECT/3-COMPLETED", f)
                os.makedirs("PROJECT/3-COMPLETED", exist_ok=True)
                os.replace(src, dst)
WR
python3 - "$FX" <<'PY' || exit 1
import argparse, os, sys
sys.path.insert(0, os.environ["EXPRESS_CANONICAL_PY"])
import releases_app as canonical
root = sys.argv[1]
canonical.cmd_init(argparse.Namespace(root=root, slug="H/H"))
c = canonical.connect(os.path.join(root, "releases.db"))
now = canonical.now_iso()
for index, number in enumerate((999, 998, 997), 1):
    c.execute("INSERT INTO issue_refs(id,global_id,url,created_at,updated_at) VALUES(?,?,?,?,?)",
              (index,canonical.new_gid("ref-"),"https://github.com/H/H/issues/%d" % number,now,now))
c.execute("INSERT INTO releases(id,global_id,repo_id,version,status,description,tracking_ref_id,updated_at) "
          "VALUES(1,?,1,'0.0.1','active','fixture',1,?)", (canonical.new_gid("rel-"),now))
for index in (1, 2, 3):
    c.execute("INSERT INTO manifest_items(id,global_id,release_id,issue_ref_id,state,updated_at) "
              "VALUES(?,?,1,?,'dialed_in',?)", (index,canonical.new_gid("mfi-"),index,now))
c.close()
# Pre-existing owned registration makes dry-run admission a pure preview, not intake.
canonical.cmd_roadmap_add(argparse.Namespace(root=root,issue_num=999,
    issue_url="https://github.com/H/H/issues/999",title="Demo hotfix",created="2026-08-27",
    doc_path="PROJECT/2-WORKING/GH-999-DEMO-HOTFIX.md",raw_text=None,dry_run=False))
PY
for projection in RELEASES-PREVIEW.html LEADERBOARD.html LEADERBOARD.md; do
  printf 'base projection\n' > "$FX/$projection"
done
printf '# Changelog\n\nAll notable changes.\n\n## [Unreleased] - 2026-01-01\n\n### Fixed\n- old entry\n' > "$FX/CHANGELOG.md"
git -C "$FX" add -A && git -C "$FX" commit -qm base
git -C "$FX" branch -m development
git -C "$FX" push -q origin development
git -C "$FX" fetch -q origin
(cd "$FX" && bash githooks/install.sh) >/dev/null
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
  # The production prerequisite is per clone; restore the canonical fixture
  # stub after every destructive sandbox reset so cases cannot contaminate it.
  rm -f "$FX/.git/hooks/pre-push"
  (cd "$FX" && bash githooks/install.sh) >/dev/null || exit 1
}
run_check() {
  require_fixture "$FX"
  python3 "$DRIVER" --root "$FX" check --issue "${1:-999}" --suite "${2:-test/gh999-demo.sh}" ;
}

echo "== refusals =="
ERR="$WORK/err"; : > "$ERR"

new_task_branch; git -C "$FX" checkout -q development
run_check > /dev/null 2> "$ERR" && bad "on-development must refuse" || { check_rule task-branch "$ERR" && ok "task-branch refusal" || bad "task-branch rule"; }
EV="$(ls "$FX/.tick/express/"*express-refused*.jsonl 2>/dev/null | head -1)"
[ -n "$EV" ] && grep -q '"verb": "express-refused"' "$EV" && ok "express-refused telemetry written under .tick/express/" || bad "express telemetry missing"
grep -q '"type": "express.refused"' "$EV" && grep -q '"schema_version": "0.2.0"' "$EV" && ok "express-refused record carries the tick 0.2.0 envelope (GH-694/#702)" || bad "express-refused record lacks the tick envelope"
# GH-694: the record must never land in tick's coordination log (#699) — one taskless record there once
# killed every projecting verb in the clone. Pin: tick still projects after a refusal.
[ -z "$(ls "$FX/.tick/events/"*express*.jsonl 2>/dev/null)" ] && ok "GH-694: nothing express-shaped in .tick/events/" || bad "GH-694: express telemetry leaked into .tick/events/"
TICK_BIN="$HERE/../bin/tick"
TICK_REPO_ROOT="$FX" "$TICK_BIN" claim GH267-PIN --agent pin --paths x >/dev/null 2>&1 || bad "GH-694 pin: tick claim failed in the fixture"
TICK_REPO_ROOT="$FX" "$TICK_BIN" info GH267-PIN >/dev/null 2>&1 && ok "GH-694: tick still projects after an express refusal" || bad "GH-694: tick cannot project after an express refusal"
TICK_REPO_ROOT="$FX" "$TICK_BIN" project >/dev/null 2>"$ERR" && ok "GH-694: tick project folded cleanly after an express refusal" || { bad "GH-694: tick project failed after an express refusal"; cat "$ERR"; }
grep -qE '^- (GH-999|lane|undefined) ' "$FX/.tick/STATE.md" && bad "GH-694: express refusal seeded a phantom task in STATE.md" || ok "GH-694: no phantom task from an express refusal"
# Defense in depth (#702): a foreign record that DOES land in .tick/events/ is skipped by the fold
# (`project.js` ignores non-`task.*` types and records without a string `task`), so it neither
# crashes projection nor seeds a phantom task. Control: `tick next` must not offer one either.
grep -q '^undefined' <<<"$(TICK_REPO_ROOT="$FX" "$TICK_BIN" next --agent pin2 2>/dev/null)" && bad "GH-694 control: phantom task present BEFORE the leak — fixture is dirty" || true
cp "$EV" "$FX/.tick/events/$(basename "$EV")"
TICK_REPO_ROOT="$FX" "$TICK_BIN" project >/dev/null 2>"$ERR" && ok "GH-694 control: the fold survives an express record leaked into .tick/events/" || { bad "GH-694 control: the fold crashed on a leaked express record"; cat "$ERR"; }
grep -qE '^- (GH-999|lane|undefined) ' "$FX/.tick/STATE.md" && bad "GH-694 control: the leaked record seeded a phantom task" || ok "GH-694 control: the leaked record is ignored — no phantom task"
grep -qE '^(undefined|GH-999|lane)\b' <<<"$(TICK_REPO_ROOT="$FX" "$TICK_BIN" next --agent pin2 2>/dev/null)" && bad "GH-694 control: tick next offers a phantom task from the leaked record" || ok "GH-694 control: tick next offers no phantom task"
TICK_REPO_ROOT="$FX" "$TICK_BIN" info GH267-PIN >/dev/null 2>&1 && ok "GH-694 control: a genuine task.* claim still projects beside the leaked record" || bad "GH-694 control: the filter dropped a genuine claim"
rm -f "$FX/.tick/events/$(basename "$EV")"

new_task_branch
for i in 1 2 3; do
  printf "c$i\n" >> "$FX/utils/py/foo.py"
  git -C "$FX" add -A && git -C "$FX" commit -qm "commit $i"
done
run_check > /dev/null 2> "$ERR" && bad "3 commits ahead must refuse" || { check_rule too-many-commits "$ERR" && ok "too-many-commits refusal (> 2 commits, GH-516)" || bad "too-many-commits rule"; }

new_task_branch; git -C "$FX" checkout -q development; printf "upstream change\n" >> "$FX/README.md"; git -C "$FX" add -A && git -C "$FX" commit -qm "upstream change"; git -C "$FX" push -q origin development; git -C "$FX" checkout -q task/gh-999
run_check > /dev/null 2> "$ERR" && bad "diverged branch must refuse" || { check_rule task-clone "$ERR" && ok "task-clone refusal on diverged branch (GH-516)" || bad "task-clone diverged rule"; }
git -C "$FX" checkout -q development; git -C "$FX" reset -q --hard HEAD~1; git -C "$FX" push -q --force origin development; git -C "$FX" checkout -q task/gh-999

new_task_branch; printf 'x\n' >> "$FX/relay-automation/consult.sh"
run_check > /dev/null 2> "$ERR" && bad "twin edit must refuse" || { check_rule frozen-twin "$ERR" && ok "frozen-twin refusal (GH-308)" || bad "frozen-twin rule"; }

new_task_branch; printf 'x\n' >> "$FX/relay-automation/relay-turn-lib.sh"
run_check > /dev/null 2> "$ERR" && bad "shared runtime edit must refuse" || { check_rule shared-runtime "$ERR" && ok "shared-runtime refusal (QA F4: not mislabeled frozen-twin)" || bad "shared-runtime rule"; }

new_task_branch; printf 'x\n' > "$FX/utils/py/leftover.py.orig"
run_check > /dev/null 2> "$ERR" && bad ".orig artifact must refuse" || { check_rule scratch "$ERR" && ok "scratch refusal for .orig (QA F2)" || bad ".orig scratch rule"; }

new_task_branch; printf 'x\n' >> "$FX/relay-automation/new-thing.sh"
run_check > /dev/null 2> "$ERR" && bad "new bash must refuse" || { check_rule no-new-bash "$ERR" && ok "no-new-bash refusal (GH-551)" || bad "no-new-bash rule"; }

new_task_branch; printf 'x\n' >> "$FX/src/project.js"
run_check > /dev/null 2> "$ERR" && bad "kernel surface must refuse" || { check_rule kernel-surface "$ERR" && ok "kernel-surface refusal" || bad "kernel-surface rule"; }

new_task_branch; printf 'x\n' >> "$FX/githooks/pre-push"
run_check > /dev/null 2> "$ERR" && bad "gate source edit must refuse" || { check_rule kernel-surface "$ERR" && ok "gate source is a refused safety surface" || bad "gate-source kernel rule"; }

new_task_branch; for i in 1 2 3 4 5; do printf 'x\n' > "$FX/utils/py/f$i.py"; done
run_check > /dev/null 2> "$ERR" && bad "5 files must refuse" || { check_rule too-many-files "$ERR" && ok "too-many-files refusal" || bad "too-many-files rule"; }

new_task_branch; printf 'x\n' >> "$FX/utils/py/foo.py"
run_check 999 test/gh999b-unreg.sh > /dev/null 2> "$ERR" && bad "unregistered suite must refuse" || { check_rule suite-unregistered "$ERR" && ok "suite-unregistered refusal" || bad "suite-unregistered rule"; }

new_task_branch; printf 'x\n' >> "$FX/utils/py/foo.py"
run_check 888 > /dev/null 2> "$ERR" && bad "closed issue must refuse" || { check_rule issue-closed "$ERR" && ok "issue-closed refusal (already-landed guard)" || bad "issue-closed rule"; }

new_task_branch; printf 'x\n' >> "$FX/utils/py/foo.py"; rm -f "$FX/.git/hooks/pre-push"
run_check > /dev/null 2> "$ERR" && bad "unwired gate must refuse" || { check_rule gate-unwired "$ERR" && ok "gate-unwired refusal (finding 3: hooks do not travel)" || bad "gate-unwired rule"; }
printf '#!/bin/sh\nexit 0\n' > "$FX/.git/hooks/pre-push" && chmod +x "$FX/.git/hooks/pre-push"
run_check > /dev/null 2> "$ERR" && bad "foreign no-op hook must not prove the gate" || { check_rule gate-unwired "$ERR" && ok "gate-unwired rejects an executable no-op impostor" || bad "gate identity rule"; }
rm -f "$FX/.git/hooks/pre-push" && (cd "$FX" && bash githooks/install.sh) >/dev/null

new_task_branch; printf 'x\n' >> "$FX/utils/py/foo.py"; printf 'hand edit\n' > "$FX/releases.sql"
run_check > /dev/null 2> "$ERR" && bad "hand-edited ledger must refuse" || { check_rule ledger-hand-edit "$ERR" && ok "ledger-hand-edit refusal (verbs only)" || bad "ledger-hand-edit rule"; }

new_task_branch; printf 'x\n' >> "$FX/utils/py/foo.py"; printf 'hand edit\n' > "$FX/RELEASES-PREVIEW.html"
run_check > /dev/null 2> "$ERR" && bad "hand-edited generated view must refuse" || { check_rule driver-output-hand-edit "$ERR" && ok "driver-output-hand-edit refusal (generated views are verb-owned)" || bad "driver-output-hand-edit rule"; }

echo "== happy path =="
new_task_branch; printf 'fixed\n' > "$FX/utils/py/foo.py"; printf '# demo suite v2\n' > "$FX/test/gh999-demo.sh"
OUT="$(run_check 999)"
grep -q "express-check: PASS" <<<"$OUT" && ok "legal fix passes" || bad "legal fix refused: $OUT"

# 1 and 2 local commits pass check (GH-516)
new_task_branch
printf 'precommitted 1\n' > "$FX/utils/py/foo.py"
git -C "$FX" add -A && git -C "$FX" commit -qm "local commit 1"
OUT="$(run_check 999)"
grep -q "express-check: PASS" <<<"$OUT" && ok "1 local commit passes check (GH-516)" || bad "1 local commit refused: $OUT"

printf 'precommitted 2\n' >> "$FX/utils/py/foo.py"
git -C "$FX" add -A && git -C "$FX" commit -qm "local commit 2"
OUT="$(run_check 999)"
grep -q "express-check: PASS" <<<"$OUT" && ok "2 local commits pass check (GH-516)" || bad "2 local commits refused: $OUT"

# multi-subsystem with <= 30 insertions across <= 2 files passes (auto-allow, GH-516)
new_task_branch
mkdir -p "$FX/config"
printf '{"key": "val"}\n' > "$FX/config/test.json"
printf 'fixed\n' > "$FX/utils/py/foo.py"
OUT="$(run_check 999)"
grep -q "express-check: PASS" <<<"$OUT" && ok "micro-diff multi-subsystem auto-allowed (GH-516)" || bad "micro-diff multi-subsystem refused: $OUT"

# multi-subsystem with > 30 insertions refuses without flag, passes with --allow-multi-subsystem (GH-516)
new_task_branch
mkdir -p "$FX/config"
python3 -c "print('\n'.join('line %d' % i for i in range(35)))" > "$FX/config/test.json"
printf 'fixed\n' > "$FX/utils/py/foo.py"
run_check > /dev/null 2> "$ERR" && bad "large multi-subsystem without flag must refuse" || { check_rule multi-subsystem "$ERR" && ok "multi-subsystem refusal without flag (GH-516)" || bad "multi-subsystem rule"; }
python3 "$DRIVER" --root "$FX" check --issue 999 --suite test/gh999-demo.sh --allow-multi-subsystem >/dev/null 2>"$ERR" \
  && ok "--allow-multi-subsystem permits multi-subsystem changes (GH-516)" || bad "--allow-multi-subsystem refused: $(cat "$ERR")"

new_task_branch; printf 'fixed\n' > "$FX/utils/py/foo.py"; for i in 1 2 3; do printf 'x\n' > "$FX/utils/py/g$i.py"; done; printf 'doc edit\n' > "$FX/README.md"
run_check > /dev/null 2> "$ERR" && bad "README must count against the file bound (finding 5)" || { check_rule too-many-files "$ERR" && ok "operator .md edits COUNT against the bound (finding 5)" || bad "README exempted: $(tail -1 "$ERR")"; }

new_task_branch; printf 'fixed\n' > "$FX/utils/py/foo.py"; printf 'entry\n' >> "$FX/CHANGELOG.md"
run_check > /dev/null 2> "$ERR" && ok "the lane's own paperwork (CHANGELOG) stays exempt" || bad "CHANGELOG counted against bounds: $(tail -1 "$ERR")"

echo "== docs born complete =="
# GH-592 I8: docs without --suite must refuse BEFORE any write (no half-born doc, no CHANGELOG mutation)
CL_BEFORE="$(shasum -a 256 "$FX/CHANGELOG.md")"
! python3 "$DRIVER" --root "$FX" docs --issue 999 --summary "demo" >/dev/null 2>"$ERR" && grep -q -- "--suite is required" "$ERR" && ok "docs refuses a missing --suite with an actionable message" || bad "docs accepted a missing --suite: $(tail -1 "$ERR")"
[ ! -f "$FX/PROJECT/2-WORKING/GH-999-DEMO-HOTFIX.md" ] && [ "$(shasum -a 256 "$FX/CHANGELOG.md")" = "$CL_BEFORE" ] && ok "docs without --suite wrote nothing" || bad "docs without --suite left a partial write"
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

echo "== run: end-to-end happy path (hermetic — stubbed gh/releases/reconcile) =="
new_task_branch; rm -f "$FX/PROJECT/2-WORKING/GH-999-DEMO-HOTFIX.md"; printf 'fixed\n' > "$FX/utils/py/foo.py"; printf '# demo suite v2\n' > "$FX/test/gh999-demo.sh"
issue_json OPEN "Demo hotfix" 999
RUNOUT="$(python3 "$DRIVER" --root "$FX" run --issue 999 --suite test/gh999-demo.sh --summary demo 2>"$ERR")"
if grep -Eq "express-land: commit [0-9a-f]+ pushed to development" <<<"$RUNOUT"; then
  ok "run accepts the full production projection set"
else
  bad "run failed: $(tail -2 "$ERR")"
fi
[ "$(git -C "$FX" branch --show-current)" = development ] && ok "closeout left the clone on development" || bad "clone not on development after run"
RECENT_LOG="$(git -C "$FX" log --format=%s -3)"
grep -q "express ship GH-999" <<<"$RECENT_LOG" && ok "ship transaction persisted before reconciliation" || bad "ship commit missing"
grep -q "express reconcile GH-999" <<<"$RECENT_LOG" && ok "reconcile persisted as a separate clean-tree transaction" || bad "reconcile commit missing"
grep -q '"state":"CLOSED"' "$GH_STATE/issue-999.json" && ok "run closed GitHub issue #999 before reconciling" || bad "run left issue #999 open"
[ -z "$(git -C "$FX" status --porcelain)" ] && ok "successful closeout leaves development clean" || bad "successful closeout left drift: $(git -C "$FX" status --short | tr '\n' ';')"
FIRED="$(ls "$FX/.tick/express/"*express-fired*.jsonl 2>/dev/null | head -1)"
[ -n "$FIRED" ] && ok "express-fired telemetry written on full success" || bad "express-fired telemetry missing"
TICK_REPO_ROOT="$FX" "$HERE/../bin/tick" project >/dev/null 2>"$ERR" && ok "tick project folded cleanly after express-fired telemetry (GH-694)" || { bad "tick project failed after express-fired telemetry (GH-694)"; cat "$ERR"; }
grep -qE '^- (GH-999|lane|undefined) ' "$FX/.tick/STATE.md" && bad "express-fired telemetry seeded a phantom task (GH-694)" || ok "no phantom task from express-fired telemetry (GH-694)"

echo "== GH-592: the landing writes its provenance receipt and reconciles under --gate =="
FIX_SHA="$(git -C "$FX" log --format=%H --grep='\[express\]' -1)"
RECEIPT_DIR="$(ls -d "$FX"/TESTS-RESULTS/*+GH-999-express 2>/dev/null | head -1)"
[ -n "$RECEIPT_DIR" ] && [ -f "$RECEIPT_DIR/provenance.jsonl" ] && ok "receipt file exists at TESTS-RESULTS/<date>+GH-999-express/provenance.jsonl" || bad "receipt file missing"
REC_CHECK="$(python3 - "$FX" "$FIX_SHA" <<'PY'
import json, os, sys
root, sha = sys.argv[1], sys.argv[2]
recs = []
for d, _, fs in os.walk(os.path.join(root, "TESTS-RESULTS")):
    if "provenance.jsonl" in fs:
        for line in open(os.path.join(d, "provenance.jsonl"), encoding="utf-8"):
            try: r = json.loads(line)
            except ValueError: continue
            if r.get("commit") == sha and r.get("case") == "express-landing": recs.append(r)
if len(recs) != 1: print("count=%d" % len(recs)); sys.exit(1)
r = recs[0]
ok = (r.get("command") == "bash test/gh999-demo.sh" and r.get("rc") == 0 and r.get("gate") == "express-suite"
      and r.get("result") == "pass" and r.get("issue") == 999)
print("ok" if ok else "bad:%s" % json.dumps(r)); sys.exit(0 if ok else 1)
PY
)"
[ "$REC_CHECK" = ok ] && ok "exactly one record for the landing sha: command/rc/gate/result/issue as specified" || bad "receipt record wrong: $REC_CHECK"
SHIP_COMMIT="$(git -C "$FX" log --format=%H --grep='express ship GH-999' -1)"
SHIP_STAT="$(git -C "$FX" show --stat --format= "$SHIP_COMMIT")"
grep -q 'GH-999-express/provenance.jsonl' <<<"$SHIP_STAT" && ok "ship transaction commits exactly the receipt" || bad "receipt not in ship commit"
grep -q "Provenance receipt matched for commit" <<<"$RUNOUT" && ok "gated reconcile outcome is printed in the landing output" || bad "gate outcome not visible: $RUNOUT"
grep -q "registered suite test/gh999-demo.sh green (express-suite, not the full gate)" "$FX/releases.sql" 2>/dev/null || true

# control (i): unrelated TESTS-RESULTS dirt appearing AFTER the clean-development check must refuse closeout
new_task_branch; rm -f "$FX/PROJECT/2-WORKING/GH-999-DEMO-HOTFIX.md"; printf 'fixed-inject\n' > "$FX/utils/py/foo.py"; printf '# demo suite v2i\n' > "$FX/test/gh999-demo.sh"
issue_json OPEN "Demo hotfix" 999
STUB_INJECT_PATH="$FX/TESTS-RESULTS/unrelated/provenance.jsonl" python3 "$DRIVER" --root "$FX" run --issue 999 --suite test/gh999-demo.sh --summary demo >/dev/null 2>"$ERR" \
  && bad "unrelated results dirt must refuse closeout" \
  || { grep -q "unexpected dirty path" "$ERR" && grep -q "TESTS-RESULTS/unrelated/provenance.jsonl" "$ERR" && ok "control (i): unrelated TESTS-RESULTS file refused by name; exact-path grant did not widen" || bad "control (i) wrong failure: $(tail -2 "$ERR")"; }
INJ_FIX_SHA="$(git -C "$FX" log --format=%H --grep='\[express\]' -1)"
[ "$(git -C "$REMOTE" rev-parse development)" = "$INJ_FIX_SHA" ] && ok "control (i): remote development == post-fix-push sha (no closeout commit landed)" || bad "control (i): closeout commits reached the remote"
rm -rf "$FX/TESTS-RESULTS/unrelated"; git -C "$FX" checkout -q -- . 2>/dev/null; git -C "$FX" clean -qfd -- TESTS-RESULTS 2>/dev/null || true

# control (ii): mutation — write_receipt returns the expected path WITHOUT writing → gate fails closed
new_task_branch; rm -f "$FX/PROJECT/2-WORKING/GH-999-DEMO-HOTFIX.md"; printf 'fixed-mut\n' > "$FX/utils/py/foo.py"; printf '# demo suite v2m\n' > "$FX/test/gh999-demo.sh"
issue_json OPEN "Demo hotfix" 999
python3 - "$DRIVER" "$FX" <<'PY' >/dev/null 2>"$ERR" && bad "no-write mutation must fail closed" || { grep -q "express-reconcile-failed" "$ERR" && grep -q "No provenance.jsonl" "$ERR" && ok "control (ii): driver without a real receipt write fails the gate (missing-receipt oracle reached)" || bad "control (ii) wrong failure: $(tail -2 "$ERR")"; }
import importlib.util, sys
spec = importlib.util.spec_from_file_location("express", sys.argv[1]); express = importlib.util.module_from_spec(spec); spec.loader.exec_module(express)
express.write_receipt = lambda root, sha, issue, suite, rc: "TESTS-RESULTS/mutant+GH-999-express/provenance.jsonl"
sys.argv = ["express.py", "--root", sys.argv[2], "run", "--issue", "999", "--suite", "test/gh999-demo.sh", "--summary", "demo"]
express.main()
PY
git -C "$FX" checkout -q development 2>/dev/null; git -C "$FX" reset -q --hard origin/development 2>/dev/null

echo "== four-step standalone flow (check / docs / ledger / land, each its own process) =="
# GH-278 review finding: SKILL.md documents this as an equally-valid alternative
# to `run` (steps 0-4 / 5 / 6 / 7-11), but `_expect_driver` only ever existed as
# an in-process attribute `run` set before calling cmd_land directly — a bare
# `land` process, invoked after separately-invoked `docs`/`ledger` steps, had no
# way to learn what those steps wrote and refused with ledger-hand-edit on its
# own driver's output. Pins that `cmd_land` recomputes the same allowlist itself.
new_task_branch; rm -f "$FX/PROJECT/2-WORKING/GH-999-DEMO-HOTFIX.md"; printf 'fixed-standalone-probe\n' > "$FX/utils/py/foo.py"; printf '# demo suite v2 standalone\n' > "$FX/test/gh999-demo.sh"
issue_json OPEN "Demo hotfix" 999
python3 "$DRIVER" --root "$FX" check --issue 999 --suite test/gh999-demo.sh >/dev/null 2>"$ERR" || bad "standalone check failed: $(cat "$ERR")"
python3 "$DRIVER" --root "$FX" docs --issue 999 --suite test/gh999-demo.sh --summary demo >/dev/null 2>"$ERR" || bad "standalone docs failed: $(cat "$ERR")"
python3 "$DRIVER" --root "$FX" ledger --issue 999 >/dev/null 2>"$ERR" || bad "standalone ledger failed: $(cat "$ERR")"
LANDOUT="$(python3 "$DRIVER" --root "$FX" land --issue 999 --suite test/gh999-demo.sh 2>"$ERR")"
if grep -Eq "express-land: commit [0-9a-f]+ pushed to development" <<<"$LANDOUT"; then
  ok "standalone land accepts what standalone docs/ledger already wrote (GH-278 review fix)"
else
  bad "standalone land refused its own driver's earlier docs/ledger output: $(tail -3 "$ERR")"
fi

echo "== run: TOCTOU — suite-generated drift never rides the commit (finding 4) =="
new_task_branch; rm -f "$FX/PROJECT/2-WORKING/GH-999-DEMO-HOTFIX.md"; printf 'fixed-drift-probe\n' > "$FX/utils/py/foo.py"
issue_json OPEN "Demo hotfix" 999
python3 "$DRIVER" --root "$FX" run --issue 999 --suite test/gh999-drift.sh --summary demo >/dev/null 2>"$ERR" \
  && bad "drift-writing suite must refuse" \
  || { check_rule tree-drift "$ERR" && ok "tree-drift refusal (finding 4: stage exactly what was qualified)" || bad "tree-drift rule: $(tail -1 "$ERR")"; }

new_task_branch; rm -f "$FX/PROJECT/2-WORKING/GH-999-DEMO-HOTFIX.md"; printf 'fixed-content-probe\n' > "$FX/utils/py/foo.py"
issue_json OPEN "Demo hotfix" 999
python3 "$DRIVER" --root "$FX" run --issue 999 --suite test/gh999-content-drift.sh --summary demo >/dev/null 2>"$ERR" \
  && bad "suite mutation of a qualified file must refuse" \
  || { check_rule tree-drift "$ERR" && ok "tree-drift detects changed bytes on an existing path" || bad "content tree-drift rule: $(tail -1 "$ERR")"; }

new_task_branch; rm -f "$FX/PROJECT/2-WORKING/GH-999-DEMO-HOTFIX.md"; printf 'fixed-hook-probe\n' > "$FX/utils/py/foo.py"
issue_json OPEN "Demo hotfix" 999
python3 "$DRIVER" --root "$FX" run --issue 999 --suite test/gh999-hook-drift.sh --summary demo >/dev/null 2>"$ERR" \
  && bad "suite replacement of the gate must refuse" \
  || { check_rule gate-unwired "$ERR" && ok "post-suite gate identity is re-proven before push" || bad "post-suite gate identity rule: $(tail -1 "$ERR")"; }

echo "== closeout failure receipt =="
new_task_branch; rm -f "$FX/PROJECT/2-WORKING/GH-999-DEMO-HOTFIX.md"; printf 'fixed\n' > "$FX/utils/py/foo.py"; printf '# demo suite v3\n' > "$FX/test/gh999-demo.sh"
issue_json OPEN "Demo hotfix" 999
WR_FAIL=1 python3 "$DRIVER" --root "$FX" run --issue 999 --suite test/gh999-demo.sh --summary demo >/dev/null 2>"$ERR" \
  && bad "forced reconcile failure must fail closed" \
  || { grep -q "express-reconcile-failed" "$ERR" && ok "SystemExit closeout failure is reported" || bad "closeout failure not reported"; }
FAILED_TICK="$(ls -t "$FX/.tick/express/"*express-reconcile-failed*.jsonl 2>/dev/null | head -1)"
[ -n "$FAILED_TICK" ] && grep -q '"verb": "express-reconcile-failed"' "$FAILED_TICK" && ok "every closeout failure writes its receipt" || bad "closeout failure tick missing"

echo "== dry-run mode (GH-516) =="
new_task_branch; rm -f "$FX/PROJECT/2-WORKING/GH-999-DEMO-HOTFIX.md"; printf 'fixed-dry\n' > "$FX/utils/py/foo.py"
issue_json OPEN "Demo hotfix" 999
DRYOUT="$(python3 "$DRIVER" --root "$FX" run --issue 999 --suite test/gh999-demo.sh --summary "dry run demo" --dry-run 2>"$ERR")"
grep -q "express-check \[dry-run\]: PASS" <<<"$DRYOUT" && ok "run --dry-run reports check pass" || bad "run --dry-run check missing: $DRYOUT"
grep -q "express-land \[dry-run\]: PASS" <<<"$DRYOUT" && ok "run --dry-run reports land pass" || bad "run --dry-run land missing: $DRYOUT"
[ ! -f "$FX/PROJECT/2-WORKING/GH-999-DEMO-HOTFIX.md" ] && ok "dry-run created no capture doc" || bad "dry-run created capture doc"
[ "$(git -C "$FX" branch --show-current)" = task/gh-999 ] && ok "dry-run left task branch intact" || bad "dry-run switched branch"
[ -z "$(git -C "$FX" status --porcelain=v1)" ] && bad "working tree changes were wiped by dry-run" || ok "dry-run preserved uncommitted working tree"

echo "== resume subcommand & central telemetry (GH-516) =="
new_task_branch; rm -f "$FX/PROJECT/2-WORKING/GH-999-DEMO-HOTFIX.md"; printf 'fixed-resume\n' > "$FX/utils/py/foo.py"
issue_json OPEN "Demo hotfix" 999

# --- Rejection 1: Unrelated dirty files on task branch ---
touch "$FX/unrelated-task-dirty.txt"
! python3 "$DRIVER" --root "$FX" resume --issue 999 --suite test/gh999-demo.sh 2>"$ERR" && ok "resume rejects dirty working tree on task branch" || bad "resume accepted dirty tree on task branch"
grep -q "working tree is not clean" "$ERR" && ok "dirty task tree error reported" || bad "dirty task tree error missing: $(cat "$ERR")"
rm -f "$FX/unrelated-task-dirty.txt"

# --- Rejection 2: Unrelated dirty files on development ---
git -C "$FX" checkout -q development
touch "$FX/unrelated-dev-dirty.txt"
! python3 "$DRIVER" --root "$FX" resume --issue 999 --suite test/gh999-demo.sh 2>"$ERR" && ok "resume rejects dirty working tree on development" || bad "resume accepted dirty tree on development"
grep -q "working tree is not clean" "$ERR" && ok "dirty development tree error reported" || bad "dirty dev tree error missing: $(cat "$ERR")"
rm -f "$FX/unrelated-dev-dirty.txt"
git -C "$FX" checkout -q task/gh-999

# --- Setup for Happy Path 1: Interruption immediately after landing push ---
# Generate doc and dial into manifest before committing
python3 "$DRIVER" --root "$FX" docs --issue 999 --suite test/gh999-demo.sh --summary "resume demo" >/dev/null 2>"$ERR" || bad "docs failed: $(cat "$ERR")"
python3 "$DRIVER" --root "$FX" ledger --issue 999 >/dev/null 2>"$ERR" || bad "ledger failed: $(cat "$ERR")"
git -C "$FX" add -A && git -C "$FX" commit -qm "fix(GH-999): simulated landing for resume [express]

Closes #999"
LAND_SHA="$(git -C "$FX" rev-parse HEAD)"
git -C "$FX" push -q origin HEAD:development

# --- Rejection 3: Unpushed / unreachable SHA passed to --sha ---
git -C "$FX" commit --allow-empty -qm "local only unpushed commit"
LOCAL_SHA="$(git -C "$FX" rev-parse HEAD)"
git -C "$FX" reset -q --hard HEAD~1
! python3 "$DRIVER" --root "$FX" resume --issue 999 --suite test/gh999-demo.sh --sha "$LOCAL_SHA" 2>"$ERR" && ok "resume rejects unpushed/unreachable SHA" || bad "resume accepted unpushed SHA"
grep -q "not reachable from origin/development" "$ERR" && ok "unreachable SHA error reported" || bad "unreachable SHA error missing: $(cat "$ERR")"

# --- Rejection 4: Unrelated commit SHA passed to --sha (no closing reference for issue) ---
git -C "$FX" commit --allow-empty -qm "fix(GH-888): unrelated issue landing [express]

Closes #888"
git -C "$FX" push -q origin HEAD:development
UNRELATED_SHA="$(git -C "$FX" rev-parse HEAD)"
! python3 "$DRIVER" --root "$FX" resume --issue 999 --suite test/gh999-demo.sh --sha "$UNRELATED_SHA" 2>"$ERR" && ok "resume rejects unrelated commit SHA" || bad "resume accepted unrelated SHA"
grep -q "does not close issue #999" "$ERR" && ok "unrelated SHA error reported" || bad "unrelated SHA error missing: $(cat "$ERR")"

# --- Rejection 5: Neighboring issue collision in auto-resolution (GH-99 vs GH-999) ---
# origin/development contains commit for GH-999; auto-resolution for GH-99 must NOT match GH-999
! python3 "$DRIVER" --root "$FX" resume --issue 99 --suite test/gh999-demo.sh 2>"$ERR" && ok "auto-resolution for GH-99 does not match GH-999" || bad "auto-resolution matched GH-999 for GH-99"
grep -q "Could not automatically resolve landing commit for GH-99" "$ERR" && ok "neighboring issue 99 reported unresolved" || bad "unresolved error missing: $(cat "$ERR")"

# --- GH-592 control (iii): no receipt for the landing → resume refuses BEFORE closing/shipping, with the recipe ---
! python3 "$DRIVER" --root "$FX" resume --issue 999 --suite test/gh999-demo.sh 2>"$ERR" && ok "control (iii): resume refuses a landing with no valid receipt" || bad "resume accepted a landing with no receipt"
grep -q "no COMMITTED valid express receipt bound to commit" "$ERR" && grep -q "write_receipt" "$ERR" && grep -q "skills/2-daily/express/SKILL.md" "$ERR" && grep -q "fails closed" "$ERR" && grep -q "VOIDs on any difference" "$ERR" && ok "control (iii): refusal carries the recovery recipe incl. identity snapshot" || bad "recipe missing: $(tail -1 "$ERR")"
grep -q '"state":"OPEN"' "$GH_STATE/issue-999.json" && ok "control (iii): issue #999 still OPEN — refused before close" || bad "resume closed the issue without evidence"
# --- GH-592 control (iv): failed / wrong-suite / wrong-issue records are not evidence ---
git -C "$FX" checkout -q development; git -C "$FX" pull -q --ff-only origin development
BADDIR="$FX/TESTS-RESULTS/$(date -u +%F)+GH-999-express"; mkdir -p "$BADDIR"
python3 - "$BADDIR/provenance.jsonl" "$LAND_SHA" <<'PY'
import json, sys
p, sha = sys.argv[1], sys.argv[2]
base = {"commit": sha, "issue": 999, "case": "express-landing", "gate": "express-suite", "command": "bash test/gh999-demo.sh", "rc": 0, "result": "pass"}
with open(p, "w") as f:
    f.write(json.dumps({**base, "rc": 1, "result": "fail"}) + "\n")
    f.write(json.dumps({**base, "command": "bash test/other.sh"}) + "\n")
    f.write(json.dumps({**base, "issue": 998}) + "\n")
    f.write("not json\n")
PY
git -C "$FX" add -A && git -C "$FX" commit -qm "fixture: invalid receipts for GH-999" && git -C "$FX" push -q origin development
! python3 "$DRIVER" --root "$FX" resume --issue 999 --suite test/gh999-demo.sh 2>"$ERR" && ok "control (iv): rc=1 / wrong-suite / wrong-issue / malformed records are not evidence" || bad "resume accepted invalid receipts"
# --- GH-592 control (vi): a valid receipt that is only in an IGNORED path (uncommitted) is not evidence ---
git -C "$FX" checkout -q development
python3 - "$DRIVER" "$FX" "$LAND_SHA" <<'PY'
import importlib.util, sys, os, json
spec = importlib.util.spec_from_file_location("express", sys.argv[1]); express = importlib.util.module_from_spec(spec); spec.loader.exec_module(express)
os.makedirs(os.path.join(sys.argv[2], "TESTS-RESULTS/.relay-scratch"), exist_ok=True)
rec = {"commit": sys.argv[3], "issue": 999, "case": "express-landing", "gate": "express-suite", "command": "bash test/gh999-demo.sh", "rc": 0, "result": "pass"}
assert express.valid_express_receipt(rec, sys.argv[3], 999, "test/gh999-demo.sh")
open(os.path.join(sys.argv[2], "TESTS-RESULTS/.relay-scratch/provenance.jsonl"), "w").write(json.dumps(rec) + "\n")
PY
[ -z "$(git -C "$FX" status --porcelain=v1)" ] && ok "control (vi): ignored receipt leaves porcelain clean (the guard alone would not catch it)" || bad "fixture ignore rule not applied"
! python3 "$DRIVER" --root "$FX" resume --issue 999 --suite test/gh999-demo.sh 2>"$ERR" && grep -q "no COMMITTED valid express receipt" "$ERR" && ok "control (vi): uncommitted (ignored-path) valid receipt is refused — evidence is read from HEAD" || bad "resume accepted an uncommitted receipt: $(tail -1 "$ERR")"
rm -rf "$FX/TESTS-RESULTS/.relay-scratch"
# --- GH-592 control (vii): a committed receipt whose only identity is an explicit PR field is not express evidence ---
python3 - "$FX" "$LAND_SHA" <<'PY'
import json, sys, glob
p = glob.glob(sys.argv[1] + "/TESTS-RESULTS/*+GH-999-express/provenance.jsonl")[0]
rec = {"commit": sys.argv[2], "pr": 4242, "issue": 999, "case": "express-landing", "gate": "express-suite", "command": "bash test/gh999-demo.sh", "rc": 0, "result": "pass"}
open(p, "a").write(json.dumps(rec) + "\n")
PY
git -C "$FX" add -A && git -C "$FX" commit -qm "fixture: pr-identified record for GH-999" && git -C "$FX" push -q origin development
! python3 "$DRIVER" --root "$FX" resume --issue 999 --suite test/gh999-demo.sh 2>"$ERR" && ok "control (vii): a record carrying an explicit pr field is not express evidence (matches the real matcher's conflict rule)" || bad "resume accepted a pr-identified record"
# --- GH-592 control (viii): a COMMITTED symlink named provenance.jsonl is not evidence (HEAD reader skips mode 120000) ---
git -C "$FX" checkout -q development
python3 - "$FX" "$LAND_SHA" <<'PY'
import json, sys, os
root, sha = sys.argv[1], sys.argv[2]
rec = {"commit": sha, "issue": 999, "case": "express-landing", "gate": "express-suite", "command": "bash test/gh999-demo.sh", "rc": 0, "result": "pass"}
open(os.path.join(root, "outside-evidence.jsonl"), "w").write(json.dumps(rec) + "\n")
os.makedirs(os.path.join(root, "TESTS-RESULTS/0-linked"), exist_ok=True)
os.symlink("../../outside-evidence.jsonl", os.path.join(root, "TESTS-RESULTS/0-linked/provenance.jsonl"))
PY
git -C "$FX" add -A && git -C "$FX" commit -qm "fixture: committed symlink receipt for GH-999" && git -C "$FX" push -q origin development
! python3 "$DRIVER" --root "$FX" resume --issue 999 --suite test/gh999-demo.sh 2>"$ERR" && grep -q "no COMMITTED valid express receipt" "$ERR" && ok "control (viii): a committed symlinked provenance.jsonl is not evidence for resume" || bad "resume accepted a committed symlink receipt: $(tail -1 "$ERR")"
git -C "$FX" rm -q -r TESTS-RESULTS/0-linked outside-evidence.jsonl && git -C "$FX" commit -qm "fixture: drop symlink receipt" && git -C "$FX" push -q origin development
# --- GH-592 control (v): genuine interrupted success — valid receipt written by the driver's own helper and committed, reconcile never ran ---
python3 - "$DRIVER" "$FX" "$LAND_SHA" <<'PY'
import importlib.util, sys
spec = importlib.util.spec_from_file_location("express", sys.argv[1]); express = importlib.util.module_from_spec(spec); spec.loader.exec_module(express)
print(express.write_receipt(sys.argv[2], sys.argv[3], 999, "test/gh999-demo.sh", 0))
PY
git -C "$FX" add -A && git -C "$FX" commit -qm "fixture: valid receipt for GH-999 landing" && git -C "$FX" push -q origin development
git -C "$FX" checkout -q task/gh-999
# --- Happy Path 1: Resume from task branch without --sha (auto-resolves LAND_SHA); bare suite name must normalize (I4) ---
python3 "$DRIVER" --root "$FX" resume --issue 999 --suite gh999-demo.sh >"$WORK/resume.log" 2>"$ERR" && ok "express resume exits 0 on valid landing" || bad "express resume failed (rc!=0): $(cat "$ERR")"
grep -q "Provenance receipt matched for commit" "$WORK/resume.log" && ok "control (v): resume reconciled under --gate against the committed receipt" || bad "resume gate outcome not printed"
[ "$(git -C "$FX" branch --show-current)" = development ] && ok "resume switched to development" || bad "resume branch wrong"
[ -z "$(git -C "$FX" status --porcelain=v1)" ] && ok "development working tree is clean after resume" || bad "development dirty after resume: $(git -C "$FX" status --porcelain=v1)"
grep -q '"state":"CLOSED"' "$GH_STATE/issue-999.json" && ok "resume closed GitHub issue #999" || bad "issue #999 remained open"
M_STATE="$(python3 -c "import sqlite3; c=sqlite3.connect('$FX/releases.db'); print(c.execute('SELECT state FROM manifest_items WHERE issue_ref_id=1').fetchone()[0])")"
[ "$M_STATE" = "shipped" ] && ok "resume shipped manifest item in releases.db" || bad "manifest item state: $M_STATE"
[ ! -f "$FX/PROJECT/2-WORKING/GH-999-DEMO-HOTFIX.md" ] && [ -f "$FX/PROJECT/3-COMPLETED/GH-999-DEMO-HOTFIX.md" ] && ok "resume reconciled active doc to 3-COMPLETED" || bad "active doc not reconciled"
REMOTE_DEV_SHA="$(git -C "$REMOTE" rev-parse development)"
LOCAL_DEV_SHA="$(git -C "$FX" rev-parse HEAD)"
[ "$REMOTE_DEV_SHA" = "$LOCAL_DEV_SHA" ] && ok "resume persisted and pushed closeout to origin/development" || bad "remote development out of sync"
RESUMED_TICK="$(ls -t "$FX/.tick/express/"*express-resumed*.jsonl 2>/dev/null | head -1)"
[ -n "$RESUMED_TICK" ] && ok "express-resumed event receipt written" || bad "express-resumed tick missing"
TICK_REPO_ROOT="$FX" "$HERE/../bin/tick" project >/dev/null 2>"$ERR" && ok "tick project folded cleanly after express-resumed telemetry (GH-694)" || bad "tick project failed after express-resumed telemetry: $(cat "$ERR")"
grep -qE '^- (GH-999|lane) ' "$FX/.tick/STATE.md" && bad "express telemetry seeded a phantom task (GH-694)" || ok "no phantom task from express-resumed telemetry (GH-694)"

# --- Happy Path 2: Idempotent second resume ---
RECEIPT_LINES_BEFORE="$(cat "$FX"/TESTS-RESULTS/*+GH-999-express/provenance.jsonl | wc -l | tr -d ' ')"
HEAD_BEFORE="$(git -C "$FX" rev-parse HEAD)"
python3 "$DRIVER" --root "$FX" resume --issue 999 --suite test/gh999-demo.sh >"$WORK/resume2.log" 2>"$ERR" && ok "second resume invocation succeeds idempotently" || bad "second resume failed: $(cat "$ERR")"
[ "$(cat "$FX"/TESTS-RESULTS/*+GH-999-express/provenance.jsonl | wc -l | tr -d ' ')" = "$RECEIPT_LINES_BEFORE" ] && ok "control (v): second resume wrote no new receipt record" || bad "second resume appended a record"
[ "$(git -C "$FX" rev-parse HEAD)" = "$LOCAL_DEV_SHA" ] && ok "idempotent resume created no spurious commits" || bad "second resume created extra commits"

# --- Happy Path 3: Interruption immediately after ship commit (post-ship recovery without --sha) ---
new_task_branch; rm -f "$FX/PROJECT/2-WORKING/GH-998-DEMO-HOTFIX.md"; printf 'fixed-998\n' > "$FX/utils/py/foo.py"
issue_json OPEN "Demo 998" 998
mkdir -p "$FX/PROJECT/2-WORKING"
printf '# Doc 998\n' > "$FX/PROJECT/2-WORKING/GH-998-DEMO-HOTFIX.md"
git -C "$FX" add -A && git -C "$FX" commit -qm "fix(GH-998): demo 998 landing [express]

Closes #998"
LAND_998_SHA="$(git -C "$FX" rev-parse HEAD)"
git -C "$FX" push -q origin HEAD:development
git -C "$FX" checkout -q development
git -C "$FX" pull -q --ff-only origin development
# Simulate that ship was already committed and pushed, but wave_reconcile was interrupted
python3 -c "import sqlite3; c=sqlite3.connect('$FX/releases.db'); c.execute('UPDATE manifest_items SET state=\"shipped\" WHERE issue_ref_id=2'); c.commit(); c.close()"
# GH-592: the ship transaction carries the landing's receipt (written by the driver's own helper)
python3 - "$DRIVER" "$FX" "$LAND_998_SHA" <<'PY'
import importlib.util, sys
spec = importlib.util.spec_from_file_location("express", sys.argv[1]); express = importlib.util.module_from_spec(spec); spec.loader.exec_module(express)
print(express.write_receipt(sys.argv[2], sys.argv[3], 998, "test/gh998-demo.sh", 0))
PY
git -C "$FX" add -A && git -C "$FX" commit -qm "chore(releases): express ship GH-998 (commit $LAND_998_SHA)"
git -C "$FX" push -q origin development
# Resume issue 998 WITHOUT --sha — must parse landing SHA from ship commit and complete reconciliation
python3 "$DRIVER" --root "$FX" resume --issue 998 --suite test/gh998-demo.sh >"$WORK/resume998.log" 2>"$ERR" && ok "resume after ship commit succeeds without --sha" || bad "post-ship resume failed: $(cat "$ERR")"
[ ! -f "$FX/PROJECT/2-WORKING/GH-998-DEMO-HOTFIX.md" ] && [ -f "$FX/PROJECT/3-COMPLETED/GH-998-DEMO-HOTFIX.md" ] && ok "post-ship resume reconciled doc to 3-COMPLETED" || bad "post-ship doc not reconciled"

# --- Falsification check: Deliberate failure during reconciliation under WR_FAIL=1 ---
new_task_branch; printf 'fixed-fail\n' > "$FX/utils/py/foo.py"
issue_json OPEN "Fail hotfix" 997
mkdir -p "$FX/PROJECT/2-WORKING"
printf '# Doc 997\n' > "$FX/PROJECT/2-WORKING/GH-997-FAIL.md"
git -C "$FX" add -A && git -C "$FX" commit -qm "fix(GH-997): fail landing [express]

Closes #997"
FAIL_SHA="$(git -C "$FX" rev-parse HEAD)"
git -C "$FX" push -q origin HEAD:development
git -C "$FX" checkout -q development
git -C "$FX" pull -q --ff-only origin development
# GH-592: give the landing a valid committed receipt so this case reaches the reconciler (not the evidence gate)
python3 - "$DRIVER" "$FX" "$FAIL_SHA" <<'PY'
import importlib.util, sys
spec = importlib.util.spec_from_file_location("express", sys.argv[1]); express = importlib.util.module_from_spec(spec); spec.loader.exec_module(express)
print(express.write_receipt(sys.argv[2], sys.argv[3], 997, "test/gh997-demo.sh", 0))
PY
git -C "$FX" add -A && git -C "$FX" commit -qm "fixture: receipt for GH-997" && git -C "$FX" push -q origin development
! WR_FAIL=1 python3 "$DRIVER" --root "$FX" resume --issue 997 --suite test/gh997-demo.sh --sha "$FAIL_SHA" 2>"$ERR" && grep -q "forced reconcile failure" "$ERR" && ok "resume fails when reconciliation fails (falsifiable)" || bad "resume succeeded despite reconcile failure"

# Verify central telemetry mirroring
CENTRAL_TICK="$(ls -t "$HOME/.config/xyz/events/"*express*.jsonl 2>/dev/null | head -1)"
[ -n "$CENTRAL_TICK" ] && ok "central telemetry mirrored to ~/.config/xyz/events" || bad "central telemetry missing from $HOME/.config/xyz/events"

echo "== source audit (direct landing) =="
LAND_BODY="$(sed -n '/^def cmd_land/,/^def active_release/p' "$DRIVER")"
grep -q '"push", "origin", "HEAD:development"' <<<"$LAND_BODY" && ok "landing is a direct fast-forward push" || bad "direct development push missing"
[ -z "$(printf '%s' "$LAND_BODY" | grep -n 'pr.*create\|pr.*merge')" ] && ok "landing creates no ghost PR" || bad "ghost PR call remains"
grep -q "def cmd_resume" "$DRIVER" && ok "cmd_resume implemented" || bad "cmd_resume missing"

echo
echo "gh267-express-skill: pass=$PASS fail=$FAIL"
# cleanup mirrors gh1-adoption-guard: the guard refuses the bare sandbox root
# by design, so teardown uses the plain -d check
[ -n "$WORK" ] && [ -d "$WORK" ] && rm -rf "$WORK"
[ "$FAIL" -eq 0 ]
