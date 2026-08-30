# RELAY · DRY skill QA after sharpening — Policy class, loosened one-rule, audit-the-guards (qwen3.8-max via CommandCode)
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-08-30.
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
6. **Commit only the relay file** (`relay(dry-skill-qa-qwen): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Reviewer: commandcode   ·   Producer: claude-a
- Started: 2026-08-30
- Artifact under review: `skills/dry/SKILL.md` — read it in the repo at that path.
  Read-only for you: do NOT edit it; append findings here only.
- Definition of Done: `dry` is a Claude Code skill that audits a codebase for **subsystem
  duplication** — several pieces doing the same job with no shared owner. It was just **sharpened
  after losing a blind head-to-head**: on the same repo and commit, a manual audit found 9 findings
  and this skill found 3. Three of the misses were design, not budget — the skill's one rule
  excluded them by construction. Five changes were made in response (Policy resource class, loosened
  one rule, an audit-the-guards step, read the repo's rules first, mandatory issue cross-check).

  Grade the CURRENT file. Do not grade the old version, and do not restate the skill back.

  1. **The loosened one rule now reads: "a finding must name a shared *resource* or a shared
     *policy*, never a shared *syntax*."** The old wording ("resource, never shape") suppressed
     text-similarity noise but blinded the skill to constants defined N times with N values. Does
     the new wording now let noise back in? **Name a concrete false positive it admits that the old
     wording correctly rejected.** A generic worry with no worked example is a `[Nit]`.
  2. **The Policy class says to "group by what the constant decides rather than what it is
     called."** Is that an actionable instruction or a wish? If an agent cannot execute it
     mechanically, say what method would replace it — the rival definitions genuinely do not share a
     name, so name-matching is not the answer.
  3. **"Audit the guards" sits inside Step 2 (build the index).** Is that the right place, or should
     it be its own step? It is the technique that produced the skill's only unique win in the
     head-to-head, so burying it is a real risk.
  4. **Self-consistency.** Five edits landed on an existing document. Quote any place where new text
     contradicts surviving old text, or where the same instruction now appears twice.
  5. **Has it bloated?** The skill preaches minimalism. It is now 201 lines. Quote anything that is
     prose rather than instruction and say what replaces or deletes it.
  6. **What is still missing?** The manual audit also found: a vendor client bypassing a shared
     error-body helper, retry/backoff written six times with no jitter, a production script reading
     config from a vendored tree, and `sys.path` surgery enabling cross-tree imports. Would the
     current file catch each of those four? For any it would miss, name the class that is absent.

  Cite `file:line` or a quoted span for every `[Pass]`. Sibling skills for context are in the same
  tree: `skills/recon/SKILL.md`, `skills/triangulate/SKILL.md`, `skills/converge/SKILL.md`,
  `skills/ponytail/SKILL.md`.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
