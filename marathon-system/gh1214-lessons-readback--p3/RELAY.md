# Marathon Phase p3
STATUS: Open
NEXT: agy (Builder)

<!-- marathon-drive: task=MARATHON-P3-TURN builder=agy reviewer=codex round-cap=5 -->

## Phase Brief

---
gh_issue: 1219
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1219
title: "consult: blind A/B reconcile with neutral answer payloads (#1214 P2)"
status: Active (2-WORKING — marathon GH-1214 phase p3)
created: 2026-10-25
updated: 2026-10-25
owner: marathon-gh-1214
doc_type: feedback
complexity: 2
risk: 2
effort: 2
phases: 1
ratings_provisional: false   # rated 2026-10-25 at marathon prep: additive output files in two twins + skill text; named originals untouched
non_goals:
  - Removing or renaming the existing named transcripts, attestation or stamps (they stay for audit)
  - Guaranteeing blindness against a model that names itself in its answer text
  - Changing which advisors run or how they are invoked
related:
  - https://github.com/HiQS-Labs/XYZ-forge/issues/1214 (umbrella, Phase 2)
  - GH-308 (Python authoritative; consult.sh frozen)
goal: >
  After a consult run, the reconciler can read neutral, shuffled answer-A/answer-B payloads with no
  harness attestation, banner, advisor-named stamp or identifying filename, settle disagreements in a
  fixed criteria order, and only then open key.json and the named originals.
---

# GH-1219 — consult: blind A/B reconcile with neutral answer payloads

## Status

| What was just completed | What's next |
|---|---|
| 2026-10-25: promoted to 2-WORKING as phase p3 of marathon #1214; Kimi K3.1 QA blocker (renaming alone does not blind) folded into the design | Marathon phase p3 (agy builder, codex reviewer): neutral payloads + key in both twins, skill steps 3-4, manual check, gate green |

Umbrella: #1214 · Phase p3 · `depends_on: p2`.

## Ground truth (`origin/development` 395e9d64)

- Answers are saved under model names (`relay-automation/consult.sh:307`; `utils/py/consult.py:648,657`).
- An attestation block is prepended to each transcript: `> **ATTESTATION** / > Model: / > Provider: / > Sandbox:` (`consult.sh:208-218`; `consult.py:224-248`).
- Stamps that name the advisor: citation warnings and degraded/single-model stamps (`consult.sh:343-351,388-397`; `consult.py:820-835,869-885`).
- The reconciler reads the named transcripts (`skills/1-hourly/consult/SKILL.md:107`) and settles disagreements with no fixed order of criteria (`:112`).
- `consult.sh` is FROZEN (GH-308); `consult.py` is authoritative. A behavior edit to the frozen twin needs a `Frozen-twin-exception:` commit trailer (`AGENTS.md:298-302`).

## Plan (one phase)

1. **`utils/py/consult.py`:** after every advisor answer is validated and stamped, write a neutral copy of each answer into the run dir:
   - strip the attestation block, CLI banners and stamp lines that name an advisor
   - replace advisor and model names in any warnings kept with the neutral ID
   - order the payloads by a shuffle seeded from the run label (stable across reruns) and write `answer-A.md`, `answer-B.md`, … plus `key.json`, which maps each ID to the advisor and the original filename
   - leave the named originals untouched; tag the code `GH-1219`

   With a single advisor, write `answer-A.md` and `key.json` too; the SINGLE-MODEL stamp logic is unchanged.

   **JSON-mode answers** (`CONSULT_GEMINI_JSON=1`, written as `${label}.gemini.json` at `consult.py:664-672`, which skips text-stamp rewriting at `:876-885`) get a neutral **Markdown projection**: decode only the `.response` value, the same boundary the validator already uses at `consult.py:208-214`. Never copy the raw JSON, because its envelope can carry model, provider or metadata fields. (Plan review, Codex, 2026-10-25.)
