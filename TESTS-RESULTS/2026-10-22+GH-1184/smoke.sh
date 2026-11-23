#!/usr/bin/env bash
# GH-1184 manual smoke (GH-1088): stub gh + logging git wrapper, disposable clone. Prints PASS/FAIL lines.
# Usage: gh1184_smoke.sh <task-clone-path> <out-dir>
set -u
SRC="$1"; OUT="$2"; mkdir -p "$OUT"; W="$OUT/work"; rm -rf "$W"; mkdir -p "$W/bin" "$W/stubstate"
ENGINE="skills/3-weekly/weekly-planner/scripts/planner_core.py"
pass(){ echo "PASS: $*" | tee -a "$OUT/results.txt"; }
fail(){ echo "FAIL: $*" | tee -a "$OUT/results.txt"; }

# --- disposable clone of the task clone (committed state) ---
git clone -q --no-hardlinks "$SRC" "$W/repo" || { fail "clone"; exit 1; }
REPO="$W/repo"
# a second throwaway checkout to act as a "local root": unpushed branch (recent), no-upstream old branch,
# dirty file, name-matching-merged branch with an extra local commit
git clone -q --no-hardlinks "$SRC" "$W/root2"
git -C "$W/root2" remote set-url origin https://github.com/HiQS-Labs/XYZ-forge.git
git -C "$W/root2" checkout -q -b feat/recent-unpushed && echo x > "$W/root2/unpushed.txt" && git -C "$W/root2" add unpushed.txt && git -C "$W/root2" commit -q -m "recent unpushed"
git -C "$W/root2" checkout -q -b fix/forgotten && echo y > "$W/root2/old.txt" && git -C "$W/root2" add old.txt && GIT_COMMITTER_DATE="2026-10-01T12:00:00-07:00" git -C "$W/root2" commit -q -m "old no-upstream" --date "2026-10-01T12:00:00-07:00"
git -C "$W/root2" checkout -q -b fix/report && echo z > "$W/root2/extra.txt" && git -C "$W/root2" add extra.txt && git -C "$W/root2" commit -q -m "extra local commit on merged-name branch"
echo dirty > "$W/root2/README.md"
# PARKED smoke notes in REPO (committed so last-commit-in-window applies)
mkdir -p "$REPO/PARKED"
printf '# smoke\n- open item SENTINEL-7f3a9c do not publish\n' > "$REPO/PARKED/2026-10-22-smoke.md"
printf '# resolved\n- **Resolved 2026-10-22:** done\n' > "$REPO/PARKED/2026-10-22-resolved.md"
printf '# prose\nClosed-loop review remains open for this item.\n' > "$REPO/PARKED/2026-10-22-closedloop.md"
for i in $(seq 1 12); do printf '# many %s\n- open\n' "$i" > "$REPO/PARKED/2026-10-21-many-$i.md"; done
# an OLD committed note (back-dated commit) that only an UNSTAGED edit can bring into the window (F3)
printf '# old committed note\n- open\n' > "$REPO/PARKED/2026-09-01-oldnote.md"
git -C "$REPO" add PARKED/2026-09-01-oldnote.md && GIT_COMMITTER_DATE="2026-09-01T12:00:00-07:00" git -C "$REPO" commit -q -m "old note" --date "2026-09-01T12:00:00-07:00"
mkdir -p "$REPO/relay-system/2026-10-22"
printf 'NEXT: Reviewer\nSTATUS: Open\n' > "$REPO/relay-system/2026-10-22/smoke-open.md"
printf 'NEXT: Producer\nSTATUS: Approved\n' > "$REPO/relay-system/2026-10-22/smoke-approved.md"
git -C "$REPO" add PARKED relay-system && git -C "$REPO" commit -q -m "smoke notes"
printf '\n- unstaged edit today\n' >> "$REPO/PARKED/2026-09-01-oldnote.md"
touch "$REPO/PARKED/README.md"

