---
name: express
description: >-
  Fast lane for explicit /express requests: critical, risk-bounded code hotfixes
  with an existing covering suite, or small documentation text/image updates
  with --docs-only and the existing PDDA docs suite. Uses a fresh gated task
  clone off origin/<base>, bounded changes, an open issue, the releases
  ledger, born-complete docs, commit-bound verification, fast-forward direct
  landing and reconciliation. Uses risk-based review for skill
  documentation and changes to execution authority; current driver admission stays narrower. No new suites or gate runners.
  Refuses unsafe surfaces, diverged branches and unqualified evidence; do not
  use for Costly or one-way-door changes.
---

# /express — bounded hotfix and documentation fast lane

One motion: the update, its existing verifier, the ledger writes, the
born-complete capture doc, the CHANGELOG entry, the landing, and the
reconciliation — all before the operator's coffee cools. The guardrails are the
skill; the speed is a side effect.

---

## Recite this — verbatim, as the first thing in your first response

> **Express Discipline:**
> 1. **Verify clone & pre-flight bounds (Phases 0–2).** Require a task clone off `origin/<base>` (the resolved integration branch; `development` in XYZ Forge) ($\le 2$ local commits, canonical pre-push gate installed via `githooks/install.sh --check`); enforce strict subsystem bounds ($\le 4$ files / $\le 150$ insertions) and hard refusals on kernel, coordination, or shared Bash surfaces.
> 2. **Validate issue & verification lane (Phases 3–4).** Confirm the tracking issue is OPEN. Code hotfixes require an existing registered covering suite. Ordinary documentation text/images use `--docs-only`, which selects the existing registered PDDA docs suite; no critical-hotfix rationale or runtime behavior suite is required. Do not add a suite in this lane; an uncovered fix goes through `/start-task` under the host repo's own test policy (XYZ-forge: GH-831).
> 3. **Generate born-complete docs & append changelog (Phase 5).** Scaffold capture doc in `PROJECT/2-WORKING/` with Status, Acceptance, Merge evidence, and Lessons Learned present from birth; append the entry to `CHANGELOG.md` in the same motion.
> 4. **Execute qualified gate & dial-in releases ledger (Phases 6–7).** Register roadmap issue in `releases.db` and dial into active release (`releases next`); execute the selected existing suite green, prove tree identity, and re-snapshot tree to prevent drift.
> 5. **Direct fast-forward landing & 3-push reconciliation (Phases 8–11).** Commit qualified paths (`Closes #N`), direct push fast-forward to `origin/<base>` (`XYZ_SKIP_PREPUSH=1`), verify remote issue closure, ship release evidence, and execute clean-tree `wave_reconcile --commit`.
>
> **Overall Goal:** Bounded hotfix or documentation update verified, ledger-tracked, landed directly to the integration branch, and reconciled with a complete paper trail in one single, unpaused motion with zero bypassed safety invariants.

Then begin work.

---

**Design provenance:** proposed on #259 (comment 5434441831, v2), filed as
#267, upgraded in #516 (True Direct-Push Mode, commit-driven reconciliation,
branch flexibility, recovery subcommand, dry-run, and central telemetry):
re-use the releases verbs, `wave_reconcile`, the pre-push gate, and `.tick`
events rather than building parallel machinery. Where jog pauses at each
landing boundary by default (orchestrator outer review), express inlines those
same predicates — base branch, diff size, gate receipts — as pre-flight
refusals, because a pause would defeat the reason /express exists. That is the
foundational difference, and it is the only one.

## Documentation text and images (GH-1080)

Small, reversible documentation edits may use express when the operator explicitly requests it;
they need not be critical hotfixes. Add `--docs-only` to each step (including `resume`), or use:

```bash
python3 utils/py/express.py run --issue <N> --docs-only --summary "Content/link/rendering checks and outcome"
python3 utils/py/express.py resume --issue <N> --docs-only --sha <landing-sha>
```

The driver selects **`test/pdda-repo-contract.sh`**, the existing registered suite that runs the
actual deterministic PDDA docs gate. Its receipt records that exact command; it does not claim
runtime coverage. The full runtime suite is not required merely because text or an image changed.
Before running, check content accuracy, relative links and image rendering as applicable, and put
the concrete results in `--summary`. Do not claim a render or visual check that did not run.

