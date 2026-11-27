---
Goal: Independent preparation QA — Conveyor packets for #1626 and #792 (Day 3 Flywheel, ledger #1611)
Date: 2026-11-27
NEXT: codex
STATUS: Open
---

# Context

Review two **preparation packets**. Do not review an implementation: none exists, and none may be written in this turn. Each packet is a capture doc with a `## Swarm Preflight Contract`, a retained readiness probe, probe-proof evidence and a PRS ledger row. Jog or start-task will consume them later as one-turn build tasks. The question is whether each packet is truthful, independent and safe to hand to that consumer.

Operational envelope: local developer tooling in XYZ-forge (single repo, local CLI). Commensurate complexity applies. XYZ-forge forbids new test suites and gate machinery (GH-831), so never ask for one. A retained manual probe under `TESTS-RESULTS/` is the sanctioned shape.

Read in full:
- `PROJECT/1-INBOX/GH-1626-DRY-RUN-SCRATCH-PRUNE.md`
- `TESTS-RESULTS/2026-11-27+GH-1626/readiness_probe.py`, `SUMMARY.md`, `simulated-fix.patch`, `probe-proof/*/`
- `PROJECT/1-INBOX/GH-792-GEN4-SANDBOX-DISJOINT-FIRST.md`
- `TESTS-RESULTS/2026-11-27+GH-792/readiness_probe.py`, `SUMMARY.md`, `simulated-fix.patch`, `probe-proof/*/`
- Source seams: `skills/2-daily/merge-cleanup/scripts/merge_cleanup.py` (lines 333-430, 1961-2013, 2535-2546, 3085-3097) and `utils/py/gen4_campaign.py` (lines 84-97, 340-350)
- Contract parser rules: `skills/1-hourly/conveyor/SKILL.md` step 3 (probe polarity) and `relay-automation/CONTRACT.example.md`

Issue text (live, quoted):
- #1626 suggested fix: "Pass `dry_run` to `prune_retained_scratch` and, in a dry run, report what *would* be removed without removing it, or skip the call when `dry_run` is true."
- #792 acceptance (plain bullets in the issue): "The overlapping call refuses with zero `makedirs`/`rmtree`/`subprocess` calls (red control: the current order records a delete first)." / "A disjoint candidate still clones as before." / "The existing self-test at `gen4_campaign.py:348` (`make_sandbox(host, os.path.join(host, "inside"))`) still refuses."

You MAY run each probe read-only (`export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"; mkdir -p "$TMPDIR"; python3 TESTS-RESULTS/2026-11-27+GH-<N>/readiness_probe.py`). Both write only under a fresh mkdtemp fixture inside `$TMPDIR` and delete it afterwards. Read them first. Do NOT run `test/*.sh`, `validate.sh` or pytest here.

Questions:

1. **Rejection of unfixed work.** Each probe is the `fix_probes` entry with `expect_nonzero: true`. What stops an unchanged or unfixed tree from being reported as delivered, and where is the observed rejection? Cite the `probe-proof/1-*` and `3-comment-only-edit` exit codes. Is there a fake fix that reads as landed but leaves the defect? For #1626: "delete pruning entirely" and "fix only `prune_retained_scratch` but not the call site". For #792: "catch the exception" and "only reorder `makedirs`".
2. **False negatives.** Would a correct fix in either shape the issues allow read as unfixed? For #1626, that means skipping the call vs. passing `dry_run` and reporting only. Check the probe's stubs (merge policy, origin, `pgrep`, lsof) and whether `land_prs([], …)` with an empty queue exercises the same `finally` path as a real dry run.
3. **Contract shape.** Are `target`, `gate`, `artifacts` and `fix_probes` valid for the parser, and is each gate an existing suite that covers the seam (`test/gh436-merge-cleanup.sh`, `test/gh-gen4-phase5-campaign.sh`)? Are the artifacts the smallest write set? Are the two write sets disjoint from each other, and from open PR #1607 (which edits `merge_cleanup.py` only inside `main()` / `_primary_blocks`, hunks at `:36` and `:2699-3062`)?
4. **Acceptance truthfulness.** #792's capture declares the three verbatim criteria as `[added]` because Preflight parses only checkbox bullets (filed as #1646). Is that declaration accurate and the minimum needed, and is the wording unchanged? #1626's three `[added]` criteria: are they faithful to the issue's suggested fix, without narrowing or widening scope?
5. **Probe safety.** Can either probe touch anything outside its mkdtemp fixture (real `$TMPDIR` siblings, the repo, the network, or `gh`)? In particular, does the #1626 probe redirect `tempfile.tempdir` before `merge_cleanup` first calls `gettempdir()`?
6. **Honesty of records.** Do the captures' recon, attempt history (0 attempts, no rows/PRs) and rating rationale match the evidence? Does anything overclaim readiness? Neither packet is enqueued or labelled, and neither may be.

Flag anything wrong, missing, mis-scoped or over/under-engineered, citing `file:line`. Every [Blocker] or [Should] that asks for a behavior change needs `Observed input:`, `Affected scope:` and `Falsifier:` lines. Write your verdict below. Change STATUS to Approved only if both packets pass; otherwise leave it Open and hand back with numbered findings.

<!-- ▽ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK ▽ -->
▶ TAKE YOUR TURN (codex)
<!-- △ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK △ -->
