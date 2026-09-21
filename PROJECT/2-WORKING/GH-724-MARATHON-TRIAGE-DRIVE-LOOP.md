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
| Intake captured, parked and rated (65/45/50/85); recon of the skill, the relay-xyz guard hook, the planner CLI and the intake writers recorded below; surgical plan drafted | Codex relay plan QA; then rewrite `skills/marathon-triage/SKILL.md`, run the doc gates and the hooks suite, final relay QA, PR into `development`; deploy the reviewed copy to the Pulse collection with `skills-army-hq` |

## Quad Concepts

- A skill that describes a workflow but never says "not done until X" gets walked through by the operator; the fix is the same recite / drive-loop / done-rule shape the newer skills use.
- Read-only tooling (`marathon_plan.py --dry-run --deep`, `swarm-preflight.sh --dry-run`) must sit *inside* the read-only default, not behind a confirmation.
- The relay-xyz guard blocks the skill's own tools until the locator has run once in the session; Step 0 is that proof-of-load and has to be first.
- Missing capture docs are written with the writers that already exist (`hq_render_capture`, `releases roadmap add`), never hand-authored.

## Recon, diagnosis and evidence (base `5e60cb01`)

Observed behaviour: invoking `/marathon-triage` yields an inventory and then a question to the operator before each of (a) writing missing `1-INBOX` capture docs, (b) `swarm-preflight.sh --dry-run`, (c) the planner dry run. Reproduced this session: a direct `bash utils/marathon-plan.sh --dry-run` from a session that had not run the locator was cancelled by the PreToolUse guard with exit 2 and the "relay-xyz guard — STOP" message.

Traced causes:

