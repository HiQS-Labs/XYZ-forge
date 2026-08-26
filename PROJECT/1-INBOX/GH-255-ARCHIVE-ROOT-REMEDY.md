---
title: marathon-drive's blocked-before-dispatch refusal omits XYZ_ARCHIVE_ROOT
status: Proposed (1-INBOX — not yet active)
created: 2026-08-26
owner: noel
gh_issue: 255
source: https://github.com/HiQS-Labs/XYZ-forge/issues/255
doc_type: bugfix
complexity: 1
risk: 1
effort: 1
phases: 1
ratings_provisional: true
reported_from: rebalanceOS
harness_commit: b051cab4
non_goals:
  - Changing what the gate blocks on, or relaxing GH-514's refusal. The refusal is correct; only the remedies it offers are incomplete.
  - Auto-setting XYZ_ARCHIVE_ROOT on the operator's behalf. Naming the knob is the fix; choosing an archive location is the operator's call.
related:
  - GH-256 (found on the same run; the two failures compound — this one misdirects, that one wastes a round cap silently)
  - GH-30 (built XYZ_ARCHIVE_ROOT; this is that feature failing to be discoverable at the moment it is needed)
goal: >
  An operator or agent that hits the blocked-before-dispatch refusal on a repo which deliberately
  ignores relay-system/ is pointed at XYZ_ARCHIVE_ROOT first, with a runnable export line, instead
  of being steered into --target-root and failing a second time.
---

# GH-255 — the refusal names every remedy except the one that fits

> **1-INBOX capture**, not the active-work doc — no `## Status` table yet. On promotion to
> `PROJECT/2-WORKING/`, add the status table + per-phase QA gates and carry `gh_issue` forward
> (`PROJECT/PDDA.md` → GitHub issue intake).

## Why

`utils/py/marathon_drive.py:300-306` prints two remedies when a repo cannot track files the run
must commit. `XYZ_ARCHIVE_ROOT` is not one of them, despite `relay-automation/CONSUMING.md:52`
being titled "Optional: keep transcripts OUT of repo B (`XYZ_ARCHIVE_ROOT`, GH-30)" — an exact
description of the repo the refusal fires on.

The cost is not theoretical. On a real run the message steered three consecutive attempts into
dead ends (`--target-root` → relay-drive exit 2 → back to vendored-in-place), and the supported
knob was never surfaced by any of them. An LLM agent will follow the error text literally, so a
message that omits the right answer does not merely fail to help — it actively misdirects.

## Key concepts

- **The refusal is right; the remedies are wrong.** GH-514 correctly refuses before spending a
  builder turn. This is a message defect, not a policy defect.
- **Remedy 2 argues against itself.** It offers "un-ignore the path", then two lines later says
  "a repo that ignores harness output usually means it". A message should not offer advice it
  immediately undercuts.
- **Ordering is the payload.** The blocked paths are already known at print time. When they are
  all under `relay-system/`, that is precisely the `XYZ_ARCHIVE_ROOT` case and can be stated
  rather than guessed at.

## Remediation

> Revised after agy QA (relay-system/2026-08-26/gh255-plan-qa.md). The first draft proposed
> demoting `--target-root` unconditionally. That is wrong, and the correction is the substance of
> this plan: `XYZ_ARCHIVE_ROOT` redirects the TRANSCRIPT write-set only. Verified at
> `utils/py/marathon_drive.py:2374-2375` — `_phase_write_set` is `[relay_file, ESCALATION.md]`
> under `marathon-system/`, and `_transcript_write_set` is separate. A repo that also ignores
> `marathon-system/` is still blocked with the archive set, and there `--target-root` is the only
> remedy that works.

1. **Order the remedies by what is actually blocked**, rather than by a fixed ranking:
   - blocked paths are **all transcripts** → `XYZ_ARCHIVE_ROOT` is remedy 1, with a runnable
     export line; `--target-root` is 2.
   - blocked paths include any **phase** file (`RELAY.md` / `ESCALATION.md` under the phases dir)
     → `--target-root` stays remedy 1, and the message states plainly that `XYZ_ARCHIVE_ROOT`
     will NOT clear this case. Offering it there would send the operator into a second failure,
     which is the exact defect this issue is about.
2. **Give the message the global view it needs to make that call.** At
   `marathon_drive.py:2412` the combined list is passed and the distinction is available. At
   `2416-2418` the `commit_root != root` path calls `preflight_write_set_trackable` twice and
   exits on the first failure, so it never sees both sets. Either pass a set-kind label into the
   check, or collect both results before printing, so the remedy text is correct on both paths.
3. **Keep the un-ignore remedy.** The first draft proposed dropping it, on the reading that the
   message argues against itself. It does not: "Not doing it for you" explains why the harness
   declines to rewrite someone's `.gitignore` automatically (GH-514), it does not discourage the
   operator from doing it deliberately. Keep it as the last remedy.
4. **Reconcile `marathon.sh --help`**, which recommends `--target-root` for repos that ignore
   "marathon-system/ and relay-system/". That text is correct for the both-ignored case and
   misleading for the transcripts-only case. Name both knobs and which case each fits.
5. **Pin the remedy text with a test**, one case per branch: transcripts-only must mention
   `XYZ_ARCHIVE_ROOT` first; phase-files-blocked must NOT offer it as the primary remedy. Text
   pinning is brittle in general but correct here, because the failure mode is precisely a remedy
   going missing from a message.

## QA record

Reviewed headless by agy on 2026-08-26, verdict **Changes requested**, all seven findings
accepted and folded in above. The load-bearing one — that `XYZ_ARCHIVE_ROOT` does not cover
`marathon-system/` — was independently verified against `marathon_drive.py:2374-2418` before
being accepted. Thread: `relay-system/2026-08-26/gh255-plan-qa.md`.
