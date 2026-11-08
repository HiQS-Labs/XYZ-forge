# RELAY · GH-1020 plan QA — reviewer close-mismatch fix
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-24.
-->

NEXT: done
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
6. **Commit only the relay file** (`relay(gh-1020-plan-qa-reviewer-close-mismatch-fix): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: `PROJECT/1-INBOX/GH-1020-REVIEWER-CLOSE-MISMATCH.md` (the plan; also seeded read-only at
  `.relay-artifacts/GH-1020-REVIEWER-CLOSE-MISMATCH.md`). This is a PLAN review; no fix code exists yet.
- Requirements source (read in full first): https://github.com/HiQS-Labs/XYZ-forge/issues/1020 (body + the two
  operator comments: the second comment's "Root cause found" and "Smallest fix" are the binding requirement;
  "Acceptance" lines 1 and 4 are binding, line 2 (row 4, header left Open) and proposal 3 are out of scope here) and
  https://github.com/HiQS-Labs/XYZ-forge/issues/763 (duplicate of the same mode; closed by the same PR).
- Ground-truth paths (read, do not grade): `relay-automation/relay-turn-lib.sh` (`rtl_turn_prompt` :995-1075, esp. the
  `handoff` string :999-1000 and the `role_note` sentence :1047; `rtl_enforce` step 4 :1559-1608),
  `relay-automation/codex-turn.sh:30-36,100` (RELAY_PEER is read from env only), `utils/py/relay_drive.py:402-420`
  (`token_state`), `:726-733` and `:777-782` (close-mismatch), `src/scope.js` (`assertOwnership`, `release`, `done`),
  `src/claim.js` (`claim`: the "Reserved for someone else" branch), `bin/tick:117,159,315-333`,
  `test/gh681-reviewer-probe-rules.sh:45-60` (pins the role_note sentence), `test/gh554-tick-unknown-flags.sh`
  (precedent: tick refuses a misuse), `TESTS-RESULTS/2026-10-24+GH-1020/` (today's before-fix reproduction: driver
  log, tick info before/after, the model's exact `tick release ... --to done` command, the relay thread it wrote),
  `AGENTS.md` (No new tests, GH-831).
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-10-24
- Operational envelope: a headless relay/marathon reviewer turn on one Mac, driven by `relay-drive.sh` through the
  shipped shims; one token per thread; `tick` is a local append-only event log. **Commensurate complexity:** grade
  against #1020's acceptance lines 1 and 4 and this envelope. Do not ask for new state, retries, a token registry,
  schema changes, or test frameworks. GH-831: a plan step that adds a test file or registry entry is itself a finding.
  Keep `close-mismatch` (relay_drive.py) as is — it is the safety property.
- Definition of Done — answer each with a grade and `file:line` / issue-section citations:
  1. **Grounded?** Does the plan's "Observed" section match the cited source: the `handoff` string when RELAY_PEER is
     unset, that relay-drive never sets RELAY_PEER, the `role_note` sentence, `assertOwnership` failing after a
     release, `claim` refusing an open token reserved for another agent (so no in-place repair exists), and the
     receipt in `TESTS-RESULTS/2026-10-24+GH-1020/`?
  2. **Does edit 1 (prompt) remove the trigger** without breaking any pinned sentence (gh681) or the non-approval path
     (`release --to <peer>` / the agent named by NEXT)? Is the proposed wording unambiguous for a model that reads
     both the `handoff` sentence and the `role_note` sentence?
  3. **Does edit 2 (tick guard: `release --to done|Approved|Closed` refused in `src/scope.js release()`) make
     acceptance line 1 true "whether or not the model also runs tick itself"?** Trace the sequence: model runs the
     refused command → still owner → shim `rtl_enforce` step 4 runs `tick done` → driver attests. Name any input where
     the guard is wrong (an agent legitimately named `done`?) or where ownership still changes hands.
  4. **Smallest change / no duplicate writer:** is a tick-layer guard the right home (precedent #554) versus
     prompt-only or a shim-side repair? Is anything in the plan beyond the two edits?
  5. **Blast radius:** who else calls `tick release --to` (`rtl_enforce`, `marathon-drive`, `relay-drive`, tests)?
     Does any legitimate caller pass a terminal word as the target?
  6. **Verification plan:** focused suites named, tier-3 full gate in a disposable clone once, and a manual before/after
     receipt with a red control (the before run) — truthful under GH-831? What is missing to falsify the claim?
  7. **Rating** `85/82/50/80` (pri/sev/appeal/effort; effort = cheapness; appeal must be 50) and the recurrence
     evidence (3 incidents 2026-09-23..28, 6 in 2026-10-10..14, 1 reproduction today) — defensible?
  8. **Non-goals:** row 4 (header left Open), proposal 3 (marathon retry), loosening close-mismatch — correctly excluded?
- Output: one Reviewer block with `swept file: yes|no`, graded findings (`[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`) each
  with a concrete fix; every `[Blocker]`/`[Should]` requesting a change carries `Observed input:` / `Affected scope:` /
  `Falsifier:`; then **VERDICT** (PASS / FAIL / PARKED) and **Basis**. Read-only probes allowed (`sed -n`, `grep`,
  `node -e`, `gh issue view`), output under `$TMPDIR`; do not run `validate.sh` or `test/*.sh`; do not post any comment.
- Token: when you approve, set `STATUS: Approved` and `NEXT: done`, then close the token with
  `tick done <task> --agent codex`. Never `tick release --to done` (that is the defect under review).

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer · Round 1 — codex

Block — the two-edit design is sound for the observed failure, but its verification must force the bad command rather than depend on the model repeating it.

swept file: yes

Reviewed the entire 109-line seeded plan, including frontmatter, alternatives, verification and rating. The factual overstatements found in that sweep are noted below; no other pre-existing plan defects found within this scope. This is plan QA, not implementation approval.

- [Should] **S1 — Make the guard independently falsifiable.** `.relay-artifacts/GH-1020-REVIEWER-CLOSE-MISMATCH.md:93` only promises another real-model approval. Once edit 1 works, that model can use `tick done`, so this check passes even if edit 2 is absent. The named GH-554 suite exercises unknown flags, not a valid `--to done` (`test/gh554-tick-unknown-flags.sh:52`); the existing handoff suite starts with a worker that never releases (`test/relay-turn-handoff.sh:44`). Fix the verification paragraph: in the disposable full clone, deliberately replay the retained `release ... --to done` command while the reviewer owns the token; require nonzero exit, a diagnostic naming `done`, unchanged event count and reviewer ownership, then existing shim closure and driver attestation/exit 0. Check the two other words the plan explicitly rejects, and retain ordinary peer/no-target release controls. Record commands, nonempty outputs, revision and provenance in the existing GH-1020 evidence directory; no new suite, registry entry or gate is needed. Keep the real-model rerun as the prompt check. Replace the ambiguous `test/gh67-*` shorthand (which matches unrelated GH-674/GH-678 suites) with the actual `test/relay-turn-handoff.sh`.
  Observed input: `TESTS-RESULTS/2026-10-24+GH-1020/before-fix-codex-tick-commands.txt:3` records the exact `release RELAY-gh1020-repro-073438 --agent codex --to done`; line 5 records `released: RELAY-gh1020-repro-073438`.
  Affected scope: the verification of edit 2 and acceptance line 1's model-runs-tick branch; no additional runtime behavior requested.
  Falsifier: with the prompt fixed but the guard removed, the forced command must succeed, lose ownership and fail closure; with the guard present it must refuse before any release event and permit shim closure. A passing prompt-only rerun cannot discharge this check.
- [Pass] **Grounding / DoD 1.** The observed failure matches `relay-turn-lib.sh:999`, `:1060`, `:1587`, `src/scope.js:31`, `:89`, `:121`, and `relay_drive.py:730`. The Python default also uses this same Bash prompt (`utils/py/codex-turn.py:43`, `:53`; `utils/py/rtl.py:849`); driver dispatch sets file/task/actor/role without assigning RELAY_PEER (`utils/py/relay_drive.py:830`). The retained driver log reports the ownership WARN, refusal and exit 4 at `before-fix-drive-run1.log:5`, `:6`, `:17`. No change needed to that causal chain. The binding [second operator comment, Root cause found / Smallest fix](https://github.com/HiQS-Labs/XYZ-forge/issues/1020#issuecomment-6101865814) independently describes it.
- [Nit] **N1 — Qualify the recovery claim.** Plan lines 61–62 say “Nobody can ever own that token again; the only recovery is a fresh token id.” `src/claim.js:52` only rejects a *different* agent: an identity literally named `done` would satisfy that predicate. Fix the prose to say the configured reviewer cannot normally reclaim it and a fresh token is the supported recovery; do not add such a repair path. The same caveat applies to “impossible” at line 81.
- [Pass] **Prompt / DoD 2.** Plan lines 65–69 explicitly choose the terminal verb and retain peer release otherwise. Implement that conditional for both peer-present and peer-absent prompt branches (`relay-turn-lib.sh:999`–1000); keep the reviewer sentence at `:1060` unchanged, as pinned by `test/gh681-reviewer-probe-rules.sh:51`. No additional prompt surface is required.
- [Pass] **Guard placement and sequence / DoD 3–4.** `src/scope.js:89` is the existing release mutation boundary, before `emitEvent` at line 91. Refusal there leaves the claim available for the existing `rtl_enforce` terminal branch (`relay-turn-lib.sh:1587`–1593), after which the driver's existing token/role/byte attestation remains authoritative (`relay_drive.py:705`, `:718`, `:730`). This is a design trace; execution remains **[Unverified — needs clone run]**. The #554 refusal precedent is visible at `bin/tick:103`. Keep exactly the two proposed runtime edits; no shim repair, second writer or weakening of close-mismatch.
- [Pass] **Blast radius / DoD 5.** The guard applies to every caller of release, not just reviewers: CLI dispatch (`bin/tick:327`), shim peer handoff (`relay-turn-lib.sh:1598`), marathon seeding/routing (`utils/py/marathon_drive.py:3348`, `:3460`), Jog seeding (`utils/py/jog_run.py:1546`), and existing tests (`test/relay-review-once.sh:34`). These inspected callers target configured agents or ordinary peer identities; no legitimate literal terminal target was found in the searched source. Dynamic user-selected identities remain possible: this intentionally disallows release targets named `done`, `Approved`, `Closed`; acknowledge that compatibility limit, without inventing an agent registry. An approving model that releases to a real peer can still relinquish ownership; the guard's guarantee is specifically the observed terminal-target misuse. Costly shared coordination surface, with the plan's two-hunk revert as rollback (`plan:83`).
- [Pass] **Gate and scope / DoD 6, 8.** Existing suites plus a manual receipt and a single final full gate in a disposable clone respect GH-831 (`AGENTS.md:154`; plan lines 85–97). `utils/ci-route.sh:339` and `:342` require the full route for both changed surfaces. Header-left-Open, marathon retry and attestation relaxation are correctly excluded (plan lines 77–82; [issue #1020, Acceptance / Non-goals](https://github.com/HiQS-Labs/XYZ-forge/issues/1020)). No suites, pytest, executable fixtures or git commands were run in this reviewer turn.
- [Nit] **N2 — Separate mixed-mode incident counts / DoD 7.** The proposed `85/82/50/80` is defensible for a repeated halt with bounded recovery and two small edits, and appeal is correctly 50 (plan lines 101–109). But “2026-10-10 ×5” as five instances of this class overstates [#1020's Observed table](https://github.com/HiQS-Labs/XYZ-forge/issues/1020): rows 1–3 are close mismatch, row 4 is the excluded header defect, row 5 is retry fallout. The second comment adds a Codex reproduction. Fix the wording to distinguish those counts; avoid “every reviewer model” beyond the observed Agy/Codex seats. The three older receipts are supported by [#763, Observed](https://github.com/HiQS-Labs/XYZ-forge/issues/763), `relay-system/2026-09-24/gh796-plan-qa.md:99`, and `relay-system/2026-09-28/gh879-n5-final-qa-r2.md:63`; #1081's Prerequisites records the later factory occurrence. No rating change required solely for this correction.

Evidence query (read-only; output in `.relay-scratch/receipt-audit.txt`):
```sh
python3 -B -c 'import json,hashlib,pathlib; rows=[json.loads(s) for s in pathlib.Path("TESTS-RESULTS/2026-10-24+GH-1020/provenance.jsonl").read_text().splitlines() if s.strip()]; assert len(rows)==5; blobs=[pathlib.Path(r["artifact"]).read_bytes() for r in rows]; assert all(blobs); assert all(hashlib.sha256(b).hexdigest()==r["sha256"] for b,r in zip(blobs,rows)); print("5/5 retained artifacts nonempty; SHA-256 matches provenance; before rc="+str(rows[0]["exit_code"]))'
```
Exit 0; decisive output: `5/5 retained artifacts nonempty; SHA-256 matches provenance; before rc=4`. This verifies retained receipt integrity, not post-fix execution. GitHub CLI and web fetch failed, but connected GitHub reads subsequently retrieved the full #1020 body and both comments, #763 body and #1081 body. Graph discovery subsequently became available: nearest registered project `XYZ-forge`, generation `2026-09-01T15:54:30Z`, is a different checkout with changed metadata on the prompt/Python paths and excluded `bin/`; coverage checked, source fallback used. Graph inbound trace was unavailable, so caller claims above are bounded source inspection, not exhaustive graph claims.

VERDICT: FAIL
Basis: S1 leaves the guard's acceptance claim untested if the corrected prompt succeeds. Add the forced-command manual check to the plan and correct N1/N2; the runtime design can stay at two edits.

Handing off to Producer (claude-a) — address S1 and disposition N1/N2, then return for Round 2.

### Producer · Round 2 — claude-a

Dispositions for Round 1 (plan revised in `PROJECT/1-INBOX/GH-1020-REVIEWER-CLOSE-MISMATCH.md`, re-seeded as the artifact):

- **S1 — Implemented.** "Verification" now lists three manual checks. Check 1 is the forced replay of the retained
  `tick release <task> --agent codex --to done` while codex owns a token: required non-zero exit, diagnostic naming
  `done` and the right verb, `.tick/events` count unchanged, `tick info` still `claimed` by codex; same for `--to Approved`
  / `--to Closed`; controls `--to claude-a` and bare `release` still succeed with one `task.released` each; then the shim's
  step-4 closure and driver attestation. Red control: the same replay with the guard hunk reverted succeeds and loses
  ownership. Check 2 is the real-model rerun (prompt check only). The plan states explicitly that check 2 cannot discharge
  check 1. `test/gh67-*` shorthand replaced with `test/relay-turn-handoff.sh`. All recorded under the existing
  `TESTS-RESULTS/2026-10-24+GH-1020/` with provenance; no suite, registry entry or gate.
- **N1 — Implemented.** Recovery claim qualified: the configured reviewer (any real agent) cannot reclaim it; only an
  identity literally named `done` could; fresh token id is the supported recovery; no repair path added. "impossible"
  reworded accordingly in the alternatives.
- **N2 — Implemented.** Recurrence now counts only this mode: 5 recent (#1020 rows 1–3 Agy, #1020 Codex comment,
  #1081), rows 4–5 excluded as a different mode; 3 earlier (#763, gh796:99, gh879:63, all Agy); "every reviewer model"
  replaced with "both observed reviewer seats (Agy, Codex)". Rating unchanged at 85/82/50/80.
- Blast-radius note from your [Pass] (release targets literally named `done`/`Approved`/`Closed` become invalid for every
  caller) is accepted as a documented compatibility limit; it will be stated in the guard's error text and the PR.

Reviewer: please re-review the revised plan (same DoD). Token: on approval set `STATUS: Approved`, `NEXT: done`, then
`tick done <task> --agent codex`; never `tick release --to done`.

### Reviewer · Round 2 — codex

Ship — approve the revised plan for implementation; execution evidence remains due.

swept file: yes

Re-read the entire 128-line seeded artifact, including frontmatter, observed chain, alternatives, verification and rating, against the full #1020 body/both operator comments and #763. S1, N1 and N2 are addressed. No additional pre-existing plan defects requiring changes found. Citations below use `plan` for `.relay-artifacts/GH-1020-REVIEWER-CLOSE-MISMATCH.md`.

- [Pass] **DoD 1 — Grounding.** The conflicting instructions are present at `relay-automation/relay-turn-lib.sh:999` and `:1060`; `relay-automation/codex-turn.sh:100` reads the optional peer, while `utils/py/relay_drive.py:830` dispatches without assigning it. The Python default also reaches this Bash prompt (`utils/py/codex-turn.py:53`, `utils/py/rtl.py:849`). Release emits an ownership-losing event (`src/scope.js:89`), `done` requires ownership (`:121`, `:31`), and reclaim by the reviewer is reserved away (`src/claim.js:52`). N1 is now qualified at plan:58–64. Retained reproduction: `TESTS-RESULTS/2026-10-24+GH-1020/before-fix-drive-run1.log:5` and `:6`, with the exact bad command at `before-fix-codex-tick-commands.txt:3`. No causal-chain change needed.
- [Pass] **DoD 2 — Prompt.** Plan:66–70 explicitly distinguishes terminal `done <task> --agent <me>` from ordinary peer release and forbids `done` as a target. Apply that wording in both existing handoff branches (`relay-turn-lib.sh:999`–1000); preserve the pinned reviewer sentence (`test/gh681-reviewer-probe-rules.sh:51`). This resolves the ambiguity without changing the non-approval protocol.
- [Pass] **DoD 3–4 — Guard and smallest design.** Plan:71–76 puts refusal before the existing release mutation (`src/scope.js:91`), retaining the claim for `rtl_enforce`'s terminal branch (`relay-turn-lib.sh:1587`). The driver still requires token done and reviewer-appended bytes (`utils/py/relay_drive.py:727`–732); do not change it. The existing CLI misuse refusal is precedent (`bin/tick:103`). Exactly two runtime edits, no repair writer or new state; plan:85 supplies rollback. This shared coordination change is **Costly** because all release callers see the guard. Its guarantee is the observed terminal-target misuse, not arbitrary release to a real peer. Runtime outcome: **[Unverified — needs clone run]**.
- [Pass] **DoD 5 — Blast radius.** Inspected CLI dispatch (`bin/tick:327`), shim (`relay-turn-lib.sh:1598`), marathon seeding/review routing (`utils/py/marathon_drive.py:3348`, `:3460`), Jog (`utils/py/jog_run.py:1546`) and relay controls (`test/relay-review-once.sh:34`). These target configured agents or ordinary peers; no inspected legitimate caller uses a literal terminal target. Producer's Round 2 compatibility disposition is accepted: identities literally named `done`, `Approved`, `Closed` become invalid release destinations globally; retain that disclosure in implementation error text/PR. This is bounded source inspection, not an exhaustive caller proof.
- [Pass] **DoD 6 / S1 — Independently falsifiable verification.** Plan:98–106 now forces each rejected target, requires nonzero exit, a useful diagnostic, unchanged event count and retained reviewer ownership, retains peer/no-target controls, and exercises shim closure plus driver attestation. Removing only the guard must make the bad release succeed and closure fail. Plan:112–113 explicitly forbids substituting the prompt rerun for this check. Focused suites are named correctly (plan:89–92); final tier-3 gate and identity checks are in a disposable full clone (plan:93–97), consistent with `utils/ci-route.sh:339`–342 and GH-831. No new suite/registry/gate requested. Keep all manual receipts/provenance in the named evidence directory. These are adequate planned checks, not results already earned.
- [Pass] **DoD 7 / N2 — Rating and recurrence.** Plan:117–128 preserves `85/82/50/80`, neutral appeal and bounded recovery. It separates five recent close-mismatch reports from the excluded row-4/header and row-5/retry modes, plus today's reproduction. The source is [#1020 Observed and second operator comment](https://github.com/HiQS-Labs/XYZ-forge/issues/1020), [#1081 Prerequisites](https://github.com/HiQS-Labs/XYZ-forge/issues/1081), and the three older incidents ([#763 Observed](https://github.com/HiQS-Labs/XYZ-forge/issues/763), `relay-system/2026-09-24/gh796-plan-qa.md:99`, `relay-system/2026-09-28/gh879-n5-final-qa-r2.md:63`). No rating change needed.
- [Pass] **DoD 8 — Non-goals.** Plan:15–19, :78–84 excludes header-left-Open, marathon retry, builder self-attestation and weakening close-mismatch, consistent with the binding [Root cause found / Smallest fix comment](https://github.com/HiQS-Labs/XYZ-forge/issues/1020#issuecomment-6101865814). Keep those exclusions.

Read-only receipt-integrity probe (output `.relay-scratch/round2-hashes.txt`):
```sh
python3 -B -c 'import json,hashlib,pathlib; rows=[json.loads(s) for s in pathlib.Path("TESTS-RESULTS/2026-10-24+GH-1020/provenance.jsonl").read_text().splitlines() if s.strip()]; assert len(rows)==5; blobs=[pathlib.Path(r["artifact"]).read_bytes() for r in rows]; assert all(blobs); assert all(hashlib.sha256(b).hexdigest()==r["sha256"] for b,r in zip(blobs,rows)); print("5/5 retained artifacts nonempty; SHA-256 matches provenance; before rc="+str(rows[0]["exit_code"]))'
```
Exit 0; decisive output: `5/5 retained artifacts nonempty; SHA-256 matches provenance; before rc=4`. This establishes retained before-receipt integrity only. No tests, executable fixtures, pytest, validate or git commands were run.

Graph evidence: Verify tier; `list_projects` returned all 84 entries, no current worktree registration. Nearest `XYZ-forge` is a different checkout, generation `2026-09-01T15:54:30Z`. Search of scope symbols returned 3/3, no further page; exact release snippet obtained. Coverage checked for the cited code paths; prompt/Python paths have changed metadata, `bin/` is excluded, and newer suites are not tracked in that generation. Direct source used for current claims. Call tracing was unavailable under the approval policy; no completeness inference made.

VERDICT: PASS
Basis: The revised verification can independently falsify the guard, the recovery/recurrence overstatements are corrected, and the two-edit design meets the scoped requirements without weakening attestation. Approval covers the plan only; implementation and clone-run receipts remain outstanding.

Relay closed (Approved), no further review turn needed. Producer (claude-a) may proceed with implementation and the specified verification.


### Attestation · relay-drive — 2026-10-24T14:52:10Z
task: RELAY-gh1020-plan-qa-074239
reviewer: codex
status: Approved
reviewed-head: 781489adceaa268cc61b55457d308b783bf1c3e4
added-range: 20769+6699
added-sha256: 13ce28608a92e141653a1bb57b77e2cca948d7e7b08001cdc8964f7ca6c1694f
<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
