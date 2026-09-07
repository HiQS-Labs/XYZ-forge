**NO FIRSTHAND VERIFICATION CITED** — treat conclusions as conditional (codex's answer carries an unsupported [Pass]/verified/confirmed-style claim with no quoted span or file:line citation nearby, despite the consult PREAMBLE asking advisors to cite evidence.)

> **ATTESTATION**
> Model: gpt-5.6-sol
> Provider: openai
> Sandbox: read-only

Reading additional input from stdin...
OpenAI Codex v0.153.4
--------
workdir: /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-55986-oe3a4_ye
model: gpt-5.6-sol
provider: openai
approval: never
sandbox: read-only
reasoning effort: medium
reasoning summaries: none
session id: 01a07953-223e-74a2-b424-8cde7a1ad204
--------
user
You are an INDEPENDENT advisor in a one-shot cross-model consult. Another model is answering the SAME question separately and a coordinator will reconcile both answers, so give your own honest, specific read — do not hedge toward a consensus you cannot see. Read any repo files the question references (cite file:line). Respond with: (1) a short direct ANSWER; (2) graded FINDINGS — [Blocker]/[Should]/[Nit]/[Pass] — where applicable; (3) a one-line RECOMMENDATION. You are ADVISORY ONLY: output your analysis as text; do not rely on writing files (you are running in a throwaway copy).

=== CONSULT QUESTION ===
# Consult: QA a two-line change to a git pre-push guard

You are reviewing a plan, not writing code. Be adversarial. The two questions I most want attacked
are marked **ATTACK 1** and **ATTACK 2** at the end. Read the real files in this worktree — do not
take my summaries on trust.

Relevant files, all present in your worktree:

- `githooks/dashboard-staleness-guard.sh` — the guard. The block in question is at lines 147-158.
- `test/gh243-dashboard-staleness-guard.sh` — its suite; tests 7 and 8 are the matched pair from GH-315.
- `utils/roadmap-dashboard.sh` — the renderer whose staleness the guard protects.
- `utils/py/releases_app.py` — the ledger CLI; `roadmap list --json` is the renderer's only data input.

## What "good" looks like for this review

A verdict of **Approve**, **Approve with changes**, or **Changes requested**, followed by findings
each labelled Blocker / Should / Nit. A finding must cite a file:line or a command whose output
would settle it. "Consider being careful about X" with no anchor is not a finding. If you believe
the plan is correct, say so plainly rather than manufacturing objections — but if the safety
argument has a hole, that hole is the most valuable thing you can hand back.

## Context: the defect

`dashboard-staleness-guard.sh` refuses a push whose commit range writes `releases.sql`/`releases.db`
without also modifying `ROADMAP-DASHBOARD.md`. GH-243 built that for one cause: a parked roadmap row
silently dropped by the renderer because of malformed `raw_text`. The guard detects the situation by
regenerating the dashboard and checking for drift.

GH-315 (closed 2026-08-29) found a second, legitimate reason a ledger write produces no dashboard
diff: the write targets a table the dashboard does not render at all. Its fix was an allowlist of
literal INSERT prefixes — `jog_queue`, `op_receipts`, and the `settings` generation counter — with
everything else falling through to the refusal.

Today a `releases marathon add --tracking-issue .../issues/462` write was refused by that same
branch. The marathon write's dump fan-out is `marathons` + `issue_refs` + `op_receipts` + the
generation counter. The last two are allowlisted; the first two are not, so the range hits the
catch-all and gets the "a parked row was dropped by the renderer" message — which is false. Nothing
was dropped. This is GH-315's defect recurring with different table names.

Reproduction: the push of merge commit `196424fb` was refused 2 seconds after start (the guard runs
before the test suite). `bash utils/roadmap-dashboard.sh` emits no warnings and produces no diff.

## The proposed fix

Two case arms added to the existing GH-315 classifier, above the catch-all:

```bash
    '-'INSERT\ INTO\ marathons*|'+'INSERT\ INTO\ marathons*) ;;
    '-'INSERT\ INTO\ issue_refs*|'+'INSERT\ INTO\ issue_refs*) ;;
```

Plus a new test 7b in `test/gh243-dashboard-staleness-guard.sh`, mirroring test 7 exactly but with a
marathon fan-out as the payload, asserting rc 0. Test 8 (a `roadmap_items` write in the same shape
still refuses) is left untouched as the red control. Negative control: revert the two arms, confirm
7b fails and 8 still passes.

## ATTACK 1 — the safety proof

The governing rule in this repo is **never weaken a check to make a gate pass.** Allowlisting these
two tables is only legitimate if they genuinely have no dashboard projection. My evidence:

1. `utils/roadmap-dashboard.sh` contains no SQL; its only data input is
   `releases_app.py roadmap list --json` (line 59).
2. That command returns 132 rows whose `global_id` values carry exactly one prefix, `rmi-`. No
   `mar-`, no `ref-`. The field set is the `roadmap_items` column list: `doc_path, gh_number,
   global_id, issue_url, position, raw_text, section, status_marker, title`.
3. The substrings `marathon` and `ref-` do appear in that JSON but only inside `raw_text`/`title` —
   prose in issue titles, e.g. "GH-202 · wave_reconcile aborts on marathon-plan exit 5".

**Attack this.** Specifically:

- Is there any path by which a `marathons` or `issue_refs` row reaches `ROADMAP-DASHBOARD.md`?
  Trace `roadmap list` in `releases_app.py` yourself. Does it join, subquery, or resolve
  `issue_refs` to populate `issue_url`? A row reachable as a *value* through a join is still a
  projection, and my evidence (3) would not catch it.
- Does anything else the guard protects — not just `ROADMAP-DASHBOARD.md` — consume these tables?
- Is empirical output from one database a sound basis at all, given the current DB may simply have
  no marathon whose issue also sits in the roadmap? What input would falsify my claim?

## ATTACK 2 — allowlist vs. inverting the check

The allowlist has now gone short twice: jog in GH-315, marathon today. The obvious alternative is to
invert it — refuse only when a `roadmap_items` line changed, one arm replacing four:

```bash
    '-'INSERT\ INTO\ roadmap_items*|'+'INSERT\ INTO\ roadmap_items*) non_jog_data=1; break ;;
```

I **rejected** this on the grounds that the allowlist fails closed (an unclassified table refuses
and forces a human to look) while the inverted denylist fails open (a future second projected table
would ship stale, silently, with the guard reporting success).

**Attack this too.** Is my fail-closed/fail-open framing right? Consider that the current allowlist
has produced two false refusals and zero true catches in its lifetime — does a guard that cries wolf
twice and never catches anything actually fail closed in any useful sense, or does it just train
people to reach for `git push --no-verify`, which skips the entire test suite? Is there a third
option better than both — for example, having the guard ask `releases_app.py` which tables the
renderer projects, at the cost of a git hook depending on the app at push time? Name the option you
would ship and why.

## Also worth your attention

- `issue_refs` is reachable from `roadmap_items.issue_url` as a value. Is allowlisting it separable
  from `marathons`, or should only `marathons` be added?
- GH-315 explicitly recorded that its classifier does not match non-INSERT dump grammars. Is the
  literal `INSERT INTO <table> ` prefix match still the right granularity, or does adding a fourth
  and fifth entry make the fragility worse?
- Is a two-line guard change the right scope at all, or should this be filed and the marathon write
  simply parked out of the current push?

codex
I’ll trace the actual renderer-to-ledger path, inspect the guard’s exact classifier and paired tests, and distinguish schema-level proof from the single-database observation. I’ll keep this read-only and cite exact lines.
exec
/bin/zsh -lc "sed -n '1,240p' /Users/noelsaw/.codex/skills/consult/SKILL.md && sed -n '1,220p' ROUTER.md && sed -n '1,180p' GUIDING-PRINCIPLES.md" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-55986-oe3a4_ye
 succeeded in 0ms:
---
name: consult
description: One-shot cross-model CONSULT — fan the same question out to Codex and agy in parallel (repo-isolated, advisory), then reconcile their answers into one. Use when the user wants a "second opinion", to "ask Codex and agy", a "panel" or "cross-model" check, or an independent gut-check on a decision/design/doc before committing — and does NOT need an iterative build/review loop. NOT a relay: a relay is an iterative 1:1 Producer↔Reviewer loop that converges an artifact; a consult is a parallel 1-shot 1:N second opinion, reconciled once. Depends on the codex + agy CLIs and the relay-automation shims; runs in any repo that ships them at the repo root OR in a vendored `.xyz/` install (the skill resolves either).
---

# Consult

**One question → N independent models in parallel → one reconciled answer.**

A consult asks Codex and agy the *same* question at the same time, isolated from your real tree, and then a
coordinator (Claude) reconciles their answers — surfacing where they **agree**, where they
**disagree**, and giving a single reconciled **call**. It is the fast "ask the other brains before I
commit" move: no copy-paste, no window-shuttling, one step.

## Consult vs. relay — pick the right tool

| | **consult** (this skill) | **relay** |
|---|---|---|
| shape | parallel fan-out, 1 question → N models | iterative loop, 2 agents |
| rounds | exactly **one** | many, until `Approved` |
| writes | **none** — advisory only | Producer edits the artifact |
| output | reconciled answer + divergences | a converged artifact |
| use for | a decision, a design gut-check, "is this doc sound?" | building/fixing an artifact under review |

If after a consult you decide the work needs iteration, *start a relay* — the consult is the cheap
first look, the relay is the build loop.

## When to use

- "Get a second opinion." "Ask Codex and agy." "What do the other models think?"
- "Panel review" / "cross-model check" / "sanity-check this before I commit."
- An independent gut-check on a plan, design, schema, or doc — where you want *divergent* reads, not
  a single model's confident answer.

Do **not** use it to build or fix an artifact iteratively — that's `relay`.

## How it works

`relay-automation/consult.sh` (path is relative to **this repo's root**, not your cwd) fans the question
out to both advisors **in parallel** and writes each transcript to a per-run dir
`relay-system/<today>/<label>-<HHMMSS>/`. The synthesis is **yours** — the script only gathers the raw
opinions.

**Locating the script — resolve it cwd-independently; never assume your cwd is the repo root.** A bare
`consult.sh` or `relay-automation/consult.sh` only resolves when you happen to be sitting at the root,
so invoke it through its repo-root anchor instead. Two homes are supported so consult works both in
the `xyz-3-agents-swarm` checkout **and** in any repo that has a vendored `.xyz/` install: the
top-level `relay-automation/` if present, otherwise the vendored `.xyz/relay-automation/`.

```
ROOT="$(git rev-parse --show-toplevel)"
SCRIPT="$ROOT/relay-automation/consult.sh"
[ -f "$SCRIPT" ] || SCRIPT="$ROOT/.xyz/relay-automation/consult.sh"
# CONSULT_ROOT MUST be the repo root: consult.sh otherwise infers its root as the script's parent-of-
# parent, which for the vendored copy is `.xyz/` (wrong). Setting it pins the consult to the real repo
# and its `relay-system/` output. Harmless (a no-op) for the top-level copy.
CONSULT_ROOT="$ROOT" "$SCRIPT" --prompt "…" --label …
```

`git rev-parse --show-toplevel` works from any subdirectory of the repo. If you are not inside a repo
that has consult (no top-level `relay-automation/` and no `.xyz/`), either `cd` into the
`xyz-3-agents-swarm` worktree, or vendor a `.xyz/` into the target repo first
(`relay-automation/xyz-vendor.sh <repo>`). (Do **not** go hunting the disk for `consult.sh`; the
anchor above always finds it.)

**Provable no-mutation boundary (not best-effort).** Advisors run with their working directory set to a
**throwaway git worktree** checked out from your *current* state — tracked WIP (via `git stash create`)
plus untracked-non-ignored files copied in — so they see your working state (minus `.gitignore`d
files), including a brand-new file under
review. Anything an advisor writes lands in that disposable worktree and is destroyed with it; your
real working tree is **never** the advisors' surface, so there is nothing to revert and ambient WIP
cannot be clobbered. (Codex additionally runs `-s read-only`.) This replaced an earlier best-effort
post-hoc revert that the skill's own first dogfood flagged as unsafe.

```
consult.sh --prompt-file Q.md            # question is the file's contents (may reference repo paths)
consult.sh --prompt "Is X sound?"        # inline question
  [--models codex,agy]                   # which advisors (default both)
  [--out DIR]                            # parent dir (default relay-system/<today>/)
  [--label SLUG]                         # run-subdir + transcript stem (default "consult")
```

Each run gets its own `<label>-<HHMMSS>/` subdir, so two consults the same day never overwrite each
other. Behavior is covered by `test/consult.sh` in `validate.sh` (WIP preservation, no advisor leak,
graceful degrade, non-git refusal).

Exit `0` = at least one advisor answered; `5` = all failed; `3` = not a git repo (isolation needs
one); `2` = usage. Per-model failures are reported, not fatal — if Codex's backend is down, Gemini's
answer still comes back (**graceful degrade**, and the degrade is stated, never silent).

## Steps (the coordinator's job)

1. **Frame one sharp question.** Put it in a prompt file when it references repo paths (the advisors
   read the files themselves). Be explicit about what "good" looks like, just like a relay's
   Definition of Done.
2. **Fan out:** run the script through its repo-root anchor (see "Locating the script" above — prefer
   `$ROOT/relay-automation/consult.sh`, fall back to `$ROOT/.xyz/relay-automation/consult.sh`, and
   always pass `CONSULT_ROOT="$ROOT"`) with the prompt + a `--label`. Both models run at once. Don't
   invoke a bare `consult.sh`; it only resolves at the repo root.
3. **Read both transcripts** in `relay-system/<today>/<label>-<HHMMSS>/<label>.codex.md` and `…agy.*`.
4. **Reconcile — this is the load-bearing step.** Produce a synthesis with four parts, in this order:
   - **TLDR** (new — one to two sentences, before anything else): the reconciled call and how confident
     it is, so the operator can stop reading right there if that's all they need. e.g. *"Both models
     agree the migration is safe — go ahead. Codex flagged one edge case worth a follow-up (see below)."*
   - **Disagree** (it's the whole point of asking two models): every point the two differ on, with your
     adjudication and *why*. Never in the TLDR — the TLDR previews the call, it doesn't bury the split.
   - **Agree:** what both independently converged on (higher confidence because it's cross-model).
   - **Sorted categories** (new — closes the synthesis, replaces a bare prose recommendation): bucket
     every point either advisor raised — agreements and adjudicated disagreements alike — into exactly
     one:
     - **Blocking** — a real risk either advisor surfaced; must address before proceeding.
     - **Worth doing, optional** — a real improvement; the operator's call.
     - **Skip / out of scope** — noted and dismissed, named so it doesn't resurface.
     Drop empty buckets. For a short, clean consult (both advisors agree, one or two minor notes),
     skip the buckets and give the recommendation as plain prose instead — don't force structure on a
     synthesis with nothing to sort.
5. **Hand the synthesis back** to the operator. If it reveals the work needs iteration, offer to
   start a `relay`.

## The one rule that makes a consult worth running

**Surface disagreement; never average it away.** The entire value of asking two models is the *delta*
between them — the place one caught what the other missed. A synthesis that smooths two answers into
one confident paragraph throws that away and is worse than asking one model, because it launders two
guesses into false consensus. Lead with the disagreements, adjudicate them explicitly, and if you
can't adjudicate one, say so and flag it for the human. (Same failure mode as a review that only
hunts overclaims and misses silent drops: the easy direction satisfices.)

## Honest caveats

- **Two models, not ground truth.** Cross-model agreement raises confidence; it does not prove
  correctness — both can share a blind spot or a wrong prior. Treat a unanimous answer as *strong
  signal*, not proof, especially when correctness rides on runtime behavior neither model ran.
- **Repo-isolated, not process-sandboxed.** Advisors run in a throwaway worktree and cannot reach
  your real tree, so a consult never changes your code even if an advisor ignores the "advisory only"
  instruction. Be precise about the boundary: this protects your *repository*, not the *host process*.
  Codex additionally runs `-s read-only`; agy runs with `--dangerously-skip-permissions` and is
  repo-isolated but not a sandboxed process (it can still reach the network / the host outside the
  worktree). For a hard process boundary, run consult inside your own sandbox. If a fix is needed,
  *you* (or a relay) apply it — the independent check stays independent.
- **The worktree shows tracked + untracked state, not ignored files.** `.gitignore`d local context is
  excluded from what advisors see; reference it inline in the question if it matters.
- **Cost capture is not available for agy.** agy has no JSON/token output, so an agy lane is cost-blind
  (a floor). Codex token parsing is also still deferred. Neither lane captures `tick cost` events in a consult.
- **Needs the shims present, but is not tied to one repo.** Unlike `relay` (model-agnostic, file-only),
  consult hard-depends on the `codex` + `agy` CLIs being installed and authed and on the
  `relay-automation` shims. Those shims can live at the repo root **or** in a vendored `.xyz/` install,
  so any repo carrying a `.xyz/` (see `relay-automation/xyz-vendor.sh`) can run consult standalone.

## Gotcha: run consult OUTSIDE Claude Code's Bash sandbox

If you launch `consult.sh` from a Claude Code session, **disable the Bash sandbox for that call**
(`dangerouslyDisableSandbox: true`). **Both advisors fail under the sandbox:**
- **Codex** — the sandbox blocks the macOS keychain (`no native root CA certificates found` / `No keychain is available`) and does not allowlist `chatgpt.com`.
- **agy** — the sandbox blocks agy's backend network; `agy -p` exits 0 with **empty output** (the shim treats this as a hard failure, exit 5).

The symptom is a two-sided `0 answered, 2 failed` degrade. Disabling the sandbox here is safe:
consult's isolation comes from its **throwaway worktree** (and Codex's own `-s read-only`), not from
the Bash sandbox, so nothing is weakened.

## What success looks like

The operator asks one question and gets back a single, honest, reconciled answer that **shows its
seams** — what the two models agreed on, where they split, and which way the coordinator called it and
why — in one step, with both raw transcripts on disk for audit.
# ROUTER.md

This file is the first entry point for an AI agent working in this repo: it tells you what to read, what to run, and which files are canonical.

## Role split

- `ROUTER.md` = startup order and canonical entry points
- `GUIDING-PRINCIPLES.md` = the *why*, and the canonical North Star: durable, reversible, DRY — extend what exists rather than forking a parallel system
- `AGENTS.md` = behavioral rules, decision quality, reversibility, blast radius, proof
- `README.md` = human-facing repo/product overview
- `ROADMAP-DASHBOARD.md` = the generated, human-readable view of the roadmap ledger (read this; regenerate with `utils/roadmap-dashboard.sh`); the RELEASES DB (`releases.db` via `releases.sql`) is the source of truth (`ROADMAP.md` retired per GH-269)
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
3. Read `ROADMAP-DASHBOARD.md` (or `python3 utils/py/releases_app.py roadmap list`) to find the active effort or parked intake. -> expect links outward to the canonical `PROJECT/**` docs; the roadmap is a pointer ledger, not a plan body. (`ROADMAP.md` is retired — the RELEASES DB is the single source of truth.)
4. Read the linked `PROJECT/**` document that owns the work you are touching. -> expect the near-top `## Status` table to tell you what was just completed and what is next.
5. If the task touches project docs, read `PROJECT/PDDA.md` and follow the PDDA contract. -> expect `PROJECT/2-WORKING` docs to have frontmatter, the exact status table, and QA gates when phased.
6. Before reporting success on code or runtime work, run `./validate.sh`. -> expect the suite to stay green; do not claim completion if it fails or was skipped.
7. Before reporting success on doc-hygiene or roadmap work, run `utils/pdda/pdda.sh run` (or the relevant `utils/pdda/pdda.sh <check>` subcommand). -> expect deterministic findings first, then any LLM review.

## Canonical rules

- Do not put phase checklists, build steps, or deep execution notes in the roadmap ledger.
- Every active doc in `PROJECT/2-WORKING/` must be reflected by a pointer row in the roadmap ledger (the RELEASES DB) that links it. A working doc that should not appear opts out with `roadmap_exempt: true` in its frontmatter. Governance lives in `PROJECT/PDDA.md` → "ROADMAP contract".
- Promoting a capture from `1-INBOX` to `2-WORKING` is a DB-verb procedure (`roadmap repoint` + `roadmap update` / `roadmap move`), never a markdown edit — the exact steps and their two known gate traps (`updated:` frontmatter key, bullet-format `raw_text`) live in `SOP.md` → "Step 1b: Promoting a capture from 1-INBOX to 2-WORKING (releases-mode)".
- Every captured GitHub issue doc in `PROJECT/1-INBOX/GH-*.md` must also be parked as a queue row immediately at intake — `python3 utils/py/releases_app.py roadmap add --issue-num N --issue-url U --title T --created YYYY-MM-DD --doc-path P` (or `hq park`, which routes there automatically in this repo) — then promoted or removed later. Governance lives in `PROJECT/PDDA.md` → "GitHub issue intake" + "ROADMAP contract".
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
**Subsystem 2 — the roadmap ledger** (GH-69 shadow → GH-238/GH-243 canonical → GH-269 retired ROADMAP.md): since the
`ROADMAP_SOURCE=releases` flip, `roadmap_items` IS the ledger — write rows with
`releases roadmap add` (or `hq park`), read with `roadmap list` / `ROADMAP-DASHBOARD.md`.
`ROADMAP.md` has been retired and removed. `roadmap sync` exists for legacy-mode repos only and
no-ops here by design (it would delete `add`-parked rows). Pinned by `test/gh69-roadmap-shadow.sh`,
`test/gh238-hq-releases-mode.sh`, and `test/gh269-roadmap-retired.sh`.

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
# Guiding Principles

North star for **xyz-3-agents-swarm**, the multi-agent coordination harness behind the `tick` event-log kernel and `relay-automation/` relay stack. When a choice is unclear, the option that keeps agents synchronized, contained, and verifiable — without leaking or destroying work — wins. AGENTS.md is the behavioral playbook; ROUTER.md is the entry-point map; this is the *why*.

## The North Star

There is no perfect architecture and no finished codebase. The bar is not perfection — it is that
every change leaves the harness **more durable, more reversible, and less duplicated** than it found
it, and that the three stay in balance:

- **Durable** — it removes the root cause and the next planned change builds on it, rather than being
  torn out when the obvious next feature lands.
- **Reversible** — the cost of being wrong is known and bounded before the change lands. A change
  nobody can undo is a bet, not a fix, and gets treated as one.
- **DRY** — nothing canonical lives in two places where it can drift. One source of truth, and every
  other surface is a pointer or a projection of it.

**Do not build a new layer, module, or sub-system when an existing piece of code can be extended
easily, logically, and safely.** Extending an existing abstraction beats standing up a parallel,
siloed system, even when the parallel path is faster to write today — the parallel path is what
later has to be kept in sync, and what silently drifts when it isn't. If the existing abstraction
genuinely cannot carry the new case, say so in one line, with the reason, before forking.

These three pull against each other, and that tension is the decision, not a problem to average
away: the most durable fix is often the least reversible, and collapsing two near-duplicates is a
DRY win that can widen the blast radius. Name the trade and pick; do not split the difference by
building both.

This section is canonical. `AGENTS.md` owns how it is applied to a given change — the reversibility
scale (§3) and blast-radius sizing (§4) — and principles 6, 7, and 10 below are the build-time and
done-time expressions of it. Where another doc restates this, that doc is the copy and this is the
original.

## Purpose

`tick` coordinates Claude Code, Codex, and agy (Antigravity CLI) on the same branch without collision: a shared local event log under `.tick/events/`, claims serialized by `O_EXCL` locks, and a `Marathon` harness that chains multi-phase build→review cycles from a `MARATHON.yaml`. The relay layer (`relay-automation/`) drives headless turns, isolates agent writes to worktrees, and enforces an allowlist so no headless agent destroys work it didn't intend to touch. The goal: a multi-agent swarm safe enough to run against a real external codebase and correct enough that its output is worth shipping.

## The quality bar

Every agent turn is a signal. A turn is high-quality only when it is all four:

- **Attested** — carries its receipts: source, evidence, confidence. Never a bare verdict. A relay review names which claim is wrong and why; a build turn names the seam it touched.
- **Relevant** — ranked, not dumped. Volume is not value. One real bug beats five nits and a phantom.
- **Fresh** — current, not stale. A turn that reads a stale `STATE.md` or misses an epoch fence is wrong by construction.
- **Structured** — one shape, clean for the operator to read and for downstream agents to feed on.

Fail a pillar, and the turn, feature, or relay review isn't done.

## How it's built

1. **Coordination is local-transport only.** `.tick/events/` is the shared bus; claims resolve from there, not from a remote. No per-event push/fetch; no remote dependency at runtime. A coordination primitive that reaches out is a coordination primitive that can fail or leak.

2. **One canonical event log; every surface is a projection.** `tick` accretes events; `STATE.md` is the current projection. Reads go through the projection; writes go through a `claim/take/scope/done` verb. Nothing canonical lives in two places where it can drift. An agent that hard-codes state outside `.tick/` is creating drift.

3. **Containment is non-negotiable.** A headless turn must not: self-commit mid-turn, orphan a peer's concurrent commit, or write outside its allowlist. The allowlist, worktree isolation, and commit-bypass guard exist because a driven agent will do all three if unconstrained — not hypothetically, but as documented live incidents (GH-13, GH-14, GH-17). New relay paths must clear the containment bar before they ship.

4. **Skill-first; never improvise the harness.** The `relay-xyz` skill owns the locator, sandbox rules, exit codes, and the safety boundary. A session that improvises those from `ls relay-automation/` silently skips the skill's safety layer. The `PreToolUse` guard (`relay-automation/hooks/relay-xyz-guard.sh`) enforces this by blocking driver calls before the skill loads. Add capabilities to the skill; do not work around it.

5. **Adversarially proven before commercially viable.** The harness exists to run against real codebases. Features in the adversarial-hardening track (epoch fencing, chaos suite, cross-repo E2E) must be verified to survive deliberate abuse — stale writers, zombie claims, macOS case-sensitivity, concurrent peer commits — not just the happy path. A feature that clears the happy path and skips chaos is half-done.

6. **Build durable, not band-aid.** Durable means it removes the root cause and the next planned change builds on it — not a patch torn out when the obvious next feature lands. A band-aid is wasted work unless a demo strictly needs one, and a demo band-aid is tagged for removal so it isn't silently inherited.

7. **Least code that clears the bar.** Node standard library only — no deps, no lockfile; the repo ships no root manifest. Prefer reusing or extending what exists; the smallest change that stays correct, contained, and durable wins. Net-new code is a cost to justify. Deleting code counts as progress.

8. **Honest; the operator decides.** Surface what failed and why — never mask a stall as success or an escalation as a stall. A headless turn self-repairs within a bounded exit-code menu (`exit 3` stall, `exit 4` escalated-by-design, `exit 6` containment revert), then stops; it never loops forever or silently swallows an error. Destructive actions require explicit authorization.

9. **Docs are resumable runtime state (PDDA).** Agent work is stoppable, resumable, and handed off from `PROJECT/**` alone — ROUTER points, project docs hold detail, CHANGELOG logs dated outcomes. ROADMAP.md is a pointer/ledger only; execution detail lives in the linked `PROJECT/**` doc. If reality and the docs disagree, the docs are the bug.

10. **Done means verified.** "Done" is `validate.sh` green, the relevant PDDA checks passing, and any relay review returning `Approved` — not work that looks finished. An unverified success claim is itself a low-quality signal.

11. **Issue-first; every non-trivial change has a signal stream.** Any change beyond a 2–3 line fix opens a GitHub issue first, then gets a `GH-<number>` in-repo pointer doc, then lands. The issue is the machine-queryable signal stream; the `PROJECT/**` doc is the execution surface of record. Genuinely trivial edits (≤2–3 line fixes, typos, path repoints, doc-only one-liners) are exempt.

12. **Independent Verification (Separated Grading)** — The agent that produces a turn must not be the sole grader of its own quality. Verification must be performed by an independent deterministic check or a separate reviewing agent before the lock releases. Applies to: the relay's structural block validator (`bin/validate-relay-block` — Phase 1 of GH-21), consult-verify diversity (Phase 3), and any other post-generation quality gate.

13. **A green gate without a witnessed red control is not evidence.** Every new or materially changed decision gate ships a recorded demonstration that it fails for the right reason: a pre-fix replay, deliberate mutation, or controlled bad fixture. Do not mistake a check that validates the artifact it just generated (#351) or a parity check that compares a lane to itself (#348) for evidence; both shapes are structurally unable to falsify their claim.

## Applying this

Adding a feature or weighing a tradeoff, ask: *does this keep agents coordinated without collision, contained within their scope, and verifiable to an outside observer? And is "done" provable by running `validate.sh`?* If any answer is no, reconsider.

---

## Conventions

### Strict-mode policy (bash `set -e`)

Strict mode is **per-subsystem, not repo-wide** (GH-110 P3b). The split is deliberate:

- **`relay-automation/` drivers and turn shims run `set -euo pipefail`.** They orchestrate risky,
  multi-step, containment-sensitive turns where a silently-ignored failure can commit off-lane or
  orphan a peer. Abort-on-error (`-e`) is the correct default there.
- **`utils/` analysis tools (`pdda/*`, `marathon-plan.sh`, `swarm-preflight.sh`) run `set -uo pipefail`
  or `set -u`, deliberately *without* `-e`.** These are long single-pass scripts whose normal control
  flow includes many expected-nonzero probes (`git rev-parse`, `gh` lookups, `grep` misses). Under
  `-e` a benign "no match" would abort the whole run, so they set `-u` (catch unset vars) + explicit
  per-call error handling instead. This is an exemption, not an oversight.

Every currently `-e`-exempt script carries a one-line `# strict-mode: -e exempt — …` header next to
its `set -` line so the exemption is self-documenting. New scripts default to `set -euo pipefail`
unless they fit the analysis-tool profile above, in which case they add the exemption header.

### Tool install paths — never inside another app's folder (GH-347)

**This harness's tool binaries never live inside another application's private directory.** Not the
worker CLIs (`codex`, `agy`, `pi`, `aider`), not `tick`, not anything the harness shells out to.

The failure mode is specific and quiet: a foreign app owns its own directory, so its next update or
reinstall deletes our dependency with it — on that app's schedule, with no signal we control. Worse, the
readiness check cannot tell the two apart. `find-harness.sh --check` tests only whether a worker is *on
PATH*, so "the neighbouring app just wiped our tool" and "never installed" produce the byte-identical
line. That is the same disease as GH-315/GH-319: a broken observation layer where failure is invisible
and every available signal agrees.

**The `npm install -g` trap — this is how GH-347 actually happened.** npm derives its global prefix from
whichever `npm` is on PATH, so a bare `npm install -g <pkg>` inherits a foreign app's runtime silently
and exits 0. On the machine that filed GH-347, another agent app had symlinked its bundled Node onto PATH
(`~/.local/bin/npm -> ~/.hermes/node/bin/npm`) with no `~/.npmrc` involved at all, so `pi` installed into
that app's folder and — because only `node`/`npm` were symlinked out, not `pi` — was invisible to every
shell while being perfectly functional. **Run `npm config get prefix` before any global install and
confirm it is a path this repo's tooling owns.** Never assume.

The positive pattern is already on disk in the two lanes that have never had this problem: a tool's own
app directory with a symlink onto PATH (`~/.local/bin/codex -> ~/.codex/packages/…/bin/codex`), or a real
binary in a shared user-local `bin`. Either is fine. Someone else's runtime is not.

**Scope note:** where a *working* binary lives stays the operator's call. This is a convention and a
warning, deliberately **not** a gate — a false positive that blocks a relay is worse than the papercut it
prevents.

### Marathon builder default & plan location (GH-212)

Two vendored-harness defaults, made explicit so an agent given only the vendored bundle picks the
right behavior without pattern-matching a downstream repo's prior drift:

- **Builder default is `codex`, not a billed CLI.** `marathon.sh`/`marathon-drive.sh` (and the
  `XYZ_PYTHON=1` port) default `--builder` to `codex` — build turns bill via the Codex/ChatGPT
  subscription, not the Anthropic API (agy is the other cost-blind option). `--builder claude`
  spawns a headless Claude Code CLI subprocess instead: a separate, per-call API-billed turn-taker.
  Use it only as an explicit, cost-acknowledged choice — never assume it's free because an
  interactive session is already running. `swarm-preflight.sh`'s suggested invocation and
  `marathon.sh`'s own default now agree; don't let them drift apart again.
- **A marathon's plan lives under `PROJECT/2-WORKING/`.** The `MARATHON.yaml` + its phase briefs
  belong under `PROJECT/2-WORKING/<capture-doc>/` — never a standalone top-level folder (e.g.
  `marathon-plans/<slug>/`). `marathon.sh --plan` enforces this: it refuses (exit 2) a plan that
  resolves outside `PROJECT/2-WORKING/`, exempting only paths under the harness's own home
  (`MARATHON_HOME` — shipped reference examples like `MARATHON.example.yaml`) or an explicit
  `MARATHON_ALLOW_PLAN_OUTSIDE_WORKING=1` override for a genuinely non-default location.

---

## Appendix: AI Doc Review Heuristics

When reviewing any repo doc (roadmap entries, plans, architecture notes, audits, task writeups), apply these. Priority: containment > coordination correctness > signal quality > implementation speed and operator friction.

**Heuristics**

1. **Containment preserved?** Any headless path that could self-commit, touch off-allowlist files, or orphan a peer commit without an explicit containment argument → reject or escalate.
2. **Skill-first respected?** Any plan that bypasses `relay-xyz` or improvises the harness from scratch without the skill layer → reject. Add to the skill instead.
3. **Coordination through the event log?** Reads/writes to shared state route through `tick` verbs; hard-coded state outside `.tick/` needs explicit justification.
4. **Done verifiable?** Names runnable gates (`validate.sh`, specific tests, `utils/pdda/pdda.sh run`). None = low-quality signal.
5. **Drift reduced, not created?** No duplicated docs, no execution detail in ROADMAP.md, no reinventing a path the event-log contract already documents.
6. **Next action singular?** One explicit next step, not buried in prose; status cells non-empty.
7. **Operator control explicit?** No silent retry, no auto-repair outside the bounded exit-code menu, no masked failure; destructive ops surface before executing.
8. **Four pillars pass?** Each turn/output is Attested, Relevant, Fresh, Structured. Fail one → not done.

**Tie-breakers**

- **Containment vs speed:** choose containment; flag friction as a design question, not a shortcut.
- **New relay path vs reuse:** extend the existing skill and harness over forking a parallel path; if the harness can't accommodate it, surface the gap.
- **Ambitious vs resumable:** a shorter plan an agent can resume cold beats a comprehensive one that buries state in prose.

**Reject or escalate when**

- A headless path has no allowlist, no worktree isolation, and no commit-bypass guard — and the doc doesn't justify why.
- "Done" has no runnable verification step.
- Adding a new relay lane requires editing the event-log kernel or the `tick` verb schema without a decision record under `decisions/`.
- Hardcoded absolute paths, silent destructive operations, or opaque epoch-fence assumptions.
- ROADMAP.md would need execution detail to make the plan legible.

mcp: codebase-memory-mcp/list_projects started
mcp: codebase-memory-mcp/list_projects (completed)
mcp: codebase-memory-mcp/index_repository started
mcp: codebase-memory-mcp/index_repository (completed)
mcp: codebase-memory-mcp/search_graph started
mcp: codebase-memory-mcp/search_graph (completed)
mcp: codebase-memory-mcp/search_graph started
mcp: codebase-memory-mcp/search_graph (completed)
mcp: codebase-memory-mcp/search_graph started
mcp: codebase-memory-mcp/search_graph (completed)
mcp: codebase-memory-mcp/search_graph started
mcp: codebase-memory-mcp/search_graph (completed)
mcp: codebase-memory-mcp/search_graph started
mcp: codebase-memory-mcp/search_graph (completed)
mcp: codebase-memory-mcp/get_code_snippet started
mcp: codebase-memory-mcp/get_code_snippet (completed)
mcp: codebase-memory-mcp/trace_path started
mcp: codebase-memory-mcp/trace_path (failed)
MCP tool call requires approval, but approval policy is never
exec
/bin/zsh -lc "nl -ba githooks/dashboard-staleness-guard.sh | sed -n '1,230p'
nl -ba test/gh243-dashboard-staleness-guard.sh | sed -n '1,300p'
nl -ba utils/roadmap-dashboard.sh | sed -n '1,240p'
nl -ba utils/py/releases_app.py | sed -n '600,730p;2440,2540p;2930,3010p;3090,3190p;3250,3378p;3535,3590p'
rg -n \"issue_refs|marathons|roadmap list|roadmap_items|ROADMAP-DASHBOARD\" utils/py/releases_app.py utils/roadmap-dashboard.sh githooks/dashboard-staleness-guard.sh test/gh243-dashboard-staleness-guard.sh" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-55986-oe3a4_ye
 succeeded in 0ms:
     1	#!/usr/bin/env bash
     2	# dashboard-staleness-guard.sh — refuse a push whose range writes the roadmap ledger but not the
     3	# dashboard (GH-243, the enforcement half of GH-169 item 3).
     4	#
     5	# WHY: since the ROADMAP_SOURCE=releases flip, ROADMAP-DASHBOARD.md is the ONLY human-readable
     6	# view of the roadmap ledger — the DB is what every tool trusts, and nothing else re-renders the
     7	# view. A ledger write (releases.sql / releases.db) that ships without a dashboard regeneration
     8	# publishes a web/agent view that silently disagrees with the data under it.
     9	#
    10	# WHERE IT RUNS: called by githooks/pre-push with the same "<local_sha> <remote_sha>" ref pairs
    11	# the gate already parses — the push boundary is this repo's one wired, branch-independent
    12	# enforcement point (GH-549); a pre-commit hook would need a second stub wiring that does not
    13	# exist. Local commits stay free and ungated on purpose.
    14	#
    15	# SCOPE: applies only when the repo being pushed declares ROADMAP_SOURCE=releases in .pdda-mode.
    16	# Legacy-mode repos and branches predating the flip are untouched. A new branch (all-zero remote
    17	# sha) has no computable range; it falls through to the full gate like every other unclassifiable
    18	# push — this guard only ever ADDS a refusal, never replaces the gate.
    19	#
    20	# Usage: dashboard-staleness-guard.sh <repo_root> <local_sha> <remote_sha> [<local_sha> <remote_sha>...]
    21	# Exit:  0 ok (guard passed or not applicable) · 1 refuse the push · 2 usage.
    22	set -uo pipefail
    23	
    24	REPO="${1:-}"; shift || true
    25	[ -n "$REPO" ] && [ -d "$REPO" ] || { echo "dashboard-staleness-guard: usage: <repo_root> <local_sha> <remote_sha>..." >&2; exit 2; }
    26	
    27	grep -q "ROADMAP_SOURCE=releases" "$REPO/.pdda-mode" 2>/dev/null || exit 0
    28	
    29	SYS_TMP="$(cd -P "${TMPDIR:-/tmp}" 2>/dev/null && pwd -P)" || SYS_TMP="/tmp"
    30	GUARD_ROOT=""
    31	GUARD_ROOT_PHYS=""
    32	GUARD_INODE=""
    33	GUARD_DEV=""
    34	
    35	get_dev_inode() {
    36	  local target="$1"
    37	  # GNU coreutils spells --format as -c and uses -f for --file-system; BSD spells --format as -f.
    38	  # Probing BSD-first therefore SUCCEEDS on Linux for the wrong reason: `-f` is accepted, "%d %i"
    39	  # is read as a filename, and stdout gets a multi-line filesystem block instead of "<dev> <inode>".
    40	  # The caller's "${x%% *}" then yields an empty device and the guard reports an identity mismatch
    41	  # between two identical inodes. `-c` is not a BSD flag, so probing GNU-first fails cleanly there.
    42	  stat -c "%d %i" "$target" 2>/dev/null || stat -f "%d %i" "$target" 2>/dev/null || true
    43	}
    44	
    45	cleanup_guard() {
    46	  local exit_code=$?
    47	  [ -n "$GUARD_ROOT" ] || return "$exit_code"
    48	  [ -e "$GUARD_ROOT" ] || return "$exit_code"
    49	  if [ -L "$GUARD_ROOT" ]; then
    50	    echo "dashboard-staleness-guard: refusing cleanup — guard root is a symlink" >&2
    51	    exit 1
    52	  fi
    53	  local cur_phys
    54	  cur_phys="$(cd -P "$GUARD_ROOT" 2>/dev/null && pwd -P)" || {
    55	    echo "dashboard-staleness-guard: failed to resolve guard root physical path" >&2
    56	    exit 1
    57	  }
    58	  if [ -n "$GUARD_ROOT_PHYS" ] && [ "$cur_phys" != "$GUARD_ROOT_PHYS" ]; then
    59	    echo "dashboard-staleness-guard: refusing cleanup — guard root path drifted ($cur_phys != $GUARD_ROOT_PHYS)" >&2
    60	    exit 1
    61	  fi
    62	  local cur_dev_inode
    63	  cur_dev_inode="$(get_dev_inode "$cur_phys")"
    64	  local cur_dev="${cur_dev_inode%% *}"
    65	  local cur_inode="${cur_dev_inode##* }"
    66	  if [ -z "$GUARD_DEV" ] || [ -z "$GUARD_INODE" ] || [ -z "$cur_dev" ] || [ -z "$cur_inode" ] || \
    67	     [ "$cur_dev" != "$GUARD_DEV" ] || [ "$cur_inode" != "$GUARD_INODE" ]; then
    68	    echo "dashboard-staleness-guard: refusing cleanup — guard root identity mismatch ($cur_dev:$cur_inode != $GUARD_DEV:$GUARD_INODE)" >&2
    69	    exit 1
    70	  fi
    71	  case "$cur_phys" in
    72	    "$SYS_TMP"/*) rm -rf "$cur_phys" || exit 1 ;;
    73	    *) echo "dashboard-staleness-guard: refusing cleanup of non-descendant $cur_phys" >&2; exit 1 ;;
    74	  esac
    75	  return "$exit_code"
    76	}
    77	trap cleanup_guard EXIT INT TERM
    78	
    79	GUARD_ROOT="$(mktemp -d "$SYS_TMP/staleness-guard.XXXXXX")"
    80	[ -n "$GUARD_ROOT" ] || { echo "dashboard-staleness-guard: mktemp failed" >&2; exit 1; }
    81	
    82	GUARD_ROOT_PHYS="$(cd -P "$GUARD_ROOT" 2>/dev/null && pwd -P)" || GUARD_ROOT_PHYS=""
    83	[ -n "$GUARD_ROOT_PHYS" ] && [ -d "$GUARD_ROOT_PHYS" ] || { echo "dashboard-staleness-guard: failed to resolve guard root" >&2; exit 1; }
    84	case "$GUARD_ROOT_PHYS" in
    85	  "$SYS_TMP"/*) ;;
    86	  *) echo "dashboard-staleness-guard: guard root $GUARD_ROOT_PHYS is not a resolved descendant of $SYS_TMP" >&2; exit 1 ;;
    87	esac
    88	
    89	init_dev_inode="$(get_dev_inode "$GUARD_ROOT_PHYS")"
    90	GUARD_DEV="${init_dev_inode%% *}"
    91	GUARD_INODE="${init_dev_inode##* }"
    92	if [ -z "$GUARD_DEV" ] || [ -z "$GUARD_INODE" ]; then
    93	  echo "dashboard-staleness-guard: failed to establish guard root device/inode identity" >&2
    94	  exit 1
    95	fi
    96	
    97	while [ "$#" -ge 2 ]; do
    98	  local_sha="$1"; remote_sha="$2"; shift 2
    99	  case "$remote_sha" in
   100	    ''|0000000000000000000000000000000000000000) continue ;;   # new branch: no range to inspect
   101	  esac
   102	  git -C "$REPO" cat-file -e "${remote_sha}^{commit}" 2>/dev/null || continue
   103	
   104	  touched_ledger=0
   105	  touched_dashboard=0
   106	  while IFS= read -r path; do
   107	    case "$path" in
   108	      releases.sql|releases.db) touched_ledger=1 ;;
   109	      ROADMAP-DASHBOARD.md)     touched_dashboard=1 ;;
   110	    esac
   111	  done < <(git -C "$REPO" diff --no-renames --name-only "$remote_sha" "$local_sha" 2>/dev/null)
   112	
   113	  if [ "$touched_ledger" -eq 1 ] && [ "$touched_dashboard" -eq 0 ]; then
   114	    # GH-257 Task 4: check whether regenerating ROADMAP-DASHBOARD.md produces drift or no diff.
   115	    # Run the diagnosis against a commit-pinned temporary projection of local_sha inside the
   116	    # private GUARD_ROOT_PHYS so uncommitted working-tree modifications do not skew the classification.
   117	    TMP_PROJ="$GUARD_ROOT_PHYS/proj-$local_sha"
   118	    mkdir -p "$TMP_PROJ"
   119	
   120	    drift_detected=1
   121	    if git -C "$REPO" archive "$local_sha" 2>/dev/null | tar -x -C "$TMP_PROJ" 2>/dev/null \
   122	       && [ -f "$TMP_PROJ/utils/roadmap-dashboard.sh" ]; then
   123	      if bash "$TMP_PROJ/utils/roadmap-dashboard.sh" --check >/dev/null 2>&1; then
   124	        drift_detected=0
   125	      else
   126	        drift_detected=1
   127	      fi
   128	    fi
   129	
   130	    if [ "$drift_detected" -eq 1 ]; then
   131	      cat >&2 <<'EOF'
   132	dashboard-staleness-guard: REFUSING the push — this range writes the roadmap ledger
   133	(releases.sql / releases.db) without regenerating ROADMAP-DASHBOARD.md, so the human-readable
   134	view would ship stale against the data under it (GH-243 / GH-169 item 3).
   135	
   136	Fix (one command, then commit the result into the same push):
   137	    bash utils/roadmap-dashboard.sh && git add ROADMAP-DASHBOARD.md && git commit -m "docs: regenerate roadmap dashboard"
   138	
   139	Bypass (deliberately loud, e.g. a WIP branch): git push --no-verify
   140	EOF
   141	    else
   142	      # The other legitimate no-diff case: a ledger change the dashboard cannot render.
   143	      # jog_queue rows have no dashboard projection, and a jog write's full dump fan-out is
   144	      # jog_queue + its op_receipts audit rows + the settings generation counter — none of
   145	      # which the dashboard renders (GH-315). If every changed data line targets exactly
   146	      # that set, allow; any other table's data change keeps the dropped-row refusal below.
   147	      non_jog_data=0
   148	      while IFS= read -r dline; do
   149	        case "$dline" in
   150	          '-'INSERT\ INTO\ jog_queue*|'+'INSERT\ INTO\ jog_queue*) ;;
   151	          '-'INSERT\ INTO\ op_receipts*|'+'INSERT\ INTO\ op_receipts*) ;;
   152	          *INSERT\ INTO\ settings*generation*) ;;
   153	          '-'INSERT\ INTO\ *|'+'INSERT\ INTO\ *) non_jog_data=1; break ;;
   154	        esac
   155	      done < <(git -C "$REPO" diff --no-renames "$remote_sha" "$local_sha" -- releases.sql 2>/dev/null)
   156	      if [ "$non_jog_data" -eq 0 ]; then
   157	        continue
   158	      fi
   159	      cat >&2 <<'EOF'
   160	dashboard-staleness-guard: REFUSING the push — this range writes the roadmap ledger
   161	(releases.sql / releases.db) without modifying ROADMAP-DASHBOARD.md, but regenerating the
   162	dashboard produces NO diff (GH-243 / GH-257).
   163	
   164	This happens when a parked row was dropped by the renderer (e.g. malformed raw_text).
   165	To diagnose:
   166	    bash utils/roadmap-dashboard.sh
   167	and inspect stderr for warnings on dropped rows. Correct the row with:
   168	    releases roadmap update --issue-num <N> --raw-text "- **GH-<N> · <title>** ..."
   169	then regenerate and commit:
   170	    bash utils/roadmap-dashboard.sh && git add releases.db releases.sql ROADMAP-DASHBOARD.md && git commit -m "docs: fix roadmap row and regenerate dashboard"
   171	
   172	Bypass (deliberately loud, e.g. a WIP branch): git push --no-verify
   173	EOF
   174	    fi
   175	    exit 1
   176	  fi
   177	done
   178	
   179	exit 0
     1	#!/bin/bash
     2	# test/gh243-dashboard-staleness-guard.sh — the GH-243 push guard: a roadmap-ledger write without a
     3	# dashboard regeneration is refused, releases-mode only, and only when a real range exists.
     4	set -eu
     5	source test/_setup.sh "GH-243" || { echo "setup failed"; exit 1; }
     6	
     7	root="$(cd "$HERE/.." && pwd)"
     8	GUARD="$root/githooks/dashboard-staleness-guard.sh"
     9	
    10	# Fixture: a releases-mode repo with a base commit, then a ledger-only commit on top.
    11	R="$WORK/fixture"
    12	mkdir -p "$R"
    13	cd "$R"
    14	git init -q .
    15	git -c user.email=t@t -c user.name=t commit -q --allow-empty -m base
    16	echo "ROADMAP_SOURCE=releases" > .pdda-mode
    17	echo "-- dump v1" > releases.sql
    18	echo "dash v1" > ROADMAP-DASHBOARD.md
    19	git add .pdda-mode releases.sql ROADMAP-DASHBOARD.md
    20	git -c user.email=t@t -c user.name=t commit -q -m "v1"
    21	BASE="$(git rev-parse HEAD)"
    22	
    23	echo "-- dump v2" > releases.sql
    24	git add releases.sql
    25	git -c user.email=t@t -c user.name=t commit -q -m "ledger write, no dashboard"
    26	LEDGER_ONLY="$(git rev-parse HEAD)"
    27	cd "$root"
    28	
    29	# 1. Ledger write without dashboard -> refuse (exit 1) with the regen instruction.
    30	rc=0; out="$(bash "$GUARD" "$R" "$LEDGER_ONLY" "$BASE" 2>&1)" || rc=$?
    31	[ "$rc" -eq 1 ] || fail "expected refusal (1), got $rc"
    32	grep -q "roadmap-dashboard.sh" <<<"$out" || fail "refusal missing the regeneration instruction"
    33	
    34	# 2. Same range with the dashboard regenerated in it -> pass.
    35	cd "$R"
    36	echo "dash v2" > ROADMAP-DASHBOARD.md
    37	git add ROADMAP-DASHBOARD.md
    38	git -c user.email=t@t -c user.name=t commit -q -m "regen dashboard"
    39	FIXED="$(git rev-parse HEAD)"
    40	cd "$root"
    41	bash "$GUARD" "$R" "$FIXED" "$BASE" || fail "regenerated range should pass, got $?"
    42	
    43	# 3. Legacy-mode repo (no releases marker) -> guard is inert even on a ledger-only range.
    44	cd "$R"; : > .pdda-mode; cd "$root"
    45	bash "$GUARD" "$R" "$LEDGER_ONLY" "$BASE" || fail "legacy-mode repo must not be guarded, got $?"
    46	cd "$R"; echo "ROADMAP_SOURCE=releases" > .pdda-mode; cd "$root"
    47	
    48	# 4. New branch (all-zero remote sha) -> no range, no refusal.
    49	bash "$GUARD" "$R" "$LEDGER_ONLY" "0000000000000000000000000000000000000000" \
    50	  || fail "new-branch push must fall through, got $?"
    51	
    52	# 5. Non-ledger range (docs commit only) -> pass.
    53	cd "$R"
    54	echo "readme" > README.md
    55	git add README.md
    56	git -c user.email=t@t -c user.name=t commit -q -m docs
    57	DOCS="$(git rev-parse HEAD)"
    58	cd "$root"
    59	bash "$GUARD" "$R" "$DOCS" "$FIXED" || fail "non-ledger range must pass, got $?"
    60	
    61	# 6. Usage error -> exit 2.
    62	rc=0; bash "$GUARD" >/dev/null 2>&1 || rc=$?
    63	[ "$rc" -eq 2 ] || fail "expected usage exit 2, got $rc"
    64	
    65	
    66	# 7. GH-315: jog-queue-only ledger write, renderer in-sync, no dashboard change -> ALLOW
    67	# (jog rows have no dashboard projection; a no-diff regen is the expected outcome, not a
    68	# dropped-row symptom). The fixture needs a renderer whose --check passes to reach the
    69	# guard's no-drift branch at all.
    70	mkdir -p "$R/utils"
    71	printf '#!/usr/bin/env bash\nexit 0\n' > "$R/utils/roadmap-dashboard.sh"
    72	chmod +x "$R/utils/roadmap-dashboard.sh"
    73	cd "$R"
    74	git add utils/roadmap-dashboard.sh
    75	git -c user.email=t@t -c user.name=t commit -q -m "add passing renderer"
    76	RENDERED="$(git rev-parse HEAD)"
    77	{ echo "-- dump v3"
    78	  echo "INSERT INTO settings(key, value) VALUES('generation', '9');"
    79	  echo "INSERT INTO jog_queue VALUES('seed');"
    80	  echo "INSERT INTO op_receipts(op, target_gid) VALUES('jog-add', 'seed');"
    81	} > releases.sql
    82	git add releases.sql
    83	git -c user.email=t@t -c user.name=t commit -q -m "jog-only ledger write"
    84	JOG_ONLY="$(git rev-parse HEAD)"
    85	cd "$root"
    86	bash "$GUARD" "$R" "$JOG_ONLY" "$RENDERED" \
    87	  || fail "jog-queue-only ledger write must pass the no-drift branch (GH-315), got $?"
    88	
    89	# 8. Control: a roadmap_items data change in the same no-drift shape still refuses.
    90	cd "$R"
    91	{ echo "-- dump v4"; echo "INSERT INTO roadmap_items VALUES('r1');"; } > releases.sql
    92	git add releases.sql
    93	git -c user.email=t@t -c user.name=t commit -q -m "roadmap-only ledger write"
    94	ROADMAP_ONLY="$(git rev-parse HEAD)"
    95	cd "$root"
    96	rc=0; out="$(bash "$GUARD" "$R" "$ROADMAP_ONLY" "$RENDERED" 2>&1)" || rc=$?
    97	[ "$rc" -eq 1 ] || fail "expected no-drift refusal (1) for non-jog data, got $rc"
    98	grep -q "NO diff" <<<"$out" || fail "expected the no-diff refusal message"
    99	
   100	echo "== GH-243 ALL PASSED =="
     1	#!/usr/bin/env bash
     2	# utils/roadmap-dashboard.sh — render a read-only dashboard from ROADMAP.md (GH-27).
     3	
     4	set -euo pipefail
     5	
     6	HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
     7	# GH-272: releases-merge-resolve.sh drives this renderer against a --root TARGET repo —
     8	# the ledger it renders and the dashboard it writes must follow the target, not this
     9	# script's own checkout. Self-location stays the default for every other caller.
    10	ROOT="${ROADMAP_DASHBOARD_ROOT:-$(cd "$HERE/.." && pwd)}"
    11	SOURCE_FILE="${ROADMAP_DASHBOARD_SOURCE:-"$ROOT/ROADMAP.md"}"
    12	OUTPUT_FILE="${ROADMAP_DASHBOARD_OUTPUT:-"$ROOT/ROADMAP-DASHBOARD.md"}"
    13	
    14	usage() {
    15	  cat <<'EOF'
    16	Usage: bash utils/roadmap-dashboard.sh [--check]
    17	
    18	  Default: render ROADMAP-DASHBOARD.md from the canonical root ROADMAP.md.
    19	  --check: exit 0 when ROADMAP-DASHBOARD.md is in sync; non-zero on drift.
    20	EOF
    21	}
    22	
    23	MODE="write"
    24	if (($# > 1)); then
    25	  usage
    26	  exit 2
    27	fi
    28	if (($# == 1)); then
    29	  case "$1" in
    30	    --check) MODE="check" ;;
    31	    --help|-h) usage; exit 0 ;;
    32	    *) usage; exit 2 ;;
    33	  esac
    34	fi
    35	
    36	command -v node >/dev/null 2>&1 || {
    37	  echo "roadmap-dashboard: node is required" >&2
    38	  exit 2
    39	}
    40	
    41	TMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/roadmap-dashboard.XXXXXX")"
    42	trap 'rm -rf "$TMP_DIR"' EXIT
    43	RENDERED="$TMP_DIR/ROADMAP-DASHBOARD.md"
    44	
    45	# GH-243: in a releases-mode repo the DB is the roadmap's source of truth and ROADMAP.md is
    46	# frozen — render from `roadmap list --json` (each row's lossless raw_text under its section)
    47	# instead of the legacy file. An explicit ROADMAP_DASHBOARD_SOURCE still wins (test seam), and
    48	# any failure here falls back to the legacy file rather than emitting an empty dashboard.
    49	if [ -z "${ROADMAP_DASHBOARD_SOURCE:-}" ] \
    50	   && (grep -q "ROADMAP_SOURCE=releases" "$ROOT/.pdda-mode" 2>/dev/null || [ ! -f "$ROOT/ROADMAP.md" ]) \
    51	   && [ -f "$ROOT/releases.db" ] && command -v python3 >/dev/null 2>&1; then
    52	  DB_SRC="$TMP_DIR/roadmap-from-db.md"
    53	  DB_JSON="$TMP_DIR/roadmap-rows.json"
    54	  # JSON goes through a temp file passed as argv — `python3 -` takes its PROGRAM from the
    55	  # heredoc on stdin, so piping data in as well would feed the parser nothing (the PR #240
    56	  # rollup.sh bug, same shape). The APP resolves from HERE (this script's own checkout) while
    57	  # --root follows $ROOT: under ROADMAP_DASHBOARD_ROOT (GH-272) the target repo may ship the
    58	  # ledger without a utils/ tree at all.
    59	  if python3 "$HERE/py/releases_app.py" --root "$ROOT" roadmap list --json > "$DB_JSON" 2>/dev/null \
    60	     && python3 - "$DB_JSON" > "$DB_SRC" <<'PY'
    61	import json, sys
    62	with open(sys.argv[1]) as f:
    63	    rows = json.load(f)
    64	print("# ROADMAP (rendered from the RELEASES DB — GH-243; ROADMAP.md is frozen legacy)\n")
    65	print("## Ledger\n")   # the renderer only counts sections below this heading
    66	sections = {}
    67	for r in rows:
    68	    sections.setdefault(r.get("section") or "(unsectioned)", []).append(r)
    69	for section, items in sections.items():
    70	    print(f"### {section}\n")
    71	    for r in sorted(items, key=lambda x: x.get("position") or 0):
    72	        line = (r.get("raw_text") or "").strip()
    73	        if not line:
    74	            gh = f"GH-{r['gh_number']} · " if r.get("gh_number") is not None else ""
    75	            line = f"- **{gh}{r.get('title', '')}**"
    76	        print(line)
    77	    print()
    78	PY
    79	  then
    80	    [ -s "$DB_SRC" ] && SOURCE_FILE="$DB_SRC"
    81	  fi
    82	fi
    83	
    84	if [ ! -f "$SOURCE_FILE" ]; then
    85	  echo "roadmap-dashboard: source not found: $SOURCE_FILE" >&2
    86	  exit 3
    87	fi
    88	
    89	node - "$SOURCE_FILE" >"$RENDERED" <<'NODE'
    90	const fs = require("fs");
    91	
    92	const sourcePath = process.argv[2];
    93	const raw = fs.readFileSync(sourcePath, "utf8");
    94	const lines = raw.split(/\r?\n/);
    95	
    96	const banner = "<!-- GENERATED by utils/roadmap-dashboard.sh — DO NOT EDIT; edit ROADMAP.md -->";
    97	const ledgerSections = [
    98	  "Queue / parked intake",
    99	  "Queue",              // GH-243: early `releases roadmap add` rows parked under the short name
   100	  "In progress",
   101	  "Completed",
   102	  "Deferred · vision",
   103	];
   104	const knownStatuses = ["🟢", "🟡", "⏸️", "⛔", "✅", "🔮", "🔲"];
   105	const extraStatuses = ["⚠️"];
   106	
   107	function escapeCell(value) {
   108	  return String(value)
   109	    .replace(/\|/g, "\\|")
   110	    .replace(/</g, "&lt;")
   111	    .replace(/>/g, "&gt;");
   112	}
   113	
   114	function stripMarkdown(value) {
   115	  return value
   116	    .replace(/`([^`]+)`/g, "$1")
   117	    .replace(/\*\*([^*]+)\*\*/g, "$1")
   118	    .replace(/\*([^*]+)\*/g, "$1")
   119	    .replace(/\[([^\]]+)\]\(([^)]+)\)/g, "$1")
   120	    .trim();
   121	}
   122	
   123	function parseBullet(block) {
   124	  const text = block.map((line) => line.trim()).join(" ").replace(/\s+/g, " ").trim();
   125	  const titleMatch = text.match(/^- \*\*(.+?)\*\*/);
   126	  const title = titleMatch ? stripMarkdown(titleMatch[1]) : stripMarkdown(text.replace(/^- /, ""));
   127	
   128	  let status = "—";
   129	  for (const emoji of knownStatuses.concat(extraStatuses)) {
   130	    if (text.includes(emoji)) {
   131	      status = emoji;
   132	      break;
   133	    }
   134	  }
   135	
   136	  const links = [];
   137	  const linkPattern = /\[([^\]]+)\]\(([^)]+)\)/g;
   138	  let match;
   139	  while ((match = linkPattern.exec(text)) !== null) {
   140	    links.push(`[${match[1]}](${match[2]})`);
   141	  }
   142	
   143	  return { title, status, links };
   144	}
   145	
   146	function formatTally(items) {
   147	  const counts = new Map();
   148	  for (const emoji of knownStatuses) counts.set(emoji, 0);
   149	  const extras = [];
   150	
   151	  for (const item of items) {
   152	    if (counts.has(item.status)) {
   153	      counts.set(item.status, counts.get(item.status) + 1);
   154	      continue;
   155	    }
   156	    if (item.status !== "—") {
   157	      if (!counts.has(item.status)) extras.push(item.status);
   158	      counts.set(item.status, (counts.get(item.status) || 0) + 1);
   159	    }
   160	  }
   161	
   162	  const ordered = knownStatuses.slice();
   163	  for (const emoji of extras) {
   164	    if (!ordered.includes(emoji)) ordered.push(emoji);
   165	  }
   166	
   167	  return ordered.map((emoji) => `${emoji} ${counts.get(emoji) || 0}`).join(" · ");
   168	}
   169	
   170	const sections = new Map();
   171	for (const heading of ledgerSections) sections.set(heading, []);
   172	
   173	let inLedger = false;
   174	let currentSection = null;
   175	const droppedRows = [];
   176	
   177	for (let i = 0; i < lines.length; i++) {
   178	  const line = lines[i];
   179	
   180	  if (!inLedger) {
   181	    if (/^##\s+Ledger\s*$/.test(line.trim())) inLedger = true;
   182	    continue;
   183	  }
   184	
   185	  if (/^##\s+/.test(line) && !/^##\s+Ledger\s*$/.test(line.trim())) break;
   186	
   187	  const sectionMatch = line.match(/^###\s+(.+?)\s*$/);
   188	  if (sectionMatch) {
   189	    const heading = sectionMatch[1].trim();
   190	    currentSection = sections.has(heading) ? heading : null;
   191	    continue;
   192	  }
   193	
   194	  if (!currentSection) continue;
   195	
   196	  const trimmed = line.trim();
   197	  if (!trimmed || trimmed.startsWith("<!--") || trimmed.startsWith("#")) continue;
   198	
   199	  if (!/^- \*\*[^\r\n*]+?\*\*/.test(line)) {
   200	    // GH-257: track non-empty dropped/unparseable line under an active ledger section
   201	    const issueMatch = trimmed.match(/(?:GH-?|#)(\d+)/i);
   202	    const id = issueMatch ? `#${issueMatch[1]}` : JSON.stringify(trimmed.length > 30 ? trimmed.slice(0, 30) + "..." : trimmed);
   203	    droppedRows.push({ section: currentSection, id, line: trimmed });
   204	    continue;
   205	  }
   206	
   207	  const block = [line];
   208	  while (i + 1 < lines.length) {
   209	    const next = lines[i + 1];
   210	    if (/^###\s+/.test(next) || /^##\s+/.test(next) || /^\s*[-*+]\s+/.test(next)) break;
   211	    block.push(next);
   212	    i += 1;
   213	  }
   214	  sections.get(currentSection).push(parseBullet(block));
   215	}
   216	
   217	if (droppedRows.length > 0) {
   218	  const ids = droppedRows.map((d) => d.id).join(", ");
   219	  process.stderr.write(`roadmap-dashboard: warning: dropped ${droppedRows.length} unparseable row(s): ${ids}\n`);
   220	}
   221	
   222	const output = [];
   223	output.push(banner);
   224	output.push("");
   225	output.push("# ROADMAP Dashboard");
   226	output.push("");
   227	output.push("Read-only derived view of the root [ROADMAP.md](ROADMAP.md) ledger.");
   228	output.push("");
   229	
   230	for (const heading of ledgerSections) {
   231	  const items = sections.get(heading) || [];
   232	  output.push(`## ${heading}`);
   233	  output.push("");
   234	  output.push(`Summary: ${items.length} items | Tally: ${formatTally(items)}`);
   235	  output.push("");
   236	  output.push("| Item | Status | Links |");
   237	  output.push("| --- | --- | --- |");
   238	  for (const item of items) {
   239	    const links = item.links.length > 0 ? item.links.join(" · ") : "—";
   240	    output.push(`| ${escapeCell(item.title)} | ${escapeCell(item.status)} | ${links} |`);
   600	  section TEXT NOT NULL CHECK (length(trim(section)) > 0),
   601	  position INTEGER NOT NULL,                -- order within its section at last sync
   602	  status_marker TEXT,                       -- the entry's leading status emoji, when present
   603	  complexity INTEGER, risk INTEGER, effort INTEGER,     -- cx/risk/eff when the entry states them
   604	  doc_path TEXT,                            -- first PROJECT/** link
   605	  issue_url TEXT,                           -- first this-repo issue/PR URL
   606	  raw_text TEXT NOT NULL,                   -- the entry block VERBATIM (lossless shadow)
   607	  first_seen TEXT NOT NULL,
   608	  updated_at TEXT NOT NULL,                 -- last sync that CHANGED this row (not last sync run)
   609	  UNIQUE (repo_id, gh_number)
   610	);
   611	CREATE INDEX IF NOT EXISTS idx_roadmap_repo ON roadmap_items(repo_id);
   612	""".format(rmi_gid=_gid_check("global_id", "rmi-"))
   613	
   614	
   615	def _ddl_statements(script):
   616	    """Split a trigger-free DDL script into individual statements.
   617	
   618	    GH-111: exists so migrations can avoid executescript(), which commits the caller's
   619	    transaction. Deliberately NOT general — it would mis-split a CREATE TRIGGER body, whose
   620	    BEGIN…END contains its own semicolons. Only trigger-free scripts may use it; migration
   621	    004 issues its trigger DDL as explicit single execute() calls instead.
   622	    """
   623	    if "CREATE TRIGGER" in script.upper():
   624	        raise ValueError("_ddl_statements cannot split trigger bodies; issue them individually")
   625	    # sqlite3.complete_statement() is comment- and string-literal-aware; a naive split(";")
   626	    # cuts mid-statement on the first `--` comment containing a semicolon.
   627	    statements, buffer = [], ""
   628	    for line in script.splitlines(keepends=True):
   629	        buffer += line
   630	        if sqlite3.complete_statement(buffer):
   631	            statements.append(buffer.strip())
   632	            buffer = ""
   633	    if buffer.strip():
   634	        statements.append(buffer.strip())
   635	    return statements
   636	
   637	
   638	def _table_exists(conn, name):
   639	    return conn.execute("SELECT 1 FROM sqlite_master WHERE type='table' AND name=?",
   640	                        (name,)).fetchone() is not None
   641	
   642	
   643	def _col(row, name, default=None):
   644	    """Read a column that may not exist yet on an un-migrated ledger. sqlite3.Row raises
   645	    IndexError for an absent key, so a bare row["baseline_count"] would turn "you have not run
   646	    `releases migrate`" into a traceback."""
   647	    try:
   648	        return row[name]
   649	    except (IndexError, KeyError):
   650	        return default
   651	
   652	
   653	def _has_column(conn, table, column):
   654	    """Schema probe. The dump writer uses it so a PRE-migration database can still be dumped
   655	    (and therefore digested) — `perform_migration` needs `business_digest` on the old shape
   656	    before it touches anything, and the dump grammar's absent-trailing-fields-read-as-NULL rule
   657	    makes the shorter record a legal dump rather than a lossy one."""
   658	    if not _table_exists(conn, table):
   659	        return False
   660	    return any(r["name"] == column for r in conn.execute("PRAGMA table_info(%s)" % table))
   661	
   662	
   663	def _ensure_roadmap_schema(conn, stamp=True):
   664	    """Apply migration 002 idempotently. MUST run inside a perform_write mutate when the DB
   665	    predates it: the new schema_migrations row is business state, and a schema change outside a
   666	    receipt would trip check's receipt-vs-change bypass detection — correctly.
   667	
   668	    GH-111: issued as individual execute() calls, NOT executescript(). Python's sqlite3
   669	    COMMITs any open transaction before running a script, so the old idiom would silently
   670	    split perform_migration()'s single transaction when 002 and 004 are both pending —
   671	    leaving 002 durable after a 004 failure while the journal still claims all-or-nothing.
   672	
   673	    stamp=False is the REGISTRY entry point: `apply_migrations` owns the ledger row there, and
   674	    `_rebuild` calls it with stamping suppressed entirely so it can write the ledger itself
   675	    afterwards. A self-stamping callback would collide with that on the primary key.
   676	    """
   677	    for statement in _ddl_statements(MIGRATION_002_DDL):
   678	        conn.execute(statement)
   679	    if stamp and conn.execute("SELECT 1 FROM schema_migrations WHERE version = 2").fetchone() is None:
   680	        conn.execute("INSERT INTO schema_migrations(version, applied_at) VALUES (2, ?)",
   681	                     (now_iso(),))
   682	
   683	
   684	MIGRATION_004_ITEMS_NEW = """
   685	CREATE TABLE manifest_items_new (
   686	  id INTEGER PRIMARY KEY,
   687	  global_id TEXT NOT NULL UNIQUE {mfi_gid},
   688	  release_id INTEGER NOT NULL REFERENCES releases(id),
   689	  issue_ref_id INTEGER NOT NULL REFERENCES issue_refs(id),
   690	  state TEXT NOT NULL CHECK (state IN ('dialed_in','shipped','cut')),
   691	  dialed_in_at TEXT,
   692	  dial_reason TEXT,
   693	  marathon_id INTEGER REFERENCES marathons(id)
   694	)"""
   695	
   696	MIGRATION_004_EVENTS_NEW = """
   697	CREATE TABLE manifest_state_events_new (
   698	  id INTEGER PRIMARY KEY,
   699	  item_id INTEGER NOT NULL REFERENCES manifest_items(id),
   700	  from_state TEXT NOT NULL CHECK (from_state IN ('open','dialed_in','shipped','cut')),
   701	  to_state   TEXT NOT NULL CHECK (to_state   IN ('open','dialed_in','shipped','cut')),
   702	  at TEXT NOT NULL,
   703	  reason TEXT NOT NULL CHECK (length(trim(reason)) > 0)
   704	)"""
   705	
   706	
   707	def _migration_004(conn):
   708	    """GH-111: retire FREEZE for DIALED-IN membership.
   709	
   710	    TRANSACTION-SAFE BY CONSTRUCTION — every statement goes through execute(), never
   711	    executescript(), which would COMMIT the caller's transaction and silently void
   712	    perform_migration()'s FK bracket, rollback, digest chain and receipt coupling.
   713	
   714	    Parent (manifest_items) is rebuilt before child (manifest_state_events), and `id`
   715	    values are carried across verbatim so the child's item_id linkage — and with it the
   716	    event digest chain — still resolves. Both CHECK vocabularies change, which SQLite
   717	    cannot do in place, hence the rebuilds. `open` stays legal in the EVENT table forever:
   718	    historical rows are copied unchanged rather than remapped, because rewriting them
   719	    would be the silent history edit this repo forbids everywhere else.
   720	    """
   721	    # ── parent: manifest_items ────────────────────────────────────────────────────────
   722	    conn.execute(MIGRATION_004_ITEMS_NEW.format(mfi_gid=_gid_check("global_id", "mfi-")))
   723	    conn.execute("""INSERT INTO manifest_items_new
   724	                      (id, global_id, release_id, issue_ref_id, state,
   725	                       dialed_in_at, dial_reason, marathon_id)
   726	                    SELECT id, global_id, release_id, issue_ref_id,
   727	                           CASE state WHEN 'open' THEN 'dialed_in' ELSE state END,
   728	                           NULL, NULL, NULL
   729	                      FROM manifest_items""")
   730	    conn.execute("DROP TABLE manifest_items")
  2440	                       "issue %r is not in release %s's manifest" % (value, args.gid))
  2441	
  2442	            # Un-shipping must not manufacture the very contradiction it exists to remove: if a live
  2443	            # row already sits beside the shipped one (GH-111 dropped UNIQUE(release_id,
  2444	            # issue_ref_id), so it can), retracting would leave TWO dialed_in rows.
  2445	            existing = conn.execute("""SELECT 1 FROM manifest_items
  2446	                                       WHERE release_id=? AND issue_ref_id=? AND state='dialed_in'
  2447	                                         AND id != ?""",
  2448	                                    (rel["id"], ref["id"], item["id"])).fetchone()
  2449	            if existing:
  2450	                refuse("manifest-duplicate",
  2451	                       "issue is already dialed into this release as dialed_in; unship would "
  2452	                       "create a duplicate live row")
  2453	
  2454	            held = conn.execute("""SELECT r.global_id, r.codename FROM manifest_items mi
  2455	                                   JOIN releases r ON r.id = mi.release_id
  2456	                                   WHERE mi.issue_ref_id = ? AND mi.release_id != ?
  2457	                                     AND mi.state = 'dialed_in'""",
  2458	                                (ref["id"], rel["id"])).fetchall()
  2459	            if held:
  2460	                refuse("dialed-in-elsewhere",
  2461	                       "issue is already dialed into %s — a task belongs to ONE release at a time."
  2462	                       % (", ".join("%s (%s)" % (h["global_id"], h["codename"] or "?")
  2463	                                    for h in held)))
  2464	
  2465	            if (item["state"], "dialed_in") not in LEGAL_ITEM_TRANSITIONS:
  2466	                refuse("transition",
  2467	                       "cannot move an item from %r to 'dialed_in' (legality is CLI-enforced)"
  2468	                       % item["state"])
  2469	
  2470	            if _has_column(conn, "manifest_items", "updated_at"):
  2471	                conn.execute("UPDATE manifest_items SET state='dialed_in', updated_at=? WHERE id=?",
  2472	                             (now_iso(), item["id"]))
  2473	            else:
  2474	                conn.execute("UPDATE manifest_items SET state='dialed_in' WHERE id=?",
  2475	                             (item["id"],))
  2476	            # item state and its event land in ONE transaction, matching ship/cut: a direct writer
  2477	            # that skips the event is caught by the digest chain.
  2478	            conn.execute("""INSERT INTO manifest_state_events(item_id, from_state, to_state, at,
  2479	                            reason) VALUES (?, 'shipped', 'dialed_in', ?, ?)""",
  2480	                         (item["id"], now_iso(), reason))
  2481	            print("manifest item %s un-shipped (shipped -> dialed_in); retraction event appended"
  2482	                  % item["global_id"])
  2483	
  2484	        perform_write(root, conn, "manifest-unship", args.gid, mutate)
  2485	    finally:
  2486	        conn.close()
  2487	
  2488	def cmd_marathon_add(args):
  2489	    root = resolve_root(args.root)
  2490	    paths = artifact_paths(root)
  2491	    conn = connect(paths["db"])
  2492	    try:
  2493	        gid = new_gid("mar-")
  2494	
  2495	        def mutate(conn):
  2496	            ref = issue_ref_for_token(conn, args.tracking_issue)
  2497	            repo_id = conn.execute("SELECT id FROM repos ORDER BY id LIMIT 1").fetchone()["id"]
  2498	            conn.execute("""INSERT INTO marathons(global_id, repo_id, tracking_ref_id, status,
  2499	                         created_at) VALUES (?, ?, ?, ?, ?)""",
  2500	                         (gid, repo_id, ref["id"], args.status, now_iso()))
  2501	            print("marathon %s added (status %s)" % (gid, args.status))
  2502	
  2503	        perform_write(root, conn, "marathon-add", gid, mutate)
  2504	    finally:
  2505	        conn.close()
  2506	
  2507	
  2508	def cmd_marathon_list(args):
  2509	    root = resolve_root(args.root)
  2510	    conn = connect(artifact_paths(root)["db"])
  2511	    try:
  2512	        for row in conn.execute("""SELECT m.global_id, m.status, m.created_at, t.url, t.temp_id
  2513	                                   FROM marathons m JOIN issue_refs t ON t.id = m.tracking_ref_id
  2514	                                   ORDER BY m.id"""):
  2515	            print("%s  %-9s  %s  %s" % (row["global_id"], row["status"], row["created_at"],
  2516	                                        row["url"] or row["temp_id"]))
  2517	    finally:
  2518	        conn.close()
  2519	
  2520	
  2521	def _repo_label(path):
  2522	    return os.path.basename(os.path.normpath(path))
  2523	
  2524	
  2525	def _aggregate_all_repos(root, conn):
  2526	    """v1 aggregation surface: this DB plus RELEASES_APP_EXTRA_DBS (colon-separated). The
  2527	    Phase-3 cockpit card reads the hq registry instead; until then this is the testable reader.
  2528	    Duplicate global IDs across DBs fail the aggregation LOUDLY, never merge silently (PRD)."""
  2529	    extra = [p for p in os.environ.get("RELEASES_APP_EXTRA_DBS", "").split(":") if p]
  2530	    seen = {}
  2531	    for r in conn.execute("SELECT global_id FROM releases"):
  2532	        seen.setdefault(r["global_id"], set()).add(_repo_label(root))
  2533	    for db_path in extra:
  2534	        if not os.path.exists(db_path):
  2535	            refuse("extra-db-missing", "RELEASES_APP_EXTRA_DBS entry %s does not exist" % db_path)
  2536	        econn = connect(db_path)
  2537	        try:
  2538	            for r in econn.execute("SELECT global_id FROM releases"):
  2539	                seen.setdefault(r["global_id"], set()).add(_repo_label(os.path.dirname(db_path)))
  2540	        finally:
  2930	
  2931	def _is_ledger_bullet(line):
  2932	    """A ledger entry opener: a bold bullet or a link bullet, never a task-list checkbox."""
  2933	    if line.startswith("- **"):
  2934	        return True
  2935	    return line.startswith("- [") and not _ROADMAP_TASKBOX_RE.match(line)
  2936	
  2937	
  2938	def _roadmap_gh_number(title):
  2939	    """The GH number a ledger entry is keyed by, or None. Anchored at the head of the title."""
  2940	    if _ROADMAP_MULTI_KEY_RE.match(title):
  2941	        return None
  2942	    m = _ROADMAP_KEY_RE.match(title)
  2943	    return int(m.group(1)) if m else None
  2944	
  2945	
  2946	# A scheme in a markdown link target: `https:`, `mailto:`, or a Windows drive prefix `C:`. Any of
  2947	# these means the target is not a repo-relative path, whatever it ends with.
  2948	_DOC_SCHEME_RE = re.compile(r"^[A-Za-z][A-Za-z0-9+.-]*:")
  2949	
  2950	
  2951	def _doc_pointer(target):
  2952	    """The repo-relative document path a link target names, or None.
  2953	
  2954	    The `doc_path` column is a path a consumer resolves against the filesystem, so an absolute
  2955	    URL, a mail address or a drive-lettered path in it yields a miss indistinguishable from a
  2956	    dead pointer. codex QA found the first cut let all three through, because the extraction
  2957	    regexes accepted any `.md`-suffixed target and this check was only consulted on the fallback
  2958	    branch. It is now the SINGLE validator every candidate passes through, whichever regex found
  2959	    it — a scheme-bearing `https://github.com/acme/specs/blob/main/DESIGN.md` is rejected here
  2960	    even though it ends `.md`."""
  2961	    if not target:
  2962	        return None
  2963	    target = target.strip()
  2964	    if not target:
  2965	        return None
  2966	    if _DOC_SCHEME_RE.match(target) or target.startswith("/") or "\\" in target:
  2967	        return None
  2968	    path = target.split("#", 1)[0].split("?", 1)[0]
  2969	    return path if path.endswith(".md") else None
  2970	
  2971	
  2972	def _roadmap_issue_url(raw, link_target, gh_number):
  2973	    """The URL a ledger entry is keyed to, or None.
  2974	
  2975	    Exactly two things count as evidence of identity: the bullet's OWN link target, and a URL in
  2976	    the block whose number corroborates the title's GH key. Nothing else — an unanchored search
  2977	    keyed GH-94 to a DIFFERENT repo's issue #2 and GH-68 to a PR, because both hooks cite other
  2978	    work in passing.
  2979	
  2980	    An earlier cut kept a third branch for UNKEYED entries: the first URL on the bullet's first
  2981	    line. codex QA showed that branch is wrong on the reporting repo's live data, where it stored
  2982	    a BLOCKER as the row's identity — `Grow Willies …` took #42 (a blocker that has its own ledger
  2983	    row) and `Marathon Plan 2026-07-07 …` took #47 (merely its only fireable lane). Being first is
  2984	    not evidence. An unkeyed entry whose own link is a document now stores nothing.
  2985	
  2986	    Position never implies identity here: no URL beats a wrong URL."""
  2987	    if link_target:
  2988	        target = link_target.strip()
  2989	        m = ROADMAP_URL_RE.fullmatch(target)
  2990	        if m:
  2991	            num = int(target.rsplit("/", 1)[1])
  2992	            if gh_number is None or num == gh_number:
  2993	                return m.group(0)
  2994	    if gh_number is None:
  2995	        return None
  2996	    for cand in ROADMAP_URL_RE.findall(raw):
  2997	        if int(cand.rsplit("/", 1)[1]) == gh_number:
  2998	            return cand
  2999	    return None
  3000	
  3001	
  3002	def parse_roadmap_ledger(path):
  3003	    """ROADMAP.md -> [entry dict], file order. Same block boundaries as the planner: an entry runs
  3004	    from its bullet line (`- **` or `- [`) to the next bullet, `###`, or `##`."""
  3005	    lines = open(path, encoding="utf-8").read().splitlines()
  3006	    entries = []
  3007	    sec = None
  3008	    inledger = False
  3009	    pos = {}
  3010	    i, n = 0, len(lines)
  3090	               "malformed --raw-text: raw_text must be a single line (no newlines permitted)")
  3091	    stripped = raw_text.strip()
  3092	    if not re.match(r'^- \*\*[^\r\n*]+?\*\*', stripped):
  3093	        refuse("invalid-raw-text",
  3094	               "malformed --raw-text %r: expected markdown bullet starting with '- **<title>**' "
  3095	               "(e.g. '- **GH-%s · <title>** ...')" % (raw_text, str(issue_num) if issue_num else "<num>"))
  3096	    if issue_num is not None:
  3097	        gh_patterns = [r'\bGH-%d\b' % issue_num, r'#%d\b' % issue_num]
  3098	        if not any(re.search(p, raw_text) for p in gh_patterns):
  3099	            refuse("invalid-raw-text",
  3100	                   "malformed --raw-text: does not reference issue GH-%d / #%d" % (issue_num, issue_num))
  3101	    return stripped
  3102	
  3103	
  3104	
  3105	def cmd_roadmap_add(args):
  3106	    root = resolve_root(args.root)
  3107	    paths = artifact_paths(root)
  3108	    conn = connect(paths["db"])
  3109	    try:
  3110	        basename = os.path.basename(args.doc_path)
  3111	        # hq park passes the hq_roadmap_line rendering via --raw-text so preview and stored row
  3112	        # share ONE template; the inline fallback exists only for direct CLI use.
  3113	        if args.raw_text:
  3114	            raw_text = validate_raw_text(args.raw_text, args.issue_num)
  3115	        else:
  3116	            raw_text = "- **GH-%d · %s** 🆕 **captured %s via HQ** — [%s](%s) · [#%d](%s)" % (
  3117	                args.issue_num, args.title, args.created, basename, args.doc_path,
  3118	                args.issue_num, args.issue_url
  3119	            )
  3120	        # GH-249: the rating rides in the ledger line, parsed by the SAME parse_rating() the
  3121	        # markdown sync uses — one grammar, one parser, never a second scorer. Before this, ratings
  3122	        # could only enter through `roadmap sync`, which GH-169 turned into a no-op in releases-mode
  3123	        # repos, so every row parked after the flip was silently unrated.
  3124	        rating = parse_rating(raw_text, args.title)
  3125	
  3126	        if args.dry_run:
  3127	            print("ROADMAP line: %s" % raw_text)
  3128	            if rating["rating_pri"] is not None:
  3129	                print("rating: %s" % "/".join(str(rating[c]) for c in RATING_COLUMNS[:4]))
  3130	                if rating["rating_ovr"] is not None:
  3131	                    print("ovr: %d" % rating["rating_ovr"])
  3132	            return
  3133	
  3134	        # Dup guard — only when the shadow table exists; a pre-migration ledger gets the schema
  3135	        # installed inside mutate (mirrors cmd_roadmap_sync) instead of a raw OperationalError.
  3136	        if _table_exists(conn, "roadmap_items"):
  3137	            row = conn.execute("SELECT id FROM roadmap_items WHERE issue_url = ?", (args.issue_url,)).fetchone()
  3138	            if row:
  3139	                refuse("roadmap-duplicate", "issue %s is already parked in the roadmap" % args.issue_url)
  3140	
  3141	            row2 = conn.execute("SELECT id FROM roadmap_items WHERE gh_number = ?", (args.issue_num,)).fetchone()
  3142	            if row2:
  3143	                refuse("roadmap-duplicate", "issue GH-%d is already parked in the roadmap" % args.issue_num)
  3144	
  3145	        gid = new_gid("rmi-")
  3146	
  3147	        def mutate(conn):
  3148	            _ensure_roadmap_schema(conn)
  3149	            ts = now_iso()
  3150	            section = "Queue / parked intake"   # the canonical ledger queue heading (GH-243)
  3151	            max_pos = conn.execute("SELECT MAX(position) FROM roadmap_items WHERE section = ?", (section,)).fetchone()
  3152	            pos = (max_pos[0] or 0) + 1 if max_pos else 1
  3153	            
  3154	            repo = conn.execute("SELECT id FROM repos ORDER BY id LIMIT 1").fetchone()
  3155	            if not repo:
  3156	                refuse("no-repo", "the DB has no repos row; run `releases init` first")
  3157	            
  3158	            # Mirrors cmd_roadmap_sync: feature commands never self-migrate. A rated line meeting
  3159	            # a ledger with no rating columns is refused BY NAME rather than written with its
  3160	            # scores silently dropped — an unrated row is indistinguishable from "never scored".
  3161	            rating_ok = _has_column(conn, "roadmap_items", "rating_pri")
  3162	            if not rating_ok and rating["rating_pri"] is not None:
  3163	                refuse("schema-behind",
  3164	                       "GH-%d carries `rated` scores but this ledger has no rating columns. Run "
  3165	                       "`releases migrate` first — intake stores scores, it never installs schema."
  3166	                       % args.issue_num)
  3167	
  3168	            cols = ["global_id", "repo_id", "gh_number", "title", "section", "position",
  3169	                    "status_marker", "doc_path", "issue_url", "raw_text", "first_seen", "updated_at"]
  3170	            vals = [gid, repo["id"], args.issue_num, args.title, section, pos,
  3171	                    "🆕", args.doc_path, args.issue_url, raw_text, ts, ts]
  3172	            if rating_ok:
  3173	                cols += list(RATING_COLUMNS)
  3174	                vals += [rating[c] for c in RATING_COLUMNS]
  3175	            conn.execute("INSERT INTO roadmap_items(%s) VALUES (%s)"
  3176	                         % (", ".join(cols), ", ".join("?" * len(cols))), vals)
  3177	                          
  3178	        perform_write(root, conn, "roadmap-add", gid, mutate)
  3179	        print("added roadmap entry %s for GH-%d" % (gid, args.issue_num))
  3180	    finally:
  3181	        conn.close()
  3182	
  3183	def cmd_roadmap_rate(args):
  3184	    """GH-253: score a roadmap row that is already parked.
  3185	
  3186	    GH-249 taught intake to STORE a rating, but rows parked between the GH-169 flip and that fix
  3187	    were written unrated and had no path back — `roadmap add` only inserts, `roadmap sync` is a
  3188	    no-op in releases-mode, and nothing else writes the columns. That made "unrated" permanent for
  3189	    exactly the rows the bug created. This is the way back.
  3190	
  3250	        print("rated %s %s" % (label, args.rated))
  3251	    finally:
  3252	        conn.close()
  3253	
  3254	
  3255	def cmd_roadmap_repoint(args):
  3256	    """Re-point a parked row's capture doc after the doc moves between PROJECT stages.
  3257	
  3258	    `roadmap add` records doc_path once and refuses duplicates, and nothing else rewrites it — so
  3259	    promoting a doc 1-INBOX -> 2-WORKING left the row pointing at a path that no longer exists, and
  3260	    pdda-check-roadmap-coverage fails on it with no supported way to fix it.
  3261	
  3262	    The move itself stays a `git mv` by the operator: this verb only rewrites the row (and the
  3263	    dashboard regenerates separately via utils/roadmap-dashboard.sh), so the GH-243 ledger-with-
  3264	    dashboard guard sees a clean regeneration range on the next push.
  3265	    """
  3266	    root = resolve_root(args.root)
  3267	    conn = connect(artifact_paths(root)["db"])
  3268	    try:
  3269	        row = conn.execute("SELECT global_id, doc_path, raw_text FROM roadmap_items "
  3270	                           "WHERE gh_number = ?", (args.issue_num,)).fetchone()
  3271	        if not row:
  3272	            refuse("no-such-row", "no roadmap row for GH-%d" % args.issue_num)
  3273	        new = args.doc_path
  3274	        if not os.path.isfile(os.path.join(root, new)):
  3275	            refuse("no-such-doc", "%s does not exist under %s — re-point to a real doc, never a "
  3276	                                  "path that merely looks right" % (new, root))
  3277	        old = row["doc_path"]
  3278	        # The ledger line embeds the path too; rewriting one without the other just moves the drift.
  3279	        raw_text = row["raw_text"].replace(old, new) if old else row["raw_text"]
  3280	        if args.dry_run:
  3281	            print("doc_path: %s -> %s" % (old, new))
  3282	            print("ROADMAP line: %s" % raw_text)
  3283	            return
  3284	
  3285	        def mutate(conn):
  3286	            conn.execute("UPDATE roadmap_items SET doc_path = ?, raw_text = ?, updated_at = ? "
  3287	                         "WHERE gh_number = ?", (new, raw_text, now_iso(), args.issue_num))
  3288	
  3289	        perform_write(root, conn, "roadmap-repoint", row["global_id"], mutate)
  3290	        print("repointed GH-%d -> %s" % (args.issue_num, new))
  3291	    finally:
  3292	        conn.close()
  3293	
  3294	
  3295	def cmd_roadmap_update(args):
  3296	    """GH-257: update an existing parked roadmap row's raw_text.
  3297	
  3298	    `roadmap add` refuses duplicates, `rate` scores an existing row, and `repoint` moves doc_path.
  3299	    Nothing edited `raw_text` directly without manually editing releases.sql.
  3300	    This command closes that gap with a validated, receipt-backed update path.
  3301	    """
  3302	    root = resolve_root(args.root)
  3303	    paths = artifact_paths(root)
  3304	    conn = connect(paths["db"])
  3305	    try:
  3306	        if not _table_exists(conn, "roadmap_items"):
  3307	            refuse("no-ledger", "this DB has no roadmap_items table; run `releases migrate` first")
  3308	        if (args.issue_num is None) == (args.gid is None):
  3309	            refuse("selector", "pass exactly one of --issue-num or --gid")
  3310	        if args.issue_num is not None:
  3311	            where, param, label = "gh_number = ?", args.issue_num, "GH-%d" % args.issue_num
  3312	        else:
  3313	            where, param, label = "global_id = ?", args.gid, args.gid
  3314	
  3315	        has_rating_cols = _has_column(conn, "roadmap_items", "rating_pri")
  3316	        select_cols = ["global_id", "gh_number", "title", "raw_text"]
  3317	        row = conn.execute(
  3318	            "SELECT %s FROM roadmap_items WHERE %s" % (", ".join(select_cols), where), (param,)).fetchone()
  3319	        if not row:
  3320	            refuse("no-such-row", "no roadmap row for %s; park it with `roadmap add` first" % label)
  3321	
  3322	        if args.raw_text is None and args.section is None:
  3323	            refuse("no-update", "pass at least one of --raw-text or --section")
  3324	
  3325	        new_raw_text = None
  3326	        rating = None
  3327	        if args.raw_text is not None:
  3328	            new_raw_text = validate_raw_text(args.raw_text, row["gh_number"])
  3329	            old_raw_text = row["raw_text"] or ""
  3330	            if new_raw_text == old_raw_text.strip() and args.section is None:
  3331	                print("roadmap update: %s raw_text unchanged; nothing written" % label)
  3332	                return
  3333	            rating = parse_rating(new_raw_text, row["title"])
  3334	            if not has_rating_cols and rating["rating_pri"] is not None:
  3335	                refuse("schema-behind",
  3336	                       "this ledger has no rating columns. Run `releases migrate` first — rating "
  3337	                       "stores scores, it never installs schema.")
  3338	
  3339	        if args.dry_run:
  3340	            if args.raw_text is not None:
  3341	                print("raw_text: %s -> %s" % (old_raw_text, new_raw_text))
  3342	                if rating["rating_pri"] is not None:
  3343	                    print("rating: %s" % "/".join(str(rating[c]) for c in RATING_COLUMNS[:4]))
  3344	                    if rating["rating_ovr"] is not None:
  3345	                        print("ovr: %d" % rating["rating_ovr"])
  3346	            if args.section:
  3347	                print("section: -> %s" % args.section)
  3348	            return
  3349	
  3350	        def mutate(conn):
  3351	            ts = now_iso()
  3352	            updates = ["updated_at = ?"]
  3353	            params = [ts]
  3354	            if args.raw_text is not None:
  3355	                updates.append("raw_text = ?")
  3356	                params.append(new_raw_text)
  3357	                if has_rating_cols:
  3358	                    for c in RATING_COLUMNS:
  3359	                        updates.append("%s = ?" % c)
  3360	                        params.append(rating[c])
  3361	            if args.section is not None:
  3362	                updates.append("section = ?")
  3363	                params.append(args.section)
  3364	            
  3365	            params.append(param)
  3366	            conn.execute("UPDATE roadmap_items SET %s WHERE %s" % (", ".join(updates), where), params)
  3367	
  3368	        perform_write(root, conn, "roadmap-update", row["global_id"], mutate)
  3369	        print("updated %s" % label)
  3370	    finally:
  3371	        conn.close()
  3372	
  3373	
  3374	def cmd_roadmap_move(args):
  3375	    """GH-269: move a roadmap row to a new section (e.g. 'Completed', 'Deferred / cancelled')."""
  3376	    return cmd_roadmap_update(args)
  3377	
  3378	
  3535	                c.execute(upd_sql, [e[f] for f in fields] + [ts, row["id"]])
  3536	            for row in removes:
  3537	                c.execute("DELETE FROM roadmap_items WHERE id = ?", (row["id"],))
  3538	
  3539	        txn = perform_write(root, conn, "roadmap-sync", None, mutate)
  3540	        print(summary + " (txn %s, generation %d)" % (txn[:12], get_generation(conn)))
  3541	    finally:
  3542	        conn.close()
  3543	
  3544	
  3545	def cmd_roadmap_list(args):
  3546	    root = resolve_root(args.root)
  3547	    conn = connect(artifact_paths(root)["db"])
  3548	    try:
  3549	        if getattr(args, "as_json", False):
  3550	            # Machine-readable contract for consumers (hq rollup): the human rendering below is
  3551	            # a display, not an API — its column offsets shift whenever a field widens.
  3552	            rows = []
  3553	            if _table_exists(conn, "roadmap_items"):
  3554	                for r in conn.execute("SELECT * FROM roadmap_items ORDER BY section, position"):
  3555	                    rows.append({"global_id": r["global_id"], "gh_number": r["gh_number"],
  3556	                                 "title": r["title"], "section": r["section"],
  3557	                                 "position": r["position"], "status_marker": r["status_marker"],
  3558	                                 "doc_path": _col(r, "doc_path"), "issue_url": _col(r, "issue_url"),
  3559	                                 "raw_text": _col(r, "raw_text")})
  3560	            print(json.dumps(rows, ensure_ascii=False))
  3561	            return
  3562	        if not _table_exists(conn, "roadmap_items"):
  3563	            print("(no roadmap shadow yet — run `releases roadmap sync`)")
  3564	            return
  3565	        for r in conn.execute("""SELECT * FROM roadmap_items ORDER BY section, position"""):
  3566	            gh = ("GH-%d" % r["gh_number"]) if r["gh_number"] is not None else "-"
  3567	            cre = ("%s/%s/%s" % (r["complexity"], r["risk"], r["effort"])
  3568	                   if r["complexity"] is not None else "-")
  3569	            # calc is DERIVED here, never stored — the equal-weighted sum of the four axes, and
  3570	            # the override wins over it for ranking wherever both exist.
  3571	            score = "-"
  3572	            if _col(r, "rating_pri") is not None:
  3573	                calc = sum(_col(r, c) for c in RATING_COLUMNS[:4])
  3574	                score = str(calc)
  3575	                if _col(r, "rating_ovr") is not None:
  3576	                    score = "%s>%d" % (score, r["rating_ovr"])
  3577	            print("%s  %-7s %-22s #%-3d cre=%-6s calc=%-8s %s %s" % (
  3578	                r["global_id"], gh, (r["section"] or "")[:22], r["position"], cre, score,
  3579	                r["status_marker"] or " ", r["title"][:64]))
  3580	    finally:
  3581	        conn.close()
  3582	
  3583	
  3584	def resolve_issue_number(target):
  3585	    """Resolve a target string or int into a GitHub issue number (int)."""
  3586	    if isinstance(target, int):
  3587	        return target
  3588	    s = str(target).strip()
  3589	    if s.isdigit():
  3590	        return int(s)
githooks/dashboard-staleness-guard.sh:5:# WHY: since the ROADMAP_SOURCE=releases flip, ROADMAP-DASHBOARD.md is the ONLY human-readable
githooks/dashboard-staleness-guard.sh:109:      ROADMAP-DASHBOARD.md)     touched_dashboard=1 ;;
githooks/dashboard-staleness-guard.sh:114:    # GH-257 Task 4: check whether regenerating ROADMAP-DASHBOARD.md produces drift or no diff.
githooks/dashboard-staleness-guard.sh:133:(releases.sql / releases.db) without regenerating ROADMAP-DASHBOARD.md, so the human-readable
githooks/dashboard-staleness-guard.sh:137:    bash utils/roadmap-dashboard.sh && git add ROADMAP-DASHBOARD.md && git commit -m "docs: regenerate roadmap dashboard"
githooks/dashboard-staleness-guard.sh:161:(releases.sql / releases.db) without modifying ROADMAP-DASHBOARD.md, but regenerating the
githooks/dashboard-staleness-guard.sh:170:    bash utils/roadmap-dashboard.sh && git add releases.db releases.sql ROADMAP-DASHBOARD.md && git commit -m "docs: fix roadmap row and regenerate dashboard"
test/gh243-dashboard-staleness-guard.sh:18:echo "dash v1" > ROADMAP-DASHBOARD.md
test/gh243-dashboard-staleness-guard.sh:19:git add .pdda-mode releases.sql ROADMAP-DASHBOARD.md
test/gh243-dashboard-staleness-guard.sh:36:echo "dash v2" > ROADMAP-DASHBOARD.md
test/gh243-dashboard-staleness-guard.sh:37:git add ROADMAP-DASHBOARD.md
test/gh243-dashboard-staleness-guard.sh:89:# 8. Control: a roadmap_items data change in the same no-drift shape still refuses.
test/gh243-dashboard-staleness-guard.sh:91:{ echo "-- dump v4"; echo "INSERT INTO roadmap_items VALUES('r1');"; } > releases.sql
utils/roadmap-dashboard.sh:12:OUTPUT_FILE="${ROADMAP_DASHBOARD_OUTPUT:-"$ROOT/ROADMAP-DASHBOARD.md"}"
utils/roadmap-dashboard.sh:18:  Default: render ROADMAP-DASHBOARD.md from the canonical root ROADMAP.md.
utils/roadmap-dashboard.sh:19:  --check: exit 0 when ROADMAP-DASHBOARD.md is in sync; non-zero on drift.
utils/roadmap-dashboard.sh:43:RENDERED="$TMP_DIR/ROADMAP-DASHBOARD.md"
utils/roadmap-dashboard.sh:46:# frozen — render from `roadmap list --json` (each row's lossless raw_text under its section)
utils/roadmap-dashboard.sh:59:  if python3 "$HERE/py/releases_app.py" --root "$ROOT" roadmap list --json > "$DB_JSON" 2>/dev/null \
utils/py/releases_app.py:270:                           FROM releases r JOIN issue_refs t ON t.id = r.tracking_ref_id
utils/py/releases_app.py:464:CREATE TABLE issue_refs (          -- normalized issue reference: real URL XOR placeholder
utils/py/releases_app.py:475:CREATE TABLE marathons (
utils/py/releases_app.py:479:  tracking_ref_id INTEGER NOT NULL REFERENCES issue_refs(id),
utils/py/releases_app.py:495:  tracking_ref_id INTEGER NOT NULL REFERENCES issue_refs(id),
utils/py/releases_app.py:496:  marathon_id INTEGER REFERENCES marathons(id),
utils/py/releases_app.py:509:  issue_ref_id INTEGER NOT NULL REFERENCES issue_refs(id),
utils/py/releases_app.py:594:CREATE TABLE IF NOT EXISTS roadmap_items (  -- GH-69/GH-269: roadmap ledger.
utils/py/releases_app.py:611:CREATE INDEX IF NOT EXISTS idx_roadmap_repo ON roadmap_items(repo_id);
utils/py/releases_app.py:689:  issue_ref_id INTEGER NOT NULL REFERENCES issue_refs(id),
utils/py/releases_app.py:693:  marathon_id INTEGER REFERENCES marathons(id)
utils/py/releases_app.py:798:    """GH-108: the pri/sev/appeal/effort rating columns on roadmap_items.
utils/py/releases_app.py:813:        if _has_column(conn, "roadmap_items", column):
utils/py/releases_app.py:816:        conn.execute("ALTER TABLE roadmap_items ADD COLUMN %s INTEGER "
utils/py/releases_app.py:988:    _emit(w, "issue_refs", ["global_id", "url", "temp_id", "created_at"],
utils/py/releases_app.py:989:          _rows(conn, "SELECT global_id, url, temp_id, created_at FROM issue_refs ORDER BY id"))
utils/py/releases_app.py:991:    _emit(w, "marathons", ["global_id", "repo_gid", "tracking_ref_gid", "status", "created_at"],
utils/py/releases_app.py:994:                         FROM marathons m JOIN repos r ON r.id = m.repo_id
utils/py/releases_app.py:995:                         JOIN issue_refs t ON t.id = m.tracking_ref_id ORDER BY m.id"""))
utils/py/releases_app.py:1011:                    JOIN issue_refs t ON t.id = rel.tracking_ref_id
utils/py/releases_app.py:1012:                    LEFT JOIN marathons mar ON mar.id = rel.marathon_id ORDER BY rel.id"""
utils/py/releases_app.py:1024:                    JOIN issue_refs t ON t.id = mi.issue_ref_id{join} ORDER BY mi.id"""
utils/py/releases_app.py:1030:        mfi_join = " LEFT JOIN marathons mar ON mar.id = mi.marathon_id"
utils/py/releases_app.py:1070:    if _table_exists(conn, "roadmap_items"):
utils/py/releases_app.py:1082:                        FROM roadmap_items ri JOIN repos r ON r.id = ri.repo_id
utils/py/releases_app.py:1084:        if _has_column(conn, "roadmap_items", "rating_pri"):
utils/py/releases_app.py:1089:        _emit(w, "roadmap_items", rmi_cols, _rows(conn, rmi_select.format(extra=rmi_extra)))
utils/py/releases_app.py:1566:                               FROM releases rel JOIN issue_refs t ON t.id = rel.tracking_ref_id
utils/py/releases_app.py:1584:                                  JOIN issue_refs t ON t.id = mi.issue_ref_id
utils/py/releases_app.py:1698:    """Find or create the issue_refs row for a URL/TMP-/MIG- token (identity is the row, so
utils/py/releases_app.py:1702:    row = conn.execute("SELECT * FROM issue_refs WHERE %s = ?" % col, (value,)).fetchone()
utils/py/releases_app.py:1706:    conn.execute("INSERT INTO issue_refs(global_id, url, temp_id, created_at) "
utils/py/releases_app.py:1710:    return conn.execute("SELECT * FROM issue_refs WHERE global_id = ?", (gid,)).fetchone()
utils/py/releases_app.py:1998:                row = conn.execute("SELECT id FROM marathons WHERE global_id = ?",
utils/py/releases_app.py:2215:                mar = conn.execute("SELECT id FROM marathons WHERE global_id = ?",
utils/py/releases_app.py:2262:            ref = conn.execute("SELECT * FROM issue_refs WHERE %s = ?" % column,
utils/py/releases_app.py:2265:                refuse("unknown-issue", "no issue_refs row for %r" % value)
utils/py/releases_app.py:2297:            ref = conn.execute("SELECT * FROM issue_refs WHERE %s = ?" % column,
utils/py/releases_app.py:2300:                refuse("unknown-issue", "no issue_refs row for %r" % value)
utils/py/releases_app.py:2307:            mar = conn.execute("SELECT id FROM marathons WHERE global_id = ?",
utils/py/releases_app.py:2373:                ref = conn.execute("SELECT * FROM issue_refs WHERE url = ?", (value,)).fetchone()
utils/py/releases_app.py:2375:                ref = conn.execute("SELECT * FROM issue_refs WHERE temp_id = ?",
utils/py/releases_app.py:2378:                refuse("unknown-issue", "no issue_refs row for %r" % value)
utils/py/releases_app.py:2421:            ref = conn.execute("SELECT * FROM issue_refs WHERE %s = ?" % column,
utils/py/releases_app.py:2424:                refuse("unknown-issue", "no issue_refs row for %r" % value)
utils/py/releases_app.py:2498:            conn.execute("""INSERT INTO marathons(global_id, repo_id, tracking_ref_id, status,
utils/py/releases_app.py:2513:                                   FROM marathons m JOIN issue_refs t ON t.id = m.tracking_ref_id
utils/py/releases_app.py:2577:                               FROM releases rel JOIN issue_refs t ON t.id = rel.tracking_ref_id
utils/py/releases_app.py:2625:        ref = conn.execute("SELECT url, temp_id FROM issue_refs WHERE id = ?",
utils/py/releases_app.py:2642:                                JOIN issue_refs t ON t.id = mi.issue_ref_id
utils/py/releases_app.py:2807:# agents edit; this code only READS it and mirrors the ledger into roadmap_items. The parser is a
utils/py/releases_app.py:3136:        if _table_exists(conn, "roadmap_items"):
utils/py/releases_app.py:3137:            row = conn.execute("SELECT id FROM roadmap_items WHERE issue_url = ?", (args.issue_url,)).fetchone()
utils/py/releases_app.py:3141:            row2 = conn.execute("SELECT id FROM roadmap_items WHERE gh_number = ?", (args.issue_num,)).fetchone()
utils/py/releases_app.py:3151:            max_pos = conn.execute("SELECT MAX(position) FROM roadmap_items WHERE section = ?", (section,)).fetchone()
utils/py/releases_app.py:3161:            rating_ok = _has_column(conn, "roadmap_items", "rating_pri")
utils/py/releases_app.py:3175:            conn.execute("INSERT INTO roadmap_items(%s) VALUES (%s)"
utils/py/releases_app.py:3199:        if not _table_exists(conn, "roadmap_items"):
utils/py/releases_app.py:3200:            refuse("no-ledger", "this DB has no roadmap_items table; run `releases migrate` first")
utils/py/releases_app.py:3212:            "FROM roadmap_items WHERE " + where, (param,)).fetchone()
utils/py/releases_app.py:3215:        if not _has_column(conn, "roadmap_items", "rating_pri"):
utils/py/releases_app.py:3245:                "UPDATE roadmap_items SET raw_text = ?, updated_at = ?, %s WHERE %s"
utils/py/releases_app.py:3269:        row = conn.execute("SELECT global_id, doc_path, raw_text FROM roadmap_items "
utils/py/releases_app.py:3286:            conn.execute("UPDATE roadmap_items SET doc_path = ?, raw_text = ?, updated_at = ? "
utils/py/releases_app.py:3306:        if not _table_exists(conn, "roadmap_items"):
utils/py/releases_app.py:3307:            refuse("no-ledger", "this DB has no roadmap_items table; run `releases migrate` first")
utils/py/releases_app.py:3315:        has_rating_cols = _has_column(conn, "roadmap_items", "rating_pri")
utils/py/releases_app.py:3318:            "SELECT %s FROM roadmap_items WHERE %s" % (", ".join(select_cols), where), (param,)).fetchone()
utils/py/releases_app.py:3366:            conn.execute("UPDATE roadmap_items SET %s WHERE %s" % (", ".join(updates), where), params)
utils/py/releases_app.py:3416:            has_rows = bool(_table_exists(conn, "roadmap_items")
utils/py/releases_app.py:3417:                            and conn.execute("SELECT 1 FROM roadmap_items LIMIT 1").fetchone())
utils/py/releases_app.py:3426:                           "parsed 0 entries from %s (%s); refusing to delete roadmap_items%s"
utils/py/releases_app.py:3431:                n_rows = conn.execute("SELECT COUNT(*) FROM roadmap_items").fetchone()[0]
utils/py/releases_app.py:3469:        rating_ok = _has_column(conn, "roadmap_items", "rating_pri")
utils/py/releases_app.py:3477:        if _table_exists(conn, "roadmap_items"):
utils/py/releases_app.py:3478:            for r in conn.execute("SELECT * FROM roadmap_items WHERE repo_id = ?", (repo["id"],)):
utils/py/releases_app.py:3483:        schema_missing = not _table_exists(conn, "roadmap_items") or conn.execute(
utils/py/releases_app.py:3527:            ins_sql = "INSERT INTO roadmap_items(%s) VALUES (%s)" % (
utils/py/releases_app.py:3529:            upd_sql = "UPDATE roadmap_items SET %s, updated_at=? WHERE id=?" % (
utils/py/releases_app.py:3537:                c.execute("DELETE FROM roadmap_items WHERE id = ?", (row["id"],))
utils/py/releases_app.py:3553:            if _table_exists(conn, "roadmap_items"):
utils/py/releases_app.py:3554:                for r in conn.execute("SELECT * FROM roadmap_items ORDER BY section, position"):
utils/py/releases_app.py:3562:        if not _table_exists(conn, "roadmap_items"):
utils/py/releases_app.py:3565:        for r in conn.execute("""SELECT * FROM roadmap_items ORDER BY section, position"""):
utils/py/releases_app.py:3671:        has_rm = _table_exists(conn, "roadmap_items")
utils/py/releases_app.py:3678:                LEFT JOIN roadmap_items ri ON ri.gh_number = jq.gh_number
utils/py/releases_app.py:4210:            for r in conn.execute("""SELECT temp_id, created_at FROM issue_refs
utils/py/releases_app.py:4237:                                     JOIN issue_refs t ON t.id = mi.issue_ref_id
utils/py/releases_app.py:4309:# re.S: a dumped value may contain newlines (a roadmap_items raw_text, say). parse_dump
utils/py/releases_app.py:4467:    for row in tables.get("issue_refs", []):
utils/py/releases_app.py:4468:        cur = conn.execute("""INSERT INTO issue_refs(global_id, url, temp_id, created_at)
utils/py/releases_app.py:4474:    for row in tables.get("marathons", []):
utils/py/releases_app.py:4475:        cur = conn.execute("""INSERT INTO marathons(global_id, repo_id, tracking_ref_id, status,
utils/py/releases_app.py:4537:    for row in tables.get("roadmap_items", []):
utils/py/releases_app.py:4538:        conn.execute("""INSERT INTO roadmap_items(global_id, repo_id, gh_number, title, section,
utils/py/releases_app.py:4738:        roadmap_items = conn.execute("""
utils/py/releases_app.py:4740:            FROM roadmap_items 
utils/py/releases_app.py:4745:        for item in roadmap_items:
utils/py/releases_app.py:4796:                row = conn.execute("SELECT * FROM issue_refs WHERE temp_id = ?",
utils/py/releases_app.py:4799:                    refuse("unknown-temp-ref", "no issue_refs row carries temp id %r" % temp)
utils/py/releases_app.py:4800:                conn.execute("UPDATE issue_refs SET url = ?, temp_id = NULL WHERE id = ?",
utils/py/releases_app.py:4944:    sp_rs = rsub.add_parser("sync", help="mirror legacy ROADMAP.md's ledger into roadmap_items (one-way)")
utils/py/releases_app.py:4947:                       help="permit clearing roadmap_items when the ledger is genuinely empty. "

mcp: codebase-memory-mcp/search_graph started
mcp: codebase-memory-mcp/search_graph (completed)
mcp: codebase-memory-mcp/get_code_snippet started
mcp: codebase-memory-mcp/get_code_snippet (completed)
mcp: codebase-memory-mcp/get_code_snippet started
mcp: codebase-memory-mcp/get_code_snippet (completed)
mcp: codebase-memory-mcp/get_code_snippet started
mcp: codebase-memory-mcp/get_code_snippet (completed)
exec
/bin/zsh -lc "nl -ba utils/py/releases_app.py | sed -n '450,625p'
nl -ba utils/py/releases_app.py | sed -n '960,1100p'
nl -ba utils/py/releases_app.py | sed -n '1685,1720p'
nl -ba utils/py/releases_app.py | sed -n '2478,2522p'
nl -ba utils/roadmap-dashboard.sh | sed -n '84,230p'
rg -n \"dashboard-staleness-guard|dashboard staleness|staleness-guard\" . --glob '"'!releases.sql'"' --glob '"'!ROADMAP-DASHBOARD.md'"' --glob '"'!CHANGELOG.md'"'" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-55986-oe3a4_ye
 succeeded in 21ms:
./relay-system/2026-08-26/relay-gh257-roadmap-ledger-qa.md:15:- githooks/dashboard-staleness-guard.sh
./relay-system/2026-08-26/relay-gh257-roadmap-ledger-qa.md:23:4. Does `githooks/dashboard-staleness-guard.sh` distinguish between actionable drift vs the no-diff scenario when ledger changed but dashboard diff is empty, providing achievable remediation steps?
./relay-system/2026-08-26/relay-gh257-roadmap-ledger-qa.md:70:   is computed from `remote_sha`/`local_sha` at `githooks/dashboard-staleness-guard.sh:31-43`, but
./relay-system/2026-08-26/relay-gh257-roadmap-ledger-qa.md:101:   refusal.** The two messages branch at `githooks/dashboard-staleness-guard.sh:45-84`; the no-diff
./relay-system/2026-08-26/relay-gh257-roadmap-ledger-qa.md:151:   `githooks/dashboard-staleness-guard.sh:31-43`, but the branch-deciding `--check` at `:45-54`
./relay-system/2026-08-26/relay-gh257-roadmap-ledger-qa.md:194:   remedies at `githooks/dashboard-staleness-guard.sh:56-83` are materially clearer. Finding 2 is
./relay-system/2026-08-26/relay-gh257-roadmap-ledger-qa.md:211:   - Updated `githooks/dashboard-staleness-guard.sh` to project the `local_sha` commit into an ephemeral sandbox via `git archive "${local_sha:-HEAD}" | tar -x -C "$TMP_PROJ"`.
./relay-system/2026-08-26/relay-gh257-roadmap-ledger-qa.md:249:   The loop at `githooks/dashboard-staleness-guard.sh:31-43` aggregates `touched_ledger` and
./relay-system/2026-08-26/relay-gh257-roadmap-ledger-qa.md:260:   `githooks/dashboard-staleness-guard.sh:56-59` runs `--check` in `$REPO`. That restores the exact
./relay-system/2026-08-26/relay-gh257-roadmap-ledger-qa.md:269:   `githooks/dashboard-staleness-guard.sh:50-63` trusts `mktemp -d` output immediately at the
./relay-system/2026-08-26/relay-gh257-roadmap-ledger-qa.md:311:   - Updated `githooks/dashboard-staleness-guard.sh` to evaluate each `(local_sha, remote_sha)` pair independently rather than accumulating across all refs and checking only the last SHA.
./relay-system/2026-08-26/relay-gh257-roadmap-ledger-qa.md:315:   - Removed the fallback to mutable working-tree state in `githooks/dashboard-staleness-guard.sh`. Failed archives/projections fail closed (`drift_detected=1`).
./relay-system/2026-08-26/relay-gh257-roadmap-ledger-qa.md:338:   contract.** `githooks/dashboard-staleness-guard.sh:49-55` checks only that `mktemp` returned a
./relay-system/2026-08-26/relay-gh257-roadmap-ledger-qa.md:373:   `githooks/dashboard-staleness-guard.sh:29-45`, the projection uses that pair's `local_sha` at
./relay-system/2026-08-26/relay-gh257-roadmap-ledger-qa.md:391:   - Updated `githooks/dashboard-staleness-guard.sh` to resolve `TMP_PARENT` via `cd -P "${TMPDIR:-/tmp}" && pwd -P`.
./relay-system/2026-08-26/relay-gh257-roadmap-ledger-qa.md:414:   The physical-descendant check at `githooks/dashboard-staleness-guard.sh:54-59` correctly protects
./relay-system/2026-08-26/relay-gh257-roadmap-ledger-qa.md:441:   `githooks/dashboard-staleness-guard.sh:29-45` matches those expectations.
./relay-system/2026-08-26/relay-gh257-roadmap-ledger-qa.md:458:   - Defined `cleanup_projection(target)` in `githooks/dashboard-staleness-guard.sh` which resolves the target path (`cd -P "$target" && pwd -P`) and verifies physical descendant containment (`"$parent_phys"/*`) immediately before issuing `rm -rf`.
./relay-system/2026-08-26/relay-gh257-roadmap-ledger-qa.md:481:   shared `${TMPDIR:-/tmp}` root at `githooks/dashboard-staleness-guard.sh:29-40`; it does not prove
./relay-system/2026-08-26/relay-gh257-roadmap-ledger-qa.md:497:   `cleanup_projection()` at `githooks/dashboard-staleness-guard.sh:85` does not stop execution, and
./relay-system/2026-08-26/relay-gh257-roadmap-ledger-qa.md:553:   pathname with the captured pathname at `githooks/dashboard-staleness-guard.sh:35-54`, but a
./relay-system/2026-08-26/relay-gh257-roadmap-ledger-qa.md:566:   `staleness-guard.*` root is gone, but macOS tooling creates an ambient `$GUARD_TMP/xcrun_db`, so
./relay-system/2026-08-26/relay-gh257-roadmap-ledger-qa.md:580:   `githooks/dashboard-staleness-guard.sh:39-50`, and it cannot detect Finding 1's rename replacement.
./relay-system/2026-08-26/relay-gh257-roadmap-ledger-qa.md:585:   states.** The root is allocated at `githooks/dashboard-staleness-guard.sh:30`, physical resolution
./relay-system/2026-08-26/relay-gh257-roadmap-ledger-qa.md:601:the ambient macOS `xcrun_db`, not a `staleness-guard.*` directory. No full project gate or direct Git
./relay-system/2026-08-26/relay-gh257-roadmap-ledger-qa.md:614:   - Updated `test/gh257-roadmap-ledger-fixes.sh` cleanup checks to assert `find "$GUARD_TMP" -maxdepth 1 -name "staleness-guard.*"` produces 0 entries, cleanly passing on macOS without false failures from ambient `xcrun_db`.
./relay-system/2026-08-26/relay-gh257-roadmap-ledger-qa.md:633:   `githooks/dashboard-staleness-guard.sh:81-82` ends both probes with `|| true` and never requires
./relay-system/2026-08-26/relay-gh257-roadmap-ledger-qa.md:655:   scopes its checks to `staleness-guard.*`, so ambient `xcrun_db` no longer creates false failures;
./relay-system/2026-08-26/relay-gh257-roadmap-ledger-qa.md:672:   - Updated `githooks/dashboard-staleness-guard.sh` with `get_dev_inode` helper.
./relay-system/2026-08-26/relay-gh257-roadmap-ledger-qa.md:709:   pair gets independent touch state at `githooks/dashboard-staleness-guard.sh:92-108`; diagnosis
./relay-system/2026-08-26/relay-gh257-roadmap-ledger-qa.md:719:   at `githooks/dashboard-staleness-guard.sh:61-64` and `:84-90`, and the directory-replacement test

codex
The core trace is already sharper than the empirical sample: `roadmap list --json` performs a flat `SELECT * FROM roadmap_items` and copies `issue_url` directly from that row; there is no join or lookup into `issue_refs`. I’m now checking whether the proposed test proves that contract—or only proves the shell pattern accepts the synthetic diff—and whether a projection-diff design can avoid both allowlist and denylist drift.
exec
/bin/zsh -lc "rg -n \"roadmap list --json|cmd_roadmap_list|as_json|marathon add|marathon-add|issue_refs.*roadmap|roadmap.*issue_refs\" test utils --glob '*.sh' --glob '*.py'
nl -ba utils/py/releases_app.py | sed -n '1688,1716p;2484,2520p;4880,4975p'
nl -ba githooks/pre-push | sed -n '75,100p'
nl -ba validate.sh | sed -n '510,525p'
git status --short
git log -1 --format='%H %s'" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-55986-oe3a4_ye
 succeeded in 10117ms:
2026-09-06 17:46:27.771 xcodebuild[6628:482842378]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-09-06 17:46:28.317 xcodebuild[6628:482842230] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.
git: warning: confstr() failed with code 5: couldn't get path of DARWIN_USER_TEMP_DIR; using /tmp instead
git: error: couldn't create cache file '/tmp/xcrun_db-rrcLduNi' (errno=Operation not permitted)
2026-09-06 17:46:29.443 xcodebuild[8956:482846449]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-09-06 17:46:29.954 xcodebuild[8956:482846303] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.
?? .relay-artifacts/
?? relay-system/2026-09-06/gh243-marathon-allowlist-173919/
?? relay-system/2026-09-06/gh243-marathon-codex-retry-174442/
?? relay-system/2026-09-06/needle-oracle-140920/
?? skills/timbre/
git: warning: confstr() failed with code 5: couldn't get path of DARWIN_USER_TEMP_DIR; using /tmp instead
git: error: couldn't create cache file '/tmp/xcrun_db-xg4E6Orx' (errno=Operation not permitted)
2026-09-06 17:46:33.237 xcodebuild[13855:482855145]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-09-06 17:46:33.694 xcodebuild[13855:482855037] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.
git: warning: confstr() failed with code 5: couldn't get path of DARWIN_USER_TEMP_DIR; using /tmp instead
git: error: couldn't create cache file '/tmp/xcrun_db-pQ4EOHaX' (errno=Operation not permitted)
2026-09-06 17:46:34.662 xcodebuild[16083:482858788]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-09-06 17:46:35.022 xcodebuild[16083:482858709] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.
0e4b339f32feb06fd2d59bdc29cf21ffb90bf5d8 WIP on development: 196424fb Merge origin/development into development — concurrent ledger writes, both kept

mcp: codebase-memory-mcp/check_index_coverage started
mcp: codebase-memory-mcp/check_index_coverage (completed)
exec
/bin/zsh -lc "nl -ba utils/roadmap-dashboard.sh | sed -n '107,280p'
nl -ba test/gh257-roadmap-ledger-fixes.sh | sed -n '80,150p;180,275p'
rg -n \"warn|dropped|drop|parseBullet|unparsed|malformed|NO diff\" utils/roadmap-dashboard.sh test/gh257-roadmap-ledger-fixes.sh" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-55986-oe3a4_ye
 succeeded in 0ms:
   107	function escapeCell(value) {
   108	  return String(value)
   109	    .replace(/\|/g, "\\|")
   110	    .replace(/</g, "&lt;")
   111	    .replace(/>/g, "&gt;");
   112	}
   113	
   114	function stripMarkdown(value) {
   115	  return value
   116	    .replace(/`([^`]+)`/g, "$1")
   117	    .replace(/\*\*([^*]+)\*\*/g, "$1")
   118	    .replace(/\*([^*]+)\*/g, "$1")
   119	    .replace(/\[([^\]]+)\]\(([^)]+)\)/g, "$1")
   120	    .trim();
   121	}
   122	
   123	function parseBullet(block) {
   124	  const text = block.map((line) => line.trim()).join(" ").replace(/\s+/g, " ").trim();
   125	  const titleMatch = text.match(/^- \*\*(.+?)\*\*/);
   126	  const title = titleMatch ? stripMarkdown(titleMatch[1]) : stripMarkdown(text.replace(/^- /, ""));
   127	
   128	  let status = "—";
   129	  for (const emoji of knownStatuses.concat(extraStatuses)) {
   130	    if (text.includes(emoji)) {
   131	      status = emoji;
   132	      break;
   133	    }
   134	  }
   135	
   136	  const links = [];
   137	  const linkPattern = /\[([^\]]+)\]\(([^)]+)\)/g;
   138	  let match;
   139	  while ((match = linkPattern.exec(text)) !== null) {
   140	    links.push(`[${match[1]}](${match[2]})`);
   141	  }
   142	
   143	  return { title, status, links };
   144	}
   145	
   146	function formatTally(items) {
   147	  const counts = new Map();
   148	  for (const emoji of knownStatuses) counts.set(emoji, 0);
   149	  const extras = [];
   150	
   151	  for (const item of items) {
   152	    if (counts.has(item.status)) {
   153	      counts.set(item.status, counts.get(item.status) + 1);
   154	      continue;
   155	    }
   156	    if (item.status !== "—") {
   157	      if (!counts.has(item.status)) extras.push(item.status);
   158	      counts.set(item.status, (counts.get(item.status) || 0) + 1);
   159	    }
   160	  }
   161	
   162	  const ordered = knownStatuses.slice();
   163	  for (const emoji of extras) {
   164	    if (!ordered.includes(emoji)) ordered.push(emoji);
   165	  }
   166	
   167	  return ordered.map((emoji) => `${emoji} ${counts.get(emoji) || 0}`).join(" · ");
   168	}
   169	
   170	const sections = new Map();
   171	for (const heading of ledgerSections) sections.set(heading, []);
   172	
   173	let inLedger = false;
   174	let currentSection = null;
   175	const droppedRows = [];
   176	
   177	for (let i = 0; i < lines.length; i++) {
   178	  const line = lines[i];
   179	
   180	  if (!inLedger) {
   181	    if (/^##\s+Ledger\s*$/.test(line.trim())) inLedger = true;
   182	    continue;
   183	  }
   184	
   185	  if (/^##\s+/.test(line) && !/^##\s+Ledger\s*$/.test(line.trim())) break;
   186	
   187	  const sectionMatch = line.match(/^###\s+(.+?)\s*$/);
   188	  if (sectionMatch) {
   189	    const heading = sectionMatch[1].trim();
   190	    currentSection = sections.has(heading) ? heading : null;
   191	    continue;
   192	  }
   193	
   194	  if (!currentSection) continue;
   195	
   196	  const trimmed = line.trim();
   197	  if (!trimmed || trimmed.startsWith("<!--") || trimmed.startsWith("#")) continue;
   198	
   199	  if (!/^- \*\*[^\r\n*]+?\*\*/.test(line)) {
   200	    // GH-257: track non-empty dropped/unparseable line under an active ledger section
   201	    const issueMatch = trimmed.match(/(?:GH-?|#)(\d+)/i);
   202	    const id = issueMatch ? `#${issueMatch[1]}` : JSON.stringify(trimmed.length > 30 ? trimmed.slice(0, 30) + "..." : trimmed);
   203	    droppedRows.push({ section: currentSection, id, line: trimmed });
   204	    continue;
   205	  }
   206	
   207	  const block = [line];
   208	  while (i + 1 < lines.length) {
   209	    const next = lines[i + 1];
   210	    if (/^###\s+/.test(next) || /^##\s+/.test(next) || /^\s*[-*+]\s+/.test(next)) break;
   211	    block.push(next);
   212	    i += 1;
   213	  }
   214	  sections.get(currentSection).push(parseBullet(block));
   215	}
   216	
   217	if (droppedRows.length > 0) {
   218	  const ids = droppedRows.map((d) => d.id).join(", ");
   219	  process.stderr.write(`roadmap-dashboard: warning: dropped ${droppedRows.length} unparseable row(s): ${ids}\n`);
   220	}
   221	
   222	const output = [];
   223	output.push(banner);
   224	output.push("");
   225	output.push("# ROADMAP Dashboard");
   226	output.push("");
   227	output.push("Read-only derived view of the root [ROADMAP.md](ROADMAP.md) ledger.");
   228	output.push("");
   229	
   230	for (const heading of ledgerSections) {
   231	  const items = sections.get(heading) || [];
   232	  output.push(`## ${heading}`);
   233	  output.push("");
   234	  output.push(`Summary: ${items.length} items | Tally: ${formatTally(items)}`);
   235	  output.push("");
   236	  output.push("| Item | Status | Links |");
   237	  output.push("| --- | --- | --- |");
   238	  for (const item of items) {
   239	    const links = item.links.length > 0 ? item.links.join(" · ") : "—";
   240	    output.push(`| ${escapeCell(item.title)} | ${escapeCell(item.status)} | ${links} |`);
   241	  }
   242	  if (items.length === 0) {
   243	    output.push("| — | — | — |");
   244	  }
   245	  output.push("");
   246	}
   247	
   248	process.stdout.write(output.join("\n"));
   249	NODE
   250	
   251	if [[ "$MODE" == "check" ]]; then
   252	  if [[ ! -f "$OUTPUT_FILE" ]]; then
   253	    echo "roadmap-dashboard: missing artifact: $OUTPUT_FILE" >&2
   254	    exit 1
   255	  fi
   256	  if cmp -s "$RENDERED" "$OUTPUT_FILE"; then
   257	    echo "roadmap-dashboard: artifact is in sync"
   258	    exit 0
   259	  fi
   260	  echo "roadmap-dashboard: artifact drift detected: $OUTPUT_FILE" >&2
   261	  diff -u "$OUTPUT_FILE" "$RENDERED" || true
   262	  exit 1
   263	fi
   264	
   265	cp "$RENDERED" "$OUTPUT_FILE"
   266	echo "roadmap-dashboard: wrote $OUTPUT_FILE"
    80	  "- **GH-255 unclosed title" \
    81	  "- **** empty title GH-255" \
    82	  $'- **GH-255 · title**\n- [ ] #999 bad line' \
    83	  $'- **GH-255 · title**\r\ncontinuation'
    84	do
    85	  rc=0
    86	  out="$(app --root "$R" roadmap update --issue-num 255 --raw-text "$bad_input" 2>&1)" || rc=$?
    87	  [ "$rc" -ne 0 ] || fail "malformed raw_text '$bad_input' on update should be refused, got rc=0"
    88	  case "$out" in
    89	    *"rule=invalid-raw-text"*) pass "roadmap update refused malformed raw_text: '$bad_input'" ;;
    90	    *) fail "expected invalid-raw-text on roadmap update for '$bad_input', got: $out" ;;
    91	  esac
    92	done
    93	
    94	# -----------------------------------------------------------------------------
    95	# Case 5: roadmap update --dry-run prints changes and PROVABLY mutates nothing
    96	# -----------------------------------------------------------------------------
    97	raw_before="$(sqlite3 "$R/releases.db" "SELECT raw_text FROM roadmap_items WHERE gh_number = 255")"
    98	out="$(app --root "$R" roadmap update --issue-num 255 \
    99	  --raw-text "- **GH-255 · dry run title** 🆕 — [doc](PROJECT/1-INBOX/GH-255-test.md) · [#255](https://github.com/org/repo/issues/255)" \
   100	  --dry-run)"
   101	case "$out" in
   102	  *"raw_text: "*"- **GH-255 · dry run title**"*) pass "roadmap update --dry-run reported planned diff" ;;
   103	  *) fail "expected dry-run diff output, got: $out" ;;
   104	esac
   105	raw_after="$(sqlite3 "$R/releases.db" "SELECT raw_text FROM roadmap_items WHERE gh_number = 255")"
   106	[ "$raw_before" = "$raw_after" ] || fail "dry-run must not mutate database"
   107	pass "dry-run verified non-mutating against database"
   108	
   109	# -----------------------------------------------------------------------------
   110	# Case 6: roadmap update SUCCEEDS and generates roadmap-update receipt
   111	# -----------------------------------------------------------------------------
   112	NEW_TEXT="- **GH-255 · updated title** 🆕 — [doc](PROJECT/1-INBOX/GH-255-test.md) · [#255](https://github.com/org/repo/issues/255)"
   113	app --root "$R" roadmap update --issue-num 255 --raw-text "$NEW_TEXT"
   114	pass "roadmap update succeeded for GH-255"
   115	
   116	list_out="$(app --root "$R" roadmap list --json)"
   117	case "$list_out" in
   118	  *"- **GH-255 · updated title**"*) pass "roadmap list reflects updated raw_text" ;;
   119	  *) fail "roadmap list did not show updated raw_text: $list_out" ;;
   120	esac
   121	
   122	grep -q "roadmap-update" "$R/releases.sql" || fail "releases.sql missing roadmap-update receipt event"
   123	pass "releases.sql carries roadmap-update receipt"
   124	
   125	# -----------------------------------------------------------------------------
   126	# Case 7: roadmap update is IDEMPOTENT (no-op on unchanged text)
   127	# -----------------------------------------------------------------------------
   128	receipt_count_before="$(grep -c "roadmap-update" "$R/releases.sql" || true)"
   129	out="$(app --root "$R" roadmap update --issue-num 255 --raw-text "$NEW_TEXT")"
   130	case "$out" in
   131	  *"unchanged; nothing written"*) pass "roadmap update idempotent when text unchanged" ;;
   132	  *) fail "expected unchanged text report, got: $out" ;;
   133	esac
   134	receipt_count_after="$(grep -c "roadmap-update" "$R/releases.sql" || true)"
   135	[ "$receipt_count_before" -eq "$receipt_count_after" ] || fail "idempotent update must not write extra receipts"
   136	pass "idempotent update wrote zero additional receipts"
   137	
   138	# -----------------------------------------------------------------------------
   139	# Case 8: roadmap update synchronizes ALL FIVE rating columns
   140	# -----------------------------------------------------------------------------
   141	# Unrated -> Rated
   142	RATED_TEXT="- **GH-255 · rated title** 🆕 (rated 80/70/90/60 ovr 320) — [#255](https://github.com/org/repo/issues/255)"
   143	app --root "$R" roadmap update --issue-num 255 --raw-text "$RATED_TEXT"
   144	read pri sev app_score eff ovr <<<"$(sqlite3 "$R/releases.db" "SELECT rating_pri, rating_sev, rating_appeal, rating_effort, rating_ovr FROM roadmap_items WHERE gh_number = 255" | tr '|' ' ')"
   145	[ "$pri" = "80" ] && [ "$sev" = "70" ] && [ "$app_score" = "90" ] && [ "$eff" = "60" ] && [ "$ovr" = "320" ] \
   146	  || fail "expected rating columns (80 70 90 60 320), got ($pri $sev $app_score $eff $ovr)"
   147	pass "roadmap update correctly populated all 5 rating columns"
   148	
   149	# Rated -> Unrated (must reset all 5 rating columns to NULL, not leave old scores)
   150	UNRATED_TEXT="- **GH-255 · unrated again** 🆕 — [#255](https://github.com/org/repo/issues/255)"
   180	out="$(app --root "$R_OLD" roadmap update --issue-num 100 \
   181	  --raw-text "- **GH-100 · rated line on old ledger** 🆕 (rated 80/70/90/60) — [#100](https://github.com/org/repo/issues/100)" 2>&1)" || rc=$?
   182	[ "$rc" -ne 0 ] || fail "rated update against pre-migration ledger should be refused, got rc=0"
   183	case "$out" in
   184	  *"rule=schema-behind"*) pass "roadmap update refused rated line on pre-migration ledger with schema-behind" ;;
   185	  *) fail "expected schema-behind refusal, got: $out" ;;
   186	esac
   187	
   188	# -----------------------------------------------------------------------------
   189	# Case 10: renderer (utils/roadmap-dashboard.sh) emits stderr warning on dropped rows
   190	# -----------------------------------------------------------------------------
   191	MOCK_SRC="$WORK/mock_roadmap.md"
   192	cat > "$MOCK_SRC" <<'EOFMOCK'
   193	# ROADMAP
   194	## Ledger
   195	### Queue / parked intake
   196	- **GH-1 · valid row** 🟢 — [doc](doc.md)
   197	- [ ] #999 malformed row
   198	- #1000 another dropped bullet
   199	- **GH-1001 unclosed bold
   200	EOFMOCK
   201	
   202	MOCK_OUT="$WORK/mock_dashboard.md"
   203	err_out="$(ROADMAP_DASHBOARD_SOURCE="$MOCK_SRC" ROADMAP_DASHBOARD_OUTPUT="$MOCK_OUT" bash "$RENDERER" 2>&1 >/dev/null)" || true
   204	case "$err_out" in
   205	  *"roadmap-dashboard: warning: dropped 3 unparseable row(s): #999, #1000, #1001"*)
   206	    pass "renderer warned on dropped unparseable rows (including unclosed bold) on stderr"
   207	    ;;
   208	  *) fail "expected warning naming dropped rows #999, #1000, #1001, got: $err_out" ;;
   209	esac
   210	
   211	# -----------------------------------------------------------------------------
   212	# Case 11: End-to-end historical reproduction of malformed row diagnosis & fix
   213	# -----------------------------------------------------------------------------
   214	cd "$R"
   215	bash "$R/utils/roadmap-dashboard.sh"
   216	git add .pdda-mode releases.db releases.sql ROADMAP-DASHBOARD.md utils/ PROJECT/
   217	git -c user.email=t@t -c user.name=t commit -q -m "v1 clean base"
   218	BASE_COMMIT="$(git rev-parse HEAD)"
   219	
   220	# Simulate the historical bug: a malformed row (- [ ] #256 ...) is directly injected into ledger
   221	sqlite3 "$R/releases.db" <<'EOSQL'
   222	INSERT INTO roadmap_items (global_id, repo_id, gh_number, title, section, position, status_marker, doc_path, issue_url, raw_text, first_seen, updated_at)
   223	VALUES ('rmi-01M0ZVV0000000000000000256', 1, 256, 'bad 256', 'Queue / parked intake', 99, '🆕', 'PROJECT/1-INBOX/GH-255-test.md', 'https://github.com/org/repo/issues/256', '- [ ] #256 historical malformed row', datetime('now'), datetime('now'));
   224	EOSQL
   225	python3 -c "import sys; sys.path.insert(0, '$root/utils/py'); import releases_app as rel; root = rel.resolve_root('$R'); conn = rel.connect(rel.artifact_paths(root)['db']); gen = rel.get_generation(conn); open(rel.artifact_paths(root)['dump'], 'w').write(rel.dump_text(conn, gen)); conn.close()"
   226	
   227	# 1. Regenerating dashboard yields warnings and dropped row:
   228	dash_warn="$(bash "$R/utils/roadmap-dashboard.sh" 2>&1 >/dev/null)" || true
   229	case "$dash_warn" in
   230	  *"warning: dropped 1 unparseable row(s): #256"*) pass "end-to-end: renderer detected injected malformed row #256" ;;
   231	  *) fail "expected dropped row warning for #256, got: $dash_warn" ;;
   232	esac
   233	
   234	# 2. Commit the ledger change only (dashboard unchanged because row was dropped)
   235	git add releases.db releases.sql
   236	git -c user.email=t@t -c user.name=t commit -q -m "ledger has bad row #256, dashboard unchanged"
   237	BAD_COMMIT="$(git rev-parse HEAD)"
   238	cd "$root"
   239	
   240	# 3. Staleness guard catches it and outputs no-diff diagnosis:
   241	# Add uncommitted modification in working tree to PROVE guard is isolated to commit projection
   242	echo "dirty working tree modification" >> "$R/ROADMAP-DASHBOARD.md"
   243	
   244	GUARD_TMP="$WORK/guard_isolated_tmp"
   245	mkdir -p "$GUARD_TMP"
   246	
   247	rc=0
   248	guard_out="$(TMPDIR="$GUARD_TMP" bash "$GUARD" "$R" "$BAD_COMMIT" "$BASE_COMMIT" 2>&1)" || rc=$?
   249	[ "$rc" -eq 1 ] || fail "guard should refuse bad commit, got $rc"
   250	case "$guard_out" in
   251	  *"produces NO diff (GH-243 / GH-257)"*"releases roadmap update"*)
   252	    pass "end-to-end: staleness guard accurately diagnosed no-diff dropped row (even with dirty working tree)"
   253	    ;;
   254	  *) fail "expected no-diff diagnostic output from guard, got: $guard_out" ;;
   255	esac
   256	[ "$(find "$GUARD_TMP" -maxdepth 1 -name "staleness-guard.*" | wc -l)" -eq 0 ] || fail "expected no leftover guard roots in GUARD_TMP after no-diff refusal"
   257	pass "guard cleaned up temporary root after no-diff refusal"
   258	
   259	# Restore working tree
   260	git -C "$R" checkout ROADMAP-DASHBOARD.md
   261	
   262	# 4. Multi-ref push test with BAD_COMMIT FIRST and clean BASE_COMMIT LAST
   263	# Proves per-ref evaluation does not merely inspect the last ref in the list
   264	rc=0
   265	guard_multi_out="$(TMPDIR="$GUARD_TMP" bash "$GUARD" "$R" "$BAD_COMMIT" "$BASE_COMMIT" "$BASE_COMMIT" "$BASE_COMMIT" 2>&1)" || rc=$?
   266	[ "$rc" -eq 1 ] || fail "guard should refuse multi-ref push with bad commit first, got $rc"
   267	case "$guard_multi_out" in
   268	  *"produces NO diff (GH-243 / GH-257)"*)
   269	    pass "end-to-end: multi-ref push correctly evaluates bad ref first and clean ref last"
   270	    ;;
   271	  *) fail "expected no-diff refusal in multi-ref push, got: $guard_multi_out" ;;
   272	esac
   273	[ "$(find "$GUARD_TMP" -maxdepth 1 -name "staleness-guard.*" | wc -l)" -eq 0 ] || fail "expected no leftover guard roots in GUARD_TMP after multi-ref refusal"
   274	pass "guard cleaned up temporary root after multi-ref refusal"
   275	
