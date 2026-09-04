---
Goal: QA the GH-421 plan — automate post-merge wave reconciliation
Date: 2026-09-04
NEXT: Reviewer
STATUS: Open
---

# Context

Adjudicate the plan at `PROJECT/1-INBOX/GH-421-AUTO-WAVE-RECONCILE.md` against the code it
describes. This is a **review turn** — report, do not edit. Cite `file:line` wherever you disagree
with a specific claim.

Read in full:

- `PROJECT/1-INBOX/GH-421-AUTO-WAVE-RECONCILE.md` — the plan under review
- `utils/py/wave_reconcile.py` — the tool being automated (esp. `:459-560` ROADMAP.md writes,
  `:671` DB rollback, `:715` the ledger call, `:925` the OPEN-issue guard)
- `utils/py/releases_app.py:3374-3383` — the `roadmap sync` releases-mode skip
- `.pdda-mode` — the `ROADMAP_SOURCE=releases` marker
- `.github/workflows/ci.yml` — esp. `:99-112` (triggers, concurrency, permissions) and `:559`
- `AGENTS.md` §13 and `GUIDING-PRINCIPLES.md` — the house rules the plan claims to follow

Repo context you should assume rather than rediscover: this repo is in releases-mode, the DB
(`releases.db` via `releases.sql`) is planning truth, `ROADMAP.md` is frozen legacy, and all ledger
writes go through `utils/py/releases_app.py` — never direct SQL.

# Questions

Answer each one explicitly. A bare "looks fine" on any of these is not an answer.

1. **Is the phase ordering right, and is the blocker real?** The plan refuses to wire any trigger
   until `wave_reconcile.py` writes the DB, arguing that automating it first would write a wrong
   record at machine speed and exit 0. Verify that claim against `wave_reconcile.py:715` and
   `releases_app.py:3374-3383`. Is `roadmap sync` genuinely the tool's *only* ledger write — or did
   the plan miss a DB write elsewhere in the file? If the blocker is overstated, say so.

2. **Is Phase 1's write set correct and complete?** The plan maps two transitions to
   `manifest ship --evidence` and `roadmap repoint`. Are those the right verbs? Is anything the
   reconciler already computes left without a DB write — in particular, what should happen to a
   `roadmap_items` row's `status_marker` when work completes, given that in releases-mode
   `roadmap sync` is the only thing that used to set it? If that is a real hole, name it.

