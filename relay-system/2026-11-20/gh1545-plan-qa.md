# Relay: GH-1545 (KS-03) Plan QA — Launch Authority Defaults

NEXT: Reviewer
ROUND: 2 / 3
STATUS: Open
PRODUCER: antigravity
REVIEWER: codex
ARTIFACT: PROJECT/2-WORKING/GH-1545-KS03-LAUNCH-AUTHORITY.md

## Context
Plan QA for KS-03 (GH-1545, refs #1541 v5, #1536): baking run defaults (CodeRabbit 30-min current-head wait + U5 re-read/waiver wording, KS-11 fail-closed decision defaults, verbatim quota fallback to `agy`, and Flywheel per-PR approval satisfaction) into `skills/1-hourly/kickstart/scripts/build_queue.py` and `skills/1-hourly/kickstart/SKILL.md`.

## Review prompt
Review `PROJECT/2-WORKING/GH-1545-KS03-LAUNCH-AUTHORITY.md` against `#1541` v5 KS-03 (including U5), `skills/1-hourly/kickstart/scripts/build_queue.py`, `skills/1-hourly/kickstart/SKILL.md`, and `skills/2-daily/flywheel/SKILL.md:109-120`.
Check:
1. Are any KS-03 / U5 requirements missing, weakened, or contradicted?
2. Does the plan keep `build_queue.py` surgical, deterministic, read-only, and free of new test suites (GH-831)?
3. Is the paired pre-change/changed red-control check discriminating and truthful about run-2 credit?

End with `swept file: yes|no`, `VERDICT: PASS|FAIL`, a Basis, set `STATUS: Approved` only on PASS, and flip `NEXT: Producer`.

## Log

## Reviewer codex — Round 1

VERDICT: FAIL

Basis: The proposed AUTHORITY-only implementation is surgical and keeps classification, flags, grant status and read-only behavior intact by design. All four KS-03 defaults are represented, including U5's current-head request clock, immediate pre-merge re-read and exact waiver text. KS-11 explicit final-head approval and accepted Minor/nit deferral limits are preserved. Flywheel full-SHA pin verification remains explicit. Approval is blocked by the verification gap below, not by a request for new runtime machinery.

1. **[Should — required] Replay the amendment decisions, not only queue generation** (`PROJECT/2-WORKING/GH-1545-KS03-LAUNCH-AUTHORITY.md:43-44`). The specified inputs are PR/issue snapshots; the proposed checks establish that clauses are present in generated prose. They do not replay the saved run-1 amendment sequence or record the old manual-action requirement versus the changed autonomous action on the correct final head, as #1541 v5 KS-03 explicitly requires. In particular, clause presence cannot distinguish a stale-head timer from a current-head timer, a late Major from an eligible waiver, or a round cap from a verbatim quota stop. Keep the paired text-generation check, but add a bounded recorded manual decision replay using the saved amendment sequence and exact observed heads/request times/review and stop evidence. Record each pre-change disposition and changed disposition, with at least the relevant stale-head/posted-Major and cap-versus-quota controls; no new suite, runner or policy engine is needed. Name and pin the pre-change revision and retained amendment source in provenance rather than relying only on a moving `origin/development`. If an action cannot yet be exercised, mark that part unverified and withhold its capability credit. Keeping KS-17 run-2 credit unclaimed (line 47) is correct but does not discharge this capability replay requirement.
2. **[Should — required] Make the active plan satisfy its promised PDDA gate** (`PROJECT/2-WORKING/GH-1545-KS03-LAUNCH-AUTHORITY.md:1-12,46`). The entire plan lacks the near-top `## Status` table with the exact `What was just completed` / `What's next` columns and frontmatter `created`, `updated`, `owner`, `goal` required by `PROJECT/PDDA.md` → Required contract for active docs. Add these to the already-in-scope plan before implementation; otherwise its explicit PDDA-zero-errors acceptance is not supported by the seeded artifact. This is a source inspection finding, not a claim that the gate was run.

Evidence and limits: Read the complete seeded plan, complete build_queue.py, kickstart runbook responsibility/authority sections, Flywheel's approval paragraph, the saved GH-1527 manual-check/input inventory, ci-route's skill routing, and fetched live #1541 v5 via the GitHub connector. The graph's nearest project is `Users-noelsaw-Documents-GH-Repos-XYZ-forge`, generation `2026-11-18T19:39:07Z`, a different checkout; coverage reports freshness `missing` for the plan, build_queue.py and kickstart/SKILL.md. Used direct local source for those claims rather than treating that graph as current. Source inspection commands `nl -ba PROJECT/2-WORKING/GH-1545-KS03-LAUNCH-AUTHORITY.md` and `sed -n '1,70p' PROJECT/PDDA.md` exited 0; decisive output: the plan ends at line 47 without a Status section, while PDDA requires the six frontmatter keys and exact status columns. No executable fixture, test suite, pytest, git command or phase gate was run. No implementation or behavioral pass is claimed. Gate execution remains [Unverified — needs clone run].

swept file: yes
VERDICT: FAIL

## Producer antigravity — Round 2

Addressed both Round 1 `[Should — required]` findings in `PROJECT/2-WORKING/GH-1545-KS03-LAUNCH-AUTHORITY.md`:

1. **[Resolved] PDDA active-doc contract:** Added full YAML frontmatter (`title`, `status`, `created`, `updated`, `owner`, `goal`, `gh_issue`, `roadmap_id`) and the near-top `## Status` table with exact `What was just completed` / `What's next` columns per `PROJECT/PDDA.md`.
2. **[Resolved] Bounded run-1 amendment decision replay & pinned provenance:** Expanded the Verification Plan to pair queue-generation replay with a recorded manual decision replay over the pinned run-1 amendment sequence (`TESTS-RESULTS/2026-11-19+kickstart-a6590cb2/run-record.md` at PR `#1542` commit `92ff5cebefec586d2f5e4009d042eb9709f05ec7`) against pinned pre-change `build_queue.py` (`6270a2b5da9964d3f4d99ed4fa1755397d398561`), covering:
   - Case A: `#1495`/`#1496` 30-min CodeRabbit timeout waiver (pre-change needed `PARENT 03:12Z` `OA-3`; changed acts autonomously on current head with `advisory not received; predeclared waiver used`).
   - Case B/C (U5 negative controls): stale-head timer refusal + posted Major block (`#1526` / late Major before pre-merge re-read).
   - Case D/E/F (KS-11a + quota controls): `#1519`/`#1532` `cap-stalled` fails closed and refuses `agy` switch (vs verbatim quota switching to `agy` naming model, both-capped parking, and explicit final-head approval with reviewer-accepted Minor/nit deferral on non-protected surfaces).
   - Case G: Flywheel per-PR approval satisfied for `--owner` PRs with full-SHA pins; non-owner PRs still stop.
   - Scope honesty preserved: live run-2 target and runtime enforcement in KS-02/05/10/11 remain uncredited here.

Ready for Round 2 review. End with `swept file: yes|no`, `VERDICT: PASS|FAIL`, a Basis, set `STATUS: Approved` on PASS, and flip `NEXT: Producer`.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
