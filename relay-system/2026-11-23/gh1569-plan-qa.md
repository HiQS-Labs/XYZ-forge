# RELAY · GH-1569 plan QA (build_queue daily-goals checklist-only)
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-11-23.
-->

NEXT: Producer
STATUS: Approved
ROUND: 2 / 3

## ▶ TAKE YOUR TURN — read this first (works for ANY agent: Claude, Codex, agy)
1. **Read this whole file** (header, Setup, Ground rules, every block in the Log).
2. **Check it's your turn:** `NEXT` (top) names the role to act. Confirm you are bound to it and the
   last Log block isn't already yours. If not → STOP and reply "wrong window — nudge the <other> window."
3. **Do your role's work** on the artifact named in Setup:
   - **Reviewer:** review vs the Definition of Done → graded findings
     (`[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`), each with a concrete fix → set a **VERDICT**
     (exactly PASS, FAIL, or PARKED) and a **Basis** (explanation). **Review the whole file, not just the diff** (GH-268):
     a beta test had this loop reach `Approved` in two rounds while an independent audit of the same
     branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the
     change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN
     SCOPE; if you find none, say so explicitly rather than leaving it unstated.
     **Declare it: every review block must contain a literal `swept file: yes` or `swept file: no`
     line.** Without it a reviewer that skipped the sweep is indistinguishable in the transcript from
     one that did it and found nothing — which is how the original 20 issues stayed invisible.
     Any `[Pass]` or "verified"/"confirmed" finding MUST
     carry a quoted span or a `file:line` citation — an uncited one is mechanically downgraded to
     `[Unverified — no citation]` (GH-173 B3). Do **not** edit the artifact; only append findings here.
     **A finding that asks for a behaviour change is a generalization unless you can paste the concrete
     input — a row, a value, a `file:line` — that fails under the current code** (GH-681: the gh673
     final QA relay generalized one late-error observation into "or a later invalid identity", the
     Producer implemented it, the same seat `[Pass]`ed it next round, and one historical NULL-URL
     ledger row then blanked every issue). Every `[Blocker]` or `[Should]` requesting a behaviour
     change MUST carry `Observed input:`, `Affected scope:` (the input predicate the change would govern),
     and `Falsifier:` (the fixture or data that would show the change unnecessary or wrong, and its expected
     result). `Observed input:` accepts two strict, non-speculative forms:
     (1) **Form 1 (observed failure or artifact contradiction):** a failing probe/gate output, or a concrete
     `fileA:line` vs `fileB:line` contradiction (e.g. IAM SA mismatch, inverted test, sibling guard omission);
     (2) **Form 2 (unrunnable runtime hazard trace):** permitted ONLY when reproduction requires an external
     service, multi-process concurrency, or a browser/container runtime forbidden in the relay worktree —
     must supply a hop-by-hop `file:line` trace plus an exact `Clone probe:` command/script for the Producer's
     disposable full clone. Default severity for an unexecuted Form 2 hazard is `[Should]`.
     A `[Blocker]` must cite an observed failure (Form 1); an unexecuted Form 2 hazard stays `[Should]`
     until a probe reproduces it, and remains pending probe verification until the Producer runs
     `Clone probe:` in a disposable full clone.
     A finding from an earlier round stays open, and the verdict stays failing, until new evidence closes it.
     This includes earlier [Nit] findings; only a newly raised [Nit] with VERDICT: PASS on STATUS: Approved remains optional.
     This is a protocol rule, not a mechanical check —
     the Producer may disposition a request lacking Form 1 evidence and lacking a complete Form 2 trace + `Clone probe:` as `Declined — unproven generalization`.
   - **Producer:** log a disposition for every open finding (Implemented / Modified / Declined + why,
     including `Declined — unproven generalization` for a behaviour-change request lacking Form 1 evidence and
     lacking a complete Form 2 trace + `Observed input:` / `Affected scope:` / `Falsifier:` / `Clone probe:`).
     For every Form 2 `Clone probe:` finding, read the probe before running it — refuse any probe that reaches
     the network, credentials, or paths outside the disposable clone and record the refusal as
     `[Unverified — clone probe failed/unavailable]` — then execute safe probes in a disposable full clone and
     record one of three outcomes: (a) Reproduced → fix and paste failing-before / passing-after probe output;
     (b) Falsified → `Declined — falsified by clone probe: <cmd → exit + output>`; (c) Errored, refused, or
     environment unavailable → keep the finding OPEN (`[Unverified — clone probe failed/unavailable]`, blocking
     `STATUS: Approved` until re-run cleanly or escalated/parked). Make approved changes, then add new work.
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
   Reviewer headings may be `### Reviewer · Round N`, `### Round N · Reviewer · <agent>`, `### Reviewer (<agent>)` (optionally followed by `— rN`), or `### Reviewer — Round N` (optionally followed by `(<agent>)`); follow the heading with a non-empty review body.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Manual relay: commit only the relay file** (`relay(gh1569-plan-qa): <role> r<N>`); no push.
   **Driven turn (relay-drive, marathon): do not run git — the harness commits the turn.** **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. (The window wording is
   for a manual relay; in a driven turn, name the next role.) The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: `PROJECT/1-INBOX/GH-1569-DAILY-GOALS-CHECKLIST-ONLY.md` (the PLAN, no code written yet).
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-11-23
- Operational envelope: a ~540-line local developer CLI script (`skills/1-hourly/kickstart/scripts/build_queue.py`),
  read-only, run by an operator at kickstart launch. Grade against the stated requirements and commensurate
  complexity; this repo forbids new test suites (AGENTS.md "No new tests", GH-831), so a request for a new
  `test/` file, `validate.sh` entry or gate machinery is itself out of scope. Verification is by manual
  red/green under `TESTS-RESULTS/<date>+GH-<n>/` with `provenance.jsonl`.
