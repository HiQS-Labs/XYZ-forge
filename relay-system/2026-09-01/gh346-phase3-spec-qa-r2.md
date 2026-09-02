---
Goal: Round 2 QA — does the revised GH-346 Phase 3 spec actually close round 1's findings?
Date: 2026-09-01
Reviewer: agy
NEXT: Author
STATUS: Approved
---

# Context

You reviewed this spec once already and returned nine findings with the verdict *"the spec needs to
be rewritten."* It has since been revised three times. **This round adjudicates the revisions, not
the original design.**

Read in full:
- `PROJECT/1-INBOX/GH-346-PHASE-3-SPEC.md` — the revised spec under review
- `relay-system/2026-09-01/gh346-phase3-spec-qa.md` — **your own round-1 findings**, verbatim
- `PROJECT/1-INBOX/GH-346-HARNESS-GATEWAY-MODEL-RESOLUTION.md` — Phases 0-2, shipped

Supporting code the revisions now depend on:
- `utils/py/device_config.py` — the 3-tier resolver the `profiles` block extends
- `utils/py/commandcode-turn.py:130-152` — the gateway literal that was corrected this round
- `utils/py/deepseek-turn.py:35-48` — the contrast case (a real OpenRouter overlay)
- `relay-automation/resolve-model-alias.sh:63-74` — the flat parser, now normalization-only
- `utils/py/harness_app.py` — the `models` table tier 3 was narrowed to
- `utils/py/marathon_drive.py` `route_agent` — the lane set the resolver must derive from

**This is a REVIEW turn. Do not edit any file except this relay thread.** Cite `file:line`.

## What changed since you last saw it

| Your round-1 finding | What the spec did |
|---|---|
| #1a GLM 5.3 wired to `gateway: openrouter`, contradicting the operator | **Accepted.** Profile is now `gateway: commandcode`. The rejection was retracted in place and `commandcode-turn.py`'s literal fixed. |
| #1b `resolve-model-alias.sh` cannot parse nested YAML | **Accepted.** No YAML file. Profiles live in `device_config.json`, parsed by `device_config.py`; the bash script is normalization-only. |
| #2 Tier 3 degrading to tier 4 silently does the wrong thing | **Partially accepted.** Tier kept; every fallback must announce which tier answered (stderr + `--explain`). |
| #3 `invocation_logs` turns history into policy | **Accepted.** Tier 3 reads `models` only. |
| #4 The prefs file becomes the eleventh allowlist | **Argued, not fixed.** Claim: folding into `device_config.json` avoids a new file, and the lane set is derived from `route_agent`. |
| #5 Malformed config blocks a turn | **Accepted.** Parse errors are now explicitly a fall-through, not a raise. |
| #6 3c's proof misses the var-set case | **Accepted.** Proof is now "both set and unset". |
| #7 Cache folded into 3a; `harnesses-merge-resolve.sh` in a parenthetical | **Accepted.** Cache is its own Phase 3d; the resolver script is named as a prerequisite for any hard dependency. |
| #8 Four design questions | Answered inline; #3 (`effort`) namespaced per gateway. |
| #9 "Drop tier 3 entirely" | **NOT adopted** — narrowed instead. Reasoning is in "Findings recorded but NOT adopted". |

Scope also narrowed on the operator's instruction: **"My main use case is around the relay-xyz
reviewer alias"**, and *"don't add any new feature to profile-pin a reviewer in the build → review
path."* Phase 3a now ships that alias alone and touches no shim.

## Questions

1. **Verify each "Accepted" row above against the spec text.** Any row where the spec *claims* to
   have taken your finding but the change is cosmetic, incomplete, or introduces a new gap — say so
   and cite the line. Do not take the table's word for it.

2. **Re-attack #4, the one that was argued rather than fixed.** The `profiles` block is still a
   hand-maintained list of names. What makes it fail loudly when a model id changes, a harness is
   deprecated, or a profile names a lane `route_agent` no longer has? If nothing does, name the
   cheapest check that would — and say whether it belongs in 3a or can wait.

3. **Re-attack #9, the one that was refused.** Tier 3 is narrowed to `models.gateway`, not dropped.
   The spec adds that `models.gateway` says where a model is *reachable*, not which router a harness
   *used* — so it must be a hint, never an override for a harness that is its own router. Is that
   distinction actually implementable from the `models` table as it exists, or does the table lack
   the column that would let a resolver tell those two cases apart? If it lacks it, tier 3 cannot be
   built as specified and should be dropped after all.

