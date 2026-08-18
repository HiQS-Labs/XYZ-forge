# RELAY · QA rgt spec (pdda upstream)
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-08-17.
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
6. **Commit only the relay file** (`relay(qa-rgt-spec-pdda-upstream): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **.relay-artifacts/rgt-spec-pdda-upstream.md** — the read-only path that
  `relay-drive.sh --artifact-file /Users/noelsaw/Documents/GH Repos/XYZ-forge/temp/rgt-spec-pdda-upstream.md` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-08-17
- Definition of Done: the artifact is a **spec for an upstream PDDA issue** (adding an optional
  `rgt:` frontmatter key + `pdda.sh frontmatter` validation). The Reviewer grades it against:
  1. **Grounded** — every claim about the PDDA codebase is checkable against THIS repo's vendored
     copies (`utils/pdda/pdda.sh` `check_frontmatter()`, `utils/pdda/PDDA-SOURCE.md`,
     `PROJECT/PDDA.md`); flag any anchor that is wrong or unverifiable.
  2. **Complete & consistent** — contract card, validator spec, docs spec, tests, non-goals, and
     acceptance all present, mutually consistent, no undefined terms, no internal contradictions.
  3. **Testable** — each acceptance checkbox is objectively decidable (a command or observation
     settles it), including the negative control.
  4. **Scoped** — no scope creep beyond one optional key + its validation + doc text; non-goals
     fence off inference, LLM rubrics, and validation-scope widening.
  5. **Implementable cold** — an agent that has never seen this conversation could implement it
     from the spec alone.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer — codex — round 1

swept file: yes

- [Should] The complementary-skills paragraph names five upstream skill paths that are absent in this vendored copy (`SKILLS/PDDA-EOD`, `SKILLS/PDDA-STATUS`, and `.claude/skills/{governance-audit,triage,release}`), so the upstream-grounded claim is unverifiable and would fossilize stale paths. Fix: remove the path inventory, or replace it with verified canonical paths; keep the requested general sentence only.
- [Should] The proposed sentence says “the contract guarantees shape, consumers own meaning,” but the contract card itself assigns meanings to `run`, `grow`, and `transform`. Fix: say consumers own their interpretation/use of the declared classification, while the PDDA contract owns the key, enum, and stated meanings.
- [Should] The last acceptance item (“Vendored consumers can pick the change up purely by sync”) is not objectively decidable: it names no sync command, fixture, or observable state, and “no local edits” could mean either no hand-maintained fork or literally no changed vendored files. Fix: define the exact sync/installation observation and state that no consumer-maintained contract patch is required.
- [Pass] The validator’s optional-present-only approach, exact enum, stable check id, and active-doc scope fit the current implementation pattern: `utils/pdda/pdda.sh:82` establishes optional-present-only validation, `utils/pdda/pdda.sh:102` iterates `pdda_list_working_docs`, and `utils/pdda/pdda-lib.sh:240` excludes `blank.md` from that list.
- [Unverified — no citation] The test acceptance explicitly requires the invalid-value rejection as a negative control, not only the valid and absent cases: “with the rejection observed as a negative control — not merely the acceptances.”
- [Unverified — no citation] Full artifact sweep completed; no additional pre-existing defects found beyond the findings above.

Verdict: Changes requested

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