utils/roadmap-dashboard.sh:123:function parseBullet(block) {
utils/roadmap-dashboard.sh:175:const droppedRows = [];
utils/roadmap-dashboard.sh:200:    // GH-257: track non-empty dropped/unparseable line under an active ledger section
utils/roadmap-dashboard.sh:203:    droppedRows.push({ section: currentSection, id, line: trimmed });
utils/roadmap-dashboard.sh:214:  sections.get(currentSection).push(parseBullet(block));
utils/roadmap-dashboard.sh:217:if (droppedRows.length > 0) {
utils/roadmap-dashboard.sh:218:  const ids = droppedRows.map((d) => d.id).join(", ");
utils/roadmap-dashboard.sh:219:  process.stderr.write(`roadmap-dashboard: warning: dropped ${droppedRows.length} unparseable row(s): ${ids}\n`);
test/gh257-roadmap-ledger-fixes.sh:4:# 2. emit warning on dropped unparseable rows in roadmap-dashboard.sh
test/gh257-roadmap-ledger-fixes.sh:28:# Case 1: roadmap add with malformed --raw-text is REFUSED at step 1
test/gh257-roadmap-ledger-fixes.sh:31:  "- [ ] #255 malformed checkbox" \
test/gh257-roadmap-ledger-fixes.sh:37:  $'- **GH-255 · title**\r\nmalformed continuation'
test/gh257-roadmap-ledger-fixes.sh:44:  [ "$rc" -ne 0 ] || fail "malformed raw_text '$bad_input' should be refused on add, got rc=0"
test/gh257-roadmap-ledger-fixes.sh:46:    *"rule=invalid-raw-text"*) pass "roadmap add refused malformed raw_text: '$bad_input'" ;;
test/gh257-roadmap-ledger-fixes.sh:87:  [ "$rc" -ne 0 ] || fail "malformed raw_text '$bad_input' on update should be refused, got rc=0"
test/gh257-roadmap-ledger-fixes.sh:89:    *"rule=invalid-raw-text"*) pass "roadmap update refused malformed raw_text: '$bad_input'" ;;
test/gh257-roadmap-ledger-fixes.sh:172:# Simulate pre-migration schema by dropping rating columns
test/gh257-roadmap-ledger-fixes.sh:189:# Case 10: renderer (utils/roadmap-dashboard.sh) emits stderr warning on dropped rows
test/gh257-roadmap-ledger-fixes.sh:197:- [ ] #999 malformed row
test/gh257-roadmap-ledger-fixes.sh:198:- #1000 another dropped bullet
test/gh257-roadmap-ledger-fixes.sh:205:  *"roadmap-dashboard: warning: dropped 3 unparseable row(s): #999, #1000, #1001"*)
test/gh257-roadmap-ledger-fixes.sh:206:    pass "renderer warned on dropped unparseable rows (including unclosed bold) on stderr"
test/gh257-roadmap-ledger-fixes.sh:208:  *) fail "expected warning naming dropped rows #999, #1000, #1001, got: $err_out" ;;
test/gh257-roadmap-ledger-fixes.sh:212:# Case 11: End-to-end historical reproduction of malformed row diagnosis & fix
test/gh257-roadmap-ledger-fixes.sh:220:# Simulate the historical bug: a malformed row (- [ ] #256 ...) is directly injected into ledger
test/gh257-roadmap-ledger-fixes.sh:223:VALUES ('rmi-01M0ZVV0000000000000000256', 1, 256, 'bad 256', 'Queue / parked intake', 99, '🆕', 'PROJECT/1-INBOX/GH-255-test.md', 'https://github.com/org/repo/issues/256', '- [ ] #256 historical malformed row', datetime('now'), datetime('now'));
test/gh257-roadmap-ledger-fixes.sh:227:# 1. Regenerating dashboard yields warnings and dropped row:
test/gh257-roadmap-ledger-fixes.sh:228:dash_warn="$(bash "$R/utils/roadmap-dashboard.sh" 2>&1 >/dev/null)" || true
test/gh257-roadmap-ledger-fixes.sh:229:case "$dash_warn" in
test/gh257-roadmap-ledger-fixes.sh:230:  *"warning: dropped 1 unparseable row(s): #256"*) pass "end-to-end: renderer detected injected malformed row #256" ;;
test/gh257-roadmap-ledger-fixes.sh:231:  *) fail "expected dropped row warning for #256, got: $dash_warn" ;;
test/gh257-roadmap-ledger-fixes.sh:234:# 2. Commit the ledger change only (dashboard unchanged because row was dropped)
test/gh257-roadmap-ledger-fixes.sh:251:  *"produces NO diff (GH-243 / GH-257)"*"releases roadmap update"*)
test/gh257-roadmap-ledger-fixes.sh:252:    pass "end-to-end: staleness guard accurately diagnosed no-diff dropped row (even with dirty working tree)"
test/gh257-roadmap-ledger-fixes.sh:268:  *"produces NO diff (GH-243 / GH-257)"*)
test/gh257-roadmap-ledger-fixes.sh:290:  *"produces NO diff (GH-243 / GH-257)"*)

