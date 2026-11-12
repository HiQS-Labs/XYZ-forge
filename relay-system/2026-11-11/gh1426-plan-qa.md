# RELAY · GH-1426 plan QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-11-11.
-->

NEXT: Reviewer
STATUS: Open
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
6. **Commit only the relay file** (`relay(gh1426-plan-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: `PROJECT/2-WORKING/GH-1426-JOG-DRYRUN-TARGET-READINESS.md` (sections `## Recon`, `## Plan`, `## Acceptance`). This is a **plan review**: no production code has been written yet.
- Reviewer: codex   ·   Producer: claude
- Started: 2026-11-11
- Operational envelope: a local developer CLI (`releases_app.py jog run`), one operator, one file changed (`utils/py/jog_run.py`). Grade against the issue's acceptance and commensurate complexity. Do not grade against enterprise or multi-tenant threat models. The repo forbids new tests, suites, registry entries or gate machinery (`AGENTS.md` "No new tests", GH-831). Verification uses existing suites plus manual checks under `TESTS-RESULTS/`. Asking for a new test is out of scope.
- Out of scope: sibling issues #1427 (claude-turn ceilings) and #1428 (reviewer gate / codex sandbox).

### Step A: paraphrase first (GH-1414). Do this BEFORE reading anything else.
Read ONLY `## Status`, `## Recon`, `## Plan` (with its sub-sections) and the plan doc's own
`## Acceptance` / `## Non-goals`. Do not open source files or the issue yet. Then, at the top of your
review block, write:
- **What this proposes** (2–5 sentences)
- **How the existing system works, per this document** (2–5 sentences)
- **What it's not** (short; ground exclusions in the doc's sections and label any inference)
- **Input boundary:** list which sections you had read when you wrote the paraphrase.

### Step B: source-backed technical validation
Now read the requirements and source:
- Issue: https://github.com/HiQS-Labs/XYZ-forge/issues/1426 (the same text is in the doc's Symptom / Observed / Acceptance sections)
- `utils/py/jog_run.py` (in particular 530-610 `_execution_root` / `run_marathon_phase`, 2163-2463 `jog_run_main`)
- `utils/py/swarm_preflight.py` (1166-1250 arg parsing + doc lookup, 1300-1350 fetch/freshness, 1585-1600 gate check, 1640-1735 verdict/dry-run exit)
- `utils/py/harness_paths.py:177` `require_primary`; `skills/2-daily/jog/SKILL.md:72-90,130-145`
- Tests that pin touched text: `test/jog-queue.sh:170-185`, `test/gh280-jog-marathon-adapter.sh:597-601,703-712,795-803`

Label this part **Source-backed assessment**. Questions:
1. Are the recon claims (line refs, behaviours) grounded in the actual code? Cite any claim that is wrong.
2. Does dry-run with `--target-root` stay free of ledger writes and locks? Are there writes in the dry-run preflight path that the plan misses (e.g. the `rtl_transcript_root` shell-out when `--out` is unset, the `git fetch`, `gh` calls)? Is skipping `_require_jog_primary` in dry-run consistent with SKILL.md:141?
3. Is the 1-INBOX → `--project-doc` substitution a faithful approximation of what a live run would evaluate after promotion? Or does `--project-doc` mode diverge in a way that would make the dry-run verdict wrong (slug, acceptance source, issue-state, etc.)?
4. Is `_preflight_summary`'s parsing robust to every exit path in preflight (0, 4, 5, 6, 7, die exit 2, contract error exit 3), and does it never yield an empty string?
5. Will the existing suites (I7, G8, jog-queue case 12) stay green under the plan without edits? Does any other consumer (docs, skills, scripts) parse `advancing halted at landing boundary`, `marathon execution`, or the `preflight-refused (exit N): …` reason?
6. Is it surgical and DRY: extends the existing writer and preflight, with no parallel subsystem? Flag over- or under-building. Is changing the halt line for *all* parked actions (not just preflight) correct, or should landing parks keep the old text?
7. Is any acceptance criterion from the issue unmapped, or is a red control unable to fail?

Write graded findings (`[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`) with file:line. Behaviour-change requests carry `Observed input:` / `Affected scope:` / `Falsifier:`. VERDICT PASS → set `STATUS: Approved`.
- Definition of Done: the plan maps every issue acceptance criterion to a falsifiable check, its recon is grounded, it stays read-only in dry-run, and it extends existing code without a parallel subsystem or new tests.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer · Round 1

**What this proposes:** Reuse existing preflight in target-root dry-runs to report readiness per pending item, then preserve its diagnostic in live park messages. Extract shared lookup/target-validation/summary helpers in jog_run.py and retain queue-only output without a target.

**How the existing system works, per this document:** Dry-run currently reads the queue without inspecting the target or requiring a primary pin. Live execution validates a separate clone, promotes inbox docs, creates an execution record, then invokes preflight; its current last-line summary drops the readiness cause and its generic halt message mislabels preflight parks.

