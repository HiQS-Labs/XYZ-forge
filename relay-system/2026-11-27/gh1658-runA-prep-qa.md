---
Goal: Independent preparation QA — Conveyor packets for Flywheel Run A (ledger #1658): #1590, #1666, #1423 ready; #1480 held
Date: 2026-11-27
NEXT: codex
STATUS: Open
---

# Context

Review **preparation packets**, not an implementation: none exists, and none may be written in this turn. Each ready packet is a capture doc with a `## Swarm Preflight Contract` (`round_cap: 9`, `prepared_commit` = `6142128d9c433d6b12972c6cd9a6f864f0ed9da2`, the `origin/development` commit it was grounded at), an inline command fix probe, probe-proof evidence and a PRS ledger row. Jog will consume them in Flywheel Run A as one-turn build tasks. The held packet must be refused by Jog's `hold_refusal` before the lease. The question is whether each packet is truthful, independent and safe to hand to that consumer.

Operational envelope: local developer tooling in XYZ-forge (single repo, local CLI). Commensurate complexity applies. XYZ-forge forbids new test suites and gate machinery (GH-831), so never ask for one. A manual probe recorded under `TESTS-RESULTS/` is the sanctioned shape.

Read in full:
- `PROJECT/1-INBOX/GH-1590-DAILY-GOALS-BACKTICKED-FOREIGN-LEAD.md`
- `PROJECT/1-INBOX/GH-1666-ACCEPTANCE-MARKDOWN-LINE-MODEL.md` (criterion 2 of its Acceptance contains a literal U+2028, copied verbatim from the issue)
- `PROJECT/1-INBOX/GH-1423-RELAY-ATTEST-GITIGNORED.md` (an existing capture from PR #1424, completed rather than duplicated)
- `PROJECT/1-INBOX/GH-1480-MERGE-CLEANUP-DECOMPOSE.md` (held)
- `TESTS-RESULTS/2026-11-27+GH-1658-runA-prep/`: `SUMMARY.md`, `matrix.txt`, `probe-gh*.py` (readable copies of the inline probes), `simulated-fix.patch`, `fake-fix.patch`, `consumer-validation.txt`, `admission-checks.txt`, `prs-readback.txt`, `preflight-*.json`/`.rc`
- Source seams: `skills/1-hourly/kickstart/scripts/build_queue.py:89-150,259-284`; `utils/py/swarm_preflight.py:594-700,827-860`; `utils/py/relay_drive.py:820-845,1000-1010`; Jog's pre-lease checks `utils/py/jog_run.py` `hold_refusal` and `stale_evidence_refusal` (around `:1681-1820`) and `lint_probe` (`:1625`); `skills/1-hourly/kickstart/scripts/build_queue.py:182-201` (`issue_hold_reason`)
- Rules: `skills/1-hourly/conveyor/SKILL.md` steps 3 and 5 (probe polarity, `prepared_commit`), `relay-automation/CONTRACT.example.md`

Issue text (live, quoted):
- #1590: "for a line whose lead is a backticked foreign reference, the span disappears and a later `#N` on that line is admitted. Example line: a `- [ ]` box, then the backticked text other/repo#9, then "then #10". `#10` should not be admitted. … Keep the no-task-list path byte-identical. Existing coverage and a manual red/green only (GH-831)."
- #1666 Acceptance: "Issue extraction, capture extraction and `collect_inline_checklist` split lines on `\r\n`, `\r`, `\n` only." / "The U+2028 fence-closer input and the `Alpha<U+2028>beta` verbatim copy both read `match`." / "Covered in the existing `test/gh400-acceptance-fidelity.sh` (no new suite, GH-831)."
- #1423 Acceptance: three criteria, copied verbatim into the capture.
- #1480: "Blocked on https://github.com/HiQS-Labs/XYZ-forge/issues/1475 and its implementation PR. Do not create a competing branch against the same lines." (#1475 is OPEN.)

You MAY run each probe read-only from the repo root: `export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"; mkdir -p "$TMPDIR"; python3 TESTS-RESULTS/2026-11-27+GH-1658-runA-prep/probe-gh<N>.py; echo $?`. #1590 and #1666 are pure function calls; #1423 writes only under a fresh mkdtemp fixture in `$TMPDIR` and deletes it. Read them first. Do NOT run `test/*.sh`, `validate.sh`, pytest or `swarm-preflight.sh` here.

Questions:

1. **Rejection of unfixed work.** Each probe is the `fix_probes` command with `expect_nonzero: true`. What stops an unchanged or unfixed tree from being reported as delivered, and where is the observed rejection (`matrix.txt` base arm)? Is there a fake fix that reads as landed but leaves the defect? Consider: #1590 "unwrap every backticked span" (would that change the no-task-list path?); #1666 "fix only `extract_acceptance_criteria`" or "only the issue side"; #1423 "always return True", "add `-f` to `git add`".
2. **False negatives.** Would a correct fix in any shape the issues allow read as unfixed? In particular: #1423's probe runs `commit_relay_file` extracted by AST with a fixed namespace (`subprocess`, `os`, `relay_file`, `transcript_repo`, `eprint`) — is that constraint, stated in the capture, reasonable or does it forbid a natural fix? #1666's probe asserts the criterion contains both `Alpha` and `beta` after `normalize_criterion` — would a fix that keeps U+2028 inside the criterion still pass?
3. **Contract shape and staleness.** Are `target`, `gate`, `artifacts`, `artifacts_new`, `fix_probes`, `round_cap: 9` and `prepared_commit` valid for the parser and Jog's linter (`lint_probe` rejects `python3 -c …`, which is why each probe is `env … python3 - <<'PY'`)? Is each gate an existing suite that covers the seam (`test/gh280-jog-marathon-adapter.sh` is the only suite that loads `build_queue.py`; `test/gh400-acceptance-fidelity.sh`; `test/gh505-relay-attest.sh`)? Are the write sets minimal and disjoint, and do they avoid `utils/py/jog_run.py`, `utils/py/gate_receipt.py` and `githooks/`? Will the #1664 stale gate actually check these packets (cited paths = artifacts + non-command probe paths)?
4. **Acceptance truthfulness.** #1590's three `[added]` criteria (the issue has no Acceptance heading): faithful to the issue, no narrowing or widening? #1666 and #1423 copy the issue's block verbatim: confirm. Note that #1666's own issue example (the fence-closer) already reads correctly at the baseline (GH-1646); is keeping it only as a no-regression control the right call?
5. **Held item.** Is #1480 genuinely held on a recorded, open prerequisite (not an invented one)? Is withholding a build contract for it correct under Conveyor ("a held item gets no pretend build contract"), and does `admission-checks.txt` show the refusal Jog would emit? Is restating the issue's block as a `HELD:` line in the capture accurate rather than a fabrication?
6. **Honesty of records.** Do the captures' recon, attempt history (0 attempts, no prior rows/PRs) and rating rationale match the evidence? Is `SUMMARY.md`'s claim that no existing backlog packet records `prepared_commit` (so none is naturally stale under #1664) correct? Does anything overclaim readiness? No packet is enqueued or labelled, and none may be.

Flag anything wrong, missing, mis-scoped or over/under-engineered, citing `file:line`. Every [Blocker] or [Should] that asks for a behavior change needs `Observed input:`, `Affected scope:` and `Falsifier:` lines. Write your verdict below. Change STATUS to Approved only if all four packets pass; otherwise leave it Open and hand back with numbered findings.

<!-- ▽ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK ▽ -->
▶ TAKE YOUR TURN (codex)
<!-- △ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK △ -->
