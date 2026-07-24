---
gh_issue: 279
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/279
title: "aider-qwen marathon trial — consolidated run issues (edit-format mismatch, empty-artifact escape, watchdog blast-radius, failure-tally gap)"
status: "Promoted to 2-WORKING 2026-07-23 — scoped down to items 4 + 6a (the only remaining in-repo, fixable gaps), contract authored, ready to fire"
created: 2026-07-22
updated: 2026-07-23
owner: noel
doc_type: bugfix
effort: 2
complexity: 2
risk: 1
phases: 1
ratings_provisional: false
non_goals:
  - Items 1/2 (Aider↔Qwen edit-format mismatch) — RESOLVED via #280, not re-litigated here.
  - Item 3 (per-turn timeout default drift) — tracked separately as #278, not this issue's scope.
  - Item 5 (marathon failure-watchdog gaps) — grounded against the real repo before contracting
    (2026-07-23): no in-repo failure-tally/cap/watchdog mechanism exists anywhere in
    relay-automation/, utils/py/, or bin/ — the reporter's "external watchdog" was a genuinely
    external, one-off script for that single investigation, not part of this harness. Nothing to
    fix here; not a residual, just not applicable.
  - Item 6b (bare `timeout(1)` on macOS) — grounded against the real repo (2026-07-23): already
    solved correctly. Every turn shim uses `rtl_run_bounded()` (relay-turn-lib.sh:390-414), a
    portable sleep+kill wrapper explicitly documented as a macOS-`timeout`-absence workaround; no
    bare `timeout` invocation exists anywhere in the repo. Not applicable.
related:
  - "#278 — per-turn timeout drift, item 3's own tracker, independently actionable, not fired here"
  - "#280 — resolved the edit-format mismatch (items 1/2)"
goal: >
  The two remaining real, in-repo gaps from the aider-qwen trial: (a) a killed/no-op builder turn's
  empty pre-created artifact stub is classified as "artifact appeared" instead of no-progress, and
  (b) the aider-turn shim's AIDER_OPENAI_API_BASE seam passes the API key as a literal CLI argument,
  visible in `ps`, instead of via environment.
---

# GH-279 · aider-qwen marathon trial — consolidated run issues

Punch list of harness defects surfaced while trialing `aider-qwen` (Aider + `qwen3.8-max-preview`) as a
marathon builder against `codex` as reviewer, on the GH-268 Phase 1 installer lanes (2026-07-22). The
builder/reviewer wiring itself is sound (one lane landed cleanly); these are the harness-side gaps found
along the way, independent of which model ends up being the reliable builder (see GH-280 for that
question).

