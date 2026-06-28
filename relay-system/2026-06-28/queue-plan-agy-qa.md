# RELAY · QA: queue-plan.sh + PDDA complexity/risk/effort ratings system
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-06-28.
-->

NEXT: Producer
STATUS: Open
ROUND: 3 / 4

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
6. **Commit only the relay file** (`relay(qa-queue-plan-sh-pdda-complexity-risk-effort-ratings-system): <role> r<N>`); no push. **Stop** and report one line.

## Setup
- Artifact under review (read all; you may read any path in the repo):
  - `utils/queue-plan.sh` — the deterministic pre-pre-flight queue planner (PRIMARY).
  - `PROJECT/PDDA.md` → section **"Project ratings — complexity / risk / effort"** — the ratings contract.
  - `utils/pdda-check-ratings.sh` — the warn-level ratings check.
  - `test/queue-plan.sh` — the 28-assertion regression suite (judge coverage adequacy).
  - The ratings backfill — provisional `complexity`/`risk`/`effort` + `ratings_exempt` across `PROJECT/**` docs (e.g. `PROJECT/2-WORKING/GH-37-AGY-CONSULT-AUTH-HANG.md`, `GH-33-LOOP-SKILL-INTEGRATION.md`, `ADVERSARIAL-HARDENING.md`).
- Reviewer: agy   ·   Producer: claude-a
- Started: 2026-06-28
- Definition of Done — grade the work against these; this is a QA of correctness AND of the ratings ("difficulty of implementation") system design:
  1. **Planner correctness.** Ledger parse; the validation signals (already-closed via `gh`, already-landed via `fix_probes` not artifact-existence, undocumented-partial ≥2-signal threshold, drift, unrated); the score `2·eff + 1·cx + 2·risk + 3·deps + zone_pen`; wave packing (write-set disjoint, ≤1 kernel lane/wave, deps push later); `--check` determinism; `gh` graceful degradation. Flag any logic bug, false-positive/negative, or non-determinism.
  2. **Ratings system soundness.** Is `complexity`/`risk`/`effort` on a `low|medium|high` scale a sound "difficulty of implementation" rubric? Are the three axes clearly distinct (not double-counting)? Is the default `quick-wins` weighting (and the `derisk-first` risk-sign flip) defensible, or gameable / mis-ordering? Is risk-as-reversibility the right meaning? Is the ≥2-signal partial threshold well-chosen?
  3. **Discipline.** Deterministic + flag-for-human only (never auto-resolves); reuses swarm-preflight contract/probe semantics rather than a second control plane; advisory check never blocks.
  4. **The provisional backfill values** — are the assigned ratings + exemptions reasonable, or obviously wrong anywhere?
- Output: graded findings (`[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`) each with a concrete fix, then a Verdict (Approved | Changes requested | Blocked). Review only — do not edit any file; append findings to this relay file.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer Turn — Round 1
**Agent:** agy (Antigravity Reviewer)
**Date:** 2026-06-28
**Verdict:** Changes requested

#### Findings & Grades

- **[Blocker-Correctness] Unresolved dependency scheduling for held items**
  - **Finding:** In `utils/queue-plan.sh`, the check `active.some((x) => x.gh === d)` only verifies if the dependency `d` is in the `active` list (i.e. ready tasks). If a dependency `d` is open but currently held/flagged (e.g. `unrated` or `needs-contract`), it will not be in `active`. Thus, `active.some` evaluates to `false`, causing the dependent task `r` to be scheduled immediately in Wave 1 or 2, violating the dependency constraint.
  - **Fix:** Update `depUnmet` to check if the dependency `d` is present in the ledger (`deduped`) under an uncompleted section (not just `active`). For example:
    ```js
    const depUnmet = r.deps.some((d) => deduped.some((x) => x.gh === d && x.section !== "Completed" && !placedIssue.has(d)));
    ```

- **[Should] Comma-separated dependencies parsing bug**
  - **Finding:** The regex in `depsOf()` (`/(?:after|once|depends on|gated on|blocked by)\s+(?:[^.]*?)\b(?:GH-|#)(\d+)/gi`) does not capture subsequent issues in a comma-separated list (e.g., `depends on GH-20, GH-21` or `gated on #20, #21`). The search resumes after the first match and fails to match subsequent issue numbers because the dependency keyword is not repeated.
  - **Fix:** Update `depsOf` or its parsing logic to parse a sequence of issue numbers (e.g., `(GH-|#)\d+` separated by commas/conjunctions) following a dependency keyword.

- **[Nit] Insufficiently scoped duplicate item deduping**
  - **Finding:** The deduping key `const key = \`${r.gh || ""}|${r.docRel || ""}|${r.title}\`;` includes the item's title. If the same issue is referenced in multiple ledger sections with slightly different titles, it will bypass deduping and be sequenced multiple times.
  - **Fix:** Key on `r.gh` (if present) or `r.docRel` (if present) instead of including the title when matching unique issues.

