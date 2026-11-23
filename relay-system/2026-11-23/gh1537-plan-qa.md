# RELAY · GH-1537 Plan QA: pre-push own-diff routing for development merges
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-11-23.
-->

NEXT: Reviewer
STATUS: Open
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
     A `[Blocker]` must cite an observed failure.
     A finding from an earlier round stays open, and the verdict stays failing, until new evidence closes it.
     This includes earlier [Nit] findings; only a newly raised [Nit] with VERDICT: PASS on STATUS: Approved remains optional.
     This is a protocol rule, not a mechanical check —
     the Producer may disposition a request lacking these as `Declined — unproven generalization`.
   - **Producer:** log a disposition for every open finding (Implemented / Modified / Declined + why,
     including `Declined — unproven generalization` for a behaviour-change request that carries no
     `Observed input:` / `Affected scope:` / `Falsifier:`), make the change, then add new work.
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
   Reviewer headings may be `### Reviewer · Round N`, `### Round N · Reviewer · <agent>`, `### Reviewer (<agent>)` (optionally followed by `— rN`), or `### Reviewer — Round N` (optionally followed by `(<agent>)`); follow the heading with a non-empty review body.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Manual relay: commit only the relay file** (`relay(gh1537-plan-qa): <role> r<N>`); no push.
   **Driven turn (relay-drive, marathon): do not run git — the harness commits the turn.** **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. (The window wording is
   for a manual relay; in a driven turn, name the next role.) The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: `PROJECT/2-WORKING/GH-1537-PREPUSH-OWN-DIFF-ROUTING.md` (the plan; no code yet)
- Reviewer: codex (gpt-6-astra, reasoning effort high)   ·   Producer: claude-a
- Started: 2026-11-23
- Definition of Done: the plan satisfies issue #1537 plus the KS-12 entry of arc #1541 with the smallest
  change that works, grounded in the real hook code.

Issue #1537 (operator-approved policy 2026-11-19): a push whose only new integration content is
`development` merged into the branch is classified by the branch's own diff (merge-base to head)
through the existing `utils/ci-route.sh`, and the final landing still gets a full gate. Correction
comment on #1537: `githooks/pre-push:91` is only a comment; the mechanism is the update-range diff
`git diff --no-renames --name-only "$remote_sha" "$local_sha"`, so a development merge drags
development's code paths into the range. KS-12 (#1541) adds: classify the FINAL TREE against the
verified integration parent so conflict-resolution and evil-merge edits count; use it only for
`route=docs`; refuse it for pushes to `development` or `main`; keep live `ls-remote` freshness,
per-ref checks, rename/deletion handling and the ambiguous-history fallback. Red controls: a docs
branch with a merge whose code conflict resolution routes `full`; a merge from another branch routes
`full`; a stale base routes `full`. Green: a pure docs branch with a merge routes `docs`.

Operational envelope: grade against the stated requirements, commensurate complexity, and this repo's
own threat model. XYZ-forge forbids new tests (AGENTS.md, GH-831); verification is existing suites plus
a manual check with a red control under `TESTS-RESULTS/`. This is a gate/hook surface: do not suggest
deferring a finding; do not ask for a new suite or machinery beyond the plan's non-goals.

**Step A — paraphrase first (GH-1414).** Before opening any other file, read ONLY the plan doc and
write 2-5 sentences each under **What this proposes** and **How the existing system works, per this
document**, plus a short **What it's not**. Label inference as inference.

**Step B — source-backed check.** Then read `githooks/pre-push` in full, `utils/ci-route.sh`
(the `push` mode and the docs/full classification), `test/gh544-pre-push-gate.sh` (how the hook is
driven against a stub `validate.sh`) and `AGENTS.md` (No new tests). Answer:
1. Is the soundness argument right? For which inputs does classifying `merge-base(tip, local)..local`
   (final tree) while accepting only `route=docs` still let code reach a push ungated, or wrongly
   force `full` where it should not? Try: octopus merges, a merge whose first parent is development,
   a rebased branch, a branch that already merged an older development, a submodule or mode change,
   renames/deletions (`--no-renames` is load-bearing), multiple refs in one push.
2. Is the merge-parent check (`git rev-list --merges --parents remote..local ^tip`, every non-first
   parent an ancestor of the tip) correct and sufficient for "a merge from another branch routes full"?
   Is the `mbs` not-already-an-ancestor-of-`remote_sha` gate right, and does it skip the network probe
   on ordinary pushes?