2. **`relay-automation/consult.sh` is not edited.** It is FROZEN (GH-308), and by default it execs `consult.py` (`consult.sh:9-18`), so the Python change covers the supported path. The Bash fallback (`XYZ_PYTHON=0`) keeps its historical output; that is GH-308 policy, not a gap. Swarm preflight refused the frozen artifact at prep (exit 5), and the write-set was narrowed to match.
3. **`skills/1-hourly/consult/SKILL.md` steps 3-4:**
   - read only `answer-*.md` first
   - settle every disagreement in this fixed order: claims checked against the source and repo → reproducibility and citations → internal consistency → whether the next consumer can use it → scope; length and polish are not merits
   - write the verdict, naming the deciding criterion and the runner-up's specific defect
   - only then open `key.json` and the named originals to attribute the result
   - say plainly that this is best-effort pseudonymization
4. Run a manual check under `TESTS-RESULTS/2026-10-25+GH-1219/` with stub advisor binaries, the same way the existing consult suites stub them; no live models. Confirm:
   - the payloads contain no `ATTESTATION`/`Model:`/`Provider:` lines, no advisor names and no named filenames
   - `key.json` maps correctly
   - a rerun produces the same order
   - a stubbed `CONSULT_GEMINI_JSON=1` run, whose JSON envelope contains identifying fields, yields an `answer-*.md` holding only the decoded response
   - the default entry point `relay-automation/consult.sh` (which execs `consult.py`) produces the same files

   Write `manual-check.md` plus `provenance.jsonl`.

Rules: shortest diff; no new script (inventory ratchet), no new suite (GH-831 D7). Edit an existing consult suite only if a pinned assertion becomes untrue.

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
      "path": "utils/py/consult.py",
      "pattern": "GH-1219"
    },
    {
      "type": "grep_absent",
      "path": "skills/1-hourly/consult/SKILL.md",
      "pattern": "key\\.json"
    },
    {
      "type": "path_absent",
      "path": "TESTS-RESULTS/2026-10-25+GH-1219/manual-check.md"
    },
    {
      "type": "path_absent",
      "path": "TESTS-RESULTS/2026-10-25+GH-1219/provenance.jsonl"
    }
  ],
  "artifacts": [
    "utils/py/consult.py",
    "skills/1-hourly/consult/SKILL.md",
    "TESTS-RESULTS/2026-10-25+GH-1219/manual-check.md",
    "TESTS-RESULTS/2026-10-25+GH-1219/provenance.jsonl"
  ],
  "artifacts_new": [
    "TESTS-RESULTS/2026-10-25+GH-1219/manual-check.md",
    "TESTS-RESULTS/2026-10-25+GH-1219/provenance.jsonl"
  ],
  "remediation": {
    "source": "issue#1219",
    "criteria": "consult.py (authoritative; consult.sh execs it by default, GH-308) writes neutral answer-A/B payloads (no attestation, banners, advisor-named stamps or names) in a seeded stable order plus key.json after all stamping, leaving the named originals intact; the consult skill reads only A/B, decides in a fixed criteria order, then opens the key; tagged GH-1219; manual check recorded; existing consult suites green."
  },
  "lanes": {
    "agy_safe": [
      "utils/py/consult.py",
      "skills/1-hourly/consult/SKILL.md",
      "TESTS-RESULTS/2026-10-25+GH-1219/manual-check.md",
      "TESTS-RESULTS/2026-10-25+GH-1219/provenance.jsonl"
    ],
    "orchestrator_only": []
  }
}
```

## Acceptance

- The manual check shows neutral payloads, a correct key and a stable order, both through `consult.py` directly and through the default `consult.sh` entry point.
- `test/consult.sh`, `test/gh308-consult-guards.sh`, `test/gh589-consult-no-tick.sh`, `test/gh648-l3-consult-cap.sh` and the full `bash validate.sh` are green.
- `relay-automation/consult.sh` is unchanged (GH-308).

## Lessons Learned (For Future Agents)

- (filled at closeout)


---

▶ TAKE YOUR TURN (agy — BUILDER role)

You are the BUILDER for this phase. Read the phase brief above and implement it.
APPEND-ONLY FILE (GH-529 attestation): add your block at the END and never delete, reorder, or rewrite any existing content — the terminal attestation refuses the approval if any byte above your block changed, even a tidy-up.
1. Implement the brief by creating/editing the artifact file(s): utils/py/consult.py, skills/1-hourly/consult/SKILL.md, TESTS-RESULTS/2026-10-25+GH-1219/manual-check.md, TESTS-RESULTS/2026-10-25+GH-1219/provenance.jsonl
2. Append a build block to this relay file: `### Round N · Builder · agy` summarizing what you did (files touched, key decisions).
3. Use this exact tick binary (run it from any directory): /Users/noelsaw/marathon-clones/marathon-gh-1214-lessons-readback/bin/tick
   - /Users/noelsaw/marathon-clones/marathon-gh-1214-lessons-readback/bin/tick claim MARATHON-P3-TURN --agent agy --paths "marathon-system/gh1214-lessons-readback--p3/RELAY.md,utils/py/consult.py, skills/1-hourly/consult/SKILL.md, TESTS-RESULTS/2026-10-25+GH-1219/manual-check.md, TESTS-RESULTS/2026-10-25+GH-1219/provenance.jsonl"
   - /Users/noelsaw/marathon-clones/marathon-gh-1214-lessons-readback/bin/tick ping MARATHON-P3-TURN --agent agy
   - /Users/noelsaw/marathon-clones/marathon-gh-1214-lessons-readback/bin/tick release MARATHON-P3-TURN --agent agy --to codex
