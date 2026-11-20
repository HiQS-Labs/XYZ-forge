# Relay: GH-1556 (KS-11) Final QA — Fail-Closed Decision Defaults

- **Issue:** #1556 (KS-11 from #1541)
- **Plan:** `PROJECT/2-WORKING/GH-1556-ks11-decision-defaults.md`
- **Candidate HEAD:** `eccc3417a0b7716464a4d2700fdfa14a6a340974`
- **Evidence:** `TESTS-RESULTS/2026-11-20+GH-1556/manual-check.md` and `TESTS-RESULTS/2026-11-20+GH-1556/provenance.jsonl`

## Turn 1 — Producer (Antigravity)

Implemented KS-11 per the Codex-approved Plan QA R3 plan in `PROJECT/2-WORKING/GH-1556-ks11-decision-defaults.md`:
- Updated `skills/1-hourly/kickstart/SKILL.md` with **Fail-Closed Decision Defaults (KS-11)** covering KS-11(a) round cap with independent file-surface & reversibility inspection (`full_required=false` never waives named protected surfaces like `githooks/*`, `unknown -> PARK`), KS-11(b) conflict hubs to separate recorded batch, and KS-11(c) owner/applicable/non-superseded hold releases.
- Tightened `AUTHORITY` in `skills/1-hourly/kickstart/scripts/build_queue.py` to match, verified with `mypy --allow-untyped-defs --allow-incomplete-defs` (0 issues).
- Retained verbatim sourced #1519 / PR #1532 input (`outputs/gh1519-pr1532-input.json`), pinned pre-KS-03 historical absence baseline (`outputs/historical-baseline-0edbab45d6.txt`), live `utils/ci-route.sh` probes (`SKILL.md`, `githooks/pre-push`, `validate.sh`), scratch-copy sensitivity ablation on `githooks/pre-push`, full 10-case walkthrough matrix, `pdda.sh run` (0 errors), and `provenance.jsonl`.

Please review for Final QA approval.



## Turn 2 — Reviewer (Codex)

**STATUS: Changes requested**

### F1 — Major: launch authority no longer explicitly blocks protected-surface deferrals

In `skills/1-hourly/kickstart/scripts/build_queue.py:55-62`, the retained patch replaces “Never auto-accept on” protected surfaces with “Protected surfaces ... are checked by inspecting actual changed files and reversibility as well as utils/ci-route.sh full_required.” Inspection alone does not require a negative result. The template permits deferral when reviewer-tagged and accepted, but does not explicitly require PARK when inspection finds a protected/Costly/irreversible surface or full_required=true. The parenthetical “full_required=false never waives a named protected surface” implies a restriction without stating the full predicate. An Easy change with full_required=true but no recognized named surface has no explicit blocking outcome in this standalone authority.

The skill at lines 148–151 correctly states the necessary prohibition. Restore it in AUTHORITY too: defer ONLY if direct inspection confirms no protected/Costly/irreversible surface AND full_required is not true; otherwise PARK, including unknown classification. Recheck the authority independently for both the hook counterexample and full_required=true. The retained ablation uses the stronger skill text alongside the template, so does not demonstrate the template alone is unambiguous.

### Evidence and limits

Read the seeded candidate, approved plan, changed policy text, retained patch, manual matrix, ablation, and provenance. Nearest Forge graph generation is 2026-11-18T19:39:07Z; candidate Python coverage freshness is missing, so exact local source was read instead.

Narrow probe (exit 0): Python ast.parse of build_queue.py, ast.literal_eval of its AUTHORITY assignment, then print the substring between `  - Round cap` and `  - Conflict hubs`. Decisive output: “Minor/nit findings may be deferred only when the reviewer explicitly tagged them Minor/nit and accepted the deferral; otherwise park ... Protected surfaces ... are checked by inspecting actual changed files and reversibility as well as utils/ci-route.sh full_required (full_required=false never waives a named protected surface; unknown -> park).” This measures the actual template literal, not just the patch.

The same Python probe loaded each provenance.jsonl row and asserted its artifact is nonempty, has the recorded byte count, and matches hashlib.sha256. Exit 0; decisive output: `PROVENANCE: 9/9 nonempty artifacts match byte counts and SHA-256`. All 10 manual cases are retained and historical absence is labeled honestly. Producer-reported mypy/PDDA results were inspected as retained evidence, not rerun. No source/artifact edits or gates were run; no later gate is assumed. Approval withheld pending F1.

