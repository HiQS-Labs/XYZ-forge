# RELAY · QA GH-62 — XYZ install registry (install.sh + call-home)
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-06-30.
-->

NEXT: Reviewer
STATUS: Open
ROUND: 1 / 4

## ▶ TAKE YOUR TURN — read this first (works for ANY agent: Claude, Codex, agy)
1. **Read this whole file** (header, Setup, Ground rules, every block in the Log).
2. **Check it's your turn:** `NEXT` (top) names the role to act. Confirm you are bound to it and the
   last Log block isn't already yours. If not → STOP and reply "wrong window — nudge the <other> window."
3. **Do your role's work** on the artifact named in Setup:
   - **Reviewer:** review vs the Definition of Done → graded findings
     (`[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`), each with a concrete fix → set a **Verdict**
     (Approved | Changes requested | Blocked). Do **not** edit the artifact; only append findings here.
   - **Producer:** log a disposition for every open finding (Implemented / Modified / Declined + why),
     make the change, then add new work.
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(qa-gh-62-xyz-install-registry-install-sh-call-home): <role> r<N>`); no push. **Stop** and report one line.

## Setup
- Artifact under review: **install.sh** (embedded below — read it here).
- Reviewer: agy   ·   Producer: claude-a
- Started: 2026-06-30

### Artifact — install.sh
```
#!/usr/bin/env bash
set -euo pipefail

# XYZ / tick installer — materialize the `tick` runtime (bin/tick + src/*.js) into a target DIR, then
# "call home": record WHERE this copy was installed and on which source version/commit in a per-user,
# machine-local registry. Run it from a clone of this repo:
#
#   ./install.sh [options] [target-dir]     # target-dir default: ./xyz-tick
#
# The registry is what lets a future `tick` version be pushed to the copies that are behind. It lives
# in $HOME (never in the repo, so it can't leak into the eventually-public tree) and is never committed.
#
# This mirrors PDDA's install->call-home pattern (pdda/install.sh). The registry-writing block is kept
# in lockstep with the compact inline version embedded in the /xyz SKILL self-extract block (§4);
# change both together.

SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

REGISTER=1
TARGET=""
COORD_REPO="${TICK_REPO_ROOT:-}"

# Per-user, per-device install registry — one row per install dir, latest wins. Machine-local; never
# committed. Override the path with XYZ_REGISTRY; skip writing it with --no-register.
XYZ_REGISTRY="${XYZ_REGISTRY:-${XDG_CONFIG_HOME:-$HOME/.config}/xyz/registry.tsv}"

# Optional multi-device rollup: if git-pulse (a GitHub-backed activity-sync tool) is present, drop a
# PATH-NORMALIZED projection of the registry (repo/dir name + date + version; never absolute paths)
# into git-pulse's repo under xyz/, and git-pulse's own sync carries it across devices. Best-effort and
# fail-open: absent git-pulse -> silently skipped. Set XYZ_GITPULSE_DIR to override or disable.
XYZ_GITPULSE_DIR="${XYZ_GITPULSE_DIR:-}"

