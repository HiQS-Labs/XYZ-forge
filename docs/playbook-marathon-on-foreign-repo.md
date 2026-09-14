# Playbook: Running a Marathon on a Foreign Repo (XYZ consumer, not a Forge-style repo)

> **Provenance:** distilled from the first full marathon run against an external consumer repo
> (`local-addon-nexus-ai`, umbrella issue jpollock/local-addon-nexus-ai#52, 2026-09-14). The target
> repo vendors `.xyz/` but has **no** `PROJECT/` PDDA structure, no `ROADMAP.md`, and a vendored
> harness copy that predates `releases_app.py`. Everything below is what had to be adapted, decided,
> or worked around — written as a repeatable recipe, not a trip report.
>
> **Rule zero:** none of this playbook belongs in the target repo. It lives in Forge so the next
> foreign-repo marathon starts from recipe, not archaeology.

## 1. Machine-local isolation before any harness work

The vendored `.xyz/` is machinery, not codebase. Keep it off origin with two **machine-local**
layers (neither travels with the repo — that is the point):

1. `.git/info/exclude` — the harness dirs and state files (`.xyz/`, `.tick/`, `XYZ.json`,
   `XYZ.heartbeat.json`, `.relay-driver.lock`, `.gate-evidence/`, `.relay-scratch/`, relay/marathon
   logs and locks). Not `.gitignore`: the shared file would advertise harness internals to every
   clone, and the harness is per-operator.
2. `.git/hooks/pre-push` — a regex guard that refuses any push whose commits touch harness paths.
   Test it against a path matrix before trusting it (harness paths must BLOCK, `README.md`-class
   paths must pass). Deliberate bypass stays `git push --no-verify`.

Verify with `git status --ignored --porcelain` (only expected dirs ignored) and
`git status --porcelain` (empty — nothing untracked-and-unexcluded that `git add -A` could sweep).

## 2. Umbrella issue first — even without PDDA structure

A marathon without an umbrella issue does not start; the umbrella keys waves, clone folder, and
closeout. On a foreign repo, open it in the target repo's tracker with: member issues, why-one-
marathon, wave sketch, acceptance rule for the arc as a whole, and run parameters (effort profile,
target branch, clone name).

Clone naming stays derived: `marathon-gh-<umbrella>-<slug>`, full clone, never a worktree, never
the operator's primary checkout.

## 3. Foreign-repo preflight: expect exit 6, then author capture docs

`swarm-preflight.sh --gh-issue <n>` reads the in-repo capture doc, never the issue thread. A repo
with no `PROJECT/` structure blocks at **exit 6** for every issue — that is the expected first
verdict, not a failure. The recipe:

1. Author `PROJECT/2-WORKING/GH-<n>-<slug>.md` per issue: frontmatter ratings
   (`complexity`/`risk`/`effort`), status, acceptance criteria, and a **Swarm Preflight Contract**.
2. Set the contract `gate` to the **target repo's real gate**, not the Forge default
   `bash validate.sh`. If the target has no validate script, name its test command
   (e.g. `npm test`). A contract naming a gate the repo does not have fails at fire time.
3. `artifacts`/`lanes` must be audited against the issue's actual write-set — a ready exit does
   not make a dishonest write-set safe.
4. Re-run preflight to exit 0 **before** cutting any branch.
5. Capture docs land via the first phase branch — the primary checkout keeps them untracked until
   then, so `git status` stays honest about operator state.

## 4. Missing `releases_app.py` in vendored copies (ledger + planner gap)

Old vendored copies may lack `utils/py/releases_app.py`; `marathon-plan.sh` imports it
(`ModuleNotFoundError`) and the ledger row CLI lives in it. Fallback recipe:

- Compute the plan by hand, deterministically, per the PDDA selection rule: gate on `risk <= 2`,
  rank by lowest `effort + complexity`, then fewest phases. Write the computation into the umbrella
  issue so it is reviewable.
- The umbrella issue itself is the ledger row of note until the harness is refreshed; reconcile at
  closeout (the token is shape-checked only — a stale reference is easy to drift, so close the loop).
- Refresh the vendored copy from upstream as soon as the marathon closes, not before it starts —
  mid-marathon harness swaps invalidate gates.

## 5. Collision rule on small codebases: one lane, sequential phases

Foreign repos usually have one kernel area (here: agent-runtime). When member issues share kernel
files, parallel lanes are illegal no matter how attractive the wave chart looks. Run one lane with
sequential phases, ordered by **dependency, not raw score**: pair issues that touch the same
vocabulary into one phase (saves a double round-trip on the same files); put message/UX-surface
work last so it can name what the earlier phases introduced.

## 6. Respect the target repo's push constitution

Foreign repos carry their own push rules (here: CLAUDE.md — no push/merge/release without the
operator's explicit word, PRs target `develop` as the integration branch). The marathon fires in
the clone, one branch per phase, PRs against the repo's stated integration branch — and the
pre-push guard from §1 travels *nowhere*, so the operator's own rules are the only guard. Get the
explicit go for branch pushes as part of the fire confirmation.

## 7. Turn profile

Operator effort level maps through `resolve-profile.sh` (e.g. `glm 5.3 max` →
`COMMANDCODE_REASONING_EFFORT=max`). State the profile in the umbrella body so reviewers know what
ran.

## 8. Field notes from the first run (pivots hit in practice)

1. **Node ≥ 22 killed the classic require hooks.** `Module._resolveFilename` and `Module._load`
   are getter-only and non-configurable; the only surviving seam is `Module.prototype.require`.
   The vendored harness's own SDK-alias patch (`AgentRegistry`'s `_resolveFilename` assignment)
   silently no-ops on Node 22 — upstream bug worth filing. Any tool that must import an
   Electron-adjacent module graph in plain Node should hook `prototype.require` and swap the
   peer requests for a chain-safe permissive stub.
2. **Optional peers break plain-Node imports of tool graphs.** `electron` /
   `@getflywheel/local` are optional peers that a normal checkout never installs, yet some
   modules import them at load time. Registration paths only build definitions, so a stub is
   safe — but it must be committed next to the tool that needs it, not left in `node_modules`.
3. **Generated files must sort deterministically.** `localeCompare` orders differently between
   a bare Node CLI run and jest's ICU setup — the "committed file matches generator" check
   failed only under jest. Use plain lexicographic `sort()` for anything committed.
4. **Watch for elision commas in generated arrays.** `[a, b,]` joining plus a trailing literal
   comma yields `b,,` — a real `undefined` hole in the array, caught by a name-format test.
   Array-format tests (every entry matches a shape) catch this class for free.
5. **Message-level assertions rot on purpose here.** Making a refusal message actionable (the
   point of the GH) breaks tests that matched the old wording; budget for updating those
   assertions in the same phase, and pin the NEW wording in the contract's acceptance criteria
   at authoring time.
6. **Raw-text drift checks are brittle on annotated files.** A build tool that compares whole
   file text fails on manifests carrying hand-written header comments even with zero drift.
   Compare only the fields the tool owns, deep-equal via a stable (key-sorted) stringify.
7. **The Forge pre-push gate reads the operator's whole tree, not the branch.** A docs-only
   foreign-branch push was refused because the operator's own uncommitted state was present;
   `--no-verify` on a docs-only non-default branch is the sanctioned path (the hook's own
   message offers it).