3. **Are the six determinism requirements sufficient AND individually testable?** For each of the
   six, say whether a test can actually falsify it as written. Call out any that is a statement of
   intent rather than a checkable property. Specifically: is the idempotency claim ("second run
   writes nothing") testable given the reconciler regenerates dashboards that may embed timestamps?

4. **Is `pull_request: closed` the right trigger, and is the anti-loop argument sound?** The plan
   claims that shape cannot self-retrigger. Verify. Also: what happens when a PR merges while
   another reconcile is mid-run — is `concurrency: {group, cancel-in-progress: false}` sufficient,
   or does the queued run operate on a base commit that has since moved?

5. **Does anything here invent a subsystem it does not need?** Judge through a YAGNI lens. The plan
   claims "no new script or module," but Phase 2 adds a new workflow file. Is a separate
   `.github/workflows/wave-reconcile.yml` justified, or should this be a job inside the existing
   `ci.yml`? Argue the cheaper option if there is one.

6. **What is missing that would bite in production?** Concretely: `--gate` is left as an open
   question in the plan; a reconcile needs a token with `contents: write` and this repo's `ci.yml`
   is `contents: read`; a bot-authored commit to `development` may interact with branch protection.
   Name the failure modes the plan does not cover, and rank them.

7. **Are the reds falsifiable?** The plan proposes reproducing PRs #420 and #409 as red controls.
   Can those actually be replayed deterministically, or does replaying a merged PR require state
   that no longer exists? If they cannot be replayed, propose reds that can.

Flag anything wrong, missing, incorrectly scoped, or over/under-engineered. Where you disagree with
the plan, cite the line in the plan and the line in the code that contradicts it.

Write your verdict below. Set `STATUS: Approved` only if the plan is implementable as written;
otherwise leave it Open and hand back with your findings.

<!-- ▽ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK ▽ -->
▶ TAKE YOUR TURN (codex)
<!-- △ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK △ -->

## Codex review — changes requested

**Verdict: not implementable as written; leave `STATUS: Open`.** The ordering bet is right,
but Phase 1 has no complete, supported DB transition and Phase 2's claimed queue semantics are
false. This is **Costly** to get wrong: a privileged bot can durably corrupt the planning ledger or
silently miss reconciliations; rollback must restore the DB and dump before any bot commit.

1. **Phase ordering / blocker — correct, with one wording correction.** The sole *potentially
   mutating* ledger operation currently invoked is `roadmap sync` (`utils/py/wave_reconcile.py:714-727`),
   and releases-mode deliberately returns success without writing (`utils/py/releases_app.py:3374-3385`).
   `releases check` is another ledger CLI call, so plan `:43` is not literally the only call, but it
   is the only ledger write attempt; the remaining downstream steps are projections/planning, not a
   replacement DB transition. The blocker at plan `:25-29` is therefore real: today it moves the doc
   and mutates legacy ROADMAP.md (`utils/py/wave_reconcile.py:926-957`) while the canonical DB stays
   untouched.

2. **Phase 1 write set — incomplete and partly malformed.** `manifest ship` is the right state
   transition, but plan `:62` omits its required positional `<issue>` argument: the CLI needs
   `manifest ship --gid <release> <issue> --evidence <merge-sha/PR>`
   (`utils/py/releases_app.py:2248-2267`). More importantly, the reconciler currently derives only
   closing issue numbers (`utils/py/wave_reconcile.py:897-906`); it has no manifest-member/release-GID
   lookup (and `--marathon` is parsed but otherwise unused at `:796-798,873-999`). The plan must
   specify the lookup and the no-member behavior.

   `roadmap repoint` alone is also wrong. It changes only `doc_path` and embedded `raw_text`
   (`utils/py/releases_app.py:3277-3289`); it does not move the row's `section` or its
   `status_marker`. In releases-mode, the old sync updated every roadmap field, including both,
   from the legacy transition (`utils/py/releases_app.py:3475-3534`). `roadmap update` can change
   `section`/`raw_text`, but cannot update `status_marker` (`:3322-3368,4984-4989`). Thus a completed
   row would still display its old marker (typically `🆕`) even if its doc was repointed. Phase 1 needs
   a supported atomic lifecycle write (extend `roadmap update` to derive/set marker from the new
   raw text, or add a purpose-built verb), plus a `Completed` section/raw-text/position policy; it
   cannot honestly claim "verbs that already exist" at plan `:58-66`.

   The rollback claim is incomplete too. The journal snapshots `releases.db` and `releases.sql` only
   inside `run_subprocesses` (`utils/py/wave_reconcile.py:670-710,987-993`), after the proposed
   per-issue DB writes would occur. Snapshot before the first new DB mutation (or use one transaction),
   and test byte-for-byte restoration on an injected failure between the manifest and roadmap writes;
   `releases check clean` alone can accept a clean but partial state.

3. **Determinism criteria — not all are presently falsifiable as stated.**

   - **Idempotency** is testable with a controlled fixture and a complete worktree digest, but currently
     false: each apply runs `export_timeline.py --preview` (`utils/py/wave_reconcile.py:729-735`), whose
     payload embeds the current UTC timestamp (`utils/timeline/export_timeline.py:517-521`). The plan's
     `:95-96` needs a frozen clock or a semantic/projection exclusion; otherwise its promised second
     byte-identical tree cannot pass.
   - **Serialized** is testable only after defining the intended queue behavior. Plan `:97-100` tests
     a YAML field, not the behavior it asserts: GitHub's default concurrency permits one pending run,
     and a later pending run replaces it. `cancel-in-progress: false` protects a running job only;
     add `queue: max` (and an integration/config red for three close events) or coalesce unprocessed
     PRs deliberately.
   - **No trigger loop** is a checkable workflow-shape property and is sound for this workflow: its
     `pull_request: closed` event cannot be caused by the reconciler's direct push. Pin that this
     workflow has no `push` trigger; its bot push may still run the existing CI workflow, which is
     not a reconcile loop.
   - **Fails loudly, never partially** is intent, not yet a falsifiable property. The existing
     rollback only proves the mutations it has snapshotted; add failure injection after every
     mutation boundary and compare the complete pre/post DB, dump, docs, and generated-artifact set.
   - **Dry-run predicts apply** is not specified in a testable normalized form. The current dry run
     deliberately omits dashboard/timeline exports (`utils/py/wave_reconcile.py:721-738`), so a raw
     file diff cannot be compared to apply. Emit/compare a stable planned-transition manifest,
     while separately asserting dry-run has zero mutations.
   - **Least privilege** is testable by parsing the workflow permissions, but the plan must name the
     job-level scope and prove the existing workflow remains read-only (`.github/workflows/ci.yml:105-112`).

4. **Trigger and concurrency.** Plan `:73-85` correctly chooses `pull_request.closed` plus the
   merged/base guards; a direct reconcile commit does not create another PR-close event. The
   concurrency conclusion is wrong: a PR closing while one job runs can cause an earlier pending
   run to be cancelled/replaced, so its PR is never reconciled. Also make checkout explicit:
   the tool requires a clean checked-out `development` branch and then does `git pull --ff-only`
   (`utils/py/wave_reconcile.py:849-854`), so the job must check out `development` as a local branch
   and fetch enough history/refs. A queued run should reconcile its event PR against freshly pulled
   development; that is safe only after all event PRs are preserved in the queue (or an explicit
   catch-up scan is designed).

5. **YAGNI.** A separate `wave-reconcile.yml` is justified and cheaper than changing `ci.yml` here.
   Adding `closed` to the existing `pull_request` trigger would make its unrelated CI jobs run on
   closes and inherit CI's cancelling concurrency and workflow-wide `contents: read`
   (`.github/workflows/ci.yml:98-112`). A small isolated workflow gives the direct-write job its own
   event, queue, and job-scoped write permission without creating a runtime module or script. Correct
   plan `:14-15` to say "no new runtime script/module" rather than treating a privileged workflow as
   no new subsystem.

6. **Production omissions, ranked.**

   1. **Critical — incomplete/corrupt DB lifecycle:** the missing marker/section transition and
      missing manifest lookup/argument above either leave truth wrong or make every applicable run
      fail; late rollback snapshots can preserve a partial but internally valid write.
   2. **Critical — lost close events:** `cancel-in-progress: false` alone does not queue all pending
      reconciliations; require `queue: max` or an explicit catch-up design.
   3. **High — bot cannot land:** plan `:87-91` notes `contents: write` but does not specify job-level
      permissions, checkout/identity, a no-diff commit path, staging allowlist, push retry/conflict
      behavior, or whether development's protection/ruleset permits the Actions token to push. If
      protected branches require a PR or lack a bot bypass, direct automation simply fails after doing
      local work.
   4. **High — `--gate` remains unresolved:** Phase 2 invokes it at plan `:79-80`, while plan `:130-134`
      leaves it open. It will block receipt-less historical merges; worse, its current checker only
      proves that *any* receipt file exists, not that one belongs to this PR
      (`utils/py/wave_reconcile.py:281-298`). Decide policy and strengthen/remove the flag before
      automation.
   5. **High — workflow checkout contract absent:** see item 4; detached/stale checkout or an
      unavailable fast-forward makes the reconciler refuse before doing useful work.
   6. **Medium — broad artifact commit:** the reconciler can generate dashboards and plan documents
      (`utils/py/wave_reconcile.py:681-709,729-735`). The workflow must verify/stage the declared
      changed paths, otherwise a future downstream generator silently expands the bot's commit.

7. **Reds are not reproducible as proposed.** Plan `:111-120` says #420 and #409 can be replayed, but
   it also says their bad state was repaired manually; today's checkout/API state is therefore not the
   pre-fix state. Replaying a merged PR number against live GitHub cannot recreate the old active doc,
   dialed-in member, or former DB row. Keep those as historical evidence only. Make falsifiable reds
   from a committed minimal fixture plus `--offline` metadata: (a) a MERGED closing PR with a
   dialed-in manifest item, closed issue, active doc, and active roadmap row; assert old code leaves
   the DB unchanged and fixed code ships/repoints/marks completed; (b) an OPEN linked issue asserting
   no lifecycle move; (c) an injected failure after each mutation boundary asserting exact rollback;
   (d) two applies under a frozen clock and a three-event queue/config red. These are stable and
   witness the claimed failure modes without depending on mutable production history.

NEXT: Producer
