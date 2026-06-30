# RELAY · PDDA git-pulse multi-device publish (Iteration 1)
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-06-30.
-->

NEXT: Producer
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
6. **Commit only the relay file** (`relay(pdda-git-pulse-multi-device-publish-iteration-1): <role> r<N>`); no push. **Stop** and report one line.

## Setup
- Artifact under review: **pdda-gitpulse-review.diff** (embedded below — read it here).
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-06-30

### Artifact — pdda-gitpulse-review.diff
```
commit 7951163a54d9df0ea7e5969ddaff3613261e0598
Author: Noel Saw <56978803+noelsaw1@users.noreply.github.com>
Date:   Tue Jun 30 14:51:48 2026 -0700

    install.sh: auto-publish multi-device PDDA status via git-pulse (Iteration 1)
    
    register_install() now calls publish_registry_projection() on every successful
    install/upgrade. When git-pulse is present it writes a path-normalized projection
    of the registry into <git-pulse-repo>/pdda/registry-<device>.tsv (bare repo name,
    NO absolute paths, + an exact-then-fuzzy maintainer find note), and git-pulse's own
    sync carries it across devices — no new command, no PDDA-side git logic.
    
    - Best-effort / fail-open (GUIDING-PRINCIPLES #6): absent git-pulse it silently
      skips; the install is unaffected.
    - Local ~/.config/pdda/registry.tsv stays the source of truth and keeps absolute
      paths (#4); the projection is one-way and rewritten each run, so it can't drift.
    - Location override PDDA_GITPULSE_DIR; --no-register skips it too.
    - Lockstep: install.sh usage + utils/pdda/PDDA-INSTALL.md step 4c.
    - Lifecycle: design doc graduated 2-WORKING -> 3-COMPLETED; ROADMAP pointer moved
      to Completed.
    
    Verification: new test/pdda-publish-projection.sh 10/10 (publish present,
    normalized/no-path-leak, local registry intact, fail-open absent, no stray dir);
    test/pdda-changelog.sh 7/7; bash -n clean; pdda.sh run all checks passed.
    
    Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>

 CHANGELOG.md                                       | 19 +++++++
 .../PDDA-MULTI-DEVICE-STATUS-VIA-GITPULSE.md       |  4 +-
 ROADMAP.md                                         |  3 +-
 install.sh                                         | 64 ++++++++++++++++++++--
 test/pdda-publish-projection.sh                    | 61 +++++++++++++++++++++
 utils/pdda/PDDA-INSTALL.md                         |  3 +-
 6 files changed, 144 insertions(+), 10 deletions(-)

commit 7951163a54d9df0ea7e5969ddaff3613261e0598
Author: Noel Saw <56978803+noelsaw1@users.noreply.github.com>
Date:   Tue Jun 30 14:51:48 2026 -0700

    install.sh: auto-publish multi-device PDDA status via git-pulse (Iteration 1)
    
    register_install() now calls publish_registry_projection() on every successful
    install/upgrade. When git-pulse is present it writes a path-normalized projection
    of the registry into <git-pulse-repo>/pdda/registry-<device>.tsv (bare repo name,
    NO absolute paths, + an exact-then-fuzzy maintainer find note), and git-pulse's own
    sync carries it across devices — no new command, no PDDA-side git logic.
    
    - Best-effort / fail-open (GUIDING-PRINCIPLES #6): absent git-pulse it silently
      skips; the install is unaffected.
    - Local ~/.config/pdda/registry.tsv stays the source of truth and keeps absolute
      paths (#4); the projection is one-way and rewritten each run, so it can't drift.
    - Location override PDDA_GITPULSE_DIR; --no-register skips it too.
    - Lockstep: install.sh usage + utils/pdda/PDDA-INSTALL.md step 4c.
    - Lifecycle: design doc graduated 2-WORKING -> 3-COMPLETED; ROADMAP pointer moved
      to Completed.
    
    Verification: new test/pdda-publish-projection.sh 10/10 (publish present,
    normalized/no-path-leak, local registry intact, fail-open absent, no stray dir);
    test/pdda-changelog.sh 7/7; bash -n clean; pdda.sh run all checks passed.
    
    Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>

diff --git a/CHANGELOG.md b/CHANGELOG.md
index 2db84c3..c13cce4 100644
--- a/CHANGELOG.md
+++ b/CHANGELOG.md
@@ -2,6 +2,25 @@
 
 ## 2026-06-30
 
+### install.sh auto-publishes multi-device PDDA status via git-pulse
+
+Wired Iteration 1 of the multi-device rollup: `install.sh` now has `publish_registry_projection()`, called
+from `register_install()` on every successful install/upgrade. When git-pulse (a separate GitHub-backed
+activity-sync tool) is present, it writes a **path-normalized** projection of the registry into
+`<git-pulse-repo>/pdda/registry-<device>.tsv` — col 1 reduced to the bare repo name, **no absolute paths**,
+plus a maintainer-LLM header with exact-then-fuzzy `find` commands to locate a repo on another machine.
+git-pulse's own sync carries the file across devices, so PDDA adds no git logic and no new command.
+
+Best-effort and fail-open (GUIDING-PRINCIPLES #6): absent git-pulse it silently skips and the install is
+unaffected. The local `~/.config/pdda/registry.tsv` stays the source of truth and keeps absolute paths
+(#4) — the projection is one-way, rewritten in full each run, so it can't drift. Location overridable with
+`PDDA_GITPULSE_DIR`; `--no-register` skips it too. Lockstep: `install.sh` usage + `utils/pdda/PDDA-INSTALL.md`
+step 4c.
+
+Verification: new `test/pdda-publish-projection.sh` 10/10 (publish present, normalized/no-path-leak,
+local registry intact, fail-open when git-pulse absent, no stray dir); `bash -n` clean; `pdda.sh run` green.
+-> `PROJECT/3-COMPLETED/PDDA-MULTI-DEVICE-STATUS-VIA-GITPULSE.md`
+
 ### `pdda.sh changelog` now accepts semver-style dated headings
 
 `check_changelog` only matched bare `## YYYY-MM-DD` headings, so repos using the common
