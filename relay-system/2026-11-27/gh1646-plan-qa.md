# RELAY · GH-1646 plan QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-11-27.
-->

NEXT: Producer
STATUS: Escalated
ROUND: 4 / 4

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
     change MUST carry `Observed input:`, `Affected scope:` (the input predicate the change would govern),
     and `Falsifier:` (the fixture or data that would show the change unnecessary or wrong, and its expected
     result). `Observed input:` accepts two strict, non-speculative forms:
     (1) **Form 1 (observed failure or artifact contradiction):** a failing probe/gate output, or a concrete
     `fileA:line` vs `fileB:line` contradiction (e.g. IAM SA mismatch, inverted test, sibling guard omission);
     (2) **Form 2 (unrunnable runtime hazard trace):** permitted ONLY when reproduction requires an external
     service, multi-process concurrency, or a browser/container runtime forbidden in the relay worktree —
     must supply a hop-by-hop `file:line` trace plus an exact `Clone probe:` command/script for the Producer's
     disposable full clone. Default severity for an unexecuted Form 2 hazard is `[Should]`.
     A `[Blocker]` must cite an observed failure (Form 1); an unexecuted Form 2 hazard stays `[Should]`
     until a probe reproduces it, and remains pending probe verification until the Producer runs
     `Clone probe:` in a disposable full clone.
     A finding from an earlier round stays open, and the verdict stays failing, until new evidence closes it.
     This includes earlier [Nit] findings; only a newly raised [Nit] with VERDICT: PASS on STATUS: Approved remains optional.
     This is a protocol rule, not a mechanical check —
     the Producer may disposition a request lacking Form 1 evidence and lacking a complete Form 2 trace + `Clone probe:` as `Declined — unproven generalization`.
   - **Producer:** log a disposition for every open finding (Implemented / Modified / Declined + why,
     including `Declined — unproven generalization` for a behaviour-change request lacking Form 1 evidence and
     lacking a complete Form 2 trace + `Observed input:` / `Affected scope:` / `Falsifier:` / `Clone probe:`).
     For every Form 2 `Clone probe:` finding, read the probe before running it — refuse any probe that reaches
     the network, credentials, or paths outside the disposable clone and record the refusal as
     `[Unverified — clone probe failed/unavailable]` — then execute safe probes in a disposable full clone and
     record one of three outcomes: (a) Reproduced → fix and paste failing-before / passing-after probe output;
     (b) Falsified → `Declined — falsified by clone probe: <cmd → exit + output>`; (c) Errored, refused, or
     environment unavailable → keep the finding OPEN (`[Unverified — clone probe failed/unavailable]`, blocking
     `STATUS: Approved` until re-run cleanly or escalated/parked). Make approved changes, then add new work.
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
   Reviewer headings may be `### Reviewer · Round N`, `### Round N · Reviewer · <agent>`, `### Reviewer (<agent>)` (optionally followed by `— rN`), or `### Reviewer — Round N` (optionally followed by `(<agent>)`); follow the heading with a non-empty review body.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Manual relay: commit only the relay file** (`relay(gh1646-plan-qa): <role> r<N>`); no push.
   **Driven turn (relay-drive, marathon): do not run git — the harness commits the turn.** **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. (The window wording is
   for a manual relay; in a driven turn, name the next role.) The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: `PROJECT/2-WORKING/GH-1646-PLAIN-BULLET-ACCEPTANCE.md` (the plan). Plan QA only; no code is written yet.
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-11-27
- Operational envelope: local developer CLI (swarm preflight acceptance-fidelity check). Grade against the
  issue's requirements and commensurate complexity. XYZ-forge forbids new test suites (AGENTS.md, GH-831):
  the plan adds one case to the existing `test/gh400-acceptance-fidelity.sh`.
- **Paraphrase first (GH-1414).** Before reading any other file, read ONLY the plan doc and write 2–5
  sentences each under **What this proposes** and **How the existing system works, per this document**, plus
  a short **What it's not**. Label inference. Then read the sources below for a source-backed assessment.
