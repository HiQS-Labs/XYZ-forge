# RELAY · GH-909 plan QA: completion locking
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-01.
-->

NEXT: Reviewer
STATUS: Open
ROUND: 2 / 4

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
6. **Commit only the relay file** (`relay(gh909-plan): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **.relay-artifacts/GH-909-COMPLETION-LOCK-LOSS.md** — the read-only path that
  `relay-drive.sh --artifact-file PROJECT/1-INBOX/GH-909-COMPLETION-LOCK-LOSS.md` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-10-01
- Definition of Done: Review GH-909 plan and committed red control, recon, ratings. Questions: Is stable fcntl sidecar sufficient to remove reclamation TOCTOU without changing JSON contracts? Does bounded wait/progress and mixed-old-writer fail-closed approach preserve safety? Are exactly three existing fixture adaptations commensurate and no new tests needed? Cite source and observed falsifier for blockers. macOS/Linux local filesystem only; no enterprise/network-FS scope. No suites in worktree. Approve only a grounded surgical plan.

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
Basis: The core flock direction is surgical, but the mixed-version safety claim is incomplete and the promised recon/evidence pointers are absent from the plan. Resolve these before implementation.
swept file: yes

- [Should] **Specify the sidecar pathname and a safe forward cutover, not only rollback quiescence.** Artifact lines 27–30 say “Stable sidecar regular file” and “fail closed if old .lock directory exists.” That check alone does not cover old writers arriving after the check. At `utils/telemetry/append-xyz-completion.sh:45,72,85–101`, old writers mkdir the legacy path, read `<path>/pid`, and recursively delete it after 20 empty reads or a stale PID. If the regular file uses that same path, an old waiter treats it as empty and deletes the inode; if it uses another path, a later old writer can acquire the legacy directory independently. Cheapest fix: explicitly require quiescing and retiring every old writer sharing the JSON path before forward deployment (including already running/waiting shell invocations), name the sidecar, retain fail-closed handling of pre-existing legacy directories, and limit the guarantee to cooperating upgraded writers. Do not claim live mixed-version safety from a directory-existence check.
  Observed input: Existing old-writer branch `if [[ "$empty_streak" -ge 20 ]]; then rm -rf "$lockdir" ...` at line 90, with a regular `<XYZ_JSON>.lock` file and no readable `<XYZ_JSON>.lock/pid`; alternatively a new sidecar plus the old writer's `mkdir "$lockdir"` at line 72.
  Affected scope: Old and upgraded writer invocations targeting the same `XYZ_JSON_PATH` during deployment or rollback; local macOS/Linux only.
  Falsifier: In a disposable clone, hold the upgraded transaction while starting an old writer and another upgraded waiter. A valid live-mixing protocol must keep one lock domain, preserve the held inode, and prevent overlapping JSON transactions. Otherwise require and verify quiescent cutover; ordinary upgraded-only writes must still succeed. This is source-derived; no mixed-version executable replay ran in this turn.

- [Should] **Add the promised bounded Recon Map and direct receipt citations.** Artifact line 21 says “Recon below and committed manual receipt,” but the complete 43-line document contains neither source locations nor the receipt path. Add entry/caller locations, the sole JSON transaction, all legacy acquisition/reclamation/release branches, timeout/error paths, fixture dependencies, and exact evidence links. Useful anchors: `utils/py/relay_drive.py:491–504`, `utils/py/marathon_drive.py:1323–1335`, `relay-automation/marathon.sh:69–79`; writer lines 27–36, 45–102, 105–142. Name `TESTS-RESULTS/2026-10-01+GH-909/red-handoff/{replay.py,writer.sh,result.json,records.json,provenance.jsonl}`. This is a document-evidence correction, not a request to broaden runtime behavior. If the sidecar path changes, account for `relay-automation/xyz-vendor.sh:236` preserving the existing runtime path.

- [Pass] **Retained red evidence supports the narrow root-cause claim.** `red-handoff/result.json` reports `"writer_rcs": [0,0,0]`, `"lock_exists_while_b_paused_after_w": false`, and `"lost_record": "W"`; records contain B/A. Read-only comparison also found the instrumented writer identical to current source after removing its three scheduling barriers. Receipt consistency probe (exit 0):
  `python3 -c 'import json,pathlib; p=pathlib.Path("TESTS-RESULTS/2026-10-01+GH-909/red-handoff"); r=json.loads((p/"result.json").read_text()); assert r==json.loads((p/"provenance.jsonl").read_text()); assert r["writer_rcs"]==[0,0,0]; assert [x["sessionId"] for x in json.loads((p/"records.json").read_text())]==r["records"]==["B","A"]; print("rcs=0,0,0; records=B,A; missing=W; receipt consistent")'`
  Decisive output: `rcs=0,0,0; records=B,A; missing=W; receipt consistent`. This checks retained evidence, not a fresh concurrency run or commit ancestry.

- [Pass] **Scope and ratings are proportionate.** Artifact lines 27, 35, 40 preserve JSON contracts, bound per-holder and total wait, require corrected replay and existing suites, and rate silent telemetry loss without claiming actual agent-work loss. Stable-inode flock around the entire existing read/replace transaction removes PID reclamation for cooperating upgraded writers; stdlib-only is sufficient within the stated filesystem envelope. Exactly three fixture adaptations are justified by the cleanup assertion in `test/xyz-completion.sh` section 5, fabricated holders in `test/gh123-lock-progress-bound.sh` sections A/B, and starvation holder in `test/gh358-lock-instrumentation.sh` control 2. No new suite is needed. The real-holder handover fixture must avoid unlocked gaps that let a waiter acquire early.

- [Unverified — needs clone run] Corrected mutual exclusion, crash release, moving-token/deadline behavior, total cap, exit 75 diagnostics, old-directory refusal, and the adapted suites remain execution acceptance gates. No suites, pytest, executable fixtures, or git commands ran here. Graph tools were unavailable; evidence used bounded source reads/searches. Whole plan swept; no additional pre-existing plan defects found beyond the two findings above. Full writer source was read for context; this is plan approval, not runtime signoff.

Handing off to Producer (claude-a) — address both Should findings and take your turn.

### Producer · Round 2 · claude-a

- Implemented mixed-version finding: named `<XYZ_JSON_PATH>.lock`, required verified quiescent forward cutover and retirement of all old running/waiting writers, limited guarantees to upgraded cooperating writers. Legacy-directory refusal is explicitly diagnostic, not a live-mixing guarantee. Retained rollback quiescence.
- Implemented recon/evidence finding: added bounded source locations for acquisition, reclamation, release, caller/error behavior, vendor path, fixture dependencies and existing flock prior art, plus direct links to all five committed red-control artifacts.
- No production edits or new runtime evidence. Please review the complete revised plan against both findings; ATE remains optional diagnostic variation after causal correction, excluded from qualification counts.

Handing off to Reviewer (codex) — review the revised plan.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
