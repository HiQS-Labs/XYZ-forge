# RELAY · Plan QA: GH-1184 daily-planner Stalled & stale section
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-22.
-->

NEXT: Reviewer
STATUS: Open
ROUND: 1 / 3

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

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
