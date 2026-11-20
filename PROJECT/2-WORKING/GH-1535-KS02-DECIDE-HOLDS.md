---
title: "GH-1535 (KS-02): Operator decision releases decide holds; body/label holds across all issue types"
status: active
created: 2026-11-20
updated: 2026-11-20
owner: noelsaw1
goal: "Update build_queue.py and kickstart/SKILL.md so --owner Operator decision comments release decide holds (proceed or close bucket, never rule 9), and status:held labels, HELD: markers, and Blocked by #N / after #N body holds are enforced across all issue types"
gh_issue: 1535
roadmap_id: rmi-01M7VZEFJCGEV7EC8NKCJH5FEK
---

# GH-1535 (KS-02): Operator decision releases decide holds & body/label holds across all issue types

## Status

| What was just completed | What's next |
|---|---|
| Created fresh full clone off `origin/development`, installed hooks, admitted `rmi-01M7VZEFJCGEV7EC8NKCJH5FEK`, completed recon of `build_queue.py`, `#1535`, `#1518`, `#1400` OL-10, and `TESTS-RESULTS/2026-11-19+GH-1527/inputs/issues.json` | Obtain Codex Plan QA approval, rebase onto latest `origin/development` (after KS-15/KS-03 land), implement KS-02 in `build_queue.py` + `kickstart/SKILL.md`, run paired manual checks, Final QA, PR, and land |

## Goal & Scope (refs #1535, #1541 v5 KS-02 + U15 + KS-11c)
Fix two queueing defects in `skills/1-hourly/kickstart/scripts/build_queue.py` and mirror the updated closed rule list in `skills/1-hourly/kickstart/SKILL.md`:

1. **Fetch issue comments in the existing single `gh issue list` call:**
   - Extend live `gh issue list --json` fields to `number,title,labels,body,createdAt,comments` (no N+1 API calls; read-only).
   - Replay `--issues-json` accepts inputs with or without a `comments` key (defaults to `[]`), maintaining full backward compatibility with `TESTS-RESULTS/2026-11-19+GH-1527/inputs/issues.json`.
2. **Owner-authored operator decision parsing (`operator_decision(issue, owner)` — KS-02 & KS-11c):**
   - Scan `issue.get("comments") or []` in chronological order (`(c.get("createdAt") or "", idx)`).
   - Accept ONLY comments whose `(c.get("author") or {}).get("login") == owner`. Non-owner comments never release or alter a hold.
   - Read the first non-empty stripped line of the comment body:
     - `^Operator decision:\s*close` (case-insensitive) → `"close"`
     - `^Operator decision:\s*hold` (case-insensitive) → `"hold"` (explicitly supersedes an earlier proceed/close decision per KS-11c)
     - `^Operator decision` (case-insensitive, excluding `: close` and `: hold`) → `"proceed"`
   - Supersession: the **latest** matching `--owner` decision comment wins. Any comment whose first non-empty line does not start with `Operator decision` (including prose or line-2 markers) is ignored.
3. **Body and label hold detection (`issue_hold_reason(issue, open_refs)` — U15) across ALL issue types:**
   - Strip markdown fenced code blocks (`` ```...``` ``) and inline backtick spans (`` `...` ``) from `body` before matching prose hold markers (prevents false positives on documentation/table examples like `` `HELD: ...` `` while catching real body holds).
   - Detect holds in priority order across all issue types (bugs, docs, refactors, merge-batches, decided, unclassified):
     1. Label `status:held` (case-insensitive) → `"label status:held"`.
     2. Line/bullet marker `(?mi)^\s*(?:[-*]\s*)?(?:\*\*)?HELD:(?:\*\*)?` in cleaned body → `"body HELD: marker"`.
     3. Explicit blocker `(?i)blocked\s+by\s+(?:PR\s+)?#(\d+)` in cleaned body → `"blocked by #N"` (fail-closed regardless of whether `#N` is in the 14-day window).
     4. Dependency gating `after #N` in cleaned body (`(?i)after\s+(?:PR\s+)?#(\d+)`) when EITHER `#N` is in `open_refs` (open PR numbers ∪ open issue numbers in the snapshot) OR written as an explicit active gating clause (`after [PR] #N lands|merges|is merged|completes|closes`, or line/bullet-initial `after [PR] #N` / `depends on [PR] #N` / `gated on [PR] #N`, excluding past-tense narrative like `"after #1403 passed"` or `"After #1389's"`).
   - Body/label holds are fail-closed: an issue with an active `status:held`, `HELD:`, `Blocked by #N`, or open/gating `after #N` hold stays in `Needs-operator` and in `parked_issues` (so no queued PR silently closes it).
4. **Rule ordering in `parked_issues(...)` and `classify_issues(...)` (never fall into rule 9):**
   - `parked_issues(issues, other, decide, owner, open_refs)`:
     An issue is parked (blocking PR rule 3) iff:
     - `n in other`, OR
     - `decision == "hold"`, OR
     - `(n in decide or DECISION.search(title)) and decision not in ("proceed", "close")`, OR
     - `issue_hold_reason(issue, open_refs)` is non-empty.
     Therefore, once `--owner` posts `Operator decision` or `Operator decision: close` on `#1518` (and `#1518` has no body/label hold), `#1518` leaves `parked_issues` and PR `#1526` (`Closes #1518`) moves out of `Needs-operator` back to queue bucket `A` keeping `(closes #1518)`.
   - `classify_issues(...)` closed order (first match wins):
     1. `n in other` → Needs-operator (`owned by another session; remind only`).
     2. `decision == "hold"` → Needs-operator (`operator decision: hold`).
     3. `(n in decide or DECISION.search(title)) and decision not in ("proceed", "close")` → Needs-operator (`operator decision`).
     4. `hold = issue_hold_reason(it, open_refs)`: if `hold` → Needs-operator (`held ({hold})`).
     5. `n in folded` → skip (folded into the open own queued PR that closes it).
     6. `decision == "close"` → **Close bucket** (rendered after stale merge-batch/G or as dedicated close-decided queue items: `#N <title>: operator decision: close — verify acceptance on development, then close with a comment citing the commit.`). Never falls into rule 9.
     7. Rules G (`merge-batch`/BATCH), H (`REFACTOR`), F (`documentation`/`.md`), E (`bug`/code file).
     8. `decision == "proceed"` → **Decided-proceed queue item** (bucket E/decided: `#N <title>: operator decision recorded — execute via start-task or jog.`). Guarantees a released issue NEVER falls into rule 9 (`unclassified`).
     9. `OUT_OF_SCOPE` → Not queued.
     10. Anything else → Needs-operator (`unclassified; operator picks scope`).
