# RELAY · GH-1279 Stage A plan QA
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
6. **Commit only the relay file** (`relay(gh1279-stagea-plan-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: `PROJECT/2-WORKING/GH-1279-READ-ONLY-PLANNING-SOAK.md`, section "Stage A plan — Codex decision adapter (this PR)". Read the whole doc plus the issue text it mirrors, and these sources: `utils/py/harness.py` (`AdapterResult`, `rules_decide`, `_adapter`, `_validate`, `_settle`, `run_tick`, `init_instance`, `init_from_prs`, `factory_parser`), `utils/py/proc_group.py` (`run_bounded`), `utils/py/factory_primitive/prompts/evaluator.v1.md`, `utils/py/factory_primitive/schemas/decision.schema.json`, `PROJECT/2-WORKING/GH-1248-OUTER-LOOP-PRIMITIVE.md`, `AGENTS.md` (No new tests, GH-831).
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-10-30
- Definition of Done: the plan's "Acceptance (Stage A)" list is achievable, falsifiable and grounded in the real code paths; nothing in the issue's six Codex-arm entry gates is missing from the plan or silently dropped.

**Operational envelope.** Local single-operator harness on one Mac; an 8-hour read-only experiment behind an existing, validated loop. Grade against the stated requirements and commensurate complexity. Do NOT ask for multi-tenant threat models, retries, new test suites or registry entries (GH-831 forbids them), or machinery beyond one adapter function plus three init flags. Challenge any bloat in the plan itself.

**Questions** (cite file:line):
1. Is each claim in the Recon section true of the code? In particular: does `run_tick` reserve, call `_adapter`, `_settle`, persist raw to `telemetry/transcripts`, route `decision is None` to safe idle, and pause at `spent >= daily_cap` exactly as stated?
2. Does the design extend the existing seam (`_adapter`, `AdapterResult`, config) without a second writer or loop? Is `run_bounded` really a drop-in for the 90 s loop-enforced cancel (`timed_out` surfaces, the process group is killed)?
3. Cost/call cap: with `--daily-cap 0.9 --max-call-cost 0.01` and every Codex call `billing_status=unknown`, does the existing accounting yield exactly 90 calls and then PAUSE? Check `_reserve`, `_settle`, the `spent` query and the `remaining < max_call_cost` branch for off-by-one or float issues (0.01 * 90 vs 0.9).
4. Classification: are `ok`, `invalid-output`, `timeout`, `rate-limited`, `adapter-error` all handled by the existing downstream code (`decision_status`, `_safe_idle(f"adapter {normalized}")`, any CHECK constraints or enums in the schema for decisions/ticks/receipts that would reject `rate-limited`)? Name every place a new normalized value could break.
5. Containment: is the stated mitigation (read-only sandbox, empty cwd, ephemeral, ignore user config/rules, API key stripped, prompt forbids tools) honestly described? Is anything the adapter lets Codex read or write a gap relative to the issue's "no agent tools" gate, and is the plan's wording about it accurate rather than overclaiming?
6. Is anything in the issue's six entry gates, the shared run contract (as far as the adapter touches it) or the acceptance criteria that Stage A owns missing from the plan? Is the manual-control list sufficient to detect the actual failures, with a red control, and without adding a suite or registry entry?
7. Is the plan commensurate? Flag unneeded pieces (e.g. a v2 prompt file, schema edit, flag count) or anything over/under-engineered.
8. Does the rating (60/30/50/40) have a grounded rationale?

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
