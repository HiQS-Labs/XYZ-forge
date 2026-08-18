# RELAY · GH-32 RELEASES app PRD review
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-08-18.
-->

NEXT: Reviewer
STATUS: Open
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
6. **Commit only the relay file** (`relay(gh32-releases-app-prd-review): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **PROJECT/1-INBOX/GH-32-RELEASES-APP-SQLITE.md** — the PRD for the SQLite-backed RELEASES app (read it in full; also read GH-28's capture doc PROJECT/1-INBOX/GH-28-RELEASES-LEDGER-DISCIPLINE.md for the predecessor context, and utils/pdda/pdda.sh check_releases() + PROJECT/PDDA.md's "RELEASES.md — release ledger" section for the consumers the PRD claims stay unchanged).
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-08-18
- Definition of Done — grade the PRD against these five questions:
  1. **Schema soundness**: do the tables/constraints actually enforce the two SOPs and the GH-28 thresholds, or are there writable states that bypass them? Is the global_id design (identity-not-hash, additive-only migrations, no EAV) the right corner-avoidance for a future PDDA home?
  2. **Phase 0 transition realism**: is lenient-mode (warn-and-write on legacy debt, refuse new structural corruption) drawn at the right line? Is the 2-week dogfood exit gate meaningful or theater? Does side-by-side generation (RELEASES.generated.md, no overwrite) actually protect the current consumers?
  3. **Consumer-compatibility claim**: the PRD claims pdda.sh releases, ballast-release.sh Half A, and /releases keep working with zero changes because the generator emits the existing block format. Verify against the actual parser (pdda-lib.sh's field parser) — is byte-stable regeneration of the CURRENT file's blocks actually achievable given multi-paragraph Description continuations (Sundown block), or does the round-trip claim need qualification?
  4. **Git story for the committed DB**: does the DB + releases.sql dump + consistency-check design actually survive concurrent sessions committing on one branch (this repo routinely has 2-3 live sessions), or is there a merge/race hole?
  5. **Scope discipline**: anything in v1 that should be cut (YAGNI), anything deferred that v1 secretly depends on?

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
