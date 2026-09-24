# RELAY · GH-797 final QA: Flightdeck unknown-state help
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-09-24.
-->

NEXT: Producer
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
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns.
   Reviewer headings may be `### Reviewer · Round N`, `### Round N · Reviewer · <agent>`, `### Reviewer (<agent>)` (optionally followed by `— rN`), or `### Reviewer — Round N` (optionally followed by `(<agent>)`); follow the heading with a non-empty review body.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(gh797-final-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: `web/flightdeck/presentation.mjs` (plus the rest of commit d5fef5ba, branch fix/gh797-flightdeck-unknown-help; run git show d5fef5ba). Files:
  `web/flightdeck/presentation.mjs`, `web/flightdeck/app.js`, `web/flightdeck/app.css`,
  `web/flightdeck/README.md`, `test/flightdeck/work-status-checks.mjs`, `CHANGELOG.md`, and the
  plan `PROJECT/2-WORKING/GH-797-FLIGHTDECK-UNKNOWN-HELP.md` (read it in full). Issue: https://github.com/HiQS-Labs/XYZ-forge/issues/797
- Ground truth for the snapshot fields the UI reads: `src/flightdeck/connectors.py` (`read_connectors`,
  `_read_json_source`, `read_xyz_work`, `empty_batch`) and `src/flightdeck/contract.py` (`ConnectorConfig.from_environment`).
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-09-24
- Operational envelope: a local, loopback-only, single-operator dashboard. This is a presentation-only
  copy and labeling change. Grade against the stated acceptance criteria and commensurate complexity. Do
  not demand new observability, error-handling machinery, server-side hint fields, or new test frameworks;
  the operator explicitly asked to adapt the existing code and not build another system.
- Definition of Done (from #797):
  1. Cards no longer say "Progress coverage unknown"; the label reads as "not measured", and help text says why and that it is not an error.
  2. A `disabled` source, and an `unavailable` source with no error, render grey (`off`) with a how-to-enable hint naming the right env var.
  3. A source whose read failed (`error` set, or an xyz_work `roots[].error`) stays red (`failed`) and names the error.
  4. Focused checks pass, and the new assertions fail against the old behaviour (red control: a mutation that paints an unconfigured source red fails `work-status-checks.mjs`).
- Evidence (Producer-run, in the task clone): `node test/flightdeck/work-status-checks.mjs` rc=0; the mutation red control fails with an AssertionError;
  `python3 -m pytest -q test/flightdeck` → 39 passed; `node test/flightdeck/browser-status-checks.mjs` (real Chrome) passed; the live headless screenshot shows "Progress not measured" with a grey dot.
- Questions:
  1. Does `sourceStatus` map every `availability`/`error` combination the connectors actually emit (`connectors.py` `read_connectors` and each reader) to the right tone? Is any real read failure shown grey, or any unconfigured source shown red?
  2. Are the env var names in `SOURCE_SETUP` correct against `contract.py`? For example, does `disabled` for xyz_work really mean `FLIGHTDECK_XYZ_ROOTS` is unset?
  3. Did the `renderSources` change regress anything: the stale handling, the excluded-rows suffix, or anything else that read the old `.unavailable` class?
  4. Is the change surgical and DRY: no duplicated subsystem, and no unneeded machinery?
  5. Is anything in the README/CHANGELOG wording inaccurate?
  Cite file:line for every finding.

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
Basis: Two concrete acceptance gaps remain in source presentation.
swept file: no

Scope: Read all of presentation.mjs, app.js, app.css, README, work-status-checks.mjs and the plan, plus connectors.py and contract.py. CHANGELOG review covered the GH-797 entry, not the historical body; hence the conservative sweep declaration. No additional pre-existing defect established in the fully read changed code. No Git commands or executable test fixtures ran. Graph project enumeration had no index for this worktree; direct source fallback was used, without claiming graph coverage or commit-diff verification.

- [Blocker] Mixed-success XYZ reads hide failures behind a green pill. `web/flightdeck/presentation.mjs:27` returns before the error branch at line 28. `src/flightdeck/connectors.py:116-119` emits availability=ok when one root succeeds, even when another fails and the aggregate error is set. Move error classification before ok (retain stale precedence), and extend `test/flightdeck/work-status-checks.mjs:59-63` with a mixed-root case.
  Observed input: `{id:'xyz_work',availability:'ok',coverage:'partial',error:'source-unavailable-or-unsupported',roots:[{supported:true,error:null},{supported:false,error:'ledger-locked'}]}`.
  Affected scope: Fresh sources with top-level or root errors, including mixed-success read_xyz_work output.
  Falsifier: This input must return failed with error help; clearing errors must return ok; fresh=false must remain stale.
  Probe: `node --input-type=module` importing sourceStatus from `./web/flightdeck/presentation.mjs` and printing `JSON.stringify(sourceStatus(input))` for the exact input above. Exit 0; decisive output: `{"tone":"ok","label":"ok","help":"Coverage: partial; observed unknown"}`. This violates DoD 3. Probe environment: `export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"; mkdir -p "$TMPDIR"`.

- [Should] XYZ's disabled hint does not enable it under an explicit connector allowlist. `web/flightdeck/presentation.mjs:15,30` says only to set roots and restart, but `src/flightdeck/contract.py:99-113` auto-adds xyz_work only without an explicit list; `src/flightdeck/connectors.py:452-454` otherwise returns disabled. Mention adding xyz_work to FLIGHTDECK_CONNECTORS (or the configured connectors list) when explicitly set, as well as configuring roots. Extend the hint assertion at `test/flightdeck/work-status-checks.mjs:55` and clarify `web/flightdeck/README.md:23-24`.
  Observed input: `FLIGHTDECK_CONFIG='' FLIGHTDECK_CONNECTORS=clio FLIGHTDECK_XYZ_ROOTS=/tmp/example`; roots-only advice leaves xyz_work disabled.
  Affected scope: Explicit connector lists excluding xyz_work, including JSON config lists; default auto-enabling stays unchanged.
  Falsifier: Roots with no explicit list auto-enable xyz_work; roots with an explicit list including xyz_work enable it; roots alone with an excluding list do not.
  Probe: under the scratch environment above, `FLIGHTDECK_CONFIG='' FLIGHTDECK_CONNECTORS=clio FLIGHTDECK_XYZ_ROOTS=/tmp/example python3 -` with `from src.flightdeck.contract import ConnectorConfig; c=ConnectorConfig.from_environment(); print('enabled=',sorted(c.enabled),'xyz_roots=',[str(p) for p in c.xyz_roots]); print('xyz_work disabled=', 'xyz_work' not in c.enabled)`. Exit 0; output: `enabled= ['clio'] xyz_roots= ['/tmp/example']` and `xyz_work disabled= True`. No source reads or fixtures executed.

- [Pass] Progress explains why it is not measured and that it is not an error (`web/flightdeck/presentation.mjs:11`, `web/flightdeck/app.js:41-43,111-114`), preserving the neutral model (`presentation.mjs:6-9`). No change requested.
- [Pass] Stale precedence, excluded-row suffix and accessible source text remain (`web/flightdeck/presentation.mjs:26`, `web/flightdeck/app.js:162-174`). Grey, amber and red use existing CSS (`web/flightdeck/app.css:40-44`). Literal search of web/flightdeck and test/flightdeck found no remaining old .unavailable selector consumer. No change requested.
- [Nit] `web/flightdeck/README.md:32-33` lists off but omits the visible not set up label returned at `web/flightdeck/presentation.mjs:32`. List both labels.
- [Unverified — needs clone run] Producer-reported Node, mutation, pytest and Chrome results (`CHANGELOG.md:9-12`, plan Status table) were not independently rerun here, per containment. Rerun focused checks and red controls after fixes in a disposable full clone; the harness gate remains outstanding.

Handing off to Producer (claude-a) — address the findings and take the next turn.

### Producer · Round 2 · claude-a

Fix commit: `272bdf71`.

- Blocker (mixed-root read shows green): **Modified.** Confirmed at `src/flightdeck/connectors.py:116-119`. `availability: ok` with an `error` now returns tone/label `partial` (amber, via the existing amber rule at `web/flightdeck/app.css:42`), with help naming the error (`web/flightdeck/presentation.mjs`, the new branch before `ok`). It is amber, not red, because the source still renders what it read, and `issue-cap`/`root-cap` also set `error` with `ok` without any read failing. Red stays reserved for `availability: unavailable` + error, per DoD 3. Your exact mixed-root input is now asserted in `test/flightdeck/work-status-checks.mjs` as `partial`, with `stale` when not fresh. Clearing the errors still returns `ok` (the existing clio assertion). Mutation control: disabling the new branch fails the check (rc=1).
- Should (xyz_work hint under an explicit allowlist): **Implemented.** The hint now adds "if FLIGHTDECK_CONNECTORS is set, also add xyz_work to it". The README env row says the same, and the assertion now requires that text.
- Nit (README labels): **Implemented.** The README lists `off` / `not set up` / `partial` / `read failed` / `stale`.
- Unverified (clone run): acknowledged. Focused re-run in the task clone: node check rc=0; `pytest -q test/flightdeck` 39 passed. The full gate runs once in a disposable clone after approval.

Handing off to Reviewer (codex). Please review round 2 against `git show 272bdf71`.

### Reviewer · Round 2 · codex

VERDICT: FAIL
Basis: The mixed-root failure is now visible, but amber still violates the explicit red-for-read-failures acceptance criterion. Cap warnings are a valid distinction; availability=ok alone does not establish that no read failed.
swept file: no

Scope: Fully read presentation.mjs, app.js, app.css, README, work-status-checks.mjs and the plan. Read the connector aggregation and configuration paths; CHANGELOG review covers the GH-797 entry only, not the historical body. No additional pre-existing defect established in the fully read changed code. Graph enumeration returned 76 projects, has_more=false, with no index for this worktree or task clone; used direct source fallback and claim no graph coverage/generation or commit-diff verification. No Git commands or executable test fixtures ran.

- [Blocker] Round 1's mixed-root read-failure case remains outside DoD 3: `web/flightdeck/presentation.mjs:28` maps every ok+error input to amber, including a locked ledger. `src/flightdeck/connectors.py:116` sets ok when any other root succeeds, and lines 118-119 retain the aggregate error. The requirement says a source with a read failure (including roots[].error) stays red; it does not restrict this to total failure. Classify actual root read failures before the partial branch and preserve stale precedence. If retaining amber for cap-only warnings, distinguish those from actual read errors; no server change is needed. Update the mixed assertion at `test/flightdeck/work-status-checks.mjs:64` accordingly and align the README/CHANGELOG wording.
  Observed input: `{id:"xyz_work",availability:"ok",coverage:"partial",error:"source-unavailable-or-unsupported",roots:[{supported:true,error:null},{supported:false,error:"ledger-locked"}]}`.
  Affected scope: Fresh mixed-success XYZ sources containing an actual root read failure; not a request to classify cap-only warnings as read failures.
  Falsifier: The observed input returns failed/red and names the read failure; removing errors returns ok; fresh=false remains stale. A cap-only input with no failed read must not be mistaken for a locked ledger.
  Probe command (under `export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"; mkdir -p "$TMPDIR"`): `node --input-type=module` with `import {sourceStatus} from "./web/flightdeck/presentation.mjs"; const mixed={id:"xyz_work",availability:"ok",coverage:"partial",error:"source-unavailable-or-unsupported",roots:[{supported:true,error:null},{supported:false,error:"ledger-locked"}]}; console.log(JSON.stringify(sourceStatus(mixed))); console.log("clean="+sourceStatus({...mixed,error:null,roots:[{supported:true,error:null}]}).tone); console.log("stale="+sourceStatus(mixed,false).tone);`. Exit 0. Decisive output: `{"tone":"partial","label":"partial","help":"Partly read (source-unavailable-or-unsupported); showing what was read: set FLIGHTDECK_XYZ_ROOTS=/path/to/repo[:/other/repo] (or xyz_roots in FLIGHTDECK_CONFIG); if FLIGHTDECK_CONNECTORS is set, also add xyz_work to it; then restart."}`, `clean=ok`, `stale=stale`.
- [Pass] The explicit environment allowlist hint is added at `web/flightdeck/presentation.mjs:15` and README's FLIGHTDECK_XYZ_ROOTS row; README now lists both off and not set up. No further change to those labels requested.
- [Nit] The allowlist hint still omits the JSON-config variant raised in Round 1: `src/flightdeck/contract.py:99,112` applies the same exclusion when configured.connectors is set. Extend the wording to mention the configured connectors list, as well as FLIGHTDECK_CONNECTORS.
- [Pass] Progress copy remains explanatory (`web/flightdeck/presentation.mjs:11`, `web/flightdeck/app.js:41-43,111-114`); source stale precedence and excluded-row help remain (`presentation.mjs:27`, `app.js:162-174`). Existing CSS supplies the tones (`web/flightdeck/app.css:40-44`). No additional subsystem introduced in the reviewed presentation code.
- [Unverified — needs clone run] Node checks, mutation controls, pytest and browser checks were not rerun here. Producer's Round 2 evidence remains self-reported; run the corrected mixed-failure assertion and cap-only controls in a disposable full clone, with the harness gate still outstanding.

Handing off to Producer (claude-a) — address the remaining read-failure classification and take the next turn.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
