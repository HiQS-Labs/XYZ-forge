# RELAY · GH-943 independent QA — loader-limit trims + merge-cleanup batch-issue protocol
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-02.
-->

NEXT: Producer
STATUS: Approved
ROUND: 2 / 2

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
6. **Commit only the relay file** (`relay(gh943-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **.relay-artifacts/gh943-relay-diff.patch** — the read-only path that
  `relay-drive.sh --artifact-file /Users/noelsaw/Documents/GH Repos/XYZ-forge/temp/gh943-relay-diff.patch` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: claude   ·   Producer: claude-a
- Started: 2026-10-02
- Definition of Done: PR #943 (branch fix/gh-942-skill-desc-1024-limit, commits e728e741+4d66ab89) is independently QA-clean:
  (a) the three trimmed skill descriptions fold to <=1024 chars while preserving trigger phrases and exclusions;
  (b) the merge-cleanup batch-issue protocol is internally consistent with the existing drive loop, Phase C ladder, and parity-guard capability table, and contradicts no repo rail (GH-831 no-new-tests, GH-564 disposable-clone, containment);
  (c) ledger/pointer-doc changes are sane;
  (d) nothing weakens an existing safety guarantee.
Operational envelope: local developer CLI skill docs (XYZ-forge). Commensurate complexity — no enterprise threat models. XYZ-forge policy: NO new test suites is CORRECT there (GH-831); asking for one is itself a finding.

## Reviewer questions (answer each, with file:line or quoted spans)
1. Fold-count each trimmed description in the diff (radar, 10days, express, merge-cleanup): is any still over 1024 folded chars? A read-only python probe under $TMPDIR is allowed (GH-681).
2. Do the trimmed descriptions keep the trigger phrases front-loaded and the "not for" exclusions? Name any loss that would break skill-consumer matching.
3. Is the "Batch issue protocol (GH-944)" section consistent with the drive loop, the Phase C caller ladder, and the capability table (caller-owned rows only; no script changes; CLI option list untouched)? Cite any contradiction.
4. Does the protocol keep issue-posting non-blocking and containment intact? Does anything in the diff weaken an existing safety guarantee?
5. Are the two pointer docs and the releases.sql roadmap rows consistent with the issues they capture?
6. Commensurate complexity: flag over- or under-engineering anywhere in the diff.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer · Round 1 (claude)

swept file: no

No review of PR #943 was performed this turn. The artifact was not seeded into this worktree, and
the session ran out of budget before a fallback read was possible. Nothing below is a judgement on
the diff itself; reviewer questions 1-6 are all unanswered.

- **[Blocker] Artifact named in Setup is absent from the isolated worktree.**
  Command (from worktree root): `wc -lc .relay-artifacts/gh943-relay-diff.patch` →
  `wc: .relay-artifacts/gh943-relay-diff.patch: open: No such file or directory`; the fold-count
  probe then died with `FileNotFoundError: [Errno 2] No such file or directory:
  '.relay-artifacts/gh943-relay-diff.patch'` (rc=1).
  `ls -la .relay-artifacts` shows exactly one file, from a different relay:
  `gh182-claim-guards.md  24.2K`.
  The seed source does exist: `/Users/noelsaw/Documents/GH Repos/XYZ-forge/temp/gh943-relay-diff.patch  32.1K`.
  Observed input: this worktree's `.relay-artifacts/` holding `gh182-claim-guards.md` instead of `gh943-relay-diff.patch`.
  Affected scope: any `relay-drive.sh --artifact-file` run whose worktree ends up with a stale or foreign `.relay-artifacts/`.
  Falsifier: re-seed and run `ls .relay-artifacts/gh943-relay-diff.patch` in the reviewer worktree — if it lists the 32.1K patch, this finding is cleared and was a one-off seeding miss.
  Fix: re-run the driver so the gh943 patch is actually seeded (or re-point Setup at a path that exists in the worktree), then re-fire the Reviewer turn. No artifact change is requested of the Producer.

- **[Unverified — not reviewed] DoD (a)-(d) and reviewer questions 1-6.** The 1024-char fold counts
  were never measured (the probe did not run against any input). Protocol consistency, containment,
  ledger/pointer-doc sanity, and safety-guarantee checks were not started. I did not read the patch
  from the source path outside the worktree: the session budget could not cover a whole-file read of
  a 32.1K diff plus the skill files it touches, and a partial read would not support a verdict.

- Pre-existing defects in the touched files: not swept, so none can be reported either way.

**VERDICT: PARKED**
**Basis:** The review could not start — the seeded artifact is missing (a foreign gh182 file sits in
its place) and the reviewer session's budget was exhausted before a fallback. This is a harness /
seeding problem, not a finding against PR #943. The round is consumed without a review; the next
Reviewer turn needs the artifact present and a fresh budget.

Handing off to Producer (claude-a) — go to the Producer window and say "take your turn": re-seed
`.relay-artifacts/gh943-relay-diff.patch`, log a disposition for the Blocker, and return the turn
to the Reviewer. No change to the diff is being asked for.

### Producer · Round 1 (claude-a)

- **[Blocker] Seeded artifact missing** — Implemented (driver invocation fix, no artifact change):
  the Round-1 drive call omitted `--artifact-file`, so `relay-drive.sh` never seeded the worktree —
  `.relay-artifacts/gh182-claim-guards.md` is a pre-existing tracked leftover in the repo, not this
  relay's seed (falsifier confirmed from the Producer side: the source patch exists at
  `temp/gh943-relay-diff.patch`, 32.1K). Re-fired with `--artifact-file` so the fresh worktree seeds
  `gh943-relay-diff.patch`; the Reviewer's own falsifier check (`ls .relay-artifacts/gh943-relay-diff.patch`)
  should now clear it.
- Reviewer budget for Round 2 raised so the whole-file read correctly declined in Round 1 is
  affordable within the turn.
- No change requested or made to the reviewed diff (PR #943 commits e728e741+4d66ab89 unchanged).

Handing off to Reviewer (claude) — take your turn with the seeded artifact.

### Reviewer · Round 2 (claude)

swept file: yes

Scope of the sweep: the whole 369-line patch, plus the pre-change `skills/2-daily/merge-cleanup/SKILL.md`
lines 140-240 (Phase 5/6, drive loop, Phase C ladder, capability table) and the parity guard at
`test/gh534_phase_c_tests.py:522-599`. Caveat: this worktree's `releases.sql` reads
`-- generation: 1301` while the patch base is 1396, so the worktree is older than the PR base;
ledger checks below are made against the patch text, not the tree. No suite was run.

Round-1 Blocker: **cleared.** `wc -lc .relay-artifacts/gh943-relay-diff.patch` → `369 32821` (rc=0), 7 `diff --git` headers.

**Q1 — fold counts (DoD a)**
- **[Pass] All four descriptions fold under 1024.** Probe: read-only python over the patch, joining the
  new-side description lines with single spaces (rc=0). Output:
  `express old 1131 → new 1015` · `10days old 1570 → new 1015` · `radar old 1336 → new 1001` ·
  `merge-cleanup old 352 → new 527`. A `>` scalar keeps one trailing newline, so express and 10days
  are 1016 under a YAML loader; radar uses `>-`. Largest UTF-8 byte count is 1016. Cross-check: PyYAML
  on the worktree's pre-change files gave 1132 / 1571 / 1336 / 352, matching the old counts quoted in
  the pointer doc (patch line 42-49: "1570", "1336", "1131").

**Q2 — triggers and exclusions (DoD a)**
- **[Pass] express** keeps all three triggers in the first sentence (patch line 152-153: `/express, "express this hotfix", or "express GH-N"`) and the exclusion (line 174: "Do not use for Costly or one-way-door changes"). The full refusal list survives (lines 171-173).
- **[Pass] radar** keeps every exclusion (patch line 364-366: "Not for shipped recaps (weekly-shipped), marathon ranking (start-marathon), or maturity assessment (/honest); never executes fixes (/10days does that)").
- **[Pass] 10days** keeps `"/10days"` and `"run the 10 day sweep"` (patch line 325) and the §8 exception (line 323-325).
- **[Nit] Triggers are not front-loaded in radar and 10days.** The pointer doc's own recipe says "front-loading trigger wording in the first ~250 chars" (patch line 54), but radar's "Trigger when" starts near char 560 and 10days' "Trigger on" near char 720. Both sit inside the 1024 limit, so nothing is dropped by the loader. Fix if wanted: move the trigger sentence to position 2.
- **[Nit] Three radar trigger phrases were cut**: "what have we actually been doing", "summarize radar reports", "what should we fix once to stop the bleeding" (patch lines 348-350 removed). The 10days verbatim canned request (lines 310-312) became a paraphrase (line 326-327). No exclusion was lost. Cut detail still lives in the bodies (`rg -c -F '.xyz/'` on 10days → 3; `rg -c -F 'events/'` on express → 2).
- **[Pass] No existing test pins the removed wording.** `rg -F` under `test/` for `~/.config/xyz/events/`, ``explicit `resume` subcommand``, `dry-run across`, `Product Release System (PRS) 4-axis`, `Under the hood`, `what have we actually` → `0 matches`, rc=1 (a real no-match; no GNU-only flags used).

**Q3 — protocol consistency (DoD b)**
- **[Pass] Drive-loop pointer resolves.** The step-3 link (patch line 206) `#batch-issue-protocol-gh-944--caller-owned-for-queues-of-three-or-more` is the GitHub slug of the new heading at patch line 215 (the em dash drops out, leaving the double hyphen).
- **[Pass] Named sources match the existing skill.** Attempt-record path (patch line 233) equals `SKILL.md:147`; the three gates (lines 234-235) equal `SKILL.md:152-157`; "exit 2/3 included" (line 225) matches `SKILL.md:148`.
- **[Pass] Capability table and CLI list.** Four rows added with owner `caller` and pin `—` (patch lines 283-286), the same shape as `code-conflict-recon` (`SKILL.md:233`). The CLI option line is context-only (patch line 288). The guard only requires a pinned test when `owner == "script"` (`test/gh534_phase_c_tests.py:586`), so the new rows cannot trip it. No new test suite is asked for or added — correct under GH-831.
- **[Should] The table's own promise is untrue for the four new rows.** `SKILL.md:214` says the guard "fails if a row, its owner, its test, or a listed CLI option disappears", but the guard iterates a fixed set.
  Observed input: `REQUIRED_CAPABILITIES` at `test/gh534_phase_c_tests.py:527-540` contains none of `batch-issue-threshold`, `batch-issue-resume-append`, `batch-regression-sweep`, `post-deploy-carryover-dual-sink`; its own comment at line 536-537 names this exact gap ("a row that the guard does not demand can be deleted from SKILL.md with the parity test still green").
  Affected scope: any capability row present in SKILL.md but absent from `REQUIRED_CAPABILITIES`.
  Falsifier: delete one new row from SKILL.md and run `TestParityGuard` in a disposable clone — if it goes red, this finding is wrong. Expected: stays green.
  Fix: add the four names with owner `"caller"` to the existing dict (an edit to an existing suite, not a new one). Pre-existing, same class: `mergeable-unknown-poll` and `exclude-drops-pr` (`SKILL.md:236-237`) are also absent from the dict in this worktree's copy — [Unverified — needs clone run] against the PR base.
- **[Should] The resume search key is not in the issue template.**
  Observed input: patch line 226-228 says search open `merge-batch` issues "for this run's date and integration branch", but the template (lines 256-257) carries date, owner/repo and PR list — no integration branch. The pointer doc says "repo+date" (line 97), a third wording.
  Affected scope: any `--resume` continuation, especially one run on a later calendar day (`SKILL.md:184-185` tells the caller to "re-run once the network is healthy").
  Falsifier: a resume the day after a deferred batch finds the original issue by the documented key. Expected: it does not, and a second issue is minted.
  Fix: add an `Integration branch:` line to the template and match on branch + overlapping PR list rather than on date.
- **[Nit] Threshold wording vs timing.** The issue opens "before the first `gh pr merge`" (patch line 223-224), yet "deferred, parked, handed-off" PRs are excluded from the count (line 221-222) — those are Phase 5 outcomes not known yet. Only `--exclude` and hold-label skips are knowable then. Fix: say the count is taken from the Phase 4 sequence after `--exclude`, and that a resume inherits the original batch's issue.
- **[Nit] Done rule untouched.** The Overall Goal now says batches are "documented and swept" (patch line 196) but the Done rule (`SKILL.md:189-191`) does not mention the sweep, and "tier-appropriate suite" (line 240) is not defined in this file. Fix: one clause in the Done rule saying whether an unrun sweep blocks Done.

**Q4 — non-blocking, containment, safety (DoD d)**
- **[Pass] Non-blocking is explicit**: "the issue is a record, not a gate" (patch line 229-230) and "nothing in the landing sequence waits on GitHub issue state" (line 218).
- **[Pass] Disposable-clone rail held**: "run the tier-appropriate suite **in a disposable full clone** — never the primary (GH-564)" (patch line 240-241).
- **[Pass] No production action**: "Transcribe only: merge-cleanup never executes production verification" (patch line 248-249); "never auto-closes it" (line 250-251).
- **[Pass] No existing guarantee is weakened.** Every `-` line in the merge-cleanup hunks is one of: the description (line 184), the Overall Goal (line 195), and "3. **Execute:** add `--execute`." (line 204) — each replaced by a superset. Phase 0 refusal, B1, the two-repair cap, Trash-only teardown and reconciliation gating are untouched context.

**Q5 — ledger and pointer docs (DoD c)**
- **[Pass] Ledger rows are internally consistent.** Generation 1396 → 1398 for exactly two `roadmap-add` receipts (patch lines 105-106, 132-133); the digest chain is unbroken (`d88ca3e6…` → `f6884f2f…` → `00b434aa…`); each `work_events` `txn_id` matches its receipt (`17722aba…`, `37d3cbef…`); both rows point at `PROJECT/1-INBOX/` docs that the patch creates. Whether `releases_app.py check` is green on the result is [Unverified — needs clone run].
- **[Should] GH-942 pointer doc is stale against its own PR** (doc-only, no behaviour change). Patch line 31 says "radar trimmed … as the first instance" and lists "10days, express" under what's next; line 42 and 49 list 10days and express as still over. Commit e728e741 trims all three (patch lines 143-176, 290-329). Fix: move 10days and express to the completed column, mark their list entries fixed, and leave six remaining (five, feynman, front-door, readme-audit, spike-360, timbre) plus the re-vendor step.
- **[Unverified — needs clone run] `PAGES/skills.html` may drift.** `PAGES/skills.html:210` quotes the old radar triggers ("what should we fix once to stop the bleeding") and the page is built by `utils/py/site_build.py`; the patch does not regenerate it. Whether a gate compares the page to the descriptions was not measured.

**Q6 — commensurate complexity**
- **[Pass] Right-sized.** Docs-only, caller-owned, no script or CLI change, no new suite. The one existing length check is `test/test_deploy_skills.py:558` (`assertLessEqual(len(description), 1024)`, swe only); the pointer doc already parks the generalised guard as optional on an existing suite (patch line 59-60). Nothing over-built.

Pre-existing defects in touched files: one, reported above (guard's required set lags the table). None found in the pre-change express/10days/radar frontmatter beyond the over-limit lengths this PR fixes.

**VERDICT: PASS**
**Basis:** DoD (a) measured — all four descriptions fold to ≤1016 chars with every exclusion and primary trigger kept. (b) the protocol contradicts no rail (GH-831, GH-564, containment) and matches the drive loop, ladder and table shape. (d) no safety guarantee is removed. (c) the ledger rows chain correctly. Three `[Should]`s remain and none blocks landing: a stale status row in the GH-942 pointer doc, a resume search key missing from the issue template, and four table rows the guard does not demand. These are follow-ups for the Producer, cheapest fixed before merge. Two items could only be measured in a disposable clone and are graded Unverified, not passed.

Relay closed (Approved), no further turn needed. Producer (claude-a): the three `[Should]`s are yours to apply or park on PR #943.


### Attestation · relay-drive — 2026-10-03T05:46:45Z
task: RELAY-gh943-qa
reviewer: claude
status: Approved
reviewed-head: a8cac21185eef9e754b4d853d2a4c00288b66921
added-range: 10885+10392
added-sha256: 04bf7fa23d9e4ce1e3023161e18655ad9f22070725b67941ebabd7829d48b25e
<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
