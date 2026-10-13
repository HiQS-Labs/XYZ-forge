# RELAY · GH-985 Agy Claude optimization build
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-06.
-->

NEXT: Producer
STATUS: Open
ROUND: 3 / 3

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
6. **Commit only the relay file** (`relay(gh-985-agy-claude-optimization-build): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **skills/2-daily/workhorse/SKILL.md** — the read-only path that
  `relay-drive.sh --artifact-file skills/2-daily/workhorse/SKILL.md` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: Reviewer   ·   Producer: Agy
- Started: 2026-10-06
- Definition of Done: _<fill in the acceptance criteria the Reviewer grades against>_

BUILD OWNERSHIP: Agy owns only skills/2-daily/workhorse/SKILL.md and stop-hook.sh. You are not alone in the codebase; preserve peers and all other paths. Approved plan: PROJECT/2-WORKING/GH-985-CLAUDE-WORKHORSE.md; plan QA attested in gh985-plan.fable.md. Exact-row accepted-start recorded. Read full two source files and plan. Implement only text/comment changes: correct hook reason to continue next authorized feasible required item, retain required scope; [!] concrete external blocker after independent work; [-] genuinely optional or explicitly user-deferred only; evidence/outcome audit, pause/cancellation and deployment windows binding. Keep Python logic unchanged except its reason string constant, preserve Bash wrapper and session/fail-open paths. Clarify comment: documented eight-consecutive cap resets on tool calls; [-] is not a required-scope escape. Add a short Claude runtime paragraph before separator near Instructions versus runtime enforcement: current hook syntactic not semantic; Stop not invoked for user interrupts; StopFailure handles API errors and cannot force retry; restored auth resumes authorized step; optional native /goal only explicitly requested, no activation/config/mod. Use existing official docs link and avoid duplicating the shared contract. No new files/tests/gates/mods/settings/installer edits. Do not run tests, git commands, publish or deploy; parent handles disposable validation and commit. Update only this build relay with brief implemented paths and bounds; do not mark final review Approved. Set NEXT Producer / STATUS Open at handback and release build token to Producer; never claim final QA success.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Producer · Round 1

- Implemented text changes in `skills/2-daily/workhorse/stop-hook.sh`:
  - Updated comment at line 7 to document the 8-consecutive-continuation cap and tool-call reset, clarifying that optional/deferred markers do not abandon required scope.
  - Rewrote the block reason text (lines 45-48) to match the shared contract, stating that `[-]` is for optional/deferred work only.
- Implemented text changes in `skills/2-daily/workhorse/SKILL.md`:
  - Added a new paragraph after line 133 to specify Claude runtime limits, noting the hook is syntactic, Stop is not invoked for user interrupts, StopFailure handles API errors, and `/goal` is optional.
- All Python logic outside of the reason string constant, the Bash wrapper, and fail-open paths were preserved unchanged.
- Manual bounds checking passed (bash syntax check and python extraction compiled successfully).

handing off to Producer — go to the parent orchestrator window and say 'take your turn'

### Producer · Round 2

First bounded check at 66612ba4: extracted Python AST matches base except reason, syntax/compile pass; guidance assertion fails `required guidance absent: authorized` (manual-first-failure.txt). Required literal terms are in the approved plan; no completed execution claim.

Agy repair ownership remains the same two source files only. Make the reason explicitly continue the next **authorized feasible required item**; mark [x] only with acceptance evidence and audit the requested outcome before completion; for a concrete external blocker record [!] and finish independent authorized work first. Keep optional/explicit-user-deferral wording and pause/cancellation limits. Preserve Python AST except reason, Bash wrapper and session/fail-open logic.

In the Claude runtime paragraph, replace `do not activate it or install a mod here` with `do not activate it implicitly`. Explicit operator /goal requests must remain supported. Link the official Claude hooks docs, describe StopFailure as ignoring continuation decisions (rather than API errors themselves forcing retry), and wrap prose to existing style. No added mod/config/gate or implicit activation. Read earlier context and make only these fixes; no new broad recon or tests; parent will run the probe. Write only allowed source and this relay. Set NEXT Producer / STATUS Open and release to Producer, do not mark final QA Approved.

### Producer · Round 2 (Repair)

- Modified `skills/2-daily/workhorse/stop-hook.sh`:
  - Rewrote the reason string to explicitly continue the next authorized feasible required item.
  - Specified to mark [x] only with acceptance evidence and audit the requested outcome before completion.
  - Specified to record [!] for a concrete external blocker and finish independent authorized work first.
  - Retained the wording for [-] and verified completion/explicit user pause/cancellation.
- Modified `skills/2-daily/workhorse/SKILL.md`:
  - Updated the Claude runtime paragraph to replace `do not activate it or install a mod here` with `do not activate it implicitly`.
  - Added that explicit operator `/goal` requests must remain supported.
  - Linked the official Claude hooks docs (`https://docs.anthropic.com/en/docs/agents-and-tools/claude-code/hooks`).
  - Described StopFailure as ignoring continuation decisions `(rather than API errors themselves forcing retry)`.
- Re-verified Python AST and Bash structure preservation; no other paths edited.

handing off to Producer — go to the parent orchestrator window and say 'take your turn'

### Producer · Round 3

Initial 10 protocol cases pass and AST unchanged apart from reason, but the stop-only clause contradicts the contract: `Stop only for verified completion or explicit user pause/cancellation.` omits concrete external blockers. Manual-blocker-clause-failure.txt records a failing literal clause assertion. Item remains unfinished.

Agy owns only the same two source files. Make this surgical correction, no other behavior or paths:
1. Replace the stop-only sentence with `Stop only for verified completion, explicit user pause/cancellation, or a concrete external blocker after independent authorized work is finished.` Keep all other reason clauses intact.
2. Replace the single long Claude runtime paragraph with the following short wrapped text (prose is desired content, not a new activation):

**Claude runtime.** The existing Stop hook checks open checklist lines and cannot verify acceptance
evidence. Claude does not call Stop on user interrupts; API failures use StopFailure, which ignores
continuation decisions, so retry the authorized action when access is restored. When available and
explicitly requested, Claude's `/goal` shortcut adds a session-scoped prompt-based Stop check; it
still relies on model judgment and does not expand authorization. See [Claude hooks](https://code.claude.com/docs/en/hooks#stop).

Preserve reason-only Python AST delta, Bash wrapper, session scoping, fail-open and installer. No new files/gates/mods/config/tests or git commands. Read only needed current source and this block; don't repeat broad recon or tests. Write source and relay only; NEXT Producer, STATUS Open, release build token to Producer. Final Fable QA is separate.

### Producer · Round 3 (Repair)

- Modified `skills/2-daily/workhorse/stop-hook.sh`:
  - Replaced the stop-only sentence with `Stop only for verified completion, explicit user pause/cancellation, or a concrete external blocker after independent authorized work is finished.`
- Modified `skills/2-daily/workhorse/SKILL.md`:
  - Replaced the single long Claude runtime paragraph with the provided short wrapped text.
- Verified reason-only Python AST delta, Bash wrapper, session scoping, fail-open and installer are preserved. No new files/gates/mods/config/tests added.

handing off to Producer — go to the parent orchestrator window and say 'take your turn'

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
