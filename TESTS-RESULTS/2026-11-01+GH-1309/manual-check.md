# GH-1309 manual check: `sync.py --migrate-legacy`

- **Code tested:** `190be352` on `feat/XYZ-forge-gh1309-sa-migrate-legacy-2026-11-01` (base `cb1bf933`). Docs-only commits follow it.
- **Runner:** local macOS, Python 3, `bash` script below. It builds a throwaway collection and two app roots under
  `$TMPDIR`, with `HOME` pointed at a fixture directory, so no real app root or collection is read or written.
  The script lives here as text only: GH-831 forbids adding a test file or registry entry.
- **Red control A** runs the base scripts (`origin/development`) against the same fixture.
- **Existing suite:** `bash test/skills-army-hq.sh` → `33 passed, 4 subtests passed` at `190be352` (and at the
  pre-edit checkpoint `6d646538`).

## Result: 36 pass, 0 fail

Verbatim output of `bash check.sh <clone> origin/development` (run 3; run 1 failed one message-text check
that expected the wrong error string, run 2 failed only the clean-tree check because a one-line edit was
uncommitted; both are fixed, and the code edit in between removed a redundant name comparison):

```text
== setup
PASS  setup: all links in place (rc 0)
PASS  setup: app1/alpha is a link to the collection
== red control A: base scripts (origin/development) cannot do it
PASS  A1: base rejects --migrate-legacy (rc 2, unrecognized arguments)
PASS  A2: base preview reports 'Foreign real entry preserved' for app1/alpha
== refusals leave the folder alone
PASS  R1: preview without --archive-legacy refuses (rc 2, names --archive-legacy)
PASS  R2: apply without --archive-legacy refuses (rc 2)
PASS  R2: folder is still a real directory, content intact
PASS  R2: no backup ZIP was taken
PASS  R3: --archive-legacy alone refuses (rc 2, message)
PASS  R4: --migrate-legacy with --retire-trinity refuses (rc 2)
== main path: stale real folder
PASS  P1: preview rc 0
PASS  P2: preview reports migrate_legacy with matches_managed false
PASS  P3: preview changed nothing (still a real directory, no ZIP)
PASS  M1: apply rc 0
PASS  M2: app1/alpha is now the owned link into the collection
PASS  M3: a verified ZIP holds the legacy folder (files, mode, internal link)
PASS  M4: the folder is retained in .staging/<op>/retired with its content
PASS  M5: the change record names the backup
PASS  M6: other app untouched (app2/alpha still the owned link)
PASS  M7: --status afterwards is clean (rc 0, no errors)
PASS  M8: history records the migration
== adjacent: repeat the same command
PASS  Q1: repeat refuses loudly (rc 2, 'nothing to migrate')
PASS  Q2: repeat took no new ZIP and staged nothing; link intact
PASS  Q3: an unknown skill name is an error, not a no-op (rc 2, 'Not a deployed skill')
== adjacent: copy identical to the managed one
PASS  B1: preview reports matches_managed true
PASS  B2: apply rc 0 and the link is in place
== adjacent: folder whose frontmatter name differs
PASS  N1: refused (rc 2, 'Folder/name mismatch: gamma != other')
PASS  N2: folder untouched, no gamma ZIP
== replay: every action applied twice (a crash after the link, then recovery)
replay: second pass was a no-op; link intact
PASS  Y1: replay of retire-directory then link is a no-op
== red controls B and C: forged recovery receipts
PASS  B0 positive control, deployed skill in an app root: accepted
PASS  B1 root = the collection: Retirement root overlaps collection
PASS  B2 root inside the collection: Retirement root overlaps collection
PASS  B3 root is the collection's parent: Retirement root overlaps collection
PASS  C1 name is neither trinity nor a deployed skill: Invalid retirement
PASS  C2 trinity name still accepted in an app root: accepted
== repository untouched
PASS  T1: task clone worktree has no changes from this run
RESULT pass=36 fail=0 (workdir /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/gh1309-check.HCFkbI)
```

## What each group shows

