# GH-911 verification — workhorse run checklist + Stop hook

- **Commit under test:** `ace8d80c` (`feat/gh-911-workhorse-reentry`)
- **Where:** a disposable full clone of the task clone (`$TMPDIR/gh911-verify`). The task clone itself ran nothing.
- **Policy:** AGENTS.md *No new tests* (GH-831). The verification is one existing suite plus a manual matrix.
  The matrix runner below is an operator script kept as evidence. It is not a repo test and is not
  registered anywhere.

## Results

| Check | Result |
|---|---|
| `bash test/gh609-sdlc-agent-gaps.sh` (existing; pins workhorse Rung 5/6 strings) | 33 pass, 0 fail |
| `bash -n` + `shellcheck` on `stop-hook.sh` | clean |
| SKILL.md frontmatter parses (`yaml.safe_load`); `hooks.Stop[0].hooks[0].command` present | ok |
| Manual hook matrix (15 checks, below) | 15 PASS, 0 FAIL |

Per-check command, sha, exit code and decisive stdout: [`provenance.jsonl`](provenance.jsonl). One-line
view: [`matrix.txt`](matrix.txt).

## Red control

A scratch copy of `stop-hook.sh` has its open-item predicate rewritten (`startswith("- [ ]")` →
`startswith("- [NEVER]")`). On an open `- [ ]` checklist, the assertion "stdout is block JSON naming the
item" **fails** for that copy (verdict PASS = the expected failure was observed). The real hook on the
same input **passes**.

## Matrix covered

