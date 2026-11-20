# RELAY · GH-1567 final QA: tick harness-config hint
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-11-20.
-->

NEXT: Producer
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
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
   Reviewer headings may be `### Reviewer · Round N`, `### Round N · Reviewer · <agent>`, `### Reviewer (<agent>)` (optionally followed by `— rN`), or `### Reviewer — Round N` (optionally followed by `(<agent>)`); follow the heading with a non-empty review body.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Manual relay: commit only the relay file** (`relay(gh-1567-final-qa-tick-harness-config-hint): <role> r<N>`); no push.
   **Driven turn (relay-drive, marathon): do not run git — the harness commits the turn.** **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. (The window wording is
   for a manual relay; in a driven turn, name the next role.) The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: The committed GH-1567 implementation and evidence. Inspect the diff from base `5935235be15f` to HEAD.
- Reviewer: codex   ·   Producer: codex-author
- Started: 2026-11-20
- Definition of Done: Check both requested CLI messages and preservation of the scanner trust boundary. Issue https://github.com/HiQS-Labs/XYZ-forge/issues/1567.

Operational envelope is a local developer CLI and advisory diagnostics. Evaluate commensurate complexity.

1. Read `PROJECT/2-WORKING/GH-1567-TICK-HARNESS-HINT.md` and sweep the changed scanner, locator and skill doc. Does the committed implementation satisfy the plan, including config-present, config-invalid, and no canonical live clone paths? Does the guidance describe what the existing discovery channels can do?
2. Verify the audited tree still cannot provide the tick executable, and no new config writer, suite or registry entry was introduced.
3. Read `TESTS-RESULTS/2026-11-20+GH-1567/probe.log` and its probe. Which observed baseline outputs reject the unfixed behavior? Do the fixed smoke and adjacent probes prove the saved config is sufficient and preserve advisory exit status?
4. Check the stored 50/40/50/85 rating against the plan and confirm the accepted start is present. Plan QA is recorded in `relay-system/2026-11-20/gh1567-plan-qa.md`.
5. The author observed green full Darwin `ci-local.sh` on `d99763ea99c27c6c0110819001da1f7e75695d09` in a disposable full clone (407 suite verdicts recorded, clone identity invariant passed). Treat this as author evidence for that revision. Do not run mutation-heavy suites in the relay workspace.

Provide actionable findings with file/line evidence and the relay verdict. Keep edits to this relay thread.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). In a manual relay, end each turn by committing just this file; no push. In a driven turn the harness commits.

## Log

### Reviewer · Round 1

**Ship with conditions — changes requested.**

swept file: yes

Swept the scanner, locator and skill document, including their pre-existing code. No additional pre-existing defect established in that sweep. Graph lookup was denied by the never-approval policy; used direct source reads. No git commands, executable fixtures or suites were run. The requested base-to-HEAD diff remains unverified because this turn expressly prohibits git; Producer should retain that diff/name-status for the next review.

- [Pass] The scanner refusal names both remedies and retains `verified: False` (`skills/2-daily/merge-cleanup/scripts/scan_clones.py:321-327`). Its executable resolver still has no audited-repo argument and uses installation/configuration/PATH (`:254-285`); coordination-root pinning and malformed-claims refusal remain (`:328-350`). No trust relaxation found in the reviewed source.
- [Pass] Locator branches cover valid config, missing/invalid config and unavailable canonical live clone; save suggestions still require `_canonical_clone` and preserve the shell-quoted save-line prefix (`skills/1-hourly/relay-xyz/find-harness.sh:421-447`). The branch ends with `true   # --check is advisory` (`:537`). No config writer was added to these reviewed runtime paths; printing a save command leaves execution to the operator.
- [Should] Correct the unconditional dependency claim in `find-harness.sh:434` (“merge-cleanup cannot find tick without it”) and `SKILL.md:133-134` (“without the config it refuses”). Config is one remedy, not a prerequisite. Say the scanner cannot use the audited tree's vendored tick and needs a trusted installation, config or explicit override; qualify the missing-binary scenario. Keep existing discovery behavior.
  Observed input: absent config with `XYZ_HARNESS` set to this checkout; AST-only execution of the actual `_tick_binary` body returned its tick path. Resolver source also explicitly accepts MERGE_CLEANUP_TICK_BIN, own ancestry and PATH (`scan_clones.py:256-285`).
  Affected scope: the new advisory warning and setup prose only.
  Falsifier: with config absent and a valid explicit XYZ_HARNESS, discovery must continue to resolve its bin/tick; with all trusted channels absent it must remain None.
  Probe command: `export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"; python3` with AST extraction of only `_tick_binary`, synthetic `__file__='/__outside__/scan_clones.py'`, MERGE_CLEANUP_TICK_BIN unset, XDG_CONFIG_HOME set to scratch/absent-config, XYZ_HARNESS set to the absolute current checkout; printed config existence and equality of the result to checkout/bin/tick. Exit 0; decisive output: `config exists: False`, `XYZ_HARNESS resolves tick: True`. No tick executable invoked.
