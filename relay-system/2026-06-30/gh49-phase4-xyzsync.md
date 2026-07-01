# RELAY · GH-49 Phase 4 — xyz-sync (registry-backed update/delete/list of vendored copies)
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
6. **Commit only the relay file** (`relay(gh49-phase4-xyzsync): <role> r<N>`); no push. **Stop** and report one line.

## Setup
- **Deliverable (Producer builds ONE new file):** `relay-automation/xyz-sync.sh` — registry-backed update/delete/list of vendored `.xyz/` copies.
- Reviewer: agy   ·   Producer: codex
- Started: 2026-06-30
- **Spec:** `PROJECT/2-WORKING/GH-49-VENDORED-LOCAL-COPY.md` → "Phase 4 — `xyz-sync` update/delete" + its QA checklist. Read it.
- **Reference (reuse, don't reinvent):**
  - `relay-automation/xyz-vendor.sh` (shipped Phase 1) — the vendor/materialize command. **`xyz-sync --update` is just a re-vendor**: invoke `xyz-vendor.sh <target-repo>` for the row. Read its registry schema + `XYZ_REGISTRY` handling and match it exactly.
  - Registry `~/.config/xyz/registry.tsv` (override `$XYZ_REGISTRY`): tab-separated, columns `install_dir · last_install_utc · tick_version · source_commit · coordinated_repo`; `#`-comment header lines. **A vendored row is one whose `install_dir` basename is `.xyz`** (xyz-vendor writes `install_dir=<repo>/.xyz`, `coordinated_repo=<repo>`). The target repo for a vendored row = its `coordinated_repo` (or `dirname install_dir`).

### Producer brief — build `relay-automation/xyz-sync.sh`

`set -euo pipefail`; bash 3.2-safe (macOS); symlink-safe self-location from `$BASH_SOURCE` (sibling of `xyz-vendor.sh`). Registry path from `$XYZ_REGISTRY` else `${XDG_CONFIG_HOME:-$HOME/.config}/xyz/registry.tsv` (same as xyz-vendor). Subcommand CLI:

- **`xyz-sync list`** — print each **vendored** registry row (install_dir basename == `.xyz`): the `.xyz` path, its `source_commit`, and whether the `.xyz/` dir still exists on disk (present / **MISSING**). Header-friendly, human-readable.
- **`xyz-sync update <dir> | --all`** — for the chosen vendored copy (or every vendored row with `--all`): resolve the target repo (`coordinated_repo`, else `dirname <install_dir>`) and **re-vendor by invoking `xyz-vendor.sh <target-repo>`** (which restamps VERSION + refreshes the registry row). `<dir>` may be given as either the repo or its `.xyz` path — normalize both. If the target repo no longer exists on disk → treat as a stale row (see prune).
- **`xyz-sync delete <dir> | --all`** — remove `<repo>/.xyz/` from disk **and** drop its row from the registry (atomic tmp+mv, mirroring xyz-vendor's dedup writer). **Guard destructive action:** require an explicit `--yes` to actually delete; without it, **dry-run** (print exactly what WOULD be removed, change nothing). Never delete anything outside a registered `.xyz/` path.
- **Fail-open on stale rows:** a vendored row whose `.xyz/` (or target repo) is gone should be handled gracefully — `list` marks it MISSING; `delete` still prunes the orphan row; `update` skips it with a note. Never crash on a missing path.
- **`-h`/`--help`** usage; unknown subcommand → usage to stderr, exit 2.

**Containment:** writes only under registered `.xyz/` paths (delete) and `$HOME`/`$XYZ_REGISTRY` (row edits) + whatever `xyz-vendor.sh` writes (update). Never touches the harness clone, `.tick/`, or any path not derived from a vendored registry row. Keep it to **this one new file**; do not edit `xyz-vendor.sh`, `find-harness.sh`, or the spec.

## Definition of Done (Reviewer grades against this)
1. `relay-automation/xyz-sync.sh` exists, `bash -n` clean, `set -euo pipefail`, bash 3.2-safe, `-h` works; subcommands `list` / `update` / `delete`.
2. `list` shows vendored rows (install_dir basename `.xyz`) with source_commit + on-disk present/MISSING.
3. `update <dir>` re-vendors via `xyz-vendor.sh` (VERSION restamped, one registry row); `--all` covers every vendored row.
4. `delete <dir>` **dry-runs by default**, needs `--yes` to actually `rm -rf` the `.xyz/` + drop the row (atomic tmp+mv); re-run after delete is a clean no-op; only ever removes a registered `.xyz/` path.
5. Stale/missing paths are fail-open (list=MISSING, delete prunes the orphan row, update skips) — never crashes.
6. Writes only under registered `.xyz/` paths + `$HOME`/registry (+ xyz-vendor's outputs for update); nothing in the harness clone or `.tick/`.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
