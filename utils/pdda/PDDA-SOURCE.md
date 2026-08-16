# PDDA Source

Every copy of this runtime ships this file — a real install, or a copy vendored inside another
vendored tool (for example `.xyz/utils/pdda/`, which arrives when a repo vendors xyz-3-agents-swarm
and that repo's own `utils/pdda/` was itself installed from here). It exists so an agent standing in
any such copy can find the canonical repo without guessing.

## Canonical repo

- name: `pdda`
- remote: `https://github.com/Hypercart-Dev-Tools/pdda`
- canonical paths inside it: `utils/pdda/` (this runtime), `PROJECT/PDDA.md` (the document contract)

## Is *this* copy the canonical repo?

Check for `pdda-sync.sh` in the same directory as this file (its canonical checkout path is
`utils/pdda/pdda-sync.sh`). It is canonical-only tooling, deliberately excluded from every install and
vendored copy (see `pdda-sync-manifest.conf`), so its presence is what distinguishes the canonical repo
from any copy of it. If `pdda-sync.sh` is sitting right here, this already is the canonical repo — stop.

## Locating the canonical repo on this machine

Both recipes below print a match and nothing else on failure — don't gate on the exit status: `find`
can exit non-zero from an unrelated permission-denied subtree (e.g. a Photos library) while still
printing a correct match, so check whether the output is non-empty instead of chaining `&&`.

`-maxdepth` isn't strict POSIX but is near-universal (GNU/BSD/macOS find all ship it) and is kept
deliberately: an unbounded `find "$HOME" ...` measured 2+ minutes / hung outright on a real machine with
a large `~/Library/Mobile Documents` (iCloud Drive) tree under `$HOME` — `-maxdepth 6` cut the same
search to ~15s. A depth-bounded, slightly-non-POSIX command that actually returns beats a portable one
that hangs.

1. Exact-name search, filtered to real canonical checkouts (skips renamed installs and copies):

   ```
   find "$HOME" -maxdepth 6 -type d -name pdda -exec sh -c 'test -f "$1/utils/pdda/pdda-sync.sh"' sh {} \; -print 2>/dev/null
   ```

2. Fuzzy fallback if the clone folder was renamed (a bracket-expression pattern stands in for
   case-insensitive `-iname`, which isn't POSIX):

   ```
   find "$HOME" -maxdepth 6 -type d -name '*[pP][dD][dD][aA]*' -exec sh -c 'test -f "$1/utils/pdda/pdda-sync.sh"' sh {} \; -print 2>/dev/null
   ```

3. If neither finds it (different machine, CI, fresh checkout), clone it fresh:

   ```
   git clone https://github.com/Hypercart-Dev-Tools/pdda.git
   ```

Machine-local registries such as `${XDG_CONFIG_HOME:-$HOME/.config}/xyz/registry.tsv` or
`~/git-pulse-sync/pdda/registry-*.tsv` may also have a lead, but neither is guaranteed to exist or to
name this repo specifically — treat them as a hint, not a source of truth.

This file is metadata only; nothing in PDDA reads it at runtime.
