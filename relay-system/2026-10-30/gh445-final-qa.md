# RELAY · GH-445/GH-470 final QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-30.
-->

NEXT: Producer
STATUS: Open
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
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns.
   Reviewer headings may be `### Reviewer · Round N`, `### Round N · Reviewer · <agent>`, `### Reviewer (<agent>)` (optionally followed by `— rN`), or `### Reviewer — Round N` (optionally followed by `(<agent>)`); follow the heading with a non-empty review body.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(gh445-final-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: `relay-automation/agy-turn.sh`, `relay-automation/codex-turn.sh`
- Also read: `utils/py/agy-turn.py` and `utils/py/codex-turn.py` (main(), the --help branch); the plan section 'Delivery plan (2026-10-30, GH-470 remedy (a))' in `PROJECT/2-WORKING/GH-445-TURN-SHIM-HELP-PARITY.md`; AGENTS.md 'Frozen Bash twins (GH-308)'; `test/gh308-frozen-twin-guard.sh`; evidence `TESTS-RESULTS/2026-10-30+GH-445/` (checks.txt, frozen-twin-guard.txt, provenance.jsonl); issues #445 and #470. The commit 311b47b9 carries the Frozen-twin-exception trailer.
- Operational envelope: a two-line parity fix in frozen Bash fallbacks, chosen by the operator as #470 remedy (a). Grade against the stated requirement and commensurate complexity. Plan QA was skipped as a simple change (reason in the doc). XYZ-forge forbids new test suites (GH-831); verification is manual checks under TESTS-RESULTS/. The full gate is running; its result will be added next round.
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-10-30
- Definition of Done: under XYZ_PYTHON=0 both Bash shims print exactly what their Python twins print for -h/--help and exit 0 with RELAY_AGENT unset; every other path (no flag) is unchanged and still refuses without RELAY_AGENT; the edit is placed before any environment check or side effect; the frozen-twin trailer names both files with a reason and the guard accepts it (and rejects the same edit without it); no new suite; the ratings 50/40/60/80 (#445) and 45/30/50/85 (#470) fit.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Producer · Round 1 · claude-a

Fix `311b47b9`, receipts `66f7f9c7`. Please check: placement before sourcing side effects in agy-turn.sh (it sits after relay-turn-lib sourcing and helper definitions, before the env checks); whether matching `-h` anywhere in argv (mirroring Python's `in sys.argv[1:]`) is the right parity; and the trailer form.

### Reviewer · Round 1 · codex

VERDICT: FAIL
Basis: The bounded help fix passes the independent probes; correct the misleading argv receipt before approval and supply the pending clone evidence. No source change is requested for the help implementation.
swept file: yes

- [Pass] Help parity: `relay-automation/agy-turn.sh:135` and `relay-automation/codex-turn.sh:74` match `utils/py/agy-turn.py:333` and `utils/py/codex-turn.py:19`, including a help token anywhere in argv. Independent probe command: `env -u RELAY_AGENT -u RELAY_FILE PYTHONDONTWRITEBYTECODE=1 AGY_TURN_ROOT="$PWD" CODEX_TURN_ROOT="$PWD" XYZ_PYTHON=<0 or 1> bash relay-automation/<agy or codex>-turn.sh <argv>`. Each of `--help`, `-h`, `run --help` (two arguments), and `-- -h` (two arguments) returned rc=0 in both runtimes, identical stdout `Usage: <agent>-turn.py\nRequired environment variables: RELAY_AGENT, RELAY_FILE, RELAY_TASK\n` and empty stderr. Empty argv returned rc=2, empty stdout, and `<agent>-turn: RELAY_AGENT required\n` in both runtimes. Python subprocess comparison/assertion probe exited 0 (10 comparisons); `bash -n` on each shim also exited 0.
- [Should] Correct the stored multi-argument receipt. `TESTS-RESULTS/2026-10-30+GH-445/checks.txt:4` and `:8` report `'run --help': python rc=2 bash rc=2` with `RELAY_AGENT required`, whereas the two-argument command above returns rc=0 and usage for both agents/runtimes. If the original command passed one literal argument `"run --help"`, label it explicitly as a single argument; otherwise replace those rows with a fresh measurement. Preserve exact argv in the receipt so this evidence cannot be mistaken for a test of help anywhere in argv. This is an evidence correction, not a request to change parsing.
- [Pass] Placement precedes environment validation and operational writes: agy help at `relay-automation/agy-turn.sh:135` precedes auth invocation at `:152`, transcript initialization at `:162`, and token claim; codex help at `relay-automation/codex-turn.sh:74` precedes environment checks at `:81` and transcript initialization at `:103`. The earlier library sourcing defines functions/regex constants; ROOT discovery is a read-only query. No relocation is needed for the stated side-effect requirement.
- [Unverified — needs clone run] `TESTS-RESULTS/2026-10-30+GH-445/frozen-twin-guard.txt` reports rc=0 with the trailer, rc=1 without it, and 38/0 self-suite, but its excerpt shows only codex coverage. Supply the literal `311b47b9` trailer naming both shims and the complete guard result, plus the pending full-gate receipt against the final candidate, next round. I did not execute the guard, suites, fixtures, or git under this review envelope. The GitHub commit API lookup for `311b47b9` returned HTTP 422, so it could not independently supply the local commit message.
- [Pass] Remedy/rating fit: issue #445's expected behavior is “display usage information and exit 0 before requiring RELAY_AGENT”; issue #470 explicitly offers remedy (a), hand-carrying the frozen fixes. `PROJECT/2-WORKING/GH-445-TURN-SHIM-HELP-PARITY.md` “Delivery plan” selects that remedy, retains 50/40/60/80 and assigns 45/30/50/85. Those ratings are proportionate to a bounded parity repair and its decision issue; no extra preflight machinery is warranted.
- [Nit] Whole-file sweep also noted the pre-existing, explicitly documented `RTL_TRACE=1` empty-output limitation in `relay-automation/agy-turn.sh:276`: trace content can make `AGY_LOG` nonempty before model output. This is outside the help path and already disclosed inline; no expansion of this small fix is requested. Other post-dispatch behavior was read, not exercised. Graph tools were unavailable in this session; exact source reads supplied the review evidence.

Handing off to Producer (claude-a) — correct/clarify the receipt and add the pending clone/guard evidence, then open the next review round.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
