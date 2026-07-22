---
gh_issue: 268
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/268
title: "Beta onboarding & build-quality test report — remediation plan (re: #123)"
status: "plan drafted 2026-07-22, pending /relay-xyz QA + preflight — no phase fired yet"
created: 2026-07-22
updated: 2026-07-22
owner: noel
doc_type: project
reversibility: "Easy — every phase's fixes are additive doc/script/gate changes with normal git history (README reordering, installer scripts, a gate-wiring script, a manual re-test); nothing here is a one-way door and all of it reverts with git revert."
complexity: 4
risk: 3
effort: 5
phases: 4
ratings_provisional: true
related:
  - "#123 — Beta Testing Protocol (CLOSED; the onboarding protocol #268's test walked through)"
  - "#232 — validate.sh ubuntu CI failures (CLOSED via PR #271, merge 2a2da17; unblocks Phase 4's cross-model re-test)"
non_goals:
  - Re-auditing or re-litigating #268's own findings — this doc takes the tester's report as given
    and organizes remediation. It does not re-run the beta test.
  - Filing 9 separate GH issues, one per finding — the operator asked for a SINGLE planning doc that
    points back to #268 as the source of truth, not an issue-per-item split.
  - Fixing the specific WooCommerce plugin bugs the independent audit found (20 issues, 1 critical,
    4 high, all pre-existing in the target repo the beta test built on) — those belong to that repo,
    not this one. This plan's Phase 3 item is about the review-loop GATE that should have caught them,
    not the bugs themselves.
