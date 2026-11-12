# GH1419 independent plan review
STATUS: Approved
NEXT: orchestrator

Artifact under review: `PROJECT/1-INBOX/GH-1419-REVIEWER-ROUTING.md`

Review the committed plan first WITHOUT supplementary source/context. Append 2–5 sentences each under What this proposes, How the existing system works per this document, and What it's not (ground exclusions, label uncertainty). Then read its referenced source and requirements for separately labeled source-backed technical validation. No author history provided.

User goal: reviewer-agnostic Jog, especially explicitly authorized Claude-only builder/reviewer with distinct actor IDs, not self-review. Existing routing/probe owner must be reused. Scope is a local CLI harness, not enterprise policy infrastructure. Do not impose new registry/runner/guard/suites. Grade commensurate complexity. Questions:
1. Does the plan trace all actual routing/admission/dispatch boundaries, including profile_resolve source parsing and manifest parity?
2. Is removing provider-specific quality eligibility in favor of explicit supported routes coherent with user goal, while keeping unavailable routes/identical actor refusal/attestation intact?
3. What is the smallest concrete shared-helper design using current code? Identify omissions or broadening before implementation.
4. Are Claude-only exact-role routing, timeout/retry, baseline red/adjacent smoke and rating/rollback sufficient?

Read whole affected contexts, not just proposed diff. Do not run test/*.sh or validate in this task clone. Read-only/manual checks only outside repo. Append findings with cited file:line, observed input, affected scope and falsifier for behavior changes; preserve original text. Append `### Round 1 · Reviewer · codex`, literal `swept file: yes/no`, and **Verdict:** Approved or Changes requested. Set STATUS: Approved only if approved, NEXT: orchestrator. Do not edit any other file, run git or claim implementation QA. This turn is plan QA only.

### Round 1 · Reviewer · codex

#### What this proposes

The plan would admit explicitly selected reviewers through existing supported routes instead of provider-specific quality allowlists. It would also preserve distinct builder and reviewer actor IDs when both use Claude or Codex, while keeping attestation and containment intact.

#### How the existing system works per this document

The document describes three inconsistent admission boundaries: Jog, Marathon, and manifest validation. It says Marathon owns route discovery and binary probes, profile discovery parses that owner's source, and the dispatcher currently preserves multiple Agy actors but overwrites other same-provider pairs.

#### What it's not

This is local CLI routing work, without automatic fallback, new quality grades, or a new registry or runner. The document does not claim implementation verification or overnight qualification; exact helper placement and timeout behavior remain uncertain from the document alone.

#### Source-backed technical validation

**Block — two bounded plan clarifications requested before implementation.** The proposed removal of provider-quality eligibility is coherent with the explicitly authorized user goal: dispatch availability does not certify review quality, and exact actor inequality plus reviewer attestation still applies. The rating rationale and scoped-PR rollback are proportionate; no new policy machinery is warranted.

1. **[P2] Include the turn-shim identity boundary in step 3.** At `PROJECT/1-INBOX/GH-1419-REVIEWER-ROUTING.md:39`, dispatcher routing is named, but its consumer contract is omitted. `utils/py/marathon_drive.py:2108` overwrites Claude's slot; `relay-automation/marathon-agent.sh:79` compares the scalar slot; importantly, `utils/py/claude-turn.py:71` and `utils/py/codex-turn.py:38` independently compare the slot to the exact actor and return successful deferral on mismatch. Input `claude-builder,claude-reviewer` therefore cannot simply be forwarded as CLAUDE_AGENT after adding dispatcher membership. Scope: same-provider build/review turns, including resumed turns. Cheapest correction: explicitly plan exact-membership dispatch followed by a child-local scalar `CLAUDE_AGENT`/`CODEX_AGENT` equal to RELAY_AGENT (or explicitly update the authoritative shim membership checks); preserve the original MARATHON role IDs and RELAY_PEER. Falsifier: a controlled clone dispatch must reach each actual shim past its identity check for both actors, while an unlisted actor refuses; merely selecting a shim or getting exit 0 is insufficient.

   Manual probe, exit 0: `python3` parsed `utils/py/marathon_drive.py` with `ast.parse`, selected its `FunctionDef` named `route_agent`, compiled only that function with `os` and a raising `die`, initialized CLAUDE_AGENT empty, then called `route_agent('claude-builder'); route_agent('claude-reviewer')`. Decisive output: `baseline CLAUDE_AGENT=claude-reviewer`. The same probe evaluated each actor's `actor != "claude-builder,claude-reviewer"`, matching the cited shim condition: `defer=True` for both. This is an isolated source-level probe, not an executed shim or implementation QA.

2. **[P2] Name a discriminating timeout/retry check rather than only preserving caps in prose.** Steps 4–5 (`PROJECT/1-INBOX/GH-1419-REVIEWER-ROUTING.md:40–41`) cover normal and resumed/review-only dispatch, but no explicit timeout input or expected stop outcome; acceptance at line 47 claims retry caps remain intact. `utils/py/marathon_drive.py:3614–3687` recovers exit 7 by inspecting the exact builder actor, then re-enters `_run_relay_drive`; this is an adjacent consumer of the actor routing being changed. Add one controlled clone/manual scenario: Claude builder times out after handing off to the distinct Claude reviewer, recovery dispatches that reviewer, and a second timeout stops with the existing escalation instead of looping or selecting the builder. Also pin the builder-still-owned refusal and existing retry cap via existing coverage where available. Record commands and nonempty evidence with committed provenance under the normal TESTS-RESULTS task location. Falsifier: wrong actor, silent deferral, unbounded recovery, or changed cap fails the check. **[Unverified — needs clone run]**; no fixtures or suites were executed here.

#### Smallest shared-helper design and scope

Keep `route_agent` as the current route owner, expose it at module scope with an optional destination environment mapping so it can validate without mutating process routing, and retain the source shape consumed by `profile_resolve.py:84–94,151–181` (or minimally adapt that reader and witness a nonempty, unchanged lane set). Use that callable plus the existing `_probe_agent_bin` owner for Jog and Marathon; adapt existing error behavior at the Jog boundary instead of creating a registry. For manifest validation, call an import-only mode on the existing Python entry point using an argv array; share supported-route recognition, but keep executable availability at execution admission so offline manifest parsing does not acquire an accidental machine-installation requirement. Document this distinction explicitly.

Preflight's suggested codex/agy roles are not authority (`utils/py/swarm_preflight.py:1094–1145`); Jog replaces them centrally in `_marathon_argv_from_invocation` (`utils/py/jog_run.py:485–500`). Run, retry-gate and retry-build use that seam; retry verbs also invoke the admission validator (`jog_run.py:792,1011`). Preserve these consumers rather than changing packet defaults. If all supported providers become eligible reviewers, acknowledge that same-provider pairs outside Claude/Codex must either follow the same membership/scalar dispatch pattern or be explicitly scoped; do not advertise acceptance that still overwrites their actors.

Packaging lesson checked: `skills/1-hourly/relay-automation/make-pkg.sh:12–30` does not package marathon-agent.sh or Python turn implementations. No tarball regeneration is required solely for the currently proposed dispatcher edit; it becomes necessary if packaged Bash shims are changed. No frozen Bash twin changes are needed.

swept file: yes

**Verdict:** Changes requested

Plan QA only. The plan's complete text and the affected admission, discovery, dispatcher, shim identity, packet substitution, role threading, and timeout-recovery contexts were inspected. No validate.sh, test/*.sh, pytest, executable fixture, git command, or live provider call was run. The two requested edits clarify existing boundaries and verification; they do not require new suites, runners, guards, or a larger policy layer.

### Round 2 · Builder · orchestrator

Both P2 findings accepted and incorporated into canonical plan steps 2, 3 and 5. Re-review the revised plan and affected source boundaries; no production changes made. Preserve Round 1. Append a Round 2 Reviewer block with substantive plain paragraphs directly under its heading (no nested headings), swept file: yes/no and explicit verdict. Set STATUS Approved only if approved; NEXT orchestrator. Same scope, no new machinery, no tests in task clone.


### Round 2 · Reviewer · codex

The revised document proposes one supported-route owner for explicit reviewer admission across Jog, Marathon and manifest parsing, plus exact actor dispatch for same-provider pairs. Per the document, current admission lists disagree and scalar provider slots overwrite actors; the revision preserves independent role IDs rather than equating independence with different providers. It excludes new registries, runners, quality certification and default-role changes. This remains plan approval only, with implementation behavior unverified.

Source-backed validation: both Round 1 P2 requests are resolved in the plan. Step 3 now explicitly requires exact membership followed by a child-local scalar equal to RELAY_AGENT, addressing the dispatcher at relay-automation/marathon-agent.sh:49–105 and scalar identity consumers at utils/py/claude-turn.py:71 and utils/py/codex-turn.py:38. Its requirement to reach actual shim identity checks, reject unlisted actors and preserve MARATHON roles/RELAY_PEER makes silent exit-0 deferral a failure. Applying this to every supported provider avoids advertising same-provider support that still overwrites actors elsewhere.

Step 5 names the discriminating timeout input and stop outcomes requested in Round 1. This matches the existing one-recovery call at utils/py/marathon_drive.py:3614–3687: builder-owned state refuses recovery; a post-handoff retry returning 7 propagates timeout-during-review-recovery. Wrong actor, silent deferral, repeated recovery or changed caps explicitly fail the planned check. These outcomes remain [Unverified — needs clone run]; no runtime success is inferred from source inspection.

The smallest shared-helper design remains the proposed module-scope route_agent with an optional destination mapping, plus the existing _probe_agent_bin at utils/py/marathon_drive.py:847. The source reader at utils/py/profile_resolve.py:84–94,151–181 specifically matches os.environ assignment syntax, so changing to a destination mapping must retain that discoverable shape or minimally adapt the reader; the revised requirement for a nonempty unchanged lane set is the right falsifier. Manifest recognition at bin/marathon-yaml:88–97 should share this owner without binary probes, while Jog execution admission at utils/py/jog_run.py:206–233 probes both selected roles before lease. This is recognition/availability separation within the existing owner, not a second registry.

Exact role replacement remains centralized at utils/py/jog_run.py:485–500, with retry admission calls at :792 and :1011, and preflight packet suggestions at utils/py/swarm_preflight.py:1094–1145. The plan now explicitly covers these boundaries, manifest parity, baseline refusal, adjacent Codex/Agy behavior, containment and attestation. Provider-neutral explicit admission is coherent with the authorized goal without asserting reviewer quality. The Costly rating, scoped-PR rollback and bounded disposable-clone verification are proportionate; no further blocking clarification or extra machinery is warranted.

swept file: yes

**Verdict:** Approved

Plan QA only. Re-read the revised complete plan and the affected source contexts; preserved Round 1. No git command, validate.sh, test/*.sh, pytest, executable fixture or live provider call was run. Implementation, controlled dispatch, timeout evidence and final committed-source QA remain required before implementation approval.

### Attestation · relay-drive — 2026-11-11T19:50:40Z
task: GH1419-PLAN-QA
reviewer: codex
status: Approved
reviewed-head: 07e36a899e07b27295de70932869e017e63ec046
added-range: 9118+3476
added-sha256: 9a5b0efe2b716a55333bbb982d741ef7b3b50c91cd1041555a89d3870fe2cad0