# --- stub gh ---
cat > "$W/bin/gh" <<'G'
#!/usr/bin/env python3
import sys, json, os
a=sys.argv[1:]; S=os.environ["STUBSTATE"]; mode=open(S+"/mode").read().strip() if os.path.exists(S+"/mode") else "ok"
def log(x): open(S+"/gh.log","a").write(x+"\n")
log(" ".join(a))
now="2026-10-22T20:00:00Z"
if a[:2]==["repo","view"]: print("HiQS-Labs/XYZ-forge"); sys.exit(0)
if a[:2]==["api","user"]: print("noelsaw1"); sys.exit(0)
if a[:2]==["pr","list"] and "--state" in a and a[a.index("--state")+1]=="open":
    if mode=="prfail": print("boom",file=sys.stderr); sys.exit(1)
    prs=[
     {"number":10,"title":"HOLD: parked spike","author":{"login":"x"},"headRefName":"spike","baseRefName":"development","mergeable":"MERGEABLE","reviewDecision":"","reviews":[],"updatedAt":"2026-09-01T00:00:00Z","statusCheckRollup":[],"files":[],"body":"","isDraft":False,"labels":[],"url":"u10"},
     {"number":11,"title":"docs: retain qualification receipts","author":{"login":"x"},"headRefName":"ev","baseRefName":"development","mergeable":"MERGEABLE","reviewDecision":"","reviews":[],"updatedAt":"2026-09-01T00:00:00Z","statusCheckRollup":[],"files":[],"body":"This PR is an evidence carrier for #1.","isDraft":True,"labels":[],"url":"u11"},
     {"number":12,"title":"old ordinary PR with hold label","author":{"login":"x"},"headRefName":"lab","baseRefName":"development","mergeable":"MERGEABLE","reviewDecision":"","reviews":[],"updatedAt":"2026-09-01T00:00:00Z","statusCheckRollup":[],"files":[],"body":"","isDraft":False,"labels":[{"name":"hold"}],"url":"u12"},
     {"number":13,"title":"ordinary idle PR","author":{"login":"x"},"headRefName":"idle","baseRefName":"development","mergeable":"CONFLICTING","reviewDecision":"","reviews":[],"updatedAt":"2026-10-10T00:00:00Z","statusCheckRollup":[],"files":[],"body":"","isDraft":False,"labels":[],"url":"u13"},
     {"number":14,"title":"fresh PR","author":{"login":"x"},"headRefName":"fresh","baseRefName":"development","mergeable":"MERGEABLE","reviewDecision":"","reviews":[],"updatedAt":now,"statusCheckRollup":[],"files":[],"body":"","isDraft":False,"labels":[],"url":"u14"},
    ]
    if mode=="trunc": prs=prs*60
    print(json.dumps(prs)); sys.exit(0)
if a[:2]==["pr","list"] and "--state" in a and a[a.index("--state")+1]=="merged": print("[]"); sys.exit(0)
if a[:2]==["issue","list"] and "--state" in a and a[a.index("--state")+1]=="closed": print("[]"); sys.exit(0)
if a[:2]==["pr","list"] and "--state" in a and a[a.index("--state")+1]=="all":
    print(json.dumps([{"number":20,"headRefName":"fix/report","state":"MERGED"},{"number":21,"headRefName":"fix/report","state":"OPEN"} if mode=="reused" else {"number":22,"headRefName":"zzz","state":"CLOSED"}])); sys.exit(0)
if a[:2]==["issue","list"]:
    if mode=="prfail": print("boom",file=sys.stderr); sys.exit(1)
    print(json.dumps([
      {"number":100,"title":"mine idle","url":"i100","labels":[],"assignees":[{"login":"noelsaw1"}],"body":"","updatedAt":"2026-10-01T00:00:00Z"},
      {"number":101,"title":"mine owner hold","url":"i101","labels":[],"assignees":[{"login":"noelsaw1"}],"body":"Owner decision: hold until product sign-off","updatedAt":"2026-10-01T00:00:00Z"},
      {"number":102,"title":"not mine idle","url":"i102","labels":[],"assignees":[],"body":"","updatedAt":"2026-10-01T00:00:00Z"},
    ])); sys.exit(0)
