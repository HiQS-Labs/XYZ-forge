# RELAY · GH805 enforced gateway plan QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-09-24.
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
6. **Commit only the relay file** (`relay(gh805-enforced-gateway-plan-qa): <role> r<N>`); no push. **Stop** and report one line.
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
- Definition of Done: Review the Gateway continuation section of the canonical plan and actual source. Operator chose human approval. Operational envelope: single public GitHub Free repo, no new service; native required operator CODEOWNER reviews are the authority, same-account agent approval prohibited. Ask: does the gateway bind complete changes, reject stale/omitted tests, surface growth, avoid candidate execution, and preserve protected-branch reconciliation? Is bot publishing viable with GitHub event suppression and required checks? Explicitly identify bootstrap/activation limitations, no self-review or pretend enforcement. Keep footprint proportional; no new suite. No test execution in worktree, only read-only source probes. Write only this thread, harness commits. Original template criteria: _<fill in the acceptance criteria the Reviewer grades against>_

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer · Round 1

VERDICT: FAIL
Basis: The gateway is proportionate and its content-binding proposal is sound, but the bot/check event path and last-pusher identity are not specified sufficiently to build a mergeable operator-approval path. These are plan gaps, not claimed live failures.
swept file: yes

- [Should] **R1 — Specify bot-created PR check delivery and activation placement.** Plan lines 64, 71–73 propose a native dispatch publisher and a required `pull_request_target` checker, but never connect them. Current [GitHub token documentation](https://docs.github.com/en/actions/concepts/security/github_token) says token-generated events are suppressed except dispatch and selected `pull_request` events; the latter require workflow-run approval. That exception does not include `pull_request_target`. Existing `.github/workflows/ci.yml:98–104,513–518` also needs its blocking smoke job delivered. Fix: name the publisher credential, trusted dispatch/check path, exact candidate SHA receiving the required status, pending/failure behavior, and separate workflow-run approval from CODEOWNER review. Specify where workflows must land for dispatch availability before protecting development; do not assume landing only on development activates default-branch dispatch. Include bot-created and bot-updated PR acceptance cases for both task and reconciliation publication, without executing candidate code in the privileged checker.
  Observed input: Plan line 71 selects `pull_request_target`; line 64 opens PRs through native Actions. Existing reconciler uses `GH_TOKEN: ${{ github.token }}` (`.github/workflows/wave-reconcile.yml:34–35`). No alternative event/check publication contract is present.
  Affected scope: PR creation/update through `GITHUB_TOKEN`, and activation of the new dispatch workflow.
  Falsifier: A bot-created PR and subsequent bot update each receive the required admission result on their current head SHA and the existing smoke result through the documented path; a stale result cannot satisfy the new head. Live demonstration remains outstanding, not inferred from YAML.
  Probe: `python3` read the nonempty 165-line artifact and enumerated lines containing `workflow_dispatch`, `repository_dispatch`, `last-push`, `pull_request_target`, and `default branch` (exit 0). Decisive output: `workflow_dispatch: []`, `repository_dispatch: []`, `default branch: []`; the only `pull_request_target` occurrence is line 71. This measures the missing plan contract, not GitHub runtime behavior.

- [Should] **R2 — Resolve the last-pusher constraint, not only PR authorship.** Plan line 62 requires last-push approval while line 64 merely opens a bot-authored PR from an existing task branch; line 56 identifies the local API identity as `noelsaw1`. [GitHub branch protection documentation](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches/about-protected-branches#require-pull-request-reviews-before-merging) requires an approver other than the latest reviewable pusher. Changing the PR author alone does not establish that distinction. Fix: specify a bot publication/update path that makes the latest reviewable push belong to a distinct identity, or explicitly choose a compatible review policy retaining stale-approval dismissal. Add a sole-operator approval acceptance case after both initial publication and a revision. Also state that native GitHub review authenticates an account, not a human: agents holding operator review credentials remain prohibited by operating policy unless credentials are separated; the limitation is broader than the current settings-mutation caveat.
  Observed input: Plan lines 56, 62, 64 combine operator API identity, required last-push approval, and bot PR creation from an existing branch without specifying who performs the reviewable push.
  Affected scope: Task branches pushed with the sole CODEOWNER's credentials, including updates after initial review; not bot-pushed reconciliation branches with a distinct pusher.
  Falsifier: A PR on an operator-pushed branch satisfies the exact proposed last-push policy with only that operator's review, or the revised publisher demonstrates a distinct last pusher and successful operator approval without a bypass. Do not count bot authorship alone as this proof.

- [Pass] **Complete-change binding, disclosure and isolation are explicit design requirements.** Plan line 70 binds “complete non-packet changed-file manifest (old/new blob IDs and modes) and merge-base,” covers stale/omitted/renamed/deleted changes, and reports suite delta with unknown case counts. Line 71 prohibits candidate scripts/imports in trusted execution; lines 73, 75 reuse existing suites and require clone evidence. These are plan-level passes, not implementation verification.
- [Pass] **Bootstrap and reconciliation are acknowledged rather than falsely declared active.** Lines 64–66 identify #811 self-review and existing direct-push incompatibility; lines 73, 77 leave activation separate. Source agrees: `utils/py/hosted_lane_publish.py:102–111` directly pushes development, and `.github/workflows/wave-reconcile.yml` explicitly tests `.protected = false`. The protected publication implementation must also specify how its allowlisted lifecycle/receipt changes satisfy the admission packet/docs-only contract; the current publisher allowlist (`utils/py/hosted_lane_publish.py:48–55,79–86`) contains no `.github/test-admission.json`.
- [Unverified — needs clone run] No suite, pytest, fixture, or git command was executed. Full artifact sweep found no additional pre-existing plan defect requiring a separate finding; historical execution claims at lines 159–165 were read as attributed prior evidence, not rerun or independently certified. Live repository policy and approval behavior still require the explicitly deferred activation witness.

Handing off to Producer (astra): disposition R1–R2 and make the event, identity, and bootstrap contracts concrete before implementation; then return for round 2.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
