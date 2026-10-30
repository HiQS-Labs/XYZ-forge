# RELAY · GH-1255 final scheduled acceptance and recovery receipts
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
6. **Commit only the relay file** (`relay(gh1255-device-final): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **.relay-artifacts/gh1255-device-final-packet.md** — the read-only path that
  `relay-drive.sh --artifact-file temp/gh1255-device-final-packet.md` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: codex   ·   Producer: codex-producer
- Started: 2026-10-29
- Definition of Done: Final docs-only acceptance review after the fresh human reply. Verify all current claims and retained failure disclosures, distinction between prior untimed observations and measured 51.303-second scheduled result, 4+3 recovered submitted source IDs, honest zero-event session disposition, unchanged core storage/jobs and current receipts, numeric ratings preserved. Runtime unchanged; existing source QA/suites retained. Do not access live prompts/DB/jobs, run suites or Git. Only this relay may change.

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
Basis: The entire 682-line packet supports the final docs-only acceptance claim: the fresh source-to-observation bound is below 120 seconds, while recovery, scope and failure limitations remain explicit. No blocking or pre-existing defect found in the full artifact sweep. This approves the evidence report, not an independently repeated live-device run or the subsequent publication gate.
swept file: yes

- [Pass] Timing is supported by the new receipt, not by the earlier observations. Packet `.relay-artifacts/gh1255-device-final-packet.md:133` calls 51.303 seconds an upper bound; lines 243–267 retain submission/observation timestamps, agent=codex, matching submitted source event, normal store, one installed-helper query row, runs 20→21 and no foreground tailer/kickstart. The later run-23 exit 0 is described as a later observation, not the exit of run 21. Lines 202–215 retain the earlier 127.029/166.674 bounds without treating them as measured capture latency. No correction required.
- [Unverified — no citation] Recovery is bounded to available submitted events: packet lines 129–131 and 182–200 retain 4/4 and 3/3 matched source IDs, zero missing IDs, and the zero-event 01a18930 limitation with no response_item fallback. Writer acceptances are explicitly not new-row counts; lines 231–241 preserve stable IDs, cutoff, schema and integrity reporting. No correction required.
- [Pass] Publication, deployment and storage claims remain distinct. Packet lines 123–127 and 146–162 distinguish the upstream revision, standalone merge, 15 published files, 9 HQ files, current receipts and Codex-only app discovery. Lines 217–227 disclose concurrent last_result metadata and existing HQ drift while retaining unchanged core storage/client/plist claims. No correction required.
- [Pass] Failure history remains visible: packet lines 102, 129, 135, 140, 280 and 633–635 retain the earlier driver exit 4, archive miss/recovery, generic helper's absent-ledger failure, whole-config metadata drift and stopped full-registry fallback. The pending historical provenance entry is followed by the fresh scheduled PASS entry; the prior review's narrower approval is preserved at lines 357–392. No correction required.
- [Pass] Scope and ratings are preserved. The supplied full diff starts at packet line 404 and changes only documentation, receipts and ledger data; it contains no runtime, suite or gate edits. The removed/added GH-1255 ledger rows at lines 661–662 both retain 85/85/50/65 and numeric columns 85,85,50,65, with the canonical issue/doc links and In progress status pending reconciliation. Existing source QA/suite reporting remains at lines 94–102 and 123; no new source validation is claimed by this turn. No correction required.
- [Pass] Packet-only measurement exited 0. Decisive output: `packet_lines 682`; `scheduled_seconds 51.303085 rounded 51.303 within_120 True`; `schedule_runs 20 21 manual False matched True query_rows 1`; prior bounds `127.029` and `166.674` match their reported values; recovery submitted/stored/matched/missing counts are `4 4 4 0`, `3 3 3 0`, and `0 0 0 0`; both rating rows print `True True`. This measures the supplied packet only. Exact command, with output confined to scratch:

  ```sh
  export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"
  mkdir -p "$TMPDIR"
  python3 - <<'PYPROBE' > "$TMPDIR/final-packet-probe.txt"
  import json
  from pathlib import Path
  from datetime import datetime
  p = Path(".relay-artifacts/gh1255-device-final-packet.md").read_text()
  d = json.JSONDecoder().raw_decode(p.split("## TESTS-RESULTS/2026-10-29+GH-1255/device-deployment.json\n", 1)[1])[0]
  print("packet_lines", len(p.splitlines()))
  s = d["scheduled_verification"]
  delta = (datetime.fromisoformat(s["observed_at"]) - datetime.fromisoformat(s["submitted_at"])).total_seconds()
  print("scheduled_seconds", delta, "rounded", round(delta,3), "within_120", delta <= 120)
  print("schedule_runs", s["baseline_job"]["runs"], s["observed_job"]["runs"], "manual", s["foreground_tailer_or_kickstart"], "matched", s["matched_submitted_source_event"], "query_rows", s["installed_helper_query_rows"])
  for row in d["ordinary_schedule_observations"]:
      delta = (datetime.fromisoformat(row["present_by"]) - datetime.fromisoformat(row["submitted_at"])).total_seconds()
      print("prior_bound", round(delta,3), "reported", row["latency_upper_bound_seconds"])
  for sid, row in d["requested_sessions"].items():
      print("recovery", sid, *[row[k] for k in ("submitted_events","stored_rows","matched_source_ids","missing_source_ids")])
  for line in p.splitlines():
      if line.startswith(("+INSERT INTO roadmap_items","-INSERT INTO roadmap_items")) and "'1255'" in line:
          print("ratings", line[0], "85/85/50/65" in line, "'85', '85', '50', '65', NULL, 'in-progress'" in line)
  diff = p.split("## Full PR diff\n",1)[1]
  print("diff_paths", [line.split(" b/",1)[1] for line in diff.splitlines() if line.startswith("diff --git ")])
  rows = [json.loads(line[1:]) for line in diff.splitlines() if line.startswith('+{"timestamp"')]
  print("new_provenance", [(row["timestamp"],row["action"],row["result"]) for row in rows])
  PYPROBE
  cat "$TMPDIR/final-packet-probe.txt"
  ```

- [Unverified — needs clone run] Historical suites and publisher controls were not rerun. No Git, executable fixture, live prompt/database/job access or runtime action occurred. The harness owns the subsequent gate; this verdict does not certify a future push or issue closure.

Relay closed (Approved), no further turn needed.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
