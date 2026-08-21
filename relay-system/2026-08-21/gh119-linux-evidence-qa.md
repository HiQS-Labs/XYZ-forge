# Relay: QA Audit of Linux Bring-Up Marathon Evidence PR #119
STATUS: Partially Blocked — repro.sh reviewed (Changes Requested, scoped); awaiting 5 remaining artifact groups
NEXT: claude (Producer) — attach LINUX-SETUP.md, FIRST-RUN-FRICTION.md, findings-log.md/FINDINGS.md, marathon run-{1,2,3} transcripts+telemetry, PR-BODY.md; address R-1..R-6; then re-invoke aider (round 3/4)

<!-- relay-drive: task=RELAY-GH119-QA-AUDIT producer=claude reviewer=aider round-cap=4 -->

## Phase Brief

Perform a comprehensive QA audit of [HiQS-Suite/XYZ-forge#119](https://github.com/HiQS-Suite/XYZ-forge/pull/119) (`evidence: Linux bring-up marathon — setup guide, 3 sessions, 26 findings`).

The PR is checked out locally at `/Users/noelsaw/Documents/GH Repos/XYZ-forge-pr-119-linux-evidence`.

### Key Deliverables in PR #119 Diff Under QA

1. **Setup & Friction Docs:**
   - `evidence/LINUX-SETUP.md` & `FIRST-RUN-FRICTION.md`: Linux cold-start environment setup guide, toolchain dependencies, and documentation divergence analysis.
2. **Findings Log:**
   - `evidence/findings-log.md` & `FINDINGS.md`: Detailed catalog of 26 findings (`F-001` through `F-026`), including the #99 `agy` TTY-takeover resolution and environmental gaps.
3. **Reproducibility Script:**
   - `repro.sh`: Re-run harness to independently reproduce findings, including guarded `mktemp` handling.
4. **Marathon Transcripts & Telemetry:**
   - `evidence/marathons/run-{1,2,3}/`: Transcripts and telemetry for three unattended marathon runs covering independent, dependent, and ambiguous tasks (10/12 approved).
5. **Gate Disclosure:**
   - `evidence/PR-BODY.md`: Gate status disclosure (224/230 passing on Linux host, isolating 6 host/environment-specific failures like BSD `sed -i` vs GNU sed and quota walls).

### Objective for Reviewer (Aider -> OpenRouter -> stealth/ox-alpha)

1. Review the structure, completeness, and rigor of the evidence package in PR #119.
2. Verify if `repro.sh` and documentation adhere to XYZ repository standards (clean paths, safe subshells, absence of private credentials).
3. Evaluate the gate disclosure: are the 6 excluded test failures genuinely isolated from the evidence changes?
4. Output structured findings and assign a verdict (`Approved` / `Changes Requested`).

---

▶ TAKE YOUR TURN:
Review the deliverables described above. Append your structured review block below, and update `STATUS:` and `NEXT:`.

## Reviewer Round 1 — aider (stealth/ox-alpha)

### Turn Outcome: BLOCKED — no auditable material in context

This turn received **only this relay file**. None of the five deliverable groups listed in the Phase Brief were attached to the session, and this reviewer role reads exclusively from in-chat file contents (no direct access to the local checkout at `/Users/noelsaw/Documents/GH Repos/XYZ-forge-pr-119-linux-evidence`). To avoid polluting the audit trail with fabricated results, **no substantive findings and no verdict are issued this round.**

#### Artifacts required but absent (all of:)
1. `evidence/LINUX-SETUP.md`
2. `FIRST-RUN-FRICTION.md`
3. `evidence/findings-log.md` and/or `FINDINGS.md`
4. `repro.sh`
5. `evidence/marathons/run-{1,2,3}/` transcripts + telemetry
6. `evidence/PR-BODY.md`

#### Checks explicitly NOT performed (recorded to prevent false assurance)
- Evidence-package structure/completeness/rigor: not assessed.
- `repro.sh` conformance (clean paths, safe subshells, credential hygiene): not assessed.
- Gate disclosure isolation (224/230 passing; 6 exclusions incl. BSD `sed -i` vs GNU sed): not assessed.
- Marathon transcript/telemetry consistency (10/12 approved claim): not assessed.

#### Verdict
**Not Assessed — blocked on inputs.** Neither `Approved` nor `Changes Requested` can be honestly assigned. This blockage concerns relay inputs, not the quality of PR #119, about which no claim is made either way.

#### Clarification requests (about the brief, not the PR)
- C1: Deliverable #2 lists both `evidence/findings-log.md` and `FINDINGS.md` — are these duplicates/symlinks or distinct documents? Which is canonical?
- C2: Confirm the intended review basis is full file contents in-chat; pointers/URLs alone are insufficient for this reviewer role.

#### Requested handoff → Producer (claude)
For round 2 (of max 4), please attach the six artifact groups above to the chat (full contents preferred; large transcripts may be trimmed to sections bearing on the F-001…F-026 catalog, the gate-exclusion rationale, and the 10/12 approval tally), then re-invoke aider. No tick, git, or test/gate actions were taken this turn, per harness constraints.

— end reviewer round 1 —

## Reviewer Round 2 — aider (stealth/ox-alpha) — PARTIAL: `audit/repro.sh` only

### Scope of this round
`audit/repro.sh` was attached in-chat and is reviewed here **standalone**: (a) conformance with the brief's repo-standards criteria (clean paths, safe subshells, absence of private credentials), and (b) internal soundness of each probe's detection logic. The remaining deliverable groups are still absent, so **no overall PR verdict is issued**. Reviewer made **no edits** to the artifact; remediation items below are addressed to the producer.

### Standards conformance (brief objective #2) — PASS
- **Credentials/secrets:** none present. No API keys, tokens, hostnames, usernames, or session artifacts embedded. The hardcoded date `2026-08-18T13-25-30` in P5 is inert (see R-4) but should be derived, not transcribed.
- **Network:** none. Script explicitly refuses `npm install` and states the no-network contract; verified — no curl/wget/npm/git-fetch anywhere.
- **Paths:** fully checkout-relative (`BASH_SOURCE`-derived `HERE`/`XYZ`) plus `mktemp -d` for the probe repo; `XYZ_UNDER_TEST` override documented. `nativep()` correctly bridges MSYS/Git-Bash → native Windows node. No machine-specific absolutes.
- **Subshells/destructive ops:** guarded `mktemp` with BSD `-t` fallback; EXIT trap deletes **only** its own mktemp dir, gated on `KEEP==0` + non-empty + `-d`, after `cd /`. Writes are pinned to the throwaway repo via `TICK_REPO_ROOT`. Meets the "creates nothing outside it, deletes only what it made" contract.
- **Preconditions:** loud FATALs with actionable messages and distinct exit codes (2, 3).

### Findings on `audit/repro.sh`

- **R-1 [MEDIUM] — P3 traversal probe has a detection blind spot.** Sanitisation is inferred solely from the filename listed inside `.tick/events`. If the harness *did* resolve `../escape` outside the events dir, `readdirSync` never sees it, `ef` prints `undefined`, and the probe downgrades to "FINDING F3 [informational]" instead of flagging path traversal. Recommended fix: snapshot the file inventory of `$DEMO` (or at minimum `$DEMO` root + `.tick/events`) before/after the probe and assert no new file appeared outside the events dir.
- **R-2 [MEDIUM] — P6 "concurrent" label overstates coverage.** The 50 appends are single-process, sequential, in one node invocation with `TICK_TS` pinned. This reliably catches the deterministic variant (naive filename derivation → every write targets the same name → `renameSync` clobber → n≪50), but it does **not** exercise cross-process check-then-write interleaving, which is the harder half of a rename-race regression. Recommended fix: spawn N short-lived node processes (or backgrounded jobs) appending in the same wall-clock ms, then count survivors; or relabel the probe honestly (e.g., "same-ms burst, single-writer").
- **R-3 [LOW] — P7 does not test what its header claims.** Header/comment say "release by non-owner (stale-epoch fence)", but the probe only (a) rejects a non-owner *claim* and (b) releases by the live *owner*. A release attempt by `owner2` — the actual fence case named in the title — is never issued. Add `r3=$(node "$T" release P7 --agent owner2 ...)` and assert rejection.
- **R-4 [LOW] — P5 poison file is additive, not a corruption of the real event.** The hardcoded name `2026-08-18T13-25-30.000Z-dispatcher-created-P5.jsonl` will almost never match the just-created P5 event's actual timestamp, so the probe *adds* a second, corrupt file rather than corrupting the genuine one. Functionally equivalent for the poisoning goal, but misleading; derive the real filename via `readdirSync` and overwrite that. Cleanup correspondingly leaves the genuine P5 file behind (benign).
- **R-5 [LOW] — Brittle, inconsistent assertion style; error-as-OK false negatives.** P1/P3/P4/P7 verdict by grepping human-readable substrings (`won`, `lost`, `released`) from CLI output; P5 alone uses exit codes. Two concrete hazards: (i) any wording change in `tick` silently flips verdicts; (ii) in P1, an unrelated *error* on the second claim contains neither "won" nor anything checked, and falls into the `else → "OK: overlap rejected"` branch — a false negative. Prefer exit codes or a machine-readable output mode throughout; treat "neither expected-success nor expected-rejection marker" as its own PROBE-ERROR category.
- **R-6 [LOW] — P2 false-positive path and magic defaults.** If the created-event file cannot be located/read, `pf`/`ef` come back empty and the probe emits "FINDING F2 … priority field = " — indistinguishable from a genuine coercion finding. Guard explicitly for "event file missing" as PROBE-ERROR. Additionally the accept-set `{null, 0, 1}` for priority (and `{null, 0}` for epoch) hardcodes assumed defaults; source them from harness config or annotate why those literals are safe.
- **R-7 [INFO] — Always exits 0.** Fine for manual evidence runs; if gate automation should consume this script, exit nonzero when `warn > 0` (or add a `--ci` flag).
- **R-8 [INFO] — Silent `git init` failure.** `git init -q 2>/dev/null` gives no signal if git is absent; if `tick` requires a repo, downstream probes would fail confusingly. Fail loudly when git is missing.
- **R-9 [INFO] — Unchecked `cd`s.** `cd "$DEMO"`, `cd "$DEMO/foreign"`, and the return `cd` are unguarded; with no `set -e` a failed cd cascades silently. Cheap to guard given dirs were just created.
- **R-10 [INFO] — Positives worth recording for the final report.** Probe↔finding traceability (P1–P7 ↔ F1–F6/BUG-1) is documented in-header; summary tally distinguishes confirmed-OK vs findings vs informational; `--keep` aids maintainer forensics; the BUG-1 note correctly scopes the result to whatever tree `XYZ_UNDER_TEST` points at.

### Scoped verdict
- **`audit/repro.sh`: Changes Requested (scoped).** Hygiene/standards conform; R-1 and R-2 materially weaken two probes' evidentiary value and should be fixed before the script is cited as independent reproduction; R-3/R-5/R-6 are correctness-of-reporting fixes.
- **Overall PR #119 verdict: Not Assessed** — objectives #1 (package structure/rigor) and #3 (gate-disclosure isolation of the 6 excluded failures) remain blocked pending artifacts.

### Still required from Producer (claude) for round 3
1. `evidence/LINUX-SETUP.md`
2. `FIRST-RUN-FRICTION.md`
3. `evidence/findings-log.md` and/or `FINDINGS.md` (C1 still open — identify canonical)
4. `evidence/marathons/run-{1,2,3}/` transcripts + telemetry (excerpts sufficient where they bear on F-001…F-026 and the 10/12 tally)
5. `evidence/PR-BODY.md` (gate disclosure + exclusion rationale for the 6 failures)

Apply R-1…R-6 in a producer fix round (or fold into the next push) and re-invoke aider. No tick, git, or test/gate actions were taken this round, per harness constraints.

— end reviewer round 2 —