usage() {
  cat <<'USAGE'
XYZ / tick installer — materialize the tick runtime into a dir and register the install.

Usage:
  ./install.sh [options] [target-dir]

Arguments:
  target-dir             Where to materialize the runtime (default: ./xyz-tick). Creates
                         <target-dir>/bin/tick and <target-dir>/src/*.js.

Options:
  --repo <path>          Record the coordinated repo (the one holding .tick/) in the registry.
                         Defaults to $TICK_REPO_ROOT if set, else "-".
  --no-register          Skip recording this install in the per-user registry
                         (default: $XDG_CONFIG_HOME/xyz/registry.tsv or ~/.config/xyz/registry.tsv;
                         override with XYZ_REGISTRY). Also skips the git-pulse projection.
  -h, --help             This message.

After install, use it with:
  export PATH="<target-dir>/bin:$PATH"
  export TICK_REPO_ROOT="<repo to coordinate>"   # where .tick/ lives
  tick --help
USAGE
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --repo) COORD_REPO="${2:-}"; shift 2 ;;
    --no-register) REGISTER=0; shift ;;
    -h|--help) usage; exit 0 ;;
    -*) printf 'install.sh: unknown option %q\n\n' "$1" >&2; usage >&2; exit 2 ;;
    *) if [ -z "$TARGET" ]; then TARGET="$1"; shift; else printf 'install.sh: unexpected argument %q\n' "$1" >&2; exit 2; fi ;;
  esac
done

TARGET="${TARGET:-xyz-tick}"

# Source sanity: we ship the repo's canonical modular runtime (bin/tick requires ../src/*).
[ -f "$SOURCE_DIR/bin/tick" ] || { printf 'install.sh: no bin/tick under %q — run this from a clone of the xyz repo.\n' "$SOURCE_DIR" >&2; exit 1; }
[ -d "$SOURCE_DIR/src" ]      || { printf 'install.sh: no src/ under %q — run this from a clone of the xyz repo.\n' "$SOURCE_DIR" >&2; exit 1; }

# Resolve target to an absolute path (create it first so `cd` succeeds).
mkdir -p "$TARGET/bin" "$TARGET/src"
TARGET="$(cd "$TARGET" && pwd)"

if [ "$TARGET" = "$SOURCE_DIR" ]; then
  printf 'install.sh: refusing to install into the source repo root (would clobber bin/tick). Pick a subdir.\n' >&2
  exit 1
fi

say() { printf '%s\n' "$*"; }

say "Installing tick runtime into: $TARGET"
say ""
say "Runtime:"
cp "$SOURCE_DIR/bin/tick" "$TARGET/bin/tick"
chmod +x "$TARGET/bin/tick"
say "  runtime   bin/tick"
# Ship the whole module set — bin/tick require()s several src/* modules that transitively pull in the
# rest; copying all of src/*.js keeps the install self-consistent regardless of the require graph.
for f in "$SOURCE_DIR"/src/*.js; do
  cp "$f" "$TARGET/src/$(basename "$f")"
  say "  runtime   src/$(basename "$f")"
done

# --- call home -------------------------------------------------------------------------------------

# Best-effort tick version: the SCHEMA_VERSION anchor lives in src/events.js. Fallback: unknown.
tick_version() {
  local v
  v="$(sed -n "s/.*SCHEMA_VERSION[[:space:]]*=[[:space:]]*['\"]\([^'\"]*\)['\"].*/\1/p" "$SOURCE_DIR/src/events.js" 2>/dev/null | head -1)"
  printf '%s' "${v:-unknown}"
}

# Publish a path-normalized projection of the registry into git-pulse's sync repo when present, so XYZ
# install status rolls up across devices with NO new sync infrastructure. Normalized = col 1 absolute
# path -> bare dir name; the projection never contains a filesystem path. Best-effort / fail-open; the
# local registry stays the source of truth (it keeps absolute paths because a push tool cd's into them).
publish_registry_projection() {
  local gp="$XYZ_GITPULSE_DIR" dev cfg out tmp cand
  cfg="${XDG_CONFIG_HOME:-$HOME/.config}/git-pulse/config.sh"
  if [ -z "$gp" ]; then
    gp="$( ( . "$cfg" 2>/dev/null; printf '%s' "${sync_repo_dir:-}" ) )"
    if [ -z "$gp" ] || [ ! -d "$gp/.git" ]; then
      for cand in "${XDG_CONFIG_HOME:-$HOME/.config}/git-pulse/repo" "$HOME/git-pulse-sync"; do
        [ -d "$cand/.git" ] && { gp="$cand"; break; }
      done
    fi
  fi
  [ -d "$gp/.git" ] || return 0
  dev="$( ( . "$cfg" 2>/dev/null; printf '%s' "${device_id:-}" ) )"
  [ -n "$dev" ] || dev="$(hostname -s 2>/dev/null || printf 'unknown-device')"
  mkdir -p "$gp/xyz" 2>/dev/null || { say "  (git-pulse xyz/ not writable — publish skipped)"; return 0; }
  out="$gp/xyz/registry-$dev.tsv"
  tmp="$out.tmp.$$"
  if {
       printf '# XYZ install status (normalized to install-dir name; absolute paths intentionally omitted).\n'
       printf '# Maintainer on another machine: locate the install by dir name, e.g.\n'
       printf '#   find ~ -type d -name "<dir>" -exec test -f "{}/bin/tick" \\; -print 2>/dev/null\n'
       printf '# install_dir\tlast_install_utc\ttick_version\tsource_commit\tcoordinated_repo\n'
       awk -F'\t' 'BEGIN{OFS="\t"} /^#/{next} NF==0{next} {n=split($1,a,"/"); $1=a[n]; print}' "$XYZ_REGISTRY"
     } > "$tmp" 2>/dev/null && mv "$tmp" "$out"; then
    say "  publish   xyz/registry-$dev.tsv (normalized; git-pulse carries it)"
  else
    rm -f "$tmp" 2>/dev/null
    say "  (git-pulse publish failed — projection unchanged)"
  fi
  return 0
}

