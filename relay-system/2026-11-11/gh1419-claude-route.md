# GH1419 live Claude reviewer-route smoke
STATUS: Open
NEXT: claude-builder

Scope: independent read-only routing review of commit d7939db9. Inspect utils/py/marathon_drive.py route_agent, utils/py/jog_run.py validate_marathon_executor, relay-automation/marathon-agent.sh, and src/marathon-yaml.js recognition. This turn is dispatched through the real Marathon dispatcher with CLAUDE_AGENT=claude-builder,claude-reviewer and exact RELAY_AGENT=claude-reviewer. Do not build, run gates, call other models, or change source. Only append this relay file. Check distinct actor retention, scalar shim identity, unknown-route refusal and whether a concrete routing defect remains. Return concise source-backed findings, literal swept file: yes, and **Verdict:** Approved or Changes requested. Use heading `### Round 1 · Reviewer · claude-reviewer` then plain paragraphs (no nested headings). If approved set STATUS: Approved, NEXT: claude-builder; otherwise STATUS: Open, NEXT: claude-builder. This is a bounded real reviewer-path smoke, not full final QA or a claim about all providers.

### Round 1 · Reviewer · claude-reviewer

Swept files: `utils/py/marathon_drive.py` (route_agent, _probe_agent_bin, --validate-agent-routes), `utils/py/jog_run.py` (validate_marathon_executor), `relay-automation/marathon-agent.sh`, `src/marathon-yaml.js` (validateReviewer, resolveOrder). literal swept file: yes.

**Distinct actor retention.** With `CLAUDE_AGENT=claude-builder,claude-reviewer` and `RELAY_AGENT=claude-reviewer`, the `marathon-agent.sh` loop (lines 48–59) splits the comma-list and matches the scalar `claude-reviewer`. On match it immediately narrows the slot with `export CLAUDE_AGENT=claude-reviewer` before `exec claude-turn.sh` (line 55–56). The shim therefore sees a scalar, not the comma-list. The comment at line 46–47 ("Its own identity check must not silently defer a comma-list actor") is enforced structurally. Actor identities are retained correctly.

**Scalar shim identity.** The narrowing `export "$slot=$me"` at line 55 is applied unconditionally before the exec, so every shim — regardless of how many comma-separated ids were configured — always receives exactly the matched id. No silent deferral possible.

**Unknown-route refusal.** Two independent layers refuse an unrecognized actor: (1) `route_agent()` in `marathon_drive.py:865` raises `ValueError("agent '...' not recognized — must start with claude/codex/...")` for any id whose prefix is not in the allowlist; (2) `marathon-agent.sh:60` reaches `die "unknown agent '$me'; configure its provider *_AGENT slot"` (exit 2) if the loop exhausts all lanes without a match. Both are fail-closed and produce diagnostic output.

**validate_marathon_executor actor admission.** `jog_run.py:224–226` calls `route_agent(actor, {})` (empty dict, not `os.environ`) plus `_probe_agent_bin(actor, role)` for both builder and reviewer before any lease mutation. `ValueError` and `SystemExit` are caught and returned as error strings. The `_RESULT` save/restore (lines 221, 232–233) prevents tainting the driver's state. The reviewer ≠ builder check at line 212 prevents same-agent routing. No gap found.

**_probe_agent_bin coverage.** The `else` branch at `marathon_drive.py:917–926` now dies loudly if `route_agent` accepts an id but `_probe_agent_bin` has no branch for it ("routable but has no binary probe — GH-117"). The kimi lane (GH-1215) has its own branch (lines 910–916). No missing lane detected for the nine recognized prefixes (claude/codex/agy/aider/pi/smallcode/commandcode/deepseek/kimi).

**marathon-yaml.js reviewer validation.** `validateReviewer` (line 106–116) shells out to `marathon_drive.py --validate-agent-routes <reviewer>`, which calls `route_agent(actor, {})` for each actor passed. A non-zero exit or spawn error throws, blocking plan acceptance. This correctly delegates YAML-level reviewer validation to the same Python routing machinery.

**Minor observation (not a defect).** In `marathon-agent.sh` lines 38–43, the RELAY_PEER `else` branch sets `RELAY_PEER="$MARATHON_BUILDER"` whenever `$me != $MARATHON_BUILDER`, regardless of whether `$me` is actually the reviewer. In a two-actor run this is always correct. A hypothetical third actor would receive a misleading RELAY_PEER before hitting `die "unknown agent"` at line 60. The existing die() catches it; no live defect in the described two-actor scenario.

No concrete routing defect found. All four surfaces cooperate correctly for the `CLAUDE_AGENT=claude-builder,claude-reviewer` + `RELAY_AGENT=claude-reviewer` case under commit d7939db9.

**Verdict:** Approved

### System · relay-drive — 2026-11-11T19:56:46Z
terminal STATUS Approved written by FAILED reviewer turn (claude-reviewer; shim returned non-zero) — reverted