4. Edit ONLY these paths: marathon-system/gh1214-lessons-readback--p3/RELAY.md and utils/py/consult.py, skills/1-hourly/consult/SKILL.md, TESTS-RESULTS/2026-10-25+GH-1219/manual-check.md, TESTS-RESULTS/2026-10-25+GH-1219/provenance.jsonl. Do NOT run git. Do NOT touch any other file — the harness commits for you.
5. HAND OFF EXPLICITLY (GH-268): after releasing the token, end your turn by naming who acts next —
   "handing off to codex — codex, take your turn." A turn that ends without that line
   leaves a human guessing whether the relay is waiting on them or has stalled. Do this EVERY round,
   not just the first. ALSO, you MUST update the `NEXT:` line at the top of this file to exactly: `NEXT: codex (Reviewer)`

---

▶ TAKE YOUR TURN (codex — REVIEWER role)

You are the REVIEWER for this phase. Read the latest builder block above AND review the artifact file(s) on disk: utils/py/consult.py, skills/1-hourly/consult/SKILL.md, TESTS-RESULTS/2026-10-25+GH-1219/manual-check.md, TESTS-RESULTS/2026-10-25+GH-1219/provenance.jsonl. REVIEW THE WHOLE FILE, NOT JUST THE DIFF (GH-268): a beta test had this loop reach 'Approved' in two rounds while an independent audit of the same branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN SCOPE; say so explicitly if you find none. DECLARE IT: your review block MUST contain a literal 'swept file: yes' or 'swept file: no' line — without it a reviewer that skipped the sweep is indistinguishable in the transcript from one that did it and found nothing, which is exactly how those 20 issues stayed invisible.
APPEND-ONLY FILE (GH-529 attestation): add your block at the END and never delete, reorder, or rewrite any existing content — the terminal attestation refuses the approval if any byte above your block changed, even a tidy-up.
1. Append a review block: `### Round N · Reviewer · codex` followed by your assessment.
2. If changes needed: add `**Verdict:** Changes requested`, update the `NEXT:` line to exactly `NEXT: agy (Builder)`, then: /Users/noelsaw/marathon-clones/marathon-gh-1214-lessons-readback/bin/tick release MARATHON-P3-TURN --agent codex --to agy
3. If satisfied: add `**Verdict:** Approved`, set `STATUS: Approved`, then: /Users/noelsaw/marathon-clones/marathon-gh-1214-lessons-readback/bin/tick done MARATHON-P3-TURN --agent codex
4. Use this exact tick binary (run it from any directory) for all token operations: /Users/noelsaw/marathon-clones/marathon-gh-1214-lessons-readback/bin/tick
   Edit ONLY marathon-system/gh1214-lessons-readback--p3/RELAY.md (your review block + STATUS). Do NOT edit the artifact yourself — request changes instead. Do NOT run git.
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
