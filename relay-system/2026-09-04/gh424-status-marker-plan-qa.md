---
Goal: QA the GH-424 implementation plan before any code is written
Date: 2026-09-04
NEXT: Writer
STATUS: Conditionally Approved
---

# Context

Adjudicate `PROJECT/2-WORKING/GH-424-ROADMAP-STATUS-MARKER-WRITER.md` against the code it describes.
**This is a review turn — report, do not edit.** Cite `file:line` wherever you disagree.

The plan was written against a completed four-lane recon, not from the issue text. Read the map
first: `PROJECT/1-INBOX/recon-gh424-status-marker.md`. It already corrected the issue body three
times, so **do not re-derive what is already there** — find what the recon and the plan both missed.

Read in full:

- `PROJECT/2-WORKING/GH-424-ROADMAP-STATUS-MARKER-WRITER.md` — the plan under review
- `PROJECT/1-INBOX/recon-gh424-status-marker.md` — the traced current state
- `utils/py/releases_app.py` — esp. `perform_write:1205-1288`, `cmd_roadmap_update:3295-3372`,
  `_ROADMAP_STATUS_MARKERS:2814`, the column DDL at `:602`, `cmd_check:4058-4288`
- `utils/py/wave_reconcile.py` — esp. `RollbackJournal:75-119`, `run_subprocesses:670-763`,
  `main()` `:840-1010`, the OPEN-issue guards at `:920-925` and `:946-959`
- `utils/py/express.py:71-77` — the canonical five-file constant
- `AGENTS.md` §13 and the ledger rails at `:155-164`; `SOP.md:80-83`

Repo context to assume rather than rediscover: releases-mode repo, `releases.db` (via `releases.sql`)
is planning truth, `ROADMAP.md` is frozen legacy, every ledger write goes through `releases_app.py`
— never direct SQL. `RELEASES.generated.md` is gitignored.

# Questions

Answer each explicitly. A bare "looks fine" on any of these is not an answer.

1. **Is the enum decision right?** The plan reuses `_ROADMAP_STATUS_MARKERS` (12 emoji,
   `releases_app.py:2814`) rather than declaring a narrower set, on the grounds that a fourth
   vocabulary is how the `⏸️`/`⏸` drift happened. But that list exists for *markdown parsing* in the
   legacy sync path. Is reusing a parse-time constant as a write-time enum sound, or is it
   overloading one constant with two contracts? If you would narrow it, name the exact set and say
   what breaks.

2. **Is "warn, do not refuse" on marker/`raw_text` divergence correct?** The plan refuses to refuse,
   citing `SOP.md:80-83` (the promotion procedure sets `--raw-text` to a bullet that itself contains
   a marker). Measured divergence today is 2 of 117 rows. Is a warning enough, or does it just make
   the drift quieter? Consider: is there a formulation that keeps SOP §1b working AND makes
   divergence impossible rather than merely visible?

3. **Phase 3 sequencing — is the insertion point right, and is it sufficient?** The plan puts the DB
   write between `update_roadmap_entry` (`:942`) and `run_subprocesses` (`:988`), arguing
   `releases check` must validate it and `roadmap-dashboard.sh` must follow it for the GH-243 push
   guard. Verify both claims against the code. Then: what happens to that write when a LATER step in
   `run_subprocesses` fails — `marathon-plan.sh` exits 4 or 6 — and the journal rolls back? Does the
   DB write get restored, and does the receipt chain survive discarding a committed
   `roadmap-update` receipt?

4. **Is the journal fix complete?** The plan moves the five-file constant into `harness_paths.py`
   and imports it from both `express.py` and `wave_reconcile.py`. Does that actually cover the
   failure? Consider `snapshot()`'s no-op on a missing path (`:83-89`), `track_created()`, the
   presence-gated adoption at `releases_app.py:1272`, and Tier-1 installs with no `releases_app.py`.
   Is `harness_paths.py` the right home for this constant, or is it the wrong module?

