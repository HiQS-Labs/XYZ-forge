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
  # `.conf` joined the extension set with GH-388, which ships relay-automation/non-durable-log-roots.conf
  # — a data file both language lanes read at runtime. The pattern is the manifest's own definition of
  # what counts as a packaged path, so an extension missing here reads as DRIFT for a correctly
  # packaged file: the tarball had it, this list did not, and the check blamed the tarball.
  pkg_list="$(grep -oE '(relay-automation|test)/[A-Za-z0-9._/-]+\.(sh|md|conf)' "$MKPKG" | sort -u)"
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
# `utils/pdda/**` is SYNC-MANAGED from Hypercart-Dev-Tools/pdda (utils/pdda/PDDA-SOURCE.md): a sync
# replaces those files wholesale, so their internal path tokens describe UPSTREAM's tree, not ours,
# and any edit we make to satisfy this check is reverted by the next sync. The 2026-08-03 sync
# (cfd56b0) added four such tokens and turned this check — and CI on `development` — red for ~2 days:
#   utils/pdda/pdda.sh:850     an EXEMPTION-LIST data string naming three upstream skill/test files
#                              under a dot-claude skills dir that this repo does not vendor
#   utils/pdda/pdda-lib.sh:467 a COMMENT citing an upstream releases-iterations test file
# None is a reference this repo can resolve or repair. (Those paths are deliberately DESCRIBED rather
# than quoted here: this file is itself scanned, so spelling them out would trip the very check.) Excluding the tree is narrower than it looks:
# every path this repo actually authors and can fix is still scanned, and upstream's tree is
# upstream's CI's job. Scoped to this one directory so a new vendored tree does not inherit the
# exemption silently.
while IFS= read -r p; do
  case "$p" in utils/pdda/*) continue ;; esac
  shfiles+=("$p")
done < <(cd "$ROOT" && git ls-files '*.sh')

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
# GH-85: test/marathon-plan.sh creates `$J/test/gh-951-genuine-test.sh` in a throwaway temp repo to
# simulate the "tests-reference-slug" partial signal — a fixture literal, not a real reference.
# GH-63: test/signal-triage.sh passes `test/foo.sh` / `test/some-test.sh` as synthetic `--test` inputs
# to exercise the classifier (they name no real file) — same class, skip them.
# GH-108/GH-126/GH-127: test/swarm-preflight.sh's T35/T36 fixtures create test/bare-redirect.sh,
# test/no-touch.sh, and test/comment-only.sh in a throwaway temp repo to exercise the genuine-ref
# and bare-`>` fs-touching detectors — fixture literals, not references to files in this tree.
# GH-321: test/gh308-frozen-twin-guard.sh feeds `relay-automation/codex-turnn.sh` to the frozen-twin
# guard to prove a TYPO'd path in a `Frozen-twin-exception:` trailer fails loudly instead of silently
# covering nothing. The token is deliberately a path that does not resolve — that IS the test input —
# and it can never exist in this tree, so skipping it cannot mask a real path break.
# GH-400: test/gh400-acceptance-fidelity.sh reproduces rebalance-OS issue #202 and its capture doc
# VERBATIM as the fixture that pins the measured inversion. Both texts name `test/clio-exporter.sh`,
# a file in THAT repo. Paraphrasing it to satisfy this check would defeat the fixture's whole point —
# the test exists to prove a byte-for-byte comparison catches a real drift — and the path can never
# exist in this tree, so skipping it cannot mask a real path break.
# GH-419 (added 2026-08-07, during the Litmus marathon): test/gh419-gate-inventory.sh writes its
# fixtures to "$FIXTURE/test/<name>.sh" under a mktemp root and then asserts on the inventory KEYS
# the tool returns, which are repo-relative by construction. The bare "test/safe.sh" strings in the
# assertions are therefore inventory keys, not references to files in this tree — they can never
# exist here, so skipping them cannot mask a real path break. Same shape as the six fixture names
# already listed above.
#
# This entry is why the gh419 lane escalated on its first attempt: the fix belongs in THIS file,
# which is not in that lane's artifact allowlist, so the builder could not have made it — an
# off-lane edit would have been reverted as a containment violation. Recorded because a lane that
# cannot pass its own gate is a plan defect, not a builder defect.
# GH-509 (added 2026-08-12): test/ci-route.sh builds a throwaway git repo under $WORK and runs a real
# `git mv test/old-regression.sh test/new-regression.sh` in it, to prove that a RENAMED regression
# test still selects the full CI gate. The rename must be real: the defect being pinned is that
# `git diff --name-only` reports only a rename's DESTINATION, so the source path never reaches
# ci-route.sh's fail-closed branch, and no amount of hand-written path strings reproduces that —
# only git does. Both names exist solely inside that temp repo and can never exist in this tree, so
# skipping them cannot mask a real path break.
# GH-551 (added 2026-08-14): the new-Bash guard's cases 15-20 create throwaway .sh files in the same
# mktemp fixture repo the GH-321 cases use (`some-shim.sh` is the trailer example in the usage
# comment). All are fixture literals that must never exist in this tree — that is what the guard
# blocks — so skipping them cannot mask a real path break.
fixture_literals=" relay-automation/Codex-turn.sh test/gh-951-genuine-test.sh test/foo.sh test/some-test.sh test/bare-redirect.sh test/no-touch.sh test/comment-only.sh relay-automation/codex-turnn.sh test/clio-exporter.sh test/safe.sh test/self-comparing.sh test/self-regenerating.sh test/new-gate.sh test/old-regression.sh test/new-regression.sh relay-automation/some-shim.sh relay-automation/new-shim.sh relay-automation/existing-lib.sh test/new-test.sh "

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
