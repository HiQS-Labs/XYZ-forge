# Parked — session close 2026-08-19

Items deliberately NOT continued in this session, filed here so they stop resurfacing in chat.
Each carries enough context to pick up cold. Nothing in this file is lost work — every item has a
GitHub issue, PR, or in-repo pointer as its real home; this is the index.

> Folder convention (new this session, operator-directed): one dated file per parking event,
> append-only. An item leaves by being done or explicitly dropped, not by silence.

> **Update — 2026-08-19, later the same day (audit session).** Three items left this file by being
> done, not by silence: release **0.7.1 Bulwark shipped** (evidence in the receipt chain, generation
> 9); issues **#61–#65** — filed that afternoon and never triaged anywhere — are now a Queue entry in
> `ROADMAP.md`; and the ledger's four stale status markers (GH-23/#39/#45/#57, all closed on GitHub)
> were moved to Completed. New: **[#75](https://github.com/HiQS-Labs/XYZ-forge/issues/75)** (the
> two-ledger dashboard) is queued at the FRONT of the line by operator call. Nothing below changed.

## Decisions waiting on the operator

| Item | Where it lives | What's needed | Check |
|---|---|---|---|
| PR **#29** (Windows/MSYS2 audit) | open PR, standing HOLD | Do not merge until the operator lifts the hold. | `check: gh pr view 29 --json state` |
| PR **#51** (portable repro scripts, follow-up to #29) | open PR | Unreviewed; review or close. | `check: gh pr view 51 --json state` |
| Four `roadmap_exempt` docs (upstream-numbered GH-544/555/563/564 in `PROJECT/2-WORKING/`) | frontmatter comments in each doc | Decide per doc: re-file under a NEW this-repo issue number, or archive. | `check: ls PROJECT/2-WORKING/GH-5*.md` |
| `PROJECT/1-INBOX/GH-18-COMMANDCODE-EVAL.md:54` | stale doc line | Still claims PR #19's actions "landed" (never true; half-true since `43bbce3`). One-line correction when touched next. | `check: grep landed PROJECT/1-INBOX/GH-18-COMMANDCODE-EVAL.md` |

## Filed issues, parked by priority

| Issue | Priority | One-liner | Check |
|---|---|---|---|
| [#59](https://github.com/HiQS-Labs/XYZ-forge/issues/59) | P2 | Re-arm hosted CI: repo is public, Actions enabled, triggers in ci.yml — yet pushes produce zero runs. Find the cause, then narrow triggers to push/merge on `development`+`main`, then wire the required status check behind `main`'s branch protection (protection is already live, PR-required). | `check: gh issue view 59 --json state` |
| [#58](https://github.com/HiQS-Labs/XYZ-forge/issues/58) | P2/P3 | GH-35 Phase 3 follow-ups: tier-2 skips the hygiene suites (security-scan, mktemp-trap-guard, path-integrity, checkjs) — P2; `--tier 3 --subsystem X` silently runs tier 2 — P3; pre-push mktemp-failure path contradicts its comment (`_rc` unbound) — P3. Recommended: ride with Phase 3's registry widening, not before. | `check: gh issue view 58 --json state` |
| [#56](https://github.com/HiQS-Labs/XYZ-forge/issues/56) | P3 | Split the 2,214-line `skills/xyz/SKILL.md` into SKILL.md + MANUAL.md. Re-derive from today's file; do NOT resurrect PR #19's `tree-hygiene-guard.sh` (GH-484 trap). | `check: gh issue view 56 --json state` |
| [#68](https://github.com/HiQS-Labs/XYZ-forge/issues/68) | P3 | `HARNESS-MODELS-REGISTRY.md` row from PR #60 is off-schema (date in the Harness column). Fold into the next touch of that file. | `check: gh issue view 68 --json state` |

*(#67 is NOT parked — promoted to the roadmap's Queue position 1 this session, per operator call.)*

## #69 (ROADMAP-as-ledger) — remaining stages, parked pending shadow evidence

The shadow (Stage 3) is LIVE as of PR #72: `releases roadmap sync` mirrors the ledger into
`roadmap_items` (18 rows at last sync). What's parked:

- **Stage 1** — make the marathon planner REFUSE an unrecognised `###` heading under `## Ledger`
  instead of skipping silently. Documented in ROADMAP.md's `## Entry format`; not built. The
  single highest-value enforcement item when enforcement is back on the menu.
- **Stage 2** — the RELEASES strict flip: 24 `grandfather_entries` still pending disposition;
  Phase 0 remains side-by-side (the tool never writes RELEASES.md).
- **Stages 4–5** — write-set/collision-cluster table, then item-level join to releases via
  `manifest_items`. Gate: does anything actually query the shadow rows? Candidate consumer:
  GH-442 `/radar`. Check back after a few weeks of shadow data.
- Enforcement trio from the wiring review (unknown-heading refusal / entry links resolve / no
  upstream-repo links creep back) — one small suite when wanted.

## Smaller loose ends

- **`releases check` post-commit rewind detection** (noted closing #57): the resolver now refuses
  a rewound generation header AT the merge, but a hand-edited dump committed WITHOUT the resolver
  would not be caught afterward. Small, separate check if wanted.
- **`--burst` benchmark** never measured (throttle vs default was: 432s/2.15-cores vs
  618s/1.39-cores, RSS identical).
- **Local `feat` branch** — RESOLVED this session, recorded for the audit trail: it was fixture
  garbage from a test-sandbox escape (~230 `init`/`seed`/`marathon:` commits; tree deleted 663
  files including validate.sh). Never pushed, no worktree. Deleted;
  recoverable until reflog expiry via `git branch feat 675b4ec6e7b1c74b926d4f526c0dc5cf3d166840`.
