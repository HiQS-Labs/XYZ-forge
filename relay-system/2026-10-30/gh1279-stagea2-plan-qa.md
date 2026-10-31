# RELAY · GH-1279 Stage A2 plan QA (Codex-authored plan content)
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-30.
-->

NEXT: Reviewer
STATUS: Open
ROUND: 3 / 4

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
6. **Commit only the relay file** (`relay(gh1279-stagea2-plan-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: `PROJECT/2-WORKING/GH-1279-READ-ONLY-PLANNING-SOAK.md`, sections "Operator decisions recorded (2026-10-31)" and "Stage A2 plan — Codex-authored plan content" (the Stage A section above them is built and already approved; review only how A2 builds on it). Sources to read: `utils/py/harness.py` (`plan_draft`, `_verify_plan_draft`, `execute_tool`, `_validate`, `run_tick`, `codex_decide`, `_file_index`, `_sections`, `_cited_paths`, `make_packet`, `_build_proposal`), `utils/py/factory_primitive/prompts/evaluator.v2.md`, `utils/py/_marathon_plan.py` only as needed, `TESTS-RESULTS/2026-10-30+GH-1279/SUMMARY.md`, `AGENTS.md` (No new tests, GH-831).
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-10-30
- Definition of Done: the plan's "Acceptance (Stage A2)" list is achievable, falsifiable and grounded in the real code paths; the design extends the existing seam (decision -> validator -> `plan_draft` tool -> brief -> proposal/packet) without a second call, tool, writer or queue; the main risk (authored text reaching briefs and later builder prompts) is stated honestly.

**Operational envelope.** Local single-operator harness; read-only experiment; the deterministic validator is the safety boundary; one 8-hour window on one machine. Grade against the stated requirements and commensurate complexity. Do NOT ask for multi-tenant threat models, retries, new test suites or registry entries (GH-831 forbids them), or machinery beyond what the plan names. Challenge bloat in the plan itself.

**Questions** (cite file:line; give the concrete failing input for any behaviour-change request):
1. Is the plan's description of `plan_draft` true: sourced `found["scope"|"acceptance"|"open_questions"]` and `write_set` feed `status` (`held` / `needs-recon` / `missing-scope` / `ready` / `draft`), and merging authored entries before that logic would let a previously held issue become a `draft`? Is anything downstream (`_build_proposal`, `make_packet`, `_verify_plan_draft`, `BRIEF_KEYS`, `render_brief`) broken or silently changed by extra entries, the new `authored` key, or authored write-set paths?
2. Does `_validate(decision, snapshot, tracked)` have exactly one call site in `run_tick`, and can `tracked` be loaded there from `backlog/base-files.txt` (via `_file_index` or directly) without new machinery? What does `base-files.txt` contain (tracked files at the frozen base?), and is "path in tracked" the right test for an invented file (renames, new files an issue plans to create)? Name the false-reject risk concretely: a plan that legitimately creates a new file.
3. How do `args` flow from the persisted intent to `plan_draft` (`--args-json`, size limits, `input_fingerprint`, failure suppression, quarantine of ambiguous attempts)? Does adding `authored` (up to ~20 KB) break any of that?
4. Prompt grounding: is reading `backlog/issues.json` via `config["manifest_path"]` correct for `init --from-prs` instances, and is the 12 requests x (5000 + 3000 chars) material block safe for a single positional argv (macOS ARG_MAX) and for the call timeout of 90 s with Terra 6.1 at medium effort? Is limiting the model to the first 12 pending requests consistent with the rules arm's oldest-first order and the 96-slot schedule (66 real requests)?
5. Is `--codex-authoring` defaulting off enough to keep Stage A's config, prompt hash and behaviour byte-identical, and is the `evaluator.v3.md` selection placed in the two config writers without a third path?
6. Risks: is the injection-into-briefs risk described accurately, and is each stated mitigation real in the code (bounded sizes, labels, sourced material kept, nothing auto-launches)? Is there an unstated gap (for example `render_brief` markdown injection, or authored text reaching `MARATHON.yaml` / `make_packet`)?
7. Verification: do the step-2 controls detect the actual failures, with a red control, and without adding a suite or registry entry? Is anything the operator decisions table implies (180 calls, dry-run cap 10, this-machine run, no merge) missing from the plan or contradicted by it?
8. Is the design commensurate and the smallest that meets "Codex authors plan content"? Name any piece that could be cut, or any requirement the plan fails to meet.

Write the verdict (PASS / FAIL / PARKED) with a Basis; set `STATUS: Approved` only on PASS.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer · Round 1 · codex

VERDICT: FAIL

Basis: The existing seam is the right size, but the combined write-set promise fails for `ready` briefs, and blank authored scope can manufacture readiness. Correct those two plan contracts before building. This is plan QA, not implementation approval.

swept file: yes

Read the entire 327-line artifact, with findings scoped to the operator decisions and A2; read all of `harness.py`, v2, the Stage A summary, and the relevant planner packing code. No additional pre-existing defect requiring a separate repair was established. Graph discovery was attempted but returned “MCP tool call requires approval, but approval policy is never”; source reads supplied the evidence. No git, suite, executable fixture, adapter call, or tool writer ran.

- **[Should] R1 — combined paths disappear for planner-ready issues.** A2 design 3 (`PROJECT/2-WORKING/GH-1279-READ-ONLY-PLANNING-SOAK.md:304`) promises collision checks and packets over the combined write set. In `harness.py:550` the ready record is copied unchanged; only `draft` briefs replace `writeset` (`:554–562`). `make_packet` uses that lane's paths (`:1151`) while copying the authored Markdown (`:1140`). A ready brief can therefore instruct work outside the packet's claims and collision set. Fix: explicitly extend `_build_proposal` to overlay the combined paths on the existing ready lane once, preserving its readiness checks and leaving the actual planner view unchanged; alternatively prohibit additions for ready lanes and state that restriction. Extend the existing manual controls with ready-brief → proposal → packet path agreement and a shared-path collision case; the unchanged proposal builder is the red control. Dynamic packet evidence is **[Unverified — needs clone run]**.
  - Observed input: the plan's permitted authored `write_set` addition at `:302–304` with the `draft_status == "ready"` value produced by `harness.py:652`; concretely a ready lane with `writeset=["utils/py/harness.py"]` and an accepted brief also adding tracked `utils/py/_marathon_plan.py`. The unchanged `ready` branch never reads that addition.
  - Affected scope: ready briefs whose combined paths contain at least one path absent from the computed lane; draft briefs already take the combined paths.
  - Falsifier: in the disposable-clone manual control, that added path must appear in the provisional lane and emitted packet claims, and prevent co-waving with another lane writing it. A ready brief with no addition must retain one lane and the original paths.

- **[Should] R2 — empty strings can lift the missing-scope hold.** Design 1–3 allows `scope:[""]` or `scope:["   "]` (strings below the upper bound). Merging either makes `found["scope"]` truthy, so `harness.py:649–652` no longer reports missing scope. Sourced extraction deliberately omits empty content (`:373–376`). Fix: require nonblank authored entries (or discard them before evaluating presence), and add this input to the existing manual controls. Preserve the distinction between structural validation and judging whether nonblank scope is true.
  - Observed input: `authored={"scope":["   "]}` under A2 `:302`, on the missing-scope case explicitly required by step 2 (`:318`), with an existing nonempty write set and planner state `needs-contract` or `unregistered`.
  - Affected scope: authored scope entries containing no non-whitespace content that would otherwise satisfy the list-presence check.
  - Falsifier: the whitespace input must remain held or be rejected; replacing it with a supported nonblank scope must permit `draft` while preserving sourced entries. Run this in the disposable clone; no runtime control was executed here.

- **[Nit] N1 — specify off-mode output compatibility.** A2 `:304` unconditionally adds `authored: true|false`, while `:318`/`:326` require Stage A equivalence with authoring absent. Adding `authored:false` changes brief JSON and receipt hashes even though `render_brief` ignores it. Cheapest resolution: omit the new field on the off path, or explicitly narrow the promised equivalence to decision/status semantics and retain the exact config/prompt requirement. Keep prompt selection in `adapter_config` (`harness.py:873–884`), already shared by both config writers (`:831`, `:913`), and guard material loading as well as prompt selection with the flag.

- **[Nit] N2 — tracked is an admissibility policy, not a truth test for invention.** `base-files.txt` is exactly the tracked HEAD tree at init (`harness.py:730`, manifest head `:810`); `_file_index` supplies its set (`:404–410`). A legitimate plan creating `utils/py/factory_primitive/prompts/evaluator.v3.md`, the new file this very plan requires (`A2 :306`, `:317`), fails membership against a base without it. Renames likewise have an absent destination. Keep the conservative restriction if intended, but name the false-reject risk in Risks and include a legitimate-new-file control/QA label; do not count all such rejections as hallucination detection. No new-file support mechanism is requested.

- **[Pass] integration and persistence, subject to R1/R2.** The status order is state hold → missing write set → missing scope → ready/draft (`harness.py:645–655`); acceptance and questions do not gate readiness. Authored entries can lift the two content holds, not arbitrary planner-state or landed-probe holds. There is one `_validate` call (`:1289`), and loading the frozen file set there in PRS mode needs no new subsystem. Intents store full args as TEXT (`:55–57`, `:1307–1308`); `--args-json` reaches `execute_tool` and `plan_draft` (`:1199`, `:1465–1466`, `:293`). Extra brief keys are allowed by the required-key check (`:696`); Markdown verification rerenders entries (`:705`). Fingerprints include all args (`:952–953`), so changing author text changes identity, but ambiguous plan attempts are quarantined by inbox ID, not retried (`:1336–1342`, `:1073–1079`). Do not describe failure suppression as invariant under author-text edits.

- **[Pass] grounding, ordering and transport are feasible; full-load timing remains unverified.** PRS config points at `backlog/manifest.json` (`harness.py:816–829`), whose request map supplies issue/doc references; sibling `issues.json` is correct (`:609`). Pending requests are ordered by `created_at,id` (`:1011`), matching rules iteration (`:190–201`); first 12 is a rolling material window, not a 12-request limit on the 66-request run. The shown-only restriction is a prompt rule unless explicitly added to validation; today's validator admits any eligible snapshot ID (`:990–993`). Narrow non-mutating probe (exit 0): `python3 -c 'import os,subprocess; s="界"*(12*(5000+3000)); print("bytes",len(s.encode()),"ARG_MAX",os.sysconf("SC_ARG_MAX")); print("rc",subprocess.run(["/usr/bin/true",s]).returncode)'` → `bytes 288000 ARG_MAX 1048576` / `rc 0`. This disproves an assumed 256-KiB limit on this machine, but measures only the material block. Add a full-prompt transport check including populated recent authored args to the existing manual controls and exercise the 12-request case in the planned live smoke. **[Unverified — needs clone run]**: full argv/environment headroom and Terra-medium completion within 90 s; two early slots alone do not measure maximum pending material/history (`A2 :319`; `harness.py:1014–1016`, `:243`).

- **[Pass] risk and scope are commensurate.** The explicit injection risk at A2 `:312–313` is real: authored text is rendered as raw Markdown (`harness.py:469`) and copied into packet briefs (`:1140`, `:1157`); labels can themselves be visually spoofed and are attribution, not sanitization. Paths reach YAML via `Packet` (`:1150–1151`). The plan honestly says the design does not remove this risk; bounded lists, retained sources and no auto-launch are real, limited mitigations. Step 2 keeps controls in a disposable clone with no new suite/registry (`A2 :318`; `AGENTS.md:156`); the old validator rejects the positive authored input (`harness.py:991`), a useful red control for that positive assertion, not proof of every downstream check. Decisions `:284–291` supply Terra/medium, up to 180 calls, dry-run cap 10, this machine, explicit go and pinned unmerged head. A2 `:307` carries the cap; these recorded overrides govern the older mirrored Stage B text. No second tool/call/writer/queue is needed; fix the existing proposal seam rather than introducing one.

Handing off to Producer (claude-a) — address R1/R2 and disposition the notes, then go to the Producer window and say 'take your turn'.

### Producer · Round 2

Plan revised and committed (A2 section, Risks, step 2 controls, step 3, Acceptance). Dispositions:

- **R1 — Modified.** An overlay on ready lanes is declined as extra machinery. Instead authored `write_set` additions apply to `draft` briefs only (where `_build_proposal` already substitutes the combined paths); for a planner-`ready` brief `plan_draft` drops them and records `"authored_ignored": ["write_set"]`, so proposal and packet stay the planner's. Controls added: ready brief keeps planner paths; draft brief's authored path reaches the lane and packet claims and separates two lanes sharing it. The unchanged proposal builder is the red control for the draft case.
- **R2 — Implemented.** Authored entries must be nonblank after trimming; blank or whitespace-only entries return `authored-shape`. Control: `scope:["   "]` stays rejected; nonblank authored scope lifts the hold while preserving sourced entries.
- **N1 — Implemented.** `authored: true` is written only when authored content was merged; with authoring off or absent the brief JSON is byte-identical to Stage A's. Material loading and prompt selection are both guarded by `--codex-authoring`.
- **N2 — Implemented.** Risks now name the tracked-tree false-reject (new files and renames), keep the conservative rule (new files go in scope/open-questions text), and report such rejections as policy false-rejects, not hallucination detection; a legitimate-new-file control is added.
- **Notes accepted.** Failure suppression is no longer described as invariant under author-text edits; the "shown requests only" rule is stated as a prompt rule with the validator unchanged; the 12 is stated as a rolling window; a full-prompt transport control (12 pending requests, populated history) and a live latency measurement against the 90 s cap are added; the raw-Markdown/label-spoofing point is added to Risks.

Requesting Round 2. Please confirm R1/R2 are closed or name the concrete input that still fails.

Handing off to Reviewer (codex) for Round 2.

### Reviewer · Round 2 · codex

VERDICT: FAIL

Basis: R1 and R2 are closed at the plan level. One remaining contract gap prevents approval: default-off compatibility is promised, but authoring is gated only in prompt construction, not at the deterministic decision boundary. This needs a small clarification in the existing seam, not new machinery. This is plan QA, not implementation or run approval.

swept file: yes

Read the entire 330-line artifact and all 1522 lines of `harness.py`, v2, the Stage A summary, and the relevant wave-packing code. Findings concern A2 and its operator decisions; no additional pre-existing defect requiring separate repair was established. Graph discovery returned “MCP tool call requires approval, but approval policy is never”; direct source reads supplied the evidence. No git, suite, executable fixture, adapter call, or tool writer ran. Only this relay file was edited.

- **[Should] R3 — enforce the off switch at validation, not only in the prompt.** A2 design 4–5 gates material loading and prompt selection (`PROJECT/2-WORKING/GH-1279-READ-ONLY-PLANNING-SOAK.md:305–306`), but design 2 admits `authored` whenever `tracked` exists (`:303`), and design 3 unconditionally reads and merges it (`:304`). Neither names the authoring flag at the validator/merge boundary. Stage A rejects every extended argument set (`utils/py/harness.py:991–993`); the proposed rule instead accepts this nonblank, path-free extension in backlog mode and changes the brief, even with the flag absent. v2's instruction to return only `inbox_id` (`utils/py/factory_primitive/prompts/evaluator.v2.md:10`) cannot establish the compatibility promise at A2 `:328`. Fix: explicitly require authoring to be enabled before accepting authored args in the existing validation path, preserve Stage A rejection when disabled, and include an off-mode authored-response control in step 2. Keep the merge behind that validated decision; no second validator or writer is needed.
  - Observed input: replay the retained eligible request `gh-1201-794fcf69ac2c` from `TESTS-RESULTS/2026-10-30+GH-1279/live/two-arm-smoke-terra-medium.json`, with its pending snapshot, no recent failures, PRS `tracked` loaded, and authoring absent/false. Adapter response: `{"tool":"plan-draft","args":{"inbox_id":"gh-1201-794fcf69ac2c","authored":{"scope":["Review the supplied issue scope."]}},"reason":"oldest plan request","confidence":1}`. The current exact-key rule rejects it; A2's stated shape/backlog rules admit it and append scope. This is a source-derived counterexample, not an executed adapter result.
  - Affected scope: otherwise-valid authored responses in backlog instances with `--codex-authoring` absent or disabled. Ordinary sourced-only decisions and enabled authoring should retain their respective paths.
  - Falsifier: replay identical stub output with the flag off and on in the disposable-clone controls. Off must reject with Stage A's `plan-draft-id-not-eligible`, safe-idle and emit no authored brief; on must accept and label the added scope. An existing specified flag check that already produces these results would close this finding. Runtime evidence is **[Unverified — needs clone run]**.

- **[Pass] R1/R2 closed by the revised contracts.** Design 3 explicitly drops authored paths for planner-ready records and records `authored_ignored` (`A2 :304`, acceptance `:329`), so the unchanged ready lane (`harness.py:550–552`) cannot disagree with added authored paths. Draft lanes already take brief paths (`:554–560`), packing checks exact overlaps (`utils/py/_marathon_plan.py:835`), and packet YAML takes the resulting lane paths (`harness.py:1150–1151`). Nonblank validation (`A2 :302–303`) closes the whitespace-presence bug at `harness.py:649`. Step 2 (`A2 :320`) names both controls. These are grounded plan resolutions; execution remains outstanding.

- **[Pass] the remaining design stays within the existing seam.** Required-key verification permits added brief metadata (`harness.py:696–705`); persisted full args flow through the existing tool invocation (`:1307–1317`, `:1199`, `:1465–1466`). The one production validation call remains `:1289`. Both config writers share `adapter_config` (`:831`, `:913`), so default-off config/prompt compatibility is feasible without another config path. Risks now explicitly retain the legitimate-new-file/rename false-reject and raw-Markdown/label-spoofing limitations (`A2 :313–314`); authored text still reaches packet briefs (`harness.py:1140`, `:1157`). No additional tool, call, queue, planner change or test suite is warranted.

- **[Pass] operator decisions and verification scope remain represented.** The decisions table (`A2 :284–291`) records Terra/medium, 180 calls, dry-run cap 10, this machine, explicit go and the pinned unmerged head; design 6 carries the reservation settings (`:307`). Full prompt transport with populated history and a 12-request live latency measurement are now explicit (`:320–321`). **[Unverified — needs clone run]**: actual transport headroom, completion time, packet/collision controls, byte compatibility and the classified gate. The old validator is a red control for positive authored admission, not evidence that every downstream assertion is sensitive; final QA must inspect the individual control receipts.

Handing off to Producer (claude-a) — specify the opt-in validation boundary and off-mode authored-response control for R3, then go to the Producer window and say 'take your turn'.

### Producer · Round 3

Dispositions (plan revised and committed):

- **R3 — Implemented.** The off switch now lives at validation. `run_tick` passes `tracked` to `_validate` only when `config["codex_authoring"]` is true and the frozen `backlog/base-files.txt` exists; otherwise `tracked` is `None`, and `None` means Stage A's exact-key rule applies unchanged, so an `authored` argument is rejected as `plan-draft-id-not-eligible`, safe-idle, no authored brief. The separate `authored-without-backlog` reason is removed (it is the same condition). The merge in `plan_draft` is reachable only behind a validated decision. A control replays the identical stub response with authoring off (rejected as above) and on (accepted, labelled).
- **Notes accepted:** final QA will inspect the individual control receipts, not only the pass count; the classified gate, transport headroom, latency, packet and byte-compatibility evidence remain owed at build time.

Round 3 is the last under the cap. Please confirm the plan is buildable or name the concrete input that still fails.

Handing off to Reviewer (codex) for Round 3.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
