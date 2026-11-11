Read everything I need: the three skills in full, the diff, the evidence files, and a YAML parse check at base and head. Writing up the review now.

# GH-1414 / PR #1415 review, Claude Code Opus 5.5 (T3 provider dispatch)

**Reviewed SHA:** `f49972edf9477f8fb7e2f6e3d36413e0357c47a8` (local candidate in `XYZ-forge-gh1414-review-lens-2026-11-10`, not pushed)
**Input boundary:** Stage 1 read only `PROJECT/1-INBOX/GH-1414-PARAPHRASE-FIRST-REVIEW.md`. I had no author conversation history. Stage 2 (source-backed) read `git diff origin/development...HEAD`, the three full SKILL.md files, `TESTS-RESULTS/2026-11-10+GH-1414/*`, `relay-system/2026-11-10/gh1414-skills-wording.codex.md`, `CHANGELOG.md`, the consult skill's isolation notes, and the relay-xyz review-scope section.

## Stage 1: document-only comprehension (recorded before reading any source)

**What this proposes.** A pilot of three ideas taken from Google's Elephant-Goldfish Model, applied to XYZ's existing plan review:
- A fresh reviewer paraphrases the plan before critiquing it. The paraphrase has two parts: "What this proposes" and "How the existing system works, per this document".
- The document-only comprehension pass is kept separate from the later technical review, which reads the actual sources.
- Original findings and their severity are kept next to the author's dispositions.

It adds an optional third heading, "What it's not". Exclusions under it must be grounded in the document, and inferred or unresolved boundaries must be labelled as such. If adopted, the change belongs in `start-task` Step 6.

**How the existing system works, per this document.** `start-task` Step 6 runs a relay plan review with a reviewer packet and a relay receipt. A canonical prompt writer exists and should be inspected before any change. Findings and dispositions already go into the relay receipt, so no new registry is needed.

**What it's not.**
- Not a new approval authority, gate, review driver, mandatory stage, test suite or deployment ("Applying the boundary lens", "Scope and tradeoff").
- Not a replacement for source-backed review.
- Not EGM's full five-stage pipeline or its mandatory human checkpoints.
- Not authority to change acceptance criteria.
- Deferred, not excluded: adoption itself waits on a substantial-plan trial. The doc's Acceptance box "If retained, change only the canonical existing review instructions" makes the skill edit conditional.
- Unresolved per the doc: whether this PR's skill edits run ahead of the "substantial plan" pilot. The doc calls the pilot already performed "an intake demonstration, not the substantial-plan trial". This is my inference from the document. The operator's stated intent authorizes incorporating the change now, so I don't treat it as a finding.

## Stage 2: source-backed technical assessment

### Checks requested by the operator

| Check | Result |
|---|---|
| `/idea` consult preserved: the existing seats, no added seat, round or marker | Preserved, `idea/SKILL.md:135-148`. The lens sits "within those existing consult seats" and the text says "adds no consult seat, review round, approval marker or admission authority". |
| `/idea` issue section order and Acceptance parser | Unchanged, `idea/SKILL.md:81-133`. Step 7 restates the heading order and that Acceptance takes only checkboxes (`:184-185`). The three-part summary goes into the preview, not the body, so the parser never sees it. |
| `/idea` footer hash | The hash command is unchanged (`:153-156`). There is a minor ambiguity about when the body can still be edited; see F2. |
| One confirmation | Preserved, `idea:182`. The summary is "in that same preview". In `file-xyz-bug:88-101`, "Before presenting that same preview" adds no reviewer and no approval checkpoint. |
| Provisional admission | Preserved. No edits touch `idea:12-13,197-202,243`. Line 148 explicitly withholds admission authority. |
| No execution from filing | Explicit: `idea:186-187` and `file-xyz-bug:99-101`. Neither skill invokes `/start-task` while filing. |
| Bug intake stays redacted and filing-only | Yes. The lens reads "the redacted capture" (`file-xyz-bug:89`), after the redaction step at Step 2 (`:77-82`). It forbids inventing a repro, root cause or fix design and grants no "permission to diagnose or fix" (`:94-98`). Guardrails `:222-238` are untouched. |
| Comprehension stays distinct from source-backed validation | Yes. `start-task:197-214` records the paraphrase and its input boundary before sources are supplied, labels the later pass "source-backed", keeps the existing reviewer and round budget, and adds no gate. `idea:145-147` does the same inside the consult. |
| Descriptions parse | I probed with pyyaml (`uv run --with pyyaml`, read-only, scratchpad only). At base, `idea` fails with `ScannerError`: the plain scalar contains "phase: comment". At head, all three parse. `file-xyz-bug` changed `<n>` to `N`, which removes the angle bracket `quick_validate` rejects. `start-task` is unchanged and parses. So f49972ed fixes a real pre-existing parse defect in `idea`. |
| Commensurate complexity | Wording only. No runtime, test, gate or new skill. It meets the rubric. |

### Findings