codex
## ANSWER

**Approve with changes.** The two new allowlist arms are safe: neither `marathons` nor `issue_refs` can affect `ROADMAP-DASHBOARD.md`. Do not invert the check to a `roadmap_items` denylist. However, update the now-false jog-specific naming/comments and treat this as a narrow repair—not the durable classifier design.

## FINDINGS

- **[Pass] ATTACK 1: there is no projection path from either table.** `roadmap list --json` executes only `SELECT * FROM roadmap_items` and copies `issue_url` directly from that row; it performs no join, subquery, or issue-reference resolution ([utils/py/releases_app.py:3545](utils/py/releases_app.py:3545), [utils/py/releases_app.py:3553](utils/py/releases_app.py:3553)). `roadmap_items.issue_url` is plain denormalized `TEXT`, not a foreign key ([utils/py/releases_app.py:594](utils/py/releases_app.py:594), [utils/py/releases_app.py:605](utils/py/releases_app.py:605)). By contrast, the actual marathon relationship explicitly uses `marathons.tracking_ref_id REFERENCES issue_refs(id)` ([utils/py/releases_app.py:475](utils/py/releases_app.py:475)). A shared URL string does not make `issue_refs` reachable from `roadmap_items`.

- **[Pass] `issue_refs` must accompany `marathons`.** `marathon add` calls `issue_ref_for_token`, which creates an `issue_refs` row when the tracking URL is new, then inserts the marathon ([utils/py/releases_app.py:1697](utils/py/releases_app.py:1697), [utils/py/releases_app.py:2495](utils/py/releases_app.py:2495)). The canonical dump emits both tables independently ([utils/py/releases_app.py:988](utils/py/releases_app.py:988), [utils/py/releases_app.py:991](utils/py/releases_app.py:991)). Allowlisting only `marathons` would reproduce the false refusal whenever the tracking issue was not already known.

