# RELAY · GH-1255 deployed-device evidence, timing acceptance pending
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-29.
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
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns.
   Reviewer headings may be `### Reviewer · Round N`, `### Round N · Reviewer · <agent>`, `### Reviewer (<agent>)` (optionally followed by `— rN`), or `### Reviewer — Round N` (optionally followed by `(<agent>)`); follow the heading with a non-empty review body.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(gh1255-device-evidence): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **.relay-artifacts/gh1255-device-evidence-packet.md** — the read-only path that
  `relay-drive.sh --artifact-file temp/gh1255-device-evidence-packet.md` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: codex   ·   Producer: codex-producer
- Started: 2026-10-29
- Definition of Done: Review this docs-only deployment/recovery report for accurate scope, retained failures/dispositions, no unsupported timed-success claim, source/publication/HQ/runtime distinctions, 4+3 recovered source IDs and zero-event unrecoverable session. Preserve numeric ratings and canonical links. Fresh timed 120-second acceptance remains pending; approval covers evidence accuracy only, not completion of that missing check. No live data, jobs, suites, Git or source edits; write only this relay.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer · Round 1

VERDICT: PASS
Basis: The complete 471-line seeded packet is internally consistent with the stated documentation-only Definition of Done. Approval covers the evidence report, not independently repeated deployment, historical suite execution, live-store recovery, or strict timed acceptance. No blocking or pre-existing defect found in the full artifact sweep.
swept file: yes

- [Unverified — no citation] Acceptance remains bounded. The current status says “Deployed — fresh timed acceptance pending”; the deployment narrative says “Do not describe timed acceptance or issue completion as passed.” The ledger remains “In progress.” The two timestamp differences are 127.029 and 166.674 seconds, matching the reported observation bounds; neither establishes actual latency or a failed/passed 120-second trial. Preserve the explicit pending check. Citations: packet lines 9, 132, 198–213, 455.
- [Pass] Recovery counts and exclusions agree across prose and JSON: “01a188ca has 4/4, 01a1892e has 3/3,” while 01a18930 has zero submitted events and no response_item fallback. Writer acceptances are explicitly distinguished from new rows; the post-recovery record retains stable IDs, cutoff, schema and integrity claims. Citations: packet lines 128–130, 176–196, 227–243. No correction required.
- [Pass] Source, publication, HQ deployment, runtime and app discovery are distinct: Rebalance source revision, standalone merge revision, 15 published files versus 9 HQ folder files, current installed receipt, and “Other app UIs not exercised.” No fleet-wide or all-app acceptance is asserted. Citations: packet lines 122–126, 140–157. No correction required.
- [Pass] Failures and dispositions are retained: the archived-source miss and exact-copy replay, concurrent fleet.last_result hash drift, generic helper's absent-ledger failure and scoped native-publication disposition, and the earlier driver exit 4 with superseding receipt. The historical sections are explicitly identified as historical. Numeric ratings remain 85/85/50/65 in both removed and added ledger rows; canonical issue and plan links remain. Citations: packet lines 102, 117, 128, 134, 249–251, 429–430, 454–455. No correction required.
- [Pass] Narrow packet-only measurement: the command below exited 0. Decisive output: `packet_lines 471`; session dictionaries yielded submitted/stored/matched counts `4/4/4`, `3/3/3`, `0/0/0`, all missing counts zero; `computed_seconds 127.029 reported 127.029`; `computed_seconds 166.674 reported 166.674`; `timing_status pending fresh timed submission`; `rating - True True` and `rating + True True`. This measures the packet, not the private source store. Probe output stayed under .relay-scratch/tmp.

  Command (after exporting PYTHONDONTWRITEBYTECODE=1 and TMPDIR="$PWD/.relay-scratch/tmp"):

  ```sh
  python3 - <<'PYPROBE' > "$TMPDIR/packet-probe.txt"
  import json
  from pathlib import Path
  from datetime import datetime
  p = Path(".relay-artifacts/gh1255-device-evidence-packet.md").read_text()
  marker = "## TESTS-RESULTS/2026-10-29+GH-1255/device-deployment.json\n"
  d = json.JSONDecoder().raw_decode(p.split(marker, 1)[1])[0]
  print("packet_lines", len(p.splitlines()))
  for sid, row in d["requested_sessions"].items():
      print(sid, row)
  for row in d["ordinary_schedule_observations"]:
      delta = (datetime.fromisoformat(row["present_by"]) - datetime.fromisoformat(row["submitted_at"])).total_seconds()
      print("computed_seconds", round(delta, 3), "reported", row["latency_upper_bound_seconds"])
  print("timing_status", d["strict_120_second_acceptance"])
  for line in p.splitlines():
      if line.startswith(("+INSERT INTO roadmap_items", "-INSERT INTO roadmap_items")) and "'1255'" in line:
          print("rating", line[0], "85/85/50/65" in line, "'85', '85', '50', '65', NULL, 'in-progress'" in line)
  PYPROBE
  ```

- [Unverified — needs clone run] Historical suite/publisher success is reviewed as retained reporting only; no suite, executable fixture, Git command, live history/database/job query, or runtime action was run this turn. The harness owns subsequent gates. The fresh timed submission remains outstanding as expressly allowed by this relay's Definition of Done.

Relay closed (Approved), no further turn needed. The producer's remaining operational milestone is the fresh timed 120-second acceptance check; this approval does not close GH-1255.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