| Group | Shows |
|---|---|
| A1, A2 (red) | The base scripts reject `--migrate-legacy` and still report `Foreign real entry preserved`: the gap is real |
| R1-R4 | Without `--archive-legacy`, with `--archive-legacy` alone, or combined with `--retire-trinity`: refused, folder and backups untouched |
| P1-P3 | Preview changes nothing and reports `matches_managed: false` for a stale copy |
| M1-M8 | Apply: owned link in place, verified ZIP (files, mode 755, internal symlink), folder retained in `.staging/<op>/retired`, other app untouched, `--status` clean, history entry |
| Q1-Q3 | Repeat run is a loud refusal with nothing new taken; an unknown skill name is an error |
| B1-B2 | A copy identical to the managed one reports `matches_managed: true` and migrates |
| N1-N2 | A folder whose frontmatter name differs from its folder is refused (`Folder/name mismatch`), untouched, no ZIP |
| Y1 | Replay: the retire and link actions each applied twice, second pass is a no-op |
| B0-C2 (receipts) | A forged `retire-directory` is rejected for a root equal to, inside, or above the collection and for a name that is neither trinity nor deployed; the legitimate shape and the trinity name are accepted |
| T1 | The task clone's worktree is unchanged by the run |

## Not verified here

The real `~/.claude/skills/xyz` was not touched. It needs this change merged and the deployed manager updated
first. A real cross-device move was not exercised (the guard is a `st_dev` comparison on the same code path
`--retire-trinity` already uses).

## The script