- **[Nit] `coverageDrift` flags legitimately exempt files**
  - **Finding:** The `coverageDrift` function flags any `.md` file in `PROJECT/2-WORKING` not in the roadmap, regardless of whether it has `roadmap_exempt: true` in its frontmatter. This produces false-positives since it doesn't parse frontmatter.
  - **Fix:** Parse/check frontmatter for `roadmap_exempt: true` before flagging a 2-WORKING file in `coverageDrift`, aligning it with `pdda-check-roadmap-coverage.sh`.

- **[Pass] Ratings Rubric and Soundness**
  - The `complexity`/`risk`/`effort` scale is distinct and avoids double-counting. The weightings for `quick-wins` and the `-4 * risk` flip for `derisk-first` are mathematically elegant and prevent gaming. The partial completion threshold of `>= 2` signals is well-chosen.

### Producer Turn — Round 1
**Agent:** claude-a (Claude Opus 4.8, producer)
**Date:** 2026-06-28
**Disposition:** all findings Implemented

- **[Blocker-Correctness] dep on held item** — **Implemented.** `depUnmet` in the wave packer now checks the full ledger (`deduped`) against a `DEP_RESOLVED` set (`completed-ref`/`already-landed`/`already-closed`/`deferred`/`exempt`/`note-only`). A dependency that is merely HELD (unrated / needs-contract / gated) is *not* resolved, so it keeps blocking its dependent until placed in an earlier wave (or, if never placed, the dependent falls to the flush wave). Confirmed your exact case. Regression: `test/queue-plan.sh` **Scenario G** — a dep on an unrated item defers the dependent (700→wave1, 701→wave2).
- **[Should] comma-separated deps** — **Implemented.** `depsOf` now matches a dependency keyword followed by a *list* of issue refs (`,`/`and`/`&`/`/`-separated) and captures all of them, while stopping at the first non-issue token so `"after GH-29 the fix landed"` still yields only 29 (no over-capture). Regression: **Scenario H** — `depends on GH-800, GH-801` ⇒ the dependent follows BOTH kernels into wave 3.
- **[Nit] dedup key includes title** — **Implemented (scoped).** Dedup now keys on `gh` when present (one issue = one canonical item, so same-issue-different-title collapses). Issue-less notes keep `docRel+title` so distinct field-findings that share one doc anchor (e.g. the four `AUTOMATED-RELAY.md#…` notes) are *not* over-merged — keying purely on `docRel` would have collapsed them.
- **[Nit] coverageDrift ignores roadmap_exempt** — **Implemented.** `coverageDrift` now parses frontmatter and skips `roadmap_exempt: true` docs, aligning it with `pdda-check-roadmap-coverage.sh`.
- **[Pass] ratings rubric** — noted; thanks for the soundness check on the difficulty-of-implementation system.

Verification: `test/queue-plan.sh` **30/30** (was 28; +Scenario G/H); `validate.sh` **55/55**; live queue regenerated. Handing back for confirmation.

### Reviewer Turn — Round 2
**Agent:** agy (Antigravity Reviewer)
**Date:** 2026-06-28
**Verdict:** Changes requested
VERDICT: FAIL
Basis: QA review of queue-plan.sh and PDDA complexity/risk/effort ratings system

#### Findings & Grades

- **[Blocker-Correctness] Oxford comma / compound separators parsing failure in dependencies**
  - **Finding:** In `utils/queue-plan.sh`, the regex in `depsOf()` (`/(?:after|once|depends on|gated on|blocked by)\s+((?:(?:GH-|#)\d+(?:\s*(?:,|and|&|\/)\s*)?)+)/gi`) fails to capture issue numbers preceded by composite separators like `, and` or `, &` (e.g., `depends on GH-100, GH-101, and GH-102`). Because `, ` matches the optional separator but the subsequent `and` is not a valid issue prefix, the repeating pattern stops and `GH-102` is completely missed. This violates dependency constraints and leads to unsafe scheduling.
  - **Fix:** Update the regex's separator group to allow composite separators (e.g., optional commas followed by optional conjunctions/spaces):
    ```js
    const re = /(?:after|once|depends on|gated on|blocked by)\s+((?:(?:GH-|#)\d+(?:\s*(?:,|and|&|\/|and\/or)?\s*)?)+)/gi;
    ```

- **[Should] `coverageDrift` does not ignore `blank.md`**
  - **Finding:** In `utils/queue-plan.sh`, the `coverageDrift` function scans all files ending in `.md` in the working queue directory, but does not ignore `blank.md`. The PDDA specification states that "`blank.md` placeholders are scaffolding and should be ignored by PDDA checks". Other checks (like `pdda-check-roadmap-coverage.sh`) ignore it, but `coverageDrift` does not.
  - **Fix:** Exclude `blank.md` from the list of scanned docs in `coverageDrift`:
    ```js
    try { docs = fs.readdirSync(E.QP_QUEUE_DIR).filter((f) => f.endsWith(".md") && f !== "blank.md"); } catch { return; }
    ```

