---
Goal: Plan QA — GH-1269 merge-cleanup B1 CHANGELOG repair keeps development's history byte-for-byte
Date: 2026-10-30
NEXT: codex
STATUS: In Review
---

# Context

Issue: https://github.com/HiQS-Labs/XYZ-forge/issues/1269. Canonical plan: `PROJECT/2-WORKING/GH-1269-B1-CHANGELOG-REORDER.md` (embedded below). Red control (pre-fix code, reproduced in this repo): `TESTS-RESULTS/2026-10-30+GH-1269/red-control-prefix.log`; smoke script `TESTS-RESULTS/2026-10-30+GH-1269/smoke.py`.

Source paths to check the claims against:
- `skills/2-daily/merge-cleanup/scripts/ledger_merge.py` — `union_changelog` (≈L449), `read_changelog_union` (≈L493), `resolve_ledger_conflict` (≈L521).
- `skills/2-daily/merge-cleanup/scripts/merge_cleanup.py:553` — `git merge --no-ff --no-commit origin/<integration>` inside the PR clone (so HEAD = PR, MERGE_HEAD = integration).
- `TESTS-RESULTS/2026-10-05+GH-789/manual_matrix.py` — the existing (unregistered) coverage of `union_changelog`.

Operational envelope: a one-function assembly change in a local merge helper. No new tests or registry entries (GH-831), no new machinery. Grade against the issue's goal and non-goals, not hypothetical threat models.