5. **Is the board_sync blast radius handled?** `board_sync.py:184` selects
   `WHERE status_marker = '🚧'` and treats hits as strong candidates to add to a LIVE GitHub
   Projects board — inert today only because nothing can write `🚧`. The plan's mitigation is a
   green asserting scan sees it and no write happens without `--write`. Is that sufficient, or
   should the first shipped version refuse to write `🚧` at all until GH-402's reconcile path is
   re-reviewed? Argue it.

6. **What did the recon and the plan both miss?** Not style — a concrete failure. Walk the first
   real invocation end to end and name where it stops or does something unintended. Include anything
   about `perform_write`'s writer lock, the intent journal, `refresh_preview`, the 28 existing
   `perform_write` call sites, or the five fixture mocks that would surprise this change.

7. **Is anything here over-engineered?** Judge through a YAGNI lens. The plan touches six source
   files plus a test and a baseline. Is that the smallest change that closes the gap, or has it
   grown a subsystem it does not need? Name anything you would cut.

Flag anything wrong, missing, incorrectly scoped, or over/under-engineered. Where you disagree, cite
the line in the plan and the line in the code that contradicts it.

Write your verdict below. Set `STATUS: Approved` only if the plan is implementable as written.

<!-- ▽ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK ▽ -->
▶ TAKE YOUR TURN (deepseek)
<!-- △ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK △ -->

# REVIEWER VERDICT — deepseek

**STATUS: Conditionally Approved** (two blocking items in §3 and §6; see below. Fix these and the plan is implementable.)

---

## Q1 — Enum decision: Correct, with one caveat

**Verdict: Approved.** Reusing `_ROADMAP_STATUS_MARKERS` (`releases_app.py:2814`) as the write-time enum is the right call. Adding a second, narrower list for the write path would create exactly the vocabulary drift the plan exists to prevent — a fourth vocabulary is how `⏸`/`⏸️` started. The 12-emoji list is already the parse-time contract in `_parse_roadmap_markdown` (`:3039`; used by `roadmap sync`) and is already what the data can hold.

**Caveat:** The plan does not explicitly note that `_ROADMAP_STATUS_MARKERS` includes emoji that none of the viewers render (`🔮`, `🟢`, `🔴`, `🐞`, `⚙️`, `🔲`, `🟡`, `⛔` — viewers at `export_timeline.py:40` and `releases_cycle.py:35` map only 4). An operator can store a marker that the dashboards and timeline will silently show as unclassified. This is the *existing* state — `roadmap sync` (the non-releases-mode path) already writes any of these. The fix is **not** to narrow the enum (the plan correctly rejects that), but to add a document note or warning text at the CLI: "markers outside ✅/🚧/⏸/‖ have no viewer mapping." The U+FE0F fix (plan §1, "One reachable-bug fix") partially addresses this for the `⏸️` case. Consider extending it to any marker outside what the viewers can render.

---

## Q2 — "Warn, do not refuse" is correct

**Verdict: Approved.** SOP.md:80-83 is the binding constraint — the promotion procedure sets `--raw-text` to a bullet that already contains a marker, and refusing that would break the documented workflow. A warning naming both markers is the honest middle.

The concern that warnings "just make the drift quieter" is valid, but the plan parks a check rule with the measurement (2 of 117 rows). That is the correct deferral: any new `releases check` rule is a contract vendored consumers must satisfy, and their data is unseen. Ship the writer, measure the divergence, then decide on a check rule.

**Implementation detail:** The divergence checker must parse the marker from `old_raw_text` (the row as stored) using `_ROADMAP_STATUS_MARKERS` (the same logic as `_parse_roadmap_markdown`:3039-3042). The function `cmd_roadmap_update` currently selects `select_cols` at `:3316` which does **not** include `status_marker`. You will need `status_marker` (or its parsed equivalent from `raw_text`) for the old-vs-new comparison. The simplest approach: select it and compare.

---

## Q3 — Phase 3 sequencing: CORRECT on placement, INSUFFICIENT on what marker to write

**Verdict: Conditionally approved.** The insertion point between `update_roadmap_entry` (`:932-942`) and `fix_mangled_roadmap_entries` (`:985`) is correct for both stated reasons: `releases check` validates the post-write state, and `roadmap-dashboard.sh` (step 4 of `run_subprocesses`) must run on the updated dump for the GH-243 push guard.

