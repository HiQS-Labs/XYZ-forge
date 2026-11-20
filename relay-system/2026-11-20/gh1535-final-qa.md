# Relay: GH-1535 (KS-02) Final QA — Operator Decision Release & U15 Body/Label Holds

STATUS: In Progress
NEXT: Reviewer
ROUND: 1 / 3
PRODUCER: antigravity
REVIEWER: codex
TARGET_REPO: HiQS-Labs/XYZ-forge
BRANCH: feat/XYZ-forge-gh1535-ks02-decide-holds-2026-11-20
CANDIDATE_SHA: d9c65f4e428e38e552c8f8aa2cb62b227277aac9
ISSUE: #1535 (parent arc #1541 v5 KS-02 + U15 + KS-11c)
ROADMAP_ID: rmi-01M7VZEFJCGEV7EC8NKCJH5FEK

## Producer Round 1 — Final QA Submission

Please review the completed implementation, docs mirror, and recorded paired manual check evidence for **GH-1535 (KS-02)** against the Codex-approved Plan QA (`PROJECT/2-WORKING/GH-1535-KS02-DECIDE-HOLDS.md`, attested at `44f9f960`).

### What Changed (inspect without calling git via retained diff files)
- `TESTS-RESULTS/2026-11-20+GH-1535/outputs/name-status.txt` — full `git diff --name-status` and `--stat` from base `6270a2b5da9964d3f4d99ed4fa1755397d398561` to code commit `5bea053cde97ad91b0b40482a7df0ee7290880af`.
- `TESTS-RESULTS/2026-11-20+GH-1535/outputs/code-and-docs-diff.patch` — complete unified diff of `skills/`, `CHANGELOG.md`, `PROJECT/`, `releases.sql`.
- `skills/1-hourly/kickstart/scripts/build_queue.py` — implemented:
  1. Single `gh issue list --json number,title,labels,body,createdAt,comments` call (replay backward-compatible when `comments` omitted).
  2. `operator_decision(issue, owner)` — chronological scan, strict `author.login == owner`, first non-empty stripped line (`Operator decision: close` -> `close`, `Operator decision: hold` -> `hold`, `Operator decision` -> `proceed`), latest matching owner comment wins (supersession per KS-11c).
  3. `_sanitize_body(body)` + `issue_hold_reason(issue, open_refs)` — strips fenced code blocks, strips wholly backtick-quoted hold example phrases while preserving prose holds with code-formatted issue refs (e.g. `Blocked by \`#1543\``), detects `status:held` label, `HELD:` marker, and `Blocked by #N` / `after #N` body holds across all issue types without overriding an existing `other-session` or `decide` hold.
  4. `parked_issues(...)` + `classify_issues(...)` — `proceed` releases decide holds cleanly into `DECIDED` bucket (never falls into rule 9 unclassified, and does not override `other-session` or explicit U15 body/label holds); `close` routes to new `CLOSE` bucket ("Close after verifying acceptance on development").
- `skills/1-hourly/kickstart/SKILL.md` — mirrored the exact closed rule list and child acceptance-verification + close behavior.
- `CHANGELOG.md`, `PROJECT/2-WORKING/GH-1535-KS02-DECIDE-HOLDS.md`, `releases.db`, `releases.sql`.

### Evidence & Gates (`TESTS-RESULTS/2026-11-20+GH-1535/`)
- `manual-check.md` — literal runnable bash verification block (zero placeholders) covering all 8 paired pre-change (`6270a2b5`) vs candidate (`5bea053c`) cases:
  1. `case1_1518_proceed_unparks_1526` (red: pre-change keeps #1518 held & parks #1526; green: #1518 released, #1526 unparked to bucket A)
  2. `case2_1518_proceed_no_rule9_fallthrough` (red: standalone #1518 stays held/rule9; green: routes to `DECIDED`, zero rule-9 fallthrough)
  3. `case3_1518_operator_decision_close_bucket` (red: stays held; green: routes to `CLOSE` bucket)
  4. `case4a_non_owner_rejected`, `case4b_second_line_rejected`, `case4c_superseded_by_hold` (author, line-1, and supersession guards)
  5. `case5_u15_holds_formatted_refs_nonoverride_and_fp_guards` (red: #1400 OL-10 body-only hold queued pre-change; green: held across all issue types, backtick-formatted ref held, fenced/inline-example FP ignored, `other-session` not overridden, `status:held` / `HELD:` / closed-ref handled)
  6. Determinism byte-identical across 2 replays
  7. Read-only invariance: `git show-ref`, `FETCH_HEAD`, `git count-objects` unchanged
  8. CI route `docs` + `mypy --allow-untyped-defs --allow-incomplete-defs` (0 issues) + PDDA gate (`pdda-run.log`: 0 errors)
- `outputs/check-transcript.log`, `outputs/matrix-summary.md`, `outputs/case*.md`, `pdda-run.log`, and `provenance.jsonl` (SHA-256 of every retained artifact, zero raw `/Users/` paths).

### Review Checklist
1. Does the implementation match the approved GH-1535 plan and `#1541` v5 KS-02 + U15 + KS-11c with no scope creep or new test suites (GH-831)?
2. Are all edge cases (non-owner, line-2, supersession, `other-session` non-override, `DECIDED`/`CLOSE` buckets, U15 body/label holds, fenced/backtick false positives, closed refs, backward-compatible replay) sound?
3. Are the paired red/green evidence, read-only invariance, `mypy`, PDDA gate, and `provenance.jsonl` complete and consistent?
4. If clean, append your review block and set `STATUS: Approved` and `NEXT: Done`. If changes are needed, list numbered findings and set `NEXT: Producer`.
