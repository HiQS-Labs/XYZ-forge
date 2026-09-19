#!/usr/bin/env bash
# test/pdda-install-startup-docs.sh — GH-23 P1 + GH-25.
#
# Two defects lived in the same four lines of install.sh:
#
#   GH-23 P1  --with-startup-docs copied the canonical repo's own ROUTER.md verbatim, so every target
#             was told to run install.sh and utils/pdda/pdda-sync.sh — neither of which a target has.
#   GH-25     copy_runtime has no create-only guard, so the same flag silently destroyed a
#             repo-authored AGENTS.md (61,829 bytes in LTVera-Pandas) with PDDA's 2,289-byte stub.
#
# These tests pin the fix: ROUTER.md is written from templates/ROUTER.target.md, and the startup docs
# are create-only unless --force.
set -uo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
REPO="$(cd "$HERE/.." && pwd)"
PASS=0; FAIL=0

ok()   { PASS=$((PASS+1)); printf 'ok   - %s\n' "$1"; }
bad()  { FAIL=$((FAIL+1)); printf 'FAIL - %s\n' "$1"; }
check(){ if [ "$1" = "$2" ]; then ok "$3"; else bad "$3 (want '$2', got '$1')"; fi; }

SBOX="$(mktemp -d "${TMPDIR:-/tmp}/pdda-install-startup.XXXXXX")"
[ -n "$SBOX" ] && [ -d "$SBOX" ] || exit 1
. "$HERE/lib/fixture-guard.sh"
require_forge_root ROUTER.md   # GH-708: forge-root only — witnessed skip in a vendored .xyz/
fixture_guard_init "$SBOX"
trap 'rm -rf "$SBOX"' EXIT

new_target() {  # <name> -> prints path
  local d="$SBOX/$1"
  mkdir -p "$d"
  require_fixture "$d" "new installer target"
  ( cd "$d" && git init -q . )
  printf '# README\n' > "$d/README.md"
  printf '%s\n' "$d"
}

# Anything the canonical repo has and a target does not. A target router naming any of these is the bug.
CANONICAL_ONLY='install\.sh|pdda-sync\.sh|\.xyz'

# ---------------------------------------------------------------------------------------------------
# 1. The template exists and is not just a copy of the canonical router.
# ---------------------------------------------------------------------------------------------------
if [ -f "$REPO/utils/pdda/templates/ROUTER.target.md" ]; then
  ok "templates/ROUTER.target.md exists"
else
  bad "templates/ROUTER.target.md exists"
fi

if cmp -s "$REPO/utils/pdda/templates/ROUTER.target.md" "$REPO/ROUTER.md"; then
  bad "target template differs from the canonical ROUTER.md"
else
  ok "target template differs from the canonical ROUTER.md"
fi

n=$(grep -cE "$CANONICAL_ONLY" "$REPO/utils/pdda/templates/ROUTER.target.md" || true)
check "$n" "0" "target template names zero canonical-only scripts/paths"

# The canonical router still legitimately documents them — the template is what got stripped, not it.
n=$(grep -cE "$CANONICAL_ONLY" "$REPO/ROUTER.md" || true)
if [ "$n" -gt 0 ]; then
  ok "canonical ROUTER.md still documents its own tooling ($n refs)"
else
  bad "canonical ROUTER.md lost its own tooling refs"
fi

# ---------------------------------------------------------------------------------------------------
# 2. A fresh --with-startup-docs install writes the template, never the canonical router.
# ---------------------------------------------------------------------------------------------------
T="$(new_target fresh)"
"$REPO/utils/pdda/pdda-install.sh" "$T" --with-startup-docs --no-register >/dev/null 2>&1

if cmp -s "$T/ROUTER.md" "$REPO/utils/pdda/templates/ROUTER.target.md"; then
  ok "installed ROUTER.md == templates/ROUTER.target.md"
else
  bad "installed ROUTER.md != templates/ROUTER.target.md"
fi

if cmp -s "$T/ROUTER.md" "$REPO/ROUTER.md"; then
  bad "installed ROUTER.md is NOT the canonical router"
else
  ok "installed ROUTER.md is NOT the canonical router"
fi

n=$(grep -cE "$CANONICAL_ONLY" "$T/ROUTER.md" || true)
check "$n" "0" "installed ROUTER.md names zero canonical-only scripts/paths"

# ---------------------------------------------------------------------------------------------------
# 3. Every *.sh path named in the installed router resolves inside the target. (P2's assertion.)
# ---------------------------------------------------------------------------------------------------
dead=0
while IFS= read -r ref; do
  [ -n "$ref" ] || continue
  [ -e "$T/$ref" ] || { dead=$((dead+1)); printf '     dead .sh ref: %s\n' "$ref"; }
