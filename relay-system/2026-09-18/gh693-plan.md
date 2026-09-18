# GH-693 plan — Lessons Learned becomes optional (highly recommended), not a promotion gate

Issue: https://github.com/HiQS-Labs/XYZ-forge/issues/693 · trigger: #691 (four merged backlog docs
stuck in `2-WORKING` for want of the section). Operator decision 2026-09-18: keep the section as a
strongly recommended habit; stop refusing or skipping lifecycle writes over it.

Ground truth measured on `development` @ 31fa7aba (file:line cited; re-measure before landing).

## 1. When it became a requirement

| Date | Commit | What |
|---|---|---|
| 2026-08-15 | `1f0a5bf1b` initial public release | `PROJECT/PDDA.md:69` rule 8 ("before moving to 3-COMPLETED, a Lessons Learned section appended"); `sentinel-overlay/pr-emit.sh:36` reminder. Convention only. |
| 2026-08-22 | `ed33b06d8` PR #166 (GH-165 wave reconciler) | First *enforcement*: `validate_and_update_doc` dies exit 5 on a merged doc without the section. Pinned by `test/wave-reconcile.sh` Test 4 ("Missing lessons learned is rejected (exit 5)"). |
| 2026-08-26 | `2dab34eea` (GH-267 /express) | Express scaffolds the section from birth; `test/gh267-express-skill.sh:327` asserts presence ("GH-232 gate"). |
| 2026-09-10 | `1a88a7ddb` (GH-496 Phase 2) | `validate_lessons_learned` also rejects empty/placeholder bodies; `--pre-merge` doc contract exits 5. Pinned by `test/gh496-phase2-reconciliation-views.sh:317-330`. |
| 2026-09-18 | `43cf4452` PR #688 (GH-684) | Catch-up path stops dying and instead `SKIPPED GH-n …` per defective backlog doc; `hosted_lane_report.py` opens/keeps an issue (#691). |

## 2. Every place it is enforced or asserted today

