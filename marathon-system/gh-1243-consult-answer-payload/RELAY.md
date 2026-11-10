# Marathon Phase gh-1243-consult-answer-payload
STATUS: Open
NEXT: codex (Builder)

<!-- marathon-drive: task=MARATHON-GH-1243-CONSULT-ANSWER-PAYLOAD-TURN builder=codex reviewer=agy round-cap=2 -->

## Phase Brief

# Marathon preflight packet — gh-1243-consult-answer-payload

- Generated: 2026-11-10T05:54:05Z
- Mode: gh-bundle
- Sources: /Users/noelsaw/.t3/worktrees/XYZ-forge/t3-ec20080d/temp/b1243-admission-gate-6x0bna0l/repo/PROJECT/2-WORKING/GH-1243-CONSULT-ANSWER-PAYLOAD.md 
- Target root: /Users/noelsaw/.t3/worktrees/XYZ-forge/t3-ec20080d/temp/b1243-admission-gate-6x0bna0l/repo (development @ 720db4f50)
- Suggested branch: `marathon/gh-1243-consult-answer-payload-2026-11-10` (branch_ready=false — not cut yet; ask the operator before proceeding, per GUIDING-PRINCIPLES.md §8)
- Verdict: ready
- Source issue state: OPEN.
- Gate: `bash validate.sh --auto development`

- Artifacts: utils/py/consult.py,TESTS-RESULTS/2026-11-10+GH-1243/manual.md,TESTS-RESULTS/2026-11-10+GH-1243/provenance.jsonl,test/gh375-auth-timeout-verdict.sh,test/synthetic/gh101-consult-programmatic.sh,test/_setup.sh
- Suggested turn budget: `turn_timeout_s: 1800` in this phase's MARATHON.yaml entry (≈ 1116 LOC across 6 artifact(s) — over the 900s default, so it needs headroom). marathon.sh reads that field and applies it to the phase; the value is a starting point, not a measurement.
- Auto-included covering tests/helpers: test/gh375-auth-timeout-verdict.sh,test/synthetic/gh101-consult-programmatic.sh,test/_setup.sh

This packet is the producer's output. The orchestrator launches the run; the planner does not
(GUIDING-PRINCIPLES.md §8).

