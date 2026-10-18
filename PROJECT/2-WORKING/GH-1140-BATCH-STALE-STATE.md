---
gh_issue: 1140
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1140
title: "merge-cleanup batch records trust stale captured state across resume/rerun — verify, then one durable fix"
status: Active (2-WORKING — plan QA Approved r3, codex, 2026-10-18)
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
| #1073 | resume discards refreshed discovery for a known repaired PR → repair interactions omitted from sweep | **Reproduced (code), same seam as #1075 — widened per r1 QA** | same `extend()`; `_row` (B:62-64) captures title/hard deps too, so those go stale as well; conflict sites DO refresh via attempt records (298-306); **in-run shape too**: discovery (M:1593/1675) precedes repair (M:1209-1275), and `finalize_sweep_inputs` still consumes the pre-repair planned files |
| #1072 | read→modify→write not transactional under the per-file lock → stale snapshot overwrites newer state | **Mechanism verified (r1 wording correction)** | `save()` (B:89-92) locks the write only; `attempt_record.save` atomically replaces the whole file (attempt_record.py:117-122). The typical loss reverts another writer's new outcome **fields** to `unattempted`; whole-row loss occurs when the row is absent from the stale snapshot. Unprotected: erased outcomes, verdict/covers, planned rows, issue metadata, sweep inputs, OID/reconcile (B:146-149 can overwrite even a merged row). QA can clear if the overwrite erases the only landing evidence |
| #1084 (1, Major) | plain rerun (no `--resume`) exits 0 while a batch has QA pending | **Reproduced (code) + two r1 extensions** | `select_batch()` (M:1739-1763): `need_qa=True` lookup only inside the `args.resume` branch (:1748); empty queue + no resume → `None` → :1729 guard skipped → exit 0 (:1736). **Also:** a one-PR queue never adopts an old batch (M:1754); and a NEW 2+ batch with no landings masks an older QA-pending batch (`qa_pending(new)=False` → exit 0). Additionally `--execute --teardown-only` returns None unconditionally (M:1742-1743) — QA debt invisible even with `--resume` (new shape) |
| #1084 (2, Minor) | printed sweep command is not executable | **Reproduced — syntax error, not just a redirection** | batch_record.py:312 emits literal `<tmp>`; `bash -n` on the emitted form exits 2 (`syntax error near unexpected token '&&'`) — r1 QA probe |
| #1084 (3, Minor) | merge OID lost when the post-merge refresh fails | **Verified — recharacterized r1: discarded verified evidence + fallible re-query, not retained stale state** | `execute_pr_merge()` verifies the OID (M:224-228, M:233-236) then returns bool only; the caller (M:1313-1316) re-fetches and records `""` on error. Degradation is guarded (B:288-307 unknown range/full gate) but the record loses the commit |
| #444 | no merge veto for "do not merge" markers | **Partially fixed — widened r1** | labels+draft veto landed citing #444 (`HOLD_LABEL_TOKENS` M:59; skip at M:1113-1122). Three residual gaps: `hold_label()` (M:315-321) never scans the title **and `refresh_pr` doesn't fetch `title` at all** (M:244-245 JSON field list); the final eligibility re-check (M:1301-1304) is **draft-only** — a hold label added between the first check (M:1117) and final merge is missed. r1 falsifiers: a title-only "DO NOT MERGE" PR and a PR acquiring the label during gating must both stay unmerged |
| **NEW (r1)** | crash between remote merge and record-save leaves persisted `unattempted`; resume never recovers it — and `closed: merged outside this run` (M:1123-1127) records no OID, is excluded from `landed()` (B:100), and is terminal (B:114) → QA debt can silently clear | **Verified (code, r1)** | discovery is OPEN-only (toposort_prs.py:33-35); resume only extends (M:1746-1752); no live recovery of absent planned PRs. Recovery must key on positive MERGED+OID evidence; CLOSED without merge must not invent a landing |
| #944 | batch-issue protocol | **Delivered by #1069** | threshold 2+ (M:1754) — an explicit subsequent operator decision (PROJECT/3-COMPLETED/GH-1064-MERGE-BATCH-ISSUE-QA.md:23-31), not an unexplained deviation; carry-over dual sink is caller-owned and present (SKILL.md:435-442) |