**BLOCKING GAP 1 — WHAT marker does the reconciler write?** The plan says "the reconciler writes the marker via subprocess before run_subprocesses" but never specifies which marker value. `update_roadmap_entry` (`wave_reconcile.py:457-556`) writes to **ROADMAP.md** with a `✅ **SHIPPED {date} (PR #{num})**` or `🛑 **DECLINED {date} (PR #{num})**` badge — an emoji in the markdown text. The Phase-3 subprocess must set the DB `status_marker` column. These two representations are now independent, and the plan provides no coordination between them.

The reconciler knows `is_merged` (a boolean passed down to `update_roadmap_entry` at `:936`). The Phase-3 subprocess should derive the marker from the same signal:
- `is_merged = True` → `--status-marker ✅`
- `is_merged = False` → `--status-marker 🛑` (or `🚧` if the entry stays in-progress)

The implementation must pass `is_merged` down to the Phase-3 call site (it currently only reaches `update_roadmap_entry`). Without this, the reconciler will write either nothing or the wrong marker.

**BLOCKING GAP 2 — Rollback after Phase-3 write + later step failure.** Your analysis is correct: the `RollbackJournal` snapshots `db_file` and `sql_file` *inside* `run_subprocesses` (`:675-680`), which is called *after* the Phase-3 write. So the snapshot captures the post-write state, and rollback RESTORES the post-write DB+dump — the write survives. This is the CORRECT behavior: the Phase-3 write is an intended part of reconciliation.

BUT: the `perform_write` call inside `releases_app.py` creates its own intent journal at `releases-app-journal.json` (`lock.journal_path`). After the Phase-3 subprocess exits cleanly, `perform_write` clears that journal (`:1284`). If the subprocess is the `releases roadmap update` call, its journal is cleared before `run_subprocesses` starts — no orphan. If the subprocess exits non-zero (e.g., `roadmap update` refuses because of a bad marker), the releases_app's `mutate()` raises BaseException and clears the journal (`:1247-1254`). Safe.

The one unaddressed failure mode: if the Phase-3 subprocess SUCCEEDS (journal cleared) but the wrapper `subprocess.run()` isn't checked for returncode before proceeding. The plan says "as a subprocess, not SQL" — ensure `check=True` or an explicit `if r.returncode != 0: die(...)` wraps the call.

---

## Q4 — Journal fix: Correct in principle, `harness_paths.py` is appropriate

**Verdict: Approved.** The 5-file snapshot tuple hardcoded in `wave_reconcile.py:686-696` is `express.py:71-77` (`DRIVER_GENERATED`) with `RELEASES.generated.md` dropped — exactly the copy-drift the plan describes. Moving the canonical list to `harness_paths.py` is the right home: it's the path-resolution module, already imported by `wave_reconcile.py:23`, ships in the core tier, and `express.py` importing from it adds no circularity (`harness_paths.py` imports only `os`, `sys`).

Two specifics the plan handles correctly:
- `snapshot()` no-ops on missing paths (`:83-89`) — `RELEASES.generated.md` is presence-gated.
- Tier 1 has no `releases_app.py` (`xyz-vendor.sh:344`) — `track_created()` handles the gen file there.

The plan's claim that the gap was invisible due to gitignore (`:107`) is correct per `verify_rollback_completeness`:146-168 using `git status --porcelain`.

---

## Q5 — board_sync blast radius: Sufficient as described

**Verdict: Approved.** `board_sync.py:184` queries `status_marker = '🚧'` and tags results as `stale_marker` — a WEAK source (`board_sync.py:75`, `WEAK_SOURCES`). `reconcile` (`:563-585`) only writes for STRONG sources (`STRONG_SOURCES` at line 74: `pdda_doc, branch, tick_event, jog_running`). So `🚧` rows are already inert for board writes: they appear in `scan` output but never trigger a `board_add` unless another strong source matches the same issue.

The plan's mitigation — "assert that a `🚧` write is visible to `board_sync scan` but that `board_sync` still performs no write without `--write`" — is a test assertion over the existing design. The plan does not need to refuse `🚧` writes; the board code already ignores them by strength classification.

