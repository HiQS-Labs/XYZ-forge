# RELAY · GH-1580 single allow-list repair final QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-11-24.
-->

NEXT: Producer
STATUS: Escalated
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
6. **Manual relay: commit only the relay file** (`relay(gh-1580-single-allow-list-repair-final-qa): <role> r<N>`); no push.
   **Driven turn (relay-drive, marathon): do not run git — the harness commits the turn.** **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. (The window wording is
   for a manual relay; in a driven turn, name the next role.) The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: `utils/py/swarm_preflight.py`, with plan and evidence under GH-1580.
- Reviewer: claude   ·   Producer: codex-a
- Started: 2026-11-24
- Definition of Done: Review this exact candidate against `origin/development` 895cec0f2. Read `PROJECT/2-WORKING/GH-1580-PREFLIGHT-MISREPORTS-GAPS.md`, `TESTS-RESULTS/2026-11-23+GH-1580/manual-check.md` and the previous FAIL in `relay-system/2026-11-24/gh1580-final-qa-plain.md`.

  - The one authorized fix is the Bash option allow-list and Bash builtin recognition. The previous F1 and F2 cases (three concrete inputs) remain READY, with a gap. A missing script or executable in a resolvable later segment still refuses. Check the normal and adjacent paths, including the fixed subprocess arguments and inherited environment handling. Preserve legacy first-command behavior.
  - Probe line anchors, the path_present outcome, advisory acceptance gaps and existing exit codes remain as previously verified. Check the complete diff, but ground findings in observed behavior and the agreed scope.  [Unverified — no citation]
  - Confirm the new red/green evidence and focused suites in provenance. The full pre-push gate is pending; grade this as implementation QA, without assuming that gate passed. Read-only review, one round, no code edits. Report PASS, FAIL or PARKED and cite evidence.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). In a manual relay, end each turn by committing just this file; no push. In a driven turn the harness commits.

## Log

### Reviewer · Round 1

swept file: no

VERDICT: FAIL

Basis: The previous F1/F2 inputs are fixed and the allow-list works for `bash`/`sh` options and builtins. One false refusal of the same class remains: an append assignment before a later command (F3). It contradicts the plan's own plain-gate rule and the acceptance criterion "a gate that is not plain keeps the first-command check it had before (no new refusal)". This is the only permitted round, so STATUS is Escalated. The pending full gate is not assumed.

- [Should] F3 — `NAME+=value cmd` is not recognized as an assignment. `utils/py/swarm_preflight.py:580` tests `[A-Za-z_]\w*=`, which misses `+=`; `+` and `=` both pass `_PLAIN_GATE_RE`, so the segment is plain and the assignment word reaches the program/PATH lookup. Contradiction: plan line "no segment that starts with an assignment" (`PROJECT/2-WORKING/GH-1580-PREFLIGHT-MISREPORTS-GAPS.md:71`, Plan item 2) vs `swarm_preflight.py:580`.
  - **Observed input:** `true && PYTHONPATH+=:src python3 -V` → BASE-equivalent ready=1, HEAD ready=0 `command 'PYTHONPATH+=:src' not found in PATH`, plain=True. `true && PATH+=:./bin ls` → base ready=1, HEAD ready=0 `gate program not found under target_root .: PATH+=:./bin`. `true && A+=1 ls` → base ready=1, HEAD ready=0 `command 'A+=1' not found in PATH`. The gate runner's shell accepts the form: `/bin/bash --noprofile --norc -c 'true && A+=1 ls README.md && PYTHONPATH+=:src python3 -c "import os;print(os.environ[\"PYTHONPATH\"])"'` printed `README.md` and `:src`, exit 0 (runner: `utils/py/marathon_drive.py:2409`, `executable="/bin/bash"`).
  - **Affected scope:** a `&&` list whose later segment's first word matches `[A-Za-z_]\w*\+=`. A lone or first-segment assignment is unchanged (base refuses it too: `A+=1 ls` base 0, HEAD 0).
  - **Fix:** `re.match(r'[A-Za-z_]\w*\+?=', program)`. One-character-class change; no parser, no per-program-block edit.
  - **Falsifier:** the finding is wrong if base also refuses these inputs or `/bin/bash` rejects them. After the fix all three must be READY plus the gap; `true && A=1 ls` stays READY plus gap; `true && gh1580_missing_command` still refuses. Record red/green in the existing `controls.sh`.

- [Nit] F4 — The plan's Risks paragraph does not name the accepted cost for programs an earlier segment creates: `true && python3 -m venv .v && .v/bin/pytest` is base ready=1, HEAD ready=0 `gate program not found under target_root .: .v/bin/pytest`. The agreed rule requires this refusal (a static check cannot tell it from a genuinely missing program, control D2d), so no behaviour change is requested. Add one sentence so an author knows to make such a gate non-plain or wrap it in a script.

