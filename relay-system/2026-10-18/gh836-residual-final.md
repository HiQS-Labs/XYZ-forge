# RELAY · GH836 residual fixture spike final QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-17.
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
6. **Commit only the relay file** (`relay(gh836-residual-fixture-spike-final-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **.relay-artifacts/SUMMARY.md** — the read-only path that
  `relay-drive.sh --artifact-file TESTS-RESULTS/2026-10-18+GH-836/SUMMARY.md` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: codex   ·   Producer: codex-producer
- Started: 2026-10-17
- Definition of Done: Approve the bounded local spike only if the three fixture edits preserve existing behavior/controls and the report accurately states the paired data and limits. No release-readiness or full-suite claim is requested.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Review packet

Read SUMMARY.md in TESTS-RESULTS/2026-10-18+GH-836, all four gh549 logs, paired-runs/timing-summary/label-comparison, candidate.patch, current gh436 collection/inventory/parity output, preparation-failures and provenance. Inspect diff from base 655bc340 and complete test/gh549-work-events.sh, relevant releases_app.py and existing parity function. Plan QA is Approved round 1/3 in gh836-residual-plan.md. Candidate code is 41977438, measured only as that test patch atop frozen base/ledger. Operational envelope: isolated test fixture spike, no product rewrite, shared mutable fixtures, new CI test/case/assertion/parameter, registry/gate/policy/routing edit, push, PR, merge or rollout. Commensurate complexity: three existing setup lines plus comments. No suites or executable fixtures in reviewer worktree; read-only inspection/probes only.

Concrete questions: Does every actual concurrent race/assertion/receipt/missing-reference control survive? Are FXD five rows/four eligible, FXI two and FXR7 one independent, with unrelated live-tail seed removed only where necessary? Do results justify 159.95s/68.1% saving versus observed spread without inventing whole-CI payoff? Is prior art correctly separated (#838/#848/#1123) and current 18-method collection described honestly without claiming the full behavioral suite ran? Are invalid manual parser/anchor attempts transparently excluded? #1131 is a DECIDED separate cadence issue; no old-cadence full benchmarks, parallel qualification or broad CI rollout are prerequisites here. Grade local spike completeness, not publication/merge qualification. Only write findings here; cap 3, never reset/extend or resume old batch. Cite evidence/file:line; no scope expansion.

## Log

### Reviewer · Round 1

VERDICT: PASS
Basis: Approve the bounded local fixture spike and its report. The paired focused evidence supports the stated local saving and preservation of the existing controls; this is not integration, promotion or full-pipeline qualification.
swept file: yes

- [Pass] Swept the entire 36-line summary and complete 1,515-line gh549 file, including pre-existing controls; no additional pre-existing defect requiring correction within this spike was found. The retained patch contains only the three setup substitutions and comments (TESTS-RESULTS/2026-10-18+GH-836/candidate.patch:1). Initialization supplies migrations, a repo row, lenient settings and a canonical dump (utils/py/releases_app.py:2175). FXD creates five real-verb rows, excluding Deferred from the four eligible projections; separate copied descendants preserve dry-run, mapping, idempotence, receipt joins and actual two-process races with the existing bounded rendezvous and exit checks (test/gh549-work-events.sh:951, :1051, :1078, :1383). FXI retains its two own rows and completed suppression; FXR7 independently retains 9920 and the exclude-source mutation (:1152, :1178, :1208). Removing their live-tail seeds avoids overshooting the new empty ledgers. Candidate logs independently retain “4 = 4”, racer exits “0 0”, “7 > 4”, all three interleave red controls and the receipt-bypass red control (candidate-gh549-1.log and candidate-gh549-2.log under the evidence directory:107, :122, :147). No correction requested.
- [Pass] The four raw logs end with “125 passed, 0 failed” and real times 236.80/75.58/233.10/74.42 (each evidence *gh549*.log:162); timing-summary.json:1 correctly gives medians 234.95/75.00, saving 159.95 s / 68.0783%, ranges 3.70/1.16 and total 619.90 s. Baseline identity and paired-runs retain the frozen base, test hashes and fixed ledger hash (baseline-gh549-1.json:1; paired-runs.jsonl:1); the current test hash matches the measured candidate. Read-only provenance probe: `python3 -c 'from pathlib import Path; import json,hashlib; p=Path("TESTS-RESULTS/2026-10-18+GH-836"); r=[json.loads(s) for s in (p/"provenance.jsonl").read_text().splitlines()]; print("entries",len(r),"mismatches",[x["artifact"] for x in r if hashlib.sha256((p/x["artifact"]).read_bytes()).hexdigest()!=x["sha256"]])'`; exit 0; decisive output: `entries 31 mismatches []`. The summary limits this to n=2 per condition on this host, discloses untimed setup/review costs and makes no hosted or whole-CI payoff claim (.relay-artifacts/SUMMARY.md:11, :36). No correction requested.
- [Pass] Prior #838/#848/#1123 work is separated from this result, and the historical wrong-anchor control and current invalid inventory parser are explicitly excluded (.relay-artifacts/SUMMARY.md:17, :30, :32). Direct source shows parity checks callable existence and AST calls without nested behavioral execution (test/gh534_phase_c_tests.py:571); gh436 still imports the phase modules (test/gh436-merge-cleanup.py:869). The retained current output says “7 passed, 173 deselected in 1.53s” with 1.83 s wall (current-gh436-parity.log:1), while inventory/collection show 18 distinct required methods once among 180; the report explicitly declines a complete behavioral-run claim. #1131 remains separate as required (.relay-artifacts/SUMMARY.md:36). No correction requested.

Review limits: source inspection and non-mutating parsing/hash checks only; no git, suite, pytest or executable fixture was run in this reviewer worktree. Runtime outcomes above are retained disposable-clone evidence, not a fresh reviewer rerun. Graph generation 2026-09-01 was stale/not-tracked for these files, so current source was read directly rather than treating graph results as current proof. Harness qualification remains outside this approval.

Relay closed (Approved), no further turn needed.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