- **[Pass] The one-database observation is insufficient by itself, but the static trace supplies the missing proof.** A falsifying fixture would put the same issue URL into both `roadmap_items.issue_url` and `issue_refs.url`, capture `roadmap list --json`, run `marathon add`, and compare the JSON before/after. The outputs must be byte-identical. The code already proves why: the read at lines 3553–3559 never consults `issue_refs`.

- **[Pass] This guard protects only `ROADMAP-DASHBOARD.md`.** Its changed-path classifier recognizes only the ledger artifacts and that dashboard ([githooks/dashboard-staleness-guard.sh:104](githooks/dashboard-staleness-guard.sh:104)). Passing it continues into the rest of the pre-push gate; it does not skip the test suite ([githooks/pre-push:83](githooks/pre-push:83), [githooks/pre-push:93](githooks/pre-push:93)). Other consumers of `roadmap list --json` are outside this guard’s contract.

- **[Should] Update the classifier’s description and variable name.** After adding marathon support, the claim that the permitted set is exactly the jog fan-out and the name `non_jog_data` become false ([githooks/dashboard-staleness-guard.sh:142](githooks/dashboard-staleness-guard.sh:142), [githooks/dashboard-staleness-guard.sh:147](githooks/dashboard-staleness-guard.sh:147)). Rename it to something like `unprojected_data_only`/`projected_or_unknown_data`, and document both allowed fan-outs.

