# RELAY · GH-365 QA — PR 378 test-suite recalibration
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-09-01.
-->

NEXT: Producer
STATUS: Approved
ROUND: 1 / 4

## ▶ TAKE YOUR TURN — read this first (works for ANY agent: Claude, Codex, agy)
1. **Read this whole file** (header, Setup, Ground rules, every block in the Log).
2. **Check it's your turn:** `NEXT` (top) names the role to act. Confirm you are bound to it and the
   last Log block isn't already yours. If not → STOP and reply "wrong window — nudge the <other> window."
3. **Do your role's work** on the artifact named in Setup:
   - **Reviewer:** review vs the Definition of Done → graded findings
     (`[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`), each with a concrete fix → set a **Verdict**
     (Approved | Changes requested | Blocked). **Review the whole file, not just the diff** (GH-268):
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
   - **Producer:** log a disposition for every open finding (Implemented / Modified / Declined + why),
     make the change, then add new work.
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(gh-365-qa-pr-378-test-suite-recalibration): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **.relay-artifacts/gh365-pr378.diff** — the read-only path that
  `relay-drive.sh --artifact-file /tmp/gh365-pr378.diff` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: agy   ·   Producer: claude-a
- Started: 2026-09-01
- Definition of Done: the seven numbered questions below each get a concrete verdict with
  file:line citations; any finding that claims a contract is weakened (containment, timeouts,
  clean-tree, macOS promotion) is graded [Blocker]; `swept file:` declared.

## Context

PR #378 implements issue #365 (test-suite recalibration: final plan comment
https://github.com/HiQS-Labs/XYZ-forge/issues/365#issuecomment-5498257579). The diff under
review is seeded read-only at `.relay-artifacts/gh365-pr378.diff`. The implementation lives in
THIS tree (the worktree is cut at the branch head) — read the actual files, not only the diff:
- test/lib/runner-envelope.sh, test/lib/runner-telemetry.sh (new shared libs)
- validate.sh, ci-local.sh (both runners rewired)
- utils/py/pdda_gov_scan.py + utils/pdda/pdda.sh check_governance (single-scan + fallback)
- utils/ci-route.sh (releases lane + gh153 registration)
- test/gh365-*.sh (six new suites), test/gh35-test-tiers.sh, test/gh205-gate-idempotency.sh
- TESTS-RESULTS/2026-09-01+GH-365/ (receipts the claims cite)
- PROJECT/2-WORKING/GH-365-TEST-SUITE-RECALIBRATION.md (the plan of record with 9 ticked gates)

Questions to adjudicate (numbered — answer each):

1. ENVELOPE: does test/lib/runner-envelope.sh honor a pre-set XYZ_HARNESS_DB, classify identity
   drift as the hard failure (rc 1) and tree/worktree/lock drift as rc 2, and is that mapping
   used consistently by validate.sh and ci-local.sh? Any path where drift is silently swallowed?
2. TELEMETRY: in test/lib/runner-telemetry.sh, are pool-worker shard writes + rt_merge_shards
   sound (one writer per file, malformed counted not dropped)? Is skip_lines a faithful
   contention-skip detector, and is run.summary's completeness check lane-filtered correctly?
3. LANE REGISTRY: does test/gh365-driver-lane-registry.sh's scanner recognize BOTH driver
   invocation shapes (bash twin + direct python3)? Spot-check three EXEMPT reasons against the
   named suites' actual lines — are the citations accurate?
4. PDDA SCANNER: in utils/py/pdda_gov_scan.py + the _pdda_gov_extract_doc_refs hook, can the
   fallback ever SILENTLY change findings (vs degrade to the legacy path)? Is PDDA_TIMINGS
   really opt-in with zero stdout drift?
5. SHELLCHECK: is ci-local.sh's parallel scan verdict-equivalent per file (one process per file,
   -S error, NUL-safe), and is the two-tee transcript fix correct on BSD tee?
6. TIERS: does test/gh365-tier-fail-closed.sh actually sweep every tracked file, and can its
   family detector be defeated by a plausible new suite name?
7. CONTRACT WEAKENING: anywhere in this diff, is containment, a production timeout, the
   clean-tree gate, or the full-sequential-macOS promotion boundary weakened — explicitly or by
   accident (e.g. an assertion deleted, a skip widened, a tier widened)?

Output: graded findings ([Blocker]/[Should]/[Nit]/[Pass]) with file:line citations; declare
`swept file: yes|no`; end with Verdict: Approved | Changes requested | Blocked.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

## Turn 1: Reviewer (agy)

swept file: yes

### Graded Findings

* **[Pass] Q1 (ENVELOPE):** `runner-envelope.sh` honors a pre-set `XYZ_HARNESS_DB` and returns rc 1 for identity drift and rc 2 for envelope drift. `ci-local.sh` (`ci-local.sh:12163`) and `validate.sh` (`validate.sh:14658`) both capture these and correctly record the failures without silently swallowing drift (added to `FAILED` array).
* **[Pass] Q2 (TELEMETRY):** Pool-worker shard writes use `RT_SHARD=1` for per-worker isolation (`test/lib/runner-telemetry.sh:75`). `rt_merge_shards` uses a Python script that counts malformed records rather than dropping them, and `run.summary` lane filters safely in `validate.sh:14695-14697`. `skip_lines` uses `grep -c` correctly.
* **[Pass] Q3 (LANE REGISTRY):** `gh365-driver-lane-registry.sh` cleanly recognizes both invocation shapes (the bash wrapper and direct `python3`). Spot-checked exemptions align accurately with their source lines.
* **[Pass] Q4 (PDDA SCANNER):** The Python scanner in `pdda.sh:13902` gracefully falls back to the legacy per-line path on failure (`pdda.sh:13905-13911`), ensuring findings are never silently modified. `PDDA_TIMINGS` is strictly opt-in (`[ "${PDDA_TIMINGS:-0}" = "1" ]`, `pdda.sh:13340`) and prints exclusively to stderr.
* **[Pass] Q5 (SHELLCHECK):** The parallel scan in `ci-local.sh:12107` correctly runs one process per file (`xargs -0 -P 4 -n 1 shellcheck -S error`), ensuring verdict equivalence. The two-tee pipe fix (`tee -a "$GATE_SUITE_LOG" | tee "$_one"`, `ci-local.sh:12131`) correctly handles BSD tee's option-permutation bug.
* **[Pass] Q6 (TIERS):** `test/gh365-tier-fail-closed.sh:50` effectively sweeps all tracked files via `git ls-files`. The family detector (`test/gh365-tier-fail-closed.sh:65-74`) CAN be defeated by a plausible new suite name (e.g. `gh999-hq-integration.sh`), but this is safe because it correctly causes the suite to fall through to an empty `family_of` match and safely fail CLOSED to Tier 3.
* **[Pass] Q7 (CONTRACT WEAKENING):** No contracts were weakened explicitly or by accident. Containment is strengthened by sharing the `runner_envelope_assert` logic. Production timeouts and the full-sequential-macOS promotion boundaries (`ci.yml`) are left completely intact.

**Verdict:** Approved

relay closed (Approved), no further turn needed

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