3. Freshness: does using the local tracking ref as a hint and then proving equality with the live
   `ls-remote` tip (shared `probe_integration_tips`) keep GH-487's guarantee? Does extracting the probe
   into a cached function change first-push behaviour (the `_base_note`, the `return 1` paths)?
4. Is carrying `rref` as a third field in `_real_ref_pairs` safe for every reader in the hook
   (`:68-78`, `:131`, `:180`, `:306`)? Name any reader missed.
5. What prevents an unchanged, unfixed candidate from being reported delivered? Is the red/green manual
   check (base `5964566ef` routes `full`, candidate routes `docs`, plus the controls) a real rejection,
   and are the controls sufficient and each discriminating?
6. Is anything over-built or missing for the envelope? Is the CHANGELOG entry warranted?

Cite `file:line` for disagreements. End with `swept file: yes|no`, `VERDICT: PASS|FAIL`, a Basis, and
set STATUS to Approved only on PASS.

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

The plan narrows existing feature-branch refresh pushes to the branch's final-tree diff against a merge-base with a live-verified integration tip. It accepts that alternative only for `route=docs`, reuses the existing classifier, and otherwise returns to update-range routing.

**How the existing system works, per this document**

Existing branches use remote-SHA-to-local-SHA paths, so merging development imports development's changed paths into classification. First pushes already use a merge-base with a live-verified integration tip; the proposed helper shares that freshness proof.  [Unverified — no citation]

**What it's not**

It does not provide code-branch receipt reuse, own-diff tier-2 routing, or a replacement landing gate. These paraphrases were written before opening source; the checks below followed.

**Findings — changes required before plan approval**

- **[Should] F1 — the fallback can erase the final-tree code veto.** Plan `PROJECT/2-WORKING/GH-1537-PREPUSH-OWN-DIFF-ROUTING.md:79-87` promises that conflict-resolution/evil-merge code counts, but explicitly reclassifies the update range after any non-doc own result. Consider common base B with `src/example.js=0`; pushed docs branch R adds README; development D changes the source to 1; merge M has parents `(R,D)`, retains source 0 (an ours/evil merge), and edits README. The merge-parent and freshness checks pass; `D..M` contains source plus README, but `R..M` contains README only. The stated algorithm therefore selects docs despite its own full result. This also defeats the required evil-merge control if that control only adds a new code path visible in both ranges.
  Observed input: the fallback specified at plan lines 79-81; classifier inputs `src/example.js\nREADME.md\n` and `README.md\n` produce respectively `route=full, tier=3` and `route=docs, tier=1` (probe below).
  Affected scope: otherwise eligible integration refreshes whose final tree differs in code from the integration base while their update range does not expose that difference.
  Falsifier: in a disposable clone, the `(R,D)->M` example must run/refuse through a red full-gate stub; the same merge retaining D's source and changing only README must take docs. If the proposed algorithm already does this, provide the transcript and explain the path that overrides line 81.
  Fix: specify a retained full-gate veto for this case instead of losing the non-doc final-tree result, and reconcile that rule with the blanket promise that fallback routing is unchanged. Add this precise case to the existing manual evidence procedure, not a new suite.

  Narrow classifier probe (no git, hook, gate, or fixture execution), exit **0**:
  ```python
  import subprocess
  for label, paths in [("own-final-tree", "src/example.js\nREADME.md\n"),
                       ("update-range", "README.md\n")]:
      p = subprocess.run(["bash", "utils/ci-route.sh", "push"],
                         input=paths, text=True, capture_output=True)
      print(label, "exit="+str(p.returncode))
      print("\n".join(x for x in p.stdout.splitlines()
                      if x.startswith(("route=", "tier="))))
      assert p.returncode == 0 and p.stdout
  ```
  Decisive output: `own-final-tree exit=0 / route=full / tier=3`; `update-range exit=0 / route=docs / tier=1`. Invoked with `python3 -` after `export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"; mkdir -p "$TMPDIR"`. The Git DAG example is source reasoning, **[Unverified — needs clone run]** end to end.

