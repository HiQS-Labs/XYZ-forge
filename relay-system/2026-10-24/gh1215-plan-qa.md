# RELAY · GH-1215 plan QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-24.
-->

NEXT: Closed
STATUS: Approved
ROUND: 2 / 3

## ▶ TAKE YOUR TURN — read this first (works for ANY agent: Claude, Codex, agy)
1. **Read this whole file** (header, Setup, Ground rules, every block in the Log).
2. **Check it's your turn:** `NEXT` (top) names the role to act. Confirm you are bound to it and the
   last Log block isn't already yours. If not → STOP and reply "wrong window — nudge the <other> window."
3. **Do your role's work** on the artifact named in Setup:
   - **Reviewer:** review vs the Definition of Done → graded findings
     (`[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`), each with a concrete fix → set a **VERDICT**
     (exactly PASS, FAIL, or PARKED) and a **Basis** (explanation). **Review the whole file, not just the diff** (GH-268):
     a beta test had this loop reach `Approved` in two rounds while an independent audit of the same
     branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the
     change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN
     SCOPE; if you find none, say so explicitly rather than leaving it unstated.
     **Declare it: every review block must contain a literal `swept file: yes` or `swept file: no`
     line.** Without it a reviewer that skipped the sweep is indistinguishable in the transcript from
     one that did it and found nothing — which is how the original 20 issues stayed invisible.
     Any `[Pass]` or "verified"/"confirmed" finding MUST
     carry a quoted span or a `file:line` citation — an uncited one is mechanically downgraded to
     `[Unverified — no citation]` (GH-173 B3). Do **not** edit the artifact; only append findings here.
     **A finding that asks for a behaviour change is a generalization unless you can paste the concrete
     input — a row, a value, a `file:line` — that fails under the current code** (GH-681: the gh673
     final QA relay generalized one late-error observation into "or a later invalid identity", the
     Producer implemented it, the same seat `[Pass]`ed it next round, and one historical NULL-URL
     ledger row then blanked every issue). Every `[Blocker]` or `[Should]` requesting a behaviour
     change MUST carry three lines: `Observed input:` (the failing input you saw), `Affected scope:`
     (the input predicate the change would govern), `Falsifier:` (the fixture or data that would show
     the change unnecessary or wrong, and its expected result).
     A `[Blocker]` must cite an observed failure. This is a protocol rule, not a mechanical check —
     the Producer may disposition a request lacking these as `Declined — unproven generalization`.
   - **Producer:** log a disposition for every open finding (Implemented / Modified / Declined + why,
     including `Declined — unproven generalization` for a behaviour-change request that carries no
     `Observed input:` / `Affected scope:` / `Falsifier:`), make the change, then add new work.
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns.
   Reviewer headings may be `### Reviewer · Round N`, `### Round N · Reviewer · <agent>`, `### Reviewer (<agent>)` (optionally followed by `— rN`), or `### Reviewer — Round N` (optionally followed by `(<agent>)`); follow the heading with a non-empty review body.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(gh-1215-plan-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: `PROJECT/1-INBOX/GH-1215-KIMI-RELAY-WORKER.md` (the plan). No code is written yet.
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-10-24
- Definition of Done: the plan is grounded in the real code paths, covers R1-R7, extends the existing
  subsystems (no parallel writer or new suite), and its checks would catch the failure they name.

### Context for the reviewer

Issue: https://github.com/HiQS-Labs/XYZ-forge/issues/1215. Ask: add a native `kimi` relay worker
for the Kimi Code CLI, shaped like `muse-turn` (GH-518) and `deepseek-turn` (GH-148).

**Operational envelope:** a local developer CLI adapter on one Mac. Grade against the stated
requirements and commensurate complexity. Do not ask for multi-tenant fail-safes, new test suites,
new gate machinery, or a reviewer-grade evaluation; `AGENTS.md` forbids new tests (GH-831) and the
non-goals in the plan's frontmatter are deliberate.

Read in full: the plan; `utils/py/muse-turn.py`; `relay-automation/muse-turn.sh`;
`test/gh346-gateway-allowlists.sh` (its header lists the ten agent-id allowlists).
Read the cited spans: `utils/py/marathon_drive.py` (`_probe_agent_bin` ~771-818, the `*_AGENT`
reset ~1971-1981, `route_agent` ~1983-2029, the reviewer gate ~2043-2049, `GATE_SCRUBBED_ENV`
~2290-2305, the `*_TURN_ROOT` tuple ~3405-3417); `utils/py/gate_env.py` ~110-122;
`relay-automation/marathon-agent.sh`; `utils/py/relay_drive.py` `prepare_turn_log` ~144-165;
`utils/py/profile_resolve.py` `lanes()`, `_gateway_var_for`, `_cli_for` ~92-180;
`skills/1-hourly/relay-xyz/find-harness.sh` ~349-458; `skills/1-hourly/relay-xyz/SKILL.md` ~360-382;
`test/gh441-gate-env-contract.sh`.

Kimi CLI facts (live probes by the Producer, `kimi` 2.3.1): `kimi -p "<prompt>"` edits files and
runs Bash with no approval prompt; `--yolo`/`--auto` combined with `-p` exit 1 ("Cannot combine
--prompt with --yolo"); `-p -` does not read stdin (it treats `-` as the prompt); stream-json emits
`{"role":"meta",...}` version/resume events, `{"role":"assistant","content":...}` or
`{"role":"assistant","tool_calls":[...]}`, and `{"role":"tool",...}` lines.

Questions:

1. Is every claim in the plan's Recon table true at the cited paths? Cite file:line where it is not.
2. Is the allowlist list complete? Would adding `kimi` to `route_agent()` with exactly the edits in
   Plan step 3 leave `test/gh346-gateway-allowlists.sh` and `test/gh441-gate-env-contract.sh` green?
   Name any allowlist or derived consumer the plan misses (e.g. something else that parses
   `route_agent` or enumerates lanes).
3. Does `profile_resolve.lanes()` really route `kimi` with no change to `profile_resolve.py`, given
   the shim shape in Plan step 1 (`gateway=os.environ.get("KIMI_GATEWAY", ...)`, `shutil.which("kimi")`)?
4. Is the empty-output rule (no `role:assistant` line with non-empty `content` or `tool_calls` →
   exit 5) right for stream-json, and is stream-json a sound choice over text mode for the log that
   `rtl.enforce` reads? Check what `rtl_enforce` does with the log in `relay-automation/relay-turn-lib.sh`.
5. Is leaving Kimi out of the marathon reviewer gate (#6/#7) consistent with the done criterion,
   which uses `relay-drive.sh --reviewer kimi` rather than `marathon-drive.sh`?
6. Is the red control in Verification a real one (would it fail before the fix and pass after)?
7. Flag anything over-built, under-built, or missing. Keep findings to the stated scope.

Write a verdict below. Set STATUS to Approved if it passes; otherwise leave it Open and hand back.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer · Round 1

swept file: yes

VERDICT: FAIL

Basis: The implementation map is grounded and keeps Kimi out of the separate marathon-reviewer eligibility gates, but the stated verification/red-control sequence omits the necessary update to the existing lane-derived allowlist suite. Without it, the planned route addition makes that suite reject Kimi before it can verify the dispatcher or later allowlists.

- [Should] Add the required existing-suite amendments to Plan step 3 (or Verification): teach `test/gh346-gateway-allowlists.sh`'s `lane_env_var()` about `kimi`, and include `kimi` in its #8/#9 and #10 lane checks. Its lane set is dynamically derived from `route_agent()` (`test/gh346-gateway-allowlists.sh:49-72`), but its mapping currently enumerates only through `deepseek` (`test/gh346-gateway-allowlists.sh:85-90`) and #10 explicitly skips any other lane (`test/gh346-gateway-allowlists.sh:291-300`). Once Plan step 3 adds `route_agent("kimi")`, the test will iterate Kimi with an empty env-variable name, so its announced red control cannot reach the claimed “#3 dispatcher did NOT route 'kimi'” assertion. The current test is an existing behavior pin and needs adjustment, not a new suite; this follows the repository’s existing-test policy.
  Observed input: `test/gh346-gateway-allowlists.sh:85-90` has no `kimi) echo KIMI_AGENT ;;` arm while `test/gh346-gateway-allowlists.sh:49-66` derives every `route_agent()` prefix.
  Affected scope: any new `route_agent()` lane whose `_AGENT` mapping is absent from the existing suite.
  Falsifier: after adding `kimi) echo KIMI_AGENT ;;` and including Kimi in the #8/#9/#10 loops, a disposable-clone run of `bash test/gh346-gateway-allowlists.sh` should proceed to the intended dispatcher assertion; before the production dispatcher arm it must report `#3 dispatcher did NOT route 'kimi'`, and after that arm it must pass.

- [Pass] Leaving Kimi out of the marathon reviewer gates is consistent with R7’s direct `relay-drive` review: `relay_drive.py` accepts an unconstrained `--reviewer` argument (`utils/py/relay_drive.py:52-98`), while marathon explicitly limits reviewers to `codex`/`agy` (`utils/py/marathon_drive.py:2043-2050`; `src/marathon-yaml.js:113-119`). The plan’s separate `relay_drive.py` log-table update is also necessary because `prepare_turn_log()` owns per-shim log routing (`utils/py/relay_drive.py:145-166`).

- [Pass] The profile-routing claim is sound for the stated shim shape: lanes are derived from `route_agent()` assignments (`utils/py/profile_resolve.py:151-181`), gateway discovery recognizes direct `gateway=os.environ.get(...)` telemetry (`utils/py/profile_resolve.py:93-128`), and `shutil.which("kimi")` supplies the CLI fallback the resolver scans (`utils/py/profile_resolve.py:132-149`).

- [Pass] Stream JSON does not need to be human-readable to satisfy containment: `rtl_enforce` acts on the relay-file structure and its log handling treats the passed log as a transcript/cleanup path (`relay-automation/relay-turn-lib.sh:1384-1459`); the planned assistant-content-or-tool-call criterion is therefore a more specific empty-turn signal than Muse’s banner-filter guard (`utils/py/muse-turn.py:327-350`).

Probe (exit 0): `python3 -B - <<'PY' ...` parsed the current router and printed `current route lanes: claude,codex,agy,aider,pi,smallcode,commandcode,deepseek` and `kimi absent from route_agent: True`; it also confirmed representative final-lane entries exist in `relay_drive.py`, `gate_env.py`, and `marathon-agent.sh`. This supports the narrow conclusion that Kimi’s planned new route must be propagated into the test’s remaining curated mapping.

handing off to Producer — go to the Producer window and say 'take your turn'.

### Producer · Round 1 → 2

- **[Should] lane map in `test/gh346-gateway-allowlists.sh`** — Implemented. Verified at :85-90
  (`lane_env_var` stops at `deepseek`), :182 and :277 (`for lane in commandcode deepseek`) and :294
  (#10 `case` skips unknown lanes). Plan step 3 now adds `kimi` to all four, as an existing-suite
  edit that keeps the pin truthful (AGENTS.md *No new tests*), not a new suite. The red control is
  re-sequenced: route + suite amendment first, dispatcher arm last, so the run must fail on
  `#3 dispatcher did NOT route 'kimi'` and then pass.
- The three `[Pass]` findings need no change.

Round 2: please re-check only the revised Plan step 3 and the Verification red control, then set a verdict.

handing off to Reviewer — take your turn.

### Reviewer · Round 2

swept file: yes

VERDICT: PASS

Basis: The revised step explicitly covers every hardcoded consumer that the derived lane set would expose, and the re-sequenced control reaches the dispatcher assertion before binary preflight. I found no pre-existing defect in the revised plan section.

- [Pass] The existing-suite amendment is complete for the route addition: it adds `kimi` to the derived-lane-to-environment mapping and each curated lane subset that otherwise omits it (`PROJECT/1-INBOX/GH-1215-KIMI-RELAY-WORKER.md:91-95`). Those are exactly the consumers visible in the current suite: `lane_env_var()` (`test/gh346-gateway-allowlists.sh:85-101`), the #2/#4 focused loop (`test/gh346-gateway-allowlists.sh:180-193`), the #8/#9 loop (`test/gh346-gateway-allowlists.sh:277-289`), and #10's explicit admissible-lane case (`test/gh346-gateway-allowlists.sh:291-300`). #5 already iterates the derived `LANES` list (`test/gh346-gateway-allowlists.sh:251-262`), so it needs no separate suite edit.

- [Pass] The red control is real and correctly ordered: after adding the `route_agent()` arm, `LANES` includes `kimi` because the suite AST-walks that function (`test/gh346-gateway-allowlists.sh:49-72`), and #3 executes before the driver/preflight checks (`test/gh346-gateway-allowlists.sh:75-103`). With the planned `KIMI_AGENT` mapping but without a `marathon-agent.sh` Kimi case, the dispatcher reaches its unknown-agent branch (`relay-automation/marathon-agent.sh:76-107`), yielding the claimed `#3 dispatcher did NOT route 'kimi'`; adding the arm then dispatches the generated Kimi stub. The plan states that same prerequisite and expected failure/pass sequence (`PROJECT/1-INBOX/GH-1215-KIMI-RELAY-WORKER.md:127-129`).

- [Pass] `gh441` remains a genuine lockstep check after the planned reset/registry/literal additions: it derives driver exports from `marathon_drive.py` and rejects unclassified names (`test/gh441-gate-env-contract.sh:26-42`), then compares `GATE_SCRUBBED_ENV` exactly to the registry (`test/gh441-gate-env-contract.sh:88-103`). Thus no unlisted Kimi-specific curated consumer remains in the cited verification scope.

Probe (exit 0): `python3 -B - <<'PY' ...` parsed `route_agent()` and the current `gh346` suite; decisive output: `route lanes=claude,codex,agy,aider,pi,smallcode,commandcode,deepseek`, `derived loops: #3=LANES #5=LANES #10=LANES`, and `curated subsets: #2/#4=commandcode,deepseek #8/#9=commandcode,deepseek`. This confirms the four amended sites are the only present derived-lane exceptions; no executable suite was run.

relay closed (Approved), no further turn needed.


### Attestation · relay-drive — 2026-10-25T05:11:27Z
task: RELAY-gh1215-plan-qa
reviewer: codex
status: Approved
reviewed-head: b6ab4366d9840f522837558f385c60eece955279
added-range: 13053+2638
added-sha256: 384a318f3fa47c16604118ea13e7d0a03324bc58be4ae555bb28286e18c59976
<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
