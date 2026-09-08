---
title: "GH-505 / GH-509: Approved means a reviewer approved — driver-attested terminal status"
status: In progress
created: 2026-09-08
updated: 2026-09-08
owner: agent-b
goal: relay-drive is the only process that can make STATUS Approved count — it knows the reviewer from its own invocation, attests only an approval it watched a reviewer-role turn write, stamps that attestation with the reviewed head and a digest of the reviewer's block, and every consumer (jog, marathon recovery, jog's merge) trusts the attestation rather than the word in the file
gh_issue: 505
source: https://github.com/HiQS-Labs/XYZ-forge/issues/505
branch: fix/gh505-relay-reviewer-integrity
base_sha: a6441b9b
doc_type: defect
related:
  - https://github.com/HiQS-Labs/XYZ-forge/issues/509
  - https://github.com/HiQS-Labs/XYZ-forge/issues/510
  - https://github.com/HiQS-Labs/XYZ-forge/issues/482
context_tags: [relay, review-integrity, governance, merge-gate]
non_goals:
  - Cryptographic signing, key management, or authenticating tick events (#509 option 3 — key isolation is not achievable on one host where agy runs unsandboxed)
  - Running the reviewer in a container or read-only checkout (#509 option 4)
  - Quorum review (#509 option 5)
  - Defending against arbitrary same-user host code outside the dispatch/containment contract (agy-turn.sh runs unsandboxed; anything it can write, a hostile agy turn can write)
  - Bridging relay-reviewer identity to GitHub-reviewer identity; branch protection; a second PR reviewer (operator-excluded)
  - Binding the merge in express.py, merge_cleanup.py and marathon-closeout.sh — none of them owns a relay task name to look an attestation up by; recorded as a limitation, not silently skipped
  - Changing the relay turn protocol, token model, or round-cap semantics
effort: 40
complexity: 4
risk: 4
phases: 4
---

# GH-505 / GH-509 — driver-attested approval

## Status

| What was just completed | What's next |
|---|---|
| Design v2 chosen by the operator from the six #509 options: **2 + 1** — roles from the invocation, driver as the only writer of a *counting* verdict, stamp as the evidence. Prior plan's three QA rounds are in `relay-system/2026-09-08/gh505-reviewer-integrity-plan-qa.md`; their accepted decisions are carried, their open B1/B2/F1/F2 are answered below | Codex plan QA on this revision (fresh thread, 3-round cap), then implement in the phase order below |

## Issue map

| Issue | Scope in this PR | Acceptance |
|---|---|---|
| [#505](https://github.com/HiQS-Labs/XYZ-forge/issues/505) | Phases 0, 2, and the consumer wiring in 3 | builder-written `STATUS: Approved` is refused and reverted; the shared prompt no longer tells a builder to approve; jog no longer overrides the driver |
| [#509](https://github.com/HiQS-Labs/XYZ-forge/issues/509) | Phase 1 (the anchor) and Phase 3 (consumers trust the attestation) | a terminal status counts only when this driver run watched a reviewer-role turn write it; the attestation names head + digest; marathon recovery and jog's merge read the attestation, not the word |
| [#510](https://github.com/HiQS-Labs/XYZ-forge/issues/510) | folded into Phase 3 because the head binding rewrites the exact lines | a refused merge parks; a missing PR parks |

Ratings: #505 `85/85/50/55`, #509 `75/85/50/25`, #510 `70/70/50/90` — all persisted in the ledger; rationale in each issue's inbox doc / issue body.

## Why the previous plan blocked, in one paragraph

Every anchor I proposed lived somewhere the reviewed party could write: the in-file directive
(round 1), the tick log (round 2). Round 3 accepted the only thing a turn cannot write — the
driver's own memory of what it dispatched — and blocked on two consequences I had not closed:
containment still read the writable directive to decide *permissions* (B1), and the merge was
not bound to the head that was reviewed (B2). This revision closes both by making the driver's
knowledge flow *outward* (env to containment, attestation to consumers) instead of asking
anything to flow *inward* from the file.

## The design in five sentences

1. `relay_drive.py` learns the reviewer from `--reviewer` (or from `--review-once`, where the
   single turn *is* the reviewer) and never from the relay file or the token.
2. Before each turn it exports `RELAY_ROLE=reviewer|builder`; `rtl_is_reviewer_turn` treats that
   as authoritative and only falls back to the directive / `NEXT:` prose when it is unset.
3. After each turn: a terminal `STATUS:` that appeared during a **builder**-role turn is reverted
   to its pre-turn value and the relay is escalated `forged-terminal`; one that appeared during a
   **reviewer**-role turn whose block is non-empty is **attested** — the driver appends an
   `### Attestation · relay-drive` block (reviewer id, reviewed head SHA, sha256 of the bytes the
   reviewer appended), commits it file-scoped, and mirrors the same three fields to
   `<git-common-dir>/relay-attest/<relay-task>.json`.
4. The driver exits 0 on a terminal status **only if it attested it in this process**; a file
   that is already terminal at startup, or becomes terminal any other way, escalates
   `unattested-terminal`.
5. Consumers stop reading the word: jog deletes its override; marathon's three post-hoc
   "already terminal" probes require the attestation file; jog's merge passes
   `--match-head-commit <approved-head>` from it.

What the attestation is and is not: it is evidence the *driver* observed, written where turns
under containment do not write. It is not a signature. A same-user host process can forge the
mirror file; that is the stated non-goal, and the driver's own exit code never depends on the
file — only on memory.

## Implementation

### Phase 0 — delete the jog override (#505)

`utils/py/jog_run.py:1375-1389`. Replace the whole `if proc.returncode != 0:` block with
`return proc.returncode`. The comment it carried ("a terminal STATUS on the relay file IS
success") is the bug in prose.

Check: `test/gh505-relay-attest.sh` case J — `run_single_phase_drive` with a stub driver that
exits 4 and a relay file reading `STATUS: Approved` returns 4. Red at base (returns 0).

### Phase 1 — driver-attested terminal status (#509)

`utils/py/relay_drive.py`, the canonical writer (`relay-drive.sh:18` is an `exec` shim; the
gh308 twin guard is unaffected because the shell file is untouched).

1. Args (`:30-41`): add `--reviewer` (agent id). `--review-once` without `--reviewer` is
   legal and means "the dispatched actor is the reviewer". Neither given → the run can never
   accept a terminal status; say so once on stderr at startup so the misconfiguration is a
   one-line read, not a silent escalation six turns later.
2. Role per turn (`:619`, beside `RELAY_AGENT`): `role = "reviewer" if args.review_once or
   (args.reviewer and actor == args.reviewer) else "builder"`; `os.environ["RELAY_ROLE"] = role`.
   Record `pre_len = os.path.getsize(relay_file)` and `pre_status = s` next to `rfsig`.
3. `attested = {}` in driver memory (module-level dict beside `cost_summary_state`).
4. Post-turn (`:820-823`, after `ns = file_status()`), one new function `judge_terminal(ns)`:
   - not terminal → return.
   - `role == "builder"` → rewrite the first `STATUS:` line back to `pre_status`, append
     `### System · relay-drive\nterminal STATUS written by builder-role turn (<actor>) — reverted`,
     `exit_escalate("forged-terminal")` (exit 4, same path as close-mismatch).
   - `role == "reviewer"` and `getsize(relay_file) <= pre_len` → the reviewer approved without
     writing anything: `exit_escalate("empty-approval")`.
   - `role == "reviewer"` → `block = file bytes[pre_len:]`, `digest = sha256(block)`,
     `head = get_head_commit()`; append the attestation block; `git add` + `git commit -m
     "relay-drive: attest <task> approved by <actor> at <head>" -- <relay_file>` when tracked
     (mirrors the consult-verify commit at `:812-813`); write the JSON mirror; set
     `attested = {"status": ns, "head": head, "digest": digest, "by": actor}`.
5. Terminal exits: loop top (`:571-579`), review-once (`:830-833`), post-loop (`:868-871`) —
   each `terminal_status(...)` success path additionally requires `attested`; otherwise
   `exit_escalate("unattested-terminal")`. The close-mismatch check stays first.
6. `token_state()` is unchanged. The token still says *whose turn*; it just no longer says
   *whether a review happened*.

Precedence and refusal (F1): `--reviewer` equal to the observed builder is a startup refusal
(exit 2) matching `marathon_drive.py:1940-1942`. The builder is never inferred; a turn is
"builder-role" by not being the reviewer, which is the safe direction (an unknown actor cannot
approve).

Checks (`test/gh505-relay-attest.sh`, fixture harness clone like gh376, stub `--agent-cmd`
scripts that edit the relay file and move the token):
- **A** builder-role turn writes `STATUS: Approved` + `tick done` → exit 4,
  `.relay-scratch/escalation-reason` = `forged-terminal`, file `STATUS:` restored, no
  attestation block. **Red control:** same fixture against the base-SHA copy of
  `relay_drive.py` exits 0 — recorded in `test/baselines/GH-505-negative-control.md`.
- **B** reviewer-role turn (actor = `--reviewer`) appends findings + `STATUS: Approved` + done →
  exit 0; attestation block present with `approved-head` = fixture HEAD and
  `reviewer-block-sha256` = sha256 of the appended bytes; mirror JSON present and equal.
- **C** file already `STATUS: Approved`, token done, no turn → exit 4 `unattested-terminal`.
  Red control: base exits 0 after 0 turns.
- **D** reviewer-role turn writes `STATUS: Approved` with no appended bytes → exit 4
  `empty-approval`.
- **E** `--review-once` with no `--reviewer`: reviewer approves → exit 0 and attested.

### Phase 2 — containment reads the driver, and the prompt stops inviting builders to approve (#505, closes B1)

`relay-automation/relay-turn-lib.sh` (the only copy — `utils/py/rtl.py:667-676` sources it).

1. `rtl_is_reviewer_turn` (`:63`): first tier, before the directive: `case "${RELAY_ROLE:-}"
   in reviewer) return 0;; builder) return 1;; esac`. Directive and `NEXT:` tiers remain for
   hand-run turns with no driver. This is the B1 fix: with a driver present, the artifact
   allowlist and the reviewer prompt are decided by what the driver dispatched, not by a line a
   builder can rewrite.
2. Shared prompt (`:1011`): delete `(or done + set STATUS: Approved when approving)` from the
   shared `printf`; append ` When approving, hand the token off with done and set STATUS:
   Approved.` to `role_note` inside the reviewer branch (`:994-998`).

Checks (same test file):
- **F** `RELAY_ROLE=reviewer` + a directive naming that agent as *builder* → helper returns 0.
  Red control: base returns 1 (directive wins).
- **G** the rendered builder prompt (`rtl_turn_prompt` with `RELAY_ROLE=builder`) does not
  contain `STATUS: Approved`; the reviewer prompt does.

### Phase 3 — consumers trust the attestation, not the word (#509, #505, #510; closes B2)

**`utils/py/marathon_drive.py`**
1. `cmd2` (`:3144-3149`): append `"--reviewer", args.reviewer`.
2. New `driver_attested(task)`: read `<git-common-dir>/relay-attest/<task>.json`, return the
   dict or `None`. `git rev-parse --git-common-dir` from `root`.
3. `satisfied_lane_terminal()` (`:2677`), the exit-3 probe (`:3218-3222`) and the exit-7 probe
   (`:3294-3298`): `terminal_status(s) and not actor` becomes `terminal_status(s) and not actor
   and driver_attested(task)`. Log the refusal when the word is terminal but no attestation
   exists — same "say it, don't absorb it" rule the #458 hardening used.
4. F2 from round 3: the recovery helper's caller consumes 0 vs non-0 only; a refused probe
   falls through to the existing no-progress escalation (exit 3) — asserted at the *process*
   exit in the check, not on the helper's return.

**`utils/py/jog_run.py`**
5. `run_single_phase_drive(root, gh_num, builder, reviewer, simulate)`: require `reviewer`
   (same message shape as the marathon-executor rule at `:189-196`); dispatch via
   `relay-automation/marathon-agent.sh` with `MARATHON_BUILDER/REVIEWER` and both `<AGENT>_AGENT`
   vars set; pass `--reviewer`. Caller at `:1665` threads `args.reviewer`.
6. `handle_landing_boundary` (`:1410-1471`): one helper `_merge_pr(root, pr_num, task)` used by
   both paths — reads `driver_attested(task)` (task = `RELAY-gh{N}-jog-drive`), runs
   `gh pr merge <n> --merge --auto=false --match-head-commit <head>` when an attestation exists
   (refuses with `parked` when it does not), captures output, parks on non-zero. Both paths park
   when no PR is found instead of falling through to `completed` (#510). The marathon-executor
   landing at `:426-435` gets `--match-head-commit` from `receipt["head_sha"]`, which the
   receipt already carries (`:137`).

Checks:
- **H** marathon: relay file terminal + token done + **no** attestation file → the recovery
  probe refuses and the process exits 3 with `no-progress`; with the file present → 0. Red
  control: base exits 0 without the file.
- **I** jog: stub `gh` records its argv; `handle_landing_boundary(auto_merge=False)` with an
  attestation present passes `--match-head-commit <head>`; stub `gh pr merge` exiting 1 →
  `(False, "parked", ...)`; stub `gh pr list` returning empty → parked. Red control: base returns
  `(True, "completed", None)` for both.
- **J** Phase 0's check above.

## Dependencies and ordering

0 → 1 → 2 → 3. Phase 2 without Phase 1 is safe but pointless (`RELAY_ROLE` unset → old tiers).
Phase 3 without Phase 1 breaks marathon (no attestation is ever written). Land as one PR.

## Risks and rollback

- **Every existing relay caller that does not pass `--reviewer` and is not `--review-once` can
  no longer reach a green exit.** That is the fix, and it is loud (startup stderr line +
  `unattested-terminal` reason). Callers in this repo: marathon (threaded), jog relay executor
  (threaded), relay-xyz Path A recipes (`--review-once`, unaffected). Vendored `.xyz/` copies pick
  it up on their next `xyz-sync.sh update`.
- **Attestation commit adds one commit per approval** to the relay repo. Same shape as the
  consult-verify commit; gitignored relay files get the mirror JSON only.
- **Rollback** is `git revert` of the single PR; the mirror directory under `.git/` is inert.
- **Tripwire, first week:** any `forged-terminal` or `unattested-terminal` escalation in
  `.tick/events` is either a real forgery or a caller I missed — both need a look.

## Verification

- `test/gh505-relay-attest.sh` cases A–J, each with the red control named above, run in a
  disposable full clone (mutation-heavy; never the task clone).
- Full gate (`validate.sh`) in that disposable clone; the task clone's push runs the pre-push
  gate again.
- Codex plan QA before Phase 0; Codex final QA on the committed implementation.
