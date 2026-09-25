---
title: "GH-825: handsfree wake and progress skill"
status: Active (2-WORKING — plan QA)
created: 2026-09-25
updated: 2026-09-25
owner: unassigned
goal: let the active agent resume authorized work every 10 minutes for at most 3 hours while asynchronous checks finish
gh_issue: 825
source: https://github.com/HiQS-Labs/XYZ-forge/issues/825
doc_type: enhancement
effort: 2
complexity: 2
risk: 1
phases: 1
---

# GH-825 — handsfree skill

## Status

| What was just completed | What's next |
|---|---|
| Codex plan and final QA approved; skill structure and focused PDDA checks passed | Run the qualifying gate in a disposable full clone, then open PR to `development` |

## Observed state and recon ledger

- Base: `61f09827edcb48bd88c4d67595af2333dca06086` (`origin/development`, 2026-09-25).
- `skills/README.md` and `ARCHITECTURE.md` establish `skills/<tier>/<name>/SKILL.md` as the canonical in-repo skill path and catalog entry. No runtime scheduler is owned by this repo for general task wakeups.
- `skills/1-hourly/relay/SKILL.md` and `skills/1-hourly/relay-xyz/SKILL.md` document Claude `/loop` for relay-specific session polling. This skill must not alter relay's scheduler or driver state.
- Official [OpenAI scheduled-task docs](https://learn.chatgpt.com/docs/automations?surface=app) describe minute-based scheduled tasks inside an existing ChatGPT/Codex app chat; availability in Codex CLI or IDE must not be inferred from that app documentation. Official [Claude Code docs](https://code.claude.com/docs/en/scheduled-tasks) describe `/loop` as session-scoped, with tasks firing while the session is running and idle. Official [Antigravity codelab](https://codelabs.developers.google.com/getting-started-google-antigravity) documents `/schedule` and project scheduled tasks; it does not establish that an Antigravity CLI task resumes the same live chat. The skill must inspect the active harness and prove scheduling destination rather than assume parity.
- `temp/` is gitignored by `.gitignore`; a session note there is local scratch. `PROJECT/**`, issue #825, and actual CI/test results remain authoritative. Date-only naming collides for two sessions on one day.
- Recon mode: instruction/consumer trace; no code state or scheduler writer to refactor. Unknown: availability of a native scheduler in a given live session. Settled at invocation by capability check and schedule receipt, not by a generic claim.

## Decision and scope

Author one portable skill at `skills/1-hourly/handsfree/SKILL.md`, catalog it in `ARCHITECTURE.md`, and record the outcome in `CHANGELOG.md`. The skill asks the *active harness* for a native wake in the same conversation if available. It uses an ignored `temp/handsfree-YYYY-MM-DD-<session-token>.md` note as a collision-safe resume aid. If same-session wake cannot be verified, it reports the limitation and offers the harness's documented native alternative without claiming unattended same-agent continuation. No daemon, shell `sleep` loop, headless agent launcher, or new tests.

**Bet:** skill instructions plus native scheduling are enough for this use case. **Disproof:** a supported harness lacks a same-session wake or the scheduled job survives the stop condition. **Reversibility: Easy:** remove the skill/catalog entry and cancel the native schedule. **Blast radius:** agent instructions and one local ignored note; no repo runtime/CI mutation. A wrong instruction could leave an idle job firing or claim a CI result prematurely; the deadline, receipt check, and evidence gate address that.

## Acceptance and falsification

1. Invoking `handsfree` records the actual task goal, current evidence/source, 10-minute cadence, start and deadline (no later than 3 hours), wake mechanism and job identity in `temp/handsfree-*.md`. Red control: a second session on the same date must not overwrite the first note; the file must be ignored and nonempty. Evidence: task clone inspection, no new test file.
2. A native scheduled wake is created only after the active harness confirms it can resume the current conversation **and can cancel/disable that job**. The agent reports the scheduler receipt and verifies the job exists. Red controls: a harness with no compatible same-chat wake or no cancellation operation leaves the job unarmed; the skill must not promise autonomous resumption. Evidence: plan/final QA review against official docs and available tools.
3. Each wake checks the original goal and live test/CI/PR artifact; it advances the nearest authorized milestone, logs the observed change/next move, and stops on verified completion, required input, hard blocker, or deadline. Red control: a pending result, empty result, or stale SHA cannot be reported as a passing result. Evidence: skill review and existing verification gates.
4. The scheduled job is cancelled in the same session when terminal, and scheduler acknowledgement/readback proves it inactive or absent. If cancellation fails or readback still shows it active, report the live job and manual stop action. Red controls: a deadline alone or an unverified cancellation response must not be claimed to delete a job automatically. Evidence: skill review.
5. No new tests for this skill file. Verify YAML/frontmatter parse, `git diff --check`, and existing relevant repo gates only.

## Plan QA finding and disposition

First Codex review identified a missing cancellation preflight and inactive-job readback. Accepted and added to criteria 2 and 4. It also noted that the OpenAI app scheduling docs cannot establish CLI/IDE availability; added that distinction to the recon ledger. Its relay block failed strict verdict formatting (`**Verdict:** Changes requested` alongside `VERDICT: FAIL`), so the failed receipt is retained in ignored `temp/gh825-plan-invalid-review.md`; a corrected review thread will provide the approval gate.

## Plan QA open question

Which native surfaces actually support returning to *this* conversation versus starting a new background task? Prefer a verified same-chat scheduler; if a surface only supports standalone runs, document that as a separate mode with the note as context, not an equivalent wake.

## Ordered implementation

1. Register the issue, capture and four-axis rating in the RELEASES ledger; promote this plan to `2-WORKING` -> expect unique issue/doc/row readback.
2. Run Codex plan QA through the repo relay harness; resolve material findings -> expect Approved receipt before production skill edits.
3. Add the concise `handsfree` skill and catalog entry, with one ignored note convention and bounded self-cancel protocol -> expect reviewable, single-skill diff.
4. Run structural checks and required gates in a disposable full clone; run final Codex relay QA -> expect passing evidence and Approved verdict for final diff.
5. Push the branch through the gate and open a PR to `development`; inspect target, SHA, diff, and hosted check -> expect ready PR or an accurately reported blocker.

## Rating rationale (2026-09-25)

Proposed `rated 75/35/50/70`: priority 75 because the operator explicitly wants relief from manual CI status nudges; severity 35 because this is workflow friction, with no observed data loss or outage; appeal 50 neutral, no user score; effort 70 because the implementation is a bounded skill plus catalog entry. Recent recurrence trend is unknown: issue search found no exact-title handsfree issue; the relay poll documentation is adjacent behavior rather than a repeat incident. No override.