- [Should] Retain accurate acceptance evidence and required provenance. `TESTS-RESULTS/2026-11-20+GH-1567/` contains only probe.sh and probe.log; add its required `provenance.jsonl` with exact revisions, commands, outcomes and artifact hashes. In `probe.sh:40,61`, `exit=$?` measures the grep pipeline's final command, not find-harness, so the log's exit=0 does not witness advisory status. Capture the locator's status before filtering (or immediately capture PIPESTATUS[0]) and retain the actual result from a disposable clone. The saved-bytes check at :47 only prints values; compare canonical expected bytes explicitly and make failure visible. Do not introduce a new suite.
  Observed input: the checked-in probe uses `bash ... --check 2>&1 | grep -v ...; echo "  exit=$?"`; retained log reports exit=0. Read-only existence probe returned `provenance exists: False` (same Python command above, exit 0).
  Affected scope: GH-1567's retained manual evidence only.
  Falsifier: a controlled locator exit 7 with printable output must be recorded as 7, while the real advisory cases record 0; unequal saved bytes must be rejected. A nonempty provenance file must identify and hash the retained outputs.
- [Pass] Retained baseline output rejects unfixed messages: `probe.log:3-10` shows remedy False before and True after, both unverified; baseline vendored checklist lacks the new config line (`:13-21`). Fixed config saving yields exact scanner tick equality and real claims `verified: True` (`:34-48`); valid/invalid/no-live-harness checklist paths are visible (`:37-69`). These support functionality, subject to the status/provenance correction above; they are author observations, not reruns here.
- [Pass] Stored rating matches 50/40/50/85 (`releases.sql:1043`, plan “PRS rating rationale”); accepted start is present with `"accepted_start": true` (`releases.sql:5932`). Plan QA is Approved with its revision attestation (`relay-system/2026-11-20/gh1567-plan-qa.md`, “Attestation · relay-drive”).
- [Unverified — needs clone run] Full Darwin gate on d99763ea99c27c6c0110819001da1f7e75695d09 is author evidence as specified in Setup, not independently rerun. No later gate assumed. Absence of new suite/registry entries across the complete commit range awaits the retained diff/name-status noted above.

**VERDICT: FAIL**

**Basis:** The implementation keeps the intended trust boundary and adds the requested hints. Correct the materially misleading config prerequisite wording and repair the narrow evidence gaps before approval.

Handing off to Producer (codex-author) — disposition these findings, correct guidance and retain accurate acceptance/provenance evidence.

### Producer · Round 1

- Accepted the warning and guide finding. The warning conditions the remedy on the scanner failure, and the guide names the canonical clone path and explicit override.
- Accepted the evidence finding. The probe records the locator status before filtering, rejects a failed locator or byte mismatch, and keeps the rerun log and command hashes. The retained log has red control and main and adjacent smoke outcomes.
- Updated the task branch from development using the repository's RELEASES resolver. The check reported a matching DB/dump and receipt chain, with 0 failures.
- Author-observed name-status against current development follows. The prior full gate belongs to the earlier revision. The new publish head will be gated before the push.