**What it's not:** No clone bootstrapping, readiness-rule changes, dry-run promotion, new suites, or work on #1427/#1428 (Plan/Non-goals).

**Input boundary:** Read Status, Recon (including its base-qualified heading), Plan and all subsections, Acceptance, and Non-goals before source/issue inspection. Relay instructions and ROUTER were also read; no source or issue had been opened.

**Source-backed assessment**

swept file: yes

- [Should] **The dry-run side-effect contract is incomplete.** Plan lines 132–134 say the only side effect is fetch, but `swarm_preflight.py:1365–1391` creates/removes/prunes registered worktrees, and `:231–235` executes arbitrary contract command probes before the dry-run exit at `:1727`. Python imports can also create bytecode unless suppressed. This is existing preflight behavior newly reached by Jog dry-run, not a reason to invent a second readiness engine. Amend Recon/Plan to inventory the actual effects, define “zero locks” as zero Jog supervisor locks/leases (fetch/worktree operations use Git locks), and explicitly bound the read-only claim for command probes. Pin bytecode suppression for the child and record a manual before/after check of both ledgers, Jog state, tracked/untracked files and worktree registrations. If literal zero mutation remains required, the proposed invocation does not satisfy it; resolve that contract before implementation.
  Observed input: `PROJECT/1-INBOX/GH-1171-BRANCH-ARTIFACT-PREFLIGHT.md:59–62` declares a command probe invoking `python3 TESTS-RESULTS/2026-11-11+GH-1171/manual_probe.py`; preflight executes command probes without a dry-run guard (`swarm_preflight.py:231–235,1374`). Plan Step 2 invokes this same path for inbox candidates.
  Affected scope: target-root dry-runs that reach ref evaluation, especially contracts with command probes; no-target queue listing stays unchanged.
  Falsifier: a manual ready-target run with a command probe that writes a marker to a supplied external scratch path; strict read-only semantics require the marker absent. If normal preflight probe execution is deliberately retained, document the marker as an allowed effect instead of claiming read-only execution. Run this only in the disposable clone.

- [Should] **Supply a non-created `--out` path for the dry-run child and account for post-verdict failures.** Step 2 omits `--out`, unlike the live call (`jog_run.py:598`). After printing READY, preflight resolves the archive through a shell-out (`swarm_preflight.py:1715–1721`); an invalid `XYZ_ARCHIVE_ROOT` exits 1 even though live's explicit output path bypasses it. `rtl_transcript_root` itself is read-only (`relay-turn-lib.sh:134–159`), but this extra dependency makes parity false. Specify an explicit prospective output path without creating it, and require `_preflight_summary` not to report an unqualified ready verdict if a later process error contradicts it. Add this case to existing manual checks, not a new suite.
  Observed input: `XYZ_ARCHIVE_ROOT=relative` with an otherwise ready target and Step 2's no-`--out` invocation; `relay-turn-lib.sh:144–146` returns 1, and `swarm_preflight.py:1719–1720` exits 1 after the verdict line. The real Jog invocation supplies `--out`.
  Affected scope: ready dry-run candidates with archive resolution failure; summary inputs with a printed verdict and a contradictory process return code.
  Falsifier: in a disposable clone, ready live-equivalent preflight with explicit `--out` and ready dry-run with the planned explicit `--out`, both under `XYZ_ARCHIVE_ROOT=relative`, must return 0; a synthetic completed process containing `verdict : ready (exit 0)` but returncode 1 must not summarize as unqualified ready.

- [Should] **Repair the plan's existing executable contract.** Whole-file sweep found `PROJECT/2-WORKING/GH-1426-JOG-DRYRUN-TARGET-READINESS.md:222–226` has a string `target`, a descriptive non-command gate, and unsupported probe type `grep`. This is pre-existing but in the reviewed artifact. Use the existing object target schema, a real focused gate command, and a supported, discriminating probe; the retained legacy landing string makes a blanket absence probe wrong.
  Observed input: the exact contract at lines 222–226. Read-only probe command: `PYTHONDONTWRITEBYTECODE=1 python3 -B` importing `extract_contract` from `utils/py` and calling `extract_contract('PROJECT/2-WORKING/GH-1426-JOG-DRYRUN-TARGET-READINESS.md')`; exit **3**, output: `contract in PROJECT/2-WORKING/GH-1426-JOG-DRYRUN-TARGET-READINESS.md missing required field: target` and `extract_contract exit: 3`. No fixture or executable test ran.
  Affected scope: this plan's own preflight contract, not production readiness rules.
  Falsifier: the corrected contract parses successfully; its probe distinguishes the specific preflight diagnostic fix before/after while allowing the intentionally retained legacy landing message.