**Note for the test:** verify that a row with only a `🚧` marker does NOT trigger a board write even under `--write`. The `reconcile` path at `:580` ("weak-only") logs and skips. That behavior is what protects the board.

---

## Q6 — What the recon AND the plan both missed

**BLOCKING GAP 3 — `update_roadmap_entry`'s emoji badge vs the DB marker are independent and uncoordinated.**

The reconciler's `update_roadmap_entry` (`wave_reconcile.py:457-556`) injects a SHIPPED badge containing `✅` or `🛑` into ROADMAP.md. The Phase-3 write (plan §3) sets `status_marker` in the DB. These are SEPARATE representations and there is no contract ensuring they agree.

In practice:
- `update_roadmap_entry` line 499: `badge_sub = f"✅ **SHIPPED {ship_date} (PR #{pr_num})**" if is_merged else f"🛑 **DECLINED {ship_date} (PR #{pr_num})**"`
- The original ROADMAP.md line also carries whatever marker was there before (e.g., `🆕`)
- The Phase-3 subprocess sets `status_marker` in the DB

After reconciliation, the ROADMAP.md line says `✅ **SHIPPED**` + the old marker, while the DB says something potentially different. This reproduces R2 (divergence) in a new form.

**Fix:** The Phase-3 subprocess must write a marker that AGREES with `update_roadmap_entry`'s badge. If the entry was SHIPPED (`is_merged=True`), write `✅`. If DECLINED (`is_merged=False`), write `🛑`. Also strip the old marker from the ROADMAP.md line so the two representations are consistent. The simplest approach: after `update_roadmap_entry`, call the same marker-derivation logic for the Phase-3 subprocess. Pass `is_merged` to the Phase-3 call site.

**BLOCKING GAP 4 — `cmd_roadmap_update` dry-run does not mention `--status-marker`.**

Currently `cmd_roadmap_update`:3339-3348 only prints changes to `raw_text`, `rating`, and `section`. If `--status-marker` is given (alone or with others), the dry-run output should show `status_marker: <old> -> <new>`. Without this, `--dry-run` misleads the operator into thinking nothing would change, then the live run surprises them.

**Note — not a blocking gap but worth addressing:** The reconciler's `update_roadmap_entry` writes to **ROADMAP.md**, which in releases-mode is frozen legacy. The plan's Phase 3 writes the DB column, which is the releases-mode canonical representation. After reconciliation, ROADMAP.md (legacy) and the DB column (canonical) may disagree. The plan does not discuss whether this is acceptable or needs cleanup. In releases-mode, ROADMAP.md is not re-synced (`roadmap sync` no-ops at `:3380-3385`), so the legacy markdown state and the DB marker state evolve independently. This is not a blocker — it is the current design — but a reconciler operator may be confused when `releases check` diverges on the legacy file.

---

## Q7 — Over-engineering: Reasonably scoped

**Verdict: The plan is not over-engineered.**

Count of touched files: `releases_app.py` (writer + parser), `wave_reconcile.py` (Phase 3), `harness_paths.py` (constant), `express.py` (import), `export_timeline.py` (2-line fix), `releases_cycle.py` (2-line fix), `validate.sh` (registration), `test/gh424-roadmap-status-marker.sh` (new), `test/baselines/GH-424-negative-control.md` (proof). That is six substantive modifications + two 2-line viewer fixups + test infrastructure. The plan arguably over-documents the test greens list (10 bullet points at `:170-179`), but every one maps to a concrete assertion, so none is ceremonial.

The only YAGNI candidate is the `⏸️` viewer fix (2 files). The plan correctly argues this is "one reachable-bug fix": the enumeration is `U+23F8 U+FE0F` while viewers key on `U+23F8`. Today this is inert because nothing can write `⏸️`. After Phase 1, an operator can. A two-line fix now prevents a support call later. Not over-engineering.

---

## Summary of blocking items

