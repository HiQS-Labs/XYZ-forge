# GH1428 independent plan review
STATUS: Open
NEXT: orchestrator

Artifact under review: `PROJECT/2-WORKING/GH-1428-REVIEWER-UNVERIFIED-APPROVAL.md` (committed plan; base `0f21b761a`).

**Paraphrase first (GH-1414).** Read ONLY the plan document first, without the issue or source. Append 2–5 sentences each under `#### What this proposes`, `#### How the existing system works, per this document`, and a short `#### What it's not` (ground exclusions in the plan's own sections; label inference; distinguish excluded vs deferred vs unresolved). No author history is provided.

**Then source-backed validation** under `#### Source-backed technical validation`. Requirements: https://github.com/HiQS-Labs/XYZ-forge/issues/1428 (acceptance: reviewer steps require running the phase gate or naming why not, attestation records it; Approved after builder-declared unverified assertions refused or downgraded without reviewer-run evidence; documented opt-in Codex builder localhost network OR preflight warning; existing suites pass, evidence under TESTS-RESULTS, GH-831 no new tests). Source paths: `utils/py/marathon_drive.py` (1519-1539, 3080-3160, 3463-3520), `utils/py/relay_drive.py` (698-790, 1095-1115), `utils/py/relay_attest.py` (262-385), `relay-automation/relay-turn-lib.sh` (1040-1070), `test/gh681-reviewer-probe-rules.sh`, `test/gh505-relay-attest.sh`, `utils/py/swarm_preflight.py:1420-1430`, `utils/py/codex-turn.py:14-18`, `utils/py/rtl.py:876-884`, `utils/py/jog_run.py:519-528`, `relay-automation/README.md:430-445`, `AGENTS.md` (No new tests; worktree rules). Ground-truth incident: the GH-955 RELAY.md excerpts quoted in the plan's Observed table.

Operational envelope: local CLI harness for one operator; grade commensurate complexity; no enterprise threat models; no new suites/runners/guards (GH-831). Parallel work: #1427 edits marathon_drive.py/claude-turn.py; the plan keeps its marathon_drive.py diff minimal.

Questions:
1. Is the root-cause correction right — the reviewer followed the GH-681 role note and preflight brief rather than ignoring an obligation? Any instruction layer missed?
2. Is the "reviewer-runnable gate" predicate (explicit `--pre-advance-cmd`, not validate.sh/ci-local.sh/run-tests.sh/test/*.sh) a sound and minimal boundary consistent with AGENTS.md worktree rules and GH-681, or should the exception be shaped differently?
3. Is `judge_terminal()` refusal gated on `MARATHON_REVIEWER_GATE_CMD` + latest Builder block matching `\bunverified\b` + reviewer `gate run:` != yes correct and non-regressing for generic relays and full-suite marathon gates? Is refusal (escalate) vs downgrade the right choice, given alternatives rejected in the plan?
4. Is the optional `gate_run` trailer/record field compatible with legacy attestation records and `_load()`?
5. Is documenting the existing `CODEX_FLAGS` with `-c sandbox_workspace_write.network_access=true` sufficient for acceptance 3, and is one PR (vs split) justified?
6. Are verification (existing suites + manual red control from the GH-955 pair + dry-run render + Codex network smoke), rating rationale, and rollback sufficient? Anything missing or over-built?

Rules: plan QA only. Read whole affected contexts. Do NOT run validate.sh, test/*.sh, pytest or executable fixtures in this clone; read-only probes with output under `$TMPDIR` only. Every behaviour-change [Blocker]/[Should] carries `Observed input:`, `Affected scope:`, `Falsifier:` and file:line citations. Append `### Round 1 · Reviewer · codex` with your sections, a literal `swept file: yes` or `swept file: no` line, and `**Verdict:** Approved` or `**Verdict:** Changes requested`. Set `STATUS: Approved` only if approved; set `NEXT: orchestrator`. Edit ONLY this file; do not run git.


### Round 1 · Reviewer · codex

#### What this proposes
The plan permits explicitly selected focused phase gates during marathon reviewer turns and adds a gate-run declaration to review attestations. It refuses approval when the latest builder block declares unverified work and the reviewer has not declared a gate run. It also documents the existing Codex network opt-in.

#### How the existing system works, per this document
The reviewer role note prohibits pytest and executable fixtures, while the marathon reviewer template asks for no gate evidence. The pre-advance gate runs later, and relay-drive already has a refusal seam before issuing attestations. Optional attestation fields and child environment signals provide the proposed extension points.

#### What it's not
The plan explicitly excludes a new harness gate stage, full-suite execution inside reviewer worktrees, new suites, and a Bash-twin port. Spend ceilings and error surfacing are assigned to #1427; broader gate selection changes are excluded. Inference: this is declaration-based evidence, not independent verification that the declared command actually ran.

#### Source-backed technical validation

[Pass] The root-cause correction is supported. `rtl.py:866-869` delegates prompt construction to the Bash library, whose reviewer note at `relay-turn-lib.sh:1067` expressly prohibits pytest. `marathon_drive.py:3134-3160` supplies no gate obligation. The brief prohibition is builder-scoped (`swarm_preflight.py:1871-1873`), so describe it as contextual ambiguity rather than a second binding reviewer prohibition. The additional GH-54 branch at `swarm_preflight.py:1418-1424` also deserves preservation when shaping the exception.

[Should] Require a successful gate result, rather than merely a declared execution.
Observed input: `gate run: yes — exit 1` with the latest Builder block containing `unverified:` and `MARATHON_REVIEWER_GATE_CMD` set. The parser and refusal planned at `PROJECT/2-WORKING/GH-1428-REVIEWER-UNVERIFIED-APPROVAL.md:176-187` accept it, contradicting the green-run requirement at lines 167-169.
Affected scope: focused marathon approvals after builder-declared unverified work; failures and timeouts are accepted as sufficient evidence by the proposed predicate.
Falsifier: a manual check showing exit 1, exit 124, and missing exit results refused while an explicit exit 0 is accepted. Extend the existing declaration parser/record, without adding a runner or suite.
Probe: `python3 -B` with `re.findall(r'^\s*[-*]?\s*gate run:\s*(yes|no)\b', s, re.I|re.M)[-1]` and the proposed `v != 'yes'` predicate; exit 0. Decisive output: `gate run: yes — exit 0 -> gate_run=yes; refusal(gate_run != yes)=False`; exit 1 and exit 124 lines produced the identical `False`. This measures the proposed predicate, not implemented behavior.

[Should] Make reviewer execution an explicitly safe focused-command exception; a filename denylist alone does not establish that property.
Observed input: explicit `--pre-advance-cmd 'python3 -m pytest'` satisfies the predicate at plan lines 156-160 despite selecting an entire project suite. More directly, `swarm_preflight.py:1418-1424` already recognizes tests that create git fixtures and forbids their execution; command spelling alone says nothing about these effects. The repo's worktree rail protects shared Git state, which containment cannot restore afterward.
Affected scope: explicit marathon commands, including full pytest discovery and wrappers around fixture-heavy gates. This is a local operational safety issue, not an adversarial-shell threat model.
Falsifier: render/manual controls demonstrating that an unscoped suite and known fixture-mutating command remain harness-only, while a specifically authorized focused, worktree-safe command gets the exception. State the positive safety contract and retain `gate run: no — <why>` when safety is unknown; do not introduce a new scanner/guard subsystem. A blanket exception for any explicit non-denylisted command is insufficient.

[Should] Specify that target-root fallback is for tooling only and cannot change the artifact revision being tested.
Observed input: plan line 165 tells the reviewer to resolve missing relative paths against the target root. A missing `tests/test_x.py` can then select a target-root test or command that imports target-root source rather than the isolated revision. `relay_drive.py:319-320` defaults to isolated turns, and the attestation records the pre-turn `reviewed_head` (`relay_drive.py:757-770`); testing another checkout would not substantiate that record.
Affected scope: foreign targets and worktrees missing dependencies or test paths, especially shared target roots that can move during a turn.
Falsifier: a manual check with distinguishable target/worktree source that proves fallback tooling still imports/tests the reviewed worktree; missing test/source paths must instead produce a truthful no-run reason. Clarify this in the plan rather than allowing arbitrary path fallback.

[Pass] Reusing `judge_terminal()` refusal is proportionate: current refusals already escalate through `relay_drive.py:1105-1110`. Escalation is consistent with the existing terminal-token lifecycle; a downgrade would require extra coordination repair. Generic/full-suite lanes remain outside this refusal when the signal is absent. Explicitly clear the child signal when there is no runnable gate, since `env2 = os.environ.copy()` at `marathon_drive.py:3489` otherwise preserves an ambient value.

[Pass] An optional `gate_run` field can preserve legacy records: `relay_attest.py:267-280` constructs trailers conditionally, and `_load()` at lines 319-385 validates fields and recomputes that trailer. Validate the allowed values, including `undeclared`, and bind any success/exit field consistently. This is a design assessment; compatibility remains [Unverified — needs clone run].

[Pass] The existing Codex flag route is visible at `codex-turn.py:14-18`, environment inheritance at `jog_run.py:519-526`, and the documentation location at `relay-automation/README.md:435-443`. Documenting an opt-in with its outbound-network scope meets the supplied acceptance wording; CLI behavior remains [Unverified — needs clone run]. Bind the network smoke server to `127.0.0.1` explicitly: the proposed bare `http.server` defaults to all interfaces and conflicts with AGENTS.md's permission requirement for machine network exposure.

[Unverified — no citation] One PR is reasonable because the network portion is documentation. The rating rationale distinguishes observed impact from limited historical coverage. Revert-based rollback is suitable for optional records, though the shared reviewer execution-policy change has a wider blast radius than an ordinary text edit. No new suite or runner is needed. Existing focused suites, dry-run renders, manual controls, and final disposable-clone verification are the appropriate evidence shape; include the failed-run and safety/path controls above. Do not count this review as implementation verification. The GH-955 incident was assessed from the supplied excerpts; the external repository transcript was not independently retrieved.

swept file: yes

Read the whole plan and affected source contexts listed above; no source artifacts changed. No validate.sh, test/*.sh, pytest, or executable fixtures were run.

**Verdict:** Changes requested

Handing off to orchestrator — orchestrator, take your turn.

### Round 2 · Builder · orchestrator

Dispositions for Round 1 (plan revised in `PROJECT/2-WORKING/GH-1428-REVIEWER-UNVERIFIED-APPROVAL.md`; no production code yet):
- [Should] exit-0 evidence — **Implemented** (step 4/5): `declared_gate_run` returns `yes` only for `gate run: yes … exit 0`; non-zero/missing exit → `failed`; refusal on anything but `yes`; manual controls for exit 1, exit 124, no exit added.
- [Should] positive safe-command contract — **Modified** (step 1): explicit cmd AND focused (names an existing test file under the target root) AND no validate.sh/ci-local.sh/run-tests.sh/test/*.sh/` -- ` passthrough AND brief lacks preflight's GH-54 fixture rule. One predicate, no scanner. Reviewer keeps `gate run: no — <why>` when unsure. Controls: `python3 -m pytest` and a GH-54-fixture brief render the do-not-run step.
- [Should] target-root fallback — **Implemented** (step 2): cwd = worktree; only tooling (e.g. untracked `.venv`) may come from the target root; missing test/source path → `gate run: no`.
- [Pass] notes — **Implemented**: env signal popped when empty (step 3); `_load()` validates the four allowed values; root-cause layer 2 reworded as builder-scoped contextual ambiguity; network smoke server bound to 127.0.0.1 (already done in the pre-run smoke).

Re-review the revised plan. Preserve Round 1. Append `### Round 2 · Reviewer · codex` with substantive plain paragraphs directly under the heading (NO nested `####` headings — the driver's review-block counter treats a body that opens with a heading as empty), a literal `swept file: yes/no` line, and an explicit `**Verdict:**`. Set STATUS: Approved only if approved; NEXT: orchestrator. Same rules as Round 1.
