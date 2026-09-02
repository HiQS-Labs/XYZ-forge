---
Goal: Adjudicate the GH-349 Phase 2 parser fixes (LTVera-Pandas #322 review of PR #350)
Date: 2026-08-31
Branch: fix/gh-349-releases-roadmap-vendored
Reviewer: agy
NEXT: Reviewer
STATUS: Approved
---

# Context

Branch `fix/gh-349-releases-roadmap-vendored` (PR #350) generalises this repo's releases
roadmap layer so a **vendored `.xyz/` install in another org** can run `releases roadmap sync`
against a link-style `ROADMAP.md`. Phase 1 shipped that. The reporting repo
(`BinoidCBD/LTVera-Pandas`, issue #322) then reviewed the PR and found four defects, one
blocking. Phase 2 — the most recent commit, `4265244e` — fixes all four.

You are reviewing **Phase 2 specifically, and the whole branch as it now stands.**

## Read these, in this order

1. `PROJECT/2-WORKING/GH-349-RELEASES-ROADMAP-VENDORED.md` — the PDDA doc; its "Phase 2 —
   Post-review hardening" section states each defect, the fix, and the reasoning.
2. The Phase 2 diff:  `git show 4265244e`
3. The whole branch diff: `git diff origin/development...HEAD`
4. `utils/py/releases_app.py` — the helpers `_is_ledger_bullet`, `_roadmap_gh_number`,
   `_is_doc_pointer`, `_roadmap_issue_url` (all immediately above `parse_roadmap_ledger`),
   `parse_roadmap_ledger` itself, and `cmd_roadmap_sync`'s `roadmap-empty-parse` guard.
5. `test/gh349-releases-roadmap-vendored.sh` — sections 6 and 7 are the new ones.
6. This repo's own `ROADMAP.md` (the corpus the parser already served before this branch).

## What Phase 2 claims to have fixed

- **Blocking.** Phase 1 replaced an anchored `^GH-(\d+)` key match with a whole-title
  `re.search(r"\bGH-(\d+)\b", title)`. That harvested a key out of titles that merely *cite*
  an issue. Over this repo's own 72 bold-style ledger entries it changed two:
  `#129/#130/#131 · Wave 1 …` → `129`, and `Execution checklist for GH-111 + GH-108` → `111`.
  The second collides with the real `GH-111 · retire manifest FREEZE` entry, so
  `cmd_roadmap_sync`'s `roadmap-duplicate-gh` guard refused outright — the branch could not
  sync the ledger this harness ships with. Fixed by `_roadmap_gh_number()` (anchored) plus
  `_ROADMAP_MULTI_KEY_RE` (umbrella titles carry no key). The `#N —` prefix form is KEPT.
- `doc_path` was being filled with a GitHub URL whenever a bullet linked to its issue rather
  than a document (5 of 51 rows in the reporting repo). Fixed by `_is_doc_pointer()`.
- `issue_url` was `URL_EXTRACT_RE.search(raw)` over the whole entry block, so a hook citing
  other work in passing re-keyed the entry: `GH-94` → a **different repository's** issue #2,
  `GH-68` → a PR, and in this repo `GH-61` → child issue #62. Fixed by `_roadmap_issue_url()`.
- `- [` also matched markdown task-list items, so `- [ ]` / `- [x]` parsed as rows with an
  empty or `"x"` title. Fixed by `_is_ledger_bullet()`.

## Questions — answer each one, numbered, with `file:line` citations

1. **Is the anchored key rule correct and complete?** `_roadmap_gh_number()` returns `None`
   when `_ROADMAP_MULTI_KEY_RE` matches. Is `^(?:GH-|#)\d+\s*[/,+&]\s*(?:GH-|#)?\d+` the right
   separator set? Name any real ledger title shape that either (a) should carry a key but now
   gets `None`, or (b) should carry none but still gets one. Check both this repo's `ROADMAP.md`
   and the fixtures in the suite.

2. **Was keeping the `#N` prefix form correct?** Phase 2 kept it because the reporting repo has
   six legitimate `#N — …` titles. Does keeping it reintroduce any ambiguity against the
   umbrella guard, given `#129/#130/#131` is exactly that form?

3. **Is `_roadmap_issue_url()`'s precedence right?** It takes (a) the bullet's own link target
   if it is a GitHub URL and its number matches `gh_number` (or `gh_number` is `None`), else
   (b) the first URL in the block whose number equals `gh_number`, else (c) if `gh_number` is
   `None`, the first URL on the FIRST LINE only, else `None`. Is returning `None` — rather than
   a best-effort URL — the right call for an entry like `GH-68` whose block contains only PR
   URLs? Is branch (c) safe, or should an un-numbered entry also refuse?

4. **Is `(?:issues|pull|pulls)` correctly left in `URL_EXTRACT_RE`?** Phase 2 argues the
   pre-Phase-1 ledger regex already accepted `pull`, so anchoring — not narrowing — is the fix,
   and `test/gh349` pins external-org PR extraction. But `URL_EXTRACT_RE` has a second caller at
   `utils/py/releases_app.py:1886` (the legacy `GH_URL` import field). Does widening it there
   change behaviour in a way that matters, and is that change acceptable or a silent regression?

5. **Is `_is_doc_pointer()` sound?** It requires a non-empty target with no `://`, not starting
   `//`, whose pre-`#` part ends `.md`. Any link target that is a genuine doc pointer but is now
   rejected, or a non-doc that slips through? Also check the two `doc` regexes just above it —
   Phase 2 restored `#anchor` tolerance that Phase 1 had silently narrowed away. Did it restore
   the ORIGINAL behaviour, or something subtly different?

6. **Is `_is_ledger_bullet()` used consistently?** It now governs both the entry opener and the
   block-boundary lookahead. Confirm a task-list item appearing MID-BLOCK is absorbed as
   continuation text rather than splitting an entry — and say whether that is the right call.

7. **Does the `roadmap-empty-parse` guard (Phase 1, `cmd_roadmap_sync`) still hold after Phase 2?**
   Its ledger-content scan re-reads the file with its own `^##\s+Ledger\s*$` detection, separate
   from `parse_roadmap_ledger`'s. Are those two detections guaranteed to agree? If they can
   diverge, the guard can miss and the table gets deleted — the exact failure the branch exists
   to prevent. Also: the guard has no override, so once `roadmap_items` has rows a deliberately
   emptied ledger can never be synced back to empty. Is that acceptable, or does it need an
   `--allow-empty` escape hatch?

8. **Are sections 6 and 7 of the suite real coverage or theatre?** Section 7 parses this repo's
   own `ROADMAP.md` on every run and fails on any duplicate GH key — the gap that let the
   blocking regression land green. Is that the right guard? Would it actually have caught the
   Phase 1 regression? What case is still uncovered?

9. **Anything wrong, missing, over- or under-engineered in the branch as a whole** —
   `validate.sh` registry entry, `relay-automation/hooks/security-scan-baseline.txt` addition,
   CHANGELOG entry, and the PDDA doc. The registry + baseline additions were needed because
   `test/gh306-registry-bidirectional.sh` and `test/security-scan.sh` were BOTH red on the
   branch before Phase 2. Is baselining the standard `ok()` eval idiom the right move, or should
   the suite avoid it?

## Verification already run on this branch

- `test/gh349-releases-roadmap-vendored.sh` — 30 passed, 0 failed
- `bash validate.sh --auto origin/development` — **305 / 305 suites passed**, exit 0
- `utils/pdda/pdda.sh run` — 0 errors, 33 warnings (all pre-existing categories)

Do not take these as proof of correctness — Phase 1 was green too, and shipped a blocking
regression. Read the code.

## Known and deliberately out of scope

The reporting repo's `ROADMAP.md` has **two** entries keyed `GH-199`, so `roadmap sync` there
still refuses with `roadmap-duplicate-gh`. That is a data condition in that repo, correctly named
by the existing guard. Do not treat it as a defect in this branch — but DO say if you think the
one-row-per-GH-key constraint is itself the wrong design.

## Your output

Answer all nine questions with `file:line` citations. Be concrete where you disagree. Rank any
findings blocking / major / minor. Then write your verdict below and set `STATUS:` to
`Approved` if the branch is sound as it stands, or leave it `Open` with changes requested.

<!-- ▽ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK ▽ -->
▶ TAKE YOUR TURN (agy)
<!-- △ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK △ -->

## Log

### agy (Reviewer) — round 1 — 2026-08-31

# Phase 2 Review Findings & Adjudication

## Question Responses

### 1. Anchored Key Rule Correctness & Completeness
- **Citations:** `utils/py/releases_app.py:2813-2833`, `ROADMAP.md:188-189`, `test/gh349-releases-roadmap-vendored.sh:139-143,154-158`
- `_roadmap_gh_number()` anchors the key extraction to the start of the title via `_ROADMAP_KEY_RE = re.compile(r"^(?:GH-|#)(\d+)\b")` and checks `_ROADMAP_MULTI_KEY_RE = re.compile(r"^(?:GH-|#)\d+\s*[/,+&]\s*(?:GH-|#)?\d+")` to treat multi-issue headings as un-keyed umbrella entries.
- **Separator set analysis:**
  - The separator set `[/,+&]` successfully catches discrete multi-key enumerations such as `#129/#130/#131` (`ROADMAP.md:189`), `GH-42 + GH-43`, `GH-111, GH-108`, and `GH-1 & GH-2`.
  - **Edge case observed:** Range syntax (e.g. `..`, `...`, `–`, `-`, `to`) is not included in `_ROADMAP_MULTI_KEY_RE`. In `ROADMAP.md:188`, the umbrella entry `- **GH-135..140 · Wave-1 follow-ups...**` is parsed with `gh_number = 135` because `\b` splits at the `.` and `_ROADMAP_MULTI_KEY_RE` does not match `..`. While this matches pre-Phase-1 behavior (`re.match(r"^GH-(\d+)\b")` also extracted `135`), `GH-135..140` conceptually represents a 6-issue range (#135–#140) and should carry `None`.
  - **Single-key safety:** No valid single-issue title (e.g. `GH-111 — description`, `#503 — description`) is mistakenly rejected or nulled, because `_ROADMAP_MULTI_KEY_RE` requires a trailing digit sequence after the delimiter.

### 2. Retention of `#N` Prefix Form
- **Citations:** `utils/py/releases_app.py:2813-2833`, `test/gh349-releases-roadmap-vendored.sh:139,160-162`
- Keeping the `#N` prefix form is correct and necessary for foreign repos (such as `BinoidCBD/LTVera-Pandas`) that use `#N — ...` titles rather than `GH-N`.
- Retaining `#N` introduces no ambiguity against umbrella titles: `_ROADMAP_MULTI_KEY_RE` explicitly handles `(?:GH-|#)` and is evaluated prior to `_ROADMAP_KEY_RE`. In `#129/#130/#131 · Wave 1 …`, `_ROADMAP_MULTI_KEY_RE` matches and returns `None`, while single `#N` titles (`#503 — ...`) pass through to `_ROADMAP_KEY_RE` and return `503`.

### 3. Precedence & Fallbacks in `_roadmap_issue_url()`
- **Citations:** `utils/py/releases_app.py:2849-2869`, `test/gh349-releases-roadmap-vendored.sh:137-138,163-174`
- Precedence order:
  1. Bullet's direct link target (`link_target`) if it is a GitHub issue/PR URL matching `gh_number` (or `gh_number` is `None`).
  2. First URL in `raw` whose issue/PR number matches `gh_number`.
  3. If `gh_number` is `None`, the first URL on the first line only (`raw.splitlines()[0]`).
  4. Else `None`.
- Returning `None` for entries like `GH-68` (where the block only cites PRs or child issues with different numbers) is strictly the correct decision: "No URL beats a wrong URL". Storing a disparate PR or foreign issue as `issue_url` creates incorrect tracking associations in downstream projections.
- Branch (c) is safe: restricting un-numbered entries to URLs on the first line ensures primary entry links (`- [Unnumbered Item](...) -> [#99](...)`) are captured while ignoring incidental references and citations in continuation/hook lines.

### 4. `(?:issues|pull|pulls)` in `URL_EXTRACT_RE` and Legacy Caller at Line 1884
- **Citations:** `utils/py/releases_app.py:116`, `utils/py/releases_app.py:1881-1892`
- `URL_EXTRACT_RE` is defined as `re.compile(r"https://github\.com/[^/\s]+/[^/\s]+/(?:issues|pull|pulls)/[0-9]+")`.
- Line 1884 caller is `_import_legacy_block` in `cmd_import` (the one-time migration path for legacy markdown `RELEASES.md`).
- Widening `URL_EXTRACT_RE` to accept PR URLs (`pull`/`pulls`) allows legacy blocks that recorded PR URLs in `GH_URL:` to populate `gh_release_url` rather than being dropped to `gh-url-unparsed`. Because PR URLs represent valid GitHub release pointers and `cmd_import` records grandfather receipts for normalization, this change is a clean and safe improvement with zero adverse impact on existing tables.

### 5. Soundness of `_is_doc_pointer()` and `#anchor` Tolerance
- **Citations:** `utils/py/releases_app.py:2836-2846`, `utils/py/releases_app.py:2914-2921`
- `_is_doc_pointer()` is sound: it rejects empty strings, absolute URLs (`://`), and protocol-relative URLs (`//`), while verifying that the pre-anchor path ends with `.md`.
- Phase 2 restored `#anchor` tolerance cleanly:
  - `re.search(r"\]\((PROJECT/[^)#]+\.md)(?:#[^)]*)?\)", raw)`
  - `re.search(r"\]\(([^)#\s]+\.md)(?:#[^)]*)?\)", raw)`
  - `link_target.strip().split("#", 1)[0]` in the `_is_doc_pointer` branch.
- This improves upon `origin/development`: original behavior matched only `PROJECT/` docs; Phase 2 properly generalizes to relative `.md` paths across arbitrary repository layouts (`docs/plans/...`, etc.) while cleanly stripping anchors from `doc_path`.

### 6. Consistent Usage of `_is_ledger_bullet()` & Mid-Block Checkboxes
- **Citations:** `utils/py/releases_app.py:2821-2826`, `utils/py/releases_app.py:2892-2897`, `test/gh349-releases-roadmap-vendored.sh:135-136,149-153`
- `_is_ledger_bullet()` is consistently applied for entry starts (`if inledger and sec and _is_ledger_bullet(line):`) and block-boundary lookahead (`while j < n and not (_is_ledger_bullet(lines[j]) ...)`).
- A task-list item (`- [ ]` / `- [x]`) occurring mid-block returns `False` from `_is_ledger_bullet()`, allowing the loop to continue and absorb the checkbox as continuation text into the entry's `raw_text`.
- This is the right behavior: subtask checklists embedded inside an entry's body are part of that item's narrative context, not standalone roadmap entries. Standalone top-level checkboxes are ignored.

### 7. Durability of the `roadmap-empty-parse` Guard
- **Citations:** `utils/py/releases_app.py:2880-2888`, `utils/py/releases_app.py:3258-3277`
- The `## Ledger` header detection and section exit regexes in `cmd_roadmap_sync` (`re.match(r"^##\s+Ledger\s*$", line.strip())` and `re.match(r"^##\s+", line)`) match `parse_roadmap_ledger` exactly.
- Even if ledger content were absent or unrecognized, the guard additionally queries the database: `(_table_exists(conn, "roadmap_items") and conn.execute("SELECT 1 FROM roadmap_items LIMIT 1").fetchone())`. If the table contains existing rows, parsing 0 entries will always refuse with `roadmap-empty-parse` rather than truncating `roadmap_items`.
- Omission of an `--allow-empty` flag is acceptable: roadmap sync is designed as an idempotent mirror of active backlog items. Entirely emptying a ledger is not a valid routine sync flow; administrative DB resets or direct SQL operations exist if an operator ever intentionally clears the table.

### 8. Regression Suite Coverage in Sections 6 & 7
- **Citations:** `test/gh349-releases-roadmap-vendored.sh:120-196`
- Sections 6 and 7 represent substantive, high-value regression coverage:
  - Section 6 explicitly validates the 5 review regression cases on isolated fixtures.
  - Section 7 parses `ROADMAP.md` directly and asserts `Counter(gh_number) > 1` is `"none"`. In Phase 1, `Execution checklist for GH-111 + GH-108` extracted `111`, creating a duplicate key with `GH-111` that caused `roadmap sync` to fail. Section 7 would have directly caught the Phase 1 regression.
- **Uncovered edge cases:** Umbrella ranges (`GH-135..140`) where extracting `135` does not collide with an existing row, and cases where an incorrect number is extracted without causing a duplicate.

### 9. Branch Architecture, Registry, Baseline, and Documentation
- **Citations:** `validate.sh:338-348`, `relay-automation/hooks/security-scan-baseline.txt:87`, `CHANGELOG.md:5-9`, `PROJECT/2-WORKING/GH-349-RELEASES-ROADMAP-VENDORED.md:91-180`, `RELEASES-DB-FAQS.md:21-36`
- Registering `gh349-releases-roadmap-vendored.sh` in `validate.sh` satisfies the bidirectional registry contract (`test/gh306-registry-bidirectional.sh`).
- Baselining the test script's `ok()` helper in `security-scan-baseline.txt:87` is consistent with the repository's convention across all other test suites (lines 28-33, 38-40, 83-89).
- Documentation in `CHANGELOG.md`, `RELEASES-DB-FAQS.md`, and the PDDA document is comprehensive, accurate, and reflects the final state of the implementation.

---

## Findings Summary

| Finding | Severity | Description |
|---|---|---|
| 1. Range syntax umbrella headings | **Minor** | `_ROADMAP_MULTI_KEY_RE` does not include range delimiters (`..`, `...`, `–`, `to`), resulting in `GH-135..140` (`ROADMAP.md:188`) extracting key `135`. Pre-existing behavior, non-blocking. |

---

VERDICT: PASS
Basis: All four Phase 2 review defects (duplicate GH key collision on this repo's ledger, doc_path issue URL pollution, issue_url mis-anchoring to foreign references, and task-list checkbox ingestion) are resolved cleanly with solid regression guards. The test suite passes 30/30 assertions.


