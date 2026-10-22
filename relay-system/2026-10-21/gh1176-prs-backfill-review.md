# RELAY · QA: PR #1176 prs-backfill — reviewed PRS rating backfill (GH-1175)
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-21.
-->

NEXT: Reviewer
STATUS: Open
ROUND: 1 / 2

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
6. **Commit only the relay file** (`relay(gh1176-prs-backfill-review): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: `utils/py/prs_backfill.py`
- Scope: PR #1176 (branch feat/gh1175-prs-backfill, head 834ca8dcc) — read these files in
  full in this worktree (they ARE the PR; everything else in the repo is pre-existing):
  - `utils/py/prs_backfill.py` (new, 836 lines — the whole implementation)
  - `skills/2-daily/prs-backfill/SKILL.md`, `prs-backfill.sh`, `install.sh` (new)
  - `CHANGELOG.md` top entry (2026-10-21, GH-1175) and the one `ARCHITECTURE.md` row
  - Context only, do not grade: `utils/py/releases_app.py:3694-3768` (`cmd_roadmap_rate`, the ONE
    writer this tool shells out to) and `skills/1-hourly/start-task/SKILL.md:335-380` (the rating policy).
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-10-21
- Operational envelope: a local, operator-attended CLI run from one checkout (macOS, python3 stdlib,
  `gh` on PATH). Single-instance per repo. No service, no multi-tenant, no cross-host. The ledger
  (`releases.db`) is written ONLY by `releases roadmap rate`; this tool never opens it read-write.
  Repo rule GH-831 (`AGENTS.md`): **no new tests, no new gate machinery** — do not ask for a test
  file; a new test in the diff would itself be a finding.
- Definition of Done (grade against these, cite `file:line`):
  1. **No second writer.** Every ledger mutation goes through `run_rate()` → `releases roadmap rate`
     without `--force` or `--ovr`; `open_ledger_ro()` is the only other DB access and is `mode=ro`.
     Is there any path where this tool writes `releases.db` directly or re-scores an existing rating?
  2. **Approval binding.** `apply` refuses unless `--approve` is a ≥12-hex prefix of
     `sha256(plan.items)` and `plan.json` is untampered. Can a changed proposal reach the ledger under
     an old hash? Can `items` ordering or JSON canonicalisation make two different plans share a hash?
  3. **Freshness before write.** Before each write `apply` re-fetches the issue, holds on
     `closed-since-scan` / `changed-since-scan` (content hash of title/body/labels/comments, not
     `updatedAt`), re-reads the row (ambiguous / already-rated / legacy held). Is there a TOCTOU gap
     that matters at the stated envelope (one operator, one checkout)? Grade commensurately.
  4. **Honest exit and receipts.** A failed write or read-back mismatch → `write-failed` receipt, stop,
     exit 3; a judgment hold (`held`) suppresses re-selection on unchanged `updatedAt`, a `write-failed`
     does not; `--include-held` lifts the filter for an attended re-rate. `--post-rationale` comments
     only after a verified read-back. Trace `cmd_apply` and `cmd_scan` and confirm or refute each.
  5. **E0 blindness.** Calibration packets must carry no ledger score: `build_packet` never includes
     `rating_*`; `strip_rating_lines` withholds the capture doc's `rating:` frontmatter;
     `select_calibration` skips placeholder rows (all axes ≤5, or exactly 50/50/50/50). Any remaining
     leak path (body text, comments, labels) you can point to?
  6. **Policy enforcement in `check_proposal`.** appeal == 50 unless `--appeal-map`; all four axes int
     1–100 (bool rejected); rationale complete and ≤1200 chars; confidence high|medium; rater identity;
     reviewer present, independent (agent+model differ) and `agree` unless `--no-review`. Anything
     the start-task policy requires that this misses, or anything it enforces that the policy does not?
  7. **Locks and kill switch.** `Lock` uses `a+` + flock + truncate-after-acquire; `PRS_BACKFILL_DISABLE=1`
     covers scan/validate/apply/calibrate, not `status`. Correct at this envelope?
  8. **Commensurate complexity.** 836 lines for scan/validate/apply/calibrate/status. Name anything
     that is speculative, duplicated inside the file, or duplicates an existing helper in
     `utils/py/` (you may grep). Do NOT propose new subsystems, schemas, or tests.
  9. **Docs truthfulness.** Does `SKILL.md` describe exit codes, holds, receipts and flags exactly as the
     code behaves? Quote any sentence that is false.
- Non-goals: the hosted/foreman control plane in #1175; registration of unregistered issues (#1022);
  the placeholder-rating ledger defect (#1177); scheduling (#1168). Do not grade those.
- Output: one Reviewer block with `swept file: yes|no`, graded findings each with `file:line` and a
  concrete fix, every `[Blocker]`/`[Should]` behaviour change with `Observed input:` / `Affected scope:` /
  `Falsifier:`, then **VERDICT** (PASS / FAIL / PARKED) and **Basis**. You may run read-only probes
  (`python3 utils/py/prs_backfill.py --help`, `python3 -c ...` against the file) with output under
  `$TMPDIR`; do not run `validate.sh` or `test/*.sh`.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
