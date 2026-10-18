# RELAY · GH-1157 final QA: skills-army-hq hard rules (implemented diff + evidence)
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-18.
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
6. **Commit only the relay file** (`relay(gh1157-final-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: the committed implementation on this branch — the diff from base
  `9a61625fa7af15e7dd2b12c06a89242ed689b088` to `HEAD`. The only runtime change is
  `skills/3-weekly/skills-army-hq/SKILL.md` (commit `4bf3361b`). Supporting artifacts in the same
  range: `PROJECT/2-WORKING/GH-1157-SKILLS-ARMY-HARD-RULES.md` (the approved plan, promoted),
  `TESTS-RESULTS/2026-10-18+GH-1157/` (evidence + `provenance.jsonl`),
  `relay-system/2026-10-18/gh1157-plan-qa.md` (plan QA, Approved r2), `releases.db`/`releases.sql`
  (ledger row for GH-1157 only).
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-10-18
- Definition of Done: the diff implements the plan's **Asks / acceptance criteria** items 1–8 and
  nothing else in the runtime surface; every factual claim the new prose makes about
  `scripts/intake.py` / `scripts/sync.py` is true at this revision; `name: skills-army-hq` is intact;
  the evidence folder's logs support exactly the claims `SUMMARY.md` makes and `provenance.jsonl`
  covers every artifact with a matching sha256; no new test, suite, registry entry or gate
  machinery (GH-831); no contradiction with the untouched sections of `SKILL.md`.

## Review packet

**Goal.** Final QA of the completed GH-1157 change before the PR is opened against `development`.
Pre-implementation plan QA already Approved the design (round 2, attested); this review grades the
*implementation* and its *evidence* against that plan.

**Operational envelope.** A documentation-only change to one `SKILL.md` of a local developer
toolkit, plus governance/evidence artifacts. Commensurate complexity: do not ask for scripts, hooks,
device configuration or tests; a request for a new test is a finding against the request (GH-831).

**Non-goals (decided, out of scope).** Script changes, Git Pulse Sync hook, device config, publisher
policy (#961), status exit-code semantics (#958), downstream child publication, any device repair.

**Read.** `git diff 9a61625f..HEAD --stat` and the full diff of `skills/3-weekly/skills-army-hq/SKILL.md`;
the plan doc's "Asks / acceptance criteria" (items 1–8); `TESTS-RESULTS/2026-10-18+GH-1157/*`;
the scripts the prose describes.

**Questions — answer each with a grade and a citation:**

1. **Asks → diff.** Map each of the plan's items 1–8 to the diff. Is any item missing, partially
   done, or implemented differently from the approved wording? Is anything in the runtime surface
   outside those items?
2. **Truth of the new prose.** Spot-check the load-bearing claims in the new "Hard rules" and
   "Definition of done": (a) intake applies with no drift gate and app links expose bytes at once;
   (b) status never compares receipt digests with deployed bytes and exit 0 can carry warnings;
   (c) a symlinked root is refused; (d) there is no supported stale-receipt refresh; (e) the
   corrected unrelated-changes sentence (applies, then declines the commit with `WARN not committed`,
   exit 0). Cite `file:line` for each or name the one that is false.
3. **Identity.** Is `name: skills-army-hq` intact and the frontmatter still valid YAML for the
   reader (`package_info`), so the existence/identity/copy-parity checks named in the plan stay
   compatible?
4. **Evidence honesty.** Do `parse-positive.log` (exit 0, 0 `__pycache__`), `parse-red-control.log`
   (exit 1, refusal), `pdda-run.log` (no errors) and `releases-check.log` (clean) say what
   `SUMMARY.md` says they say? Does `provenance.jsonl` have one line per other artifact with a
   sha256 that matches the file bytes at HEAD, and the stated base/candidate SHAs?
5. **GH-831.** Is there any new test file, `validate.sh` TESTS entry, runner, guard or gate
   machinery in the diff? (Expected: none.)
6. **Contradictions / sweep.** Read the whole `SKILL.md` at HEAD (`swept file: yes|no`). Does the
   new block contradict any remaining sentence (GH-672 SOP, drift guard, read-through boundary,
   commands)? Any pre-existing defect still uncorrected that a reader of the new rules would trip on?
7. **PR readiness.** Is the branch ready to push through the docs-route gate and open as a PR
   against `development`, stopping there (no merge)? Name any blocker.

Write graded findings with `file:line` citations, declare `swept file: yes|no`, set a VERDICT and
Basis, and set `STATUS: Approved` if the implementation passes.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
