# RELAY · GH805 implementation plan QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-09-24.
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
6. **Commit only the relay file** (`relay(gh805-implementation-plan-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **.relay-artifacts/GH-805-TEST-VALUE-ADMISSION.md** — the read-only path that
  `relay-drive.sh --artifact-file PROJECT/2-WORKING/GH-805-TEST-VALUE-ADMISSION.md` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: codex   ·   Producer: astra
- Started: 2026-09-24
- Definition of Done: Review the full canonical plan against GH805's seven-step refined checklist. Operational envelope: one local developer toolkit repository, bounded observe-only pilot, one PR; commensurate complexity, no enterprise approval service or speculative scanner framework.

Questions: (1) Are source/collector claims grounded and preserved consumers identified? (2) Do the seven checklist steps have falsifiable acceptance, bounded tests, meaningful red controls and honest no-go options? (3) Does this extend gate_inventory/ci-route/current runners rather than duplicate them? (4) Are ratings, unknown recurrence trend, rollback, GH808 exclusion and GH774 partial scope honest? (5) Is the authority distinction sufficient for an explicitly NON-enforcing pilot? Grade plan readiness, not missing implementation evidence at this pre-build stage. Read referenced source files; do not run tests in the reviewer worktree. Write findings only here, no commits yourself (the harness owns commit).

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer · Round 1 · codex

VERDICT: PASS
Basis: Ready to implement within the stated one-repository, observe-only envelope. The seven steps identify existing owners, bounded changes, falsifiable acceptance and explicit keep/no-go outcomes. This approves the plan, not implementation or merge readiness.
swept file: yes

- [Pass] Grounded collector and consumer map. `utils/py/gate_inventory.py:inventory` emits the existing `gates`/`negative_control` contract consumed at `test/gh419-gate-inventory.sh:45` and `test/litmus-release.sh:179`. The plan explicitly says “Preserve that default contract; new audit/decision output is opt-in.” `test/gh436-merge-cleanup.py:863` imports the three gh534 modules; retaining their wrapper avoids duplicate collection. No change requested.
- [Pass] Selection repair targets actual seams: `validate.sh:1453` and `ci-local.sh:323` invoke only `test/test_python_layer.py`; `package.json:12` owns the Node unit command; `test/flightdeck/test_flightdeck.py:226` binds the server to ephemeral loopback. The source-only probe below corroborates all four releases omissions. Step 2 requires supported-host eligibility, additions-only selection, once-per-runner collection and child-failure propagation before claiming repair. No change requested.
- [Pass] Controls and simplification are proportionate. `test/gh269-roadmap-retired.sh:22` documents 0/4 but its predicate rejects only 3; step 3 explicitly repairs that accepted set. The gh165 quote/comment filter and suppressed missing-input errors are addressed by witnessed controls rather than a speculative scanner. `test/gh567-roadmap-dashboard-retired.sh:check_writer_audit` repeats discovery for distinct searches; step 4 preserves diagnostics/detection and permits “record a keep decision.” The gh269 DB scenario and gh568 CLI/AST checks remain separate. No change requested.
- [Unverified — no citation] Authority claims are sufficient for this non-enforcing pilot: step 5 says “live authority unavailable means explicit no-go, without changing branch protection”; step 6 says “approval_trusted remains false without independently verified authority, even if metadata says approved.” Three advisory states and one optional metadata artifact do not require an approval service. Forgery/staleness observations are separated from semantic recommendations and synthetic fixtures are explicitly excluded from real-world false-accept estimates. No change requested.
- [Unverified — no citation] Scope and evidence limits remain honest: the plan states “Complete incident counts and trend are unknown,” excludes GH808/gh251, limits GH774 completion claims, preserves existing guards, and names a reviewed PR revert for Costly routing changes. The final review, committed provenance, identity checks and full qualifying gate remain required. Full-file sweep found no additional pre-existing plan defect requiring revision.
- [Unverified — needs clone run] Actual Flightdeck/Node eligibility, runner parity, witnessed red/green controls, simplification benefit and final gate status remain future acceptance work. No suites or executable fixtures were run here; their absence is not a pre-build blocker. Ledger ratings and historical timing were not independently re-measured in this review.

Read-only probe (exit 0; Python used only source text and directory names, no imports of repository code):
```python
import re
from pathlib import Path
s=Path("validate.sh").read_text(); b=s.split("TESTS=(")[1].split("\n)")[0]
n=re.findall(r'^\s*"([^"\n]+\.sh)"',b,re.M)
assert n and len(n)==len(set(n))
r=Path("utils/ci-route.sh").read_text(); m=re.search(r'^SUBSYSTEM_TESTS_releases="([^"]+)"',r,re.M).group(1).split()
print("unique_shell_entries",len(n))
for x in ("jog-queue.sh","gh75-dashboard.sh","gh605-board-policy.sh","gh605-work-state.sh"):
 print(x,"full_registered",x in n,"releases_selected",x in m)
print("node_unit_files",len(list(Path("test/unit").glob("*.test.js"))))
```
Command: `export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"; mkdir -p "$TMPDIR"` followed by `python3 -` with the above stdin. Decisive output:
```text
unique_shell_entries 417
jog-queue.sh full_registered True releases_selected False
gh75-dashboard.sh full_registered True releases_selected False
gh605-board-policy.sh full_registered True releases_selected False
gh605-work-state.sh full_registered True releases_selected False
node_unit_files 4
```

Relay closed (Approved), no further review turn needed. Producer astra may proceed with implementation and the specified clone-based verification; the harness owns the relay-file commit.


### Attestation · relay-drive — 2026-09-25T03:03:49Z
task: RELAY-gh805-plan
reviewer: codex
status: Approved
reviewed-head: 7813ab52cbb368e97ee43a6336cb9be91ea18b69
added-range: 6316+4650
added-sha256: 0f224dfeb432b45a6a212864d129bd5973e665d447d16ecbb5eb677fca1b91d8
<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
