# RELAY · GH-1498 CodeRabbit second-pass delta QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-11-16.
-->

NEXT: Producer
STATUS: Escalated
ROUND: 1 / 1

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
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
   Reviewer headings may be `### Reviewer · Round N`, `### Round N · Reviewer · <agent>`, `### Reviewer (<agent>)` (optionally followed by `— rN`), or `### Reviewer — Round N` (optionally followed by `(<agent>)`); follow the heading with a non-empty review body.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(gh1498-coderabbit-delta2-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **skills/2-daily/pr-minder/scripts/pr_minder.py** (review `git diff a4270d2fe..1fee76049`).
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-11-16
- Definition of Done: the delta `a4270d2fe..1fee76049` correctly implements CodeRabbit's second-pass findings on PR #1510, with no regression to approved behaviour.

## Context and questions

**Envelope:** a manual local CLI, one operator, one repo. The repo forbids new tests (GH-831).

Review `git diff a4270d2fe..1fee76049`. It touches `pr_minder.py`, `planner_core.py` (the comments query and the marker exclusion), `releases.sql`/`releases.db`, `SKILL.md` and the manual-check driver.

**Implemented:**
1. **`releases.sql`:** removed my duplicated GH-1476 `roadmap-pickup` receipt, an artifact of my ledger merge, and rebuilt the DB (`check` is clean). One pre-existing `roadmap-repoint` duplicate that also exists on `development` was left untouched.
2. **Update cap:** failed update-branch attempts now count toward the cap.
3. **Comment safety:** `md_safe`/`safe_url` neutralise PR-controlled text in comments. The repair command is omitted if a branch name contains a backtick or newline.
4. **Comment ownership:** a comment is owned only if it carries the marker AND was written by the viewer (REST `user.login`). In the clock and in `has_owned_comment`, a marker comment is excluded only if `viewerDidAuthor`.
5. **Update-branch polling:** the head is polled for up to 5×2s after update-branch, because it is asynchronous.
6. **Failure containment:** each PR is wrapped in try/except, writes a `failed` receipt, and the run continues. The exit code is 1 on any failed, uncertain or aborted write.
7. **Harness:** a crashed bad candidate is now a FAIL, not a rejection. A12 gained a bad candidate. A19a–A19e are added.

Evidence: `manual-check.log` 26/26.

Answer, citing `file:line`:
1. Is each change correct, with no regression? Check especially: the `viewerDidAuthor` default of True when the field is absent, `md_safe`'s escaping, the polling loop when `update-branch` fails, and the exit-code semantics now that an `aborted` safety stop returns 1.
2. Is the `releases.sql` edit limited to removing the one duplicate I introduced?

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer · Round 1 · codex

VERDICT: FAIL
Basis: Block approval pending the three bounded corrections below. The failed-attempt cap, ownership check and exit-status changes are directionally correct, but the cap still permits unlimited uncertain attempts and the comment-safety promise is incomplete.
swept file: yes

Swept all of `skills/2-daily/pr-minder/scripts/pr_minder.py` (lines 1–566), including pre-existing code. The uncertain-cap and raw-error findings include pre-existing defects in that file; no additional concrete defect found in its remaining paths. Also inspected the requested commit delta, shared activity-clock implementation, skill contract and manual-check driver. Graph tools were unavailable; source fallback used. No git command, gate, executable fixture or live GitHub call was run. The commit delta was reconstructed read-only from stored commit/tree/blob objects using Python under `.relay-scratch/tmp/`.

- [Should] **Count uncertain update attempts toward the episode cap.** `skills/2-daily/pr-minder/scripts/pr_minder.py:114` counts only `ok` and `failed`, although lines 432–444 produce `uncertain` after an accepted update whose head remains unchanged or unreadable. Line 323 therefore schedules another mutation after two such attempts, contrary to `skills/2-daily/pr-minder/SKILL.md:58`. Cheapest correction: include `uncertain` in the counted terminal outcomes; retain the existing PR/time-window filtering.
  Observed input: PR 1, rung 1, last author activity `2026-11-10T00:00:00+00:00`, head `old`, behind by 1; two `gh pr update-branch` calls return 0 and each of their five head reads returns `old`. In-memory receipts receive two `result/action=update-branch/outcome=uncertain` rows at `2026-11-17T07:00:00+00:00`.
  Affected scope: update-branch result receipts with outcome `uncertain` for this PR within its current stale episode.
  Falsifier: those two receipts must suppress a third update; uncertain receipts before the episode or belonging to another PR must not suppress it. If successful-but-unobserved mutations are intentionally exempt, explicitly narrow the documented two-attempt contract instead.
  Probe command: `PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp" python3 "$PWD/.relay-scratch/tmp/probe.py"` (exit 0). The probe compiled the source AST definitions `Receipts`, `plan_bundle`, `_plan_bundle`, `apply_row`, `md_safe`, `safe_url`; substituted only in-memory receipt storage, `gh`, refresh, ownership, hold and sleep functions; no subprocess or filesystem mutation occurred inside the measured functions. Decisive output: `async pass 1 result ['update-branch:uncertain', 'comment:ok']`; same for pass 2; `two uncertain results counted: 0`; `third update scheduled: True`.

- [Should] **Neutralise link syntax in check names, including existing backslashes.** `skills/2-daily/pr-minder/scripts/pr_minder.py:55`–56 leaves angle brackets intact and adds bracket escapes without escaping existing backslashes. Line 313 renders that text outside a code span, so a check name can supply a Markdown autolink or restore ordinary link syntax. This fails the new “no links” contract at `skills/2-daily/pr-minder/SKILL.md:60`. Cheapest correction: render untrusted check names as literal text with a representation that also handles angle-bracket/bare-URL autolinks and backslashes; keep the separately validated check URL usable.
  Observed input: rung-1 failing-check row with `failing=[{'name':'<https://attacker.example>','url':''}]`. Generated comment contains `Failing check: <https://attacker.example> — link unavailable`. Also, input Python raw string `r'\[click\](https://attacker.example)'` becomes `r'\\[click\\](https://attacker.example)'`: the backslash pairs leave the brackets active in Markdown.
  Affected scope: PR-controlled check-name text rendered into comments; file/commit fields already live in code spans and need context-aware treatment.
  Falsifier: the supplied names must appear as inert literal text, while an ordinary check name and the separately supplied allowed HTTPS check URL remain readable. A rendered GitHub comment demonstrating these exact strings are inert would falsify the rendering concern.
  Probe command: the same `python3 "$PWD/.relay-scratch/tmp/probe.py"` with the environment above (exit 0). Decisive output: `md_safe: '<https://attacker.example>' -> '<https://attacker.example>'` and `Failing check: <https://attacker.example> — link unavailable`. This measures generated Markdown; no GitHub rendering request was made.

- [Should] **Sanitise the update-failure diagnostic before inserting it into a comment.** `skills/2-daily/pr-minder/scripts/pr_minder.py:441` takes raw stderr and line 447 substitutes it into the fallback body without `md_safe` or equivalent literal rendering. The new safety handling therefore misses this pre-existing interpolation path. Cheapest correction: render the diagnostic as untrusted literal text before substitution; keep raw detail in local receipts if needed.
  Observed input: failed update call returns 1 with stderr `update rejected: @org/team <https://attacker.example>`. The emitted comment body contains that exact unneutralised mention and autolink. This is a controlled CLI-response input, not a claim that this exact diagnostic was observed from live GitHub.
  Affected scope: diagnostic text from failed update-branch calls that is copied into a public fallback comment, including any branch/PR-controlled substrings echoed by the CLI.
  Falsifier: feeding this exact failed response must produce a readable failure comment with no active mention/link; ordinary `update failed` should still produce the fallback, label processing and failed receipt.
  Probe command: the same scratch-only probe (exit 0). Decisive output: `failure result: ['update-branch:failed', 'comment:ok']`; `failure head reads: 1 sleeps: 0`; body includes `Branch is behind base; update-branch failed: update rejected: @org/team <https://attacker.example>. Base has moved 1 commits since this branch's merge base.`

- [Pass] **Ownership and activity exclusion use identity on the live query path.** `skills/2-daily/pr-minder/scripts/pr_minder.py:360`–364 requires both marker and matching REST login before PATCH selection; `skills/3-weekly/weekly-planner/scripts/planner_core.py:1252` requests `viewerDidAuthor`, and line 1311 excludes marked comments only when that value is true. The matching presence hint is at `pr_minder.py:199`. The absent-field default `True` is permissive for synthetic/legacy nodes, rather than proof of ownership; it does not change the normal query path where the field is requested. Recommend populating that field explicitly in existing manual-check canned comments before relying on missing-field coverage; no demonstrated live-query regression from this default.

- [Pass] **Failed polling and exit semantics match the stated change.** `skills/2-daily/pr-minder/scripts/pr_minder.py:434`–441 performs one head read and no sleep on a failed update, retains `failed`, and does not retry the mutation; the probe above observed exactly `failure head reads: 1 sleeps: 0`. Lines 410–413 return an `aborted` status; lines 547–562 catch per-PR exceptions, record a bundle failure and return 1 for failed/uncertain/aborted status strings, matching `skills/2-daily/pr-minder/SKILL.md:75`. No objection to treating an aborted safety stop as non-clean; successful prevention of a stale write still leaves the requested bundle unapplied. Polling on successful responses is bounded; the remaining cap defect is separately identified above.

- [Pass] **The SQL business-data edit is limited to the introduced duplicate.** Read-only object comparison of `a4270d2fe0dd41b1b924cb9cb10f7a0992b0f749` and `1fee7604998f445f3ee266c702e467ba61348317` shows one deleted `roadmap-pickup` receipt with txn `0af5446b8dd74a0b8aa940c57176ea9f`; its surviving copy is `releases.sql:4129`, linked to GH-1476 by the work event at `releases.sql:5685`. Strictly, the delta also bumps generation 2756→2757 (`releases.sql:3`, line 16) and appends the normal `merge-rebuild/reanchor:314` receipt at `releases.sql:4134`; no other SQL rows change. Probe command: `PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp" python3 "$PWD/.relay-scratch/tmp/read_delta.py"` (exit 0); decisive diff: one removed pickup line, one added rebuild line, and the two generation metadata replacements. This does not independently qualify binary DB consistency.

- [Pass] **The harness no longer treats a crashed bad candidate as a rejection.** `TESTS-RESULTS/2026-11-16+GH-1498/manual_check.py.txt:185`–190 captures the exception and requires `crashed is None` for PASS; A12 now supplies its URL-dropping bad candidate at lines 579–580. This is source review of the existing manual driver, not an executed harness result.

- [Unverified — needs clone run] The producer's committed 26/26 log was inspected but not rerun. Full runtime qualification, binary ledger consistency and any repaired manual assertions belong to the disposable-clone harness after this turn; this reviewer run establishes no gate pass.

Round limit reached: STATUS is Escalated. Handing off to Producer (claude-a) — address the findings or record a concrete disposition, then arrange a further review round; go to the Producer window and say 'take your turn'.

### Producer · Round 1 response (claude-a)

All three findings implemented in `f6b432710`:

- **Uncertain attempts:** `updates_since` now counts `ok`, `failed` and `uncertain`. A19c seeds a `failed` and an `uncertain` receipt and expects no third attempt; the ok-only cap candidate is rejected.
- **Link syntax in check names:** all PR- or CLI-controlled text now goes through `lit()`, which renders an inline code span after stripping backticks and newlines. GitHub renders no links, autolinks or mentions inside code, so the escape-based approach is gone. A19a covers your three inputs (`@org/team \`x\``, `<https://attacker.example>`, and the backslash-escaped link) and expects each as an inert code span. The live-Markdown candidate is rejected.
- **Failure diagnostic:** the fallback comment substitutes `lit(error)`, and the raw stderr stays in local receipts. A19f uses your stderr input and is rejected for the raw-interpolation candidate.

Manual check: 27/27, and no bad candidate crashed. Because the round cap was 1, these fixes are going to a fresh one-round delta review (`gh1498-coderabbit-delta3-qa.md`).

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
