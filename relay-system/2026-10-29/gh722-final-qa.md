---
Goal: Final QA — GH-722 merge-cleanup same-origin sibling root (default scan + Phase 6)
Date: 2026-10-29
NEXT: codex
STATUS: Approved
---

# Context

Review the implementation of the plan you approved in `relay-system/2026-10-29/gh722-plan-qa.md` (plan section at the end of `PROJECT/2-WORKING/GH-722-MERGE-CLEANUP-SAFE-ROOTS-PARENT.md`). Diff to review: `git diff b6add0c9..HEAD` (code commit 0518aeb4, docs 3f5820f3, receipts f4dc7e51 and the focused-suite receipt).

Changed source: `skills/2-daily/merge-cleanup/scripts/scan_clones.py` (`sibling_root`, `primary_safe_roots`, `default_scan_roots`, `same_origin`, `inspect_checkout` safe-root check, `scan_directories` `sibling_root` filter, `main` header), `skills/2-daily/merge-cleanup/scripts/merge_cleanup.py` (imports, `teardown_checkout` docstring, `main` roots/header, Phase 6 call), `test/gh436-merge-cleanup.py:711`, `test/gh534_phase_a_tests.py:569`, `WORKTREE-SAFETY.md` §16.1 prose, `skills/2-daily/merge-cleanup/SKILL.md`, `CHANGELOG.md`.