if a[:1]==["api"] and "comments?per_page" in " ".join(a):
    if mode=="listfail": print("boom",file=sys.stderr); sys.exit(1)
    p=S+"/comments.json"; data=json.load(open(p)) if os.path.exists(p) else []
    print(json.dumps([data])); sys.exit(0)
if a[:1]==["api"] and "--method" in a:
    if mode=="writefail": print("boom",file=sys.stderr); sys.exit(1)
    body=json.load(open(a[a.index("--input")+1]))["body"]
    p=S+"/comments.json"; data=json.load(open(p)) if os.path.exists(p) else []
    if a[a.index("--method")+1]=="PATCH":
        cid=int(a[a.index("--method")+2].rsplit("/",1)[1])
        for c in data:
            if c["id"]==cid: c["body"]=body; log("PATCH %d"%cid)
    else:
        data.append({"id":len(data)+1,"body":body}); log("POST %d"%len(data))
    json.dump(data,open(p,"w")); print("{}"); sys.exit(0)
print("stub gh: unhandled "+" ".join(a),file=sys.stderr); sys.exit(1)
G
chmod +x "$W/bin/gh"
# --- logging git wrapper (records argv, forwards to real git) ---
REALGIT="$(command -v git)"
cat > "$W/bin/git" <<G
#!/usr/bin/env bash
echo "\$*" >> "$W/stubstate/git.log"
exec "$REALGIT" "\$@"
G
chmod +x "$W/bin/git"
export PATH="$W/bin:$PATH" STUBSTATE="$W/stubstate"
run(){ (cd "$REPO" && python3 "$ENGINE" --repo-root "$REPO" --gh-repo HiQS-Labs/XYZ-forge --local-roots "$REPO" --local-roots "$W/root2" --device-id "Noels-Mac-Studio.local" "$@"); }

# seed a prior-day marker for another device
echo '[{"id":1,"body":"<!-- planner-stalled:other-mac:2026-10-20 -->\nold report"}]' > "$STUBSTATE/comments.json"
IDX_BEFORE=$(shasum "$W/root2/.git/index" | cut -c1-40)
touch "$W/root2/.gitignore"   # stat-only change to a tracked file

