---
gh_issue: 1265
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1265
title: "consult: add the installed kimi and cmd seats so a degraded pair can be re-fired without API keys"
status: Proposed (1-INBOX — not yet active)
created: 2026-10-30
owner: unassigned
doc_type: feedback
complexity: 2
risk: 1
effort: 2
phases: 1
ratings_provisional: true
non_goals:
  - no automatic seat substitution
  - no cost capture
  - no change to the codex,agy default
  - no sidecar schema
related:
  - GH-178
  - GH-492
  - #1258
goal: >
  TODO: one-paragraph statement of what "done" looks like for this idea.
---

## Key concepts

- kimi/cmd branches mirroring agy
- each shim's own invocation (KIMI_BIN -p; COMMANDCODE_BIN --print)
- vendor words in the neutralizer
- Python --help text; frozen Bash twin untouched

> **Note for plan writers:** apply the `/ponytail` lens — favor the laziest approach that actually
> works over new infrastructure, and question whether new surface needs to exist at all.

# consult: add the installed kimi and cmd seats so a degraded pair can be re-fired without API keys

## Status

| What was just completed | What's next |
|---|---|
| Captured via HQ (`/hq park`) for project **XYZ-forge** → repo `XYZ-forge`. The GitHub issue is the signal stream; this doc is the in-repo capture and back-reference. | Fill in Why/Key Concepts, correct the provisional ratings above, and run a Phase 0 explore pass before promoting to `2-WORKING`. |

## Idea

## Observed (2026-10-30, `development@e305cbf3`)

| Claim | Command | Observed |
|---|---|---|
| A consult can lose a seat to an external timeout | `relay-system/2026-10-29/gh1258-plan-223724/DEGRADED-SINGLE-MODEL.txt`; re-fire `relay-system/2026-10-29/gh1258-plan-agy-224323/` | agy killed at the idle threshold twice in one review episode on 2026-10-29 (`timeout-idle-in-flight`, both before the 599 s wall cap); the plan review of #1258 shipped as a single-model record |
| Only codex, agy, aider, claude, muse can be seats | `grep -n 'elif m ==' utils/py/consult.py` (`:767-839`); `relay-automation/consult.sh:51-56` | `--models` branches exist for `claude`, `codex`, `agy`, `gemini` (alias), `aider` (needs `OPENROUTER_API_KEY`), `muse`; any other name hits `consult.sh:305` "unknown model — skipping" |
| Two more seats are installed and already wired as relay workers | `find-harness.sh --check`; `ls relay-automation/*-turn.sh` | `kimi` (`/Users/<user>/.kimi-code/bin/kimi`, `kimi-turn.sh` → `utils/py/kimi-turn.py`, headless `kimi -p "<prompt>"`) and `cmd` (`commandcode-turn.sh`) are on PATH and have turn shims, but no consult branch |
| The neutralizer would leak a new seat's vendor words | `utils/py/consult.py:291-295` | the regex strips `re.escape(advisor)` (so a seat's own name is removed) plus `codex|agy|gemini|claude|aider|muse` and `openai|anthropic|openrouter|antigravity`; `Moonshot` and `Commandcode` are not in the list, so an in-memory replay of "I am kimi from Moonshot" leaves `Moonshot` in the neutral payload |

## Diagnosis / existing gap

`consult.py` enumerates advisors by hand (GH-178 A1 names this as the extension point: add the vendor invocation and reuse `guarded_with_timeout`). The relay side already knows how to drive kimi and cmd headless; the consult side never gained the branches, so a degraded pair cannot be re-fired with an installed seat that needs no API key. One instance per missing seat; the agy branch (`consult.py:802-809`) is the shape to mirror.

## Plan

