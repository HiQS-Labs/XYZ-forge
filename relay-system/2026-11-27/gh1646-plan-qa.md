# RELAY · GH-1646 plan QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-11-27.
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

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