# Record this install (one row per install dir, latest wins). Machine-local; never committed.
# Best-effort: a failure here never fails the install.
register_install() {
  [ "$REGISTER" -eq 1 ] || return 0
  local reg="$XYZ_REGISTRY" dir
  dir="$(dirname "$reg")"
  mkdir -p "$dir" 2>/dev/null || { say "  (registry dir $dir not writable — skipped)"; return 0; }

  local ts ver src_commit coord row tmp
  ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  ver="$(tick_version)"
  src_commit="$(git -C "$SOURCE_DIR" rev-parse --short HEAD 2>/dev/null || printf 'unknown')"
  coord="${COORD_REPO:-}"
  [ -n "$coord" ] && coord="$(cd "$coord" 2>/dev/null && pwd || printf '%s' "$COORD_REPO")"
  coord="${coord:--}"

  if [ ! -f "$reg" ]; then
    {
      printf '# XYZ install registry — per-user, per-device. Machine-local; do NOT commit.\n'
      printf '# install_dir\tlast_install_utc\ttick_version\tsource_commit\tcoordinated_repo\n'
    } > "$reg"
  fi

  # One row per install dir: drop any prior row for this exact path (tab col 1), then append fresh.
  row="$(printf '%s\t%s\t%s\t%s\t%s' "$TARGET" "$ts" "$ver" "$src_commit" "$coord")"
  tmp="$reg.tmp.$$"
  if awk -F'\t' -v t="$TARGET" '$1 != t' "$reg" > "$tmp" 2>/dev/null; then
    if printf '%s\n' "$row" >> "$tmp" && mv "$tmp" "$reg"; then
      say "  register  $TARGET -> $reg (tick $ver, $src_commit, repo=$coord)"
      publish_registry_projection   # best-effort multi-device rollup; never fails the install
    fi
  else
    rm -f "$tmp"
    say "  (registry write failed — skipped)"
  fi
}

say ""
say "Registry:"
register_install

say ""
say "tick runtime installed in $TARGET/"
say "Use it with:"
say "  export PATH=\"$TARGET/bin:\$PATH\""
say "  export TICK_REPO_ROOT=\"${COORD_REPO:-<repo to coordinate>}\""
say "  tick --help"
```
- Context: `install.sh` is new (GH-62). It materializes the `tick` runtime (`bin/tick` + `src/*.js`)
  into a target dir, then "calls home" — appends a row to a per-user, machine-local
  `~/.config/xyz/registry.tsv` so a future `tick` version can be pushed to copies that are behind. It
  mirrors PDDA's `pdda/install.sh`. A compact copy of the same register logic is embedded in the `/xyz`
  SKILL self-extract block (`skills/xyz/SKILL.md`) — the two must stay in lockstep.
- Definition of Done (grade against these; anchored to GUIDING-PRINCIPLES.md):
  1. **Correctness** — the registry write is atomic (tmp+mv), dedups on `install_dir` (latest wins),
     and `tick_version`/`source_commit`/`coordinated_repo` are stamped correctly. No data-loss race.
  2. **Fail-open / honest (#8)** — a registry or git-pulse-projection failure never fails the install;
     nothing is masked. `set -euo pipefail` cannot abort mid-install on a guarded step.
  3. **No leak (#1, containment)** — the registry lives in `$HOME`, never in the repo/worktree; the
     git-pulse projection is path-normalized (no absolute paths leak across devices).
  4. **Least code that clears the bar (#7)** — no needless deps (bash + coreutils only), no
     over-engineering; reuse over reinvention.
  5. **Robustness** — safe under paths with spaces, missing `git`, absent `src/events.js`, unwritable
     `~/.config`, and `--repo` pointing at a nonexistent dir. Quoting is correct throughout.
  6. **Portability** — macOS (BSD) + Linux (GNU) `sed`/`awk`/`date`/`mktemp`-free assumptions hold.
  7. **Lockstep** — the SKILL self-extract register step and `install.sh`'s `register_install` agree on
     schema (same columns/order) so both write compatible rows.
  Focus on real Blockers/Shoulds with a concrete fix; one real bug beats five nits (four-pillars: be
  Attested, Relevant, Fresh, Structured).

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
