**NO FIRSTHAND VERIFICATION CITED** — treat conclusions as conditional (codex's answer carries an unsupported [Pass]/verified/confirmed-style claim with no quoted span or file:line citation nearby, despite the consult PREAMBLE asking advisors to cite evidence.)

> **ATTESTATION**
> Model: gpt-5.6-terra
> Provider: openai
> Sandbox: read-only

Reading additional input from stdin...
2026-09-04T06:36:37.023850Z ERROR codex_models_manager::cache: failed to load models cache: missing field `base_instructions` at line 94 column 5
OpenAI Codex v0.144.6
--------
workdir: /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-46123-z8dp_mu5
model: gpt-5.6-terra
provider: openai
approval: never
sandbox: read-only
reasoning effort: high
reasoning summaries: none
session id: 01a06b22-2e5e-7f41-95ea-4764afaec45b
--------
user
You are an INDEPENDENT advisor in a one-shot cross-model consult. Another model is answering the SAME question separately and a coordinator will reconcile both answers, so give your own honest, specific read — do not hedge toward a consensus you cannot see. Read any repo files the question references (cite file:line). Respond with: (1) a short direct ANSWER; (2) graded FINDINGS — [Blocker]/[Should]/[Nit]/[Pass] — where applicable; (3) a one-line RECOMMENDATION. You are ADVISORY ONLY: output your analysis as text; do not rely on writing files (you are running in a throwaway copy).

=== CONSULT QUESTION ===
# Disposition question: PR #427 (GH-414 fail-closed source-comment reference scanner)

You are advising on a blocked PR in HiQS-Labs/XYZ-forge. Advisory only — no edits.

## What the PR built (branch feat/gh414-comment-reference-check, NOT in your worktree — facts inlined)

A new fail-closed scanner in `utils/pdda/pdda.sh` (`check_governance`): extracts path-shaped
references (`foo/bar.md`, optionally `#anchor`) from comment lines of source files under `src/`
(js/ts/py/sh/...), and asserts each target EXISTS — ERROR in full mode if not. Runs against the
source tree and, when `PDDA_COMMENT_REFERENCE_ARTIFACT` is set, the built artifact separately.
The PR also restores two real ADRs (`decisions/2026-06-18-epoch-fencing.md`,
`decisions/2026-07-01-cross-agent-dep-conflict.md`) that `src/events.js` and `src/project.js`
cite but which had been dropped from the shipped tree — that was the original defect (GH-414
finding 1.5), and the scanner catches it. Hosted CI green; reviewer (me) verified the artifact
semantics, the fail-closed polarity, and mutation controls.

## Blocker 1 — design tension (found in review, fix already on the branch)

`src/project.js:334` legitimately cites `.tick/STATE.md` and `.tick/rejected.jsonl` —
runtime-GENERATED, gitignored state. They exist in any working tree that has run the harness,
but NEVER in a pristine checkout. So on any fresh clone (CI, contributor, launch build):
`governance` exits 1 with `comment reference '.tick/STATE.md' has no file at .tick/STATE.md`.
The lane's own tree passed because it had run the harness — the claim was masked by untracked
local files. My fix, now committed on the branch: exempt paths matching
`git -C "$root" check-ignore` (fail-closed preserved in non-repo roots, where check-ignore
errors), plus a two-direction pristine-fixture control in the suite (suite now 9/0, fresh-clone
governance rc 0).

## Blocker 2 — intermittent signal death (NEW, found during the merge train; why the PR is held)

`bash utils/pdda/pdda.sh governance` on a pristine clone dies by signal stochastically:
SIGSEGV 139 / SIGABRT 134, roughly 3-5 times in 20 runs (macOS arm64, /bin/bash 3.2).
Controlled attribution:
- With the check-ignore line removed: crash still occurs (1 in 7) — not my exemption line.
- Direct `git check-ignore` × 50: zero crashes — git is not the crasher.
- Unsandboxed runs: still crash — not the test harness sandbox.
- `bash -x` capture: death occurs mid-`read` while consuming the scanner's process-substitution
  feeds (`done < <(_pdda_comment_scannable_lines "$file")`, and the
  `printf | grep -oE | sed | sort -u` pipeline in `_pdda_comment_extract_refs`) — i.e. the new
  scanner's streaming plumbing (bash 3.2 process-substitution interaction suspected).
Consequence: governance — and therefore validate.sh — would fail stochastically for everyone if
merged. The pre-existing pdda code also uses `done < <(…)` constructs but at much lower
frequency/size; the new pipelines run per-line over every src file.

Suggested fix direction (not yet implemented): temp-file intermediates instead of process
substitutions, or a single awk pass per file; then a documented ~20× zero-signal-exit loop under
/bin/bash 3.2 as the stability control.

## The goal in question (GH-414, verbatim key parts)

"Nothing deterministic checks whether an inline code comment is still true… Extend the
dead-reference check to extract filesystem-path-shaped references from source comments and
assert the target exists. Pure path resolution — no semantics… Run it against both trees…
A source comment citing a non-existent path fails the check… Explicit non-goal: this verifies
that references resolve, not that prose is accurate." Status: OPEN, remediation rank R5 of an
external-review umbrella; the two dropped ADRs were real and are now restored.

## Questions (answer all three, be specific and opinionated)

1. **Disposition of PR #427**: fix-on-branch (which approach for the crash — temp files? single
   awk? something else?), or restructure (e.g. make the scanner Python — utils/py/ is the
   authoritative runtime for Tier-A tooling in this repo), or split (land artifact-check +
   ADR restoration without the fail-closed source scan)? What would YOU do next, concretely?
2. **Was the goal invalid?** The issue's own acceptance says "a comment citing a non-existent
   path FAILS" — but the false-positive class is "path exists in a used tree, is deliberately
   untracked, absent in a fresh clone". Is `git check-ignore` exemption the right category model,
   or is fail-closed-on-source-comments the wrong polarity entirely (should source-scan be
   warn-only and only the ARTIFACT check fail-closed)? Where is the line between "the goal was
   fine, the implementation hit a real category it didn't model" and "the goal was over-broad"?
3. **Amended acceptance criteria** for GH-414: what should the issue's Acceptance section say
   after this lesson (e.g. about fresh-clone determinism, generated-state citations, runtime
   choice)? Keep it in the issue's own voice (deterministic, verifiable, red-control-oriented).

hook: SessionStart
hook: SessionStart Completed
codex
I’m applying the repo’s debugging discipline because this is a stochastic failure attribution question, and I’ll ground the disposition in the current scanner and governance contracts.
exec
/bin/zsh -lc "sed -n '1,240p' '/Users/noelsaw/Documents/GH Repos/XYZ-forge/skills/debug-mantra/SKILL.md' && sed -n '1,180p' ROUTER.md && rg -n -C 3 \"_pdda_comment|check_governance|COMMENT_REFERENCE|check-ignore\" utils/pdda/pdda.sh test src" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-46123-z8dp_mu5
 succeeded in 0ms:
---
name: debug-mantra
description: "Four-mantra debugging discipline — reproduce, trace the fail path, falsify the hypothesis, cross-reference every breadcrumb. Recite the mantra block verbatim at the start of any debugging session, then apply the four steps in order before proposing any fix. Trigger on /debug-mantra and proactively whenever debugging starts — user reports a bug, says something is broken/throwing/failing, asks to debug/diagnose/investigate an issue, pastes a stack trace or error log, or asks an attribution question ('where is this coming from?', 'what posts/triggers/generates this?', 'why is X appearing?') where the answer is an unknown source to find, not just a crash to fix. Also trigger on /debug-mantra plan, and proactively when writing or reviewing the acceptance criteria of a plan, capture doc, or marathon plan — apply the same four mantras through the pivots in 'When the target is a plan, not a bug'. Adapted from: https://github.com/thananon/9arm-skills"
---

# Debug Mantra