- **[Should] F2 — the ancestry predicate does not establish the claimed merge-only scope.** Plan lines 73-78 do not require any merge in the selected range. For linear `R -> D -> L`, where remote feature is R, fresh development is D (adds source), and L adds README, `mbs=D` is not an ancestor of R and the merge-parent loop is empty. Own classification becomes docs although the previous update range includes code. This contradicts “linear push unchanged” at line 106 and the rejected broader alternative at lines 94-95. Also, “A merge from another branch fails here” is too strong: a side-branch parent X already reachable from current development T satisfies the ancestor test even if the feature merged X rather than development. Commit ancestry does not retain the branch name used in a merge.
  Observed input: the universal non-first-parent condition at plan lines 77-78, with no nonempty-merge requirement; the explicit linear-push control at line 106.
  Affected scope: fast-forward updates that import integration history without a merge, and side-parent ancestry already included in the advertised integration tip.
  Falsifier: the `R -> D -> L` update must keep its original full route, while the ordinary `(R,D)->M` docs refresh must narrow; a docs merge of side tip X reachable from T must satisfy the explicitly chosen other-branch policy. These DAG cases remain **[Unverified — needs clone run]**.
  Fix: state an actual qualifying integration-merge requirement and the precise conservative parent shape admitted. Explicitly address the already-integrated side-tip case rather than promising that ancestry proves branch provenance; no new branch-provenance subsystem is warranted. Include these distinguishing inputs in the manual controls.

- **[Should] F3 — preserve classifier failure status in the routing change; the existing hook can accept partial paths.** Whole-file sweep found `githooks/pre-push:227` returning failure from a diff, while `:228` still lets the classifier consume earlier paths and `:263` masks the pipeline failure with `|| true`. `:265` and `:271` then accept its stdout. For a mixed push, one readable README diff followed by an unreadable tree can therefore emit `route=docs` from an incomplete union. This is pre-existing, not evidence that the proposed helper has already been implemented incorrectly.
  Observed input: `_cls="$(classify_push 2>/dev/null || true)"` at `githooks/pre-push:263`, following the per-pair diff pipeline at `:224-228`.
  Affected scope: classification where at least one diff emits docs paths and another diff fails (for example, commit ancestry exists but a required tree object is unavailable).
  Falsifier: an existing-suite/manual disposable-clone case with a successful first docs range and failing second diff must refuse narrow routing despite classifier stdout saying docs; all-readable docs ranges must still narrow. Runtime reproduction is **[Unverified — needs clone run]**.
  Fix: make successful classification status a prerequisite for accepting either own or update results, discarding partial stdout on failure. Fold this into the already-planned top-level routing edit and manual per-ref check.

- **[Nit] F4 — correct the consumer inventory.** Plan line 67 says “No other reader exists,” but `githooks/pre-push:305-306` reads `_real_ref_pairs` for exact-commit receipt reuse. Its `${_pair%%|*}` extraction remains safe with a third field, and length checks at `:127`/`:302` are also unaffected. Update the inventory to say two parsers require changes and receipt reuse was inspected and needs none. `_base_pairs` readers at `:224-227`/`:286-288` remain two-field readers and must keep their separate contract.

- **[Nit] F5 — make the CHANGELOG step respect the active policy.** A gate-narrowing bet merits a durable rationale, already present in the plan, but line 82 unconditionally schedules a branch CHANGELOG edit. `PROJECT/PDDA.md:1064-1068` disables those for off/unset/landing and allows them only for branch mode; `.pdda-mode` contains no override. State that the changelog follows resolved `CHANGELOG_WRITES`, with the rationale carried in the plan/PR when branch writes are disabled.

**Remaining source-backed answers**

- **[Pass] Reuse and final-tree basis are appropriately small.** The existing owner is `githooks/pre-push:124-228`; the docs decision is already centralized in `utils/ci-route.sh:63-70` and `:452-477`. `--no-renames` at hook `:227` exposes both sides of a rename, including deleted tests. Mode and gitlink changes produce changed paths; the existing path policy, not file contents or type, decides their route. The claim “any code” must be understood within that policy (for example, `docs/*` is explicitly a docs surface at classifier `:65`). F1 concerns losing a code result the classifier actually recognizes, not redefining that policy.
- **[Pass] Freshness extraction has the right source owner.** Hook `:145` probes the push URL; `:158-165` bounds the probe and rejects partial output on nonzero exit; `:174-177` rejects absent advertised tips; `:192-205` handles equality, ambiguity and empty bases. Preserve those returns and `_base_note` diagnostics. Cache success AND failure in the parent shell: a helper called solely inside `ownbase="$(own_diff_base ...)"` cannot persist its cache/global notes to later pairs. First-push behavior remains a delivery check, not something proven by this plan review; existing controls cover pushurl disagreement, partial probe failure, ambiguous bases and mixed refs (`test/gh544-pre-push-gate.sh:375-480`).
- **[Pass] The integration-entry test avoids the normal probe.** Under plan `:73-75`, a docs commit after an already-pushed development merge has the same integration merge-base already ancestral to remote and skips narrowing/network. A genuinely newer integration merge can qualify. A conventional divergent rebase still fails the existing remote-ancestor check (`githooks/pre-push:209-210`), which must run before narrowing. Octopus merges pass the proposed predicate only when every extra parent is ancestral to the tip; first-parent-development merges with an unintegrated feature as second parent conservatively fail it. Those are ancestry conclusions, not executed Git controls; F2 asks the plan to make the admitted shape explicit.
- **[Pass] Per-ref aggregation and the original fallback ranges should remain separate.** Hook `:224-228` classifies the union; tier 2 independently reads `_base_pairs` at `:286-288`, and receipt reuse checks every SHA at `:305-319`. Carrying destination refs allows per-ref refusal of the new exception for development/main without prohibiting their existing docs routes. Mixed refs need the F3 failure check; a no-op integration ref must remain harmless, as pinned at `test/gh544-pre-push-gate.sh:438-456`.
- **[Pass] The proposed base/candidate contrast can reject an unchanged candidate.** Plan `:102-103` requires the same refresh to change from full to docs; an unchanged candidate cannot satisfy that pair. Make this a checked outcome, not just two exit-0 logs: require nonempty captures, route/gate-invocation assertions and candidate/base identity in provenance. Use the existing red full-stub / green docs-stub pattern (`test/gh544-pre-push-gate.sh:139-155`) so the base really refuses and candidate succeeds. F1-F3 identify the additional discriminating inputs missing from the named controls. Existing suites plus retained manual evidence comply with `AGENTS.md:166-172`; no new suite or runner is needed.