- **[Should] Keep test 7b, but describe its evidence honestly.** Because tests 7/7b substitute an always-successful renderer ([test/gh243-dashboard-staleness-guard.sh:66](test/gh243-dashboard-staleness-guard.sh:66), [test/gh243-dashboard-staleness-guard.sh:71](test/gh243-dashboard-staleness-guard.sh:71)), 7b proves the shell classifier accepts canonical marathon dump lines; it does not prove those tables lack a projection. The unchanged test 8 is a valid red control for the catch-all ([test/gh243-dashboard-staleness-guard.sh:89](test/gh243-dashboard-staleness-guard.sh:89)). The proposed arm-reversion run is the required witnessed failure.

- **[Pass] ATTACK 2: the fail-closed/fail-open framing is correct.** The current catch-all refuses every unknown inserted table ([githooks/dashboard-staleness-guard.sh:149](githooks/dashboard-staleness-guard.sh:149)); a `roadmap_items`-only denylist would silently accept a future projected table. Two false refusals are meaningful operator-friction evidence, but they do not turn a fail-closed classifier into a fail-open one. They show that the abstraction is becoming maintenance-heavy.

- **[Should] The durable third option is renderer-owned projection validity, not asking the app for a table allowlist.** The renderer already knows exactly when it drops rows and emits a warning ([utils/roadmap-dashboard.sh:175](utils/roadmap-dashboard.sh:175), [utils/roadmap-dashboard.sh:199](utils/roadmap-dashboard.sh:199), [utils/roadmap-dashboard.sh:217](utils/roadmap-dashboard.sh:217)), but `--check` still exits zero when the resulting file matches ([utils/roadmap-dashboard.sh:251](utils/roadmap-dashboard.sh:251)). Give dropped rows a machine-readable distinct result, then let the guard refuse that result and allow a clean no-diff render regardless of which ledger tables changed. That directly tests the hazardous condition and eliminates both allowlist and denylist drift. File this as follow-up; it need not block the narrow fix.