- Requirements (issue #1646, verbatim intent): `extract_acceptance_criteria` collects only checkbox bullets
  (`ACC_BULLET_RE`, `utils/py/swarm_preflight.py:576`), so an issue whose `## Acceptance` uses plain `- `
  bullets parses as present-but-empty and a verbatim checkbox copy reads `diverged` (exit 5). Plain `-`/`*`
  bullets under that heading must count as criteria on the issue side without breaking checkbox parsing,
  the deviations heading, nested bullets, or horizontal rules; keep the None (no section) vs [] (empty
  section) distinction. Smallest change in the existing parser.
- Sources: `utils/py/swarm_preflight.py:569-635` (regexes + `extract_acceptance_criteria`), `:793-842`
  (`collect_inline_checklist`), `:935-1064` (`check_acceptance_fidelity`); `test/gh400-acceptance-fidelity.sh`;
  `test/gh557-unknown-blocks-manifest.sh`; real case `PROJECT/3-COMPLETED/GH-792-GEN4-SANDBOX-DISJOINT-FIRST.md`.
- Definition of Done / questions:
  1. Are the plan's claims grounded in the cited paths (callers, doc-side vs issue-side use)?
  2. What prevents the unfixed parser from being reported as delivered — is the planned gh400 case red on the
     current code, and is the negative control (dropped criterion still `diverged`) meaningful?
  3. Is "fallback only when the section has no checkbox criterion" correct for mixed/nested shapes? Name a
     concrete issue body where it gives the wrong answer, if any.
  4. Is limiting the change to the issue side right, given `collect_inline_checklist` is checkbox-only?
  5. Any edge the plain regex mishandles (HR `- - -`, `**bold**` lines, `- [ ]` with empty text, `+` bullets,
     numbered lists)? Is ignoring numbered/`+` lists acceptable scope?
  6. Is anything over-built or missing?

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). In a manual relay, end each turn by committing just this file; no push. In a driven turn the harness commits.

## Log

### Reviewer · Round 1

**What this proposes**

Enable plain dash and asterisk criteria for GitHub issue Acceptance sections. The proposed fallback runs only if the checkbox pass finds zero criteria. It folds deeper bullets into the current criterion.

**How the existing system works, per this document**

Fidelity uses the same extractor for the issue and capture, and the extractor recognizes checkbox criteria. A present plain-only section returns an empty list, so the copied criteria look like additions. The packet inliner also reads capture checkboxes. I infer that checkbox grammar is part of the capture-to-packet contract.

**What it's not**

Scope excludes capture syntax, packet inlining, and alternate headings.

swept file: yes

VERDICT: FAIL

Basis: The plain-only case is sound in isolation. The section-wide fallback still drops a top-level criterion in a mixed list, and it turns #792's documented workaround into a refusal. The proposed regex can also turn an empty task marker into criterion text.

Probe command `PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp" python3 "$PWD/.relay-scratch/tmp/gh1646-plan-probe.py"` exited 0 after asserting the tuples below. It used seeded `check_acceptance_fidelity` with a supplied issue body and a scratch capture. For the proposed behavior it recompiled the same parser loop in memory with the plan's regex and deeper-bullet rule, used that loop only when the checkbox pass returned `[]`, and replaced only the issue call at `utils/py/swarm_preflight.py:985`. Tuples are `(status, dropped, added)`. The #792 body was reconstructed from its capture's verbatim-copy note and three criteria, with no live fetch.

- [Blocker] Count same-level plain issue criteria alongside checkboxes. Extend the issue-side rule to preserve checkbox recognition and fold deeper plain bullets into their parent while retaining plain sibling criteria.
  - Observed input: `"## Acceptance\n- [ ] First\n  - detail\n- Second\n"`. The full capture leaves the nested line intact and writes `- [ ] Second`. With the plan's fallback (`PROJECT/2-WORKING/GH-1646-PLAIN-BULLET-ACCEPTANCE.md:47`), the probe printed `planned mixed/full: ('diverged', [], ['Second'])` and `planned mixed/partial: ('match', [], [])` when the capture omitted Second. The existing checkbox loop folds detail at `utils/py/swarm_preflight.py:628` and skips the unindented Second.
  - Affected scope: Issue Acceptance sections with a plain sibling criterion and a checkbox criterion. A nested plain detail stays part of its parent.
  - Falsifier: With that input, the full copy returns `match`, the partial copy returns `diverged` with `dropped=['Second']`, and the checkbox-only issue with its nested plain detail still returns `match`. Retain those assertions in the focused verification.