diff --git a/PROJECT/2-WORKING/PDDA-MULTI-DEVICE-STATUS-VIA-GITPULSE.md b/PROJECT/3-COMPLETED/PDDA-MULTI-DEVICE-STATUS-VIA-GITPULSE.md
similarity index 89%
rename from PROJECT/2-WORKING/PDDA-MULTI-DEVICE-STATUS-VIA-GITPULSE.md
rename to PROJECT/3-COMPLETED/PDDA-MULTI-DEVICE-STATUS-VIA-GITPULSE.md
index bae485c..1e97f43 100644
--- a/PROJECT/2-WORKING/PDDA-MULTI-DEVICE-STATUS-VIA-GITPULSE.md
+++ b/PROJECT/3-COMPLETED/PDDA-MULTI-DEVICE-STATUS-VIA-GITPULSE.md
@@ -1,6 +1,6 @@
 ---
 title: Multi-device PDDA install status — piggyback git-pulse's sync repo (new folder)
-status: Active (sketch — design only, not yet built)
+status: Completed (2026-06-30 — Iteration 1 wired into install.sh; 10/10 publish test green; today's ledger backfilled)
 created: 2026-06-30
 updated: 2026-06-30
 owner: noel
@@ -19,7 +19,7 @@ gh_issue: pending (gh auth re-login required; rename this doc to GH-<n>-… once
 
 | What was just completed | What's next |
 |---|---|
-| Sketched, **ponytail-trimmed**, then refined to a **path-normalized projection**. Open questions resolved: (1) reuse `rebalance-git-pulse` with an isolated `pdda/` folder; (2) repo is **private** — confirmed; (3) cadence — **git-pulse's existing launchd sync carries any file written into its repo** (its own snapshot: "the existing pulse sync carries the file"); (4) projection carries repo name + date + build hash + mode, **never the folder path**. So PDDA needs **no git logic and no new command**. | Build **Iteration 1**: ~6 best-effort lines in the existing `register_install()` that write a normalized `pdda/registry-<device>.tsv`. Open: bare repo name vs git remote slug as the key (defaulting to bare name). |
+| **Iteration 1 built and shipped.** `publish_registry_projection()` added to `install.sh` and called from `register_install()` on every successful install/upgrade: when git-pulse is present it writes a path-normalized `pdda/registry-<device>.tsv` (bare repo name + date + source commit + mode; no absolute paths), carried by git-pulse's own sync. Best-effort/fail-open. Key = bare repo name with an exact-then-fuzzy maintainer `find` note. Backfilled today's ledger by hand earlier; this makes it automatic going forward. | Nothing committed remaining. Deferred (YAGNI, reopen if needed): a `roster` aggregation read and folding the projection into `pdda-sync.sh status`. |
 
 ## Design (post-ponytail)
 
diff --git a/ROADMAP.md b/ROADMAP.md
index 96bd11d..4b9d9a5 100644
--- a/ROADMAP.md
+++ b/ROADMAP.md
@@ -40,10 +40,11 @@ This standalone repo exists to keep the PDDA contract, shell checks, and extract
 
 - **Root `install.sh` + operator onboarding** (2026-06-25) - installer that provisions a foreign repo to a clean zero state; README rewritten for onboarding. Tracking issue pending `gh` re-auth. -> [PROJECT/2-WORKING/INSTALL-SCRIPT-AND-ONBOARDING.md](PROJECT/2-WORKING/INSTALL-SCRIPT-AND-ONBOARDING.md)
 - **Reconcile pdda-sync `list` vs `status` wording** (2026-06-30) - a just-installed-but-unpushed target read as `not-yet-pushed` in `list` while `status` reported it current; `list` is now content-aware (`current`/`out-of-sync` + `(unpushed)` marker). Iteration 1 shipped. -> [PROJECT/2-WORKING/SYNC-LIST-STATUS-RECONCILE.md](PROJECT/2-WORKING/SYNC-LIST-STATUS-RECONCILE.md)
-- **Multi-device PDDA status via git-pulse piggyback** (2026-06-30) - sketch (ponytail-trimmed): a per-device, **path-normalized** registry projection (repo name + date + build hash + mode, no folder path) dropped into a new `pdda/` folder of git-pulse's sync repo, carried by git-pulse's existing sync — ~6 best-effort lines in `register_install()`, no new command or git logic. Ready to build. -> [PROJECT/2-WORKING/PDDA-MULTI-DEVICE-STATUS-VIA-GITPULSE.md](PROJECT/2-WORKING/PDDA-MULTI-DEVICE-STATUS-VIA-GITPULSE.md)
 
 ### Completed
 
+- **Multi-device PDDA status via git-pulse piggyback** (2026-06-30) - `install.sh` now publishes a per-device, **path-normalized** registry projection (repo name + date + source commit + mode, no folder path) into a `pdda/` folder of git-pulse's sync repo on every install/upgrade; git-pulse's existing sync carries it across devices. Best-effort/fail-open, no new command or git logic. 10/10 publish test green; today's ledger backfilled. -> [PROJECT/3-COMPLETED/PDDA-MULTI-DEVICE-STATUS-VIA-GITPULSE.md](PROJECT/3-COMPLETED/PDDA-MULTI-DEVICE-STATUS-VIA-GITPULSE.md)
+
 - **Issue↔doc sync check + two-tier doc-health hooks** (2026-06-29) - new warn-only `pdda.sh issue-doc-sync` flags 2-WORKING/GH-*.md docs drifted from their GitHub issue state (both directions); `pdda.sh gh-refresh` writes the offline gh-state cache; two-tier PostToolUse (single-file lint) + Stop (consolidated full-scan) doc-health hooks. Deterministic, warn-only, fail-open; 31 tests; all phases shipped, committed + pushed. Issue [#5](https://github.com/Hypercart-Dev-Tools/pdda/issues/5) (closed). -> [PROJECT/3-COMPLETED/GH-5-ISSUE-DOC-SYNC.md](PROJECT/3-COMPLETED/GH-5-ISSUE-DOC-SYNC.md)
 - **PDDA-EOD skill — end-of-day wrap** (2026-06-29) - `/pdda-eod` runs hygiene checks, reconciles docs/ROADMAP/CHANGELOG, helps reach a clean/pushed tree, and closes 100%-done issues (user-verified); delegates deterministic work to `pdda.sh`, all propose-then-confirm. Shipped at `SKILLS/PDDA-EOD/SKILL.md`. Issue [#6](https://github.com/Hypercart-Dev-Tools/pdda/issues/6). -> [PROJECT/3-COMPLETED/GH-6-PDDA-EOD.md](PROJECT/3-COMPLETED/GH-6-PDDA-EOD.md)
 - **Sync the PDDA runtime to other repos** (2026-06-27 → completed 2026-06-29) - `utils/pdda/pdda-sync.sh`: HQ → registered-targets, on-demand `push` (manual primary, launchd optional) over an auto-regenerated manifest shared with `install.sh`; content-hash state-stamp copy, delete-mirror with backup, manifest-poisoning guard. Realigned + Codex relay-approved (4 rounds), built in 5 phases, every QA gate green + end-to-end dogfood. -> [PROJECT/3-COMPLETED/PDDA-SYNC-TO-OTHER-REPOS.md](PROJECT/3-COMPLETED/PDDA-SYNC-TO-OTHER-REPOS.md)
diff --git a/install.sh b/install.sh
index 19aae53..0518441 100755
--- a/install.sh
+++ b/install.sh
@@ -40,6 +40,14 @@ TARGET=""
 # path with PDDA_REGISTRY; skip writing it with --no-register.
 PDDA_REGISTRY="${PDDA_REGISTRY:-${XDG_CONFIG_HOME:-$HOME/.config}/pdda/registry.tsv}"
 
+# Optional multi-device rollup: if git-pulse (a separate, GitHub-backed activity-sync tool) is present, the
+# installer also drops a PATH-NORMALIZED projection of the registry (repo name + date + source commit +
+# mode; never absolute paths) into git-pulse's repo under pdda/, and git-pulse's own sync carries it across
+# devices — no new sync infrastructure. Best-effort and fail-open: absent git-pulse → silently skipped, the
+# install is unaffected. The LOCAL registry above stays the source of truth. Override the location with
+# PDDA_GITPULSE_DIR; disable by pointing it at a nonexistent path, or with --no-register (same gate).
+PDDA_GITPULSE_DIR="${PDDA_GITPULSE_DIR:-${XDG_CONFIG_HOME:-$HOME/.config}/git-pulse/repo}"
+
 usage() {
   cat <<'USAGE'
 PDDA installer — install Project-Driven Doc Automation into a target repo.
@@ -59,6 +67,7 @@ Options:
   --no-register          Skip recording this install in the per-user registry
                          (default: $XDG_CONFIG_HOME/pdda/registry.tsv or ~/.config/pdda/registry.tsv;
                          override with PDDA_REGISTRY). The registry is machine-local and never committed.
+                         Also skips the multi-device git-pulse projection (see below).
   --mode <m>             Initial .pdda-mode: observe (default) | light | full.
   -h, --help             This message.
 
@@ -69,8 +78,14 @@ What gets installed (zero state):
   ROADMAP.md CHANGELOG.md PROJECT/PDDA-ACTIVITY.jsonl .pdda-mode   (blank seeds, create-only)
   .gitignore += PROJECT/PDDA-ACTIVITY.jsonl .pdda-gh-state.tsv     (churning runtime state)
 
-It also records the install in a per-user, machine-local registry (~/.config/pdda/registry.tsv) so a
-future sync layer knows where every copy lives. The registry is never committed. --no-register skips it.
+It also records the install in a per-user, machine-local registry (~/.config/pdda/registry.tsv) so
+pdda-sync.sh knows where every copy lives. The registry is never committed. --no-register skips it.
+
+If git-pulse (a GitHub-backed activity-sync tool) is present, the installer additionally drops a
+path-normalized projection of the registry (repo name + date + source commit + mode; never absolute
+paths) into git-pulse's repo under pdda/, and git-pulse's own sync carries that status across your
+devices. Best-effort and fail-open — absent git-pulse it is silently skipped. Override the location with
+PDDA_GITPULSE_DIR; the local registry remains the source of truth.
 
 After install it runs `utils/pdda/pdda.sh run` in the target so you see it working immediately.
 USAGE
@@ -228,10 +243,44 @@ ensure_runtime_ignored() {
   done
 }
 
+# Publish a path-normalized projection of the registry into git-pulse's sync repo when git-pulse is present,
+# so PDDA install status rolls up across devices with NO new sync infrastructure (git-pulse's own sync
+# carries the file). Normalized = col 1 absolute path -> bare repo name; the projection never contains a
+# filesystem path. Best-effort / fail-open (GUIDING-PRINCIPLES #6: never break an install); the local
+# registry stays the source of truth (#4) and keeps absolute paths because pdda-sync.sh cd's into them.
+# Rewritten in full every run, so the projection can't drift from the registry. A maintainer-LLM on another
+# machine locates a repo by name (the file header carries the exact find command), not by a path we ship.
+publish_registry_projection() {
+  local gp="$PDDA_GITPULSE_DIR" dev cfg out
+  [ -d "$gp/.git" ] || return 0   # no git-pulse checkout here -> nothing to roll up
+  cfg="${XDG_CONFIG_HOME:-$HOME/.config}/git-pulse/config.sh"
+  # Reuse git-pulse's own device id so PDDA and pulse files key on the same device; else fall back to host.
+  dev="$( ( . "$cfg" 2>/dev/null; printf '%s' "${device_id:-}" ) )"
+  [ -n "$dev" ] || dev="$(hostname -s 2>/dev/null || printf 'unknown-device')"
+  mkdir -p "$gp/pdda" 2>/dev/null || { say "  (git-pulse pdda/ not writable — publish skipped)"; return 0; }
+  out="$gp/pdda/registry-$dev.tsv"
+  # ponytail: registry paths are pwd-normalized (no trailing slash), so basename-via-split is safe.
+  if {
+       printf '# PDDA install status (normalized to repo name; absolute paths intentionally omitted).\n'
+       printf '# Maintainer LLM on another machine: a clone usually keeps the origin repo name as its folder,\n'
+       printf '# so locate it by exact name first:\n'
+       printf '#   find ~ -type d -name "<repo>" -exec test -d "{}/.git" \\; -print 2>/dev/null\n'
+       printf '# If that returns nothing (repo cloned into a renamed folder), fall back to a fuzzy search:\n'
+       printf '#   find ~ -type d -iname "*<repo>*" -exec test -d "{}/.git" \\; -print 2>/dev/null\n'
+       printf '# repo\tlast_install_utc\tmode\tsource_commit\tstartup_docs\n'
+       awk -F'\t' 'BEGIN{OFS="\t"} /^#/{next} NF==0{next} {n=split($1,a,"/"); $1=a[n]; print}' "$PDDA_REGISTRY"
+     } > "$out" 2>/dev/null; then
+    say "  publish   pdda/registry-$dev.tsv (normalized; git-pulse carries it)"
+  else
+    say "  (git-pulse publish failed — skipped)"
+  fi
+  return 0
+}
+
 # Record this install in the per-user, per-device registry (one row per target, latest wins). This is
-# the data a future sync layer reads to find copies that are behind — recording source_commit now means
-# that layer needs no schema change. Machine-local; never committed. Best-effort: a failure here never
-# fails the install.
+# the data pdda-sync.sh reads to find copies that are behind — recording source_commit means that layer
+# needs no schema change. Machine-local; never committed. Best-effort: a failure here never fails the
+# install. On success it also publishes the multi-device projection (publish_registry_projection).
 register_install() {
   [ "$REGISTER" -eq 1 ] || return 0
   local reg="$PDDA_REGISTRY" dir
@@ -255,7 +304,10 @@ register_install() {
   row="$(printf '%s\t%s\t%s\t%s\t%s' "$TARGET" "$ts" "$MODE" "$src_commit" "$sdocs")"
   tmp="$reg.tmp.$$"
   if awk -F'\t' -v t="$TARGET" '$1 != t' "$reg" > "$tmp" 2>/dev/null; then
-    printf '%s\n' "$row" >> "$tmp" && mv "$tmp" "$reg" && say "  register  $TARGET -> $reg"
+    if printf '%s\n' "$row" >> "$tmp" && mv "$tmp" "$reg"; then
+      say "  register  $TARGET -> $reg"
+      publish_registry_projection   # best-effort multi-device rollup; never fails the install
+    fi
   else
     rm -f "$tmp"
     say "  (registry write failed — skipped)"
diff --git a/test/pdda-publish-projection.sh b/test/pdda-publish-projection.sh
new file mode 100755
index 0000000..94fbef8
--- /dev/null
+++ b/test/pdda-publish-projection.sh
@@ -0,0 +1,61 @@
+#!/usr/bin/env bash
+# Test: install.sh's git-pulse projection (publish_registry_projection).
+# Verifies the multi-device rollup is (a) written, normalized to repo name with NO absolute paths, when a
+# git-pulse checkout is present, and (b) fail-open — an install on a machine without git-pulse still
+# succeeds and writes the local registry, and never creates a stray projection.
+set -u
+
+HERE="$(cd "$(dirname "$0")" && pwd)"
+REPO_ROOT="$(cd "$HERE/.." && pwd)"
+INSTALL="$REPO_ROOT/install.sh"
+
+PASS=0
+FAIL=0
+pass() { PASS=$((PASS + 1)); printf 'ok   - %s\n' "$1"; }
+fail() { FAIL=$((FAIL + 1)); printf 'FAIL - %s\n' "$1"; }
+assert_contains() { case "$1" in *"$2"*) pass "$3" ;; *) fail "$3 (missing: $2)"; printf '----\n%s\n----\n' "$1" ;; esac; }
+assert_absent()   { case "$1" in *"$2"*) fail "$3 (unexpected: $2)"; printf '----\n%s\n----\n' "$1" ;; *) pass "$3" ;; esac; }
+
+SBOX="$(mktemp -d "${TMPDIR:-/tmp}/pdda-publish.XXXXXX")"
+cleanup() { [ -n "$SBOX" ] && rm -rf "$SBOX"; }
+trap cleanup EXIT
+
+git_init() { ( cd "$1" && git init -q && git config user.name t && git config user.email t@e ); }
+
+# --- Case 1: git-pulse present -> normalized projection is published ------------------------------------
+TARGET="$SBOX/myproj-repo"; mkdir -p "$TARGET"; git_init "$TARGET"
+GP="$SBOX/gitpulse-repo";   mkdir -p "$GP";     git_init "$GP"          # the .git makes it a publish target
+REG="$SBOX/registry.tsv"
+XDG="$SBOX/xdg"; mkdir -p "$XDG/git-pulse"; printf 'device_id="test-device"\n' > "$XDG/git-pulse/config.sh"
+
+XDG_CONFIG_HOME="$XDG" PDDA_REGISTRY="$REG" PDDA_GITPULSE_DIR="$GP" \
+  bash "$INSTALL" --mode observe "$TARGET" >/dev/null 2>&1
+rc=$?
+[ "$rc" -eq 0 ] && pass "install exits 0 with git-pulse present" || fail "install exit $rc with git-pulse present"
+
+PROJ="$GP/pdda/registry-test-device.tsv"
+[ -f "$PROJ" ] && pass "projection written under git-pulse device id" || fail "projection file missing ($PROJ)"
+body="$(cat "$PROJ" 2>/dev/null)"
+assert_contains "$body" "absolute paths intentionally omitted" "projection carries the maintainer header"
+assert_contains "$body" "myproj-repo" "projection lists the installed repo by bare name"
+# No data row (non-comment line) may contain a slash -> proves paths are stripped.
+data_with_slash="$(grep -v '^#' "$PROJ" 2>/dev/null | grep '/' || true)"
+[ -z "$data_with_slash" ] && pass "no absolute path leaks into any data row" || { fail "a data row contains '/'"; printf '%s\n' "$data_with_slash"; }
+assert_absent "$body" "$SBOX" "projection contains no sandbox/filesystem path"
+# Local registry still authoritative and DOES keep the absolute path.
+assert_contains "$(cat "$REG")" "$TARGET" "local registry keeps the absolute target path"
+
+# --- Case 2: no git-pulse -> fail-open (install still works, nothing published) ------------------------
+TARGET2="$SBOX/other-repo"; mkdir -p "$TARGET2"; git_init "$TARGET2"
+REG2="$SBOX/registry2.tsv"
+MISSING="$SBOX/no-such-gitpulse"   # never created -> no .git -> publish must skip
+
+XDG_CONFIG_HOME="$XDG" PDDA_REGISTRY="$REG2" PDDA_GITPULSE_DIR="$MISSING" \
+  bash "$INSTALL" --mode observe "$TARGET2" >/dev/null 2>&1
+rc=$?
+[ "$rc" -eq 0 ] && pass "install exits 0 with git-pulse absent (fail-open)" || fail "install exit $rc with git-pulse absent"
+assert_contains "$(cat "$REG2")" "$TARGET2" "local registry written even when git-pulse absent"
+[ ! -e "$MISSING" ] && pass "no stray projection dir created when git-pulse absent" || fail "publish wrote into a non-git-pulse path"
+
+printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"
+[ "$FAIL" -eq 0 ]
diff --git a/utils/pdda/PDDA-INSTALL.md b/utils/pdda/PDDA-INSTALL.md
index 39d9a8b..b1e3066 100644
--- a/utils/pdda/PDDA-INSTALL.md
+++ b/utils/pdda/PDDA-INSTALL.md
@@ -128,7 +128,8 @@ Create a fresh empty file instead.
 3. Create baseline `ROADMAP.md` and `CHANGELOG.md` files if the target repo does not already have them. -> expect the roadmap contract to have a file to guard and the changelog check to warn less.
 4. Create an empty `PROJECT/PDDA-ACTIVITY.jsonl` if it does not exist. -> expect a zero- or low-byte log file, not this repo's historical log.
 4a. Add `PROJECT/PDDA-ACTIVITY.jsonl` to the target's `.gitignore` (and `git rm --cached` it if already tracked). -> expect the churning runtime log to stop dirtying `git status` on every run.
-4b. Record the install in the per-user, machine-local registry `${XDG_CONFIG_HOME:-$HOME/.config}/pdda/registry.tsv` (one tab-delimited row per target: `target · last_install_utc · mode · source_commit · startup_docs`; latest install wins). -> expect a future sync layer to read this to find copies that are behind. Machine-local, never committed; `--no-register` or `PDDA_REGISTRY` adjust it.
+4b. Record the install in the per-user, machine-local registry `${XDG_CONFIG_HOME:-$HOME/.config}/pdda/registry.tsv` (one tab-delimited row per target: `target · last_install_utc · mode · source_commit · startup_docs`; latest install wins). -> expect `pdda-sync.sh` to read this to find copies that are behind. Machine-local, never committed; `--no-register` or `PDDA_REGISTRY` adjust it.
+4c. If git-pulse (a separate, GitHub-backed activity-sync tool) is present, also write a path-normalized projection of the registry into `<git-pulse-repo>/pdda/registry-<device>.tsv` (col 1 reduced to the bare repo name; **no absolute paths**), letting git-pulse's own sync roll PDDA install status up across devices. -> expect this to be best-effort and fail-open: absent git-pulse it is silently skipped and the install is unaffected. The local registry stays the source of truth. Location: `PDDA_GITPULSE_DIR` (default `${XDG_CONFIG_HOME:-$HOME/.config}/git-pulse/repo`); `--no-register` skips it too.
 5. Make the shell scripts executable. -> expect `chmod +x utils/pdda/pdda.sh utils/pdda/pdda-doc-ready.sh utils/pdda/pdda-lib.sh utils/pdda/pdda-catchup.sh utils/pdda/pdda-gh-refresh.sh utils/pdda/pdda-edit-doc-hook.sh utils/pdda/pdda-stop-doc-health.sh` to succeed.
 6. Optionally create a repo-root `.pdda-mode` file with `observe` for first install. -> expect a non-destructive first run.
 7. If the target repo uses a different doc layout, set environment overrides instead of editing the scripts first. -> expect the checks to honor the env vars below.
```
- Definition of Done: _<fill in the acceptance criteria the Reviewer grades against>_

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Round 1 · Reviewer · codex · 2026-06-30
- [Should] `install.sh` writes the shared projection straight to `"$gp/pdda/registry-$dev.tsv"` with `> "$out"`. That is fine for a local cache, but this file exists specifically to be picked up by git-pulse's concurrent sync, so a sync/read can catch the file mid-truncate and publish a partial snapshot to other devices. Concrete fix: write the header + `awk` output to a temp file in `"$gp/pdda"` and `mv` it into place only after generation succeeds, preserving the previous good projection on failure. Add a targeted test that seeds an existing projection, forces generation failure, and proves the old file survives unchanged.
- [Pass] The feature stays on the right side of the fail-open / no-new-git-logic bet: local registry remains authoritative, `--no-register` gates both writes, and the docs/test update in lockstep with the shell change.

**Verdict:** Changes requested.
**NEXT:** Producer.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