- [Pass] Previous F1/F2 closed. Same probe: `true && bash +x -n utils/swarm-preflight.sh`, `true && bash -eO extglob utils/swarm-preflight.sh`, `true && shopt -s nullglob` → HEAD ready=1, plain=False. The gap text (`utils/py/swarm_preflight.py:1906`) is asserted READY + gap at `TESTS-RESULTS/2026-11-23+GH-1580/outputs/allowlist-green.txt:116`, `:120`, `:124`; the previous candidate reads `[MISMATCH]` on the same three at `outputs/allowlist-red-full.txt:116`, `:120`, `:124`.
- [Pass] Genuine absences still refuse: `true && bash -n utils/missing.sh`, `true && gh1580_missing_command`, `true && ./gh1580_missing` → base ready=1, HEAD ready=0, each naming the missing item (`utils/py/swarm_preflight.py:1875` loop). `true && bash -nx utils/swarm-preflight.sh` and `sh -n` → ready=1, plain=True. `-o pipefail`, `-c`, `--`, `-`, `--posix`, `-l`, bare `bash`, `cd`, `time`, `command`, `.`, `:`, `env`, `A=1 ls`, newline, `;`, `|` and trailing `&&` → no flip, non-plain.
- [Pass] First-command behaviour: `true`, `pytest_missing`, blank, empty, `bash -e`, `bash +x ...`, `A+=1 ls` gave identical base/HEAD readiness; a single simple builtin skips the subprocess at `utils/py/swarm_preflight.py:601`.
- [Pass] Builtin discovery is fixed text in a clean environment. The captured call was `['/bin/bash','--noprofile','--norc','-c','compgen -b && compgen -k']` with `cwd='/'`, `env={'LC_ALL':'C'}`, `timeout=2`; with hostile `BASH_ENV` and `BASH_FUNC_compgen%%` set in the parent it returned 79 words including `shopt` and `time`, no injected word. A forced `TimeoutExpired` fell back to first-command, non-plain (`utils/py/swarm_preflight.py:565-576`, fallback at `:604-606`). `coproc`, `mapfile`, `readarray` flip to refused, but on this host the runner `/bin/bash` does not report them either, so that refusal is consistent with the runner.
- [Pass] Anchors, `path_present`, gaps, exit codes: `re.M` in both grep branches and `landed` on absence (`utils/py/swarm_preflight.py:250-283`), matching `relay-automation/CONTRACT.example.md` ("Patterns are regexes matched per line"); `acceptance_gaps` only appends to a list (`:1123-1142`), and `report_candidate` derives codes 6/7/4/5 from state and ready alone (`:1999-2004`).
- [Pass] Evidence: the sha256 of `outputs/allowlist-green.txt` (`f82781f8...`), `allowlist-red-full.txt` (`b6ac73cd...`) and `allowlist-focused-suites.txt` (`ee159d9d...`) equal the `output_sha256` in `provenance.jsonl`; current source sha256 `964ba60c00da...` equals the prefix on `allowlist-green.txt:1`. Totals 42/0 and 39/3; focused suites 100+12+16+26 = 154, all rc=0 at ba7cf57cb, identity bracket unchanged. These are Producer receipts I read, not fresh runs.

Probe: `python3 .relay-scratch/probe.py`, exit 0 (scratch, discarded). It drives `evaluate_candidate` with the stubbed-network harness printed in `relay-system/2026-11-24/gh1580-final-qa-plain.md`, allows only the fixed `/bin/bash` discovery subprocess, and compares the real `gate_segments` with the base-equivalent `lambda g: ([g.split()] if g.split() else [], False)`. Decisive output:

```text
     'true && A=1 ls' base 1 head 1 plain False
FLIP 'true && A+=1 ls' base 1 head 0 plain True command 'A+=1' not found in PATH
FLIP 'true && PATH+=:./bin ls' base 1 head 0 plain True gate program not found under target_root .: PATH+=:./bin
FLIP 'true && PYTHONPATH+=:src python3 -V' base 1 head 0 plain True command 'PYTHONPATH+=:src' not found in PATH
```

Limits: `swept file: no` is literal. I read the changed evaluator, gate, gap, readiness and report regions of `swarm_preflight.py`, not all 2280 lines; the unread remainder (contract extraction, artifact inference, acceptance parsing, packet rendering) got no new sweep here, so I make no no-defects claim for it. No Git command was run, so I compared against a base-equivalent segment function, not a live diff against 895cec0f2. No suite, fixture or gate was run. No Form 2 finding is pending.

Handing off to Producer (codex-a) — the single round is Escalated: report FAIL with F3 (and Nit F4) to the operator; a repair needs the operator's authorization and a new review round.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
