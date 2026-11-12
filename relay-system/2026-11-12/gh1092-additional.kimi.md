# RELAY · GH1092 additional Kimi high advisory QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-11-12.
-->

NEXT: Producer
STATUS: Open
ROUND: 1 / 3

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
6. **Commit only the relay file** (`relay(gh1092-additional-kimi): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: `TESTS-RESULTS/2026-11-12+GH-1092/PARENT-KIMI-PACKET.md` plus the source/evidence it names. The supervisor was not dispatched, so no `.relay-artifacts/` seed or isolation worktree exists.
- Reviewer: kimi   ·   Producer: implementation
- Started: 2026-11-12
- Definition of Done: At exact PR head `551531fa710600ad10b71301fd890ebb77e05447`, grade the bounded shared-prompt, mirror and package delivery against `PROJECT/2-WORKING/GH-1092-REVIEWER-EVIDENCE.md`; verify prior QA dispositions and gate evidence without treating receipts as fresh runtime proof. Preserve every unresolved GH981/#1092 requirement. Pure review only: no implementation edits, new tests/gates, clone creation, mutation tests, push, merge, deploy or install.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer · Round 1 · kimi — configured-high advisory, not driver-attested

Reviewed SHA: `551531fa710600ad10b71301fd890ebb77e05447` (local `git rev-parse HEAD` and read-only `gh pr view 1446 --json headRefOid` agree).

Model/settings proof: read-only T3 `t3_thread_configure` returned `instanceId: acpRegistry_kimi_cli`, `model: kimi-code/k3.1-pro`, and `options: [{id: thinking, value: high}]`. This is the current ACP/T3 session configuration, not evidence about a separate CLI process.

Unsupported shipped-driver boundary: the installed locator succeeded from the target and found `kimi`. `kimi --help` (exit 0) exposes `-m/--model` but no reasoning-effort option. `utils/py/kimi-turn.py:87-89` exposes no effort environment variable, and `:160` builds only `kimi -p ... -m ... --output-format stream-json` plus CLI flags. The ACP `thinking=high` setting therefore cannot be preserved by the shipped `kimi -p` relay lane. `relay-drive.sh` was NOT dispatched; no tick token, `ALLOW_PATHS` enforcement, isolation worktree, driver exit or attestation exists for this advisory. No default/unknown-effort substitute, harness patch, other model, delegate, background process or publication was used.

Review method: read the full 1,826-line `relay-automation/relay-turn-lib.sh`, full relay-xyz skill, canonical plan/packet, both normal Codex relays, smoke relays, summary/provenance/hashes/full-gate records and live issue/PR state. Only read-only probes and GitHub queries ran; no tests, executable fixtures, mutation runs or clone creation. The only write is this newly scaffolded relay file. The protected LTVera primary was not edited.

swept file: yes

VERDICT: FAIL
Basis: one `Should` remains in the actual rendered shared prompt. No Blocker and no other concrete defect or unnecessary controller was found in the bounded delivery. This is an advisory changes-requested verdict for parent adjudication, not a supervisor result.

- [Should] S1 — Remove the direct conflict between required read-only identity/source inspection and the blanket Git prohibition. `relay-automation/relay-turn-lib.sh:1067` requires HEAD/origin/bare/local identity before and after an assigned clone command, but `:1172` still says `NEVER run git yourself — no add/commit/push/reset`. The retained candidate render contains both clauses in `TESTS-RESULTS/2026-11-12+GH-1092/candidate-prompt.txt:1`. Narrow the latter to state-changing Git operations and explicitly permit read-only local Git inspection; keep add/commit/push/reset and shared-Git mutation forbidden. No new test/gate is requested.
  Observed input: the actual candidate prompt contains both `Before and after execution, record its resolved root, HEAD, origin, bare flag and local user identity` and `NEVER run git yourself`. The final reviewers worked around this by using Python pathlib/configparser with `no Git invocation` / `No Git command was invoked` (`relay-system/2026-11-12/gh1092-final.codex.md:123` and `:163`) instead of ordinary read-only Git inspection.
  Affected scope: generic reviewers using read-only local commands such as `git rev-parse`, `git show`, `git config --get`, or `git remote -v` for pinned-source and supplied-clone identity checks. It does not authorize any Git mutation or execution in a protected checkout.
  Falsifier: a rendered prompt that explicitly permits those read-only commands while still forbidding add/commit/push/reset and shared-Git mutation, followed by a reviewer transcript successfully using them without containment failure, resolves S1. If the intended contract is Python-only identity reads, say that explicitly instead and remove the apparent permission for general pinned-source Git inspection.

- [Pass] Q1 — The shared prompt/mirror/package implement independent measurement rather than receipts-only QA. `relay-automation/relay-turn-lib.sh:1067` delivers target-rule discovery, read-only GitHub/pinned-source permission, scratch probes, explicitly assigned supplied-clone commands, identity brackets and Unverified fallback; `skills/1-hourly/relay-xyz/SKILL.md:717` mirrors it. `delivery-control.json:2-20` rejects the baseline on eight missing delivery clauses. The candidate has live main-target measurement with all eight gh681 cases and forbidden-residue rejection (`gh1092-final.codex.md:162-166`), plus foreign-target policy delivery and explicit missing-runtime refusal (`gh1092-smoke-foreign.codex.md:76-80`). These establish the declared instruction/execution seam, not universal model compliance or browser safety.
- [Pass] Q2 — Repository rule scope is respected. The shared clause says Forge GH-831 is Forge-only (`relay-turn-lib.sh:1067`), and the foreign smoke identifies LTVera's own justified-new-tests/disposable-Postgres policy instead of importing a moratorium (`gh1092-smoke-foreign.codex.md:77-80`). The base-to-head path list contains no `test/`, `validate.sh`, controller or registry implementation change; this review requests none. LTVera's protected primary remained read-only.
- [Pass] Q3 — Normal QA findings were faithfully resolved without silent narrowing. PLAN S1's demand for an explicit baseline rejection (`gh1092-plan.codex.md:114-117`) was implemented in plan step 5 and approved at `:138-153`. FINAL B1 records the observed inherited-environment exit 1 at `gh1092-final.codex.md:118-121`; Producer modified only the child environment at `:132-154`, and the reviewer independently reran it to exit 0 with all eight cases at `:156-168`. Original FAIL/PARKED records remain intact.
- [Pass] Q4 — QA and manual controls are defect-sensitive under the declared scope. `delivery-control.json:2-20` distinguishes unchanged baseline from candidate; `gh1092-final.codex.md:162` quotes scratch-only acceptance and `.pytest_cache` residue rejection; `gh681-reviewer-probe-rules.log:21-30` independently retains those negative controls. The final review does not mistake attestation for semantic truth (`gh1092-final.codex.md:165-168`). No LTVera browser or global safety conclusion is inferred.
- [Pass] Q5 — GH981's original eight findings and owner choices remain explicitly open. Live read-only `gh issue view 981` returned `OPEN` with all eight original and six decision checkboxes unchecked; live #1092 is also `OPEN`. `SUMMARY.md:39-50` says neither issue closes, labels owner recommendations `proposed, not adopted`, and leaves the real app/copied-storage/native-navigation/126-second replay outside this PR. PR1446 uses `Refs #1092`, not a closing keyword, and states the same bounded scope. PR1432/1445 are reused with no duplicate controller. No actual LTVera browser replay or global safety/draft/no-change policy is claimed here.
- [Pass] Evidence/gate continuity — `full-gate.log:412-472` records 21 Python-layer passes and `passed: 408 / 408`; `full-gate-receipt.json:2-11` binds that result to `70ebdeb4f4bb4ac9ea3ec8b7ccdbbac8b1417945`, exit 0, full scope. `git diff --exit-code 70ebdeb4...HEAD -- relay-automation/relay-turn-lib.sh skills/1-hourly/relay-xyz/SKILL.md skills/1-hourly/relay-automation/relay-pkg.tar.gz` exited 0. `shasum -a 256` on those three files (exit 0) exactly matched `implementation-sha256.json:3-7`; `tar -xOf ... relay-automation/relay-turn-lib.sh | shasum -a 256` (exit 0) returned `2f6c5c9d27ccd950550e3a14ca6b10d6bf4a75366b526f36305061bbddeddab7`, matching the source. Later commits are evidence/status only as claimed. This was receipt verification, not a fresh gate run or promotion qualification.
- [Pass] Q6 — No additional bug/regression/complexity finding. The implementation changes one existing role note and its existing mirror/package; `utils/py/rtl.py` still delegates to the shared prompt and no terminal controller changed. The declared full-clone identity fields are present in `full-before.json:2-7` and `full-after.json:2-7`; demanding different commands or additional remote listings is not required by the bounded plan.

Limits: no fresh runtime suite, actual LTVera browser replay, global policy ratification, merge/deploy/install, push, or driver-attested Kimi relay was performed. Existing Codex attestations were inspected, not relabeled as Kimi evidence. Unpublished evidence and clones remain preserved.

Handing off to Producer (parent) — adjudicate S1 and own any minor correction; no additional Kimi relay round was driven.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
