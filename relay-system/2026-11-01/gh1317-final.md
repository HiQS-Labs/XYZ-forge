# RELAY · GH-1317 final independent repair evaluation
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-11-01.
-->

NEXT: Producer
STATUS: Approved
ROUND: 1 / 3

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
6. **Commit only the relay file** (`relay(gh-1317-final-independent-repair-evaluation): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Read utils/py/harness.py (actor diff b3dd3e43); PROJECT/2-WORKING/GH-1317-CODEX-REPAIR-PILOT.md; TESTS-RESULTS/2026-11-01+GH-1317/pilot/CONTRACT.md and manual-check.v3.py.txt; frozen.v3.sha256; baseline-v3/, candidate/ and mutation/ raw results/commands/calls/state; provenance.jsonl; actor and plan relay threads.
- Independent evaluator turn: do not edit source, protocol, fixtures or evidence. Local supervised CLI pilot, no enterprise machinery. Judge whether actor fixed two concrete defects, preserved strictly >3600 behavior, settled no-call reservations, and whether unchanged frozen checks plus deliberate bypass substantiate those claims. Independently inspect raw event/DB/output evidence, not only summaries. No running tests/fixtures/full suites in relay worktree. Narrow read-only probes allowed.
- Explicit limits: no immutable boundary/general autonomy claim; v3 positive is idle-call control; missing/delete prompt behavior is not an added requirement. Admission selector failed and was corrected after actor; process deviation is disclosed. Plan QA corrected fixture/oracle failures before actor, within 3 rounds. Source changed in one actor attempt, zero API/provider spending.
- Runtime source classifies full; operator limited this exercise to focused checks/no broad full-suite rerun. Draft-only publication may use documented GH-487 bypass with focused evidence and explicit PR disclosure. Grade scoped implementation/evidence, not merge readiness. Full gate/promotion/merge are outstanding; do not demand a new gate framework or speculative tests.
- Reviewer: codex   ·   Producer: supervisor
- Started: 2026-11-01
- Independent final verdict on exact repair and semantic evidence. Cite concrete incorrect claims/paths. Approved means scoped review approved, not merge-ready. No source edits.

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
Basis: Ship the scoped two-defect repair and supervised pilot evidence. Approval is not merge readiness, full-gate qualification, or a general autonomy claim.
swept file: yes

- [Pass] Whole-file review of utils/py/harness.py found no additional concrete production defect requiring expansion of this repair. The change extends the existing adapter and settlement owner: one due predicate at harness.py:186–190 is used by rules at :221 and Codex at :248; selected prompt identity is checked at :251–254 before snapshot/request composition and subprocess dispatch. Initialization uses the same text/hash convention at :1016–1034. The no-call result is unbilled, cost zero, called=False; _settle at :1256–1267 releases that reservation. No new framework or source correction requested.
- [Pass] Strictly >3600 is preserved. Narrow source-function probe command: `export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"; mkdir -p "$TMPDIR"; python3 -B - <<'PY'`, parse harness.py with ast, compile only _probe_due with datetime, and call it with last=2026-11-01T00:00:00+00:00 and now=01:00:00 / 01:00:00.000001 (UTC), plus absent-history and empty-target inputs. Exit 0; decisive output: equality => False, one microsecond above => True, absent history with ['x'] => True, absent history with [] => False. This measures the extracted predicate, not a CLI equality case.
- [Pass] Independently inspected retained raw commands, call records, evaluate events, decisions, reservations, tool_runs and receipts across baseline-v3/, candidate/ and mutation/ under TESTS-RESULTS/2026-11-01+GH-1317/pilot/. Read-only probe command: `export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"; mkdir -p "$TMPDIR"; python3 -B - <<'PY'`, using pathlib/json/hashlib to recompute frozen.v3.sha256 entries, parse each results.json/commands.json/calls.jsonl and every *-state.json, and assert tool_runs[0].sha256 equals the completed receipt's output_sha256. Exit 0; decisive output: CONTRACT.md MATCH; manual-check.v3.py.txt MATCH; each run has 21 commands, nonzero []; call counts baseline=7, candidate=4, mutation=6. Current source's computed Git-blob SHA1 is 721858cd469a8bda4c70fcbe56275d018c8c5f44, matching the candidate source_blob prefix in pilot/provenance.jsonl. No Git command was invoked.
- [Pass] Evidence detects the concrete faults rather than accepting exit zero: baseline-v3/results.json fails not-due/mutated-v2/mutated-v3 while its four controls pass. Candidate results pass all seven; candidate/not-due-state.json has evaluate agent_called=false and released/0.0 reservation, and candidate/mutated-v2-state.json plus mutated-v3-state.json have evaluate status prompt-mismatch, agent_called=false and released/0.0 reservations. Their results retain spent_before=0, spent_after=0.0, and completed ticks/receipts/tool runs. The four positive cases each record one external fake call and the expected probe/note/note/idle tool (candidate/results.json); v3 is an idle-call control, not plan-authoring acceptance.
- [Pass] The unchanged frozen oracle is sensitive to deliberate bypass: mutation/change.txt names removal of exactly the prompt comparison/refusal, and mutation/results.json fails exactly mutated-v2/mutated-v3, with one call each, evaluate ok/true and held reservations in their raw state files. Five controls still pass. The earlier baseline also supplies the red control for not-due call suppression. Contract/manual hashes still match; pilot/provenance.jsonl retains run-specific base/candidate/mutation receipts. Existing focused output ends "codex-turn: 43 pass, 0 fail" (pilot/codex-turn-check.txt); this is retained evidence, not a new run in this turn.
- [Nit] Evidence retention limit: the supplied raw state preserves output paths and matching output hashes, while manual-check.v3.py.txt records the runtime nonempty-file/hash check. The actual generated tool-output bytes are not included in these retained directories, so this turn cannot independently rehash them; approval relies on the frozen evaluator's recorded output check for that part.
- [Unverified — needs clone run] No CLI case, executable fixture, suite, pytest or full gate ran here. Full gate/promotion/merge remain outstanding, as Setup requires. The project document explicitly discloses admission after actor execution; it is a process deviation, not proof of correct admission order. Source repair used one actor attempt; this review does not erase that deviation or infer immutable containment, provider quality, reliability calibration or productivity gains from the fake-call pilot.

Relay closed (Approved), no further turn needed. Supervisor owns draft publication with the documented focused-evidence/bypass disclosure and any later merge qualification.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
