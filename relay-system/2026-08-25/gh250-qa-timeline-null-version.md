---
Goal: QA the GH-250 hotfix (export_timeline.py NULL-version crashes)
Date: 2026-08-25
NEXT: — (relay closed)
STATUS: Approved
Reviewer: commandcode
---

# Context

QA the hotfix commit `05fe73aa` on `development` — "fix(timeline): GH-250 hotfix — exporter no longer crashes on codename-only (NULL-version) releases". The spec is GitHub issue #250: `releases add` accepts a codename with no version, and `utils/timeline/export_timeline.py` crashed on any ledger containing such a row (`--preview`, `--leaderboard`, and the warn-only `refresh_preview()` path that then silently stops updating baked artifacts).

Read in full:
- utils/timeline/export_timeline.py (the fix — four sites: the `id` derivation in `release_columns()` ~L277, `_ver()` ~L380, the rail-order sort tiebreaker ~L197, and `md_drift()`'s `db_only` listing ~L424)
- test/gh103-timeline-exporter.sh (the new "GH-250: codename-only releases" section near the end)

This is a REVIEW turn: report findings in this file only. Do not edit the artifact files.

Questions:

1. Id derivation: `"c-" + (version or codename or "untitled").lower().replace(".", "-").replace(" ", "-")`. Is the id stable and unique for codename-only releases? Can two distinct releases now collide (e.g. version "1.0 0" vs codename "1.0-0", or two releases with neither version nor codename)? Is a collision reachable through `releases_app.py`'s add/update validation, or only by hand-editing the DB?
2. `_ver()` now catches `(ValueError, AttributeError)`. Does that mask any error it should not (e.g. a non-str non-None type), and does every `_ver` caller handle the `None` return?
3. The sort tiebreaker changed from `r[1]` to `r[1] or ""`. Does this alter the relative ordering of any EXISTING all-versioned ledger (it must not), and does it fully close the None-vs-str `TypeError` for ties on the primary key?
4. `md_drift()`: codename-only rows now render by codename and sort with `key=lambda v: v or ""`. Two codename-only releases share the `None` dict key in `db = {c["version"]: ...}` so only one survives — is that acceptable for a drift banner, or a real undercount worth a follow-up issue?
5. Are there REMAINING NULL-version sites in export_timeline.py or its consumers (utils/leaderboard.sh, the RELEASES.html template's use of `version`, `strip_entries()`'s `f"v{c['version']}"` which renders "vNone")? Crash vs cosmetic — classify each.
6. Tests: does the new gh103 section actually pin the four fixes (would each one, reverted alone, fail at least one assertion)? Name any fix left unpinned.

Flag anything wrong, missing, incorrectly scoped, or over/under-engineered. Be concrete and cite file:line. Acceptance criteria from #250: preview + leaderboard succeed on NULL-version ledgers; stable unique ids for codename-only releases; regression test coverage.

Write your verdict below and change the STATUS to Approved/Closed if it passes.

## Log

### commandcode — Reviewer · r1 · 2026-08-25
VERDICT: PASS
Basis: Reviewed all six questions against utils/timeline/export_timeline.py, utils/py/releases_app.py, utils/timeline/RELEASES.html, and utils/leaderboard.sh. The four crash fixes are correct, non-invasive for existing all-versioned ledgers, and jointly pinned by the new gh103 assertions. Remaining items are cosmetic/latent and correctly out of scope for a crash hotfix; three follow-ups flagged (id collision, md_drift dict-key undercount, strip_entries "vNone").

#### Evaluation of Questions & Graded Findings

1. **[Pass, with follow-up] Id derivation — not collision-free, and the collision IS reachable through the CLI.**
   `"c-" + (version or codename or "untitled").lower().replace(".", "-").replace(" ", "-")`
   collapses `version="1.0 0"` → `c-1-0-0` and `codename="1.0-0"` (codename-only) → `c-1-0-0`.
   `--version` has no shape validation (`validate_release_fields` only checks non-empty + uniqueness,
   releases_app.py:1662-1678), and `--codename` is optional, so both forms are add-able. Two rows
   with neither version nor codename (`--codename` omitted) both render `c-untitled`, and two
   codename-only rows with the same codename collide too. The DB's `UNIQUE(repo_id, version)` does
   not help: NULL versions are exempt in SQLite, and the colliding pairs are version-NULL-vs-versioned
   or two-NULLs. Severity: cosmetic only — `id` is a DOM `id` / scroll anchor, never a join key.
   Acceptance criterion "stable unique ids" is met for the *fixture* cases but not for
   adversarial-yet-reachable inputs. **Follow-up warranted** (e.g. append the GID when the slug is
   ambiguous, or forbid version/codename shapes that normalize to the same id).

2. **[Pass] `_ver()` catch — technically over-broad, practically unreachable.** `except (ValueError,
   AttributeError)` also swallows `_ver(5)` → `None` (a non-str raises AttributeError on `.split`),
   masking a latent TypeError. In practice `version` is a SQLite TEXT column (always `str | None`),
   so this cannot fire through the exporter. Every `_ver` caller handles `None`: `in_md_band` L393-395
   and both band-bound calls L398-399 gate on `lo and hi`.

3. **[Pass] Sort tiebreaker — correct and non-invasive.** Verified `sorted(["9.9.9", None])` raises
   TypeError and `key=lambda v: v or ""` fixes it. For an all-versioned ledger every `r[1]` is a
   truthy str, so `r[1] or ""` == `r[1]`; ordering is unchanged. The None-vs-str tie TypeError is
   fully closed. The gh103 fixture's versioned-no-target `9.9.9` row deliberately forces the tie.

4. **[Pass, with follow-up] `md_drift()` dict-key None — real undercount, but only in the drift
   banner.** Confirmed `{None: ..., None: ...}` keeps one entry, so `db = {c["version"]: ...}` (L413)
   collapses N codename-only releases to one None key; `db_only` and `flipped` undercount them. The
   `sorted(db_only, key=lambda v: v or "")` fix (L427) is correct for what survives. This is a
   warning-banner count, not exported data — acceptable for the hotfix, but **worth a follow-up** to
   key `db` by `id`/GID instead of `version`.

5. **[Pass] Remaining NULL-version sites — one cosmetic leftover, no crashes.**
   - `strip_entries()` L311/L321 `f"v{c['version']}"` renders `"vNone"` for a *shipped* codename-only
     release (`justFinished`) or an unshipped-with-target one (`whatsNext`). **Cosmetic, unfixed.**
   - `RELEASES.html` L563/L579 `esc(rel.version)` and `esc(rel.version)` in `data-v`: `esc()` maps
     `null`→`''` (L492-494), so no `"None"` text and no crash. **Cosmetic, already safe.**
   - `utils/leaderboard.sh` consumes only `ratedTasks` (no `version` key), so it never touches
     NULL versions. **No issue.**

6. **[Pass] Tests — all four crash fixes are jointly pinned.** The single `--json succeeds on a
   NULL-version ledger` assertion (gh103:255) exits non-zero if *any one* of the four sites regresses,
   because each original site raised (id `.lower()` on None, `_ver` `.split` on None, mixed-None sort,
   mixed-None `sorted(db_only)`) and would abort `build_payload` before JSON is written. The fixture
   exercises all three None paths: two codename-only rows + the versioned `9.9.9` tiebreaker forcing
   the sort compare, and `RELEASES.md` lacking the codename rows forces `md_drift`'s `db_only` path.
   The id-derivation correctness is separately pinned by `unique, non-empty ids` and `c-night-owl`
   (gh103:267-268). **Left unpinned (correctly, cosmetic):** id-collision resistance (Q1) and
   `strip_entries` `"vNone"` (Q5).

---
**Verdict:** Approved (STATUS: Approved). Relay closed; no further turn needed. Follow-ups to file:
(1) id-collision resistance for adversarial version/codename shapes, (2) `md_drift` dict-keyed-by-version undercount, (3) `strip_entries` `"vNone"` cosmetic.

<!-- ▽ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK ▽ -->
▶ TAKE YOUR TURN (commandcode)
<!-- △ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK △ -->
