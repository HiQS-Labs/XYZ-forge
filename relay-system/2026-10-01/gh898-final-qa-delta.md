# RELAY · GH-898 final QA delta — ratchet marker
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-01.
-->

NEXT: Reviewer
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
6. **Commit only the relay file** (`relay(gh898-final-qa-delta): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: The delta since your approval (final QA round 3, reviewed-head 2a5cac92): `git diff 2a5cac92..HEAD`. Code change is ONE line: utils/py/board_sync.py:148 gains the comment `# SQLITE-GATEWAY-OK: read-only rebalanceOS DB, not harness state (GH-898)`. Also: the plan's "Ratchet exception record" (PROJECT/2-WORKING/GH-898-BOARD-SYNC-ACTIVE-REPOS.md), CHANGELOG.md entry, evidence under TESTS-RESULTS/2026-09-30+GH-898/marker/ (provenance.jsonl, logs, red gate log) and SUMMARY.md. Prior QA: relay-system/2026-09-30/gh898-final-qa.md. Scanner under discussion: utils/pdda/check_inventory_ratchet.py (line 79 exemption; shrink-only logic; --update-baseline refusal).
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-10-01
- Definition of Done: The marker line is the smallest correct way to satisfy the repo's SQLite ratchet for one justified read-only read of a foreign DB; no gate/baseline edit, no new module; evidence substantiates the claim; nothing else changed.

**Operational envelope:** local single-operator developer CLI; one-line code delta. Grade against commensurate complexity; do not ask for new suites, gate machinery or alternative architectures already weighed (new module + CANONICAL_GATEWAYS edit, subprocess into rebalanceOS, HQ, Flightdeck, `gh` listing, git-pulse files were rejected in the plan's exception record with recon). Per the measure-read-only rule you may run narrow non-mutating probes under .relay-scratch/ or $TMPDIR; you may NOT run validate.sh/test/*.sh/pytest. Behavior-change requests need Observed input / Affected scope / Falsifier.

**Questions (cite file:line):**
1. Does the marker at board_sync.py:148 exempt exactly the intended connect and nothing else? Is the OTHER sqlite3.connect in board_sync.py (baselined, ~:511) still counted, and can the exemption shield any other line (e.g. via the substring match at check_inventory_ratchet.py:79)?
2. Is the exemption legitimate and durable enough: is the marker a deliberate scanner feature (code evidence), what happens if it is later removed, and is that risk disclosed accurately in the plan's record?
3. Is the plan record's account of the red gate accurate — the 12 harness-discovery suites failing on base due to inherited XYZ_HARNESS, and gh777 failing because of this change — as substantiated by marker/provenance.jsonl and marker/gate-red-before-marker.log?
4. Is the CHANGELOG wording accurate and not overclaiming (the full pre-push gate has NOT yet passed on this commit; it is re-run once on the final commit)?
5. Is anything in the delta over-built or unrelated scope?

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
