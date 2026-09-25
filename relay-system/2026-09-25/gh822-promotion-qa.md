# RELAY · GH-822 promotion QA — development to main and 0.9.0 Cargo release
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-09-25.
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
6. **Commit only the relay file** (`relay(gh-822-promotion-qa-development-to-main-and-0-9-0-cargo-release): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- **What is being decided:** whether `development` is ready to be promoted to `main` and released as the first GitHub
  Release, `0.9.0` "Cargo". This is the GH-784 promotion QA receipt that `AGENTS.md:302` requires before a promotion
  sign-off: an independent review, not the orchestrator reading its own green suites.
- Artifacts under review (branch `chore/gh822-promotion-prep`, base `origin/development` @ `a2de2359`):
  - `PROJECT/2-WORKING/GH-822-PROMOTION.md` — scope, Cargo trim, promotion steps, rollback, rating
  - `.relay-artifacts/gh822-issue-export.md` — read-only export of issue #822 (the review, its checklist, the Gemini
    review and its dispositions, the gate-result comment)
  - Evidence in the tree:
    - `TESTS-RESULTS/2026-09-25+GH-591/wave-61f09827*/provenance.jsonl` and `wave-6f956294*/provenance.jsonl`:
      hosted macOS `validate.sh --sequential` qualification receipts
    - `TESTS-RESULTS/2026-09-25+GH-823/`: the #824 push gate, and the `ci-local.sh` gate record for `9ab269c8`
    - `PROJECT/3-COMPLETED/GH-823-BOUNDARY-TIMEOUT.md` and `relay-system/2026-09-25/gh823-final-qa.md`: the blocker
      fix and its approved QA
  - Ledger: read with `python3 utils/py/releases_app.py show --gid rel-01M0GKP4YGTHVTXHVV5WAP08B5` (read-only; do not
    write). The trim described in the plan doc has **not** been applied yet; you are reviewing the plan for it.
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-09-25
- **Operational envelope:** single-maintainer, macOS-first developer toolkit; public repo; `development` is the default
  branch and nothing in the repo consumes this repo's `main`. Grade promotion readiness and the plan's safety. Do **not**
  re-review the 1,799 commits line by line. Their evidence is the per-landing hosted qualification (GH-591) plus the
  `boundary-macos` run that the promotion itself triggers. Do not ask for new tooling.
- **Definition of Done:**
  1. #822's blocking items are resolved with cited evidence, or the plan explicitly keeps them as gates: #823 merged and
     reconciled; a green local qualifying run; this receipt.
  2. The promotion mechanics are correct and reversible as stated: `main` is a strict ancestor, so the push is a
     fast-forward; the protection toggle is restored; the Release is published only after `MACOS-BOUNDARY: green` for
     the exact SHA; there is no force push.
  3. The Cargo trim is justified: #663 shipped with evidence `4481ab48`; five open items moved to 0.6.0 by `releases next`
     order; the exit criterion is backed by the six named suites passing in the `9ab269c8` gate record.
  4. Nothing known should block the promotion, or it is named as a gate.
- **Questions:**
  1. Is `main` (`29144118`) an ancestor of `development`, so the planned push is a pure fast-forward? Check with
     `git merge-base --is-ancestor 29144118 HEAD` if `git` is readable in your worktree; otherwise say you could not.
  2. Do the hosted qualification receipts (`wave-61f09827*`, `wave-6f956294*`) show `result: pass` with `rc: 0` for
     `validate.sh --sequential`, and do they cover the #795, #765 and #824 landings?
  3. Is the protection sequence in the plan's "Promotion steps" safe? Is `enforce_admins` the right switch, and is anything
     else (required reviews, deletions) left relaxed? Does the plan keep the release strictly after the green boundary?
  4. Cargo trim: is `shipped` for #663 supported by `4481ab48`'s subject? Are `cut` plus `dial-in` into 0.6.0 the right
     verbs for the five open items (see `releases manifest --help`)? Do the six named suites plausibly cover the exit
     criterion text?
  5. Is anything in #822's findings (the ubuntu canary, gh153, gh544, the undeployed `start-marathon`, #796 still open,
     the hygiene gaps) a reason to block this promotion rather than follow up after it? Say which, with a falsifier.
  6. Is the plan over- or under-built for a first promotion in 5.5 weeks?
- Reply with graded findings citing `file:line` or quoted spans, a `swept file: yes|no` line, and a VERDICT. Set
  `STATUS: Approved` if promotion may proceed as planned.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer · Round 1 · codex

swept file: yes

Read the entire seeded issue export (including Gemini review and dispositions) and the entire GH-822 promotion plan. Reviewed the supporting receipts, workflow boundary, ledger readout, and relevant suite assertions. No additional pre-existing blocking defect found in the reviewed artifacts. This is approval of the promotion **plan**, not attestation that promotion or publication has happened.

- [Pass] **#823 and local qualification evidence are sufficient for the stated prerequisites.** `.github/workflows/ci.yml:158` now sets `timeout-minutes: 120`; `PROJECT/2-WORKING/GH-822-PROMOTION.md:25` records merge `61f09827` and reconcile `a2de2359`. The two `TESTS-RESULTS/2026-09-25+GH-591/wave-{61f09827edcb48bd88c4d67595af2333dca06086,6f956294ff05b66eaf0c79ea886a6ce5c64724c3}/provenance.jsonl:1` receipts each quote `"gate": "validate.sh --sequential"`, `"rc": 0`, `"result": "pass"`, and 422/422; their PR fields are 824 and 765 respectively. #795 coverage is inherited through the landing order documented in the export’s “What landed” table, not a separate ancestry measurement here. Probe: `python3` with `json.loads`, `Path.read_bytes`, and `hashlib.sha256` over each receipt’s `telemetry` path; exit 0; decisive output: `61f09827 bytes 130026 sha256_matches True result pass rc 0 passed 422 total 422` and `6f956294 bytes 130049 sha256_matches True result pass rc 0 passed 422 total 422`. The nonempty telemetry matches both committed digests. `TESTS-RESULTS/2026-09-25+GH-823/provenance.jsonl:4` records the baseline sequential qualifying run; its gate record quotes `result: green` and correctly labels it self-reported.
- [Pass] **Promotion ordering and scope are appropriate.** Plan lines 53–60 freeze the chosen SHA through the boundary, use a non-force push, restore `enforce_admins: true`, require `MACOS-BOUNDARY: green P`, and publish only afterward. The workflow’s “Promotion evidence” step binds its green line to `GITHUB_SHA` and job success. The narrow admin-enforcement endpoint is the right classic-protection switch: the plan does not delete the protection rule, required-review settings, or deletion settings. See [GitHub’s endpoint contract](https://docs.github.com/en/rest/branches/branch-protection#delete-admin-branch-protection). Execute restoration even if the push fails; do not advance until the plan’s restoration postcondition is observed. This is a small operator procedure, not a reason to add tooling. Plan lines 62–65 correctly price the branch change as Costly and specify fix-forward recovery; tag deletion cannot undo copies consumers already fetched.
- [Pass] **Cargo trim matches the ledger and existing verbs.** Probes `python3 utils/py/releases_app.py show --gid rel-01M0GKP4YGTHVTXHVV5WAP08B5`, `python3 utils/py/releases_app.py next`, and `python3 utils/py/releases_app.py manifest --help` completed successfully (combined shell exit 0). Decisive output: `Manifest: 36 item(s)`, exactly #342/#255/#256/#275/#345/#663 still `dialed_in`; `NEXT: 0.9.0 Cargo` then `0.6.0 Front-Door ... target=2026-09-26`; `cut ... REQUIRES --reason`, `dial-in ... one release at a time`, and `ship ... REQUIRES --evidence`. Thus cut-then-dial-in preserves the handoff trail, and Front-Door is next **after Cargo**, not the current next release. `PROJECT/3-COMPLETED/GH-663-QA-FINDINGS-AGY-RELAY-REVIEW-ON-THE-GH-654-658-659-660-HOTFI.md:33` independently records the full `4481ab48…` landing and closure. The trim remains proposed, as Setup explicitly says; the plan’s past-tense “recorded shipped” must not be mistaken for applied ledger state.
- [Pass] **The six suites plausibly cover the exit criterion.** `TESTS-RESULTS/2026-09-25+GH-823/baseline-9ab269c8-ci-local-gate-record.txt:263,276,405,406,409,411` each record `pass` for the named suites. `test/gh105-vendor-releases-addon.sh` checks payload presence, actual sync materialization and unchanged target-ledger hashes; `test/gh103-timeline-exporter.sh:196` exercises preview generation; `test/gh349-releases-roadmap-vendored.sh:48` binds the vendored CLI to the target root; the tier/preservation suites cover opt-in payload and surviving runtime state. This is supporting component coverage, not a newly executed end-to-end demonstration.
- [Pass] **The export’s remaining findings are follow-ups within the declared macOS-first envelope.** Its Findings 3–7 identify ubuntu portability/argument-size debt, gh544’s broken-toolchain phrase collision, local skill deployment lag, #796 administrative closeout and hygiene gaps. None establishes a failure of the proposed Cargo release on its supported platform; the local record includes `gh544-parallel-default.sh pass`. Falsifiers: the argument/toolchain defects occurring on the selected supported macOS environment, #796 revealing omitted required code or unresolved integration failures, or Cargo requiring the undeployed global skill would change this disposition. A red exact-SHA macOS boundary already stops publication. Preserve these follow-ups rather than expand this promotion into their repair.
- [Unverified — network unavailable / Git prohibited] **Live ancestry, protection state and commit subject were not independently established.** No Git command was run, per the turn restriction. Read-only probes `gh api repos/HiQS-Labs/XYZ-forge/commits/4481ab48 --jq .commit.message`, `gh api repos/HiQS-Labs/XYZ-forge/branches/main/protection --jq ...`, and `gh api repos/HiQS-Labs/XYZ-forge/compare/29144118...61f09827 --jq ...` each printed `error connecting to api.github.com` (combined exit 1). Therefore the export’s strict-ancestor statement and #663 subject remain supplied evidence, not fresh verification. At execution, check ancestry against the actual selected P and observe restored protection; if state differs, stop rather than force. The exact-P hosted boundary is still a future gate, not satisfied by these historical receipts.
- [Nit] **Two wording cleanups can wait for the Producer’s planned update.** Plan line 44 should say “next after Cargo”; line 42 should use future tense until the trim is applied. Neither changes the reviewed plan or its gates.

VERDICT: PASS
Basis: The supplied and committed evidence supports proceeding with the proposed trim and fast-forward promotion procedure. The plan is proportionate for the first promotion in 5.5 weeks: historical landing qualification plus an exact-SHA hosted boundary, with publication withheld until green. Approval does not waive merge/reconcile, applied-trim verification, restored protection, or the final hosted boundary. No suites or executable fixtures were run in this worktree.

Relay closed (Approved), no further turn needed. Producer (claude-a) resumes the planned trim, harness commit, merge/reconcile and gated promotion workflow.


### Attestation · relay-drive — 2026-09-25T18:08:22Z
task: RELAY-gh822-promotion-qa
reviewer: codex
status: Approved
reviewed-head: fe7425fe29dd261bbb9fd85bea3a4d2d08531ea5
added-range: 9192+6868
added-sha256: 7ad4e84f687d74f1ea15b76172797746ab7ccd703f7967c4e0bc026f74daafc6
<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
