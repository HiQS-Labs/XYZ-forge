# RELAY · GH-1015 independent plan QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-10.
-->

NEXT: Producer
STATUS: Approved
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
6. **Commit only the relay file** (`relay(gh-1015-independent-plan-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **gh1015-plan-packet.md** (embedded below — read it here).
- Reviewer: codex   ·   Producer: codex-author
- Started: 2026-10-10

### Artifact — gh1015-plan-packet.md
```
# Independent Codex plan QA — GH-1015

Read PROJECT/2-WORKING/GH-1015-OBSERVER-PATH.md and its recon map in full, source relay-automation/marathon.sh (embedded Python + launcher target forwarding), utils/py/marathon_drive.py (_result_arm/main/receipt writer), validate.sh:144, test/gh609-sdlc-agent-gaps.sh, baseline observations/provenance, and GH-1015's RELEASES row. Review before production implementation.

Local opted-in developer CLI observer; three proposed local edits. Grade against those requirements and commensurate complexity. No new suites, gates, controllers, driver/schema/qualification changes, live provider execution or merging. Reviewer writes only the relay thread. Do not run mutation-heavy suites or executable fixtures in a worktree; use bounded read-only source probes if needed.

1. Does observer init abspath match the actual driver target path for both default and explicit/relative symlink targets while strict receipt attribution remains unchanged?
2. Are the three asks grounded, package exclusion correct, blast/rollback and red/green acceptance sufficient?
3. Does existing ledger writer ownership/rating 60/35/50/90 fit observed consequences, neutral appeal, unknown recurrence, no user override?
4. Does this plan add unnecessary machinery, miss a requirement, or violate the no-new-tests rail?

Append a concrete review with file:line support; required behavior-change findings include Observed input/Affected scope/Falsifier. Approve if no required issue remains; else hand off to producer codex-author. Do not implement the proposal. Use the scaffolded relay's status/turn/tick protocol.
```
- Definition of Done: Approve only if all four review questions are satisfied and the planned acceptance checks distinguish the reproduced failure from valid/foreign receipts; no implementation is authorized until plan QA is Approved.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer · Round 1 · codex

VERDICT: PASS
Basis: All four plan questions are satisfied. The proposed correction preserves strict attribution, the acceptance matrix distinguishes the reproduced failure from valid and foreign receipts, and verification remains a prerequisite to publication rather than an assertion of implementation success.
swept file: yes

- [Pass] Whole embedded packet, working plan and recon read; full `relay-automation/marathon.sh` swept, including pre-existing code. No additional required pre-existing defect found in that sweep. Driver receipt seams and GH-609 safeguards were read directly. Graph Verify evidence: nearest indexed project `Users-noelsaw-Documents-GH-Repos-XYZ-forge`, generation `2026-10-10T08:23:22Z`, ready; `_result_arm` inbound trace names `main`, with no remaining pagination. This is the primary checkout's graph, not this worktree's index; local source is the evidence of record. Coverage gaps at marathon.sh:416 and :694 were read; the working plan was absent from that graph and read locally in full. Scope and unknowns are explicit at `PROJECT/2-WORKING/GH-1015-OBSERVER-PATH.md:15,39–41,55`.
- [Pass] Path correction is grounded: init currently resolves product_root (`relay-automation/marathon.sh:267`), while `_result_arm` uses `os.path.abspath(target_root)` for explicit targets and retains root for the default (`utils/py/marathon_drive.py:325`); the writer serializes that stored value at :250. The launcher sends the same target spelling to observer and driver at `relay-automation/marathon.sh:565,604`, and exports its default root to the driver at :642–646. Replacing only init product_root with abspath aligns normal default and explicit absolute/relative symlink targets without changing the exact schema/execution/phase/lane/target/token predicates at :135–144 or qualification at :148–157. No reader-side realpath tolerance or driver edit is needed.
- [Pass] The other two edits are local and earned: normal output already sorts keys (`relay-automation/marathon.sh:208`) and missed-check output does not (:240–241); GH-609's registry comment still says “expand-contract migrations” (`validate.sh:144`), whereas its existing checker explicitly scopes online migrations and says offline work need not inherit rolling-deployment protocol (`test/gh609-sdlc-agent-gaps.sh:113–119`). Package exclusion is correct: `skills/1-hourly/relay-automation/make-pkg.sh:12–30` lists 18 members and excludes marathon.sh. Read-only command `tar -tzf skills/1-hourly/relay-automation/relay-pkg.tar.gz` displayed those same 18 paths; an independent stdlib archive query below measured `package_members= 18 marathon.sh_present= False`.
- [Pass] Blast, rollback and acceptance are proportionate (`PROJECT/2-WORKING/GH-1015-OBSERVER-PATH.md:33–49`): three reversible edits, no new suite/gate/controller or schema/qualification change, synthetic receipts and controlled clock, nonempty parsed output, foreign execution/token/target/schema/phase/lane negatives, missing/non-green qualification negatives, and base/candidate/restored-old-init red/green/red. Existing focused checks, source hashes/provenance, independent final QA and the macOS full pre-push gate are required in disposable full clones. The full route is conservative and correct for the validate.sh comment edit (`utils/ci-route.sh:325–329`). No live provider run or merge is authorized.
- [Pass] Ledger identity/rating fit the observed consequence. `releases.sql:842` names the owned GH-1015 row `rmi-01M4KATWBJ8T1GHXBSQMACY5KE`, correct issue/doc, 60/35/50/90 and NULL override. Plan :45 admits only that exact row through accepted-start; the existing writer requires `--gid` (:3902–3905), qualified owned/open issue (:3942–3953), and rechecks identity/state before mutation (`utils/py/releases_app.py:3994–4006`). Plan :53–55 appropriately treats this as observation-fidelity loss, neutral appeal and unknown recurrence, without inventing a safety consequence or trend. Keep that existing writer and exact row; no second ledger mechanism is warranted.
- [Pass] Retained baseline is nonempty and internally matches its provenance: `TESTS-RESULTS/2026-10-10+GH-1015/baseline-observations.json` records physical/logical/foreign counts `[1,0,0]`; provenance quotes “Synthetic qualified receipt; no worker, provider or live marathon invoked.” Read-only probe command: `python3 -` with stdlib `tarfile.getnames()`, `json.loads(Path(...baseline-observations.json).read_text())`, `hashlib.sha256(p.read_bytes()).hexdigest()`, and `ast.parse()` of the embedded payload. Exit 0; decisive output: `package_members= 18 marathon.sh_present= False`, `baseline_nonempty= True counts= [1, 0, 0] sha256= 0e6a643e848cc28155022ac696726ca7cef49ba995519f6cca33495d40229968`, `observer_parse=OK`. This verifies retained evidence integrity and source parsing, not a fresh runtime reproduction. An initial probe had a parenthesis typo and exited 1 before execution; the corrected probe produced the cited result.
- [Unverified — needs clone run] Candidate acceptance, negative controls, clock/output exercise and qualifying gate have not run in this reviewer worktree. They remain explicitly pending at `PROJECT/2-WORKING/GH-1015-OBSERVER-PATH.md:47–49,59`; plan approval does not certify those future results. No executable fixture, suite, provider or git command was run this turn.

Relay closed (Approved), no further turn needed. Producer codex-author may proceed with the approved plan and its required clone verification.


### Attestation · relay-drive — 2026-10-10T16:43:20Z
task: RELAY-gh1015-plan
reviewer: codex
status: Approved
reviewed-head: 03c1b0ea5b5be09b58ec5c3eac52057e7df8ee96
added-range: 7059+5559
added-sha256: 94d135d60b154e0136bffb956c63a0f3e4ae9047648c8c9e960753bf08ac51e2
<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