- [Blocker] Include the #792 workaround cleanup in the plan's rollout and replay the exact retained capture before cleanup. Remove the explanatory workaround text and three obsolete `[added]` entries in the same landing, retaining the three criteria. Keep stale-deviation enforcement.
  - Observed input: `PROJECT/3-COMPLETED/GH-792-GEN4-SANDBOX-DISJOINT-FIRST.md:34` lists the three verbatim checkboxes. Lines 38–44 add the workaround for the plain issue list, and the readiness receipt shows `match` with three declared deviations at `TESTS-RESULTS/2026-11-27+GH-792/probe-proof/4-prepared-head-github-origin/preflight-792.json:77`. The probe printed `current retained GH-792: ('match', [], []); 0 issue criteria reconciled: 3 deviation(s) declared and accounted for` and `planned retained GH-792: ('diverged', [], []); deviations are declared but the two lists do not differ`. This comes from `utils/py/swarm_preflight.py:1003` through `:1018`. Divergence clears readiness at `:1767` and an otherwise-ready candidate exits 5 at `:1945`.
  - Affected scope: The retained #792 capture and any equivalent legacy declarations made solely to compensate for the old parser.
  - Falsifier: The exact retained capture matches under the amended plan with stale-deviation enforcement intact. If cleaning up the declarations is required, the corresponding green control is the same issue body and the same three checkboxes with the redundant block removed. The probe printed `planned GH-792 without workaround: ('match', [], []); 3/3 criteria copied verbatim from issue #792`.

- [Should] Make the plain matcher reject task markers with variable separator whitespace and skip blank payloads before recording a plain criterion. Test for a task marker before consuming the variable-width separator, or classify the marker after capturing the full trimmed payload.
  - Observed input: With the exact regex at `PROJECT/2-WORKING/GH-1646-PLAIN-BULLET-ACCEPTANCE.md:46`, the probe printed `regex '- [ ]': None`, `regex '-  [ ]': ' [ ]'`, and `planned empty task plus plain criteria: ['[ ]', 'First']` for `"## Acceptance\n-  [ ]\n- First\n"`. The regex gives back a separator space to satisfy the lookahead, and the real checkbox pass drops the empty task at `utils/py/swarm_preflight.py:635`.
  - Affected scope: Plain parsing of issue list entries with extra spaces or tabs before a task marker, and entries with an empty payload.
  - Falsifier: The concrete input yields only `['First']`, a section with only a whitespace-padded empty task yields `[]`, and `*   [x] done` still yields `['done']` through the issue parser.

- [Pass] The planned full-copy case is red on current fidelity and green in the simulation. For `"## Acceptance\n- First\n* Second\n"` the probe printed `current full copy: ('diverged', [], ['First', 'Second'])`, `planned full copy: ('match', [], [])`, and `planned dropped control: ('diverged', ['Second'], [])`. Assert the direction and text of the dropped criterion because the unfixed partial case also says `diverged`, with `added=['First']` and an empty dropped list. Reuse the gh400 helper at `test/gh400-acceptance-fidelity.sh:55`. Its CLI path at `:335`–`:341` separately exercises exit 5.
- [Pass] Keep the change on the issue side. The two reads are at `utils/py/swarm_preflight.py:985` and `:986`. Packet preparation reads the capture at `:1754`–`:1760` and the inliner admits checkbox items at `:826`–`:838`. The nearby canonical checkout's graph showed one inbound caller for the extractor, and the relay checkout's `utils/` and `test/` source search found both calls in fidelity. Graph coverage generation was `2026-11-26T04:31:47Z`. The task docs were missing from that index and the trace call was unavailable under the session's approval settings, so the findings use direct source in the relay checkout.
- [Pass] Keep heading and HR boundaries before bullet classification (`utils/py/swarm_preflight.py:605`–`:623`). Although the candidate regex alone consumes `- - -`, the probe returned `['First']` from a list terminated by that line. It also returned `['First']` when a deviations heading preceded Acceptance, `None` for an absent section, and `[]` for the no-criteria control. The regex skipped standalone `**bold**`, preserved the payload of `- **bold**`, and skipped `+` and numbered lists, which are outside the requested marker scope. Keep the existing absent-section check at `test/gh557-unknown-blocks-manifest.sh:216` and empty-section check at `test/gh400-acceptance-fidelity.sh:406`–`:423`.

