# RELAY · QA: release-tags backfill plan for #452 (plan comment by claude-a)
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-09-05.
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
6. **Commit only the relay file** (`relay(gh452-release-tags-plan-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **.relay-artifacts/xyz-452-plan-comment.md** — the read-only path that
  `relay-drive.sh --artifact-file /Users/noelsaw/Documents/GH Repos/XYZ-forge/temp/xyz-452-plan-comment.md` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: commandcode   ·   Producer: claude-a
- Started: 2026-09-05
- Definition of Done: the plan comment is **executable as written** — every repo-fact claim it
  rests on is true of this repo, its decisions are internally consistent, and its execution order
  is safe. Answer these numbered questions explicitly, each with a citation (file:line, command
  output, or a quoted span of the artifact):

  1. **Ground-truth check (verify in this worktree, don't trust the plan):** (a) does
     `utils/py/releases_app.py` `update` really expose `--gh-release-url`, and is there any
     existing tag/SHA column in `releases.sql`? (b) does `githooks/pre-push` really have NO
     `refs/tags` handling today? (c) `git tag --list` — exactly the two archival tags named?
     (d) do the four candidate SHAs (136eafbc, cd0f5bdb, 713ba6d1, 17b18b84) exist with the
     commit dates the plan claims?
  2. **Decision soundness:** decision 3 reuses `gh_release_url` instead of a tag-SHA column,
     while the vendor-stamping follow-up arc consumes the tag convention. Is that consistent, or
     does the vendor arc silently depend on a schema change the plan deferred?
  3. **Reachability:** is the "0.1.0–0.3.0 have no identifiable landing commit" claim correctly
     derived (check `git log` dates on the two archival refs), and is skipping them consistent
     with the issue body's "otherwise start from the next release"?
  4. **Hook carve-out safety (Phase A step 2):** all-annotated-`v*`-tags + targets already on the
     remote ⇒ skip the suite. Is this genuinely fail-closed, or is there a bypass (lightweight
     tag, non-`v` name, tag pointing at a commit pushed to a side branch without ever being
     gated)?
  5. **Execution order:** are the 8 steps correctly ordered and complete — e.g. is anything
     missing around the `PAGES/` status copy, `provenance.jsonl` evidence for the gate-claim
     runs, or post-merge reconcile duties in AGENTS.md?
  6. **Acceptance criteria:** can each criterion actually fail when it should ("a check that
     cannot fail is not a check")? Name any that are decorative as written.

  Verdict: **Approved** | **Changes requested** | **Blocked**, plus the mandatory `swept file:`
  line. Cite; uncited `[Pass]` findings get downgraded.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
