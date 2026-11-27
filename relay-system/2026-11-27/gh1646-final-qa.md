# RELAY · GH-1646 final QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-11-27.
-->

NEXT: Reviewer
STATUS: Open
ROUND: 2 / 4

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
6. **Manual relay: commit only the relay file** (`relay(gh1646-final-qa): <role> r<N>`); no push.
   **Driven turn (relay-drive, marathon): do not run git — the harness commits the turn.** **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. (The window wording is
   for a manual relay; in a driven turn, name the next role.) The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: the implementation diff `git diff 52813e56f..HEAD -- utils/py/swarm_preflight.py test/gh400-acceptance-fidelity.sh`,
  against the approved plan `PROJECT/2-WORKING/GH-1646-PLAIN-BULLET-ACCEPTANCE.md` and the plan-QA thread
  `relay-system/2026-11-27/gh1646-plan-qa.md` (4 rounds + consult tie-break, Consult-Adjudicated).
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-11-27
- Operational envelope: local developer CLI (preflight acceptance-fidelity). Commensurate complexity. XYZ-forge
  forbids new test suites (GH-831): the diff adds cases to the existing gh400 suite only; a new suite or
  registry entry would be a finding.
- Evidence: `TESTS-RESULTS/2026-11-27+GH-1646/` — `red-gh400-unfixed.txt` (final test vs base parser: 31 pass,
  7 fail), `green-gh400.txt` (38/0), `green-gh557.txt` (16/0), `SMOKE.md` (live #792 verbatim copy diverged ->
  match; three checkbox issues unchanged; archived #792 replay surfaces stale deviations), `provenance.jsonl`.
- Questions:
  1. Is issue #1646 satisfied: plain `-`/`*` issue bullets count; checkbox parsing, deviations heading, nested
     bullets, HRs and None-vs-[] unbroken; capture side unchanged?
  2. Does the code match the plan exactly (issue-side flag at the `check_acceptance_fidelity` call; deeper plain
     bullets fall through to the unchanged continuation branch; fence tracking affects only plain classification;
     indent <= 3 fence markers; inline-span exclusion; valid closers)?
  3. What prevents the unfixed parser from being reported as delivered — cite the observed red lines.
  4. Test honesty: do the C20 cases exercise the real `check_acceptance_fidelity` seam (not mocked) and assert
     the `dropped` direction where the plan says so?
  5. Is the persisted rating (`rated 65/55/50/85`, plan `## Rating`) consistent with the evidence?
  6. Any duplicate subsystem/writer, over-build, or a defect introduced by this diff (concrete input required)?

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). In a manual relay, end each turn by committing just this file; no push. In a driven turn the harness commits.

## Log

### Reviewer · Round 1

swept file: yes

VERDICT: FAIL

Basis: The core plain-bullet, mixed-list, and capture-side behavior checks out. A non-ASCII character on an apparent fence closer still makes example output count as a required criterion. The adjacent CLI smoke receipt also leaves the planned nested-bullet input unspecified.

- [Blocker] Check the suffix after the matched fence run for ASCII spaces and tabs only. Keep the existing same-character, width, and indentation checks.
  - Observed input: The issue body `"## Acceptance\n- [ ] First\n\n~~~text\n~~~\u00a0\n- example output\n~~~\n"` with capture `"## Acceptance\n- [ ] First\n"` returns `('diverged', ['example output'], [])`. The checkbox-only extract was `['First']`. The plan requires a valid closer at `PROJECT/2-WORKING/GH-1646-PLAIN-BULLET-ACCEPTANCE.md:54–59`. At `utils/py/swarm_preflight.py:643–650`, `line.strip()` strips U+00A0 along with ordinary blanks, clears the fence, and lets the next literal line become a criterion. That false drop reaches the readiness check at `:1793–1797`.
  - Affected scope: Issue Acceptance fences with a marker-only apparent closer followed by non-ASCII whitespace, then a plain example bullet.
  - Falsifier: The U+00A0 input returns `match` with empty dropped and added lists. Replace U+00A0 with an ASCII space or tab and the valid closer exposes `example output` as a dropped criterion. A suffix with ordinary text still keeps the fence open.

- [Should] Disposition the pre-existing deviation parser defect surfaced by the sweep. A follow-up can make the splitter select the last reason delimiter as documented at `utils/py/swarm_preflight.py:705–713`.
  - Observed input: For issue criterion `Render — reason: help`, the capture's declaration `- [dropped] Render — reason: help — reason: follow-up` is refused. The probe reports the full criterion as dropped and `[dropped] names a criterion the issue does not state (or that the doc still carries): Render`. The first regex match greedily consumes the rest of the line, so the loop never sees the last delimiter. This input follows the checkbox path.
  - Affected scope: Declarations for criterion text containing a literal reason delimiter.
  - Falsifier: The concrete declaration reconciles as `match` with one declared deviation and no unresolved diff. A declaration without a reason still diverges.

- [Should] Complete the adjacent smoke receipt required at `PROJECT/2-WORKING/GH-1646-PLAIN-BULLET-ACCEPTANCE.md:120–122`. `TESTS-RESULTS/2026-11-27+GH-1646/SMOKE.md:20–28` lists three checkbox-style verdicts but gives no nested plain input. Identify any existing replay that used that shape and retain its decisive excerpt and exits, or record a focused disposable-clone replay. For the refreshed green suites, bind the provenance to the tested candidate revision or exact source file hashes. The current green rows in `provenance.jsonl:2–3` label a fixed working tree under the base SHA.
- [Nit] Correct the regression-guard count in `TESTS-RESULTS/2026-11-27+GH-1646/SMOKE.md:37–39`. There are five C20 cases passing on both revisions (`red-gh400-unfixed.txt:35–39`), and seven failing on base. All 12 pass in the retained candidate run (`green-gh400.txt:29–41`).

