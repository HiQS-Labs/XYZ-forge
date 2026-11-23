#!/usr/bin/env bash
# GH-1537 manual red/green check (no new suite, GH-831).
#
# Drives REAL `git push` runs through the installed pre-push stub in throwaway fixtures (a bare origin plus two
# clones), with the REAL githooks/pre-push and utils/ci-route.sh and a STUB validate.sh / pdda.sh (so a "full gate"
# costs a second, not 15 minutes). Each scenario runs the SAME push twice, in fresh fixtures:
#   base = the pre-change hook (red side), cand = the candidate hook (green side)
# and records the route each chose (docs | full | tier2) plus which stub gate actually ran, in provenance.jsonl.
# The candidate's route must equal the desired route (WANT) in every scenario; scenarios where base != WANT are the RED rows.
#
# Usage: REPO=<candidate checkout> BASE_HOOK=<file with the pre-change githooks/pre-push> OUT=<results dir> bash check.sh
set -u
REPO="${REPO:?candidate checkout root}"
BASE_HOOK="${BASE_HOOK:?file holding the pre-change githooks/pre-push}"
OUT="${OUT:?results dir}"
CAND_HOOK="${CAND_HOOK:-$REPO/githooks/pre-push}"
[ -s "$BASE_HOOK" ] && [ -s "$CAND_HOOK" ] || { echo "hook files missing or empty" >&2; exit 2; }
mkdir -p "$OUT"
PROV="$OUT/provenance.jsonl"; : > "$PROV"; : > "$OUT/push-output.log"
W="$(mktemp -d "${TMPDIR:-/tmp}/gh1537-check.XXXXXX")"
[ -n "$W" ] && [ -d "$W" ] || { echo "mktemp failed" >&2; exit 2; }
trap 'rm -rf "$W"' EXIT
export PYTHONDONTWRITEBYTECODE=1 GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_SYSTEM=/dev/null \
  GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@t GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@t
REPO_HEAD="$(git -C "$REPO" rev-parse HEAD)"
G() { git "$@"; }   # plain git: hooks stay live, the installed stub IS the thing under test

route_of() {
  case "$1" in
    *"docs-only update"*) echo docs ;;
    *"utility-only update"*|*"tier 2 gate"*) echo tier2 ;;
    *"running the full gate before"*|*"reusing the passing full-gate receipt"*) echo full ;;
    *) echo unknown ;;
  esac
}
gate_ran() {  # which stub gate really executed
  case "$1" in
    *"stub documentation gate ran"*) echo docs-gate ;;
    *"stub full gate ran"*) echo full-gate ;;
    *) echo none ;;
  esac
}

# mkfx <hook-file> -> FX. origin has development (+main at the same seed); w = pushing clone with the hook installed;
# x = a second clone with NO hook, used to move origin behind w's back.
mkfx() {
  local hook="$1"
  FX="$(mktemp -d "$W/fx.XXXXXX")"
  [ -n "$FX" ] && [ -d "$FX" ] || { echo "fixture mktemp failed" >&2; exit 2; }
  git init -q --bare "$FX/o.git"
  git init -q -b development "$FX/w"
  ( cd "$FX/w" || exit 2
    mkdir -p githooks utils/pdda utils/py docs
    cp "$hook" githooks/pre-push; chmod +x githooks/pre-push
    cp "$REPO/githooks/install.sh" githooks/install.sh
    cp "$REPO/utils/ci-route.sh" utils/ci-route.sh; chmod +x utils/ci-route.sh
    cp "$REPO/utils/py/gate_receipt.py" utils/py/gate_receipt_impl.py
    cp "$REPO/utils/py/rtl.py" utils/py/
    cat > utils/py/gate_receipt.py <<'STUB'
import gate_receipt_impl as impl
def attempt_admission(*args, **kwargs):
    return {"kind": "fixture-admitted"}
impl.attempt_admission = attempt_admission
if __name__ == "__main__":
    impl.main()
STUB
    cat > validate.sh <<'STUB'
#!/usr/bin/env bash
if [ "${1:-}" = "--print-mode" ]; then echo "validate.sh: PARALLEL mode — stub"; exit 0; fi
echo "stub full gate ran"; exit 0
STUB
    chmod +x validate.sh
    printf '#!/usr/bin/env bash\necho "stub documentation gate ran"\n' > utils/pdda/pdda.sh; chmod +x utils/pdda/pdda.sh
    printf 'echo foo\n' > utils/foo.sh
    printf '# guide\nline one\n' > docs/guide.md
    printf '# readme\n' > README.md
    G add -A && G commit -qm seed
    G remote add origin "$FX/o.git"
    XYZ_SKIP_PREPUSH=1 G push -q -u origin development 2>/dev/null
    XYZ_SKIP_PREPUSH=1 G push -q origin development:refs/heads/main 2>/dev/null
    bash githooks/install.sh >/dev/null 2>&1
  )
  G clone -q "$FX/o.git" "$FX/x" 2>/dev/null
}