**Pattern verdict (amended after r1 QA — codex FAIL round):** the class is real and is **five
mechanisms plus one command defect**, not three: (1) stale planned metadata never refreshed (#1075,
#1073 — including the in-run post-repair window); (2) lost durable updates via non-transactional
saves (#1072); (3) incomplete QA-debt discovery (#1084-1, one-PR queues, new-batch masking,
teardown-only); (4) discarded verified merge OID re-queried fallibly (#1084-3 — evidence loss, not
retained state); (5) incomplete/live-stale veto inputs (#444: title unfetched, title unscanned,
late labels unchecked); plus the unrecorded-merge recovery seam (NEW r1) and the `<tmp>` command
defect. #944 is done.

## Phase B — the fix (only the verified shapes; extends the existing subsystem)

One mechanism per family, all inside the two existing files (plus `refresh_pr`'s field list).
No new modules, no queue/locking subsystem, no rewrite.

1. **Refresh captured metadata at the point of reuse** — `extend()` updates `files`/`soft`/`hard`/`title`
   for known PRs from the current discovery it already receives (order/outcomes untouched); a repair
   that lands within a run updates that PR's planned row from the repair's own changed-file record.
   Retires #1075, #1073 (both the resume and in-run shapes).
2. **Transactional-enough saves with intentional-update provenance** (r2 amendment) — `save()`
   merges under the existing `RecordLock` with rules that distinguish *intentional fresh writes*
   from *stale carried fields*: (a) `outcomes` merges per PR at field level with GH-1074 monotonicity
   (concrete status/merge_oid/reconcile win over `unattempted`/empty; `merged` never downgraded);
   (b) `planned` merges per PR — a row the current writer **refreshed this turn carries a refresh
   marker and wins**; unmarked rows preserve the on-disk copy (a stale snapshot cannot resurrect old
   metadata, and a refresh cannot be clobbered by a stale writer); (c) `verdict` and `sweep_inputs`
   carry write timestamps and the newer intentional replacement wins (B:308-314/B:332-333 are
   replacements by design); (d) `landed_order` unions; `issue` metadata on-disk unless absent.
   Acceptance = the three r2 falsifiers: refreshed row reloads as `["a","b"]`; a replacement
   verdict covering `[1,2]` reloads with the new covers/body; the two-writer preservation control
   from Phase A still holds.
3. **QA-debt discovery on every executing run** — a final-status step in `main()` independent of
   batch adoption: after Phase 6, look up `find_unfinished(..., [], need_qa=True)` whenever the
   run's own batch is `None` or not QA-pending, including `--teardown-only` executes; exit 4 when
   owed. Adoption of an old batch still requires `--resume`. Retires #1084-1 and both r1 extensions
   (one-PR queue masking, teardown-only invisibility, new-batch masking).
4. **Keep verified evidence** — `execute_pr_merge()` returns `(bool, oid)` carrying the OID it
   verified; the caller records it directly; the post-merge re-fetch becomes reconciliation-only.
   Retires #1084-3.
5. **Veto inputs complete and live** — `refresh_pr` fetches `title`; `hold_label()` scans the title
   against the existing `HOLD_LABEL_TOKENS`; the final eligibility re-check (:1297-1311) re-checks
   hold labels, not just draft. Retires the widened #444.
6. **Recover unrecorded merges** (r2 amendment, three coverage points) —
   (a) *in-run retention:* when a discovered PR refreshes as `MERGED` mid-run (M:1123-1127), record
   the merge OID and count it in `landed()` instead of the OID-less `closed: merged outside this run`;
   (b) *resume recovery:* for planned PRs absent from OPEN-only discovery, one live refresh each —
   positive `MERGED`+OID records `status=merged, merge_oid` (QA owed); `CLOSED` without merge
   evidence stays terminal (no invented landing); refresh failure defers;
   (c) *reachability:* a resume whose discovery does not overlap an old unfinished batch reaches it
   for recovery — `find_unfinished` gains a recovery mode matching repo+integration over batches
   with unlanded planned PRs (before overlap/qa_pending filtering excludes them), performs (b), and
   lets the ordinary flow continue. Bounded to planned PRs of unfinished batches for this
   repo+integration — no arbitrary historical scanning. Retires the r1 recovery shape including the
   r2 selection boundary.
7. **Executable sweep command** — emit the mktemp form at batch_record.py:312. Retires #1084-2.
8. **#944 disposition** — close as delivered by #1069 (threshold 2+ was the operator's recorded
   decision), from the PR description.

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
2. `save()` provenance merge (refresh marker, monotonic outcome fields, timestamped verdict/sweep) + two-process manual check under TESTS-RESULTS -> expect: both writers' outcomes survive; refreshed row reloads fresh; replacement verdict reloads with new covers (r2 falsifiers).
3. `execute_pr_merge` OID return + caller demote-refetch -> expect: recorded OID non-empty when refresh later fails (unit with mocked refresh).
4. Final-status `need_qa` lookup in main() (covers plain rerun, one-PR queue, teardown-only, new-batch masking) -> expect: plain rerun with QA-pending fixture exits 4; red control by removing the lookup.
4b. Recovery: in-loop MERGED OID retention (M:1123-1127) + resume absent-PR recovery + find_unfinished recovery mode -> expect: (a) in-loop MERGED observation records OID and lands in `landed()`; (b) resume with both PRs remotely MERGED reaches the old non-overlapping batch and owes QA; CLOSED-without-merge stays non-landed; unrelated OPEN PRs are never invented as landings.
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