- Requirements (the issue, https://github.com/HiQS-Labs/XYZ-forge/issues/1569): when the daily-goals issue body has a
  task list, admit only numbers on unchecked `- [ ]` lines (a checked `- [x]` line and prose are not admitted). ONE lead
  number per checklist line: the FIRST `#N` on the line is the item, later `#N` on that line are references. A body with no
  task list must behave exactly as today OR fail closed (pick the smaller, state it, prove it). Also handle any other
  readers of that body. Red: replay #1568's ORIGINAL body (before its 2026-11-20 edit) through `--daily-goals-json`:
  #1480/#1483 queued and #1537 in Needs-the-operator on base; green: they are not. Also prove #1568's CURRENT body still
  yields its 7 items and that checklist lines carrying nested refs such as `(GH-…)` or `after #N` behave as stated.
- Evidence already in the repo (committed): `TESTS-RESULTS/2026-11-23+GH-1569/` (inputs, `run.sh`, red output on base).

## Definition of Done (for THIS plan review)

STEP 1 — before opening any file other than the plan, write under headings, 2-5 sentences each:
**What this proposes**, **How the existing system works, per this document**, and (short) **What it's not**.
Ground exclusions in the plan's sections; label inference and missing boundaries rather than inventing non-goals.
Quote this paraphrase as the first part of your review block and state its input boundary ("plan only").
STEP 2 — then read the requirements above and the source (`build_queue.py` lines 86-110, 259-279, 435-510; `SKILL.md`
302-308; the red output) and label the rest of your review "source-backed". If your STEP 1 paraphrase mismatches the
plan, say whether the plan failed to explain it or you misread.

Questions (cite `file:line`; findings graded per the protocol above):
1. Is the plan grounded in the actual code? In particular, is `parse_daily_goals_refs` really the ONLY reader of the
   daily-goals body that can admit numbers? Name any other reader the plan missed (check `main()` and `parked_issues`).
2. What prevents an unchanged, unfixed `build_queue.py` from being reported as delivered, and where is the observed
   rejection? Is the red (original-body replay) a real discriminator, and do acceptance rows 3-7 each fail on base?
3. Is the decision for no-task-list bodies (keep today's behaviour rather than fail closed) justified as the smaller
   option, and is the proof (byte-identical replay vs base) sufficient?
4. Edge cases of "task list" detection and the lead-ref rule: indented/nested checkboxes, `+` and `1.` bullets,
   `- [ ]` with no ref, lead ref foreign-repo or self, `- [X]` upper-case, sanitized backtick refs. Does the plan define
   each, or leave a bug? Give a concrete input if you claim a defect.
5. Is the change surgical and DRY (extends `parse_daily_goals_refs`, no second parser, no new flag/test/suite)?
6. Are the risks/rollback and the SKILL.md update adequate? Is anything over- or under-engineered?

Write the verdict (PASS / FAIL) with a Basis; include a literal `swept file: yes|no` line.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). In a manual relay, end each turn by committing just this file; no push. In a driven turn the harness commits.

## Log

### Reviewer · Round 1 · codex

Input boundary: **plan only** for the paraphrase below; no implementation or evidence files read yet. Procedural note: ROUTER.md was read alongside the relay before STEP 1; it supplied no facts for this paraphrase.

> **What this proposes**
>
> Change daily-goals selection so a body containing checkbox lines contributes only the first reference on each unchecked line. Preserve the existing prose behavior for bodies without checkboxes, update the skill paragraph, and demonstrate the distinction with retained manual evidence (plan lines 36-54).
>
> **How the existing system works, per this document**
>
> The plan says `parse_daily_goals_refs` is the sole reader that admits references from the daily-goals body, collecting all references outside checked lines. It attributes the three unwanted #1568 selections to prose and says atomic reference matching already excludes foreign-repository references and leaves `GH-N` text inert (lines 16-34).
>
> **What it's not**
>
> The explicit non-goals exclude changes to resolution, holds, age filtering, exit codes, flags, and new suites (lines 56-57). The described parser accepts `-`, `*`, `+`, and numbered-dot checkbox bullets; other task syntaxes are excluded, while sanitized inline-code behavior remains a boundary to verify from source.

**Source-backed review**

swept file: yes

Swept the entire 81-line plan and all 544 lines of `skills/1-hourly/kickstart/scripts/build_queue.py`, plus the named skill paragraph and retained inputs/output. The paraphrase matches what the plan says; the source contradicts its sole-reader explanation, rather than revealing a paraphrase misreading. Verify-tier source fallback: `list_projects` returned all 86 projects (no matching worktree); the nearest Forge index was generation `2026-11-23T23:18:20Z`, at a different checkout. Symbol search returned zero results and coverage reported `freshness: missing` for all five requested evidence paths. Findings therefore rely on this worktree's exact source, not graph completeness. No further concrete pre-existing defect was found in this bounded sweep beyond the known admission bug and the documentation/evidence discrepancies below; this is not runtime certification.

- **[Should] R1 — Correct the reader inventory and explicitly preserve the safety reader.** Observed input: plan `PROJECT/1-INBOX/GH-1569-DAILY-GOALS-CHECKLIST-ONLY.md:26-29` says the body is read in exactly one place and other readers see only other issues. Source contradicts that: `build_queue.py:432` copies *all* fetched issues to `safety_issues`; when that includes the goals issue, `:517` passes it to `parked_issues`, `:214-222` invokes `issue_hold_reason`, and `:187-200` reads its body and numeric dependencies. A concrete goals body `- [ ] #10 after #11`, with open refs `{10,11,1568}`, puts **1568**, not 11, in the parked set (probe below). This can hold an admitted PR closing the goals issue through `classify_prs` at `:242-243`; it does not admit #11 to the execution queue. Affected scope: goals issues present in the safety collection, including a goals issue fetched as an admitted PR's closing target at `:495-504`. Falsifier: show that this issue is excluded before `:517`, or that the probe returns an empty set; current source and output show neither. Fix: distinguish the sole **queue-admission parser** from the safety reader and state that safety/hold parsing stays intact. Do not apply checklist selection to hold evidence or remove that reader.

- **[Should] R2 — Make acceptance rows precise about context and defect sensitivity.** Observed input: plan `:69` gives `other/repo#9 then #10` without a checkbox, expects no result, but `:38-48` preserves prose behavior, which returns `[10]`. Also `:65` groups `(GH-1700)` with extra `#N` cases under “later refs admitted (base)”, although source `build_queue.py:98,270` and the probe below return only `[10]` for `- [ ] #10 (GH-1700)`. Affected scope: the acceptance matrix and its later manual replay; no broader parser feature requested. Falsifier: those exact inputs would have to return `[]` and an extra numeric reference respectively on base; they do not. Fix: put an explicit unchecked checkbox on row 7; split the GH-only example into a preservation control, and label rows 2, 5, 6 as regression controls. Rows 3 (actual second `#N`), 4 (prose beside a checkbox), and 7 (unchecked foreign lead plus local secondary ref) distinguish changed behavior. Rows 3–7 do **not** each fail on base: row 5 intentionally preserves base, and row 6 already yields no refs and reaches the existing zero-selection exit at `:482-483`. Keep the real original-body rejection as the delivery discriminator; do not count a successful CLI exit as acceptance.

  Exact narrow probe for R1/R2 (exit **0**, no source mutation):

  ```bash
  export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"
  python3 - <<'PYPROBE'
  import runpy
  m=runpy.run_path('skills/1-hourly/kickstart/scripts/build_queue.py',run_name='review')
  p=m['parse_daily_goals_refs']
  for body in ('- [ ] #10 (GH-1700)', '- [ ] #10 after #1601', '- [x] #9\nprose #10', 'prose #10', '- [x] #10', '- [ ] other/repo#9 then #10'):
   print(repr(body),p(body,'HiQS-Labs/XYZ-forge',1568))
  i={'number':1568,'title':'Daily goals','body':'- [ ] #10 after #11'}
  print('parked daily goals:',m['parked_issues']([i],set(),set(),'noelsaw1',{10,11,1568}))
  PYPROBE
  ```

  Decisive output, in order: `[10]`, `[10, 1601]`, `[10]`, `[10]`, `[]`, `[10]`; `parked daily goals: {1568}`. The bare row-7 input follows the same base `ATOMIC_REF` loop (`:270-278`), and under the proposed no-task-list branch remains `[10]`.

- **[Should] R3 — Retain provenance for the red run already cited.** Observed input: plan `:16-22,63` cites an existing red run on `2ac998d130d9`, while `rg --files TESTS-RESULTS/2026-11-23+GH-1569` (exit **0**) lists only `run.sh`, one output, and five input JSON files; `Path('TESTS-RESULTS/2026-11-23+GH-1569/provenance.jsonl').exists()` returned **False**. `run.sh:1-7` only invokes the CLI and records no provenance. Affected scope: attribution of the already-cited red replay and eventual red/green receipts, required by AGENTS.md Rule 6; this is an evidence correction, not new gate machinery. Falsifier: a retained provenance record identifying this run, inputs, revision, command, exit and output would close it. Fix: retain the receipt alongside this evidence (or rerun on an explicitly identified base and record that result truthfully); do not invent historical metadata. Plan `:54` correctly promises provenance for later verification but does not establish the existing run's provenance.

- **[Pass] The original-body red is a real discriminator, and unchanged code was observed rejected.** `outputs/red-base-original-body.md:43-44,58` contains #1480/#1483 in Queue and #1537 in Needs-operator, exactly as plan `:20-22,63` reports. The following narrow offline replay produced `CLI rc: 0 matches retained red: True`, then exited **1** with `AssertionError: acceptance rejected unchanged code: [1480, 1483, 1537]`. This supplies an observed rejection, rather than treating `run.sh`'s exit 0 as delivery. No candidate green is claimed at plan review.

  ```bash
  export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"
  python3 - <<'PYPROBE'
  import contextlib, io, runpy, sys
  from pathlib import Path
  D='TESTS-RESULTS/2026-11-23+GH-1569/inputs/'
  sys.argv=['build_queue.py','--as-of','2026-11-20','--owner','noelsaw1','--repo-slug','HiQS-Labs/XYZ-forge','--other-session','1400,1418','--prs-json',D+'prs.json','--pr-meta-json',D+'pr-meta.json','--issues-json',D+'issues.json','--daily-goals','1568','--daily-goals-json',D+'1568-original-body.json']
  m=runpy.run_path('skills/1-hourly/kickstart/scripts/build_queue.py',run_name='review')
  out=io.StringIO()
  with contextlib.redirect_stdout(out): rc=m['main']()
  s=out.getvalue()
  assert s.strip(), 'empty replay'
  print('CLI rc:',rc,'matches retained red:',s==Path('TESTS-RESULTS/2026-11-23+GH-1569/outputs/red-base-original-body.md').read_text())
  bad=[n for n in (1480,1483,1537) if f'#{n} ' in s]
  assert not bad, f'acceptance rejected unchanged code: {bad}'
  PYPROBE
  ```

- **[Pass] Compatibility choice and scope are proportionate.** Plan `:36-42,44-57` keeps the existing fallback and extends its owner without a new parser, flag, dependency or suite. Retaining the old loop plus byte-identical offline output with all inputs/arguments fixed is adequate evidence for the chosen prose-only control; it is not a proof for every arbitrary body. Source `build_queue.py:398-414,419-426` supplies the offline boundary. The current-body input's seven intended refs are `[1417,1467,1471,1497,1500,1530,1551]` (its `body` field); the same replay with `1568-current-body.json` returned rc **0** and those seven Queue items plus the final-QA line. Plan `:64` correctly requires candidate parity for that Queue section. Easy reversibility: parser/doc edits have no stored-state migration; revert those edits to restore behavior. A dedicated rollback system would be disproportionate. The planned `SKILL.md:305` update is sufficient if it states checklist presence, first-reference selection, and fallback; `:307`'s safety promise should remain intact.

- **[Pass] The specified syntax boundaries are sufficiently concrete for this small change.** Plan `:46-51` explicitly handles indentation/nesting, `-`, `*`, `+`, numbered-dot bullets, uppercase X, and foreign/self lead refs without promoting later refs. An unchecked line without a ref establishes task-list mode but contributes nothing; `build_queue.py:482-483` already rejects zero open selections. The lead rule is explicitly **after sanitizing**: `build_queue.py:146-150` strips fences/inline spans but unwraps bare backticked `#N`/`PR #N` via `:96`. Thus ``- [ ] `#10` after #11`` retains #10 as the lead, while a backticked qualified reference is removed before matching. This follows the stated existing sanitation, not a new raw-Markdown guarantee. The implementation review should check these defined boundaries without adding another parser or a new suite.

VERDICT: FAIL

Basis: The intended parser change is small and sound, and the observed original-body rejection establishes useful defect sensitivity. Approval waits for the inaccurate reader inventory, contradictory acceptance descriptions, and missing retained red-run provenance to be corrected (R1–R3). No gate is configured in this relay's Reviewer steps, and none was assumed or run; no source, artifact, fixture executable, or Git command was modified/executed beyond the allowed narrow read-only probes.

Handing off to Producer (claude-a) — address R1–R3 in the plan/evidence and record each disposition before the next review.

### Producer · Round 1 · claude-a

Dispositions (plan file `PROJECT/1-INBOX/GH-1569-DAILY-GOALS-CHECKLIST-ONLY.md`; evidence under `TESTS-RESULTS/2026-11-23+GH-1569/`):

- **R1 — Implemented.** Recon now names two readers: the queue-admission parser (`parse_daily_goals_refs`, the only change) and the safety/hold reader (`main()` ~432/517 -> `parked_issues` -> `issue_hold_reason`), which is explicitly left unchanged and pinned by new acceptance row 8 (`parked_issues` on `- [ ] #10 after #11` returns `{1568}` on base and change).
- **R2 — Implemented.** Acceptance table rewritten with a Kind column: discriminator rows (1, 3, 4, 7: each differs on base) vs control rows (2, 3b, 5, 6, 8). Row 7 now carries an explicit unchecked checkbox; `(GH-1700)` split out as control 3b; row 3 uses a genuine second `#N` (`after #1601`).
- **R3 — Implemented.** `TESTS-RESULTS/2026-11-23+GH-1569/provenance.jsonl` now records sha256/size/command/base SHA for the inputs, `run.sh` and the red output. `issues.json` is labelled SYNTHETIC in its note (not live data).

Request: re-review the revised plan; no code has been written yet.

### Reviewer · Round 2 · codex

Input boundary: **plan only** for this paraphrase; no source or evidence files read this turn yet.

> **What this proposes**
>
> Extend the existing daily-goals parser so checkbox-bearing bodies select only the first reference from each unchecked line, while prose-only bodies retain existing behavior. Update one skill paragraph and retain manual red/green evidence, separating changed-behavior discriminators from preservation controls (plan lines 42–81).
>
> **How the existing system works, per this document**
>
> The queue parser currently admits all references from non-checked lines, including excluded prose. A separate safety reader can inspect the same goals body and park the goals issue itself; that reader and its hold behavior remain unchanged (lines 16–38).
>
> **What it's not**
>
> The explicit non-goals exclude resolution, hold, age-filter, exit-code, flag and suite changes (lines 62–63). The stated syntax boundary covers dash, star, plus and numbered-dot checkboxes after existing sanitization; the plan does not promise a general Markdown parser (lines 52–57,63).

**Source-backed review**

swept file: yes

Read the entire revised 93-line plan and all 544 lines of `skills/1-hourly/kickstart/scripts/build_queue.py`, the named skill paragraph, both goals bodies, the retained red output, wrapper and new provenance. The plan-only paraphrase matches the plan and source; no correction is needed. No additional concrete pre-existing defect was found in this bounded sweep beyond the known admission bug; this is plan approval, not implementation/runtime certification.

Verify-tier graph fallback: `list_projects(limit=100)` returned all 86 projects with `has_more=false`, none at this worktree. The nearest Forge project was `Users-noelsaw-Documents-GH-Repos-XYZ-forge`, generation `2026-11-23T23:18:20Z`, in a different checkout. Symbol search for `parse_daily_goals_refs|parked_issues|issue_hold_reason` returned zero nodes and no further page. Coverage reported `freshness: missing` for the parser, skill, plan, provenance and red-output paths; conclusions therefore use the exact local source and narrow offline probe below, not graph completeness.

- **[Pass] R1 closed — reader inventory and safety boundary corrected.** Plan `PROJECT/1-INBOX/GH-1569-DAILY-GOALS-CHECKLIST-ONLY.md:26-35` now distinguishes the sole queue-admission parser from the safety reader, explicitly preserving the latter. Source `build_queue.py:432,455,495-504,517` and `:187-200,214-222,242-243` supports that chain. Acceptance row 8 at plan `:81` pins the unchanged hold behavior; the probe returns `{1568}`. No additional goals-body reader that admits queue numbers was identified in the full local-file sweep.

- **[Pass] R2 closed — acceptance rows distinguish defects from preservation.** Plan `:67-81` now gives row 7 an unchecked checkbox, separates GH-only nesting into control 3b, and labels the preservation controls. The probe reproduces all listed parser base values. Rows 3 (actual second `#N`), 4 and 7 reject unchanged behavior; rows 3b, 5, 6 and 8 already satisfy their stated controls. Rows 3–7 do not all fail on base, and the revised plan correctly no longer requires that. Row 1 is the delivery discriminator: the original-body replay equals `outputs/red-base-original-body.md`, whose `:43-44,58` shows the excluded items, and the acceptance assertion below exits **1**. The unchanged CLI's own exit **0** cannot count as delivery. The current-body replay produces precisely the seven issue items required by plan `:74` (plus the normal final-QA line from `build_queue.py:370`).

- **[Pass] R3 closed — the cited red evidence now has retained attribution.** `TESTS-RESULTS/2026-11-23+GH-1569/provenance.jsonl:1-7` records the base revision, recording timestamp, inputs/wrapper/output paths, hashes and sizes; `:7` identifies the replay command and exit 0. The probe verifies all seven nonempty artifacts against those hashes/sizes and reproduces the retained red byte-for-byte. The synthetic issue universe is explicitly identified at `:3`. This is retrospective attribution plus a fresh offline reproduction, not an independent verification of Git history or a newly observed live GitHub acquisition.

- **[Pass] Fallback proof and syntax contract remain adequate.** Plan `:42-48,52-57,78` preserves the current loop for no-checkbox bodies; a fixed-input byte-identical replay is sufficient for the stated prose control, alongside source inspection that the branch remains unchanged. It does not establish universal equivalence for every body. The explicit regex at `:52` handles indentation/nesting, `+`, `1.`, and uppercase X; an unchecked no-ref line activates checklist mode but contributes no ref. The first match is consumed even when foreign, self-referential or already seen (`:55-57`), so a later reference cannot be promoted. Sanitization precedes detection/selection: `build_queue.py:95-99,146-150,263` preserves bare backticked `#N` / `PR #N` but strips other inline-code spans. Those boundaries are defined, not new Markdown behavior to invent during implementation. Zero selected open items already fail closed at `:482-483`.

- **[Pass] Scope, documentation and reversal are proportionate.** Plan `:50-63` extends the existing parser and one skill paragraph, with manual evidence and no second parser, new flag or suite. Updating `skills/1-hourly/kickstart/SKILL.md:305` to describe checklist presence, first-reference selection and fallback is adequate; the safety promise at `:307` remains intact. Reversibility is **Easy**: the parser/doc changes alter no persisted state and can be reverted together; no dedicated rollback mechanism is warranted. Candidate red/green receipts and the routed verification in plan `:60,83` remain implementation work, not results claimed here.

Exact narrow read-only probe (no fixture wrapper, gate, Git command or network call executed), exit **1**, deliberately at the final unchanged-code rejection:

```bash
export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"
mkdir -p "$TMPDIR"
python3 - <<'PYPROBE'
import contextlib, hashlib, io, json, re, runpy, sys
from pathlib import Path
D=Path('TESTS-RESULTS/2026-11-23+GH-1569')
records=[json.loads(l) for l in (D/'provenance.jsonl').read_text().splitlines()]
assert len(records)==7
for r in records:
    b=Path(r['artifact']).read_bytes()
    assert b and len(b)==r['size_bytes'] and hashlib.sha256(b).hexdigest()==r['sha256'], r['artifact']
print('provenance: 7/7 nonempty artifacts match hashes and sizes')
m=runpy.run_path('skills/1-hourly/kickstart/scripts/build_queue.py',run_name='review')
p=m['parse_daily_goals_refs']
for label,body,expected in (
    ('3a','- [ ] #10 after #1601',[10,1601]),
    ('3b-extra','- [ ] #11 and also #12',[11,12]),
    ('3b-control','- [ ] #10 (GH-1700)',[10]),
    ('4','- [ ] #11\n- [x] #9\nsee #10',[11,10]),
    ('5','prose #10',[10]),
    ('6','- [x] #10',[]),
    ('7','- [ ] other/repo#9 then #10',[10]),
):
    got=p(body,'HiQS-Labs/XYZ-forge',1568)
    assert got==expected,(label,got)
    print('base row',label,got)
parked=m['parked_issues']([{'number':1568,'title':'Daily goals','body':'- [ ] #10 after #11'}],set(),set(),'noelsaw1',{10,11,1568})
assert parked=={1568}
print('base row 8',parked)
outputs={}
for name in ('original','current'):
    sys.argv=['build_queue.py','--as-of','2026-11-20','--owner','noelsaw1','--repo-slug','HiQS-Labs/XYZ-forge','--other-session','1400,1418','--prs-json',str(D/'inputs/prs.json'),'--pr-meta-json',str(D/'inputs/pr-meta.json'),'--issues-json',str(D/'inputs/issues.json'),'--daily-goals','1568','--daily-goals-json',str(D/f'inputs/1568-{name}-body.json')]
    out=io.StringIO()
    with contextlib.redirect_stdout(out): rc=m['main']()
    s=out.getvalue()
    assert rc==0 and s.strip()
    outputs[name]=s
    queue=s.split('## Queue (execution order)\n',1)[1].split('\n## Needs the operator',1)[0]
    print(name,'CLI rc',rc,'queue',re.findall(r'^\d+\. #(\d+) ',queue,re.M))
assert outputs['original']==(D/'outputs/red-base-original-body.md').read_text()
print('original replay matches retained red: True')
current_queue=outputs['current'].split('## Queue (execution order)\n',1)[1].split('\n## Needs the operator',1)[0]
assert re.findall(r'^\d+\. #(\d+) ',current_queue,re.M)==['1417','1467','1471','1497','1500','1530','1551']
bad=[n for n in (1480,1483,1537) if f'#{n} ' in outputs['original']]
assert not bad, f'acceptance rejected unchanged code: {bad}'
PYPROBE
```

Decisive output:

```text
provenance: 7/7 nonempty artifacts match hashes and sizes
base row 3a [10, 1601]
base row 3b-extra [11, 12]
base row 3b-control [10]
base row 4 [11, 10]
base row 5 [10]
base row 6 []
base row 7 [10]
base row 8 {1568}
original CLI rc 0 queue ['1417', '1467', '1471', '1480', '1483', '1497', '1500', '1501', '1507', '1526', '1530', '1541', '1551']
current CLI rc 0 queue ['1417', '1467', '1471', '1497', '1500', '1530', '1551']
original replay matches retained red: True
AssertionError: acceptance rejected unchanged code: [1480, 1483, 1537]
```

VERDICT: PASS

Basis: R1–R3 are closed with source and artifact evidence. The plan is surgical, specifies its boundaries, preserves the safety reader, and has an observed acceptance rejection of unchanged code. No implementation green is claimed. No phase gate is configured for this reviewer turn; none was run or assumed to run later. Only this relay file was edited.

Relay closed (Approved), no further turn needed.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
