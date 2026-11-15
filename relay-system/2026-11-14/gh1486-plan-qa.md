# RELAY · GH-1486 plan QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-11-14.
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
6. **Commit only the relay file** (`relay(gh1486-plan-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: `PROJECT/2-WORKING/GH-1486-RE-VENDOR-XYZ-SKILL.md` (frontmatter `non_goals`, `## Recon`, `## Preflight bet`, `## Plan`, `## Acceptance`, `## Verification`, `## Risks`). This is a **plan review**: the skill file has not been written yet.
- Reviewer: codex   ·   Producer: claude
- Started: 2026-11-14
- Operational envelope: an instruction-only skill (one `SKILL.md`) that an agent follows on one developer's machine to refresh one repository's git-ignored `.xyz/` copy, by sequencing commands that already exist (`relay-automation/xyz-sync.sh`, `xyz-vendor.sh`, Skills Army HQ `sync.py`/`intake.py`). No script, flag or suite is added (XYZ-forge `AGENTS.md` *No new tests*, GH-831). Grade against that envelope; do not ask for locks, journals, daemons, a helper script or a fleet mode.
- Operator decision already made: a **separate skill**, not a `## Refresh` section in `vendor-stack`. Two consult advisors recommended the section under `skills/README.md:25-28`; the operator chose the separate skill for a memorable name (issue #1486, first comment). Do not reopen this; you may flag a concrete harm it causes.
- Definition of Done: the plan is grounded in the cited paths, sequences the existing writers without duplicating any, each listed stop is checkable with the commands the plan names, and each acceptance item would fail on base `5967bde25`.

### Step A: paraphrase first (GH-1414). Do this BEFORE reading anything else.
Read ONLY the plan doc's frontmatter `non_goals`, `## Status`, `## Recon`, `## Preflight bet`, `## Plan`, `## Acceptance`, `## Verification` and `## Risks`. Do not open source files or the issue yet. Then, at the top of your review block, write:
- **What this proposes** (2–5 sentences)
- **How the existing system works, per this document** (2–5 sentences)
- **What it's not** (short; ground exclusions in the doc's sections and label any inference)
- **Input boundary:** list which sections you had read when you wrote the paraphrase.

### Step B: source-backed technical validation
Now read the requirements and source:
- Issue: https://github.com/HiQS-Labs/XYZ-forge/issues/1486 and its first comment (consult dispositions).
- `relay-automation/xyz-sync.sh` (whole file: `select_vendored_rows`, `update_rows` 268-298, `require_safe_update_source` 300-330, `check_rows` 406-465).
- `relay-automation/xyz-vendor.sh:36-75` (args, tier auto-detect), `:230-240` (`XYZ_RUNTIME_PATHS`), `:420-516` (`materialize_vendor`, `register_vendor`).
- `relay-automation/driver-lock-lib.sh:1-40`.
- `skills/3-weekly/skills-army-hq/SKILL.md:20-90,190-250`.
- `skills/4-occasional/vendor-stack/SKILL.md` (whole file), `skills/README.md:15-40`, `ARCHITECTURE.md:130-155`, `README.md:245-265`.
- `utils/ci-route.sh:54-70` (gate route).

Label this assessment **source-backed**. Answer each question with `file:line` evidence:

1. Are the Recon claims true at the cited lines? Name any that are wrong.
2. Plan step 1.2: does `fetch` + `merge --ff-only origin/<branch>` + `HEAD == origin/<branch>` reliably reject a Forge checkout carrying unpublished commits, without mutating anything the operator would not expect? Is the merge step needed at all, or should a behind checkout simply stop?
3. Plan step 1.3/1.6: `xyz-sync.sh` matches `<target>` or `<target>/.xyz` and `check` prints the install dir. Is passing `$T/.xyz` everywhere and matching the line `ok    $T/.xyz` exact and robust (paths with spaces, a registry with several rows for nested repos)?
4. Plan step 1.4: is "relay lock path absent and no process command line contains `$T/.xyz/`" a sound check for a live relay, marathon or Jog run in that repository? Name a live-run shape it misses, and say whether missing it matters within the envelope.
5. Plan step 1.5: is the tier rule right? When `releases.db` exists, does `xyz-vendor.sh` already keep tier 2, and is there any tier-1 copy the rule would wrongly stop?
6. Plan step 1.6's three-part current test: is it the right definition of "current"? Does `check` read the registry rather than the copy (so a registry row and `VERSION` could disagree), and does the third condition close that?
7. Plan step 1.9: is the Skills Army handoff correct (read-only status with `--canonical`, then the `skills-army-hq` skill's own preview/apply), and does it avoid writing the collection on its own authority?
8. What prevents an unchanged base from passing each acceptance item A1–A7, and is each red control or contrast the right observation? Distinguish checks that prove the skill's stops fire from checks that only prove nothing crashed.
9. Is anything here more machinery than the problem needs, or is a required case missing? Flag over- and under-engineering concretely. Do not ask for new suites.

Write graded findings, then a VERDICT. Set STATUS to Approved only if no `[Blocker]` or `[Should]` remains.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