**Vendored hosts (GH-1169).** In a repo that uses the harness from a gitignored `.xyz/`, run
`python3 .xyz/utils/py/express.py --root . … --repo <owner>/<name>`. The docs lane then runs the host's own
PDDA install, `utils/pdda/pdda.sh run`, under `PDDA_MODE=full` (as in XYZ Forge; a host's `observe` mode never
fails), and the receipt records `bash utils/pdda/pdda.sh run`. Gate wiring accepts the host's own pre-push hook,
or reports that the host has none (the landing push bypasses pre-push by lane design). Harness tools come from
`.xyz/`. Pass `--release` when the host's `releases next` is stale. Code hotfixes still need a `validate.sh` TESTS
registry and refuse `suite-unregistered` without one.

Judge documentation by the effect of the proposed change, not merely its filename or whether
an agent reads it. Editorial wording, links, images and bounded documentation-only skill changes
may use the lightweight hotfix path when explicitly requested and appropriately reviewed. Inspect
the actual diff and its consumers; a Markdown extension alone does not establish low risk.

Changes to executable code, runtime configuration, permissions, safety gates, destructive behavior
or material execution authority require proportionate, explicit review and operator approval for
that change. Approval to edit documentation is not standing permission to weaken a gate or expand
execution authority. Mixed code/docs work must meet the applicable code-hotfix or normal PR rules.

Keep the existing operator-tunable file/insertion bounds, issue traceability, current-head evidence,
repository identity checks, concurrency protection and safe fast-forward publication. Generated
artifacts still use their canonical writers. No filename-based exemption bypasses those controls.

**Current driver compatibility:** `express.py --docs-only` currently has a narrower path allowlist
and rejects `SKILL.md`; its landing pushes also set `XYZ_SKIP_PREPUSH=1`. This policy wording does
not change those executable checks or authorize ignoring them. When a requested docs hotfix cannot
meet the driver's admission or the operator's required normal-hook publication, report the exact
mismatch before executable changes. Until the driver supports these paths, manual hotfix
handling requires explicit operator authorization for that exact change and procedure. Do not relabel
a skill as a code hotfix merely to evade documentation admission, or silently skip a gate.

## Procedure

Normally run the driver; it enforces the order. Do not hand-perform its steps without an
explicit, scoped operator override. For a separately authorized manual documentation hotfix,
record the precise scope and driver mismatch, independently review the diff, retain canonical
ledger writers and current-head documentation evidence, and publish through the installed normal
pre-push hook. Recheck repository identity, ownership and the exact remote base-branch tip at
publication; a concurrent update means fetch/reconcile/revalidate, never force push. This exception
is not standing bypass authority and does not change express.py or its default push behavior.

