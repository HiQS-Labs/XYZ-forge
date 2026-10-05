# RELAY · GH-789 port plan QA (+#965)
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-05.
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
6. **Commit only the relay file** (`relay(gh-789-port-plan-qa-965): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: `PROJECT/2-WORKING/GH-789-MERGE-CLEANUP-AUTONOMOUS-PIPELINE.md` (the port plan).
  Source being ported: commit `08bb0655` (base `f1321d6d`), diff `git diff f1321d6d 08bb0655 -- skills/2-daily/merge-cleanup/`.
  Both commits are reachable in this clone only if fetched; the plan quotes the relevant facts. Issues:
  https://github.com/HiQS-Labs/XYZ-forge/issues/789 and https://github.com/HiQS-Labs/XYZ-forge/issues/965.
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-10-05
- Definition of Done: the plan is grounded in today's `development` code paths, scopes the port correctly (phase one
  + #965, not GH-786), resolves the two named conflicts without dropping dev behaviour, keeps GH-831 (no new tests or
  capability rows), and its manual matrix + red controls would actually catch each behaviour failing.

**Operational envelope.** Single-operator local merge tool, core skill (full gate on push). Grade against the plan's
stated scope. Do not ask for new test suites, new capability rows, retries, telemetry or a generic Markdown parser.

**Paths to read in this clone:** the plan; `skills/2-daily/merge-cleanup/scripts/{merge_cleanup,ledger_merge,scan_clones,toposort_prs}.py`;
`skills/2-daily/merge-cleanup/SKILL.md` (capability table + Drive loop); `test/gh534_phase_c_tests.py` (`TestParityGuard`,
`parity_failures`); `AGENTS.md` "No new tests". Plus the port source, retrievable read-only with
`git fetch https://github.com/HiQS-Labs/XYZ-forge.git` — it is NOT on GitHub; read the saved patch at
`.relay-artifacts/gh789-code.patch` (seeded read-only by the driver; the unified diff `f1321d6d..08bb0655` for the four scripts and SKILL.md).

**Questions.**
1. Are the plan's claims about today's code right: `refresh_pr` / `fetch_open_prs` lack `isDraft`; the hold-label skip,
   GH-851 post-push head wait and `PUSH_GATE_TIMEOUT_S` exist where the conflict notes say; `inspect_primary_landing`
   treats a lone `REBASE_HEAD` as an active rebase (`scan_clones.py` ~line 1167)? Cite lines.
2. Does the conflict-resolution plan keep every behaviour `development` gained since `f1321d6d` (GH-851 head wait,
   GH-852 MERGED re-query, `--resume`, attempt records, soft edges)? Name anything the patch would silently revert.
3. Is leaving out the two new capability rows correct under the parity guard, and is anything else in the patch
   (e.g. `gh534_phase_c_tests.py` +3) needed to keep an existing suite truthful?
4. Would the manual matrix cases (a)–(g) and the two red controls fail if the behaviour were wrong? Anything missing
   for #965's acceptance (Phase 4 Draft column; drafts named in summary; run not stopped)?
5. Is the `merge-cleanup-deep` intake (`scan_clones --json`) safe with the REBASE_HEAD change?
6. Anything over- or under-built? Cite `file:line`.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
