#!/usr/bin/env bash
# GH-505 / GH-509 / GH-510 — driver-attested terminal status.
#
# The relay driver is the only process in a relay the party under review does not run. These
# cases drive the REAL relay_drive.py through the REAL codex-turn.sh shim (worktree isolation on,
# containment on, file-scoped commit on) with a stub `codex` binary that plays builder or reviewer,
# and assert that:
#   A   a builder-role turn that writes STATUS: Approved is reverted, committed as reverted, and
#       escalated `forged-terminal` (exit 4) — RED at base: the base driver exits 0
#   A2  the same behind a containment failure keeps the shim's exit 6
#   B   a reviewer-role approval is attested: trailer + record, reviewed_head = HEAD BEFORE dispatch
#       = the parent of the shim's commit, digest = sha256 of exactly the appended bytes
#   B4  a parent commit landing DURING the turn does not move reviewed_head (worktree cut at the pin)
#       and the candidate check refuses the drifted HEAD
#   C   a file that is already terminal at startup is refused `unattested-terminal` — RED at base
#   D1  STATUS-only change by the reviewer → empty-approval;  D3 rewritten body → review-body-rewritten
#   E2  no --reviewer → exit 2 before any tick mutation;  E3 builder == reviewer → exit 2
#   K   reviewer leaves the token claimed → close-mismatch, no record
#   L   the reader refuses a changed reviewer / STATUS / review text / truncated record
#   F   RELAY_ROLE outranks the in-file directive under RELAY_DRIVER_LOCKED=1, through rtl.py
#   G   the builder prompt no longer says "set STATUS: Approved"; the reviewer prompt does
#   S1  RELAY_WORKTREE_ISOLATION other than 0/1 is refused before dispatch
#   I   jog's landing parks on a refused merge, a missing PR, and a drifted candidate (GH-510);
#       merges with --match-head-commit <candidate> otherwise
#   J   jog no longer overrides a non-zero driver exit
source "$(dirname "$0")/_setup.sh" gh505-relay-attest
export TICK_BIN="$TICK"
REPO="$(cd "$(dirname "$0")/.." && pwd)"
BASE_SHA="${GH505_BASE_SHA:-a6441b9b}"
tick_a init >/dev/null

# ---- fixture harness: a copy of the shipped scripts, so .relay-scratch and locks land in $WORK ----
MAIN="$WORK/harness"; mkdir -p "$MAIN"
cp -R "$REPO/relay-automation" "$REPO/utils" "$REPO/bin" "$REPO/src" "$MAIN/" 2>/dev/null
git init -q "$MAIN"; git -C "$MAIN" add -A >/dev/null 2>&1; git -C "$MAIN" commit -qm seed >/dev/null 2>&1
DRIVER="$MAIN/utils/py/relay_drive.py"

# ---- target repo $A: tracked relay file, .tick/bin gitignored ----
mkdir -p "$A/bin"; ln -sf "$TICK" "$A/bin/tick"
printf '.tick/\nbin/\n' >"$A/.gitignore"
printf '# RELAY · fixture\n\nNEXT: bld\nSTATUS: Open\nROUND: 1 / 2\n\n## Body\n\nseeded body line one\n' >"$A/relay.md"
printf 'v1\n' >"$A/src.txt"
git -C "$A" add .gitignore relay.md src.txt >/dev/null 2>&1; git -C "$A" commit -qm "seed relay" >/dev/null 2>&1

# ---- stub codex: plays the role the driver dispatched; edits cwd-relative relay.md (the worktree) ----
STUB="$WORK/codex"
cat >"$STUB" <<STUB_EOF
#!/usr/bin/env bash
set -u
export TICK_REPO_ROOT="$A"
T="$TICK"
touch "$WORK/ran-\${RELAY_AGENT}-\${RELAY_TASK}"
printf '%s\n' "\$(git -C "$A" rev-parse HEAD)" >"$WORK/head-at-turn-\${RELAY_TASK}"
printf '%s\n' "\$(git rev-parse HEAD 2>/dev/null)" >"$WORK/wt-cut-\${RELAY_TASK}"
f="\$PWD/relay.md"
mode="\${STUB_MODE:-approve}"
"\$T" claim "\$RELAY_TASK" --agent "\$RELAY_AGENT" --paths "relay.md" >/dev/null 2>&1
case "\$mode" in
  handoff)
    printf '\n### Round 1 · Builder · %s\nbuilt it\n' "\$RELAY_AGENT" >>"\$f"
    "\$T" release "\$RELAY_TASK" --agent "\$RELAY_AGENT" --to "\${STUB_HANDOFF_TO:-rev}" >/dev/null 2>&1 ;;
  statusonly)
    perl -pi -e 's/^STATUS:.*/STATUS: Approved/' "\$f"
    "\$T" done "\$RELAY_TASK" --agent "\$RELAY_AGENT" >/dev/null 2>&1 ;;
  rewrite)
    perl -pi -e 's/^seeded body line one/REWRITTEN/' "\$f"
    printf '\n### Round 1 · Reviewer · %s\nlooks fine\n' "\$RELAY_AGENT" >>"\$f"
    perl -pi -e 's/^STATUS:.*/STATUS: Approved/' "\$f"
    "\$T" done "\$RELAY_TASK" --agent "\$RELAY_AGENT" >/dev/null 2>&1 ;;
  uncited)
    printf '\n### Round 1 · Reviewer · %s\n- [Pass] verified the thing works\n**Verdict:** Approved\n' "\$RELAY_AGENT" >>"\$f"
    perl -pi -e 's/^STATUS:.*/STATUS: Approved/' "\$f"
    "\$T" done "\$RELAY_TASK" --agent "\$RELAY_AGENT" >/dev/null 2>&1 ;;
  keepclaimed)
    printf '\n### Round 1 · Reviewer · %s\nlooks fine\n' "\$RELAY_AGENT" >>"\$f"
    perl -pi -e 's/^STATUS:.*/STATUS: Approved/' "\$f" ;;
  citeafter)
    printf '\n### Round 1 · Reviewer · %s\nsee \`src.txt\`\n**Verdict:** Approved\n' "\$RELAY_AGENT" >>"\$f"
    perl -pi -e 's/^STATUS:.*/STATUS: Approved/' "\$f"
    "\$T" done "\$RELAY_TASK" --agent "\$RELAY_AGENT" >/dev/null 2>&1 ;;
  parentcommit|approve|failafter)
    printf '\n### Round 1 · Reviewer · %s\n**Verdict:** Approved\n' "\$RELAY_AGENT" >>"\$f"
    perl -pi -e 's/^STATUS:.*/STATUS: Approved/; s/^NEXT:.*/NEXT: done/' "\$f"
    "\$T" done "\$RELAY_TASK" --agent "\$RELAY_AGENT" >/dev/null 2>&1
    [ "\$mode" = failafter ] && exit 1 ;;