done < <(grep -oE '[A-Za-z0-9_./-]+\.sh' "$T/ROUTER.md" | sort -u)
check "$dead" "0" "every .sh ref in the installed router exists in the target"

# ---------------------------------------------------------------------------------------------------
# 4. GH-25: a repo-authored AGENTS.md survives --with-startup-docs.
# ---------------------------------------------------------------------------------------------------
T="$(new_target authored)"
printf '# AGENTS.md\n\nMY HARD-WON REPO CONVENTIONS.\n' > "$T/AGENTS.md"
printf '# GUIDING-PRINCIPLES.md\n\nMY OWN PRINCIPLES.\n' > "$T/GUIDING-PRINCIPLES.md"
a_before=$(md5 -q "$T/AGENTS.md" 2>/dev/null || md5sum "$T/AGENTS.md" | cut -d' ' -f1)
g_before=$(md5 -q "$T/GUIDING-PRINCIPLES.md" 2>/dev/null || md5sum "$T/GUIDING-PRINCIPLES.md" | cut -d' ' -f1)

"$REPO/utils/pdda/pdda-install.sh" "$T" --with-startup-docs --no-register >/dev/null 2>&1

a_after=$(md5 -q "$T/AGENTS.md" 2>/dev/null || md5sum "$T/AGENTS.md" | cut -d' ' -f1)
g_after=$(md5 -q "$T/GUIDING-PRINCIPLES.md" 2>/dev/null || md5sum "$T/GUIDING-PRINCIPLES.md" | cut -d' ' -f1)
check "$a_after" "$a_before" "repo-authored AGENTS.md survives --with-startup-docs (GH-25)"
check "$g_after" "$g_before" "repo-authored GUIDING-PRINCIPLES.md survives --with-startup-docs (GH-25)"

# A repo-authored ROUTER.md is equally protected.
T="$(new_target authored-router)"
printf '# ROUTER.md\n\nMY OWN ROUTER.\n' > "$T/ROUTER.md"
r_before=$(md5 -q "$T/ROUTER.md" 2>/dev/null || md5sum "$T/ROUTER.md" | cut -d' ' -f1)
"$REPO/utils/pdda/pdda-install.sh" "$T" --with-startup-docs --no-register >/dev/null 2>&1
r_after=$(md5 -q "$T/ROUTER.md" 2>/dev/null || md5sum "$T/ROUTER.md" | cut -d' ' -f1)
check "$r_after" "$r_before" "repo-authored ROUTER.md survives --with-startup-docs"

# ---------------------------------------------------------------------------------------------------
# 5. --force is the opt-in that overwrites. Negative control for test 4: prove the guard, not a no-op.
# ---------------------------------------------------------------------------------------------------
"$REPO/utils/pdda/pdda-install.sh" "$T" --with-startup-docs --no-register --force >/dev/null 2>&1
r_forced=$(md5 -q "$T/ROUTER.md" 2>/dev/null || md5sum "$T/ROUTER.md" | cut -d' ' -f1)
if [ "$r_forced" != "$r_before" ]; then
  ok "--force does overwrite the startup docs (guard is real, not a silent skip)"
else
  bad "--force did not overwrite — the create-only guard may be unconditional"
fi
if cmp -s "$T/ROUTER.md" "$REPO/utils/pdda/templates/ROUTER.target.md"; then
  ok "--force rewrites ROUTER.md from the template"
else
  bad "--force rewrote ROUTER.md from something other than the template"
fi

# ---------------------------------------------------------------------------------------------------
# 6. --help tells the truth: it must not promise an "adapted" copy of files it copies verbatim.
# ---------------------------------------------------------------------------------------------------
help_txt="$("$REPO/utils/pdda/pdda-install.sh" --help 2>&1 || true)"
if grep -q 'templates/ROUTER.target.md' <<< "$help_txt"; then
  ok "--help names the template ROUTER.md is written from"
else
  bad "--help does not name the template"
fi
if grep -qi 'create-only' <<< "$help_txt"; then
  ok "--help states the create-only semantics"
else
  bad "--help does not state create-only semantics"
fi

# ---------------------------------------------------------------------------------------------------
# 7. A fresh install is clean under the target's own checks.
# ---------------------------------------------------------------------------------------------------
T="$(new_target clean)"
"$REPO/utils/pdda/pdda-install.sh" "$T" --with-startup-docs --no-register >/dev/null 2>&1
errs=$( cd "$T" && utils/pdda/pdda.sh run 2>&1 | grep -cE '^ERROR' || true )
check "$errs" "0" "a fresh --with-startup-docs install reports zero errors in the target"


# ===================================================================================================
# GH-23 P2 — the post-install self-check.
#
# One assertion would have caught the whole of GH-23 at install time: a router naming a script the
# target does not contain. For months --with-startup-docs shipped exactly that, and nothing noticed,
# because pdda-check-governance only scans .md references.
#
# The cases marked NEGATIVE CONTROL are the ones that keep this from becoming a nuisance that gets
# disabled: it must not police a router the operator wrote, and it must not flag a bare filename that
# genuinely resolves.
# ===================================================================================================

