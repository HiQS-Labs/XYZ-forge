# RELAY · GH-836 D1 final QA — gh436 to Large, inputs routed full
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-09-26.
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
6. **Commit only the relay file** (`relay(gh836-d1-final-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **.relay-artifacts/gh836-d1-final.diff** — the read-only path that
  `relay-drive.sh --artifact-file /private/tmp/claude-501/-Users-noelsaw-Documents-GitHub-Repos-XYZ-forge/0cc9b6f4-22bd-4606-b4ec-21e1b8f38591/scratchpad/gh836-d1-final.diff` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-09-26
- Definition of Done: **Approved** when all of these hold:
  - (a) the implementation matches the approved D1 plan (`relay-system/2026-09-26/gh836-d1-plan-review.md`,
    attested at `86b778d2`);
  - (b) every landing that changes something `gh436` reads still runs `gh436` at its hosted reconcile, and
    nothing else's routing changed (the controls hold);
  - (c) `test/ci-route.sh`'s only change keeps its existing Small pin truthful. There is no new suite,
    registry entry or gate machinery;
  - (d) the evidence (V1–V3) substantiates the Results table. V4, the full gate, is honestly marked owed;
  - (e) the docs (ROUTER, CHANGELOG, the plan) describe the behaviour accurately.

## Review packet

**What this is.** The implementation of D1 of #836: `gh436-merge-cleanup.sh` moves from Small to Large, and
`WORKTREE-SAFETY.md` and `skills/*/merge-cleanup/SKILL.md` join `full_required` in `utils/ci-route.sh`. The
artifact `.relay-artifacts/gh836-d1-final.diff` is `git diff 1eef93a3 HEAD`, without the plan-review thread.
Branch `fix/gh836-d1-gh436-large`.

**Operational envelope.** A single-repo local developer harness. The operator has ruled "no new tests". Grade
against the approved plan and commensurate complexity.

**Read:**
- the artifact;
- `utils/ci-route.sh` (the Small list, and the new case in the `full_required` block and its neighbours);
- `test/ci-route.sh` around the Small pin;
- `ROUTER.md` 120-135;
- `PROJECT/2-WORKING/GH-836-GATE-HOTSPOTS.md` → "D1 — `gh436` to Large" and its Results;
- `TESTS-RESULTS/2026-09-26+GH-836/`: `d1-routing-probes.log`, `d1-probes.sh.txt`, `d1-v1-pin-red-green.log`,
  `d1-v3-registry-tier-suites.log`, and the last two `provenance.jsonl` records.

You may run read-only probes: `printf '%s\n' <paths> | bash utils/ci-route.sh push`,
`bash utils/ci-route.sh subsystems small`, and `bash TESTS-RESULTS/2026-09-26+GH-836/d1-probes.sh.txt "$PWD" review`.
Do not run suites.

**Questions** (cite `file:line`): does the case pattern catch every real path, and nothing unintended? Is there
any regression in `route`, `pdda_needed` or CI job selection for other docs? Is anything overclaimed?

Write findings in the Log per the turn rules. Set `STATUS: Approved` only if the Definition of Done is met.

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
Basis: D1 matches the approved plan, preserves hosted coverage through the existing full-required routing, and changes only the existing Small pin. The supplied V1–V3 evidence supports the Results table; V4 remains explicitly owed. Approval is review approval, not full-gate or promotion qualification.
swept file: yes

- [Pass] Implementation scope matches `relay-system/2026-09-26/gh836-d1-plan-review.md` Round 2: `utils/ci-route.sh:38` removes only gh436 from Small, `:333-338` adds the two specified document exceptions, and `test/ci-route.sh:239-246` updates only the existing pin. `validate.sh:619` still registers gh436. No new suite, registry entry or gate machinery appears in the seeded diff.
- [Pass] Coverage and controls: ran the equivalent of `printf '%s\n' <paths> | bash utils/ci-route.sh <event>` through Python subprocess stdin, for both `push` and `pull_request`. Every invocation exited 0 with nonempty output. `WORKTREE-SAFETY.md` and `skills/2-daily/merge-cleanup/SKILL.md`, alone and each paired with README, returned `pdda_needed=true route=full tier=3 tier_reason=kernel/gate surface (route=full)`. README, releases/SKILL.md, merge-cleanup/README.md and docs/WORKTREE-SAFETY.md controls returned `pdda_needed=true route=docs tier=1 tier_reason=docs-only`. The case at `utils/ci-route.sh:336` matches the real reader paths (`test/gh534_phase_a_tests.py:125`, `test/gh534_phase_c_tests.py:523`); full-required wins at `utils/ci-route.sh:459-477`. No unintended routing change found.
- [Pass] Non-doc dependencies retain their routes: the same probes returned releases_app.py and releases-merge-resolve.sh → `route=fast tier=2 pdda_needed=false`; .gitattributes and merge_cleanup.py → `route=fast tier=3 pdda_needed=false`; bin/tick and utils/py/rtl.py → `route=full tier=3 pdda_needed=true` (all rc 0). `utils/py/wave_reconcile.py:589-614` selects the full registry for every non-1 tier. `.github/workflows/ci.yml:480-489` also selects the advisory full canary for the new full routes, as the plan records.
- [Pass] Evidence correspondence: `bash utils/ci-route.sh subsystems small` exited 0 with 72 names and no gh436. Python hashlib over the router returned `9881afe850a20e3da4b51098b4e34e5add9b9a9472c722c93ae86c0a443dc5db`, matching the recorded edited-router prefix. `TESTS-RESULTS/2026-09-26+GH-836/d1-routing-probes.log:1-17` records old/new routing and the two controls; `d1-v1-pin-red-green.log:1-9` records the pin's rc 1 red and rc 0 / 81-pass green; `d1-v3-registry-tier-suites.log:1-2` records 10/0 and 72/0. The final two provenance records identify those artifacts and distinguish manual probes from disposable-clone suite execution. These are supplied execution receipts, not suites rerun by this reviewer.
- [Pass] Swept the full router, its existing test file, the plan and ROUTER beyond the changed hunks, and reviewed the diff's documentation/evidence in context. No actionable pre-existing defect found in that sweep. `ROUTER.md:127-132` names the exceptions, `CHANGELOG.md:6` calls the approximately 12-minute result a projection, and `PROJECT/2-WORKING/GH-836-GATE-HOTSPOTS.md:342-345` matches the supplied evidence and explicitly says V4 is owed.
- [Unverified — needs clone run] The final full gate remains owed at `PROJECT/2-WORKING/GH-836-GATE-HOTSPOTS.md:345`. No suites, executable fixtures or Git commands ran in this turn. Historical change frequency and future hosted timing were not independently measured; neither is claimed as fresh verification here.

Relay closed (Approved), no further review turn needed. Producer (claude-a) should obtain V4 on the final commit in a disposable full clone before treating the change as gate-qualified.


### Attestation · relay-drive — 2026-09-27T00:00:09Z
task: RELAY-gh836-d1-final-qa
reviewer: codex
status: Approved
reviewed-head: 12d7266777d2fca394d232a0ea67ed35157ff546
added-range: 7677+3748
added-sha256: ba720a706015a7e1c23c6ebf54de685c128efb58a8ca7ce148555e0ebf540b46
<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
