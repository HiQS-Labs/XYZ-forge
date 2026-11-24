# RELAY · GH-1580 retained-scope delivery QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-11-24.
-->

NEXT: none
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
6. **Manual relay: commit only the relay file** (`relay(gh-1580-retained-scope-delivery-qa): <role> r<N>`); no push.
   **Driven turn (relay-drive, marathon): do not run git — the harness commits the turn.** **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. (The window wording is
   for a manual relay; in a driven turn, name the next role.) The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: `utils/py/swarm_preflight.py` and `relay-automation/CONTRACT.example.md`.
- Reviewer: claude   ·   Producer: codex-a
- Started: 2026-11-24
- Definition of Done: Operator-authorized fallback only. The previous gate-extension review Failed, and the extension has been removed. Review the deliverable at the relay seed head against development 895cec0f2. Read the working GH-1580 plan and retained-scope red/green output and provenance. Verify the legacy gate block is identical, the remaining grep-anchor and removed-path probe outcomes preserve caller semantics, and new acceptance gaps are advisory and observable. Source sweep as required by protocol; report every finding with its observed evidence. The final full gate is a separate requirement and is pending. No code edits. Report PASS, FAIL or PARKED for the retained scope.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). In a manual relay, end each turn by committing just this file; no push. In a driven turn the harness commits.

## Log

### Reviewer (claude) — r1

VERDICT: PASS
Basis: the retained scope (anchors, removed-path, advisory gaps, legacy gate untouched) matches its Definition of Done at seed head 99f48b73d vs development 895cec0f2. The final full gate is NOT covered here — it is a separate pending requirement.
swept file: yes

Method: read-only probes in-process (`python3 -I`, TMPDIR under `.relay-scratch/`), `git diff`, and the retained outputs. No validate.sh / test/*.sh / pytest run.

- [Pass] Legacy gate block identical to development. `git diff -U0 895cec0f2 HEAD -- utils/py/swarm_preflight.py | grep '^@@'` lists hunks at 251, 268, 277, 282, 415, 1067, 1354, 1762, 1876, 1924, 1982. The gate check sits at `utils/py/swarm_preflight.py:1819-1849` (`gate_parts = gate_cmd.split()` … `command '{g0}' not found in PATH`); no hunk touches it. The 1762 and 1876 hunks bracket it, so `test/gh343-gate-program-target-root.sh`'s branch-deletion control is unaffected.
- [Pass] Anchor probe semantics. Executed `eval_probes` on a temp file `a\nENABLE_X=1\nb\n`: `grep_present '^ENABLE_X=1$'` → `unfixed`; `grep_absent '^b$'` → `landed`; `(?m)^ENABLE_X=1$` → `unfixed` (inline flag still fine); `\AENABLE_X=1\Z` → `landed` (whole-file anchor works as documented in `relay-automation/CONTRACT.example.md:25`). CRLF file with `^ENABLE_X=1$` → `unfixed` (text-mode open normalizes newlines, `swarm_preflight.py:276`). Non-UTF-8 file → `blocked` (existing `except Exception`, `:296`), unchanged.
- [Pass] Removed-path caller semantics. `swarm_preflight.py:268-271` now reads an absent `path_present` target as `landed`; present stays `unfixed`. The only landed-only consumer, `utils/py/marathon_drive.py:2698-2704`, therefore accepts a completed removal. Corpus sweep `TESTS-RESULTS/2026-11-23+GH-1580/outputs/corpus-sweep.txt`: 129 docs, 128 identical, one differs (`GH-269-RELEASES-DB-SWITCHOVER.md`, rc 6 → 4, the intended `path_present` effect; recomputed with a python pairing script, not taken from the summary alone).
- [Pass] Gaps are advisory and observable. Text line `gap         :` and JSON `readiness.gaps` come from one list (`swarm_preflight.py:1762` → `:1876` → `:1924` → `:415`/`:1982`); nothing in `acceptance_gaps` (`:1070-1089`) touches `ready`/`ready_next`, and GH-557's frozen-manifest block is untouched. Retained green output shows the `## Done when` case still `exit 0 … verdict : ready` and the verbatim-match control `gaps=[]` (`outputs/retained-scope-green.txt`).
- [Pass] Provenance matches the artifact. `sha256sum utils/py/swarm_preflight.py` starts `73bc3ee6c113`, equal to the green header; `git diff --stat c6b4959ab HEAD` shows no `utils/` change after the green run; `provenance.jsonl` red 6 MATCH / 8 MISMATCH at 895cec0f2, green 14 / 0 at c6b4959ab. The eight red MISMATCH rows are exactly D1a, D1b, D4a, D3 text/json, D3-control json, D3-doc text/json; the three D2 legacy rows MATCH on both sides, so the legacy-gate claim is measured, not asserted.
- [Pass] Pre-existing code sweep (`eval_probes` and its two consumers): nothing new found beyond the Nit below.
- [Nit] Planner/preflight now disagree on line anchors. `utils/py/_marathon_plan.py:503-510` (and the frozen JS twin `utils/marathon-plan.sh:414-420`) still call `re.search(p.get("pattern",""), content)` without `re.M`, while `swarm_preflight.py:277,282` use it, so a `^…$` `grep_present` reads `landed` in the planner and `unfixed` in preflight. The tracking line (`PROJECT/2-WORKING/MARATHON-PLAN-2026-11-23.md:207`, #1583) names only `path_present`. Not blocking: no in-repo contract uses a line-anchored pattern (plan "Recon map"), and the same file's `path_present` parity is already parked. Suggest widening #1583's title to cover grep anchors. Optional; no behaviour change requested.
- [Nit] Deferred scope stays open as the plan states: a later missing command (e.g. `bash -n x && uv lock --check`) still reads ready — proven by the green D2 row `observed: exit 0 … verdict : ready`. The PR must not close #1580.

Dropped/parked from this review: none beyond the Nits above.

handing off: relay closed (Approved) for the retained scope; no further turn needed. The full gate remains a separate pending requirement.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