esac
exit 0
STUB_EOF
chmod +x "$STUB"

# ---- agent-cmd: every actor goes through the REAL codex-turn.sh with the stub binary ----
DISPATCH="$WORK/dispatch.sh"
cat >"$DISPATCH" <<EOF
#!/usr/bin/env bash
export CODEX_AGENT="\$RELAY_AGENT" CODEX_BIN="$STUB" CODEX_TURN_ROOT="$A" CODEX_LOG="$WORK/codex-\$RELAY_TASK.log"
# B4: a peer commit that lands AFTER the driver pinned the revision and BEFORE the shim cuts its worktree
if [ "\${STUB_MODE:-}" = parentcommit ]; then printf 'v2\n' >"$A/src.txt"; git -C "$A" commit -qam "peer commit between pin and cut" >/dev/null 2>&1; fi
exec bash "$MAIN/relay-automation/codex-turn.sh"
EOF
chmod +x "$DISPATCH"

seed_to(){ # <task> <agent>
  tick_a log task.created "$1" --agent claude-a >/dev/null
  tick_a claim "$1" --agent claude-a --paths relay.md >/dev/null
  tick_a release "$1" --agent claude-a --to "$2" >/dev/null
}
reset_repo(){ git -C "$A" reset -q --hard "$SEED" >/dev/null 2>&1; git -C "$A" clean -qfd >/dev/null 2>&1; rm -rf "$MAIN/.relay-scratch"; rm -f "$(git -C "$A" rev-parse --absolute-git-dir)"/relay-attest/*.json 2>/dev/null; }
SEED="$(git -C "$A" rev-parse HEAD)"
run_driver(){ # <driver.py> <task> <stub-mode> [extra driver args…]  — stderr+stdout to $WORK/out-<task>
  local drv="$1" task="$2" mode="$3"; shift 3
  env -u RELAY_DRIVER_LOCKED RELAY_TARGET_ROOT="$A" TICK_REPO_ROOT="$A" TICK_BIN="$TICK" XYZ_ROOT="$MAIN" \
    RELAY_WORKTREE_ISOLATION="${ISO:-1}" STUB_MODE="$mode" \
    python3 "$drv" --relay-file "$A/relay.md" --relay-task "$task" --agent-cmd "$DISPATCH" --round-cap 2 "$@" \
    >"$WORK/out-$task" 2>&1
}
reason(){ cat "$MAIN/.relay-scratch/escalation-reason" 2>/dev/null; }
record_path(){ echo "$(git -C "$A" rev-parse --absolute-git-dir)/relay-attest/$1.json"; }

echo "== test: gh505-relay-attest =="

# --- A: builder-role turn forges STATUS: Approved -------------------------------------------------
reset_repo; seed_to T-A bld
run_driver "$DRIVER" T-A approve --reviewer rev --builder bld; rc=$?
[ -f "$WORK/ran-bld-T-A" ] && pass "A: the stub builder turn really ran through codex-turn" || fail "A: builder stub did not run"
[ "$rc" -eq 4 ] && pass "A: builder-written Approved → driver exits 4" || fail "A: expected exit 4, got $rc: $(tail -3 "$WORK/out-T-A")"
[ "$(reason)" = forged-terminal ] && pass "A: escalation reason is forged-terminal" || fail "A: reason=$(reason)"
grep -q '^STATUS: Open' "$A/relay.md" && pass "A: STATUS restored on disk" || fail "A: STATUS not restored: $(grep '^STATUS' "$A/relay.md")"
grep -q '^STATUS: Open' <<<"$(git -C "$A" show HEAD:relay.md)" && pass "A: STATUS restored in HEAD (revert committed)" || fail "A: HEAD still carries the forged STATUS"
grep -q 'revert unattestable terminal' <<<"$(git -C "$A" log -1 --format=%s)" && pass "A: revert commit is the driver's" || fail "A: last commit: $(git -C "$A" log -1 --format=%s)"
! grep -q 'Attestation · relay-drive' "$A/relay.md" && pass "A: no attestation trailer" || fail "A: trailer present after a forgery"
[ ! -f "$(record_path T-A)" ] && pass "A: no record written" || fail "A: record written for a forgery"

# --- A2: the same forgery on a FAILED turn (codex exits non-zero; GH-432 still commits the turn) ---
#         keeps the shim's own exit code and is still reverted — never attested.
reset_repo; seed_to T-A2 bld
run_driver "$DRIVER" T-A2 failafter --reviewer rev --builder bld; rc=$?
[ "$rc" -eq 5 ] && pass "A2: failed turn keeps the shim's exit 5 (not 4)" || fail "A2: expected 5, got $rc: $(tail -3 "$WORK/out-T-A2")"
[ "$(reason)" = forged-terminal ] && pass "A2: reason still names the forgery" || fail "A2: reason=$(reason)"
grep -q '^STATUS: Open' <<<"$(git -C "$A" show HEAD:relay.md)" && pass "A2: forged STATUS reverted in HEAD on the failure path" || fail "A2: HEAD still forged"
[ ! -f "$(record_path T-A2)" ] && pass "A2: no record" || fail "A2: record written on a failed turn"

# --- A3: a FAILED reviewer turn that approved is reverted, never attested (shim's exit preserved) --
reset_repo; seed_to T-A3 rev
run_driver "$DRIVER" T-A3 failafter --reviewer rev --builder bld; rc=$?
[ "$rc" -eq 5 ] && pass "A3: failed reviewer turn keeps the shim's exit 5" || fail "A3: expected 5, got $rc: $(grep -v GH-370 "$WORK/out-T-A3" | tail -3)"
[ "$(reason)" = failed-turn-terminal ] && pass "A3: reason is failed-turn-terminal" || fail "A3: reason=$(reason)"
grep -q '^STATUS: Open' <<<"$(git -C "$A" show HEAD:relay.md)" && pass "A3: the failed turn's Approved reverted in HEAD" || fail "A3: HEAD still Approved"
[ ! -f "$(record_path T-A3)" ] && ! grep -q 'Attestation · relay-drive' "$A/relay.md" && pass "A3: no trailer, no record" || fail "A3: attestation published for a failed turn"

# --- B: reviewer-role approval is attested -------------------------------------------------------
reset_repo; seed_to T-B rev
HEAD_BEFORE="$(git -C "$A" rev-parse HEAD)"
run_driver "$DRIVER" T-B approve --reviewer rev --builder bld; rc=$?
[ "$rc" -eq 0 ] && pass "B: reviewer approval → driver exits 0" || fail "B: expected 0, got $rc: $(tail -5 "$WORK/out-T-B")"
grep -q '^### Attestation · relay-drive' "$A/relay.md" && pass "B: attestation trailer appended" || fail "B: no trailer"
grep -q "^reviewed-head: $HEAD_BEFORE" "$A/relay.md" && pass "B: reviewed-head = HEAD before dispatch" || fail "B: reviewed-head wrong: $(grep '^reviewed-head' "$A/relay.md")"
[ "$(cat "$WORK/wt-cut-T-B")" = "$HEAD_BEFORE" ] && pass "B: the isolated worktree was cut at the pinned revision" || fail "B: worktree cut at $(cat "$WORK/wt-cut-T-B")"
SHIM_COMMIT="$(git -C "$A" log --format=%H --grep='rev turn' -1)"
[ -n "$SHIM_COMMIT" ] && [ "$(git -C "$A" rev-parse "$SHIM_COMMIT^")" = "$HEAD_BEFORE" ] && pass "B: reviewed-head is the parent of the shim's commit" || fail "B: shim commit parentage wrong"
python3 - "$MAIN" "$A/relay.md" "$(record_path T-B)" <<'PY' && pass "B: record loads for reviewer rev; digest = sha256(exactly the appended bytes)" || fail "B: record validation failed"
import sys, os, json, hashlib
sys.path.insert(0, os.path.join(sys.argv[1], "utils", "py")); import relay_attest
rec, why = relay_attest.load("T-B", expected_reviewer="rev", relay_file=sys.argv[2], target_repo=os.path.dirname(sys.argv[2]))
assert rec, why
canon = relay_attest.canonical(sys.argv[2])
added = canon[rec["added_start"]:rec["added_start"]+rec["added_len"]]
assert b"Round 1 \xc2\xb7 Reviewer" in added and b"seeded body" not in added, added
assert hashlib.sha256(added).hexdigest() == rec["added_sha256"]
ok, why = relay_attest.candidate_ok(rec, relay_attest.rev_parse(os.path.dirname(sys.argv[2])), os.path.dirname(sys.argv[2]))
assert ok, why
PY

# --- B4: a parent commit during the turn does not move reviewed_head; candidate check refuses -----
reset_repo; seed_to T-B4 rev
HEAD_BEFORE="$(git -C "$A" rev-parse HEAD)"
run_driver "$DRIVER" T-B4 parentcommit --reviewer rev --builder bld; rc=$?
[ "$rc" -eq 0 ] && pass "B4: approval still attested (the reviewer read the pinned revision)" || fail "B4: rc=$rc: $(tail -3 "$WORK/out-T-B4")"
grep -q "^reviewed-head: $HEAD_BEFORE" "$A/relay.md" && pass "B4: reviewed-head is the PRE-dispatch revision, not the peer commit" || fail "B4: reviewed-head moved"
[ "$(cat "$WORK/head-at-turn-T-B4")" != "$HEAD_BEFORE" ] && pass "B4: control — HEAD had already moved when the shim started" || fail "B4: control — peer commit did not land before the cut"
[ "$(cat "$WORK/wt-cut-T-B4")" = "$HEAD_BEFORE" ] && pass "B4: worktree cut at the pin even though HEAD moved before the cut" || fail "B4: cut at $(cat "$WORK/wt-cut-T-B4")"
python3 - "$MAIN" "$A/relay.md" <<'PY' && pass "B4: candidate_ok REFUSES the HEAD that carries the peer's source change" || fail "B4: candidate_ok accepted drifted HEAD"
import sys, os
sys.path.insert(0, os.path.join(sys.argv[1], "utils", "py")); import relay_attest
repo = os.path.dirname(sys.argv[2])
rec, why = relay_attest.load("T-B4", expected_reviewer="rev", relay_file=sys.argv[2], target_repo=repo); assert rec, why
ok, why = relay_attest.candidate_ok(rec, relay_attest.rev_parse(repo), repo)
assert not ok and "non-transcript" in why, why
PY

# --- B5: the harness downgrades an uncited [Pass] claim in place after the reviewer's turn -------
reset_repo; seed_to T-B5 rev
run_driver "$DRIVER" T-B5 uncited --reviewer rev --builder bld; rc=$?
[ "$rc" -eq 0 ] && pass "B5: harness's uncited-claim downgrade does not read as a body rewrite; approval attested" || fail "B5: rc=$rc reason=$(reason): $(grep -v 'GH-370' "$WORK/out-T-B5" | tail -4)"
grep -q 'Unverified — no citation' "$A/relay.md" && pass "B5: the downgrade really happened (control)" || fail "B5: control — no downgrade marker in the file"
python3 - "$MAIN" "$A/relay.md" <<'PY' && pass "B5: record still loads after the downgrade" || fail "B5: record does not load"
import sys, os
sys.path.insert(0, os.path.join(sys.argv[1], "utils", "py")); import relay_attest
rec, why = relay_attest.load("T-B5", expected_reviewer="rev", relay_file=sys.argv[2], target_repo=os.path.dirname(sys.argv[2])); assert rec, why
PY

# --- B6: an old uncited claim gains a citation from the reviewer's appended lines ------------------
reset_repo
printf '# RELAY · fixture\n\nNEXT: rev\nSTATUS: Open\nROUND: 1 / 2\n\n## Body\n\nverified the seed\n' >"$A/relay.md"; git -C "$A" commit -qam "seed with trailing uncited claim" >/dev/null
seed_to T-B6 rev
run_driver "$DRIVER" T-B6 citeafter --reviewer rev --builder bld; rc=$?
[ "$rc" -eq 0 ] && pass "B6: appended citation changes the harness's judgement of an OLD line without reading as a rewrite" || fail "B6: rc=$rc reason=$(reason): $(grep -v GH-370 "$WORK/out-T-B6" | tail -4)"
grep -q '^verified the seed$' "$A/relay.md" && pass "B6: control — the old claim stayed un-stamped (the awk saw the new citation)" || fail "B6: control — old claim line is: $(grep 'verified the seed' "$A/relay.md")"
# --- B7: CRLF relay file ------------------------------------------------------------------------
reset_repo
printf '# RELAY · fixture\r\n\r\nNEXT: rev\r\nSTATUS: Open\r\nROUND: 1 / 2\r\n\r\nbody line\r\n' >"$A/relay.md"; git -C "$A" commit -qam "seed crlf" >/dev/null
seed_to T-B7 rev
run_driver "$DRIVER" T-B7 approve --reviewer rev --builder bld; rc=$?
[ "$rc" -eq 0 ] && pass "B7: CRLF relay file attested" || fail "B7: rc=$rc reason=$(reason)"
python3 - "$MAIN" "$A/relay.md" <<'PY' && pass "B7: record loads on the CRLF file" || fail "B7: record does not load"
import sys, os
sys.path.insert(0, os.path.join(sys.argv[1], "utils", "py")); import relay_attest
rec, why = relay_attest.load("T-B7", expected_reviewer="rev", relay_file=sys.argv[2], target_repo=os.path.dirname(sys.argv[2])); assert rec, why
PY
reset_repo; git -C "$A" reset -q --hard "$SEED"

# --- C: already terminal at startup, token done, no turn ------------------------------------------
reset_repo; seed_to T-C rev; tick_a claim T-C --agent rev --paths relay.md >/dev/null; tick_a done T-C --agent rev >/dev/null
perl -pi -e 's/^STATUS:.*/STATUS: Approved/' "$A/relay.md"; git -C "$A" commit -qam "pre-approved" >/dev/null
run_driver "$DRIVER" T-C approve --reviewer rev --builder bld; rc=$?
[ "$rc" -eq 4 ] && [ "$(reason)" = unattested-terminal ] && pass "C: pre-approved file → unattested-terminal (exit 4)" || fail "C: rc=$rc reason=$(reason)"
[ ! -f "$WORK/ran-rev-T-C" ] && pass "C: no turn dispatched" || fail "C: a turn ran"

# --- D1 / D3 ------------------------------------------------------------------------------------
reset_repo; seed_to T-D1 rev
run_driver "$DRIVER" T-D1 statusonly --reviewer rev --builder bld; rc=$?
[ "$rc" -eq 4 ] && [ "$(reason)" = empty-approval ] && pass "D1: STATUS-only approval → empty-approval" || fail "D1: rc=$rc reason=$(reason)"
reset_repo; seed_to T-D3 rev
run_driver "$DRIVER" T-D3 rewrite --reviewer rev --builder bld; rc=$?
[ "$rc" -eq 4 ] && [ "$(reason)" = review-body-rewritten ] && pass "D3: rewritten body → review-body-rewritten" || fail "D3: rc=$rc reason=$(reason)"
[ ! -f "$(record_path T-D3)" ] && pass "D3: no record" || fail "D3: record written"

# --- E2 / E3 / S1: refusals before any tick mutation --------------------------------------------
reset_repo
seed_to T-E2 rev
run_driver "$DRIVER" T-E2 approve; rc=$?
[ "$rc" -eq 4 ] && [ "$(reason)" = forged-terminal ] && grep -q 'WARNING — no --reviewer' "$WORK/out-T-E2" && pass "E2: no --reviewer → warned at startup; the approval is refused as forged (no reviewer can exist)" || fail "E2: rc=$rc reason=$(reason)"
[ ! -f "$(record_path T-E2)" ] && pass "E2: no record" || fail "E2: record written without a named reviewer"
run_driver "$DRIVER" T-E3 approve --reviewer rev --builder rev; rc=$?
[ "$rc" -eq 2 ] && pass "E3: builder == reviewer → exit 2" || fail "E3: rc=$rc"
ISO=false run_driver "$DRIVER" T-S1 approve --reviewer rev --builder bld; rc=$?
[ "$rc" -eq 2 ] && grep -q 'RELAY_WORKTREE_ISOLATION must be 0 or 1' "$WORK/out-T-S1" && pass "S1: RELAY_WORKTREE_ISOLATION=false refused before dispatch" || fail "S1: rc=$rc"
[ ! -f "$WORK/ran-rev-T-S1" ] && pass "S1: no turn dispatched" || fail "S1: a turn ran"

# --- K: reviewer approves but leaves the token claimed -------------------------------------------
# Through the real shim this cannot happen — rtl_enforce closes a terminal turn's token itself
# (GH-67/GH-165) — so K1 pins that, and K2 exercises the driver's own gate with a BARE agent-cmd
# (a custom --agent-cmd with no containment), which is exactly the caller the gate exists for.
reset_repo; seed_to T-K1 rev
run_driver "$DRIVER" T-K1 keepclaimed --reviewer rev --builder bld; rc=$?
[ "$rc" -eq 0 ] && [ "$(tick_a info T-K1 | sed -n 's/^status:[[:space:]]*//p')" = done ] && pass "K1: the shim closes the token for a terminal reviewer turn; approval attested" || fail "K1: rc=$rc token=$(tick_a info T-K1 | sed -n 's/^status:[[:space:]]*//p')"
BARE="$WORK/bare-agent.sh"
cat >"$BARE" <<BARE_EOF
#!/usr/bin/env bash
export TICK_REPO_ROOT="$A"
"$TICK" claim "\$RELAY_TASK" --agent "\$RELAY_AGENT" --paths relay.md >/dev/null 2>&1
printf '\n### Round 1 · Reviewer · %s\nfine\n' "\$RELAY_AGENT" >>"$A/relay.md"
perl -pi -e 's/^STATUS:.*/STATUS: Approved/' "$A/relay.md"
exit 0
BARE_EOF
chmod +x "$BARE"
reset_repo; seed_to T-K2 rev
env -u RELAY_DRIVER_LOCKED RELAY_TARGET_ROOT="$A" TICK_REPO_ROOT="$A" TICK_BIN="$TICK" XYZ_ROOT="$MAIN" RELAY_WORKTREE_ISOLATION=0 \
  python3 "$DRIVER" --relay-file "$A/relay.md" --relay-task T-K2 --agent-cmd "$BARE" --round-cap 2 --reviewer rev --builder bld >"$WORK/out-T-K2" 2>&1; rc=$?
[ "$rc" -eq 4 ] && [ "$(reason)" = close-mismatch ] && pass "K2: bare agent-cmd leaves the token claimed → close-mismatch, not attested" || fail "K2: rc=$rc reason=$(reason): $(tail -3 "$WORK/out-T-K2")"
[ ! -f "$(record_path T-K2)" ] && pass "K2: no record" || fail "K2: record written with a live token"
tick_a done T-K2 --agent rev >/dev/null 2>&1 || true   # release the bare agent's live claim on relay.md

# --- L: the reader refuses tampering ------------------------------------------------------------
reset_repo; seed_to T-L rev
run_driver "$DRIVER" T-L approve --reviewer rev --builder bld; rc=$?
[ "$rc" -eq 0 ] && pass "L: fixture approval attested" || fail "L: fixture driver rc=$rc: $(grep -v 'GH-370 progress' "$WORK/out-T-L" | tail -6)"
python3 - "$MAIN" "$A/relay.md" "$(record_path T-L)" <<'PY' && pass "L: reader refuses wrong reviewer / edited STATUS / edited review text / truncated record" || fail "L: reader accepted a tampered record"
import sys, os, json, shutil
sys.path.insert(0, os.path.join(sys.argv[1], "utils", "py")); import relay_attest
rf, rp = sys.argv[2], sys.argv[3]; repo = os.path.dirname(rf)
ok = lambda **kw: relay_attest.load("T-L", expected_reviewer=kw.get("rev","rev"), relay_file=rf, target_repo=repo)[0]
assert ok(), "baseline must load"
assert not ok(rev="bld"), "wrong reviewer accepted"
orig = open(rf, "rb").read()
open(rf, "wb").write(orig.replace(b"STATUS: Approved", b"STATUS: Closed", 1)); assert not ok(), "STATUS edit accepted"
open(rf, "wb").write(orig.replace(b"**Verdict:** Approved", b"**Verdict:** Rejected", 1)); assert not ok(), "review-text edit accepted"
open(rf, "wb").write(orig); assert ok()
rec = open(rp).read(); open(rp, "w").write(rec[: len(rec)//2]); assert not ok(), "truncated record accepted"
import json as _j
d = _j.loads(rec); d.pop("attested_at"); open(rp, "w").write(_j.dumps(d)); r = relay_attest.load("T-L", expected_reviewer="rev", relay_file=rf, target_repo=repo); assert r[0] is None and "attested_at" in r[1], r
d = _j.loads(rec); d["added_start"] = "12"; open(rp, "w").write(_j.dumps(d)); r = relay_attest.load("T-L", expected_reviewer="rev", relay_file=rf, target_repo=repo); assert r[0] is None and "integral" in r[1], r
d = _j.loads(rec); d["relay_file"] = 7; open(rp, "w").write(_j.dumps(d)); r = relay_attest.load("T-L", expected_reviewer="rev", relay_file=rf, target_repo=repo); assert r[0] is None, r
open(rp, "w").write(rec); assert ok()
PY

# --- N3: candidate binding for a tracked relay beside source files -------------------------------
python3 - "$MAIN" "$WORK" <<'PY' && pass "N3: neighbouring source drift refused; relay-only and ESCALATION.md-only changes pass" || fail "N3: candidate binding wrong for a relay beside source"
import sys, os, subprocess
sys.path.insert(0, os.path.join(sys.argv[1], "utils", "py")); import relay_attest
r = os.path.join(sys.argv[2], "n3"); os.makedirs(os.path.join(r, "src")); subprocess.run(["git", "init", "-q", r], check=True)
g = lambda *a: subprocess.run(["git", "-C", r] + list(a), check=True, capture_output=True)
rf = os.path.join(r, "src", "review[1].md"); open(rf, "w").write("STATUS: Approved\nbody\n"); open(os.path.join(r, "src", "service.py"), "w").write("v1\n")
g("add", "-A"); g("commit", "-qm", "seed"); reviewed = relay_attest.rev_parse(r)
rec = {"isolated": True, "artifact_sha256": None, "reviewed_head": reviewed, "relay_file_rel": "src/review[1].md"}
open(os.path.join(r, "src", "service.py"), "w").write("v2\n"); g("commit", "-qam", "drift")
ok, why = relay_attest.candidate_ok(rec, relay_attest.rev_parse(r), r); assert not ok and "non-transcript" in why, why
g("reset", "-q", "--hard", reviewed)
open(rf, "a").write("more review\n"); open(os.path.join(r, "src", "ESCALATION.md"), "w").write("x\n"); g("add", "-A"); g("commit", "-qm", "relay+record")
ok, why = relay_attest.candidate_ok(rec, relay_attest.rev_parse(r), r); assert ok, why
PY

# --- F / G: containment reads the driver; prompt ----------------------------------------------
RTL="$MAIN/relay-automation/relay-turn-lib.sh"
mkdir -p "$WORK/fg"; RF="$WORK/fg/RELAY.md"
printf 'STATUS: Open\nNEXT: bld (Builder)\n\n<!-- marathon-drive: task=X builder=rev reviewer=bld -->\n' >"$RF"
printf 'art\n' >"$WORK/fg/art.md"
git init -q "$WORK/fg"; git -C "$WORK/fg" add -A >/dev/null 2>&1; git -C "$WORK/fg" commit -qm seed >/dev/null 2>&1
role_of(){ ( export RELAY_DRIVER_LOCKED="${1}" RELAY_ROLE="${2}"; bash -c "source '$RTL' >/dev/null 2>&1; rtl_is_reviewer_turn '$RF' rev && echo reviewer || echo builder" ); }
[ "$(role_of 1 reviewer)" = reviewer ] && pass "F: RELAY_ROLE=reviewer outranks a directive that calls the agent builder" || fail "F: got $(role_of 1 reviewer)"
[ "$(role_of 1 builder)" = builder ] && pass "F: RELAY_ROLE=builder outranks a directive that calls the agent reviewer" || fail "F: got $(role_of 1 builder)"
[ "$(role_of '' reviewer)" = builder ] && pass "F2: without RELAY_DRIVER_LOCKED the directive still decides" || fail "F2: got $(role_of '' reviewer)"
python3 - "$MAIN" "$RF" <<'PY' && pass "F: same answer through the rtl.py bridge (allowlist narrows to the relay file for a reviewer)" || fail "F: rtl.py bridge disagrees"
import sys, os
sys.path.insert(0, os.path.join(sys.argv[1], "utils", "py")); from rtl import RelayTurnLib
os.environ["RELAY_DRIVER_LOCKED"] = "1"
root = os.path.dirname(sys.argv[2])
def is_rev():
    lib = RelayTurnLib(root, sys.argv[1], sys.argv[2], "art.md")
    r = lib._run_rtl(f"rtl_is_reviewer_turn '{sys.argv[2]}' rev && echo yes || echo no")
    return (getattr(r, "stdout", r) or "").strip().endswith("yes")
os.environ["RELAY_ROLE"] = "reviewer"; assert is_rev()
os.environ["RELAY_ROLE"] = "builder";  assert not is_rev()
PY
prompt_of(){ ( export RELAY_DRIVER_LOCKED=1 RELAY_ROLE="$1"; bash -c "source '$RTL' >/dev/null 2>&1; rtl_init '$WORK/fg' '$RF' 'art.md' >/dev/null 2>&1; rtl_turn_prompt rev '$RF' T-G art.md peer" ); }
BP="$(prompt_of builder)"; RP="$(prompt_of reviewer)"
[ -n "$BP" ] && [ -n "$RP" ] && pass "G: both prompts render non-empty" || fail "G: empty prompt"
! grep -q 'STATUS: Approved' <<<"$BP" && pass "G: builder prompt does not invite STATUS: Approved" || fail "G: builder prompt still says Approved"
grep -q 'set STATUS: Approved' <<<"$RP" && pass "G: reviewer prompt carries the approval instruction" || fail "G: reviewer prompt lacks it"

# --- I / J: jog landing (GH-510) + no override ---------------------------------------------------
JOGA="$WORK/jog"; git init -q "$JOGA"; git -C "$JOGA" commit -q --allow-empty -m init
GHBIN="$WORK/ghbin"; mkdir -p "$GHBIN"
cat >"$GHBIN/gh" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >>"$GH_ARGS"
case "$*" in
  *"pr list"*) printf '%s\n' "${GH_PR-42}" ;;
  *"pr view"*) printf '{"state":"OPEN","baseRefName":"development","number":42,"headRefName":"feat/gh7","headRefOid":"%s"}\n' "$GH_HEAD" ;;
  *"pr merge"*) exit "${GH_MERGE_RC:-0}" ;;
