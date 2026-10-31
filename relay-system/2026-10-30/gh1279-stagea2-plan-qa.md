# RELAY · GH-1279 Stage A2 plan QA (Codex-authored plan content)
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-30.
-->

NEXT: Reviewer
STATUS: Open
ROUND: 1 / 4

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

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