adv_dev() {  # <path> <line>: move origin/development behind w's back (from clone x, which has no hook)
  ( cd "$FX/x" && G checkout -q development && G pull -q origin development 2>/dev/null; printf '%s\n' "$2" >> "$1"; G add -A; G commit -qm "dev: $1"; XYZ_SKIP_PREPUSH=1 G push -q origin development 2>/dev/null )
}
wcommit() { ( cd "$FX/w" && printf '%s\n' "$2" >> "$1" && G add -A && G commit -qm "w: $1" ); }
wpush()   { local rc; ( cd "$FX/w" && G push "$@" 2>&1 ); rc=$?; printf '%s' "$rc" > "$FX/.push_rc"; return "$rc"; }   # real git push -> installed stub -> hook under test; exit status kept for provenance
wmerge()  { ( cd "$FX/w" && G fetch -q origin && G merge -q --no-edit "$1" ); }
first()   { ( cd "$FX/w" && G checkout -q -b "$1" && wcommit "$2" "branch edit" ) && XYZ_SKIP_PREPUSH=1 wpush -q -u origin "$1" >/dev/null; }

# ---- scenarios: each leaves the result in PUSHOUT and the desired route in WANT -----------------------------------------
sc_merge_only_docs()    { first docs-pr docs/guide.md; adv_dev utils/foo.sh "echo dev-code"; wmerge origin/development
                          PUSHOUT="$(wpush origin docs-pr)"; WANT=docs; }
sc_conflict_docs_only() { first conf-pr docs/guide.md; adv_dev docs/guide.md "dev docs edit"; adv_dev utils/foo.sh "echo dev-code"
                          ( cd "$FX/w" && G fetch -q origin && { G merge -q --no-commit origin/development >/dev/null 2>&1 || true; }
                            printf '# guide\nresolved by hand\n' > docs/guide.md; G add -A && G commit -qm "merge development (docs-only resolution)" )
                          PUSHOUT="$(wpush origin conf-pr)"; WANT=docs; }
sc_code_branch_merge()  { first code-pr utils/bar.sh; adv_dev utils/foo.sh "echo dev-code"; wmerge origin/development
                          PUSHOUT="$(wpush origin code-pr)"; WANT=full; }
sc_evil_merge_code()    { first evil-pr docs/guide.md; adv_dev docs/guide.md "dev docs edit"; adv_dev utils/foo.sh "echo dev-code"
                          ( cd "$FX/w" && G fetch -q origin && { G merge -q --no-commit origin/development >/dev/null 2>&1 || true; }
                            printf '# guide\nresolved by hand\n' > docs/guide.md; printf 'echo smuggled-in-resolution\n' > utils/baz.sh
                            G add -A && G commit -qm "merge development (resolution also adds code)" )
                          PUSHOUT="$(wpush origin evil-pr)"; WANT=full; }
sc_ours_merge_drops_dev_code() {  # Codex r1 F1: keeps the OLD source, edits a README; update range R..M reads docs, D..M carries the source
                          first ours-pr docs/guide.md; adv_dev utils/foo.sh "echo dev-code"
                          ( cd "$FX/w" && G fetch -q origin && G merge -q --no-commit -s ours origin/development >/dev/null 2>&1
                            printf 'readme edit in the merge\n' >> README.md; G add -A && G commit -qm "ours merge + README edit" )
                          PUSHOUT="$(wpush origin ours-pr)"; WANT=full; }
sc_other_branch_merge() { first om-pr docs/guide.md; adv_dev utils/foo.sh "echo dev-code"
                          ( cd "$FX/x" && G checkout -q -b other development 2>/dev/null && printf 'o\n' > docs/other.md && G add -A && G commit -qm "other docs" && XYZ_SKIP_PREPUSH=1 G push -q origin other 2>/dev/null )
                          wmerge origin/other; PUSHOUT="$(wpush origin om-pr)"; WANT=full; }
