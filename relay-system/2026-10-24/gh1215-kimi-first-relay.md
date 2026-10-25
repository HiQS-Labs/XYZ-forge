# RELAY · GH-1215 first Kimi relay: review kimi-turn.py
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-24.
-->

NEXT: Closed
STATUS: Approved
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
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns.
   Reviewer headings may be `### Reviewer · Round N`, `### Round N · Reviewer · <agent>`, `### Reviewer (<agent>)` (optionally followed by `— rN`), or `### Reviewer — Round N` (optionally followed by `(<agent>)`); follow the heading with a non-empty review body.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(gh-1215-first-kimi-relay-review-kimi-turn-py): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: `utils/py/kimi-turn.py` (and its entry point `relay-automation/kimi-turn.sh`)
- Reviewer: kimi   ·   Producer: claude-a
- Started: 2026-10-24
- Definition of Done: the shim is a faithful, minimal port of `utils/py/muse-turn.py`'s turn
  lifecycle to the Kimi Code CLI, with no containment logic of its own.

### Context for the reviewer

This is the first relay turn driven through `kimi-turn.sh` itself (GH-1215). Review-only: you may
write only this relay file.

**Operational envelope:** a local developer CLI adapter on one Mac. Grade against commensurate
complexity; do not ask for new test suites (AGENTS.md, GH-831) or enterprise fail-safes.

Read in full: `utils/py/kimi-turn.py`, `relay-automation/kimi-turn.sh`, `utils/py/muse-turn.py`.

Questions:

1. Does `kimi-turn.py` keep muse-turn.py's lifecycle order: claim, `rtl.before`, worktree begin,
   bounded run, timeout record, worktree end, empty-output guard, `rtl.enforce`, telemetry, exit
   mapping? Cite any step that is missing or reordered.
2. Is `has_model_output()` correct for the stream-json lines the CLI emits (`role:meta`,
   `role:assistant` with `content` or `tool_calls`, `role:tool`)? Could a real turn be wrongly
   failed, or an empty one wrongly passed?
3. Are the exit codes (2 usage, 0 defer, 5 launch/empty, 6 containment, 7 timeout) mapped the
   same way as muse-turn.py?
4. Flag anything over-built or missing. Keep findings to the stated scope.

Write a verdict below. Set STATUS to Approved if it passes; otherwise leave it Open and hand back.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer · Round 1 · kimi

swept file: yes

- [Pass] Lifecycle order is faithful to Muse: claim (`utils/py/kimi-turn.py:128-129`), `rtl.before` (`:131`), optional worktree begin (`:141-149`), bounded run (`:158-179`), timeout record (`:181-188`), worktree end (`:190-195`), empty-output guard (`:200-204`), `rtl.enforce` (`:206`), telemetry (`:208-223`), then exit mapping (`:225-234`). No step is missing or reordered relative to `utils/py/muse-turn.py:203-234,274-382`.
- [Pass] `has_model_output()` accepts only an assistant event with non-blank string content or a truthy tool-call list, while ignoring meta, tool, malformed, and blank events (`utils/py/kimi-turn.py:60-74`). Probe: `PYTHONDONTWRITEBYTECODE=1 PYTHONPATH="$PWD/utils/py" TMPDIR="$PWD/.relay-scratch/tmp" python3 .relay-scratch/kimi_output_probe.py`; exit status 0; decisive output: `meta_only: expected=False actual=False`, `tool_only: expected=False actual=False`, `empty_assistant: expected=False actual=False`, `assistant_text: expected=True actual=True`, `assistant_tool_call: expected=True actual=True`, `all output-guard probes passed`.
- [Pass] Exit behavior matches Muse: usage exits 2 (`utils/py/kimi-turn.py:40-42`), non-Kimi defer exits 0 (`:105-108`), launch and empty-output failures become 5 (`:171-177,200-204,231-232`), containment exits 6 (`:225-228`), and timeout exits 7 (`:229-230`), matching `utils/py/muse-turn.py:373-382`.
- [Pass] The entry point only establishes `XYZ_ROOT`/`PYTHONPATH` and execs Python (`relay-automation/kimi-turn.sh:11-14`); containment remains delegated to `RelayTurnLib` rather than reimplemented (`utils/py/kimi-turn.py:120,128-131,141-151,190-206`). Probe: `relay-automation/kimi-turn.sh --help`; exit status 0; decisive output included `Usage: kimi-turn.py [--print-bin]` and the required environment variables. Nothing is over-built or missing within the stated scope.

No Blocker, Should, or Nit findings; no pre-existing defects found in the swept files. Concrete fix: none required.

VERDICT: PASS
Basis: The complete adapter and entry point satisfy the Definition of Done, with lifecycle and exit behavior aligned to Muse and the Kimi-specific output guard verified by focused probes.  [Unverified — no citation]

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
