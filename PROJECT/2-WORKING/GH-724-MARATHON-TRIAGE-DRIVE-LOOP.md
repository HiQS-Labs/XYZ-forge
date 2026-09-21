---
title: marathon-triage drives end to end — drive-loop shape, guard-aware Step 0, capture recipe
status: Active
created: 2026-09-20
updated: 2026-09-20
owner: noel
goal: >
  An agent invoking /marathon-triage runs inventory, reconciliation, missing capture docs, the planner
  dry run and per-candidate preflight unattended, and reports classifications, verdicts and
  RECOMMEND/BECAUSE/UNLESS decisions without the operator walking it through each step.
effort: 4
complexity: 2
risk: 1
phases: 1
gh_issue: 724
source: https://github.com/HiQS-Labs/XYZ-forge/issues/724
doc_type: bugfix
---

# GH-724 — marathon-triage drive loop

## Status

| What was just completed | What's next |
|---|---|
| Plan QA R1 (Codex) returned four `[Should]` findings — umbrella prerequisite blocks discovery triage, dry-run side effects misdescribed, complete vs blocked report undefined, heading-count acceptance too weak — all verified against source and accepted; plan revised. Deployed copy refreshed from canonical `5e60cb01` (Pulse `6cb97aa8`) so the `ROADMAP.md` drift is already gone | Plan QA R2; then rewrite `skills/marathon-triage/SKILL.md`, run the doc gates and the hooks suite, final relay QA with the four-scenario walkthrough, PR into `development`; re-publish to Pulse after landing |

## Quad Concepts

- A skill that describes a workflow but never says "not done until X" gets walked through by the operator; the fix is the same recite / drive-loop / done-rule shape the newer skills use.
- Read-only tooling (`marathon_plan.py --dry-run --deep`, `swarm-preflight.sh --dry-run`) must sit *inside* the read-only default, not behind a confirmation.
- The relay-xyz guard blocks the skill's own tools until the locator has run once in the session; Step 0 is that proof-of-load and has to be first.
- Missing capture docs are written with the writers that already exist (`hq_render_capture`, `releases roadmap add`), never hand-authored.

## Recon, diagnosis and evidence (base `5e60cb01`)

Observed behaviour: invoking `/marathon-triage` yields an inventory and then a question to the operator before each of (a) writing missing `1-INBOX` capture docs, (b) `swarm-preflight.sh --dry-run`, (c) the planner dry run. Reproduced this session: a direct `bash utils/marathon-plan.sh --dry-run` from a session that had not run the locator was cancelled by the PreToolUse guard with exit 2 and the "relay-xyz guard — STOP" message.

Traced causes:

