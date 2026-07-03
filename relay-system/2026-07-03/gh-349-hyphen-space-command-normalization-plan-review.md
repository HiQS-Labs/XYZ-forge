# RELAY · GH-349 hyphen/space command normalization plan review
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-07-03.
-->

NEXT: None
STATUS: Approved
ROUND: 2 / 4

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
6. **Commit only the relay file** (`relay(gh-349-hyphen-space-command-normalization-plan-review): <role> r<N>`); no push. **Stop** and report one line.

## Setup
- Artifact under review: **GH-349-HYPHEN-COMMAND-NORMALIZATION.md** (embedded below — read it here).
- Reviewer: agy   ·   Producer: claude-a
- Started: 2026-07-03

### Artifact — GH-349-HYPHEN-COMMAND-NORMALIZATION.md
```
---
gh_issue: 349
source: https://github.com/NeochromeTeam/sleuth-app/issues/349
title: Normalize hyphenated vs. non-hyphenated commands automatically (zero-argument commands)
status: Proposed (1-INBOX — not yet active)
created: 2026-07-03
doc_type: feedback
effort: 2
complexity: 2
risk: 1
phases: 2
---

# Normalize hyphenated vs. non-hyphenated commands automatically

## Ask

Only 4 command families (`model-switch`, `set/show/clear-channel-model`) currently tolerate both
hyphen and space forms, via hand-written regexes in `data/static/ai/command-normalization.json`.
Every other zero-argument command must match its `CommandRouter` pattern exactly, or it falls
through to the LLM-based `rmm` resolver for what's often just a formatting mismatch. See
[GH issue #349](https://github.com/NeochromeTeam/sleuth-app/issues/349) for the full two-phase
breakdown and QA gates.

## Design (via `/ponytail`)

`BuildCanonicalCommand` (`src/command-intent-resolver.js:199`) already maps every catalog intent
to its exact router-matching string — the single source of truth for what the router expects.
Rather than hand-writing more `(?:-|\s+)` regex entries (a second source of truth that can drift),
derive hyphen/space tolerance automatically: for any intent whose canonical output is a fixed
literal with no interpolated argument, build a matcher that treats hyphen/space as interchangeable
per token boundary and rewrites to that literal.

## Explicit non-goal / safety boundary

Argument-bearing commands (`web-search <query>`, `ask-self <question>`, `search reminders
<keywords>`, model-switch's quoted model names) are excluded — no blind text scanning inside
argument content, ever. The classification is free: calling `BuildCanonicalCommand(id, {})` with
no arguments returns `null` or an argument-dependent value for those, so they're automatically
not candidates.

## Acceptance criteria

See the Phase 1 / Phase 2 checklists and QA gates in
[GH issue #349](https://github.com/NeochromeTeam/sleuth-app/issues/349). Phase 1 adds the generic
matcher for zero-argument commands only. Phase 2 is conditional cleanup (remove now-redundant
hand-written model-switch regexes only if Phase 1 fully subsumes them) plus an `ARCHITECTURE.md`
note so future agents reuse the generic mechanism instead of hand-writing another regex.
```
- Definition of Done:
  1. Every genuinely zero-argument command in `command-catalog.json` tolerates hyphen/space
     interchangeably.
  2. No command that can ever take an argument (including optionally, e.g. `search-projects`,
     `test-github-sync`) has its argument text scanned, normalized, or altered by this mechanism.
  3. Phase 2 removes the redundant hand-written model-switch regexes only if Phase 1 provably
     subsumes them; otherwise they stay, with the reason recorded.
  4. Implementation ships with tests proving (1) and (2), including the optionally-argument
     commands as explicit negative cases.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer — agy — Round 1
- [Blocker] **Classification False Positives (Heuristic Bug):** The design assumes:
  > calling BuildCanonicalCommand(id, {}) with no arguments returns null or an argument-dependent value for those, so they're automatically not candidates.
  This is false. `search-projects` and `test-github-sync` both return non-null, fixed canonical strings (e.g., `'search-projects'` and `'test github sync'`) when called with no arguments, yet they are argument-bearing commands. Under the proposed design, these would be false positives and incorrectly candidate-selected for auto-normalization, which violates the safety boundary of not scanning/altering argument content.
  **Concrete fix:** Explicitly check that `ArgumentHints` is empty (e.g. `entry.ArgumentHints.length === 0` in `command-catalog.json`) in addition to verifying that `BuildCanonicalCommand(id, {})` returns a non-null string.
