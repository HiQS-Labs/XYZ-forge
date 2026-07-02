#!/usr/bin/env bash
# Guard against path-reference rot — the failure class that silently broke
# skill-extract twice:
#   - the skills/ rename left a hardcoded singular-dir path that no longer
#     resolved (make-pkg.sh wrote to a dead path; the test read from one), and
#   - the gemini -> agy migration left the package manifest pointing at sources
#     that had been swapped out.
# Both are "a path/name in a script or doc stopped matching reality and nothing
# noticed." Two checks close that gap:
#   A. The relay-automation package manifest is internally consistent —
#      make-pkg.sh's source list == the committed tarball's contents (so a
#      source swap that isn't repackaged, or a repackage that isn't committed,
#      fails here).
#   B. Every repo-relative script/doc path referenced in tracked shell scripts
#      and the operational docs actually resolves to a real file (so a stale
#      "skill/<...>" singular path, a renamed/removed script, or a typo'd path
#      in a runnable command fails here — in scripts OR docs).
source "$(dirname "$0")/_setup.sh" path-integrity
ROOT="$(cd "$(dirname "$0")/.." && pwd)"

# --- Check A: package manifest == tarball contents (no source/package drift) ---
MKPKG="$ROOT/skills/relay-automation/make-pkg.sh"
TARBALL="$ROOT/skills/relay-automation/relay-pkg.tar.gz"
if [ -f "$MKPKG" ] && [ -f "$TARBALL" ]; then
  pkg_list="$(grep -oE '(relay-automation|test)/[A-Za-z0-9._/-]+\.(sh|md)' "$MKPKG" | sort -u)"
  tar_list="$(tar tzf "$TARBALL" | sort -u)"
  if [ "$pkg_list" = "$tar_list" ]; then
    pass "make-pkg.sh source list matches the committed tarball ($(printf '%s\n' "$tar_list" | grep -c .) files)"
  else
    echo "  --- listed in make-pkg.sh, absent from tarball ---" >&2
    comm -23 <(printf '%s\n' "$pkg_list") <(printf '%s\n' "$tar_list") >&2
    echo "  --- in tarball, not listed in make-pkg.sh ---" >&2
    comm -13 <(printf '%s\n' "$pkg_list") <(printf '%s\n' "$tar_list") >&2
    fail "package manifest drift — re-run skills/relay-automation/make-pkg.sh and commit the tarball"
  fi
else
  fail "packaging files missing: expected make-pkg.sh + relay-pkg.tar.gz under skills/relay-automation/"
fi

# --- Check B: referenced script/doc paths resolve ------------------------------
# Scanned surface: every tracked *.sh + a curated set of operational docs (the
# files that hand an operator a runnable path). The prefix list is intentionally
# scoped to the relay/tooling surface to keep the signal high; extend `prefixes`
# and `docs` when a new top-level tooling dir or operator doc appears.
docs="README.md \
relay-automation/README.md \
skills/relay-automation/SKILL.md \
skills/relay-xyz/SKILL.md"

shfiles=()
while IFS= read -r p; do shfiles+=("$p"); done < <(cd "$ROOT" && git ls-files '*.sh')

# A path-like token must (a) start with a known tooling prefix, (b) contain no
# glob/var/placeholder char (the [A-Za-z0-9._/-] class excludes * ? $ < > { } ` ),
# and (c) end in a real extension — so globs (relay-automation/*.sh) and
# placeholders (relay-system/<date>/<slug>.md) are skipped by construction.
ext_re='(relay-automation|test|skill|skills|bin)/[A-Za-z0-9._/-]+\.(sh|md|tar\.gz)'

# Intentional FIXTURE LITERALS — path-like tokens that are test DATA (a file a test creates in a
# throwaway temp repo at runtime), NOT references to a real file in this tree. Check B must skip them,
# otherwise it false-positives on a case-sensitive filesystem: e.g. test/swarm-preflight.sh T22a asserts
# case-INSENSITIVE shim classification using `relay-automation/Codex-turn.sh` (a deliberate case-variant
# of the real lowercase codex-turn.sh). That literal resolves on case-insensitive macOS but not on
# case-sensitive Linux, so scanning it made `validate.sh` green on macOS and red on Linux. Skipping it
# keeps Check B FS-portable without weakening it for genuine references (the capital-C file can never
# exist in this tree — the real shim is lowercase — so this can never mask a real path break). See #80.
# Space-delimited; a token matches only when flanked by spaces (exact-token match, no substring slip).
fixture_literals=" relay-automation/Codex-turn.sh "

bad=0
for f in "${shfiles[@]}" $docs; do
  [ -f "$ROOT/$f" ] || continue
  while IFS= read -r tok; do
    [ -n "$tok" ] || continue
    case "$fixture_literals" in *" $tok "*) continue ;; esac
    if [ ! -e "$ROOT/$tok" ]; then
      echo "  broken path reference '$tok' in $f" >&2
      bad=1
    fi
  done < <(grep -hoE "$ext_re|bin/tick" "$ROOT/$f" 2>/dev/null | sort -u)
done
[ "$bad" = 0 ] \
  && pass "all referenced relay/script/doc paths resolve (scanned ${#shfiles[@]} scripts + curated docs)" \
  || fail "one or more referenced paths do not exist (see above) — fix the path or the reference"

echo "  $TEST_NAME: $PASS pass, $FAIL fail"
exit 0