goal: >
  Work through all 9 findings in GH-268's beta test report (2 blocking, 4 fix-before-broader-beta,
  2 follow-up, 1 untested-needs-retest) in 4 sequenced phases, ending with a re-test of the
  cross-model (Codex/agy) lane now that its blocker (#232) is closed.
---

# GH-268 · Beta onboarding & build-quality test report — remediation plan

## Status
| What was just completed | What's next |
|---|---|
| Plan drafted 2026-07-22 from a full read of [#268](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/268)'s report (Matthew Taylor, beta tester; compiled 2026-07-20). Cross-checked current repo state: 9 of 17 skills still lack `install.sh` (report said "8 of 13" on 2026-07-20 — the skill count has grown since); #123 is CLOSED; #232 (the cross-model retest's stated blocker) is now CLOSED via PR #271 (merge `2a2da17`), so Phase 4 is unblocked. | QA this plan via `/relay-xyz` with Agy as reviewer, then fire Phase 1 (the two tester-blocking items) through the marathon pipeline. |

## Table of contents
- [Phase 1 — Unblock a new tester (blocking)](#phase-1--unblock-a-new-tester-blocking)
- [Phase 2 — Onboarding polish before broader beta](#phase-2--onboarding-polish-before-broader-beta)
- [Phase 3 — Review-loop scope gap (follow-up)](#phase-3--review-loop-scope-gap-follow-up)
- [Phase 4 — Cross-model re-test (now unblocked)](#phase-4--cross-model-re-test-now-unblocked)
- [Deferred / out of scope](#deferred--out-of-scope)

---

## Phase 1 — Unblock a new tester (blocking)

**Goal:** a first-run Quickstart ends green on a genuinely clean clone, and every named onboarding
skill has a working installer — the report's 2 "Blocking for a new tester" items, closed.

### Checklist
- [ ] **Quickstart (`validate.sh`) passes on a clean machine.** The report's "prove it works, ~1
      minute" step took ~10 minutes and ended with 7 failed tests, reproduced on a **fresh macOS
      clone**, not just Ubuntu CI — meaning it depends on state on the author's machine, not a clean
      one. *Fix:* reproduce the 7 failures on a genuinely clean clone (new tmp dir, no prior
      `xyz`/`hq` state) and either fix the state dependency or scope the Quickstart to only what needs
      no setup.
- [x] **Every skill ships an `install.sh`.** Originally confirmed 2026-07-22 (before remediation):
      `consult/`, `open-router/`, `ponytail/`, `relay-automation/`, `release/`, `skills-sync-trinity/`,
      `swe/`, `weekly-shipped/`, `xyz/` (9 of 17) had no `install.sh` — onboarding text says "install
      the `/relay-xyz` and `/consult` skills" but `consult/` had no installer, so the step only
      completed if the assistant improvised the symlink. *Fix:* add `install.sh` to each (or one
      top-level installer covering all `skills/*`) so no onboarding step depends on assistant
      improvisation.
      **Done 2026-07-22** on `marathon/gh-268-installers-2026-07-22` (not yet merged): all 9 now mirror
      `skills/relay-xyz/install.sh` byte-for-byte except `SKILL_NAME`, mode 755, functionally verified
      (fresh install, idempotent re-run, real-file-collision refusal all exercised manually). Built via
      marathon (2 files by an aider+qwen3.8-max trial that landed cleanly first try — see #279/#280 for
      that trial's reliability issues on the other 7; remaining 7 built by codex+agy, 0 failures).

### Phase 1 — QA checklist
- [ ] Every todo above produced its checkable output (no orphan tasks): clean-clone `validate.sh` result, and `skills/consult/install.sh` present.
- [ ] Tests written **and run** — `bash validate.sh` executed against a genuinely clean clone (fresh `git clone`, fresh `$TMPDIR`, no inherited `xyz`/`hq` state), output attached/quoted here, not asserted.
- [ ] Diagnosable: if the 7 failures don't fully resolve, each remaining one names its own repro command and log location — no "some tests are flaky" hand-wave.
- [ ] Blast: undo-class Easy (revert the installer/doc commits); shield = none needed (additive only); tripwire = none needed (no one-way step in this phase).
- [ ] Status table and `updated:` date refreshed before this phase is marked done.

---

## Phase 2 — Onboarding polish before broader beta

**Goal:** the README and `relay-automation/README.md` lead with what-it-is/Quickstart/prerequisites
in the right order, and the Quickstart's sandbox-hang failure mode is caught and messaged instead of
silently burning ~5 minutes — the report's 4 "fix before broader beta" items, closed.

### Checklist
- [ ] **README leads with logistics, not "what it is / try it."** `README:~115` ("what XYZ is") and
      `README:~130` (Quickstart) currently sit well below beta logistics and the mode taxonomy.
      *Fix:* name + one-line "what it is" + Quickstart at the top (standard per
      https://www.makeareadme.com/).
- [ ] **CLI prerequisites appear after the fast path that needs them.** The "fast path — just this
      repo" section (`README:~79`) precedes the requirement to install/auth the Codex + agy CLIs
      (`README:~68` and below). *Fix:* state CLI prerequisites inside or above the fast path, matching
      #123's own "Initial Steps" ordering.
- [ ] **`relay-automation/README.md`'s prerequisite section is titled/worded as specialist jargon
      ("Headless bring-up") and tells the user how to *test* the CLIs, not how to *install* them.**
      *Fix:* rename to plain language (e.g. "Set up Codex and agy") and include the install links
      #123 already provides.
- [ ] **The Quickstart hangs silently under the default Claude Code Bash sandbox** (an `mktemp`-under-
      sandbox issue, ~5 minutes of zero output until sandboxing is disabled — this repo's own
      recurring gotcha, see `[[git-push-needs-sandbox-disabled]]`-class issues). *Fix:* detect the
      sandbox condition and message it, or document the un-sandboxed requirement at the Quickstart
      step itself, not only deeper in the docs.

### Phase 2 — QA checklist
- [ ] Every todo above produced its checkable output: README reorder, prereq reorder, `relay-automation/README.md` rename, sandbox-hang message — each a diffable doc/script change, no orphans.
- [ ] Tests written **and run** — no test coverage applies here (doc-only + one message string); note that explicitly rather than leaving it silently unchecked.
- [ ] Diagnosable: the sandbox-hang message names the actual condition (`mktemp` under Bash sandbox) and the fix (`dangerouslyDisableSandbox`/`/sandbox` off), not a generic "something went wrong."
- [ ] Blast: undo-class Easy (doc/text changes only); shield = none needed; tripwire = none needed.
- [ ] Status table and `updated:` date refreshed before this phase is marked done.

---

## Phase 3 — Review-loop scope gap (follow-up)

**Goal:** every relay turn boundary states the handoff cue, and the per-phase gate can run a
target-repo-native lint/security check against the file a diff lands in — not just the diff hunk —
the report's 2 "fix in a follow-up" items. The more consequential one — the review loop only checks
the diff, not the file it lands in — is the one with real teeth: an independent audit of the same
branch found 20 issues (1 critical, 4 high) in code the relay's own Producer/Reviewer loop approved
in 2 rounds, entirely because those issues lived in the pre-existing file the diff touched, not the
diff itself.

### Checklist
- [ ] **Relay handoff cue reinforcement.** All-Claude relay mode requires manually copy-pasting a
      prompt between two windows, and the Reviewer turn didn't cue the user to return to the Producer
      window. *Fix:* reinforce the "go to the other window / say take your turn" cue at every turn
      boundary; track the automatic poll-loop mode (already referenced elsewhere in this repo,
      `relay-loop.sh`/`poll.sh`) as the real fix, not just better copy.
- [ ] **Wire target-repo code checks into the per-phase gate.** The Producer/Reviewer loop reviews
      the diff, not the surrounding file — this is the actual root cause of the missed 20 issues.
      *Fix:* run the target repo's own checks in the per-phase gate the harness already supports (this
      repo already has a `--pre-advance-cmd` gate seam per GH-238/GH-249's closed docs) — for
      PHP/WordPress specifically, `php -l` + PHPCS with the WordPress-security ruleset would
      mechanically catch several of these; and consider prompting the reviewer to sweep the touched
      file, not just the diff, as a cheaper first step before full linter wiring.

### Phase 3 — QA checklist
- [ ] Every todo above produced its checkable output: handoff-cue reinforcement in the relay template, and the gate seam's target-repo-check capability, each with a worked example (PHP/PHPCS).
- [ ] Tests written **and run** — at least one relay driven end-to-end with `--pre-advance-cmd` pointed at a real lint/security command, with the pass/fail output attached.
- [ ] Diagnosable: a reviewer that skips the file-sweep step is visibly distinguishable in the transcript from one that ran it (e.g. an explicit "swept file: yes/no" line), not silently assumed.
- [ ] Blast: undo-class Easy (gate wiring is opt-in per lane via `--pre-advance-cmd`, doesn't change default behavior for lanes that don't set it); shield = the check stays advisory/gate-only, never auto-edits; tripwire = none needed (reversible, additive).
- [ ] Status table and `updated:` date refreshed before this phase is marked done.

---

## Phase 4 — Cross-model re-test (now unblocked)

**Goal:** a real cross-vendor relay (Codex or agy as Reviewer, not Claude-reviewing-Claude) round-trips
with a genuine verdict, and the result is written back into this doc — the report's 1
"untested — needs re-test" item. The headline cross-model claim never ran in the original test because
the Codex/agy CLIs weren't installed/authenticated, and the tester correctly flagged that "the failing
tests cluster around this lane's driver scripts... until #232 is closed" made setup friction likely.
#232 closed 2026-07-22 via PR #271 — this phase is now actionable, not blocked.

### Checklist
- [ ] Install and authenticate the Codex and Antigravity (`agy`) CLIs per #123's own Initial Steps.
- [ ] Run one `/consult` and one cross-vendor `/relay-xyz` (Codex or agy as Reviewer, not
      Claude-reviewing-Claude) against a small real feature, mirroring the original test's shape.
- [ ] Record the result back into this doc (pass/fail, and any new friction found) — this is a
      re-test gate, its findings must be written back before the phase can be called done, per this
      repo's own PDDA discovery-phase convention.

### Phase 4 — QA checklist
- [ ] Every todo above produced its checkable output: authenticated CLIs, a completed cross-vendor relay round-trip, and findings written back — no orphan tasks.
- [ ] Tests written **and run** — the actual `/relay-xyz` + `/consult` transcripts are the execution artifact; a claimed "it worked" with no transcript reference doesn't close this phase.
- [ ] Diagnosable: any new friction found is written back here with the exact failing command/exit code, not summarized as "some issues."
- [ ] Blast: undo-class Easy (a re-test produces no lasting repo change beyond this doc's own findings entry); shield = none needed; tripwire = none needed.
- [ ] Status table and `updated:` date refreshed before this phase is marked done.

---

## Deferred / out of scope

- The 20 issues (1 critical, 4 high) the independent audit found in the target WooCommerce plugin
  itself — those are bugs in that repo, not this one. Phase 3 addresses the *gate* that should have
  caught them, not the bugs.
- Any new GH issue per finding — deliberately not done; this doc is the single point of reference,
  per the operator's explicit instruction.

## Swarm Preflight Contract

Scoped to Phase 1 only (the two blocking items) — Phases 2-4 need their own contract redraft once
Phase 1 ships, since their artifacts differ (README/doc files, then the gate-wiring script, then a
manual re-test with no code artifact at all).

```json
{
  "target": { "repo": ".", "ref": "development" },
  "gate": "bash validate.sh",
  "fix_probes": [
    { "type": "path_absent", "path": "skills/consult/install.sh" }
  ],
  "artifacts": [ "skills/consult/install.sh", "validate.sh" ],
  "artifacts_new": [ "skills/consult/install.sh" ],
  "remediation": {
    "source": "issue#268",
    "criteria": "Phase 1 only: the Quickstart (validate.sh) is green on a genuinely clean clone (or its scope is reduced and documented), and skills/consult/install.sh exists (minimum bar from the report; ideally all 9 gap skills get one)."
  },
  "lanes": { "agy_safe": [ "skills/consult/install.sh" ], "orchestrator_only": [ "validate.sh" ] }
}
```
