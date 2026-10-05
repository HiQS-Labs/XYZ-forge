# RELAY · GH-964 final QA: xyz-mod /xyz-status implementation
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
6. **Commit only the relay file** (`relay(gh-964-final-qa-xyz-mod-xyz-status-implementation): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review (branch `feat/gh964-xyz-mod` vs `origin/development` `8853cd6a`):
  `skills/2-daily/xyz-mod/mod/hooks/register.ts`, `skills/2-daily/xyz-mod/mod/hooks/hooks.json`,
  `skills/2-daily/xyz-mod/mod/.claude-plugin/plugin.json`, `skills/2-daily/xyz-mod/mod/tsconfig.json`
  (written by Claude Code when it loaded the mod), `skills/2-daily/xyz-mod/SKILL.md`, the
  `ARCHITECTURE.md` and `CHANGELOG.md` entries, `PARKED/2026-10-04-gh964-skills-index.md`, and the
  evidence in `TESTS-RESULTS/2026-10-04+GH-964/`.
- Approved plan: `PROJECT/2-WORKING/GH-964-CLAUDE-CODE-MODS.md` (plan QA:
  `relay-system/2026-10-04/gh964-plan-qa.md`, Approved round 2).
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-10-04
- Definition of Done: the code does what plan step 1 says and nothing more; the evidence substantiates
  the plan's D1–D3, D6 and R1; the skill and docs are accurate; no new test suite, registry entry or
  gate machinery (GH-831); the rating 35/15/50/70 still matches the evidence.

**Operational envelope.** Optional, read-only, single-operator local mod, ~45 lines of TypeScript.
Grade against the approved plan. Do not ask for retries, caching, telemetry, installers or tests.

**Facts you cannot check here** (stated input, from Claude Code 2.1.289's bundled typings and runs):
`$.process.run(argv, { cwd, env, timeoutMs })` resolves `{ exitCode, stdout, stderr }` for any exit
code and rejects when the command cannot start or times out; `env` is set *over* the host
environment (PATH survives). `claude plugin validate` output is in `TESTS-RESULTS/.../d2-validate.txt`.
A scratch type-check with TypeScript 5.6 against those typings was clean.

**Owed by the operator, not claimed here:** D4 (`/plugin` lists the mod active) and D5 interactive in
the terminal and VS Code. Only a headless `claude -p` run is recorded for D5.

**Questions.**
1. Does `register.ts` match plan step 1 exactly: root via `git rev-parse --show-toplevel`, root line
   first, repo-local readers by absolute path, `gh` from PATH, `cwd` = root, `TICK_REPO_ROOT` pinned,
   15 s timeouts, independent sections, nonzero / thrown / empty → `ERROR`, and no other hooks?
2. Any input where a failed reader would still print as healthy, or one section's failure hides
   another's? Cite `register.ts:line` and the concrete input.
3. Do the recorded results in `TESTS-RESULTS/2026-10-04+GH-964/provenance.jsonl` and the two logs
   support the D1–D3, D6, R1 verdicts? Is anything over-claimed (for example D5)?
4. Are `SKILL.md`, the ARCHITECTURE row and the CHANGELOG entry accurate against the code?
5. Is the committed engine-written `tsconfig.json` acceptable, or an accidental file to drop?
6. Anything over- or under-built for the envelope? Cite `file:line` for every disagreement.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
