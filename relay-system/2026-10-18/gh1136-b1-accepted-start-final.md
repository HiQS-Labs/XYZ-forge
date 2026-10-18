# RELAY · GH-1136 final QA: B1 replay keeps accepted-start
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-18.
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
6. **Commit only the relay file** (`relay(gh1136-b1-accepted-start-final): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **.relay-artifacts/review-diff.patch.txt** — the read-only path that
  `relay-drive.sh --artifact-file TESTS-RESULTS/2026-10-18+GH-1136/review-diff.patch.txt` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-10-18
- Definition of Done: _<fill in the acceptance criteria the Reviewer grades against>_

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Round 1 — Producer (claude-a) → Reviewer (codex)

**Final QA request.**
- Approved plan: `PROJECT/2-WORKING/GH-1136-B1-ACCEPTED-START.md`. Plan relay `relay-system/2026-10-18/gh1136-b1-accepted-start-plan.md` was Approved in r1.
- The seeded artifact is the scoped diff (`review-diff.patch.txt`, bound in `review-diff.binding.txt`). It includes `releases.sql`, so the GH-1112 repair row is visible.
- Review it against the repository copy of `skills/2-daily/merge-cleanup/scripts/ledger_merge.py` (whole file).
- Evidence is in `TESTS-RESULTS/2026-10-18+GH-1136/`: `replay-controls.py.txt` plus `.log.txt`, the gh436 clone run, and `provenance.jsonl`.

**Verify (cite file:line):**
1. `_replayed_gid` does the following:
   - It checks the command result and the JSON shape.
   - It compares numbers as strings, with the exact issue URL.
   - It requires exactly one match and a non-empty gid.
2. The accepted-start call runs only when `status_label == "in-progress"`, after add, rate and update. Any refusal returns False (handoff).
3. The plan's Nit (string normalization) is applied.
4. The controls are non-vacuous:
   - (a) The label survives.
   - (b) Red control: base drops it.
   - (c) No accepted-start call for an unlabeled row.
   - (d) A closed native issue fails closed, rc=3 `accepted-start-native`.
   - The GitHub boundary is stubbed via `RELEASES_GH_BIN`, and the real writer runs.
5. GH-1112 repair: `releases.sql` shows `status_label='in-progress'` on gid `rmi-01M56GEJJR4PXDB80R4JG60NG1`, written through the CLI (receipt present). The original start time is not recoverable, and this is disclosed.
6. No new test file or case. Note any pre-existing defects in the touched regions.

End with a line that is exactly `VERDICT: PASS|FAIL|PARKED` (no bold, no prefix), plus a `swept file:` line. Append your block at the very bottom, directly above the NEXT TURN marker. Set `STATUS: Approved` only on PASS.

### Reviewer · Round 1

Ship. Basis: the scoped patch meets the approved plan; no blocking or additional pre-existing defects found in the whole-file sweep of `skills/2-daily/merge-cleanup/scripts/ledger_merge.py:1-680`. Applied SWE review; graph tools unavailable, so source fallback used.

swept file: yes

- [Pass] Lookup checks exit status, JSON list shape, string-normalized issue number, exact URL, exactly one match and nonempty gid (`ledger_merge.py:293-310`). The plan's normalization Nit is applied. Narrow probe command: `export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"; mkdir -p "$TMPDIR"; python3 -` (stdin: AST-extract only `_replayed_gid`, replace `_run` with in-memory CompletedProcess responses). Exit 0; decisive output: `int/string match: PASS; command refusal: PASS; invalid JSON: PASS; wrong shape: PASS; empty list: PASS; duplicate matches: PASS; missing gid: PASS; wrong URL: PASS`. No subprocess writer or git operation executed.
- [Pass] Only added rows with `status_label == "in-progress"` call accepted-start, after add/rate/section-marker update; lookup or writer refusal returns False (`ledger_merge.py:321-361`). Resolver converts that refusal to handoff (`:602-606`). Existing writer checks owned identity/open native issue (`utils/py/releases_app.py:3949-3961`); no competing writer introduced.
- [Pass] Recorded controls run the real writer and stub only GitHub through `RELEASES_GH_BIN` (`TESTS-RESULTS/2026-10-18+GH-1136/replay-controls.py.txt:8-37`). Recorded outputs demonstrate candidate preservation, base label loss, no accepted-start for unlabeled input, and closed-native refusal `rc=3 refused: rule=accepted-start-native` (`replay-controls.log.txt:1-5`). Existing clone suite reports `Ran 180 tests in 307.596s`, `OK` (`clone-gh436.log.txt:1892-1894`). These are inspected producer receipts, not suites rerun this turn. The same `python3 -` read-only probe checked all five provenance entries: exit 0, `provenance: 5 nonempty artifact sizes and SHA256 hashes match`.
- [Pass] GH-1112 gid `rmi-01M56GEJJR4PXDB80R4JG60NG1` has `in-progress` (`releases.sql:874`), matching roadmap-update receipt (`:2899`) and accepted-start event (`:3744`). Original time loss is disclosed in `PROJECT/2-WORKING/GH-1136-B1-ACCEPTED-START.md:46`; this repair records 2026-10-18T17:05:44Z.
- [Pass] Seeded diff changes only the plan, ledger and existing implementation (`.relay-artifacts/review-diff.patch.txt:1,75,125`); no new test file/case or gate. Whole-file sweep found no additional actionable defect.
- Limitation: full final-commit gate remains the harness's next action; no validate.sh, test/*.sh, pytest, or executable fixtures run here. Approval is for this reviewed artifact, not merge/promotion qualification.

VERDICT: PASS

Relay closed (Approved), no further turn needed. Handing the token to Producer (claude-a); the harness owns the relay-only commit and subsequent gate.

### Round 2 — Producer (claude-a) → Reviewer (codex)

Your Round 1 verdict was PASS. The harness reverted it only on format: `relay block structural validation failed (exit 8): Basis: line is missing or empty`. You wrote `Ship. Basis: ...` on one line. Nothing has changed since Round 1.

Re-issue the verdict with these three lines at the **start of their own lines**, exactly in this shape (no bold, no prefix):

```
VERDICT: PASS
Basis: <one sentence>
swept file: yes
```

Append your block at the very bottom, directly above the NEXT TURN marker, and set `STATUS: Approved` if PASS stands.

### Reviewer · Round 2

VERDICT: PASS
Basis: Ship; the source and recorded controls satisfy the approved plan, and Round 1's verdict requires only the requested structural correction.
swept file: yes

- [Pass] Re-read the whole implementation, including pre-existing code; no additional actionable defect found (`skills/2-daily/merge-cleanup/scripts/ledger_merge.py:1-680`). Applied SWE review; graph tools are unavailable, so source fallback used.
- [Pass] Lookup checks command result, JSON shape, string-normalized number, exact URL, one match and nonempty gid (`ledger_merge.py:293-310`). Only added in-progress rows call the existing accepted-start writer after add/rate/update; refusal hands off (`:321-361`, `:602-606`).
- [Pass] Recorded controls demonstrate preservation, base label loss, unlabeled-row exclusion and closed-native refusal rc=3 (`TESTS-RESULTS/2026-10-18+GH-1136/replay-controls.log.txt:1-5`). They invoke the real writer and stub GitHub (`replay-controls.py.txt:8-37`). The clone suite records 180 tests, OK (`clone-gh436.log.txt:1892-1894`). These are inspected producer receipts, not reruns.
- [Pass] Read-only probe command: `export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"; python3 -` with stdin loading provenance rows and asserting nonempty bytes, recorded size and SHA256. Python exit 0; decisive output: `provenance: 5 nonempty artifact sizes and SHA256 hashes match` (`TESTS-RESULTS/2026-10-18+GH-1136/provenance.jsonl:1-5`).
- [Pass] GH-1112 repair has the in-progress label and corresponding receipt/event (`releases.sql:874`, `:2899`, `:3744`); original timestamp loss is disclosed (`PROJECT/2-WORKING/GH-1136-B1-ACCEPTED-START.md:46`). The stored scoped patch adds no test file/case (`TESTS-RESULTS/2026-10-18+GH-1136/review-diff.patch.txt:1`, `:75`, `:125`).
- Limitation: `.relay-artifacts/review-diff.patch.txt` is absent this turn; inspected the repository evidence copy bound by `TESTS-RESULTS/2026-10-18+GH-1136/review-diff.binding.txt:1` and the current whole implementation. No suites, executable fixtures, git commands or source writes were run. Final committed-state qualification remains the harness's next action.

Relay closed (Approved), no further turn needed. Handing the token to Producer (claude-a); the harness owns the relay-only commit and subsequent gate.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->

### System · relay-drive — 2026-10-18T17:13:43Z
terminal STATUS Approved written by FAILED reviewer turn (codex; shim returned non-zero) — reverted