- **Blocks:**
  - an open item;
  - `stop_hook_active: true` with an open item (the cap is the harness's job);
  - a non-git `cwd` that falls back to `CLAUDE_PROJECT_DIR`.
- **Silent exit 0:**
  - only `[x]`/`[-]`/`[!]` lines;
  - no checklist;
  - another session's id;
  - garbage, empty or wrongly typed stdin;
  - a path-traversal session id;
  - `python3` missing.
- **Frontmatter command resolution:**
  - project-scope path present → the hook runs;
  - user-scope symlink present → the hook runs;
  - neither present → silent exit 0.

## Runner (operator script, as run)

```bash
#!/usr/bin/env bash
# GH-911 manual hook matrix (operator-run, not a repo test). Usage: gh911-matrix.sh <disposable-clone> <outdir>
set -u
D="$1"; OUT="$2"; mkdir -p "$OUT"
HOOK="$D/skills/2-daily/workhorse/stop-hook.sh"
SHA="$(git -C "$D" rev-parse HEAD)"
CMD="$(python3 -c 'import yaml,sys; t=open(sys.argv[1]).read().split("---")[1]; print(yaml.safe_load(t)["hooks"]["Stop"][0]["hooks"][0]["command"])' "$D/skills/2-daily/workhorse/SKILL.md")"
W="$(mktemp -d "${TMPDIR:-/tmp}/gh911.XXXXXX")" || exit 2; R="$W/repo"; mkdir -p "$R/.workhorse"; git -C "$R" init -q
PROV="$OUT/provenance.jsonl"; : > "$PROV"; FAILS=0

inp(){ printf '{"session_id":"%s","cwd":"%s","stop_hook_active":%s,"hook_event_name":"Stop"}' "$1" "$2" "${3:-false}"; }
is_block(){ python3 -c 'import json,sys; d=json.loads(sys.stdin.read()); sys.exit(0 if d.get("decision")=="block" and sys.argv[1] in d.get("reason","") else 1)' "$1" 2>/dev/null; }
rec(){ # name rc stdout verdict
  python3 -c 'import json,sys; print(json.dumps({"kind":"manual_check","check":sys.argv[1],"sha":sys.argv[2],"exit_code":int(sys.argv[3]),"stdout":sys.argv[4][:300],"verdict":sys.argv[5]}))' "$1" "$SHA" "$2" "$3" "$4" >> "$PROV"
  printf '%-48s %s\n' "$1" "$4" | tee -a "$OUT/matrix.txt"; [ "$4" = PASS ] || FAILS=$((FAILS+1)); }
run(){ out="$(printf '%s' "$2" | env -u CLAUDE_PROJECT_DIR HOME="$W/nohome" bash "$1" 2>&1)"; rc=$?; }

printf -- '- [ ] W1 P0 fix the parser — test passes\n- [x] W2 P1 done item\n' > "$R/.workhorse/S1.md"
printf -- '- [x] W1 done\n- [-] W2 parked → PARKED/x.md\n- [!] W3 blocked: needs operator decision\n' > "$R/.workhorse/S2.md"

# Red control: predicate disabled in a scratch copy -> the block assertion must FAIL.
sed 's/startswith("- \[ \]")/startswith("- [NEVER]")/' "$HOOK" > "$W/mutant.sh"
grep -q 'NEVER' "$W/mutant.sh" || { echo "mutation not applied"; exit 2; }
run "$W/mutant.sh" "$(inp S1 "$R")"; if printf '%s' "$out" | is_block "fix the parser"; then v=FAIL; else v=PASS; fi
rec "red: mutant (predicate off) fails block assertion" "$rc" "$out" "$v"
run "$HOOK" "$(inp S1 "$R")"; printf '%s' "$out" | is_block "fix the parser" && v=PASS || v=FAIL
rec "green: real hook blocks on open item" "$rc" "$out" "$v"
run "$HOOK" "$(inp S1 "$R" true)"; printf '%s' "$out" | is_block "fix the parser" && v=PASS || v=FAIL
rec "stop_hook_active=true still blocks" "$rc" "$out" "$v"
for c in "S2|closed/parked/blocked only" "S9|no checklist file" "S3|other session id"; do
  sid="${c%%|*}"; run "$HOOK" "$(inp "$sid" "$R")"; [ "$rc" = 0 ] && [ -z "$out" ] && v=PASS || v=FAIL
  rec "allow: ${c#*|} → silent exit 0" "$rc" "$out" "$v"; done
for c in 'not json|garbage stdin' '{"session_id":5,"cwd":"x"}|wrongly typed session_id' '{"session_id":"../S1","cwd":"x"}|path-traversal session_id' '|empty stdin'; do
  run "$HOOK" "${c%%|*}"; [ "$rc" = 0 ] && [ -z "$out" ] && v=PASS || v=FAIL
  rec "allow: ${c#*|} → silent exit 0" "$rc" "$out" "$v"; done
# Non-git cwd falls back to CLAUDE_PROJECT_DIR
out="$(inp S1 "$W" | env CLAUDE_PROJECT_DIR="$R" HOME="$W/nohome" bash "$HOOK" 2>&1)"; rc=$?
printf '%s' "$out" | is_block "fix the parser" && v=PASS || v=FAIL; rec "non-git cwd → CLAUDE_PROJECT_DIR fallback blocks" "$rc" "$out" "$v"

# Frontmatter command resolution (project path, user symlink, neither)
P="$W/proj"; mkdir -p "$P/.claude/skills/workhorse" "$W/home/.claude/skills" "$W/nohome"
ln -s "$HOOK" "$P/.claude/skills/workhorse/stop-hook.sh"; ln -s "$D/skills/2-daily/workhorse" "$W/home/.claude/skills/workhorse"
out="$(inp S1 "$R" | env CLAUDE_PROJECT_DIR="$P" HOME="$W/nohome" bash -c "$CMD" 2>&1)"; rc=$?
printf '%s' "$out" | is_block "fix the parser" && v=PASS || v=FAIL; rec "resolve: project-scope path runs hook" "$rc" "$out" "$v"
out="$(inp S1 "$R" | env -u CLAUDE_PROJECT_DIR HOME="$W/home" bash -c "$CMD" 2>&1)"; rc=$?
printf '%s' "$out" | is_block "fix the parser" && v=PASS || v=FAIL; rec "resolve: user-scope symlink runs hook" "$rc" "$out" "$v"
out="$(inp S1 "$R" | env -u CLAUDE_PROJECT_DIR HOME="$W/nohome" bash -c "$CMD" 2>&1)"; rc=$?
[ "$rc" = 0 ] && [ -z "$out" ] && v=PASS || v=FAIL; rec "resolve: neither path → silent exit 0" "$rc" "$out" "$v"
# Missing python3 → fail open
out="$(inp S1 "$R" | env -u CLAUDE_PROJECT_DIR PATH=/nonexistent /bin/bash "$HOOK" 2>&1)"; rc=$?
[ "$rc" = 0 ] && [ -z "$out" ] && v=PASS || v=FAIL; rec "allow: python3 missing → silent exit 0" "$rc" "$out" "$v"

rm -rf "$W"; echo "FAILS=$FAILS"; exit "$FAILS"
```

## Not covered here

- **A live Claude Code session.** No live session invoked the skill to watch the harness register and fire the
  frontmatter hook. The hook contract (stdin shape, `decision: block`, skill-hook lifetime,
  8-continuation cap) comes from the documentation, fetched 2026-10-01. Confirm it on first real use.
- **The qualifying gate** (`ci-local.sh`) runs once on the final approved commit and is recorded in the PR.
