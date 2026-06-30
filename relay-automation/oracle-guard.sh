#!/usr/bin/env bash
# oracle-guard.sh — oracle-immutability guard for the Part C self-improvement loop (#50).
#
# Load-bearing rule of a legitimate optimization loop: the ORACLE (the test/fixture suite + the
# measure-cmd + the reviewer's inputs) must live OUTSIDE the builder's write surface. Otherwise the
# loop "wins" by editing the oracle instead of the artifact — deleting tests, hardcoding outputs,
# moving the benchmark. This asserts ALLOW_PATHS ∩ oracle-paths = ∅ and FAILS LOUD on any overlap.
#
# Reuses the kernel's OWN conservative path-overlap (src/paths.js patternsOverlap) — the same logic the
# claim router and the GH-40 reviewer-overstep canary rely on. It is deliberately fail-safe: a literal
# prefix of one path matching the other counts as overlap, so an ancestor dir (src/**) vs a child
# (src/foo.js) is caught, and when unsure it reports overlap rather than waving the build through.
#
# Usage:  oracle-guard.sh --allow "<csv>" --oracle "<csv>"
#         (or set ALLOW_PATHS / ORACLE_PATHS in the env; flags win)
# Exit: 0 disjoint (safe) · 9 OVERLAP — the builder could edit the oracle (lists offending pairs) · 2 usage.

set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ALLOW="${ALLOW_PATHS:-}" ORACLE="${ORACLE_PATHS:-}"
while [ $# -gt 0 ]; do
  case "$1" in
    --allow) ALLOW="${2:-}"; shift 2 ;;
    --oracle) ORACLE="${2:-}"; shift 2 ;;
    -h|--help) echo 'usage: oracle-guard.sh --allow "<csv>" --oracle "<csv>"'; exit 0 ;;
    *) echo "oracle-guard.sh: unexpected arg: $1" >&2; exit 2 ;;
  esac
done
[ -n "$ALLOW" ]  || { echo "oracle-guard.sh: --allow (builder write surface) is required" >&2; exit 2; }
[ -n "$ORACLE" ] || { echo "oracle-guard.sh: --oracle (the protected oracle paths) is required" >&2; exit 2; }

# Find overlapping (allow, oracle) pairs via the kernel's own path-overlap. CANONICALIZE first —
# resolve `..` (path.resolve) and symlinks (realpathSync, when the path exists) against the repo root —
# so an alias like `a/../oracle` or a symlink can't slip a builder path past a string-prefix check that
# only sees the textual form. Globs / not-yet-created paths keep their resolved-but-not-real form (the
# literal-prefix overlap still catches an ancestor dir). node exit 0 = disjoint, 1 = overlap, 3 = load error.
HITS="$(node -e '
  const path = require("path"), fs = require("fs");
  let po;
  try { po = require(process.argv[1] + "/src/paths").patternsOverlap; }
  catch (e) { console.error("cannot load src/paths.js: " + e.message); process.exit(3); }
  const root = process.argv[1];
  const canon = p => {
    let r = path.resolve(root, p);            // absolute + collapse ".."
    try { r = fs.realpathSync(r); } catch (_) {}   // resolve symlinks when the path exists
    return r;
  };
  const split = s => s.split(",").map(x => x.trim()).filter(Boolean).map(canon);
  const allow = split(process.argv[2]), oracle = split(process.argv[3]);
  const hits = [];
  for (const a of allow) for (const o of oracle) if (po(a, o)) hits.push(a + "  ∩  " + o);
  if (hits.length) { process.stdout.write(hits.join("\n")); process.exit(1); }
  process.exit(0);
' "$ROOT" "$ALLOW" "$ORACLE" 2>/dev/null)"; NRC=$?

case "$NRC" in
  0) echo "oracle-guard: OK — builder write surface is disjoint from the oracle"; exit 0 ;;
  1) echo "oracle-guard: OVERLAP — the builder could edit the oracle (the loop would optimize the oracle, not the artifact):" >&2
     printf '%s\n' "$HITS" >&2; exit 9 ;;
  *) echo "oracle-guard: could not evaluate overlap (node/src/paths.js error)" >&2; exit 2 ;;
esac