[Unverified — needs clone run] The actual gh400 addition, both shell suites, and the CLI smoke require the Producer's disposable full clone. This round measured fidelity directly without running suites or a CLI preflight. The whole plan was swept and no further plan defects surfaced in the reviewed scope.

### Producer · Round 1

- Finding 1 [Blocker] mixed list — **Implemented.** Dropped the section-wide fallback. Plain bullets are
  read inline in the same loop (issue side only): checkbox first, then plain; a plain bullet deeper than
  the current criterion folds as a continuation, a same/shallower one is a new criterion. Your observed
  input is now an acceptance check (full copy `match`; omitting `Second` → `dropped=['Second']`). Plan
  `## Plan` step 2 and `## Acceptance` updated.
- Finding 2 [Blocker] #792 cleanup — **Declined — out of scope / historical record.** #792 is CLOSED
  (`stateReason: COMPLETED`, `gh issue view 792`), its capture sits in `PROJECT/3-COMPLETED/`, and it is the
  archived record of the packet actually delivered; its deviations were true for the parser that ran. No
  live path re-preflights a completed capture (preflight runs on a candidate's active doc). Rewriting it
  edits evidence and leaves the parent's stated scope (swarm_preflight.py + its tests). Recorded as a known
  effect in the plan and to be stated in the PR. Stale-deviation enforcement is untouched.
- Finding 3 [Should] padded task marker — **Implemented differently.** The plain regex no longer needs a
  lookahead: `ACC_BULLET_RE` (`[-*]\s*\[[ xX]\]`) is tried first and already matches `-  [ ]`/`*   [x] done`,
  so the plain branch never sees a task marker. Plain regex is now `^([ \t]*)[-*][ \t]+(\S.*)$` (non-blank
  payload). Your input `-  [ ]` + `- First` → `['First']` is an acceptance check.
- [Unverified — no citation] items: dropped-control now asserts the dropped direction and text.

<!-- ROUND 2 -->

### Reviewer · Round 2

**What this proposes**

Teach the existing acceptance extractor to count plain dash and asterisk bullets on GitHub issues, including siblings of checkbox criteria. It gives checkbox recognition precedence and folds a deeper plain bullet into its parent criterion.

**How the existing system works, per this document**

Fidelity uses one checkbox extractor for both the issue and capture. The packet uses a checkbox-only capture reader, so I infer that accepting plain capture criteria could credit text that would never reach the packet.

**What it's not**

Capture syntax, packet inlining, and alternate headings are outside this change.

swept file: yes

VERDICT: FAIL

Basis: The mixed-list, dropped-criterion, and padded-marker controls now work in the plan simulation. The new matcher also counts literal example output and can disagree with capture continuation handling on a verbatim tab-indented line. Keep #792's historical record and correct the stated replay boundary.

Probe `PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp" python3 "$PWD/.relay-scratch/tmp/gh1646-r2.py"` exited 0. It compiled the exact regex from the seeded plan, added the proposed branch in memory after checkbox recognition, and routed only the issue parse through that branch. It used the seeded fidelity comparator and unchanged capture parser, with supplied issue bodies and scratch captures. Output tuples are `(status, dropped, added)`. The #792 body was reconstructed from the three verbatim criteria in the retained capture.

- [Blocker] Keep fenced example text out of the new issue-side plain bullet matcher. Scope the fence handling to plain classification and cover the regression with the focused controls.
  - Observed input: Issue `"## Acceptance\n- [ ] First\n\n```text\n- example output\n```\n"`; capture `"## Acceptance\n- [ ] First\n"`. The fenced text is literal output. The old loop at `utils/py/swarm_preflight.py:624–635` ignores the unindented example. The proposed matcher and sibling rule at `PROJECT/2-WORKING/GH-1646-PLAIN-BULLET-ACCEPTANCE.md:46–51` classify it as a new criterion. Probe `fenced/example`: baseline `('match', [], [])`; both plan simulations `('diverged', ['example output'], [])`.
  - Affected scope: Plain dash or asterisk lines in fenced examples under issue Acceptance, where the prior checkbox extractor skips those lines.
  - Falsifier: The example body and capture return `match`. Moving `- example output` outside the closing fence makes that exact text appear in `dropped` until copied.

- [Should] Specify how plain classification preserves the existing continuation result where tabs and spaces mix. Reuse the same continuation check and preserve the existing skip where an expanded indent is deeper but the capture continuation check skips the line.
  - Observed input: Issue and capture both contain `"## Acceptance\n  - [ ] First\n\t- detail\n- [ ] Last\n"`. The parser stores the checkbox indent in expanded columns (`utils/py/swarm_preflight.py:627`) and tests the continuation using raw character count (`:629`), which the inliner also does (`:830–838`). The plan's claim of identical folding at `PROJECT/2-WORKING/GH-1646-PLAIN-BULLET-ACCEPTANCE.md:50–51` fails either way if the plain branch always folds or creates a criterion. Probe `tab/nested`: baseline `('match', [], [])`; expanded-column folding `('diverged', ['First - detail'], ['First'])`; raw-column classification `('diverged', ['detail'], [])`.
  - Affected scope: Issue plain lines nested under a checkbox whose indent and the plain line's indent compare differently with and without tab expansion.
  - Falsifier: The verbatim pair above still returns `match`, the spaces-only mixed pair still matches with its detail intact, and a plain item at the same expanded indent still counts as a sibling.

- [Should] Correct the plan's #792 replay claim. Preserve the historical capture, keep stale-deviation enforcement, and document that direct archive replay surfaces stale deviations. For the green smoke use a scratch capture of the three verbatim criteria without the historical workaround. This supersedes Round 1's request to rewrite the completed record.
  - Observed input: Plan lines 65–69 say preflight does not re-run completed captures. Issue-number discovery is limited to `PROJECT/2-WORKING` at `utils/py/swarm_preflight.py:1434–1447`, but `--project-doc` accepts any existing file at `:1423–1432`. Candidate evaluation falls back to the doc's issue at `:1740–1744`, and fidelity checks the declarations at `:1003–1018` without using the issue state. Probe `archive/closed` on the exact archive path with supplied `CLOSED` state: baseline `('match', [], [])`; simulated issue parser `('diverged', [], [])`. The three declarations and their rationale are at `PROJECT/3-COMPLETED/GH-792-GEN4-SANDBOX-DISJOINT-FIRST.md:34–44`.
  - Affected scope: Explicit selection of a completed capture carrying old workaround declarations. The issue-number discovery path excludes this archive.
  - Falsifier: A source guard rejecting completed docs on explicit selection before fidelity would support the current claim. Otherwise the exact archive replay reports stale declarations and a scratch verbatim copy without them matches.

- [Pass] Round 1 mixed-list and direction findings close. For `PROJECT/2-WORKING/GH-1646-PLAIN-BULLET-ACCEPTANCE.md:88–95`, probe `plain/full` changed from `('diverged', [], ['First', 'Second'])` to `('match', [], [])` and `plain/partial` changed from `('diverged', [], ['First'])` to `('diverged', ['Second'], [])`. Mixed full changed from `('diverged', [], ['Second'])` to `('match', [], [])`; mixed partial changed from `('match', [], [])` to `('diverged', ['Second'], [])`. For the directional assertion, read the `dropped` list directly because the existing gh400 helper at `test/gh400-acceptance-fidelity.sh:55–63` prints only status and detail.
- [Pass] Round 1 padded-marker finding closes for the stated fixture. The checkbox regex at `utils/py/swarm_preflight.py:576` runs first. In both simulations `-  [ ]\n- First` yielded `['First']`; `*   [x] done` yielded `['done']`. The probe also kept `- - -` as a section boundary, preserved `- **bold**` while skipping standalone bold text, skipped numbered and `+` entries per issue scope, returned `None` for absent Acceptance and `[]` for a blank bullet, and skipped a leading deviations heading (`utils/py/swarm_preflight.py:605–623`, plan lines 46–63).
- [Pass] Keep issue-only opt-in. Fidelity reads the issue and capture separately (`utils/py/swarm_preflight.py:985–986`) and packet construction uses the checkbox inliner for the capture (`:1754–1760`, `:826–838`). The nearest graph generation was `2026-11-26T04:31:47Z`; it reports one production caller for the extractor and no recorded code coverage gap. Trace was unavailable under the session approval policy and both task docs were missing from that index, so the relay checkout's source and plan were read directly.

[Unverified — needs clone run] The actual gh400 red/green case, both shell suites, and preflight CLI smoke are pending implementation and disposable-clone verification. The sweep surfaced no further plan defects. 

Handing off to Producer to address the open findings and update the plan.

### Producer · Round 2

- Finding 1 [Blocker] fenced example text — **Implemented.** With `plain_bullets` on, the loop tracks a
  fence toggle (lines whose stripped text starts with ``` or ~~~); a line inside a fence is never classified
  as a plain bullet. Checkbox handling inside fences is unchanged. Your observed input is now the fence control.
- Finding 2 [Should] tab/space continuation — **Implemented.** A plain bullet creates a criterion only when
  no criterion exists yet or its tab-expanded indent is not deeper than the current criterion's; otherwise
  it is left unclassified and falls through to the existing continuation branch untouched (raw-indent fold
  or skip), so it gets the same result the capture side gives the identical line. Your verbatim
  `  - [ ] First / \t- detail / - [ ] Last` pair is now the tab control.
- Finding 3 [Should] #792 replay claim — **Implemented.** Plan text corrected: explicit `--project-doc`
  replay of the archive surfaces stale deviations; discovery only scans `PROJECT/2-WORKING`. Archive kept,
  enforcement kept, smoke uses a scratch verbatim copy without the workaround.

<!-- ROUND 3 -->

### Reviewer · Round 3

**What this proposes**

Extend the shared Acceptance extractor so the issue side reads plain dash and asterisk criteria alongside checkboxes. A deeper plain bullet follows the existing continuation path, and a fence toggle is intended to keep literal examples out of the new matcher.

**How the existing system works, per this document**

Fidelity compares two extracts from a checkbox parser, so a faithful checkbox copy of a plain issue list looks like an addition. The packet separately reads capture checkboxes. I infer that enabling plain bullets on the capture side would let fidelity give credit for criteria that never reach the packet.

**What it's not**

Capture grammar, packet inlining, alternate headings, and stale-deviation enforcement are outside this plan.

swept file: yes

VERDICT: FAIL

Basis: The simple fence case, indent parity, and #792 disposition check out. The proposed toggle can still credit literal example text, and the existing section-boundary order can skip real criteria after a fenced example.

Probe command `PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp" python3 "$PWD/.relay-scratch/tmp/gh1646-r3.py" "$PWD/.relay-scratch/tmp/gh1646-r3.py"` exited 0. The scratch script compiled the plan's exact plain regex, inserted the Producer's stripped-prefix toggle and expanded-indent check in a copy of the seeded loop in memory, then enabled that copy only for the issue call in seeded fidelity. It supplied issue bodies and scratch captures directly. Tuples below are `(status, dropped, added)`.

- [Blocker] Close an issue fence only on a valid closer for its opener. Track the delimiter character and width instead of flipping a boolean on either prefix.
  - Observed input: Issue `"## Acceptance\n- [ ] First\n\n```text\n~~~\n- example output\n```\n"`, capture `"## Acceptance\n- [ ] First\n"`. The toggle in the Round 2 Producer reply and plan lines 54–55 treats the literal `~~~` as a closer. Probe `mixed fence delimiters` reported baseline `('match', [], [])` and planned `('diverged', ['example output'], [])`. The same result occurred with a four-backtick opener and a three-backtick line inside it.
  - Affected scope: Literal fence-like lines within issue Acceptance examples containing plain dash or asterisk text.
  - Falsifier: Both inputs match the capture with only First. A plain `- Second` after the real closer is still reported in `dropped` until copied.
- [Blocker] While inside an issue fence, keep literal headings and rules from ending the Acceptance section. Retain the existing boundary checks outside fences and the default capture path.
  - Observed input: Issue `"## Acceptance\n- [ ] First\n\n```text\n## sample output\n```\n\n- Second\n"`. The boundary checks at `utils/py/swarm_preflight.py:618–623` run before bullet classification, as preserved by plan lines 64–67. With a capture holding only First, both baseline and planned fidelity reported `('match', [], [])`. With a capture holding First and Second, both reported `('diverged', [], ['Second'])`. Replacing the literal heading with `---` produced the same two results. This is a pre-existing boundary defect that also defeats the planned plain-bullet behavior.
  - Affected scope: Real issue criteria following a fenced example that contains a heading at or above the Acceptance level or a horizontal rule.
  - Falsifier: Both examples match the full copy and report `('diverged', ['Second'], [])` for the partial copy. A real heading or rule outside the fence still terminates Acceptance.
- [Pass] The Round 2 tab and archive findings close. The verbatim tab pair matched before and after simulation using the unchanged continuation branch at `utils/py/swarm_preflight.py:628–635`. With the issue body reconstructed from the three archived criteria, the retained #792 capture went from `match` to `diverged` with `deviations are declared but the two lists do not differ`, and the scratch verbatim copy matched. Plan lines 69–75 now document the explicit archive replay path and the smoke correctly. See `utils/py/swarm_preflight.py:1426–1447` and `:1003–1018`.
- [Pass] Plan lines 94–104 pin observable behavior. The plain full-copy case changed from `('diverged', [], ['First', 'Second'])` to `('match', [], [])`. The plain and mixed partial copies both reported `('diverged', ['Second'], [])` in the simulation. The simple fence and padded empty task controls matched, and the extractor returned `None` for absent Acceptance and `[]` for an empty section with out-of-scope markers. The existing gh400 helper only emits status and detail, so assert `dropped` directly for the new control (`test/gh400-acceptance-fidelity.sh:55–63`).
- [Pass] Keep the issue-only opt-in at `utils/py/swarm_preflight.py:985–986`. The capture's packet reader still takes checkboxes at `:826–838` and `:1754–1760`. The nearest graph generation was `2026-11-26T04:31:47Z`; the snippet reports one caller. Trace was unavailable under the approval policy and the plan and archive were absent from that index. Direct source in the relay checkout shows both extractor calls in fidelity.

[Unverified — needs clone run] The gh400 red/green case, both shell suites, and the CLI smoke remain for implementation verification in a disposable full clone. The whole plan was reviewed. No further plan defects surfaced in this sweep.

Handing off to Producer to correct fence handling and retain both controls in the plan.

### Producer · Round 3

- Finding 1 [Blocker] fence closer — **Implemented.** Issue-side fence tracking records the opener's character
  and width; a line closes it only when it is the same character, at least as long, and nothing else
  (CommonMark). Both observed inputs (`~~~` inside ```` ``` ````, three backticks inside four) are fence controls.
- Finding 2 [Blocker] heading/rule inside a fence ending Acceptance — **Implemented, issue side only.** While
  inside an issue fence, the heading and HR boundary checks are skipped; outside fences and on the capture side
  they are unchanged (the capture side keeps agreeing with `collect_inline_checklist`). Your observed input is
  the fence boundary control (full copy `match`, partial `dropped=['Second']`).

This is the last plan round (4/4). Remaining edge cases beyond the stated controls are proposed as out of scope.

<!-- ROUND 4 -->

### Reviewer · Round 4

**What this proposes**

Count plain dash and asterisk bullets alongside checkboxes in GitHub issue Acceptance sections. The plan retains the existing continuation logic and uses issue-side fence tracking so real criteria after a fenced example are still read.

**How the existing system works, per this document**

Fidelity extracts checkboxes from both the issue and the capture. A verbatim checkbox copy of a plain issue list therefore looks like an addition. The packet inliner also consumes capture checkboxes, so I infer that the capture grammar is part of the packet contract.

**What it's not**

The capture grammar, packet inliner, accepted headings, and stale-deviation rules remain as they are.

swept file: yes

VERDICT: FAIL

Basis: Both Round 3 replays pass for their specified inputs. The same fence design introduces a false refusal for a literal checkbox and can suppress a real criterion after an inline code span. Round 4 reached the cap, so this relay is escalated to the Producer.

Probe commands `PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp" python3 "$PWD/.relay-scratch/tmp/gh1646-r4.py"` and `PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp" python3 "$PWD/.relay-scratch/tmp/gh1646-r4-corrected.py"` both exited 0 after asserting the results below. The first compiled the exact planned regex, substituted the Round 4 fence and classification rules into the seeded extractor in memory, and used that version for the issue call only. The second rejected backticks in backtick opener info and skipped fenced lines before classification. Both used seeded fidelity with injected issue bodies and scratch captures. Tuples are `(status, dropped, added)`. These are plan simulations.

- [Blocker] Prevent newly reachable literal checkboxes from becoming required criteria. When skipping a literal heading or rule inside a fence, suppress criterion creation from the fence content the old loop would never reach. Preserve the capture path and normal checkbox parsing.
  - Observed input: Issue `"## Acceptance\n- [ ] First\n\n```text\n## sample output\n- [ ] example output\n```\n"`, capture `"## Acceptance\n- [ ] First\n"`. The existing parser stops at the sample heading (`utils/py/swarm_preflight.py:618–623`). The plan skips that break but still runs checkbox matching inside the fence (`PROJECT/2-WORKING/GH-1646-PLAIN-BULLET-ACCEPTANCE.md:56–59`, `utils/py/swarm_preflight.py:624–627`). Probe `fenced checkbox after heading` printed baseline `('match', [], [])`, plan `('diverged', ['example output'], [])`, and corrected simulation `('match', [], [])`.
  - Affected scope: Issue-side fenced examples with a literal section boundary followed by a sample checkbox. Ordinary checkboxes outside the fence still count.
  - Falsifier: The exact capture matches. Add `- Second` after the closer and the partial copy reports only `dropped=['Second']`. Skipping every issue-side fenced line also fixed the reproduced input in simulation, but if taking that broader route, account for the existing continuation behavior on fenced text that is indented under a criterion.

- [Blocker] Require a valid backtick fence opener before suppressing plain criteria. A backtick opener's info string cannot contain a backtick. A same-line closing run can belong to an inline code span.
  - Observed input: Issue `"## Acceptance\n- [ ] First\n\n```inline code```\n\n- Second\n"`. The stripped-prefix opener in `PROJECT/2-WORKING/GH-1646-PLAIN-BULLET-ACCEPTANCE.md:54–57` starts a fence on the inline span, then suppresses Second. With both criteria copied as checkboxes the plan reports `('diverged', [], ['Second'])`. With only First it reports `('match', [], [])`. Probe `inline code/full` and `inline code/partial` returned `('match', [], [])` and `('diverged', ['Second'], [])` after the opener check was tightened.
  - Affected scope: Plain issue criteria after a line beginning with a backtick code span of width three or greater.
  - Falsifier: The full copy matches and the partial copy identifies Second as dropped. A real opener such as three backticks followed by `text` still shields literal bullets until the valid closer.

- [Pass] The Round 3 controls close for their exact inputs. A tilde run inside a backtick fence and a three-backtick run inside a four-backtick fence both preserved `match`. Fenced `## sample output` and `---` both preserved Second after the closer, yielding full `match` and partial `dropped=['Second']`. An outside `- - -` still ends Acceptance. See plan lines 54–59 and 106–110, and `utils/py/swarm_preflight.py:618–623`.
- [Pass] The full plain copy moved from `('diverged', [], ['First', 'Second'])` to `('match', [], [])`; plain and mixed partial copies both reported `('diverged', ['Second'], [])` in the simulation. The tab pair, padded empty task, absent and empty sections, deviations heading, and bold controls also passed. For the new directional assertion read `dropped` directly because the existing shell helper prints status and detail only. See plan lines 98–113, `utils/py/swarm_preflight.py:605–635`, and `test/gh400-acceptance-fidelity.sh:55–63`.
- [Pass] The issue body and capture reads are separate (`utils/py/swarm_preflight.py:985–986`). Capture packet inlining still uses the checkbox reader (`:826–838`, `:1754–1760`). The reconstructed #792 issue shape diverged on the retained archive and matched the scratch copy without the workaround, as described at plan lines 73–79 and implemented by the stale-deviation check at `utils/py/swarm_preflight.py:1003–1018`. The nearest index generation was `2026-11-26T04:31:47Z`. Its extractor snippet reports one caller, inbound tracing was unavailable under the session approval policy, and both task docs were absent from that index. The call sites and docs were checked directly in the relay checkout.

[Unverified — needs clone run] The two shell suites, the actual gh400 red/green addition, and the preflight CLI smoke remain implementation checks for the disposable full clone. No phase gate was specified for this reviewer turn. The sweep surfaced no further defects in the reviewed scope.

Handing off to Producer (claude-a) to address the two blockers and arrange a fresh plan review after escalation.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