```bash
#!/usr/bin/env bash
# GH-1309 manual check: throwaway collection and app roots, fixture HOME. Nothing real is touched.
# usage: check.sh <task clone> [base ref for red control A]
set -u
CLONE="$1"; BASE_REF="${2:-origin/development}"
B="$CLONE/skills/3-weekly/skills-army-hq"
W="$(mktemp -d "${TMPDIR:-/tmp}/gh1309-check.XXXXXX")"; W="$(cd "$W" && pwd -P)"
export HOME="$W/home" PYTHONDONTWRITEBYTECODE=1; mkdir -p "$HOME"; unset XYZ_FORGE_ROOT XYZ_SKILLS_ROOT
REPO="$W/repo"; ROOT="$W/Documents/Deployed Skills"; A1="$W/app1"; A2="$W/app2"
PASS=0; FAIL=0
ok() { if [ "$2" = 0 ]; then PASS=$((PASS+1)); echo "PASS  $1"; else FAIL=$((FAIL+1)); echo "FAIL  $1"; fi; }
cond() { local d="$1"; shift; "$@" >/dev/null 2>&1; ok "$d" $?; }
intake() { python3 -B "$REPO/skills/skills-army-hq/scripts/intake.py" --root "$ROOT" "$@"; }
sync() { python3 -B "$ROOT/sync.py" --root "$ROOT" "$@"; }
G=/usr/bin/grep
legacy() {  # app skill content [frontmatter-name]
  unlink "$1/$2" 2>/dev/null
  mkdir "$1/$2"
  printf -- "---\nname: %s\ndescription: Stale.\n---\n\n%s\n" "${4:-$2}" "$3" > "$1/$2/SKILL.md"
  printf 'old\n' > "$1/$2/old.txt"; chmod 755 "$1/$2/old.txt"; ln -s old.txt "$1/$2/old-link"
}
jfield() { python3 -B -c "import json,sys;d=json.load(open(sys.argv[1]));print(eval(sys.argv[2]))" "$1" "$2"; }

echo "== setup"
mkdir -p "$REPO/skills" "$A1" "$A2"
rsync -a --exclude __pycache__ --exclude '*.pyc' "$B/" "$REPO/skills/skills-army-hq/"
git -C "$REPO" init -q; git -C "$REPO" -c user.name=F -c user.email=f@example.invalid commit --allow-empty -qm fixture
for n in alpha beta gamma delta; do
  mkdir -p "$REPO/skills/$n"; printf -- "---\nname: %s\ndescription: Fixture.\n---\n\nCurrent.\n" "$n" > "$REPO/skills/$n/SKILL.md"
done
intake --apply init >/dev/null 2>&1 || { echo "setup failed: init"; exit 9; }
for n in alpha beta gamma delta; do intake --apply add "$REPO/skills/$n" >/dev/null 2>&1 || { echo "setup failed: add $n"; exit 9; }; done
intake --apply targets --id app1 --path "$A1" --consumer app1 >/dev/null 2>&1 || exit 9
intake --apply targets --id app2 --path "$A2" --consumer app2 >/dev/null 2>&1 || exit 9
sync --apply >/dev/null 2>&1; ok "setup: all links in place (rc 0)" $?
cond "setup: app1/alpha is a link to the collection" test "$(readlink "$A1/alpha")" = "$ROOT/alpha"

echo "== red control A: base scripts ($BASE_REF) cannot do it"
mkdir -p "$W/base/scripts"
for f in intake.py sync.py; do git -C "$CLONE" show "$BASE_REF:skills/3-weekly/skills-army-hq/scripts/$f" > "$W/base/scripts/$f"; done
legacy "$A1" alpha "Stale."
python3 -B "$W/base/scripts/sync.py" --root "$ROOT" --migrate-legacy alpha --archive-legacy >"$W/ra.out" 2>"$W/ra.err"; rc=$?
cond "A1: base rejects --migrate-legacy (rc 2, unrecognized arguments)" bash -c "[ $rc = 2 ] && $G -q 'unrecognized arguments' '$W/ra.err'"
python3 -B "$W/base/scripts/sync.py" --root "$ROOT" >"$W/rb.out" 2>/dev/null
cond "A2: base preview reports 'Foreign real entry preserved' for app1/alpha" $G -q "Foreign real entry preserved" "$W/rb.out"

echo "== refusals leave the folder alone"
sync --migrate-legacy alpha >"$W/r1.out" 2>"$W/r1.err"; rc=$?
cond "R1: preview without --archive-legacy refuses (rc 2, names --archive-legacy)" bash -c "[ $rc = 2 ] && $G -q 'explicitly select --archive-legacy' '$W/r1.out'"
sync --apply --migrate-legacy alpha >"$W/r2.out" 2>"$W/r2.err"; rc=$?
cond "R2: apply without --archive-legacy refuses (rc 2)" test $rc = 2
cond "R2: folder is still a real directory, content intact" bash -c "[ -d '$A1/alpha' ] && [ ! -L '$A1/alpha' ] && [ -f '$A1/alpha/old.txt' ]"
cond "R2: no backup ZIP was taken" bash -c "! ls '$ROOT'/backups/alpha-*.zip"
sync --archive-legacy >"$W/r3.out" 2>"$W/r3.err"; rc=$?
cond "R3: --archive-legacy alone refuses (rc 2, message)" bash -c "[ $rc = 2 ] && $G -q 'requires --retire-trinity or --migrate-legacy' '$W/r3.err'"
sync --migrate-legacy alpha --retire-trinity "$REPO/skills/alpha" >"$W/r4.out" 2>"$W/r4.err"; rc=$?
cond "R4: --migrate-legacy with --retire-trinity refuses (rc 2)" bash -c "[ $rc = 2 ] && $G -q 'cannot be combined' '$W/r4.err'"

echo "== main path: stale real folder"
sync --migrate-legacy alpha --archive-legacy >"$W/p.json" 2>"$W/p.err"; rc=$?
cond "P1: preview rc 0" test $rc = 0
cond "P2: preview reports migrate_legacy with matches_managed false" bash -c "python3 -B -c \"import json;d=json.load(open('$W/p.json'));c=[x for x in d['changes'] if 'migrate_legacy' in x];assert len(c)==1 and c[0]['matches_managed'] is False and not any('backup' in x for x in c)\""
cond "P3: preview changed nothing (still a real directory, no ZIP)" bash -c "[ -d '$A1/alpha' ] && [ ! -L '$A1/alpha' ] && ! ls '$ROOT'/backups/alpha-*.zip"
sync --apply --migrate-legacy alpha --archive-legacy >"$W/m.json" 2>"$W/m.err"; rc=$?
cond "M1: apply rc 0" test $rc = 0
cond "M2: app1/alpha is now the owned link into the collection" test "$(readlink "$A1/alpha")" = "$ROOT/alpha"
cond "M3: a verified ZIP holds the legacy folder (files, mode, internal link)" python3 -B -c "
import glob,zipfile,stat,sys
z=glob.glob(sys.argv[1]+'/backups/alpha-*.zip'); assert len(z)==1,z
f=zipfile.ZipFile(z[0]); assert f.testzip() is None
n={i.filename:i for i in f.infolist()}
assert 'alpha/old.txt' in n and 'alpha/old-link' in n and 'alpha/SKILL.md' in n
assert stat.S_IFMT(n['alpha/old-link'].external_attr>>16)==stat.S_IFLNK
assert stat.S_IMODE(n['alpha/old.txt'].external_attr>>16)==0o755
assert f.read('alpha/old-link').decode()=='old.txt'
assert b'Stale.' in f.read('alpha/SKILL.md')" "$ROOT"
cond "M4: the folder is retained in .staging/<op>/retired with its content" bash -c "ls '$ROOT'/.staging/*/retired/old.txt && $G -q 'Stale.' '$ROOT'/.staging/*/retired/SKILL.md"
cond "M5: the change record names the backup" bash -c "python3 -B -c \"import json;d=json.load(open('$W/m.json'));assert any(x.get('backup','').startswith('backups/alpha-') for x in d['changes'])\""
cond "M6: other app untouched (app2/alpha still the owned link)" test "$(readlink "$A2/alpha")" = "$ROOT/alpha"
sync --status >"$W/s.json" 2>"$W/s.err"; rc=$?
cond "M7: --status afterwards is clean (rc 0, no errors)" bash -c "[ $rc = 0 ] && python3 -B -c \"import json;d=json.load(open('$W/s.json'));assert d['errors']==[] and d['actions']==[]\""
cond "M8: history records the migration" $G -q "migrate_legacy" "$ROOT/changelog.md"

echo "== adjacent: repeat the same command"
Z1=$(ls "$ROOT"/backups/alpha-*.zip | wc -l | tr -d ' '); S1=$(ls "$ROOT/.staging" | wc -l | tr -d ' ')
sync --apply --migrate-legacy alpha --archive-legacy >"$W/q.json" 2>"$W/q.err"; rc=$?
cond "Q1: repeat refuses loudly (rc 2, 'nothing to migrate')" bash -c "[ $rc = 2 ] && $G -q 'nothing to migrate' '$W/q.json'"
cond "Q2: repeat took no new ZIP and staged nothing; link intact" bash -c "[ $(ls "$ROOT"/backups/alpha-*.zip | wc -l | tr -d ' ') = $Z1 ] && [ $(ls "$ROOT/.staging" | wc -l | tr -d ' ') = $S1 ] && [ \"\$(readlink '$A1/alpha')\" = '$ROOT/alpha' ]"
sync --migrate-legacy nosuchskill --archive-legacy >"$W/q2.json" 2>/dev/null; rc=$?
cond "Q3: an unknown skill name is an error, not a no-op (rc 2, 'Not a deployed skill')" bash -c "[ $rc = 2 ] && $G -q 'Not a deployed skill' '$W/q2.json'"

echo "== adjacent: copy identical to the managed one"
unlink "$A2/beta"; cp -R "$ROOT/beta" "$A2/beta"
sync --migrate-legacy beta --archive-legacy >"$W/b.json" 2>/dev/null
cond "B1: preview reports matches_managed true" bash -c "python3 -B -c \"import json;d=json.load(open('$W/b.json'));c=[x for x in d['changes'] if 'migrate_legacy' in x];assert len(c)==1 and c[0]['matches_managed'] is True\""
sync --apply --migrate-legacy beta --archive-legacy >/dev/null 2>&1; rc=$?
cond "B2: apply rc 0 and the link is in place" bash -c "[ $rc = 0 ] && [ \"\$(readlink '$A2/beta')\" = '$ROOT/beta' ]"

echo "== adjacent: folder whose frontmatter name differs"
legacy "$A2" gamma "Wrong skill." other
sync --apply --migrate-legacy gamma --archive-legacy >"$W/g.json" 2>/dev/null; rc=$?
cond "N1: refused (rc 2, 'Folder/name mismatch: gamma != other')" bash -c "[ $rc = 2 ] && $G -q 'Folder/name mismatch: gamma != other' '$W/g.json'"
cond "N2: folder untouched, no gamma ZIP" bash -c "[ -d '$A2/gamma' ] && [ ! -L '$A2/gamma' ] && [ -f '$A2/gamma/old.txt' ] && ! ls '$ROOT'/backups/gamma-*.zip"
mv "$A2/gamma" "$W/gamma.kept"; sync --apply >/dev/null 2>&1

echo "== replay: every action applied twice (a crash after the link, then recovery)"
legacy "$A2" delta "Stale delta."
python3 -B - "$ROOT" "$A2" <<'PY'
import os, sys
from pathlib import Path
root, a2 = Path(sys.argv[1]), Path(sys.argv[2])
sys.path.insert(0, str(root / "skills-army-hq" / "scripts"))
import sync, intake as shared
state, config = shared.load(root)
found = shared.inventory(root, state)
actions, errors, changes = sync.reconcile(root, state, config, found, legacy=("delta",), archive_directories=True, apply=True)
assert not errors, errors
assert [a["kind"] for a in actions] == ["retire-directory", "link"], actions
for a in actions: shared.action_apply(root, a)
for a in actions: shared.action_apply(root, a)
assert os.readlink(a2 / "delta") == str(root / "delta")
print("replay: second pass was a no-op; link intact")
PY
ok "Y1: replay of retire-directory then link is a no-op" $?

echo "== red controls B and C: forged recovery receipts"
python3 -B - "$ROOT" "$A1" <<'PY'
import sys
from pathlib import Path
root, a1 = Path(sys.argv[1]), sys.argv[2]
sys.path.insert(0, str(root / "skills-army-hq" / "scripts"))
import intake as shared
state, config = shared.load(root)
def receipt(act):
    r = {"schema": shared.SCHEMA, "root": str(root), "state": state, "targets": config, "actions": [act],
         "event": {"id": "0" * 32, "time": shared.utc(), "kind": "x", "details": {}}}
    r["checksum"] = shared.receipt_digest(r)
    return r
good = {"kind": "retire-directory", "name": "alpha", "root": a1, "op": "a" * 32, "before": "b" * 64, "after": None}
def verdict(label, act, expect):
    try:
        shared.validate_receipt(root, receipt(act))
        res = "accepted"
    except shared.DeployError as exc:
        res = str(exc)
    good_ = (res == "accepted") if expect is None else (expect in res)
    print(("PASS  " if good_ else "FAIL  ") + f"{label}: {res}")
    return good_
results = [
    verdict("B0 positive control, deployed skill in an app root", good, None),
    verdict("B1 root = the collection", {**good, "root": str(root)}, "overlaps collection"),
    verdict("B2 root inside the collection", {**good, "root": str(root / "backups")}, "overlaps collection"),
    verdict("B3 root is the collection's parent", {**good, "root": str(root.parent)}, "overlaps collection"),
    verdict("C1 name is neither trinity nor a deployed skill", {**good, "name": "notdeployed"}, "Invalid retirement"),
    verdict("C2 trinity name still accepted in an app root", {**good, "name": "skills-sync-trinity"}, None),
]
sys.exit(0 if all(results) else 1)
PY
rc=$?; if [ $rc = 0 ]; then PASS=$((PASS+6)); else FAIL=$((FAIL+1)); fi

echo "== repository untouched"
cond "T1: task clone worktree has no changes from this run" bash -c "[ -z \"\$(git -C '$CLONE' status --porcelain)\" ]"

echo "RESULT pass=$PASS fail=$FAIL (workdir $W)"
python3 -B -c "import shutil,sys;shutil.rmtree(sys.argv[1])" "$W"
[ "$FAIL" = 0 ]
```
