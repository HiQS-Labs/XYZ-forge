# RELAY · GH-1020 final QA — reviewer close-mismatch fix
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-24.
-->

NEXT: done
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
6. **Commit only the relay file** (`relay(gh-1020-final-qa-reviewer-close-mismatch-fix): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: `PROJECT/2-WORKING/GH-1020-REVIEWER-CLOSE-MISMATCH.md` (the approved plan; also seeded at
  `.relay-artifacts/GH-1020-REVIEWER-CLOSE-MISMATCH.md`) together with the committed implementation in
  `relay-automation/relay-turn-lib.sh` and `src/scope.js` at the worktree head you are in.
- Branch: fix/XYZ-forge-gh1020-reviewer-close-mismatch-2026-10-24 (reviewed head = your worktree HEAD). Codex approved
  the plan in `relay-system/2026-10-24/gh1020-plan-qa.md` round 2. This is FINAL QA of code + evidence.
- Requirements source: https://github.com/HiQS-Labs/XYZ-forge/issues/1020 (second comment "Root cause found / Smallest
  fix" binding; Acceptance lines 1 and 4 binding) and https://github.com/HiQS-Labs/XYZ-forge/issues/763 (duplicate).
- Diff under review (`git diff origin/development..HEAD -- relay-automation/relay-turn-lib.sh src/scope.js`):
  `relay-automation/relay-turn-lib.sh` — inside `rtl_turn_prompt`'s reviewer branch (after `verify_note=''`), the
  `handoff` sentence is prefixed with: "if you set STATUS: Approved or Closed, close the token with: done <task>
  --agent <me> (never release --to done — done is a verb, not an agent); otherwise <peer | the role named by NEXT>".
  Builder prompt unchanged (gh505 case G). `src/scope.js` — `TERMINAL_WORDS = /^(done|approved|closed)$/i` and
  `release()` throws before `assertOwnership`/`emitEvent` when `to_agent` matches, message names `tick done <task>
  --agent <agent>`. Nothing else in runtime code changed.
- Evidence: `TESTS-RESULTS/2026-10-24+GH-1020/SUMMARY.md` and `provenance.jsonl` (sha256 per artifact);
  `before-fix-*` (red control: exit 4, `handoff-to: done`, the model's verbatim `release … --to done`);
  `check1-forced-replay/` (script + outputs: 25 PASS, 0 FAIL, guard-reverted red control);
  `check2-after-fix/` (real Codex approval on the fixed prompt: exit 0, attested, model ran `tick done`);
  `check3-after-fix/` (real Codex non-approval: exit 5, `release --to claude-a`); `focused-suites-7cbbeb5e.txt`.
- Ground-truth paths (read, do not grade): `relay-turn-lib.sh` `rtl_turn_prompt` :995-1080 and `rtl_enforce` step 4
  :1565-1615; `src/scope.js` :1-40, :84-110 (`assertOwnership`, `release`, `done`); `src/claim.js:45-60`;
  `bin/tick:315-333, 576-584`; `utils/py/relay_drive.py:402-420, 726-733, 777-782`; `test/gh505-relay-attest.sh:352-366`
  (case G); `test/gh681-reviewer-probe-rules.sh:45-60`; `test/relay-turn-handoff.sh`; `AGENTS.md` (No new tests, GH-831).
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-10-24
- Operational envelope: headless relay/marathon reviewer turns on one Mac through the shipped shims; `tick` is a local
  append-only event log. **Commensurate complexity:** grade against #1020 acceptance lines 1 and 4 and this envelope;
  do not ask for new state, retries, registries, schema changes, or test frameworks. GH-831: a new test file or
  registry entry in the diff would be a finding (there is none; `check1.sh` lives under `TESTS-RESULTS/`, not `test/`).
  `close-mismatch` in relay_drive.py is intentionally untouched.
- Definition of Done — answer each with a grade and `file:line` citations:
  1. **Acceptance line 1** (approving turn → header Approved, token done, exit 0, whether or not the model runs tick):
     does the code achieve it? Trace both branches: model runs `tick done` (check 2) and model runs the refused
     `release --to done` then the shim closes (check 1, incl. the `tick done after refused misfire` case). Is any branch
     left where ownership is lost before the shim's step 4?
  2. **Acceptance line 4** (no weakening of GH-505/509 attestation): confirm the diff touches neither
     `relay_drive.py` nor the attestation inputs; the verdict is still reviewer-appended bytes.
  3. **Codepaths match the plan:** exactly the two edits, prompt reviewer-only, guard before any event write, message
     content as planned; no second writer, no repair path, no new state.
  4. **Blast radius of the guard:** any legitimate `release --to` caller (`rtl_enforce`:1598, `marathon_drive.py`,
     `jog_run.py`, tests) passing a terminal word? Is case-insensitive matching (`approved`/`closed` lowercase too)
     acceptable, or over-broad? Is the compatibility limit stated where an operator will see it (error text, plan, PR)?
  5. **Pinned sentences:** gh681's reviewer sentence byte-identical; gh505 case G (builder prompt never says
     `STATUS: Approved`) — verify from the diff and the suite log.
  6. **Evidence substantiates the claims:** do the receipts show what SUMMARY.md says (check the sha256 rows, the
     before/after `tick info`, the model's exact tick commands, the red control)? Is anything claimed but not shown?
  7. **Rating** `85/82/50/80` still matches the evidence and effort actually spent?
  8. **Remaining gate:** the plan requires one tier-3 `ci-local.sh` run in a disposable `-gate` clone on the approved
     commit; it has NOT run yet and will run after your approval — is that the right order, and is anything else
     outstanding before a ready PR against `development`?
- Output: one Reviewer block with `swept file: yes|no`, graded findings (`[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`) each
  with a concrete fix; every `[Blocker]`/`[Should]` requesting a change carries `Observed input:` / `Affected scope:` /
  `Falsifier:`; then **VERDICT** (PASS / FAIL / PARKED) and **Basis**. Read-only probes allowed (`git diff`, `sed -n`,
  `grep`, `node -e` against a copy under `$TMPDIR`, `python3 -c` hash checks), output under `$TMPDIR`; do not run
  `validate.sh` or `test/*.sh`; do not post any comment.
- Token: when you approve, set `STATUS: Approved` and `NEXT: done`, then close the token with
  `tick done <task> --agent codex`. Never `tick release --to done`.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer · Round 1 — codex

Ship with conditions — approve the scoped code change; the final tier-3 gate remains due before a ready PR.

swept file: yes

Read the entire seeded plan, all 1,719 lines of `relay-automation/relay-turn-lib.sh`, all 207 lines of `src/scope.js`, the relevant callers/attestation path, and the retained receipts. No additional pre-existing code defects found in the reviewed files. The plan has one non-blocking chronology nit below. This review uses the binding [second operator comment on #1020](https://github.com/HiQS-Labs/XYZ-forge/issues/1020#issuecomment-6101865814) and [#763](https://github.com/HiQS-Labs/XYZ-forge/issues/763), not the superseded two-writer hypothesis. `plan` below means `.relay-artifacts/GH-1020-REVIEWER-CLOSE-MISMATCH.md`; `evidence` means `TESTS-RESULTS/2026-10-24+GH-1020/`.

- [Pass] **DoD 1 — Approval closes the observed failure mode.** The model-done branch is idempotent at `relay-turn-lib.sh:1592`; check 2 shows its exact `done` command (`evidence/check2-after-fix/codex-tick-commands.txt:3`), attestation (`drive.log:12`), exit 0 (`:24`) and token done (`:27`). The refused-misfire branch throws before ownership/event operations (`src/scope.js:97`–102); check 1 records unchanged events and retained codex ownership (`evidence/check1-forced-replay/results.txt:2`–16), then successful same-agent done (`:21`–22). With no model token command, the claim likewise remains available to the shim (`relay-turn-lib.sh:1594`–1600; existing `test/relay-turn-handoff.sh:44`–63). No ownership-loss branch remains for the terminal-word misuse under review. A model deliberately releasing to a real peer or doing a bare release can still lose ownership; that is outside this approved scope, as already stated at `relay-system/2026-10-24/gh1020-plan-qa.md:180`. No code fix requested.
- [Pass] **DoD 2 — Attestation stays intact.** Byte comparison with the connector-fetched `c5ef7a2e` base found `utils/py/relay_drive.py` unchanged. Its reviewer-role/shim-success checks (`:705`–715), canonical append-only check (`:716`–727), nonempty appended bytes (`:728`–729), token-done check (`:730`–732), and appended-byte digest (`:746`–748) remain. The changed prompt/guard add no attestation input. No fix requested.
- [Pass] **DoD 3 — Exactly the planned runtime edits.** Removing only the GH-1020 comment/handoff hunk from the current library reproduces base blob `25ab935f563923bb8a99fb998535f80c3923e273`; removing only the GH-1020 comment/guard hunk from scope reproduces base blob `a2b838b48e4cb1b9fa9d491e2a5023cca272c580`. Reviewer classification encloses the prompt edit (`relay-turn-lib.sh:1045`, `:1066`); the guard precedes `assertOwnership` and `emitEvent` (`src/scope.js:96`–102). The diagnostic names the task, claiming agent and correct verb. No new state, repair path or writer appears in either change. Keep the documented two-hunk rollback (`plan:91`); no fix requested.
- [Pass] **DoD 4 — Bounded compatibility change is acceptable.** Inspected release callers use configured peer/builder/reviewer values (`relay-turn-lib.sh:1605`; `utils/py/marathon_drive.py:3348`, `:3460`, `:3463`; `utils/py/jog_run.py:1546`) or ordinary peer controls (`test/gh505-relay-attest.sh:61`, `:117`; `test/relay-turn-handoff.sh:50`). None of those inspected legitimate calls hardcodes a terminal target. Case-insensitive exact-word matching (`src/scope.js:94`) consistently reserves done/approved/closed in every case; identities with those literal names lose release-target compatibility globally. The code comment (`:93`), runtime error (`:98`–99) and plan smallest-fix section (`plan:77`–82) disclose the boundary. Carry this limit into the PR as agreed in plan QA (`gh1020-plan-qa.md:164`–165). This is a bounded caller review, not an exhaustive identity inventory. No code fix requested.
- [Pass] **DoD 5 — Pinned wording and builder boundary.** The complete `role_note` assignment at `relay-turn-lib.sh:1067` is byte-identical to the base; only the reviewer handoff changes. Builder handoff initialization remains at `:999`–1000. Existing case G requires nonempty prompts and forbids the approval instruction in the builder prompt (`test/gh505-relay-attest.sh:362`–366); the receipt records that suite rc=0 (`evidence/focused-suites-7cbbeb5e.txt:9`–10), and gh681 rc=0 (`:11`–12). The retained log is an aggregate receipt, not individual case-G output. No fix requested.
- [Pass] **DoD 6 — Receipts support the bounded claims.** The integrity probe below found all 19 hashed artifacts nonempty and matching provenance. The before transcript really ran `release --to done` (`evidence/before-fix-codex-tick-commands.txt:3`–5), followed by the shim warning and refused approval (`before-fix-drive-run1.log:5`–6), exit 4 and handoff-to done (`:17`–23). Check 1 independently removes the guard, observes the bad release succeed and subsequent done fail, then restores it (`check1-forced-replay/check1.sh:47`–60; `results.txt:23`–28). Check 3 records the actual peer release (`check3-after-fix/codex-tick-commands.txt:3`–4), exit 5 and peer reservation (`drive.log:24`–30). Check 1 invokes `tick done` directly, not `rtl_enforce` or the driver (`check1.sh:40`–45); thus the forced-misfire-to-attestation chain has compositional source/existing-suite evidence, not a retained end-to-end driver run. SUMMARY accurately describes that limit. Do not describe check 1 as an observed driver-attested run; no additional code fix requested.
- [Pass] **DoD 7 — Rating remains reasonable.** `85/82/50/80` still fits an automation-stopping failure with bounded recovery, neutral appeal and two small runtime edits (`plan:123`–134). The receipts add a concrete Codex reproduction and the implementation has no schema or state migration. Verification cost does not enlarge the implementation. No score change requested; correct the chronology wording as the optional nit below.
- [Pass] **DoD 8 — Approval precedes the qualifying gate.** The plan explicitly schedules final QA, then the tier-3 run on the approved commit (`plan:36`, `:99`–101). That is the correct order. **[Unverified — needs clone run]** The final full gate has not run and PR readiness is not established by this approval. Producer must run `bash ci-local.sh` in the disposable `-gate` full clone, compare identity before/after, retain the qualifying receipt/provenance, and include the compatibility limit in the ready PR against `development`. A failure requires investigation and any code fix requires renewed review. No new suite, fixture framework or gate machinery is requested.
- [Nit] **Rating date windows do not match the listed older incidents.** `plan:126` names the comparison window as 2026-09-26..10-09, while `:129` includes incidents on September 23 and 24. Optional text correction: describe these as three earlier incidents across September 23–28, or recount the stated window (only the listed September 28 incident falls inside it). The numeric rating need not change; avoid presenting those counts as equal-window frequency evidence.

Read-only integrity probe (output `.relay-scratch/tmp/hashes.txt`):
```sh
python3 -B -c 'import json,hashlib,pathlib; rows=[json.loads(s) for s in pathlib.Path("TESTS-RESULTS/2026-10-24+GH-1020/provenance.jsonl").read_text().splitlines() if s.strip()]; assert len(rows)==19; blobs=[pathlib.Path(r["artifact"]).read_bytes() for r in rows]; assert all(blobs); assert all(hashlib.sha256(b).hexdigest()==r["sha256"] for b,r in zip(blobs,rows)); print("19/19 retained artifacts nonempty; SHA-256 matches provenance")'
```
Exit 0; decisive output: `19/19 retained artifacts nonempty; SHA-256 matches provenance`.

Source-comparison probe: `python3 -B -` read the three current source files, removed only the two specified GH-1020 hunks with one-match assertions, and calculated each Git blob SHA-1 (`sha1(b"blob "+str(len(b)).encode()+b"\0"+b)`) against the base blobs fetched via GitHub at `c5ef7a2e6cbb93fa41ba67da856815d856e28bb9`. Exit 0; decisive output: `relay-automation/relay-turn-lib.sh: matches c5ef7a2e base after removing only the planned hunk`; `src/scope.js: matches c5ef7a2e base after removing only the planned hunk`; `utils/py/relay_drive.py: byte-identical to c5ef7a2e base`. A separate literal assignment comparison returned `gh681_role_note_identical: true`. These are read-only byte comparisons, not runtime tests.

Graph limitation: Verify tier. `list_projects` paginated all 84 entries; this worktree is not registered. Nearest `XYZ-forge` points to another checkout with generation `2026-09-01T15:54:30Z`. The release lookup returned 1/1, no further page; its old line range predates this change. Coverage checked the cited runtime/caller paths: library/Python metadata changed, bin excluded, newer suites unavailable in that generation. Current source reads replace stale graph evidence; no graph completeness claim is made. No git commands, suites, pytest or executable fixtures were run in this turn. Only this relay file was edited.

VERDICT: PASS
Basis: The observed terminal-target ownership loss is prevented before any write, the reviewer prompt names the right verb, and current source plus falsifiable retained receipts support both closure paths without weakening attestation. Approval covers code QA; the specified qualifying full gate remains a prerequisite for ready-PR status.

Relay closed (Approved), no further turn needed. Producer (claude-a) proceeds to the disposable-clone gate and ready-PR closeout.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