## Status
| What was just completed | What's next |
|---|---|
| 2026-07-23: promoted to 2-WORKING. Re-grounded all 6 original items against the live repo (a subagent investigation, not the issue's prose) before scoping the contract: items 1/2 already resolved via #280, item 3 tracked separately as #278, items 5 and 6b have no in-repo equivalent to fix (confirmed via direct code search, not assumed) — only items 4 and 6a are real, fixable, in-repo gaps. Authored a Swarm Preflight Contract scoped to exactly those two. | Fire via `swarm-preflight → marathon-drive` (codex builder, agy reviewer). |

## Original items (full detail in the GitHub issue)
1. ~~Aider↔Qwen edit-format mismatch → empty artifacts~~ — **RESOLVED via #280** (`AIDER_FLAGS=--edit-format diff`).
2. ~~Chat-membership confusion on multi-file turns → no-op builder turns~~ — **RESOLVED**, was finding #1 restated (see #280).
3. Per-turn timeout default drift across `aider-turn.py`/`aider-turn.sh`/skill docs — **tracked separately as #278**, not this issue's scope.
4. **[IN SCOPE]** Empty/no-op builder turns commit empty stubs that read as "artifacts appeared" to a weak gate.
5. Marathon failure-watchdog gaps — **not applicable**, no in-repo watchdog/failure-tally mechanism exists; the reporter's watchdog was external, one-off tooling for that single trial.
6. Minor: **(a) [IN SCOPE]** API key visible in `ps` args; **(b) not applicable**, `timeout(1)` portability is already solved via `rtl_run_bounded()`.

## Swarm Preflight Contract

```json
{
  "target": { "repo": ".", "ref": "development" },
  "gate": "bash validate.sh",
  "fix_probes": [
    { "type": "grep_present", "path": "relay-automation/marathon-drive.sh", "pattern": "artifacts_exist_for_timeout" },
    { "type": "grep_present", "path": "utils/py/marathon_drive.py", "pattern": "def artifacts_exist" },
    { "type": "grep_present", "path": "relay-automation/aider-turn.sh", "pattern": "openai-api-key" },
    { "type": "grep_present", "path": "utils/py/aider-turn.py", "pattern": "openai-api-key" }
  ],
  "artifacts": [
    "relay-automation/marathon-drive.sh",
    "utils/py/marathon_drive.py",
    "relay-automation/aider-turn.sh",
    "utils/py/aider-turn.py",
    "test/marathon-drive.sh",
    "test/aider-turn.sh"
  ],
  "remediation": {
    "source": "issue#279",
    "criteria": "TWO independent fixes, both grounded against real code (file:line confirmed 2026-07-23, not guessed from the issue prose):\n\n(1) Zero-byte/unchanged artifact classification (item 4). `artifacts_exist_for_timeout()` in relay-automation/marathon-drive.sh:355-370 and `artifacts_exist()` in utils/py/marathon_drive.py:733-744 both check ONLY existence (`[[ -e \"$path\" ]]` / `os.path.exists(ap)`), so a 0-byte newly-created stub from a killed/no-op turn passes as 'artifact appeared' (marathon-drive.sh:949/1013, marathon_drive.py). A stricter pattern already exists in the SAME files for a different feature — `requires_test_delta()` (marathon-drive.sh:379-394) / `requires_test_delta` (marathon_drive.py:498) — which checks non-empty (`-s`) AND a git-diff/untracked delta since PRE_PHASE_HEAD. Reuse that existing pattern for the general artifact-appeared check in BOTH runtimes: a declared artifact must be non-empty AND changed since PRE_PHASE_HEAD to count as 'appeared'; a killed or no-op turn's untouched/empty stub must be classified as no-progress instead. Do not weaken the existing requires_test_delta path — extend/reuse it, don't replace it.\n\n(2) API key exposed in ps argv (item 6a). relay-automation/aider-turn.sh:126 builds `aider_auth_args=(--openai-api-base \"$AIDER_OPENAI_API_BASE\" --openai-api-key \"${AIDER_OPENAI_API_KEY:-dummy}\")` — the key is a literal CLI argument, visible to any local `ps` call. utils/py/aider-turn.py:77 does the same (`\"--openai-api-key\", os.environ.get(\"AIDER_OPENAI_API_KEY\", \"dummy\")`). This ONLY fires on the AIDER_OPENAI_API_BASE seam (direct-MaaS/LM-Studio path) — the default OPENROUTER_API_KEY seam already reads from env natively via aider/litellm, untouched. Fix: pass the key to the aider subprocess via an environment variable (e.g. OPENAI_API_KEY, which litellm/aider read natively) in BOTH runtimes instead of the --openai-api-key CLI flag, dropping the flag from the invocation. Before committing this: EMPIRICALLY VERIFY aider actually honors an env-var-supplied key on this seam (run it against a stub/real endpoint and confirm the key is no longer in the subprocess argv, e.g. via `ps` or by asserting on the captured invocation in the test) rather than assuming from aider's docs alone. If aider's CLI genuinely requires the literal flag on this path (no env alternative), do NOT silently leave it broken — document that specific finding in this doc's Status table as a confirmed residual with the verification evidence, rather than fixing it.\n\nAdd regression tests: test/marathon-drive.sh gets a zero-byte-artifact case (declared artifact exists but is 0 bytes -> must NOT be classified as appeared) and an unchanged-artifact case (declared artifact pre-exists unchanged since PRE_PHASE_HEAD -> must NOT be classified as appeared), mirroring the existing requires_test_delta test pattern. test/aider-turn.sh gets a case asserting the captured aider invocation's argv does not contain the literal API key string when AIDER_OPENAI_API_BASE is set (or documents the confirmed residual per above). Both test files already exist with established STUB patterns — extend them, do not rewrite."
  },
  "lanes": { "agy_safe": [ "relay-automation/marathon-drive.sh", "utils/py/marathon_drive.py", "relay-automation/aider-turn.sh", "utils/py/aider-turn.py", "test/marathon-drive.sh", "test/aider-turn.sh" ], "orchestrator_only": [] }
}
```
