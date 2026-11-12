# RELAY · GH-1426 plan QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-11-11.
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
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
   Reviewer headings may be `### Reviewer · Round N`, `### Round N · Reviewer · <agent>`, `### Reviewer (<agent>)` (optionally followed by `— rN`), or `### Reviewer — Round N` (optionally followed by `(<agent>)`); follow the heading with a non-empty review body.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(gh1426-plan-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: `PROJECT/2-WORKING/GH-1426-JOG-DRYRUN-TARGET-READINESS.md` (sections `## Recon`, `## Plan`, `## Acceptance`). This is a **plan review**: no production code has been written yet.
- Reviewer: codex   ·   Producer: claude
- Started: 2026-11-11
- Operational envelope: a local developer CLI (`releases_app.py jog run`), one operator, one file changed (`utils/py/jog_run.py`). Grade against the issue's acceptance and commensurate complexity. Do not grade against enterprise or multi-tenant threat models. The repo forbids new tests, suites, registry entries or gate machinery (`AGENTS.md` "No new tests", GH-831). Verification uses existing suites plus manual checks under `TESTS-RESULTS/`. Asking for a new test is out of scope.
- Out of scope: sibling issues #1427 (claude-turn ceilings) and #1428 (reviewer gate / codex sandbox).

### Step A: paraphrase first (GH-1414). Do this BEFORE reading anything else.
Read ONLY `## Status`, `## Recon`, `## Plan` (with its sub-sections) and the plan doc's own
`## Acceptance` / `## Non-goals`. Do not open source files or the issue yet. Then, at the top of your
review block, write:
- **What this proposes** (2–5 sentences)
- **How the existing system works, per this document** (2–5 sentences)
- **What it's not** (short; ground exclusions in the doc's sections and label any inference)
- **Input boundary:** list which sections you had read when you wrote the paraphrase.

### Step B: source-backed technical validation
Now read the requirements and source:
- Issue: https://github.com/HiQS-Labs/XYZ-forge/issues/1426 (the same text is in the doc's Symptom / Observed / Acceptance sections)
- `utils/py/jog_run.py` (in particular 530-610 `_execution_root` / `run_marathon_phase`, 2163-2463 `jog_run_main`)
- `utils/py/swarm_preflight.py` (1166-1250 arg parsing + doc lookup, 1300-1350 fetch/freshness, 1585-1600 gate check, 1640-1735 verdict/dry-run exit)
- `utils/py/harness_paths.py:177` `require_primary`; `skills/2-daily/jog/SKILL.md:72-90,130-145`
- Tests that pin touched text: `test/jog-queue.sh:170-185`, `test/gh280-jog-marathon-adapter.sh:597-601,703-712,795-803`

Label this part **Source-backed assessment**. Questions:
1. Are the recon claims (line refs, behaviours) grounded in the actual code? Cite any claim that is wrong.
2. Does dry-run with `--target-root` stay free of ledger writes and locks? Are there writes in the dry-run preflight path that the plan misses (e.g. the `rtl_transcript_root` shell-out when `--out` is unset, the `git fetch`, `gh` calls)? Is skipping `_require_jog_primary` in dry-run consistent with SKILL.md:141?
3. Is the 1-INBOX → `--project-doc` substitution a faithful approximation of what a live run would evaluate after promotion? Or does `--project-doc` mode diverge in a way that would make the dry-run verdict wrong (slug, acceptance source, issue-state, etc.)?
4. Is `_preflight_summary`'s parsing robust to every exit path in preflight (0, 4, 5, 6, 7, die exit 2, contract error exit 3), and does it never yield an empty string?
5. Will the existing suites (I7, G8, jog-queue case 12) stay green under the plan without edits? Does any other consumer (docs, skills, scripts) parse `advancing halted at landing boundary`, `marathon execution`, or the `preflight-refused (exit N): …` reason?
6. Is it surgical and DRY: extends the existing writer and preflight, with no parallel subsystem? Flag over- or under-building. Is changing the halt line for *all* parked actions (not just preflight) correct, or should landing parks keep the old text?
7. Is any acceptance criterion from the issue unmapped, or is a red control unable to fail?

Write graded findings (`[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`) with file:line. Behaviour-change requests carry `Observed input:` / `Affected scope:` / `Falsifier:`. VERDICT PASS → set `STATUS: Approved`.
- Definition of Done: the plan maps every issue acceptance criterion to a falsifiable check, its recon is grounded, it stays read-only in dry-run, and it extends existing code without a parallel subsystem or new tests.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
