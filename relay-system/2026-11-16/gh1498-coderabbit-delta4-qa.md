# RELAY · GH-1498 CodeRabbit third-pass QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-11-17.
-->

NEXT: Producer
STATUS: Open
ROUND: 1 / 1

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
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
   Reviewer headings may be `### Reviewer · Round N`, `### Round N · Reviewer · <agent>`, `### Reviewer (<agent>)` (optionally followed by `— rN`), or `### Reviewer — Round N` (optionally followed by `(<agent>)`); follow the heading with a non-empty review body.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(gh1498-coderabbit-delta4-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **skills/2-daily/pr-minder/scripts/pr_minder.py** (review `git diff a37ecbf67..4080d4b80`).
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-11-17
- Definition of Done: `git diff a37ecbf67..4080d4b80` correctly fixes CodeRabbit's third-pass findings 4597724739 (narrow `--pr`/`--explain` before the conflict lookup) and 4597724770 (null `reviewThreads` entries), with no regression.

## Context and questions

**Envelope:** a manual local CLI. No new tests (GH-831).

The two changes:
- `pr_minder.py` `main`: the focus filter now runs before the `conflict_files` loop. `assess` still covers all PRs, which stack inheritance needs.
- `planner_core.author_activity`: a null or malformed thread, or inner comment, returns `(None, False)`.

Evidence: A20a and A20b in `TESTS-RESULTS/2026-11-16+GH-1498/manual-check.log`, 29/29 total.

A third finding (4597724725, retaining your AST probe source and provenance) is declined, for the same reason as the first-round decline that CodeRabbit accepted for the lock: reviewer probes are quoted in the relay threads and aren't producer evidence runs.

Answer, citing `file:line`:
1. Are both fixes correct and complete, with no regression? For example, does `--explain` still show conflict files for its own PR?
2. Is the decline sound?

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer · Round 1 · codex

VERDICT: PASS
Basis: Both bounded third-pass fixes are correct; no regression or additional concrete pre-existing defect found in the full pr_minder.py sweep. The reviewer-probe retention decline is sound under this turn's explicit scratch-and-quote protocol. This is code-review approval, not final gate qualification.
swept file: yes

Read all 571 lines of `skills/2-daily/pr-minder/scripts/pr_minder.py`, the shared activity query/clock in `skills/3-weekly/weekly-planner/scripts/planner_core.py:1237–1339`, A20 source/results/provenance and prior relay evidence. Verify-tier graph discovery returned 86 projects, none for this worktree; XYZ-forge generation `2026-09-01T15:54:30Z` returned zero relevant symbols (has_more=false), with coverage missing/not-tracked for the two Python paths. Direct seeded source supplies the evidence. No Git executable, network call, suite, pytest, gate or executable fixture was run; only this relay file was edited.

- [Pass] **Candidate matches the seeded source.** Read-only Python traversal of loose and packed commit/tree/blob objects reconstructed `a37ecbf67..4080d4b80` and asserted both candidate blobs equal the seeded files. Command: `export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"; python3 - <<'PY'` (inline pathlib/zlib pack/index decoding and difflib; exit **0**). Decisive output: `seed equals 4080d4b80: skills/2-daily/pr-minder/scripts/pr_minder.py` and the same for `skills/3-weekly/weekly-planner/scripts/planner_core.py`. The delta moves the focus block ahead of conflict lookup (`pr_minder.py:523–533`) and replaces the thread comprehension with validation (`planner_core.py:1325–1329`). An initial loose-object-only attempt exited 1 because the base object was packed; the successful packed-object traversal resolved that limitation.

- [Pass] **Focus limits conflict lookup while preserving stack assessment and explanation.** `pr_minder.py:523` assesses all PRs; `:524–529` filters and rejects an absent focus before `:530–533` performs lookup/rebuild; `:535–539` then prints the enriched explanation. Stack resolution remains at `:232–253`. Narrow probe command: `export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"; python3 - <<'PY'` (exit **0**). Inline Python AST-compiled the real `main` with in-memory readers, receipts, assess/lookup/render spies; no external call was reachable. Asserted outputs: `['--pr', '150', '--json'] lookup= [150] assessed= [150, 151] rc= 0`; `['--explain', '151'] lookup= [151] assessed= [150, 151] rc= 0`; `['--pr', '999'] lookup= [] assessed= [150, 151] rc= 2`; `['--json'] lookup= [150, 151] assessed= [150, 151] rc= 0`. The explanation JSON contained `conflict_files=['own-conflict.txt']` and the rebuilt comment contained that filename. The probe checks main's wiring; source inspection establishes the unchanged stack resolver.

- [Pass] **Null thread/comment entries fail closed for the affected PR.** `planner_core.py:1323–1329` rejects an incomplete thread connection, non-dict thread, missing inner list or non-dict inner entry before reading timestamps. `pr_minder.py:202,217–223,276–278` maps the unknown result to a report-only plan and skips drift. The same bounded command AST-compiled only `_parse_gh_time`, `is_maintenance_commit` and `author_activity`, using empty complete connections and a valid createdAt. Decisive asserted output: `null-thread -> unknown`; `null-comment -> unknown`; `missing-comments -> unknown`; `bad-inner -> unknown`; `valid-thread -> latest 2026-11-15, complete=True`. Replaying the removed comprehension on `[None]` and `[{'comments': {'nodes': [None]}}]` yielded `pre-fix null control -> AttributeError` twice. This establishes the reported null-entry cases and valid GraphQL-shaped connections, not arbitrary corruption of every nested container.

- [Pass] **Recorded producer checks cover the reported inputs; reviewer retention decline is appropriate.** `TESTS-RESULTS/2026-11-16+GH-1498/manual_check.py.txt:821–827` supplies both null inputs; `:830–853` spies on two conflicting PRs and rejects eager lookup before focus. `manual-check.log:29–32` records A20a/A20b PASS, 29 passed/0 failed and rc=0; the `provenance.jsonl` record with id `A1-A20b` binds that producer run to `4080d4b80`. These are inspected receipts, not rerun claims. Reviewer probes are separately quoted with command, status and decisive output here, as required by the operator and already accepted in `relay-system/2026-11-16/gh1498-coderabbit-delta-qa.md:112` and delta3's reviewer block. No retained scratch source or new producer provenance is required for this reviewer turn; producer evidence provenance remains required and present.

- [Unverified — needs clone run] Full driver execution and final-head qualification remain with the disposable-full-clone harness after this turn. No gate-pass or delivery-readiness claim is made here.

Relay closed (Approved), no further turn needed. Token handed off with `done`; the harness owns the file-scoped commit.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->

### System · relay-drive — 2026-11-17T09:43:25Z
terminal STATUS Approved written by FAILED reviewer turn (codex; shim returned non-zero) — reverted
