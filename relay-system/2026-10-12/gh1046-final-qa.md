# RELAY · GH-1046 final QA: skills-army-hq copy-not-link visibility
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-12.
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
     change MUST carry three lines: `Observed input:` (the failing input you saw), `Affected scope:`
     (the input predicate the change would govern), `Falsifier:` (the fixture or data that would show
     the change unnecessary or wrong, and its expected result).
     A `[Blocker]` must cite an observed failure. This is a protocol rule, not a mechanical check —
     the Producer may disposition a request lacking these as `Declined — unproven generalization`.
   - **Producer:** log a disposition for every open finding (Implemented / Modified / Declined + why,
     including `Declined — unproven generalization` for a behaviour-change request that carries no
     `Observed input:` / `Affected scope:` / `Falsifier:`), make the change, then add new work.
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns.
   Reviewer headings may be `### Reviewer · Round N`, `### Round N · Reviewer · <agent>`, `### Reviewer (<agent>)` (optionally followed by `— rN`), or `### Reviewer — Round N` (optionally followed by `(<agent>)`); follow the heading with a non-empty review body.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(gh1046-final-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: `skills/3-weekly/skills-army-hq/SKILL.md`, `skills/3-weekly/skills-army-hq/scripts/intake.py`, `skills/3-weekly/skills-army-hq/scripts/sync.py`, `PROJECT/2-WORKING/GH-1046-COPY-NOT-LINK.md`, `TESTS-RESULTS/2026-10-12+GH-1046/manual-check.log`, `TESTS-RESULTS/2026-10-12+GH-1046/provenance.jsonl`
- Diff under review: git diff d86f647b245e866f23245211b8d36e4cc49ecc67..HEAD -- skills/3-weekly/skills-army-hq (the three skill files above), graded against the approved plan (plan QA thread relay-system/2026-10-12/gh1046-plan-qa.md, approved r2) and the evidence files above. Issue: https://github.com/HiQS-Labs/XYZ-forge/issues/1046
- Operational envelope: local single-operator CLI plus a skill doc; a clarity change. Grade against the issue's Goal 1-4 and the approved plan with commensurate complexity; do not ask for new state, JSON keys, flags, tests or machinery (GH-831: a new test file or validate.sh entry in the diff is itself a finding). Read-only probes only; no validate.sh / test/*.sh / pytest in the relay worktree.
- Questions:
  1. Is each issue goal met? (1) copy not link, (2) source path + revision per copy, (3) which app roots link, (4) consequences (any clean checkout of the merged revision; deletable after intake; update needs a newer source). Cite SKILL.md lines and the emitted lines in `manual-check.log`.
  2. Do the code paths match the plan (steps 2-5)? `is_linked` reused by `render_catalog` with catalog output unchanged; `copy_line` fallbacks `manual/unadopted` / `unknown`; `(disabled)` marking; `print_copies` shared by `intake.py list` and `sync.py --status`; `will COPY` only on add/update preview (and not on the unchanged-update early return). Did a duplicate helper or parallel writer slip in?
  3. Is stdout JSON unchanged on all four paths? Does the evidence (byte `cmp` on nonempty output, existing suite green, three red controls) substantiate that, and the stderr claims?
  4. Any correctness bug: e.g. `copy_line` on a receipt whose `commit` is present but `None`, a target path that no longer resolves (`location()` raising inside `is_linked` for `list`/`--status` where base did not raise), `--retire-trinity --status`, or SKILL.md wording that overclaims (e.g. that every collection entry is a real folder)?
  5. Does the persisted rating `rated 55/40/50/85` still match the evidence?
- Flag anything wrong, missing or over/under-engineered, citing file:line.
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-10-12
- Definition of Done: the issue's Goal 1-4 are met by the approved plan's smallest change; stdout JSON is byte-identical; no new tests/state/deps; the cited evidence supports each claim. Approve (STATUS: Approved) when that holds.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer · Round 1 · codex

VERDICT: FAIL
Basis: The implementation follows the approved small design and the retained evidence supports its normal paths, but nullable revision metadata accepted by the existing validator now breaks the new summary. Fix that narrow regression before approval.
swept file: yes

Read all six Setup artifacts and the approved plan QA, including the full SKILL.md, intake.py and sync.py. No additional pre-existing defect requiring expansion of this change was identified. Graph tools are unavailable in this session; findings use direct source. No Git commands, suites, executable fixtures or artifact edits were performed. Only the non-mutating function probe below was run. A base diff and exact committed-state attribution were not independently checked because Git is prohibited this turn.

- **[Should] R1 — Null commit metadata crashes the added human summary (`skills/3-weekly/skills-army-hq/scripts/intake.py:388`).** `validate_state` accepts a receipt with `commit: None` (`:259–264`), but slicing `receipt.get('commit', 'unknown')[:12]` raises TypeError. Both list (`:754–755`) and status (`sync.py:254–256`) call this after writing JSON; their exception handlers then return 2. Normalize missing/null revision to `unknown` before slicing, without tightening the existing receipt schema or changing stdout. The old catalog interpolation (`intake.py:412`) does not slice this value.
  Observed input: `{'digest': 'a'*64, 'prerequisites': [], 'commit': None}`, in a schema-1 state with a valid 32-character collection id, `skills={'sample': receipt}`, and `links={}`. The direct probe accepted the state and reproduced `TypeError: 'NoneType' object is not subscriptable`.
  Affected scope: list/status human summaries for otherwise accepted receipts whose optional commit is null; ordinary string commits and missing commits must retain their current formatting.
  Falsifier: pass the same validated receipt to `copy_line` and expect `@ unknown` with no exception; absent commit must still show `unknown`, and a full string revision must still shorten to twelve characters. Record the narrow manual check; no new suite or schema machinery.
  Probe command (exit 0; exception deliberately captured, no filesystem fixture or subprocess):
  ```python
  # Invoked with python3 -B - <<'PY', after exporting
  # PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"
  import importlib.util
  from pathlib import Path
  spec = importlib.util.spec_from_file_location('intake_review', 'skills/3-weekly/skills-army-hq/scripts/intake.py')
  m = importlib.util.module_from_spec(spec); spec.loader.exec_module(m)
  root = Path.cwd()/'.relay-scratch/tmp/collection'
  receipt = {'digest':'a'*64, 'prerequisites':[], 'commit':None}
  state = {'schema':1, 'root':str(root), 'collection':'b'*32, 'skills':{'sample':receipt}, 'links':{}}
  m.validate_state(root, state)
  print('validate_state: accepted commit=None')
  print('missing commit:', m.copy_line(root, 'sample', {}, {'targets':[]}))
  try:
      print(m.copy_line(root, 'sample', receipt, {'targets':[]}))
  except Exception as exc:
      print(f'commit=None: {type(exc).__name__}: {exc}')
  ```
  Decisive output: `validate_state: accepted commit=None`; absent commit rendered `recorded source manual/unadopted @ unknown`; null commit rendered `commit=None: TypeError: 'NoneType' object is not subscriptable`.

- **[Pass] Four goals and helper reuse.** `SKILL.md:14–24` explains physical copies, recorded provenance, disposable clean merged source and explicit updates; `intake.py:637` actually copies payloads. `manual-check.log:85–97` shows copy/source/revision, configured target IDs, disabled links and COPY previews. `intake.py:374–418` shares the link predicate with the catalog and a single `print_copies`; `sync.py:255–256` uses that same printer. The existing unchanged-update return (`intake.py:797–798`) precedes the preview notice (`:804–806`). No duplicate writer or new state/dependency appears in these files.
- **[Pass] The proposed target-path regression is not established.** `load` already invokes `validate_targets`, which calls `location` for every configured target (`intake.py:243,280`), including disabled ones. A missing ordinary target directory is permitted; a symlinked ancestor is already rejected before the summary. `sync.py:219` makes status read-only even with apply, and `:243–256` prints the same inventory summary after the retirement branch too. No new target-validation policy is requested.
- **[Pass] Retained normal-path evidence meets the planned verification shape.** `TESTS-RESULTS/2026-10-12+GH-1046/manual-check.log:38–40` size-checks the base output and compares bytes; `:60–71` records zero exits and nonempty identical stdout for all four paths (3167/1104/286/353 bytes). Lines `:72–98` record the expected stderr and `fail=0`. `provenance.jsonl:2–6` records the existing suite green and all three red controls, including JSON indentation sensitivity. These are reviewed producer receipts, not suite runs independently repeated here, and do not cover R1.
- **[Nit] Bound two explanatory claims.** `SKILL.md:19` says the catalog “shows the same,” although the catalog intentionally excludes disabled targets (`intake.py:409–410`) while the new summary includes them. Say it also records provenance and enabled-target status. `SKILL.md:21` says deleting the source “breaks nothing”; this is accurate for copied payloads/app links, but an explicit canonical path to that checkout makes later sync fail (`sync.py:39–49`). Prefer “does not break the copy or its app links,” keeping the existing update-source and canonical-root guidance.
- **[Pass] Rating remains proportionate.** The small presentation change and single reported confusion incident still fit `rated 55/40/50/85` and its rationale (`PROJECT/2-WORKING/GH-1046-COPY-NOT-LINK.md:104–109`). Recurrence/history and the live persisted DB value were not independently queried.
- **[Unverified — needs clone run]** After R1, retain the focused manual evidence and run the required final gate in the disposable full clone. The pending gate remains explicit in the plan status (`:23`) and step 6 (`:100`); this review does not claim it ran.

Handing off to Producer (claude-a): fix R1, disposition the wording nit, and return for review; go to the Producer window and say 'take your turn'.

### Producer · Round 2 · claude-a

- R1 — **Implemented** (cba245ae). `copy_line` now uses `(receipt.get('commit') or 'unknown')[:12]` and `receipt.get('source') or 'manual/unadopted'` (`skills/3-weekly/skills-army-hq/scripts/intake.py:387-388`); receipt schema and stdout untouched. Your falsifier was witnessed red on 66cd4701 (`null -> TypeError`) and green on cba245ae (`null -> @ unknown`; missing -> `@ unknown`; full -> 12-char rev + `, dirty`): `TESTS-RESULTS/2026-10-12+GH-1046/r1-null-commit-probe.log`. Disposable clone at cba245ae: existing suite 33 passed; byte check rerun identical on all four paths (`provenance.jsonl` lines 7-10).
- Nit — **Implemented.** `SKILL.md:19` now says the catalog "also records provenance and enabled-target link status"; `SKILL.md:21` now says deleting the source "does not break the copy or its app links".

Handing off to Reviewer (codex) for Round 2.

### Reviewer · Round 2 · codex

VERDICT: PASS
Basis: R1 and the wording nit are resolved. The implementation meets the four goals through the existing receipt and link machinery, and retained producer evidence supports stdout preservation and sensitivity. Approval is final artifact QA; the separate final-commit harness gate remains pending.
swept file: yes

Read all six Setup artifacts in full, the approved plan QA, and the added null-commit probe log. Re-swept the entire SKILL.md, intake.py and sync.py; no additional pre-existing defect requiring expansion of this change was identified. Verify-tier discovery enumerated all 84 graph projects (has_more=false); neither this worktree nor its task clone has an index. Used direct current source throughout rather than another checkout's graph; no current graph generation/coverage claim. No Git commands, suites, executable fixtures or artifact edits were performed. The historical diff, committed-state attribution and live persisted rating were not independently queried under this turn's restrictions.

- **[Pass] R1 resolved.** `skills/3-weekly/skills-army-hq/scripts/intake.py:387–388` now normalizes null/missing provenance before slicing. The retained red/green comparison in `TESTS-RESULTS/2026-10-12+GH-1046/r1-null-commit-probe.log:14–21` witnesses the old null failure and new fallback. My non-mutating probe below independently returned exit 0 on the seeded source: missing and null rendered `recorded source manual/unadopted @ unknown`; full rendered `recorded source /src/x @ 0123456789ab, dirty`. No receipt schema change is needed.
  Command (no subprocess or filesystem fixture):
  ```bash
  export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"
  mkdir -p "$TMPDIR"
  python3 -B - <<'PY'
  import importlib.util
  from pathlib import Path
  spec = importlib.util.spec_from_file_location('intake_review', 'skills/3-weekly/skills-army-hq/scripts/intake.py')
  m = importlib.util.module_from_spec(spec); spec.loader.exec_module(m)
  root = Path('/nonexistent/collection')
  receipt = {'digest':'a'*64, 'prerequisites':[], 'commit':None}
  m.validate_state(root, {'schema':1,'root':str(root),'collection':'b'*32,'skills':{'sample':receipt},'links':{}})
  for label, r in (('missing', {}), ('null', receipt), ('full', {'source':'/src/x','commit':'0123456789abcdef0123','dirty':True})):
      line = m.copy_line(root, 'sample', r, {'targets':[]})
      assert ('@ 0123456789ab, dirty' if label == 'full' else '@ unknown') in line
      print(label, '->', line)
  PY
  ```
- **[Pass] Wording and four goals.** `SKILL.md:14–24` covers physical copies, per-copy recorded source/revision, app links, clean merged source checkouts, deletion and explicit updates. Line 19 now bounds the catalog to enabled-target status; line 21 bounds deletion safety to the copy and its app links. The emitted evidence at `manual-check.log:85–97` shows the copy path, shortened revision, fallback receipts, disabled target marking and COPY previews. `intake.py:637` is the existing physical copy operation; internal relative payload links remain documented at `SKILL.md:152–153`.
- **[Pass] Shared implementation and special paths.** `intake.py:374–418` has one link predicate reused by the catalog and one stderr printer; list calls it at `:754–755`, status at `sync.py:254–256`. Preview text is confined to the non-apply add/update branch (`intake.py:804–806`), after the unchanged return (`:797–798`). Target paths are already validated at load (`:243,280`); status forces apply false (`sync.py:219`) and the shared summary follows both retirement and ordinary branches (`:243–256`). No parallel writer or new dependency/state appears in these reviewed files.
- **[Pass] Retained evidence supports stdout preservation.** `manual-check.log:38–40,60–71` checks nonempty output and compares bytes on all four paths; `:72–98` records stderr checks and `fail=0`. `provenance.jsonl:3–6` records the three red controls. Lines 8–10 attribute the null-fix check, existing suite (33 passed, 4 subtests) and repeated four-path byte comparison to cba245ae. These are reviewed producer receipts, not suite runs repeated in this worktree.
- **[Pass] Rating remains proportionate.** `PROJECT/2-WORKING/GH-1046-COPY-NOT-LINK.md:104–109` still supports the documented `rated 55/40/50/85` for the bounded clarity change; no new evidence here warrants changing it. Live DB persistence and historical recurrence remain outside this review's independent evidence.
- **[Unverified — needs clone run]** The final-commit tier-2 harness gate remains due, as stated in the plan's status (`:23`) and step 6 (`:100`). This approval does not attest that gate or authorize skipping it.

Relay closed (Approved), no further turn needed. Producer (claude-a) resumes the already-planned final-commit gate and delivery after the harness commits this review.


### Attestation · relay-drive — 2026-10-13T03:58:12Z
task: RELAY-gh1046-final-qa
reviewer: codex
status: Approved
reviewed-head: 602be59e1af50f2345037f4f7bfaeb999b0c723f
added-range: 15080+4924
added-sha256: a76ed53611030044d0a2086578e3b9de5e11773f3c15bf18c1ce89e1f57de24b
<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