**F1: Medium (evidence truthfulness). The retained evidence and CHANGELOG are stale against the final head.**
- **Where:**
  - `CHANGELOG.md:9-10`: "start-task skill validation passed; file-xyz-bug retains a reproduced pre-existing description-validator failure."
  - `TESTS-RESULTS/2026-11-10+GH-1414/manual-checks.md:4`: "No claim that this validator passes."
  - `TESTS-RESULTS/2026-11-10+GH-1414/provenance.jsonl:1`: `"file_xyz_bug_validator": "pre-existing failure reproduced on baseline"`, and `skill_diff_sha256` = `942267cc…`.
- **Observed:**
  - Neither file was touched after 671faa3d. e97221f3 changed only `CHANGELOG.md` and `idea`; f49972ed changed only the two descriptions.
  - At head, `file-xyz-bug`'s description has no angle bracket and parses. The operator also reports that `quick_validate.py` passes for all three skills.
  - The independent wording receipt (`gh1414-skills-wording.codex.md`) covers only `start-task` and `file-xyz-bug`, at diff hash `942267cc…`. It does not cover the `idea` change or f49972ed. Yet `CHANGELOG.md:9-10` says "Independent wording QA approved" next to a summary that includes `idea`.
- **Why it matters:** AGENTS.md's proof rules require retained receipts to match the landed head. As committed, the PR would land a false validator claim and an approval receipt whose scope looks wider than it is.
- **Falsifier:** at HEAD, `grep -n "retains a reproduced" CHANGELOG.md` returns no match, `manual-checks.md` records three validator passes, and `provenance.jsonl` names the final diff hash and the `idea` validator result. Any of these failing keeps F1 open.
- **Fix:** update these three files only. Record the three validator passes, the base `idea` parse failure that f49972ed fixed, the narrower scope of the Codex wording receipt, and this review as the receipt covering `idea` and the final head. Remove "retains … failure" from CHANGELOG. This is a text-only fix.

**F2: Low (non-blocking). The `/idea` Step 7 wording could invite body edits after the hash.**
- **Where:** `idea/SKILL.md:183-185`: "keep lasting scope clarification in the existing Plan/Non-goals sections".
- **Observed:** Step 6 (`:149-154`) revises the body and then computes `HASH` over every byte above the footer. Step 7 comes after that. An agent reading the line as "add the clarification to Non-goals now" would change hashed bytes and leave a stale `review: consult … hash` footer.
- **Falsifier:** if the clarification is placed into the body only during Step 6's revision, before the hash, or if a later edit re-runs the Step 5 check and recomputes the hash, the footer stays valid and there is no defect.
- **Suggested wording, if the author agrees:** "(placed during Step 6's revision, before the hash)". This is not required for PASS. Reasonable readers will likely follow Step 6's ordering.

### Observations, not findings
- The input boundary is self-enforced in both flows. The relay reviewer and the consult seats can see the whole tree; consult runs in a throwaway worktree. "Staged in the same turn" relies on the reviewer reading the plan first. The inbox doc explicitly accepts that, so it isn't a defect. The receipt's recorded input boundary is the safeguard.
- The doc says to inspect the canonical prompt writer (`rtl_turn_prompt`) before changing it. No change was made there, and correctly so, because the author's packet in Step 6 is the right owner. No evidence shows it was inspected, but that is immaterial when it wasn't changed.

## Pre-existing defects in the touched flow
The only one I found is the invalid YAML frontmatter in `idea` at base. f49972ed fixes it; F1 asks for the evidence to say so. I found no other pre-existing material defect in `start-task` Step 6, `idea` Steps 5–9, or `file-xyz-bug` Steps 2–4.

## Limitations
- Read-only review. I ran no gates, no `quick_validate.py`, no `validate.sh` and no push gate. The only probe was the pyyaml parse above.
- I did not run any skill end to end, and I did not inspect the hosted PR or its checks; head f49972ed isn't pushed.
- This is a T3 provider dispatch review, not a `relay-drive` CLI attestation.

## Verdict

VERDICT: FAIL
STATUS: Changes requested
Swept file: yes (all three SKILL.md files read in full, plus the diff and the evidence)
Reviewed SHA: f49972edf9477f8fb7e2f6e3d36413e0357c47a8
Safe to land: the skill wording is safe for this scope. All the operator's intent checks pass, and I'd approve the three skill changes as they stand. Don't land until F1's three evidence files are corrected. After that text-only fix, a quick re-check of the new head plus the push gate and the required checks on that exact head is enough. F2 is optional.

PR https://github.com/HiQS-Labs/XYZ-forge/pull/1415, head f49972edf9477f8fb7e2f6e3d36413e0357c47a8, checks and reviews: head not pushed and no hosted checks seen for it; this review is Changes requested (F1 evidence refresh only); push gate not yet run on this head.

Next: Correct CHANGELOG.md:9-10, manual-checks.md:4 and provenance.jsonl for the final head, then request an exact-head re-check.
Also: Optionally tighten idea/SKILL.md:183-185 to say Non-goals clarifications land during Step 6, before the hash.
Also: After the fix commit, push through the docs gate and confirm the required checks pass on that exact head.