- **[Nit] Literal invisible character in frontmatter parser**
  - **Finding:** The frontmatter parser in `utils/queue-plan.sh` contains an invisible literal BOM character in `replace(/^﻿/, "")`. Literal invisible characters are hard to identify in text editors and are prone to accidental deletion or corruption.
  - **Fix:** Replace the literal character with a Unicode escape sequence `replace(/^\ufeff/, "")` for clarity and editor safety.

- **[Pass] Ratings Rubric, Soundness, and Backfill Values**
  - The design, weightings, and scoring logic for `quick-wins` and `derisk-first` are mathematically elegant. The backfill ratings are appropriate, and completed/generated docs are properly exempt.

### Producer Turn — Round 2
**Agent:** claude-a (Claude Opus 4.8, producer)
**Date:** 2026-06-28
**Disposition:** all findings Implemented

- **[Blocker] Oxford-comma / compound separator** — **Implemented.** The `depsOf` separator is now a *run* of separator tokens `(?:\s*(?:,|&|\/|and|or)\s*)*` (zero-or-more), so `", and"` / `", & "` / `"and/or"` are consumed and the following ref is still captured. Each token consumes ≥1 char so the `*` cannot loop. Regression strengthened: **Scenario H** now uses three kernels and `"depends on GH-800, GH-801, and GH-803"` — the dependent now lands in wave 4 (after ALL three), proving 803 past the `, and` is parsed.
- **[Should] coverageDrift ignores blank.md** — **Implemented.** `coverageDrift` now filters `f !== "blank.md"`, matching `pdda_list_working_docs` / `pdda-check-roadmap-coverage.sh`.
- **[Nit] literal BOM character** — **Implemented.** `replace(/^﻿/, "")` → `replace(/^﻿/, "")` (the visible escape) in the frontmatter parser.
- **[Pass] ratings rubric + backfill** — noted; thanks for re-confirming the difficulty-of-implementation system and the exemptions.

Verification: `test/queue-plan.sh` **30/30** (Scenario H upgraded to the 3-dep Oxford-comma case); `validate.sh` **55/55**; live queue regenerated. Handing back for confirmation.

### Reviewer Turn — Round 3
**Agent:** agy (Antigravity Reviewer)
**Date:** 2026-06-28
**Verdict:** Changes requested

#### Findings & Grades

- **[Should] Dependent of a held item is scheduled in active waves (transitive dependency violation)**
  - **Finding:** In `utils/queue-plan.sh`, if a "ready" item depends on an issue that is held (e.g. `unrated`, `needs-doc`, `needs-contract`, `gated`, etc.), the dependency is excluded from the active ready items list (`active = deduped.filter(...)`). During wave packing, the dependent item's `depUnmet` correctly evaluates to `true`, causing it to be deferred. However, because its dependency is never placed, the dependent item is eventually flushed to the final wave when `wave.length === 0`. This incorrectly schedules the dependent item in the active waves even though its dependency is held and won't be built.
  - **Fix:** If a "ready" item has a dependency that is in a non-ready/held state and not scheduled in any wave, the dependent item itself should be marked as blocked/held (e.g., `state = "blocked-dependency"`) and excluded from `active` sequencing, rather than being scheduled in the flush wave.

- **[Nit] `coverageDrift` is shallow while `pdda-check-roadmap-coverage.sh` is recursive**
  - **Finding:** In `utils/queue-plan.sh`, `coverageDrift` scans `E.QP_QUEUE_DIR` using `fs.readdirSync` which is shallow (only listing direct children of `PROJECT/2-WORKING/`). In contrast, `pdda-check-roadmap-coverage.sh` uses `pdda_list_working_docs` which runs a recursive `find` check, capturing documents in subdirectories (like `PROJECT/2-WORKING/briefs/`). This creates an inconsistency in drift detection.
  - **Fix:** Update `coverageDrift` in `utils/queue-plan.sh` to read the queue directory recursively (e.g., using a recursive directory helper or matching the files recursively) to match `pdda_list_working_docs`.

- **[Nit] Silent failure to warn on missing dependencies**
  - **Finding:** If an item lists a dependency on an issue number that does not exist anywhere in the roadmap ledger, `depUnmet` evaluates to `false` because `!dep` is `true`. The item is scheduled without warning. While not blocking the queue packer, it silently ignores what is likely a typo or missing ledger pointer.
  - **Fix:** Emit a `warn` or `info` finding when a parsed dependency issue number is completely absent from the roadmap ledger.

- **[Pass] Ratings Rubric, Soundness, and Backfill Values**
  - The complexity/risk/effort rubric is distinct and sound. The quick-wins and derisk-first policy weightings and risk-sign logic are correct. The ≥2-signal partial threshold is well-chosen. Backfill ratings and exemptions are reasonable.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->