# seed a prior-day marker for THIS device too (F2: this run must report its own date as today)
echo '[{"id":1,"body":"<!-- planner-stalled:other-mac:2026-10-20 -->\nold report"},{"id":2,"body":"<!-- planner-stalled:noels-mac-studio:2026-10-21 -->\nyesterday"}]' > "$STUBSTATE/comments.json"
echo "== main: stalled mode with team issue"; : > "$STUBSTATE/git.log"; echo ok > "$STUBSTATE/mode"
run --mode stalled --team-issue 999 > "$OUT/run1.out" 2>&1; echo "rc=$?" >> "$OUT/run1.out"; tail -2 "$OUT/run1.out"
MD=$(ls "$REPO"/temp/planner/STALLED-*.md | head -1); cp "$MD" "$OUT/STALLED.md"; cp "$STUBSTATE/comments.json" "$OUT/comments-after-run1.json"
BODY=$(python3 -c "import json;d=json.load(open('$STUBSTATE/comments.json'));print([c['body'] for c in d if 'planner-stalled:noels-mac-studio:2026-10-22' in c['body']][0])")   # THIS run's comment, not yesterday's seed
[ -n "$BODY" ] && pass "comment body captured (non-empty, $(echo "$BODY" | wc -c | tr -d ' ') bytes)" || fail "comment body empty"
grep -q 'planner-stalled:noels-mac-studio:' "$STUBSTATE/comments.json" && pass "marker device normalized (noels-mac-studio)" || fail "marker"
grep -q 'no report since 2026-10-20' "$OUT/STALLED.md" && pass "prior-day device gap reported (other-mac)" || fail "prior device gap"
# Held vs stalled
for n in 10 11 12; do grep -A50 '\*\*Held' "$OUT/STALLED.md" | grep -q "PR #$n" && pass "PR #$n under Held" || fail "PR #$n not under Held"; done
grep -A50 '\*\*Stalled' "$OUT/STALLED.md" | grep -B100 '\*\*Local' | grep -q 'PR #13' && pass "PR #13 Stalled (rebase)" || fail "PR #13"
grep -A50 '\*\*Stalled' "$OUT/STALLED.md" | grep -B100 '\*\*Local' | grep -q 'PR #14' && fail "fresh PR #14 wrongly stalled" || pass "fresh PR #14 not stalled"
grep -A50 '\*\*Stalled' "$OUT/STALLED.md" | grep -B100 '\*\*Local' | grep -q 'rebase' && pass "CONFLICTING idle PR → rebase" || fail "rebase hint"
grep -A50 '\*\*Held' "$OUT/STALLED.md" | grep -q 'issue #101' && pass "issue #101 owner-decision hold under Held" || fail "issue #101"
grep -A50 '\*\*Stalled' "$OUT/STALLED.md" | grep -B100 '\*\*Local' | grep -q 'issue #100' && pass "issue #100 assigned idle → Stalled" || fail "issue #100"
grep -q 'issue #102' "$OUT/STALLED.md" && fail "unassigned issue #102 listed" || pass "unassigned issue #102 not listed"
# local rows
grep -q 'root2:feat/recent-unpushed' "$OUT/STALLED.md" && pass "recent no-upstream branch listed" || fail "recent branch"
grep -q 'root2:fix/forgotten' "$OUT/STALLED.md" && pass "3-week-old no-upstream branch listed (F2)" || fail "old branch"
grep -q 'uncommitted change' "$OUT/STALLED.md" && pass "dirty tree row" || fail "dirty"
grep -q 'retire? name match' "$OUT/STALLED.md" && pass "merged-name branch is an unverified candidate (F3)" || fail "retire candidate"
grep -q 'safe to retire' "$OUT/STALLED.md" && fail "says safe to retire" || pass "never says safe to retire"
# notes — presence is checked in the JSON (the rendered section caps rows at 10 per group), rendering in the MD
JSONF=$(ls "$REPO"/temp/planner/stalled-*.json | head -1); cp "$JSONF" "$OUT/stalled.json"
refs=$(python3 -c "import json;print('\n'.join(r['ref'] for r in json.load(open('$JSONF'))['stalled_stale']['local'] if r['kind'] in ('note','relay')))")
echo "$refs" | grep -q 'PARKED/2026-10-22-smoke.md' && pass "open PARKED note listed" || fail "open note"
echo "$refs" | grep -q '2026-10-22-resolved.md' && fail "resolved note listed" || pass "resolved note excluded (F4)"
echo "$refs" | grep -q 'PARKED/README.md' && fail "README listed" || pass "README excluded (F4)"
echo "$refs" | grep -q 'smoke-open.md' && pass "open relay thread listed" || fail "open relay"
echo "$refs" | grep -q 'smoke-approved.md' && fail "approved relay listed" || pass "approved relay excluded"
echo "$refs" | grep -q '2026-10-22-closedloop.md' && pass "'Closed-loop …' prose is NOT treated as resolved (nit)" || fail "closedloop prose excluded"
echo "$refs" | grep -q '2026-09-01-oldnote.md' && pass "old note with an UNSTAGED edit today is listed (F3: porcelain first line)" || fail "unstaged note edit missed (F3)"
[ "$(echo "$refs" | grep -c PARKED/)" -ge 15 ] && pass "all $(echo "$refs" | grep -c PARKED/) PARKED notes in the JSON" || fail "note count in JSON"
# F4: at most 10 rendered rows per CHECKOUT (branches + worktree + notes + relays together) plus one "+N more" line
RENDERED_REPO=$(sed -n '/\*\*Local/,/\*\*Held/p' "$OUT/STALLED.md" | grep -v '… +' | grep -c '^- `repo\|^- `PARKED/\|^- `relay-system/')
MORE_REPO=$(sed -n '/\*\*Local/,/\*\*Held/p' "$OUT/STALLED.md" | grep -c '^- `repo` … +')
[ "$RENDERED_REPO" -le 10 ] && [ "$MORE_REPO" -eq 1 ] && pass "checkout 'repo' renders $RENDERED_REPO rows (<= 10) + one '+N more' line (F4)" || fail "per-checkout cap: rendered=$RENDERED_REPO more=$MORE_REPO"
python3 -c "import json;d=json.load(open('$JSONF'))['stalled_stale'];me=[x for x in d['devices'] if x['device']=='noels-mac-studio'][0];import sys;sys.exit(0 if me['last_report']=='2026-10-22' and me['status']=='today' else 1)" && pass "current device last_report == local today (F2)" || fail "current device last_report (F2)"
grep -A60 '\*\*Held' "$OUT/STALLED.md" | grep 'PR #10' | grep -q 'last activity 2026-09-01' && pass "Held row carries dated evidence (F5)" || fail "held row date"
# secrets
echo "$BODY" | grep -q 'SENTINEL-7f3a9c' && fail "sentinel leaked into comment" || pass "no note contents in comment (sentinel absent, body non-empty)"
echo "$BODY SENTINEL-7f3a9c" | grep -q 'SENTINEL-7f3a9c' && pass "RED CONTROL: contaminated body is detected" || fail "red control sentinel"
# read-only
[ -s "$STUBSTATE/git.log" ] && pass "git argv log non-empty ($(wc -l < "$STUBSTATE/git.log" | tr -d ' ') calls)" || fail "git log empty"
grep -Eq '(^| )(fetch|prune|push|checkout|pull|reset|clean)( |$)' "$STUBSTATE/git.log" && fail "mutating git verb used" || pass "no fetch/prune/push/checkout/pull/reset/clean in git argv"
{ cat "$STUBSTATE/git.log"; echo "fetch origin"; } > "$W/red-git.log"; grep -Eq '(^| )(fetch|prune|push|checkout|pull|reset|clean)( |$)' "$W/red-git.log" && pass "RED CONTROL: a fetch line is detected" || fail "red control git"
IDX_AFTER=$(shasum "$W/root2/.git/index" | cut -c1-40); [ "$IDX_BEFORE" = "$IDX_AFTER" ] && pass "index bytes unchanged after scan (--no-optional-locks) (F5)" || fail "index changed"
cp "$STUBSTATE/git.log" "$OUT/git-argv.log"; cp "$STUBSTATE/gh.log" "$OUT/gh-argv.log"