```bash
# 0. From the task clone carrying the fix (SOP §4 clone, <= 2 commits ahead, hooks installed):
python3 utils/py/express.py check --issue <N> --suite test/<existing-suite>.sh   # steps 0–4
python3 utils/py/express.py docs  --issue <N> --suite test/<existing-suite>.sh --summary "<one line>"  # step 5
python3 utils/py/express.py ledger --issue <N>                               # step 6
python3 utils/py/express.py land  --issue <N> --suite test/<existing-suite>.sh   # steps 7–11
# or the whole motion at once:
python3 utils/py/express.py run --issue <N> --suite test/<existing-suite>.sh --summary "<one line>"

# Inspect what would happen without modifying disk, DB, or git state:
python3 utils/py/express.py run --issue <N> --suite test/<existing-suite>.sh --summary "<one line>" --dry-run

# Integration branch (GH-1144): express lands on the base it resolves once per run — `--base <branch>`,
# else origin/HEAD, else GitHub's default branch, else it refuses `base-unresolved`. In XYZ Forge that is
# `development`; below, "development" means that resolved base. Pass the same `--base` to every step and
# to `resume` when origin/HEAD is not set.

# Recover/resume an interrupted express run (e.g. dropped network or post-push closeout fault).
# --suite names the registered suite the landing ran: resume validates the COMMITTED receipt
# (read from HEAD, never the working tree) against it and never runs a suite or writes evidence
# (GH-592). With no committed valid receipt it refuses BEFORE closing the issue or shipping and
# prints the recovery recipe below.
python3 utils/py/express.py resume --issue <N> --suite test/<existing-suite>.sh [--sha <SHA>] [--base <branch>]

# Recovery recipe when resume refuses. Run in a FRESH disposable full clone. Every inspection fails
# closed: `set -euo pipefail` is active (not a comment), cleanliness is asserted with git's own exit
# codes (never by an empty-stdout test), and snap() aborts on the first failing command.
set -euo pipefail
SHA=<SHA>; N=<N>; SUITE=test/<existing-suite>.sh; BASE=<base-branch>   # development in XYZ Forge
git checkout "$SHA"
git diff-index --quiet HEAD -- && [ "$(git ls-files --others --exclude-standard | wc -c)" -eq 0 ]   # 1. clean baseline
LOG=$(mktemp -t express-recovery)                                                                 # 2. log OUTSIDE the tree
snap(){ git rev-parse HEAD && git status --porcelain && git remote -v && git config --list --local | shasum -a 256; }
BEFORE=$(snap) || { echo "identity inspection failed"; exit 1; }; printf '%s\n' "$BEFORE" >"$LOG"
set +e; bash "$SUITE" >>"$LOG" 2>&1; RC=$?; set -e; echo "rc=$RC" >>"$LOG"                     # 3. record rc at once
AFTER=$(snap) || { echo "identity inspection failed"; exit 1; }; printf '%s\n' "$AFTER" >>"$LOG"
[ "$BEFORE" = "$AFTER" ] || { echo "VOID: identity drifted during the suite — no receipt"; exit 1; }  # 4.
git checkout "$BASE" && git diff-index --quiet HEAD --                                           # 5. same helper, actual rc
REC=$(python3 -c "import sys; sys.path.insert(0,'utils/py'); import express; print(express.write_receipt('.', '$SHA', $N, '$SUITE', $RC, base='$BASE'))")
cp "$LOG" "$(dirname "$REC")/recovery-run.log"                                                   # 6. retain the run beside the receipt
git add TESTS-RESULTS && git commit -m "chore(express): recovery receipt GH-$N (commit $SHA)" && git push origin "$BASE"
python3 utils/py/express.py resume --issue "$N" --suite "$SUITE" --sha "$SHA" --base "$BASE"                 # 7.
```