Questions:
1. Is the root cause right (the reverse sort over both sides' additions), and is HEAD=PR / MERGE_HEAD=integration actually true at the only call site?
2. Does `preamble + PR additions (own order, minus blocks byte-identical to an integration addition) + theirs[len(preamble):]` keep every existing refusal and still satisfy the GH-789 matrix cases (notably `test_same_date_additions_preserve_history_and_deduplicate`)?
3. Is prepending (rather than date-sorting) the PR's blocks acceptable under the issue's goal? Any requirement missing?
4. Are the verification steps (smoke main + adjacent paths with red control, GH-789 matrix rerun in a disposable clone, one full gate) sufficient?
5. Is the rating `65/60/50/85` grounded?

End with exactly `VERDICT: PASS` (or `FAIL`) on its own line, followed by a non-empty `Basis:` line (GH-533). Set STATUS to Approved on PASS.

## Plan doc

## Status

| What was just completed | What's next |
|---|---|
| Promoted; root cause reproduced in the intake repo (`TESTS-RESULTS/2026-10-30+GH-1269/red-control-prefix.log`); plan written | Codex plan QA, then the one-function fix |

## Symptom

The B1 additive CHANGELOG resolution reorders the integration branch's existing same-date
sections and records the repair `resolved`. The next B1 attempt refuses that output ("changelog
preamble or existing history changed") and hands off, which uses up the PR's two-repair budget.

## Environment
- **Observed from:** `LTVera-Pandas` (vendored `.xyz/` at `017b1425`; `merge_cleanup.py` from the deployed Skills Army copy)
- **Harness commit:** `e305cbf3` (intake repo at report time)
- **Worker/CLI:** merge-cleanup (`merge_cleanup.py --execute`, B1 rung)
- **Runtime:** Python — matches the `runtime:python` issue label
- **Sandbox:** off

## Reproduction
1. LTVera PR #874 (one new 2026-10-30 section) conflicts with `development` `3c936bea`, whose `CHANGELOG.md` holds six 2026-10-29 sections added by three parallel PRs.
2. `merge_cleanup.py --primary <landing clone> --prs 870,874 --execute`: B1 attempt 1 on head `f57f2540` resolves and pushes merge commit `497ca1e8`, recorded `resolved`.
3. On the next run, B1 attempt 2 on head `497ca1e8` hands off.

**Expected:** `497ca1e8`'s CHANGELOG = the GH-818 section + development's history unchanged.
**Observed:** the six 2026-10-29 sections are reordered (development order 867-QA, 867, 866-typing, 866, 866-resumed, 776 → output order 776, 866, 867, 866-typing, 866-resumed, 867-QA); bodies intact. Attempt 2: `outcome: handoff`, `reason: CHANGELOG handoff: changelog preamble or existing history changed`.
**Frequency:** once so far; expected to be deterministic for multi-section same-date history.

```text
attempts[0]: rung=B1 head=f57f2540 outcome=resolved commit=497ca1e8
attempts[1]: rung=B1 head=497ca1e8 outcome=handoff reason="CHANGELOG handoff: changelog preamble or existing history changed"
conflict_files: CHANGELOG.md, RELEASES-PREVIEW.html, releases.db, releases.sql
```

## Impact
LTVera PR #874 needs an operator-approved third, CHANGELOG-only repair. Any batch landing with
several same-date CHANGELOG sections from parallel PRs is exposed. No data loss: bodies are kept
and the handoff stopped the reordered history from landing.

## Phase 0 — Diagnose & scope
> Discovery phase: its findings are written **back into this doc** before its QA gate can pass
> (`PROJECT/PDDA.md` → Discovery & spike phases).

### Checklist
- [x] Reproduce it in the intake repo (not just in the reporting repo)
- [x] Locate the responsible script/path — name the concrete write-set (likely the additive-section merge under `skills/2-daily/merge-cleanup/scripts/`)
- [x] Decide fix vs. guard-and-document; reuse an existing code path before adding one (`/ponytail`)
- [x] Set/correct the triage ratings; clear `ratings_provisional` once real

### QA checklist — Phase 0
- [x] The repro is confirmed from the report, not assumed
- [x] An existing suite, or a recorded manual check, covers the failure path before the fix lands (no new test suites: `AGENTS.md` *No new tests*, GH-831)
- [x] The fix composes with the existing harness rather than adding a parallel path

## Rating (2026-10-30)

`rated 65/60/50/85`. Severity 60: a resolved B1 repair produces history its own next attempt refuses,
burning the GH-789 two-repair budget and forcing an operator-approved manual repair; recoverable, no
data loss (the refusal stops the reordered history from landing). Priority 65: severity-led;
deterministic whenever parallel PRs add several same-date sections, which batch landings do routinely.
Appeal 50 (neutral, no operator preference). Effort 85: one function's assembly line plus a manual
smoke. Recurrence: 1 incident (LTVera #874, 2026-10-30) in the last 14 days, 0 in the prior 14;
no other open or closed issue reports it (search "changelog B1"). Trend: unknown beyond one incident.

## Plan (GH-1269)

### Recon (base: origin/development, see Status)

- Landing merge runs inside the PR clone: `merge_cleanup.py:553` `git merge --no-ff --no-commit origin/<integration>`.
  So in B1, `HEAD` = PR head (ours) and `MERGE_HEAD` = integration tip (theirs).
- `ledger_merge.py::read_changelog_union` reads `CHANGELOG.md` at (merge-base, HEAD, MERGE_HEAD) and calls
  `union_changelog(base, ours, theirs)`; its only caller is `resolve_ledger_conflict` (B1).
- `union_changelog` validates that both sides are `preamble + additions + history`, collects every
  addition block from **both** sides into one dict, and emits
  `preamble + sorted(blocks, reverse=True) + history`. Sorting by heading text reorders the integration
  side's own additions whenever they are not already in descending heading order (LTVera #874: six
  2026-10-29 sections 867-QA, 867, 866-typing, 866, 866-resumed, 776 → 776, 866, 867, ...).
- On the next attempt the merge base is the integration tip, so its whole post-preamble text becomes
  `history`; the reordered output fails `text.endswith(history)` → "changelog preamble or existing
  history changed" → handoff, second repair slot burned.
- Coverage: no registered suite exercises `union_changelog`; GH-789's unregistered
  `TESTS-RESULTS/2026-10-05+GH-789/manual_matrix.py` (ChangelogUnitCases, ChangelogMergeCases) does.

### Fix (one function, one file)

`skills/2-daily/merge-cleanup/scripts/ledger_merge.py::union_changelog`: keep every existing validation;
change only the assembly. Output = `preamble + <PR-side (ours) addition blocks, in their own order,
skipping any block byte-identical to an integration-side addition> + theirs[len(preamble):]`.
The integration side's text after the preamble is copied verbatim, so the next B1 attempt's history
check passes by construction. Docstring names the ours=PR / theirs=integration contract.

Non-goals: no change to the two-repair budget, the refusal rules, fenced/HTML refusal, or
same-heading-different-body handoff; no date re-sorting of PR blocks against integration blocks
(the PR's sections are prepended, as the capture's goal states); no new suite (GH-831).

Risk / rollback: single-function revert. A PR whose new section is dated older than an integration
addition now lands above it (prepend) instead of being date-sorted; acceptable per goal, and B1 history
stays byte-for-byte.

### Verification

1. Smoke (GH-1088), `TESTS-RESULTS/2026-10-30+GH-1269/`: main path = LTVera-shaped fixture (base; theirs
   adds six same-date sections in non-sorted order; ours adds one newer section) → output equals
   `preamble + ours block + theirs-after-preamble`; red control on the pre-fix function shows the
   reorder. Adjacent path = feed the output back as the next attempt's (base=theirs, ours=output,
   theirs=theirs + nothing new / plus one more section) → no "history changed" refusal.
2. Re-run `TESTS-RESULTS/2026-10-05+GH-789/manual_matrix.py` in a disposable full clone (all cases green).
3. Full gate via the pre-push hook (merge-cleanup scripts route to the full tier), run once on the
   final commit.

## Current union_changelog

```python
def union_changelog(base: str, ours: str, theirs: str) -> str:
    """Resolve only complete prepended dated blocks; historical bytes are never rewritten."""
    if not all((base, ours, theirs)) or any(re.search(r"(?m)^(?:<{7}|={7}|>{7}|\|{7})(?: |$)", t)
                                          for t in (base, ours, theirs)):
        raise ValueError("empty changelog or conflict markers")
    first = re.search(r"(?m)^## ", base)
    if first is None:
        raise ValueError("base has no section boundary")
    preamble, history = base[:first.start()], base[first.start():]
    historical_headings = set(re.findall(r"(?m)^## [^\r\n]+", history))
    blocks = {}
    for text in (ours, theirs):
        if not text.startswith(preamble) or not text.endswith(history):
            raise ValueError("changelog preamble or existing history changed")
        additions = text[len(preamble):len(text) - len(history)]
        # This deliberately narrow resolver does not interpret fenced/HTML Markdown blocks:
        # a heading inside an example must never become a separately sorted release entry.
        if "<!--" in additions or re.search(r"(?m)^[ \t]{0,3}(?:`{3,}|~{3,}|<)", additions):
            raise ValueError("fenced or HTML additions require manual changelog resolution")
        starts = list(re.finditer(r"(?m)^## ", additions))
        if additions and (not starts or starts[0].start() != 0):
            raise ValueError("additions are not complete sections")
        seen = set()
        for i, match in enumerate(starts):
            block = additions[match.start():starts[i + 1].start() if i + 1 < len(starts) else len(additions)]
            heading, newline, body = block.partition("\n")
            date_match = re.fullmatch(r"## (\d{4}-\d{2}-\d{2})(?:[ \t]+[^\r\n]+)?", heading)
            if not date_match or not newline or not body.strip() or not block.endswith("\n"):
                raise ValueError("malformed or empty dated section")
            # Calendar validation is cheap and prevents impossible dates sorting as real entries.
            date.fromisoformat(date_match[1])
            if heading in seen:
                raise ValueError("duplicate heading on one side")
            seen.add(heading)
            if heading in historical_headings:
                raise ValueError("addition repeats an existing heading")
            if heading in blocks and blocks[heading] != block:
                raise ValueError("different additions share the same heading")
            blocks[heading] = block
    if not blocks:
        raise ValueError("no additive sections extracted")
    return preamble + "".join(blocks[h] for h in sorted(blocks, reverse=True)) + history
```

## Red control (pre-fix)

```text
[FAIL] main: LTVera #874 shape keeps development's same-date order
       integration same-date order in output: ['GH-867 heartbeat', 'GH-867 QA follow-up', 'GH-866 typing', 'GH-866 store', 'GH-866 resumed', 'GH-776 klaviyo']
[FAIL] adjacent: attempt 2 on the repaired head does not refuse its own output
       raised ValueError: changelog preamble or existing history changed
[FAIL] adjacent: attempt 2 after development gained a section
       raised ValueError: changelog preamble or existing history changed
[FAIL] adjacent: block already present on both sides is kept once
       no duplicate blocks
[PASS] guard: different bodies under one heading still hand off
       ValueError: different additions share the same heading
loaded: skills/2-daily/merge-cleanup/scripts/ledger_merge.py
result: FAIL (4)
```

# Turns
