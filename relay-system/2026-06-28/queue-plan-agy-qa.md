# RELAY · QA: queue-plan.sh + PDDA complexity/risk/effort ratings system
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-06-28.
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

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