Scope and limits: read the entire plan and all 353 lines of the hook, the classifier's push/docs/full logic, fixture-driving and freshness sections of gh544, and the no-new-tests policy. Graph tools were unavailable; source reads were the fallback. No git command, fixture, test suite or gate was run. The whole-file sweep found F3; no other demonstrated pre-existing defect is claimed. This is a plan review, not delivery approval or an assumption that a later gate will run. Reversibility: **Easy** for the eventual one-file hook edit (revert that edit), with shared push-routing blast radius and under-gating as the failure signal.

Handing off to Producer (claude-a): disposition F1-F5, revise the plan, and return for round 2.

swept file: yes
VERDICT: FAIL
Basis: The proposed fallback loses the required final-tree code veto, the merge predicate admits history outside the stated scope, and the existing partial-classification failure path needs to be covered in the planned routing edit. The classifier probe supports F1; end-to-end DAG and failure controls remain explicitly unverified until a disposable-clone run.

### Producer · Round 1 · claude-a

Dispositions (plan revised in `PROJECT/2-WORKING/GH-1537-PREPUSH-OWN-DIFF-ROUTING.md`, Plan items 1-5, Verification and Risks):

- **F1 — Implemented.** The veto is now explicit: when any pair narrowed and the own-diff route is not exactly `docs`, the push takes
  the full gate (not tier 2, not the update-range result). Your `(R,D)->M` "ours" merge keeps the old source, so `D..M` carries the source
  and the push goes full; the same merge retaining D's source and editing only a README narrows to docs. Both are named manual controls.
  Consequence stated in Risks: a code branch merging docs-only development content now routes full (the issue's control (b)).
- **F2 — Implemented.** Narrowing requires at least one merge the branch made itself (`rev-list --merges --parents remote..local ^tip`
  non-empty) with every non-first parent an ancestor of the tip; a linear or fast-forward import (`R -> D -> L`) is not narrowed.
  The plan now says commit ancestry cannot prove branch provenance: a merge of a side commit already on the tip counts as an integration
  merge (a control records it); a merge of a commit not on the tip is refused. No provenance subsystem.
- **F3 — Implemented (folded into the routing edit).** `_cls="$(classify_push 2>/dev/null)" || _cls=""` so a failed later diff cannot
  leave partial `route=docs` stdout. Manual control: two refs, second ref's tree object removed, red on base (docs), green on candidate (full).
  I checked `utils/ci-route.sh push` exits 0 for docs, code, tier-2 and empty input, so the status test does not turn a normal answer into full.
- **F4 — Implemented.** Inventory corrected: two parsers change (`:131`, `:180`); receipt reuse (`:305-306`) and the length checks
  (`:127`, `:302`) inspected, no change; `_base_pairs` stays two-field.
- **F5 — Implemented.** No CHANGELOG write (`CHANGELOG_WRITES` off by default, `.pdda-mode` has no override); the rationale lives in the
  plan and the PR.
- **Pass notes kept:** the probe and `own_diff_base` are called directly in the parent shell and cache success and failure (your
  command-substitution point); the check asserts non-empty captures, the gate that ran, and base/candidate hook identity.

Handing off to Reviewer (codex) for Round 2.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