Code (the change set):
- `utils/py/wave_reconcile.py:931` `validate_lessons_learned(content, doc_name)` — detector; returns an error string or None.
- `utils/py/wave_reconcile.py:1025-1027` explicit landing (`--pr N`): `die(ll_err, code=5)`.
- `utils/py/wave_reconcile.py:1795-1798` `--pre-merge`: appended to `errors`, `doc_contract_failed = True` → exit 5. No production caller today (`rg -- --pre-merge` outside tests: only the argparse line) — tests only.
- `utils/py/wave_reconcile.py:2050-2057` catch-up (`--catch-up`, the hosted lane's mode): `SKIPPED GH-n — <ll_err> (… fix the doc and the next run retries)`; `skipped_issues.add`; `continue`.

Tests that pin the old behaviour (flip):
- `test/wave-reconcile.sh:238-250` Test 4 — expects exit 5.
- `test/gh496-phase2-reconciliation-views.sh:317-330` — expects the "empty/placeholder" error and a non-zero `--pre-merge`.

Tests that stay valid as-is:
- `test/gh267-express-skill.sh:327` (scaffold still present from birth).
- `test/gh684-hosted-lane-report.sh:53` (synthetic ERROR line fixture for the reporter's parser; not produced by the reconciler after this change, still a valid parser input).
- `test/gh421-auto-wave-reconcile.sh`, `gh168`, `gh202`, `gh232`, `gh358`, `gh429` fixtures include the section — unaffected.

Docs / wording (the change set):
- `PROJECT/PDDA.md:69` rule 8 → move out of the numbered "required" list into "Recommended" as *highly recommended*.
- `HOW-TO-USE.md:27` ("capture docs need their Lessons Learned section *before* merge").
- `skills/express/SKILL.md:120` ("the 08-26 reconcile gate refuses promotion otherwise").
- `sentinel-overlay/pr-emit.sh:36` message ("add a ## Lessons Learned before completion").
- `utils/pdda/pdda-doc-ready.sh:75` — advisory already; unchanged.

Not touched: `.github/workflows/wave-reconcile.yml`, `utils/py/hosted_lane_report.py` (WARN lines are not
terminal errors and not SKIPPED lines; with zero skips the next green run closes #691 itself),
`utils/py/express.py` scaffold (keeps the habit), frontmatter schema validation (stays mandatory).

## 3. Least mechanism (ponytail)

One detector, one advisory emitter, three call sites:

```python
# wave_reconcile.py
def validate_lessons_learned(content, doc_name):   # unchanged detector; docstring: advisory since GH-693
    ...
def warn_lessons_learned(content, doc_name):
    """GH-693: the section is highly recommended, never a promotion gate. Say it loudly, move on."""
    msg = validate_lessons_learned(content, doc_name)
    if msg:
        log_warn(f"{msg} Highly recommended — add it before or after closeout (GH-693); promotion proceeds.")
```
- `validate_and_update_doc` (explicit): replace `die(ll_err, code=5)` with `warn_lessons_learned(...)`.
- `--pre-merge`: replace the `errors.append` + `doc_contract_failed` pair with `warn_lessons_learned(...)`.
- catch-up: delete the GH-684 lessons-learned skip block (it was the only defect check on that path); the
  SKIP machinery (`SKIP_MARKER`, `skipped_issues`, reporter parsing) stays for future defects.
- Message texts: "is missing mandatory '## Lessons Learned …'" → "has no '## Lessons Learned (For Future Agents)' section"; "Substantive reflections are required before closeout." → "…is empty/placeholder".
- `log_warn` exists? If not, use the module's existing `log()` with a `WARN —` prefix consistent with
  the `SKIPPED ` marker style (`wave-reconcile: WARN — …`). No new module, no flag.

Runnable checks:
- New suite `test/gh693-lessons-learned-advisory.sh` (registered in `validate.sh` TESTS), fixtures cloned
  from `test/wave-reconcile.sh` Test 4: (a) explicit `--pr` on a merged doc with NO section → exit 0, doc in
  `3-COMPLETED`, stdout/stderr contains `WARN` + the doc name; (b) same with a placeholder body (`TODO`);
  (c) `--pre-merge` on such a doc → exit 0 with the WARN; (d) catch-up on such a doc → no `SKIPPED` line,
  doc promoted; (e) negative control: a doc missing `goal:` frontmatter still exits 5 on `--pre-merge`
  (frontmatter stays mandatory); (f) red-before proof: the suite fails on the parent commit.
- Flip `test/wave-reconcile.sh` Test 4 → "missing lessons learned is a WARN, doc promoted (exit 0)".
- Flip `test/gh496-phase2-reconciliation-views.sh:317-330` → WARN cites "empty/placeholder", `--pre-merge`
  exit 0 for that fixture.

## 4. Blast radius

- Hosted lane (`--catch-up --gate --qualify`): runs that skipped (backlog) or died (explicit) over this now
  complete with WARN lines. On the first run after merge the four #691 docs promote to `3-COMPLETED`
  without the section and #691 closes itself. Nothing else about promotion, manifest ship, or roadmap
  updates changes.
- `--pre-merge`: no production caller; only its test contract changes.
- Express: scaffold unchanged; wording only.
- Vendored `.xyz/` copies (14 on this machine) keep the strict reconciler until `xyz-sync.sh update`;
  consumers running their own hosted lane see the old behaviour until then. XYZ-mini does not ship it.
- What we lose: the forcing function. Kept visible by the express scaffold, the WARN in every hosted log,
  and `pdda-doc-ready.sh`. What we gain: no more red/skipped lanes over a reflection field.

## 5. Governance & reversibility

- AGENTS: not a kernel/containment surface (`utils/py/wave_reconcile.py` is governance tooling); SOP:
  issue-first (#693), suite registered, capture doc born complete via express; GUIDING-PRINCIPLES: extend
  what exists (one detector, one emitter), operator decides (#691 → operator call), reversible.
- Reversibility: **Easy** — one revert restores the gate. Docs promoted in the window stay promoted (no
  un-promotion); acceptable and stated.
- Preservation invariant: no doc, ledger row, or manifest item is deleted or rewritten by this change;
  only refusals become warnings. Evidence: the suite's (a)–(e) plus `releases check` clean after landing.

## 6. Landing (/express, per operator)

- Task clone `XYZ-forge-gh693-lessons`, branch `fix/gh693-lessons-learned-advisory`, ≤ 2 commits.
- Diff: `utils/py/wave_reconcile.py`, `test/wave-reconcile.sh`, `test/gh496-phase2-reconciliation-views.sh`,
  `test/gh693-lessons-learned-advisory.sh` (new), `validate.sh` (registration), `HOW-TO-USE.md`,
  `skills/express/SKILL.md`, `sentinel-overlay/pr-emit.sh`, `PROJECT/PDDA.md` (exempt path), this thread.
  That is 9 counted files, > the 4-file default, so run with the operator-tunable bounds
  `--max-files 12 --max-insertions 400 --allow-multi-subsystem` (bounds are tunable; the hard refusals —
  frozen twins, kernel surfaces, `.sh` under `utils/`/`relay-automation/` — are not, and none is touched:
  `sentinel-overlay/pr-emit.sh` is outside both trees).
- `express run --issue 693 --suite test/gh693-lessons-learned-advisory.sh --summary "…"` after a `--dry-run`.
- After: `releases check` clean, `pdda.sh issue-doc-sync` 0 errors; watch the next hosted run promote the
  four docs and close #691.

## Definition of Done for this review

The plan is sound if: (1) the enforcement inventory in §2 is complete (a missed call site would leave a
refusal in place), (2) the emitter shape in §3 is the least mechanism, (3) the flipped/added tests would
actually fail on the parent commit, (4) the blast radius in §4 names everything that changes behaviour,
(5) the express bounds in §6 are legitimate tuning, not a bypass.