esac
exit 0
EOF
chmod +x "$GHBIN/gh"
python3 - "$MAIN" "$JOGA" "$GHBIN" <<'PY' && pass "I/J: jog landing parks on merge failure, missing PR, drifted candidate; merges with --match-head-commit; no driver override" || fail "I/J: jog landing assertions failed"
import sys, os, io, json, subprocess, time, importlib.util
harness, repo, ghbin = sys.argv[1:4]
sys.path.insert(0, os.path.join(harness, "utils", "py"))
import relay_attest
spec = importlib.util.spec_from_file_location("jog_run", os.path.join(harness, "utils", "py", "jog_run.py")); jog = importlib.util.module_from_spec(spec); spec.loader.exec_module(jog)
os.environ["PATH"] = ghbin + os.pathsep + os.environ["PATH"]
os.environ["GH_ARGS"] = os.path.join(repo, "gh-args")
# a real attestation for RELAY-gh7-jog-drive over a tracked relay file
d = os.path.join(repo, "relay-system", "2026-09-08"); os.makedirs(d); rf = os.path.join(d, "gh7-jog-drive.md")
open(rf, "w").write("# RELAY · GH-7\n\nNEXT: rev\nSTATUS: Open\nROUND: 1 / 2\n\nbody\n")
subprocess.run(["git", "-C", repo, "add", "-A"], check=True); subprocess.run(["git", "-C", repo, "commit", "-qm", "relay"], check=True)
pre = relay_attest.canonical(rf)
open(rf, "a").write("\n### Round 1 · Reviewer · rev\nok\n"); txt = open(rf).read(); open(rf, "w").write(txt.replace("STATUS: Open", "STATUS: Approved", 1))
post = relay_attest.canonical(rf); added = post[len(pre):]
rec = {"schema": relay_attest.SCHEMA, "task": "RELAY-gh7-jog-drive", "transcript_repo": repo, "relay_file": rf,
       "relay_file_rel": "relay-system/2026-09-08/gh7-jog-drive.md", "target_repo": repo, "reviewer": "rev", "status": "Approved",
       "isolated": True, "reviewed_head": relay_attest.rev_parse(repo), "artifact_sha256": None, "added_start": len(pre),
       "added_len": len(added), "added_sha256": relay_attest.sha256(added), "attested_at": "t", "driver_pid": 1}