| # | Gap | Location | Fix |
|---|---|---|---|
| B1 | Phase-3 reconciler subprocess does not specify WHICH marker to write | GH-424 plan §3; `wave_reconcile.py:932-942` insertion point | Pass `is_merged` to the Phase-3 call site; write `✅` when merged, `🛑` when declined |
| B2 | Same as B1 — the marker derivation must agree with `update_roadmap_entry`'s badge (`✅ SHIPPED` / `🛑 DECLINED`) | `wave_reconcile.py:499`, plan §3 | Coordinate the two writes; strip the old marker from ROADMAP.md so the representations do not diverge |
| B3 | `cmd_roadmap_update` dry-run does not show `--status-marker` effect | `releases_app.py:3339-3348` | Add `status_marker: <old> -> <new>` to the dry-run output |
| B4 | `cmd_roadmap_update:3316` `select_cols` does not include `status_marker` | `releases_app.py:3316` | Add `status_marker` to the SELECT for divergence comparison |

Fix these four items and the plan is implementable as written. The viewer `⏸` fix, journal constant consolidation, and board_sync assertions are sound and need no change.

---

## Recorded findings

- `releases_app.py:2814` — `_ROADMAP_STATUS_MARKERS` contains 12 emoji, 4 of which viewers render. No change needed but worth documenting.
- `wave_reconcile.py:686-696` — hardcoded 4-tuple missing `RELEASES.generated.md`. Phase 2 fixes this.
- `board_sync.py:74-75` — `stale_marker` is WEAK; the board is safe.
- `releases_app.py:4984-4989` — parser must add `--status-marker` to `roadmap update`.
- `releases_app.py:3322-3323` — `no-update` guard must extend to `--status-marker`.
- `SOP.md:80-83` — promotion sets `--raw-text` to a bullet containing a marker — the binding constraint on Q2's "warn, do not refuse."

---

`STATUS: Conditionally Approved`
`NEXT: fix-blockers → return to deepseek for re-review`


---

# ROUND 2 — producer response, back to you

All four blockers (B1-B4) are folded into `PROJECT/2-WORKING/GH-424-ROADMAP-STATUS-MARKER-WRITER.md`.
Re-read that file; the "Review history" section records each disposition.

**One correction against your review, and it is the thing to check first.**

B1/B2 specify `is_merged = False → --status-marker 🛑`. **`🛑` (U+1F6D1) is not in
`_ROADMAP_STATUS_MARKERS`** — the 12-emoji enum you approved in Q1 as the write-time vocabulary. So
that fix, as written, would be rejected by the validation you endorsed two sections earlier. The
in-enum stop glyph is `⛔` (U+26D4). Verified:

```
enum: 🆕 🚧 ✅ ⏸️ 🟡 ⚙️ 🔲 ⛔ 🔮 🟢 🔴 🐞
  ✅ U+2705  in enum? True
  🛑 U+1F6D1 in enum? False
  ⛔ U+26D4  in enum? True
```

Resolved as **merged → `✅`, declined → `⛔`**, with the asymmetry against
`wave_reconcile.py:499`'s `🛑 **DECLINED**` badge documented in code rather than removed — closing
the gap by glyph identity would mean either widening a parse-time enum or editing frozen legacy
text, and neither is worth it.

# Questions for round 2

1. **Do you accept `⛔` over `🛑`**, or do you want `🛑` added to `_ROADMAP_STATUS_MARKERS`? If the
   latter, say what it costs — that constant is the markdown parse contract for legacy-mode repos,
   so widening it changes what `roadmap sync` will absorb elsewhere.

2. **Is B2 actually satisfied?** You asked the two representations to "agree". They now agree
   *semantically* (shipped/declined) but not *glyphically*. Is that sufficient, or does the
   divergence warning need to special-case the reconciler's own writes so it does not fire on every
   reconcile?

3. **The unrenderable-marker warning bites the declined path immediately** — `⛔` has no viewer
   mapping, so the reconciler's own declined write trips the warning the plan just added. Is that
   acceptable noise, or should `⛔` gain a viewer mapping in this change (making it three viewer
   lines, not two)?

4. **Anything in the folded-in text that is wrong or that you did not intend?** Read the four
   blocker dispositions specifically. A misread of your own finding is worse than the original gap.

5. **Is the plan now implementable as written?** If yes, say so plainly and set `STATUS: Approved`.
   Implementation is gated on this answer.

<!-- ▽ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK ▽ -->
▶ TAKE YOUR TURN (deepseek)
<!-- △ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK △ -->
