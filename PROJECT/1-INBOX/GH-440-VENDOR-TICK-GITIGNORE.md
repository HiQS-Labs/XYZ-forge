---
title: xyz-vendor.sh ensure_gitignore adds .xyz/ but not /.tick/, leaving tick runtime state untracked
status: Proposed (1-INBOX — not yet active)
created: 2026-08-07
owner: noel
gh_issue: 440
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/440
doc_type: bugfix
complexity: 1
risk: 2
effort: 1
phases: 1
ratings_provisional: true
reported_from: giant-brains-claude-skills
harness_commit: beb0a51
non_goals:
  - Changing where .tick/ lives, or making tick state shareable across machines — this is a
    gitignore-hygiene gap in the vendor step, not a redesign of tick's storage model
  - Fixing #314's inverse problem (ensure_gitignore never un-ignoring paths that must be tracked),
    though a fix here should compose with it rather than adding a second append path
related:
  - "#18 — Medium finding #3 names the same untracked-.tick symptom, but for a --target-root
     cross-repo drive into a repo that never vendored; resolved doc-only, no code change"
  - "#314 — OPEN, same ensure_gitignore() function, opposite direction (un-ignoring phases/ and
     relay-system/); likely the same seam a fix would touch"
  - "#312 — re-vendor destroying live .tick/ state; different bug, unrelated to gitignore"
goal: >
  After `xyz-vendor.sh vendor <repo>`, the consuming repo ignores `/.tick/` the same way it
  ignores `.xyz/`, so the first driven relay leaves no untracked runtime noise and the tick
  event log cannot be committed by an unrelated `git add -A`.
---

# GH-440 — `xyz-vendor.sh` `ensure_gitignore` adds `.xyz/` but not `/.tick/`

> **1-INBOX capture**, not the active-work doc — no `## Status` table yet. On promotion to
> `PROJECT/2-WORKING/`, add the status table + per-phase QA gates and carry `gh_issue` forward
> (`PROJECT/PDDA.md` → GitHub issue intake).

## Symptom

After `xyz-vendor.sh vendor <repo>`, the consuming repo's `.gitignore` gets `.xyz/` but **not**
`/.tick/`. The first driven relay or marathon run creates `<repo>/.tick/` at the repo root, where
it shows up as untracked (`?? .tick/`) in `git status` and can be committed by accident.

`.tick/` is explicitly per-device, non-shared coordination state — `skills/relay-xyz/SKILL.md`
says ".tick/ is gitignored and per-device, so this is single-clone coordination, not
cross-machine" — but nothing in the vendor path makes that true for the consuming repo.

## Environment

- **Observed from:** `giant-brains-claude-skills` (vendored `.xyz/`)
- **Harness commit:** `beb0a51` — `ensure_gitignore()` verified unchanged at this commit
- **Worker/CLI:** n/a — the gap is in the vendor step, not a turn-taker
- **Runtime:** n/a — `xyz-vendor.sh` is bash-only with no Python twin, so no `runtime:*` label was
  applied (tagging it would misroute triage toward the turn-taker twins)
- **Sandbox:** n/a

## Reproduction

1. `xyz-vendor.sh vendor <some-repo>` → `.xyz/` is appended to `<some-repo>/.gitignore`.
2. From that repo, drive any relay that seeds a tick task:
   `tick log task.created <T> --agent claude-a && tick claim <T> --agent claude-a --paths <f> &&
   tick release <T> --agent claude-a --to codex`, then
   `relay-automation/relay-drive.sh --relay-file <f> --relay-task <T> --agent-cmd
   relay-automation/codex-turn.sh --review-once`
3. `git -C <some-repo> status --short`

**Expected:** `.tick/` is ignored the same way `.xyz/` is — `ensure_gitignore()` appends `/.tick/`
idempotently alongside `.xyz/`.
**Observed:** `?? .tick/` appears as untracked noise in the consuming repo.
**Frequency:** Every time — deterministic code path, not a race.

```text
$ git status --short
 M README.md
?? .tick/
```

Responsible code — `relay-automation/xyz-vendor.sh:211-218`:

```bash
ensure_gitignore() {
  local gitignore="$TARGET_REPO/.gitignore"
  if [ ! -f "$gitignore" ]; then
    : > "$gitignore"
  fi
  if ! grep -Fqx '.xyz/' "$gitignore" 2>/dev/null; then
    printf '%s\n' '.xyz/' >> "$gitignore"
```

## Impact

Low severity, hygiene class — but a public-repo footgun. The reporting repo is a public skills
repo whose maintainers deliberately gitignore local runtime state rather than track it; a
per-device tick event log sitting in `git status` is exactly what gets swept up by an unrelated
`git add -A`. Workaround is a hand-added `/.tick/` line in the consuming repo's `.gitignore`.

## Related work

Prior art was checked before filing (see `related` frontmatter). #18 named the same *symptom* in
the `--target-root` cross-repo case and was closed doc-only, so the vendor-time gap was never
addressed in code. #314 is open against the same function in the opposite direction; if it lands
first, this fix should extend its mechanism rather than bolt on a second append.

## Phase 0 — Diagnose & scope

> Discovery phase: its findings are written **back into this doc** before its QA gate can pass
> (`PROJECT/PDDA.md` → Discovery & spike phases).

### Checklist
- [ ] Reproduce in the intake repo (vendor into a scratch repo, drive a relay, check `git status`)
- [ ] Confirm the write-set is `relay-automation/xyz-vendor.sh` alone, plus its test
- [ ] Decide whether `/.tick/` is appended unconditionally or only when tick is actually vendored
- [ ] Check interaction with #314 — one `ensure_gitignore` that both adds and removes, not two paths
- [ ] Decide whether existing vendored repos get retrofitted by `xyz-sync update`, or only new vendors
- [ ] Set/correct the triage ratings; clear `ratings_provisional` once real

### QA checklist — Phase 0
- [ ] The repro is confirmed in the intake repo, not just taken from the report
- [ ] `test/xyz-vendor.sh` gains a case asserting `/.tick/` is present and appears exactly once
      after an idempotent re-run (mirroring the existing `.xyz/` assertions at lines 62 and 67-69)
- [ ] The fix reuses the existing `grep -Fqx` guard rather than introducing a parallel append path
