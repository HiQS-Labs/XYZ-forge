# RELAY · GH-1003 PR 953 generated-view correction QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-09.
-->

NEXT: Producer
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
6. **Commit only the relay file** (`relay(gh-1003-pr-953-generated-view-correction-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: _<fill in the repo-relative path(s) the turn reviews>_
- Reviewer: codex   ·   Producer: merge-cleanup
- Started: 2026-10-09
- Definition of Done: _<fill in the acceptance criteria the Reviewer grades against>_

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.


## Narrow renewed review

Goal: verify the generated-view correction to the already reviewed merge candidate. Read the previous complete review at relay-system/2026-10-08/gh1003-pr953-merge.codex.md and the correction commit a57884ad3208d2923d59d4e9914ad06939ec8990. The previous review independently passed both entire parent changelogs, all ledger tables/receipts and normal code merge. Its only requested correction on #953/#966 was the routine LEADERBOARD delta. #971 also removes its routine view delta for the same binding policy.

The correction changes exactly LEADERBOARD.md to integration-parent blob 38ac9ee43bdedbd25be0cfec2029b0a27abd70a1:LEADERBOARD.md; it changes neither authoritative ledger nor code nor changelog. The original view bytes are preserved in primary scratch, not deleted. Review the changed file in full and compare object/blob identities. Do not repeat the already completed full-ledger sweep unless an unexpected artifact difference is observed. This is a bounded metadata correction, no new behavior or machinery.

Questions:
1. Does the corrected view exactly match the integration parent, satisfying AGENTS.md's rule that routine views belong to hosted reconciliation?
2. Are authoritative ledger, changelog and runtime/source blobs identical to the previously reviewed passing resolution?
3. Is the prior Should finding resolved with no new defect in this correction? Return Approved or specific Changes requested with observed input/falsifier; cite the previous receipt and correction head.

The final-head release check and relevant existing gate run belong in a separate full clone. Do not run suite/pytest/fixtures or change artifacts. Edit only this transcript.

## Log

### Reviewer · Round 1 · codex

VERDICT: PASS
Basis: Approved for the bounded generated-view correction at `a57884ad3208d2923d59d4e9914ad06939ec8990`. The prior Should finding is resolved; authoritative artifacts and source retain the previously reviewed resolution. Final-head clone qualification remains pending.
swept file: yes

Scope: read all 309 lines of `LEADERBOARD.md`, the entire previous receipt, and compared complete stored trees with SHA-1 verification without invoking git. No additional pre-existing defect was found within this view-preservation review. The graph registry has no project rooted at this seeded checkout; these non-code/object-identity claims use direct stored-object and file reads. No full-ledger sweep was repeated.

- [Pass] The corrected view and integration parent `38ac9ee43bdedbd25be0cfec2029b0a27abd70a1` share blob `86a63289f4def9c436de2419377ed8379cfabe17`; the working file equals those 66,283 bytes. `LEADERBOARD.md:1` now reads `<!-- releases-app generation: 1481 -->`; `LEADERBOARD.md:2` identifies it as generated, and `AGENTS.md:54`–56 assigns routine views to hosted reconciliation. This satisfies the exact falsifier in `relay-system/2026-10-08/gh1003-pr953-merge.codex.md:96`; the retained older view generation is deliberate pending reconciliation. Probe: `PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp" python3 .relay-scratch/tmp/object_probe.py`, exit 0; decisive output: `integration view equals correction True`, `working view equals correction True bytes 66283 lines 309`.
- [Pass] Correction versus its immediate parent `77b3a477f250ce38403b25e557b8c8bb66ce3391` changes exactly `['LEADERBOARD.md']`. Versus previously reviewed `a5abfacb2e80bfe65ee7dbc68666eb676343ad6f`, the only changes are that view and the previous review transcript. Every remaining path retains its mode/object identity, including all source and committed merge evidence. Exact unchanged blobs: CHANGELOG `2efcb720002acc116fe43609ae9ae7233feefa2e`, SQL `58f211e366134448a385b6c5642ada8f828dab6b`, DB `e8f2f18b3b83f06e97695ec9cec6a6e435047c1a`. Citations: previous receipt `relay-system/2026-10-08/gh1003-pr953-merge.codex.md:98`–101 records their passing preservation/consistency review. Same object probe, exit 0, prints these exact deltas and `equals prior True` for all three authoritative artifacts.
- [Pass] Seed HEAD `0db45866d2984aee6bd7d9d39fecc491172c95d2` contains the correction and adds only this renewed relay scaffold. The working changelog/SQL/DB hash to the correction's blobs. Full-view inspection includes the explanation at `LEADERBOARD.md:6`, all 292 rows at `LEADERBOARD.md:14` through `LEADERBOARD.md:305`, and source footer at `LEADERBOARD.md:309`. Probe: `PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp" python3 .relay-scratch/tmp/seed_check.py`, exit 0; decisive output: `seed delta versus correction ['relay-system/2026-10-09/gh1003-pr953-merge-r2.codex.md']`, three `working bytes equal correction ... True`, and `whole view rows 292 first rank 1 last rank 292`.
- [Unverified — needs clone run] The final-head release check and existing gate were not run here, as required by this review request at line 80 and the previous receipt at `relay-system/2026-10-08/gh1003-pr953-merge.codex.md:102`. Approval covers this correction; merge qualification remains the Producer/harness's separate full-clone step.

Manual red control of the same integration-parent identity predicate (original candidate substituted for correction), exit **1**, decisive output: `AssertionError: red control: old view fails integration-parent identity`. Command:

```sh
PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp" python3 - <<'PY'
import sys
sys.path.insert(0,'.relay-scratch/tmp')
from object_probe import commit
old,_=commit('a5abfacb2e80bfe65ee7dbc68666eb676343ad6f')
integration,_=commit('38ac9ee43bdedbd25be0cfec2029b0a27abd70a1')
assert old['LEADERBOARD.md']==integration['LEADERBOARD.md'], 'red control: old view fails integration-parent identity'
PY
```

Relay closed (Approved), no further review turn needed. Handing completion to Producer (merge-cleanup) for the final-head release check and relevant existing gate in a separate full clone; the harness owns the file-scoped commit.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
