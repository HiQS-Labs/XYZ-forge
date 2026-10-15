---
gh_issue: 1077
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1077
title: "close-the-loop: conversation follow-up sweep"
status: In Progress
created: 2026-10-15
updated: 2026-10-15
owner: Codex
goal: "Surface possible forgotten session follow-ups as a numbered report without creating work."
doc_type: feature
---

# GH-1077 — Close the loop

## Status

| What was just completed | What's next |
|---|---|
| Prior art checked; single-file skill drafted and indexed. | Validate, independent QA and publish through the documentation route. |

## Scope and fit

One skill payload: skills/2-daily/close-the-loop/SKILL.md. No scripts, installer, scheduler,
UI metadata, dependency or new tests. Normal index and issue/ledger paperwork accompany it.
The daily index now reflects disk and includes the existing missing daily-planner row.
Easy to reverse by reverting the new skill/index entries. No deployment is included.

Prior art: deployed daily scans device/git work state; sop catches up operational documentation;
relay-to-issue files relay findings. None is the requested current-conversation report-only sweep.
Express is ineligible: this is a new workflow, not a critical hotfix with a registered covering suite.
No express guard changes or invented covering suite. Routine prose implementation is reviewed once
before publication; this is not a claim of a separate pre-implementation plan relay.

## Acceptance and verification

- Payload contains only SKILL.md under the daily folder, with valid identifying frontmatter.
- Numbered candidates retain conversation anchors, target, honest status and smallest next action.
- Cancellations/deferrals, unaccepted ideas, normal pending PRs and missing history do not create
  invented obligations; only named relevant artifacts may be checked read-only.
- Reporting performs no doc/GitHub mutation or task execution; selected actions retain real scope.

Use skill-creator quick_validate and a bounded independent review with representative scenarios.
Use the existing documentation gate; do not add tests or invoke a full runtime suite for this prose.
Task clone was provisioned clean from development before issue assignment under its current prep
name; Spotlight readers prevented the safe rename. Reuse that one known clone rather than duplicate
it. Its only helper will be an independent full verification clone. Current task ownership excludes
all prior tasks and the operator's primary checkout.

Ratings:65/20/50/85 — explicitly requested workflow, bounded reporting risk, neutral appeal, small
prose change. No numeric override or incident growth claim. Context visibility can be partial; the
skill must disclose that limit rather than promise complete recall.

## Clarified handoff-gap requirement

The operator clarified that the sweep must find missing documentation and execution propagation,
not only unkept explicit promises. Example: a technical spike for tomorrow is captured in the
main issue but tomorrow's execution planning doc lacks even a pointer. Trace finding/decision
→ existing source record → next execution consumer; propose a minimal pointer and execution
implication, labeled inferred/possible until checked. Bounded task/date lookup is allowed when
the downstream plan is not already linked. No blanket doc synchronization or automatic writing.

Round1's independent reviewer applied the initial example and returned PASS, but relay-drive
rejected close-mismatch (token released rather than done); it is not an attested approval.
Clarified skill and spike-to-plan example receive cumulative round2/3. No harness repair or new
review machinery is in scope.