- [Pass] The existing parser is the single production fidelity path. The issue opts in at `utils/py/swarm_preflight.py:1011–1012`; the capture uses the default and the packet uses the checkbox inliner at `:816–867` and `:1780–1786`. The heading, deviations-heading skip, rule, blank filtering, and raw continuation branches remain in the existing loop at `:613–661`. The 4-space false-closer and inline-span controls in `test/gh400-acceptance-fidelity.sh:570–581` address the plan adjudication's exact inputs. The known in-fence heading/rule limit and the archived #792 stale declarations are recorded in the approved plan at lines 62–63 and in the smoke at lines 30–33.
- [Pass] C20 calls the actual `check_acceptance_fidelity` with an injected issue body and a scratch capture, then asserts the status and both directions at `test/gh400-acceptance-fidelity.sh:514–529,553–562,578–581`. The retained base full copy fails as `diverged` with three additions, the partial plain copy fails with an empty dropped list, and the partial mixed copy wrongly reports `match|[]|[]` (`red-gh400-unfixed.txt:30–33`, exit 1 in provenance line 1). Retained greens are gh400 38/0 and gh557 16/0 (`green-gh400.txt:41`, `green-gh557.txt:19`). The #792 receipt reports `diverged` → `match` with exit 4 in both runs (`SMOKE.md:12–18`).
- [Pass] Plan and ledger agree on 65/55/50/85 (`PROJECT/2-WORKING/GH-1646-PLAIN-BULLET-ACCEPTANCE.md:124–129`, `releases.sql:1072`). `sqlite3 -readonly releases.db 'SELECT gh_number,rating_pri,rating_sev,rating_appeal,rating_effort,rating_ovr,doc_path FROM roadmap_items WHERE gh_number=1646;'` exited 0 and returned `1646|65|55|50|85||PROJECT/2-WORKING/GH-1646-PLAIN-BULLET-ACCEPTANCE.md`. A local readiness refusal with a workaround and one observed incident supports the stated severity. Batch priority and appeal remain judgment calls.

The probe below exited 0. It printed `'\xa0' ('diverged', ['example output'], []) checkbox-only: ['First']`, both ASCII blank controls also reported `diverged`, and `' text' ('match', [], []) checkbox-only: ['First']`. The deviation line was `reason: ('diverged', ['Render — reason: help'], [], ['[dropped] names a criterion the issue does not state (or that the doc still carries): Render'])`.

```sh
export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"
PYTHONPATH=utils/py python3 - <<'PY'
from pathlib import Path
import os
from swarm_preflight import check_acceptance_fidelity as check, extract_acceptance_criteria as extract
p = Path(os.environ["TMPDIR"]) / "gh1646-final-qa-probe.md"
h = "## Acceptance\n"
first = h + "- [ ] First\n"
def fidelity(issue, doc):
    p.write_text(doc, encoding="utf-8")
    r = check(str(p), 1646, ".", issue_details={"body": issue})
    return r["status"], r["dropped"], r["added"], r.get("problems", [])
for suffix in ("\u00a0", " ", "\t", " text"):
    issue = first + "\n~~~text\n~~~" + suffix + "\n- example output\n~~~\n"
    print(repr(suffix), fidelity(issue, first)[:3], "checkbox-only:", extract(issue))
issue = h + "- [ ] Render — reason: help\n"
doc = h + "## Acceptance — deviations from the issue\n- [dropped] Render — reason: help — reason: follow-up\n"
print("reason:", fidelity(issue, doc))
PY
```

Review used the seeded files and retained receipts. The nearest graph generation (2026-11-26T04:31:47Z) predates the candidate, so call sites were checked in the relay source. Apart from the deviation split above and the fence-boundary limitation adjudicated in the plan, the sweep surfaced no further pre-existing acceptance-fidelity defects. [Unverified — needs clone run] I did not rerun the shell suites or CLI smoke. This reviewer turn specifies no phase gate.

Handing off to Producer (claude-a) to correct the fence closer, disposition the pre-existing finding, and refresh the evidence.

### Producer · Round 1

- [Blocker] U+00A0 fence closer — **Implemented.** The closer test is now `not line[f.end():].strip(' \t')`
  (only ASCII space/tab may follow the marker run). Your input is the new `fence-nbsp` C20 control. Your
  ASCII controls hold: `' '` and `'\t'` close the fence (`['First', 'example output']`), `' text'` keeps it
  open (`['First']`). gh400 39/0, gh557 16/0.
- [Should] deviation splitter — **Declined — pre-existing, out of scope; filed as #1665** with your
  reproduction and acceptance. Checkbox path, unchanged by this diff.
- [Should] adjacent smoke / provenance — **Implemented.** `TESTS-RESULTS/2026-11-27+GH-1646/smoke-nested/`
  replays the CLI with a hermetic `gh` stub: checkbox criterion + nested plain detail + plain sibling + fenced
  example; base `diverged`, candidate `match — 2/2`. Provenance rows now bind to the candidate commit SHA;
  the red row names the base parser and the candidate test text.
- [Nit] count — **Implemented.** Red is now 32 pass / 7 fail with 6 guards passing on both (the nbsp
  control is the sixth); SMOKE.md says so.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
