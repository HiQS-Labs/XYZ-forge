---
Goal: Final QA — GH-1098 Scope A implementation (A1–A4)
Date: 2026-10-16
NEXT: codex (Reviewer)
STATUS: Open
---

# Context

Adjudicate the committed implementation of #1098 Scope A against the Approved plan `PROJECT/2-WORKING/GH-1098-SHIFT-PHASE3.md` (plan QA: `relay-system/2026-10-16/gh1098-plan-qa.md`, Approved round 3) and the retained evidence under `TESTS-RESULTS/2026-10-16+GH-1098/` (`provenance.jsonl` first).

Operational envelope: local developer harness, single repo, one operator. Four surgical edits in two files. **No new tests, suites, registry entries or gate machinery (AGENTS.md "No new tests", GH-831)** — a new test file or registry entry in the diff is itself a finding. Grade against the plan's stated requirements and commensurate complexity.

Diff to review: `git diff 05bd9303..HEAD -- utils/py/jog_run.py utils/py/swarm_preflight.py` (read-only). Commits: `4dc76a33` (A1–A4), `e358dd86` (shlex import), `2d7dba09` (A4 bash form).

Read in full:
- `utils/py/jog_run.py` `run_marathon_phase` (~:521–560 and ~:583–595) and `promote_contract_to_working` (~:1177–1225); the legacy preflight call (~:1740–1752)
- `utils/py/swarm_preflight.py` ~:1388–1402 and the packet `Gate:` line (~:1845)
- `TESTS-RESULTS/2026-10-16+GH-1098/provenance.jsonl`, `manual-A1-A3-{candidate,parent}.json`, `manual-A2-A4-{candidate,parent}.json`

Questions:

1. **A1.** Does the marathon path now resolve `swarm_preflight.py` root-first and pin `SWARM_PREFLIGHT_ROOT=root` on both the marathon and legacy calls? Is the "resolved outside this root" log computed correctly (three dirname levels from `utils/py/swarm_preflight.py`)? Does the vendored `.xyz/` fallback still work when `root` has no copy? Does this satisfy #1093 (pin OR refuse)?
2. **A2.** Does the hoisted frontmatter block set `status: Active`/`updated` whether or not a Status table exists, insert the table only when absent, fill only absent `updated`/`owner`/`goal`, never overwrite existing values, and emit the marker as a YAML `#` comment? Any case where a doc without a leading `---` is mishandled? Is `.lstrip()` applied only when a table is inserted (so existing body spacing is preserved otherwise)?
3. **A3.** Does `env.setdefault("RELAY_TURN_IDLE_S", env.get("RELAY_TURN_TIMEOUT_S", "900"))` express "idle bound = wall cap, operator export wins" for every agy turn a jog invocation dispatches, and nothing else? Does it reach `agy-turn.py` unchanged through marathon-drive and relay-drive?
4. **A4.** Does the rewrite trigger only for the three default spellings, produce `bash validate.sh --auto <quoted ref>`, propagate into the invocation JSON `gate` and the `--pre-advance-cmd` argv, and record the routing in the packet? Why did `./validate.sh` form fail T33/T36 and is the bash form the smallest correct fix? Any contract gate that should have been rewritten and is not, or vice versa?
5. **Evidence.** For each of A1–A4, do the candidate/parent JSONs show the red control failing on the parent and passing on the candidate for the plan's stated reason? Is the contamination of the first full-gate run correctly described and excluded from evidence? What remains `[Unverified — needs clone run]` pending the clean full gate and Scope C?
6. **Scope and hygiene.** Any new test file, registry entry, flag, config key, or duplicate writer in the diff? Any unrelated change? Does the persisted rating 75/55/50/55 still match the evidence?

Rules (GH-681): a `[Blocker]`/`[Should]` requesting a behaviour change carries `Observed input:`, `Affected scope:`, `Falsifier:`; a `[Blocker]` cites an observed failure. Measure read-only only; no suite runs in the relay worktree.

Write your verdict (`**Verdict:** Approved` or `**Verdict:** Changes requested`), set STATUS, and close with `VERDICT: PASS|FAIL` plus `Basis:`.

<!-- ▽ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK ▽ -->
▶ TAKE YOUR TURN (codex)
<!-- △ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK △ -->

## Log