echo "== adjacent: same-day re-run edits own comment"; N1=$(python3 -c "import json;print(len(json.load(open('$STUBSTATE/comments.json'))))")
run --mode stalled --team-issue 999 > "$OUT/run2.out" 2>&1; echo "rc=$?" >> "$OUT/run2.out"
N2=$(python3 -c "import json;print(len(json.load(open('$STUBSTATE/comments.json'))))"); grep -q 'PATCH' "$STUBSTATE/gh.log" && [ "$N1" = "$N2" ] && pass "re-run PATCHed own comment; count $N1 → $N2" || fail "re-run did not edit in place ($N1 → $N2)"
echo "== adjacent: second device"; (cd "$REPO" && python3 "$ENGINE" --repo-root "$REPO" --gh-repo HiQS-Labs/XYZ-forge --local-roots "$REPO" --device-id other-mac --mode stalled --team-issue 999 > "$OUT/run3.out" 2>&1)
N3=$(python3 -c "import json;print(len(json.load(open('$STUBSTATE/comments.json'))))"); [ "$N3" -eq $((N2+1)) ] && pass "second device → separate comment ($N2 → $N3)" || fail "second device comment count $N3"
cp "$STUBSTATE/gh.log" "$OUT/gh-argv.log"   # retained AFTER the re-run and second device, so POST, PATCH and the second POST are all in it
grep -q '^PATCH' "$OUT/gh-argv.log" && [ "$(grep -c '^POST' "$OUT/gh-argv.log")" -eq 2 ] && pass "retained gh log shows POST, PATCH (re-run), POST (second device)" || fail "gh log shape"
echo "== adjacent: daily mode without baseline still fails as before"; rm -f "$REPO"/temp/planner/weekly-plan-*; run --mode daily > "$OUT/run4.out" 2>&1; rc=$?; grep -qi 'weekly' "$OUT/run4.out" && [ $rc -ne 0 ] && pass "daily without baseline → nonzero with weekly hint (unchanged)" || fail "daily baseline rc=$rc"
echo "== adjacent: daily mode with a baseline renders section 5, no comment without --team-issue"
echo '{"mode":"weekly_plan","date":"2026-10-20","tasks":[],"raw_tasks":[],"roadmap_items":[]}' > "$REPO/temp/planner/weekly-plan-2026-10-20.json"; : > "$STUBSTATE/gh.log"
run --mode daily > "$OUT/run5.out" 2>&1; rc=$?; grep -q '## 5. Stalled & stale' "$REPO"/temp/planner/DAILY-PIVOT-*.md && pass "daily MD has section 5 (rc=$rc)" || fail "daily section 5 rc=$rc"
grep -q 'POST\|PATCH' "$STUBSTATE/gh.log" && fail "daily without --team-issue posted" || pass "daily without --team-issue posts nothing"
echo "== gaps"; echo prfail > "$STUBSTATE/mode"; rm -f "$REPO"/temp/planner/STALLED-*.md; run --mode stalled > "$OUT/run6.out" 2>&1; rc=$?; echo "prfail rc=$rc" >> "$OUT/run6.out"
[ $rc -eq 0 ] && grep -q 'failed. open PRs' "$REPO"/temp/planner/STALLED-*.md && pass "open-PR lookup failure → report still produced with 'failed open PRs' coverage (F1)" || fail "prfail rc=$rc or no coverage line"
grep -q 'coverage incomplete' "$REPO"/temp/planner/STALLED-*.md && pass "empty Stalled under a gap renders 'coverage incomplete'" || fail "coverage incomplete wording"
echo trunc > "$STUBSTATE/mode"; run --mode stalled > "$OUT/run7.out" 2>&1; grep -q 'truncated' "$REPO"/temp/planner/STALLED-*.md && pass "300-row PR list → truncated coverage" || fail "truncated"
echo listfail > "$STUBSTATE/mode"; : > "$STUBSTATE/gh.log"; run --mode stalled --team-issue 999 > "$OUT/run8.out" 2>&1; rc=$?; grep -q POST "$STUBSTATE/gh.log" && fail "blind POST after list failure" || { [ $rc -eq 3 ] && pass "comment list failure → no POST, exit 3" || fail "listfail rc=$rc"; }
grep -q 'failed. weekly issue comments' "$REPO"/temp/planner/STALLED-*.md && pass "list failure visible as coverage gap" || fail "listfail coverage"
echo writefail > "$STUBSTATE/mode"; run --mode stalled --team-issue 999 > "$OUT/run9.out" 2>&1; rc=$?; [ $rc -eq 3 ] && pass "comment write failure → exit 3" || fail "writefail rc=$rc"
echo reused > "$STUBSTATE/mode"; run --mode stalled > "$OUT/run10.out" 2>&1; grep -q 'root2:fix/report' "$REPO"/temp/planner/STALLED-*.md && ! grep -A3 'root2:fix/report' "$REPO"/temp/planner/STALLED-*.md | grep -q 'retire?' && pass "reused name with an OPEN PR → not a retire candidate" || fail "reused-name case"
echo ok > "$STUBSTATE/mode"
echo "== summary"; grep -c '^PASS' "$OUT/results.txt"; grep -c '^FAIL' "$OUT/results.txt" || true
