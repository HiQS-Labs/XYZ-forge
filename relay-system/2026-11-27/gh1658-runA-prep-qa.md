---
Goal: Independent preparation QA — Conveyor packets for Flywheel Run A (ledger #1658): #1590, #1666, #1423 ready; #1480 held
Date: 2026-11-27
NEXT: claude-a
STATUS: Escalated
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

### Round 1 · Reviewer · codex

VERDICT: FAIL

Preparation needs revision. #1480 is correctly held. #1590 has a prior unresolved preparation hold and a simulated fix that violates the issue. #1666's probe misses part of its own contract.

1. **[Blocker] Reconcile #1590 with its prior held preparation.**
   - Observed input: `PROJECT/1-INBOX/GH-1590-DAILY-GOALS-BACKTICKED-FOREIGN-LEAD.md:62` says no prior capture, branch or roadmap row. The [operator's Conveyor marker](https://github.com/HiQS-Labs/XYZ-forge/issues/1590#issuecomment-7142471947) names a capture, PRS row and receipts on `docs/XYZ-forge-gh1583-conveyor-prep-2026-11-24` at `6047be0fe`. It records three prior preparation-review rounds, escalation at the cap, an open finding about exact commands and exits on the delivery acceptance path, and no build dispatch. The seeded current ledger does show zero Jog rows for the four issues and a `parked` pickup event each. That is consistent with zero build attempts and is separate from prior prep review.
   - Affected scope: #1590 selection, deduplication and rating provenance, and the Run A readiness list. Reconcile the older branch and rating, preserve the history, and obtain or cite the authorized disposition of the existing hold. If it remains held, exclude it from the three ready packets. Conveyor steps 1 and 3 require both the comment lookup and preservation of holds (`skills/1-hourly/conveyor/SKILL.md:65,69`).
   - Falsifier: the packet identifies the prior branch and review outcome, accounts for any carried rating, and cites the authorized hold disposition. Any outstanding delivery-path finding remains visible until adjudicated.

2. **[Blocker] #1590's simulated fix and its no-task-list control disagree with the issue.**
   - Observed input: the capture requires exact preservation of the no-task-list path at `:12,33` and broadens sanitation before the task-list branch in the plan at `:52`. `simulated-fix.patch:9-12` unwraps any atomic reference before `build_queue.py:265-267` detects a list. The control in `probe-gh1590.py:9` unwraps a foreign slug, which `build_queue.py:275-279` discards, so it cannot distinguish this regression. The suite named at capture `:81` loads `build_queue.py` for the Jog hold seam (`test/gh280-jog-marathon-adapter.sh:171`, `utils/py/jog_run.py:1691-1729`) and has no daily-goals parser assertion.
   - Affected scope: #1590's proposed behavior, proof and manual control. Preserve the legacy sanitizer result on the no-task-list path. Add a no-task-list example containing a backticked same-repo qualified reference and one with inline code mentioning `#N`. Retain the existing checkbox controls.
   - Falsifier: the revised probe rejects both unconditional atomic unwrapping and unconditional unwrapping of all spans, and a scoped simulated fix passes while both no-task-list cases still return `[14, 15]`.

3. **[Should] #1666 can read landed with a declared acceptance reader still on `splitlines()`.**
   - Observed input: `PROJECT/1-INBOX/GH-1666-ACCEPTANCE-MARKDOWN-LINE-MODEL.md:18-20,48,101` specifically includes `extract_declared_deviations`, but `probe-gh1666.py:3-13` never invokes it. Replacing just the shared issue/capture extraction and checklist splits passes the probe with the deviations reader still splitting at `utils/py/swarm_preflight.py:689`. The earlier issue-side-only negative control is useful and misses this case. The checklist assertion also searches normalized text and raw lines together, so it does not prove the literal separator survives in the raw lines.
   - Affected scope: #1666's declared remediation and proof. If deviations are intended as part of the shared model, explain that scope and exercise a Unicode separator followed by a marker that must remain on the same physical line. Assert raw checklist fidelity directly. Apply the stronger check in the existing #400 suite as the issue requests.
   - Falsifier: the revised proof rejects the two-reader partial change and an inline copy that replaces the literal separator. The complete fix passes with both sides still matching and the fence control still green. `normalize_criterion` folds whitespace at `utils/py/swarm_preflight.py:585-592`, so the normalized extraction control can accept `Alpha beta` and still require the literal separator in the raw checklist.

4. **[Should] Retain provenance and distinguish probe results from delivery-path receipts.**
   - Observed input: `TESTS-RESULTS/2026-11-27+GH-1658-runA-prep/matrix.txt:1-13` gives useful standalone probe exits, and `preflight-*.json` and `.rc` give base consumer results. The evidence directory has no `provenance.jsonl` for the cited runs (`AGENTS.md:123-124` and `skills/1-hourly/conveyor/SKILL.md:105`). It has no evaluated result for the simulated fix with and without its required delivery file. `utils/py/swarm_preflight.py:265-266,283-305,1677-1680,1979-1982` makes those states distinct. `utils/py/marathon_drive.py:2680-2720,2778-2791` rechecks the pinned contract before the gate and requires every probe to read landed. A standalone exit 0 can coexist with a missing delivery receipt.
   - Affected scope: preparation evidence and the earlier #1590 finding. Retain exact commands, evaluated heads, exits and decisive output for the refreshed proof, with provenance. Exercise the existing consumer in a disposable clone for the fixed-with-receipt and fixed-without-receipt arms. Label the evidence as preparation, pending publication, merge and the exact-ref recheck in Conveyor step 6.
   - Falsifier: base and rejected mutants show the behavioral probe unfixed. A complete demonstration with the delivery file produces both probes landed and Preflight exit 4. A complete behavior fix with the file absent produces mixed verdicts and exit 7. The retained provenance identifies the commands and commits for those outcomes.

5. **[Should] Document the shared inferred lane paths.**
   - Observed input: `SUMMARY.md:18-22` lists disjoint declared paths. Preflight adds inferred tests/helpers at `utils/py/swarm_preflight.py:480-529` and assigns them to the effective lane at `:335-349`. `jq -r '.lane_plan.effective_artifacts[]' TESTS-RESULTS/2026-11-27+GH-1658-runA-prep/preflight-<N>.json` exits 0 for each receipt. All three lists include `test/_setup.sh`, and both #1590 and #1666 include `test/gh280-jog-marathon-adapter.sh`.
   - Affected scope: the independence claim and builder-facing packet. Keep the inferred shared files outside the intended edits. The declared implementation and delivery paths are independent and avoid Jog, gate receipts and `githooks/`.
   - Falsifier: the summary distinguishes declared and effective scope and the lane instructions clearly reserve all inferred shared paths from edits for these three tasks.

#### Review evidence

- With `PYTHONDONTWRITEBYTECODE=1` and `TMPDIR="$PWD/.relay-scratch/tmp"`, running `python3 TESTS-RESULTS/2026-11-27+GH-1658-runA-prep/probe-gh1590.py` returned **1**, `AssertionError: backticked foreign lead admitted a later #N`. The same command for `probe-gh1666.py` returned **1**, `AssertionError: ('0x85', ['Alpha', 'Gamma'], ['Alpha', 'Gamma'])`. The proof matrix records exit 1 on the base and fake arms and 0 on the simulated arms for all three. Command polarity is correct. A crash also reads unfixed, which is why the decisive assertions matter.
- The additional counterexamples were replayed with `PYTHONPATH=utils/py python3 -` and source mutations only in memory. This is the decisive replay (the interpreter exited **0**):

  ```python
  from pathlib import Path
  import sys
  from types import ModuleType
  d = Path('TESTS-RESULTS/2026-11-27+GH-1658-runA-prep')
  def load(name, path, source):
      m = ModuleType(name)
      m.__file__ = path
      sys.modules[name] = m
      exec(compile(source, path, 'exec'), m.__dict__)
      return m
  p = 'skills/1-hourly/kickstart/scripts/build_queue.py'
  src = Path(p).read_text()
  start = src.index('def parse_daily_goals_refs(')
  base = load('base', p, src)
  patch = next(s[1:] for s in (d/'simulated-fix.patch').read_text().splitlines()
               if s.startswith('+    clean ='))
  cases = [
      ('atomic', patch, 'Do #14 and `HiQS-Labs/XYZ-forge#9` #15'),
      ('unwrap-all', '    clean = INLINE_BACKTICK.sub(lambda m: m.group(0)[1:-1], FENCED_CODE.sub("", body or ""))',
       'Do #14 and `literal #9` #15'),
  ]
  for name, repl, body in cases:
      m = load(name, p, src[:start] + src[start:].replace('    clean = _sanitize_body(body or "")', repl, 1))
      probe = (d/'probe-gh1590.py').read_text()
      exec(probe[probe.index('f, S, B'):], {'m': m})
      print(name, 'seeded probe rc=0', 'base', base.parse_daily_goals_refs(body, 'HiQS-Labs/XYZ-forge', 1),
            'mutant', m.parse_daily_goals_refs(body, 'HiQS-Labs/XYZ-forge', 1))
  p = 'utils/py/swarm_preflight.py'
  src = Path(p).read_text()
  for name in ('extract_acceptance_criteria', 'collect_inline_checklist'):
      start = src.index('def '+name+'(')
      src = src[:start] + src[start:].replace('lines = text.splitlines()', r"lines = re.split(r'\r\n|\r|\n', text)", 1)
  m = load('swarm_preflight', p, src)
  exec((d/'probe-gh1666.py').read_text(), {})
  print('1666 two-reader mutant seeded probe rc=0; deviations unchanged:',
        m.extract_declared_deviations('## Acceptance — deviations from the issue\n- [added] Alpha\u2028- [added] beta — reason: R\n'))
  ```

  Both #1590 mutants printed `base [14, 15] mutant [14, 9, 15]` after their seeded controls passed. The #1666 mutant printed `added: [('beta', 'R')]` and a malformed declaration for `[added] Alpha` even though its seeded probe passed.
- **#1423.** The AST probe's fixed namespace permits both local fixes named in the capture (`:78,93,145`). It would reject a valid refactor that depends on an external helper or renames the function. The existing-shaped fixes fit the task. The fake `return True` fails because no commit lands (`matrix.txt:10`). `git add -f` after the existing tracked-path check can genuinely fix the ignored-path symptom while the hook control still requires failure on a rejected commit. Forcing the stage can leave a staged modification after a failed commit, so the simpler redundant-add removal is preferable. The recorded helper proof stops at `commit_relay_file`. Full driver exit 4/0, captured add stderr, and presence of the attestation record on success remain delivery evidence under the verbatim criteria at `:43-45`. The driver maps the helper's False to `attest-publish-failed` before record write (`utils/py/relay_drive.py:1005-1028,1574-1581,1588-1594`). The existing #505 gate exercises attestation on a plain tracked path (`test/gh505-relay-attest.sh:40-45,170-191`). I did not rerun the Git fixture or any gate in this turn.
- **Acceptance and hold.** Compared the raw checkbox lines with the fetched GitHub issue bodies. #1666 and #1423 each match all three lines literally, including U+2028 in #1666's second line. The U+2028 fence case is a valid no-regression control because GH-1646 already handles physical fence boundaries (`utils/py/swarm_preflight.py:629-656`, `test/gh400-acceptance-fidelity.sh:570-581`). #1590's three declared additions are faithful, and its preflight fidelity is advisory (`no-issue-section`). #1480's issue explicitly blocks on #1475 and its implementation PR, and GitHub returned #1475 open. Using those live issue snapshots as lookup inputs, the local `hold_refusal` returned `hold: capture body HELD: marker` for #1480 and `None` for the other three, matching `admission-checks.txt`. That mechanical check does not adjudicate #1590's comment. Jog checks holds before the lease (`utils/py/jog_run.py:3163-3179`). Withholding #1480's build contract is correct.
- **Contracts, ledger and staleness.** Local parser/linter read-back exited 0 with two labels, no reason, round cap 9, and matching inline and readable probe copies for each build packet. The three nonempty base JSONs say both probes unfixed and evaluate `development` at `6142128d9c433d6b12972c6cd9a6f864f0ed9da2`. The `env` prefix permits the here-doc under the current shape linter (`utils/py/jog_run.py:1625-1644,1850-1900`). Every new delivery path appears in both artifacts lists and has a corresponding `path_absent` probe. The #400 and #505 gates cover the reader and attestation paths. #280 is hold/adapter coverage only, as noted above. The immutable SQLite read-back matched `prs-readback.txt`, with one `parked` event per issue and no Jog rows. The ratings are plausible at the stated sizes, subject to reconciliation of #1590's earlier packet. The stale check compares the declared source paths and delivery path against the resolved `target.ref` of the aligned execution clone (`utils/py/jog_run.py:1779-1818,2853-2883,3143-3145`). Legacy contracts omit the pin and are skipped. A literal source scan of the seeded `PROJECT/` found the three new pins and the #1664 prose example. The pinned historical scan in `SUMMARY.md:62-67` is retained producer evidence. I did not rerun it with Git. Its conclusion applies to the integration backlog at that pin, and does not establish the state of the earlier unmerged #1590 branch.

### Round 1 · Producer · claude-a

All five findings accepted. The ready set changed: **#1590 is withdrawn and #1638 replaces it.** Round 2 reviews #1666, #1423, #1638 (ready) and #1480 (held).

1. **#1590 prior hold — accepted; #1590 withdrawn.** The 2026-11-24 marker comment records an unmerged preparation (`docs/XYZ-forge-gh1583-conveyor-prep-2026-11-24` at `6047be0fe`), Escalated at the review cap with one open [Should], next owner the operator. Conveyor preserves holds, so this PR now carries no #1590 capture or PRS row (`releases.db`/`releases.sql` were restored to the prepared commit and the remaining pickups re-run). `SUMMARY.md` "Dropped from the ready set" records why.
2. **#1590 simulated fix / control — moot** with the withdrawal (the probe, patches and receipts were removed). Noted for whoever resumes #1590.
3. **#1666 deviations reader and raw separator — fixed.** `probe-gh1666.py` now asserts the raw checklist line `- [ ] Alpha<sep>beta` keeps the literal separator, and that `extract_declared_deviations` parses `- [added] Alpha<sep>- [added] beta — reason: R` as one declaration with no malformed entry. `matrix.txt`: base 1, simulated fix 0, issue-side-only fake 1, your two-reader partial fix (`fake2-gh1666-two-reader.patch`) 1. Capture probe JSON updated; parser/linter read-back matches the proved copy.
4. **Provenance and consumer arms — fixed.** `provenance.jsonl` records every command, head, exit and decisive output. `preflight-arms.txt` runs the real Preflight `--dry-run` in a disposable scratch clone with each simulated fix committed on `development`: fixed + delivery receipt → exit 4 (landed/landed) and fixed without the receipt → exit 7 (landed/unfixed) for all three ready items. `SUMMARY.md` is labelled preparation evidence pending publication, merge and the Conveyor step-6 recheck.
5. **Inferred shared lane paths — fixed.** `SUMMARY.md` "Scope: declared vs effective" lists the overlapping inferred paths (`test/_setup.sh` in all three; `test/gh505-relay-attest.sh`, `test/gh371-…`, `test/gh372-…` in #1423/#1638; `test/gh642-…` in #1666/#1638) and reserves them; each remediation string now says not to edit any Preflight-inferred lane path.

**New packet: #1638** (`PROJECT/1-INBOX/GH-1638-RELAY-SEED-DIR-NESTING.md`). Reproduced on the real `rtl_worktree_begin` (`relay-automation/relay-turn-lib.sh:722,783-784`; `utils/py/rtl.py:1156-1161` delegates to it): seeding an existing allowlisted directory produces `<wt>/seeded/seeded/` and leaves the top-level file at its HEAD content. Inline Bash probe (`probe-gh1638.sh`, run as `env bash -s <<'SH'` so `lint_probe` accepts it); gate `bash test/worktree-isolation.sh`; artifacts `relay-turn-lib.sh` plus the regenerated `skills/1-hourly/relay-automation/relay-pkg.tar.gz` (`make-pkg.sh:18`). Scope is the issue's first item and red control only; the commit-pathspec filter at `:1629-1634` is a declared non-goal, and #1638 stays open for it. `matrix.txt`: base 1, simulated fix (`rm -rf` before `cp -R`) 0, fake fix (skip directory entries) 1. No prior comments, capture, row or PR for #1638.

**#1423 (your evidence notes):** the capture now says the probe proves the helper, and the full-driver repro (exit 4 → 0 with captured `git add` stderr, attestation record present) is delivery evidence for `delivery.md`. The fixed AST namespace is stated as a constraint.

Read for round 2: the three ready captures and `GH-1480-MERGE-CLEANUP-DECOMPOSE.md`; `TESTS-RESULTS/2026-11-27+GH-1658-runA-prep/` (`SUMMARY.md`, `matrix.txt`, `preflight-arms.txt`, `provenance.jsonl`, `probe-gh1666.py`, `probe-gh1423.py`, `probe-gh1638.sh`, `sim-gh*.patch`, `fake*-gh*.patch`, `consumer-validation.txt`, `admission-checks.txt`, `prs-readback.txt`, `preflight-*.json`). Seams for #1638: `relay-automation/relay-turn-lib.sh:722-791`, `utils/py/rtl.py:1156-1161`, `skills/1-hourly/relay-automation/make-pkg.sh`. You may run `probe-gh1638.sh` read-only (`bash TESTS-RESULTS/2026-11-27+GH-1658-runA-prep/probe-gh1638.sh; echo $?`): it writes only under its own mktemp dir in `$TMPDIR` and removes it. Same rules as round 1 otherwise.

### Round 2 · Reviewer · codex

VERDICT: FAIL

#1590 is withdrawn, #1423 is ready for preparation handoff, and #1480 is correctly held. #1638 needs a bounded directory-mirror proof and a package check. #1666 needs one stronger counterexample for its CR/LF-only criterion.

1. **[Blocker] #1638's green arm changes file seeding and its probe accepts an incomplete directory mirror.**
   - Observed input: the capture requires current host contents and declares file entries unchanged (`PROJECT/1-INBOX/GH-1638-RELAY-SEED-DIR-NESTING.md:12-19,32-34,52`). Both Python and Bash use the same seed loop (`utils/py/rtl.py:1156-1161`, `relay-automation/relay-turn-lib.sh:722-750,774-791`). `sim-gh1638.patch:7-10` adds recursive removal to every existing host input, including files. The loop currently checks only for an absolute entry and source existence before the copy. Normalization at `relay-automation/relay-turn-lib.sh:395-433` does not prove the resolved destination is strictly below the scratch worktree at the point of removal. The loop traces SEED and eventually reports success without checking the copy (`:784-799,826-828`). The green arm therefore endorses a new destructive operation on an unproven destination and can drop a previously checked-out entry on a failed copy.
   - Observed input: `probe-gh1638.sh:7-20` has no tracked child deleted on the host. A contents-only overlay can satisfy all three checks while leaving a stale HEAD file in the worktree. Direct command replay with only temporary directories, no Git, returned interpreter exit 0 and printed `cp exit=0; seeded assertions=True; retired file survives=True`. The three seeded assertions in that replay were absence of the extra directory, current top-level bytes, and preservation of the nested file.
   - Affected scope: the GH-1638 packet's plan, simulated proof and common producer worktree seeding. Keep the fix confined to directory entries and require any replacement to stay strictly inside the worktree, with an explicit failed-copy outcome. Use a tracked child deleted on the host as the smallest extra input. Keep the directory commit-pathspec fix out of this partial lane. Jog strips `--lane-closes-issue` (`utils/py/jog_run.py:520-523`), so the issue can stay open for that second item.
   - Falsifier: a directory-only simulated fix retains the latest host files, removes the deleted child, creates no nested copy and preserves ordinary file seeds. A contents-only overlay fails the deleted-child control. A controlled copy failure never yields a successful but incomplete seed. The proof shows a resolved worktree-relative boundary before any recursive removal.
   - Narrow replay command, run with `PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp" python3 -`:

     ```python
     from pathlib import Path
     from subprocess import run
     from tempfile import TemporaryDirectory
     with TemporaryDirectory(prefix="gh1638-overlay-") as tmp:
         host, dst = (Path(tmp) / name / "seeded" for name in ("host", "checkout"))
         for path, version in ((host, "v2"), (dst, "v1")):
             (path / "sub").mkdir(parents=True)
             (path / "sub/g.txt").write_text("s1")
             (path / "f.txt").write_text(version)
         (dst / "retired.txt").write_text("only in HEAD")
         result = run(["cp", "-R", str(host) + "/.", str(dst)], check=True)
         ok = (not any(p.name == "seeded" for p in dst.glob("*"))
               and not any(p.name == "seeded" for p in dst.glob("*/*"))
               and (dst / "f.txt").read_text() == "v2"
               and (dst / "sub/g.txt").read_text() == "s1")
         print(f"cp exit={result.returncode}; seeded assertions={ok}; "
               f"retired file survives={(dst / 'retired.txt').exists()}")
     ```

2. **[Should] Check that #1638's packaged copy actually contains the fix.**
   - Observed input: the archive regeneration is explicit acceptance and a declared write (`GH-1638-RELAY-SEED-DIR-NESTING.md:34,81-101`). The probe loads the live library and the second probe checks only receipt path existence (`probe-gh1638.sh:2,13`, `utils/py/swarm_preflight.py:265-266,283-293`). The selected gate, `test/worktree-isolation.sh`, exercises the live library (`:181-191`) and does not compare archive bytes. The retained fixed+receipt arm returns exit 4 (`preflight-arms.txt:10`) without reporting an archive freshness measurement. A read-only `PYTHONDONTWRITEBYTECODE=1 python3 -` comparison extracted the library member with `tarfile`, then compared it with the live source and the source with the one insertion from `sim-gh1638.patch:9`. Python exited 0 and printed `archive == baseline: True` and `archive == simulated source: False`.
   - Affected scope: #1638 delivery acceptance for the installed relay skill. Use the existing `test/relay-pkg-freshness.sh:7-34` as part of the selected gate or record its result as a required delivery check. Keep the existing worktree gate and introduce no new suite.
   - Falsifier: a source-only fix plus a receipt fails the package check. The same source with the package regenerated passes, and the delivery records that result.
   - Clone probe: from the disposable full clone on the source-only simulated-fix arm, run `bash test/relay-pkg-freshness.sh` and retain its exit and reported drift. Then run `bash skills/1-hourly/relay-automation/make-pkg.sh && bash test/relay-pkg-freshness.sh` on the same arm and retain the exit and output. I did not run these gates here.

3. **[Should] Prove #1666's CR/LF-only rule beyond the three reported Unicode examples.**
   - Observed input: `GH-1666-ACCEPTANCE-MARKDOWN-LINE-MODEL.md:35,101` requires the readers to split on CRLF, CR and LF only. `probe-gh1666.py:3-15` catches the issue-only and two-reader mutants and checks raw fidelity, but it checks only U+0085/U+2028/U+2029 as non-breaks. I ran `PYTHONDONTWRITEBYTECODE=1 PYTHONPATH=utils/py python3 -` with the three readers loaded from memory, wrapping each original `text.splitlines()` with masking/restoration of just those three code points (to/from U+E100/U+E101/U+E102) and setting `marker_lines = list(lines)` as in the simulated patch. The command ran the exact seeded probe and then extracted and inlined `"## Acceptance\n- [ ] Alpha\vbeta\n- [ ] Gamma\n"`. It exited 0 and printed `seeded probe passed`, `U+000B extraction: ['Alpha', 'Gamma']` and `U+000B raw checklist: ['- [ ] Alpha']`. The capture's simulated fix already uses the broader rule.
   - Affected scope: the inline probe and its planned case in the existing #400 suite. Extend the same loop to the other Python line separators (U+000B, U+000C and U+001C–U+001E). Preserve the three reported examples, raw-line equality and real CR/LF controls.
   - Falsifier: the current full simulated fix passes the extended table. A reader retaining broader Python splitting fails on a non-CR/LF separator even when it explicitly handles the original three. A correct fix may normalize criterion whitespace while preserving the separator in the raw checklist.

4. **[Should] Make the retained provenance replayable for the cited consumer arms.**
   - Observed input: `SUMMARY.md:4-6` says every command, head and exit is retained. `provenance.jsonl:14-19` has the full consumer-arm commit IDs and exits, but its command is the label `swarm-preflight --dry-run (target-root scratch clone)`, omitting the project doc, actual entry point and target arguments. The hostile `GIT_DIR` arms in `matrix.txt:12-14` and the admission checks in `admission-checks.txt:1-4` have no corresponding invocation in the provenance. The table distinguishes the two exits correctly.
   - Affected scope: replay of the preparation evidence requested in Round 1. Record exact invocations with a bound variable for the disposable clone and identify how each proof arm was constructed so the commit ID has a reproducible input.
   - Falsifier: a producer can replay the base, fixed-with-receipt and fixed-without-receipt arms from the retained commands and patch/receipt inputs, and correlate the selected command, evaluated commit, exit and output. The preparation evidence remains labelled as pending publication, merge and the exact-ref recheck.

#### Verified preparation evidence

- Capture parsing and linting agreed with the readable probe files. `PYTHONDONTWRITEBYTECODE=1 PYTHONPATH=utils/py python3 -` using `swarm_preflight.extract_contract`, `jog_run.lint_probe` and direct JSON reads exited 0. Each packet reported cap 9, the full expected pin, `(True, 'ok')` and identical here-doc contents. The three base receipts evaluated `development` at `6142128d9c433d6b12972c6cd9a6f864f0ed9da2`, READY with two unfixed probes. `python3 TESTS-RESULTS/2026-11-27+GH-1658-runA-prep/probe-gh1666.py` with bytecode disabled returned 1 with `AssertionError: ('0x85', ['Alpha', 'Gamma'], ['Alpha', 'Gamma'])`. The producer's positive and negative clone-arm receipts were inspected; I did not rerun Git fixtures or consumer gates.
- The effective lane intersections extracted from the three base JSONs match `SUMMARY.md:34-39`. The declared paths are disjoint, and the shared inferred paths are reserved. The stated pin and cited paths reach the #1664 stale check (`utils/py/jog_run.py:1779-1818`), ahead of lease acquisition (`:3163-3179`).
- An immutable SQLite read using `PYTHONDONTWRITEBYTECODE=1 python3 -` returned the exact four ratings in `prs-readback.txt`, all in Queue / parked intake with no override, zero matching Jog rows and no #1590 row. The seeded project tree has no #1590 capture. The historical-pin backlog scan remains retained producer evidence. The source graph was from a separate checkout, so I used exact local source for the cited lines.
- GitHub returned #1480 and #1475 open. The issue's explicit dependency matches the capture's `HELD:` marker and the recorded pre-lease refusal. #1666 and #1423 each match all three live issue checkboxes literally, including U+2028 in #1666. #1423's only issue comment records the already-reused #1424 capture and an open fix. Its AST constraint is explicit and permits both local fix shapes. Its helper proof and full-driver delivery requirements are now distinguished. #1638's source issue confirms both symptoms and has zero comments. The packet states its partial scope and the issue closure behavior supports that scope.

### Round 2 · Producer · claude-a

All four findings accepted and fixed. Ready set unchanged: #1666, #1423, #1638; #1480 held.

1. **#1638 directory mirror (Blocker) — fixed.** The plan and simulated fix (`sim-gh1638.patch`) now touch **directory entries only** (not symlinks): an existing destination is resolved and removed only when it lies strictly inside the worktree (`"$_wtp"/?*`), otherwise the begin refuses; a failed `cp -R` removes the worktree and returns 1 (the caller already falls back on a failed begin). File entries keep today's `cp -R`. The probe (`probe-gh1638.sh`) now also requires: a tracked child deleted on the host is absent, an ordinary file entry (`plain.txt`) seeds its current bytes, and a directory whose copy fails (one `chmod 000` file) makes `rtl_worktree_begin` return non-zero. Your contents-only overlay is a retained fake (`fake2-gh1638-overlay.patch`) and fails on the deleted child. Acceptance gained two declared criteria (deleted child and file entries; failed copy and bounded removal).
2. **#1638 package (Should) — fixed.** The probe compares the `relay-automation/relay-turn-lib.sh` member of `relay-pkg.tar.gz` with the live file, so a source-only fix plus receipt reads unfixed (`matrix.txt`: `sim-gh1638` 1, `sim-gh1638-with-pkg` 0). Your clone probe ran (`pkg-freshness-arms.txt`): on the source-only arm `bash test/relay-pkg-freshness.sh` exits 1 (drift: `relay-automation/relay-turn-lib.sh`); after `make-pkg.sh` it exits 0. The Acceptance and remediation require that result in the delivery receipt.
3. **#1666 CR/LF-only (Should) — fixed.** The probe loop now covers U+000B, U+000C, U+001C-U+001E, U+0085, U+2028, U+2029. Your mask-three reader is retained as `fake3-gh1666-mask-three.patch` and fails (`('0xb', ['Alpha', 'Gamma'], …)`); the full simulated fix still passes.
4. **Replayable provenance (Should) — fixed.** Every `provenance.jsonl` row now has `build` (exact arm construction from the retained patch and receipt), `cwd` (`$P`, `$PROOF`, `$SCRATCH`), the full command, evaluated head, exit and output, including the hostile-`GIT_DIR` arms, the admission checks and the package-freshness arms.

Re-run results: READY preflight exit 0 for all three at `6142128d9c43`; consumer arms fixed+receipt → 4 and fixed-no-receipt → 7 for all three (#1638 on the with-package fix); admission checks unchanged; parser/linter read-back matches the proved copies. Round 3 of 4.

### Round 3 · Reviewer · codex

VERDICT: FAIL

#1666 and #1423 pass preparation review, and #1480 is correctly held. #1638's simulated fix can report success after a failed replacement, so the batch stays open.

1. **[Blocker] #1638 must stop when it cannot replace the destination directory.**
   - Observed input: `TESTS-RESULTS/2026-11-27+GH-1658-runA-prep/sim-gh1638.patch:12-24` ignores the exit from `rm -rf "$_dst"`. If the destination survives, the subsequent successful copy recreates the original nested tree. The normal seed tail logs `SEED` and returns a worktree path (`relay-automation/relay-turn-lib.sh:785,826-829`). `utils/py/rtl.py:1156-1161` passes that path back and `utils/py/codex-turn.py:83-91` accepts it for the isolated turn. The current red control exercises a failed source copy only (`probe-gh1638.sh:36-44`). Its readable arm also skips all content checks when there is no valid returned worktree directory (`:26-35`).
   - Affected scope: the #1638 directory-only plan, simulated fix and inline proof. Check successful physical path resolution and destination containment before the directory operation, and refuse on a failed removal before attempting the copy. Make the readable arm require a nonempty, existing returned worktree before checking contents. Keep the package and file-seed controls. Clarify the failure handoff in the plan. The Python Codex caller above exits 5 when isolation is requested and begin fails.
   - Falsifier: a controlled destination-removal refusal yields nonzero and no usable worktree path even when the source is readable. A stub returning success with no path fails the readable arm. The complete mirror with the refreshed archive still passes, and the overlay with a stale child still fails.
   - Narrow replay, run as `PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp" python3 -` with the body below. The interpreter exited 0. The copied branch printed `seed exit: 0 stderr: controlled rm refusal` and `top bytes: HEAD nested copy: True`. The replay never invokes Git or performs the directory removal.

     ```python
     from pathlib import Path
     from tempfile import TemporaryDirectory
     import subprocess

     p = Path("TESTS-RESULTS/2026-11-27+GH-1658-runA-prep/sim-gh1638.patch")
     block = "\n".join(line[1:] for line in p.read_text().splitlines()[9:27])
     assert 'rm -rf "$_dst"' in block
     with TemporaryDirectory(prefix="review-rm-failure-") as d:
         host, wt = (Path(d) / x for x in ("host", "wt"))
         for root in (host, wt):
             (root / "seeded").mkdir(parents=True)
         (host / "seeded/current").write_text("host")
         (wt / "seeded/current").write_text("HEAD")
         result = subprocess.run(
             ["bash", "-c", 'RTL_ROOT="$1"; wt="$2"; a=seeded\n'
              'rm() { printf "controlled rm refusal\\n" >&2; return 1; }\n'
              'seed() {\n' + block + '\n}\nseed', "_", str(host), str(wt)],
             capture_output=True, text=True)
         print("seed exit:", result.returncode, "stderr:", result.stderr.strip())
         print("top bytes:", (wt / "seeded/current").read_text(),
               "nested copy:", (wt / "seeded/seeded/current").is_file())
     ```

2. **[Should] Finish the replay instructions for the cited consumer evidence.**
   - Observed input: `TESTS-RESULTS/2026-11-27+GH-1658-runA-prep/SUMMARY.md:6` describes every command as replayable. `provenance.jsonl:25-28` appends `(n=1480)` and its equivalents outside the quoted Python command while leaving `n` undefined inside. I passed the first admission row's decoded `cmd` plus a newline to `subprocess.run(["bash", "-n"], input=cmd+"\n", capture_output=True, text=True)` from `python3 -`. Bash exited 2 with `syntax error near unexpected token '('`. The consumer commands in `:19-24` now name the correct entry point and target. Their `build` descriptions still omit the prep-clone path to the patch from the scratch clone and the creation of the parent directory before writing the new delivery file.
   - Affected scope: the Round 2 replayability finding and the summary's evidence claim. Retain an executable admission invocation that supplies the issue number and the intended target and lookup inputs. Separate the scratch-clone construction cwd from the consumer invocation cwd and include the missing construction steps. The #1638 summary table at `:17` should also say four `[added]` criteria, matching its capture at `:42-45`.
   - Falsifier: a reader can replay the four admission rows and construct the fixed-with-receipt and fixed-without-receipt arms from the recorded variables and commands. The retained decisions remain hold for #1480, no refusal for the other admission snapshots, and consumer exits 4/7 for the corresponding fixed arms.

#### Review evidence

- `PYTHONDONTWRITEBYTECODE=1 PYTHONPATH=utils/py python3 -` read all three contracts with `swarm_preflight.extract_contract` and `jog_run.contract_probes_from_doc`, compared each command with the corresponding `.cmd.json` and its here-doc body with the readable probe, and parsed the retained base JSONs. It exited 0. Each packet reported pin `6142128d9c433d6b12972c6cd9a6f864f0ed9da2`, cap 9, two labels, no reason and retained READY exit 0.
- `PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp" python3 TESTS-RESULTS/2026-11-27+GH-1658-runA-prep/probe-gh1666.py` exited 1 at `('0xb', ['Alpha', 'Gamma'], ['Alpha', 'Gamma'])`. The revised probe checks every non-CR/LF separator that Python `splitlines()` treats as a line break. The retained green and three red arms cover the full fix, issue-side-only fix, missing deviations reader, and mask-three change. The archive-drift evidence also now distinguishes source-only from regenerated package (`pkg-freshness-arms.txt:1-12`).
- #1423's helper proof and delivery requirements remain as adjudicated in Round 2. #1480 remains explicitly held in its capture with no build contract, and the retained admission check records the expected pre-lease refusal. #1590 remains withdrawn. I inspected retained clone evidence and used exact local source because the available graph indexes a separate checkout. I ran no Git fixture or gate in this turn.

### Round 3 · Producer · claude-a

Both findings accepted and fixed. This is round 4 of 4.

1. **#1638 uncleared destination (Blocker) — fixed.** `sim-gh1638.patch` / `sim-gh1638-with-pkg.patch` now resolve the worktree and the entry's parent physically and fail the begin if either resolution fails, require containment, then `rm -rf` the destination and fail the begin if `rm` fails **or** the path still exists, all **before** the copy; a failed copy also fails it. Every failure removes the worktree and returns 1 with no path echoed. The capture's plan states the handoff (`rtl.py:1156-1161` returns None; `codex-turn.py:83-91` exits 5 when isolation was requested). The probe gained arm 3: `rm` shadowed to refuse the `…/seeded` destination with a readable source, which must give rc≠0 and no path. The readable arm now fails outright when no usable worktree path comes back. `matrix.txt`: base 1, source-only 1, with-package 0, skip-dirs fake 1, overlay fake 1, and your round-2 simulated fix retained as `fake3-gh1638-rm-unchecked.patch` 1 (`uncleared checkout copy still reported a seed`).
2. **Replay instructions (Should) — fixed.** Admission rows now carry an executable command per issue (`n=<N>` inside the Python; each passes `bash -n`). Every matrix and consumer-arm `build` names the full construction from `$SCRATCH`, including `git apply --binary $P/<patch>`, `mkdir -p` before the receipt, and the commit; consumer commands run from `$P`. `SUMMARY.md` now says four `[added]` for #1638.

Re-run: READY preflight exit 0 for all three at `6142128d9c43`; consumer arms 4/7 for each; admission checks unchanged (#1480 held, others None); parser/linter read-back matches.

### Round 4 · Reviewer · codex

VERDICT: FAIL

#1666 and #1423 pass preparation review. #1480 is correctly held on #1475. #1590 remains withdrawn. #1638 still has a containment blocker. This is the last configured review round.

1. **[Blocker] #1638's directory-seed failure path can write outside the worktree and bypass Git's teardown refusal.**
   - Observed input: `relay-automation/relay-turn-lib.sh:782-784` creates the destination parent before copying. `TESTS-RESULTS/2026-11-27+GH-1658-runA-prep/sim-gh1638.patch:7-22` retains that `mkdir -p` ahead of the new physical-parent check. With a real host directory and a checkout parent symlink pointing outside the worktree, the branch creates the missing parent directory outside the worktree before refusing. The patch also runs `rm -rf "$wt"` at `:16,22,27,32` even if `git worktree remove --force` fails. That can erase the checkout while leaving it registered. `WORKTREE-SAFETY.md:59-79` requires Git-managed removal. The capture at `PROJECT/1-INBOX/GH-1638-RELAY-SEED-DIR-NESTING.md:55` promises a bounded destination and removal on failure. The existing controls cover an ordinary mirror, a failed copy and a refused destination deletion (`probe-gh1638.sh:19-61`). They leave this path untested.
   - Affected scope: the #1638 directory-only plan, simulated green arm and failure handling. Prove the destination's existing ancestry is inside the worktree before creating missing parents. Use Git-managed teardown for the linked worktree and make a teardown refusal visible. Preserve the file-seed behavior and the existing mirror and package controls.
   - Falsifier: a directory entry with an escaping checkout parent fails without returning a worktree path or creating any outside directory. A controlled Git teardown refusal yields an observable failure with no raw worktree deletion. The ordinary mirror, package, and existing failure controls still pass with the corrected simulated fix.
   - Narrow replay run as `PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp" python3 -`. The interpreter exited 0. The branch exited 1 with empty stdout and printed `REFUSE seed parent/new/seeded resolves outside the worktree` followed by `mock raw removal called for -rf`. The scratch fixture reported `outside new directory=True`. Both Git and raw removal were stubbed.

     ```python
     from pathlib import Path
     from tempfile import TemporaryDirectory
     from subprocess import run

     d = Path('TESTS-RESULTS/2026-11-27+GH-1658-runA-prep')
     patch = (d/'sim-gh1638.patch').read_text().splitlines()
     block = '\n'.join(line[1:] for line in patch[6:37] if not line.startswith('-'))
     with TemporaryDirectory(prefix='gh1638-parent-') as temp:
         host, wt, outside = (Path(temp) / key for key in ('host', 'wt', 'outside'))
         (host/'parent'/'new'/'seeded').mkdir(parents=True)
         wt.mkdir()
         outside.mkdir()
         (wt/'parent').symlink_to(outside, target_is_directory=True)
         proc = run(['bash', '-c', """
     RTL_ROOT="$1"; wt="$2"; a=parent/new/seeded
     git() { echo "mock worktree remove refused" >&2; return 1; }
     rm() { echo "mock raw removal called for $1" >&2; return 0; }
     rtl_trace() { printf '%s\n' "$*" >&2; }
     seed() {
     """ + block + """
     fi
     }
     seed
     """, '_', str(host), str(wt)], capture_output=True, text=True)
         print(f'branch rc={proc.returncode}; stdout={proc.stdout!r}; '
               f'stderr={proc.stderr.strip()!r}; outside new directory={(outside/"new").is_dir()}')
         assert proc.returncode == 1 and not proc.stdout and (outside/'new').is_dir()
         assert 'mock raw removal called' in proc.stderr
     ```

#### Verified preparation evidence

- The Round 3 unchecked destination-removal finding is resolved for the ordinary directory path. `sim-gh1638.patch:24-33` checks both the removal result and the path's absence before copying. The readable probe requires an existing returned path and tests a refused destination removal (`probe-gh1638.sh:26-35,49-61`). The retained packaged green arm exits 0 and the unchecked-removal fake exits 1 (`matrix.txt:12,15`).
- The Round 3 provenance finding is resolved for replay. I passed each decoded admission command from `provenance.jsonl:26-29` to `bash -n` and checked the numeric input in the embedded Python. Each syntax check returned 0. The fixed arms include the patch path rooted at the preparation clone and create the delivery directory before writing the receipt (`:20-25`). Those retained executions report exits 4 and 7 for each item. The check of the records did not execute the live admission lookups or rebuild the clone arms.
- `PYTHONDONTWRITEBYTECODE=1 PYTHONPATH=utils/py python3 -` using `swarm_preflight.extract_contract`, `jog_run.contract_probes_from_doc`, and direct reads of the retained JSON and probe copies exited 0. Each ready contract returned two labels with no lint error, the exact proved probe, cap 9, the full prepared pin, and a retained base exit 0 with consumer exits 4/7. The standalone `python3 TESTS-RESULTS/2026-11-27+GH-1658-runA-prep/probe-gh1666.py`, with bytecode disabled and workspace scratch as `TMPDIR`, exited 1 at the expected baseline assertion `('0xb', ['Alpha', 'Gamma'], ['Alpha', 'Gamma'])`. The retained #1480 receipt records `hold: capture body HELD: marker` and its capture has no build contract. No Git fixture or gate was run in this turn.

### Round 4 · Producer · claude-a

Round cap reached (4 of 4). The single open finding is answered below; per the Flywheel cap rule it goes to a consult tie-break instead of a fifth review round. #1666, #1423 and #1480 passed in rounds 3 and 4.

1. **#1638 containment on the failure path (Blocker) — fixed in plan, simulated fix and probe.** `sim-gh1638.patch` now proves the deepest **existing** ancestor of the entry's parent resolves inside the worktree **before** `mkdir -p`, re-checks the parent after creating it, then clears and copies. All failures go through one helper, `_rtl_seed_abort`, which tears down with `git worktree remove --force` only and, if Git refuses, prints `git worktree remove refused …; left in place for inspection` and never raw-deletes the worktree. File entries keep `mkdir -p` + `cp -R`. The probe gained arm 4 (your replay: tracked checkout symlink `parent -> <outside>` with a real host directory; the begin must fail with no path and `<outside>/new` must not exist) and arm 5 (`git worktree remove` shadowed to refuse after a failed copy; the refusal must be reported and the worktree must still exist). `matrix.txt`: base 1, source-only 1, with-package 0, skip-dirs 1, overlay 1, rm-unchecked (round-2 fix) 1, mkdir-first (round-3 fix, retained as `fake4-gh1638-mkdir-first.patch`) 1. READY preflight exit 0 and consumer arms 4/7 re-run; admission checks unchanged.

### Cap tie-break · consult (coordinator: claude-a)

**Outcome: Consult-Adjudicated — PUBLISH all four packets (#1666, #1423, #1638 ready; #1480 held). Never auto-merge.** Review rounds were exhausted at 4/4 with one open #1638 Blocker (round 4). The producer's round-4 response was put to a consult tie-break instead of a fifth round.

- **Panel 1** (`relay-system/2026-11-27/gh1638-cap-tiebreak-142053/`): degraded. The Codex seat failed before reviewing (its backend refused the prompt with a content flag; see the `.codex.md.transcript`). The surviving agy seat said PUBLISH with one [Should]: refuse `.`, `..` and empty path segments in a directory entry. Folded into the plan, `sim-gh1638.patch` and probe arm 6; `fake5-gh1638-no-dotdot-guard.patch` reads unfixed.
- **Panel 2** (`relay-system/2026-11-27/gh1638-cap-tiebreak-r2-142845/`, agy + kimi, both answered): **both PUBLISH**, reconciled blind before attribution. **Agree:** the round-4 Blocker is resolved (deepest existing ancestor proven inside the worktree before `mkdir -p`; teardown is `git worktree remove --force` only, refusals reported, no raw `rm -rf "$wt"`); base, source-only and all five fakes read unfixed and the packaged fix reads fixed; scope is still one loop plus one helper in one file plus `make-pkg.sh`. **Disagree:** none on the verdict. One seat added a second probe gap (no multi-segment directory positive case), with an in-sandbox mutant that passes the probe. Both called the gaps build-QA items, not HOLD: the plan and remediation require the behaviour, and the implementation gets its own independent review. Deciding criterion: claims checked against the source (both cited `sim-gh1638.patch:31-53` and `probe-gh1638.sh` and replayed fixtures). The `.`/empty-segment and multi-segment checks are recorded as a builder checklist in the capture's recon note.

Rounds 1-4 approved #1666 and #1423 (rounds 3 and 4) and #1480's hold (rounds 1-4). #1590 stays withdrawn (prior operator hold).

