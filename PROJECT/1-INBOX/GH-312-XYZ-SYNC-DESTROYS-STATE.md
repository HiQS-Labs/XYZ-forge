---
title: xyz-sync update destroys the target's live relay-system/ and .tick/ state
status: Proposed (1-INBOX — not yet active)
created: 2026-07-27
owner: noel
gh_issue: 312
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/312
doc_type: bugfix
complexity: 2
risk: 5
effort: 2
phases: 1
ratings_provisional: true
reported_from: rebalance-OS
harness_commit: dff45d5
non_goals:
  - Redesigning where vendored runtime state lives (noted as the more durable fix, scoped separately)
  - Changing the pinned-and-manual update model itself
  - Any change to `check`'s report-only drift contract (GH-96)
related:
  - skills/relay-xyz/SKILL.md (sells vendoring on per-repo `.tick/` isolation)
goal: >
  `xyz-sync update` updates the vendored harness CODE while leaving the target repo's
  runtime state — relay-system/, .tick/, .relay-driver.lock — intact. An operator with a
  live or closed relay in a vendored repo can update without losing it, and without
  needing to know to check first.
---

# GH-312 — xyz-sync update destroys the target's live relay-system/ and .tick/ state

> **1-INBOX capture**, not the active-work doc — no `## Status` table yet. On promotion to
> `PROJECT/2-WORKING/`, add the status table + per-phase QA gates and carry `gh_issue` forward
> (`PROJECT/PDDA.md` → GitHub issue intake).

## Symptom

`xyz-sync.sh update <dir>` re-vendors the whole `.xyz/` tree and deletes the target's live runtime
state — `relay-system/` and `.tick/` — with no warning, no backup, and no preservation. It exits 0
and prints a success message.

## Environment

- **Observed from:** `rebalance-OS` (vendored `.xyz/` install)
- **Harness commit:** `dff45d5`
- **Vendored `.xyz/VERSION`:** `58b30fe464d9` → `dff45d58f034` (the update under test)
- **Worker/CLI:** `tick` 0.2.0; `codex` (relay had just closed)
- **Runtime:** n/a — `xyz-sync.sh` / `xyz-vendor.sh` are bash-only utilities with no Python twin.
  Not a Python-twin bug, not `XYZ_PYTHON=0`-only, not a parity divergence. `runtime:*` label
  deliberately omitted so this is not misrouted into legacy-bash-path triage.
- **Sandbox:** off

## Reproduction

Deterministic — an unconditional `rm -rf`, so it reproduces every time.

1. Vendor the harness into a repo: `xyz-vendor.sh vendor <repo>`
2. Run any relay in it, so `.xyz/relay-system/<date>/<slug>.md` and `.xyz/.tick/events/*.jsonl` exist
3. Let the harness move ahead so the vendored copy drifts
4. `bash relay-automation/xyz-sync.sh update <repo>`

**Expected:** the harness *code* updates; the target's runtime state survives.

**Observed:** exit 0, success output, runtime state gone.

**Frequency:** every time.

```text
$ bash relay-automation/xyz-sync.sh update /path/to/repo
registry: updated /Users/<redacted>/.config/xyz/registry.tsv
vendored harness -> /path/to/repo/.xyz

$ ls /path/to/repo/.xyz/relay-system/2026-07-27/
MISSING

$ ls /path/to/repo/.xyz/.tick/events/ | wc -l
0
```

## Mechanism

`relay-automation/xyz-vendor.sh:281-282`:

```bash
rm -rf "$VENDOR_DIR"
mv "$STAGE_DIR" "$VENDOR_DIR"
```

Stage-then-swap. `$STAGE_DIR` is mirrored purely from `$HARNESS_ROOT`, which holds harness source
and nothing the target accumulated — so the `rm -rf` deletes `relay-system/` and `.tick/` unread.
No backup step, no `--dry-run`, no preserve list in either `xyz-vendor.sh` or `xyz-sync.sh`.

## Why this is worse than it first looks

- **The destroyed paths are what vendoring is sold on.** `skills/relay-xyz/SKILL.md` pitches a
  vendored install as the way to get per-repo isolation — "**own** `.xyz/.relay-driver.lock`,
  `.tick/`, and worktrees". The documented benefit of vendoring is exactly what `update` destroys.
- **Invisible to git by construction.** `xyz-vendor.sh` calls `ensure_gitignore`, so `.xyz/` is
  gitignored. Nothing under it was ever hashed into a git object — no reflog, no stash, no
  `git fsck --lost-found` recovery.
- **A closed relay was the lucky case.** The same command mid-review destroys an *active* thread
  and a claimed `tick` token; the peer agent's turn simply vanishes.
- **The docs give no warning.** `xyz-sync.sh`'s header explains that `check` is "report-only…
  never auto-pulls" and that updates are "pinned + manual, by design" — framing `update` as
  *deliberate*, never as *destructive*.

## Impact

Any operator who both vendors the harness and runs relays in that repo, on any explicit `update`.
`xyz-sync list` on the reporting machine showed **6 repos** with vendored `.xyz/` at the same stale
commit — each a candidate to lose live state on its next update, and `xyz-sync update --all` would
take them all out in one command.

**Real incident (2026-07-27):** destroyed a completed two-round Codex relay thread — both reviews,
producer dispositions, closing block — plus the full `.tick/` event log. The findings survived only
because the Codex CLI transcripts happen to live in `$TMPDIR`, outside the harness. Recovery was
manual reconstruction into the reporting repo's tracked tree.

Workaround: manually copy `relay-system/` and `.tick/` aside before updating, then copy back.
Nothing surfaces this requirement.

## Requested fix

Preserve target-owned runtime state across the swap — treat `relay-system/`, `.tick/`, and
`.relay-driver.lock` as data belonging to the target repo rather than harness code:

```bash
# xyz-vendor.sh, before the swap
for keep in relay-system .tick .relay-driver.lock; do
  [ -e "$VENDOR_DIR/$keep" ] && cp -Rp "$VENDOR_DIR/$keep" "$STAGE_DIR/"
done
rm -rf "$VENDOR_DIR"
mv "$STAGE_DIR" "$VENDOR_DIR"
```

Chosen over a warning or a refusal because both still depend on someone reading output at the right
moment. Preservation makes `update` non-destructive by default and needs no operator vigilance.

## Phase 0 — Diagnose & scope

> Discovery phase: its findings are written **back into this doc** before its QA gate can pass
> (`PROJECT/PDDA.md` → Discovery & spike phases).

### Checklist

- [ ] Reproduce in the intake repo (vendor into a scratch repo, seed a relay, update)
- [ ] Confirm the preserve list is complete — audit what else `.xyz/` accumulates at runtime
      beyond `relay-system/`, `.tick/`, `.relay-driver.lock`
- [ ] Decide whether preservation is the end state, or whether runtime state should live outside
      `.xyz/` entirely (that directory is disposable and gitignored by design — arguably the wrong
      home for durable state). Preservation is the minimal fix; relocation is the durable one.
- [ ] Check whether `xyz-vendor.sh vendor` (first install over an existing `.xyz/`) has the same
      destructive path
- [ ] Set/correct triage ratings; clear `ratings_provisional` once real

### QA checklist — Phase 0

- [ ] The repro is confirmed in the intake repo, not assumed from the report
- [ ] A regression test seeds `relay-system/` + `.tick/`, runs `update`, and asserts both survive —
      landed **before** the fix
- [ ] The fix composes with the existing stage-then-swap rather than adding a parallel copy path
- [ ] Docs updated: `xyz-sync.sh` header and `relay-xyz/SKILL.md` state what `update` does to
      runtime state
