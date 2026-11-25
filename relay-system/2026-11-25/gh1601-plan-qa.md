# RELAY · GH-1601 plan QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-11-25.
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
     change MUST carry `Observed input:`, `Affected scope:` (the input predicate the change would govern),
     and `Falsifier:` (the fixture or data that would show the change unnecessary or wrong, and its expected
     result). `Observed input:` accepts two strict, non-speculative forms:
     (1) **Form 1 (observed failure or artifact contradiction):** a failing probe/gate output, or a concrete
     `fileA:line` vs `fileB:line` contradiction (e.g. IAM SA mismatch, inverted test, sibling guard omission);
     (2) **Form 2 (unrunnable runtime hazard trace):** permitted ONLY when reproduction requires an external
     service, multi-process concurrency, or a browser/container runtime forbidden in the relay worktree —
     must supply a hop-by-hop `file:line` trace plus an exact `Clone probe:` command/script for the Producer's
     disposable full clone. Default severity for an unexecuted Form 2 hazard is `[Should]`.
     A `[Blocker]` must cite an observed failure (Form 1); an unexecuted Form 2 hazard stays `[Should]`
     until a probe reproduces it, and remains pending probe verification until the Producer runs
     `Clone probe:` in a disposable full clone.
     A finding from an earlier round stays open, and the verdict stays failing, until new evidence closes it.
     This includes earlier [Nit] findings; only a newly raised [Nit] with VERDICT: PASS on STATUS: Approved remains optional.
     This is a protocol rule, not a mechanical check —
     the Producer may disposition a request lacking Form 1 evidence and lacking a complete Form 2 trace + `Clone probe:` as `Declined — unproven generalization`.
   - **Producer:** log a disposition for every open finding (Implemented / Modified / Declined + why,
     including `Declined — unproven generalization` for a behaviour-change request lacking Form 1 evidence and
     lacking a complete Form 2 trace + `Observed input:` / `Affected scope:` / `Falsifier:` / `Clone probe:`).
     For every Form 2 `Clone probe:` finding, read the probe before running it — refuse any probe that reaches
     the network, credentials, or paths outside the disposable clone and record the refusal as
     `[Unverified — clone probe failed/unavailable]` — then execute safe probes in a disposable full clone and
     record one of three outcomes: (a) Reproduced → fix and paste failing-before / passing-after probe output;
     (b) Falsified → `Declined — falsified by clone probe: <cmd → exit + output>`; (c) Errored, refused, or
     environment unavailable → keep the finding OPEN (`[Unverified — clone probe failed/unavailable]`, blocking
     `STATUS: Approved` until re-run cleanly or escalated/parked). Make approved changes, then add new work.
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
   Reviewer headings may be `### Reviewer · Round N`, `### Round N · Reviewer · <agent>`, `### Reviewer (<agent>)` (optionally followed by `— rN`), or `### Reviewer — Round N` (optionally followed by `(<agent>)`); follow the heading with a non-empty review body.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Manual relay: commit only the relay file** (`relay(gh1601-plan-qa): <role> r<N>`); no push.
   **Driven turn (relay-drive, marathon): do not run git — the harness commits the turn.** **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. (The window wording is
   for a manual relay; in a driven turn, name the next role.) The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **.relay-artifacts/GH-1601-YESTERDAY-TODAY-SKILL.md** — the read-only path that
  `relay-drive.sh --artifact-file PROJECT/2-WORKING/GH-1601-YESTERDAY-TODAY-SKILL.md` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-11-25
- Operational envelope: an instruction-only skill (one `SKILL.md`, about 130 lines, no scripts) that an agent follows on one operator's machine to refresh a team's per-day planned-work GitHub issue from the previous day's issue, using `gh` and `git` reads and one body edit. XYZ-forge forbids new tests (`AGENTS.md` "No new tests", GH-831). Grade against the stated requirements and commensurate complexity; do not ask for scripts, a new suite or a new subsystem.
- Operator decisions already made (do not reopen): the skill is a **new named skill** `yesterday-today` in `skills/2-daily/`; it must be a thin layer reusing `daily-planner --mode ledger` by reference where that applies; its validation step uses a low-effort read-only Codex sub-agent given the two issue URLs and a checklist, never the author's conclusions.
- Definition of Done: the plan is grounded in the cited paths, the overlap with `daily-planner` is correctly characterized, each acceptance item would fail on base `ac0e8b65b`, and nothing required by the issue is missing.

### Step A: paraphrase first (GH-1414). Do this BEFORE reading anything else.
Read ONLY the plan doc's frontmatter `non_goals`, `goal`, `## Status`, `## Requirements`, `## Recon`, `## Preflight bet`, `## Plan`, `## Acceptance`, `## Verification` and `## Risks`. Do not open source files or the issue yet. At the top of your review block write:
- **What this proposes** (2-5 sentences)
- **How the existing system works, per this document** (2-5 sentences)
- **What it's not** (short; ground exclusions in the doc's sections, label inference)
- **Input boundary:** the sections you had read when you wrote the paraphrase.

### Step B: source-backed technical validation
Now read the requirements and source, and label this assessment **source-backed**:
- Issue: https://github.com/HiQS-Labs/XYZ-forge/issues/1601
- `skills/2-daily/daily-planner/SKILL.md` (the "Daily Work Ledger" section, lines 128-183)
- `skills/README.md` (the contract, "Mode before skill (GH-1299)"), `ARCHITECTURE.md` Skills Index (`2-daily` table)
- `skills/2-daily/todo-list/SKILL.md` (section 4, the issue-closeout procedure), `skills/2-daily/where-are-we-at/SKILL.md`
- `utils/ci-route.sh` (the docs/full route for `skills/2-daily/<name>/SKILL.md`)

Answer each with `file:line` evidence:

1. Are the Recon claims about `daily-planner --mode ledger` true at the cited lines? In particular: does it already rewrite a ledger issue body or verify checkbox claims against PR reviews? Is "thin layer over it" achievable, or does the skill have to stand on its own with a reference?
2. Does the plan satisfy "Mode before skill (GH-1299)": are the existing skills checked, and is each rejection reason true?
3. The plan's `## Requirements` section lists nine lessons the skill must carry; `## Plan` lists the steps. Is any lesson missing, merged away or contradicted by the plan's steps? Check especially: the save-old-body and re-read-live-body rule before `gh issue edit`, the "plan, not an approval" rule, the header/estimate preservation, the Codex `gpt-6.2-astra` low-effort read-only validator that never receives the author's conclusions, and the traps (zsh word-splitting, expired cloud login reported as not checked, proxied grep false negatives, no bare @mentions, no personal emails or secrets in an issue).
4. Is the registration surface complete (index row; anything else this repo requires when a skill is added, such as a catalog, a README table or a pinned count)? Name any file the plan misses, with the line that pins it.
5. What prevents an unchanged base from passing each acceptance item A1-A6, and is each red control the right observation? Distinguish checks that prove the skill is right from checks that only prove a file exists.
6. Is the smoke plan (A5) a real exercise of the skill's steps 1-2 from the consumer entry point, and does its adjacent path (missing today ledger) actually reach a stop the skill can show without writing anything?
7. Is anything here more machinery than the problem needs, or is a required case missing? Flag over- and under-engineering concretely.

Write graded findings (`[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`), then a VERDICT. Set STATUS to Approved only if no `[Blocker]` or `[Should]` remains.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). In a manual relay, end each turn by committing just this file; no push. In a driven turn the harness commits.

## Log

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
