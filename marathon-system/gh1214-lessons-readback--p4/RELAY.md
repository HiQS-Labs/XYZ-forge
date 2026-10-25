# Marathon Phase p4
STATUS: Approved
NEXT: codex (Reviewer)

<!-- marathon-drive: task=MARATHON-P4-TURN builder=agy reviewer=codex round-cap=7 -->

## Phase Brief

---
gh_issue: 1218
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1218
title: "Lessons read-back: evidence-gated LESSONS-LEARNED.md entries via rtl_turn_prompt + defect-campaign writer (#1214 P1+6a)"
status: Active (2-WORKING — marathon GH-1214 phase p4)
created: 2026-10-25
updated: 2026-10-25
owner: marathon-gh-1214
doc_type: feedback
complexity: 3
risk: 2
effort: 3
phases: 1
ratings_provisional: false   # rated 2026-10-25 at marathon prep: one shared prompt-builder change + doc/skill text; warn-only, silent when absent
non_goals:
  - Any lint, check, guard or gate on lessons entries (AGENTS.md:156, GH-831 D7)
  - Backfilling the existing completed-doc Lessons Learned sections (#1214 Phase 0, option B)
  - Relevance filtering by area (newest-5 only until volume justifies it)
  - debug.log / harvest-findings / proposals-sink (out of scope by operator decision)
related:
  - https://github.com/HiQS-Labs/XYZ-forge/issues/1214 (umbrella, Phase 1 + Phase 6a; Phase 0 decisions)
  - GH-591 (the existing LESSONS-LEARNED.md entry), GH-693 (sections advisory)
goal: >
  Every relay/marathon turn prompt carries a capped, warn-only pointer list of the newest five
  non-superseded lessons from LESSONS-LEARNED.md; lessons are written only through evidence-gated
  writer prompts in /start-task, /marathon-cleanup and defect-campaign; the file uses one structured
  entry format with public evidence.
---

# GH-1218 — Lessons read-back: evidence-gated entries via `rtl_turn_prompt`

## Status

| What was just completed | What's next |
|---|---|
| 2026-10-25: promoted to 2-WORKING as phase p4 of marathon #1214; Phase 0 decided (single home `LESSONS-LEARNED.md`; doc sections → writer input; no backfill); Kimi K3.1 QA dispositions folded in | Marathon phase p4 (agy builder, codex reviewer): entry format + #591 conversion, reader in `rtl_turn_prompt`, writer text in three skills, pkg regen, manual check, gate green |

Umbrella: #1214 · Phase p4 · `depends_on: p3`.

## Ground truth (`origin/development` 395e9d64)

- `relay-automation/relay-turn-lib.sh:995` defines `rtl_turn_prompt`. Every Python turn shim reaches it through `utils/py/rtl.py:849-852`, and every Bash shim calls it directly, `relay-automation/smallcode-turn.sh:28` included. That makes it the single place to inject the list.
- The style precedent is `rtl_drift_brief` (`relay-turn-lib.sh:1679-1719`): warn-only, at most 5 items, plus a "+N omitted" line.
- `relay-turn-lib.sh` is packaged into `skills/1-hourly/relay-automation/relay-pkg.tar.gz` (`make-pkg.sh:18`), so regenerate with `bash skills/1-hourly/relay-automation/make-pkg.sh` after the edit, or `test/relay-pkg-freshness.sh` goes red.
- `LESSONS-LEARNED.md` holds one free-form lesson, from #591.
- Writer insertion points:
  - `skills/1-hourly/start-task/SKILL.md` step 9, PR handoff (~288-305), plus one reader line in step 1 (~63-75)
  - `skills/3-weekly/marathon-cleanup/SKILL.md`, evidence review (~12-25)
  - `skills/4-occasional/defect-campaign/SKILL.md`, disposition step (~91-107)
- The repo is **public**. `harnesses.db` `evaluations` rows carry a free-form `work_description_narrative` (`utils/py/harness_app.py:253-265`).

## Plan (one phase)

1. **Entry format** at the top of `LESSONS-LEARNED.md`, under a short header that explains the format and the rules. Each entry is a `## <short title>` heading followed by field lines:
   - `- **cue**:` the kind of situation, not this task's facts
   - `- **lesson**:` an operation that can be checked, naming the component
   - `- **evidence**:` public links only
   - `- **confidence**:` high/medium/low, with the reason
   - `- **area**:` relay | marathon | pdda | gate | skills | releases
   - `- **source**:` the issue/PR
   - `- **date**:`
   - optional `- **superseded-by**:`

   Convert the existing #591 lesson into this format, keeping its substance. The narrative body may stay under the fields.
2. **Rules, stated in the header and repeated in every writer prompt.** Prompt text only; no tooling.
   - **Admission:** refuse an entry whose `cue`, `lesson` or `evidence` is empty. Adoption or a merge alone is not evidence. Writing `NO_ENTRY` is a valid outcome.
   - **Edit verdicts:** before drafting, write one row per changed component: helped / hurt / no observed effect / confounded. Use `confounded` when several things changed at once or a single run is the only support. A lesson resting only on `confounded` rows is refused.
   - **Public evidence:** use repo-relative paths to committed `TESTS-RESULTS/` receipts, stable IDs, or public issue/PR/commit links. Never paste DB narratives, transcripts, credentials, hostnames or absolute paths.
   - **ATE/fuzz evidence (Phase 6a):** it counts only after semantic replay, and the cited record must show the predicate and the clean/failing controls. A raw cluster, or a replay matched only by digest or exit code, is `confounded`.
3. **Reader, in `rtl_turn_prompt`.** Resolve `LESSONS-LEARNED.md` at the turn's repo root (`RTL_ROOT` when set, else the git toplevel). If the file exists, append a short block, warn-only and informational, in the drift-brief style:
   - one heading line, then the heading and `cue` of the **newest 5 non-superseded entries**, never their bodies
   - the file path
   - a `+N earlier lesson(s) omitted` line when more exist

   If the file is absent or unreadable, emit nothing. Tag the code `GH-1218`. Make no per-shim edits and leave the frozen twins alone. Regenerate `relay-pkg.tar.gz`.
4. **Writers (prompt text).**
   - `start-task` step 9: before handoff, read the task doc's own `## Lessons Learned` section, if present, as the candidate. Apply the rules, then append one entry to `LESSONS-LEARNED.md` in the PR, or state `NO_ENTRY`.
   - `start-task` step 1: one line telling the agent to read relevant `LESSONS-LEARNED.md` entries.
   - `marathon-cleanup` evidence review: the same writer step, per member doc.
   - `defect-campaign` disposition step: optional; for `new defect` / `faulty oracle` with a semantic replay, draft an entry with `cue` = the shape of the cluster (target + violated invariant), `evidence` = the replay result + the `TESTS-RESULTS/` path, and `area` = the target's subsystem. It stays inside that skill's approval boundary.
5. **Manual check** under `TESTS-RESULTS/2026-10-25+GH-1218/`:
   - capture the `rtl_turn_prompt` output with a fixture lessons file in a throwaway repo under `$TMPDIR`: 7 entries, one of them superseded
   - show that 5 pointers plus the "+N omitted" line appear, that the superseded entry is skipped, and that the output is identical through the Python path (`rtl.py`), the Bash fallback (`XYZ_PYTHON=0`) and SmallCode
   - show silence when the file is absent
   - show the writer rule refusing an empty-evidence entry and accepting a cited one, as a worked example in `manual-check.md`

   Write `manual-check.md` plus `provenance.jsonl`.

Rules: shortest diff; no new script (inventory ratchet), no new suite or registry entry, no new guard (GH-831 D7, `AGENTS.md:154-157`). Edit an existing suite only if a pinned prompt assertion becomes untrue. Design credit: add a one-line comment near the reader, "Design adapted from Harness² (google-research/harness2, Apache-2.0)". No code is copied.

## Swarm Preflight Contract

```json
{
  "target": {
    "repo": ".",
    "ref": "development"
  },
  "gate": "bash validate.sh",
  "fix_probes": [
    {
      "type": "grep_absent",
      "path": "relay-automation/relay-turn-lib.sh",
      "pattern": "GH-1218"
    },
    {
      "type": "grep_absent",
      "path": "LESSONS-LEARNED.md",
      "pattern": "\\*\\*cue\\*\\*"
    },
    {
      "type": "path_absent",
      "path": "TESTS-RESULTS/2026-10-25+GH-1218/manual-check.md"
    },
    {
      "type": "path_absent",
      "path": "TESTS-RESULTS/2026-10-25+GH-1218/provenance.jsonl"
    }
  ],
  "artifacts": [
    "relay-automation/relay-turn-lib.sh",
    "skills/1-hourly/relay-automation/relay-pkg.tar.gz",
    "LESSONS-LEARNED.md",
    "skills/1-hourly/start-task/SKILL.md",
    "skills/3-weekly/marathon-cleanup/SKILL.md",
    "skills/4-occasional/defect-campaign/SKILL.md",
    "TESTS-RESULTS/2026-10-25+GH-1218/manual-check.md",
    "TESTS-RESULTS/2026-10-25+GH-1218/provenance.jsonl"
  ],
  "artifacts_new": [
    "TESTS-RESULTS/2026-10-25+GH-1218/manual-check.md",
    "TESTS-RESULTS/2026-10-25+GH-1218/provenance.jsonl"
  ],
  "remediation": {
    "source": "issue#1218",
    "criteria": "rtl_turn_prompt (tagged GH-1218) appends a warn-only block listing heading+cue of the newest five non-superseded LESSONS-LEARNED.md entries plus path and +N omitted, silent when the file is absent, identical via Python, Bash fallback and SmallCode; relay-pkg.tar.gz regenerated; LESSONS-LEARNED.md uses the structured format with the #591 entry converted and the admission/verdict/public-evidence/ATE rules stated; writer text in start-task step 9 (+reader line in step 1), marathon-cleanup and defect-campaign; manual check recorded; no new suite, script or guard."
  },
  "lanes": {
    "agy_safe": [
      "relay-automation/relay-turn-lib.sh",
      "skills/1-hourly/relay-automation/relay-pkg.tar.gz",
      "LESSONS-LEARNED.md",
      "skills/1-hourly/start-task/SKILL.md",
      "skills/3-weekly/marathon-cleanup/SKILL.md",
      "skills/4-occasional/defect-campaign/SKILL.md",
      "TESTS-RESULTS/2026-10-25+GH-1218/manual-check.md",
      "TESTS-RESULTS/2026-10-25+GH-1218/provenance.jsonl"
    ],
    "orchestrator_only": []
  }
}
```

## Acceptance

- Manual check: 5 pointers plus the omitted count, superseded entry skipped, silent when absent, identical across Python, Bash fallback and SmallCode.
- `LESSONS-LEARNED.md` uses the format, with #591 converted and the rules stated.
- Writer and reader text present in all three skills.
- `test/relay-pkg-freshness.sh`, the prompt-pinning suites (`gh397-reviewer-turn-role.sh`, `gh681-reviewer-probe-rules.sh`, `relay-self-sufficiency.sh`, …) and the full `bash validate.sh` are green.

## Lessons Learned (For Future Agents)

- (filled at closeout)


---

▶ TAKE YOUR TURN (agy — BUILDER role)

You are the BUILDER for this phase. Read the phase brief above and implement it.
APPEND-ONLY FILE (GH-529 attestation): add your block at the END and never delete, reorder, or rewrite any existing content — the terminal attestation refuses the approval if any byte above your block changed, even a tidy-up.
1. Implement the brief by creating/editing the artifact file(s): relay-automation/relay-turn-lib.sh, skills/1-hourly/relay-automation/relay-pkg.tar.gz, LESSONS-LEARNED.md, skills/1-hourly/start-task/SKILL.md, skills/3-weekly/marathon-cleanup/SKILL.md, skills/4-occasional/defect-campaign/SKILL.md, TESTS-RESULTS/2026-10-25+GH-1218/manual-check.md, TESTS-RESULTS/2026-10-25+GH-1218/provenance.jsonl
2. Append a build block to this relay file: `### Round N · Builder · agy` summarizing what you did (files touched, key decisions).
3. Use this exact tick binary (run it from any directory): /Users/noelsaw/marathon-clones/marathon-gh-1214-lessons-readback/bin/tick
   - /Users/noelsaw/marathon-clones/marathon-gh-1214-lessons-readback/bin/tick claim MARATHON-P4-TURN --agent agy --paths "marathon-system/gh1214-lessons-readback--p4/RELAY.md,relay-automation/relay-turn-lib.sh, skills/1-hourly/relay-automation/relay-pkg.tar.gz, LESSONS-LEARNED.md, skills/1-hourly/start-task/SKILL.md, skills/3-weekly/marathon-cleanup/SKILL.md, skills/4-occasional/defect-campaign/SKILL.md, TESTS-RESULTS/2026-10-25+GH-1218/manual-check.md, TESTS-RESULTS/2026-10-25+GH-1218/provenance.jsonl"
   - /Users/noelsaw/marathon-clones/marathon-gh-1214-lessons-readback/bin/tick ping MARATHON-P4-TURN --agent agy
   - /Users/noelsaw/marathon-clones/marathon-gh-1214-lessons-readback/bin/tick release MARATHON-P4-TURN --agent agy --to codex
4. Edit ONLY these paths: marathon-system/gh1214-lessons-readback--p4/RELAY.md and relay-automation/relay-turn-lib.sh, skills/1-hourly/relay-automation/relay-pkg.tar.gz, LESSONS-LEARNED.md, skills/1-hourly/start-task/SKILL.md, skills/3-weekly/marathon-cleanup/SKILL.md, skills/4-occasional/defect-campaign/SKILL.md, TESTS-RESULTS/2026-10-25+GH-1218/manual-check.md, TESTS-RESULTS/2026-10-25+GH-1218/provenance.jsonl. Do NOT run git. Do NOT touch any other file — the harness commits for you.
5. HAND OFF EXPLICITLY (GH-268): after releasing the token, end your turn by naming who acts next —
   "handing off to codex — codex, take your turn." A turn that ends without that line
   leaves a human guessing whether the relay is waiting on them or has stalled. Do this EVERY round,
   not just the first. ALSO, you MUST update the `NEXT:` line at the top of this file to exactly: `NEXT: codex (Reviewer)`

---

▶ TAKE YOUR TURN (codex — REVIEWER role)

You are the REVIEWER for this phase. Read the latest builder block above AND review the artifact file(s) on disk: relay-automation/relay-turn-lib.sh, skills/1-hourly/relay-automation/relay-pkg.tar.gz, LESSONS-LEARNED.md, skills/1-hourly/start-task/SKILL.md, skills/3-weekly/marathon-cleanup/SKILL.md, skills/4-occasional/defect-campaign/SKILL.md, TESTS-RESULTS/2026-10-25+GH-1218/manual-check.md, TESTS-RESULTS/2026-10-25+GH-1218/provenance.jsonl. REVIEW THE WHOLE FILE, NOT JUST THE DIFF (GH-268): a beta test had this loop reach 'Approved' in two rounds while an independent audit of the same branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN SCOPE; say so explicitly if you find none. DECLARE IT: your review block MUST contain a literal 'swept file: yes' or 'swept file: no' line — without it a reviewer that skipped the sweep is indistinguishable in the transcript from one that did it and found nothing, which is exactly how those 20 issues stayed invisible.
APPEND-ONLY FILE (GH-529 attestation): add your block at the END and never delete, reorder, or rewrite any existing content — the terminal attestation refuses the approval if any byte above your block changed, even a tidy-up.
1. Append a review block: `### Round N · Reviewer · codex` followed by your assessment.
2. If changes needed: add `**Verdict:** Changes requested`, update the `NEXT:` line to exactly `NEXT: agy (Builder)`, then: /Users/noelsaw/marathon-clones/marathon-gh-1214-lessons-readback/bin/tick release MARATHON-P4-TURN --agent codex --to agy
3. If satisfied: add `**Verdict:** Approved`, set `STATUS: Approved`, then: /Users/noelsaw/marathon-clones/marathon-gh-1214-lessons-readback/bin/tick done MARATHON-P4-TURN --agent codex
4. Use this exact tick binary (run it from any directory) for all token operations: /Users/noelsaw/marathon-clones/marathon-gh-1214-lessons-readback/bin/tick
   Edit ONLY marathon-system/gh1214-lessons-readback--p4/RELAY.md (your review block + STATUS). Do NOT edit the artifact yourself — request changes instead. Do NOT run git.
4b. TO VERIFY A FINDING, WRITE PROBE FILES OUTSIDE THE REPO — under $TMPDIR, never inside the
   working tree. Creating even one scratch file in the repo is an off-lane write: containment
   reverts it and FAILS YOUR WHOLE TURN, discarding the review you just did (GH-441). Observed
   2026-08-08: a reviewer found a real latent crash, wrote two probe files in-tree to demonstrate
   it, and lost the turn for doing so — the finding survived only because RELAY.md happens to be
   on your allowlist. `cp` what you need to "$TMPDIR/probe.$$/" and work there instead. Verifying
   is wanted; verifying in-tree is what costs you the turn.
4c. A finding that asks for a behaviour change is a generalization unless you can paste the concrete
   input — a row, a value, a `file:line` — that fails under the current code (GH-681). Every
   `[Blocker]` or `[Should]` requesting a behaviour change MUST carry `Observed input:`,
   `Affected scope:` and `Falsifier:` lines; a `[Blocker]` must cite an observed failure. The Builder
   may disposition a request lacking these as `Declined — unproven generalization`.
5. HAND OFF EXPLICITLY (GH-268): end your turn by naming who acts next — "handing off to agy —
   agy, take your turn" when requesting changes, or "relay closed, no further turn needed" when
   approving. The beta report singled this out: the Reviewer turn did not tell the user to go back to the
   Producer, so the relay looked stalled when it was simply waiting. Do this EVERY round.

---

### Round 1 · Builder · agy

Implemented GH-1218 (#1214 Phase 1 + 6a) across all declared phase artifacts:

- **`LESSONS-LEARNED.md`**:
  - Added the structured entry format specification (`## <short title>` with `- **cue**:`, `- **lesson**:`, `- **evidence**:`, `- **confidence**:`, `- **area**:` [`relay | marathon | pdda | gate | skills | releases`], `- **source**:`, `- **date**:`, and optional `- **superseded-by**:`) and the four prompt-enforced writer/admission rules (**Admission**, **Edit verdicts**, **Public evidence**, **ATE/fuzz evidence (Phase 6a)**) at the top of the file.
  - Converted the existing #591 lesson into the structured field format while preserving its full narrative body under `### What happened`, `### The lesson`, and `### How to apply`.
- **`relay-automation/relay-turn-lib.sh` & `skills/1-hourly/relay-automation/relay-pkg.tar.gz`**:
  - In `rtl_turn_prompt` (tagged `GH-1218` with the `Design adapted from Harness² (google-research/harness2, Apache-2.0)` credit comment), resolved `LESSONS-LEARNED.md` at the turn's repo root (`RTL_ROOT` when set, else git toplevel).
  - Parsed non-superseded entries (`## <short title>` + `- **cue**:`, skipping fenced code blocks, `###` narrative bodies, and entries with a non-empty `- **superseded-by**:` value other than `none`/`null`/`-`/`~`) and appended a warn-only `[lessons learned (LESSONS-LEARNED.md) — informational, warn-only; inspect LESSONS-LEARNED.md when a cue matches your task]` block listing the newest 5 non-superseded entries' heading + `cue` and `+N earlier lesson(s) omitted — see LESSONS-LEARNED.md for full history.` when more exist. Silent when `LESSONS-LEARNED.md` is absent or unreadable.
  - Regenerated `skills/1-hourly/relay-automation/relay-pkg.tar.gz` via `bash skills/1-hourly/relay-automation/make-pkg.sh`.
- **Skill writer & reader prompts**:
  - `skills/1-hourly/start-task/SKILL.md`: added the reader instruction in Step 1 (`Read relevant entries in LESSONS-LEARNED.md (when present at the repo root) whose cue matches the task`) and the evidence-gated writer instruction with all four rules in Step 9.
  - `skills/3-weekly/marathon-cleanup/SKILL.md`: added the evidence-gated writer instruction with all four rules under Guardrails / evidence review per verified-complete member task doc.
  - `skills/4-occasional/defect-campaign/SKILL.md`: added the optional evidence-gated writer instruction with all four rules in the disposition step (`Replay, classify and hand off`) for `new defect` / `faulty oracle` backed by a semantic replay, staying inside the skill's approval boundary.
- **Verification & Manual Check (`TESTS-RESULTS/2026-10-25+GH-1218/manual-check.md`, `TESTS-RESULTS/2026-10-25+GH-1218/provenance.jsonl`)**:
  - Verified in a throwaway repo under `$TMPDIR` with 7 entries (1 superseded) and an absent-file control that 5 pointers + `+1 earlier lesson(s) omitted` appear, the superseded entry and narrative bodies are excluded, absent file is silent, and output is byte-for-byte identical across Python (`utils/py/rtl.py`), Bash fallback (`XYZ_PYTHON=0`), and SmallCode (`relay-automation/smallcode-turn.sh`).
  - Documented the worked writer-rule example (refusal on empty evidence / `confounded`-only verdicts -> `NO_ENTRY` vs acceptance with `helped` verdict and public evidence).
  - Verified `test/relay-pkg-freshness.sh`, `test/gh397-reviewer-turn-role.sh`, `test/gh681-reviewer-probe-rules.sh`, `test/gh91-relay-scratch.sh`, `test/gh304-vendored-relay-path.sh`, `test/gh609-sdlc-agent-gaps.sh`, `test/gh615-start-task-reinforce.sh`, `test/gh616-start-task-commensurate-envelope.sh`, and `test/gh308-frozen-twin-guard.sh --check --base HEAD` all pass.

### Round 1 · Reviewer · codex

swept file: yes

**Verdict:** Changes requested

[Should] `rtl_turn_prompt` does not reliably select the newest five lessons when field dates are out of source order. Its GH-1218 branch deliberately switches to `_lend=5` when `_first_date > _last_date`, which selects the first five parsed entries (including an older entry) rather than the five newest. This contradicts the phase requirement, and the supplied manual check covers only increasing dates.

Observed input: a temporary `LESSONS-LEARNED.md` containing six valid entries in source order `Entry 1` through `Entry 6`, each with a cue; `Entry 1` has `- **date**: 2026-12-31`, and Entries 2–6 have dates `2026-10-02` through `2026-10-06`. Probe command (run with `PYTHONDONTWRITEBYTECODE=1`, output under `.relay-scratch/tmp`): `bash -c 'RTL_ROOT="$probe"; export RTL_ROOT; source relay-automation/relay-turn-lib.sh; rtl_turn_prompt codex "$probe/RELAY.md" T probe agy' | sed -n '/^\\[lessons learned/,/^+.*omitted/p'`; exit 0. Decisive output selected `Entry 1`, `Entry 2`, `Entry 3`, `Entry 4`, and `Entry 5`, then `+1 earlier lesson(s) omitted`; it omitted `Entry 6`, although `Entry 6` is newer than Entries 2–5.

Affected scope: `relay-automation/relay-turn-lib.sh` GH-1218 reader (and its packaged `relay-pkg.tar.gz` copy); any historical/manual date correction or imported entry that makes first/last dates descend can display a stale pointer instead of a newest one.

Falsifier: a focused throwaway-repo probe with the same six-entry fixture emits exactly the five entries with greatest parsed ISO `YYYY-MM-DD` dates (`Entry 1`, `Entry 6`, `Entry 5`, `Entry 4`, `Entry 3`, in whichever deterministic presentation order is documented), with `Entry 2` omitted; retain the existing normal-order and absent-file parity controls. Regenerate the package and update the manual receipt/provenance to record the added control.

I swept the listed implementation, skills, manual receipt, provenance, and packaged relay copy; aside from the selection defect above, I found no pre-existing in-scope defect requiring a finding. The package's embedded `relay-turn-lib.sh` SHA-256 matches the source (`20672503e7991333336dcd8dc1890bd22a1e367f9af57566d2e21919626dea28`).

handing off to agy — agy, take your turn

### Round 2 · Builder · agy

Resolved the Round 1 `[Should]` finding on non-monotonic / out-of-order entry dates in `rtl_turn_prompt`:

- **`relay-automation/relay-turn-lib.sh` & `skills/1-hourly/relay-automation/relay-pkg.tar.gz`**:
  - Replaced the two-endpoint (`_first_date > _last_date`) slice heuristic in `rtl_turn_prompt` with per-entry date ranking over all parsed non-superseded entries (`_ldates`, defaulting undated entries to `0000-00-00` and breaking date ties by later file index `$_li > $_best`), then emitting the selected 5 newest entries in deterministic source order.
  - Regenerated `skills/1-hourly/relay-automation/relay-pkg.tar.gz` via `bash skills/1-hourly/relay-automation/make-pkg.sh` and verified `test/relay-pkg-freshness.sh` (3/3 pass).
- **`TESTS-RESULTS/2026-10-25+GH-1218/manual-check.md` & `TESTS-RESULTS/2026-10-25+GH-1218/provenance.jsonl`**:
  - Added the 6-entry out-of-order date control (`Entry 1` dated `2026-12-31`, `Entry 2`..`Entry 6` dated `2026-10-02`..`2026-10-06`) to the throwaway-repo probe, confirming that `Entry 1`, `Entry 3`, `Entry 4`, `Entry 5`, and `Entry 6` are selected while `Entry 2` (`2026-10-02`) is omitted with `+1 earlier lesson(s) omitted — see LESSONS-LEARNED.md for full history.`, and that output remains byte-for-byte identical across Python (`utils/py/rtl.py`), Bash fallback (`XYZ_PYTHON=0`), and SmallCode (`relay-automation/smallcode-turn.sh`), alongside the existing 7-entry (1 superseded) and absent-file controls.
  - Appended the corresponding `manual_probe_out_of_order_dates` receipt entry to `TESTS-RESULTS/2026-10-25+GH-1218/provenance.jsonl`.

### Round 2 · Reviewer · codex

swept file: yes

**Verdict:** Approved

The Round 1 selection defect is resolved: the reader ranks every eligible entry by its date, retains the five greatest values, and then emits the selected set in deterministic source order. Independent narrow probe (exit 0): `RTL_ROOT="$probe" bash -c 'source "$root/relay-automation/relay-turn-lib.sh"; rtl_turn_prompt agy "$probe/RELAY.md" T art codex' | sed -n '/^\\[lessons learned/,/^+.*omitted/p'` with dates `2026-12-31, 2026-10-02..06` emitted Entries 1 and 3–6, omitted Entry 2, and printed `+1 earlier lesson(s) omitted`. `bash -n relay-automation/relay-turn-lib.sh` exited 0; the packaged `relay-automation/relay-turn-lib.sh` compared byte-identically with its source (exit 0).

I swept the complete listed reader implementation, package contents, structured lessons document, all three writer prompts, manual receipt, and provenance. I found no remaining pre-existing in-scope defect or unmet phase criterion. The manual receipt records the normal, absent-file, out-of-order-date, and Python/Bash/SmallCode parity controls; no clone-only suite was run in this reviewer worktree.

relay closed, no further turn needed
