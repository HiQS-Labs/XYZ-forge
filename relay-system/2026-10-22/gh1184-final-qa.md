# RELAY · Final QA: GH-1184 daily-planner Stalled & stale implementation
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
6. **Commit only the relay file** (`relay(gh1184-final-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: `skills/3-weekly/weekly-planner/scripts/planner_core.py`
- Also in the diff (read in full): `skills/2-daily/daily-planner/SKILL.md`, `skills/3-weekly/weekly-planner/SKILL.md`
  (one sentence), `TESTS-RESULTS/2026-10-22+GH-1184/` (receipt: `SUMMARY.md`, `smoke-results.txt`, `smoke.sh`,
  `stub-run-*.log`, `live-run-*.md/json`, `provenance.jsonl`), `PROJECT/2-WORKING/GH-1184-STALLED-STALE-SECTION.md`
  (the Approved plan: decisions and smoke contract this code must match). Diff base: `origin/development` @ `eb0623ce`;
  the implementation commit is `b3138992`, receipt `88bd3091`. In the engine, the new code is the block between
  `# ── Stalled & stale (GH-1184)` and `def format_daily_markdown`, plus `get_open_prs`'s field list, the tail of
  `format_daily_markdown`, and `main` (new flags, `--mode stalled`, daily wiring).
- Requirements: GitHub issue #1184 — https://github.com/HiQS-Labs/XYZ-forge/issues/1184 (acceptance criteria are
  binding; the scheduler is #1168's). Plan QA for this work was Approved in `relay-system/2026-10-22/gh1184-plan-qa.md`.
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-10-22
- Operational envelope: a local, operator-attended (later scheduler-invoked, non-interactive) CLI run from one checkout
  on macOS; python3 stdlib; `gh` on PATH; one device per run. Not a service. **Commensurate complexity:** grade against
  the issue's acceptance lines and the Approved plan; do not ask for daemons, locks, retries, schemas or test
  frameworks. GH-831: no new tests or gate machinery — a new `test/` file or `validate.sh` entry in the diff is a
  finding (there is none; the smoke is a recorded manual check with scratch stubs). GH-777/#1182: a new file under
  `utils/`, `scripts/` or `bin/`, or any new `sqlite3.connect`, is a finding (ratchet `--check` is clean).
- Definition of Done — grade each with `file:line` citations; you may run read-only probes
  (`python3 -c`, `python3 planner_core.py --help`, `--mode stalled --repo-root . --gh-repo HiQS-Labs/XYZ-forge`
  WITHOUT `--team-issue`, which writes only `temp/planner/*`; `gh … view/list`) with output under `$TMPDIR`; do not pass
  `--team-issue`, post comments, or run `validate.sh`/`test/*.sh`:
  1. **Each acceptance line of #1184 satisfied by actual code paths** — map each to functions/lines: section with
     dated rows + next action; Held never Stalled (engine phase, labels `hold`/`parked`, `Owner decision: hold`);
     two devices → two comments / same-day re-run edits own (marker + PATCH/POST); failed or truncated lookup →
     coverage gap, never "nothing stalled"; local scan read-only (no fetch/prune/write; `--no-optional-locks`); no
     contents/secrets posted (paths, names, counts only); no new `sqlite3.connect` and no ledger write; headless
     `--mode stalled` non-interactive.
  2. **Plan ↔ code fidelity:** does the code match the Approved plan's decisions (recognised-holds set and its
     disclosure, unpushed branches regardless of age, name match = unverified candidate, integration branches skipped,
     notes by last commit not mtime, resolved-note filter, one-hop origin resolution with visible gaps, list failure →
     no blind POST → exit 3, local rows capped at 10 per checkout in the rendering)? Name any divergence.
  3. **Correctness traps:** `_age_days` on missing/odd timestamps; `_origin_slug` regex on ssh/https/local URLs;
     `RESOLVED_NOTE_RE` false positives (a line beginning "Closed-loop review…" would be excluded — acceptable?);
     `STALLED_MARKER_RE` vs `normalize_device_id` alphabet; `--paginate --slurp` page-array handling; `sys.exit` inside
     `main` for daily mode with `--team-issue` (does it skip any required output?); the stub smoke's `--local-roots`
     passing the repo itself twice (dedup).
  4. **Receipt truthfulness:** does `smoke-results.txt` (38 PASS) actually witness what `SUMMARY.md` claims, including
     the two red controls and the index-bytes check? Is anything claimed but not evidenced? Are the live-run artifacts
     consistent with the stub ones?
  5. **No duplicate subsystem:** is anything here a second copy of logic the repo already owns (hold predicates, merged
     PR index, comment-id finder), beyond the deliberate ~15-line copy of marathon_drive's finder?
  6. **Rating** `50/30/50/45` still matches the delivered scope (effort = cheapness; appeal 50)?
  7. **Docs:** does daily-planner SKILL.md Step 6 describe exactly what the code does (flags, defaults, exit codes,
     disclosures, forge-only)? Any sentence that is false?
- Output: one Reviewer block with `swept file: yes|no`, graded findings (`[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`) each
  with a concrete fix; `[Blocker]`/`[Should]` behaviour changes carry `Observed input:` / `Affected scope:` /
  `Falsifier:`; then **VERDICT** (PASS / FAIL / PARKED) and **Basis**.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