1. **Shape.** `skills/marathon-triage/SKILL.md` (207 lines) has `## Guardrails` + `## Workflow` steps 0–5. It has none of: `## Recite this` (present in `start-task:34`, `merge-cleanup:14`, `express:29`, `workhorse:27`, `unstuck:34`), a `## Drive loop` (`merge-cleanup:167`), an exit-code ladder, or a `**Done rule**` (`merge-cleanup:188`).
2. **Guardrail wording.** `SKILL.md:21-22`: "Default to read-only. Do not move docs, promote intake, author contracts, close issues, generate a plan file, cut a branch, or fire a marathon without explicit operator confirmation." and `:170-171`: "Running the planner writes a file, so request confirmation before generating or refreshing one." Ground truth: `utils/py/marathon_plan.py:49` — `--dry-run` "Print the report; write no marathon-plan doc"; `:52` — `--deep` "delegate to utils/swarm-preflight.sh --dry-run per ready item"; exit codes `0 clean · 2 usage · 3 ROADMAP unparseable · 4 drift present · 5 items held · 6 gh required-but-absent` (`:58`). `swarm-preflight.sh --dry-run` exits `0/2/3/4/5/6/7` and writes nothing. The confirmation wording therefore fences off two read-only tools.
3. **Guard hook.** `relay-automation/hooks/relay-xyz-guard.sh` derives Tier-A entrypoints from AGENTS.md (`:102-140`; `marathon-plan` is the 12th frozen twin, `swarm-preflight` is Tier-A; Python twins `utils/py/<name>.py` included). Proof-of-load is `Skill(relay-xyz)` **or** any Bash command whose text contains `find-harness.sh` (`:98-100` writes the session marker). The skill's Step 0 locator loop contains that literal, so it *is* proof-of-load — but the skill never says so, and nothing says Step 0 must be the first Bash call.
4. **Capture docs.** The skill classifies `NEEDS-CONTRACT` / no-doc issues (`:142-150`) with no recipe to create the capture. `utils/hq/hq.sh park` files a *new* issue (`gh issue create`, `hq.sh:254`); there is no verb for an existing issue. Writers to reuse: `hq_render_capture` (`utils/hq/hq-lib.sh:401-416`, signature `<num> <src> <title> <created> <doc_type> <project> <repo> <request> [cx] [risk] [eff] [phases] [why] [key|concepts] [non|goals] [related]`), `hq_roadmap_line` (`:548`), and `python3 utils/py/releases_app.py roadmap add …` (`hq.sh:339`). This intake was itself produced that way as the control.
5. **Deployment drift.** `diff` of canonical vs `~/git-pulse-sync/Deployed Skills/marathon-triage/SKILL.md`: three hunks (`:20`, `:132`, `:180`) where the deployed copy still says `ROADMAP.md` (retired GH-269). `agents/openai.yaml` and `install.sh` are identical.
6. **Planner source (adjacent, #418).** `utils/py/_marathon_plan.py:767-824` reads `releases.db` `roadmap_items` in releases-mode and only falls back to `ROADMAP.md` otherwise; `PROJECT/2-WORKING/MARATHON-PLAN-2026-09-18.md` header says `source: releases.db (roadmap_items)`. #418 looks addressed in code; this plan does not touch it.

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
   - Guardrails rewritten: the read-only default **includes** `marathon_plan.py --dry-run --deep` and `swarm-preflight.sh --dry-run`; the confirmation list is exactly promote / close / fire / cut a branch / write the plan file (planner without `--dry-run`).
   - New step **"Capture missing intake"** between reconcile and preflight: for each open, in-scope issue with no `GH-<n>-*.md` in `1-INBOX`/`2-WORKING`, render the capture with `hq_render_capture` (sourced from `$HARNESS/utils/hq/hq-lib.sh`), write it to `PROJECT/1-INBOX/GH-<n>-<SLUG>.md`, park it with `releases roadmap add … --raw-text "$(hq_roadmap_line …)"`, read the row back. `NOT-A-WORK-ITEM` issues are excluded and listed. Commit is the operator's call and is listed as one.
   - `## Drive loop` with the exit ladder: planner `0` → continue, `2` → fix the invocation, `3` → report the ledger as unreadable and stop, `4` → record drift per item and continue, `5` → record held items and continue, `6` → re-run without `--require-gh` and mark live state `UNKNOWN`; preflight `0/2/3/4/5/6/7` → the classification each maps to, never a stop except `2`. "Do not stop at the first non-zero; classify it."
   - `**Done rule:**` no report unless (a) every open issue and every `GH-*.md` doc has exactly one classification, (b) every `READY`/`NEEDS-PROMOTE` candidate has a recorded preflight exit and verdict, (c) the planner dry-run output is quoted (waves, held, drift), (d) every capture written is listed with its ledger gid. "Asked the operator whether to run preflight" is not a terminal state.
   - Replace every `ROADMAP.md` mention with the RELEASES DB (`releases roadmap list`) — canonical already does; this keeps it that way after the deployed copy is refreshed.
   -> expect `grep -c '^## Recite this\|^## Drive loop\|^\*\*Done rule' SKILL.md` = 3 and `grep -c ROADMAP.md SKILL.md` = 0.
2. `CHANGELOG.md`: one entry under today's date naming GH-724, the shape change, the guard-aware Step 0 and the capture recipe; reversibility Easy.
3. Gates in this clone (docs only): `utils/pdda/pdda.sh frontmatter`, `status-table`, `roadmap-coverage`, `changelog` → 0 errors. Hooks suite in a **separate disposable clone**: `bash test/xyz-harness-hooks.sh` → passes (nudge behaviour unchanged). Red control: temporarily delete the `## Drive loop` heading in a scratch copy and confirm the acceptance grep drops to 2 (the check can fail).
4. Codex final relay QA on the committed diff; push through the normal pre-push gate; PR into `development` with this doc, the acceptance map and gate evidence.
5. After approval (and again after merge, from the primary): `skills-army-hq` update of `marathon-triage` into the Pulse collection; verify `diff -q skills/marathon-triage/SKILL.md "<collection>/marathon-triage/SKILL.md"` is clean and each app link resolves to the collection copy.

### Phase 1 — QA checklist

- [ ] `SKILL.md` has `## Recite this`, `## Drive loop`, an exit ladder for planner and preflight codes, and a `**Done rule**`.
- [ ] Step 0 names the guard's proof-of-load and the exit-2 symptom; it is the first Bash call.
- [ ] Read-only default explicitly includes `marathon_plan.py --dry-run --deep` and `swarm-preflight.sh --dry-run`; confirmation list limited to promote / close / fire / branch / write plan file.
- [ ] Capture recipe reuses `hq_render_capture` + `hq_roadmap_line` + `releases roadmap add`; no hand-authored frontmatter, no new writer.
- [ ] `grep -c ROADMAP.md` is 0 in canonical and in the deployed copy; `diff -q` clean after deployment.
- [ ] `test/xyz-harness-hooks.sh` passes in a disposable clone; PDDA doc gates 0 errors.
- [ ] Red control for the heading grep observed failing.

## Lessons Learned (For Future Agents)

- TBD at close-out.