Four-step discipline for any debug session. Recite verbatim, then apply in order. When the target is a plan rather than a bug, the same four steps apply read through the pivots in [When the target is a plan, not a bug](#when-the-target-is-a-plan-not-a-bug).

## Recite this — verbatim, as the first thing in your first response

> **Mantra:**
> 1. **First is reproducibility.** Can the issue — or the artifact — be reproduced or observed reliably?
> 2. **Know the fail path.** Debugger first; then source trace + knob enumeration; then in-code instrumentation.
> 3. **Question your hypothesis.** What would disprove it?
> 4. **Every run is a breadcrumb.** Cross-reference all of them.

Then begin work.

---

## 1. Reproduce reliably

Establish ground truth before anything else — a runnable repro for a failure, a direct look at the real artifact for an attribution question.

**Reproduce = observe the primitive ground truth, not your impression of it.** For a crash that's a failing test; for an *attribution* question ("what posts this?", "where does X come from?") it's inspecting the actual artifact — the real message, record, or raw bytes — **before** theorising about its origin. A screenshot, a rendered view, or a remembered detail is an **observation to verify, not an axiom to build on**: name it as assumption-zero and check it first. The cheapest disproof is usually looking straight at the thing — one query against the real object beats a sweep of the code that *might* have produced it. Beware visual grouping and other rendering artifacts: what looks like "one consolidated thing" may be many separate ones (or vice versa) — confirm against the raw object before any hypothesis inherits the shape.

- **Reliable repro** → capture the exact steps, inputs, and environment as a runnable artifact: failing test, curl script, CLI invocation, replay harness.
- **Flaky repro** → the bug is not yet debuggable. Raise the rate first: loop the trigger, parallelise, add stress, narrow timing windows, inject sleeps. 50% flake is debuggable; 1% is not.
- **No repro at all** → stop. Say so explicitly. Ask the user for env access, captured artifacts (HAR, log dump, core), or permission to instrument. Do **not** proceed to hypothesise.

Target: a fast (1–5 s), deterministic pass/fail signal. Pin time, seed the RNG, freeze network, isolate filesystem.

## 2. Know the fail path

Once reproducible, find *where* the code breaks and *what stops it from breaking*. The differential narrows the search. Try in this order — escalate only when the prior tactic fails.

1. **Attach a debugger.** If the env supports it, attach and step to the failure site. One breakpoint beats ten logs. Do this **before** turning any knobs.
2. **Source trace + knob enumeration.** If no debugger (or it can't reach the bug), trace the code path end-to-end and list every knob that can influence the outcome:
   - config flags, env vars, feature toggles
   - branch conditions, input shape
   - timing, concurrency, build options
   Each knob is a candidate axis to flip in the differential. Flip one at a time.
3. **In-code instrumentation.** If outside knobs can't move the failure, go inside: `printf` / log statements at the suspected fail site, dump the relevant internal state. Tag every probe with a unique prefix (e.g. `[DBG-a4f2]`) so cleanup is a single grep. Let the trace show where reality diverges from your model.

## 3. Falsify the hypothesis

When a candidate root cause surfaces, scrutinise it **before** testing it.

- Does it actually explain the symptom end-to-end? Walk it through.
- What is the simplest **proof**? What is the cleanest **disproof**?
- Run the **disproof first**. If the hypothesis survives, it's real. If it dies, you saved yourself from chasing a phantom.
- Generate 3–5 ranked hypotheses, not one. Single-hypothesis thinking anchors on the first plausible idea.

## 4. Every run is a breadcrumb

Maintain a running **ledger** of every experiment in this session. Each entry: what changed, what happened, what it ruled in or out.

- When a new hypothesis surfaces, walk the ledger. Does it hold for **every** prior observation, not just the most recent?
- If any past run contradicts it, the hypothesis is wrong or incomplete — refine or discard.
- When in doubt, design the **single experiment** whose outcome makes it certain. Run that next, instead of churning on adjacent runs.
- Update the ledger after every run. It is your memory across the session.

---

## When the target is a plan, not a bug

Invoked as `/debug-mantra plan`, or proactively when writing or reviewing the acceptance criteria of a plan, capture doc, or marathon plan. The four mantras apply unchanged and the recital stands verbatim — "the issue — or the artifact" includes the plan's own evidence. Each step is read through its pivot:

| Step | Debug reading | Plan pivot |
|---|---|---|
| 1. Reproduce | Runnable repro of the failure. | **Measured ground truth at plan time.** Every count, `file:line`, and live-state claim in the plan is re-run now, not remembered — the "measured, not assumed" evidence table in [#419's "What is actually unenforced today" section](https://github.com/HiQS-Labs/XYZ-forge/issues/419) is the shape. A recalled repo state is hypothesis-zero. |
| 2. Fail path | Trace the code that breaks. | **Trace the real path the plan changes**, before proposing: walk it and enumerate every caller and surface it touches. A criterion about a path nobody traced is a guess wearing a checkbox. |
| 3. Falsify | Disprove the root-cause hypothesis. | **Falsify the acceptance criteria.** Each criterion must name how it fails — a criterion that cannot fail is decorative, and one an empty input satisfies passes vacuously. Specify the red control *and where its evidence will land* (`test/baselines/` negative-control pattern). Rank 3–5 alternatives for the load-bearing design choice and name the strongest counterargument ([#419](https://github.com/HiQS-Labs/XYZ-forge/issues/419)'s "Open question for the reviewers" block is the pattern). |
| 4. Breadcrumbs | Session experiment ledger. | **Recon ledger.** Record the greps, counts, and probes that grounded the plan, citable from the plan or its capture doc. Before finalizing, walk the ledger against what is already shipped — a plan resting on a stale claim (feature already exists, path already changed) inherits the stale claim. |

**The plan-only rule, and why pivot 3 is the strictest:** at plan time falsification is *specified*, not *performed* — strictly weaker evidence than a red control you have watched fire. That gap is why each criterion must name a destination for its red evidence: a planned red control that is not witnessed when implemented is a promise, not a control. Plan reviews have caught criteria "satisfiable by an empty pre-created file" and "satisfiable by a print statement while the defect persisted" — both passed review as written.

Scale rigor as ever: a one-line fix's plan needs a confirming observation, not the full table; a marathon or large-refactor plan needs every pivot. For large refactors this is the SOP "Arc planning" discipline applied debug-mantra-first.

## Operating rules

- Recite the mantra block **once** per debug session, in your first response. Do not re-recite mid-session.
- Recite **verbatim**. Never paraphrase or abridge the recital.
- If the user says "skip the mantra" → skip the recital but still apply the four steps silently.
- Apply the four steps **in order**:
  - Do not propose a fix before #1 is satisfied (reliable repro exists).
  - Do not start testing hypotheses before #2 has narrowed the fail path.
  - Do not commit to a hypothesis before #3 has tried to disprove it.
  - Do not declare a hypothesis correct until #4 confirms it against every prior breadcrumb.
- **Scale rigor to the bug.** The gate is on *evidence*, not ceremony: a trivially obvious defect — a typo, a stack trace pointing straight at the line — needs a confirming **observation**, not necessarily a runnable harness or a written ledger. The burden stays on a direct look, never on assumption.
- If you catch yourself proposing a fix without a reliable repro, stop and return to step 1.
- If you catch yourself building on an unverified observation ("it's obviously X", "that's clearly one Y") — especially one drawn from a screenshot, a rendered view, or memory — stop and inspect the raw artifact first. The impression is hypothesis-zero, not ground truth, and a single direct look at the real object usually settles it faster than any search of the code that might explain it.
- The mantra is a constraint **you** carry through the session — not advice to deliver back to the user.
# ROUTER.md

This file is the first entry point for an AI agent working in this repo: it tells you what to read, what to run, and which files are canonical.

## Role split

- `ROUTER.md` = startup order and canonical entry points
- `GUIDING-PRINCIPLES.md` = the *why*, and the canonical North Star: durable, reversible, DRY — extend what exists rather than forking a parallel system
- `AGENTS.md` = behavioral rules, decision quality, reversibility, blast radius, proof
- `README.md` = human-facing repo/product overview
- `ROADMAP-DASHBOARD.md` = the generated, human-readable view of the roadmap ledger (read this; regenerate with `utils/roadmap-dashboard.sh`)
- `ROADMAP.md` = LEGACY pointer ledger, frozen since the `ROADMAP_SOURCE=releases` flip (GH-169/GH-243) — the RELEASES DB (`releases.db` via `releases.sql`) is the source of truth; write via `releases roadmap add`, never by editing this file
- `CHANGELOG.md` = the end-of-iteration running log (first-class PDDA artifact; governed by `PROJECT/PDDA.md`)
- `RELEASES.md` = forward-looking release-planning ledger (first-class PDDA artifact; governed by `PROJECT/PDDA.md`)
- `HARNESS-MODELS-REGISTRY.md` = evaluated agent harnesses, supported model grades (A/B/C), and CLI flags
- `MACHINE-CONTRACTS.md` = the Jog ↔ Preflight ↔ Marathon machine-contract reference (`marathon-invocation@1`, `marathon-drive/result@1`) and their version/deprecation policy
- `PROJECT/**` docs = canonical execution detail for a specific effort
- `PROJECT/PDDA.md` = document contract and automation rules (incl. the CHANGELOG contract)
- `PROJECT/CONSTITUTION.md` = the policy of record: PDDA's lane and its non-negotiables (deterministic-before-LLM, verified-success-only, reversibility, local-first)
- `PROJECT/DO-NOT-BUILD.md` = the anti-scope list — product directions PDDA must not become (companion to `CONSTITUTION.md`)

## Startup sequence

1. Read `ROUTER.md` to understand the repo's operating order and canonical files. -> expect one clear next file, not a repo-wide scavenger hunt.
2. Read `AGENTS.md` before making recommendations or edits. -> expect explicit assumptions, a reversibility read on consequential changes, and verified claims only.
3. Read `ROADMAP-DASHBOARD.md` (or `python3 utils/py/releases_app.py roadmap list`) to find the active effort or parked intake. -> expect links outward to the canonical `PROJECT/**` docs; the roadmap is a pointer ledger, not a plan body. (`ROADMAP.md` is the frozen legacy file — do not read it for current state or edit it.)
4. Read the linked `PROJECT/**` document that owns the work you are touching. -> expect the near-top `## Status` table to tell you what was just completed and what is next.
5. If the task touches project docs, read `PROJECT/PDDA.md` and follow the PDDA contract. -> expect `PROJECT/2-WORKING` docs to have frontmatter, the exact status table, and QA gates when phased.
6. Before reporting success on code or runtime work, run `./validate.sh`. -> expect the suite to stay green; do not claim completion if it fails or was skipped.
7. Before reporting success on doc-hygiene or roadmap work, run `utils/pdda/pdda.sh run` (or the relevant `utils/pdda/pdda.sh <check>` subcommand). -> expect deterministic findings first, then any LLM review.

## Canonical rules

- Do not put phase checklists, build steps, or deep execution notes in the roadmap ledger.
- Every active doc in `PROJECT/2-WORKING/` must be reflected by a pointer row in the roadmap ledger (the RELEASES DB) that links it. A working doc that should not appear opts out with `roadmap_exempt: true` in its frontmatter. (`utils/pdda/pdda.sh roadmap-coverage` still checks the legacy `ROADMAP.md` text — repointing it to the DB is tracked in #169's blast-radius list.) Governance lives in `PROJECT/PDDA.md` → "ROADMAP.md contract".
- Promoting a capture from `1-INBOX` to `2-WORKING` is a DB-verb procedure (`roadmap repoint` + `roadmap update`), never a `ROADMAP.md` edit — the exact steps and their two known gate traps (`updated:` frontmatter key, bullet-format `raw_text`) live in `SOP.md` → "Step 1b: Promoting a capture from 1-INBOX to 2-WORKING (releases-mode)".
- Every captured GitHub issue doc in `PROJECT/1-INBOX/GH-*.md` must also be parked as a queue row immediately at intake — `python3 utils/py/releases_app.py roadmap add --issue-num N --issue-url U --title T --created YYYY-MM-DD --doc-path P` (or `hq park`, which routes there automatically in this repo) — then promoted or removed later. Governance lives in `PROJECT/PDDA.md` → "GitHub issue intake" + "ROADMAP.md contract".
- Do not create a second competing plan when a canonical `PROJECT/**` doc already exists.
- Issue-first: any change beyond a **2–3 line** fix opens a GitHub issue first, then a pointer doc **named after the issue** (`GH-<number>-VERY-SHORT-DESC.md`, e.g. `GH-1234-SHOWME-COMMAND.md`), and that capture is **parked in the roadmap ledger immediately** (`releases roadmap add`) before execution begins. The issue is the signal stream; the pointer doc is the execution surface of record. Genuinely trivial edits (≤2–3 line fixes, typos, path repoints, doc-only one-liners) are exempt. Governed by `PROJECT/PDDA.md` → "GitHub issue intake".
- Runtime triage labels: since the `XYZ_PYTHON` flip the harness is dual-runtime, so any harness-bug issue gets a `runtime:` label — `runtime:python` (default path), `runtime:bash` (`XYZ_PYTHON=0` opt-out), or `runtime:parity` (the twins diverge). `/file-xyz-bug` harvests and applies it; for in-repo intake (`/triage`, hand-filed `gh issue create`) apply it by hand. Omit rather than guess — a wrong runtime tag misroutes triage.
- **`GH-<n>` numbering spans two repos.** This repo succeeded [`Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm`](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm) and the migration did **not** renumber references, so a `GH-<n>` in a source comment, test name, or CHANGELOG entry may belong to either repo. Upstream ledger entries are preserved verbatim in [`docs/ROADMAP-UPSTREAM-ARCHIVE.md`](docs/ROADMAP-UPSTREAM-ARCHIVE.md), which states its own numbering caveat and is not parsed by anything. Where an upstream number is cited from code that ships here, mirror it as a closed `[upstream archive]` issue so the citation resolves locally (#407, #408 are the pattern) rather than editing the comment. Raised externally as GH-406 §3.1.
- Do not override deterministic PDDA findings with prose.
- Do not report a win you did not verify with the relevant script or test.
- Update `CHANGELOG.md` at the end of each iteration; its governance lives in `PROJECT/PDDA.md` — do not re-specify CHANGELOG rules in `AGENTS.md` or elsewhere.

## Command rails

For repo correctness:

```bash
bash githooks/install.sh        # ONCE PER CLONE — wires the pre-push gate (GH-544)
bash githooks/install.sh --check # is this clone gated? exit 1 if not
./validate.sh              # the gate — PARALLEL by default (GH-544), auto-sized to the host (GH-35)
./validate.sh --print-mode # which mode would this host pick, and why — runs nothing
./validate.sh --sequential # force the sequential run (~16 min)
./validate.sh --tier 2 --subsystem hq   # GH-35: one subsystem's focused suites (pre-push speed, NOT evidence)
./validate.sh --auto       # GH-35: classify the git diff, run the minimal safe tier (fails closed to 3)
./validate.sh --throttle   # GH-35: 2 workers under nice — quiet-machine mode (--burst restores full width)
bash ci-local.sh           # the QUALIFYING run — sequential + writes the gate record (GH-509/GH-536)
```

**Both gate entry points refuse to run from a linked git worktree (GH-45)** — a worktree shares
the parent clone's `.git`, and an observed suite escape corrupted the parent (core.bare, origin,
remote refs, development). Run the gate from a normal clone; `XYZ_ALLOW_WORKTREE_GATE=1` is the
announced override for disposable runs.

**Hosted CI fires on nothing while this repo is private (GH-544).** The gate runs locally at the push
boundary instead, so `githooks/install.sh` is part of setting up a clone — the hook lives in
`.git/hooks/`, which does not travel with a clone, and an uninstalled one pushes unverified. One
install covers every branch and every linked worktree of that clone (GH-549). Bypass with
`git push --no-verify` or `XYZ_SKIP_PREPUSH=1`; both announce themselves. Re-arm CI when the repo
goes public (free there).

**Parallel became the default on 2026-08-14 (GH-544)** because the local gate is the only gate during
the private phase, and a 16-minute gate does not get run — it gets skipped, which is worse than a
3-minute one. **GH-35 (2026-08-18) rebalanced the width to `cores/2` (floor 2, cap 4) and put every
worker under `nice -n 10`** — the original `cores − 2` (up to 8) saturated developer machines badly
enough to wedge the editor; `--burst` buys the old full-core width back for unattended runs, and
`--throttle`/`--quiet-cpu` pins 2 workers. Ambient levers: `XYZ_VALIDATE_THROTTLE=1`,
`XYZ_VALIDATE_MAX_JOBS=N`, `XYZ_VALIDATE_PARALLEL` (flags > MAX_JOBS > THROTTLE > PARALLEL > host
detection; malformed values exit 2 naming the variable). Below 4 cores, or where `xargs -P` is
unsupported, the run **falls back to sequential and says so** — every run prints the mode it chose
and the reason, so a fallback is never silent.

**GH-35 also added TIERED SELECTION on top, as a separate axis from width.** `utils/ci-route.sh`
owns one fail-closed subsystem registry (hq, releases, telemetry, ate, swe-diagram, pdda,
agent-chorus); a push the classifier rates `tier=2` runs only those focused suites at the boundary,
`--tier 1` runs the docs gate, and everything else — unknown paths, test edits, kernel surfaces —
runs the full suite. `--auto` classifies a local diff the same way. Tiers 1 and 2 are pre-push
speed and are labelled NOT promotion evidence; only `ci-local.sh`'s sequential full run qualifies
(GH-509).

**What still qualifies a claim is unchanged.** `./validate.sh` in either mode is a self-check;
`ci-local.sh` is the run that writes the evidence record, it does **not** call `validate.sh`, and it
stays sequential. The macOS promotion boundary in `ci.yml` pins `--sequential` explicitly for the same
reason. GH-528 Phase 2 (multi-width stress evidence) is still **owed** — the flip was an operator
decision taken with that evidence outstanding, mitigated by the announced fallback rather than
discharged. See `PROJECT/2-WORKING/GH-528-TEST-SUITE-RECALIBRATION.md`, #509 and #544.

For document hygiene:

```bash
utils/pdda/pdda.sh run
```

For targeted PDDA debugging (subcommands of the single dispatcher):

```bash
utils/pdda/pdda.sh frontmatter
utils/pdda/pdda.sh status-table
utils/pdda/pdda.sh hardcoded-paths
utils/pdda/pdda.sh roadmap
utils/pdda/pdda.sh roadmap-coverage
utils/pdda/pdda.sh changelog
utils/pdda/pdda.sh stale
utils/pdda/pdda.sh issue-doc-sync   # warn-only: flags 2-WORKING/GH-*.md docs drifted from their GitHub issue state
utils/pdda/pdda.sh releases         # validate RELEASES.md, the OPTIONAL release-planning ledger (warn-only; skips a missing file)
utils/pdda/pdda.sh releases-current # read-only roll-up: RELEASES.md entries whose Status isn't "Shipped"
utils/pdda/pdda.sh quad-concepts    # opt-in: requires a "## Quad Concepts" section of 1-4 bullets (lever: .pdda-quad / PDDA_QUAD)
utils/pdda/pdda.sh glance           # read-only roll-up: title + Quad Concepts for each PROJECT/2-WORKING doc
utils/pdda/pdda.sh gh-refresh       # refresh the cached GitHub issue-state file issue-doc-sync reads offline (needs gh)
utils/pdda/pdda.sh catchup          # LLM repo triage + ROUTER.md recommendations (delegates to pdda-catchup.sh)
utils/pdda/pdda.sh doc-ready        # LLM readiness review — set PDDA_LLM_BIN (codex/claude/agy) for recommendations, else it self-skips
```

## The RELEASES DB — two subsystems, one ledger (GH-32 / GH-69)

`releases.db` + `releases.sql` hold TWO mirrored subsystems, both operated through ONE CLI,
`utils/py/releases_app.py` (alias: the `/releases` skill). Read
[RELEASES-DB-FAQS.md](RELEASES-DB-FAQS.md) before merging either file — the SQLite binary is
derived; the SQL dump is what git actually merges, and a conflicted merge has a one-command
resolver (`utils/releases-merge-resolve.sh`).

```bash
python3 utils/py/releases_app.py check          # trio consistency, receipt chain, crash recovery
python3 utils/py/releases_app.py next           # the next unshipped release, by target date
python3 utils/py/releases_app.py add|ship ...   # RELEASE writes — never hand-edit releases.sql
python3 utils/py/releases_app.py roadmap add ... # GH-238: park one issue as a roadmap row (the intake write path)
                                                #   GH-249: put `rated N/N/N/N [ovr N]` in --raw-text to score it
python3 utils/py/releases_app.py roadmap rate ...# GH-253: score a row that is ALREADY parked (--force to re-score)
python3 utils/py/releases_app.py roadmap list   # read the roadmap rows (--json for machine consumers)
python3 utils/py/releases_app.py roadmap sync   # LEGACY-mode only (mirrors ROADMAP.md); a guarded no-op in this repo
```

**Subsystem 1 — releases** (GH-32, Phase 0 side-by-side): the release ledger. App-managed writes
only; `RELEASES.md` is still the human file during the shadow phase.
**Subsystem 2 — the roadmap ledger** (GH-69 shadow → GH-238/GH-243 canonical): since the
`ROADMAP_SOURCE=releases` flip, `roadmap_items` IS the ledger — write rows with
`releases roadmap add` (or `hq park`), read with `roadmap list` / `ROADMAP-DASHBOARD.md`, and
never edit `ROADMAP.md` (frozen legacy). `roadmap sync` exists for legacy-mode repos only and
no-ops here by design (it would delete `add`-parked rows). Pinned by `test/gh69-roadmap-shadow.sh`
and `test/gh238-hq-releases-mode.sh`.

## Routing hints

- If the task is about current priorities or active work, start in `ROADMAP-DASHBOARD.md` (or `releases roadmap list`), then follow the linked `PROJECT/**` doc.
- If the task changes the roadmap ledger, write through the CLI (`releases roadmap add` for intake; `hq park` routes there automatically) and finish by regenerating `ROADMAP-DASHBOARD.md` (`utils/roadmap-dashboard.sh`) — the push gate refuses a ledger write with a stale dashboard (GH-243).
- If the task touches `releases.db`, `releases.sql`, or a merge conflict on either, start in [RELEASES-DB-FAQS.md](RELEASES-DB-FAQS.md); writes go through the CLI, never a hand-edit.
- If the task is about fresh GitHub intake or duplicate-prevention, start in the dashboard's queue section (or `releases roadmap list`), then follow the linked `PROJECT/1-INBOX/GH-*.md` capture doc.
- If the task is about document quality, active-doc lifecycle, roadmap sprawl, or automation policy, start in `PROJECT/PDDA.md`.
- If the task is about the CHANGELOG, provenance, or end-of-iteration logging, the governance is in `PROJECT/PDDA.md` (the "CHANGELOG.md — end-of-iteration record" contract).
- If the task is about release planning, ledger health, cleanup, authoring, or publishing, invoke `/releases`. It reads and synthesizes `RELEASES.md` first, then routes explicit requests into confirmation-gated cleanup, planning, or publication; governance is in `PROJECT/PDDA.md` (the "RELEASES.md — release ledger" contract). It conditionally points strategic drift to `/radar` and a frozen path-to-ship to `/finish-line` without duplicating either workflow.
- If the task is about the `tick` runtime, event projection, or multi-agent coordination kernel, start in `README.md`, then `bin/`, `src/`, `test/`, and the active project doc.
- If the task is about the **Aider ↔ OpenRouter** turn-taker lane (`relay-automation/aider-turn.sh` — an OpenAI-standard build lane discrete from Codex; `AIDER_MODEL`/`OPENROUTER_API_KEY`, `--builder aider`), start in `PROJECT/3-COMPLETED/GH-77-AIDER-OPENROUTER-LANE.md`. The shim owns the tick token ops (Aider can't run shell mid-turn), asserts token ownership before launching Aider, and runs Aider `--no-auto-commits` (the harness commits).
- If the task is about running, driving, or reviewing via the relay (`relay-automation/` — `relay-drive.sh`, `poll.sh`, the turn shims, `marathon*.sh`), **invoke the `relay-xyz` skill first — do not improvise the handoff or hand-roll a harness from `ls relay-automation/`.** The skill owns the locator, sandbox rules, exit codes, and the safety boundary; a `PreToolUse` guard (`relay-automation/hooks/relay-xyz-guard.sh`) blocks driving a harness driver before the skill is loaded. For the two live-Claude-windows, same-machine duel recipe (Reporter↔Maintainer with a human go-gate), the copy-paste form is [relay-automation/DUELING-CLAUDES.md](relay-automation/DUELING-CLAUDES.md).
- If the task is about the ATE (Automated Testing Environment) skill — unattended variation-test fuzzing whose implementation lives under `utils/ate/` — start at its canonical interface in `skills/ate/SKILL.md`.
- If the task is about relay session telemetry, the `focus5float` health feed, or extraction scripts under `utils/telemetry/`, start in `PROJECT/1-INBOX/GH-24-RELAY-TELEMETRY-EXTRACTOR.md`.
- If the task is about live per-session completion telemetry — the `XYZ.json` log every relay/marathon/swarm session appends to at the harness repo root (schema: `harness`/`sessionId`/`health`/`title`/`description`/`updatedAt`), the shared writer `utils/telemetry/append-xyz-completion.sh`, or the shared health mapping `utils/telemetry/health-lib.sh` — start in `PROJECT/1-INBOX/GH-75-XYZ-JSON-COMPLETION-TELEMETRY.md`. `XYZ.json` is local + gitignored (machine-specific).
- If the task is about cross-repo HQ tooling (`utils/hq/` — `hq.sh` single-repo actions, `rollup.sh` the Obsidian daily ROADMAP rollup, `marathon-scan.sh` the cross-repo marathon-preflight aggregator, `hq-lib.sh` the shared repo registry), start in `PROJECT/3-COMPLETED/GH-27-ROADMAP-DASHBOARD.md` and `PROJECT/3-COMPLETED/GH-158-HQ-MARATHON-SCAN.md`. The two rollups are deliberately separate today (`rollup.sh` → Obsidian, generic; `marathon-scan.sh` → hub repo, preflight-aware) and are not yet bridged — tracked in `PROJECT/1-INBOX/GH-192-HQ-MARATHON-OBSIDIAN-ROLLUP.md`.
- If the task is about a proposed roadmap-steward agent, start here, then read `PROJECT/PDDA.md` and its `Proposed roadmap steward extension` section.
- If the task is about finding or picking a skill for a job, see `ARCHITECTURE.md` → "Skills Index" for a one-line inventory of every skill in `skills/`.
- Issue-first SOP: any change beyond a 2–3 line fix (and every project plan) opens a GitHub issue *first*, then gets a pointer doc named after the issue at `PROJECT/1-INBOX/GH-<number>-VERY-SHORT-DESC.md` — e.g. `GH-1234-SHOWME-COMMAND.md` — and that capture is parked in the roadmap ledger queue immediately via `releases roadmap add` (format + lifecycle owned by `PROJECT/PDDA.md` → "GitHub issue intake"), following the normal `1-INBOX` → `2-WORKING` flow. Genuinely trivial edits (≤2–3 line fixes, typos, path repoints, doc-only one-liners) are exempt and commit directly.
utils/pdda/pdda.sh-982-        found=""
utils/pdda/pdda.sh-983-        cache_hit=0
utils/pdda/pdda.sh-984-        if [ -n "$cache_dir" ] && [ -d "$cache_dir" ]; then
utils/pdda/pdda.sh:985:          # GH-48 (round 4): check_governance already ran ONE whole-tree `find` for every unique bare
utils/pdda/pdda.sh-986-          # name across the whole run and populated this cache — a pure read here, no traversal. Each
utils/pdda/pdda.sh-987-          # entry is TWO files (the verbatim looked-up name + its resolved path/"-" sentinel), never one
utils/pdda/pdda.sh-988-          # file with an internal delimiter — the cache key is a 32-bit checksum, which *can* collide
--
utils/pdda/pdda.sh-1005-          fi
utils/pdda/pdda.sh-1006-        fi
utils/pdda/pdda.sh-1007-        if [ "$cache_hit" != "1" ]; then
utils/pdda/pdda.sh:1008:          # Either no usable batch cache (mktemp/find failed building it, check_governance didn't build
utils/pdda/pdda.sh-1009-          # one, or this specific key collided with a different name) — fall back to a single-name
utils/pdda/pdda.sh-1010-          # `find` so `$path` still resolves correctly. Slower than the batch cache for this one name,
utils/pdda/pdda.sh-1011-          # but correctness-preserving; the batch cache is what the speed fix actually relies on for the
utils/pdda/pdda.sh-1012-          # common (no collision, cache built fine) case. `$path` is glob-escaped (GH-34) so it still
utils/pdda/pdda.sh-1013-          # can't be misread as a pattern, and no `-type` filter is applied (first traversal match wins,
utils/pdda/pdda.sh:1014:          # any type — see check_governance's batch build for the full rationale, identical here).
utils/pdda/pdda.sh-1015-          esc="$(_pdda_gov_glob_escape "$path")"
utils/pdda/pdda.sh-1016-          found=""
utils/pdda/pdda.sh-1017-          while IFS= read -r -d '' p; do
--
utils/pdda/pdda.sh-1027-
utils/pdda/pdda.sh-1028-# GH-365 step 4: extract every reference from ONE doc as "<line>\t<ref>" pairs. This is the
utils/pdda/pdda.sh-1029-# per-doc replacement for the per-line `_pdda_gov_extract_refs` fan-out, which spawned 4
utils/pdda/pdda.sh:1030:# printf|grep|sed pipelines per line and ran twice per doc (once per check_governance pass) —
utils/pdda/pdda.sh-1031-# ~78% of an 87s `pdda.sh run` on macOS. Preferred engine is the in-process scanner
utils/pdda/pdda.sh-1032-# utils/py/pdda_gov_scan.py (ONE python process per doc, byte-exact with the legacy output —
utils/pdda/pdda.sh-1033-# see that file's CONTRACT header). It lives OUTSIDE utils/pdda/ because this tree is
--
utils/pdda/pdda.sh-1053-  done < <(_pdda_gov_scannable_lines "$abs_file")
utils/pdda/pdda.sh-1054-}
utils/pdda/pdda.sh-1055-
utils/pdda/pdda.sh:1056:# The per-doc cache check_governance's TWO passes both read (GH-365 step 4: "retaining
utils/pdda/pdda.sh-1057-# extracted references across its validation passes"). Same two-file shape as the bare-name
utils/pdda/pdda.sh-1058-# find-cache below: the key is a 32-bit cksum and CAN collide, so each entry stores the doc
utils/pdda/pdda.sh-1059-# path it was built from and a colliding doc is served UNCACHED (never overwritten) — the
--
utils/pdda/pdda.sh-1081-  _pdda_gov_extract_doc_refs "$abs_file"
utils/pdda/pdda.sh-1082-}
utils/pdda/pdda.sh-1083-
utils/pdda/pdda.sh:1084:check_governance() {
utils/pdda/pdda.sh-1085-  pdda_reset_counts
utils/pdda/pdda.sh-1086-  local CHECK_NAME="pdda-check-governance" rc=0
utils/pdda/pdda.sh-1087-  local docs="${PDDA_GOVERNANCE_DOCS:-$PDDA_GOVERNANCE_DOCS_DEFAULT}"
--
utils/pdda/pdda.sh-1109-  # rather than blocking a build even in full mode — same calibration as check_stale/check_changelog.
utils/pdda/pdda.sh-1110-  # GH-48 (round 4): batch-resolve every unique bare (no-directory-component) reference across ALL
utils/pdda/pdda.sh-1111-  # scanned docs in exactly ONE whole-tree `find` call, before doing anything else — the DoD is one
utils/pdda/pdda.sh:1112:  # traversal per check_governance run, not one per unique name (a per-name `find`, even memoized,
utils/pdda/pdda.sh-1113-  # still multiplies with the number of DISTINCT dead names on a doc set with many different missing
utils/pdda/pdda.sh-1114-  # bare mentions). Pass 1 below just extracts and collects candidate names; pass 2, further down,
utils/pdda/pdda.sh-1115-  # is the existing per-ref loop, unchanged except it now reads a fully-populated cache instead of
--
utils/pdda/pdda.sh-1319-pdda-stale-working-docs:check_stale
utils/pdda/pdda.sh-1320-pdda-check-issue-doc-sync:check_issue_doc_sync
utils/pdda/pdda.sh-1321-pdda-check-releases:check_releases
utils/pdda/pdda.sh:1322:pdda-check-governance:check_governance
utils/pdda/pdda.sh-1323-"
utils/pdda/pdda.sh-1324-
utils/pdda/pdda.sh-1325-cmd_run() {
--
utils/pdda/pdda.sh-1516-  issue-doc-sync)   check_issue_doc_sync; exit "$?" ;;
utils/pdda/pdda.sh-1517-  releases)         check_releases; exit "$?" ;;
utils/pdda/pdda.sh-1518-  releases-current) cmd_releases_current; exit "$?" ;;
utils/pdda/pdda.sh:1519:  governance)       check_governance; exit "$?" ;;
utils/pdda/pdda.sh-1520-  gh-refresh)       exec "$HERE/pdda-gh-refresh.sh" "$@" ;;
utils/pdda/pdda.sh-1521-  doc-ready)        exec "$HERE/pdda-doc-ready.sh" "$@" ;;
utils/pdda/pdda.sh-1522-  catchup)          exec "$HERE/pdda-catchup.sh" "$@" ;;
--
test/gh430-state-dir-tracked-default.sh-49-
test/gh430-state-dir-tracked-default.sh-50-if [ -n "$SD" ]; then
test/gh430-state-dir-tracked-default.sh-51-  REL="${SD#"$REPO"/}"
test/gh430-state-dir-tracked-default.sh:52:  if (cd "$REPO" && git check-ignore -q "$REL"); then
test/gh430-state-dir-tracked-default.sh-53-    fail "default STATE_DIR path is gitignored (zero containment protection, GH-396): $REL"
test/gh430-state-dir-tracked-default.sh-54-  else
test/gh430-state-dir-tracked-default.sh-55-    pass "default STATE_DIR path is NOT gitignored -> tracked-eligible: $REL"
--
test/gh314-transcript-writeset.sh-149-: >"$DISPATCH_LOG"
test/gh314-transcript-writeset.sh-150-rc="$(run_drive "$HEALTHY" "$WORK/healthy.out")"
test/gh314-transcript-writeset.sh-151-
test/gh314-transcript-writeset.sh:152:/usr/bin/grep -qi "cannot track\|check-ignore\|ignored by" "$WORK/healthy.out" \
test/gh314-transcript-writeset.sh-153-  && fail "GH-314: the healthy target was refused by the write-set check — output: $(cat "$WORK/healthy.out")" \
test/gh314-transcript-writeset.sh-154-  || pass "CONTROL: a healthy target is not refused by the transcript check"
test/gh314-transcript-writeset.sh-155-
--
test/xyz-vendor.sh-132-# the fix. An append-only ensure_gitignore sails straight past a blocking rule.
test/xyz-vendor.sh-133-BR="$(mkignore_repo '/relay-system')"
test/xyz-vendor.sh-134-( cd "$BR" && printf 'x\n' > f && git add -A >/dev/null 2>&1 && git -c user.email=t@t -c user.name=t commit -qm s >/dev/null 2>&1 )
test/xyz-vendor.sh:135:git -C "$BR" check-ignore -q relay-system \
test/xyz-vendor.sh-136-  && pass "  control: the fixture repo really does ignore relay-system" \
test/xyz-vendor.sh-137-  || fail "  control: fixture is not actually blocking — the refusal assertions prove nothing"
test/xyz-vendor.sh-138-
--
test/marathon-root-audit.sh-439-ignore_violations=0
test/marathon-root-audit.sh-440-for probe in marathon-system/audit-probe/RELAY.md marathon-system/audit-probe/ESCALATION.md \
test/marathon-root-audit.sh-441-             phases/audit-probe/RELAY.md phases/audit-probe/ESCALATION.md; do
test/marathon-root-audit.sh:442:  if git -C "$audit_root" check-ignore -q "$probe" 2>/dev/null; then
test/marathon-root-audit.sh-443-    echo "FAIL: .gitignore covers $probe, but the driver stages it with \`git add --\` + check=True — a new same-repo phase would exit 1 while recording itself" >&2
test/marathon-root-audit.sh-444-    ignore_violations=$((ignore_violations + 1))
test/marathon-root-audit.sh-445-  fi
--
test/gh197-vendor-tier-split.sh-210-grep -Fqx '!releases.db' "$EX_REPO/.gitignore" \
test/gh197-vendor-tier-split.sh-211-  && pass "Gitignore carve-out: !releases.db added to newly-created .gitignore" \
test/gh197-vendor-tier-split.sh-212-  || fail "Gitignore carve-out: !releases.db missing from newly-created .gitignore"
test/gh197-vendor-tier-split.sh:213:! git -C "$EX_REPO" check-ignore -q releases.db \
test/gh197-vendor-tier-split.sh-214-  && pass "Gitignore carve-out: releases.db is now trackable despite info/exclude rule" \
test/gh197-vendor-tier-split.sh-215-  || fail "Gitignore carve-out: releases.db remains ignored"
test/gh197-vendor-tier-split.sh-216-
--
test/gh514-write-set-trackable.sh-187-rc3="$(run_drive "$EXCL" "$WORK/excl.out")"
test/gh514-write-set-trackable.sh-188-d3="$(/usr/bin/grep -c DISPATCHED "$DISPATCH_LOG" 2>/dev/null | head -1)"; d3="${d3:-0}"
test/gh514-write-set-trackable.sh-189-if [ "$d3" -eq 0 ] && /usr/bin/grep -q "BLOCKED before dispatch" "$WORK/excl.out"; then
test/gh514-write-set-trackable.sh:190:  pass "an exclude-file rule is caught too (git check-ignore is the authority, not a .gitignore parser)"
test/gh514-write-set-trackable.sh-191-else
test/gh514-write-set-trackable.sh-192-  fail "GH-514: a .git/info/exclude rule was missed — the check is reading .gitignore itself instead of asking git. dispatches=$d3"
test/gh514-write-set-trackable.sh-193-fi
--
test/gh514-write-set-trackable.sh-199-# ---------------------------------------------------------------------------
test/gh514-write-set-trackable.sh-200-# Case 4 — a NEGATION rule re-includes the path, so the guard must not block it
test/gh514-write-set-trackable.sh-201-# ---------------------------------------------------------------------------
test/gh514-write-set-trackable.sh:202:# `git check-ignore -v` exits 0 whenever ANY pattern matches — including a negation that
test/gh514-write-set-trackable.sh-203-# re-includes the path. The exit status therefore does NOT mean "ignored", which is what this
test/gh514-write-set-trackable.sh-204-# function's docstring originally claimed. Reading it that way blocks a marathon before dispatch
test/gh514-write-set-trackable.sh-205-# over a path git will happily track, and the operator is told to fix a rule that is already
test/gh514-write-set-trackable.sh-206-# correct. Reproduced directly:
test/gh514-write-set-trackable.sh-207-#
test/gh514-write-set-trackable.sh:208:#     .gitignore:  *.log        -> check-ignore rc=0, `git add` REFUSES  (genuinely ignored)
test/gh514-write-set-trackable.sh:209:#                  !logs/keep.log -> check-ignore rc=0, `git add` ACCEPTS  (re-included)
test/gh514-write-set-trackable.sh:210:#                  (no rule)    -> check-ignore rc=1
test/gh514-write-set-trackable.sh-211-#
test/gh514-write-set-trackable.sh-212-# so rc=0 alone cannot distinguish the middle row from the first.
test/gh514-write-set-trackable.sh-213-echo "-- case 4: a negation rule re-includes the path — the guard must NOT block"
--
test/gh514-write-set-trackable.sh-218-if /usr/bin/grep -q "BLOCKED before dispatch" "$WORK/neg.out"; then
test/gh514-write-set-trackable.sh-219-  fail "GH-514 false positive: a path re-included by a negation rule was blocked; git can track it, so the run was refused over a rule that is already correct"
test/gh514-write-set-trackable.sh-220-else
test/gh514-write-set-trackable.sh:221:  pass "a path re-included by a negation rule is NOT blocked (check-ignore exit 0 means a pattern matched, not that the path is ignored)"
test/gh514-write-set-trackable.sh-222-fi
test/gh514-write-set-trackable.sh-223-# The guard must still be live in this fixture — a change that simply stopped blocking everything
test/gh514-write-set-trackable.sh-224-# would also pass the assertion above. Prove the genuinely-ignored case still refuses.
--
test/gh57-live-merge-resolve.sh-214-echo "-- 6: releases.db.bak is ignored, not merely unmentioned"
test/gh57-live-merge-resolve.sh-215-ok "the rebuild really produced a .bak to worry about" "[ -f '$R3/releases.db.bak' ]"
test/gh57-live-merge-resolve.sh-216-ok "this repo's .gitignore covers releases.db.bak" \
test/gh57-live-merge-resolve.sh:217:   "git -C '$ROOT_DIR' check-ignore -q releases.db.bak"
test/gh57-live-merge-resolve.sh-218-
test/gh57-live-merge-resolve.sh-219-# ── 7. EDGE CASE: an explicitly empty --root must be refused, not silently retargeted ──────────
test/gh57-live-merge-resolve.sh-220-# This is here because it actually happened. While writing this suite, `conflicted()` aborted on a
--
test/baselines/GH-3-state-dir-negative-control.md-31-```
test/baselines/GH-3-state-dir-negative-control.md-32-
test/baselines/GH-3-state-dir-negative-control.md-33-The two FAIL assertions are the point: they pin exactly GH-3's defect (default lands outside the
test/baselines/GH-3-state-dir-negative-control.md:34:repo, under a tmp root that macOS purges within ~3 days). A stray `git check-ignore` invocation
test/baselines/GH-3-state-dir-negative-control.md-35-against a path outside the repo also emits a harmless `fatal:` line to stderr in this mutated
test/baselines/GH-3-state-dir-negative-control.md-36-state — not a test failure, just `git`'s own diagnostic for an out-of-repo path.
test/baselines/GH-3-state-dir-negative-control.md-37-
--
test/baselines/GH-514-negative-control.md-80-  PASS: a trackable target still dispatches its builder turn (2)
test/baselines/GH-514-negative-control.md-81-  PASS: the healthy target is not reported as blocked
test/baselines/GH-514-negative-control.md-82--- case 3: a rule in .git/info/exclude is honoured too
test/baselines/GH-514-negative-control.md:83:  PASS: an exclude-file rule is caught too (git check-ignore is the authority, not a .gitignore parser)
test/baselines/GH-514-negative-control.md-84-  PASS: and it names the exclude file as the matching source
test/baselines/GH-514-negative-control.md-85-
test/baselines/GH-514-negative-control.md-86-  gh514-write-set-trackable: 12 passed, 0 failed
--
test/baselines/GH-514-negative-control.md-88-
test/baselines/GH-514-negative-control.md-89-## Case 4 — negation false positive (added with the gitignore-negation fix)
test/baselines/GH-514-negative-control.md-90-
test/baselines/GH-514-negative-control.md:91:`git check-ignore -v` exits **0 whenever any pattern matched**, including a negation that
test/baselines/GH-514-negative-control.md-92-re-includes the path. The original guard read exit 0 as "ignored", so a path git will happily track
test/baselines/GH-514-negative-control.md-93-blocked the marathon before dispatch and sent the operator to fix a rule that was already correct.
test/baselines/GH-514-negative-control.md-94-
test/baselines/GH-514-negative-control.md-95-Reproduced directly against `git add`, which is the authority the guard is trying to predict:
test/baselines/GH-514-negative-control.md-96-
test/baselines/GH-514-negative-control.md:97:| `.gitignore` | `check-ignore -v` | `git add` |
test/baselines/GH-514-negative-control.md-98-|---|---|---|
test/baselines/GH-514-negative-control.md-99-| `*.log` | rc=0, prints the rule | **refuses** — genuinely ignored |
test/baselines/GH-514-negative-control.md-100-| `!logs/keep.log` | rc=0, prints the `!` rule | **accepts** — re-included |
--
test/gh365-pdda-gov-scan.sh-1-#!/usr/bin/env bash
test/gh365-pdda-gov-scan.sh-2-# gh365-pdda-gov-scan.sh — GH-365 step 4: the per-doc governance reference scanner.
test/gh365-pdda-gov-scan.sh-3-#
test/gh365-pdda-gov-scan.sh:4:# The hot path this closes: check_governance extracted references one LINE at a time (four
test/gh365-pdda-gov-scan.sh-5-# printf|grep|sed pipelines per line, every doc scanned twice — ~78% of an 87s `pdda.sh run` on
test/gh365-pdda-gov-scan.sh:6:# macOS). utils/py/pdda_gov_scan.py does ONE in-process scan per doc; check_governance caches the
test/gh365-pdda-gov-scan.sh-7-# "<lineno>\t<ref>" list per doc and both passes read the cache, with the legacy per-line path
test/gh365-pdda-gov-scan.sh-8-# kept as a fail-safe fallback.
test/gh365-pdda-gov-scan.sh-9-#
--
test/gh365-pdda-gov-scan.sh-15-#      command-position at line start and after a backtick, each interpreter wrapper, and the
test/gh365-pdda-gov-scan.sh-16-#      negatives: exempt-fence mention, blockquote mention, GH-*.md names, deploy.sh.bak,
test/gh365-pdda-gov-scan.sh-17-#      bash -c). Both paths must agree AND the scanner must get every shape right.
test/gh365-pdda-gov-scan.sh:18:#   C. RED control — a fixture doc with a genuinely dead .md reference makes check_governance
test/gh365-pdda-gov-scan.sh-19-#      emit the dead-reference warn on BOTH the scanner path and the forced-legacy path
test/gh365-pdda-gov-scan.sh-20-#      (PDDA_GOV_SCAN pointed at a nonexistent file), with identical findings text.
test/gh365-pdda-gov-scan.sh-21-#   D. PDDA_TIMINGS smoke — PDDA_TIMINGS=1 prints at least one "PDDA_TIMING <check> <ms>" line
--
test/gh365-pdda-gov-scan.sh-43-[ "$(grep -c '^_pdda_gov_[a-z_]*() {' "$LEGACY")" -eq 2 ] \
test/gh365-pdda-gov-scan.sh-44-  || fail "A0: expected exactly 2 legacy _pdda_gov_* functions between the markers, got $(grep -c '^_pdda_gov_[a-z_]*() {' "$LEGACY")"
test/gh365-pdda-gov-scan.sh-45-
test/gh365-pdda-gov-scan.sh:46:# The legacy driver — EXACTLY check_governance's pre-GH-365 nested loops (scannable lines, then
test/gh365-pdda-gov-scan.sh-47-# per-line extraction), emitting the same "<lineno>\t<ref>" stream the scanner produces.
test/gh365-pdda-gov-scan.sh-48-cat > "$WORK/legacy-driver.sh" <<'DRV'
test/gh365-pdda-gov-scan.sh-49-run_legacy() {
--
test/gh365-pdda-gov-scan.sh-159-printf '# fixture index\n\nRead [guide](guide.md) and the missing [dead](dead-walkthrough.md).\n' > "$F/ROUTER.md"
test/gh365-pdda-gov-scan.sh-160-printf '# guide\n\nBack to [router](ROUTER.md).\n' > "$F/guide.md"
test/gh365-pdda-gov-scan.sh-161-
test/gh365-pdda-gov-scan.sh:162:run_gov() {  # <scanner-path> — check_governance against the fixture root
test/gh365-pdda-gov-scan.sh-163-  PDDA_REPO_ROOT="$F" PDDA_GOVERNANCE_DOCS="ROUTER.md" PDDA_GOVERNANCE_INDEX="ROUTER.md" \
test/gh365-pdda-gov-scan.sh-164-    PDDA_ACTIVITY_LOG=/dev/null PDDA_GOV_SCAN="$1" bash "$PDDA" governance
test/gh365-pdda-gov-scan.sh-165-}

codex
> **Mantra:**
> 1. **First is reproducibility.** Can the issue — or the artifact — be reproduced or observed reliably?
> 2. **Know the fail path.** Debugger first; then source trace + knob enumeration; then in-code instrumentation.
> 3. **Question your hypothesis.** What would disprove it?
> 4. **Every run is a breadcrumb.** Cross-reference all of them.
mcp: codebase-memory-mcp/list_projects started
mcp: codebase-memory-mcp/list_projects (completed)
mcp: codebase-memory-mcp/index_repository started
mcp: codebase-memory-mcp/index_repository (completed)
mcp: codebase-memory-mcp/search_graph started
mcp: codebase-memory-mcp/search_graph (failed)
user cancelled MCP tool call
mcp: codebase-memory-mcp/search_graph started
mcp: codebase-memory-mcp/search_graph (failed)
user cancelled MCP tool call
mcp: codebase-memory-mcp/check_index_coverage started
mcp: codebase-memory-mcp/check_index_coverage (failed)
user cancelled MCP tool call
mcp: codebase-memory-mcp/search_graph started
mcp: codebase-memory-mcp/search_graph (failed)
user cancelled MCP tool call
exec
/bin/zsh -lc "git status --short && git branch --show-current && git log -1 --oneline && nl -ba utils/pdda/pdda.sh | sed -n '1018,1175p' && nl -ba utils/py/pdda_gov_scan.py | sed -n '1,260p' && nl -ba test/gh365-pdda-gov-scan.sh | sed -n '1,260p' && nl -ba src/project.js | sed -n '320,342p' && nl -ba src/events.js | sed -n '1,100p' && nl -ba .gitignore | sed -n '1,100p'" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-46123-z8dp_mu5
2026-09-04T06:37:26.374906Z ERROR codex_models_manager::manager: failed to renew cache TTL: missing field `base_instructions` at line 94 column 5
 succeeded in 7492ms:
2026-09-03 23:37:19.103 xcodebuild[70758:202324382]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-09-03 23:37:19.409 xcodebuild[70758:202324381] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.
git: warning: confstr() failed with code 5: couldn't get path of DARWIN_USER_TEMP_DIR; using /tmp instead
git: error: couldn't create cache file '/tmp/xcrun_db-rjn4vPcm' (errno=Operation not permitted)
2026-09-03 23:37:20.072 xcodebuild[70829:202324563]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-09-03 23:37:20.271 xcodebuild[70829:202324562] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.
?? relay-system/2026-09-03/consult-427-crash-233636/
?? relay-system/2026-09-04/gh162-hypothesis-setup-qa.md
git: warning: confstr() failed with code 5: couldn't get path of DARWIN_USER_TEMP_DIR; using /tmp instead
git: error: couldn't create cache file '/tmp/xcrun_db-5GVU53FE' (errno=Operation not permitted)
2026-09-03 23:37:21.764 xcodebuild[70921:202325043]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-09-03 23:37:21.959 xcodebuild[70921:202325042] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.
git: warning: confstr() failed with code 5: couldn't get path of DARWIN_USER_TEMP_DIR; using /tmp instead
git: error: couldn't create cache file '/tmp/xcrun_db-4pC1lSX7' (errno=Operation not permitted)
2026-09-03 23:37:22.533 xcodebuild[70923:202325056]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-09-03 23:37:22.805 xcodebuild[70923:202325054] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.
git: warning: confstr() failed with code 5: couldn't get path of DARWIN_USER_TEMP_DIR; using /tmp instead
git: error: couldn't create cache file '/tmp/xcrun_db-QDc7JatB' (errno=Operation not permitted)
2026-09-03 23:37:24.155 xcodebuild[71001:202325247]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-09-03 23:37:24.369 xcodebuild[71001:202325243] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.
git: warning: confstr() failed with code 5: couldn't get path of DARWIN_USER_TEMP_DIR; using /tmp instead
git: error: couldn't create cache file '/tmp/xcrun_db-wSt0v9a3' (errno=Operation not permitted)
2026-09-03 23:37:24.932 xcodebuild[71012:202325288]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-09-03 23:37:25.141 xcodebuild[71012:202325287] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.
2f2c4ad1 WIP on development: a43cc723 Merge pull request #431 from HiQS-Labs/feat/gh412-transient-claim-exit-code
  1018	            found="$p"; break
  1019	          done < <(find "$PDDA_REPO_ROOT" -not -path '*/.git/*' -name "$esc" -print0 2>/dev/null)
  1020	        fi
  1021	        [ -n "$found" ] && candidate="$found"
  1022	      fi
  1023	      ;;
  1024	  esac
  1025	  printf '%s\n' "$candidate"
  1026	}
  1027	
  1028	# GH-365 step 4: extract every reference from ONE doc as "<line>\t<ref>" pairs. This is the
  1029	# per-doc replacement for the per-line `_pdda_gov_extract_refs` fan-out, which spawned 4
  1030	# printf|grep|sed pipelines per line and ran twice per doc (once per check_governance pass) —
  1031	# ~78% of an 87s `pdda.sh run` on macOS. Preferred engine is the in-process scanner
  1032	# utils/py/pdda_gov_scan.py (ONE python process per doc, byte-exact with the legacy output —
  1033	# see that file's CONTRACT header). It lives OUTSIDE utils/pdda/ because this tree is
  1034	# sync-managed (PROJECT/PDDA-SYNC-POLICY.md: new local behaviour belongs outside utils/pdda/**
  1035	# so a later sync cannot silently remove it); PDDA_GOV_SCAN overrides the path for tests.
  1036	# FAIL-SAFE: python3 absent, scanner file missing, or the scanner itself failing (non-zero
  1037	# exit) degrades to the LEGACY per-line path below — findings stay identical, only slower.
  1038	_pdda_gov_extract_doc_refs() {
  1039	  local abs_file="$1" scanner out line_no text ref
  1040	  # $HERE is utils/pdda — the scanner is ONE level up, in utils/py/ (NOT the repo root: this
  1041	  # file can be installed into a target repo whose own py/ contents differ).
  1042	  scanner="${PDDA_GOV_SCAN:-$HERE/../py/pdda_gov_scan.py}"
  1043	  if command -v python3 >/dev/null 2>&1 && [ -f "$scanner" ]; then
  1044	    out="$(python3 "$scanner" "$abs_file" 2>/dev/null)" && { printf '%s\n' "$out"; return 0; }
  1045	    # a failed scanner run falls through to legacy — it must degrade to slow, never to silence
  1046	  fi
  1047	  while IFS=$'\t' read -r line_no text; do
  1048	    [ -n "$line_no" ] || continue
  1049	    while IFS= read -r ref; do
  1050	      [ -n "$ref" ] || continue
  1051	      printf '%s\t%s\n' "$line_no" "$ref"
  1052	    done <<< "$(_pdda_gov_extract_refs "$text")"
  1053	  done < <(_pdda_gov_scannable_lines "$abs_file")
  1054	}
  1055	
  1056	# The per-doc cache check_governance's TWO passes both read (GH-365 step 4: "retaining
  1057	# extracted references across its validation passes"). Same two-file shape as the bare-name
  1058	# find-cache below: the key is a 32-bit cksum and CAN collide, so each entry stores the doc
  1059	# path it was built from and a colliding doc is served UNCACHED (never overwritten) — the
  1060	# GH-48 collision policy, applied one cache up.
  1061	_pdda_gov_doc_refs() {
  1062	  local abs_file="$1" cache_dir="${2:-}" key marker refs_file out
  1063	  if [ -n "$cache_dir" ] && [ -d "$cache_dir" ]; then
  1064	    key="$(_pdda_gov_cache_key "$abs_file")"
  1065	    marker="$cache_dir/$key.doc"
  1066	    refs_file="$cache_dir/$key.refs"
  1067	    if [ -f "$marker" ]; then
  1068	      if [ "$(cat "$marker" 2>/dev/null)" = "$abs_file" ]; then
  1069	        cat "$refs_file" 2>/dev/null
  1070	        return 0
  1071	      fi
  1072	    else
  1073	      out="$(_pdda_gov_extract_doc_refs "$abs_file")"
  1074	      printf '%s' "$abs_file" > "$marker" 2>/dev/null || :
  1075	      if [ -n "$out" ]; then printf '%s\n' "$out" > "$refs_file" 2>/dev/null || :
  1076	      else : > "$refs_file" 2>/dev/null || : ; fi
  1077	      printf '%s\n' "$out"
  1078	      return 0
  1079	    fi
  1080	  fi
  1081	  _pdda_gov_extract_doc_refs "$abs_file"
  1082	}
  1083	
  1084	check_governance() {
  1085	  pdda_reset_counts
  1086	  local CHECK_NAME="pdda-check-governance" rc=0
  1087	  local docs="${PDDA_GOVERNANCE_DOCS:-$PDDA_GOVERNANCE_DOCS_DEFAULT}"
  1088	  local index_doc="${PDDA_GOVERNANCE_INDEX:-$PDDA_GOVERNANCE_INDEX_DEFAULT}"
  1089	  local shipped_docs="${PDDA_GOV_SHIPPED_DOCS:-$PDDA_GOV_SHIPPED_DOCS_DEFAULT}"
  1090	  local ref_exempt="${PDDA_GOV_SHIPPED_DOC_REF_EXEMPTIONS:-$PDDA_GOV_SHIPPED_DOC_REF_EXEMPTIONS_DEFAULT}"
  1091	  local envvar_exempt="${PDDA_GOV_SHIPPED_DOC_ENVVAR_EXEMPTIONS:-$PDDA_GOV_SHIPPED_DOC_ENVVAR_EXEMPTIONS_DEFAULT}"
  1092	  local doc file abs_file from_dir line_no text ref resolved base var line
  1093	  local present_docs="" index_abs is_shipped_doc ref_path
  1094	
  1095	  for doc in $docs; do
  1096	    [ -f "$PDDA_REPO_ROOT/$doc" ] && present_docs="$present_docs $doc"
  1097	  done
  1098	
  1099	  if [ -z "$(pdda_trim "$present_docs")" ]; then
  1100	    pdda_record_finding info "$CHECK_NAME" "$PDDA_REPO_ROOT" 0 \
  1101	      "no governance docs found in the configured set ($docs)" "skip"
  1102	    pdda_emit_summary "$CHECK_NAME" 0
  1103	    return "$(pdda_gated_exit 0)"
  1104	  fi
  1105	
  1106	  # --- (1) dead references: every .md ref in a governance doc must resolve to a real file ---------
  1107	  # warn-only: markdown-reference extraction from free-form prose is inherently more heuristic than
  1108	  # the mechanical checks above (frontmatter, status-table), so a false flag costs one ignorable line
  1109	  # rather than blocking a build even in full mode — same calibration as check_stale/check_changelog.
  1110	  # GH-48 (round 4): batch-resolve every unique bare (no-directory-component) reference across ALL
  1111	  # scanned docs in exactly ONE whole-tree `find` call, before doing anything else — the DoD is one
  1112	  # traversal per check_governance run, not one per unique name (a per-name `find`, even memoized,
  1113	  # still multiplies with the number of DISTINCT dead names on a doc set with many different missing
  1114	  # bare mentions). Pass 1 below just extracts and collects candidate names; pass 2, further down,
  1115	  # is the existing per-ref loop, unchanged except it now reads a fully-populated cache instead of
  1116	  # resolving anything itself.
  1117	  # GH-365 (step 4): both passes read their references from the per-doc cache fed by
  1118	  # _pdda_gov_doc_refs — each doc is extracted ONCE per run (one in-process scan), retained across
  1119	  # the passes, instead of re-running the per-line grep fan-out twice. The bare-name collection and
  1120	  # the batch find-cache below are unchanged.
  1121	  local gov_ref_cache_dir="" gov_names_file="" gov_uniq_names_file=""
  1122	  local gov_find_args gov_name gov_p gov_bn gov_key
  1123	  local gov_refs_dir=""
  1124	  gov_ref_cache_dir="$(mktemp -d 2>/dev/null || true)"
  1125	  gov_refs_dir="$(mktemp -d 2>/dev/null || true)"
  1126	  if [ -n "$gov_ref_cache_dir" ]; then
  1127	    gov_names_file="$(mktemp 2>/dev/null || true)"
  1128	    if [ -n "$gov_names_file" ]; then
  1129	      for doc in $present_docs; do
  1130	        abs_file="$PDDA_REPO_ROOT/$doc"
  1131	        is_shipped_doc=0
  1132	        case " $shipped_docs " in *" $doc "*) is_shipped_doc=1 ;; esac
  1133	        while IFS=$'\t' read -r line_no ref; do
  1134	          [ -n "$line_no" ] || continue
  1135	          if [ "$is_shipped_doc" -eq 1 ]; then
  1136	            ref_path="${ref%%#*}"
  1137	            while :; do
  1138	              case "$ref_path" in
  1139	                ../*) ref_path="${ref_path#../}" ;;
  1140	                ./*) ref_path="${ref_path#./}" ;;
  1141	                *) break ;;
  1142	              esac
  1143	            done
  1144	            case " $ref_exempt " in *" $ref_path "*) continue ;; esac
  1145	          fi
  1146	          case "$ref" in
  1147	            http://*|https://*|//*|/*|./*|../*|*/*) continue ;;   # not a bare-name fallback candidate
  1148	          esac
  1149	          ref_path="${ref%%#*}"
  1150	          [ -f "$PDDA_REPO_ROOT/$ref_path" ] && continue          # resolves directly, no lookup needed
  1151	          printf '%s\n' "$ref_path" >> "$gov_names_file"
  1152	        done < <(_pdda_gov_doc_refs "$abs_file" "$gov_refs_dir")
  1153	      done
  1154	      if [ -s "$gov_names_file" ]; then
  1155	        gov_uniq_names_file="$(mktemp 2>/dev/null || true)"
  1156	        if [ -n "$gov_uniq_names_file" ]; then
  1157	          LC_ALL=C sort -u "$gov_names_file" > "$gov_uniq_names_file"
  1158	          gov_find_args=()
  1159	          while IFS= read -r gov_name; do
  1160	            [ -n "$gov_name" ] || continue
  1161	            [ ${#gov_find_args[@]} -gt 0 ] && gov_find_args+=(-o)
  1162	            gov_find_args+=(-name "$(_pdda_gov_glob_escape "$gov_name")")
  1163	          done < "$gov_uniq_names_file"
  1164	          if [ ${#gov_find_args[@]} -gt 0 ]; then
  1165	            while IFS= read -r -d '' gov_p; do
  1166	              gov_bn="${gov_p##*/}"
  1167	              gov_key="$(_pdda_gov_cache_key "$gov_bn")"
  1168	              [ -f "$gov_ref_cache_dir/$gov_key.name" ] && continue   # first traversal match wins
  1169	              printf '%s' "$gov_bn" > "$gov_ref_cache_dir/$gov_key.name"
  1170	              printf '%s' "$gov_p"  > "$gov_ref_cache_dir/$gov_key.path"
  1171	            done < <(find "$PDDA_REPO_ROOT" -not -path '*/.git/*' \( "${gov_find_args[@]}" \) -print0 2>/dev/null)
  1172	          fi
  1173	          # GH-48 (round 5 follow-up): `find` only ever reports MATCHES, so a genuinely dead name never
  1174	          # got a cache entry above — every confirmed-dead reference still re-triggered its own fallback
  1175	          # `find` in _pdda_gov_resolve_ref, the exact per-name traversal cost this fix exists to remove.
     1	#!/usr/bin/env python3
     2	r"""pdda_gov_scan.py — GH-365 step 4: ONE in-process governance reference scan per doc.
     3	
     4	WHY THIS FILE EXISTS
     5	--------------------
     6	`utils/pdda/pdda.sh`'s check_governance used to extract file references from its governance docs
     7	one LINE at a time: `_pdda_gov_extract_refs` spawned four `printf | grep -oE | sed` pipelines per
     8	line, and check_governance scanned every doc TWICE (pass 1 collects bare names for the batch
     9	find-cache, pass 2 validates refs). ~2,775 scannable lines x 2 passes x ~8 short-lived processes
    10	is tens of thousands of process spawns per run — measured at ~78% of an 87s `pdda.sh run` on
    11	macOS (GH-365 step 4). This file replaces that fan-out with ONE in-process scan per doc that
    12	reproduces the legacy extraction byte-exactly, so check_governance can cache the whole
    13	"<lineno>TAB<ref>" list once per doc and read it from both passes.
    14	
    15	It lives in `utils/py/` — NOT `utils/pdda/` — because `utils/pdda/**` is sync-managed (see
    16	PROJECT/PDDA-SYNC-POLICY.md: "New local behaviour belongs outside utils/pdda/** so a later sync
    17	cannot silently remove it"). A sync that reverts pdda.sh's hook simply falls back to the legacy
    18	per-line path pdda.sh still carries; this scanner then goes unused, never wrong.
    19	
    20	CONTRACT (byte-exact with the legacy path it replaces)
    21	------------------------------------------------------
    22	CLI:  python3 pdda_gov_scan.py <abs-doc-path>
    23	out:  one "<lineno>TAB<ref>" pair per extracted reference, in the legacy iteration order —
    24	      scannable-line order, and LC_ALL=C sort -u order of refs within a line. Refs never
    25	      contain tabs or newlines (the extraction patterns exclude both), so the pair is
    26	      unambiguous.
    27	exit: 0 with the pairs (an empty set prints nothing and exits 0); 2 if the doc cannot be read.
    28	
    29	What "byte-exact" means here, concretely — every stage of the legacy pipeline is reproduced:
    30	
    31	  1. `_pdda_gov_scannable_lines` (awk): lines outside an exempt ```console/```text/```transcript
    32	     fence and outside blockquotes, emitted as "<NR>TAB<line>". Fence delimiter lines and
    33	     blockquote lines are never emitted; lines inside a NON-exempt fence (e.g. ```bash) ARE.
    34	  2. `_pdda_gov_extract_refs` (4x grep -oE + sed) applied to each line, unioned, then
    35	     GH-<n>-*.md names filtered and the result LC_ALL=C sort -u'd:
    36	       (a) markdown-link targets   ](x.md) / ](x.sh#anchor)
    37	       (b) whole-span code refs    `x.md` / `x.sh`
    38	       (c) command-position paths  a *.sh at line start or opening a code span, ending at a
    39	           terminator (space class, backtick, `,;:)"'`) or end of line; leading ./ stripped
    40	       (d) interpreter-wrapped     bash/sudo/env/source/... x.sh — wrapper words (and VAR=val
    41	           assignments for env) stripped; leading ./ stripped
    42	  3. The GH filter '(^|/)GH-[0-9]+-[^/]*\.md(#.*)?$' drops illustrative issue-doc names.
    43	
    44	POSIX-vs-Python notes (why this is not a naive regex transliteration):
    45	  * The file is read as BYTES and decoded latin-1, so one char == one byte and every character
    46	    class below has exactly the ASCII membership its POSIX [[:space:]] / [A-Za-z0-9_] counterpart
    47	    has. Sorting latin-1 strings by codepoint is LC_ALL=C byte order, so the final per-line sort
    48	    matches `LC_ALL=C sort -u` exactly. Python's \s is NOT used anywhere: it is Unicode-aware and
    49	    would admit non-ASCII whitespace grep never matches.
    50	  * POSIX ERE is leftmost-longest; Python `re` is leftmost-first. Where the two could print a
    51	    different FULL match, the legacy sed post-strip normalizes the difference away (an anchor
    52	    chosen as ^ instead of consuming the backtick still yields the same ref after the leading
    53	    backtick/whitespace strips), and the terminator alternation is unambiguous (a terminator
    54	    char is consumed whenever one follows; $ only at end of line). The alternation order below
    55	    (backtick before ^, terminator class before $) mirrors the longest-match preference anyway.
    56	"""
    57	
    58	import re
    59	import sys
    60	
    61	# POSIX [[:space:]] membership: space, tab, newline, CR, FF, VT. Built with chr() so the class
    62	# carries the real control characters, not a spelling of them.
    63	_SP, _TAB, _NL, _CR, _FF, _VT = " ", chr(9), chr(10), chr(13), chr(12), chr(11)
    64	_WS_CHARS = _SP + _TAB + _NL + _CR + _FF + _VT
    65	_WS = "[" + _WS_CHARS + "]"
    66	
    67	# The (c)/(d) terminator class, POSIX [[:space:]`,;:)"'] — space class plus backtick, comma,
    68	# semicolon, colon, close-paren, double quote, single quote. Built by concatenation so neither
    69	# quote needs an escape that a raw string would mangle.
    70	_TERM_C = "[" + _WS_CHARS + "`" + ",;:)" + '"' + "']"
    71	
    72	FENCE_DELIM_RE = re.compile("^[" + _WS_CHARS + "]*```")   # /^[[:space:]]*```/
    73	LEADING_TICKS_RE = re.compile("^[" + _WS_CHARS + "]*`+")  # sub(/^[[:space:]]*`+/,"",info)
    74	ANY_WS_RE = re.compile("[" + _WS_CHARS + "]+")            # gsub(/[[:space:]]/,"",info)
    75	BLOCKQUOTE_RE = re.compile("^[" + _WS_CHARS + "]*>")      # /^[[:space:]]*>/
    76	EXEMPT_INFO_STRINGS = ("console", "text", "transcript")
    77	
    78	# (a) markdown-link targets — '\]\([^)[:space:]]+\.(md|sh)(#[A-Za-z0-9_-]*)?\)'
    79	# The negated class is built from _WS_CHARS (the bare members), not _WS (a full class), because
    80	# this class is already open — embedding a bracketed class inside it would close it early.
    81	PAT_LINK = re.compile(r"\]\([^)" + _WS_CHARS + r"]+\.(md|sh)(#[A-Za-z0-9_-]*)?\)")
    82	
    83	# (b) whole-span code refs — '`[A-Za-z0-9_./-]+\.(md|sh)(#[A-Za-z0-9_-]*)?`'
    84	PAT_CODESPAN = re.compile(r"`[A-Za-z0-9_./-]+\.(md|sh)(#[A-Za-z0-9_-]*)?`")
    85	
    86	# (c) command-position paths. A *.sh token opening a code span or the scanned line, ending at
    87	# one of the terminators or end of line. A trailing '.' is deliberately NOT a terminator —
    88	# deploy.sh.bak must not yield deploy.sh (see the legacy comment in pdda.sh).
    89	_SUFFIX = r"\.sh(" + _TERM_C + r"|$)"
    90	PAT_COMMAND = re.compile(
    91	    r"(`|^)" + _WS + r"*(\.{1,2}/)?[A-Za-z0-9_.][A-Za-z0-9_./-]*" + _SUFFIX
    92	)
    93	
    94	# (d) interpreter-wrapped invocations — one or more wrapper words (sudo|source|bash|zsh|env|sh|.,
    95	# i.e. a literal '.' for POSIX sourcing), each optionally followed by VAR=val assignments (env),
    96	# then the path in argument position. The path's leading char class rejects '-' (so `bash -c`
    97	# is not a path) and '"'/'$' (a quoted or variable-expanded argument is not a path claim).
    98	_WRAPPER = (
    99	    r"((sudo|source|bash|zsh|env|sh|\.)("
   100	    + _WS
   101	    + r"+[A-Za-z_][A-Za-z0-9_]*=[^"
   102	    + _WS_CHARS
   103	    + r"]*)*"
   104	    + _WS
   105	    + r"+)+"
   106	)
   107	PAT_WRAPPED = re.compile(
   108	    r"(`|^)" + _WS + r"*" + _WRAPPER + r"(\.{1,2}/)?[A-Za-z0-9_.][A-Za-z0-9_./-]*" + _SUFFIX
   109	)
   110	
   111	# sed post-strips, translated. Each operates on one grep -o match string.
   112	LEADING_WS_STRIP = re.compile("^" + _WS + "+")
   113	TRAILING_TERM_STRIP = re.compile(_TERM_C + "+$")  # s/[[:space:]`,;:)"']+$//
   114	WRAPPER_STRIP = re.compile(_WRAPPER)              # s/^((sudo|...)+// — used anchored at start
   115	
   116	# The final GH-<n>-*.md filter — grep -Ev '(^|/)GH-[0-9]+-[^/]*\.md(#.*)?$'
   117	GH_NAME_FILTER = re.compile(r"(^|/)GH-[0-9]+-[^/]*\.md(#.*)?$")
   118	
   119	
   120	def scannable_lines(text):
   121	    """Yield (lineno, line) pairs outside exempt fences/blockquotes — the awk filter."""
   122	    lines = text.split(_NL)
   123	    # awk's last record has no terminator: "a\n" is ONE record, but split yields a trailing "".
   124	    if text.endswith(_NL):
   125	        lines.pop()
   126	    in_fence = False
   127	    fence_exempt = False
   128	    for lineno, line in enumerate(lines, 1):
   129	        if FENCE_DELIM_RE.match(line):
   130	            if in_fence:
   131	                in_fence = False
   132	                fence_exempt = False
   133	            else:
   134	                info = LEADING_TICKS_RE.sub("", line)
   135	                info = ANY_WS_RE.sub("", info)
   136	                info = info.lower()
   137	                in_fence = True
   138	                fence_exempt = info in EXEMPT_INFO_STRINGS
   139	            continue
   140	        if in_fence and fence_exempt:
   141	            continue
   142	        if BLOCKQUOTE_RE.match(line):
   143	            continue
   144	        yield lineno, line
   145	
   146	
   147	def _strip_span(match_text, drop_wrapper):
   148	    """The sed chain every (c)/(d) match goes through, in the legacy order."""
   149	    s = match_text
   150	    if s.startswith("`"):                 # s/^`//
   151	        s = s[1:]
   152	    s = LEADING_WS_STRIP.sub("", s)       # s/^[[:space:]]+//
   153	    if drop_wrapper:                      # s/^((sudo|source|...)+//   ((d) only)
   154	        m = WRAPPER_STRIP.match(s)
   155	        if m:
   156	            s = s[m.end():]
   157	    s = TRAILING_TERM_STRIP.sub("", s)    # s/[[:space:]`,;:)"']+$//
   158	    if s.startswith("./"):                # s|^\./||
   159	        s = s[2:]
   160	    return s
   161	
   162	
   163	def extract_refs(line):
   164	    """Refs for ONE line — the union of patterns (a)-(d), GH-filtered, LC_ALL=C sorted unique.
   165	
   166	    Reproduces `_pdda_gov_extract_refs "$line"` including its final `sort -u`: the four pattern
   167	    outputs are unioned and deduplicated per line, in byte order.
   168	    """
   169	    refs = []
   170	    for m in PAT_LINK.finditer(line):
   171	        refs.append(m.group(0)[2:-1])  # strip leading "](" and trailing ")"
   172	    for m in PAT_CODESPAN.finditer(line):
   173	        refs.append(m.group(0)[1:-1])  # strip the surrounding backticks
   174	    for m in PAT_COMMAND.finditer(line):
   175	        refs.append(_strip_span(m.group(0), drop_wrapper=False))
   176	    for m in PAT_WRAPPED.finditer(line):
   177	        refs.append(_strip_span(m.group(0), drop_wrapper=True))
   178	    return sorted(set(r for r in refs if not GH_NAME_FILTER.search(r)))
   179	
   180	
   181	def scan(path):
   182	    """The whole-doc scan: every scannable line's refs, as "lineno TAB ref" lines."""
   183	    with open(path, "rb") as fh:
   184	        text = fh.read().decode("latin-1")
   185	    out = []
   186	    for lineno, line in scannable_lines(text):
   187	        for ref in extract_refs(line):
   188	            out.append("%d" % lineno + _TAB + ref)
   189	    return out
   190	
   191	
   192	def main(argv):
   193	    if len(argv) != 2:
   194	        sys.stderr.write("usage: pdda_gov_scan.py <abs-doc-path>" + _NL)
   195	        return 2
   196	    try:
   197	        lines = scan(argv[1])
   198	    except OSError as exc:
   199	        sys.stderr.write("pdda_gov_scan: cannot read %s: %s" % (argv[1], exc) + _NL)
   200	        return 2
   201	    payload = _NL.join(lines) + (_NL if lines else "")
   202	    sys.stdout.buffer.write(payload.encode("latin-1"))
   203	    sys.stdout.buffer.flush()
   204	    return 0
   205	
   206	
   207	if __name__ == "__main__":
   208	    sys.exit(main(sys.argv))
     1	#!/usr/bin/env bash
     2	# gh365-pdda-gov-scan.sh — GH-365 step 4: the per-doc governance reference scanner.
     3	#
     4	# The hot path this closes: check_governance extracted references one LINE at a time (four
     5	# printf|grep|sed pipelines per line, every doc scanned twice — ~78% of an 87s `pdda.sh run` on
     6	# macOS). utils/py/pdda_gov_scan.py does ONE in-process scan per doc; check_governance caches the
     7	# "<lineno>\t<ref>" list per doc and both passes read the cache, with the legacy per-line path
     8	# kept as a fail-safe fallback.
     9	#
    10	# What this suite witnesses:
    11	#   A. EQUIVALENCE on the real governance docs — the scanner's output is byte-identical to the
    12	#      LIVE legacy functions (extracted from pdda.sh by name, so a legacy edit re-witnesses
    13	#      equivalence) over every doc of PDDA_GOVERNANCE_DOCS_DEFAULT present in this repo.
    14	#   B. Synthetic corpus — one line per pattern shape (markdown link, anchored link, code span,
    15	#      command-position at line start and after a backtick, each interpreter wrapper, and the
    16	#      negatives: exempt-fence mention, blockquote mention, GH-*.md names, deploy.sh.bak,
    17	#      bash -c). Both paths must agree AND the scanner must get every shape right.
    18	#   C. RED control — a fixture doc with a genuinely dead .md reference makes check_governance
    19	#      emit the dead-reference warn on BOTH the scanner path and the forced-legacy path
    20	#      (PDDA_GOV_SCAN pointed at a nonexistent file), with identical findings text.
    21	#   D. PDDA_TIMINGS smoke — PDDA_TIMINGS=1 prints at least one "PDDA_TIMING <check> <ms>" line
    22	#      to stderr and leaves stdout byte-identical; without it, zero timing lines.
    23	#   E. Speed — the scanner runs at most once per doc per run (PATH-shim invocation counter over
    24	#      a two-doc fixture), and a real-repo `pdda.sh governance` completes under a generous 30s
    25	#      ceiling (observed ~5s post-change, ~72s pre-change; recorded in the commit message — the
    26	#      ceiling is flake headroom, not the claim).
    27	source "$(dirname "$0")/_setup.sh" gh365-pdda-gov-scan
    28	set -u
    29	HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    30	REPO="$(cd "$HERE/.." && pwd)"
    31	PDDA="$REPO/utils/pdda/pdda.sh"
    32	SCANNER="$REPO/utils/py/pdda_gov_scan.py"
    33	
    34	[ -f "$SCANNER" ] || fail "A0: scanner missing at $SCANNER"
    35	[ -f "$PDDA" ] || fail "A0: pdda.sh missing at $PDDA"
    36	
    37	# The LIVE legacy functions, extracted from pdda.sh by name markers (they have no pdda-lib
    38	# dependencies — pure awk/grep/sed). Extracting the live text (rather than pinning a copy here)
    39	# is the point: if someone edits the legacy path, this suite re-witnesses equivalence against it.
    40	LEGACY="$WORK/gov-legacy-funcs.sh"
    41	awk '/^_pdda_gov_scannable_lines\(\) \{/{grab=1} /^_pdda_gov_glob_escape\(\) \{/{grab=0} grab' \
    42	  "$PDDA" > "$LEGACY"
    43	[ "$(grep -c '^_pdda_gov_[a-z_]*() {' "$LEGACY")" -eq 2 ] \
    44	  || fail "A0: expected exactly 2 legacy _pdda_gov_* functions between the markers, got $(grep -c '^_pdda_gov_[a-z_]*() {' "$LEGACY")"
    45	
    46	# The legacy driver — EXACTLY check_governance's pre-GH-365 nested loops (scannable lines, then
    47	# per-line extraction), emitting the same "<lineno>\t<ref>" stream the scanner produces.
    48	cat > "$WORK/legacy-driver.sh" <<'DRV'
    49	run_legacy() {
    50	  local abs_file="$1" line_no text ref
    51	  while IFS=$'\t' read -r line_no text; do
    52	    [ -n "$line_no" ] || continue
    53	    while IFS= read -r ref; do
    54	      [ -n "$ref" ] || continue
    55	      printf '%s\t%s\n' "$line_no" "$ref"
    56	    done <<< "$(_pdda_gov_extract_refs "$text")"
    57	  done < <(_pdda_gov_scannable_lines "$abs_file")
    58	}
    59	DRV
    60	
    61	legacy_scan() {  # <abs-doc> -> "<lineno>\t<ref>" lines via the live legacy functions
    62	  (
    63	    . "$LEGACY"
    64	    . "$WORK/legacy-driver.sh"
    65	    run_legacy "$1"
    66	  )
    67	}
    68	
    69	echo "== test: gh365-pdda-gov-scan =="
    70	
    71	# ── A. equivalence on the real governance docs ──────────────────────────────────────────────────
    72	for doc in ROUTER.md AGENTS.md GUIDING-PRINCIPLES.md README.md CLAUDE.md PROJECT/PDDA.md utils/pdda/PDDA-INSTALL.md; do
    73	  abs="$REPO/$doc"
    74	  if [ ! -f "$abs" ]; then
    75	    pass "A: $doc absent in this repo — skipped (CLAUDE.md is optional by design)"
    76	    continue
    77	  fi
    78	  legacy_scan "$abs" > "$WORK/a-leg.txt"
    79	  python3 "$SCANNER" "$abs" > "$WORK/a-scan.txt"
    80	  if cmp -s "$WORK/a-leg.txt" "$WORK/a-scan.txt"; then
    81	    pass "A: $doc — scanner byte-identical to legacy ($(wc -l < "$WORK/a-scan.txt" | tr -d ' ') refs)"
    82	  else
    83	    fail "A: $doc — scanner/legacy differ:"$'\n'"$(diff "$WORK/a-leg.txt" "$WORK/a-scan.txt" | head -10)"
    84	  fi
    85	done
    86	
    87	# ── B. synthetic corpus — every pattern shape, positives and negatives ──────────────────────────
    88	CORPUS="$WORK/corpus.md"
    89	cat > "$CORPUS" <<'EOF'
    90	# GH-365 synthetic corpus — one line per pattern shape
    91	
    92	Links: [router](ROUTER.md) and [script](utils/x.sh) and [anchored](scripts/run.sh#setup).
    93	Code spans: `deploy.md` and `lib/run.sh`.
    94	utils/pdda/pdda-sync.sh push --force
    95	After a backtick: `.xyz/utils/marathon-plan.sh --help`
    96	bash utils/x.sh
    97	sudo ./install.sh
    98	env FOO=1 ./run.sh
    99	sh setup.sh
   100	bash -c "echo deploy.sh"
   101	
   102	```console
   103	fence-hidden.sh run
   104	```
   105	
   106	> quote-hidden.sh run
   107	
   108	Filtered GH names: [one](GH-123-EXAMPLE.md) and `GH-456-y.md`.
   109	deploy.sh.bak at line start must not extract.
   110	A mid-sentence deploy.sh.bak stays silent too.
   111	EOF
   112	
   113	legacy_scan "$CORPUS" > "$WORK/b-leg.txt"
   114	python3 "$SCANNER" "$CORPUS" > "$WORK/b-scan.txt"
   115	cmp -s "$WORK/b-leg.txt" "$WORK/b-scan.txt" \
   116	  && pass "B1: synthetic corpus — scanner byte-identical to legacy ($(wc -l < "$WORK/b-scan.txt" | tr -d ' ') refs)" \
   117	  || fail "B1: synthetic corpus — scanner/legacy differ:"$'\n'"$(diff "$WORK/b-leg.txt" "$WORK/b-scan.txt" | head -10)"
   118	
   119	# The hand-derived expectation: exactly these refs, nothing else. Line numbers are deliberately
   120	# not pinned here — A already witnesses lineno fidelity; this pins the extracted ref SET.
   121	awk -F'\t' '{print $2}' "$WORK/b-scan.txt" | LC_ALL=C sort -u > "$WORK/b-refs.txt"
   122	cat > "$WORK/b-want.txt" <<'EOF'
   123	.xyz/utils/marathon-plan.sh
   124	ROUTER.md
   125	deploy.md
   126	install.sh
   127	lib/run.sh
   128	run.sh
   129	scripts/run.sh#setup
   130	setup.sh
   131	utils/pdda/pdda-sync.sh
   132	utils/x.sh
   133	EOF
   134	cmp -s "$WORK/b-refs.txt" "$WORK/b-want.txt" \
   135	  && pass "B2: every pattern shape extracted exactly (10 refs)" \
   136	  || fail "B2: ref set mismatch:"$'\n'"$(diff "$WORK/b-want.txt" "$WORK/b-refs.txt")"
   137	
   138	# Negative controls, named one by one so a regression reads as its shape, not "set differs".
   139	! grep -qx 'fence-hidden.sh' "$WORK/b-refs.txt" \
   140	  && pass "B3: console-fence mention NOT extracted (exempt fence)" \
   141	  || fail "B3: fence mention extracted — exempt-fence filter broken"
   142	! grep -qx 'quote-hidden.sh' "$WORK/b-refs.txt" \
   143	  && pass "B4: blockquote mention NOT extracted" \
   144	  || fail "B4: blockquote mention extracted — blockquote filter broken"
   145	! grep -Eq '^GH-[0-9]+-' "$WORK/b-refs.txt" \
   146	  && pass "B5: GH-<n>-*.md illustrative names filtered" \
   147	  || fail "B5: a GH-*.md name survived the filter"
   148	! grep -qx 'deploy.sh' "$WORK/b-refs.txt" \
   149	  && pass "B6: deploy.sh.bak does NOT yield deploy.sh (trailing . is not a terminator)" \
   150	  || fail "B6: deploy.sh extracted from deploy.sh.bak"
   151	grep -qx 'utils/x.sh' "$WORK/b-refs.txt" \
   152	  && pass "B7: interpreter-wrapped bash utils/x.sh recovered" \
   153	  || fail "B7: interpreter-wrapped extraction missing"
   154	
   155	# ── C. RED control — a dead .md reference warns on BOTH the scanner and legacy paths ────────────
   156	F="$WORK/fixture-root"
   157	mkdir -p "$F"
   158	require_fixture "$F" "governance red-control fixture root"
   159	printf '# fixture index\n\nRead [guide](guide.md) and the missing [dead](dead-walkthrough.md).\n' > "$F/ROUTER.md"
   160	printf '# guide\n\nBack to [router](ROUTER.md).\n' > "$F/guide.md"
   161	
   162	run_gov() {  # <scanner-path> — check_governance against the fixture root
   163	  PDDA_REPO_ROOT="$F" PDDA_GOVERNANCE_DOCS="ROUTER.md" PDDA_GOVERNANCE_INDEX="ROUTER.md" \
   164	    PDDA_ACTIVITY_LOG=/dev/null PDDA_GOV_SCAN="$1" bash "$PDDA" governance
   165	}
   166	
   167	run_gov "$SCANNER" > "$WORK/c-scan.out" 2>&1
   168	grep -q "dead reference 'dead-walkthrough.md'" "$WORK/c-scan.out" \
   169	  && pass "C1: dead reference warns on the scanner path" \
   170	  || fail "C1: scanner path stayed silent about the dead reference:"$'\n'"$(cat "$WORK/c-scan.out")"
   171	
   172	run_gov "$WORK/no-such-scanner.py" > "$WORK/c-leg.out" 2>&1   # scanner file absent -> legacy fallback
   173	grep -q "dead reference 'dead-walkthrough.md'" "$WORK/c-leg.out" \
   174	  && pass "C2: dead reference warns on the forced-legacy fallback path" \
   175	  || fail "C2: legacy fallback stayed silent about the dead reference:"$'\n'"$(cat "$WORK/c-leg.out")"
   176	
   177	cmp -s "$WORK/c-scan.out" "$WORK/c-leg.out" \
   178	  && pass "C3: both paths emit byte-identical governance findings" \
   179	  || fail "C3: scanner/legacy findings differ on the fixture:"$'\n'"$(diff "$WORK/c-leg.out" "$WORK/c-scan.out")"
   180	
   181	# ── D. PDDA_TIMINGS smoke — stderr-only decoration, zero stdout drift ───────────────────────────
   182	TF="$WORK/timing-root"
   183	mkdir -p "$TF"
   184	require_fixture "$TF" "PDDA_TIMINGS fixture root"
   185	PDDA_REPO_ROOT="$TF" PDDA_ACTIVITY_LOG=/dev/null bash "$PDDA" run > "$WORK/d-off.out" 2> "$WORK/d-off.err"
   186	PDDA_REPO_ROOT="$TF" PDDA_ACTIVITY_LOG=/dev/null PDDA_TIMINGS=1 bash "$PDDA" run > "$WORK/d-on.out" 2> "$WORK/d-on.err"
   187	[ "$(grep -c '^PDDA_TIMING ' "$WORK/d-on.err")" -ge 1 ] \
   188	  && pass "D1: PDDA_TIMINGS=1 prints $(grep -c '^PDDA_TIMING ' "$WORK/d-on.err") PDDA_TIMING lines to stderr" \
   189	  || fail "D1: PDDA_TIMINGS=1 printed no PDDA_TIMING lines:"$'\n'"$(cat "$WORK/d-on.err")"
   190	[ "$(grep -c '^PDDA_TIMING ' "$WORK/d-off.err")" -eq 0 ] \
   191	  && pass "D2: without PDDA_TIMINGS, zero timing lines (default OFF)" \
   192	  || fail "D2: timing lines appeared without PDDA_TIMINGS:"$'\n'"$(cat "$WORK/d-off.err")"
   193	cmp -s "$WORK/d-off.out" "$WORK/d-on.out" \
   194	  && pass "D3: stdout byte-identical with and without PDDA_TIMINGS (zero output drift)" \
   195	  || fail "D3: PDDA_TIMINGS changed stdout:"$'\n'"$(diff "$WORK/d-off.out" "$WORK/d-on.out" | head -6)"
   196	
   197	# ── E. speed — once per doc per run, and a real-repo ceiling ────────────────────────────────────
   198	# E1: invocation count via a PATH shim that tallies every python3 call during ONE governance run
   199	# over the two-doc fixture. The shim execs the real interpreter resolved BEFORE the shim PATH is
   200	# prepended, so it cannot recurse, and the PATH change is scoped to this single invocation so the
   201	# suite's own python3 calls (fixture guard) are not tallied.
   202	SHIM="$WORK/pyshim"
   203	mkdir -p "$SHIM"
   204	REAL_PY="$(command -v python3)"
   205	printf '#!/usr/bin/env bash\nn=$(( $(cat "%s/count" 2>/dev/null || echo 0) + 1 ))\nprintf %%s "$n" > "%s/count"\nexec "%s" "$@"\n' \
   206	  "$SHIM" "$SHIM" "$REAL_PY" > "$SHIM/python3"
   207	chmod +x "$SHIM/python3"
   208	: > "$SHIM/count"
   209	PDDA_REPO_ROOT="$F" PDDA_GOVERNANCE_DOCS="ROUTER.md guide.md" PDDA_GOVERNANCE_INDEX="ROUTER.md" \
   210	  PDDA_ACTIVITY_LOG=/dev/null PATH="$SHIM:$PATH" bash "$PDDA" governance > "$WORK/e1.out" 2>&1
   211	calls="$(cat "$SHIM/count")"
   212	[ "$calls" -le 2 ] \
   213	  && pass "E1: scanner invoked $calls time(s) for 2 docs in one run (cache retains across passes)" \
   214	  || fail "E1: scanner invoked $calls times for 2 docs — the per-doc cache is not retaining"
   215	
   216	# E2: real-repo governance under a generous ceiling. Pre-change this measured ~72s on macOS; the
   217	# post-change run is ~5s. The assert is flake headroom (<30s), NOT the speed claim — the honest
   218	# number is recorded in the step-4 commit message.
   219	t0="$(perl -MTime::HiRes -e 'print int(Time::HiRes::time()*1000)')"
   220	PDDA_ACTIVITY_LOG=/dev/null bash "$PDDA" governance > "$WORK/e2.out" 2>&1
   221	t1="$(perl -MTime::HiRes -e 'print int(Time::HiRes::time()*1000)')"
   222	ms=$((t1 - t0))
   223	[ "$ms" -lt 30000 ] \
   224	  && pass "E2: real-repo governance completed in ${ms}ms (< 30000ms ceiling; pre-change ~72000ms)" \
   225	  || fail "E2: real-repo governance took ${ms}ms — over the 30000ms ceiling"
   226	
   227	echo "== gh365-pdda-gov-scan: $PASS passed, $FAIL failed =="
   228	[ "$FAIL" -eq 0 ] || exit 1
   229	exit 0
   320	  for (const t of done) lines.push(`- ${t.id}`);
   321	  lines.push('');
   322	
   323	  lines.push('## Circuit-Broken');
   324	  if (!broken.length) lines.push('_(none)_');
   325	  for (const t of broken) {
   326	    lines.push(`- ${t.id} by ${t.break.agent} — reason: ${JSON.stringify(t.break.reason)}`);
   327	  }
   328	  lines.push('');
   329	
   330	  return lines.join('\n');
   331	}
   332	
   333	/**
   334	 * Reads the event log, projects it, and writes both `.tick/STATE.md` (the
   335	 * human-readable state) and `.tick/rejected.jsonl` (the fenced-event audit
   336	 * log, fully rewritten each call so it's always a deterministic mirror of the
   337	 * current event set).
   338	 * @param {string} repoRoot - absolute path to the repo root
   339	 * @returns {{tasks: Map<string, Object>, stateFile: string, rejections: Object[], rejectedFile: string}}
   340	 */
   341	function project(repoRoot) {
   342	  const events = readAllEvents(repoRoot);
     1	'use strict';
     2	
     3	const fs = require('fs');
     4	const path = require('path');
     5	
     6	// 0.2.0 — adds the optional `epoch` field to claim/mutation events (Part B
     7	// Phase 1, R1 epoch fencing). Events without `epoch` are read as epoch 0, so
     8	// pre-0.2.0 logs project identically. See decisions/2026-06-18-epoch-fencing.md.
     9	const SCHEMA_VERSION = '0.2.0';
    10	
    11	const EVENT_TYPES = new Set([
    12	  'task.created',
    13	  'task.claimed',
    14	  'task.released',
    15	  'task.scope_changed',
    16	  'task.commented',
    17	  'task.heartbeat',
    18	  'task.done',
    19	  'task.circuit_break',
    20	  // Cost signals (Phase 1, COST-OBSERVABILITY-PLAN). Deterministic, additive, ignored by the
    21	  // coordination metrics — they describe what a turn COST, not how it coordinated.
    22	  'cost.tokens',
    23	  'cost.human',
    24	  'cost.memory',
    25	  // Marathon phase-chain signals (Phase 3, marathon-drive.sh). Emitted at phase boundaries by
    26	  // marathon-drive, not by individual turn-takers. Not coordination signals — ignored by tick analyze.
    27	  'marathon.phase.start',
    28	  'marathon.phase.approved',
    29	  'marathon.phase.escalated',
    30	  'marathon.phase.revision',
    31	  'marathon.complete',
    32	  // Cross-agent dependency-drift signal (GH-68, warn-only Phase 1). Emitted by relay-turn-lib.sh
    33	  // post-commit when a landed turn changes a shared surface, so the NEXT agent's shim can inject a
    34	  // heads-up. Purely informational: carries no epoch, claims no task, is NOT a state-transition —
    35	  // the projection kernel ignores it exactly like cost.*/marathon.* signals.
    36	  // See decisions/2026-07-01-cross-agent-dep-conflict.md.
    37	  'dependency.drift',
    38	]);
    39	
    40	const CRITICAL_EVENTS = new Set([
    41	  'task.claimed',
    42	  'task.scope_changed',
    43	  'task.released',
    44	  'task.circuit_break',
    45	  'task.done',
    46	]);
    47	
    48	/**
    49	 * Path to the shared local event-log directory for a repo clone.
    50	 * @param {string} repoRoot - absolute path to the repo root
    51	 * @returns {string} absolute path to `<repoRoot>/.tick/events`
    52	 */
    53	function eventsDir(repoRoot) {
    54	  return path.join(repoRoot, '.tick', 'events');
    55	}
    56	
    57	/**
    58	 * Creates the events directory (and any missing parents) if it doesn't exist yet.
    59	 * @param {string} repoRoot - absolute path to the repo root
    60	 * @returns {void}
    61	 */
    62	function ensureEventsDir(repoRoot) {
    63	  fs.mkdirSync(eventsDir(repoRoot), { recursive: true });
    64	}
    65	
    66	/**
    67	 * Current timestamp in ISO-8601, overridable via `TICK_TS` for deterministic tests.
    68	 * @returns {string} ISO-8601 timestamp
    69	 */
    70	function isoNow() {
    71	  if (process.env.TICK_TS) return process.env.TICK_TS;
    72	  return new Date().toISOString();
    73	}
    74	
    75	function tsForFilename(iso) {
    76	  return iso.replace(/:/g, '-');
    77	}
    78	
    79	function safeSegment(s) {
    80	  return String(s).replace(/[^A-Za-z0-9._-]/g, '_');
    81	}
    82	
    83	/**
    84	 * Appends one event to the log as a new `.jsonl` file (one event per file — the
    85	 * projection's unit of atomicity). Fields present in the event depend on `type`;
    86	 * unset optional fields are omitted from the written JSON, not written as null,
    87	 * so unrelated event types stay byte-identical across schema additions.
    88	 *
    89	 * Publication is atomic (GH-14): the document is written to a `.tmp` name that
    90	 * {@link readAllEvents}' `.jsonl` filter never matches, then `rename(2)`d onto
    91	 * the final path, so concurrent readers either do not see the event yet or see
    92	 * the complete document — never a partial/empty file.
    93	 * @param {string} repoRoot - absolute path to the repo root
    94	 * @param {Object} fields
    95	 * @param {string} fields.type - one of {@link EVENT_TYPES}
    96	 * @param {string} fields.task - task id
    97	 * @param {string} fields.agent - acting agent id
    98	 * @param {string} [fields.note]
    99	 * @param {string[]} [fields.paths] - glob patterns the event declares/claims
   100	 * @param {string} [fields.to_agent] - handoff target (task.released)
     1	.tick/
     2	node_modules/
     3	.vscode/
     4	# GH-480: tools/vscode-cockpit ships its own F5 debug launch config as part of the extension.
     5	!tools/vscode-cockpit/.vscode/
     6	!tools/vscode-cockpit/.vscode/*.json
     7	.claude/settings.local.json
     8	.claude/scheduled_tasks.lock
     9	.DS_Store
    10	**/.DS_Store
    11	PROJECT/PDDA-ACTIVITY.jsonl
    12	relay-system/2026-06-21/shakedown-lib.sh
    13	/temp/
    14	.pdda-gh-state.tsv
    15	# GH-75 / GH-96: XYZ.json is the local newest-first completion log; XYZ.heartbeat.json is the mutable
    16	# in-flight companion marker. Both are machine-specific and kept out of git to avoid churn.
    17	XYZ.json
    18	XYZ.json.lock/
    19	XYZ.heartbeat.json
    20	# GH-78: hourly doc-preflight telemetry — per-machine, per-run edit/warn logs; gitignored to avoid churn.
    21	utils/telemetry/preflight-log/
    22	# swarm-preflight packet output — ephemeral per-run artifact (sleuth-app already gitignores this).
    23	relay-system/preflight/
    24	# GH-161: persistent CODEX_LOG/AGY_LOG default (rtl_default_log in relay-turn-lib.sh). MUST stay
    25	# ignored — rtl_check already deletes any file landing in the tracked tree that matches the shim's
    26	# own transcript path, so an un-ignored log here would be wiped at the end of every single turn.
    27	relay-system/logs/
    28	# Hourly HQ marathon scan (utils/hq/hourly-global-scan.sh) — a live, machine-local rolling snapshot
    29	# overwritten every run; committing it each hour would be pure churn with no historical value.
    30	PROJECT/2-WORKING/GLOBAL-HQ-MARATHON.md
    31	# Aider aux files: a MANUAL (non-shim) aider run drops .aider.chat.history.md / .aider.input.history /
    32	# .aider.llm.history into the tree. The aider-turn.sh shim already redirects these via AIDER_AUX_DIR;
    33	# this guards ad-hoc runs so they can't re-leak as untracked noise.
    34	.aider*
    35	# GH-112 Python layer: bytecode caches from pytest / XYZ_PYTHON=1 runs.
    36	__pycache__/
    37	*.pyc
    38	# codebase-memory MCP index — a per-device local tool cache (like .tick/); never committed.
    39	.codebase-memory/
    40	
    41	# Aider Studio (auto-added)
    42	REPO_MAP.md
    43	
    44	# ask-self RAG — kept PER-USER / PER-DEVICE, not committed to the shared repo.
    45	# The whole integration layer is local: teammates opt in by installing ask-self
    46	# themselves (see ask-self's ASK_SELF_INTEGRATION.md) rather than inheriting it here.
    47	/ask_self/
    48	/scripts/ask-self-ingest.sh
    49	/scripts/ask-self-query.sh
    50	/.claude/commands/reingest.md
    51	/.claude/commands/ask_self.md
    52	# Local working index lives under temp/rag/ (already ignored via /temp/); these lines
    53	# also catch the per-DB sidecars anywhere they land.
    54	temp/rag/
    55	temp/ask-self-rag.env
    56	*__embed_cache.sqlite
    57	*__events.jsonl
    58	# ask-self generated architecture doc (falls back to ASK_SELF.md; our ARCHITECTURE.md is hand-owned).
    59	ASK_SELF.md
    60	ARCHITECTURE-BAK.md
    61	
    62	# Sentinel Tier 1 debug capture — local only, never committed.
    63	debug.log
    64	/BTW
    65	
    66	# Vendored per-repo harness copy (xyz-vendor.sh) — machine-local, never committed.
    67	.xyz/
    68	
    69	# GH-509: per-commit local gate evidence — machine-local, self-reported, never committed.
    70	.gate-evidence/
    71	
    72	# GH-32 Phase 0: side-by-side generator output is regenerable proof, never committed
    73	RELEASES.generated.md
    74	RELEASES.generated.md.drift
    75	# `check --rebuild` displaces the old DB to this path, and utils/releases-merge-resolve.sh tells the
    76	# operator it is "untracked and safe to delete". It was not actually ignored, so a `git add -A`
    77	# during a merge resolution would have committed a ~200KB stale binary copy of the ledger — the one
    78	# artifact guaranteed to disagree with the dump (GH-57 probe, 2026-08-19).
    79	releases.db.bak
    80	
    81	# GH-38: agent2agent lock files are flock mutexes, deliberately never unlinked (unlinking is what
    82	# reintroduced the steal race). They are per-machine runtime state, never discussion content.
    83	relay-system/**/.*.lock
    84	# Doorbell liveness markers — per-agent, mtime-only, regenerated by every watch.
    85	relay-system/**/*.watch.agent*
    86	# GH-236 QA / GH-327: agent-chorus USED to root its telemetry sidecar at <discussion>/runtime for
    87	# any discussion path, so a join/send/close against a legacy relay-system discussion wrote
    88	# telemetry.jsonl and close_report.json into the worktree — unreachable by `telemetry purge`, which
    89	# only walks the store. Fixed at the source: telemetry_runtime_dir() now returns None for anything
    90	# not named conversation.md, so no such file is written any more.
    91	#
    92	# Kept anyway, deliberately. It costs nothing, and it is the backstop if a future call site
    93	# re-derives a runtime path by hand instead of going through the resolver — which is exactly the
    94	# mistake close_report.json had already made once.
    95	relay-system/**/runtime/
    96	
    97	# Audit probe output when --out is pointed at the worktree (default is a scratch dir).
    98	audit/out/
    99	.relay-scratch/
   100	

exec
/bin/zsh -lc "rg -n -C 4 \"comment reference|COMMENT_REFERENCE|comment.*scan|comment.*ref|check-ignore\" utils/pdda/pdda.sh test --glob '"'!test/baselines/**'"' && nl -ba utils/pdda/pdda.sh | sed -n '1170,1285p' && nl -ba utils/py/pdda_gov_scan.py | sed -n '100,245p' && nl -ba test/gh365-pdda-gov-scan.sh | sed -n '1,75p'" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-46123-z8dp_mu5
 succeeded in 0ms:
test/xyz-vendor.sh-131-# NEGATIVE CONTROL — the pre-fix behavior, so this suite proves it detects the bug and not merely
test/xyz-vendor.sh-132-# the fix. An append-only ensure_gitignore sails straight past a blocking rule.
test/xyz-vendor.sh-133-BR="$(mkignore_repo '/relay-system')"
test/xyz-vendor.sh-134-( cd "$BR" && printf 'x\n' > f && git add -A >/dev/null 2>&1 && git -c user.email=t@t -c user.name=t commit -qm s >/dev/null 2>&1 )
test/xyz-vendor.sh:135:git -C "$BR" check-ignore -q relay-system \
test/xyz-vendor.sh-136-  && pass "  control: the fixture repo really does ignore relay-system" \
test/xyz-vendor.sh-137-  || fail "  control: fixture is not actually blocking — the refusal assertions prove nothing"
test/xyz-vendor.sh-138-
test/xyz-vendor.sh-139-# An unrelated ignore rule must NOT trip the refusal: over-refusing makes vendoring unusable.
--
test/gh411-tick-log-foreign-cwd.sh-88-
test/gh411-tick-log-foreign-cwd.sh-89-# ── GREEN 4: the `drift` VERB keeps its warn-only invariant ───────────────────
test/gh411-tick-log-foreign-cwd.sh-90-# GH-68 / decisions/2026-07-01-cross-agent-dep-conflict.md: `drift` is a separate VERB, not a log
test/gh411-tick-log-foreign-cwd.sh-91-# type, and is deliberately outside MUTATING_GUARD_VERBS so it can NEVER hard-fail a turn. It sits
test/gh411-tick-log-foreign-cwd.sh:92:# next to `cost`/`log` in the same comment at bin/tick:35, which is exactly why a later refactor
test/gh411-tick-log-foreign-cwd.sh-93-# generalising "guard everything that isn't cost.*" would silently capture it. Pinned here so that
test/gh411-tick-log-foreign-cwd.sh-94-# refactor fails loudly instead of quietly breaking the warn-only contract.
test/gh411-tick-log-foreign-cwd.sh-95-# FRESH dir, for the same reason as GREEN 2: the guard only fires where .tick/events is absent,
test/gh411-tick-log-foreign-cwd.sh-96-# so asserting this in a directory a prior case already seeded would pass under a refactor that
--
test/gh430-state-dir-tracked-default.sh-48-fi
test/gh430-state-dir-tracked-default.sh-49-
test/gh430-state-dir-tracked-default.sh-50-if [ -n "$SD" ]; then
test/gh430-state-dir-tracked-default.sh-51-  REL="${SD#"$REPO"/}"
test/gh430-state-dir-tracked-default.sh:52:  if (cd "$REPO" && git check-ignore -q "$REL"); then
test/gh430-state-dir-tracked-default.sh-53-    fail "default STATE_DIR path is gitignored (zero containment protection, GH-396): $REL"
test/gh430-state-dir-tracked-default.sh-54-  else
test/gh430-state-dir-tracked-default.sh-55-    pass "default STATE_DIR path is NOT gitignored -> tracked-eligible: $REL"
test/gh430-state-dir-tracked-default.sh-56-  fi
--
test/path-integrity.sh-88-# simulate the "tests-reference-slug" partial signal — a fixture literal, not a real reference.
test/path-integrity.sh-89-# GH-63: test/signal-triage.sh passes `test/foo.sh` / `test/some-test.sh` as synthetic `--test` inputs
test/path-integrity.sh-90-# to exercise the classifier (they name no real file) — same class, skip them.
test/path-integrity.sh-91-# GH-108/GH-126/GH-127: test/swarm-preflight.sh's T35/T36 fixtures create test/bare-redirect.sh,
test/path-integrity.sh:92:# test/no-touch.sh, and test/comment-only.sh in a throwaway temp repo to exercise the genuine-ref
test/path-integrity.sh-93-# and bare-`>` fs-touching detectors — fixture literals, not references to files in this tree.
test/path-integrity.sh-94-# GH-321: test/gh308-frozen-twin-guard.sh feeds `relay-automation/codex-turnn.sh` to the frozen-twin
test/path-integrity.sh-95-# guard to prove a TYPO'd path in a `Frozen-twin-exception:` trailer fails loudly instead of silently
test/path-integrity.sh-96-# covering nothing. The token is deliberately a path that does not resolve — that IS the test input —
--
test/gh284-runlog-heartbeat.sh-206-
test/gh284-runlog-heartbeat.sh-207-# The parser LOGIC being right is not enough — the first version of this fix was logically correct
test/gh284-runlog-heartbeat.sh-208-# and still broken, because the driver invoked it as `python3 - "$marker" <<'PYEOF'`: a heredoc and
test/gh284-runlog-heartbeat.sh-209-# a pipe both claim stdin, so python got the comments JSON prepended to its own source and died
test/gh284-runlog-heartbeat.sh:210:# with a SyntaxError. `comment_id` was therefore always empty and the run log always POSTed a
test/gh284-runlog-heartbeat.sh-211-# duplicate — the exact bug the --slurp fix above exists to prevent. This suite MISSED it because
test/gh284-runlog-heartbeat.sh-212-# it ran the parser from a file, which is not how the driver runs it. Pin the invocation shape too.
test/gh284-runlog-heartbeat.sh-213-INVOKE="$(grep -n 'python3' "$ROOT/relay-automation/marathon-drive.sh" | grep -F "$(printf '%s' 'runlog_marker_py')" || true)"
test/gh284-runlog-heartbeat.sh-214-printf '%s' "$INVOKE" | grep -Fq 'python3 -c' \
--
test/gh14-atomic-append.sh-146-const prefix = process.argv[2];
test/gh14-atomic-append.sh-147-const count = Number(process.argv[3]);
test/gh14-atomic-append.sh-148-for (let i = 1; i <= count; i++) {
test/gh14-atomic-append.sh-149-  const task = `${prefix}-${String(i).padStart(4, '0')}`;
test/gh14-atomic-append.sh:150:  appendEvent(root, { type: 'task.commented', task, agent: `writer-${prefix}`, note: `note-${task}` });
test/gh14-atomic-append.sh-151-}
test/gh14-atomic-append.sh-152-console.log(`writer ${prefix} done`);
test/gh14-atomic-append.sh-153-EOF
test/gh14-atomic-append.sh-154-cat > "$WORK/stress-reader.js" <<'EOF'
--
test/gh314-transcript-writeset.sh-148-HEALTHY="$(mk_target healthy-transcript '')"
test/gh314-transcript-writeset.sh-149-: >"$DISPATCH_LOG"
test/gh314-transcript-writeset.sh-150-rc="$(run_drive "$HEALTHY" "$WORK/healthy.out")"
test/gh314-transcript-writeset.sh-151-
test/gh314-transcript-writeset.sh:152:/usr/bin/grep -qi "cannot track\|check-ignore\|ignored by" "$WORK/healthy.out" \
test/gh314-transcript-writeset.sh-153-  && fail "GH-314: the healthy target was refused by the write-set check — output: $(cat "$WORK/healthy.out")" \
test/gh314-transcript-writeset.sh-154-  || pass "CONTROL: a healthy target is not refused by the transcript check"
test/gh314-transcript-writeset.sh-155-
test/gh314-transcript-writeset.sh-156-echo "  gh314-transcript-writeset: $PASS pass, $FAIL fail"
--
test/marathon-root-audit.sh-438-audit_root="$(cd "$(dirname "$0")/.." && pwd)"
test/marathon-root-audit.sh-439-ignore_violations=0
test/marathon-root-audit.sh-440-for probe in marathon-system/audit-probe/RELAY.md marathon-system/audit-probe/ESCALATION.md \
test/marathon-root-audit.sh-441-             phases/audit-probe/RELAY.md phases/audit-probe/ESCALATION.md; do
test/marathon-root-audit.sh:442:  if git -C "$audit_root" check-ignore -q "$probe" 2>/dev/null; then
test/marathon-root-audit.sh-443-    echo "FAIL: .gitignore covers $probe, but the driver stages it with \`git add --\` + check=True — a new same-repo phase would exit 1 while recording itself" >&2
test/marathon-root-audit.sh-444-    ignore_violations=$((ignore_violations + 1))
test/marathon-root-audit.sh-445-  fi
test/marathon-root-audit.sh-446-done
--
test/gh197-vendor-tier-split.sh-209-[ -f "$EX_REPO/.gitignore" ] && pass "Gitignore carve-out: .gitignore created when rule lives in info/exclude" || fail "Gitignore carve-out: .gitignore was not created"
test/gh197-vendor-tier-split.sh-210-grep -Fqx '!releases.db' "$EX_REPO/.gitignore" \
test/gh197-vendor-tier-split.sh-211-  && pass "Gitignore carve-out: !releases.db added to newly-created .gitignore" \
test/gh197-vendor-tier-split.sh-212-  || fail "Gitignore carve-out: !releases.db missing from newly-created .gitignore"
test/gh197-vendor-tier-split.sh:213:! git -C "$EX_REPO" check-ignore -q releases.db \
test/gh197-vendor-tier-split.sh-214-  && pass "Gitignore carve-out: releases.db is now trackable despite info/exclude rule" \
test/gh197-vendor-tier-split.sh-215-  || fail "Gitignore carve-out: releases.db remains ignored"
test/gh197-vendor-tier-split.sh-216-
test/gh197-vendor-tier-split.sh-217-# 6d. Negative case: repo without *.db ignore rule does NOT get !releases.db appended
--
test/agent-chorus-bridge.sh-458-expect_contains "A3: banner names DISABLED auth on an unauthenticated bridge" "$banner_off" "DISABLED"
test/agent-chorus-bridge.sh-459-
test/agent-chorus-bridge.sh-460-# The fixture values go through variables, not inline literals. security-scan.sh's
test/agent-chorus-bridge.sh-461-# PATTERN_CRED_ASSIGN flags a secret-named variable assigned an inline literal wherever it appears
test/agent-chorus-bridge.sh:462:# (including inside a comment — it is a static text scan, so this note must not spell the shape
test/agent-chorus-bridge.sh-463-# out) — correctly, since it cannot
test/agent-chorus-bridge.sh-464-# know a probe value from a real one — and PATTERN_CRED_EXCLUDE deliberately permits a `$`-prefixed
test/agent-chorus-bridge.sh-465-# value. Indirection is the sanctioned shape here, not a baseline entry: baselining a fixture
test/agent-chorus-bridge.sh-466-# teaches the scanner to ignore the pattern that matters.
--
test/mktemp-trap-guard.sh-81-
test/mktemp-trap-guard.sh-82-  # GH-177 review (Codex round 3, Blocker 1): scanning whole physical lines missed a same-line
test/mktemp-trap-guard.sh-83-  # multi-statement chain — `TMP="$(mktemp -d)"; cd "$TMP"` (or `; TMP="$(cd "$TMP" && pwd)"`) all on
test/mktemp-trap-guard.sh-84-  # ONE line is the identical failure shape, just never split across lines at all. Flatten each
test/mktemp-trap-guard.sh:85:  # non-comment physical line into `;`-separated segments and scan those instead, so a same-line chain
test/mktemp-trap-guard.sh-86-  # is checked exactly like the same statements on separate lines would be. Naive split — doesn't
test/mktemp-trap-guard.sh-87-  # respect quoting/heredocs — an accepted limitation of this heuristic audit, same tradeoff already
test/mktemp-trap-guard.sh-88-  # made by its other checks (comment-skip, no real parser). A comment line contributes NO segments
test/mktemp-trap-guard.sh-89-  # (splitting `# TMP=...; stuff` would wrongly treat "stuff" as live code).
--
test/gh376-relay-drive-lock-parity.sh-36-# NOT hypothetical: this suite went 12/6 inside the Nightwatch wave-3 gate on 2026-08-11 while
test/gh376-relay-drive-lock-parity.sh-37-# passing 18/0 standalone, and halted the marathon at phase 1 for a defect that was in this file and
test/gh376-relay-drive-lock-parity.sh-38-# not in the phase's own work. Setting RELAY_DRIVER_LOCKED=1 and running this file reproduces it
test/gh376-relay-drive-lock-parity.sh-39-# exactly. (Spell that invocation out rather than abbreviating the filename: test/path-integrity.sh
test/gh376-relay-drive-lock-parity.sh:40:# reads a path-shaped token in any comment as a real reference and fails the gate on the ellipsis.)
test/gh376-relay-drive-lock-parity.sh-41-#
test/gh376-relay-drive-lock-parity.sh-42-# The per-suite clear is the shipped remedy for exactly this (GH-441 Phase 1), and this file is the
test/gh376-relay-drive-lock-parity.sh-43-# fifth to need it — see test/driver-lock.sh:11, gh284-runlog-heartbeat.sh:12, gh331-cost-summary.sh:24,
test/gh376-relay-drive-lock-parity.sh-44-# gh342-sentinel-debug-log-python.sh:27. Section F below then re-asserts the inherited=1 behaviour
--
test/gh551-resolver-refuses.sh-1-#!/usr/bin/env bash
test/gh551-resolver-refuses.sh-2-# test/gh551-resolver-refuses.sh — GH-551 resolver refusal contract suite.
test/gh551-resolver-refuses.sh:3:# gate-evidence: {"form":"pre-fix-replay","observed":true,"result":"reproducer: bash test/gh551-resolver-refuses.sh; assertions verify: (1) contract comment is present in utils/py/rtl.py; (2) resolve_tick_bin raises RuntimeError on unresolvable binary (refusal observed) vs passes on valid binary; (3) resolve_tick_repo_root raises RuntimeError on missing root (refusal observed) vs passes on valid root; (4) resolve_turn_root raises RuntimeError on invalid explicit root (refusal observed) vs passes on valid root"}
test/gh551-resolver-refuses.sh-4-
test/gh551-resolver-refuses.sh-5-source "$(dirname "$0")/_setup.sh" gh551-resolver-refuses
test/gh551-resolver-refuses.sh-6-
test/gh551-resolver-refuses.sh-7-RTL_PY="$(cd "$(dirname "$0")/.." && pwd)/utils/py/rtl.py"
--
test/gh57-live-merge-resolve.sh-213-# of the ledger — the one artifact guaranteed to disagree with the dump.
test/gh57-live-merge-resolve.sh-214-echo "-- 6: releases.db.bak is ignored, not merely unmentioned"
test/gh57-live-merge-resolve.sh-215-ok "the rebuild really produced a .bak to worry about" "[ -f '$R3/releases.db.bak' ]"
test/gh57-live-merge-resolve.sh-216-ok "this repo's .gitignore covers releases.db.bak" \
test/gh57-live-merge-resolve.sh:217:   "git -C '$ROOT_DIR' check-ignore -q releases.db.bak"
test/gh57-live-merge-resolve.sh-218-
test/gh57-live-merge-resolve.sh-219-# ── 7. EDGE CASE: an explicitly empty --root must be refused, not silently retargeted ──────────
test/gh57-live-merge-resolve.sh-220-# This is here because it actually happened. While writing this suite, `conflicted()` aborted on a
test/gh57-live-merge-resolve.sh-221-# bash 3.2 `local` quirk and returned "", the call became `--root ""`, the resolver fell back to
--
test/gh514-write-set-trackable.sh-186-: >"$DISPATCH_LOG"
test/gh514-write-set-trackable.sh-187-rc3="$(run_drive "$EXCL" "$WORK/excl.out")"
test/gh514-write-set-trackable.sh-188-d3="$(/usr/bin/grep -c DISPATCHED "$DISPATCH_LOG" 2>/dev/null | head -1)"; d3="${d3:-0}"
test/gh514-write-set-trackable.sh-189-if [ "$d3" -eq 0 ] && /usr/bin/grep -q "BLOCKED before dispatch" "$WORK/excl.out"; then
test/gh514-write-set-trackable.sh:190:  pass "an exclude-file rule is caught too (git check-ignore is the authority, not a .gitignore parser)"
test/gh514-write-set-trackable.sh-191-else
test/gh514-write-set-trackable.sh-192-  fail "GH-514: a .git/info/exclude rule was missed — the check is reading .gitignore itself instead of asking git. dispatches=$d3"
test/gh514-write-set-trackable.sh-193-fi
test/gh514-write-set-trackable.sh-194-case "$(cat "$WORK/excl.out")" in
--
test/gh514-write-set-trackable.sh-198-
test/gh514-write-set-trackable.sh-199-# ---------------------------------------------------------------------------
test/gh514-write-set-trackable.sh-200-# Case 4 — a NEGATION rule re-includes the path, so the guard must not block it
test/gh514-write-set-trackable.sh-201-# ---------------------------------------------------------------------------
test/gh514-write-set-trackable.sh:202:# `git check-ignore -v` exits 0 whenever ANY pattern matches — including a negation that
test/gh514-write-set-trackable.sh-203-# re-includes the path. The exit status therefore does NOT mean "ignored", which is what this
test/gh514-write-set-trackable.sh-204-# function's docstring originally claimed. Reading it that way blocks a marathon before dispatch
test/gh514-write-set-trackable.sh-205-# over a path git will happily track, and the operator is told to fix a rule that is already
test/gh514-write-set-trackable.sh-206-# correct. Reproduced directly:
test/gh514-write-set-trackable.sh-207-#
test/gh514-write-set-trackable.sh:208:#     .gitignore:  *.log        -> check-ignore rc=0, `git add` REFUSES  (genuinely ignored)
test/gh514-write-set-trackable.sh:209:#                  !logs/keep.log -> check-ignore rc=0, `git add` ACCEPTS  (re-included)
test/gh514-write-set-trackable.sh:210:#                  (no rule)    -> check-ignore rc=1
test/gh514-write-set-trackable.sh-211-#
test/gh514-write-set-trackable.sh-212-# so rc=0 alone cannot distinguish the middle row from the first.
test/gh514-write-set-trackable.sh-213-echo "-- case 4: a negation rule re-includes the path — the guard must NOT block"
test/gh514-write-set-trackable.sh-214-NEG="$(mk_target negated 'marathon-system/**
--
test/gh514-write-set-trackable.sh-217-rc4="$(run_drive "$NEG" "$WORK/neg.out")"
test/gh514-write-set-trackable.sh-218-if /usr/bin/grep -q "BLOCKED before dispatch" "$WORK/neg.out"; then
test/gh514-write-set-trackable.sh-219-  fail "GH-514 false positive: a path re-included by a negation rule was blocked; git can track it, so the run was refused over a rule that is already correct"
test/gh514-write-set-trackable.sh-220-else
test/gh514-write-set-trackable.sh:221:  pass "a path re-included by a negation rule is NOT blocked (check-ignore exit 0 means a pattern matched, not that the path is ignored)"
test/gh514-write-set-trackable.sh-222-fi
test/gh514-write-set-trackable.sh-223-# The guard must still be live in this fixture — a change that simply stopped blocking everything
test/gh514-write-set-trackable.sh-224-# would also pass the assertion above. Prove the genuinely-ignored case still refuses.
test/gh514-write-set-trackable.sh-225-BOTH="$(mk_target negated-and-ignored '!marathon-system/**
  1170	              printf '%s' "$gov_p"  > "$gov_ref_cache_dir/$gov_key.path"
  1171	            done < <(find "$PDDA_REPO_ROOT" -not -path '*/.git/*' \( "${gov_find_args[@]}" \) -print0 2>/dev/null)
  1172	          fi
  1173	          # GH-48 (round 5 follow-up): `find` only ever reports MATCHES, so a genuinely dead name never
  1174	          # got a cache entry above — every confirmed-dead reference still re-triggered its own fallback
  1175	          # `find` in _pdda_gov_resolve_ref, the exact per-name traversal cost this fix exists to remove.
  1176	          # Second pass: any unique name still without an entry after the batch find truly has no match
  1177	          # anywhere (or lost a same-key collision to a different name, in which case it correctly falls
  1178	          # back on lookup regardless — same as a live colliding name) — cache it as a verified "-" miss
  1179	          # so a repeat mention of the same dead name doesn't re-scan either.
  1180	          while IFS= read -r gov_name; do
  1181	            [ -n "$gov_name" ] || continue
  1182	            gov_key="$(_pdda_gov_cache_key "$gov_name")"
  1183	            [ -f "$gov_ref_cache_dir/$gov_key.name" ] && continue
  1184	            printf '%s' "$gov_name" > "$gov_ref_cache_dir/$gov_key.name"
  1185	            printf '%s' "-"         > "$gov_ref_cache_dir/$gov_key.path"
  1186	          done < "$gov_uniq_names_file"
  1187	          rm -f "$gov_uniq_names_file"
  1188	        fi
  1189	      fi
  1190	      rm -f "$gov_names_file"
  1191	    fi
  1192	  fi
  1193	  for doc in $present_docs; do
  1194	    abs_file="$PDDA_REPO_ROOT/$doc"
  1195	    from_dir="$(dirname "$abs_file")"
  1196	    is_shipped_doc=0
  1197	    case " $shipped_docs " in *" $doc "*) is_shipped_doc=1 ;; esac
  1198	    while IFS=$'\t' read -r line_no ref; do
  1199	      [ -n "$line_no" ] || continue
  1200	      if [ "$is_shipped_doc" -eq 1 ]; then
  1201	        # normalize away leading ./ or ../ so a relative mention (e.g. "../../PROJECT/3-COMPLETED/
  1202	        # PDDA-SYNC-TO-OTHER-REPOS.md") matches the same manifest entry as its repo-relative form
  1203	        ref_path="${ref%%#*}"
  1204	        while :; do
  1205	          case "$ref_path" in
  1206	            ../*) ref_path="${ref_path#../}" ;;
  1207	            ./*) ref_path="${ref_path#./}" ;;
  1208	            *) break ;;
  1209	          esac
  1210	        done
  1211	        case " $ref_exempt " in *" $ref_path "*) continue ;; esac
  1212	      fi
  1213	      resolved="$(_pdda_gov_resolve_ref "$ref" "$from_dir" "$gov_ref_cache_dir")" || continue
  1214	      [ -f "$resolved" ] && continue
  1215	      pdda_record_finding warn "$CHECK_NAME" "$abs_file" "$line_no" \
  1216	        "dead reference '$ref' — no file at $(pdda_relpath "$resolved")" "fix-dead-reference"
  1217	    done < <(_pdda_gov_doc_refs "$abs_file" "$gov_refs_dir")
  1218	  done
  1219	  [ -n "$gov_ref_cache_dir" ] && rm -rf "$gov_ref_cache_dir"
  1220	  [ -n "$gov_refs_dir" ] && [ -d "$gov_refs_dir" ] && rm -rf "$gov_refs_dir"
  1221	
  1222	  # --- (2) orphan governance docs: a present doc the index doc never points at --------------------
  1223	  index_abs="$PDDA_REPO_ROOT/$index_doc"
  1224	  if [ -f "$index_abs" ]; then
  1225	    for doc in $present_docs; do
  1226	      [ "$doc" = "$index_doc" ] && continue
  1227	      base="$(basename "$doc")"
  1228	      if ! grep -Fq "$base" "$index_abs"; then
  1229	        pdda_record_finding warn "$CHECK_NAME" "$PDDA_REPO_ROOT/$doc" 1 \
  1230	          "governance doc is not referenced anywhere in $index_doc — a cold agent following its read order won't discover it" \
  1231	          "add-index-pointer"
  1232	      fi
  1233	    done
  1234	  else
  1235	    pdda_record_finding info "$CHECK_NAME" "$index_abs" 0 \
  1236	      "governance index doc '$index_doc' not found; skipping orphan-doc check" "skip"
  1237	  fi
  1238	
  1239	  # --- (3) subcommand drift: every pdda.sh dispatcher subcommand must be named in the index doc ---
  1240	  if [ -f "$index_abs" ]; then
  1241	    local subcommands sub
  1242	    subcommands="$(awk '
  1243	      /case "\$cmd" in/ { in_case = 1; next }
  1244	      in_case && /^esac/ { in_case = 0 }
  1245	      in_case && /^[[:space:]]*[A-Za-z*][A-Za-z0-9*_-]*(\|[A-Za-z0-9*_-]+)*\)/ {
  1246	        line = $0
  1247	        sub(/^[[:space:]]*/, "", line)
  1248	        sub(/\).*/, "", line)
  1249	        n = split(line, parts, "|")
  1250	        for (i = 1; i <= n; i++) print parts[i]
  1251	      }
  1252	    ' "$HERE/pdda.sh" | grep -Ev '^(run|help|-h|--help|\*)$' | LC_ALL=C sort -u)"
  1253	
  1254	    for sub in $subcommands; do
  1255	      if ! grep -Eq "(^|[^A-Za-z0-9_-])${sub}([^A-Za-z0-9_-]|\$)" "$index_abs"; then
  1256	        pdda_record_finding error "$CHECK_NAME" "$index_abs" 1 \
  1257	          "pdda.sh subcommand '$sub' is not documented anywhere in $index_doc — keep the installer surface in lockstep (AGENTS.md #5)" \
  1258	          "document-subcommand"
  1259	        rc=1
  1260	      fi
  1261	    done
  1262	  fi
  1263	
  1264	  # --- (4) env-var drift: a PDDA_* var named in a governance doc should exist in a shipped script ---
  1265	  # warn-only: PDDA_GOVERNANCE_INDEX_DEFAULT names ONLY the files a target install actually receives
  1266	  # (utils/pdda/*.sh + install.sh). PDDA-INSTALL.md itself ships to every target but also documents
  1267	  # utils/pdda/pdda-sync.sh (a canonical-only tool never copied to targets, per its own "Canonical install
  1268	  # set" list) — so a var like PDDA_SYNC_BACKUPS legitimately mentioned there will never resolve in a
  1269	  # target install. That's expected, not drift, so a false flag must cost one ignorable line, not a
  1270	  # blocked build (same calibration as the dead-reference check above).
  1271	  local shipped_vars doc_vars install_sh
  1272	  install_sh="$PDDA_REPO_ROOT/install.sh"
  1273	  shipped_vars="$(grep -ohE 'PDDA_[A-Z0-9_]+' "$HERE"/*.sh "$install_sh" 2>/dev/null | LC_ALL=C sort -u)"
  1274	  for doc in $present_docs; do
  1275	    abs_file="$PDDA_REPO_ROOT/$doc"
  1276	    is_shipped_doc=0
  1277	    case " $shipped_docs " in *" $doc "*) is_shipped_doc=1 ;; esac
  1278	    doc_vars="$(grep -ohE 'PDDA_[A-Z0-9_]+' "$abs_file" | LC_ALL=C sort -u)"
  1279	    for var in $doc_vars; do
  1280	      if [ "$is_shipped_doc" -eq 1 ]; then
  1281	        case " $envvar_exempt " in *" $var "*) continue ;; esac
  1282	      fi
  1283	      if ! printf '%s\n' "$shipped_vars" | grep -Fxq "$var"; then
  1284	        line="$(grep -nF "$var" "$abs_file" | head -1 | cut -d: -f1)"
  1285	        pdda_record_finding warn "$CHECK_NAME" "$abs_file" "${line:-1}" \
   100	    + _WS
   101	    + r"+[A-Za-z_][A-Za-z0-9_]*=[^"
   102	    + _WS_CHARS
   103	    + r"]*)*"
   104	    + _WS
   105	    + r"+)+"
   106	)
   107	PAT_WRAPPED = re.compile(
   108	    r"(`|^)" + _WS + r"*" + _WRAPPER + r"(\.{1,2}/)?[A-Za-z0-9_.][A-Za-z0-9_./-]*" + _SUFFIX
   109	)
   110	
   111	# sed post-strips, translated. Each operates on one grep -o match string.
   112	LEADING_WS_STRIP = re.compile("^" + _WS + "+")
   113	TRAILING_TERM_STRIP = re.compile(_TERM_C + "+$")  # s/[[:space:]`,;:)"']+$//
   114	WRAPPER_STRIP = re.compile(_WRAPPER)              # s/^((sudo|...)+// — used anchored at start
   115	
   116	# The final GH-<n>-*.md filter — grep -Ev '(^|/)GH-[0-9]+-[^/]*\.md(#.*)?$'
   117	GH_NAME_FILTER = re.compile(r"(^|/)GH-[0-9]+-[^/]*\.md(#.*)?$")
   118	
   119	
   120	def scannable_lines(text):
   121	    """Yield (lineno, line) pairs outside exempt fences/blockquotes — the awk filter."""
   122	    lines = text.split(_NL)
   123	    # awk's last record has no terminator: "a\n" is ONE record, but split yields a trailing "".
   124	    if text.endswith(_NL):
   125	        lines.pop()
   126	    in_fence = False
   127	    fence_exempt = False
   128	    for lineno, line in enumerate(lines, 1):
   129	        if FENCE_DELIM_RE.match(line):
   130	            if in_fence:
   131	                in_fence = False
   132	                fence_exempt = False
   133	            else:
   134	                info = LEADING_TICKS_RE.sub("", line)
   135	                info = ANY_WS_RE.sub("", info)
   136	                info = info.lower()
   137	                in_fence = True
   138	                fence_exempt = info in EXEMPT_INFO_STRINGS
   139	            continue
   140	        if in_fence and fence_exempt:
   141	            continue
   142	        if BLOCKQUOTE_RE.match(line):
   143	            continue
   144	        yield lineno, line
   145	
   146	
   147	def _strip_span(match_text, drop_wrapper):
   148	    """The sed chain every (c)/(d) match goes through, in the legacy order."""
   149	    s = match_text
   150	    if s.startswith("`"):                 # s/^`//
   151	        s = s[1:]
   152	    s = LEADING_WS_STRIP.sub("", s)       # s/^[[:space:]]+//
   153	    if drop_wrapper:                      # s/^((sudo|source|...)+//   ((d) only)
   154	        m = WRAPPER_STRIP.match(s)
   155	        if m:
   156	            s = s[m.end():]
   157	    s = TRAILING_TERM_STRIP.sub("", s)    # s/[[:space:]`,;:)"']+$//
   158	    if s.startswith("./"):                # s|^\./||
   159	        s = s[2:]
   160	    return s
   161	
   162	
   163	def extract_refs(line):
   164	    """Refs for ONE line — the union of patterns (a)-(d), GH-filtered, LC_ALL=C sorted unique.
   165	
   166	    Reproduces `_pdda_gov_extract_refs "$line"` including its final `sort -u`: the four pattern
   167	    outputs are unioned and deduplicated per line, in byte order.
   168	    """
   169	    refs = []
   170	    for m in PAT_LINK.finditer(line):
   171	        refs.append(m.group(0)[2:-1])  # strip leading "](" and trailing ")"
   172	    for m in PAT_CODESPAN.finditer(line):
   173	        refs.append(m.group(0)[1:-1])  # strip the surrounding backticks
   174	    for m in PAT_COMMAND.finditer(line):
   175	        refs.append(_strip_span(m.group(0), drop_wrapper=False))
   176	    for m in PAT_WRAPPED.finditer(line):
   177	        refs.append(_strip_span(m.group(0), drop_wrapper=True))
   178	    return sorted(set(r for r in refs if not GH_NAME_FILTER.search(r)))
   179	
   180	
   181	def scan(path):
   182	    """The whole-doc scan: every scannable line's refs, as "lineno TAB ref" lines."""
   183	    with open(path, "rb") as fh:
   184	        text = fh.read().decode("latin-1")
   185	    out = []
   186	    for lineno, line in scannable_lines(text):
   187	        for ref in extract_refs(line):
   188	            out.append("%d" % lineno + _TAB + ref)
   189	    return out
   190	
   191	
   192	def main(argv):
   193	    if len(argv) != 2:
   194	        sys.stderr.write("usage: pdda_gov_scan.py <abs-doc-path>" + _NL)
   195	        return 2
   196	    try:
   197	        lines = scan(argv[1])
   198	    except OSError as exc:
   199	        sys.stderr.write("pdda_gov_scan: cannot read %s: %s" % (argv[1], exc) + _NL)
   200	        return 2
   201	    payload = _NL.join(lines) + (_NL if lines else "")
   202	    sys.stdout.buffer.write(payload.encode("latin-1"))
   203	    sys.stdout.buffer.flush()
   204	    return 0
   205	
   206	
   207	if __name__ == "__main__":
   208	    sys.exit(main(sys.argv))
     1	#!/usr/bin/env bash
     2	# gh365-pdda-gov-scan.sh — GH-365 step 4: the per-doc governance reference scanner.
     3	#
     4	# The hot path this closes: check_governance extracted references one LINE at a time (four
     5	# printf|grep|sed pipelines per line, every doc scanned twice — ~78% of an 87s `pdda.sh run` on
     6	# macOS). utils/py/pdda_gov_scan.py does ONE in-process scan per doc; check_governance caches the
     7	# "<lineno>\t<ref>" list per doc and both passes read the cache, with the legacy per-line path
     8	# kept as a fail-safe fallback.
     9	#
    10	# What this suite witnesses:
    11	#   A. EQUIVALENCE on the real governance docs — the scanner's output is byte-identical to the
    12	#      LIVE legacy functions (extracted from pdda.sh by name, so a legacy edit re-witnesses
    13	#      equivalence) over every doc of PDDA_GOVERNANCE_DOCS_DEFAULT present in this repo.
    14	#   B. Synthetic corpus — one line per pattern shape (markdown link, anchored link, code span,
    15	#      command-position at line start and after a backtick, each interpreter wrapper, and the
    16	#      negatives: exempt-fence mention, blockquote mention, GH-*.md names, deploy.sh.bak,
    17	#      bash -c). Both paths must agree AND the scanner must get every shape right.
    18	#   C. RED control — a fixture doc with a genuinely dead .md reference makes check_governance
    19	#      emit the dead-reference warn on BOTH the scanner path and the forced-legacy path
    20	#      (PDDA_GOV_SCAN pointed at a nonexistent file), with identical findings text.
    21	#   D. PDDA_TIMINGS smoke — PDDA_TIMINGS=1 prints at least one "PDDA_TIMING <check> <ms>" line
    22	#      to stderr and leaves stdout byte-identical; without it, zero timing lines.
    23	#   E. Speed — the scanner runs at most once per doc per run (PATH-shim invocation counter over
    24	#      a two-doc fixture), and a real-repo `pdda.sh governance` completes under a generous 30s
    25	#      ceiling (observed ~5s post-change, ~72s pre-change; recorded in the commit message — the
    26	#      ceiling is flake headroom, not the claim).
    27	source "$(dirname "$0")/_setup.sh" gh365-pdda-gov-scan
    28	set -u
    29	HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    30	REPO="$(cd "$HERE/.." && pwd)"
    31	PDDA="$REPO/utils/pdda/pdda.sh"
    32	SCANNER="$REPO/utils/py/pdda_gov_scan.py"
    33	
    34	[ -f "$SCANNER" ] || fail "A0: scanner missing at $SCANNER"
    35	[ -f "$PDDA" ] || fail "A0: pdda.sh missing at $PDDA"
    36	
    37	# The LIVE legacy functions, extracted from pdda.sh by name markers (they have no pdda-lib
    38	# dependencies — pure awk/grep/sed). Extracting the live text (rather than pinning a copy here)
    39	# is the point: if someone edits the legacy path, this suite re-witnesses equivalence against it.
    40	LEGACY="$WORK/gov-legacy-funcs.sh"
    41	awk '/^_pdda_gov_scannable_lines\(\) \{/{grab=1} /^_pdda_gov_glob_escape\(\) \{/{grab=0} grab' \
    42	  "$PDDA" > "$LEGACY"
    43	[ "$(grep -c '^_pdda_gov_[a-z_]*() {' "$LEGACY")" -eq 2 ] \
    44	  || fail "A0: expected exactly 2 legacy _pdda_gov_* functions between the markers, got $(grep -c '^_pdda_gov_[a-z_]*() {' "$LEGACY")"
    45	
    46	# The legacy driver — EXACTLY check_governance's pre-GH-365 nested loops (scannable lines, then
    47	# per-line extraction), emitting the same "<lineno>\t<ref>" stream the scanner produces.
    48	cat > "$WORK/legacy-driver.sh" <<'DRV'
    49	run_legacy() {
    50	  local abs_file="$1" line_no text ref
    51	  while IFS=$'\t' read -r line_no text; do
    52	    [ -n "$line_no" ] || continue
    53	    while IFS= read -r ref; do
    54	      [ -n "$ref" ] || continue
    55	      printf '%s\t%s\n' "$line_no" "$ref"
    56	    done <<< "$(_pdda_gov_extract_refs "$text")"
    57	  done < <(_pdda_gov_scannable_lines "$abs_file")
    58	}
    59	DRV
    60	
    61	legacy_scan() {  # <abs-doc> -> "<lineno>\t<ref>" lines via the live legacy functions
    62	  (
    63	    . "$LEGACY"
    64	    . "$WORK/legacy-driver.sh"
    65	    run_legacy "$1"
    66	  )
    67	}
    68	
    69	echo "== test: gh365-pdda-gov-scan =="
    70	
    71	# ── A. equivalence on the real governance docs ──────────────────────────────────────────────────
    72	for doc in ROUTER.md AGENTS.md GUIDING-PRINCIPLES.md README.md CLAUDE.md PROJECT/PDDA.md utils/pdda/PDDA-INSTALL.md; do
    73	  abs="$REPO/$doc"
    74	  if [ ! -f "$abs" ]; then
    75	    pass "A: $doc absent in this repo — skipped (CLAUDE.md is optional by design)"

