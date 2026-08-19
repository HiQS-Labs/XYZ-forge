#!/usr/bin/env bash
# gh39-releases-project-sync.sh — GitHub Project projection is dry-run safe and idempotent.
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP="$HERE/../utils/py/releases_app.py"

pass=0; fail=0
ok(){ if [ "$2" = "0" ]; then echo "  PASS: $1"; pass=$((pass+1)); else echo "  FAIL: $1"; fail=$((fail+1)); fi; }
has(){ printf '%s' "$1" | grep -q "$2"; }

echo "== test: gh39-releases-project-sync =="
command -v python3 >/dev/null 2>&1 || { echo "python3 required" >&2; exit 1; }

WORK="$(mktemp -d "${TMPDIR:-/tmp}/gh39-project-sync.XXXXXX")"
[ -n "$WORK" ] && [ -d "$WORK" ] || { echo "mktemp failed" >&2; exit 1; }
. "$HERE/lib/fixture-guard.sh"
fixture_guard_init "$WORK"
cleanup(){ [ -n "${WORK:-}" ] && [ -d "$WORK" ] && rm -rf "$WORK"; }
trap cleanup EXIT

R="$WORK/repo"
mkdir -p "$R"
git -C "$R" init -q
git -C "$R" config user.email t@t
git -C "$R" config user.name t

FAKE="$WORK/fake-gh.py"
STATE="$WORK/project.json"
cat > "$FAKE" <<'PY'
#!/usr/bin/env python3
import json, os, sys

state_path = os.environ["FAKE_GH_STATE"]
fields = [
    {"id": "f-release-id", "name": "Release ID"},
    {"id": "f-release-status", "name": "Release status",
     "options": [{"id": "draft", "name": "Draft"}, {"id": "active", "name": "Active"},
                 {"id": "shipped", "name": "Shipped"}, {"id": "cut", "name": "Cut"}]},
    {"id": "f-target", "name": "Target date"},
    {"id": "f-shipped", "name": "Shipped date"},
    {"id": "f-codename", "name": "Codename"},
    {"id": "f-tracking", "name": "Tracking issue"},
    {"id": "f-gh-release", "name": "GitHub release"},
    {"id": "f-front-door", "name": "Front-door reviewed",
     "options": [{"id": "yes", "name": "Yes"}, {"id": "no", "name": "No"}]},
    {"id": "f-shakedown", "name": "Shakedown reviewed",
     "options": [{"id": "yes", "name": "Yes"}, {"id": "no", "name": "No"}]},
    {"id": "f-license", "name": "License file",
     "options": [{"id": "yes", "name": "Yes"}, {"id": "no", "name": "No"}]},
]

try:
    state = json.load(open(state_path))
except FileNotFoundError:
    state = {"items": [], "calls": []}
if state.get("omit_target"):
    fields = [field for field in fields if field["name"] != "Target date"]

args = sys.argv[1:]
state["calls"].append(args)
def value(flag):
    return args[args.index(flag) + 1]
def save():
    with open(state_path, "w") as fh:
        json.dump(state, fh)
def item(item_id):
    return next(row for row in state["items"]
                if row["id"] == item_id or row.get("content", {}).get("id") == item_id)

if args[:2] == ["project", "view"]:
    print(json.dumps({"id": "project-1", "number": 9}))
elif args[:2] == ["project", "field-list"]:
    print(json.dumps({"fields": fields}))
elif args[:2] == ["project", "item-list"]:
    print(json.dumps({"items": state["items"]}))
elif args[:2] == ["project", "item-create"]:
    number = len(state["items"]) + 1
    row = {"id": "item-%d" % number, "title": value("--title"),
           "content": {"id": "draft-%d" % number, "type": "DraftIssue",
                       "title": value("--title"), "body": value("--body")}}
    state["items"].append(row)
    save()
    print(json.dumps(row))
elif args[:2] == ["project", "item-edit"]:
    row = item(value("--id"))
    if "--title" in args:
        row["content"]["title"] = value("--title")
        row["content"]["body"] = value("--body")
        row["title"] = value("--title")
    if "--field-id" in args:
        field_id = value("--field-id")
        field_name = next(entry["name"] for entry in fields if entry["id"] == field_id)
        key = field_name[:1].lower() + field_name[1:]
        if "--clear" in args:
            row.pop(key, None)
        elif "--text" in args:
            row[key] = value("--text")
        elif "--date" in args:
            row[key] = value("--date")
        elif "--single-select-option-id" in args:
            option_id = value("--single-select-option-id")
            row[key] = next(option["name"] for entry in fields if entry["id"] == field_id
                            for option in entry.get("options", []) if option["id"] == option_id)
    save()
    print(json.dumps(row))
else:
    print("unexpected fake gh arguments: %r" % args, file=sys.stderr)
    sys.exit(2)
PY
chmod +x "$FAKE"

RA(){ RELEASES_GH_BIN="$FAKE" FAKE_GH_STATE="$STATE" PYTHONDONTWRITEBYTECODE=1 python3 "$APP" --root "$R" "$@"; }
RA init --slug sync >/dev/null
RA add --version 1.0.0 --codename Alpha --status draft --target-date 2026-09-01 --description "First release." --tracking-issue "https://github.com/A/B/issues/1" >/dev/null
RA add --version 2.0.0 --codename Beta --status active --target-date 2026-10-01 --description "Second release." --tracking-issue "https://github.com/A/B/issues/2" >/dev/null

OUT="$(RA project sync --owner Example --number 9)"
COUNT="$(if [ -f "$STATE" ]; then python3 -c 'import json,sys; print(len(json.load(open(sys.argv[1]))["items"]))' "$STATE"; else echo 0; fi)"
if has "$OUT" "DRY RUN" && [ "$COUNT" = "0" ]; then ok "dry-run plans cards but leaves GitHub unchanged" 0; else ok "dry-run safety" 1; fi

RA project sync --owner Example --number 9 --apply >/dev/null
COUNT="$(python3 -c 'import json,sys; print(len(json.load(open(sys.argv[1]))["items"]))' "$STATE")"
IDS="$(python3 -c 'import json,sys; print(" ".join(sorted(x.get("release ID", "") for x in json.load(open(sys.argv[1]))["items"])))' "$STATE")"
if [ "$COUNT" = "2" ] && has "$IDS" "rel-" && has "$IDS" " "; then ok "apply creates one card per immutable Release ID" 0; else ok "apply creates cards" 1; fi

OUT="$(RA project sync --owner Example --number 9 --apply)"
COUNT2="$(python3 -c 'import json,sys; print(len(json.load(open(sys.argv[1]))["items"]))' "$STATE")"
if has "$OUT" "UPDATE 1.0.0" && has "$OUT" "UPDATE 2.0.0" && [ "$COUNT2" = "2" ]; then ok "repeat apply updates cards without duplicates" 0; else ok "idempotent repeat" 1; fi

python3 - "$STATE" <<'PY'
import json, sys
path = sys.argv[1]
state = json.load(open(path))
state["omit_target"] = True
with open(path, "w") as fh:
    json.dump(state, fh)
PY
OUT="$(RA project sync --owner Example --number 9 2>&1)"; RC=$?
if [ "$RC" = "3" ] && has "$OUT" "github-project-schema"; then ok "missing required Project field fails loudly" 0; else ok "schema guard" 1; fi

echo "== result: $pass pass, $fail fail =="
[ "$fail" -eq 0 ]
