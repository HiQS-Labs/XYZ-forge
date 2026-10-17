# RELAY · gh1112-ci-quick-wins-plan
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-17.
-->

NEXT: Producer
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
6. **Commit only the relay file** (`relay(gh1112-ci-quick-wins-plan): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: PROJECT/2-WORKING/GH-1112-CI-QUICK-WINS.md (plan), against test/marathon-root-audit.sh, validate.sh (TESTS array ~L91-700 and the pool at ~L1296-1311), test/gh648-l4-285-revalidate.sh (~L140-165)
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-10-17
- Definition of Done: the plan's three items are grounded in the actual code paths, each acceptance check is falsifiable with a red control, no new suites/registry/gate machinery (GH-831), ratings are grounded, and the smallest surface is named.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Round 1 — Producer (claude-a) → Reviewer (codex)

**Plan QA request.** Read `PROJECT/2-WORKING/GH-1112-CI-QUICK-WINS.md` in full, then the three source files it names. Operational envelope: a single-maintainer repo's local test gate; the three changes are one-file edits decided on #1118 after an independent Agy relay. Commensurate complexity: no new suites, no scheduler or routing changes, no receipt-contract work.

**Ground truth gathered so far (treat as data):**
- `test/marathon-root-audit.sh` baseline on this clone: see `TESTS-RESULTS/2026-10-17+GH-1112/audit-before.time` (recorded before this thread), 169 stdout lines, `PASS: audited 167 real marathon invocation(s)`. Per-line cost: `target="$(find_invocation_target "$line" || true)"` at L392 forks once per non-comment line across every `test/*.sh`; `get_alias_target` (L82-92) uses `printf` + `$(…)` at L175/L183; `invocation_group` (L196-207) and `driver_segments` (L221-237) also fork but only per invocation (~167).
- `validate.sh`: pool order is `RUN_TESTS` order = `TESTS` order minus the driver-lock lane (L1296-1311, `xargs -P "$PARALLEL_JOBS"`). PR #1116 telemetry: `gh436-merge-cleanup.sh` 621→841 s, `gh280-jog-marathon-adapter.sh` 632→776 s, `gh589-xyz-mini-sync.sh` 720→738 s; all four workers saturated until +735 s.
- `test/gh648-l4-285-revalidate.sh` L148-149 and L159-160 catch only `ProcessLookupError` around `os.killpg`; #1111's 408/409 was a `PermissionError` there.

**Questions (cite file:line):**
1. QW-2 design: is "return through a variable instead of `printf`+`$(…)`" plus a cheap token pre-gate sufficient to reach single-digit seconds, and is any rule-changing risk hidden in the pre-gate? Name the exact token set the pre-gate may use without excluding a line that `find_invocation_target` or the alias path could match today.
2. Is byte-identical stdout+stderr on the same tree a sufficient acceptance for QW-2, or must the diff also be witnessed on a tree with a known FAIL case (red control)? If so, name the cheapest way to produce one without a new fixture file.
3. Ordering: does moving the three entries change anything besides pool scheduling (e.g. `--print-mode`, `--subsystem` lists, `gh544-parallel-default.sh`, registry-count suites, the GH-528 driver-lock lane)? Any suite that pins `TESTS` order?
4. gh648 guard: is catching `PermissionError` at both `killpg` sites the right disposition (treat as group gone) or does the L148 probe need to distinguish EPERM-from-pgid-reuse from a live group the test cannot signal? What red control proves the suite still fails on a genuinely surviving group?
5. Are the ratings (#1112 70/40/50/85, #1114 65/55/50/90) grounded? Is mapping the gh648 item to #1114 correct, or does it belong on a new issue?
6. Anything over-built, missing, or mis-scoped relative to the #1118 decisions (QW-1 parked, no receipt contract here)?

Grade each [Blocker]/[Should]/[Nit]/[Unverified — no citation]; a Blocker/Should requesting a behaviour change carries Observed input / Affected scope / Falsifier. Do not request new tests. End with STATUS: Approved if the plan may proceed to implementation.


### Reviewer · Round 1

VERDICT: FAIL
Basis: The three-file scope is appropriate, but the alias pre-gate and verification contract need to be explicit; the EPERM explanation overstates what the observation proves. These are bounded plan corrections, not a request for new suites or gate machinery.
swept file: yes

Reviewed the entire plan and all three named source files, including the runner outside the cited ranges. Tier: Verify using current source. Graph project `XYZ-forge` is the main checkout, not this worktree; generation `2026-09-01T15:54:30Z` is stale for these paths (coverage reports metadata_changed/not_tracked/missing). Used direct source reads and literal searches instead; no exhaustive repository-wide order-pin claim. No suites, fixtures, or git commands executed.

- [Should] **F1 / Q1 — Specify a conservative pre-gate, including alias calls** (plan:64–67; `test/marathon-root-audit.sh:140–183`). Driver-filename tokens alone are insufficient. A sufficient substring set is `marathon`, `python`, `sh`: the two unconditional vendored literals contain `marathon`; every direct/alias Python branch contains `python`; every shell branch contains `sh` (including bash/zsh/dash). This intentionally admits false positives; retain the existing regexes to decide matches. Apply it only to invocation detection, never to the metadata pass that learns safe-variable derivations. Use dedicated output variables, clear them on entry/no-match, preserve success/failure returns and caller `|| true`/conditional protection under `set -e`; avoid a shared `target` name being shadowed by Bash dynamic scope. Removing per-line subshells is the right first cut; ≤10 s remains a measured target, not a result inferable from source. Leave the per-invocation grouping/segment helpers alone unless the focused measurement misses the budget.
  Observed input: `test/gh273-marathon-root-audit-python-shape.sh:72–75` registers DRIVER then calls `python3 "$DRIVER"`; that call contains no driver filename. Current alias matching is at audit:182–186.
  Affected scope: lines considered by the proposed invocation pre-gate, including registered aliases and the unconditional vendored literals.
  Falsifier: run the existing gh273 suite against the candidate in a disposable full clone; its alias/flag/version and unscoped cases must retain their verdicts. A driver-filename-only pre-gate must lose an alias case; record that manual mutation if needed, without adding cases to the suite.

- [Should] **F2 / Q2 — Require nonempty, status-aware green AND red parity** (plan:16,52,73–74,85–88). `diff <(bash old) <(bash new)` checks only stdout and does not propagate either audit exit status; two crashing audits with matching output can satisfy it. Capture stdout, stderr and exit status separately, require nonempty expected audit output, compare both streams and statuses on the same tree, and keep timing stderr separate from diagnostic stderr. Name the existing gh273 suite explicitly as covering verification. Cheapest red witness: in a disposable clone temporarily append an unscoped direct Python driver line to an existing test script, outside any 40-line safe-scoping lookback (e.g. pad with comments); never execute that script. Both audits must exit 1 and name that exact unsafe line. Restore the saved bytes. Preserve this evidence with provenance in the already named evidence directory. No new fixture file or suite is needed.
  Observed input: the current baseline artifact cited in the Producer block is empty. Probe `python3 -c 'from pathlib import Path; p=Path("TESTS-RESULTS/2026-10-17+GH-1112/audit-before.time"); print(p.stat().st_size)'` is the minimal equivalent of the read-only inventory probe run this turn (exit 0; decisive output: `TESTS-RESULTS/2026-10-17+GH-1112/audit-before.time 0`). No local timing/output baseline is established by that file.
  Affected scope: rebuilt audit parity, performance evidence and fix-probe verdicts; the historical 111.52→4.78 s report is historical evidence, not this candidate measurement.
  Falsifier: an audit replaced by an immediate nonzero exit must fail acceptance even if both captures are empty; the planted unsafe invocation must produce matching rc=1 and nonempty FAIL diagnostics on old/new. The timing probe must reject a slow audit and an audit that exits nonzero, rather than merely finding the word `real`.

- [Should] **F3 / Q4 — Correct EPERM inference and specify the group-oracle control** (plan:42–46,54,75–76). Catching PermissionError in cleanup prevents a cleanup error masking the original verdict. At the observation site, however, the proposed tuple immediately sets `group_absent=True` and breaks (gh648:148–151), so the deadline at :152–154 does NOT protect an EPERM case. Permission denial alone does not establish pgid reuse or absence. Label reuse as a hypothesis unless corroborated; explicitly document the chosen policy that an unsignalable group is outside this fixture oracle, and its limitation, or provide ownership evidence before treating it as gone. Do not claim unconditional leak detection from this two-line change. For the requested red control, temporarily replace only observation `os.killpg(proc.pid, 0)` with a no-op in a disposable copy: the normal run must reach `process group remains` and fail; restore bytes afterward. Separately inject PermissionError at each site to witness the intended handling. These are recorded manual controls, not new committed assertions. The existing no-kill mutation is useful but insufficient for this branch: it is rejected by `cap containment` at :139 and explicitly expects that error at :174, before the group check.
  Observed input: gh648:148–154 observation/deadline sequence and :171–178 existing mutant acceptance; plan:76 claims the deadline covers the permission-denied path despite the proposed earlier break.
  Affected scope: the two killpg exception handlers and the claims made about owned descendants versus unknown/unsignalable groups.
  Falsifier: an observation returning normally forever must fail at the deadline; ProcessLookupError must pass; injected PermissionError must follow the explicitly documented policy without being described as proof of absence. Full execution remains [Unverified — needs clone run].

- [Pass] **Q3 / Q6 — Keep the list edit and existing runner** (`validate.sh:1106–1117,1254,1294–1311,1405–1424`; `ci-local.sh:267–270`). All three heavy suites are pooled, so moving entries advances their dispatch. It ALSO changes sequential execution order and `--list` output order; say “same sequential runner and suite set,” rather than implying identical order. Tier-2 execution order comes from T2_TESTS, not TESTS. Mode selection is independent of registry order (:935–1047). The inspected gh544/gh35/gh141/gh306 checks concern mode/membership/set comparisons; no order pin was found in those inspected checks. This does not prove absence across every suite. Static extraction probe (Python regex over the nonempty TESTS block, exit 0) returned `registry_count 406 unique 406`, heavy positions `354,363,404`. Preserve the exact multiset (406 unique entries), not just its count. Its red control can be a manual comparison against the old ordering (must reject late heavy entries) plus a dropped/duplicated-entry mutation (must reject membership drift). No scheduler, lane, routing or receipt changes are needed.

- [Nit] **Q5 — Ratings are recorded judgments, and #1114 is a cross-track association.** `releases.sql:3675,3677` records the two exact ratings. Their developer-time/flake rationale is reasonable, but effort cheapness for gh648 depends on resolving F3. Read-only `gh issue view 1114 --repo HiQS-Labs/XYZ-forge --json number,title,body` (exit 0) identifies the original subject as bookkeeping requalification, not gh648; #1118 explicitly groups parallel work and pre-measurement hygiene there. Cite #1118 as the gh648 authorization and mark this as a partial hygiene item; do not close #1114 or imply its bookkeeping/receipt work is delivered by this PR. A new issue is unnecessary for this already authorized hygiene slice.

- [Pass] **Whole-file sweep / scope limits:** pre-existing limitations are visible: audit safety is lexical (`test/marathon-root-audit.sh:267–268`) and raw `MARATHON_ROOT=` is accepted in some branches (:312–314,352–353); the runner counts rescued failures as passed (:1355–1362) and emits the existing receipt at :1584–1587. Preserve those rules for byte parity; the receipt issue is explicitly excluded by plan:59–60 and tracked on #1118. No additional demonstrated defect requiring this quick-win plan to expand was established. Reversibility is Easy for three independent edits; the significant bet is semantic preservation, with F2 supplying its falsifier. Historical speedups and the new candidate runtime remain [Unverified — needs clone run].

Handing off to Producer (claude-a) — disposition F1–F3, tighten the plan and return it for review. No source/artifact edits were made by this reviewer.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
