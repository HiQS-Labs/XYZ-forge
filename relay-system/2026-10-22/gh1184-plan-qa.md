# RELAY · Plan QA: GH-1184 daily-planner Stalled & stale section
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-22.
-->

NEXT: Reviewer
STATUS: Open
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
6. **Commit only the relay file** (`relay(gh1184-plan-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: `PROJECT/2-WORKING/GH-1184-STALLED-STALE-SECTION.md`
- Requirements source (read in full first): GitHub issue #1184 — https://github.com/HiQS-Labs/XYZ-forge/issues/1184
  ("How it works", "Defaults", "Out of scope", "Acceptance criteria", "Scheduled morning run" are binding; the
  scheduler itself is #1168's and out of scope here). This is a PLAN review; no code exists yet.
- Ground-truth paths (read, do not grade): `skills/3-weekly/weekly-planner/scripts/planner_core.py` (`main` :1271-1348,
  `get_open_prs` :326-341, `get_open_issues` :259-275, `detect_merge_sequence` :344-486 esp. :399-447, `pivot_daily`
  :718-771, `format_daily_markdown` :1188-1268, team-issue read :911-925), `skills/2-daily/daily-planner/SKILL.md`,
  `utils/py/marathon_drive.py:332-362,1696-1722` (comment find/edit pattern), `utils/py/device_config.py:19-31,120-140`,
  `utils/py/poll.py:74-90`, `skills/2-daily/merge-cleanup/scripts/scan_clones.py:494,525,873-1171`,
  `utils/pdda/check_inventory_ratchet.py:50-85`, `utils/ci-route.sh:40-70`, `utils/py/xyz_mini_sync.py:57-72`,
  `AGENTS.md` (No new tests, GH-831).
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-10-22
- Operational envelope: a local, operator-attended (later: scheduler-invoked, non-interactive) CLI run from one
  checkout on macOS; python3 stdlib; `gh` on PATH. Not a service; one device per run; the other device contributes
  by running the same command itself. **Commensurate complexity:** grade against the issue's acceptance lines and
  this envelope; do not ask for daemons, locks, retries/backoff, schemas or test frameworks. GH-831: no new tests or
  gate machinery — a plan step adding one is itself a finding. GH-777/#1182: a new file under utils/, scripts/ or
  bin/, or any new `sqlite3.connect`, is a finding.
- Definition of Done — answer each with a grade and `file:line` / issue-section citations:
  1. **Grounded?** Does every recon claim match the cited source (engine flags and daily flow, PR/issue fields, hold
     predicates and phase name, team-issue read is read-only, no comment code in P, marathon_drive pattern,
     device_config resolution, scan_clones fetches, ci-route docs/tier 1, ratchet scopes, mini `adapted`)?
  2. **Coverage of the issue:** map each of the 7 acceptance lines + the headless entry point to the design decision
     or step that satisfies it. Which has no credible mechanism? Specifically: AC2 (Held never Stalled — are the
     engine's hold predicates plus labels `hold`/`parked` sufficient, and where do "owner-held decisions" come from?),
     AC3 (two devices/two comments, same-day re-run edits own comment — is device+date in the marker sufficient and
     is the normalized device id stable?), AC4 (gaps never read as "nothing stalled"), AC5 (read-only local scan).
  3. **Extends, no duplicate:** is adding to `planner_core.py` (new `--mode`, collector, formatter, poster) the right
     home versus a new script, given ratchet scope and the "new CLI verbs route through existing entry points" rule?
     Is copying the ~15-line comment find/edit pattern (rather than importing `marathon_drive`) the right call?
  4. **Local scan contract (design 1):** `for-each-ref` + `status --porcelain` only; root discovery via origin URL
     with one hop through local-path origins; merged/closed-PR matching by `headRefName` from one `gh pr list
     --state all --limit 300`. Name the input that breaks it (e.g. a renamed branch, a fork PR, 300+ PRs) and whether
     the plan's coverage rules make that visible.
  5. **Comment contract (design 4):** marker format, PATCH-vs-POST, `--paginate --slurp` reading, the "no report from
     <device> since <date>" derivation, and failure → exit 3 only for the comment write itself.
  6. **Staleness semantics:** is `updatedAt` an acceptable proxy for "no commits, review or comment in N days"?
     Where would it mislead (label churn, bot comments)? Is that acceptable at this envelope or does the plan need a
     cheaper disclosure?
  7. **Rating** `50/30/50/45` (pri/sev/appeal/effort, effort = cheapness; appeal must be 50) — defensible?
  8. **Verification:** the plan records a manual smoke under `TESTS-RESULTS/` with stub `gh`/`git` because no test
     exercises `planner_core.py` and GH-831 forbids a new suite — is that the truthful reading of the issue's
     "covered by an extension to the existing tests" line? Are the smoke scenarios and red controls sufficient and
     falsifiable? Is "full gate in a disposable clone" the right precaution given ci-route says docs/tier 1?
  9. **Non-goals / risk:** anything the plan would build that #1184 excludes (arc, shared body, scheduler,
     dispatch, ledger writes)? Any one-way door? Is forge-only (no mini port) correctly stated?
- Output: one Reviewer block with `swept file: yes|no`, graded findings (`[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`)
  each with a concrete fix; every `[Blocker]`/`[Should]` requesting a change carries `Observed input:` /
  `Affected scope:` / `Falsifier:`; then **VERDICT** (PASS / FAIL / PARKED) and **Basis**. Read-only probes allowed
  (`python3 -c`, `sed -n`, `gh … view/list`), output under `$TMPDIR`; do not run `validate.sh` or `test/*.sh`; do
  not post any comment or create any issue.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer · Round 1 · codex

swept file: yes

**Call: revise before implementation.** Read the entire 208-line plan, including its pre-existing recon, design, rating and verification sections. Findings below exhaust the defects identified in that plan sweep; this is not a review of unrelated defects in the ground-truth code. `P` below means `skills/3-weekly/weekly-planner/scripts/planner_core.py`; `Plan` means `PROJECT/2-WORKING/GH-1184-STALLED-STALE-SECTION.md`.

Evidence boundary: GitHub connector `github_fetch_issue(repo="HiQS-Labs/XYZ-forge", issue_number=1184)` succeeded and supplied the complete open issue, including all seven ACs and the scheduled-run decision. CLI `gh issue view 1184 --repo HiQS-Labs/XYZ-forge --json title,body,state` exited 1: `error connecting to api.github.com`. Graph project `XYZ-forge` is the canonical checkout, not this relay worktree; `check_index_coverage` reports generation `2026-09-01T15:54:30Z`, with P/scan_clones/ratchet not tracked and other relevant paths changed. The symbol search returned no matches. Consequently the source citations below come from direct reads of the seeded files, not an assertion of current graph completeness. No git command, suite, executable fixture, or artifact edit was performed.

- **[Should] F1 — AC2 lacks PR-label data and a complete owner-decision input contract** (Plan:53-61,116-122,169-173). P:332 omits `labels`; retaining that query cannot implement the promised `hold`/`parked` classification. Also P:399-427 recognizes specific PR title/body phrases; it neither reads owner comments nor classifies issue bodies. Calling those predicates “owner decisions already encoded” does not cover all owner-held decisions promised by the issue.
  Observed input: P:332's actual field list ends `files,body,isDraft` and has no labels. Concrete counterexamples are an old ordinary PR whose only hold signal is `labels=[{"name":"hold"}]`, and an operator-assigned old issue whose body says `Owner decision: hold until product sign-off` with no hold label. These are input examples, not claims that such live items were queried.
  Affected scope: held PRs/issues whose hold is a label or explicit owner decision outside the existing PR regexes.
  Falsifier: feed those two inputs plus an ordinary idle item to the eventual manual smoke; both held inputs must appear only under Held, and the ordinary item under Stalled. A documented owner-decision representation/source that actually reaches the collector would resolve the second gap.
  Fix: explicitly extend the PR field list with labels; specify the smallest supported owner-decision source/representation for PRs **and issues**, including how any unsupported/unread decision source is disclosed. Add those examples to the recorded smoke, rather than introducing a general natural-language decision engine.
  Read-only probe: `python3 -c 'from pathlib import Path; p=Path("skills/3-weekly/weekly-planner/scripts/planner_core.py"); s=p.read_text().splitlines(); print(s[331]); print("resolved note:",Path("PARKED/2026-09-29-xyz-mini-sync.md").read_text().splitlines()[23])'` exited 0; decisive PR output: `"--json", "number,title,author,headRefName,baseRefName,mergeable,reviewDecision,reviews,updatedAt,statusCheckRollup,files,body,isDraft"`.

- **[Should] F2 — Do not age out unpublished local branches** (Plan:123-131; issue “How it works” §2). The window restriction is required for notes, but the issue does not restrict unpushed work to recent commits. The proposed `no upstream and a commit in the window` drops the forgotten work this feature is meant to recover.
  Observed input: the Plan:127 predicate excludes a `for-each-ref` row with branch `fix/forgotten`, empty upstream/track fields and committer date `2026-10-01T12:00:00-07:00` on the October 22 run.
  Affected scope: no-upstream local branches older than the lookback window.
  Falsifier: the old unpublished branch remains visible with its date and a cautious inspect/push suggestion; an otherwise equivalent recent branch remains visible too.
  Fix: remove the recency cutoff for unpublished branch candidates, or explicitly report that older branches are excluded as a coverage limitation; reserve the notes window for notes. Include an old branch in the smoke.

- **[Should] F3 — A name match is a retirement candidate, not proof of safe retirement** (Plan:128-134; issue “How it works” §2, AC5). The selected `headRefName,state,number` projection cannot distinguish reused branch names or fork heads. A successful list below 300 therefore still has semantic uncertainty that the current failure/truncation rules never display. Cached tracking refs also cannot establish current remote push status without fetching.
  Observed input: local branch `fix/report` with an extra unpublished commit, and PR rows `[{"number":10,"headRefName":"fix/report","state":"MERGED"},{"number":11,"headRefName":"fix/report","state":"OPEN"}]`; the name-only retirement predicate matches #10 even though the branch still carries work. A fork's closed `fix/report` creates the same collision.
  Affected scope: local retirement suggestions derived only from branch names and unpushed conclusions derived from cached upstream refs.
  Falsifier: the reused/fork-name cases must not say “safe to retire”; a unique merged-name match may be shown as a candidate requiring cleanup verification. Renamed/unmatched branches must remain visible as unmatched, and 300 PR rows must retain the planned truncation gap.
  Fix: retain the bounded read-only scan, but explicitly label name matches as unverified retirement candidates and route the next action to the existing merge-cleanup verification; disclose cached-ref/name-match limits in coverage. Do not add fetches, ancestry machinery or deletion to this feature. One-hop local-origin discovery is reasonable; an unresolved second hop must be a visible gap rather than silently absent coverage.

- **[Should] F4 — Exclude resolved notes and metadata files** (Plan:129-131; issue “How it works” §2 requires notes “not marked resolved”). Only relay `Approved|Closed` filtering is specified; `PARKED/*.md` includes resolved pointers and `README.md`.
  Observed input: `PARKED/2026-09-29-xyz-mini-sync.md:24` says `- **Resolved 2026-09-29:**` and :28 says `Kept as a pointer.` If touched during the chosen window it passes the plan's PARKED predicate. `PARKED/README.md:1` is folder guidance, not an open session note.
  Affected scope: recently touched PARKED notes already resolved/promoted, plus folder metadata matched by the glob.
  Falsifier: a recent unresolved note is listed; an otherwise recent resolved note and README are absent. Unknown note status must not be presented as established open work.
  Fix: define a small resolved/promoted-note filter using the existing note conventions (`PARKED/README.md:17`) and exclude metadata files; record the example in the smoke. Do not execute note contents or their `check`/`close` fields. The F1 probe above exited 0 and printed the cited `Resolved 2026-09-29` line.

- **[Should] F5 — Make the status read genuinely non-writing** (Plan:125-126,153-154,195-197). Plain `git status --porcelain` can refresh/write the index. The proposed before/after status and reflog comparison does not detect that mutation. Git's [BACKGROUND REFRESH documentation](https://git-scm.com/docs/git-status#_background_refresh) explicitly describes this and recommends disabling optional locks.
  Observed input: Plan:126's exact `git status --porcelain` invocation on a checkout whose cached index stat information needs refresh; output can remain identical while index bytes change. This is a documented failure path, not a git experiment performed in this turn.
  Affected scope: every checkout scanned by the status command, particularly later scheduled/background runs.
  Falsifier: in the disposable smoke checkout, change tracked-file stat information without changing its content, capture index bytes before scanning, then show identical index bytes afterward and unchanged reported dirtiness.
  Fix: specify `git --no-optional-locks status --porcelain` (or `GIT_OPTIONAL_LOCKS=0`) and add the index observation to the existing manual smoke. No additional gate machinery is needed.

- **[Should] F6 — Specify actual red controls and nonempty observations** (Plan:184-208; AGENTS.md:107-125,154-166). Stub error inputs and the existing before/after checks are useful planned scenarios, but `any fetch|prune|push|checkout in the log fails` only states an assertion; it does not witness that assertion failing. Likewise an empty captured comment passes the sentinel-absence check.
  Observed input: an empty captured body satisfies Plan:198-199's “sentinel absent” check; an empty argv log satisfies Plan:197's forbidden-command check.
  Affected scope: the manual receipt used to substantiate AC5 and the claimed verification completion.
  Falsifier: the clean nonempty body/log passes, while an intentionally contaminated body containing the sentinel and a scratch copy of the argv log containing a forbidden mutation each make their respective check fail.
  Fix: require successful capture and nonempty expected report/command evidence before assertions; specify these two deliberate red observations and their retained commands, statuses and output under the same `TESTS-RESULTS/.../provenance.jsonl` receipt. Also exercise the F1–F5 inputs, comment-list failure (no blind POST), comment-write failure (exit 3), and a prior-day device marker. Keep this a recorded manual check, not a new suite.

- **[Nit] N1 — Describe `updatedAt` as a proxy, not an exact activity ledger** (Plan:119-120). Keeping this cheap timestamp is proportionate; GitHub's own [stale action](https://github.com/actions/stale) uses update time as its idle signal. Label/metadata churn can hide human inactivity, and bot comments count as activity. Fix: disclose that the report measures GitHub update age and may miss human stalls after metadata/bot activity; avoid claiming exact equivalence to “no commits, review or comment.” No timeline crawler is requested.

- **[Pass] Grounding and reuse, with the exceptions above.** P:1271-1320 matches the flags, unconditional PR/sequence call, UTC naming and daily files; P:732-742 establishes the baseline requirement and closure reads; P:259-275 and :326-341 match issue/PR fields and limit handling. P:399-447, :451-486 and :1120 establish hold predicates, precedence, prerequisite demotion and Phase 5. P:911-925 is a read-only team-issue read; comment posting is absent from the source read of P. `marathon_drive.py:332-362,1696-1722` supplies pagination flattening and PATCH/POST; its :19-22 imports justify copying the small pattern rather than importing the driver. `device_config.py:19,120-140` supports the planned resolver; `poll.py:74-90` supports header reads. `scan_clones.py:494,525` fetches, so retaining a separate small read-only collector is justified. `check_inventory_ratchet.py:50-85` scopes script inventory to utils/scripts/bin and SQLite scanning more broadly; extending P with no new connect is the right home. `ci-route.sh:63-70` routes this non-core skill path as docs/tier 1. `xyz_mini_sync.py:57-72` establishes adapted ownership. Retain these choices. Machine-specific inventory counts in Plan:73-77 were not remeasured and should remain dated reconnaissance, not current completeness evidence.

- **[Pass] Comment design and operational scope, subject to the failure smoke.** Plan:143-152's device+local-date marker, paginated comment read and PATCH-vs-POST meet same-day reruns/two-device separation within this single-run-per-device envelope. Lowercasing/stripping `.local` is deterministic for an unchanged configured id; document that the scheduler/manual command use the same stable per-device id (hostname fallback changes if the host is renamed). Prior comments establish only previously seen devices, not a never-reporting Mac. Retain the known-device/latest-date derivation; rebuild the current device's date as today when composing its new report. Treat failed comment discovery as a publication failure (exit 3, no blind POST), while unrelated collection gaps remain visible with exit 0, as Plan:132-150 intends.

**Acceptance mapping and DoD disposition** (all references to the [issue](https://github.com/HiQS-Labs/XYZ-forge/issues/1184) mean its numbered Acceptance criteria):

| Requirement / DoD | Grade | Design/step and disposition |
|---|---|---|
| AC1: section, dates, reasons/actions | [Pass] design | Plan:112-115,135-138,169-178 define row fields, JSON and section 5; retain. |
| AC2: Held never Stalled | [Should] | Plan:121-122; resolve F1 and exercise label/owner holds, not just HOLD titles. |
| AC3: two Macs / own same-day edit | [Pass] design | Plan:143-150,188-190; retain marker and PATCH contract; runtime still unverified. |
| AC4: failures/truncation as gaps | [Pass] design | Plan:132-134,193-194; retain. Wrap P:1289's initial fetch and issue/closure reads before they can abort the report; keep existing other modes' semantics. |
| AC5: read-only local scan / no secrets | [Should] | Plan:123-134,195-199; resolve F2–F6. |
| AC6: no new SQLite / no ledger writes | [Pass] design | Plan:153-154,169-173; retain existing connection unchanged and keep stalled mode out of weekly intake. |
| AC7: extend existing coverage, no new suite | [Pass] policy resolution / [Should] smoke | Plan:200-208 explicitly discloses the manual-smoke substitution. Read-only search of 457 test source files found planner skill references only in `test/gh589-xyz-mini-sync.sh:62,95-126` and zero direct `planner_core` references; no existing planner behavior suite was found in that bounded scope. AGENTS.md:154-166 permits recorded manual evidence. Describe this as a disclosed substitution, not literally a test extension; resolve F6. |
| Scheduled scan-only entry point | [Pass] design | Plan:139-142,176-178: no weekly baseline/pivot; #1168 owns missed-run/skipped scheduling and enabling. Prior-device gaps come from :149-150; retain and smoke a prior-day marker. |
| DoD 1–3: recon / coverage / extension | [Pass] with F1 | Source checks above; extend P and copy the small comment pattern. |
| DoD 4–6: local / comment / staleness | [Should] local; [Pass] comment design; [Nit] proxy | F2–F5, comment assessment, N1. A 300-row result is already a visible gap; rename/fork/name-reuse uncertainty currently is not. |
| DoD 7: rating | [Pass] | Plan:156-162 explains 50/30/50/45 with effort as cheapness and appeal 50. No reason to change it. |
| DoD 8: verification | [Should] | Resolve F6. Plan:181-183's full gate in a separate disposable clone is appropriate despite docs/tier 1 classification. **[Unverified — needs clone run]** All runtime/smoke/gate claims remain pending; none ran this turn. |
| DoD 9: non-goals / risk / mini | [Pass] | Plan:15-20,107-108,153-154,167 excludes arc/shared body/scheduler/dispatch/ledger writes and mini port. Easy reversal is credible; no one-way door is proposed. Retain. |

Root cause at plan level: the proposed collector lacks some required classification inputs and treats limited local evidence as stronger than it is; fix site: Plan design 1 and manual-smoke step 4; these are the origin contracts to settle before implementing, without a new subsystem.

**VERDICT: FAIL**

**Basis:** The small extension to P is appropriate and most recon is grounded, but AC2 and parts of the local/verification contracts are not yet credible as specified. F1–F6 are bounded plan corrections; no observed runtime implementation failure is alleged and no new tests/gates/frameworks are requested. After dispositions and plan edits, return the same artifact for round 2.

Handing off to Producer (claude-a) — address each finding, update the plan and take the next turn.

### Producer · Round 1 → 2 · claude-a

All seven accepted; design decision 1 and smoke step 4 of the plan are rewritten. Dispositions:

- **F1 — Implemented.** `labels` is added to `get_open_prs`'s `--json` list (the engine ignores extra keys). The
  recognised-holds set is now enumerated: (a) the engine's hold/evidence-carrier predicates, (b) labels `hold`/`parked`
  on PRs and issues, (c) a body line `(?im)^\s*(?:owner decision|decision)\s*:\s*hold\b` on PRs and issues. Comment-only
  holds are not read; the coverage block says so verbatim. Your two counterexamples are in the smoke.
- **F2 — Implemented.** Unpublished branches (`ahead N` or no upstream) are listed regardless of age with their
  committer date; the window applies to notes only. A 3-week-old no-upstream branch is in the smoke.
- **F3 — Implemented.** Name matches render `retire? name match — verify with /merge-cleanup`, never "safe to
  retire"; `ahead` is labelled `as of last fetch`; cached-ref and name-match limits are standing coverage
  disclosures; a root whose origin is unresolved after one hop is a visible gap. No fetch, no ancestry machinery.
- **F4 — Implemented.** Only dated `PARKED/YYYY-MM-DD-*.md` files count; `README.md`/`PARKED.md` never; a note with a
  `- **Resolved`/`Resolved:`/`Promoted:`/`Closed:` line is excluded (PARKED/README.md:14-17 convention); relay threads
  with `STATUS: Approved|Closed` excluded; `check`/`close` fields never executed. Examples in the smoke.
- **F5 — Implemented.** `git --no-optional-locks status --porcelain`; smoke captures `.git/index` bytes before/after a
  stat-only touch.
- **F6 — Implemented.** Smoke now requires non-empty captured body / argv log before asserting, and has two deliberate
  red observations (sentinel-contaminated body; argv log with one `fetch` line); adds comment-list failure (no blind
  POST, exit 3), comment-write failure (exit 3) and a prior-day marker for another device.
- **N1 — Implemented.** `updatedAt` is described and printed as a proxy (GitHub update age), with the bot/metadata
  caveat; no timeline crawl.

Handing off to Reviewer codex — re-grade DoD 1–9 against the revised plan and set Approved or list what remains; go
to the Reviewer window and say 'take your turn'.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