tr = relay_attest.trailer_text(rec); rec["trailer_sha256"] = relay_attest.sha256(tr.encode()); open(rf, "a").write(tr); relay_attest.write(rec)
subprocess.run(["git", "-C", repo, "commit", "-qam", "attest"], check=True)   # transcript-only commit → still a valid candidate
head = relay_attest.rev_parse(repo)
rec_chk, why_chk = jog._legacy_attestation(repo, 7, "rev"); assert rec_chk, f"fixture attestation does not load: {why_chk}"
os.environ["TICK_REPO_ROOT"] = repo
tick = os.environ["TICK_BIN"]
subprocess.run([tick, "init"], cwd=repo, check=True, capture_output=True)
class TTY(io.StringIO):
    def isatty(self): return True
def land(auto, **env):
    for k, v in env.items(): os.environ[k] = v
    sys.stdin = TTY("y\n")
    open(os.environ["GH_ARGS"], "w").close()
    return jog.handle_landing_boundary(repo, 7, auto_merge=auto, reviewer="rev")
# I0: the record is valid but the token does not exist → parked (token must read done)
r = land(False, GH_HEAD=head, GH_MERGE_RC="0"); assert r[1] == "parked" and ("not done" in r[2] or "not found" in r[2] or "unreadable" in r[2]), r
assert "pr merge" not in open(os.environ["GH_ARGS"]).read()
for cmd in (["log", "task.created", "RELAY-gh7-jog-drive", "--agent", "seed"], ["claim", "RELAY-gh7-jog-drive", "--agent", "rev", "--paths", "relay-system/2026-09-08/gh7-jog-drive.md"], ["done", "RELAY-gh7-jog-drive", "--agent", "rev"]):
    subprocess.run([tick] + cmd, cwd=repo, check=True, capture_output=True)