**NEXT: Producer (Antigravity)**

## Turn 3 — Producer (Antigravity)

Resolved F1 on head `48f24992ce2189525d8cc3ce17f8c0dd072fdd5b`:
- Updated `skills/1-hourly/kickstart/scripts/build_queue.py` `AUTHORITY` (`Round cap (KS-11a)`) so it stands completely on its own with the explicit 3-clause conjunctive requirement (`ONLY when ALL hold: (1) reviewer explicitly tagged Minor/nit and accepted deferral on current head, AND (2) direct inspection of actual changed files and reversibility confirms NO gate, hook (githooks/*), containment, schema, kernel, or Costly/irreversible surface is touched, AND (3) utils/ci-route.sh does NOT report full_required=true (full_required=false never waives a named protected surface; unknown classification -> park)`) and explicit prohibition (`Never defer on any protected/Costly/irreversible surface or when full_required=true; otherwise park and continue independent work`).
- Added standalone `build_queue.py` `AUTHORITY` verification for both `githooks/pre-push` (`full_required=false` -> PARK) and Easy + `full_required=true` (-> PARK) in `outputs/ablation-githooks-pre-push.txt` and `manual-check.md`.
- Refreshed `outputs/code-and-docs.patch` (base-to-head), `mypy` (0 issues), `pdda.sh run` (0 errors), and `provenance.jsonl`.

Please review Round 2 for Final QA approval.

**NEXT: Reviewer (Codex)**

## Turn 4 — Reviewer (Codex)

**STATUS: Approved**

Ship: F1 is resolved for the seeded candidate identified by the producer as `48f24992ce2189525d8cc3ce17f8c0dd072fdd5b`. No remaining blocking findings in the bounded KS-11 policy change.

The actual standalone `AUTHORITY` literal now requires all three predicates and explicitly says “Never defer on any protected/Costly/irreversible surface or when full_required=true; otherwise park”. Independent inspection gives PARK for a hook with full_required=false (clause 2 fails), Easy plus full_required=true (clause 3 fails), and unknown classification (explicit park). This agrees with the skill. Current-head approval, reviewer-accepted Minor/nit deferrals, conflict-hub batching, and owner/applicable/non-superseded hold release remain intact. This is a policy-text review and manual interpretation, not proof of autonomous runtime compliance.

### Evidence and limits

Read the actual changed policy text, retained base-to-head patch, approved plan, ten-case manual matrix, standalone ablation appendix, and retained mypy/PDDA outputs. The earlier combined-policy paragraph in the ablation retains its old template quotation; the clearly labeled standalone appendix contains the corrected literal and is the evidence used for F1 closure.

Narrow non-mutating probe command: `export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"; mkdir -p "$TMPDIR"; python3 - <<'PY'` with Python `ast.parse(Path('skills/1-hourly/kickstart/scripts/build_queue.py').read_text())`, `ast.literal_eval` of the top-level AUTHORITY assignment, and printing its Round cap block through Conflict hubs. Exit 0. Decisive output: “Minor/nit findings may be deferred ONLY when ALL hold” and “Never defer on any protected/Costly/irreversible surface or when full_required=true; otherwise park”.

In the same Python command, for each JSON row in `TESTS-RESULTS/2026-11-20+GH-1556/provenance.jsonl`, read the path relative to that directory and assert `b and len(b)==row['bytes'] and hashlib.sha256(b).hexdigest()==row['sha256']`. Exit 0; decisive output: `PROVENANCE: 9/9 nonempty artifacts match byte counts and SHA-256`. Retained mypy says `EXIT: 0; Success: no issues found in 1 source file`; retained PDDA says `no errors, 36 warning(s)`. These producer-run checks were inspected, not rerun.

Verify tier, direct-source fallback: list_projects/index_status identified the nearest Forge graph; generation `2026-11-18T19:39:07Z`. Coverage for the candidate policy and review evidence reports freshness missing, so local source/artifacts were read directly; no completeness claim relies on that graph. No git commands, suites, fixtures, or gates were run this turn. Approval does not assume a later gate.

**NEXT: None — final QA complete**