1. **Shape.** `skills/marathon-triage/SKILL.md` (207 lines) has `## Guardrails` + `## Workflow` steps 0–5. It has none of: `## Recite this` (present in `start-task:34`, `merge-cleanup:14`, `express:29`, `workhorse:27`, `unstuck:34`), a `## Drive loop` (`merge-cleanup:167`), an exit-code ladder, or a `**Done rule**` (`merge-cleanup:188`).
2. **Guardrail wording.** `SKILL.md:21-22`: "Default to read-only. Do not move docs, promote intake, author contracts, close issues, generate a plan file, cut a branch, or fire a marathon without explicit operator confirmation." and `:170-171`: "Running the planner writes a file, so request confirmation before generating or refreshing one." Ground truth: `utils/py/marathon_plan.py:49` — `--dry-run` "Print the report; write no marathon-plan doc"; `:52` — `--deep` "delegate to utils/swarm-preflight.sh --dry-run per ready item"; exit codes `0 clean · 2 usage · 3 ROADMAP unparseable · 4 drift present · 5 items held · 6 gh required-but-absent` (`:57`). `swarm-preflight.sh --dry-run` exits `0/2/3/4/5/6/7` and **publishes nothing** — but it is not side-effect-free: it runs `git fetch --prune` (`utils/py/swarm_preflight.py:1297`), adds a detached temporary worktree at `target.ref` (`:1355-1361`) and removes/prunes it (`:1378-1380`) before the `--dry-run` exit at `:1705-1711`; `--deep` reaches the same path (`_marathon_plan.py:1022-1030`). The correct boundary is therefore "ordinary readiness computation: refreshes remote-tracking refs and uses a transient worktree; writes no packet, no plan file, no doc" — inside the default, described accurately. The confirmation wording fences off exactly that computation.
3. **Guard hook.** `relay-automation/hooks/relay-xyz-guard.sh` derives Tier-A entrypoints from AGENTS.md (`:102-140`; `marathon-plan` is the 12th frozen twin, `swarm-preflight` is Tier-A; Python twins `utils/py/<name>.py` included). Proof-of-load is `Skill(relay-xyz)` **or** any Bash command whose text contains `find-harness.sh` (`:98-100` writes the session marker). The skill's Step 0 locator loop contains that literal, so it *is* proof-of-load — but the skill never says so, and nothing says Step 0 must be the first Bash call. (Qualified: the block fires only in a session with this hook wired and no prior marker; the hook is fail-open and session-scoped, `:24/:33-34`.)
4. **Capture docs.** The skill classifies `NEEDS-CONTRACT` / no-doc issues (`:142-150`) with no recipe to create the capture. `utils/hq/hq.sh park` files a *new* issue (`gh issue create`, `hq.sh:254`); there is no verb for an existing issue. Writers to reuse: `hq_render_capture` (`utils/hq/hq-lib.sh:401-416`, signature `<num> <src> <title> <created> <doc_type> <project> <repo> <request> [cx] [risk] [eff] [phases] [why] [key|concepts] [non|goals] [related]`), `hq_roadmap_line` (`:548`), and `python3 utils/py/releases_app.py roadmap add …` (`hq.sh:339`). This intake was itself produced that way as the control.
5. **Deployment drift.** `diff` of canonical vs `~/git-pulse-sync/Deployed Skills/marathon-triage/SKILL.md`: three hunks (`:20`, `:132`, `:180`) where the deployed copy still says `ROADMAP.md` (retired GH-269). `agents/openai.yaml` and `install.sh` are identical.
6. **Umbrella prerequisite blocks discovery-first triage (found in plan QA R1).** `SKILL.md:66-83` (Step 0b) says "Procedure, before any triage work" and "If you cannot name the umbrella issue, you are not ready to triage" — an unconditional stop that asks for a wave sketch *before* inventory has computed one, and a second reason agents halt on "choose work to swarm next". The umbrella and full-clone rules are execution prerequisites for launching a *selected* marathon, not for triage.
7. **Deep delegation hides per-candidate evidence.** `_marathon_plan.py:1022-1049` runs preflight with stdout/stderr to `DEVNULL` and handles only exits 4/5/6/7, so planner success alone is not a candidate's recorded exit/verdict; per-candidate verdicts must be recorded from direct `swarm-preflight.sh --dry-run` calls.
8. **Planner source (adjacent, #418).** `utils/py/_marathon_plan.py:767-824` reads `releases.db` `roadmap_items` in releases-mode and only falls back to `ROADMAP.md` otherwise; `PROJECT/2-WORKING/MARATHON-PLAN-2026-09-18.md` header says `source: releases.db (roadmap_items)`. #418 looks addressed in code; this plan does not touch it.

Pinning tests: `test/xyz-harness-hooks.sh:61-65` pins the *nudge hook* (prompt → suggests `marathon-triage`), not SKILL.md content. No test asserts SKILL.md text. `ARCHITECTURE.md:63` indexes the skill with a one-line description (unchanged by this plan).

Recurrence: the operator reports hand-driving every invocation; #443 (2026-09-05) describes the same gap from the rating angle ("nothing in the triage → plan → fire path … dry-runs the marathon"). Two distinct reports of one class over ~2 weeks; no data loss, operator time only.

## Task ratings (RELEASES, 2026-09-20)

`rated 65/45/50/85` — **pri 65**: operator-requested now; blocks unattended marathon planning. **sev 45**: no data loss or corruption; every invocation costs operator hand-holding and the stale deployed copy misroutes agents to a retired ledger. **appeal 50**: neutral, not user-supplied. **effort 85** (cheapness): one SKILL.md rewrite plus a Pulse re-publish; no runtime code. No operator `ovr`.

## Scope and reversibility

**Surface:** `skills/marathon-triage/SKILL.md` (rewrite in place), `CHANGELOG.md` (one dated entry), this doc. **No runtime code, no test changes, no new writer.** Deployment: `skills-army-hq` update of the durable collection copy (machine-local, outside git) — the GH-672 SOP.

**Reversibility: Easy** — a reviewed revert of one markdown file and a re-publish of the previous copy.

**Non-goals:** the PRS-rating pass, PRS-ranked planner, `marathon-drive --dry-run` and its test (#443); an `hq park --gh-issue N` verb (follow-up); changing the guard hook; changing `marathon_plan.py` or `swarm-preflight.sh`; closing #418 (verify separately).

## Phase 1 — Rewrite the skill in the drive-loop shape

Ordered work, verification inline:

1. Rewrite `skills/marathon-triage/SKILL.md`, keeping frontmatter `name`/`description` intent and the existing Step 0 locator loop, 0b umbrella, 0c clone rules, classification table, ranking rule and `RECOMMEND/BECAUSE/UNLESS` report shape. Add, in this order:
   - `## Recite this — verbatim, as the first thing in your first response` — five numbered lines (resolve harness & guard → inventory & reconcile → capture missing intake → compute: planner dry run + per-candidate preflight → report with decisions) and an **Overall Goal** line.
   - Step 0 states: "This locator call is the relay-xyz guard's proof-of-load; it must be the first Bash call. Skipping it makes every `marathon-plan`/`swarm-preflight` call exit 2 with `relay-xyz guard — STOP`; the remedy is to run this block, not to ask the operator."
   - Guardrails rewritten: the default **includes** ordinary readiness computation — `marathon_plan.py --dry-run --deep` and `swarm-preflight.sh --dry-run` — described accurately (refreshes remote-tracking refs, uses a transient worktree, publishes no packet/plan/doc) — and the reversible intake writes (capture doc + ledger row through the writer). The confirmation list is exactly promote / close / fire / cut a branch / write the plan file (planner without `--dry-run`). An explicit operator request for a strictly read-only audit is honoured by *reporting proposed captures* instead of writing them.
   - Step 0b/0c rescoped: umbrella issue + `marathon add` + derived full-clone name are prerequisites for **launching a selected marathon**, moved after the report as "before firing"; triage itself (inventory, capture, planner dry run, preflight, report) runs without an umbrella, and umbrella creation/linking appears in the decisions list when not already authorized.
   - New step **"Capture missing intake"** between reconcile and preflight: for each open, in-scope issue with no `GH-<n>-*.md` in `1-INBOX`/`2-WORKING`, render the capture with `hq_render_capture` (sourced from `$HARNESS/utils/hq/hq-lib.sh`), write it to `PROJECT/1-INBOX/GH-<n>-<SLUG>.md`, park it with `releases roadmap add … --raw-text "$(hq_roadmap_line …)"`, read the row back; a failed `roadmap add` is reported as **intake half-complete** (doc exists, no row — `hq.sh:342-345` behaviour), never as success. `NOT-A-WORK-ITEM` issues are excluded and listed. Commit is the operator's call and is listed as one.
   - `## Drive loop` with the exit ladder: planner `0` → continue, `2` → fix the invocation (one retry), `3` → **blocked report** naming the ledger error, `4` → record drift per item and continue, `5` → record held items and continue, `6` → re-run once without `--require-gh` and mark live state `UNKNOWN`, any other code → treat as unknown, never as success; preflight `0/2/3/4/5/6/7` → the classification each maps to, never a stop except `2`. Per-candidate verdicts come from direct `swarm-preflight.sh --dry-run` calls (deep delegation discards output). "Do not stop at the first non-zero; classify it."
   - Two terminal shapes, both reports: a **complete report** and a **blocked report**. `**Done rule:**` do not claim *completion* unless (a) every open issue and every `GH-*.md` doc has exactly one classification, (b) every `READY`/`NEEDS-PROMOTE`/`CONTRACT-STALE` candidate has a recorded preflight exit and verdict, (c) the planner dry-run output is quoted (waves, held, drift), (d) every capture written is listed with its ledger gid. When a requirement cannot be met (planner exit 3, `gh` unavailable, writer refusal), emit a **blocked report** that names the command, exit code, missing evidence and next action — no fabricated waves, no retry loop beyond the one bounded retry. "Asked the operator whether to run preflight" is neither shape; it is a step left undone.
   - Replace every `ROADMAP.md` mention with the RELEASES DB (`releases roadmap list`) — canonical already does; this keeps it that way after the deployed copy is refreshed.
   -> expect `grep -c '^## Recite this\|^## Drive loop\|^\*\*Done rule' SKILL.md` = 3, `grep -c ROADMAP.md SKILL.md` = 0, and the two stop-sentences gone: `grep -c 'request confirmation before generating\|before any triage work\|not ready to triage' SKILL.md` = 0.
2. `CHANGELOG.md`: one entry under today's date naming GH-724, the shape change, the guard-aware Step 0 and the capture recipe; reversibility Easy.
3. Gates in this clone (docs only): `utils/pdda/pdda.sh frontmatter`, `status-table`, `roadmap-coverage`, `changelog` → 0 errors. Hooks suite in a **separate disposable clone**: `bash test/xyz-harness-hooks.sh` → passes (nudge behaviour unchanged). Red controls: (i) structural — delete the `## Drive loop` heading in a scratch copy and confirm the heading grep drops to 2; (ii) behavioural — restore the old sentence "Running the planner writes a file, so request confirmation before generating or refreshing one" into a scratch copy that keeps all three headings and confirm the stop-sentence grep goes to 1 (the mutant is rejected even though the heading count passes). (iii) Reviewer walkthrough in final QA: the Codex reviewer walks the revised text for four scenarios — no umbrella and two unrelated candidates; an issue with no capture doc; an invalid contract (preflight 3); `gh` unavailable — and grades whether the instructions reach the right terminal shape (complete or blocked report) without asking the operator; the current skill's stop-before-preflight behaviour is the failing control.
4. Codex final relay QA on the committed diff; push through the normal pre-push gate; PR into `development` with this doc, the acceptance map and gate evidence.
5. After approval (and again after merge, from the primary): `skills-army-hq` update of `marathon-triage` into the Pulse collection; verify `diff -q skills/marathon-triage/SKILL.md "<collection>/marathon-triage/SKILL.md"` is clean and each app link resolves to the collection copy.

### Phase 1 — QA checklist

- [ ] `SKILL.md` has `## Recite this`, `## Drive loop`, an exit ladder for planner and preflight codes, and a `**Done rule**`.
- [ ] Step 0 names the guard's proof-of-load and the exit-2 symptom; it is the first Bash call.
- [ ] Read-only default explicitly includes `marathon_plan.py --dry-run --deep` and `swarm-preflight.sh --dry-run`; confirmation list limited to promote / close / fire / branch / write plan file.
- [ ] Capture recipe reuses `hq_render_capture` + `hq_roadmap_line` + `releases roadmap add`; no hand-authored frontmatter, no new writer.
- [ ] `grep -c ROADMAP.md` is 0 in canonical and in the deployed copy; `diff -q` clean after deployment.
- [ ] `test/xyz-harness-hooks.sh` passes in a disposable clone; PDDA doc gates 0 errors.
- [ ] Red controls observed failing: heading grep (structural) and stop-sentence grep on the ask-before-planner mutant (behavioural).
- [ ] Step 0b/0c rescoped to marathon launch; triage runs without an umbrella (reviewer walkthrough scenario 1).
- [ ] Complete vs blocked report both defined; planner exit 3 / `gh` unavailable yield a blocked report, not a stop or a fabricated report.
- [ ] Per-candidate preflight verdicts recorded from direct calls, not inferred from planner success.

## Lessons Learned (For Future Agents)

- TBD at close-out.
