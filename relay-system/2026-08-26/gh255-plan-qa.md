---
Goal: QA the GH-255 remediation plan
Date: 2026-08-26
NEXT: Reviewer
STATUS: Open
---

# Context

Adjudicate the remediation plan captured in `PROJECT/1-INBOX/GH-255-ARCHIVE-ROOT-REMEDY.md`
against the code it proposes to change. This is a plan review, not a build turn — do not edit
any file except this relay thread.

Read in full:
- `PROJECT/1-INBOX/GH-255-ARCHIVE-ROOT-REMEDY.md` (the plan)
- `utils/py/marathon_drive.py` around lines 280-310 (the message being changed)
- `relay-automation/CONSUMING.md` lines 48-80 (the `XYZ_ARCHIVE_ROOT` contract, GH-30)
- `relay-automation/marathon.sh` usage/help text where it documents `--target-root`

Background: on a real run against a consuming repo that gitignores `relay-system/` and `phases/`,
the blocked-before-dispatch refusal offered `--target-root` as remedy 1. Following it produced
`relay-drive` exit 2 ("relay file resolves outside the target root ... a build turn has no
writable path for its findings"), whose own suggested remedy is to vendor in place and drop
`--target-root` — a loop. `XYZ_ARCHIVE_ROOT` was never mentioned by either failure.

Questions:

1. **Is the premise correct?** Does `marathon_drive.py`'s blocked-before-dispatch message in fact
   omit `XYZ_ARCHIVE_ROOT`? Cite the exact lines. If it is mentioned somewhere I missed, say so
   plainly — that would invalidate the whole plan.

2. **Is `XYZ_ARCHIVE_ROOT` actually the right remedy for this case?** Read the GH-30 contract in
   `CONSUMING.md`. Does the Phase 3 "full turn redirect" genuinely leave the consuming repo's tree
   free of `relay-system/` while keeping the code artifact and `.tick` token anchored there? Or is
   there a caveat that makes it unsuitable when the blocked paths include `phases/` as well as
   `relay-system/`?

3. **Is the proposed remedy ORDERING right?** The plan demotes `--target-root` to remedy 2. Is
   there a case where `--target-root` is genuinely better than `XYZ_ARCHIVE_ROOT`, such that
   demoting it would misdirect a different class of user?

4. **Is remedy 3 (un-ignore) worth keeping at all?** The message currently argues against its own
   remedy 2 two lines later. Should it be dropped rather than demoted?

5. **Is the self-diagnosing step (plan item 2) implementable where it is proposed?** At the point
   the message is printed, is the set of blocked paths actually available in a form that lets the
   code distinguish "all blocked paths are transcripts" from "some are not"?

6. **Is the test in plan item 4 the right test?** Pinning message text is brittle. Is there a
   better assertion, or is text-pinning correct here given the failure mode is specifically that a
   remedy silently dropped out of a message?

7. **What is missing?** Anything the plan should cover and does not — other call sites that print
   similar remedy lists, docs that would go stale, or a migration concern for existing runs.

Flag anything wrong, missing, incorrectly scoped, or over/under-engineered. Be concrete and cite
file:line where you disagree with a specific claim. Do not soften a real objection.

Write your verdict below. Set `STATUS: Approved` if the plan is sound as written, or leave it
Open with `**Verdict:** Changes requested` and say exactly what must change.

**Verdict:** Changes requested

1. **Is the premise correct?** Yes. `utils/py/marathon_drive.py` (lines 300-305) lists exactly two remedies (`--target-root` and un-ignore) and completely omits `XYZ_ARCHIVE_ROOT`.

2. **Is XYZ_ARCHIVE_ROOT actually the right remedy for this case?** Not always. `XYZ_ARCHIVE_ROOT` only redirects transcripts (under `relay-system/`). It does NOT redirect the `marathon-system/` directory (the `_phase_write_set` which contains `RELAY.md` and `ESCALATION.md`). If the repo ignores both `marathon-system/` and `relay-system/`, setting `XYZ_ARCHIVE_ROOT` will still leave the run blocked because the phase files cannot be tracked. It is unsuitable when the blocked paths include `phases/`.

3. **Is the proposed remedy ORDERING right?** No. Unconditionally demoting `--target-root` is wrong. If a target repo ignores both `marathon-system/` and `relay-system/`, `--target-root` is the ONLY remedy that works. The ordering must be dynamic: if `marathon-system/` paths are blocked, `--target-root` MUST remain remedy 1. `XYZ_ARCHIVE_ROOT` should only be remedy 1 if ONLY transcripts are blocked.

4. **Is remedy 3 (un-ignore) worth keeping at all?** Yes, it is worth keeping. The plan misinterprets the message "Not doing it for you...". The message isn't arguing against the operator manually un-ignoring the paths; it is explaining why the harness didn't silently rewrite the `.gitignore` rules itself (which was the fix for GH-514). It justifies the manual step; it doesn't invalidate it.

5. **Is the self-diagnosing step (plan item 2) implementable where it is proposed?** Yes, but with a caveat. When `commit_root == root`, `preflight_write_set_trackable` is called with the combined `_phase_write_set + _transcript_write_set` list, so it can inspect the `blocked` paths to see if they are exclusively transcripts (e.g., by checking if none are `RELAY.md` or `ESCALATION.md`). However, when `commit_root != root` (lines 2412-2418), the function is called sequentially for phases and transcripts and exits immediately on failure, so it wouldn't have the global view.

6. **Is the test in plan item 4 the right test?** Yes. Since the failure mode is precisely that the remedy was omitted from the refusal message, pinning the message text to assert that the remedy is present is the correct validation.

7. **What is missing?** The plan completely misses that `_phase_write_set` and `_transcript_write_set` are handled differently with respect to `XYZ_ARCHIVE_ROOT`. The plan needs to address how the message should conditionally format its output based on which paths are blocked (e.g., transcripts vs phase files) instead of blindly demoting `--target-root`.

<!-- ▽ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK ▽ -->
▶ TAKE YOUR TURN (agy)
<!-- △ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK △ -->
