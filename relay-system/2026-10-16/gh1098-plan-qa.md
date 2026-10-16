---
Goal: Plan QA — GH-1098 Shift outer loop Phase 3 (Scope A: four surgical fixes)
Date: 2026-10-16
NEXT: codex (Reviewer)
STATUS: Open
---

# Context

Adjudicate the plan in `PROJECT/1-INBOX/GH-1098-SHIFT-PHASE3.md` against issue #1098 Scope A (A1–A4). The plan is the artifact; no code has been written yet.

Operational envelope: local developer harness (XYZ-forge jog/marathon supervisor), single repo, one operator. Four edits of ≤ 15 lines each in two files. **No new tests, suites, registry entries or gate machinery (AGENTS.md "No new tests", GH-831)** — verification is existing suites plus manual checks recorded under `TESTS-RESULTS/`. Grade against the stated requirements and commensurate complexity; do not request enterprise fail-safes, new config surfaces, or refactors.

Read in full:
- `PROJECT/1-INBOX/GH-1098-SHIFT-PHASE3.md` (plan, verification table, Preflight Bet Check, contract)
- `utils/py/jog_run.py` lines 515–610 (`run_marathon_phase`: preflight resolution, dispatch env) and 1177–1245 (`promote_contract_to_working`)
- `utils/py/swarm_preflight.py` lines 1095–1140 (invocation builder), 1386–1395 (`gate_cmd`), ~1834 (packet `Gate:` line)
- `utils/py/harness_paths.py` lines 30–60 (`harness_home` precedence)
- `utils/py/agy-turn.py` lines 15–25 and 400–470 (idle bound, wall cap)
- `validate.sh` lines 780–900 (`--auto` classification, fail-closed)
- `utils/pdda/pdda.sh` line 40 (required 2-WORKING keys)

Evidence from Phase 2 the plan cites: issue #1081 comments of 2026-10-16 (runs 1–5), issue #1093.

Questions:

1. **Grounding.** For each of A1–A4, is the cited file/line/symbol the real seam, and does the proposed ≤15-line edit actually change the observed failure? Cite file:line where a claim is wrong.
2. **A1 completeness.** The plan prefers `root/utils/py/swarm_preflight.py` and exports `SWARM_PREFLIGHT_ROOT=root`. Does `swarm_preflight.py` honour `SWARM_PREFLIGHT_ROOT` for the doc glob and probe evaluation (not only `compute_default_root`)? Is the retry path at ~1728 covered? Is "log, don't refuse" on `harness_home() != root` the right call for vendored `.xyz/` installs?
3. **A2 minimality.** Filling `updated/owner/goal` at promotion (goal from `title` plus a visible marker) versus refusing promotion with the missing keys named: which is the smaller correct fix given unattended jog runs? Does the hoisted frontmatter rewrite risk touching docs that already carry the keys?
4. **A3 scope.** Setting `RELAY_TURN_IDLE_S` to the wall cap in jog's dispatch env (operator export still wins) — does it reach `agy-turn.py` through `marathon-drive` → `relay-drive` → shim unchanged? Any suite that pins the 300 s default and would go red? Is builder-only vs all-turns a real distinction here?
5. **A4 safety.** Rewriting the default full gate (`bash ci-local.sh` / `bash validate.sh` / `./validate.sh`) to `./validate.sh --auto <target.ref>` in the preflight packet: does `validate.sh --auto` run the right diff inside the marathon lane (what is HEAD at gate time, what is the base), does it fail closed to tier 3 when unclassifiable, and does the full gate still run on the pre-push hook so nothing lands with less than today? Should the rewrite be recorded anywhere besides the packet line?
6. **Verification table.** Are the named existing suites the ones that actually cover each seam? Is each red control real (reproducible on the parent commit) rather than illustrative?
7. **Rating.** `75/55/50/55` — grounded in the cited recurrence (one day's window, prior trend unknown)? Appeal neutral at 50 with no operator override?
8. **Over/under-build.** Flag anything in the plan that is speculative machinery, and anything the issue requires that the plan omits.

Rules for findings (GH-681): a `[Blocker]` or `[Should]` that asks for a behaviour change carries `Observed input:`, `Affected scope:` and `Falsifier:` lines; a `[Blocker]` cites an observed failure. Measure read-only only; no `validate.sh`/`test/*` runs in the relay worktree.

Write your verdict below (`**Verdict:** Approved` or `**Verdict:** Changes requested`) and set STATUS accordingly.

<!-- ▽ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK ▽ -->
▶ TAKE YOUR TURN (codex)
<!-- △ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK △ -->
