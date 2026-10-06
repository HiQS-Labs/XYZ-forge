# RELAY · GH-985 Claude continuation final QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-06.
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
6. **Commit only the relay file** (`relay(gh-985-claude-continuation-final-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **skills/2-daily/workhorse/SKILL.md** — the read-only path that
  `relay-drive.sh --artifact-file skills/2-daily/workhorse/SKILL.md` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: Fable   ·   Producer: Producer
- Started: 2026-10-06
- Definition of Done: full source sweep and cited acceptance/evidence review, no unresolved Blocker/Should, truthful runtime limits, PASS/Approved only when satisfied.

Final-review envelope: user-selected Fable low effort, independent of the earlier planner and Agy builder turns. Scope is 11 source additions / 3 deletions on top of parent PR #984 at aedc0726, plus required GH-985 governance and evidence. Read full SKILL.md and stop-hook.sh (not just diff), approved canonical plan and current SUMMARY.md, comparison-final.json, manual-hook-checks-final.json/provenance, final validator outputs and governance identity/route/outputs as needed. Intermediate comparison.json, manual-hook-checks.json and builder logs are historical receipts, not current acceptance. Current source hashes in comparison-final.json and final manual result must match. Do read-only JSON/hash inspection if helpful; do not run suites/gates/operational tests or git commands. Write only this relay; parent/harness owns commits.

Questions: Does guidance preserve the shared evidence/outcome audit, authorized feasible queue, optional/deferred distinction, independent-work-first blocker and pause/window boundaries? Is existing Python AST unchanged except reason and installer/frontmatter preserved? Are Claude Stop/cap/StopFailure/native /goal claims grounded and limits truthful (no semantic or live multi-turn guarantee, no implicit activation/mod/new gate)? Are completed checks current, non-empty, able to fail via witnessed controls; unresolved intermediate findings actually fixed? Does publication target development, declare #984 dependency and incremental comparison with no merge/deploy authorization? Are ratings 65/45/50/85 and scope commensurate? Do not demand unrequested new machinery. Grade concrete observed failures only.

TOKEN CLOSEOUT: For Approved, while still owning GH985-FINAL, call existing tick `done GH985-FINAL --agent Reviewer`; do NOT release/handoff an Approved token. Set NEXT Producer / STATUS Approved, append a nonempty Reviewer block with VERDICT PASS/FAIL/PARKED, Basis, cited sweep. Harness commits and mechanically attests. On non-approval, release to Producer with findings.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer · Round 1 (Fable, claude-fable-5-1, low effort — independent final QA)

**VERDICT: PASS**

swept file: yes — full `skills/2-daily/workhorse/SKILL.md` (1–382), full `stop-hook.sh` (1–53), full `install.sh` (1–58), plan doc, SUMMARY.md, comparison-final.json, manual-hook-checks-final.json, runtime-recon.md, runtime-capabilities.txt, governance identity/route/releases, validator outputs, CHANGELOG head, provenance.jsonl.

Probes (read-only, under `.relay-scratch/tmp`, discarded after this turn):
- `shasum -a 256` on SKILL.md / stop-hook.sh / install.sh → `5b05f30a…faef`, `4fbfb305…8de1`, `42a2401f…94f7`; identical to `comparison-final.json.source_hashes` and to `manual-hook-checks-final.json.skill_sha256`/`hook_sha256`. Final manual result and current source match.
- Independent AST probe: extracted the `<<'PY' … PY` heredoc from the parent-base hook (`aedc0726`, sha `b0463b25…9f79`, byte-identical at stack base `3c9bfa8c`) and the current hook, replaced only the string constant containing `open item(s)` with a placeholder, `ast.dump` compared → `ast_equal_except_reason: True`, rc=0. `bash -n stop-hook.sh` → ok. Confirms `python_ast_equal_except_reason: true` in the final manual JSON.
- Read-only diff vs `aedc0726` under `skills/2-daily/workhorse/`: 2 files, +11/−3 (SKILL.md +6; stop-hook.sh +5/−3). install.sh and frontmatter (`SKILL.md:1–29`, `hooks: Stop` block) untouched. Matches the declared scope.

Findings (whole file; current change first, then pre-existing):
- `[Pass]` Shared evidence/outcome audit, authorized-feasible queue, optional/deferred split, independent-work-first blocker, pause/window boundaries preserved — `SKILL.md:90` ("Select the highest-priority feasible required item… Mark `[x]` only with acceptance evidence; mark `[!]`… then finish independent authorized items"), `:99–107` (Evidence before ticking / Audit before ending), `:113–121` (Stop-only clause, "Finish independent authorized work first", deployment-window hold). Hook reason text mirrors it: `stop-hook.sh:45–48` ("Continue the next authorized feasible required item… Stop only for verified completion, explicit user pause/cancellation, or a concrete external blocker after independent authorized work is finished. [-] … does not reduce required scope").
- `[Pass]` Python decision/session/fail-open logic unchanged except the reason constant — probe above; `stop-hook.sh:14–21` (bad JSON / bad session id → `sys.exit(0)`), `:36–43` (missing checklist → `continue`), `:52` (`exit 0`).
- `[Pass]` Completed checks are current, non-empty, and able to fail: ten cases in `manual-hook-checks-final.json` at the matching hashes; `red_control.wording_assertion_exit: 1` with `"assertion": "required guidance absent: optional"` against the old reason, then `green_after_red` emits the new reason. Both intermediate findings (missing authorized-work wording; stop-only clause omitting external blockers) are present in the final text quoted above, so they are actually fixed, not just dispositioned.
- `[Pass]` Claude runtime claims are bounded and truthful: `SKILL.md:134–138` says the hook "cannot verify acceptance evidence", `/goal` is "when available and explicitly requested… still relies on model judgment and does not expand authorization"; `stop-hook.sh:7` "Do not change runtime controls". No semantic or live multi-turn guarantee is claimed — `manual-hook-checks-final.json.limits` and plan doc "Validation limits" (`GH-985-CLAUDE-WORKHORSE.md:121–124`) say so explicitly. StopFailure ignoring decision output is confirmed on the official hooks page ("StopFailure | No | Exit code and stderr are ignored"). The eight-continuation cap and `/goal` command are witnessed in local CLI 2.1.289 strings (`runtime-capabilities.txt`: `CLAUDE_CODE_STOP_HOOK_BLOCK_CAP??8`, `name:"goal"`). No mod, new gate, trust change or implicit activation anywhere in the diff.
- `[Nit]` Doc-citation drift, not a defect: three read-only fetches of `code.claude.com/docs/en/hooks` through the sandbox's summariser did not surface the phrases "user interrupt", "stop_hook_active" or "consecutive" that `runtime-recon.md` attributes to the official page (direct `curl` was network-denied, so this could be summariser truncation). The behaviour itself is witnessed in the CLI binary and the `hook-continuation` case (`stop_hook_active: true` input still blocks). No change requested; if the Producer wants belt-and-braces, cite the CLI string alongside the doc link in `runtime-recon.md`. Not a `[Should]`: no observed failure.
- `[Pass]` Publication: plan doc `GH-985-CLAUDE-WORKHORSE.md:22–23` targets `development`, names #984 as landing dependency, supplies incremental comparison (`comparison-final.json` base `aedc0726` → head `868399fe`), "No merge or deployment authorization is granted here." `governance-route.txt`: `route=docs`, `tier=1`; `governance-identity.json` before/after equal at `08014160`; releases `check: clean (0 failures, 9 warning(s))` all pre-existing `mig-ref-stale`/`release-target-passed`.
- `[Pass]` Ratings 65/45/50/85 (`GH-985-CLAUDE-WORKHORSE.md:116–119`) are commensurate: two-file wording change on an advisory Claude-only path, no evidenced loss. Scope matches +11/−3.
- `[Pass]` Raw `quick_validate` exit 1 is the pre-existing `hooks` frontmatter key only ("Unexpected key(s) in SKILL.md frontmatter: hooks"); metadata projection "Skill is valid!". Deliberately preserved per plan; not introduced by this change.
- Pre-existing sweep of the untouched 370 lines: no defects found. Relative links at `SKILL.md:144` (`../../1-hourly/sanity-check/SKILL.md`), `:220` (`skills/1-hourly/consult/SKILL.md`), `:289` (`../ci-debug/SKILL.md`) all resolve on disk. `SKILL.md:178` names foreign-repo paths (`src/rebalance/lib/`) as examples — pre-existing, cosmetic, out of this issue's scope; not graded.

Not run here (by rule): validate.sh, test suites, pytest, live Claude session. The exact-head pre-push gate and hosted CI remain the Producer/harness's step before PR readiness, as the plan already states.

**Basis:** Definition of Done met — full source sweep done and cited; no Blocker or Should; runtime limits stated truthfully in SKILL.md, hook comment, plan doc and evidence JSON; final evidence hashes match current source; decision logic provably unchanged; publication routing and dependency declared without merge/deploy authorization.

Token closeout: `tick done GH985-FINAL --agent Reviewer` (Approved — not released). Relay closed (Approved), no further turn needed; the harness commits this file and runs its gate.


### Attestation · relay-drive — 2026-10-06T23:21:42Z
task: GH985-FINAL
reviewer: Reviewer
status: Approved
reviewed-head: af59f1a4d716c71869d3d7f8d9e32e79080e2809
added-range: 7496+6645
added-sha256: 55eef3fbce2d9a50dd80e6e89000e1ca3bc5305854ba223772efc1e19eee33e9
<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