2026-09-04T06:37:32.710343Z ERROR codex_models_manager::manager: failed to renew cache TTL: missing field `base_instructions` at line 94 column 5
exec
/bin/zsh -lc "rg -n -C 3 \"GH-414|#414|PR #427|comment-reference\" PROJECT test CHANGELOG.md README.md .github 2>/dev/null || true
nl -ba AGENTS.md | sed -n '150,220p'
nl -ba GUIDING-PRINCIPLES.md | sed -n '1,125p'" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-46123-z8dp_mu5
 succeeded in 0ms:
CHANGELOG.md-140-- **#131 — `--target-root` with a separate harness repo was a catch-22.** New `phase_commit_root()` routes the relay-file render and `ESCALATION.md` commits to the repo containing `phase_dir` — the TARGET under `--target-root` + a target `--phases-dir` (the layout relay-drive's containment advice prescribes), byte-identically `root` in every in-repo shape. The GH-514 write-set preflight probes each file against the repo that actually receives it. Transcripts deliberately stay with the harness root.
CHANGELOG.md-141-- **#139 — GH-460's SIGPIPE shape swept out of the suite.** 369 of 482 pipe-into-`grep -q` assertions converted to the capture-then-match form (`grep -q PAT <<<"$(producer)"` — the substitution completes before grep starts, so no reader can vanish under a writer); the 113 unconvertible-by-mechanical-pass sites (function bodies, grouped conditions, lookalike prose) are inventoried in a baseline that may only shrink, enforced by the new `gh139-pipe-grep-guard.sh` suite, which fails on any new occurrence. Two live flakes during this work confirmed the class again (a first-line `git log | grep -q` match in the new gh131 suite; gh322 on a pristine clone).
CHANGELOG.md-142-- **#140 — `datetime.utcnow()` deprecation warnings** no longer pollute captured driver output: the three sites (marathon transcript save, write-set probe, consult-verify archive day) now use timezone-aware `now(timezone.utc)` with byte-identical `strftime` output.
CHANGELOG.md:143:- **#138 — the post-#129 Bash/Python twin divergence is pinned at the divergence site** (`relay_drive.py`'s post-lock block, the `marathon_drive.py` GH-414 style), so a `XYZ_PYTHON=0` run is not misread as a regression.
CHANGELOG.md-144-
CHANGELOG.md-145-### Changed
CHANGELOG.md-146-- **#137 — the Wave-1 suites are registered in `validate.sh`'s TESTS array** (gh129/gh130/gh131, 40 assertions total, plus the gh139 guard) via the GH-124 wrapper pattern, so the push gate and CI execute them; previously nothing ran them after the lane landed.
--
test/marathon-drive.sh-1061-rm -rf "$A/.tick" "$A/phases" "$A/relay-system"
test/marathon-drive.sh-1062-git -C "$A" reset -q --hard "$INIT_HEAD" >/dev/null 2>&1 || true
test/marathon-drive.sh-1063-
test/marathon-drive.sh:1064:# ── (20) GH-414: Pi is routable as a BUILDER, and the Bash fallback is a known divergence ────────
test/marathon-drive.sh-1065-#
test/marathon-drive.sh-1066-# GH-295 shipped the Pi builder lane and GH-451/PR #452 wired `pi*` into the Python router — but no
test/marathon-drive.sh:1067:# case here ever named Pi, so the whole builder half was covered by nothing. #414 criterion 4 is
test/marathon-drive.sh-1068-# exactly this gap. Both halves below are asserted because one without the other is not a regression
test/marathon-drive.sh-1069-# test: (20a) alone cannot fail if routing silently regresses to the Bash driver, and (20b) alone
test/marathon-drive.sh-1070-# would pass on a tree where Pi does not work at all.
--
test/marathon-drive.sh-1080-  bash "$DRIVER" --phases-dir "$A/phases" --phase-brief "$BRIEF" --reviewer agy \
test/marathon-drive.sh-1081-    --pre-advance-cmd "true" --builder pi 2>&1)"; rc=$?
test/marathon-drive.sh-1082-[ "$rc" -eq 0 ] \
test/marathon-drive.sh:1083:  && pass "GH-414: --builder pi is accepted by the default (Python) router and completes a phase" \
test/marathon-drive.sh:1084:  || fail "GH-414: --builder pi exit=$rc: $PI_OUT"
test/marathon-drive.sh-1085-# The identity must reach the rendered relay file, not merely survive argument parsing — a router
test/marathon-drive.sh-1086-# that accepted `pi` and then dispatched someone else would still exit 0 above.
test/marathon-drive.sh-1087-grep -q "TAKE YOUR TURN.*pi.*BUILDER" "$A/phases/p1/RELAY.md" 2>/dev/null \
test/marathon-drive.sh:1088:  && pass "GH-414: the pi builder identity is what actually reaches the relay file" \
test/marathon-drive.sh:1089:  || fail "GH-414: expected pi as the BUILDER identity in the rendered relay file"
test/marathon-drive.sh-1090-
test/marathon-drive.sh-1091-# (20b) CONTROL — the frozen Bash twin does NOT know Pi, and that divergence is deliberate, not a
test/marathon-drive.sh-1092-# bug to be silently "fixed" here. relay-automation/marathon-drive.sh:779-783 routes
--
test/marathon-drive.sh-1102-  bash "$DRIVER" --phases-dir "$A/phases" --phase-brief "$BRIEF" --reviewer agy \
test/marathon-drive.sh-1103-    --pre-advance-cmd "true" --builder pi 2>&1)"; rc=$?
test/marathon-drive.sh-1104-[ "$rc" -ne 0 ] \
test/marathon-drive.sh:1105:  && pass "GH-414 control: the frozen Bash driver REJECTS --builder pi (divergence is real, not assumed)" \
test/marathon-drive.sh:1106:  || fail "GH-414 control: XYZ_PYTHON=0 accepted --builder pi — Bash gained Pi support; retire the divergence note"
test/marathon-drive.sh-1107-grep -q "must start with claude/codex/agy/aider" <<<"$(printf '%s' "$PI_BASH_OUT")" \
test/marathon-drive.sh:1108:  && pass "GH-414 control: the Bash rejection names the agent set that omits pi" \
test/marathon-drive.sh:1109:  || fail "GH-414 control: expected the claude/codex/agy/aider rejection message, got: $PI_BASH_OUT"
test/marathon-drive.sh-1110-rm -rf "$A/.tick" "$A/phases" "$A/relay-system"
test/marathon-drive.sh-1111-git -C "$A" reset -q --hard "$INIT_HEAD" >/dev/null 2>&1 || true
test/marathon-drive.sh-1112-
--
PROJECT/3-COMPLETED/GH-138-TWIN-DIVERGENCE-RECORD.md-12-risk: 1
PROJECT/3-COMPLETED/GH-138-TWIN-DIVERGENCE-RECORD.md-13-goal: >
PROJECT/3-COMPLETED/GH-138-TWIN-DIVERGENCE-RECORD.md-14-  Record the deliberate post-#129 divergence at the divergence site in relay_drive.py, in the
PROJECT/3-COMPLETED/GH-138-TWIN-DIVERGENCE-RECORD.md:15:  marathon_drive.py GH-414 style, so a XYZ_PYTHON=0 run is not misread as a regression.
PROJECT/3-COMPLETED/GH-138-TWIN-DIVERGENCE-RECORD.md-16----
PROJECT/3-COMPLETED/GH-138-TWIN-DIVERGENCE-RECORD.md-17-
PROJECT/3-COMPLETED/GH-138-TWIN-DIVERGENCE-RECORD.md-18-# GH-138: the twin-divergence record
--
PROJECT/3-COMPLETED/GH-138-TWIN-DIVERGENCE-RECORD.md-26-## Why
PROJECT/3-COMPLETED/GH-138-TWIN-DIVERGENCE-RECORD.md-27-
PROJECT/3-COMPLETED/GH-138-TWIN-DIVERGENCE-RECORD.md-28-Undocumented twin divergences generate false bug reports against the dead half (#379/#380); the
PROJECT/3-COMPLETED/GH-138-TWIN-DIVERGENCE-RECORD.md:29:repo's convention is to pin them at the divergence site (see `marathon_drive.py`'s GH-414 note).
PROJECT/3-COMPLETED/GH-138-TWIN-DIVERGENCE-RECORD.md-30-
PROJECT/3-COMPLETED/GH-138-TWIN-DIVERGENCE-RECORD.md-31-## Verification
PROJECT/3-COMPLETED/GH-138-TWIN-DIVERGENCE-RECORD.md-32-
--
PROJECT/2-WORKING/MARATHON-PLAN-2026-08-16.md-116-- #435 GH-435 · XYZ's coordination model is a sequential chain, not a DAG — `blocked`
PROJECT/2-WORKING/MARATHON-PLAN-2026-08-16.md-117-- #396 GH-396 · Accuracy Ledger — design constraints to settle before build — `blocked`
PROJECT/2-WORKING/MARATHON-PLAN-2026-08-16.md-118-- #378 GH-378 · a marathon can only run against a repo whose suite is already green — `blocked`
PROJECT/2-WORKING/MARATHON-PLAN-2026-08-16.md:119:- #414 GH-414 · --builder pi is rejected by the marathon router while the shim sits on disk, working — `blocked`
PROJECT/2-WORKING/MARATHON-PLAN-2026-08-16.md-120-- #392 GH-392 · the harness publishes no hardware requirement, so a 16 GB host gets no signal before a 7-lane wave — `blocked`
PROJECT/2-WORKING/MARATHON-PLAN-2026-08-16.md-121-- #391 GH-391 · nothing generates MARATHON.yaml, so every multi-phase run starts with an undocumented hand-authoring step — `blocked`
PROJECT/2-WORKING/MARATHON-PLAN-2026-08-16.md-122-- #383 GH-383 · the "pre-advance gate has no timeout" claim is STALE — the guard already bounds it — `blocked`
--
PROJECT/2-WORKING/MARATHON-PLAN-2026-09-03.md-27-
PROJECT/2-WORKING/MARATHON-PLAN-2026-09-03.md-28-| What was just completed | What's next |
PROJECT/2-WORKING/MARATHON-PLAN-2026-09-03.md-29-|---|---|
PROJECT/2-WORKING/MARATHON-PLAN-2026-09-03.md:30:| Generated by `utils/marathon-plan.sh` on 2026-09-03 from the live ROADMAP ledger (102 items; 8 active across 3 wave(s); 23 held). Drift present: yes — see Held/Flagged. | **Wave 1:** #414 ‖ #251 ‖ #415 ‖ #413 ‖ #411. Fire each lane via `swarm-preflight → marathon-drive`, scoped by `ALLOW_PATHS`. Re-run this script when the ledger changes. |
PROJECT/2-WORKING/MARATHON-PLAN-2026-09-03.md-31-
PROJECT/2-WORKING/MARATHON-PLAN-2026-09-03.md-32-## The one safety rule
PROJECT/2-WORKING/MARATHON-PLAN-2026-09-03.md-33-
--
PROJECT/2-WORKING/MARATHON-PLAN-2026-09-03.md-40-|---|---|---|
PROJECT/2-WORKING/MARATHON-PLAN-2026-09-03.md-41-| kernel | ❌ serialize — one at a time | #411, #412, #410 |
PROJECT/2-WORKING/MARATHON-PLAN-2026-09-03.md-42-| shim | ✅ one lane per file (serialize when inferred) | — |
PROJECT/2-WORKING/MARATHON-PLAN-2026-09-03.md:43:| independent | ✅ one lane per file | #414, #251, #415, #413, #269 |
PROJECT/2-WORKING/MARATHON-PLAN-2026-09-03.md-44-
PROJECT/2-WORKING/MARATHON-PLAN-2026-09-03.md-45-## Per-item scoring
PROJECT/2-WORKING/MARATHON-PLAN-2026-09-03.md-46-
--
PROJECT/2-WORKING/MARATHON-PLAN-2026-09-03.md-48-
PROJECT/2-WORKING/MARATHON-PLAN-2026-09-03.md-49-| Item | cx | risk | eff | zone | deps | score | wave |
PROJECT/2-WORKING/MARATHON-PLAN-2026-09-03.md-50-|---|---|---|---|---|---|---|---|
PROJECT/2-WORKING/MARATHON-PLAN-2026-09-03.md:51:| [#414] GH-414 · Nothing deterministic checks whether an inline code comment is still true — extend the dead-reference resolver past the doc boundary | 2 | 1 | 2 | independent | — | 8 | 1 |
PROJECT/2-WORKING/MARATHON-PLAN-2026-09-03.md-52-| [#251] GH-251 · validate.sh miscounts an absent pytest as FAILED | 2 | 2 | 2 | independent | — | 10 | 1 |
PROJECT/2-WORKING/MARATHON-PLAN-2026-09-03.md-53-| [#415] GH-415 · The skill-first guard hook covers 6 of 12 Tier-A entrypoints — derive the set from AGENTS.md instead of hardcoding it | 2 | 2 | 2 | independent | — | 10 | 1 |
PROJECT/2-WORKING/MARATHON-PLAN-2026-09-03.md-54-| [#413] GH-413 · The launch-artifact marker authorises a destructive rebuild of any directory — marker alone, no git history required | 1 | 4 | 1 | independent | — | 11 | 1 |
--
PROJECT/2-WORKING/MARATHON-PLAN-2026-09-03.md-61-
PROJECT/2-WORKING/MARATHON-PLAN-2026-09-03.md-62-## Recommended waves
PROJECT/2-WORKING/MARATHON-PLAN-2026-09-03.md-63-
PROJECT/2-WORKING/MARATHON-PLAN-2026-09-03.md:64:**Wave 1:** #414 ‖ #251 ‖ #415 ‖ #413 ‖ #411
PROJECT/2-WORKING/MARATHON-PLAN-2026-09-03.md-65-
PROJECT/2-WORKING/MARATHON-PLAN-2026-09-03.md:66:- #414 → suggested_branch: `marathon/gh-414-comment-reference-check-2026-09-03`
PROJECT/2-WORKING/MARATHON-PLAN-2026-09-03.md-67-- #251 → suggested_branch: `marathon/gh-251-validate-pytest-skip-2026-09-03`
PROJECT/2-WORKING/MARATHON-PLAN-2026-09-03.md-68-- #415 → suggested_branch: `marathon/gh-415-guard-hook-derive-entrypoints-2026-09-03`
PROJECT/2-WORKING/MARATHON-PLAN-2026-09-03.md-69-- #413 → suggested_branch: `marathon/gh-413-launch-artifact-marker-destruction-2026-09-03`
--
PROJECT/2-WORKING/MARATHON-PLAN-2026-09-03.md-85-`CONTRACT.md` for the seam and point **each** lane's prompt at it (code TO the contract, not to
PROJECT/2-WORKING/MARATHON-PLAN-2026-09-03.md-86-the other lane's source), or the split can stall when the consumer waits on the producer's handoff.
PROJECT/2-WORKING/MARATHON-PLAN-2026-09-03.md-87-
PROJECT/2-WORKING/MARATHON-PLAN-2026-09-03.md:88:- **Wave 1:** #414 ‖ #415 share `test/baselines/` → pin a contract for that seam.
PROJECT/2-WORKING/MARATHON-PLAN-2026-09-03.md:89:- **Wave 1:** #414 ‖ #413 share `test/baselines/` → pin a contract for that seam.
PROJECT/2-WORKING/MARATHON-PLAN-2026-09-03.md:90:- **Wave 1:** #414 ‖ #411 share `test/baselines/` → pin a contract for that seam.
PROJECT/2-WORKING/MARATHON-PLAN-2026-09-03.md-91-- **Wave 1:** #415 ‖ #413 share `test/baselines/` → pin a contract for that seam.
PROJECT/2-WORKING/MARATHON-PLAN-2026-09-03.md-92-- **Wave 1:** #415 ‖ #411 share `test/baselines/` → pin a contract for that seam.
PROJECT/2-WORKING/MARATHON-PLAN-2026-09-03.md-93-- **Wave 1:** #413 ‖ #411 share `test/baselines/` → pin a contract for that seam.
--
PROJECT/1-INBOX/GH-425-GATE-PROVENANCE-CHECK.md-17-related:
PROJECT/1-INBOX/GH-425-GATE-PROVENANCE-CHECK.md-18-  - GH-421 (Phase 2 may not pass --gate until this lands)
PROJECT/1-INBOX/GH-425-GATE-PROVENANCE-CHECK.md-19-  - GH-406 (the external review that catalogued this defect class)
PROJECT/1-INBOX/GH-425-GATE-PROVENANCE-CHECK.md:20:  - GH-414 (nothing deterministic checks whether a claim in a comment is still true)
PROJECT/1-INBOX/GH-425-GATE-PROVENANCE-CHECK.md-21-goal: >
PROJECT/1-INBOX/GH-425-GATE-PROVENANCE-CHECK.md-22-  Make --gate verify what its message claims — that a provenance receipt exists for THIS PR — or
PROJECT/1-INBOX/GH-425-GATE-PROVENANCE-CHECK.md-23-  remove the flag. A gate that cannot fail is worse than no gate, because it gets cited as evidence.
--
PROJECT/1-INBOX/GH-414-COMMENT-REFERENCE-CHECK.md-23-  gate instead of staying green forever.
PROJECT/1-INBOX/GH-414-COMMENT-REFERENCE-CHECK.md-24----
PROJECT/1-INBOX/GH-414-COMMENT-REFERENCE-CHECK.md-25-
PROJECT/1-INBOX/GH-414-COMMENT-REFERENCE-CHECK.md:26:# GH-414: comment references are unchecked
PROJECT/1-INBOX/GH-414-COMMENT-REFERENCE-CHECK.md-27-
PROJECT/1-INBOX/GH-414-COMMENT-REFERENCE-CHECK.md-28-> **1-INBOX capture**, not an active-work doc. On promotion, create the status table.
PROJECT/1-INBOX/GH-414-COMMENT-REFERENCE-CHECK.md-29-
--
PROJECT/1-INBOX/GH-414-COMMENT-REFERENCE-CHECK.md-63-  "fix_probes":  [ { "type": "grep_absent", "path": "utils/pdda/pdda.sh", "pattern": "comment_reference" } ],
PROJECT/1-INBOX/GH-414-COMMENT-REFERENCE-CHECK.md-64-  "artifacts":   [
PROJECT/1-INBOX/GH-414-COMMENT-REFERENCE-CHECK.md-65-    "utils/pdda/pdda.sh",
PROJECT/1-INBOX/GH-414-COMMENT-REFERENCE-CHECK.md:66:    "test/gh414-comment-reference-check.sh",
PROJECT/1-INBOX/GH-414-COMMENT-REFERENCE-CHECK.md:67:    "test/baselines/GH-414-negative-control.md"
PROJECT/1-INBOX/GH-414-COMMENT-REFERENCE-CHECK.md-68-  ],
PROJECT/1-INBOX/GH-414-COMMENT-REFERENCE-CHECK.md:69:  "remediation": { "source": "issue#414", "criteria": "a source comment citing a non-existent path fails the check, and the check runs against the built artifact as well as the source tree" },
PROJECT/1-INBOX/GH-414-COMMENT-REFERENCE-CHECK.md-70-  "lanes":       { "agy_safe": [], "orchestrator_only": [] }
PROJECT/1-INBOX/GH-414-COMMENT-REFERENCE-CHECK.md-71-}
PROJECT/1-INBOX/GH-414-COMMENT-REFERENCE-CHECK.md-72-```
--
PROJECT/1-INBOX/GH-416-DOC-TRUES-UP-BATCH.md-16-  - Renumbering any GH reference. Upstream numbers are mirrored, not rewritten.
PROJECT/1-INBOX/GH-416-DOC-TRUES-UP-BATCH.md-17-related:
PROJECT/1-INBOX/GH-416-DOC-TRUES-UP-BATCH.md-18-  - GH-406 (umbrella — external review by Russ K.)
PROJECT/1-INBOX/GH-416-DOC-TRUES-UP-BATCH.md:19:  - GH-414 (the dead-reference class this batch's items 2 and 4 belong to)
PROJECT/1-INBOX/GH-416-DOC-TRUES-UP-BATCH.md-20-goal: >
PROJECT/1-INBOX/GH-416-DOC-TRUES-UP-BATCH.md-21-  Make four documents literally true of the tree: §7's no-dependencies claim, the README's
PROJECT/1-INBOX/GH-416-DOC-TRUES-UP-BATCH.md-22-  PROJECT/4-MISC references, SKILL.md's CODEX_FLAGS default and its no-op escalation rung, and
   150	     correct state is idle**. Say so plainly and do the smaller work; an idle gap is honest signal,
   151	     a fabricated marathon is noise that costs real tokens.
   152	  4. **The point is the failures.** A marathon that completes cleanly and teaches nothing is a
   153	     weaker result than one that escalates and names a defect. Report what broke; do not smooth it.
   154	
   155	- **The RELEASES DB is two subsystems behind one CLI** (`utils/py/releases_app.py`): the GH-32
   156	  release ledger and the roadmap ledger (`roadmap_items`). Since the `ROADMAP_SOURCE=releases`
   157	  flip (GH-169/GH-238/GH-243) the DB is the roadmap's source of truth in THIS repo: park intake
   158	  with `releases roadmap add` (or `hq park`), read with `roadmap list` / `ROADMAP-DASHBOARD.md`,
   159	  and never edit `ROADMAP.md` (frozen legacy). `roadmap sync` is for legacy-mode repos only and
   160	  no-ops here — it mirrors markdown and would delete `add`-parked rows. Never hand-edit
   161	  `releases.sql` or `releases.db`. Merge conflicts on the dump have a one-command resolver
   162	  (`utils/releases-merge-resolve.sh`). The whole contract, including what a real merge conflict
   163	  looks like: [RELEASES-DB-FAQS.md](RELEASES-DB-FAQS.md).
   164	
   165	- **The local gate runs at the push boundary; hosted CI independently attests public-repo changes
   166	  (GH-544, XYZ-forge #16).** The private-phase bridge ended when this repository became public on
   167	  2026-08-15. `.github/workflows/ci.yml` now covers `push`/`pull_request` on `main` and `development`;
   168	  the macOS promotion boundary remains restricted to a push on `main`, while the Ubuntu job is an
   169	  advisory portability canary. Local commits are ungated on purpose; pushes are still gated by
   170	  `githooks/pre-push` so failures are caught before the remote round trip.
   171	  - Wire a new clone once: `bash githooks/install.sh` (idempotent). It installs a dispatch stub into
   172	    `.git/hooks/`, which covers **every branch and linked worktree** of that clone, including branches
   173	    with no `githooks/` directory (GH-549 — the first design wired `core.hooksPath` at the in-tree
   174	    directory, and git skips a hook path that does not resolve *in total silence*). **The wiring is
   175	    still per clone and does not travel** — a fresh clone or second machine has NO gate until this
   176	    runs. Check with `bash githooks/install.sh --check`.
   177	  - `./validate.sh` is **parallel by default** (~4–6 min at the GH-35 balanced width of cores/2 capped 4; `--burst`
   178	  restores the old full-core width), auto-sized to the host, and announces a
   179	    sequential fallback with its reason. `bash ci-local.sh` is still the qualifying run that writes
   180	    the evidence record — it stays sequential and does not call `validate.sh`.
   181	  - Bypasses are `git push --no-verify` and `XYZ_SKIP_PREPUSH=1`. Both announce themselves. Use them
   182	    deliberately, not reflexively — they skip the local boundary even when hosted CI later runs.
   183	  - **PR checks are meaningful again only after a hosted run actually appears for the commit.** A
   184	    configured workflow is not evidence; query the run and cite its SHA.
   185	
   186	- **Never use a git command that overwrites the working tree from a committed state to undo a
   187	  working-tree experiment.** In this clone other agents hold uncommitted work you cannot see.
   188	  Three spellings destroyed peer work three times in one session (GH-527) and the common factor
   189	  is not obvious from any one of them:
   190	  - `git reset --hard <anything>`
   191	  - `git checkout -- <path>` (restores **HEAD**, not the state before your edit)
   192	  - tree-wide `git stash` (and it may time out before its `pop`)
   193	
   194	  To undo your own experiment, copy the file first (`cp f f.bak`) and restore from that. The
   195	  blast radius is **tracked** modifications; untracked files survive. `relay-automation/hooks/gh527-destructive-git-guard.sh`
   196	  snapshots the doomed tracked files into `.tick/orphan-backups/` before the command runs, so
   197	  this is recoverable rather than prevented — the snapshot is a net, not permission to swing.
   198	- **Preflight sandboxed branch mutations (GH-50).** A sandbox may let `git switch --track` rewrite
   199	  the index and working tree, then deny the `.git/config` lock and leave HEAD on the old branch.
   200	  Before a harness runs a tracking switch or destructive branch mutation such as `git branch -D`,
   201	  wrap the complete command with `utils/git-sandbox-guard.sh --repo <root> -- <git command>` so it
   202	  refuses before mutation when the config cannot be written. Never truncate git stderr for branch
   203	  operations: the decisive `could not lock config file` line can otherwise disappear behind an
   204	  unrelated upstream hint.
   205	- `ROUTER.md` owns startup order, canonical files, command rails, and the issue-first SOP.
   206	- `GUIDING-PRINCIPLES.md` owns the product/runtime priorities: local event-log coordination,
   207	  containment, skill-first relay work, durable fixes, and verified done.
   208	- `PROJECT/PDDA.md` owns doc lifecycle, `ROADMAP.md` pointer-ledger rules, and `CHANGELOG.md`
   209	  governance.
   210	- Before approving a PDDA dependency sync, follow the repo-owned
   211	  [PDDA sync review policy](PROJECT/PDDA-SYNC-POLICY.md); a green suite after fixups does not by
   212	  itself establish that deleted local behaviour was safe to remove.
   213	- `validate.sh` is the code/runtime gate. `utils/pdda/pdda.sh run` and its targeted
   214	  `utils/pdda/pdda.sh <check>` subcommands are the doc-hygiene gates.
   215	- **Scratch and temporary files go in `temp/`, never the repo root.** `/temp/` is already gitignored
   216	  (`.gitignore:13`). Probes, reproduction scripts, one-off analysis, captured command output,
   217	  half-written notes — anything you would not put in a commit — belongs there or outside the repo
   218	  entirely. **Do not create `scratch-*.md`, `notes-*.md`, `*.tmp` or similar at the repo root.**
   219	
   220	  This is a housekeeping rule with a real failure mode behind it, which is why it is a rail and not a
     1	# Guiding Principles
     2	
     3	North star for **xyz-3-agents-swarm**, the multi-agent coordination harness behind the `tick` event-log kernel and `relay-automation/` relay stack. When a choice is unclear, the option that keeps agents synchronized, contained, and verifiable — without leaking or destroying work — wins. AGENTS.md is the behavioral playbook; ROUTER.md is the entry-point map; this is the *why*.
     4	
     5	## The North Star
     6	
     7	There is no perfect architecture and no finished codebase. The bar is not perfection — it is that
     8	every change leaves the harness **more durable, more reversible, and less duplicated** than it found
     9	it, and that the three stay in balance:
    10	
    11	- **Durable** — it removes the root cause and the next planned change builds on it, rather than being
    12	  torn out when the obvious next feature lands.
    13	- **Reversible** — the cost of being wrong is known and bounded before the change lands. A change
    14	  nobody can undo is a bet, not a fix, and gets treated as one.
    15	- **DRY** — nothing canonical lives in two places where it can drift. One source of truth, and every
    16	  other surface is a pointer or a projection of it.
    17	
    18	**Do not build a new layer, module, or sub-system when an existing piece of code can be extended
    19	easily, logically, and safely.** Extending an existing abstraction beats standing up a parallel,
    20	siloed system, even when the parallel path is faster to write today — the parallel path is what
    21	later has to be kept in sync, and what silently drifts when it isn't. If the existing abstraction
    22	genuinely cannot carry the new case, say so in one line, with the reason, before forking.
    23	
    24	These three pull against each other, and that tension is the decision, not a problem to average
    25	away: the most durable fix is often the least reversible, and collapsing two near-duplicates is a
    26	DRY win that can widen the blast radius. Name the trade and pick; do not split the difference by
    27	building both.
    28	
    29	This section is canonical. `AGENTS.md` owns how it is applied to a given change — the reversibility
    30	scale (§3) and blast-radius sizing (§4) — and principles 6, 7, and 10 below are the build-time and
    31	done-time expressions of it. Where another doc restates this, that doc is the copy and this is the
    32	original.
    33	
    34	## Purpose
    35	
    36	`tick` coordinates Claude Code, Codex, and agy (Antigravity CLI) on the same branch without collision: a shared local event log under `.tick/events/`, claims serialized by `O_EXCL` locks, and a `Marathon` harness that chains multi-phase build→review cycles from a `MARATHON.yaml`. The relay layer (`relay-automation/`) drives headless turns, isolates agent writes to worktrees, and enforces an allowlist so no headless agent destroys work it didn't intend to touch. The goal: a multi-agent swarm safe enough to run against a real external codebase and correct enough that its output is worth shipping.
    37	
    38	## The quality bar
    39	
    40	Every agent turn is a signal. A turn is high-quality only when it is all four:
    41	
    42	- **Attested** — carries its receipts: source, evidence, confidence. Never a bare verdict. A relay review names which claim is wrong and why; a build turn names the seam it touched.
    43	- **Relevant** — ranked, not dumped. Volume is not value. One real bug beats five nits and a phantom.
    44	- **Fresh** — current, not stale. A turn that reads a stale `STATE.md` or misses an epoch fence is wrong by construction.
    45	- **Structured** — one shape, clean for the operator to read and for downstream agents to feed on.
    46	
    47	Fail a pillar, and the turn, feature, or relay review isn't done.
    48	
    49	## How it's built
    50	
    51	1. **Coordination is local-transport only.** `.tick/events/` is the shared bus; claims resolve from there, not from a remote. No per-event push/fetch; no remote dependency at runtime. A coordination primitive that reaches out is a coordination primitive that can fail or leak.
    52	
    53	2. **One canonical event log; every surface is a projection.** `tick` accretes events; `STATE.md` is the current projection. Reads go through the projection; writes go through a `claim/take/scope/done` verb. Nothing canonical lives in two places where it can drift. An agent that hard-codes state outside `.tick/` is creating drift.
    54	
    55	3. **Containment is non-negotiable.** A headless turn must not: self-commit mid-turn, orphan a peer's concurrent commit, or write outside its allowlist. The allowlist, worktree isolation, and commit-bypass guard exist because a driven agent will do all three if unconstrained — not hypothetically, but as documented live incidents (GH-13, GH-14, GH-17). New relay paths must clear the containment bar before they ship.
    56	
    57	4. **Skill-first; never improvise the harness.** The `relay-xyz` skill owns the locator, sandbox rules, exit codes, and the safety boundary. A session that improvises those from `ls relay-automation/` silently skips the skill's safety layer. The `PreToolUse` guard (`relay-automation/hooks/relay-xyz-guard.sh`) enforces this by blocking driver calls before the skill loads. Add capabilities to the skill; do not work around it.
    58	
    59	5. **Adversarially proven before commercially viable.** The harness exists to run against real codebases. Features in the adversarial-hardening track (epoch fencing, chaos suite, cross-repo E2E) must be verified to survive deliberate abuse — stale writers, zombie claims, macOS case-sensitivity, concurrent peer commits — not just the happy path. A feature that clears the happy path and skips chaos is half-done.
    60	
    61	6. **Build durable, not band-aid.** Durable means it removes the root cause and the next planned change builds on it — not a patch torn out when the obvious next feature lands. A band-aid is wasted work unless a demo strictly needs one, and a demo band-aid is tagged for removal so it isn't silently inherited.
    62	
    63	7. **Least code that clears the bar.** Node standard library only — no deps, no lockfile; the repo ships no root manifest. Prefer reusing or extending what exists; the smallest change that stays correct, contained, and durable wins. Net-new code is a cost to justify. Deleting code counts as progress.
    64	
    65	8. **Honest; the operator decides.** Surface what failed and why — never mask a stall as success or an escalation as a stall. A headless turn self-repairs within a bounded exit-code menu (`exit 3` stall, `exit 4` escalated-by-design, `exit 6` containment revert), then stops; it never loops forever or silently swallows an error. Destructive actions require explicit authorization.
    66	
    67	9. **Docs are resumable runtime state (PDDA).** Agent work is stoppable, resumable, and handed off from `PROJECT/**` alone — ROUTER points, project docs hold detail, CHANGELOG logs dated outcomes. ROADMAP.md is a pointer/ledger only; execution detail lives in the linked `PROJECT/**` doc. If reality and the docs disagree, the docs are the bug.
    68	
    69	10. **Done means verified.** "Done" is `validate.sh` green, the relevant PDDA checks passing, and any relay review returning `Approved` — not work that looks finished. An unverified success claim is itself a low-quality signal.
    70	
    71	11. **Issue-first; every non-trivial change has a signal stream.** Any change beyond a 2–3 line fix opens a GitHub issue first, then gets a `GH-<number>` in-repo pointer doc, then lands. The issue is the machine-queryable signal stream; the `PROJECT/**` doc is the execution surface of record. Genuinely trivial edits (≤2–3 line fixes, typos, path repoints, doc-only one-liners) are exempt.
    72	
    73	12. **Independent Verification (Separated Grading)** — The agent that produces a turn must not be the sole grader of its own quality. Verification must be performed by an independent deterministic check or a separate reviewing agent before the lock releases. Applies to: the relay's structural block validator (`bin/validate-relay-block` — Phase 1 of GH-21), consult-verify diversity (Phase 3), and any other post-generation quality gate.
    74	
    75	13. **A green gate without a witnessed red control is not evidence.** Every new or materially changed decision gate ships a recorded demonstration that it fails for the right reason: a pre-fix replay, deliberate mutation, or controlled bad fixture. Do not mistake a check that validates the artifact it just generated (#351) or a parity check that compares a lane to itself (#348) for evidence; both shapes are structurally unable to falsify their claim.
    76	
    77	## Applying this
    78	
    79	Adding a feature or weighing a tradeoff, ask: *does this keep agents coordinated without collision, contained within their scope, and verifiable to an outside observer? And is "done" provable by running `validate.sh`?* If any answer is no, reconsider.
    80	
    81	---
    82	
    83	## Conventions
    84	
    85	### Strict-mode policy (bash `set -e`)
    86	
    87	Strict mode is **per-subsystem, not repo-wide** (GH-110 P3b). The split is deliberate:
    88	
    89	- **`relay-automation/` drivers and turn shims run `set -euo pipefail`.** They orchestrate risky,
    90	  multi-step, containment-sensitive turns where a silently-ignored failure can commit off-lane or
    91	  orphan a peer. Abort-on-error (`-e`) is the correct default there.
    92	- **`utils/` analysis tools (`pdda/*`, `marathon-plan.sh`, `swarm-preflight.sh`) run `set -uo pipefail`
    93	  or `set -u`, deliberately *without* `-e`.** These are long single-pass scripts whose normal control
    94	  flow includes many expected-nonzero probes (`git rev-parse`, `gh` lookups, `grep` misses). Under
    95	  `-e` a benign "no match" would abort the whole run, so they set `-u` (catch unset vars) + explicit
    96	  per-call error handling instead. This is an exemption, not an oversight.
    97	
    98	Every currently `-e`-exempt script carries a one-line `# strict-mode: -e exempt — …` header next to
    99	its `set -` line so the exemption is self-documenting. New scripts default to `set -euo pipefail`
   100	unless they fit the analysis-tool profile above, in which case they add the exemption header.
   101	
   102	### Tool install paths — never inside another app's folder (GH-347)
   103	
   104	**This harness's tool binaries never live inside another application's private directory.** Not the
   105	worker CLIs (`codex`, `agy`, `pi`, `aider`), not `tick`, not anything the harness shells out to.
   106	
   107	The failure mode is specific and quiet: a foreign app owns its own directory, so its next update or
   108	reinstall deletes our dependency with it — on that app's schedule, with no signal we control. Worse, the
   109	readiness check cannot tell the two apart. `find-harness.sh --check` tests only whether a worker is *on
   110	PATH*, so "the neighbouring app just wiped our tool" and "never installed" produce the byte-identical
   111	line. That is the same disease as GH-315/GH-319: a broken observation layer where failure is invisible
   112	and every available signal agrees.
   113	
   114	**The `npm install -g` trap — this is how GH-347 actually happened.** npm derives its global prefix from
   115	whichever `npm` is on PATH, so a bare `npm install -g <pkg>` inherits a foreign app's runtime silently
   116	and exits 0. On the machine that filed GH-347, another agent app had symlinked its bundled Node onto PATH
   117	(`~/.local/bin/npm -> ~/.hermes/node/bin/npm`) with no `~/.npmrc` involved at all, so `pi` installed into
   118	that app's folder and — because only `node`/`npm` were symlinked out, not `pi` — was invisible to every
   119	shell while being perfectly functional. **Run `npm config get prefix` before any global install and
   120	confirm it is a path this repo's tooling owns.** Never assume.
   121	
   122	The positive pattern is already on disk in the two lanes that have never had this problem: a tool's own
   123	app directory with a symlink onto PATH (`~/.local/bin/codex -> ~/.codex/packages/…/bin/codex`), or a real
   124	binary in a shared user-local `bin`. Either is fine. Someone else's runtime is not.
   125	

2026-09-04T06:37:38.510412Z ERROR codex_models_manager::manager: failed to renew cache TTL: missing field `base_instructions` at line 94 column 5
exec
/bin/zsh -lc "nl -ba PROJECT/1-INBOX/GH-414-COMMENT-REFERENCE-CHECK.md | sed -n '1,110p'
nl -ba PROJECT/2-WORKING/MARATHON-PLAN-2026-09-03.md | sed -n '24,70p'
nl -ba AGENTS.md | sed -n '290,344p'" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-46123-z8dp_mu5
 succeeded in 0ms:
     1	---
     2	title: Nothing deterministic checks whether an inline code comment is still true — extend the dead-reference resolver past the doc boundary
     3	status: Proposed (1-INBOX — not yet active)
     4	created: 2026-09-03
     5	owner: noelsaw1
     6	gh_issue: 414
     7	source: https://github.com/HiQS-Labs/XYZ-forge/issues/414
     8	doc_type: feature
     9	complexity: 2
    10	risk: 1
    11	effort: 2
    12	phases: 2
    13	ratings_provisional: true
    14	non_goals:
    15	  - Detecting semantic comment-vs-code drift. This verifies that references RESOLVE, nothing more.
    16	  - Building a new checker; the dead-reference resolver already exists and is scoped to markdown.
    17	related:
    18	  - GH-406 (umbrella — external review by Russ K.)
    19	  - GH-413 (adds the two dropped ADRs to KEEP_FILES; this catches the class permanently)
    20	goal: >
    21	  Extend pdda-check-governance's dead-reference resolver to source comments and run it against
    22	  the built artifact as well as the source tree, so a kernel comment citing an absent ADR fails a
    23	  gate instead of staying green forever.
    24	---
    25	
    26	# GH-414: comment references are unchecked
    27	
    28	> **1-INBOX capture**, not an active-work doc. On promotion, create the status table.
    29	
    30	## Why this is worth more than the nit that produced it
    31	
    32	Russ K. asked whether anything catches comment rot. It does not — it is culture and review. His
    33	finding 1.5 (`src/events.js:8`, `:36`, `src/project.js:59` cite two ADRs the build drops) is not
    34	one broken link; it is proof that the repo's best documentation has **zero** deterministic
    35	protection. Fix 1.5 by hand and it silently regrows.
    36	
    37	## The check already half exists
    38	
    39	A live PDDA run at HEAD emits three markdown dead-reference warnings from `README.md`. So the
    40	resolver works — it stops at the document boundary. Pointing it at source comments is closer to a
    41	configuration change than a new check, which makes the highest-leverage umbrella item one of the
    42	cheapest.
    43	
    44	Second-order finding: those markdown warnings have been in the stream long enough to appear in an
    45	external review. **A warning nobody acts on is functionally not a check** — so triaging the
    46	existing stream is in scope, not just adding to it.
    47	
    48	## Phases
    49	
    50	1. Extend the resolver to path-shaped references in source comments; run against both trees. The
    51	   public-tree run is the one that catches 1.5, since the defect is created by the build's
    52	   `decisions` drop rather than by the source.
    53	2. Triage the existing markdown warning stream to zero or explicit acceptances.
    54	
    55	Red control: the two ADR citations in `src/events.js` fail pre-fix.
    56	
    57	## Swarm Preflight Contract
    58	
    59	```json
    60	{
    61	  "target":      { "repo": ".", "ref": "development" },
    62	  "gate":        "bash validate.sh",
    63	  "fix_probes":  [ { "type": "grep_absent", "path": "utils/pdda/pdda.sh", "pattern": "comment_reference" } ],
    64	  "artifacts":   [
    65	    "utils/pdda/pdda.sh",
    66	    "test/gh414-comment-reference-check.sh",
    67	    "test/baselines/GH-414-negative-control.md"
    68	  ],
    69	  "remediation": { "source": "issue#414", "criteria": "a source comment citing a non-existent path fails the check, and the check runs against the built artifact as well as the source tree" },
    70	  "lanes":       { "agy_safe": [], "orchestrator_only": [] }
    71	}
    72	```
    24	> detail still lives in each `PROJECT/**` doc — this is a scheduling overlay.
    25	
    26	## Status
    27	
    28	| What was just completed | What's next |
    29	|---|---|
    30	| Generated by `utils/marathon-plan.sh` on 2026-09-03 from the live ROADMAP ledger (102 items; 8 active across 3 wave(s); 23 held). Drift present: yes — see Held/Flagged. | **Wave 1:** #414 ‖ #251 ‖ #415 ‖ #413 ‖ #411. Fire each lane via `swarm-preflight → marathon-drive`, scoped by `ALLOW_PATHS`. Re-run this script when the ledger changes. |
    31	
    32	## The one safety rule
    33	
    34	Two lanes are safe to run concurrently **iff their write-sets are disjoint** and their zone
    35	caps are respected. Current caps: kernel≤1/wave.
    36	
    37	## Collision map
    38	
    39	| Zone | Parallel-safe? | Active items here |
    40	|---|---|---|
    41	| kernel | ❌ serialize — one at a time | #411, #412, #410 |
    42	| shim | ✅ one lane per file (serialize when inferred) | — |
    43	| independent | ✅ one lane per file | #414, #251, #415, #413, #269 |
    44	
    45	## Per-item scoring
    46	
    47	Every input is shown so the ordering is verifiable by hand (lower score = earlier).
    48	
    49	| Item | cx | risk | eff | zone | deps | score | wave |
    50	|---|---|---|---|---|---|---|---|
    51	| [#414] GH-414 · Nothing deterministic checks whether an inline code comment is still true — extend the dead-reference resolver past the doc boundary | 2 | 1 | 2 | independent | — | 8 | 1 |
    52	| [#251] GH-251 · validate.sh miscounts an absent pytest as FAILED | 2 | 2 | 2 | independent | — | 10 | 1 |
    53	| [#415] GH-415 · The skill-first guard hook covers 6 of 12 Tier-A entrypoints — derive the set from AGENTS.md instead of hardcoding it | 2 | 2 | 2 | independent | — | 10 | 1 |
    54	| [#413] GH-413 · The launch-artifact marker authorises a destructive rebuild of any directory — marker alone, no git history required | 1 | 4 | 1 | independent | — | 11 | 1 |
    55	| [#411] GH-411 · tick log is exempt from the foreign-cwd guard — the verb that seeds every run, plus the whole marathon namespace | 2 | 2 | 2 | kernel | — | 12 | 1 |
    56	| [#412] GH-412 · A transient O_EXCL claim collision exits 1, identical to a durable loss — no retry channel under marathon load | 2 | 3 | 3 | kernel | — | 16 | 2 |
    57	| [#269] GH-269 · full switchover to Releases DB — retire ROADMAP.md | 4 | 3 | 3 | independent | — | 16 | 2 |
    58	| [#410] GH-410 · The structural relay-block validator never runs on the driven path, and rejects the bold STATUS format real threads write | 3 | 3 | 3 | kernel | — | 17 | 3 |
    59	
    60	`*` = zone inferred from keywords (no preflight contract write-set to prove it).
    61	
    62	## Recommended waves
    63	
    64	**Wave 1:** #414 ‖ #251 ‖ #415 ‖ #413 ‖ #411
    65	
    66	- #414 → suggested_branch: `marathon/gh-414-comment-reference-check-2026-09-03`
    67	- #251 → suggested_branch: `marathon/gh-251-validate-pytest-skip-2026-09-03`
    68	- #415 → suggested_branch: `marathon/gh-415-guard-hook-derive-entrypoints-2026-09-03`
    69	- #413 → suggested_branch: `marathon/gh-413-launch-artifact-marker-destruction-2026-09-03`
    70	- #411 → suggested_branch: `marathon/gh-411-tick-log-foreign-cwd-guard-2026-09-03`
   290	  another repo's docs. Full command surface (`status`/`resolve`/`next`/`park`/`promote`/`queue`/`fire`),
   291	  install, and the resolution ladder are in [README.md → HQ — multi-repo command center](README.md#hq--multi-repo-command-center); agent-facing invocation flow + guardrails live in [skills/hq/SKILL.md](skills/hq/SKILL.md). Write paths preview by default; `fire` never drives the harness.
   292	- Changes to `.tick/events/`, `src/project.js`, relay containment, or event/verb shape are usually
   293	  broader than they look. Treat them as at least Costly until proven otherwise.
   294	- **Contain tree-touching subagents with `isolation: "worktree"` (GH-177/GH-233).** A Claude Code
   295	  session spawning Agent/Workflow subagents that will *modify files* in this repo should pass
   296	  `isolation: "worktree"` so a runaway destructive command shreds a disposable checkout, not the main
   297	  tree (this repo has been wiped twice — see
   298	  `PROJECT/3-COMPLETED/GH-177-MKTEMP-TRAP-REPO-WIPE.md`). Know what it does NOT protect: worktrees
   299	  share `.git` objects/refs, so destructive *git* operations (`update-ref`, `branch -D`, resets,
   300	  force-push) still hit the real repo — a worktree-isolated agent once reset ROOT HEAD via
   301	  `rtl_enforce`'s commit-bypass guard. Harness-driven codex/agy lanes are covered by
   302	  `rtl_worktree_begin` instead and don't need the flag. Known frictions: `--require-clean` self-trips
   303	  on the driver's own lock dir inside a linked worktree, and untracked artifacts are invisible to a
   304	  worktree checkout — commit review inputs first. Read-only subagents (Explore, audits) don't need
   305	  isolation. Related guards: never execute `validate.sh`/`test/*.sh` under a sandboxed Bash call
   306	  (enforced by `relay-automation/hooks/gh177-sandbox-test-guard.sh` — re-run it un-sandboxed; do NOT
   307	  push it to CI to be exercised, see the CI rail below), and `test/mktemp-trap-guard.sh` statically
   308	  outlaws the wipe idiom repo-wide. **The "what it does NOT protect" list above is narrower than
   309	  reality — see the next rail (GH-564): a worktree isolates the working tree only, and everything
   310	  under `.git` is shared, which is why running the suite in one contaminated the parent clone twice.**
   311	- **Run the suite in a SEPARATE FULL CLONE, never in a clone whose state you care about — and a
   312	  linked worktree is NOT a way around it (GH-564).** `validate.sh` and `test/*.sh` can write to the
   313	  git config, remotes, and refs of the repository they are invoked from. On 2026-08-15 the primary
   314	  clone was contaminated **twice in one morning**: `core.bare=true`, `remote.origin.url` repointed at
   315	  a fixture bare repo, a fixture `[user]` identity appended, and `refs/heads/development` reset onto
   316	  ~35 fixture commits. It also **defeated the push gate while corrupting it** — pushes failed with
   317	  `'/var/folders/…/bare.XXXXXX' does not appear to be a git repository` because the suite repointed
   318	  `origin` mid-hook.
   319	  - **The worktree precaution was taken and it FAILED.** Both bursts came from `./validate.sh` run in
   320	    linked worktrees cut off the primary clone, chosen specifically to isolate the risk. **Linked
   321	    worktrees share `.git/config` with the parent clone**, so an escape landing in a worktree's CWD
   322	    writes the parent's config. Reproduced deterministically: from a worktree CWD, `r=""; git -C "$r"
   323	    remote set-url origin "$b"` rewrote the *parent* clone's origin. Same structural fact the
   324	    driver-lock matrix documents from the other side (GH-42/GH-354/GH-448) — a linked worktree
   325	    resolves to the parent's `git-common-dir`, which is why it grants no second lane either.
   326	  - **State the boundary precisely, because the previous rail's version was too narrow.** The rail
   327	    above says worktree isolation does not protect against destructive *git operations*. That is
   328	    true and insufficient: a worktree isolates the **working tree only**. Everything reached through
   329	    `.git` — config, remotes, refs, objects, hooks — is shared with the parent clone, whether it is
   330	    touched deliberately or by an escaped fixture. Only a **separate full clone** isolates any of it.
   331	  - **Why it escapes at all:** `git -C ""` is documented to leave the working directory unchanged and
   332	    `cd ""` is a bash no-op, and these suites run without `set -e` — so one unguarded
   333	    `r="$(mktemp -d …)"` silently redirects every "fixture" operation onto the caller's clone. It
   334	    fires under **parallel** load (the failure mode of `mktemp`), which is why a serial re-run of the
   335	    same suite reproduces nothing and must not be read as an all-clear. GH-177 family.
   336	  - **Until #564's suite-wide invariant gate lands**, treat any clone you ran the suite in as
   337	    suspect: check `git config --get core.bare`, `git remote -v`, `git config --local --get user.email`,
   338	    and `git log --oneline -1` before trusting a push, a fetch, or a green run from it. A guarded
   339	    fixture helper (`require_fixture`: the path must exist AND live under `$WORK` — containment, not
   340	    a null check) is the pattern to copy; `test/gh544-pre-push-gate.sh` has it, 31 other suites do
   341	    not.
   342	  - **Validate a sandbox path at the USE boundary, not where it was created (GH-567).** An empty
   343	    variable does not fail — `git -C ""` uses the current directory, `cd ""` is a no-op,
   344	    `rm -rf "$VAR/"` becomes `/`, `find "$VAR" -delete` becomes `.`. So guard immediately before the

2026-09-04T06:37:43.505235Z ERROR codex_models_manager::manager: failed to renew cache TTL: missing field `base_instructions` at line 94 column 5
codex
ANSWER: Hold PR #427 and fix it on the branch. Keep the fail-closed source and artifact checks; replace the Bash streaming scanner with a small Python extraction helper and regular-file handoff. Do not split out the scanner or downgrade source checking to warn-only.

FINDINGS

- [Blocker] A gate that exits by SIGSEGV/SIGABRT is not mergeable. The proposed Python helper is the right repair: the repo already uses this exact pattern for governance extraction—one Python scan per document, with a shell wrapper—because the former per-line Bash pipeline fan-out was costly and fragile ([utils/pdda/pdda.sh:1028](utils/pdda/pdda.sh:1028), [utils/py/pdda_gov_scan.py:181](utils/py/pdda_gov_scan.py:181)). For GH-414, invoke one Python scanner per tree, write its `file:line:ref` records to a temp file, then consume that file with `while read`. Do not retain a process-substitution “fallback”; a known crash path cannot be the availability fallback.

- [Should] `git check-ignore` identifies a real category—runtime-generated, intentionally untracked state—not a reason to make all source checks advisory. `.tick/` is explicitly ignored ([.gitignore:1](.gitignore:1)), while `project()` explicitly writes `.tick/STATE.md` and `.tick/rejected.jsonl` ([src/project.js:333](src/project.js:333)). The exemption should be narrow and observable: only a repository-relative ref that Git says is currently ignored may be classified `generated-state` and skipped; a non-repo/error result must fail closed; test both a truly ignored path and a negated/re-included path. Emit an informational skip so this does not become invisible debt.

- [Should] The goal was valid; its path model was incomplete. “Exists in a developer’s used tree” is not a valid static-resolution criterion. The contract should be “resolves in a pristine checkout, unless explicitly classified as generated ignored state.” Artifact-only checking would miss a genuine source-tree broken reference, and warn-only contradicts the issue’s stated requirement that a nonexistent comment path fails ([PROJECT/1-INBOX/GH-414-COMMENT-REFERENCE-CHECK.md:20](PROJECT/1-INBOX/GH-414-COMMENT-REFERENCE-CHECK.md:20), [PROJECT/1-INBOX/GH-414-COMMENT-REFERENCE-CHECK.md:50](PROJECT/1-INBOX/GH-414-COMMENT-REFERENCE-CHECK.md:50)).

- [Should] Do not land ADR restoration alone. It repairs today’s two missing files but abandons the recurrence guard, despite the issue correctly identifying the defect as systemic ([PROJECT/1-INBOX/GH-414-COMMENT-REFERENCE-CHECK.md:30](PROJECT/1-INBOX/GH-414-COMMENT-REFERENCE-CHECK.md:30)). Keep the restoration and scanner in the same PR after the stability fix.

- [Should] Amend acceptance criteria to say:

  > `governance` deterministically scans path-shaped references in comments under `src/`, separately against the source and configured artifact trees. An unresolved non-ignored reference fails the full gate with source file, line, and reference. A reference to Git-ignored generated state is reported as a non-blocking generated-state exemption and must not require pre-existing local state. The result is identical in a pristine clone. The scanner has no process-substitution or streaming-pipeline hot path; twenty consecutive `/bin/bash 3.2` pristine-clone runs exit normally with zero signal exits. Red controls prove: a missing source target fails, an artifact-only missing target fails, a pristine `.tick` citation passes by exemption, and scanner failure itself fails closed.

- [Pass] The proposed scope remains “path resolution, not prose truth,” consistent with the issue’s explicit non-goal ([PROJECT/1-INBOX/GH-414-COMMENT-REFERENCE-CHECK.md:14](PROJECT/1-INBOX/GH-414-COMMENT-REFERENCE-CHECK.md:14)). The current governance-scanner tests also provide the right shape: equivalence, synthetic corpus, red control, and operational ceiling ([test/gh365-pdda-gov-scan.sh:10](test/gh365-pdda-gov-scan.sh:10)).

RECOMMENDATION: Rework #427 in place around a Python comment extractor plus temp-file consumption, add the pristine/stability and generated-state controls, then merge the complete fail-closed guard—not a split or warn-only variant.
tokens used
86,038
ANSWER: Hold PR #427 and fix it on the branch. Keep the fail-closed source and artifact checks; replace the Bash streaming scanner with a small Python extraction helper and regular-file handoff. Do not split out the scanner or downgrade source checking to warn-only.

FINDINGS

- [Blocker] A gate that exits by SIGSEGV/SIGABRT is not mergeable. The proposed Python helper is the right repair: the repo already uses this exact pattern for governance extraction—one Python scan per document, with a shell wrapper—because the former per-line Bash pipeline fan-out was costly and fragile ([utils/pdda/pdda.sh:1028](utils/pdda/pdda.sh:1028), [utils/py/pdda_gov_scan.py:181](utils/py/pdda_gov_scan.py:181)). For GH-414, invoke one Python scanner per tree, write its `file:line:ref` records to a temp file, then consume that file with `while read`. Do not retain a process-substitution “fallback”; a known crash path cannot be the availability fallback.

- [Should] `git check-ignore` identifies a real category—runtime-generated, intentionally untracked state—not a reason to make all source checks advisory. `.tick/` is explicitly ignored ([.gitignore:1](.gitignore:1)), while `project()` explicitly writes `.tick/STATE.md` and `.tick/rejected.jsonl` ([src/project.js:333](src/project.js:333)). The exemption should be narrow and observable: only a repository-relative ref that Git says is currently ignored may be classified `generated-state` and skipped; a non-repo/error result must fail closed; test both a truly ignored path and a negated/re-included path. Emit an informational skip so this does not become invisible debt.

- [Should] The goal was valid; its path model was incomplete. “Exists in a developer’s used tree” is not a valid static-resolution criterion. The contract should be “resolves in a pristine checkout, unless explicitly classified as generated ignored state.” Artifact-only checking would miss a genuine source-tree broken reference, and warn-only contradicts the issue’s stated requirement that a nonexistent comment path fails ([PROJECT/1-INBOX/GH-414-COMMENT-REFERENCE-CHECK.md:20](PROJECT/1-INBOX/GH-414-COMMENT-REFERENCE-CHECK.md:20), [PROJECT/1-INBOX/GH-414-COMMENT-REFERENCE-CHECK.md:50](PROJECT/1-INBOX/GH-414-COMMENT-REFERENCE-CHECK.md:50)).

- [Should] Do not land ADR restoration alone. It repairs today’s two missing files but abandons the recurrence guard, despite the issue correctly identifying the defect as systemic ([PROJECT/1-INBOX/GH-414-COMMENT-REFERENCE-CHECK.md:30](PROJECT/1-INBOX/GH-414-COMMENT-REFERENCE-CHECK.md:30)). Keep the restoration and scanner in the same PR after the stability fix.

- [Should] Amend acceptance criteria to say:

  > `governance` deterministically scans path-shaped references in comments under `src/`, separately against the source and configured artifact trees. An unresolved non-ignored reference fails the full gate with source file, line, and reference. A reference to Git-ignored generated state is reported as a non-blocking generated-state exemption and must not require pre-existing local state. The result is identical in a pristine clone. The scanner has no process-substitution or streaming-pipeline hot path; twenty consecutive `/bin/bash 3.2` pristine-clone runs exit normally with zero signal exits. Red controls prove: a missing source target fails, an artifact-only missing target fails, a pristine `.tick` citation passes by exemption, and scanner failure itself fails closed.

- [Pass] The proposed scope remains “path resolution, not prose truth,” consistent with the issue’s explicit non-goal ([PROJECT/1-INBOX/GH-414-COMMENT-REFERENCE-CHECK.md:14](PROJECT/1-INBOX/GH-414-COMMENT-REFERENCE-CHECK.md:14)). The current governance-scanner tests also provide the right shape: equivalence, synthetic corpus, red control, and operational ceiling ([test/gh365-pdda-gov-scan.sh:10](test/gh365-pdda-gov-scan.sh:10)).

RECOMMENDATION: Rework #427 in place around a Python comment extractor plus temp-file consumption, add the pristine/stability and generated-state controls, then merge the complete fail-closed guard—not a split or warn-only variant.