sc_side_tip_on_integration() {  # stated policy: a side commit already on development counts as an integration merge
                          first st-pr docs/guide.md
                          ( cd "$FX/x" && G checkout -q -b side origin/development 2>/dev/null && printf 'echo side\n' > utils/side.sh && G add -A && G commit -qm "side code" && XYZ_SKIP_PREPUSH=1 G push -q origin side 2>/dev/null
                            G checkout -q -B development origin/development && G merge -q --no-ff --no-edit side && XYZ_SKIP_PREPUSH=1 G push -q origin development 2>/dev/null )
                          wmerge origin/side; PUSHOUT="$(wpush origin st-pr)"; WANT=docs; }
sc_ff_import_no_merge() {  # Codex r1 F2: R -> D -> L with no merge commit; update range carries D's code
                          ( cd "$FX/w" && G push -q origin development:refs/heads/ff-pr 2>/dev/null ); adv_dev utils/foo.sh "echo dev-code"
                          ( cd "$FX/w" && G fetch -q origin && G checkout -q -B ff-pr origin/development && wcommit docs/guide.md "docs on top" )
                          PUSHOUT="$(wpush origin ff-pr)"; WANT=full; }
sc_stale_ours_merge()   {  # Codex r2 F6: the "ours" merge AND a stale tracking ref; the rejected candidate must still take full
                          first so-pr docs/guide.md; adv_dev utils/foo.sh "echo dev-code"
                          ( cd "$FX/w" && G fetch -q origin && G merge -q --no-commit -s ours origin/development >/dev/null 2>&1
                            printf 'readme edit in the merge\n' >> README.md; G add -A && G commit -qm "ours merge + README edit" )
                          adv_dev README.md "dev moved again after our fetch"; PUSHOUT="$(wpush origin so-pr)"; WANT=full; }
sc_other_branch_docs_only() {  # issue control (c) with docs-only content: a branch based on NEWER development, merged in
                          first od-pr docs/guide.md; adv_dev README.md "dev docs edit"
                          ( cd "$FX/x" && G checkout -q -b other2 development 2>/dev/null && printf 'o\n' > docs/other.md && G add -A && G commit -qm "other docs" && XYZ_SKIP_PREPUSH=1 G push -q origin other2 2>/dev/null )
                          wmerge origin/other2; PUSHOUT="$(wpush origin od-pr)"; WANT=full; }
sc_stale_before_merge_ours() {  # Codex r3 F6 residual: tracking tip B is OLDER than the merged commit D (advertised); "ours" merge keeps B's source
                          first sb-pr docs/guide.md; B="$(cd "$FX/w" && G rev-parse origin/development)"; adv_dev utils/foo.sh "echo dev-code"
                          ( cd "$FX/w" && G fetch -q origin && G merge -q --no-commit -s ours origin/development >/dev/null 2>&1
                            printf 'readme edit in the merge\n' >> README.md; G add -A && G commit -qm "ours merge + README edit"
                            G update-ref refs/remotes/origin/development "$B" )
                          PUSHOUT="$(wpush origin sb-pr)"; WANT=full; }
sc_rewound_tip_ours()   {  # Codex final QA r1 F1: the tracking tip CONTAINS the new merge M but advertised development was rewound to D
                          first rw-pr docs/guide.md; adv_dev utils/foo.sh "echo dev-code"
                          ( cd "$FX/w" && G fetch -q origin && G merge -q --no-commit -s ours origin/development >/dev/null 2>&1
                            printf 'readme edit in the merge\n' >> README.md; G add -A && G commit -qm "ours merge + README edit"
                            G update-ref refs/remotes/origin/development "$(G rev-parse HEAD)" )
                          PUSHOUT="$(wpush origin rw-pr)"; WANT=full; }
sc_followup_after_merge() {  # README-only follow-up after the merge is already on the remote: stays docs, no probe needed
                          first fu-pr docs/guide.md; adv_dev utils/foo.sh "echo dev-code"; wmerge origin/development
                          XYZ_SKIP_PREPUSH=1 wpush -q origin fu-pr >/dev/null; ( cd "$FX/w" && wcommit README.md "follow-up" )
                          PUSHOUT="$(wpush origin fu-pr)"; WANT=docs; }
sc_stale_base()         { first stale-pr docs/guide.md; adv_dev utils/foo.sh "echo dev-code"; wmerge origin/development
                          adv_dev README.md "dev moved again after our fetch"; PUSHOUT="$(wpush origin stale-pr)"; WANT=full; }