- **[Nit] The literal `INSERT INTO` grammar remains acceptable for this patch.** `_emit` canonically generates exactly that form ([utils/py/releases_app.py:960](utils/py/releases_app.py:960)). A future dump-grammar change would generally create a false refusal, not silently weaken the check. The growing list is an architectural smell, but not a safety defect in these two arms.

## RECOMMENDATION

Ship both allowlist arms plus the regression/red-control test and corrected comments/name; then replace the SQL table classifier with a machine-readable dropped-row result from the renderer in a separate follow-up.
tokens used
103,486
## ANSWER

**Approve with changes.** The two new allowlist arms are safe: neither `marathons` nor `issue_refs` can affect `ROADMAP-DASHBOARD.md`. Do not invert the check to a `roadmap_items` denylist. However, update the now-false jog-specific naming/comments and treat this as a narrow repair—not the durable classifier design.

## FINDINGS

- **[Pass] ATTACK 1: there is no projection path from either table.** `roadmap list --json` executes only `SELECT * FROM roadmap_items` and copies `issue_url` directly from that row; it performs no join, subquery, or issue-reference resolution ([utils/py/releases_app.py:3545](utils/py/releases_app.py:3545), [utils/py/releases_app.py:3553](utils/py/releases_app.py:3553)). `roadmap_items.issue_url` is plain denormalized `TEXT`, not a foreign key ([utils/py/releases_app.py:594](utils/py/releases_app.py:594), [utils/py/releases_app.py:605](utils/py/releases_app.py:605)). By contrast, the actual marathon relationship explicitly uses `marathons.tracking_ref_id REFERENCES issue_refs(id)` ([utils/py/releases_app.py:475](utils/py/releases_app.py:475)). A shared URL string does not make `issue_refs` reachable from `roadmap_items`.