1. `utils/py/consult.py`: add `kimi` and `cmd` branches beside `agy` (`:802-809`), each with its shim's own invocation contract: kimi = `KIMI_BIN` → PATH → installer location (`utils/py/kimi-turn.py:45-47`), headless `kimi -p "<prompt>"`; cmd = `COMMANDCODE_BIN` and `--print` with the shim's headless flags (`utils/py/commandcode-turn.py:13,26,86`). Both through `guarded_with_timeout` with the same idle and wall bounds and the same result tuple; answer validation through the existing `advisor_answer_ok` (`:209`). Add the vendor words `moonshot` and `commandcode` to the neutralizer token list (`:293-294`); the seat's own name is already stripped by `re.escape(advisor)`.
2. `utils/py/consult.py` `--help` text (`:658`, the Python runtime's actual help): list the two names; `skills/1-hourly/consult/SKILL.md`: one line under the degrade note, "re-fire a degraded pair with `--models <survivor>,kimi`". `relay-automation/consult.sh` is the frozen Bash twin (banner at `:2`) and is **not** touched: preflight refuses a frozen artifact (`swarm_preflight.py:1474`).
3. No automatic fallback: a degraded run still reports the degrade; the operator chooses the re-fire seat (the consult skill's "degrade is stated, never silent" rule stays).

## Blast radius

| Seam | Where | What changes |
|---|---|---|
| advisor dispatch | `utils/py/consult.py:767-839` | two branches mirroring agy |
| answer validation and neutralization | `utils/py/consult.py:209`, `:248-300` | token list extended; validation reused |
| CLI help and skill doc | `utils/py/consult.py:658`, `skills/1-hourly/consult/SKILL.md` | text (the Bash twin `relay-automation/consult.sh` is frozen and untouched) |
| Existing suite | `test/consult.sh` (in `validate.sh`) | must stay green; it covers degrade and refusal paths with fake advisors |

Recon `e305cbf3`; base `development@e305cbf3`. Write-set: `utils/py/consult.py`, `skills/1-hourly/consult/SKILL.md`, `TESTS-RESULTS/<date>+GH-<this>/`. Route: full (`utils/py/consult.py` is not in a tier-2 subsystem); focused suite `test/consult.sh`. Builder: Codex or agy headless; reviewer: Codex relay.

## Dependencies

None. Related: GH-178 A1 (advisor extension point), GH-492 (idle threshold), #1258 (D2 records `models=` and degrade in the issue footer, so a re-fired seat is legible there).

## Acceptance

- [ ] `relay-automation/consult.sh --prompt "Reply with the single word OK." --models kimi --label probe` exits 0 with one non-empty `answer-*.md` whose payload contains `OK` (recorded). Red control: on the base the same command prints `unknown model 'kimi' — skipping` and exits 2 (no valid model reaches `die`, `consult.py:185,862`; recorded).
- [ ] The same for `--models cmd` (recorded; if `cmd` is not authenticated on the box, the run must fail as a stated advisor failure, not a silent 0, and the receipt says so).
- [ ] Neutralizer witness: a prompt that makes the seat name its vendor ("state your vendor") yields a neutral payload with no `kimi`, `moonshot`, `cmd` or `commandcode` token (recorded). Red control: on the base, an in-memory `_neutralize_answer_text` replay of "I am kimi from Moonshot" keeps `Moonshot` (recorded).
- [ ] `--models codex,agy` output layout is unchanged: both runs exit 0 and both produce `answer-A.md`, `answer-B.md` and `key.json` (asserted present and non-empty before comparing), and the sorted file-name sets are equal (an empty pair does not pass; recorded).
- [ ] `bash test/consult.sh` passes on the final commit.

## Verification

Existing suite `test/consult.sh` (GH-831: no new tests), run in a separate disposable full clone (AGENTS.md: mutation-heavy suites never run in a valued checkout). The live witnesses are manual checks recorded under `TESTS-RESULTS/<date>+GH-<this>/` with `provenance.jsonl` in the same PR; they run un-sandboxed (keychain and network).

## Non-goals

No automatic seat substitution; no cost capture for the new seats (agy has none either); no change to the pair default (`codex,agy`); no new sidecar schema; no profile machinery.

## Risk and rollback

Risk: a seat whose CLI prints banners the neutralizer does not know leaks its identity into the neutral payload; the token-list extension covers the two names and the vendor words, and `NO-CITATION`/`PROVENANCE` sidecars still apply. Rollback: revert the commit; `--models kimi` returns to "unknown model".

## PRS proposal

- pri 50: the flywheel's review records lean on a two-seat consult (#1258 D2); one review episode on 2026-10-29 lost its second seat twice and shipped single-model.
- sev 40: a degraded panel is stated, not hidden, so nothing is lost; the cost is a weaker review record and a wasted 10-minute cap.
- appeal 50: operator did not set a preference.
- effort 70: two branches mirroring an existing one, plus text; the live witnesses need authenticated CLIs on the box.

## Preflight Contract

```json
{
  "target": { "repo": ".", "ref": "development" },
  "gate": "bash test/consult.sh",
  "fix_probes": [
    { "type": "grep_absent", "path": "utils/py/consult.py", "pattern": "m == \"kimi\"",
      "note": "pre-fix: no kimi branch in the dispatch; landed when present" }
  ],
  "artifacts": [ "utils/py/consult.py", "skills/1-hourly/consult/SKILL.md" ],
  "remediation": {
    "source": "issue#<this>",
    "criteria": "kimi and cmd dispatch branches mirroring agy with each shim's own invocation (KIMI_BIN / COMMANDCODE_BIN --print), vendor words added to the neutralizer, Python --help and skill text; the frozen Bash twin is untouched; no automatic fallback, no new test (GH-831)."
  }
}
```

Recon: e305cbf3 · base: development@e305cbf3 · tier: standard · review: consult relay-system/2026-10-30/gh-idea-B-draft-113947 models=codex, degraded hash 1313bc69aae78934cb8e3b0feca9c54d0bf00c0c92e75db0bf7d70ae424ce08d

## Why

consult.py enumerates advisors by hand; kimi and cmd have relay shims but no consult branch, so when agy times out the panel ships single-model.

## Phase 0 — Explore & scope

### Checklist

- [ ] TODO: scope-specific checklist items for this idea's Phase 0 pass.

### QA checklist — Phase 0

- [ ] TODO: acceptance criteria for the Phase 0 pass above.

## Merge evidence

- PR #1268 merged 2026-10-31 — linked issue still OPEN; doc stays active by design (GH-202: promotion requires the issue to be closed).