5. **Runbook mirror (`skills/1-hourly/kickstart/SKILL.md`):**
   - Mirror the updated closed ordering, `--owner` `Operator decision` / `Operator decision: close` / `Operator decision: hold` release/supersession rules, U15 body/label holds (`status:held`, `HELD:`, `Blocked by #N`, `after #N`), and the child closeout rule (for `operator decision: close` items, verify acceptance on `origin/development` and close the issue citing the landing commit).
6. **No new test suites (GH-831):** Recorded paired manual checks under `TESTS-RESULTS/2026-11-20+GH-1535/`.

## Preflight Contract
- **Target files:** `skills/1-hourly/kickstart/scripts/build_queue.py`, `skills/1-hourly/kickstart/SKILL.md`, `CHANGELOG.md`, `PROJECT/2-WORKING/GH-1535-KS02-DECIDE-HOLDS.md`, `TESTS-RESULTS/2026-11-20+GH-1535/*`, `relay-system/2026-11-20/gh1535-*.md`, `releases.db`, `releases.sql`.
- **Classified route:** `utils/ci-route.sh pull_request` → `route=docs`, `tier=1` (`utils/pdda/pdda.sh run`).
- **Static check:** `mypy --allow-untyped-defs --allow-incomplete-defs skills/1-hourly/kickstart/scripts/build_queue.py` (with new helper functions cleanly typed).

## Verification Plan (R2 Discriminating Manual Check)
Record a literal runnable manual procedure, retained diff/name-status, transcripts, and `provenance.jsonl` under `TESTS-RESULTS/2026-11-20+GH-1535/` against pinned pre-change `build_queue.py` (base commit SHA recorded in `provenance.jsonl`) and the 2026-11-19 saved inputs (`TESTS-RESULTS/2026-11-19+GH-1527/inputs/`):
1. **Red control 1 — `#1518` decide-hold release (`Operator decision` proceed) & PR `#1526` unparking:**
   Add an `--owner noelsaw1` comment `Operator decision: ...` to `#1518`. Pre-change keeps `#1518` in Needs-operator AND parks PR `#1526` (`merging it would close parked #1518`). Changed moves `#1526` to bucket `A` keeping `(closes #1518)` and removes `#1518` from Needs-operator.
2. **Red control 2 — Released issue must NOT fall into rule 9 (`unclassified`):**
   Replay `#1518` with `--owner noelsaw1` `Operator decision` proceed AND without `#1526` closing it (`Refs #1518`). Pre-change keeps `#1518` held; a naive release without the post-rules-4-7 proceed catch would drop `#1518` (no labels, no file extension in title) into rule 9 (`unclassified`). Changed queues `#1518` cleanly in the Queue section (`operator decision recorded`).
3. **Red control 3 — `Operator decision: close` bucket:**
   Replay `#1518` with `--owner noelsaw1` `Operator decision: close — verified on development` (not folded into a PR). Pre-change keeps `#1518` in Needs-operator; changed queues `#1518` in the close bucket (`verify acceptance on development, then close with a comment citing the commit`).
4. **Negative controls (KS-11c fail-closed):**
   - Non-`--owner` comment (`author=someone-else`, `Operator decision: proceed`) → stays held in Needs-operator.
   - Wrong first line (`author=noelsaw1`, `Decided by operator` or `Operator decision` on line 2) → stays held.
   - Superseded decision (`author=noelsaw1` `Operator decision: proceed` followed by later `Operator decision: hold`) → stays held (`operator decision: hold`).
5. **Red control 4 (U15) — `#1400` OL-10 body/label hold shapes across issue types:**
   - Bug issue (`bug` label) with `HELD: owner decision required` in body only → pre-change queues in bucket `E`; changed holds in Needs-operator.
   - Docs issue (`documentation` label) with `status:held` label → pre-change queues in bucket `F`; changed holds in Needs-operator.
   - Bug issue with `Blocked by #1499` in body only → pre-change queues in bucket `E`; changed holds in Needs-operator.
   - Bug issue with `after #1467` (open PR) in body only → pre-change queues in bucket `E`; changed holds in Needs-operator.
   - False-positive guard: past-tense `"after #1403 passed"` (`#1412`) and backtick-quoted `` `HELD: ...` `` (`#1476`) do NOT spuriously move out of their expected buckets (`G` / `Not queued`).
   - Parked-PR propagation: an open PR with `Closes #<body-held-issue>` moves to Needs-operator (`merging it would close parked`).
6. **Determinism, read-only invariance & classified gate:**
   - Two back-to-back replays produce `cmp=0`; `git show-ref`, `FETCH_HEAD`, `git count-objects -v` unchanged.
   - `utils/ci-route.sh pull_request` → `route=docs`, `tier=1`; `./utils/pdda/pdda.sh run` exits `0` (`0 errors`); `mypy` exits `0`.
