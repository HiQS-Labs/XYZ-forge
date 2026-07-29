---
gh_issue: 268
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/268
title: "Beta onboarding & build-quality test report — remediation plan (re: #123)"
status: "Phases 3 and 4 SHIPPED 2026-07-28 (items 7, 8, 9). Phases 1-2 (onboarding) still open. The cross-model re-test RAN and returned 6 real findings across two vendors with ZERO overlap — written back below."
created: 2026-07-22
updated: 2026-07-28
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

### Phase 3 — as shipped, 2026-07-28

- [x] **Relay handoff cue** — step 7 of the turn template, in **both** paths a repo can meet a relay
      through (`relay-automation/new-relay.sh` and the marathon template in
      `utils/py/marathon_drive.py`) and in **both** turn blocks. The report's complaint was that the
      *Reviewer* turn failed to cue, so a builder-only fix would have missed the reported case.
- [x] **Target-repo checks wired into the gate** — `relay-automation/target-checks.sh` detects and
      runs a foreign repo's own checks (`php -l`, phpcs incl. the WordPress ruleset by name when a
      wpcs dep is present, npm lint/test, pytest, ruff, make test, validate.sh).
      `utils/py/marathon_drive.py` uses it automatically when `--target-root` is set, no explicit
      `--pre-advance-cmd` was given, and the target has no `validate.sh` — the case that previously
      died "pre-advance gate not runnable" (GH-238) and left a cross-repo lane **with no gate at all**.
- [x] **Reviewer file-sweep prompt** — pre-existing defects in a touched file are declared IN SCOPE,
      and the reviewer must emit a literal `swept file: yes|no` line. This is the checklist's
      "diagnosable" requirement: a prompt to look harder is unfalsifiable, a required declaration is
      not.
- [x] **Tests run** — `test/gh268-relay-cue-and-target-checks.sh`, 34 pass / 0 fail; observed
      **1 pass / 18 fail** against pre-change code.

**Honest limit, and it matters:** `php -l` catches parse errors only. PHPCS-WordPress may flag raw
input, nonce, sanitization and SQL patterns, but **cannot** establish that a shortcode writing order
records requires a capability check, and cannot prove refund behaviour. **Neither of the report's two
named defects is mechanically guaranteed by this gate.** The report's "would mechanically catch
several of these" is true of *several*, not of the critical two. Stated here rather than left to be
inferred.

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

### Phase 4 — RESULT, written back 2026-07-28

**The re-test ran.** Both CLIs live and authenticated. One Consult (Codex) and one cross-vendor
Relay (agy as Reviewer, Claude as Producer), both against the Phase 3 change itself.

**Verdict on the multi-model claim: SUPPORTED, and more strongly than expected.**

Two vendors reviewed the same 341-line diff. **Their findings did not overlap once.**

| Vendor | Found |
|---|---|
| **Codex** (Consult) | `[Blocker]` a `--target-root` that HAS its own `validate.sh` was gated on the **harness's** copy — a foreign repo verified by the wrong repo's tests. `[Blocker]` `vendor/bin/phpcs` — how WordPress plugins actually install PHPCS — was skipped as "not installed", so `php -l` alone passed the gate and the security ruleset never ran. Plus the overclaim above. |
| **agy** (Relay) | `[Blocker]` the tool-path substitution mangled any command whose tool is not the leading word (`/vendor/bin/phpfind . -name ...`). `[Blocker]` `xargs` without `-r`: **GNU runs the command once on empty input**, so `php -l` reads stdin and **hangs the lane indefinitely** — on ubuntu CI, invisible on macOS. `[Should]` `bash -c` does not inherit `pipefail`, so a failing `find` is masked by a passing `xargs`. |

Five of six were implemented. Two were declined with evidence:

- agy's `[Blocker]` that the consult-mode template tells the Producer to edit a read-only `.diff` is
  a **false positive**: `grep -n is_consult utils/py/marathon_drive.py` returns nothing, and the
  cited lines are `--artifact` (marathon-drive's *writable* source paths), not `--artifact-file`
  (relay-drive's read-only seed). Two similarly-named flags on two different scripts were conflated.
- agy's re-raise of "a skipped check still yields a green gate" was declined **as stated** — the
  blanket "exit 1 on any skip" would break the documented lenient mode. The load-bearing case is
  where nobody *chose* the gate, and there the harness already passes `--strict`.

**Friction found, with exact commands** (the checklist requires this, not a summary):

1. `agy -p exceeded 300s wall-clock cap — killed`, `relay-drive: RELAY_EXIT=7`, on a shim documenting
   **900s**. Cause: `utils/py/agy-turn.py` — the executing lane since GH-264 — defaulted to 300 while
   `relay-automation/agy-turn.sh` defaulted to 900. Filed and fixed as
   [#320](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/320); `codex-turn`
   (900↔300) and `claude-turn` (600↔300) had the same split. **A tester hitting this would read it as
   a hung model, retry, and burn another turn at the same wrong cap.**
2. The Consult emitted `consult: NO FIRSTHAND VERIFICATION CITED for: codex` — the harness's own
   citation guard firing on an answer that *did* carry `file:line` citations. Not blocking (the
   findings were real and verifiable), but the guard's heuristic is worth revisiting.

**What this says about the original test.** The tester's inference — that Claude-reviewing-Claude
"shares blind spots" and was "the likely reason 1 of 9 pre-existing defects surfaced" — is supported.
The zero-overlap result is the evidence. Note especially that the `xargs` hang is a defect this
machine's OS **cannot** surface: BSD `xargs` does not run on empty input, GNU does. A second vendor
found a CI-only failure mode on a developer machine that could never reproduce it.

**Transcripts (the execution artifact this phase requires):**
- Relay: `relay-system/2026-07-28/gh268-item9-crossvendor-retest.md` (full thread, both turns)
- Consult: run 2026-07-28, model `gpt-5.6-terra` via `relay-automation/consult.sh --models codex`;
  findings quoted verbatim in the relay thread's Definition of Done.

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

## Swarm Preflight Contract (Phase 2 only)

**Re-scoped 2026-07-23 (/10days sweep).** Phase 1's install.sh item shipped via PR #282 (merged
2026-07-22) — the contract above is stale. Phase 1's OTHER item (clean-machine `validate.sh` pass) is
still open but is investigation-shaped, not mechanical — left for a separate pass. This contract
targets Phase 2 only: the doc-only README/relay-automation-README reorder + sandbox-hang message,
which is small, mechanical, and low-risk (text/doc changes, no code paths).

```json
{
  "target": { "repo": ".", "ref": "development" },
  "gate": "bash validate.sh",
  "fix_probes": [
    { "type": "grep_present", "path": "README.md", "pattern": "## What XYZ is" }
  ],
  "artifacts": [ "README.md", "relay-automation/README.md" ],
  "remediation": {
    "source": "issue#268",
    "criteria": "Phase 2 only: README.md leads with name + one-line what-it-is + Quickstart before beta logistics/mode taxonomy; CLI prerequisites appear at-or-above the fast-path section that needs them; relay-automation/README.md's prerequisite section is renamed from 'Headless bring-up' to plain install language; the Quickstart's sandbox-hang failure mode (mktemp under Bash sandbox) is messaged/documented at the Quickstart step itself."
  },
  "lanes": { "agy_safe": [ "README.md", "relay-automation/README.md" ], "orchestrator_only": [] }
}
```
