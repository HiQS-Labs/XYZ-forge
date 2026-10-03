# RELAY · GH-928 canary + GH-884 direction: independent QA before committing direction (GH-784)
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-02.
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
6. **Commit only the relay file** (`relay(gh928-gh884-independent-review): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **.relay-artifacts/gh928-gh884-review-packet.md** — the read-only path that
  `relay-drive.sh --artifact-file temp/gh928-gh884-review-packet.md` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-10-02
- Operational envelope: local CLI toolkit, single repo, macOS-first. Machinery must stay commensurate with that scope — do NOT demand enterprise multi-tenant fail-safes, and do NOT propose new test suites (GH-831 forbids them in this repo: no new `test/` suite, no new `validate.sh` TESTS entry, no new gate machinery; verification = existing suites or `TESTS-RESULTS/` receipts).
- Definition of Done: an independent adjudication of (a) the GH-928 canary work and its fix round, (b) the GH-884 prognosis/PoC evidence, and (c) the recommended direction — each graded, with the verdict PASS/FAIL/PARKED and a Basis.

Questions (answer each, numbered, with `file:line` or quoted-span citations for every finding):

1. **Fix round soundness.** Given the packet's Part 1 diff (sandbox use-boundary guards `sandbox_resolve`/`sandbox_deletable`, full-local-config `git_state_fingerprint`, sandbox-copy `python-ports`, teardown ownership marker): is the P1 `rm -rf` hazard actually closed, or is there a bypass you can name (a concrete input that still deletes something dangerous)?
2. **Evidence sufficiency.** Part 2's `provenance.jsonl` — does it satisfy "a run cited as evidence must have committed provenance" (GH-430) for the claims made (21/21 clean, red controls, gate refusal + green)? What claim, if any, remains unbacked?
3. **Method read.** Part 3's core claim — "the clean-room method re-derives surfaces but re-makes containment/evidence mistakes; import the primitives as day-one admission requirements" — is that supported by the packet, or over-generalized from two artifacts (one canary, one worked example)?
4. **Direction.** The recommendation is: do NOT commit to the GH-884 rebuild now; prune-first if the #854 window holds (Oct 8 audit + canary-as-pre-push-first-stage + tier enforcement); rebuild only if a trigger fires, with the three amendments. Is this the right call on the stated evidence, or is there a materially better option the packet misses? Name it concretely if so.
5. **Swept file:** did you review the WHOLE packet (Parts 1–4 including receipts and the PR review context), not just the diff? Declare `swept file: yes/no`.

Write your verdict block below (graded findings → VERDICT: PASS/FAIL/PARKED + Basis), flip `STATUS` to `Approved` only if it passes, and follow the turn protocol above.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer · Round 1

swept file: yes

Scope: all 360 lines of the seeded packet: complete diff, 11 receipts, recommendation, and empty Part 4. Citations below refer to `.relay-artifacts/gh928-gh884-review-packet.md`. No graph tools were available; this is direct artifact review. No git commands, canary execution, suites, or executable fixtures were run. Only the two side-effect-free guard functions were evaluated against scratch directories.

1. **[Blocker] Fix round: the P1 deletion hazard remains open.** The predicate at packet:151–170 excludes the harness and its descendants, root, and home, but accepts other existing populated directories AND ancestors of the harness. Setup creates `logs/` itself (packet:274–284); its existence proves neither exclusive ownership nor creation by this run. Teardown recursively deletes the entire accepted directory (packet:292–293). Selecting an existing project as `XYZ_CANARY_SANDBOX` therefore targets its unrelated contents; selecting the harness's parent also passes the directional path check. The observed failure is guard acceptance of unsafe targets, not an executed deletion.
   Observed input: unchanged functions extracted from packet:151–170; `ROOT=<scratch>/parent/harness`; candidates `<scratch>/existing-project` (containing `valuable.txt` and `logs/`) and `<scratch>/parent` (containing the harness and `logs/`). Both returned 0 and printed the deletion target.
   Affected scope: caller-selected pre-existing directories outside the harness, including its ancestors; default fresh mktemp directories need not change.
   Falsifier: in a disposable full clone, select a populated scratch project and a scratch ancestor of the harness; both must be refused before writes or preserved while only a freshly allocated run-owned child is used/deleted. A fresh owned sandbox must still work; root/home/harness must still be refused.
   Concrete fix: treat the override as a parent for a fresh unique child, or refuse pre-existing override targets and prove exclusive creation; reject harness ancestors as well. Do not manufacture ownership by placing a generic `logs/` directory into an arbitrary caller directory. Root cause: caller input is promoted to recursive deletion authority; fix site: sandbox allocation/ownership and deletion boundary.

   Guard probe command (outer exit 0; scratch creation only, no deletion):

   ```python
   # Shell prefix: export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"
   # mkdir -p "$TMPDIR"; python3 - <<'PY' [body below] PY
   import os, pathlib, subprocess, tempfile
   lines = pathlib.Path('.relay-artifacts/gh928-gh884-review-packet.md').read_text().splitlines()
   guards = '\n'.join(x[1:] for x in lines[150:170])
   assert guards.startswith('sandbox_resolve() {') and 'sandbox_deletable()' in guards
   base = pathlib.Path(tempfile.mkdtemp(prefix='guard-probe-', dir=os.environ['TMPDIR']))
   root = base / 'parent' / 'harness'; root.mkdir(parents=True)
   existing = base / 'existing-project'; (existing / 'logs').mkdir(parents=True)
   (existing / 'valuable.txt').write_text('pre-existing data; must survive\n')
   (root.parent / 'logs').mkdir()
   shell = guards + '\nROOT="$1"\nSANDBOX="$2"\nsandbox_deletable\n'
   for candidate in (existing, root.parent, pathlib.Path('/'), pathlib.Path.home(), root):
       r = subprocess.run(['bash', '-c', shell, 'guard-probe', str(root), str(candidate)],
                          capture_output=True, text=True)
       print(r.returncode, r.stdout.strip())
   ```

   Decisive captured output (paths normalized): populated directory `guard_rc=0`, output `<scratch>/existing-project`; ancestor `guard_rc=0`, output `<scratch>/parent`; root, home, and harness each `guard_rc=1`. Sentinel remained unchanged. **[Unverified — needs clone run]** End-to-end deletion/control behavior was deliberately not executed here.

2. **[Should] Evidence: Part 2 does not substantiate every claimed outcome.** Its 11 rows (packet:331–341) attest 21/21, home/root refusal, config sensitivity, jog break, gate refusal, and a focused path-integrity-plus-canary green. There is NO receipt for the full second push's “GREEN in 1062s” (packet:3,349), nor for the tick-break claim (packet:18,45–47). The jog receipt reports two failed checks (packet:339), while prose also claims `jog-help` failed (packet:46–47); distinguish separate runs or correct the prose. The diff does not include provenance additions or a commit-content attestation, so the packet alone cannot establish GH-430's **committed** requirement; this is not a claim that the actual PR lacks committed receipts. Receipt bases also do not identify the exact tested candidate content for every run.
   Concrete fix: include missing full-gate/tick receipts or withdraw those claims; reconcile jog outcomes; identify the provenance-bearing commit and tested revision/patch. Include reproducible commands for the abbreviated fingerprint probes. No new suites are requested.
   **[Unverified — needs clone run]** I did not independently repeat 21/21, red controls, the full gate, or the gh308 PoC. Part 3's 57ms, 38 assertions, unchanged fingerprint, and seven-bar result are only a summary (packet:351), without underlying commands/receipts/scorecard here. Supply those before treating the PoC as verified evidence. Keep the 60–70% odds and 4–8 weeks (packet:350) explicitly judgmental estimates, not measured forecasts.

3. **[Pass] Method: importing existing containment/evidence primitives is a supported local lesson, with a narrower inference.** The documented unsafe deletion, incomplete fingerprint, and missing path reference (packet:57–83), plus finding 1, support the admission constraint at packet:355. They do not establish a general clean-room failure rate or the scalability of re-earning the long tail from one gh308 example (packet:351). Retain the rule; describe it as observations from this canary and a single worked example. “All 21 smoke checks passed ... no new surface defects” (packet:91) establishes only that these checks detected none.

4. **[Pass] Direction: defer rebuild commitment, conditionally.** T1 requires three qualifying local gates and three hosted runs and currently has only one clean data point in the stated evidence (packet:346). That supports waiting for the Oct 8 audit, not declaring stabilization successful. The trigger-gated contingency and three amendments (packet:354–355) are proportionate. Concrete next choice: keep PR #930 on HOLD until finding 1 and evidence gaps are resolved; retain the current gate, then separately decide pre-push integration after the audit and operator decision (packet:356). A ~4s smoke check does not itself remove the full-gate cost; no measured pruning savings are supplied. No better-supported immediate rebuild option is present. Reversibility: deferral/additive smoke integration is Easy; replacement is Costly and should retain the existing gate as rollback through shadow qualification. This is conditional agreement with direction, not approval to land or arm the canary.

5. **[Should] Whole-packet sweep: promised PR review context is missing.** Part 4's heading at packet:358 is followed only by blank lines through EOF (packet:360). A non-mutating Python parse exited 0: `part4_body_nonwhitespace_chars=0`, `receipt_count=11`. The decisive expressions were `len(packet.split("## Part 4 —", 1)[1].split("\n", 1)[1].strip())` and `len([json.loads(line) for line in packet.splitlines() if line.startswith('{"timestamp"')])`. Populate actual PR review verdicts/dispositions, or explicitly state that they were not supplied. I swept everything provided, but cannot adjudicate absent review threads or full source omitted from the diff. The sweep found the outstanding defects above; no whole-source clean bill is claimed.

VERDICT: FAIL

Basis: the claimed P1 closure is falsified by unchanged guards accepting populated unowned directories and harness ancestors. The packet also omits the full-gate green receipt and all Part 4 context. Deferring GH-884 remains reasonable conditionally, but the canary fix/evidence cannot be approved as presented.

Handoff: Producer (claude-a) — disposition the findings, correct the artifact/source and evidence in your authorized workspace, and return the revised packet for Round 2. No approval, landing, or workflow arming is granted.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
