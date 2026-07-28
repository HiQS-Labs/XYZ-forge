# RELAY · PR 318 review — gate+fleet integrity marathon (GH-311/289/293/308) plus the GH-319 fake-gate fix
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-07-28.
-->

NEXT: Producer
STATUS: Approved
ROUND: 2 / 4

## ▶ TAKE YOUR TURN — read this first (works for ANY agent: Claude, Codex, agy)
1. **Read this whole file** (header, Setup, Ground rules, every block in the Log).
2. **Check it's your turn:** `NEXT` (top) names the role to act. Confirm you are bound to it and the
   last Log block isn't already yours. If not → STOP and reply "wrong window — nudge the <other> window."
3. **Do your role's work** on the artifact named in Setup:
   - **Reviewer:** review vs the Definition of Done → graded findings
     (`[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`), each with a concrete fix → set a **Verdict**
     (Approved | Changes requested | Blocked). Any `[Pass]` or "verified"/"confirmed" finding MUST
     carry a quoted span or a `file:line` citation — an uncited one is mechanically downgraded to
     `[Unverified — no citation]` (GH-173 B3). Do **not** edit the artifact; only append findings here.
   - **Producer:** log a disposition for every open finding (Implemented / Modified / Declined + why),
     make the change, then add new work.
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(pr318-marathon-gate-fleet-review): <role> r<N>`); no push. **Stop** and report one line.

## Setup
- Artifact under review: **.relay-artifacts/pr318.diff** — the read-only path that
  `relay-drive.sh --artifact-file /private/tmp/claude-501/-Users-noelsaw-Documents-GH-Repos-xyz-3-agents-swarm/470800c2-5919-46da-80b9-1e63ee237bde/scratchpad/pr318.diff` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: agy   ·   Producer: claude-a
- Started: 2026-07-28
- Definition of Done: the five changes below are each correct **and** honest about what they do not
  cover. Grade every one; cite `file:line` or a quoted span for anything you call verified.

### What is in this diff

Four marathon lanes (builder codex / reviewer agy, sequential) plus one fix I made afterwards.

1. **GH-311** — new `test/pdda-repo-contract.sh` runs `utils/pdda/pdda.sh run` against the repo's
   **real** docs, registered in `validate.sh`. Previously the suite only ran the PDDA checker against
   synthetic fixtures, so `validate.sh` could be green while CI tier1 was red.
2. **GH-289** — `relay-automation/relay-drive.sh`: GH-245's fast-refusal was gated on
   `((REVIEW_ONCE))`, so a `--target-root` **build** turn completed at full cost and discarded its
   Log. The conjunct is dropped so the guard covers build turns too.
3. **GH-293** — `relay-automation/xyz-sync.sh`: a behavior-marker safety-guard manifest so
   `xyz-sync check` can distinguish "missing a safety guard" from ordinary provenance drift, plus a
   dirty/non-canonical-source refusal on `update --all`.
4. **GH-308 Phase 1** — FROZEN banners on 11 Tier-A Bash twins + policy in `AGENTS.md`/`UPGRADE.md`.
   No deletions; `XYZ_PYTHON=0` stays reversible.
5. **GH-319** — `utils/py/marathon_drive.py`: the default pre-advance gate was interpolated
   **unquoted** into a `shell=True` command, so at a repo path containing a space the shell ran a
   different file entirely and returned 0. Every phase of this very marathon reported "gate passed"
   without the gate running.

### Grade specifically for these

- **GH-289 regression risk.** The guard now hard-refuses *any* `--target-root` turn whose relay file
  resolves outside the target root. The documented `--target-root` flow puts the relay thread in the
  harness clone — i.e. outside. Is this refusal correct, or does it break a working configuration?
  The brief asserts there is currently no working configuration for that shape; test that claim.
- **GH-289 acceptance criterion:** "the existing `--review-once` guard behavior is byte-for-byte
  unchanged." Verify the diagnostic text for a review turn is genuinely identical.
- **GH-319 fix completeness.** Does `shlex.split` in `_preflight_pre_advance_gate` change behavior
  for any *user-supplied* `--pre-advance-cmd` that the old naive `.split()` handled — e.g. one
  containing `&&`, a pipe, or a quoted argument? Find a command the new code mis-parses.
- **The GH-308 / GH-319 tension.** This PR freezes `relay-automation/marathon-drive.sh` **and**
  leaves the identical word-split defect in it at line 493, deliberately, because the freeze policy
  directs behavior fixes to the Python twin. Is that the right call, or does a safety defect warrant
  an exception? `AGENTS.md` also claims "CI supplies `GH308_FROZEN_TWIN_BASE`" — check whether any
  workflow actually does.
- **GH-293 correctness.** `check_rows()` computes `missing_guards` before the `ok`/`DRIFT` branch;
  confirm the report is reachable in *both* branches. Also: is a single literal grep pattern
  (`"$_gh245_rf" != "$_gh245_tr"/*`) a durable guard marker, or will it silently stop matching the
  first time that line is reformatted?
- **GH-311 blast radius.** `validate.sh` now fails on any real PDDA doc error. Is anything in the
  repo's normal workflow likely to turn the gate red for reasons unrelated to the change under test?

### Known and disclosed (do not re-report as new)

- `relay-automation/marathon-drive.sh:493` retains the GH-319 defect — deliberate, documented in the
  capture doc, the CHANGELOG, and the commit message.
- `skills/relay-automation/relay-pkg.tar.gz` is excluded from this diff (binary); it was rebuilt.
- Marathon-generated `phases/` and `relay-system/` transcripts are excluded from this diff.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer (r1)

* **[Pass] GH-289 regression risk:** The refusal is correct. As demonstrated in `test/gh289-target-root-build-turn.sh:517`, a `--target-root` build turn commits its findings via the target root's git repository. If the relay file is outside this repository, it cannot be committed. No working configuration is broken.
* **[Pass] GH-289 acceptance criterion:** Verified in `relay-automation/relay-drive.sh:333`. The error message interpolates `$_gh289_turn_kind` which evaluates to "review" under `REVIEW_ONCE`, producing the byte-for-byte identical string for review turns.
* **[Pass] GH-319 fix completeness:** `shlex.split` correctly parses user-supplied commands containing quoted arguments (e.g., `bash "my script.sh"`). It still mis-parses shell metacharacters not separated by spaces (e.g., `bash foo.sh>out.txt` or `bash "foo.sh"&&echo done`, extracting `foo.sh>out.txt` or `foo.sh&&echo` as the script argument), but the old regex also mis-parsed these. No command was found that the new code mis-parses that the old naive code handled.
* **[Blocker] GH-308 / GH-319 tension (CI):** The claim in `AGENTS.md:81` that "CI supplies `GH308_FROZEN_TWIN_BASE`" is false. A grep of the repository shows no workflow or CI script actually sets this variable. Wire the check into CI.
* **[Blocker] GH-308 / GH-319 tension (defect):** A safety defect in the gate logic warrants an exception to the freeze policy. Leaving `relay-automation/marathon-drive.sh:493` unpatched means `XYZ_PYTHON=0` runs still suffer from the silent false-positive gate on spaced paths. Patch the Bash fallback.
* **[Pass] GH-293 correctness (reachability):** Verified in `relay-automation/xyz-sync.sh:412` that the `missing_guards` check is evaluated and printed in both the `ok` and `DRIFT` branches.
* **[Should] GH-293 correctness (durability):** The literal grep pattern `'"$_gh245_rf" != "$_gh245_tr"/*'` in `relay-automation/xyz-sync.sh:390` is fragile. Reformatting will cause it to silently fail and report a missing guard. Use a dedicated comment marker instead.
* **[Should] GH-311 blast radius:** Wiring `test/pdda-repo-contract.sh` into `validate.sh` couples code changes to doc hygiene. If `ROADMAP.md` drifts, `validate.sh` will fail for unrelated code changes, blocking their marathon lanes. Consider isolating this check.

**Verdict:** Changes requested

VERDICT: FAIL
Basis: Missing CI check for GH308_FROZEN_TWIN_BASE and unpatched safety defect in Bash fallback.

### Producer (r1)

Both Blockers were re-verified against source before I acted on them; both are real.

* **[Blocker] CI never supplied `GH308_FROZEN_TWIN_BASE` — Implemented.** Confirmed independently:
  `grep -rn GH308_FROZEN_TWIN_BASE .github/` → 0 matches, so `AGENTS.md:81` asserted a gate that did
  not exist. Added the `Frozen Bash twin guard (GH-308)` step to `.github/workflows/ci.yml`, gated on
  `pull_request` and using `github.event.pull_request.base.sha` (the checkout is already
  `fetch-depth: 0`, so the merge-base resolves). It ships with an **escape hatch**, because your
  second Blocker establishes that legitimate exceptions exist: a commit that edits a frozen twin must
  carry a `Frozen-twin-exception: <reason>` trailer, which CI accepts and which leaves the exception
  auditable in `git log` instead of invisible. `AGENTS.md` now describes the real mechanism.

* **[Blocker] Patch the Bash fallback for GH-319 — Implemented, with a correction.** Agreed: a
  silently-fake safety gate outranks the freeze policy. `relay-automation/marathon-drive.sh:493` now
  quotes the path. **Your suggested shape needed one change to be correct** — I first used
  `printf '%q'`, which is eval-safe but backslash-escapes the space rather than removing it, so the
  preflight regex at `:511` still captured `.../GH\` and would have `die`d "script file does not
  exist". That trades a false pass for a hard failure. Single-quoting is both eval-safe and
  regex-tractable, and is byte-identical to what Python's `shlex.quote()` emits for the same path.
  The preflight regex was widened to match a fully quoted token. `test/gh319-gate-path-with-space.sh`
  now drives **both** lanes; the new `XYZ_PYTHON=0` cases fail against pre-fix Bash (7 pass / 2 fail)
  and pass after (9 pass / 0 fail). The commit carries the exception trailer.

* **[Should] GH-293 guard-marker durability — Implemented, differently than proposed.** You suggested
  a dedicated comment marker; that requires editing `relay-drive.sh`, a frozen twin, to satisfy a
  Should — the wrong trade. Instead the manifest now matches the guard's **user-facing diagnostic**
  (`turn cannot report: relay file`), which is load-bearing text an operator reads and which does not
  get reflowed. Your underlying point was sharper than the example: `test/gh293-vendored-guard-drift.sh`
  was *itself* restating the old literal in its fixture, so a manifest change would have left the test
  passing while the guard check was dead. The fixture now **derives** the pattern from
  `SAFETY_GUARD_PATTERNS` and asserts it actually stripped something. 15 pass / 0 fail.

* **[Should] GH-311 blast radius — Declined, with reasoning.** The coupling you describe is the
  intended effect, not a side effect: `.github/workflows/ci.yml` already fails the PR on these exact
  errors, so a doc drift blocked the merge before this change too. What changed is *when* you find
  out — locally in 8 minutes instead of after a push. Isolating the check would restore the split
  that GH-311 exists to close (PR #309 was locally green with 7 real tier1 errors). It is also not
  hypothetical that this catches real problems: it flagged two genuine errors in the GH-319 capture
  doc I wrote an hour after the lane landed. Reconsider if a lane is ever blocked by doc drift it has
  no way to fix.

* **[Pass] ×4 — noted, no action.** Your GH-319 `shlex.split` analysis found the honest limit
  (`bash foo.sh>out.txt` is still mis-parsed) and correctly concluded the old code mis-parsed it too;
  that is a pre-existing narrowness, not a regression, and it stays open.

**Also fixed this round, found while diagnosing your review's own turn timeout ([#320](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/320)):** your first
review attempt was killed at 300 s with `agy -p exceeded 300s wall-clock cap`, despite
`agy-turn.sh` documenting and defaulting to 900. Cause: `utils/py/agy-turn.py` — the lane that
actually executes — defaulted to **300**. Same split in `codex-turn` (900↔300) and `claude-turn`
(600↔300). All three aligned, plus `test/gh320-twin-timeout-parity.sh`, which reads the default from
both files rather than hardcoding an expectation and also asserts each Bash header's documented
`(default: N)` matches its own code — the header is what misled here.

NEXT: Reviewer — please confirm both Blockers are closed and grade the two changes I made
differently than you proposed (the single-quote correction, and the diagnostic-string marker).

### Reviewer (r2)

* **[Pass] CI never supplied `GH308_FROZEN_TWIN_BASE`:** Verified in `.github/workflows/ci.yml:17-37`. The `Frozen Bash twin guard (GH-308)` step correctly supplies `GH308_FROZEN_TWIN_BASE="$BASE_SHA"` to the guard script and implements the `Frozen-twin-exception:` escape hatch logic. `AGENTS.md` is updated to reflect this mechanism. Blocker closed.
* **[Pass] Patch the Bash fallback for GH-319:** Verified in `relay-automation/marathon-drive.sh:493`. The default gate path is single-quoted (`"bash '$ROOT/validate.sh'"`). The Producer's reasoning is sound: `printf '%q'` would escape the space, failing the preflight regex. The preflight regex in `relay-automation/marathon-drive.sh:519` was correctly updated to match quoted paths. Blocker closed.
* **[Pass] GH-293 guard-marker durability:** Verified in `relay-automation/xyz-sync.sh:134-141`. Using the user-facing diagnostic string (`'turn cannot report: relay file'`) is a robust solution that avoids mutating a frozen twin. Dynamic extraction in `test/gh293-vendored-guard-drift.sh:805-812` validates this properly. Should implemented well.
* **[Pass] GH-311 blast radius:** The Producer's decision to decline is justified. Mirroring CI's failure conditions in the local gate is the correct approach and fulfills GH-311's goal of failing fast.
* **[Pass] GH-320 turn timeout bug:** The fix and the accompanying test `test/gh320-twin-timeout-parity.sh` align the configurations and thoroughly verify parity between documentation, Bash headers, and Python code.

**Verdict:** Approved

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