In a vendored host (GH-1169) the recipe differs in four places: set `REPO=<owner>/<name>` (the host's slug; express's
default is XYZ Forge's), run the suite as `PDDA_MODE=full PDDA_ACTIVITY_LOG=/dev/null bash utils/pdda/pdda.sh run`
instead of `bash "$SUITE"` (with `SUITE='utils/pdda/pdda.sh run'`, the receipt spelling), import express from
`.xyz/utils/py` in step 5, and resume with
`python3 .xyz/utils/py/express.py --root . resume --issue "$N" --docs-only --sha "$SHA" --base "$BASE" --repo "$REPO"`.

Before landing, `cmd_land` qualifies the change, resolves the exact owned full issue
URL, and invokes `roadmap update --gid OWNED_ROW --accepted-start` (schema009 must
already be deliberately installed). It then requalifies against the existing
driver-projection allowlist before snapshots/testing. Dry-run previews only;
registration via `ledger` is not admission. Interrupted/repeated land preserves
one effective start; receipt-based `resume` never starts work after landing.


What each phase asserts (all refusals and fired runs write `.tick/express/*` — a sibling of tick's coordination log, never inside it (GH-694) — and mirror to `~/.config/xyz/events/`):

0. **Tree of execution** — task branch based on `origin/<base>` (the resolved base) with $\le 2$
   local commits (GH-516; $> 2$ refuses with `too-many-commits`; diverged branches
   refuse with `task-clone`), no scratch paths, and `bash githooks/install.sh --check`
   proves the canonical pre-push stub (`gate-unwired`; hooks do not travel, GH-549).
   Express never commits over peer work (GH-527). Hand-edits to ledger files or
   generated views are refused; only the driver's verbs may write them.
1. **Bounds** — ≤ 4 core files / ≤ 150 insertions, single subsystem for code hotfixes (unless
   `--allow-multi-subsystem` is passed, or micro-diff tolerance applies: $\le 30$
   insertions across $\le 2$ files auto-passes, GH-516). Only the lane's OWN
   paperwork (`CHANGELOG.md` and the current issue's capture doc resolved by
   `capture_doc_path(root, issue)`) is exempt. Every other `PROJECT/**` path and
   operator .md edit (README, governance, skills) COUNTS (a gateless merge never
   rewrites policy unbounded).
   Defaults are operator-tunable via `--max-files` / `--max-insertions`; the
   refusals are never optional.
2. **Hard refusals** — frozen twins and shared Bash runtime (GH-308), any
   new/edited `.sh` under `utils/` or `relay-automation/` (GH-551),
   coordination-kernel and containment surfaces (AGENTS: at least Costly).
3. **Issue first** — the tracking issue exists and is OPEN. Closed => the work
   may already be landed; run the preflight probes instead of re-doing it.
4. **Suite** — code hotfixes name an existing covering suite registered in
   `validate.sh` TESTS; `--docs-only` selects the existing PDDA docs suite above. Do not
   add a new suite to get one; an uncovered code fix goes through `/start-task` under the host repo's own
   test policy (in XYZ-forge: `AGENTS.md` *No new tests*, GH-831).
5. **Docs born complete** — capture doc scaffolded in `2-WORKING` with Status,
   Acceptance, Merge evidence, and `## Lessons Learned (For Future Agents)`
   present from birth (highly recommended — since GH-693 the reconciler warns
   rather than refuses promotion when it is missing; fill it in anyway),
   plus the CHANGELOG entry appended in the same motion.
6. **Ledger** — `roadmap add` if the issue is unparked, then `manifest dial-in`
   against the active release (`releases next`) with an express reason. The
   adopted release/leaderboard projections refresh
   in the same phase and are the only accepted driver outputs.
7. **Gate** — the fix's suite runs green, the tree is RE-SNAPSHOTTED afterwards
   by path and content (`tree-drift`: new paths and changed qualified bytes both
   refuse). Gate identity is re-proven after the suite, staging uses explicit
   pathspecs, and the direct push passes `XYZ_SKIP_PREPUSH=1`. That bypasses the
   FULL pre-push gate (`validate.sh`) by lane design (GH-267/GH-516) — it is not a
   duplicate of Step 7, which ran only the fix's registered suite. The receipt
   written in Step 9 says exactly that (`gate: express-suite`).
8. **Land** — one commit of exactly the qualified paths with `Closes #N`, then
   `git push origin HEAD:<base>`. A concurrent update refuses as a normal
   non-fast-forward; there is no force push and no PR. The closeout switches to clean,
   current `<base>` (ship/reconcile state never rides the task branch).
9. **Receipt, then ship with evidence** (GH-592) — from clean, current
   `<base>`, the driver writes `TESTS-RESULTS/<date>+GH-<N>-express/provenance.jsonl`
   (`commit` = the landing sha, `command` = the suite, the real `rc`,
   `gate: express-suite`) and then `manifest ship --gid <rel> --evidence "<sha>;
   registered suite <suite> green (express-suite, not the full gate); receipt <path>;
   direct <base> push"`. Ship precedes the issue close below, so the
   GH-205 shape (an issue closed while its manifest item is still dialed_in)
   can only arise if the ship persist itself fails — which exits non-zero with
   an `express-reconcile-failed` receipt and is what `resume` recovers.
10. **Close the issue** — the commit message says `Closes #<N>` and lands on the
    default branch; the driver verifies and closes explicitly if GitHub has not.
11. **Persist, reconcile cleanly, persist — fail closed.** The landing is
    three pushes total: (1) the hotfix land push (step 8), then from
    `<base>`, (2) the ship outputs are committed and pushed, and only
    then (3) `wave_reconcile.py --commit <sha> --base <base> --gate` runs from the clean tree —
    `--gate` proves the receipt from step 9 is attributable to this landing (it
    proves attribution, not test success) and its stdout is printed; its
    outputs form the third commit and push. The ship commit (2) carries exactly
    the receipt file and nothing else under `TESTS-RESULTS/`. Every post-push fault exits
    non-zero with an `express-reconcile-failed` receipt; success prints only
    after every boundary.

## After the run

- Confirm the tail: `releases check` clean, `pdda.sh issue-doc-sync` 0 errors,
  capture doc promoted (or, under an OPEN umbrella, correctly left in
  `2-WORKING` with merge evidence — that is success, not failure).
- `standup` reports the weekly express count; a rising counter means the normal
  lane is too slow — fix the lane, don't normalize express.

## Non-goals

- No automatic override flag: a refused driver run defaults to the normal fresh-clone PR lane.
  The explicitly authorized manual documentation exception above is scoped to its named change
  and procedure; it grants no standing `--force`, gate bypass or automatic admission authority.
- No Costly/one-way-door work, ever (see step 2 refusals).
- No force push (direct landing pushes fast-forward with Step 7 qualifying suite receipt and `XYZ_SKIP_PREPUSH=1`).
