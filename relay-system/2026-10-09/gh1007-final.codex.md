# RELAY · GH-1007 SWE post-build QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-09.
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
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns.
   Reviewer headings may be `### Reviewer · Round N`, `### Round N · Reviewer · <agent>`, `### Reviewer (<agent>)` (optionally followed by `— rN`), or `### Reviewer — Round N` (optionally followed by `(<agent>)`); follow the heading with a non-empty review body.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(gh-1007-swe-post-build-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: `skills/1-hourly/swe/SKILL.md`, `ARCHITECTURE.md`, `PROJECT/2-WORKING/GH-1007-SWE-GOVERNANCE.md`, `TESTS-RESULTS/2026-10-09+GH-1007/`, `CHANGELOG.md`, roadmap row GH-1007 and plan relay
- Reviewer: codex   ·   Producer: codex-author
- Started: 2026-10-09
- Definition of Done: All GH-1007 acceptance requirements are implemented; evidence is truthful, retained and commensurate; no new tests, gate machinery, runtime subsystem, or unauthorized deployment. Independent plan QA is Approved.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Review packet and explicit questions

Operational envelope: instruction-only skill, existing lifecycle and distribution tools.
No enterprise hardening, blanket SOLID ceremony, runtime framework, or new test suite.
Use /ponytail as the primary complexity filter. The integration base is
`ecec5561a200b12c235bec3dd9dc37dd5d8d0d5e`; implementation checkpoint is `ebad4e53`.
Read the full updated skill, plan, evidence, and plan-review dispositions. Only task
records/evidence and relay setup change after that implementation checkpoint. The actual
classifier selected docs/tier 1. Review current gate evidence if present; pending push/hosted
attestation remains a separate publication boundary, never infer it from this review.

1. Does the final source govern planning, implementation, and code review using the four
   agreed axes, requiring reuse/extension without sacrificing real security/safety contracts?
2. Do new tests have a meaningful burden of proof and an independent CI-admission decision?
   Does the text honor GH-831, avoid quotas/policy tests, and preserve necessary verification?
3. Apply the seven manual scenarios yourself using the final text. Would an Easy rename
   trigger ceremony? Would an authorization gap be ignored? Would cache-driven CI improvement
   be mislabeled product speed? Would an authorized irreversible action without its last-safe
   intervention point be accepted? Record your own decisions and decisive citations.
4. Omission-diff: compare to the old source using the plan relay's recorded audit. Are S1,
   mixed-version migration, failure diagnosis, rollback and named Pillar 0/Blast consumer
   contracts retained without arbitrary FSM/SOLID/scaffold/bidirectional-sync requirements?
5. Is every claimed verification backed by nonempty evidence and source digest/revision?
   Format sensitivity is only a format claim, manual scenarios are bounded textual evidence,
   and the existing codex-turn suite was run in a disposable full clone. Do not turn these
   into a claim of live multi-model compliance or product-performance improvement.
6. Are the PRS rating/accepted-start record and serial GH-1008 boundary truthful? Is any
   parallel subsystem, test file, gate change, deployed payload or unrelated edit present?

Reviewer may write only this relay file. Do not run test suites, validate.sh, pytest, or
executable fixtures; do not mutate source or self-commit. The shim commits your relay.
Approve only the implemented scope supported by evidence. Use file:line/quoted spans for
findings. No missing runtime benchmark is a finding for this documentation-only change.

## Log

### Reviewer · Round 1

VERDICT: FAIL
Basis: The SWE implementation satisfies the seven instruction scenarios and preserves the repaired safety contracts. One pre-existing, concrete architecture-document error needs a small correction under this relay's whole-file rule. Review coverage is also incomplete as disclosed below; this is not implementation, publication, or merge approval.
swept file: no

- [Should] **F1 — Distinguish the default Python runtime from the historical Bash description.** `ARCHITECTURE.md:173` says “Nobody imports anybody” and describes shell processes throughout; `:208` and `:238` locate the shared containment implementation in `relay-turn-lib.sh`, under an unqualified current-code claim at `:138`. The actual entry shims default to Python (`relay-automation/codex-turn.sh:9` and `:18`; `relay-automation/relay-drive.sh:9` and `:18`). The default Codex implementation imports `RelayTurnLib` from `rtl` at `utils/py/codex-turn.py:7`, calls `rtl.before()` at `:72` and `rtl.enforce(...)` at `:136`; the driver imports shared helpers at `utils/py/relay_drive.py:17`. A reader following the architecture for a default-runtime fix is sent to the frozen fallback. Cheapest correction: identify the Python owners and qualify the shell-specific account as the legacy `XYZ_PYTHON=0` path; remove or qualify the categorical no-import claim. No runtime change, new suite, or architecture redesign is requested.
  Observed input: the unqualified current-runtime statements at `ARCHITECTURE.md:173`, `:208`, and `:238`, contradicted by the default dispatch and imports cited above.
  Affected scope: documentation of default relay implementation ownership versus the Bash fallback; this is pre-existing in a file the relay explicitly includes, not a flaw in the new SWE rubric.
  Falsifier: with `XYZ_PYTHON` unset and supported Python present, source dispatch would have to execute the inline Bash body rather than `utils/py/codex-turn.py`; the current shim does the opposite. A corrected document should direct default-runtime repairs to Python while retaining the fallback account as such.
  Read-only source probe: `rg -n "^(import rtl|from rtl)|rtl\.(init|before|enforce|run_bounded)|def main" utils/py/codex-turn.py utils/py/relay_drive.py`, exit 0. Decisive output: `utils/py/codex-turn.py:7:from rtl import RelayTurnLib, claim_task_or_exit, rtl_default_log, resolve_turn_root`; `:72: rtl.before()`; `:136: rc = rtl.enforce(t, me, codex_log, "codex")`. This is source evidence, not an executed runtime test.

- [Pass] **Three modes, four axes, and earned verification.** `skills/1-hourly/swe/SKILL.md:14`–`:18` covers planning, implementation, and review while preserving project authority. Its `:26`–`:31` makes safety/security floors explicit; `:41`–`:49` requires contract-aware reuse and justified separation; `:57`–`:67` prices test creation separately from CI placement and forbids quotas/policy tests. `:18` preserves GH-831's stricter prohibition and `:67` preserves necessary security/data-integrity verification. No additional defect was found in the full 114-line SWE source.

- [Unverified — no citation] **Independent application of all seven scenarios.** These are my bounded textual decisions, not model-execution results:

  | Input | Reviewer decision | Decisive final-source citation |
  | --- | --- | --- |
  | Easy rename with existing coverage | Reuse focused verification; reject mandatory new tests, phase scaffolding, or a benchmark. | `skills/1-hourly/swe/SKILL.md:20`, `:55`, `:67`, `:75` |
  | Authorization boundary with missing coverage | Require meaningful security verification. A new test needs the stated gap/cost proof and a separate CI decision, subject to repository prohibition. | `skills/1-hourly/swe/SKILL.md:18`, `:27`, `:57`–`:67` |
  | Feature fits an existing writer; alternative crosses incompatible trust boundaries | Extend the owner in the first case; permit explained separation in the second. | `skills/1-hourly/swe/SKILL.md:41`–`:49` |
  | Faster CI due to warm dependencies; noisy product sample | Classify the cache result as pipeline timing only; treat the noisy product result as inconclusive. | `skills/1-hourly/swe/SKILL.md:81`–`:84` |
  | Slow hot path with a material latency budget | Capture comparable base/candidate workload/environment/samples; report advisory evidence in existing task records. No automatic gate or issue per sample. | `skills/1-hourly/swe/SKILL.md:75`–`:90` |
  | Authorized irreversible action without a stop checkpoint | Reject as incomplete despite authorization: name the stop signal and last safe intervention point. Easy rename remains exempt from that ceremony. | `skills/1-hourly/swe/SKILL.md:20`, `:100` |
  | Mixed-version rolling migration; safe offline alternative | Require ordering, compatibility, bounded backfill, convergence, rollback and retirement accounting. Do not mandate bidirectional sync or unsafe fallback; permit simpler offline handling. | `skills/1-hourly/swe/SKILL.md:49`, `:100`–`:104` |

- [Pass] **Omission audit against the recorded plan-review comparison.** `relay-system/2026-10-09/gh1007-plan.codex.md`, Reviewer Round 2, records the deliberate removal of arbitrary FSM/use-count/SOLID/scaffold/correlation-ID and universal dual-sync prescriptions. Final `skills/1-hourly/swe/SKILL.md:43`–`:49`, `:96`, `:102`, and `:108` implement those substitutions. S1's stop signal and last safe intervention point are present at `:100`; failure diagnosis and bounded loops at `:96`–`:98`; mixed-version obligations at `:104`. Pillar 0/Blast names and current-state versus proposed-impact distinction remain at `:35`, `:37`, `:94`, matching the consumers at `skills/1-hourly/recon/SKILL.md:122` and `:128`. This comparison uses the requested recorded omission audit; I did not independently retrieve the base Git blob.

- [Pass] **Nonempty retained evidence matches the final skill bytes.** Read-only Python probe, exit 0: `hashlib.sha256(Path("skills/1-hourly/swe/SKILL.md").read_bytes()).hexdigest()` returned `b8a507482cd0def67078df57b1477af014f63f78e8993e8061f73c6fae60fe2b`. Iterating `TESTS-RESULTS/2026-10-09+GH-1007/` and asserting every file's `stat().st_size > 0` found seven files; parsing every `provenance.jsonl` line with `json.loads` found six records, and every recorded `source_sha256` matched. `SUMMARY.md:3`–`:9` correctly identifies the exact source by digest and limits the missing-name red control to format sensitivity. Retained `codex-turn.txt` ends “codex-turn: 43 pass, 0 fail”; provenance record `relay-preflight` attributes it to revision `846cae919dbc67722957838b1883f216bdb09699` in a separate disposable clone with unchanged identity. I inspected this receipt, not that live clone. `route.txt` says `route=docs`, `tier=1`; `pdda.txt` ends “no errors, 28 warning(s)” and provenance attributes both to `ebad4e53416adffac926d968181627ec37fa338d`. None of this proves multi-model compliance or product speed; `SUMMARY.md:38`–`:47` expressly limits those claims.

- [Pass] **PRS and serial boundary.** Read-only SQLite probe, exit 0: connect with `sqlite3.connect(Path("releases.db").resolve().as_uri()+"?mode=ro", uri=True)`; run `SELECT gh_number,doc_path,rating_pri,rating_sev,rating_appeal,rating_effort,rating_ovr FROM roadmap_items WHERE gh_number IN (1007,1008)` and `SELECT event,payload,at FROM work_events WHERE gh_number=1007 AND event='in_flight'`. Decisive output: exactly one roadmap row, GH-1007, owned doc `PROJECT/2-WORKING/GH-1007-SWE-GOVERNANCE.md`, rating `75/55/50/85`, override `null`; one `in_flight` event at `2026-10-09T15:39:51Z` with `accepted_start: true`. The sum is 265. GH-1008 has no local roadmap row, consistent with the explicitly issue-only boundary at plan `:28`; plan `:30`–`:32` defers it until the prerequisite lands and does not authorize merge/deployment. Plan approval is separately attested at the end of `gh1007-plan.codex.md` (Round 2, Approved).

- [Unverified — review coverage] Full current SWE, plan, architecture and plan-review text were examined, along with the GH-1007 evidence and ledger records. The 1,048,419-byte historical `CHANGELOG.md` was not fully semantically swept; only its current entries including GH-1007 (`:3`–`:11`) were read. No base-to-head patch or changed-path manifest was seeded, and the explicit no-Git rule was honored. Consequently I cannot independently attest the exhaustive absence of unrelated edits, new test/gate files or deployed payload changes. For the next review, seed the base-to-head patch/path manifest and explicitly bound historical append-only records if an entire historical audit is not intended. This requests review input, not new testing machinery. Graph tools were unavailable in this turn; direct source reads support the findings and no graph-completeness claim is made.

- [Unverified — needs clone run] No validator, `validate.sh`, `test/*.sh`, pytest, or executable fixture ran in this reviewer turn. The retained gate evidence predates this review, and final push/hosted attestation remains a separate publication boundary under plan `:98`–`:102`.

Handing off to Producer (codex-author) — disposition F1, supply the missing review inputs/scope, and return for Round 2. Only this relay file was edited; the harness owns its commit.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