# I1: clean candidate merges, bound to the exact SHA
r = land(False, GH_HEAD=head, GH_MERGE_RC="0"); assert r[0] and r[1] == "completed", r
assert f"pr merge 42 --merge --auto=false --match-head-commit {head}" in open(os.environ["GH_ARGS"]).read()
# I2: merge fails → parked (was: completed)
r = land(False, GH_HEAD=head, GH_MERGE_RC="1"); assert r == (False, "parked", r[2]) and "merge failed" in r[2], r
# I3: no PR → parked (was: completed)
r = land(False, GH_PR="", GH_MERGE_RC="0"); assert r[0] is False and r[1] == "parked" and "no open PR" in r[2], r
os.environ.pop("GH_PR")
# I4: candidate drifted (source commit after the reviewed head) → parked before merge
open(os.path.join(repo, "code.txt"), "w").write("x\n"); subprocess.run(["git", "-C", repo, "add", "-A"], check=True); subprocess.run(["git", "-C", repo, "commit", "-qm", "code"], check=True)
drift = relay_attest.rev_parse(repo)
r = land(False, GH_HEAD=drift, GH_MERGE_RC="0"); assert r[1] == "parked" and "candidate-drifted" in r[2], r
assert "pr merge" not in open(os.environ["GH_ARGS"]).read()
# I5: auto branch, same three
r = land(True, GH_HEAD=drift); assert r[1] == "parked" and "candidate-drifted" in r[2], r
r = land(True, GH_HEAD=head, GH_MERGE_RC="1"); assert r[1] == "parked", r
# J: run_single_phase_drive returns the driver's exit unchanged even when the file says Approved
stub = os.path.join(repo, "relay-automation"); os.makedirs(stub); s = os.path.join(stub, "relay-drive.sh"); open(s, "w").write("#!/usr/bin/env bash\nexit 4\n"); os.chmod(s, 0o755)
ma = os.path.join(stub, "marathon-agent.sh"); open(ma, "w").write("#!/usr/bin/env bash\nexit 0\n"); os.chmod(ma, 0o755)
assert jog.run_single_phase_drive(repo, 7, builder="bld", reviewer="rev") == 4
assert jog.run_single_phase_drive(repo, 7, builder="bld", reviewer=None) == 2
assert jog.run_single_phase_drive(repo, 7, builder="rev", reviewer="rev") == 2
PY

