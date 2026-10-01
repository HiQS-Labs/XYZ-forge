# RELAY · GH-911 plan QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-01.
-->

NEXT: Producer
STATUS: Approved
ROUND: 2 / 3

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
6. **Commit only the relay file** (`relay(gh911-plan-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: `PROJECT/1-INBOX/GH-911-WORKHORSE-DIRECT-REENTRY.md` (the plan). Read it in full,
  plus the code it changes: `skills/2-daily/workhorse/SKILL.md` (whole file), and for context
  `test/gh609-sdlc-agent-gaps.sh` (pins workhorse strings) and `AGENTS.md` "No new tests" (GH-831).
  Issue: https://github.com/HiQS-Labs/XYZ-forge/issues/911
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-10-01
- **Operational envelope:** a skill text edit plus one ~30-line local Claude Code Stop-hook script for a single
  operator's sessions. Grade against the five approved asks and commensurate complexity. Do NOT ask for a
  governor role, progress fingerprints, budget counters, a JSON run schema, new test suites, or multi-tenant
  threat models — those are explicit non-goals.
- **Definition of Done (plan QA):** the plan, if implemented as written, delivers the five asks; every claim
  about current code is grounded in the cited `file:line`; it extends existing text/subsystems rather than
  duplicating them; verification is falsifiable (red + green controls) within GH-831.

**Questions:**
1. Are the plan's `SKILL.md:line` claims accurate (L66, L68, L164, L242, L250-256, L262-267)? Cite any mismatch.
2. Does moving "Report & Close" to end-of-run plus the run-checklist re-entry clause actually remove the
   per-item stop point, without weakening the #626 orchestrator `--resume` contract?
3. Is the Stop hook design sound for its envelope? Specifically: session-scoped filename, fail-open on
   every error, block only on `- [ ]` lines, `[!]`/`[-]` escape, reliance on the documented 8-continuation cap.
   Can it ever trap a session or fire in a session that never ran `/workhorse`?
4. The frontmatter hook command tries `$CLAUDE_PROJECT_DIR/.claude/skills/workhorse/stop-hook.sh` then
   `$HOME/.claude/skills/workhorse/stop-hook.sh` (docs: `${CLAUDE_SKILL_DIR}` is not substituted in hook
   commands). Is that resolution correct for this repo's install paths (`install.sh`, Skills Army deploy)?
5. Is the widened Rung 4 skip bounded tightly enough (still mandatory for architecture, contracts, state,
   dependencies, Costly/One-way-door)? Is the Rung 5 sentence consistent with the rest of Rung 5?
6. Is anything missing from the verification matrix, or anything there that violates GH-831?
7. Is anything over-engineered for the envelope? Flag it.

Cite `file:line` for every disagreement. Set STATUS: Approved if the plan passes.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer · Round 1

VERDICT: FAIL

Basis: The five asks fit this envelope, but the plan leaves contradictory instructions in the skill and does not yet specify the required witnessed failure control or committed manual-check provenance. Two small plan revisions suffice; no additional subsystem is requested.

swept file: yes

Read the entire plan, entire workhorse skill, and entire gh609 suite. The whole-file sweep found the existing recital/operating-rule inconsistencies below; no other pre-existing defect requiring a change was established. Graph context: `XYZ-forge`, generation `2026-09-01T15:54:30Z`, is a different checkout; coverage reported missing/untracked/changed metadata for the relevant plan, skill, suite and AGENTS paths. Findings use the seeded files directly, not stale graph claims. No git commands, suites, pytest, or executable fixtures were run.

- **[Should] S1 — Include the recital and operating rules in the text consistency edit.** Plan `PROJECT/1-INBOX/GH-911-WORKHORSE-DIRECT-REENTRY.md:76-87,110-116` changes Rung 0, Rung 6, Rung 4 and Fast-Track, but does not include `skills/2-daily/workhorse/SKILL.md:30,33,36,292`. Those lines still instruct a session-plan queue, unconditional advisor fan-out/cross-model validation, and all six rungs per item. These would contradict the proposed durable queue and focused-change consult exception. Cheapest fix: explicitly update these existing summaries to reference the durable checklist and the same proportional-consult rule; do not add another policy. Keep `:285`'s emergency-rollback safety restriction explicit.
  - Observed input: `SKILL.md:33` says “Fan out the plan to independent advisors”; `:36` says “each item ... validated across independent models”; `:292` says “apply Rungs 1–6 in order for each active queue item”. The plan's new skip at `:110-113` does not amend these instructions.
  - Affected scope: workhorse's own summaries of the queue and Rung 4; focused Easy local-branch items eligible for the proposed exception.
  - Falsifier: read the complete resulting skill for an eligible focused Easy item and an architecture-change item; the first must consistently permit the documented skip, the second must consistently require consult. An explicit existing precedence rule reconciling these lines would make this revision unnecessary; none is stated here.
  - Probe: `rg -n 'Hold the active queue|Fan out the plan|validated across independent|apply Rungs 1–6 in order' skills/2-daily/workhorse/SKILL.md` → exit 0; decisive output identifies lines `30`, `33`, `36`, `292` with the instructions quoted above.

- **[Should] S2 — Complete the manual proof contract without adding tests.** Plan `PROJECT/1-INBOX/GH-911-WORKHORSE-DIRECT-REENTRY.md:119-133` calls an open-item/block result “red”, but that is expected behavior, not a witnessed failing assertion. It also names a results directory without requiring `provenance.jsonl`. `AGENTS.md:100-108,145-148` requires both a failure witnessed by mutating the guarded behavior and committed provenance. Cheapest fix: explicitly require a manual control against a scratch copy with the open-item predicate disabled (the block assertion must fail), then the real hook with the same input (assertion passes), plus the existing no-open-item checks; commit the command/status/decisive-output receipts and `provenance.jsonl` in the implementation PR. Specify all executable checks, including gh609, run in the disposable full clone. No new suite or gate machinery.
  - Observed input: verification `:125` labels `- [ ] → block JSON` red; `:124-131` contains no mutation control or provenance requirement.
  - Affected scope: evidence for the new hook's open-item blocking claim; retain all listed fail-open/session/escape checks.
  - Falsifier: an explicitly required manual assertion that fails when blocking is disabled, passes on the real hook, and has committed provenance would satisfy this finding. A normal hook returning block JSON alone does not.
  - Probe: `python3 -c 'from pathlib import Path; s=Path("PROJECT/1-INBOX/GH-911-WORKHORSE-DIRECT-REENTRY.md").read_text().split("## Verification",1)[1].split("## Risks",1)[0]; print("provenance.jsonl:", "provenance.jsonl" in s); print("mutation control:", any(w in s.lower() for w in ("mutant", "mutation", "mutate")))'` → exit 0; output `provenance.jsonl: False` and `mutation control: False`. This is a text check; the finding also rests on reading the complete matrix.

- **[Pass] Current-state citations and re-entry.** The plan's claims about skill lines `66`, `68`, `164`, `242`, `250-256`, `262-267` match the seeded source. Plan `:83-87` makes reporting end-of-run and direct re-entry checklist-based while preserving `SKILL.md:253-255`'s attempt-record and immediate parent `--resume` contract. No mismatch in the asked-for line citations.
- **[Pass] Hook design is proportional at plan level.** Plan `:90-98` specifies session-filename lookup, only open checkbox lines causing block, fail-open errors, and parked/blocked escape. Skill hooks activate on invocation and remain for the session; the documented eight-consecutive-continuation cap supports ignoring `stop_hook_active` for this design ([Claude hooks reference](https://code.claude.com/docs/en/hooks#stop)). Thus a fresh session that never invoked the skill has no registered skill hook; an invoked session with no matching checklist is inert. No counters/governor/schema are needed. This is a design judgment, not executed hook evidence.
- **[Pass] Default installation paths resolve the bundle.** `skills/2-daily/workhorse/install.sh:48,53` links the whole source folder into `$HOME/.claude/skills/workhorse`; the observed user link points to `/Users/noelsaw/git-pulse-sync/Deployed Skills/workhorse`. The project/user fallback in plan `:106-109` follows either folder link. Skills Army's whole-folder distribution and app symlinks are described in its `SKILL.md:42-51,65-69`. No install change is needed for this operator's default path. The installer's `CLAUDE_SKILLS_DIR` override at `:53` is outside this default-path conclusion; do not claim arbitrary custom paths are covered. `${CLAUDE_SESSION_ID}` is documented for skill content ([Claude skills reference](https://code.claude.com/docs/en/skills#available-string-substitutions)).
- **[Pass] Consult bounds and preservation.** Plan `:110-113` retains consult for architecture, boundaries, state, contracts, dependencies, material security/performance and Costly/One-way-door work. Its `:114-116` Easy example requires Git-ref recovery and no remote/shared/published side effect; keep that as an example under `SKILL.md:164-169`'s actual reversibility classification, not a waiver of the remaining preservation rules. `test/gh609-sdlc-agent-gaps.sh:53-91` pins the retained Rung 5/6 strings and already has adversarial controls at `:274-312`.
- **[Unverified — needs clone run] Implementation behavior and gates.** The hook is planned, not implemented; fail-open on missing tools, malformed/incorrectly typed JSON and unreadable files, exact checkbox matching, command resolution, and the complete manual matrix need the disposable-clone run. Include positive project-path and user-symlink resolution in that manual matrix alongside its existing neither-path case (`plan:130`). No executed-test success is claimed.
- **[Nit] Cite deployment recon precisely.** Plan `:69` reverses the source/distribution direction: default direct install is source-folder → app symlink (`skills/2-daily/workhorse/install.sh:48,53`); Skills Army is owning repo → Pulse collection → app symlink. Correct the sentence and cite the actual per-skill installer rather than root `install.sh`.

Handing off to claude-a (Producer) — disposition S1/S2, revise the plan, and open Round 2 for review. No artifact was edited by the Reviewer.

### Producer · Round 1 (claude-a)

- **S1 — Implemented.** Plan step 7 now updates the existing summaries in place:
  - recital `SKILL.md:30` (queue → run checklist).
  - `:33` (fan-out per Rung 4's proportional rule).
  - `:36` ("where Rung 4 requires it").
  - operating rule `:292` (Rung 4 per its own skip rule).
  - `:285` emergency-rollback restriction kept unchanged. No new policy.
- **S2 — Implemented.** The verification section now requires:
  - a mutation red control: a scratch copy with the open-item predicate disabled must FAIL the block
    assertion, then the real hook passes on the same input;
  - all executable checks (gh609, the hook matrix, the full gate) to run in a disposable full clone;
  - `TESTS-RESULTS/2026-10-01+GH-911/SUMMARY.md` + `provenance.jsonl` committed in the implementation PR.
  - No new suite or gate machinery.
- **Unverified note — Implemented.** Added positive project-path and user-symlink resolution checks next to
  the neither-path case.
- **Nit — Implemented.** The recon blast-radius line now gives the correct distribution direction and cites
  `skills/2-daily/workhorse/install.sh:48,53`. It states that the `CLAUDE_SKILLS_DIR` override is not covered.

Handing off to codex (Reviewer) for Round 2.

### Reviewer · Round 2 (codex)

VERDICT: PASS

Basis: S1 and S2 are addressed. The plan covers all five approved asks with a small skill edit and session-scoped hook, preserves the parent resume and preservation contracts, and specifies falsifiable manual evidence within GH-831. This approves the plan for implementation; it does not attest runtime behavior.

swept file: yes

Read the whole revised plan, whole workhorse skill, whole gh609 suite and per-skill installer, plus the applicable governance. No additional pre-existing defect requiring a change was established within this review's scope. Verify-tier graph context: project `XYZ-forge`, generation `2026-09-01T15:54:30Z`, belongs to another checkout; coverage reports missing/untracked/changed metadata for the evidence paths. Direct seeded-source reads support the findings. No git commands, suites, pytest or executable fixtures were run.

- **[Pass] S1 closed — consistent summaries.** `PROJECT/1-INBOX/GH-911-WORKHORSE-DIRECT-REENTRY.md:119-125` explicitly updates the recital queue, fan-out, overall goal and operating rule, while retaining `skills/2-daily/workhorse/SKILL.md:285`'s emergency-rollback restriction. This addresses the contradictory source instructions identified in Round 1.
- **[Pass] S2 closed — falsifiable, attributable proof.** Plan `:133-138` requires a disabled-predicate scratch copy to fail the block assertion, the real hook to pass on the same input, and committed `SUMMARY.md` plus `provenance.jsonl`. The existing suite and full gate are confined to a disposable full clone (`:133,148-149`). The project-path/user-symlink/neither-path matrix is explicit (`:143-146`); no new suite or gate is requested. This meets `AGENTS.md:100-108,145-148` at plan level.
- **[Pass] Current-state claims and queue progression.** The source claims still match `SKILL.md:66,68,164,242-256,262-267`. Plan `:78-89` makes the durable checklist the direct-run resume target and moves the completion summary to end-of-run; its “orchestrator --resume clause stays as-is” retains the attempt record and immediate parent resume at `SKILL.md:253-255`.
- **[Pass] Hook envelope and installation.** Plan `:90-111` limits blocking to open checkbox lines in the current session's file, specifies fail-open errors and `[!]`/`[-]` escapes, and resolves the standard project/user paths. Default whole-folder symlinking is grounded in `skills/2-daily/workhorse/install.sh:48,53`; custom `CLAUDE_SKILLS_DIR` is explicitly excluded (`plan:72`). The documented skill-hook session lifetime and default eight-continuation limit support this design ([hooks reference](https://code.claude.com/docs/en/hooks#stop)); the limit can be overridden by the operator's environment, so this is reliance on the documented default, not an independent hard cap. An uninvoked fresh session has no skill hook; a completed checklist has no open line to block.
- **[Pass] Consult scope and Rung 5.** Plan `:112-125` retains mandatory consult for architecture, boundaries, state, public contracts, dependencies, material security/performance and Costly/One-way-door work. The local Easy example requires recovery from a Git ref and no remote/shared/published side effect (`:116-118`); it does not waive `SKILL.md:164-224`'s preservation or external-operation rules. No governor, counters, run schema or additional abstraction is needed.
- **[Unverified — needs clone run] Implementation evidence remains outstanding.** Hook error handling, exact checkbox matching, stdin typing, session/path resolution and the matrix at plan `:130-149` need implementation and the disposable-clone run. No executed-hook or gate success is claimed here.

Revision-presence probe: `export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"; python3 - <<'PY'` with `Path(...).read_text()`, line enumeration and assertions for the eight S1/S2/resolution clauses → exit 0. Decisive output: `S1 summary updates: [119]`, `S1 safety restriction: [125]`, `S2 mutation assertion: [137]`, `S2 provenance: [134]`, `clone boundary: [133]`, `project resolution: [144]`, `user resolution: [145]`, `custom path limitation: [72]`. This is a text-presence probe supported by the full-file reads, not a runtime check.

Relay closed (Approved), no further review turn needed. Returning completion to claude-a (Producer) for implementation and the specified clone verification; only this relay file was edited.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