# Build a throwaway copy of the canonical repo so a test can poison its template. .git is excluded on
# purpose — pdda_manifest_expand then takes its non-git `find` fallback, which is itself worth covering.
make_source_copy() {  # -> prints path
  local dst="$SBOX/src-$1"
  mkdir -p "$dst"
  require_fixture "$dst" "installer source fixture"
  ( cd "$REPO" && tar -cf - utils/pdda utils/py/pdda_gov_scan.py utils/py/pdda_comment_refs.py PROJECT/PDDA.md 2>/dev/null ) | ( cd "$dst" && tar -xf - )
  printf '%s\n' "$dst"
}

# --- 8. Happy path: the self-check runs, passes, and says so ---------------------------------------
T="$(new_target selfcheck-ok)"
out="$("$REPO/utils/pdda/pdda-install.sh" "$T" --with-startup-docs --no-register 2>&1)"; rc=$?
case "$out" in *"self-check  ok"*) ok "self-check runs and passes on the real template" ;;
               *) bad "self-check did not report ok"; printf '%s\n' "$out" ;; esac
check "$rc" "0" "a clean install exits 0"

# --- 9. THE POINT: a poisoned template fails the install ------------------------------------------
# Reproduces GH-23 exactly: a target router naming install.sh and utils/pdda/pdda-sync.sh.
SRC="$(make_source_copy poison)"
cat >> "$SRC/utils/pdda/templates/ROUTER.target.md" <<'POISON'

## Routing hints (poisoned by the test)

- If the task is about installing PDDA into another repo, run `install.sh <target>`.
- To distribute this runtime, use `utils/pdda/pdda-sync.sh` — a canonical-only tool.
POISON

T="$(new_target poisoned)"
out="$("$SRC/utils/pdda/pdda-install.sh" "$T" --with-startup-docs --no-register 2>&1)"; rc=$?
case "$out" in *'names "install.sh"'*)             ok "self-check names the dead bare ref (install.sh)" ;;
               *) bad "did not flag install.sh"; printf '%s\n' "$out" ;; esac
case "$out" in *'names "utils/pdda/pdda-sync.sh"'*) ok "self-check names the dead path ref (pdda-sync.sh)" ;;
               *) bad "did not flag pdda-sync.sh" ;; esac
case "$out" in *"2 dead script reference(s)"*)      ok "self-check counts the dead refs" ;;
               *) bad "no dead-ref count" ;; esac
case "$out" in *"bug in PDDA"*)                     ok "self-check blames the template, not the target repo" ;;
               *) bad "did not attribute the failure to PDDA" ;; esac
[ "$rc" -ne 0 ] && ok "a poisoned template makes install.sh exit non-zero" || bad "poisoned install exited 0"

# ...and the install still COMPLETED. The router is misleading; the repo is usable. Aborting mid-install
# would leave a half-provisioned tree, which is strictly worse.
[ -f "$T/utils/pdda/pdda.sh" ] && ok "install still completes despite the failed self-check" || bad "install aborted mid-way"
[ -f "$T/PROJECT/PDDA.md" ]    && ok "the contract still landed" || bad "PROJECT/PDDA.md missing"

# --- 9b. GH-23 P3: the self-check covers EVERY doc we write, not just the router --------------------
# The router was never special. Scoped to ROUTER.md alone, this check sailed past a dead `install.sh`
# sitting in the GUIDING-PRINCIPLES.md scaffolded into every single target — found only once the
# governance scan learned to read .sh. Poison a non-router startup doc and the install must still fail.
SRC="$(make_source_copy poison-gp)"
printf '\nAdopt it by running `tools/bootstrap-pdda.sh` from the root.\n' >> "$SRC/utils/pdda/templates/GUIDING-PRINCIPLES.target.md"
T="$(new_target poisoned-gp)"
out="$("$SRC/utils/pdda/pdda-install.sh" "$T" --with-startup-docs --no-register 2>&1)"; rc=$?
case "$out" in *'GUIDING-PRINCIPLES.md names "tools/bootstrap-pdda.sh"'*)
                 ok "self-check catches a dead ref in a non-router startup doc" ;;
               *) bad "self-check ignored a poisoned GUIDING-PRINCIPLES.md"; printf '%s\n' "$out" ;; esac
[ "$rc" -ne 0 ] && ok "a poisoned non-router startup doc makes install.sh exit non-zero" || bad "poisoned GP install exited 0"
case "$out" in *"self-check  every *.sh named in the written ROUTER.md"*)
                 ok "the router is still validated alongside it" ;;
               *) bad "router self-check went missing" ;; esac