# --- Red controls: the BASE driver, invoked without the new flags, accepts both forgeries --------
BASE="$WORK/base"; mkdir -p "$BASE"
if git -C "$REPO" archive "$BASE_SHA" relay-automation utils bin src 2>/dev/null | tar -x -C "$BASE"; then
  git init -q "$BASE"; git -C "$BASE" add -A >/dev/null 2>&1; git -C "$BASE" commit -qm base >/dev/null 2>&1
  DISPATCH_BASE="$WORK/dispatch-base.sh"; sed "s#$MAIN/relay-automation#$BASE/relay-automation#" "$DISPATCH" >"$DISPATCH_BASE"; chmod +x "$DISPATCH_BASE"
  reset_repo; seed_to T-RA bld
  env -u RELAY_DRIVER_LOCKED RELAY_TARGET_ROOT="$A" TICK_REPO_ROOT="$A" TICK_BIN="$TICK" XYZ_ROOT="$BASE" RELAY_WORKTREE_ISOLATION=1 STUB_MODE=approve \
    python3 "$BASE/utils/py/relay_drive.py" --relay-file "$A/relay.md" --relay-task T-RA --agent-cmd "$DISPATCH_BASE" --round-cap 2 >"$WORK/out-T-RA" 2>&1; rc=$?
  [ "$rc" -eq 0 ] && pass "RED CONTROL A: base driver ($BASE_SHA) exits 0 on a BUILDER-written Approved" || fail "red control A: base rc=$rc (expected 0): $(tail -3 "$WORK/out-T-RA")"
  reset_repo; seed_to T-RC rev; tick_a claim T-RC --agent rev --paths relay.md >/dev/null; tick_a done T-RC --agent rev >/dev/null
  perl -pi -e 's/^STATUS:.*/STATUS: Approved/' "$A/relay.md"; git -C "$A" commit -qam "pre-approved" >/dev/null
  env -u RELAY_DRIVER_LOCKED RELAY_TARGET_ROOT="$A" TICK_REPO_ROOT="$A" TICK_BIN="$TICK" XYZ_ROOT="$BASE" \
    python3 "$BASE/utils/py/relay_drive.py" --relay-file "$A/relay.md" --relay-task T-RC --agent-cmd "$DISPATCH_BASE" --round-cap 2 >"$WORK/out-T-RC" 2>&1; rc=$?
  [ "$rc" -eq 0 ] && pass "RED CONTROL C: base driver exits 0 on a pre-approved file after 0 turns" || fail "red control C: base rc=$rc"
else
  pass "red controls skipped: base $BASE_SHA not present in this clone (set GH505_BASE_SHA)"
fi

exit 0