## Acceptance criteria — the build is DONE when these hold
*Inlined verbatim from `/Users/noelsaw/.t3/worktrees/XYZ-forge/t3-ec20080d/temp/b1243-admission-gate-6x0bna0l/repo/PROJECT/2-WORKING/GH-1243-CONSULT-ANSWER-PAYLOAD.md` (its `## Acceptance` section, 5 criterion(a)). Continuation lines included; if a
criterion here reads as a fragment, that is the source text, not a truncation.*
*Verified against [issue #1243](https://github.com/HiQS-Labs/XYZ-forge/issues/1243) — 3 issue criteria reconciled: 2 deviation(s) declared and accounted for.*
- [ ] Re-running a small Codex + agy consult gives neutral payloads of comparable shape and size: answer text only, with no exec logs, prompt echo or token footer.
- [ ] A Codex answer that cites file:line next to its `[Pass]` lines is not stamped. An answer with an uncited `[Pass]` still is.
- [ ] Verified per GH-831 with existing suites (`test/consult.sh`) plus a manual TESTS-RESULTS receipt. No new suites.
- [ ] Preserve baseline failure and final passing evidence in the declared manual/provenance artifacts; use existing checks only.
- [ ] Do not install or publish anything, change versions or release tags, add dependencies, create new test suites, or modify unrelated paths.

## Scope lock — builder, do exactly this and nothing else
- Edit ONLY: `utils/py/consult.py,TESTS-RESULTS/2026-11-10+GH-1243/manual.md,TESTS-RESULTS/2026-11-10+GH-1243/provenance.jsonl,test/gh375-auth-timeout-verdict.sh,test/synthetic/gh101-consult-programmatic.sh,test/_setup.sh` (plus the relay file). Any other edit is reverted and FAILS the turn.
- Do NOT run ANY test or gate yourself — not `bash validate.sh --auto development`, and NOT `test/gh375-auth-timeout-verdict.sh,test/synthetic/gh101-consult-programmatic.sh,test/_setup.sh` either. Those tests create temporary git fixtures/files inside your isolated worktree, which containment treats as off-lane edits and can discard your whole turn. Read them as specs instead; the harness runs the real gate after your turn, outside the worktree.
- Do NOT analyze the roadmap, file issues, or refactor adjacent code. Implement the acceptance criteria above — nothing more.

## Suggested marathon-drive.sh invocation

```bash
XYZ_HARNESS_CONTEXT=swarm XYZ_SESSION_ID=gh-1243-consult-answer-payload RELAY_WORKTREE_ISOLATION=1 relay-automation/marathon-drive.sh \
  --phase-brief <packet>/packet.md \
  --reviewer agy \
  --builder codex \
  --artifact utils/py/consult.py,TESTS-RESULTS/2026-11-10+GH-1243/manual.md,TESTS-RESULTS/2026-11-10+GH-1243/provenance.jsonl,test/gh375-auth-timeout-verdict.sh,test/synthetic/gh101-consult-programmatic.sh,test/_setup.sh \
  --pre-advance-cmd 'bash validate.sh --auto development' \
  --require-clean
```

## Files in this packet
- `run-candidate.json` — normalized run candidate (provenance + contract + checks)
- `freshness.json` — branch state + fix-still-required probes
- `readiness.json` — remediation readiness verdict
- `lane-plan.json` — Codex / agy / orchestrator lane assignment
- `marathon-invocation.txt` — the invocation hint above
- `marathon-invocation.json` — the same invocation as structured data (`swarm-preflight/marathon-invocation@1`, GH-280); supervisors consume this, never the shell text


---

▶ TAKE YOUR TURN (codex — BUILDER role)

You are the BUILDER for this phase. Read the phase brief above and implement it.
APPEND-ONLY FILE (GH-529 attestation): add your block at the END and never delete, reorder, or rewrite any existing content — the terminal attestation refuses the approval if any byte above your block changed, even a tidy-up.
1. Implement the brief by creating/editing the artifact file(s): utils/py/consult.py,TESTS-RESULTS/2026-11-10+GH-1243/manual.md,TESTS-RESULTS/2026-11-10+GH-1243/provenance.jsonl,test/gh375-auth-timeout-verdict.sh,test/synthetic/gh101-consult-programmatic.sh,test/_setup.sh
2. Append a build block to this relay file: `### Round N · Builder · codex` summarizing what you did (files touched, key decisions).
3. Use this exact tick binary (run it from any directory): /Users/noelsaw/.t3/worktrees/XYZ-forge/t3-ec20080d/temp/b1243-admission-gate-6x0bna0l/repo/bin/tick
   - /Users/noelsaw/.t3/worktrees/XYZ-forge/t3-ec20080d/temp/b1243-admission-gate-6x0bna0l/repo/bin/tick claim MARATHON-GH-1243-CONSULT-ANSWER-PAYLOAD-TURN --agent codex --paths "marathon-system/gh-1243-consult-answer-payload/RELAY.md,utils/py/consult.py,TESTS-RESULTS/2026-11-10+GH-1243/manual.md,TESTS-RESULTS/2026-11-10+GH-1243/provenance.jsonl,test/gh375-auth-timeout-verdict.sh,test/synthetic/gh101-consult-programmatic.sh,test/_setup.sh"
   - /Users/noelsaw/.t3/worktrees/XYZ-forge/t3-ec20080d/temp/b1243-admission-gate-6x0bna0l/repo/bin/tick ping MARATHON-GH-1243-CONSULT-ANSWER-PAYLOAD-TURN --agent codex
   - /Users/noelsaw/.t3/worktrees/XYZ-forge/t3-ec20080d/temp/b1243-admission-gate-6x0bna0l/repo/bin/tick release MARATHON-GH-1243-CONSULT-ANSWER-PAYLOAD-TURN --agent codex --to agy
4. Edit ONLY these paths: marathon-system/gh-1243-consult-answer-payload/RELAY.md and utils/py/consult.py,TESTS-RESULTS/2026-11-10+GH-1243/manual.md,TESTS-RESULTS/2026-11-10+GH-1243/provenance.jsonl,test/gh375-auth-timeout-verdict.sh,test/synthetic/gh101-consult-programmatic.sh,test/_setup.sh. Do NOT run git. Do NOT touch any other file — the harness commits for you.
5. HAND OFF EXPLICITLY (GH-268): after releasing the token, end your turn by naming who acts next —
   "handing off to agy — agy, take your turn." A turn that ends without that line
   leaves a human guessing whether the relay is waiting on them or has stalled. Do this EVERY round,
   not just the first. ALSO, you MUST update the `NEXT:` line at the top of this file to exactly: `NEXT: agy (Reviewer)`

---

▶ TAKE YOUR TURN (agy — REVIEWER role)

You are the REVIEWER for this phase. Read the latest builder block above AND review the artifact file(s) on disk: utils/py/consult.py,TESTS-RESULTS/2026-11-10+GH-1243/manual.md,TESTS-RESULTS/2026-11-10+GH-1243/provenance.jsonl,test/gh375-auth-timeout-verdict.sh,test/synthetic/gh101-consult-programmatic.sh,test/_setup.sh. REVIEW THE WHOLE FILE, NOT JUST THE DIFF (GH-268): a beta test had this loop reach 'Approved' in two rounds while an independent audit of the same branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN SCOPE; say so explicitly if you find none. DECLARE IT: your review block MUST contain a literal 'swept file: yes' or 'swept file: no' line — without it a reviewer that skipped the sweep is indistinguishable in the transcript from one that did it and found nothing, which is exactly how those 20 issues stayed invisible.
APPEND-ONLY FILE (GH-529 attestation): add your block at the END and never delete, reorder, or rewrite any existing content — the terminal attestation refuses the approval if any byte above your block changed, even a tidy-up.
1. Append a review block: `### Round N · Reviewer · agy` followed by your assessment.
2. If changes needed: add `**Verdict:** Changes requested`, update the `NEXT:` line to exactly `NEXT: codex (Builder)`, then: /Users/noelsaw/.t3/worktrees/XYZ-forge/t3-ec20080d/temp/b1243-admission-gate-6x0bna0l/repo/bin/tick release MARATHON-GH-1243-CONSULT-ANSWER-PAYLOAD-TURN --agent agy --to codex
3. If satisfied: add `**Verdict:** Approved`, set `STATUS: Approved`, then: /Users/noelsaw/.t3/worktrees/XYZ-forge/t3-ec20080d/temp/b1243-admission-gate-6x0bna0l/repo/bin/tick done MARATHON-GH-1243-CONSULT-ANSWER-PAYLOAD-TURN --agent agy
4. Use this exact tick binary (run it from any directory) for all token operations: /Users/noelsaw/.t3/worktrees/XYZ-forge/t3-ec20080d/temp/b1243-admission-gate-6x0bna0l/repo/bin/tick
   Edit ONLY marathon-system/gh-1243-consult-answer-payload/RELAY.md (your review block + STATUS). Do NOT edit the artifact yourself — request changes instead. Do NOT run git.
4b. TO VERIFY A FINDING, WRITE PROBE FILES OUTSIDE THE REPO — under $TMPDIR, never inside the
   working tree. Creating even one scratch file in the repo is an off-lane write: containment
   reverts it and FAILS YOUR WHOLE TURN, discarding the review you just did (GH-441). Observed
   2026-08-08: a reviewer found a real latent crash, wrote two probe files in-tree to demonstrate
   it, and lost the turn for doing so — the finding survived only because RELAY.md happens to be
   on your allowlist. `cp` what you need to "$TMPDIR/probe.$$/" and work there instead. Verifying
   is wanted; verifying in-tree is what costs you the turn.
4c. A finding that asks for a behaviour change is a generalization unless you can paste the concrete
   input — a row, a value, a `file:line` — that fails under the current code (GH-681). Every
   `[Blocker]` or `[Should]` requesting a behaviour change MUST carry `Observed input:`,
   `Affected scope:` and `Falsifier:` lines; a `[Blocker]` must cite an observed failure. The Builder
   may disposition a request lacking these as `Declined — unproven generalization`.
5. HAND OFF EXPLICITLY (GH-268): end your turn by naming who acts next — "handing off to codex —
   codex, take your turn" when requesting changes, or "relay closed, no further turn needed" when
   approving. The beta report singled this out: the Reviewer turn did not tell the user to go back to the
   Producer, so the relay looked stalled when it was simply waiting. Do this EVERY round.

### Round 1 · Builder · codex

Implemented GH-1243 in `utils/py/consult.py`: Codex `--output-last-message`
feeds the named answer, citation/provenance screening and blind payloads;
combined CLI diagnostics remain in `.codex.md.transcript` with attestation.
Idle and timeout diagnostics follow the raw stream. Missing/empty finals fail.
Updated the in-scope GH-101 synthetic fixture to honor the last-message flag.
Added manual.md and provenance.jsonl with baseline leak control, final payload,
cited/uncited and missing/empty controls (11 manual assertions passed).
No git commands or shell suites/gates were run. All probe artifacts stayed in
`.relay-scratch/`. Easy reversibility: localized output routing; no dependencies.

Verification is partial: no live-provider consult, no harness gate yet.
`test/consult.sh` has stdout-only Codex fixtures; it is not allowlisted and was
not edited. Those fixtures require last-message support before that existing
suite can qualify this change. Please flag this scope gap to the orchestrator;
missing-final safety must remain strict. Acceptance is not claimed complete.

Handing off to agy for independent review.

### Round 1 · Reviewer · agy

**Verdict:** Changes requested
swept file: yes

Swept all 6 in-scope artifact files in full (`utils/py/consult.py:1-1117`, `TESTS-RESULTS/2026-11-10+GH-1243/manual.md:1-79`, `TESTS-RESULTS/2026-11-10+GH-1243/provenance.jsonl:1-2`, `test/gh375-auth-timeout-verdict.sh:1-204`, `test/synthetic/gh101-consult-programmatic.sh:1-114`, `test/_setup.sh:1-175`), plus the phase contract (`PROJECT/2-WORKING/GH-1243-CONSULT-ANSWER-PAYLOAD.md:1-83`), admission probe (`TESTS-RESULTS/2026-11-10+GH-1386/consult-admission.py:1-2`), and existing consult suites (`test/consult.sh:1-306`, `test/gh308-consult-guards.sh:1-131`, `test/gh589-consult-no-tick.sh:1-54`, `test/archive-writers.sh:1-85`). No pre-existing critical defects outside the two blockers below were found in the swept files.

- **[Blocker] R1 — Contract `fix_probes[0]` (`python3 TESTS-RESULTS/2026-11-10+GH-1386/consult-admission.py`) fails with `AssertionError` (exit 1) because `_neutralize_answer_text` in `utils/py/consult.py:253-317` does not strip Codex transcript preamble/exec logs/token footers.**
  - `Observed input:` `raw='Prompt echo\nTRANSCRIPT_SENTINEL\nexec log\ntokens used\n123\n[Pass] utils/py/consult.py:89 final answer.'` passed to `_neutralize_answer_text(raw, 'advisor.md', 'A', 'codex')` in `TESTS-RESULTS/2026-11-10+GH-1386/consult-admission.py:2` (referenced by `PROJECT/2-WORKING/GH-1243-CONSULT-ANSWER-PAYLOAD.md:45-50` `fix_probes`).
    Probe run under `.relay-scratch/tmp`:
    ```text
    $ PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp" python3 TESTS-RESULTS/2026-11-10+GH-1386/consult-admission.py
    Traceback (most recent call last):
      File ".../TESTS-RESULTS/2026-11-10+GH-1386/consult-admission.py", line 2, in <module>
        ... assert 'TRANSCRIPT_SENTINEL' not in out and 'exec log' not in out and '[Pass] utils/py/consult.py:89 final answer.' in out
    AssertionError
    exit=1
    ```
  - `Affected scope:` `utils/py/consult.py:253-317` (`_neutralize_answer_text`), `TESTS-RESULTS/2026-11-10+GH-1243/manual.md:36-45`, `TESTS-RESULTS/2026-11-10+GH-1243/provenance.jsonl:1-2`. Note that in `utils/py/swarm_preflight.py:239-241` (invoked by `utils/py/marathon_drive.py:2671` `acceptance_probes_unmet()`), `expect_nonzero: true` means the probe failed pre-fix (nonzero exit) and MUST exit `0` (`verdict == "landed"`) post-fix. Additionally, `TESTS-RESULTS/2026-11-10+GH-1243/manual.md:38` currently asserts `'TRANSCRIPT_SENTINEL' in consult._neutralize_answer_text(...)` against the live post-fix function rather than a pre-fix baseline control.
  - `Falsifier:` `PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp" python3 TESTS-RESULTS/2026-11-10+GH-1386/consult-admission.py` exits `0`, and `_neutralize_answer_text(raw, 'advisor.md', 'A', 'codex')` returns a neutralized payload containing `[Pass] utils/py/consult.py:89 final answer.` without `Prompt echo`, `TRANSCRIPT_SENTINEL`, `exec log`, or `tokens used\n123`.

- **[Blocker] R2 — Requiring `--output-last-message` as the sole producer of `<label>.codex.md` and moving `consult_codex_attestation` off `<label>.codex.md` breaks existing suites (`test/consult.sh:20-30,195-292`, `test/gh308-consult-guards.sh:31-60`, `test/gh589-consult-no-tick.sh:26`, `test/archive-writers.sh:23-30`) without needing out-of-scope test edits.**
  - `Observed input:` A `codex` invocation where the CLI writes only to stdout (as in `test/gh308-consult-guards.sh:31-37` and `test/consult.sh:20-30`) or where a caller inspects `<label>.codex.md` for `> **ATTESTATION**` (`test/gh308-consult-guards.sh:54-60`).
    Probe run under `.relay-scratch/tmp` simulating `test/gh308-consult-guards.sh:31-60`:
    ```text
    $ PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp" python3 -c '...'
    rc: 5
    stderr: ... consult: all advisors failed
    cx.codex.md exists: False
    cx.codex.md.transcript exists: True
    ```
  - `Affected scope:` `utils/py/consult.py:88-127` (`rtl_has_uncited_claim`), `utils/py/consult.py:130-191` (`rtl_classify_cited_claims`), `utils/py/consult.py:209-250` (`advisor_answer_ok`), `utils/py/consult.py:253-317` (`_neutralize_answer_text`), `utils/py/consult.py:804-813` (`run_one` codex branch), `utils/py/consult.py:919-926`, `952`, `978`.
  - `Falsifier:` This does NOT require editing `test/consult.sh` or expanding the scope lock. Resolve both R1 and R2 inside `utils/py/consult.py` by adding a shared final-answer extractor (e.g. `_extract_final_answer(raw_text)` in `utils/py/consult.py`):
    1. When `raw_text` contains a Codex CLI token footer (`(?m)^tokens used\s*\n\s*[\d,]+\s*(?:\n|$)`), extract only the text after the last `tokens used\n<count>` line (which yields `""` if nothing follows the token count, so a mid-run crash or truncated transcript after `tokens used` still fails `advisor_answer_ok`).
    2. When `raw_text` contains Codex CLI transcript preamble/exec markers (e.g. `^Reading additional input from stdin\.\.\.`, `^=== CONSULT QUESTION ===`, or `\nexec\n` with `codex\n` / `workdir:`) and NO `tokens used\n<count>` footer, return `""` so a mid-run crash before the final answer fails `advisor_answer_ok`.
    3. Otherwise (plain answer text or stdout-only test stubs without CLI transcript framing), return the body after stripping attestation/stamps/banners.
    4. Keep `<label>.codex.md` populated and attested via `consult_codex_attestation(out)` (`utils/py/consult.py:926`) — e.g. if `--output-last-message` writes to `f_out + ".last"` (or if `codex` stdout is captured to `f_out` / copied from `.transcript` when `--output-last-message` did not write `f_out`), ensure `<label>.codex.md` exists and starts with `> **ATTESTATION**` (`test/gh308-consult-guards.sh:54-60`), while `advisor_answer_ok`, `rtl_has_uncited_claim`, `rtl_classify_cited_claims`, and `_neutralize_answer_text` operate on the extracted final answer (preferring the `--output-last-message` payload when non-empty and falling back to `_extract_final_answer` on `<label>.codex.md`).

- **[Pass]** `utils/py/consult.py:88-191` (`rtl_has_uncited_claim` and `rtl_classify_cited_claims`) accurately classifies cited `[Pass] utils/py/consult.py:89` claims vs uncited `[Pass]` claims when given the final answer text.
- **[Pass]** `test/synthetic/gh101-consult-programmatic.sh:21-38` cleanly handles `--output-last-message` while still emitting stdout, and `test/gh375-auth-timeout-verdict.sh:1-204` and `test/_setup.sh:1-175` remain untouched and intact.

handing off to codex — codex, take your turn
