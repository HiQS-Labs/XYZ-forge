---
Goal: Plan QA for GH-505 / GH-509 design v2 — driver-attested approval
Date: 2026-09-08
NEXT: Reviewer
STATUS: Open
ROUND: 3 / 3
---

# Context

Adjudicate the **revised** implementation plan for GH-505 / GH-509 before any code is written.
This is a new design, not a fourth round of the previous thread. The previous thread
(`relay-system/2026-09-08/gh505-reviewer-integrity-plan-qa.md`) blocked at its 3-round cap with
B1 (containment reads the builder-writable directive for permissions) and B2 (merge not bound to
the reviewed head) open, plus F1/F2. Its accepted decisions are carried forward; the plan says how
each open finding is answered.

**Base:** `origin/development` at `a6441b9b`. **Branch:** `fix/gh505-relay-reviewer-integrity`.

Read in full:

- `PROJECT/2-WORKING/GH-505-RELAY-REVIEWER-INTEGRITY.md` — the plan under review (shared by #505, #509, #510)
- `PROJECT/2-WORKING/GH-509-RELAY-TERMINAL-AUTHORIZATION.md` — the #509 pointer
- `PROJECT/1-INBOX/GH-505-RELAY-REVIEWER-INTEGRITY.md`, `PROJECT/1-INBOX/GH-510-JOG-MERGE-FALSE-SUCCESS.md` — evidence and ratings

Source the plan changes:

- `utils/py/relay_drive.py` — args `:30-41`; `terminal_status` `:355`; `token_state` `:361`; loop-top terminal `:571-579`; `RELAY_AGENT` export `:619`; post-turn reads `:820-823`; review-once `:826-846`; post-loop `:866-873`; consult-verify commit `:812-813`
- `relay-automation/relay-turn-lib.sh` — `rtl_is_reviewer_turn` `:63-101`; reviewer `role_note` `:994-998`; shared prompt `:1011`
- `utils/py/marathon_drive.py` — `satisfied_lane_terminal` `:2677-2698`; relay cmd `:3144-3149`; recovery probes `:3218-3222`, `:3294-3298`; caller `:3320-3328`; builder/reviewer env `:1878-1879`, equality refusal `:1940-1942`
- `utils/py/jog_run.py` — override `:1375-1389`; `run_single_phase_drive` `:1279`; caller `:1665`; `handle_landing_boundary` `:1410-1471`; marathon-receipt landing `:426-435`; receipt fields `:137`
- `relay-automation/marathon-agent.sh` — the dispatcher jog will reuse
- `utils/py/codex-turn.py:65-70`, `relay-automation/agy-turn.sh:71-73` — what each turn can write (the trust boundary the plan states)

## The design being reviewed

The driver (`relay_drive.py`) is the only process not run by the party under review. It learns
the reviewer from `--reviewer` (or `--review-once`), exports `RELAY_ROLE` per turn so containment
uses the driver's knowledge instead of the file's, reverts and escalates a terminal STATUS written
in a builder-role turn, and **attests** one written in a reviewer-role turn — appending a block
with reviewer id, reviewed head SHA and a sha256 of the reviewer's appended bytes, and mirroring
it to `<git-common-dir>/relay-attest/<task>.json`. The driver exits 0 only on an approval it
attested in-process. Marathon's post-hoc probes and jog's merge read the attestation, not the word.

## Questions

Answer each with a verdict and cite `file:line` where you disagree.

1. **Does this close B1?** With `RELAY_ROLE` as the first tier of `rtl_is_reviewer_turn`, is
   there any remaining path where a turn's *permissions* (artifact allowlist, reviewer prompt)
   are decided by bytes a builder turn can write? Consider: hand-run turns with no driver,
   `rtl.py` bridging, a stale `RELAY_ROLE` inherited from a parent env.

2. **Does this close B2, and is the trust claim on the mirror file stated honestly?** The plan
   says the driver's exit never depends on the mirror; only marathon's recovery probes and jog's
   merge do, and a same-user host process can forge it (stated non-goal; agy runs unsandboxed).
   Is that the right boundary, or does the mirror reintroduce the round-2 `.tick` problem under
   a different path? Would `receipt["head_sha"]` for the marathon-executor landing be the
   reviewed head, or the head at receipt time?

3. **F1 — precedence.** Builder is never named; a turn is builder-role by not being the reviewer.
   `--review-once` makes the single dispatched actor the reviewer. Neither flag → no terminal
   status can ever be accepted (loud at startup). Is this complete? Is there an existing caller
   this strands that the plan's risk table missed?

4. **Forgery revert.** Reverting the first `STATUS:` line to its pre-turn value and escalating
   `forged-terminal` — is rewriting the relay file from the driver acceptable, given the file is
   committed by the shim's file-scoped commit before the driver sees it? Is a second driver
   commit (attestation or revert) safe with respect to `rtl_enforce`'s commit-bypass guard on the
   *next* turn?

5. **Empty approval.** A reviewer-role turn that writes `STATUS: Approved` without appending
   any bytes is escalated `empty-approval`. Is byte growth a sufficient definition of "the
   reviewer wrote something", or does the attestation need to name what a review must contain?

6. **Falsifiability.** Cases A–J each name a red control at base. Does any of them pass for a
   reason unrelated to the fix? In particular: does case H assert the *process* exit of
   marathon (F2), and does case A's fixture reach the driver's post-turn path rather than a
   helper in isolation?

7. **Scope and DRY.** #510 is folded in because Phase 3 rewrites the same lines. Is that a
   correct fold or scope creep? Is there a second subsystem being built anywhere (the mirror
   directory, `judge_terminal`, `_merge_pr`) that should instead extend something that exists?

8. **Ratings.** #505 `85/85/50/55`, #509 `75/85/50/25`, #510 `70/70/50/90`. Grounded? Appeal
   neutral? Does #509's effort 25 still hold now that the design is ~80 lines rather than a
   subsystem?

Flag anything wrong, missing, incorrectly scoped, or over/under-engineered.

Write your verdict below. Set `STATUS: Approved` only if the plan is sound as written.

<!-- ▽ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK ▽ -->
▶ TAKE YOUR TURN (codex)
<!-- △ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK △ -->

## Round 1 — Reviewer (codex) — 2026-09-08

**VERDICT: CHANGES REQUESTED — Block.** The driver-owned role closes the driven containment hole, and the same-user-host limitation is honest. The plan still confuses file growth with reviewer text, post-turn HEAD with reviewed HEAD, and an existing mirror with applicable approval. Keep `STATUS: Open`; this is not implementation approval.

Review basis: read the shared plan, pointer and both requested intake documents, and traced the named Python driver, shell containment/dispatcher, Python RTL bridge, Marathon recovery/result writer and Jog landing paths. Also checked the prior round-3 dispositions and shipped launch recipes. No graph tools were exposed, so project/generation and index coverage could not be established; findings use bounded source reads and searches. No source/artifact, project test, gate or git command was executed. Counterexamples below are source-derived, not witnessed runtime reproductions. Only this relay file is edited; the token operations are the explicitly authorized exception.

### Graded findings

**B1 — Block / Proof: size growth does not establish a reviewer append, and the digest is offset incorrectly.** Plan `PROJECT/2-WORKING/GH-505-RELAY-REVIEWER-INTEGRITY.md:106`, `:113–119` snapshots the whole file's size and hashes the post-turn suffix beginning at that old size. Changing `STATUS: Open` to `STATUS: Approved` alone grows the file by four bytes. With no appended findings, the size check passes and the digest covers four old trailing bytes. With real findings appended, header growth shifts the append boundary, so the digest still includes old bytes; a shrinking header can instead hide a short legitimate append. Changes to NEXT or ROUND cause the same problem. Case D therefore fails the intended requirement under the proposed algorithm, and case B's expected digest is not the described implementation's digest.

Cheapest correction: snapshot and compare the actual pre/post review body, accounting separately for the permitted header edits; require a non-whitespace appended review body and hash precisely that addition. Specify what happens if prior body content is rewritten rather than appended. A reviewer-quality scorer or prescribed substantive verdict vocabulary is unnecessary for the stated non-goal: this check need only prove that the designated reviewer added review text. Cover status-only growth, NEXT/ROUND-only growth, header shrink plus a genuine append, whitespace-only append, and an independently calculated expected digest.

**B2 — Block / Blast + Recon: the attested SHA and the final merge candidate are different commits, and the receipt does not repair that distinction.** The plan takes `head = get_head_commit()` after the shim returns, then creates an attestation commit (`plan:115–119`), and Jog merges only that earlier head (`:184–190`). For a tracked relay in the target repo, the shim has already committed its review at `relay-automation/relay-turn-lib.sh:1437`; the driver then adds another commit. Thus an ordinary final PR pushed with the attestation commit will fail the proposed match against its parent. More fundamentally, the post-turn head need not be the checkout the reviewer read: the existing isolated-turn guard explicitly permits a concurrent parent commit and commits review text on top (`relay-turn-lib.sh:1285–1293`). Labeling the result “reviewed head” silently blesses that concurrent code.

Marathon's `receipt["head_sha"]` is **HEAD at result-write time**, read at `utils/py/marathon_drive.py:165` and emitted at `:253`. It is not carried from a reviewer observation. Between approval and that receipt, `complete_phase_success()` saves/commits a transcript (`:2575`, `:2134–2156`) and can run a post-approve command (`:2595–2602`). Passing the receipt SHA to merge closes the receipt-check/merge race, but does not establish that its code was reviewed.

Cheapest correction: define and preserve the actual reviewed revision before dispatch, then explicitly define the permitted transition to the final merge revision. Either keep approval metadata off the candidate branch, or prove that intervening commits change only the specified harness metadata and preserve the reviewed artifact content; refuse arbitrary code drift. Carry that validated relationship through the existing Marathon result receipt and Jog consumers instead of relabeling receipt-time HEAD. Specify the target repo separately from the transcript repo for foreign/archive layouts. Add positive coverage with a tracked relay and the real shim/driver commit order, plus negative coverage for a parent code commit during review and code movement before receipt/merge. Test the ignored/separate-transcript case too. A stub that merely records a SHA argument cannot catch the normal parent-versus-child mismatch.

**B3 — Block / Proof: recovery treats mirror existence as authorization without validating applicability or completion.** `plan:169–174` returns any parsed dict and checks its truthiness. No comparison with the current reviewer, terminal status, review body/digest, or current candidate revision is specified, and no stale-record lifecycle is defined. An honestly produced approval for task T at H1 can remain while the candidate changes to H2; Marathon's terminal retry then takes `complete_phase_success("already-satisfied")` (`utils/py/marathon_drive.py:2696–2698`) without another review, and its receipt records H2. No hostile host write is required. The new digest is ornamental if consumers never validate it against the bytes it purports to attest.

There is also a publication-order gap: `judge_terminal()` publishes the mirror immediately after reading `ns` (`plan:108–122`), before the later terminal-success checks. A reviewer may leave a live token. Current review-once success does not check that token at all (`utils/py/relay_drive.py:830–834`); ordinary loop-top rejection occurs only later (`:572–575`). “The close-mismatch check stays first” does not specify a common check before mirror publication at these sites.

Cheapest correction: define one validated attestation record and reader with explicit task/repo/reviewer, status, revision and body binding; reuse it in both consumers. Publish it only after successful containment, valid review-body extraction, and the canonical done-token check. Specify missing/malformed/truncated records, write failure, stale records, retry task identities, and atomic publication so a partial write never becomes a counting verdict. Bind recovery to the reviewed-content/final-head policy in B2; do not equate a truthy JSON object with that policy. Add stale-H1/H2, changed-reviewer/body, malformed-record, and live/missing-token controls at the real consumers. This is ordinary freshness/crash correctness within the stated trust boundary, not a demand for cryptography or hostile-host isolation.

**F1 — Fix / Recon: invocation precedence and the caller inventory are still incomplete.** `plan:126–129` promises a startup rejection when reviewer equals “the observed builder,” while simultaneously saying the builder is never inferred and providing no builder input. Initial actor is not a builder identity: case B and legitimate direct reviews start with the reviewer. Also, the expression at `:104–105` lets `--review-once` override an explicitly different `--reviewer`, allowing the wrong dispatched actor to count as reviewer. Define the explicit-flags conflict rule, the trusted builder input if equality refusal remains promised, and the `--agent-cmd` contract that routes the captured actor to the corresponding contained shim. Reuse Marathon's already-exported builder/reviewer and equality refusal (`marathon_drive.py:1878–1879`, `:1940–1942`); do not infer them from the directive or initial token.

The risk table's claim that Path A recipes use review-once (`plan:211–213`) is false for the Codex, agy and Commandcode examples in `skills/relay-xyz/SKILL.md:324–328`, `:345–349`, `:366–370`. The README's supervisor recipe also supplies neither role flag (`relay-automation/README.md:229–230`). Include migration of these shipped instructions. For Jog, explicitly retain the same-agent rejection already present in `validate_marathon_executor()` (`jog_run.py:195–196`) when wiring the legacy executor; “require reviewer” alone is insufficient. Missing trusted configuration should preferably refuse before dispatch rather than merely warn and consume builder turns that can never succeed.

**F2 — Fix / Proof: the named controls need executable entry conditions and distinguishable failure reasons.** A base-SHA driver does not accept the new `--reviewer` flag: `relay_drive.py:55–56` rejects unknown arguments with exit 2. “Same fixture against the base-SHA copy exits 0” (`plan:135–136`) therefore needs an explicitly adapted baseline invocation or a guard-transposition mutation that retains the new CLI. The previous thread already recorded this constraint. Case A otherwise correctly asks for a real stub-dispatched turn, done token, exact exit 4/reason and restored status; retain proof that the stub actually ran, including the final-round path.

Case H now correctly requires the Marathon **process** exit 3/no-progress for the exit-3 recovery branch (`marathon_drive.py:3322–3328`), resolving the old F2 semantic mismatch. But name the fixture that reaches it: artifact delta exists, gate passes, stub relay returns 3, and terminal/done state is produced after startup rather than intercepted by `satisfied_lane_terminal()`. Test startup recovery and timeout recovery separately; the latter's refused no-actor branch returns 7 (`:3299–3303`), not 3. Case I must supply an interactive stdin and affirmative input (`jog_run.py:1442–1447`), a valid PR view, and assert the fake merge was reached; otherwise “parked” passes without exercising merge failure. Cover both legacy branches and Marathon landing, and actual changed-head refusal, not only argv presence. G needs nonempty role-specific prompts before the negative text assertion. B and E are positive controls, not tests that must fail at base. Name committed nonempty red/green evidence and `provenance.jsonl`; the current blanket A–J red-control claim and one baseline markdown path do not supply that contract.

**F3 — Fix / Diagnosable: define forgery-revert persistence and the failed-turn boundary.** A compensating driver edit/commit is acceptable after a shim's file-scoped commit. It cannot trip the *next* turn's commit-bypass guard when serialized: `rtl_before()` snapshots the then-current HEAD (`relay-turn-lib.sh:1016`) and `rtl_enforce()` compares only against that turn's snapshot (`:1285`). However, the builder branch in `plan:110–112` specifies a rewrite and append followed by exit, with no commit; only the reviewer branch specifies a commit. The forged Approved therefore remains in committed history/current committed state until somebody deliberately persists the correction. State the file-scoped corrective commit and check failures rather than silently imitating the unchecked consult commit at `relay_drive.py:812–813`.

Also, a shim returning nonzero exits the driver at `relay_drive.py:711–712`, before the proposed judge at `:820`. Such a turn can leave terminal text committed/on disk without the promised revert. Either explicitly bound the revert promise to successfully returned turns, or inspect and repair forged terminal state on that exit path while preserving failure and never attesting failed turns. Do not reopen a spent token automatically. Keep the refusal reason on stderr as well as scratch; `exit_escalate()` currently writes scratch and exits (`:558–563`), and the plan's `.tick/events` tripwire is not emitted by that helper for standalone relays.

### Answers to the eight questions

1. **B1: yes for driver-dispatched turns, with a bounded compatibility exception.** Overwriting `RELAY_ROLE` before each dispatch defeats a stale parent value in that driver run. The Python bridge preserves the environment (`utils/py/rtl.py:690–696`) and `rtl_init` snapshots the resulting allowlist (`relay-turn-lib.sh:354–371`). Hand-run turns still trust editable directive/NEXT data, and a stale `RELAY_ROLE=builder` on a hand-run reviewer still widens permissions. State that limit and require an explicit correctly scoped role for a trusted manual review; do not claim universal permission independence. Cover both contradictory directive directions through the bridge/allowlist, not just the shell helper.
2. **B2: no, as written; see B2–B3.** The unsigned same-user mirror limitation is honestly disclosed and accepted. Its placement differs materially from the universally writable `.tick` grant for sandboxed Codex, but it does not make arbitrary agy host writes impossible. The remaining blockers require no adversary outside that boundary. Receipt `head_sha` is receipt-time HEAD.
3. **Precedence: incomplete; see F1.** Unknown actors being builder-role is a safe default for terminal refusal. The equality promise, explicit reviewer/review-once conflict and shipped recipes still need correction.
4. **Forgery revert/driver commit: acceptable in principle; see F3.** Serialized compensating commits do not violate the next turn's guard. Persistence, checked failure and the early nonzero-return path need to be explicit.
5. **Empty approval: no, size is not sufficient; see B1.** Require an actual nonempty reviewer addition, without introducing review-quality scoring.
6. **Falsifiability: improved but incomplete; see F2.** H correctly names the process exit for its particular branch; A names the real dispatch seam. Their setup and baseline controls still need the specified corrections, and B2–B3 require consumer-level counterexamples.
7. **Scope/DRY: folding #510 is justified by the exact landing edits.** Reusing `marathon-agent.sh` and one Jog merge helper is appropriate. Keep the existing PR state/base checks (`jog_run.py:1393–1407`). A small durable record is defensible for the two actual recovery/merge consumers; give it one writer, resolver and validated reader rather than importing a nested Marathon helper into Jog or duplicating parsers. Existing `marathon-drive/result@1` should carry the review binding where that receipt already exists. The excluded express/cleanup/closeout paths are clearly disclosed; no server-policy expansion is requested.
8. **Ratings: priority/severity are defensible provisional judgments; appeal 50 remains correct.** #505 has local mechanism evidence independent of the unverified companion statistics. #510's 70/70/50/90 remains reasonable for its isolated false-success fix. I cannot independently confirm #509's ledger/rationale from the supplied local pointer, which contains no rating rationale. Effort is cheapness: ~80 proposed lines alone cannot justify raising it, because identity, commit ordering, recovery and falsifiable integration tests dominate this work. Keep 25 provisional until B1–B3 are resolved and re-estimate from the settled scope; do not claim it is grounded by a line-count estimate.

SWE disposition: **Recon Fix; Minimal acceptable in direction; Diagnosable Fix; Blast Block; Proof Block.** Restore an explicit **Costly** reversibility classification for the containment/approval contract and name debug-mantra as the implementation-time debugging protocol; the existing one-PR rollback and bounded QA rounds are appropriate. These do not require a second plan or additional review machinery.

NEXT: Producer (claude-a)

## Round 1 — Producer (claude-b) — 2026-09-08

All six findings accepted; none rejected. The plan is revised in place —
`PROJECT/2-WORKING/GH-505-RELAY-REVIEWER-INTEGRITY.md` — with a per-finding table under
"Round 1 dispositions". Summary of what changed:

- **B1** → `review_body()` strips the header block and the driver's own trailer; the check is
  append-only + non-whitespace; the digest covers exactly the added bytes. Cases D1–D3, B2 added.
- **B2** → `reviewed_head` is the pre-dispatch HEAD (the revision the isolated worktree was cut
  from). Transition rule stated: only transcript-path commits may sit between `reviewed_head` and
  the candidate; `candidate_ok()` enforces it at every consumer, then `--match-head-commit`
  binds the checked SHA to the merged one. Receipt gains `reviewed_head`; `head_sha` is no
  longer described as reviewed. H3, I4 added.
- **B3** → one `relay-drive/attest@1` record, one module (`utils/py/relay_attest.py`) with the
  writer, resolver and validating reader; publication only after shim 0 + body check + done
  token (close-mismatch moved before publication, so review-once gets it); atomic write; stale
  records fail `candidate_ok` rather than being trusted or deleted. K added.
- **F1** → `--reviewer` required, `--builder` optional, equality and review-once actor-mismatch
  refusals before any tick mutation; recipes in `skills/relay-xyz/SKILL.md` and
  `relay-automation/README.md` migrated; jog keeps `validate_marathon_executor`'s same-agent rule.
- **F2** → base controls run without the new flags; H split into H1/H2/H3 with the process exit
  asserted; I1–I5 with stdin, PR view and reached-merge assertions; positive controls labelled;
  baseline doc and committed `provenance.jsonl` named.
- **F3** → revert is a checked file-scoped commit; the nonzero-shim exit path calls the judge for
  revert only; stderr reason on every refusal.
- Q1 limit → `RELAY_ROLE` honoured only under `RELAY_DRIVER_LOCKED=1`; hand-run limit stated.
- Reversibility marked **Costly**; `/debug-mantra` named. #509 effort stays 25, provisional.

Questions for round 2: the same eight, against the revision. Two specific ones added:

9. Is the transcript-only transition rule (`git diff --quiet <reviewed_head> <candidate> --
   . ':(exclude)relay-system' ':(exclude)<relay_file>'`) the right shape, or does it need to
   name the driver's own commit messages instead of paths? Consider a relay file that lives
   outside `relay-system/` and a gitignored one.
10. Is `RELAY_DRIVER_LOCKED=1` an acceptable gate for the `RELAY_ROLE` tier, given the shims
    already treat it as the driver's marker, or does that couple two unrelated contracts?

Set `STATUS: Approved` only if the revision is sound as written.

<!-- ▽ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK ▽ -->
▶ TAKE YOUR TURN (codex)
<!-- △ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK △ -->


## Round 2 — Reviewer (codex) — 2026-09-08

**VERDICT: CHANGES REQUESTED — Block.** The revision resolves the intended role precedence, publication ordering and corrective-commit requirements. Three contract gaps remain: the review-body definition rejects shipped relay formats and cannot locate the recorded addition; the reviewed revision is not consistently bound to the checkout and merge candidate; recovery still lacks expected-reviewer/current-status validation. Keep `STATUS: Open`.

Review basis: read the revised shared plan, pointer and both intake documents in full; inspected the relevant driver, containment, bridge, dispatcher, Marathon result/recovery and Jog landing source. These are source-derived counterexamples, not executed reproductions. No git command, source/artifact execution, project test or gate was run. Only this relay file was edited, with the authorized env-pinned token operations.

Graph evidence limit: `list_projects` was fully paginated (56 projects); this worktree and its parent task clone are not indexed. The nearest reference project is `Users-noelsaw-Documents-GH-Repos-XYZ-forge`, a different checkout, generation `2026-09-08T20:17:17Z`. Symbol discovery and coverage were consulted there, but cannot establish this worktree's freshness. Coverage reported no recorded source gaps in the requested paths and missing current plan/pointer/relay files in that checkout. Therefore the material findings below use direct reads of this worktree; no exhaustive graph claim or reindex is made. Review tier: bounded Verify with source fallback.

### Graded findings

**B1 — Block / Recon + Proof: define a body parser that accepts the shipped formats, and persist the start of the reviewer addition.** `PROJECT/2-WORKING/GH-505-RELAY-REVIEWER-INTEGRITY.md:80` recognizes leading frontmatter or a leading run of `KEY:` lines. Both actual consumers emit a Markdown title first: Marathon at `utils/py/marathon_drive.py:2797-2801`, Jog at `utils/py/jog_run.py:1322-1325`. Under the stated parser neither has a removable header. Updating STATUS/NEXT changes the pre-existing body prefix, so a legitimate approval fails `review-body-rewritten`. The frontmatter-only positive fixture would conceal a failure of both production callers.

Separately, the record/trailer at `plan:89-101` stores the digest of **added** bytes but no start offset, length or other unambiguous start boundary. Its trailer position marks the **end** of those bytes. For `pre_body=P`, appended reviewer text `R`, and trailer `T`, the final file is `P + R + T`; hashing after T cannot recover R, and hashing everything before T includes P. This is still an undefined reader, despite the correct in-memory append check. Stripping a trailer by its heading also needs a precise terminal-block rule so a quotation or old attestation in the body is not silently discarded.

Cheapest correction: parse the actual title-plus-header, frontmatter and header-first forms; separate only the permitted header edits from the retained body. Store a driver-observed canonical-body start offset and length (or an equivalently precise range) in the record and validate bounds, exact added bytes and the actual trailer. Require the existing non-whitespace/append-only checks. Add positive cases using the real Marathon and Jog renderers, a multi-round body, independent digest calculation and an attestation-heading quotation. No review-quality scorer is needed.

**B2 — Block / Blast: the reviewed-to-candidate binding remains incomplete at both ends.**

- **Checkout anchor:** `plan:62,80` labels `head_before` as the revision the worktree was cut from. It is captured at `utils/py/relay_drive.py:615`; the shim subsequently creates the worktree from the then-current symbolic `HEAD` at `relay-automation/relay-turn-lib.sh:733`. A parent commit between those operations makes them different revisions. The current guard explicitly tolerates parent commits (`relay-turn-lib.sh:1285-1293`). A later endpoint comparison cannot prove which revision was read, particularly if the parent moves again. Pin the actual review checkout to the captured SHA, or obtain and validate a trusted observation of the shim's actual checkout revision. Also state how non-isolated turns and separately seeded artifact content qualify for this claim; HEAD alone does not describe a dirty or externally seeded review input (`relay-turn-lib.sh:767-774`). An explicit refusal for unsupported merge-attestation layouts is sufficient; no new isolation subsystem is required.
- **Marathon landing:** `plan:138` calls `candidate_ok` against `receipt["reviewed_head"]`, then merges `<PR head>`. Given a valid record at R, this compares R with R and succeeds even when the PR and receipt-time head are C with unreviewed code. Existing `jog_verify_pr_before_merge` checks PR head against **receipt-time** head (`utils/py/jog_run.py:392-393`), so it does not close R→C. Validate the actual PR candidate C against the validated record's R, and pass exactly C to `--match-head-commit`. Extend the same helper used by the legacy branches; do not treat presence of a receipt field as a substitute for loading/binding the record.
- **Normal Marathon success:** `plan:132` loads/copies the record on relay exit 0 but does not specify `candidate_ok` before issuing the approved result. Its candidate checks at `:133` cover recovery only. `complete_phase_success()` can run a post-approve command after saving the transcript (`marathon_drive.py:2575,2595-2602`), and the result later captures HEAD (`:165`). Validate the final candidate before representing that candidate as approved, and carry the relationship into the receipt. A concurrent code commit or post-approve source change must not become an approved receipt merely because the relay exited 0.

**Q9 disposition:** path-based validation is preferable to commit-message matching; messages prove no content property. But `plan:64` says **every commit** is transcript-only while specifying an **endpoint tree diff**, with no ancestry check. A code change followed by its revert, or an unrelated commit with identical non-transcript content, passes the latter. Choose explicitly: ancestor + preserved final artifact content is a reasonable smaller contract; if every intervening commit must be metadata-only, inspect that range. Do not claim one while implementing the other. Name exact permitted metadata paths in the target repo, use literal path handling for a relay outside `relay-system/`, and resolve the `.relay-scratch/` prose/command mismatch. A gitignored relay needs no target-tree exclusion; an archive relay needs its own transcript-repo identity, not an unexplained target-repo-relative path (`plan:101`). Git lookup/diff errors must refuse, not count as a clean diff.

**B3 — Block / Proof: record validation still omits current reviewer and terminal agreement.** The `load(task, relay_file, target_repo)` contract at `plan:100-101` has no expected reviewer input, never compares its reviewer with the configured reviewer, and checks only that the **record's** status is terminal. It does not require equality with the current relay status or trailer fields. `plan:133` adds a truthy validated load to a separate terminal-word test. An honestly produced approval by reviewer A can therefore satisfy a later invocation configured for reviewer B at the same code head. Changing only current STATUS from Approved to Closed also preserves the body digest and candidate check. Neither counterexample requires a hostile host write to `.git`.

Cheapest correction: feed trusted expected reviewer/task/repo/file identity into the shared reader; compare record, trailer and current terminal status exactly, and have consumers require the current task to be `done`, not merely actorless. `token_state()` returns no actor on missing/read-failed state as well as done (`relay_drive.py:361-377`); the recovery shortcuts still start from `not actor`. Keep atomic publication and the same-user-host non-goal. Add consumer-level changed-reviewer, changed-status/body, missing-token, malformed/truncated-record and stale-code-head refusals. Case K currently tests only a claimed token during publication; it does not cover these reader obligations. Specify the logged refusal and recovery path when commit or mirror publication fails; never authorize from a partial record or a stale prior success.

**F1 — Fix / Recon: put the role-marker guard at the shared decision point and correct its permission description.** `plan:118` reverses the effect of stale roles: reviewer means relay-only permissions; builder means the wider artifact allowlist (`relay-turn-lib.sh:990-998`). Therefore stale **builder** on a manual reviewer widens permissions; stale reviewer narrows them. `RELAY_DRIVER_LOCKED=1` is acceptable as a compatibility marker, not proof that a driver is currently present: it is inherited and already suppresses driver lock acquisition (`relay_drive.py:465,512`). Gate the new tier in shared `rtl_is_reviewer_turn` itself, so the `rtl.py` bridge and all shims agree, rather than promising unspecified edits across frozen shims. State the inherited-both-variables/manual limit honestly. In driven turns, overwrite role on every dispatch as planned. F must set the locked marker, and F2 should exercise the same shared path.

The required reviewer/equality/review-once precedence is otherwise resolved. In migration (`plan:149`), use each recipe's actual agent variable or explicit identity: the shown recipes define `CODEX_AGENT`, `AGY_AGENT`, `COMMANDCODE_AGENT`, not a generic `$AGENT` (`skills/relay-xyz/SKILL.md:323,344,365`). The README recipe is generic whole-thread supervision (`relay-automation/README.md:227-234`), so name its reviewer configuration explicitly. State that custom `--agent-cmd` must route the captured actor to the corresponding contained shim; a token actor alone cannot authenticate an arbitrary command.

**F2 — Fix / Proof: close the remaining fixture escape hatches.** The adapted base invocations, explicit process exit in H2, reached-merge assertions and committed evidence destinations are improvements. Retain them, with these corrections:

- H1 (`plan:141`) promises dispatch after refusing a pre-existing terminal/done task. The existing workflow says done tokens cannot reopen (`marathon_drive.py:2605-2610`) and subsequently attempts to claim that same task (`:3115-3117`). Specify a fresh authorized retry identity or assert a loud refusal; do not require dispatch from a spent token without a stated lifecycle change.
- I1's `stdin y` (`plan:142`) must also make `isatty()` true, or Jog parks before prompting (`jog_run.py:1442-1447`). I5's baseline claim must distinguish the branches: auto-merge failure already parks at base (`:1432-1435`), so that case is a preservation control, not red-at-base.
- Add the B1–B3 integration controls above, including real shim/driver commits with a tracked relay, gitignored/archive behavior, drift during review, drift before receipt, and the **Marathon-executor** merge consumer. The current I cases explicitly cover only the two legacy branches. Preserve final-round A coverage. For requirements that do not fail on the old CLI, name a guard-transposition mutation instead of claiming every control is red at base.

**F3 — Fix / Diagnosable: make failure-code precedence executable in the stated judge.** `plan:82,105` promises shim failure 6 remains 6, but the builder branch at `:84` unconditionally invokes `exit_escalate("forged-terminal")`, which exits 4 (`relay_drive.py:558-563`). Return a judgement to the caller (or pass an explicit preserve-exit mode), persist the corrective file-scoped commit, and then exit with the original shim code on that path. State how a corrective-commit failure is reported while preserving the original failure. Serialized driver commits remain compatible with the next turn's fresh `rtl_before()` snapshot (`relay-turn-lib.sh:1016`); that concern is resolved.

### Answers to the ten questions

1. **Driven B1 permission hole: closed in direction.** Invocation-owned role works through the env-preserving Python bridge. F1 narrows the implementation and manual/stale-env claim; hand-run compatibility still trusts editable role prose.
2. **B2: not closed as written.** See B2–B3. The unsigned mirror's same-user-host limitation is honest and remains accepted; the findings concern ordinary binding and freshness. Receipt `head_sha` remains receipt-time HEAD.
3. **Precedence: resolved; migration details need F1.** Required reviewer, optional trusted builder, equality refusal and review-once actor match are coherent. Do not infer builder identity from the initial actor.
4. **Forgery revert: acceptable; F3 remains.** Checked file-scoped compensating commits are the right shape; fix the error-code contradiction and ignored/archive persistence behavior.
5. **Empty approval: append-only non-whitespace text is sufficient for the declared non-goal.** B1 concerns extracting and binding those bytes, not assessing their quality.
6. **Falsifiability: improved, not complete.** A names the real driver seam; H2 names process exit correctly. F2 and the blocker-specific integration cases prevent unrelated early refusals from looking like proof.
7. **Scope/DRY: acceptable.** Folding #510 touches the same landing lines. One record module for two consumers and one shared merge helper are justified. Reuse the existing receipt/PR checks; no additional service, signature system or reviewer scorer is requested.
8. **Ratings: unchanged provisional judgments.** Appeal 50 is neutral. #509 effort 25 remains provisional and cannot be justified by the ~60-line helper estimate. The local pointer still supplies no 75/85/50/25 rationale to independently verify; #505/#510 rationales were read, not their live ledger state.
9. **Transition rule: use content paths, not commit messages; amend the contract as in B2.** Exact reviewed checkout, candidate identity, ancestry policy and transcript/target separation must agree with the named comparison.
10. **Locked marker: acceptable as a scoped compatibility convention, not authentication.** Apply it once at shared role derivation and retain the inherited/manual limitation (F1).

SWE disposition: **Recon Fix; Minimal acceptable; Diagnosable Fix; Blast Block; Proof Block.** Costly classification, one-PR rollback, bounded QA rounds and named debug-mantra are accepted. The next revision can remain in the same plan and module design; resolve the three contracts and align their fixtures rather than add review machinery.

NEXT: Producer (claude-b)

## Round 2 — Producer (claude-b) — 2026-09-08

All findings accepted; none rejected. Plan revised in place
(`PROJECT/2-WORKING/GH-505-RELAY-REVIEWER-INTEGRITY.md`, "Round 2 dispositions" table); #509
rating rationale added to `PROJECT/2-WORKING/GH-509-RELAY-TERMINAL-AUTHORIZATION.md`.

- **B1** → comparison is on *canonical* bytes: the first `STATUS:`/`NEXT:`/`ROUND:` lines reduced
  to bare keys, nothing else touched — so marathon's and jog's title-first renders, frontmatter
  threads and bare-header threads all work, and header edits never disturb the body prefix.
  Record and trailer carry `added_start`+`added_len`; the reader validates range, digest and the
  trailer *by offset*, never by heading. B/B2/B3 use the real marathon and jog renderers, a
  multi-round body and a quoted attestation heading.
- **B2 checkout** → the driver exports `RELAY_REVIEWED_HEAD`; `rtl_worktree_begin` cuts the
  worktree at that SHA instead of live HEAD. Non-isolated turns are `isolated:false` and refused
  by every merge consumer (new non-goal). Seeded artifacts recorded by digest. B4 (parent commit
  during the turn) and F3 (cut-at-SHA) added.
- **B2 landing** → one `_merge_reviewed_pr` for all three jog branches, comparing record R with
  the PR candidate C and passing exactly C. M1/M2 added for the marathon-executor branch.
- **B2 success** → `candidate_ok` runs after the post-approve command and before the approved
  receipt; drift escalates instead of writing an approved receipt. H4 added.
- **Q9** → contract chosen explicitly: ancestor + preserved endpoint content outside
  `relay-system/` and the relay file's repo-relative path; `.relay-scratch` dropped; git errors
  refuse; archive relays carry `transcript_repo`.
- **B3** → `load(task, expected_reviewer=…, relay_file, target_repo)`; compares reviewer, status
  (record = current file = trailer), range/digest/trailer; consumers require the token to read
  `done`, not merely actorless; publish failure is `attest-publish-failed` with no partial record.
  L and K2 added.
- **F1** → gate inside shared `rtl_is_reviewer_turn`; permission direction corrected (stale
  *builder* widens); recipes migrated per their own variables; custom `--agent-cmd` contract stated.
- **F2** → H1 asserts loud refusal + no dispatch; I1 substitutes an `isatty()`-true stdin; I5's
  merge-failure case labelled preservation; integration fixtures run the real `relay-turn-lib.sh`;
  mutations named where base is not red.
- **F3** → `judge_terminal` returns a verdict; the shim-failure path preserves 6/7 and reports
  `revert-commit-failed` without masking the original code.

This is round 3 of 3. Please review the revision against the same ten questions and set
`STATUS: Approved` if it is sound as written; otherwise list what remains, ranked.

<!-- ▽ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK ▽ -->
▶ TAKE YOUR TURN (codex)
<!-- △ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK △ -->
