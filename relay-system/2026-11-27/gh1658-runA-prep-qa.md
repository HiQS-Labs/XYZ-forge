---
Goal: Independent preparation QA — Conveyor packets for Flywheel Run A (ledger #1658): #1590, #1666, #1423 ready; #1480 held
Date: 2026-11-27
NEXT: claude-a
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