```text
M	CHANGELOG.md
M	LEADERBOARD.md
A	PROJECT/2-WORKING/GH-1567-TICK-HARNESS-HINT.md
A	TESTS-RESULTS/2026-11-20+GH-1567/probe.log
A	TESTS-RESULTS/2026-11-20+GH-1567/probe.sh
A	relay-system/2026-11-20/gh1567-final-qa.md
A	relay-system/2026-11-20/gh1567-plan-qa.md
M	releases.db
M	releases.sql
M	skills/1-hourly/relay-xyz/SKILL.md
M	skills/1-hourly/relay-xyz/find-harness.sh
M	skills/2-daily/merge-cleanup/scripts/scan_clones.py
A	TESTS-RESULTS/2026-11-20+GH-1567/provenance.jsonl
```

Handing off to Reviewer (codex) for Round 2. Check both Round 1 findings, the name-status scope and retained acceptance evidence.

### Reviewer · Round 2

**Approved — both Round 1 requests are addressed.**

swept file: yes

Swept scanner, locator and skill document, including pre-existing code. No git commands, suites or executable fixtures run. Scope comparison relies on the Producer's retained name-status above; the requested base-to-HEAD diff was not independently obtained because this turn prohibits git. This is implementation QA approval, not exact-head publication-gate attestation.

- [Pass] Corrected conditional guidance: `find-harness.sh:434` now says “configure it if merge-cleanup reports tick binary not found”; `skills/1-hourly/relay-xyz/SKILL.md:133-142` supplies config or XYZ_HARNESS without making config mandatory. Round 1 wording finding closed.
- [Pass] `scan_clones.py:254-285` still resolves override, explicit harness, own installation, config and PATH without taking the audited checkout as an executable source. The refusal retains `verified: False` at `:321-327`, coordination pinning remains at `:328-331`, and malformed claims remain unverified at `:339-350`. Locator config checks and canonical save-target validation remain at `find-harness.sh:421-447`, with advisory `true` at `:537`. No new writer in these runtime paths; the Producer's name-status lists no new suite or registry.
- [Pass] Evidence correction closes Round 1's retention finding: `TESTS-RESULTS/2026-11-20+GH-1567/probe.sh:42-46` captures locator status before filtering and returns it; `:54-57` rejects empty hints and mismatching saved bytes. `provenance.jsonl:1` identifies baseline 5c3388dd720ef19acf71b1c230407f6ea81d6285 and tested revision 6edbe5d2f4cc21af684d3365eb3d963f285f4312, command, platform and hashes. Read-only probe: `python3` using `json.loads`, `hashlib.sha256((p/name).read_bytes()).hexdigest() == want` for each recorded hash; exit 0, decisive output: `probe.sh hash matches: True`, `probe.log hash matches: True`.
- [Pass] Retained `probe.log` section A observes baseline remedy False versus fixed True while both remain unverified. Sections B–D observe missing/valid/invalid config and no-live-clone guidance, all locator exits 0; section C records exact saved-byte match, resolved tick equality True and real empty claims `verified: True`. These are author observations, not fixtures rerun in this worktree. No extra machinery needed for these message changes.
- [Pass] Plan rating remains **50/40/50/85** in the plan's “PRS rating rationale”; accepted start is retained in `releases.sql:5938` (`"accepted_start": true`). Previously approved plan QA remains the plan review record.
- [Unverified — needs clone run] Full Darwin gate on d99763ea99c27c6c0110819001da1f7e75695d09 remains author evidence only for that earlier revision. Exact publication-head gate remains outstanding as the Producer states; approval assumes no future gate result.

**VERDICT: PASS**

**Basis:** Requested messages and retained baseline/fixed observations satisfy the bounded plan, preserve scanner executable discovery and fail-closed behavior, and resolve the two prior requests. Publication still needs its separately required exact-revision gate.

Relay closed (Approved), no further turn needed.


### Attestation · relay-drive — 2026-11-20T18:32:32Z
task: RELAY-gh1567-final-qa
reviewer: codex
status: Approved
reviewed-head: 2680fb175ec3749ca231095e06623d90db55a25a
added-range: 14282+3197
added-sha256: 45df9ac09db8a947085cc601272d594daa98b0860aeeb127b63b0037d30c317a
gate-run: undeclared
<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
