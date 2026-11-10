# RELAY · GH1400 PR1403 Opus medium QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-11-09.
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
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
   Reviewer headings may be `### Reviewer · Round N`, `### Round N · Reviewer · <agent>`, `### Reviewer (<agent>)` (optionally followed by `— rN`), or `### Reviewer — Round N` (optionally followed by `(<agent>)`); follow the heading with a non-empty review body.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(gh1400-pr1403-opus-medium-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **.relay-artifacts/gh1400-packet.md** — the read-only path that
  `relay-drive.sh --artifact-file temp/opus-qa/gh1400-packet.md` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: claude-opus   ·   Producer: codex-parent
- Started: 2026-11-09
- Definition of Done: _<fill in the acceptance criteria the Reviewer grades against>_

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer · Round 1 (claude-opus)

swept file: yes. I read all of `skills/2-daily/flywheel/SKILL.md` (lines 1-258), the plan doc, SUMMARY.md, provenance.jsonl and integration-repair.json. I checked them against the owner contracts in `skills/2-daily/merge-cleanup/SKILL.md` and `skills/1-hourly/handsfree/SKILL.md`. I ran no git, suites or fixtures. Probes: `shasum -a 256` and `grep`/`sed` only.

- [Pass] Q1 scope and honesty. The change claims only instruction-level guidance. It discloses that #1399, #1401 and the trial are not done. Quoted: SKILL.md:136-137 "Universal push/gate enforcement is proposed in GH-1399; these instructions do not claim that raw edits are mechanically intercepted today". SKILL.md:143-144 "A prose change or green component check does not qualify unattended progression or establish a supervision-cost saving". The plan doc table (lines 65-70) names the dependency still held for each requirement.
- [Pass] Q2 batch pin, moved head and merge authority match merge-cleanup:
  - Approval: SKILL.md:108-109 "neither a ready PR nor a `--prs` pin grants approval" agrees with merge-cleanup/SKILL.md:396-401. There, a request naming PRs authorizes the drive loop, and discovery never adds PRs.
  - Moved head: SKILL.md:114-115 (a moved head needs a new pin and the list is never widened) agrees with merge-cleanup:240 ("may narrow ... never widen") and merge-cleanup:249 (a repaired PR is deferred, then re-dry-run to re-pin).
  - Attempt scopes: SKILL.md:132-134 keeps them separate and matches merge-cleanup:336 ("Two repairs per PR, whatever the head").
  - Landing checkpoint: SKILL.md:113 keeps it, matching merge-cleanup:259-263.
  - QA pending: SKILL.md:139-141 treats landed-but-QA-pending as still open, matching merge-cleanup:427 "exit 4 is never Done".
- [Pass] Q2 waits. SKILL.md:117-128 makes the native watcher the hedged first choice ("for example `watch_pull_request` where the harness provides it"). It falls back to handsfree only after "its capability/readback checks pass" (handsfree/SKILL.md:40,63-69). It allows no duplicate watchers and no shell polling, and it says to state that a wake is unarmed rather than promise one. That last point matches handsfree:67 (unarmed on a failed capability check).
- [Pass] Q3 readiness handoff. SKILL.md:102-103 "A `status:ready-for-pickup` label is neither automatic Jog selection nor execution approval". Pickup-time revalidation stays with the execution owner (SKILL.md:100-101). No new label consumer is added: `grep ready-for-pickup skills/2-daily/jog/SKILL.md` returned no hits.
- [Pass] Q4 evidence integrity. `shasum -a 256 skills/2-daily/flywheel/SKILL.md` gives `df6430db…cded15`, which equals the provenance.jsonl line 1 `sha256`. So the skill bytes at the pinned head are the ones QA checked, which supports plan:117 "no source/skill bytes changed after final QA". SUMMARY.md labels every scenario "PASS (textual)" and sets `runtime_claim: false`, so it overclaims nothing. The rating recurrence counts (plan:79-82) are marked as search hits, not incidents, with the trend unknown. [Unverified — needs live gh] for the actual 20-versus-1 counts. They are honestly hedged and do not affect the decision.
- [Pass] Q5 surgical and DRY. The only production file is the flywheel SKILL. It adds no runner, test, gate or schema, as the plan non-goals state (plan:96-100). The new section points to the owners' contracts instead of restating their mechanics.
- [Nit] Stale status in the plan doc. PROJECT/2-WORKING/GH-1400-SUPERVISION-COMPOSITION.md:23 says the next step is "Publish the reviewed subset PR". But PR1403 is already published, and the same doc's Integration repair section (lines 111-119) records the push. Fix: update the next step to something like "Land PR1403; arc stays open for GH-1399/1401/GH-1386 qualification", either now or during landing reconciliation. Docs only, no behaviour change.
- [Nit] SKILL.md:110-111 says "use merge-cleanup's existing dry run to pin exactly that list". merge-cleanup:239 also accepts self-pinned `N@sha` entries without a dry-run record. The text is still correct, because the dry run is the normal path. No change is required.
- Pre-existing defects in the rest of the swept file (rubrics, ladder, ordered flow, completion contract): none found. Steps 1-7 still route to existing owners and do not contradict the new section.

VERDICT: PASS
Basis: The change is one instruction file that is consistent with merge-cleanup's pinned, never-widened `--prs` contract, its per-PR approval and repair budgets, and its exit-4 QA-pending rule. It is also consistent with handsfree's capability and readback limits. Deferred work (#1399 enforcement, #1401 conveyor, real-work qualification) is stated as deferred, not implemented. The evidence is labelled textual, and the provenance hash matches the head under review. The two findings are non-blocking Nits. STATUS: Approved.


### Attestation · relay-drive — 2026-11-10T05:27:15Z
task: RELAY-gh1400-opus-medium
reviewer: claude-opus
status: Approved
reviewed-head: edd1dccbb21ad7d09a439de65fe7ac1f71b52381
added-range: 5801+4924
added-sha256: 04a2be7e98b028da012505ec5ed310dd1c91349a6e3fe3acca838fa854cb4ea0
<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