sc_push_to_main()       { first main-pr docs/guide.md; adv_dev utils/foo.sh "echo dev-code"; wmerge origin/development
                          PUSHOUT="$(wpush origin main-pr:refs/heads/main)"; WANT=full; }
sc_two_refs_code()      { first two-pr docs/guide.md; adv_dev utils/foo.sh "echo dev-code"; wmerge origin/development
                          ( cd "$FX/w" && G checkout -q -b twoc-pr development && wcommit utils/bar.sh "echo c" )
                          PUSHOUT="$(wpush origin two-pr twoc-pr)"; WANT=full; }
sc_two_refs_partial_failure() {  # Codex r1 F3: second ref's tree object is unreadable -> diff fails; partial stdout must not read as docs
                          first p1 docs/guide.md; first p2 README.md
                          ( cd "$FX/w" && G checkout -q p1 && wcommit docs/guide.md "p1 docs" && G checkout -q p2 && wcommit README.md "p2 docs"
                            t="$(G rev-parse 'p2^{tree}')"; chmod u+w ".git/objects/${t:0:2}/${t:2}" 2>/dev/null; rm -f ".git/objects/${t:0:2}/${t:2}" )
                          PUSHOUT="$(wpush origin p1 p2)"; WANT=full; }
sc_first_push_docs()    { ( cd "$FX/w" && G checkout -q -b first-pr && wcommit docs/guide.md "branch edit" ); PUSHOUT="$(wpush -u origin first-pr)"; WANT=docs; }
sc_first_push_code()    { ( cd "$FX/w" && G checkout -q -b firstc-pr && wcommit utils/bar.sh "echo branch-code" ); PUSHOUT="$(wpush -u origin firstc-pr)"; WANT=full; }
sc_linear_docs()        { first lin-pr docs/guide.md; ( cd "$FX/w" && wcommit docs/guide.md "two" ); PUSHOUT="$(wpush origin lin-pr)"; WANT=docs; }

SCENARIOS="merge_only_docs conflict_docs_only side_tip_on_integration code_branch_merge evil_merge_code ours_merge_drops_dev_code other_branch_merge other_branch_docs_only ff_import_no_merge stale_base stale_ours_merge stale_before_merge_ours rewound_tip_ours followup_after_merge push_to_main two_refs_code two_refs_partial_failure first_push_docs first_push_code linear_docs"
bad=0; red=0
printf '%-28s %-5s %-5s %-5s %s\n' scenario want base cand verdict
for s in $SCENARIOS; do
  for variant in base cand; do
    hook="$CAND_HOOK"; [ "$variant" = base ] && hook="$BASE_HOOK"
    mkfx "$hook"
    PUSHOUT=""; WANT=""
    "sc_$s"
    r="$(route_of "$PUSHOUT")"; g="$(gate_ran "$PUSHOUT")"; prc="$(cat "$FX/.push_rc" 2>/dev/null || echo na)"
    [ -n "$PUSHOUT" ] || { r=empty-capture; }
    eval "R_$variant=\$r; G_$variant=\$g"
    printf '%s\n' "$PUSHOUT" | sed "s|^|[$s/$variant] |" >> "$OUT/push-output.log"
    printf '{"scenario":"%s","variant":"%s","hook_sha256":"%s","repo_head":"%s","want":"%s","route":"%s","gate_ran":"%s","push_exit":"%s"}\n' \
      "$s" "$variant" "$(shasum -a 256 "$hook" | cut -c1-16)" "$REPO_HEAD" "$WANT" "$r" "$g" "$prc" >> "$PROV"
  done
  verdict="ok"
  [ "$R_cand" = "$WANT" ] || { verdict="CANDIDATE WRONG"; bad=$((bad+1)); }
  case "$R_cand:$G_cand" in docs:docs-gate|full:full-gate) ;; *) verdict="CANDIDATE WRONG (gate that ran does not match route)"; bad=$((bad+1)) ;; esac
  note=""; [ "$R_base" = "$WANT" ] || { note="(RED on base: $R_base)"; red=$((red+1)); }
  printf '%-28s %-5s %-5s %-5s %s %s\n' "$s" "$WANT" "$R_base" "$R_cand" "$verdict" "$note"
done
echo "candidate mismatches: $bad   rows red on base: $red"
[ "$bad" -eq 0 ]