- [Pass] Core recon and surgical approach are grounded: dry-run precedes primary validation (`jog_run.py:2221–2243`), and `SKILL.md:141` explicitly exempts read-only dry-run from the pin. Reusing target validation and existing preflight avoids parallel readiness rules. Changing every marathon park halt is appropriate because the reason retains awaiting-landing information (`jog_run.py:2374–2395`); legacy landing remains separately handled at `:2453`.
- [Pass] Inbox substitution preserves basename-derived slug (`swarm_preflight.py:1285–1288`) and checklist source (`:1509–1514`); issue fidelity/state use frontmatter in project-doc mode (`:1494–1504`). Promotion preserves basename and acceptance content (`jog_run.py:1638–1677`). This is an approximation of post-promotion preflight, not proof promotion itself succeeds: the existing unattended probe-validation refusal at `:1687–1691` remains separate. The plan should describe that qualification and require matching `gh_issue` identity for this substitution rather than silently evaluating a different issue.
- [Pass] Summary fallback design covers printed verdicts 0/4/5/6/7, early BLOCKED/CONTRACT ERROR, die's stderr prefix, and empty output via `exit N` (`swarm_preflight.py:43–45,1256–1278,1649–1655,1704–1713`). It must inspect stdout and stderr together; post-verdict return-code handling is the finding above.
- [Pass] Static consumer search found G8's prefix assertion (`test/gh280-jog-marathon-adapter.sh:710`) compatible with the proposed suffix, I7's substring/no-notice/pending assertions (`:795–803`) compatible with added target output, and no-target case 12 (`test/jog-queue.sh:172–185`) compatible with the untouched branch. No other parser of the changed halt/execution strings was found in skills/docs/utils/test. **[Unverified — needs clone run]** Actual suite success is deferred to the harness/disposable full clone; no suites ran here.
- [Pass] All five Acceptance bullets map to R1/R2/R3 or existing suites (`plan:155–168,210–216`), with pre-fix controls capable of failing. Extend the manual matrix for the side-effect and archive cases above; no new test machinery is needed.

**VERDICT: FAIL**

**Basis:** The small shared-helper/message change is sound, but Step 2's claimed effect boundary and live parity are not yet accurate, and the artifact's existing contract fails its parser. Resolve the three Should findings before implementation. No source or artifact was edited; only this relay file changed.

Handing off to Producer (claude-a) — amend the plan and disposition these findings, then request the next review turn.

### Producer · Round 1 → 2 (claude)

Dispositions (plan amended in `PROJECT/2-WORKING/GH-1426-JOG-DRYRUN-TARGET-READINESS.md`):

- **[Should] Dry-run side-effect contract incomplete: Implemented (Modified).** Recon now lists preflight's real effects in the target: fetch, transient ref worktree add/remove/prune (1365-1391), and contract `command` probes (231-235). Step 2 adds an explicit **Effect contract**: no primary ledger write, no `.tick/jog` state, no Jog lock or lease, no packet. Target-side preflight operations are accepted as documented effects, identical to a manual `swarm-preflight.sh --dry-run`, and the plan no longer calls them "read-only". The child runs with `PYTHONDONTWRITEBYTECODE=1`. R1 now records before/after for both primary ledger files, `.tick/jog`, `git status --porcelain` in both clones, and `git worktree list` in the target. Not adopted: the external-marker command-probe run. Your falsifier allows documenting probe execution as an allowed effect, and the plan now does that. Disposition for the marker run: Rejected (Out of Scope / Ponytail).
- **[Should] Missing `--out` / post-verdict failure: Implemented.** The dry-run child passes `--out <prospective never-created temp path>`, which matches live and bypasses the `rtl_transcript_root` shell-out (1715-1721). `_preflight_summary` appends `; preflight exited <rc>: <last line>` when the return code differs from the verdict's `(exit K)`. New manual check R4 covers the synthetic `ready (exit 0)`/rc 1 case and the empty-output case. No new suite.
- **[Should] Plan's own contract does not parse: Implemented.** It now has an object `target`, a real gate (`bash test/gh280-jog-marathon-adapter.sh && bash test/jog-queue.sh`) and a `grep_absent` probe on `def _preflight_summary\(` that discriminates before from after. Read-back: `extract_contract(...)` now returns that gate and probe, exit 0.
- **[Pass] notes:** the 1-INBOX substitution is now worded as an approximation that does not prove promotion succeeds (probe-lint refusal at `jog_run.py:1687-1691` remains separate). Identity comes from `find_issue_doc`, the canonical `wave_reconcile` resolver. Summary parsing reads stdout and stderr together.

Pre-fix red controls are already captured in a disposable fixture (primary + target clones, isolated `GIT_CONFIG_GLOBAL`). R1 pre: `would process 2 pending item(s)`, no reason, rc 0. R2 pre: the exact four-line console from the issue, with the row reason `preflight-refused (exit 5): No packet written — …`.

Handing off to Reviewer (codex): re-review the amended plan and approve, or list the remaining findings.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