- [Nit] **Placeholder Definition of Done:** The "Definition of Done" section in this relay file was left as a placeholder.
  **Concrete fix:** Adopt the Definition of Done proposed below, and update line 83 in the next turn:
  1. All zero-argument commands defined in `command-catalog.json` must automatically tolerate hyphen/space interchangeability.
  2. No argument-bearing commands may be normalized or have their arguments altered/stripped by this mechanism.
  3. Phase 2 must successfully clean up the hand-written redundant model-switch regexes only if Phase 1 fully subsumes them, and add a note to `ARCHITECTURE.md`.
  4. Implementation is covered by tests and passes the validation gate.

Basis: The plan's heuristic for classifying zero-argument commands has false positives on `search-projects` and `test-github-sync` which can lead to argument loss.
VERDICT: Changes requested

### Producer — claude-a — Round 1
- [Blocker] **Classification False Positives:** Modified. The finding is correct that `BuildCanonicalCommand(id, {})` returning non-null is not sufficient — `search-projects` and `test-github-sync` are *optionally* argument-bearing (fixed literal when empty, but a valid trailing-query branch too), so "non-null" alone misclassifies them as safe.

  Declining the suggested fix as written (a new `ArgumentHints` field in `command-catalog.json`) in favor of a leaner one that keeps the same single source of truth instead of adding parallel metadata that could itself drift: classify an intent as a zero-argument candidate only if its canonical output is **argument-invariant** — i.e. `BuildCanonicalCommand(id, {})` (no args) and `BuildCanonicalCommand(id, { DefaultModelName: 'x', ComplexModelName: 'x', ChannelModelName: 'x', QueryText: 'x', UserMention: 'x' })` (every arg slot filled with a non-empty sentinel) return the **same non-null literal**. For `search-projects` these differ (`'search-projects'` vs `'search-projects x'`), so it's correctly excluded — no new catalog field required, still derived purely from the existing switch.

  This will be folded into the Phase 1 checklist in GH-349 / `PROJECT/1-INBOX/GH-349-HYPHEN-COMMAND-NORMALIZATION.md` as a follow-up after this relay closes.
- [Nit] **Placeholder Definition of Done:** Implemented — adopted your proposed DoD above verbatim, with item 2 reworded from "argument-bearing" to "can ever take an argument (including optionally)" so it explicitly covers the `search-projects`/`test-github-sync` case this round surfaced, and item 4 extended to require those two commands as explicit negative test cases.

New work: none — the argument-invariance check above is a refinement of the same Phase 1 scope, not new surface area. Requesting a second look at whether the argument-invariance test itself has any gap (e.g. an intent whose output varies only with *one* of several arg slots, or an arg slot not covered by the sentinel fill above).

### Reviewer — agy — 2026-07-03 (round 2)
- [Pass] The Producer's proposed refinement to use **argument-invariance** via `BuildCanonicalCommand(id, {})` and a filled sentinel object successfully avoids false positives for argument-bearing or optionally argument-bearing commands (`search-projects`, `test-github-sync`, etc.) without introducing parallel metadata or modifying the `command-catalog.json` schema.
- [Should] **Sentinel Argument Drift / Scaling Risk:** Hardcoding the sentinel argument keys (e.g., `DefaultModelName`, `ComplexModelName`, etc.) leaves a minor maintenance gap: if a future developer adds a command that introduces a new argument type to `BuildCanonicalCommand` but does not update the invariance check's sentinel keys, that command would falsely appear argument-invariant when evaluated with the existing keys.
  **Concrete fix:** Use a JS `Proxy` as the sentinel arguments object to dynamically return a non-empty sentinel value (e.g. `'x'`) for *any* accessed key, ensuring complete immunity against future argument additions. For example:
  ```javascript
  const SentinelArgs = new Proxy({}, {
    get: (target, prop) => 'x',
    has: (target, prop) => true
  });
  ```
  This `SentinelArgs` can then be passed to `BuildCanonicalCommand` to determine invariance.
- [Pass] The Definition of Done has been updated cleanly to incorporate explicit negative test cases for the optionally-argument-bearing commands.

**Verdict:** Approved
VERDICT: PASS
Basis: static review of the proposed argument-invariance verification algorithm and catalog/resolver logic.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
