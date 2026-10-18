---
gh_issue: 1140
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1140
title: "merge-cleanup batch records trust stale captured state across resume/rerun — verify, then one durable fix"
status: Proposed (1-INBOX — plan QA pending)
created: 2026-10-18
updated: 2026-10-18
owner: noelsaw1
goal: "Verify the RADAR-class-merge-batch-stale-state pattern at HEAD, then fix the verified shapes as a few surgical mechanisms in the existing batch-record/driver code."
doc_type: fix
effort: 3
complexity: 3
risk: 3
phases: 2
related:
  - "#1075 — stale file lists on resume (same seam: extend)"
  - "#1073 — refreshed discovery discarded for known PRs (same seam: extend)"
  - "#1072 — non-transactional read-modify-write on the batch dict"
  - "#1084 — QA gate bypass on non-resume rerun (Major) + sweep command quoting + merge OID loss"
  - "#444 — do-not-merge veto: labels+draft landed, title marker still unchecked"
  - "#944 — batch-issue protocol: delivered by #1069 at threshold 2+ (ask was >=3)"
---

# GH-1140: batch records trust stale captured state

## Authority and history

Radar run 6 (2026-10-18, run record #1138, board #293) filed this class; the operator scheduled it
via start-task the same day with the directive that **plan-QA round 1 verifies the pattern before any
fix is designed**. This supersedes the "deferred, not scheduled" triage note on the Medium members.
Base: `origin/development` @ `4fd5dca8` (2026-10-18T08:02:42Z), task clone
`XYZ-forge-gh1140-batch-stale-state-2026-10-18`.

## Phase A — pattern verification (done at base; plan-QA round 1 adjudicates this table)

Every claim was traced to current HEAD, not the October review heads. Line numbers are at `4fd5dca8`.

| Issue | Claimed shape | Verdict at HEAD | Evidence |
|---|---|---|---|
| #1075 | resume keeps stale `files`/`soft` for known PRs → sweep misses new shared files | **Reproduced (code)** | `batch_record.extend()` (batch_record.py:79-87) appends only unknown PRs; `finalize_sweep_inputs()` (282-295) computes `shared_files` from the stored `row["files"]` |
| #1073 | resume discards refreshed discovery for a known repaired PR → repair interactions omitted from sweep | **Reproduced (code), same seam as #1075** | same `extend()`; note conflict sites DO refresh via per-PR attempt records (298-306) — only file lists/soft reasons go stale |
| #1072 | read→modify→write not transactional under the per-file lock → stale snapshot can overwrite newer state and clear QA-pending | **Mechanism verified** | `save()` (89-93) locks the write only; whole-dict last-writer-wins. GH-1074's guards (merge-never-downgrade :144; `landed()` backstop :95-102) protect two specific consequences, but a writer whose snapshot predates another writer's `set_outcome` still drops that PR's outcome row entirely |
| #1084 (1, Major) | plain rerun (no `--resume`) exits 0 while a batch has QA pending | **Reproduced (code)** | `select_batch()` (merge_cleanup.py:1739-1763): the `need_qa=True` lookup exists only inside the `args.resume` branch (:1748); empty queue + no resume → `None` → :1729 guard skipped → exit 0 |
| #1084 (2, Minor) | printed sweep command is not executable | **Reproduced** | batch_record.py:312 emits literal `<tmp>`; the shell parses it as a redirection |
| #1084 (3, Minor) | merge OID lost when the post-merge refresh fails | **Verified** | `execute_pr_merge()` (:200-239) returns bool and discards the OID it already verified; the caller (:1313-1316) re-fetches and records `""` on error. Degrades safely (full gate) but the record loses the commit |
| #444 | no merge veto for "do not merge" markers | **Partially fixed** | labels+draft veto landed citing #444 (`HOLD_LABEL_TOKENS` :59; skip at :1113-1122, re-check :1301-1304) — but `hold_label()` (:315-321) never scans the **title**, and the original #441 near-miss carried its marker in the title |
| #944 | batch-issue protocol | **Delivered by #1069** | threshold `len(ordered_prs) < 2 → None` (:1754) — 2+, ask was ≥3; content sections, sweep inputs, `--record-sweep` all present |

**Pattern verdict (the hypothesis plan-QA round 1 must confirm or reject):** the class is real but
is **three mechanisms, not one**: (A) *captured-once state never refreshed* (#1075, #1073, #1084-3 —
file lists, discovery, verified OID); (B) *QA-pending state invisible outside `--resume`* (#1084-1)
plus *non-transactional saves* (#1072); and one pre-existing *veto gap* (#444 title). #944 is done.

## Phase B — the fix (only the verified shapes; extends the existing subsystem)

One mechanism per family, all inside the two existing files. No new modules, no queue/locking
subsystem, no rewrite.

1. **Refresh captured state at the point of reuse** — `extend()` updates `files`/`soft`/`hard`/`title`
   for known PRs from the current discovery it already receives (order/outcomes untouched);
   `execute_pr_merge()` returns `(bool, oid)` and the caller records the OID it verified, demoting
   the post-merge re-fetch to reconciliation. Retires #1075, #1073, #1084-3.
2. **Make QA-pending visible on every executing run** — after Phase 6, if the run's batch is `None`
   or not QA-pending, look up `find_unfinished(..., [], need_qa=True)` for the final status so a
   plain rerun exits 4 (status-only; adoption of an old batch still requires `--resume`). Retires #1084-1.
3. **Transactional-enough saves** — `save()` becomes a per-key merge under the existing
   `RecordLock`: `planned`/`outcomes`/`landed_order` union with on-disk winning per-PR except
   merged-never-downgrade; `verdict`/`sweep_inputs`/`issue` metadata from on-disk unless absent.
   One choke point; callers unchanged. Retires #1072's whole-row-loss shape.
4. **Veto reads titles too** — `hold_label()` also scans `info["title"]` against the existing
   `HOLD_LABEL_TOKENS`. Retires the residual #444 shape.
5. **Executable sweep command** — emit the mktemp form at batch_record.py:312. Retires #1084-2.
6. **#944 disposition** — close as delivered by #1069 (threshold 2+ noted), from the PR description.

### Acceptance checks (falsifiable; existing suites only — AGENTS.md GH-831)

- `test/gh436-merge-cleanup.sh` / `gh436-merge-cleanup.py` and `gh534_phase_b_tests.py` stay green,
  extended only where pinned behavior changes (resume-refresh, exit-4 on plain rerun, save-merge,
  title veto). Each extension's red control: mutate the fix (e.g. revert `extend()` refresh) and
  watch the assertion fail.
- Manual checks under `TESTS-RESULTS/2026-10-18+GH-1140/` with `provenance.jsonl` for shapes the
  suites cannot reach end-to-end (two-writer save race: two concurrent `set_outcome` processes —
  assert both PRs' outcomes survive; plain-rerun exit 4 against a fixture QA-pending batch).
- Empty-input guards: refreshed discovery lists that are empty must not blank a known row's files.

### Non-goals

No merge-cleanup rewrite, no new lock manager or queue subsystem, no new test suites or registry
entries, no change to landing/QA exit-code contract beyond surfacing exit 4 where it was already
owed, no threshold change for batch-issue creation (2+ stands; #944 closes on it).

### Preflight bet

- *Outcome sought:* a resumed/rerun batch always reflects current discovery, verified merges, and
  owed QA — no silent stale-state decisions.
- *Smallest viable bet:* the six surgical edits above in two files.
- *Alternatives rejected:* (a) re-derive ALL batch state from attempt records at every read —
  larger, duplicates `attempt_record`'s job; (b) per-writer process locking — new subsystem for a
  two-writer problem; (c) doing nothing — #1084-1 already lets a whole QA gate be skipped by
  forgetting one flag.
- *Rollback:* single revert of the task branch; no schema, format, or contract migration involved.

## Ordered implementation list

1. `extend()` refresh + unit coverage (gh436 .py) -> expect: resume-with-changed-branch fixture keeps new file list; red control by reverting the refresh.
2. `save()` per-key merge + two-process manual check under TESTS-RESULTS -> expect: both writers' outcomes survive.
3. `execute_pr_merge` OID return + caller demote-refetch -> expect: recorded OID non-empty when refresh later fails (unit with mocked refresh).
4. Final-status `need_qa` lookup in main() -> expect: plain rerun with QA-pending fixture exits 4; red control by removing the lookup.
5. `hold_label()` title scan -> expect: title-marked PR skipped in unit fixture.
6. Sweep-command mktemp form -> expect: emitted string shell-safe (`bash -n` clean when substituted).
7. Focused suites green (`bash test/gh436-merge-cleanup.sh`, gh534 phase-b focused run) -> expect: 0 failures.
8. Final gate per `utils/ci-route.sh` classification of the changed paths (code tier; full gate in the disposable `-gate` clone if routed) -> expect: GREEN, identity intact before/after.

## Rating

`rated 78/72/50/62` — pri 78 (operator-scheduled 2026-10-18; four recurring member issues + observed
durable-record loss in the #1064 QA campaign); sev 72 (QA-gate bypass + durable batch-history loss —
recoverable process artifacts, not product data; the machinery gates every multi-PR landing);
appeal 50 (default, no operator preference stated); effort 62 (six surgical edits, two files,
existing suites; no design risk beyond the save-merge rules). Recurrence window: issues filed
2026-09-05 → 2026-10-15, fixes across ≥4 PRs (Sep 27 → Oct 17).