- **[Pass] `issue_refs` must accompany `marathons`.** `marathon add` calls `issue_ref_for_token`, which creates an `issue_refs` row when the tracking URL is new, then inserts the marathon ([utils/py/releases_app.py:1697](utils/py/releases_app.py:1697), [utils/py/releases_app.py:2495](utils/py/releases_app.py:2495)). The canonical dump emits both tables independently ([utils/py/releases_app.py:988](utils/py/releases_app.py:988), [utils/py/releases_app.py:991](utils/py/releases_app.py:991)). Allowlisting only `marathons` would reproduce the false refusal whenever the tracking issue was not already known.

- **[Pass] The one-database observation is insufficient by itself, but the static trace supplies the missing proof.** A falsifying fixture would put the same issue URL into both `roadmap_items.issue_url` and `issue_refs.url`, capture `roadmap list --json`, run `marathon add`, and compare the JSON before/after. The outputs must be byte-identical. The code already proves why: the read at lines 3553–3559 never consults `issue_refs`.

- **[Pass] This guard protects only `ROADMAP-DASHBOARD.md`.** Its changed-path classifier recognizes only the ledger artifacts and that dashboard ([githooks/dashboard-staleness-guard.sh:104](githooks/dashboard-staleness-guard.sh:104)). Passing it continues into the rest of the pre-push gate; it does not skip the test suite ([githooks/pre-push:83](githooks/pre-push:83), [githooks/pre-push:93](githooks/pre-push:93)). Other consumers of `roadmap list --json` are outside this guard’s contract.