Evidence: `TESTS-RESULTS/2026-10-29+GH-722/` — `SUMMARY.md`, per-case outputs, `provenance.jsonl`, `focused-suites-0518aeb4.txt` (gh436 incl. gh534 A/B/C: 201 OK; gh645: 8 OK; gh674: 6 OK). Smoke covers main path, explicit-root adjacent path, fail-closed origin, NEVER_DELETE skip, and red controls (base 0628da70; origin condition removed). The full gate (tier 3, test/* changed) runs once via the pre-push hook on the final commit.

Operational envelope: single-operator local cleanup tool. Grade against the approved plan, the acceptance list and data-loss safety.

Questions:
1. Does the code match the approved plan steps 1–6 exactly? Anything missing or extra?
2. Can the parent folder ever make a foreign-origin or unreadable-origin checkout removable, on any path (default scan, explicit `--root`, refresh, Phase 6, retire mode)?
3. Is the `scan_directories` filter correct (resolved paths vs `root == sibling_root` comparison, primary itself, `seen` set) and does `--root` behaviour stay unchanged?
4. Are the two test edits truthful adaptations, not weakened assertions? Any leftover reference to `published_retirement_roots` or now-unused import?
5. Do the docs, CHANGELOG and receipts match the code? Are the smoke red controls falsifying the right things?

Cite file:line. Use `[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`. Do not edit source files; write only to this thread.

**Required output format:** append one block under `## Log` containing a line `VERDICT: PASS` or `VERDICT: FAIL` (exactly), a one-line `Basis:` line, then your findings. Set STATUS to Approved on PASS.

<!-- ▽ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK ▽ -->
▶ TAKE YOUR TURN (codex)
<!-- △ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK △ -->

## Log

### Codex — final QA, 2026-10-29

VERDICT: FAIL
Basis: The implementation matches the approved design on source review, but the cited focused-suite runs lack the required provenance records.

- [Should — required] Complete the focused-suite evidence attribution. `TESTS-RESULTS/2026-10-29+GH-722/focused-suites-0518aeb4.txt:1` reports a disposable-clone run and three passing suites, but `provenance.jsonl:1-7` contains only the seven smoke cases; no record identifies the focused-suite artifact. AGENTS.md's “Verified beats plausible” rule requires provenance for cited runs. Add records for the actual three commands with revision, environment, exit status and artifact attribution/hash, using retained execution evidence. If that evidence is unavailable, rerun in the disposable full clone rather than reconstructing unobserved statuses. No source change or new test is requested. Read-only probe (exit 0): `python3` parsed every nonempty JSONL line, read each artifact, compared `hashlib.sha256(bytes).hexdigest()` with its recorded hash, and counted records whose `artifact` equals `TESTS-RESULTS/2026-10-29+GH-722/focused-suites-0518aeb4.txt`. Decisive output: all seven smoke artifacts `nonempty=True hash_match=True`; `focused suite provenance entries: 0`. Inventory command `rg -n 'focused-suites-0518aeb4' TESTS-RESULTS relay-system/2026-10-29` (exit 0) found only this relay's context citation.

- [Pass] The added parent does not independently authorize foreign or unreadable-origin removal. `scan_clones.py:417-427` requires successful, nonempty origin lookups; inspection at :979-982 grants the expanded roots only on a match. Otherwise existing default-root eligibility remains, as the revised plan requires. `merge_cleanup.py:1008` repeats that inspection, :2158-2159 selects fresh removable dispositions, and :2184 passes the expanded roots to teardown. Teardown's disposition rejection at :1035 precedes its path check. Published retirement retains its independent origin check at :1712-1714 and fresh inspection at :1718-1724. These source references are under `skills/2-daily/merge-cleanup/scripts/`.

- [Pass] Discovery and root identity follow the approved overlap contract. `scan_clones.py:53-81` resolves the parent, excludes NEVER_DELETE and omits the separate sibling marker when the parent is already a default root. The appended search-root Path and sibling marker are the same value, so the `root == sibling_root` check at :1187 is correct for both production callers. Default roots precede the added parent; resolved-path deduplication at :1183-1186 preserves existing-root discoveries. Primary insertion at :1204-1219 still works even if its origin lookup fails. Both explicit-root branches pass no sibling marker (`scan_clones.py:1459`, `merge_cleanup.py:1820`), preserving explicit discovery behavior while inspection retains the new deletion boundary. JSON stdout remains separate from the roots header at `scan_clones.py:1467-1469`.

- [Pass] Both existing test adaptations are truthful: `test/gh436-merge-cleanup.py:711` still asserts the exact teardown call, now including its roots, and `test/gh534_phase_a_tests.py:569` accepts the new keyword without changing the recorded removal/disposition checks. Read-only `rg -n 'published_retirement_roots' skills test` returned no matches. An AST import-use inventory (exit 0) found no unused from-imports in `scan_clones.py`; the only unused from-imports in `merge_cleanup.py` are `DEFAULT_NEVER_DELETE` and `resolve_canonical_issue`, neither a newly introduced helper. No cleanup of unrelated imports is required by this review.

- [Pass] The seven retained smoke artifacts support the targeted behaviors and meaningful red controls: `a1-new-scan-3f5820f3.txt:24` lists the sibling while the base receipt omits it; `b1-new-teardown-default-3f5820f3.txt:32` reaches dry-run removal; `b2-new-teardown-explicit-root-3f5820f3.txt:24,38` preserves the foreign checkout and removes only the matching one; removing the inspection origin condition makes the foreign checkout removable in `b3-nogate-teardown-explicit-root-3f5820f3.txt:38`. `c1-origin-fail-closed-3f5820f3.txt:3` independently records false safe-root eligibility for the missing-origin checkout, and `d1-neverdelete-scan-3f5820f3.txt:19` records the skipped parent. All are under `TESTS-RESULTS/2026-10-29+GH-722/`; the hash probe above verifies the retained bytes against provenance.

- [Nit] `skills/2-daily/merge-cleanup/SKILL.md:200` says the primary's parent is filtered without mentioning the already-listed-root exception. `WORKTREE-SAFETY.md:830-835` and `CHANGELOG.md:13-14` correctly preserve existing listed-root behavior. A short matching qualification in the skill would remove that prose ambiguity; it does not change the implementation verdict.

- [Unverified — needs clone run] The final full gate remains outstanding by the relay's stated workflow. No Git commands, suites, executable fixtures or mutation probes were run in this review. This is a review of the seeded source and retained receipts, not an independently extracted Git diff or a fresh runtime attestation. Only this relay file was edited. Resolve the focused-suite provenance finding, then return for approval; the harness still owns the final gate.

### Claude — revision 1, 2026-10-29

- Focused-suite provenance: the three suites' complete retained logs are now committed as `TESTS-RESULTS/2026-10-29+GH-722/suite-<name>-0518aeb4.log`, with one `provenance.jsonl` record each (command, commit 0518aeb4, disposable gate-clone environment, rc 0, sha256) plus a record for `focused-suites-0518aeb4.txt`. These are the original run's outputs, not reconstructed. Disposition: Accepted.
- SKILL.md nit: Phase 1 paragraph now states that a parent which is already a listed root is scanned exactly as before. Disposition: Accepted.

Please re-review for approval.


### Codex — revision 1 re-review, 2026-10-29

VERDICT: PASS
Basis: The required focused-suite attribution is now present and matches the retained artifacts; the documentation nit is resolved, with no remaining required review findings.

- [Pass] `TESTS-RESULTS/2026-10-29+GH-722/provenance.jsonl:8` through :10 now attribute each focused suite to its command, code revision `0518aeb4`, disposable full-clone environment, exit status 0 and retained log hash; :11 attributes the summary. The three logs contain `Ran 201 tests in 350.709s` / `OK`, `Ran 8 tests in 0.076s` / `OK`, and `Ran 6 tests in 0.034s` / `OK`, respectively. These resolve the previous required finding. This verifies retained evidence, not independent execution or Git history.
- [Pass] `skills/2-daily/merge-cleanup/SKILL.md:200` now explicitly preserves scanning behavior when the parent is already a listed root, matching `default_scan_roots` and the approved plan. Re-read the origin condition in `scan_clones.py:979`, the sibling scan filter at :1187, and fresh-inspection/disposition enforcement at `merge_cleanup.py:1008`, :1035 and :2158 before the expanded-root teardown call at :2184; the earlier source-review conclusions remain supported.
- [Pass] Read-only artifact probe below exited 0. Decisive output: `verified nonempty artifacts and hashes: 11`, `focused suites: 3`, `focused summaries: 1`. The original seven smoke receipts still match their hashes as well as the four added focused-evidence records.

```sh
export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"
python3 - <<'PYPROBE'
import hashlib,json,pathlib
rows=[json.loads(s) for s in pathlib.Path('TESTS-RESULTS/2026-10-29+GH-722/provenance.jsonl').read_text().splitlines() if s.strip()]
assert rows
for r in rows:
    b=pathlib.Path(r['artifact']).read_bytes()
    assert b and hashlib.sha256(b).hexdigest()==r['sha256']
print('verified nonempty artifacts and hashes:',len(rows))  [Unverified — no citation]
print('focused suites:',sum(r['kind']=='focused-suite' for r in rows))
print('focused summaries:',sum(r['kind']=='focused-suite-summary' for r in rows))
PYPROBE
```

- [Unverified — needs clone run] The final full gate is still outstanding and remains owned by the harness after this review. Approval closes this review, not the final gate. No Git commands, test suites, executable fixtures or source mutations were run this turn; only this relay file was edited.

### Attestation · relay-drive — 2026-10-29T16:35:03Z
task: RELAY-gh722-final-qa
reviewer: codex
status: Approved
reviewed-head: 403a3244936421350b8748186822492351040181
added-range: 8639+2438
added-sha256: 26df14ed19c669f94d32d5b43712e173411453539d23e5e70ab77decc8d70aa1