4. **Does Phase 3a alone satisfy the operator's stated main use case?** Walk `relay-xyz with GLM 5.3
   max` end to end using **only** tiers 1, 2 and 4 — no `harnesses.db`. Does it reach Command Code →
   `zai-org/glm-5.3` with `effort: max`, and does `--env` emit every variable
   `relay-drive.sh --review-once` actually needs? Name anything missing from that env block.

5. **The Command Code correction — is the data model now right?** The spec asserts Command Code is
   both harness and router, so `harness == gateway` on that lane, while DeepSeek → OpenRouter is a
   genuine three-element path. Check that against the shims. Does a `{harness, gateway, model}`
   profile shape handle both cleanly, or does the collapsed case need explicit representation
   (e.g. `gateway: null` / `gateway: self`) to stop a future resolver from "helpfully" inserting a
   router that isn't there?

6. **Phase 3c is deferred and carries a coupling.** The spec says while 3c is deferred, the ROI
   checkpoint item "telemetry matches dispatch for all 8 gateways" must stay unticked. Is that the
   correct and complete consequence of deferring 3c, or does deferring it leave another claim
   somewhere in Phases 0-2 that is now overstated?

7. **Is the spec now implementable without further clarification?** Concretely: could two
   implementers read this and build the same 3a? Name every remaining place where they would not.

8. **Anything new the revisions broke.** Three rounds of edits on one document is how contradictions
   get in. If the spec is now sound, say so plainly rather than manufacturing findings.

Write your verdict below. Set `STATUS: Approved` if 3a is ready to implement, or leave it `Open`
with findings.

## QA Findings

<!-- ▽ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK ▽ -->
▶ TAKE YOUR TURN (Author)
<!-- △ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK △ -->

1. **Verify each "Accepted" row:**
   - **#1a GLM 5.3 to CommandCode:** Accepted. Profile uses `gateway: commandcode` (`GH-346-PHASE-3-SPEC.md:117-118`).
   - **#1b No YAML file:** Accepted. The spec correctly shifts to JSON parsed by `device_config.py` (`GH-346-PHASE-3-SPEC.md:111-124`).
   - **#2 Tier 3 degrades silently:** Accepted. `--explain` and stderr reporting are required, eliminating silent fallback (`GH-346-PHASE-3-SPEC.md:162, 191`).
   - **#3 History into policy:** Accepted. Tier 3 is restricted to the curated `models` table (`GH-346-PHASE-3-SPEC.md:177`).
   - **#5 Malformed config:** Accepted. Parse errors fall through and report on stderr (`GH-346-PHASE-3-SPEC.md:190-194`).
   - **#6 3c proof misses var-set:** Accepted. Proof now explicitly tests "both set and unset" (`GH-346-PHASE-3-SPEC.md:271-272`).
   - **#7 Cache folded into 3a:** Accepted. Separated into Phase 3d, and the merge resolver is properly named as a prerequisite for a hard dependency (`GH-346-PHASE-3-SPEC.md:196, 220-221, 280-284`).

2. **Re-attack #4 (Argued, not fixed):**
   The spec relies on non-blocking fallback, so if a profile names a deprecated harness or an invalid model, it degrades to Tier 3 or 4 and silently runs a different model. The cheapest check to ensure it fails loudly is an automated validation step (e.g., added to `check_integrity` in `utils/py/harness_app.py` or a CI test) that parses `device_config.json` and asserts every profile's `harness` exists in `route_agent()` and `model` exists in the `models` table. This belongs in Phase 3a so the new config surface starts with integrity checking.

3. **Re-attack #9 (Refused):**
   The DB lacks the necessary column. The `models` table has a `gateway` column, but neither the `models` nor `harnesses` table has any indicator for "this harness is its own router and ignores the model's gateway." Without this distinction, a resolver using Tier 3 will erroneously apply the model's reachable gateway (e.g., `openrouter` for `GLM-5.3`) to harnesses that don't route through it (CommandCode). This would reinject the exact data model error Phase 0 fixed. Tier 3 cannot be built as specified and must be dropped.

4. **Does Phase 3a alone satisfy the main use case?**
   Walk `glm 5.3 max`: Tier 2 profile matches. The spec says `--env` emits `RELAY_AGENT_CMD`, `*_AGENT`, `*_MODEL`, `*_REASONING_EFFORT`, `*_FLAGS`, `$HARNESS`, `$TICK` (`GH-346-PHASE-3-SPEC.md:245-247`). It misses the gateway variable (e.g., `COMMANDCODE_GATEWAY`). If the resolver doesn't emit this, the shim will use its hardcoded literal, risking telemetry drift.

5. **Command Code correction — is the data model now right?**
   The `{harness, gateway, model}` shape handles OpenRouter well, but for CommandCode, `gateway: commandcode` is weak. It allows invalid permutations like `harness: commandcode, gateway: openrouter`. If parsed, the resolver would emit `COMMANDCODE_GATEWAY=openrouter`. The shim would still route through its internal catalog, but telemetry would silently lie and record `openrouter`. The collapsed case needs explicit representation (e.g., `gateway: null` or `gateway: self`) to enforce that the harness cannot use a third-party gateway, protecting telemetry integrity.

6. **Phase 3c coupling:**
   Deferring Phase 3c leaves a gap in Phase 0.5's completion claim. If `agy` and `codex` pass no model when unset, they record `device_config`'s declared default. However, without Phase 3c telling the shim what that default is, the shim executes its own internal hardcoded default. This means the telemetry model *still* does not match the actual dispatched model for these gateways, and Phase 0.5's proof ("shows the right model") is overstated and validating a lie.

7. **Is the spec implementable without clarification?**
   No. The spec claims Phase 3a "reuses `resolve-model-alias.sh` for normalization only" (`GH-346-PHASE-3-SPEC.md:248-249`) while Python parses the JSON. However, `resolve-model-alias.sh` is tightly coupled to reading the flat `openrouter-model-aliases.yml` file (`resolve-model-alias.sh:62-73`) and does not expose its normalizer functions (`normalize`, `squash`) as an importable library or accept candidate lists via stdin. Implementers would diverge: one might rewrite the bash string manipulation in Python, another might refactor the bash script, and a third might have Python write a temporary flat text file to feed the bash script via `MODEL_ALIASES_FILE=...`.

8. **Anything new the revisions broke?**
   The revisions are a massive improvement, closing almost all round-1 holes. The remaining flaws are the stubborn inclusion of Tier 3 (which the DB schema cannot support), the lack of validation for the JSON profiles, and the false assumption that the bash alias script can be trivially reused as a pure normalizer library by a Python script.

**Verdict**: The spec is very close but still Open. Drop Tier 3 entirely (the schema doesn't support it), add a validation check for `device_config.json` profiles, require explicit representation for self-routing gateways (`gateway: null`), and specify exactly how Python will interface with the bash alias script's normalization logic.

## Log

- 2026-08-31 (agy): Reviewed GH-346 Phase 3 Spec R2.

VERDICT: FAIL
Basis: The spec still includes Tier 3 which cannot be implemented given the DB schema. `device_config.json` needs explicit integrity checking to avoid drifting allowlists. Command Code routing needs an explicit null/self marker to avoid invalid permutations.

---

## Author's adjudication — round 2 CLOSED

Full working in `gh346-phase3-spec-qa-r2-adjudication.md`. **Six findings, none dismissed.** Every
one was checked against the code before adjudication, per the standing rule on this issue.

| # | Finding | Outcome |
|---|---|---|
| 4 | `--env` omits `*_GATEWAY` | **Upheld.** Added. It became load-bearing this round — `commandcode-turn.py:141` now reads it, so a resolver emitting everything else leaves the shim on its literal. |
| 2 | Nothing validates the `profiles` block | **Upheld.** Folded into `test/gh346-gateway-allowlists.sh` — a test, never a runtime raise. |
| 5 | The shape permits `{commandcode, openrouter}` | **Upheld — the round's sharpest finding.** `"gateway": "self"`, validated. |
| 3 | Schema cannot express self-routing → drop tier 3 | **Fact upheld, conclusion declined.** Verified: no column in `models` or `harnesses`, and `execution_engine` does not encode it. But mandatory `gateway` means tier 3 is never asked for one. |
| 6 | Deferring 3c leaves a second overstated claim | **Upheld.** Checkbox 0.4 said "each shim"; untrue for two. Scoped, not unticked — the test is real, the sentence overreached. |
| 7 | The bash/Python normalizer seam is unspecified | **Upheld and closed in code, not deferred.** |

### On #7 — the fix was one character

You predicted three divergent implementations, all of which grow a second matcher. The script
already read `$MODEL_ALIASES_FILE`; only its `-f` guard refused a pipe. That is now `-r`:

```bash
printf 'glm 5.3 max: zai-org/glm-5.3\n' | MODEL_ALIASES_FILE=/dev/stdin resolve-model-alias.sh "GLM5.3 Max"
# -> zai-org/glm-5.3
```

Six new cases in `test/model-alias.sh` (21 pass) pin it, including that an unreadable path still
exits 2 — loosening the guard must admit a pipe, not treat a missing table as an empty one. One
matcher, no parity test, no new file, no new validate.sh entry.

### One thing your review did not catch, found while acting on it

**There are seven turn shims, not eight.** `utils/py/*-turn.py` is agy, aider, claude, codex,
commandcode, deepseek, pi. The "8 gateways" figure came from `test/gh346-telemetry-row-written.sh`
printing "8 pass" — 8 *assertions*, 7 gateways plus one that the scratch DB was written. It had
propagated into the capture doc, this spec, the ROI checkpoint, and a test header comment. All
corrected.

That makes the original Phase 0 claim — *"harnesses.db records the wrong model for 5 of 8
gateways"* — wrong in both halves: the numerator was already retracted in round 1, and the
denominator was never right either.

**Verdict accepted in full. Phase 3a is now specified.** Still gated on the Phase 2 ROI checkpoint.
