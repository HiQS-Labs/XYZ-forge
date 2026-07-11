# RELAY · GH-197 spike review — two-axis diagnostic soundness check
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-07-10.
-->

NEXT: Producer
STATUS: Open
ROUND: 1 / 4

## ▶ TAKE YOUR TURN — read this first (works for ANY agent: Claude, Codex, agy)
1. **Read this whole file** (header, Setup, Ground rules, every block in the Log).
2. **Check it's your turn:** `NEXT` (top) names the role to act. Confirm you are bound to it and the
   last Log block isn't already yours. If not → STOP and reply "wrong window — nudge the <other> window."
3. **Do your role's work** on the artifact named in Setup:
   - **Reviewer:** review vs the Definition of Done → graded findings
     (`[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`), each with a concrete fix → set a **Verdict**
     (Approved | Changes requested | Blocked). Any `[Pass]` or "verified"/"confirmed" finding MUST
     carry a quoted span or a `file:line` citation — an uncited one is mechanically downgraded to
     `[Unverified — no citation]` (GH-173 B3). Do **not** edit the artifact; only append findings here.
   - **Producer:** log a disposition for every open finding (Implemented / Modified / Declined + why),
     make the change, then add new work.
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(gh-197-spike-review): <role> r<N>`); no push. **Stop** and report one line.

## Setup
- Artifact under review: **.relay-artifacts/GH-197-AGENTS-MD-TWO-AXIS-SPIKE.md** — the read-only path that
  `relay-drive.sh --artifact-file PROJECT/1-INBOX/GH-197-AGENTS-MD-TWO-AXIS-SPIKE.md` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-07-10
- Definition of Done: this is a doc-only spike (no code/tests) — "sound" means the claims are
  actually grounded in the real files, not fabricated or overreaching. Read
  `.relay-artifacts/GH-197-AGENTS-MD-TWO-AXIS-SPIKE.md` (the spike doc), then read
  `AGENTS.md` and `ROUTER.md` directly from the worktree (normal repo paths, not artifacts) and grade
  each of these five checks as a finding:
  1. Is the per-rule tagging in the Phase 0 table (disclosure/steering/both for each of AGENTS.md's
     8 Operating Principles) defensible against AGENTS.md's actual text, or is any tag a stretch/
     mislabeled?
  2. Is the "predicted skew did not hold" verdict and the disclosure-vs-steering count arithmetic
     (6 steering-leaning vs. 4 disclosure-leaning, out of 8 principles) correct?
  3. Is the "ROUTER.md owns disclosure / AGENTS.md owns steering" explanation actually grounded in
     ROUTER.md's real content (cite `file:line`), or asserted without checking?
  4. Is the "the source doc says eleven rules but AGENTS.md currently has 8" claim correct — verify
     by reading AGENTS.md directly, don't trust the spike doc's count.
  5. Any finding in the spike doc that is ungrounded, overclaimed, or where the verdict overreaches
     the evidence actually in AGENTS.md/ROUTER.md?

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer (codex) - Round 1

**Verdict:** Changes requested

VERDICT: FAIL
Basis: Reviewed `.relay-artifacts/GH-197-AGENTS-MD-TWO-AXIS-SPIKE.md` against `AGENTS.md:11-17,21-59` and `ROUTER.md:17-36,66-80`. The tag table and arithmetic are defensible, but the file-level split and "no further work needed" conclusions overreach those sources.

#### Findings:

1. **Check 1 — per-rule tagging:** `[Pass]` The Phase 0 table is broadly defensible against `AGENTS.md:21-59`. The strongest tags are grounded directly in the text: #2 says "before you commit to a path" (`AGENTS.md:25-28`), #3 requires "explicit confirmation before proceeding" (`AGENTS.md:30-34`), #5 says to keep "verification inline" (`AGENTS.md:41-44`), and #8 suppresses extra ceremony on "small and reversible" edits (`AGENTS.md:56-59`). Fix: none; keep the table, but don't use it to claim stronger file-wide purity than the row-level evidence supports.
2. **Check 2 — skew verdict arithmetic:** `[Pass]` The arithmetic in the spike doc is correct for the table as written: disclosure-leaning = 4, steering-leaning = 6, both = 3, neither = 1 (`.relay-artifacts/GH-197-AGENTS-MD-TWO-AXIS-SPIKE.md:89-94`). On that count, "the predicted disclosure-heavy skew did not hold" is a supported verdict. Fix: none.
3. **Check 3 — `ROUTER.md` owns disclosure / `AGENTS.md` owns steering:** `[Should]` This explanation is directionally right but overstated. `ROUTER.md` is not just disclosure; it also imposes steering-like gates such as "Before reporting success ... run `./validate.sh`" and "`utils/pdda/pdda.sh run`" plus "Do not report a win you did not verify" (`ROUTER.md:23-25,29-36`). `AGENTS.md` is not just steering either; it includes disclosure/startup routing at the top ("Read `ROUTER.md` first...", "Read `GUIDING-PRINCIPLES.md`...", "Read `PROJECT/PDDA.md` when...") plus ownership rails (`AGENTS.md:3-9,63-69`). Fix: rewrite the conclusion as "ROUTER leans disclosure and AGENTS leans steering" rather than a strict file-level split.
4. **Check 4 — "eleven rules" vs current AGENTS count:** `[Pass]` The current-file count is correct. `AGENTS.md` has 8 numbered Operating Principles, beginning at `AGENTS.md:21,25,30,36,41,46,51,56`, so the spike doc is right to say the present file is 8, not 11 (`.relay-artifacts/GH-197-AGENTS-MD-TWO-AXIS-SPIKE.md:70-74`). Fix: none on the current-count claim.
5. **Check 5 — overclaim / evidence stretch:** `[Should]` Two later conclusions outrun the AGENTS/ROUTER evidence. First, "`AGENTS.md`'s Operating Principles are near-purely steering ... every one of them fires while or after acting, not before..." is contradicted by the source itself: #2 is "before you commit to a path," #3 says "before proceeding," and #4 says "Before a refactor..." (`AGENTS.md:25-39`). Second, "No further work needed on this doc" and "the repo already runs the pydantic two-axis split" (`.relay-artifacts/GH-197-AGENTS-MD-TWO-AXIS-SPIKE.md:48,111-115`) go beyond what a read of only `AGENTS.md` and `ROUTER.md` proves. Fix: narrow the verdict to the demonstrated scope: the 8-principle table is not disclosure-heavy, and `ROUTER.md` adds disclosure-oriented routing context; repo-wide sufficiency and "no further work needed" remain unproven by this spike.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
