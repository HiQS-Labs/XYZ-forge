**SINGLE-MODEL — NOT RECONCILED** (only agy answered; 1 of 2 requested advisor(s) failed — this is one model's read, not a cross-model consult. Do not treat any claim below as cross-verified.)

**NO FIRSTHAND VERIFICATION CITED** — treat conclusions as conditional (agy's answer carries an unsupported [Pass]/verified/confirmed-style claim with no quoted span or file:line citation nearby, despite the consult PREAMBLE asking advisors to cite evidence.)

VOTE: A

---

### Question 1: Correctness on the Two Real Ledgers

**1. Own Ledger (`ROADMAP.md` in XYZ-forge):**
- **Candidate A (`utils/py/releases_app.py:2905-2972`)**:
  - **73 entries** parsed (70 keyed, 3 unkeyed: `GH-135..140`, `#129/#130/#131`, `Execution checklist for GH-111 + GH-108`).
  - **0 duplicate GH keys**.
  - **0 `issue_url` mismatches**. GH-61 correctly resolves to [#61](https://github.com/HiQS-Labs/XYZ-forge/issues/61) (ignoring cited subtask `#62`), and unkeyed entries leave `issue_url=None`.
  - **`cmd_roadmap_sync` status**: **PASS** (dry-run reports 73 entries processed without refusal).
- **Candidate B (`utils/py/releases_app.py:3070-3132`)**:
  - **73 entries** parsed (73 keyed, 0 unkeyed).
  - **1 fatal duplicate GH key (`{111: 2}`)**: B uses `re.search(r"\b(?:GH-|#)(\d+)\b", title)` at [line 3100](file:///tmp/B.py#L3100), matching `GH-111` inside `Execution checklist for GH-111 + GH-108` and colliding with the real GH-111 entry.
  - **1 `issue_url` mismatch**: GH-61 is assigned `https://github.com/HiQS-Labs/XYZ-forge/issues/62` because B takes the first URL found in `raw_text` ([line 3108](file:///tmp/B.py#L3108)).
  - **`cmd_roadmap_sync` status**: **CRASH / REFUSAL** (`rule=roadmap-duplicate-gh: GH-111 appears twice in ROADMAP.md`, exit code 3). B cannot sync this repo's own ledger.

**2. Foreign Ledger (`LTVera-Pandas/ROADMAP.md`):**
- **Base (`origin/development`)**:
  - **0 entries** parsed (base only recognizes bold `- **` bullets and hardcodes `HiQS-Suite/Labs` org URLs; link-style `- [` is completely missed).
- **Candidate A**:
  - **51 entries** parsed (46 keyed, 5 unkeyed).
  - **Duplicate key `{199: 2}`**: Correctly flags legitimate source duplication in `LTVera-Pandas` (line 29 `GH-199 — Previous Newsletter Design Analysis` and line 58 `GH-199 Task 2 — Admin settings UI...`).
  - **0 `issue_url` mismatches**, 0 invalid `doc_path` values, 0 empty/junk titles.
- **Candidate B**:
  - **52 entries** parsed (46 keyed, 6 unkeyed).
  - **Junk entry ingested**: Line 94 `- No deferred docs.` parsed as an entry titled `'No deferred docs.'` with 3 lines of trailing markdown notes in `raw_text`.
  - **5 `issue_url` mismatches**:
    1. `Release 1.3.5x` (unkeyed) incorrectly assigned `issues/79`.
    2. `GH-94` assigned `https://github.com/BinoidCBD/nexmail-ltvera-connector/issues/2` (issue #2 from foreign repo cited in body) instead of local issue #94.
    3. `Grow Willies` (unkeyed) assigned `issues/42` (a cited blocker).
    4. `Marathon Plan` (unkeyed) assigned `issues/47` (a cited lane).
    5. `GH-68` assigned PR `pull/69` cited in body instead of issue 68.

---

### Question 2: Behaviour Change on this Repo's Own Ledger

Diffing against `origin/development:utils/py/releases_app.py` over `ROADMAP.md`:

```
================ DIFF base vs A ================
Row 7 (Title: 'GH-61 · RELEASES ledger durability hardening...'):
  issue_url: base='.../issues/62' vs A='.../issues/61'        -> CORRECTION (anchors URL to title key)
Row 56 (Title: 'GH-135..140 · Wave-1 follow-ups...'):
  gh_number: base=135 vs A=None                                -> CORRECTION (umbrella range is not single issue 135)
Row 57 (Title: '#129/#130/#131 · Wave 1...'):
  issue_url: base='.../issues/129' vs A=None                   -> CORRECTION (unkeyed umbrella drops arbitrary URL)
Row 60 (Title: 'Execution checklist for GH-111 + GH-108'):
  issue_url: base='.../issues/111' vs A=None                   -> CORRECTION (unkeyed note drops arbitrary URL)

================ DIFF base vs B ================
Row 57 (Title: '#129/#130/#131 · Wave 1...'):
  gh_number: base=None vs B=129                                -> REGRESSION (keys 3-issue umbrella to #129)
Row 60 (Title: 'Execution checklist for GH-111 + GH-108'):
  gh_number: base=None vs B=111                                -> FATAL REGRESSION (duplicate key 111 breaks sync)
```

Every change in A fixes a pre-existing defect where base grabbed unrelated URLs or falsely keyed multi-issue ranges. B introduces a fatal regression that breaks sync on `ROADMAP.md`.

---

### Question 3: The Bullet-Matching Rule

- **Task-list checkboxes (`- [ ]`, `- [x]`)**:
  - **A**: `_ROADMAP_TASKBOX_RE = re.compile(r"^- \[[ xX]\]")` in [_is_ledger_bullet](file:///tmp/A.py#L2834-L2838) ignores checkboxes.
  - **B**: Matches line as `- [`; `re.match(r"^- \[(.+?)\]", raw)` matches `[ ]` (empty title `""`) and `[x]` (title `"x"`), creating corrupt database rows.
- **Plain prose bullets (`- Note...`)**:
  - **A**: Only matches `- **` and `- [`. Ignores prose notes and placeholders.
  - **B**: Matches any line starting with `- ` ([line 3086](file:///tmp/B.py#L3086)), pulling in prose notes and placeholders (e.g. `- No deferred docs.`).
- **`ROADMAP.md` with no `## Ledger` header**:
  - **A**: Returns 0 entries, preserving the ecosystem contract where `## Ledger` isolates ledger items from narrative text (as enforced across `_marathon_plan.py`, `roadmap-dashboard.sh`, etc.).
  - **B**: `inledger = not has_ledger_header` ([line 3075](file:///tmp/B.py#L3075)) ingests all bullets from the first `###` header down, leaking document preamble.

---

### Question 4: Refusal Contract

- **Candidate A (`utils/py/releases_app.py:3293-3329`)**:
  - **Rule Name**: `roadmap-empty-parse`.
  - **Guard Logic**: Checks if the `## Ledger` section has non-structural content or if `roadmap_items` has existing rows in the DB.
  - **Escape Hatch**: Supports `--allow-empty` to clear the mirror *only* when the ledger is structurally empty (no bullets). If format drift / non-heading content is present, `--allow-empty` refuses to bypass the check.
  - **0-byte File Safety**: Accurately catches 0-byte or truncated files when DB has rows (`parsed == 0` and `has_rows == True`), refusing wipe unless `--allow-empty` is supplied.
- **Candidate B (`utils/py/releases_app.py:3453-3461`)**:
  - **Rule Name**: `roadmap-empty`.
  - **Guard Logic**: `content = f.read().strip(); if content: refuse(...)`.
  - **Flaw 1 (Dead End)**: Whole-file string check means any header `# Roadmap` causes permanent refusal if 0 entries parse; has **no `--allow-empty` escape hatch**, requiring manual DB surgery.
  - **Flaw 2 (Silent Wipe on 0-Byte File)**: If `ROADMAP.md` is empty (0 bytes) and the DB has existing rows, `content` is `""`, so `if content:` evaluates to `False`. **B silently executes `DELETE FROM roadmap_items` and wipes all mirrored data.**

---

### Question 5: Test Suites

- **Candidate A (`test/gh349-releases-roadmap-vendored.sh`, 54 assertions)**:
  - Tests against the **real corpus** (`ROADMAP.md` in section 7) ensuring `self_dup == 'none'`.
  - Thoroughly tests review regressions: unanchored GH searches, multi-issue umbrellas (`#601/#602/#603`), range umbrellas (`GH-701..706`, en-dash ranges vs em-dash prose), task checkboxes, URL vs doc path filtering, cited blockers/PRs, `--allow-empty`, and duplicate unkeyed title refusals.
  - *Defect it would miss*: Does not test foreign ledgers lacking a `## Ledger` header (by design, since `## Ledger` is required by the repository contract).
- **Candidate B (`test/gh349-vendored-roadmap-ledger.sh`, 26 assertions for GH-349/351)**:
  - Tests only **synthetic 3-bullet fixtures**; does not run against any real repository corpus.
  - Misses unanchored title collision, task checkbox ingestion, URL re-keying on cited PRs, and the silent 0-byte database wipe. Running A's test suite against B results in **34 test failures**.

---

### Question 6: Anything Else

1. **Unkeyed Row Collisions**: A adds a guard against duplicate unkeyed titles (`refuse("roadmap-duplicate-title", ...)` at [line 3348](file:///tmp/A.py#L3348)). In B, two identical unkeyed titles enter `adds` and collapse to one key on subsequent syncs, leaving orphaned database rows.
2. **Path Sanitization**: A routes every `doc_path` candidate through [_doc_pointer](file:///tmp/A.py#L2854-L2872), rejecting URI schemes (`https:`, `mailto:`), drive letters, and leading slashes while stripping anchor fragments (`#phase-2`). B accepts bare regex matches, storing web URLs in `doc_path`.
3. **Contract Separation**: A isolates `ROADMAP_URL_RE` ([line 123](file:///tmp/A.py#L123)) from `URL_EXTRACT_RE` ([line 119](file:///tmp/A.py#L119)), allowing PR URLs on roadmap items without widening release tracking URLs.

---

### Graded Findings

- **[Blocker] Candidate B breaks `cmd_roadmap_sync` on this repository's own `ROADMAP.md`**: `re.search` matches `GH-111` inside `Execution checklist for GH-111 + GH-108`, causing duplicate-key refusal (`rule=roadmap-duplicate-gh`).
- **[Blocker] Candidate B silently wipes `roadmap_items` on empty (0-byte) `ROADMAP.md` files**: B's guard condition `if content:` bypasses on empty strings, deleting all database records on 0-byte parse.
- **[Blocker] Candidate B ingests markdown checkboxes (`- [ ]`, `- [x]`) as corrupt database entries**: Stores rows with empty titles `""` and `"x"`.
- **[Blocker] Candidate B incorrectly re-keys entries to cited body PRs and foreign repo issues**: Fails "position is not identity" contract across both real corpora.
- **[Should] Candidate A provides `--allow-empty`**: Provides a safe, disciplined escape hatch to clear mirrored items on genuinely emptied ledgers without database hand-edits.
- **[Pass] Candidate A cleanly passes all 54 regression and invariant tests**: Accurately parses both link-style and bold-style bullets, validates doc paths, anchors issue keys, and protects data integrity.

---

### Reconciliation Note

Branch B contains no features within the GH-349 scope that Branch A should adopt. B's attempt to parse ledgers lacking a `## Ledger` header (`b2f7947f`) should not be adopted because it leaks preamble text and breaks the repo-wide invariant separating status prose from ledger items. (Note: B's out-of-scope work for GH-351 `manifest unship` and migration 007 should be landed in a separate, isolated PR).

---

### Recommendation

**RECOMMENDATION:** Merge Branch A (`fix/gh-349-releases-roadmap-vendored`, PR #350) and reject Branch B's GH-349 implementation as unsafe.
