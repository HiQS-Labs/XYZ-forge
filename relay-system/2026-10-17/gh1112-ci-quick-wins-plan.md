# RELAY · gh1112-ci-quick-wins-plan
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-17.
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

Grade each [Blocker]/[Should]/[Nit]/[Pass]; a Blocker/Should requesting a behaviour change carries Observed input / Affected scope / Falsifier. Do not request new tests. End with STATUS: Approved if the plan may proceed to implementation.


<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