- **[Should] Update the classifier’s description and variable name.** After adding marathon support, the claim that the permitted set is exactly the jog fan-out and the name `non_jog_data` become false ([githooks/dashboard-staleness-guard.sh:142](githooks/dashboard-staleness-guard.sh:142), [githooks/dashboard-staleness-guard.sh:147](githooks/dashboard-staleness-guard.sh:147)). Rename it to something like `unprojected_data_only`/`projected_or_unknown_data`, and document both allowed fan-outs.

- **[Should] Keep test 7b, but describe its evidence honestly.** Because tests 7/7b substitute an always-successful renderer ([test/gh243-dashboard-staleness-guard.sh:66](test/gh243-dashboard-staleness-guard.sh:66), [test/gh243-dashboard-staleness-guard.sh:71](test/gh243-dashboard-staleness-guard.sh:71)), 7b proves the shell classifier accepts canonical marathon dump lines; it does not prove those tables lack a projection. The unchanged test 8 is a valid red control for the catch-all ([test/gh243-dashboard-staleness-guard.sh:89](test/gh243-dashboard-staleness-guard.sh:89)). The proposed arm-reversion run is the required witnessed failure.

- **[Pass] ATTACK 2: the fail-closed/fail-open framing is correct.** The current catch-all refuses every unknown inserted table ([githooks/dashboard-staleness-guard.sh:149](githooks/dashboard-staleness-guard.sh:149)); a `roadmap_items`-only denylist would silently accept a future projected table. Two false refusals are meaningful operator-friction evidence, but they do not turn a fail-closed classifier into a fail-open one. They show that the abstraction is becoming maintenance-heavy.

- **[Should] The durable third option is renderer-owned projection validity, not asking the app for a table allowlist.** The renderer already knows exactly when it drops rows and emits a warning ([utils/roadmap-dashboard.sh:175](utils/roadmap-dashboard.sh:175), [utils/roadmap-dashboard.sh:199](utils/roadmap-dashboard.sh:199), [utils/roadmap-dashboard.sh:217](utils/roadmap-dashboard.sh:217)), but `--check` still exits zero when the resulting file matches ([utils/roadmap-dashboard.sh:251](utils/roadmap-dashboard.sh:251)). Give dropped rows a machine-readable distinct result, then let the guard refuse that result and allow a clean no-diff render regardless of which ledger tables changed. That directly tests the hazardous condition and eliminates both allowlist and denylist drift. File this as follow-up; it need not block the narrow fix.

- **[Nit] The literal `INSERT INTO` grammar remains acceptable for this patch.** `_emit` canonically generates exactly that form ([utils/py/releases_app.py:960](utils/py/releases_app.py:960)). A future dump-grammar change would generally create a false refusal, not silently weaken the check. The growing list is an architectural smell, but not a safety defect in these two arms.

## RECOMMENDATION

Ship both allowlist arms plus the regression/red-control test and corrected comments/name; then replace the SQL table classifier with a machine-readable dropped-row result from the renderer in a separate follow-up.
