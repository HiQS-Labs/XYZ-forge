# RELAY · PDDA-SYNC realignment review (HQ push model, auto-manifest, delete-mirror)
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-06-29.
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
6. **Commit only the relay file** (`relay(pdda-sync-realignment-review-hq-push-model-auto-manifest-delete-mirror): <role> r<N>`); no push. **Stop** and report one line.

## Setup
- Artifact under review: **.relay-artifacts/PDDA-SYNC-TO-OTHER-REPOS.md** — the read-only path that
  `relay-drive.sh --artifact-file /Users/noelsaw/Documents/GH Repos/pdda/PROJECT/2-WORKING/PDDA-SYNC-TO-OTHER-REPOS.md` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-06-29
- Definition of Done (grade the PLAN doc against these — it is a planning/design doc, not code):
  1. **Internal consistency of the realignment.** The three reversed decisions (trigger → manual
     `push` primary / launchd optional; deletions → mirror-with-backup; manifest → auto-regenerated)
     are reflected coherently across frontmatter `goal`, Context, Design, every Phase, and Resolved
     decisions — no leftover "launchd-primary" or "static-list" language that contradicts the new model.
  2. **Delete-mirror safety is airtight.** The new "remove from targets what HQ removed" behavior has
     no path to irrecoverable or runaway data loss: backup-before-delete, manifest-diff-gated (only
     paths HQ previously shipped), `--no-delete`, and the large-deletion abort guard are sufficient and
     unambiguous. Flag any gap (e.g. an empty/mis-declared source root, a target that renamed a file).
  3. **Honors GUIDING-PRINCIPLES.** Esp. #4 (one canonical place per fact — this doc is now the sole
     owner), #6 (low-friction/portable), and the non-destructive `observe` ethos (dry-run, recoverable
     backups, dirty-source guard).
  4. **Phases + QA gates are testable and cover the new behaviors.** New-file/folder propagation,
     delete-mirror (copy + delete dogfood), manual-push-primary, and optional-launchd each have a
     concrete, falsifiable QA gate.
  5. **No scope creep past `non_goals`; ratings plausible.** effort/complexity/risk (3/3/3) still fit
     after adding delete-mirroring and the manifest expander.
- Producer's stance to challenge: I (claude-a) deliberately reopened 3 prior "Resolved decisions" per
  the operator's fresh choices. Push back if any reversal is under-justified or introduces risk the doc
  doesn't contain.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Round 1 · Reviewer · codex
**Verdict:** Changes requested
VERDICT: FAIL
Basis: Textual review of `.relay-artifacts/PDDA-SYNC-TO-OTHER-REPOS.md` against the relay Definition of Done and `GUIDING-PRINCIPLES.md`; no code or repo-wide gates run because this turn is review-only and relay-file-scoped.

- **[Blocker] Delete-mirror safety is still underspecified for a truncated/poisoned manifest.** The doc adds `--no-delete` and a "large deletion abort guard," but it never defines a hard stop for the case where the expander silently returns an empty or badly shrunken set from a mis-declared root / over-broad exclude. As written, a bad manifest that drops "only" a moderate fraction of files could still delete previously shipped paths, which fails DoD #2's "no path to runaway data loss" bar. Concrete fix: add an explicit invariant in Design + Phase 2 that delete mode aborts before touching targets when any declared root unexpectedly resolves to zero tracked files, when the current expanded manifest is empty after previously being non-empty, or when shrinkage crosses a defined threshold unless the operator passes an explicit force/ack flag.
- **[Should] Phase 3 duplicates registry ownership instead of keeping `install.sh` canonical.** Context/Design say the registry foundation is already shipped and `install.sh` writes `~/.config/pdda/registry.tsv` on every install/upgrade, but Phase 3 still says `register` should run `install.sh` and then "append to the registry." That creates two writers for the same fact and directly cuts against GUIDING-PRINCIPLES #4 / the doc's own DRY story. Concrete fix: rewrite Phase 3 so `register` delegates the initial copy + registry write to `install.sh` (or a shared helper) and only seeds sync state/manifest snapshot afterward; do not describe a second append path unless the design explicitly moves registry writes out of `install.sh`.
- **[Should] Phase 5 has a leftover location contradiction about the registry.** The doc correctly says the registry lives in `${XDG_CONFIG_HOME:-$HOME/.config}/pdda/registry.tsv`, but Phase 5 says to note in `.gitignore` that `temp/` holds "the registry/state/manifest/backups." `temp/` does not hold the registry under this design. Concrete fix: change that Phase-5 docs bullet to say `temp/` holds sync state, expanded-manifest snapshots, backups, log, and lockfiles, while the registry remains machine-local under XDG config.
- **[Pass] The trigger/manifest/deletion realignment is otherwise coherent.** `goal`, Realignment, Context, Phases 2/4, and Resolved decisions all consistently describe manual `push` as primary, launchd as optional, and the manifest as auto-regenerated rather than static.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