# --- 9c. NEGATIVE CONTROL: a longer suffix is not a shell script ------------------------------------
# `grep -oE '...\.sh'` harvests `foo.sh` out of `foo.shtml` and fails the install over a script nobody
# named. Found by an adversarial cross-model review; the `\b` anchor is the whole fix.
SRC="$(make_source_copy shtml)"
printf '\nLegacy pages live at `docs/legacy.shtml` and are not shipped.\n' >> "$SRC/utils/pdda/templates/ROUTER.target.md"
T="$(new_target shtml)"
out="$("$SRC/utils/pdda/pdda-install.sh" "$T" --with-startup-docs --no-register 2>&1)"; rc=$?
check "$rc" "0" "a .shtml reference does not fail the install"
case "$out" in *'legacy.sh"'*) bad "harvested 'legacy.sh' out of 'legacy.shtml'" ;;
               *) ok "a longer suffix (.shtml) is not read as a .sh reference" ;; esac

# --- 10. NEGATIVE CONTROL: never police a ROUTER.md the operator wrote ------------------------------
# If --with-startup-docs kept their file, it is theirs. Failing their install over their own scripts
# would be indefensible — and would make this check the first thing anyone turns off.
#
# GH-23 P3 sharpened this case. TWO mechanisms can name the operator's script, and only one of them
# would be a violation:
#   - the install SELF-CHECK aborts the install (exit 1). It must never assert over a doc we kept.
#   - the governance DEAD-REF scan is warn-only advisory, run by install's first-run verification. Its
#     entire job is to say "this doc names a script that is not here". Suppressing it on the operator's
#     own docs would suppress it exactly where it matters — that is the LTVera bug.
# So assert the self-check ignores the kept router and that nothing blocks — NOT that the script name
# never appears anywhere in the output.
T="$(new_target kept-router)"
printf '# MY ROUTER\n\nRun `my-private-deploy.sh` before shipping.\n' > "$T/ROUTER.md"
out="$("$REPO/utils/pdda/pdda-install.sh" "$T" --with-startup-docs --no-register 2>&1)"; rc=$?
check "$rc" "0" "an operator's own ROUTER.md never fails the install"
case "$out" in *"self-check skipped — ROUTER.md was kept"*) ok "self-check skips a kept router and says why" ;;
               *) bad "did not skip the self-check for a kept router"; printf '%s\n' "$out" ;; esac
case "$out" in *'ROUTER.md names "my-private-deploy.sh"'*) bad "the self-check policed the operator's own script" ;;
               *) ok "the self-check never asserts over a kept router" ;; esac
case "$out" in *"dead script reference(s)"*) bad "install raised a blocking dead-ref failure for a kept router" ;;
               *) ok "no install-blocking dead-ref failure for a kept router" ;; esac
# The advisory warn IS expected and correct: their router points at a script their repo does not have.
case "$out" in *"dead reference 'my-private-deploy.sh'"*) ok "governance still warns (advisory) on the operator's dead ref" ;;
               *) bad "governance failed to warn about a genuinely dead .sh ref" ;; esac
grep -q 'my-private-deploy.sh' "$T/ROUTER.md" && ok "the operator's router is left untouched" || bad "operator's router was modified"

# --- 11. NEGATIVE CONTROL: a bare filename that genuinely resolves must not flag --------------------
# A doc may legitimately write `pdda-lib.sh` meaning utils/pdda/pdda-lib.sh. The bare-name fallback
# mirrors _pdda_gov_resolve_ref. Without this test, tightening the matcher to paths-only looks correct.
SRC="$(make_source_copy barename)"
printf '\nSee `pdda-lib.sh` for the shared helpers.\n' >> "$SRC/utils/pdda/templates/ROUTER.target.md"
T="$(new_target barename)"
out="$("$SRC/utils/pdda/pdda-install.sh" "$T" --with-startup-docs --no-register 2>&1)"; rc=$?
check "$rc" "0" "a bare filename that resolves elsewhere in the target does not fail the install"
case "$out" in *'names "pdda-lib.sh"'*) bad "bare pdda-lib.sh was wrongly flagged as dead" ;;
               *) ok "bare 'pdda-lib.sh' resolves via the repo-wide fallback" ;; esac

# --- 12. Self-check is skipped entirely without --with-startup-docs ---------------------------------
T="$(new_target no-startup-docs)"
out="$("$REPO/utils/pdda/pdda-install.sh" "$T" --no-register 2>&1)"; rc=$?
check "$rc" "0" "a plain install exits 0"
case "$out" in *"self-check"*) bad "self-check ran without --with-startup-docs" ;;
               *) ok "no --with-startup-docs, no self-check" ;; esac

printf '\n=== pdda-install-startup-docs: %d passed, %d failed ===\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
