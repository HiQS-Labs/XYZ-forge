# RELAY · GH-399 + GH-400 acceptance fidelity QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-08-03.
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
6. **Commit only the relay file** (`relay(gh399-400-acceptance-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **gh399-400-review-brief.md** (embedded below — read it here).
- Reviewer: agy   ·   Producer: claude-a
- Started: 2026-08-03

### Artifact — gh399-400-review-brief.md
````
# QA review request — GH-399 + GH-400 (acceptance-criteria fidelity)

You are reviewing a **committed** change on branch `gh-399-packet-acceptance-continuation`.
Read the files on disk. Do **not** edit them — report findings in your review block.

## What the change is for

Two defects in one chain. The chain is:

```
GitHub issue  →  /10days writes a capture doc  →  swarm-preflight inlines it into a packet
              →  relay file  →  builder + reviewer
```

Neither the builder nor the reviewer ever sees the GitHub issue. So any damage done in either
translation step becomes the contract, and nothing downstream can detect it.

- **GH-400** — the capture doc *restated* the issue's acceptance criteria instead of copying them.
  Measured: `rebalance-OS` #202 required a malformed row be *"proven to be either reconciled or
  surfaced, never silently dropped"*; the generated doc required asserting *"the actual current
  behavior (drop the row)"*; the delivered test is named `malformed_source_row_is_dropped`. Two
  marathon runs produced it. All gates green.
- **GH-399** — preflight then inlined that checklist with a match that kept only each bullet's
  **first line**, so every hard-wrapped criterion reached the builder as a half-sentence. 10 of 10
  lanes affected.

## Files to review

| File | What to check |
|---|---|
| `utils/py/swarm_preflight.py` | the whole GH-400/GH-399 block: `extract_acceptance_criteria`, `extract_declared_deviations`, `check_acceptance_fidelity`, `collect_inline_checklist`, `render_inline_checklist`, `verify_inlined_acceptance`, and how they gate `ready`/`ready_next` in `main()` |
| `test/gh400-acceptance-fidelity.sh` | 21 cases |
| `test/gh399-packet-acceptance-continuation.sh` | 14 cases |
| `skills/10days/SKILL.md` | §4 (copy-verbatim contract, deviations format) and §6 (what an acceptance-drift exit 5 means) |
| `PROJECT/2-WORKING/GH-400-*.md`, `PROJECT/2-WORKING/GH-399-*.md` | the capture docs, including GH-399's declared deviation |

**Review the whole file, not just the diff** — pre-existing defects in a file being touched are in
scope. Declare `swept file: yes` or `swept file: no` in your block.

## Questions I specifically want attacked

1. **Can the gate be dodged?** The rule is: unexplained divergence between a capture doc's
   `## Acceptance` block and its issue's ⇒ NOT-READY, exit 5, no packet. Find a doc shape that
   diverges in substance but still reads `match` — heading variants, checkbox state, nested or
   indented bullets, an empty section, a second `## Acceptance` heading, HTML comments, unicode
   look-alikes, a `gh_issue` pointing at a different repo's issue number.
2. **Can it cry wolf?** The opposite failure is worse in practice: a gate that flags a *faithful*
   copy gets switched off. `normalize_criterion` collapses whitespace only. Is there a legitimate
   copy that now fails? Consider trailing whitespace, tabs vs spaces, CRLF, a criterion containing a
   fenced code block or a table, a bullet using `*` instead of `-`, smart quotes from the GitHub UI.
3. **Is the deviations mechanism sound?** Format is
   `- [dropped|changed|added] <text> — reason: <why>`, entries must reconcile the two lists exactly,
   and a deviation declared when the lists already agree is itself rejected. Can a rubber stamp get
   through? Can a legitimate deviation be impossible to express?
4. **The `unknown` path.** No `gh`, unauthenticated, offline, or an issue with no `## Acceptance`
   section all report `unknown` and do **not** block. Is that the right call, and is it possible for
   a genuine divergence to be misreported as `unknown`? Note `fetch_issue_body` swallows every
   exception — is any of that swallowing hiding a real signal?
5. **GH-399's scope deviation.** The issue asks for extraction bounded *unconditionally* to
   `## Acceptance`. I narrowed it: bounded where the section exists, whole-document fallback
   otherwise, because 32 of this repo's 33 active capture docs have no such section and would have
   had their definition of done emptied. The deviation is declared in the capture doc. Is the
   reasoning sound, and is the fallback disclosed clearly enough in the packet?
6. **Do the tests actually distinguish bug from fix?** This repo has five documented cases of an
   assertion that passed against both. Both suites were observed failing pre-fix (gh400: 1/19,
   gh399: 2/12). Is any individual case unfalsifiable — would it pass against the old code?
7. **The 25-item cap** now appends a notice. Can the notice itself be confused for a criterion when
   the packet is re-parsed by `verify_inlined_acceptance`?

## Verdict

End with `**Verdict:** Approved` or `**Verdict:** Changes requested`, and rank findings
Blocker / Should / Nit. Be adversarial — the point of this review is to find what I missed, not to
confirm the work.
````
- Definition of Done: _<fill in the acceptance criteria the Reviewer grades against>_

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
