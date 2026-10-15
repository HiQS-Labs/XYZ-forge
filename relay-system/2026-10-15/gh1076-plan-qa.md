# RELAY · GH1076 end-to-end implementation plan QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-15.
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
6. **Commit only the relay file** (`relay(gh1076-end-to-end-implementation-plan-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup

Operational envelope: one XYZ Forge developer-tooling policy change in an operator-owned isolated full clone. Full issue1076 is requested end-to-end; no coverage weakening without sufficient evidence, no new individual CI assertion/case/parametrization without Noel approval, no merge/protection/deployment/install/activation. Actual Agy+Claude advisory consult runs separately; this is the required independent Codex plan review, normal3-round cap. Source basef974fcee, plan source3ccbb4e1. Read the complete plan plus existing router/selector/receipt contracts and relevant existing tests. Do not run suites in a linked review worktree. The earlier spike is issue1076 comment6186021918; the plan incorporates its source findings.

Questions:
1. Does the plan meet authorized whole-issue scope without falsely claiming unproved Medium coverage or unsafe batch readiness? Identify exact prerequisite ownership/decision boundaries.
2. Is additive versioned hosted decision output plus existing wave consumer full fallback the smallest safe consolidation? Preserve historical receipt replay, fixed commands, non-shell stages and exact-main full.
3. Is widening known markdown package input to its existing publication consumer area grounded and minimally sufficient? No new framework or CI cases.
4. Are matched before/after full-suite measurements, identity bracketing, host serialization, failure/skips/retries attribution and natural-hosted-only comparisons sufficient and honest?
5. Are intake/ratings, dependency/rollback plan and existing-check/red-control verification commensurate? Do not demand speculative framework or tests. Any behavior-change finding needs concrete observed input, affected scope and falsifier; blockers need observed failure.

- Artifact under review: **.relay-artifacts/GH-1076-CI-POLICY.md** — the read-only path that
  `relay-drive.sh --artifact-file PROJECT/1-INBOX/GH-1076-CI-POLICY.md` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: codex   ·   Producer: codex-producer
- Started: 2026-10-15
- Definition of Done: _<fill in the acceptance criteria the Reviewer grades against>_

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer · Round 1

VERDICT: PARKED
Basis: Required seeded review input is absent. This is an input-delivery finding, not a rejection or approval of the implementation plan.
swept file: no

- [Blocker] Setup names `.relay-artifacts/GH-1076-CI-POLICY.md` and explicitly directs the reviewer to read the seeded artifact there. That file does not exist in this review worktree. The complete canonical `PROJECT/1-INBOX/GH-1076-CI-POLICY.md` was readable, but its presence does not establish that it is the intended immutable seed at plan source `3ccbb4e1`. Concrete fix: have the Producer/harness seed the named artifact from the intended plan revision, then return for whole-file review; do not substitute an unverified artifact identity.
  Observed input: `.relay-artifacts/GH-1076-CI-POLICY.md` is absent; `.relay-artifacts/` contains only `gh182-claim-guards.md`.
  Affected scope: this relay's required plan input and the resulting approval, not router/selector behavior.
  Falsifier: the named seeded file exists, is nonempty, and is attributable to the intended plan revision; expected result is a readable complete plan suitable for the requested source-contract review.
  Probe: `python3 -B -c 'from pathlib import Path; p=Path(".relay-artifacts/GH-1076-CI-POLICY.md"); print("seeded_artifact_exists=" + str(p.is_file())); q=Path("PROJECT/1-INBOX/GH-1076-CI-POLICY.md"); print("canonical_plan_exists=" + str(q.is_file())); raise SystemExit(0 if p.is_file() else 2)'` → exit **2**, decisive output: `seeded_artifact_exists=False`, `canonical_plan_exists=True`. Initial `cat .relay-artifacts/GH-1076-CI-POLICY.md` also returned `No such file or directory`.
- [Unverified — needs clone run] No suites, executable fixtures, or mutation probes ran. No conclusion about Medium coverage, batch readiness, receipt compatibility, performance, or pre-existing source defects is established by this turn. The requested whole-file/source-contract sweep remains outstanding.

Handing off to Producer (codex-producer) — restore the intended seeded review input, then return the relay to Reviewer. No artifact/source edits or git commands were performed by this reviewer.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
