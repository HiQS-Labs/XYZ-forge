# RELAY · GH-964 plan QA: Claude Code mod /xyz-status
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-04.
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
6. **Commit only the relay file** (`relay(gh-964-plan-qa-claude-code-mod-xyz-status): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: `PROJECT/2-WORKING/GH-964-CLAUDE-CODE-MODS.md` (the plan; no code exists yet).
  Requirements source: issue https://github.com/HiQS-Labs/XYZ-forge/issues/964 (body transcribed in the plan).
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-10-04
- Definition of Done: the plan is grounded in the real paths it cites, covers the issue's acceptance
  list (or names what it defers and why), extends existing read-only commands instead of re-implementing
  them, has a falsifiable manual diagnostic with a red control, and adds no test suite (GH-831).

**Operational envelope.** A single operator's local developer tool: an optional, read-only Claude Code
mod loaded with `--plugin-dir`, about 60 lines of TypeScript plus a skill doc. Grade against that.
Do not ask for enterprise machinery, retries, caching, telemetry, installers or new tests (AGENTS.md
"No new tests", GH-831: a request for a new suite is itself out of scope).

**Paths to read** (all in this clone): the plan; `AGENTS.md` (No new tests rail); `utils/ci-route.sh`
lines 40–70 (routing of non-core `skills/**`); `relay-automation/marathon-ls.sh` (header);
`bin/tick` (`claims` verb); `skills/2-daily/xyz/SKILL.md` (the existing `/xyz` name);
`test/gh589-skill-viewer.sh` (what a new skill folder must satisfy). The mod API facts in the plan's
Recon come from Claude Code 2.1.289's bundled typings, not in this repo; treat them as stated input.

**Questions.**
1. Are the three data sources (`gh run list --workflow wave-reconcile.yml`, `bin/tick claims`,
   `relay-automation/marathon-ls.sh`) real, read-only, and the right existing commands for "what is in
   flight"? Is any better existing reader missed?
2. Is dropping the issue's "open relay threads with STATUS" (beyond what `marathon-ls.sh` shows) and the
   optional `/xyz row N` a reasonable, stated deferral, or does it leave an acceptance item unmet?
3. Is the naming right (`/xyz-status` command, `xyz-mod` skill folder) given `skills/2-daily/xyz/`?
4. Does placing the mod under `skills/2-daily/xyz-mod/mod/` route as docs/Small per `utils/ci-route.sh`,
   and does it trip `test/gh589-skill-viewer.sh` or any other existing suite?
5. Is the manual diagnostic falsifiable (does the red control actually go red), and does it stay inside
   GH-831 (no new suite, no registry entry)?
6. Anything over- or under-built for the envelope above? Cite `file:line` for every disagreement.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
