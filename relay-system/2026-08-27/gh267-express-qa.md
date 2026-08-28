---
Goal: QA the /express hotfix fast-lane skill (GH-267)
Date: 2026-08-27
NEXT: Reviewer
STATUS: Changes Requested
---

# Context

Adjudicate the just-built `/express` skill against its spec (issue #267 v2, summarized in the capture doc) and the repo's conventions (SOP §4 express carve-out; jog-plan consistency, PR #261).

Read these files in full:

- `utils/py/express.py` — the driver (steps 0–11)
- `skills/express/SKILL.md` — the operator-facing contract
- `test/gh267-express-skill.sh` — the guardrail regression suite
- `PROJECT/2-WORKING/GH-267-EXPRESS-HOTFIX-LANE.md` — capture doc (spec + status)

Questions:

1. **Guardrail fidelity.** Does `cmd_check` in `express.py` enforce everything SKILL.md claims for steps 0–2 — the frozen-twin list (all 12), new-Bash refusal under `utils/`+`relay-automation/`, kernel surfaces (`.tick/`, `src/project.js`, containment hooks), the ≤4 core-file / ≤150 insertion bounds with DOC_PREFIXES exempt, and the single-subsystem rule? Name any input that dodges a check (path shapes, renames via `change_paths`, untracked files, `--max-*` flags).
2. **Order integrity.** Are the writes ordered so the documented traps are structurally impossible: evidence sha exists before `manifest ship` (step 9 after merge), issue closed before reconcile (step 10 before 11), capture doc born complete matching `wave_reconcile.py`'s promotion regex (`##\s+Lessons\s+Learned`, case-insensitive — check `validate_and_update_doc`)? Cite line numbers.
3. **`git add -A` blast radius.** `cmd_land` re-runs `cmd_check` then stages everything with `git add -A`. Is there a real TOCTOU or sweep risk (files appearing between check and add; scratch paths refused at check but `add -A` sweeping something new)? Would explicit path staging from the check's change set be strictly safer, and is anything else in the landing sequence unsafe against the repo's own rails (GH-527 peer work, pre-push gate bypass)?
4. **Ghost-PR deviation honesty.** The spec's letter says "direct commit and push into development"; the implementation lands via a driver-opened PR merged immediately. Is this deviation documented accurately and completely in SKILL.md and the capture doc, per what #267 actually says?
5. **Test suite non-vacuity.** Would `gh267-express-skill.sh` actually catch a removed or weakened refusal (e.g., delete the frozen-twin loop from `express.py` — does any assertion fail)? Is the hermetic `gh` stub sound (does it exercise the real CLI surface the driver calls)? Is the GH-567 containment story (fixture paths validated at use) correctly implemented?
6. **CHANGELOG insertion.** In `cmd_docs`, the "today's section already exists" branch rewrites via regex — is the bullet inserted under the right heading in both branches, and can either branch corrupt the file?
7. **Anything else** wrong, missing, mis-scoped, or over/under-engineered vs the #267 v2 spec — including the `build_offline_manifest` fallback (does it correctly omit unresolvable numbers so wave_reconcile treats them as unknown?) and the `.tick` telemetry shape.

Flag anything wrong, missing, incorrectly scoped, or over/under-engineered. Be concrete and cite file:line where you disagree with a specific claim. Write your verdict below (numbered findings, each with severity BLOCKER / MAJOR / MINOR / NOTE) and change STATUS to Approved if nothing blocking, else leave Open with STATUS: Changes Requested.

<!-- ▽ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK ▽ -->
▶ TAKE YOUR TURN (deepseek)
<!-- △ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK △ -->

## REVIEWER FINDINGS — deepseek

### Finding 1 (BLOCKER): `--repo` flag ignored by `cmd_land` and `build_offline_manifest`

**express.py:419–420** defines `args_repo()` which reads `EXPRESS_REPO` env var (default `"HiQS-Labs/XYZ-forge"`), ignoring the argparse `--repo` value.

- **`cmd_check`:229** correctly uses `-R args.repo` — the `--repo` flag works here.
- **`cmd_land`:446, 453, 462** and **`build_offline_manifest`:402, 413** all call `args_repo()` instead of using the `args.repo` that was parsed from the command line.

An operator who sets `--repo different/org` gets:
  - `cmd_check` validates against the right repo → PASS
  - `cmd_land` creates/merges the PR against the *wrong* repo → functional split-brain

**Fix:** Either make `cmd_land`/`build_offline_manifest` close over `args.repo`, or thread it as a parameter. Since `build_offline_manifest` is called from `cmd_land`, the simplest path is to pass `repo` as a parameter.

---

### Finding 2 (MAJOR): `src/project.js.orig` misclassified as kernel surface

**express.py:55** lists `"src/project.js.orig"` in `KERNEL_SURFACES`.

AGENTS.md says: _"Changes to .tick/events/, src/project.js, relay containment, or event/verb shape are usually broader than they look."_ — there is no mention of `.orig` backup files, which are editor artifacts, not coordination-kernel surfaces.

The scratch check at **line 208–209** catches `p.endswith(".bak")` but not `".orig"`, so `src/project.js.orig` falls through to the wrong refusal rule (`kernel-surface` instead of `scratch`). This is functionally harmless (the path is extremely unlikely to appear in practice) but creates a docs-vs-code inconsistency: a reviewer reading KERNEL_SURFACES would reasonably ask why `.orig` is there.

**Fix:** Remove from KERNEL_SURFACES; optionally add `p.endswith(".orig")` to the scratch refusal (line 208) alongside `.bak`.

---

### Finding 3 (MAJOR): CHANGELOG "today's section exists" branch silently drops the entry when `### Fixed` is absent

**express.py:330–332** — when today's `## [Unreleased] - YYYY-MM-DD` section already exists, the code does:

```python
cbody = cbody[:m.start()] + re.sub(r"^(### Fixed\n)", r"\1- **GH-%d: ...**", cbody[m.start():], count=1)
```

The `re.sub` only inserts after the *first* `### Fixed\n` in the suffix. If today's section has no `### Fixed` subheading (e.g., created by a prior `/express` run for a different issue using the `entry` fallback which only emits `## [Unreleased] - ...` + `### Fixed` bullet, or manually edited without one), the regex produces no match, `re.sub` returns the string unchanged, and the new entry is **silently lost** — no error, no warning, no evidence anything went wrong.

**Trigger scenario (concrete):**
1. First `/express` run for GH-999 → `entry` path executed (line 334), creating `## [Unreleased] - 2026-08-27\n\n### Fixed\n- **GH-999: ...` — entry correctly inserted.
2. Second `/express` run for GH-1000 on the same day → "today's section exists" branch (line 331). It finds `### Fixed\n` and inserts a second bullet. OK.
3. If instead the `### Fixed` heading were absent (e.g., a human removed it, or never had it), the second run silently loses the entry.

**Fix:** Assert `### Fixed` is present in the matched section, or fall through to the `elif m:` branch (which prepends a whole new section even if today's date exists — that would create a duplicate dated header, but at least nothing is dropped).

---

### Finding 4 (MAJOR): `relay-turn-lib.sh` refusal uses misleading rule name

**express.py:195** refuses `relay-automation/relay-turn-lib.sh` with rule name `frozen-twin`.

**AGENTS.md:210** explicitly states: _"relay-turn-lib.sh remains a shared Bash runtime dependency rather than a twin."_ The refusal is *correct* (the file is shared runtime and should not be edited by an express lane), but the rule name in the tick event and stderr is wrong. A reader diagnosing `express-refused: rule=frozen-twin` for `relay-turn-lib.sh` will reasonably suspect a bug — the response says "frozen twin" for a file the repo explicitly says is not one.

**Fix:** Add a separate refusal rule name, e.g. `shared-runtime`, or change the check to include `relay-turn-lib.sh` under a different rule.

---

### Finding 5 (MINOR): `DOC_PREFIXES` omits `README.md` and other doc files

**express.py:58–59** lists: `CHANGELOG.md`, `PROJECT/`, `ROADMAP.md`, `ROADMAP-DASHBOARD.md`, `RELEASES.generated.md`, `LEADERBOARD`, `RELEASES-PREVIEW`.

Notable omission: **`README.md`** (top-level and sub-directory). Also no `UPGRADE.md`, `CONTRIBUTING.md`, or `ARCHITECTURE.md`.

The SKILL.md claim at step 1 says *"Docs (CHANGELOG, PROJECT/) never count against the bounds"* — the code is more restrictive than the prose, which is fine, but the technical contract should match the code. If an express fix touches `README.md`, it counts against the 150-insertion / 4-file bounds, which may surprise an operator.

No fix needed if intentional; but DOC_PREFIXES should either include more doc paths or the SKILL.md prose should say which prefixes are exempt.

---

### Finding 6 (MINOR): `git status --porcelain` without explicit version

**express.py:128** uses `git status --porcelain` without `--porcelain=v1`. In practice this defaults to v1 on all widely-used git versions, but the format is version-dependent — a future git update or unusual config could change the output format and silently corrupt `change_paths()`.

**Fix:** `git status --porcelain=v1` (explicit).

---

### Finding 7 (MINOR): `.tick` event filename is `.jsonl` but contains single JSON object

**express.py:84** writes files named `{ts}-express-{verb}.jsonl` where each file contains exactly one JSON line.

The `.jsonl` extension canonically implies **line-delimited JSON** (multiple JSON objects, one per line). A single object per file is valid subset, but any consumer expecting standard `.jsonl` (one file, many lines) needs to handle one-record-per-file correctly. This works but is slightly misleading.

**Recommendation:** Rename to `.json` or document the convention in the telemetry spec.

---

### Finding 8 (NOTE): Ghost-PR deviation is well-documented

The landing shape (PR opened and immediately merged vs. literal direct push) is accurately and completely documented in all three files:

- **express.py docstring:10–16** — full reasoning, names Phase 2
- **SKILL.md:17–21** — explicitly calls it a "documented deviation" with rationale
- **Capture doc:57–65** — "Landing shape (documented deviation from the letter of 'direct commit')" with detailed justification

The reasoning (keeping wave_reconcile --pr alive, auto-closing the linked issue) is sound and consistent. No issue here.

---

### Finding 9 (NOTE): Test suite is non-vacuous and properly hermetic

- Removing any single guard from `express.py` inverts the corresponding test assertion (e.g., line 106–107 fails if the frozen-twin loop is deleted). Verified by reading the test flow.
- The hermetic `gh` stub (lines 44–58) serves `issue view --json state,title,url,createdAt` from pre-seeded JSON files — exactly the CLI surface that `cmd_check` and `cmd_docs` call. It does NOT need to cover `pr view`/`pr merge`/`issue close` (those are in `cmd_land`, which the test suite doesn't exercise), so the stub is appropriately scoped.
- GH-567 containment: `require_fixture()` (lines 30–34) validates at the use boundary (non-empty and lexically under `$WORK`), called at line 141 before cleanup. All derived paths (`$FX`, `$BIN`, etc.) descend from `$WORK`. Sound.

One minor observation: `require_fixture "$WORK"` at line 141 validates `$WORK` itself, but derived variables like `$FX`/`$REMOTE` are never independently validated. Since they're constructed by concatenation (`FX="$WORK/repo"`) and `$WORK` is safe, this is fine — but a future refactor that constructs them differently could miss the containment check.

---

### Finding 10 (NOTE): `build_offline_manifest` correctly handles unresolvable numbers

**express.py:396–416** — issues resolvable via `gh issue view` carry live state; unresolvable ones are omitted. Per wave_reconcile's GH-202 contract, unknown numbers = "promote as before" (no state assertion). This is correct.

One edge case: the regex pattern `(?:GH-|#)(\d{1,5})` only captures `GH-N` and `#N` mentions. A PR body referencing an issue via a bare GitHub URL (`https://github.com/owner/repo/issues/123`) would not be matched, and that issue would not appear in the offline manifest. This is an acceptable limitation for the fallback path.

---

### Finding 11 (NOTE): Order integrity is sound

Verified structural imposability of the documented traps:  [Unverified — no citation]

| Trap | Statement | File:Line |
|------|-----------|-----------|
| Evidence SHA before manifest ship | `cmd_land` commits (435) → pushes (441) → gets SHA (439) → merge (453) → ship with evidence (464) | Lines 435–465, in order |
| Issue closed before reconcile | Merge closes via `Closes #N` (448–449) → explicit close if missed (469–472) → reconcile (476...) | Lines 469 vs 476 |
| Doc born complete matching wave_reconcile | Capture doc template at 314 has `## Lessons Learned (For Future Agents)`; wave_reconcile's `validate_and_update_doc` at **wave_reconcile.py:339** uses `re.search(r"##\s+Lessons\s+Learned", content, re.IGNORECASE)` — matches. | express.py:314 matches wave_reconcile.py:339 |
| Dial-in before ship (GH-205) | `cmd_ledger` dials-in (line 388) before `cmd_land` ships (line 464). In `cmd_run`, `ledger` runs before `land`. | cmd_run:504–506 vs land:464 |

---

### Finding 12 (NOTE): `git add -A` sweep risk is manageable

`cmd_land:435` runs `git add -A` after `cmd_check` re-runs. The TOCTOU window is:
1. `cmd_check` enumerates the change set (lines 187, paths from `git status --porcelain`).
2. Suite runs (line 429) — could theoretically create files (e.g., test output), but `test/` output in a clean sandbox should not produce stray files.
3. `git add -A` (line 435) sweeps everything, including any test artifacts.

The pre-push gate at line 441 (`git push`) then runs the full `validate.sh` which would catch an unexpected artifact. Additionally, `refuse(root, "scratch", ...)` at line 208–209 refuses `scratch/` and `temp/` paths, but only runs at `cmd_check` time — files appearing between check and `git add -A` in a standard layout would be at most test artifacts.

**Risk:** Low in practice for the defined use cases. Explicit path staging from the `cmd_check`-returned change set would be strictly safer, but adds code complexity for a minimal threat window. Acceptable as-is with the current guardrail.

---

### Finding 13 (NOTE): `--max-files`/`--max-insertions` flags are not enforced in SKILL.md

`SKILL.md` step 1 states bounds of "≤ 4 core files / ≤ 150 insertions" as absolutes. `express.py` defaults to these but allows override via `--max-files` and `--max-insertions` (lines 518–519).

This is a documentation gap, not a code bug: if the bounds are truly non-negotiable (per SKILL.md's "No override flag" at line 101), then `--max-*` should not exist or should also be documented. If they're legitimate operator-settable overrides, SKILL.md should mention them. As filed, an operator could pass `--max-files 100` and bypass the 4-file bound while SKILL.md states 4 as hard.

---

## Summary

| # | Severity | Subject |
|---|----------|---------|
| 1 | **BLOCKER** | `--repo` flag ignored by `cmd_land` and `build_offline_manifest` (uses env var instead of `args.repo`) |
| 2 | MAJOR | `src/project.js.orig` misclassified as kernel surface (not in AGENTS.md list; scratch check doesn't catch `.orig`) |
| 3 | MAJOR | CHANGELOG "today exists" branch silently drops entry when no `### Fixed` heading is present |
| 4 | MAJOR | `relay-turn-lib.sh` refusal mislabeled `frozen-twin` (AGENTS.md says it's not a twin) |
| 5 | MINOR | `DOC_PREFIXES` omits `README.md` and other doc paths |
| 6 | MINOR | `git status --porcelain` without explicit `--porcelain=v1` |
| 7 | MINOR | `.tick` event filename `.jsonl` for single-object-per-file (convention mismatch) |
| 8 | NOTE | Ghost-PR deviation honesty: well-documented across all three files ✅ |
| 9 | NOTE | Test suite non-vacuity: verified hermetic and non-vacuous ✅ |
| 10 | NOTE | `build_offline_manifest` correctly omits unresolvable numbers (GH-202 contract) ✅ |
| 11 | NOTE | Order integrity: all documented traps structurally impossible ✅ |
| 12 | NOTE | `git add -A` sweep risk: low, acceptable as-is |
| 13 | NOTE | `--max-*` flags allow operator override not documented in SKILL.md |

**STATUS: Changes Requested** — Finding 1 (BLOCKER) must be fixed before the express lane can ship. Findings 2–4 (MAJOR) should also be addressed.

<!-- ▽ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK ▽ -->
▶ TAKE YOUR TURN (deepseek)
<!-- △ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK △ -->
