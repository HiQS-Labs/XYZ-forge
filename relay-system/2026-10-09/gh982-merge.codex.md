# RELAY · GH982 current-development merge QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-09.
-->

NEXT: Producer
STATUS: Approved
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
6. **Commit only the relay file** (`relay(gh982-current-development-merge-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **.relay-artifacts/982-qa-packet.md** — the read-only path that
  `relay-drive.sh --artifact-file /Users/noelsaw/Documents/GH Repos/XYZ-forge/temp/merge-cleanup-2026-10-09/982-qa-packet.md` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: codex   ·   Producer: codex-producer
- Started: 2026-10-09
- Definition of Done: _<fill in the acceptance criteria the Reviewer grades against>_

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
Basis: The optional dashboard implementation remains suitable for the explicitly requested development landing, subject to the outstanding full merge-time gate. No new integration blocker or additional blocking pre-existing defect was found in the bounded source sweep. This is implementation approval only, not gate qualification or permission to merge without qualification.
swept file: yes

Acceptance is the five questions and local operational envelope in .relay-artifacts/982-qa-packet.md, rather than the unused Setup placeholder. Read the whole packet, all eight add-on files, canonical plan/recon, prior final relay and current SUMMARY/evidence; read the complete current Flightdeck server/aggregate/contract/connectors and both shared selectors, with the helper waitid span one level further out. Graph discovery returned no relevant symbols; coverage generation 2026-09-01T15:54:30Z belongs to the main checkout and reports these paths not tracked/missing or changed. Current worktree source and SHA-checked stored objects therefore supply the evidence, not graph completeness. No Git commands, servers, browser sessions, suites or executable fixtures were run. Only this relay file changed; probes and object-reader code stayed in .relay-scratch/tmp.

- [Pass] **Optional launch and bounded read surface remain intact.** preview.py:55–68, :81–82 require explicit launch, bind literally to 127.0.0.1 and configure/attach the aggregator only with --live. Demo snapshot GET is rejected at :38–42. Assets are a finite seven-route map (:21–29), foreign Host is rejected (:34–36), unknown routes return 404 (:44–47), and the shared headers carry no-store/CSP/nosniff/referrer policy (src/flightdeck/server.py:20, :27–35). The inherited handler owns the bounded 503 snapshot failure (:44–51); there is no producer write endpoint. Scope is the stated local developer preview, not an attestation of Internet-facing server capacity. Preserve this explicit launch/read boundary.

- [Pass] **Current Flightdeck contracts and conservative presentation agree.** app.js:1–3, :37–40, :82 call the current exported selectors; issueCards(repo, now, sourceHealthy) supplies workflow on every work card (web/flightdeck/issue-context.mjs:49–81), and laneIssues(lane, repo) resolves optional issue/PR context (:5–12). FlightdeckAggregator.snapshot supplies schema 1 and repo arrays plus coverage/truncation (src/flightdeck/aggregate.py:144–188); ConnectorConfig.from_environment remains the configuration owner (contract.py:96). Text insertion uses textContent (app.js:20); PRs require current-head QA (:74, :91), progress is unmeasured (:67, :92), expiry is recomputed every 30 seconds and polling has timeout/three-failure pause (:100–116). Card/row focus keys remain distinct (:66, :71, :84). No signature/state-shape incompatibility was exposed by integration. Retain shared selectors instead of introducing another projection.

- [Pass] **Both ancestry and complete scope were measured without Git.** Read-only Python object queries, command `PYTHONDONTWRITEBYTECODE=1 python3 -` with the SHA-verifying loose/packed reader under `$TMPDIR/objects.py`, exit 0, decoded c4ef7f3dbd2ed937150fd84d3aef0f0d2335946e with parents 7ea3c7d3c76a7225b790e2fafd635eb1ded8d1d2 and 47fb72dfcb13af1d0f64ed7d527a8db467171cbb. Decisive output: `PASS all 8 add-on working files match PR-head blobs`; `PASS 8 Flightdeck/shared/helper seam blobs identical in both parents and working tree`; `PASS 42 development differences are eight add-on files, GH981 docs/evidence/receipts, two parked observations, generated leaderboard and ledger`. Scope accounting includes PARKED/2026-10-06-codex-launcher.md, PARKED/2026-10-06-flightdeck-waitid.md and LEADERBOARD.md, not just the folder named in the packet. The latter adds the GH981 row and rank shifts, with generation 1551 (LEADERBOARD.md:1, :276); it exposes no lost development runtime bytes. The equality assertion also rejected an in-memory mutation: `EXPECTED RED byte-equivalence assertion rejects in-memory add-on mutation`. No file was mutated for that red control.

- [Pass] **Ledger integration preserves development and replays GH981 only.** Read-only `PYTHONDONTWRITEBYTECODE=1 python3 -` query, exit 0, deserialized binary blobs into in-memory SQLite and compared canonical SQL INSERT lines. Decisive output: `PASS every development non-settings binary row preserved`; `PASS every development non-settings canonical SQL INSERT preserved; added 9`. Binary delta is one GH981 roadmap row, three GH981 work events, five writer/rebuild receipts and the generation change 1546→1551; no existing roadmap/release/work row was removed or altered. The row retains ratings 55/20/50/65 and the canonical plan pointer; releases.sql:3, :16 record generation 1551. Generic executescript probes exited 1 because the canonical dump uses GID/natural-key grammar rather than the binary schema (notably repo_gid); those probes do not establish a product failure or SQL/binary rebuild qualification. The final passing preservation query replaces that invalid comparison. Full writer/rebuild qualification remains for the clone gate.

- [Pass] **Retained evidence supports its bounded claims and stays honest.** Read-only `PYTHONDONTWRITEBYTECODE=1 python3 -` hash/size query, exit 0: `PASS 24 nonempty evidence files match committed byte/hash receipts`; failure-name comparison, exit 0: `PASS same five named failures in retained candidate and baseline RED runs`. manual-boundary.txt:9–14 records the deliberately forced snapshot exception, bounded 503 and `EXPECTED RED source immutability assertion rejected a deliberately modified disposable fixture: source bytes changed`, then the restored passing check. SUMMARY.md:6 records the witnessed keyboard focus loss and repair; lanes-focus.txt:4 retains row focus. Attribution/license remain explicit (ATTRIBUTION.md:3–17; LICENSE.paperclip:1–21). These are inspected committed producer receipts, not freshly repeated HTTP/browser checks.

- [Unverified — needs clone run] **Full merge-time qualification remains outstanding.** SUMMARY.md:9–10 preserves the old five Darwin os.waitid failures and interrupted full gate; the same helper calls remain at utils/py/releases_cycle.py:85, :104. They are neither green nor a newly measured add-on regression. SUMMARY.md:6 and browser-checks.json:16 leave native Lanes timer focus unverified; source calls to the same render function do not prove browser timing. No fresh HTTP/browser run or canonical ledger rebuild was performed here. Run the required full gate in a disposable full clone against the final committed integration revision and record its actual result before a merge-readiness claim. Implementation PASS does not qualify that gate.

Relay closed (Approved), no further review turn needed. Handing the completion token to done; codex-producer owns the outstanding disposable-clone full qualification. The harness owns the one-file commit.

### Producer · Round 2 · codex-producer

Modified — protocol closure only. Round1 implementation PASS is retained verbatim, but driver exit4 rejected its closing token. Event log proves the reviewer released the task to literal actor `done`, leaving status=open and no owner; the shim could not complete it. Recovered this run's unclaimed token through its named handoff target, handed it back to producer, and now return it to codex. No product bytes changed; c4ef7f3d remains the integrated implementation ancestor.

Reviewer: confirm the prior source-backed verdict and this unchanged scope, append a substantive Round2 verdict, and close correctly. On approval set STATUS Approved and NEXT Producer, but **do not call tick release or hand off to an actor named done**. Keep the relay task claimed by codex; the existing shim owns the tick done operation after your file-scoped turn. Do not commit or run suites; the shim commits only this thread. The fresh full clone gate is still a producer obligation after review.

### Reviewer · Round 2 · codex

VERDICT: PASS
Basis: The implementation approval from Round 1 remains applicable to the packet's five acceptance questions and local optional developer envelope. This protocol-only round exposes no new implementation blocker or additional blocking pre-existing defect in the reviewed files. Full merge-time qualification remains outstanding; this approval is not gate qualification or a merge-readiness attestation.
swept file: yes

Read the complete seeded packet and relay, all eight add-on files, canonical plan, prior final QA and current SUMMARY/manual/browser receipts. Reread the renderer, launcher, shared presentation/issue selectors and Flightdeck server/aggregate/configuration seams. Round 1's broader connector/helper, ledger-preservation and complete ancestry/scope findings remain retained evidence, not freshly rerun checks. Graph lookup returned zero add-on symbols; coverage generation 2026-09-01T15:54:30Z is for the main checkout and reports missing/not-tracked paths, so current source supplies the material evidence. No Git commands, suites, executable fixtures, server or browser sessions ran. Only this relay file was edited.

- [Pass] **Optional launch/read boundary still meets the packet.** addons/paperclip-dashboard/preview.py:21–29 retains seven finite asset routes; :34–46 rejects foreign Host, demo snapshot reads and unknown routes; :64–68 binds 127.0.0.1 and attaches the shared aggregator only with --live. src/flightdeck/server.py:27–35 supplies no-store/CSP/nosniff/referrer headers and :44–51 supplies bounded snapshot failure. Preserve this explicit optional read boundary; no behavior change requested.
- [Pass] **Current shared signatures and conservative display remain aligned.** app.js:37–40 calls issueCards(repo, now, sourceHealthy), matching web/flightdeck/issue-context.mjs:49–81; app.js:93 calls laneIssues(item, repo), matching that module's :5–12. app.js:20 uses textContent; :66/:71 retain distinct card/row focus keys; :91–98 retains current-head QA, unmeasured progress and selectable handoff; :100–116 retains timeout, failure pause and independent expiry rendering. Attribution and MIT notice remain explicit at ATTRIBUTION.md:3–17 and LICENSE.paperclip:1–21. No additional blocking pre-existing defect was found in these complete add-on files.
- [Pass] **Producer's unchanged add-on scope is supported by a fresh narrow comparison.** Read-only command `PYTHONDONTWRITEBYTECODE=1 python3 -` (Path byte comparison and SHA1-checked loose commit decode), exit 0: `PASS eight nonempty add-on files byte-identical to producer checkout`; `EXPECTED RED same byte comparison rejects in-memory alteration`; candidate parents `7ea3c7d3c76a7225b790e2fafd635eb1ded8d1d2` and `47fb72dfcb13af1d0f64ed7d527a8db467171cbb`. Round 1's complete object and ledger-preservation comparisons remain the evidence for unchanged candidate runtime and development preservation. Two attempted loose-only tree queries exited 1 with FileNotFoundError for stored objects; they cannot independently re-attest packed-tree scope and are not product failures. No success is inferred from them.
- [Pass] **Retained red controls remain bounded and honest.** TESTS-RESULTS/2026-10-06+GH-981/manual-boundary.txt:9–14 retains demo denial, nonempty immutable live fixture, bounded 503 and `EXPECTED RED source immutability assertion rejected a deliberately modified disposable fixture: source bytes changed`, followed by restored success. These are inspected producer receipts, not repeated HTTP or fixture execution.
- [Unverified — needs clone run] **Qualification is still the producer's next obligation.** SUMMARY.md:9–10 retains five Darwin failures and the interrupted full run; browser-checks.json:16 leaves timer focus unverified. Run and record the required full gate against the final committed integration revision in a disposable full clone before claiming merge readiness. No fresh ledger rebuild or browser timer observation is attested here.

Relay closed (Approved), no further review turn needed. NEXT Producer identifies codex-producer as owner of outstanding disposable-clone qualification. Per the current user instruction, close with the actual env-pinned `tick done RELAY-gh982-merge --agent codex`; never release to an actor named done. This supersedes the Producer's embedded suggestion to leave completion to the shim. The harness owns the one-file commit.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
